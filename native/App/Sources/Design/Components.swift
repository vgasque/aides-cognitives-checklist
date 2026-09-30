import SwiftUI
import AidesCore

// COMPOSANTS PARTAGÉS — la grammaire visuelle de la PWA, en SwiftUI.
// Registres (règle 8) : ROUGE = ce qui tue si on l'oublie · AMBRE = là où l'on se trompe ·
// VERT = fait / nominal · BLEU = l'action et le bloc courant. Une couleur n'est JAMAIS seule :
// toujours un mot (et/ou un glyphe).

// MARK: Taille du texte (réglage 100 / 115 / 130 %, le `--zf` de la PWA)

private struct TextScaleKey: EnvironmentKey { static let defaultValue: CGFloat = 1 }
extension EnvironmentValues {
    var textScale: CGFloat {
        get { self[TextScaleKey.self] }
        set { self[TextScaleKey.self] = newValue }
    }
}

enum FontFamily { case ui, mono, title }

/// Police à l'échelle FERMÉE, multipliée par le réglage de taille du texte.
struct AFont: ViewModifier {
    @Environment(\.textScale) private var scale
    var size: CGFloat
    var weight: Font.Weight
    var family: FontFamily
    func body(content: Content) -> some View {
        let s = size * scale
        switch family {
        case .ui: return content.font(.system(size: s, weight: weight, design: .default))
        case .mono: return content.font(.system(size: s, weight: weight, design: .monospaced).monospacedDigit())
        case .title: return content.font(.system(size: s, weight: weight, design: .serif))
        }
    }
}
extension View {
    func aFont(_ size: CGFloat, _ weight: Font.Weight = .semibold, _ family: FontFamily = .ui) -> some View {
        modifier(AFont(size: size, weight: weight, family: family))
    }
}

// MARK: Matières

/// Carte « travail » (blanche le jour, bordée la nuit : la nuit ne projette pas, elle borde).
struct WorkCard<Content: View>: View {
    var padding: CGFloat = 16
    var highlighted = false
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous)
                .strokeBorder(highlighted ? T.act : T.workLine, lineWidth: highlighted ? 2 : (scheme == .dark ? 1 : 0.5)))
            .shadow(color: scheme == .dark ? .clear : Color.black.opacity(highlighted ? 0.12 : 0.06), radius: highlighted ? 16 : 12, y: highlighted ? 12 : 6)
    }
}

/// Intitulé de section en petites capitales (sur-titre).
struct Overline: View {
    var text: String
    var color: Color = T.ink2
    var body: some View {
        Text(text.uppercased()).aFont(TypeScale.meta, .bold).tracking(0.8).foregroundStyle(color)
    }
}

// MARK: Boutons (échelle fermée S 32 · M 40 · L 44 · XL 56)

enum BtnKind { case primary, secondary, danger, quiet, confirm }

struct AButtonStyle: ButtonStyle {
    var kind: BtnKind = .secondary
    var height: CGFloat = Ctrl.l
    var fullWidth = false
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        let (bg, fg, border): (Color, Color, Color) = {
            switch kind {
            case .primary: return (T.act, T.onPrimary, .clear)
            case .confirm: return (T.ok, T.onPrimary, .clear)
            case .danger: return (T.critSoft, T.crit, T.critLine)
            case .secondary: return (T.work, T.ink, T.ctlLine)
            case .quiet: return (.clear, T.act, .clear)
            }
        }()
        return configuration.label
            .aFont(TypeScale.item, .bold)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .frame(minHeight: height)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .foregroundStyle(fg)
            .background(bg, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(border, lineWidth: 1))
            .opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.45)
            .contentShape(Rectangle())
    }
}
extension ButtonStyle where Self == AButtonStyle {
    static func a(_ kind: BtnKind = .secondary, _ height: CGFloat = Ctrl.l, full: Bool = false) -> AButtonStyle {
        AButtonStyle(kind: kind, height: height, fullWidth: full)
    }
}

/// MAINTENIR POUR CONFIRMER (`holdToReset`) : 800 ms (remises à zéro), 1 200 ms (« Terminer »).
/// Au clavier / VoiceOver, l'action part sans maintien (accessibilité : aucun maintien exigé).
struct HoldButton: View {
    var label: String
    var ms: Double = 800
    var kind: BtnKind = .secondary
    var height: CGFloat = Ctrl.l
    var action: () -> Void
    @State private var holding = false
    @State private var progress: CGFloat = 0
    @State private var task: Task<Void, Never>?

    var body: some View {
        Text(holding ? "Maintenir…" : label)
            .aFont(TypeScale.item, .bold)
            .padding(.horizontal, 16)
            .frame(minHeight: height)
            .frame(maxWidth: .infinity)
            .foregroundStyle(kind == .danger ? T.crit : T.ink)
            .background(alignment: .leading) {
                GeometryReader { g in
                    Rectangle().fill((kind == .danger ? T.critLine : T.act).opacity(0.22)).frame(width: g.size.width * progress)
                }
            }
            .background(kind == .danger ? T.critSoft : T.work)
            .clipShape(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(kind == .danger ? T.critLine : T.ctlLine))
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in if !holding { start() } }
                .onEnded { _ in cancel() })
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
    }
    private func start() {
        holding = true
        withAnimation(.linear(duration: ms / 1000)) { progress = 1 }
        task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(ms * 1_000_000))
            guard !Task.isCancelled, holding else { return }
            holding = false; progress = 0
            action()
        }
    }
    private func cancel() {
        task?.cancel(); task = nil
        holding = false
        withAnimation(.easeOut(duration: 0.15)) { progress = 0 }
    }
}

// MARK: Étiquettes

/// Le MOT du registre d'une étape (A345) : jamais un glyphe seul.
struct RegisterTag: View {
    var level: Int
    var body: some View {
        if level == 3 {
            Text("Critique").aFont(TypeScale.meta, .heavy).foregroundStyle(T.crit)
                .accessibilityLabel("Étape critique.")
        } else if level == 2 {
            Text("Vigilance").aFont(TypeScale.meta, .heavy).foregroundStyle(T.warn)
                .accessibilityLabel("Vigilance.")
        }
    }
}

/// Pastille de catégorie (couleur + nom — jamais la couleur seule).
struct CategoryDot: View {
    var color: String
    var size: CGFloat = 8
    var body: some View { Circle().fill(Color(cssHex: color)).frame(width: size, height: size) }
}

struct Chip: View {
    var text: String
    var selected = false
    var color: Color = T.ink2
    var body: some View {
        Text(text)
            .aFont(TypeScale.meta, .bold)
            .padding(.horizontal, 10)
            .frame(minHeight: 28)
            .foregroundStyle(selected ? T.onPrimary : color)
            .background(selected ? T.act : T.amb2, in: Capsule())
    }
}

/// État d'une aide (Brouillon · À revérifier · Validée), mot d'abord.
struct StatusLabel: View {
    var status: Status
    var validatedAt: String
    var body: some View {
        switch status {
        case .draft: Text("○ Brouillon").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
        case .review: Text("△ À revérifier").aFont(TypeScale.meta, .bold).foregroundStyle(T.warn)
        case .validated:
            Text(validatedAt.isEmpty ? "Sans date" : "Validée " + Validation.display(validatedAt))
                .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
        }
    }
}

/// Texte à **gras** (convention de la PWA : `**…**` dans les étapes et listes).
struct BoldText: View {
    var text: String
    var size: CGFloat = TypeScale.item
    var weight: Font.Weight = .regular
    var color: Color = T.ink
    var body: some View {
        Text(Self.attributed(text)).aFont(size, weight).foregroundStyle(color)
    }
    static func attributed(_ s: String) -> AttributedString {
        var out = AttributedString()
        var rest = Substring(s)
        while let a = rest.range(of: "**"), let b = rest[a.upperBound...].range(of: "**"),
              !rest[a.upperBound..<b.lowerBound].isEmpty, !rest[a.upperBound..<b.lowerBound].contains("\n") {
            out += AttributedString(String(rest[..<a.lowerBound]))
            var bold = AttributedString(String(rest[a.upperBound..<b.lowerBound]))
            bold.inlinePresentationIntent = .stronglyEmphasized
            out += bold
            rest = rest[b.upperBound...]
        }
        out += AttributedString(String(rest))
        return out
    }
}

// MARK: Toast

struct ToastView: View {
    var toast: Toast
    var body: some View {
        Text(toast.text)
            .aFont(TypeScale.body, .semibold)
            .foregroundStyle(T.sysInk)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(T.sys, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
            .padding(.horizontal, 16)
            .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: Largeur disponible (paliers 780 / 1200, mesurés sur la largeur divisée par le zoom)

private struct WidthClassKey: EnvironmentKey { static let defaultValue: WidthClass = .phone }
extension EnvironmentValues {
    var widthClass: WidthClass {
        get { self[WidthClassKey.self] }
        set { self[WidthClassKey.self] = newValue }
    }
}
