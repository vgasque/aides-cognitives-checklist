import Foundation

/* ===== PARTAGE DE SESSION — le moteur (port de l'objet `Share` de la PWA) =====
 *
 * Miroir ADDITIF d'une session de crise vers d'autres appareils. RIEN de ce qui suit n'est
 * jamais attendu par un chemin d'interface (règle 15) : l'app appelle `emit`/`emitDiff`, qui
 * mettent en FILE et rendent la main aussitôt ; le cycle (`cycle`) tourne à part. Couper le
 * réseau ne change, chez l'hôte, qu'UN mot dans le quai (`quaiTag`).
 *
 * POURQUOI DU SONDAGE : les invités sans compte n'ont pas de JWT, et Realtime autorise ses canaux
 * par JWT. Tout le chemin invité passe donc par les fonctions SECURITY DEFINER `share_*` —
 * sondées à cadence ADAPTATIVE (2 s après une action, 5 s, puis 10 s au calme ; 5 s de plancher
 * tant qu'une crise est à l'écran). L'exactitude des minuteurs n'en dépend pas : elle vient de
 * l'ancre absolue transmise, pas du réseau.
 *
 * L'état est un JOURNAL append-only par partage. L'hôte n'y plie rien (sa session locale EST
 * l'état) : il ÉMET par différence d'instantanés. L'invité PLIE le journal (`ShareCore.fold`) et
 * l'applique en direct. La divergence se détecte au COMPTE puis à l'EMPREINTE SHA-256 du flux
 * reçu ; sur écart, tout est redemandé depuis zéro (l'application est idempotente).
 *
 * Isolation : @MainActor — le moteur a la sémantique « une seule file » du JavaScript (les
 * entrelacements n'ont lieu qu'aux `await`, et `inflight` protège le cycle comme dans la PWA).
 */

/// Ce que l'app fournit au moteur : l'application d'un lot distant à SA session, l'instantané
/// courant (base de diff), et les canaux d'annonce. Toutes les méthodes ont un défaut vide.
@MainActor
public protocol ShareEngineDelegate: AnyObject {
    /// Applique un lot distant (sans `sig` ; la passation et les départs sont déjà traités) à la
    /// session partagée, par `ShareApply`. Rendre nil si RIEN n'a été appliqué (invité dont la
    /// session partagée n'est pas à l'écran : le pli continue d'accumuler, pas de rebase) ;
    /// sinon le nombre d'évènements peints et s'il faut ANNONCER (faux quand l'hôte consulte
    /// une autre aide — `shareApplyAway`).
    func share(_ engine: ShareEngine, apply events: [JSON]) -> ShareApplyResult?
    /// Instantané de la session partagée (`ShareCore.snap(runtime, flowEnded:)`) — la base de diff
    /// après une application, pour ne jamais renvoyer l'écho de ce qu'on vient de recevoir.
    func shareCurrentSnapshot(_ engine: ShareEngine) -> JSON?
    /// Annonce au lecteur d'écran (région vivante cachée — jamais une notification).
    func share(_ engine: ShareEngine, announce text: String)
    /// Le statut a changé (bandeau figé de l'invité, quai).
    func share(_ engine: ShareEngine, statusChanged new: String, from old: String)
    /// La liste des participants a changé de SIGNATURE (menu « Partage en cours (n) », feuille).
    func shareParticipantsChanged(_ engine: ShareEngine)
    /// Évènement `sig` (plomberie du secours chaud) — jamais d'interface.
    func share(_ engine: ShareEngine, signal event: JSON)
    /// Un cycle a échoué (`slSbFail`).
    func shareCycleFailed(_ engine: ShareEngine)
    /// Un cycle sain (`slSbGuestKick` chez l'invité sur la couture REST).
    func shareCycleHealthy(_ engine: ShareEngine)
    /// Divergence détectée : le miroir sera refait depuis zéro.
    func share(_ engine: ShareEngine, desync reason: String)
    /// Une crise est-elle à l'écran (`crisisOnScreen`) — plancher de cadence de 5 s.
    func shareCrisisOnScreen(_ engine: ShareEngine) -> Bool
    /// L'app est-elle en arrière-plan (`visibilityState === 'hidden'`).
    func shareIsHidden(_ engine: ShareEngine) -> Bool
}
public extension ShareEngineDelegate {
    func share(_ engine: ShareEngine, apply events: [JSON]) -> ShareApplyResult? { nil }
    func shareCurrentSnapshot(_ engine: ShareEngine) -> JSON? { nil }
    func share(_ engine: ShareEngine, announce text: String) {}
    func share(_ engine: ShareEngine, statusChanged new: String, from old: String) {}
    func shareParticipantsChanged(_ engine: ShareEngine) {}
    func share(_ engine: ShareEngine, signal event: JSON) {}
    func shareCycleFailed(_ engine: ShareEngine) {}
    func shareCycleHealthy(_ engine: ShareEngine) {}
    func share(_ engine: ShareEngine, desync reason: String) {}
    func shareCrisisOnScreen(_ engine: ShareEngine) -> Bool { false }
    func shareIsHidden(_ engine: ShareEngine) -> Bool { false }
}

public struct ShareApplyResult: Equatable, Sendable {
    public var painted: Int
    public var announce: Bool
    public init(painted: Int, announce: Bool = true) { self.painted = painted; self.announce = announce }
}

// MARK: - Persistance de la file et des billets

/// File d'émission persistée (`shareq_v1` / store `meta` clé `shareq`) : `{share, q}`.
@MainActor
public protocol ShareQueueStore: AnyObject {
    func load() -> (share: String?, queue: [JSON])
    func save(share: String?, queue: [JSON])
}
@MainActor
public final class MemoryShareQueueStore: ShareQueueStore {
    public var share: String?
    public var queue: [JSON] = []
    public init() {}
    public func load() -> (share: String?, queue: [JSON]) { (share, queue) }
    public func save(share: String?, queue: [JSON]) { self.share = share; self.queue = queue }
}
/// File persistée dans un fichier JSON (écriture atomique) — pour l'hôte et l'invité « avec trace ».
@MainActor
public final class FileShareQueueStore: ShareQueueStore {
    let url: URL
    public init(url: URL) { self.url = url }
    public func load() -> (share: String?, queue: [JSON]) {
        guard let d = try? Data(contentsOf: url), let j = try? JSON.parse(d) else { return (nil, []) }
        return (j["share"]?.string, j["q"]?.array ?? [])
    }
    public func save(share: String?, queue: [JSON]) {
        let j: JSON = ["share": share.map { .string($0) } ?? .null, "q": .array(queue)]
        try? j.data().write(to: url, options: .atomic)
    }
}

/// Billets de reprise (équivalent de `sessionStorage` : portée du processus/de la scène, AUCUNE
/// donnée clinique — seulement de quoi rouvrir le tuyau).
@MainActor
public protocol ShareTicketStore: AnyObject {
    func get(_ key: String) -> JSON?
    func set(_ key: String, _ value: JSON?)
}
@MainActor
public final class MemoryShareTicketStore: ShareTicketStore {
    public var values: [String: JSON] = [:]
    public init() {}
    public func get(_ key: String) -> JSON? { values[key] }
    public func set(_ key: String, _ value: JSON?) { values[key] = value }
}

/// Billet de l'INVITÉ (`ac-share-tk` / `ac-share-tk-cloud`) : `{s, k, m, r}`.
public struct ShareGuestTicket: Equatable, Sendable {
    public var share: String, secret: String, me: String?, role: String?
    public init(share: String, secret: String, me: String?, role: String?) { self.share = share; self.secret = secret; self.me = me; self.role = role }
    public var json: JSON { ["s": .string(share), "k": .string(secret), "m": me.map { .string($0) } ?? .null, "r": role.map { .string($0) } ?? .null] }
    public init?(_ j: JSON?) {
        guard let s = j?["s"]?.string, !s.isEmpty, let k = j?["k"]?.string, !k.isEmpty else { return nil }
        share = s; secret = k; me = j?["m"]?.string; role = j?["r"]?.string
    }
}
/// Billet de l'HÔTE (`ac-share-host-tk`) : reprendre le MÊME partage cloud après un rechargement.
public struct ShareHostTicket: Equatable, Sendable {
    public var share: String, code: String?, joinUntil: Double, expiresAt: Double, cursor: Int, ficheId: String
    public init(share: String, code: String?, joinUntil: Double, expiresAt: Double, cursor: Int, ficheId: String) {
        self.share = share; self.code = code; self.joinUntil = joinUntil; self.expiresAt = expiresAt; self.cursor = cursor; self.ficheId = ficheId
    }
    public var json: JSON {
        ["share": .string(share), "code": code.map { .string($0) } ?? .null, "joinUntil": .number(joinUntil),
         "expiresAt": .number(expiresAt), "cursor": .number(Double(cursor)), "fiche": .string(ficheId)]
    }
    public init?(_ j: JSON?) {
        guard let s = j?["share"]?.string, !s.isEmpty else { return nil }
        share = s; code = j?["code"]?.string; joinUntil = ShareJS.num0(j?["joinUntil"]); expiresAt = ShareJS.num0(j?["expiresAt"])
        cursor = Int(ShareJS.num0(j?["cursor"])); ficheId = j?["fiche"]?.string ?? ""
    }
}

// MARK: - Le moteur

@MainActor
public final class ShareEngine {
    public enum Mode: String, Sendable { case off, host, guest }

    // Constantes (spec E § 2)
    nonisolated public static let nominalMs: Double = 2000         // SHARE_NOMINAL_MS
    nonisolated public static let staleFloorMs: Double = 4000      // SHARE_STALE_MS
    nonisolated public static let maxBatch = 50                    // SHARE_MAX_BATCH
    nonisolated public static let pullPage = 500
    nonisolated public static let seenQuietMs: Double = 45000      // SHARE_SEEN_QUIET_MS
    nonisolated public static let seenLostMs: Double = 180000      // SHARE_SEEN_LOST_MS
    nonisolated public static let emitKickMs: Double = 250
    nonisolated public static let detachedPollMs: Double = 10000
    nonisolated public static let defaultTtlMin = 180
    nonisolated public static let admitSeconds = 120
    nonisolated public static let guestRole = "scribe"
    nonisolated public static let ticketGuest = "ac-share-tk", ticketCloudGuest = "ac-share-tk-cloud", ticketHost = "ac-share-host-tk"

    public let env: ShareEnvironment
    /// La couture Supabase par défaut (`_ioRest`) — TOUT chemin cloud commence par la restaurer.
    public let restIO: ShareIO?
    /// La couture en place (`_io`).
    public var io: ShareIO
    let queueStore: ShareQueueStore
    public let tickets: ShareTicketStore
    public weak var delegate: ShareEngineDelegate?

    // État public (lecture seule pour l'interface)
    public private(set) var mode: Mode = .off
    public private(set) var status = "off"           // active | revoked | detached | expired | ended | off
    public private(set) var share: String?
    public private(set) var secret: String?
    public private(set) var me: String?
    public private(set) var role: String?
    /// Projection de la fiche : la sienne (hôte) ou la reçue (invité — à passer par `migrate`).
    public private(set) var fiche: JSON?
    /// État PLIÉ du fil — l'unique état de l'invité (jamais chez l'hôte).
    public var fold: JSON?
    public private(set) var code: String?
    public private(set) var joinUntil: Double = 0
    public private(set) var expiresAt: Double = 0
    public private(set) var codeTakenBy: String?
    /// Le lien est mort ALORS QUE cet invité tenait la main : il garde son écran et poursuit.
    public private(set) var soloLead = false
    public private(set) var cursor = 0, seq = 0, nEvents = 0, applied = 0
    /// Décalage d'horloge serveur − local (Cristian) ; public en écriture pour le miroir optique
    /// (`o.at - Date.now()` : l'heure de l'hôte devient la référence).
    public var offset: Double = 0
    public private(set) var lastOk: Double = 0
    public private(set) var participants: [JSON] = []
    public private(set) var queue: [JSON] = []
    /// Échecs consécutifs — l'évènement `offline` du système le force à ≥ 2 (`markOffline`).
    public private(set) var fails = 0
    /// Délai de la dernière relance programmée (observabilité et tests).
    public private(set) var lastKickMs: Double?
    /// Départs EXPLICITES reçus (`presence{state:'quit'}` — jamais reçu à travers la liste blanche,
    /// spec § 20.2, mais gardé pour un serveur qui l'accepterait).
    public private(set) var left: Set<String> = []
    // Passation (en mémoire : une offre est un MOMENT, pas un contrat)
    public private(set) var hoOffer = false         // invité : on me propose la main
    public private(set) var hoTake: String?         // hôte : quelqu'un l'a prise, reste à l'inscrire
    public private(set) var hoOffered: String?      // hôte : à qui je l'ai proposée
    /// Dernière avance venue d'en face (mention « avancé par … »).
    public private(set) var navBy: (label: String, at: Double)?

    var ids: [String] = []
    var samples: [ShareCore.ClockSample] = []
    var act: Double = 0
    var resync = false
    var inflight = false
    var timer: ShareTimer?
    /// Base de l'émission par différence (`_shareBase`).
    public private(set) var diffBase: JSON?

    public init(env: ShareEnvironment, restIO: ShareIO?, queueStore: ShareQueueStore? = nil, tickets: ShareTicketStore? = nil) {
        self.env = env; self.restIO = restIO
        self.queueStore = queueStore ?? MemoryShareQueueStore(); self.tickets = tickets ?? MemoryShareTicketStore()
        self.io = restIO ?? ShareNoIO()
    }

    // MARK: Horloge et fraîcheur

    /// Heure SERVEUR estimée — tout ce qui est horodaté pendant un partage passe par ici.
    public func now() -> Double { env.now() + offset }
    public var staleMs: Double { mode == .off ? 0 : max(0, env.now() - lastOk) }
    /// Péremption = CONTRAT affiché : « deux cycles manqués », solidaire de la cadence nominale.
    public var staleLimit: Double { max(Self.staleFloorMs, JS.round(2.5 * baseMs())) }
    public var isStale: Bool { mode != .off && staleMs > staleLimit }
    public var pendingCount: Int { queue.count }
    /// Un coupé/détaché perd l'écriture ; un PÉRIMÉ la garde (file persistée, envoi au retour).
    public func canWrite(_ kind: String) -> Bool { mode != .off && status == "active" && ShareCore.can(role, kind) }
    public var isDirect: Bool { share == ShareHostIO.localShare || io.kind != .rest }

    // MARK: Cadence adaptative (`_base`, `_delay`, `_kick`)

    public func baseMs() -> Double {
        if delegate?.shareIsHidden(self) ?? false { return 15000 }
        let idle = env.now() - act
        let floor: Double = (delegate?.shareCrisisOnScreen(self) ?? false) ? 5000 : 10000
        return idle < 30000 ? Self.nominalMs : (idle < 120000 ? 5000 : floor)
    }
    public func delayMs() -> Double {
        let back = fails > 0 ? min(30000, Self.nominalMs * pow(2, Double(fails))) : 0
        return JS.round(max(baseMs(), back) * (0.8 + env.random() * 0.4))
    }
    /// (Re)programme le cycle. `ms == nil` : cadence courante avec gigue.
    public func kick(_ ms: Double? = nil) {
        timer?.cancel()
        let d = ms ?? delayMs()
        lastKickMs = d
        timer = env.schedule(afterMs: d) { [weak self] in
            Task { @MainActor [weak self] in await self?.cycle() }
        }
    }
    func cancelTimer() { timer?.cancel(); timer = nil }

    /// L'évènement `offline` du système (+1,5 s, toujours hors ligne, partage cloud) : la panne
    /// est tranchée aussitôt.
    public func markOffline() { fails = max(fails, 2) }

    // MARK: File d'émission

    func saveQueue() { queueStore.save(share: share, queue: queue) }
    func loadQueue(_ share: String?) {
        let v = queueStore.load()
        queue = (v.share == share) ? v.queue : []
    }

    /// Émet un évènement : en FILE (persistée), avec l'heure du GESTE (serveur estimée), relance
    /// du cycle dans 250 ms. Refusé (rôle, statut) → nil ; chez un invité actif, un refus
    /// déclare le miroir PÉRIMÉ (la base de diff a déjà avancé) et redemande tout.
    @discardableResult
    public func emit(_ kind: String, _ payload: JSON? = nil) -> String? {
        if mode == .off { return nil }
        guard canWrite(kind) else {
            if mode == .guest && status == "active" { desync("geste refusé") }
            return nil
        }
        let id = ShareJS.uuidV4()
        queue.append(["event_id": .string(id), "kind": .string(kind), "payload": payload ?? .object([:]),
                      "ts": .string(ShareJS.isoString(now()))])
        act = env.now()
        saveQueue()
        kick(Self.emitKickMs)
        return id
    }

    /// `shareEmitDiff` : diffe l'instantané courant contre la base, émet, avance la base.
    /// L'APPELANT tient les gardes de la PWA : n'appeler QUE pour la session partagée (chez
    /// l'invité : celle sans dossier local ; chez l'hôte : la session hébergée) — cf.
    /// `ShareEngine.shouldEmit`. `sessionId` = l'identité optique portée par `session_start`.
    @discardableResult
    public func emitDiff(snapshot now: JSON, sessionId: String?) -> Int {
        if mode == .off { return 0 }
        guard let b = diffBase else { diffBase = now; return 0 }
        let evs = ShareCore.diff(b, now, sessionId: sessionId)
        diffBase = now
        for e in evs { emit(e.kind, e.payload) }
        return evs.count
    }
    /// `shareRebase` : la base suit ce qu'on vient d'APPLIQUER (jamais d'écho vers l'expéditeur).
    public func rebase(_ snapshot: JSON?) { if mode != .off { diffBase = snapshot } }
    /// Les deux gardes de `shareEmitDiff` : chez l'invité, jamais une session LOCALE ; chez
    /// l'hôte, seulement la session hébergée (A387).
    public func shouldEmit(runtimeHasLocalSession: Bool, isHostedRuntime: Bool) -> Bool {
        switch mode {
        case .off: return false
        case .guest: return !runtimeHasLocalSession
        case .host: return isHostedRuntime
        }
    }

    // MARK: Horloge de Cristian

    func sample(_ t0: Double, _ srv: JSON?) {
        guard let s = srv?.string, let ms = ShareJS.isoMs(s) else { return }
        samples.append(ShareCore.ClockSample(t0: t0, t1: env.now(), srv: ms))
        if samples.count > 5 { samples.removeFirst() }
        if let o = ShareCore.offset(samples) { offset = o }   // mesure trop lente : on GARDE le dernier bon
    }

    // MARK: Le cycle (`_cycle`)

    /// Pousse la file (50 au plus), tire le journal depuis le curseur, mesure l'horloge, détecte la
    /// divergence, reprogramme. Jamais d'exception vers l'appelant.
    public func cycle() async {
        if mode == .off || inflight { return }
        inflight = true
        let t0 = env.now()
        do {
            if !queue.isEmpty {
                let lot = Array(queue.prefix(Self.maxBatch))
                let r = try await io.push(secret: secret, share: share, events: lot)
                sample(t0, r["server_time"])
                if r["ok"]?.bool == true {
                    queue.removeFirst(min(lot.count, queue.count))
                    saveQueue()
                } else if let st = r["status"]?.string, !st.isEmpty { transition(to: st) }   // refus MOTIVÉ
            }
            let p = try await io.pull(secret: secret, share: share, since: cursor)
            sample(t0, p["server_time"])
            if p["ok"]?.bool != true {
                fails += 1
                delegate?.shareCycleFailed(self)
            } else {
                await handlePull(p)
            }
        } catch {
            fails += 1
            delegate?.shareCycleFailed(self)
        }
        inflight = false
        if mode != .off && (status == "active" || (status == "detached" && !queue.isEmpty)) {
            kick(status == "detached" ? Self.detachedPollMs : nil)
        }
    }

    func participantsSignature(_ q: [JSON]) -> String {
        q.filter { !ShareJS.truthy($0["owner"]) }.map { x in
            let sil = silenceMs(x)
            return (x["id"]?.jsString ?? "") + ":" + (x["role"]?.string ?? "") + (ShareJS.truthy(x["revoked"]) ? "R" : "")
                + (ShareJS.truthy(x["detached"]) ? "D" : "") + (hasLeft(x) ? "P" : "") + (isLost(x) ? "S" : "")
                + (sil > Self.seenQuietMs ? "Q\(Int(JS.round(sil / 60000)))" : "")
        }.joined(separator: "|")
    }

    /// Changement de statut rapporté par le serveur. Geler sur la TRANSITION, jamais à chaque tour
    /// (re-geler reconvertirait la file d'annexes). Un statut terminal est une DÉCISION : on cesse
    /// de sonder et on le DIT. ⚠ Écart assumé : la PWA pose le statut d'un refus de `push` SANS
    /// passer par ce gel (ni `soloLead`, ni `onStatus`, file gardée) ; le natif traite les deux
    /// sources de la même façon.
    func transition(to st: String) {
        let before = status
        status = st
        if status != "active" && status != before {
            if mode == .guest && role == "lead" && status != "revoked" { soloLead = true }
            freeze(status)
        }
        if status != before { delegate?.share(self, statusChanged: status, from: before) }
    }

    func handlePull(_ p: JSON) async {
        fails = 0
        lastOk = env.now()
        let roleBefore = role
        if let r = p["role"]?.string, !r.isEmpty { role = r }
        if let m = p["me"]?.string, !m.isEmpty { me = m }
        if mode == .guest && roleBefore == "lead" && role != "lead" { delegate?.share(self, announce: ShareStrings.leadReturnedToHost) }
        transition(to: p["status"]?.string ?? status)
        let newParts = p["participants"]?.array ?? []
        // Un détaché ou un coupé qui tenait la main la REND : jamais un partage sans conducteur.
        if mode == .host, let gone = newParts.first(where: { !ShareJS.truthy($0["owner"]) && $0["role"]?.string == "lead"
            && (ShareJS.truthy($0["detached"]) || ShareJS.truthy($0["revoked"])) }), let gid = gone["id"]?.string {
            _ = await reclaimLead(gid)   // lit la liste PRÉCÉDENTE, comme la PWA (appel non attendu là-bas)
        }
        // Le code est MORT dès que quelqu'un entre (`share_join` le consomme) : l'hôte cesse de le dicter.
        do {
            let av = Set(participants.filter { !ShareJS.truthy($0["owner"]) }.compactMap { $0["id"]?.jsString })
            if let neuf = newParts.first(where: { !ShareJS.truthy($0["owner"]) && !av.contains($0["id"]?.jsString ?? "") }), code != nil {
                code = nil; joinUntil = 0
                let lab = neuf["label"]?.string
                codeTakenBy = (lab?.isEmpty == false) ? lab : ShareStrings.guestDefault
                delegate?.share(self, announce: ShareStrings.joined(lab))
            }
        }
        let moved = participantsSignature(participants) != participantsSignature(newParts)
        participants = newParts
        if moved { delegate?.shareParticipantsChanged(self) }
        seq = Int(ShareJS.num0(p["seq"]))
        nEvents = Int(ShareJS.num0(p["n_events"]))
        let ev = p["events"]?.array ?? []
        if !ev.isEmpty {
            applied += ev.count
            cursor = Int(ShareJS.num0(ev.last?["seq"]))
            act = env.now()
            for e in ev { ids.append((e["seq"]?.jsString ?? "undefined") + ":" + (e["id"]?.jsString ?? "undefined")) }
            for e in ev where e["kind"]?.string == "sig" { delegate?.share(self, signal: e) }
            if mode == .guest { fold = ShareCore.fold(ev, base: fold) }
            route(ev.filter { $0["kind"]?.string != "sig" })
        }
        // Avancer jusqu'à la borne haute du serveur (trous des lignes refusées), SAUF lot tronqué.
        if ev.count < Self.pullPage { cursor = max(cursor, seq) }
        let upToDate = cursor >= seq
        if upToDate && applied != nEvents { desync("compte") }
        else if upToDate, let stream = p["stream"]?.string, !stream.isEmpty {
            if streamHash() != stream { desync("empreinte") } else { resync = false }
        } else if upToDate { resync = false }
        if mode == .guest && io.kind == .rest { delegate?.shareCycleHealthy(self) }
    }

    /// `_streamHash` : SHA-256 des couples « numéro:identifiant » reçus, dans l'ordre.
    public func streamHash() -> String { ShareSHA256.hex(ids.joined(separator: ",")) }

    /// Reprise TOTALE : on ne rattrape pas un miroir faux, on le refait (garde contre l'enchaînement).
    public func desync(_ reason: String) {
        if resync { return }
        resync = true; cursor = 0; applied = 0; ids = []; fold = nil
        delegate?.share(self, desync: reason)
    }

    // MARK: Application d'un lot distant (`onEvents`)

    /// Passation et départs d'abord (ce sont des ÉTATS de fenêtre, jamais des interruptions),
    /// puis l'application par le délégué, la rebase, l'inscription automatique d'une prise de
    /// main, et UNE annonce pour le lot. Public : le retour optique y passe aussi (acteur
    /// « optique »), et la reprise (`resume`) y rejoue le journal.
    public func route(_ ev: [JSON]) {
        var navLabel: String?
        for e in ev {
            let actor = e["actor"]?.string
            let other = actor != nil && actor != me
            let kind = e["kind"]?.string ?? ""
            if kind == "nav" && other {
                let q = participants.first { $0["id"]?.string == actor }
                let l = q?["label"]?.string
                navLabel = (l?.isEmpty == false) ? l! : "un participant"
            }
            if kind == "presence" && other && e["payload"]?["state"]?.string == "quit" {
                left.insert(actor!); delegate?.shareParticipantsChanged(self); continue
            }
            guard kind == "handoff", other else { continue }
            let p = e["payload"] ?? .object([:])
            if let to = p["to"], to.truthy, to.string == me { hoOffer = true; delegate?.shareParticipantsChanged(self) }
            else if let to = p["to"], to.truthy, hoOffer { hoOffer = false; delegate?.shareParticipantsChanged(self) }
            if ShareJS.truthy(p["take"]) && mode == .host { hoTake = actor }
        }
        let res = delegate?.share(self, apply: ev)
        if res != nil { rebase(delegate?.shareCurrentSnapshot(self)) }
        if let who = hoTake, mode == .host {
            hoTake = nil
            Task { @MainActor in
                if await self.grantLead(who) { self.delegate?.share(self, announce: ShareStrings.gaveLead) }
            }
        }
        guard let r = res, r.announce else { return }
        if let l = navLabel {
            navBy = (l, env.now())
            delegate?.share(self, announce: ShareStrings.advanced(l))
        }
        if r.painted > 0 { delegate?.share(self, announce: ShareStrings.actions(r.painted)) }
    }

    // MARK: Gestes de l'HÔTE

    /// Ouvre le partage. `snapshot` = instantané de la session DÉMARRÉE (nil → `not_started`) ;
    /// tout l'état courant part aussitôt en évènements depuis une base vide (« rembobinage »).
    /// Une exception réseau rend `{ok:false, err:'network'}` (la PWA bascule alors en direct).
    public func host(fiche f: JSON, sessionId: String?, snapshot: JSON?, ttlMin: Int = ShareEngine.defaultTtlMin) async -> JSON {
        guard let snapshot else { return ["ok": false, "err": "not_started"] }
        let t0 = env.now()
        let snap = ShareCore.payload(f)
        let id = Guard.uid("sh")
        let r: JSON
        do { r = try await io.open(id: id, sessionId: sessionId ?? id, ficheId: f["id"]?.jsString ?? "", snap: snap, guestRole: Self.guestRole, ttlMin: ttlMin) }
        catch { return ["ok": false, "err": "network"] }
        guard r["ok"]?.bool == true else { return r.object != nil ? r : ["ok": false, "err": "refused"] }
        mode = .host; status = "active"; share = r["share"]?.string; secret = nil; me = nil; role = "lead"
        fiche = snap; fold = nil
        code = r["code"]?.string
        joinUntil = r["join_open_until"]?.string.flatMap(ShareJS.isoMs) ?? 0
        expiresAt = r["expires_at"]?.string.flatMap(ShareJS.isoMs) ?? 0
        participants = []; cursor = 0; applied = 0; seq = 0; nEvents = 0; ids = []
        lastOk = env.now(); fails = 0; act = env.now(); queue = []; samples = []
        sample(t0, r["server_time"])
        diffBase = ShareCore.emptySnap
        emitDiff(snapshot: snapshot, sessionId: sessionId)
        saveHostTicket(ficheId: f["id"]?.jsString ?? "")
        kick(0)
        return r
    }

    /// Reprend le MÊME partage cloud (id et code inchangés) après une panne ou un rechargement ;
    /// les invités gardent leur secret. Refus (expiré, purgé) → false : l'appelant ouvre un neuf.
    public func rehost(_ tk: ShareHostTicket, fiche f: JSON, sessionId: String?, snapshot: JSON) async -> Bool {
        let t0 = env.now()
        guard let r = try? await io.pull(secret: nil, share: tk.share, since: tk.cursor), r["ok"]?.bool == true,
              r["status"]?.string == "active" else { return false }
        mode = .host; status = "active"; share = tk.share; secret = nil; me = nil; role = "lead"
        fiche = ShareCore.payload(f); fold = nil; code = tk.code; joinUntil = tk.joinUntil; expiresAt = tk.expiresAt
        participants = r["participants"]?.array ?? []; cursor = tk.cursor; applied = 0; seq = 0; nEvents = 0; ids = []
        lastOk = env.now(); fails = 0; act = env.now(); queue = []; samples = []
        sample(t0, r["server_time"])
        diffBase = ShareCore.emptySnap
        emitDiff(snapshot: snapshot, sessionId: sessionId)
        saveHostTicket(ficheId: f["id"]?.jsString ?? "")
        return true
    }

    /// Ré-ouvrir la porte : code NEUF, l'ancien meurt.
    public func admit(seconds: Int = ShareEngine.admitSeconds) async -> JSON {
        guard mode == .host, let s = share else { return ["ok": false, "err": "refused"] }
        guard let r = try? await io.admit(share: s, seconds: seconds) else { return ["ok": false, "err": "refused"] }
        if r["ok"]?.bool == true {
            code = r["code"]?.string; joinUntil = r["join_open_until"]?.string.flatMap(ShareJS.isoMs) ?? 0; codeTakenBy = nil
        }
        return r
    }
    /// Temps restant de la porte ouverte (0 = code expiré ou consommé) — le décompte de la feuille.
    public var doorOpenMs: Double { code == nil ? 0 : max(0, joinUntil - now()) }

    /// Couper un participant : aucun affichage optimiste (« coupure… » jusqu'au sondage suivant).
    /// Couper celui qui tient la main la rend à l'hôte.
    public func revoke(_ pid: String) async -> Bool {
        guard mode == .host, let s = share, !pid.isEmpty else { return false }
        do {
            _ = try await io.revoke(share: s, pid: pid)
            _ = await reclaimLead(pid)
            kick(0)
            return true
        } catch { return false }
    }
    /// Rendre la main à l'hôte si `pid` la détenait. ⚠ Ne rétrograde pas l'autre (comme la PWA).
    public func reclaimLead(_ pid: String) async -> Bool {
        guard let p = participants.first(where: { $0["id"]?.string == pid }), p["role"]?.string == "lead",
              let mine = participants.first(where: { ShareJS.truthy($0["owner"]) }), let myId = mine["id"]?.string, let s = share else { return false }
        do { _ = try await io.setRole(share: s, pid: myId, role: "lead") } catch { return false }
        role = "lead"; hoOffered = nil; hoTake = nil
        delegate?.share(self, announce: ShareStrings.leadBack)
        return true
    }
    /// Arrêter le partage (`endShare`) — aussi à la fin de la session, JAMAIS attendu par l'UI.
    @discardableResult
    public func endShare() async -> Bool {
        clearHostTicket()
        guard mode == .host, let s = share else { return false }
        var ok = false
        do { _ = try await io.end(share: s); ok = true } catch {}
        stop()
        diffBase = nil
        return ok
    }

    // MARK: Passation de la main (trois temps, jamais par un évènement)

    /// 1. L'hôte PROPOSE (le rôle ne change pas ici).
    @discardableResult public func offerLead(_ pid: String) -> Bool {
        guard mode == .host, !pid.isEmpty else { return false }
        hoOffered = pid; emit("handoff", ["to": .string(pid)]); return true
    }
    /// 2. L'invité PREND (il ne s'accorde rien : il annonce).
    @discardableResult public func takeLead() -> Bool {
        guard mode == .guest, hoOffer else { return false }
        hoOffer = false; emit("handoff", ["take": true])
        delegate?.share(self, announce: ShareStrings.tookLead)
        return true
    }
    /// 3. L'hôte INSCRIT : rétrograder d'ABORD, promouvoir ENSUITE (pire cas : zéro lead, jamais deux).
    public func grantLead(_ pid: String) async -> Bool {
        guard mode == .host, let s = share, !pid.isEmpty else { return false }
        do {
            if let mine = participants.first(where: { ShareJS.truthy($0["owner"]) }), let myId = mine["id"]?.string {
                _ = try await io.setRole(share: s, pid: myId, role: "scribe")
            }
            _ = try await io.setRole(share: s, pid: pid, role: "lead")
            role = "scribe"; hoTake = nil; hoOffered = nil
            return true
        } catch { return false }
    }

    // MARK: Gestes de l'INVITÉ

    func guestReset(_ f: JSON?, status st: String, t0: Double, serverTime: JSON?) {
        status = st; soloLead = false; cursor = 0; applied = 0; seq = 0; nEvents = 0
        fiche = f; fold = nil; lastOk = env.now(); fails = 0; act = env.now(); ids = []
        samples = []; sample(t0, serverTime)
    }
    /// Rejoindre par code. LÈVE sur une panne réseau (l'écran dit « Pas de réseau… ») ; un refus
    /// du serveur rend `{ok:false, err:'refused'}` (sept causes indistinguables, à dessein).
    public func joinByCode(_ code: String, label: String?) async throws -> JSON {
        let t0 = env.now()
        let r = try await io.join(code: JS.trim(code.uppercased()), label: (label?.isEmpty == false) ? label! : ShareStrings.guestDefault)
        guard r["ok"]?.bool == true else { return r.object != nil ? r : ["ok": false, "err": "refused"] }
        mode = .guest; share = r["share"]?.string; secret = r["secret"]?.string; me = r["me"]?.string; role = r["role"]?.string
        guestReset(r["fiche"], status: "active", t0: t0, serverTime: r["server_time"])
        loadQueue(share)
        saveGuestTicket()
        kick(0)
        return r
    }

    public func saveGuestTicket() {
        guard mode == .guest, let s = share, let k = secret else { return }
        tickets.set(Self.ticketGuest, ShareGuestTicket(share: s, secret: k, me: me, role: role).json)
    }
    public func clearGuestTicket() { tickets.set(Self.ticketGuest, nil) }
    public var guestTicket: ShareGuestTicket? { ShareGuestTicket(tickets.get(Self.ticketGuest)) }
    public var cloudGuestTicket: ShareGuestTicket? {
        get { ShareGuestTicket(tickets.get(Self.ticketCloudGuest)) }
        set { tickets.set(Self.ticketCloudGuest, newValue?.json) }
    }
    func saveHostTicket(ficheId: String) {
        guard mode == .host, let s = share, s != ShareHostIO.localShare else { return }
        tickets.set(Self.ticketHost, ShareHostTicket(share: s, code: code, joinUntil: joinUntil, expiresAt: expiresAt, cursor: cursor, ficheId: ficheId).json)
    }
    public var hostTicket: ShareHostTicket? { ShareHostTicket(tickets.get(Self.ticketHost)) }
    public func clearHostTicket() { tickets.set(Self.ticketHost, nil) }

    /// Reprise après rechargement par le billet : on ne rejoint pas (le code est brûlé), on
    /// REPREND le fil depuis zéro avec le secret obtenu. Refus → le billet est effacé.
    /// `sharedRuntimeShown` : la session partagée est déjà à l'écran (reprise après une panne) —
    /// le journal est alors rejoué par la voie vivante, idempotente.
    public func resume(sharedRuntimeShown: Bool = false) async -> Bool {
        guard let tk = guestTicket else { return false }
        let t0 = env.now()
        guard let r = try? await io.pull(secret: tk.secret, share: tk.share, since: 0), r["ok"]?.bool == true,
              let f = r["fiche"], f.truthy else { clearGuestTicket(); return false }
        mode = .guest; share = tk.share; secret = tk.secret
        me = r["me"]?.string ?? tk.me; role = r["role"]?.string ?? tk.role
        guestReset(f, status: r["status"]?.string ?? "active", t0: t0, serverTime: r["server_time"])
        let evs = r["events"]?.array ?? []
        if !evs.isEmpty {
            fold = ShareCore.fold(evs)
            cursor = Int(ShareJS.num0(evs.last?["seq"]))
            for e in evs { ids.append((e["seq"]?.jsString ?? "undefined") + ":" + (e["id"]?.jsString ?? "undefined")) }
        }
        participants = r["participants"]?.array ?? []
        if sharedRuntimeShown { route(evs.filter { $0["kind"]?.string != "sig" }) }
        kick(0)
        return true
    }

    /// « Continuer seul… » : `detach` poussé DIRECTEMENT (hors file), puis gel en `detached`.
    @discardableResult
    public func detach() async -> Bool {
        guard mode == .guest, status == "active" else { return false }
        let e: JSON = ["event_id": .string(ShareJS.uuidV4()), "kind": "detach", "payload": .object([:]), "ts": .string(ShareJS.isoString(now()))]
        _ = try? await io.push(secret: secret, share: share, events: [e])
        freeze("detached")
        return true
    }
    /// Le LIEN meurt : le sondage s'arrête, le mode reste (l'écran garde son état, figé). Un
    /// détaché CONVERTIT sa file en repères d'annexe (`offline_mark`) qui remontent encore ; les
    /// autres statuts jettent la file (la prétendre délivrable serait mentir).
    public func freeze(_ st: String?) {
        status = (st?.isEmpty == false) ? st! : "ended"
        cancelTimer()
        if status == "detached" {
            queue = queue.map { e in
                let ts = e["ts"] ?? .null
                let t = ts.string.flatMap(ShareJS.isoMs) ?? env.now()
                return ["event_id": .string(ShareJS.uuidV4()), "kind": "offline_mark", "ts": ts,
                        "payload": ["t": .number(t), "ref": ShareCore.orNull(e["payload"]?["ref"]), "was": e["kind"] ?? .null]]
            }
            saveQueue(); kick(2000); return
        }
        queue = []; saveQueue()
    }
    /// L'ÉCRAN est quitté (ou l'hôte arrête) : plus rien du partage ne subsiste.
    public func stop() {
        clearGuestTicket()
        mode = .off; status = "off"; cancelTimer(); ids = []
        queue = []; saveQueue(); share = nil; secret = nil; me = nil; role = nil
        soloLead = false; participants = []; fiche = nil; fold = nil; left = []
        hoOffer = false; hoTake = nil; hoOffered = nil; navBy = nil
    }
    /// « Quitter le partage… » : `presence{state:'quit'}` en meilleur effort (jamais attendu),
    /// puis `stop()`. ⚠ `state` est amputé par la liste blanche serveur (spec § 20.2).
    public func quit() {
        if mode == .guest && status == "active", let k = secret {
            let e: JSON = ["event_id": .string(ShareJS.uuidV4()), "kind": "presence", "ts": .string(ShareJS.isoString(now())),
                           "payload": ["state": "quit"]]
            let io = self.io, s = share
            Task { _ = try? await io.push(secret: k, share: s, events: [e]) }
        }
        stop()
    }

    // MARK: Présence observée, jamais déclarée

    public func silenceMs(_ p: JSON) -> Double { ShareCore.silenceMs(p, serverNow: now()) }
    public func hasLeft(_ p: JSON) -> Bool { (p["id"]?.string).map { left.contains($0) } ?? false }
    public func isLost(_ p: JSON) -> Bool { silenceMs(p) > Self.seenLostMs }
    /// Présent : ni propriétaire, ni coupé, ni détaché, ni parti, silence ≤ 3 min.
    public func isPresent(_ p: JSON) -> Bool {
        !ShareJS.truthy(p["owner"]) && !ShareJS.truthy(p["revoked"]) && !ShareJS.truthy(p["detached"]) && !hasLeft(p) && !isLost(p)
    }
    public var presentCount: Int { participants.filter(isPresent).count }
    /// Silence de l'HÔTE vu de l'invité (rangée propriétaire).
    public var hostSilenceMs: Double {
        guard let o = participants.first(where: { ShareJS.truthy($0["owner"]) }), let t = ShareCore.seenMs(o["seen"]) else { return 0 }
        return max(0, now() - t)
    }
    /// État d'une rangée de participant (`sharePartRowsHtml`) : coupé, seul, parti, absent,
    /// coupure…, conduit, relève — plus le silence si 45 s < silence ≤ 3 min.
    public func participantState(_ p: JSON, cutting: Bool = false) -> (word: String, quietMin: Int?) {
        let parti = hasLeft(p), perdu = !parti && isLost(p), sil = silenceMs(p)
        let rev = ShareJS.truthy(p["revoked"]), det = ShareJS.truthy(p["detached"])
        let calme = !parti && !perdu && !rev && !det && sil > Self.seenQuietMs
        let w = rev ? ShareStrings.partRevoked : det ? ShareStrings.partDetached : parti ? ShareStrings.partLeft
            : perdu ? ShareStrings.partAbsent : (cutting ? ShareStrings.partCutting : (p["role"]?.string == "lead" ? ShareStrings.partLead : ShareStrings.partScribe))
        return (w, calme ? Int(JS.round(sil / 60000)) : nil)
    }

    // MARK: Quai (`shareGlobTag`) et bandeau figé (`shareFrozen`)

    /// Le jeton du quai : '' · coupé/fini/seul · figé · ⇄n (hôte) · offert · main/suit (invité).
    public var quaiTag: String {
        if mode == .off { return "" }
        if status != "active" { return ShareStrings.statusTag[status] ?? "coupé" }
        if isStale { return ShareStrings.tagStale }
        if mode == .host { return "⇄\(presentCount)" }
        if hoOffer { return ShareStrings.tagOffered }
        return role == "lead" ? ShareStrings.tagLead : ShareStrings.tagScribe
    }
    /// Un jeton non nominal fait passer l'encre du point vert au NEUTRE (« le vert ne ment pas »).
    public var quaiTagIsNominal: Bool {
        let t = quaiTag
        return t.isEmpty || t == ShareStrings.tagLead || t == ShareStrings.tagScribe || t == ShareStrings.tagOffered || t.hasPrefix("⇄")
    }
    /// Libellé du chrono du quai, borné à 18 caractères.
    public func quaiLabel(exercise: Bool, sayWord: String?) -> String {
        let tag = quaiTag
        let active = mode != .off && status == "active"
        let s = exercise ? ShareStrings.quaiExercise : (sayWord.map { "● " + $0 } ?? ((active ? ShareStrings.quaiShared : ShareStrings.quaiSession) + (tag.isEmpty ? "" : " · " + tag)))
        return JS.prefix(s, 18)
    }
    /// L'invité figé (statut mort, sans la main) : tout geste mutateur est bloqué.
    public var isFrozenGuest: Bool { mode == .guest && ["revoked", "ended", "expired"].contains(status) && !soloLead }
    /// Refus d'un geste de l'invité (`canToggleStep` et gestes réservés) : nil = autorisé.
    public func refusal(forKind kind: String) -> String? {
        guard mode == .guest else { return nil }
        if isFrozenGuest { return status == "revoked" ? ShareStrings.refuseRevoked : ShareStrings.refuseEnded }
        if canWrite(kind) { return nil }
        if status != "active" { return kind == "check" || kind == "uncheck" ? ShareStrings.refuseStopped : ShareStrings.refuseLeadOnlyStopped }
        if kind == "check" { return ShareStrings.refuseCheck }
        if kind == "uncheck" { return ShareStrings.refuseUncheck }
        return ShareStrings.refuseLeadOnly
    }

    // MARK: Couture

    /// Remplace la couture (bascules direct ↔ en ligne). `useRest()` restaure `_ioRest`.
    public func setIO(_ io: ShareIO) { self.io = io }
    public func useRest() { if let r = restIO { io = r } }
    /// Ré-injecte des évènements portés d'un transport à l'autre (même ids, mêmes clés) en TÊTE.
    public func requeueFront(_ carried: [JSON]) {
        guard !carried.isEmpty else { return }
        queue = carried + queue; saveQueue(); kick(0)
    }
    /// Pousse un lot DIRECTEMENT (hors file) — `sig {t:'go'}`, présence, reprise des évènements du hub.
    public func pushDirect(_ events: [JSON], secret s: String? = nil, share sh: String? = nil) async -> JSON? {
        try? await io.push(secret: s ?? secret, share: sh ?? share, events: events)
    }
    public func envelope(_ kind: String, _ payload: JSON) -> JSON {
        ["event_id": .string(ShareJS.uuidV4()), "kind": .string(kind), "payload": payload, "ts": .string(ShareJS.isoString(now()))]
    }
}

// Accès réservés aux tests (@testable).
extension ShareEngine {
    func resetResyncForTest() { resync = false }
    func actForTest(_ t: Double) { act = t }
    func failsForTest(_ n: Int) { fails = n }
}

/// Couture nulle (aucun partage en ligne configuré) : tout appel échoue.
final class ShareNoIO: ShareIO {
    var kind: ShareIOKind { .other }
    func open(id: String, sessionId: String, ficheId: String, snap: JSON, guestRole: String, ttlMin: Int) async throws -> JSON { throw ShareError.refused("aucun serveur") }
    func admit(share: String, seconds: Int) async throws -> JSON { throw ShareError.refused("aucun serveur") }
    func join(code: String, label: String) async throws -> JSON { throw ShareError.refused("aucun serveur") }
    func pull(secret: String?, share: String?, since: Int) async throws -> JSON { throw ShareError.refused("aucun serveur") }
    func push(secret: String?, share: String?, events: [JSON]) async throws -> JSON { throw ShareError.refused("aucun serveur") }
    func revoke(share: String, pid: String) async throws -> JSON { throw ShareError.refused("aucun serveur") }
    func setRole(share: String, pid: String, role: String) async throws -> JSON { throw ShareError.refused("aucun serveur") }
    func end(share: String) async throws -> JSON { throw ShareError.refused("aucun serveur") }
}

// MARK: - Décision de démarrage (`shareBootDecide`)

public enum ShareBoot {
    public enum Decision: Equatable, Sendable {
        case resumeGuest            // billet `ac-share-tk` : reprendre (il prime sur tout `#j=`)
        case resumeCloudGuest       // billet `ac-share-tk-cloud` : l'invité rechargé en direct reprend le cloud
        case join(code: String)     // lien `#j=CODE` valide
        case none
    }
    public static func decide(guestTicket: ShareGuestTicket?, cloudTicket: ShareGuestTicket?, fragment: String?) -> Decision {
        if guestTicket != nil { return .resumeGuest }
        if cloudTicket != nil { return .resumeCloudGuest }
        if let c = ShareCode.fromHash(fragment) { return .join(code: c) }
        return .none
    }
}
