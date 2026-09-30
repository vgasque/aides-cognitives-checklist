import XCTest
@testable import AidesCore

extension Proj {
    static func timer(_ j: JSON) -> Live.TimerRun {
        Live.TimerRun(id: j["id"]?.string ?? "", label: j["label"]?.string ?? "", type: j["type"]?.string == "interval" ? .interval : .stopwatch,
                      seconds: Int(j["seconds"]?.number ?? 0), autoloop: j["autoloop"]?.truthy ?? false, onDue: j["onDue"]?.string ?? "",
                      elapsedMs: j["elapsedMs"]?.number ?? 0, running: j["running"]?.truthy ?? false, lastStart: j["lastStart"]?.number ?? 0,
                      cycles: Int(j["cycles"]?.number ?? 0), ack: j["ack"]?.truthy ?? false, adhoc: j["adhoc"]?.truthy ?? false)
    }
    static func wt(_ w: Live.Witness?) -> JSON {
        guard let w else { return .null }
        var o: [String: JSON] = ["cls": .string(w.cls), "g": .string(w.g), "n": .string(w.n)]
        if let v = w.off { o["off"] = .number(v) }
        if let v = w.e { o["e"] = .string(v) }
        if let v = w.v { o["v"] = .string(v) }
        if let v = w.va { o["va"] = .string(v) }
        if let v = w.vb { o["vb"] = .string(v) }
        if let v = w.fresh { o["fresh"] = .bool(v) }
        if let v = w.arm { o["arm"] = .number(v) }
        if let v = w.gr { o["gr"] = .number(v) }
        return .object(o)
    }
    static func tagOpt(_ t: Live.TagOption) -> JSON { ["ref": t.ref, "label": .string(t.label), "src": .string(t.src), "alias": strs(t.alias)] }
    static func mark(_ j: JSON?) -> Live.CountMark? {
        guard let j, !j.isNull else { return nil }
        return Live.CountMark(t: j["t"]!.number!, hasRef: j["ref"] != nil, v: j["ref"]?["v"].map { JS.number($0) })
    }
}

final class LiveOracleTests: XCTestCase {
    func testLiveMatchesWeb() throws {
        var fiches = 0
        for (ci, c) in try Oracle.cases("live").enumerated() {
            let k = c.input["k"]!.string!, o = c.output
            if k == "timers" {
                let ts = c.input["timers"]!.array!.map(Proj.timer)
                let now = c.input["now"]!.number!
                let evs = c.input["events"]!.array!
                let labels = c.input["labels"]!.array!.map { $0.string! }
                XCTAssertEqual(Live.soonMs, o["soon"]!.number!)
                XCTAssertEqual(Live.monNow, o["monNow"]!.number!)
                assertJSONEqual(.array(ts.map { .bool(Live.tmIsDue($0)) }), o["due"]!, "tmIsDue")
                let subsets: [[Live.TimerRun]] = [ts, ts.filter { $0.type == .interval && !$0.running }, ts.filter(\.running), [], Array(ts.prefix(2)), Array(ts.dropFirst(4))]
                let nows = [now, now + 60000, now - 200000]
                assertJSONEqual(.array(nows.map { n in .array(subsets.map { Proj.strs(Live.tmLiveOrder($0, now: n).map(\.id)) }) }), o["order"]!, "tmLiveOrder")
                assertJSONEqual(.array(nows.map { n in .array(subsets.map { Proj.s(Live.monPick($0, now: n)?.id) }) }), o["pick"]!, "monPick")
                let marks = evs.map { Live.EventMark(t: $0["t"]!.number!, voided: $0["voidAt"]?.truthy ?? false) }
                func band(_ b: (past: [Live.BandPast], dated: [Live.BandDated], sans: [Live.BandUndated])) -> JSON {
                    ["past": .array(b.past.map { ["x": .number($0.x), "n": Proj.n($0.n), "lab": .string($0.lab), "t": .number($0.t)] }),
                     "dated": .array(b.dated.map { ["lab": .string($0.lab), "x": .number($0.x), "t": .number($0.t), "ghosts": .array($0.ghosts.map { .number($0) })] }),
                     "sans": .array(b.sans.map { ["lab": .string($0.lab), "val": .string($0.val), "kind": .string($0.kind)] })]
                }
                assertJSONEqual(.array(nows.map { band(Live.monBandData(ts, events: marks, now: $0, labels: labels)) }), o["band"]!, "monBandData")
                assertJSONEqual(band(Live.monBandData(ts, events: marks, now: now)), o["bandNoLab"]!, "monBandData sans libellés")
                assertJSONEqual(.array(nows.map { n in .array(ts.map { let d = Live.timerDisplay($0, now: n); return ["val": .string(d.val), "bw": .number(d.bw)] }) }), o["disp"]!, "timerDisplay")
                assertJSONEqual(.array(nows.map { n in .array(ts.map { .array([Proj.wt(Live.wtTimerModel($0, now: n)),
                    Proj.wt(Live.wtTimerModel($0, now: n, hint: "Indice", gr: 120, exited: true, lat: "au bloc"))]) }) }), o["wt"]!, "wtTimerModel")
                assertJSONEqual(.array(Live.evDeltas(evs).map { $0.map { .number($0) } ?? .null }), o["deltas"]!, "evDeltas")
                continue
            }
            if k == "tags" {
                let mine = JSON.array(Live.sanitizeTags(c.input["tags"]).map { ["k": .string($0.k), "l": .string($0.l), "a": Proj.strs($0.a)] })
                assertJSONEqual(normalizeGenerated(mine, input: c.input), normalizeGenerated(o, input: c.input), "sanitizeTags")
                continue
            }
            let f = Sanitize.fiche(o["f"])
            let L = "fiche \(ci) \(f.id)"
            let tz = TimeZone(identifier: o["tz"]!.string!)!
            let nav = Proj.nav(o["nav"]), navSeq = Proj.ints(o["navSeq"]), ck = Proj.checked(o["checked"])
            let evs = c.input["events"]!.array!
            let now = c.input["now"]!.number!
            XCTAssertEqual(Live.liveWhereText(f, nav: nav, events: evs, tz: tz), o["where"]!.string!, "\(L) liveWhereText")
            XCTAssertEqual(Live.liveWhereText(f, nav: nav, events: [], tz: tz), o["whereNoEv"]!.string!, "\(L) liveWhereText sans repère")
            XCTAssertEqual(Live.liveWhereText(f, nav: [], events: [["t": 0]], tz: tz), o["whereEmpty"]!.string!, "\(L) liveWhereText vide")
            let rts = [Live.TimerRun(id: "a", type: .interval, running: true), Live.TimerRun(id: "b", type: .interval), Live.TimerRun(id: "c", type: .interval, running: true)]
            assertJSONEqual(.array(Live.endSessOpenTxt(f, nav: nav, navSeq: navSeq, checked: ck, timers: rts).map { l -> JSON in
                l.crit ? ["crit": true, "txt": .string(l.txt)] : ["g": Proj.s(l.g), "txt": .string(l.txt)]
            }), o["open"]!, "\(L) endSessOpenTxt")
            let ex = Live.Extra(timers: [(id: "z1", label: "", interval: true, adhoc: true), (id: "z2", label: "Ad hoc nommé", interval: false, adhoc: true)],
                                counters: [(id: "y1", label: "", adhoc: true), (id: "y2", label: "Compteur ad hoc", adhoc: true)])
            let tags: JSON = [["k": "mru", "l": "Médecin régulateur", "a": ["mru", "regul"]], ["l": "Famille prévenue"]]
            let all = Live.tagAll(f, tags: tags, extra: ex)
            assertJSONEqual(.array(all.map(Proj.tagOpt)), o["all"]!, "\(L) tagAll")
            assertJSONEqual(.array(Live.tagAll(f, tags: tags).map(Proj.tagOpt)), o["allNoEx"]!, "\(L) tagAll sans ad hoc")
            let ids = f.blocks.map(\.id)
            let sug: [[Live.TagOption]] = [
                Live.tagSuggest(f, tags: tags, blockId: ids.first, n: 5, extra: ex),
                Live.tagSuggest(f, tags: tags, blockId: ids.count > 1 ? ids[1] : nil, n: 8, garantis: ["counter", "timer"], extra: ex),
                Live.tagSuggest(f, tags: tags, blockId: nil, n: 0, garantis: ["poso"], extra: ex),
                Live.tagSuggest(f, tags: nil, blockId: ids.first, n: -3, extra: ex),
            ]
            assertJSONEqual(.array(sug.map { .array($0.map(Proj.tagOpt)) }), o["sug"]!, "\(L) tagSuggest")
            let b0: JSON = .string(ids.first ?? "x")
            var refs: [JSON] = all.map(\.ref)
            refs += [["type": "counter", "id": "n1", "v": "3"], ["type": "counter", "id": "zz", "v": .null], ["type": "counter", "id": "n1", "v": 2.6],
                     ["type": "step", "b": b0, "i": "1"], ["type": "step", "b": b0, "i": 1.5], ["type": "step", "b": b0, "i": -1], ["type": "step", "b": b0, "i": .null],
                     ["type": "poso", "i": 0], ["type": "poso", "i": 99], ["type": "core", "k": "nope"], ["type": "tag", "k": "mru"], ["type": "x"], .null, "str", ["type": "timer", "id": "z1"]]
            let b0i: JSON = .string(ids.first ?? "x")
            let tkEvs = evs + [["t": 1, "label": "Renommé", "ref": ["type": "core", "k": "renfort"]], ["t": 2], .null, ["t": 3, "ref": ["type": "step", "b": b0i, "i": 0]]]
            assertJSONEqual(Proj.strs(Live.tkLabels(tkEvs, f, tags: tags, extra: ex)), o["tk"]!, "\(L) tkLabels")
            assertJSONEqual(Proj.strsOpt(refs.map { Live.tagLabel($0, f, tags: tags, extra: ex) }), o["labels"]!, "\(L) tagLabel")
            assertJSONEqual(Proj.strsOpt(refs.map { Live.tagLabel($0, f, tags: tags) }), o["labelsNoEx"]!, "\(L) tagLabel sans ad hoc")
            assertJSONEqual(.array(["", "mru", "adrenaline", "regul", "famille", "choc électrique"].map { q in .array(Live.tagRank(q, all).map {
                ["ref": $0.ref, "label": .string($0.label), "src": .string($0.src), "i": Proj.n($0.i), "score": Proj.n($0.score)] }) }), o["rank"]!, "\(L) tagRank")
            let ev = Live.CountMark(t: now - 5000, v: 3), last = Live.CountMark(t: now - 20000, hasRef: false, v: nil)
            assertJSONEqual(.array(f.counters.map { cc in .array([
                Proj.wt(Live.wtCountModel(cc, cur: 2, done: true, ev: ev, last: last, now: now)),
                Proj.wt(Live.wtCountModel(cc, cur: 2, done: true, ev: nil, last: last, now: now)),
                Proj.wt(Live.wtCountModel(cc, cur: 2, done: false, ev: nil, last: last, now: now)),
                Proj.wt(Live.wtCountModel(cc, cur: 0, done: false, ev: nil, last: nil, now: now)),
                Proj.wt(Live.wtCountModel(cc, cur: 5, done: true, ev: Live.CountMark(t: now - 100, v: nil), last: nil, now: now)),
                Proj.wt(Live.wtCountModel(cc, cur: 1, done: true, ev: Live.CountMark(t: now - 100000, v: 0), last: nil, now: now)),
            ]) }), o["count"]!, "\(L) wtCountModel")
            fiches += 1
        }
        XCTAssertEqual(fiches, 40)
    }
}
