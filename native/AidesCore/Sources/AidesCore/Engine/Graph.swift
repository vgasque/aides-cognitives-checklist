import Foundation

// GRAPHE DES BLOCS ET COMPLÉTUDE DES VISITES — port de blocksById, blkSucc, blkReach, blkInLoop,
// loopExitStops, latestPass, passInfo, navNextIdx, visitNeed, instComplete, momentOf, jalonProg.
// Fonctions PURES : l'état de session (compteurs, minuteurs, coches) est passé explicitement,
// là où la PWA lisait les globales `Runtime` et `state` (la dépendance devient visible).

public enum Graph {
    /// `blocksById` : index {id → bloc}, PREMIER gagnant (un id dupliqué garde sa 1ʳᵉ définition).
    public static func byId(_ blocks: [Block]) -> [String: Block] {
        var m: [String: Block] = [:]
        for b in blocks where !b.id.isEmpty && m[b.id] == nil { m[b.id] = b }
        return m
    }
    /// `blkSucc` : suites d'un bloc d'étapes, cibles d'une décision.
    public static func succ(_ b: Block?) -> [String] {
        guard let b else { return [] }
        if b.kind == .decision { return b.options.compactMap { ($0.target?.isEmpty == false) ? $0.target : nil } }
        if let n = b.next, !n.isEmpty { return [n] }
        return []
    }
    /// `blkReach` : ensemble atteignable depuis `from` (inclus s'il existe).
    public static func reach(_ f: Fiche, from: String?) -> Set<String> {
        let by = byId(f.blocks)
        var seen = Set<String>()
        var q: [String] = from.map { [$0] } ?? []
        while let id = q.popLast() {
            if id.isEmpty || seen.contains(id) || by[id] == nil { continue }
            seen.insert(id)
            q.append(contentsOf: succ(by[id]))
        }
        return seen
    }
    /// `blkInLoop` : le bloc est-il sur un cycle ?
    public static func inLoop(_ f: Fiche, _ id: String) -> Bool {
        succ(byId(f.blocks)[id]).contains { reach(f, from: $0).contains(id) }
    }
    /// `loopExitStops` (A377) : minuteurs armés par un bloc de boucle que l'on QUITTE en allant à `toId`.
    public static func loopExitStops(_ f: Fiche, arm: [String: LinkArm], toId: String) -> [String] {
        let vus = reach(f, from: toId)
        return arm.keys.sorted().filter { tid in
            guard let a = arm[tid] else { return false }
            return !a.b.isEmpty && a.x == 0 && !vus.contains(a.b) && inLoop(f, a.b)
        }
    }
    /// `latestPass` : dernière visite d'un bloc.
    public static func latestPass(nav: [String], navSeq: [Int], _ id: String) -> (idx: Int, seq: Int, pass: Int, total: Int)? {
        var idx = -1, total = 0
        for (i, x) in nav.enumerated() where x == id { total += 1; idx = i }
        if idx < 0 { return nil }
        let s = idx < navSeq.count ? navSeq[idx] : 0
        return (idx, s == 0 ? 1 : s, total, total)
    }
    /// `passInfo` : rang du passage `idx` parmi les visites du même bloc.
    public static func passInfo(nav: [String], _ idx: Int) -> (pass: Int, total: Int) {
        guard idx >= 0, idx < nav.count else {
            // nav[idx] vaut undefined en JS : aucune entrée ne lui est égale.
            return (0, 0)
        }
        let id = nav[idx]
        var pass = 0, total = 0
        for (i, x) in nav.enumerated() where x == id { total += 1; if i <= idx { pass += 1 } }
        return (pass, total)
    }
    /// `navNextIdx` : entrée suivante qui N'EST PAS une visite de complication.
    public static func navNextIdx(nav: [String], navSeq: [Int], _ idx: Int, cxBack: [Int: CxBack]) -> Int {
        var j = idx + 1
        while j < nav.count {
            let s = j < navSeq.count ? navSeq[j] : -1
            if cxBack[s] == nil { return j }
            j += 1
        }
        return -1
    }

    /// `clean(stepsOf(b))` : chaînes d'étape non vides (après trim) — l'INDEX des clés de cochage.
    public static func cleanSteps(_ f: Fiche, _ b: Block) -> [String] {
        Pool.blockItems(f, b).map { JS.trim($0.legacyString) }.filter { !$0.isEmpty }
    }
    /// `stepsOf(b)` (sans `clean`) — lu par tagLabel et stepTextFromKey.
    public static func stepsOf(_ f: Fiche, _ b: Block) -> [String] {
        Pool.blockItems(f, b).map(\.legacyString)
    }
}

/// Ancre d'une visite de complication (`cxBack`).
public struct CxBack: Equatable, Sendable {
    public var id: String
    public var t: Double
    public init(id: String, t: Double) { self.id = id; self.t = t }
}

/// Armement d'un minuteur par une coche ou un bloc (A377).
public struct LinkArm: Equatable, Sendable {
    /// Bloc qui l'a armé ('' = une coche).
    public var b: String
    /// Heure de l'arrêt de sortie de boucle (0 = armé).
    public var x: Double
    /// Clé de la coche qui l'a armé (locale, jamais persistée).
    public var ck: String?
    public init(b: String, x: Double, ck: String? = nil) { self.b = b; self.x = x; self.ck = ck }
}

// MARK: - Moments d'une étape (A382)

public struct Moment: Equatable, Sendable {
    public enum St: String, Sendable { case wait, gone, due, need, met }
    public enum Why: String, Sendable { case from, due }
    public var st: St
    public var why: Why?
    /// Retient « Continuer ».
    public var req: Bool
    public init(_ st: St, why: Why? = nil, req: Bool = false) { self.st = st; self.why = why; self.req = req }
}

public enum Moments {
    /// État d'un minuteur vu par les moments : '' (au repos / jamais lancé), 'run', 'due'.
    public enum TimerSt: String, Sendable { case idle = "", run, due }

    /// `momentOf(it, cn, tm, before, tid)` — PURE.
    public static func momentOf(_ it: Item?, counter: (String) -> Double, timer: (String) -> TimerSt,
                                before: Bool, tid: String) -> Moment? {
        guard let it, it.from != nil || it.repeat != nil else { return nil }
        if let fr = it.from, counter(fr.counter) < Double(fr.n) { return Moment(.wait, why: .from) }
        if it.repeat == .once && before { return Moment(.gone) }
        if it.repeat == .due && !tid.isEmpty {
            let s = timer(tid)
            if s == .run { return Moment(.wait, why: .due) }
            if s == .due { return Moment(.due, req: true) }
        }
        if it.repeat == .need { return Moment(.need) }
        return it.from != nil ? Moment(.met, req: true) : nil
    }
    /// `stepReq(mo, on)`.
    public static func required(_ mo: Moment?, on: Bool) -> Bool { on || mo == nil || mo!.req }
    /// `momTid(f, it)` : le minuteur qui rythme l'étape (celui qu'elle lance, ou celui de son compteur).
    public static func timerId(_ f: Fiche, _ it: Item?) -> String {
        guard let it else { return "" }
        if let s = it.starts, !s.isEmpty { return s }
        if let c = it.counts, let cd = f.counters.first(where: { $0.id == c }) { return cd.timerId }
        return ""
    }
}

// MARK: - Jalons de boucle

public enum Jalons {
    /// `jalonProg(j, pass, cnt)`.
    public static func progress(_ j: Milestone, pass: Int, count: Double) -> (cur: Double, goal: Int, active: Bool) {
        let goal = j.n == 0 ? 1 : j.n
        let cur = max(0, j.at == .count ? count : Double(pass))
        return (cur, goal, cur >= Double(goal))
    }
    /// `jalonCondLbl(f, j)` : la condition en toutes lettres.
    public static func conditionLabel(_ f: Fiche, _ j: Milestone) -> String {
        if j.at == .count {
            let c = f.counters.first { $0.id == j.counter }
            let l = (c?.label.isEmpty == false) ? c!.label : "compteur"
            return l + " ≥ \(j.n)"
        }
        return "à partir du " + (j.n == 1 ? "1ᵉʳ" : "\(j.n)ᵉ") + " passage"
    }
}
