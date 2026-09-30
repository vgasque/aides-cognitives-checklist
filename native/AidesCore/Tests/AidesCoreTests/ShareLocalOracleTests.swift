import XCTest
@testable import AidesCore

/// Parité « en direct » : SDP, charges SO:/SA:, trames RPC, adresse locale, HUB rejoué.
final class ShareLocalOracleTests: XCTestCase {
    func quint(_ j: JSON?) -> ShareSDPQuintuple {
        ShareSDPQuintuple(u: j?["u"]?.string, p: j?["p"]?.string, f: j?["f"]?.string, s: j?["s"]?.string,
                          c: (j?["c"]?.array ?? []).map { $0.jsString })
    }
    func pairingJSON(_ p: SharePairing?) -> JSON {
        guard let p else { return .null }
        var o = p.sdp.json.object!
        o["k"] = .string(p.k)
        return .object(o)
    }
    @MainActor func testLocalMatchesWeb() async throws {
        let cases = try Oracle.cases("share-local")
        XCTAssertEqual(cases.count, 20)
        for (i, c) in cases.enumerated() {
            let fn = c.input["fn"]!.string!, a = c.input["arg"] ?? .null
            var mine: JSON
            switch fn {
            case "sdp": mine = ShareSDP.extract(a.string!).json
            case "rebuild":
                if a["c"]?.array == nil { mine = .null } else { mine = ShareSDP.rebuild(quint(a)).map { .string($0) } ?? .null }
            case "pack":
                let p = SharePairing(k: a["k"]!.string!, sdp: quint(a)).pack()
                mine = ["b64": p.map { .string($0) } ?? .null, "back": p.map { pairingJSON(SharePairing.unpack($0)) } ?? .null]
            case "unpack": mine = pairingJSON(SharePairing.unpack(a.string!))
            case "rpc": mine = .array(a.array!.map { ShareRPC.unpack($0.string!) ?? .null })
            case "rpcOut":
                mine = .array([ShareRPC.pack(3, "push", ["secret": "s", "events": []]), ShareRPC.reply(3, result: ["ok": true]),
                               ShareRPC.reply(4, result: nil, error: "hub"), ShareRPC.pack(1, "end", nil)].map { try! JSON.parse($0) })
            case "localCand": mine = .array(a.array!.map { .bool(ShareSDP.hasLocalCandidate(($0.array ?? []).map { $0.jsString })) })
            case "hub":
                var t = 1727697600000.0, nu = 0, ns = 0
                let h = ShareHub(.init(now: { t }, uid: { nu += 1; return "p\(nu)" }, secret: { ns += 1; return "S\(ns)" },
                                       shareId: "shl1", fiche: ["id": "f1", "title": "T"]))
                var r: [JSON] = []
                for op in a.array! {
                    t += 1000
                    let o = op.array!
                    switch o[0].string! {
                    case "join": r.append(h.join(label: o[1].string))
                    case "pull": r.append(h.pull(secret: o[1].string, since: o[2].number!))
                    case "push": r.append(h.push(secret: o[1].string, events: o[2].array!))
                    case "revoke": r.append(h.revoke(pid: o[1].string))
                    case "setRole": r.append(h.setRole(pid: o[1].string, role: o[2].string))
                    default: r.append(h.end())
                    }
                }
                mine = .array(r)
            default: XCTFail(fn); continue
            }
            assertJSONEqual(mine, c.output, "cas \(i) \(fn)")
        }
    }
}
