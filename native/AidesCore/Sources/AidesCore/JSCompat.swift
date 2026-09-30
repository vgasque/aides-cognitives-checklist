import Foundation

/// Primitives qui reproduisent À L'IDENTIQUE la sémantique JavaScript utilisée par la PWA.
///
/// La parité n'est pas cosmétique : le web et le natif partagent la même bibliothèque (import,
/// synchro, partage). Si `sstr` tronquait en graphèmes ici et en unités UTF-16 là-bas, une même
/// fiche aurait deux titres selon l'appareil. Tout est donc calqué sur le comportement JS :
/// longueur en unités UTF-16, `Math.round` (demi vers +∞), `Number()`, `String.prototype.trim`.
public enum JS {
    /// `Date.now()` — millisecondes depuis l'époque Unix.
    public static func now() -> Double { (Date().timeIntervalSince1970 * 1000).rounded(.down) }

    /// `Math.round` : arrondi du demi vers +∞ (Math.round(-1.5) === -1).
    public static func round(_ x: Double) -> Double { (x + 0.5).rounded(.down) }

    /// `Number(v)` pour une valeur JSON.
    public static func number(_ v: JSON?) -> Double {
        guard let v else { return .nan }          // undefined
        switch v {
        case .null: return 0
        case .bool(let b): return b ? 1 : 0
        case .number(let n): return n
        case .string(let s): return number(string: s)
        case .array(let a):
            if a.isEmpty { return 0 }
            if a.count == 1 { return number(string: a[0].isNull ? "" : a[0].jsString) }
            return .nan
        case .object: return .nan
        }
    }
    static func number(string s: String) -> Double {
        let t = trim(s)
        if t.isEmpty { return 0 }
        let lower = t.lowercased()
        if lower.hasPrefix("0x"), let v = UInt64(t.dropFirst(2), radix: 16) { return Double(v) }
        if lower.hasPrefix("0b"), let v = UInt64(t.dropFirst(2), radix: 2) { return Double(v) }
        if lower.hasPrefix("0o"), let v = UInt64(t.dropFirst(2), radix: 8) { return Double(v) }
        if t == "Infinity" || t == "+Infinity" { return .infinity }
        if t == "-Infinity" { return -.infinity }
        // Grammaire décimale JS stricte (Double(String) accepterait « nan », « inf »…).
        let allowed = Set("0123456789+-.eE")
        guard t.allSatisfy({ allowed.contains($0) }), let d = Double(t) else { return .nan }
        return d
    }

    /// `Math.round(Number(v)) || 0` — idiome omniprésent de l'assainissement.
    public static func roundedOrZero(_ v: JSON?) -> Double {
        let r = round(number(v))
        return (r.isNaN || r == 0) ? 0 : r
    }
    public static func clamp(_ x: Double, _ lo: Double, _ hi: Double) -> Double { max(lo, min(hi, x)) }

    /// `\s` de JavaScript (espaces + fins de ligne Unicode, BOM compris).
    public static func isSpace(_ u: Unicode.Scalar) -> Bool {
        switch u.value {
        case 0x09...0x0D, 0x20, 0xA0, 0x1680, 0x2000...0x200A, 0x2028, 0x2029, 0x202F, 0x205F, 0x3000, 0xFEFF: return true
        default: return false
        }
    }
    /// `String.prototype.trim()`.
    public static func trim(_ s: String) -> String {
        let sc = s.unicodeScalars
        guard let a = sc.firstIndex(where: { !isSpace($0) }) else { return "" }
        let b = sc.lastIndex(where: { !isSpace($0) })!
        return String(sc[a...b])
    }
    /// Retire les blancs de TÊTE (`/^\s*/`).
    public static func trimStart(_ s: String) -> Substring.UnicodeScalarView {
        let sc = s.unicodeScalars
        guard let a = sc.firstIndex(where: { !isSpace($0) }) else { return sc[sc.endIndex...] }
        return sc[a...]
    }

    /// Longueur JS (unités UTF-16).
    public static func length(_ s: String) -> Int { s.utf16.count }

    /// `s.slice(0, max)` en unités UTF-16. Une paire de substitution coupée en deux est retirée
    /// ENTIÈRE (une chaîne Swift ne peut pas porter une moitié de paire) — seul écart, sans effet
    /// pratique : le JS garderait un demi-caractère illisible.
    public static func prefix(_ s: String, _ max: Int) -> String {
        if s.utf16.count <= max { return s }
        let u = s.utf16
        var end = u.index(u.startIndex, offsetBy: max)
        if end > u.startIndex, UTF16.isLeadSurrogate(u[u.index(before: end)]) { end = u.index(before: end) }
        return String(u[u.startIndex..<end]) ?? String(s.prefix(max))
    }
    /// `s.slice(a, b)` en unités UTF-16 (bornes positives).
    public static func slice(_ s: String, _ a: Int, _ b: Int? = nil) -> String {
        let u = Array(s.utf16)
        let lo = min(max(0, a), u.count), hi = min(max(lo, b ?? u.count), u.count)
        return String(decoding: u[lo..<hi], as: UTF16.self)
    }

    /// `x.toString(36)` pour un entier positif.
    public static func base36(_ v: UInt64) -> String { String(v, radix: 36) }
}

// MARK: - Garde-fous de la PWA (section « Garde-fous de sécurité »)

public enum Guard {
    public static let badKeys: Set<String> = ["__proto__", "constructor", "prototype"]

    /// `SAFE_ID = /^[A-Za-z0-9_-]{1,64}$/` + clés bannies.
    public static func isSafeId(_ s: String) -> Bool {
        let n = s.utf8.count
        guard n >= 1, n <= 64, !badKeys.contains(s) else { return false }
        return s.utf8.allSatisfy { c in
            (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 || c == 45
        }
    }
    /// `SAFE_ID.test(x)` seul (sans la liste noire) — utilisé tel quel par quelques sites.
    public static func matchesSafeIdPattern(_ s: String) -> Bool {
        let n = s.utf8.count
        guard n >= 1, n <= 64 else { return false }
        return s.utf8.allSatisfy { c in
            (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 || c == 45
        }
    }

    /// Générateur d'identifiants — port de `uid(p)` : préfixe + horodatage base 36 + 8 caractères
    /// aléatoires. La clé primaire du cloud est GLOBALE (tous comptes) : l'aléa est indispensable.
    public static func uid(_ prefix: String? = nil) -> String {
        var g = SystemRandomNumberGenerator()
        let r = JS.base36(UInt64(UInt32.random(in: 0...UInt32.max, using: &g))) + JS.base36(UInt64(UInt32.random(in: 0...UInt32.max, using: &g)))
        let p = (prefix?.isEmpty == false) ? prefix! : "f"
        return p + JS.base36(UInt64(JS.now())) + String((r + "00000000").prefix(8))
    }

    /// `safeId(id, p)` : l'id s'il est sûr, sinon un NOUVEL id.
    public static func safeId(_ v: JSON?, _ prefix: String? = nil) -> String {
        if case .string(let s)? = v, isSafeId(s) { return s }
        return uid(prefix)
    }
    /// `safeCatRef` : une RÉFÉRENCE n'est jamais inventée — invalide devient ''.
    public static func safeRef(_ v: JSON?) -> String {
        if case .string(let s)? = v, isSafeId(s) { return s }
        return ""
    }
    /// `safeMetaId` : identifiant de synchronisation — invalide devient nil.
    public static func safeMetaId(_ v: JSON?) -> String? {
        if case .string(let s)? = v, isSafeId(s) { return s }
        return nil
    }
    public static let defaultColor = "#45556b"
    /// `safeColor` : `/^#[0-9a-fA-F]{3,8}$/`, sinon la couleur par défaut.
    public static func safeColor(_ v: JSON?) -> String {
        if case .string(let s)? = v, isHexColor(s) { return s }
        return defaultColor
    }
    public static func isHexColor(_ s: String) -> Bool {
        let u = Array(s.utf8)
        guard u.count >= 4, u.count <= 9, u[0] == 35 else { return false }
        return u.dropFirst().allSatisfy { c in (c >= 48 && c <= 57) || (c >= 65 && c <= 70) || (c >= 97 && c <= 102) }
    }
    /// `safeImg` : seules les data-URI d'image base64 reconnues passent.
    /// `/^data:image\/(png|jpe?g|gif|webp);base64,[A-Za-z0-9+/=\s]{0,6000000}$/i`
    public static func safeImg(_ v: JSON?) -> String? {
        guard case .string(let s)? = v else { return nil }
        let lower = s.prefix(40).lowercased()
        var head = 0
        for p in ["data:image/png;base64,", "data:image/jpeg;base64,", "data:image/jpg;base64,", "data:image/gif;base64,", "data:image/webp;base64,"] where lower.hasPrefix(p) {
            head = p.count; break
        }
        guard head > 0 else { return nil }
        let body = s.unicodeScalars.dropFirst(head)
        var n = 0
        for c in body {
            n += c.utf16.count
            if n > 6_000_000 { return nil }
            let v = c.value
            let ok = (v >= 48 && v <= 57) || (v >= 65 && v <= 90) || (v >= 97 && v <= 122) || v == 43 || v == 47 || v == 61 || JS.isSpace(c)
            if !ok { return nil }
        }
        return s
    }
    /// `sstr(v, max)` : coercition en chaîne puis troncature (défaut 5000).
    public static func sstr(_ v: JSON?, _ max: Int = 5000) -> String {
        guard let v, !v.isNull else { return "" }
        return JS.prefix(v.jsString, max)
    }
    /// `sarr(a, max)` : tableau de chaînes bornées (4000 car. chacune).
    public static func sarr(_ v: JSON?, _ max: Int = 1000) -> [String] {
        guard case .array(let a)? = v else { return [] }
        return a.prefix(max).map { sstr($0, 4000) }
    }

    public static let maxPdfBytes = 15 * 1024 * 1024
    public static let maxAttPerEntity = 10
    public static let maxImgBytes = 25 * 1024 * 1024
    public static let maxImportBytes = 40 * 1024 * 1024
    public static let maxImgPerEntity = 60

    /// `safeFileName` : borné, sans séparateur de chemin ni caractère de contrôle.
    public static func safeFileName(_ v: JSON?) -> String {
        let s = sstr(v, 150)
        let cleaned = String(String.UnicodeScalarView(s.unicodeScalars.filter { c in
            !(c == "/" || c == "\\" || c.value <= 0x1f || c.value == 0x7f)
        }))
        return JS.trim(cleaned)
    }
    /// `attDlName` : nom de fichier téléchargé, extension .pdf garantie une fois.
    public static func attDownloadName(_ n: String) -> String {
        var s = safeFileName(.string(n))
        if s.lowercased().hasSuffix(".pdf") { s = String(s.dropLast(4)) }
        s = JS.trim(s)
        return (s.isEmpty ? "document" : s) + ".pdf"
    }
    /// Signature réelle d'un PDF (« %PDF- »).
    public static func isPdf(_ d: Data) -> Bool {
        let p = [UInt8](d.prefix(5))
        return p == [0x25, 0x50, 0x44, 0x46, 0x2d]
    }
    /// `imgKind` : format d'image reconnu par sa SIGNATURE (HEIC compris, SVG exclu).
    public static func imageKind(_ d: Data) -> String? {
        let u = [UInt8](d.prefix(16))
        func at(_ off: Int, _ b: [UInt8]) -> Bool { u.count >= off + b.count && Array(u[off..<(off + b.count)]) == b }
        if at(0, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) { return "png" }
        if at(0, [0xFF, 0xD8, 0xFF]) { return "jpeg" }
        if at(0, Array("RIFF".utf8)) && at(8, Array("WEBP".utf8)) { return "webp" }
        if at(0, Array("GIF87a".utf8)) || at(0, Array("GIF89a".utf8)) { return "gif" }
        if at(4, Array("ftyp".utf8)), u.count >= 12 {
            let m = String(decoding: u[8..<12], as: UTF8.self)
            if ["heic", "heix", "heim", "heis", "hevc", "hevx", "mif1", "msf1"].contains(m) { return "heic" }
        }
        return nil
    }
    /// `dataKind` : .zip par signature, .json par sa tête (`{`, `[` ou clôture de code).
    public static func dataKind(_ d: Data) -> String? {
        let u = [UInt8](d.prefix(64))
        if u.count >= 4, u[0] == 0x50, u[1] == 0x4B, u[2] == 3, u[3] == 4 { return "zip" }
        var i = (u.count >= 3 && u[0] == 0xEF && u[1] == 0xBB && u[2] == 0xBF) ? 3 : 0
        while i < u.count, u[i] <= 0x20 { i += 1 }
        guard i < u.count else { return nil }
        return (u[i] == 0x7B || u[i] == 0x5B || u[i] == 0x60) ? "json" : nil
    }

    /// `stripJsonFences` : tolère une réponse d'IA enrobée de ```json … ``` et un BOM.
    public static func stripJsonFences(_ s: String) -> String {
        var t = s
        if t.hasPrefix("\u{FEFF}") { t.removeFirst() }
        t = JS.trim(t)
        guard t.hasPrefix("```"), t.hasSuffix("```"), t.count >= 6 else { return t }
        var body = t.dropFirst(3).dropLast(3)
        // langue facultative [a-zA-Z0-9-]*
        while let c = body.first, c.isASCII, c.isLetter || c.isNumber || c == "-" { body = body.dropFirst() }
        return JS.trim(String(body))
    }
}

// MARK: - Date de validation « AAAA-MM »

public enum Validation {
    static let months: [[String]] = [["janvier", "janv", "jan"], ["février", "fevrier", "févr", "fevr", "fév", "fev"], ["mars", "mar"], ["avril", "avr"], ["mai"], ["juin"], ["juillet", "juil", "jul"], ["août", "aout", "aoû", "aou"], ["septembre", "sept", "sep"], ["octobre", "octo", "oct"], ["novembre", "nove", "nov"], ["décembre", "decembre", "déc", "dec"]]

    static func monthFromName(_ s: String) -> Int {
        let l = s.lowercased()
        for i in 0..<12 { for a in months[i] where l.contains(a) { return i + 1 } }
        return 0
    }
    /// Suites de chiffres ASCII (`/\d{1,max}/g`, le `\d` JS n'est QUE l'ASCII).
    static func digitRuns(_ s: String, max: Int) -> [String] {
        var out: [String] = []
        var cur = ""
        for c in s.unicodeScalars {
            if c.value >= 48 && c.value <= 57 {
                cur.unicodeScalars.append(c)
                if cur.count == max { out.append(cur); cur = "" }
            } else if !cur.isEmpty { out.append(cur); cur = "" }
        }
        if !cur.isEmpty { out.append(cur) }
        return out
    }
    static func pad2(_ m: Int) -> String { m < 10 ? "0\(m)" : "\(m)" }

    /// Port exact de `parseValidation` : tolérant en entrée, TOUJOURS « AAAA-MM » ou ''.
    public static func parse(_ v: JSON?) -> String {
        let raw: String
        if let v, !v.isNull { raw = v.jsString } else { raw = "" }
        let s = JS.trim(raw)
        if s.isEmpty { return "" }
        let u = Array(s.unicodeScalars)
        let isDigit: (Unicode.Scalar) -> Bool = { $0.value >= 48 && $0.value <= 57 }
        if u.count == 7, u[0...3].allSatisfy(isDigit), u[4] == "-", let m = Int(String(String.UnicodeScalarView(u[5...6]))),
           u[5...6].allSatisfy(isDigit), m >= 1, m <= 12 { return s }
        if u.count == 6, u.allSatisfy(isDigit) {
            let y1 = Int(String(s.prefix(4)))!, m1 = Int(String(s.suffix(2)))!
            let y2 = Int(String(s.suffix(4)))!, m2 = Int(String(s.prefix(2)))!
            if y1 >= 1900, y1 <= 2999, m1 >= 1, m1 <= 12 { return "\(y1)-\(pad2(m1))" }
            if y2 >= 1900, y2 <= 2999, m2 >= 1, m2 <= 12 { return "\(y2)-\(pad2(m2))" }
            return ""
        }
        var mo = monthFromName(s)
        var y = 0
        // /(?:19|20|21)\d{2}/ — première occurrence
        if u.count >= 4 {
            for i in 0...(u.count - 4) {
                let a = u[i], b = u[i + 1]
                if (a == "1" && b == "9") || (a == "2" && (b == "0" || b == "1")), isDigit(u[i + 2]), isDigit(u[i + 3]) {
                    y = Int(String(String.UnicodeScalarView(u[i...(i + 3)])))!; break
                }
            }
        }
        if mo == 0 {
            for n in digitRuns(s, max: 4) where n.count <= 2 {
                let v = Int(n)!
                if v >= 1, v <= 12 { mo = v; break }
            }
        }
        if y == 0 {
            let two = digitRuns(s, max: 2).map { Int($0)! }
            var c = two.first(where: { $0 > 12 })
            if c == nil, mo != 0 { c = two.first(where: { $0 != mo }) }
            if let c { y = 2000 + c }
        }
        return (mo >= 1 && mo <= 12 && y >= 1900 && y <= 2999) ? "\(y)-\(pad2(mo))" : ""
    }
    /// « AAAA-MM » → « MM/AAAA » pour l'affichage.
    public static func display(_ v: String) -> String {
        let p = v.split(separator: "-")
        guard p.count == 2, p[0].count == 4, p[1].count == 2 else { return "" }
        return "\(p[1])/\(p[0])"
    }
}
