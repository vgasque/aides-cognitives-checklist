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

/// La coque : accueil (ou écran de bienvenue), pile de navigation, bandeau d'alarme, toasts.
struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        GeometryReader { geo in
            NavigationStack(path: $model.path) {
                Group {
                    if model.onboarded || !model.fiches.isEmpty || !model.references.isEmpty {
                        HomeView()
                    } else {
                        WelcomeView()
                    }
                }
                .navigationDestination(for: Route.self) { r in
                    switch r {
                    case .fiche(let id): ReadFicheView(ficheId: id)
                    case .reference(let id): ReferenceReadView(referenceId: id)
                    case .editFiche(let id): FicheEditorView(ficheId: id)
                    case .editReference(let id): ReferenceEditorView(referenceId: id)
                    case .pdf(let id, let name): PDFViewerView(attachmentId: id, name: name)
                    }
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
                    .padding(.bottom, 90)
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
    }
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
        .background(T.warnSys, in: RoundedRectangle(cornerRadius: Radius.r3))
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
