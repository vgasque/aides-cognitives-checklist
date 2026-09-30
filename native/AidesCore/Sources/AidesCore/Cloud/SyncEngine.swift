import Foundation

// MOTEUR DE SYNCHRONISATION — port de l'objet `Sync` de la PWA (`full`, `_pullTable`,
// `_pushTable`, `_reclaimBlocked`, `_reconcileShared`, `_syncCats`, `_syncNotes`,
// `_syncAttachments`, `loadProfile`, `_initIfNeeded`).
//
// LOCAL-FIRST : le disque de l'appareil (`SpaceStore`) est la SOURCE DE VÉRITÉ ; le cloud est un
// miroir asynchrone. Aucune étape n'est attendue par un geste de l'interface : un échec laisse
// tout sur l'appareil, la pastille dit « Erreur de synchro » et une relance est programmée.
//
// ACTEUR PRINCIPAL (`@MainActor`) : la couche d'application écrit le même `SpaceStore` depuis
// l'acteur principal ; en y vivant aussi, le moteur ne fait jamais de lecture-modification-écriture
// concurrente d'un enregistrement. ENTRE DEUX `await` (un appel réseau), l'utilisateur peut avoir
// modifié le stockage : le moteur RELIT donc toujours l'enregistrement frais avant d'écrire (le web
// s'appuie sur des copies lues avant l'appel — le natif ferme ainsi deux petites courses, sans
// changer aucune règle de résolution).
//
// MODE CRISE (règle 11) : le moteur ne fait JAMAIS de rendu. Il met le stockage à jour puis remet
// à l'hôte la liste des changements (`SyncChanges`) ; c'est l'hôte qui décide de ne rien
// reconstruire tant qu'une session de crise est à l'écran (la version fraîche d'une fiche ouverte
// arrive à sa réouverture) et de RETENIR les notices (`SyncNotice`) jusqu'à la fin de la session.
//
// UN MOTEUR PAR ESPACE : la bascule d'espace (connexion d'un autre compte) jette le moteur et en
// crée un neuf sur le nouvel espace — l'équivalent du rechargement de page du web.

/// Changements appliqués au STOCKAGE par une étape de synchro, à reporter dans les collections en
/// mémoire de l'app. Aucune pierre tombale n'y figure : une suppression est un id retiré.
public struct SyncChanges: Equatable, Sendable {
    /// Aides créées ou remplacées (version du serveur, copie Perso, id réparé…).
    public var fiches: [Fiche] = []
    public var removedFicheIds: [String] = []
    public var references: [Reference] = []
    public var removedReferenceIds: [String] = []
    /// Sessions archivées (JSON, forme `sanitizeSession` + `updatedAt`/`deletedAt`).
    public var sessions: [JSON] = []
    public var removedSessionIds: [String] = []
    /// Les catégories ont été remplacées (relire `meta.categories`).
    public var categories = false
    /// Les épingles ont été remplacées par celles du document personnel.
    public var pins = false
    /// Aides dont la NOTE personnelle a changé à distance (re-rendre seulement si c'est la fiche
    /// ouverte, en lecture, hors édition de la note).
    public var notes: Set<String> = []
    public init() {}
    public var isEmpty: Bool {
        fiches.isEmpty && removedFicheIds.isEmpty && references.isEmpty && removedReferenceIds.isEmpty
            && sessions.isEmpty && removedSessionIds.isEmpty && !categories && !pins && notes.isEmpty
    }
    mutating func upsert(_ d: SyncDecoded) {
        switch d {
        case .fiche(let f): fiches.removeAll { $0.id == f.id }; removedFicheIds.removeAll { $0 == f.id }; fiches.append(f)
        case .reference(let r): references.removeAll { $0.id == r.id }; removedReferenceIds.removeAll { $0 == r.id }; references.append(r)
        case .session(let s):
            let id = s["id"]?.string
            sessions.removeAll { $0["id"]?.string == id }
            if let id { removedSessionIds.removeAll { $0 == id } }
            sessions.append(s)
        }
    }
    mutating func remove(_ t: SyncTable, _ id: String) {
        switch t {
        case .fiches: fiches.removeAll { $0.id == id }; if !removedFicheIds.contains(id) { removedFicheIds.append(id) }
        case .protocols: references.removeAll { $0.id == id }; if !removedReferenceIds.contains(id) { removedReferenceIds.append(id) }
        case .sessions: sessions.removeAll { $0["id"]?.string == id }; if !removedSessionIds.contains(id) { removedSessionIds.append(id) }
        }
    }
}

/// Préférences apprises du document personnel, à APPLIQUER par l'hôte (thème, taille du texte,
/// accent) — ou seulement à retenir (mode de lecture, rangement de l'accueil : jamais de bascule de
/// la vue ouverte pendant un soin). Déjà écrites dans `SpaceStore.prefs`.
public struct RemotePrefsChange: Equatable, Sendable {
    public var theme: String?
    public var zoom: Int?
    public var accent: String?
    public var readMode: String?
    public var homeGroup: String?
    public var tags = false
    public var syncSessions: Bool?
    public init() {}
    public var isEmpty: Bool { theme == nil && zoom == nil && accent == nil && readMode == nil && homeGroup == nil && !tags && syncSessions == nil }
}

public enum SyncEntityKind: Sendable { case fiche, reference }

/// Ce que l'app fournit au moteur, et ce qu'elle apprend de lui. Toutes les méthodes ont une
/// implémentation vide par défaut.
@MainActor
public protocol SyncHost: AnyObject {
    /// Pastille / bandeau / ligne d'état (source unique).
    func syncStatusDidChange(_ status: SyncStatus)
    /// Le stockage a changé : reporter en mémoire, SANS reconstruire la vue de crise.
    func syncDidApply(_ changes: SyncChanges)
    /// Nouvelle non bloquante (toast), à retenir pendant une session de crise.
    func syncNotice(_ notice: SyncNotice)
    /// Bibliothèques, rôles, statut app-admin ou statut du compte ont changé.
    func syncProfileDidChange(_ profile: Profile)
    /// Préférences reçues du document personnel.
    func syncPrefsDidChange(_ change: RemotePrefsChange)
    /// Une entité a changé d'IDENTIFIANT (réparation d'un 403 : id déjà pris par un autre compte).
    /// L'hôte déplace la session vive, l'écran ouvert et le brouillon en cours sur le nouvel id.
    func syncDidReassign(_ kind: SyncEntityKind, from oldId: String, to newId: String)
    /// Ids de PDF référencés par un BROUILLON en cours d'édition (pas encore enregistré) : ils
    /// ne doivent pas être purgés comme orphelins.
    func syncProtectedAttachmentIds() -> Set<String>
    /// Fin d'un téléchargement de fond de PDF (rafraîchir la ligne « documents sur l'appareil »).
    func syncAttachmentsDidDownload(_ ids: [String])
}

public extension SyncHost {
    func syncStatusDidChange(_ status: SyncStatus) {}
    func syncDidApply(_ changes: SyncChanges) {}
    func syncNotice(_ notice: SyncNotice) {}
    func syncProfileDidChange(_ profile: Profile) {}
    func syncPrefsDidChange(_ change: RemotePrefsChange) {}
    func syncDidReassign(_ kind: SyncEntityKind, from oldId: String, to newId: String) {}
    func syncProtectedAttachmentIds() -> Set<String> { [] }
    func syncAttachmentsDidDownload(_ ids: [String]) {}
}

/// Les trois tables synchronisées « entité complète en JSONB ».
public enum SyncTable: Sendable, CaseIterable {
    case fiches, protocols, sessions
    /// Nom DISTANT (≠ nom du dossier local pour les fiches : `cognitive_aids` ↔ `fiches`).
    public var remote: String {
        switch self { case .fiches: return "cognitive_aids"; case .protocols: return "protocols"; case .sessions: return "sessions" }
    }
    public var cursorKey: String {
        switch self { case .fiches: return SpaceKeys.cursorFiches; case .protocols: return SpaceKeys.cursorProtocols; case .sessions: return SpaceKeys.cursorSessions }
    }
    var idPrefix: String { switch self { case .fiches: return "f"; case .protocols: return "p"; case .sessions: return "s" } }
}

enum SyncDecoded {
    case fiche(Fiche), reference(Reference), session(JSON)
}

@MainActor
public final class SyncEngine {
    public let auth: AuthClient
    public let api: AccountAPI
    public let local: LocalStore
    public let store: SpaceStore
    public weak var host: SyncHost?
    /// Échec RAPIDE hors ligne (`Sync.online()` ; natif : `NWPathMonitor`). Jamais une preuve de
    /// joignabilité : réseau « disponible », on essaie et le délai de garde tranche.
    public var isOnline: () -> Bool
    let scheduler: SyncScheduler
    let clock: () -> Double

    public private(set) var status: SyncStatus = .connected
    public private(set) var lastError: SyncErrorInfo?
    public private(set) var lastErrorAt: Double = 0
    /// Dernière synchro COMPLÈTE réussie (« Synchronisé · HH:MM »).
    public private(set) var lastSyncAt: Double = 0
    public private(set) var profile = Profile()
    public private(set) var running = false
    /// Délai de la prochaine relance (ms) ; 0 après un succès.
    public private(set) var retryDelay: Double = 0
    var debounce: SyncCancellable?
    var retryTimer: SyncCancellable?
    var attDownload: Task<Void, Never>?
    var acc = SyncChanges()

    public init(auth: AuthClient, local: LocalStore, store: SpaceStore, host: SyncHost? = nil,
                scheduler: SyncScheduler? = nil, isOnline: @escaping () -> Bool = { true },
                clock: @escaping () -> Double = { JS.now() }) {
        self.auth = auth
        self.api = AccountAPI(auth: auth)
        self.local = local
        self.store = store
        self.host = host
        self.scheduler = scheduler ?? TaskSyncScheduler()
        self.isOnline = isOnline
        self.clock = clock
    }

    public var prefs: SpacePrefs { SpacePrefs(store) }
    /// Une relance automatique est armée (fenêtre d'erreur : « · nouvelle tentative automatique en cours »).
    public var retryPending: Bool { retryTimer != nil }
    func now() -> Double { clock() }

    // MARK: Pastille

    /// `setSyncChip(state, text)`.
    public func setStatus(_ s: SyncStatus) {
        status = s
        host?.syncStatusDidChange(s)
    }

    func flush() {
        guard !acc.isEmpty else { return }
        let c = acc
        acc = SyncChanges()
        host?.syncDidApply(c)
    }

    // MARK: Déclencheurs

    /// `Sync.schedule()` : débounce de 900 ms (sans effet hors connexion). Toute écriture locale,
    /// le retour au premier plan et la fin d'un rattrapage d'historique passent par ici.
    public func schedule() {
        guard auth.signedIn else { return }
        debounce?.cancel()
        debounce = scheduler.after(ms: 900) { [weak self] in
            self?.debounce = nil
            await self?.full()
        }
    }
    /// L'app revient au premier plan (`visibilitychange` → visible ; natif : `scenePhase == .active`).
    public func appDidBecomeActive() { schedule() }
    /// Changement de chemin réseau (`online` / `offline` ; natif : `NWPathMonitor`).
    public func networkDidChange(online: Bool) async {
        if online { setStatus(.synced); await full() } else { setStatus(.offline) }
    }

    /// `_scheduleRetry` : 5 s, 10 s, 20 s, 40 s, 80 s, puis 120 s. À l'échéance, `full()` seulement
    /// si le réseau est là (le retour du réseau relance de lui-même).
    func scheduleRetry() {
        retryTimer?.cancel()
        retryDelay = min(retryDelay > 0 ? retryDelay * 2 : 5000, 120_000)
        retryTimer = scheduler.after(ms: retryDelay) { [weak self] in
            guard let self else { return }
            self.retryTimer = nil
            if self.isOnline() { await self.full() }
        }
    }

    // MARK: full()

    /// `Sync.full()` — la séquence EXACTE du web (spec D § 7.3).
    public func full() async {
        // 1. Garde d'espace : ne JAMAIS synchroniser un compte dans l'espace d'un autre.
        guard let s = auth.session, !s.accessToken.isEmpty else { return }
        if (s.userId ?? "") != store.space { return }
        // 2.
        if !isOnline() { setStatus(.offline); return }
        if running { return }
        // 3.
        retryTimer?.cancel(); retryTimer = nil
        running = true
        setStatus(.busy)
        defer { running = false }
        do {
            let conflicts = try await fullSequence()
            guard let conflicts else { return }   // compte en attente / refusé : arrêt sans relance
            retryDelay = 0
            lastSyncAt = now()
            setStatus(.synced)
            if !conflicts.isEmpty { host?.syncNotice(.conflicts(conflicts)) }
        } catch {
            flush()
            lastError = explainSyncError(error)
            lastErrorAt = now()
            setStatus(.error)
            scheduleRetry()
        }
    }

    /// Rend les conflits, ou nil si le compte n'est pas approuvé (arrêt silencieux).
    func fullSequence() async throws -> [String]? {
        await auth.ensureFresh()                                   // 4
        await refreshAccountStatus()                               // 5
        if profile.accountStatus == .pending { setStatus(.pending); return nil }
        if profile.accountStatus == .rejected { setStatus(.rejected); return nil }
        await loadProfile()                                        // 6
        guard let uid = auth.userId else { throw CloudError.notSignedIn }
        try await initIfNeeded(uid: uid)                           // 7
        var conflicts = try await pull(.fiches)                    // 8
        conflicts += try await pull(.protocols)
        flush()
        _ = try? await pullSessions()                              // 9 (silencieux)
        flush()
        var pushErr: Error?                                        // 10
        do { try await push(.fiches, uid: uid) } catch { pushErr = error }
        do { try await push(.protocols, uid: uid) } catch { if pushErr == nil { pushErr = error } }
        do { try await pushSessions(uid: uid) } catch { if pushErr == nil { pushErr = error } }
        flush()
        try await reconcileShared()                                // 11
        await syncCategories(uid: uid)                             // 12
        try await syncNotes(uid: uid)                              // 13
        var attErr: Error?                                         // 14
        do { try await syncAttachments(uid: uid) } catch { attErr = error }
        flush()
        if let pushErr { throw pushErr }                           // 15
        if let attErr { throw attErr }
        return conflicts
    }

    // MARK: Statut et profil

    /// `refreshAccountStatus()` : un échec réseau GARDE le dernier statut (jamais de fausse alerte
    /// « en attente » hors ligne).
    public func refreshAccountStatus() async {
        let before = profile.accountStatus
        if !auth.signedIn { profile.accountStatus = nil }
        else { do { profile.accountStatus = try await api.myStatus() } catch {} }
        if profile.accountStatus != before { host?.syncProfileDidChange(profile) }
    }

    /// `Sync.loadProfile()` : adhésions (rôle le plus élevé par bibliothèque), statut app-admin,
    /// comptes en attente. Un échec réseau GARDE la dernière valeur connue ; le cache n'est écrit
    /// qu'après un succès complet. L'hôte n'est prévenu que si l'empreinte CHANGE (un re-rendu
    /// inutile, sur le web, détruisait l'élément sous le doigt).
    public func loadProfile() async {
        let prev = profile.fingerprint
        var ok = true
        do { profile.libraries = try await api.memberships() } catch { ok = false }
        do { profile.isAppAdmin = try await api.isAppAdmin() } catch { ok = false }
        if profile.isAppAdmin {
            do { profile.pendingCount = try await api.listUnapprovedUsers().filter { $0.status == .pending }.count } catch { profile.pendingCount = 0 }
        } else { profile.pendingCount = 0 }
        if ok, let uid = auth.userId { local.global[GlobalKeys.profile(uid)] = profile.cacheJSON }
        if profile.fingerprint != prev { host?.syncProfileDidChange(profile) }
    }

    /// `loadProfileCache()` : au démarrage, AVANT tout appel réseau — les bibliothèques partagées
    /// restent visibles hors ligne.
    public func restoreProfileCache() {
        guard let uid = auth.userId, let j = local.global[GlobalKeys.profile(uid)] else { return }
        profile.restore(cache: j)
    }

    /// `resetAuthState()` : déconnexion ou suppression de compte — profil vidé, caches
    /// `ac-profile-*` effacés.
    public func resetAuthState() {
        profile = Profile()
        local.global.remove { $0.hasPrefix("ac-profile-") }
        host?.syncProfileDidChange(profile)
    }

    /// `accountEverSynced()` : cet appareil a-t-il déjà synchronisé ce compte ?
    public func accountEverSynced() -> Bool {
        guard let uid = auth.userId else { return false }
        return !(local.global.string(GlobalKeys.syncInit(uid)) ?? "").isEmpty
    }

    // MARK: Première synchro sur l'appareil

    /// `_initIfNeeded` : une fois par compte et par appareil. Cloud VIDE (aucune fiche perso, même
    /// supprimée) → la bibliothèque locale est marquée à pousser ; sinon le cloud est ADOPTÉ.
    func initIfNeeded(uid: String) async throws {
        let k = GlobalKeys.syncInit(uid)
        if let v = local.global.string(k), !v.isEmpty { return }
        let peek = try await auth.rest("GET", "/rest/v1/cognitive_aids?select=id&library_id=is.null&limit=1")?.array ?? []
        if peek.isEmpty {
            for (dir, _) in [(store.fiches, SyncTable.fiches), (store.protocols, .protocols)] {
                for r in dir.all() where LocalRecord.library(r) == nil && !LocalRecord.isDeleted(r) {
                    guard let id = LocalRecord.id(r) else { continue }
                    try putRecord(dir, id, LocalRecord.with(r, "dirty", true))
                }
            }
            prefs.setString(SpaceKeys.catsDirty(""), "1")
            if prefs.kv[SpaceKeys.catsUpdated("")] == nil { prefs.set(SpaceKeys.catsUpdated(""), .number(now())) }
        }
        local.global.set(k, "1")
    }

    // MARK: Accès au stockage

    func dir(_ t: SyncTable) -> RecordDir {
        switch t { case .fiches: return store.fiches; case .protocols: return store.protocols; case .sessions: return store.sessions }
    }
    func putRecord(_ d: RecordDir, _ id: String, _ v: JSON) throws {
        do { try d.put(id, v) } catch { throw CloudError.localStore("Écriture locale impossible (\(id)) : \(error)") }
    }
    /// `fromRow` de la table : l'enregistrement à écrire + sa forme typée pour l'hôte.
    func decode(_ t: SyncTable, _ row: JSON) -> (JSON, SyncDecoded) {
        switch t {
        case .fiches: let f = SyncRows.ficheFromRow(row, now: now()); return (f.json, .fiche(f))
        case .protocols: let r = SyncRows.referenceFromRow(row, now: now()); return (r.json, .reference(r))
        case .sessions: let s = SyncRows.sessionFromRow(row, now: now()); return (s, .session(s))
        }
    }
    /// Forme typée d'un enregistrement LOCAL (copies Perso, réparations).
    func decodeLocal(_ t: SyncTable, _ rec: JSON) -> SyncDecoded {
        switch t {
        case .fiches: return .fiche(Sanitize.fiche(rec))
        case .protocols: return .reference(Sanitize.reference(rec))
        case .sessions: return .session(rec)
        }
    }
    func toRow(_ t: SyncTable, _ o: JSON, uid: String) -> JSON {
        t == .sessions ? SyncRows.sessionToRow(o, uid: uid, now: now()) : SyncRows.entityToRow(o, uid: uid, now: now())
    }
    func enc(_ s: String) -> String { jsEncodeURIComponent(s) }

    // MARK: PULL

    /// `_pullTable` : pages de 1000 par `updated_at` croissant (recouvrement de 2 s sur le
    /// curseur, application idempotente), puis REPÊCHAGE de complétude par id. Rend les titres des
    /// fiches modifiées ici et écrasées par une version plus récente (conflits).
    func pull(_ t: SyncTable) async throws -> [String] {
        let d = dir(t)
        let prefs = self.prefs
        // Curseur illisible = pas de curseur (le web lèverait sur `toISOString` d'une date invalide).
        let curMs: Double? = prefs.string(t.cursorKey).flatMap { $0.isEmpty ? nil : JSDate.parse($0) }
        var since = curMs.map { JSDate.iso($0 - 2000) } ?? "1970-01-01T00:00:00Z"
        var maxTs = curMs ?? 0
        var conflicts: [String] = []
        // id → updatedAt local (tombstones et enregistrements « dirty » compris).
        var byId: [String: Double] = [:]
        for r in d.all() { if let id = LocalRecord.id(r) { byId[id] = LocalRecord.updatedAt(r) } }

        func apply(_ row: JSON) throws {
            // Un id hors SAFE_ID ne peut pas devenir un nom de fichier local : la ligne est ignorée.
            guard let id = row["id"]?.string, Guard.isSafeId(id) else { return }
            let localRec = d.get(id)   // relu FRAIS (voir l'en-tête)
            if row["deleted_at"]?.truthy ?? false {
                // Pierre tombale distante : la copie locale part, MÊME modifiée (pas de LWW sur
                // une suppression) ; les tombes distantes ne sont jamais stockées.
                if localRec != nil { d.delete(id); byId[id] = nil; acc.remove(t, id) }
                if t == .fiches { clearNoteOnRemoteDelete(id) }
                return
            }
            guard let localRec else {
                let (rec, dec) = decode(t, row)
                try putRecord(d, id, rec)
                byId[id] = LocalRecord.updatedAt(rec)
                acc.upsert(dec)
                return
            }
            if JSDate.parseOrZero(row["updated_at"]) > LocalRecord.updatedAt(localRec) {
                if t == .fiches { putBackup(of: localRec) }
                if LocalRecord.isDirty(localRec) { conflicts.append(LocalRecord.title(localRec)) }
                let (rec, dec) = decode(t, row)
                try putRecord(d, id, rec)
                byId[id] = LocalRecord.updatedAt(rec)
                acc.upsert(dec)
            }
            // Sinon : le local est plus récent ou identique — gardé (poussé s'il est « dirty »).
        }

        let page = 1000
        for _ in 0..<50 {
            let rows = try await auth.rest("GET", "/rest/v1/\(t.remote)?select=*&updated_at=gt.\(enc(since))&order=updated_at.asc&limit=\(page)")?.array ?? []
            for row in rows {
                let rts = JSDate.parseOrZero(row["updated_at"])
                if rts > maxTs { maxTs = rts }
                try apply(row)
            }
            if rows.count < page { break }
            let next = JSDate.iso(maxTs)
            if next == since { break }
            since = next
        }
        if curMs != nil {
            var missed: [String] = []
            var after = ""
            for _ in 0..<50 {
                let rows = try await auth.rest("GET", "/rest/v1/\(t.remote)?select=id,updated_at,deleted_at&order=id.asc" + (after.isEmpty ? "" : "&id=gt." + enc(after)) + "&limit=\(page)")?.array ?? []
                missed += SyncRows.pullMissedIds(rows) { byId[$0] }
                if rows.count < page { break }
                after = rows.last?["id"]?.jsString ?? ""
            }
            // Lots de 60 ids (URL ≤ ~4 Ko) ; ids SAFE_ID, donc sans encodage.
            var i = 0
            while i < missed.count {
                let chunk = missed[i..<min(i + 60, missed.count)]
                let rows = try await auth.rest("GET", "/rest/v1/\(t.remote)?select=*&id=in.(" + chunk.joined(separator: ",") + ")")?.array ?? []
                for row in rows { try apply(row) }
                i += 60
            }
        }
        if maxTs != 0 && !maxTs.isNaN { prefs.setString(t.cursorKey, JSDate.iso(maxTs)) }
        return conflicts
    }

    /// Une fiche supprimée ailleurs emporte ma note personnelle (t:'' poussé → propagé).
    func clearNoteOnRemoteDelete(_ id: String) {
        var notes = loadNotes()
        if let n = notes[id], !n.t.isEmpty {
            notes[id] = Note(t: "", at: now(), dirty: true)
            saveNotes(notes)
            acc.notes.insert(id)
        }
    }

    /// `_pullSessions` : RIEN ne descend tant que l'utilisateur n'a pas choisi (opt-in).
    @discardableResult
    func pullSessions() async throws -> Bool {
        guard prefs.syncSessions else { return false }
        _ = try await pull(.sessions)
        return true
    }

    // MARK: PUSH

    /// `_pushSessions` : SEULES les sessions ARCHIVÉES montent (une session vive poussée serait un
    /// second canal de partage, sans code, sans rôle, sans péremption).
    func pushSessions(uid: String) async throws {
        guard prefs.syncSessions else { return }
        try await push(.sessions, uid: uid)
    }

    /// `_pushTable` : cas nominal en UNE requête atomique ; lot refusé → élément par élément ;
    /// Perso en 403 → réparation par id neuf si l'espace perso est bien inscriptible ; droits
    /// perdus sur une bibliothèque → copie en Perso d'abord, version de l'équipe ensuite.
    func push(_ t: SyncTable, uid: String) async throws {
        let d = dir(t)
        var all = d.all()
        if t == .sessions { all = all.filter { !($0["live"]?.truthy ?? false) } }
        let held = t == .fiches ? Set(prefs.heldEdits) : []
        let skip: (JSON) -> Bool = { held.contains(LocalRecord.id($0) ?? "") }
        let reclaimed = await reclaimBlocked(t, all, skip: skip)
        let dirty = all.filter { o in
            LocalRecord.isDirty(o) && profile.canEdit(scope: LocalRecord.library(o)) && !skip(o)
                && !reclaimed.done.contains(LocalRecord.id(o) ?? "")
        } + reclaimed.copies
        if dirty.isEmpty { return }

        func send(_ batch: [JSON]) async throws {
            try await auth.rest("POST", "/rest/v1/" + t.remote, body: .array(batch.map { toRow(t, $0, uid: uid) }),
                                extra: ["Prefer": "resolution=merge-duplicates,return=minimal"])
            for o in batch { settle(t, o) }
        }
        do { try await send(dirty); return } catch {}
        var firstErr: Error?
        var persoOk = 0
        var perso403: [JSON] = []
        for o in dirty {
            do {
                try await send([o])
                if LocalRecord.library(o) == nil { persoOk += 1 }
            } catch {
                // ÉCART VOULU : une SESSION refusée en 403 n'a pas de réparation (le web tentait
                // un `cfg.repair` absent et affichait « Serveur injoignable ») — l'erreur reste le 403.
                if t != .sessions, isPersoRepairCandidate(Self.message(of: error), isPerso: LocalRecord.library(o) == nil) {
                    perso403.append(o)
                } else if firstErr == nil { firstErr = error }
            }
        }
        if !perso403.isEmpty {
            var writable = persoOk > 0
            if !writable { writable = (try? await api.isApproved()) ?? false }
            if writable {
                for o in perso403 {
                    do {
                        let fixed = try repair(t, o)
                        try await send([fixed])
                    } catch { if firstErr == nil { firstErr = error } }
                }
            } else if firstErr == nil {
                firstErr = CloudError.http(status: 403, body: "(espace personnel indisponible en écriture)")
            }
        }
        if let firstErr { throw firstErr }
    }

    static func message(of e: Error) -> String { (e as? CloudError)?.message ?? String(describing: e) }

    /// Après un envoi réussi : une pierre tombale est PURGÉE ; sinon `dirty` retombe — à condition
    /// que l'enregistrement n'ait pas changé pendant la requête (sinon il reste à pousser).
    func settle(_ t: SyncTable, _ o: JSON) {
        guard let id = LocalRecord.id(o) else { return }
        let d = dir(t)
        let fresh = d.get(id)
        if LocalRecord.isDeleted(o) {
            if let f = fresh, LocalRecord.updatedAt(f) != LocalRecord.updatedAt(o) { return }
            d.delete(id)
            acc.remove(t, id)
        } else {
            guard let f = fresh, LocalRecord.updatedAt(f) == LocalRecord.updatedAt(o), LocalRecord.isDirty(f) else { return }
            try? d.put(id, LocalRecord.with(f, "dirty", false))
        }
    }

    /// Réparation d'un 403 PERSO : l'id existe déjà dans le cloud sous un AUTRE compte (fiche
    /// transférée par export/import entre comptes — la clé primaire est globale). L'entité est
    /// adoptée sous un id NEUF ; ses rattachements locaux suivent.
    func repair(_ t: SyncTable, _ o: JSON) throws -> JSON {
        guard let oldId = LocalRecord.id(o) else { throw CloudError.localStore("id manquant") }
        switch t {
        case .fiches: return try reassignFicheId(oldId, o)
        case .protocols:
            let newId = Guard.uid("p")
            let rec = LocalRecord.with(LocalRecord.with(o, "id", .string(newId)), "dirty", true)
            try putRecord(store.protocols, newId, rec)
            store.protocols.delete(oldId)
            acc.remove(.protocols, oldId)
            acc.upsert(decodeLocal(.protocols, rec))
            host?.syncDidReassign(.reference, from: oldId, to: newId)
            return rec
        case .sessions:
            throw CloudError.http(status: 403, body: "")
        }
    }

    /// `reassignFicheId(f)` : nouvel id `uid()`, et tout ce qui s'y rattache SUR CET APPAREIL suit
    /// — note, épingle (préférences à pousser), sessions, versions sauvegardées ; l'hôte déplace
    /// la session vive, l'écran ouvert et le brouillon. Les documents distants ne bougent pas.
    func reassignFicheId(_ oldId: String, _ o: JSON) throws -> JSON {
        let newId = Guard.uid()
        let rec = LocalRecord.with(LocalRecord.with(o, "id", .string(newId)), "dirty", true)
        try putRecord(store.fiches, newId, rec)
        store.fiches.delete(oldId)
        acc.remove(.fiches, oldId)
        acc.upsert(decodeLocal(.fiches, rec))
        var notes = loadNotes()
        if let n = notes[oldId] { notes[newId] = n; notes[oldId] = nil; saveNotes(notes) }
        var pins = prefs.pins
        if let i = pins.firstIndex(of: oldId) {
            pins[i] = newId
            prefs.pins = pins
            markPrefsDirty()
            acc.pins = true
        }
        for s in store.sessions.all() where s["ficheId"]?.string == oldId {
            guard let sid = LocalRecord.id(s) else { continue }
            var m = s.object ?? [:]
            m["ficheId"] = .string(newId); m["dirty"] = true; m["updatedAt"] = .number(now())
            try? store.sessions.put(sid, .object(m))
            acc.upsert(.session(.object(m)))
        }
        for b in store.backups.all() where b["ficheId"]?.string == oldId {
            guard let bid = b["bid"]?.string else { continue }
            try? store.backups.put(bid, LocalRecord.with(b, "ficheId", .string(newId)))
        }
        host?.syncDidReassign(.fiche, from: oldId, to: newId)
        return rec
    }

    /// `_reclaimBlocked` : modifications locales dans une bibliothèque où je ne suis plus éditeur.
    /// DUPLIQUÉES en Perso D'ABORD (au pire un doublon, jamais une modification effacée), puis la
    /// version de l'équipe est rétablie ; une suppression bloquée est simplement annulée.
    func reclaimBlocked(_ t: SyncTable, _ all: [JSON], skip: (JSON) -> Bool) async -> (done: Set<String>, copies: [JSON]) {
        var done = Set<String>(), copies: [JSON] = [], names: [String] = []
        var restoredDel = false
        let d = dir(t)
        let blocked = all.filter { o in
            LocalRecord.isDirty(o) && LocalRecord.library(o) != nil && !profile.canEdit(scope: LocalRecord.library(o)) && !skip(o)
        }
        for o in blocked {
            guard let id = LocalRecord.id(o) else { continue }
            do {
                if !LocalRecord.isDeleted(o) {
                    var c: [String: JSON]
                    switch t {
                    case .fiches: c = Sanitize.fiche(o).json.object ?? [:]
                    case .protocols: c = Sanitize.reference(o).json.object ?? [:]
                    case .sessions: c = o.object ?? [:]
                    }
                    let cid = Guard.uid(t.idPrefix)
                    c["id"] = .string(cid); c["library"] = .null; c["ownerId"] = .null
                    c["updatedBy"] = ""; c["updatedAt"] = .number(now()); c["dirty"] = true
                    try putRecord(d, cid, .object(c))
                    acc.upsert(decodeLocal(t, .object(c)))
                    copies.append(.object(c))
                } else { restoredDel = true }
                let rows = try await auth.rest("GET", "/rest/v1/\(t.remote)?id=eq.\(enc(id))&select=*")?.array ?? []
                if let r = rows.first, !(r["deleted_at"]?.truthy ?? false) {
                    let (rec, dec) = decode(t, r)
                    try putRecord(d, id, rec)
                    acc.upsert(dec)
                } else {
                    d.delete(id)
                    acc.remove(t, id)
                }
                done.insert(id)
                names.append(LocalRecord.title(o))
            } catch {
                // Réseau : l'enregistrement reste « dirty », l'opération sera rejouée.
            }
        }
        if !names.isEmpty {
            flush()
            host?.syncNotice(.rightsLost(names: names, copied: !copies.isEmpty, restoredDelete: restoredDel))
        }
        return (done, copies)
    }

    // MARK: Réconciliation des partagés

    /// `_reconcileShared` : retire localement les enregistrements PARTAGÉS devenus inaccessibles
    /// (déplacés hors de la bibliothèque, membre retiré, bibliothèque supprimée). Perso n'est jamais
    /// touché ; un enregistrement « dirty » non plus ; en cas d'échec réseau, rien n'est supprimé.
    /// ÉCART VOULU (spec D, Q2/Q4) : le web lit la vue de compatibilité `fiches?select=id` SANS
    /// pagination — au-delà de 1000 lignes visibles, il supprimerait à tort. Le natif lit
    /// `cognitive_aids` (mêmes ids) PAGINÉ par id, et ne supprime rien si la liste n'est pas complète.
    func reconcileShared() async throws {
        try await reconcile(.fiches)
        try await reconcile(.protocols)
    }

    func reconcile(_ t: SyncTable) async throws {
        var ids = Set<String>()
        var after = ""
        var complete = false
        do {
            for _ in 0..<50 {
                let rows = try await auth.rest("GET", "/rest/v1/\(t.remote)?select=id&order=id.asc" + (after.isEmpty ? "" : "&id=gt." + enc(after)) + "&limit=1000")?.array ?? []
                for r in rows { if let id = r["id"]?.string { ids.insert(id) } }
                if rows.count < 1000 { complete = true; break }
                after = rows.last?["id"]?.jsString ?? ""
            }
        } catch { return }
        guard complete else { return }
        let d = dir(t)
        for r in d.all() where LocalRecord.library(r) != nil && !LocalRecord.isDirty(r) {
            guard let id = LocalRecord.id(r), !ids.contains(id) else { continue }
            d.delete(id)
            acc.remove(t, id)
        }
    }
}
