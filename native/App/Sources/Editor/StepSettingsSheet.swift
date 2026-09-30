import SwiftUI
import AidesCore

// « RÉGLAGES DE L'ÉTAPE » (A383, `stepSetHtml`) — UNE feuille, trois sections nommées :
// importance · ce que fait la coche · moment. Ce qui ne peut servir à rien n'est pas montré
// (moment seulement si le bloc se répète ou s'il est déjà posé). Chaque réglage est un geste
// STRUCTUREL (point de reprise + écriture immédiate) ; la rangée repeint ses pastilles derrière.

struct StepSettingsSheet: View {
    @Bindable var ed: FicheDraft
    var blockId: String
    var itemId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if let b = ed.block(blockId), let it = ed.item(itemId) {
                    StepSettingsBody(ed: ed, block: b, item: it, onDelete: deleteStep)
                        .padding(16)
                }
            }
            .background(T.amb)
            .navigationTitle("Réglages de l’étape")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Image(systemName: "checkmark") }
                        .accessibilityLabel("OK")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationSizing(.form)
    }

    /// « Supprimer l’étape » : sans confirmation (l'anneau d'annulation couvre le geste) ; le bloc
    /// ne reste jamais vide ; le focus va à l'étape voisine.
    private func deleteStep() {
        guard let b = ed.block(blockId), let i = b.items.firstIndex(of: itemId) else { dismiss(); return }
        ed.deleteStep(block: blockId, item: itemId)
        dismiss()
        if let nb = ed.block(blockId), !nb.items.isEmpty {
            ed.requestFocus("s:" + nb.items[min(i, nb.items.count - 1)])
        }
    }
}

struct StepSettingsBody: View {
    @Bindable var ed: FicheDraft
    var block: Block
    var item: Item
    var onDelete: () -> Void

    var body: some View {
        let it = item, b = block
        let i = b.items.firstIndex(of: it.id) ?? 0
        VStack(alignment: .leading, spacing: 14) {
            Text(recap(it, i)).aFont(TypeScale.item, .semibold).foregroundStyle(T.ink).fixedSize(horizontal: false, vertical: true)
            heading("Importance")
            EdSeg(options: [(1, "Normale"), (2, "△ Vigilance"), (3, "⚠ Critique")], selection: it.level, accessibility: "Importance") { lv in
                apply { $0.level = lv }
            }
            EdToggleRow(title: "★ Rappel en mémoire", sub: "affichée aussi dans « Ne pas oublier »", isOn: it.memory) { v in apply { $0.memory = v } }
            EdToggleRow(title: "Double contrôle", sub: "en session, marquée « Double contrôle » : les deux soignants la vérifient à voix haute", isOn: it.dual) { v in apply { $0.dual = v } }
            heading("Ce que fait la coche")
            StepLinkSection(ed: ed, item: it)
            StepRefsSection(ed: ed, block: b, item: it)
            if it.review == nil {
                StepMomentSection(ed: ed, block: b, item: it)
            }
            Divider().padding(.top, 4)
            Button("Supprimer l’étape", role: .destructive, action: onDelete)
                .buttonStyle(.a(.danger, Ctrl.m))
        }
    }
    private func recap(_ it: Item, _ i: Int) -> String {
        let d = JS.trim(it.do)
        return (d.isEmpty ? "Étape \(i + 1)" : d) + (JS.trim(it.expect).isEmpty ? "" : " — " + it.expect)
    }
    private func apply(_ g: (inout Item) -> Void) { ed.updateItem(item.id, typing: false, g) }
    @ViewBuilder private func heading(_ t: String) -> some View {
        Text(t).aFont(TypeScale.body, .bold).foregroundStyle(T.ink2).padding(.top, 4)
    }
}

/// « Ce que fait la coche » : lance un minuteur OU compte (exclusifs), ou rien ; sans minuteur ni
/// compteur dans la fiche, deux boutons les créent d'ici (nommés d'après l'étape).
struct StepLinkSection: View {
    @Bindable var ed: FicheDraft
    var item: Item

    var body: some View {
        let f = ed.d, it = item
        if f.timers.isEmpty && f.counters.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("La fiche n’a ni minuteur ni compteur.").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                HStack(spacing: 8) {
                    Button("＋ Créer un minuteur") { create(timer: true) }.buttonStyle(.a(.secondary, Ctrl.s))
                    Button("＋ Créer un compteur") { create(timer: false) }.buttonStyle(.a(.secondary, Ctrl.s))
                }
            }
        } else {
            let cur = it.starts.map { "t:" + $0 } ?? (it.counts.map { "n:" + $0 } ?? "")
            Picker("Ce que fait la coche", selection: Binding<String>(
                get: { cur },
                set: { v in
                    ed.updateItem(it.id, typing: false) { x in
                        x.starts = nil; x.counts = nil
                        if v.hasPrefix("t:") { x.starts = String(v.dropFirst(2)) }
                        else if v.hasPrefix("n:") { x.counts = String(v.dropFirst(2)) }
                    }
                })) {
                Text("Rien d’autre").tag("")
                if !f.timers.isEmpty {
                    Section("La coche lance") {
                        ForEach(f.timers) { t in Text(EdKit.timerOptionLabel(t)).tag("t:" + t.id) }
                    }
                }
                if !f.counters.isEmpty {
                    Section("La coche compte") {
                        ForEach(f.counters) { c in Text("＋\(max(1, c.step)) " + EdKit.counterName(c)).tag("n:" + c.id) }
                    }
                }
            }
            .pickerStyle(.menu)
            .help("La coche peut lancer un minuteur ou compter — à réserver aux gestes essentiels")
            .accessibilityLabel("Ce que fait la coche")
        }
    }
    /// `newTimerObj(120, label)` / `newCounterObj(label)` : libellé = les 40 premiers caractères de l'étape.
    private func create(timer: Bool) {
        let l = JS.prefix(JS.trim(Steps.text(item.legacyString)), 40)
        let iid = item.id
        ed.structural { f in
            guard let k = f.items.firstIndex(where: { $0.id == iid }) else { return }
            if timer {
                let t = EdKit.newTimer(seconds: 120, label: l)
                f.timers.append(t)
                f.items[k].starts = t.id; f.items[k].counts = nil
            } else {
                let c = EdKit.newCounter(label: l)
                f.counters.append(c)
                f.items[k].counts = c.id; f.items[k].starts = nil
            }
        }
    }
}

/// Revue ouverte par l'étape (A396) et repère posologique lié (A397) — rien si la fiche n'en a pas.
struct StepRefsSection: View {
    @Bindable var ed: FicheDraft
    var block: Block
    var item: Item

    var body: some View {
        let f = ed.d, it = item
        let revs = block.kind == .review ? [] : f.blocks.filter { $0.kind == .review }
        let doses = Pool.roleItems(f, .dose)
        VStack(alignment: .leading, spacing: 8) {
            if !revs.isEmpty {
                Text("Revue").aFont(TypeScale.body, .bold).foregroundStyle(T.ink2).padding(.top, 4)
                Picker("Revue ouverte par cette étape", selection: Binding<String>(
                    get: { it.review ?? "" },
                    set: { v in
                        ed.updateItem(it.id, typing: false) { x in
                            if v.isEmpty { x.review = nil; return }
                            x.review = v
                            x.do = JS.prefix(JS.trim(f.blocks.first { $0.id == v }?.title ?? ""), 500)
                            x.expect = ""
                            x.from = nil
                            x.repeat = nil
                        }
                    })) {
                    Text("Aucune — une étape ordinaire").tag("")
                    ForEach(revs) { r in Text("▦ " + (r.title.isEmpty ? "Revue" : r.title)).tag(r.id) }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Revue ouverte par cette étape")
                Text("L’étape prend le nom de la revue ; ses hypothèses se cochent dans sa boîte, sans retenir « Continuer ».")
                    .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
            }
            if !doses.isEmpty {
                Text("Repère posologique").aFont(TypeScale.body, .bold).foregroundStyle(T.ink2).padding(.top, 4)
                Picker("Repère posologique lié", selection: Binding<String>(
                    get: { it.poso ?? "" },
                    set: { v in ed.updateItem(it.id, typing: false) { $0.poso = v.isEmpty ? nil : v } })) {
                    Text("Aucun").tag("")
                    ForEach(doses) { d in Text(doseName(d)).tag(d.id) }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Repère posologique lié")
                Text("En session, le repère rejoint « Repères de ce bloc » au pied du bloc, avec son état : fait · à faire · à préparer.")
                    .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private func doseName(_ d: Item) -> String {
        let n = EdKit.posoParts(d.legacyString).name
        return n.isEmpty ? JS.prefix(Steps.text(d.legacyString), 40) : n
    }
}

/// Le MOMENT (A382) : « Dès le 1ᵉʳ passage » / « À partir d’un compte », puis « Puis revient ».
struct StepMomentSection: View {
    @Bindable var ed: FicheDraft
    var block: Block
    var item: Item

    var body: some View {
        let f = ed.d, it = item
        let loop = Graph.inLoop(f, block.id)
        let cs = f.counters
        let tid = Moments.timerId(f, it)
        let T0 = f.timers.first { $0.id == tid }
        if loop || it.from != nil || it.repeat != nil {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 4) {
                    Text("Moment").aFont(TypeScale.body, .bold).foregroundStyle(T.ink2)
                    if loop { Text("· le bloc se répète").aFont(TypeScale.body, .regular).italic().foregroundStyle(T.ink2) }
                }
                .padding(.top, 4)
                EdSeg(options: [(0, "Dès le 1ᵉʳ passage"), (1, "À partir d’un compte")], selection: it.from == nil ? 0 : 1,
                      disabled: cs.isEmpty ? [1] : [], accessibility: "Moment") { v in
                    if v == 0 { apply { $0.from = nil } }
                    else if let first = cs.first {
                        apply { x in x.from = ItemFrom(counter: x.from?.counter ?? first.id, n: x.from?.n ?? 3) }
                    }
                }
                if let fr = it.from {
                    HStack(spacing: 8) {
                        Picker("Compteur", selection: Binding<String>(
                            get: { fr.counter },
                            set: { v in apply { x in x.from = ItemFrom(counter: v, n: x.from?.n ?? 3) } })) {
                            ForEach(cs) { c in Text(EdKit.counterName(c)).tag(c.id) }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Compteur")
                        EdStepper(value: fr.n, label: "Seuil du compteur") { n in
                            apply { x in if let c = x.from?.counter { x.from = ItemFrom(counter: c, n: n) } }
                        }
                    }
                } else if cs.isEmpty {
                    Text("La fiche n’a pas de compteur.").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                }
                Text("Puis revient").aFont(TypeScale.body, .bold).foregroundStyle(T.ink2).padding(.top, 4)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    radio(nil, "À chaque passage", "", disabled: false, cur: it.repeat)
                    radio(.due, "À l’échéance", T0.map { "de « " + EdKit.timerName($0) + " »" } ?? "aucun minuteur lié",
                          disabled: tid.isEmpty && it.repeat != .due, cur: it.repeat)
                    radio(.once, "Une seule fois", "", disabled: false, cur: it.repeat)
                    radio(.need, "Au besoin", "", disabled: false, cur: it.repeat)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Puis revient")
                if it.repeat == .due && tid.isEmpty {
                    Text("△ La coche ne relance aucun minuteur : l’étape est lue « à chaque passage ».")
                        .aFont(TypeScale.meta, .semibold).foregroundStyle(T.warn).fixedSize(horizontal: false, vertical: true)
                }
            }
        } else {
            Text("Le moment d’une étape — à partir d’un compte, à une échéance, une seule fois — se règle dans un bloc qui se répète.")
                .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }
    @ViewBuilder private func radio(_ v: Repeat?, _ l: String, _ sub: String, disabled: Bool, cur: Repeat?) -> some View {
        let on = v == cur
        Button { apply { $0.repeat = v } } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: on ? "largecircle.fill.circle" : "circle").foregroundStyle(on ? T.act : T.ink3)
                    Text(l).aFont(TypeScale.body, .bold).foregroundStyle(disabled ? T.ink3 : T.ink)
                }
                if !sub.isEmpty { Text(sub).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).lineLimit(2) }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: Ctrl.row, alignment: .leading)
            .background(on ? T.primarySoft : T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(on ? T.act : T.line))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }
    private func apply(_ g: (inout Item) -> Void) { ed.updateItem(item.id, typing: false, g) }
}
