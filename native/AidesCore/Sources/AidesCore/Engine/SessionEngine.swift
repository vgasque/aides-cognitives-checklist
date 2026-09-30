import Foundation

// MOTEUR DE SESSION — les gestes du mode crise (port de applyCheck, linkOnCheck, linkEnter,
// navAdvance/navRestore, ovAnswer, cxEnter/cxResume, toggleTimer/resetTimer/tmRestart, tickAll,
// cnInc/cnBump, tkNoteNow, ensureStarted, endSession, persistLive…).
//
// RÈGLE 11 : le mode crise n'est JAMAIS interrompu. Le moteur ne présente rien : il signale
// (délégué) et l'interface décide, sans modale ni défilement automatique.
// « NAVIGUER N'EST PAS CONDUIRE » : seuls les gestes de CONDUITE (Continuer, réponse, Refaire,
// complication, démarrage) passent par `linkEnter` ; un saut de consultation ne lance rien.

/// Ce que le moteur demande au monde extérieur (persistance, alarmes, partage).
public protocol SessionEngineDelegate: AnyObject {
    /// Écrire l'instantané d'une session (live:true en cours, false à l'archivage).
    func engine(_ e: SessionEngine, persist snapshot: JSON, of R: RuntimeSession)
    /// Un minuteur à échéance vient de sonner (son, vibration, flash, notification).
    func engine(_ e: SessionEngine, timerFired t: TimerState, in R: RuntimeSession)
    /// Point d'émission UNIQUE du partage (appelé avant la temporisation d'écriture).
    func engine(_ e: SessionEngine, didMutate R: RuntimeSession)
    /// Une session vient de démarrer / de se terminer (notifications, veille d'écran…).
    func engine(_ e: SessionEngine, started R: RuntimeSession)
    func engine(_ e: SessionEngine, ended R: RuntimeSession, snapshot: JSON?)
    /// Petit retour haptique (coche, compteur +).
    func engineTick(_ e: SessionEngine)
}

public extension SessionEngineDelegate {
    func engine(_ e: SessionEngine, timerFired t: TimerState, in R: RuntimeSession) {}
    func engine(_ e: SessionEngine, didMutate R: RuntimeSession) {}
    func engine(_ e: SessionEngine, started R: RuntimeSession) {}
    func engine(_ e: SessionEngine, ended R: RuntimeSession, snapshot: JSON?) {}
    func engineTick(_ e: SessionEngine) {}
}

/// Bilan éphémère de la dernière session terminée (carte de l'accueil).
public struct EndedRecap: Equatable, Sendable {
    public var id: String
    public var title: String
    public var dur: Double
    public var passes: Int
    public var done: Int
    public var exercise: Bool
}

public final class SessionEngine {
    public static let linkGraceMs: Double = 10_000
    public static let soonMs: Double = 20_000
    public static let persistDebounceMs: Double = 700
    public static let adhocDurations = [60, 120, 180, 300]
    public static let maxAdhocCounters = 20

    /// Horloge injectable (tests) : ms depuis l'époque.
    public var now: () -> Double = JS.now
    /// Horloge du journal (`vfNow`) : corrigée par le serveur pendant un partage.
    public var eventNow: (() -> Double)?
    public weak var delegate: SessionEngineDelegate?
    /// Toutes les sessions DÉMARRÉES et vives, une par aide.
    public private(set) var live: [String: RuntimeSession] = [:]
    public private(set) var lastEnded: EndedRecap?
    /// Garde de rôle du partage (invité) : peut-on écrire ce geste ?
    public var canWrite: (String) -> Bool = { _ in true }

    private var pendingPersist: [ObjectIdentifier: Double] = [:]

    public init() {}

    func vfNow() -> Double { eventNow?() ?? now() }

    // MARK: Cycle de vie

    /// `buildRuntime` pour une aide sans session, ou la session vive si elle existe (`openRead`).
    public func runtimeFor(_ f: Fiche, keepIfNotStarted current: RuntimeSession? = nil) -> RuntimeSession {
        if let R = live[f.id] { R.fiche = f; return R }
        if let c = current, c.ficheId == f.id, !c.started { c.fiche = f; return c }
        return RuntimeSession.build(f, session: nil)
    }

    /// `restoreLiveSessions` : au lancement, chaque session `live:true` dont l'aide existe revient
    /// — minuteurs EN PAUSE (le temps app fermée n'est JAMAIS rattrapé).
    public func restore(sessions: [JSON], fiches: [String: Fiche]) {
        for s in sessions where s["live"]?.truthy == true {
            guard let fid = s["ficheId"]?.string, let f = fiches[fid], f.deletedAt == nil else { continue }
            let R = RuntimeSession.build(f, session: s)
            R.started = true
            let st = s["startedAt"]?.number ?? 0, sv = s["savedAt"]?.number ?? 0
            R.startedAt = st != 0 ? st : (sv != 0 ? sv : now())
            live[fid] = R
        }
    }

    /// `ensureStarted` : démarre la session DÈS le premier geste qui agit. Rend vrai si elle vient de démarrer.
    @discardableResult
    public func ensureStarted(_ R: RuntimeSession) -> Bool {
        if R.started { return false }
        if R.essai || R.guest {
            // L'essai (K5) démarre sans jamais entrer dans le registre des sessions vives.
            if R.essai {
                R.started = true; R.startedAt = now(); R.aidRev = R.fiche.updatedAt
                if R.sessionId == nil { R.sessionId = Guard.uid("s") }
                linkEnter(R, R.nav.last, noExit: true)
                return true
            }
            return false
        }
        lastEnded = nil
        R.started = true; R.startedAt = now(); R.aidRev = R.fiche.updatedAt
        if R.sessionId == nil { R.sessionId = Guard.uid("s") }
        if R.name.isEmpty { R.name = Fmt.autoSessionName(R.fiche.title, now: now()) }
        live[R.ficheId] = R
        linkEnter(R, R.nav.last, noExit: true)
        delegate?.engine(self, started: R)
        persist(R, immediate: true)
        return true
    }

    /// Essai d'un brouillon (« ▶ Essayer ») : même moteur, rien n'est écrit ni émis.
    public func trialRuntime(_ draft: Fiche) -> RuntimeSession {
        let R = RuntimeSession.build(draft, session: nil)
        R.essai = true
        return R
    }

    /// `endSession(R)` : arrête les minuteurs, archive (`live:false`), sort du registre vif.
    public func end(_ R: RuntimeSession) {
        for id in R.timerOrder where R.timers[id]?.running == true { toggleTimer(R, id, persist: false) }
        if R.essai { R.started = false; R.essai = false; R.sessionId = nil; R.name = ""; return }
        if R.startedAt == 0 { R.startedAt = now() }
        let snap = R.snapshot(live: false, now: now())
        delegate?.engine(self, persist: snap, of: R)
        var done = 0
        for i in R.nav.indices where instComplete(R, i) { done += 1 }
        lastEnded = EndedRecap(id: R.sessionId ?? "", title: R.fiche.title.isEmpty ? "Aide cognitive" : R.fiche.title,
                               dur: max(0, now() - R.startedAt), passes: R.nav.count, done: done, exercise: R.exercise)
        live[R.ficheId] = nil
        pendingPersist[ObjectIdentifier(R)] = nil
        R.started = false; R.sessionId = nil; R.name = ""
        delegate?.engine(self, ended: R, snapshot: snap)
    }
    public func clearLastEnded() { lastEnded = nil }

    /// `resumeSession(id)` : une session ARCHIVÉE redevient vive (même id), ou la vive est reprise.
    public func resume(_ f: Fiche, session s: JSON) -> RuntimeSession {
        let sid = s["id"]?.string
        if let R = live[f.id], R.sessionId == sid { R.fiche = f; return R }
        if let other = live[f.id] { end(other) }   // Q5 : jamais deux sessions vives pour une même aide
        let R = RuntimeSession.build(f, session: s)
        R.started = true
        let st = s["startedAt"]?.number ?? 0
        R.startedAt = st != 0 ? st : now()
        R.aidRev = s["aidRev"]?.number ?? 0
        live[f.id] = R
        persist(R, immediate: true)
        return R
    }

    /// Retire une session vive du registre sans l'archiver (suppression de l'historique).
    public func drop(sessionId: String) {
        for (k, R) in live where R.sessionId == sessionId { live[k] = nil; R.started = false }
    }

    // MARK: Persistance (`persistLive`)

    /// Toute mutation passe ici : c'est aussi le point d'émission UNIQUE du partage.
    public func persist(_ R: RuntimeSession, immediate: Bool = false) {
        guard R.started else { return }
        R.lastActAt = now()
        if R.essai { return }
        delegate?.engine(self, didMutate: R)
        if R.guest { return }                       // l'invité émet mais n'écrit rien
        let key = ObjectIdentifier(R)
        if immediate { pendingPersist[key] = nil; write(R) }
        else if pendingPersist[key] == nil { pendingPersist[key] = now() + Self.persistDebounceMs }
    }
    func write(_ R: RuntimeSession) {
        delegate?.engine(self, persist: R.snapshot(live: true, now: now()), of: R)
    }
    /// Écrit les instantanés dont la temporisation (700 ms) est écoulée — appelé par `tick`.
    public func flushDue() {
        let t = now()
        for R in live.values {
            let k = ObjectIdentifier(R)
            if let due = pendingPersist[k], due <= t { pendingPersist[k] = nil; write(R) }
        }
    }
    /// `persistAllLive` : passage en arrière-plan, fermeture…
    public func persistAll() {
        for R in live.values { pendingPersist[ObjectIdentifier(R)] = nil; if !R.essai && !R.guest { write(R) } }
    }

    // MARK: Coches

    /// `ckItem(f, k)` : l'item d'une clé de cochage (nil pour une décision ou un bloc inconnu).
    public func item(_ R: RuntimeSession, key k: String) -> (block: Block, item: Item?)? {
        let p = k.split(separator: ":", omittingEmptySubsequences: false)
        guard p.count == 3, let b = Graph.byId(R.fiche.blocks)[String(p[1])], b.kind != .decision, let i = Int(p[2]) else { return nil }
        let its = Pool.blockItems(R.fiche, b)
        return (b, i < its.count ? its[i] : nil)
    }

    /// `applyCheck(k, on)` — LE point d'écriture unique de `checked`.
    @discardableResult
    public func applyCheck(_ R: RuntimeSession, _ k: String, _ on: Bool) -> Bool {
        if R.guest && !canWrite(on ? "check" : "uncheck") { return false }
        delegate?.engineTick(self)
        R.setChecked(k, on)
        if on { R.vgaps[k] = nil } else { R.verified[k] = nil }
        if !on { R.flowEnded = false }
        linkOnCheck(R, k, on)
        return true
    }

    /// Le geste complet sur une rangée d'étape (`ovToggleStep` + `paintCheckRow`) : bascule,
    /// démarre la session si besoin, enregistre. Rend (appliqué, vient de démarrer).
    @discardableResult
    public func toggleStep(_ R: RuntimeSession, _ k: String) -> (applied: Bool, justStarted: Bool) {
        let on = !R.isChecked(k)
        guard applyCheck(R, k, on) else { return (false, false) }
        let js = ensureStarted(R)
        persist(R)
        return (true, js)
    }

    /// « Faire maintenant » (A382) : coche une étape avant son moment. (Q7 corrigé : on enregistre.)
    public func doNow(_ R: RuntimeSession, _ k: String) {
        guard applyCheck(R, k, true) else { return }
        ensureStarted(R)
        persist(R)
    }

    func linkOf(_ it: Item?) -> (tm: String?, cn: String?) {
        guard let it else { return (nil, nil) }
        if let s = it.starts { return (s, nil) }
        if let c = it.counts { return (nil, c) }
        return (nil, nil)
    }

    /// `linkOnCheck(k, on)` (A377) — effets d'une coche LIÉE, geste local seulement.
    func linkOnCheck(_ R: RuntimeSession, _ k: String, _ on: Bool) {
        guard let ci = item(R, key: k) else { return }
        let L = linkOf(ci.item)
        if let tid = L.tm {
            guard R.timers[tid] != nil else { return }
            if on {
                let r = arm(R, tid, "")
                R.linkGrace[k] = LinkGrace(real: now(), tid: tid, prev: r?.prev, prevArm: r?.prevArm)
                R.linkArm[tid]?.ck = k
            } else if let g = R.linkGrace.removeValue(forKey: k), now() - g.real < Self.linkGraceMs {
                if let p = g.prev { R.timers[g.tid] = p }
                R.linkBack[k] = now()
                R.linkArm[g.tid] = g.prevArm
            }
            return
        }
        if let cid = L.cn {
            guard let c = R.fiche.counters.first(where: { $0.id == cid }) else { return }
            let step = Double(max(1, c.step))
            if on {
                let idx = counterBump(R, cid, step)
                R.events[idx].ck = k
                return
            }
            let before = R.counters[cid] ?? 0
            R.counters[cid] = max(0, before - step)
            R.linkBack[k] = now()
            let evs = R.events.indices.filter { R.events[$0].refType == "counter" && R.events[$0].refId == cid && !R.events[$0].isVoid }.reversed()
            if let e = evs.first(where: { R.events[$0].ck == k }) ?? evs.first(where: { R.events[$0].ref?["v"]?.number == before }) {
                R.events[e].voidAt = vfNow()
            }
        }
    }

    /// `linkArm(R, tid, bid)` : arme depuis zéro ; rend l'état d'avant (annulation de 10 s).
    @discardableResult
    func arm(_ R: RuntimeSession, _ tid: String, _ bid: String) -> (prev: TimerState, prevArm: LinkArm?)? {
        guard let t = R.timers[tid] else { return nil }
        let r = (prev: t, prevArm: R.linkArm[tid])
        restartTimer(R, tid)
        R.linkArm[tid] = LinkArm(b: bid, x: 0)
        return r
    }

    /// `linkEnter(f, toId, noExit)` — LA PORTE DE CONDUITE : arrêts de sortie de boucle + minuteur du bloc.
    public func linkEnter(_ R: RuntimeSession, _ toId: String?, noExit: Bool = false) {
        guard R.started, let toId, !toId.isEmpty else { return }
        if !noExit {
            for tid in Graph.loopExitStops(R.fiche, arm: R.linkArm, toId: toId) {
                guard var t = R.timers[tid] else { continue }
                if t.running { toggleTimer(R, tid, persist: false) } else { t.ack = true; R.timers[tid] = t }
                R.linkArm[tid]?.x = now()
            }
        }
        if let b = Graph.byId(R.fiche.blocks)[toId], let tm = b.timer, R.timers[tm] != nil { arm(R, tm, b.id) }
    }

    // MARK: Moments (A382)

    public func momentTimerState(_ R: RuntimeSession, _ id: String) -> Moments.TimerSt {
        guard let t = R.timers[id] else { return .idle }
        return t.isDue ? .due : (t.running ? .run : .idle)
    }
    /// `stepMoment(it, seq, bid, i)`.
    public func stepMoment(_ R: RuntimeSession, _ it: Item?, seq: Int, blockId: String, index i: Int) -> Moment? {
        let suf = ":\(blockId):\(i)"
        let before = it?.repeat == .once && R.checkedKeys.contains { $0.hasSuffix(suf) && !$0.hasPrefix("\(seq):") }
        return Moments.momentOf(it, counter: { R.counters[$0] ?? 0 }, timer: { self.momentTimerState(R, $0) },
                                before: before, tid: Moments.timerId(R.fiche, it))
    }

    // MARK: Complétude

    /// `visitNeed(b, seq, checked)` : ce que « Continuer » attend.
    public func visitNeed(_ R: RuntimeSession, _ b: Block, seq: Int) -> (tot: Int, dn: Int) {
        let its = Pool.blockItems(R.fiche, b)
        var tot = 0, dn = 0
        for i in Graph.cleanSteps(R.fiche, b).indices {
            let it = i < its.count ? its[i] : nil
            if it?.review != nil { continue }
            let on = R.isChecked("\(seq):\(b.id):\(i)")
            if Moments.required(stepMoment(R, it, seq: seq, blockId: b.id, index: i), on: on) { tot += 1; if on { dn += 1 } }
        }
        return (tot, dn)
    }
    /// `instComplete(f, nav, navSeq, checked, idx, cxb)`.
    public func instComplete(_ R: RuntimeSession, _ idx: Int) -> Bool {
        guard idx >= 0, idx < R.nav.count, let b = R.fiche.blocks.first(where: { $0.id == R.nav[idx] }) else { return false }
        if b.kind == .decision {
            let nx = Graph.navNextIdx(nav: R.nav, navSeq: R.navSeq, idx, cxBack: R.cxBack)
            let t = nx >= 0 ? R.nav[nx] : nil
            return b.options.contains { $0.target != nil && $0.target == t }
        }
        let n = visitNeed(R, b, seq: idx < R.navSeq.count && R.navSeq[idx] != 0 ? R.navSeq[idx] : 1)
        return n.dn >= n.tot
    }
    /// L'option de décision prise à la visite `idx` (`decTaken`).
    public func decisionTaken(_ R: RuntimeSession, _ idx: Int) -> DecisionOption? {
        guard idx < R.nav.count, let b = Graph.byId(R.fiche.blocks)[R.nav[idx]], b.kind == .decision else { return nil }
        let nx = Graph.navNextIdx(nav: R.nav, navSeq: R.navSeq, idx, cxBack: R.cxBack)
        guard nx >= 0 else { return nil }
        return b.options.first { $0.target != nil && $0.target == R.nav[nx] }
    }

    // MARK: Navigation

    /// `navAdvance(id)` : nouvelle visite au bout du journal.
    public func navAdvance(_ R: RuntimeSession, _ id: String, persist p: Bool = true) {
        R.seq += 1
        R.nav.append(id); R.navSeq.append(R.seq)
        if p && R.started { persist(R) }
    }
    /// « Continuer — … → » : geste de conduite.
    public func continueTo(_ R: RuntimeSession, _ toId: String) {
        linkEnter(R, toId)
        navAdvance(R, toId)
    }
    /// Réponse à une décision depuis la visite `idx` (`ovAnswer`). Rend l'index de la visite à
    /// montrer si la même réponse était déjà donnée (« regarder », pas refaire).
    @discardableResult
    public func answer(_ R: RuntimeSession, decisionAt idx: Int, target: String?) -> Int? {
        guard let target, !target.isEmpty, R.fiche.blocks.contains(where: { $0.id == target }), idx < R.nav.count else { return nil }
        let dec = R.nav[idx]
        let nx = Graph.navNextIdx(nav: R.nav, navSeq: R.navSeq, idx, cxBack: R.cxBack)
        if nx >= 0 && R.nav[nx] == target { return nx }
        if R.nav.last != dec { navAdvance(R, dec, persist: false) }   // répondre à une décision ANCIENNE : nouveau passage d'abord
        linkEnter(R, target)
        navAdvance(R, target, persist: false)
        if R.started { persist(R) }
        return nil
    }
    /// « Refaire » : nouvelle visite d'un bloc complet (`ovNewPass`).
    public func redo(_ R: RuntimeSession, _ id: String) {
        guard R.fiche.blocks.contains(where: { $0.id == id }) else { return }
        linkEnter(R, id)
        navAdvance(R, id, persist: false)
        if R.started { persist(R) }
    }
    /// « Terminer l’algorithme ✓ ».
    public func endAlgorithm(_ R: RuntimeSession) {
        R.flowEnded = true
        if R.started { persist(R) }
    }
    /// Saut de CONSULTATION (`jumpToBlock`) : un bloc jamais visité devient une visite, sans rien lancer.
    /// Rend vrai si une visite a été ajoutée.
    @discardableResult
    public func jump(_ R: RuntimeSession, _ id: String) -> Bool {
        if Graph.latestPass(nav: R.nav, navSeq: R.navSeq, id) != nil { return false }
        navAdvance(R, id)
        return true
    }
    /// « Recommencer le parcours » : le chemin est effacé, chrono/minuteurs/compteurs conservés.
    public func restartCourse(_ R: RuntimeSession) {
        guard let s = R.fiche.start ?? R.fiche.blocks.first?.id else { return }
        R.nav.removeAll(); R.navSeq.removeAll()
        R.seq += 1
        R.nav.append(s); R.navSeq.append(R.seq)
        R.flowEnded = false
        linkEnter(R, s)
        if R.started { persist(R) }
    }
    /// `navRestore(k)` (A333) : la visite `k` revient au bout, coches gardées. Rend (avant, après) navSeq.
    @discardableResult
    public func navRestore(_ R: RuntimeSession, _ k: Int) -> (before: [Int], after: [Int]) {
        let avant = R.navSeq
        let id = R.nav.remove(at: k), sq = R.navSeq.remove(at: k)
        R.nav.append(id); R.navSeq.append(sq)
        if R.started { persist(R) }
        return (avant, R.navSeq)
    }

    // MARK: Complications (excursions)

    /// `cxEnter(f, target)` : entrée dans un bloc « à tout moment » de CETTE aide, avec retour.
    /// Rend faux si la cible est une autre aide (l'interface l'ouvre).
    @discardableResult
    public func enterComplication(_ R: RuntimeSession, target: String) -> Bool {
        guard R.fiche.blocks.contains(where: { $0.id == target }) else { return false }
        let from = R.nav.last
        navAdvance(R, target, persist: false)
        linkEnter(R, target, noExit: true)          // sans effet tant que la session n'a pas démarré
        if let from, from != target { R.cxBack[R.seq] = CxBack(id: from, t: now()) }
        R.flowEnded = false
        ensureStarted(R)
        persist(R)
        return true
    }

    /// `cxResume(f, backId)` : la MÊME visite interrompue revient au bout (A333).
    @discardableResult
    public func resumeFromComplication(_ R: RuntimeSession, backId: String) -> (before: [Int], after: [Int])? {
        guard R.fiche.blocks.contains(where: { $0.id == backId }) else { return nil }
        R.flowEnded = false
        let bout = R.nav.count - 1
        var k = -1
        if bout >= 0, R.cxBack[R.navSeq[bout]] != nil {
            var i = bout - 1
            while i >= 0 { if R.nav[i] == backId { k = i; break }; i -= 1 }
        }
        if k >= 0 { return navRestore(R, k) }
        navAdvance(R, backId)
        return nil
    }

    // MARK: Minuteurs

    /// Le bouton principal : Démarrer / Pause / Relancer (`toggleTimer`).
    public func toggleTimer(_ R: RuntimeSession, _ id: String, persist p: Bool = true) {
        guard var t = R.timers[id] else { return }
        let n = now()
        t.ack = false
        if t.running {
            let w = t.elapsedMs + (n - t.lastStart)
            t.elapsedMs = t.type == .interval ? min(t.period, w) : w
            t.running = false; t.stoppedAt = n; t.stopClosed = false
        } else {
            if t.type == .interval && t.elapsedMs >= (t.period == 0 ? 1 : t.period) { t.elapsedMs = 0 }
            t.lastStart = n; t.running = true; t.stoppedAt = 0; t.stopClosed = false
        }
        R.timers[id] = t
        if p { ensureStarted(R); persist(R) }
    }
    /// `tmRestart` : repart de zéro, en marche.
    public func restartTimer(_ R: RuntimeSession, _ id: String) {
        guard var t = R.timers[id] else { return }
        t.elapsedMs = 0; t.lastStart = now(); t.running = true; t.ack = false; t.stoppedAt = 0; t.stopClosed = false
        R.timers[id] = t
    }
    /// Remise à zéro (maintenue 800 ms ; réservée au conducteur en partage).
    public func resetTimer(_ R: RuntimeSession, _ id: String) {
        guard var t = R.timers[id] else { return }
        t.running = false; t.elapsedMs = 0; t.cycles = 0; t.lastStart = 0; t.ack = false; t.stoppedAt = 0; t.stopClosed = false
        R.timers[id] = t
        persist(R)
    }
    /// « ✓ Vu » : l'alarme se tait, le minuteur RESTE échu.
    public func acknowledge(_ R: RuntimeSession, _ id: String) {
        R.timers[id]?.ack = true
        persist(R)
    }
    /// « ＋ Minuteur » ad hoc (1·2·3·5 min) : démarre aussitôt.
    @discardableResult
    public func addAdhocTimer(_ R: RuntimeSession, seconds: Int) -> String {
        let sec = max(30, min(3600, seconds))
        let id = Guard.uid("t")
        R.timers[id] = TimerState(id: id, label: "\(Int(JS.round(Double(sec) / 60))) min", short: "", type: .interval, seconds: sec,
                                  autoloop: false, onDue: "", elapsedMs: 0, cycles: 0, running: true, lastStart: now(),
                                  stoppedAt: 0, stopClosed: false, ack: false, adhoc: true)
        R.timerOrder.append(id)
        ensureStarted(R)
        persist(R, immediate: true)
        return id
    }
    public func renameAdhocTimer(_ R: RuntimeSession, _ id: String, _ label: String) {
        guard R.timers[id]?.adhoc == true else { return }
        R.timers[id]?.label = JS.prefix(label, 40)
        persist(R, immediate: true)
    }
    public func removeAdhocTimer(_ R: RuntimeSession, _ id: String) {
        guard R.timers[id]?.adhoc == true else { return }
        R.timers[id] = nil; R.timerOrder.removeAll { $0 == id }
        persist(R, immediate: true)
    }

    /// `tickAll` — à appeler toutes les 300 ms. Calcule depuis l'horloge murale (jamais par cumul
    /// de battements). Rend les minuteurs qui viennent de sonner.
    @discardableResult
    public func tick() -> [(RuntimeSession, TimerState)] {
        let n = now()
        var fired: [(RuntimeSession, TimerState)] = []
        for R in live.values {
            var any = false
            for id in R.timerOrder {
                guard var t = R.timers[id], t.type == .interval, t.running else { continue }
                let per = t.period == 0 ? 1 : t.period
                let within = t.elapsedMs + (n - t.lastStart)
                guard within >= per else { continue }
                let comp = (within / per).rounded(.down)
                t.cycles += comp
                let left = within - comp * per
                if t.autoloop { t.elapsedMs = 0; t.lastStart = n - left }
                else { t.running = false; t.elapsedMs = per; t.lastStart = 0 }
                R.timers[id] = t
                fired.append((R, t)); any = true
                delegate?.engine(self, timerFired: t, in: R)
            }
            if any { persist(R, immediate: true) }
        }
        flushDue()
        return fired
    }

    // MARK: Compteurs

    /// `cnInc` : le « + » cœur (relance le minuteur lié du compteur).
    func counterInc(_ R: RuntimeSession, _ id: String, _ step: Double) {
        R.counters[id] = (R.counters[id] ?? 0) + step
        if let cc = R.fiche.counters.first(where: { $0.id == id }), !cc.timerId.isEmpty, R.timers[cc.timerId] != nil {
            restartTimer(R, cc.timerId)
        }
    }
    /// `cnBump` : « + » avec son repère horodaté. Rend l'index de l'évènement.
    @discardableResult
    func counterBump(_ R: RuntimeSession, _ id: String, _ step: Double) -> Int {
        counterInc(R, id, step)
        R.events.append(SessionEvent(id: Guard.uid("e"), t: vfNow(), label: "",
                                     ref: ["type": "counter", "id": .string(id), "v": .number(R.counters[id] ?? 0)]))
        return R.events.count - 1
    }
    /// « + » d'un compteur.
    public func counterPlus(_ R: RuntimeSession, _ id: String) {
        let step = Double(R.fiche.counters.first { $0.id == id }?.step ?? 1)
        delegate?.engineTick(self)
        counterBump(R, id, step)
        ensureStarted(R)
        persist(R)
    }
    /// « − » : une correction n'est pas un geste de soin — aucun repère.
    public func counterMinus(_ R: RuntimeSession, _ id: String) {
        let step = Double(R.fiche.counters.first { $0.id == id }?.step ?? 1)
        R.counters[id] = max(0, (R.counters[id] ?? 0) - step)
        ensureStarted(R)
        persist(R)
    }
    /// Remise à la valeur de départ (maintenue 800 ms).
    public func counterReset(_ R: RuntimeSession, _ id: String) {
        R.counters[id] = Double(R.fiche.counters.first { $0.id == id }?.start ?? 0)
        persist(R)
    }
    /// « ＋ Compteur » ad hoc : naît À 1 (l'évènement vient d'avoir lieu), jamais de minuteur lié.
    @discardableResult
    public func addAdhocCounter(_ R: RuntimeSession) -> String? {
        guard R.adhocCounters.count < Self.maxAdhocCounters else { return nil }
        let id = Guard.uid("c")
        R.adhocCounters.append(AdhocCounter(id: id, label: ""))
        R.counters[id] = 1
        delegate?.engineTick(self)
        // Q11 corrigé : `v` (et non `n`), pour que le repère se lise « Compteur n° 1 ».
        R.events.append(SessionEvent(id: Guard.uid("e"), t: vfNow(), label: "", ref: ["type": "counter", "id": .string(id), "v": 1]))
        ensureStarted(R)
        persist(R, immediate: true)
        return id
    }
    public func renameAdhocCounter(_ R: RuntimeSession, _ id: String, _ label: String) {
        guard let i = R.adhocCounters.firstIndex(where: { $0.id == id }) else { return }
        R.adhocCounters[i].label = JS.prefix(label, 80)
        persist(R, immediate: true)
    }
    public func removeAdhocCounter(_ R: RuntimeSession, _ id: String) {
        R.adhocCounters.removeAll { $0.id == id }
        R.counters[id] = nil
        persist(R, immediate: true)
    }
    /// Libellé d'un compteur (de l'aide ou ad hoc).
    public func counterLabel(_ R: RuntimeSession, _ id: String) -> String {
        if let c = R.fiche.counters.first(where: { $0.id == id }) { return c.label }
        if let i = R.adhocCounters.firstIndex(where: { $0.id == id }) {
            let l = R.adhocCounters[i].label
            return l.isEmpty ? "Compteur \(i + 1)" : l
        }
        return ""
    }

    // MARK: Journal des actions

    /// « Horodater » : l'HEURE est prise au tap. Rend l'id du repère posé.
    @discardableResult
    public func stamp(_ R: RuntimeSession) -> String {
        let ev = SessionEvent(id: Guard.uid("e"), t: vfNow(), label: "")
        R.events.append(ev)
        ensureStarted(R)
        persist(R)
        return ev.id
    }
    /// Nommer un repère : le libellé manuel est SOUVERAIN et remplace la référence.
    public func labelEvent(_ R: RuntimeSession, _ id: String, _ label: String) {
        guard let i = R.events.firstIndex(where: { $0.id == id }) else { return }
        R.events[i].label = JS.prefix(label, 200); R.events[i].ref = nil
        persist(R)
    }
    /// Étiqueter un repère par une référence (puce de suggestion). Un compteur est incrémenté
    /// DANS le même repère (un seul évènement). Q12 corrigé : de son pas, comme le « + ».
    public func tagEvent(_ R: RuntimeSession, _ id: String, ref: JSON) {
        guard let i = R.events.firstIndex(where: { $0.id == id }), var r = SessionSanitize.ref(ref) else { return }
        if r["type"]?.string == "counter", let cid = r["id"]?.string {
            let step = Double(R.fiche.counters.first { $0.id == cid }?.step ?? 1)
            counterInc(R, cid, step)
            r = ["type": "counter", "id": .string(cid), "v": .number(R.counters[cid] ?? 0)]
        }
        R.events[i].ref = r; R.events[i].label = ""
        persist(R)
    }
    /// Annuler / rétablir un repère — JAMAIS supprimé : la ligne reste, barrée.
    public func toggleVoid(_ R: RuntimeSession, _ id: String) {
        guard let i = R.events.firstIndex(where: { $0.id == id }) else { return }
        R.events[i].voidAt = R.events[i].voidAt == nil ? now() : nil
        persist(R)
    }
    /// Corriger l'heure d'un repère (l'heure d'origine est gardée pour toujours).
    public func correctTime(_ R: RuntimeSession, _ id: String, to nt: Double) {
        guard let i = R.events.firstIndex(where: { $0.id == id }) else { return }
        if (R.events[i].t / 1000).rounded(.down) != (nt / 1000).rounded(.down) {
            if R.events[i].origT == nil { R.events[i].origT = R.events[i].t }
            R.events[i].t = nt
            R.events.sort { $0.t < $1.t }
            persist(R)
        }
    }
    /// « revenir » à l'heure d'origine.
    public func revertTime(_ R: RuntimeSession, _ id: String) {
        guard let i = R.events.firstIndex(where: { $0.id == id }), let o = R.events[i].origT else { return }
        R.events[i].t = o; R.events[i].origT = nil
        R.events.sort { $0.t < $1.t }
        persist(R)
    }

    // MARK: Vérification (Do-Verify)

    /// « Constaté ✓ » : l'étape est cochée ET tracée comme constatée.
    public func verifyOK(_ R: RuntimeSession, key k: String, actor: String? = nil) {
        R.setChecked(k, true)
        R.verified[k] = VTrace(a: actor, t: vfNow()); R.vgaps[k] = nil
        ensureStarted(R)
        persist(R)
    }
    /// « △ Écart » : trace l'écart, ne décoche JAMAIS.
    public func verifyGap(_ R: RuntimeSession, key k: String, actor: String? = nil) {
        R.vgaps[k] = VTrace(a: actor, t: vfNow()); R.verified[k] = nil
        if R.started { persist(R) }
    }

    // MARK: Revue (A396/A398)

    /// État d'une revue : k/n cochées, faite.
    public func reviewState(_ R: RuntimeSession, _ rb: Block) -> (k: Int, n: Int, done: Bool) {
        let n = Graph.cleanSteps(R.fiche, rb).count
        var k = 0
        for i in 0..<n where R.isChecked("r:\(rb.id):\(i)") { k += 1 }
        return (k, n, n > 0 && k == n)
    }
    /// « Nouvelle revue » : efface les coches de la revue.
    public func newReview(_ R: RuntimeSession, _ rid: String) {
        for k in R.checkedOrder where k.hasPrefix("r:\(rid):") { R.removeChecked(k) }
        if R.started { persist(R) }
    }

    // MARK: Exercice

    /// Arme une session d'EXERCICE (non démarrée) sur l'aide.
    public func armExercise(_ f: Fiche) -> RuntimeSession {
        let R = RuntimeSession.build(f, session: nil)
        R.exercise = true
        return R
    }

    // MARK: Lectures utiles à l'interface

    /// Étapes vitales non cochées des blocs VISITÉS (`endSessOpenTxt`) et minuteurs en cours.
    public func openAtEnd(_ R: RuntimeSession) -> (crit: Int, where: String, running: Int) {
        var crit = 0, ou = ""
        var seen = Set<String>()
        let by = Graph.byId(R.fiche.blocks)
        for (i, id) in R.nav.enumerated() {
            let seq = i < R.navSeq.count && R.navSeq[i] != 0 ? R.navSeq[i] : i + 1
            guard let b = by[id], b.kind != .decision, !seen.contains("\(seq):\(id)") else { continue }
            seen.insert("\(seq):\(id)")
            for (j, s) in Graph.stepsOf(R.fiche, b).enumerated() where Steps.isCrit(s) && !R.isChecked("\(seq):\(id):\(j)") {
                crit += 1
                if ou.isEmpty { ou = JS.trim(b.title) }
            }
        }
        let run = R.timers.values.filter(\.running).count
        return (crit, ou, run)
    }
}
