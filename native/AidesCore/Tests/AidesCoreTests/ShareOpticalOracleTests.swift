import XCTest
@testable import AidesCore

/// Parité « par l'écran » : PRNG, CDF, indices, trames, DEFLATE et fontaine dans les deux sens.
final class ShareOpticalOracleTests: XCTestCase {
    func unhex(_ s: String) -> [UInt8] {
        let u = Array(s.utf8)
        func v(_ c: UInt8) -> UInt8 { c <= 57 ? c - 48 : c - 87 }
        return stride(from: 0, to: u.count, by: 2).map { v(u[$0]) << 4 | v(u[$0 + 1]) }
    }
    func testOpticalMatchesWeb() throws {
        let cases = try Oracle.cases("share-optical")
        XCTAssertEqual(cases.count, 10)
        for (i, c) in cases.enumerated() {
            let fn = c.input["fn"]!.string!, a = c.input["arg"] ?? .null, web = c.output
            switch fn {
            case "mulberry":
                let mine: JSON = .array(a.array!.map { s in
                    var r = ShareFountain.Mulberry(UInt32(s.number!))
                    return .array((0..<12).map { _ in .number(r.next()) })
                })
                assertJSONEqual(mine, web, "cas \(i) mulberry")
            case "cdf":
                for (j, k) in a.array!.enumerated() {
                    let mine = ShareFountain.cdf(Int(k.number!)), w = web[j]!.array!.map { $0.number! }
                    XCTAssertEqual(mine, w, "cdf k=\(k.number!)")
                }
            case "logs":
                var bad = 0
                for (j, v) in web.array!.enumerated() {
                    let k = Double(j + 1)
                    let R = max(1, 0.1 * ShareFountain.v8Log(k / 0.5) * k.squareRoot())
                    if ShareFountain.v8Log(k / 0.5) != v[0]!.number! || R != v[1]!.number! || ShareFountain.v8Log(R / 0.5) != v[2]!.number! { bad += 1 }
                }
                XCTAssertEqual(bad, 0, "Math.log de V8 : \(bad) écarts sur 3000")
            case "indices":
                for (j, p) in a.array!.enumerated() {
                    let seed = UInt32(p[0]!.number!), k = Int(p[1]!.number!)
                    let cdf = ShareFountain.cdf(k)
                    let mine: JSON = .array((0..<40).map { x in .array(ShareFountain.indices(seed: seed, i: k + x, k: k, cdf: cdf).map { .number(Double($0)) }) })
                    assertJSONEqual(mine, web[j]!, "indices seed=\(seed) k=\(k)")
                }
            case "frames":
                let data = a["data"]!.array!.map { UInt8($0.number!) }
                let tx = ShareFountain.Transmitter(payload: data, type: UInt8(a["type"]!.number!), seed: UInt32(web["seed"]!.number!))
                XCTAssertEqual(Double(tx.k), web["k"]?.number); XCTAssertEqual(Double(tx.cycle), web["cycle"]?.number)
                let fr = web["frames"]!.array!
                for (p, f) in fr.enumerated() { XCTAssertEqual(ShareJS.hex(tx.frame(at: p)), f.string!, "trame \(p)") }
                let last = ShareFountain.parse(unhex(fr.last!.string!))!
                XCTAssertEqual(Double(last.i), web["parsed"]!["i"]!.number)
                XCTAssertEqual(ShareJS.hex(last.h4), web["parsed"]!["h"]!.string)
            case "webDeflate":
                for v in web.array! {
                    let text = try ShareDeflate.inflate(unhex(v["hex"]!.string!))
                    XCTAssertEqual(String(decoding: text, as: UTF8.self), v["text"]!.string!)
                }
            case "webFountain":
                XCTAssertEqual(web["webDone"]?.string, "done")
                let rx = ShareFountain.Receiver()
                var st = ShareFountain.Feed.ignored
                for f in web["frames"]!.array! { st = rx.feed(unhex(f.string!)); if st == .done { break } }
                XCTAssertEqual(st, .done)
                XCTAssertTrue(rx.h4Matches)
                let o = ShareOptical.unpack(rx.bytes()!)
                assertJSONEqual(o ?? .null, a["json"]!, "fontaine web → natif")
                assertJSONEqual(o ?? .null, web["webBack"]!, "fontaine web → web")
            case "nativeDeflate":
                assertJSONEqual(web, .array(ShareVectors.texts.map { .string($0) }), "deflate natif → web")
            case "nativeFountain":
                XCTAssertEqual(web["res"]?.array?.last?.string, "done")
                XCTAssertEqual(web["h"]?.string, web["sha"]?.string)
                assertJSONEqual(web["o"] ?? .null, ShareVectors.bigPayload(), "fontaine natif → web")
            default: XCTFail(fn)
            }
        }
    }
}
