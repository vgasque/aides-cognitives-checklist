import SwiftUI
import AidesCore

// L'ACCUEIL — port de `renderLibrary` / `renderHomeList` / `homeSideHtml` (C1 §1, §3), sur la
// grammaire iOS 27 (Liquid Glass).
//
// La coque est SYSTÈME (cf. `RootView`) : onglets Aides · Sessions · Moi · Recherche, barre
// d'onglets flottante au téléphone, barre latérale sur iPad et Mac. L'accueil n'a donc plus ni
// en-tête dessiné, ni quai de recherche, ni disque de compte : un grand titre, une barre d'outils
// (« Affichage » en symbole, « Créer » en action PROÉMINENTE à droite) et la recherche dans son
// onglet (avec ses portées « Tout · Aides · Protocoles »).
//
// Deux compositions, décidées par la largeur EFFECTIVE (`\.widthClass`, déjà divisée par la
// taille du texte) :
//  • téléphone (< 780) : UNE colonne qui défile en entier, rail A→Z à droite ;
//  • ≥ 780 : colonne des FILTRES (bibliothèques, catégories, état de la synchro) à gauche, liste
//    de 960 pt au plus, centrée, qui défile seule. Sessions et Moi sont des onglets.

/// Les fenêtres que l'accueil présente (une à la fois).
enum HomeSheet: Identifiable, Equatable {
    case display, create, account, sessions, join, syncError
    case catMgr(String?)
    case report(String)
    case endSession(String)
    case selActions, selMoveLib, selCategory, selDelete
    var id: String {
        switch self {
        case .display: return "display"
        case .create: return "create"
        case .account: return "account"
        case .sessions: return "sessions"
        case .join: return "join"
        case .syncError: return "syncError"
        case .catMgr(let s): return "catMgr:" + (s ?? "*")
        case .report(let s): return "report:" + s
        case .endSession(let s): return "end:" + s
        case .selActions: return "selActions"
        case .selMoveLib: return "selMoveLib"
        case .selCategory: return "selCategory"
        case .selDelete: return "selDelete"
        }
    }
}

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.widthClass) private var wc
    /// true = l'accueil affiché DANS l'onglet de recherche (champ système, portées, une colonne).
    var searchMode = false
    @State private var sheet: HomeSheet?
    @State private var qText = ""
    @State private var exporter = HomeExportJob()

    private var st: HomeState { model.home }

    var body: some View {
        let corpus = HomeCorpus(model: model)
        layout(corpus)
            .navigationTitle(searchMode ? "Rechercher" : "Aides")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar { toolbar(corpus) }
            .modifier(HomeSearchable(on: searchMode, st: st, qText: $qText))
            .sheet(item: $sheet) { s in
                HomeSheetHost(sheet: s, st: st, corpus: corpus, sheetBinding: $sheet, exporter: exporter)
            }
            .homeExporter(exporter)
            .onAppear {
                loadPrefsIfNeeded()
                consumeRequest()
                qText = st.q
            }
            .onChange(of: model.store.currentSpace) { loadPrefsIfNeeded() }
            .onChange(of: model.homeRequest) { consumeRequest() }
            .onChange(of: st.section) { _, v in model.setHomePref("ac-section", v.rawValue) }
            .onChange(of: st.group) { _, v in model.setHomePref("ac-home-group", v.rawValue) }
            .onChange(of: st.sort) { _, v in model.setHomePref("ac-home-sort", v.rawValue) }
            .onChange(of: st.compact) { _, v in model.setHomePref("ac-home-compact", v ? "1" : "0") }
            // La sélection se referme en quittant l'accueil (§3.11).
            .onChange(of: model.path) { _, p in if !p.isEmpty { st.endSelection() } }
            // Recherche différée de 150 ms (`#q` : `input` → re-rendu).
            .task(id: qText) {
                guard searchMode, qText != st.q else { return }
                try? await Task.sleep(nanoseconds: 150_000_000)
                if Task.isCancelled { return }
                st.q = qText
                st.libLimit = 60
            }
            .onChange(of: st.q) { _, v in if v != qText { qText = v } }
            .background {
                // ⌘K (Mac, iPad avec clavier) : ouvre l'onglet de recherche (§17.2).
                Button("Rechercher") { model.rootTab = .search }
                    .keyboardShortcut("k", modifiers: .command)
                    .opacity(0)
                    .accessibilityHidden(true)
            }
    }

    @ViewBuilder
    private func layout(_ corpus: HomeCorpus) -> some View {
        if wc == .phone || searchMode {
            HomePhoneLayout(st: st, corpus: corpus, sheet: $sheet, exporter: exporter, rail: !searchMode && wc == .phone)
        } else {
            HomeWideLayout(st: st, corpus: corpus, sheet: $sheet, exporter: exporter)
        }
    }

    /// Barre d'outils (HIG iOS 27) : au plus deux groupes — « Affichage » en symbole, puis
    /// « Créer », SEULE action proéminente, au bord droit.
    @ToolbarContentBuilder
    private func toolbar(_ corpus: HomeCorpus) -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            let n = st.activeFilterCount
            let label = "Affichage et filtres" + (n > 0 ? " — \(n) actif" + either(n > 1, "s", "") : "")
            Button { sheet = .display } label: {
                Image(systemName: n > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
            }
            .accessibilityLabel(label)
            .help(label)
        }
        if !searchMode && corpus.canEdit(scope: st.lib ?? "") {
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItem(placement: .primaryAction) {
                let label = st.section == .protocols ? "Créer un protocole" : "Créer une aide cognitive"
                Button { sheet = .create } label: { Image(systemName: "plus") }
                    .buttonStyle(.glassProminent)
                    .accessibilityLabel(label)
                    .help(label)
            }
        }
    }

    private func loadPrefsIfNeeded() {
        let sp = model.store.currentSpace
        if st.loadedSpace == sp { return }
        st.loadedSpace = sp
        st.load(from: model)
        st.endSelection()
        st.lib = nil; st.cat = nil
    }
    /// Porte choisie sur l'écran de bienvenue (§2) : l'accueil l'ouvre dès qu'il est là.
    private func consumeRequest() {
        guard !searchMode, let r = model.homeRequest else { return }
        model.homeRequest = nil
        switch r {
        case .create: sheet = .create
        case .join: sheet = .join
        case .account: model.rootTab = .me
        }
    }
}

/// Recherche SYSTÈME de l'onglet « Rechercher » : champ dans la barre (flottant au pouce sur
/// iPhone), portées « Tout · Aides · Protocoles » sous le champ.
private struct HomeSearchable: ViewModifier {
    var on: Bool
    let st: HomeState
    @Binding var qText: String
    func body(content: Content) -> some View {
        @Bindable var st = st
        if on {
            content
                .searchable(text: $qText, prompt: "Aide, protocole, mot-clé…")
                .searchScopes($st.section, activation: .onSearchPresentation) {
                    ForEach(HomeSection.allCases, id: \.self) { s in Text(s.chip).tag(s) }
                }
                .onChange(of: st.section) { st.rev = false }
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
        } else {
            content
        }
    }
}

// MARK: - Compositions

/// Téléphone (et onglet de recherche) : une seule colonne.
struct HomePhoneLayout: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?
    let exporter: HomeExportJob
    var rail = true

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HomeMainContent(st: st, corpus: corpus, sheet: $sheet, exporter: exporter)
                        .frame(maxWidth: 960, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity)
                    HStack {
                        Spacer()
                        Text(verbatim: "v" + AppModel.appVersion).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .overlay(alignment: .trailing) {
                if rail { HomeAZRail(st: st, corpus: corpus, proxy: proxy) }
            }
        }
        .background(T.amb.ignoresSafeArea())
    }
}

/// ≥ 780 : colonne des filtres + liste centrée.
struct HomeWideLayout: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?
    let exporter: HomeExportJob

    var body: some View {
        HStack(spacing: 0) {
            HomeSidebar(st: st, corpus: corpus, sheet: $sheet)
                .frame(width: 250)
            Rectangle().fill(T.line).frame(width: 1).ignoresSafeArea()
            ScrollView {
                HomeMainContent(st: st, corpus: corpus, sheet: $sheet, exporter: exporter)
                    .frame(maxWidth: 960)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(T.amb.ignoresSafeArea())
    }
}

/// Pastille d'état de la synchro (jamais une couleur seule : l'état se dit en mots à côté,
/// et la pastille porte un glyphe).
struct HomeSyncDot: View {
    var state: SyncState
    private var color: Color {
        switch state {
        case .ok: return T.ok
        case .busy: return T.ink2
        case .off: return T.ink3
        case .err, .rejected, .pending: return T.warn
        }
    }
    private var glyph: String {
        switch state {
        case .ok: return "checkmark"
        case .busy: return "arrow.triangle.2.circlepath"
        case .off: return "pause.fill"
        case .err, .rejected: return "exclamationmark"
        case .pending: return "lock.fill"
        }
    }
    var body: some View {
        Image(systemName: glyph).font(.system(size: 7, weight: .black)).foregroundStyle(T.work)  // design: glyphe dans une pastille de 14 pt, sous le plancher du texte
            .frame(width: 14, height: 14).background(color, in: Circle())
            .overlay(Circle().strokeBorder(T.amb, lineWidth: 1.5))
            .accessibilityHidden(true)
    }
}

// MARK: - Colonne principale : blocs du haut puis liste

/// `renderHomeList` : barre de sélection, ligne « code reconnu », bilan, sessions vives, notice de
/// synchro, notices d'amorçage, puis la liste (§3.6).
struct HomeMainContent: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?
    let exporter: HomeExportJob

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12, pinnedViews: st.selOn ? [.sectionHeaders] : []) {
            Section {
                if !st.selOn {
                    if let code = HomeSearch.shareCode(st.q) { HomeJoinLine(code: code, sheet: $sheet) }
                    if st.q.isEmpty {
                        HomeSystemBanner()
                        HomeRecapCard(sheet: $sheet)
                        HomeLiveCards(sheet: $sheet)
                    }
                }
                HomeSyncNotice(sheet: $sheet)
                if !st.selOn { HomeNotices(st: st, corpus: corpus) }
                HomeListArea(st: st, corpus: corpus, sheet: $sheet)
            } header: {
                if st.selOn { HomeSelectionBar(st: st, corpus: corpus, sheet: $sheet, exporter: exporter) }
            }
        }
    }
}

/// Ligne « Code de session reconnu » (§3.6.2).
struct HomeJoinLine: View {
    @Environment(AppModel.self) private var model
    var code: String
    @Binding var sheet: HomeSheet?
    var body: some View {
        let shown = String(code.prefix(4)) + "-" + String(code.suffix(4))
        WorkCard(padding: 12) {
            HStack(spacing: 12) {
                Text(verbatim: "⇄").aFont(TypeScale.stepL, .bold).foregroundStyle(T.act).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Code de session reconnu").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                    Text("Vous allez suivre la session d’un collègue").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                }
                Spacer(minLength: 8)
                Button("Rejoindre " + shown) {
                    // Contrat documenté des liens entrants (`AppModel.handleURL`).
                    model.pendingJoinURL = URL(string: "aidescog://join?code=" + code)
                    sheet = .join
                }
                .buttonStyle(.a(.primary, Ctrl.m))
            }
        }
    }
}

/// Bandeau système (§1.2) — un seul message à la fois ; ✕ « Masquer ».
struct HomeSystemBanner: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        if let text = model.homeSysBanner {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill").foregroundStyle(T.sysInk2).accessibilityHidden(true)
                Text(text).aFont(TypeScale.body, .semibold).foregroundStyle(T.sysInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("J’ai compris") { model.homeSysBanner = nil }
                    .buttonStyle(.plain)
                    .aFont(TypeScale.body, .bold)
                    .foregroundStyle(T.sysInk)
                    .padding(.horizontal, 10).frame(minHeight: Ctrl.s)
                    .overlay(Capsule().strokeBorder(T.sysLine))
                Button { model.homeSysBanner = nil } label: {
                    Image(systemName: "xmark").frame(width: Ctrl.s, height: Ctrl.s)
                }
                .buttonStyle(.plain)
                .foregroundStyle(T.sysInk2)
                .accessibilityLabel("Masquer")
            }
            .padding(12)
            .background(T.sys, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
        }
    }
}

/// Carte-bilan de la dernière session terminée (`lastEndedSession`, éphémère).
struct HomeRecapCard: View {
    @Environment(AppModel.self) private var model
    @Binding var sheet: HomeSheet?
    @State private var hiddenId: String?

    var body: some View {
        // Relue à chaque changement de l'historique (`model.sessions`) : une session supprimée
        // entre-temps efface la carte.
        if let r = model.engine.lastEnded, r.id != hiddenId, model.sessions.contains(where: { $0["id"]?.string == r.id }) {
            HStack(spacing: 10) {
                Group {
                    if r.exercise { Text(verbatim: "▲").aFont(TypeScale.item, .bold) }
                    else { Image(systemName: "checkmark").aFont(TypeScale.item, .heavy) }
                }
                .foregroundStyle(r.exercise ? T.act : T.ok)
                .accessibilityHidden(true)
                (Text(r.exercise ? "Exercice terminé" : "Session terminée").bold()
                 + Text(verbatim: " — " + r.title + " · " + Fmt.ms(r.dur) + " · \(r.done)/\(r.passes) bloc" + either(r.passes > 1, "s", "") + " ✓"))
                    .aFont(TypeScale.body, .regular)
                    .foregroundStyle(T.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Compte-rendu") { sheet = .report(r.id) }
                    .buttonStyle(.a(.secondary, Ctrl.s))
                Button {
                    hiddenId = r.id
                    model.engine.clearLastEnded()
                } label: { Image(systemName: "xmark").frame(width: Ctrl.s, height: Ctrl.s) }
                    .buttonStyle(.plain)
                    .foregroundStyle(T.ink2)
                    .accessibilityLabel("Masquer le bilan")
            }
            .padding(12)
            .background(r.exercise ? T.primarySoft : T.okSoft, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
        }
    }
}

/// Cartes « Session en cours » (une par session vive démarrée) — chrono vivant (§3.6.3c).
struct HomeLiveCards: View {
    @Environment(AppModel.self) private var model
    @Environment(\.widthClass) private var wc
    @Binding var sheet: HomeSheet?

    var body: some View {
        // `model.rev` bat toutes les 300 ms tant qu'une session vit : SEULES ces cartes le lisent.
        let _ = model.rev
        let _ = model.sessions.count
        ForEach(model.homeLiveSessions, id: \.ficheId) { R in
            card(R)
        }
    }

    @ViewBuilder
    private func card(_ R: RuntimeSession) -> some View {
        let chrono = Fmt.ms(JS.now() - R.startedAt)
        let whereTxt = homeLiveWhereText(R)
        let title = R.fiche.title.isEmpty ? "Aide cognitive" : R.fiche.title
        let phone = wc == .phone
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Circle().fill(phone ? T.okSys : T.ok).frame(width: 10, height: 10).padding(.top, 4)
                    .accessibilityHidden(true)
                Button { model.openFiche(R.ficheId) } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(R.exercise ? "Exercice en cours" : "Session en cours").aFont(TypeScale.meta, .bold)
                            .foregroundStyle(phone ? T.sysInk2 : T.ink2)
                        Text(title).aFont(TypeScale.item, .bold).foregroundStyle(phone ? T.sysInk : T.ink)
                            .lineLimit(2).multilineTextAlignment(.leading)
                        if !whereTxt.isEmpty {
                            Text(whereTxt).aFont(TypeScale.body, .regular).foregroundStyle(phone ? T.sysInk2 : T.ink2)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Reprendre la session")
                Text(verbatim: chrono).aFont(TypeScale.stepL, .bold, .mono)
                    .foregroundStyle(phone ? T.okSys : T.ok)
                    .accessibilityLabel("Durée " + chrono)
            }
            HStack(spacing: 8) {
                Button("Reprendre") { model.openFiche(R.ficheId) }
                    .buttonStyle(.a(.primary, phone ? 48 : Ctrl.m, full: phone))
                Button("Terminer") { sheet = .endSession(R.ficheId) }
                    .buttonStyle(.plain)
                    .aFont(TypeScale.item, .bold)
                    .foregroundStyle(phone ? T.critSys : T.crit)
                    .padding(.horizontal, 16)
                    .frame(minHeight: phone ? 48 : Ctrl.m)
                    .frame(maxWidth: phone ? .infinity : nil)
                    .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous)
                        .strokeBorder(phone ? T.critSys : T.critLine, lineWidth: phone ? 1 : 0))
                    .accessibilityLabel("Terminer la session — confirmation demandée")
                if !phone { Spacer() }
            }
        }
        .padding(14)
        .background(phone ? T.sys : T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(phone ? T.sysEdge : T.doneLine))
    }
}

/// Notice d'erreur / d'attente de la synchro (§3.6.4) — un tap ouvre le détail ou « Moi ».
struct HomeSyncNotice: View {
    @Environment(AppModel.self) private var model
    @Environment(\.widthClass) private var wc
    @Binding var sheet: HomeSheet?

    var body: some View {
        let s = model.syncStatus
        if model.auth.signedIn, let b = s.homeBanner(lastError: model.sync.lastError) {
            Button {
                if s.state == .err { sheet = .syncError } else { model.rootTab = .me }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: s.state == .pending ? "lock.fill" : (s.state == .rejected ? "nosign" : "exclamationmark.triangle.fill"))
                        .foregroundStyle(T.warn)
                        .accessibilityHidden(true)
                    (Text(b.bold).bold() + Text(b.rest))
                        .aFont(TypeScale.body, .regular)
                        .foregroundStyle(T.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right").foregroundStyle(T.ink3).accessibilityHidden(true)
                }
                .padding(12)
                .background(T.warnSoft, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.verifyLine))
            }
            .buttonStyle(.plain)
        }
    }
}

/// Notices d'amorçage (§3.6.5) : responsabilité de l'auteur ; fiches d'exemple.
struct HomeNotices: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @State private var authorHidden = false
    @State private var seedsHidden = false

    var body: some View {
        let authorOff = authorHidden || model.store.global.string("ac-notice-hidden") == "1"
        let seedsOff = seedsHidden || model.library.space.prefs.string("ac-seeds-hidden") == "1"
        let hasPersoFiche = model.fiches.contains { ($0.library ?? "").isEmpty }
        if st.lib == nil && !authorOff && model.homeSysBanner == nil {
            notice(icon: "info.circle") {
                Text("Vous êtes l'auteur et le responsable du contenu. Validez chaque fiche et tenez la date à jour.")
                    .aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
            } close: {
                model.store.global["ac-notice-hidden"] = "1"
                authorHidden = true
            }
        }
        if st.lib == nil && !hasPersoFiche && !seedsOff {
            notice(icon: "lightbulb") {
                VStack(alignment: .leading, spacing: 8) {
                    (Text("Besoin d'exemples pour commencer ?").bold()
                     + Text(" Ajoutez les deux fiches d'exemple (Anaphylaxie, Arrêt cardiaque) pour découvrir l'application — à relire et adapter avant tout usage clinique."))
                        .aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
                    Button("Ajouter les fiches d'exemple") { model.addExamplesFromHome() }
                        .buttonStyle(.a(.primary, Ctrl.s))
                }
            } close: {
                model.library.space.prefs["ac-seeds-hidden"] = "1"
                seedsHidden = true
            }
        }
    }

    private func notice<C: View>(icon: String, @ViewBuilder content: () -> C, close: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(T.ink2).accessibilityHidden(true).padding(.top, 2)
            content().frame(maxWidth: .infinity, alignment: .leading)
            Button(action: close) { Image(systemName: "xmark").frame(width: Ctrl.s, height: Ctrl.s) }
                .buttonStyle(.plain)
                .foregroundStyle(T.ink2)
                .accessibilityLabel("Masquer")
        }
        .padding(12)
        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.line))
    }
}
