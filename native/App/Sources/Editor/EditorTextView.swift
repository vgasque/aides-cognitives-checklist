import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// CHAMP MULTI-LIGNES À SÉLECTION ACCESSIBLE — les barres d'outils Markdown (« Gras », titres,
// listes, encadrés, tableau, image au curseur) agissent sur la SÉLECTION (`selBounds`, `mdSplice`),
// que `TextEditor` ne donne pas avant iOS 18. On enveloppe donc `UITextView` / `NSTextView`, en
// unités UTF-16 (`NSRange`) — exactement les indices de `selectionStart` du web.

/// Poignée vers le champ natif : lire la sélection, appliquer une insertion puis replacer le curseur.
@MainActor
final class EdTextController {
    #if canImport(UIKit)
    weak var view: UITextView?
    #elseif canImport(AppKit)
    weak var view: NSTextView?
    #endif
    /// Appelée par l'éditeur pour propager une insertion au modèle (comme l'`input` rejoué du web).
    var onEdit: ((String) -> Void)?

    /// Sélection courante (le curseur reste mémorisé même quand le champ n'a plus le focus).
    var selection: NSRange {
        #if canImport(UIKit)
        return view?.selectedRange ?? NSRange(location: 0, length: 0)
        #elseif canImport(AppKit)
        return view?.selectedRange() ?? NSRange(location: 0, length: 0)
        #else
        return NSRange(location: 0, length: 0)
        #endif
    }
    /// Pose le texte ET la sélection sur le champ, puis rend le focus (curseur en fin de segment).
    func apply(_ e: EdKit.TextEdit) {
        #if canImport(UIKit)
        if let v = view {
            v.text = e.text
            v.selectedRange = clamp(e.sel, (e.text as NSString).length)
            if !v.isFirstResponder { v.becomeFirstResponder() }
        }
        #elseif canImport(AppKit)
        if let v = view {
            v.string = e.text
            v.setSelectedRange(clamp(e.sel, (e.text as NSString).length))
            v.window?.makeFirstResponder(v)
        }
        #endif
        onEdit?(e.text)
    }
    func select(_ r: NSRange) {
        #if canImport(UIKit)
        if let v = view { v.selectedRange = clamp(r, (v.text as NSString).length); if !v.isFirstResponder { v.becomeFirstResponder() } }
        #elseif canImport(AppKit)
        if let v = view { v.setSelectedRange(clamp(r, (v.string as NSString).length)); v.window?.makeFirstResponder(v) }
        #endif
    }
    private func clamp(_ r: NSRange, _ n: Int) -> NSRange {
        let a = max(0, min(r.location, n))
        return NSRange(location: a, length: max(0, min(r.length, n - a)))
    }
}

/// Champ multi-lignes de l'éditeur (fond `--amb-2`, indication tant qu'il est vide).
struct EdTextView: View {
    var text: String
    var placeholder: String
    var accessibility: String
    var minHeight: CGFloat = 64
    var mono = false
    var controller: EdTextController
    var onChange: (String) -> Void
    @Environment(\.textScale) private var scale

    var body: some View {
        EdTextViewRep(text: text, fontSize: TypeScale.item * scale, mono: mono, accessibility: accessibility,
                      minHeight: minHeight, controller: controller, onChange: onChange)
            .frame(minHeight: minHeight)
            .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder).aFont(TypeScale.item, .regular, mono ? .mono : .ui).foregroundStyle(T.ink3)
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .edLock()
    }
}

#if canImport(UIKit)
struct EdTextViewRep: UIViewRepresentable {
    var text: String
    var fontSize: CGFloat
    var mono: Bool
    var accessibility: String
    var minHeight: CGFloat
    var controller: EdTextController
    var onChange: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onChange: onChange) }

    func makeUIView(context: Context) -> UITextView {
        let v = UITextView()
        v.delegate = context.coordinator
        v.isScrollEnabled = false
        v.backgroundColor = .clear
        v.textColor = .label
        v.font = mono ? .monospacedSystemFont(ofSize: fontSize, weight: .regular) : .systemFont(ofSize: fontSize)
        v.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        v.autocorrectionType = .default
        v.smartQuotesType = .no
        v.smartDashesType = .no
        v.text = text
        v.accessibilityLabel = accessibility
        v.adjustsFontForContentSizeCategory = true
        controller.view = v
        return v
    }
    func updateUIView(_ v: UITextView, context: Context) {
        context.coordinator.onChange = onChange
        controller.view = v
        if v.text != text {
            let sel = v.selectedRange
            v.text = text
            let n = (text as NSString).length
            v.selectedRange = NSRange(location: min(sel.location, n), length: 0)
        }
    }
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let w = proposal.width, w.isFinite, w > 0 else { return nil }
        let s = uiView.sizeThatFits(CGSize(width: w, height: .greatestFiniteMagnitude))
        return CGSize(width: w, height: max(minHeight, s.height))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var onChange: (String) -> Void
        init(onChange: @escaping (String) -> Void) { self.onChange = onChange }
        func textViewDidChange(_ tv: UITextView) { onChange(tv.text) }
    }
}
#elseif canImport(AppKit)
struct EdTextViewRep: NSViewRepresentable {
    var text: String
    var fontSize: CGFloat
    var mono: Bool
    var accessibility: String
    var minHeight: CGFloat
    var controller: EdTextController
    var onChange: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onChange: onChange) }

    func makeNSView(context: Context) -> NSScrollView {
        let sv = NSTextView.scrollableTextView()
        sv.drawsBackground = false
        sv.hasVerticalScroller = true
        if let tv = sv.documentView as? NSTextView {
            tv.delegate = context.coordinator
            tv.isRichText = false
            tv.drawsBackground = false
            tv.font = mono ? .monospacedSystemFont(ofSize: fontSize, weight: .regular) : .systemFont(ofSize: fontSize)
            tv.textColor = .labelColor
            tv.textContainerInset = NSSize(width: 6, height: 8)
            tv.isAutomaticQuoteSubstitutionEnabled = false
            tv.isAutomaticDashSubstitutionEnabled = false
            tv.string = text
            tv.setAccessibilityLabel(accessibility)
            controller.view = tv
        }
        return sv
    }
    func updateNSView(_ sv: NSScrollView, context: Context) {
        context.coordinator.onChange = onChange
        guard let tv = sv.documentView as? NSTextView else { return }
        controller.view = tv
        if tv.string != text {
            let sel = tv.selectedRange()
            tv.string = text
            let n = (text as NSString).length
            tv.setSelectedRange(NSRange(location: min(sel.location, n), length: 0))
        }
    }
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSScrollView, context: Context) -> CGSize? {
        guard let w = proposal.width, w.isFinite, w > 0 else { return nil }
        return CGSize(width: w, height: max(minHeight, 120))
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var onChange: (String) -> Void
        init(onChange: @escaping (String) -> Void) { self.onChange = onChange }
        func textDidChange(_ n: Notification) {
            guard let tv = n.object as? NSTextView else { return }
            onChange(tv.string)
        }
    }
}
#endif
