import SwiftUI
import Observation
import AidesCore
#if canImport(UIKit)
import UIKit
#endif

/// Où l'on est (pile de navigation).
/// Les onglets racine (iOS 27 : `TabView` adaptable — barre d'onglets au téléphone, barre latérale
/// sur iPad et Mac). La recherche est un onglet à part entière (rôle `.search`), comme le veut la HIG.
enum RootTab: Hashable { case aides, sessions, me, search }

enum Route: Hashable {
    case fiche(String)
    case reference(String)
    case editFiche(String)
    case editReference(String)
    case pdf(String, String)   // (id du document, nom)
}

/// Message bref non bloquant (jamais pendant une crise, sauf réponse directe à un geste).
struct Toast: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var seconds: Double = 4
}

/// Bandeau d'alarme d'un minuteur échu sur une AUTRE aide que celle affichée (règle 11 : il
/// s'annonce sur place, ne s'impose jamais).
struct AlarmBanner: Identifiable, Equatable {
    let id = UUID()
    var ficheId: String
    var title: String
    var sub: String
}

enum ThemePref: String, CaseIterable { case auto, light, dark
    var label: String { switch self { case .auto: return "Auto"; case .light: return "Clair"; case .dark: return "Sombre" } }
    var scheme: ColorScheme? { switch self { case .auto: return nil; case .light: return .light; case .dark: return .dark } }
}

/// LE MODÈLE DE L'APPLICATION — relie la bibliothèque locale, le moteur de session, les
/// alarmes, la synchro. Toute l'interface lit ses propriétés observées ; tout geste passe par
/// ses méthodes (qui délèguent au cœur testé, AidesCore).
@MainActor
@Observable
final class AppModel {
    // MARK: Cœur
    let store: LocalStore
    private(set) var library: Library
    let engine = SessionEngine()
    let auth: AuthClient
    private(set) var sync: SyncEngine
    @ObservationIgnored private var bridge: EngineBridge?
    @ObservationIgnored private var tickTask: Task<Void, Never>?

    // MARK: État observé
    private(set) var fiches: [Fiche] = []
    private(set) var references: [Reference] = []
    private(set) var categories: [Category] = []
    private(set) var sessions: [JSON] = []
    private(set) var pins: [String] = []
    /// Révision de l'état vivant : incrémentée à chaque geste et à chaque battement (300 ms).
    private(set) var rev = 0
    /// Onglet racine (iOS 27 : barre d'onglets système au téléphone, barre latérale sur iPad/Mac).
    var rootTab: RootTab = .aides
    /// UNE pile de navigation PAR onglet (comportement système : changer d'onglet garde sa pile).
    var paths: [RootTab: [Route]] = [:]
    /// La pile de l'onglet affiché : c'est là qu'une ouverture pousse son écran.
    var path: [Route] {
        get { paths[rootTab] ?? [] }
        set { paths[rootTab] = newValue }
    }
    /// État de l'accueil, partagé par l'onglet « Aides » et l'onglet de recherche.
    let home = HomeState()
    /// Runtime de l'aide ouverte (vive ou non).
    var current: RuntimeSession?
    var toast: Toast?
    var banner: AlarmBanner?
    /// Lien d'appariement reçu (partage de session) en attente de traitement.
    var pendingJoinURL: URL?
    private(set) var syncStatus: SyncStatus = .connected
    private(set) var profile = Profile()
    var onboarded: Bool
    var theme: ThemePref { didSet { library.space.prefs["ac-theme"] = .string(theme.rawValue); store.global["ac-theme"] = .string(theme.rawValue) } }
    /// Taille du texte : 100 / 115 / 130 % (le `--zf` de la PWA).
    var textScale: Int { didSet { library.space.prefs["ac-zoom"] = .number(Double(textScale)) } }
    var soundOn = true { didSet { Alarm.shared.soundOn = soundOn } }
    var wakeWanted: Bool { didSet { library.space.prefs["ac-wake"] = .string(wakeWanted ? "1" : "0") } }
    /// « Ouvrir les aides en » : un bloc (journal) ou toute la fiche (Page).
    var readMode: String { didSet { library.space.prefs["ac-read-mode"] = .string(readMode) } }

    // MARK: État ajouté — zone ACCUEIL (réservé)
    /// Fenêtre que l'accueil ouvre à son arrivée (porte choisie sur l'écran de bienvenue).
    var homeRequest: HomeRequest?
    /// Bandeau système de l'accueil (C1 §1.2) : UN message à la fois, masque la notice d'auteur.
    var homeSysBanner: String?
    // MARK: État ajouté — zone COMPTE / CRÉER / IMPORT (réservé)
    /// Fichiers .json / .zip à faire passer par l'atelier d'import (dépôt sur l'accueil, « Ouvrir
    /// avec… ») : la coque présente `ImportWorkshopView(request:)` tant que ce champ est posé.
    var importRequest: ImportRequest?
    // MARK: État ajouté — zone MODE CRISE (réservé)
    // MARK: État ajouté — zone ÉDITEUR (réservé)
    // MARK: État ajouté — zone RÉFÉRENCE / PDF (réservé)
    // MARK: État ajouté — zone PARTAGE (réservé)

    static let appVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0.0"

    init() {
        let store = LocalStore(base: LocalStore.defaultBase())
        self.store = store
        let space = store.open(store.currentSpace)
        let lib = Library(space: space)
        self.library = lib
        let auth = AuthClient(config: SupabaseConfig.fromBundle(), secureStore: KeychainStore())
        self.auth = auth
        self.sync = SyncEngine(auth: auth, local: store, store: space)
        self.onboarded = store.global.string("ac-onboarded") == "1"
        theme = ThemePref(rawValue: space.prefs["ac-theme"]?.string ?? "") ?? .auto
        textScale = Int(space.prefs["ac-zoom"]?.number ?? 100)
        wakeWanted = space.prefs["ac-wake"]?.string != "0"
        readMode = space.prefs["ac-read-mode"]?.string ?? "overview"
        boot()
    }

    private func boot() {
        // Un espace de compte qui ne correspond plus à la session (bascule interrompue) : on suit le compte.
        if let uid = auth.userId, uid != store.currentSpace { switchSpace(to: uid) }
        library.identity = { [weak self] in (self?.auth.signedIn ?? false, self?.auth.email) }
        library.onLocalWrite = { [weak self] in self?.sync.schedule() }
        library.libraries = sync.profile.libraries
        library.load()
        let bridge = EngineBridge(model: self)
        self.bridge = bridge
        engine.delegate = bridge
        engine.restore(sessions: library.sessions, fiches: Dictionary(library.fiches.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }))
        sync.host = self
        sync.restoreProfileCache()
        profile = sync.profile
        library.libraries = profile.libraries
        refresh()
        library.collectGarbageAttachments()
        startTicking()
        // F5 : une seule session vive, dernier geste il y a moins de 10 min → on atterrit dans le soin.
        if engine.live.count == 1, let R = engine.live.values.first, JS.now() - (R.lastActAt ?? R.startedAt) <= 600_000 {
            current = R
            path = [.fiche(R.ficheId)]
        }
        if auth.signedIn { Task { await sync.full() } }
    }

    /// Recopie les collections du cœur dans l'état observé.
    func refresh() {
        fiches = library.fiches
        references = library.protocols
        categories = library.categories
        sessions = library.sessions
        pins = library.pins
    }
    func touch() { rev &+= 1 }

    // MARK: Espaces de compte

    /// Bascule d'espace (connexion d'un autre compte) : tout l'état en mémoire est remplacé —
    /// l'équivalent natif du rechargement de page de la PWA. Jamais de mélange entre comptes.
    func switchSpace(to space: String) {
        engine.persistAll()
        store.currentSpace = space
        let s = store.open(space)
        library = Library(space: s)
        sync = SyncEngine(auth: auth, local: store, store: s)
        sync.host = self
        library.identity = { [weak self] in (self?.auth.signedIn ?? false, self?.auth.email) }
        library.onLocalWrite = { [weak self] in self?.sync.schedule() }
        library.load()
        current = nil
        paths = [:]
        rootTab = .aides
        refresh()
    }

    // MARK: Battement (tickAll, 300 ms)

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard let self else { return }
                let active = !self.engine.live.isEmpty || (self.current?.started ?? false)
                if active {
                    self.engine.tick()
                    self.touch()
                }
            }
        }
    }

    // MARK: Cycle de vie de l'app

    func scenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .background, .inactive:
            engine.persistAll()
            scheduleTimerNotifications()
        case .active:
            Notifier.cancelAll()
            sync.appDidBecomeActive()
        @unknown default: break
        }
    }

    /// En arrière-plan, le système prend le relais : une notification par minuteur à échéance qui tourne.
    private func scheduleTimerNotifications() {
        Notifier.cancelAll()
        let now = JS.now()
        for R in engine.live.values {
            for t in R.orderedTimers where t.type == .interval && t.running && t.period > 0 {
                let due = t.lastStart + (t.period - t.elapsedMs)
                let action = JS.trim(t.onDue)
                Notifier.schedule(id: R.ficheId + "-" + t.id, title: "⏰ " + t.name + (action.isEmpty ? "" : " — " + action) + " — terminé",
                                  body: R.fiche.title.isEmpty ? "Aide cognitive" : R.fiche.title, dueAt: due)
                if t.autoloop {   // la prochaine borne seulement : l'app reprend la main au retour
                    _ = now
                }
            }
        }
    }

    /// Veille de l'écran : coupée tant qu'une crise est à l'écran (et que l'utilisateur le veut).
    func applyWake(crisisOnScreen: Bool) {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = crisisOnScreen && wakeWanted
        #endif
    }

    // MARK: Ouverture

    func openFiche(_ id: String) {
        guard let f = fiches.first(where: { $0.id == id }) else { toast("⚠ Fiche introuvable."); return }
        current = engine.runtimeFor(f, keepIfNotStarted: current)
        library.bumpUsage(id)
        path.append(.fiche(id))
        touch()
    }
    func openReference(_ id: String) {
        library.bumpUsage(id)
        path.append(.reference(id))
    }
    /// Ouvre une entité liée (« Voir aussi », complication vers une autre aide).
    func openLinked(_ id: String) {
        if fiches.contains(where: { $0.id == id }) { openFiche(id) }
        else if references.contains(where: { $0.id == id }) { openReference(id) }
        else { toast("⚠ Élément introuvable (supprimé, ou dans une bibliothèque à laquelle vous n’avez pas accès).") }
    }
    func runtime(for ficheId: String) -> RuntimeSession? {
        if let c = current, c.ficheId == ficheId { return c }
        if let R = engine.live[ficheId] { return R }
        guard let f = fiches.first(where: { $0.id == ficheId }) else { return nil }
        let R = engine.runtimeFor(f, keepIfNotStarted: nil)
        current = R
        return R
    }

    // MARK: Gestes de session (délégués au moteur, puis rafraîchissement)

    func act(_ R: RuntimeSession, _ f: (SessionEngine, RuntimeSession) -> Void) {
        f(engine, R)
        touch()
    }
    func endSession(_ R: RuntimeSession) {
        engine.end(R)
        if current === R, let f = fiches.first(where: { $0.id == R.ficheId }) {
            current = engine.runtimeFor(f, keepIfNotStarted: nil)
        }
        refresh()
        touch()
    }
    func armExercise(_ f: Fiche) {
        if let R = engine.live[f.id] { engine.end(R) }
        current = engine.armExercise(f)
        touch()
    }
    func cancelExercise(_ f: Fiche) {
        guard let R = current, R.exercise, !R.started else { return }
        current = engine.runtimeFor(f, keepIfNotStarted: nil)
        touch()
    }
    func resumeSession(_ s: JSON) {
        guard let fid = s["ficheId"]?.string, let f = fiches.first(where: { $0.id == fid }) else { toast("⚠ Fiche introuvable."); return }
        current = engine.resume(f, session: s)
        path.append(.fiche(fid))
        refresh(); touch()
    }
    func deleteSession(_ id: String) {
        engine.drop(sessionId: id)
        library.deleteSession(id, syncHistory: library.space.prefs["ac-sync-sessions"]?.string == "1")
        refresh()
    }

    // MARK: Écritures de contenu

    @discardableResult
    func save(_ f: Fiche) -> Bool {
        let ok = library.persist(f)
        if !ok { toast("⚠ Stockage saturé. Exportez vos fiches puis allégez les images.") }
        refresh()
        return ok
    }
    @discardableResult
    func save(_ p: Reference) -> Bool {
        let ok = library.persist(p)
        if !ok { toast("⚠ Stockage saturé. Exportez vos données puis allégez les images.") }
        refresh()
        return ok
    }
    func delete(_ f: Fiche) {
        if let R = engine.live[f.id] { engine.end(R) }
        library.delete(f)
        for s in sessions where s["ficheId"]?.string == f.id { if let id = s["id"]?.string { library.deleteSession(id, syncHistory: false) } }
        for k in paths.keys { paths[k]?.removeAll { $0 == .fiche(f.id) || $0 == .editFiche(f.id) } }
        refresh()
    }
    func delete(_ p: Reference) {
        library.delete(p)
        for k in paths.keys { paths[k]?.removeAll { $0 == .reference(p.id) || $0 == .editReference(p.id) } }
        refresh()
    }
    func togglePin(_ id: String) { library.togglePin(id); refresh() }
    func saveNote(_ ficheId: String, _ text: String) { library.saveNote(ficheId, text) }
    func saveCategories(scope: String?) { library.saveCategories(scope: scope); refresh() }
    func setCategories(_ cats: [Category], scope: String?) { library.categories = cats; saveCategories(scope: scope) }

    /// « Voir des fiches d'exemple » : les deux aides de la PWA, en BROUILLON, à relire.
    func addExamples() {
        guard let url = Bundle.main.url(forResource: "exemples", withExtension: "json"),
              let d = try? Data(contentsOf: url), let arr = try? JSON.parse(d).array else { return }
        let urg = categories.first { $0.name == "Urgences" }?.id ?? categories.first?.id ?? ""
        let smur = categories.first { $0.name == "SMUR" }?.id ?? urg
        for j in arr {
            var f = Sanitize.fiche(j)
            f.id = Guard.uid()
            f.category = f.category == "__URG__" ? urg : (f.category == "__SMUR__" ? smur : "")
            f.order = JS.now()
            f.status = .draft
            library.persist(f)
        }
        refresh()
        toast("2 fiches d’exemple ajoutées. Relisez-les et validez-les : vous êtes responsable du contenu clinique.", seconds: 8)
    }
    func finishOnboarding() { onboarded = true; store.global["ac-onboarded"] = "1" }

    func toast(_ text: String, seconds: Double = 4) { toast = Toast(text: text, seconds: seconds) }

    // MARK: Compte

    func signedIn() -> Bool { auth.signedIn }
    func afterSignIn() async {
        if let uid = auth.userId, uid != store.currentSpace {
            let hasAnon = store.currentSpace.isEmpty && !library.fiches.isEmpty
            _ = hasAnon
            switchSpace(to: uid)
        }
        await sync.refreshAccountStatus()
        await sync.full()
        profile = sync.profile
        library.libraries = profile.libraries
        refresh()
    }
    /// Emporter les fiches « hors compte » dans le compte (proposé à la première connexion).
    func moveAnonymousData(to uid: String) {
        try? store.moveData(from: "", to: uid)
    }
    func signOut(wipe: Bool) async {
        await auth.signOut()
        sync.resetAuthState()
        if wipe {
            let sp = store.currentSpace
            store.wipeSpace(sp)
            switchSpace(to: sp)
        }
        profile = Profile()
        library.libraries = []
        refresh()
    }
}

// MARK: - Synchro → modèle

extension AppModel: SyncHost {
    func syncStatusDidChange(_ status: SyncStatus) { syncStatus = status }
    func syncDidApply(_ changes: SyncChanges) {
        // Le disque a changé sous nous : on relit (tout repasse par migrate). Une session vive
        // garde son Runtime ; son aide y est re-pointée.
        library.load()
        for R in engine.live.values { if let f = library.fiches.first(where: { $0.id == R.ficheId }) { R.fiche = f } }
        if let c = current, let f = library.fiches.first(where: { $0.id == c.ficheId }) { c.fiche = f }
        refresh()
    }
    func syncNotice(_ notice: SyncNotice) {
        // Règle 11 : jamais de notification flottante pendant une crise à l'écran.
        if current?.started == true, case .fiche? = path.last { return }
        toast(notice.message, seconds: Double(notice.durationMs) / 1000)
    }
    func syncProfileDidChange(_ profile: Profile) {
        self.profile = profile
        library.libraries = profile.libraries
    }
    func syncDidReassign(_ kind: SyncEntityKind, from oldId: String, to newId: String) {
        library.load()
        if let R = engine.live[oldId], let f = library.fiches.first(where: { $0.id == newId }) { R.fiche = f; R.ficheId = newId }
        for k in paths.keys {
            paths[k] = paths[k]?.map { r in
                switch r {
                case .fiche(let i) where i == oldId: return .fiche(newId)
                case .reference(let i) where i == oldId: return .reference(newId)
                default: return r
                }
            }
        }
        refresh()
    }
}

// MARK: - Moteur → modèle

/// Pont non isolé : le protocole du moteur n'est pas lié à un acteur (le cœur se teste sous
/// Linux) ; l'app n'appelle le moteur que depuis le fil principal.
final class EngineBridge: SessionEngineDelegate {
    weak var model: AppModel?
    init(model: AppModel) { self.model = model }

    func engine(_ e: SessionEngine, persist snapshot: JSON, of R: RuntimeSession) {
        MainActor.assumeIsolated {
            guard let m = model else { return }
            m.library.upsertSession(snapshot)
            m.refreshSessionsOnly()
        }
    }
    func engine(_ e: SessionEngine, timerFired t: TimerState, in R: RuntimeSession) {
        MainActor.assumeIsolated {
            Alarm.shared.beep()
            guard let m = model else { return }
            let onScreen = m.current === R
            if !onScreen {
                let action = JS.trim(t.onDue)
                m.banner = AlarmBanner(ficheId: R.ficheId, title: t.name + (action.isEmpty ? "" : " — " + action) + " — terminé",
                                       sub: R.fiche.title.isEmpty ? "Aide cognitive" : R.fiche.title)
            }
        }
    }
    func engine(_ e: SessionEngine, started R: RuntimeSession) {
        MainActor.assumeIsolated {
            Alarm.shared.prepare()
            Notifier.requestPermission()
        }
    }
    func engine(_ e: SessionEngine, ended R: RuntimeSession, snapshot: JSON?) {
        MainActor.assumeIsolated { model?.refresh() }
    }
    func engineTick(_ e: SessionEngine) {
        MainActor.assumeIsolated { Alarm.shared.tick() }
    }
}

extension AppModel {
    func refreshSessionsOnly() { sessions = library.sessions }
}
