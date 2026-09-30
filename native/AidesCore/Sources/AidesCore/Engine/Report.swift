import Foundation

// COMPTE-RENDU DE SESSION — port de `exportSessionReport`, `stepTextFromKey`, `tkLabels`.
//
// Le compte-rendu est un DOCUMENT autonome (HTML) : l'application l'affiche, l'enregistre en PDF
// (impression système) ou le partage en .html — jamais automatiquement. Toute valeur interpolée
// passe par `esc` (le seul endroit où une chaîne devient un document entier : une injection ici
// serait une XSS dans la vue web qui l'affiche).

public enum HTML {
    /// `esc` : & < > " ' échappés (le backtick reste, décision mesurée de la PWA).
    public static func esc(_ s: String) -> String {
        var o = ""
        o.reserveCapacity(s.utf8.count)
        for c in s.unicodeScalars {
            switch c {
            case "&": o += "&amp;"
            case "<": o += "&lt;"
            case ">": o += "&gt;"
            case "\"": o += "&quot;"
            case "'": o += "&#39;"
            default: o.unicodeScalars.append(c)
            }
        }
        return o
    }
    /// `fmt` : esc() d'abord, puis chaque **…** (non vide, sans saut de ligne) devient <b>…</b>.
    public static func fmt(_ s: String) -> String {
        let e = esc(s)
        var out = ""
        var rest = Substring(e)
        while let a = rest.range(of: "**") {
            let after = rest[a.upperBound...]
            if let b = after.range(of: "**") {
                let inner = after[..<b.lowerBound]
                if !inner.isEmpty && !inner.contains("*") && !inner.contains("\n") {
                    out += rest[..<a.lowerBound] + "<b>" + inner + "</b>"
                    rest = after[b.upperBound...]
                    continue
                }
            }
            out += rest[..<a.upperBound]
            rest = after
        }
        return out + rest
    }
    /// `stripBold`.
    public static func stripBold(_ s: String) -> String {
        fmt(s) == esc(s) ? s : s.replacingOccurrences(of: "**", with: "")
    }
}

public enum Report {
    /// `stepTextFromKey(f, key, snap)` : la SESSION fait foi quand elle porte le texte archivé.
    public static func stepText(_ f: Fiche?, key: String, snapshot: JSON?) -> (block: String, step: String, archived: Bool)? {
        if let a = snapshot?["stepTexts"]?[key], let s = a["s"]?.string, !s.isEmpty {
            let b = a["b"]?.string ?? ""
            return (b.isEmpty ? "Étapes" : b, s, true)
        }
        let p = key.split(separator: ":", omittingEmptySubsequences: false)
        guard p.count == 3, let f, let blk = f.blocks.first(where: { $0.id == String(p[1]) }), let i = Int(p[2]) else { return nil }
        let steps = Graph.stepsOf(f, blk)
        guard i >= 0, i < steps.count, !steps[i].isEmpty else { return nil }
        return (blk.title.isEmpty ? "Étapes" : blk.title, steps[i], false)
    }

    /// `posoName` : texte avant « : », gras retiré.
    public static func posoName(_ s: String) -> String {
        let t = Steps.text(s)
        if let r = t.range(of: " : "), r.lowerBound > t.startIndex { return JS.trim(HTML.stripBold(String(t[..<r.lowerBound]))) }
        return JS.trim(HTML.stripBold(t))
    }
    /// `tagShort` : libellé court d'une étape (avant « :: », coupé à — – ( , ;, trois mots, 26 car.).
    public static func tagShort(_ l: String) -> String {
        var t = l.components(separatedBy: "::")[0]
        if let r = t.range(of: #"\s*[—–(,;]"#, options: .regularExpression) { t = String(t[..<r.lowerBound]) }
        t = JS.trim(t)
        let w = t.split(whereSeparator: { $0.unicodeScalars.allSatisfy(JS.isSpace) })
        if w.count > 3 { t = w.prefix(3).joined(separator: " ") }
        if JS.length(t) > 26 {
            var c = JS.prefix(t, 25)
            while let l = c.unicodeScalars.last, JS.isSpace(l) { c.unicodeScalars.removeLast() }
            return c + "…"
        }
        return t
    }

    /// Objets ad hoc d'une session (pour nommer leurs repères).
    public struct Extras {
        public var timers: [(id: String, label: String)] = []
        public var counters: [(id: String, label: String)] = []
        public init(timers: [(id: String, label: String)] = [], counters: [(id: String, label: String)] = []) {
            self.timers = timers; self.counters = counters
        }
    }

    /// `tagLabel(ref, f, tags, ex)` : une référence résolue en mot ; nil = introuvable.
    public static func tagLabel(_ r: JSON?, _ f: Fiche?, tags: [(k: String, l: String)], extras: Extras = Extras()) -> String? {
        guard let r, let type = r["type"]?.string else { return nil }
        switch type {
        case "counter":
            let id = r["id"]?.string ?? ""
            let label = f?.counters.first { $0.id == id }?.label ?? extras.counters.first { $0.id == id }?.label ?? ""
            let base = label.isEmpty ? "Compteur" : label
            guard let v = r["v"], !v.isNull else { return base }
            let n = JS.number(v)
            return base + " n° " + JSON.formatNumber(n.isNaN ? 0 : n)
        case "timer":
            let id = r["id"]?.string ?? ""
            let l = f?.timers.first { $0.id == id }?.label ?? extras.timers.first { $0.id == id }?.label
            return (l?.isEmpty == false) ? l : nil
        case "step":
            guard let f, let b = f.blocks.first(where: { $0.id == r["b"]?.string }) else { return nil }
            let i = Int(JS.number(r["i"]).isFinite ? JS.number(r["i"]) : -1)
            let st = Graph.stepsOf(f, b)
            guard i >= 0, i < st.count, !st[i].isEmpty else { return nil }
            return tagShort(posoName(st[i]))
        case "poso":
            guard let f else { return nil }
            let d = Pool.list(f, .dose).map(\.legacyString)
            let i = Int(JS.number(r["i"]).isFinite ? JS.number(r["i"]) : -1)
            return i >= 0 && i < d.count ? posoName(d[i]) : nil
        case "core":
            return SessionSanitize.tagCore.first { $0.k == r["k"]?.string }?.l
        case "tag":
            return tags.first { $0.k == r["k"]?.string }?.l
        default: return nil
        }
    }
    /// `tkLabels(events, f, tags, ex)` : « Action N » numérote les seuls repères GÉNÉRIQUES.
    public static func eventLabels(_ events: [SessionEvent], _ f: Fiche?, tags: [(k: String, l: String)], extras: Extras = Extras()) -> [String] {
        var n = 0
        return events.map { e in
            if !e.label.isEmpty { return e.label }
            if let l = tagLabel(e.ref, f, tags: tags, extras: extras) { return l }
            n += 1
            return "Action \(n)"
        }
    }
    /// `evDeltas` : écart brut au geste précédent du MÊME objet (jamais une évaluation).
    public static func deltas(_ evs: [SessionEvent]) -> [Double?] {
        var prev: [String: Double] = [:]
        return evs.map { e in
            guard let t = e.refType, let id = e.refId, !e.isVoid else { return nil }
            let k = t + ":" + id
            let d = prev[k].map { e.t - $0 }
            prev[k] = e.t
            return d
        }
    }

    static let css = """
    body{font-family:system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;color:#101b28;max-width:720px;margin:24px auto;padding:0 18px;line-height:1.5}
    h1{font-family:'Source Serif 4',Georgia,'Times New Roman',serif;font-weight:600;font-size:22px;margin:0 0 2px}h2{font-size:14px;text-transform:uppercase;letter-spacing:.07em;color:#5b6570;margin:22px 0 8px;border-bottom:1px solid #d5dbe2;padding-bottom:4px}
    .meta{color:#5b6570;font-size:13px;margin-bottom:6px}table{width:100%;border-collapse:collapse;font-size:13.5px}td{padding:5px 8px;border-bottom:1px solid #f2f5f8;vertical-align:top}
    td:first-child{white-space:nowrap}ul{margin:0;padding-left:20px;font-size:13.5px}.muted{color:#5b6570}
    td:first-child,td:nth-child(2){font-family:ui-monospace,"SF Mono",Menlo,Consolas,monospace;font-variant-numeric:tabular-nums;font-size:12.5px}
    .foot{margin-top:26px;font-size:11px;color:#5b6570;border-top:1px solid #d5dbe2;padding-top:8px}
    .bilan{display:flex;flex-wrap:wrap;align-items:center;gap:18px;margin:14px 0 4px;padding:14px 16px;background:#eff2f6;border:1px solid #d5dbe2;border-radius:12px}
    .bilan-dur{display:flex;flex-direction:column;gap:2px}
    .bd-v{font-family:ui-monospace,"SF Mono",Menlo,Consolas,monospace;font-variant-numeric:tabular-nums;font-size:40px;font-weight:700;line-height:1;letter-spacing:-1px}
    .bd-k{font-size:11px;letter-spacing:.07em;text-transform:uppercase;color:#5b6570}
    .kpis{display:flex;flex-wrap:wrap;gap:8px;margin-left:auto}
    .kpi{min-width:74px;background:#fff;border:1px solid #d5dbe2;border-radius:10px;padding:8px 12px;text-align:center}
    .kpi-v{display:block;font-family:ui-monospace,"SF Mono",Menlo,Consolas,monospace;font-variant-numeric:tabular-nums;font-size:20px;font-weight:700;line-height:1.1}
    .kpi-k{display:block;font-size:11px;color:#5b6570;margin-top:2px}
    .wm{position:fixed;right:-34px;top:24px;transform:rotate(24deg);font-size:13px;font-weight:800;letter-spacing:3px;color:#17477f;background:#e3ecf7;border:1px dashed #1f5fa6;padding:4px 44px;z-index:2}
    .meta.exo{color:#17477f;font-weight:700}
    @media print{body{margin:0}}
    """

    /// Le document complet (`_reportDoc`) et son nom de fichier.
    public static func document(session s: JSON, fiche f: Fiche?, tags: [(k: String, l: String)], appVersion: String,
                                now: Double = JS.now()) -> (html: String, fileName: String) {
        let title = HTML.esc((f?.title.isEmpty == false ? f!.title : nil) ?? s["ficheTitle"]?.string ?? "Fiche")
        let st = s["startedAt"]?.number ?? 0, sv = s["savedAt"]?.number ?? 0
        let start = st != 0 ? st : sv
        let dur = Fmt.ms(max(0, (sv != 0 ? sv : now) - start))
        let evs = (s["events"]?.array ?? []).map { SessionEvent(json: $0) }.sorted { $0.t < $1.t }
        let dl = deltas(evs)
        let labs = eventLabels(evs, f, tags: tags)
        var evRows = ""
        if evs.isEmpty { evRows = "<tr><td colspan=\"4\" class=\"muted\">Aucun repère horodaté.</td></tr>" }
        for (i, e) in evs.enumerated() {
            let lab = e.isVoid ? "<s>\(HTML.esc(labs[i]))</s> <span class=\"muted\">— annulé\(e.voidAt.map { " à " + HTML.esc(Fmt.hms($0)) } ?? "")</span>" : HTML.esc(labs[i])
            let d = dl[i].map { "+" + HTML.esc(Fmt.ms($0)) } ?? "—"
            evRows += "<tr><td>\(HTML.esc(Fmt.hms(e.t)))</td><td>+\(HTML.esc(Fmt.ms(e.t - start)))</td><td>\(d)</td><td>\(lab)</td></tr>"
        }
        var stepRows = ""
        for (k, v) in orderedChecked(s) where v {
            if let x = stepText(f, key: k, snapshot: s) { stepRows += "<li><span class=\"muted\">\(HTML.esc(x.block)) —</span> \(HTML.fmt(x.step))</li>" }
        }
        if stepRows.isEmpty { stepRows = "<li class=\"muted\">Aucune étape cochée.</li>" }
        let navSeq = (s["navSeq"]?.array ?? []).map { JS.number($0) }, nav = (s["nav"]?.array ?? []).compactMap(\.string)
        var cx: [(Double, String)] = []
        for (sq, v) in s["cxBack"]?.object ?? [:] {
            let id = v.string ?? v["id"]?.string ?? "", t = v["t"]?.number ?? 0
            let ix = navSeq.firstIndex(of: JS.number(.string(sq)))
            let bb = ix.flatMap { $0 < nav.count ? nav[$0] : nil }.flatMap { bid in f?.blocks.first { $0.id == bid } }
            let fromB = f?.blocks.first { $0.id == id }
            let h = "\(t != 0 ? HTML.esc(Fmt.hms(t)) : "—") — ⚡ \(HTML.esc(bb?.title.isEmpty == false ? bb!.title : "Complication"))" +
                (fromB.map { " <span class=\"muted\">(pendant : \(HTML.esc($0.title)))</span>" } ?? "")
            cx.append((t, h))
        }
        cx.sort { $0.0 < $1.0 }
        let nVer = s["verified"]?.object?.count ?? 0
        var gaps: [(Double, String)] = []
        for (k, v) in s["vgaps"]?.object ?? [:] {
            guard let x = stepText(f, key: k, snapshot: s) else { continue }
            let ts = VTrace.norm(v)?.t ?? 0
            gaps.append((ts, "\(ts != 0 ? HTML.esc(Fmt.hms(ts)) : "—") — △ écart : \(HTML.fmt(x.step)) <span class=\"muted\">(\(HTML.esc(x.block)))</span>"))
        }
        gaps.sort { $0.0 < $1.0 }
        let sc = s["counters"]?.object ?? [:], stim = s["timers"]?.object ?? [:]
        func cval(_ id: String) -> String { let n = JS.number(sc[id]); return JSON.formatNumber(n.isNaN || n == 0 ? 0 : n) }
        let counters = (f?.counters ?? []).map { "<tr><td>\(HTML.esc($0.label.isEmpty ? "Compteur" : $0.label))</td><td>\(HTML.esc(cval($0.id)))</td></tr>" }.joined()
        let timers = (f?.timers ?? []).map { t -> String in
            let ts = stim[t.id]
            let el = ts?["elapsedMs"]?.number ?? 0, cy = ts?["cycles"]?.number ?? 0
            let v = t.type == .interval ? HTML.esc(Fmt.ms(el)) + " · " + HTML.esc(JSON.formatNumber(cy)) + " cycle(s)" : HTML.esc(Fmt.ms(el))
            return "<tr><td>\(HTML.esc(t.label.isEmpty ? (t.type == .interval ? "Minuteur" : "Chronomètre") : t.label))</td><td>\(v)</td></tr>"
        }.joined()
        let kpi = (f?.counters ?? []).prefix(4).map { "<div class=\"kpi\"><span class=\"kpi-v\">\(HTML.esc(cval($0.id)))</span><span class=\"kpi-k\">\(HTML.esc($0.label.isEmpty ? "compteur" : $0.label))</span></div>" }.joined()
        let exo = s["exercise"]?.truthy ?? false
        let rv = s["aidRev"]?.number ?? 0
        var inner = "<h1>Compte-rendu de session</h1>\n<div class=\"meta\"><b>\(title)</b>"
        if let va = f?.validatedAt, !va.isEmpty { inner += " · " + HTML.esc("Validation : " + (Validation.display(va).isEmpty ? va : Validation.display(va))) }
        inner += "</div>\n"
        if exo { inner += "<div class=\"wm\">EXERCICE</div><div class=\"meta exo\">▲ Exercice — répétition sans patient, aucune trace clinique</div>\n" }
        inner += "<div class=\"meta\">\(exo ? "Exercice" : "Session") « \(HTML.esc((s["name"]?.string).flatMap { $0.isEmpty ? nil : $0 } ?? "sans nom")) » · début \(HTML.esc(Fmt.localeString(start)))</div>\n"
        inner += "<div class=\"meta\">Révision de l’aide lue pendant le soin : " + (rv != 0 ? "<b>\(HTML.esc(Fmt.localeString(rv)))</b>" : "<i>non enregistrée (session antérieure à la v5)</i>") + "</div>\n"
        inner += "<div class=\"bilan\"><div class=\"bilan-dur\"><span class=\"bd-v\">\(HTML.esc(dur))</span><span class=\"bd-k\">durée totale</span></div>\(kpi.isEmpty ? "" : "<div class=\"kpis\">\(kpi)</div>")</div>\n"
        inner += "<h2>Chronologie des actions</h2><table><thead><tr><td><b>Heure</b></td><td><b>Écoulé</b></td><td><b>Écart</b></td><td><b>Action</b></td></tr></thead><tbody>\(evRows)</tbody></table>\n"
        inner += "<h2>Étapes réalisées</h2><ul>\(stepRows)</ul>\n"
        if !cx.isEmpty { inner += "<h2>⚡ Complications</h2><ul>\(cx.map { "<li>\($0.1)</li>" }.joined())</ul>\n" }
        if nVer > 0 || !gaps.isEmpty {
            inner += "<h2>Vérification (do-verify)</h2><ul><li>\(nVer) étape\(nVer > 1 ? "s" : "") constatée\(nVer > 1 ? "s" : "") ✓✓</li>\(gaps.map { "<li>\($0.1)</li>" }.joined())</ul>\n"
        } else if s["vElsewhere"]?.truthy == true {
            inner += "<h2>Vérification (do-verify)</h2><p class=\"muted\">Une passe de vérification a été faite pendant cette session. Son détail — étapes constatées et écarts — <b>n’est pas synchronisé</b> : il reste sur l’appareil qui l’a produite.</p>\n"
        }
        if !counters.isEmpty { inner += "<h2>Compteurs</h2><table>\(counters)</table>\n" }
        if !timers.isEmpty { inner += "<h2>Minuteurs</h2><table>\(timers)</table>\n" }
        inner += "<div class=\"foot\">Document généré par Aides cognitives (v\(HTML.esc(appVersion))) le \(HTML.esc(Fmt.localeString(now))). Aucune donnée patient. Relire et contextualiser avant archivage.</div>"
        let doc = "<!doctype html><html lang=\"fr\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>Compte-rendu — \(title)</title><style>\(css)</style></head><body>\(inner)</body></html>"
        let name = "compte-rendu-" + Slug.file((f?.title.isEmpty == false ? f!.title : nil) ?? s["ficheTitle"]?.string ?? "")
        return (doc, name)
    }

    /// Clés cochées dans l'ordre du document (Q19 : un document relu a perdu l'ordre d'insertion
    /// JavaScript ; on trie par visite puis par index, l'ordre du soin).
    static func orderedChecked(_ s: JSON) -> [(String, Bool)] {
        let o = s["checked"]?.object ?? [:]
        return o.keys.sorted { a, b in
            let pa = a.split(separator: ":"), pb = b.split(separator: ":")
            let sa = Int(pa.first ?? "") ?? Int.max, sb = Int(pb.first ?? "") ?? Int.max
            if sa != sb { return sa < sb }
            if pa.count > 1, pb.count > 1, pa[1] != pb[1] { return pa[1] < pb[1] }
            return (Int(pa.last ?? "") ?? 0) < (Int(pb.last ?? "") ?? 0)
        }.map { ($0, o[$0]!.truthy) }
    }
}

public enum Slug {
    /// `catSlug` puis borné : accents retirés, [a-z0-9]+ joints par « - », ≤ 40, repli « fiche ».
    public static func file(_ s: String) -> String {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR")).lowercased()
        var parts: [String] = []
        var cur = ""
        for c in folded.unicodeScalars {
            if (c.value >= 97 && c.value <= 122) || (c.value >= 48 && c.value <= 57) { cur.unicodeScalars.append(c) }
            else if !cur.isEmpty { parts.append(cur); cur = "" }
        }
        if !cur.isEmpty { parts.append(cur) }
        let r = String(parts.joined(separator: "-").prefix(40))
        return r.isEmpty ? "fiche" : r
    }
}
