import Foundation

// RELECTURE ET COMPARAISON — port de `stepGuardTxt`, `nfGuardTxt`, `stepNote`, `stepShortcut`,
// `reviewNotes`, `reviewOffers` (la relecture de l'éditeur, JAMAIS bloquante, jamais rouge), et de
// `flattenFiche`, `diffFicheLines`, `flattenProto`, `impDiff`, `impDupRel`, `normalizeImport`
// (« Versions » et l'atelier d'import : on voit ce qu'on écrit AVANT de l'écrire).
//
// Le NOMBRE d'une proposition vient de la PHRASE de l'auteur, jamais d'un barème : c'est la
// frontière réglementaire de la PWA (aucune recommandation individualisée), reprise telle quelle.

public enum Review {
    static let rxCumul = JSRegExp(#"\s[·+]\s"#, "g")
    static func cumulCount(_ c: String) -> Int { rxCumul.allMatches(in: Array(c.utf16)).count }

    /// `stepGuardTxt(steps, scope)` : garde-fou TÉLÉGRAPHIQUE d'un bloc (7 étapes au plus, challenge
    /// ≤ 110 car., une action par ligne) ; `blocOnly` = `scope:'bloc'` (seule la remarque de bloc).
    public static func stepGuardTxt(_ steps: [String], blocOnly: Bool = false) -> String {
        let s = Txt.clean(steps)
        var parts: [String] = []
        if s.count > 7 { parts.append("\(s.count) étapes — au-delà de 7, scinder le bloc (lisibilité sous stress)") }
        if blocOnly { return parts.isEmpty ? "" : "△ " + parts.joined(separator: " · ") }
        let long = s.filter { JS.length(Steps.challengeResponse(Steps.text($0)).c) > 110 }.count
        if long != 0 { parts.append("\(long) challenge" + (long > 1 ? "s" : "") + " très long" + (long > 1 ? "s" : "") + " — style télégraphique : une action courte, la valeur en réponse « challenge :: réponse »") }
        let cumul = s.filter { cumulCount(Steps.challengeResponse(Steps.text($0)).c) >= 2 }.count
        if cumul != 0 { parts.append("\(cumul) étape" + (cumul > 1 ? "s" : "") + " cumulant plusieurs actions — une action cochable = une ligne (sinon on coche « à moitié fait »)") }
        return parts.isEmpty ? "" : "△ " + parts.joined(separator: " · ")
    }
    /// `nfGuardTxt(arr)` : le chapeau « Ne pas oublier » — plus de 4 rappels, ou un rappel > 110 car.
    public static func nfGuardTxt(_ arr: [String]) -> String { nfGuard(Txt.clean(arr).count, arr) }
    /// `nfGuardTxt(n)` (forme compatible : un simple nombre).
    public static func nfGuardTxt(count: Double) -> String { nfGuard(count.isNaN ? 0 : Int(exactly: count.rounded(.towardZero)) ?? 0, nil, raw: count) }
    static func nfGuard(_ n: Int, _ arr: [String]?, raw: Double? = nil) -> String {
        var parts: [String] = []
        let big = raw.map { $0 > 4 } ?? (n > 4)
        if big {
            let nTxt = raw.map { JS.numStr($0) } ?? String(n)
            parts.append(nTxt + " rappels — au-delà de 4, plus rien n’est saillant. Un rappel lié à une étape précise est plus sûr en étape ⚠ du bloc concerné, une surveillance dans « À vérifier »")
        }
        if let arr {
            let lg = Txt.clean(arr).filter { JS.length(Txt.stripBold($0)) > 110 }.count
            if lg != 0 { parts.append("\(lg) rappel" + (lg > 1 ? "s" : "") + " très long" + (lg > 1 ? "s" : "") + " — style télégraphique : au-delà de 110 caractères, le chapeau pousse la première action sous le bas de l’écran") }
        }
        return parts.isEmpty ? "" : "△ " + parts.joined(separator: " · ")
    }
    /// `stepNote(st)` : la remarque SOUS la ligne qu'elle vise (édition seulement).
    public static func stepNote(_ st: String) -> String {
        let c = Steps.challengeResponse(Steps.text(st)).c
        if JS.trim(c).isEmpty { return "" }
        if cumulCount(c) >= 2 { return "Plusieurs actions dans une étape cochable — une action = une ligne, sinon on coche « à moitié fait »" }
        if JS.length(c) > 110 { return "Challenge très long (\(JS.length(c)) c.) — style télégraphique : l’action courte, la valeur en réponse « :: »" }
        return ""
    }
    static let rxShortcut = JSRegExp(#"^([!?])\s(.*)$"#, "s")
    /// `stepShortcut(val)` : « ! » / « ? » EN TÊTE de ligne → registre ⚠ / △, préfixe consommé.
    public static func stepShortcut(_ val: String) -> (mark: String, rest: String)? {
        guard let m = rxShortcut.exec(val) else { return nil }
        return (m[1] == "!" ? "⚠ " : "△ ", m[2]!)
    }
    /// Remarque de relecture : où (`at` : 'nf' ou 'b:<bloc>'), sur quoi, quoi.
    public struct Note: Equatable, Sendable { public var at: String; public var cible: String; public var txt: String }
    /// `reviewNotes(f)` : les garde-fous rassemblés (« △ Relecture »).
    public static func reviewNotes(_ f: Fiche) -> [Note] {
        var out: [Note] = []
        let t = nfGuardTxt(Parcours.forgetAll(f))
        if !t.isEmpty { out.append(Note(at: "nf", cible: "Ne pas oublier", txt: t)) }
        for b in f.blocks where b.kind != .decision {
            let g = stepGuardTxt(Parcours.stepsOf(f, b))
            if !g.isEmpty { out.append(Note(at: "b:" + b.id, cible: JS.trim(b.title).isEmpty ? "Bloc d’étapes" : JS.trim(b.title), txt: g)) }
        }
        return out
    }

    // MARK: Propositions (Q1)

    static let rxCycle = JSRegExp(#"\btoutes?\s+les\s+(\d{1,3})\s*(?:min\b|minutes\b)"#, "i")
    static let rxDelai = JSRegExp(#"(?:^|[^\wàâäéèêëîïôöùûüç])(?:à|apr[èe]s)\s+(\d{1,3})\s*(?:min\b|minutes\b)"#, "i")
    static let rxQH = JSRegExp(#"\bq(\d{1,2})\s*h\b"#, "i")
    static let rxRenouv = JSRegExp(#"\b(?:renouvel|r[ée]p[ée]t|nouvelle\s+dose|seconde\s+dose|2e?\s+dose|nouveau\s+choc)"#, "i")
    /// Proposition de la relecture : ajouter un minuteur (`seconds`), un compteur, ou marquer ★ un item.
    public struct Offer: Equatable, Sendable {
        public var id: String
        /// 'interval' · 'counter' · 'memory'
        public var kind: String
        public var seconds: Int?
        public var itemId: String?
        public var cible: String, btn: String, txt: String
    }
    /// `q1Texts(f)` : tous les textes de l'auteur (étapes, questions, listes).
    static func q1Texts(_ f: Fiche) -> [String] {
        var out: [String] = []
        for b in f.blocks {
            out += Parcours.stepsOf(f, b).map(Steps.text)
            if !b.question.isEmpty { out.append(b.question) }
        }
        for k: Parcours.ListKey in [.confirmation, .notForget, .verify, .posology, .differentials] { out += Parcours.listOf(f, k) }
        return out
    }
    /// `reviewOffers(f)` : les objets que le texte décrit — un cycle écrit (« toutes les 3 min »,
    /// « q4h »), un geste qui se répète, une étape vitale non étoilée. RIEN n'est créé d'office ;
    /// `refused` = les refus transitoires de l'auteur (`state.edOffNo`).
    public static func reviewOffers(_ f: Fiche, refused: Set<String> = []) -> [Offer] {
        var out: [Offer] = []
        let txts = q1Texts(f)
        if !f.timers.contains(where: { $0.type == .interval }) {
            var sec = 0, src = ""
            for t in txts {
                if let m = rxCycle.exec(t) ?? rxDelai.exec(t) { sec = Int(m[1]!)! * 60; src = t; break }
                if let q = rxQH.exec(t) { sec = Int(q[1]!)! * 3600; src = t; break }
            }
            if sec > 0 && sec <= 86400 {
                out.append(Offer(id: "tm", kind: "interval", seconds: sec, itemId: nil, cible: "Minuteur", btn: "＋ Minuteur " + Txt.fmtMs(Double(sec) * 1000),
                                 txt: "« " + JS.prefix(src, 64) + " » — un minuteur à cycles s’armerait au premier geste et sonnerait seul."))
            }
        }
        if f.counters.isEmpty && txts.contains(where: { rxRenouv.test($0) }) {
            out.append(Offer(id: "cn", kind: "counter", seconds: nil, itemId: nil, cible: "Compteur", btn: "＋ Compteur",
                             txt: "Votre texte parle de renouveler un geste — un compteur en horodate chaque unité dans le compte rendu. Il naîtra sans nom : c’est à vous de le nommer."))
        }
        let its = f.blocks.flatMap { Pool.blockItems(f, $0) }.filter { !$0.id.isEmpty }
        if !its.contains(where: \.memory),
           let c = its.first(where: { !JS.trim($0.do).isEmpty && ($0.level == 3 || Steps.isCrit($0.do)) }) {
            out.append(Offer(id: "mem:" + c.id, kind: "memory", seconds: nil, itemId: c.id, cible: "Ne pas oublier", btn: "★ Marquer",
                             txt: "« " + JS.prefix(c.do, 64) + " » est une étape vitale — ★ la ferait aussi paraître dans « Ne pas oublier », sans quitter son bloc."))
        }
        return out.filter { !refused.contains($0.id) }
    }

    // MARK: Versions et import

    /// `flattenFiche(f)` : une aide aplatie en lignes « Section · contenu » — le diff de versions
    /// devient une différence d'ensembles.
    public static func flattenFiche(_ f: Fiche?) -> [String] {
        guard let f else { return [] }
        var L: [String] = []
        func add(_ sec: String, _ v: String) { let t = JS.trim(v); if !t.isEmpty { L.append(sec + " · " + t) } }
        add("Titre", f.title); add("Validation", f.validatedAt); add("Contexte", f.local); add("État", f.status == .draft ? "brouillon" : "validée")
        for (k, lbl) in [(Parcours.ListKey.confirmation, "Confirmation"), (.verify, "À vérifier"), (.notForget, "Ne pas oublier"), (.differentials, "Différentiels"), (.posology, "Posologie")] {
            for v in Parcours.listOf(f, k) { add(lbl, v) }
        }
        for v in f.sources { add("Références", v) }
        for b in f.blocks {
            let t = b.title.isEmpty ? (b.kind == .decision ? "Décision" : "Étapes") : b.title
            if b.kind == .decision {
                add("Bloc « " + t + " »", b.question)
                for o in b.options { add("Bloc « " + t + " » — option", o.label) }
            } else { for s in Parcours.stepsOf(f, b) { add("Bloc « " + t + " »", s) } }
        }
        for t in f.timers { add("Minuteur", t.label + (t.type == .interval ? " (\(t.seconds) s)" : " (chrono)")) }
        for c in f.counters { add("Compteur", c.label) }
        return L
    }
    /// `diffFicheLines(cur, old)` : ce que RESTAURER `old` retirerait / rétablirait.
    public static func diffFicheLines(_ cur: Fiche?, _ old: Fiche?) -> (removed: [String], added: [String]) {
        let a = flattenFiche(cur), b = flattenFiche(old)
        let sa = Set(a), sb = Set(b)
        return (a.filter { !sb.contains($0) }, b.filter { !sa.contains($0) })
    }
    /// `flattenProto(p)` : une référence aplatie (ses lignes SONT ses unités).
    public static func flattenProto(_ p: Reference?) -> [String] {
        guard let p else { return [] }
        var L: [String] = []
        func add(_ sec: String, _ v: String) { let t = JS.trim(v); if !t.isEmpty { L.append(sec + " · " + t) } }
        add("Titre", p.title); add("Validation", p.validatedAt); add("État", p.status == .draft ? "brouillon" : "validée")
        for l in JS.split(p.body, "\n") { add("Corps", l) }
        for v in p.sources { add("Références", v) }
        return L
    }
    /// `impDiff(mien, entrant, ref)` : `plus` = ce que remplacer AJOUTERAIT, `moins` = ce qu'il SUPPRIMERAIT.
    public static func impDiff(mine: [String], incoming: [String]) -> (plus: [String], moins: [String]) {
        let sa = Set(mine), sb = Set(incoming)
        return (incoming.filter { !sa.contains($0) }, mine.filter { !sb.contains($0) })
    }
    public static func impDiff(_ mine: Fiche?, _ incoming: Fiche?) -> (plus: [String], moins: [String]) { impDiff(mine: flattenFiche(mine), incoming: flattenFiche(incoming)) }
    public static func impDiff(_ mine: Reference?, _ incoming: Reference?) -> (plus: [String], moins: [String]) { impDiff(mine: flattenProto(mine), incoming: flattenProto(incoming)) }

    /// `impDupRel(entrant, mien)` : 'neuf' (le fichier est plus récent), 'vieux', 'egal', ou '' si
    /// l'un des horodatages manque (lu AVANT migrate, qui en poserait un).
    public static func impDupRel(_ incoming: Double?, _ mine: Double?) -> String {
        guard let e = incoming, e.isFinite, let m = mine, m.isFinite else { return "" }
        return e == m ? "egal" : (e > m ? "neuf" : "vieux")
    }
    /// Libellés de `impDupRel` (`IMP_REL`).
    public static let impRel = ["neuf": "le fichier est plus récent", "vieux": "votre version est plus récente", "egal": "même version"]

    /// `normalizeImport(imp)` : `aids[]` (v4) → `fiches` ; les références rangées dans `fiches`
    /// (`kind:'reference'`) partent dans `protocols` — sinon `migrate` en ferait des aides VIDES.
    public static func normalizeImport(_ imp: JSON?) -> JSON {
        guard let imp, var out = imp.object else {
            if let a = imp?.array { return normalizeArray(a) }
            return ["fiches": [], "categories": []]
        }
        if out["fiches"]?.array == nil, let aids = out["aids"]?.array { out["fiches"] = .array(aids) }
        out["aids"] = nil
        guard let fs = out["fiches"]?.array else { return .object(out) }
        var refs: [JSON] = [], aides: [JSON] = []
        for x in fs {
            if (x.object != nil || x.array != nil) && x["kind"] == "reference" { refs.append(x) } else { aides.append(x) }
        }
        out["fiches"] = .array(aides)
        if !refs.isEmpty { out["protocols"] = .array((out["protocols"]?.array ?? []) + refs) }
        return .object(out)
    }
    /// Un tableau est un objet pour la PWA (`Object.assign({}, [..])` → clés « 0 », « 1 »…).
    static func normalizeArray(_ a: [JSON]) -> JSON {
        var o: [String: JSON] = [:]
        for (i, v) in a.enumerated() { o[String(i)] = v }
        return normalizeImport(.object(o))
    }
}
