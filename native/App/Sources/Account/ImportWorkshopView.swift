import SwiftUI
import UniformTypeIdentifiers
import AidesCore

// L'ATELIER D'IMPORT (A129/A131/A132/A159/A225) — port de `readImportFile`, `_importRead`,
// `importWorkshop`, `impRowHtml`, `impDestHtml`, `impSyncDest` et de la suite d'écriture.
// RIEN N'EST ÉCRIT AVANT « Importer » : l'atelier sert à RETIRER ce dont on ne veut pas (tout est
// coché au départ) et à dire OÙ chaque élément va (bibliothèque et catégorie, rangée par rangée).
// Plusieurs fichiers d'un geste : UN atelier par fichier, l'un après l'autre, chacun nommé
// (« « nom » (fichier i/n) ») ; abandonner l'un n'abandonne pas les autres.

/// Une demande d'import : la file des fichiers, et si la dernière aide importée doit s'ouvrir à la
/// fin (porte « Rédiger avec l'IA » : `pendingOpenImport`).
struct ImportRequest: Identifiable {
    let id = UUID()
    var urls: [URL]
    var openLast: Bool
    init(urls: [URL], openLast: Bool = false) { self.urls = urls; self.openLast = openLast }
}

/// Un fichier lu, passé par la porte `acceptFile('data', …)`.
struct ImportSource {
    var name: String
    var data: Data
}

/// La porte des fichiers de données (`UP_KINDS.data`) : taille avant signature.
enum ImportGate {
    static let accept: [UTType] = [.json, .zip]

    /// `upShortName` : nom sûr, ou « ce fichier » ; au-delà de 44 caractères, 41 + « … ».
    static func shortName(_ name: String) -> String {
        let s = Guard.safeFileName(.string(name))
        let n = s.isEmpty ? "ce fichier" : s
        return n.count > 44 ? String(n.prefix(41)) + "…" : n
    }

    /// Lit un fichier choisi (accès « security-scoped » sur iOS et dans le bac à sable du Mac)
    /// et le passe à la porte. Rend le fichier accepté, ou le motif du refus (texte verbatim).
    static func read(_ url: URL) -> (source: ImportSource?, refusal: String?) {
        let nom = shortName(url.lastPathComponent)
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return (nil, "« " + nom + " » est illisible.") }
        if data.isEmpty { return (nil, "« " + nom + " » est vide.") }
        if data.count > Guard.maxImportBytes {
            return (nil, "« " + nom + " » est trop volumineux (" + acctFmtBytes(Double(data.count)) + ") : "
                    + acctFmtBytes(Double(Guard.maxImportBytes)) + " maximum.")
        }
        if Guard.dataKind(data) == nil {
            // Le refus NOMME ce que le fichier est, quand on le reconnaît (`upDetect`).
            var other = ""
            if Guard.isPdf(data) { other = "un PDF" } else if Guard.imageKind(data) != nil { other = "une image" }
            return (nil, "Ici, on n’accepte que un fichier .json ou .zip (.json · .zip) — « " + nom + " » "
                    + (other.isEmpty ? "n’en est pas un." : "est " + other + "."))
        }
        return (ImportSource(name: url.lastPathComponent, data: data), nil)
    }

    /// Résumé des refus d'un dépôt multiple (toast 8 s).
    static func refusalSummary(_ bad: [String]) -> String? {
        guard let first = bad.first else { return nil }
        return "⚠ " + (bad.count > 1 ? "\(bad.count) fichiers ignorés — " + first : first)
    }
}

// MARK: - L'atelier

struct ImportWorkshopView: View {
    var request: ImportRequest
    /// Appelé à la fin de la file avec l'id de la dernière aide importée (porte IA), ou nil.
    /// Sans lui, la vue se ferme d'elle-même et ouvre cette aide.
    var onFinish: ((String?) -> Void)?

    init(request: ImportRequest, onFinish: ((String?) -> Void)? = nil) {
        self.request = request
        self.onFinish = onFinish
    }

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var started = false
    @State private var sources: [ImportSource] = []
    @State private var index = 0
    @State private var file: Importer.File?
    @State private var rows: [Importer.Row] = []
    @State private var label = ""
    @State private var openDiffs: Set<String> = []
    @State private var confirm: AcctConfirm?
    @State private var catManager: ImportCatScope?
    @State private var lastFiche: String?
    /// Ce que les fichiers précédents ont donné (le toast de l'app vit SOUS la feuille).
    @State private var notes: [String] = []

    var body: some View {
        AcctWindow(title: "Importer", maxWidth: 720, onClose: { abandon() }, closeLabel: "Annuler", confirm: importAction) {
            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(notes.enumerated()), id: \.offset) { _, n in
                        Text(n).aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            if let file {
                workshop(file)
            } else {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Lecture du fichier…").aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2)
                }
            }
        }
        .acctConfirm($confirm)
        // Seconde feuille portée par un fond : deux `.sheet` sur la même vue se disputent la présentation.
        .background { Color.clear.sheet(item: $catManager) { s in CategoryManagerView(scope: s.scope) } }
        .task {
            guard !started else { return }
            started = true
            load()
        }
    }

    // MARK: File

    private func load() {
        var ok: [ImportSource] = []
        var bad: [String] = []
        for u in request.urls {
            let r = ImportGate.read(u)
            if let s = r.source { ok.append(s) } else if let m = r.refusal { bad.append(m) }
        }
        if let m = ImportGate.refusalSummary(bad) { notes.append(m) }
        sources = ok
        index = 0
        advance()
    }

    /// Ouvre l'atelier du fichier courant, ou saute ceux qui ne se lisent pas ; fin de file → `finish`.
    private func advance() {
        while index < sources.count {
            let s = sources[index]
            let n = sources.count
            let lbl = n > 1 ? "« " + ImportGate.shortName(s.name) + " » (fichier \(index + 1)/\(n))" : ""
            do {
                let f = try Importer.read(s.data, label: lbl, currentSpace: model.store.currentSpace)
                label = lbl
                rows = Importer.rows(f, library: model.library, defaultLibrary: defaultLibrary)
                openDiffs = []
                file = f
                return
            } catch let e as ImportError {
                notes.append(e.description)
            } catch {
                notes.append("⚠ " + (lbl.isEmpty ? "Fichier" : lbl) + " illisible.")
            }
            index += 1
        }
        finish()
    }

    private func next() {
        file = nil
        rows = []
        index += 1
        advance()
    }

    private func finish() {
        file = nil
        let open = request.openLast ? lastFiche : nil
        let summary = notes.joined(separator: " ")
        if model.importRequest?.id == request.id { model.importRequest = nil }
        if let onFinish {
            if !summary.isEmpty { model.toast(summary, seconds: 8) }
            onFinish(open)
            return
        }
        dismiss()
        if !summary.isEmpty { model.toast(summary, seconds: 8) }
        if let open {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                model.openFiche(open)
            }
        }
    }

    /// ✕ / Annuler : abandonne CE fichier seulement (les suivants gardent leur atelier).
    private func abandon() {
        if file == nil { finish(); return }
        next()
    }

    /// `impLibDefaut()` : la bibliothèque affichée si elle est éditable, sinon Perso. L'accueil
    /// natif ne publie pas (encore) sa portée : Perso par défaut.
    private var defaultLibrary: String? { nil }

    // MARK: Destinations

    /// Bibliothèques partagées ÉDITABLES, triées par nom (`impLibOptions`).
    private var editableLibraries: [LibraryInfo] {
        model.profile.libraries.filter { $0.role.canEdit }.sorted { acctNameLess($0.name, $1.name) }
    }
    /// La pastille de bibliothèque ne paraît que s'il y a un choix à faire.
    private var hasLibraryChoice: Bool { !editableLibraries.isEmpty }

    private func libName(_ lib: String?) -> String {
        guard let lib else { return "Perso" }
        let n = model.library.libraryName(lib)
        return n.isEmpty ? "Bibliothèque partagée" : n
    }
    private func categories(in lib: String?) -> [Category] {
        model.categories.filter { $0.library == lib }.sorted { acctNameLess($0.name, $1.name) }
    }
    /// `impCatLabel(r)` : la pastille dit TOUJOURS le mot « Catégorie ».
    private func catLabel(_ r: Importer.Row) -> (text: String, color: String?, keep: Bool) {
        if r.destCategory == Importer.keep { return ("Catégorie du fichier : " + (r.sourceCategoryName.isEmpty ? "aucune" : r.sourceCategoryName), nil, true) }
        if r.destCategory.isEmpty { return ("Sans catégorie", nil, false) }
        if let c = model.categories.first(where: { $0.id == r.destCategory && $0.library == r.destLibrary }) {
            return ("Catégorie : " + c.name, c.color, false)
        }
        return ("Sans catégorie", nil, false)
    }

    private func setLibrary(_ lib: String?, keys: Set<String>) {
        for i in rows.indices where keys.contains(rows[i].id) {
            if rows[i].destLibrary != lib {
                rows[i].destLibrary = lib
                // Un id de catégorie n'a de sens que dans SA bibliothèque ; « sans » se garde.
                if !rows[i].destCategory.isEmpty && rows[i].destCategory != Importer.keep { rows[i].destCategory = Importer.keep }
            }
        }
    }
    private func setCategory(_ cat: String, keys: Set<String>) {
        for i in rows.indices where keys.contains(rows[i].id) { rows[i].destCategory = cat }
    }

    // MARK: Contenu

    @ViewBuilder
    private func workshop(_ f: Importer.File) -> some View {
        let n = rows.count
        Text((label.isEmpty ? "Ce fichier contient " : label + " contient ") + acctPlural(n, "élément", "éléments")
             + (f.isZip ? " et ses documents PDF" : "")
             + ". Décochez ce que vous ne voulez pas, réglez où chacun va : rien n'est écrit avant votre validation. L'état (Validée / À relire / Brouillon) est celui du fichier.")
            .aFont(TypeScale.body, .regular)
            .foregroundStyle(T.ink)
            .fixedSize(horizontal: false, vertical: true)
        tools
        band
        VStack(spacing: 8) {
            ForEach($rows) { $row in
                ImportRowView(row: $row,
                              existing: existingEntity(row),
                              diffOpen: openDiffs.contains(row.id),
                              toggleDiff: { toggleDiff(row.id) },
                              libraryPill: hasLibraryChoice ? AnyView(libraryMenu(keys: [row.id], label: libName(row.destLibrary),
                                                                                  aria: "Bibliothèque de destination : " + libName(row.destLibrary) + " — toucher pour changer")) : nil,
                              categoryPill: AnyView(categoryMenu(keys: [row.id], library: row.destLibrary, sameLibrary: true,
                                                                 label: catLabel(row))))
            }
        }
        if let w = sharedWarning {
            Text(w).aFont(TypeScale.body, .semibold).foregroundStyle(T.warn)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var checkedCount: Int { rows.filter(\.checked).count }

    private var tools: some View {
        let n = checkedCount
        return HStack(spacing: 8) {
            Button("Tout cocher") { for i in rows.indices { rows[i].checked = true } }
                .buttonStyle(.a(.secondary, Ctrl.s))
            Button("Tout décocher") { for i in rows.indices { rows[i].checked = false } }
                .buttonStyle(.a(.secondary, Ctrl.s))
            Spacer(minLength: 4)
            Text("\(n) / \(rows.count) coché\(acctS(n))")
                .aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    /// Le bandeau : il commande les rangées COCHÉES, et nomme son champ dans tous ses états.
    private var band: some View {
        let sel = rows.filter(\.checked)
        let n = sel.count
        let keys = Set(sel.map(\.id))
        let libs = Set(sel.map { $0.destLibrary ?? "" })
        let commonLib: String?? = libs.count == 1 ? .some(sel.first?.destLibrary) : nil
        let cats = Set(sel.map(\.destCategory))
        var catText = "Catégorie"
        var catColor: String? = nil
        if n > 0 {
            if cats.count != 1 { catText = "Plusieurs catégories" }
            else if let v = cats.first {
                if v == Importer.keep { catText = "Catégorie du fichier" }
                else if v.isEmpty { catText = "Sans catégorie" }
                else if case .some(let lib) = commonLib, let c = model.categories.first(where: { $0.id == v && $0.library == lib }) {
                    catText = "Catégorie : " + c.name; catColor = c.color
                } else { catText = "Plusieurs catégories" }
            }
        }
        let libText: String = n == 0 ? "Bibliothèque" : (commonLib.map { libName($0) } ?? "Plusieurs bibliothèques")
        let bandLib: String? = commonLib ?? nil
        return VStack(alignment: .leading, spacing: 8) {
            Text(n > 0 ? "Ranger " + (n > 1 ? "les \(n) cochés" : "l'élément coché") + " dans" : "Cochez au moins un élément pour choisir sa destination")
                .aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
            HStack(spacing: 8) {
                if hasLibraryChoice {
                    libraryMenu(keys: keys, label: libText, aria: "Bibliothèque de destination des éléments cochés : " + libText)
                }
                categoryMenu(keys: keys, library: bandLib, sameLibrary: commonLib != nil,
                             label: (catText, catColor, catText == "Catégorie du fichier"))
            }
            .disabled(n == 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.line))
    }

    private func libraryMenu(keys: Set<String>, label: String, aria: String) -> some View {
        let current: String?? = {
            let s = Set(rows.filter { keys.contains($0.id) }.map { $0.destLibrary ?? "" })
            return s.count == 1 ? .some(s.first.flatMap { $0.isEmpty ? nil : $0 }) : nil
        }()
        return Menu {
            Button { setLibrary(nil, keys: keys) } label: {
                if case .some(nil) = current { Label("Ma bibliothèque perso", systemImage: "checkmark") } else { Text("Ma bibliothèque perso") }
            }
            ForEach(editableLibraries) { l in
                Button { setLibrary(l.id, keys: keys) } label: {
                    let t = (l.name.isEmpty ? "Bibliothèque partagée" : l.name) + " (partagée)"
                    if case .some(.some(let c)) = current, c == l.id { Label(t, systemImage: "checkmark") } else { Text(t) }
                }
            }
        } label: {
            ImportPill(text: label, color: nil, keep: false, icon: "books.vertical")
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel(aria)
    }

    private func categoryMenu(keys: Set<String>, library: String?, sameLibrary: Bool,
                              label: (text: String, color: String?, keep: Bool)) -> some View {
        let values = Set(rows.filter { keys.contains($0.id) }.map(\.destCategory))
        let current: String? = values.count == 1 ? values.first : nil
        let aria = label.text + (label.keep ? " — la catégorie n'a pas été changée : celle du fichier sera retrouvée par son nom dans la destination, ou créée" : "") + " — toucher pour changer"
        return Menu {
            Button { setCategory(Importer.keep, keys: keys) } label: {
                if current == Importer.keep { Label("Garder la catégorie du fichier", systemImage: "checkmark") } else { Text("Garder la catégorie du fichier") }
            }
            Button { setCategory("", keys: keys) } label: {
                if current == "" { Label("Sans catégorie", systemImage: "checkmark") } else { Text("Sans catégorie") }
            }
            // Les catégories d'une destination n'ont de sens que si les rangées visées la partagent.
            if sameLibrary {
                ForEach(categories(in: library)) { c in
                    Button { setCategory(c.id, keys: keys) } label: {
                        if current == c.id { Label(c.name, systemImage: "checkmark") } else { Text(c.name) }
                    }
                }
                if model.library.canEdit(scope: library) {
                    Divider()
                    Button { catManager = ImportCatScope(scope: library) } label: { Text("＋ Nouvelle catégorie") }
                }
            }
        } label: {
            ImportPill(text: label.text, color: label.color, keep: label.keep, icon: nil)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel(aria)
    }

    /// Avertissement : ce qui part dans une bibliothèque PARTAGÉE est visible par tous ses membres.
    private var sharedWarning: String? {
        let sel = rows.filter { $0.checked && $0.destLibrary != nil }
        guard !sel.isEmpty else { return nil }
        var names: [String] = []
        for r in sel { let n = "« " + libName(r.destLibrary) + " »"; if !names.contains(n) { names.append(n) } }
        let c = sel.count
        let verb = c > 1 ? "s iront" : " ira"
        let dest = names.joined(separator: " et ")
        return "△ \(c) élément\(verb) dans \(dest) : visible\(acctS(c)) par tous les membres."
    }

    private func existingEntity(_ r: Importer.Row) -> (fiche: Fiche?, reference: Reference?) {
        guard r.existing else { return (nil, nil) }
        if let f = r.fiche { return (model.fiches.first { $0.id == f.id }, nil) }
        if let p = r.reference { return (nil, model.references.first { $0.id == p.id }) }
        return (nil, nil)
    }
    private func toggleDiff(_ k: String) {
        if openDiffs.contains(k) { openDiffs.remove(k) } else { openDiffs.insert(k) }
    }

    // MARK: Pied

    /// « Annuler » = ✕ de la barre (abandonne CE fichier) ; « Importer … » = l'action principale,
    /// à droite, seule proéminente — absente tant qu'aucun atelier n'est ouvert.
    private var importAction: AcctBarAction? {
        guard file != nil else { return nil }
        let n = checkedCount
        let label = n > 0 ? (n > 1 ? "Importer les \(n) éléments" : "Importer cet élément") : "Importer"
        return AcctBarAction(title: label, systemImage: nil, disabled: n == 0) { runImport() }
    }

    // MARK: Écriture (après l'atelier)

    private func scopeLabel(_ sel: [Importer.Row]) -> String {
        let libs = Set(sel.map { $0.destLibrary ?? "" })
        if libs.count > 1 { return "les bibliothèques choisies" }
        guard let l = libs.first, !l.isEmpty else { return "votre bibliothèque perso" }
        let n = model.library.libraryName(l)
        return "« " + (n.isEmpty ? "la bibliothèque partagée" : n) + " »"
    }

    private func runImport() {
        guard file != nil else { return }
        let sel = rows.filter(\.checked)
        let n = sel.count
        guard n > 0 else { return }
        let libs = Set(sel.map { $0.destLibrary ?? "" })
        let lbl = scopeLabel(sel)
        if n > 1 && libs.count == 1 {
            confirm = AcctConfirm(title: "Importer", message: "Import de \(n) éléments.",
                                  yes: "Fusionner avec " + lbl, no: "REMPLACER " + lbl) { r in
                switch r {
                case .yes: askDuplicates(merge: true)
                case .no: askReplace(sel: sel, scopeLabel: lbl)
                case .dismissed: break
                }
            }
        } else {
            askDuplicates(merge: true)
        }
    }

    private func askReplace(sel: [Importer.Row], scopeLabel lbl: String) {
        let hasProtos = sel.contains { $0.reference != nil }
        confirm = AcctConfirm(title: "Remplacer la bibliothèque",
                              message: "Toutes les fiches" + (hasProtos ? " et tous les protocoles" : "") + " de " + lbl
                                + " seront supprimé(e)s puis remplacé(e)s par les \(sel.count) éléments cochés. Continuer ?",
                              yes: "Tout remplacer", danger: true) { r in
            if case .yes = r { write(merge: false, replaceDuplicates: false) }
        }
    }

    private func askDuplicates(merge: Bool) {
        let c = Importer.clashes(rows, library: model.library)
        let total = c.fiches + c.references
        guard merge, total > 0 else { write(merge: merge, replaceDuplicates: false); return }
        let parts = [c.fiches > 0 ? "\(c.fiches) fiche(s)" : "", c.references > 0 ? "\(c.references) protocole(s)" : ""].filter { !$0.isEmpty }
        confirm = AcctConfirm(title: "Doublons détectés",
                              message: parts.joined(separator: " et ") + " déjà présent(e)(s) (même identifiant).",
                              yes: "Remplacer les existants", no: "Garder les deux") { r in
            switch r {
            case .yes: write(merge: true, replaceDuplicates: true)
            case .no: write(merge: true, replaceDuplicates: false)
            case .dismissed: break
            }
        }
    }

    private func write(merge: Bool, replaceDuplicates: Bool) {
        guard let f = file else { return }
        let res = Importer.apply(f, rows: rows, library: model.library, merge: merge, replaceDuplicates: replaceDuplicates)
        model.refresh()
        if let last = res.fiches.last { lastFiche = last }
        if !res.message.isEmpty { notes.append(res.message) }
        next()
    }
}

/// Portée à ouvrir dans le gestionnaire de catégories (« ＋ Nouvelle catégorie »).
struct ImportCatScope: Identifiable {
    let id = UUID()
    var scope: String?
}

/// Pastille de destination (bouton de menu) — la catégorie « du fichier » en pointillé : rien
/// n'a été décidé à votre place.
private struct ImportPill: View {
    var text: String
    var color: String?
    var keep: Bool
    var icon: String?
    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.system(size: 12, weight: .semibold)) }
            if let color { CategoryDot(color: color, size: 9) }
            Text(text).aFont(TypeScale.meta, .bold).lineLimit(2).multilineTextAlignment(.leading)
            Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold)).foregroundStyle(T.ink2)
        }
        .foregroundStyle(T.ink)
        .padding(.horizontal, 10)
        .frame(minHeight: Ctrl.s)
        .background(T.amb2, in: Capsule())
        .overlay(Capsule().strokeBorder(T.ctlLine, style: StrokeStyle(lineWidth: 1, dash: keep ? [3, 3] : [])))
    }
}

/// Une rangée de l'atelier : ce qu'il faut pour décider, et pas un mot de plus.
private struct ImportRowView: View {
    @Binding var row: Importer.Row
    var existing: (fiche: Fiche?, reference: Reference?)
    var diffOpen: Bool
    var toggleDiff: () -> Void
    var libraryPill: AnyView?
    var categoryPill: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Button { row.checked.toggle() } label: {
                    Image(systemName: row.checked ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(row.checked ? T.act : T.ctlLine)
                        .frame(width: Ctrl.l, height: Ctrl.l)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(titleText)
                .accessibilityValue(row.checked ? "cochée" : "non cochée")
                VStack(alignment: .leading, spacing: 6) {
                    Text(titleText).aFont(TypeScale.item, .bold).foregroundStyle(T.ink).lineLimit(2)
                    meta
                    HStack(spacing: 6) {
                        if let libraryPill { libraryPill }
                        categoryPill
                    }
                }
                .padding(.top, 10)
            }
            if row.existing && diffOpen { diffView }
        }
        .padding(.trailing, 12)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.workLine))
    }

    private var titleText: String {
        let t = JS.trim(row.title)
        let d = row.fiche?.discriminant ?? row.reference?.discriminant ?? ""
        return (t.isEmpty ? "Sans titre" : t) + (d.isEmpty ? "" : " — " + d)
    }

    private var meta: some View {
        let status = row.fiche?.status ?? row.reference?.status ?? .validated
        let carry = row.fiche.map { carryParts($0).joined(separator: " · ") } ?? ""
        let nd = (row.fiche?.docs.count ?? row.reference?.docs.count) ?? 0
        return ImportFlow(spacing: 8) {
            Text(row.isFiche ? "Aide" : "Référence").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
            Text(acctStatusLabel(status, feminine: row.isFiche)).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
            if row.existing {
                Text("⟳ déjà présent").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink)
                    .accessibilityLabel("déjà présente dans votre bibliothèque")
                    .help("Une entité de même identifiant est déjà dans votre bibliothèque — la question « Doublons » qui suit décide de son sort, pour toutes celles-ci à la fois")
                if let rel = row.relation, let t = Importer.relationText[rel] {
                    Text((rel == .vieux ? "△ " : "") + t).aFont(TypeScale.meta, .bold)
                        .foregroundStyle(rel == .vieux ? T.warn : T.ink2)
                }
            }
            if !carry.isEmpty { Text(carry).aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2) }
            if nd > 0 { Text("\(nd) PDF").aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2) }
            if row.existing {
                Button(diffOpen ? "Masquer" : "Comparer", action: toggleDiff)
                    .buttonStyle(.a(.quiet, Ctrl.s))
                    .accessibilityValue(diffOpen ? "déplié" : "replié")
            }
        }
    }

    /// `impDiffHtml` : « + » = ce que remplacer AJOUTERAIT, « − » = ce qu'il SUPPRIMERAIT.
    @ViewBuilder
    private var diffView: some View {
        let mine: [String] = existing.fiche.map { AcctFlatten.fiche($0) } ?? existing.reference.map { AcctFlatten.reference($0) } ?? []
        let theirs: [String] = row.fiche.map { AcctFlatten.fiche($0) } ?? row.reference.map { AcctFlatten.reference($0) } ?? []
        let d = AcctFlatten.diff(mine, theirs)
        if d.plus.isEmpty && d.minus.isEmpty {
            Text("Aucune différence de contenu — remplacer ne changerait rien (images et documents non comparés).")
                .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                .padding(.leading, 12)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            AcctDiffView(plusTitle: "Remplacer ajouterait :", minusTitle: "Remplacer supprimerait :",
                         plus: d.plus, minus: d.minus,
                         note: "Images et documents non comparés. Décocher la rangée laisse votre version intacte.")
                .padding(.leading, 12)
        }
    }

    /// `carryParts(f)` — « 6 blocs · 2 minuteurs · 1 complication déclarée » (les blocs de revue
    /// ne comptent pas comme blocs du parcours).
    private func carryParts(_ f: Fiche) -> [String] {
        let nb = f.blocks.filter { $0.kind != .review }.count
        let tl = f.timers.count, cl = f.counters.count, cx = f.excursions.count
        var p: [String] = []
        if nb > 0 { p.append("\(nb)" + (nb > 1 ? " blocs" : " bloc")) }
        if tl > 0 { p.append("\(tl)" + (tl > 1 ? " minuteurs" : " minuteur")) }
        if cl > 0 { p.append("\(cl)" + (cl > 1 ? " compteurs" : " compteur")) }
        if cx > 0 { p.append("\(cx)" + (cx > 1 ? " complications déclarées" : " complication déclarée")) }
        return p
    }
}

/// Mise en ligne qui passe à la ligne (`flex-wrap`) — iOS 16+ / macOS 13+ (`Layout`).
struct ImportFlow: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0, widest: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(ProposedViewSize(width: maxW, height: nil))
            if x > 0 && x + sz.width > maxW { y += lineH + lineSpacing; x = 0; lineH = 0 }
            x += sz.width + spacing
            lineH = max(lineH, sz.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, maxW), height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x > bounds.minX && x + sz.width > bounds.maxX { y += lineH + lineSpacing; x = bounds.minX; lineH = 0 }
            s.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(width: sz.width, height: sz.height))
            x += sz.width + spacing
            lineH = max(lineH, sz.height)
        }
    }
}
