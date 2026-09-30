import XCTest
@testable import AidesCore

/// Le moteur JSRegExp contre V8 : exec (index + captures), replace avec gabarit `$1|$&|$$`,
/// split (captures non participantes = null) et matchAll.
final class JSRegExpOracleTests: XCTestCase {
    func testMatchesV8() throws {
        var n = 0
        var cache: [String: JSRegExp] = [:]
        for (i, c) in try Oracle.cases("jsregexp").enumerated() {
            let p = c.input["p"]!.string!, f = c.input["f"]!.string!, s = c.input["s"]!.string!
            let key = p + "/" + f
            let base = cache[key + "0"] ?? JSRegExp(p, f.replacingOccurrences(of: "g", with: ""))
            cache[key + "0"] = base
            let glob = cache[key + "g"] ?? JSRegExp(p, f.contains("g") ? f : f + "g")
            cache[key + "g"] = glob
            let full = cache[key] ?? JSRegExp(p, f)
            cache[key] = full
            var m: JSON = .null
            if let x = base.exec(s) {
                var g: [JSON] = [.string(x[0]!)]
                for k in 0..<x.groups.count { g.append(x[k + 1].map { .string($0) } ?? .null) }
                m = ["i": .number(Double(x.range.lowerBound)), "g": .array(g)]
            }
            let all: [JSON] = glob.allMatches(in: Array(s.utf16)).map { [.number(Double($0.range.lowerBound)), .number(Double($0.range.count))] }
            let mine: JSON = ["m": m, "r": .string(full.replace(s, "<$1|$&|$$>")),
                              "sp": .array(base.splitOpt(s).map { $0.map { .string($0) } ?? .null }), "all": .array(all)]
            assertJSONEqual(mine, c.output, "cas \(i) /\(p)/\(f) « \(s) »")
            n += 1
        }
        XCTAssertGreaterThan(n, 4000)
    }

    func testToFixed() {
        XCTAssertEqual(JS.toFixed(1.25, 1), "1.3")
        XCTAssertEqual(JS.toFixed(1.005, 2), "1.00")
        XCTAssertEqual(JS.toFixed(0.5, 0), "1")
        XCTAssertEqual(JS.toFixed(-0.001, 2), "-0.00")
        XCTAssertEqual(JS.toFixed(9.995, 2), "9.99")
        XCTAssertEqual(JS.toFixed(99.96, 1), "100.0")
        XCTAssertEqual(JS.toFixed(3, 2), "3.00")
    }
}
