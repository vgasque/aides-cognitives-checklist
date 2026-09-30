import Foundation

// PERTINENCE DES REPÈRES POSOLOGIQUES — port de `posoTokens`, `posoName`, `posoScore`,
// `posoRank`, `posoSplit`, `posoParts` (section « PERTINENCE DES REPÈRES POSOLOGIQUES »).
//
// RÈGLE DE SÛRETÉ ABSOLUE, reprise telle quelle : ce classement RÉORDONNE, il ne FILTRE JAMAIS.
// Un faux positif coûte un rang, un faux négatif un défilement — jamais une dose manquante ; un
// repère signalé (⚠ ou △) n'est jamais replié. Le natif ne doit donc rien « améliorer » ici : la
// même liste doit sortir dans le même ordre sur les deux clients, au bloc près.

public enum Posology {
    /// `POSO_SYN` : chaque variante de voie ou de forme → un jeton CANONIQUE.
    static let syn: [String: String] = [
        "im": "im", "intramusculaire": "im", "intramusculaires": "im",
        "iv": "iv", "ivl": "iv", "ivd": "iv", "intraveineux": "iv", "intraveineuse": "iv", "intraveineuses": "iv",
        "ivse": "ivse", "pse": "ivse",
        "sc": "sc", "souscutane": "sc", "souscutanee": "sc",
        "io": "io", "intraosseux": "io", "intraosseuse": "io",
        "po": "po", "oral": "po", "orale": "po",
        "intranasal": "in", "intranasale": "in",
        "sl": "sl", "sublingual": "sl", "sublinguale": "sl",
        "inhale": "inh", "inhalee": "inh", "aerosol": "inh", "nebulisation": "inh", "nebulise": "inh",
    ]
    /// `POSO_PHRASE` : locutions en deux mots, remplacées avant la découpe (ordre significatif).
    static let phrases: [(JSRegExp, String)] = [
        (JSRegExp(#"\bper os\b"#, "g"), "po"), (JSRegExp(#"\bvoie orale\b"#, "g"), "po"),
        (JSRegExp(#"\bseringue electrique\b"#, "g"), "ivse"), (JSRegExp(#"\bpousse seringue\b"#, "g"), "ivse"),
        (JSRegExp(#"\bintra musculaire\b"#, "g"), "im"), (JSRegExp(#"\bintra veineuse?\b"#, "g"), "iv"),
        (JSRegExp(#"\bsous cutanee?\b"#, "g"), "sc"), (JSRegExp(#"\bintra osseuse?\b"#, "g"), "io"),
        (JSRegExp(#"\bintra nasale?\b"#, "g"), "in"),
    ]
    /// `POSO_STOP` : mots de grammaire et unités (présents partout, ils rapprocheraient tout de tout).
    static let stop: Set<String> = ["de", "du", "des", "la", "le", "les", "un", "une", "au", "aux", "en", "et", "ou", "par",
                                    "pour", "sur", "dans", "avec", "si", "puis", "selon", "apres", "avant", "mg", "ml", "g", "kg", "mcg", "ug", "ui",
                                    "min", "mn", "h", "dose", "doses", "voie", "voies", "max", "maxi", "soit", "fois"]
    static let rxApos = JSRegExp("[’']", "g"), rxDash = JSRegExp("-", "g"), rxNon = JSRegExp("[^a-z0-9]+", "g")

    /// `posoNorm(s)` : `txNorm`, apostrophes → espace, traits d'union recollés, le reste → espace.
    static func norm(_ s: String) -> String {
        JS.trim(rxNon.replace(rxDash.replace(rxApos.replace(Txt.txNorm(s), " "), ""), " "))
    }
    /// `posoTokens(s)` : jetons canoniques, sans mots vides.
    public static func tokens(_ s: String) -> [String] {
        var t = norm(s)
        for (rx, to) in phrases { t = rx.replace(t, to) }
        return JS.split(t, " ").filter { !$0.isEmpty }.map { syn[$0] ?? $0 }.filter { !stop.contains($0) }
    }
    /// `posoName(s)` : le nom d'un repère = ce qui précède le premier « : ».
    public static func name(_ s: String) -> String {
        let t = Steps.text(s)
        let i = JS.indexOf(t, " : ")
        return JS.trim(Txt.stripBold(i > 0 ? JS.slice(t, 0, i) : t))
    }
    /// `posoScore(name, hay)` : proximité entre le NOM d'un repère et le texte du bloc courant.
    /// Troncature à 4 caractères au moins (« adre » ⊂ « adrenaline ») ; le produit en tête pèse plus.
    public static func score(_ name: String, _ hay: String) -> Int {
        let A = tokens(name), B = tokens(hay)
        if A.isEmpty || B.isEmpty { return 0 }
        let set = Set(B)
        var sc = 0
        for (i, t) in A.enumerated() {
            var hit = 0
            if set.contains(t) { hit = 3 }
            else {
                let tl = JS.length(t)
                for u in B where tl >= 4 && JS.length(u) >= 4 && (u.utf16.starts(with: t.utf16) || t.utf16.starts(with: u.utf16)) { hit = 2; break }
            }
            if hit != 0 { sc += hit + (i == 0 ? 1 : 0) }
        }
        return sc
    }
    /// Un repère classé : `s` la chaîne, `i` son rang d'origine (dans la liste nettoyée), `crit` =
    /// SIGNALÉ (⚠ ou △ — jamais repliable), `score` sa proximité.
    public struct Ranked: Equatable, Sendable { public var s: String; public var i: Int; public var crit: Bool; public var score: Int }
    /// `posoRank(items, hay)` : TOUS les items (nettoyés), signalés d'abord, puis score, puis ordre d'origine.
    public static func rank(_ items: [String], _ hay: String) -> [Ranked] {
        Txt.clean(items).enumerated().map { Ranked(s: $0.element, i: $0.offset, crit: Steps.isCrit($0.element) || Steps.isVigil($0.element),
                                                   score: score(name($0.element), hay)) }
            .sorted { a, b in
                if a.crit != b.crit { return a.crit }
                if a.score != b.score { return a.score > b.score }
                return a.i < b.i
            }
    }
    /// `posoSplit(items, hay, cap)` : visible d'emblée (`head` : signalés + rapprochés, sinon les deux
    /// premiers) et REPLIÉ (`rest`, dont le nombre est annoncé — un pli muet serait un filtre déguisé).
    public static func split(_ items: [String], _ hay: String, cap: Int = 3) -> (head: [Ranked], rest: [Ranked]) {
        let r = rank(items, hay)
        if r.count <= (cap == 0 ? 3 : cap) { return (r, []) }
        var head = r.filter { $0.crit || $0.score > 0 }
        if head.isEmpty { head = Array(r.prefix(2)) }
        let keep = Set(head.map(\.i))
        return (head, r.filter { !keep.contains($0.i) })
    }
    /// `posoParts(x)` : UN point de lecture d'un repère — nom (facultatif), corps, signalement.
    public static func parts(_ x: String) -> (name: String, body: String, flag: Bool) {
        let t = Steps.text(x)
        let i = JS.indexOf(t, " : ")
        return (i > 0 ? JS.trim(Txt.stripBold(JS.slice(t, 0, i))) : "", i > 0 ? JS.slice(t, i + 3) : t, Steps.isCrit(x) || Steps.isVigil(x))
    }
}
