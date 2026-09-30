import XCTest
@testable import AidesCore

extension Proj {
    static func usage(_ u: [String: Search.Usage]) -> JSON { .object(u.mapValues { ["n": n($0.n), "t": .number($0.t)] }) }
    static func ranked(_ r: Posology.Ranked) -> JSON { ["s": .string(r.s), "i": n(r.i), "crit": .bool(r.crit), "score": n(r.score)] }
    static func strsOpt(_ a: [String?]) -> JSON { .array(a.map { s($0) }) }
}

final class SearchOracleTests: XCTestCase {
    func testSearchMatchesWeb() throws {
        var seen = Set<String>()
        for (ci, c) in try Oracle.cases("search").enumerated() {
            let k = c.input["k"]!.string!, o = c.output
            seen.insert(k)
            switch k {
            case "text":
                let txt = c.input["txt"]!.array!.map { $0.string! }
                let terms = c.input["terms"]!.array!.map { $0.array!.map { $0.string! } }
                assertJSONEqual(Proj.strs(txt.map(Txt.txNorm)), o["norm"]!, "txNorm")
                assertJSONEqual(.array(txt.map { Proj.strs(Search.qTerms($0)) }), o["q"]!, "qTerms")
                assertJSONEqual(.array(txt.map { s in Proj.strs(terms.map { Search.markQTermsHTML(s, $0) }) }), o["mark"]!, "markQTerms")
                assertJSONEqual(.array(txt.map { s in .array(terms.map { .bool(Search.hayMatch(Txt.txNorm(s), $0)) }) }), o["match"]!, "hayMatch")
            case "snip":
                let mine = c.input["snip"]!.array!.map { e -> JSON in
                    let parts = e[0]!.array!.map { $0.string ?? "" }
                    return .string(Search.snippetHTML(parts, e[1]!.string!))
                }
                assertJSONEqual(.array(mine), o, "searchSnippet")
            case "titles":
                let t = c.input["titles"]!.array!.map { $0.string! }
                let idx = Array(t.indices)
                assertJSONEqual(.array(Search.sortedByTitle(idx, title: { t[$0] }).map(Proj.n)), o["sorted"]!, "byTitle (tri)")
                let pairs = JSON.array(t.map { a in .array(t.map { b in
                    let r = Search.compareTitles(a, b)
                    return .number(r == .orderedAscending ? -1 : (r == .orderedSame ? 0 : 1))
                }) })
                assertJSONEqual(pairs, o["pairs"]!, "byTitle (paires)")
            case "usage":
                let us = c.input["usage"]!.array!
                assertJSONEqual(.array(us.map { Proj.usage(Search.sanitizeUsage($0["a"])) }), o["san"]!, "sanitizeUsage")
                assertJSONEqual(.array(us.map { Proj.usage(Search.mergeUsage($0["a"], $0["b"])) }), o["merge"]!, "mergeUsage")
                let fr = c.input["frec"]!.array!.map { e -> JSON in
                    let u = e[0]!.isNull ? nil : Search.Usage(n: Int(JS.number(e[0]!["n"]).isNaN ? 0 : JS.number(e[0]!["n"])), t: e[0]!["t"]?.number ?? 0)
                    return .number(Search.frecencyScore(u, now: e[1]!.number!))
                }
                assertJSONEqual(.array(fr), o["frec"]!, "frecencyScore")
            case "az":
                let az = c.input["az"]!.array!.map { $0.string! }
                assertJSONEqual(Proj.strs(az.map(Search.azLetter)), o["letters"]!, "azLetter")
                assertJSONEqual(.array(Search.azGroups(az, title: { $0 }).map { ["L": .string($0.letter), "items": Proj.strs($0.items)] }), o["groups"]!, "azGroups")
                let objs = az.indices.map { "i\($0)" }
                assertJSONEqual(Proj.strs(Search.qaPick(objs, pinIds: ["i3", "i0", "zz", "i7"], id: { $0 })), o["qa"]!, "qaPick")
            case "vocab":
                let v = c.input["voc"]!
                let items = v["items"]!.array!.map { (title: $0["title"]?.string ?? "", code: $0["code"]?.string ?? "", discriminant: $0["discriminant"]?.string ?? "") }
                let voc = Search.libVocab(items, extra: v["extra"]!.array!.map { $0.string! })
                assertJSONEqual(Proj.strs(voc), o["vocab"]!, "libVocab")
                assertJSONEqual(Proj.strsOpt(c.input["spell"]!.array!.map { Search.spellFix($0.string!, vocab: voc) }), o["spell"]!, "spellFix")
                assertJSONEqual(.array(c.input["dlev"]!.array!.map { Proj.n(Search.dlev($0[0]!.string!, $0[1]!.string!, Int($0[2]!.number!))) }), o["dlev"]!, "dlev")
                XCTAssertNil(Search.spellFix("abcd", vocab: []))
                let v2 = c.input["v2"]!.array!.map { $0.string! }
                assertJSONEqual(Proj.strsOpt(c.input["q2"]!.array!.map { Search.spellFix($0.string!, vocab: v2) }), o["s2"]!, "spellFix (égalités)")
            case "poso":
                for (pi, p) in c.input["poso"]!.array!.enumerated() {
                    let items = p["items"]!.array!.map { $0.string! }, hays = p["hays"]!.array!.map { $0.string! }
                    let w = o[pi]!
                    assertJSONEqual(.array((items + hays).map { Proj.strs(Posology.tokens($0)) }), w["tokens"]!, "posoTokens")
                    assertJSONEqual(Proj.strs(items.map(Posology.name)), w["names"]!, "posoName")
                    assertJSONEqual(.array(items.map { i in .array(hays.map { Proj.n(Posology.score(Posology.name(i), $0)) }) }), w["scores"]!, "posoScore")
                    assertJSONEqual(.array(hays.map { .array(Posology.rank(items, $0).map(Proj.ranked)) }), w["rank"]!, "posoRank")
                    assertJSONEqual(.array(hays.map { h in .array([3, 2, 10].map { cap -> JSON in
                        let s = Posology.split(items, h, cap: cap)
                        return ["head": .array(s.head.map(Proj.ranked)), "rest": .array(s.rest.map(Proj.ranked))]
                    }) }), w["split"]!, "posoSplit")
                    assertJSONEqual(.array(items.map { let x = Posology.parts($0); return ["name": .string(x.name), "body": .string(x.body), "flag": .bool(x.flag)] }), w["parts"]!, "posoParts")
                }
            case "misc":
                let tz = TimeZone(identifier: o["tz"]!.string!)!
                assertJSONEqual(Proj.strs(c.input["bytes"]!.array!.map { v in let x = JS.number(v); return Txt.fmtBytes(x.isNaN ? 0 : x) }), o["bytes"]!, "fmtBytes")
                assertJSONEqual(Proj.strs(c.input["ms"]!.array!.map { Txt.fmtMs($0.number!) }), o["ms"]!, "fmtMs")
                assertJSONEqual(.array(c.input["times"]!.array!.map { t -> JSON in
                    guard let r = Txt.tkParseTime(t.string!) else { return .null }
                    return ["h": Proj.n(r.h), "m": Proj.n(r.m), "s": Proj.n(r.s)]
                }), o["times"]!, "tkParseTime")
                assertJSONEqual(Proj.strs(c.input["stamps"]!.array!.map { Txt.sessStamp($0.number!, tz: tz) }), o["stamps"]!, "sessStamp")
                assertJSONEqual(.array(c.input["stale"]!.array!.map { .bool(Txt.staleDate($0[0]!.string!, now: $0[1]!.number!)) }), o["stale"]!, "staleDate")
                let slugs = c.input["slugs"]!.array!.map { $0.string! }
                assertJSONEqual(Proj.strs(slugs.map(Txt.catSlug)), o["slugs"]!, "catSlug")
                assertJSONEqual(Proj.strsOpt(slugs.map { Txt.catSlug($0).isEmpty ? nil : Txt.detCatId($0) }), o["det"]!, "detCatId")
                XCTAssertTrue(Txt.detCatId("").hasPrefix("c"), "detCatId sans slug → uid('c')")
                assertJSONEqual(.array(c.input["labels"]!.array!.map { let p = Parcours.tmLabelParts($0.string!); return ["name": .string(p.name), "meta": .string(p.meta)] }), o["labels"]!, "tmLabelParts")
                assertJSONEqual(Proj.strs(c.input["since"]!.array!.map { Txt.sinceTxt($0[0]!.number!, now: $0[1]!.number!) }), o["since"]!, "sinceTxt")
            case "fiche":
                let f = Sanitize.fiche(o["f"])
                XCTAssertEqual(Search.ficheHaystack(f, categoryName: ""), o["hay"]!.string!, "ficheHaystack \(ci)")
                assertJSONEqual(Proj.strs(Search.ficheSnipParts(f)), .array(o["parts"]!.array!.map { $0.isNull ? "" : $0 }), "ficheSnipParts \(ci)")
                assertJSONEqual(Proj.strs(["adre", "choc", "masser", "e", "b1", "à compléter", "zzz"].map { Search.snippetHTML(Search.ficheSnipParts(f), $0) }), o["snips"]!, "snips \(ci)")
                let tz = TimeZone(identifier: o["tz"]!.string!)!
                let sess = [Search.SessionStamp(ficheId: f.id, aidRev: f.updatedAt - 1, startedAt: 1727700000000), Search.SessionStamp(ficheId: f.id, aidRev: f.updatedAt, startedAt: 1727600000000),
                            Search.SessionStamp(ficheId: "autre", aidRev: 1, startedAt: 9e12)]
                assertJSONEqual(Proj.strs([Search.revisedSinceTxt(f, sessions: sess, tz: tz), Search.revisedSinceTxt(f, sessions: Array(sess.dropFirst()), tz: tz),
                                           Search.revisedSinceTxt(f, sessions: [], tz: tz)]), o["rev"]!, "revisedSinceTxt \(ci)")
            case "rel":
                let fs = o["fs"]!.array!.map { Sanitize.fiche($0) }
                let ps = o["ps"]!.array!.map { Sanitize.reference($0) }
                let mine = JSON.array(fs.map { e in .array(Search.relCandidatesFor(id: e.id, links: e.links, library: e.library, fiches: fs, references: ps).map {
                    ["id": .string($0.id), "title": .string($0.title), "kind": .string($0.kind), "code": .string($0.code)]
                }) })
                assertJSONEqual(mine, o["out"]!, "relCandidatesFor")
            default: XCTFail(k)
            }
        }
        XCTAssertEqual(seen.count, 10)
    }

    /// Protoсole : les parties d'extrait d'une référence (mdStrip du corps, documents, sources).
    func testProtoSnipParts() {
        var p = Reference(id: "p1")
        p.code = "C1"; p.body = "# Titre\n- [x] fait\n\n| a | b |\n|---|---|"; p.sources = ["S"]
        p.docs = [Attachment(id: "d1", name: "doc.pdf", size: 1)]
        XCTAssertEqual(Search.protoSnipParts(p), ["C1", Markdown.strip(p.body), "doc.pdf", "S"])
    }
}
