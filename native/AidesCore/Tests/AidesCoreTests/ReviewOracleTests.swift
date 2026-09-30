import XCTest
@testable import AidesCore

extension Proj {
    static func offer(_ o: Review.Offer) -> JSON {
        let pre: JSON = o.kind == "interval" ? ["seconds": n(o.seconds!)] : (o.kind == "memory" ? ["itemId": .string(o.itemId!)] : .null)
        return ["id": .string(o.id), "kind": .string(o.kind), "pre": pre, "cible": .string(o.cible), "btn": .string(o.btn), "txt": .string(o.txt)]
    }
}

final class ReviewOracleTests: XCTestCase {
    func testReviewMatchesWeb() throws {
        var fiches = 0
        for (ci, c) in try Oracle.cases("review").enumerated() {
            let k = c.input["k"]!.string!, o = c.output
            if k == "text" {
                let steps = c.input["steps"]!.array!.map { $0.array!.map { $0.string! } }
                assertJSONEqual(.array(steps.map { Proj.strs([Review.stepGuardTxt($0), Review.stepGuardTxt($0, blocOnly: true)]) }), o["guard"]!, "stepGuardTxt")
                assertJSONEqual(Proj.strs(c.input["nf"]!.array!.map { Review.nfGuardTxt($0.array!.map { $0.string! }) }), o["nf"]!, "nfGuardTxt")
                assertJSONEqual(Proj.strs(c.input["nfNum"]!.array!.map { v in let x = JS.number(v); return Review.nfGuardTxt(count: x.isNaN ? 0 : x) }), o["nfNum"]!, "nfGuardTxt(n)")
                assertJSONEqual(Proj.strs(c.input["notes"]!.array!.map { Review.stepNote($0.string!) }), o["notes"]!, "stepNote")
                assertJSONEqual(.array(c.input["short"]!.array!.map { s -> JSON in
                    guard let r = Review.stepShortcut(s.string!) else { return .null }
                    return ["mark": .string(r.mark), "rest": .string(r.rest)]
                }), o["short"]!, "stepShortcut")
                assertJSONEqual(.array(c.input["imports"]!.array!.map { Review.normalizeImport($0) }), o["imports"]!, "normalizeImport")
                assertJSONEqual(Proj.strs(c.input["rel"]!.array!.map { Review.impDupRel($0[0]!.number, $0[1]!.number) }), o["rel"]!, "impDupRel")
                // stepIsCrit / stepIsVigil / stepText / stepCR — déjà portés dans Migrate.swift (`Steps`), vérifiés ici.
                assertJSONEqual(.array(c.input["stepStr"]!.array!.map { v -> JSON in
                    let s = v.string!
                    func cr(_ x: String) -> JSON { let r = Steps.challengeResponse(x); return ["c": .string(r.c), "r": Proj.s(r.r)] }
                    return ["crit": .bool(Steps.isCrit(s)), "vig": .bool(Steps.isVigil(s)), "text": .string(Steps.text(s)), "cr": cr(s), "crt": cr(Steps.text(s))]
                }), o["steps"]!, "stepIsCrit/stepIsVigil/stepText/stepCR")
                continue
            }
            if k == "proto" {
                let ps: [Reference?] = o["ps"]!.array!.map { $0.isNull ? nil : Sanitize.reference($0) }
                assertJSONEqual(.array(ps.map { Proj.strs(Review.flattenProto($0)) }), o["flat"]!, "flattenProto")
                let d = [Review.impDiff(ps[0], ps[1]), Review.impDiff(nil as Reference?, ps[1]), Review.impDiff(ps[0], nil as Reference?)]
                assertJSONEqual(.array(d.map { ["plus": Proj.strs($0.plus), "moins": Proj.strs($0.moins)] }), o["diff"]!, "impDiff (référence)")
                assertJSONEqual(.array(ps.compactMap { $0 }.map { Proj.strs(Search.protoSnipParts($0)) }), o["snip"]!, "protoSnipParts")
                continue
            }
            let f = Sanitize.fiche(o["f"])
            let prev: Fiche? = o["prev"]!.isNull ? nil : Sanitize.fiche(o["prev"])
            let L = "fiche \(ci) \(f.id)"
            assertJSONEqual(.array(Review.reviewNotes(f).map { ["at": .string($0.at), "cible": .string($0.cible), "txt": .string($0.txt)] }), o["notes"]!, "\(L) reviewNotes")
            assertJSONEqual(.array(Review.reviewOffers(f).map(Proj.offer)), o["offers"]!, "\(L) reviewOffers")
            assertJSONEqual(.array(Review.reviewOffers(f, refused: ["tm", "cn"]).map(Proj.offer)), o["offersRef"]!, "\(L) reviewOffers (refus)")
            assertJSONEqual(Proj.strs(Review.flattenFiche(f)), o["flat"]!, "\(L) flattenFiche")
            let d = Review.diffFicheLines(f, prev), dn = Review.diffFicheLines(nil, f)
            assertJSONEqual(["removed": Proj.strs(d.removed), "added": Proj.strs(d.added)], o["diff"]!, "\(L) diffFicheLines")
            assertJSONEqual(["removed": Proj.strs(dn.removed), "added": Proj.strs(dn.added)], o["diffNull"]!, "\(L) diffFicheLines(null)")
            let im = Review.impDiff(prev, f)
            assertJSONEqual(["plus": Proj.strs(im.plus), "moins": Proj.strs(im.moins)], o["imp"]!, "\(L) impDiff")
            fiches += 1
        }
        XCTAssertGreaterThan(fiches, 160)
    }
}
