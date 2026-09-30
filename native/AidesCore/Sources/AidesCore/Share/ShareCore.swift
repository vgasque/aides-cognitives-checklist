import Foundation

// PARTAGE DE SESSION — NOYAU PUR (port de la section « share pure core » d'index.html).
//
// Miroir ADDITIF d'une session de crise vers d'autres appareils (règle 15 d'AGENTS.md) : aucun
// chemin d'interface n'attend jamais le réseau, et AUCUN TEXTE LIBRE ne traverse — le format
// transmis ne porte que des références (clés d'étape, ids de minuteur/compteur/bloc/repère) et
// des heures. Le seul mot saisi qui voyage est le RÔLE, choisi dans une liste fermée.
//
// Tout ici opère sur `JSON`, exactement comme la PWA opère sur des objets JS : le moteur de
// session natif produit la même forme d'état que le `Runtime` web (checked, verified, vgaps,
// counters, timers{running,elapsedMs,cycles,lastStart,stoppedAt}, events, nav, navSeq, cxBack,
// exercise, startedAt), et le fil porte les mêmes charges. Chaque fonction est vérifiée contre la
// PWA exécutée (`native/tools/oracle-cases/share-*.mjs`).

public enum ShareCore {

    // MARK: Listes fermées (SHARE_KEEP / SHARE_DROP / SHARE_KINDS_* / SHARE_PAYLOAD_KEYS)

    /// Clés de la fiche qui VOYAGENT (`SHARE_KEEP`) — le serveur (`share_open`) applique la même
    /// liste blanche et reste l'autorité ; `complications` est délibérément absent (geste du lead,
    /// cibles vers d'autres aides que l'invité ne possède pas).
    public static let keep = ["id", "title", "discriminant", "code", "status", "validatedAt", "blocks", "start", "timers", "counters", "items"]
    /// Documentation seulement (`SHARE_DROP`) : ce qui ne voyage jamais.
    public static let drop = ["v", "kind", "category", "local", "excursions", "sources", "images", "docs",
                              "links", "order", "updatedBy", "updatedAt", "deletedAt", "ownerId", "library"]
    /// Genres ouverts à TOUT rôle — la ligne passe sur la DESTRUCTION, pas sur la hiérarchie.
    public static let kindsAny = ["sig", "check", "verify", "gap", "counter", "timer_arm", "timer_stop", "mark", "mark_void",
                                  "nav", "flow_end", "cx", "presence", "detach", "offline_mark", "handoff"]
    /// Genres réservés au `lead` (décocher, RAZ, terminer, démarrer).
    public static let kindsLead = ["uncheck", "timer_reset", "end", "session_start"]
    /// Liste blanche des CLÉS DE CHARGE — miroir exact de `share_push` (et du hub). Toute autre
    /// clé est AMPUTÉE sur le fil : `label` (règle 15), mais aussi `cxb` et `state` (spec § 20.1-2).
    public static let payloadKeys = ["k", "t", "id", "v", "running", "elapsedMs", "cycles", "anchor",
                                     "nav", "navSeq", "on", "exo", "ref", "was", "to", "take", "o", "a", "code"]
    /// État de SESSION (voyage) vs état de VUE (propre à chaque écran) — `SHARE_TRAVELS`/`SHARE_LOCAL`.
    public static let travels = ["checked", "verified", "vgaps", "nav", "navSeq", "counters", "timers", "events", "flowEnded", "cxBack"]
    public static let local = ["confOpen", "ovFold", "ovVerify", "navPos", "rtOpen", "railTkOpen", "railLadOpen", "showFlow",
                               "readMode", "previewFrom", "cxOpen", "tkSheet", "railTmOpen", "tmAddOpen"]

    /// `shareCan(role, kind)` — capacités, miroir de `share_kind_allowed` côté serveur.
    public static func can(_ role: String?, _ kind: String) -> Bool {
        if kindsAny.contains(kind) { return role == "scribe" || role == "lead" }
        if kindsLead.contains(kind) { return role == "lead" }
        return false
    }

    /// Régime d'application d'un évènement distant (`SHARE_APPLY`).
    public enum ApplyMode: String, Sendable { case live, anchored, deferred, none }
    public static let applyTable: [String: ApplyMode] = [
        "check": .live, "uncheck": .live, "counter": .live, "mark": .live, "mark_void": .live,
        "timer_arm": .live, "timer_stop": .live, "timer_reset": .live,
        "nav": .anchored, "flow_end": .anchored, "cx": .anchored,
        "session_start": .live,
        "verify": .deferred, "gap": .deferred,
        "presence": .none, "detach": .none, "handoff": .none, "end": .none,
        "sig": .none,
        "offline_mark": .live,
    ]
    /// `shareApplyMode(kind)` — genre inconnu : 'deferred', le défaut prudent.
    public static func applyMode(_ kind: String) -> ApplyMode { applyTable[kind] ?? .deferred }

    // MARK: Projection de la fiche (`sharePayload`)

    /// Ce qui voyage de la fiche : les clés de `keep`, `blocks` TOUJOURS présent et sans `image`.
    public static func payload(_ f: JSON?) -> JSON {
        var out: [String: JSON] = [:]
        if let o = f?.object { for k in keep { if let v = o[k] { out[k] = v } } }
        let blocks = f?["blocks"]?.array ?? []
        out["blocks"] = .array(blocks.map { b in
            var c = b.object ?? [:]
            c["image"] = nil
            return .object(c)
        })
        return .object(out)
    }

    // MARK: Trace de vérification (`vfNorm`, `vfTime`, `vfActor`, `vfMapNorm`)

    public static func vfNorm(_ v: JSON?) -> JSON? {
        guard let v else { return nil }
        switch v {
        case .object, .array:
            let a = v["a"]
            return ["a": (a?.truthy ?? false) ? a! : .null, "t": .number(ShareJS.num0(v["t"]))]
        case .number(let n): return ["a": .null, "t": .number(n)]
        default: return nil
        }
    }
    public static func vfTime(_ v: JSON?) -> Double { vfNorm(v)?["t"]?.number ?? 0 }
    public static func vfActor(_ v: JSON?) -> JSON { vfNorm(v)?["a"] ?? .null }
    public static func vfMapNorm(_ m: JSON?) -> JSON {
        var o: [String: JSON] = [:]
        for (k, v) in m?.object ?? [:] { if let n = vfNorm(v) { o[k] = n } }
        return .object(o)
    }

    // MARK: Grammaires du fil (`SHARE_KEY_RX`, `_fkey`, `shareNavNorm`, `shareCxbNorm`, `cxbForFiche`)

    /// `_fkey` : clé de cochage `visite:bloc:index` validée, sinon nil.
    public static func fkey(_ v: JSON?) -> String? {
        let t: String
        if let v, !v.isNull { t = v.jsString } else { t = "" }
        return SessionSanitize.isCheckKey(t) ? t : nil
    }

    /// `shareNavNorm` rendu en JSON ({nav, navSeq}) ou nil.
    public static func navNorm(_ nav: JSON?, _ navSeq: JSON?) -> (nav: [JSON], navSeq: [JSON])? {
        guard let n = SessionSanitize.nav(nav, navSeq) else { return nil }
        return (n.nav.map { .string($0) }, n.navSeq.map { .number(Double($0)) })
    }

    /// `shareCxbNorm(cxb, navSeq)` : ancres d'excursion {visite: {id, t}} pour les visites connues.
    public static func cxbNorm(_ cxb: JSON?, _ navSeq: [JSON]) -> JSON {
        var o: [String: JSON] = [:]
        guard let src = cxb?.object else { return .object(o) }
        let seqs = Set(navSeq.map { JS.number($0) })
        for k in ShareJS.jsSorted(Array(src.keys)) {
            let n = JS.round(JS.number(string: k))
            guard n.isFinite, n > 0, seqs.contains(n), let v = src[k], v.object != nil || v.array != nil else { continue }
            let id = Guard.safeId(v["id"], "b")
            o[String(Int(n))] = ["id": .string(id), "t": .number(ShareJS.num0(v["t"]))]
        }
        return .object(o)
    }

    /// `cxbForFiche(cxb, f)` : ne garde que les ancres dont la cible est un bloc de NOTRE copie.
    public static func cxbForFiche(_ cxb: JSON?, _ fiche: JSON?) -> JSON {
        var o: [String: JSON] = [:]
        let ids = Set((fiche?["blocks"]?.array ?? []).compactMap { $0["id"] })
        for (k, v) in cxb?.object ?? [:] {
            if v.truthy, let id = v["id"], ids.contains(id) { o[k] = v }
        }
        return .object(o)
    }

    // MARK: Instantané (`shareSnap`)

    /// Instantané NORMALISÉ d'une session (forme du `Runtime` web) — la base de l'émission par
    /// différence. `flowEnded` est un état de VUE que l'appelant fournit.
    public static func snap(_ r: JSON?, flowEnded: Bool) -> JSON {
        let R = r ?? .object([:])
        var tm: [String: JSON] = [:]
        for (k, t0) in R["timers"]?.object ?? [:] {
            let t = t0.truthy ? t0 : .object([:])
            tm[k] = ["running": .bool(ShareJS.truthy(t["running"])), "elapsedMs": .number(ShareJS.num0(t["elapsedMs"])),
                     "cycles": .number(ShareJS.num0(t["cycles"])), "anchor": .number(ShareJS.num0(t["lastStart"])),
                     "stoppedAt": .number(ShareJS.num0(t["stoppedAt"]))]
        }
        var cn: [String: JSON] = [:]
        for (k, v) in R["counters"]?.object ?? [:] { cn[k] = .number(ShareJS.num0(v)) }
        let events: [JSON] = (R["events"]?.array ?? []).map { e in
            var o: [String: JSON] = [:]
            if let id = e["id"] { o["id"] = id }
            o["t"] = .number(ShareJS.num0(e["t"]))
            o["ref"] = (e["ref"]?.truthy ?? false) ? e["ref"]! : .null
            o["voidAt"] = (e["voidAt"]?.truthy ?? false) ? e["voidAt"]! : .null
            return .object(o)
        }
        var cxb: [String: JSON] = [:]
        for (k, v) in R["cxBack"]?.object ?? [:] {
            if v.truthy, let id = v["id"], id.truthy { cxb[k] = ["id": .string(id.jsString), "t": .number(ShareJS.num0(v["t"]))] }
        }
        return [
            "checked": .object(R["checked"]?.object ?? [:]),
            "verified": vfMapNorm(R["verified"]), "vgaps": vfMapNorm(R["vgaps"]),
            "counters": .object(cn), "timers": .object(tm),
            "events": .array(events),
            "nav": .array(R["nav"]?.array ?? []), "navSeq": .array(R["navSeq"]?.array ?? []),
            "flowEnded": .bool(flowEnded),
            "cxb": .object(cxb),
            "exercise": .bool(ShareJS.truthy(R["exercise"])),
            "startedAt": .number(ShareJS.num0(R["startedAt"])),
        ]
    }

    /// Instantané vide (`shareSnap(null,false)`) — la base d'où l'on « rembobine » tout l'état à
    /// l'ouverture d'un partage.
    public static let emptySnap: JSON = snap(nil, flowEnded: false)

    // MARK: Différence (`shareDiff`)

    /// Un évènement à émettre : {kind, payload}.
    public struct Emit: Equatable, Sendable {
        public var kind: String
        public var payload: JSON
        public var json: JSON { ["kind": .string(kind), "payload": payload] }
    }

    /// `Array.join(sep)` : null/undefined → chaîne vide.
    static func join(_ a: [JSON], _ sep: String) -> String { a.map { $0.isNull ? "" : $0.jsString }.joined(separator: sep) }
    /// `e.payload || {}` — ⚠ jamais `cond ? x : nil` quand le type attendu est `JSON?` : `JSON` est
    /// `ExpressibleByNilLiteral`, et ce `nil` devient `.null` ENVELOPPÉ, pas l'absence.
    static func payloadOrEmpty(_ e: JSON) -> JSON {
        if let p = e["payload"], p.truthy { return p }
        return .object([:])
    }
    /// `x || null`
    static func orNull(_ v: JSON?) -> JSON { (v?.truthy ?? false) ? v! : .null }

    /// Évènements qui font passer de l'instantané `a` à `b`, dans l'ordre du journal web :
    /// check, uncheck, verify, gap, counter, timers, repères, nav, flow_end, session_start.
    /// Les clés d'objets sont parcourues triées (le JS suit l'ordre d'insertion — sans effet sur
    /// l'état plié, seulement sur l'ordre des lignes d'un même lot).
    /// `sessionId` : l'identité OPTIQUE de la session locale, portée par `session_start.id`.
    public static func diff(_ a0: JSON?, _ b0: JSON?, sessionId: String? = nil) -> [Emit] {
        // `a || shareSnap(null,false)` — ⚠ `nil` s'écrit aussi `.null` (JSON est ExpressibleByNilLiteral).
        let a = (a0 == nil || a0!.isNull) ? emptySnap : a0!, b = (b0 == nil || b0!.isNull) ? emptySnap : b0!
        var out: [Emit] = []
        let ac = a["checked"]?.object ?? [:], bc = b["checked"]?.object ?? [:]
        for k in ShareJS.jsSorted(Array(bc.keys)) where !(ac[k]?.truthy ?? false) { out.append(Emit(kind: "check", payload: ["k": .string(k)])) }
        for k in ShareJS.jsSorted(Array(ac.keys)) where !(bc[k]?.truthy ?? false) { out.append(Emit(kind: "uncheck", payload: ["k": .string(k)])) }
        for (field, kind) in [("verified", "verify"), ("vgaps", "gap")] {
            let av = a[field]?.object ?? [:], bv = b[field]?.object ?? [:]
            for k in ShareJS.jsSorted(Array(bv.keys)) {
                let y = bv[k]!
                if let x = av[k], x.truthy, x["t"] == y["t"], x["a"] == y["a"] { continue }
                out.append(Emit(kind: kind, payload: ["k": .string(k), "t": y["t"] ?? .null]))
            }
        }
        let an = a["counters"]?.object ?? [:], bn = b["counters"]?.object ?? [:]
        for k in ShareJS.jsSorted(Array(bn.keys)) where an[k] != bn[k] {
            out.append(Emit(kind: "counter", payload: ["id": .string(k), "v": bn[k]!]))
        }
        let at = a["timers"]?.object ?? [:], bt = b["timers"]?.object ?? [:]
        for k in ShareJS.jsSorted(Array(bt.keys)) {
            let x = at[k] ?? .object([:]), y = bt[k]!
            if x["running"] != y["running"] || x["elapsedMs"] != y["elapsedMs"] || x["cycles"] != y["cycles"] || x["anchor"] != y["anchor"] {
                out.append(Emit(kind: ShareJS.truthy(y["running"]) ? "timer_arm" : "timer_stop",
                                payload: ["id": .string(k), "running": y["running"] ?? .null, "elapsedMs": y["elapsedMs"] ?? .null,
                                          "cycles": y["cycles"] ?? .null, "anchor": y["anchor"] ?? .null]))
            }
        }
        // Journal d'actions : append-only ; un repère ne disparaît pas, il s'annule.
        do {
            var seen: [String: JSON] = [:]
            func key(_ e: JSON) -> String { e["id"].map { $0.jsString } ?? "undefined" }
            for e in a["events"]?.array ?? [] { seen[key(e)] = e }
            for e in b["events"]?.array ?? [] {
                var markPl: [String: JSON] = ["t": e["t"] ?? .null, "ref": e["ref"] ?? .null]
                if let id = e["id"] { markPl["id"] = id }
                guard let old = seen[key(e)] else {
                    out.append(Emit(kind: "mark", payload: .object(markPl)))
                    if ShareJS.truthy(e["voidAt"]) {
                        var p: [String: JSON] = ["on": true, "t": e["voidAt"]!]
                        if let id = e["id"] { p["id"] = id }
                        out.append(Emit(kind: "mark_void", payload: .object(p)))
                    }
                    continue
                }
                if orNull(old["ref"]) != orNull(e["ref"]) || ShareJS.num0(old["t"]) != ShareJS.num0(e["t"]) {
                    out.append(Emit(kind: "mark", payload: .object(markPl)))
                }
                if orNull(old["voidAt"]) != orNull(e["voidAt"]) {
                    var p: [String: JSON] = ["on": .bool(ShareJS.truthy(e["voidAt"])), "t": ShareJS.truthy(e["voidAt"]) ? e["voidAt"]! : 0]
                    if let id = e["id"] { p["id"] = id }
                    out.append(Emit(kind: "mark_void", payload: .object(p)))
                }
            }
        }
        // Navigation : le couple nav/navSeq voyage INDISSOCIABLE (les clés de cochage en dépendent).
        let aNav = a["nav"]?.array ?? [], bNav = b["nav"]?.array ?? []
        let aSeq = a["navSeq"]?.array ?? [], bSeq = b["navSeq"]?.array ?? []
        if join(aNav, "|") != join(bNav, "|") || join(aSeq, "|") != join(bSeq, "|") {
            out.append(Emit(kind: "nav", payload: ["nav": .array(bNav), "navSeq": .array(bSeq), "cxb": orObject(b["cxb"])]))
        }
        if a["flowEnded"] != b["flowEnded"] { out.append(Emit(kind: "flow_end", payload: ["on": b["flowEnded"] ?? .null])) }
        if a["startedAt"] != b["startedAt"], ShareJS.truthy(b["startedAt"]) {
            var p: [String: JSON] = ["t": b["startedAt"]!, "exo": .bool(ShareJS.truthy(b["exercise"]))]
            if let s = sessionId, !s.isEmpty { p["id"] = .string(s) }
            out.append(Emit(kind: "session_start", payload: .object(p)))
        }
        return out
    }
    static func orObject(_ v: JSON?) -> JSON { (v?.truthy ?? false) ? v! : .object([:]) }

    // MARK: Pli (`shareFold`)

    /// État plié initial (`shareFold([])`).
    public static let emptyFold: JSON = [
        "checked": [:], "verified": [:], "vgaps": [:], "counters": [:], "timers": [:], "nav": [], "navSeq": [],
        "cxb": [:], "events": [], "flowEnded": false, "annex": [], "startedAt": 0, "exercise": false,
    ]

    /// Pli du journal : évènements → état. Déterministe et pur — deux appareils qui plient la même
    /// suite obtiennent le même état (ce que `stateHash` et l'empreinte du flux vérifient).
    public static func fold(_ events: [JSON], base: JSON? = nil) -> JSON {
        var s = emptyFold.object!
        for (k, v) in base?.object ?? [:] { s[k] = v }
        var checked = s["checked"]?.object ?? [:], verified = s["verified"]?.object ?? [:], vgaps = s["vgaps"]?.object ?? [:]
        var counters = s["counters"]?.object ?? [:], timers = s["timers"]?.object ?? [:]
        var evs = s["events"]?.array ?? [], annex = s["annex"]?.array ?? []
        func find(_ id: String) -> Int? { evs.firstIndex { $0["id"] == .string(id) } }
        for e in events {
            let p = payloadOrEmpty(e)
            let actor = e["actor"]
            switch e["kind"]?.string ?? "" {
            case "check": if let k = fkey(p["k"]) { checked[k] = true }
            case "uncheck": if let k = fkey(p["k"]) { checked[k] = nil }
            case "verify":
                if let k = fkey(p["k"]) { verified[k] = vfEntry(actor, ShareJS.fnum(p["t"], e["ts"])); vgaps[k] = nil }
            case "gap":
                if let k = fkey(p["k"]) { vgaps[k] = vfEntry(actor, ShareJS.fnum(p["t"], e["ts"])); verified[k] = nil }
            case "counter":
                if let id = p["id"], !id.isNull { counters[Guard.safeId(id, "c")] = .number(ShareJS.fnum(p["v"], 0)) }
            case "timer_arm", "timer_stop", "timer_reset":
                if let id = p["id"], !id.isNull {
                    let run = ShareJS.truthy(p["running"])
                    timers[Guard.safeId(id, "t")] = ["running": .bool(run), "elapsedMs": .number(ShareJS.fnum(p["elapsedMs"], 0)),
                                                     "cycles": .number(ShareJS.fnum(p["cycles"], 0)), "anchor": .number(ShareJS.fnum(p["anchor"], 0)),
                                                     "stoppedAt": .number(run ? 0 : ShareJS.eventTimeMs(e))]
                }
            case "nav":
                if let n = navNorm(p["nav"], p["navSeq"]) {
                    s["nav"] = .array(n.nav); s["navSeq"] = .array(n.navSeq); s["cxb"] = cxbNorm(p["cxb"], n.navSeq)
                }
            case "flow_end": s["flowEnded"] = .bool(ShareJS.truthy(p["on"]))
            case "session_start":
                let t = JS.number(p["t"])
                if !t.isNaN, t != 0 { s["startedAt"] = .number(t) }
                s["exercise"] = .bool(ShareJS.truthy(p["exo"]))
                if let id = p["id"], id.truthy { s["sessId"] = .string(id.jsString) }
            case "mark":
                let id = Guard.safeId(p["id"], "e")
                if let i = find(id) {
                    var ex = evs[i].object ?? [:]
                    ex["t"] = .number(ShareJS.fnum(p["t"], ex["t"]))
                    ex["ref"] = SessionSanitize.ref(p["ref"]) ?? .null
                    if let a = actor, a.truthy { ex["a"] = a }
                    evs[i] = .object(ex)
                } else {
                    var n: [String: JSON] = ["id": .string(id), "t": .number(ShareJS.fnum(p["t"], e["ts"])), "ref": SessionSanitize.ref(p["ref"]) ?? .null]
                    if let a = actor { n["a"] = a }
                    evs.append(.object(n))
                }
            case "mark_void":
                if let i = find(Guard.safeId(p["id"], "e")) {
                    var m = evs[i].object ?? [:]
                    if ShareJS.truthy(p["on"]) {
                        let t = ShareJS.fnum(p["t"], e["ts"])
                        m["voidAt"] = .number(t == 0 ? 1 : t)
                    } else { m["voidAt"] = .null }
                    evs[i] = .object(m)
                }
            case "offline_mark":
                var n: [String: JSON] = ["t": .number(ShareJS.fnum(p["t"], e["ts"])), "ref": SessionSanitize.ref(p["ref"]) ?? .null]
                if let a = actor { n["a"] = a }
                annex.append(.object(n))
            default: break   // sig, presence, detach, handoff, cx, end, inconnu : sans effet d'état
            }
        }
        s["checked"] = .object(checked); s["verified"] = .object(verified); s["vgaps"] = .object(vgaps)
        s["counters"] = .object(counters); s["timers"] = .object(timers); s["events"] = .array(evs); s["annex"] = .array(annex)
        return .object(s)
    }

    /// `{a: e.actor, t}` — un acteur absent (`undefined`) n'écrit pas de clé, comme en JS.
    static func vfEntry(_ actor: JSON?, _ t: Double) -> JSON {
        var o: [String: JSON] = ["t": .number(t)]
        if let a = actor { o["a"] = a }
        return .object(o)
    }

    // MARK: Assainissement d'un instantané optique (`slFoldSan`)

    /// Liste FERMÉE : un miroir ne réécrit rien, il n'a pas le besoin « liste grise » de
    /// `sanitizeSession`. Aucun libellé de repère ne traverse (règle 15).
    public static func foldSan(_ s0: JSON?) -> JSON {
        let s = (s0?.object != nil || s0?.array != nil) ? s0! : .object([:])
        func map(_ src: JSON?, _ max: Int, _ ok: (String) -> Bool, _ f: (JSON) -> JSON) -> JSON {
            var m: [String: JSON] = [:], n = 0
            if let o = src?.object {
                for k in ShareJS.jsSorted(Array(o.keys)) {
                    if n >= max { break }
                    if !ok(k) { continue }
                    m[k] = f(o[k]!); n += 1
                }
            }
            return .object(m)
        }
        let nv = navNorm(s["nav"], s["navSeq"]) ?? ([], [])
        let events: [JSON] = (s["events"]?.array ?? []).prefix(5000).filter { $0.object != nil || $0.array != nil }.map { e in
            let va = e["voidAt"]
            return ["id": .string(Guard.sstr(e["id"], 80)), "t": .number(ShareJS.num0(e["t"])),
                    "ref": SessionSanitize.ref(e["ref"]) ?? .null,
                    "voidAt": (va == nil || va!.isNull) ? .null : .number(ShareJS.num0(va))]
        }
        return [
            "checked": map(s["checked"], 4000, SessionSanitize.isCheckKey) { .bool($0.truthy) },
            "verified": vfMapNorm(map(s["verified"], 4000, SessionSanitize.isCheckKey) { $0 }),
            "vgaps": vfMapNorm(map(s["vgaps"], 4000, SessionSanitize.isCheckKey) { $0 }),
            "counters": map(s["counters"], 500, Guard.matchesSafeIdPattern) { .number(ShareJS.num0($0)) },
            "timers": map(s["timers"], 200, Guard.matchesSafeIdPattern) { t0 in
                let t = (t0.object != nil || t0.array != nil) ? t0 : .object([:])
                return ["running": .bool(ShareJS.truthy(t["running"])), "elapsedMs": .number(ShareJS.num0(t["elapsedMs"])),
                        "cycles": .number(ShareJS.num0(t["cycles"])), "anchor": .number(ShareJS.num0(t["anchor"])),
                        "stoppedAt": .number(ShareJS.num0(t["stoppedAt"]))]
            },
            "events": .array(events),
            "nav": .array(nv.nav), "navSeq": .array(nv.navSeq), "cxb": cxbNorm(s["cxb"], nv.navSeq),
            "flowEnded": .bool(ShareJS.truthy(s["flowEnded"])), "exercise": .bool(ShareJS.truthy(s["exercise"])),
            "startedAt": .number(ShareJS.num0(s["startedAt"])),
        ]
    }

    // MARK: Empreinte d'état (`shareStateHash`) — tests et harnais

    /// FNV-1a 32 bits sur une sérialisation TRIÉE de l'état, rendue en base 36.
    public static func stateHash(_ s: JSON) -> String {
        func keys(_ f: String) -> [String] { ShareJS.jsSorted(Array((s[f]?.object ?? [:]).keys)) }
        var parts: [String] = []
        parts.append("c:" + keys("checked").filter { s["checked"]![$0]!.truthy }.joined(separator: ","))
        parts.append("v:" + keys("verified").joined(separator: ","))
        parts.append("g:" + keys("vgaps").joined(separator: ","))
        parts.append("n:" + join(s["nav"]?.array ?? [], ",") + "|" + join(s["navSeq"]?.array ?? [], ","))
        parts.append("k:" + keys("counters").map { k in k + "=" + (s["counters"]![k]!.isNull ? "null" : s["counters"]![k]!.jsString) }.joined(separator: ","))
        parts.append("t:" + keys("timers").map { k in
            let c = s["timers"]![k]!["cycles"]
            return k + "=" + ((c?.truthy ?? false) ? c!.jsString : "0")
        }.joined(separator: ","))
        parts.append("f:" + (ShareJS.truthy(s["flowEnded"]) ? "1" : "0"))
        var h: UInt32 = 0x811c9dc5
        for u in parts.joined(separator: ";").utf16 { h ^= UInt32(u); h = h &* 0x01000193 }
        return String(h, radix: 36)
    }

    // MARK: Horloge de Cristian (`shareOffset`)

    public struct ClockSample: Equatable, Sendable {
        public var t0: Double, t1: Double, srv: Double
        public init(t0: Double, t1: Double, srv: Double) { self.t0 = t0; self.t1 = t1; self.srv = srv }
    }
    /// Décalage serveur − local : médiane des mesures dont l'aller-retour est dans [0, maxRtt].
    /// nil si aucune ne qualifie (on GARDE alors le dernier bon décalage).
    public static func offset(_ samples: [ClockSample], maxRtt: Double = 400) -> Double? {
        var offs: [Double] = []
        for s in samples {
            let rtt: Double = s.t1 - s.t0
            if rtt >= 0 && rtt <= maxRtt { offs.append(s.srv + rtt / 2 - s.t1) }
        }
        offs.sort()
        guard !offs.isEmpty else { return nil }
        let m = offs.count >> 1
        return JS.round(offs.count % 2 == 1 ? offs[m] : (offs[m - 1] + offs[m]) / 2)
    }

    // MARK: Amputation (share_push / slHub.push)

    /// Charge reconstruite depuis la liste blanche — ce que le serveur et le hub stockent.
    public static func whitelist(_ payload: JSON?) -> JSON {
        var o: [String: JSON] = [:]
        if let src = payload?.object { for (k, v) in src where payloadKeys.contains(k) { o[k] = v } }
        return .object(o)
    }

    // MARK: Présence observée (`shareSeenSilenceMs`, `shareHostSilenceMs`, `sharePresent`)

    /// `seen` : ISO côté serveur, NOMBRE côté hub local — les deux se lisent.
    public static func seenMs(_ v: JSON?) -> Double? {
        switch v {
        case .number(let n)?: return n.isFinite ? n : nil
        case .string(let s)?: return ShareJS.isoMs(s)
        default: return nil
        }
    }
    /// Silence d'un participant (0 pour le propriétaire), en heure SERVEUR (`Share.now()`).
    public static func silenceMs(_ p: JSON?, serverNow: Double) -> Double {
        guard let p, !ShareJS.truthy(p["owner"]), let t = seenMs(p["seen"]) else { return 0 }
        return max(0, serverNow - t)
    }
}

// MARK: - Code d'appariement (cloud)

/// Codes de session — lecture, normalisation, affichage (`SHARE_ALPHA`, `shareCode*`).
/// L'alphabet est RECOPIÉ du serveur, seule autorité. On NE DEVINE PAS : `0 1 I O` sont absents
/// du jeu, les saisir est une erreur, et on la dit au lieu de la « corriger ».
public enum ShareCode {
    public static let alphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
    public static let length = 8
    static let alphaSet = Set(alphabet)

    /// `shareCodeNorm` : majuscules, tout ce qui n'est pas [0-9A-Z] retiré.
    public static func norm(_ s: String?) -> String {
        String((s ?? "").uppercased().filter { c in c.isASCII && (c.isNumber || (c >= "A" && c <= "Z")) })
    }
    public static func isValid(_ s: String?) -> Bool {
        let c = norm(s)
        return c.count == length && c.allSatisfy { alphaSet.contains($0) }
    }
    /// Caractères saisis qui n'existent dans aucun code (dédoublonnés, dans l'ordre).
    public static func badChars(_ s: String?) -> [String] {
        var out: [String] = []
        for ch in norm(s) where !alphaSet.contains(ch) { if !out.contains(String(ch)) { out.append(String(ch)) } }
        return out
    }
    /// « XXXX-XXXX » — le tiret n'est JAMAIS transmis.
    public static func format(_ s: String?) -> String {
        let c = norm(s)
        return c.count == length ? String(c.prefix(4)) + "-" + String(c.suffix(4)) : c
    }
    /// `shareCodeFromHash` : `/[#&]j=([0-9A-Za-z-]{1,24})/` puis validation.
    public static func fromHash(_ h: String?) -> String? {
        let u = Array((h ?? "").unicodeScalars)
        var i = 0
        while i + 2 < u.count {
            if (u[i] == "#" || u[i] == "&"), u[i + 1] == "j", u[i + 2] == "=" {
                var j = i + 3, cap = ""
                while j < u.count, cap.unicodeScalars.count < 24 {
                    let c = u[j]
                    guard c.isASCII, CharacterSet.alphanumerics.contains(c) || c == "-" else { break }
                    cap.unicodeScalars.append(c); j += 1
                }
                if !cap.isEmpty { return isValid(cap) ? norm(cap) : nil }
            }
            i += 1
        }
        return nil
    }
    /// `shareJoinUrl` : `<adresse de l'app web>#j=<CODE>` — le code dans le FRAGMENT, jamais dans
    /// la query (aucun journal de serveur ni proxy ne le voit). `webAppURL` est l'adresse
    /// canonique du déploiement web (origine + chemin) ; sans adresse http(s), nil : le QR
    /// porte alors le CODE SEUL.
    public static func joinURL(webAppURL: String?, code: String) -> String? {
        guard let w = webAppURL, w.lowercased().hasPrefix("http:") || w.lowercased().hasPrefix("https:") else { return nil }
        let base = w.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? w
        return base + "#j=" + code
    }
}
