import Foundation

// IMPORT / EXPORT — port d'`exportData`, `_importRead`, `normalizeImport`, `impRowsOf`,
// l'algorithme d'écriture qui suit l'« atelier », `importAtts`, `dupToPerso`.
//
// FORMAT : enveloppe `version: 3` (inchangée alors que les entités sont v4 — le zip n'est qu'un
// emballage : un client antérieur peut en extraire donnees.json). Sessions, notes, épingles,
// préférences et versions ne sont JAMAIS exportées. Un import n'ÉCRASE JAMAIS un binaire PDF déjà
// présent, et ne s'écrit qu'après validation de l'atelier.

public enum Exporter {
    /// `strip` : champs purement LOCAUX retirés (le contenu importé ailleurs devient celui de l'importateur).
    static func strip(_ j: JSON) -> JSON {
        guard var o = j.object else { return j }
        o["dirty"] = nil; o["ownerId"] = nil; o["library"] = nil
        return .object(o)
    }
    /// L'enveloppe JSON. `categories` nil = celles réellement utilisées par le contenu.
    public static func envelope(fiches: [Fiche], references: [Reference], categories: [Category]?, all: [Category], space: String) -> JSON {
        let used = Set(fiches.map(\.category) + references.map(\.category))
        let cats = categories ?? all.filter { used.contains($0.id) }
        var o: [String: JSON] = ["version": 3, "origin": .string(LocalStore.spaceTag(space)),
                                 "categories": .array(cats.map(\.exportJSON)), "fiches": .array(fiches.map { strip($0.json) })]
        if !references.isEmpty { o["protocols"] = .array(references.map { strip($0.json) }) }
        return .object(o)
    }
    /// Documents référencés, dédoublonnés, dans l'ordre de première apparition.
    public static func attachmentIds(fiches: [Fiche], references: [Reference]) -> [String] {
        var seen = Set<String>(), out: [String] = []
        for d in fiches.flatMap(\.docs) + references.flatMap(\.docs) where !seen.contains(d.id) { seen.insert(d.id); out.append(d.id) }
        return out
    }
    /// Nom de fichier : `base-AAAA-MM-JJ.ext` (date UTC, comme `toISOString`).
    public static func fileName(base: String, ext: String, now: Double = JS.now()) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(identifier: "UTC"); f.dateFormat = "yyyy-MM-dd"
        return base + "-" + f.string(from: Date(timeIntervalSince1970: now / 1000)) + "." + ext
    }
    /// `fileSlug` : identifiant de nom de fichier (≤ 40, repli « fiche »).
    public static func slug(_ s: String) -> String {
        let r = String(Library.catSlug(s).prefix(40))
        return r.isEmpty ? "fiche" : r
    }
    /// Construit le fichier : .json seul, ou .zip avec `documents/<id>.pdf`. Rend aussi le nombre
    /// de documents absents de l'appareil (référencés mais pas encore téléchargés).
    public static func build(envelope: JSON, withDocuments: Bool, attachmentIds: [String], store: SpaceStore) -> (data: Data, isZip: Bool, missing: Int) {
        let json = envelope.data(pretty: true)
        guard withDocuments else { return (json, false, 0) }
        var entries = [Zip.Entry(name: "donnees.json", data: json)]
        var missing = 0
        for id in attachmentIds {
            if let d = store.attachmentData(id) { entries.append(Zip.Entry(name: "documents/\(id).pdf", data: d)) } else { missing += 1 }
        }
        return (Zip.build(entries), true, missing)
    }
    public static let docsQuestion: (Int) -> String = { n in
        (n > 1 ? "Ce contenu référence \(n) documents PDF joints." : "Ce contenu référence un document PDF joint.") + " Les inclure dans le fichier exporté ?"
    }
    public static let jsonOnlyNotice = "Les documents PDF joints ne sont pas inclus dans le fichier exporté ; ils suivent votre compte via la synchronisation."
    public static func missingNotice(_ n: Int) -> String {
        "⚠ \(n) document(s) pas encore téléchargé(s) sur cet appareil : référence(s) exportée(s) sans le fichier. Synchronisez avec du réseau puis ré-exportez pour les inclure."
    }
}

public enum ImportError: Error, CustomStringConvertible {
    case unreadable(String)
    case notAnExport(String)
    case empty(String)
    public var description: String {
        switch self {
        case .unreadable(let l): return "⚠ \(l.isEmpty ? "Fichier" : l) illisible."
        case .notAnExport(let l): return "⚠ \(l.isEmpty ? "Ce fichier" : l) est un JSON valide, mais il ne contient ni « aids » ni « fiches » : ce n'est pas un export de l'application."
        case .empty(let l): return "\(l.isEmpty ? "Ce fichier" : l) ne contient aucune aide ni référence — rien à importer."
        }
    }
}

public enum Importer {
    public static let keep = "~garder"   // IMP_KEEP : sentinelle qui ne peut PAS être un identifiant

    public struct File {
        public var imp: JSON
        public var zipAttachments: [String: Data]
        public var sameSpace: Bool
        public var isZip: Bool
    }

    /// `_importRead` : .zip (par SIGNATURE) ou .json, clôtures d'IA tolérées.
    public static func read(_ data: Data, label: String = "", currentSpace: String) throws -> File {
        var text: String
        var atts: [String: Data] = [:]
        let zip = Zip.looksLikeZip(data)
        if zip {
            let entries = try Zip.parse(data)
            guard let j = entries.first(where: { $0.name == "donnees.json" || $0.name.hasSuffix("/donnees.json") })
                    ?? entries.first(where: { $0.name.lowercased().hasSuffix(".json") }) else { throw ImportError.unreadable(label) }
            text = String(decoding: j.data, as: UTF8.self)
            for e in entries where e.name.hasPrefix("documents/") && e.name.hasSuffix(".pdf") {
                let id = String(e.name.dropFirst("documents/".count).dropLast(4))
                if Guard.matchesSafeIdPattern(id) { atts[id] = e.data }
            }
        } else {
            text = String(decoding: data, as: UTF8.self)
        }
        let parsed: JSON
        do { parsed = try JSON.parse(Guard.stripJsonFences(text)) } catch { throw ImportError.unreadable(label) }
        let imp = normalize(parsed.array != nil ? ["fiches": parsed, "categories": []] : parsed)
        guard imp["fiches"]?.array != nil || imp["protocols"]?.array != nil else { throw ImportError.notAnExport(label) }
        if (imp["fiches"]?.array ?? []).isEmpty && (imp["protocols"]?.array ?? []).isEmpty { throw ImportError.empty(label) }
        let same = imp["origin"]?.string == LocalStore.spaceTag(currentSpace)
        return File(imp: imp, zipAttachments: atts, sameSpace: same, isZip: zip)
    }

    /// `normalizeImport` : `aids` accepté pour `fiches`, entrées `kind:'reference'` routées vers les références.
    public static func normalize(_ imp: JSON) -> JSON {
        guard var out = imp.object else { return ["fiches": [], "categories": []] }
        if out["fiches"]?.array == nil, let a = out["aids"], a.array != nil { out["fiches"] = a }
        out["aids"] = nil
        guard let list = out["fiches"]?.array else { return .object(out) }
        let refs = list.filter { $0.object != nil && $0["kind"]?.string == "reference" }
        let aides = list.filter { !($0.object != nil && $0["kind"]?.string == "reference") }
        out["fiches"] = .array(aides)
        if !refs.isEmpty { out["protocols"] = .array((out["protocols"]?.array ?? []) + refs) }
        return .object(out)
    }

    public enum Relation: String { case neuf, vieux, egal }
    public static let relationText: [Relation: String] = [.neuf: "le fichier est plus récent", .vieux: "votre version est plus récente", .egal: "même version"]

    /// Une rangée de l'atelier.
    public struct Row: Identifiable {
        public var id: String        // 'f:i' | 'p:i'
        public var fiche: Fiche?
        public var reference: Reference?
        public var existing: Bool
        public var relation: Relation?
        public var sourceCategoryName: String
        public var checked = true
        public var destLibrary: String?
        public var destCategory: String = Importer.keep
        public var title: String { fiche?.title ?? reference?.title ?? "" }
        public var isFiche: Bool { fiche != nil }
    }

    /// `impRowsOf` : chaque entité passe par migrate AVANT d'être montrée.
    public static func rows(_ file: File, library: Library, defaultLibrary: String?) -> [Row] {
        let srcCats = Sanitize.categories(file.imp["categories"])
        func srcName(_ id: String) -> String { srcCats.first { $0.id == id }?.name ?? "" }
        func rel(_ a: Double?, _ b: Double) -> Relation? {
            guard let a, a.isFinite, b.isFinite else { return nil }
            return a == b ? .egal : (a > b ? .neuf : .vieux)
        }
        var out: [Row] = []
        for (i, raw) in (file.imp["fiches"]?.array ?? []).enumerated() {
            let av = raw["updatedAt"]?.number
            let o = Sanitize.fiche(raw)
            let mine = file.sameSpace ? library.fiches.first { $0.id == o.id } : nil
            out.append(Row(id: "f:\(i)", fiche: o, reference: nil, existing: mine != nil, relation: mine.flatMap { rel(av, $0.updatedAt) },
                           sourceCategoryName: srcName(o.category), destLibrary: defaultLibrary))
        }
        for (i, raw) in (file.imp["protocols"]?.array ?? []).enumerated() {
            let av = raw["updatedAt"]?.number
            let o = Sanitize.reference(raw)
            let mine = file.sameSpace ? library.protocols.first { $0.id == o.id } : nil
            out.append(Row(id: "p:\(i)", fiche: nil, reference: o, existing: mine != nil, relation: mine.flatMap { rel(av, $0.updatedAt) },
                           sourceCategoryName: srcName(o.category), destLibrary: defaultLibrary))
        }
        return out
    }

    /// Nombre de doublons (même identifiant) parmi les rangées cochées, en mode fusion.
    public static func clashes(_ rows: [Row], library: Library) -> (fiches: Int, references: Int) {
        let ef = Set(library.fiches.map(\.id)), ep = Set(library.protocols.map(\.id))
        let sel = rows.filter(\.checked)
        return (sel.filter { $0.fiche.map { ef.contains($0.id) } ?? false }.count,
                sel.filter { $0.reference.map { ep.contains($0.id) } ?? false }.count)
    }

    public struct Result {
        public var fiches: [String] = []
        public var references: [String] = []
        public var message: String = ""
    }

    /// L'écriture après l'atelier. `merge` false = REMPLACER la bibliothèque de destination
    /// (question posée par l'interface) ; `replaceDuplicates` = « Remplacer les existants ».
    public static func apply(_ file: File, rows: [Row], library: Library, merge: Bool, replaceDuplicates: Bool) -> Result {
        let sel = rows.filter(\.checked)
        let libs = Array(Set(sel.map { $0.destLibrary ?? "" }))
        let scopeLbl = libs.count > 1 ? "les bibliothèques choisies"
            : (libs.first.map { $0.isEmpty ? "votre bibliothèque perso" : "« " + (library.libraryName($0).isEmpty ? "la bibliothèque partagée" : library.libraryName($0)) + " »" } ?? "votre bibliothèque perso")
        let hasRefs = sel.contains { $0.reference != nil }
        if !merge, let lib = libs.first {
            let scope: String? = lib.isEmpty ? nil : lib
            for f in library.fiches where f.library == scope { library.delete(f) }
            if hasRefs { for p in library.protocols where p.library == scope { library.delete(p) } }
        }
        let srcCats = Sanitize.categories(file.imp["categories"])
        var catMap: [String: String] = [:]
        var touched = Set<String>()
        func resolve(_ lib: String?, _ id: String) -> String {
            let k = (lib ?? "") + "\u{0}" + id
            if let c = catMap[k] { return c }
            guard let c = srcCats.first(where: { $0.id == id }) else { catMap[k] = ""; return "" }
            let slug = Library.catSlug(c.name)
            if !slug.isEmpty, let d = library.categories(in: lib).first(where: { Library.catSlug($0.name) == slug }) { catMap[k] = d.id; return d.id }
            let nid = library.categories.contains(where: { $0.id == c.id }) ? library.newCategoryId(c.name, scope: lib) : c.id
            library.categories.append(Category(id: nid, name: c.name, color: c.color, library: lib))
            touched.insert(lib ?? "")
            catMap[k] = nid
            return nid
        }
        func place<E: Entity>(_ d: inout E, _ row: Row) {
            d.library = row.destLibrary
            if row.destCategory == keep { d.category = d.category.isEmpty ? "" : resolve(d.library, d.category) }
            else { d.category = row.destCategory }
            if !d.category.isEmpty && !library.categories.contains(where: { $0.id == d.category && $0.library == d.library }) { d.category = "" }
        }
        func attachments(_ docs: [Attachment]) -> [Attachment] {
            var kept: [Attachment] = []
            for var a in docs {
                var have = library.space.attachmentRecord(a.id) != nil && library.space.attachmentURL(a.id) != nil
                if have, let r = library.space.attachmentRecord(a.id) { a.size = r.size }
                if !have, let z = file.zipAttachments[a.id], z.count <= Guard.maxPdfBytes, Guard.isPdf(z) {
                    if (try? library.space.putAttachment(id: a.id, data: z, dirty: true)) != nil { a.size = z.count; have = true }
                }
                if have || file.sameSpace { kept.append(a) }
            }
            return kept
        }
        var res = Result()
        var existing = Set(library.fiches.map(\.id))
        for row in sel {
            guard var d = row.fiche else { continue }
            place(&d, row)
            d.docs = attachments(d.docs)
            if existing.contains(d.id) && replaceDuplicates {
                if library.persist(d) { res.fiches.append(d.id) }
            } else {
                if d.id.isEmpty || existing.contains(d.id) || !file.sameSpace { d.id = Guard.uid() }
                existing.insert(d.id)
                if library.persist(d) { res.fiches.append(d.id) }
            }
        }
        var existingP = Set(library.protocols.map(\.id))
        for row in sel {
            guard var d = row.reference else { continue }
            place(&d, row)
            d.docs = attachments(d.docs)
            if existingP.contains(d.id) && replaceDuplicates {
                if library.persist(d) { res.references.append(d.id) }
            } else {
                if d.id.isEmpty || existingP.contains(d.id) || !file.sameSpace { d.id = Guard.uid("p") }
                existingP.insert(d.id)
                if library.persist(d) { res.references.append(d.id) }
            }
        }
        for lib in touched { library.saveCategories(scope: lib.isEmpty ? nil : lib) }
        let a = res.fiches.count, b = res.references.count
        let parts = [a > 0 ? (a > 1 ? "\(a) fiches importées" : "1 fiche importée") : "",
                     b > 0 ? (b > 1 ? "\(b) protocoles importés" : "1 protocole importé") : ""].filter { !$0.isEmpty }
        res.message = parts.isEmpty ? "" : parts.joined(separator: " et ") + " dans " + scopeLbl + "."
        return res
    }

    /// « Dupliquer dans « Perso » » : copie en BROUILLON, nouvel id, hors bibliothèque partagée.
    public static func duplicateToPerso(_ src: Fiche, library: Library) -> Fiche {
        var c = Sanitize.fiche(src.json)
        c.id = Guard.uid(); c.title = (src.title.isEmpty ? "Fiche" : src.title) + " (copie)"
        c.library = nil; c.status = .draft; c.order = library.now()
        library.persist(c)
        return library.fiches.first { $0.id == c.id } ?? c
    }
    public static func duplicateToPerso(_ src: Reference, library: Library) -> Reference {
        var c = Sanitize.reference(src.json)
        c.id = Guard.uid("p"); c.title = (src.title.isEmpty ? "Protocole" : src.title) + " (copie)"
        c.library = nil; c.status = .draft; c.order = library.now()
        library.persist(c)
        return library.protocols.first { $0.id == c.id } ?? c
    }
}
