import SwiftUI
import AidesCore

// LA CAPSULE (état, en haut) ET LE QUAI (commandes, en bas) — les deux COMMANDES FLOTTANTES du
// mode crise, en Liquid Glass « regular » (jamais « clear ») ; le contenu défile dessous. Port de
// `updateRtStrip`, `#sessionDock`, `#dockSheet`, `#blkReturn`. L'alarme y est portée par une
// TEINTE ambre + « △ » + le mot (règle 8 : une couleur n'est jamais seule).

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

    struct Variant: Hashable {
        var n: Int
        var counter: Bool
        var recall: Bool
        var chevron: Bool
    }

    var body: some View {
        let phone = ctx.wc == .phone
        let shown = shownTimers()
        GlassEffectContainer(spacing: 6) {
            HStack(spacing: 6) {
                Button { tap(phone) } label: { globalSegment }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .accessibilityLabel(globalA11y + " — minuteurs en cours, afficher le panneau")
                if phone {
                    ViewThatFits(in: .horizontal) {
                        ForEach(variants(shown), id: \.self) { v in row(shown, v, phone: true) }
                    }
                } else {
                    row(shown, Variant(n: min(2, shown.count), counter: false, recall: shown.isEmpty, chevron: false), phone: false)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: ctx.narrow360 ? 44 : 52, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private func tap(_ phone: Bool) {
        if phone { vs.sheet = (vs.sheet == .panel) ? nil : .panel }
        else { vs.railScroll = "timers-\(Int(ctx.now))" }
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
    private func row(_ shown: [TimerState], _ v: Variant, phone: Bool) -> some View {
        let R = ctx.R
        let visible = Array(shown.prefix(v.n))
        let dueHidden = shown.dropFirst(v.n).filter { $0.isDueDock && !$0.ack }.count
        HStack(spacing: 6) {
            ForEach(visible, id: \.id) { t in timerTile(t, phone: phone) }
            if dueHidden > 0 {
                Text("△ +\(dueHidden)").aFont(TypeScale.meta, .heavy).foregroundStyle(T.onSysFill)
                    .padding(.horizontal, 10).frame(minHeight: 36)
                    .glassEffect(.regular.tint(T.warnSys), in: .capsule)
                    .accessibilityLabel("\(dueHidden) autre(s) minuteur(s) échu(s)")
            }
            if v.counter, let c = ctx.f.counters.first {
                counterTile(c, R.counters[c.id] ?? 0, phone: phone)
            }
            Spacer(minLength: 0)
            if v.chevron {
                Button { tap(phone) } label: {
                    HStack(spacing: 4) {
                        if v.recall && v.n == 0 {
                            let r = recallText()
                            if !r.isEmpty { Text(r).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2).lineLimit(1) }
                        }
                        Image(systemName: vs.sheet == .panel ? "chevron.up" : "chevron.down").aFont(TypeScale.body, .bold)
                            .foregroundStyle(T.ink2)
                    }
                    .padding(.horizontal, 12)
                    .frame(minWidth: Ctrl.l, minHeight: Ctrl.l)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .capsule)
                .fixedSize()
                .accessibilityLabel("Minuteurs en cours — afficher le panneau")
            }
        }
    }

    private var globalA11y: String {
        let R = ctx.R
        return either(R.exercise, "Exercice", "Session") + " — durée " + (R.startedAt > 0 ? Fmt.ms(ctx.now - R.startedAt) : "inconnue")
    }

    private var globalSegment: some View {
        let R = ctx.R
        return VStack(alignment: .leading, spacing: 0) {
            Text(R.exercise ? "▲ EXERCICE" : "● SESSION")
                .aFont(TypeScale.body, .heavy)
                .foregroundStyle(R.exercise ? T.act : T.ok)
                .lineLimit(1)
            Text(R.startedAt > 0 ? Fmt.ms(ctx.now - R.startedAt) : "—")
                .aFont(TypeScale.val, .bold, .mono)
                .foregroundStyle(T.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 14).padding(.vertical, 4)
        .frame(minWidth: 92, minHeight: ctx.narrow360 ? 44 : 52, alignment: .leading)
        .contentShape(Capsule())
    }

    private func timerTile(_ t: TimerState, phone: Bool) -> some View {
        let now = ctx.now
        let due = t.isDueDock && !t.ack
        let soon = !due && CrisisPure.isSoon(t, now)
        let ink: Color = due ? T.onSysFill : (soon ? T.warn : T.ink)
        // Pulsation du MOT de l'échu (1 → 0,55 → 1 en 2 s), calculée depuis l'horloge ; rien sous « réduire les animations ».
        let phase = now.truncatingRemainder(dividingBy: 2000) / 2000
        let pulse = (due && !reduceMotion) ? 1 - 0.45 * sin(Double.pi * phase) : 1
        let frac = t.type == .interval && t.period > 0 ? max(0, min(1, t.remaining(now) / t.period)) : 1
        let glass: Glass = due ? Glass.regular.tint(T.warnSys).interactive() : Glass.regular.interactive()
        return Button { tap(phone) } label: {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(((due || soon) ? "△ " : "") + CrisisPure.tmShort(t).uppercased())
                        .aFont(TypeScale.body, .heavy).foregroundStyle(ink).lineLimit(1)
                    if due { Text("ÉCHU").aFont(TypeScale.cap, .heavy).foregroundStyle(ink).opacity(pulse) }
                }
                Text(t.display(now)).aFont(TypeScale.step, .bold, .mono).foregroundStyle(ink).lineLimit(1)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(T.line)
                        Capsule().fill(due ? T.onSysFill : T.ink2).frame(width: g.size.width * frac)
                    }
                }
                .frame(height: 3)
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            .frame(minWidth: 96, minHeight: ctx.narrow360 ? 44 : 52, alignment: .leading)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(glass, in: .capsule)
        .accessibilityLabel(t.name + " : " + t.display(now) + (due ? ", échu" : (soon ? ", bientôt échu" : "")))
        .accessibilityHint("Afficher le panneau des minuteurs")
    }

    private func counterTile(_ c: CounterDef, _ v: Double, phone: Bool) -> some View {
        Button { tap(phone) } label: {
            VStack(alignment: .leading, spacing: 1) {
                Text(CrisisPure.cnShort(c).uppercased()).aFont(TypeScale.body, .heavy).foregroundStyle(T.ink).lineLimit(1)
                Text(crNum(v)).aFont(TypeScale.step, .bold, .mono).foregroundStyle(T.ink)
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            .frame(minWidth: 84, minHeight: ctx.narrow360 ? 44 : 52, alignment: .leading)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
        .accessibilityLabel((c.label.isEmpty ? "Compteur" : c.label) + " : " + crNum(v))
    }

    /// « n minuteurs · k compteurs · ⏸ p en pause » — seulement ce qui n'est pas montré.
    private func recallText() -> String {
        let R = ctx.R
        let nT = R.orderedTimers.count
        let nC = ctx.f.counters.count + R.adhocCounters.count
        let pause = R.orderedTimers.filter { $0.type == .interval && !$0.running && !$0.isDueDock && $0.elapsedMs > 0 }.count
        var p: [String] = []
        if nT > 0 { p.append("\(nT) minuteur" + either(nT > 1, "s", "")) }
        if nC > 0 { p.append("\(nC) compteur" + either(nC > 1, "s", "")) }
        if pause > 0 { p.append("⏸ \(pause) en pause") }
        return p.joined(separator: " · ")
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
        if ctx.started { sessionDock } else { entryDock }
    }

    private var act: CrAct { CrAct(model: model, vs: vs, R: ctx.R) }

    // MARK: Avant la session : « Exercice » + « Démarrer la session » (la seule action proéminente)

    private var entryDock: some View {
        let R = ctx.R
        let crit = !Pool.list(ctx.f, .entry).isEmpty
        let base = R.exercise ? "l’exercice" : "la session"
        let label = either(crit, "Confirmé — démarrer ", "Démarrer ") + base
        let hint = CrLocal.bool("start-hint") != true
        return GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    if R.exercise { act.cancelExercise() } else { act.armExercise() }
                } label: {
                    HStack(spacing: 6) {
                        Text("▲").aFont(TypeScale.body, .heavy)
                        Text(R.exercise ? "Annuler" : (ctx.narrow430 ? "Exo." : "Exercice")).aFont(TypeScale.item, .bold)
                    }
                    .foregroundStyle(T.act)
                    .padding(.horizontal, 8)
                    .frame(minHeight: Ctrl.xl)
                }
                .buttonStyle(.glass)
                .accessibilityLabel(R.exercise ? "Annuler l’exercice — la session n’a pas démarré" : "Répéter en exercice — rien n’est enregistré comme soin")
                .accessibilityAddTraits(R.exercise ? .isSelected : [])

                Button { act.start() } label: {
                    VStack(spacing: 1) {
                        Text(label).aFont(TypeScale.step, .heavy).lineLimit(2).multilineTextAlignment(.center)
                        if hint { Text("Lance le chrono · minuteurs prêts").aFont(TypeScale.meta, .semibold).opacity(0.85) }
                    }
                    .frame(maxWidth: .infinity, minHeight: Ctrl.xl)
                }
                .buttonStyle(.glassProminent)
                .tint(T.act)
                .accessibilityLabel(label + (R.exercise ? " — répétition sans patient ; démarre aussi à la première action"
                                                       : " — chrono, minuteurs et journal ; démarre aussi à la première action"))
            }
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
            Capsule()
                .stroke(T.ink.opacity(0.7), lineWidth: 2)
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
        return GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                key(glyph: "stop.fill", glyphColor: T.crit, label: "Fin", a11y: "Terminer la session — confirmation demandée") {
                    vs.endOpen = true
                }
                if ctx.hasFlow { allKey }
                if showCx { cxKey(cxs) }
                key(glyph: "stopwatch", glyphColor: T.ink, label: "Horodater" + either(n > 0, " · \(n)", ""),
                    a11y: "Horodater — noter l’heure d’un geste, puis le nommer") { act.stamp() }
            }
        }
    }

    /// « Tout voir » / « Un bloc » : quand l'écran n'est PAS au format d'origine, la touche se
    /// teinte en vert — « ceci vous ramène ».
    @ViewBuilder
    private var allKey: some View {
        let page = vs.showAll
        let away = page != (model.readMode == "static")
        let b = Button {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) { vs.showAll.toggle() }
        } label: {
            keyLabel(glyph: page ? "arrow.uturn.backward" : "arrow.up.left.and.arrow.down.right",
                     glyphColor: away ? T.onPrimary : T.ink, label: ctx.narrow360 ? nil : (page ? "Un bloc" : "Tout voir"),
                     ink: away ? T.onPrimary : T.ink)
        }
        .accessibilityLabel(page ? (away ? "Revenir au bloc en cours" : "Voir un bloc à la fois")
                                 : (away ? "Revenir à la fiche entière" : "Tout voir — la fiche entière, puis retour au bloc"))
        if away { b.buttonStyle(.glassProminent).tint(T.ok) } else { b.buttonStyle(.glass) }
    }

    private func cxKey(_ cxs: [CrisisPure.Cx]) -> some View {
        let one = cxs.count == 1
        let open = vs.sheet == .cx
        return Button {
            if one { act.cxGo(cxs[0]) }
            else { vs.sheet = open ? nil : .cx }
        } label: {
            VStack(spacing: 2) {
                CrBolt(size: 15)
                Text(one ? CrisisPure.cxShort(cxs[0]) : "Complications · \(cxs.count)")
                    // A403 : même règle que les autres touches — une ligne, jamais coupée dans un mot.
                    .aFont(TypeScale.body, one ? .bold : .heavy).foregroundStyle(T.warn)
                    .lineLimit(1).minimumScaleFactor(0.75).allowsTightening(true)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.glass)
        .accessibilityLabel(one ? "Complication : " + cxs[0].label + " — interrompt le parcours, retour prévu"
                                : "\(cxs.count) complications prévues — à tout moment")
    }

    private func keyLabel(glyph: String, glyphColor: Color, label: String?, ink: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: glyph).aFont(TypeScale.item, .bold).foregroundStyle(glyphColor)
            if let label {
                // A403 : libellés du quai à 13,5, sur UNE ligne (jamais coupés au milieu d'un mot :
                // « Horodat/er ») — le texte se resserre plutôt que de passer à la ligne.
                Text(label).aFont(13.5, .heavy).foregroundStyle(ink).lineLimit(1)
                    .minimumScaleFactor(0.75).allowsTightening(true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
    }

    private func key(glyph: String, glyphColor: Color, label: String, a11y: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { keyLabel(glyph: glyph, glyphColor: glyphColor, label: label, ink: T.ink) }
            .buttonStyle(.glass)
            .accessibilityLabel(a11y)
    }
}

// MARK: - Retour au bloc en cours (#blkReturn) — « ceci vous ramène » : verre teinté vert

struct CrReturnBar: View {
    let ctx: CrCtx
    let vs: CrisisViewState

    var body: some View {
        let i = ctx.tipIdx
        let b = ctx.tipBlock
        let title = b.map { $0.title.isEmpty ? "le bloc en cours" : $0.title } ?? "le bloc en cours"
        let n = b.flatMap { ctx.num($0.id) }
        let need: (tot: Int, dn: Int)? = (b != nil && b!.kind != .decision) ? ctx.e.visitNeed(ctx.R, b!, seq: ctx.seq(i)) : nil
        Button { vs.pendingScroll = "!v\(i)" } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.backward").aFont(TypeScale.body, .bold)
                Text((n.map { "\($0) · " } ?? "") + JS.prefix(title, 40)).aFont(TypeScale.body, .bold).lineLimit(1)
                Spacer(minLength: 4)
                if let need, need.tot > 0 {
                    Text("\(need.dn)/\(need.tot)").aFont(TypeScale.meta, .bold, .mono).opacity(0.75)
                }
            }
            .frame(maxWidth: .infinity, minHeight: Ctrl.l - 8)
        }
        .buttonStyle(.glassProminent)
        .tint(T.ok)
        .accessibilityLabel("Revenir au bloc en cours — " + title)
        .transition(.opacity)
    }
}

// MARK: - Feuille « Horodater » (le repère est DÉJÀ écrit ; la feuille le nomme)

struct CrStampSheet: View {
    let R: RuntimeSession
    let vs: CrisisViewState
    let evId: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var loaded = false

    var body: some View {
        let _ = model.rev
        let ev = R.events.first { $0.id == evId }
        let t0 = R.startedAt > 0 ? R.startedAt : (R.events.first?.t ?? 0)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("⏱ REPÈRE POSÉ ·").aFont(TypeScale.cap, .heavy).foregroundStyle(T.ink2)
                        Text("T+" + Fmt.ms(max(0, (ev?.t ?? JS.now()) - t0))).aFont(TypeScale.meta, .bold, .mono).foregroundStyle(T.ink)
                        Text("✓ au journal").aFont(TypeScale.meta, .bold).foregroundStyle(T.ok)
                    }
                    CrCritWarn(R: R)
                    TextField("Nommer (facultatif) — déjà enregistré", text: $text)
                        .textFieldStyle(.plain)
                        .aFont(16, .semibold)  // design: champ tactile, plancher 16 (règle 9, exemption de check-type)
                        .foregroundStyle(T.ink)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 48)
                        .background(T.amb2, in: Capsule())
                        .accessibilityLabel("Nommer le repère")
                        .onChange(of: text) { _, v in
                            guard loaded else { return }
                            CrAct(model: model, vs: vs, R: R).label(evId, v)
                        }
                        .onSubmit { dismiss() }
                    chips
                    if R.events.count >= 2 { list(t0) }
                }
                .padding(16)
            }
            .navigationTitle("Horodater")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Image(systemName: "checkmark") }
                        .accessibilityLabel("Terminer")
                }
            }
        }
        .onAppear {
            text = ev?.label ?? ""
            loaded = true
        }
    }

    @ViewBuilder
    private var chips: some View {
        let sug = CrisisPure.tagSuggest(R.fiche, tags: crTags(model), R: R, blockId: R.nav.last, n: 6, guaranteed: ["counter"])
        CrWrap(spacing: 8) {
            ForEach(Array(sug.enumerated()), id: \.offset) { _, c in
                Button {
                    CrAct(model: model, vs: vs, R: R).tag(evId, c)
                    dismiss()
                } label: { chipLabel(c) }
                .buttonStyle(.plain)
                .accessibilityLabel(chipA11y(c))
            }
        }
    }

    @ViewBuilder
    private func chipLabel(_ c: CrisisPure.TagCand) -> some View {
        HStack(spacing: 6) {
            Text(Live.tagShort(c.label)).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink).lineLimit(1)
            if c.type == "counter", let cid = c.ref["id"]?.string {
                let cur = R.counters[cid] ?? 0
                let step = Double(max(1, R.fiche.counters.first { $0.id == cid }?.step ?? 1))
                Text(crNum(cur) + " → " + crNum(cur + step)).aFont(TypeScale.cap, .heavy, .mono).foregroundStyle(T.ink2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(T.amb2, in: Capsule())
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: Ctrl.l)
        .background(T.work, in: Capsule())
        .overlay(Capsule().strokeBorder(T.ctlLine, lineWidth: 1))
        .contentShape(Capsule())
    }
    private func chipA11y(_ c: CrisisPure.TagCand) -> String {
        guard c.type == "counter", let cid = c.ref["id"]?.string else { return c.label }
        let cur = R.counters[cid] ?? 0
        let step = Double(max(1, R.fiche.counters.first { $0.id == cid }?.step ?? 1))
        return c.label + " — incrémenter à " + crNum(cur + step) + " et nommer ce repère"
    }

    private func list(_ t0: Double) -> some View {
        let labs = Report.eventLabels(R.events, R.fiche, tags: model.library.tags, extras: crExtras(R))
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(R.events.enumerated()), id: \.element.id) { i, e in
                HStack(spacing: 8) {
                    Text("T+" + Fmt.ms(max(0, e.t - t0))).aFont(TypeScale.meta, .bold, .mono).foregroundStyle(T.ok)
                    Text(i < labs.count ? labs[i] : "").aFont(TypeScale.meta, e.id == evId ? .heavy : .medium).foregroundStyle(T.ink)
                        .strikethrough(e.isVoid).lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

/// Le vocabulaire personnel du journal (préférence `ac-tags` de l'espace, synchronisée).
@MainActor
func crTags(_ m: AppModel) -> JSON? { m.library.space.prefs["ac-tags"] }

/// Les objets AD HOC de la session, pour nommer leurs repères (`rtExtra`).
func crExtras(_ R: RuntimeSession) -> Report.Extras {
    Report.Extras(timers: R.orderedTimers.filter(\.adhoc).map { (id: $0.id, label: $0.label) },
                  counters: R.adhocCounters.enumerated().map { (id: $0.element.id, label: $0.element.label.isEmpty ? "Compteur \($0.offset + 1)" : $0.element.label) })
}

/// Rappel d'interruption (`dockSheetWarn`) : étapes critiques non cochées du bloc en cours.
struct CrCritWarn: View {
    let R: RuntimeSession
    var body: some View {
        let i = R.nav.count - 1
        if let id = R.nav.last, let b = R.fiche.blocks.first(where: { $0.id == id }), b.kind != .decision {
            let seq = i < R.navSeq.count && R.navSeq[i] != 0 ? R.navSeq[i] : 1
            let n = Graph.cleanSteps(R.fiche, b).enumerated().filter { Steps.isCrit($0.element) && !R.isChecked("\(seq):\(b.id):\($0.offset)") }.count
            if n > 0 {
                Text("⚠ \(n) " + either(n > 1, "étapes critiques", "étape critique") + " en attente dans « " + (b.title.isEmpty ? "Étapes" : b.title) + " »")
                    .aFont(TypeScale.cap, .bold)
                    .foregroundStyle(T.crit)
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .overlay(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).strokeBorder(T.critLine, lineWidth: 1))
            }
        }
    }
}

// MARK: - Feuille « Complications » (≥ 2 déclarées)

struct CrCxSheet: View {
    let R: RuntimeSession
    let vs: CrisisViewState
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let _ = model.rev
        let cxs = CrisisPure.cxAll(R.fiche)
        let here = R.nav.last ?? ""
        let curTitle = R.fiche.blocks.first { $0.id == here }.map { $0.title.isEmpty ? "le parcours" : $0.title } ?? "le parcours"
        NavigationStack {
            List {
                Section {
                    CrCritWarn(R: R)
                    ForEach(cxs, id: \.self) { c in
                        let inIt = c.isBlock && c.target == here
                        Button {
                            dismiss()
                            CrAct(model: model, vs: vs, R: R).cxGo(c)
                        } label: { row(c, inIt: inIt, curTitle: curTitle) }
                        .disabled(inIt)
                    }
                } header: {
                    HStack(spacing: 6) {
                        CrBolt(size: 12)
                        Text("Complications prévues ici · \(cxs.count)")
                    }
                }
            }
            .navigationTitle("Complications")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Fermer")
                }
            }
        }
    }

    private func row(_ c: CrisisPure.Cx, inIt: Bool, curTitle: String) -> some View {
        let dest: String
        if inIt { dest = "vous y êtes" }
        else if c.isBlock {
            let t = R.fiche.blocks.first { $0.id == c.target }?.title ?? ""
            dest = "→ " + (t.isEmpty ? "Complication" : t) + " · retour ↩ " + curTitle
        } else {
            dest = "→ " + (externalTitle(c.target) ?? "aide introuvable") + " ↗"
        }
        return VStack(alignment: .leading, spacing: 2) {
            Text(HTML.stripBold(c.label)).aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
            Text(inIt ? "vous y êtes" : (c.isBlock ? "interrompt le parcours — retour prévu" : "ouvre une autre aide"))
                .aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink2)
            Text(dest).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .contentShape(Rectangle())
    }
    private func externalTitle(_ id: String) -> String? {
        model.fiches.first { $0.id == id }?.title ?? model.references.first { $0.id == id }?.title
    }
}
