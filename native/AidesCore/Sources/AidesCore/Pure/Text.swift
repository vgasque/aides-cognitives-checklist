import Foundation

// PETITS OUTILS DE TEXTE partagés par tous les portages « purs » — chacun recopie une fonction
// nommée de la PWA (`esc`, `stripBold`, `clean`, `txNorm`, `catSlug`, `fmtMs`, `fmtBytes`…).
// Ils vivent ici pour qu'il n'en existe qu'UNE copie native : deux rédactions d'un même format
// finiraient par diverger, exactement comme la PWA l'a payé (« une phrase, deux lecteurs »).

public enum Txt {
    // MARK: Échappement et gras

    /// `esc(s)` : & < > " ' → entités (le backtick reste, décision mesurée de la PWA — règle 4).
    public static func esc(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.utf8.count)
        for c in s.unicodeScalars {
            switch c {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&#39;"
            default: out.unicodeScalars.append(c)
            }
        }
        return out
    }
    /// Inverse d'`esc` (les cinq entités qu'il produit, et elles seules).
    public static func unesc(_ s: String) -> String {
        guard s.contains("&") else { return s }
        let u = Array(s.utf16)
        var out: [UInt16] = []
        out.reserveCapacity(u.count)
        let ents: [([UInt16], UInt16)] = [(Array("&amp;".utf16), 38), (Array("&lt;".utf16), 60), (Array("&gt;".utf16), 62),
                                          (Array("&quot;".utf16), 34), (Array("&#39;".utf16), 39)]
        var i = 0
        outer: while i < u.count {
            if u[i] == 38 {
                for (e, c) in ents where i + e.count <= u.count && Array(u[i..<(i + e.count)]) == e {
                    out.append(c); i += e.count; continue outer
                }
            }
            out.append(u[i]); i += 1
        }
        return JS.str(out)
    }

    /// `BOLD_RX = /\*\*([^*\n]+)\*\*/g`
    public static let boldRx = JSRegExp(#"\*\*([^*\n]+)\*\*"#, "g")
    /// `stripBold(s)` : retire les `**` du gras de saisie.
    public static func stripBold(_ s: String) -> String { boldRx.replace(s, "$1") }

    /// `clean(a)` : chaînes coupées de leurs blancs, vides retirées.
    public static func clean(_ a: [String]) -> [String] { a.map { JS.trim($0) }.filter { !$0.isEmpty } }

    // MARK: Normalisation de recherche

    static let combining = JSRegExp(#"[̀-ͯ]"#, "g")
    /// `txNorm(s)` : NFD, diacritiques combinants (U+0300–U+036F) retirés, minuscules — la même
    /// normalisation des deux côtés de toute recherche de l'app.
    public static func txNorm(_ s: String) -> String {
        if s.isEmpty { return "" }
        let d = JS.nfd(s)
        let stripped = String(String.UnicodeScalarView(d.unicodeScalars.filter { !($0.value >= 0x300 && $0.value <= 0x36F) }))
        return JS.toLowerCase(stripped)
    }

    static let nonAlnum = JSRegExp("[^a-z0-9]+", "g")
    static let edgeDash = JSRegExp("^-|-$", "g")
    /// `catSlug(name)` : identifiant déterministe dérivé d'un nom (48 caractères au plus).
    public static func catSlug(_ name: String) -> String {
        let n = JS.toLowerCase(String(String.UnicodeScalarView(JS.nfd(name).unicodeScalars.filter { !($0.value >= 0x300 && $0.value <= 0x36F) })))
        return JS.prefix(edgeDash.replace(nonAlnum.replace(n, "-"), ""), 48)
    }
    /// `detCatId(name)` : « c-<slug> », sinon un identifiant neuf (`uid('c')`).
    public static func detCatId(_ name: String) -> String {
        let s = catSlug(name)
        return s.isEmpty ? Guard.uid("c") : "c-" + s
    }

    // MARK: Durées, tailles, dates

    /// `fmtMs(ms)` : « mm:ss », « h:mm:ss » au-delà de l'heure.
    public static func fmtMs(_ ms: Double) -> String {
        if ms.isNaN { return "NaN:NaN" }                 // ce qu'écrit la PWA (Math.max(0, NaN) = NaN)
        if ms == .infinity { return "Infinity:NaN:NaN" }
        let t = max(0, (ms / 1000).rounded(.down))
        let h = Int((t / 3600).rounded(.down)), m = Int((t / 60).rounded(.down)) % 60, s = Int(t.truncatingRemainder(dividingBy: 60))
        let mm = (m < 10 ? "0" : "") + String(m), ss = (s < 10 ? "0" : "") + String(s)
        return h != 0 ? "\(h):\(mm):\(ss)" : "\(mm):\(ss)"
    }
    /// `sinceTxt(t, now)` : durée écoulée, bornée à zéro (une horloge qui recule n'invente rien).
    public static func sinceTxt(_ t: Double, now: Double) -> String { fmtMs(max(0, now - t)) }

    /// `fmtBytes(n)` : o / Ko / Mo / Go, virgule décimale française.
    public static func fmtBytes(_ n: Double) -> String {
        let v = n.isNaN ? 0 : n
        if v < 1024 { return JS.numStr(v) + " o" }
        if v < 1_048_576 { return JS.numStr(JS.round(v / 1024)) + " Ko" }
        if v < 1_073_741_824 { return JS.toFixed(v / 1_048_576, 1).replacingOccurrences(of: ".", with: ",") + " Mo" }
        return JS.toFixed(v / 1_073_741_824, 2).replacingOccurrences(of: ".", with: ",") + " Go"
    }

    /// `durTxt(s)` : une durée en mots, nombre et unité insécables (A391).
    public static func durTxt(_ s: Int) -> String {
        if s % 60 == 0 { return "\(s / 60)\u{a0}min" }
        if s < 60 { return "\(s)\u{a0}s" }
        return "\(s / 60)\u{a0}min \(s % 60)\u{a0}s"
    }
    /// `guil(n)` : guillemets qui ne se séparent pas de leur nom.
    public static func guil(_ n: String) -> String { "«\u{a0}" + n + "\u{a0}»" }

    /// Composantes calendaires d'un instant (ms) dans un fuseau — ce que `Date#getHours` & co.
    /// lisent dans le fuseau du navigateur. Le fuseau est un PARAMÈTRE : la PWA dépend du système.
    static func parts(_ ms: Double, _ tz: TimeZone) -> DateComponents {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        return cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date(timeIntervalSince1970: ms / 1000))
    }
    static func pad2(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }
    /// `toLocaleDateString('fr-FR')` → « jj/mm/aaaa ».
    public static func frDate(_ ms: Double, tz: TimeZone = .current) -> String {
        let p = parts(ms, tz)
        return "\(pad2(p.day!))/\(pad2(p.month!))/\(p.year!)"
    }
    /// `toLocaleTimeString('fr-FR',{hour:'2-digit',minute:'2-digit'})` → « HH:MM ».
    public static func frHM(_ ms: Double, tz: TimeZone = .current) -> String {
        let p = parts(ms, tz)
        return "\(pad2(p.hour!)):\(pad2(p.minute!))"
    }
    /// `fmtHMS(t)` → « HH:MM:SS ».
    public static func fmtHMS(_ ms: Double, tz: TimeZone = .current) -> String {
        let p = parts(ms, tz)
        return "\(pad2(p.hour!)):\(pad2(p.minute!)):\(pad2(p.second!))"
    }
    static let frMonths = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    /// `toLocaleDateString('fr-FR',{month:'long',year:'numeric'})` → « septembre 2026 ».
    public static func frMonthYear(_ ms: Double, tz: TimeZone = .current) -> String {
        let p = parts(ms, tz)
        return frMonths[p.month! - 1] + " " + String(p.year!)
    }
    /// `sessStamp(ms)` : « jj/mm/aaaa · HH:MM » (la seconde vit au compte rendu, pas dans une liste).
    public static func sessStamp(_ ms: Double, tz: TimeZone = .current) -> String {
        frDate(ms, tz: tz) + " · " + frHM(ms, tz: tz)
    }

    /// `staleDate(v)` : date de validation de plus de 730 jours (≈ 2 ans).
    /// `new Date('AAAA-MM-01')` est une date UTC en JS : on la lit en UTC.
    public static func staleDate(_ v: String, now: Double) -> Bool {
        if v.isEmpty { return false }
        let s = JS.length(v) == 7 ? v + "-01" : v
        guard let t = parseJSDate(s) else { return false }
        return (now - t) > 730 * 864e5
    }
    /// Sous-ensemble de `Date.parse` utile ici : « AAAA-MM-JJ » (UTC) et « AAAA-MM » ; le reste
    /// (formats libres que V8 accepte) n'est pas reconnu — il ne se présente pas : la date de
    /// validation est normalisée « AAAA-MM » par `parseValidation`.
    static let isoDate = JSRegExp(#"^(\d{4})-(\d{2})(?:-(\d{2}))?$"#)
    static func parseJSDate(_ s: String) -> Double? {
        guard let m = isoDate.exec(s), let y = Int(m[1]!), let mo = Int(m[2]!) else { return nil }
        let d = m[3].flatMap { Int($0) } ?? 1
        guard mo >= 1, mo <= 12, d >= 1, d <= 31 else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        var dc = DateComponents(); dc.year = y; dc.month = mo; dc.day = d
        guard let date = cal.date(from: dc), cal.component(.day, from: date) == d else { return nil }
        return date.timeIntervalSince1970 * 1000
    }

    // MARK: Heure saisie

    /// `tkParseTime(str)` : heure tapée sans deux-points (clavier numérique iOS) ; une valeur
    /// IMPOSSIBLE rend nil — jamais écrêtée (l'écrêtage fabriquerait une heure fausse).
    public static func tkParseTime(_ str: String) -> (h: Int, m: Int, s: Int)? {
        let t = JS.trim(str)
        if t.isEmpty { return nil }
        var h = 0, m = 0, s = 0
        let u = Array(t.utf16)
        let isD: (UInt16) -> Bool = { $0 >= 48 && $0 <= 57 }
        func pint(_ x: String) -> Int? { Int(x) }   // groupes de chiffres ASCII : parseInt exact
        if u.contains(where: { !isD($0) }) {
            let g = JSRegExp("[^0-9]+").split(t).filter { !$0.isEmpty }
            if g.isEmpty || g.count > 3 || g.contains(where: { JS.length($0) > 2 }) { return nil }
            h = pint(g[0])!; if g.count > 1 { m = pint(g[1])! }; if g.count > 2 { s = pint(g[2])! }
        } else {
            if u.count > 6 { return nil }
            if u.count <= 2 { h = pint(t)! }
            else if u.count <= 4 { h = pint(JS.slice(t, 0, u.count - 2))!; m = pint(JS.slice(t, u.count - 2))! }
            else { h = pint(JS.slice(t, 0, u.count - 4))!; m = pint(JS.slice(t, u.count - 4, u.count - 2))!; s = pint(JS.slice(t, u.count - 2))! }
        }
        guard h >= 0, h <= 23, m >= 0, m <= 59, s >= 0, s <= 59 else { return nil }
        return (h, m, s)
    }
}
