import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// Système de design — partie ÉCRITE À LA MAIN. Les VALEURS (couleurs, échelle typographique,
// rayons, mesures, ombres, mouvement, accents, nuancier) sont GÉNÉRÉES depuis les tokens CSS de
// la PWA dans `Tokens.generated.swift` (`npm run design:build`) : ne jamais les recopier ici.
// Ce fichier ne garde que les outils (couleurs à variantes, ombres) et ce que le CSS ne déclare
// pas encore comme token (échelle des contrôles A375, paliers de largeur).
//
// Règle 8 (registres, A407) : ROUGE = ce qui tue si on l'oublie, et l'alarme active ;
// AMBRE = là où l'on risque de se tromper, et l'échéance ; VERT = fait / nominal ;
// BLEU = l'action et le bloc courant. Une couleur n'est JAMAIS seule : toujours un glyphe et un mot.

extension Color {
    /// Couleur qui suit le thème (clair / sombre) et « Augmenter le contraste » — la forme que
    /// prennent les tokens générés. Sans variante de contraste, elle vaut la variante normale.
    init(light: UInt32, dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1,
         lightContrast: UInt32? = nil, darkContrast: UInt32? = nil,
         lightContrastAlpha: Double? = nil, darkContrastAlpha: Double? = nil) {
        let lc = lightContrast ?? light, dc = darkContrast ?? dark
        let lca = lightContrastAlpha ?? (lightContrast == nil ? lightAlpha : 1)
        let dca = darkContrastAlpha ?? (darkContrast == nil ? darkAlpha : 1)
        #if canImport(UIKit)
        self.init(uiColor: UIColor { tc in
            let hi = tc.accessibilityContrast == .high
            return tc.userInterfaceStyle == .dark
                ? UIColor(hex: hi ? dc : dark, alpha: hi ? dca : darkAlpha)
                : UIColor(hex: hi ? lc : light, alpha: hi ? lca : lightAlpha)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { ap in
            switch ap.bestMatch(from: [.aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua]) {
            case .darkAqua?: return NSColor(hex: dark, alpha: darkAlpha)
            case .accessibilityHighContrastAqua?: return NSColor(hex: lc, alpha: lca)
            case .accessibilityHighContrastDarkAqua?: return NSColor(hex: dc, alpha: dca)
            default: return NSColor(hex: light, alpha: lightAlpha)
            }
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

/// Ombre d'un token `--shadow-*` (générée) ; `nil` quand la PWA déclare `none`.
struct ShadowToken {
    var color: Color
    var radius: CGFloat
    var x: CGFloat
    var y: CGFloat
}
extension View {
    /// Applique une ombre de token (aucune si le token vaut `none`, ou la nuit quand la PWA
    /// l'éteint : « la nuit ne projette pas, elle borde »).
    @ViewBuilder func shadow(_ token: ShadowToken?) -> some View {
        if let token { shadow(color: token.color, radius: token.radius, x: token.x, y: token.y) } else { self }
    }
}

// (La « bande d'affichage » 20 · 24 · 26 · 34 · 40 a été SUPPRIMÉE par la PWA en v5.6, A6 : une
// seule échelle, générée depuis `--t-*`. Le garde-fou `check-swift-design` lit ses paliers dans
// `scripts/check-type.mjs`.)

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

/// Échelle FERMÉE des contrôles (A375) : S 32 · M 40 · L 44 · XL 56 · rangées 52. Pas encore un
/// token CSS (le garde-fou `check-ctrl` de la PWA reste à écrire) : à générer dès qu'il le sera.
enum Ctrl {
    static let s: CGFloat = 32
    static let m: CGFloat = 40
    static let l: CGFloat = Metrics.hit   // cible minimale en crise (règle 9, `--hit`)
    static let xl: CGFloat = 56
    static let row: CGFloat = 52
    static let stepRow: CGFloat = 64
}

/// Paliers de largeur de la PWA (mesurés en points de la fenêtre, déjà divisés par le zoom).
enum WidthClass: Comparable {
    case phone      // < 780
    case tablet     // ≥ 780
    case cockpit    // ≥ 1200
    static func of(_ w: CGFloat) -> WidthClass { w >= 1200 ? .cockpit : (w >= 780 ? .tablet : .phone) }
}
