import XCTest
@testable import AidesCore

/// Projections JSON des types natifs dans la forme exacte que rend la PWA.
enum Proj {
    static func s(_ x: String?) -> JSON { x.map { .string($0) } ?? .null }
    static func n(_ x: Int) -> JSON { .number(Double(x)) }
    static func strs(_ a: [String]) -> JSON { .array(a.map { .string($0) }) }
    static func plan(_ p: Parcours.Plan) -> JSON {
        ["order": strs(p.order), "items": .array(p.items.map { it -> JSON in
            switch it {
            case .block(let id, let d): return ["k": "block", "id": .string(id), "depth": n(d)]
            case .branchOpen(let dec, let oi, let label, let tgt, let d):
                return ["k": "bropen", "dec": .string(dec), "oi": n(oi), "label": .string(label), "tgt": s(tgt), "depth": n(d)]
            case .branchClose: return ["k": "brclose"]
            case .link(let to, let from, let d, let back): return ["k": "link", "to": .string(to), "from": s(from), "depth": n(d), "back": .bool(back)]
            case .end(let d): return ["k": "end", "depth": n(d)]
            }
        })]
    }
    static func mini(_ m: Parcours.BlockState) -> JSON {
        ["id": .string(m.id), "n": n(m.n), "title": .string(m.title), "dec": .bool(m.dec), "off": .bool(m.off), "cur": .bool(m.cur),
         "visited": .bool(m.visited), "seq": n(m.seq), "done": n(m.done), "tot": n(m.tot), "complete": .bool(m.complete), "taken": s(m.taken),
         "pass": n(m.pass), "total": n(m.total)]
    }
    static func cx(_ c: Parcours.Complication) -> JSON {
        ["label": .string(c.label), "target": .string(c.target), "short": .string(c.short), "kind": .string(c.kind)]
    }
    /// JSON d'entrée d'un scénario → types natifs.
    static func checked(_ j: JSON?) -> Set<String> { Set((j?.object ?? [:]).filter { $0.value.truthy }.keys) }
    static func nav(_ j: JSON?) -> [String] { (j?.array ?? []).map { $0.string ?? "" } }
    static func ints(_ j: JSON?) -> [Int] { (j?.array ?? []).map { Int($0.number ?? 0) } }
}

final class ParcoursOracleTests: XCTestCase {
    func testParcoursMatchesWeb() throws {
        var fiches = 0
        for (ci, c) in try Oracle.cases("parcours").enumerated() {
            let k = c.input["k"]!.string!
            if k == "labels" {
                let labels = c.input["labels"]!.array!.map { $0.string! }
                let mine = JSON.array(labels.map { l in
                    let p = Parcours.tmLabelParts(l)
                    return ["tm": .string(Parcours.tmShort(TimerDef(id: "t", label: l, type: .stopwatch))),
                            "cn": .string(Parcours.cnShort(CounterDef(id: "c", label: l))),
                            "cx": .string(Parcours.cxShort(label: l, short: nil)),
                            "head": .string(Parcours.autoShortHead(l, 9)), "key": .string(Parcours.cxKeyLabel(l)),
                            "parts": ["name": .string(p.name), "meta": .string(p.meta)]]
                })
                assertJSONEqual(mine, c.output, "libellés")
                continue
            }
            if k == "optAbbr" {
                let mine = JSON.array(c.input["lists"]!.array!.map { Proj.strs(Parcours.optAbbr($0.array!.map { $0.string! })) })
                assertJSONEqual(mine, c.output, "optAbbr")
                continue
            }
            let o = c.output
            let f = Sanitize.fiche(o["f"])
            assertJSONEqual(f.json, o["f"]!, "fiche \(ci) relue")
            let L = "fiche \(ci) \(f.id)"
            assertJSONEqual(Proj.plan(Parcours.flowPlan(f)), o["plan"]!, "\(L) flowPlan")
            assertJSONEqual(.array(Parcours.cxAll(f).map(Proj.cx)), o["cxAll"]!, "\(L) cxAll")
            assertJSONEqual(.array(Parcours.cxDetached(f).map(Proj.cx)), o["cxDetached"]!, "\(L) cxDetached")
            assertJSONEqual(.array(f.items.map { it -> JSON in
                switch Parcours.linkOf(it) {
                case .timer(let id)?: return ["k": "tm", "id": .string(id)]
                case .counter(let id)?: return ["k": "cn", "id": .string(id)]
                case nil: return .null
                }
            }), o["links"]!, "\(L) linkOf")
            assertJSONEqual(.array(f.blocks.map { b in Proj.strs(b.milestones.map { Parcours.jalonCondLbl(f, $0) }) }), o["jalons"]!, "\(L) jalons")
            assertJSONEqual(Proj.s(Parcours.cycleHint(f)?.id), o["cycle"]!, "\(L) cycleHint")
            XCTAssertEqual(Parcours.cycleTxt(f), o["cycleTxt"]!.string!, "\(L) cycleTxt")
            assertJSONEqual(Proj.strs(Parcours.phasesOf(f)), o["phases"]!, "\(L) phasesOf")
            assertJSONEqual(Proj.strs(f.blocks.map { Parcours.phaseOf(f, $0.id) }), o["phase"]!, "\(L) phaseOf")
            assertJSONEqual(Proj.strs(Parcours.completionSpots(f)), o["spots"]!, "\(L) completionSpots")
            assertJSONEqual(.array(Parcours.ListKey.allCases.map { Proj.strs(Parcours.listOf(f, $0)) }), o["lists"]!, "\(L) listOf")
            assertJSONEqual(.array(f.blocks.map { Proj.strs(Parcours.stepsOf(f, $0)) }), o["steps"]!, "\(L) stepsOf")
            assertJSONEqual(Proj.strs(Parcours.forgetAll(f)), o["forget"]!, "\(L) forgetAll")
            for (key, extra) in [("groups", 0), ("groupsOver", 2)] {
                assertJSONEqual(.array(f.blocks.map { b -> JSON in
                    let its = Pool.blockItems(f, b)
                    return .array(Parcours.stepGroups(its, its.count + extra).map { g -> JSON in
                        guard let fr = g.from else { return ["from": .null, "ix": .array(g.ix.map(Proj.n))] }
                        return ["from": ["counter": .string(fr.counter), "n": Proj.n(fr.n)], "it": g.item?.json ?? .null, "ix": .array(g.ix.map(Proj.n))]
                    })
                }), o[key]!, "\(L) \(key)")
            }
            assertJSONEqual(.array(f.items.map { Proj.strs([Parcours.stepQualTxt(f, $0), Parcours.stepQualTxt(f, $0, faite: true), Parcours.stepQualTxt(f, $0, sansOnce: true)]) }),
                            o["qual"]!, "\(L) stepQualTxt")
            assertJSONEqual(Proj.strs(f.blocks.map { Parcours.blkTimerTxt(f, $0) }), o["btimer"]!, "\(L) blkTimerTxt")
            assertJSONEqual(["tm": Proj.strs(f.timers.map(Parcours.tmShort)), "cn": Proj.strs(f.counters.map(Parcours.cnShort)),
                             "cx": Proj.strs(f.excursions.map { Parcours.cxShort(label: $0.label, short: $0.short) })], o["shorts"]!, "\(L) noms courts")
            // Scénarios de journal
            let scen = c.input["scen"]!.array!
            for (si, s) in scen.enumerated() {
                let nav = Proj.nav(s["nav"]), seq = Proj.ints(s["navSeq"]), ck = Proj.checked(s["checked"])
                let np: Int? = s["navPos"]?.number.map { Int($0) }
                let ws = o["scen"]![si]!
                let SL = "\(L) scénario \(si)"
                assertJSONEqual(Proj.strs(Parcours.offPathSet(f, nav: nav, navPos: np).sorted()), ws["off"]!, "\(SL) offPathSet")
                assertJSONEqual(.array(Parcours.minimapData(f, nav: nav, navSeq: seq, checked: ck, navPos: np).map(Proj.mini)), ws["mini"]!, "\(SL) minimapData")
                var ckd: [String: Bool] = [:]
                for (kk, v) in s["checked"]!.object! { ckd[kk] = v.truthy }
                assertJSONEqual(.object(Parcours.revKeysLift(f, ckd).mapValues { .bool($0) }), ws["lift"]!, "\(SL) revKeysLift")
                assertJSONEqual(.array(Parcours.revBlocks(f).map { rb in
                    let r = Parcours.revState(f, rb, seq: "r", checked: ck)
                    return ["k": Proj.n(r.k), "n": Proj.n(r.n), "done": .bool(r.done)]
                }), ws["rev"]!, "\(SL) revState")
                let moOf: (Item, Int) -> Parcours.MomentInfo? = { _, i in
                    i % 3 == 0 ? .init(st: "wait") : (i % 3 == 1 ? .init(st: "met", req: true) : (i % 5 == 2 ? .init(st: "gone") : nil))
                }
                let band = { (b: Block, sq: String, mo: ((Item, Int) -> Parcours.MomentInfo?)?) -> JSON in
                    .array(Parcours.posBandModel(f, b, seq: sq, checked: ck, moOf: mo).map {
                        ["id": .string($0.id), "name": .string($0.name), "body": .string($0.body), "note": .string($0.note), "stt": .string($0.stt)]
                    })
                }
                let s0 = seq.first.map { $0 == 0 ? 1 : $0 } ?? 1
                assertJSONEqual(.array(f.blocks.map { band($0, String(s0), moOf) }), ws["band"]!, "\(SL) posBandModel")
                assertJSONEqual(.array(f.blocks.map { band($0, "1", nil) }), ws["bandNoMo"]!, "\(SL) posBandModel sans moment")
            }
            fiches += 1
        }
        XCTAssertGreaterThan(fiches, 75)
    }
}
