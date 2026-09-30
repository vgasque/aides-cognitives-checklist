import SwiftUI
import Observation
import AidesCore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// ÉTAT DE VUE DU MODE CRISE — le `state` de la PWA restreint à la lecture d'une aide
// (`ovFold`, `ovVerify`, `rtOpen`, `tkSheet`, `cxOpen`, `revOpen`, `pband`, `resumeSince`…).
// PAR ÉCRAN, jamais persisté, jamais partagé : il décide de l'AFFICHAGE, l'état du soin vit dans
// le `RuntimeSession` du moteur.

/// Passe Do-Verify en cours (`state.ovVerify`).
struct CrVerify: Equatable {
    var idx: Int
    var i: Int
    var gaps: [Int]
}

/// Fenêtres DEMANDÉES par l'utilisateur (jamais ouvertes seules : règle 11) — UNE à la fois.
/// Les feuilles du quai (« Horodater », « Complications ») et le panneau des instruments du
/// téléphone sont des feuilles à détentes qui laissent l'écran de crise actif dessous.
enum CrSheet: Identifiable, Equatable {
    case stamp(String)   // id du repère posé
    case cx
    case panel
    case parcours
    case page
    case schema
    case report(String)
    case history
    case export(URL)
    var id: String {
        switch self {
        case .stamp(let s): return "stamp-" + s
        case .cx: return "cx"
        case .panel: return "panel"
        case .parcours: return "parcours"
        case .page: return "page"
        case .schema: return "schema"
        case .report(let s): return "report-" + s
        case .history: return "history"
        case .export(let u): return "export-" + u.lastPathComponent
        }
    }
}

@MainActor
@Observable
final class CrisisViewState {
    /// Replis du journal : clé = index de visite (« 3 »), « r:3 » (ligne d'historique), « r:conf ».
    var ovFold: [String: Bool] = [:]
    var verify: CrVerify?
    var tmAddOpen = false
    /// Cartes de minuteur dépliées dans le rail (commandes visibles).
    var railTimerOpen: Set<String> = []
    var revOpen: [String: Bool] = [:]
    var pbandOpen = true
    var pbandDetail: Set<String> = []
    /// Cartes dépliables de session OUVERTES (toutes fermées d'office, transitoires).
    var sessFold: Set<String> = []
    /// Ligne « Reprise après interruption » (Q2) : heure du dernier geste.
    var resumeSince: Double?
    /// « Tout voir » (mode statique : Page · Schéma), non persisté.
    var showAll = false
    var allTab = 0
    var menuOpen = false
    var endOpen = false
    var monitorOpen = false
    var sheet: CrSheet?
    /// Défilement DEMANDÉ (Continuer, réponse, complication, « Reprendre », retour au bloc).
    var pendingScroll: String?
    /// Défilement du rail demandé par la capsule (≥ 780).
    var railScroll: String?
    /// Éclair plein écran d'une alarme à l'écran (`#screenFlash`).
    var flashOn = false
    var flashTimer: String?
    var lastCycles: [String: Double] = [:]
    var lastDue: Set<String> = []
    var jalonActive = -1
    /// Tri vivant des minuteurs suspendu (TM_HOLD_MS) : rien ne bouge sous le doigt.
    var tmHoldUntil: Double = 0
    var tmFrozen: [String] = []
    var posoMoreOpen = false
    /// Carte d'une visite ciblée (repère visuel de 900 ms après un saut demandé).
    var spotVisit: Int?
    /// Cadre de la carte vive dans le défileur (retour au bloc en cours).
    var tipVisible = true
    var confirmRestart = false
    var confirmExercise = false
    var confirmDeleteTimer: String?
    var confirmDeleteCounter: String?
    var arrivalPlayed = false
    /// « Ouvrir les aides en : toute la fiche (Page) » appliqué une fois à l'ouverture.
    var readModeApplied = false
    var entryFoldLoaded = ""
    /// Cartes de l'écran d'entrée (par aide, mémorisées sur l'appareil).
    var preOpen: [String: Bool] = [:]
    var colFold: [String: Bool] = [:]
    var colAllOpen = false
}

// MARK: - Petites fonctions d'interface partagées par la zone

/// Annonce VoiceOver (`#srLive` assertif de la PWA).
@MainActor
func crAnnounce(_ text: String) {
    AccessibilityNotification.Announcement(text).post()
}

/// Mémoire LOCALE de l'appareil (préférences d'affichage, jamais un état de soin).
enum CrLocal {
    static func bool(_ k: String) -> Bool? {
        UserDefaults.standard.object(forKey: "ac-crisis-" + k) as? Bool
    }
    static func set(_ k: String, _ v: Bool?) {
        if let v { UserDefaults.standard.set(v, forKey: "ac-crisis-" + k) }
        else { UserDefaults.standard.removeObject(forKey: "ac-crisis-" + k) }
    }
}

/// Image venue d'une data-URI validée par `safeImg` (bloc, schémas & captures).
struct CrDataImage: View {
    var dataURI: String
    var maxHeight: CGFloat = 320
    var body: some View {
        if let img = Self.decode(dataURI) {
            img.resizable().scaledToFit().frame(maxHeight: maxHeight)
                .clipShape(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
        }
    }
    static func decode(_ s: String) -> Image? {
        guard let comma = s.firstIndex(of: ",") else { return nil }
        let b64 = String(s[s.index(after: comma)...]).filter { !$0.isWhitespace }
        guard let d = Data(base64Encoded: b64) else { return nil }
        #if canImport(UIKit)
        guard let ui = UIImage(data: d) else { return nil }
        return Image(uiImage: ui)
        #elseif canImport(AppKit)
        guard let ns = NSImage(data: d) else { return nil }
        return Image(nsImage: ns)
        #else
        return nil
        #endif
    }
}

/// Carré d'icône d'une carte dépliable (26 × 26, teinté).
struct CrIconSquare: View {
    var glyph: String
    var system = false
    var fg: Color
    var bg: Color
    var body: some View {
        Group {
            if system { Image(systemName: glyph).aFont(TypeScale.body, .bold) }
            else { Text(glyph).aFont(TypeScale.body, .heavy) }
        }
        .foregroundStyle(fg)
        .frame(width: 26, height: 26)
        .background(bg, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// CARTE DÉPLIABLE (`foldCardHtml`, A358) — une seule grammaire avant et pendant la session.
struct CrFoldCard<Content: View>: View {
    var icon: CrIconSquare
    var title: String
    var count: String = ""
    var open: Bool
    var toggle: () -> Void
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggle) {
                HStack(spacing: 12) {
                    icon
                    Text(title).aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 8)
                    if !count.isEmpty { Text(count).aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2) }
                    Image(systemName: "chevron.down")
                        .aFont(TypeScale.body, .semibold)
                        .rotationEffect(.degrees(open ? 180 : 0))
                        .foregroundStyle(T.ink2)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: Ctrl.row)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(open ? "déplié" : "replié")
            if open {
                VStack(alignment: .leading, spacing: 0) { content() }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.workLine, lineWidth: 1))
        .shadow(Shadows.work)
        .padding(.top, 10)
    }
}

/// Rangée simple d'une carte dépliable (44 min, filet au-dessus).
struct CrFlatRow<Content: View>: View {
    var first = false
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(spacing: 0) {
            if !first { Rectangle().fill(T.line).frame(height: 1) }
            HStack(alignment: .firstTextBaseline, spacing: 8) { content() }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.vertical, 6)
        }
    }
}

/// Étiquette en petites capitales (registre, moment, trace de vérification).
struct CrTag: View {
    var text: String
    var fg: Color
    var bg: Color = .clear
    var border: Color? = nil
    var dashed = false
    var body: some View {
        Text(text.uppercased())
            .aFont(TypeScale.cap, .heavy)
            .tracking(0.8)
            .foregroundStyle(fg)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(bg, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
            .overlay {
                if let border {
                    RoundedRectangle(cornerRadius: Radius.r1, style: .continuous)
                        .strokeBorder(border, style: StrokeStyle(lineWidth: 1.5, dash: dashed ? [3, 2] : []))
                }
            }
    }
}

/// L'éclair REMPLI des complications (`boltIcon`, A335) : jamais l'emoji.
struct CrBolt: View {
    var size: CGFloat = 14
    var body: some View {
        Image(systemName: "bolt.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(T.bolt)
            .accessibilityHidden(true)
    }
}
