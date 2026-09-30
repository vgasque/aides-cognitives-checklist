import XCTest
@testable import AidesCore

final class JSONTests: XCTestCase {
    func testParseTypes() throws {
        let j = try JSON.parse(#"{"a":true,"b":1,"c":1.5,"d":"x","e":[null,false],"f":{}}"#)
        XCTAssertEqual(j["a"], .bool(true))
        XCTAssertEqual(j["b"], .number(1))
        XCTAssertEqual(j["c"], .number(1.5))
        XCTAssertEqual(j["d"], .string("x"))
        XCTAssertEqual(j["e"], .array([.null, .bool(false)]))
        XCTAssertEqual(j["f"], .object([:]))
    }
    func testRoundTrip() throws {
        let j: JSON = ["x": [1, 2.5, "t", true, .null]]
        XCTAssertEqual(try JSON.parse(j.data()), j)
    }
}
