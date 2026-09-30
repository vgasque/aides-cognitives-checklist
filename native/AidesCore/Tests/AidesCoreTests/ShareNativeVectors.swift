import XCTest
@testable import AidesCore

/// Vecteurs PRODUITS PAR LE NATIF, que l'oracle fait décoder par la PWA (sens natif → web) :
/// DEFLATE brut de l'encodeur maison et trames fontaine. Régénérer :
///   SHARE_WRITE_NATIVE=1 swift test --filter ShareNativeVectors && node native/tools/oracle.mjs share-optical
enum ShareVectors {
    static let texts: [String] = [
        "", "a", String(repeating: "abcabcabc", count: 300),
        "{\"sess\":\"s-1\",\"at\":1727697600000,\"ret\":[{\"id\":\"e1\",\"t\":5,\"ref\":null,\"voidAt\":null}]}",
        (0..<400).map { "{\"k\":\"\($0):b\($0 % 7):\($0 % 13)\",\"é\":\"€𝄞\"}" }.joined(separator: ","),
    ]
    static func bigPayload() -> JSON {
        var checked: [String: JSON] = [:]
        for i in 0..<300 { checked["\(i % 9 + 1):b\(i % 5):\(i % 17)"] = true }
        return ["sess": "s-native", "at": 1727697600000, "fiche": ["id": "f1", "title": "Arrêt cardio-respiratoire — adulte", "blocks": []],
                "snap": ["checked": .object(checked), "nav": ["b1", "b2"], "navSeq": [1, 2], "startedAt": 1727690000000]]
    }
}

final class ShareNativeVectors: XCTestCase {
    func testWriteNativeVectors() throws {
        guard ProcessInfo.processInfo.environment["SHARE_WRITE_NATIVE"] == "1" else { return }
        var defl: [JSON] = []
        for t in ShareVectors.texts { defl.append(["text": .string(t), "hex": .string(ShareJS.hex(ShareDeflate.deflate(Array(t.utf8))))]) }
        let z = ShareDeflate.deflate(Array(ShareVectors.bigPayload().data()))
        let tx = ShareFountain.Transmitter(payload: z, type: 0, seed: 0xC0FFEE11)
        // Toutes les trames d'un cycle et demi, sauf les 3 premières (perdues) : la fontaine doit réparer.
        let frames = (0..<(tx.cycle * 3 / 2)).map { tx.frame(at: $0) }.dropFirst(3).map { JSON.string(ShareJS.hex($0)) }
        let out: JSON = ["deflate": .array(defl), "frames": .array(Array(frames)), "payload": ShareVectors.bigPayload()]
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../tools/oracle-cases/share-optical.native.json").standardized
        try out.data(pretty: true).write(to: url)
        print("vecteurs natifs écrits :", url.path)
    }
}
