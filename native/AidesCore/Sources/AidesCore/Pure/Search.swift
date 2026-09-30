import Foundation

// RECHERCHE ET ACCUEIL — port de `ficheHaystack`, `qTerms`, `hayMatch`, `markQTerms`,
// `searchSnippet`, `ficheSnipParts`, `protoSnipParts`, `frecencyScore`, `sanitizeUsage`,
// `mergeUsage`, `azLetter`, `azGroups`, `qaPick`, `byTitle`, `relCandidatesFor`, `libVocab`,
// `spellFix`, `dlev`, `revisedSinceTxt`.
//
// La recherche doit trouver LA MÊME CHOSE des deux côtés : même normalisation (`txNorm`), même
// découpe en termes, même « ET » logique par sous-chaîne, même tolérance orthographique bornée
// (on corrige la REQUÊTE, jamais la liste ; déterministe). Les index sont en unités UTF-16, comme
// en JS — y compris le décalage que la PWA assume entre une chaîne et sa forme normalisée.

public enum Search {
    // MARK: Termes et foin

    static let rxWs = JSRegExp(#"\s+"#)
    /// `qTerms(q)` : termes normalisés, séparés par les blancs.
    public static func qTerms(_ q: String) -> [String] { rxWs.split(Txt.txNorm(q)).filter { !$0.isEmpty } }
    /// `hayMatch(hay, terms)` : chaque terme présent (ET logique, sous-chaîne, où qu'il soit).
    public static func hayMatch(_ hay: String, _ terms: [String]) -> Bool {
        let h = Array(hay.utf16)
        return terms.allSatisfy { JS.indexOf(h, Array($0.utf16)) >= 0 }
    }
    /// `ficheHaystack(f)` : tout le texte d'une aide, normalisé, suivi du NOM de sa catégorie.
    /// `categoryName` = `catName(f)` (la catégorie se résout dans la bibliothèque de l'aide ; le nom
    /// n'est pas porté par la fiche, d'où le paramètre). La PWA met la partie fiche en cache par objet.
    public static func ficheHaystack(_ f: Fiche, categoryName: String) -> String {
        var parts: [String] = [f.title, f.code, f.local]
        for k: Parcours.ListKey in [.confirmation, .verify, .posology, .notForget, .differentials] { parts += Parcours.listOf(f, k) }
        parts += f.sources
        for b in f.blocks {
            parts.append(b.title)
            parts.append(b.question)
            parts += Parcours.stepsOf(f, b)
            parts += b.options.map(\.label)
        }
        let h = Txt.txNorm(Txt.stripBold(parts.filter { !$0.isEmpty }.joined(separator: " ")))
        return h + " " + Txt.txNorm(categoryName)
    }

    // MARK: Extraits

    /// `markQTerms(s, terms)` : intervalles [début, fin) (unités UTF-16 de `s`) des occurrences,
    /// FUSIONNÉS quand ils se chevauchent. Les index viennent de `txNorm(s)` et s'appliquent à `s` :
    /// l'alignement 1:1 est celui qu'assume la PWA (un caractère composé → un caractère nu).
    public static func markRanges(_ s: String, _ terms: [String]) -> [Range<Int>] {
        let n = Array(Txt.txNorm(s).utf16)
        var iv: [(Int, Int)] = []
        for t in terms {
            let tu = Array(t.utf16)
            guard !tu.isEmpty else { continue }
            var i = 0
            while true {
                i = JS.indexOf(n, tu, from: i)
                if i < 0 { break }
                iv.append((i, i + tu.count)); i += tu.count
            }
        }
        if iv.isEmpty { return [] }
        let sorted = iv.enumerated().sorted { $0.element.0 != $1.element.0 ? $0.element.0 < $1.element.0 : $0.offset < $1.offset }.map(\.element)
        var m: [(Int, Int)] = []
        for (a, b) in sorted {
            if let l = m.last, a <= l.1 { m[m.count - 1].1 = max(l.1, b) } else { m.append((a, b)) }
        }
        return m.map { $0.0..<$0.1 }
    }
    /// `markQTerms` en HTML (occurrences en `<b>`, tout le reste échappé) — le rendu de la PWA.
    public static func markQTermsHTML(_ s: String, _ terms: [String]) -> String {
        let r = markRanges(s, terms)
        if r.isEmpty { return Txt.esc(s) }
        var out = "", p = 0
        for x in r {
            out += Txt.esc(JS.slice(s, p, x.lowerBound)) + "<b>" + Txt.esc(JS.slice(s, x.lowerBound, x.upperBound)) + "</b>"
            p = x.upperBound
        }
        return out + Txt.esc(JS.slice(s, p))
    }

    /// Extrait contextuel d'un résultat : ~120 caractères autour du premier terme, coupés aux mots.
    public struct Snippet: Equatable, Sendable {
        /// « … » en tête / en queue (bord tronqué).
        public var leading: Bool
        public var trailing: Bool
        public var text: String
        /// Occurrences à mettre en relief (GRAISSE seule — la couleur est un registre), dans `text`.
        public var marks: [Range<Int>]
    }
    /// `searchSnippet(parts, q)` : la première partie de CONTENU où la requête correspond.
    public static func snippet(_ parts: [String], _ q: String) -> Snippet? {
        let T = qTerms(q)
        if T.isEmpty { return nil }
        for raw in parts {
            let s = JS.trim(JS.nfc(Txt.stripBold(raw)))
            if s.isEmpty { continue }
            let n = Array(Txt.txNorm(s).utf16)
            var first = -1
            for t in T {
                let i = JS.indexOf(n, Array(t.utf16))
                if i >= 0 && (first < 0 || i < first) { first = i }
            }
            if first < 0 { continue }
            let su = Array(s.utf16)
            var a = max(0, first - 36), b = min(su.count, first + 90)
            if a > 0 { let sp = JS.indexOf(su, [32], from: a); if sp >= 0 && sp < first { a = sp + 1 } }
            if b < su.count { let sp = JS.lastIndexOf(su, [32], from: b); if sp > first { b = sp } }
            let text = JS.slice(s, a, b)
            return Snippet(leading: a > 0, trailing: b < su.count, text: text, marks: markRanges(text, T))
        }
        return nil
    }
    /// `searchSnippet` en HTML (div `card-snip`), '' sans correspondance.
    public static func snippetHTML(_ parts: [String], _ q: String) -> String {
        guard let s = snippet(parts, q) else { return "" }
        return "<div class=\"card-snip\">" + (s.leading ? "… " : "") + markQTermsHTML(s.text, qTerms(q)) + (s.trailing ? " …" : "") + "</div>"
    }
    /// `ficheSnipParts(f)` : les sources de l'extrait, dans l'ordre de LECTURE (titre exclu).
    public static func ficheSnipParts(_ f: Fiche) -> [String] {
        var p: [String] = [f.code] + Parcours.listOf(f, .notForget) + Parcours.listOf(f, .confirmation)
        for b in f.blocks {
            p.append(b.title)
            p.append(b.question)
            p += Parcours.stepsOf(f, b).map(Steps.text)
            p += b.options.map(\.label)
        }
        p += Parcours.listOf(f, .verify) + Parcours.listOf(f, .posology) + Parcours.listOf(f, .differentials)
        p.append(f.local)
        p += f.sources
        return p
    }
    static let rxNl = JSRegExp(#"\n+"#)
    /// `protoSnipParts(p)` pour une référence.
    public static func protoSnipParts(_ p: Reference) -> [String] {
        [p.code] + rxNl.split(Markdown.strip(p.body)) + p.docs.map(\.name) + p.sources
    }

    // MARK: Fréquence d'usage (frecency)

    public struct Usage: Equatable, Sendable { public var n: Int; public var t: Double }
    /// `frecencyScore(u, now)` : ouvertures amorties par l'ancienneté (≤ 15 j pleine valeur, ≤ 60 j
    /// moitié, au-delà un quart — une fiche saisonnière revient).
    public static func frecencyScore(_ u: Usage?, now: Double) -> Double {
        guard let u, u.n != 0 else { return 0 }
        let days = max(0, (now - u.t) / 86_400_000)
        return Double(u.n) * (days <= 15 ? 1 : (days <= 60 ? 0.5 : 0.25))
    }
    static func floorNum(_ v: JSON?) -> Double {
        let x = JS.number(v)
        return (x.isNaN || x == 0) ? 0 : x.rounded(.down)
    }
    /// `sanitizeUsage(o)` : ids sûrs, n entier 1…9999, t entier ≥ 0, 200 entrées au plus (les plus
    /// récentes). ⚠ À égalité d'horodatage au-delà de 200 entrées, la PWA garde l'ordre d'insertion
    /// des clés, que le JSON natif ne conserve pas : départage ici par clé (cas sans portée pratique).
    public static func sanitizeUsage(_ o: JSON?) -> [String: Usage] {
        var out: [String: Usage] = [:]
        guard let obj = o?.object else { return out }
        for (id, u) in obj where Guard.matchesSafeIdPattern(id) && !Guard.badKeys.contains(id) {
            guard u.object != nil || u.array != nil else { continue }
            let n = min(9999, max(0, floorNum(u["n"])))
            let t = max(0, floorNum(u["t"]))
            if n > 0 { out[id] = Usage(n: Int(n), t: t) }
        }
        if out.count > 200 {
            let ids = out.keys.sorted { (out[$0]!.t, $0) < (out[$1]!.t, $1) }
            for k in ids.prefix(out.count - 200) { out[k] = nil }
        }
        return out
    }
    /// `mergeUsage(a, b)` : par id, le n le plus GRAND (à égalité, t le plus récent) — max idempotent,
    /// jamais de double compte ; puis `sanitizeUsage`. Les comparaisons suivent JS à la lettre
    /// (`>` entre deux chaînes compare les chaînes, `===` exige le même type). Une entrée `null`
    /// est ignorée (la PWA lèverait une exception sur `null.n`).
    public static func mergeUsage(_ a: JSON?, _ b: JSON?) -> [String: Usage] {
        var out: [String: [String: JSON]] = [:]
        func entries(_ j: JSON?) -> [(String, JSON)] {
            if let o = j?.object { return o.map { ($0.key, $0.value) } }
            if let a = j?.array { return a.enumerated().map { (String($0.offset), $0.element) } }
            return []
        }
        func or0(_ v: JSON?) -> JSON { (v?.truthy ?? false) ? v! : 0 }
        for src in [a, b] {
            for (id, u) in entries(src) {
                if u.isNull { continue }
                let cur = out[id]
                if cur == nil || JS.greater(u["n"], cur!["n"]) || (JS.strictEq(u["n"], cur!["n"]) && JS.greater(or0(u["t"]), or0(cur!["t"]))) {
                    var e: [String: JSON] = ["t": or0(u["t"])]
                    if let n = u["n"] { e["n"] = n }
                    out[id] = e
                }
            }
        }
        return sanitizeUsage(.object(out.mapValues { .object($0) }))
    }

    // MARK: Répertoire A→Z, épinglées

    /// `azLetter(t)` : la lettre de rangement (accents retirés, majuscule) ; hors A-Z → « # ».
    /// Parité : la majuscule d'UNE unité peut faire deux lettres (« ß » → « SS ») — gardée telle quelle.
    public static func azLetter(_ t: String) -> String {
        let d = Array(Txt.combining.replace(JS.nfd(JS.trim(t)), "").utf16)
        guard let c0 = d.first else { return "#" }
        let c = JS.toUpperCase(JS.str([c0]))
        return c.utf16.contains(where: { $0 >= 65 && $0 <= 90 }) ? c : "#"
    }
    /// `azGroups(list, titleOf)` : groupes par lettre, « # » en fin.
    public static func azGroups<T>(_ list: [T], title: (T) -> String) -> [(letter: String, items: [T])] {
        var gm: [String: [T]] = [:], keys: [String] = []
        for x in list {
            let L = azLetter(title(x))
            if gm[L] == nil { keys.append(L) }
            gm[L, default: []].append(x)
        }
        return keys.sorted { a, b in a == "#" ? false : (b == "#" ? true : Array(a.utf16).lexicographicallyPrecedes(Array(b.utf16))) }
            .map { ($0, gm[$0]!) }
    }
    /// `qaPick(list, pinIds)` : les ÉPINGLÉES seules, dans l'ordre des épingles, sans plafond.
    public static func qaPick<T>(_ list: [T], pinIds: [String], id: (T) -> String) -> [T] {
        list.filter { pinIds.contains(id($0)) }.sorted { pinIds.firstIndex(of: id($0))! < pinIds.firstIndex(of: id($1))! }
    }

    // MARK: Tri par titre

    /// `byTitle` : `Intl.Collator('fr', {sensitivity:'base', numeric:true})` — casse et accents
    /// ignorés, nombres comparés comme des nombres (« Bloc 2 » avant « Bloc 10 »).
    /// Portage : comparaison Foundation localisée (fr) à la même force ; à égalité primaire, 0
    /// comme le collateur (l'ordre stable d'origine décide).
    public static func compareTitles(_ a: String, _ b: String) -> ComparisonResult {
        a.compare(b, options: [.caseInsensitive, .diacriticInsensitive, .numeric, .widthInsensitive], range: nil, locale: Locale(identifier: "fr"))
    }
    /// Tri STABLE par titre (le tri JS d'`Array#sort` l'est).
    public static func sortedByTitle<T>(_ list: [T], title: (T) -> String) -> [T] {
        list.enumerated().sorted { x, y in
            let c = compareTitles(title(x.element), title(y.element))
            return c == .orderedSame ? x.offset < y.offset : c == .orderedAscending
        }.map(\.element)
    }

    // MARK: « Voir aussi »

    public struct RelCandidate: Equatable, Sendable {
        public var id: String, title: String
        /// 'f' aide, 'p' référence
        public var kind: String
        public var code: String
    }
    /// `relCandidatesFor(entity, fs, ps)` : aides puis références du MÊME périmètre (Perso ou même
    /// bibliothèque), hors soi-même, déjà liées et corbeille, chacune triée par titre.
    public static func relCandidatesFor(id: String, links: [String], library: String?, fiches: [Fiche], references: [Reference]) -> [RelCandidate] {
        let have = Set([id] + links)
        let scope = (library?.isEmpty ?? true) ? nil : library
        func ok(_ lib: String?, _ del: Double?, _ xid: String) -> Bool {
            del == nil && !have.contains(xid) && ((lib?.isEmpty ?? true) ? nil : lib) == scope
        }
        let fs = sortedByTitle(fiches.filter { ok($0.library, $0.deletedAt, $0.id) }, title: \.title)
            .map { RelCandidate(id: $0.id, title: $0.title.isEmpty ? "Sans titre" : $0.title, kind: "f", code: $0.code) }
        let ps = sortedByTitle(references.filter { ok($0.library, $0.deletedAt, $0.id) }, title: \.title)
            .map { RelCandidate(id: $0.id, title: $0.title.isEmpty ? "Sans titre" : $0.title, kind: "p", code: $0.code) }
        return fs + ps
    }

    // MARK: Tolérance orthographique

    /// `dlev(a, b, max)` : Damerau-Levenshtein BORNÉE (transposition = 1), en unités UTF-16 ;
    /// rend `max + 1` dès que la borne est dépassée.
    public static func dlev(_ a0: String, _ b0: String, _ max: Int) -> Int {
        let a = Array(a0.utf16), b = Array(b0.utf16)
        let m = a.count, n = b.count
        if abs(m - n) > max { return max + 1 }
        var p2: [Int]? = nil
        var p1 = Array(0...n), cu = Array(repeating: 0, count: n + 1)
        if m == 0 { return p1[n] }
        for i in 1...m {
            cu[0] = i
            var best = i
            if n > 0 {
                for j in 1...n {
                    let c = a[i - 1] == b[j - 1] ? 0 : 1
                    var v = Swift.min(cu[j - 1] + 1, p1[j] + 1, p1[j - 1] + c)
                    if let p2, i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] { v = Swift.min(v, p2[j - 2] + 1) }
                    cu[j] = v
                    if v < best { best = v }
                }
            }
            if best > max { return max + 1 }
            let t = p2
            p2 = p1; p1 = cu
            cu = t ?? Array(repeating: 0, count: n + 1)
        }
        return p1[n]
    }
    static let vocMin = 4
    static let rxNonWord = JSRegExp("[^a-z0-9]+")
    /// `libVocab(items, extra)` : le vocabulaire de VOTRE bibliothèque (titres, codes, discriminants,
    /// noms de catégorie fournis), mots de 4 lettres et plus, dans l'ordre de première rencontre.
    public static func libVocab(_ items: [(title: String, code: String, discriminant: String)], extra: [String] = []) -> [String] {
        var seen = Set<String>(), out: [String] = []
        func manger(_ v: String) {
            for w in rxNonWord.split(Txt.txNorm(v)) where JS.length(w) >= vocMin && !seen.contains(w) { seen.insert(w); out.append(w) }
        }
        for x in items { manger(x.title); manger(x.code); manger(x.discriminant) }
        for v in extra { manger(v) }
        return out
    }
    /// `spellFix(q, vocab)` : la requête CORRIGÉE, ou nil s'il n'y a rien à corriger. Budget : 1
    /// édition jusqu'à 5 lettres, 2 jusqu'à 8, 3 au-delà ; égalité → ordre alphabétique ; un
    /// fragment d'un mot du vocabulaire n'est jamais corrigé (frappe en cours).
    public static func spellFix(_ q: String, vocab: [String]) -> String? {
        let T = qTerms(q)
        if T.isEmpty || vocab.isEmpty { return nil }
        var touche = false
        let out = T.map { t -> String in
            let tl = JS.length(t)
            if tl < vocMin { return t }
            if vocab.contains(where: { JS.includes($0, t) }) { return t }
            let mx = tl <= 5 ? 1 : (tl <= 8 ? 2 : 3)
            var best: String? = nil, bd = mx + 1
            for w in vocab {
                let d = dlev(t, w, mx)
                if d < bd || (d == bd && best != nil && Array(w.utf16).lexicographicallyPrecedes(Array(best!.utf16))) { bd = d; best = w }
            }
            if let b = best, bd <= mx { touche = true; return b }
            return t
        }
        return touche ? out.joined(separator: " ") : nil
    }

    // MARK: « Révisée depuis votre dernier passage »

    /// Session vue par `revisedSinceTxt` : l'aide, la révision (`aidRev` = `updatedAt` au départ)
    /// et l'heure de départ.
    public struct SessionStamp: Equatable, Sendable {
        public var ficheId: String, aidRev: Double, startedAt: Double
        public init(ficheId: String, aidRev: Double, startedAt: Double) { self.ficheId = ficheId; self.aidRev = aidRev; self.startedAt = startedAt }
    }
    /// `revisedSinceTxt(f, sessions)` : « révisée depuis votre dernier passage (jj/mm/aaaa) » ou ''.
    public static func revisedSinceTxt(_ f: Fiche, sessions: [SessionStamp], tz: TimeZone = .current) -> String {
        if f.updatedAt == 0 { return "" }
        var last: SessionStamp? = nil
        for x in sessions where x.ficheId == f.id && x.aidRev != 0 {
            if last == nil || x.startedAt > last!.startedAt { last = x }
        }
        guard let l = last, l.aidRev < f.updatedAt else { return "" }
        return "révisée depuis votre dernier passage (" + Txt.frDate(l.startedAt != 0 ? l.startedAt : l.aidRev, tz: tz) + ")"
    }
}
