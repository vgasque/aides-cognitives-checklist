import Foundation

// PRÉFÉRENCES D'ESPACE ET DOCUMENT PERSONNEL — ports de `sanitizePins`, `sanitizeUsage`,
// `mergeUsage`, `sanitizeTags`, `catSlug`, et des clés `spaceKey(...)` de la PWA.
//
// Le document de catégories PERSONNEL (`category_sets`, `personal:<uid>`) transporte aussi les
// épingles, la « frecency » et les PRÉFÉRENCES de l'utilisateur (thème, taille du texte, accent,
// mode de lecture, vocabulaire du journal, opt-in de l'historique, rangement de l'accueil) : elles
// suivent le COMPTE sur tous ses appareils. Les clés de `SpaceStore.prefs` sont celles du
// localStorage de la PWA (sans le suffixe d'espace : un espace = un dossier natif).

/// Clés de `SpaceStore.prefs` (préférences et curseurs PROPRES À UN ESPACE). Mêmes noms que les
/// clés `spaceKey(...)` du web. Valeurs : chaîne pour les chaînes, nombre pour les horodatages,
/// tableaux/objets JSON natifs (et non des chaînes JSON) ; les lecteurs tolèrent aussi la forme
/// « chaîne » du localStorage, au cas où une donnée importée l'aurait gardée.
public enum SpaceKeys {
    public static let cursorFiches = "ac-sync-cursor"
    public static let cursorProtocols = "ac-sync-cursor-prot"
    public static let cursorSessions = "ac-sync-cursor-sess"
    /// `ac-cats-updated:<k>` (ms, horloge LOCALE) — `k` = '' (Perso) ou id de bibliothèque.
    public static func catsUpdated(_ scope: String) -> String { "ac-cats-updated:" + scope }
    /// `ac-cats-dirty:<k>` = "1" quand le document `k` est à pousser.
    public static func catsDirty(_ scope: String) -> String { "ac-cats-dirty:" + scope }
    public static let pins = "ac-pins"
    public static let usage = "ac-usage"
    public static let usagePushMark = "ac-usage-pushmark"
    public static let theme = "ac-theme"
    public static let zoom = "ac-zoom"
    public static let accent = "ac-accent"
    public static let readMode = "ac-read-mode"
    public static let homeGroup = "ac-home-group"
    public static let tags = "ac-tags"
    public static let syncSessions = "ac-sync-sessions"
    public static let sessionsBackfilled = "ac-sess-backfilled"
    public static let attachmentDeleteQueue = "ac-att-del"
    public static let heldEdits = "ac-held-edits"
}

/// Clés GLOBALES (`LocalStore.global`), communes à tous les espaces.
public enum GlobalKeys {
    public static let space = "ac-space"
    public static let spaces = "ac-spaces"
    /// Marqueur de première synchro sur CET appareil pour ce compte (`_initIfNeeded`).
    public static func syncInit(_ uid: String) -> String { "ac-sync-init-" + uid }
    /// Cache de profil `{libraries, isAppAdmin}`.
    public static func profile(_ uid: String) -> String { "ac-profile-" + uid }
    public static let reopenAuth = "ac-reopen-auth"
    public static let moveFailed = "ac-move-failed"
}

// MARK: - Nommage des espaces (web)

/// `dbNameFor(space, owner)` — nom de la base IndexedDB d'un espace côté web. Le natif range un
/// espace par dossier (`LocalStore.folder(for:)`) ; ce port sert aux tests de parité.
public func dbNameFor(space: String, owner: String?) -> String {
    owner == space ? "ac-db" : "ac-db-" + (space.isEmpty ? "anon" : space)
}
/// `spaceKeyFor(base, space, owner)` — clé localStorage d'un espace côté web.
public func spaceKeyFor(base: String, space: String, owner: String?) -> String {
    owner == space ? base : base + "@" + (space.isEmpty ? "anon" : space)
}

// MARK: - Constantes des préférences

public enum PrefValues {
    public static let themes = ["auto", "light", "dark"]
    /// `ZOOM_STEPS`.
    public static let zoomSteps = [100, 115, 130]
    /// `ACCENT_IDS`.
    public static let accents = ["", "teal", "violet", "indigo", "framboise", "ardoise"]
    public static let accentLabels = ["": "Par défaut", "teal": "Sarcelle", "violet": "Violet", "indigo": "Indigo", "framboise": "Framboise", "ardoise": "Ardoise"]
    /// `READ_MODES`.
    public static let readModes = ["overview", "static"]
    /// `HOME_GROUPS`.
    public static let homeGroups = ["none", "kind", "bib", "cat", "az"]
    public static let tagMax = 40
    public static let tagAliasMax = 8
    public static let pinsMax = 50
    public static let usageMax = 200
}

// MARK: - Assainisseurs purs (testés contre la PWA)

/// `sanitizePins` : 50 ids sûrs au plus.
public func sanitizePins(_ v: JSON?) -> [String] {
    Array((v?.array ?? []).prefix(PrefValues.pinsMax).compactMap { x -> String? in
        guard let s = x.string, Guard.isSafeId(s) else { return nil }
        return s
    })
}

/// Une entrée de « frecency » : `n` ouvertures, dernière à `t` (ms).
public struct Usage: Equatable, Sendable {
    public var n: Int
    public var t: Double
    public init(n: Int, t: Double) { self.n = n; self.t = t }
    public var json: JSON { ["n": .number(Double(n)), "t": .number(t)] }
}

public func usageJSON(_ u: [String: Usage]) -> JSON { .object(u.mapValues(\.json)) }

/// `sanitizeUsage` : ids sûrs, n entier 1…9999, t entier ≥ 0, 200 entrées au plus (les PLUS
/// RÉCENTES gardées).
public func sanitizeUsage(_ v: JSON?) -> [String: Usage] {
    var out: [String: Usage] = [:]
    guard let o = v?.object else { return out }
    for (id, u) in o where Guard.isSafeId(id) {
        guard u.object != nil || u.array != nil else { continue }
        let n = min(9999, max(0, floorNum(u["n"])))
        let t = max(0, floorNum(u["t"]))
        if n > 0 { out[id] = Usage(n: Int(n), t: t) }
    }
    if out.count > PrefValues.usageMax {
        // Tri par `t` croissant (égalité : ordre des ids, faute de l'ordre d'insertion JS).
        let drop = out.keys.sorted { (out[$0]!.t, $0) < (out[$1]!.t, $1) }.prefix(out.count - PrefValues.usageMax)
        for k in drop { out[k] = nil }
    }
    return out
}
/// `Math.floor(+x||0)`.
func floorNum(_ v: JSON?) -> Double {
    let n = JS.number(v)
    return (n.isNaN || n == 0) ? 0 : n.rounded(.down)
}

/// `mergeUsage(a, b)` : par id, l'entrée au `n` le plus GRAND (égalité : `t` le plus récent) —
/// chaque appareil compte ses propres ouvertures, jamais de double compte.
public func mergeUsage(_ a: [String: Usage], _ b: [String: Usage]) -> [String: Usage] {
    var out: [String: Usage] = [:]
    for src in [a, b] {
        for (id, u) in src {
            if let cur = out[id], !(u.n > cur.n || (u.n == cur.n && u.t > cur.t)) { continue }
            out[id] = u
        }
    }
    return sanitizeUsage(usageJSON(out))
}

/// `txNorm` : NFD, sans diacritiques (U+0300–U+036F), en minuscules.
public func txNorm(_ s: String) -> String {
    let d = s.decomposedStringWithCanonicalMapping
    let kept = d.unicodeScalars.filter { !($0.value >= 0x300 && $0.value <= 0x36F) }
    return String(String.UnicodeScalarView(kept)).lowercased()
}

/// `catSlug(name)` : `txNorm`, suites non alphanumériques → « - », tirets de bord retirés, 48 max.
/// Les ids de catégories PERSO en dérivent (`c-<slug>`) : deux appareils qui créent la même
/// catégorie produisent le même id.
public func catSlug(_ name: String) -> String {
    var out = ""
    var dash = false
    for c in txNorm(name).unicodeScalars {
        let v = c.value
        if (v >= 97 && v <= 122) || (v >= 48 && v <= 57) {
            if dash && !out.isEmpty { out += "-" }
            dash = false
            out.unicodeScalars.append(c)
        } else {
            dash = true
        }
    }
    // `replace(/^-|-$/g,'')` : un tiret n'est émis qu'ENTRE deux suites alphanumériques, les
    // tirets de bord n'existent donc jamais.
    return JS.prefix(out, 48)
}

/// Une étiquette du vocabulaire du journal : clé stable (jamais dérivée du libellé une fois
/// créée), libellé ≤ 40, alias ≤ 8 × 24.
public struct JournalTag: Equatable, Sendable {
    public var k: String
    public var l: String
    public var a: [String]
    public init(k: String, l: String, a: [String] = []) { self.k = k; self.l = l; self.a = a }
    public var json: JSON { ["k": .string(k), "l": .string(l), "a": .array(a.map { .string($0) })] }
}

/// `sanitizeTags` : 40 au plus, libellé obligatoire, clé `safeId` (dérivée du libellé si absente),
/// doublons de clé écartés.
public func sanitizeTags(_ v: JSON?) -> [JournalTag] {
    var out: [JournalTag] = []
    var seen = Set<String>()
    for t in (v?.array ?? []).prefix(PrefValues.tagMax) {
        guard t.object != nil || t.array != nil else { continue }
        let lv: JSON? = (t["l"] != nil && !(t["l"]!.isNull)) ? t["l"] : t["label"]
        let l = JS.trim(Guard.sstr(lv, 40))
        if l.isEmpty { continue }
        let kSrc: JSON
        if let k = t["k"], k.truthy { kSrc = k } else {
            // `replace(/[^a-z0-9]+/g,'-')` garde les tirets de BORD (pas de trim ici).
            let slug = tagSlugKeepingEdges(txNorm(l))
            kSrc = .string("t-" + JS.prefix(slug, 24))
        }
        let k = Guard.safeId(kSrc, "t")
        if seen.contains(k) { continue }
        seen.insert(k)
        let av: JSON? = (t["a"] != nil && !(t["a"]!.isNull)) ? t["a"] : t["alias"]
        let a = Guard.sarr(av, PrefValues.tagAliasMax).map { JS.trim(Guard.sstr(.string($0), 24)) }.filter { !$0.isEmpty }
        out.append(JournalTag(k: k, l: l, a: a))
    }
    return out
}
/// `s.replace(/[^a-z0-9]+/g, '-')` (tirets de bord conservés).
func tagSlugKeepingEdges(_ s: String) -> String {
    var out = ""
    var inRun = false
    for c in s.unicodeScalars {
        let x = c.value
        if (x >= 97 && x <= 122) || (x >= 48 && x <= 57) { out.unicodeScalars.append(c); inRun = false }
        else if !inRun { out += "-"; inRun = true }
    }
    return out
}

// MARK: - Accès typé aux préférences d'un espace

/// Lecture/écriture TYPÉE de `SpaceStore.prefs`. La couche d'application et le moteur de synchro
/// passent par ici : une seule forme de valeur par clé.
public struct SpacePrefs {
    public let kv: KVFile
    public init(_ kv: KVFile) { self.kv = kv }
    public init(_ store: SpaceStore) { self.kv = store.prefs }

    /// Chaîne (un nombre stocké est rendu sous sa forme JS).
    public func string(_ k: String) -> String? {
        switch kv[k] {
        case .string(let s)?: return s
        case .number(let n)?: return JSON.formatNumber(n)
        case .bool(let b)?: return b ? "true" : "false"
        default: return nil
        }
    }
    /// `+(localStorage.getItem(k) || 0)` : nombre, ou nil si absent/illisible.
    public func number(_ k: String) -> Double? {
        guard let v = kv[k], !v.isNull else { return nil }
        let n = JS.number(v)
        return n.isNaN ? nil : n
    }
    /// Tableau/objet JSON (tolère une chaîne JSON à la manière du localStorage).
    public func json(_ k: String) -> JSON? {
        guard let v = kv[k] else { return nil }
        if case .string(let s) = v { return try? JSON.parse(s) }
        return v
    }
    public func set(_ k: String, _ v: JSON?) { kv[k] = v }
    public func setString(_ k: String, _ v: String?) { kv[k] = v.map { .string($0) } }
    public func remove(_ k: String) { if kv.values[k] != nil { kv[k] = nil } }

    // Préférences utilisateur (voyagent dans `data.prefs`).
    public var theme: String {
        get { let t = string(SpaceKeys.theme) ?? ""; return PrefValues.themes.contains(t) ? t : "auto" }
        nonmutating set { setString(SpaceKeys.theme, newValue) }
    }
    /// `currentZoom()` : 100, 115 ou 130 (100 par défaut).
    public var zoom: Int {
        get { let z = Int(number(SpaceKeys.zoom) ?? 100); return z == 0 ? 100 : z }
        nonmutating set { set(SpaceKeys.zoom, .number(Double(newValue))) }
    }
    /// `currentAccent()` : un id de `ACCENT_IDS`, '' par défaut.
    public var accent: String {
        get { let a = string(SpaceKeys.accent) ?? ""; return PrefValues.accents.contains(a) ? a : "" }
        nonmutating set { setString(SpaceKeys.accent, newValue) }
    }
    /// `currentReadMode()` : 'overview' par défaut.
    public var readMode: String {
        get { let m = string(SpaceKeys.readMode) ?? ""; return PrefValues.readModes.contains(m) ? m : "overview" }
        nonmutating set { setString(SpaceKeys.readMode, newValue) }
    }
    /// `homeGroupKey()` : 'cat' par défaut.
    public var homeGroup: String {
        get { let g = string(SpaceKeys.homeGroup) ?? ""; return PrefValues.homeGroups.contains(g) ? g : "cat" }
        nonmutating set { setString(SpaceKeys.homeGroup, newValue) }
    }
    public var tags: [JournalTag] {
        get { sanitizeTags(json(SpaceKeys.tags)) }
        nonmutating set { set(SpaceKeys.tags, .array(sanitizeTags(.array(newValue.map(\.json))).map(\.json))) }
    }
    /// `sessSyncOn()` — opt-in de l'historique des sessions.
    public var syncSessions: Bool { string(SpaceKeys.syncSessions) == "1" }
    public var pins: [String] {
        get { sanitizePins(json(SpaceKeys.pins)) }
        nonmutating set { set(SpaceKeys.pins, .array(sanitizePins(.array(newValue.map { .string($0) })).map { .string($0) })) }
    }
    public var usage: [String: Usage] {
        get { sanitizeUsage(json(SpaceKeys.usage)) }
        nonmutating set { set(SpaceKeys.usage, usageJSON(newValue)) }
    }

    // Documents de catégories.
    public func catsUpdated(_ scope: String) -> Double {
        let n = number(SpaceKeys.catsUpdated(scope)) ?? 0
        return n.isNaN ? 0 : n
    }
    public func catsDirty(_ scope: String) -> Bool { string(SpaceKeys.catsDirty(scope)) == "1" }
    /// `markPrefsDirty()` / `saveCats(scope)` : horodatage local + marqueur « à pousser ».
    public func markCatsDirty(_ scope: String, now: Double) {
        set(SpaceKeys.catsUpdated(scope), .number(now))
        setString(SpaceKeys.catsDirty(scope), "1")
    }

    // Modifications retenues (`heldEdits`) — 500 au plus, ids sûrs.
    public var heldEdits: [String] {
        get { (json(SpaceKeys.heldEdits)?.array ?? []).compactMap { $0.string }.filter(Guard.matchesSafeIdPattern) }
        nonmutating set {
            if newValue.isEmpty { remove(SpaceKeys.heldEdits) }
            else { set(SpaceKeys.heldEdits, .array(newValue.prefix(500).map { .string($0) })) }
        }
    }
    /// File des suppressions distantes de PDF (`ac-att-del`) — chemins valides seulement, 500 au plus.
    public var attachmentDeleteQueue: [String] {
        get { (json(SpaceKeys.attachmentDeleteQueue)?.array ?? []).compactMap { $0.string }.filter(isAttachmentPath) }
        nonmutating set {
            if newValue.isEmpty { remove(SpaceKeys.attachmentDeleteQueue) }
            else { set(SpaceKeys.attachmentDeleteQueue, .array(newValue.prefix(500).map { .string($0) })) }
        }
    }
    /// `queueAttDelete(path)`.
    public func queueAttachmentDelete(_ path: String) {
        guard isAttachmentPath(path) else { return }
        var q = attachmentDeleteQueue
        if !q.contains(path) { q.append(path); attachmentDeleteQueue = q }
    }
}

// MARK: - Chemins des documents PDF

/// `attStoragePath(libraryId, ownerUid, attId)` : `l/<lib>/<att>.pdf` (bibliothèque) ou
/// `u/<uid>/<att>.pdf` (perso, uid de l'utilisateur COURANT). Le chemin porte le périmètre de
/// sécurité : les politiques Storage de la RLS le lisent.
public func attStoragePath(library: String?, ownerUid: String, attId: String) -> String {
    if let library, !library.isEmpty { return "l/" + library + "/" + attId + ".pdf" }
    return "u/" + ownerUid + "/" + attId + ".pdf"
}

/// `ATT_PATH_RX = /^[ul]\/[A-Za-z0-9_-]{1,64}\/[A-Za-z0-9_-]{1,64}\.pdf$/`.
public func isAttachmentPath(_ p: String) -> Bool {
    let parts = p.split(separator: "/", omittingEmptySubsequences: false)
    guard parts.count == 3, parts[0] == "u" || parts[0] == "l", parts[2].hasSuffix(".pdf") else { return false }
    return Guard.matchesSafeIdPattern(String(parts[1])) && Guard.matchesSafeIdPattern(String(parts[2].dropLast(4)))
}
