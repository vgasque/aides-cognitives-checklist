import SwiftUI
import AidesCore

/// LECTURE D'UNE AIDE — l'écran d'entrée « Avant la session » puis le MODE CRISE (journal de
/// parcours, capsule, quai, volet/rail). Port de `renderRead` / `overviewSection` / `runtimePanel`.
///
/// Règle 11 : rien ne s'ouvre seul pendant une session — aucune alerte, aucune fenêtre, aucun
/// défilement autonome. Les seuls défilements sont DEMANDÉS (Continuer, réponse, complication,
/// « Reprendre », retour au bloc) ; les alarmes s'annoncent SUR PLACE (segment ambre de la capsule,
/// carte « ■ … — à réévaluer », éclair d'écran, annonce VoiceOver).
struct ReadFicheView: View {
    let ficheId: String
    @Environment(AppModel.self) private var model
    @State private var vs = CrisisViewState()

    var body: some View {
        let _ = model.rev
        Group {
            if let R = resolved {
                CrisisScreen(R: R, vs: vs)
            } else if model.fiches.contains(where: { $0.id == ficheId }) {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    Text("⚠ Fiche introuvable.").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                    Button("Retour à l’accueil") { model.path.removeAll() }.buttonStyle(.a(.secondary, Ctrl.l))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(T.amb.ignoresSafeArea())
        .onAppear { claim() }
    }

    /// La session vive de l'aide, ou le Runtime courant s'il est le sien — sans ÉCRIRE pendant le rendu.
    private var resolved: RuntimeSession? {
        if let c = model.current, c.ficheId == ficheId { return c }
        return model.engine.live[ficheId]
    }
    /// À l'apparition (y compris au retour d'une aide liée), l'aide affichée redevient la courante :
    /// l'alarme d'un minuteur de CETTE aide s'annonce alors sur place, pas en bandeau.
    private func claim() {
        guard let R = model.runtime(for: ficheId) else { return }
        if model.current !== R { model.current = R }
        model.touch()
    }
}

/// Boîte NON observée : la géométrie lue au défilement ne doit pas redessiner tout le journal.
final class CrGeomBox {
    var tip: CGRect = .zero
    var viewH: CGFloat = 0
    /// La carte vive est-elle ENTIÈREMENT hors de la zone utile ? (barre « Revenir au bloc »)
    @MainActor
    func report(_ r: CGRect, vs: CrisisViewState) {
        tip = r
        guard viewH > 0 else { return }
        let visible = r.maxY > 8 && r.minY < viewH - 8
        if vs.tipVisible != visible { vs.tipVisible = visible }
    }
}

/// L'écran vivant d'une aide.
struct CrisisScreen: View {
    let R: RuntimeSession
    let vs: CrisisViewState
    @Environment(AppModel.self) private var model
    @Environment(\.textScale) private var textScale
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lastStarted = false

    var body: some View {
        let _ = model.rev
        @Bindable var b = vs
        GeometryReader { geo in
            let w = geo.size.width / max(0.5, textScale)
            let ctx = CrCtx(R: R, f: R.fiche, e: model.engine, plan: CrisisPure.flowPlan(R.fiche),
                            now: JS.now(), w: w, wc: WidthClass.of(w))
            layout(ctx)
                .environment(\.widthClass, ctx.wc)
        }
        .background(T.amb.ignoresSafeArea())
        .navigationTitle(R.fiche.title.isEmpty ? "Aide" : R.fiche.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { toolbarContent }
        .sheet(item: $b.sheet) { s in CrSheetHost(sheet: s, R: R, vs: vs) }
        #if os(iOS)
        .fullScreenCover(isPresented: $b.monitorOpen) { CrMonitorView(R: R, vs: vs) }
        #else
        .sheet(isPresented: $b.monitorOpen) { CrMonitorView(R: R, vs: vs).frame(minWidth: 720, minHeight: 520) }
        #endif
        .confirmationDialog("Recommencer le parcours ?", isPresented: $b.confirmRestart, titleVisibility: .visible) {
            Button("Recommencer", role: .destructive) { act.restartCourse() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Le chemin parcouru est effacé et l’aide repart du début. Le chrono de session, les minuteurs, les compteurs et le compte-rendu sont CONSERVÉS.")
        }
        .confirmationDialog(R.exercise ? "Nouvel exercice ?" : "Passer en exercice ?", isPresented: $b.confirmExercise, titleVisibility: .visible) {
            Button(R.exercise ? "Nouvel exercice" : "Terminer et exercer", role: .destructive) { act.armExercise() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text(R.exercise ? "Un exercice est déjà en cours. En recommencer un nouveau ?"
                 : "Une session réelle est en cours sur cette fiche. La terminer pour passer en exercice ? Elle est archivée — son compte-rendu reste disponible.")
        }
        .overlay {
            if vs.flashOn {
                T.warnSys.opacity(0.4).ignoresSafeArea().allowsHitTesting(false).transition(.opacity)
            }
        }
        .overlay {
            if vs.endOpen { CrEndDialog(R: R, vs: vs) }
        }
        .onAppear {
            lastStarted = R.started
            model.applyWake(crisisOnScreen: R.started)
            primeWatch()
        }
        .onDisappear { model.applyWake(crisisOnScreen: false) }
        .onChange(of: model.rev) { _, _ in watch() }
        .onChange(of: scenePhase) { _, p in
            // Q2 : au retour après ≥ 2 min, la carte vive le dit (sans son, sans fenêtre, sans défilement).
            guard p == .active, R.started else { return }
            let last = R.lastActAt ?? R.startedAt
            if JS.now() - last >= 120_000 { vs.resumeSince = last }
        }
    }

    private var act: CrAct { CrAct(model: model, vs: vs, R: R) }

    // MARK: Disposition par largeur (téléphone · rail ≥ 780 · poste ≥ 1200)

    @ViewBuilder
    private func layout(_ ctx: CrCtx) -> some View {
        let showCol = ctx.wc == .cockpit && !ctx.f.blocks.isEmpty && !vs.showAll
        HStack(alignment: .top, spacing: ctx.wc == .phone ? 0 : 20) {
            if showCol {
                CrCockpitColumn(ctx: ctx, vs: vs)
                    .frame(width: 240)
                    .accessibilitySortPriority(0)
            }
            CrActionColumn(ctx: ctx, vs: vs)
                .frame(maxWidth: .infinity)
                .accessibilitySortPriority(2)
            if ctx.wc != .phone {
                CrRail(ctx: ctx, vs: vs)
                    .frame(width: ctx.w >= 1000 ? 320 : 280)
                    .accessibilitySortPriority(1)
            }
        }
        .padding(.horizontal, ctx.wc == .phone ? 0 : 20)
    }

    // MARK: En-tête

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) { CrBrandBar(R: R) }
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                let all = ThemePref.allCases
                let i = all.firstIndex(of: model.theme) ?? 0
                model.theme = all[(i + 1) % all.count]
            } label: {
                Image(systemName: "circle.lefthalf.filled").frame(width: Ctrl.m, height: Ctrl.m)
            }
            .accessibilityLabel("Thème — " + model.theme.label)
            CrMoreButton(R: R, vs: vs)
        }
    }

    // MARK: Veille, alarmes sur place, jalons

    private func primeWatch() {
        for t in R.orderedTimers { vs.lastCycles[t.id] = t.cycles }
        vs.jalonActive = activeJalons().count
    }

    /// Détection des minuteurs qui VIENNENT de sonner (le moteur a déjà bipé via le pont) :
    /// ici, seulement l'annonce sur place — éclair d'écran 2 s, carte qui clignote, VoiceOver.
    private func watch() {
        if lastStarted != R.started {
            lastStarted = R.started
            model.applyWake(crisisOnScreen: R.started)
        }
        var fired: [TimerState] = []
        for t in R.orderedTimers {
            let prev = vs.lastCycles[t.id] ?? t.cycles
            if t.cycles > prev { fired.append(t) }
            if prev != t.cycles { vs.lastCycles[t.id] = t.cycles }
        }
        if let t = fired.first, R.started, model.current === R {
            let a = JS.trim(t.onDue)
            crAnnounce("Minuteur terminé : " + t.name + (a.isEmpty ? "" : " — " + a))
            vs.flashTimer = t.id
            withAnimation(.easeOut(duration: 0.2)) { vs.flashOn = true }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeOut(duration: 0.4)) { vs.flashOn = false }
                vs.flashTimer = nil
            }
        }
        let act = activeJalons()
        if vs.jalonActive >= 0, act.count > vs.jalonActive, let j = act.last {
            crAnnounce("Jalon atteint — " + j.text)
        }
        if vs.jalonActive != act.count { vs.jalonActive = act.count }
    }

    /// Jalons ATTEINTS de la carte vive (le seul endroit où ils s'annoncent).
    private func activeJalons() -> [Milestone] {
        guard R.started, let id = R.nav.last, let b = R.fiche.blocks.first(where: { $0.id == id }) else { return [] }
        let pass = Graph.passInfo(nav: R.nav, R.nav.count - 1).pass
        return b.milestones.filter { Jalons.progress($0, pass: pass, count: R.counters[$0.counter] ?? 0).active }
    }
}

/// Le bloc de marque de la barre : sur-titre « CATÉGORIE · CODE · MODE » + titre.
struct CrBrandBar: View {
    let R: RuntimeSession
    @Environment(AppModel.self) private var model
    @Environment(\.widthClass) private var wc

    var body: some View {
        let f = R.fiche
        let cat = model.categories.first { $0.id == f.category }
        VStack(spacing: 1) {
            HStack(spacing: 5) {
                if let cat { CategoryDot(color: cat.color, size: 8) }
                Text(overline(cat: cat)).aFont(TypeScale.cap, .heavy).tracking(0.6)
                    .foregroundStyle(modeColor).lineLimit(1)
            }
            if R.started || wc != .phone {
                HStack(spacing: 4) {
                    Text(f.title.isEmpty ? "Aide" : f.title)
                        .aFont(wc == .phone ? TypeScale.item : TypeScale.step, wc == .phone ? .bold : .heavy)
                        .foregroundStyle(T.ink).lineLimit(1)
                    if !f.discriminant.isEmpty {
                        Text("· " + f.discriminant).aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2).lineLimit(1)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
    private var modeColor: Color { R.exercise ? T.act : T.ink2 }
    private func overline(cat: Category?) -> String {
        var parts: [String] = []
        if let cat { parts.append(cat.name.uppercased()) }
        if !R.fiche.code.isEmpty && wc != .phone { parts.append(R.fiche.code.uppercased()) }
        if R.exercise { parts.append("▲ EXERCICE") }
        else if R.started { parts.append("■ MODE CRISE") }
        else if CrisisPure.hasFlow(R.fiche) { parts.append("AVANT LA SESSION") }
        return parts.joined(separator: " · ")
    }
}

/// Le bouton ⋯ et son menu (feuille basse au téléphone, bulle ancrée dès 780).
struct CrMoreButton: View {
    let R: RuntimeSession
    let vs: CrisisViewState
    var body: some View {
        @Bindable var b = vs
        Button { vs.menuOpen = true } label: {
            Image(systemName: "ellipsis").frame(width: Ctrl.m, height: Ctrl.m)
        }
        .accessibilityLabel("Actions")
        .popover(isPresented: $b.menuOpen) {
            CrMoreMenu(R: R, vs: vs)
                .frame(minWidth: 300, idealWidth: 320)
                #if os(iOS)
                .presentationDetents([.medium, .large])
                #endif
        }
    }
}

// MARK: - La colonne d'action (capsule · journal · quai)

struct CrActionColumn: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var geom = CrGeomBox()

    var body: some View {
        let avant = !ctx.started && ctx.hasFlow
        VStack(spacing: 0) {
            if ctx.started {
                CrCapsule(ctx: ctx, vs: vs)
                    .padding(.horizontal, ctx.narrow430 ? 12 : 14)
                    .padding(.vertical, 8)
                    .background(T.amb)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if ctx.R.exercise { CrExerciseBand(ctx: ctx, vs: vs) }
                        CrPageHead(ctx: ctx)
                        if avant {
                            CrEntryView(ctx: ctx, vs: vs)
                        } else if vs.showAll {
                            CrAllView(ctx: ctx, vs: vs)
                        } else {
                            CrJournalView(ctx: ctx, vs: vs, geom: geom)
                            CrSessionFolds(ctx: ctx, vs: vs)
                            CrTail(ctx: ctx)
                        }
                    }
                    .padding(.horizontal, ctx.narrow360 ? 12 : 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                    .frame(maxWidth: 820, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .coordinateSpace(name: "crScroll")
                .background(GeometryReader { g in
                    Color.clear
                        .onAppear { geom.viewH = g.size.height }
                        .onChange(of: g.size.height) { _, h in geom.viewH = h }
                })
                .overlay(alignment: .top) {
                    if vs.voletOpen && ctx.wc == .phone && ctx.started {
                        GeometryReader { g in
                            ZStack(alignment: .top) {
                                Color.black.opacity(0.001)
                                    .onTapGesture { vs.voletOpen = false }
                                    .accessibilityHidden(true)
                                CrVolet(ctx: ctx, vs: vs)
                                    .frame(maxHeight: g.size.height * 0.8, alignment: .top)
                                    .padding(.horizontal, 14)
                                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
                            }
                        }
                    }
                }
                .overlay(alignment: .bottom) { bottomOverlays }
                .onChange(of: vs.pendingScroll) { _, v in handleScroll(v, proxy) }
            }
            CrDock(ctx: ctx, vs: vs)
        }
    }

    @ViewBuilder
    private var bottomOverlays: some View {
        VStack(spacing: 8) {
            if ctx.started && !vs.tipVisible && !vs.showAll && ctx.tipIdx >= 0 && vs.dockSheet == .closed {
                CrReturnBar(ctx: ctx, vs: vs)
            }
            switch vs.dockSheet {
            case .closed: EmptyView()
            case .stamp(let id): CrStampSheet(ctx: ctx, vs: vs, evId: id)
            case .cx: CrCxSheet(ctx: ctx, vs: vs)
            }
        }
        .frame(maxWidth: 660)
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    /// Défilement DEMANDÉ : « !id » force, sinon seulement si la nouvelle carte n'est pas entièrement visible.
    private func handleScroll(_ v: String?, _ proxy: ScrollViewProxy) {
        guard var id = v else { return }
        let force = id.hasPrefix("!")
        if force { id.removeFirst() }
        vs.pendingScroll = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            if !force {
                let r = geom.tip
                if geom.viewH > 0 && r.minY >= 0 && r.maxY <= geom.viewH { return }
            }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { proxy.scrollTo(id, anchor: .top) }
            if vs.spotVisit != nil {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                vs.spotVisit = nil
            }
        }
    }
}

// MARK: - Tête de page, bande d'exercice, queue

/// Titre de la page (téléphone, avant la session) + méta + notices d'état.
struct CrPageHead: View {
    let ctx: CrCtx
    @Environment(AppModel.self) private var model

    var body: some View {
        let f = ctx.f
        VStack(alignment: .leading, spacing: 6) {
            if ctx.wc == .phone && !ctx.started {
                Text(f.title.isEmpty ? "Aide" : f.title)
                    .aFont(TypeScale.val, .heavy).foregroundStyle(T.ink)
                    .accessibilityAddTraits(.isHeader)
                if !f.discriminant.isEmpty {
                    Text(f.discriminant).aFont(TypeScale.step, .semibold).foregroundStyle(T.ink2)
                }
            }
            if !ctx.started {
                meta
                if f.status == .draft {
                    notice("Brouillon", " — cette fiche n'a pas encore été validée pour l'usage clinique.")
                } else if f.status == .review {
                    notice("À relire", " — cette fiche est signalée à relire avant validation.")
                }
            }
        }
        .padding(.bottom, ctx.started ? 0 : 6)
    }

    @ViewBuilder
    private var meta: some View {
        let f = ctx.f
        let cat = model.categories.first { $0.id == f.category }
        let lib = model.library.libraryName(f.library)
        HStack(spacing: 6) {
            if f.library != nil {
                Label(lib.isEmpty ? "Partagée" : lib, systemImage: "books.vertical")
                    .labelStyle(.titleAndIcon)
                    .accessibilityLabel("Bibliothèque partagée : " + (lib.isEmpty ? "Partagée" : lib))
                Text("·")
            }
            if let cat {
                CategoryDot(color: cat.color, size: 8)
                Text(cat.name)
            }
            if !f.code.isEmpty { Text("·"); Text(f.code).aFont(TypeScale.meta, .semibold, .mono) }
            if f.status == .validated {
                Text("·")
                Text(f.validatedAt.isEmpty ? "✓ Validée" : "Validée " + Validation.display(f.validatedAt))
            }
        }
        .aFont(TypeScale.meta, .medium)
        .foregroundStyle(T.ink2)
        .lineLimit(1)
    }

    private func notice(_ bold: String, _ rest: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(T.warn).accessibilityHidden(true)
            (Text(bold).bold() + Text(rest))
                .aFont(TypeScale.body, .medium).foregroundStyle(T.ink)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(T.warnSoft, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
    }
}

/// « ▲ Exercice » + « Quitter l’exercice… » (`#crisisBand`).
struct CrExerciseBand: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    @Environment(AppModel.self) private var model
    var body: some View {
        HStack(spacing: 10) {
            Text("▲ Exercice").aFont(TypeScale.body, .heavy).foregroundStyle(T.act)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(T.primarySoft, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).strokeBorder(T.act, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            Spacer(minLength: 8)
            Button("Quitter l’exercice…") {
                if ctx.started { vs.endOpen = true }
                else { CrAct(model: model, vs: vs, R: ctx.R).cancelExercise() }
            }
            .aFont(TypeScale.body, .bold)
            .foregroundStyle(T.act)
            .padding(.horizontal, 12)
            .frame(minHeight: Ctrl.l)
            .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.act, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

/// Queue de page : informations locales, puis la note personnelle (C1 §14).
struct CrTail: View {
    let ctx: CrCtx
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle().fill(T.line).frame(height: 1).padding(.top, 20)
            let local = JS.trim(ctx.f.local)
            if !local.isEmpty {
                Text(local).aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
            }
            CrNoteBlock(ficheId: ctx.f.id, locked: ctx.started)
        }
    }
}
