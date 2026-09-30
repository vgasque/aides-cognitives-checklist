import SwiftUI
import AidesCore

// LA CAPSULE (état, en haut) ET LE QUAI (commandes, en bas) — les deux seuls objets sombres de
// l'écran (matière système), trouvables sans lire. Port de `updateRtStrip`, `#sessionDock`,
// `#dockSheet`, `#blkReturn`.

// MARK: - Mise en rangée qui passe à la ligne (puces)

struct CrWrap: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? 10_000
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, width: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(ProposedViewSize(width: maxW, height: nil))
            if x > 0 && x + sz.width > maxW { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
            width = max(width, x - spacing)
        }
        return CGSize(width: min(width, maxW), height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x > bounds.minX && x + sz.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: min(sz.width, bounds.width), height: sz.height))
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
    }
}

// MARK: - La capsule

struct CrCapsule: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let R = ctx.R
        let now = ctx.now
        let phone = ctx.wc == .phone
        let shown = shownTimers()
        Button {
            if phone { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) { vs.voletOpen.toggle() } }
            else { vs.railScroll = "timers-\(Int(now))" }
        } label: {
            HStack(spacing: 6) {
                globalSegment(R, now)
                if phone {
                    ViewThatFits(in: .horizontal) {
                        ForEach(variants(shown), id: \.self) { v in
                            row(shown, v)
                        }
                    }
                } else {
                    row(shown, Variant(n: min(2, shown.count), counter: false, recall: shown.isEmpty, chevron: false))
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, minHeight: ctx.narrow360 ? 56 : 64, alignment: .leading)
            .background(T.sys, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.sysEdge, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Minuteurs en cours — afficher le panneau")
        .accessibilityValue(summary(shown, now))
    }

    struct Variant: Hashable {
        var n: Int
        var counter: Bool
        var recall: Bool
        var chevron: Bool
    }

    /// Minuteurs à montrer : au téléphone tout ce qui tourne ou sonne ; en large, échus + bientôt échus (≤ 2).
    private func shownTimers() -> [TimerState] {
        let R = ctx.R
        let run = R.orderedTimers.filter { $0.running || ($0.isDueDock && !$0.ack) }
        let sorted = CrisisPure.tmLiveOrder(run, now: ctx.now)
        if ctx.wc == .phone { return sorted }
        return Array(sorted.filter { ($0.isDueDock && !$0.ack) || CrisisPure.isSoon($0, ctx.now) }.prefix(2))
    }
    /// Ordre de sacrifice (`updateRtStrip`) : libellé de rappel → chevron → tuile compteur → minuteur
    /// nominal ; jamais le segment de session, jamais « +n », jamais un échu si autre chose peut partir.
    private func variants(_ shown: [TimerState]) -> [Variant] {
        let hasCounter = ctx.started && !ctx.f.counters.isEmpty
        var out: [Variant] = []
        let maxN = min(3, shown.count)
        if maxN > 0 {
            for n in stride(from: maxN, through: 1, by: -1) {
                if hasCounter { out.append(Variant(n: n, counter: true, recall: false, chevron: true)) }
                out.append(Variant(n: n, counter: false, recall: false, chevron: true))
                out.append(Variant(n: n, counter: false, recall: false, chevron: false))
            }
        } else {
            if hasCounter {
                out.append(Variant(n: 0, counter: true, recall: true, chevron: true))
                out.append(Variant(n: 0, counter: true, recall: false, chevron: true))
            }
            out.append(Variant(n: 0, counter: false, recall: true, chevron: true))
        }
        out.append(Variant(n: 0, counter: false, recall: false, chevron: true))
        return out
    }

    @ViewBuilder
    private func row(_ shown: [TimerState], _ v: Variant) -> some View {
        let R = ctx.R
        let visible = Array(shown.prefix(v.n))
        let dueHidden = shown.dropFirst(v.n).filter { $0.isDueDock && !$0.ack }.count
        HStack(spacing: 6) {
            ForEach(visible, id: \.id) { t in timerTile(t) }
            if dueHidden > 0 {
                Text("+\(dueHidden)").aFont(TypeScale.meta, .bold).foregroundStyle(T.warnSys)
                    .accessibilityLabel("\(dueHidden) autre(s) minuteur(s) échu(s)")
            }
            if v.counter, let c = ctx.f.counters.first {
                counterTile(c, R.counters[c.id] ?? 0)
            }
            Spacer(minLength: 0)
            if v.chevron {
                HStack(spacing: 4) {
                    if v.recall && v.n == 0 {
                        let r = recallText()
                        if !r.isEmpty { Text(r).aFont(TypeScale.meta, .bold).foregroundStyle(T.sysInk2).lineLimit(1) }
                    }
                    Text(vs.voletOpen ? "▴" : "▾").aFont(TypeScale.meta, .bold).foregroundStyle(T.sysInk2)
                }
                .fixedSize()
            }
        }
    }

    private func globalSegment(_ R: RuntimeSession, _ now: Double) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(R.exercise ? "▲ EXERCICE" : "● SESSION")
                .aFont(TypeScale.body, .heavy)
                .foregroundStyle(R.exercise ? T.act : T.okSys)
                .lineLimit(1)
            Text(R.startedAt > 0 ? Fmt.ms(now - R.startedAt) : "—")
                .aFont(TypeScale.val, .bold, .mono)
                .foregroundStyle(T.sysInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.leading, 8).padding(.trailing, 12)
        .frame(minWidth: 92, alignment: .leading)
        .overlay(alignment: .trailing) { Rectangle().fill(T.sysLine).frame(width: 1).padding(.vertical, 6) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel((R.exercise ? "Exercice" : "Session") + " — durée " + (R.startedAt > 0 ? Fmt.ms(now - R.startedAt) : "inconnue"))
    }

    private func timerTile(_ t: TimerState) -> some View {
        let now = ctx.now
        let due = t.isDueDock && !t.ack
        let soon = !due && CrisisPure.isSoon(t, now)
        let ink: Color = (due || soon) ? T.warnSys : T.sysInk
        // Pulsation de l'échu (1 → 0,55 → 1 en 2 s), calculée depuis l'horloge : jamais sous « réduire les animations ».
        let phase = now.truncatingRemainder(dividingBy: 2000) / 2000
        let pulse = (due && !reduceMotion) ? 1 - 0.45 * sin(Double.pi * phase) : 1
        let frac = t.type == .interval && t.period > 0 ? max(0, min(1, t.remaining(now) / t.period)) : 1
        return VStack(alignment: .leading, spacing: 2) {
            Text(((due || soon) ? "△ " : "") + CrisisPure.tmShort(t).uppercased())
                .aFont(TypeScale.body, .heavy).foregroundStyle(ink).lineLimit(1)
            Text(t.display(now)).aFont(TypeScale.step, .bold, .mono).foregroundStyle(ink).lineLimit(1)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle().fill(T.sysLine)
                    Rectangle().fill(due ? T.warnSys : T.sysInk2).frame(width: g.size.width * frac)
                }
            }
            .frame(height: 3)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .frame(minWidth: 96, minHeight: ctx.narrow360 ? 44 : 52, alignment: .leading)
        .background(due ? T.warnSysBg : T.sys2, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(due ? T.warnSys : Color.clear, lineWidth: 1))
        .opacity(pulse)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(t.name + " : " + t.display(now) + (due ? ", échu" : (soon ? ", bientôt échu" : "")))
    }

    private func counterTile(_ c: CounterDef, _ v: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(CrisisPure.cnShort(c).uppercased()).aFont(TypeScale.body, .heavy).foregroundStyle(T.sysInk).lineLimit(1)
            Text(crNum(v)).aFont(TypeScale.step, .bold, .mono).foregroundStyle(T.sysInk)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .frame(minWidth: 84, minHeight: ctx.narrow360 ? 44 : 52, alignment: .leading)
        .background(T.sys2, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel((c.label.isEmpty ? "Compteur" : c.label) + " : " + crNum(v))
    }

    /// « n minuteurs · k compteurs · ⏸ p en pause » — seulement ce qui n'est pas montré.
    private func recallText() -> String {
        let R = ctx.R
        let nT = R.orderedTimers.count
        let nC = ctx.f.counters.count + R.adhocCounters.count
        let pause = R.orderedTimers.filter { $0.type == .interval && !$0.running && !$0.isDueDock && $0.elapsedMs > 0 }.count
        var p: [String] = []
        if nT > 0 { p.append("\(nT) minuteur" + (nT > 1 ? "s" : "")) }
        if nC > 0 { p.append("\(nC) compteur" + (nC > 1 ? "s" : "")) }
        if pause > 0 { p.append("⏸ \(pause) en pause") }
        return p.joined(separator: " · ")
    }
    private func summary(_ shown: [TimerState], _ now: Double) -> String {
        shown.map { $0.name + " " + $0.display(now) + ($0.isDueDock && !$0.ack ? ", échu" : "") }.joined(separator: ", ")
    }
}

// MARK: - Le quai

struct CrDock: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ringOn = false
    @State private var ringPhase: CGFloat = 0

    var body: some View {
        Group {
            if ctx.started { sessionDock } else { entryDock }
        }
        .frame(maxWidth: 660)
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(T.amb)
    }

    private var act: CrAct { CrAct(model: model, vs: vs, R: ctx.R) }

    // MARK: Avant la session : « Exercice » + « Démarrer la session »

    private var entryDock: some View {
        let R = ctx.R
        let crit = !Pool.list(ctx.f, .entry).isEmpty
        let base = R.exercise ? "l’exercice" : "la session"
        let label = (crit ? "Confirmé — démarrer " : "Démarrer ") + base
        let hint = CrLocal.bool("start-hint") != true
        return HStack(spacing: 10) {
            Button {
                if R.exercise { act.cancelExercise() }
                else { act.armExercise() }
            } label: {
                HStack(spacing: 6) {
                    Text("▲").aFont(TypeScale.body, .heavy)
                    Text(R.exercise ? "Annuler" : (ctx.narrow430 ? "Exo." : "Exercice")).aFont(TypeScale.item, .bold)
                }
                .foregroundStyle(T.act)
                .padding(.horizontal, 14)
                .frame(minHeight: Ctrl.xl)
                .background(R.exercise ? T.primarySoft : T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous)
                    .strokeBorder(T.act, style: StrokeStyle(lineWidth: 1.5, dash: R.exercise ? [] : [5, 4])))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(R.exercise ? "Annuler l’exercice — la session n’a pas démarré" : "Répéter en exercice — rien n’est enregistré comme soin")
            .accessibilityAddTraits(R.exercise ? .isSelected : [])

            Button { act.start() } label: {
                VStack(spacing: 2) {
                    Text(label).aFont(TypeScale.step, .heavy).lineLimit(2).multilineTextAlignment(.center)
                    if hint { Text("Lance le chrono · minuteurs prêts").aFont(TypeScale.meta, .semibold).opacity(0.85) }
                }
                .foregroundStyle(T.onPrimary)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: Ctrl.xl)
                .background(T.act, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label + (R.exercise ? " — répétition sans patient ; démarre aussi à la première action"
                                                   : " — chrono, minuteurs et journal ; démarre aussi à la première action"))
        }
        .overlay { arrivalRings }
        .onAppear {
            // A331 : trois anneaux, une fois par ouverture, fini sous les 5 s ; rien sous « réduire les animations ».
            guard !vs.arrivalPlayed, !reduceMotion else { return }
            vs.arrivalPlayed = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 800_000_000)
                ringOn = true
                withAnimation(.timingCurve(0.22, 0.61, 0.36, 1, duration: 1.3).repeatCount(3, autoreverses: false)) { ringPhase = 1 }
                try? await Task.sleep(nanoseconds: 3_900_000_000)
                ringOn = false
            }
        }
    }

    @ViewBuilder
    private var arrivalRings: some View {
        if ringOn {
            // L'anneau part du bord du quai et s'en éloigne en s'effaçant (transform + opacité seulement).
            RoundedRectangle(cornerRadius: Radius.r4, style: .continuous)
                .stroke(T.sys.opacity(0.85), lineWidth: 2)
                .scaleEffect(x: 1 + 0.04 * ringPhase, y: 1 + 0.3 * ringPhase)
                .opacity(Double(1 - ringPhase))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: En session : Fin · Tout voir · Complications · Horodater

    private var sessionDock: some View {
        let R = ctx.R
        let cxs = CrisisPure.cxAll(ctx.f)
        let here = R.nav.last ?? ""
        let showCx = !cxs.isEmpty && !(cxs.count == 1 && cxs[0].target == here)
        let n = R.events.count
        return HStack(spacing: 4) {
            key(glyph: Image(systemName: "stop.fill"), glyphColor: T.critSys, label: "Fin",
                a11y: "Terminer la session — confirmation demandée") { vs.endOpen = true }
            if ctx.hasFlow {
                sep
                allKey
            }
            if showCx {
                sep
                cxKey(cxs)
            }
            sep
            key(glyph: Image(systemName: "stopwatch"), glyphColor: T.sysInk, label: "Horodater" + (n > 0 ? " · \(n)" : ""),
                a11y: "Horodater — noter l’heure d’un geste, puis le nommer", recessed: true) { act.stamp() }
        }
        .padding(6)
        .background(T.sys, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.sysEdge, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.18), radius: 16, y: -6)
    }

    private var sep: some View { Rectangle().fill(T.sysLine).frame(width: 1, height: 28).accessibilityHidden(true) }

    private var allKey: some View {
        let away = vs.showAll
        return Button {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) { vs.showAll.toggle() }
            vs.dockSheet = .closed
        } label: {
            VStack(spacing: 2) {
                Image(systemName: away ? "arrow.uturn.backward" : "arrow.up.left.and.arrow.down.right").font(.system(size: 15, weight: .bold))
                if !ctx.narrow360 { Text(away ? "Un bloc" : "Tout voir").aFont(TypeScale.body, .heavy).lineLimit(2) }
            }
            .foregroundStyle(away ? T.onSysFill : T.sysInk2)
            .frame(maxWidth: ctx.narrow360 ? 46 : .infinity, minHeight: 50)
            .background(away ? T.okSys : Color.clear, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(away ? "Revenir au bloc en cours" : "Tout voir — la fiche entière, puis retour au bloc")
    }

    private func cxKey(_ cxs: [CrisisPure.Cx]) -> some View {
        let one = cxs.count == 1
        let open = vs.dockSheet == .cx
        return Button {
            if one { act.cxGo(cxs[0]) }
            else { vs.dockSheet = open ? .closed : .cx }
        } label: {
            VStack(spacing: 2) {
                CrBolt(size: 15)
                Text(one ? CrisisPure.cxShort(cxs[0]) : "Complications · \(cxs.count)")
                    .aFont(TypeScale.body, one ? .bold : .heavy).lineLimit(2).multilineTextAlignment(.center)
            }
            .foregroundStyle(T.warnSys)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(open ? T.sysHi : Color.clear, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(one ? "Complication : " + cxs[0].label + " — interrompt le parcours, retour prévu"
                                : "\(cxs.count) complications prévues — à tout moment")
        .accessibilityValue(one ? "" : (open ? "déplié" : "replié"))
    }

    private func key(glyph: Image, glyphColor: Color, label: String, a11y: String, recessed: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                glyph.font(.system(size: 15, weight: .bold)).foregroundStyle(glyphColor)
                Text(label).aFont(TypeScale.body, .heavy).foregroundStyle(recessed ? T.sysInk : T.sysInk2)
                    .lineLimit(2).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(recessed ? T.sys2 : Color.clear, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(a11y)
    }
}

// MARK: - Retour au bloc en cours (#blkReturn)

struct CrReturnBar: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    @Environment(AppModel.self) private var model

    var body: some View {
        let i = ctx.tipIdx
        let b = ctx.tipBlock
        let title = b.map { $0.title.isEmpty ? "le bloc en cours" : $0.title } ?? "le bloc en cours"
        let n = b.flatMap { ctx.num($0.id) }
        let need: (tot: Int, dn: Int)? = (b != nil && b!.kind != .decision) ? ctx.e.visitNeed(ctx.R, b!, seq: ctx.seq(i)) : nil
        Button { vs.pendingScroll = "!v\(i)" } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.backward").font(.system(size: 13, weight: .bold))
                Text((n.map { "\($0) · " } ?? "") + JS.prefix(title, 40)).aFont(TypeScale.body, .bold).lineLimit(1)
                Spacer(minLength: 4)
                if let need, need.tot > 0 {
                    Text("\(need.dn)/\(need.tot)").aFont(TypeScale.meta, .bold, .mono).opacity(0.75)
                }
            }
            .foregroundStyle(T.onSysFill)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: Ctrl.l)
            .background(T.okSys, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Revenir au bloc en cours — " + title)
        .transition(.opacity)
    }
}

// MARK: - Feuille « Horodater » (le repère est DÉJÀ écrit ; la feuille le nomme)

struct CrStampSheet: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let evId: String
    @Environment(AppModel.self) private var model
    @State private var text = ""
    @State private var loaded = false

    var body: some View {
        let R = ctx.R
        let ev = R.events.first { $0.id == evId }
        let t0 = R.startedAt > 0 ? R.startedAt : (R.events.first?.t ?? 0)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("⏱ REPÈRE POSÉ ·").aFont(TypeScale.cap, .heavy).foregroundStyle(T.sysInk2)
                Text("T+" + Fmt.ms(max(0, (ev?.t ?? ctx.now) - t0))).aFont(TypeScale.meta, .bold, .mono).foregroundStyle(T.sysInk)
                Text("✓ au journal").aFont(TypeScale.meta, .bold).foregroundStyle(T.okSys)
                Spacer()
                Button { vs.dockSheet = .closed } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundStyle(T.sysInk2)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Fermer")
            }
            CrCritWarn(ctx: ctx)
            TextField("", text: $text, prompt: Text("Nommer (facultatif) — déjà enregistré").foregroundColor(T.sysInk2))
                .textFieldStyle(.plain)
                .aFont(16, .semibold)
                .foregroundStyle(T.sysInk)
                .padding(.horizontal, 12)
                .frame(minHeight: 48)
                .background(T.sys2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.sysLine, lineWidth: 1))
                .accessibilityLabel("Nommer le repère")
                .onChange(of: text) { _, v in
                    guard loaded else { return }
                    CrAct(model: model, vs: vs, R: R).label(evId, v)
                }
                .onSubmit { vs.dockSheet = .closed }
            chips
            if R.events.count >= 2 { list(t0) }
        }
        .padding(.horizontal, 14).padding(.bottom, 12)
        .background(T.sys, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.sysEdge, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.35), radius: 16, y: -4)
        .onAppear {
            text = ev?.label ?? ""
            loaded = true
        }
    }

    @ViewBuilder
    private var chips: some View {
        let R = ctx.R
        let all = CrisisPure.tagAll(ctx.f, tags: model.library.tags, R: R)
        let sug = CrisisPure.tagSuggest(all, blockId: R.nav.last, n: 6, guaranteed: ["counter"])
        CrWrap(spacing: 8) {
            ForEach(Array(sug.enumerated()), id: \.offset) { _, c in
                Button {
                    CrAct(model: model, vs: vs, R: R).tag(evId, c)
                    vs.dockSheet = .closed
                } label: { chipLabel(c) }
                .buttonStyle(.plain)
                .accessibilityLabel(chipA11y(c))
            }
        }
    }

    @ViewBuilder
    private func chipLabel(_ c: CrisisPure.TagCand) -> some View {
        HStack(spacing: 6) {
            Text(Report.tagShort(c.label)).aFont(TypeScale.meta, .bold).foregroundStyle(T.sysInk).lineLimit(1)
            if c.type == "counter", let cid = c.ref["id"]?.string {
                let cur = ctx.R.counters[cid] ?? 0
                let step = Double(max(1, ctx.f.counters.first { $0.id == cid }?.step ?? 1))
                Text(crNum(cur) + " → " + crNum(cur + step)).aFont(TypeScale.cap, .heavy, .mono).foregroundStyle(T.sysInk2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(T.sys2, in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: Ctrl.l)
        .overlay(Capsule().strokeBorder(T.sysLine, lineWidth: 1))
        .contentShape(Capsule())
    }
    private func chipA11y(_ c: CrisisPure.TagCand) -> String {
        guard c.type == "counter", let cid = c.ref["id"]?.string else { return c.label }
        let cur = ctx.R.counters[cid] ?? 0
        let step = Double(max(1, ctx.f.counters.first { $0.id == cid }?.step ?? 1))
        return c.label + " — incrémenter à " + crNum(cur + step) + " et nommer ce repère"
    }

    private func list(_ t0: Double) -> some View {
        let R = ctx.R
        let labs = Report.eventLabels(R.events, R.fiche, tags: model.library.tags, extras: crExtras(R))
        return ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(R.events.enumerated()), id: \.element.id) { i, e in
                    HStack(spacing: 8) {
                        Text("T+" + Fmt.ms(max(0, e.t - t0))).aFont(TypeScale.meta, .bold, .mono).foregroundStyle(T.okSys)
                        Text(labs[i]).aFont(TypeScale.meta, e.id == evId ? .heavy : .medium).foregroundStyle(T.sysInk)
                            .strikethrough(e.isVoid).lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 160)
    }
}

/// Les objets AD HOC de la session, pour nommer leurs repères (`rtExtra`).
func crExtras(_ R: RuntimeSession) -> Report.Extras {
    Report.Extras(timers: R.orderedTimers.filter(\.adhoc).map { (id: $0.id, label: $0.label) },
                  counters: R.adhocCounters.enumerated().map { (id: $0.element.id, label: $0.element.label.isEmpty ? "Compteur \($0.offset + 1)" : $0.element.label) })
}

/// Rappel d'interruption (`dockSheetWarn`) : étapes critiques non cochées du bloc en cours.
struct CrCritWarn: View {
    let ctx: CrCtx
    var body: some View {
        let R = ctx.R
        let i = ctx.tipIdx
        if let b = ctx.tipBlock, b.kind != .decision {
            let seq = ctx.seq(i)
            let n = Graph.cleanSteps(ctx.f, b).enumerated().filter { Steps.isCrit($0.element) && !R.isChecked("\(seq):\(b.id):\($0.offset)") }.count
            if n > 0 {
                Text("⚠ \(n) " + (n > 1 ? "étapes critiques" : "étape critique") + " en attente dans « " + (b.title.isEmpty ? "Étapes" : b.title) + " »")
                    .aFont(TypeScale.cap, .bold)
                    .foregroundStyle(T.critSys)
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .overlay(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).strokeBorder(T.critLine, lineWidth: 1))
            }
        }
    }
}

// MARK: - Feuille « Complications » (≥ 2 déclarées)

struct CrCxSheet: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    @Environment(AppModel.self) private var model

    var body: some View {
        let cxs = CrisisPure.cxAll(ctx.f)
        let here = ctx.R.nav.last ?? ""
        let curTitle = ctx.tipBlock.map { $0.title.isEmpty ? "le parcours" : $0.title } ?? "le parcours"
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                CrBolt(size: 13)
                Text("COMPLICATIONS PRÉVUES ICI · \(cxs.count)").aFont(TypeScale.cap, .heavy).foregroundStyle(T.critSys)
                Spacer()
                Button { vs.dockSheet = .closed } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundStyle(T.sysInk2).frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Fermer")
            }
            CrCritWarn(ctx: ctx).padding(.bottom, 6)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(cxs, id: \.self) { c in
                        let inIt = c.isBlock && c.target == here
                        Button { CrAct(model: model, vs: vs, R: ctx.R).cxGo(c) } label: {
                            row(c, inIt: inIt, curTitle: curTitle)
                        }
                        .buttonStyle(.plain)
                        .disabled(inIt)
                    }
                }
            }
            .frame(maxHeight: 320)
        }
        .padding(.horizontal, 14).padding(.bottom, 10)
        .background(T.sys, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.sysEdge, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.35), radius: 16, y: -4)
    }

    private func row(_ c: CrisisPure.Cx, inIt: Bool, curTitle: String) -> some View {
        let dest: String
        if inIt { dest = "vous y êtes" }
        else if c.isBlock {
            let t = ctx.block(c.target)?.title ?? ""
            dest = "→ " + (t.isEmpty ? "Complication" : t) + " · retour ↩ " + curTitle
        } else {
            dest = "→ " + (externalTitle(c.target) ?? "aide introuvable") + " ↗"
        }
        return VStack(spacing: 0) {
            Rectangle().fill(T.sysLine).frame(height: 1)
            CrWrap(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(HTML.stripBold(c.label)).aFont(TypeScale.body, .bold).foregroundStyle(T.sysInk)
                    Text(inIt ? "vous y êtes" : (c.isBlock ? "interrompt le parcours — retour prévu" : "ouvre une autre aide"))
                        .aFont(TypeScale.cap, .semibold).foregroundStyle(T.sysInk2)
                }
                Text(dest).aFont(TypeScale.cap, .bold).foregroundStyle(T.sysInk2)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .contentShape(Rectangle())
            .opacity(inIt ? 0.6 : 1)
        }
    }
    private func externalTitle(_ id: String) -> String? {
        model.fiches.first { $0.id == id }?.title ?? model.references.first { $0.id == id }?.title
    }
}
