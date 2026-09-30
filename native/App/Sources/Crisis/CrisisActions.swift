import SwiftUI
import AidesCore

/// Le contexte de rendu d'une aide ouverte : ce que toute vue de la zone lit, calculé UNE fois
/// par battement (300 ms) — l'heure `now` est la même pour toute la peinture.
struct CrCtx {
    let R: RuntimeSession
    let f: Fiche
    let e: SessionEngine
    let plan: CrPlan
    let now: Double
    /// Largeur EFFECTIVE (fenêtre ÷ taille du texte, règle 10).
    let w: CGFloat
    let wc: WidthClass
    var started: Bool { R.started }
    var hasFlow: Bool { CrisisPure.hasFlow(f) }
    var tipIdx: Int { R.nav.count - 1 }
    var tipBlock: Block? { R.nav.last.flatMap { id in f.blocks.first { $0.id == id } } }
    func block(_ id: String) -> Block? { f.blocks.first { $0.id == id } }
    func seq(_ i: Int) -> Int { i < R.navSeq.count && R.navSeq[i] != 0 ? R.navSeq[i] : 1 }
    /// « bloc n » d'après la numérotation commune ; nil hors du tronc.
    func num(_ id: String) -> Int? { plan.number(id) }
    var narrow360: Bool { w < 360 }
    var narrow430: Bool { w < 430 }
}

/// LES GESTES DU MODE CRISE — chaque geste passe par le moteur (`model.act`), jamais par une
/// logique réécrite dans la vue. Les effets d'AFFICHAGE qui accompagnent un geste (replis qui
/// suivent leur visite, défilement DEMANDÉ, annonce VoiceOver) vivent ici, pas dans le moteur.
@MainActor
struct CrAct {
    let model: AppModel
    let vs: CrisisViewState
    let R: RuntimeSession

    /// Tout geste persisté efface la ligne « Reprise après interruption » (Q2).
    func run(_ body: (SessionEngine, RuntimeSession) -> Void) {
        vs.resumeSince = nil
        model.act(R, body)
    }
    private func dropOpens() { vs.ovFold = CrisisPure.ovDropOpens(vs.ovFold) }
    private func scrollTip(force: Bool) {
        vs.pendingScroll = (force ? "!" : "") + "v\(R.nav.count - 1)"
    }

    // MARK: Démarrage, exercice

    /// `startSessionGesture` : le chrono part, puis la carte vive est amenée sous les couches collantes.
    func start() {
        run { e, R in e.ensureStarted(R) }
        CrLocal.set("start-hint", true)
        scrollTip(force: false)
    }
    func armExercise() {
        model.armExercise(R.fiche)
        vs.ovFold = [:]; vs.verify = nil; vs.dockSheet = .closed
    }
    func cancelExercise() {
        model.cancelExercise(R.fiche)
        crAnnounce("Exercice annulé — la session n’a pas démarré.")
    }

    // MARK: Coches

    /// `ovToggleStep` → `applyCheck` : la coche, ses liens, et le démarrage au premier geste.
    func toggleStep(_ k: String) {
        run { e, R in e.toggleStep(R, k) }
    }
    /// « Faire maintenant » (A382) — une coche comme une autre, jamais « en avance ».
    func doNow(_ k: String) {
        run { e, R in e.doNow(R, k) }
    }
    /// Coche d'une hypothèse de revue ; la revue COMPLÈTE se referme d'elle-même.
    func toggleReview(_ rid: String, _ k: String) {
        run { e, R in e.toggleStep(R, k) }
        if let rb = R.fiche.blocks.first(where: { $0.id == rid }), model.engine.reviewState(R, rb).done { vs.revOpen[rid] = false }
    }
    func newReview(_ rid: String) {
        run { e, R in e.newReview(R, rid) }
        vs.revOpen[rid] = true
    }

    // MARK: Conduite (portes de `linkEnter`)

    func continueTo(_ id: String) {
        dropOpens()
        vs.verify = nil
        run { e, R in e.continueTo(R, id) }
        scrollTip(force: false)
    }
    func answer(_ idx: Int, _ target: String?) {
        guard let target, !target.isEmpty else { return }   // « ▪ fin » : inerte (Q23)
        // La même réponse, redonnée : on REGARDE, on ne refait pas.
        let nx = Graph.navNextIdx(nav: R.nav, navSeq: R.navSeq, idx, cxBack: R.cxBack)
        if nx >= 0 && R.nav[nx] == target {
            vs.ovFold[String(nx)] = false
            vs.pendingScroll = "!v\(nx)"; vs.spotVisit = nx
            return
        }
        dropOpens()
        vs.verify = nil
        run { e, R in _ = e.answer(R, decisionAt: idx, target: target) }
        scrollTip(force: false)
    }
    func redo(_ id: String) {
        dropOpens()
        vs.verify = nil
        run { e, R in e.redo(R, id) }
        scrollTip(force: false)
    }
    func endAlgorithm() {
        dropOpens()
        run { e, R in e.endAlgorithm(R) }
    }
    /// Saut de CONSULTATION (`jumpToBlock`) : ne démarre rien, ne coche rien, ne lance rien.
    func jump(_ id: String) {
        if Graph.latestPass(nav: R.nav, navSeq: R.navSeq, id) == nil {
            dropOpens()
            run { e, R in e.jump(R, id) }
        }
        if let lp = Graph.latestPass(nav: R.nav, navSeq: R.navSeq, id) {
            vs.ovFold[String(lp.idx)] = false
            vs.pendingScroll = "!v\(lp.idx)"
            vs.spotVisit = lp.idx
        }
        vs.showAll = false
    }
    func restartCourse() {
        run { e, R in e.restartCourse(R) }
        vs.ovFold = [:]; vs.verify = nil
        scrollTip(force: true)
    }

    // MARK: Complications (`cxGo` / `cxEnter` / `cxResume`)

    func cxGo(_ c: CrisisPure.Cx) {
        vs.dockSheet = .closed
        guard c.isBlock else { model.openLinked(c.target); return }
        dropOpens()
        let navPos = R.nav.count - 1
        if navPos >= 0 { vs.ovFold[String(navPos)] = true }   // la visite interrompue se replie (jamais une puce)
        vs.verify = nil
        run { e, R in e.enterComplication(R, target: c.target) }
        scrollTip(force: true)
        vs.spotVisit = R.nav.count - 1
    }
    func resume(_ backId: String) {
        dropOpens()
        vs.verify = nil
        var res: (before: [Int], after: [Int])? = nil
        run { e, R in res = e.resumeFromComplication(R, backId: backId) }
        if let res { vs.ovFold = CrisisPure.ovFoldRemap(vs.ovFold, before: res.before, after: res.after) }
        vs.ovFold[String(R.nav.count - 1)] = nil
        scrollTip(force: true)
    }

    // MARK: Vérification (Do-Verify)

    func verifyStart(_ idx: Int) { vs.verify = CrVerify(idx: idx, i: 0, gaps: []) }
    func verifyOK(_ k: String) {
        run { e, R in e.verifyOK(R, key: k) }
        vs.verify?.i += 1
    }
    func verifyGap(_ k: String, _ i: Int) {
        run { e, R in e.verifyGap(R, key: k) }
        vs.verify?.gaps.append(i)
        vs.verify?.i += 1
    }
    func verifyEnd() {
        if R.started { model.engine.persist(R, immediate: true) }
        vs.verify = nil
    }

    // MARK: Minuteurs

    /// Rien ne bouge sous le doigt : le tri vivant attend 1,2 s après tout geste sur un minuteur.
    func holdOrder() { vs.tmHoldUntil = JS.now() + 1200 }
    func toggleTimer(_ id: String) {
        holdOrder()
        Alarm.shared.prepare()
        run { e, R in e.toggleTimer(R, id) }
    }
    func resetTimer(_ id: String) {
        holdOrder()
        run { e, R in e.resetTimer(R, id) }
    }
    func ack(_ id: String) {
        run { e, R in e.acknowledge(R, id) }
        crAnnounce("Alarme acquittée — le minuteur reste échu.")
    }
    func addTimer(_ sec: Int) {
        Alarm.shared.prepare()
        vs.tmAddOpen = false
        run { e, R in e.addAdhocTimer(R, seconds: sec) }
    }
    func restartAdhoc(_ id: String) {
        holdOrder()
        run { e, R in
            e.restartTimer(R, id)
            e.ensureStarted(R)
            e.persist(R, immediate: true)
        }
    }
    func renameTimer(_ id: String, _ label: String) { run { e, R in e.renameAdhocTimer(R, id, label) } }
    func removeTimer(_ id: String) { run { e, R in e.removeAdhocTimer(R, id) } }

    // MARK: Compteurs

    func counterPlus(_ id: String) { run { e, R in e.counterPlus(R, id) } }
    func counterMinus(_ id: String) { run { e, R in e.counterMinus(R, id) } }
    func counterReset(_ id: String) { run { e, R in e.counterReset(R, id) } }
    func addCounter() { run { e, R in e.addAdhocCounter(R) } }
    func renameCounter(_ id: String, _ l: String) { run { e, R in e.renameAdhocCounter(R, id, l) } }
    func removeCounter(_ id: String) { run { e, R in e.removeAdhocCounter(R, id) } }

    // MARK: Journal des actions

    /// « Horodater » : l'HEURE est prise au tap ; la feuille ne fait que nommer.
    func stamp() {
        if case .stamp = vs.dockSheet { vs.dockSheet = .closed; return }
        var id = ""
        run { e, R in id = e.stamp(R) }
        vs.dockSheet = .stamp(id)
    }
    func label(_ id: String, _ text: String) { run { e, R in e.labelEvent(R, id, text) } }
    func tag(_ id: String, _ cand: CrisisPure.TagCand) {
        run { e, R in e.tagEvent(R, id, ref: cand.ref) }
        if cand.type == "counter", let ev = R.events.first(where: { $0.id == id }) {
            let nm = Report.tagLabel(ev.ref, R.fiche, tags: model.library.tags) ?? cand.label
            crAnnounce("Compteur incrémenté : " + nm + " — repère horodaté")
        } else {
            crAnnounce("Repère étiqueté : " + cand.label)
        }
    }
    func toggleVoid(_ id: String) { run { e, R in e.toggleVoid(R, id) } }
    func correctTime(_ id: String, _ t: Double) { run { e, R in e.correctTime(R, id, to: t) } }
    func revertTime(_ id: String) { run { e, R in e.revertTime(R, id) } }

    // MARK: Fin

    /// Confirmation MAINTENUE (1,2 s) : la session s'archive, puis retour à l'accueil.
    func endSession() {
        vs.endOpen = false
        vs.dockSheet = .closed
        vs.voletOpen = false
        vs.verify = nil
        vs.ovFold = [:]
        model.endSession(R)
        model.applyWake(crisisOnScreen: false)
        model.path.removeAll()
    }
}
