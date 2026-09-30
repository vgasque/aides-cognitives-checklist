import Foundation
import AidesCore

// ADAPTATEURS DU MODE CRISE vers les fonctions PURES du cœur (vérifiées contre la PWA) :
// `Parcours` (flowPlan, cxAll, noms courts, posBandModel, stepQualTxt, blkTimerTxt, cycleHint,
// minimapData, offPathSet), `Live` (tmLiveOrder, monPick, monBandData, wtTimerModel, wtCountModel,
// endSessOpenTxt, tagAll, tagSuggest, tagRank), `Posology` (parts, split), `Txt` (tkParseTime).
// Ils convertissent l'état du MOTEUR (`TimerState`, `RuntimeSession`) vers les types d'entrée de ces
// fonctions. Seules restent écrites ICI les règles d'AFFICHAGE propres à l'interface (`ovPresList`,
// `ovFoldRemap`, `ovDropOpens`, `momTag`, `onceFaite`) — à remonter dans le cœur au besoin.

/// Nombre affiché comme `String(n)` en JS (compteurs).
func crNum(_ v: Double) -> String { JS.numStr(v.isNaN ? 0 : v) }

// MARK: - flowPlan (numérotation commune « le tronc d'abord »)

struct CrPlanItem: Hashable {
    enum Kind: Hashable { case block, bropen, brclose, link, end }
    var k: Kind
    /// Bloc (`block`) ou cible (`link`).
    var id: String = ""
    var depth: Int = 0
    var dec: String = ""
    var oi: Int = 0
    var label: String = ""
    var tgt: String? = nil
    var from: String? = nil
    var back = false
}

struct CrPlan {
    var items: [CrPlanItem] = []
    var order: [String] = []
    var index: [String: Int] = [:]
    /// Numéro commun d'un bloc (`order.indexOf(id) + 1`), nil hors du tronc (cible de complication, revue).
    func number(_ id: String) -> Int? { index[id].map { $0 + 1 } }
}

enum CrisisPure {
    // Le cœur ne cache pas `flowPlan` (la PWA le cache par objet fiche) : on le garde par CONTENU du graphe.
    @MainActor private static var planCache: [String: (blocks: [Block], start: String?, cx: [Excursion], plan: CrPlan)] = [:]

    @MainActor
    static func flowPlan(_ f: Fiche) -> CrPlan {
        if let c = planCache[f.id], c.blocks == f.blocks, c.start == f.start, c.cx == f.excursions { return c.plan }
        let p = Parcours.flowPlan(f)
        var out = CrPlan()
        out.order = p.order
        for (i, id) in p.order.enumerated() where out.index[id] == nil { out.index[id] = i }
        out.items = p.items.map { it -> CrPlanItem in
            switch it {
            case .block(let id, let depth): return CrPlanItem(k: .block, id: id, depth: depth)
            case .branchOpen(let dec, let option, let label, let target, let depth):
                return CrPlanItem(k: .bropen, depth: depth, dec: dec, oi: option, label: label, tgt: target)
            case .branchClose: return CrPlanItem(k: .brclose)
            case .link(let to, let from, let depth, let back): return CrPlanItem(k: .link, id: to, depth: depth, from: from, back: back)
            case .end(let depth): return CrPlanItem(k: .end, depth: depth)
            }
        }
        planCache[f.id] = (f.blocks, f.start, f.excursions, out)
        return out
    }

    /// `hasFlow` : plus d'un bloc, ou une décision.
    static func hasFlow(_ f: Fiche) -> Bool { f.blocks.count > 1 || f.blocks.contains { $0.kind == .decision } }

    // MARK: Complications

    struct Cx: Hashable {
        var label: String
        var target: String
        var short: String
        var isBlock: Bool
    }
    static func cxAll(_ f: Fiche) -> [Cx] {
        Parcours.cxAll(f).map { Cx(label: $0.label, target: $0.target, short: $0.short, isBlock: $0.isBlock) }
    }
    static func cxShort(_ c: Cx) -> String { Parcours.cxShort(label: c.label, short: c.short) }

    // MARK: Noms courts

    /// `tmShort` d'un minuteur VIVANT (nom court de l'auteur, sinon abrégé d'office ; défaut par nature).
    static func tmShort(_ t: TimerState) -> String {
        if !t.short.isEmpty { return t.short }
        let s = Parcours.autoShort(t.label, Parcours.shortTimer)
        return s.isEmpty ? t.name : s
    }
    static func cnShort(_ c: CounterDef) -> String {
        let s = Parcours.cnShort(c)
        return s.isEmpty ? "Compteur" : s
    }

    // MARK: Minuteurs (types du moteur → `Live.TimerRun`)

    static func run(_ t: TimerState) -> Live.TimerRun {
        Live.TimerRun(id: t.id, label: t.label, type: t.type, seconds: t.seconds, autoloop: t.autoloop, onDue: t.onDue,
                      elapsedMs: t.elapsedMs, running: t.running, lastStart: t.lastStart,
                      cycles: Int(t.cycles.isFinite ? t.cycles : 0), ack: t.ack, adhoc: t.adhoc)
    }
    /// `tmLiveOrder(list, now)`.
    static func tmLiveOrder(_ list: [TimerState], now: Double) -> [TimerState] {
        let by = Dictionary(list.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return Live.tmLiveOrder(list.map(run), now: now).compactMap { by[$0.id] }
    }
    /// « Bientôt échu » (`TM_SOON_MS`) : minuteur à échéance en marche, 0 < restant ≤ 20 s.
    static func isSoon(_ t: TimerState, _ now: Double) -> Bool {
        guard t.type == .interval, t.running else { return false }
        let r = t.remaining(now)
        return r > 0 && r <= Live.soonMs
    }
    /// `monPick(timers, now)`.
    static func monPick(_ timers: [TimerState], now: Double) -> TimerState? {
        guard let p = Live.monPick(timers.map(run), now: now) else { return nil }
        return timers.first { $0.id == p.id }
    }

    // MARK: Journal des actions

    /// L'heure corrigée garde la DATE calendaire d'origine (Q13, comportement web).
    static func correctedTime(_ orig: Double, _ hms: (h: Int, m: Int, s: Int)) -> Double {
        let cal = Calendar.current
        let d = Date(timeIntervalSince1970: orig / 1000)
        var c = cal.dateComponents([.year, .month, .day], from: d)
        c.hour = hms.h; c.minute = hms.m; c.second = hms.s
        guard let nd = cal.date(from: c) else { return orig }
        return (nd.timeIntervalSince1970 * 1000).rounded(.down)
    }

    struct TagCand {
        var ref: JSON
        var label: String
        var type: String
    }
    /// Les objets AD HOC de la session VIVE (`rtExtra()`).
    static func extra(_ R: RuntimeSession?) -> Live.Extra? {
        guard let R else { return nil }
        return Live.Extra(timers: R.orderedTimers.filter(\.adhoc).map { (id: $0.id, label: $0.label, interval: $0.type == .interval, adhoc: true) },
                          counters: R.adhocCounters.map { (id: $0.id, label: $0.label, adhoc: true) })
    }
    private static func cand(_ o: Live.TagOption) -> TagCand { TagCand(ref: o.ref, label: o.label, type: o.ref["type"]?.string ?? "") }
    /// `tagAll(f, tags, ex)`.
    static func tagAll(_ f: Fiche, tags: JSON?, R: RuntimeSession?) -> [TagCand] {
        Live.tagAll(f, tags: tags, extra: extra(R)).map(cand)
    }
    /// `tagSuggest(f, tags, bid, n, garantis)` : réordonne, ne filtre jamais.
    static func tagSuggest(_ f: Fiche, tags: JSON?, R: RuntimeSession?, blockId: String?, n: Int, guaranteed: [String]) -> [TagCand] {
        Live.tagSuggest(f, tags: tags, blockId: blockId, n: n, garantis: guaranteed, extra: extra(R)).map(cand)
    }
    /// Pendant la frappe (≥ 2 caractères) : `tagRank`, au plus 4 propositions de score > 0.
    static func tagMatch(_ f: Fiche, tags: JSON?, R: RuntimeSession?, query: String, excludeTypes: Set<String> = []) -> [TagCand] {
        let q = JS.trim(query)
        guard JS.length(q) >= 2 else { return [] }
        let all = Live.tagAll(f, tags: tags, extra: extra(R)).filter { !excludeTypes.contains($0.ref["type"]?.string ?? "") }
        return Live.tagRank(q, all).filter { $0.score > 0 }.prefix(4).map { TagCand(ref: $0.ref, label: $0.label, type: $0.ref["type"]?.string ?? "") }
    }

    // MARK: Repères posologiques

    /// `posoParts` : nom (avant « : », peut être vide), corps.
    static func posoParts(_ s: String) -> (name: String, body: String) {
        let p = Posology.parts(s)
        return (p.name, p.body)
    }
    typealias PosoRow = Parcours.PosBandRow
    /// `posBandModel(f, b, seq, checked, moOf)` (A397/A398) — l'état vient des SEULES coches.
    static func posBandModel(_ f: Fiche, _ b: Block, seq: Int, R: RuntimeSession, e: SessionEngine) -> [PosoRow] {
        Parcours.posBandModel(f, b, seq: String(seq), checked: Set(R.checkedKeys), moOf: { it, i in
            e.stepMoment(R, it, seq: seq, blockId: b.id, index: i).map { Parcours.MomentInfo(st: $0.st.rawValue, req: $0.req) }
        })
    }
    /// `posoSplit` : signalés + rapprochés d'emblée, le reste replié (son nombre annoncé).
    static func posoSplit(_ items: [String], hay: String) -> (head: [Posology.Ranked], rest: [Posology.Ranked]) {
        Posology.split(items, hay)
    }

    // MARK: Réglages de coche en mots

    static func stepQualTxt(_ f: Fiche, _ it: Item, faite: Bool = false) -> String { Parcours.stepQualTxt(f, it, faite: faite) }
    static func blockTimerTxt(_ f: Fiche, _ b: Block) -> String? {
        let s = Parcours.blkTimerTxt(f, b)
        return s.isEmpty ? nil : s
    }
    static func cycleHint(_ f: Fiche) -> TimerDef? { Parcours.cycleHint(f) }
    /// `onceFaite` : « une seule fois » déjà cochée dans cette session.
    static func onceFaite(_ R: RuntimeSession, _ it: Item?, _ bid: String, _ i: Int) -> Bool {
        guard it?.repeat == .once, R.started else { return false }
        let suf = ":\(bid):\(i)"
        return R.checkedKeys.contains { $0.hasSuffix(suf) }
    }

    // MARK: Moments — étiquette (`momTag`)

    enum TagTone { case outline, warn, ok, neutral }
    static func momFromLbl(_ f: Fiche, _ it: Item) -> String {
        guard let fr = it.from else { return "" }
        let c = f.counters.first { $0.id == fr.counter }
        let nm = Parcours.tmLabelParts(c?.label ?? "").name
        return (nm.isEmpty ? "Compteur" : nm) + " ≥ \(fr.n)"
    }
    static func momTag(_ f: Fiche, _ it: Item, _ mo: Moment) -> (tone: TagTone, word: String) {
        switch mo.st {
        case .wait: return mo.why == .from ? (.outline, momFromLbl(f, it)) : (.outline, "À l’échéance")
        case .met: return (.ok, "✓ " + momFromLbl(f, it))
        case .due: return (.warn, "Échu")
        case .gone: return (.ok, "Faite")
        case .need: return (.neutral, "Au besoin")
        }
    }

    // MARK: Témoins des liens (A377) — `Live.wtTimerModel` / `Live.wtCountModel`

    struct Witness {
        var value: String
        var text: String
        var due = false
        var running = false
        /// Fraction RESTANTE de l'anneau (minuteur à échéance) ; nil = icône.
        var ring: Double? = nil
        var glyph = "timer"
    }
    private static func witness(_ w: Live.Witness) -> Witness {
        let value = w.e ?? ((w.va != nil && w.vb != nil) ? w.va! + " → " + w.vb! : (w.v ?? ""))
        let ring: Double? = w.g == "ring" ? max(0, min(1, 1 - (w.off ?? 0) / Live.ringC)) : nil
        return Witness(value: value, text: w.n, due: w.cls == "due", running: w.cls == "run" || w.cls == "up", ring: ring,
                       glyph: w.g == "count" ? "number" : (w.g == "ring" ? "timer" : "stopwatch"))
    }
    /// Témoin d'un minuteur lancé par une coche (`key`) ou par l'entrée du bloc (`key == nil`).
    /// Indice « décocher annule · n s » : la grâce du moteur (`linkGrace`) n'est pas publique — elle
    /// est reconnue ici à l'armement PAR CETTE coche il y a moins de 10 s (même fenêtre, même geste).
    static func wtTimerModel(_ R: RuntimeSession, _ tid: String, key: String?, now: Double) -> Witness? {
        guard let t = R.timers[tid] else { return nil }
        var hint: String? = nil
        if let k = key, t.running {
            let on = R.isChecked(k)
            let armedByMe = R.linkArm[tid]?.ck == k
            let age = now - t.lastStart
            if on && armedByMe && t.elapsedMs == 0 && age < SessionEngine.linkGraceMs {
                hint = "décocher annule · \(Int(((SessionEngine.linkGraceMs - age) / 1000).rounded(.up))) s"
            } else if !on && armedByMe {
                hint = "décochée, le minuteur continue"
            } else if !on {
                hint = "la coche relance" + (t.type == .interval ? " à " + Fmt.ms(t.period) : "")
            }
        }
        let exited = (R.linkArm[tid]?.x ?? 0) != 0
        guard let w = Live.wtTimerModel(run(t), now: now, hint: hint, exited: exited, lat: key == nil ? "à chaque entrée" : nil) else { return nil }
        return witness(w)
    }
    /// Témoin d'une coche qui COMPTE.
    static func wtCountModel(_ R: RuntimeSession, _ cid: String, key: String, now: Double) -> Witness? {
        let c = R.fiche.counters.first { $0.id == cid }
        let evs = R.events.filter { $0.refType == "counter" && $0.refId == cid && !$0.isVoid }
        let mine = evs.last { $0.ck == key }
        let mark = mine.map { Live.CountMark(t: $0.t, hasRef: $0.ref != nil, v: $0.ref?["v"]?.number) }
        let last = evs.last.map { Live.CountMark(t: $0.t, hasRef: $0.ref != nil, v: $0.ref?["v"]?.number) }
        guard let w = Live.wtCountModel(c, cur: R.counters[cid] ?? 0, done: R.isChecked(key), ev: mark, last: last, now: now) else { return nil }
        return witness(w)
    }

    // MARK: Présentation du journal (`ovPresList`)

    enum Pres { case open, line, chip }
    static func ovPresList(complete: [Bool], manual: [Bool?], forcedOpen: Int?) -> [Pres] {
        let n = complete.count
        return (0..<n).map { i in
            if i == n - 1 || i == forcedOpen { return .open }
            if manual[i] == false { return .open }
            if !complete[i] { return manual[i] == true ? .line : .open }
            return .chip
        }
    }
    /// `ovFoldRemap(avant, après)` : les replis suivent leur VISITE quand le chemin est réordonné.
    static func ovFoldRemap(_ fold: [String: Bool], before: [Int], after: [Int]) -> [String: Bool] {
        if before == after { return fold }
        var pos: [Int: Int] = [:]
        for (i, s) in after.enumerated() { pos[s] = i }
        var n: [String: Bool] = [:]
        for (k, v) in fold {
            let isRun = k.hasPrefix("r:")
            let digits = isRun ? String(k.dropFirst(2)) : k
            guard !digits.isEmpty, digits.allSatisfy({ $0.isASCII && $0.isNumber }), let ix = Int(digits) else { n[k] = v; continue }
            guard ix < before.count, let j = pos[before[ix]] else { continue }
            n[either(isRun, "r:", "") + String(j)] = v
        }
        return n
    }
    /// `ovDropOpens()` : tout geste de navigation rend les dépliages manuels à la condensation automatique.
    static func ovDropOpens(_ fold: [String: Bool]) -> [String: Bool] {
        fold.filter { k, v in !(v == false && (k.hasPrefix("r:") || (!k.isEmpty && k.allSatisfy { $0.isASCII && $0.isNumber }))) }
    }
    /// « d/t étapes » : somme sur la DERNIÈRE visite de chaque bloc numéroté (`minimapData`).
    static func progress(_ R: RuntimeSession) -> (done: Int, tot: Int) {
        let m = Parcours.minimapData(R.fiche, nav: R.nav, navSeq: R.navSeq, checked: Set(R.checkedKeys))
        return (m.reduce(0) { $0 + $1.done }, m.reduce(0) { $0 + $1.tot })
    }
    /// `offPathSet` (session seulement).
    static func offPath(_ R: RuntimeSession) -> Set<String> {
        R.started ? Parcours.offPathSet(R.fiche, nav: R.nav) : []
    }
}
