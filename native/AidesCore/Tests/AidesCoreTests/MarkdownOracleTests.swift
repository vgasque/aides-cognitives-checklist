import XCTest
@testable import AidesCore

/// Mini-Markdown natif contre la PWA : blocs bruts (mdBlocks), HTML rendu (mdRender, icônes SVG
/// neutralisées des deux côtés), texte de recherche (mdStrip), clés de repli (mdFoldApply), et
/// l'en-ligne à l'octet (mdInline) — puis l'ARBRE en ligne re-rendu en HTML doit redonner le même
/// octet : c'est la preuve que l'arbre porte tout ce que le HTML porte.
final class MarkdownOracleTests: XCTestCase {
    static let img = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg=="
    let images = [
        ImageRef(id: "i1", data: img, w: 120, h: 80, caption: "Schéma", scale: 50),
        ImageRef(id: "i2", data: img, w: 0, h: 0, caption: "", scale: 100),
        ImageRef(id: "i3", data: "javascript:alert(1)", w: 1, h: 1, caption: "mauvaise", scale: 33),
        ImageRef(id: "i1", data: img, w: 10, h: 10, caption: "doublon (le dernier gagne)", scale: 75),
    ]

    static func project(_ b: Markdown.Block) -> JSON {
        switch b {
        case .heading(let l, let t): return ["t": .string("h\(l)"), "text": .string(t)]
        case .paragraph(let ls): return ["t": "p", "lines": .array(ls.map { .string($0) })]
        case .list(let o, let items):
            return ["t": .string(o ? "ol" : "ul"), "items": .array(items.map { it in
                ["text": .string(it.text),
                 "sub": it.sub.map { ["t": .string($0.ordered ? "ol" : "ul"), "items": .array($0.items.map { .string($0) })] } ?? .null,
                 "task": it.done.map { ["done": .bool($0)] } ?? .null]
            })]
        case .quote(let k, let ls): return ["t": "q", "kind": .string(k?.rawValue ?? ""), "lines": .array(ls.map { .string($0) })]
        case .code(let ls): return ["t": "code", "lines": .array(ls.map { .string($0) })]
        case .hr: return ["t": "hr"]
        case .image(let c, let id): return ["t": "img", "caption": .string(c), "id": .string(id)]
        case .table(let a, let h, let rs):
            return ["t": "tbl", "align": .array(a.map { .string($0.rawValue) }), "head": .array(h.map { .string($0) }),
                    "rows": .array(rs.map { .array($0.map { .string($0) }) })]
        }
    }
    /// La PWA sérialise un registre-fonction (« [!constructor] ») en omettant `kind` : même rendu
    /// qu'une citation neutre, qu'on écrit `kind: ''`.
    static func normalizeWeb(_ j: JSON) -> JSON {
        guard case .array(let a) = j else { return j }
        return .array(a.map { b in
            guard case .object(var o) = b, o["t"] == "q", o["kind"] == nil else { return b }
            o["kind"] = ""
            return .object(o)
        })
    }
    static let svg = JSRegExp(#"<svg[\s\S]*?</svg>"#, "g")
    static func noSvg(_ s: String) -> String { svg.replace(s, "") }

    func testDocumentsMatchWeb() throws {
        var docs = 0, inl = 0, trees = 0
        var treeMismatch: [String] = []
        for (i, c) in try Oracle.cases("markdown").enumerated() {
            switch c.input["k"]!.string! {
            case "doc":
                let src = c.input["src"]!.string!
                let mine = JSON.array(Markdown.blocks(src).map(MarkdownOracleTests.project))
                assertJSONEqual(mine, MarkdownOracleTests.normalizeWeb(c.output["blocks"]!), "doc \(i) blocs")
                XCTAssertEqual(MarkdownOracleTests.noSvg(Markdown.renderHTML(src, images: images)),
                               MarkdownOracleTests.noSvg(c.output["html"]!.string!), "doc \(i) html")
                XCTAssertEqual(Markdown.strip(src), c.output["strip"]!.string!, "doc \(i) strip")
                var folds: [JSON] = []
                for b in Markdown.document(src, images: images) {
                    if case .heading(let h) = b { folds.append(["k": h.foldKey.map { .string($0) } ?? .null, "id": h.sectionId.map { .string($0) } ?? .null]) }
                }
                assertJSONEqual(.array(folds), c.output["folds"]!, "doc \(i) replis")
                docs += 1
            case "inline":
                let s = c.input["s"]!.string!, web = c.output.string!
                XCTAssertEqual(Markdown.inlineHTML(s), web, "inline \(i)")
                if Markdown.html(Markdown.inline(s)) == web { trees += 1 } else { treeMismatch.append(s) }
                inl += 1
            case "cells":
                XCTAssertEqual(JSON.array(Markdown.cells(c.input["s"]!.string!).map { .string($0) }), c.output, "cells \(i)")
            case "callout":
                let m = Markdown.callout(c.input["s"]!.string!)
                XCTAssertEqual(m.kind?.rawValue ?? (m.marker ? nil : ""), c.output["kind"]!.string ?? (c.output["fn"] == .bool(true) ? nil : "?"), "callout \(i)")
                XCTAssertEqual(m.text, c.output["text"]!.string!, "callout \(i)")
            case "task":
                let t = Markdown.task(c.input["s"]!.string!)
                let mine: JSON = t.map { ["done": .bool($0.done), "text": .string($0.text)] } ?? .null
                assertJSONEqual(mine, c.output, "task \(i)")
            default: XCTFail("cas inconnu")
            }
        }
        XCTAssertGreaterThan(docs, 70)
        XCTAssertGreaterThan(inl, 30)
        // Les seuls écarts arbre→HTML admis sont les URL que la PWA elle-même abîme (un `*…*` ou
        // `==…==` DANS l'adresse devient une balise dans l'attribut href).
        XCTAssertTrue(treeMismatch.isEmpty, "arbre en ligne ≠ HTML web : \(treeMismatch)")
        XCTAssertGreaterThan(trees, 30)
    }

    /// Le même arbre, re-rendu, sur chaque LIGNE de chaque document du corpus.
    func testInlineTreeRoundTripOnCorpus() throws {
        var n = 0, bad: [String] = []
        for c in try Oracle.cases("markdown") where c.input["k"] == "doc" {
            for line in JS.split(c.input["src"]!.string!, "\n") {
                if Markdown.html(Markdown.inline(line)) != Markdown.inlineHTML(line) { bad.append(line) }
                n += 1
            }
        }
        XCTAssertGreaterThan(n, 500)
        // Écart connu et documenté : URL portant `*…*`/`==…==` (balises injectées DANS href par la PWA).
        XCTAssertEqual(bad.filter { !$0.contains("https://x.org/a*b*c") }, [])
    }
}
