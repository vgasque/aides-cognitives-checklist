import SwiftUI
import AidesCore

// L'ÉDITEUR D'UN BLOC — port de `blockEditor`, `blkTopHtml`, `blkOptsHtml`, `phaseFieldHtml`,
// `jalonEditor`, `targetSelect`, `imageEditor` et de la rangée d'étape (A383 : écrire une étape
// n'ouvre rien ; un bouton « Réglages » ouvre UNE feuille ; ce qui est réglé se lit en pastilles).

struct BlockEditorCard: View {
    @Bindable var ed: FicheDraft
    var bid: String

    var body: some View {
        if let b = ed.block(bid) {
            WorkCard(padding: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    BlockHeader(ed: ed, block: b)
                    switch b.kind {
                    case .do: DoBlockBody(ed: ed, block: b)
                    case .decision: DecisionBlockBody(ed: ed, block: b)
                    case .review: StepList(ed: ed, block: b, review: true)
                    }
                    if b.kind != .review { BlockOptionsFold(ed: ed, block: b) }
                    HStack {
                        Spacer()
                        Button("Supprimer le bloc") { ed.deleteBlock(bid) }
                            .buttonStyle(.a(.danger, Ctrl.s))
                            .edLock()
                    }
                }
            }
            .id("b:" + bid)
            .edFlash(ed.flashKey == "b:" + bid)
        }
    }
}

// MARK: - En-tête : pastille · titre · « ↺ Se répète » · poignée

struct BlockHeader: View {
    @Bindable var ed: FicheDraft
    var block: Block

    var body: some View {
        let b = block
        HStack(spacing: 8) {
            badge(b)
            EdField(value: b.title, placeholder: placeholder(b), label: aria(b), focusKey: "bt:" + b.id, request: ed.focusRequest,
                    maxLength: 300, size: TypeScale.item, weight: .bold, resync: ed.syncTick) { v in
                ed.updateBlock(b.id, typing: true) { $0.title = v }
            }
            if b.kind != .review && Graph.inLoop(ed.d, b.id) {
                Text("↺ Se répète").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
                    .padding(.horizontal, 8).frame(minHeight: 24)
                    .background(T.amb2, in: Capsule())
                    .help("Le parcours revient à ce bloc")
                    .accessibilityLabel("Se répète : le parcours revient à ce bloc")
            }
            if b.kind != .review {
                EdGrabHandle(active: ed.grab == .block(b.id), label: "Déplacer ce bloc") {
                    ed.grab = ed.grab == .block(b.id) ? nil : .block(b.id)
                }
                .help("Déplacer le bloc — touchez, puis touchez la destination")
            }
        }
    }
    @ViewBuilder private func badge(_ b: Block) -> some View {
        Group {
            switch b.kind {
            case .do: Text("\(EdKit.blockNumber(ed.d, b.id))").aFont(TypeScale.body, .bold, .mono)
            case .decision: Text("◆").aFont(TypeScale.body, .bold)
            case .review: Image(systemName: "square.grid.2x2").font(.system(size: 13, weight: .bold))
            }
        }
        .foregroundStyle(T.onPrimary)
        .frame(width: 28, height: 28)
        .background(b.kind == .decision ? T.warn : T.act, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
        .accessibilityHidden(true)
    }
    private func placeholder(_ b: Block) -> String {
        switch b.kind {
        case .do: return "Titre (ex. Mesures immédiates)"
        case .decision: return "Titre (ex. Réévaluation)"
        case .review: return "Titre (ex. Rechercher les causes réversibles (4H / 4T))"
        }
    }
    private func aria(_ b: Block) -> String {
        switch b.kind {
        case .do: return "Titre du bloc"
        case .decision: return "Titre de la décision"
        case .review: return "Titre de la revue"
        }
    }
}

// MARK: - Bloc d'étapes

struct DoBlockBody: View {
    @Bindable var ed: FicheDraft
    var block: Block

    var body: some View {
        let b = block
        VStack(alignment: .leading, spacing: 8) {
            StepList(ed: ed, block: b, review: false)
            EdSub(text: "Étape suivante")
            Picker("Bloc suivant", selection: Binding<String>(
                get: { b.next ?? "" },
                set: { v in ed.updateBlock(b.id, typing: false) { $0.next = v.isEmpty ? nil : v } })) {
                Text("— Fin / aucun —").tag("")
                ForEach(ed.d.blocks.filter { $0.id != b.id && $0.kind != .review }) { x in
                    Text(EdKit.targetLabel(ed.d, x)).tag(x.id)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .edLock()
        }
    }
}

/// Les étapes d'un bloc (ou les hypothèses d'une revue) avec leurs destinations « Poser ».
struct StepList: View {
    @Bindable var ed: FicheDraft
    var block: Block
    var review: Bool

    var body: some View {
        let b = block
        let items = Pool.blockItems(ed.d, b)
        VStack(alignment: .leading, spacing: 6) {
            EdSub(text: review ? "Hypothèses" : "Étapes")
            if items.isEmpty {
                // Un bloc vide montre une rangée vide : la première frappe crée l'étape.
                EdField(value: "", placeholder: review ? "Hypothèse…" : "Nouvelle étape…", label: "Étape 1 — ce qui se prononce",
                        resync: ed.syncTick) { v in
                    let it = EdKit.newStepItem(v)
                    ed.structural { EdKit.bItemAdd(&$0, blockId: b.id, at: 0, it) }
                    ed.requestFocus("s:" + it.id)
                }
            }
            ForEach(Array(items.enumerated()), id: \.element.id) { j, it in
                stepDrop(b, items, j)
                StepRow(ed: ed, blockId: b.id, item: it, index: j, total: items.count, reviewBlock: review)
            }
            stepDrop(b, items, items.count)
            EdGuardLine(text: EdKit.stepGuardTxt(Graph.stepsOf(ed.d, b), bloc: true))
            EdLinkButton(text: review ? "+ Ajouter une hypothèse" : "+ Ajouter une étape") {
                ed.addStep(block: b.id, at: b.items.count)
            }
        }
    }

    /// Destination d'une étape tenue : dans CHAQUE bloc ; une étape ⚠ qui change de bloc est annoncée.
    @ViewBuilder private func stepDrop(_ b: Block, _ items: [Item], _ j: Int) -> some View {
        if case .step(let sb, let si)? = ed.grab {
            let srcIdx = sb == b.id ? items.firstIndex(where: { $0.id == si }) : nil
            let hidden = srcIdx.map { j == $0 || j == $0 + 1 } ?? false
            if !hidden {
                let lvl = ed.item(si)?.level ?? 1
                EdDropTarget(label: j == 0 ? "Poser en tête" : (j >= items.count ? "Poser en fin" : "Poser ici"),
                             warn: lvl == 3 && sb != b.id) {
                    drop(from: sb, item: si, to: b, items: items, j: j)
                }
            }
        }
    }
    private func drop(from sb: String, item si: String, to b: Block, items: [Item], j: Int) {
        var pos = j < items.count ? (b.items.firstIndex(of: items[j].id) ?? b.items.count) : b.items.count
        if sb == b.id, let sp = b.items.firstIndex(of: si), sp < pos { pos -= 1 }
        ed.grab = nil
        ed.structural { EdKit.bItemMove(&$0, from: sb, itemId: si, to: b.id, at: pos) }
        ed.scrollTo("b:" + b.id)
    }
}

// MARK: - Rangée d'étape

struct StepRow: View {
    @Bindable var ed: FicheDraft
    var blockId: String
    var item: Item
    var index: Int
    var total: Int
    var reviewBlock: Bool
    @State private var doFocus = false
    @State private var expFocus = false
    @State private var expOpen = false

    var body: some View {
        let it = ed.item(item.id) ?? item
        let reg = it.level
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if total >= 2 {
                    EdGrabHandle(active: ed.grab == .step(block: blockId, item: it.id), label: "Déplacer l'étape \(index + 1)") {
                        let g = EdGrab.step(block: blockId, item: it.id)
                        ed.grab = ed.grab == g ? nil : g
                    }
                }
                EdField(value: it.do, placeholder: reviewBlock ? "Hypothèse…" : "Nouvelle étape…",
                        label: "Étape \(index + 1) — ce qui se prononce", focusKey: "s:" + it.id, request: ed.focusRequest,
                        maxLength: 500, weight: .semibold, disabled: it.review != nil, resync: ed.syncTick,
                        rewrite: { v in shortcut(v) },
                        onChange: { v in setText(v) },
                        onSubmit: { ed.addStep(block: blockId, at: index + 1) },
                        onFocus: { f in doFocus = f; focusMoved(f) })
                    .submitLabel(.next)
                settingsButton(it)
            }
            if it.review == nil && (expOpen || !it.expect.isEmpty) {
                EdField(value: it.expect, placeholder: reviewBlock ? "indice (facultatif)" : "réponse attendue (facultatif)",
                        label: "Étape \(index + 1) — réponse attendue (facultatif)", maxLength: 200, size: TypeScale.body,
                        resync: ed.syncTick,
                        onChange: { v in ed.updateItem(it.id, typing: true) { $0.expect = v } },
                        onFocus: { f in expFocus = f; focusMoved(f) })
                    .padding(.leading, total >= 2 ? Ctrl.s + 6 : 0)
            }
            let pills = EdKit.stepPills(ed.d, it)
            if !pills.isEmpty {
                EdPillsRow(pills: pills).padding(.leading, total >= 2 ? Ctrl.s + 6 : 0)
            }
            let note = EdKit.stepNote(it.legacyString)
            if !note.isEmpty {
                Text("△ Relecture — " + note).aFont(TypeScale.meta, .semibold).foregroundStyle(T.warn)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, total >= 2 ? Ctrl.s + 6 : 0)
            }
        }
        .padding(.vertical, 2)
        .padding(.leading, reg >= 2 ? 8 : 0)
        .overlay(alignment: .leading) {
            if reg >= 2 {
                Rectangle().fill(reg == 3 ? T.critLine : T.warnLine).frame(width: 3)
                    .accessibilityHidden(true)
            }
        }
        .id("s:" + it.id)
    }

    @ViewBuilder private func settingsButton(_ it: Item) -> some View {
        let on = EdKit.stepSetOn(it)
        Button { ed.sheet = .step(block: blockId, item: it.id) } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(on ? T.act : T.ink2)
                .frame(width: Ctrl.l, height: Ctrl.l)
                .background(on ? T.primarySoft : Color.clear, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .edLock()
        .accessibilityLabel("Réglages de l’étape \(index + 1)")
        .help("Importance, ce que fait la coche, moment")
    }

    /// Raccourci « ! » / « ? » en TÊTE de ligne : le registre va au modèle, le préfixe est consommé.
    private func shortcut(_ v: String) -> String? {
        guard let s = EdKit.stepShortcut(v) else { return nil }
        ed.updateItem(item.id, typing: false) { $0.level = s.level }
        return s.rest
    }
    /// `setStepStr(b, i, prefix + value)` : le registre courant est conservé.
    private func setText(_ v: String) {
        let lvl = ed.item(item.id)?.level ?? 1
        let pfx = lvl == 3 ? "⚠ " : (lvl == 2 ? "△ " : "")
        ed.typing { EdKit.setStepStr(&$0, itemId: item.id, pfx + v) }
    }
    /// La rangée reste ouverte tant que le focus y reste (`.ed-on`, A384) ; une étape quittée VIDE
    /// disparaît (jamais la dernière d'un bloc, jamais pendant un déplacement).
    private func focusMoved(_ f: Bool) {
        if f { expOpen = true; return }
        let iid = item.id, bid = blockId
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard !doFocus && !expFocus else { return }
            expOpen = false
            guard ed.grab == nil, let cur = ed.item(iid), cur.do.isEmpty, cur.expect.isEmpty, cur.review == nil,
                  let b = ed.block(bid), b.items.count >= 2 else { return }
            if case .step(_, let open)? = ed.sheet, open == iid { return }
            ed.deleteStep(block: bid, item: iid)
        }
    }
}

// MARK: - Décision

struct DecisionBlockBody: View {
    @Bindable var ed: FicheDraft
    var block: Block

    var body: some View {
        let b = block
        let opts = b.options.isEmpty ? [DecisionOption(label: "", target: nil)] : b.options
        VStack(alignment: .leading, spacing: 8) {
            EdSub(text: "Question")
            EdField(value: b.question, placeholder: "ex. Réponse à l'adrénaline ?", label: "Question posée", focusKey: "bq:" + b.id,
                    request: ed.focusRequest, maxLength: 1000, resync: ed.syncTick) { v in
                ed.updateBlock(b.id, typing: true) { $0.question = v }
            }
            EdSub(text: "Réponses → bloc cible")
            ForEach(Array(opts.enumerated()), id: \.offset) { i, o in
                HStack(spacing: 6) {
                    EdField(value: o.label, placeholder: "ex. Oui", label: "Libellé de la réponse \(i + 1)", focusKey: "bo:" + b.id + ":\(i)",
                            request: ed.focusRequest, maxLength: 300, resync: ed.syncTick) { v in
                        ed.updateBlock(b.id, typing: true) { x in
                            if x.options.isEmpty { x.options = [DecisionOption(label: "", target: nil)] }
                            if i < x.options.count { x.options[i].label = v }
                        }
                    }
                    Picker("Bloc suivant", selection: Binding<String>(
                        get: { o.target ?? "" },
                        set: { v in ed.updateBlock(b.id, typing: false) { x in
                            if x.options.isEmpty { x.options = [DecisionOption(label: "", target: nil)] }
                            if i < x.options.count { x.options[i].target = v.isEmpty ? nil : v }
                        } })) {
                        Text("— Fin / aucun —").tag("")
                        ForEach(ed.d.blocks.filter { $0.id != b.id && $0.kind != .review }) { x in
                            Text(EdKit.targetLabel(ed.d, x)).tag(x.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: 200)
                    .edLock()
                    EdIconButton(system: "xmark", label: "Supprimer la réponse") {
                        ed.updateBlock(b.id, typing: false) { x in
                            if i < x.options.count { x.options.remove(at: i) }
                            if x.options.isEmpty { x.options = [DecisionOption(label: "", target: nil)] }
                        }
                    }
                }
            }
            EdLinkButton(text: "+ Ajouter une réponse") {
                let n = max(1, b.options.count)
                ed.updateBlock(b.id, typing: false) { x in
                    if x.options.isEmpty { x.options = [DecisionOption(label: "", target: nil)] }
                    x.options.append(DecisionOption(label: "", target: nil))
                }
                ed.requestFocus("bo:" + b.id + ":\(n)")
            }
        }
    }
}

// MARK: - « Options du bloc » (carte dépliable, `blkOptsHtml`)

struct BlockOptionsFold: View {
    @Bindable var ed: FicheDraft
    var block: Block

    var body: some View {
        let b = block, f = ed.d
        let loop = Graph.inLoop(f, b.id)
        let dep = f.start == b.id
        let ph = JS.trim(b.phase)
        let nj = b.milestones.count
        let nl = b.kind != .decision && (b.next?.isEmpty == false)
        var sum: [String] = []
        if dep { sum.append("Départ") }
        if !ph.isEmpty { sum.append(ph) }
        if nl && !JS.trim(b.nextLbl).isEmpty { sum.append("« Continuer » renommé") }
        if b.timer != nil { sum.append("Minuteur") }
        if nj > 0 { sum.append("\(nj) jalon" + either(nj > 1, "s", "")) }
        if b.image != nil { sum.append("Image") }
        let open = ed.blockOptOpen[b.id] ?? (sum.count > (dep ? 1 : 0))
        return VStack(alignment: .leading, spacing: 10) {
            Button { ed.blockOptOpen[b.id] = !open } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3").foregroundStyle(T.ink2)
                    Text("Options du bloc").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                    Text(sum.isEmpty ? "Aucune" : sum.joined(separator: " · ")).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundStyle(T.ink3)
                }
                .frame(minHeight: Ctrl.m).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .edLock()
            .accessibilityValue(open ? "déplié" : "replié")
            if open {
                BlockOptionRows(ed: ed, block: b, loop: loop, dep: dep, nl: nl)
            }
        }
        .padding(10)
        .background(T.amb2.opacity(0.6), in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
    }
}

struct BlockOptionRows: View {
    @Bindable var ed: FicheDraft
    var block: Block
    var loop: Bool
    var dep: Bool
    var nl: Bool

    var body: some View {
        let b = block, f = ed.d
        VStack(alignment: .leading, spacing: 12) {
            row("Bloc de départ", dep ? "le parcours commence ici" : "") {
                Toggle("", isOn: Binding(get: { dep }, set: { v in if v { ed.structural { $0.start = b.id } } }))
                    .labelsHidden().toggleStyle(.switch).tint(T.act)
                    .disabled(dep).edLock()
                    .help(dep ? "Pour changer, choisissez un autre bloc de départ" : "")
                    .accessibilityLabel("Bloc de départ")
            }
            row("Phase", JS.trim(b.phase).isEmpty ? "facultative" : "") { PhaseField(ed: ed, block: b) }
            if nl {
                let nxt = f.blocks.first { $0.id == b.next }.map { JS.trim($0.title) } ?? ""
                row("Libellé de « Continuer »", "facultatif") {
                    EdField(value: b.nextLbl, placeholder: nxt.isEmpty ? "Continuer" : nxt, label: "Libellé du bouton Continuer",
                            maxLength: 120, resync: ed.syncTick) { v in ed.updateBlock(b.id, typing: true) { $0.nextLbl = v } }
                }
            }
            if (loop || b.timer != nil) && !f.timers.isEmpty {
                row("Minuteur du bloc", "à chaque entrée") {
                    Picker("Minuteur lancé à chaque entrée dans le bloc", selection: Binding<String>(
                        get: { b.timer ?? "" },
                        set: { v in ed.updateBlock(b.id, typing: false) { $0.timer = v.isEmpty ? nil : v } })) {
                        Text("Aucun").tag("")
                        ForEach(f.timers) { t in Text(EdKit.timerOptionLabel(t)).tag(t.id) }
                    }
                    .pickerStyle(.menu).labelsHidden().edLock()
                }
            }
            if loop || !b.milestones.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Jalons de boucle").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                        Text("le bloc se répète").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                        Spacer()
                        if b.milestones.count < 3 {
                            EdLinkButton(text: "+ Jalon") {
                                ed.updateBlock(b.id, typing: false) { $0.milestones.append(Milestone(at: .pass, n: 2, counter: "", text: "", go: "")) }
                            }
                        }
                    }
                    MilestoneRows(ed: ed, block: b)
                }
            }
            row("Image", "") { BlockImageEditor(ed: ed, block: b) }
        }
    }
    /// Une rangée d'option : libellé (et sous-ligne) au-dessus, contrôle dessous — une seule
    /// instance du contrôle (un champ dupliqué pour la mesure aurait deux focus).
    @ViewBuilder private func row<C: View>(_ l: String, _ sub: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            label(l, sub)
            c()
        }
    }
    @ViewBuilder private func label(_ l: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(l).aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
            if !sub.isEmpty { Text(sub).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2) }
        }
    }
}

// MARK: - Phase (`phaseFieldHtml`) : valeurs suggérées, héritage, « ＋ Nouvelle phase… »

struct PhaseField: View {
    @Bindable var ed: FicheDraft
    var block: Block
    @State private var draft = ""

    var body: some View {
        let b = block, f = ed.d
        let her = EdKit.phaseInherited(f, b.id)
        let cur = JS.trim(b.phase)
        let cnt = EdKit.phaseCounts(f)
        if ed.phaseNewFor == b.id {
            HStack(spacing: 6) {
                EdField(value: "", placeholder: "Nom de la phase…", label: "Nom de la nouvelle phase", focusKey: "ph:" + b.id,
                        request: ed.focusRequest, maxLength: 40,
                        onChange: { v in draft = v },
                        onSubmit: { commitNew() },
                        onFocus: { fo in if !fo { commitNew() } })
                    .frame(minWidth: 160)
                EdIconButton(system: "xmark", label: "Annuler") { ed.phaseNewFor = nil; draft = "" }
            }
        } else {
            Picker("Phase du bloc (facultative, héritée du bloc précédent)", selection: Binding<String>(
                get: { cur },
                set: { v in
                    if v == "__new" { draft = ""; ed.phaseNewFor = b.id; ed.requestFocus("ph:" + b.id) }
                    else { ed.updateBlock(b.id, typing: false) { $0.phase = v } }
                })) {
                Text(her.isEmpty ? "Aucune" : her + " (héritée)").tag("")
                ForEach(EdKit.phaseOptions(f, b), id: \.self) { v in
                    Text(v + (cnt[v].map { " (\($0) bloc" + either($0 > 1, "s", "") + ")" } ?? "")).tag(v)
                }
                Text("＋ Nouvelle phase…").tag("__new")
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .edLock()
            .help("Phase — facultative. Vide, le bloc reprend celle du bloc précédent" + (her.isEmpty ? "" : " (« " + her + " »)") + ".")
        }
    }
    private func commitNew() {
        guard ed.phaseNewFor == block.id else { return }
        let v = JS.prefix(JS.trim(draft), 40)
        ed.phaseNewFor = nil
        draft = ""
        if !v.isEmpty { ed.updateBlock(block.id, typing: false) { $0.phase = v } }
    }
}

// MARK: - Jalons de boucle (`jalonEditor`)

struct MilestoneRows: View {
    @Bindable var ed: FicheDraft
    var block: Block

    var body: some View {
        let b = block, f = ed.d
        let exs = f.excursions.filter { !$0.label.isEmpty && !$0.target.isEmpty }
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(b.milestones.enumerated()), id: \.offset) { i, j in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Picker("Ce que compte le jalon", selection: Binding<String>(
                            get: { j.at == .count ? j.counter : "pass" },
                            set: { v in edit(i) { m in
                                if v == "pass" { m.at = .pass; m.counter = "" } else { m.at = .count; m.counter = v }
                            } })) {
                            Text("Passages du bloc").tag("pass")
                            ForEach(f.counters) { c in Text(EdKit.counterName(c)).tag(c.id) }
                        }
                        .pickerStyle(.menu).labelsHidden().edLock()
                        Text("≥").aFont(TypeScale.item, .bold).foregroundStyle(T.ink2).accessibilityHidden(true)
                        EdStepper(value: j.n, label: "Seuil du jalon") { n in edit(i) { $0.n = n } }
                        Spacer(minLength: 0)
                        EdIconButton(system: "xmark", label: "Supprimer ce jalon") {
                            ed.updateBlock(b.id, typing: false) { x in if i < x.milestones.count { x.milestones.remove(at: i) } }
                        }
                    }
                    EdField(value: j.text, placeholder: "ex. 3 CEE sans RACS — envisager une FV réfractaire",
                            label: "Texte du jalon (mis en avant au seuil, registre ambre)", maxLength: 140, resync: ed.syncTick) { v in
                        ed.updateBlock(b.id, typing: true) { x in if i < x.milestones.count { x.milestones[i].text = v } }
                    }
                    if !exs.isEmpty {
                        Picker("Renvoi du jalon vers une complication (facultatif)", selection: Binding<String>(
                            get: { j.go },
                            set: { v in edit(i) { $0.go = v } })) {
                            Text("sans renvoi").tag("")
                            ForEach(Array(exs.enumerated()), id: \.offset) { _, c in Text("⚡ " + (c.label.isEmpty ? "Complication" : c.label)).tag(c.target) }
                        }
                        .pickerStyle(.menu).labelsHidden().edLock()
                    }
                }
                .padding(8)
                .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            }
        }
    }
    private func edit(_ i: Int, _ g: @escaping (inout Milestone) -> Void) {
        ed.updateBlock(block.id, typing: false) { x in if i < x.milestones.count { g(&x.milestones[i]) } }
    }
}

// MARK: - Image d'un bloc (`imageEditor`) — « Retirer » ne fait que DÉTACHER

struct BlockImageEditor: View {
    @Bindable var ed: FicheDraft
    var block: Block
    var body: some View {
        if let img = block.image, !img.isEmpty {
            HStack(spacing: 8) {
                EdDataImage(key: "blk:" + block.id, dataURI: img)
                    .frame(width: 96, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
                    .accessibilityLabel("Image du bloc")
                Button("Retirer") {
                    ed.updateBlock(block.id, typing: false) { $0.image = nil; $0.imageW = 0; $0.imageH = 0 }
                }
                .buttonStyle(.a(.danger, Ctrl.s))
                .edLock()
            }
        } else {
            EdLinkButton(text: "+ Ajouter") { ed.imageChoice = .block(block.id) }
        }
    }
}
