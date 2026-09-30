import Foundation

// ANNEXES DE LA SYNCHRO — documents de catégories (épingles, frecency, préférences), notes
// personnelles, documents PDF (bucket Storage `attachments`), versions sauvegardées.

extension SyncEngine {
    // MARK: Stockage « meta »

    /// Catégories locales (`meta.categories`), assainies.
    public func loadCategories() -> [Category] { Sanitize.categories(store.meta["categories"]) }
    func saveCategories(_ cats: [Category]) { store.meta["categories"] = .array(cats.map(\.json)) }

    /// Notes locales (`meta.notes`) — TOUTES (sans le plafond d'import de `sanitizeNotes` : une
    /// relecture bornée suivie d'une réécriture perdrait des notes).
    public func loadNotes() -> [String: Note] {
        var out: [String: Note] = [:]
        for (k, n) in store.meta["notes"]?.object ?? [:] where Guard.matchesSafeIdPattern(k) && !Guard.badKeys.contains(k) {
            guard n.object != nil else { continue }
            out[k] = Note(t: Guard.sstr(n["t"], 10000), at: jsNumberOrZero(n["at"]), dirty: n["dirty"]?.truthy ?? false)
        }
        return out
    }
    func saveNotes(_ notes: [String: Note]) {
        store.meta["notes"] = .object(notes.mapValues { n in
            var o: [String: JSON] = ["t": .string(n.t), "at": .number(n.at)]
            if n.dirty { o["dirty"] = true }
            return .object(o)
        })
    }

    // MARK: Versions sauvegardées

    /// Sauvegarde locale de la version écrasée par un pull (bouton « Versions ») — 5 par fiche au
    /// plus, les plus anciennes élaguées.
    func putBackup(of localRec: JSON) {
        guard let fid = LocalRecord.id(localRec) else { return }
        let bid = Guard.uid("bk")
        try? store.backups.put(bid, ["bid": .string(bid), "ficheId": .string(fid), "at": .number(now()), "data": localRec])
        let mine = store.backups.all().filter { $0["ficheId"]?.string == fid }
            .sorted { jsNumberOrZero($0["at"]) < jsNumberOrZero($1["at"]) }
        if mine.count > 5 {
            for b in mine.prefix(mine.count - 5) { if let x = b["bid"]?.string { store.backups.delete(x) } }
        }
    }
    /// Versions conservées d'une fiche, de la plus récente à la plus ancienne.
    public func backups(ficheId: String) -> [JSON] {
        store.backups.all().filter { $0["ficheId"]?.string == ficheId }.sorted { jsNumberOrZero($0["at"]) > jsNumberOrZero($1["at"]) }
    }

    // MARK: Catégories, épingles, frecency, préférences (`_syncCats`)

    /// UN document par périmètre : Perso (`personal:<uid>`) et chaque bibliothèque (`lib:<id>`).
    /// Le document distant PLUS RÉCENT que l'horodatage local gagne EN BLOC — même sur une
    /// modification locale non poussée (règle du web, spec D Q8). Sinon, s'il est à pousser (ou
    /// absent du serveur) et qu'on peut l'éditer, il est poussé. Toute erreur est avalée : le
    /// document reste « à pousser » et repart à la synchro suivante.
    func syncCategories(uid: String) async {
        struct Scope { let key: String; let scopeKey: String; let library: String?; let canPush: Bool }
        let scopes = [Scope(key: "", scopeKey: "personal:" + uid, library: nil, canPush: true)]
            + profile.libraries.map { Scope(key: $0.id, scopeKey: "lib:" + $0.id, library: $0.id, canPush: $0.role.canEdit) }
        var changed = false
        for s in scopes {
            let localTs = prefs.catsUpdated(s.key)
            let dirty = prefs.catsDirty(s.key)
            let remote: JSON?
            do {
                remote = try await auth.rest("GET", "/rest/v1/category_sets?select=*&scope_key=eq." + enc(s.scopeKey))?.array?.first
            } catch { continue }
            if let remote, JSDate.parseOrZero(remote["updated_at"]) > localTs {
                // Le document distant REMPLACE les catégories de ce périmètre (bibliothèque forcée).
                let incoming = Sanitize.categories(remote["data"]?["categories"]).map { c -> Category in
                    var c = c; c.library = s.library; return c
                }
                let cats = loadCategories().filter { $0.library != s.library } + incoming
                saveCategories(cats)
                if s.library == nil, let data = remote["data"] { applyPersonalDocument(data) }
                prefs.set(SpaceKeys.catsUpdated(s.key), .number(JSDate.parseOrZero(remote["updated_at"])))
                prefs.remove(SpaceKeys.catsDirty(s.key))
                changed = true
                continue
            }
            if s.canPush && (dirty || remote == nil) {
                let ts = localTs != 0 ? localTs : now()
                var data: [String: JSON] = ["categories": .array(loadCategories().filter { $0.library == s.library }.map { c in
                    ["id": .string(c.id), "name": .string(c.name), "color": .string(c.color), "library": s.library.map { .string($0) } ?? .null]
                })]
                if s.library == nil {
                    data["pins"] = .array(prefs.pins.map { .string($0) })
                    data["usage"] = usageJSON(sanitizeUsage(usageJSON(prefs.usage)))
                    data["prefs"] = personalPrefsJSON()
                }
                let row: JSON = ["scope_key": .string(s.scopeKey), "owner": .string(uid), "library_id": s.library.map { .string($0) } ?? .null,
                                 "data": .object(data), "updated_at": .string(JSDate.iso(ts))]
                do {
                    try await auth.rest("POST", "/rest/v1/category_sets", body: [row], extra: ["Prefer": "resolution=merge-duplicates,return=minimal"])
                    // Marqueur retiré SEULEMENT si rien n'a changé pendant la requête (le web le
                    // retirait toujours : une modification faite pendant l'envoi ne serait pas repartie).
                    if prefs.catsUpdated(s.key) == localTs { prefs.remove(SpaceKeys.catsDirty(s.key)) }
                } catch {}
            }
        }
        if changed { acc.categories = true; flush() }
    }

    /// `data.prefs` du document personnel, tel que le web l'écrit.
    public func personalPrefsJSON() -> JSON {
        let p = prefs
        return ["theme": .string(p.theme), "zoom": .number(Double(p.zoom)), "accent": .string(p.accent),
                "readMode": .string(p.readMode), "tags": .array(p.tags.map(\.json)), "syncSessions": .bool(p.syncSessions),
                "homeGroup": .string(p.homeGroup)]
    }

    /// Document PERSONNEL reçu : épingles REMPLACÉES, frecency FUSIONNÉE (chaque appareil garde
    /// ses comptes), préférences écrites SANS marquer le document à pousser (sinon écho : on
    /// renverrait au serveur ce qu'on vient d'en recevoir).
    func applyPersonalDocument(_ data: JSON) {
        let p = prefs
        if let pins = data["pins"], pins.array != nil {
            let np = sanitizePins(pins)
            if np != p.pins { acc.pins = true }
            p.pins = np
        }
        if let u = data["usage"], u.truthy {
            p.usage = mergeUsage(p.usage, sanitizeUsage(u))
        }
        guard let pr = data["prefs"], pr.object != nil else { return }
        var ch = RemotePrefsChange()
        if let th = pr["theme"]?.string, PrefValues.themes.contains(th), th != p.theme { p.theme = th; ch.theme = th }
        let zn = JS.number(pr["zoom"])
        if zn.isFinite, let z = PrefValues.zoomSteps.first(where: { Double($0) == zn }), z != p.zoom { p.zoom = z; ch.zoom = z }
        if let ac = pr["accent"]?.string, PrefValues.accents.contains(ac), ac != p.accent { p.accent = ac; ch.accent = ac }
        if let rm = pr["readMode"]?.string, PrefValues.readModes.contains(rm) {
            if rm != p.readMode { ch.readMode = rm }
            p.readMode = rm
        }
        if let tags = pr["tags"], tags.array != nil {
            let nt = sanitizeTags(tags)
            if nt != p.tags { ch.tags = true }
            p.tags = nt
        }
        if case .bool(let on)? = pr["syncSessions"] {
            if on != p.syncSessions { ch.syncSessions = on }
            writeSessionSync(on)
        }
        if let hg = pr["homeGroup"]?.string, PrefValues.homeGroups.contains(hg) {
            if hg != p.homeGroup { ch.homeGroup = hg }
            p.homeGroup = hg
        }
        if !ch.isEmpty { host?.syncPrefsDidChange(ch) }
    }

    // MARK: Notes (`_syncNotes`)

    /// PULL complet (volume minuscule) puis PUSH des notes « dirty ». Une note locale en attente
    /// GAGNE toujours ; le marqueur n'est effacé que sur les entrées inchangées depuis l'envoi.
    /// ÉCART : la lecture est PAGINÉE (spec D, Q4) — le web lisait tout d'un coup.
    func syncNotes(uid: String) async throws {
        var rows: [JSON]? = []
        do {
            var after = ""
            for _ in 0..<50 {
                let page = try await auth.rest("GET", "/rest/v1/aid_notes?select=fiche_id,note,updated_at&order=fiche_id.asc" + (after.isEmpty ? "" : "&fiche_id=gt." + enc(after)) + "&limit=1000")?.array ?? []
                rows! += page
                if page.count < 1000 { break }
                after = page.last?["fiche_id"]?.jsString ?? ""
            }
        } catch { rows = nil }
        var changedIds = Set<String>()
        if let rows {
            var notes = loadNotes()
            for r in rows {
                let id = (r["fiche_id"].map { $0.truthy ? $0.jsString : "" }) ?? ""
                guard Guard.matchesSafeIdPattern(id), !Guard.badKeys.contains(id) else { continue }
                let rts = JSDate.parseOrZero(r["updated_at"])
                let loc = notes[id]
                if loc == nil || (!loc!.dirty && rts > loc!.at) {
                    notes[id] = Note(t: Guard.sstr(r["note"], 10000), at: rts)
                    changedIds.insert(id)
                }
            }
            if !changedIds.isEmpty { saveNotes(notes) }
        }
        let snap = loadNotes().filter { $0.value.dirty }.map { (id: $0.key, at: $0.value.at, t: $0.value.t) }.sorted { $0.id < $1.id }
        if !snap.isEmpty {
            let up: [JSON] = snap.map { s in
                ["user_id": .string(uid), "fiche_id": .string(s.id), "note": .string(s.t),
                 "updated_at": .string(JSDate.iso(s.at != 0 ? s.at : now()))]
            }
            try await auth.rest("POST", "/rest/v1/aid_notes", body: .array(up), extra: ["Prefer": "resolution=merge-duplicates,return=minimal"])
            var fresh = loadNotes()
            for s in snap { if var n = fresh[s.id], n.dirty, n.at == s.at { n.dirty = false; fresh[s.id] = n } }
            saveNotes(fresh)
        }
        if !changedIds.isEmpty { acc.notes.formUnion(changedIds); flush() }
    }

    // MARK: Documents PDF (`_syncAttachments`)

    /// Chemin attendu et droit de pousser, par document référencé (fiches ET protocoles, pierres
    /// tombales comprises ; le périmètre d'une entité VIVANTE prime sur celui d'une tombe).
    func attachmentPlan(uid: String) -> (order: [String], paths: [String: String], editable: Set<String>) {
        var order: [String] = []
        var paths: [String: String] = [:]
        var editable = Set<String>()
        for r in store.fiches.all() + store.protocols.all() {
            for a in r["docs"]?.array ?? [] {
                guard let aid = a["id"], aid.truthy else { continue }
                let id = aid.jsString
                guard Guard.isSafeId(id) else { continue }
                if paths[id] == nil { order.append(id) }
                if paths[id] == nil || !LocalRecord.isDeleted(r) {
                    paths[id] = attStoragePath(library: LocalRecord.library(r), ownerUid: uid, attId: id)
                }
                if profile.canEdit(scope: LocalRecord.library(r)) { editable.insert(id) }
            }
        }
        return (order, paths, editable)
    }

    /// 1. file des suppressions distantes ; 2. binaires orphelins purgés (leur copie cloud mise en
    /// file) ; 3. téléversement des binaires modifiés ou changés de périmètre ; 4. téléchargement
    /// de FOND, séquentiel, des documents manquants (n'allonge pas la synchro).
    func syncAttachments(uid: String) async throws {
        var firstErr: Error?
        let p = prefs
        for path in p.attachmentDeleteQueue {
            do {
                try await auth.storage("DELETE", path)
                p.attachmentDeleteQueue = p.attachmentDeleteQueue.filter { $0 != path }
            } catch {
                // 404 : déjà parti ; 400/403 : ne passera jamais (droits perdus, chemin refusé).
                if let st = (error as? CloudError)?.httpStatus, st == 404 || st == 403 || st == 400 {
                    p.attachmentDeleteQueue = p.attachmentDeleteQueue.filter { $0 != path }
                } else if firstErr == nil { firstErr = error }
            }
        }
        let plan = attachmentPlan(uid: uid)
        let protected = host?.syncProtectedAttachmentIds() ?? []
        for rec in store.attachmentRecords().sorted(by: { $0.id < $1.id }) {
            guard let want = plan.paths[rec.id] else {
                if protected.contains(rec.id) { continue }             // brouillon en cours : intouché
                if let rp = rec.remotePath { p.queueAttachmentDelete(rp) }
                store.deleteAttachment(rec.id)
                continue
            }
            if !plan.editable.contains(rec.id) { continue }             // un lecteur ne téléverse jamais
            if rec.dirty || rec.remotePath != want {
                do {
                    guard let body = store.attachmentData(rec.id) else { continue }
                    try await auth.storage("POST", want, body: body, contentType: "application/pdf", extra: ["x-upsert": "true"])
                    if let old = rec.remotePath, old != want { p.queueAttachmentDelete(old) }
                    // Relu frais : le document a pu être remplacé ou retiré pendant l'envoi.
                    if var fresh = store.attachmentRecord(rec.id), fresh.size == rec.size {
                        fresh.dirty = false; fresh.remotePath = want
                        store.updateAttachmentRecord(fresh)
                    }
                } catch { if firstErr == nil { firstErr = error } }
            }
        }
        let missing = plan.order.filter { store.attachmentURL($0) == nil }
        if !missing.isEmpty && attDownload == nil {
            let paths = plan.paths
            attDownload = Task { @MainActor [weak self] in
                var got: [String] = []
                for id in missing {
                    guard let self, let path = paths[id] else { continue }
                    if (try? await self.fetchAttachment(id: id, path: path)) != nil { got.append(id) }
                }
                self?.attDownload = nil
                self?.host?.syncAttachmentsDidDownload(got)
            }
        }
        if let firstErr { throw firstErr }
    }

    /// `attFetchOne(id, path)` : télécharge UN document et le range (`dirty: 0`, `remotePath`).
    /// La signature `%PDF-` et le plafond de 15 Mo sont vérifiés à l'écriture.
    public func fetchAttachment(id: String, path: String) async throws {
        let r = try await auth.storage("GET", path)
        do { try store.putAttachment(id: id, data: r.body, dirty: false, remotePath: path) }
        catch { throw CloudError.localStore(String(describing: error)) }
    }

    /// Chemin cloud d'un document référencé (visionneuse : téléchargement à la demande).
    public func attachmentPath(id: String) -> String? {
        guard let uid = auth.userId else { return nil }
        return attachmentPlan(uid: uid).paths[id]
    }

    /// Téléchargement à la demande (visionneuse, bouton « Télécharger »). Rend les ids en échec.
    @discardableResult
    public func downloadMissingAttachments(progress: ((Int, Int) -> Void)? = nil) async -> [String] {
        guard let uid = auth.userId else { return [] }
        let plan = attachmentPlan(uid: uid)
        let missing = plan.order.filter { store.attachmentURL($0) == nil }
        var failed: [String] = []
        for (i, id) in missing.enumerated() {
            progress?(i + 1, missing.count)
            do { try await fetchAttachment(id: id, path: plan.paths[id]!) } catch { failed.append(id) }
        }
        if !missing.isEmpty { host?.syncAttachmentsDidDownload(missing.filter { !failed.contains($0) }) }
        return failed
    }

    /// Attend la fin du téléchargement de fond en cours (tests, fin de synchro manuelle).
    public func waitForAttachmentDownloads() async { await attDownload?.value }
}
