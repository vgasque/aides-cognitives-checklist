import SwiftUI
import AidesCore

// LE JOURNAL DE PARCOURS (`overviewSection`, `ovInstHtml`, `ovPresList`) — la liste chronologique
// des visites : passages terminés condensés, la carte vive (le « bout ») en grand.
// « Rien ne bouge sous le doigt » (A9) : cocher ne replie rien ; la condensation d'un bloc fini
// n'arrive qu'au PROCHAIN geste de navigation.

struct CrJournalView: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let geom: CrGeomBox

    enum Entry: Identifiable {
        case card(Int)
        case run(Int, [Int])
        var id: String {
            switch self {
            case .card(let i): return "c\(i)"
            case .run(let f, _): return "r\(f)"
            }
        }
    }

    /// Les puces consécutives se groupent en une ligne « Fait · a→b ».
    static func group(_ pres: [CrisisPure.Pres]) -> [Entry] {
        var out: [Entry] = []
        var run: [Int] = []
        func flush() { if let f = run.first { out.append(.run(f, run)); run = [] } }
        for (i, p) in pres.enumerated() {
            if p == .chip { run.append(i) } else { flush(); out.append(.card(i)) }
        }
        flush()
        return out
    }

    var body: some View {
        let R = ctx.R
        let n = R.nav.count
        let complete: [Bool] = (0..<n).map { ctx.e.instComplete(R, $0) }
        let manual: [Bool?] = (0..<n).map { vs.ovFold[String($0)] }
        let pres = CrisisPure.ovPresList(complete: complete, manual: manual, forcedOpen: vs.verify?.idx)
        let entries = Self.group(pres)
        let headRun: [Int]? = entries.first.flatMap { en -> [Int]? in
            if case .run(let f, let ix) = en, f == 0 { return ix }
            return nil
        }
        VStack(alignment: .leading, spacing: 0) {
            if ctx.started { CrProgressLine(ctx: ctx, vs: vs, headRun: headRun) }
            ForEach(entries) { en in
                switch en {
                case .card(let i):
                    CrBlockCard(ctx: ctx, vs: vs, geom: geom, idx: i, pres: pres[i], complete: complete[i])
                        .id("v\(i)")
                case .run(let f, let ix):
                    if f != 0 {
                        CrRunPill(ctx: ctx, vs: vs, first: f, ix: ix).padding(.bottom, 10)
                    }
                }
            }
            if R.flowEnded {
                Text("Algorithme terminé — surveillance en cours")
                    .aFont(TypeScale.item, .heavy).foregroundStyle(T.ok)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).strokeBorder(T.doneLine, lineWidth: 2))
                    .padding(.bottom, 10)
            }
        }
    }
}

/// « PARCOURS · [Fait · 1→4] · d/t étapes » (A369).
struct CrProgressLine: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let headRun: [Int]?

    var body: some View {
        let p = CrisisPure.progress(ctx.R, ctx.plan)
        let conf = !Pool.list(ctx.f, .entry).isEmpty
        VStack(alignment: .leading, spacing: 8) {
            if p.tot > 0 || headRun != nil || conf {
                HStack(spacing: 10) {
                    if !ctx.narrow360 { Text("PARCOURS").aFont(TypeScale.meta, .heavy).tracking(0.8).foregroundStyle(T.ink2) }
                    Spacer(minLength: 4)
                    if let headRun {
                        CrRunPill(ctx: ctx, vs: vs, first: 0, ix: headRun, inline: false)
                    } else if conf {
                        confPill
                    }
                    Spacer(minLength: 4)
                    if p.tot > 0 {
                        Text("\(p.done)/\(p.tot) étapes").aFont(TypeScale.body, .bold).foregroundStyle(T.ink2)
                    }
                }
                .frame(minHeight: 28)
            }
            if let headRun, vs.ovFold["r:0"] == false {
                CrHistoryCard(ctx: ctx, vs: vs, ix: headRun, conf: conf)
            }
            if headRun == nil && conf && vs.ovFold["r:conf"] == false {
                CrCriteriaList(ctx: ctx).padding(.horizontal, 16)
                    .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
            }
        }
        .padding(.bottom, 10)
    }

    private var confPill: some View {
        Button {
            vs.ovFold["r:conf"] = (vs.ovFold["r:conf"] == false) ? true : false
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath").font(.system(size: 12, weight: .bold))
                Text("Fait · diagnostic confirmé").aFont(TypeScale.meta, .bold).lineLimit(1)
                Image(systemName: vs.ovFold["r:conf"] == false ? "chevron.up" : "chevron.down").font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(T.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 32)
            .background(T.amb2, in: Capsule())
            .contentShape(Capsule())
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

/// Critères d'entrée repris dans l'historique (« ■ » en encre secondaire : un critère n'est PAS une étape vitale).
struct CrCriteriaList: View {
    let ctx: CrCtx
    var body: some View {
        let crit = Pool.list(ctx.f, .entry)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(crit.enumerated()), id: \.offset) { i, it in
                CrFlatRow(first: i == 0) {
                    Text("■").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
                    BoldText(text: it.do, size: TypeScale.item, weight: .regular, color: T.ink)
                }
            }
        }
    }
}

/// Ligne condensée « Fait · a→b » ; tap = la carte d'historique (une rangée par passage fini).
struct CrRunPill: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let first: Int
    let ix: [Int]
    var inline = true

    var body: some View {
        let key = "r:\(first)"
        let open = vs.ovFold[key] == false
        let conf = first == 0 && !Pool.list(ctx.f, .entry).isEmpty
        let a = ix.first.flatMap { ctx.num(ctx.R.nav[$0]) }
        let b = ix.last.flatMap { ctx.num(ctx.R.nav[$0]) }
        let span: String = {
            guard let a, let b else { return "\(ix.count) blocs" }
            return a == b ? "\(a)" : "\(a)→\(b)"
        }()
        let label = "Fait · " + span + (conf ? " · diagnostic confirmé" : "")
        VStack(alignment: .leading, spacing: 8) {
            Button { vs.ovFold[key] = (vs.ovFold[key] == false) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 12, weight: .bold))
                    Text(label).aFont(TypeScale.meta, .bold).lineLimit(1)
                    Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(T.ink)
                .padding(.horizontal, 12)
                .frame(minHeight: 32)
                .background(T.amb2, in: Capsule())
                .contentShape(Capsule())
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(ix.count) blocs faits — taper pour déplier")
            .accessibilityValue(open ? "déplié" : "replié")
            if open && inline { CrHistoryCard(ctx: ctx, vs: vs, ix: ix, conf: conf) }
        }
    }
}

/// Carte d'historique (`ovHistRowHtml`) : « ✓ n · Titre » · « k/n » ou « › Réponse ».
struct CrHistoryCard: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let ix: [Int]
    let conf: Bool

    var body: some View {
        let R = ctx.R
        VStack(alignment: .leading, spacing: 0) {
            if conf {
                Button { vs.ovFold["r:confdet"] = !(vs.ovFold["r:confdet"] ?? false) } label: {
                    HStack(spacing: 8) {
                        Text("✓").aFont(TypeScale.item, .heavy).foregroundStyle(T.ok)
                        Text("Diagnostic confirmé · \(Pool.list(ctx.f, .entry).count) critères").aFont(TypeScale.body, .semibold).foregroundStyle(T.ink)
                        Spacer()
                        Image(systemName: vs.ovFold["r:confdet"] == true ? "chevron.up" : "chevron.down").foregroundStyle(T.ink2)
                    }
                    .frame(minHeight: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if vs.ovFold["r:confdet"] == true { CrCriteriaList(ctx: ctx) }
            }
            ForEach(ix, id: \.self) { i in
                let id = R.nav[i]
                if let b = ctx.block(id) {
                    VStack(spacing: 0) {
                        Rectangle().fill(T.line).frame(height: 1)
                        Button {
                            vs.ovFold[String(i)] = false
                            vs.pendingScroll = "!v\(i)"
                            vs.spotVisit = i
                        } label: { row(b, i) }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.workLine, lineWidth: 1))
    }

    private func row(_ b: Block, _ i: Int) -> some View {
        let R = ctx.R
        let pi = Graph.passInfo(nav: R.nav, i)
        let right: String
        if b.kind == .decision {
            right = ctx.e.decisionTaken(R, i).map { "› " + ($0.label.isEmpty ? "Option" : $0.label) } ?? "?"
        } else {
            let nd = ctx.e.visitNeed(R, b, seq: ctx.seq(i))
            right = nd.tot > 0 ? "\(nd.dn)/\(nd.tot)" : "—"
        }
        return HStack(spacing: 8) {
            Text("✓").aFont(TypeScale.item, .heavy).foregroundStyle(T.ok)
            Text((ctx.num(b.id).map { "\($0) · " } ?? "") + (b.title.isEmpty ? "Étapes" : b.title))
                .aFont(TypeScale.body, .semibold).foregroundStyle(T.ink).lineLimit(1)
            if pi.total > 1 { Text("· passage \(pi.pass)/\(pi.total)").aFont(TypeScale.meta, .medium).foregroundStyle(T.ink3) }
            Spacer(minLength: 6)
            Text(right).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2).lineLimit(1)
            Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold)).foregroundStyle(T.ink2)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

// MARK: - Carte de bloc

struct CrBlockCard: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let geom: CrGeomBox
    let idx: Int
    let pres: CrisisPure.Pres
    let complete: Bool
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if idx < ctx.R.nav.count, let b = ctx.block(ctx.R.nav[idx]) {
            card(b)
        }
    }

    @ViewBuilder
    private func card(_ b: Block) -> some View {
        let isTip = idx == ctx.tipIdx
        let dec = b.kind == .decision
        let line = pres == .line
        let border: Color = isTip ? (dec ? T.warnLine : T.act) : (dec ? T.verifyLine : (complete ? T.doneLine : T.workLine))
        let bg: Color = dec ? T.warnSoft : ((line && complete) ? T.okSoft : T.work)
        VStack(alignment: .leading, spacing: 0) {
            CrCardHead(ctx: ctx, vs: vs, b: b, idx: idx, isTip: isTip, line: line, complete: complete)
            if !line {
                CrCardBody(ctx: ctx, vs: vs, b: b, idx: idx, isTip: isTip)
                    .padding(.horizontal, ctx.narrow360 ? 12 : 18)
                    .padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(border, lineWidth: isTip ? 2 : 1))
        .overlay {
            if vs.spotVisit == idx {
                RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.act, lineWidth: 3)
                    .allowsHitTesting(false)
            }
        }
        .shadow(color: (isTip && scheme != .dark) ? Color.black.opacity(0.12) : .clear, radius: 16, y: 12)
        .background {
            if isTip {
                GeometryReader { g in
                    let fr = g.frame(in: .named("crScroll"))
                    Color.clear
                        .onAppear { geom.report(fr, vs: vs) }
                        .onChange(of: fr) { _, n in geom.report(n, vs: vs) }
                }
            }
        }
        .padding(.bottom, 10)
        .accessibilityElement(children: .contain)
    }
}

/// Tête d'une carte : pastille numérotée, titre, suffixes, « EN COURS », compte, chevron, « Refaire ».
struct CrCardHead: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let b: Block
    let idx: Int
    let isTip: Bool
    let line: Bool
    let complete: Bool
    @Environment(AppModel.self) private var model

    var body: some View {
        let R = ctx.R
        let seq = ctx.seq(idx)
        let dec = b.kind == .decision
        let isCx = R.cxBack[seq] != nil
        let pi = Graph.passInfo(nav: R.nav, idx)
        let latest = Graph.latestPass(nav: R.nav, navSeq: R.navSeq, b.id)?.idx == idx
        let count: String = {
            if dec { return complete ? "✓" : "?" }
            let n = ctx.e.visitNeed(R, b, seq: seq)
            return n.tot > 0 ? "\(n.dn)/\(n.tot)" : "—"
        }()
        VStack(alignment: .leading, spacing: 6) {
            Button {
                guard !isTip else { return }
                vs.ovFold[String(idx)] = line ? false : true
            } label: {
                HStack(alignment: line ? .center : .top, spacing: 10) {
                    badge(isCx: isCx)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(b.title.isEmpty ? (dec ? "Décision" : "Étapes") : b.title)
                            .aFont(line ? TypeScale.item : (dec ? TypeScale.step : TypeScale.stepL), line ? .bold : (dec ? .bold : .heavy))
                            .foregroundStyle(line && complete && !dec ? T.ok : T.ink)
                            .lineLimit(line ? 1 : nil)
                            .multilineTextAlignment(.leading)
                        if !line { suffixes(pi: pi, isCx: isCx, dec: dec) }
                    }
                    Spacer(minLength: 6)
                    if isTip && !line && !ctx.narrow360 {
                        Text("EN COURS").aFont(TypeScale.cap, .heavy).foregroundStyle(T.onPrimary)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(T.act, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    if !(isTip && !line) || ctx.narrow360 {
                        Text(count).aFont(TypeScale.body, .semibold).foregroundStyle(complete ? T.ok : T.ink2)
                    }
                    if !isTip {
                        Image(systemName: "chevron.down").font(.system(size: 14, weight: .semibold))
                            .rotationEffect(.degrees(line ? 0 : 180)).foregroundStyle(T.ink2)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: line ? 44 : 52, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(headA11y(pi: pi, isCx: isCx, count: count))
            .accessibilityValue(isTip ? "bloc en cours" : (line ? "replié" : "déplié"))
            .accessibilityAddTraits(isTip ? [.isHeader] : [.isHeader, .isButton])

            if !line, latest, let tid = b.timer, let w = CrisisPure.wtTimerModel(R, tid, key: nil, now: ctx.now) {
                CrWitnessLine(w: w)
            }
            if !isTip && complete && !dec && !line {
                Button { CrAct(model: model, vs: vs, R: R).redo(b.id) } label: {
                    Label("Refaire", systemImage: "arrow.uturn.backward")
                        .aFont(TypeScale.meta, .bold).foregroundStyle(T.ink)
                        .padding(.horizontal, 12)
                        .frame(minHeight: Ctrl.l)
                        .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.line, lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Refaire ce bloc : nouvelle carte au bout du journal — celle-ci reste telle quelle")
            }
        }
        .padding(.horizontal, line ? 8 : 16)
        .padding(.top, line ? 4 : 12)
        .padding(.bottom, line ? 4 : 4)
    }

    private func badge(isCx: Bool) -> some View {
        let n = ctx.num(b.id)
        return ZStack {
            RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).fill(complete ? T.ok : T.sys)
            if complete {
                Image(systemName: "checkmark").font(.system(size: 14, weight: .heavy)).foregroundStyle(T.onPrimary)
            } else if isCx {
                HStack(spacing: 1) {
                    CrBolt(size: 11)
                    if let n { Text("\(n)").aFont(TypeScale.meta, .heavy).foregroundStyle(T.sysInk) }
                }
            } else {
                Text(n.map { "\($0)" } ?? "·").aFont(TypeScale.body, .heavy).foregroundStyle(T.sysInk)
            }
        }
        .frame(minWidth: 30, minHeight: 30)
        .fixedSize()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func suffixes(pi: (pass: Int, total: Int), isCx: Bool, dec: Bool) -> some View {
        let taken = dec ? ctx.e.decisionTaken(ctx.R, idx) : nil
        if pi.total > 1 || isCx || taken != nil {
            CrWrap(spacing: 6) {
                if pi.total > 1 {
                    Text("passage \(pi.pass)/\(pi.total)").aFont(TypeScale.meta, .semibold, .mono).foregroundStyle(T.act)
                }
                if isCx {
                    HStack(spacing: 3) {
                        CrBolt(size: 10)
                        Text("COMPLICATION").aFont(TypeScale.cap, .heavy).foregroundStyle(T.warn)
                    }
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(T.warnSoft, in: Capsule())
                }
                if let taken {
                    Text("→ " + (taken.label.isEmpty ? "Option" : taken.label)).aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink2)
                }
            }
        }
    }

    private func headA11y(pi: (pass: Int, total: Int), isCx: Bool, count: String) -> String {
        var s = ctx.num(b.id).map { "Bloc \($0) — " } ?? (isCx ? "Complication — " : "")
        s += b.title.isEmpty ? "Étapes" : b.title
        if pi.total > 1 { s += ", passage \(pi.pass) sur \(pi.total)" }
        if count != "—" && count != "?" { s += ", " + count.replacingOccurrences(of: "/", with: " sur ") }
        return s
    }
}

/// Corps d'une carte ouverte.
struct CrCardBody: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let b: Block
    let idx: Int
    let isTip: Bool
    @Environment(AppModel.self) private var model

    var body: some View {
        let R = ctx.R
        let seq = ctx.seq(idx)
        let act = CrAct(model: model, vs: vs, R: R)
        VStack(alignment: .leading, spacing: 12) {
            if isTip, let back = R.cxBack[seq] {
                let bt = ctx.block(back.id)?.title ?? ""
                Button { act.resume(back.id) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward").font(.system(size: 15, weight: .bold))
                        Text("Reprendre — " + (bt.isEmpty ? "le parcours" : bt) + " →").aFont(TypeScale.step, .heavy)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(T.onPrimary)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: Ctrl.xl)
                    .background(T.act, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            if let img = b.image { CrDataImage(dataURI: img) }
            if isTip, let since = vs.resumeSince { resumeLine(since) }
            if let v = vs.verify, v.idx == idx, b.kind != .decision {
                CrVerifyView(ctx: ctx, vs: vs, b: b, idx: idx)
            } else if b.kind == .decision {
                if isTip { CrMilestones(ctx: ctx, vs: vs, b: b, idx: idx) }
                CrDecisionBody(ctx: ctx, vs: vs, b: b, idx: idx)
            } else {
                let steps = Graph.cleanSteps(ctx.f, b)
                let its = Pool.blockItems(ctx.f, b)
                let latest = Graph.latestPass(nav: R.nav, navSeq: R.navSeq, b.id)?.idx == idx
                if !ctx.narrow360 && its.contains(where: { !$0.expect.isEmpty }) {
                    Text("réponse attendue").aFont(TypeScale.meta, .semibold, .mono).foregroundStyle(T.ink2)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                if isTip { CrMilestones(ctx: ctx, vs: vs, b: b, idx: idx) }
                VStack(spacing: 6) {
                    ForEach(steps.indices, id: \.self) { i in
                        CrStepRow(ctx: ctx, vs: vs, b: b, visit: idx, seq: seq, i: i, s: steps[i],
                                  it: i < its.count ? its[i] : nil, latest: latest)
                    }
                }
                .padding(.horizontal, -8)
                if isTip && ctx.started { CrPosoBand(ctx: ctx, vs: vs, b: b, seq: seq) }
                if isTip { CrControls(ctx: ctx, vs: vs, b: b, idx: idx, hasSteps: !steps.isEmpty) }
            }
        }
    }

    private func resumeLine(_ since: Double) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "stopwatch").font(.system(size: 13, weight: .bold))
            Text("Reprise après interruption — dernier geste il y a " + Fmt.ms(ctx.now - since))
                .aFont(TypeScale.body, .semibold)
            Spacer(minLength: 4)
            Button { vs.resumeSince = nil } label: {
                Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).frame(width: Ctrl.l, height: Ctrl.l)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Masquer le rappel de reprise")
        }
        .foregroundStyle(T.warn)
        .overlay(alignment: .bottom) { Rectangle().fill(T.line).frame(height: 1) }
    }
}

/// « Vérifier » + « Continuer — … → » / « Terminer l’algorithme ✓ » (un SEUL bouton plein).
struct CrControls: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let b: Block
    let idx: Int
    let hasSteps: Bool
    @Environment(AppModel.self) private var model

    var body: some View {
        let R = ctx.R
        let seq = ctx.seq(idx)
        let need = ctx.e.visitNeed(R, b, seq: seq)
        let allDone = need.dn >= need.tot
        let act = CrAct(model: model, vs: vs, R: R)
        let rest = "Cochez les étapes restantes (\(need.tot - need.dn))"
        HStack(spacing: 10) {
            if hasSteps {
                Button { act.verifyStart(idx) } label: {
                    Text("Vérifier").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                        .padding(.horizontal, 16)
                        .frame(minHeight: Ctrl.xl)
                        .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Do-Verify : redérouler ce bloc étape par étape — « Constaté ✓ » coche, « △ Écart » avance sans cocher")
            }
            if let nx = b.next, let nb = ctx.block(nx) {
                let lbl = JS.trim(b.nextLbl).isEmpty ? (JS.trim(nb.title).isEmpty ? "suite" : JS.trim(nb.title)) : JS.trim(b.nextLbl)
                contButton(allDone ? "Continuer — " + lbl + " →" : rest, enabled: allDone) { act.continueTo(nx) }
            } else if !R.flowEnded && R.cxBack[seq] == nil {
                contButton(allDone ? "Terminer l’algorithme ✓" : rest, enabled: allDone) { act.endAlgorithm() }
            }
        }
        .padding(.top, 2)
    }

    /// Le libellé DIT pourquoi le bouton attend (`aria-disabled`, jamais inerte ni caché).
    private func contButton(_ label: String, enabled: Bool, _ go: @escaping () -> Void) -> some View {
        Button { if enabled { go() } } label: {
            Text(label).aFont(TypeScale.step, .heavy)
                .multilineTextAlignment(.center)
                .foregroundStyle(enabled ? T.onPrimary : T.ink2)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: Ctrl.xl)
                .background(enabled ? T.act : T.amb2, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.workLine, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(enabled ? "" : "Indisponible tant que des étapes restent à cocher")
    }
}

/// La carte de DÉCISION : question 21/800, options « → bloc n · Titre » ; toujours actives.
struct CrDecisionBody: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let b: Block
    let idx: Int
    @Environment(AppModel.self) private var model

    var body: some View {
        let taken = ctx.e.decisionTaken(ctx.R, idx)
        let cols: [GridItem] = ctx.w >= 1000 || ctx.narrow360 ? [GridItem(.flexible())] : [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        VStack(alignment: .leading, spacing: 12) {
            if !JS.trim(b.question).isEmpty {
                BoldText(text: b.question, size: TypeScale.stepL, weight: .heavy, color: T.ink)
            }
            LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
                ForEach(Array(b.options.enumerated()), id: \.offset) { oi, o in
                    option(o, oi, taken: taken != nil && taken!.target == o.target && taken!.label == o.label)
                }
            }
        }
    }

    private func option(_ o: DecisionOption, _ oi: Int, taken: Bool) -> some View {
        let dest: String = {
            guard let t = o.target, let tb = ctx.block(t) else { return "▪ fin" }
            let title = tb.title.isEmpty ? "Étapes" : tb.title
            return ctx.num(t).map { "→ bloc \($0) · " + title } ?? "→ " + title
        }()
        let label = o.label.isEmpty ? "Option \(oi + 1)" : o.label
        return Button { CrAct(model: model, vs: vs, R: ctx.R).answer(idx, o.target) } label: {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    BoldText(text: label, size: ctx.started ? TypeScale.step : TypeScale.item, weight: .bold, color: taken ? T.sysInk : T.ink)
                    Text(dest).aFont(TypeScale.meta, .semibold).foregroundStyle(taken ? T.sysInk2 : T.ink2).lineLimit(1)
                }
                Spacer(minLength: 4)
                if taken { Text("✓").aFont(TypeScale.step, .heavy).foregroundStyle(T.okSys) }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
            .background(taken ? T.sys : T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.workLine, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label + ", " + dest)
        .accessibilityAddTraits(taken ? .isSelected : [])
    }
}

/// Jalons de boucle (carte vive seulement) : rien ne se déclenche — ils s'allument en ambre.
struct CrMilestones: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let b: Block
    let idx: Int
    @Environment(AppModel.self) private var model

    var body: some View {
        let R = ctx.R
        let pass = Graph.passInfo(nav: R.nav, idx).pass
        let cxs = CrisisPure.cxAll(ctx.f)
        if !b.milestones.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(b.milestones.enumerated()), id: \.offset) { _, j in
                    let p = Jalons.progress(j, pass: pass, count: R.counters[j.counter] ?? 0)
                    let go = j.go.isEmpty ? nil : cxs.first { $0.target == j.go }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("△").aFont(TypeScale.meta, .heavy)
                            Text(Jalons.conditionLabel(ctx.f, j) + (j.text.isEmpty ? "" : " — " + j.text))
                                .aFont(TypeScale.meta, p.active ? .heavy : .medium)
                                .lineLimit(3)
                            Spacer(minLength: 4)
                            Text("\(crNum(p.cur))/\(p.goal)").aFont(TypeScale.meta, .bold, .mono)
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(T.amb2, in: Capsule())
                                .accessibilityLabel("\(crNum(p.cur)) sur un seuil de \(p.goal)")
                        }
                        if p.active, let go {
                            Button { CrAct(model: model, vs: vs, R: R).cxGo(go) } label: {
                                HStack(spacing: 6) {
                                    CrBolt(size: 13)
                                    Text(HTML.stripBold(go.label) + (go.isBlock ? "" : " ↗")).aFont(TypeScale.meta, .bold)
                                }
                                .foregroundStyle(T.crit)
                                .padding(.horizontal, 12)
                                .frame(minHeight: Ctrl.l)
                                .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.critLine, lineWidth: 1))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(go.isBlock ? "Interrompt le parcours, retour prévu — à tout moment" : "Ouvre une autre aide — à tout moment")
                        }
                    }
                    .foregroundStyle(p.active ? T.warn : T.ink2)
                    .padding(.vertical, 8).padding(.horizontal, p.active ? 10 : 0)
                    .background(p.active ? T.warnSoft : Color.clear)
                    .overlay(alignment: .leading) { if p.active { Rectangle().fill(T.warnLine).frame(width: 3) } }
                    .overlay(alignment: .bottom) { Rectangle().fill(T.line).frame(height: 1) }
                }
            }
        }
    }
}

// MARK: - Rangée d'étape (le cœur)

struct CrStepRow: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let b: Block
    let visit: Int
    let seq: Int
    let i: Int
    let s: String
    let it: Item?
    let latest: Bool
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let rid = it?.review, let rb = ctx.block(rid), rb.kind == .review {
            CrReviewDoor(ctx: ctx, vs: vs, rb: rb, text: Steps.challengeResponse(Steps.text(s)).c)
        } else {
            row
        }
    }

    private var key: String { "\(seq):\(b.id):\(i)" }

    @ViewBuilder
    private var row: some View {
        let R = ctx.R
        let on = R.isChecked(key)
        let mo = ctx.e.stepMoment(R, it, seq: seq, blockId: b.id, index: i)
        let wait = !on && mo?.st == .wait
        let gone = !on && mo?.st == .gone
        if wait || gone {
            content(on: on, mo: mo, wait: wait, gone: gone)
                .accessibilityElement(children: .contain)
        } else {
            Button { CrAct(model: model, vs: vs, R: R).toggleStep(key) } label: {
                content(on: on, mo: mo, wait: false, gone: false)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(a11yLabel)
            .accessibilityValue(on ? "cochée" : "non cochée")
            .accessibilityAddTraits(.isToggle)
        }
    }

    private var a11yLabel: String {
        let cr = Steps.challengeResponse(Steps.text(s))
        let lvl = Steps.level(s)
        let pre = lvl == 3 ? "Étape critique. " : (lvl == 2 ? "Vigilance. " : "")
        let dual = (it?.dual ?? false) ? " À confirmer par les deux (AC 120-71B §5.2.2.5)." : ""
        return pre + HTML.stripBold(cr.c) + (cr.r.map { ", réponse attendue : " + $0 } ?? "") + dual
    }

    @ViewBuilder
    private func content(on: Bool, mo: Moment?, wait: Bool, gone: Bool) -> some View {
        let R = ctx.R
        let cr = Steps.challengeResponse(Steps.text(s))
        let lvl = Steps.level(s)
        let legend = legendModel(on: on, wait: wait)
        let size: CGFloat = ctx.narrow360 ? TypeScale.item : (ctx.started ? TypeScale.step : TypeScale.item)
        HStack(alignment: legend != nil || wait ? .top : .center, spacing: 12) {
            box(on: on, lvl: lvl, wait: wait, gone: gone)
            VStack(alignment: .leading, spacing: 4) {
                tags(on: on, mo: mo, lvl: lvl, wait: wait)
                BoldText(text: cr.c, size: size, weight: .bold, color: (on || wait || gone) ? T.ink2 : T.ink)
                if let r = cr.r {
                    Text((on ? "✓ " : "") + r).aFont(TypeScale.body, .semibold, .mono).foregroundStyle(T.ink2)
                }
                if wait, let mo { waitLine(mo) }
                if let legend { CrWitnessLine(w: legend) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if R.verified[key] != nil {
                CrTag(text: "✓✓ constaté", fg: T.ok, bg: T.okSoft, border: T.doneLine)
            } else if R.vgaps[key] != nil {
                CrTag(text: "△ écart", fg: T.warn, bg: T.warnSoft, border: T.warnLine)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: ctx.narrow360 ? 56 : Ctrl.stepRow, alignment: .leading)
        .background(wait ? Color.clear : (on ? T.okSoft : T.amb2), in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
        .overlay {
            if wait {
                RoundedRectangle(cornerRadius: Radius.r4, style: .continuous)
                    .strokeBorder(T.ctlLine, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            } else if gone {
                RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.line, lineWidth: 1)
            }
        }
        .contentShape(Rectangle())
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: on)
    }

    private func box(on: Bool, lvl: Int, wait: Bool, gone: Bool) -> some View {
        let border: Color = lvl == 3 ? T.crit : (lvl == 2 ? T.warnLine : T.ctlLine)
        return ZStack {
            if wait {
                RoundedRectangle(cornerRadius: Radius.r3, style: .continuous)
                    .strokeBorder(T.ctlLine, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            } else if gone {
                RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).fill(T.ink3)
                Image(systemName: "checkmark").font(.system(size: 17, weight: .heavy)).foregroundStyle(T.work)
            } else if on {
                RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).fill(T.ok)
                Image(systemName: "checkmark").font(.system(size: 19, weight: .heavy)).foregroundStyle(T.onPrimary)
                    .transition(reduceMotion ? .identity : .scale(scale: 0.6).combined(with: .opacity))
            } else {
                RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).fill(T.work)
                RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(border, lineWidth: 2.5)
            }
        }
        .frame(width: 36, height: 36)
        .accessibilityHidden(true)
    }

    /// Le MOT du registre (A345) au-dessus du libellé, « Double contrôle », le moment — jamais de glyphe ⚠/△.
    @ViewBuilder
    private func tags(on: Bool, mo: Moment?, lvl: Int, wait: Bool) -> some View {
        let mt: (tone: CrisisPure.TagTone, word: String)? = momentTag(on: on, mo: mo)
        let showReg = lvl >= 2 && !wait
        let dual = it?.dual ?? false
        if showReg || dual || mt != nil {
            CrWrap(spacing: 6) {
                if showReg {
                    if on { CrTag(text: lvl == 3 ? "Critique" : "Vigilance", fg: T.ink2, bg: T.amb2) }
                    else if lvl == 3 { CrTag(text: "Critique", fg: T.crit, bg: T.critSoft) }
                    else { CrTag(text: "Vigilance", fg: T.warn, bg: T.warnSoft) }
                }
                if dual { CrTag(text: "Double contrôle", fg: T.ink2, bg: T.amb2, border: T.ctlLine) }
                if let mt { momentTagView(mt) }
            }
        }
    }
    @ViewBuilder
    private func momentTagView(_ mt: (tone: CrisisPure.TagTone, word: String)) -> some View {
        switch mt.tone {
        case .outline: CrTag(text: mt.word, fg: T.ink2, bg: T.work, border: T.ink2)
        case .warn: CrTag(text: mt.word, fg: T.warn, bg: T.warnSoft)
        case .ok: CrTag(text: mt.word, fg: T.ok, bg: T.okSoft)
        case .neutral: CrTag(text: mt.word, fg: T.ink2, bg: T.amb2)
        }
    }
    /// Étiquette du moment : sur une rangée cochée, la RÈGLE de départ seulement (`momDone`).
    private func momentTag(on: Bool, mo: Moment?) -> (tone: CrisisPure.TagTone, word: String)? {
        guard let it else { return nil }
        if !on { return mo.map { CrisisPure.momTag(ctx.f, it, $0) } }
        if let fr = it.from {
            let met = (ctx.R.counters[fr.counter] ?? 0) >= Double(fr.n)
            return CrisisPure.momTag(ctx.f, it, met ? Moment(.met, req: true) : Moment(.wait, why: .from))
        }
        if it.repeat == .need { return (.neutral, "Au besoin") }
        return nil
    }

    /// Avant son moment : progression (pastilles ≤ 8) ou témoin du minuteur attendu, puis « Faire maintenant ».
    @ViewBuilder
    private func waitLine(_ mo: Moment) -> some View {
        let R = ctx.R
        VStack(alignment: .leading, spacing: 6) {
            if mo.why == .from, let fr = it?.from {
                let n = Int(R.counters[fr.counter] ?? 0), N = fr.n
                HStack(spacing: 4) {
                    if N <= 8 {
                        ForEach(0..<N, id: \.self) { k in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(k < n ? T.ink2 : Color.clear)
                                .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous).strokeBorder(T.ink2, lineWidth: 1))
                                .frame(width: 8, height: 8)
                        }
                        .accessibilityHidden(true)
                        Text("encore \(max(0, N - n))").aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink2)
                            .padding(.leading, 4)
                            .accessibilityLabel("\(n) sur \(N), encore \(max(0, N - n))")
                    } else {
                        Text("\(n) / \(N) · encore \(max(0, N - n))").aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink2)
                    }
                }
            } else if mo.why == .due, let it, let w = CrisisPure.wtTimerModel(R, Moments.timerId(ctx.f, it), key: key, now: ctx.now) {
                CrWitnessLine(w: w)
            }
            Button { CrAct(model: model, vs: vs, R: R).doNow(key) } label: {
                Text("Faire maintenant").aFont(TypeScale.meta, .bold).foregroundStyle(T.act)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 28)
                    .overlay(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).strokeBorder(T.act, lineWidth: 1))
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Faire maintenant : " + HTML.stripBold(Steps.challengeResponse(Steps.text(s)).c))
        }
    }

    /// Le témoin d'un lien (A377), sur le passage le plus récent du bloc seulement.
    private func legendModel(on: Bool, wait: Bool) -> CrisisPure.Witness? {
        guard latest, !wait, let it else { return nil }
        if let tid = it.starts, ctx.R.timers[tid] != nil { return CrisisPure.wtTimerModel(ctx.R, tid, key: key, now: ctx.now) }
        if let cid = it.counts { return CrisisPure.wtCountModel(ctx.R, cid, key: key, now: ctx.now) }
        return nil
    }
}

/// Ligne témoin (24 pt réservés) : anneau / icône · valeur · nom. Gris au repos, bleu SANS FOND en
/// cours, pastille ambre à l'échéance.
struct CrWitnessLine: View {
    let w: CrisisPure.Witness
    var body: some View {
        HStack(spacing: 6) {
            if let r = w.ring {
                ZStack {
                    Circle().stroke(T.primary200, lineWidth: 2)
                    Circle().trim(from: 0, to: CGFloat(r)).stroke(w.due ? T.warnLine : (w.running ? T.act : T.ink2), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 12, height: 12)
            } else {
                Image(systemName: w.glyph == "number" ? "number" : "stopwatch").font(.system(size: 12, weight: .bold))
            }
            Text(w.value).aFont(TypeScale.body, w.due ? .heavy : .bold, w.due ? .ui : .mono)
                .foregroundStyle(w.due ? T.warn : (w.running ? T.act : T.ink2))
            Text(w.text).aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2).lineLimit(1)
        }
        .foregroundStyle(T.ink2)
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(w.due ? T.warnSoft : Color.clear, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
        .overlay {
            if w.due { RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).strokeBorder(T.warnLine, lineWidth: 1) }
        }
        .padding(.leading, -8)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Porte de revue (A396/A398)

struct CrReviewDoor: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let rb: Block
    let text: String
    @Environment(AppModel.self) private var model

    var body: some View {
        let st = ctx.e.reviewState(ctx.R, rb)
        let open = vs.revOpen[rb.id] ?? !st.done
        let word = st.done ? "faite" : (st.k > 0 ? "en cours" : "à faire")
        VStack(alignment: .leading, spacing: 8) {
            Button { vs.revOpen[rb.id] = !open } label: {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.r3, style: .continuous)
                            .strokeBorder(st.done ? T.ok : T.ctlLine, style: StrokeStyle(lineWidth: 2, dash: st.done ? [] : [4, 3]))
                        if st.done { Image(systemName: "checkmark").font(.system(size: 17, weight: .heavy)).foregroundStyle(T.ok) }
                    }
                    .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        BoldText(text: text.isEmpty ? (rb.title.isEmpty ? "Revue" : rb.title) : text,
                                 size: ctx.started ? TypeScale.step : TypeScale.item, weight: .bold, color: T.ink)
                        HStack(spacing: 6) {
                            Image(systemName: "square.grid.2x2").font(.system(size: 12, weight: .bold))
                            Text("\(st.k)/\(st.n)").aFont(TypeScale.meta, .bold, .mono)
                            Text(word).aFont(TypeScale.meta, .bold)
                            Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(st.done ? T.ok : T.act)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: Ctrl.stepRow, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue("\(st.k) sur \(st.n), " + word + (open ? ", déplié" : ", replié"))
            if open { CrReviewGrid(ctx: ctx, vs: vs, rb: rb).padding(.horizontal, 8).padding(.bottom, 8) }
        }
        .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
    }
}

/// Grille des hypothèses d'une revue (cases `r:revue:index`).
struct CrReviewGrid: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let rb: Block
    @Environment(AppModel.self) private var model

    var body: some View {
        let R = ctx.R
        let steps = Graph.cleanSteps(ctx.f, rb)
        let act = CrAct(model: model, vs: vs, R: R)
        VStack(alignment: .leading, spacing: 4) {
            ForEach(steps.indices, id: \.self) { i in
                let k = "r:\(rb.id):\(i)"
                let on = R.isChecked(k)
                let cr = Steps.challengeResponse(Steps.text(steps[i]))
                let lvl = Steps.level(steps[i])
                Button { act.toggleReview(rb.id, k) } label: {
                    HStack(alignment: .center, spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).fill(on ? T.ok : T.work)
                            RoundedRectangle(cornerRadius: Radius.r1, style: .continuous)
                                .strokeBorder(on ? T.ok : (lvl == 3 ? T.crit : (lvl == 2 ? T.warnLine : T.ctlLine)), lineWidth: 2)
                            if on { Image(systemName: "checkmark").font(.system(size: 14, weight: .heavy)).foregroundStyle(T.onPrimary) }
                        }
                        .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            if lvl >= 2 && !on {
                                CrTag(text: lvl == 3 ? "Critique" : "Vigilance", fg: lvl == 3 ? T.crit : T.warn, bg: lvl == 3 ? T.critSoft : T.warnSoft)
                            }
                            BoldText(text: cr.c, size: TypeScale.item, weight: .semibold, color: on ? T.ink2 : T.ink)
                            if let r = cr.r { Text(r).aFont(TypeScale.meta, .semibold, .mono).foregroundStyle(T.ink2) }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel((lvl == 3 ? "Étape critique. " : (lvl == 2 ? "Vigilance. " : "")) + HTML.stripBold(cr.c))
                .accessibilityValue(on ? "cochée" : "non cochée")
                .accessibilityAddTraits(.isToggle)
            }
            Button { act.newReview(rb.id) } label: {
                Text("Nouvelle revue").aFont(TypeScale.meta, .bold).foregroundStyle(T.act)
                    .padding(.horizontal, 12).frame(minHeight: Ctrl.s)
                    .overlay(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).strokeBorder(T.line, lineWidth: 1))
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
    }
}

// MARK: - Bande « Repères de ce bloc » (A397)

struct CrPosoBand: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let b: Block
    let seq: Int

    var body: some View {
        let R = ctx.R
        let e = ctx.e
        let rows = CrisisPure.posBandModel(ctx.f, b, seq: seq, isChecked: { R.isChecked($0) },
                                          moOf: { it, i in e.stepMoment(R, it, seq: seq, blockId: b.id, index: i) })
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle().fill(T.line).frame(height: 1)
                Button { vs.pbandOpen.toggle() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pills").font(.system(size: 13, weight: .bold)).foregroundStyle(T.act).frame(width: 20)
                        Text("REPÈRES DE CE BLOC").aFont(TypeScale.cap, .heavy).tracking(0.6).foregroundStyle(T.ink2)
                        Text("\(rows.count)").aFont(TypeScale.body, .bold, .mono).foregroundStyle(T.ink2)
                        Spacer(minLength: 4)
                        if !vs.pbandOpen { Text(summary(rows)).aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink2).lineLimit(1) }
                        Image(systemName: vs.pbandOpen ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .bold)).foregroundStyle(T.ink2)
                    }
                    .frame(minHeight: Ctrl.l)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(vs.pbandOpen ? "déplié" : "replié")
                if vs.pbandOpen {
                    ForEach(rows, id: \.id) { r in rowView(r) }
                }
            }
        }
    }

    private func summary(_ rows: [CrisisPure.PosoRow]) -> String {
        var p: [String] = []
        for w in ["fait", "à faire", "à préparer"] {
            let n = rows.filter { $0.stt == w }.count
            if n > 0 { p.append("\(n)\u{00A0}" + w.replacingOccurrences(of: " ", with: "\u{00A0}")) }
        }
        return p.joined(separator: " · ")
    }

    private func rowView(_ r: CrisisPure.PosoRow) -> some View {
        let open = vs.pbandDetail.contains(r.id)
        let (fg, bg): (Color, Color) = r.stt == "fait" ? (T.ok, T.okSoft) : (r.stt == "à faire" ? (T.act, T.primarySoft) : (T.ink2, T.amb2))
        return VStack(alignment: .leading, spacing: 6) {
            Button {
                if open { vs.pbandDetail.remove(r.id) } else { vs.pbandDetail.insert(r.id) }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "pills").font(.system(size: 11, weight: .bold)).foregroundStyle(T.act)
                        .frame(width: 20, height: 20)
                        .background(T.primarySoft, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(r.name.uppercased()).aFont(TypeScale.body, .heavy).foregroundStyle(T.ink).lineLimit(2)
                            CrTag(text: r.stt, fg: fg, bg: bg)
                        }
                        if !r.body.isEmpty { Text(r.body).aFont(TypeScale.body, .semibold, .mono).foregroundStyle(T.ink2) }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 11, weight: .bold)).foregroundStyle(T.ink2)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if open {
                Text(r.note.isEmpty ? "Aucun détail rédigé." : r.note)
                    .aFont(TypeScale.body, .medium).foregroundStyle(T.ink)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(T.amb, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                    .padding(.leading, 30)
            }
        }
    }
}

// MARK: - Passe Do-Verify

struct CrVerifyView: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let b: Block
    let idx: Int
    @Environment(AppModel.self) private var model

    var body: some View {
        let R = ctx.R
        let seq = ctx.seq(idx)
        let steps = Graph.cleanSteps(ctx.f, b)
        let v = vs.verify ?? CrVerify(idx: idx, i: 0, gaps: [])
        let act = CrAct(model: model, vs: vs, R: R)
        let nOk = steps.indices.filter { R.verified["\(seq):\(b.id):\($0)"] != nil }.count
        let nGap = steps.indices.filter { R.vgaps["\(seq):\(b.id):\($0)"] != nil }.count
        let rest = max(0, steps.count - v.i)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("VÉRIFICATION").aFont(TypeScale.cap, .heavy).tracking(0.8).foregroundStyle(T.act)
                Spacer()
                Button("✕ Quitter") { act.verifyEnd() }
                    .aFont(TypeScale.meta, .bold).foregroundStyle(T.ink)
                    .frame(minHeight: Ctrl.l)
                    .buttonStyle(.plain)
                    .accessibilityHint("L'état des cases est déjà enregistré")
            }
            Text("lisez le challenge, constatez l'état réel").aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
            HStack(spacing: 10) {
                Text("✓✓ \(nOk) constaté" + (nOk > 1 ? "s" : "")).foregroundStyle(T.ok)
                Text("△ \(nGap) écart" + (nGap > 1 ? "s" : "")).foregroundStyle(T.warn)
                Text("\(rest) restante" + (rest > 1 ? "s" : "")).foregroundStyle(T.ink2)
            }
            .aFont(TypeScale.meta, .heavy)
            ForEach(steps.indices, id: \.self) { i in
                vRow(i, steps[i], seq: seq, cur: i == v.i)
            }
            if v.i < steps.count {
                let k = "\(seq):\(b.id):\(v.i)"
                HStack(spacing: 10) {
                    Button { act.verifyOK(k) } label: {
                        Text("Constaté ✓").aFont(TypeScale.item, .heavy).foregroundStyle(T.onPrimary)
                            .frame(maxWidth: .infinity, minHeight: Ctrl.row)
                            .background(T.ok, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .layoutPriority(2)
                    Button { act.verifyGap(k, v.i) } label: {
                        Text("△ Écart").aFont(TypeScale.item, .heavy).foregroundStyle(T.warn)
                            .frame(maxWidth: .infinity, minHeight: Ctrl.row)
                            .background(T.warnSoft, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.warnLine, lineWidth: 2))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                endBox(steps: steps, seq: seq)
                Button { act.verifyEnd() } label: {
                    Text("Terminer la vérification").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                        .frame(maxWidth: .infinity, minHeight: Ctrl.l)
                        .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func vRow(_ i: Int, _ s: String, seq: Int, cur: Bool) -> some View {
        let R = ctx.R
        let k = "\(seq):\(b.id):\(i)"
        let ok = R.verified[k] != nil
        let gap = R.vgaps[k] != nil
        let v = vs.verify ?? CrVerify(idx: idx, i: 0, gaps: [])
        let passed = i < v.i
        let mark = ok ? "✓✓" : (gap ? "△" : (cur ? "▸" : "·"))
        let cr = Steps.challengeResponse(Steps.text(s))
        return HStack(alignment: .top, spacing: 10) {
            Text(mark).aFont(TypeScale.item, .heavy).foregroundStyle(ok ? T.ok : (gap ? T.warn : T.act)).frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                BoldText(text: cr.c, size: cur ? TypeScale.step : TypeScale.item, weight: cur ? .heavy : .semibold, color: T.ink)
                if let r = cr.r { Text(r).aFont(TypeScale.body, .semibold, .mono).foregroundStyle(T.ink2) }
                if ok { CrTag(text: "✓✓ constaté", fg: T.ok, bg: T.okSoft) }
                else if gap { CrTag(text: "△ écart", fg: T.warn, bg: T.warnSoft) }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ok ? T.okSoft : (gap ? T.warnSoft : T.amb2), in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .overlay { if cur { RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.act, lineWidth: 2) } }
        .opacity(cur || passed || ok || gap ? 1 : 0.45)
        .accessibilityElement(children: .combine)
    }

    private func endBox(steps: [String], seq: Int) -> some View {
        let R = ctx.R
        let g = steps.indices.filter { !R.isChecked("\(seq):\(b.id):\($0)") }
        let n = steps.count
        let text: Text
        if g.isEmpty {
            text = Text("\(n)/\(n) vérifiées — bloc confirmé ✓").bold()
        } else {
            let nums = g.map { String($0 + 1) }.joined(separator: ", ")
            text = Text("\(n - g.count)/\(n) vérifiées · \(g.count) écart" + (g.count > 1 ? "s" : "")).bold()
                + Text(" — étape" + (g.count > 1 ? "s " : " ") + nums + " non cochée" + (g.count > 1 ? "s" : "") + " (elles restent visibles dans le parcours)")
        }
        return text.aFont(TypeScale.body, .medium)
            .foregroundStyle(g.isEmpty ? T.ok : T.warn)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(g.isEmpty ? T.okSoft : T.warnSoft, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
    }
}
