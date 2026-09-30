import XCTest
@testable import AidesCore

final class EngineOracleTests: XCTestCase {
    func cases() throws -> [Oracle.Case] { try Oracle.cases("engine") }

    func testGraphMatchesWeb() throws {
        let c = try cases()[0]
        let f = Sanitize.fiche(c.input["fiche"])
        let ids = f.blocks.map(\.id)
        var reach: [String: JSON] = [:], loop: [String: JSON] = [:]
        for id in ids {
            reach[id] = .array(Graph.reach(f, from: id).sorted().map { .string($0) })
            loop[id] = .bool(Graph.inLoop(f, id))
        }
        let arm: [String: LinkArm] = ["t1": LinkArm(b: "b1", x: 0), "t9": LinkArm(b: "b2", x: 0), "tz": LinkArm(b: "b1", x: 5), "ty": LinkArm(b: "", x: 0)]
        let exits = JSON.array(ids.map { to in .array(Graph.loopExitStops(f, arm: arm, toId: to).map { .string($0) }) })
        let nav = ["b1", "bd", "b1", "bx", "b2", "b1"], seq = [1, 2, 3, 4, 5, 6]
        let latest = JSON.array(ids.map { id in
            Graph.latestPass(nav: nav, navSeq: seq, id).map { ["idx": .int($0.idx), "seq": .int($0.seq), "pass": .int($0.pass), "total": .int($0.total)] } ?? .null
        })
        let pass = JSON.array((nav.indices.map { $0 } + [99]).map { i in let p = Graph.passInfo(nav: nav, i); return ["pass": .int(p.pass), "total": .int(p.total)] })
        let web = c.output
        // L'ordre des clés d'`exits` dépend de l'ordre d'insertion côté JS : on compare en ensembles.
        func sets(_ j: JSON) -> JSON { .array((j.array ?? []).map { .array(($0.array ?? []).sorted { $0.jsString < $1.jsString }) }) }
        assertJSONEqual(normalizeGenerated(.object(reach), input: c.input), normalizeGenerated(web["reach"]!, input: c.input), "reach")
        assertJSONEqual(normalizeGenerated(.object(loop), input: c.input), normalizeGenerated(web["inLoop"]!, input: c.input), "inLoop")
        assertJSONEqual(sets(exits), sets(web["exits"]!), "loopExitStops")
        assertJSONEqual(latest, web["latest"]!, "latestPass")
        assertJSONEqual(pass, web["pass"]!, "passInfo")
    }

    func testMomentsMatchWeb() throws {
        let web = try cases()[1].output.array!
        let its: [Item?] = [nil, Item(id: "a"), { var i = Item(id: "a"); i.from = ItemFrom(counter: "n", n: 2); return i }(),
                            { var i = Item(id: "a"); i.from = ItemFrom(counter: "n", n: 1); return i }(),
                            { var i = Item(id: "a"); i.repeat = .once; return i }(), { var i = Item(id: "a"); i.repeat = .due; return i }(),
                            { var i = Item(id: "a"); i.repeat = .need; return i }(),
                            { var i = Item(id: "a"); i.from = ItemFrom(counter: "n", n: 1); i.repeat = .due; return i }(),
                            { var i = Item(id: "a"); i.from = ItemFrom(counter: "n", n: 1); i.repeat = .need; return i }()]
        var k = 0
        for it in its { for cn in [0.0, 1, 3] { for tm in [Moments.TimerSt.idle, .run, .due] { for before in [false, true] { for tid in ["", "t"] {
            let m = Moments.momentOf(it, counter: { _ in cn }, timer: { _ in tm }, before: before, tid: tid)
            var mine: JSON = .null
            if let m {
                var o: [String: JSON] = ["st": .string(m.st.rawValue)]
                if let w = m.why { o["why"] = .string(w.rawValue) }
                if m.req { o["req"] = 1 }
                mine = .object(o)
            }
            assertJSONEqual(mine, web[k], "momentOf #\(k)")
            k += 1
        } } } } }
        XCTAssertEqual(k, web.count)
    }

    func testJalonsMatchWeb() throws {
        let c = try cases()[2]
        let f = Sanitize.fiche(c.input["fiche"])
        let js = f.blocks.flatMap(\.milestones)
        var prog: [JSON] = []
        for j in js { for (p, n) in [(0, 0.0), (1, 2), (5, 3), (99, 99)] {
            let r = Jalons.progress(j, pass: p, count: n)
            prog.append(["cur": .number(r.cur), "goal": .int(r.goal), "active": .bool(r.active)])
        } }
        assertJSONEqual(.array(prog), c.output["prog"]!, "jalonProg")
        assertJSONEqual(.array(js.map { .string(Jalons.conditionLabel(f, $0)) }), c.output["lbl"]!, "jalonCondLbl")
    }

    /// L'instantané d'une session (format disque et synchro) est IDENTIQUE à celui du web.
    func testSnapshotMatchesWeb() throws {
        for c in try cases()[3...] {
            let f = Sanitize.fiche(c.input["fiche"])
            let sess = c.input["session"].flatMap { $0.isNull ? nil : $0 }
            let R = RuntimeSession.build(f, session: sess)
            let now = c.input["now"]!.number!
            if sess == nil { R.started = true; R.startedAt = now - 1000; R.sessionId = "s0"; R.name = "N" }
            assertJSONEqual(normalizeGenerated(R.snapshot(live: true, now: now), input: c.input),
                            normalizeGenerated(c.output, input: c.input), "snapshot")
        }
    }
}
