import Foundation

// MOTEUR D'EXPRESSIONS RÉGULIÈRES « À LA JAVASCRIPT » — sur des unités UTF-16.
//
// POURQUOI UN MOTEUR MAISON, et pas NSRegularExpression : la PWA décrit sa grammaire (mini-Markdown,
// recherche, repères posologiques, relecture…) par une soixantaine d'expressions régulières JS, et la
// parité exige leur SÉMANTIQUE exacte. ICU (NSRegularExpression) en diffère sur des points qui
// changent des résultats : `\s`, `\d`, `\w` et `\b` y sont Unicode (en JS : jeu fixe / ASCII), `.`
// y exclut aussi U+0085 et U+000B/U+000C, `$` y accepte une fin de ligne finale, et surtout ICU
// compte les QUANTIFICATEURS en points de code là où JS (sans drapeau `u`) compte en unités UTF-16 —
// `[^\]\n]{1,200}` (texte d'un lien) ne s'arrête pas au même endroit sur des emojis.
// Ici les motifs sont recopiés TELS QUELS depuis `index.html` et interprétés par un moteur à retour
// arrière qui suit la spécification ECMAScript (mode non-Unicode, annexe B tolérée) :
// alternance ordonnée, quantificateurs gloutons/paresseux, captures remises à zéro à chaque tour,
// lookahead, `\b` ASCII, `/i` par `Canonicalize` (toUpperCase d'une unité, jamais non-ASCII→ASCII).
// Les répétitions d'un seul caractère (le cas de presque tous les motifs) sont ITÉRATIVES : une ligne
// de 20 000 caractères ne creuse pas la pile.

public final class JSRegExp {
    public let source: String
    public let global: Bool
    public let ignoreCase: Bool
    public let multiline: Bool
    public let dotAll: Bool
    let root: RNode
    public let groupCount: Int

    /// `new RegExp(pattern, flags)`. Les motifs sont des LITTÉRAUX du code : un motif invalide est
    /// une faute de programmation (arrêt), jamais une donnée utilisateur.
    public init(_ pattern: String, _ flags: String = "") {
        source = pattern
        global = flags.contains("g"); ignoreCase = flags.contains("i")
        multiline = flags.contains("m"); dotAll = flags.contains("s")
        var p = RParser(Array(pattern.utf16), dotAll: flags.contains("s"))
        root = p.parseDisjunction()
        guard p.pos == p.src.count else { fatalError("JSRegExp : motif invalide « \(pattern) » à \(p.pos)") }
        groupCount = p.groups
    }

    /// Correspondance : bornes en unités UTF-16, captures (nil = groupe non participant).
    public struct Match {
        public let range: Range<Int>
        public let groups: [Range<Int>?]
        let text: [UInt16]
        /// Texte du groupe `i` (0 = correspondance entière) ; nil si le groupe n'a pas participé.
        public subscript(_ i: Int) -> String? {
            let r = i == 0 ? range : groups[i - 1]
            guard let r else { return nil }
            return JS.str(text[r])
        }
    }

    /// Recherche à partir de `from` (comme `exec` avec `lastIndex = from`).
    public func firstMatch(in s: [UInt16], from: Int = 0) -> Match? {
        guard from <= s.count else { return nil }
        let m = RMatcher(self, s)
        var i = max(0, from)
        while i <= s.count {
            if let end = m.run(at: i) { return Match(range: i..<end, groups: m.captureRanges(), text: s) }
            i += 1
        }
        return nil
    }
    /// Correspondance ANCRÉE à `at` (sémantique « sticky », utilisée par `split`).
    func match(in s: [UInt16], at: Int) -> Match? {
        let m = RMatcher(self, s)
        if let end = m.run(at: at) { return Match(range: at..<end, groups: m.captureRanges(), text: s) }
        return nil
    }
    public func firstMatch(in s: String) -> Match? { firstMatch(in: Array(s.utf16)) }
    /// `re.test(s)`.
    public func test(_ s: String) -> Bool { firstMatch(in: Array(s.utf16)) != nil }
    public func test(_ s: [UInt16]) -> Bool { firstMatch(in: s) != nil }

    /// Toutes les correspondances d'une passe globale (`matchAll` / boucle `exec`), avec la règle JS
    /// de la correspondance VIDE (on avance d'une unité).
    public func allMatches(in s: [UInt16]) -> [Match] {
        var out: [Match] = []
        var i = 0
        while i <= s.count, let m = firstMatch(in: s, from: i) {
            out.append(m)
            i = m.range.isEmpty ? m.range.upperBound + 1 : m.range.upperBound
        }
        return out
    }

    // MARK: String.prototype.replace / split / match

    /// `s.replace(re, template)` — `$1`…`$99`, `$&`, `$$`, `` $` ``, `$'` comme en JS ; un groupe
    /// non participant vaut ''.
    public func replace(_ s: String, _ template: String) -> String {
        let t = Array(template.utf16)
        return replace(s) { m in JS.str(JSRegExp.expand(t, m)) }
    }
    /// `s.replace(re, fonction)` — la fonction reçoit la correspondance.
    public func replace(_ s: String, _ f: (Match) -> String) -> String {
        let u = Array(s.utf16)
        let ms = global ? allMatches(in: u) : (firstMatch(in: u).map { [$0] } ?? [])
        if ms.isEmpty { return s }
        var out: [UInt16] = []
        out.reserveCapacity(u.count)
        var p = 0
        for m in ms {
            out.append(contentsOf: u[p..<m.range.lowerBound])
            out.append(contentsOf: f(m).utf16)
            p = m.range.upperBound
        }
        out.append(contentsOf: u[p...])
        return JS.str(out)
    }

    static func expand(_ t: [UInt16], _ m: Match) -> [UInt16] {
        var out: [UInt16] = []
        var i = 0
        let n = m.groups.count
        while i < t.count {
            let c = t[i]
            if c == 36, i + 1 < t.count {          // '$'
                let d = t[i + 1]
                if d == 36 { out.append(36); i += 2; continue }
                if d == 38 { out.append(contentsOf: m.text[m.range]); i += 2; continue }
                if d == 96 { out.append(contentsOf: m.text[0..<m.range.lowerBound]); i += 2; continue }
                if d == 39 { out.append(contentsOf: m.text[m.range.upperBound...]); i += 2; continue }
                if d >= 48 && d <= 57 {
                    // $nn si valide, sinon $n
                    var num = Int(d - 48), len = 2
                    if i + 2 < t.count, t[i + 2] >= 48, t[i + 2] <= 57 {
                        let two = num * 10 + Int(t[i + 2] - 48)
                        if two >= 1 && two <= n { num = two; len = 3 }
                    }
                    if num >= 1 && num <= n {
                        if let r = m.groups[num - 1] { out.append(contentsOf: m.text[r]) }
                        i += len; continue
                    }
                }
            }
            out.append(c); i += 1
        }
        return out
    }

    /// `s.split(re)` — algorithme de la spécification (correspondance ANCRÉE à chaque position),
    /// captures insérées entre les morceaux.
    public func split(_ s: String) -> [String] { splitOpt(s).map { $0 ?? "" } }
    /// Variante fidèle : une capture non participante vaut `undefined` (nil) comme en JS.
    public func splitOpt(_ s: String) -> [String?] {
        let u = Array(s.utf16)
        if u.isEmpty { return match(in: u, at: 0) != nil ? [] : [""] }
        var out: [String?] = []
        var p = 0, q = 0
        while q < u.count {
            guard let m = match(in: u, at: q) else { q += 1; continue }
            let e = min(m.range.upperBound, u.count)
            if e == p { q += 1; continue }
            out.append(JS.str(u[p..<q]))
            for g in m.groups { out.append(g.map { JS.str(u[$0]) }) }
            p = e; q = p
        }
        out.append(JS.str(u[p...]))
        return out
    }
    /// `s.match(re)` non global : la correspondance, ou nil.
    public func exec(_ s: String) -> Match? { firstMatch(in: Array(s.utf16)) }
}

// MARK: - Arbre

struct RSet {
    var ranges: [(UInt16, UInt16)] = []
    var negated = false
    func has(_ c: UInt16) -> Bool {
        for (a, b) in ranges where c >= a && c <= b { return true }
        return false
    }
    func contains(_ c: UInt16, ignoreCase: Bool) -> Bool {
        var hit = has(c)
        if !hit && ignoreCase {
            // Canonicalize (ES2023 22.2.2.7.3, non-Unicode) : on teste l'unité, sa forme canonique
            // et la minuscule de celle-ci — couvre les paires de casse, y compris µ/Μ/μ.
            let k = JSRegExp.canon(c)
            if k != c && has(k) { hit = true }
            else if let l = JSRegExp.lower1(k), l != c, JSRegExp.canon(l) == k, has(l) { hit = true }
            else if let l = JSRegExp.lower1(c), l != c, JSRegExp.canon(l) == k, has(l) { hit = true }
        }
        return hit != negated
    }
}

indirect enum RNode {
    case empty
    case char(UInt16)
    case set(RSet)
    case seq([RNode])
    case alt([RNode])
    case group(RNode, Int)                  // capture n° (0-based)
    case rep(RNode, Int, Int, Bool, Int, Int) // atome, min, max, glouton, 1re capture, nb captures
    case bol, eol
    case wordB(Bool)
    case look(RNode, Bool)                  // lookahead, négatif ?
    case backref(Int)

    var single: Bool { switch self { case .char, .set: return true; default: return false } }
}

extension JSRegExp {
    /// Canonicalize(ch) du mode non-Unicode : majuscule d'UNE unité ; si elle fait plus d'une unité
    /// ou qu'elle ferait passer un caractère non-ASCII en ASCII, le caractère reste tel quel.
    static func canon(_ c: UInt16) -> UInt16 {
        if c < 128 { return (c >= 97 && c <= 122) ? c - 32 : c }
        guard let sc = Unicode.Scalar(c) else { return c }
        let u = Array(String(sc).uppercased().utf16)
        if u.count != 1 { return c }
        if u[0] < 128 { return c }
        return u[0]
    }
    static func lower1(_ c: UInt16) -> UInt16? {
        guard let sc = Unicode.Scalar(c) else { return nil }
        let u = Array(String(sc).lowercased().utf16)
        return u.count == 1 ? u[0] : nil
    }
}

// MARK: - Analyse du motif

struct RParser {
    let src: [UInt16]
    var pos = 0
    var groups = 0
    let dotAll: Bool
    init(_ s: [UInt16], dotAll: Bool) { src = s; self.dotAll = dotAll }

    var peek: UInt16? { pos < src.count ? src[pos] : nil }
    mutating func eat(_ c: UInt16) -> Bool { if peek == c { pos += 1; return true }; return false }

    mutating func parseDisjunction() -> RNode {
        var alts = [parseAlternative()]
        while eat(124) { alts.append(parseAlternative()) }   // '|'
        return alts.count == 1 ? alts[0] : .alt(alts)
    }
    mutating func parseAlternative() -> RNode {
        var seq: [RNode] = []
        while let c = peek, c != 124, c != 41 {                // '|' ')'
            seq.append(parseTerm())
        }
        return seq.count == 1 ? seq[0] : .seq(seq)
    }
    mutating func parseTerm() -> RNode {
        let c = src[pos]
        if c == 94 { pos += 1; return .bol }                   // ^
        if c == 36 { pos += 1; return .eol }                   // $
        if c == 92, pos + 1 < src.count {                      // \b \B
            if src[pos + 1] == 98 { pos += 2; return .wordB(true) }
            if src[pos + 1] == 66 { pos += 2; return .wordB(false) }
        }
        if c == 40, pos + 2 < src.count, src[pos + 1] == 63, src[pos + 2] == 61 || src[pos + 2] == 33 { // (?= (?!
            let neg = src[pos + 2] == 33
            pos += 3
            let inner = parseDisjunction()
            precondition(eat(41), "JSRegExp : ')' attendue")
            // Annexe B : un lookahead peut être quantifié ; aucun motif du port ne le fait.
            return .look(inner, neg)
        }
        let firstGroup = groups
        let atom = parseAtom()
        return parseQuantifier(atom, firstGroup)
    }
    mutating func parseQuantifier(_ atom: RNode, _ firstGroup: Int) -> RNode {
        guard let c = peek else { return atom }
        var mn = 0, mx = Int.max
        switch c {
        case 42: mn = 0; pos += 1                               // *
        case 43: mn = 1; pos += 1                               // +
        case 63: mn = 0; mx = 1; pos += 1                       // ?
        case 123:                                               // {n,m} — sinon littéral (annexe B)
            let save = pos
            pos += 1
            guard let a = readInt() else { pos = save; return atom }
            mn = a; mx = a
            if eat(44) { mx = readInt() ?? Int.max }
            guard eat(125) else { pos = save; return atom }
        default: return atom
        }
        let greedy = !eat(63)
        return .rep(atom, mn, mx, greedy, firstGroup, groups - firstGroup)
    }
    mutating func readInt() -> Int? {
        var v: Int? = nil
        while let c = peek, c >= 48, c <= 57 { v = (v ?? 0) * 10 + Int(c - 48); pos += 1 }
        return v
    }
    mutating func parseAtom() -> RNode {
        let c = src[pos]
        switch c {
        case 46:                                                // .
            pos += 1
            return .set(dotAll ? RSet(ranges: [(0, 0xFFFF)]) : RSet(ranges: [(10, 10), (13, 13), (0x2028, 0x2029)], negated: true))
        case 40:                                                // (
            pos += 1
            if peek == 63, pos + 1 < src.count, src[pos + 1] == 58 {   // (?:
                pos += 2
                let inner = parseDisjunction()
                precondition(eat(41))
                return inner
            }
            let idx = groups
            groups += 1
            let inner = parseDisjunction()
            precondition(eat(41), "JSRegExp : ')' attendue")
            return .group(inner, idx)
        case 91:                                                // [
            pos += 1
            return .set(parseClass())
        case 92:                                                // \
            pos += 1
            return parseAtomEscape()
        default:
            pos += 1
            return .char(c)
        }
    }
    static let spaceRanges: [(UInt16, UInt16)] = [(9, 13), (32, 32), (0xA0, 0xA0), (0x1680, 0x1680), (0x2000, 0x200A),
                                                  (0x2028, 0x2029), (0x202F, 0x202F), (0x205F, 0x205F), (0x3000, 0x3000), (0xFEFF, 0xFEFF)]
    static let digitRanges: [(UInt16, UInt16)] = [(48, 57)]
    static let wordRanges: [(UInt16, UInt16)] = [(48, 57), (65, 90), (95, 95), (97, 122)]

    /// Classe d'échappement (\d \s \w et leurs négations) — nil si ce n'en est pas une.
    static func classEscape(_ c: UInt16) -> RSet? {
        switch c {
        case 100: return RSet(ranges: digitRanges)
        case 68: return RSet(ranges: digitRanges, negated: true)
        case 115: return RSet(ranges: spaceRanges)
        case 83: return RSet(ranges: spaceRanges, negated: true)
        case 119: return RSet(ranges: wordRanges)
        case 87: return RSet(ranges: wordRanges, negated: true)
        default: return nil
        }
    }
    mutating func charEscape(_ c: UInt16, inClass: Bool) -> UInt16 {
        switch c {
        case 110: return 10          // \n
        case 114: return 13          // \r
        case 116: return 9           // \t
        case 118: return 11          // \v
        case 102: return 12          // \f
        case 48: return 0            // \0
        case 98 where inClass: return 8
        case 117:                    // \uXXXX
            if pos + 4 <= src.count, let v = UInt16(String(decoding: src[pos..<(pos + 4)], as: UTF16.self), radix: 16) { pos += 4; return v }
            return c
        case 120:                    // \xXX
            if pos + 2 <= src.count, let v = UInt16(String(decoding: src[pos..<(pos + 2)], as: UTF16.self), radix: 16) { pos += 2; return v }
            return c
        default: return c            // échappement d'identité
        }
    }
    mutating func parseAtomEscape() -> RNode {
        let c = src[pos]; pos += 1
        if let s = RParser.classEscape(c) { return .set(s) }
        if c >= 49 && c <= 57 { return .backref(Int(c - 49)) }
        return .char(charEscape(c, inClass: false))
    }
    mutating func parseClass() -> RSet {
        var set = RSet()
        if eat(94) { set.negated = true }
        while let c = peek, c != 93 {
            // un élément : caractère, échappement, ou classe d'échappement
            var lo: UInt16
            if c == 92 {
                pos += 1
                let e = src[pos]; pos += 1
                if let cs = RParser.classEscape(e) {
                    if cs.negated {
                        // complément des plages (seul \S / \D / \W dans une classe)
                        var prev: UInt32 = 0
                        for (a, b) in cs.ranges.sorted(by: { $0.0 < $1.0 }) {
                            if UInt32(a) > prev { set.ranges.append((UInt16(prev), a - 1)) }
                            prev = UInt32(b) + 1
                        }
                        if prev <= 0xFFFF { set.ranges.append((UInt16(prev), 0xFFFF)) }
                    } else { set.ranges.append(contentsOf: cs.ranges) }
                    continue
                }
                lo = charEscape(e, inClass: true)
            } else { lo = c; pos += 1 }
            // plage a-b ?
            if peek == 45, pos + 1 < src.count, src[pos + 1] != 93 {
                pos += 1
                var hi: UInt16
                if src[pos] == 92 {
                    pos += 1
                    let e = src[pos]; pos += 1
                    hi = charEscape(e, inClass: true)
                } else { hi = src[pos]; pos += 1 }
                set.ranges.append((lo, hi))
            } else {
                set.ranges.append((lo, lo))
            }
        }
        precondition(eat(93), "JSRegExp : ']' attendu")
        return set
    }
}

// MARK: - Exécution (retour arrière par continuations)

final class RMatcher {
    let re: JSRegExp
    let s: [UInt16]
    var caps: [Int]
    init(_ re: JSRegExp, _ s: [UInt16]) {
        self.re = re; self.s = s
        caps = Array(repeating: -1, count: re.groupCount * 2)
    }
    func captureRanges() -> [Range<Int>?] {
        (0..<re.groupCount).map { g in
            let a = caps[2 * g], b = caps[2 * g + 1]
            return (a >= 0 && b >= a) ? a..<b : nil
        }
    }
    func run(at i: Int) -> Int? {
        for k in caps.indices { caps[k] = -1 }
        var end = -1
        if m(re.root, i, { j in end = j; return true }) { return end }
        return nil
    }

    @inline(__always) func isWord(_ i: Int) -> Bool {
        guard i >= 0, i < s.count else { return false }
        let c = s[i]
        return (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || c == 95 || (c >= 97 && c <= 122)
    }
    @inline(__always) func isLT(_ c: UInt16) -> Bool { c == 10 || c == 13 || c == 0x2028 || c == 0x2029 }

    @inline(__always) func one(_ n: RNode, _ i: Int) -> Bool {
        guard i < s.count else { return false }
        switch n {
        case .char(let c):
            return re.ignoreCase ? JSRegExp.canon(c) == JSRegExp.canon(s[i]) : c == s[i]
        case .set(let st):
            return st.contains(s[i], ignoreCase: re.ignoreCase)
        default: return false
        }
    }

    func m(_ n: RNode, _ i: Int, _ k: (Int) -> Bool) -> Bool {
        switch n {
        case .empty: return k(i)
        case .char, .set: return one(n, i) ? k(i + 1) : false
        case .seq(let ns): return seq(ns, 0, i, k)
        case .alt(let ns):
            for a in ns { if m(a, i, k) { return true } }
            return false
        case .group(let inner, let g):
            return m(inner, i) { j in
                let o0 = caps[2 * g], o1 = caps[2 * g + 1]
                caps[2 * g] = i; caps[2 * g + 1] = j
                if k(j) { return true }
                caps[2 * g] = o0; caps[2 * g + 1] = o1
                return false
            }
        case .bol:
            if i == 0 || (re.multiline && isLT(s[i - 1])) { return k(i) }
            return false
        case .eol:
            if i == s.count || (re.multiline && isLT(s[i])) { return k(i) }
            return false
        case .wordB(let b):
            return (isWord(i - 1) != isWord(i)) == b ? k(i) : false
        case .look(let inner, let neg):
            let saved = caps
            let hit = m(inner, i) { _ in true }
            if neg {
                caps = saved
                return hit ? false : k(i)
            }
            if !hit { caps = saved; return false }
            if k(i) { return true }
            caps = saved
            return false
        case .backref(let g):
            let a = caps[2 * g], b = caps[2 * g + 1]
            guard a >= 0, b >= a else { return k(i) }
            let len = b - a
            guard i + len <= s.count else { return false }
            for x in 0..<len {
                let p = s[a + x], q = s[i + x]
                if re.ignoreCase ? JSRegExp.canon(p) != JSRegExp.canon(q) : p != q { return false }
            }
            return k(i + len)
        case .rep(let atom, let mn, let mx, let greedy, let g0, let gn):
            if atom.single {
                // Répétition d'UN caractère : on compte la course, puis on essaie les longueurs.
                var n = 0
                while n < mx, one(atom, i + n) { n += 1 }
                if n < mn { return false }
                if greedy {
                    var c = n
                    while c >= mn { if k(i + c) { return true }; c -= 1 }
                } else {
                    var c = mn
                    while c <= n { if k(i + c) { return true }; c += 1 }
                }
                return false
            }
            return rep(atom, mn, mx, greedy, g0, gn, 0, i, k)
        }
    }
    func seq(_ ns: [RNode], _ x: Int, _ i: Int, _ k: (Int) -> Bool) -> Bool {
        if x == ns.count { return k(i) }
        return m(ns[x], i) { j in seq(ns, x + 1, j, k) }
    }
    func rep(_ atom: RNode, _ mn: Int, _ mx: Int, _ greedy: Bool, _ g0: Int, _ gn: Int, _ count: Int, _ i: Int, _ k: (Int) -> Bool) -> Bool {
        if mx == 0 { return k(i) }
        // Chaque tour remet à zéro les captures de l'atome (spécification, RepeatMatcher).
        func iter(_ cont: (Int) -> Bool) -> Bool {
            let saved = Array(caps[(2 * g0)..<(2 * (g0 + gn))])
            for x in (2 * g0)..<(2 * (g0 + gn)) { caps[x] = -1 }
            if m(atom, i, cont) { return true }
            for (o, v) in saved.enumerated() { caps[2 * g0 + o] = v }
            return false
        }
        if count < mn {
            return iter { j in rep(atom, mn, mx, greedy, g0, gn, count + 1, j, k) }
        }
        if greedy {
            if count < mx, iter({ j in j != i && rep(atom, mn, mx, greedy, g0, gn, count + 1, j, k) }) { return true }
            return k(i)
        }
        if k(i) { return true }
        return count < mx && iter { j in j != i && rep(atom, mn, mx, greedy, g0, gn, count + 1, j, k) }
    }
}

// MARK: - Primitives de chaîne JS (unités UTF-16)

extension JS {
    /// Unités UTF-16 → String (une moitié de paire isolée devient U+FFFD : aucun chemin du port
    /// n'en fabrique, les coupes tombant sur des délimiteurs ASCII).
    @inline(__always) public static func str<C: Collection>(_ u: C) -> String where C.Element == UInt16 {
        String(decoding: u, as: UTF16.self)
    }
    public static func u16(_ s: String) -> [UInt16] { Array(s.utf16) }

    /// `s.indexOf(t, from)` en unités UTF-16 (jamais d'équivalence canonique, contrairement aux
    /// recherches Foundation/Swift sur `String`).
    public static func indexOf(_ s: [UInt16], _ t: [UInt16], from: Int = 0) -> Int {
        let n = s.count, m = t.count
        var i = max(0, from)
        if m == 0 { return min(i, n) }
        guard m <= n else { return -1 }
        while i <= n - m {
            if s[i] == t[0] {
                var j = 1
                while j < m && s[i + j] == t[j] { j += 1 }
                if j == m { return i }
            }
            i += 1
        }
        return -1
    }
    public static func indexOf(_ s: String, _ t: String, from: Int = 0) -> Int { indexOf(Array(s.utf16), Array(t.utf16), from: from) }
    /// `s.lastIndexOf(t, from)`.
    public static func lastIndexOf(_ s: [UInt16], _ t: [UInt16], from: Int? = nil) -> Int {
        let n = s.count, m = t.count
        var i = min(from ?? n, n - m)
        while i >= 0 {
            var j = 0
            while j < m && s[i + j] == t[j] { j += 1 }
            if j == m { return i }
            i -= 1
        }
        return -1
    }
    /// `s.includes(t)`.
    public static func includes(_ s: String, _ t: String) -> Bool { indexOf(Array(s.utf16), Array(t.utf16)) >= 0 }
    /// `s.split(sep)` avec un séparateur CHAÎNE non vide.
    public static func split(_ s: String, _ sep: String) -> [String] {
        let u = Array(s.utf16), t = Array(sep.utf16)
        guard !t.isEmpty else { return u.map { JS.str([$0]) } }
        var out: [String] = []
        var p = 0
        while true {
            let i = indexOf(u, t, from: p)
            if i < 0 { break }
            out.append(JS.str(u[p..<i]))
            p = i + t.count
        }
        out.append(JS.str(u[p...]))
        return out
    }

    /// `String.prototype.toLowerCase()` — correspondance COMPLÈTE d'Unicode, avec la seule règle de
    /// contexte que la spécification impose (sigma final : Σ → ς en fin de mot). Le `lowercased()`
    /// de Swift n'applique aucun contexte.
    public static func toLowerCase(_ s: String) -> String {
        let sc = Array(s.unicodeScalars)
        guard sc.contains(where: { $0.value == 0x3A3 }) else { return s.lowercased() }
        var out = String.UnicodeScalarView()
        for (i, c) in sc.enumerated() {
            if c.value == 0x3A3 {
                var before = false
                var j = i - 1
                while j >= 0, sc[j].properties.isCaseIgnorable { j -= 1 }
                if j >= 0, sc[j].properties.isCased { before = true }
                var after = false
                j = i + 1
                while j < sc.count, sc[j].properties.isCaseIgnorable { j += 1 }
                if j < sc.count, sc[j].properties.isCased { after = true }
                out.append(before && !after ? "\u{3C2}" : "\u{3C3}")
            } else {
                out.append(contentsOf: String(c).lowercased().unicodeScalars)
            }
        }
        return String(out)
    }
    /// `String.prototype.toUpperCase()` (correspondance complète, sans contexte).
    public static func toUpperCase(_ s: String) -> String { s.uppercased() }

    /// `s.normalize('NFD')`.
    public static func nfd(_ s: String) -> String { s.decomposedStringWithCanonicalMapping }
    /// `s.normalize('NFC')`.
    public static func nfc(_ s: String) -> String { s.precomposedStringWithCanonicalMapping }

    /// `x.toFixed(d)` : l'entier n le plus proche de x·10^d sur la valeur BINAIRE exacte, et à
    /// égalité parfaite le plus GRAND (printf arrondirait au pair : 1.25 → « 1.2 » contre « 1.3 » en JS).
    public static func toFixed(_ x: Double, _ d: Int) -> String {
        guard x.isFinite else { return JSON.formatNumber(x) }
        // Développement décimal EXACT (la libc imprime la valeur binaire exacte).
        let full = String(format: "%.100f", abs(x))
        let parts = full.split(separator: ".", omittingEmptySubsequences: false)
        let ip = String(parts[0]), fp = parts.count > 1 ? String(parts[1]) : ""
        var digits = Array(ip + String(fp.prefix(d)))
        // premier chiffre abandonné ≥ 5 : au-dessus de la moitié, ou égalité → le plus grand.
        if let f = fp.dropFirst(d).first, f >= "5" {
            var i = digits.count - 1
            while i >= 0 {
                if digits[i] == "9" { digits[i] = "0"; i -= 1 } else { digits[i] = Character(String(digits[i].wholeNumberValue! + 1)); break }
            }
            if i < 0 { digits.insert("1", at: 0) }
        }
        var s = String(digits)
        if d > 0 { s.insert(".", at: s.index(s.endIndex, offsetBy: -d)) }
        // JS garde le signe même quand le résultat s'écrit zéro : (-0.001).toFixed(2) === "-0.00".
        return (x < 0 ? "-" : "") + s
    }
    /// `String(n)` pour un nombre (formatage JS : entiers sans « .0 », sinon représentation courte).
    public static func numStr(_ n: Double) -> String { JSON.formatNumber(n) }
}
