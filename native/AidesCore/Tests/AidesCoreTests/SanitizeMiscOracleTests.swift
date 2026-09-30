import XCTest
@testable import AidesCore

final class SanitizeMiscOracleTests: XCTestCase {
    func testMatchesWeb() throws {
        for (i, c) in try Oracle.cases("sanitize-misc").enumerated() {
            let fn = c.input["fn"]!.string!, arg = c.input["arg"]!
            let mine: JSON
            switch fn {
            case "sanitizeSession": mine = SessionSanitize.session(arg)
            case "migrateProtocol": mine = Sanitize.reference(arg).json
            case "sanitizeCats": mine = .array(Sanitize.categories(arg).map(\.json))
            case "sanitizeNotes":
                var o: [String: JSON] = [:]
                for (k, n) in Sanitize.notes(arg) {
                    var v: [String: JSON] = ["t": .string(n.t), "at": .number(n.at)]
                    if n.dirty { v["dirty"] = true }
                    o[k] = .object(v)
                }
                mine = .object(o)
            case "parseValidation": mine = .string(Validation.parse(arg))
            default: XCTFail(fn); continue
            }
            assertJSONEqual(normalizeGenerated(mine, input: c.input), normalizeGenerated(c.output, input: c.input), "cas \(i) \(fn)")
        }
    }
}
