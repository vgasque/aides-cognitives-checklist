import Foundation

// SESSIONS — assainissement (port de `sanitizeSession`, `tkRefNorm`, `linkArmSnap`, `shareNavNorm`).
//
// LISTE GRISE, PAS BLANCHE (doctrine J210) : les champs connus sont bornés et normalisés, les
// champs inconnus TRAVERSENT (moins les clés bannies) — une liste blanche perdrait les champs d'un
// client plus récent au prochain aller-retour de synchro. Une session reste donc un document JSON ;
// le moteur (`SessionEngine`) en lit et écrit les champs connus.

public enum SessionSanitize {
    /// `SHARE_KEY_RX = /^[A-Za-z0-9_-]{1,64}:[A-Za-z0-9_-]{1,64}:\d{1,4}$/` — clé de cochage.
    public static func isCheckKey(_ s: String) -> Bool {
        let p = s.split(separator: ":", omittingEmptySubsequences: false)
        guard p.count == 3, Guard.matchesSafeIdPattern(String(p[0])), Guard.matchesSafeIdPattern(String(p[1])) else { return false }
        let d = p[2]
        return d.count >= 1 && d.count <= 4 && d.utf8.allSatisfy { $0 >= 48 && $0 <= 57 }
    }

    /// Le noyau universel des étiquettes du journal (liste FERMÉE et livrée).
    public static let tagCore: [(k: String, l: String)] = [
        ("renfort", "Renfort demandé"), ("regul", "Régulation"), ("dep-base", "Départ de la base"),
        ("arr-lieu", "Arrivée sur place"), ("bilan", "Bilan passé"), ("transm", "Transmission"),
        ("releve", "Relève"), ("depart", "Départ des lieux"), ("arr-hop", "Arrivée à l’hôpital"),
    ]

    /// `tkRefNorm` : référence d'un repère du journal — six types admis, le reste REJETÉ.
    public static func ref(_ r: JSON?) -> JSON? {
        guard let r, r.object != nil || r.array != nil else { return nil }
        let type = r["type"]?.string
        switch type {
        case "counter":
            var o: [String: JSON] = ["type": "counter", "id": .string(Guard.safeId(r["id"], "c"))]
            if let v = r["v"], !v.isNull { o["v"] = .number(max(0, JS.roundedOrZero(v))) }
            return .object(o)
        case "timer":
            return ["type": "timer", "id": .string(Guard.safeId(r["id"], "t"))]
        case "step":
            let i = JS.round(JS.number(r["i"]))
            guard i >= 0, i < 10000 else { return nil }
            return ["type": "step", "b": .string(Guard.safeId(r["b"], "b")), "i": .number(i)]
        case "poso":
            let i = JS.round(JS.number(r["i"]))
            guard i >= 0, i < 10000 else { return nil }
            return ["type": "poso", "i": .number(i)]
        case "core":
            let k = Guard.sstr(r["k"], 32)
            return tagCore.contains(where: { $0.k == k }) ? ["type": "core", "k": .string(k)] : nil
        case "tag":
            return ["type": "tag", "k": .string(Guard.safeId(r["k"], "t"))]
        default:
            return nil
        }
    }

    /// `shareNavNorm` : nav et navSeq de même longueur (1…512), visites entières positives.
    public static func nav(_ nav: JSON?, _ navSeq: JSON?) -> (nav: [String], navSeq: [Int])? {
        guard let a = nav?.array, let s = navSeq?.array, a.count == s.count, !a.isEmpty, a.count <= 512 else { return nil }
        let ids = a.map { Guard.safeId($0, "b") }
        let seqs = s.map { x -> Int in
            let n = JS.round(JS.number(x))
            return (n.isFinite && n > 0 && n < 1e6) ? Int(n) : 1
        }
        return (ids, seqs)
    }

    /// `linkArmSnap` : {idMinuteur: {b: idBloc|'', x: arrêt de sortie}} (A377).
    public static func linkArm(_ src: JSON?) -> JSON {
        var m: [String: JSON] = [:]
        guard let o = src?.object else { return .object(m) }
        var n = 0
        for k in o.keys.sorted() {
            if n >= 200 { break }
            guard Guard.isSafeId(k), let a = o[k], a.object != nil || a.array != nil else { continue }
            m[k] = ["b": .string(Guard.safeRef(a["b"])), "x": .number(numOrZero(a["x"]))]
            n += 1
        }
        return .object(m)
    }

    /// `+v || 0`
    static func numOrZero(_ v: JSON?) -> Double {
        let n = JS.number(v)
        return (n.isNaN || n == 0) ? 0 : n
    }

    /// Port de `sanitizeSession(d)` — JSON → JSON.
    public static func session(_ d: JSON) -> JSON {
        var out: [String: JSON] = [:]
        for (k, v) in d.object ?? [:] where !Guard.badKeys.contains(k) { out[k] = v }
        out["ficheId"] = .string(Guard.safeId(out["ficheId"], "f"))
        out["ficheTitle"] = .string(Guard.sstr(out["ficheTitle"], 300))
        out["name"] = .string(Guard.sstr(out["name"], 160))
        out["startedAt"] = .number(numOrZero(out["startedAt"]))
        out["savedAt"] = .number(numOrZero(out["savedAt"]))
        out["aidRev"] = .number(numOrZero(out["aidRev"]))
        out["live"] = .bool(out["live"]?.truthy ?? false)
        out["exercise"] = .bool(out["exercise"]?.truthy ?? false)
        for k in ["checked", "verified", "vgaps", "stepTexts"] {
            var m: [String: JSON] = [:]
            var n = 0
            if let src = out[k]?.object {
                for key in src.keys.sorted() {
                    if n >= 4000 { break }
                    if !isCheckKey(key) { continue }
                    m[key] = src[key]; n += 1
                }
            }
            out[k] = .object(m)
        }
        if let nv = nav(out["nav"], out["navSeq"]) {
            out["nav"] = .array(nv.nav.map { .string($0) }); out["navSeq"] = .array(nv.navSeq.map { .number(Double($0)) })
        } else { out["nav"] = []; out["navSeq"] = [] }
        do {
            var m: [String: JSON] = [:]; var n = 0
            for key in (out["counters"]?.object ?? [:]).keys.sorted() {
                if n >= 500 { break }
                if !Guard.matchesSafeIdPattern(key) { continue }
                m[key] = .number(numOrZero(out["counters"]![key])); n += 1
            }
            out["counters"] = .object(m)
        }
        do {
            var m: [String: JSON] = [:]; var n = 0
            let src = out["timers"]?.object ?? [:]
            for key in src.keys.sorted() {
                if n >= 200 { break }
                if !Guard.matchesSafeIdPattern(key) { continue }
                let t = src[key]!
                m[key] = ["elapsedMs": .number(numOrZero(t["elapsedMs"])), "cycles": .number(numOrZero(t["cycles"])),
                          "running": .bool(t["running"]?.truthy ?? false), "stoppedAt": .number(numOrZero(t["stoppedAt"]))]
                n += 1
            }
            out["timers"] = .object(m)
        }
        do {
            var m: [String: JSON] = [:]
            for (key, v) in out["cxBack"]?.object ?? [:] {
                guard key.count >= 1, key.count <= 6, key.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }) else { continue }
                if let s = v.string { m[key] = ["id": .string(Guard.safeId(.string(s), "b")), "t": 0] }
                else { m[key] = ["id": .string(Guard.safeId(v["id"], "b")), "t": .number(numOrZero(v["t"]))] }
            }
            out["cxBack"] = .object(m)
        }
        out["extraTimers"] = .array((out["extraTimers"]?.array ?? []).prefix(100).map { x in
            ["id": .string(Guard.safeId(x["id"], "t")), "label": .string(Guard.sstr(x["label"], 120)),
             "seconds": .number(numOrZero(x["seconds"])), "autoloop": .bool(x["autoloop"]?.truthy ?? false)]
        })
        out["extraCounters"] = .array((out["extraCounters"]?.array ?? []).prefix(100).map { x in
            ["id": .string(Guard.safeId(x["id"], "n")), "label": .string(Guard.sstr(x["label"], 120))]
        })
        out["linkArm"] = linkArm(out["linkArm"])
        out["events"] = .array((out["events"]?.array ?? []).prefix(5000).compactMap { e -> JSON? in
            guard let eo = e.object else { return e.array != nil ? ["t": 0] : nil }
            var ev: [String: JSON] = [:]
            for (k, v) in eo where !Guard.badKeys.contains(k) { ev[k] = v }
            ev["t"] = .number(numOrZero(ev["t"]))
            if ev["voidAt"] != nil { ev["voidAt"] = .number(numOrZero(ev["voidAt"])) }
            if ev["label"] != nil { ev["label"] = .string(Guard.sstr(ev["label"], 200)) }
            if let r = ref(ev["ref"]) { ev["ref"] = r } else { ev["ref"] = nil }
            return .object(ev)
        })
        return .object(out)
    }
}
