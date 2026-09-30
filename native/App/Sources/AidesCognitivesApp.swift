import SwiftUI
import AidesCore

// Point d'entrée de l'application native (iPhone, iPad, Mac).
@main
struct AidesCognitivesApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(model.theme.scheme)
                .environment(\.textScale, CGFloat(model.textScale) / 100)
                .onChange(of: scenePhase) { _, p in model.scenePhaseChanged(p) }
                .onOpenURL { url in model.handleURL(url) }
        }
        #if os(macOS)
        .defaultSize(width: 1200, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        #endif
    }
}

/// La coque (iOS 27, Liquid Glass) : onglets SYSTÈME — Aides · Sessions · Moi · Recherche —
/// en barre d'onglets flottante au téléphone et en barre latérale sur iPad et Mac
/// (`.sidebarAdaptable`). Une pile de navigation par onglet ; l'écran de bienvenue passe avant.
/// Le mode crise masque la barre d'onglets : le quai de session est la seule barre du bas.
struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        GeometryReader { geo in
            Group {
                if model.onboarded || !model.fiches.isEmpty || !model.references.isEmpty {
                    tabs
                } else {
                    NavigationStack(path: pathBinding(.aides)) { WelcomeView().withRoutes() }
                }
            }
            .environment(\.widthClass, WidthClass.of(geo.size.width / (CGFloat(model.textScale) / 100)))
        }
        .background(T.amb.ignoresSafeArea())
        .tint(T.act)
        .overlay(alignment: .top) {
            if let b = model.banner {
                AlarmBannerView(banner: b)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: b.id) {
                        try? await Task.sleep(nanoseconds: 10_000_000_000)
                        if model.banner?.id == b.id { withAnimation { model.banner = nil } }
                    }
            }
        }
        .overlay(alignment: .bottom) {
            if let t = model.toast {
                ToastView(toast: t)
                    .padding(.bottom, 96)
                    .transition(.opacity)
                    .task(id: t.id) {
                        try? await Task.sleep(nanoseconds: UInt64(t.seconds * 1_000_000_000))
                        if model.toast?.id == t.id { withAnimation { model.toast = nil } }
                    }
                    .onTapGesture { model.toast = nil }
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.toast)
        .animation(.easeOut(duration: 0.2), value: model.banner)
        // Atelier d'import (fichiers déposés, « Ouvrir avec… ») : une porte, où que l'on soit.
        .sheet(item: $model.importRequest) { r in ImportWorkshopView(request: r) }
    }

    private var tabs: some View {
        @Bindable var model = model
        return TabView(selection: $model.rootTab) {
            Tab("Aides", systemImage: "checklist", value: RootTab.aides) {
                NavigationStack(path: pathBinding(.aides)) { HomeView().withRoutes() }
            }
            Tab("Sessions", systemImage: "clock.arrow.circlepath", value: RootTab.sessions) {
                NavigationStack(path: pathBinding(.sessions)) { SessionsTabView().withRoutes() }
            }
            .badge(model.homeLiveSessions.isEmpty ? 0 : model.homeLiveSessions.count)
            Tab("Moi", systemImage: "person.crop.circle", value: RootTab.me) {
                NavigationStack(path: pathBinding(.me)) { MeTabView().withRoutes() }
            }
            .badge(model.auth.signedIn && model.syncStatus.state.isTappable ? Text(verbatim: "!") : nil)
            Tab(value: RootTab.search, role: .search) {
                NavigationStack(path: pathBinding(.search)) { HomeView(searchMode: true).withRoutes() }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        #if os(iOS)
        .tabBarMinimizeBehavior(.onScrollDown)
        #endif
        // La recherche n'agit que dans son onglet : en sortir rend la liste entière aux « Aides ».
        .onChange(of: model.rootTab) { old, new in
            if old == .search && new != .search { model.home.q = "" }
        }
    }

    private func pathBinding(_ tab: RootTab) -> Binding<[Route]> {
        Binding(get: { model.paths[tab] ?? [] }, set: { model.paths[tab] = $0 })
    }
}

extension View {
    /// Les écrans poussés, identiques dans chaque onglet. La lecture d'une aide masque la barre
    /// d'onglets (mode crise : aucune autre barre que le quai, règle 11).
    func withRoutes() -> some View {
        navigationDestination(for: Route.self) { r in
            switch r {
            case .fiche(let id):
                ReadFicheView(ficheId: id)
                    #if os(iOS)
                    .toolbar(.hidden, for: .tabBar)
                    #endif
            case .reference(let id): ReferenceReadView(referenceId: id)
            case .editFiche(let id): FicheEditorView(ficheId: id)
            case .editReference(let id): ReferenceEditorView(referenceId: id)
            case .pdf(let id, let name): PDFViewerView(attachmentId: id, name: name)
            }
        }
    }
}

/// Onglet « Sessions » : l'historique, titre système.
struct SessionsTabView: View {
    var body: some View {
        ScrollView {
            SessionsHistoryView(ficheId: nil, embedded: true)
                .frame(maxWidth: 720, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
        }
        .background(T.amb.ignoresSafeArea())
        .navigationTitle("Sessions")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

/// Onglet « Moi » : compte, synchronisation, bibliothèques, réglages. `AccountView` se sait
/// racine d'onglet (grand titre « Moi », pas de ✕) quand elle n'est pas présentée en feuille.
struct MeTabView: View {
    var body: some View { AccountView() }
}

/// Alarme d'un minuteur d'une AUTRE aide que celle affichée : bandeau 10 s, un tap ouvre l'aide.
struct AlarmBannerView: View {
    @Environment(AppModel.self) private var model
    var banner: AlarmBanner
    var body: some View {
        HStack(spacing: 12) {
            Text("⏰").aFont(TypeScale.stepL)
            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title).aFont(TypeScale.item, .bold).foregroundStyle(T.onSysFill)
                Text(banner.sub).aFont(TypeScale.meta, .medium).foregroundStyle(T.onSysFill.opacity(0.8))
            }
            Spacer()
            Button { model.banner = nil } label: { Image(systemName: "xmark").frame(width: Ctrl.l, height: Ctrl.l) }
                .foregroundStyle(T.onSysFill)
                .accessibilityLabel("Fermer")
        }
        .padding(.leading, 16)
        .padding(.vertical, 4)
        // Verre teinté AMBRE (règle 8 : l'échéance), mot + glyphe : la couleur n'est jamais seule.
        .floatingGlass(cornerRadius: 28, tint: T.warnSys, interactive: true)  // design: verre fonctionnel, rayon de conteneur système (couche plateforme)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            model.banner = nil
            model.openFiche(banner.ficheId)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Minuteur terminé : \(banner.title) — \(banner.sub)")
    }
}

extension AppModel {
    /// Liens entrants (`aidescog://join?code=…`, liens d'appariement du partage).
    func handleURL(_ url: URL) {
        pendingJoinURL = url
    }
}
