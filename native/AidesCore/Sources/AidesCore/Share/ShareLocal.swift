import Foundation

/* PARTAGE « EN DIRECT » — ce que fait la PWA, et ce que le natif peut en reprendre.
 *
 * ═══ COMMENT LE WEB RÉALISE « EN DIRECT » ═══════════════════════════════════════════════════
 * Ce n'est PAS un serveur HTTP local : c'est un canal de données WebRTC (`RTCDataChannel`,
 * libellé « ac », ordonné et fiable) entre deux navigateurs du même réseau local.
 *   · `new RTCPeerConnection({iceServers: []})` — AUCUN serveur, ni STUN ni TURN : seuls les
 *     candidats « host » du Wi-Fi commun (IPv4 privée, ou nom mDNS `<uuid>.local` que Safari et
 *     Chrome substituent à l'adresse) ; internet n'est pas nécessaire.
 *   · Négociation NON-TRICKLE : on attend la fin du rassemblement ICE (5 s au plus), puis on
 *     réduit le SDP à un QUINTUPLE (ufrag, pwd, empreinte DTLS sha-256, setup, candidats UDP
 *     hôte) — `slSdpExtract` — et l'autre côté RECONSTRUIT un SDP minimal (`slSdpRebuild`).
 *   · Le quintuple voyage en BINAIRE base64url (`slPairPack`, ~130 caractères = UN code QR),
 *     préfixé « SO: » (offre de l'hôte) ou « SA: » (réponse de l'invité), avec un jeton de 4
 *     caractères qui refuse une réponse périmée. Appariement MANUEL, écran contre caméra :
 *     l'hôte montre son offre, l'invité la filme et montre sa réponse, l'hôte la filme.
 *   · Sur le canal, une trame RPC JSON {i, n, p} → {i, r} | {i, e} (`slRpcPack`/`slRpcReply`)
 *     transporte LES MÊMES HUIT VERBES que le serveur. L'HÔTE fait tourner un « hub »
 *     (`slHub`) qui reproduit la sémantique de `share_push`/`share_pull` en mémoire — séquence,
 *     dédoublonnage, acteur déduit du secret, capacités, AMPUTATION de la liste blanche,
 *     empreinte du flux — et le moteur `Share` tourne INCHANGÉ au-dessus (`slHostIo`,
 *     `slClient(wire).io`).
 *   · Secours chaud : pendant qu'un partage EN LIGNE fonctionne, l'invité propose une offre par
 *     un évènement `sig {t:'o'}` relayé par le serveur, l'hôte répond `sig {t:'a'}` ; le canal
 *     s'ouvre et DORT. À la panne, l'hôte bascule son partage sur un hub servi par ces canaux
 *     dormants et crie la trame brute « AC:GO » (la bouée) ; l'invité rejoint par le canal.
 *
 * ═══ CE QUE LE NATIF PEUT FAIRE EN PUR FOUNDATION (ce fichier) ═══════════════════════════════
 * Tout ce qui n'est pas la pile WebRTC elle-même : extraction/reconstruction du SDP, charges
 * d'appariement SO:/SA:, trames RPC, le hub (sémantique serveur), le client RPC, le serveur RPC,
 * la couture de l'hôte, et le contrat de canal `ShareWire` (texte seul, comme `slChanWire`).
 *
 * ═══ CE QUI MANQUE POUR INTEROPÉRER AVEC UN PAIR WEB : UNE PILE WEBRTC ═══════════════════════
 * Un pair web ne parle QUE WebRTC (DTLS/SCTP sur ICE). Apple n'expose AUCUNE API WebRTC publique
 * hors WKWebView : l'interop « en direct » natif ↔ web EXIGE donc l'une de ces deux voies —
 *   (a) libwebrtc (binaire Google via SPM, ~10-20 Mo) : `RTCPeerConnection` sans iceServers,
 *       canal « ac » ordonné, réponse en `a=setup:active` (la charge ne sait pas dire
 *       `passive`), SDP reconstruit accepté tel quel (à vérifier sur la version retenue),
 *       résolution des candidats mDNS `.local` (Bonjour) + `NSLocalNetworkUsageDescription` ;
 *       il suffit alors d'implémenter `ShareWire` sur le `RTCDataChannel` natif.
 *   (b) un WKWebView caché qui exécute la pile web — fragile (cycle de vie, permissions).
 * Entre appareils NATIFS seulement, MultipeerConnectivity (ou Network.framework + Bonjour)
 * suffirait et se passerait de QR — mais n'interopère PAS avec le web. Recommandation : ne pas
 * livrer « en direct » natif↔web sans (a) ; offrir MultipeerConnectivity natif↔natif derrière
 * le même `ShareWire` (le hub et le client RPC ci-dessous s'y branchent sans changement).
 */

// MARK: - Signalisation compacte (`slSdpExtract` / `slSdpRebuild`)

/// Le quintuple qui remplace le SDP brut dans un code QR.
public struct ShareSDPQuintuple: Equatable, Sendable {
    public var u: String?      // ice-ufrag
    public var p: String?      // ice-pwd
    public var f: String?      // empreinte sha-256, hex MAJUSCULE sans « : »
    public var s: String?      // setup : actpass (offre) | active (réponse)
    public var c: [String]     // candidats UDP hôte composant 1, « adresse~port »
    public init(u: String?, p: String?, f: String?, s: String?, c: [String]) { self.u = u; self.p = p; self.f = f; self.s = s; self.c = c }
    public var json: JSON {
        func o(_ x: String?) -> JSON { x.map { .string($0) } ?? .null }
        return ["u": o(u), "p": o(p), "f": o(f), "s": o(s), "c": .array(c.map { .string($0) })]
    }
}

public enum ShareSDP {
    static func first(_ sdp: String, _ pattern: String, _ opts: NSRegularExpression.Options = []) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: opts),
              let m = re.firstMatch(in: sdp, range: NSRange(sdp.startIndex..., in: sdp)), m.numberOfRanges > 1,
              let r = Range(m.range(at: 1), in: sdp) else { return nil }
        return String(sdp[r])
    }
    /// `slSdpExtract(sdp)`.
    public static func extract(_ sdp: String) -> ShareSDPQuintuple {
        let fp = first(sdp, "a=fingerprint:sha-256 ([0-9A-F:]+)", [.caseInsensitive])
        var cands: [String] = []
        if let re = try? NSRegularExpression(pattern: "a=candidate:\\S+ 1 udp \\d+ (\\S+) (\\d+) typ host", options: [.caseInsensitive]) {
            for m in re.matches(in: sdp, range: NSRange(sdp.startIndex..., in: sdp)) {
                guard let a = Range(m.range(at: 1), in: sdp), let b = Range(m.range(at: 2), in: sdp) else { continue }
                let c = String(sdp[a]) + "~" + String(sdp[b])
                if !cands.contains(c) { cands.append(c) }
            }
        }
        return ShareSDPQuintuple(u: first(sdp, "a=ice-ufrag:(\\S+)"), p: first(sdp, "a=ice-pwd:(\\S+)"),
                                 f: fp.map { $0.uppercased().replacingOccurrences(of: ":", with: "") },
                                 s: first(sdp, "a=setup:(\\S+)"), c: cands)
    }
    /// `slSdpRebuild(o)` — SDP minimal (une seule ligne m= de données, mid 0, SCTP 5000,
    /// max-message-size 256 Kio), CRLF, CRLF final. nil si un champ manque.
    public static func rebuild(_ o: ShareSDPQuintuple) -> String? {
        guard let u = o.u, !u.isEmpty, let p = o.p, !p.isEmpty, let f = o.f, !f.isEmpty, let s = o.s, !s.isEmpty else { return nil }
        var pairs: [String] = []
        var cur = ""
        for ch in f { cur.append(ch); if cur.count == 2 { pairs.append(cur); cur = "" } }
        if !cur.isEmpty { pairs.append(cur) }
        var L = ["v=0", "o=- 4262 2 IN IP4 127.0.0.1", "s=-", "t=0 0", "a=group:BUNDLE 0",
                 "a=msid-semantic: WMS", "m=application 9 UDP/DTLS/SCTP webrtc-datachannel",
                 "c=IN IP4 0.0.0.0", "a=ice-ufrag:" + u, "a=ice-pwd:" + p,
                 "a=fingerprint:sha-256 " + pairs.joined(separator: ":"),
                 "a=setup:" + s, "a=mid:0", "a=sctp-port:5000", "a=max-message-size:262144"]
        for (i, cd) in o.c.enumerated() {
            let k = cd.components(separatedBy: "~")
            L.append("a=candidate:\(i + 1) 1 udp \(2113937151 - i) \(k[0]) \(k.count > 1 ? k[1] : "undefined") typ host generation 0")
        }
        L.append("a=end-of-candidates")
        return L.joined(separator: "\r\n") + "\r\n"
    }
    /// `slLocalCand(c)` — une adresse de réseau LOCAL (RFC 1918, 169.254/16) ou un nom `.local` :
    /// sans elle, l'appariement direct est voué à l'échec et la feuille passe « par l'écran ».
    public static func hasLocalCandidate(_ c: [String]) -> Bool {
        c.contains { x in
            let a = x.components(separatedBy: "~")[0]
            if a.contains(".local") { return true }
            if a.hasPrefix("10.") || a.hasPrefix("192.168.") || a.hasPrefix("169.254.") { return true }
            if a.hasPrefix("172.") {
                let parts = a.split(separator: ".")
                if parts.count > 2, let n = Int(parts[1]), (16...31).contains(n), parts[1].count == 2 { return true }
            }
            return false
        }
    }
}

// MARK: - Charges d'appariement « SO: » / « SA: » (`slPairPack` / `slPairUnpack`)

/// Offre (« SO: », hôte) ou réponse (« SA: », invité) d'appariement : jeton + quintuple.
public struct SharePairing: Equatable, Sendable {
    public var k: String
    public var sdp: ShareSDPQuintuple
    public init(k: String, sdp: ShareSDPQuintuple) { self.k = k; self.sdp = sdp }

    public static let offerPrefix = "SO:", answerPrefix = "SA:"

    /// Binaire, PAS compressé : ufrag/pwd/empreinte/UUID mDNS sont de l'ENTROPIE, deflate n'y
    /// mord pas. Couche : [1][actpass?][k][u][p][32 o d'empreinte][n][candidats…] → base64url.
    /// nil si une chaîne dépasse 255 octets (la PWA lèverait dans `btoa`).
    public func pack() -> String? {
        var A: [UInt8] = [1, sdp.s == "actpass" ? 1 : 0]
        func putS(_ v: String?) -> Bool {
            let b = Array((v ?? "").utf8)
            guard b.count <= 255 else { return false }
            A.append(UInt8(b.count)); A += b; return true
        }
        guard putS(k), putS(sdp.u), putS(sdp.p) else { return nil }
        let f = Array((sdp.f ?? "").utf16)
        for i in stride(from: 0, to: 64, by: 2) { A.append(Self.parseHex2(f, i)) }
        let cs = Array(sdp.c.prefix(6))
        A.append(UInt8(cs.count))
        for cd in cs {
            let sp = cd.components(separatedBy: "~")
            let ad = sp[0]
            let ptN: Double = sp.count > 1 ? JS.number(.string(sp[1])) : .nan
            let pt = Int(Self.toInt32(ptN.isNaN ? 0 : ptN)) & 0xffff
            if let q = Self.ipv4(ad) {
                A += [0] + q + [UInt8(pt >> 8), UInt8(pt & 255)]
            } else if let h = Self.mdnsUUID(ad) {
                A.append(1); A += h; A += [UInt8(pt >> 8), UInt8(pt & 255)]
            } else {
                A.append(2); guard putS(ad) else { return nil }; A += [UInt8(pt >> 8), UInt8(pt & 255)]
            }
        }
        return ShareJS.base64url(A)
    }

    /// Décode une charge ; nil sur toute violation (version ≠ 1, empreinte non conforme, ufrag
    /// ou pwd vides, troncature).
    public static func unpack(_ b64: String) -> SharePairing? {
        guard let u = ShareJS.base64urlDecode(b64) else { return nil }
        var i = 0
        func byte() -> UInt8? { guard i < u.count else { return nil }; defer { i += 1 }; return u[i] }
        func rdS() -> String? {
            guard let n = byte(), i + Int(n) <= u.count else { return nil }
            defer { i += Int(n) }
            return String(decoding: u[i..<(i + Int(n))], as: UTF8.self)
        }
        guard byte() == 1, let sb = byte() else { return nil }
        guard let k = rdS(), let uf = rdS(), let pw = rdS(), i + 32 <= u.count else { return nil }
        let f = ShareJS.hex(Array(u[i..<(i + 32)])).uppercased(); i += 32
        var c: [String] = []
        let n = byte() ?? 0     // flux coupé juste après l'empreinte : zéro candidat (comme le JS)
        for _ in 0..<Int(n) {
            guard let t = byte() else { return nil }
            if t == 0 {
                guard i + 6 <= u.count else { return nil }
                c.append("\(u[i]).\(u[i + 1]).\(u[i + 2]).\(u[i + 3])~\((Int(u[i + 4]) << 8) | Int(u[i + 5]))"); i += 6
            } else if t == 1 {
                guard i + 18 <= u.count else { return nil }
                let h = Array(ShareJS.hex(Array(u[i..<(i + 16)])))
                i += 16
                c.append(String(h[0..<8]) + "-" + String(h[8..<12]) + "-" + String(h[12..<16]) + "-" + String(h[16..<20]) + "-"
                         + String(h[20..<32]) + ".local~" + String((Int(u[i]) << 8) | Int(u[i + 1])))
                i += 2
            } else {
                guard let ad = rdS(), i + 2 <= u.count else { return nil }
                c.append(ad + "~" + String((Int(u[i]) << 8) | Int(u[i + 1]))); i += 2
            }
        }
        guard !uf.isEmpty, !pw.isEmpty, f.count == 64 else { return nil }
        return SharePairing(k: k, sdp: ShareSDPQuintuple(u: uf, p: pw, f: f, s: sb != 0 ? "actpass" : "active", c: c))
    }

    /// Texte du QR : « SO:… » ou « SA:… ».
    public func qrText(offer: Bool) -> String? { pack().map { (offer ? Self.offerPrefix : Self.answerPrefix) + $0 } }

    /// Jeton de corrélation (`Math.random().toString(36).slice(2,6)`) : 4 caractères base 36.
    public static func newToken(_ random: () -> Double = { Double.random(in: 0..<1) }) -> String {
        let alpha = Array("0123456789abcdefghijklmnopqrstuvwxyz")
        return String((0..<4).map { _ in alpha[Int(random() * 36) % 36] })
    }

    // `parseInt(f.slice(i,i+2),16)||0` : chiffres hex de TÊTE seulement.
    static func parseHex2(_ f: [UInt16], _ i: Int) -> UInt8 {
        var v = 0, n = 0
        guard i < f.count else { return 0 }
        for j in i..<min(i + 2, f.count) {
            let c = f[j]
            let d: Int
            if c >= 48 && c <= 57 { d = Int(c) - 48 } else if c >= 65 && c <= 70 { d = Int(c) - 55 } else if c >= 97 && c <= 102 { d = Int(c) - 87 } else { break }
            v = v * 16 + d; n += 1
        }
        return n == 0 ? 0 : UInt8(v & 255)
    }
    static func toInt32(_ d: Double) -> Int32 {
        guard d.isFinite else { return 0 }
        let m = d.rounded(.towardZero).truncatingRemainder(dividingBy: 4294967296)
        return Int32(truncatingIfNeeded: Int64(m < 0 ? m + 4294967296 : m))
    }
    static func ipv4(_ ad: String) -> [UInt8]? {
        let p = ad.components(separatedBy: ".")
        guard p.count == 4, p.allSatisfy({ !$0.isEmpty && $0.utf8.allSatisfy { $0 >= 48 && $0 <= 57 } }) else { return nil }
        return p.map { s in UInt8(truncatingIfNeeded: Int(toInt32(Double(s) ?? 0)) & 255) }
    }
    static func mdnsUUID(_ ad: String) -> [UInt8]? {
        let l = ad.lowercased()
        guard l.hasSuffix(".local") else { return nil }
        let core = String(l.dropLast(6))
        let g = core.components(separatedBy: "-")
        guard g.count == 5, zip(g, [8, 4, 4, 4, 12]).allSatisfy({ $0.count == $1 && $0.allSatisfy { $0.isHexDigit && $0.isASCII } }) else { return nil }
        let h = Array(g.joined().utf16)
        return stride(from: 0, to: 32, by: 2).map { parseHex2(h, $0) }
    }
}

// MARK: - Trames RPC (`slRpcPack` / `slRpcReply` / `slRpcUnpack`)

public enum ShareRPC {
    /// La bouée (A332) : trame BRUTE, hors RPC, criée sur les canaux dormants à la bascule.
    public static let bouee = "AC:GO"
    /// Délai d'un appel RPC côté invité.
    public static let timeoutMs: Double = 8000
    /// Code factice du `join` sur le canal : l'admission, c'est le canal apparié lui-même.
    public static let dummyCode = "AAAA2222"

    public static func pack(_ id: Int, _ name: String, _ params: JSON?) -> String {
        var o: [String: JSON] = ["i": .number(Double(id)), "n": .string(name)]
        if let params { o["p"] = params }
        return JSON.object(o).text()
    }
    public static func reply(_ id: JSON, result: JSON?, error: String? = nil) -> String {
        if let error { return JSON.object(["i": id, "e": .string(error)]).text() }
        var o: [String: JSON] = ["i": id]
        if let result { o["r"] = result }
        return JSON.object(o).text()
    }
    /// Trame illisible → nil, JAMAIS d'exception depuis le fil.
    public static func unpack(_ txt: String) -> JSON? {
        guard let m = try? JSON.parse(txt), let o = m.object, o["i"] != nil else { return nil }
        if (o["n"]?.truthy ?? false) || o["e"] != nil || o["r"] != nil { return m }
        return Optional<JSON>.none
    }
}

// MARK: - Canal (`slChanWire`)

/// Un canal TEXTE bidirectionnel : `RTCDataChannel` (texte seul, les trames binaires sont
/// ignorées), MultipeerConnectivity, ou la paire en mémoire des tests.
@MainActor
public protocol ShareWire: AnyObject {
    func send(_ text: String)
    var onMessage: ((String) -> Void)? { get set }
}

/// Paire de canaux en mémoire (`slWirePair`) — tests et bancs uniquement. Livraison
/// synchrone : le moteur ne suppose aucun ordre plus faible.
@MainActor
public final class ShareWirePair {
    public final class End: ShareWire {
        weak var peer: End?
        public var onMessage: ((String) -> Void)?
        public var closed = false
        public var sent: [String] = []
        public func send(_ text: String) {
            sent.append(text)
            guard !closed, let p = peer, !p.closed else { return }   // `slChanWire` avale les erreurs d'envoi
            p.onMessage?(text)
        }
    }
    public let a = End(), b = End()
    public init() { a.peer = b; b.peer = a }
}

// MARK: - Le hub de l'hôte (`slHub`)

/// Sans serveur, l'HÔTE tient la sémantique serveur (schema.sql § 8) : séquence sous compteur
/// unique, dédoublonnage `event_id`, `actor` DÉDUIT du secret (jamais un paramètre), capacités,
/// AMPUTATION par la liste blanche, empreinte au format du serveur. Écarts documentés avec le
/// serveur (spec § 20.4) reproduits À L'IDENTIQUE pour l'interopérabilité : un invité coupé
/// reçoit `err:'auth'`, `detach` ne marque pas le participant, pas de limite de débit.
@MainActor
public final class ShareHub {
    public struct Participant: Equatable, Sendable {
        public var id: String, secret: String, label: String, role: String
        public var owner: Bool, seen: Double, revoked: Bool, detached: Bool
        public var publicJSON: JSON {
            ["id": .string(id), "label": .string(label), "role": .string(role), "owner": .bool(owner),
             "seen": .number(seen), "revoked": .bool(revoked), "detached": .bool(detached)]
        }
    }
    public struct Options {
        public var now: () -> Double
        public var uid: () -> String
        public var secret: () -> String
        public var shareId: String
        public var fiche: JSON?
        public var guestRole: String
        public var hostLabel: String
        public init(now: @escaping () -> Double, uid: @escaping () -> String, secret: @escaping () -> String,
                    shareId: String, fiche: JSON?, guestRole: String = "scribe", hostLabel: String = "Hôte") {
            self.now = now; self.uid = uid; self.secret = secret; self.shareId = shareId; self.fiche = fiche
            self.guestRole = guestRole; self.hostLabel = hostLabel
        }
    }
    let o: Options
    public private(set) var seq = 0
    public private(set) var events: [JSON] = []
    public private(set) var parts: [Participant] = []
    public private(set) var status = "active"
    public let fiche: JSON?
    public var shareId: String { o.shareId }

    public init(_ o: Options) {
        self.o = o
        fiche = o.fiche
        parts.append(Participant(id: o.uid(), secret: o.secret(), label: o.hostLabel, role: "lead", owner: true,
                                 seen: o.now(), revoked: false, detached: false))
    }
    /// `slNewHub(f)` : hub neuf pour la fiche `f` — LE littéral des deux portes (bascule et départ direct).
    public static func make(fiche: JSON, now: @escaping () -> Double = JS.now) -> ShareHub {
        ShareHub(Options(now: now, uid: { Guard.uid("p") }, secret: { ShareHub.newSecret() },
                         shareId: Guard.uid("shl"), fiche: ShareCore.payload(fiche)))
    }
    /// `slSecret()` : 18 caractères, alphabet de 31 symboles (local seulement).
    nonisolated public static func newSecret(_ bytes: [UInt8]? = nil) -> String {
        let alpha = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        return String((bytes ?? ShareJS.randomBytes(18)).map { alpha[Int($0) % 31] })
    }

    func nowISO() -> String { ShareJS.isoString(o.now()) }
    func find(_ secret: String?) -> Int? { parts.firstIndex { $0.secret == secret && !$0.revoked } }
    public var hostSecret: String { parts[0].secret }
    public var guests: [Participant] { parts.filter { !$0.owner && !$0.revoked } }
    public func streamHash() -> String { ShareSHA256.hex(events.map { "\($0["seq"]!.jsString):\($0["id"]!.jsString)" }.joined(separator: ",")) }

    public func join(label: String?) -> JSON {
        if status != "active" { return ["ok": false, "err": "ended"] }
        if parts.filter({ !$0.revoked }).count >= 8 { return ["ok": false, "err": "full"] }
        let lab = Guard.sstr(label.map { .string($0) }, 24)
        let p = Participant(id: o.uid(), secret: o.secret(), label: lab.isEmpty ? "Invité" : lab, role: o.guestRole,
                            owner: false, seen: o.now(), revoked: false, detached: false)
        parts.append(p)
        return ["ok": true, "share": .string(o.shareId), "me": .string(p.id), "secret": .string(p.secret), "role": .string(p.role),
                "fiche": fiche ?? .null, "since": .number(Double(seq)), "server_time": .string(nowISO())]
    }
    public func pull(secret: String?, since: Double) -> JSON {
        guard let i = find(secret) else { return ["ok": false, "err": "auth"] }
        if status != "active" {
            return ["ok": true, "status": .string(status), "events": [], "seq": .number(Double(seq)), "n_events": .number(Double(events.count)),
                    "participants": .array(parts.map(\.publicJSON)), "server_time": .string(nowISO())]
        }
        parts[i].seen = o.now()
        let ev = events.filter { ($0["seq"]?.number ?? 0) > since }.prefix(500)
        var r: [String: JSON] = ["ok": true, "status": .string(parts[i].revoked ? "revoked" : status), "role": .string(parts[i].role),
                                 "me": .string(parts[i].id), "events": .array(Array(ev)), "seq": .number(Double(seq)),
                                 "n_events": .number(Double(events.count)), "stream": .string(streamHash()),
                                 "participants": .array(parts.map(\.publicJSON)), "server_time": .string(nowISO())]
        if since == 0 && !parts[i].owner { r["fiche"] = fiche ?? .null }
        return .object(r)
    }
    public func push(secret: String?, events evs: [JSON]) -> JSON {
        guard let i = find(secret) else { return ["ok": false, "err": "auth"] }
        if status != "active" { return ["ok": false, "err": "ended"] }
        if parts[i].detached { return ["ok": false, "err": "detached"] }
        parts[i].seen = o.now()
        var accepted = 0, rejected = 0
        for e in evs.prefix(50) {
            guard e.truthy, let eid = e["event_id"], eid.truthy, let kind = e["kind"], kind.truthy else { rejected += 1; continue }
            if events.contains(where: { $0["id"] == eid }) { rejected += 1; continue }
            if !parts[i].owner && !ShareCore.can(parts[i].role, kind.jsString) { rejected += 1; continue }
            seq += 1
            let ts: JSON = (e["ts"]?.truthy ?? false) ? e["ts"]! : .string(nowISO())
            events.append(["seq": .number(Double(seq)), "id": eid, "actor": .string(parts[i].id), "kind": .string(Guard.sstr(kind, 24)),
                           "payload": ShareCore.whitelist(e["payload"]), "ts": ts, "at": .string(nowISO())])
            accepted += 1
        }
        return ["ok": true, "accepted": .number(Double(accepted)), "rejected": .number(Double(rejected)), "seq": .number(Double(seq)),
                "status": .string(status), "server_time": .string(nowISO())]
    }
    public func revoke(pid: String?) -> JSON {
        guard let i = parts.firstIndex(where: { $0.id == pid && !$0.owner }) else { return ["ok": false] }
        parts[i].revoked = true
        return ["ok": true]
    }
    public func setRole(pid: String?, role: String?) -> JSON {
        guard let i = parts.firstIndex(where: { $0.id == pid }) else { return ["ok": false] }
        parts[i].role = Guard.sstr(role.map { .string($0) }, 24)
        return ["ok": true]
    }
    @discardableResult public func end() -> JSON { status = "ended"; return ["ok": true] }
}

// MARK: - Servir le hub sur un canal (`slServe`)

@MainActor
public enum ShareRPCServer {
    /// Trame reçue → verbe du hub → réponse. Jamais d'exception ; verbe inconnu → `e:'verbe'`,
    /// paramètres illisibles → `e:'hub'`. Les trames sans `n` (réponses, bouée) sont ignorées.
    public static func serve(_ hub: ShareHub, on wire: ShareWire) {
        wire.onMessage = { [weak hub, weak wire] txt in
            guard let hub, let wire, let m = ShareRPC.unpack(txt), let n = m["n"], n.truthy else { return }
            let id = m["i"]!
            let p = m["p"]
            let r: JSON
            func str(_ v: JSON?) -> String? { v?.string }
            switch n.jsString {
            case "join": r = hub.join(label: p?["label"].flatMap { $0.isNull ? nil : $0.jsString })
            case "pull", "push", "revoke", "setRole":
                guard let p, p.object != nil else { wire.send(ShareRPC.reply(id, result: nil, error: "hub")); return }
                switch n.jsString {
                case "pull": r = hub.pull(secret: str(p["secret"]), since: ShareJS.num0(p["since"]))
                case "push": r = hub.push(secret: str(p["secret"]), events: p["events"]?.array ?? [])
                case "revoke": r = hub.revoke(pid: str(p["pid"]))
                default: r = hub.setRole(pid: str(p["pid"]), role: p["role"].map { $0.jsString })
                }
            case "end": r = hub.end()
            default: wire.send(ShareRPC.reply(id, result: nil, error: "verbe")); return
            }
            wire.send(ShareRPC.reply(id, result: r))
        }
    }
}

// MARK: - Couture de l'hôte sur son propre hub (`slHostIo`)

/// L'hôte cloud n'a pas de secret : `secret == nil` désigne ici le secret d'hôte du hub, et
/// `open` rend la forme qu'attend `host()` avec `share:'local'` — le marqueur « hôte en direct ».
@MainActor
public final class ShareHostIO: ShareIO {
    public nonisolated var kind: ShareIOKind { .hostHub }
    public let hub: ShareHub
    let clock: () -> Double
    public static let localShare = "local"
    public init(hub: ShareHub, clock: @escaping () -> Double = JS.now) { self.hub = hub; self.clock = clock }
    public func open(id: String, sessionId: String, ficheId: String, snap: JSON, guestRole: String, ttlMin: Int) async throws -> JSON {
        ["ok": true, "share": .string(Self.localShare), "code": .null, "join_open_until": .null, "expires_at": .null,
         "server_time": .string(ShareJS.isoString(clock()))]
    }
    public func admit(share: String, seconds: Int) async throws -> JSON { ["ok": true] }
    public func join(code: String, label: String) async throws -> JSON { ["ok": false, "err": "local"] }
    public func pull(secret: String?, share: String?, since: Int) async throws -> JSON { hub.pull(secret: secret ?? hub.hostSecret, since: Double(since)) }
    public func push(secret: String?, share: String?, events: [JSON]) async throws -> JSON { hub.push(secret: secret ?? hub.hostSecret, events: events) }
    public func revoke(share: String, pid: String) async throws -> JSON { hub.revoke(pid: pid) }
    public func setRole(share: String, pid: String, role: String) async throws -> JSON { hub.setRole(pid: pid, role: role) }
    public func end(share: String) async throws -> JSON { hub.end() }
}

// MARK: - Client RPC de l'invité (`slClient`)

/// La couture `_io` ENTIÈRE, servie par le hub d'en face à travers le canal. Chaque appel a
/// 8 s pour répondre (`Error('timeout')` → un cycle raté, comme une panne réseau).
@MainActor
public final class ShareRPCClient: ShareIO {
    public nonisolated var kind: ShareIOKind { .rpcClient }
    let wire: ShareWire
    let env: ShareEnvironment
    let timeoutMs: Double
    var n = 0
    var pending: [Int: (CheckedContinuation<JSON, Error>, ShareTimer?)] = [:]

    public init(wire: ShareWire, env: ShareEnvironment, timeoutMs: Double = ShareRPC.timeoutMs) {
        self.wire = wire; self.env = env; self.timeoutMs = timeoutMs
        wire.onMessage = { [weak self] txt in self?.receive(txt) }
    }
    func receive(_ txt: String) {
        guard let m = ShareRPC.unpack(txt), !(m["n"]?.truthy ?? false), let i = m["i"]?.number,
              let w = pending.removeValue(forKey: Int(i)) else { return }
        w.1?.cancel()
        if let e = m["e"] { w.0.resume(throwing: ShareError.transport(e.jsString)) } else { w.0.resume(returning: m["r"] ?? .null) }
    }
    public func call(_ name: String, _ params: JSON) async throws -> JSON {
        n += 1
        let id = n
        return try await withCheckedThrowingContinuation { cont in
            let t = env.schedule(afterMs: timeoutMs) { [weak self] in
                if let w = self?.pending.removeValue(forKey: id) { w.0.resume(throwing: ShareError.timeout) }
            }
            pending[id] = (cont, t)
            wire.send(ShareRPC.pack(id, name, params))
        }
    }
    static func opt(_ s: String?) -> JSON { s.map { .string($0) } ?? .null }
    public func open(id: String, sessionId: String, ficheId: String, snap: JSON, guestRole: String, ttlMin: Int) async throws -> JSON {
        throw ShareError.refused("local : open est le geste de l’hôte")
    }
    public func admit(share: String, seconds: Int) async throws -> JSON { ["ok": true] }
    public func join(code: String, label: String) async throws -> JSON { try await call("join", ["label": .string(label)]) }
    public func pull(secret: String?, share: String?, since: Int) async throws -> JSON {
        try await call("pull", ["secret": Self.opt(secret), "since": .number(Double(since))])
    }
    public func push(secret: String?, share: String?, events: [JSON]) async throws -> JSON {
        try await call("push", ["secret": Self.opt(secret), "events": .array(events)])
    }
    public func revoke(share: String, pid: String) async throws -> JSON { try await call("revoke", ["pid": .string(pid)]) }
    public func setRole(share: String, pid: String, role: String) async throws -> JSON { try await call("setRole", ["pid": .string(pid), "role": .string(role)]) }
    public func end(share: String) async throws -> JSON { try await call("end", [:]) }
}
