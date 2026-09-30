import Foundation

// LIGNES SUPABASE ⇄ ENREGISTREMENTS LOCAUX — ports de `rowConverters` (fiches, protocoles),
// `sessionToRow`, `sessionFromRow` et `pullMissedIds`.
//
// INTEROPÉRABILITÉ : la colonne `data` est l'entité ENTIÈRE telle que l'écrit la PWA, moins
// `dirty`. Les colonnes (`id`, `owner`, `library_id`, `updated_at`, `deleted_at`) font foi au
// retour : elles écrasent leurs copies redondantes dans `data`. Tout ce qui revient du serveur
// repasse par le point d'entrée d'assainissement (`Sanitize.fiche` = `migrate`,
// `Sanitize.reference` = `migrateProtocol`, `SessionSanitize.session` = `sanitizeSession`) — règle 5.

/// Forme d'un ENREGISTREMENT LOCAL tel que le moteur de synchro le lit et l'écrit dans
/// `SpaceStore` (le contrat partagé avec la couche d'application) :
/// - `fiches/<id>.json`    : `Fiche.json`, plus `"dirty": true|false` quand il y a lieu ;
/// - `protocols/<id>.json` : `Reference.json`, plus `dirty` ;
/// - `sessions/<id>.json`  : la session (forme `sanitizeSession`), plus `dirty`, `updatedAt`
///   (horloge de synchro, ms) et `deletedAt` (pierre tombale) ;
/// - `backups/<bid>.json`  : `{bid, ficheId, at, data}` — version écrasée par un pull (5 par fiche) ;
/// - `meta.json`           : `categories` (tableau de `Category.json`), `notes` (`{ficheId: {t, at, dirty?}}`).
public enum LocalRecord {
    public static func updatedAt(_ r: JSON) -> Double { jsNumberOrZero(r["updatedAt"]) }
    /// `o.deletedAt` vrai au sens JS.
    public static func isDeleted(_ r: JSON) -> Bool { r["deletedAt"]?.truthy ?? false }
    public static func isDirty(_ r: JSON) -> Bool { r["dirty"]?.truthy ?? false }
    /// `o.library || null`.
    public static func library(_ r: JSON) -> String? {
        guard let l = r["library"], l.truthy else { return nil }
        return l.jsString
    }
    public static func title(_ r: JSON) -> String {
        if let t = r["title"], t.truthy { return t.jsString }
        return r["id"]?.jsString ?? ""
    }
    public static func id(_ r: JSON) -> String? { r["id"]?.string }
    /// Copie sans une liste de clés.
    static func without(_ r: JSON, _ keys: [String]) -> JSON {
        guard var o = r.object else { return r }
        for k in keys { o[k] = nil }
        return .object(o)
    }
    static func with(_ r: JSON, _ k: String, _ v: JSON?) -> JSON {
        var o = r.object ?? [:]
        o[k] = v
        return .object(o)
    }
}

/// `x || 0` pour un nombre (NaN, 0, absent → 0).
func jsNumberOrZero(_ v: JSON?) -> Double {
    guard case .number(let n)? = v, !n.isNaN else { return 0 }
    return n
}

/// `new Date(v).getTime()` pour une valeur JSON (nombre, ou chaîne ISO). nil = date invalide.
func jsDateValue(_ v: JSON) -> Double? {
    switch v {
    case .number(let n): return n.isFinite ? n : nil
    case .string(let s): return JSDate.parse(s)
    case .bool(let b): return b ? 1 : 0
    default: return nil
    }
}

/// `new Date(x || fallback).toISOString()` — `x` pris au sens JS (un falsy passe au suivant).
/// Une date invalide lèverait `RangeError` côté web ; ici elle retombe sur `fallback`.
func isoOf(_ candidates: [JSON?], fallback: Double) -> String {
    for c in candidates {
        guard let c, c.truthy else { continue }
        return JSDate.iso(jsDateValue(c) ?? fallback)
    }
    return JSDate.iso(fallback)
}

public enum SyncRows {
    // MARK: Fiches et protocoles (`rowConverters`)

    /// `toRow(o, uid)` : `owner` = TOUJOURS l'utilisateur qui pousse (même pour une ligne de
    /// bibliothèque partagée), `data` = l'enregistrement moins `dirty`.
    public static func entityToRow(_ o: JSON, uid: String, now: Double) -> JSON {
        let data = LocalRecord.without(o, ["dirty"])
        return .object([
            "id": o["id"] ?? .null,
            "owner": .string(uid),
            "library_id": LocalRecord.library(o).map { .string($0) } ?? .null,
            "data": data,
            "updated_at": .string(isoOf([o["updatedAt"]], fallback: now)),
            "deleted_at": LocalRecord.isDeleted(o) ? .string(isoOf([o["deletedAt"]], fallback: now)) : .null,
        ])
    }

    /// Fusion `{...row.data, id, updatedAt, deletedAt, ownerId, library}` : les COLONNES gagnent.
    static func mergedEntity(_ row: JSON, now: Double) -> JSON {
        var o: [String: JSON] = row["data"]?.object ?? [:]
        o["id"] = row["id"] ?? .null
        let ua = row["updated_at"]?.string.flatMap { JSDate.parse($0) } ?? 0
        o["updatedAt"] = .number(ua != 0 ? ua : now)
        if let d = row["deleted_at"], d.truthy, let t = d.string.flatMap({ JSDate.parse($0) }) { o["deletedAt"] = .number(t) }
        else if let d = row["deleted_at"], d.truthy { o["deletedAt"] = .null /* Date.parse invalide → NaN → écarté par migrate */ }
        else { o["deletedAt"] = .null }
        o["ownerId"] = (row["owner"]?.truthy ?? false) ? row["owner"]! : .null
        o["library"] = (row["library_id"]?.truthy ?? false) ? row["library_id"]! : .null
        return .object(o)
    }

    /// `ficheFromRow(row)` = `migrate({...row.data, …colonnes})`.
    public static func ficheFromRow(_ row: JSON, now: Double) -> Fiche { Sanitize.fiche(mergedEntity(row, now: now)) }
    /// `protocolFromRow(row)` = `migrateProtocol({...row.data, …colonnes})`.
    public static func referenceFromRow(_ row: JSON, now: Double) -> Reference { Sanitize.reference(mergedEntity(row, now: now)) }

    // MARK: Sessions (`sessionToRow`, `sessionFromRow`)

    /// Champs qui ne quittent JAMAIS l'appareil : la trace de vérification (do-verify) et les
    /// textes d'étape saisis. Le drapeau `vElsewhere` le DIT au compte rendu consulté ailleurs.
    public static let sessionLocalOnly = ["verified", "vgaps", "stepTexts"]

    /// `sessionToRow(o, uid)` : `data` = la session moins `dirty`, `updatedAt`, `deletedAt`,
    /// `linkArm` et les champs locaux ; colonne `exercise` ; horloge = `updatedAt || savedAt || now`.
    public static func sessionToRow(_ o: JSON, uid: String, now: Double) -> JSON {
        var data = o.object ?? [:]
        for k in ["dirty", "updatedAt", "deletedAt", "linkArm"] { data[k] = nil }
        var hadV = false
        for k in sessionLocalOnly {
            if let v = data[k], v.truthy, jsKeyCount(v) > 0 { hadV = true }
            data[k] = nil
        }
        if hadV { data["vElsewhere"] = true }
        return .object([
            "id": o["id"] ?? .null,
            "owner": .string(uid),
            "data": .object(data),
            "exercise": .bool(o["exercise"]?.truthy ?? false),
            "updated_at": .string(isoOf([o["updatedAt"], o["savedAt"]], fallback: now)),
            "deleted_at": LocalRecord.isDeleted(o) ? .string(isoOf([o["deletedAt"]], fallback: now)) : .null,
        ])
    }

    /// `sessionFromRow(row)` : la seule porte d'entrée d'une session distante. `verified`/`vgaps`
    /// arrivent VIDES (ils ne sont jamais partis).
    public static func sessionFromRow(_ row: JSON, now: Double) -> JSON {
        var d: JSON = .object([:])
        if let data = row["data"] {
            // `typeof data === 'object'` : un tableau passe aussi (ses indices deviennent des clés).
            if data.object != nil { d = data }
            else if let a = data.array {
                var o: [String: JSON] = [:]
                for (i, v) in a.enumerated() { o[String(i)] = v }
                d = .object(o)
            }
        }
        var out = SessionSanitize.session(d).object ?? [:]
        out["id"] = row["id"] ?? .null
        out["exercise"] = .bool(row["exercise"]?.truthy ?? false)
        out["verified"] = .object([:])
        out["vgaps"] = .object([:])
        let ua = row["updated_at"]?.string.flatMap { JSDate.parse($0) } ?? 0
        out["updatedAt"] = .number(ua != 0 ? ua : now)
        if let dl = row["deleted_at"], dl.truthy { out["deletedAt"] = dl.string.flatMap { JSDate.parse($0) }.map { .number($0) } ?? .null }
        else { out["deletedAt"] = .null }
        return .object(out)
    }

    /// `Object.keys(v).length` (chaîne : unités UTF-16 ; nombre/booléen : 0).
    static func jsKeyCount(_ v: JSON) -> Int {
        switch v {
        case .object(let o): return o.count
        case .array(let a): return a.count
        case .string(let s): return s.utf16.count
        default: return 0
        }
    }

    // MARK: Repêchage de complétude

    /// `pullMissedIds(rows, byId)` : lignes que le pull INCRÉMENTAL ne ramènera jamais — id absent
    /// en local et non supprimé (ligne révélée par la RLS après une adhésion, ou `updated_at`
    /// « dans le passé » d'un appareil à l'horloge en retard), ou id présent mais version distante
    /// plus récente. Seuls des ids au format SAFE_ID sortent (ils repartent dans un `id=in.(…)`).
    /// `localUpdatedAt(id)` : nil = pas d'enregistrement local.
    public static func pullMissedIds(_ rows: [JSON], localUpdatedAt: (String) -> Double?) -> [String] {
        var out: [String] = []
        for r in rows {
            let id = (r["id"].map { $0.truthy ? $0.jsString : "" }) ?? ""
            guard Guard.matchesSafeIdPattern(id) else { continue }
            if let lu = localUpdatedAt(id) {
                if JSDate.parseOrZero(r["updated_at"]) > lu { out.append(id) }
            } else if !(r["deleted_at"]?.truthy ?? false) {
                out.append(id)
            }
        }
        return out
    }
}
