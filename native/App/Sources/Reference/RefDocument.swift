import SwiftUI
import AidesCore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// LECTURE D'UNE RÉFÉRENCE — la logique sans vue : structure des sections (`mdFoldApply`),
// mémoire des replis (`mdFoldGet`/`mdFoldSet`), recherche DANS la référence (`pfRun`,
// `pfSyncFind`), rendu en ligne (`mdInline`) en texte attribué, images (data-URI).
// Le cœur (`Markdown.document`) a déjà tout découpé : on ne fait ici que l'INTERACTIF, que la
// PWA pose aussi APRÈS le rendu (le parseur reste pur et non interactif — doctrine-js J92).

// MARK: - Structure : sections repliables et sommaire

/// Une entrée du sommaire (`.md-h1, .md-h2` seulement, comme `renderProtocolRead`).
struct RefTocEntry: Identifiable, Equatable {
    var block: Int
    var level: Int
    var title: String
    var id: Int { block }
}

/// La géométrie des sections, calculée UNE fois par corps (elle ne dépend que du texte).
struct RefLayout {
    let blocks: [Markdown.RBlock]
    /// Titre repliable (bloc) → fin exclusive de sa section. Un titre sans corps n'y est pas
    /// (`mdFoldApply` : « un titre sans corps ne se replie pas : aucun bouton mort »).
    let sectionEnd: [Int: Int]
    /// Pour chaque bloc, les titres repliables dont la section le contient (ses « ancêtres »).
    let ancestors: [[Int]]
    let toc: [RefTocEntry]

    init(_ blocks: [Markdown.RBlock]) {
        self.blocks = blocks
        var end: [Int: Int] = [:]
        var toc: [RefTocEntry] = []
        for (i, b) in blocks.enumerated() {
            guard case .heading(let h) = b else { continue }
            if h.level <= 2 { toc.append(RefTocEntry(block: i, level: h.level, title: Markdown.plainText(h.content))) }
            guard h.foldKey != nil else { continue }
            var j = i + 1
            while j < blocks.count {
                if case .heading(let n) = blocks[j], n.level <= h.level { break }
                j += 1
            }
            end[i] = j
        }
        var anc = Array(repeating: [Int](), count: blocks.count)
        for (i, e) in end { for j in (i + 1)..<max(i + 1, e) { anc[j].append(i) } }
        for j in anc.indices { anc[j].sort() }
        sectionEnd = end
        ancestors = anc
        self.toc = toc
    }

    func heading(_ i: Int) -> Markdown.RHeading? {
        guard i >= 0, i < blocks.count, case .heading(let h) = blocks[i] else { return nil }
        return h
    }
    /// Tous les titres repliables, dans l'ordre du document.
    var foldable: [Int] { sectionEnd.keys.sorted() }
}

// MARK: - Mémoire des replis (par référence, préférence LOCALE de l'espace)

/// `mdFoldGet`/`mdFoldSet` : les clés des sections REPLIÉES, par référence. Jamais dans la donnée
/// (une préférence locale), bornée aux `MD_FOLD_MAX` = 50 dernières références écrites — la plus
/// ancienne part la première. Rangée en tableau ordonné (un dictionnaire Swift ne garde pas
/// l'ordre d'insertion sur lequel la PWA fonde sa borne).
enum RefFoldStore {
    static let key = "ac-fold"
    static let max = 50

    @MainActor
    static func get(_ model: AppModel, _ id: String) -> Set<String> {
        guard let arr = model.library.space.prefs[key]?.array else { return [] }
        for e in arr where e["id"]?.string == id {
            return Set((e["k"]?.array ?? []).compactMap(\.string))
        }
        return []
    }
    @MainActor
    static func set(_ model: AppModel, _ id: String, _ closed: Set<String>) {
        var arr = (model.library.space.prefs[key]?.array ?? []).filter { $0["id"]?.string != id }
        if !closed.isEmpty {
            arr.append(.object(["id": .string(id), "k": .array(closed.sorted().map { .string($0) })]))
        }
        if arr.count > max { arr.removeFirst(arr.count - max) }
        model.library.space.prefs[key] = .array(arr)
    }
}

// MARK: - Recherche dans la référence (`pfRun`)

/// Une unité de lecture : la cible d'un défilement (ligne de paragraphe, item de liste, rangée de
/// tableau, titre, bloc de code, légende). `b` = bloc, `s` = sous-partie.
struct RefUnit: Hashable {
    var b: Int
    var s: Int
    var anchor: String { "u\(b)-\(s)" }
}

/// Une partie de texte cherchable : de l'en-ligne, ou du texte brut (code, légende).
enum RefPart {
    case inl([Markdown.Inline])
    case raw(String)
}

/// Les unités d'un bloc, dans l'ordre de lecture — LA MÊME énumération sert au compte des
/// occurrences et au rendu (sinon « 3 / 7 » désignerait une autre marque que celle surlignée).
func refUnits(_ block: Markdown.RBlock, at b: Int) -> [(RefUnit, [RefPart])] {
    switch block {
    case .heading(let h): return [(RefUnit(b: b, s: 0), [.inl(h.content)])]
    case .paragraph(let lines): return lines.enumerated().map { (RefUnit(b: b, s: $0.offset), [.inl($0.element)]) }
    case .list(_, let items):
        return items.enumerated().map { k, it in
            var parts: [RefPart] = [.inl(it.content)]
            if let sub = it.sub { parts += sub.items.map { .inl($0) } }
            return (RefUnit(b: b, s: k), parts)
        }
    case .quote(_, let lines): return lines.enumerated().map { (RefUnit(b: b, s: $0.offset), [.inl($0.element)]) }
    case .code(let s): return [(RefUnit(b: b, s: 0), [.raw(s)])]
    case .hr: return []
    case .image(_, let caption): return caption.isEmpty ? [] : [(RefUnit(b: b, s: 0), [.raw(caption)])]
    case .table(_, let head, let rows):
        var out: [(RefUnit, [RefPart])] = [(RefUnit(b: b, s: 0), head.map { .inl($0) })]
        for (r, row) in rows.enumerated() { out.append((RefUnit(b: b, s: r + 1), row.map { .inl($0) })) }
        return out
    }
}

/// La recherche en cours : requête NORMALISÉE (`txNorm`), cherchée d'un bloc comme UNE chaîne
/// (`pfRun` ne découpe pas en termes) dans chaque nœud de texte séparément ; ≥ 2 caractères.
struct RefFind: Equatable {
    var q: String = ""
    /// Index global de l'occurrence visée (‹ ›).
    var cur: Int = 0
    var active: Bool { !q.isEmpty }

    static func normalized(_ raw: String) -> String {
        let s = Txt.txNorm(raw.trimmingCharacters(in: .whitespacesAndNewlines))
        return JS.length(s) >= 2 ? s : ""
    }
    func ranges(_ s: String) -> [Range<Int>] { active ? Search.markRanges(s, [q]) : [] }
    func count(_ ns: [Markdown.Inline]) -> Int {
        guard active else { return 0 }
        var n = 0
        for x in ns {
            switch x {
            case .text(let s), .code(let s): n += ranges(s).count
            case .bold(let k), .italic(let k), .mark(let k): n += count(k)
            case .link(_, let k), .attachment(_, let k): n += count(k)
            }
        }
        return n
    }
    func count(_ p: RefPart) -> Int {
        switch p { case .inl(let ns): return count(ns); case .raw(let s): return ranges(s).count }
    }
}

/// L'index des occurrences d'un document pour une requête : premier numéro de chaque unité,
/// unité de chaque occurrence, compte par section (le badge du sommaire, `pfSyncFind`).
struct RefHits {
    var start: [RefUnit: Int] = [:]
    var units: [RefUnit] = []
    var perBlock: [Int: Int] = [:]
    var total: Int { units.count }

    init() {}
    init(_ layout: RefLayout, _ find: RefFind) {
        guard find.active else { return }
        for (b, block) in layout.blocks.enumerated() {
            for (u, parts) in refUnits(block, at: b) {
                let n = parts.reduce(0) { $0 + find.count($1) }
                start[u] = units.count
                if n > 0 {
                    units += Array(repeating: u, count: n)
                    perBlock[b, default: 0] += n
                }
            }
        }
    }
    /// Occurrences dans le titre ET sa section (sous-sections comprises).
    func inSection(_ layout: RefLayout, _ i: Int) -> Int {
        let e = layout.sectionEnd[i] ?? (i + 1)
        var n = 0
        for j in i..<e { n += perBlock[j] ?? 0 }
        return n
    }
}

// MARK: - En-ligne → texte attribué (`mdInline`), occurrences surlignées

/// Rendu d'un arbre en ligne. Les liens web restent des liens (ouverts hors de l'app par le
/// système) ; un lien `att:ID` devient une URL interne interceptée par la vue (visionneuse PDF).
/// Le surligné `==…==` est ACHROMATIQUE (registre MEMO : jamais une couleur qui veut dire « ça
/// tue » ou « on s'y trompe »). L'occurrence de recherche prend l'ambre doux de `mark.pf-h`, et
/// l'occurrence visée un fond plus soutenu, du gras et un soulignement — jamais la couleur seule
/// (la pastille dit aussi « 3 / 7 »).
struct RefInline {
    static let attScheme = "aidesref-att"

    var find: RefFind
    /// Premier numéro global des occurrences de cette partie.
    var base: Int

    func attributed(_ part: RefPart) -> AttributedString {
        var k = base
        var out = AttributedString()
        switch part {
        case .inl(let ns): append(ns, &out, &k, Style())
        case .raw(let s): leaf(s, &out, &k, Style())
        }
        return out
    }

    struct Style {
        var intent: InlinePresentationIntent = []
        var mark = false
        var code = false
        var link: URL? = nil
    }

    private func append(_ ns: [Markdown.Inline], _ out: inout AttributedString, _ k: inout Int, _ st: Style) {
        for x in ns {
            switch x {
            case .text(let s): leaf(s, &out, &k, st)
            case .code(let s):
                var c = st; c.code = true; c.intent.insert(.code)
                leaf(s, &out, &k, c)
            case .bold(let kids):
                var c = st; c.intent.insert(.stronglyEmphasized)
                append(kids, &out, &k, c)
            case .italic(let kids):
                var c = st; c.intent.insert(.emphasized)
                append(kids, &out, &k, c)
            case .mark(let kids):
                var c = st; c.mark = true
                append(kids, &out, &k, c)
            case .link(let url, let kids):
                var c = st
                if let u = URL(string: url), let sc = u.scheme?.lowercased(), sc == "http" || sc == "https" { c.link = u }
                append(kids, &out, &k, c)
            case .attachment(let id, let kids):
                var c = st
                var comp = URLComponents(); comp.scheme = Self.attScheme; comp.host = "doc"
                comp.queryItems = [URLQueryItem(name: "id", value: id)]
                c.link = comp.url
                append(kids, &out, &k, c)
            }
        }
    }

    private func leaf(_ s: String, _ out: inout AttributedString, _ k: inout Int, _ st: Style) {
        let rs = find.ranges(s)
        let u = Array(s.utf16)
        var p = 0
        func piece(_ a: Int, _ b: Int, hit: Int?) {
            guard b > a else { return }
            var t = AttributedString(String(decoding: u[a..<b], as: UTF16.self))
            var intent = st.intent
            if st.mark { t.backgroundColor = T.amb2; t.foregroundColor = T.ink2 }
            if st.code { t.backgroundColor = T.amb2 }
            if let l = st.link { t.link = l; t.foregroundColor = T.act; t[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] = .single }
            if let h = hit {
                if h == find.cur {
                    t.backgroundColor = T.bolt
                    t.foregroundColor = T.onSysFill
                    t[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] = .single
                    intent.insert(.stronglyEmphasized)
                } else {
                    t.backgroundColor = T.warnSoft
                    t.foregroundColor = T.ink
                }
            }
            if !intent.isEmpty { t.inlinePresentationIntent = intent }
            out += t
        }
        for r in rs {
            let a = min(max(r.lowerBound, p), u.count), b = min(r.upperBound, u.count)
            piece(p, a, hit: nil)
            piece(a, b, hit: k)
            k += 1
            p = b
        }
        piece(p, u.count, hit: nil)
    }
}

// MARK: - Images (data-URI validées par `safeImg` dans le cœur)

#if canImport(UIKit)
typealias RefPlatformImage = UIImage
#elseif canImport(AppKit)
typealias RefPlatformImage = NSImage
#endif

extension Image {
    init(refPlatform img: RefPlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: img)
        #else
        self.init(nsImage: img)
        #endif
    }
}

/// Décodage des images du contenu rédigé : une fois par image (le base64 d'une photo pèse
/// plusieurs centaines de Ko ; le redécoder à chaque passage du corps serait ruineux).
@MainActor
enum RefImages {
    private static var cache: [String: RefPlatformImage] = [:]
    private static var order: [String] = []

    static func image(_ im: ImageRef) -> RefPlatformImage? {
        let key = im.id + ":" + String(im.data.utf8.count)
        if let c = cache[key] { return c }
        guard let comma = im.data.firstIndex(of: ","),
              let data = Data(base64Encoded: String(im.data[im.data.index(after: comma)...]), options: .ignoreUnknownCharacters),
              let img = RefPlatformImage(data: data) else { return nil }
        cache[key] = img
        order.append(key)
        if order.count > 40 { cache[order.removeFirst()] = nil }
        return img
    }
}
