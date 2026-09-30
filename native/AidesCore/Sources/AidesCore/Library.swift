import Foundation

// LA BIBLIOTHÈQUE LOCALE — port de `load()`, `persist`, `persistProtocol`, `softDelete`,
// `saveCats`, `saveNote`, `togglePin`, `bumpUsage`, `putBackup`, draft park, catégories par défaut,
// `remapCatsDeterministic`, `migrateCategories`, `gcAttachments`.
//
// Le disque est la source de vérité ; les collections en mémoire en sont le reflet. Le drapeau
// `dirty` (« à pousser ») vit dans l'ENREGISTREMENT, jamais dans le modèle : `migrate` l'efface à
// la relecture, et un objet réécrit sans lui perdrait sa poussée en attente (doctrine 16.6).

/// Une bibliothèque partagée dont je suis membre (type du module compte : `LibraryInfo`).
public typealias SharedLibrary = LibraryInfo

public struct Backup: Equatable, Sendable {
    public var bid: String
    public var ficheId: String
    public var at: Double
    public var data: JSON
}

public struct UsageEntry: Equatable, Sendable { public var n: Int; public var t: Double }

public final class Library {
    public let space: SpaceStore
    /// Identité courante (connecté ? e-mail ?) — injectée par la couche compte.
    public var identity: () -> (signedIn: Bool, email: String?) = { (false, nil) }
    /// Planifie une synchro après une écriture locale (`Sync.schedule`).
    public var onLocalWrite: () -> Void = {}
    public var now: () -> Double = JS.now

    public private(set) var allFiches: [Fiche] = []
    public private(set) var allProtocols: [Reference] = []
    public var fiches: [Fiche] { allFiches.filter { $0.deletedAt == nil } }
    public var protocols: [Reference] { allProtocols.filter { $0.deletedAt == nil } }
    public var categories: [Category] = []
    public private(set) var notes: [String: Note] = [:]
    public private(set) var sessions: [JSON] = []
    public var libraries: [SharedLibrary] = []

    public static let palette = ["#905a39", "#6f684a", "#4f6727", "#116b4c", "#226a71", "#1f6f96",
                                 "#45556b", "#0d5b56", "#5156b6", "#755a96", "#7a2f6b", "#95516c"]
    public static let backupMax = 5

    public init(space: SpaceStore) { self.space = space }

    // MARK: Chargement

    /// `load()` : lecture, assainissement (TOUT repasse par migrate), catégories par défaut, maintenance.
    public func load() {
        categories = Sanitize.categories(space.meta["categories"])
        allFiches = space.fiches.all().map { Sanitize.fiche($0) }
        allProtocols = space.protocols.all().map { Sanitize.reference($0) }
        sessions = space.sessions.all().filter { $0["deletedAt"] == nil || $0["deletedAt"]!.isNull }
        notes = Sanitize.notes(space.meta["notes"])
        if categories.isEmpty {
            categories = Self.defaultCategories()
            space.meta["categories"] = .array(categories.map(\.json))
        }
        remapCategoriesDeterministic()
        let changed = migrateLegacyCategories()
        for f in changed { try? putFiche(f, dirty: true) }
    }

    public var liveFicheCount: Int { fiches.count }

    /// `catSlug` : accents retirés, [a-z0-9]+ joints par « - », ≤ 48.
    public static func catSlug(_ name: String) -> String {
        let d = name.decomposedStringWithCanonicalMapping.unicodeScalars.filter { !(0x300...0x36f).contains($0.value) }
        let low = String(String.UnicodeScalarView(d)).lowercased()
        var out = "", dash = false
        for c in low.unicodeScalars {
            if (c.value >= 97 && c.value <= 122) || (c.value >= 48 && c.value <= 57) { if dash && !out.isEmpty { out += "-" }; dash = false; out.unicodeScalars.append(c) }
            else { dash = true }
        }
        return String(out.prefix(48))
    }
    public static func detCatId(_ name: String) -> String {
        let s = catSlug(name)
        return s.isEmpty ? Guard.uid("c") : "c-" + s
    }
    public static func defaultCategories() -> [Category] {
        [("Anesthésie", "#226a71"), ("Cardiologie", "#95516c"), ("Pédiatrie", "#116b4c"), ("Réanimation", "#1f6f96"),
         ("Régulation", "#5156b6"), ("SMUR", "#905a39"), ("SSE", "#6f684a"), ("Urgences", "#7a2f6b")]
            .map { Category(id: detCatId($0.0), name: $0.0, color: $0.1, library: nil) }
    }
    public func newCategoryId(_ name: String, scope: String?) -> String {
        if scope != nil { return Guard.uid("c") }
        var id = Self.detCatId(name), n = 2
        while categories.contains(where: { $0.id == id }) { id = Self.detCatId(name) + "-\(n)"; n += 1 }
        return id
    }
    /// `remapCatsDeterministic` : ids Perso dérivés du nom, doublons de nom fusionnés.
    func remapCategoriesDeterministic() {
        var map: [String: String] = [:], byNew = Set<String>(), kept: [Category] = []
        for var c in categories {
            if c.library != nil { kept.append(c); continue }
            let nid = Self.detCatId(c.name)
            if byNew.contains(nid) { map[c.id] = nid; continue }
            byNew.insert(nid)
            if c.id != nid { map[c.id] = nid }
            c.id = nid; kept.append(c)
        }
        categories = kept
        guard !map.isEmpty else { return }
        saveCategories(scope: nil)
        for var f in fiches where !f.category.isEmpty && map[f.category] != nil {
            f.category = map[f.category]!
            persist(f)
        }
    }
    /// `migrateCategories` : anciennes catégories « texte libre » → objets.
    func migrateLegacyCategories() -> [Fiche] {
        var changed: [Fiche] = []
        var byName: [String: String] = [:]
        for c in categories { byName[c.name.lowercased()] = c.id }
        var pi = categories.count
        for i in allFiches.indices where allFiches[i].deletedAt == nil {
            let cv = allFiches[i].category
            if cv.isEmpty || categories.contains(where: { $0.id == cv }) { continue }
            let name = JS.trim(cv)
            if name.isEmpty { allFiches[i].category = ""; changed.append(allFiches[i]); continue }
            var id = byName[name.lowercased()]
            if id == nil {
                id = newCategoryId(name, scope: nil)
                categories.append(Category(id: id!, name: name, color: Self.palette[pi % Self.palette.count], library: nil))
                pi += 1
                byName[name.lowercased()] = id
            }
            allFiches[i].category = id!
            changed.append(allFiches[i])
        }
        if !changed.isEmpty { space.meta["categories"] = .array(categories.map(\.json)) }
        return changed
    }

    // MARK: Écritures

    func record(_ j: JSON, dirty: Bool) -> JSON {
        guard var o = j.object else { return j }
        if dirty { o["dirty"] = true }
        return .object(o)
    }
    func putFiche(_ f: Fiche, dirty: Bool) throws {
        try space.fiches.put(f.id, record(f.json, dirty: dirty))
        if let i = allFiches.firstIndex(where: { $0.id == f.id }) { allFiches[i] = f } else { allFiches.append(f) }
    }
    func putReference(_ p: Reference, dirty: Bool) throws {
        try space.protocols.put(p.id, record(p.json, dirty: dirty))
        if let i = allProtocols.firstIndex(where: { $0.id == p.id }) { allProtocols[i] = p } else { allProtocols.append(p) }
    }
    /// Une fiche porte-t-elle une poussée en attente ?
    public func isDirty(ficheId: String) -> Bool { space.fiches.get(ficheId)?["dirty"]?.truthy ?? false }
    public func isDirty(referenceId: String) -> Bool { space.protocols.get(referenceId)?["dirty"]?.truthy ?? false }

    /// `persist(f)` : horodate, marque « à pousser », écrit, planifie la synchro.
    @discardableResult
    public func persist(_ f: Fiche) -> Bool {
        var f = f
        f.updatedAt = now()
        let id = identity()
        if id.signedIn, let e = id.email, !e.isEmpty { f.updatedBy = JS.prefix(e, 160) }
        markHeldEdit(f.id)
        do { try putFiche(f, dirty: true) } catch { return false }
        onLocalWrite()
        return true
    }
    @discardableResult
    public func persist(_ p: Reference) -> Bool {
        var p = p
        p.updatedAt = now()
        let id = identity()
        if id.signedIn, let e = id.email, !e.isEmpty { p.updatedBy = JS.prefix(e, 160) }
        do { try putReference(p, dirty: true) } catch { return false }
        onLocalWrite()
        return true
    }
    /// Écriture brute depuis la synchro (pull) : ni horodatage ni drapeau (la version distante fait foi).
    public func storeFromSync(_ f: Fiche) { try? putFiche(f, dirty: false) }
    public func storeFromSync(_ p: Reference) { try? putReference(p, dirty: false) }
    /// Purge définitive (tombe poussée, ou espace anonyme).
    public func purgeFiche(_ id: String) { space.fiches.delete(id); allFiches.removeAll { $0.id == id } }
    public func purgeReference(_ id: String) { space.protocols.delete(id); allProtocols.removeAll { $0.id == id } }
    /// Efface le drapeau « à pousser » après une poussée réussie.
    public func markClean(ficheId: String) { if let f = allFiches.first(where: { $0.id == ficheId }) { try? putFiche(f, dirty: false) } }
    public func markClean(referenceId: String) { if let p = allProtocols.first(where: { $0.id == referenceId }) { try? putReference(p, dirty: false) } }

    /// `softDelete(f)` : espace anonyme hors connexion = suppression DÉFINITIVE ; sinon une TOMBE,
    /// pour que la suppression hors ligne se propage.
    public func delete(_ f: Fiche) {
        if space.space.isEmpty && !identity().signedIn {
            if notes[f.id] != nil { notes[f.id] = nil; saveNotes() }
            purgeFiche(f.id)
            return
        }
        if let n = notes[f.id], !n.t.isEmpty { notes[f.id] = Note(t: "", at: now(), dirty: true); saveNotes() }
        var f = f
        f.deletedAt = now(); f.updatedAt = now()
        markHeldEdit(f.id)
        try? putFiche(f, dirty: true)
        onLocalWrite()
    }
    public func delete(_ p: Reference) {
        if space.space.isEmpty && !identity().signedIn { purgeReference(p.id); return }
        var p = p
        p.deletedAt = now(); p.updatedAt = now()
        try? putReference(p, dirty: true)
        onLocalWrite()
    }

    // MARK: Modifications hors connexion dans l'espace d'un compte (6.9)

    public var heldEdits: [String] {
        get { (space.prefs["ac-held-edits"]?.array ?? []).compactMap(\.string) }
        set { space.prefs["ac-held-edits"] = .array(newValue.prefix(500).map { .string($0) }) }
    }
    func markHeldEdit(_ id: String) {
        guard !space.space.isEmpty, !identity().signedIn else { return }
        var h = heldEdits
        if !h.contains(id) { h.append(id); heldEdits = h }
    }

    // MARK: Catégories

    /// `saveCats(scope)` : le document de catégories de la portée devient « à pousser ».
    public func saveCategories(scope: String?) {
        space.meta["categories"] = .array(categories.map(\.json))
        let sk = scope ?? ""
        space.prefs["ac-cats-updated:" + sk] = .number(now())
        space.prefs["ac-cats-dirty:" + sk] = "1"
        onLocalWrite()
    }
    /// Catégorie d'une entité : résolue DANS sa bibliothèque seulement.
    public func category(of e: some Entity) -> Category? {
        categories.first { $0.id == e.category && $0.library == e.library }
    }
    public func categories(in scope: String?) -> [Category] { categories.filter { $0.library == scope } }
    /// Éléments (aides ET références) d'une catégorie dans une portée.
    public func items(inCategory id: String, scope: String?) -> Int {
        fiches.filter { $0.category == id && $0.library == scope }.count + protocols.filter { $0.category == id && $0.library == scope }.count
    }
    @discardableResult
    public func addCategory(name: String, scope: String?) -> Category? {
        let n = JS.trim(name)
        guard !n.isEmpty else { return nil }
        let c = Category(id: newCategoryId(n, scope: scope), name: n, color: Self.palette[categories(in: scope).count % Self.palette.count], library: scope)
        categories.append(c)
        saveCategories(scope: scope)
        return c
    }
    public func updateCategory(_ c: Category) {
        guard let i = categories.firstIndex(where: { $0.id == c.id && $0.library == c.library }) else { return }
        categories[i] = c
        saveCategories(scope: c.library)
    }
    /// Suppression : les éléments sont d'abord déplacés vers `moveTo` ('' = sans catégorie).
    public func deleteCategory(_ c: Category, moveTo: String) {
        for var f in fiches where f.category == c.id && f.library == c.library { f.category = moveTo; persist(f) }
        for var p in protocols where p.category == c.id && p.library == c.library { p.category = moveTo; persist(p) }
        categories.removeAll { $0.id == c.id && $0.library == c.library }
        saveCategories(scope: c.library)
    }

    // MARK: Notes personnelles

    func saveNotes() {
        var o: [String: JSON] = [:]
        for (k, n) in notes {
            var v: [String: JSON] = ["t": .string(n.t), "at": .number(n.at)]
            if n.dirty { v["dirty"] = true }
            o[k] = .object(v)
        }
        space.meta["notes"] = .object(o)
    }
    public func note(_ ficheId: String) -> String { notes[ficheId]?.t ?? "" }
    /// `saveNote` : vide et inexistante = rien ; vide et existante = tombe '' (propagée par LWW).
    public func saveNote(_ ficheId: String, _ text: String) {
        let t = JS.prefix(text, 10000)
        if JS.trim(t).isEmpty && notes[ficheId] == nil { return }
        notes[ficheId] = Note(t: JS.trim(t).isEmpty ? "" : t, at: now(), dirty: true)
        saveNotes()
        onLocalWrite()
    }
    public func setNotesFromSync(_ n: [String: Note]) { notes = n; saveNotes() }

    // MARK: Épingles, fréquence d'usage, vocabulaire

    public var pins: [String] {
        get { (space.prefs["ac-pins"]?.array ?? []).compactMap(\.string).filter { Guard.isSafeId($0) }.prefix(50).map { $0 } }
        set { space.prefs["ac-pins"] = .array(newValue.prefix(50).map { .string($0) }); markPrefsDirty() }
    }
    public func togglePin(_ id: String) {
        var p = pins
        if let i = p.firstIndex(of: id) { p.remove(at: i) } else { p.insert(id, at: 0) }
        pins = p
    }
    public var usage: [String: UsageEntry] {
        get {
            var out: [String: UsageEntry] = [:]
            for (k, v) in space.prefs["ac-usage"]?.object ?? [:] where Guard.isSafeId(k) {
                let n = Int(min(9999, max(0, JS.number(v["n"]).isFinite ? JS.number(v["n"]).rounded(.down) : 0)))
                if n == 0 { continue }
                out[k] = UsageEntry(n: n, t: max(0, (v["t"]?.number ?? 0).rounded(.down)))
            }
            if out.count > 200 { out = Dictionary(uniqueKeysWithValues: out.sorted { $0.value.t > $1.value.t }.prefix(200).map { ($0.key, $0.value) }) }
            return out
        }
        set { space.prefs["ac-usage"] = .object(newValue.mapValues { ["n": .number(Double($0.n)), "t": .number($0.t)] }) }
    }
    public func bumpUsage(_ id: String) {
        var u = usage
        let cur = u[id]?.n ?? 0
        u[id] = UsageEntry(n: min(9999, cur + 1), t: now())
        usage = u
    }
    /// Score de fréquence récente : n × (≤ 15 j : 1 · ≤ 60 j : 0,5 · au-delà : 0,25).
    public func frecency(_ id: String) -> Double {
        guard let e = usage[id] else { return 0 }
        let days = (now() - e.t) / 86_400_000
        return Double(e.n) * (days <= 15 ? 1 : (days <= 60 ? 0.5 : 0.25))
    }
    func markPrefsDirty() {
        space.prefs["ac-cats-updated:"] = .number(now())
        space.prefs["ac-cats-dirty:"] = "1"
        onLocalWrite()
    }
    /// Vocabulaire personnel du journal `[{k, l, a}]`.
    public var tags: [(k: String, l: String)] {
        (space.prefs["ac-tags"]?.array ?? []).compactMap { t in
            guard let k = t["k"]?.string, let l = t["l"]?.string, !l.isEmpty else { return nil }
            return (k, l)
        }
    }

    // MARK: Sessions

    /// Écriture d'une session (`_putSessionSafe` + `sessUpsert`) : dirty + updatedAt.
    public func upsertSession(_ s: JSON) {
        guard var o = s.object, let id = o["id"]?.string, Guard.isSafeId(id) else { return }
        o["dirty"] = true; o["updatedAt"] = .number(now())
        let j = JSON.object(o)
        try? space.sessions.put(id, j)
        if let i = sessions.firstIndex(where: { $0["id"]?.string == id }) { sessions[i] = j } else { sessions.append(j) }
    }
    /// Suppression d'une session : tombe si l'historique est synchronisé, sinon définitive.
    public func deleteSession(_ id: String, syncHistory: Bool) {
        if syncHistory, var o = sessions.first(where: { $0["id"]?.string == id })?.object {
            o["deletedAt"] = .number(now()); o["dirty"] = true; o["updatedAt"] = .number(now())
            try? space.sessions.put(id, .object(o))
        } else { space.sessions.delete(id) }
        sessions.removeAll { $0["id"]?.string == id }
    }
    public func session(_ id: String) -> JSON? { sessions.first { $0["id"]?.string == id } }

    // MARK: Versions précédentes (5 par aide)

    public func backups(of ficheId: String) -> [Backup] {
        space.backups.all().compactMap { j in
            guard let bid = j["bid"]?.string, j["ficheId"]?.string == ficheId else { return nil }
            return Backup(bid: bid, ficheId: ficheId, at: j["at"]?.number ?? 0, data: j["data"] ?? .null)
        }.sorted { $0.at > $1.at }
    }
    public func putBackup(_ f: Fiche) {
        let bid = Guard.uid("bk")
        try? space.backups.put(bid, ["bid": .string(bid), "ficheId": .string(f.id), "at": .number(now()), "data": f.json])
        let all = backups(of: f.id)
        for b in all.dropFirst(Self.backupMax) { space.backups.delete(b.bid) }
    }
    /// Restaurer : la version courante est sauvegardée d'abord, puis remplacée.
    public func restore(_ b: Backup) -> Fiche? {
        guard let cur = fiches.first(where: { $0.id == b.ficheId }) else { return nil }
        putBackup(cur)
        var d = b.data.object ?? [:]
        d["id"] = .string(b.ficheId)
        let f = Sanitize.fiche(.object(d))
        persist(f)
        return fiches.first { $0.id == f.id }
    }

    // MARK: Brouillons parqués

    public func draftPark(_ kind: String) -> JSON? { space.meta["draftpark"]?[kind].flatMap { $0.isNull ? nil : $0 } }
    public func setDraftPark(_ kind: String, _ slot: JSON?) {
        var o = space.meta["draftpark"]?.object ?? [:]
        o[kind] = slot ?? .null
        space.meta["draftpark"] = .object(o)
    }

    // MARK: Documents PDF

    /// Ajoute un PDF (porte : signature et plafond vérifiés). Rend ses métadonnées.
    public func addAttachment(data: Data, name: String) throws -> Attachment {
        guard data.count <= Guard.maxPdfBytes else { throw StoreError.tooLarge }
        guard Guard.isPdf(data) else { throw StoreError.notPdf }
        let id = Guard.uid("a")
        try space.putAttachment(id: id, data: data, dirty: true)
        return Sanitize.attachment(["id": .string(id), "name": .string(name), "size": .number(Double(data.count))])!
    }
    /// `gcAttachments` : un binaire que plus RIEN ne référence (tombes comprises) est retiré ;
    /// s'il était dans le cloud, sa suppression distante est mise en file.
    public func collectGarbageAttachments(extraReferenced: Set<String> = []) {
        var used = extraReferenced
        for f in allFiches { for d in f.docs { used.insert(d.id) } }
        for p in allProtocols { for d in p.docs { used.insert(d.id) } }
        var queue = (space.prefs["ac-att-del"]?.array ?? []).compactMap(\.string)
        for r in space.attachmentRecords() where !used.contains(r.id) {
            if let rp = r.remotePath { queue.append(rp) }
            space.deleteAttachment(r.id)
        }
        space.prefs["ac-att-del"] = .array(queue.suffix(500).map { .string($0) })
    }

    // MARK: Rôles

    public func role(of lib: String?) -> LibraryRole? { lib.flatMap { l in libraries.first { $0.id == l }?.role } }
    public func libraryName(_ lib: String?) -> String { lib.flatMap { l in libraries.first { $0.id == l }?.name } ?? "" }
    /// `canEditScope` : Perso toujours ; une bibliothèque partagée selon le rôle.
    public func canEdit(scope: String?) -> Bool {
        guard scope != nil else { return true }
        let r = role(of: scope)
        return r == .editor || r == .admin
    }
    public func canEdit(_ e: some Entity) -> Bool { canEdit(scope: e.library) }
}

