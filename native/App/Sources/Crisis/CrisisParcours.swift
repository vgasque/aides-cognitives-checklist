import SwiftUI
import AidesCore

// LE PARCOURS À PLAT (`preFlowFlatHtml`, A376/A388) — version de la ZONE MODE CRISE : la liste
// numérotée « le tronc d'abord » (même numérotation que le journal, `flowPlan`), dépliée dans la
// carte d'entrée, dense et repliée dans la colonne du poste et le rail. Le dessin complet de la
// feuille « Se repérer » (branches tracées, renvois flashés) est `ParcoursSheetView`, d'une autre
// zone. Ici, comme là : le parcours ne coche JAMAIS rien et ne démarre JAMAIS la session.

enum CrPlace { case card, col }

struct CrParcoursList: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let place: CrPlace

    var body: some View {
        let items = ctx.plan.items
        let off = offPath()
        let reviews = ctx.f.blocks.filter { $0.kind == .review }
        let order = Set(ctx.plan.order)
        let detached = CrisisPure.cxAll(ctx.f).filter { $0.isBlock && !order.contains($0.target) }
        VStack(alignment: .leading, spacing: place == .col ? 4 : 6) {
            if place == .col {
                HStack {
                    Spacer()
                    Button(vs.colAllOpen ? "Tout replier" : "Tout déplier") {
                        vs.colAllOpen.toggle()
                        vs.colFold = [:]
                    }
                    .aFont(TypeScale.meta, .bold).foregroundStyle(T.act).buttonStyle(.plain)
                    .frame(minHeight: Ctrl.s)
                }
            }
            ForEach(Array(items.enumerated()), id: \.offset) { i, it in
                itemView(it, at: i, off: off)
            }
            if !reviews.isEmpty || !detached.isEmpty {
                Text("À TOUT MOMENT").aFont(TypeScale.meta, .heavy).tracking(0.8).foregroundStyle(T.ink2)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .top) { Rectangle().fill(T.line).frame(height: 1) }
                ForEach(reviews, id: \.id) { rb in
                    CrPfBlockRow(ctx: ctx, vs: vs, b: rb, depth: 0, place: place, off: false, glyph: "square.grid.2x2")
                }
                ForEach(detached, id: \.self) { c in
                    if let b = ctx.block(c.target) {
                        CrPfBlockRow(ctx: ctx, vs: vs, b: b, depth: 0, place: place, off: false, glyph: "bolt.fill")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func itemView(_ it: CrPlanItem, at i: Int, off: Set<String>) -> some View {
        switch it.k {
        case .block:
            if let b = ctx.block(it.id) {
                CrPfBlockRow(ctx: ctx, vs: vs, b: b, depth: it.depth, place: place, off: off.contains(b.id), glyph: nil)
            }
        case .bropen:
            HStack(spacing: 6) {
                Text("◇").aFont(TypeScale.meta, .heavy).foregroundStyle(T.warn)
                BoldText(text: it.label, size: place == .col ? TypeScale.meta : TypeScale.body, weight: .heavy, color: T.warn)
                    .lineLimit(2)
            }
            .padding(.leading, CGFloat(max(0, it.depth - 1)) * 16 + 8)
            .padding(.top, 4)
        case .brclose:
            EmptyView()
        case .link:
            let n = ctx.num(it.id)
            let t = ctx.block(it.id)?.title ?? ""
            let cyc = it.back ? CrisisPure.cycleHint(ctx.f).map { " · toutes les " + Fmt.dur($0.seconds) } ?? "" : ""
            Text(either(it.back, "↺ retour à ", "↳ puis ") + (n.map { "\($0) · " } ?? "") + (t.isEmpty ? "Étapes" : t) + cyc)
                .aFont(place == .col ? TypeScale.meta : TypeScale.body, .semibold)
                .foregroundStyle(it.back ? T.act : T.ink2)
                .padding(.leading, CGFloat(it.depth) * 16 + 8)
        case .end:
            Text("■ Fin").aFont(TypeScale.body, .heavy).foregroundStyle(T.ok)
                .padding(.leading, CGFloat(it.depth) * 16 + 8)
        }
    }

    /// `offPathSet` : blocs ni visités ni atteignables depuis la tête (session seulement).
    private func offPath() -> Set<String> {
        CrisisPure.offPath(ctx.R)
    }
}

/// Une rangée de bloc du parcours à plat.
struct CrPfBlockRow: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let b: Block
    let depth: Int
    let place: CrPlace
    let off: Bool
    let glyph: String?
    @Environment(AppModel.self) private var model

    var body: some View {
        let R = ctx.R
        let key = either(place == .col, "lc:", "l:") + b.id
        let defOpen = place == .card ? true : vs.colAllOpen
        let open = vs.colFold[key] ?? defOpen
        let dense = place == .col
        let lp = Graph.latestPass(nav: R.nav, navSeq: R.navSeq, b.id)
        let cur = R.started && R.nav.last == b.id
        let done = R.started && lp != nil && ctx.e.instComplete(R, lp!.idx)
        let dec = b.kind == .decision
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: dense ? 8 : 12) {
                badge(dense: dense, done: done, cur: cur, dec: dec)
                Button { vs.colFold[key] = !open } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(b.title.isEmpty ? (dec ? "Décision" : "Étapes") : b.title)
                            .aFont(dense ? TypeScale.body : TypeScale.step, .heavy)
                            .foregroundStyle(done ? T.ink2 : T.ink)
                            .multilineTextAlignment(.leading)
                        if cur { Text("ICI").aFont(TypeScale.cap, .heavy).foregroundStyle(T.act) }
                        Spacer(minLength: 4)
                        Image(systemName: open ? "chevron.up" : "chevron.down").aFont(TypeScale.cap, .bold).foregroundStyle(T.ink2)
                    }
                    .frame(minHeight: 32)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(open ? "déplié" : "replié")
                if R.started && place == .col {
                    Button { CrAct(model: model, vs: vs, R: R).jump(b.id) } label: {
                        Image(systemName: "arrow.right.circle").aFont(TypeScale.item, .semibold).foregroundStyle(T.act)
                            .frame(width: Ctrl.s, height: Ctrl.s).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Aller à ce bloc — " + (b.title.isEmpty ? "Étapes" : b.title))
                }
            }
            if open { detail(dense: dense, dec: dec) }
            else if dec { briefOptions(dense: dense) }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(cur ? T.primarySoft : (dec ? T.warnSoft : Color.clear), in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
        .overlay { if cur { RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.act, lineWidth: 2) } }
        .opacity(off ? 0.62 : 1)
        .padding(.leading, CGFloat(depth) * 16)
        .accessibilityElement(children: .contain)
        .accessibilityHint(off ? "hors chemin" : "")
    }

    private func badge(dense: Bool, done: Bool, cur: Bool, dec: Bool) -> some View {
        let sz: CGFloat = dense ? 22 : 28
        let n = ctx.num(b.id)
        return ZStack {
            if dec {
                RoundedRectangle(cornerRadius: 3, style: .continuous).fill(T.warnSoft)
                    .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous).strokeBorder(T.warnLine, lineWidth: 2))
                    .frame(width: sz * 0.72, height: sz * 0.72)
                    .rotationEffect(.degrees(45))
                Text(n.map { "\($0)" } ?? "·").aFont(TypeScale.meta, .heavy).foregroundStyle(T.warn)
            } else {
                RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).fill(done ? T.ok : (cur ? T.act : T.sys))
                if let glyph {
                    Image(systemName: glyph).aFont(dense ? TypeScale.cap : TypeScale.meta, .bold).foregroundStyle(glyph == "bolt.fill" ? T.bolt : T.sysInk)
                } else if done {
                    Image(systemName: "checkmark").aFont(dense ? TypeScale.cap : TypeScale.meta, .heavy).foregroundStyle(T.onPrimary)
                } else {
                    Text(n.map { "\($0)" } ?? "·").aFont(dense ? TypeScale.meta : TypeScale.body, .heavy).foregroundStyle(T.sysInk)
                }
            }
        }
        .frame(width: sz, height: sz)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func detail(dense: Bool, dec: Bool) -> some View {
        let fsz: CGFloat = dense ? TypeScale.body : TypeScale.item
        VStack(alignment: .leading, spacing: 4) {
            if let bt = CrisisPure.blockTimerTxt(ctx.f, b) {
                Text(bt).aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
            }
            if dec {
                if !JS.trim(b.question).isEmpty { BoldText(text: b.question, size: fsz, weight: .semibold, color: T.ink) }
                ForEach(Array(b.options.enumerated()), id: \.offset) { oi, o in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        BoldText(text: o.label.isEmpty ? "Option \(oi + 1)" : o.label, size: fsz, weight: .heavy, color: T.warn)
                        Text(dest(oi, o)).aFont(dense ? TypeScale.meta : TypeScale.body, .medium).foregroundStyle(T.ink2)
                    }
                }
            } else {
                let steps = Graph.cleanSteps(ctx.f, b)
                let its = Pool.blockItems(ctx.f, b)
                ForEach(steps.indices, id: \.self) { i in
                    stepLine(steps[i], i < its.count ? its[i] : nil, i, fsz: fsz)
                }
            }
            ForEach(Array(b.milestones.enumerated()), id: \.offset) { _, j in
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Si").aFont(fsz, .heavy).foregroundStyle(T.ink2)
                    Text(Jalons.conditionLabel(ctx.f, j) + " : " + j.text).aFont(fsz, .medium).foregroundStyle(T.ink2)
                    if !j.go.isEmpty { CrBolt(size: 11) }
                }
            }
        }
        .padding(.leading, dense ? 30 : 40)
    }

    private func stepLine(_ s: String, _ it: Item?, _ i: Int, fsz: CGFloat) -> some View {
        let cr = Steps.challengeResponse(Steps.text(s))
        let lvl = Steps.level(s)
        let q = it.map { CrisisPure.stepQualTxt(ctx.f, $0, faite: CrisisPure.onceFaite(ctx.R, $0, b.id, i)) } ?? ""
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle().fill(T.ink2).frame(width: 6, height: 6).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    BoldText(text: cr.c + (cr.r.map { " — " + $0 } ?? ""), size: fsz, weight: .medium, color: T.ink)
                    Spacer(minLength: 4)
                    if lvl == 3 { Text("CRITIQUE").aFont(TypeScale.cap, .heavy).foregroundStyle(T.crit) }
                    else if lvl == 2 { Text("VIGILANCE").aFont(TypeScale.cap, .heavy).foregroundStyle(T.warn) }
                }
                if !q.isEmpty {
                    Text("· " + q).aFont(TypeScale.meta, q.hasPrefix("✓") ? .bold : .medium)
                        .foregroundStyle(q.hasPrefix("✓") ? T.ok : T.ink2)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func briefOptions(dense: Bool) -> some View {
        let taken = ctx.R.started ? Graph.latestPass(nav: ctx.R.nav, navSeq: ctx.R.navSeq, b.id).flatMap { ctx.e.decisionTaken(ctx.R, $0.idx) } : nil
        let parts: [String] = b.options.enumerated().map { oi, o in
            let l = o.label.isEmpty ? "Option \(oi + 1)" : HTML.stripBold(o.label)
            let mark = (taken != nil && taken!.target == o.target && taken!.label == o.label) ? "✓ " : ""
            let n = o.target.flatMap { ctx.num($0) }
            return mark + l + (n.map { " →\($0)" } ?? (o.target == nil ? " ▪" : ""))
        }
        return Text(parts.joined(separator: " · ")).aFont(TypeScale.meta, .semibold).foregroundStyle(T.warn)
            .lineLimit(1).padding(.leading, dense ? 30 : 40)
    }

    private func dest(_ oi: Int, _ o: DecisionOption) -> String {
        guard let t = o.target, let tb = ctx.block(t) else { return "▪ fin" }
        let items = ctx.plan.items
        if let k = items.firstIndex(where: { $0.k == .bropen && $0.dec == b.id && $0.oi == oi }),
           k + 1 < items.count, items[k + 1].k == .block, items[k + 1].id == t { return "↓ ci-dessous" }
        let title = tb.title.isEmpty ? "Étapes" : tb.title
        guard let n = ctx.num(t) else { return "→ aller à " + title }
        let mine = ctx.num(b.id) ?? 0
        return either(n < mine, "↺ retour à \(n) · ", "→ aller à \(n) · ") + title
    }
}

/// La colonne gauche du POSTE (≥ 1200) : « Parcours » dense, replié d'office, « Tout déplier ».
struct CrCockpitColumn: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Parcours").aFont(TypeScale.step, .heavy).foregroundStyle(T.ink).accessibilityAddTraits(.isHeader)
                if !ctx.started {
                    Text("Aperçu — se déroule après le démarrage.").aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
                }
                CrLinksRow(ctx: ctx, vs: vs, docs: false)
                CrParcoursList(ctx: ctx, vs: vs, place: .col)
            }
            .padding(.vertical, 12)
        }
    }
}

/// « Tableau » (la Page) · « Schéma » · « Documents · n » — liens de l'écran d'entrée.
struct CrLinksRow: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    var docs = true
    var body: some View {
        CrWrap(spacing: 8) {
            link("tablecells", "Tableau") { vs.sheet = .page }
            link("point.3.connected.trianglepath.dotted", "Schéma") { vs.sheet = .schema }
            if docs && !ctx.f.docs.isEmpty {
                link("doc.text", "Documents · \(ctx.f.docs.count)") {
                    vs.preOpen["refs"] = true
                    CrLocal.set("pre:\(ctx.f.id):refs", true)
                    vs.pendingScroll = "!pre-refs"
                }
            }
        }
    }
    private func link(_ sf: String, _ label: String, _ go: @escaping () -> Void) -> some View {
        Button(action: go) {
            HStack(spacing: 6) {
                Image(systemName: sf).aFont(TypeScale.body, .bold).foregroundStyle(T.act)
                Text(label).aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: Ctrl.l)
            .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.ctlLine, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
