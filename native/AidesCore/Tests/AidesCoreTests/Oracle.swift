import XCTest
@testable import AidesCore

/// Lecture des fixtures produites par `native/tools/oracle.mjs` (la PWA exécutée dans Chromium).
enum Oracle {
    struct Case { let input: JSON; let output: JSON }
    static func cases(_ name: String, file: StaticString = #filePath, line: UInt = #line) throws -> [Case] {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures/oracle") else {
            XCTFail("fixture d'oracle absente : \(name) — lancer `node native/tools/oracle.mjs \(name)`", file: file, line: line)
            return []
        }
        let j = try JSON.parse(Data(contentsOf: url))
        return (j.array ?? []).map { Case(input: $0["input"] ?? .null, output: $0["output"] ?? .null) }
    }
}

final class OracleCrcTests: XCTestCase {
    func testCrc32MatchesWeb() throws {
        for c in try Oracle.cases("crc32") {
            XCTAssertEqual(Double(Zip.crc32(Data(c.input.string!.utf8))), c.output.number)
        }
    }
}
