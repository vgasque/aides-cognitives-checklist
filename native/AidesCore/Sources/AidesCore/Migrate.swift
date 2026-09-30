import Foundation

// POINT D'ENTRÉE UNIQUE DE SÉCURITÉ/COMPAT (règle 5) — port ligne à ligne de `migrate()`,
// `migrateProtocol()`, `sanitizeEntityCommon()`, `v4SanItem()`, `sanitizeCats()`, `sanitizeNotes()`.
// Toute donnée entrante (chargement, import, ZIP, duplication, pull cloud, partage) passe ICI.
// Les tests `MigrateOracleTests` comparent la sortie à celle de la PWA exécutée dans Chromium.

public enum Steps {
    /// `STEP_CRIT_RX = /^\s*(?:⚠️?|!)\s*/`
    static func critPrefixEnd(_ sc: String.UnicodeScalarView) -> String.UnicodeScalarView.Index? {
        var i = sc.startIndex
        while i < sc.endIndex, JS.isSpace(sc[i]) { i = sc.index(after: i) }
        guard i < sc.endIndex else { return nil }
        if sc[i] == "\u{26A0}" {
            i = sc.index(after: i)
            if i < sc.endIndex, sc[i] == "\u{FE0F}" { i = sc.index(after: i) }
        } else if sc[i] == "!" {
            i = sc.index(after: i)
        } else { return nil }
        while i < sc.endIndex, JS.isSpace(sc[i]) { i = sc.index(after: i) }
        return i
    }
    /// `STEP_VIG_RX = /^\s*△\s*/`
    static func vigPrefixEnd(_ sc: String.UnicodeScalarView) -> String.UnicodeScalarView.Index? {
        var i = sc.startIndex
        while i < sc.endIndex, JS.isSpace(sc[i]) { i = sc.index(after: i) }
        guard i < sc.endIndex, sc[i] == "\u{25B3}" else { return nil }
        i = sc.index(after: i)
        while i < sc.endIndex, JS.isSpace(sc[i]) { i = sc.index(after: i) }
        return i
    }
    public static func isCrit(_ s: String) -> Bool { critPrefixEnd(s.unicodeScalars) != nil }
    public static func isVigil(_ s: String) -> Bool { !isCrit(s) && vigPrefixEnd(s.unicodeScalars) != nil }
    /// `stepText` : retire le préfixe « ⚠ »/« ! » PUIS le préfixe « △ ».
    public static func text(_ s: String) -> String {
        var sc = s.unicodeScalars
        if let e = critPrefixEnd(sc) { sc = String.UnicodeScalarView(sc[e...]) }
        if let e = vigPrefixEnd(sc) { sc = String.UnicodeScalarView(sc[e...]) }
        return String(sc)
    }
    /// `stepCR` : challenge « :: » réponse (première occurrence).
    public static func challengeResponse(_ s: String) -> (c: String, r: String?) {
        guard let r = s.range(of: "::") else { return (JS.trim(s), nil) }
        let c = JS.trim(String(s[..<r.lowerBound])), a = JS.trim(String(s[r.upperBound...]))
        if !c.isEmpty && !a.isEmpty { return (c, a) }
        return (c.isEmpty ? a : c, nil)
    }
    /// `v4Level` : 3 ⚠, 2 △, 1 sinon.
    public static func level(_ s: String) -> Int { isCrit(s) ? 3 : (isVigil(s) ? 2 : 1) }

    /// `v4MakeItem(id, role, raw, memory)` : lit le préfixe de registre et le « :: ».
    public static func makeItem(id: String, role: Role, raw: String, memory: Bool = false) -> Item {
        let cr = challengeResponse(text(raw))
        return Item(id: id, role: role, do: cr.c, expect: cr.r ?? "", level: level(raw), memory: memory, dual: false, note: "")
    }
}

public enum Sanitize {
    /// Tailles d'affichage d'image admises.
    public static let mdScales = [25, 33, 50, 66, 75, 100]
    static func dim(_ v: JSON?) -> Int { Int(JS.clamp(JS.roundedOrZero(v), 0, 20000)) }
    static func scale(_ v: JSON?) -> Int {
        let n = JS.round(JS.number(v))
        return mdScales.contains(where: { Double($0) == n }) ? Int(n) : 100
    }
    static func short(_ x: JSON?) -> String? {
        let v = JS.trim(Guard.sstr(x?["short"], 24))
        return v.isEmpty ? nil : v
    }
    static func finite(_ v: JSON?) -> Double? {
        if case .number(let n)? = v, n.isFinite { return n }
        return nil
    }

    /// Pièce jointe : l'id n'est JAMAIS régénéré (un id inventé ne pointerait sur aucun binaire).
    public static func attachment(_ a: JSON?) -> Attachment? {
        guard let a, a.object != nil || a.array != nil else { return nil }
        guard case .string(let id)? = a["id"], Guard.isSafeId(id) else { return nil }
        var name = Guard.safeFileName(a["name"])
        if name.isEmpty { name = "document.pdf" }
        if !name.lowercased().hasSuffix(".pdf") { name = JS.prefix(name, 146) + ".pdf" }
        let size = Int(JS.clamp(JS.roundedOrZero(a["size"]), 0, Double(Guard.maxPdfBytes)))
        return Attachment(id: id, name: name, size: size)
    }

    // MARK: sanitizeEntityCommon

    struct Common {
        var id = "", title = "", validatedAt = "", category = "", order = 0.0
        var images: [ImageRef] = [], docs: [Attachment] = [], status = Status.validated
        var code = "", discriminant = "", links: [String] = [], updatedBy = ""
        var updatedAt = 0.0, deletedAt: Double? = nil, ownerId: String? = nil, library: String? = nil
    }
    static let commonKeys: Set<String> = ["id", "title", "validatedAt", "category", "order", "images", "docs", "status",
                                          "code", "discriminant", "links", "updatedBy", "updatedAt", "deletedAt", "ownerId", "library", "dirty"]

    static func common(_ x: [String: JSON], idPrefix: String, imgMax: Int) -> Common {
        var c = Common()
        c.id = Guard.safeId(x["id"], idPrefix)
        c.title = Guard.sstr(x["title"], 300)
        let pv = Validation.parse(x["validatedAt"])
        c.validatedAt = pv.isEmpty ? Guard.sstr(x["validatedAt"], 16) : pv
        c.category = Guard.safeRef(x["category"])
        c.order = finite(x["order"]) ?? JS.now()
        var budget = 24_000_000
        c.images = (x["images"]?.array ?? []).prefix(imgMax).compactMap { im -> ImageRef? in
            let img = ImageRef(id: Guard.safeId(im["id"], "i"), data: Guard.safeImg(im["data"]) ?? "",
                               w: dim(im["w"]), h: dim(im["h"]), caption: Guard.sstr(im["caption"], 300), scale: scale(im["scale"]))
            guard !img.data.isEmpty else { return nil }
            budget -= JS.length(img.data)
            return budget >= 0 ? img : nil
        }
        c.docs = (x["docs"]?.array ?? []).prefix(Guard.maxAttPerEntity).compactMap { attachment($0) }
        let st = x["status"]?.string
        c.status = st == "draft" ? .draft : (st == "review" ? .review : .validated)
        c.code = Guard.sstr(x["code"], 40)
        c.discriminant = Guard.sstr(x["discriminant"], 60)
        c.links = (x["links"]?.array ?? []).prefix(20).compactMap { v -> String? in
            if case .string(let s) = v, Guard.isSafeId(s) { return s }
            return nil
        }
        c.updatedBy = Guard.sstr(x["updatedBy"], 160)
        c.updatedAt = finite(x["updatedAt"]) ?? c.order
        c.deletedAt = finite(x["deletedAt"])
        c.ownerId = Guard.safeMetaId(x["ownerId"])
        c.library = Guard.safeMetaId(x["library"])
        return c
    }

    // MARK: v4SanItem

    public static func item(_ x: JSON?) -> Item {
        let o = x ?? .object([:])
        let lvRaw = JS.round(JS.number(o["level"]))
        let lv = Int(JS.clamp((lvRaw.isNaN || lvRaw == 0) ? 1 : lvRaw, 1, 3))
        let roleStr = o["role"]?.string ?? ""
        var it = Item(id: Guard.safeId(o["id"]), role: Role(rawValue: roleStr) ?? .do,
                      do: Guard.sstr(o["do"], 500), expect: Guard.sstr(o["expect"], 200), level: lv,
                      memory: o["memory"]?.truthy ?? false, dual: o["dual"]?.truthy ?? false, note: Guard.sstr(o["note"], 500))
        let s = Guard.safeRef(o["starts"]), c = Guard.safeRef(o["counts"])
        if !s.isEmpty { it.starts = s } else if !c.isEmpty { it.counts = c }
        if let fr = o["from"], fr.truthy {
            let fc = Guard.safeRef(fr["counter"])
            let n = JS.round(JS.number(fr["n"]))
            if !fc.isEmpty, n >= 1 { it.from = ItemFrom(counter: fc, n: Int(min(99, n))) }
        }
        if let r = o["repeat"]?.string, let rp = Repeat(rawValue: r) { it.repeat = rp }
        let rv = Guard.safeRef(o["review"]), q = Guard.safeRef(o["poso"])
        if !rv.isEmpty { it.review = rv }
        if !q.isEmpty { it.poso = q }
        return it
    }

    // MARK: migrate

    static let renames: [(String, String)] = [("localInfo", "local"), ("related", "links"), ("attachments", "docs"),
                                              ("complications", "excursions"), ("references", "sources"),
                                              ("validation", "validatedAt"), ("libraryId", "library")]
    static let ficheKnown: Set<String> = commonKeys.union(["v", "kind", "local", "sources", "items", "excursions", "blocks",
                                                            "start", "timers", "counters", "steps",
                                                            "confirmation", "verify", "notForget", "differentials", "posology"])
    static let blockKnownDo: Set<String> = ["id", "kind", "type", "title", "phase", "image", "imageW", "imageH", "timer",
                                            "milestones", "items", "steps", "next", "nextLbl", "options", "question"]
    static let blockKnownDecision: Set<String> = ["id", "kind", "type", "title", "phase", "image", "imageW", "imageH", "timer",
                                                  "milestones", "question", "options", "steps", "next"]

    /// Port de `migrate(f)` : compatibilité ET assainissement. Ne lève jamais.
    public static func fiche(_ input: JSON?) -> Fiche {
        var f: [String: JSON] = input?.object ?? [:]
        if input?.array != nil { f = [:] }
        for (a, b) in renames {
            if let v = f[a], f[b] == nil { f[b] = v }
            f[a] = nil
        }
        let c = common(f, idPrefix: "f", imgMax: 200)
        var out = Fiche(id: c.id)
        apply(c, to: &out)
        out.local = Guard.sstr(f["local"], 4000)
        out.sources = Guard.sarr(f["sources"], 500)

        // LE POOL D'ITEMS
        var pool: [Item] = []
        if let raw = f["items"]?.array, !raw.isEmpty {
            for x in raw { pool.append(item(x)) }
        } else {
            let lists: [(String, Role, Bool)] = [("confirmation", .entry, false), ("notForget", .do, true), ("verify", .watch, false),
                                                 ("posology", .dose, false), ("differentials", .ddx, false)]
            for (k, role, mem) in lists {
                for x in (f[k]?.array ?? []).prefix(500) {
                    if x.object != nil || x.array != nil {
                        let t = JS.trim(Guard.sstr(x["text"]?.truthy == true ? x["text"] : x["do"], 4000))
                        if t.isEmpty { continue }
                        let sid: String
                        if case .string(let s)? = x["id"], Guard.isSafeId(s) { sid = s } else { sid = Guard.uid() }
                        var it = Steps.makeItem(id: sid, role: role, raw: t, memory: mem)
                        it.note = Guard.sstr(x["note"], 500)
                        pool.append(it)
                        continue
                    }
                    let t = JS.trim(Guard.sstr(x, 4000))
                    if !t.isEmpty { pool.append(Steps.makeItem(id: Guard.uid("i"), role: role, raw: t, memory: mem)) }
                }
            }
        }

        // COMPLICATIONS « à tout moment »
        out.excursions = (f["excursions"]?.array ?? []).prefix(8).compactMap { cx -> Excursion? in
            guard cx.object != nil || cx.array != nil else { return nil }
            var target = ""
            if case .string(let s)? = cx["target"], Guard.isSafeId(s) { target = s }
            let e = Excursion(label: Guard.sstr(cx["label"], 120), target: target, short: short(cx))
            return (!e.label.isEmpty && !e.target.isEmpty) ? e : nil
        }

        // BLOCS
        var rawBlocks: [JSON]
        var start: JSON? = f["start"]
        if let arr = f["blocks"]?.array {
            rawBlocks = Array(arr.prefix(400)).filter { $0.object != nil || $0.array != nil }
        } else {
            let bid = Guard.uid("b")
            let t = out.title.isEmpty ? "Prise en charge" : out.title
            rawBlocks = [.object(["id": .string(bid), "kind": "do", "title": .string(JS.prefix(t, 300)), "items": [], "image": .null, "next": .null])]
            start = .string(bid)
        }
        var idMap: [String: String] = [:]
        var used = Set<String>()
        var newIds: [String] = []
        for b in rawBlocks {
            var nid = Guard.safeId(b["id"], "b")
            while used.contains(nid) { nid = Guard.uid("b") }
            used.insert(nid)
            let key = (b["id"] == nil || b["id"]!.isNull) ? "" : b["id"]!.jsString
            idMap[key] = nid
            newIds.append(nid)
        }
        func mapId(_ x: JSON?) -> String? {
            let key = (x == nil || x!.isNull) ? "" : x!.jsString
            return idMap[key]
        }
        var knownIds = Set(pool.map(\.id))
        for it in f["items"]?.array ?? [] { if let i = it["id"], i.truthy { knownIds.insert(i.jsString) } }

        var blocks: [Block] = []
        for (bi, braw) in rawBlocks.enumerated() {
            let bo = braw.object ?? [:]
            var kindStr: String
            if let k = bo["kind"] { kindStr = k.string ?? "\u{0}" } else { kindStr = (bo["type"]?.string == "decision") ? "decision" : "do" }
            if bo["kind"] != nil, bo["kind"]!.string == nil { kindStr = "\u{0}" }
            var b = Block(id: newIds[bi])
            b.title = Guard.sstr(bo["title"], 300)
            b.phase = Guard.sstr(bo["phase"], 40)
            b.image = Guard.safeImg(bo["image"])
            b.imageW = dim(bo["imageW"]); b.imageH = dim(bo["imageH"])
            let tm = Guard.safeRef(bo["timer"]); b.timer = tm.isEmpty ? nil : tm
            if kindStr == "decision" {
                b.kind = .decision
                b.question = Guard.sstr(bo["question"], 1000)
                b.options = (bo["options"]?.array ?? []).prefix(40).map { o in
                    DecisionOption(label: Guard.sstr(o["label"], 300), target: mapId(o["target"]))
                }
                for (k, v) in bo where !blockKnownDecision.contains(k) { b.extra[k] = v }
            } else {
                b.kind = kindStr == "review" ? .review : .do
                var ids: [String] = []
                for x in bo["items"]?.array ?? [] {
                    if x.object != nil || x.array != nil {
                        let it = item(x); pool.append(it); ids.append(it.id); continue
                    }
                    let t = x.truthy ? x.jsString : ""
                    if knownIds.contains(t) { ids.append(t); continue }
                    if JS.trim(t).isEmpty { continue }
                    let it = Steps.makeItem(id: Guard.uid("i"), role: .do, raw: t)
                    pool.append(it); knownIds.insert(it.id); ids.append(it.id)
                }
                b.items = ids
                if b.kind == .review {
                    b.timer = nil
                } else {
                    b.next = mapId(bo["next"])
                    b.nextLbl = Guard.sstr(bo["nextLbl"], 120)
                }
                for (k, v) in bo where !blockKnownDo.contains(k) { b.extra[k] = v }
            }
            blocks.append(b)
        }
        out.start = mapId(start) ?? blocks.first?.id
        out.items = pool

        func uniq(_ arr: [JSON], _ pfx: String) -> [String] {
            var u = Set<String>()
            return arr.map { x in
                var n = Guard.safeId(x["id"], pfx)
                while u.contains(n) { n = Guard.uid(pfx) }
                u.insert(n); return n
            }
        }
        let tl = Array((f["timers"]?.array ?? []).prefix(40))
        let tids = uniq(tl, "t")
        out.timers = tl.enumerated().map { i, t in
            TimerDef(id: tids[i], label: Guard.sstr(t["label"], 120), type: t["type"]?.string == "interval" ? .interval : .stopwatch,
                     seconds: Int(JS.clamp(JS.roundedOrZero(t["seconds"]), 0, 86400)), autoloop: t["autoloop"]?.truthy ?? false,
                     onDue: Guard.sstr(t["onDue"], 120), short: short(t))
        }
        let cl = Array((f["counters"]?.array ?? []).prefix(40))
        let cids = uniq(cl, "n")
        out.counters = cl.enumerated().map { i, c in
            let stepR = JS.roundedOrZero(c["step"])
            return CounterDef(id: cids[i], label: Guard.sstr(c["label"], 120), step: Int(JS.clamp(stepR == 0 ? 1 : stepR, 1, 9999)),
                              start: Int(JS.clamp(JS.roundedOrZero(c["start"]), 0, 1e9)), timerId: Guard.safeRef(c["timerId"]), short: short(c))
        }

        // JALONS, puis résolution des liens (minuteur de bloc, starts/counts/from)
        let cnIds = Set(out.counters.map(\.id)), exT = Set(out.excursions.map(\.target)), tmIds = Set(out.timers.map(\.id))
        for i in blocks.indices {
            let raw = rawBlocks[i]
            let ms = blocks[i].kind == .review ? [] : (raw["milestones"]?.array ?? [])
            blocks[i].milestones = ms.prefix(3).compactMap { j -> Milestone? in
                guard j.object != nil || j.array != nil else { return nil }
                let at: Milestone.At = j["at"]?.string == "count" ? .count : .pass
                let n = JS.round(JS.number(j["n"]))
                guard n >= 1 else { return nil }
                var counter = ""
                if at == .count, case .string(let s)? = j["counter"], cnIds.contains(s) { counter = s }
                if at == .count && counter.isEmpty { return nil }
                let text = Guard.sstr(j["text"], 140)
                if text.isEmpty { return nil }
                var go = ""
                if case .string(let s)? = j["go"], exT.contains(s) { go = s }
                return Milestone(at: at, n: Int(min(99, n)), counter: counter, text: text, go: go)
            }
            if let t = blocks[i].timer, !tmIds.contains(t) { blocks[i].timer = nil }
        }
        for i in out.items.indices {
            if let s = out.items[i].starts, !tmIds.contains(s) { out.items[i].starts = nil }
            if let c = out.items[i].counts, !cnIds.contains(c) { out.items[i].counts = nil }
            if out.items[i].starts != nil { out.items[i].counts = nil }
            if let fr = out.items[i].from, !cnIds.contains(fr.counter) { out.items[i].from = nil }
        }
        out.blocks = blocks
        // A396/A397 : renvois résolus ; l'étape-revue prend le titre de sa revue.
        var rv: [String: Block] = [:]
        for b in blocks where b.kind == .review { rv[b.id] = b }
        let doseIds = Set(Pool.roleItems(out, .dose).map(\.id))
        for i in out.items.indices {
            if let r = out.items[i].review {
                if let b = rv[r] { out.items[i].do = JS.prefix(b.title, 500); out.items[i].expect = "" }
                else { out.items[i].review = nil }
            }
            if let q = out.items[i].poso, !doseIds.contains(q) { out.items[i].poso = nil }
        }
        for (k, v) in f where !ficheKnown.contains(k) { out.extra[k] = v }
        return out
    }

    static func apply<E: Entity>(_ c: Common, to e: inout E) {
        e.id = c.id; e.title = c.title; e.validatedAt = c.validatedAt; e.category = c.category; e.order = c.order
        e.images = c.images; e.docs = c.docs; e.status = c.status; e.code = c.code; e.discriminant = c.discriminant
        e.links = c.links; e.updatedBy = c.updatedBy; e.updatedAt = c.updatedAt; e.deletedAt = c.deletedAt
        e.ownerId = c.ownerId; e.library = c.library
    }

    public static let mdMaxChars = 20000

    /// Port de `migrateProtocol(p)`.
    public static func reference(_ input: JSON?) -> Reference {
        let p: [String: JSON] = input?.object ?? [:]
        let c = common(p, idPrefix: "p", imgMax: 60)
        var out = Reference(id: c.id)
        apply(c, to: &out)
        out.body = Guard.sstr(p["body"], mdMaxChars)
        out.sources = Guard.sarr(p["sources"], 500)
        for (k, v) in p where !commonKeys.contains(k) && k != "body" && k != "sources" { out.extra[k] = v }
        return out
    }

    /// Port de `sanitizeCats`.
    public static func categories(_ v: JSON?) -> [Category] {
        (v?.array ?? []).prefix(400).map { c in
            Category(id: Guard.safeId(c["id"], "c"), name: Guard.sstr(c["name"], 120), color: Guard.safeColor(c["color"]),
                     library: Guard.safeMetaId(c["library"]))
        }
    }

    /// Port de `sanitizeNotes`.
    public static func notes(_ v: JSON?) -> [String: Note] {
        var out: [String: Note] = [:]
        guard let o = v?.object else { return out }
        for k in o.keys.sorted().prefix(2000) where Guard.matchesSafeIdPattern(k) && !Guard.badKeys.contains(k) {
            guard let n = o[k], n.object != nil else { continue }
            out[k] = Note(t: Guard.sstr(n["t"], 10000), at: finite(n["at"]) ?? 0, dirty: n["dirty"] == .bool(true))
        }
        return out
    }
}

// MARK: - Lecture du pool

public enum Pool {
    /// `bItems(b)` : les items d'un bloc, RÉSOLUS (un id pendant est ignoré).
    public static func blockItems(_ f: Fiche, _ b: Block) -> [Item] {
        var by: [String: Item] = [:]
        for it in f.items { by[it.id] = it }
        return b.items.compactMap { by[$0] }
    }
    /// `roleItems(f, role)` : items du pool de ce rôle NON référencés par un bloc.
    public static func roleItems(_ f: Fiche, _ role: Role) -> [Item] {
        var taken = Set<String>()
        for b in f.blocks { for id in b.items { taken.insert(id) } }
        return f.items.filter { $0.role == role && !taken.contains($0.id) }
    }
    /// `forgetPool` : le chapeau « Ne pas oublier » — items `do` étoilés, dans l'ordre du pool.
    public static func forget(_ f: Fiche) -> [(item: Item, source: String?, blockId: String?)] {
        var src: [String: (String, String)] = [:]
        for (bi, b) in f.blocks.enumerated() {
            for id in b.items { src[id] = (b.title.isEmpty ? "Bloc \(bi + 1)" : b.title, b.id) }
        }
        return f.items.filter { $0.role == .do && $0.memory }.map { ($0, src[$0.id]?.0, src[$0.id]?.1) }
    }
    /// `listOf(f, key)` pour les listes de portée fiche.
    public static func list(_ f: Fiche, _ role: Role) -> [Item] {
        role == .do ? roleItems(f, .do).filter(\.memory) : roleItems(f, role)
    }
    /// Phase héritée (`phaseOf`).
    public static func phase(_ f: Fiche, _ blockId: String) -> String {
        var cur = ""
        for b in f.blocks {
            let p = JS.trim(b.phase)
            if !p.isEmpty { cur = p }
            if b.id == blockId { return cur }
        }
        return ""
    }
    public static let phaseCore = ["Immédiate", "2ᵉ intention", "Surveillance", "Vérification", "Orientation"]
}
