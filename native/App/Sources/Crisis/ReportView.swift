import SwiftUI
import WebKit
import AidesCore

// COMPTE-RENDU DE SESSION (`exportSessionReport`, B1 §25) — le DOCUMENT autonome du cœur
// (`Report.document`, toutes valeurs échappées) affiché dans une vue web, puis enregistré en PDF
// (`WKWebView.createPDF`) ou partagé en .html. JAMAIS automatique : chaque sortie répond à un geste.

struct ReportView: View {
    let sessionId: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var holder = CrWebHolder()
    @State private var pdfURL: URL?
    @State private var htmlURL: URL?
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Group {
                if let doc = document {
                    CrWebView(html: doc.html, holder: holder)
                        .background(T.paper)
                        .onAppear { htmlURL = writeHTML(doc) }
                } else {
                    Text("⚠ Session introuvable.").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Compte-rendu de session")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel("Fermer")
                }
                if document != nil {
                    ToolbarItemGroup(placement: .primaryAction) {
                        if let htmlURL {
                            ShareLink(item: htmlURL) { Label("Fichier .html", systemImage: "chevron.left.forwardslash.chevron.right") }
                        }
                        if let pdfURL {
                            ShareLink(item: pdfURL) { Label("Partager le PDF", systemImage: "square.and.arrow.up") }
                        } else {
                            Button { makePDF() } label: { Label("Enregistrer en PDF", systemImage: "doc.richtext") }
                                .disabled(busy)
                        }
                    }
                }
            }
        }
    }

    private var document: (html: String, fileName: String)? {
        guard let s = model.library.session(sessionId) ?? model.sessions.first(where: { $0["id"]?.string == sessionId }) else { return nil }
        let f = s["ficheId"]?.string.flatMap { id in model.fiches.first { $0.id == id } }
        return Report.document(session: s, fiche: f, tags: model.library.tags, appVersion: AppModel.appVersion)
    }

    private func writeHTML(_ doc: (html: String, fileName: String)) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName + ".html")
        do { try Data(doc.html.utf8).write(to: url, options: .atomic); return url } catch { return nil }
    }

    /// « Enregistrer en PDF » : le document rendu, puis la feuille de partage système.
    private func makePDF() {
        guard let web = holder.web, let doc = document else { return }
        busy = true
        web.createPDF(configuration: WKPDFConfiguration()) { result in
            Task { @MainActor in
                busy = false
                switch result {
                case .success(let data):
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(doc.fileName + ".pdf")
                    if (try? data.write(to: url, options: .atomic)) != nil { pdfURL = url }
                    else { model.toast("⚠ Sortie PDF indisponible sur ce navigateur — utilisez « Fichier .html », lisible partout.", seconds: 9) }
                case .failure:
                    model.toast("⚠ Sortie PDF indisponible sur ce navigateur — utilisez « Fichier .html », lisible partout.", seconds: 9)
                }
            }
        }
    }
}

/// Référence à la vue web (pour `createPDF`), gardée hors observation.
final class CrWebHolder {
    weak var web: WKWebView?
}

#if canImport(UIKit)
struct CrWebView: UIViewRepresentable {
    let html: String
    let holder: CrWebHolder
    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.defaultWebpagePreferences.allowsContentJavaScript = false
        let w = WKWebView(frame: .zero, configuration: cfg)
        w.isOpaque = false
        holder.web = w
        w.loadHTMLString(html, baseURL: nil)
        context.coordinator.last = html
        return w
    }
    func updateUIView(_ w: WKWebView, context: Context) {
        holder.web = w
        if context.coordinator.last != html { context.coordinator.last = html; w.loadHTMLString(html, baseURL: nil) }
    }
    func makeCoordinator() -> Coord { Coord() }
    final class Coord { var last = "" }
}
#elseif canImport(AppKit)
struct CrWebView: NSViewRepresentable {
    let html: String
    let holder: CrWebHolder
    func makeNSView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.defaultWebpagePreferences.allowsContentJavaScript = false
        let w = WKWebView(frame: .zero, configuration: cfg)
        holder.web = w
        w.loadHTMLString(html, baseURL: nil)
        context.coordinator.last = html
        return w
    }
    func updateNSView(_ w: WKWebView, context: Context) {
        holder.web = w
        if context.coordinator.last != html { context.coordinator.last = html; w.loadHTMLString(html, baseURL: nil) }
    }
    func makeCoordinator() -> Coord { Coord() }
    final class Coord { var last = "" }
}
#endif
