import Foundation

// ÉTAT VIVANT D'UNE SESSION — port de `makeRuntime`/`buildRuntime`/`snapshotSession`.
//
// Type RÉFÉRENCE (classe) : dans la PWA, `state.checked`, `state.nav`… sont des ALIAS des
// collections du Runtime ; cocher ou naviguer met donc à jour la session vive sans recopie.
// L'instantané JSON rend exactement les clés du web (`checked`, `nav`, `navSeq`, `timers`…),
// pour rester compatible avec l'export, la synchro de l'historique et le partage.

/// Un minuteur vivant (`TimerRT`).
public struct TimerState: Equatable, Sendable {
    public var id: String
    public var label: String
    public var short: String
    public var type: TimerKind
    public var seconds: Int
    public var autoloop: Bool
    /// L'ACTION annoncée à l'échéance (K7). ⚠ La PWA ne la recopie pas dans son minuteur vivant
    /// (question Q9 de la spécification : l'alarme web n'affiche jamais que le nom) ; le natif la
    /// garde pour que l'alarme dise QUOI FAIRE, comme la doctrine K7 le demande.
    public var onDue: String
    /// Temps accumulé HORS segment en cours.
    public var elapsedMs: Double
    public var cycles: Double
    public var running: Bool
    public var lastStart: Double
    public var stoppedAt: Double
    /// Restauré « en pause » parce que l'application était fermée pendant qu'il tournait.
    public var stopClosed: Bool
    /// Alarme acquittée (« ✓ Vu »), locale.
    public var ack: Bool
    public var adhoc: Bool

    public var period: Double { Double(seconds) * 1000 }
    /// Temps écoulé à l'instant `now`.
    public func within(_ now: Double) -> Double { elapsedMs + (running ? now - lastStart : 0) }
    /// `timerStarted`
    public var started: Bool { elapsedMs > 0 || cycles > 0 }
    /// `timerDue` : minuteur à échéance, sans reprise seule, arrêté au bout de sa période.
    public var isDue: Bool { type == .interval && !autoloop && !running && period > 0 && elapsedMs >= period }
    /// `tmIsDue` (quai) : sans le test d'autoloop.
    public var isDueDock: Bool { type == .interval && !running && period > 0 && elapsedMs >= period }
    /// `timerPaused`
    public var isPaused: Bool { !running && started && !isDue }
    public var name: String { Fmt.timerName(label: label, type: type) }
    /// Valeur affichée : restant (minuteur) ou écoulé (chronomètre).
    public func display(_ now: Double) -> String {
        type == .interval ? Fmt.ms(max(0, period - within(now))) : Fmt.ms(within(now))
    }
    /// Restant en ms (minuteur), +∞ sinon.
    public func remaining(_ now: Double) -> Double { type == .interval ? max(0, period - within(now)) : .infinity }
    /// Largeur de la barre de progression : pourcentage RESTANT.
    public func barPercent(_ now: Double) -> Double {
        period > 0 ? max(0, 100 - min(100, within(now) / period * 100)) : 100
    }
    /// `timerBtnLabel`
    public var buttonLabel: String { running ? "Pause" : (started ? "Relancer" : "Démarrer") }
    /// `timerStateLabel`
    public var stateLabel: String { isDue ? "■ " + name + " — à réévaluer" : (isPaused ? name + " — en pause" : name) }
}

public struct VTrace: Equatable, Sendable {
    public var a: String?
    public var t: Double
    public init(a: String?, t: Double) { self.a = a; self.t = t }
    var json: JSON { ["a": .str(a), "t": .number(t)] }
    /// `vfNorm` : objet → {a, t} ; nombre nu → {a:nil, t} ; sinon rien.
    static func norm(_ v: JSON?) -> VTrace? {
        guard let v else { return nil }
        if case .number(let n) = v { return VTrace(a: nil, t: n) }
        guard v.object != nil else { return nil }
        let t = JS.number(v["t"])
        return VTrace(a: v["a"]?.string, t: t.isNaN ? 0 : t)
    }
}

/// Un repère du journal des actions.
public struct SessionEvent: Equatable, Identifiable, Sendable {
    public var id: String
    public var t: Double
    /// Renommage MANUEL, souverain et STRICTEMENT LOCAL (règle 15).
    public var label: String
    /// Référence résolue en mot par `tagLabel` (c'est elle qui voyage).
    public var ref: JSON?
    public var voidAt: Double?
    public var origT: Double?
    public var a: String?
    public var annex: Bool
    /// Clé de la coche qui l'a produit (locale).
    public var ck: String?
    public var extra: [String: JSON]

    public init(id: String, t: Double, label: String = "", ref: JSON? = nil) {
        self.id = id; self.t = t; self.label = label; self.ref = ref
        voidAt = nil; origT = nil; a = nil; annex = false; ck = nil; extra = [:]
    }
    init(json e: JSON) {
        let o = e.object ?? [:]
        id = o["id"]?.string ?? Guard.uid("e")
        t = JS.number(o["t"]).isFinite ? JS.number(o["t"]) : 0
        label = o["label"]?.string ?? ""
        ref = o["ref"]
        voidAt = (o["voidAt"]?.number).flatMap { $0 == 0 ? nil : $0 }
        origT = o["origT"]?.number
        a = o["a"]?.string
        annex = o["annex"]?.truthy ?? false
        ck = o["ck"]?.string
        var ex = o
        for k in ["id", "t", "label", "ref", "voidAt", "origT", "a", "annex", "ck"] { ex[k] = nil }
        extra = ex
    }
    public var json: JSON {
        var o = extra
        o["id"] = .string(id); o["t"] = .number(t); o["label"] = .string(label)
        if let ref { o["ref"] = ref }
        if let voidAt { o["voidAt"] = .number(voidAt) }
        if let origT { o["origT"] = .number(origT) }
        if let a { o["a"] = .string(a) }
        if annex { o["annex"] = true }
        if let ck { o["ck"] = .string(ck) }
        return .object(o)
    }
    public var isVoid: Bool { voidAt != nil }
    public var refType: String? { ref?["type"]?.string }
    public var refId: String? { ref?["id"]?.string }
}

public struct AdhocCounter: Equatable, Sendable {
    public var id: String
    public var label: String
}

/// Grâce de 10 s d'une coche liée à un minuteur (A377).
struct LinkGrace {
    var real: Double
    var tid: String
    var prev: TimerState?
    var prevArm: LinkArm?
}

/// Le Runtime d'une aide.
public final class RuntimeSession {
    public var fiche: Fiche
    public var ficheId: String
    public var sessionId: String?
    public var name: String = ""
    public var started = false
    public var startedAt: Double = 0
    public var aidRev: Double = 0
    public var exercise = false
    /// Essai d'un brouillon (K5) : rien n'est écrit, rien n'est émis.
    public var essai = false
    /// Session suivie par un invité (partage) : n'écrit rien localement.
    public var guest = false
    /// Coches : true = cochée (la PWA stocke `false` au décochage, Q1). Ordre d'insertion gardé.
    public private(set) var checked: [String: Bool] = [:]
    public private(set) var checkedOrder: [String] = []
    public var verified: [String: VTrace] = [:]
    public var vgaps: [String: VTrace] = [:]
    public var cxBack: [Int: CxBack] = [:]
    public var nav: [String] = []
    public var navSeq: [Int] = []
    public var seq: Int = 0
    public var counters: [String: Double] = [:]
    public var timers: [String: TimerState] = [:]
    /// Ordre d'affichage des minuteurs (ceux de l'aide, puis les ad hoc).
    public var timerOrder: [String] = []
    public var adhocCounters: [AdhocCounter] = []
    public var events: [SessionEvent] = []
    public var linkArm: [String: LinkArm] = [:]
    var linkGrace: [String: LinkGrace] = [:]
    /// Heure du dernier décochage d'une étape liée (animation).
    public var linkBack: [String: Double] = [:]
    public var lastActAt: Double?
    public var navBad = false
    /// « Algorithme terminé » — partagé, jamais persisté (Q22).
    public var flowEnded = false

    public init(fiche: Fiche) {
        self.fiche = fiche
        self.ficheId = fiche.id
    }

    public func isChecked(_ k: String) -> Bool { checked[k] == true }
    public func setChecked(_ k: String, _ on: Bool) {
        if checked[k] == nil { checkedOrder.append(k) }
        checked[k] = on
    }
    public func removeChecked(_ k: String) {
        checked[k] = nil
        checkedOrder.removeAll { $0 == k }
    }
    /// Clés cochées, dans l'ordre où elles l'ont été la première fois.
    public var checkedKeys: [String] { checkedOrder.filter { checked[$0] == true } }

    /// Minuteurs dans l'ordre d'affichage.
    public var orderedTimers: [TimerState] { timerOrder.compactMap { timers[$0] } }
}

// MARK: - Construction et instantané

extension RuntimeSession {
    /// `buildRuntime(f, session)` — la session vient de `SessionSanitize.session` (déjà bornée).
    public static func build(_ f: Fiche, session: JSON?) -> RuntimeSession {
        let R = RuntimeSession(fiche: f)
        guard let s = session, s.object != nil else {
            R.nav = [f.start ?? f.blocks.first?.id ?? ""]
            R.navSeq = [1]; R.seq = 1
            for c in f.counters { R.counters[c.id] = Double(c.start) }
            for t in f.timers { R.addTimer(from: t, sv: nil, session: nil) }
            return R
        }
        R.sessionId = s["id"]?.string
        R.name = s["name"]?.string ?? ""
        R.started = true
        R.startedAt = s["startedAt"]?.number ?? 0
        // Coches (ordre des clés : celui du document relu), avec la remontée des clés de revue (A398).
        var ck: [(String, Bool)] = []
        if let o = s["checked"]?.object { for k in o.keys.sorted(by: RuntimeSession.keyOrder) { ck.append((k, o[k]!.truthy)) } }
        let reviews = Set(f.blocks.filter { $0.kind == .review }.map(\.id))
        for (k, v) in ck {
            let p = k.split(separator: ":", omittingEmptySubsequences: false)
            if p.count == 3, p[0] != "r", reviews.contains(String(p[1])) {
                if v { R.setChecked("r:\(p[1]):\(p[2])", true) }
                continue
            }
            R.setChecked(k, v)
        }
        for (k, v) in s["verified"]?.object ?? [:] { if let t = VTrace.norm(v) { R.verified[k] = t } }
        for (k, v) in s["vgaps"]?.object ?? [:] { if let t = VTrace.norm(v) { R.vgaps[k] = t } }
        for (k, v) in s["cxBack"]?.object ?? [:] {
            guard let n = Int(k) else { continue }
            if let str = v.string { R.cxBack[n] = CxBack(id: str, t: 0) }
            else if let id = v["id"]?.string { R.cxBack[n] = CxBack(id: id, t: v["t"]?.number ?? 0) }
        }
        R.exercise = s["exercise"]?.truthy ?? false
        let nav = (s["nav"]?.array ?? []).compactMap(\.string)
        R.nav = nav.isEmpty ? [f.start ?? f.blocks.first?.id ?? ""] : nav
        let seqs = (s["navSeq"]?.array ?? []).map { Int(JS.number($0).isFinite ? JS.number($0) : 1) }
        let shared = s["shared"]?.truthy ?? false
        if shared && !seqs.isEmpty && seqs.count != R.nav.count { R.navSeq = seqs; R.navBad = true }
        else { R.navSeq = seqs.count == R.nav.count ? seqs : Array(1...max(1, R.nav.count)).prefix(R.nav.count).map { $0 } }
        R.seq = R.navSeq.max() ?? 0
        let sc = s["counters"]?.object ?? [:]
        for c in f.counters { R.counters[c.id] = sc[c.id].map { JS.number($0) } ?? Double(c.start) }
        R.adhocCounters = (s["extraCounters"]?.array ?? []).prefix(20).map { c in
            AdhocCounter(id: Guard.safeId(c["id"], "c"), label: Guard.sstr(c["label"], 80))
        }
        for c in R.adhocCounters { R.counters[c.id] = sc[c.id].map { JS.number($0) } ?? 0 }
        let st = s["timers"]?.object ?? [:]
        for t in f.timers { R.addTimer(from: t, sv: st[t.id], session: s) }
        for x in s["extraTimers"]?.array ?? [] {
            guard let xid = x["id"]?.string, !xid.isEmpty, R.timers[xid] == nil else { continue }
            let secR = JS.round(JS.number(x["seconds"]))
            let def = TimerDef(id: Guard.safeId(.string(xid), "t"), label: Guard.sstr(x["label"], 120), type: .interval,
                               seconds: Int(JS.clamp((secR.isNaN || secR == 0) ? 300 : secR, 0, 86400)),
                               autoloop: x["autoloop"]?.truthy ?? false)
            R.addTimer(from: def, sv: st[xid], session: s, adhoc: true)
        }
        R.events = (s["events"]?.array ?? []).map { SessionEvent(json: $0) }
        for (k, v) in SessionSanitize.linkArm(s["linkArm"]).object ?? [:] {
            R.linkArm[k] = LinkArm(b: v["b"]?.string ?? "", x: v["x"]?.number ?? 0)
        }
        // `aidRev` n'est PAS relu ici (comme la PWA) : c'est la reprise (`resume`) qui le rétablit.
        return R
    }

    /// Ordre des clés d'un objet JS : entiers croissants d'abord, puis ordre d'insertion (ici :
    /// lexicographique, faute de mieux — un document relu a perdu son ordre d'insertion).
    static func keyOrder(_ a: String, _ b: String) -> Bool { a < b }

    func addTimer(from t: TimerDef, sv: JSON?, session: JSON?, adhoc: Bool = false) {
        var stoppedAt = 0.0, stopClosed = false
        if let sv {
            let sav = session?["savedAt"]?.number ?? 0
            if sv["running"]?.truthy == true { stoppedAt = sav; stopClosed = true }
            else { let so = sv["stoppedAt"]?.number ?? 0; stoppedAt = so != 0 ? so : sav }
        }
        timers[t.id] = TimerState(id: t.id, label: t.label, short: t.short ?? "", type: t.type, seconds: t.seconds,
                                  autoloop: t.autoloop, onDue: t.onDue,
                                  elapsedMs: sv?["elapsedMs"]?.number ?? 0, cycles: sv?["cycles"]?.number ?? 0,
                                  running: false, lastStart: 0, stoppedAt: stoppedAt, stopClosed: stopClosed, ack: false, adhoc: adhoc)
        if !timerOrder.contains(t.id) { timerOrder.append(t.id) }
    }

    /// `stepTextsFor(R)` : texte des étapes touchées, archivé avec la session (jamais synchronisé).
    func stepTexts() -> JSON {
        var keys: [String] = checkedKeys
        for k in verified.keys.sorted() where !keys.contains(k) { keys.append(k) }
        for k in vgaps.keys.sorted() where !keys.contains(k) { keys.append(k) }
        var out: [String: JSON] = [:]
        for k in keys { if let st = Report.stepText(fiche, key: k, snapshot: nil) { out[k] = ["b": .string(st.block), "s": .string(st.step)] } }
        return .object(out)
    }

    /// `snapshotSession(R, live)`.
    public func snapshot(live: Bool, now: Double) -> JSON {
        var tsnap: [String: JSON] = [:]
        for t in timers.values {
            let w = t.within(now)
            tsnap[t.id] = ["elapsedMs": .number(t.type == .interval ? min(t.period, w) : w), "cycles": .number(t.cycles),
                           "running": .bool(t.running), "stoppedAt": .number(t.stoppedAt)]
        }
        var ck: [String: JSON] = [:]
        for k in checkedOrder { if let v = checked[k] { ck[k] = .bool(v) } }
        var cx: [String: JSON] = [:]
        for (k, v) in cxBack { cx[String(k)] = ["id": .string(v.id), "t": .number(v.t)] }
        var la: [String: JSON] = [:]
        for (k, v) in linkArm.prefix(200) { la[k] = ["b": .string(v.b), "x": .number(v.x)] }
        var o: [String: JSON] = [:]
        o["id"] = .str(sessionId); o["ficheId"] = .string(fiche.id); o["ficheTitle"] = .string(fiche.title)
        o["aidRev"] = .number(aidRev); o["name"] = .string(name); o["savedAt"] = .number(now)
        o["startedAt"] = .number(startedAt != 0 ? startedAt : now); o["live"] = .bool(live)
        o["checked"] = .object(ck)
        o["verified"] = .object(verified.mapValues(\.json)); o["vgaps"] = .object(vgaps.mapValues(\.json))
        o["stepTexts"] = stepTexts(); o["cxBack"] = .object(cx); o["exercise"] = .bool(exercise)
        o["nav"] = .array(nav.map { .string($0) }); o["navSeq"] = .array(navSeq.map { .number(Double($0)) })
        o["counters"] = .object(counters.mapValues { .number($0) }); o["timers"] = .object(tsnap)
        o["extraTimers"] = .array(orderedTimers.filter(\.adhoc).map {
            ["id": .string($0.id), "label": .string($0.label), "seconds": .number(Double($0.seconds)), "autoloop": .bool($0.autoloop)]
        })
        o["extraCounters"] = .array(adhocCounters.map { ["id": .string($0.id), "label": .string($0.label)] })
        o["linkArm"] = .object(la)
        o["events"] = .array(events.map(\.json))
        return .object(o)
    }
}
