import SwiftUI
import AidesCore

// L'ACCUEIL — port de `renderLibrary` / `renderHomeList` / `homeSideHtml` (C1 §1, §3).
//
// Deux compositions, décidées par la largeur EFFECTIVE (`\.widthClass`, déjà divisée par la
// taille du texte) :
//  • téléphone (< 780) : UNE colonne qui défile en entier, en-tête statique (il part avec la
//    page), recherche + filtre FLOTTANT au pouce en bas (A423 — pas la recherche système dans la
//    barre de navigation : la position est une décision de dessin), rail A→Z à droite ;
//  • ≥ 780 : colonne gauche fixe de 250 pt (bibliothèques, catégories, Sessions, Moi) + colonne
//    principale de 960 pt au plus, centrée, qui défile seule. Sessions et Moi y sont des VUES de
//    la colonne principale (A365) ; au téléphone, des fenêtres.

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
    @State private var st = HomeState()
    @State private var loadedSpace: String?
    @State private var sheet: HomeSheet?
    @State private var qText = ""
    @FocusState private var searchFocused: Bool
    @State private var exporter = HomeExportJob()

    var body: some View {
        let corpus = HomeCorpus(model: model)
        layout(corpus)
            .sheet(item: $sheet) { s in
                HomeSheetHost(sheet: s, st: st, corpus: corpus, sheetBinding: $sheet, exporter: exporter)
            }
            .homeExporter(exporter)
            .onAppear {
                loadPrefsIfNeeded()
                consumeRequest()
            }
            .onChange(of: model.store.currentSpace) { loadPrefsIfNeeded() }
            .onChange(of: model.homeRequest) { consumeRequest() }
            .onChange(of: st.section) { _, v in model.setHomePref("ac-section", v.rawValue) }
            .onChange(of: st.group) { _, v in model.setHomePref("ac-home-group", v.rawValue) }
            .onChange(of: st.sort) { _, v in model.setHomePref("ac-home-sort", v.rawValue) }
            .onChange(of: st.compact) { _, v in model.setHomePref("ac-home-compact", v ? "1" : "0") }
            // La sélection se referme en quittant l'accueil (§3.11).
            .onChange(of: model.path) { _, p in if !p.isEmpty { st.endSelection() } }
            // `syncHomeTabs` : franchir 780 convertit une présentation dans l'autre.
            .onChange(of: wc) { _, w in
                if w == .phone && st.tab != .aides {
                    let t = st.tab
                    st.tab = .aides
                    sheet = t == .sessions ? .sessions : .account
                } else if w != .phone, sheet == .sessions || sheet == .account {
                    st.tab = sheet == .sessions ? .sessions : .me
                    sheet = nil
                }
            }
            // Recherche différée de 150 ms (`#q` : `input` → re-rendu) ; taper ramène à « Aides ».
            .task(id: qText) {
                if qText == st.q { return }
                try? await Task.sleep(nanoseconds: 150_000_000)
                if Task.isCancelled { return }
                st.q = qText
                st.tab = .aides
                st.libLimit = 60
            }
            .onChange(of: st.q) { _, v in if v != qText { qText = v } }
            .background {
                // ⌘K (Mac, iPad avec clavier) : place le curseur dans la recherche (§17.2).
                Button("Rechercher") { st.tab = .aides; searchFocused = true }
                    .keyboardShortcut("k", modifiers: .command)
                    .opacity(0)
                    .accessibilityHidden(true)
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
    }

    @ViewBuilder
    private func layout(_ corpus: HomeCorpus) -> some View {
        if wc == .phone {
            HomePhoneLayout(st: st, corpus: corpus, sheet: $sheet, qText: $qText, searchFocused: $searchFocused, exporter: exporter)
        } else {
            HomeWideLayout(st: st, corpus: corpus, sheet: $sheet, qText: $qText, searchFocused: $searchFocused, exporter: exporter)
        }
    }

    private func loadPrefsIfNeeded() {
        let sp = model.store.currentSpace
        if loadedSpace == sp { return }
        loadedSpace = sp
        st.load(from: model)
        st.endSelection()
        st.lib = nil; st.cat = nil
    }
    /// Porte choisie sur l'écran de bienvenue (§2) : l'accueil l'ouvre dès qu'il est là.
    private func consumeRequest() {
        guard let r = model.homeRequest else { return }
        model.homeRequest = nil
        switch r {
        case .create: sheet = .create
        case .join: sheet = .join
        case .account:
            if wc == .phone { sheet = .account } else { st.tab = .me }
        }
    }
}

// MARK: - Compositions

/// Téléphone : une seule colonne, dock flottant en bas.
struct HomePhoneLayout: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?
    @Binding var qText: String
    var searchFocused: FocusState<Bool>.Binding
    let exporter: HomeExportJob

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HomePhoneHeader(st: st, corpus: corpus, sheet: $sheet)
                    HomeMainContent(st: st, corpus: corpus, sheet: $sheet, exporter: exporter)
                        .padding(.horizontal, 16)
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
                HomeAZRail(st: st, corpus: corpus, proxy: proxy)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HomeSearchDock(st: st, qText: $qText, sheet: $sheet, searchFocused: searchFocused, wide: false)
            }
        }
        .background(T.amb.ignoresSafeArea())
    }
}

/// ≥ 780 : colonne gauche fixe + colonne principale bornée à 960, centrée.
struct HomeWideLayout: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?
    @Binding var qText: String
    var searchFocused: FocusState<Bool>.Binding
    let exporter: HomeExportJob

    var body: some View {
        HStack(spacing: 0) {
            HomeSidebar(st: st, corpus: corpus, sheet: $sheet)
                .frame(width: 250)
            Rectangle().fill(T.line).frame(width: 1).ignoresSafeArea()
            VStack(spacing: 0) {
                if st.tab == .aides {
                    HStack(spacing: 8) {
                        HomeSearchDock(st: st, qText: $qText, sheet: $sheet, searchFocused: searchFocused, wide: true)
                        HomeCreateButton(corpus: corpus, st: st, sheet: $sheet, wide: true)
                    }
                    .frame(maxWidth: 960)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                }
                mainColumn
            }
        }
        .background(T.amb.ignoresSafeArea())
    }

    @ViewBuilder
    private var mainColumn: some View {
        switch st.tab {
        case .aides:
            ScrollViewReader { _ in
                ScrollView {
                    HomeMainContent(st: st, corpus: corpus, sheet: $sheet, exporter: exporter)
                        .frame(maxWidth: 960)
                        .padding(.horizontal, 22)
                        .padding(.top, 18)
                        .padding(.bottom, 32)
                        .frame(maxWidth: .infinity)
                }
            }
        case .sessions:
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sessions").aFont(TypeScale.display[1], .heavy).foregroundStyle(T.ink)
                        .accessibilityAddTraits(.isHeader)
                    SessionsHistoryView(ficheId: nil, embedded: true)
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
            }
        case .me:
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Moi").aFont(TypeScale.display[1], .heavy).foregroundStyle(T.ink)
                        .accessibilityAddTraits(.isHeader)
                    AccountView()
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - En-tête (téléphone)

/// En-tête statique du téléphone (§3.3.1) : logo, « Aides cognitives », Sessions, Créer, compte.
struct HomePhoneHeader: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.square.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(T.act)
                .accessibilityHidden(true)
            Text("Aides cognitives").aFont(TypeScale.stepL, .semibold, .title).foregroundStyle(T.ink)
                .lineLimit(1).minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
            Button { sheet = .sessions } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: Ctrl.m, height: Ctrl.m)
                    .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.workLine))
            }
            .buttonStyle(.plain)
            .foregroundStyle(T.ink)
            .accessibilityLabel("Sessions — historique")
            .help("Sessions")
            HomeCreateButton(corpus: corpus, st: st, sheet: $sheet, wide: false)
            HomeAccountDisc(sheet: $sheet)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

/// « ＋ Créer » (`#hdrNew`) : seulement quand la portée affichée est modifiable.
struct HomeCreateButton: View {
    @Environment(AppModel.self) private var model
    let corpus: HomeCorpus
    let st: HomeState
    @Binding var sheet: HomeSheet?
    var wide: Bool

    var body: some View {
        if st.tab == .aides && corpus.canEdit(scope: st.lib ?? "") {
            Button { sheet = .create } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                    Text("Créer").aFont(TypeScale.item, .bold)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: Ctrl.m)
                .foregroundStyle(wide ? T.act : T.onPrimary)
                .background(wide ? T.amb2 : T.act, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(st.section == .protocols ? "Créer un protocole" : "Créer une aide cognitive")
            .help(st.section == .protocols ? "Créer un protocole" : "Créer une aide cognitive")
        }
    }
}

/// Disque du compte (`#acctTop`) : initiales quand connecté, pastille d'état de la synchro.
struct HomeAccountDisc: View {
    @Environment(AppModel.self) private var model
    @Binding var sheet: HomeSheet?

    var body: some View {
        let email = model.auth.email ?? ""
        let signed = model.auth.signedIn
        Button { sheet = .account } label: {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if signed && !email.isEmpty {
                        Text(verbatim: String(email.prefix(2)).uppercased()).aFont(TypeScale.body, .heavy)
                            .foregroundStyle(T.onPrimary)
                            .frame(width: Ctrl.m, height: Ctrl.m)
                            .background(T.act, in: Circle())
                    } else {
                        Image(systemName: "person.fill").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(T.ink)
                            .frame(width: Ctrl.m, height: Ctrl.m)
                            .background(T.work, in: Circle())
                            .overlay(Circle().strokeBorder(T.workLine))
                    }
                }
                if signed { HomeSyncDot(state: model.syncStatus.state).offset(x: 2, y: 2) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Compte et synchronisation")
        .help(signed && !email.isEmpty ? "Compte — " + email : "Compte")
    }
}

/// Pastille d'état de la synchro (jamais une couleur seule : l'état se dit en mots ailleurs,
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
        Image(systemName: glyph).font(.system(size: 7, weight: .black)).foregroundStyle(T.work)
            .frame(width: 14, height: 14).background(color, in: Circle())
            .overlay(Circle().strokeBorder(T.amb, lineWidth: 1.5))
            .accessibilityHidden(true)
    }
}

// MARK: - Recherche et filtre (dock)

/// `#homeDock` : bouton rond « Affichage et filtres » + champ de recherche en capsule ; pendant
/// une recherche, les puces « Tout · Aides · Protocoles » au-dessus (§3.4).
struct HomeSearchDock: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    @Binding var qText: String
    @Binding var sheet: HomeSheet?
    var searchFocused: FocusState<Bool>.Binding
    var wide: Bool

    var body: some View {
        VStack(spacing: 8) {
            if !st.q.isEmpty && st.tab == .aides {
                HStack(spacing: 6) {
                    ForEach(HomeSection.allCases, id: \.self) { s in
                        Button { st.section = s; st.rev = false } label: {
                            Chip(text: s.chip, selected: st.section == s && !st.rev)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(st.section == s && !st.rev ? .isSelected : [])
                    }
                    Spacer()
                }
            }
            HStack(spacing: 8) {
                filterButton
                searchField
            }
        }
        .padding(.horizontal, wide ? 0 : 16)
        .padding(.top, wide ? 0 : 12)
        .padding(.bottom, wide ? 0 : 12)
        .background {
            if !wide {
                LinearGradient(colors: [T.amb.opacity(0), T.amb.opacity(0.92), T.amb], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
        }
    }

    private var filterButton: some View {
        let n = st.activeFilterCount
        let open = sheet == .display
        let base = open ? "Fermer l'affichage et les filtres" : "Affichage et filtres"
        let label = base + (n > 0 ? " — \(n) actif" + (n > 1 ? "s" : "") : "")
        return Button { sheet = open ? nil : .display } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(n > 0 ? T.act : T.ink)
                    .frame(width: Ctrl.l, height: Ctrl.l)
                    .background(n > 0 ? T.primarySoft : T.work, in: Circle())
                    .overlay(Circle().strokeBorder(n > 0 ? T.act : T.workLine))
                    .shadow(color: .black.opacity(wide ? 0 : 0.12), radius: 8, y: 3)
                if n > 0 {
                    Text(verbatim: "\(n)").aFont(TypeScale.cap, .heavy).foregroundStyle(T.onPrimary)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(T.act, in: Circle())
                        .offset(x: 3, y: -3)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .help(label)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .semibold)).foregroundStyle(T.ink2)
                .accessibilityHidden(true)
            TextField("Rechercher une aide, un protocole…", text: $qText)
                .aFont(16, .regular)   // 16 : sous 16 pt, iOS zoome au focus (règle 9)
                .foregroundStyle(T.ink)
                .focused(searchFocused)
                .autocorrectionDisabled()
                .submitLabel(.search)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .accessibilityLabel("Rechercher")
            if !qText.isEmpty {
                Button {
                    qText = ""; st.q = ""
                    searchFocused.wrappedValue = true
                } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 17)).foregroundStyle(T.ink3)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Effacer la recherche")
                .help("Effacer la recherche")
            } else if wide {
                Text(verbatim: "⌘K").aFont(TypeScale.meta, .bold, .mono).foregroundStyle(T.ink3)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(T.line))
                    .accessibilityHidden(true)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .frame(height: Ctrl.l)
        .background(T.work, in: Capsule())
        .overlay(Capsule().strokeBorder(T.workLine))
        .shadow(color: .black.opacity(wide ? 0 : 0.12), radius: 8, y: 3)
        .frame(maxWidth: .infinity)
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
                    else { Image(systemName: "checkmark").font(.system(size: 15, weight: .heavy)) }
                }
                .foregroundStyle(r.exercise ? T.act : T.ok)
                .accessibilityHidden(true)
                (Text(r.exercise ? "Exercice terminé" : "Session terminée").bold()
                 + Text(verbatim: " — " + r.title + " · " + Fmt.ms(r.dur) + " · \(r.done)/\(r.passes) bloc" + (r.passes > 1 ? "s" : "") + " ✓"))
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
                Circle().fill(phone ? T.okSys : T.ok).frame(width: 10, height: 10).padding(.top, 5)
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
                if s.state == .err { sheet = .syncError } else { sheet = .account }
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
