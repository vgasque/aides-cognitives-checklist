import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// Système de design repris À LA VALEUR des tokens de `index.html` (`:root` et
// `html[data-theme="dark"]`) — source de vérité inchangée : la PWA.
//
// Règle 8 (registres, A407) : ROUGE = ce qui tue si on l'oublie, et l'alarme active ;
// AMBRE = là où l'on risque de se tromper, et l'échéance ; VERT = fait / nominal ;
// BLEU = l'action et le bloc courant. Une couleur n'est JAMAIS seule : toujours un glyphe et un mot.

extension Color {
    /// Couleur qui suit le thème (clair / sombre) du système ou le réglage de l'app.
    init(light: UInt32, dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark ? UIColor(hex: dark, alpha: darkAlpha) : UIColor(hex: light, alpha: lightAlpha)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { ap in
            ap.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(hex: dark, alpha: darkAlpha) : NSColor(hex: light, alpha: lightAlpha)
        })
        #endif
    }
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255, opacity: alpha)
    }
    /// Couleur venue des DONNÉES (catégorie) : déjà validée par `safeColor` dans le cœur.
    init(cssHex: String) {
        var s = cssHex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        let v = UInt32(s.prefix(6), radix: 16) ?? 0x45556b
        self.init(hex: v)
    }
}

#if canImport(UIKit)
extension UIColor {
    convenience init(hex: UInt32, alpha: Double) {
        self.init(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
                  blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
    }
}
#elseif canImport(AppKit)
extension NSColor {
    convenience init(hex: UInt32, alpha: Double) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
                  blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
    }
}
#endif

/// Les tokens de couleur (noms repris de la PWA, sans le préfixe `--`).
enum T {
    // 1. Matières
    static let amb = Color(light: 0xf4f5f7, dark: 0x0d0f13)          // ambiance (fond de page)
    static let amb2 = Color(light: 0xeceef1, dark: 0x101318)
    static let work = Color(light: 0xffffff, dark: 0x1e232b)         // matière travail (cartes)
    static let workLine = Color(light: 0x14181d, dark: 0x667080, lightAlpha: 0.08)
    static let sys = Color(light: 0x1d232b, dark: 0x333b47)          // matière système (quai, capsule)
    static let sysHi = Color(light: 0x2b333e, dark: 0x3d4653)
    static let sys2 = Color(light: 0xffffff, dark: 0xffffff, lightAlpha: 0.07, darkAlpha: 0.12)
    static let sysLine = Color(light: 0xffffff, dark: 0xffffff, lightAlpha: 0.18, darkAlpha: 0.16)
    static let sysEdge = Color(light: 0x000000, dark: 0x7c879a, lightAlpha: 0, darkAlpha: 1)
    static let sysInk = Color(hex: 0xe6eaf0)
    static let sysInk2 = Color(hex: 0x9aa5b3)
    static let line = Color(light: 0xe3e6ea, dark: 0x2c313a)
    static let lineStrong = Color(light: 0xc3ccd6, dark: 0x2c313a)
    static let ctlLine = Color(light: 0x828c98, dark: 0x6b7480)
    static let ctlSys = Color(light: 0x6a7381, dark: 0x7c879a)
    // 2. Encres
    static let ink = Color(light: 0x14181d, dark: 0xe6eaf0)
    static let ink2 = Color(light: 0x5b6472, dark: 0x9aa5b3)
    static let ink3 = Color(light: 0xa3abb6, dark: 0x707c8c)
    // 3. Registres
    static let ok = Color(light: 0x1d7a38, dark: 0x4ade80)
    static let okSoft = Color(light: 0xe8f2ea, dark: 0x12241a)
    static let warn = Color(light: 0x7a5900, dark: 0xfbbf24)
    static let warnLine = Color(hex: 0xb45309)
    static let warnSoft = Color(light: 0xfbf3dc, dark: 0x2b2005)
    static let bolt = Color(light: 0xf5b800, dark: 0xfbbf24)
    static let boltEdge = Color(light: 0x8a5200, dark: 0xf59e0b)
    static let warnSys = Color(hex: 0xfbbf24)
    static let warnSysBg = Color(hex: 0x3c2b06)
    static let okSys = Color(hex: 0x4ade80)
    static let critSys = Color(hex: 0xff9d94)
    static let onSysFill = Color(hex: 0x0d0f13)
    static let crit = Color(light: 0xa32e1f, dark: 0xff7a70)
    static let critLine = Color(light: 0xc43d34, dark: 0xff7a70)
    static let critSoft = Color(light: 0xfbf0ee, dark: 0x211114)
    static let act = Color(light: 0x17477f, dark: 0x8fb8e8)
    static let primarySoft = Color(light: 0xe3ecf7, dark: 0x12263f)
    static let primary100 = Color(light: 0xcddbf0, dark: 0x1b3556)
    static let primary200 = Color(light: 0xb9cde6, dark: 0x2c4b6e)
    static let onPrimary = Color(light: 0xffffff, dark: 0x0d0f13)
    static let doneLine = Color(light: 0xbfd8c6, dark: 0x1e3a28)
    static let criticalLine = Color(light: 0xecc4bc, dark: 0x3a1f1c)
    static let verifyLine = Color(light: 0xeddfb6, dark: 0x3a2f12)
    static let paper = Color(hex: 0xffffff)                          // fixe des deux thèmes (QR, impression)
    static let scrim = Color(light: 0x14181d, dark: 0x000000, lightAlpha: 0.55, darkAlpha: 0.62)

    /// Nuancier des catégories (A408 : sorti des registres).
    static let categoryPresets: [String] = [
        "#905a39", "#6f684a", "#4f6727", "#116b4c", "#226a71", "#1f6f96",
        "#45556b", "#0d5b56", "#5156b6", "#755a96", "#7a2f6b", "#95516c",
    ]
}

/// Échelle typographique FERMÉE (A6) : aucune valeur entre les crans.
/// Dynamic Type : chaque cran suit le réglage de taille du texte du système (`relativeTo:`),
/// ce qui remplace le zoom `--zf` de la PWA.
enum TypeScale {
    static let cap: CGFloat = 11      // plancher (règle 9)
    static let meta: CGFloat = 12
    static let body: CGFloat = 13.5
    static let item: CGFloat = 15
    static let step: CGFloat = 17.5
    static let stepL: CGFloat = 21
    static let val: CGFloat = 24
    static let display: [CGFloat] = [20, 24, 26, 34, 40]
}

extension Font {
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .semibold, relativeTo style: Font.TextStyle = .body) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func title(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

/// Échelle FERMÉE des contrôles (A375) : S 32 · M 40 · L 44 · XL 56 · rangées 52.
enum Ctrl {
    static let s: CGFloat = 32
    static let m: CGFloat = 40
    static let l: CGFloat = 44       // cible minimale en crise (règle 9)
    static let xl: CGFloat = 56
    static let row: CGFloat = 52
    static let stepRow: CGFloat = 64
}

/// Rayons (4 crans).
enum Radius {
    static let r1: CGFloat = 8
    static let r2: CGFloat = 10
    static let r3: CGFloat = 12
    static let r4: CGFloat = 14
}

/// Paliers de largeur de la PWA (mesurés en points de la fenêtre, déjà divisés par le zoom).
enum WidthClass: Comparable {
    case phone      // < 780
    case tablet     // ≥ 780
    case cockpit    // ≥ 1200
    static func of(_ w: CGFloat) -> WidthClass { w >= 1200 ? .cockpit : (w >= 780 ? .tablet : .phone) }
}
