import Foundation

// COULEURS DE CATÉGORIE — port de `PALETTE`, `hexToOklch`, `catHueHex`, `catHueSnap`, `catHueDeg`,
// `dEok`, `catLisible`, `catRegNear`, `catSafeTwin` (anneau OKLCH ancré sur les presets, A308-A314 ;
// garde-fou « jamais plus proche d'un registre que deux catégories entre elles », A408).
//
// Les couleurs STOCKÉES ne changent jamais d'office (A314) : ces fonctions proposent, elles ne
// réécrivent rien. Le natif doit proposer LA MÊME teinte que le web au même degré — sinon deux
// appareils d'une même équipe verraient deux couleurs pour une catégorie nouvellement réglée.

public enum CatColor {
    /// `PALETTE` : les douze presets (WCAG AA en pastille comme en chip sélectionnée).
    public static let palette = ["#905a39", "#6f684a", "#4f6727", "#116b4c", "#226a71", "#1f6f96", "#45556b", "#0d5b56", "#5156b6", "#755a96", "#7a2f6b", "#95516c"]
    /// `CAT_REGS` : les couleurs de REGISTRE (rouge, ambre, vert) dont une catégorie doit s'écarter.
    public static let registers = ["#a32e1f", "#c43d34", "#7a5900", "#b45309", "#1d7a38"]
    /// `CAT_OLD` : anciens presets → leur remplaçant sûr.
    public static let oldPresets = ["#b23240": "#7a2f6b", "#8d5c39": "#905a39", "#786824": "#6f684a", "#4f6b1e": "#4f6727", "#096e50": "#116b4c"]

    /// `parseInt(s, 16)` (espaces de tête, signe, préfixe 0x, chiffres jusqu'au premier invalide).
    static func parseHex(_ s0: String) -> Double {
        var s = Substring(String(JS.trimStart(s0)))
        var sign = 1.0
        if s.hasPrefix("-") { sign = -1; s = s.dropFirst() } else if s.hasPrefix("+") { s = s.dropFirst() }
        if s.hasPrefix("0x") || s.hasPrefix("0X") { s = s.dropFirst(2) }
        var v = 0.0, any = false
        for c in s.unicodeScalars {
            guard let d = Int(String(c), radix: 16), c.isASCII else { break }
            v = v * 16 + Double(d); any = true
        }
        return any ? sign * v : .nan
    }
    /// `hexToRgb(h)` : composantes 0…1 (« #abc » doublé en « #aabbcc »).
    public static func hexToRgb(_ h0: String) -> [Double] {
        var h = Array(h0.utf16.dropFirst())
        if h.count < 6 { h = h.flatMap { [$0, $0] } }
        return [0, 2, 4].map { i in parseHex(JS.str(h[min(i, h.count)..<min(i + 2, h.count)])) / 255 }
    }
    /// `rgbToHex(rgb)`.
    public static func rgbToHex(_ rgb: [Double]) -> String {
        "#" + rgb.map { v -> String in
            let c = max(0, min(1, v))
            if v.isNaN { return "NaN" }
            let s = String(Int(JS.round(c * 255)), radix: 16)
            return s.count < 2 ? "0" + s : s
        }.joined()
    }
    static func srgbLin(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
    static func srgbGam(_ v0: Double) -> Double { let v = max(0, min(1, v0)); return v <= 0.0031308 ? 12.92 * v : 1.055 * pow(v, 1 / 2.4) - 0.055 }
    static func rgbToOklab(_ r: Double, _ g: Double, _ b: Double) -> [Double] {
        let R = srgbLin(r), G = srgbLin(g), B = srgbLin(b)
        let l = cbrt(0.4122214708 * R + 0.5363325363 * G + 0.0514459929 * B)
        let m = cbrt(0.2119034982 * R + 0.6806995451 * G + 0.1073969566 * B)
        let s = cbrt(0.0883024619 * R + 0.2817188376 * G + 0.6299787005 * B)
        return [0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
                1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
                0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s]
    }
    static func oklabToRgb(_ L: Double, _ a: Double, _ b: Double) -> [Double] {
        let l_ = L + 0.3963377774 * a + 0.2158037573 * b, m_ = L - 0.1055613458 * a - 0.0638541728 * b, s_ = L - 0.0894841775 * a - 1.2914855480 * b
        let l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_
        return [srgbGam(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
                srgbGam(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
                srgbGam(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)]
    }
    /// `oklchToHex(L, C, h)`.
    public static func oklchToHex(_ L: Double, _ C: Double, _ h: Double) -> String {
        let r = h * Double.pi / 180
        return rgbToHex(oklabToRgb(L, C * cos(r), C * sin(r)))
    }
    /// `hexToOklch(hex)` → [L, C, h°].
    public static func hexToOklch(_ hex: String) -> [Double] {
        let c = hexToRgb(hex)
        let lab = rgbToOklab(c[0], c[1], c[2])
        var h = atan2(lab[2], lab[1]) * 180 / Double.pi
        if h < 0 { h += 360 }
        return [lab[0], hypot(lab[1], lab[2]), h]
    }
    /// `catHueDeg(hex)` : la teinte entière (0…359) ; nil pour une couleur illisible (NaN en JS).
    public static func hueDeg(_ hex: String) -> Int? {
        let r = JS.round(hexToOklch(hex)[2])
        return r.isNaN ? nil : Int(r.truncatingRemainder(dividingBy: 360))
    }
    /// `dEok(h1, h2)` : écart OKLab × 100.
    public static func dEok(_ h1: String, _ h2: String) -> Double {
        let a = hexToRgb(h1), b = hexToRgb(h2)
        let A = rgbToOklab(a[0], a[1], a[2]), B = rgbToOklab(b[0], b[1], b[2])
        let x = A[0] - B[0], y = A[1] - B[1], z = A[2] - B[2]
        return 100 * (x * x + y * y + z * z).squareRoot()
    }
    static func relY(_ hex: String) -> Double { let c = hexToRgb(hex).map(srgbLin); return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2] }
    /// `wcagRatio(a, b)`.
    public static func wcagRatio(_ a: String, _ b: String) -> Double {
        let A = relY(a), B = relY(b)
        return (max(A, B) + 0.05) / (min(A, B) + 0.05)
    }
    /// `catLisible(col)` : blanc sur la pleine couleur ET la couleur sur sa teinte à 15 %, ≥ 4,5:1.
    public static func lisible(_ col: String) -> Bool {
        let tint = rgbToHex(hexToRgb(col).map { $0 * 0.15 + 0.85 })
        return wcagRatio("#ffffff", col) >= 4.5 && wcagRatio(col, tint) >= 4.5
    }
    /// `CAT_ANK` : les presets en OKLCH, triés par teinte (l'anneau passe PAR eux).
    static let anchors: [(L: Double, C: Double, h: Double)] = palette.map { p in let o = hexToOklch(p); return (o[0], o[1], o[2]) }
        .enumerated().sorted { $0.element.2 != $1.element.2 ? $0.element.2 < $1.element.2 : $0.offset < $1.offset }.map(\.element)
    /// `catHueHex(h)` : la couleur de l'anneau au degré h — L et C interpolées entre presets voisins,
    /// clarté abaissée tant que la pastille n'est pas lisible.
    public static func hueHex(_ h0: Double) -> String {
        let h = (h0.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let n = anchors.count
        var i = anchors.firstIndex { h < $0.h } ?? -1
        if i < 0 { i = 0 }
        let b = anchors[(i - 1 + n) % n], c = anchors[i]
        let hb = b.h
        var hc = c.h
        if hc <= hb { hc += 360 }
        var hh = h
        if hh < hb { hh += 360 }
        let t = (hh - hb) / (hc - hb)
        var L = b.L + (c.L - b.L) * t
        let C = b.C + (c.C - b.C) * t
        var hex = oklchToHex(L, C, h)
        while !lisible(hex) && L > 0.40 { L -= 0.004; hex = oklchToHex(L, C, h) }
        return hex
    }
    /// `catHueSnap(h, orig)` : à un degré, TOUJOURS la même couleur — l'origine, puis un preset, puis l'anneau.
    public static func hueSnap(_ h: Int, orig: String?) -> String {
        if let o = orig, !o.isEmpty, hueDeg(o) == h { return o }
        if let p = palette.first(where: { hueDeg($0) == h }) { return p }
        return hueHex(Double(h))
    }
    /// `catRegNear(col)` : trop proche d'un registre (ΔE OKLab < 6,2).
    public static func regNear(_ col: String) -> Bool { registers.contains { dEok(col, $0) < 6.2 } }
    /// `catSafeTwin(col)` : la teinte voisine sûre, proposée d'un tap (jamais appliquée d'office).
    public static func safeTwin(_ col: String) -> String? {
        if let o = oldPresets[col] { return o }
        let h = hueHex(hueDeg(col).map(Double.init) ?? .nan)
        guard regNear(h) else { return h }
        return palette.enumerated().sorted { a, b in
            let da = dEok(col, a.element), db = dEok(col, b.element)
            return da != db ? da < db : a.offset < b.offset
        }.map(\.element).first { !regNear($0) }
    }
}
