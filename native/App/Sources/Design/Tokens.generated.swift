// ⚠ FICHIER GÉNÉRÉ — ne pas éditer. Source : les tokens CSS d'index.html (PWA).
// Régénérer : `npm run design:build` (→ design/tokens.mjs → native/tools/build-tokens.mjs).
// `npm run design:check` échoue si ce fichier n'est plus à jour avec index.html.
import SwiftUI

/// Couleurs (`--nom` → `T.nom`, en camelCase). Quatre variantes quand la PWA en déclare :
/// jour, nuit, et « Augmenter le contraste » (`@media (prefers-contrast:more)`).
enum T {
    static let amb = Color(light: 0xf4f5f7, dark: 0x0d0f13)
    static let amb2 = Color(light: 0xeceef1, dark: 0x101318)
    static let work = Color(light: 0xffffff, dark: 0x1e232b)
    static let workLine = Color(light: 0x14181d, dark: 0x667080, lightAlpha: 0.08)
    static let sys = Color(light: 0x1d232b, dark: 0x333b47)
    static let sysHi = Color(light: 0x2b333e, dark: 0x3d4653)
    static let sys2 = Color(light: 0xffffff, dark: 0xffffff, lightAlpha: 0.07, darkAlpha: 0.12)
    static let sysLine = Color(light: 0xffffff, dark: 0xffffff, lightAlpha: 0.18, darkAlpha: 0.16)
    static let sysInk = Color(hex: 0xe6eaf0, alpha: 1)
    static let sysInk2 = Color(hex: 0x9aa5b3, alpha: 1)
    static let sysEdge = Color(light: 0x000000, dark: 0x7c879a, lightAlpha: 0)
    static let sysKey = Color(light: 0xffffff, dark: 0xffffff, lightAlpha: 0.1, darkAlpha: 0.14)
    static let dockRing = Color(light: 0x1d232b, dark: 0xe6eaf0, lightAlpha: 0.85, darkAlpha: 0.8)
    static let line = Color(light: 0xe3e6ea, dark: 0x1c1f25, lightContrast: 0xc3ccd6, darkContrast: 0x2c313a)
    static let lineStrong = Color(light: 0xc3ccd6, dark: 0x2c313a)
    static let ctlLine = Color(light: 0x828c98, dark: 0x6b7480)
    static let ctlSys = Color(light: 0x6a7381, dark: 0x7c879a)
    static let ink = Color(light: 0x14181d, dark: 0xe6eaf0)
    static let ink2 = Color(light: 0x5b6472, dark: 0x9aa5b3)
    static let ink3 = Color(light: 0xa3abb6, dark: 0x707c8c)
    static let ok = Color(light: 0x1d7a38, dark: 0x4ade80)
    static let okSoft = Color(light: 0xe8f2ea, dark: 0x12241a)
    static let warn = Color(light: 0x7a5900, dark: 0xfbbf24)
    static let warnLine = Color(hex: 0xb45309, alpha: 1)
    static let warnSoft = Color(light: 0xfbf3dc, dark: 0x2b2005)
    static let bolt = Color(light: 0xf5b800, dark: 0xfbbf24)
    static let boltEdge = Color(light: 0x8a5200, dark: 0xf59e0b)
    static let warnSys = Color(hex: 0xfbbf24, alpha: 1)
    static let warnSysBg = Color(hex: 0x3c2b06, alpha: 1)
    static let alarmBd = Color(light: 0xb45309, dark: 0xfbbf24)
    static let okSys = Color(hex: 0x4ade80, alpha: 1)
    static let critSys = Color(hex: 0xff9d94, alpha: 1)
    static let onSysFill = Color(hex: 0x0d0f13, alpha: 1)
    static let crit = Color(light: 0xa32e1f, dark: 0xff7a70)
    static let critLine = Color(light: 0xc43d34, dark: 0xff7a70)
    static let critSoft = Color(light: 0xfbf0ee, dark: 0x211114)
    static let act = Color(light: 0x17477f, dark: 0x8fb8e8)
    static let edgeMask = Color(hex: 0x000000, alpha: 1)
    static let paper = Color(hex: 0xffffff, alpha: 1)
    static let inkSoft = Color(light: 0x5b6472, dark: 0x9aa5b3, lightContrast: 0x14181d, darkContrast: 0xe6eaf0)
    static let primarySoft = Color(light: 0xe3ecf7, dark: 0x12263f)
    static let primary100 = Color(light: 0xcddbf0, dark: 0x1b3556)
    static let primary200 = Color(light: 0xb9cde6, dark: 0x2c4b6e)
    static let onPrimary = Color(light: 0xffffff, dark: 0x0d0f13)
    static let doneLine = Color(light: 0xbfd8c6, dark: 0x1e3a28)
    static let criticalLine = Color(light: 0xecc4bc, dark: 0x3a1f1c)
    static let verifyLine = Color(light: 0xeddfb6, dark: 0x3a2f12)
    static let scrimSoft = Color(light: 0x14181d, dark: 0x000000, lightAlpha: 0.45, darkAlpha: 0.5)
    static let scrim = Color(light: 0x14181d, dark: 0x000000, lightAlpha: 0.55, darkAlpha: 0.62)
    static let scrimFull = Color(light: 0x14181d, dark: 0x000000, lightAlpha: 0.92, darkAlpha: 0.94)
    static let lbCap = Color(hex: 0xcfe0dd, alpha: 1)
    static let lbInk = Color(hex: 0xffffff, alpha: 1)
    static let qrInk = Color(hex: 0x14181d, alpha: 1)
    static let pdfHl = Color(hex: 0xffd500, alpha: 0.4)
    static let pdfHlRing = Color(hex: 0xc78a00, alpha: 0.85)
    static let hoverDk = Color(hex: 0x1c1d21, alpha: 1)
    static let hoverDkHi = Color(hex: 0x26282e, alpha: 1)
    static let flowHlDk = Color(hex: 0x4e8fd9, alpha: 1)

    /// Nuancier des catégories (`PALETTE`, A408 : hors des registres).
    static let palette: [String] = ["#905a39", "#6f684a", "#4f6727", "#116b4c", "#226a71", "#1f6f96", "#45556b", "#0d5b56", "#5156b6", "#755a96", "#7a2f6b", "#95516c"]
}

/// Échelle typographique FERMÉE (`--t-*`, A6) — aucune valeur entre les crans.
enum TypeScale {
    static let cap: CGFloat = 11
    static let meta: CGFloat = 12
    static let body: CGFloat = 13.5
    static let item: CGFloat = 15
    static let step: CGFloat = 17.5
    static let stepL: CGFloat = 21
    static let val: CGFloat = 24
    /// Corps des commandes de session (`--g-cmd`).
    static let cmd: CGFloat = 17.5
}

/// Rayons (`--r-*`).
enum Radius {
    static let r1: CGFloat = 8
    static let r2: CGFloat = 10
    static let r3: CGFloat = 12
    static let r4: CGFloat = 14
}

/// Mesures de mise en page (colonnes, fenêtres, cible tactile).
enum Metrics {
    static let sideW: CGFloat = 250
    static let colOrient: CGFloat = 240
    static let colState: CGFloat = 320
    static let colGap: CGFloat = 20
    static let dlgConfirm: CGFloat = 420
    static let dlgStd: CGFloat = 480
    static let dlgAtelier: CGFloat = 720
    static let hit: CGFloat = 44
}

/// Mouvement (`--dur-*`, `--ease-out`).
enum Motion {
    static let dur2: Double = 0.2
    /// `--ease-out` : cubic-bezier(0.2, 0.8, 0.2, 1).
    static func easeOut(_ duration: Double = 0.2) -> Animation { .timingCurve(0.2, 0.8, 0.2, 1, duration: duration) }
}

/// Graisses (`--w-*`).
enum Weights {
    static let ui: Font.Weight = .semibold
    static let strong: Font.Weight = .bold
}

/// Ombres (`--shadow-*`) : première couche, rayon SwiftUI = flou CSS ÷ 2. `none` → nil.
enum Shadows {
    static let work: ShadowToken? = ShadowToken(color: Color(light: 0x14181d, dark: 0x000000, lightAlpha: 0.06, darkAlpha: 0), radius: 12, x: 0, y: 6)
    static let cur: ShadowToken? = ShadowToken(color: Color(light: 0x14181d, dark: 0x000000, lightAlpha: 0.12, darkAlpha: 0), radius: 16, x: 0, y: 12)
    static let float: ShadowToken? = ShadowToken(color: Color(light: 0x14181d, dark: 0x000000, lightAlpha: 0.06, darkAlpha: 0), radius: 1, x: 0, y: 1)
    static let up: ShadowToken? = ShadowToken(color: Color(light: 0x14181d, dark: 0x000000, lightAlpha: 0.26, darkAlpha: 0), radius: 16, x: 0, y: -12)
    static let bar: ShadowToken? = nil
    static let primarySm: ShadowToken? = nil
}

/// Couleurs d'accent (`body[data-accent]`) : elles ne teintent que le disque du compte.
enum Accent {
    static let all: [(name: String, color: Color)] = [
        ("teal", Color(light: 0x0f766e, dark: 0x0d9488)),
        ("violet", Color(light: 0x6d28d9, dark: 0x8b5cf6)),
        ("indigo", Color(light: 0x4338ca, dark: 0x6366f1)),
        ("framboise", Color(light: 0xbe185d, dark: 0xdb2777)),
        ("ardoise", Color(light: 0x475569, dark: 0x64748b)),
    ]
    static func color(_ name: String) -> Color? { all.first { $0.name == name }?.color }
}
