import XCTest
@testable import AidesCore

extension Proj {
    static func b(_ x: Bool?) -> JSON? { x.map { .bool($0) } }
    static func row(_ r: Page.Row) -> JSON {
        var o: [String: JSON] = ["k": .string(r.k)]
        if let v = r.id { o["id"] = .string(v) }
        if let v = r.fin { o["fin"] = .bool(v) }
        if let v = r.colId { o["colId"] = .string(v) }
        if let v = r.kind { o["kind"] = .string(v) }
        if let v = r.to { o["to"] = .string(v) }
        if let v = r.from { o["from"] = s(v) }
        if let v = r.alts { o["alts"] = .array(v.map { ["label": .string($0.label), "tgt": s($0.tgt), "kind": .string($0.kind)] }) }
        if let v = r.brs { o["brs"] = .array(v.map { ["label": .string($0.label), "colId": .string($0.colId), "cont": .bool($0.cont)] }) }
        if let v = r.dec { o["dec"] = .string(v) }
        if let v = r.label { o["label"] = .string(v) }
        if let v = r.last { o["last"] = .bool(v) }
        if let v = r.merge { o["merge"] = .string(v) }
        if let v = r.mergeTo { o["mergeTo"] = .string(v) }
        if let v = r.coll { o["coll"] = .bool(v) }
        if let v = r.tgt { o["tgt"] = .bool(v) }
        if let v = r.merged { o["merged"] = .bool(v) }
        return .object(o)
    }
    static func src(_ e: Page.EdgeSrc) -> JSON {
        var o: [String: JSON] = [:]
        if let v = e.alt { o["alt"] = .string(v) }
        if let v = e.pill { o["pill"] = s(v) }
        if let v = e.col { o["col"] = .string(v) }
        return .object(o)
    }
    static func col(_ c: Page.Column) -> JSON {
        ["id": .string(c.id), "kind": .string(c.kind), "w": n(c.w), "depth": n(c.depth), "right": .bool(c.right), "parentId": s(c.parentId),
         "rows": .array(c.rows.map(row))]
    }
    static func tree(_ t: Page.TreePlan) -> JSON {
        ["root": col(t.root), "cols": .array(t.cols.map(col)), "order": strs(t.order), "firstOf": .object(t.firstOf.mapValues { .string($0) }),
         "edges": .array(t.edges.map { e in
            var o: [String: JSON] = ["k": .string(e.k), "to": .string(e.to)]
            if let v = e.src { o["src"] = src(v) }
            if let v = e.col { o["col"] = .string(v) }
            if let v = e.parent { o["parent"] = .string(v) }
            if let v = e.cols { o["cols"] = strs(v) }
            if let v = e.srcs { o["srcs"] = .array(v.map(src)) }
            return .object(o)
         })]
    }
}

final class PageOracleTests: XCTestCase {
    func testPageMatchesWeb() throws {
        var n = 0
        for (i, c) in try Oracle.cases("page").enumerated() {
            let o = c.output
            let f = Sanitize.fiche(o["f"])
            let L = "fiche \(i) \(f.id)"
            assertJSONEqual(Proj.tree(Page.treePlan(f)), o["tree"]!, "\(L) svTreePlan")
            assertJSONEqual(Proj.strs(Page.validWarn(f)), o["warn"]!, "\(L) svValidWarn")
            assertJSONEqual(Proj.strs(Page.sources(f)), o["src"]!, "\(L) svSources")
            XCTAssertEqual(Page.countsTxt(f), o["counts"]!.string!, "\(L) svCountsTxt")
            assertJSONEqual(Proj.strs(Page.carryParts(f)), o["carry"]!, "\(L) carryParts")
            let tz = TimeZone(identifier: o["tz"]!.string!)!
            XCTAssertEqual(Page.revTxt(f, tz: tz), o["rev"]!.string!, "\(L) svRevTxt")
            XCTAssertEqual(Double(Page.rootColumn), o["col"]!.number!)
            n += 1
        }
        XCTAssertGreaterThan(n, 150)
    }
}
