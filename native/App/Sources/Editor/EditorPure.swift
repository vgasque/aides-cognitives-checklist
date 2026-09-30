import Foundation
import AidesCore

// FONCTIONS PURES DE L'ÉDITEUR — ports des fonctions JS de `index.html` qui ne sont pas (encore)
// dans le cœur AidesCore. Chacune porte le nom de la fonction d'origine dans son commentaire :
// au moindre doute, relire la source (la PWA reste la vérité).
// Aucune ne touche à l'interface ni au stockage : elles prennent une aide (ou une référence) et
// rendent une valeur, ce qui les rend testables et relisibles ligne à ligne contre le web.

enum EdKit {

    // MARK: Chaînes

    /// `BOLD_RX = /\*\*([^*\n]+)\*\*/g` — motif compilé une fois.
    private static let boldRx = try! NSRegularExpression(pattern: "\\*\\*([^*\\n]+)\\*\\*")
    /// `stripBold(s)` : retire les marqueurs `**…**`.
    static func stripBold(_ s: String) -> String {
        let ns = s as NSString
        return boldRx.stringByReplacingMatches(in: s, range: NSRange(location: 0, length: ns.length), withTemplate: "$1")
    }
    /// `clean(a)` : chaînes coupées aux blancs, vides retirées.
    static func clean(_ a: [String]) -> [String] { a.map { JS.trim($0) }.filter { !$0.isEmpty } }

    /// `fmtBytes(n)` : « 812 o », « 34 Ko », « 2,4 Mo », « 1,25 Go ».
    static func fmtBytes(_ n: Int) -> String {
        if n < 1024 { return "\(n) o" }
        if n < 1_048_576 { return "\(Int(JS.round(Double(n) / 1024))) Ko" }
        if n < 1_073_741_824 { return String(format: "%.1f", Double(n) / 1_048_576).replacingOccurrences(of: ".", with: ",") + " Mo" }
        return String(format: "%.2f", Double(n) / 1_073_741_824).replacingOccurrences(of: ".", with: ",") + " Go"
    }

    /// Recherche insensible aux accents et à la casse (`txNorm`).
    static func norm(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
    }
    /// `byTitle` : collation française, numérique.
    static func titleLess(_ a: String, _ b: String) -> Bool {
        a.compare(b, options: [.caseInsensitive, .numeric, .diacriticInsensitive], range: nil, locale: Locale(identifier: "fr_FR")) == .orderedAscending
    }

    // MARK: Pool et vues « liste » (A §4.4-4.6)

    /// Les cinq listes v3, VUES sur le pool (`listOf`, `setList`, `V4_ROLE_OF`).
    enum ListKey: String, CaseIterable {
        case confirmation, notForget, verify, posology, differentials
        var role: Role {
            switch self {
            case .confirmation: return .entry
            case .notForget: return .do
            case .verify: return .watch
            case .posology: return .dose
            case .differentials: return .ddx
            }
        }
    }

    /// `listOf(f, key)` : chaînes (`v4ItemToStr`) de la tranche du pool.
    static func listOf(_ f: Fiche, _ key: ListKey) -> [String] {
        listItems(f, key).map(\.legacyString)
    }
    static func listItems(_ f: Fiche, _ key: ListKey) -> [Item] {
        key == .notForget ? Pool.roleItems(f, .do).filter(\.memory) : Pool.roleItems(f, key.role)
    }

    /// `setList(f, key, arr)` : réécrit la tranche EN PLACE, en conservant les identités par position.
    static func setList(_ f: inout Fiche, _ key: ListKey, _ arr: [String]) {
        let role = key.role, mem = key == .notForget
        let anciens = listItems(f, key)
        var neufs: [Item] = []
        for (i, str) in arr.enumerated() {
            if i < anciens.count {
                var a = anciens[i]
                let cr = Steps.challengeResponse(Steps.text(str))
                a.do = cr.c; a.expect = cr.r ?? ""; a.level = Steps.level(str); a.memory = mem
                neufs.append(a)
            } else {
                neufs.append(Steps.makeItem(id: Guard.uid("i"), role: role, raw: str, memory: mem))
            }
        }
        let pris = Set(anciens.map(\.id))
        var k = 0, dernier = -1
        var out: [Item] = []
        for it in f.items {
            if !pris.contains(it.id) { out.append(it); continue }
            if k < neufs.count { out.append(neufs[k]); k += 1; dernier = out.count }
        }
        let reste = Array(neufs[k...])
        if !reste.isEmpty {
            if dernier < 0 { dernier = out.count }
            out.insert(contentsOf: reste, at: dernier)
        }
        f.items = out
    }

    /// `forgetAll(f)` : les chaînes du chapeau, dans l'ordre du pool.
    static func forgetAll(_ f: Fiche) -> [String] { Pool.forget(f).map { $0.item.legacyString } }

    /// `newStepItem(str)`.
    static func newStepItem(_ raw: String = "") -> Item { Steps.makeItem(id: Guard.uid("i"), role: .do, raw: raw) }

    /// `setStepStr(b, i, str)` par identité : le « :: » ne change la réponse que s'il est présent.
    static func setStepStr(_ f: inout Fiche, itemId: String, _ str: String) {
        guard let k = f.items.firstIndex(where: { $0.id == itemId }) else { return }
        let cr = Steps.challengeResponse(Steps.text(str))
        f.items[k].do = cr.c
        if let r = cr.r { f.items[k].expect = r }
        f.items[k].level = Steps.level(str)
    }

    /// `bItemAdd(b, i, item)` : dans le pool ET dans le bloc (les deux côtés, toujours).
    static func bItemAdd(_ f: inout Fiche, blockId: String, at i: Int, _ item: Item) {
        guard let bi = f.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        f.items.append(item)
        let n = f.blocks[bi].items.count
        f.blocks[bi].items.insert(item.id, at: max(0, min(i, n)))
    }
    /// `bItemDel(b, i)` : la référence ET l'item du pool.
    static func bItemDel(_ f: inout Fiche, blockId: String, itemId: String) {
        guard let bi = f.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        guard let pos = f.blocks[bi].items.firstIndex(of: itemId) else { return }
        f.blocks[bi].items.remove(at: pos)
        f.items.removeAll { $0.id == itemId }
    }
    /// `bItemMove(src, i, dst, j)` : l'item ne bouge PAS dans le pool, seule sa référence change de bloc.
    static func bItemMove(_ f: inout Fiche, from src: String, itemId: String, to dst: String, at j: Int) {
        guard let si = f.blocks.firstIndex(where: { $0.id == src }),
              let pos = f.blocks[si].items.firstIndex(of: itemId) else { return }
        f.blocks[si].items.remove(at: pos)
        guard let di = f.blocks.firstIndex(where: { $0.id == dst }) else { return }
        let n = f.blocks[di].items.count
        f.blocks[di].items.insert(itemId, at: max(0, min(j, n)))
    }

    // MARK: Raccourcis à la frappe (K10)

    /// `stepShortcut(val)` : « ! » + espace → critique (3), « ? » + espace → vigilance (2), en tête seulement.
    static func stepShortcut(_ val: String) -> (level: Int, rest: String)? {
        let u = Array(val.unicodeScalars)
        guard u.count >= 2, u[0] == "!" || u[0] == "?", JS.isSpace(u[1]) else { return nil }
        let rest = String(String.UnicodeScalarView(u[2...]))
        return (u[0] == "!" ? 3 : 2, rest)
    }

    // MARK: Relecture (§11) — jamais bloquante, jamais rouge

    /// Nombre de séparateurs « · » / « + » entourés de blancs (`/\s[·+]\s/g`).
    private static let sepRx = try! NSRegularExpression(pattern: "\\s[·+]\\s")
    static func sepCount(_ s: String) -> Int {
        sepRx.numberOfMatches(in: s, range: NSRange(location: 0, length: (s as NSString).length))
    }

    /// `nfGuardTxt(arr)`.
    static func nfGuardTxt(_ arr: [String]) -> String {
        let c = clean(arr)
        var parts: [String] = []
        if c.count > 4 {
            parts.append("\(c.count) rappels — au-delà de 4, plus rien n’est saillant. Un rappel lié à une étape précise est plus sûr en étape ⚠ du bloc concerné, une surveillance dans « À vérifier »")
        }
        let lg = c.filter { JS.length(stripBold($0)) > 110 }.count
        if lg > 0 {
            parts.append("\(lg) rappel" + either(lg > 1, "s", "") + " très long" + either(lg > 1, "s", "") + " — style télégraphique : au-delà de 110 caractères, le chapeau pousse la première action sous le bas de l’écran")
        }
        return parts.isEmpty ? "" : "△ " + parts.joined(separator: " · ")
    }

    /// `stepGuardTxt(steps, scope)` : `bloc` = la seule remarque de bloc (éditeur).
    static func stepGuardTxt(_ steps: [String], bloc: Bool) -> String {
        let s = clean(steps)
        var parts: [String] = []
        if s.count > 7 { parts.append("\(s.count) étapes — au-delà de 7, scinder le bloc (lisibilité sous stress)") }
        if bloc { return parts.isEmpty ? "" : "△ " + parts.joined(separator: " · ") }
        let long = s.filter { JS.length(Steps.challengeResponse(Steps.text($0)).c) > 110 }.count
        if long > 0 {
            parts.append("\(long) challenge" + either(long > 1, "s", "") + " très long" + either(long > 1, "s", "") + " — style télégraphique : une action courte, la valeur en réponse « challenge :: réponse »")
        }
        let cumul = s.filter { sepCount(Steps.challengeResponse(Steps.text($0)).c) >= 2 }.count
        if cumul > 0 {
            parts.append("\(cumul) étape" + either(cumul > 1, "s", "") + " cumulant plusieurs actions — une action cochable = une ligne (sinon on coche « à moitié fait »)")
        }
        return parts.isEmpty ? "" : "△ " + parts.joined(separator: " · ")
    }

    /// `stepNote(st)` : remarque sous la ligne qu'elle vise.
    static func stepNote(_ st: String) -> String {
        let c = Steps.challengeResponse(Steps.text(st)).c
        if JS.trim(c).isEmpty { return "" }
        if sepCount(c) >= 2 { return "Plusieurs actions dans une étape cochable — une action = une ligne, sinon on coche « à moitié fait »" }
        if JS.length(c) > 110 { return "Challenge très long (\(JS.length(c)) c.) — style télégraphique : l’action courte, la valeur en réponse « :: »" }
        return ""
    }

    struct RevNote: Identifiable, Equatable {
        var at: String
        var cible: String
        var txt: String
        var id: String { at + "|" + txt }
    }

    /// `reviewNotes(f)`.
    static func reviewNotes(_ f: Fiche) -> [RevNote] {
        var out: [RevNote] = []
        let t = nfGuardTxt(forgetAll(f))
        if !t.isEmpty { out.append(RevNote(at: "nf", cible: "Ne pas oublier", txt: t)) }
        for b in f.blocks where b.kind != .decision {
            let g = stepGuardTxt(Graph.stepsOf(f, b), bloc: false)
            if !g.isEmpty {
                let ti = JS.trim(b.title)
                out.append(RevNote(at: "b:" + b.id, cible: ti.isEmpty ? "Bloc d’étapes" : ti, txt: g))
            }
        }
        return out
    }

    /// `TODO_RX = /[àa] compl[eé]ter/i`.
    private static let todoRx = try! NSRegularExpression(pattern: "[àa] compl[eé]ter", options: [.caseInsensitive])
    static func hasTodo(_ s: String) -> Bool {
        todoRx.firstMatch(in: s, range: NSRange(location: 0, length: (s as NSString).length)) != nil
    }

    /// `reviewNotesProto(p)`.
    static func reviewNotesProto(_ p: Reference) -> [RevNote] {
        var out: [RevNote] = []
        let corps = JS.trim(p.body)
        if corps.isEmpty && p.docs.isEmpty {
            out.append(RevNote(at: "p-body", cible: "Contenu", txt: "△ Cette référence est vide — ni texte rédigé, ni document joint : elle ne servira à rien telle quelle"))
        }
        if hasTodo(corps) { out.append(RevNote(at: "p-body", cible: "Contenu rédigé", txt: "△ Un « à compléter » reste dans le texte")) }
        if hasTodo(p.sources.joined(separator: " ")) {
            out.append(RevNote(at: "p-sources", cible: "Références", txt: "△ Un « à compléter » reste dans les sources"))
        }
        if !corps.isEmpty && clean(p.sources).isEmpty {
            out.append(RevNote(at: "p-sources", cible: "Références", txt: "△ Aucune source citée — la traçabilité d’une référence est ce qui permet de la revalider"))
        }
        if JS.trim(p.title).isEmpty { out.append(RevNote(at: "p-title", cible: "Titre", txt: "△ Sans titre, rien n’entre dans la bibliothèque")) }
        return out
    }

    // MARK: Propositions de la relecture (Q1)

    enum OfferKind: Equatable { case interval(Int), counter, memory(String) }
    struct Offer: Identifiable, Equatable {
        var id: String
        var kind: OfferKind
        var cible: String
        var btn: String
        var txt: String
    }
    private static let q1Cycle = try! NSRegularExpression(pattern: "\\btoutes?\\s+les\\s+(\\d{1,3})\\s*(?:min\\b|minutes\\b)", options: [.caseInsensitive])
    private static let q1Delai = try! NSRegularExpression(pattern: "(?:^|[^\\wàâäéèêëîïôöùûüç])(?:à|apr[èe]s)\\s+(\\d{1,3})\\s*(?:min\\b|minutes\\b)", options: [.caseInsensitive])
    private static let q1QH = try! NSRegularExpression(pattern: "\\bq(\\d{1,2})\\s*h\\b", options: [.caseInsensitive])
    private static let q1Renouv = try! NSRegularExpression(pattern: "\\b(?:renouvel|r[ée]p[ée]t|nouvelle\\s+dose|seconde\\s+dose|2e?\\s+dose|nouveau\\s+choc)", options: [.caseInsensitive])

    private static func firstNumber(_ rx: NSRegularExpression, _ s: String) -> Int? {
        let ns = s as NSString
        guard let m = rx.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)), m.numberOfRanges > 1 else { return nil }
        let r = m.range(at: 1)
        guard r.location != NSNotFound else { return nil }
        return Int(ns.substring(with: r))
    }

    /// `q1Texts(f)` : étapes, questions, et les cinq listes.
    static func q1Texts(_ f: Fiche) -> [String] {
        var out: [String] = []
        for b in f.blocks {
            for s in Graph.stepsOf(f, b) { out.append(Steps.text(s)) }
            if !b.question.isEmpty { out.append(b.question) }
        }
        for k in [ListKey.confirmation, .notForget, .verify, .posology, .differentials] { out.append(contentsOf: listOf(f, k)) }
        return out
    }

    /// `reviewOffers(f)` : ce que le texte suggère — jamais créé d'office, le NOMBRE vient de la phrase.
    static func reviewOffers(_ f: Fiche, dismissed: Set<String>) -> [Offer] {
        var out: [Offer] = []
        let txts = q1Texts(f)
        if !f.timers.contains(where: { $0.type == .interval }) {
            var sec = 0, src = ""
            for t in txts {
                if let n = firstNumber(q1Cycle, t) ?? firstNumber(q1Delai, t) { sec = n * 60; src = t; break }
                if let n = firstNumber(q1QH, t) { sec = n * 3600; src = t; break }
            }
            if sec > 0 && sec <= 86400 {
                out.append(Offer(id: "tm", kind: .interval(sec), cible: "Minuteur", btn: "＋ Minuteur " + Fmt.ms(Double(sec) * 1000),
                                 txt: "« " + JS.prefix(src, 64) + " » — un minuteur à cycles s’armerait au premier geste et sonnerait seul."))
            }
        }
        if f.counters.isEmpty && txts.contains(where: { q1Renouv.firstMatch(in: $0, range: NSRange(location: 0, length: ($0 as NSString).length)) != nil }) {
            out.append(Offer(id: "cn", kind: .counter, cible: "Compteur", btn: "＋ Compteur",
                             txt: "Votre texte parle de renouveler un geste — un compteur en horodate chaque unité dans le compte rendu. Il naîtra sans nom : c’est à vous de le nommer."))
        }
        let its = f.blocks.flatMap { Pool.blockItems(f, $0) }
        if !its.contains(where: \.memory) {
            if let c = its.first(where: { !JS.trim($0.do).isEmpty && ($0.level == 3 || Steps.isCrit($0.do)) }) {
                out.append(Offer(id: "mem:" + c.id, kind: .memory(c.id), cible: "Ne pas oublier", btn: "★ Marquer",
                                 txt: "« " + JS.prefix(c.do, 64) + " » est une étape vitale — ★ la ferait aussi paraître dans « Ne pas oublier », sans quitter son bloc."))
            }
        }
        return out.filter { !dismissed.contains($0.id) }
    }

    // MARK: Noms courts (`autoShort`, `cxShort`)

    static let shortStop: Set<String> = ["après", "avant", "de", "du", "des", "la", "le", "les", "en", "pour", "sur", "avec", "et", "au", "aux", "à", "par", "d", "l"]
    static let shortTM = 14, shortCN = 10, shortCX = 20

    /// Espaces successifs réduits à un, puis `trim` (`replace(/\s+/g,' ').trim()`).
    static func collapse(_ s: String) -> String {
        var out = "", sp = false
        for c in s.unicodeScalars {
            if JS.isSpace(c) { sp = true; continue }
            if sp && !out.isEmpty { out += " " }
            sp = false
            out.unicodeScalars.append(c)
        }
        return out
    }
    /// `shortCut(w)`.
    static func shortCut(_ w: String) -> String {
        let v = "aeiouyàâäéèêëîïôöùûü"
        let ch = Array(w)
        var i = 4
        while i < ch.count - 2, v.contains(String(ch[i]).lowercased()) { i += 1 }
        return String(ch.prefix(i + 1)) + "."
    }
    /// Retire un groupe final « ( … ) » (`/\s*\([^()]*\)\s*$/`).
    static func dropTrailingParen(_ s: String) -> String {
        var t = s
        while let l = t.unicodeScalars.last, JS.isSpace(l) { t.unicodeScalars.removeLast() }
        guard t.hasSuffix(")"), let open = t.lastIndex(of: "(") else { return s }
        let inner = t[t.index(after: open)..<t.index(before: t.endIndex)]
        if inner.contains("(") || inner.contains(")") { return s }
        return String(t[..<open])
    }
    /// `autoShort(name, max)`.
    static func autoShort(_ name: String, _ max: Int) -> String {
        let full = collapse(name)
        var s = JS.trim(dropTrailingParen(full))
        if s.isEmpty { s = full }
        if JS.length(s) <= max { return s }
        var ws: [String] = []
        for (i, x) in s.components(separatedBy: " ").enumerated() {
            var low = x.lowercased()
            if let f = low.first, (f == "l" || f == "d"), low.count >= 2 {
                let second = low[low.index(after: low.startIndex)]
                if second == "'" || second == "’" { low = String(f) }
            }
            if i == 0 || !shortStop.contains(low) { ws.append(x) }
        }
        s = ws.joined(separator: " ")
        if JS.length(s) <= max { return s }
        if ws.count > 1 {
            for i in 0..<(ws.count - 1) where ws[i].count > 6 {
                ws[i] = shortCut(ws[i]); s = ws.joined(separator: " ")
                if JS.length(s) <= max { return s }
            }
        }
        let L = ws.count - 1
        if L >= 0, ws[L].count > 6 {
            ws[L] = shortCut(ws[L]); s = ws.joined(separator: " ")
            if JS.length(s) <= max { return s }
        }
        while ws.count > 2 && JS.length(ws.joined(separator: " ")) > max { ws.remove(at: 1) }
        return ws.joined(separator: " ")
    }
    /// `autoShortHead(name, max)`.
    static func autoShortHead(_ name: String, _ max: Int) -> String {
        var ws = collapse(name).components(separatedBy: " ")
        while ws.count > 1 && JS.length(ws.joined(separator: " ")) > max { ws.removeLast() }
        return ws.joined(separator: " ")
    }
    /// `cxKeyLabel(s)` : « Événement (précision) » → « Événement ».
    static func cxKeyLabel(_ s: String) -> String {
        let t = JS.trim(s)
        let head = JS.trim(dropTrailingParen(t))
        return (head.isEmpty || head == t) ? t : head
    }
    /// `cxShort(c)`.
    static func cxShort(_ label: String) -> String { autoShortHead(cxKeyLabel(stripBold(label)), shortCX) }

    // MARK: Mots des pastilles (`edStepSum`, `momFromLbl`, `posoParts`)

    /// `posoParts(x)` : nom (avant « : ») · corps · signalé.
    static func posoParts(_ x: String) -> (name: String, body: String, flag: Bool) {
        let t = Steps.text(x)
        if let r = t.range(of: " : "), r.lowerBound > t.startIndex {
            return (JS.trim(stripBold(String(t[..<r.lowerBound]))), String(t[r.upperBound...]), Steps.isCrit(x) || Steps.isVigil(x))
        }
        return ("", t, Steps.isCrit(x) || Steps.isVigil(x))
    }
    /// Nom d'un compteur (`tmLabelParts(c.label).name || 'Compteur'`).
    static func counterName(_ c: CounterDef?) -> String {
        let n = Fmt.labelParts(c?.label ?? "").name
        return n.isEmpty ? "Compteur" : n
    }
    static func timerName(_ t: TimerDef) -> String { Fmt.timerName(label: t.label, type: t.type) }
    /// `tmOptLbl(t)` : « ⏱ Nom · 02:00 ».
    static func timerOptionLabel(_ t: TimerDef) -> String {
        "⏱ " + timerName(t) + (t.type == .interval ? " · " + Fmt.ms(Double(t.seconds) * 1000) : "")
    }
    /// `momFromLbl(f, it)` : « Chocs ≥ 3 ».
    static func momFromLbl(_ f: Fiche, _ fr: ItemFrom) -> String {
        counterName(f.counters.first { $0.id == fr.counter }) + " ≥ \(fr.n)"
    }
    /// `MOM_WORD`.
    static func momWord(_ r: Repeat) -> String {
        switch r { case .due: return "à l’échéance"; case .once: return "une seule fois"; case .need: return "au besoin" }
    }
    /// `stepSetOn(s, it)` : un réglage est posé.
    static func stepSetOn(_ it: Item) -> Bool {
        it.level >= 2 || it.memory || it.dual || it.starts != nil || it.counts != nil || it.from != nil || it.repeat != nil || it.review != nil || it.poso != nil
    }

    enum PillKind { case crit, vig, mem, x2, lk, mo, ko }
    struct Pill: Identifiable, Equatable {
        var id: String
        var text: String
        var kind: PillKind
        /// Symbole SF (les icônes de la PWA — `warn`, `grid`, `pill`).
        var icon: String?
    }
    /// `edStepSum(f, it, s)` : ce qui est réglé, une pastille par réglage, dans l'ordre de la feuille.
    static func stepPills(_ f: Fiche, _ it: Item) -> [Pill] {
        var out: [Pill] = []
        let T = it.starts.flatMap { s in f.timers.first { $0.id == s } }
        let C = it.counts.flatMap { c in f.counters.first { $0.id == c } }
        let dueKo = it.repeat == .due && Moments.timerId(f, it).isEmpty
        if it.level == 3 { out.append(Pill(id: "crit", text: "Critique", kind: .crit, icon: "exclamationmark.triangle.fill")) }
        else if it.level == 2 { out.append(Pill(id: "vig", text: "△ Vigilance", kind: .vig, icon: nil)) }
        if it.memory { out.append(Pill(id: "mem", text: "★ Mémoire", kind: .mem, icon: nil)) }
        if it.dual { out.append(Pill(id: "x2", text: "Double contrôle", kind: .x2, icon: nil)) }
        if let T { out.append(Pill(id: "lk", text: "⏱ lance " + timerName(T), kind: .lk, icon: nil)) }
        else if let C { out.append(Pill(id: "lk", text: "+\(max(1, C.step)) " + counterName(C), kind: .lk, icon: nil)) }
        if let fr = it.from { out.append(Pill(id: "from", text: momFromLbl(f, fr), kind: .mo, icon: nil)) }
        if let r = it.repeat {
            out.append(Pill(id: "rep", text: dueKo ? "△ à l’échéance — aucun minuteur" : momWord(r), kind: dueKo ? .ko : .mo, icon: nil))
        }
        if it.review != nil { out.append(Pill(id: "rev", text: "revue", kind: .lk, icon: "square.grid.2x2")) }
        if let q = it.poso, let d = Pool.roleItems(f, .dose).first(where: { $0.id == q }) {
            let n = posoParts(d.legacyString).name
            out.append(Pill(id: "poso", text: n.isEmpty ? "repère" : n, kind: .lk, icon: "pills"))
        }
        return out
    }

    // MARK: Phase (`phaseInherited`, `phaseCounts`, `phaseFieldHtml`)

    static func phaseInherited(_ f: Fiche, _ bid: String) -> String {
        guard let i = f.blocks.firstIndex(where: { $0.id == bid }), i > 0 else { return "" }
        return Pool.phase(f, f.blocks[i - 1].id)
    }
    static func phaseCounts(_ f: Fiche) -> [String: Int] {
        var c: [String: Int] = [:]
        for b in f.blocks {
            let p = Pool.phase(f, b.id)
            if !p.isEmpty { c[p, default: 0] += 1 }
        }
        return c
    }
    /// Les valeurs proposées : le socle, puis les phases employées, puis la valeur courante si libre.
    static func phaseOptions(_ f: Fiche, _ b: Block) -> [String] {
        let cnt = phaseCounts(f), cur = JS.trim(b.phase)
        var vals = Pool.phaseCore
        let used = f.blocks.map { Pool.phase(f, $0.id) }.filter { !$0.isEmpty }
        for p in used where !Pool.phaseCore.contains(p) { vals.append(p) }
        if !cur.isEmpty && !Pool.phaseCore.contains(cur) && cnt[cur] == nil { vals.append(cur) }
        var seen = Set<String>(), out: [String] = []
        for v in vals where !seen.contains(v) { seen.insert(v); out.append(v) }
        return out
    }

    // MARK: Blocs

    /// Libellé d'un bloc comme cible (`targetSelect`) : « Bloc sans titre (n) ».
    static func targetLabel(_ f: Fiche, _ b: Block) -> String {
        let t = JS.trim(b.title)
        if !t.isEmpty { return t }
        let i = (f.blocks.firstIndex(where: { $0.id == b.id }) ?? 0) + 1
        return "Bloc sans titre (\(i))"
    }
    /// Numéro d'un bloc d'étapes parmi les blocs non-revue (1-based).
    static func blockNumber(_ f: Fiche, _ id: String) -> Int {
        (f.blocks.filter { $0.kind != .review }.firstIndex(where: { $0.id == id }) ?? 0) + 1
    }

    // MARK: Normalisation avant écriture (`edSnapshot`, A §15.3)

    /// Copie NORMALISÉE prête à publier — le brouillon vivant garde ses lignes vides.
    /// Écart assumé (A-spec Q15) : le « Nom court » des minuteurs et compteurs est CONSERVÉ
    /// (la PWA le perdait au commit, défaut signalé ; les complications le gardaient déjà).
    static func snapshot(_ src: Fiche) -> Fiche {
        var d = src
        d.validatedAt = Validation.parse(.string(d.validatedAt))
        d.title = JS.trim(d.title)
        if !(d.order > 0) { d.order = JS.now() }
        d.docs = d.docs.compactMap { Sanitize.attachment($0.json) }
        for k in ListKey.allCases { setList(&d, k, clean(listOf(d, k))) }
        d.sources = clean(d.sources)
        for bi in d.blocks.indices {
            d.blocks[bi].title = JS.trim(d.blocks[bi].title)
            if d.blocks[bi].kind != .decision {
                let garde = Pool.blockItems(d, d.blocks[bi]).filter { !JS.trim($0.legacyString).isEmpty }.map(\.id)
                let gs = Set(garde)
                let jetes = d.blocks[bi].items.filter { !gs.contains($0) }
                d.blocks[bi].items = garde
                if !jetes.isEmpty { let j = Set(jetes); d.items.removeAll { j.contains($0.id) } }
                if d.blocks[bi].items.isEmpty {
                    let it = newStepItem()
                    d.items.append(it)
                    d.blocks[bi].items = [it.id]
                }
                d.blocks[bi].nextLbl = JS.trim(d.blocks[bi].nextLbl)
            } else {
                d.blocks[bi].question = JS.trim(d.blocks[bi].question)
                d.blocks[bi].options = d.blocks[bi].options.filter { !JS.trim($0.label).isEmpty }
            }
        }
        d.timers = d.timers.map { t in
            var x = t
            x.label = JS.trim(t.label); x.seconds = max(0, t.seconds); x.onDue = JS.trim(t.onDue)
            let s = JS.trim(t.short ?? ""); x.short = s.isEmpty ? nil : JS.prefix(s, 24)
            return x
        }
        let tmIds = Set(d.timers.map(\.id))
        d.counters = d.counters.map { c in
            var x = c
            x.label = JS.trim(c.label); x.step = max(1, c.step)
            x.timerId = tmIds.contains(c.timerId) ? c.timerId : ""
            let s = JS.trim(c.short ?? ""); x.short = s.isEmpty ? nil : JS.prefix(s, 24)
            return x
        }
        d.excursions = d.excursions.filter { !JS.trim($0.label).isEmpty && !$0.target.isEmpty }
        let cnIds = Set(d.counters.map(\.id))
        for bi in d.blocks.indices { if let t = d.blocks[bi].timer, !tmIds.contains(t) { d.blocks[bi].timer = nil } }
        var rv: [String: Block] = [:]
        for b in d.blocks where b.kind == .review { rv[b.id] = b }
        let dose = Set(Pool.roleItems(d, .dose).map(\.id))
        for i in d.items.indices {
            if let s = d.items[i].starts, !tmIds.contains(s) { d.items[i].starts = nil }
            if let c = d.items[i].counts, !cnIds.contains(c) { d.items[i].counts = nil }
            if let r = d.items[i].review {
                if let rb = rv[r] { d.items[i].do = JS.trim(rb.title); d.items[i].expect = "" } else { d.items[i].review = nil }
            }
            if let q = d.items[i].poso, !dose.contains(q) { d.items[i].poso = nil }
        }
        if d.start == nil || !d.blocks.contains(where: { $0.id == d.start }) { d.start = d.blocks.first?.id }
        return d
    }

    /// `edSnapshot('p')` : titre, ordre, documents, date de validation, corps borné à 20 000.
    static func snapshot(_ src: Reference) -> Reference {
        var d = src
        d.validatedAt = Validation.parse(.string(d.validatedAt))
        d.title = JS.trim(d.title)
        if !(d.order > 0) { d.order = JS.now() }
        d.docs = d.docs.compactMap { Sanitize.attachment($0.json) }
        d.body = JS.prefix(d.body, Sanitize.mdMaxChars)
        return d
    }

    // MARK: Entités neuves

    /// `blankFiche()` : un bloc « Prise en charge » à une étape vide, contexte local à compléter.
    static func blankFiche(id: String, library: String?) -> Fiche {
        let it = newStepItem()
        let bid = Guard.uid("b")
        let raw: JSON = .object([
            "id": .string(id), "title": "", "code": "", "category": "", "validatedAt": "",
            "local": "Tél renfort : à compléter\nTél régulation : à compléter",
            "excursions": .array([]), "sources": .array([""]), "images": .array([]), "docs": .array([]),
            "timers": .array([]), "counters": .array([]),
            "items": .array([it.json]),
            "blocks": .array([.object(["id": .string(bid), "kind": "do", "title": "Prise en charge",
                                       "items": .array([.string(it.id)]), "image": .null, "next": .null])]),
            "start": .string(bid), "order": .number(JS.now()),
            "library": library.map { .string($0) } ?? .null,
        ])
        return Sanitize.fiche(raw)
    }
    /// `blankProtocol()`.
    static func blankReference(id: String, library: String?) -> Reference {
        let raw: JSON = .object([
            "id": .string(id), "title": "", "code": "", "category": "", "validatedAt": "", "body": "",
            "images": .array([]), "docs": .array([]), "links": .array([]), "sources": .array([]),
            "order": .number(JS.now()), "status": "", "updatedBy": "", "updatedAt": .number(JS.now()),
            "deletedAt": .null, "ownerId": .null, "library": library.map { .string($0) } ?? .null,
        ])
        return Sanitize.reference(raw)
    }
    /// `newTimerObj(sec, lbl)` : 2 min par défaut, sans reprise seule (A379).
    static func newTimer(seconds: Int? = nil, label: String = "") -> TimerDef {
        let s = seconds ?? 0
        return TimerDef(id: Guard.uid("t"), label: label, type: .interval, seconds: (s > 0 && s <= 86400) ? s : 120, autoloop: false)
    }
    /// `newCounterObj(lbl)`.
    static func newCounter(label: String = "") -> CounterDef { CounterDef(id: Guard.uid("n"), label: label, step: 1, start: 0) }
    /// Nouveau bloc d'étapes (porte « ＋ »).
    static func newDoBlock(_ f: inout Fiche, title: String = "") -> String {
        let it = newStepItem()
        f.items.append(it)
        let b = Block(id: Guard.uid("b"), kind: .do, title: title, items: [it.id])
        f.blocks.append(b)
        return b.id
    }

    /// `edSyncGallery(f)` : toute image de bloc absente de la galerie y est ajoutée (idempotent).
    static func syncGallery(_ f: inout Fiche) {
        for b in f.blocks {
            guard let data = b.image, !data.isEmpty else { continue }
            if f.images.contains(where: { $0.data == data }) { continue }
            f.images.append(ImageRef(id: Guard.uid("i"), data: data, w: b.imageW, h: b.imageH, caption: "", scale: 100))
        }
    }

    // MARK: Versions (`flattenFiche`, `diffFicheLines`)

    static func flattenFiche(_ f: Fiche) -> [String] {
        var L: [String] = []
        func add(_ sec: String, _ v: String) { let t = JS.trim(v); if !t.isEmpty { L.append(sec + " · " + t) } }
        add("Titre", f.title); add("Validation", f.validatedAt); add("Contexte", f.local)
        add("État", f.status == .draft ? "brouillon" : "validée")
        let lists: [(ListKey, String)] = [(.confirmation, "Confirmation"), (.verify, "À vérifier"), (.notForget, "Ne pas oublier"),
                                          (.differentials, "Différentiels"), (.posology, "Posologie")]
        for (k, l) in lists { for v in listOf(f, k) { add(l, v) } }
        for v in f.sources { add("Références", v) }
        for b in f.blocks {
            let t = b.title.isEmpty ? (b.kind == .decision ? "Décision" : "Étapes") : b.title
            if b.kind == .decision {
                add("Bloc « " + t + " »", b.question)
                for o in b.options { add("Bloc « " + t + " » — option", o.label) }
            } else {
                for s in Graph.stepsOf(f, b) { add("Bloc « " + t + " »", s) }
            }
        }
        for t in f.timers { add("Minuteur", t.label + either(t.type == .interval, " (\(t.seconds) s)", " (chrono)")) }
        for c in f.counters { add("Compteur", c.label) }
        return L
    }
    static func diffLines(cur: Fiche, old: Fiche) -> (added: [String], removed: [String]) {
        let a = flattenFiche(cur), b = flattenFiche(old)
        let sa = Set(a), sb = Set(b)
        return (b.filter { !sa.contains($0) }, a.filter { !sb.contains($0) })
    }

    // MARK: Liens et documents joignables

    struct RelCandidate: Identifiable, Equatable {
        var id: String
        var title: String
        var isReference: Bool
        var code: String
    }
    /// `relCandidatesFor(entity, fs, ps)` : même périmètre, ni soi ni déjà lié ; aides puis références.
    static func relCandidates(selfId: String, links: [String], library: String?, fiches: [Fiche], references: [Reference]) -> [RelCandidate] {
        let have = Set([selfId] + links)
        let fs = fiches.filter { $0.deletedAt == nil && !have.contains($0.id) && $0.library == library }
            .sorted { titleLess($0.title, $1.title) }
            .map { RelCandidate(id: $0.id, title: $0.title.isEmpty ? "Sans titre" : $0.title, isReference: false, code: $0.code) }
        let ps = references.filter { $0.deletedAt == nil && !have.contains($0.id) && $0.library == library }
            .sorted { titleLess($0.title, $1.title) }
            .map { RelCandidate(id: $0.id, title: $0.title.isEmpty ? "Sans titre" : $0.title, isReference: true, code: $0.code) }
        return fs + ps
    }

    struct AttCandidate: Identifiable, Equatable {
        var id: String
        var name: String
        var size: Int
        var from: String
    }
    /// `attachablePdfs(f)` : documents des AUTRES entités du même périmètre, pas encore joints, dédoublonnés.
    static func attachablePdfs(selfId: String, docs: [Attachment], library: String?, fiches: [Fiche], references: [Reference]) -> [AttCandidate] {
        let have = Set(docs.map(\.id))
        var seen = Set<String>(), out: [AttCandidate] = []
        func take(_ id: String, _ title: String, _ lib: String?, _ del: Double?, _ ds: [Attachment]) {
            if id == selfId || del != nil || lib != library { return }
            for a in ds where !have.contains(a.id) && !seen.contains(a.id) {
                seen.insert(a.id)
                out.append(AttCandidate(id: a.id, name: a.name, size: a.size, from: title.isEmpty ? "Sans titre" : title))
            }
        }
        for f in fiches { take(f.id, f.title, f.library, f.deletedAt, f.docs) }
        for p in references { take(p.id, p.title, p.library, p.deletedAt, p.docs) }
        return out
    }

    // MARK: Mini-Markdown : insertions au curseur (`mdWrapSel`, `mdPrefixLines`, `mdCalloutLines`,
    // `mdInsertAt`, `wrapBold`). Travaillent en unités UTF-16 (NSRange), exactement comme les
    // indices de `selectionStart` du web.

    struct TextEdit { var text: String; var sel: NSRange }

    private static func bounds(_ v: NSString, _ sel: NSRange) -> (Int, Int) {
        let a = max(0, min(sel.location, v.length)), b = max(a, min(sel.location + sel.length, v.length))
        return (a, b)
    }
    /// `wrapBold(inp)` : entoure la sélection de `**`, ou retire ceux qui l'entourent déjà.
    static func wrapBold(_ text: String, _ sel: NSRange) -> TextEdit {
        let v = text as NSString
        let (a, b) = bounds(v, sel)
        let s = v.substring(with: NSRange(location: a, length: b - a))
        let before = a >= 2 ? v.substring(with: NSRange(location: a - 2, length: 2)) : ""
        let after = b + 2 <= v.length ? v.substring(with: NSRange(location: b, length: 2)) : ""
        if !s.isEmpty && before == "**" && after == "**" {
            let nv = v.substring(to: a - 2) + s + v.substring(from: b + 2)
            return TextEdit(text: nv, sel: NSRange(location: a - 2, length: b - a))
        }
        let sn = s as NSString
        if sn.length >= 5 && s.hasPrefix("**") && s.hasSuffix("**") {
            let inner = sn.substring(with: NSRange(location: 2, length: sn.length - 4))
            let nv = v.substring(to: a) + inner + v.substring(from: b)
            return TextEdit(text: nv, sel: NSRange(location: a, length: b - a - 4))
        }
        let nv = v.substring(to: a) + "**" + s + "**" + v.substring(from: b)
        return TextEdit(text: nv, sel: NSRange(location: a + 2, length: b - a))
    }
    /// `mdWrapSel(inp, mark)`.
    static func mdWrap(_ text: String, _ sel: NSRange, _ mark: String) -> TextEdit {
        let v = text as NSString
        let (a, b) = bounds(v, sel)
        let m = (mark as NSString).length
        let nv = v.substring(to: a) + mark + v.substring(with: NSRange(location: a, length: b - a)) + mark + v.substring(from: b)
        return TextEdit(text: nv, sel: NSRange(location: a + m, length: b - a))
    }
    /// Début de la ligne contenant `a`, fin de celle contenant `b`.
    private static func lineSpan(_ v: NSString, _ a: Int, _ b: Int) -> (Int, Int) {
        var ls = 0
        if a > 0 {
            let r = v.range(of: "\n", options: .backwards, range: NSRange(location: 0, length: a))
            ls = r.location == NSNotFound ? 0 : r.location + 1
        }
        let r2 = v.range(of: "\n", options: [], range: NSRange(location: b, length: v.length - b))
        let end = r2.location == NSNotFound ? v.length : r2.location
        return (ls, end)
    }
    private static func rx(_ p: String) -> NSRegularExpression { try! NSRegularExpression(pattern: p) }
    private static let headRx = rx("^#{1,3}\\s+")
    private static let quoteRx = rx("^>\\s?")
    private static let calloutRx = rx("^\\[!\\s*[A-Za-zÀ-ÿ]{2,12}\\s*\\]\\s*")
    private static let listMarkRx = rx("^\\s*(?:[-*]|\\d{1,3}[.)])\\s+")
    /// `MD_TASK_RX` : marqueur de tâche « [ ] » / « [x] ».
    private static let taskRx = rx("^\\[[ xX]\\]\\s+")
    private static func strip(_ rx: NSRegularExpression, _ s: String) -> String {
        rx.stringByReplacingMatches(in: s, range: NSRange(location: 0, length: (s as NSString).length), withTemplate: "")
    }
    /// `mdSplice(inp, v, from, to, seg)` : curseur EN FIN de segment.
    private static func splice(_ v: NSString, _ from: Int, _ to: Int, _ seg: String) -> TextEdit {
        let nv = v.substring(to: from) + seg + v.substring(from: to)
        let c = from + (seg as NSString).length
        return TextEdit(text: nv, sel: NSRange(location: c, length: 0))
    }
    /// `mdPrefixLines(inp, prefix, numbered)` : un titre sur un titre REMPLACE son niveau ; idem citation, tâche.
    static func mdPrefixLines(_ text: String, _ sel: NSRange, prefix: String, numbered: Bool = false) -> TextEdit {
        let v = text as NSString
        let (a, b) = bounds(v, sel)
        let (ls, end) = lineSpan(v, a, b)
        let head = prefix.hasPrefix("#"), quo = prefix.hasPrefix(">"), tsk = prefix.hasPrefix("- [")
        let lines = v.substring(with: NSRange(location: ls, length: end - ls)).components(separatedBy: "\n")
        var out: [String] = []
        for (i, l) in lines.enumerated() {
            var c = l
            if head { c = strip(headRx, l) }
            else if quo { c = strip(calloutRx, strip(quoteRx, l)) }
            else if tsk { c = strip(taskRx, strip(listMarkRx, l)) }
            out.append((numbered ? "\(i + 1). " : prefix) + c)
        }
        return splice(v, ls, end, out.joined(separator: "\n"))
    }
    /// `mdCalloutLines(inp, word)` : forme canonique GitHub, marqueur seul sur sa ligne.
    static func mdCallout(_ text: String, _ sel: NSRange, word: String) -> TextEdit {
        let v = text as NSString
        let (a, b) = bounds(v, sel)
        let (ls, end) = lineSpan(v, a, b)
        let raw = v.substring(with: NSRange(location: ls, length: end - ls)).components(separatedBy: "\n")
            .map { strip(calloutRx, strip(quoteRx, $0)) }
        let kept = raw.count == 1 ? raw : raw.filter { !JS.trim($0).isEmpty }
        let body = kept.map { "> " + $0 }.joined(separator: "\n")
        let seg = "> [!" + word + "]\n" + (body.isEmpty ? "> " : body)
        return splice(v, ls, end, seg)
    }
    /// `mdInsertAt(inp, text)`.
    static func mdInsert(_ text: String, _ sel: NSRange, _ ins: String) -> TextEdit {
        let v = text as NSString
        let (a, _) = bounds(v, sel)
        return splice(v, a, a, ins)
    }
    /// Le caractère avant le curseur est-il un début de ligne ? (« précédé d'un saut si besoin »)
    static func atLineStart(_ text: String, _ sel: NSRange) -> Bool {
        let v = text as NSString
        let a = max(0, min(sel.location, v.length))
        return a == 0 || v.substring(with: NSRange(location: a - 1, length: 1)) == "\n"
    }

    /// Lignes image `![légende](img:ID)` (`MD_IMG_RX`), hors blocs de code : ids référencés par le corps.
    private static let imgLineRx = rx("^!\\[([^\\]]{0,300})\\]\\(img:([A-Za-z0-9_-]{1,64})\\)\\s*$")
    static func referencedImageIds(_ body: String) -> Set<String> {
        var out = Set<String>()
        var inCode = false
        for line in body.components(separatedBy: "\n") {
            if JS.trim(line).hasPrefix("```") { inCode.toggle(); continue }
            if inCode { continue }
            let ns = line as NSString
            if let m = imgLineRx.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)) {
                out.insert(ns.substring(with: m.range(at: 2)))
            }
        }
        return out
    }
}
