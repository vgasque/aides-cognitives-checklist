import XCTest
@testable import AidesCore

/// Parité des appliqueurs d'état (`shareStateLive`, `shareNavState`, `shareVfState`, `shareApplyAway`).
final class ShareApplyOracleTests: XCTestCase {
    func testApplyMatchesWeb() throws {
        let cases = try Oracle.cases("share-apply")
        XCTAssertEqual(cases.count, 14)
        for (i, c) in cases.enumerated() {
            var R = c.input["R"]!
            let off = c.input["offset"]!.number!
            let evs = c.input["evs"]!.array!
            var res: [JSON] = []
            if ShareJS.truthy(c.input["away"]) {
                res.append(.number(Double(ShareApply.applyAway(&R, evs, me: c.input["me"]?.string, fiche: R["fiche"], serverNow: 0, offset: off))))
            } else {
                for e in evs {
                    if ShareJS.truthy(c.input["nav"]) { res.append(ShareApply.navState(&R, e["payload"]!, fiche: R["fiche"]).map { .array($0) } ?? .null) }
                    else if ShareJS.truthy(c.input["vf"]) { res.append(.bool(ShareApply.vfState(&R, e))) }
                    else { res.append(.bool(ShareApply.stateLive(&R, e, serverNow: 0, offset: off))) }
                }
            }
            let mine: JSON = ["R": R, "res": .array(res)]
            assertJSONEqual(normalizeGenerated(mine, input: c.input), normalizeGenerated(c.output, input: c.input), "cas \(i)")
        }
    }
}
