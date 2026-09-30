import Foundation

// MINI-MARKDOWN DES RÉFÉRENCES — port de la section « Mini-Markdown » d'`index.html`
// (`mdBlocks`, `mdInline`, `mdRender`, `mdStrip`, `mdCells`, `mdCallout`, `mdTask`, `mdFoldApply`).
//
// DEUX ÉTAGES, comme la PWA :
//  1. `blocks(_:)` = `mdBlocks` : découpe ligne à ligne en blocs dont le texte reste BRUT. C'est la
//     structure que la PWA teste et sur laquelle l'oracle compare, champ pour champ.
//  2. `document(_:images:)` = ce que `mdRender` affiche, sous forme d'ARBRE typé pour SwiftUI :
//     l'en-ligne est analysé (`inline`), les images résolues, les tâches numérotées (`data-task`),
//     et les titres repliables reçoivent la clé que `mdFoldApply` leur donne (mémoire des replis
//     partagée entre appareils : même clé des deux côtés).
//
// L'EN-LIGNE EST PRODUIT COMME LE WEB LE PRODUIT : `inlineHTML` rejoue `mdInline` à l'octet
// (échappement d'abord, puis liens, gras, italique, surligné — mêmes motifs, même ordre), puis
// `inline` relit ce HTML au jeu de balises FERMÉ qu'il peut contenir. Reconstruire un arbre « à
// côté » aurait divergé sur les cas limites que la PWA tranche par l'ordre de ses remplacements
// (« ***a** », un `*` dans une URL…) ; ainsi l'arbre natif dit exactement ce que le navigateur
// affiche. Aucune donnée utilisateur n'atteint un attribut ou une classe : registre d'encadré et
// alignement de colonne sont des énumérations fermées, comme dans la PWA.

public enum Markdown {
    /// `MD_MAX_CHARS` / `MD_MAX_LINES` : plafonds anti-DoS.
    public static let maxChars = 20000
    public static let maxLines = 2000
    /// `MD_MAX_TCOLS` / `MD_MAX_TROWS`.
    public static let maxTableCols = 12
    public static let maxTableRows = 200
    /// `MD_SCALES` : tailles d'image admises (jeu fermé).
    public static let scales = [25, 33, 50, 66, 75, 100]

    /// Registre d'un encadré (`MD_CALL` → 'crit' | 'vig' | 'info' | 'ok').
    public enum Callout: String, Sendable, CaseIterable {
        case crit, vig, info, ok
        /// `MD_CALL_LBL` : la couleur n'est jamais seule, le registre s'écrit en toutes lettres.
        public var label: String {
            switch self { case .crit: return "Alerte"; case .vig: return "Attention"; case .info: return "Information"; case .ok: return "Confirmation" }
        }
    }
    /// Alignement d'une colonne de tableau ('' | 'l' | 'c' | 'r').
    public enum Align: String, Sendable { case none = "", left = "l", center = "c", right = "r" }

    /// Sous-liste d'UN niveau (items bruts, jamais des tâches).
    public struct SubList: Equatable, Sendable { public var ordered: Bool; public var items: [String] }
    /// Item de liste brut ; `done` non nil = tâche « [ ] »/« [x] ».
    public struct ListItem: Equatable, Sendable { public var text: String; public var sub: SubList?; public var done: Bool? }

    /// Bloc BRUT — miroir exact de la sortie de `mdBlocks`.
    public enum Block: Equatable, Sendable {
        case heading(level: Int, text: String)
        case paragraph(lines: [String])
        case list(ordered: Bool, items: [ListItem])
        /// `callout` nil = citation neutre.
        case quote(callout: Callout?, lines: [String])
        case code(lines: [String])
        case hr
        case image(caption: String, id: String)
        case table(align: [Align], head: [String], rows: [[String]])
    }

    // MARK: Motifs (recopiés de la PWA)

    static let rxFence = JSRegExp("^```")
    static let rxBlank = JSRegExp(#"^\s*$"#)
    /// `MD_TROW` — pipes ouvrant ET fermant exigés : une phrase avec « | » ne devient jamais un tableau.
    static let rxTRow = JSRegExp(#"^\s*\|.*\|\s*$"#)
    /// `MD_TSEP` — ligne de séparation (porte l'alignement).
    static let rxTSep = JSRegExp(#"^\s*\|(?:\s*:?-{1,}:?\s*\|)+\s*$"#)
    static let rxHeading = JSRegExp(#"^(#{1,3})\s+(.*)$"#)
    static let rxHr = JSRegExp(#"^(---+|\*\*\*+)\s*$"#)
    static let rxImg = JSRegExp(#"^!\[([^\]]{0,300})\]\(img:([A-Za-z0-9_-]{1,64})\)\s*$"#)
    static let rxQuote = JSRegExp(#"^>\s?(.*)$"#)
    static let rxSub = JSRegExp(#"^\s{2,}(?:[-*]\s+|(\d{1,3})[.)]\s+)(.*)$"#)
    static let rxUl = JSRegExp(#"^[-*]\s+(.*)$"#)
    static let rxOl = JSRegExp(#"^\d{1,3}[.)]\s+(.*)$"#)
    /// `MD_TASK_RX` — marqueur STRICT : « [] » ou « [y] » restent du texte visible.
    static let rxTask = JSRegExp(#"^\[( |x|X)\](?:\s+|$)"#)
    static let rxCallWord = JSRegExp(#"^\s*\[!\s*([A-Za-zÀ-ÿ]{2,12})\s*\]\s*(.*)$"#)
    static let rxCallGlyph = JSRegExp(#"^\s*(⚠️|⚠|△|ℹ️|ℹ|✓|✔)\s*(.*)$"#)
    static let rxAlignL = JSRegExp("^:"), rxAlignR = JSRegExp(":$")
    static let rxLeadPipe = JSRegExp(#"^\|"#), rxTrailPipe = JSRegExp(#"\|$"#)

    /// `MD_CALL` : registre par mot (FR/EN, casse indifférente) ou par glyphe.
    static let callMap: [String: Callout] = [
        "caution": .crit, "alerte": .crit, "alert": .crit, "danger": .crit, "⚠": .crit, "⚠️": .crit, "!": .crit,
        "warning": .vig, "attention": .vig, "△": .vig,
        "note": .info, "info": .info, "important": .info, "ℹ": .info, "ℹ️": .info,
        "tip": .ok, "ok": .ok, "astuce": .ok, "✓": .ok, "✔": .ok,
    ]

    // MARK: mdTask / mdCallout / mdCells

    /// `mdTask(text)` : {done, text} si l'item porte un marqueur de tâche, nil sinon.
    public static func task(_ text: String) -> (done: Bool, text: String)? {
        guard let m = rxTask.exec(text) else { return nil }
        return (m[1] != " ", JS.slice(text, m.range.upperBound))
    }

    /// Résultat de `mdCallout` : `kind` nil = citation neutre. `marker` vrai quand un marqueur a été
    /// reconnu et RETIRÉ de la ligne (voir la note sur « [!constructor] » dans `callout`).
    public struct CalloutMatch: Equatable, Sendable { public var kind: Callout?; public var text: String; public var marker: Bool }

    /// `mdCallout(line)` : marqueur de registre en tête de la PREMIÈRE ligne d'une citation.
    /// ⚠ PARITÉ D'UN ACCIDENT DE LA PWA : `MD_CALL` est un objet littéral, donc « [!constructor] »
    /// y trouve `Object.prototype.constructor` (une fonction, vraie) — le marqueur est RETIRÉ mais
    /// aucun registre n'existe, et le rendu est une citation neutre. On le reproduit (`marker` vrai,
    /// `kind` nil) : une référence écrite sur le web se lit pareil sur l'iPhone.
    public static func callout(_ line: String) -> CalloutMatch {
        if let m = rxCallWord.exec(line) {
            let w = JS.toLowerCase(m[1]!)
            if let k = callMap[w] { return CalloutMatch(kind: k, text: m[2]!, marker: true) }
            if w == "constructor" { return CalloutMatch(kind: nil, text: m[2]!, marker: true) }
            return CalloutMatch(kind: nil, text: line, marker: false)
        }
        if let m = rxCallGlyph.exec(line), let k = callMap[m[1]!] { return CalloutMatch(kind: k, text: m[2]!, marker: true) }
        return CalloutMatch(kind: nil, text: line, marker: false)
    }

    /// `mdCells(line)` : cellules d'une ligne de tableau ; « \| » est un pipe littéral.
    public static func cells(_ line: String) -> [String] {
        let s = Array(rxTrailPipe.replace(rxLeadPipe.replace(JS.trim(line), ""), "").utf16)
        var out: [String] = []
        var cur: [UInt16] = []
        var i = 0
        while i < s.count {
            let c = s[i]
            if c == 92, i + 1 < s.count, s[i + 1] == 124 { cur.append(124); i += 2; continue }
            if c == 124 { out.append(JS.trim(JS.str(cur))); cur = []; i += 1; continue }
            cur.append(c); i += 1
        }
        out.append(JS.trim(JS.str(cur)))
        return Array(out.prefix(maxTableCols))
    }

    // MARK: mdBlocks

    /// `mdBlocks(src)` : blocs bruts, ligne à ligne, avec les mêmes priorités que la PWA (code
    /// d'abord — un « | » dans du code ne fait jamais un tableau —, puis tableau, titre, filet,
    /// image, citation, sous-liste, liste, paragraphe).
    public static func blocks(_ src: String) -> [Block] {
        let lines = Array(JS.split(JS.prefix(src, maxChars), "\n").prefix(maxLines))
        var out: [Block] = []
        var listOrdered: Bool? = nil
        var listItems: [ListItem] = []
        var para: [String] = []
        var quote: (Callout?, [String])? = nil
        var code: [String]? = nil
        func flushPara() { if !para.isEmpty { out.append(.paragraph(lines: para)); para = [] } }
        func flushList() { if let o = listOrdered { out.append(.list(ordered: o, items: listItems)); listOrdered = nil; listItems = [] } }
        func flushQuote() { if let q = quote { out.append(.quote(callout: q.0, lines: q.1)); quote = nil } }
        func flushAll() { flushPara(); flushList(); flushQuote() }
        func listItem(_ t: String) -> ListItem {
            if let tk = task(t) { return ListItem(text: tk.text, sub: nil, done: tk.done) }
            return ListItem(text: t, sub: nil, done: nil)
        }
        var i = 0
        while i < lines.count {
            let l = lines[i]
            defer { i += 1 }
            if code != nil {
                if rxFence.test(l) { out.append(.code(lines: code!)); code = nil } else { code!.append(l) }
                continue
            }
            if rxFence.test(l) { flushAll(); code = []; continue }
            if rxBlank.test(l) { flushAll(); continue }
            if rxTRow.test(l), i + 1 < lines.count, rxTSep.test(lines[i + 1]) {
                flushAll()
                let align: [Align] = cells(lines[i + 1]).map { c in
                    let L = rxAlignL.test(c), R = rxAlignR.test(c)
                    return (L && R) ? .center : (R ? .right : (L ? .left : .none))
                }
                let head = cells(l)
                var rows: [[String]] = []
                var j = i + 2
                while j < lines.count, rxTRow.test(lines[j]), !rxTSep.test(lines[j]), rows.count < maxTableRows {
                    rows.append(cells(lines[j])); j += 1
                }
                let n = max(1, min(head.count, maxTableCols))
                func fit(_ r: [String]) -> [String] { var o = Array(r.prefix(n)); while o.count < n { o.append("") }; return o }
                out.append(.table(align: Array(align.prefix(n)), head: fit(head), rows: rows.map(fit)))
                i = j - 1
                continue
            }
            if let m = rxHeading.exec(l) { flushAll(); out.append(.heading(level: JS.length(m[1]!), text: m[2]!)); continue }
            if rxHr.test(l) { flushAll(); out.append(.hr); continue }
            if let m = rxImg.exec(l) { flushAll(); out.append(.image(caption: m[1]!, id: m[2]!)); continue }
            if let m = rxQuote.exec(l) {
                flushPara(); flushList()
                if quote == nil {
                    let c = callout(m[1]!)
                    quote = (c.kind, [])
                    if c.marker { if !c.text.isEmpty { quote!.1.append(c.text) } } else { quote!.1.append(m[1]!) }
                } else { quote!.1.append(m[1]!) }
                continue
            }
            if listOrdered != nil, !listItems.isEmpty, let m = rxSub.exec(l) {
                let st = m[1] != nil
                var last = listItems[listItems.count - 1]
                if last.sub == nil || last.sub!.ordered != st { last.sub = SubList(ordered: st, items: []) }
                last.sub!.items.append(m[2]!)
                listItems[listItems.count - 1] = last
                continue
            }
            if let m = rxUl.exec(l) {
                flushPara(); flushQuote()
                if listOrdered != false { flushList(); listOrdered = false }
                listItems.append(listItem(m[1]!)); continue
            }
            if let m = rxOl.exec(l) {
                flushPara(); flushQuote()
                if listOrdered != true { flushList(); listOrdered = true }
                listItems.append(listItem(m[1]!)); continue
            }
            flushList(); flushQuote(); para.append(l)
        }
        if let c = code { out.append(.code(lines: c)) }   // ``` non refermé : le contenu reste visible
        flushAll()
        return out
    }

    // MARK: mdInline (HTML exact) et arbre en ligne

    static let rxCode = JSRegExp("(`[^`\\n]+`)")
    static let rxLink = JSRegExp(#"\[([^\]\n]{1,200})\]\(([^()\s]{1,500})\)"#, "g")
    static let rxHttp = JSRegExp(#"^https?:\/\/\S+$"#, "i")
    static let rxAtt = JSRegExp(#"^att:([A-Za-z0-9_-]{1,64})$"#)
    static let rxHrefBad = JSRegExp(#"["'<>`]"#, "g")
    /// `MD_ITAL_RX` — *italique* sans manger les ** du gras.
    static let rxItal = JSRegExp(#"(^|[^*])\*([^*\n]+)\*(?!\*)"#, "g")
    /// `MD_MARK_RX` — ==surligné== (registre MEMO, achromatique).
    static let rxMark = JSRegExp(#"==([^=\n]+)=="#, "g")

    /// `mdInline(s)` à l'octet : échappement d'ABORD (XSS impossible par construction), segments
    /// `code` préservés, liens https/http ou `att:ID` seulement (jamais `javascript:`).
    public static func inlineHTML(_ s: String) -> String {
        let h = Txt.esc(JS.prefix(s, 4000))
        return rxCode.split(h).map { seg -> String in
            let u = Array(seg.utf16)
            if u.count > 2, u[0] == 96, u[u.count - 1] == 96 {
                return "<code class=\"md-ci\">" + JS.str(u[1..<(u.count - 1)]) + "</code>"
            }
            var x = rxLink.replace(seg) { m in
                let txt = m[1]!, href = m[2]!
                if rxHttp.test(href) {
                    return "<a href=\"" + rxHrefBad.replace(href, "") + "\" target=\"_blank\" rel=\"noopener noreferrer\">" + txt + "</a>"
                }
                if let am = rxAtt.exec(href), !Guard.badKeys.contains(am[1]!) {
                    return "<a href=\"#\" data-mdatt=\"" + am[1]! + "\">" + txt + "</a>"
                }
                return m[0]!
            }
            x = Txt.boldRx.replace(x, "<b>$1</b>")
            x = rxItal.replace(x, "$1<i>$2</i>")
            x = rxMark.replace(x, "<mark class=\"md-mk\">$1</mark>")
            return x
        }.joined()
    }

    /// Nœud en ligne — tout ce que `mdInline` peut émettre.
    public indirect enum Inline: Equatable, Sendable {
        case text(String)
        case bold([Inline])
        case italic([Inline])
        /// ==surligné== (surligneur achromatique).
        case mark([Inline])
        /// `code` en ligne : texte littéral.
        case code(String)
        /// Lien web (http/https), ouvert hors de l'app.
        case link(url: String, [Inline])
        /// Lien vers un document joint (`att:ID`).
        case attachment(id: String, [Inline])
    }

    /// Arbre en ligne de `s` (relecture de `inlineHTML` au jeu de balises fermé qu'il émet).
    public static func inline(_ s: String) -> [Inline] { parseInline(inlineHTML(s)) }

    enum Tag: Equatable { case b, i, mark, a(String), att(String), root }
    static func parseInline(_ html: String) -> [Inline] {
        let u = Array(html.utf16)
        var stack: [(Tag, [Inline])] = [(.root, [])]
        var text: [UInt16] = []
        func flush() {
            guard !text.isEmpty else { return }
            let t = Txt.unesc(JS.str(text)); text = []
            if case .text(let prev)? = stack[stack.count - 1].1.last {
                stack[stack.count - 1].1[stack[stack.count - 1].1.count - 1] = .text(prev + t)
            } else { stack[stack.count - 1].1.append(.text(t)) }
        }
        func starts(_ lit: String, _ at: Int) -> Bool {
            let l = Array(lit.utf16)
            return at + l.count <= u.count && Array(u[at..<(at + l.count)]) == l
        }
        func close(_ match: (Tag) -> Bool) {
            flush()
            guard let k = stack.lastIndex(where: { match($0.0) }), k > 0 else { return }
            while stack.count > k {
                let (tag, kids) = stack.removeLast()
                let node: Inline
                switch tag {
                case .b: node = .bold(kids)
                case .i: node = .italic(kids)
                case .mark: node = .mark(kids)
                case .a(let url): node = .link(url: url, kids)
                case .att(let id): node = .attachment(id: id, kids)
                case .root: node = .text("")
                }
                stack[stack.count - 1].1.append(node)
            }
        }
        var i = 0
        while i < u.count {
            if u[i] == 60 {   // '<'
                if starts("<b>", i) { flush(); stack.append((.b, [])); i += 3; continue }
                if starts("<i>", i) { flush(); stack.append((.i, [])); i += 3; continue }
                if starts("<mark class=\"md-mk\">", i) { flush(); stack.append((.mark, [])); i += 20; continue }
                if starts("</b>", i) { close { $0 == .b }; i += 4; continue }
                if starts("</i>", i) { close { $0 == .i }; i += 4; continue }
                if starts("</mark>", i) { close { $0 == .mark }; i += 7; continue }
                if starts("</a>", i) {
                    close { if case .a = $0 { return true }; if case .att = $0 { return true }; return false }
                    i += 4; continue
                }
                if starts("<code class=\"md-ci\">", i) {
                    let body = i + 20
                    let end = JS.indexOf(u, Array("</code>".utf16), from: body)
                    if end >= 0 {
                        flush()
                        stack[stack.count - 1].1.append(.code(Txt.unesc(JS.str(u[body..<end]))))
                        i = end + 7; continue
                    }
                }
                if starts("<a href=\"#\" data-mdatt=\"", i) {
                    let v0 = i + 24
                    let q = JS.indexOf(u, [34], from: v0)
                    if q >= 0, q + 1 < u.count, u[q + 1] == 62 {
                        flush(); stack.append((.att(JS.str(u[v0..<q])), [])); i = q + 2; continue
                    }
                }
                if starts("<a href=\"", i) {
                    let v0 = i + 9
                    let tail = "\" target=\"_blank\" rel=\"noopener noreferrer\">"
                    let q = JS.indexOf(u, Array(tail.utf16), from: v0)
                    if q >= 0 {
                        flush(); stack.append((.a(Txt.unesc(JS.str(u[v0..<q]))), [])); i = q + JS.length(tail); continue
                    }
                }
            }
            text.append(u[i]); i += 1
        }
        flush()
        // Balises restées ouvertes (HTML mal imbriqué par un cas limite) : refermées en fin de texte.
        while stack.count > 1 {
            let (tag, kids) = stack.removeLast()
            let node: Inline
            switch tag {
            case .b: node = .bold(kids)
            case .i: node = .italic(kids)
            case .mark: node = .mark(kids)
            case .a(let url): node = .link(url: url, kids)
            case .att(let id): node = .attachment(id: id, kids)
            case .root: node = .text("")
            }
            stack[stack.count - 1].1.append(node)
        }
        return stack[0].1
    }

    /// Texte affiché d'un arbre en ligne (le `textContent` du navigateur).
    public static func plainText(_ ns: [Inline]) -> String {
        ns.map { n -> String in
            switch n {
            case .text(let t), .code(let t): return t
            case .bold(let k), .italic(let k), .mark(let k), .link(_, let k), .attachment(_, let k): return plainText(k)
            }
        }.joined()
    }

    /// Rendu HTML d'un arbre en ligne — le chemin inverse, utile à l'impression et aux tests.
    public static func html(_ ns: [Inline]) -> String {
        ns.map { n -> String in
            switch n {
            case .text(let t): return Txt.esc(t)
            case .code(let t): return "<code class=\"md-ci\">" + Txt.esc(t) + "</code>"
            case .bold(let k): return "<b>" + html(k) + "</b>"
            case .italic(let k): return "<i>" + html(k) + "</i>"
            case .mark(let k): return "<mark class=\"md-mk\">" + html(k) + "</mark>"
            case .link(let url, let k): return "<a href=\"" + Txt.esc(url) + "\" target=\"_blank\" rel=\"noopener noreferrer\">" + html(k) + "</a>"
            case .attachment(let id, let k): return "<a href=\"#\" data-mdatt=\"" + id + "\">" + html(k) + "</a>"
            }
        }.joined()
    }

    // MARK: Document rendu (ce que mdRender affiche)

    public struct RSubList: Equatable, Sendable { public var ordered: Bool; public var items: [[Inline]] }
    public struct RItem: Equatable, Sendable {
        public var content: [Inline]
        public var sub: RSubList?
        /// Tâche : état initial ET index en ordre de document (`data-task`) — les coches sont
        /// ÉPHÉMÈRES, jamais écrites dans le corps.
        public var task: (done: Bool, index: Int)?
        public static func == (a: RItem, b: RItem) -> Bool {
            a.content == b.content && a.sub == b.sub && a.task?.done == b.task?.done && a.task?.index == b.task?.index
        }
    }
    /// Titre : `foldKey` = clé de repli mémorisée (`mdFoldApply`, « slug~n »), nil si le titre n'a
    /// pas de corps (il ne se replie pas : aucun bouton mort) ; `sectionId` = id de sa section.
    public struct RHeading: Equatable, Sendable {
        public var level: Int
        public var content: [Inline]
        public var foldKey: String?
        public var sectionId: String?
    }
    public enum RBlock: Equatable, Sendable {
        case heading(RHeading)
        case paragraph(lines: [[Inline]])
        case list(ordered: Bool, items: [RItem])
        case quote(callout: Callout?, lines: [[Inline]])
        case code(String)
        case hr
        /// Image résolue (référence morte → bloc absent, jamais une image cassée) ; `scale` ∈ `scales`.
        case image(ImageRef, caption: String)
        case table(align: [Align], head: [[Inline]], rows: [[[Inline]]])
    }

    /// Le document tel que `mdRender` l'affiche. `images` = celles de l'entité.
    public static func document(_ src: String, images: [ImageRef]) -> [RBlock] {
        var imgs: [String: ImageRef] = [:]
        for im in images where !im.id.isEmpty && !Guard.badKeys.contains(im.id) { imgs[im.id] = im }
        var tk = 0
        func item(_ it: ListItem) -> RItem {
            var r = RItem(content: inline(it.text), sub: it.sub.map { RSubList(ordered: $0.ordered, items: $0.items.map(inline)) }, task: nil)
            if let d = it.done { r.task = (d, tk); tk += 1 }
            return r
        }
        var out: [RBlock] = []
        for b in blocks(src) {
            switch b {
            case .heading(let l, let t): out.append(.heading(RHeading(level: l, content: inline(t), foldKey: nil, sectionId: nil)))
            case .paragraph(let ls): out.append(.paragraph(lines: ls.map(inline)))
            case .list(let o, let its): out.append(.list(ordered: o, items: its.map(item)))
            case .quote(let k, let ls): out.append(.quote(callout: k, lines: ls.map(inline)))
            case .code(let ls): out.append(.code(ls.joined(separator: "\n")))
            case .hr: out.append(.hr)
            case .image(let cap, let id):
                guard let im = imgs[id], Guard.safeImg(.string(im.data)) != nil else { continue }
                out.append(.image(im, caption: cap.isEmpty ? im.caption : cap))
            case .table(let a, let h, let rs): out.append(.table(align: a, head: h.map(inline), rows: rs.map { $0.map(inline) }))
            }
        }
        // Clés de repli (mdFoldApply) : un titre se replie s'il a un corps ; la clé est le TITRE
        // (slug) numéroté dans l'ordre de lecture, jamais son rang.
        var seen: [String: Int] = [:]
        for idx in out.indices {
            guard case .heading(var h) = out[idx] else { continue }
            let hasBody: Bool
            if idx + 1 < out.count {
                if case .heading(let n) = out[idx + 1] { hasBody = n.level > h.level } else { hasBody = true }
            } else { hasBody = false }
            guard hasBody else { continue }
            var base = Txt.catSlug(plainText(h.content))
            if base.isEmpty { base = "s" }
            let n = (seen[base] ?? 0) + 1
            seen[base] = n
            let k = base + "~" + String(n)
            h.foldKey = k
            h.sectionId = "mdsect-" + Guard.safeId(.string(Txt.catSlug(k)), "s")
            out[idx] = .heading(h)
        }
        return out
    }

    /// `mdRender(src, {images})` en HTML, À L'OCTET (impression, export, tests) : l'en-ligne passe
    /// par `inlineHTML`, pas par l'arbre, pour garder jusqu'aux cas limites de la PWA. Les icônes
    /// (`uiIcon`) sont rendues par `icon(nom)` — un SVG côté web, un simple repère par défaut.
    public static func renderHTML(_ src: String, images: [ImageRef], icon: (String) -> String = { "<svg data-i=\"\($0)\"></svg>" }) -> String {
        var imgs: [String: ImageRef] = [:]
        for im in images where !im.id.isEmpty && !Guard.badKeys.contains(im.id) { imgs[im.id] = im }
        var tk = 0
        func sub(_ s: SubList?) -> String {
            guard let s else { return "" }
            let t = s.ordered ? "ol" : "ul"
            let body: String = s.items.map { "<li>" + inlineHTML($0) + "</li>" }.joined()
            return "<\(t) class=\"md-\(t)\">\(body)</\(t)>"
        }
        func li(_ it: ListItem) -> String {
            if let d = it.done {
                let n = tk; tk += 1
                let cls = d ? " done" : ""
                return "<li class=\"md-task\(cls)\" data-task=\"\(n)\"><span class=\"md-tkbox\" aria-hidden=\"true\">\(icon("check"))</span><span class=\"md-tktxt\">\(inlineHTML(it.text))\(sub(it.sub))</span></li>"
            }
            return "<li>" + inlineHTML(it.text) + sub(it.sub) + "</li>"
        }
        func ta(_ a: Align?) -> String {
            switch a { case .left?: return " class=\"ta-l\""; case .center?: return " class=\"ta-c\""; case .right?: return " class=\"ta-r\""; default: return "" }
        }
        func calloutIcon(_ k: Callout) -> String {
            switch k {
            case .crit: return icon("warn")
            case .vig: return "<span class=\"mc-g\" aria-hidden=\"true\">△</span>"
            case .ok: return icon("check")
            case .info: return icon("info")
            }
        }
        func cell(_ tag: String, _ al: [Align], _ i: Int, _ c: String, _ extra: String) -> String {
            let a: Align? = i < al.count ? al[i] : nil
            return "<" + tag + ta(a) + extra + ">" + inlineHTML(c) + "</" + tag + ">"
        }
        func block(_ b: Block) -> String {
            switch b {
            case .table(let al, let head, let rows):
                var hd = ""
                for (i, c) in head.enumerated() { hd += cell("th", al, i, c, " scope=\"col\"") }
                var bd = ""
                for r in rows {
                    bd += "<tr>"
                    for (i, c) in r.enumerated() { bd += cell("td", al, i, c, "") }
                    bd += "</tr>"
                }
                return "<div class=\"md-tw\" tabindex=\"0\" role=\"region\" aria-label=\"Tableau\"><table class=\"md-tbl\"><thead><tr>\(hd)</tr></thead><tbody>\(bd)</tbody></table></div>"
            case .heading(let l, let t):
                return "<h\(l) class=\"md-h\(l)\">\(inlineHTML(t))</h\(l)>"
            case .list(let o, let items):
                let t = o ? "ol" : "ul"
                var body = ""
                for it in items { body += li(it) }
                return "<\(t) class=\"md-\(t)\">\(body)</\(t)>"
            case .quote(let k, let lines):
                let body: String = lines.map(inlineHTML).joined(separator: "<br>")
                guard let k else { return "<blockquote class=\"md-q\">\(body)</blockquote>" }
                let ic = calloutIcon(k)
                return "<blockquote class=\"md-q md-call \(k.rawValue)\"><span class=\"mc-k\">\(ic)\(k.label)</span>\(body)</blockquote>"
            case .code(let ls): return "<pre class=\"md-code\"><code>\(Txt.esc(ls.joined(separator: "\n")))</code></pre>"
            case .hr: return "<hr class=\"md-hr\">"
            case .image(let capRaw, let id):
                guard let im = imgs[id], Guard.safeImg(.string(im.data)) != nil else { return "" }
                let cap = capRaw.isEmpty ? im.caption : capRaw
                let dim = (im.w != 0 && im.h != 0) ? " width=\"\(im.w)\" height=\"\(im.h)\"" : ""
                let sc = [25, 33, 50, 66, 75].contains(im.scale) ? " w\(im.scale)" : ""
                let c = Txt.esc(cap)
                let fig: String = cap.isEmpty ? "" : "<figcaption>\(c)</figcaption>"
                return "<figure class=\"md-fig\(sc)\"><img src=\"\(im.data)\" data-full=\"\(im.data)\"\(dim) data-cap=\"\(c)\" alt=\"\(c)\" loading=\"lazy\" decoding=\"async\">\(fig)</figure>"
            case .paragraph(let lines):
                let body: String = lines.map(inlineHTML).joined(separator: "<br>")
                return "<p class=\"md-p\">\(body)</p>"
            }
        }
        return blocks(src).map(block).joined()
    }

    // MARK: mdStrip

    static let sFence = JSRegExp("^```.*$")
    static let sHr = JSRegExp(#"^(---+|\*\*\*+)\s*$"#)
    static let sHead = JSRegExp(#"^#{1,3}\s+"#)
    static let sQuote = JSRegExp(#"^>\s?"#)
    static let sCall = JSRegExp(#"^\[!\s*[A-Za-zÀ-ÿ]{2,12}\s*\]\s*"#)
    static let sUl = JSRegExp(#"^\s*[-*]\s+"#)
    static let sOl = JSRegExp(#"^\s*\d{1,3}[.)]\s+"#)
    static let sImg = JSRegExp(#"^!\[([^\]]*)\]\([^()]*\)\s*$"#)
    static let sLink = JSRegExp(#"\[([^\]\n]{1,200})\]\([^()\s]{1,500}\)"#, "g")
    static let sCode = JSRegExp("`([^`\\n]+)`", "g")

    /// `mdStrip(src)` : texte brut pour la recherche plein texte — balisage retiré, légendes et
    /// libellés de liens gardés, cellules séparées par des espaces, marqueurs de tâche retirés
    /// (« [x] » ne doit jamais faire correspondre une recherche « x »).
    public static func strip(_ src: String) -> String {
        let joined = JS.split(JS.prefix(src, maxChars), "\n").map { l0 -> String in
            var l = sFence.replace(l0, "")
            l = sHr.replace(l, "")
            l = rxTSep.replace(l, "")
            l = rxTRow.replace(l) { m in cells(m[0]!).joined(separator: " ") }
            l = sHead.replace(l, ""); l = sQuote.replace(l, ""); l = sCall.replace(l, "")
            l = sUl.replace(l, ""); l = sOl.replace(l, ""); l = rxTask.replace(l, "")
            l = sImg.replace(l, "$1")
            l = sLink.replace(l, "$1")
            return l
        }.joined(separator: " ")
        return sCode.replace(rxMark.replace(rxItal.replace(Txt.boldRx.replace(joined, "$1"), "$1$2"), "$1"), "$1")
    }
}
