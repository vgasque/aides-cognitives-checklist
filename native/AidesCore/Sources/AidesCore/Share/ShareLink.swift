import Foundation

/* PARTAGE — LES BASCULES ENTRE TRANSPORTS (port de `slSb`, `slLink`, `slSbFail`,
 * `slSbHostSwitch`, `slSbGuestSwitch`, `slGoCloud`, `slGcJoin`, `slResumeCloud`, `slHostRehost`,
 * `slBackTick`, `slWake`, `slSbGuestKick`, `slSbOnSig`, `slOffer`/`slGuestUp`).
 *
 * Le maître mot de l'auteur : SEAMLESS. Le partage passe tout seul du serveur au direct quand
 * le réseau lâche (≤ 5 s : la sonde tranche au premier raté), et revient seul quand internet
 * revient (3 sondes OK et ≥ 60 s en direct, hystérésis doublée à chaque retour) — jamais contre
 * un choix manuel, jamais en ouvrant une fenêtre (règle 11). Chaque transition se DIT : un mot
 * de 8 s au quai (`say`) et une ligne au journal du lien (5 dernières, en mémoire).
 *
 * Tout ce qui touche la pile WebRTC passe par `ShareDirectStack` (protocole) : sans pile
 * (aucune pile WebRTC native n'est livrée — cf. ShareLocal.swift), le secours chaud ne se forme
 * pas et seules les bascules sans canal (reprise du cloud, par l'écran) opèrent. Avec une pile
 * (libwebrtc pour interopérer avec le web, ou MultipeerConnectivity entre natifs), tout ce
 * fichier s'applique tel quel.
 */

// MARK: - Contrat de la pile directe (WebRTC ou autre)

/// Canal de données : texte seul, ordonné, fiable (`RTCDataChannel` « ac »).
@MainActor
public protocol ShareDataChannel: ShareWire {
    var isOpen: Bool { get }
    var onOpen: (() -> Void)? { get set }
    var onClose: (() -> Void)? { get set }
    func close()
}
/// Côté qui OFFRE (crée le canal) — `slPcHost`.
@MainActor
public protocol ShareDirectOffer: AnyObject {
    var quintuple: ShareSDPQuintuple { get }
    var channel: ShareDataChannel { get }
    func accept(answer: ShareSDPQuintuple) async throws
    func close()
}
/// Côté qui RÉPOND (reçoit le canal) — `slPcGuest`. Le canal arrive par `onChannel`.
@MainActor
public protocol ShareDirectAnswer: AnyObject {
    var quintuple: ShareSDPQuintuple { get }
    var onChannel: ((ShareDataChannel) -> Void)? { get set }
    func close()
}
/// La pile : `iceServers: []`, non-trickle (5 s au plus), réponse en `a=setup:active`.
@MainActor
public protocol ShareDirectStack: AnyObject {
    func makeOffer() async throws -> ShareDirectOffer
    func makeAnswer(to offer: ShareSDPQuintuple) async throws -> ShareDirectAnswer
}

/// Ce que l'app expose de la session partagée (côté hôte) et du compte.
@MainActor
public protocol ShareSessionSource: AnyObject {
    /// La fiche de la session hébergée (brute ; la projection est faite ici).
    var sharedFiche: JSON? { get }
    /// Identifiant local de la session (identité optique, `session_start.id`).
    var sharedSessionId: String? { get }
    /// Instantané de la session démarrée (`ShareCore.snap`) ; nil si aucune session n'est démarrée.
    func sharedSnapshot() -> JSON?
    /// Compte connecté ET approuvé (seul l'hôte « en ligne » en a besoin).
    var signedIn: Bool { get }
}

// MARK: - État du lien (`slLink`)

public struct ShareLinkState: Equatable, Sendable {
    public enum Why: String, Sendable { case net, canal, expired }
    public var lost: Bool
    public var why: Why?
    public var since: Double
    public var hostQuiet: Bool
    public var hostSince: Double
    public static let ok = ShareLinkState(lost: false, why: nil, since: 0, hostQuiet: false, hostSince: 0)
}

// MARK: - Le coordinateur

@MainActor
public final class ShareLinkCoordinator {
    // Constantes (spec E § 2)
    nonisolated public static let sayMs: Double = 8000
    nonisolated public static let logMax = 5
    nonisolated public static let kickWatchdogMs: Double = 30000
    nonisolated public static let goDirectEndDelayMs: Double = 12000
    nonisolated public static let switchTries = 3
    nonisolated public static let switchGapMs: Double = 2000
    nonisolated public static let admitWaitMs: Double = 15000
    nonisolated public static let admitPollMs: Double = 500
    nonisolated public static let hubLingerMs: Double = 20000
    nonisolated public static let dwellMinMs: Double = 60000
    nonisolated public static let dwellMaxMs: Double = 600000
    nonisolated public static let hostLostAfterMs: Double = 15000
    nonisolated public static let probeFreshMs: Double = 30000
    nonisolated public static let okRunNeeded = 3

    public let engine: ShareEngine
    public let env: ShareEnvironment
    public weak var source: ShareSessionSource?
    public var stack: ShareDirectStack?
    /// La sonde de joignabilité (`ShareNetProbe.probe`) — injectée.
    public var probeFn: () async -> Bool
    /// La feuille de partage est-elle ouverte (la sonde veille alors en continu).
    public var sheetOpen: () -> Bool = { false }

    // Rappels vers l'interface (jamais une modale sur évènement distant)
    /// Reconstruire la session partagée À L'ÉCRAN si elle y est (`if(sharedShown())openSharedFiche()`).
    public var onRebuildShared: (() -> Void)?
    /// Repeindre ce qui dépend de l'état du lien (quai, bandeau, feuille).
    public var onChanged: (() -> Void)?
    /// Ouvrir la feuille de partage (retour en ligne NON silencieux).
    public var onOpenSheet: (() -> Void)?
    /// Message éphémère (toast).
    public var onToast: ((String) -> Void)?

    // État (`slSb`)
    public private(set) var hostDormant: [(actor: String, channel: ShareDataChannel)] = []
    public private(set) var guestDormant: ShareDataChannel?
    var guestOffer: (offer: ShareDirectOffer, k: String)?
    var kickLock = false
    public private(set) var auto = false
    /// « Par l'écran » : une COUCHE par-dessus le transport, jamais un transport.
    public var optic = false
    public private(set) var okRun = 0
    public private(set) var since: Double = 0
    public private(set) var log: [(t: Double, txt: String)] = []
    var sayState: (txt: String, until: Double)?
    var said = false
    /// Billet cloud de l'HÔTE passé en direct automatiquement (reprise du MÊME partage).
    public private(set) var cloudHost: ShareHostTicket?
    public private(set) var dwellMs: Double = ShareLinkCoordinator.dwellMinMs
    public private(set) var lastBack: Double = 0
    public private(set) var expired = false
    public private(set) var lostAt: Double = 0
    public private(set) var switching = false
    public private(set) var netOk: Bool?
    public private(set) var netAt: Double = 0
    var watch: ShareTimer?
    // Hub de l'hôte en direct (`SL`)
    public private(set) var hub: ShareHub?
    public private(set) var hubLive = false
    var pairing: (offer: ShareDirectOffer, k: String)?
    /// Connexions directes (offres/réponses) GARDÉES en vie tant que leur canal peut servir : une
    /// pile native (libwebrtc) ferme le canal quand sa `RTCPeerConnection` est libérée — le JS,
    /// lui, la garde par les fermetures de ses rappels.
    var retainedPeers: [AnyObject] = []
    /// Canaux SERVIS par le hub (`SL.wires`) : le serveur RPC ne les tient que faiblement.
    public private(set) var servedChannels: [ShareDataChannel] = []
    public enum PairPhase: String, Sendable { case offer, optic }
    public private(set) var pairPhase: PairPhase?

    public init(engine: ShareEngine, env: ShareEnvironment, source: ShareSessionSource?, stack: ShareDirectStack? = nil,
                probe: @escaping () async -> Bool) {
        self.engine = engine; self.env = env; self.source = source; self.stack = stack; self.probeFn = probe
    }

    // MARK: Mots et journal (`slSay`)

    /// Une transition se DIT : mot au quai 8 s, ligne au journal du lien, phrase au lecteur d'écran.
    public func say(_ word: String, _ sr: String? = nil) {
        sayState = (word, env.now() + Self.sayMs)
        log.insert((env.now(), word), at: 0)
        if log.count > Self.logMax { log.removeLast(log.count - Self.logMax) }
        engine.delegate?.share(engine, announce: sr ?? word)
        onChanged?()
    }
    /// Le mot du quai en cours (nil passé 8 s).
    public var sayWord: String? { (sayState.map { env.now() < $0.until ? $0.txt : nil }) ?? nil }
    func readySay() { if said { return }; said = true; say(ShareStrings.sayStandbyReady, ShareStrings.srStandbyReady) }

    /// `slSbReset` — ardoise propre (nouvelle participation, retour en ligne).
    public func reset() {
        guestOffer?.offer.close()
        for d in hostDormant { d.channel.close() }
        hostDormant = []; guestOffer = nil; guestDormant = nil; said = false; optic = false; kickLock = false
        retainedPeers = []
    }
    /// `slSbReady` : par RÔLE, et un canal mort n'est pas un canal.
    public var isReady: Bool {
        engine.mode == .host ? hostDormant.contains { $0.channel.isOpen } : (guestDormant?.isOpen ?? false)
    }
    public var liveOk: Bool { hubLive && hub != nil && engine.mode == .host && engine.status == "active" }

    // MARK: Sonde

    public func probe() async {
        let ok = await probeFn()
        netAt = env.now()
        if ok != netOk { netOk = ok; onChanged?() }
    }
    /// Veille de la sonde : toutes les 8 s tant que la feuille est ouverte ou que le retour est armé.
    public func startNetWatch() {
        watch?.cancel()
        func tick() {
            watch = env.schedule(afterMs: ShareNetProbe.periodMs) { [weak self] in
                guard let self else { return }
                if !self.sheetOpen() && !self.backArmed { self.watch = nil; return }
                Task { @MainActor in await self.probe(); await self.backTick() }
                tick()
            }
        }
        tick()
        Task { @MainActor in await self.probe() }
    }
    public var isWatching: Bool { watch != nil }
    /// Évènement système `offline` (+1,5 s, toujours hors ligne, partage cloud).
    public func systemOffline() async {
        netOk = false; onChanged?()
        if engine.mode != .off && engine.share != ShareHostIO.localShare { engine.markOffline(); await onCycleFailed() }
    }

    // MARK: État du lien (`slLink`) et couches

    public func link() -> ShareLinkState {
        guard engine.mode != .off, engine.status == "active" else { return .ok }
        if expired { return ShareLinkState(lost: true, why: .expired, since: lostAt != 0 ? lostAt : engine.lastOk, hostQuiet: false, hostSince: 0) }
        let direct = engine.isDirect, net = netOk == true
        var lost: Bool
        if engine.mode == .host {
            let vivid = engine.participants.contains { !ShareJS.truthy($0["owner"]) && !ShareJS.truthy($0["revoked"]) && engine.silenceMs($0) <= ShareEngine.seenQuietMs }
            lost = direct ? (auto && !net && env.now() - since > Self.hostLostAfterMs && !vivid) : (engine.fails >= 2 && hostDormant.isEmpty)
        } else {
            lost = direct ? (engine.fails >= 2 && !net) : (engine.fails >= 2 && guestDormant == nil)
        }
        let sil = (engine.mode == .guest && !direct && !lost) ? engine.hostSilenceMs : 0
        let quiet = sil > ShareEngine.seenQuietMs
        return ShareLinkState(lost: lost, why: direct ? .canal : .net, since: engine.lastOk, hostQuiet: quiet, hostSince: quiet ? env.now() - sil : 0)
    }
    /// `slOpticOn` (sans l'état miroir, tenu par l'app).
    public var opticOn: Bool { optic || pairPhase == .optic }
    /// Mot de la porte « Mode : … › ».
    public var modeWord: String {
        optic ? ShareStrings.modeWordForcedOptic : (engine.share == ShareHostIO.localShare && liveOk && !auto ? ShareStrings.modeWordForcedDirect : ShareStrings.modeWordAuto)
    }
    /// Transport en cours : 'direct' | 'cloud' | '' (« par l'écran » n'en est pas un).
    public var currentTransport: String {
        if (engine.mode == .host && engine.share == ShareHostIO.localShare) || (hub != nil && !hubLive) { return "direct" }
        return (engine.mode == .host && engine.status == "active") ? "cloud" : ""
    }

    // MARK: Détection de panne (`slSbFail`) — à appeler sur `shareCycleFailed`

    public func onCycleFailed() async {
        if switching || engine.mode == .off { return }
        if engine.isDirect {
            if engine.mode == .guest && engine.cloudGuestTicket != nil && engine.fails >= 2 {
                await probe()
                if netOk == true { _ = await resumeCloud() }
            }
            return
        }
        if engine.fails < 2 {
            if engine.fails == 1 {
                await probe()
                if netOk == false && engine.fails >= 1 { engine.markOffline(); await onCycleFailed() }
            }
            return
        }
        if engine.mode == .host && !hostDormant.isEmpty {
            if env.now() - lastBack > Self.dwellMaxMs { dwellMs = Self.dwellMinMs }
            auto = true
            await hostSwitch(say: nil)
        } else if engine.mode == .guest && guestDormant != nil {
            await guestSwitch()
        }
    }

    // MARK: Secours chaud — l'invité propose, l'hôte répond (`slSbGuestKick`, `slSbOnSig`)

    /// À appeler sur `shareCycleHealthy` : l'invité propose son canal dormant (jamais pendant une panne).
    public func guestKick() async {
        guard guestOffer == nil, guestDormant == nil, !kickLock, let stack, engine.mode == .guest else { return }
        kickLock = true
        defer { kickLock = false }
        guard let o = try? await stack.makeOffer() else { return }
        let k = SharePairing.newToken(env.random)
        guestOffer = (o, k)
        retainedPeers.append(o)
        let ch = o.channel
        ch.onOpen = { [weak self] in guard let self else { return }; self.guestDormant = ch; self.onChanged?(); self.readySay() }
        ch.onClose = { [weak self] in
            guard let self else { return }
            if self.guestDormant === ch { self.guestDormant = nil }
            if self.guestOffer?.offer === o { self.guestOffer = nil }
        }
        // LA BOUÉE : l'hôte a basculé en direct — suivre, même si notre relais répond encore.
        ch.onMessage = { [weak self] txt in
            guard let self, txt == ShareRPC.bouee, self.guestDormant === ch, self.engine.mode == .guest, self.engine.io.kind == .rest else { return }
            Task { @MainActor in await self.guestSwitch() }
        }
        if let pack = SharePairing(k: k, sdp: o.quintuple).pack() { engine.emit("sig", ["t": "o", "o": .string(pack)]) }
        env.schedule(afterMs: Self.kickWatchdogMs) { [weak self] in
            guard let self else { return }
            if self.guestDormant == nil, self.guestOffer?.offer === o { o.close(); self.guestOffer = nil }
        }
    }

    /// Évènements `sig` reçus (routés par le moteur, jamais à l'interface).
    public func onSignal(_ ev: JSON) async {
        let p = ev["payload"] ?? .object([:])
        let t = p["t"]?.string
        if engine.mode == .host && t == "o", let o = p["o"], o.truthy, !hubLive, let stack, let actor = ev["actor"]?.string {
            guard let off = SharePairing.unpack(o.jsString), let h = try? await stack.makeAnswer(to: off.sdp) else { return }
            retainedPeers.append(h)
            h.onChannel = { [weak self] ch in
                guard let self else { return }
                let go = {
                    self.hostDormant.append((actor, ch))
                    ch.onClose = { [weak self] in self?.hostDormant.removeAll { $0.channel === ch }; self?.onChanged?() }
                    self.onChanged?(); self.readySay()
                }
                if ch.isOpen { go() } else { ch.onOpen = go }
            }
            if let pack = SharePairing(k: off.k, sdp: h.quintuple).pack() { engine.emit("sig", ["t": "a", "to": .string(actor), "a": .string(pack)]) }
        } else if engine.mode == .guest && t == "a", p["to"]?.string == engine.me, let go = guestOffer, let a = p["a"], a.truthy {
            guard let ans = SharePairing.unpack(a.jsString), ans.k == go.k else { return }   // réponse d'une offre morte : ignorée
            try? await go.offer.accept(answer: ans.sdp)
        } else if engine.mode == .guest && t == "go" && guestDormant != nil {
            await guestSwitch()
        } else if engine.mode == .guest && t == "gc", p["to"]?.string == engine.me, let c = p["code"], c.truthy, engine.io.kind != .rest {
            await gcJoin(c.jsString)
        } else if engine.mode == .guest && t == "rc" && engine.cloudGuestTicket != nil && engine.io.kind != .rest {
            _ = await resumeCloud()
        }
    }

    // MARK: Bascules vers le direct

    /// `slSbHostSwitch` : le partage continue sur un hub servi par les canaux dormants ; la bouée
    /// fait suivre chaque invité apparié. Automatique : le billet cloud est gardé pour revenir.
    public func hostSwitch(say sr: String?) async {
        guard !switching else { return }
        switching = true
        defer { switching = false }
        guard let f = source?.sharedFiche, let snap = source?.sharedSnapshot() else { return }
        let dcs = hostDormant
        hostDormant = []; guestOffer = nil; guestDormant = nil
        if auto, let s = engine.share {
            cloudHost = ShareHostTicket(share: s, code: engine.code, joinUntil: engine.joinUntil, expiresAt: engine.expiresAt,
                                        cursor: engine.cursor, ficheId: f["id"]?.jsString ?? "")
        }
        let h = ShareHub.make(fiche: f, now: env.now)
        engine.stop()
        engine.setIO(ShareHostIO(hub: h, clock: env.now))
        hub = h; hubLive = true; pairPhase = nil
        let r = await engine.host(fiche: f, sessionId: source?.sharedSessionId, snapshot: snap)
        guard r["ok"]?.bool == true else { hub = nil; hubLive = false; return }
        servedChannels = dcs.map(\.channel)
        for d in dcs { ShareRPCServer.serve(h, on: d.channel) }
        for d in dcs { d.channel.send(ShareRPC.bouee) }
        say(ShareStrings.sayDirect, sr ?? ShareStrings.srNetDropped)
        if auto { since = env.now(); okRun = 0; startNetWatch() }
    }

    /// `slSbGoSwitch` (Mode « En direct » avec canaux prêts) : prévenir par `sig {t:'go'}` poussé
    /// DIRECTEMENT, basculer, puis terminer le partage cloud 12 s plus tard.
    public func goSwitch() async {
        auto = false; cloudHost = nil; engine.clearHostTicket()
        let oldShare = engine.share, rest = engine.restIO
        _ = await engine.pushDirect([engine.envelope("sig", ["t": "go"])])
        await hostSwitch(say: ShareStrings.srGoDirect)
        if let rest, let old = oldShare, old != ShareHostIO.localShare {
            env.schedule(afterMs: Self.goDirectEndDelayMs) { Task { _ = try? await rest.end(share: old) } }
        }
    }

    /// `slSbGuestSwitch` : rejoindre par le canal dormant (3 essais espacés de 2 s), la file NON
    /// transmise voyage avec l'invité (mêmes ids, mêmes clés). Échec : le canal est gardé.
    public func guestSwitch() async {
        guard !switching, let dc = guestDormant else { return }
        switching = true
        defer { switching = false }
        let lbl = myLabel()
        let carried = engine.queue
        if let s = engine.share, s != ShareHostIO.localShare, let k = engine.secret {
            engine.cloudGuestTicket = ShareGuestTicket(share: s, secret: k, me: engine.me, role: engine.role)
        }
        engine.setIO(ShareRPCClient(wire: dc, env: env))
        var ok = false
        for i in 0..<Self.switchTries where !ok {
            if i > 0 { await env.sleep(ms: Self.switchGapMs) }
            ok = ((try? await engine.joinByCode(ShareRPC.dummyCode, label: lbl))?["ok"]?.bool) == true
        }
        guard ok else { return }
        guestDormant = nil; guestOffer = nil
        engine.requeueFront(carried)
        onRebuildShared?()
        say(ShareStrings.sayFollowDirect, ShareStrings.srFollowDirect)
    }
    func myLabel() -> String {
        let l = engine.participants.first { $0["id"]?.string == engine.me }?["label"]?.string
        return (l?.isEmpty == false) ? l! : ShareStrings.defaultRole
    }

    // MARK: Retour en ligne (`slGoCloud`, `slGcJoin`, `slResumeCloud`, `slHostRehost`)

    public enum CloudOutcome: Equatable, Sendable {
        case ok
        /// Rien à migrer (pas de hub, ou hub sans invité et sans billet) : le partage direct est
        /// arrêté, l'app ouvre un partage en ligne NEUF (`startShare`).
        case freshShareNeeded
        /// Ouverture en ligne refusée : le partage est RE-HÉBERGÉ sur le même hub (personne
        /// n'est déconnecté) ; le message dit pourquoi.
        case failed(String)
        case busy
    }

    public func goCloud(sr: String? = nil, quiet: Bool = false) async -> CloudOutcome {
        let tk = cloudHost
        guard let h = hub, !(h.guests.isEmpty && tk == nil) else {
            await engine.endShare(); hub = nil; hubLive = false
            return .freshShareNeeded
        }
        guard !switching else { return .busy }
        guard let f = source?.sharedFiche, let snap = source?.sharedSnapshot() else { return .busy }
        switching = true
        defer { switching = false }
        let guests = h.guests
        let sid = source?.sharedSessionId
        engine.stop()
        engine.useRest()
        // Le MÊME partage d'abord : les gestes du direct rejoignent son journal (par lots de 50 —
        // la PWA les pousse d'un bloc, refusé `too_many` au-delà de 50 : écart corrigé ici).
        if let tk, await engine.rehost(tk, fiche: f, sessionId: sid, snapshot: snap) {
            let evs: [JSON] = h.events.map { e in
                ["event_id": e["id"] ?? .null, "kind": e["kind"] ?? .null, "payload": e["payload"] ?? .object([:]),
                 "ts": (e["ts"]?.truthy ?? false) ? e["ts"]! : .string(ShareJS.isoString(env.now()))]
            }
            var i = 0
            while i < evs.count { _ = await engine.pushDirect(Array(evs[i..<min(i + ShareEngine.maxBatch, evs.count)]), secret: nil); i += ShareEngine.maxBatch }
            _ = h.push(secret: h.hostSecret, events: [["event_id": .string(Guard.uid("e")), "kind": "sig", "payload": ["t": "rc"],
                                                       "ts": .string(ShareJS.isoString(env.now()))]])
            hub = nil; hubLive = false; reset(); engine.kick(0)
            let served = servedChannels; servedChannels = []
            env.schedule(afterMs: Self.hubLingerMs) { h.end(); _ = served }
            cloudHost = nil
            if !quiet { onOpenSheet?() }
            onChanged?()
            say(ShareStrings.sayBackOnline, sr ?? ShareStrings.srBackOnlineGeneric)
            return .ok
        }
        let r = await engine.host(fiche: f, sessionId: sid, snapshot: snap)
        guard r["ok"]?.bool == true else {
            engine.setIO(ShareHostIO(hub: h, clock: env.now))
            _ = await engine.host(fiche: f, sessionId: sid, snapshot: snap)
            hubLive = true
            let msg = r["err"]?.string == "draft" ? ShareStrings.draftRefused : ShareStrings.staysDirect
            onToast?(msg)
            return .failed(msg)
        }
        cloudHost = nil
        hub = nil; hubLive = false; reset()
        // Un code cloud n'a qu'UN logement et meurt à la première entrée : les invités un par un.
        for g in guests {
            let a = await engine.admit(seconds: ShareEngine.admitSeconds)
            guard a["ok"]?.bool == true, let c = a["code"]?.string else { continue }
            let before = engine.participants.filter { !ShareJS.truthy($0["owner"]) }.count
            _ = h.push(secret: h.hostSecret, events: [["event_id": .string(Guard.uid("e")), "kind": "sig",
                                                       "payload": ["t": "gc", "to": .string(g.id), "code": .string(c)],
                                                       "ts": .string(ShareJS.isoString(env.now()))]])
            let t0 = env.now()
            while env.now() - t0 < Self.admitWaitMs {
                await env.sleep(ms: Self.admitPollMs)
                if engine.participants.filter({ !ShareJS.truthy($0["owner"]) }).count > before { break }
            }
        }
        let served = servedChannels; servedChannels = []
        env.schedule(afterMs: Self.hubLingerMs) { h.end(); _ = served }
        if !quiet { onOpenSheet?() }
        onChanged?()
        say(ShareStrings.sayBackOnline, sr ?? ShareStrings.srBackOnlineGeneric)
        return .ok
    }

    /// `slGcJoin` : l'hôte remet par le canal un code d'admission neuf — rejoindre le serveur sans
    /// rien ressaisir. Un échec RESTE en direct (on ne casse jamais le transport qui marche).
    public func gcJoin(_ code: String) async {
        guard !switching else { return }
        switching = true
        defer { switching = false }
        let before = engine.io
        let lbl = myLabel()
        let carried = engine.queue
        reset()
        engine.useRest()
        var ok = false
        for i in 0..<Self.switchTries where !ok {
            if i > 0 { await env.sleep(ms: Self.switchGapMs) }
            ok = ((try? await engine.joinByCode(code, label: lbl))?["ok"]?.bool) == true
        }
        if ok {
            engine.requeueFront(carried)
            onRebuildShared?()
            engine.delegate?.share(engine, announce: ShareStrings.followingOnline)
        } else { engine.setIO(before) }
    }

    /// `slResumeCloud` : l'invité en direct reprend SON partage cloud par son billet. Un refus du
    /// serveur = partage expiré pendant la coupure (« Se reconnecter… »).
    @discardableResult
    public func resumeCloud() async -> Bool {
        guard let tk = engine.cloudGuestTicket, !switching, let rest = engine.restIO else { return false }
        switching = true
        defer { switching = false }
        let before = engine.io
        let r = try? await rest.pull(secret: tk.secret, share: tk.share, since: 0)
        if let r, r["ok"]?.bool == false {
            engine.cloudGuestTicket = nil; expired = true; lostAt = env.now()
            say(ShareStrings.sayExpired, ShareStrings.srExpired)
            return false
        }
        engine.useRest()
        engine.tickets.set(ShareEngine.ticketGuest, tk.json)
        let ok = await engine.resume(sharedRuntimeShown: false)
        if ok {
            engine.cloudGuestTicket = nil; guestDormant = nil; guestOffer = nil
            onRebuildShared?()
            say(ShareStrings.sayBackOnline, ShareStrings.srBackOnlineGuest)
        } else { engine.setIO(before) }
        return ok
    }

    /// `slBootCloudResume` : au démarrage, un invité rechargé EN DIRECT reprend le cloud si le
    /// serveur répond ; sinon le billet attend la sonde.
    @discardableResult
    public func bootCloudResume() async -> Bool {
        guard engine.cloudGuestTicket != nil, engine.mode == .off else { return false }
        await probe()
        guard netOk == true else { startNetWatch(); return false }
        let ok = await resumeCloud()
        if ok { onRebuildShared?() }
        return ok
    }

    /// `slHostRehost` : après un rechargement, l'hôte qui reprend la session de cette fiche reprend
    /// SON partage cloud. Serveur muet : le billet attend la sonde. Refus : le billet meurt.
    @discardableResult
    public func hostRehost() async -> Bool {
        guard let tk = engine.hostTicket, let f = source?.sharedFiche, tk.ficheId == f["id"]?.jsString,
              let snap = source?.sharedSnapshot(), engine.mode == .off, source?.signedIn == true, !switching else { return false }
        await probe()
        guard netOk == true else { startNetWatch(); return false }
        switching = true
        defer { switching = false }
        engine.useRest()
        let ok = await engine.rehost(tk, fiche: f, sessionId: source?.sharedSessionId, snapshot: snap)
        if ok { engine.kick(0); onChanged?(); say(ShareStrings.sayBackOnline, ShareStrings.srRehosted) }
        else { engine.clearHostTicket() }
        return ok
    }

    // MARK: Retour automatique (`slBackArmed`, `slBackTick`, `slWake`)

    var guestBack: Bool {
        engine.mode == .guest && engine.io.kind != .rest && engine.cloudGuestTicket != nil && (engine.fails >= 1 || link().lost)
    }
    public var backArmed: Bool {
        let signed = source?.signedIn == true
        return (engine.mode == .host && engine.share == ShareHostIO.localShare && auto && signed)
            || (engine.mode == .off && source?.sharedSnapshot() != nil && engine.hostTicket != nil && signed)
            || (engine.mode == .off && engine.cloudGuestTicket != nil)
            || guestBack || link().lost
    }
    /// Un tour de la sonde : hystérésis (3 OK, ≥ `dwellMs` en direct), puis retour en ligne.
    public func backTick() async {
        guard backArmed else { return }
        if engine.mode == .off {
            if netOk == true { if engine.cloudGuestTicket != nil { await bootCloudResume() } else { await hostRehost() } }
            return
        }
        if engine.mode == .guest {
            if netOk == true && guestBack && !switching { await resumeCloud() }
            return
        }
        okRun = netOk == true ? okRun + 1 : 0
        let guestsOnHub = !(hub?.guests.isEmpty ?? true)
        if okRun >= Self.okRunNeeded && (guestsOnHub || cloudHost != nil) && env.now() - since >= dwellMs && !switching {
            okRun = 0
            if await goCloud(sr: ShareStrings.srBackOnlineHost, quiet: true) == .ok {
                auto = false; lastBack = env.now(); dwellMs = min(Self.dwellMaxMs, dwellMs * 2)
            } else { since = env.now() }
        }
    }
    /// `slWake` (retour au premier plan) : un hôte direct aux canaux morts revient SEUL en ligne si
    /// le retour est armé et le serveur répond ; sinon on le DIT.
    public func wake() async {
        guard liveOk, engine.participants.contains(where: { !ShareJS.truthy($0["owner"]) && !ShareJS.truthy($0["revoked"]) && engine.isLost($0) }) else { return }
        if backArmed {
            await probe()
            if netOk == true && !switching { auto = false; _ = await goCloud(sr: ShareStrings.srBackOnlineHost, quiet: true); return }
        }
        say(ShareStrings.sayLost, ShareStrings.srWakeLost)
    }
    /// Choix « Automatique » dans la feuille Mode : retire la couche optique, réarme le retour.
    public func chooseAutomatic() {
        optic = false
        if engine.share == ShareHostIO.localShare && liveOk && source?.signedIn == true { auto = true; since = env.now(); okRun = 0; startNetWatch() }
    }

    // MARK: Appariement direct par QR (`startShareLocal`, `slOffer`, `slGuestUp`)

    /// L'hôte ouvre un appariement direct : hub neuf (ou celui déjà vivant), offre « SO: ».
    /// Rend le texte du QR ; la phase dit s'il faut plutôt passer par l'écran (pas d'adresse locale).
    public func offerPairing() async -> String? {
        guard let stack, let f = source?.sharedFiche else { return nil }
        if !liveOk { if hub == nil || hubLive { hub = ShareHub.make(fiche: f, now: env.now); hubLive = false } }
        pairing?.offer.close()
        guard let o = try? await stack.makeOffer() else { return nil }
        let k = SharePairing.newToken(env.random)
        pairing = (o, k)
        retainedPeers.append(o)
        let ch = o.channel
        // Servir le canal DÈS son ouverture, avant tout `await` (comme `slGuestUp`) : la jointure
        // de l'invité peut arriver dans la même rafale.
        ch.onOpen = { [weak self] in
            guard let self else { return }
            self.serveChannel(ch)
            Task { @MainActor in await self.goLive() }
        }
        if !liveOk { pairPhase = ShareSDP.hasLocalCandidate(o.quintuple.c) && !optic ? .offer : .optic }
        return SharePairing(k: k, sdp: o.quintuple).qrText(offer: true)
    }
    public enum AnswerScan: Equatable, Sendable { case notAnswer, stale, connecting, failed }
    /// L'hôte scanne la réponse « SA: » : jeton vérifié (« Réponse périmée — attendez la nouvelle »).
    public func acceptPairingAnswer(_ text: String) async -> AnswerScan {
        guard text.hasPrefix(SharePairing.answerPrefix), let a = SharePairing.unpack(String(text.dropFirst(3))) else { return .notAnswer }
        guard let p = pairing else { return .failed }
        guard a.k == p.k else { return .stale }
        do { try await p.offer.accept(answer: a.sdp); return .connecting } catch { return .failed }
    }
    /// `slGuestUp` : un canal s'ouvre — le servir ; la première fois, le partage direct démarre.
    public func guestUp(_ ch: ShareDataChannel) async {
        serveChannel(ch)
        await goLive()
    }
    func serveChannel(_ ch: ShareDataChannel) {
        guard let h = hub else { return }
        servedChannels.append(ch)
        ShareRPCServer.serve(h, on: ch)
    }
    func goLive() async {
        guard let h = hub, let f = source?.sharedFiche else { return }
        guard !hubLive else { onChanged?(); return }
        hubLive = true; pairPhase = nil
        engine.setIO(ShareHostIO(hub: h, clock: env.now))
        let r = await engine.host(fiche: f, sessionId: source?.sharedSessionId, snapshot: source?.sharedSnapshot())
        if r["ok"]?.bool != true { onToast?(ShareStrings.directFailed) }
        onChanged?()
    }
    /// Arrêt d'un appariement pas encore vivant.
    public func cancelPairing() { pairing?.offer.close(); pairing = nil; pairPhase = nil; if !hubLive { hub = nil; servedChannels = [] }; optic = false }
    /// « Arrêter le partage… » en direct : le moteur termine (`endShare`), le hub et ses canaux tombent.
    public func stopDirect() async {
        await engine.endShare()
        hub?.end(); hub = nil; hubLive = false
        for c in servedChannels { c.close() }
        servedChannels = []; pairing?.offer.close(); pairing = nil; pairPhase = nil; optic = false
        reset()
    }
    /// Forcer « par l'écran » faute de réponse (« Rien après 10 s ? Passer par l'écran »).
    public func forceOptic() { optic = true; if !hubLive { pairPhase = .optic } }

    /// Invité : scanne l'offre « SO: », rend la réponse « SA: » à montrer ; quand le canal s'ouvre,
    /// rejoint par RPC (`joinByCode('AAAA2222', rôle)`).
    public func answerPairing(offerText: String, label: String, onJoined: @escaping (Bool) -> Void) async -> String? {
        guard let stack, offerText.hasPrefix(SharePairing.offerPrefix), let o = SharePairing.unpack(String(offerText.dropFirst(3))),
              let h = try? await stack.makeAnswer(to: o.sdp) else { return nil }
        retainedPeers.append(h)
        h.onChannel = { [weak self] ch in
            guard let self else { return }
            let go: () -> Void = {
                _ = Task { @MainActor in
                    self.engine.setIO(ShareRPCClient(wire: ch, env: self.env))
                    let r = try? await self.engine.joinByCode(ShareRPC.dummyCode, label: label)
                    onJoined(r?["ok"]?.bool == true)
                }
            }
            if ch.isOpen { go() } else { ch.onOpen = { go() } }
        }
        return SharePairing(k: o.k, sdp: h.quintuple).qrText(offer: false)
    }
}
