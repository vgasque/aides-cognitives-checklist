import Foundation

// LA PAGE (« Tableau », A344) — port de `svTreePlan` (l'arbre EST le fil), du cartouche
// (`svValidWarn`, `svSources`, `svCountsTxt`) et de `carryParts` (« ce que la fiche embarque »,
// une phrase, deux lecteurs : écran d'entrée et atelier d'import).
//
// `svTreePlan` est PURE et sans DOM : elle rend les COLONNES (tronc, branches de fourche, rails),
// leurs RANGÉES (cellule, décision, pilule de renvoi, fourche, niveau de rail, fin) et les ARÊTES
// que le peintre mesure (sorties, retours, collecteurs, réunions de rail). Le natif dessinera la
// même composition : les rangées gardent les noms de champs de la PWA (`k`, `kind`, `tgt`…) pour
// que la doctrine A344/A391 se lise pareil des deux côtés.

public enum Page {
    /// `SV_W` : largeur d'auteur = A4 (740 px).
    public static let width = 740
    /// `SV_COL` : colonne racine — bordure, padding 14×2, gouttières 16 et 24.
    public static let rootColumn = width - 2 - 28 - 16 - 24

    // MARK: Cartouche

    static let validRx = JSRegExp(#"g[ée]n[ée]r[ée]e?\s+par\s+IA|[àa]\s+(re)?lire\s+et\s+valider|[àa]\s+valider"#, "i")
    /// `svValidWarn(f)` : les sources qui disent « générée par IA / à relire et valider » —
    /// l'avertissement OBLIGATOIRE du cartouche (une feuille affichée sans lui est un danger).
    public static func validWarn(_ f: Fiche) -> [String] { Txt.clean(f.sources).filter { validRx.test($0) } }
    /// `svSources(f)` : les autres sources.
    public static func sources(_ f: Fiche) -> [String] { Txt.clean(f.sources).filter { !validRx.test($0) } }

    /// `carryParts(f)` : « 6 blocs · 2 minuteurs · 1 complication déclarée » (revues exclues des blocs).
    public static func carryParts(_ f: Fiche) -> [String] {
        let nb = f.blocks.count - Parcours.revBlocks(f).count, tl = f.timers.count, cl = f.counters.count, cx = f.excursions.count
        var p: [String] = []
        if nb != 0 { p.append("\(nb)" + (nb > 1 ? " blocs" : " bloc")) }
        if tl != 0 { p.append("\(tl)" + (tl > 1 ? " minuteurs" : " minuteur")) }
        if cl != 0 { p.append("\(cl)" + (cl > 1 ? " compteurs" : " compteur")) }
        if cx != 0 { p.append("\(cx)" + (cx > 1 ? " complications déclarées" : " complication déclarée")) }
        return p
    }
    static let blocRx = JSRegExp("bloc")
    /// `svCountsTxt(f)` : le compte du cartouche = `carryParts` + les posologies (après les blocs).
    public static func countsTxt(_ f: Fiche) -> String {
        var p = carryParts(f)
        let np = Txt.clean(Parcours.listOf(f, .posology)).count
        if np != 0 {
            let at = (!p.isEmpty && blocRx.test(p[0])) ? 1 : 0
            p.insert("\(np)" + (np > 1 ? " posologies" : " posologie"), at: at)
        }
        return p.joined(separator: " · ")
    }
    /// `svRevTxt(f)` : « révision {mois année} » depuis `updatedAt` ('' sans horodatage).
    public static func revTxt(_ f: Fiche, tz: TimeZone = .current) -> String {
        f.updatedAt == 0 ? "" : Txt.frMonthYear(f.updatedAt, tz: tz)
    }

    // MARK: svTreePlan

    /// Alternative d'une décision : `kind` 'go' (branche à contenu), 'back' (retour), 'out' (sortie), 'fin'.
    public struct Alt: Equatable, Sendable { public var label: String; public var tgt: String?; public var kind: String }
    /// Branche d'une fourche : `cont` = elle se termine par la suite commune (barre de réunion).
    public struct ForkBranch: Equatable, Sendable { public var label: String; public var colId: String; public var cont: Bool }

    /// Rangée d'une colonne. `k` : 'fin' · 'cell' · 'pill' · 'dec' · 'fork' · 'lvl' ; les champs
    /// présents dépendent du genre, comme dans la PWA.
    public struct Row: Equatable, Sendable {
        public var k: String
        public var id: String? = nil
        public var fin: Bool? = nil
        public var colId: String? = nil
        /// pilule : 'loop' · 'cont' · 'out'
        public var kind: String? = nil
        public var to: String? = nil
        /// pilule : bloc d'où part le renvoi (peut manquer : `.some(nil)`).
        public var from: String?? = nil
        public var alts: [Alt]? = nil
        public var brs: [ForkBranch]? = nil
        public var dec: String? = nil
        public var label: String? = nil
        public var last: Bool? = nil
        /// Fourche : 'l', 'r' ou 'lr' — branches qui rejoignent la suite ; `mergeTo` = la suite.
        public var merge: String? = nil
        public var mergeTo: String? = nil
        /// Fourche portant un COLLECTEUR de retours (de l'air dessous).
        public var coll: Bool? = nil
        /// Rangée CIBLE d'une voie mesurée (marge d'entrée).
        public var tgt: Bool? = nil
        /// Bloc commun ENTRÉ par la barre de réunion de la fourche qui le précède.
        public var merged: Bool? = nil
    }
    public struct Column: Equatable, Sendable {
        public var id: String
        /// 'root' · 'fl' · 'fr' (fourche gauche/droite) · 'rail'
        public var kind: String
        public var w: Int
        public var depth: Int
        /// Colonne qui touche la voie de droite (sorties traçables).
        public var right: Bool
        public var parentId: String?
        public var rows: [Row]
    }
    /// Source d'une arête : une alternative de décision (« dec/cible ») ou une pilule (bloc d'origine).
    public struct EdgeSrc: Equatable, Sendable {
        public var alt: String? = nil
        public var pill: String?? = nil
        public var col: String? = nil
    }
    /// Arête à MESURER : 'loop' · 'collect' · 'rail' · 'exit' · 'railMerge'.
    public struct Edge: Equatable, Sendable {
        public var k: String
        public var src: EdgeSrc? = nil
        public var to: String
        public var col: String? = nil
        public var parent: String? = nil
        public var cols: [String]? = nil
        public var srcs: [EdgeSrc]? = nil
    }
    public struct TreePlan: Equatable, Sendable {
        public var cols: [Column]
        public var edges: [Edge]
        public var order: [String]
        /// bloc en tête de colonne → id de colonne (la dernière colonne gagne, comme en JS).
        public var firstOf: [String: String]
        public var root: Column { cols[0] }
    }

    indirect enum Seg {
        case block(String)
        case end
        case link(to: String, from: String?, back: Bool)
        case dec(id: String, brs: [(label: String, tgt: String?, segs: [Seg])])
        var blockId: String? { switch self { case .block(let id): return id; case .dec(let id, _): return id; default: return nil } }
    }

    /// `svTreePlan(f)` — cinq règles (le numéro est l'ancre ; la colonne des numéros est la surface
    /// de dessin ; une sortie s'écrit « SI … ALLER À n » ; un retour entre par la gauche ; deux
    /// branches à contenu = fourche côte à côte à pleine largeur, sinon un rail en retrait de 32 px).
    public static func treePlan(_ f: Fiche) -> TreePlan {
        let plan = Parcours.flowPlan(f)
        let items = plan.items
        let byId = Parcours.byId(f)
        // ÉTAPE 1 — l'arbre des segments.
        var i = 0
        func segs() -> [Seg] {
            var out: [Seg] = []
            while i < items.count {
                let it = items[i]
                if case .branchClose = it { break }
                switch it {
                case .branchOpen: i += 1; continue           // garde-fou : jamais hors décision
                case .link(let to, let from, _, let back): out.append(.link(to: to, from: from, back: back)); i += 1; continue
                case .end: out.append(.end); i += 1; continue
                case .block(let id, _):
                    guard let b = byId[id] else { i += 1; continue }
                    if b.kind != .decision { out.append(.block(id)); i += 1; continue }
                    i += 1
                    var brs: [(label: String, tgt: String?, segs: [Seg])] = []
                    while i < items.count, case .branchOpen(_, _, let label, let tgt, _) = items[i] {
                        i += 1
                        let inner = segs()
                        if i < items.count, case .branchClose = items[i] { i += 1 }
                        brs.append((label, tgt, inner))
                    }
                    out.append(.dec(id: id, brs: brs))
                default: i += 1
                }
            }
            return out
        }
        let racine = segs()
        // ÉTAPE 2 — les colonnes. Adresse d'une rangée = (colonne, rang).
        var cols: [Column] = []
        var colOf: [String: Int] = [:], rowOf: [String: (Int, Int)] = [:], parentOf: [String: Int?] = [:]
        func mkCol(_ kind: String, _ w: Int, _ depth: Int, _ right: Bool, _ parent: Int?) -> Int {
            let c = Column(id: "c\(cols.count)", kind: kind, w: w, depth: depth, right: right, parentId: parent.map { cols[$0].id }, rows: [])
            cols.append(c)
            parentOf[c.id] = parent
            return cols.count - 1
        }
        func firstBlock(_ ss: [Seg]) -> String? { for s in ss { if let id = s.blockId { return id } }; return nil }
        func emit(_ ss: [Seg], _ col: Int, _ nextId: String?, _ inline: Bool) {
            var prev: String? = nil
            var k = 0
            while k < ss.count {
                let s = ss[k], last = k == ss.count - 1
                defer { k += 1 }
                switch s {
                case .end: cols[col].rows.append(Row(k: "fin"))
                case .block(let id):
                    var fin = false
                    if k + 1 < ss.count, case .end = ss[k + 1] { fin = true; k += 1 }
                    cols[col].rows.append(Row(k: "cell", id: id, fin: fin, colId: cols[col].id))
                    colOf[id] = col; rowOf[id] = (col, cols[col].rows.count - 1); prev = id
                case .link(let to, let from, let back):
                    if !back, last, let n = nextId, to == n, inline { continue }
                    let kind = back ? "loop" : ((nextId != nil && to == nextId) ? "cont" : "out")
                    cols[col].rows.append(Row(k: "pill", colId: cols[col].id, kind: kind, to: to, from: .some(prev ?? from)))
                case .dec(let did, let brs):
                    var content: [(label: String, tgt: String?, segs: [Seg])] = []
                    let alts: [Alt] = brs.map { br in
                        if let fb = firstBlock(br.segs) { content.append(br); return Alt(label: br.label, tgt: fb, kind: "go") }
                        for x in br.segs { if case .link(let to, _, let back) = x { return Alt(label: br.label, tgt: to, kind: back ? "back" : "out") } }
                        return Alt(label: br.label, tgt: nil, kind: "fin")
                    }
                    cols[col].rows.append(Row(k: "dec", id: did, colId: cols[col].id, alts: alts))
                    colOf[did] = col; rowOf[did] = (col, cols[col].rows.count - 1); prev = did
                    let after: String? = (k + 1 < ss.count && ss[k + 1].blockId != nil) ? ss[k + 1].blockId : nextId
                    let kk = content.count
                    if kk == 1 {
                        emit(content[0].segs, col, after, true)       // (5) une seule branche à contenu : la suite du tronc
                    } else if kk == 2 && cols[col].kind == "root" && cols[col].w >= 560 {
                        var fbs: [ForkBranch] = []
                        for (bi, br) in content.enumerated() {
                            let c = mkCol(bi != 0 ? "fr" : "fl", (cols[col].w - 12) / 2, cols[col].depth, cols[col].right && bi == 1, col)
                            emit(br.segs, c, after, false)
                            let lr = cols[c].rows.last
                            fbs.append(ForkBranch(label: br.label, colId: cols[c].id, cont: lr?.k == "pill" && lr?.kind == "cont"))
                        }
                        var fr = Row(k: "fork", brs: fbs, dec: did)
                        if after != nil, fbs[0].cont || fbs[1].cont { fr.merge = (fbs[0].cont ? "l" : "") + (fbs[1].cont ? "r" : "") }
                        if fr.merge != nil { fr.mergeTo = after }
                        cols[col].rows.append(fr)
                    } else if kk >= 2 {
                        for (bi, br) in content.enumerated() {
                            let c = mkCol("rail", cols[col].w - 32, cols[col].depth + 1, cols[col].right, col)
                            emit(br.segs, c, after, false)
                            cols[col].rows.append(Row(k: "lvl", colId: cols[c].id, dec: did, label: br.label, last: bi == content.count - 1))
                        }
                    }
                }
            }
        }
        let root = mkCol("root", rootColumn, 0, true, nil)
        emit(racine, root, nil, false)
        // Le bloc commun d'une fourche est ENTRÉ par sa barre de réunion.
        for c in cols.indices {
            for ri in cols[c].rows.indices where cols[c].rows[ri].k == "fork" && cols[c].rows[ri].merge != nil {
                if ri + 1 < cols[c].rows.count, let nid = cols[c].rows[ri + 1].id, nid == cols[c].rows[ri].mergeTo { cols[c].rows[ri + 1].merged = true }
            }
        }
        var firstOf: [String: String] = [:]
        for c in cols { if let id = c.rows.first?.id { firstOf[id] = c.id } }
        // ÉTAPE 3 — les arêtes à MESURER.
        var edges: [Edge] = []
        func loopEdge(_ src: EdgeSrc, _ to: String, _ col: Int) {
            guard let tc = colOf[to] else { return }
            if tc == col { edges.append(Edge(k: "loop", src: src, to: to, col: cols[col].id)); return }
            let kind = cols[col].kind, par = parentOf[cols[col].id] ?? nil
            if kind == "fl" || kind == "fr", par == tc {
                let pid = cols[col].parentId
                var ei = edges.firstIndex { $0.k == "collect" && $0.to == to && $0.parent == pid }
                if ei == nil { edges.append(Edge(k: "collect", to: to, parent: pid, cols: [], srcs: [])); ei = edges.count - 1 }
                var s2 = src; s2.col = cols[col].id
                edges[ei!].srcs!.append(s2)
                if !edges[ei!].cols!.contains(cols[col].id) { edges[ei!].cols!.append(cols[col].id) }
                return
            }
            if kind == "rail", par == tc { edges.append(Edge(k: "rail", src: src, to: to, col: cols[col].id)) }
        }
        func ouvreFourche(_ id: String) -> Bool {
            guard let c = colOf[id] else { return false }
            return (cols[c].kind == "fl" || cols[c].kind == "fr") && cols[c].rows.first?.id == id
        }
        func cible(_ id: String) { if let (c, r) = rowOf[id], !ouvreFourche(id) { cols[c].rows[r].tgt = true } }
        for ci in cols.indices {
            for ri in cols[ci].rows.indices {
                let r = cols[ci].rows[ri]
                if r.k == "dec" {
                    for a in r.alts ?? [] {
                        guard let t = a.tgt else { continue }
                        if a.kind == "out" {
                            if let tc = colOf[t], cols[ci].right, cols[tc].right {
                                edges.append(Edge(k: "exit", src: EdgeSrc(alt: r.id! + "/" + t), to: t)); cible(t)
                            }
                        } else if a.kind == "back" { loopEdge(EdgeSrc(alt: r.id! + "/" + t), t, ci) }
                    }
                }
                if r.k == "pill", let to = r.to {
                    let from: String? = r.from ?? nil
                    if r.kind == "loop" { loopEdge(EdgeSrc(pill: .some(from)), to, ci) }
                    else if r.kind == "out" {
                        if let tc = colOf[to], cols[ci].right, cols[tc].right { edges.append(Edge(k: "exit", src: EdgeSrc(pill: .some(from)), to: to)); cible(to) }
                    } else if r.kind == "cont", cols[ci].kind == "rail", cols[ci].right {
                        let pid = cols[ci].parentId
                        var ei = edges.firstIndex { $0.k == "railMerge" && $0.to == to && $0.parent == pid }
                        if ei == nil {
                            edges.append(Edge(k: "railMerge", to: to, parent: pid, srcs: [])); ei = edges.count - 1
                            if let (c, rr) = rowOf[to] { cols[c].rows[rr].tgt = true }
                        }
                        edges[ei!].srcs!.append(EdgeSrc(pill: .some(from), col: cols[ci].id))
                    }
                }
            }
        }
        // Une fourche dont des branches reviennent en arrière porte un COLLECTEUR dessous.
        for e in edges where e.k == "collect" {
            for c in cols.indices {
                for r in cols[c].rows.indices where cols[c].rows[r].k == "fork" && (cols[c].rows[r].brs ?? []).contains(where: { e.cols!.contains($0.colId) }) {
                    cols[c].rows[r].coll = true
                }
            }
        }
        return TreePlan(cols: cols, edges: edges, order: plan.order, firstOf: firstOf)
    }
}
