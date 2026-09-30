import SwiftUI
import AidesCore

// LE RAIL (≥ 780) — la colonne d'ÉTAT à droite de l'action, son propre défileur. Ordre par urgence
// décroissante, zones non bornées en dernier : minuteurs → compteurs → ajouts → jalons → réglages →
// journal des actions → repères posologiques → (sous 1200) parcours.

struct CrRail: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    @Environment(AppModel.self) private var model
    @State private var journalOpen: Bool?
    @State private var parcoursOpen = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !ctx.started && ctx.hasFlow { preSession } else { session }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: vs.railScroll) { _, v in
                guard v != nil else { return }
                withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("rail-timers", anchor: .top) }
                vs.railScroll = nil
            }
        }
    }

    private func section<C: View>(_ title: String, count: Int = 0, first: Bool = false, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            CrFamHead(title: title, count: count, pal: CrPal(sys: false))
            content()
        }
        .padding(.top, first ? 0 : 20)
        .overlay(alignment: .top) { if !first { Rectangle().fill(T.lineStrong).frame(height: 1) } }
        .padding(.bottom, 20)
    }

    // MARK: Avant la session

    @ViewBuilder
    private var preSession: some View {
        let f = ctx.f
        section("En session", count: f.timers.count + 1, first: true) {
            VStack(alignment: .leading, spacing: 6) {
                preRow("Chrono de session", "démarre avec la session")
                ForEach(f.timers, id: \.id) { t in
                    let nm = Fmt.timerName(label: t.label, type: t.type)
                    let v: String = t.type == .interval
                        ? Fmt.ms(Double(t.seconds) * 1000) + (t.autoloop ? " cyclique, à lancer" : ", à lancer")
                        : "compte à partir de 0, à lancer"
                    preRow(nm, v)
                }
            }
        }
        if !Pool.list(f, .dose).isEmpty {
            section("Repères posologiques", count: Pool.list(f, .dose).count) { CrPosoCards(ctx: ctx, vs: vs) }
        }
        lastSession
    }

    private func preRow(_ l: String, _ v: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(l).aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2)
            Spacer(minLength: 6)
            Text(v).aFont(TypeScale.cap, .semibold, .mono).foregroundStyle(T.ink3).multilineTextAlignment(.trailing)
        }
    }

    /// « Dernière session : … · n blocs · mm:ss » + « Voir le compte-rendu ».
    @ViewBuilder
    private var lastSession: some View {
        let s = model.sessions
            .filter { $0["ficheId"]?.string == ctx.f.id && $0["live"]?.truthy != true }
            .max { ($0["savedAt"]?.number ?? 0) < ($1["savedAt"]?.number ?? 0) }
        if let s, let id = s["id"]?.string {
            let sv = s["savedAt"]?.number ?? 0
            let st = s["startedAt"]?.number ?? sv
            let n = s["nav"]?.array?.count ?? 0
            VStack(alignment: .leading, spacing: 6) {
                Text("Dernière session : " + Fmt.sessStamp(sv) + " · \(n) bloc" + (n > 1 ? "s" : "") + " · " + Fmt.ms(max(0, sv - st)))
                    .aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
                Button("Voir le compte-rendu") { vs.sheet = .report(id) }
                    .aFont(TypeScale.body, .bold).foregroundStyle(T.act).buttonStyle(.plain)
                    .frame(minHeight: Ctrl.l)
            }
            .padding(.top, 8)
        }
    }

    // MARK: En session

    @ViewBuilder
    private var session: some View {
        let R = ctx.R
        let pal = CrPal(sys: false)
        let nT = R.orderedTimers.count
        let nC = ctx.f.counters.count + R.adhocCounters.count
        let jalons = ctx.f.blocks.reduce(0) { $0 + $1.milestones.count }
        let jOpen = journalOpen ?? (ctx.wc == .cockpit)
        section("Minuteurs", count: nT, first: true) {
            CrTimersSection(ctx: ctx, vs: vs, pal: pal, compact: true)
        }
        .id("rail-timers")
        if nC > 0 {
            section("Compteurs", count: nC) { CrCountersSection(ctx: ctx, vs: vs, pal: pal, compact: true) }
        }
        CrAddRow(ctx: ctx, vs: vs, pal: pal).padding(.bottom, 20)
        if jalons > 0 {
            section("Jalons", count: jalons) { CrJalonsSection(ctx: ctx, pal: pal) }
        }
        CrSettingsRow(pal: pal).padding(.bottom, 20)
        VStack(alignment: .leading, spacing: 10) {
            Button { journalOpen = !jOpen } label: {
                HStack {
                    CrFamHead(title: "Journal des actions", count: R.events.count, pal: pal)
                    Spacer()
                    Image(systemName: jOpen ? "chevron.up" : "chevron.down").foregroundStyle(T.ink2)
                }
                .frame(minHeight: Ctrl.l).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(jOpen ? "déplié" : "replié")
            if jOpen { CrEventJournal(ctx: ctx, vs: vs, pal: pal) }
        }
        .padding(.top, 20)
        .overlay(alignment: .top) { Rectangle().fill(T.lineStrong).frame(height: 1) }
        .padding(.bottom, 20)
        if !Pool.list(ctx.f, .dose).isEmpty {
            section("Repères posologiques", count: Pool.list(ctx.f, .dose).count) { CrPosoCards(ctx: ctx, vs: vs) }
        }
        if ctx.wc != .cockpit && ctx.hasFlow {
            let tip = ctx.tipBlock
            let here = tip.map { b in (ctx.num(b.id).map { "\($0) " } ?? "") + (b.title.isEmpty ? "Étapes" : b.title) } ?? ""
            VStack(alignment: .leading, spacing: 10) {
                Button { parcoursOpen.toggle() } label: {
                    HStack {
                        CrFamHead(title: "Parcours", count: ctx.plan.order.count, pal: pal)
                        Text("· ici : " + here).aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink2).lineLimit(1)
                        Spacer()
                        Image(systemName: parcoursOpen ? "chevron.up" : "chevron.down").foregroundStyle(T.ink2)
                    }
                    .frame(minHeight: Ctrl.l).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(parcoursOpen ? "déplié" : "replié")
                if parcoursOpen { CrParcoursList(ctx: ctx, vs: vs, place: .col) }
            }
            .padding(.top, 20)
            .overlay(alignment: .top) { Rectangle().fill(T.lineStrong).frame(height: 1) }
        }
    }
}
