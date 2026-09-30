import SwiftUI
import AidesCore

// LE PANNEAU DES INSTRUMENTS — minuteurs · compteurs · jalons · journal des actions · réglages
// (`runtimePanel` + `timekeeperPanel`). Deux présentations d'un même contenu : le VOLET du
// téléphone (matière système, suspendu sous la capsule) et le RAIL dès 780 (matière travail).

/// Encres selon la matière (système sombre au volet, travail clair au rail).
struct CrPal {
    let sys: Bool
    var ink: Color { sys ? T.sysInk : T.ink }
    var ink2: Color { sys ? T.sysInk2 : T.ink2 }
    var card: Color { sys ? T.sys2 : T.work }
    var line: Color { sys ? T.sysLine : T.line }
    var warn: Color { sys ? T.warnSys : T.warn }
    var warnBg: Color { sys ? T.warnSysBg : T.warnSoft }
    var warnLine: Color { sys ? T.warnSys : T.warnLine }
    var run: Color { sys ? T.sysInk : T.act }
    var ok: Color { sys ? T.okSys : T.ok }
    var btn: Color { sys ? T.sysHi : T.amb2 }
    var ctl: Color { sys ? T.ctlSys : T.ctlLine }
}

/// En-tête de famille : « MINUTEURS [n] ».
struct CrFamHead: View {
    let title: String
    var count: Int = 0
    let pal: CrPal
    var body: some View {
        HStack(spacing: 6) {
            Text(title.uppercased()).aFont(TypeScale.cap, .heavy).tracking(0.8).foregroundStyle(pal.ink2)
            if count > 1 {
                Text("\(count)").aFont(TypeScale.meta, .bold, .mono).foregroundStyle(pal.ink2)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(pal.btn, in: Capsule())
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Minuteurs

struct CrTimersSection: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let pal: CrPal
    var compact = false
    @Environment(AppModel.self) private var model

    var body: some View {
        let R = ctx.R
        let now = ctx.now
        let listed = R.orderedTimers.filter { !$0.adhoc }
        let ordered = liveOrder(listed, now)
        let adhoc = R.orderedTimers.filter(\.adhoc)
        let cols = compact ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 160), spacing: 10)]
        VStack(alignment: .leading, spacing: 10) {
            if !ordered.isEmpty {
                LazyVGrid(columns: cols, alignment: .leading, spacing: 10) {
                    ForEach(ordered, id: \.id) { t in
                        CrTimerCard(ctx: ctx, vs: vs, t: t, pal: pal, compact: compact)
                    }
                }
                .animation(.easeOut(duration: 0.18), value: ordered.map(\.id))
            }
            ForEach(Array(adhoc.enumerated()), id: \.element.id) { i, t in
                CrAdhocTimerRow(ctx: ctx, vs: vs, t: t, rank: i + 1, pal: pal)
            }
        }
    }

    /// Tri vivant (`tmLiveOrder`), SUSPENDU 1,2 s après un geste sur un minuteur (rien ne bouge sous le doigt).
    private func liveOrder(_ list: [TimerState], _ now: Double) -> [TimerState] {
        if now < vs.tmHoldUntil, !vs.tmFrozen.isEmpty {
            let by = Dictionary(list.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let kept = vs.tmFrozen.compactMap { by[$0] }
            let rest = list.filter { !vs.tmFrozen.contains($0.id) }
            return kept + rest
        }
        let o = CrisisPure.tmLiveOrder(list, now: now)
        let ids = o.map(\.id)
        if vs.tmFrozen != ids {
            DispatchQueue.main.async { vs.tmFrozen = ids }
        }
        return o
    }
}

struct CrTimerCard: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let t: TimerState
    let pal: CrPal
    var compact = false
    @Environment(AppModel.self) private var model

    var body: some View {
        let now = ctx.now
        let due = t.isDue
        let soon = CrisisPure.isSoon(t, now)
        let open = !compact || due || vs.railTimerOpen.contains(t.id)
        let color: Color = due ? pal.warn : (t.running ? pal.run : (t.isPaused ? pal.ink2 : pal.ink))
        let parts = Fmt.labelParts(t.label)
        let flashing = vs.flashTimer == t.id
        VStack(alignment: .leading, spacing: 6) {
            Button {
                guard compact, !due else { return }
                if vs.railTimerOpen.contains(t.id) { vs.railTimerOpen.remove(t.id) } else { vs.railTimerOpen.insert(t.id) }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text((soon && !due ? "△ " : "") + t.stateLabel + (soon && !due ? " — bientôt échu" : ""))
                        .aFont(compact ? TypeScale.cap : TypeScale.body, compact ? .bold : .semibold)
                        .foregroundStyle(compact ? pal.ink2 : color)
                        .lineLimit(compact ? 1 : 2)
                    if !compact && !parts.meta.isEmpty {
                        Text(parts.meta).aFont(TypeScale.meta, .medium).foregroundStyle(pal.ink2)
                    }
                    Text(t.display(now))
                        .aFont(compact ? TypeScale.step : (pal.sys ? TypeScale.stepL : TypeScale.val), .bold, .mono)
                        .foregroundStyle(color)
                        .accessibilityLabel(t.name + " : " + t.display(now))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if !compact { natureLine(now) }
            if t.isPaused && t.stoppedAt > 0 {
                Text("△ arrêté depuis " + Fmt.ms(now - t.stoppedAt) + (t.stopClosed ? " — application fermée, le temps n’a pas été rattrapé" : ""))
                    .aFont(TypeScale.cap, .semibold).foregroundStyle(pal.warn)
            }
            if open { controls(due: due) }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: compact ? 0 : 80, alignment: .leading)
        .background(flashing ? T.warnSys.opacity(0.5) : (due ? pal.warnBg : pal.card), in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(due ? pal.warnLine : pal.line, lineWidth: due ? 1.5 : 1))
        .animation(.easeInOut(duration: 0.25), value: flashing)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(t.name + (soon && !due ? " — bientôt échu" : ""))
    }

    @ViewBuilder
    private func natureLine(_ now: Double) -> some View {
        if t.type == .interval {
            let frac = t.period > 0 ? max(0, min(1, t.remaining(now) / t.period)) : 1
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(pal.line)
                    Capsule().fill(t.isDue ? pal.warnLine : (t.running ? pal.run : pal.ink2)).frame(width: g.size.width * frac)
                }
            }
            .frame(height: 4)
            .accessibilityHidden(true)
            if t.cycles > 0 || t.autoloop {
                Text("Cycles : " + crNum(t.cycles)).aFont(TypeScale.meta, .medium).foregroundStyle(pal.ink2)
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "stopwatch").font(.system(size: 11, weight: .bold))
                Text("Chronomètre · le temps monte").aFont(TypeScale.meta, .medium)
            }
            .foregroundStyle(pal.ink2)
        }
    }

    @ViewBuilder
    private func controls(due: Bool) -> some View {
        let act = CrAct(model: model, vs: vs, R: ctx.R)
        HStack(spacing: 8) {
            if due && !t.ack {
                Button { act.ack(t.id) } label: {
                    Text("✓ Vu").aFont(TypeScale.body, .heavy).foregroundStyle(pal.ink)
                        .padding(.horizontal, 12).frame(minHeight: Ctrl.l)
                        .background(pal.btn, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Acquitter l’alarme — " + t.name + " ; le minuteur reste échu, seul le bandeau se tait")
            }
            Button { act.toggleTimer(t.id) } label: {
                HStack(spacing: 6) {
                    Image(systemName: t.running ? "pause.fill" : "play.fill").font(.system(size: 13, weight: .bold))
                    Text(t.buttonLabel).aFont(TypeScale.body, .heavy)
                }
                .foregroundStyle(pal.ink)
                .padding(.horizontal, 12).frame(maxWidth: .infinity, minHeight: Ctrl.l)
                .background(pal.btn, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(t.buttonLabel + " — " + t.name)
            if !(compact && due) {
                HoldButton(label: "↺ " + (t.type == .interval ? Fmt.ms(t.period) : "00:00") + " · maintenir", ms: 800, kind: .secondary, height: Ctrl.l) {
                    act.resetTimer(t.id)
                }
                .disabled(t.running)
                .opacity(t.running ? 0.45 : 1)
                .accessibilityLabel("Remettre à zéro — " + t.name)
                .help("Maintenir pour remettre à zéro (↺ " + (t.type == .interval ? Fmt.ms(t.period) : "00:00") + ")")
            }
        }
    }
}

/// Minuteur AD HOC (« ＋ Minuteur ») : une rangée compacte, nommable, relançable, supprimable.
struct CrAdhocTimerRow: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let t: TimerState
    let rank: Int
    let pal: CrPal
    @Environment(AppModel.self) private var model
    @State private var editing = false
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var b = vs
        let act = CrAct(model: model, vs: vs, R: ctx.R)
        let name = t.label.isEmpty ? "Minuteur \(rank)" : t.label
        let due = t.isDueDock && !t.ack
        HStack(spacing: 6) {
            if editing {
                TextField("Nom du minuteur", text: $text)
                    .textFieldStyle(.plain)
                    .aFont(16, .semibold)
                    .foregroundStyle(pal.ink)
                    .focused($focused)
                    .onSubmit { commit(act) }
                    .onChange(of: focused) { _, f in if !f && editing { commit(act) } }
                    .accessibilityLabel("Nom du minuteur")
            } else {
                Text((due ? "■ " : "") + name).aFont(TypeScale.body, .bold).foregroundStyle(due ? pal.warn : pal.ink).lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(t.display(ctx.now)).aFont(TypeScale.item, .bold, .mono).foregroundStyle(due ? pal.warn : (t.running ? pal.run : pal.ink2))
            iconBtn("pencil", "Nommer — " + name) { text = t.label; editing = true; focused = true }
            iconBtn("arrow.counterclockwise", "Relancer — " + name) { act.restartAdhoc(t.id) }
                .help("Relancer (" + Fmt.ms(t.period) + ")")
            iconBtn("xmark", "Supprimer — " + name) {
                if t.running { vs.confirmDeleteTimer = t.id } else { act.removeTimer(t.id) }
            }
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 48)
        .background(due ? pal.warnBg : pal.card, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
        .confirmationDialog("Ce minuteur tourne encore. Le supprimer ?", isPresented: Binding(
            get: { b.confirmDeleteTimer == t.id }, set: { if !$0 { b.confirmDeleteTimer = nil } }), titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) { act.removeTimer(t.id); vs.confirmDeleteTimer = nil }
            Button("Annuler", role: .cancel) { vs.confirmDeleteTimer = nil }
        }
    }
    private func commit(_ act: CrAct) {
        editing = false
        if text != t.label { act.renameTimer(t.id, text) }
    }
    private func iconBtn(_ sf: String, _ a11y: String, _ go: @escaping () -> Void) -> some View {
        Button(action: go) {
            Image(systemName: sf).font(.system(size: 13, weight: .bold)).foregroundStyle(pal.ink2)
                .frame(width: Ctrl.l, height: Ctrl.l).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(a11y)
    }
}

/// « ＋ Minuteur » → « CHOISIR LA DURÉE » 01:00 · 02:00 · 03:00 · 05:00 ; « ＋ Compteur ».
struct CrAddRow: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let pal: CrPal
    var showCounter = true
    var showTimer = true
    @Environment(AppModel.self) private var model

    var body: some View {
        let act = CrAct(model: model, vs: vs, R: ctx.R)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if showTimer {
                    dashed("＋ Minuteur") { vs.tmAddOpen.toggle() }
                        .accessibilityHint("Ajouter un minuteur pour cette session — la durée se choisit ensuite")
                        .accessibilityValue(vs.tmAddOpen ? "déplié" : "replié")
                }
                if showCounter && ctx.R.adhocCounters.count < SessionEngine.maxAdhocCounters {
                    dashed("＋ Compteur") { act.addCounter() }
                        .accessibilityHint("Ajouter un compteur pour cette session — créé à 1")
                }
            }
            if vs.tmAddOpen && showTimer {
                Text("CHOISIR LA DURÉE").aFont(TypeScale.cap, .heavy).tracking(0.8).foregroundStyle(pal.ink2)
                HStack(spacing: 8) {
                    ForEach(SessionEngine.adhocDurations, id: \.self) { sec in
                        Button { act.addTimer(sec) } label: {
                            Text(Fmt.ms(Double(sec) * 1000)).aFont(TypeScale.body, .bold, .mono).foregroundStyle(pal.ink)
                                .frame(maxWidth: .infinity, minHeight: Ctrl.l)
                                .background(pal.btn, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Minuteur de " + Fmt.dur(sec))
                    }
                }
            }
        }
    }
    private func dashed(_ label: String, _ go: @escaping () -> Void) -> some View {
        Button(action: go) {
            Text(label).aFont(TypeScale.meta, .bold).foregroundStyle(pal.sys ? T.sysInk : T.act)
                .frame(maxWidth: .infinity, minHeight: Ctrl.l)
                .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous)
                    .strokeBorder(pal.sys ? T.sysInk2 : T.act, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compteurs

struct CrCountersSection: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let pal: CrPal
    var compact = false
    var body: some View {
        let R = ctx.R
        let cols = compact ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 150), spacing: 10)]
        LazyVGrid(columns: cols, alignment: .leading, spacing: 10) {
            ForEach(ctx.f.counters, id: \.id) { c in
                CrCounterCard(ctx: ctx, vs: vs, id: c.id, def: c, adhocRank: nil, pal: pal, compact: compact)
            }
            ForEach(Array(R.adhocCounters.enumerated()), id: \.element.id) { i, c in
                CrCounterCard(ctx: ctx, vs: vs, id: c.id, def: nil, adhocRank: i + 1, pal: pal, compact: compact)
            }
        }
    }
}

struct CrCounterCard: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let id: String
    let def: CounterDef?
    let adhocRank: Int?
    let pal: CrPal
    var compact = false
    @Environment(AppModel.self) private var model
    @State private var editing = false
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var b = vs
        let R = ctx.R
        let act = CrAct(model: model, vs: vs, R: R)
        let v = R.counters[id] ?? 0
        let label = ctx.e.counterLabel(R, id)
        let name = label.isEmpty ? "Compteur" : label
        let last = R.events.last { $0.refType == "counter" && $0.refId == id && !$0.isVoid }
        VStack(alignment: compact ? .leading : .center, spacing: 6) {
            HStack(spacing: 4) {
                if editing {
                    TextField("Nom du compteur", text: $text)
                        .textFieldStyle(.plain).aFont(16, .semibold).foregroundStyle(pal.ink)
                        .focused($focused)
                        .onSubmit { commit(act) }
                        .onChange(of: focused) { _, f in if !f && editing { commit(act) } }
                } else {
                    Text(name).aFont(compact ? TypeScale.meta : TypeScale.body, .semibold).foregroundStyle(pal.ink2).lineLimit(2)
                }
                if adhocRank != nil && !editing {
                    Button { text = R.adhocCounters.first { $0.id == id }?.label ?? ""; editing = true; focused = true } label: {
                        Group {
                            if (R.adhocCounters.first { $0.id == id }?.label ?? "").isEmpty {
                                Text("— nommer").aFont(TypeScale.meta, .bold)
                            } else {
                                Image(systemName: "pencil").font(.system(size: 12, weight: .bold))
                            }
                        }
                        .foregroundStyle(pal.sys ? T.sysInk : T.act)
                        .frame(minWidth: 32, minHeight: 32).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Nommer ce compteur")
                    Button {
                        if v > 0 { vs.confirmDeleteCounter = id } else { act.removeCounter(id) }
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(pal.ink2)
                            .frame(width: 32, height: 32).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Supprimer ce compteur")
                }
                if compact {
                    Spacer(minLength: 4)
                    Text(crNum(v)).aFont(TypeScale.item, .bold, .mono).foregroundStyle(pal.ink)
                    pmButtons(act, name: name)
                }
            }
            if !compact {
                Text(crNum(v)).aFont(TypeScale.val, .bold, .mono).foregroundStyle(pal.ink)
                    .accessibilityLabel(name + " : " + crNum(v))
            }
            if let last {
                let t0 = R.startedAt
                Text("consigné " + (t0 > 0 ? "T+" + Fmt.ms(max(0, last.t - t0)) : Fmt.hms(last.t)) + " · il y a " + Fmt.ms(ctx.now - last.t))
                    .aFont(TypeScale.cap, .bold, .mono).foregroundStyle(pal.ink2)
            }
            if !compact {
                pmButtons(act, name: name)
                if let def, !def.timerId.isEmpty, let lt = R.timers[def.timerId] {
                    Text("＋ relance le minuteur « " + lt.name + " »").aFont(TypeScale.meta, .medium).foregroundStyle(pal.ink2)
                }
                HoldButton(label: "Remettre à zéro · maintenir", ms: 800, kind: .secondary, height: Ctrl.s) { act.counterReset(id) }
                    .accessibilityLabel("Remettre à zéro — " + name)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(pal.card, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(pal.line, lineWidth: 1))
        .confirmationDialog("Ce compteur est à " + crNum(v) + ". Le supprimer ?", isPresented: Binding(
            get: { b.confirmDeleteCounter == id }, set: { if !$0 { b.confirmDeleteCounter = nil } }), titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) { act.removeCounter(id); vs.confirmDeleteCounter = nil }
            Button("Annuler", role: .cancel) { vs.confirmDeleteCounter = nil }
        }
    }

    private func pmButtons(_ act: CrAct, name: String) -> some View {
        HStack(spacing: 8) {
            Button { act.counterMinus(id) } label: {
                Text("−").aFont(TypeScale.stepL, .bold).foregroundStyle(pal.ink)
                    .frame(width: Ctrl.l, height: Ctrl.l)
                    .background(pal.btn, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Diminuer — " + name)
            Button { act.counterPlus(id) } label: {
                Text("+").aFont(TypeScale.stepL, .heavy).foregroundStyle(pal.sys ? T.sysInk : T.act)
                    .frame(minWidth: compact ? Ctrl.l : 0, maxWidth: compact ? Ctrl.l : .infinity, minHeight: Ctrl.l)
                    .background(pal.sys ? T.sysHi : T.primarySoft, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .layoutPriority(1.4)
            .accessibilityLabel("Augmenter — " + name)
        }
    }
    private func commit(_ act: CrAct) {
        editing = false
        act.renameCounter(id, text)
    }
}

// MARK: - Jalons (tous les blocs)

struct CrJalonsSection: View {
    let ctx: CrCtx
    let pal: CrPal
    var body: some View {
        let R = ctx.R
        VStack(alignment: .leading, spacing: 0) {
            ForEach(ctx.f.blocks.filter { !$0.milestones.isEmpty }, id: \.id) { b in
                let lp = Graph.latestPass(nav: R.nav, navSeq: R.navSeq, b.id)
                let pass = lp.map { Graph.passInfo(nav: R.nav, $0.idx).pass } ?? 0
                ForEach(Array(b.milestones.enumerated()), id: \.offset) { _, j in
                    let p = Jalons.progress(j, pass: pass, count: R.counters[j.counter] ?? 0)
                    HStack(spacing: 8) {
                        Text("△").aFont(TypeScale.meta, .heavy)
                        Text(Jalons.conditionLabel(ctx.f, j)).aFont(TypeScale.meta, p.active ? .heavy : .medium).lineLimit(1)
                        Spacer(minLength: 4)
                        Text("\(crNum(p.cur))/\(p.goal)").aFont(TypeScale.meta, .bold, .mono)
                            .accessibilityLabel("\(crNum(p.cur)) sur un seuil de \(p.goal)")
                    }
                    .foregroundStyle(p.active ? pal.warn : pal.ink2)
                    .frame(minHeight: 32)
                }
            }
        }
    }
}

// MARK: - Journal des actions

struct CrEventJournal: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let pal: CrPal
    @Environment(AppModel.self) private var model

    var body: some View {
        let R = ctx.R
        let labs = Report.eventLabels(R.events, R.fiche, tags: model.library.tags, extras: crExtras(R))
        let t0 = R.startedAt > 0 ? R.startedAt : (R.events.first?.t ?? 0)
        VStack(alignment: .leading, spacing: 0) {
            if R.events.isEmpty && R.started {
                Text("Chaque tap sur « Horodater », en bas de l’écran, inscrit ici l’heure d’un geste.")
                    .aFont(TypeScale.cap, .medium).foregroundStyle(pal.ink2)
            }
            ForEach(Array(R.events.enumerated()), id: \.element.id) { i, e in
                CrEventRow(ctx: ctx, vs: vs, ev: e, label: i < labs.count ? labs[i] : "", t0: t0, pal: pal)
            }
        }
    }
}

struct CrEventRow: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    let ev: SessionEvent
    let label: String
    let t0: Double
    let pal: CrPal
    @Environment(AppModel.self) private var model
    @State private var text = ""
    @State private var shown = ""
    @FocusState private var labelFocus: Bool
    @State private var editTime = false
    @State private var timeText = ""
    @State private var timeBad = false
    @FocusState private var timeFocus: Bool

    var body: some View {
        let act = CrAct(model: model, vs: vs, R: ctx.R)
        let d = ev.t - t0
        VStack(alignment: .leading, spacing: 6) {
            Rectangle().fill(pal.line).frame(height: 1)
            HStack(spacing: 8) {
                if editTime { timeField(act) } else {
                    Button { timeText = Fmt.hms(ev.t); timeBad = false; editTime = true; timeFocus = true } label: {
                        Text(Fmt.hms(ev.t)).aFont(TypeScale.body, .semibold, .mono).foregroundStyle(pal.ink)
                            .frame(minHeight: Ctrl.l).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Cliquer pour corriger l'heure")
                    .accessibilityHint("Corriger l'heure")
                }
                Text(d == 0 ? "—" : (d > 0 ? "+" : "−") + Fmt.ms(abs(d))).aFont(TypeScale.cap, .medium, .mono).foregroundStyle(pal.ink2)
                TextField("Libellé…", text: $text)
                    .textFieldStyle(.plain)
                    .aFont(16, .medium)
                    .foregroundStyle(ev.isVoid ? pal.ink2 : pal.ink)
                    .strikethrough(ev.isVoid)
                    .disabled(ev.isVoid)
                    .focused($labelFocus)
                    .onSubmit { commitLabel(act) }
                    .onChange(of: labelFocus) { _, f in if !f { commitLabel(act) } }
                    .accessibilityLabel("Libellé du repère")
                Button { act.toggleVoid(ev.id) } label: {
                    Image(systemName: ev.isVoid ? "arrow.uturn.backward" : "xmark").font(.system(size: 12, weight: .bold))
                        .foregroundStyle(pal.ink2).frame(width: Ctrl.l, height: Ctrl.l).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ev.isVoid ? "Rétablir ce repère" : "Annuler ce repère")
            }
            if editTime {
                HStack(spacing: 8) {
                    Text("noté en retard ?").aFont(TypeScale.cap, .semibold).foregroundStyle(pal.ink2)
                    ForEach([1, 2, 5], id: \.self) { m in
                        Button {
                            act.correctTime(ev.id, ev.t - Double(m) * 60_000)
                            editTime = false
                        } label: {
                            Text("−\(m) min").aFont(TypeScale.meta, .bold).foregroundStyle(pal.ink)
                                .padding(.horizontal, 10).frame(minHeight: Ctrl.l)
                                .overlay(Capsule().strokeBorder(pal.line, lineWidth: 1))
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                if timeBad {
                    Text("△ Heure non reconnue — ex. 1547 ou 15:47").aFont(TypeScale.cap, .bold).foregroundStyle(pal.warn)
                }
            }
            if let o = ev.origT {
                HStack(spacing: 8) {
                    Text("à l'origine " + Fmt.hms(o)).aFont(TypeScale.cap, .medium, .mono).foregroundStyle(pal.ink2)
                    Button("↺ revenir") { act.revertTime(ev.id) }
                        .aFont(TypeScale.cap, .bold).foregroundStyle(pal.sys ? T.sysInk : T.act).buttonStyle(.plain)
                        .frame(minHeight: Ctrl.s)
                }
            }
            if labelFocus && text.count >= 2 { suggestions(act) }
        }
        .padding(.vertical, 4)
        .onAppear { text = label; shown = label }
        .onChange(of: label) { _, l in if !labelFocus { text = l; shown = l } }
    }

    private func timeField(_ act: CrAct) -> some View {
        TextField("hh:mm:ss", text: $timeText)
            .textFieldStyle(.plain)
            .aFont(16, .semibold, .mono)
            .foregroundStyle(pal.ink)
            .frame(width: 110, height: Ctrl.l)
            .padding(.horizontal, 6)
            .overlay(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).strokeBorder(timeBad ? pal.warnLine : pal.line, lineWidth: timeBad ? 2 : 1))
            .focused($timeFocus)
            #if os(iOS)
            .keyboardType(.numbersAndPunctuation)
            #endif
            .onSubmit {
                if let h = CrisisPure.tkParseTime(timeText) {
                    act.correctTime(ev.id, CrisisPure.correctedTime(ev.t, h))
                    editTime = false
                } else {
                    timeBad = true
                    crAnnounce("Heure non reconnue — exemples : 1547, ou 15:47")
                    timeFocus = true
                }
            }
            .onChange(of: timeFocus) { _, f in
                guard !f, editTime else { return }
                if let h = CrisisPure.tkParseTime(timeText) { act.correctTime(ev.id, CrisisPure.correctedTime(ev.t, h)) }
                else { crAnnounce("Heure non reconnue — repère inchangé") }
                editTime = false
            }
            .accessibilityLabel("Heure du repère")
    }

    /// Libellé MANUEL, souverain et strictement local (règle 15) — écrit seulement s'il a changé.
    private func commitLabel(_ act: CrAct) {
        guard text != shown else { return }
        shown = text
        act.label(ev.id, text)
    }

    @ViewBuilder
    private func suggestions(_ act: CrAct) -> some View {
        // SIMPLIFICATION : les compteurs ne sont pas proposés ici (l'étiquette d'un compteur
        // l'incrémente dans le moteur — `tagEvent` ; le volet ne COMPTE pas, B1 §15.4).
        let all = CrisisPure.tagAll(ctx.f, tags: model.library.tags, R: ctx.R).filter { $0.type != "counter" }
        let hits = CrisisPure.tagMatch(all, query: text)
        if !hits.isEmpty {
            CrWrap(spacing: 6) {
                ForEach(Array(hits.enumerated()), id: \.offset) { _, c in
                    Button {
                        shown = c.label; text = c.label
                        labelFocus = false
                        act.tag(ev.id, c)
                    } label: {
                        Text(Report.tagShort(c.label))
                            .aFont(TypeScale.meta, .bold).foregroundStyle(pal.ink)
                            .padding(.horizontal, 12).frame(minHeight: Ctrl.l)
                            .overlay(Capsule().strokeBorder(pal.line, lineWidth: 1))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Réglages (son, veille)

struct CrSettingsRow: View {
    let pal: CrPal
    @Environment(AppModel.self) private var model
    var body: some View {
        CrWrap(spacing: 8) {
            Button { model.soundOn.toggle() } label: {
                Text(model.soundOn ? "🔔 Son activé" : "🔕 Son coupé").aFont(TypeScale.meta, .bold)
                    .foregroundStyle(model.soundOn ? pal.ink : pal.warn)
                    .padding(.horizontal, 12).frame(minHeight: Ctrl.l)
                    .overlay(Capsule().strokeBorder(pal.line, lineWidth: 1))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .help(model.soundOn ? "Le son est activé — appuyer pour couper" : "Le son est coupé — appuyer pour activer")
            .accessibilityAddTraits(model.soundOn ? .isSelected : [])
            #if os(iOS)
            Button {
                model.wakeWanted.toggle()
                model.applyWake(crisisOnScreen: model.current?.started ?? false)
            } label: {
                Text(model.wakeWanted ? "☀ Veille coupée" : "☾ Veille active").aFont(TypeScale.meta, .bold)
                    .foregroundStyle(pal.ink)
                    .padding(.horizontal, 12).frame(minHeight: Ctrl.l)
                    .overlay(Capsule().strokeBorder(pal.line, lineWidth: 1))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .help(model.wakeWanted ? "L’écran reste allumé pendant la session — appuyer pour laisser la veille normale"
                                   : "La veille du système s’applique — appuyer pour maintenir l’écran allumé")
            .accessibilityAddTraits(model.wakeWanted ? .isSelected : [])
            #endif
        }
    }
}

// MARK: - Le volet du téléphone (matière système, suspendu sous la capsule)

struct CrVolet: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    var body: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: Radius.r3,
                                           bottomTrailingRadius: Radius.r3, topTrailingRadius: 0, style: .continuous)
        // Court : il tient sans défileur ; long : il défile SEUL (jamais la page).
        ViewThatFits(in: .vertical) {
            inner
            ScrollView { inner }.scrollDismissesKeyboard(.interactively)
        }
        .background(T.sys, in: shape)
        .overlay(shape.stroke(T.sysEdge, lineWidth: 1))
        .clipShape(shape)
        .shadow(color: Color.black.opacity(0.3), radius: 16, y: 8)
    }

    private var inner: some View {
        let pal = CrPal(sys: true)
        let R = ctx.R
        let nT = R.orderedTimers.count
        let nC = ctx.f.counters.count + R.adhocCounters.count
        let hasJalons = ctx.f.blocks.contains { !$0.milestones.isEmpty }
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "stopwatch").foregroundStyle(pal.ink2)
                CrFamHead(title: "Minuteurs", count: nT, pal: pal)
                Spacer()
                Button { vs.voletOpen = false } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundStyle(pal.ink2)
                        .frame(width: Ctrl.l, height: Ctrl.l).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Replier les minuteurs et le journal")
            }
            CrTimersSection(ctx: ctx, vs: vs, pal: pal)
            CrAddRow(ctx: ctx, vs: vs, pal: pal, showCounter: false)
            Rectangle().fill(pal.line).frame(height: 1)
            CrFamHead(title: "Compteurs", count: nC, pal: pal)
            CrCountersSection(ctx: ctx, vs: vs, pal: pal)
            CrAddRow(ctx: ctx, vs: vs, pal: pal, showTimer: false)
            if hasJalons {
                Rectangle().fill(pal.line).frame(height: 1)
                CrFamHead(title: "Jalons", count: ctx.f.blocks.reduce(0) { $0 + $1.milestones.count }, pal: pal)
                CrJalonsSection(ctx: ctx, pal: pal)
            }
            Rectangle().fill(pal.line).frame(height: 1)
            CrFamHead(title: "Journal des actions", count: R.events.count, pal: pal)
            CrEventJournal(ctx: ctx, vs: vs, pal: pal)
            Rectangle().fill(pal.line).frame(height: 1)
            CrSettingsRow(pal: pal)
        }
        .padding(14)
    }
}
