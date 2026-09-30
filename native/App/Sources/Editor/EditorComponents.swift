import SwiftUI
import AidesCore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// BRIQUES DE L'ÉDITEUR — champs, cartes, segmentés, pastilles, poignées « prendre / poser ».
// Grammaire de la PWA : champs sur `--amb-2` (A350), contrôles de l'échelle fermée S 32 · M 40 ·
// L 44 (A375), boutons d'outil au dessin unique `.ed-ic` (A384), registres jamais seuls.

// MARK: Verrou pendant un déplacement (« tout le reste est inerte tant qu'on tient un objet »)

private struct EdLockedKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    /// Vrai pendant « prendre / poser » : seuls les poignées, les destinations et la bannière restent actifs.
    var edLocked: Bool {
        get { self[EdLockedKey.self] }
        set { self[EdLockedKey.self] = newValue }
    }
}
private struct EdLockModifier: ViewModifier {
    @Environment(\.edLocked) private var locked
    func body(content: Content) -> some View { content.disabled(locked) }
}
extension View {
    /// À poser sur chaque champ ou bouton ordinaire de l'éditeur (jamais sur une poignée ou une destination).
    func edLock() -> some View { modifier(EdLockModifier()) }

    /// Éclair unique d'un élément visé (`revGoFlash`) : un contour bleu qui s'éteint.
    func edFlash(_ on: Bool) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: Radius.r4, style: .continuous)
                .strokeBorder(T.act, lineWidth: 3)
                .opacity(on ? 1 : 0)
                .animation(.easeOut(duration: 0.6), value: on)
                .allowsHitTesting(false)
        )
    }
}

// MARK: Champ texte à état LOCAL

/// Champ de l'éditeur. Comme le DOM du web, il GARDE ce qu'on tape tant qu'il a le focus : le
/// modèle peut normaliser (« a :: » → « a »), la saisie n'est jamais réécrite sous les doigts ;
/// hors focus, il se recale sur la valeur du modèle (annulation, déplacement, restauration).
struct EdField: View {
    var value: String
    var placeholder: String
    var label: String
    var focusKey: String? = nil
    var request: EdRequest? = nil
    var multiline = false
    var mono = false
    var maxLength: Int? = nil
    var size: CGFloat = TypeScale.item
    var weight: Font.Weight = .regular
    var disabled = false
    /// `syncTick` du brouillon : un changement non tapé recale le champ même s'il a le focus.
    var resync: Int = 0
    /// Clavier numérique (durées, pas, seuils) — sans effet hors iOS.
    var numeric = false
    /// Réécriture à la frappe (raccourcis « ! » / « ? ») : rend la nouvelle saisie, ou nil.
    var rewrite: ((String) -> String?)? = nil
    var onChange: (String) -> Void
    var onSubmit: (() -> Void)? = nil
    var onFocus: ((Bool) -> Void)? = nil

    @State private var local = ""
    @State private var handled = -1
    @State private var loaded = false
    @FocusState private var focused: Bool

    var body: some View {
        TextField("", text: $local, prompt: Text(placeholder).foregroundColor(T.ink3), axis: multiline ? .vertical : .horizontal)
            .lineLimit(multiline ? 2...12 : 1...1)
            .focused($focused)
            .aFont(size, weight, mono ? .mono : .ui)
            .foregroundStyle(T.ink)
            .textFieldStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, multiline ? 10 : 0)
            .frame(minHeight: Ctrl.m)
            .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous)
                .strokeBorder(focused ? T.act : Color.clear, lineWidth: 1.5))
            .disabled(disabled)
            .edLock()
            .accessibilityLabel(label)
            #if os(iOS)
            .keyboardType(numeric ? .numberPad : .default)
            #endif
            .onAppear {
                if !loaded { local = value; loaded = true }
                takeRequest()
            }
            .onChange(of: value) { _, v in if !focused { local = v } }
            .onChange(of: resync) { _, _ in if local != value { local = value } }
            .onChange(of: local) { _, v in
                guard loaded else { return }
                if let m = maxLength, JS.length(v) > m { local = JS.prefix(v, m); return }
                if let rw = rewrite, let nv = rw(v) { local = nv; return }
                if v != value { onChange(v) }
            }
            .onChange(of: focused) { _, f in
                if !f { local = value }
                onFocus?(f)
            }
            .onChange(of: request) { _, _ in takeRequest() }
            .onSubmit { onSubmit?() }
    }
    private func takeRequest() {
        guard let r = request, let k = focusKey, r.key == k, r.n != handled else { return }
        handled = r.n
        DispatchQueue.main.async { focused = true }
    }
}

// MARK: Carte de section (fieldset)

/// Carte « travail » à intitulé + indication (le `<fieldset class="field ed-card">` de la PWA).
struct EdCard<Content: View, Trailing: View>: View {
    var title: String
    var hint: String = ""
    var flash = false
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var content: Content

    var body: some View {
        WorkCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                        if !hint.isEmpty {
                            Text(hint).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 8)
                    trailing
                }
                content
            }
        }
        .edFlash(flash)
    }
}
extension EdCard where Trailing == EmptyView {
    init(title: String, hint: String = "", flash: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title; self.hint = hint; self.flash = flash
        self.trailing = EmptyView()
        self.content = content()
    }
}

/// Sous-intitulé dans une carte (« Étapes », « Question »…).
struct EdSub: View {
    var text: String
    var body: some View {
        Text(text).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2).padding(.top, 4)
    }
}

// MARK: Sélecteur segmenté (pastille glissante, `.seg`)

struct EdSeg<V: Hashable>: View {
    var options: [(value: V, label: String)]
    var selection: V
    var disabled: Set<V> = []
    var accessibility: String
    var onSelect: (V) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, o in
                segButton(o.value, o.label)
            }
        }
        .padding(3)
        .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibility)
    }
    @ViewBuilder private func segButton(_ v: V, _ label: String) -> some View {
        let on = v == selection
        let off = disabled.contains(v)
        Button { onSelect(v) } label: {
            Text(label)
                .aFont(TypeScale.body, on ? .bold : .semibold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(off ? T.ink3 : (on ? T.ink : T.ink2))
                .frame(maxWidth: .infinity, minHeight: Ctrl.s + 4)
                .padding(.horizontal, 6)
                .background(on ? T.work : Color.clear, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                .shadow(color: on ? Color.black.opacity(0.08) : .clear, radius: 3, y: 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .edLock()
        .accessibilityAddTraits(on ? [.isSelected] : [])
        .accessibilityHint(off ? "Indisponible" : "")
        .animation(.easeOut(duration: 0.18), value: selection)
    }
}

// MARK: Bouton d'outil (`.ed-ic`)

struct EdIconButton: View {
    var system: String
    var label: String
    var danger = false
    var on = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(danger ? T.crit : (on ? T.act : T.ink2))
                .frame(width: Ctrl.m, height: Ctrl.m)
                .background(on ? T.primarySoft : Color.clear, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .edLock()
        .accessibilityLabel(label)
        .help(label)
    }
}

/// Lien d'action (« + Ajouter une étape », « + Jalon »…).
struct EdLinkButton: View {
    var text: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text).aFont(TypeScale.body, .bold).foregroundStyle(T.act)
                .frame(minHeight: Ctrl.m, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .edLock()
    }
}

// MARK: Prendre / poser (§9)

/// Poignée ⠿ : touchez, puis touchez la destination. Retoucher la même poignée repose l'objet.
struct EdGrabHandle: View {
    var active: Bool
    var label: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("⠿").aFont(TypeScale.stepL, .bold)
                .foregroundStyle(active ? T.onPrimary : T.ink3)
                .frame(width: Ctrl.s, height: Ctrl.l)
                .background(active ? T.act : Color.clear, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint("Touchez, puis touchez la destination")
        .help("Déplacer — touchez, puis touchez la destination")
    }
}

/// Destination « Poser ici » (bouton pleine largeur ≥ 44 pt). `warn` : une étape ⚠ qui change de bloc
/// est ANNONCÉE, jamais interdite.
struct EdDropTarget: View {
    var label: String
    var warn = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(either(warn, "△ ", "") + label)
                .aFont(TypeScale.body, .bold)
                .foregroundStyle(warn ? T.warn : T.act)
                .frame(maxWidth: .infinity, minHeight: Ctrl.l)
                .background(warn ? T.warnSoft : T.primarySoft, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(warn ? T.warnLine : T.act))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .transition(.opacity)
    }
}

// MARK: Pas −/+ (`numStpHtml`)

struct EdStepper: View {
    var value: Int
    var label: String
    var range: ClosedRange<Int> = 1...99
    var onChange: (Int) -> Void
    var body: some View {
        HStack(spacing: 0) {
            Button { onChange(max(range.lowerBound, value - 1)) } label: {
                Text("−").aFont(TypeScale.stepL, .bold).frame(width: Ctrl.m, height: Ctrl.m).contentShape(Rectangle())
            }
            .buttonStyle(.plain).edLock().accessibilityLabel("Moins un")
            Text("\(value)").aFont(TypeScale.item, .bold, .mono).frame(minWidth: 28)
                .accessibilityLabel("\(value)")
            Button { onChange(min(range.upperBound, value + 1)) } label: {
                Text("+").aFont(TypeScale.stepL, .bold).frame(width: Ctrl.m, height: Ctrl.m).contentShape(Rectangle())
            }
            .buttonStyle(.plain).edLock().accessibilityLabel("Plus un")
        }
        .foregroundStyle(T.ink)
        .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}

// MARK: Interrupteur à libellé (`tg-sw`)

struct EdToggleRow: View {
    var title: String
    var sub: String = ""
    var isOn: Bool
    var disabledReason: String? = nil
    var onToggle: (Bool) -> Void
    var body: some View {
        Toggle(isOn: Binding(get: { isOn }, set: { onToggle($0) })) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).aFont(TypeScale.item, .semibold).foregroundStyle(T.ink)
                if !sub.isEmpty {
                    Text(sub).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toggleStyle(.switch)
        .tint(T.act)
        .frame(minHeight: Ctrl.l)
        .disabled(disabledReason != nil)
        .edLock()
        .help(disabledReason ?? "")
    }
}

// MARK: Pastilles des réglages (`edStepSum`)

struct EdPillsRow: View {
    var pills: [EdKit.Pill]
    var body: some View {
        EdFlow(spacing: 6) {
            ForEach(pills) { p in EdPillView(pill: p) }
        }
    }
}
struct EdPillView: View {
    var pill: EdKit.Pill
    var body: some View {
        HStack(spacing: 4) {
            if let ic = pill.icon { Image(systemName: ic).font(.system(size: 11, weight: .bold)) }
            Text(pill.text).aFont(TypeScale.meta, .bold)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 24)
        .foregroundStyle(fg)
        .background(bg, in: Capsule())
        .overlay(Capsule().strokeBorder(border, lineWidth: 1))
    }
    private var fg: Color {
        switch pill.kind {
        case .crit: return T.crit
        case .vig, .ko: return T.warn
        case .lk: return T.act
        default: return T.ink2
        }
    }
    private var bg: Color {
        switch pill.kind {
        case .crit: return T.critSoft
        case .vig, .ko: return T.warnSoft
        case .lk: return T.primarySoft
        default: return T.amb2
        }
    }
    private var border: Color {
        switch pill.kind {
        case .crit: return T.criticalLine
        case .vig, .ko: return T.verifyLine
        default: return Color.clear
        }
    }
}

/// Mise en page qui passe à la ligne (pastilles, puces de liens).
struct EdFlow: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, width: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0 && x + sz.width > maxW { y += rowH + spacing; x = 0; rowH = 0 }
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
            width = max(width, x - spacing)
        }
        return CGSize(width: min(width, maxW), height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + sz.width > bounds.maxX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
    }
}

// MARK: Ligne d'avertissement ambre (garde-fous, jamais rouge)

struct EdGuardLine: View {
    var text: String
    var body: some View {
        if !text.isEmpty {
            Text(text).aFont(TypeScale.meta, .semibold).foregroundStyle(T.warn)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.updatesFrequently)
        }
    }
}

// MARK: Images en data-URI (galerie, blocs)

/// Décodage d'une data-URI d'image, avec un petit cache par clé (id d'image) : une vignette ne se
/// redécode pas à chaque frappe dans l'éditeur.
enum EdImageCache {
    #if canImport(UIKit)
    typealias PlatformImage = UIImage
    #else
    typealias PlatformImage = NSImage
    #endif
    @MainActor private static var cache: [String: PlatformImage] = [:]
    @MainActor static func image(key: String, dataURI: String) -> PlatformImage? {
        let k = key + ":" + String(dataURI.utf8.count)
        if let i = cache[k] { return i }
        guard let comma = dataURI.firstIndex(of: ","),
              let d = Data(base64Encoded: String(dataURI[dataURI.index(after: comma)...]), options: .ignoreUnknownCharacters) else { return nil }
        #if canImport(UIKit)
        let img = UIImage(data: d)
        #else
        let img = NSImage(data: d)
        #endif
        if let img {
            if cache.count > 200 { cache.removeAll() }
            cache[k] = img
        }
        return img
    }
}

struct EdDataImage: View {
    var key: String
    var dataURI: String
    var body: some View {
        if let img = EdImageCache.image(key: key, dataURI: dataURI) {
            #if canImport(UIKit)
            Image(uiImage: img).resizable().scaledToFit()
            #else
            Image(nsImage: img).resizable().scaledToFit()
            #endif
        } else {
            Rectangle().fill(T.amb2).overlay(Image(systemName: "photo").foregroundStyle(T.ink3))
        }
    }
}

// MARK: Ligne-bouton de menu (grammaire `menuRowHtml` : icône · libellé · sous-ligne · chevron)

struct EdMenuRow: View {
    var icon: String?
    var glyph: String? = nil
    var title: String
    var sub: String = ""
    var chevron = false
    var danger = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let glyph {
                    Text(glyph).aFont(TypeScale.item, .bold).foregroundStyle(T.ink2).frame(width: 24)
                } else if let icon {
                    Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(danger ? T.crit : T.ink2).frame(width: 24)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).aFont(TypeScale.item, .bold).foregroundStyle(danger ? T.crit : T.ink)
                    if !sub.isEmpty { Text(sub).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2) }
                }
                Spacer(minLength: 8)
                if chevron { Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(T.ink3) }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: Ctrl.row, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Zone d'ajout (`upDropHtml`) : un bouton qui ouvre le sélecteur de fichier de l'appareil.
struct EdDropZone: View {
    var title: String
    var sub: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.down").font(.system(size: 17, weight: .semibold)).foregroundStyle(T.act)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).aFont(TypeScale.item, .bold).foregroundStyle(T.act)
                    Text(sub).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: Ctrl.row, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])).foregroundStyle(T.ctlLine))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .edLock()
        .help(title)
    }
}

/// Intitulé de l'état d'enregistrement (`edSaySave`) : forme longue, ou courte à l'étroit.
enum EdSaveText {
    static func text(_ s: EdSaveState, at: Double, short: Bool) -> String {
        let t = at > 0 ? Fmt.hm(at) : ""
        switch s {
        case .none: return ""
        case .saving: return short ? "⟳" : "⟳ Enregistrement…"
        case .err: return short ? "⚠ non enregistré" : "⚠ Non enregistré — réessai"
        case .untitled: return short ? "○ sans titre" : "○ Sans titre — rien n’est enregistré"
        case .saved: return short ? ("✓" + (t.isEmpty ? "" : " " + t)) : ("✓ Enregistré" + (t.isEmpty ? "" : " · " + t))
        }
    }
}

/// Libellé d'état éditorial de l'en-tête (`statusLbl`).
enum EdStatusText {
    static func label(_ s: Status, fem: Bool) -> String {
        switch s {
        case .draft: return "○ Brouillon"
        case .review: return "△ À relire"
        case .validated: return fem ? "✓ Validée" : "✓ Validé"
        }
    }
}
