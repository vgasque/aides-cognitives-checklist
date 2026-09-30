import Foundation
import AidesCore

// RECHERCHE DE L'ACCUEIL — port PRIVÉ (module de l'app) des fonctions pures de la PWA :
// `txNorm`, `qTerms`, `hayMatch`, `ficheHaystack`, `protocolHaystack`, `searchSnippet`,
// `ficheSnipParts`, `protoSnipParts`, `azLetter`, `azGroups`, `qaPick`, `byTitle`, `dlev`,
// `libVocab`, `spellFix`, `staleDate`, `fmtDate`, `fmtDateShort`, `completionSpots`.
//
// ⚠ PROVISOIRE PAR CONSTRUCTION : le cœur (AidesCore, `Pure/Search.swift`) reçoit une version
// CANONIQUE vérifiée contre la PWA (oracle), en unités UTF-16. Les noms ci-dessous sont les MÊMES
// (préfixe `HomeSearch.` au lieu de `Search.`/`Txt.`), pour que la bascule soit un simple
// renommage à la fusion. Ici, on travaille en caractères Swift : les index ne sortent jamais
// de ce fichier (les extraits sont rendus en `AttributedString`), donc aucune parité d'index
// n'est promise — seulement la même chose TROUVÉE et le même extrait.

enum HomeSearch {
    // MARK: Normalisation

    /// `txNorm(s)` : NFD, marques combinantes U+0300–036F retirées, minuscules. Sert à TOUTES
    /// les comparaisons de l'accueil (recherche, filtre de catégorie par nom, rangement A→Z).
    static func txNorm(_ s: String) -> String {
        let d = s.decomposedStringWithCanonicalMapping.unicodeScalars.filter { !(0x300...0x36f).contains($0.value) }
        return String(String.UnicodeScalarView(d)).lowercased()
    }
    /// `stripBold` : les marques `**…**` de la convention « gras » ne sont pas du texte.
    static func stripBold(_ s: String) -> String { s.replacingOccurrences(of: "**", with: "") }

    /// `qTerms(q)` : termes normalisés, séparés par les blancs.
    static func qTerms(_ q: String) -> [String] {
        txNorm(q).split(whereSeparator: { $0.isWhitespace }).map(String.init).filter { !$0.isEmpty }
    }
    /// `hayMatch(hay, terms)` : ET logique, par sous-chaîne, où qu'elle soit.
    static func hayMatch(_ hay: String, _ terms: [String]) -> Bool {
        terms.allSatisfy { hay.contains($0) }
    }

    // MARK: Foins (le texte cherché d'une entité)

    /// Les cinq listes de portée fiche, dans l'ordre de `ficheHaystack` :
    /// confirmation (entry), verify (watch), posology (dose), notForget (do étoilés), differentials (ddx).
    static func lists(_ f: Fiche) -> [String] {
        var out: [String] = []
        for r: Role in [.entry, .watch, .dose, .do, .ddx] { out += Pool.list(f, r).map(\.legacyString) }
        return out
    }
    /// `ficheHaystack(f)` + nom de catégorie (non mis en cache dans la PWA).
    static func ficheHaystack(_ f: Fiche, categoryName: String) -> String {
        var parts: [String] = [f.title, f.code, f.local]
        parts += lists(f)
        parts += f.sources
        for b in f.blocks {
            parts.append(b.title)
            parts.append(b.question)
            parts += Graph.stepsOf(f, b)
            parts += b.options.map(\.label)
        }
        return txNorm(stripBold(parts.filter { !$0.isEmpty }.joined(separator: " "))) + " " + txNorm(categoryName)
    }
    /// `protocolHaystack(p)` : titre, code, texte rédigé dépouillé, sources, noms des documents.
    static func protocolHaystack(_ p: Reference, categoryName: String) -> String {
        let parts: [String] = [p.title, p.code, mdStrip(p.body)] + p.sources + p.docs.map(\.name)
        return txNorm(parts.filter { !$0.isEmpty }.joined(separator: " ")) + " " + txNorm(categoryName)
    }

    /// `mdStrip(src)` — APPROXIMATION locale du texte brut d'un document mini-Markdown : la
    /// syntaxe de bloc (titres, listes, cases, citations, encadrés, barres de tableau) et les
    /// marques en ligne (`**`, `==`, `` ` ``) sont retirées. Le port exact vit avec le lecteur de
    /// références (C1 §8.6) ; ici, seule compte la TROUVAILLE d'un mot.
    static func mdStrip(_ src: String) -> String {
        var lines: [String] = []
        for raw in src.split(separator: "\n", omittingEmptySubsequences: false) {
            var l = String(raw).trimmingCharacters(in: .whitespaces)
            if l.hasPrefix("```") || l.hasPrefix(":::") { continue }
            while let f = l.first, f == "#" || f == ">" { l.removeFirst(); l = l.trimmingCharacters(in: .whitespaces) }
            for p in ["- [ ] ", "- [x] ", "- [X] ", "- ", "* ", "+ "] where l.hasPrefix(p) { l.removeFirst(p.count); break }
            if let dot = l.firstIndex(of: "."), l[..<dot].allSatisfy(\.isNumber), !l[..<dot].isEmpty {
                l = String(l[l.index(after: dot)...]).trimmingCharacters(in: .whitespaces)
            }
            if l.allSatisfy({ $0 == "|" || $0 == "-" || $0 == ":" || $0 == " " }) { continue }
            l = l.replacingOccurrences(of: "|", with: " ")
            for m in ["**", "==", "`"] { l = l.replacingOccurrences(of: m, with: "") }
            lines.append(l)
        }
        return lines.joined(separator: "\n")
    }

    // MARK: Extraits

    /// Extrait contextuel d'un résultat (`searchSnippet`).
    struct Snippet: Equatable {
        var leading: Bool
        var trailing: Bool
        var text: String
        /// Occurrences à mettre en GRAS (la couleur est un registre : jamais pour une trouvaille).
        var marks: [Range<Int>]   // en index de Character de `text`
    }

    /// Texte normalisé caractère par caractère, avec pour chaque caractère normalisé l'index du
    /// caractère d'origine — un « é » donne « e », une ligature reste elle-même.
    private static func normMap(_ chars: [Character]) -> (norm: [Character], map: [Int]) {
        var n: [Character] = [], m: [Int] = []
        for (i, c) in chars.enumerated() {
            for x in txNorm(String(c)) { n.append(x); m.append(i) }
        }
        return (n, m)
    }
    private static func find(_ hay: [Character], _ needle: [Character], from: Int = 0) -> Int {
        guard !needle.isEmpty, hay.count >= needle.count, from <= hay.count - needle.count else { return -1 }
        var i = from
        while i <= hay.count - needle.count {
            if hay[i] == needle[0] && Array(hay[i..<(i + needle.count)]) == needle { return i }
            i += 1
        }
        return -1
    }
    /// `markQTerms` : intervalles (en caractères de `s`) des occurrences, fusionnés.
    static func markRanges(_ s: String, _ terms: [String]) -> [Range<Int>] {
        let (n, map) = normMap(Array(s))
        var iv: [(Int, Int)] = []
        for t in terms {
            let tc = Array(t)
            guard !tc.isEmpty else { continue }
            var i = 0
            while true {
                i = find(n, tc, from: i)
                if i < 0 { break }
                iv.append((map[i], map[i + tc.count - 1] + 1)); i += tc.count
            }
        }
        let sorted = iv.sorted { $0.0 < $1.0 }
        var m: [(Int, Int)] = []
        for (a, b) in sorted {
            if let l = m.last, a <= l.1 { m[m.count - 1].1 = max(l.1, b) } else { m.append((a, b)) }
        }
        return m.map { $0.0..<$0.1 }
    }
    /// `searchSnippet(parts, q)` : la première partie de CONTENU où un terme paraît ; fenêtre de
    /// 36 caractères avant et 90 après la première occurrence, coupée aux mots, « … » aux bords.
    static func snippet(_ parts: [String], _ q: String) -> Snippet? {
        let T = qTerms(q)
        if T.isEmpty { return nil }
        for raw in parts {
            let s = stripBold(raw).precomposedStringWithCanonicalMapping.trimmingCharacters(in: .whitespacesAndNewlines)
            if s.isEmpty { continue }
            let chars = Array(s)
            let (n, map) = normMap(chars)
            var first = -1
            for t in T {
                let i = find(n, Array(t))
                if i >= 0 && (first < 0 || map[i] < first) { first = map[i] }
            }
            if first < 0 { continue }
            var a = max(0, first - 36), b = min(chars.count, first + 90)
            if a > 0, let sp = chars[a..<first].firstIndex(of: " ") { a = sp + 1 }
            if b < chars.count, let sp = chars[(first + 1)..<b].lastIndex(of: " ") { b = sp }
            let text = String(chars[a..<b])
            return Snippet(leading: a > 0, trailing: b < chars.count, text: text, marks: markRanges(text, T))
        }
        return nil
    }
    /// `ficheSnipParts(f)` : dans l'ordre de LECTURE, titre exclu.
    static func ficheSnipParts(_ f: Fiche) -> [String] {
        var p: [String] = [f.code] + Pool.list(f, .do).map(\.legacyString) + Pool.list(f, .entry).map(\.legacyString)
        for b in f.blocks {
            p.append(b.title)
            p.append(b.question)
            p += Graph.stepsOf(f, b).map(Steps.text)
            p += b.options.map(\.label)
        }
        p += Pool.list(f, .watch).map(\.legacyString) + Pool.list(f, .dose).map(\.legacyString) + Pool.list(f, .ddx).map(\.legacyString)
        p.append(f.local)
        p += f.sources
        return p
    }
    /// `protoSnipParts(p)`.
    static func protoSnipParts(_ p: Reference) -> [String] {
        [p.code] + mdStrip(p.body).split(separator: "\n").map(String.init) + p.docs.map(\.name) + p.sources
    }
    /// L'extrait en texte mis en forme (occurrences en gras).
    static func attributed(_ s: Snippet) -> AttributedString {
        let chars = Array(s.text)
        var out = AttributedString(s.leading ? "… " : "")
        var p = 0
        for r in s.marks where r.lowerBound >= p && r.upperBound <= chars.count {
            out += AttributedString(String(chars[p..<r.lowerBound]))
            var b = AttributedString(String(chars[r]))
            b.inlinePresentationIntent = .stronglyEmphasized
            out += b
            p = r.upperBound
        }
        out += AttributedString(String(chars[p...]))
        if s.trailing { out += AttributedString(" …") }
        return out
    }

    // MARK: Rangements

    /// `azLetter(t)` : première lettre sans accent, en majuscule ; hors A-Z → « # ».
    static func azLetter(_ t: String) -> String {
        guard let c = txNorm(t.trimmingCharacters(in: .whitespacesAndNewlines)).first else { return "#" }
        let u = String(c).uppercased()
        return u.count == 1 && u >= "A" && u <= "Z" ? u : "#"
    }
    /// `azGroups(list)` : groupes par lettre, « # » en fin.
    static func azGroups<T>(_ list: [T], title: (T) -> String) -> [(letter: String, items: [T])] {
        var gm: [String: [T]] = [:], keys: [String] = []
        for x in list {
            let L = azLetter(title(x))
            if gm[L] == nil { keys.append(L) }
            gm[L, default: []].append(x)
        }
        return keys.sorted { a, b in a == "#" ? false : (b == "#" ? true : a < b) }.map { ($0, gm[$0]!) }
    }
    /// `qaPick(list, pins)` : les ÉPINGLÉES seules, dans l'ordre des épingles, sans plafond.
    static func qaPick<T>(_ list: [T], pinIds: [String], id: (T) -> String) -> [T] {
        var pos: [String: Int] = [:]
        for (i, p) in pinIds.enumerated() where pos[p] == nil { pos[p] = i }
        return list.filter { pos[id($0)] != nil }.sorted { pos[id($0)]! < pos[id($1)]! }
    }
    /// `byTitle` : collateur fr, force « base » (casse et accents ignorés), numérique.
    static func compareTitles(_ a: String, _ b: String) -> ComparisonResult {
        a.compare(b, options: [.caseInsensitive, .diacriticInsensitive, .numeric, .widthInsensitive], range: nil, locale: Locale(identifier: "fr"))
    }
    /// Égalité au sens du collateur « base » (`localeCompare(…,{sensitivity:'base'}) === 0`).
    static func sameBase(_ a: String, _ b: String) -> Bool { compareTitles(a, b) == .orderedSame }

    // MARK: Tolérance orthographique

    /// `dlev(a, b, max)` : Damerau-Levenshtein BORNÉE (transposition = 1) ; `max + 1` au-delà.
    static func dlev(_ a0: String, _ b0: String, _ mx: Int) -> Int {
        let a = Array(a0), b = Array(b0)
        let m = a.count, n = b.count
        if abs(m - n) > mx { return mx + 1 }
        if m == 0 { return n }
        if n == 0 { return m }
        var p2: [Int]? = nil
        var p1 = Array(0...n)
        for i in 1...m {
            var cu = Array(repeating: 0, count: n + 1)
            cu[0] = i
            var best = i
            for j in 1...n {
                let c = a[i - 1] == b[j - 1] ? 0 : 1
                var v = Swift.min(cu[j - 1] + 1, p1[j] + 1, p1[j - 1] + c)
                if let p2, i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] { v = Swift.min(v, p2[j - 2] + 1) }
                cu[j] = v
                if v < best { best = v }
            }
            if best > mx { return mx + 1 }
            p2 = p1; p1 = cu
        }
        return p1[n]
    }
    /// `libVocab` : mots de 4 lettres et plus des titres, codes, discriminants et noms fournis.
    static func libVocab(_ items: [(title: String, code: String, discriminant: String)], extra: [String] = []) -> [String] {
        var seen = Set<String>(), out: [String] = []
        func manger(_ v: String) {
            let words = txNorm(v).split(whereSeparator: { c in !(("a"..."z").contains(c) || ("0"..."9").contains(c)) })
            for w in words.map(String.init) where w.count >= 4 && !seen.contains(w) { seen.insert(w); out.append(w) }
        }
        for x in items { manger(x.title); manger(x.code); manger(x.discriminant) }
        for v in extra { manger(v) }
        return out
    }
    /// `spellFix(q, vocab)` : la requête CORRIGÉE, ou nil. Budget 1 (≤ 5 lettres), 2 (≤ 8), 3 ;
    /// égalité → ordre alphabétique ; un fragment d'un mot connu n'est jamais corrigé.
    static func spellFix(_ q: String, vocab: [String]) -> String? {
        let T = qTerms(q)
        if T.isEmpty || vocab.isEmpty { return nil }
        var touche = false
        let out = T.map { t -> String in
            let tl = t.count
            if tl < 4 { return t }
            if vocab.contains(where: { $0.contains(t) }) { return t }
            let mx = tl <= 5 ? 1 : (tl <= 8 ? 2 : 3)
            var best: String? = nil, bd = mx + 1
            for w in vocab {
                let d = dlev(t, w, mx)
                if d < bd || (d == bd && best != nil && w < best!) { bd = d; best = w }
            }
            if let b = best, bd <= mx { touche = true; return b }
            return t
        }
        return touche ? out.joined(separator: " ") : nil
    }

    // MARK: Dates de validation

    /// `staleDate(v)` : validée il y a plus de 730 jours.
    static func staleDate(_ v: String, now: Double = JS.now()) -> Bool {
        guard let d = parseISODay(v) else { return false }
        return now - d > 730 * 86_400_000
    }
    /// 'AAAA-MM' (1ᵉʳ du mois) ou 'AAAA-MM-JJ' → ms UTC (comme `new Date('AAAA-MM-01')`).
    static func parseISODay(_ v: String) -> Double? {
        let p = v.split(separator: "-").map(String.init)
        guard p.count == 2 || p.count == 3, let y = Int(p[0]), let m = Int(p[1]) else { return nil }
        let d = p.count == 3 ? (Int(p[2]) ?? 1) : 1
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let date = cal.date(from: DateComponents(year: y, month: m, day: d)) else { return nil }
        return date.timeIntervalSince1970 * 1000
    }
    /// `fmtDate(v)` : « Validation : MM/AAAA » / « Validation : JJ/MM/AAAA » / « Sans date de validation ».
    static func fmtDate(_ v: String) -> String {
        if v.isEmpty { return "Sans date de validation" }
        let p = v.split(separator: "-").map(String.init)
        if (p.count == 2 || p.count == 3), p[0].count == 4, p[1].count == 2, p.count == 2 || p[2].count == 2,
           p.allSatisfy({ $0.allSatisfy(\.isNumber) }) {
            return "Validation : " + (p.count == 3 ? p[2] + "/" : "") + p[1] + "/" + p[0]
        }
        return "Validation : " + v
    }
    /// `fmtDateShort(v)` : sans le préfixe « Validation : ».
    static func fmtDateShort(_ v: String) -> String {
        let s = fmtDate(v)
        return s.hasPrefix("Validation : ") ? String(s.dropFirst("Validation : ".count)) : s
    }

    // MARK: « À compléter »

    /// `TODO_RX = /[àa] compl[eé]ter/i`.
    static func isTodo(_ s: String) -> Bool {
        let l = s.lowercased()
        return ["à compléter", "a compléter", "à completer", "a completer"].contains { l.contains($0) }
    }
    /// `completionSpots(f)` : où il reste des « à compléter ».
    static func completionSpots(_ f: Fiche) -> [String] {
        var spots: [String] = []
        if isTodo(f.local) { spots.append("Contexte local") }
        let sect: [(Role?, String)] = [(.entry, "Confirmation diagnostique"), (.watch, "À vérifier"), (.do, "Ne pas oublier"),
                                       (.dose, "Repères posologiques"), (.ddx, "Diagnostics différentiels"), (nil, "Références")]
        for (r, label) in sect {
            let l: [String] = r.map { Pool.list(f, $0).map(\.legacyString) } ?? f.sources
            if l.contains(where: isTodo) { spots.append(label) }
        }
        for b in f.blocks {
            let hit = isTodo(b.title) || isTodo(b.question) || Graph.stepsOf(f, b).contains(where: isTodo) || b.options.contains { isTodo($0.label) }
            if hit {
                let t = b.title.trimmingCharacters(in: .whitespaces)
                spots.append("Bloc « " + (t.isEmpty ? "sans titre" : t) + " »")
            }
        }
        return spots
    }

    // MARK: Code de session partagée

    /// Alphabet des codes de partage (8 caractères, sans 0/1/I/O).
    static let shareAlphabet = Set("23456789ABCDEFGHJKLMNPQRSTUVWXYZ")
    /// `homeJoinHtml` : la requête est-elle un code de session valide ? (rend le code nu, 8 car.)
    static func shareCode(_ q: String) -> String? {
        let c = q.trimmingCharacters(in: .whitespaces).uppercased().filter { ("0"..."9").contains($0) || ("A"..."Z").contains($0) }
        guard c.count == 8, c.allSatisfy({ shareAlphabet.contains($0) }) else { return nil }
        return c
    }
}
