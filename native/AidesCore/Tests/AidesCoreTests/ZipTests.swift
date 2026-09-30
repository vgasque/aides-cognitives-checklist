import XCTest
@testable import AidesCore

final class ZipTests: XCTestCase {
    func fixture(_ n: String) throws -> Data {
        try Data(contentsOf: Bundle.module.url(forResource: n, withExtension: nil, subdirectory: "Fixtures")!)
    }
    /// Les octets produits sont IDENTIQUES à ceux de `zipBuild` de la PWA (même en-têtes, même date).
    func testBuildIsByteIdenticalToWeb() throws {
        let e = [Zip.Entry(name: "donnees.json", data: Data(#"{"version":3}"#.utf8)),
                 Zip.Entry(name: "documents/é-1.pdf", data: Data("%PDF-1.4 test".utf8))]
        XCTAssertEqual(Zip.build(e), try fixture("web-zipbuild.zip"))
    }
    func testRoundTripAndCorruption() throws {
        let e = [Zip.Entry(name: "a.txt", data: Data("bonjour".utf8))]
        var z = Zip.build(e)
        XCTAssertEqual(try Zip.parse(z), e)
        XCTAssertTrue(Zip.looksLikeZip(z))
        z[36] ^= 0xFF   // un octet du contenu (en-tête 30 + nom 5)
        XCTAssertThrowsError(try Zip.parse(z))
        XCTAssertThrowsError(try Zip.parse(Data([1, 2, 3])))
    }
}
