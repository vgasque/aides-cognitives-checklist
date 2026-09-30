import Foundation

// LECTURES PURES D'UNE SESSION VIVANTE — port de `tmIsDue`, `tmLiveOrder`, `TM_SOON_MS`, `monPick`,
// `monBandData`, `wtTimerModel`, `wtCountModel`, `evDeltas`, `liveWhereText`, `endSessOpenTxt`, et du
// vocabulaire des repères (`sanitizeTags`, `tagAll`, `tagSuggest`, `tagLabel`, `tagRank`).
//
// Aucune de ces fonctions n'ÉVALUE le soin (§ 2 du dossier de conformité) : elles disent un état,
// un écart brut, un compte — jamais un score, une cible ou une « conformité ». Le natif garde la
// même frontière : mêmes entrées, mêmes mots.
//
// L'état d'un minuteur est passé en valeur (`TimerRun`) : le moteur de session (Engine/) en tient
// la source et la convertit (TODO fusion : aligner sur le type du moteur).

public enum Live {
    /// État vivant d'un minuteur (champs de `Runtime.timers[id]` que lisent ces fonctions).
    public struct TimerRun: Equatable, Sendable {
        public var id: String
        public var label: String
        public var type: TimerKind
        public var seconds: Int
        public var autoloop: Bool
        public var onDue: String
        public var elapsedMs: Double
        public var running: Bool
        public var lastStart: Double
        public var cycles: Int
        public var ack: Bool
        /// Minuteur ajouté pendant la session (hors fiche).
        public var adhoc: Bool
        public init(id: String, label: String = "", type: TimerKind, seconds: Int = 0, autoloop: Bool = false, onDue: String = "",
                    elapsedMs: Double = 0, running: Bool = false, lastStart: Double = 0, cycles: Int = 0, ack: Bool = false, adhoc: Bool = false) {
            self.id = id; self.label = label; self.type = type; self.seconds = seconds; self.autoloop = autoloop; self.onDue = onDue
            self.elapsedMs = elapsedMs; self.running = running; self.lastStart = lastStart; self.cycles = cycles; self.ack = ack; self.adhoc = adhoc
        }
        var per: Double { Double(seconds) * 1000 }
    }

    /// `TM_SOON_MS` : seuil d'AFFICHAGE de l'imminence (20 s) — un arbitrage, pas une valeur clinique.
    public static let soonMs: Double = 20000

    /// `tmIsDue(t)` : minuteur d'intervalle arrêté au bout de sa période (prédicat UNIQUE).
    public static func tmIsDue(_ t: TimerRun?) -> Bool {
        guard let t else { return false }
        return t.type == .interval && !t.running && t.per > 0 && t.elapsedMs >= t.per
    }
    /// `timerDue(t)` (carte) : échu, et SANS reprise seule (`autoloop`).
    public static func timerDue(_ t: TimerRun) -> Bool { t.type == .interval && !t.autoloop && !t.running && t.per > 0 && t.elapsedMs >= t.per }
    /// `timerStarted(t)`.
    public static func timerStarted(_ t: TimerRun) -> Bool { t.elapsedMs > 0 || t.cycles > 0 }
    /// `timerDisplay(t, now)` : valeur affichée (chrono : écoulé ; cycle : restant) et proportion
    /// RESTANTE de la barre (100 tant que rien n'a tourné).
    public static func timerDisplay(_ t: TimerRun, now: Double) -> (val: String, bw: Double) {
        let run = t.running ? now - t.lastStart : 0
        if t.type == .stopwatch { return (Txt.fmtMs(t.elapsedMs + run), 0) }
        let per = t.per, within = t.elapsedMs + run
        return (Txt.fmtMs(max(0, per - within)), per != 0 ? max(0, 100 - min(100, within / per * 100)) : 100)
    }
    /// `tmName(t)`.
    public static func tmName(_ t: TimerRun) -> String { Parcours.tmName(label: t.label, interval: t.type == .interval) }

    /// `tmLiveOrder(list, now)` : ORDRE VIVANT — alarme non acquittée, puis ce qui tourne par temps
    /// restant croissant, puis le reste dans l'ordre de l'auteur (tri stable).
    public static func tmLiveOrder(_ list: [TimerRun], now: Double) -> [TimerRun] {
        func rk(_ t: TimerRun) -> Double {
            if tmIsDue(t) && !t.ack { return -1 }
            if t.type == .interval && t.running { return max(0, t.per - (t.elapsedMs + (now - t.lastStart))) }
            return .infinity
        }
        return list.enumerated().map { ($0.offset, $0.element, rk($0.element)) }
            .sorted { $0.2 != $1.2 ? $0.2 < $1.2 : $0.0 < $1.0 }.map(\.1)
    }

    /// `monPick(timers, now)` : ce que le MONITEUR montre — un échu l'emporte toujours, sinon le plus
    /// proche de son échéance parmi ceux qui tournent (à égalité, l'ordre de la fiche).
    public static func monPick(_ timers: [TimerRun], now: Double) -> TimerRun? {
        let arr = timers.filter { $0.type == .interval }
        if arr.isEmpty { return nil }
        func reste(_ t: TimerRun) -> Double { max(0, t.per - (t.elapsedMs + (t.running ? now - t.lastStart : 0))) }
        if let e = arr.first(where: timerDue) { return e }
        let actifs = arr.filter(\.running)
        let pool = actifs.isEmpty ? arr : actifs
        return pool.enumerated().sorted { reste($0.element) != reste($1.element) ? reste($0.element) < reste($1.element) : $0.offset < $1.offset }.first?.element
    }

    /// `MON_PAST_MS`, `MON_FUT_MS`, `MON_NOW` : la bande du moniteur, −2 min … +5 min.
    public static let monPastMs: Double = 120_000, monFutMs: Double = 300_000
    public static let monNow = monPastMs / (monPastMs + monFutMs)
    /// `MON_REP_NOM` : les trois derniers repères portent leur nom et ne fusionnent jamais.
    public static let monRepNom = 3
    public struct BandPast: Equatable, Sendable { public var x: Double; public var n: Int; public var lab: String; public var t: Double }
    public struct BandDated: Equatable, Sendable { public var lab: String; public var x: Double; public var t: Double; public var ghosts: [Double] }
    public struct BandUndated: Equatable, Sendable {
        public var lab: String, val: String
        /// 'chrono' · 'due' · 'pause'
        public var kind: String
    }
    /// Repère du journal vu par le moniteur.
    public struct EventMark: Equatable, Sendable {
        public var t: Double; public var voided: Bool
        public init(t: Double, voided: Bool = false) { self.t = t; self.voided = voided }
    }
    /// `monBandData(timers, events, now, labels)` — TROIS registres de trait : passé ARRIVÉ (points),
    /// avenir DATÉ (minuteur qui tourne), tours suivants PROJETÉS (tirets, sans libellé). Ce qui n'a
    /// pas d'heure n'a pas de position (pause, échu, chrono) ; un jalon COMPTÉ n'y entre jamais.
    public static func monBandData(_ timers: [TimerRun], events: [EventMark], now: Double, labels: [String]? = nil)
        -> (past: [BandPast], dated: [BandDated], sans: [BandUndated]) {
        func pos(_ t: Double) -> Double { (t - now + monPastMs) / (monPastMs + monFutMs) }
        var dated: [BandDated] = [], sans: [BandUndated] = []
        for t in timers {
            if t.type != .interval {
                if t.running { sans.append(BandUndated(lab: t.label.isEmpty ? "Chronomètre" : t.label, val: "en cours", kind: "chrono")) }
                continue
            }
            let per = t.per, lab = t.label.isEmpty ? "Minuteur" : t.label
            if tmIsDue(t) { sans.append(BandUndated(lab: lab, val: "échu", kind: "due")); continue }
            if !t.running {
                if per != 0 { sans.append(BandUndated(lab: lab, val: Txt.fmtMs(max(0, per - t.elapsedMs)), kind: "pause")) }
                continue
            }
            let fin = now + max(0, per - (t.elapsedMs + (now - t.lastStart)))
            if pos(fin) > 1 { continue }
            var d = BandDated(lab: lab, x: pos(fin), t: fin, ghosts: [])
            if t.autoloop && per > 0 {
                for k in 1...3 { let g = pos(fin + Double(k) * per); if g > 1 { break }; d.ghosts.append(g) }
            }
            dated.append(d)
        }
        dated = dated.enumerated().sorted { $0.element.t != $1.element.t ? $0.element.t < $1.element.t : $0.offset < $1.offset }.map(\.element)
        var fen: [(t: Double, lab: String)] = []
        for (i, e) in events.enumerated() where !e.voided && now - e.t <= monPastMs {
            fen.append((e.t, (labels != nil && i < labels!.count) ? labels![i] : ""))
        }
        var past: [BandPast] = []
        for (i, e) in fen.enumerated() {
            let x = pos(e.t), nom = i >= fen.count - monRepNom
            if !nom, let p = past.last, p.lab.isEmpty, x - p.x < 0.045 { past[past.count - 1].n += 1; continue }
            past.append(BandPast(x: x, n: 1, lab: nom ? (e.lab.isEmpty ? "Repère" : e.lab) : "", t: e.t))
        }
        return (past, dated, sans)
    }

    // MARK: Légendes des objets liés (A377)

    /// `WT_RING_C` : circonférence de l'anneau (r 4,5).
    public static let ringC = 28.27
    /// `WT_MV_MS` : durée d'un mouvement de légende.
    public static let moveMs: Double = 360
    /// Modèle d'une légende : `cls` ('', 'run', 'up', 'due'), glyphe `g` ('ring', 'watch', 'count'),
    /// décalage d'anneau `off`, étiquette `e`, valeur `v` (ou `va` → `vb` pour un compte qui monte),
    /// nom `n`, phases d'animation `arm`/`gr`, `fresh`.
    public struct Witness: Equatable, Sendable {
        public var cls: String
        public var g: String
        public var off: Double? = nil
        public var e: String? = nil
        public var v: String? = nil
        public var va: String? = nil
        public var vb: String? = nil
        public var fresh: Bool? = nil
        public var n: String
        public var arm: Double? = nil
        public var gr: Double? = nil
    }
    /// `wtTimerModel(t, now, {hint, gr, exited, lat})`.
    public static func wtTimerModel(_ t: TimerRun?, now: Double, hint: String? = nil, gr: Double? = nil, exited: Bool = false, lat: String? = nil) -> Witness? {
        guard let t else { return nil }
        let iv = t.type == .interval, name = tmName(t), d = timerDisplay(t, now: now)
        if iv && timerDue(t) {
            let od = JS.trim(t.onDue)
            return Witness(cls: "due", g: "ring", off: 0, e: "Échu", v: "", n: "· " + (od.isEmpty ? name : od))
        }
        let h = (hint?.isEmpty ?? true) ? name : hint!
        if t.running {
            var m = iv ? Witness(cls: "run", g: "ring", off: Double(JS.toFixed(ringC * (1 - d.bw / 100), 2))!, v: d.val, n: "· " + h)
                : Witness(cls: "up", g: "watch", v: "↑ " + d.val, n: "· " + h)
            let age = now - t.lastStart
            if t.elapsedMs == 0 && age >= 0 && age < moveMs { m.arm = age }
            if let gr { m.gr = gr }
            return m
        }
        if timerStarted(t) { return Witness(cls: "", g: "watch", v: d.val, n: "· " + name + " · " + (exited ? "arrêté, sortie de la boucle" : "arrêté")) }
        return Witness(cls: "", g: "watch", v: iv ? Txt.fmtMs(t.per) : "↑", n: ((lat?.isEmpty ?? true) ? "à la coche" : lat!) + " · " + name)
    }
    /// Repère d'un compteur : `t` = heure, `hasRef` = le repère porte sa référence, `v` = la valeur
    /// posée (`ev.ref.v`, nil si absente — lue 0 comme en JS).
    public struct CountMark: Equatable, Sendable {
        public var t: Double; public var hasRef: Bool; public var v: Double?
        public init(t: Double, hasRef: Bool = true, v: Double?) { self.t = t; self.hasRef = hasRef; self.v = v }
    }
    /// `wtCountModel(c, cur, done, ev, last, now)` : `ev` = le repère de CETTE coche, `last` = le
    /// dernier repère vivant du compteur.
    public static func wtCountModel(_ c: CounterDef?, cur: Double, done: Bool, ev: CountMark?, last: CountMark?, now: Double) -> Witness? {
        guard let c else { return nil }
        let nm = Parcours.tmLabelParts(c.label).name, name = nm.isEmpty ? "Compteur" : nm
        let step = Double(c.step == 0 ? 1 : c.step)
        func ago(_ t: Double) -> String { now - t < 10000 ? "à l’instant" : "il y a " + Txt.fmtMs(now - t) }
        if done, let ev, ev.hasRef {
            let vv = (ev.v == nil || ev.v!.isNaN) ? 0 : ev.v!
            return Witness(cls: "", g: "count", va: JS.numStr(max(0, vv - step)), vb: JS.numStr(vv), fresh: now - ev.t < 1800, n: "· " + name + " · " + ago(ev.t))
        }
        if done { return Witness(cls: "", g: "count", v: JS.numStr(cur), n: "· " + name) }
        return Witness(cls: "", g: "count", v: JS.numStr(cur) + " → " + JS.numStr(cur + step), n: "à la coche · " + name + (last != nil ? " · dernier " + ago(last!.t) : ""))
    }

    // MARK: Journal

    /// `evDeltas(evs)` : l'écart BRUT entre deux gestes du MÊME objet (null sinon) — un fait, jamais
    /// une évaluation ; un repère annulé ne compte pas et ne coupe pas la série.
    public static func evDeltas(_ evs: [JSON]) -> [Double?] {
        var prev: [String: Double] = [:]
        return evs.map { e -> Double? in
            guard let ref = e["ref"], let ty = ref["type"], ty.truthy, let id = ref["id"], id.truthy else { return nil }
            if e["voidAt"]?.truthy ?? false { return nil }
            // `safeId` régénère un id invalide : la clé devient unique, la série ne se rejoint jamais.
            let a = ty.jsString, b = id.jsString
            guard Guard.isSafeId(a), Guard.isSafeId(b) else { return nil }
            let k = a + ":" + b
            let t = JS.number(e["t"])
            let d: Double? = (prev[k].map { $0 != 0 && !$0.isNaN } ?? false) ? t - prev[k]! : nil
            prev[k] = t
            return d
        }
    }

    /// `liveWhereText(R)` : « n · titre du bloc — dernier repère 14h32 » (rien → '').
    public static func liveWhereText(_ f: Fiche?, nav: [String], events: [JSON], tz: TimeZone = .current) -> String {
        guard let f else { return "" }
        var p: [String] = []
        if let id = nav.last, !id.isEmpty {
            let n = (Parcours.flowPlan(f).order.firstIndex(of: id) ?? -1) + 1
            if let b = f.blocks.first(where: { $0.id == id }) {
                let t = JS.trim(b.title)
                p.append((n != 0 ? "\(n) · " : "") + (t.isEmpty ? (b.kind == .decision ? "Décision" : "Étapes") : t))
            }
        }
        let ev = events.filter { $0["t"]?.truthy ?? false }
        if let last = ev.last, let t = last["t"], JS.number(t) != 0 {
            p.append("dernier repère " + Txt.frHM(JS.number(t), tz: tz).replacingOccurrences(of: ":", with: "h"))
        }
        return p.joined(separator: " — ")
    }

    /// Ligne de « ce qui reste ouvert » : `crit` (étapes vitales) ou `g` (glyphe).
    public struct OpenLine: Equatable, Sendable { public var crit: Bool; public var g: String?; public var txt: String }
    /// `endSessOpenTxt(R)` : des FAITS comptés sur les blocs VISITÉS (hors chemin n'est pas « oublié »).
    public static func endSessOpenTxt(_ f: Fiche?, nav: [String], navSeq: [Int], checked: Set<String>, timers: [TimerRun]) -> [OpenLine] {
        guard let f else { return [] }
        var out: [OpenLine] = []
        var seen = Set<String>(), crit = 0, ou = ""
        for (i, id) in nav.enumerated() where !id.isEmpty {
            let s = i < navSeq.count ? navSeq[i] : 0
            let seq = s != 0 ? s : i + 1
            guard let b = f.blocks.first(where: { $0.id == id }), b.kind != .decision else { continue }
            let cle = "\(seq):\(id)"
            if seen.contains(cle) { continue }
            seen.insert(cle)
            for (j, st) in Parcours.stepsOf(f, b).enumerated() where Steps.isCrit(st) && !checked.contains("\(seq):\(id):\(j)") {
                crit += 1
                if ou.isEmpty { ou = JS.trim(b.title) }
            }
        }
        if crit != 0 { out.append(OpenLine(crit: true, g: nil, txt: "\(crit)" + (crit > 1 ? " étapes vitales non cochées" : " étape vitale non cochée") + (ou.isEmpty ? "" : " — " + ou))) }
        let run = timers.filter(\.running).count
        if run != 0 { out.append(OpenLine(crit: false, g: "⏱", txt: "\(run)" + (run > 1 ? " minuteurs en cours" : " minuteur en cours"))) }
        return out
    }

    // MARK: Vocabulaire des repères (étiquettes)

    /// `TAG_MAX`, `TAG_ALIAS_MAX`.
    public static let tagMax = 40, tagAliasMax = 8
    /// Étiquette personnelle : clé, libellé, alias.
    public struct Tag: Equatable, Sendable { public var k: String; public var l: String; public var a: [String] }
    static let rxSlug = JSRegExp("[^a-z0-9]+", "g")
    /// `sanitizeTags(v)` : 40 au plus, libellé 40 car., clé `safeId` (ou dérivée du libellé), alias
    /// 8 × 24 car., dédoublonnées par clé. ⚠ Une clé INVALIDE est régénérée (`uid('t')`), comme en JS.
    public static func sanitizeTags(_ v: JSON?) -> [Tag] {
        var out: [Tag] = [], seen = Set<String>()
        for t in (v?.array ?? []).prefix(tagMax) {
            guard t.object != nil || t.array != nil else { continue }
            let lv: JSON? = (t["l"] != nil && !t["l"]!.isNull) ? t["l"] : t["label"]
            let l = JS.trim(Guard.sstr(lv, 40))
            if l.isEmpty { continue }
            let kv: JSON = (t["k"]?.truthy ?? false) ? t["k"]! : .string("t-" + JS.prefix(rxSlug.replace(Txt.txNorm(l), "-"), 24))
            let k = Guard.safeId(kv, "t")
            if seen.contains(k) { continue }
            seen.insert(k)
            let av: JSON? = (t["a"] != nil && !t["a"]!.isNull) ? t["a"] : t["alias"]
            let a = Guard.sarr(av, tagAliasMax).map { JS.trim(Guard.sstr(.string($0), 24)) }.filter { !$0.isEmpty }
            out.append(Tag(k: k, l: l, a: a))
        }
        return out
    }
    /// Objets ajoutés pendant la session (`rtExtra()` / `extraTimers` d'une archive).
    public struct Extra: Sendable {
        public var timers: [(id: String, label: String, interval: Bool, adhoc: Bool)]
        public var counters: [(id: String, label: String, adhoc: Bool)]
        public init(timers: [(id: String, label: String, interval: Bool, adhoc: Bool)] = [], counters: [(id: String, label: String, adhoc: Bool)] = []) {
            self.timers = timers; self.counters = counters
        }
    }
    /// Proposition de repère : `ref` (la RÉFÉRENCE qui voyage), libellé, source (fiche/noyau/perso), alias.
    public struct TagOption: Equatable, Sendable { public var ref: JSON; public var label: String; public var src: String; public var alias: [String] }
    static func sources(_ f: Fiche?, _ ex: Extra?) -> (timers: [(id: String, label: String, interval: Bool, adhoc: Bool)], counters: [(id: String, label: String, adhoc: Bool)]) {
        let ft = (f?.timers ?? []).map { (id: $0.id, label: $0.label, interval: $0.type == .interval, adhoc: false) }
        let fc = (f?.counters ?? []).map { (id: $0.id, label: $0.label, adhoc: false) }
        return (ft + (ex?.timers ?? []), fc + (ex?.counters ?? []))
    }
    /// `tagAll(f, tags, ex)` : le vocabulaire disponible ICI — objets de la fiche (et de la session),
    /// étapes, repères posologiques, noyau universel, étiquettes personnelles. Aucun filtrage.
    public static func tagAll(_ f: Fiche?, tags: JSON?, extra: Extra? = nil) -> [TagOption] {
        var out: [TagOption] = [], vus = Set<String>()
        let S = sources(f, extra)
        func add(_ ref: JSON, _ label: String, _ src: String, _ alias: [String] = []) {
            let l = JS.trim(JS.prefix(label, 80))
            if l.isEmpty { return }
            let ty = ref["type"]!.string!
            var key: String
            if let id = ref["id"]?.string, !id.isEmpty { key = id }
            else if let k = ref["k"]?.string, !k.isEmpty { key = k }
            else { key = (ref["b"]?.jsString ?? "undefined") + "/" + (ref["i"]?.jsString ?? "undefined") }
            let cle = ty + ":" + key
            if vus.contains(cle) { return }
            vus.insert(cle)
            out.append(TagOption(ref: ref, label: l, src: src, alias: alias))
        }
        for (i, t) in S.timers.enumerated() {
            let lt = JS.trim(t.label)
            add(["type": "timer", "id": .string(t.id)], lt.isEmpty ? (t.interval ? "Minuteur" : "Chronomètre") + (t.adhoc ? " \(i + 1)" : "") : lt, "fiche")
        }
        for (i, c) in S.counters.enumerated() {
            let lc = JS.trim(c.label)
            add(["type": "counter", "id": .string(c.id)], lc.isEmpty ? "Compteur" + (c.adhoc ? " \(i + 1)" : "") : lc, "fiche")
        }
        if let f {
            for b in f.blocks {
                for (i, st) in Txt.clean(Parcours.stepsOf(f, b)).enumerated() {
                    add(["type": "step", "b": .string(b.id), "i": .number(Double(i))], Posology.name(Steps.text(st)), "fiche")
                }
            }
            for (i, pp) in Txt.clean(Parcours.listOf(f, .posology)).enumerated() { add(["type": "poso", "i": .number(Double(i))], Posology.name(pp), "fiche") }
        }
        for c in SessionSanitize.tagCore { add(["type": "core", "k": .string(c.k)], c.l, "noyau") }
        for t in sanitizeTags(tags) { add(["type": "tag", "k": .string(t.k)], t.l, "perso", t.a) }
        return out
    }
    /// `tagSuggest(f, tags, bid, n, garantis)` : proposer SANS qu'on ait tapé — bloc courant, puis ses
    /// minuteurs/compteurs, autres étapes, posologie, étiquettes, noyau ; les types `garantis`
    /// occupent les premières places. `extra` = `rtExtra()` (objets ad hoc de la session VIVE).
    public static func tagSuggest(_ f: Fiche?, tags: JSON?, blockId: String?, n: Int = 5, garantis: [String] = [], extra: Extra? = nil) -> [TagOption] {
        let all = tagAll(f, tags: tags, extra: extra)
        func rang(_ t: TagOption) -> Int {
            let ty = t.ref["type"]?.string ?? ""
            if ty == "step", let bid = blockId, !bid.isEmpty, t.ref["b"]?.string == bid { return 0 }
            if ty == "timer" || ty == "counter" { return 1 }
            if ty == "step" { return 2 }
            if ty == "poso" { return 3 }
            if ty == "tag" { return 4 }
            return 5
        }
        let mx = max(1, n == 0 ? 5 : n)
        func est(_ t: TagOption) -> Bool { garantis.contains(t.ref["type"]?.string ?? "") }
        let tete = Array(all.filter(est).prefix(mx))
        let reste = all.enumerated().filter { !est($0.element) }.map { (t: $0.element, r: rang($0.element), i: $0.offset) }
            .sorted { $0.r != $1.r ? $0.r < $1.r : $0.i < $1.i }.map(\.t)
        return Array((tete + reste).prefix(mx))
    }
    static let rxTagCut = JSRegExp(#"\s*[—–(,;].*$"#)
    /// `tagShort(l)` : libellé court d'une étape (avant « :: », avant la première ponctuation forte,
    /// trois mots, 26 caractères).
    public static func tagShort(_ l: String) -> String {
        var t = JS.trim(rxTagCut.replace(JS.split(l, "::")[0], ""))
        let w = JSRegExp(#"\s+"#).split(t)
        if w.count > 3 { t = w.prefix(3).joined(separator: " ") }
        if JS.length(t) > 26 {
            var u = Array(JS.prefix(t, 25).unicodeScalars)
            while let last = u.last, JS.isSpace(last) { u.removeLast() }
            return String(String.UnicodeScalarView(u)) + "…"
        }
        return t
    }
    /// `tagLabel(ref, f, tags, ex)` : la référence d'un repère résolue en libellé — nil = introuvable
    /// (une RÉPONSE, pas un échec : le journal écrit alors « Action n »).
    public static func tagLabel(_ ref: JSON?, _ f: Fiche?, tags: JSON?, extra: Extra? = nil) -> String? {
        guard let r = ref, r.object != nil || r.array != nil else { return nil }
        let S = sources(f, extra)
        let ty = r["type"]?.string
        switch ty {
        case "counter":
            let c = S.counters.first { r["id"]?.string == $0.id }
            let base = (c?.label.isEmpty == false) ? c!.label : "Compteur"
            guard let v = r["v"], !v.isNull else { return base }
            let x = JS.number(v)
            return base + " n° " + JS.numStr(x.isNaN || x == 0 ? 0 : x)
        case "timer":
            let t = S.timers.first { r["id"]?.string == $0.id }
            return (t?.label.isEmpty == false) ? t!.label : nil
        case "step":
            guard let f, let b = f.blocks.first(where: { r["b"]?.string == $0.id }) else { return nil }
            let i = JS.number(r["i"]), st = Parcours.stepsOf(f, b)
            guard i == i.rounded(.towardZero), i >= 0, Int(exactly: i).map({ $0 < st.count }) ?? false else { return nil }
            let s = st[Int(i)]
            return s.isEmpty ? nil : tagShort(Posology.name(s))
        case "poso":
            guard let f else { return nil }
            let i = JS.number(r["i"]), L = Parcours.listOf(f, .posology)
            guard i == i.rounded(.towardZero), i >= 0, Int(exactly: i).map({ $0 < L.count }) ?? false else { return nil }
            let pp = L[Int(i)]
            return pp.isEmpty ? nil : Posology.name(pp)
        case "core": return SessionSanitize.tagCore.first { r["k"]?.string == $0.k }?.l
        case "tag": return sanitizeTags(tags).first { r["k"]?.string == $0.k }?.l
        default: return nil
        }
    }
    /// `tkLabels(events, f, tags, ex)` : le libellé de chaque repère du journal — renommage manuel
    /// souverain, sinon la référence résolue, sinon « Action n » (rang parmi les repères génériques).
    /// Source unique du journal, du compte rendu et des noms du moniteur (`monBandData`).
    public static func tkLabels(_ events: [JSON], _ f: Fiche?, tags: JSON?, extra: Extra? = nil) -> [String] {
        var n = 0
        return events.map { e in
            if let l = e["label"]?.string, !l.isEmpty { return l }
            if let l = tagLabel(e["ref"], f, tags: tags, extra: extra), !l.isEmpty { return l }
            n += 1
            return "Action \(n)"
        }
    }
    /// Proposition classée (`tagRank`).
    public struct RankedTag: Equatable, Sendable { public var ref: JSON; public var label: String; public var src: String; public var i: Int; public var score: Int }
    /// `tagRank(q, items)` : on RÉORDONNE, on ne filtre jamais ; les alias comptent comme le libellé.
    public static func tagRank(_ q: String, _ items: [TagOption]) -> [RankedTag] {
        items.enumerated().map { i, it in
            var sc = Posology.score(it.label, q)
            for a in it.alias { let s2 = Posology.score(a, q); if s2 > sc { sc = s2 } }
            return RankedTag(ref: it.ref, label: it.label, src: it.src, i: i, score: sc)
        }.sorted { $0.score != $1.score ? $0.score > $1.score : $0.i < $1.i }
    }
}
