import SwiftUI
import PDFKit
import AidesCore

// VISIONNEUSE PDF — PDFKit natif (remplace pdf.js vendorisé de la PWA : rendu, zoom, liens,
// sommaire et recherche sont ceux du système, hors ligne, sans dépendance).
// Spécification : C2 §20 (ouverture, barre d'outils, liens, sommaire, surlignage des termes).

struct PDFViewerView: View {
    let attachmentId: String
    let name: String
    /// Page d'ouverture (1-based) et termes à surligner (recherche de l'accueil).
    var page: Int? = nil
    var highlight: [String] = []

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.widthClass) private var wc
    @State private var doc: PDFDocument?
    @State private var message = "Ouverture du document…"
    @State private var controller = PDFController()
    @State private var tocOpen = false
    @State private var hits: [PDFSelection] = []
    @State private var hitIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            if tocOpen, let doc, wc != .cockpit { OutlineList(doc: doc) { go($0); tocOpen = false }.frame(maxHeight: 280) }
            HStack(spacing: 0) {
                if tocOpen, let doc, wc == .cockpit {
                    OutlineList(doc: doc) { go($0) }.frame(width: 280)
                    Divider()
                }
                ZStack(alignment: .bottom) {
                    if let doc {
                        PDFKitView(document: doc, controller: controller).ignoresSafeArea(edges: .bottom)
                    } else {
                        Text(message).aFont(TypeScale.item, .medium).foregroundStyle(T.ink2).padding(24)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    if !hits.isEmpty { hitPill.padding(.bottom, 20) }
                }
            }
        }
        .background(T.amb)
        .navigationTitle(name.isEmpty ? "Document" : name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await load() }
    }

    // MARK: Barre d'outils

    private var toolbar: some View {
        HStack(spacing: 8) {
            if let doc, doc.outlineRoot?.numberOfChildren ?? 0 > 0 {
                Button { tocOpen.toggle() } label: { Label("Sommaire", systemImage: "list.bullet") }
                    .buttonStyle(.a(.secondary, Ctrl.m))
                    .accessibilityLabel(tocOpen ? "Replier le sommaire" : "Afficher le sommaire")
            }
            Spacer()
            Button { controller.zoom(by: -0.25) } label: { Image(systemName: "minus") }
                .buttonStyle(.a(.secondary, Ctrl.m)).accessibilityLabel("Dézoomer")
            Text("\(Int((controller.scale * 100).rounded()))%").aFont(TypeScale.meta, .bold, .mono).frame(minWidth: 48)
            Button { controller.zoom(by: 0.25) } label: { Image(systemName: "plus") }
                .buttonStyle(.a(.secondary, Ctrl.m)).accessibilityLabel("Zoomer")
            Button("Page") { controller.fitPage() }.buttonStyle(.a(.secondary, Ctrl.m))
            Button("Largeur") { controller.fitWidth() }.buttonStyle(.a(.secondary, Ctrl.m))
            if let url = model.library.space.attachmentURL(attachmentId) {
                ShareLink(item: shareURL(url)) { Image(systemName: "square.and.arrow.down") }
                    .buttonStyle(.a(.secondary, Ctrl.m))
                    .accessibilityLabel("Télécharger le document")
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(T.work)
    }

    /// Le fichier partagé porte le nom d'affichage (`attDlName`), pas l'identifiant interne.
    private func shareURL(_ src: URL) -> URL {
        let dst = FileManager.default.temporaryDirectory.appendingPathComponent(Guard.attDownloadName(name))
        try? FileManager.default.removeItem(at: dst)
        try? FileManager.default.copyItem(at: src, to: dst)
        return dst
    }

    private var hitPill: some View {
        HStack(spacing: 4) {
            Button { step(-1) } label: { Image(systemName: "chevron.left").frame(width: Ctrl.l, height: Ctrl.l) }
                .accessibilityLabel("Page d'occurrence précédente")
            Text(pillText).aFont(TypeScale.meta, .bold, .mono).foregroundStyle(T.sysInk)
                .accessibilityAddTraits(.updatesFrequently)
            Button { step(1) } label: { Image(systemName: "chevron.right").frame(width: Ctrl.l, height: Ctrl.l) }
                .accessibilityLabel("Page d'occurrence suivante")
        }
        .foregroundStyle(T.sysInk)
        .padding(.horizontal, 6)
        .background(T.sys, in: Capsule())
    }
    private var pillText: String {
        guard hitIndex < hits.count, let p = hits[hitIndex].pages.first, let doc else { return "" }
        return "\(hitIndex + 1) / \(hits.count) · p. \(doc.index(for: p) + 1)"
    }
    private func step(_ d: Int) {
        guard !hits.isEmpty else { return }
        hitIndex = (hitIndex + d + hits.count) % hits.count
        controller.show(hits[hitIndex])
    }
    private func go(_ dest: PDFDestination) { controller.go(dest) }

    // MARK: Chargement (local, sinon téléchargement du cloud)

    private func load() async {
        if model.library.space.attachmentURL(attachmentId) == nil {
            if model.auth.signedIn, let path = model.sync.attachmentPath(id: attachmentId) {
                message = "Téléchargement du document…"
                do { try await model.sync.fetchAttachment(id: attachmentId, path: path) }
                catch { message = "⚠ Document introuvable dans le cloud — il n'a peut-être pas encore été envoyé depuis l'appareil où il a été ajouté."; return }
            } else {
                message = "Document pas encore téléchargé sur cet appareil : connectez-vous avec du réseau pour le récupérer."
                return
            }
        }
        guard let url = model.library.space.attachmentURL(attachmentId), let d = PDFDocument(url: url) else {
            message = "⚠ Impossible d'ouvrir ce document : le fichier semble endommagé ou dans un format non pris en charge. Retirez-le puis ajoutez-le à nouveau depuis le fichier d'origine."
            return
        }
        doc = d
        tocOpen = wc == .cockpit && (d.outlineRoot?.numberOfChildren ?? 0) > 0
        try? await Task.sleep(nanoseconds: 150_000_000)
        controller.fitPage()
        if let page, page > 1, let p = d.page(at: page - 1) { controller.go(PDFDestination(page: p, at: CGPoint(x: 0, y: p.bounds(for: .mediaBox).height))) }
        let terms = highlight.filter { $0.count >= 2 }
        if !terms.isEmpty {
            // Toutes les occurrences du PREMIER terme, sur les pages qui contiennent tous les termes.
            var sel = d.findString(terms[0], withOptions: [.caseInsensitive, .diacriticInsensitive])
            if terms.count > 1 {
                sel = sel.filter { s in
                    guard let p = s.pages.first, let txt = p.string?.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil) else { return false }
                    return terms.dropFirst().allSatisfy { txt.contains($0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)) }
                }
            }
            hits = sel
            controller.highlight(sel)
            if let startPage = page, let i = sel.firstIndex(where: { s in s.pages.first.map { d.index(for: $0) + 1 >= startPage } ?? false }) {
                hitIndex = i
            }
        }
    }
}

// MARK: - Sommaire (signets du PDF, 3 niveaux, 200 entrées au plus)

private struct OutlineList: View {
    let doc: PDFDocument
    var pick: (PDFDestination) -> Void
    var body: some View {
        List {
            Section { ForEach(entries.indices, id: \.self) { i in row(entries[i]) } } header: { Text("Sommaire").aFont(TypeScale.meta, .bold) }
        }
        .listStyle(.plain)
    }
    private func row(_ e: (title: String, depth: Int, dest: PDFDestination?, page: Int)) -> some View {
        Button { if let d = e.dest { pick(d) } } label: {
            HStack {
                Text(e.title).aFont(TypeScale.body, e.depth == 0 ? .semibold : .regular).foregroundStyle(T.ink).lineLimit(2)
                Spacer()
                Text("\(e.page)").aFont(TypeScale.meta, .regular, .mono).foregroundStyle(T.ink2)
            }
            .padding(.leading, CGFloat(e.depth) * 14)
        }
    }
    private var entries: [(title: String, depth: Int, dest: PDFDestination?, page: Int)] {
        var out: [(title: String, depth: Int, dest: PDFDestination?, page: Int)] = []
        func walk(_ o: PDFOutline, _ d: Int) {
            for i in 0..<o.numberOfChildren {
                guard out.count < 200, let c = o.child(at: i) else { return }
                let t = (c.label ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let pg = c.destination?.page.map { doc.index(for: $0) + 1 } ?? 0
                out.append((t.isEmpty ? "Sans titre" : t, d, c.destination, pg))
                if d < 2 { walk(c, d + 1) }
            }
        }
        if let r = doc.outlineRoot { walk(r, 0) }
        return out
    }
}

// MARK: - Pont PDFKit (iOS / macOS)

@Observable
final class PDFController {
    @ObservationIgnored weak var view: PDFView?
    var scale: CGFloat = 1
    func zoom(by d: CGFloat) {
        guard let v = view else { return }
        v.autoScales = false
        v.scaleFactor = min(4, max(0.25, ((v.scaleFactor + d) * 100).rounded() / 100))
        scale = v.scaleFactor
    }
    /// « Page » : la page entière dans la fenêtre.
    func fitPage() {
        guard let v = view else { return }
        v.autoScales = false
        v.scaleFactor = v.scaleFactorForSizeToFit
        v.autoScales = true
        scale = v.scaleFactor
    }
    /// « Largeur » : la largeur de page = la largeur disponible.
    func fitWidth() {
        guard let v = view, let p = v.currentPage ?? v.document?.page(at: 0) else { return }
        v.autoScales = false
        let w = p.bounds(for: v.displayBox).width
        if w > 0 { v.scaleFactor = max(0.25, min(4, (v.bounds.width - 20) / w)) }
        scale = v.scaleFactor
    }
    func go(_ d: PDFDestination) { view?.go(to: d) }
    func show(_ s: PDFSelection) { view?.setCurrentSelection(s, animate: true); view?.go(to: s) }
    func highlight(_ s: [PDFSelection]) {
        for x in s { x.color = PlatformColor.systemYellow.withAlphaComponent(0.45) }
        view?.highlightedSelections = s
    }
}

#if os(iOS)
typealias PlatformColor = UIColor
struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    let controller: PDFController
    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        configure(v, context.coordinator)
        return v
    }
    func updateUIView(_ v: PDFView, context: Context) { if v.document !== document { v.document = document } }
    func makeCoordinator() -> LinkGuard { LinkGuard() }
    private func configure(_ v: PDFView, _ c: LinkGuard) {
        v.document = document
        v.displayMode = .singlePageContinuous
        v.displayDirection = .vertical
        v.autoScales = true
        v.backgroundColor = .secondarySystemBackground
        v.delegate = c
        controller.view = v
    }
}
#else
typealias PlatformColor = NSColor
struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    let controller: PDFController
    func makeNSView(context: Context) -> PDFView {
        let v = PDFView()
        v.document = document
        v.displayMode = .singlePageContinuous
        v.autoScales = true
        v.delegate = context.coordinator
        controller.view = v
        return v
    }
    func updateNSView(_ v: PDFView, context: Context) { if v.document !== document { v.document = document } }
    func makeCoordinator() -> LinkGuard { LinkGuard() }
}
#endif

/// Liens externes : http(s), mailto, tel SEULEMENT (jamais javascript: ni data:) — comme la PWA.
final class LinkGuard: NSObject, PDFViewDelegate {
    func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
        guard let s = url.scheme?.lowercased(), ["http", "https", "mailto", "tel"].contains(s) else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #else
        NSWorkspace.shared.open(url)
        #endif
    }
}
