import Foundation

// PARTAGE — APPLICATION D'UN ÉVÈNEMENT DISTANT À UNE SESSION (port de `shareStateLive`,
// `shareNavState`, `shareVfState`, `shareApplyAway`).
//
// L'ÉTAT est SÉPARÉ de la PEINTURE (A387) : ces fonctions n'écrivent que la session (JSON de la
// forme du `Runtime` web), jamais l'écran. L'app peint ensuite — sans re-rendu complet, sans
// modale, sans défilement automatique (règle 11) : un évènement distant ne déplace jamais le sol
// sous le doigt de quelqu'un qui lit.
//
// Trois interdits hérités de la PWA : (1) aucun évènement de SOI n'est appliqué (écho), (2) aucun
// LIBELLÉ n'est lu du réseau — un repère reçu n'a qu'une RÉFÉRENCE, le mot se dérive de NOTRE
// copie de la fiche (règle 15 à la réception), (3) un minuteur ou un compteur inconnu de notre
// copie est ignoré (les ad hoc de l'hôte ne se créent pas chez l'invité — spec § 20.9).

public enum ShareApply {

    /// Répartit un lot selon `SHARE_APPLY`, sans ses propres évènements ni les 'none' :
    /// 'live' à appliquer et peindre tout de suite, 'anchored' (nav, flow_end) à appliquer en
    /// gardant l'ancre de lecture, 'deferred' (verify, gap) au prochain geste LOCAL.
    public static func partition(_ evs: [JSON], me: String?) -> (live: [JSON], anchored: [JSON], deferred: [JSON]) {
        var l: [JSON] = [], a: [JSON] = [], d: [JSON] = []
        for e in evs {
            if let actor = e["actor"]?.string, actor == me { continue }
            switch ShareCore.applyMode(e["kind"]?.string ?? "") {
            case .none: continue
            case .anchored: a.append(e)
            case .live: l.append(e)
            case .deferred: d.append(e)
            }
        }
        return (l, a, d)
    }

    /// Tri STABLE par heure (le `Array.prototype.sort` de V8 l'est ; celui de Swift non).
    static func sortByT(_ evs: [JSON]) -> [JSON] {
        evs.enumerated().sorted { x, y in
            let a = ShareJS.num0(x.element["t"]), b = ShareJS.num0(y.element["t"])
            return a != b ? a < b : x.offset < y.offset
        }.map(\.element)
    }

    /// `shareStateLive(R, e)` — l'état d'un évènement « vivant » sur la session `R`.
    /// `serverNow` = `Share.now()`, `offset` = `Share.offset`. Rend vrai si quelque chose a changé.
    ///
    /// ⚠ Écart assumé : la clé d'un `check`/`uncheck` est validée par `SHARE_KEY_RX` (la PWA ne la
    /// valide qu'au pli) — une clé hors grammaire est ignorée au lieu d'entrer dans l'état.
    @discardableResult
    public static func stateLive(_ R: inout JSON, _ e: JSON, serverNow: Double, offset: Double) -> Bool {
        guard var r = R.object else { return false }
        defer { R = .object(r) }
        let p = ShareCore.payloadOrEmpty(e)
        let actor: JSON = (e["actor"]?.truthy ?? false) ? e["actor"]! : .null
        switch e["kind"]?.string ?? "" {
        case "check", "uncheck":
            guard let k = ShareCore.fkey(p["k"]) else { return false }
            var checked = r["checked"]?.object ?? [:], verified = r["verified"]?.object ?? [:], vgaps = r["vgaps"]?.object ?? [:]
            if e["kind"]?.string == "check" { checked[k] = true; vgaps[k] = nil } else { checked[k] = nil; verified[k] = nil }
            r["checked"] = .object(checked); r["verified"] = .object(verified); r["vgaps"] = .object(vgaps)
            return true
        case "offline_mark":
            // L'annexe d'un détaché entre au JOURNAL, jamais dans l'état (clés de visite divergentes).
            var evs = r["events"]?.array ?? []
            let tPart = (p["t"]?.truthy ?? false) ? p["t"]!.jsString : "0"
            let sPart = (e["seq"]?.truthy ?? false) ? e["seq"]!.jsString : "0"
            let id = Guard.safeId(.string("ax-" + tPart + "-" + sPart), "e")
            if evs.contains(where: { $0["id"]?.string == id }) { return false }
            let t = ShareJS.num0(p["t"])
            evs.append(["id": .string(id), "t": .number(t != 0 ? t : serverNow), "a": actor, "annex": true,
                        "ref": SessionSanitize.ref(p["ref"]) ?? .null])
            r["events"] = .array(sortByT(evs))
            return true
        case "session_start":
            let t = ShareJS.num0(p["t"])
            guard t != 0 else { return false }
            r["startedAt"] = .number(t)
            return true
        case "counter":
            guard let idv = p["id"], !idv.isNull, var cn = r["counters"]?.object, cn[idv.jsString] != nil else { return false }
            cn[idv.jsString] = .number(ShareJS.num0(p["v"]))
            r["counters"] = .object(cn)
            return true
        case "timer_arm", "timer_stop", "timer_reset":
            // L'ANCRE ABSOLUE voyage ; convertie en heure LOCALE par le décalage mesuré.
            guard let idv = p["id"], var tm = r["timers"]?.object, var t = tm[idv.jsString]?.object else { return false }
            let run = ShareJS.truthy(p["running"])
            t["running"] = .bool(run)
            t["elapsedMs"] = .number(ShareJS.num0(p["elapsedMs"]))
            t["cycles"] = .number(ShareJS.num0(p["cycles"]))
            let anchor = ShareJS.num0(p["anchor"])
            t["lastStart"] = .number(run ? ((anchor != 0 ? anchor : serverNow) - offset) : 0)
            let ets = ShareJS.eventTimeMs(e)
            t["stoppedAt"] = .number(run ? 0 : ((ets != 0 ? ets : serverNow) - offset))
            t["stopClosed"] = false
            tm[idv.jsString] = .object(t)
            r["timers"] = .object(tm)
            return true
        case "mark":
            var evs = r["events"]?.array ?? []
            let id = Guard.safeId(p["id"], "e")
            let ref = SessionSanitize.ref(p["ref"]) ?? .null
            let t = ShareJS.num0(p["t"])
            if let i = evs.firstIndex(where: { $0["id"]?.string == id }) {
                // Mise à jour EN PLACE ; un libellé MANUEL local reste souverain (jamais écrasé).
                var ex = evs[i].object ?? [:]
                ex["t"] = t != 0 ? .number(t) : (ex["t"] ?? .null)
                ex["ref"] = ref
                if actor.truthy { ex["a"] = actor }
                evs[i] = .object(ex)
            } else {
                evs.append(["id": .string(id), "t": .number(t != 0 ? t : serverNow), "a": actor, "ref": ref])
            }
            r["events"] = .array(sortByT(evs))
            return true
        case "mark_void":
            var evs = r["events"]?.array ?? []
            guard let pid = p["id"], let i = evs.firstIndex(where: { $0["id"] == pid }) else { return false }
            var m = evs[i].object ?? [:]
            let t = ShareJS.num0(p["t"])
            m["voidAt"] = ShareJS.truthy(p["on"]) ? .number(t != 0 ? t : serverNow) : .null
            evs[i] = .object(m)
            r["events"] = .array(evs)
            return true
        default:
            return false
        }
    }

    /// `shareNavState(R, p)` : nav/navSeq REMPLACÉS en couple, compteur de visites relevé au-dessus
    /// de tout ce qui a été minté ailleurs, ancres d'excursion validées contre NOTRE fiche.
    /// Rend la navSeq d'AVANT (pour remapper les replis par visite) ou nil si la charge est invalide.
    @discardableResult
    public static func navState(_ R: inout JSON, _ p: JSON, fiche: JSON?) -> [JSON]? {
        guard var r = R.object, let nn = ShareCore.navNorm(p["nav"], p["navSeq"]) else { return nil }
        let before = r["navSeq"]?.array ?? []
        r["nav"] = .array(nn.nav); r["navSeq"] = .array(nn.navSeq)
        let mx = nn.navSeq.compactMap(\.number).max() ?? 0
        r["seq"] = .number(max(ShareJS.num0(r["seq"]), mx))
        r["cxBack"] = ShareCore.cxbForFiche(ShareCore.cxbNorm(p["cxb"], nn.navSeq), fiche)
        R = .object(r)
        return before
    }

    /// `shareVfState(R, e)` : même écriture que le pli (`{a, t}`, registre opposé effacé).
    @discardableResult
    public static func vfState(_ R: inout JSON, _ e: JSON) -> Bool {
        guard var r = R.object else { return false }
        let p = e["payload"] ?? .object([:])
        guard let k = ShareCore.fkey(p["k"]) else { return false }
        let v = ShareCore.vfEntry(e["actor"], ShareJS.fnum(p["t"], e["ts"]))
        var verified = r["verified"]?.object ?? [:], vgaps = r["vgaps"]?.object ?? [:]
        if e["kind"]?.string == "verify" { verified[k] = v; vgaps[k] = nil } else { vgaps[k] = v; verified[k] = nil }
        r["verified"] = .object(verified); r["vgaps"] = .object(vgaps)
        R = .object(r)
        return true
    }

    /// `shareApplyAway(R, evs)` : l'hôte consulte une AUTRE aide — le lot va à la session
    /// hébergée, en état seul (rien ne se peint, `flowEnded` est un état de vue et ne bouge pas).
    public static func applyAway(_ R: inout JSON, _ evs: [JSON], me: String?, fiche: JSON?, serverNow: Double, offset: Double) -> Int {
        var n = 0
        for e in evs {
            if let a = e["actor"]?.string, a == me { continue }
            let kind = e["kind"]?.string ?? ""
            if ShareCore.applyMode(kind) == .none { continue }
            if kind == "nav" { if navState(&R, e["payload"] ?? .object([:]), fiche: fiche) != nil { n += 1 } }
            else if kind == "verify" || kind == "gap" { if vfState(&R, e) { n += 1 } }
            else if stateLive(&R, e, serverNow: serverNow, offset: offset) { n += 1 }
        }
        return n
    }

    /// Graine de la session PARTAGÉE à partir du pli (ce que `openSharedFiche` passe à
    /// `buildRuntime`) : champs de session + `shared:true`. Le moteur de session natif la
    /// consomme comme une session reprise, sans dossier local (`sessionId` nul).
    public static func sharedSessionSeed(fold: JSON?) -> JSON {
        var f = (fold ?? ShareCore.emptyFold).object ?? [:]
        f["shared"] = true
        return .object(f)
    }

    /// Minuteurs de la session partagée reconstruits DEPUIS LE PLI. La PWA les rebâtit en pause
    /// (spec § 20.5 : après un rechargement ou un miroir, un minuteur qui tourne paraît arrêté
    /// jusqu'au prochain évènement) ; le natif RESTAURE la marche (`lastStart = ancre − décalage`),
    /// ce qui reste interopérable (même convention d'ancre que `stateLive`). Les arrêtés gardent
    /// leur date d'arrêt convertie en heure locale.
    public static func restoreTimers(_ R: inout JSON, fold: JSON?, offset: Double, serverNow: Double) {
        guard var r = R.object, var tm = r["timers"]?.object, let ft = fold?["timers"]?.object else { return }
        for (id, sv) in ft {
            guard var t = tm[id]?.object else { continue }
            t["elapsedMs"] = .number(ShareJS.num0(sv["elapsedMs"])); t["cycles"] = .number(ShareJS.num0(sv["cycles"]))
            if ShareJS.truthy(sv["running"]) {
                let a = ShareJS.num0(sv["anchor"])
                t["running"] = true; t["lastStart"] = .number((a != 0 ? a : serverNow) - offset); t["stoppedAt"] = 0
            } else {
                t["running"] = false; t["lastStart"] = 0
                let s = ShareJS.num0(sv["stoppedAt"])
                if s != 0 { t["stoppedAt"] = .number(s - offset); t["stopClosed"] = false }
            }
            tm[id] = .object(t)
        }
        r["timers"] = .object(tm)
        R = .object(r)
    }
}
