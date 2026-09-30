import SwiftUI
import PDFKit
import AidesCore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// LES ANNEXES D'UNE RÉFÉRENCE — documents PDF joints (`attListHtml`, vignette de la 1ʳᵉ page,
// « △ à télécharger »), documents trouvés par la recherche (`pfDocsRun`), « Voir aussi »
// (`relRowHtml`), « Références » (sources), agrandissement d'une image (`openLightbox`),
// impression / enregistrement en PDF (`exportPdfCurrent`).

// MARK: - Documents joints

struct RefDocsCard: View {
    let docs: [Attachment]
    var open: (Attachment) -> Void

    var body: some View {
        WorkCard(padding: 12) {
            VStack(alignment: .leading, spacing: 4) {
                RefSectionTitle(icon: "doc.text", text: "Documents (\(docs.count))")
                    .padding(.horizontal, 4)
                ForEach(docs) { a in
                    RefDocRow(a: a) { open(a) }
                }
            }
        }
    }
}

/// Une rangée de document : vignette, nom, poids ; « △ à télécharger » quand le binaire n'est
/// pas encore sur l'appareil (ajouté ailleurs — consultable dès la prochaine synchro).
struct RefDocRow: View {
    @Environment(AppModel.self) private var model
    let a: Attachment
    var open: () -> Void

    var body: some View {
        let local = model.library.space.attachmentURL(a.id) != nil
        Button(action: open) {
            HStack(spacing: 12) {
                RefDocThumb(id: a.id, local: local)
                VStack(alignment: .leading, spacing: 2) {
                    Text(a.name.isEmpty ? "document.pdf" : a.name)
                        .aFont(TypeScale.item, .semibold).foregroundStyle(T.ink)
                        .multilineTextAlignment(.leading).lineLimit(2)
                    HStack(spacing: 8) {
                        if a.size > 0 { Text(Txt.fmtBytes(Double(a.size))).aFont(TypeScale.meta, .regular, .mono).foregroundStyle(T.ink2) }
                        if !local {
                            Text("△ à télécharger").aFont(TypeScale.meta, .bold).foregroundStyle(T.warn)
                                .help("Ajouté sur un autre appareil — sera téléchargé à la prochaine synchronisation avec du réseau ; pas encore consultable hors ligne ici.")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(T.ink3)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 4).padding(.vertical, 6)
            .frame(minHeight: Ctrl.row)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ouvrir le document " + (a.name.isEmpty ? "document.pdf" : a.name) + (local ? "" : ", pas encore téléchargé sur cet appareil"))
    }
}

/// Vignette de la première page, générée seulement quand la rangée est à l'écran (la règle de la
/// PWA : une vignette compte comme une ouverture). Cache de session, une entrée par document.
struct RefDocThumb: View {
    let id: String
    let local: Bool
    @Environment(AppModel.self) private var model
    @State private var img: RefPlatformImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous).fill(T.amb2)
            if let img {
                Image(refPlatform: img).resizable().scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                Image(systemName: "doc").font(.system(size: 16, weight: .semibold)).foregroundStyle(T.ink2)
            }
        }
        .frame(width: 36, height: 46)
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(T.line))
        .accessibilityHidden(true)
        .task(id: id + (local ? "1" : "0")) {
            guard local else { return }
            img = RefThumbs.thumb(id, url: model.library.space.attachmentURL(id))
        }
    }
}

@MainActor
enum RefThumbs {
    private static var cache: [String: RefPlatformImage] = [:]
    static func thumb(_ id: String, url: URL?) -> RefPlatformImage? {
        if let c = cache[id] { return c }
        guard let url, let d = PDFDocument(url: url), let p = d.page(at: 0) else { return nil }
        let t = p.thumbnail(of: CGSize(width: 72, height: 92), for: .mediaBox)
        cache[id] = t
        return t
    }
}

// MARK: - Documents trouvés par la recherche (`pfDocsRun`)

/// Un document dont des pages contiennent TOUS les termes (≥ 2 caractères) : pages annoncées
/// (6 au plus, puis « +n »), tap = visionneuse à la page, occurrences surlignées. Rien du
/// CONTENU n'est affiché ici.
struct RefDocHit: Hashable, Identifiable {
    var id: String
    var name: String
    var pages: [Int]      // 1-based
    var terms: [String]
}

struct RefDocHitRow: View {
    let hit: RefDocHit
    var open: () -> Void
    private static let shown = 6   // PG_SHOWN

    var body: some View {
        Button(action: open) {
            HStack(spacing: 10) {
                Image(systemName: "doc.text.magnifyingglass").font(.system(size: 16, weight: .semibold)).foregroundStyle(T.act)
                    .frame(width: 24).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(hit.name.isEmpty ? "document.pdf" : hit.name).aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                        .multilineTextAlignment(.leading).lineLimit(2)
                    Text(sub).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(T.ink3)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 6)
            .frame(minHeight: Ctrl.row)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    private var sub: String {
        let n = hit.pages.count
        let pp = hit.pages.prefix(Self.shown).map(String.init).joined(separator: ", ")
        let more = n > Self.shown ? " +\(n - Self.shown)" : ""
        return "\(n) passage\(n > 1 ? "s" : "") · p. \(pp)\(more)"
    }
}

/// Texte normalisé des pages d'un PDF (lu une fois par document et par ouverture de la vue),
/// hors du fil principal : un PDF de 200 pages ne gèle pas la frappe.
enum RefPdfText {
    static func pages(_ url: URL) async -> [String] {
        await Task.detached(priority: .utility) { () -> [String] in
            guard let d = PDFDocument(url: url) else { return [] }
            var out: [String] = []
            out.reserveCapacity(d.pageCount)
            for i in 0..<d.pageCount { out.append(Txt.txNorm(d.page(at: i)?.string ?? "")) }
            return out
        }.value
    }
    /// Pages (1-based) qui contiennent tous les termes.
    static func search(_ pages: [String], _ terms: [String]) -> [Int] {
        guard !terms.isEmpty else { return [] }
        var out: [Int] = []
        for (i, t) in pages.enumerated() where terms.allSatisfy({ t.contains($0) }) { out.append(i + 1) }
        return out
    }
}

// MARK: - « Voir aussi » et « Références »

struct RefRelated: Identifiable {
    var id: String
    var title: String
    var isReference: Bool
}

struct RefLinksCard: View {
    let rel: [RefRelated]
    var open: (String) -> Void

    var body: some View {
        WorkCard(padding: 12) {
            VStack(alignment: .leading, spacing: 4) {
                RefSectionTitle(icon: "link", text: "Voir aussi (\(rel.count))").padding(.horizontal, 4)
                ForEach(rel) { r in
                    Button { open(r.id) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: r.isReference ? "book.closed" : "checklist")
                                .font(.system(size: 15, weight: .semibold)).foregroundStyle(T.act)
                                .frame(width: 24).accessibilityHidden(true)
                            Text(r.title.isEmpty ? "Sans titre" : r.title).aFont(TypeScale.item, .semibold).foregroundStyle(T.ink)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "arrow.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(T.ink3)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, 4).padding(.vertical, 6)
                        .frame(minHeight: Ctrl.row)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel((r.isReference ? "Protocole : " : "Aide cognitive : ") + (r.title.isEmpty ? "Sans titre" : r.title))
                }
            }
        }
    }
}

struct RefSourcesCard: View {
    let sources: [String]
    var body: some View {
        WorkCard {
            VStack(alignment: .leading, spacing: 8) {
                RefSectionTitle(icon: "text.book.closed", text: "Références")
                ForEach(sources.indices, id: \.self) { i in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(i + 1).").aFont(TypeScale.body, .semibold, .mono).foregroundStyle(T.ink2)
                        BoldText(text: sources[i], size: TypeScale.body, color: T.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }
}

struct RefSectionTitle: View {
    var icon: String
    var text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(T.ink2)
                .accessibilityHidden(true)
            Text(text).aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Agrandissement d'une image (`openLightbox`)

struct RefLightboxItem: Identifiable {
    let id = UUID()
    var image: ImageRef
    var caption: String
}

struct RefLightbox: View {
    let item: RefLightboxItem
    @Environment(\.dismiss) private var dismiss
    @State private var zoom: CGFloat = 1
    @State private var base: CGFloat = 1

    var body: some View {
        NavigationStack {
            GeometryReader { g in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    VStack(spacing: 12) {
                        if let img = RefImages.image(item.image) {
                            Image(refPlatform: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: max(1, (g.size.width - 32) * zoom))
                                .accessibilityLabel(item.caption.isEmpty ? "Image agrandie" : item.caption)
                        }
                        if !item.caption.isEmpty {
                            Text(item.caption).aFont(TypeScale.body, .medium).foregroundStyle(Color(hex: 0xcfe0dd))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(16)
                    .frame(minWidth: g.size.width, minHeight: g.size.height)
                }
                .gesture(MagnifyGesture()
                    .onChanged { v in zoom = min(4, max(1, base * v.magnification)) }
                    .onEnded { _ in base = zoom })
                .onTapGesture(count: 2) { withAnimation { zoom = zoom > 1 ? 1 : 2; base = zoom } }
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Fermer l’image")
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Impression / « Enregistrer en PDF » (`exportPdfCurrent`)

/// Le document imprimé = le rendu de la PWA (`Markdown.renderHTML`, à l'octet) dans une page
/// sobre : titre, méta, notice d'état, documents, corps, « Voir aussi », références. Le nom du
/// PDF enregistré est le TITRE de la référence (A393), pas le nom de l'application.
enum RefPrint {
    static func html(_ p: Reference, meta: String, notice: String?, docs: [String], rel: [String]) -> String {
        let body = Markdown.renderHTML(p.body, images: p.images) { name in
            switch name { case "check": return "✓ "; case "warn": return "⚠ "; case "info": return "ⓘ "; default: return "" }
        }
        var h = "<!doctype html><html lang=\"fr\"><head><meta charset=\"utf-8\"><title>\(Txt.esc(p.title))</title><style>"
        h += "body{font:15px/1.6 -apple-system,system-ui,sans-serif;color:#14181d;margin:0}"
        h += "h1.t{font-size:24px;margin:0 0 4px}.m{font-size:12px;color:#5b6472;margin:0 0 12px}"
        h += ".n{border:1px solid #eddfb6;border-left:4px solid #b45309;background:#fbf3dc;padding:6px 10px;border-radius:8px;margin:0 0 12px}"
        h += "h1,h2,h3{font-size:17px;margin:16px 0 4px}h3{font-size:15px}"
        h += "table{border-collapse:collapse;width:100%;font-size:13px}th,td{border-bottom:1px solid #e3e6ea;padding:6px 8px;text-align:left;vertical-align:top}"
        h += "th{background:#eceef1;font-size:11px;text-transform:uppercase}.ta-c{text-align:center}.ta-r{text-align:right}"
        h += "blockquote{margin:0 0 10px;padding:6px 12px;border-left:3px solid #c3ccd6;color:#5b6472}"
        h += ".md-call{border:1px solid #c3ccd6;border-left-width:4px;border-radius:8px;color:#14181d}.mc-k{display:block;font-size:11px;font-weight:800;text-transform:uppercase}"
        h += ".md-call.crit{border-left-color:#c43d34}.md-call.vig{border-left-color:#b45309}.md-call.info{border-left-color:#17477f}.md-call.ok{border-left-color:#1d7a38}"
        h += "pre{background:#eceef1;padding:8px 10px;border-radius:8px;font-size:12px;white-space:pre-wrap}"
        h += "img{max-width:100%;height:auto}.w25 img{width:25%}.w33 img{width:33%}.w50 img{width:50%}.w66 img{width:66%}.w75 img{width:75%}"
        h += "figcaption{font-size:12px;color:#5b6472}.md-mk{background:#eceef1}li.md-task{list-style:none}.md-tkbox{display:none}"
        h += ".md-task .md-tktxt::before{content:'☐ '}.md-task.done .md-tktxt::before{content:'☑ '}"
        h += ".s{margin-top:16px;font-size:13px}.s b{display:block;margin-bottom:4px}"
        h += "</style></head><body>"
        h += "<h1 class=\"t\">\(Txt.esc(p.title.isEmpty ? "Sans titre" : p.title))</h1>"
        if !meta.isEmpty { h += "<p class=\"m\">\(Txt.esc(meta))</p>" }
        if let notice { h += "<div class=\"n\">\(Txt.esc(notice))</div>" }
        if !docs.isEmpty {
            h += "<div class=\"s\"><b>Documents (\(docs.count))</b><ul>" + docs.map { "<li>" + Txt.esc($0) + "</li>" }.joined() + "</ul></div>"
        }
        h += body
        if !rel.isEmpty {
            h += "<div class=\"s\"><b>Voir aussi (\(rel.count))</b><ul>" + rel.map { "<li>" + Txt.esc($0) + "</li>" }.joined() + "</ul></div>"
        }
        let refs = Txt.clean(p.sources)
        if !refs.isEmpty {
            h += "<div class=\"s\"><b>Références</b><ol>" + refs.map { "<li>" + Txt.boldRx.replace(Txt.esc($0), "<b>$1</b>") + "</li>" }.joined() + "</ol></div>"
        }
        return h + "</body></html>"
    }

    @MainActor
    static func run(title: String, html: String) {
        let job = title.isEmpty ? "Protocole" : title
        #if os(iOS)
        let pc = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = job
        pc.printInfo = info
        pc.printFormatter = UIMarkupTextPrintFormatter(markupText: html)
        pc.present(animated: true, completionHandler: nil)
        #elseif os(macOS)
        guard let data = html.data(using: .utf8),
              let attr = NSAttributedString(html: data, documentAttributes: nil) else { return }
        let info = (NSPrintInfo.shared.copy() as? NSPrintInfo) ?? NSPrintInfo.shared
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic
        let w = info.paperSize.width - info.leftMargin - info.rightMargin
        let tv = NSTextView(frame: NSRect(x: 0, y: 0, width: w, height: 100))
        tv.isVerticallyResizable = true
        tv.textStorage?.setAttributedString(attr)
        if let lm = tv.layoutManager, let tc = tv.textContainer { lm.ensureLayout(for: tc) }
        tv.sizeToFit()
        let op = NSPrintOperation(view: tv, printInfo: info)
        op.jobTitle = job
        op.run()
        #endif
    }
}
