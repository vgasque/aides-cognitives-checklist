import Foundation

// PARTAGE DE SESSION — primitives « à la JavaScript » propres au partage.
//
// Le partage est un PROTOCOLE partagé avec le client web : un octet de travers et l'invité natif
// d'un hôte web (ou l'inverse) lit un autre état que celui de l'écran d'en face. On recopie donc
// ici, à l'identique, les idiomes JS dont dépendent les fonctions pures de la PWA (`+v||0`,
// `_fnum`, `_ets`, `Date.parse`, `toISOString`, `crypto.subtle.digest('SHA-256')`, `Share._uuid`).
// Tout est pur Foundation : le module compile et se teste sous Linux (ni CryptoKit ni Compression).

public enum ShareJS {
    /// `+v || 0` — coercition numérique JS, NaN et ±0 ramenés à 0.
    public static func num0(_ v: JSON?) -> Double {
        let n = JS.number(v)
        return (n.isNaN || n == 0) ? 0 : n
    }
    /// `!!v`
    public static func truthy(_ v: JSON?) -> Bool { v?.truthy ?? false }

    /// `_fnum(v, def)` : nombre fini, sinon `def || 0`.
    ///
    /// ⚠ ÉCART DÉLIBÉRÉ (spec E § 7.1 / § 20.10) : quand `def` est l'heure ISO d'un évènement
    /// (`e.ts`), la PWA rend… la CHAÎNE elle-même (`def||0`). Le natif la convertit en
    /// millisecondes (`Date.parse`) : un horodatage reste un nombre, ce que tous les lecteurs
    /// (tri du journal, compte rendu) attendent. Sur le fil rien ne change : ce champ n'est
    /// jamais ré-émis tel quel.
    public static func fnum(_ v: JSON?, _ def: JSON?) -> Double {
        let n = JS.number(v)
        if n.isFinite { return n }
        guard let def else { return 0 }
        switch def {
        case .number(let d): return d.isFinite ? d : 0
        case .string(let s): return isoMs(s) ?? 0
        default: return def.truthy ? JS.number(def).nanToZero : 0
        }
    }
    /// `_ets(e)` : heure d'un évènement (nombre, ou ISO), 0 si absente.
    public static func eventTimeMs(_ e: JSON) -> Double {
        switch e["ts"] {
        case .number(let n)?: return n.isFinite ? n : 0
        case .string(let s)?: return isoMs(s) ?? 0
        default: return 0
        }
    }

    // MARK: Dates ISO-8601 (Date.parse / toISOString)

    /// `Date.parse` restreint à ce que produisent le serveur (jsonb timestamptz :
    /// `2026-09-30T12:34:57.012345+00:00`) et les navigateurs (`…T12:34:56.789Z`) : 0 à 9
    /// décimales (tronquées à la milliseconde comme V8), `Z`, `±HH:MM`, `±HHMM` ou `±HH`.
    /// Une date-heure SANS décalage est lue en UTC (le JS la lirait en heure locale — aucun
    /// émetteur du protocole n'en produit).
    public static func isoMs(_ s: String) -> Double? {
        let u = Array(s.utf8)
        var i = 0
        func digits(_ n: Int) -> Int? {
            guard i + n <= u.count else { return nil }
            var v = 0
            for k in 0..<n { let c = u[i + k]; guard c >= 48, c <= 57 else { return nil }; v = v * 10 + Int(c - 48) }
            i += n; return v
        }
        func eat(_ c: UInt8) -> Bool { if i < u.count, u[i] == c { i += 1; return true }; return false }
        var sign = 1
        var year: Int
        if eat(43) { guard let y = digits(6) else { return nil }; year = y }
        else if eat(45) { guard let y = digits(6) else { return nil }; year = y; sign = -1 }
        else { guard let y = digits(4) else { return nil }; year = y }
        year *= sign
        guard eat(45), let mo = digits(2), eat(45), let d = digits(2), mo >= 1, mo <= 12, d >= 1, d <= 31 else { return nil }
        var h = 0, mi = 0, se = 0, ms = 0.0, off = 0
        if i < u.count {
            guard eat(84) || eat(116) || eat(32), let hh = digits(2), eat(58), let mm = digits(2) else { return nil }
            h = hh; mi = mm
            if eat(58) {
                guard let ss = digits(2) else { return nil }
                se = ss
                if eat(46) || eat(44) {
                    var frac = "", n = 0
                    while i < u.count, u[i] >= 48, u[i] <= 57 { if n < 3 { frac.append(Character(UnicodeScalar(u[i]))) }; n += 1; i += 1 }
                    guard n > 0 else { return nil }
                    while frac.count < 3 { frac += "0" }
                    ms = Double(Int(frac)!)
                }
            }
            if i < u.count {
                if eat(90) || eat(122) { off = 0 }
                else {
                    let neg: Bool
                    if eat(43) { neg = false } else if eat(45) { neg = true } else { return nil }
                    guard let oh = digits(2) else { return nil }
                    var om = 0
                    if eat(58) { guard let m = digits(2) else { return nil }; om = m }
                    else if i < u.count { guard let m = digits(2) else { return nil }; om = m }
                    off = (oh * 60 + om) * (neg ? -1 : 1)
                }
            }
            guard i == u.count, h <= 24, mi <= 59, se <= 59 else { return nil }
        }
        let days = daysFromCivil(year, mo, d)
        let secs = Double(days) * 86400 + Double(h * 3600 + mi * 60 + se) - Double(off * 60)
        return secs * 1000 + ms
    }

    /// `new Date(ms).toISOString()` — « AAAA-MM-JJTHH:MM:SS.sssZ ».
    public static func isoString(_ ms: Double) -> String {
        let t = ms.rounded(.down)
        var days = Int((t / 86_400_000).rounded(.down))
        var rem = Int(t - Double(days) * 86_400_000)
        if rem < 0 { rem += 86_400_000; days -= 1 }
        let (y, m, d) = civilFromDays(days)
        let hh = rem / 3_600_000, mm = (rem / 60_000) % 60, ss = (rem / 1000) % 60, mss = rem % 1000
        func p(_ v: Int, _ n: Int) -> String { let s = String(v); return String(repeating: "0", count: max(0, n - s.count)) + s }
        let ys = (y >= 0 && y <= 9999) ? p(y, 4) : ((y < 0 ? "-" : "+") + p(abs(y), 6))
        return "\(ys)-\(p(m, 2))-\(p(d, 2))T\(p(hh, 2)):\(p(mm, 2)):\(p(ss, 2)).\(p(mss, 3))Z"
    }

    // Algorithmes de H. Hinnant (calendrier grégorien proleptique, comme ECMAScript).
    static func daysFromCivil(_ y0: Int, _ m: Int, _ d: Int) -> Int {
        let y = m <= 2 ? y0 - 1 : y0
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146097 + doe - 719468
    }
    static func civilFromDays(_ z0: Int) -> (Int, Int, Int) {
        let z = z0 + 719468
        let era = (z >= 0 ? z : z - 146096) / 146097
        let doe = z - era * 146097
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
        let y = yoe + era * 400
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp + (mp < 10 ? 3 : -9)
        return (m <= 2 ? y + 1 : y, m, d)
    }

    // MARK: Tri et chaînes « JS »

    /// `Array.prototype.sort()` sans comparateur : ordre des UNITÉS UTF-16.
    public static func jsSorted(_ a: [String]) -> [String] {
        a.sorted { x, y in x.utf16.lexicographicallyPrecedes(y.utf16) }
    }

    /// Hexadécimal minuscule.
    public static func hex(_ bytes: [UInt8]) -> String {
        let d = Array("0123456789abcdef".utf8)
        var o = [UInt8](); o.reserveCapacity(bytes.count * 2)
        for b in bytes { o.append(d[Int(b >> 4)]); o.append(d[Int(b & 15)]) }
        return String(decoding: o, as: UTF8.self)
    }

    /// base64url sans remplissage (`btoa` puis `+`→`-`, `/`→`_`, `=` retirés).
    public static func base64url(_ bytes: [UInt8]) -> String {
        Data(bytes).base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    /// Inverse de `base64url` ; nil si l'alphabet est violé (`atob` lèverait).
    public static func base64urlDecode(_ s: String) -> [UInt8]? {
        var t = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while t.utf8.count % 4 != 0 { t += "=" }
        guard let d = Data(base64Encoded: t) else { return nil }
        return [UInt8](d)
    }

    // MARK: Aléa

    /// Octets aléatoires cryptographiques (`crypto.getRandomValues`).
    public static func randomBytes(_ n: Int) -> [UInt8] {
        var g = SystemRandomNumberGenerator()
        return (0..<n).map { _ in UInt8.random(in: 0...255, using: &g) }
    }
    /// `Share._uuid()` : UUID v4 en minuscules — le serveur caste `event_id` en `uuid` et refuse
    /// TOUT le lot sur une valeur non conforme (`err:'refused'`).
    public static func uuidV4(_ bytes: [UInt8]? = nil) -> String {
        var b = bytes ?? randomBytes(16)
        b[6] = (b[6] & 0x0f) | 0x40
        b[8] = (b[8] & 0x3f) | 0x80
        let h = hex(b)
        let c = Array(h)
        return String(c[0..<8]) + "-" + String(c[8..<12]) + "-" + String(c[12..<16]) + "-" + String(c[16..<20]) + "-" + String(c[20..<32])
    }
    /// `SHARE_ALPHA`/`uid` n'ont rien à voir ici : identifiant de participant du hub (`uid('p')`)
    /// et de partage local (`uid('shl')`) reprennent `Guard.uid`.
}

extension Double {
    var nanToZero: Double { isNaN ? 0 : self }
}

// MARK: - SHA-256 (FIPS 180-4), pur Swift

/// SHA-256 — empreinte du FLUX reçu (`_streamHash`, comparée à celle que `share_pull` calcule en
/// PL/pgSQL) et préfixe `h4` des trames optiques. Même entrée, même algorithme : aucune variante
/// maison à tenir synchronisée.
public enum ShareSHA256 {
    static let k: [UInt32] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2]

    public static func digest(_ input: [UInt8]) -> [UInt8] {
        var h: [UInt32] = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]
        var msg = input
        let bitLen = UInt64(input.count) &* 8
        msg.append(0x80)
        while msg.count % 64 != 56 { msg.append(0) }
        for s in stride(from: 56, through: 0, by: -8) { msg.append(UInt8((bitLen >> UInt64(s)) & 0xff)) }
        var w = [UInt32](repeating: 0, count: 64)
        @inline(__always) func rotr(_ x: UInt32, _ n: UInt32) -> UInt32 { (x >> n) | (x << (32 - n)) }
        for chunk in stride(from: 0, to: msg.count, by: 64) {
            for t in 0..<16 {
                let j = chunk + t * 4
                w[t] = UInt32(msg[j]) << 24 | UInt32(msg[j + 1]) << 16 | UInt32(msg[j + 2]) << 8 | UInt32(msg[j + 3])
            }
            for t in 16..<64 {
                let s0 = rotr(w[t - 15], 7) ^ rotr(w[t - 15], 18) ^ (w[t - 15] >> 3)
                let s1 = rotr(w[t - 2], 17) ^ rotr(w[t - 2], 19) ^ (w[t - 2] >> 10)
                w[t] = w[t - 16] &+ s0 &+ w[t - 7] &+ s1
            }
            var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7]
            for t in 0..<64 {
                let S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)
                let ch = (e & f) ^ (~e & g)
                let t1 = hh &+ S1 &+ ch &+ k[t] &+ w[t]
                let S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                let t2 = S0 &+ maj
                hh = g; g = f; f = e; e = d &+ t1; d = c; c = b; b = a; a = t1 &+ t2
            }
            h[0] = h[0] &+ a; h[1] = h[1] &+ b; h[2] = h[2] &+ c; h[3] = h[3] &+ d
            h[4] = h[4] &+ e; h[5] = h[5] &+ f; h[6] = h[6] &+ g; h[7] = h[7] &+ hh
        }
        var out = [UInt8](); out.reserveCapacity(32)
        for v in h { out += [UInt8(v >> 24), UInt8((v >> 16) & 0xff), UInt8((v >> 8) & 0xff), UInt8(v & 0xff)] }
        return out
    }
    /// `hexDigest(str)` — SHA-256 de la chaîne en UTF-8, hexadécimal minuscule.
    public static func hex(_ s: String) -> String { ShareJS.hex(digest(Array(s.utf8))) }
}
