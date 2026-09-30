import XCTest
@testable import AidesCore

/// Scénarios de gestes, horloge SIMULÉE — les règles de la spécification B1 (§9 à §16).
final class EngineScenarioTests: XCTestCase {
    final class Spy: SessionEngineDelegate {
        var writes: [JSON] = [], fired: [String] = [], emitted = 0
        func engine(_ e: SessionEngine, persist snapshot: JSON, of R: RuntimeSession) { writes.append(snapshot) }
        func engine(_ e: SessionEngine, timerFired t: TimerState, in R: RuntimeSession) { fired.append(t.id) }
        func engine(_ e: SessionEngine, didMutate R: RuntimeSession) { emitted += 1 }
    }
    var clock = 1_700_000_000_000.0
    var eng = SessionEngine()
    let spy = Spy()

    /// Aide de test : b1 (3 étapes : lance t1, compte n1, normale) → décision bd → b2 (fin) | b1 (boucle).
    func fiche() -> Fiche {
        Sanitize.fiche([
            "id": "f1", "title": "Test", "order": 1, "start": "b1",
            "items": [["id": "i1", "role": "do", "do": "Masser", "starts": "t1"], ["id": "i2", "role": "do", "do": "Choc", "counts": "n1"],
                      ["id": "i3", "role": "do", "do": "Adrénaline", "level": 3],
                      ["id": "i4", "role": "do", "do": "Amiodarone", "from": ["counter": "n1", "n": 3]]],
            "blocks": [["id": "b1", "kind": "do", "title": "RCP", "items": ["i1", "i2", "i3", "i4"], "next": "bd", "timer": "t2"],
                       ["id": "bd", "kind": "decision", "title": "Rythme", "question": "Choquable ?",
                        "options": [["label": "Oui", "target": "b1"], ["label": "Non", "target": "b2"]]],
                       ["id": "b2", "kind": "do", "title": "Fin", "items": ["Surveiller"], "next": .null],
                       ["id": "bx", "kind": "do", "title": "Complication", "items": ["Gérer"], "next": .null]],
            "excursions": [["label": "Complication", "target": "bx"]],
            "timers": [["id": "t1", "label": "Cycle RCP", "type": "interval", "seconds": 120],
                       ["id": "t2", "label": "Bloc", "type": "interval", "seconds": 60, "autoloop": true]],
            "counters": [["id": "n1", "label": "Chocs", "step": 1, "start": 0, "timerId": "t1"]],
        ])
    }
    override func setUp() {
        eng = SessionEngine()
        eng.now = { [unowned self] in self.clock }
        eng.delegate = spy
    }

    func testFirstCheckStartsSessionAndLinkedTimer() {
        let R = RuntimeSession.build(fiche(), session: nil)
        XCTAssertFalse(R.started)
        let r = eng.toggleStep(R, "1:b1:0")
        XCTAssertTrue(r.justStarted)
        XCTAssertTrue(R.started)
        XCTAssertNotNil(eng.live["f1"])
        XCTAssertEqual(R.timers["t1"]?.running, true, "la coche LANCE le minuteur lié")
        XCTAssertEqual(R.timers["t2"]?.running, true, "le minuteur du bloc de départ part avec la session")
        XCTAssertFalse(spy.writes.isEmpty, "démarrage : écriture immédiate")
    }

    func testUncheckWithinGraceRestoresTimer() {
        let R = RuntimeSession.build(fiche(), session: nil)
        eng.toggleStep(R, "1:b1:0")
        clock += 3000
        eng.toggleStep(R, "1:b1:0")   // décoche sous 10 s
        XCTAssertEqual(R.timers["t1"]?.running, false, "le minuteur revient à son état d'avant")
        eng.toggleStep(R, "1:b1:0"); clock += 11_000
        eng.toggleStep(R, "1:b1:0")   // après 10 s : il continue
        XCTAssertEqual(R.timers["t1"]?.running, true)
    }

    func testCountedCheckIncrementsAndVoidsOnUncheck() {
        let R = RuntimeSession.build(fiche(), session: nil)
        eng.toggleStep(R, "1:b1:1")
        XCTAssertEqual(R.counters["n1"], 1)
        XCTAssertEqual(R.events.last?.ref?["v"]?.number, 1)
        XCTAssertEqual(R.timers["t1"]?.running, true, "le « + » du compteur relance son minuteur")
        eng.toggleStep(R, "1:b1:1")
        XCTAssertEqual(R.counters["n1"], 0)
        XCTAssertNotNil(R.events.last?.voidAt, "le repère de la coche est barré, jamais supprimé")
    }

    func testMomentHoldsContinueUntilThreshold() {
        let R = RuntimeSession.build(fiche(), session: nil)
        let b1 = R.fiche.blocks[0]
        for k in ["1:b1:0", "1:b1:1", "1:b1:2"] { eng.toggleStep(R, k) }
        XCTAssertEqual(eng.visitNeed(R, b1, seq: 1).tot, 3, "l'étape « à partir de 3 chocs » ne retient pas encore")
        XCTAssertTrue(eng.instComplete(R, 0))
        R.counters["n1"] = 3
        XCTAssertEqual(eng.visitNeed(R, b1, seq: 1).tot, 4, "au seuil, elle devient requise")
        XCTAssertFalse(eng.instComplete(R, 0))
    }

    func testDecisionLoopAndBlockTimerRestart() {
        let R = RuntimeSession.build(fiche(), session: nil)
        eng.ensureStarted(R)
        clock += 30_000
        eng.continueTo(R, "bd")
        XCTAssertEqual(R.nav, ["b1", "bd"])
        eng.answer(R, decisionAt: 1, target: "b1")
        XCTAssertEqual(R.nav, ["b1", "bd", "b1"])
        XCTAssertEqual(R.navSeq, [1, 2, 3], "une nouvelle visite = des cases neuves")
        XCTAssertEqual(R.timers["t2"]?.lastStart, clock, "le minuteur du bloc repart à CHAQUE entrée de conduite")
        // même réponse une seconde fois depuis la même visite : on regarde, on ne refait pas
        XCTAssertEqual(eng.answer(R, decisionAt: 1, target: "b1"), 2)
        XCTAssertEqual(R.nav.count, 3)
    }

    func testLoopExitStopsBlockTimer() {
        let R = RuntimeSession.build(fiche(), session: nil)
        eng.ensureStarted(R)
        eng.continueTo(R, "bd")
        eng.answer(R, decisionAt: 1, target: "b2")   // sortie de la boucle b1↔bd
        XCTAssertEqual(R.timers["t2"]?.running, false, "sortir de la boucle arrête le minuteur qu'elle avait armé")
        XCTAssertNotEqual(R.linkArm["t2"]?.x, 0)
    }

    func testTickFiresNonLoopingTimerOnceAndLoopsAutoloop() {
        let R = RuntimeSession.build(fiche(), session: nil)
        eng.toggleStep(R, "1:b1:0")   // t1 (120 s) + t2 (60 s, autoloop)
        clock += 125_000
        eng.tick()
        XCTAssertEqual(R.timers["t1"]?.isDue, true)
        XCTAssertEqual(R.timers["t1"]?.running, false)
        XCTAssertEqual(R.timers["t2"]?.running, true, "à cycles : repart aussitôt")
        XCTAssertEqual(R.timers["t2"]?.cycles, 2)
        XCTAssertEqual(Set(spy.fired), ["t1", "t2"])
        spy.fired = []
        clock += 1000; eng.tick()
        XCTAssertFalse(spy.fired.contains("t1"), "un minuteur échu ne resonne pas")
        eng.acknowledge(R, "t1")
        XCTAssertEqual(R.timers["t1"]?.isDue, true, "« ✓ Vu » tait l'alarme, le minuteur reste échu")
    }

    func testComplicationEnterAndResumeRestoresSameVisit() {
        let R = RuntimeSession.build(fiche(), session: nil)
        eng.toggleStep(R, "1:b1:2")
        XCTAssertTrue(eng.enterComplication(R, target: "bx"))
        XCTAssertEqual(R.nav, ["b1", "bx"])
        XCTAssertEqual(R.cxBack[2]?.id, "b1")
        eng.resumeFromComplication(R, backId: "b1")
        XCTAssertEqual(R.nav, ["bx", "b1"], "la MÊME visite interrompue revient au bout (A333)")
        XCTAssertEqual(R.navSeq, [2, 1])
        XCTAssertTrue(R.isChecked("1:b1:2"), "ses coches sont gardées")
        XCTAssertEqual(Graph.navNextIdx(nav: R.nav, navSeq: R.navSeq, 0, cxBack: R.cxBack), 1)
    }

    func testEndArchivesAndStopsTimers() {
        let R = RuntimeSession.build(fiche(), session: nil)
        eng.toggleStep(R, "1:b1:0")
        clock += 5000
        eng.end(R)
        XCTAssertNil(eng.live["f1"])
        XCTAssertEqual(spy.writes.last?["live"], .bool(false))
        XCTAssertEqual(spy.writes.last?["timers"]?["t1"]?["running"], .bool(false))
        XCTAssertEqual(eng.lastEnded?.passes, 1)
    }

    func testRestoreBringsTimersBackPausedWithoutCatchUp() {
        let R = RuntimeSession.build(fiche(), session: nil)
        eng.toggleStep(R, "1:b1:0")
        clock += 10_000
        let snap = R.snapshot(live: true, now: clock)
        clock += 3_600_000   // l'application est restée fermée une heure
        let e2 = SessionEngine(); e2.now = { [unowned self] in self.clock }
        e2.restore(sessions: [SessionSanitize.session(snap)], fiches: ["f1": R.fiche])
        let R2 = e2.live["f1"]!
        XCTAssertEqual(R2.timers["t1"]?.running, false)
        XCTAssertEqual(R2.timers["t1"]?.elapsedMs, 10_000, "le temps app fermée n'est JAMAIS rattrapé")
        XCTAssertEqual(R2.timers["t1"]?.stopClosed, true)
        XCTAssertTrue(R2.isChecked("1:b1:0"))
    }

    func testReportDocument() {
        let R = RuntimeSession.build(fiche(), session: nil)
        eng.toggleStep(R, "1:b1:2"); eng.counterPlus(R, "n1"); eng.stamp(R)
        eng.end(R)
        let doc = Report.document(session: spy.writes.last!, fiche: R.fiche, tags: [], appVersion: "1.0.0", now: clock)
        XCTAssertTrue(doc.html.contains("Compte-rendu de session"))
        XCTAssertTrue(doc.html.contains("Chocs n° 1"))
        XCTAssertTrue(doc.html.contains("Action 1"))
        XCTAssertTrue(doc.html.contains("RCP —</span> ⚠ Adrénaline"))
        XCTAssertEqual(doc.fileName, "compte-rendu-test")
    }
}
