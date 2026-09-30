import XCTest
@testable import AidesCore

final class PdfIndexOracleTests: XCTestCase {
    static let queries: [[String]] = [["adre"], ["dose", "mg"], ["drenalin"], ["a"], ["ab"], ["zz", "choc"], ["xxxxxxxx"], [], ["inconnu"], ["10"], ["0"], ["c", "ch"], ["s\na"]]
    static func bytes(_ j: JSON?) -> [UInt8] { (j?.array ?? []).map { UInt8($0.number!) } }
    static func record(_ j: JSON) -> PdfIndex.Record {
        PdfIndex.Record(v: Int(j["v"]!.number!), pages: Int(j["pages"]!.number!), terms: Int(j["terms"]!.number!), dict: bytes(j["dict"]), post: bytes(j["post"]))
    }
    static func reads(_ h: PdfIndex.Handle?) -> (JSON, JSON) {
        let po: JSON = h.map { h in .array((0..<h.n).map { .array(PdfIndex.pagesOf(h, $0).map(Proj.n)) }) } ?? .null
        let se = JSON.array(queries.map { q in PdfIndex.search(h, q).map { .array($0.map(Proj.n)) } ?? .null })
        return (po, se)
    }
    func testIndexMatchesWeb() throws {
        var docs = 0
        for c in try Oracle.cases("pdfindex") {
            let k = c.input["k"]!.string!, o = c.output
            switch k {
            case "tokens":
                assertJSONEqual(.array(c.input["texts"]!.array!.map { Proj.strs(PdfIndex.tokens($0.string!)) }), o["tokens"]!, "ixTokens")
                XCTAssertEqual(Double(PdfIndex.version), o["v"]!.number!)
            case "doc":
                let pages = c.input["pages"]!.array!.map { $0.array!.map { $0.string! } }
                let rec = PdfIndex.build(pages)
                // LE FORMAT BINAIRE, À L'OCTET.
                XCTAssertEqual(rec, PdfIndexOracleTests.record(o["rec"]!), "ixBuild doc \(docs)")
                let (po, se) = PdfIndexOracleTests.reads(PdfIndex.open(rec))
                assertJSONEqual(po, o["pagesOf"]!, "ixPagesOf doc \(docs)")
                assertJSONEqual(se, o["search"]!, "ixSearch doc \(docs)")
                // Lecture croisée : l'index WEB ouvert par le natif.
                let (po2, se2) = PdfIndexOracleTests.reads(PdfIndex.open(PdfIndexOracleTests.record(o["rec"]!)))
                assertJSONEqual(po2, o["pagesOf"]!, "index web relu doc \(docs)")
                assertJSONEqual(se2, o["search"]!, "index web cherché doc \(docs)")
                docs += 1
            case "corrupt":
                for (i, r) in o.array!.enumerated() {
                    let h = PdfIndex.open(PdfIndexOracleTests.record(r["rec"]!))
                    XCTAssertEqual(h != nil, r["ok"]!.bool!, "ixOpen corrompu \(i)")
                    let (po, se) = PdfIndexOracleTests.reads(h)
                    assertJSONEqual(po, r["pagesOf"]!, "ixPagesOf corrompu \(i)")
                    assertJSONEqual(se, r["search"]!, "ixSearch corrompu \(i)")
                }
            default: XCTFail(k)
            }
        }
        XCTAssertGreaterThan(docs, 30)
    }
}

final class CatColorOracleTests: XCTestCase {
    func near(_ a: Double, _ b: JSON?, _ l: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let b = b?.number else { XCTAssertTrue(a.isNaN, l, file: file, line: line); return }
        XCTAssertEqual(a, b, accuracy: 1e-9 * max(1, abs(b)), l, file: file, line: line)
    }
    func testColorsMatchWeb() throws {
        for c in try Oracle.cases("catcolors") {
            if c.input["k"] == "hues" {
                let o = c.output
                assertJSONEqual(Proj.strs((0..<360).map { CatColor.hueHex(Double($0)) }), o["hex"]!, "catHueHex")
                assertJSONEqual(Proj.strs([-30, 360, 725, 12.5].map { CatColor.hueHex($0) }), o["extra"]!, "catHueHex (hors bornes)")
                assertJSONEqual(Proj.strs((0..<360).map { CatColor.hueSnap($0, orig: $0 % 7 != 0 ? nil : "#7a2f6b") }), o["snap"]!, "catHueSnap")
                assertJSONEqual(Proj.strs(CatColor.palette), o["palette"]!, "PALETTE")
                assertJSONEqual(.array(["#123456", "#abcdef", "#8d5c39", "#e11d48"].map { c -> JSON in
                    let d = CatColor.hueDeg(c)!
                    return Proj.strs([CatColor.hueSnap(d, orig: c), CatColor.hueSnap((d + 1) % 360, orig: c)])
                }), o["orig"]!, "catHueSnap (origine hors palette)")
                continue
            }
            let cols = c.input["cols"]!.array!.map { $0.string! }
            for (i, w) in c.output.array!.enumerated() {
                let col = cols[i]
                let ok = CatColor.hexToOklch(col)
                for j in 0..<3 { near(ok[j], w["oklch"]![j], "hexToOklch \(col)[\(j)]") }
                XCTAssertEqual(CatColor.hueDeg(col).map(Double.init), w["deg"]!.number, "catHueDeg \(col)")
                XCTAssertEqual(CatColor.lisible(col), w["lis"]!.bool!, "catLisible \(col)")
                XCTAssertEqual(CatColor.regNear(col), w["near"]!.bool!, "catRegNear \(col)")
                XCTAssertEqual(CatColor.safeTwin(col), w["twin"]!.string, "catSafeTwin \(col)")
                for (j, other) in cols.prefix(12).enumerated() { near(CatColor.dEok(col, other), w["d"]![j], "dEok \(col) \(other)") }
            }
        }
    }
}
