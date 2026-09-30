import XCTest
@testable import AidesCore

/// Parité du partage avec la PWA exécutée (fixtures de `native/tools/oracle-cases/share-*.mjs`).
final class ShareCoreOracleTests: XCTestCase {
    func testCoreMatchesWeb() throws {
        let cases = try Oracle.cases("share-core")
        XCTAssertGreaterThan(cases.count, 40)
        for (i, c) in cases.enumerated() {
            let fn = c.input["fn"]!.string!, a = c.input["arg"] ?? .null
            let mine: JSON
            switch fn {
            case "code":
                let s = a.string
                mine = ["norm": .string(ShareCode.norm(s)), "valid": .bool(ShareCode.isValid(s)),
                        "bad": .array(ShareCode.badChars(s).map { .string($0) }), "fmt": .string(ShareCode.format(s))]
            case "fromHash": mine = ShareCode.fromHash(a.string).map { .string($0) } ?? .null
            case "payload": mine = ShareCore.payload(a)
            case "can":
                var o: [String: JSON] = [:]
                for r in ["lead", "scribe", "x", nil] as [String?] {
                    for k in ShareCore.kindsAny + ShareCore.kindsLead + ["zz"] { o[(r ?? "null") + "/" + k] = .bool(ShareCore.can(r, k)) }
                }
                mine = .object(o)
            case "applyMode": mine = .array(a.array!.map { .string(ShareCore.applyMode($0.string!).rawValue) })
            case "vf":
                let arr = a.array!
                var m: [String: JSON] = [:]
                for (j, v) in arr.enumerated() { m[String(j)] = v }
                mine = ["norm": .array(arr.map { ShareCore.vfNorm($0) ?? .null }), "time": .array(arr.map { .number(ShareCore.vfTime($0)) }),
                        "actor": .array(arr.map { ShareCore.vfActor($0) }), "map": ShareCore.vfMapNorm(.object(m))]
            case "navNorm":
                if let n = ShareCore.navNorm(a[0], a[1]) { mine = ["nav": .array(n.nav), "navSeq": .array(n.navSeq)] } else { mine = .null }
            case "cxbNorm": mine = ShareCore.cxbNorm(a[0], a[1]?.array ?? [])
            case "cxbForFiche": mine = ShareCore.cxbForFiche(a[0], a[1])
            case "snap": mine = ShareCore.snap(a, flowEnded: ShareJS.truthy(a["stopClosed"]))
            case "diff":
                let base: JSON? = (a[0]?.isNull ?? true) ? Optional<JSON>.none : ShareCore.snap(a[0], flowEnded: false)
                mine = .array(ShareCore.diff(base, ShareCore.snap(a[1], flowEnded: false), sessionId: a[2]?.string).map(\.json))
            case "fold": mine = ShareCore.fold(a[0]?.array ?? [], base: (a[1]?.isNull ?? true) ? Optional<JSON>.none : a[1])
            case "foldSan": mine = ShareCore.foldSan(a)
            case "hash": mine = .string(ShareCore.stateHash(a))
            case "offset":
                let s = a.array!.map { ShareCore.ClockSample(t0: $0["t0"]!.number!, t1: $0["t1"]!.number!, srv: $0["srv"]!.number!) }
                mine = ShareCore.offset(s).map { .number($0) } ?? .null
            case "iso": mine = .array(a.array!.map { ShareJS.isoMs($0.string!).map { .number($0) } ?? .null })
            case "isoOut": mine = .array(a.array!.map { .string(ShareJS.isoString($0.number!)) })
            case "stream": mine = .array(a.array!.map { .string(ShareSHA256.hex(($0.array ?? []).map { $0.string! }.joined(separator: ","))) })
            case "whitelist":
                mine = ["pl": ShareCore.whitelist(a), "keys": .array(ShareCore.payloadKeys.map { .string($0) }), "keep": .array(ShareCore.keep.map { .string($0) }),
                        "any": .array(ShareCore.kindsAny.map { .string($0) }), "lead": .array(ShareCore.kindsLead.map { .string($0) }),
                        "travels": .array(ShareCore.travels.map { .string($0) }), "local": .array(ShareCore.local.map { .string($0) }),
                        "alpha": .string(ShareCode.alphabet)]
            default: XCTFail("fn inconnue \(fn)"); continue
            }
            if ProcessInfo.processInfo.environment["SHARE_DUMP"] == String(i) { for x in mine.array ?? [mine] { print("DUMP", x.text()) } }
            assertJSONEqual(normalizeGenerated(mine, input: c.input), normalizeGenerated(c.output, input: c.input), "cas \(i) \(fn)")
        }
    }
}
