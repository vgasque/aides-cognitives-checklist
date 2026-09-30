import Foundation

// STOCKAGE LOCAL — l'équivalent natif d'IndexedDB (`ac-db`) et du localStorage de la PWA.
//
// LOCAL-FIRST : le disque de l'appareil est la SOURCE DE VÉRITÉ ; le cloud est une couche
// séparée, asynchrone, par-dessus (Sync). Rien ne bloque jamais l'usage hors ligne.
//
// ESPACES PAR COMPTE (doctrine « ESPACES LOCAUX PAR COMPTE ») : tout le stockage est cloisonné
// par compte — un dossier par espace (`anon` pour « sans compte », sinon l'UUID du compte).
// Aucune donnée de deux comptes ne se mélange jamais ; l'espace suit le DERNIER compte connecté.
//
// UN FICHIER PAR ENREGISTREMENT, écrit atomiquement : une aide modifiée ne réécrit qu'elle-même
// (une aide peut peser plusieurs Mo d'images), et une coupure au milieu d'une écriture ne peut
// pas corrompre la bibliothèque entière.

/// Petit magasin clé-valeur JSON persistant (équivalent d'un espace de localStorage).
public final class KVFile {
    public let url: URL
    public internal(set) var values: [String: JSON]

    public init(url: URL) {
        self.url = url
        if let d = try? Data(contentsOf: url), let j = try? JSON.parse(d), let o = j.object { values = o } else { values = [:] }
    }
    public subscript(key: String) -> JSON? {
        get { values[key] }
        set { values[key] = newValue; save() }
    }
    public func string(_ key: String) -> String? { values[key]?.string }
    public func set(_ key: String, _ v: String?) { self[key] = v.map { .string($0) } }
    public func remove(where pred: (String) -> Bool) {
        let before = values.count
        values = values.filter { !pred($0.key) }
        if values.count != before { save() }
    }
    public func save() {
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSON.object(values).data().write(to: url, options: .atomic)
    }
}

/// Un dossier d'enregistrements JSON, un fichier par identifiant.
public final class RecordDir {
    public let url: URL
    public init(url: URL) {
        self.url = url
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    /// Nom de fichier sûr et INSENSIBLE À LA CASSE du système de fichiers (APFS l'est souvent) :
    /// « Ab » et « ab » sont deux identifiants distincts, les majuscules sont donc échappées.
    static func fileName(_ id: String) -> String {
        var s = ""
        for c in id.unicodeScalars {
            if c.value >= 65 && c.value <= 90 { s += "^" + String(Character(c)).lowercased() } else { s.unicodeScalars.append(c) }
        }
        return s + ".json"
    }
    func path(_ id: String) -> URL { url.appendingPathComponent(Self.fileName(id)) }

    public func get(_ id: String) -> JSON? {
        guard Guard.isSafeId(id), let d = try? Data(contentsOf: path(id)) else { return nil }
        return try? JSON.parse(d)
    }
    public func all() -> [JSON] {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: url.path) else { return [] }
        return names.filter { $0.hasSuffix(".json") }.sorted().compactMap { n in
            guard let d = try? Data(contentsOf: url.appendingPathComponent(n)) else { return nil }
            return try? JSON.parse(d)
        }
    }
    public func put(_ id: String, _ value: JSON) throws {
        guard Guard.isSafeId(id) else { throw StoreError.badId }
        try value.data().write(to: path(id), options: .atomic)
    }
    public func delete(_ id: String) {
        guard Guard.isSafeId(id) else { return }
        try? FileManager.default.removeItem(at: path(id))
    }
    public func deleteAll() {
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}

public enum StoreError: Error, CustomStringConvertible {
    case badId, tooLarge, notPdf, missing
    public var description: String {
        switch self {
        case .badId: return "Identifiant invalide."
        case .tooLarge: return "Document trop volumineux."
        case .notPdf: return "Ce fichier n’est pas un PDF."
        case .missing: return "Document introuvable sur cet appareil."
        }
    }
}

/// Métadonnées locales d'un PDF (store IndexedDB `attachments` de la PWA).
public struct AttachmentRecord: Equatable, Sendable {
    public var id: String
    public var size: Int
    public var createdAt: Double
    /// À téléverser (synchro).
    public var dirty: Bool
    /// Chemin dans le bucket Supabase `attachments`, une fois téléversé.
    public var remotePath: String?
    public init(id: String, size: Int, createdAt: Double, dirty: Bool, remotePath: String?) {
        self.id = id; self.size = size; self.createdAt = createdAt; self.dirty = dirty; self.remotePath = remotePath
    }
    var json: JSON {
        ["id": .string(id), "size": .number(Double(size)), "type": "application/pdf", "createdAt": .number(createdAt),
         "dirty": .number(dirty ? 1 : 0), "remotePath": .str(remotePath)]
    }
    init?(json j: JSON) {
        guard let id = j["id"]?.string, Guard.isSafeId(id) else { return nil }
        self.id = id
        size = Int(JS.number(j["size"]).isFinite ? JS.number(j["size"]) : 0)
        createdAt = j["createdAt"]?.number ?? 0
        dirty = j["dirty"]?.truthy ?? false
        remotePath = j["remotePath"]?.string
    }
}

/// Le stockage d'UN espace (un compte, ou « sans compte »).
public final class SpaceStore {
    public let space: String
    public let root: URL
    public let fiches: RecordDir
    public let protocols: RecordDir
    public let sessions: RecordDir
    public let backups: RecordDir
    /// Catégories, notes, brouillons parqués… (store `meta` de la PWA).
    public let meta: KVFile
    /// Préférences et curseurs propres à l'espace (clés `spaceKey(...)` de la PWA).
    public let prefs: KVFile
    let attDir: URL
    let attMeta: KVFile

    public init(root: URL, space: String) {
        self.space = space
        self.root = root
        fiches = RecordDir(url: root.appendingPathComponent("fiches"))
        protocols = RecordDir(url: root.appendingPathComponent("protocols"))
        sessions = RecordDir(url: root.appendingPathComponent("sessions"))
        backups = RecordDir(url: root.appendingPathComponent("backups"))
        meta = KVFile(url: root.appendingPathComponent("meta.json"))
        prefs = KVFile(url: root.appendingPathComponent("prefs.json"))
        attDir = root.appendingPathComponent("attachments")
        attMeta = KVFile(url: root.appendingPathComponent("attachments.json"))
        try? FileManager.default.createDirectory(at: attDir, withIntermediateDirectories: true)
    }

    // MARK: Documents PDF

    public func attachmentRecord(_ id: String) -> AttachmentRecord? {
        attMeta[id].flatMap { AttachmentRecord(json: $0) }
    }
    public func attachmentRecords() -> [AttachmentRecord] {
        attMeta.values.values.compactMap { AttachmentRecord(json: $0) }
    }
    public func attachmentURL(_ id: String) -> URL? {
        guard Guard.isSafeId(id) else { return nil }
        let u = attDir.appendingPathComponent(RecordDir.fileName(id).replacingOccurrences(of: ".json", with: ".pdf"))
        return FileManager.default.fileExists(atPath: u.path) ? u : nil
    }
    public func attachmentData(_ id: String) -> Data? {
        attachmentURL(id).flatMap { try? Data(contentsOf: $0) }
    }
    /// Écrit un PDF (signature « %PDF- » et plafond vérifiés ici, dernière porte).
    public func putAttachment(id: String, data: Data, dirty: Bool, remotePath: String? = nil) throws {
        guard Guard.isSafeId(id) else { throw StoreError.badId }
        guard data.count <= Guard.maxPdfBytes else { throw StoreError.tooLarge }
        guard Guard.isPdf(data) else { throw StoreError.notPdf }
        let u = attDir.appendingPathComponent(RecordDir.fileName(id).replacingOccurrences(of: ".json", with: ".pdf"))
        try data.write(to: u, options: .atomic)
        attMeta[id] = AttachmentRecord(id: id, size: data.count, createdAt: JS.now(), dirty: dirty, remotePath: remotePath).json
    }
    public func updateAttachmentRecord(_ r: AttachmentRecord) { attMeta[r.id] = r.json }
    public func deleteAttachment(_ id: String) {
        guard Guard.isSafeId(id) else { return }
        let u = attDir.appendingPathComponent(RecordDir.fileName(id).replacingOccurrences(of: ".json", with: ".pdf"))
        try? FileManager.default.removeItem(at: u)
        attMeta[id] = nil
    }

    /// Efface tout l'espace (déconnexion avec « effacer », suppression de compte).
    public func wipe() {
        try? FileManager.default.removeItem(at: root)
    }
}

/// Racine du stockage : registre des espaces et réglages GLOBAUX (non cloisonnés).
public final class LocalStore {
    public let base: URL
    /// Clés globales : `ac-space`, `ac-spaces`, `ac-auth` (hors jetons, qui vont au trousseau),
    /// `ac-sync-init-<uid>`, `ac-profile-<uid>`, `ac-onboarded`, `ac-notice-hidden`…
    public let global: KVFile

    public init(base: URL) {
        self.base = base
        global = KVFile(url: base.appendingPathComponent("global.json"))
    }

    /// Emplacement par défaut : « Application Support/AidesCognitives ».
    public static func defaultBase() -> URL {
        let fm = FileManager.default
        let sup = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? fm.temporaryDirectory
        return sup.appendingPathComponent("AidesCognitives", isDirectory: true)
    }

    /// L'espace courant : '' = sans compte, sinon l'UUID du compte.
    public var currentSpace: String {
        get { global.string("ac-space") ?? "" }
        set { global.set("ac-space", newValue); register(newValue) }
    }
    public var spaces: [String] { (global["ac-spaces"]?.array ?? []).compactMap(\.string) }
    public func register(_ space: String) {
        var s = spaces
        if !s.contains(space) { s.append(space); global["ac-spaces"] = .array(s.map { .string($0) }) }
    }
    public func folder(for space: String) -> URL {
        let name = space.isEmpty ? "anon" : (Guard.isSafeId(space) ? space : "invalid")
        return base.appendingPathComponent("spaces", isDirectory: true).appendingPathComponent(name, isDirectory: true)
    }
    public func open(_ space: String) -> SpaceStore {
        register(space)
        return SpaceStore(root: folder(for: space), space: space)
    }

    /// `spaceTag` : empreinte FNV-1a 32 bits de l'espace, « sp » + base 36 — posée en `origin`
    /// dans les exports pour qu'un import sache s'il vient du MÊME espace (ids conservés).
    public static func spaceTag(_ space: String) -> String {
        var h: UInt32 = 0x811c9dc5
        for u in space.utf16 { h ^= UInt32(u); h = h &* 0x01000193 }
        return "sp" + String(h, radix: 36)
    }

    /// Déplace (jamais ne copie) les données d'un espace vers un autre — un id de fiche ne peut
    /// appartenir qu'à un compte, la clé primaire du cloud étant globale.
    public func moveData(from: String, to: String) throws {
        let src = open(from), dst = open(to)
        for (a, b) in [(src.fiches, dst.fiches), (src.protocols, dst.protocols), (src.sessions, dst.sessions), (src.backups, dst.backups)] {
            // Les sauvegardes de version sont indexées par `bid`, pas par `id` (elles étaient perdues).
            for j in a.all() { if let id = j["id"]?.string ?? j["bid"]?.string { try b.put(id, j) } }
        }
        for (k, v) in src.meta.values { dst.meta.values[k] = v }
        dst.meta.save()
        for r in src.attachmentRecords() {
            if let d = src.attachmentData(r.id) { try dst.putAttachment(id: r.id, data: d, dirty: r.dirty, remotePath: r.remotePath) }
        }
        if let pins = src.prefs["ac-pins"] { dst.prefs["ac-pins"] = pins }
        dst.prefs["ac-cats-dirty:"] = "1"
        dst.prefs["ac-cats-updated:"] = .number(JS.now())
        src.wipe()
    }

    /// Effacement TOTAL de l'appareil (suppression du compte avec « effacer »).
    public func wipeAll() {
        try? FileManager.default.removeItem(at: base)
        global.values = [:]
    }
    public func wipeSpace(_ space: String) {
        open(space).wipe()
        global.remove { $0 == "ac-sync-init-" + space }
    }
}

