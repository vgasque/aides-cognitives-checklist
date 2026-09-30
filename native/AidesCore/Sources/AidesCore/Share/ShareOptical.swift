import Foundation

/* PARTAGE « PAR L'ÉCRAN » — le canal du ZÉRO réseau (port de la section optique de la PWA).
 *
 * ═══ COMMENT LE WEB RÉALISE « PAR L'ÉCRAN » ═════════════════════════════════════════════════
 * Aucune radio : un écran montre une BOUCLE de codes QR binaires (6 par seconde), l'autre la
 * filme. La charge — un INSTANTANÉ DATÉ de la session, pas du direct — est :
 *   1. un JSON {sess, fiche, at, snap} (hôte → invité) ou {sess, at, ret} (retour de l'invité :
 *      ses repères datés SEULEMENT — jamais une coche) ;
 *   2. compressé en DEFLATE BRUT (`CompressionStream('deflate-raw')`) ;
 *   3. découpé par un code FONTAINE (Luby Transform, soliton robuste, variante SYSTÉMATIQUE) :
 *      k blocs de 195 octets montrés dans l'ordre, puis ⌈k/4⌉ réparations (XOR de blocs tirés
 *      par un PRNG mulberry32 graine+indice), les indices de réparation ne se répétant jamais ;
 *   4. chaque trame = 18 octets d'en-tête [0xF7, type, graine u32 LE, indice u24 LE, k u16 LE,
 *      taille u24 LE, 4 premiers octets du SHA-256 de la charge] + 195 octets = 213 octets,
 *      soit EXACTEMENT un QR version 10, correction M, mode octet (masque 4 figé côté web).
 * Le récepteur « épluche » (peeling decoder) : n'importe quelle trame l'initialise, une graine
 * nouvelle signale un émetteur redémarré, la jauge ne fait que monter.
 *
 * Le natif reprend ici TOUT le protocole, au bit près (PRNG et CDF vérifiés contre la PWA) :
 * trames, émetteur, récepteur, emballage, règles d'acceptation, et le routage d'un code scanné
 * (trame optique / offre directe / code en ligne). Restent à l'app : afficher un QR binaire
 * (CoreImage `CIQRCodeGenerator`, `inputMessage` = les 213 octets, correction « M ») et DÉCODER
 * un QR binaire (la chaîne d'`AVMetadataMachineReadableCodeObject` est texte et perd les octets :
 * passer par `CIQRCodeDescriptor.errorCorrectedPayload` ou Vision `VNBarcodeObservation
 * .payloadData`, puis extraire le segment « mode octet » — cf. spec E § 21 Q11).
 */

public enum ShareFountain {
    public static let blockSize = 195          // LT_CH
    public static let magic: UInt8 = 0xF7      // LT_MAGIC
    public static let headerSize = 18
    public static let frameSize = 213
    /// 6 codes par seconde (`setInterval(paint, Math.round(1000/6))`).
    public static let frameIntervalMs: Double = 167
    public static let typeSnapshot: UInt8 = 0, typeReturn: UInt8 = 1

    /// `ltMulberry(a)` — mulberry32, arithmétique 32 bits exacte.
    public struct Mulberry {
        var a: UInt32
        public init(_ seed: UInt32) { a = seed }
        public mutating func next() -> Double {
            a = a &+ 0x6D2B79F5
            var t = (a ^ (a >> 15)) &* (1 | a)
            t = (t &+ ((t ^ (t >> 7)) &* (61 | t))) ^ t
            return Double(t ^ (t >> 14)) / 4294967296
        }
    }

    /// `Math.log` de V8 — portage À L'IDENTIQUE de `__ieee754_log` de fdlibm (V8 `base::ieee754::log`).
    ///
    /// POURQUOI PAS `Foundation.log` : la libm de la plateforme (glibc, Darwin) n'arrondit pas
    /// forcément comme fdlibm — mesuré : ln(74) diffère d'UN ulp entre glibc et V8, ce qui décale
    /// la CDF de k = 37 et peut, à la frontière, changer le DEGRÉ d'une trame de réparation. Un
    /// émetteur et un récepteur doivent tirer les MÊMES ensembles de blocs : le moindre écart
    /// d'arrondi casse l'interopérabilité de la fontaine. Vérifié contre la PWA pour k = 1…3000.
    public static func v8Log(_ x0: Double) -> Double {
        let ln2Hi = 6.93147180369123816490e-01, ln2Lo = 1.90821492927058770002e-10, two54 = 1.80143985094819840000e+16
        let Lg1 = 6.666666666666735130e-01, Lg2 = 3.999999999940941908e-01, Lg3 = 2.857142874366239149e-01,
            Lg4 = 2.222219843214978396e-01, Lg5 = 1.818357216161805012e-01, Lg6 = 1.531383769920937332e-01,
            Lg7 = 1.479819860511658591e-01
        var x = x0
        var hx = Int32(truncatingIfNeeded: Int64(bitPattern: x.bitPattern) >> 32)
        let lx = UInt32(truncatingIfNeeded: x.bitPattern)
        var k: Int32 = 0
        if hx < 0x00100000 {
            if ((hx & 0x7fffffff) | Int32(bitPattern: lx)) == 0 { return -.infinity }
            if hx < 0 { return .nan }
            k -= 54; x *= two54
            hx = Int32(truncatingIfNeeded: Int64(bitPattern: x.bitPattern) >> 32)
        }
        if hx >= 0x7ff00000 { return x + x }
        k += (hx >> 20) - 1023
        hx &= 0x000fffff
        let i0 = (hx &+ 0x95f64) & 0x100000
        let hiWord = UInt64(UInt32(bitPattern: hx | (i0 ^ 0x3ff00000)))
        x = Double(bitPattern: (hiWord << 32) | (x.bitPattern & 0xffff_ffff))
        k += i0 >> 20
        let f = x - 1.0
        if (0x000fffff & (2 &+ hx)) < 3 {
            if f == 0 { if k == 0 { return 0 }; let dk = Double(k); return dk * ln2Hi + dk * ln2Lo }
            let R = f * f * (0.5 - 0.33333333333333333 * f)
            if k == 0 { return f - R }
            let dk = Double(k)
            return dk * ln2Hi - ((R - dk * ln2Lo) - f)
        }
        let s = f / (2.0 + f)
        let dk = Double(k)
        let z = s * s
        var i = hx &- 0x6147a
        let w = z * z
        let j = 0x6b851 &- hx
        let t1 = w * (Lg2 + w * (Lg4 + w * Lg6))
        let t2 = z * (Lg1 + w * (Lg3 + w * (Lg5 + w * Lg7)))
        i |= j
        let R = t2 + t1
        if i > 0 {
            let hfsq = 0.5 * f * f
            if k == 0 { return f - (hfsq - s * (hfsq + R)) }
            return dk * ln2Hi - ((hfsq - (s * (hfsq + R) + dk * ln2Lo)) - f)
        }
        if k == 0 { return f - s * (f - R) }
        return dk * ln2Hi - ((s * (f - R) - dk * ln2Lo) - f)
    }

    /// `ltCdf(k)` — fonction de répartition du soliton robuste (c = 0,1, δ = 0,5).
    public static func cdf(_ k: Int) -> [Double] {
        if k <= 0 { return [0] }
        if k == 1 { return [0, 1] }
        let kd = Double(k), c = 0.1, delta = 0.5
        let R = max(1, c * v8Log(kd / delta) * kd.squareRoot())
        let kR = max(2, Int(JS.round(kd / R)))
        var w = [Double](repeating: 0, count: k + 1)
        var Z = 0.0
        if k >= 1 {
            for d in 1...k {
                let dd = Double(d)
                let rho = d == 1 ? 1 / kd : 1 / (dd * (dd - 1))
                let tau = d < kR ? R / (dd * kd) : (d == kR ? R * v8Log(R / delta) / kd : 0)
                w[d] = rho + tau; Z += w[d]
            }
        }
        var out = [0.0], acc = 0.0
        if k >= 1 { for d in 1...k { acc += w[d] / Z; out.append(acc) } }
        return out
    }

    /// `ltIndices(seed, i, k, cdf)` — blocs combinés dans la trame d'indice `i`.
    public static func indices(seed: UInt32, i: Int, k: Int, cdf: [Double]) -> [Int] {
        if i < k { return [i] }
        var rng = Mulberry(seed ^ (UInt32(truncatingIfNeeded: i + 1) &* 0x9E3779B9))
        let r = rng.next()
        var d = 1
        while d < cdf.count - 1 && r > cdf[d] { d += 1 }
        d = min(d, k)
        var set: [Int] = []
        while set.count < d {
            let j = Int((rng.next() * Double(k)).rounded(.down))
            if !set.contains(j) { set.append(j) }
        }
        return set
    }

    /// Une trame décodée (`ltParse`).
    public struct Frame: Equatable, Sendable {
        public var type: UInt8, seed: UInt32, i: Int, k: Int, z: Int, h4: [UInt8], d: [UInt8]
    }
    public static func parse(_ bin: [UInt8]) -> Frame? {
        guard bin.count == frameSize, bin[0] == magic else { return nil }
        let seed = UInt32(bin[2]) | UInt32(bin[3]) << 8 | UInt32(bin[4]) << 16 | UInt32(bin[5]) << 24
        return Frame(type: bin[1], seed: seed, i: Int(bin[6]) | Int(bin[7]) << 8 | Int(bin[8]) << 16,
                     k: Int(bin[9]) | Int(bin[10]) << 8, z: Int(bin[11]) | Int(bin[12]) << 8 | Int(bin[13]) << 16,
                     h4: Array(bin[14..<18]), d: Array(bin[18...]))
    }

    // MARK: Émetteur (`ltTx` + `ltFrame`)

    /// Émetteur : la charge compressée, découpée ; `frame(at:)` rend la trame de la position
    /// d'affichage (k blocs dans l'ordre, puis ⌈k/4⌉ réparations à indices toujours neufs).
    public final class Transmitter {
        public let type: UInt8, seed: UInt32, k: Int, z: Int, h4: [UInt8], cycle: Int
        let blocks: [[UInt8]], cdfv: [Double]
        var iRep: Int
        public init(payload: [UInt8], type: UInt8, seed: UInt32? = nil) {
            self.type = type
            self.seed = seed ?? UInt32.random(in: 0...UInt32.max)
            let k = (payload.count + blockSize - 1) / blockSize
            self.k = k; z = payload.count
            var bl: [[UInt8]] = []
            for j in 0..<k {
                var b = [UInt8](repeating: 0, count: blockSize)
                let s = j * blockSize, e = min((j + 1) * blockSize, payload.count)
                b.replaceSubrange(0..<(e - s), with: payload[s..<e])
                bl.append(b)
            }
            blocks = bl; cdfv = ShareFountain.cdf(k)
            h4 = Array(ShareSHA256.digest(payload).prefix(4))
            cycle = k + max(1, (k + 3) / 4)
            iRep = k
        }
        /// `ltFrame(p, i)`.
        public func frame(index i: Int) -> [UInt8] {
            var f = [UInt8](repeating: 0, count: frameSize)
            f[0] = magic; f[1] = type
            f[2] = UInt8(seed & 0xff); f[3] = UInt8((seed >> 8) & 0xff); f[4] = UInt8((seed >> 16) & 0xff); f[5] = UInt8(seed >> 24)
            f[6] = UInt8(i & 0xff); f[7] = UInt8((i >> 8) & 0xff); f[8] = UInt8((i >> 16) & 0xff)
            f[9] = UInt8(k & 0xff); f[10] = UInt8((k >> 8) & 0xff)
            f[11] = UInt8(z & 0xff); f[12] = UInt8((z >> 8) & 0xff); f[13] = UInt8((z >> 16) & 0xff)
            for j in 0..<4 { f[14 + j] = h4[j] }
            for j in ShareFountain.indices(seed: seed, i: i, k: k, cdf: cdfv) {
                for x in 0..<blockSize { f[headerSize + x] ^= blocks[j][x] }
            }
            return f
        }
        /// `frameAt(pos)` — AVEC ÉTAT (les réparations ne se répètent jamais d'un cycle à l'autre).
        public func frame(at pos: Int) -> [UInt8] {
            let m = pos % cycle
            if m < k { return frame(index: m) }
            defer { iRep += 1 }
            return frame(index: iRep)
        }
    }

    // MARK: Récepteur (`ltRx` / `ltRxFeed` / `ltRxBytes`)

    public enum Feed: Equatable, Sendable { case ignored, dup, more, done }

    /// Récepteur par épluchage. `progress` (0…1) alimente la jauge, qui ne fait que monter.
    public final class Receiver {
        var seen = Set<String>()
        public private(set) var seed: UInt32?
        public private(set) var type: UInt8 = 0
        public private(set) var k = 0, z = 0, nRec = 0
        public private(set) var h4: [UInt8] = []
        var cdfv: [Double] = []
        var rec: [[UInt8]?] = []
        var pend: [(idx: Set<Int>, d: [UInt8])] = []
        public init() {}
        public var progress: Double { k > 0 ? Double(nRec) / Double(k) : (seed != nil ? 1 : 0) }
        public var isStarted: Bool { seed != nil }

        public func feed(_ bin: [UInt8]) -> Feed {
            guard let bf = ShareFountain.parse(bin) else { return .ignored }
            let key = "\(bf.seed):\(bf.i)"
            if seen.contains(key) { return .dup }
            seen.insert(key)
            if seed != bf.seed {   // première trame OU émetteur redémarré
                seed = bf.seed; type = bf.type; k = bf.k; z = bf.z; h4 = bf.h4
                cdfv = ShareFountain.cdf(bf.k); rec = [[UInt8]?](repeating: nil, count: bf.k); nRec = 0; pend = []
            }
            if nRec == k { return .done }
            var idx = Set(ShareFountain.indices(seed: bf.seed, i: bf.i, k: k, cdf: cdfv))
            var d = Array(bf.d.prefix(blockSize))
            for j in idx where j < rec.count { if let r = rec[j] { xor(&d, r); idx.remove(j) } }
            if idx.count == 1 { let j = idx.first!; if j < rec.count, rec[j] == nil { rec[j] = d; nRec += 1 } }
            else if idx.count > 1 { pend.append((idx, d)) }
            var again = true
            while again {
                again = false
                var p = pend.count - 1
                while p >= 0 {
                    var f = pend[p]
                    for q in f.idx where q < rec.count { if let r = rec[q] { xor(&f.d, r); f.idx.remove(q) } }
                    pend[p] = f
                    if f.idx.count <= 1 {
                        pend.remove(at: p)
                        if f.idx.count == 1 { let j = f.idx.first!; if j < rec.count, rec[j] == nil { rec[j] = f.d; nRec += 1; again = true } }
                    }
                    p -= 1
                }
            }
            return nRec == k ? .done : .more
        }
        func xor(_ a: inout [UInt8], _ b: [UInt8]) { for x in 0..<min(a.count, b.count) { a[x] ^= b[x] } }
        /// `ltRxBytes` : blocs concaténés, tronqués à la taille annoncée.
        public func bytes() -> [UInt8]? {
            guard seed != nil, nRec == k else { return nil }
            var all: [UInt8] = []
            for r in rec { all += r ?? [] }
            return Array(all.prefix(z))
        }
        /// Le préfixe SHA-256 annoncé correspond-il ? (La PWA ne le vérifie pas — spec § 20.6 ;
        /// ses émetteurs le posent correctement, le natif peut donc l'exiger.)
        public var h4Matches: Bool {
            guard let b = bytes() else { return false }
            return Array(ShareSHA256.digest(b).prefix(4)) == h4
        }
    }
}

// MARK: - Charges optiques (`ltSnapPack`, `ltRetPack`, `ltSnapUnpack`)

public enum ShareOptical {
    /// Borne de décompression : le flux d'un QR hostile s'annule au dépassement.
    public static let maxInflate = 4_194_304

    /// Instantané : {sess, fiche (projection `sharePayload`), at (heure d'émission, `Share.now()`), snap}.
    public static func packSnapshot(sess: String, fiche: JSON, at: Double, snap: JSON) -> [UInt8] {
        ShareDeflate.deflate(Array(JSON.object(["sess": .string(sess), "fiche": fiche, "at": .number(at), "snap": snap]).data()))
    }
    /// Retour : {sess, at, ret} — les repères datés, jamais une coche.
    public static func packReturn(sess: String, at: Double, events: [JSON]) -> [UInt8] {
        let ret: [JSON] = events.map { e in
            var o: [String: JSON] = ["t": e["t"] ?? .null, "ref": ShareCore.orNull(e["ref"]), "voidAt": ShareCore.orNull(e["voidAt"])]
            if let id = e["id"] { o["id"] = id }
            return .object(o)
        }
        return ShareDeflate.deflate(Array(JSON.object(["sess": .string(sess), "at": .number(at), "ret": .array(ret)]).data()))
    }
    /// Déballe une charge : nil si illisible, trop grosse, sans `at` numérique, ou sans
    /// (`ret` tableau | `snap` et `fiche`).
    public static func unpack(_ bytes: [UInt8]) -> JSON? {
        guard let raw = try? ShareDeflate.inflate(bytes, limit: maxInflate), let o = try? JSON.parse(Data(raw)),
              o.object != nil, o["at"]?.number != nil else { return nil }
        if o["ret"]?.array != nil { return o }
        if ShareJS.truthy(o["snap"]) && ShareJS.truthy(o["fiche"]) { return o }
        return Optional<JSON>.none
    }

    /// Émetteur prêt à l'emploi.
    public static func transmitter(payload: [UInt8], isReturn: Bool, seed: UInt32? = nil) -> ShareFountain.Transmitter {
        ShareFountain.Transmitter(payload: payload, type: isReturn ? ShareFountain.typeReturn : ShareFountain.typeSnapshot, seed: seed)
    }

    // MARK: Règles d'acceptation (`slOptiqueGot`)

    public enum SnapshotDecision: Equatable, Sendable { case accept, refuse(String) }

    /// Un INSTANTANÉ n'entre que si cet appareil n'a pas de session à l'écran, ou s'il reflète
    /// DÉJÀ cette session (miroir, ou invité en ligne/direct qui l'a apprise par `session_start`).
    /// Sinon : un message, ZÉRO écriture.
    public static func acceptSnapshot(sess: String, deviceHasStartedRuntime: Bool, mirrorSess: String?, guestFoldSessId: String?) -> SnapshotDecision {
        let followed = (mirrorSess != nil && mirrorSess == sess) || (guestFoldSessId != nil && guestFoldSessId == sess)
        if deviceHasStartedRuntime && !followed { return .refuse(ShareStrings.opticOtherSession) }
        return .accept
    }
    /// Un RETOUR n'annote que la session VIVE de cet appareil.
    public static func acceptReturn(sess: String, localSessionId: String?) -> Bool {
        guard let l = localSessionId, !l.isEmpty else { return false }
        return l == sess
    }
    /// Évènements synthétisés d'un retour (acteur « optique ») : `mark`, et `mark_void` si annulé.
    /// À passer aux appliqueurs d'état (upsert par id : re-scanner ne duplique rien).
    public static func returnEvents(_ ret: [JSON]) -> [JSON] {
        var out: [JSON] = []
        for e in ret {
            guard e.truthy, let id = e["id"], id.truthy else { continue }
            out.append(["kind": "mark", "actor": "optique",
                        "payload": ["id": .string(id.jsString), "t": .number(ShareJS.num0(e["t"])), "ref": ShareCore.orNull(e["ref"])]])
            if ShareJS.truthy(e["voidAt"]) {
                out.append(["kind": "mark_void", "actor": "optique",
                            "payload": ["id": .string(id.jsString), "on": true, "t": .number(ShareJS.num0(e["voidAt"]))]])
            }
        }
        return out
    }
    /// Pli d'un miroir reçu : l'instantané assaini (`slFoldSan`), puis — chez un invité en
    /// ligne — sa propre file non transmise repliée par-dessus (acteur = lui-même).
    public static func mirrorFold(snap: JSON?, guestQueue: [JSON] = [], me: String? = nil) -> JSON {
        var fold = ShareCore.foldSan(snap)
        if !guestQueue.isEmpty {
            let evs: [JSON] = guestQueue.map { e in
                var o = e.object ?? [:]
                o["actor"] = me.map { .string($0) } ?? .null
                return .object(o)
            }
            fold = ShareCore.fold(evs, base: fold)
        }
        return fold
    }
    /// Identité de session montrée par CET appareil : sa session locale, sinon celle qu'il
    /// reflète (miroir), sinon celle apprise en ligne (`fold.sessId`).
    public static func sessionIdentity(localSessionId: String?, mirrorSess: String?, foldSessId: String?) -> String {
        for s in [localSessionId, mirrorSess, foldSessId] { if let s, !s.isEmpty { return s } }
        return ""
    }
}

// MARK: - Routage d'un code scanné (écran d'entrée : « c'est le format qui décide »)

public enum ShareScan {
    public enum Kind: Equatable, Sendable {
        case opticalFrame               // trame fontaine binaire (0xF7)
        case directOffer(SharePairing)  // « SO:… »
        case directAnswer(SharePairing) // « SA:… »
        case cloudCode(String)          // lien `#j=CODE` ou code nu, normalisé
        case unreadable(String)         // « SO: »/« SA: » illisible
        case unknown
    }
    /// Classe un QR décodé (texte et/ou octets bruts).
    public static func classify(text: String?, binary: [UInt8]?) -> Kind {
        if let b = binary, let f = b.first, f == ShareFountain.magic { return .opticalFrame }
        let t = text ?? ""
        if t.hasPrefix(SharePairing.offerPrefix) {
            return SharePairing.unpack(String(t.dropFirst(3))).map { .directOffer($0) } ?? .unreadable(ShareStrings.codeIllisible)
        }
        if t.hasPrefix(SharePairing.answerPrefix) {
            return SharePairing.unpack(String(t.dropFirst(3))).map { .directAnswer($0) } ?? .unreadable(ShareStrings.codeIllisible)
        }
        // `/#j=([0-9A-Za-z-]+)/` puis normalisation.
        var cand = t
        if let r = t.range(of: "#j=") {
            let m = String(t[r.upperBound...].prefix { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") })
            if !m.isEmpty { cand = m }
        }
        let c = ShareCode.norm(cand)
        return ShareCode.isValid(c) ? .cloudCode(c) : .unknown
    }
}
