import SwiftUI
import AidesCore

// LES FENÊTRES DES ÉDITEURS — la porte « ＋ » (`ED_PALETTE`, `edAdd`), les sélecteurs (« Voir
// aussi », cible de complication, document existant, catégorie) et « Versions précédentes ».
// Feuilles iOS 26 : détentes moyenne/grande, poignée visible, fermer (xmark) à gauche.

struct FicheSheetHost: View {
    @Bindable var ed: FicheDraft
    var sheet: FicheSheet
    @Environment(AppModel.self) private var model

    var body: some View {
        switch sheet {
        case .palette:
            FichePaletteSheet(ed: ed)
        case .step(let b, let i):
            StepSettingsSheet(ed: ed, blockId: b, itemId: i)
        case .links:
            EdLinkPicker(candidates: EdKit.relCandidates(selfId: ed.d.id, links: ed.d.links, library: ed.d.library,
                                                          fiches: model.fiches, references: model.references)) { id in
                if ed.d.links.count >= 20 { model.toast("⚠ 20 liens maximum."); return }
                ed.structural { $0.links.append(id) }
            }
        case .cxTarget(let i):
            CxTargetPicker(ed: ed, index: i)
        case .attPicker:
            EdAttPicker(candidates: EdKit.attachablePdfs(selfId: ed.d.id, docs: ed.d.docs, library: ed.d.library,
                                                         fiches: model.fiches, references: model.references)) { a in
                if ed.d.docs.count >= Guard.maxAttPerEntity { model.toast("⚠ \(Guard.maxAttPerEntity) documents maximum.", seconds: 6); return }
                ed.structural { $0.docs.append(Attachment(id: a.id, name: a.name, size: a.size)) }
            }
        case .versions:
            EdVersionsSheet(ed: ed)
        case .category:
            EdCategoryPicker(library: ed.d.library, current: ed.d.category) { id in
                ed.structural { $0.category = id }
            }
        }
    }
}

// MARK: - Coque commune des feuilles

struct EdSheetShell<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            content
                .background(T.amb)
                .navigationTitle(title)
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationSizing(.form)
    }
}

// MARK: - La porte « ＋ » d'une aide (`ED_PALETTE`)

enum FichePalette {
    enum Kind { case steps, decision, interval, stopwatch, counter, cx, review, poso, verify, diff, img, att, ref }
    struct Row: Identifiable {
        var id: String { name }
        var group: String
        var kind: Kind
        var glyph: String?
        var icon: String?
        var name: String
        var gloss: String
    }
    static let rows: [Row] = [
        Row(group: "Structure", kind: .steps, glyph: "❑", icon: nil, name: "Bloc d’étapes", gloss: "titre, puis ⏎"),
        Row(group: "Structure", kind: .decision, glyph: "◆", icon: nil, name: "Décision oui / non", gloss: "2 branches"),
        Row(group: "Pendant la session", kind: .interval, glyph: nil, icon: "alarm", name: "Minuteur ou cycle", gloss: "durée + libellé"),
        Row(group: "Pendant la session", kind: .stopwatch, glyph: nil, icon: "stopwatch", name: "Chronomètre", gloss: "temps qui monte"),
        Row(group: "Pendant la session", kind: .counter, glyph: "№", icon: nil, name: "Compteur", gloss: "chocs, doses…"),
        Row(group: "Pendant la session", kind: .cx, glyph: nil, icon: "bolt.fill", name: "Complication", gloss: "à tout moment"),
        Row(group: "Pendant la session", kind: .review, glyph: nil, icon: "square.grid.2x2", name: "Revue", gloss: "liste cochable, à tout moment"),
        Row(group: "Contenu clinique", kind: .poso, glyph: "▤", icon: nil, name: "Doses & seuils", gloss: "consulté, pas coché"),
        Row(group: "Contenu clinique", kind: .verify, glyph: "△", icon: nil, name: "À vérifier", gloss: "surveillances, pièges"),
        Row(group: "Contenu clinique", kind: .diff, glyph: "≠", icon: nil, name: "Diagnostic différentiel", gloss: "si le tableau ne colle pas"),
        Row(group: "Annexes", kind: .img, glyph: "▣", icon: nil, name: "Schéma ou capture", gloss: "associable à un bloc"),
        Row(group: "Annexes", kind: .att, glyph: nil, icon: "doc.text", name: "Document PDF", gloss: "rangé dans « Consulter »"),
        Row(group: "Annexes", kind: .ref, glyph: "❞", icon: nil, name: "Référence", gloss: "source de la fiche"),
    ]
    static let groups = ["Structure", "Pendant la session", "Contenu clinique", "Annexes"]

    /// `edAdd(f, kind, pre)` — LE point de création unique (porte « ＋ » ET propositions de la
    /// relecture). Amène ensuite sur ce qu'on vient de créer, focus dans son premier champ.
    @MainActor
    static func add(_ ed: FicheDraft, _ k: Kind, seconds: Int?) {
        switch k {
        case .steps:
            var id = ""
            ed.structural { f in id = EdKit.newDoBlock(&f) }
            ed.scrollTo("b:" + id); ed.requestFocus("bt:" + id)
        case .decision:
            let b = Block(id: Guard.uid("b"), kind: .decision, title: "", question: "",
                          options: [DecisionOption(label: "Oui", target: nil), DecisionOption(label: "Non", target: nil)])
            ed.structural { $0.blocks.append(b) }
            ed.scrollTo("b:" + b.id); ed.requestFocus("bt:" + b.id)
        case .stopwatch:
            let t = TimerDef(id: Guard.uid("t"), label: "", type: .stopwatch)
            ed.structural { $0.timers.append(t) }
            ed.scrollTo("t:" + t.id); ed.requestFocus("t:" + t.id)
        case .interval:
            let t = EdKit.newTimer(seconds: seconds)
            ed.structural { $0.timers.append(t) }
            ed.scrollTo("t:" + t.id); ed.requestFocus("t:" + t.id)
        case .counter:
            let c = EdKit.newCounter()
            ed.structural { $0.counters.append(c) }
            ed.scrollTo("n:" + c.id); ed.requestFocus("n:" + c.id)
        case .cx:
            let n = ed.d.excursions.count
            ed.structural { $0.excursions.append(Excursion(label: "", target: "")) }
            ed.scrollTo("cx:\(n)"); ed.requestFocus("cx:\(n)")
        case .review:
            let it = EdKit.newStepItem()
            let b = Block(id: Guard.uid("b"), kind: .review, title: "", items: [it.id])
            ed.structural { f in f.items.append(it); f.blocks.append(b) }
            ed.scrollTo("b:" + b.id); ed.requestFocus("bt:" + b.id)
        case .poso, .verify, .diff:
            let key: EdKit.ListKey = k == .poso ? .posology : (k == .verify ? .verify : .differentials)
            ed.structural { f in EdKit.setList(&f, key, EdKit.listOf(f, key) + [""]) }
            if let last = EdKit.listItems(ed.d, key).last { ed.scrollTo("li:" + last.id); ed.requestFocus("li:" + last.id) }
        case .ref:
            let n = ed.d.sources.count
            ed.structural { $0.sources.append("") }
            ed.scrollTo("src:\(n)"); ed.requestFocus("src:\(n)")
        case .img:
            // Le sélecteur s'ouvre APRÈS la fermeture de la porte (une seule fenêtre à la fois).
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { ed.imageChoice = .gallery }
        case .att:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { ed.fileImport = .pdf }
        }
    }
}

struct FichePaletteSheet: View {
    @Bindable var ed: FicheDraft
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        EdSheetShell(title: "Ajouter à la fiche") {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(FichePalette.groups, id: \.self) { g in
                        VStack(alignment: .leading, spacing: 2) {
                            Overline(text: g)
                            ForEach(FichePalette.rows.filter { $0.group == g }) { r in
                                EdMenuRow(icon: r.icon, glyph: r.glyph, title: r.name, sub: r.gloss) {
                                    dismiss()
                                    ed.sheet = nil
                                    FichePalette.add(ed, r.kind, seconds: nil)
                                }
                                .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Sélecteur filtrable (grammaire commune)

struct EdPickRow: Identifiable {
    var id: String
    var icon: String
    var title: String
    var sub: String
    var trailing: String
    var search: String
}

struct EdPickerList: View {
    var intro: String
    var filterPrompt: String
    var groups: [(title: String?, rows: [EdPickRow])]
    var emptyFiltered: String
    var emptyNone: String
    var onPick: (String) -> Void
    @State private var q = ""

    var body: some View {
        let nq = EdKit.norm(JS.trim(q))
        let total = groups.reduce(0) { $0 + $1.rows.count }
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if !intro.isEmpty {
                    Text(intro).aFont(TypeScale.body, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
                }
                TextField("", text: $q, prompt: Text(filterPrompt).foregroundColor(T.ink3))
                    .textFieldStyle(.plain)
                    .aFont(TypeScale.item, .regular)
                    .padding(.horizontal, 12).frame(minHeight: Ctrl.m)
                    .background(T.work, in: Capsule())
                    .accessibilityLabel(filterPrompt)
                let shown = groups.map { g in (g.title, g.rows.filter { nq.isEmpty || EdKit.norm($0.search).contains(nq) }) }
                if shown.allSatisfy({ $0.1.isEmpty }) {
                    Text(total == 0 ? emptyNone : emptyFiltered).aFont(TypeScale.body, .regular).foregroundStyle(T.ink2).padding(.top, 8)
                }
                ForEach(Array(shown.enumerated()), id: \.offset) { _, g in
                    if !g.1.isEmpty {
                        if let t = g.0 { Overline(text: t).padding(.top, 6) }
                        ForEach(g.1) { r in row(r) }
                    }
                }
            }
            .padding(16)
        }
    }
    @ViewBuilder private func row(_ r: EdPickRow) -> some View {
        Button { onPick(r.id) } label: {
            HStack(spacing: 10) {
                Image(systemName: r.icon).foregroundStyle(r.icon == "bolt.fill" ? T.bolt : T.ink2).frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(r.title).aFont(TypeScale.item, .semibold).foregroundStyle(T.ink).lineLimit(2)
                    if !r.sub.isEmpty { Text(r.sub).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).lineLimit(1) }
                }
                Spacer(minLength: 6)
                if !r.trailing.isEmpty { Text(r.trailing).aFont(TypeScale.meta, .semibold, .mono).foregroundStyle(T.ink2) }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: Ctrl.row, alignment: .leading)
            .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// « Lier une aide ou un protocole » (`#relPickModal`).
struct EdLinkPicker: View {
    var candidates: [EdKit.RelCandidate]
    var onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        EdSheetShell(title: "Lier une aide ou un protocole") {
            EdPickerList(intro: "Le lien apparaît en lecture, dans la section « Voir aussi » — un raccourci, pas une copie.",
                         filterPrompt: "Filtrer par titre ou code…",
                         groups: [(nil, candidates.map { c in
                             EdPickRow(id: c.id, icon: c.isReference ? "book" : "doc.text", title: c.title,
                                       sub: c.isReference ? "Protocole" : "Aide cognitive", trailing: c.code, search: c.title + " " + c.code)
                         })],
                         emptyFiltered: "Aucune fiche ne correspond au filtre.",
                         emptyNone: "Aucune fiche disponible.") { id in
                onPick(id)
                dismiss()
            }
        }
    }
}

/// « Joindre un document existant » (`#attPickModal`) : le même blob, partagé.
struct EdAttPicker: View {
    var candidates: [EdKit.AttCandidate]
    var onPick: (EdKit.AttCandidate) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        EdSheetShell(title: "Joindre un document existant") {
            EdPickerList(intro: "Le document sera partagé : le remplacer le mettra à jour sur toutes les fiches et tous les protocoles qui l'utilisent.",
                         filterPrompt: "Filtrer par nom ou origine…",
                         groups: [(nil, candidates.map { a in
                             EdPickRow(id: a.id, icon: "doc.text", title: a.name, sub: a.from, trailing: EdKit.fmtBytes(a.size), search: a.name + " " + a.from)
                         })],
                         emptyFiltered: "Aucun document ne correspond au filtre.",
                         emptyNone: "Aucun document disponible.") { id in
                if let a = candidates.first(where: { $0.id == id }) { onPick(a) }
                dismiss()
            }
        }
    }
}

/// « Cible de la complication » : un bloc de cette aide, ou une autre aide / un protocole.
/// (Question ouverte n° 8 : comme le web, toutes les bibliothèques sont proposées.)
struct CxTargetPicker: View {
    @Bindable var ed: FicheDraft
    var index: Int
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let f = ed.d
        let flow = f.blocks.filter { $0.kind != .review }
        let blocks: [EdPickRow] = flow.enumerated().map { i, b in
            let t = JS.trim(b.title)
            let name = t.isEmpty ? "Bloc sans titre (\(i + 1))" : t
            return EdPickRow(id: b.id, icon: "bolt.fill", title: name, sub: "", trailing: "", search: name)
        }
        let fs: [EdPickRow] = model.fiches.filter { $0.id != f.id }.map { x in
            EdPickRow(id: x.id, icon: "doc.text", title: x.title.isEmpty ? "Sans titre" : x.title, sub: "", trailing: x.code, search: x.title + " " + x.code)
        }
        let ps: [EdPickRow] = model.references.map { x in
            EdPickRow(id: x.id, icon: "book", title: x.title.isEmpty ? "Sans titre" : x.title, sub: "", trailing: x.code, search: x.title + " " + x.code)
        }
        let others = (fs + ps).sorted { EdKit.titleLess($0.title, $1.title) }
        return EdSheetShell(title: "Cible de la complication") {
            EdPickerList(intro: "", filterPrompt: "Filtrer par titre ou code…",
                         groups: [("Blocs de cette fiche", blocks), ("Aides & protocoles", others)],
                         emptyFiltered: "Rien ne correspond au filtre.",
                         emptyNone: "Rien ne correspond au filtre.") { id in
                ed.structural { x in if index < x.excursions.count { x.excursions[index].target = id } }
                dismiss()
            }
        }
    }
}

// MARK: - Catégorie (`openCatMenu`)

struct EdCategoryPicker: View {
    var library: String?
    var current: String
    var onPick: (String) -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var q = ""
    @State private var askNew = false
    @State private var newName = ""

    var body: some View {
        let cats = model.categories.filter { $0.library == library }
        let nq = EdKit.norm(JS.trim(q))
        let shown = cats.filter { nq.isEmpty || EdKit.norm($0.name).contains(nq) }
        EdSheetShell(title: "Catégorie") {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if cats.count > 8 {
                        TextField("", text: $q, prompt: Text("Filtrer…").foregroundColor(T.ink3))
                            .textFieldStyle(.plain).aFont(TypeScale.item, .regular)
                            .padding(.horizontal, 12).frame(minHeight: Ctrl.m)
                            .background(T.work, in: Capsule())
                            .accessibilityLabel("Filtrer…")
                    }
                    ForEach(shown) { c in
                        Button { onPick(c.id); dismiss() } label: {
                            HStack(spacing: 10) {
                                CategoryDot(color: c.color, size: 12)
                                Text(c.name).aFont(TypeScale.item, .semibold).foregroundStyle(T.ink)
                                Spacer()
                                if c.id == current { Image(systemName: "checkmark").foregroundStyle(T.act) }
                            }
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, minHeight: Ctrl.l, alignment: .leading)
                            .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(c.id == current ? [.isSelected] : [])
                    }
                    EdLinkButton(text: "＋ Nouvelle catégorie") { newName = ""; askNew = true }
                        .padding(.top, 4)
                }
                .padding(16)
            }
        }
        .alert("＋ Nouvelle catégorie", isPresented: $askNew) {
            TextField("Nom", text: $newName)
            Button("Créer") {
                if let c = model.library.addCategory(name: newName, scope: library) {
                    model.refresh()
                    onPick(c.id)
                    dismiss()
                }
            }
            Button("Annuler", role: .cancel) {}
        }
    }
}

// MARK: - Versions précédentes (`openVersions`, `renderVersions`, `diffFiches`)

struct EdVersionsSheet: View {
    @Bindable var ed: FicheDraft
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var open: String?
    @State private var restoreAsk: Backup?

    var body: some View {
        let shared = ed.d.library != nil
        let list = model.library.backups(of: ed.d.id)
        EdSheetShell(title: shared ? "Récupérer ma version écrasée" : "Versions précédentes") {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(shared
                         ? "Vos versions écrasées par une modification d’un coéquipier (dernière écriture appliquée). Sauvegardes locales à cet appareil — ce n’est pas l’historique partagé de l’équipe. Restaurer remplace la fiche actuelle par la version choisie."
                         : "Sauvegardes locales créées avant qu’une version venue d’un autre appareil ne remplace la vôtre. Restaurer remplace la fiche actuelle par la version choisie.")
                        .aFont(TypeScale.body, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
                    if list.isEmpty {
                        Text("Aucune version précédente conservée pour cette fiche.").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                    }
                    ForEach(list, id: \.bid) { b in row(b) }
                }
                .padding(16)
            }
        }
        .alert("Restaurer cette version ?", isPresented: Binding(get: { restoreAsk != nil }, set: { if !$0 { restoreAsk = nil } })) {
            Button("Restaurer") { if let b = restoreAsk { restore(b) } }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Restaurer cette version ? La fiche actuelle sera remplacée (et sauvegardée à son tour).")
        }
    }
    @ViewBuilder private func row(_ b: Backup) -> some View {
        WorkCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(Fmt.localeString(b.at)).aFont(TypeScale.item, .semibold, .mono).foregroundStyle(T.ink)
                    Spacer()
                    Button(open == b.bid ? "Masquer" : "Comparer") { open = open == b.bid ? nil : b.bid }
                        .buttonStyle(.a(.secondary, Ctrl.s))
                    Button("Restaurer") { restoreAsk = b }.buttonStyle(.a(.secondary, Ctrl.s))
                }
                if open == b.bid { diff(b) }
            }
        }
    }
    @ViewBuilder private func diff(_ b: Backup) -> some View {
        if b.data.object == nil {
            Text("Version illisible.").aFont(TypeScale.body, .semibold).foregroundStyle(T.warn)
        } else {
            let old = backupFiche(b)
            let cur = model.fiches.first { $0.id == ed.d.id } ?? EdKit.snapshot(ed.d)
            let d = EdKit.diffLines(cur: cur, old: old)
            if d.added.isEmpty && d.removed.isEmpty {
                Text("Aucune différence de contenu (les images ne sont pas comparées).").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    if !d.added.isEmpty {
                        Text("Restaurer rétablirait :").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink)
                        ForEach(Array(d.added.enumerated()), id: \.offset) { _, x in
                            Text("+ " + x).aFont(TypeScale.meta, .regular, .mono).foregroundStyle(T.ok).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if !d.removed.isEmpty {
                        Text("Restaurer supprimerait :").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink).padding(.top, 4)
                        ForEach(Array(d.removed.enumerated()), id: \.offset) { _, x in
                            Text("− " + x).aFont(TypeScale.meta, .regular, .mono).foregroundStyle(T.warn).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Text("Images non comparées. La version actuelle est sauvegardée avant toute restauration.")
                        .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).padding(.top, 4)
                }
            }
        }
    }
    private func backupFiche(_ b: Backup) -> Fiche {
        var o = b.data.object ?? [:]
        o["id"] = .string(b.ficheId)
        return Sanitize.fiche(.object(o))
    }
    /// Restaurer : la version courante est sauvegardée d'abord ; le brouillon ouvert repart de la
    /// version restaurée (question ouverte n° 7 : sinon l'écriture suivante l'écraserait).
    private func restore(_ b: Backup) {
        ed.flush()
        if let f = model.library.restore(b) {
            model.refresh()
            ed.reload(from: f)
        }
        restoreAsk = nil
        dismiss()
    }
}
