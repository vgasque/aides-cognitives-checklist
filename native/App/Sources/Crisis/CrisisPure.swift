import Foundation
import AidesCore

// FONCTIONS PURES DU MODE CRISE absentes du cœur — portées ici, privées à la zone, nommées comme
// la fonction JS d'origine (`flowPlan`, `autoShort`, `tmShort`, `cnShort`, `cxShort`, `cxAll`,
// `tagAll`, `tagSuggest`, `tkParseTime`, `posBandModel`, `stepQualTxt`, `wtTimerModel`,
// `wtCountModel`, `tmLiveOrder`, `monPick`, `momTag`, `ovPresList`, `cycleHint`, `hasFlow`).
// Elles ne lisent RIEN de global : l'état de session est passé en paramètre (la dépendance se voit).
// À REMONTER dans AidesCore (avec leurs tests d'oracle) quand le lot le permettra.

// MARK: - flowPlan (numérotation commune « le tronc d'abord »)

struct CrPlanItem: Hashable {
    enum Kind: Hashable { case block, bropen, brclose, link, end }
    var k: Kind
    /// Bloc (`block`) ou cible (`link`).
    var id: String = ""
    var depth: Int = 0
    var dec: String = ""
    var oi: Int = 0
    var label: String = ""
    var tgt: String? = nil
    var from: String? = nil
    var back = false
}

struct CrPlan {
    var items: [CrPlanItem] = []
    var order: [String] = []
    var index: [String: Int] = [:]
    /// Numéro commun d'un bloc (`order.indexOf(id) + 1`), nil hors du tronc (cible de complication, revue).
    func number(_ id: String) -> Int? { index[id].map { $0 + 1 } }
}

/// Port fidèle de `flowPlan(f)` (B1 §7). Classe interne : fonctions mutuellement récursives sûres.
private final class CrFlowPlanner {
    let f: Fiche
    let byId: [String: Block]
    let X = "#exit"
    var ids: [String] = []
    var backE = Set<String>()
    var onStack = Set<String>()
    var fini = Set<String>()
    var pdom: [String: Set<String>] = [:]
    var rendered = Set<String>()
    var items: [CrPlanItem] = []
    var order: [String] = []

    init(_ f: Fiche) {
        self.f = f
        byId = Graph.byId(f.blocks)
    }

    func valid(_ t: String?) -> String? { (t != nil && byId[t!] != nil) ? t : nil }

    func succ(_ id: String) -> [String] {
        guard let b = byId[id] else { return [X] }
        if b.kind == .decision {
            let t = b.options.map { o -> String in valid(o.target) ?? X }
            return t.isEmpty ? [X] : t
        }
        return [valid(b.next) ?? X]
    }
    func succD(_ id: String) -> [String] {
        succ(id).map { v in (v != X && backE.contains(id + ">" + v)) ? X : v }
    }
    func dfs(_ u: String) {
        onStack.insert(u)
        for v in succ(u) where v != X {
            if onStack.contains(v) { backE.insert(u + ">" + v) }
            else if !fini.contains(v) { dfs(v) }
        }
        onStack.remove(u); fini.insert(u)
    }
    func joinOf(_ id: String) -> String? {
        let tg = succD(id).filter { $0 != X }
        var cnt: [String: Int] = [:]
        for t in tg { for p in pdom[t] ?? [] where p != X && p != id { cnt[p, default: 0] += 1 } }
        let c = cnt.keys.filter { (cnt[$0] ?? 0) >= 2 }
        if c.isEmpty { return nil }
        let sorted = c.sorted { a, b in
            let pa = pdom[a]?.count ?? 0, pb = pdom[b]?.count ?? 0
            if pa != pb { return pa > pb }
            let ca = cnt[a] ?? 0, cb = cnt[b] ?? 0
            if ca != cb { return ca > cb }
            return (ids.firstIndex(of: a) ?? 0) < (ids.firstIndex(of: b) ?? 0)
        }
        return sorted.first
    }
    func link(_ to: String, _ from: String?, _ depth: Int) {
        items.append(CrPlanItem(k: .link, id: to, depth: depth, from: from))
    }
    func walk(_ id: String, _ stop: String?, _ depth: Int, _ pend: inout [String]) {
        var cur: String? = id
        var prev: String? = nil
        while let c = cur, c != stop, c != X {
            if rendered.contains(c) { link(c, prev, depth); return }
            guard let b = byId[c] else { return }
            rendered.insert(c); order.append(c)
            items.append(CrPlanItem(k: .block, id: c, depth: depth))
            if b.kind == .decision {
                var join = joinOf(c)
                if let j = join, rendered.contains(j) { join = nil }
                for (oi, o) in b.options.enumerated() {
                    let tgt = valid(o.target)
                    items.append(CrPlanItem(k: .bropen, depth: depth + 1, dec: c, oi: oi,
                                            label: o.label.isEmpty ? "Option \(oi + 1)" : o.label, tgt: tgt))
                    if let t = tgt {
                        if t == join || rendered.contains(t) { link(t, c, depth + 1) }
                        else if let j = join, !(pdom[t]?.contains(j) ?? false) { link(t, c, depth + 1); pend.append(t) }
                        else { chain(t, join, depth + 1) }
                    } else {
                        items.append(CrPlanItem(k: .end, depth: depth + 1))
                    }
                    items.append(CrPlanItem(k: .brclose))
                }
                if let j = join, j != stop { prev = c; cur = j; continue }
                return
            }
            guard let nx = valid(b.next) else { items.append(CrPlanItem(k: .end, depth: depth)); return }
            prev = c; cur = nx
        }
        if let c = cur, let s = stop, c == s, s != X { link(s, prev, depth) }
    }
    func chain(_ id: String, _ stop: String?, _ depth: Int) {
        var pend: [String] = []
        walk(id, stop, depth, &pend)
        for t in pend where !rendered.contains(t) { chain(t, stop, depth) }
    }

    func run() -> CrPlan {
        let blocks = f.blocks
        if blocks.isEmpty { return CrPlan() }
        ids = blocks.map(\.id).filter { byId[$0] != nil }
        let start = valid(f.start) ?? blocks[0].id
        dfs(start)
        for id in ids where !fini.contains(id) { dfs(id) }
        pdom[X] = [X]
        let all = Set(ids + [X])
        for id in ids { pdom[id] = all }
        var moved = true
        while moved {
            moved = false
            for id in ids {
                var inter: Set<String>? = nil
                for s in succD(id) {
                    let ps = pdom[s] ?? []
                    inter = inter == nil ? ps : inter!.intersection(ps)
                }
                var i2 = inter ?? []
                i2.insert(id)
                if i2.count != (pdom[id]?.count ?? 0) { pdom[id] = i2; moved = true }
            }
        }
        chain(start, nil, 0)
        let cxT = Set(f.excursions.map(\.target).filter { !$0.isEmpty })
        for b in blocks where byId[b.id] != nil && !rendered.contains(b.id) && !cxT.contains(b.id) && b.kind != .review {
            chain(b.id, nil, 0)
        }
        var idx: [String: Int] = [:]
        for (i, id) in order.enumerated() where idx[id] == nil { idx[id] = i }
        for i in items.indices where items[i].k == .link {
            let it = items[i]
            if let ti = idx[it.id], let fr = it.from, let fi = idx[fr] { items[i].back = ti < fi }
        }
        return CrPlan(items: items, order: order, index: idx)
    }
}

/// Nombre affiché (entier sans décimale), comme `String(n)` en JS pour les compteurs.
func crNum(_ v: Double) -> String {
    if v.isNaN || v.isInfinite { return "0" }
    if v == v.rounded() && abs(v) < 1e15 { return String(Int(v)) }
    return String(v)
}

enum CrisisPure {
    // Cache par CONTENU du graphe (la PWA cache par objet fiche ; une nouvelle fiche = un nouveau plan).
    @MainActor private static var planCache: [String: (blocks: [Block], start: String?, cx: [Excursion], plan: CrPlan)] = [:]

    @MainActor
    static func flowPlan(_ f: Fiche) -> CrPlan {
        if let c = planCache[f.id], c.blocks == f.blocks, c.start == f.start, c.cx == f.excursions { return c.plan }
        let p = CrFlowPlanner(f).run()
        planCache[f.id] = (f.blocks, f.start, f.excursions, p)
        return p
    }

    /// `hasFlow` : plus d'un bloc, ou une décision.
    static func hasFlow(_ f: Fiche) -> Bool { f.blocks.count > 1 || f.blocks.contains { $0.kind == .decision } }

    // MARK: Complications

    struct Cx: Hashable {
        var label: String
        var target: String
        var short: String
        var isBlock: Bool
    }
    /// `cxAll(f)` : déclarations valides, résolues par nature.
    static func cxAll(_ f: Fiche) -> [Cx] {
        let ids = Set(f.blocks.map(\.id).filter { !$0.isEmpty })
        return f.excursions.filter { !$0.label.isEmpty && !$0.target.isEmpty }
            .map { Cx(label: $0.label, target: $0.target, short: $0.short ?? "", isBlock: ids.contains($0.target)) }
    }

    // MARK: Noms courts (audit UX N4)

    static let shortStop: Set<String> = ["après", "avant", "de", "du", "des", "la", "le", "les", "en", "pour", "sur", "avec", "et", "au", "aux", "à", "par", "d", "l"]
    static func shortCut(_ w: String) -> String {
        let V = "aeiouyàâäéèêëîïôöùûü"
        let a = Array(w)
        var i = 4
        while i < a.count - 2, V.contains(Character(String(a[i]).lowercased())) { i += 1 }
        return String(a.prefix(i + 1)) + "."
    }
    private static func squash(_ s: String) -> String {
        s.split(whereSeparator: { $0.unicodeScalars.allSatisfy(JS.isSpace) }).joined(separator: " ")
    }
    /// `autoShort(name, max)` : un minuteur se DISTINGUE par son dernier mot — on abrège d'abord les premiers.
    static func autoShort(_ name: String, _ max: Int) -> String {
        let full = squash(name)
        var s = full
        if s.hasSuffix(")"), let open = s.lastIndex(of: "("), !s[s.index(after: open)...].dropLast().contains("(") {
            let head = JS.trim(String(s[..<open]))
            s = head.isEmpty ? full : head
        }
        if s.count <= max { return s }
        let words: [String] = s.split(separator: " ").map { String($0) }
        var ws: [String] = []
        for (i, x) in words.enumerated() {
            if i == 0 { ws.append(x); continue }
            var l = x.lowercased()
            if l.count >= 2, l.hasPrefix("l'") || l.hasPrefix("l’") || l.hasPrefix("d'") || l.hasPrefix("d’") { l = String(l.prefix(1)) }
            if !shortStop.contains(l) { ws.append(x) }
        }
        s = ws.joined(separator: " ")
        if s.count <= max { return s }
        if ws.count > 1 {
            for i in 0..<(ws.count - 1) where ws[i].count > 6 {
                ws[i] = shortCut(ws[i]); s = ws.joined(separator: " ")
                if s.count <= max { return s }
            }
        }
        let L = ws.count - 1
        if L >= 0, ws[L].count > 6 {
            ws[L] = shortCut(ws[L]); s = ws.joined(separator: " ")
            if s.count <= max { return s }
        }
        while ws.count > 2 && ws.joined(separator: " ").count > max { ws.remove(at: 1) }
        return ws.joined(separator: " ")
    }
    /// `autoShortHead` : une complication se NOMME par son premier mot — on retire les derniers.
    static func autoShortHead(_ name: String, _ max: Int) -> String {
        var ws = squash(name).split(separator: " ").map(String.init)
        while ws.count > 1 && ws.joined(separator: " ").count > max { ws.removeLast() }
        return ws.joined(separator: " ")
    }
    static func tmShort(_ t: TimerState) -> String { t.short.isEmpty ? autoShort(t.label.isEmpty ? t.name : t.label, 14) : t.short }
    static func cnShort(_ c: CounterDef) -> String { (c.short?.isEmpty == false) ? c.short! : autoShort(c.label, 10) }
    /// `cxKeyLabel` : « Titre (précision) » → « Titre ».
    static func cxKeyLabel(_ s: String) -> String {
        let t = JS.trim(s)
        if t.hasSuffix(")"), let open = t.lastIndex(of: "(") {
            let inner = t[t.index(after: open)..<t.index(before: t.endIndex)]
            if !inner.contains("(") && !inner.contains(")") {
                let head = JS.trim(String(t[..<open]))
                if !head.isEmpty { return head }
            }
        }
        return t
    }
    static func cxShort(_ c: Cx) -> String { c.short.isEmpty ? autoShortHead(cxKeyLabel(HTML.stripBold(c.label)), 20) : c.short }

    // MARK: Journal des actions

    /// `tkParseTime(str)` : « 1547 », « 15:47 », « 15h47 », « 154730 » → (h, m, s) ; jamais de bornage.
    static func tkParseTime(_ str: String) -> (h: Int, m: Int, s: Int)? {
        let t = JS.trim(str)
        if t.isEmpty { return nil }
        let isDigit: (Character) -> Bool = { $0.isASCII && $0.isNumber }
        var h = 0, m = 0, s = 0
        if t.contains(where: { !isDigit($0) }) {
            let g = t.split(whereSeparator: { !isDigit($0) }).map(String.init).filter { !$0.isEmpty }
            if g.isEmpty || g.count > 3 || g.contains(where: { $0.count > 2 }) { return nil }
            h = Int(g[0]) ?? -1
            if g.count > 1 { m = Int(g[1]) ?? -1 }
            if g.count > 2 { s = Int(g[2]) ?? -1 }
        } else {
            if t.count > 6 { return nil }
            let a = Array(t)
            if a.count <= 2 { h = Int(t) ?? -1 }
            else if a.count <= 4 { h = Int(String(a.dropLast(2))) ?? -1; m = Int(String(a.suffix(2))) ?? -1 }
            else { h = Int(String(a.dropLast(4))) ?? -1; m = Int(String(a.dropLast(2).suffix(2))) ?? -1; s = Int(String(a.suffix(2))) ?? -1 }
        }
        guard h >= 0, h <= 23, m >= 0, m <= 59, s >= 0, s <= 59 else { return nil }
        return (h, m, s)
    }
    /// L'heure corrigée garde la DATE calendaire d'origine (Q13, comportement web).
    static func correctedTime(_ orig: Double, _ hms: (h: Int, m: Int, s: Int)) -> Double {
        let cal = Calendar.current
        let d = Date(timeIntervalSince1970: orig / 1000)
        var c = cal.dateComponents([.year, .month, .day], from: d)
        c.hour = hms.h; c.minute = hms.m; c.second = hms.s
        guard let nd = cal.date(from: c) else { return orig }
        return (nd.timeIntervalSince1970 * 1000).rounded(.down)
    }

    struct TagCand {
        var ref: JSON
        var label: String
        var type: String
        var alias: [String] = []
    }
    /// `tagAll(f, tags, ex)` : le vocabulaire disponible ici — aucun filtrage.
    static func tagAll(_ f: Fiche, tags: [(k: String, l: String)], R: RuntimeSession?) -> [TagCand] {
        var out: [TagCand] = []
        var vus = Set<String>()
        func add(_ ref: JSON, _ key: String, _ label: String) {
            let l = JS.trim(JS.prefix(label, 80))
            if l.isEmpty { return }
            let cle = (ref["type"]?.string ?? "") + ":" + key
            if vus.contains(cle) { return }
            vus.insert(cle)
            out.append(TagCand(ref: ref, label: l, type: ref["type"]?.string ?? ""))
        }
        var timers: [(id: String, label: String, interval: Bool, adhoc: Bool)] = f.timers.map { ($0.id, $0.label, $0.type == .interval, false) }
        if let R { timers += R.orderedTimers.filter(\.adhoc).map { ($0.id, $0.label, $0.type == .interval, true) } }
        for (i, t) in timers.enumerated() {
            let l = JS.trim(t.label)
            add(["type": "timer", "id": .string(t.id)], t.id, l.isEmpty ? ((t.interval ? "Minuteur" : "Chronomètre") + (t.adhoc ? " \(i + 1)" : "")) : l)
        }
        var counters: [(id: String, label: String, adhoc: Bool)] = f.counters.map { ($0.id, $0.label, false) }
        if let R { counters += R.adhocCounters.map { ($0.id, $0.label, true) } }
        for (i, c) in counters.enumerated() {
            let l = JS.trim(c.label)
            add(["type": "counter", "id": .string(c.id)], c.id, l.isEmpty ? ("Compteur" + (c.adhoc ? " \(i + 1)" : "")) : l)
        }
        for b in f.blocks {
            for (i, st) in Graph.cleanSteps(f, b).enumerated() {
                add(["type": "step", "b": .string(b.id), "i": .number(Double(i))], b.id + "/\(i)", Report.posoName(st))
            }
        }
        let doses = Pool.list(f, .dose).map { JS.trim($0.legacyString) }.filter { !$0.isEmpty }
        for (i, pp) in doses.enumerated() { add(["type": "poso", "i": .number(Double(i))], "\(i)", Report.posoName(pp)) }
        for c in SessionSanitize.tagCore { add(["type": "core", "k": .string(c.k)], c.k, c.l) }
        for t in tags { add(["type": "tag", "k": .string(t.k)], t.k, t.l) }
        return out
    }
    /// `tagSuggest(f, tags, bid, n, garantis)` : RÉORDONNE, ne filtre jamais ; `garantis` réserve la tête.
    static func tagSuggest(_ all: [TagCand], blockId: String?, n: Int, guaranteed: [String]) -> [TagCand] {
        func rang(_ t: TagCand) -> Int {
            switch t.type {
            case "step": return (blockId != nil && t.ref["b"]?.string == blockId) ? 0 : 2
            case "timer", "counter": return 1
            case "poso": return 3
            case "tag": return 4
            default: return 5
            }
        }
        let mx = max(1, n)
        let est: (TagCand) -> Bool = { guaranteed.contains($0.type) }
        let tete = Array(all.filter(est).prefix(mx))
        let reste = all.enumerated().filter { !est($0.element) }
            .sorted { a, b in rang(a.element) != rang(b.element) ? rang(a.element) < rang(b.element) : a.offset < b.offset }
            .map { $0.element }
        return Array((tete + reste).prefix(mx))
    }
    static func fold(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR")).lowercased()
    }
    /// Rapprochement pendant la frappe (≥ 2 caractères, ≤ 4 propositions de score > 0).
    /// SIMPLIFICATION de `tagRank`/`posoScore` : préfixe, puis début de mot, puis inclusion ; sans table de synonymes.
    static func tagMatch(_ all: [TagCand], query: String, max: Int = 4) -> [TagCand] {
        let q = fold(JS.trim(query))
        guard q.count >= 2 else { return [] }
        func score(_ t: TagCand) -> Int {
            let l = fold(t.label)
            if l.hasPrefix(q) { return 3 }
            if l.split(separator: " ").contains(where: { $0.hasPrefix(q) }) { return 2 }
            return l.contains(q) ? 1 : 0
        }
        return all.enumerated().map { ($0.offset, $0.element, score($0.element)) }.filter { $0.2 > 0 }
            .sorted { $0.2 != $1.2 ? $0.2 > $1.2 : $0.0 < $1.0 }.prefix(max).map { $0.1 }
    }

    // MARK: Repères posologiques

    /// `posoParts` : nom avant « : », corps après.
    static func posoParts(_ s: String) -> (name: String, body: String) {
        let t = Steps.text(s)
        if let r = t.range(of: " : "), r.lowerBound > t.startIndex {
            return (JS.trim(HTML.stripBold(String(t[..<r.lowerBound]))), JS.trim(String(t[r.upperBound...])))
        }
        return (JS.trim(HTML.stripBold(t)), "")
    }

    struct PosoRow: Hashable {
        var id: String
        var name: String
        var body: String
        var note: String
        var stt: String   // « fait » · « à faire » · « à préparer »
    }
    /// `posBandModel(f, b, seq, checked, moOf)` (A397/A398) — l'état vient des SEULES coches.
    static func posBandModel(_ f: Fiche, _ b: Block, seq: Int, isChecked: (String) -> Bool, moOf: (Item, Int) -> Moment?) -> [PosoRow] {
        let its = Pool.blockItems(f, b)
        var byDose: [String: Item] = [:]
        for d in Pool.roleItems(f, .dose) { byDose[d.id] = d }
        var out: [PosoRow] = []
        var seen = Set<String>()
        var next = true
        for (i, it) in its.enumerated() {
            let d = it.poso.flatMap { byDose[$0] }
            let on = isChecked("\(seq):\(b.id):\(i)")
            let mo = on ? nil : moOf(it, i)
            let wait = mo?.st == .wait, gone = mo?.st == .gone
            let req = !on && !wait && !gone && it.review == nil && (mo == nil || mo!.req)
            guard let d, !seen.contains(d.id) else { if req { next = false }; continue }
            seen.insert(d.id)
            let p = posoParts(d.legacyString)
            out.append(PosoRow(id: d.id, name: p.name, body: p.body, note: JS.trim(d.note),
                               stt: (on || gone) ? "fait" : ((wait || !next) ? "à préparer" : "à faire")))
            if req { next = false }
        }
        return out
    }
    /// Classement des repères pour le bloc courant (`posoRank`, SIMPLIFIÉ : signalés d'abord, puis
    /// mots communs avec le texte du bloc, puis ordre de l'auteur — réordonne, ne filtre jamais).
    static func posoRank(_ items: [String], hay: String) -> [(s: String, flagged: Bool, score: Int)] {
        let hw = Set(fold(hay).split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init).filter { $0.count >= 4 })
        return items.enumerated().map { (i, s) -> (Int, String, Bool, Int) in
            let nm = fold(Report.posoName(s)).split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init).filter { $0.count >= 4 }
            var sc = 0
            for (j, w) in nm.enumerated() where hw.contains(where: { $0.hasPrefix(w) || w.hasPrefix($0) }) { sc += 3 + (j == 0 ? 1 : 0) }
            return (i, s, Steps.isCrit(s) || Steps.isVigil(s), sc)
        }.sorted { a, b in
            if a.2 != b.2 { return a.2 }
            if a.3 != b.3 { return a.3 > b.3 }
            return a.0 < b.0
        }.map { ($0.1, $0.2, $0.3) }
    }

    // MARK: Qualificatif d'étape en mots (`stepQualTxt`)

    static func timerDef(_ f: Fiche, _ id: String) -> TimerDef? { id.isEmpty ? nil : f.timers.first { $0.id == id } }
    static func durParen(_ t: TimerDef) -> String { (t.type == .interval && t.seconds > 0) ? " (" + Fmt.dur(t.seconds) + ")" : "" }
    static func stepQualTxt(_ f: Fiche, _ it: Item, faite: Bool = false) -> String {
        let t = timerDef(f, Moments.timerId(f, it))
        var q: [String] = []
        if it.repeat == .once { q.append(faite ? "✓ faite — plus à refaire" : "si pas déjà faite") }
        else if it.repeat == .need { q.append("au besoin") }
        else if it.repeat == .due, let t {
            q.append((t.type == .interval && t.seconds > 0) ? "toutes les " + Fmt.dur(t.seconds)
                     : "quand « " + Fmt.timerName(label: t.label, type: t.type) + " » ne tourne pas")
        }
        if let cid = it.counts, let C = f.counters.first(where: { $0.id == cid }) {
            let r = (!C.timerId.isEmpty && it.repeat != .due) ? timerDef(f, C.timerId) : nil
            let nm = Fmt.labelParts(C.label).name
            q.append("+\(max(1, C.step)) " + (nm.isEmpty ? "Compteur" : nm)
                     + (r.map { " · relance « " + Fmt.timerName(label: $0.label, type: $0.type) + " »" + durParen($0) } ?? ""))
        } else if let s = it.starts, it.repeat != .due, let x = timerDef(f, s) {
            q.append("lance « " + Fmt.timerName(label: x.label, type: x.type) + " »" + durParen(x))
        }
        return q.joined(separator: " · ")
    }
    /// `blkTimerTxt(f, b)`.
    static func blockTimerTxt(_ f: Fiche, _ b: Block) -> String? {
        guard let tid = b.timer, let t = timerDef(f, tid) else { return nil }
        return "lance « " + Fmt.timerName(label: t.label, type: t.type) + " »" + durParen(t) + " à chaque entrée"
    }
    /// `cycleHint(f)` : le seul minuteur cyclique (s'il est unique).
    static func cycleHint(_ f: Fiche) -> TimerDef? {
        let c = f.timers.filter { $0.type == .interval && $0.autoloop && $0.seconds > 0 }
        return c.count == 1 ? c[0] : nil
    }
    /// `onceFaite` : « une seule fois » déjà cochée dans cette session.
    static func onceFaite(_ R: RuntimeSession, _ it: Item?, _ bid: String, _ i: Int) -> Bool {
        guard it?.repeat == .once, R.started else { return false }
        let suf = ":\(bid):\(i)"
        return R.checkedKeys.contains { $0.hasSuffix(suf) }
    }

    // MARK: Moments — étiquette (`momTag`)

    enum TagTone { case outline, warn, ok, neutral }
    static func momFromLbl(_ f: Fiche, _ it: Item) -> String {
        guard let fr = it.from else { return "" }
        let c = f.counters.first { $0.id == fr.counter }
        let nm = Fmt.labelParts(c?.label ?? "").name
        return (nm.isEmpty ? "Compteur" : nm) + " ≥ \(fr.n)"
    }
    static func momTag(_ f: Fiche, _ it: Item, _ mo: Moment) -> (tone: TagTone, word: String) {
        switch mo.st {
        case .wait: return mo.why == .from ? (.outline, momFromLbl(f, it)) : (.outline, "À l’échéance")
        case .met: return (.ok, "✓ " + momFromLbl(f, it))
        case .due: return (.warn, "Échu")
        case .gone: return (.ok, "Faite")
        case .need: return (.neutral, "Au besoin")
        }
    }

    // MARK: Témoins des liens (A377)

    struct Witness {
        var value: String
        var text: String
        var due = false
        var running = false
        var ring: Double? = nil      // fraction restante (minuteur à échéance)
        var glyph = "timer"          // SF Symbol
    }
    static func ago(_ t: Double, _ now: Double) -> String { now - t < 10_000 ? "à l’instant" : "il y a " + Fmt.ms(now - t) }

    /// `wtTimerModel` : le témoin d'un minuteur lancé par une coche (`key`) ou par l'entrée du bloc (`key == nil`).
    static func wtTimerModel(_ R: RuntimeSession, _ tid: String, key: String?, now: Double) -> Witness? {
        guard let t = R.timers[tid] else { return nil }
        let name = t.name
        let interval = t.type == .interval
        let ring: Double? = interval && t.period > 0 ? max(0, min(1, t.remaining(now) / t.period)) : nil
        if t.isDue {
            let a = JS.trim(t.onDue)
            return Witness(value: "Échu", text: "· " + (a.isEmpty ? name : a), due: true, ring: 0, glyph: interval ? "timer" : "stopwatch")
        }
        if t.running {
            var hint: String? = nil
            if let k = key {
                let on = R.isChecked(k)
                let armedByMe = R.linkArm[tid]?.ck == k
                if on && armedByMe && now - t.lastStart < SessionEngine.linkGraceMs && t.elapsedMs == 0 {
                    hint = "décocher annule · \(Int(((SessionEngine.linkGraceMs - (now - t.lastStart)) / 1000).rounded(.up))) s"
                } else if !on && armedByMe {
                    hint = "décochée, le minuteur continue"
                } else if !on {
                    hint = "la coche relance" + (interval ? " à " + Fmt.ms(t.period) : "")
                }
            }
            return Witness(value: interval ? t.display(now) : "↑ " + Fmt.ms(t.within(now)), text: "· " + (hint ?? name),
                           running: true, ring: ring, glyph: interval ? "timer" : "stopwatch")
        }
        if t.started {
            let exited = (R.linkArm[tid]?.x ?? 0) != 0
            return Witness(value: t.display(now), text: "· " + name + " · " + (exited ? "arrêté, sortie de la boucle" : "arrêté"),
                           ring: ring, glyph: interval ? "timer" : "stopwatch")
        }
        return Witness(value: interval ? Fmt.ms(t.period) : "↑", text: (key == nil ? "à chaque entrée" : "à la coche") + " · " + name,
                       ring: interval ? 1 : nil, glyph: interval ? "timer" : "stopwatch")
    }
    /// `wtCountModel` : le témoin d'une coche qui COMPTE.
    static func wtCountModel(_ R: RuntimeSession, _ cid: String, key: String, now: Double) -> Witness? {
        guard let c = R.fiche.counters.first(where: { $0.id == cid }) else { return nil }
        let step = Double(max(1, c.step))
        let cur = R.counters[cid] ?? 0
        let nm = Fmt.labelParts(c.label).name
        let name = nm.isEmpty ? "Compteur" : nm
        let evs = R.events.filter { $0.refType == "counter" && $0.refId == cid && !$0.isVoid }
        func n(_ v: Double) -> String { crNum(v) }
        if R.isChecked(key) {
            if let ev = evs.last(where: { $0.ck == key }) {
                let v = ev.ref?["v"]?.number ?? cur
                return Witness(value: n(v - step) + " → " + n(v), text: "· " + name + " · " + ago(ev.t, now), glyph: "number")
            }
            return Witness(value: n(cur), text: "· " + name, glyph: "number")
        }
        let last = evs.last
        return Witness(value: n(cur) + " → " + n(cur + step), text: "à la coche · " + name + (last.map { " · dernier " + ago($0.t, now) } ?? ""), glyph: "number")
    }

    // MARK: Minuteurs

    /// `tmLiveOrder(list, now)` : échus non acquittés d'abord, puis par temps restant, puis ordre de l'auteur.
    static func tmLiveOrder(_ list: [TimerState], now: Double) -> [TimerState] {
        func rk(_ t: TimerState) -> Double {
            if t.isDueDock && !t.ack { return -1 }
            if t.type == .interval && t.running { return max(0, t.period - (t.elapsedMs + (now - t.lastStart))) }
            return .infinity
        }
        return list.enumerated().map { ($0.offset, $0.element, rk($0.element)) }
            .sorted { $0.2 != $1.2 ? $0.2 < $1.2 : $0.0 < $1.0 }.map { $0.1 }
    }
    /// « Bientôt échu » : minuteur à échéance en marche, 0 < restant ≤ 20 s.
    static func isSoon(_ t: TimerState, _ now: Double) -> Bool {
        guard t.type == .interval, t.running else { return false }
        let r = t.remaining(now)
        return r > 0 && r <= SessionEngine.soonMs
    }
    /// `monPick(timers, now)` : un échu gagne, sinon le minuteur en marche le plus proche de sa fin.
    static func monPick(_ timers: [TimerState], now: Double) -> TimerState? {
        let arr = timers.filter { $0.type == .interval }
        if arr.isEmpty { return nil }
        if let d = arr.first(where: \.isDue) { return d }
        let actifs = arr.filter(\.running)
        let pool = actifs.isEmpty ? arr : actifs
        return pool.min { $0.remaining(now) < $1.remaining(now) }
    }

    // MARK: Présentation du journal (`ovPresList`)

    enum Pres { case open, line, chip }
    static func ovPresList(complete: [Bool], manual: [Bool?], forcedOpen: Int?) -> [Pres] {
        let n = complete.count
        return (0..<n).map { i in
            if i == n - 1 || i == forcedOpen { return .open }
            if manual[i] == false { return .open }
            if !complete[i] { return manual[i] == true ? .line : .open }
            return .chip
        }
    }
    /// `ovFoldRemap(avant, après)` : les replis suivent leur VISITE quand le chemin est réordonné.
    static func ovFoldRemap(_ fold: [String: Bool], before: [Int], after: [Int]) -> [String: Bool] {
        if before == after { return fold }
        var pos: [Int: Int] = [:]
        for (i, s) in after.enumerated() { pos[s] = i }
        var n: [String: Bool] = [:]
        for (k, v) in fold {
            let isRun = k.hasPrefix("r:")
            let digits = isRun ? String(k.dropFirst(2)) : k
            guard let ix = Int(digits), digits.allSatisfy(\.isNumber) else { n[k] = v; continue }
            guard ix < before.count, let j = pos[before[ix]] else { continue }
            n[(isRun ? "r:" : "") + String(j)] = v
        }
        return n
    }
    /// `ovDropOpens()` : tout geste de navigation rend les dépliages manuels à la condensation automatique.
    static func ovDropOpens(_ fold: [String: Bool]) -> [String: Bool] {
        fold.filter { k, v in !(v == false && (k.hasPrefix("r:") || (!k.isEmpty && k.allSatisfy { $0.isNumber }))) }
    }
    /// Somme « d/t étapes » sur la DERNIÈRE visite de chaque bloc numéroté (`minimapData`).
    static func progress(_ R: RuntimeSession, _ plan: CrPlan) -> (done: Int, tot: Int) {
        var d = 0, t = 0
        let by = Graph.byId(R.fiche.blocks)
        for id in plan.order {
            guard let b = by[id], b.kind != .decision else { continue }
            let steps = Graph.cleanSteps(R.fiche, b)
            t += steps.count
            if let lp = Graph.latestPass(nav: R.nav, navSeq: R.navSeq, id) {
                for i in steps.indices where R.isChecked("\(lp.seq):\(id):\(i)") { d += 1 }
            }
        }
        return (d, t)
    }
}
