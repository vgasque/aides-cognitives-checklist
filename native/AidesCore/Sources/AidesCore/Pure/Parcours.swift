import Foundation

// LE PARCOURS D'UNE AIDE — port des fonctions pures qui lisent le graphe des blocs : `flowPlan`
// (numérotation « le tronc d'abord », A344), `offPathSet`, `minimapData`, `cxAll`/`cxDetached`,
// `linkOf`, `jalonCondLbl`, `cycleHint`/`cycleTxt`, `phasesOf`, `completionSpots`, les revues
// (`revBlocks`, `revState`, `revKeysLift`, `REV_SEQ`), la bande des repères (`posBandModel`), les
// réglages de coche en mots (`stepGroups`, `stepQualTxt`, `blkTimerTxt`) et les noms courts.
//
// LE NUMÉRO EST PARTAGÉ : journal, parcours, Page et schéma disent le même numéro parce qu'ils
// lisent le même `flowPlan.order`. Le natif doit donc produire EXACTEMENT le même ordre — c'est ce
// que l'oracle vérifie, sur les aides d'exemple et sur des graphes tirés au sort (boucles,
// décisions imbriquées, cibles pendantes, complications).
//
// Les dépendances globales de la PWA (`state.nav`, `state.checked`, `Runtime`…) deviennent des
// PARAMÈTRES : `nav`/`navSeq` (le journal), `checked` (clés « visite:bloc:index » cochées).

public enum Parcours {
    // MARK: Lectures communes du modèle

    /// `stepsOf(b)` : les étapes d'un bloc en chaînes v3 (« ⚠ défi :: réponse »), items résolus.
    public static func stepsOf(_ f: Fiche, _ b: Block) -> [String] { Pool.blockItems(f, b).map(\.legacyString) }

    /// Les cinq listes de portée fiche (`listOf(f, key)`), vues sur le pool.
    public enum ListKey: String, CaseIterable, Sendable { case confirmation, notForget, verify, posology, differentials }
    public static func listOf(_ f: Fiche, _ key: ListKey) -> [String] {
        switch key {
        case .notForget: return Pool.roleItems(f, .do).filter(\.memory).map(\.legacyString)
        case .confirmation: return Pool.roleItems(f, .entry).map(\.legacyString)
        case .verify: return Pool.roleItems(f, .watch).map(\.legacyString)
        case .posology: return Pool.roleItems(f, .dose).map(\.legacyString)
        case .differentials: return Pool.roleItems(f, .ddx).map(\.legacyString)
        }
    }
    /// `forgetAll(f)` : le chapeau « Ne pas oublier » dans l'ordre du pool (portée fiche ET ★ d'étape).
    public static func forgetAll(_ f: Fiche) -> [String] { Pool.forget(f).map(\.item.legacyString) }

    /// `blocksById` : PREMIER gagnant (un id dupliqué garde sa première définition).
    static func byId(_ f: Fiche) -> [String: Block] {
        var m: [String: Block] = [:]
        for b in f.blocks where !b.id.isEmpty && m[b.id] == nil { m[b.id] = b }
        return m
    }
    /// `blkSucc(b)` : suites d'un bloc d'étapes, cibles d'une décision.
    static func succ(_ b: Block?) -> [String] {
        guard let b else { return [] }
        if b.kind == .decision { return b.options.compactMap { ($0.target?.isEmpty == false) ? $0.target : nil } }
        if let n = b.next, !n.isEmpty { return [n] }
        return []
    }
    /// Blocs atteignables depuis `from`. TODO fusion : Graph.blkReach (moteur de session).
    static func _reach(_ f: Fiche, _ from: String?) -> Set<String> {
        let by = byId(f)
        var seen = Set<String>()
        var q: [String] = from.map { [$0] } ?? []
        while let id = q.popLast() {
            guard !id.isEmpty, !seen.contains(id), let b = by[id] else { continue }
            seen.insert(id)
            q.append(contentsOf: succ(b))
        }
        return seen
    }
    /// Dernier passage d'un bloc. TODO fusion : Graph.latestPass.
    static func _latestPass(_ nav: [String], _ navSeq: [Int], _ id: String) -> (idx: Int, seq: Int, pass: Int, total: Int)? {
        var idx = -1, total = 0
        for (i, x) in nav.enumerated() where x == id { total += 1; idx = i }
        if idx < 0 { return nil }
        let s = idx < navSeq.count ? navSeq[idx] : 0
        return (idx, s != 0 ? s : 1, total, total)
    }

    // MARK: flowPlan

    /// Élément du plan : le parcours ENTIER en arbre indenté.
    public enum PlanItem: Equatable, Sendable {
        case block(id: String, depth: Int)
        /// Ouverture d'une branche de décision (`tgt` nil = option sans cible valide).
        case branchOpen(dec: String, option: Int, label: String, target: String?, depth: Int)
        case branchClose
        /// Renvoi « → n » ou « ↺ n » (`back` : la cible est numérotée AVANT la source).
        case link(to: String, from: String?, depth: Int, back: Bool)
        case end(depth: Int)
    }
    public struct Plan: Equatable, Sendable {
        public var items: [PlanItem]
        /// Ordre de LECTURE = numérotation commune (plan, journal, chips, rail, Page, schéma).
        public var order: [String]
    }

    /// `flowPlan(f)` — DFS depuis le départ ; le tronc reprend au POINT DE CONVERGENCE (plus proche
    /// post-dominateur commun à au moins DEUX options, arêtes de retour ignorées) ; une option qui n'y
    /// passe pas est une SORTIE, chaînée après le tronc ; une cible de complication jamais atteinte
    /// reste hors du tronc (elle s'entre par l'évènement, jamais comme « l'étape d'après »).
    /// La PWA met le résultat en cache par objet fiche ; ici l'appelant garde le résultat s'il le relit.
    public static func flowPlan(_ f: Fiche) -> Plan {
        let blocks = f.blocks
        let by = byId(f)
        var items: [PlanItem] = [], order: [String] = []
        if blocks.isEmpty { return Plan(items: [], order: []) }
        let X = "#exit"   // sentinelle : un id SAFE_ID ne contient jamais « # »
        let ids = blocks.map(\.id).filter { !$0.isEmpty && by[$0] != nil }
        func succ(_ id: String) -> [String] {
            let b = by[id]!
            if b.kind == .decision {
                let t = b.options.map { o -> String in (o.target.map { !$0.isEmpty && by[$0] != nil } ?? false) ? o.target! : X }
                return t.isEmpty ? [X] : t
            }
            if let n = b.next, !n.isEmpty, by[n] != nil { return [n] }
            return [X]
        }
        let start = (f.start.map { by[$0] != nil } ?? false) ? f.start! : blocks[0].id
        // Arêtes de retour (DFS dans l'ordre des options) : elles valent une sortie pour la post-dominance.
        var backE = Set<String>()
        do {
            var onStack = Set<String>(), fini = Set<String>()
            func dfs(_ u: String) {
                onStack.insert(u)
                for v in succ(u) where v != X {
                    if onStack.contains(v) { backE.insert(u + ">" + v) } else if !fini.contains(v) { dfs(v) }
                }
                onStack.remove(u); fini.insert(u)
            }
            dfs(start)
            for id in ids where !fini.contains(id) { dfs(id) }
        }
        func succD(_ id: String) -> [String] { succ(id).map { ($0 != X && backE.contains(id + ">" + $0)) ? X : $0 } }
        // Post-dominateurs (itératif) : pdom[n] = {n} ∪ ∩ pdom(successeurs).
        var pdom: [String: Set<String>] = [X: [X]]
        let all = Set(ids + [X])
        for id in ids { pdom[id] = all }
        var moved = true
        while moved {
            moved = false
            for id in ids {
                var inter: Set<String>? = nil
                for s in succD(id) { let ps = pdom[s]!; inter = inter == nil ? ps : inter!.intersection(ps) }
                var v = inter ?? []
                v.insert(id)
                if v.count != pdom[id]!.count { pdom[id] = v; moved = true }
            }
        }
        let pos: [String: Int] = Dictionary(ids.enumerated().map { ($0.element, $0.offset) }, uniquingKeysWith: { a, _ in a })
        func joinOf(_ id: String) -> String? {
            let tg = succD(id).filter { $0 != X }
            var cnt: [String: Int] = [:]
            for t in tg { for p in pdom[t]! where p != X && p != id { cnt[p, default: 0] += 1 } }
            let c = cnt.keys.filter { cnt[$0]! >= 2 }
            if c.isEmpty { return nil }
            return c.sorted { a, b in
                let da = pdom[a]!.count, db = pdom[b]!.count
                if da != db { return da > db }
                if cnt[a]! != cnt[b]! { return cnt[a]! > cnt[b]! }
                return pos[a]! < pos[b]!
            }[0]
        }
        var rendered = Set<String>()
        func link(_ to: String, _ from: String?, _ depth: Int) { items.append(.link(to: to, from: from, depth: depth, back: false)) }
        func walk(_ id: String, _ stop: String?, _ depth: Int, _ pend: inout [String]) {
            var cur: String? = id, prev: String? = nil
            while let c = cur, c != stop, c != X {
                if rendered.contains(c) { link(c, prev, depth); return }
                guard let b = by[c] else { return }
                rendered.insert(c); order.append(c)
                items.append(.block(id: c, depth: depth))
                if b.kind == .decision {
                    var join = joinOf(c)
                    if let j = join, rendered.contains(j) { join = nil }   // convergence déjà décrite : les branches lieront
                    for (oi, o) in b.options.enumerated() {
                        let tgt: String? = (o.target.map { !$0.isEmpty && by[$0] != nil } ?? false) ? o.target : nil
                        items.append(.branchOpen(dec: c, option: oi, label: o.label.isEmpty ? "Option \(oi + 1)" : o.label, target: tgt, depth: depth + 1))
                        if let t = tgt {
                            if t == join || rendered.contains(t) { link(t, c, depth + 1) }
                            else if let j = join, !pdom[t]!.contains(j) { link(t, c, depth + 1); pend.append(t) }
                            else { chain(t, join, depth + 1) }
                        } else { items.append(.end(depth: depth + 1)) }
                        items.append(.branchClose)
                    }
                    // Le tronc reprend au point de convergence, sauf s'il est la butée du niveau englobant.
                    if let j = join, j != stop { prev = c; cur = j; continue }
                    return
                }
                guard let nx = b.next, !nx.isEmpty, by[nx] != nil else { items.append(.end(depth: depth)); return }
                prev = c; cur = nx
            }
            if let c = cur, c == stop, let s = stop, s != X { link(s, prev, depth) }
        }
        // Les sorties en attente d'une décision se chaînent quand le tronc qui la porte est épuisé.
        func chain(_ id: String, _ stop: String?, _ depth: Int) {
            var pend: [String] = []
            walk(id, stop, depth, &pend)
            for t in pend where !rendered.contains(t) { chain(t, stop, depth) }
        }
        chain(start, nil, 0)
        let cxT = Set(f.excursions.map(\.target).filter { !$0.isEmpty })
        for b in blocks where !b.id.isEmpty && by[b.id] != nil && !rendered.contains(b.id) && !cxT.contains(b.id) && b.kind != .review {
            chain(b.id, nil, 0)
        }
        // « ↺ » ou « → » se décide sur le NUMÉRO, pas sur l'ordre de visite.
        var idx: [String: Int] = [:]
        for (i, id) in order.enumerated() { idx[id] = i }
        items = items.map { it in
            guard case .link(let to, let from, let d, _) = it else { return it }
            var back = false
            if let a = idx[to], let fr = from, let b = idx[fr] { back = a < b }
            return .link(to: to, from: from, depth: d, back: back)
        }
        return Plan(items: items, order: order)
    }

    // MARK: Hors chemin, minimap

    /// `offPathSet(f, nav, navPos)` : blocs ni visités ni atteignables depuis la position courante
    /// (tête irrésoluble → repli sur le départ, sinon tout serait grisé).
    public static func offPathSet(_ f: Fiche, nav: [String], navPos: Int? = nil) -> Set<String> {
        let blocks = f.blocks
        var out = Set<String>()
        if blocks.isEmpty { return out }
        let by = byId(f)
        var keep = Set(nav)
        let len = nav.count
        let np = max(0, min(navPos ?? (len - 1), len - 1))
        let head: String? = np < nav.count ? nav[np] : nil
        // Parité fine : en JS `byId[undefined]` lit la clé « undefined » et `byId[null]` la clé
        // « null » — un bloc portant ces ids (valides SAFE_ID) change le repli. Reproduit tel quel.
        let from: String? = by[head ?? "undefined"] != nil ? head : (by[f.start ?? "null"] != nil ? f.start : blocks[0].id)
        keep.formUnion(_reach(f, from))
        for b in blocks where !b.id.isEmpty && !keep.contains(b.id) { out.insert(b.id) }
        return out
    }

    /// État affichable d'un bloc (ordre du plan) — `minimapData`.
    public struct BlockState: Equatable, Sendable {
        public var id: String
        /// Numéro commun (1-based, ordre de `flowPlan`).
        public var n: Int
        public var title: String
        public var dec: Bool
        public var off: Bool
        public var cur: Bool
        public var visited: Bool
        /// Visite du dernier passage (0 = jamais visité).
        public var seq: Int
        public var done: Int
        public var tot: Int
        public var complete: Bool
        /// Décision : réponse prise (cible suivante du journal).
        public var taken: String?
        public var pass: Int
        public var total: Int
    }
    /// `minimapData(f, nav, navSeq, checked, navPos)`.
    public static func minimapData(_ f: Fiche, nav: [String], navSeq: [Int], checked: Set<String>, navPos: Int? = nil) -> [BlockState] {
        let by = byId(f)
        let off = offPathSet(f, nav: nav, navPos: navPos)
        let len = nav.count
        let np = max(0, min(navPos ?? (len - 1), len - 1))
        let curId: String? = np < nav.count ? nav[np] : nil
        return flowPlan(f).order.enumerated().map { i, id in
            let b = by[id]!
            let lp = _latestPass(nav, navSeq, id)
            let dec = b.kind == .decision
            let steps = dec ? [] : Txt.clean(stepsOf(f, b))
            let seq = lp?.seq ?? 0
            var done = 0
            for j in steps.indices where checked.contains("\(seq):\(id):\(j)") { done += 1 }
            var taken: String? = nil
            if dec, let lp, lp.idx + 1 < nav.count {
                let nx = nav[lp.idx + 1]
                if b.options.contains(where: { ($0.target ?? "") != "" && $0.target == nx }) { taken = nx }
            }
            return BlockState(id: id, n: i + 1, title: b.title, dec: dec, off: off.contains(id), cur: id == curId, visited: lp != nil, seq: seq,
                              done: done, tot: steps.count, complete: dec ? taken != nil : (!steps.isEmpty && done >= steps.count), taken: taken,
                              pass: lp?.pass ?? 0, total: lp?.total ?? 0)
        }
    }

    // MARK: Complications, liens, jalons, cycles

    /// Complication déclarée, résolue par nature : 'block' (bloc de la fiche) ou 'ext' (autre aide).
    public struct Complication: Equatable, Sendable {
        public var label: String
        public var target: String
        public var short: String
        public var isBlock: Bool
        public var kind: String { isBlock ? "block" : "ext" }
    }
    /// `cxAll(f)` : déclarations valides (libellé ET cible).
    public static func cxAll(_ f: Fiche) -> [Complication] {
        let ids = Set(f.blocks.map(\.id).filter { !$0.isEmpty })
        return f.excursions.filter { !$0.label.isEmpty && !$0.target.isEmpty }
            .map { Complication(label: $0.label, target: $0.target, short: $0.short ?? "", isBlock: ids.contains($0.target)) }
    }
    /// `cxDetached(f)` : cibles-blocs HORS du tronc de `flowPlan` (section « À tout moment »).
    public static func cxDetached(_ f: Fiche) -> [Complication] {
        let order = Set(flowPlan(f).order)
        return cxAll(f).filter { $0.isBlock && !order.contains($0.target) }
    }

    /// Lien d'une coche (A377) : elle LANCE un minuteur ou COMPTE sur un compteur.
    public enum CheckLink: Equatable, Sendable { case timer(String), counter(String) }
    /// `linkOf(it)`.
    public static func linkOf(_ it: Item?) -> CheckLink? {
        guard let it else { return nil }
        if let s = it.starts, !s.isEmpty { return .timer(s) }
        if let c = it.counts, !c.isEmpty { return .counter(c) }
        return nil
    }

    /// `jalonCondLbl(f, j)` : la condition d'un jalon en toutes lettres.
    public static func jalonCondLbl(_ f: Fiche, _ j: Milestone) -> String {
        if j.at == .count {
            let c = f.counters.first { $0.id == j.counter }
            return ((c?.label).flatMap { $0.isEmpty ? nil : $0 } ?? "compteur") + " ≥ " + String(j.n)
        }
        return "à partir du " + (j.n == 1 ? "1ᵉʳ" : "\(j.n)ᵉ") + " passage"
    }

    /// `cycleHint(f)` : l'UNIQUE minuteur à cycles de la fiche (deux → aucune attribution devinée).
    public static func cycleHint(_ f: Fiche) -> TimerDef? {
        let ts = f.timers.filter { $0.type == .interval && $0.autoloop && $0.seconds > 0 }
        return ts.count == 1 ? ts[0] : nil
    }
    /// `cycleTxt(f)` : « · toutes les 2 min » (ou '').
    public static func cycleTxt(_ f: Fiche) -> String {
        guard let t = cycleHint(f) else { return "" }
        return " · toutes les " + Txt.durTxt(t.seconds)
    }

    // MARK: Phases, relecture « à compléter »

    /// `phaseOf(f, bid)` — phase HÉRITÉE du bloc précédent (déjà portée : `Pool.phase`).
    public static func phaseOf(_ f: Fiche, _ bid: String) -> String { Pool.phase(f, bid) }
    /// `phasesOf(f)` : les phases réellement présentes, dans l'ordre des blocs, sans doublon.
    public static func phasesOf(_ f: Fiche) -> [String] {
        var seen = Set<String>(), out: [String] = []
        for b in f.blocks {
            let p = Pool.phase(f, b.id)
            if !p.isEmpty, !seen.contains(p) { seen.insert(p); out.append(p) }
        }
        return out
    }

    static let todoRx = JSRegExp("[àa] compl[eé]ter", "i")
    /// `completionSpots(f)` : où la fiche contient encore « à compléter » (libellés de section/bloc).
    public static func completionSpots(_ f: Fiche) -> [String] {
        var spots: [String] = []
        if todoRx.test(f.local) { spots.append("Contexte local") }
        let sect: [(ListKey?, String)] = [(.confirmation, "Confirmation diagnostique"), (.verify, "À vérifier"), (.notForget, "Ne pas oublier"),
                                          (.posology, "Repères posologiques"), (.differentials, "Diagnostics différentiels"), (nil, "Références")]
        for (k, lbl) in sect {
            let list = k.map { listOf(f, $0) } ?? f.sources
            if list.contains(where: { todoRx.test($0) }) { spots.append(lbl) }
        }
        for b in f.blocks {
            let hit = todoRx.test(b.title) || todoRx.test(b.question) || stepsOf(f, b).contains(where: { todoRx.test($0) })
                || b.options.contains(where: { todoRx.test($0.label) })
            if hit { spots.append("Bloc « " + (JS.trim(b.title).isEmpty ? "sans titre" : JS.trim(b.title)) + " »") }
        }
        return spots
    }

    // MARK: Revues « à tout moment » (A396/A398)

    /// `REV_SEQ` : la revue est UNE par session — ses coches vivent sous « r:revue:index ».
    public static let revSeq = "r"
    /// `revBlocks(f)`.
    public static func revBlocks(_ f: Fiche) -> [Block] { f.blocks.filter { $0.kind == .review } }
    /// `revKeysLift(f, ck)` : une session née avant A398 voit ses coches « visite:revue:i » rejoindre
    /// la revue de session. Rend le jeu de coches transformé.
    public static func revKeysLift(_ f: Fiche, _ ck: [String: Bool]) -> [String: Bool] {
        let ids = Set(revBlocks(f).map(\.id))
        if ids.isEmpty { return ck }
        var out = ck
        for (k, v) in ck {
            let p = JS.split(k, ":")
            if p.count == 3, p[0] != revSeq, ids.contains(p[1]) {
                if v { out[revSeq + ":" + p[1] + ":" + p[2]] = true }
                out[k] = nil
            }
        }
        return out
    }
    /// `revState(rb, seq, checked)` : {k cochées, n hypothèses, done}.
    public static func revState(_ f: Fiche, _ rb: Block, seq: String, checked: Set<String>) -> (k: Int, n: Int, done: Bool) {
        let n = Txt.clean(stepsOf(f, rb)).count
        var k = 0
        for i in 0..<n where checked.contains("\(seq):\(rb.id):\(i)") { k += 1 }
        return (k, n, n > 0 && k == n)
    }

    /// Le MOMENT d'une étape tel que le rend `momentOf` (A382) — seuls les champs lus ici.
    /// TODO fusion : Moments.momentOf (moteur de session) rendra ce type.
    public struct MomentInfo: Equatable, Sendable {
        /// wait · gone · due · need · met
        public var st: String
        public var req: Bool
        public init(st: String, req: Bool = false) { self.st = st; self.req = req }
    }
    /// Rangée de la bande des repères d'un bloc (A397).
    public struct PosBandRow: Equatable, Sendable {
        public var id: String, name: String, body: String, note: String
        /// « fait » · « à faire » · « à préparer » — venu de la COCHE, jamais d'un minuteur.
        public var stt: String
    }
    /// `posBandModel(f, b, seq, checked, moOf)` : un repère par étape liée (`item.poso`), sans doublon.
    public static func posBandModel(_ f: Fiche, _ b: Block, seq: String, checked: Set<String>, moOf: ((Item, Int) -> MomentInfo?)? = nil) -> [PosBandRow] {
        let its = Pool.blockItems(f, b)
        var by: [String: Item] = [:]
        for it in Pool.roleItems(f, .dose) { by[it.id] = it }
        var out: [PosBandRow] = [], seen = Set<String>()
        var next = true
        for (i, it) in its.enumerated() {
            let d = it.poso.flatMap { by[$0] }
            let on = checked.contains("\(seq):\(b.id):\(i)")
            let mo = (!on && moOf != nil) ? moOf!(it, i) : nil
            let wait = mo?.st == "wait", gone = mo?.st == "gone"
            let req = !on && !wait && !gone && (it.review ?? "").isEmpty && (mo == nil || mo!.req)
            guard let d, !seen.contains(d.id) else { if req { next = false }; continue }
            seen.insert(d.id)
            let p = Posology.parts(d.legacyString)
            out.append(PosBandRow(id: d.id, name: p.name, body: p.body, note: JS.trim(d.note),
                                  stt: (on || gone) ? "fait" : ((wait || !next) ? "à préparer" : "à faire")))
            if req { next = false }
        }
        return out
    }

    // MARK: Réglages de coche en mots (A388/A391)

    /// Groupe d'étapes consécutives au même seuil (`from`) ; l'ordre de l'auteur n'est jamais changé.
    public struct StepGroup: Equatable, Sendable {
        public var from: ItemFrom?
        /// Première étape du groupe (groupes à seuil seulement).
        public var item: Item?
        public var ix: [Int]
    }
    /// `stepGroups(its, n)`.
    public static func stepGroups(_ its: [Item], _ n: Int) -> [StepGroup] {
        var out: [StepGroup] = []
        var i = 0
        func at(_ k: Int) -> Item? { k >= 0 && k < its.count ? its[k] : nil }
        while i < n {
            guard let fr = at(i)?.from else { out.append(StepGroup(from: nil, item: nil, ix: [i])); i += 1; continue }
            var g = StepGroup(from: fr, item: at(i), ix: [])
            while i < n, let x = at(i)?.from, x.counter == fr.counter, x.n == fr.n { g.ix.append(i); i += 1 }
            out.append(g)
        }
        return out
    }
    /// `tmLabelParts(label)` : « nom (précision) » → nom + méta.
    static let rxLabelParts = JSRegExp(#"^(.*\S)\s*\(([^()]{2,})\)$"#)
    public static func tmLabelParts(_ label: String) -> (name: String, meta: String) {
        let t = JS.trim(label)
        if let m = rxLabelParts.exec(t) { return (m[1]!, m[2]!) }
        return (t, "")
    }
    /// `tmName(t)` : nom affiché d'un minuteur, sinon son défaut par nature.
    public static func tmName(label: String, interval: Bool) -> String {
        let n = tmLabelParts(label).name
        return n.isEmpty ? (interval ? "Minuteur" : "Chronomètre") : n
    }
    static func tmName(_ t: TimerDef) -> String { tmName(label: t.label, interval: t.type == .interval) }
    /// `momTid(f, it)` : le minuteur que relance la coche (lancé, ou via le compteur lié).
    public static func momTid(_ f: Fiche, _ it: Item) -> String {
        if let s = it.starts, !s.isEmpty { return s }
        if let c = it.counts, let cc = f.counters.first(where: { $0.id == c }) { return cc.timerId }
        return ""
    }
    /// `ONCE_FAITE` (A392).
    public static let onceFaite = "✓ faite — plus à refaire"
    /// `stepQualTxt(f, it, {faite, sansOnce})` : ce que règle l'étape, en mots.
    public static func stepQualTxt(_ f: Fiche, _ it: Item, faite: Bool = false, sansOnce: Bool = false) -> String {
        func T(_ id: String) -> TimerDef? { f.timers.first { $0.id == id } }
        let C = it.counts.flatMap { c in f.counters.first { $0.id == c } }
        func dur(_ t: TimerDef?) -> String { (t != nil && t!.type == .interval && t!.seconds > 0) ? " (" + Txt.durTxt(t!.seconds) + ")" : "" }
        let t = T(momTid(f, it))
        var q: [String] = []
        switch it.repeat {
        case .once?: if !sansOnce { q.append(faite ? onceFaite : "si pas déjà faite") }
        case .need?: q.append("au besoin")
        case .due?:
            if let t {
                q.append(t.type == .interval && t.seconds > 0 ? "toutes les " + Txt.durTxt(t.seconds) : "quand " + Txt.guil(tmName(t)) + " ne tourne pas")
            }
        case nil: break
        }
        if let C {
            let r = (!C.timerId.isEmpty && it.repeat != .due) ? T(C.timerId) : nil
            let nm = tmLabelParts(C.label).name
            q.append("+" + String(max(1, C.step)) + " " + (nm.isEmpty ? "Compteur" : nm) + (r != nil ? " · relance " + Txt.guil(tmName(r!)) + dur(r) : ""))
        } else if let s = it.starts, !s.isEmpty, it.repeat != .due, let x = T(s) {
            q.append("lance " + Txt.guil(tmName(x)) + dur(x))
        }
        return q.joined(separator: " · ")
    }
    /// `blkTimerTxt(f, b)` : le minuteur d'un bloc, en mots.
    public static func blkTimerTxt(_ f: Fiche, _ b: Block) -> String {
        guard let id = b.timer, let t = f.timers.first(where: { $0.id == id }) else { return "" }
        return "lance " + Txt.guil(tmName(t)) + (t.type == .interval && t.seconds > 0 ? " (" + Txt.durTxt(t.seconds) + ")" : "") + " à chaque entrée"
    }

    // MARK: Noms courts (A403)

    static let shortStop: Set<String> = ["après", "avant", "de", "du", "des", "la", "le", "les", "en", "pour", "sur", "avec", "et", "au", "aux", "à", "par", "d", "l"]
    /// `SHORT_TM`, `SHORT_CN`, `SHORT_CX` : budgets de caractères.
    public static let shortTimer = 14, shortCounter = 10, shortComplication = 20
    static let rxWs = JSRegExp(#"\s+"#, "g")
    static let rxTailParen = JSRegExp(#"\s*\([^()]*\)\s*$"#)
    static let rxElision = JSRegExp("^([ld])['’].*$")
    static func shortCut(_ w: [UInt16]) -> [UInt16] {
        let V = Array("aeiouyàâäéèêëîïôöùûü".utf16)
        var i = 4
        while i < w.count - 2, let l = JSRegExp.lower1(w[i]), V.contains(l) { i += 1 }
        return Array(w.prefix(i + 1)) + [46]
    }
    /// `autoShort(name, max)` : un minuteur se DISTINGUE par son dernier mot — on abrège d'abord les
    /// premiers, puis le dernier, puis on retire les mots du milieu.
    public static func autoShort(_ name: String, _ max: Int) -> String {
        let full = JS.trim(rxWs.replace(name, " "))
        var s = JS.trim(rxTailParen.replace(full, ""))
        if s.isEmpty { s = full }
        if JS.length(s) <= max { return s }
        var ws = JS.split(s, " ").enumerated().filter { i, x in i == 0 || !shortStop.contains(rxElision.replace(JS.toLowerCase(x), "$1")) }.map { Array($0.element.utf16) }
        func joined() -> String { ws.map { JS.str($0) }.joined(separator: " ") }
        s = joined(); if JS.length(s) <= max { return s }
        if ws.count > 1 {
            for i in 0..<(ws.count - 1) where ws[i].count > 6 {
                ws[i] = shortCut(ws[i]); s = joined(); if JS.length(s) <= max { return s }
            }
        }
        let L = ws.count - 1
        if ws[L].count > 6 { ws[L] = shortCut(ws[L]); s = joined(); if JS.length(s) <= max { return s } }
        while ws.count > 2, JS.length(joined()) > max { ws.remove(at: 1) }
        return joined()
    }
    /// `autoShortHead(name, max)` : une complication se NOMME par son premier mot — on retire les derniers.
    public static func autoShortHead(_ name: String, _ max: Int) -> String {
        var ws = JS.split(JS.trim(rxWs.replace(name, " ")), " ")
        while ws.count > 1, JS.length(ws.joined(separator: " ")) > max { ws.removeLast() }
        return ws.joined(separator: " ")
    }
    /// `tmShort(t)`, `cnShort(c)`, `cxShort(c)` : le nom court fixé par l'auteur, sinon abrégé d'office.
    public static func tmShort(_ t: TimerDef) -> String { (t.short?.isEmpty == false) ? t.short! : autoShort(t.label, shortTimer) }
    public static func cnShort(_ c: CounterDef) -> String { (c.short?.isEmpty == false) ? c.short! : autoShort(c.label, shortCounter) }
    public static func cxShort(label: String, short: String?) -> String {
        (short?.isEmpty == false) ? short! : autoShortHead(cxKeyLabel(Txt.stripBold(label)), shortComplication)
    }
    static let rxKeyLabel = JSRegExp(#"^(.*?)\s*\([^()]*\)$"#)
    /// `cxKeyLabel(s)` : la parenthèse finale tombe, seulement si la tête survit.
    public static func cxKeyLabel(_ s0: String) -> String {
        let s = JS.trim(s0)
        let tete = rxKeyLabel.exec(s).map { JS.trim($0[1]!) } ?? ""
        return tete.isEmpty ? s : tete
    }

    static let rxNotAbbr = JSRegExp("[^0-9A-ZÀ-ÖØ-Þ]", "g")
    /// `optAbbr(labels)` : renvois abrégés — premier mot en capitales (6 car.), homonymes départagés.
    public static func optAbbr(_ labels: [String]) -> [String] {
        func words(_ l: String) -> [String] { JSRegExp(#"\s+"#).split(JS.trim(Txt.stripBold(l))) }
        func clean1(_ w: String?) -> String { rxNotAbbr.replace(JS.toUpperCase(w ?? ""), "") }
        let first = labels.map { l -> String in let a = JS.prefix(clean1(words(l).first), 6); return a.isEmpty ? "OPT" : a }
        return first.enumerated().map { i, a in
            if first.filter({ $0 == a }).count < 2 { return a }
            let w = words(labels[i])
            let b2 = JS.prefix(clean1(w.count > 1 ? w[1] : nil), 1)
            return b2.isEmpty ? a + String(i + 1) : a + "·" + b2
        }
    }
}
