import Foundation

/// Dates « à la JavaScript » : `Date.parse` (sous-ensemble ISO-8601) et `toISOString()`.
///
/// La synchro compare des horodatages du SERVEUR (`updated_at`, rendu par PostgREST sous la forme
/// `2026-09-30T08:56:13.046123+00:00`) à des horodatages LOCAUX en millisecondes depuis l'époque, et
/// renvoie au serveur des chaînes `toISOString()` (`2026-09-30T08:56:13.046Z`). Un écart d'une
/// milliseconde entre le web et le natif suffirait à faire « gagner » une version que l'autre
/// client jugerait égale — d'où un port arithmétique exact plutôt qu'un `ISO8601DateFormatter`
/// (qui arrondit les fractions et refuse les microsecondes selon les plateformes).
public enum JSDate {
    /// `new Date(ms).toISOString()` : UTC, millisecondes, « Z ». Le temps est TRONQUÉ vers zéro
    /// (TimeClip), comme en JS. Années hors 0…9999 : forme étendue ±YYYYYY.
    public static func iso(_ msIn: Double) -> String {
        let ms = Int64(msIn.rounded(.towardZero))
        var days = ms / 86_400_000
        var rem = ms % 86_400_000
        if rem < 0 { rem += 86_400_000; days -= 1 }
        let (y, m, d) = civil(fromDays: days)
        let h = rem / 3_600_000, mi = (rem / 60_000) % 60, s = (rem / 1000) % 60, milli = rem % 1000
        let year: String
        if y >= 0 && y <= 9999 { year = pad(y, 4) } else { year = (y < 0 ? "-" : "+") + pad(abs(y), 6) }
        return "\(year)-\(pad(m, 2))-\(pad(d, 2))T\(pad(h, 2)):\(pad(mi, 2)):\(pad(s, 2)).\(pad(milli, 3))Z"
    }

    /// `Date.parse(s)` pour les formes ISO que produisent PostgREST, Postgres et `toISOString` :
    /// `YYYY[-MM[-DD]]`, puis `T` (ou espace) `HH:MM[:SS[.fraction]]`, puis `Z`, `±HH:MM`, `±HHMM`
    /// ou `±HH`. Fraction : les chiffres au-delà de la milliseconde sont IGNORÉS (V8 tronque).
    /// Une date-heure SANS décalage est lue en UTC (JS la lirait en heure locale : le serveur ne
    /// produit jamais cette forme). nil = `NaN`.
    public static func parse(_ sIn: String) -> Double? {
        let s = Array(JS.trim(sIn).utf8)
        var i = 0
        func digits(_ n: Int) -> Int64? {
            guard i + n <= s.count else { return nil }
            var v: Int64 = 0
            for k in 0..<n {
                let c = s[i + k]
                guard c >= 48 && c <= 57 else { return nil }
                v = v * 10 + Int64(c - 48)
            }
            i += n
            return v
        }
        func peek(_ c: Character) -> Bool { i < s.count && s[i] == c.asciiValue! }
        var sign: Int64 = 1
        var year: Int64
        if peek("+") || peek("-") {
            sign = peek("-") ? -1 : 1; i += 1
            guard let y = digits(6) else { return nil }
            year = sign * y
        } else {
            guard let y = digits(4) else { return nil }
            year = y
        }
        var month: Int64 = 1, day: Int64 = 1, hh: Int64 = 0, mm: Int64 = 0, ss: Int64 = 0, milli: Int64 = 0
        var offsetMin: Int64 = 0
        if peek("-") {
            i += 1; guard let m = digits(2) else { return nil }; month = m
            if peek("-") { i += 1; guard let d = digits(2) else { return nil }; day = d }
        }
        if i < s.count && (s[i] == 84 || s[i] == 116 || s[i] == 32) {   // T, t ou espace
            i += 1
            guard let h = digits(2), peek(":") else { return nil }
            i += 1
            guard let mi = digits(2) else { return nil }
            hh = h; mm = mi
            if peek(":") {
                i += 1; guard let se = digits(2) else { return nil }; ss = se
                if peek(".") || peek(",") {
                    i += 1
                    var n = 0; var frac: Int64 = 0
                    while i < s.count, s[i] >= 48, s[i] <= 57 {
                        if n < 3 { frac = frac * 10 + Int64(s[i] - 48) }
                        n += 1; i += 1
                    }
                    guard n > 0 else { return nil }
                    while n < 3 { frac *= 10; n += 1 }
                    milli = frac
                }
            }
            if peek("Z") || peek("z") { i += 1 }
            else if peek("+") || peek("-") {
                let sg: Int64 = peek("-") ? -1 : 1; i += 1
                guard let oh = digits(2) else { return nil }
                var om: Int64 = 0
                if peek(":") { i += 1; guard let x = digits(2) else { return nil }; om = x }
                else if let x = digits(2) { om = x }
                guard oh <= 23, om <= 59 else { return nil }
                offsetMin = sg * (oh * 60 + om)
            }
        }
        guard i == s.count else { return nil }
        // V8 ne borne le jour qu'à 31 (« 2026-02-30 » roule au 2 mars) : même règle ici.
        guard month >= 1, month <= 12, day >= 1, day <= 31, hh <= 24, mm <= 59, ss <= 59 else { return nil }
        if hh == 24 && (mm != 0 || ss != 0 || milli != 0) { return nil }
        let days = daysFromCivil(year, month, day)
        let t = days * 86_400_000 + hh * 3_600_000 + mm * 60_000 + ss * 1000 + milli - offsetMin * 60_000
        return Double(t)
    }

    /// `Date.parse(x) || 0` appliqué à une valeur JSON (non-chaîne → 0).
    public static func parseOrZero(_ v: JSON?) -> Double {
        guard let s = v?.string, let t = parse(s) else { return 0 }
        return t == 0 ? 0 : t
    }

    // MARK: Calendrier grégorien proleptique (algorithmes de H. Hinnant)

    static func daysFromCivil(_ y0: Int64, _ m: Int64, _ d: Int64) -> Int64 {
        let y = m <= 2 ? y0 - 1 : y0
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (m + 9) % 12
        let doy = (153 * mp + 2) / 5 + d - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }
    static func civil(fromDays z0: Int64) -> (Int64, Int64, Int64) {
        let z = z0 + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365
        let y = yoe + era * 400
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        return (m <= 2 ? y + 1 : y, m, d)
    }
    static func pad(_ v: Int64, _ n: Int) -> String {
        let s = String(v)
        return s.count >= n ? s : String(repeating: "0", count: n - s.count) + s
    }
}
