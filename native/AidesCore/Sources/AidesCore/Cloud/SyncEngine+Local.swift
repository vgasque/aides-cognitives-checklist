import Foundation

// ÉCRITURES LOCALES QUI NOURRISSENT LA SYNCHRO — ports de `persist`, `persistProtocol`,
// `softDelete`, `softDeleteProtocol`, `saveNote`, `saveCats`, `markPrefsDirty`,
// `schedulePrefsPush`, `bumpUsage`, `_putSessionSafe`, `deleteSession`, `setSessionSync`,
// `backfillSessSync`, `markHeldEdit` / `confirmHeldEdits`.
//
// Elles fixent les INVARIANTS dont le moteur dépend (`dirty`, `updatedAt`, pierres tombales,
// marqueurs de documents de catégories) : la couche d'application les appelle au lieu d'écrire
// directement ces champs, pour qu'aucun chemin d'écriture n'oublie la synchro.

extension SyncEngine {
    /// Espace « sans compte » ET déconnecté : aucune synchro possible, suppressions DURES.
    var isAnonymousOffline: Bool { store.space.isEmpty && !auth.signedIn }

    // MARK: Aides et références

    /// `persist(f)` : `updatedAt = now`, `dirty`, modification retenue si déconnecté dans l'espace
    /// d'un compte, signature `updatedBy` = e-mail si connecté, écriture, synchro programmée.
    /// Lève `CloudError.localStore` si le disque refuse (l'app dit « ⚠ Stockage saturé… »).
    @discardableResult
    public func persist(_ f: Fiche) throws -> Fiche {
        var f = f
        f.updatedAt = now()
        markHeldEdit(f.id)
        if auth.signedIn, let e = auth.email, !e.isEmpty { f.updatedBy = e }
        try putRecord(store.fiches, f.id, LocalRecord.with(f.json, "dirty", true))
        schedule()
        return f
    }

    /// `persistProtocol(p)` — même mécanique, SANS retenue hors connexion (comme le web).
    @discardableResult
    public func persist(_ r: Reference) throws -> Reference {
        var r = r
        r.updatedAt = now()
        if auth.signedIn, let e = auth.email, !e.isEmpty { r.updatedBy = e }
        try putRecord(store.protocols, r.id, LocalRecord.with(r.json, "dirty", true))
        schedule()
        return r
    }

    /// `softDelete(f)` : suppression DURE dans l'espace sans compte hors connexion ; sinon PIERRE
    /// TOMBALE (même déconnecté dans l'espace d'un compte : une suppression hors ligne doit se
    /// propager). La note personnelle suit (t:'' à pousser).
    public func softDelete(_ f: Fiche) throws {
        var notes = loadNotes()
        if isAnonymousOffline {
            if notes[f.id] != nil { notes[f.id] = nil; saveNotes(notes) }
            store.fiches.delete(f.id)
            return
        }
        if let n = notes[f.id], !n.t.isEmpty { notes[f.id] = Note(t: "", at: now(), dirty: true); saveNotes(notes) }
        var t = f
        t.deletedAt = now(); t.updatedAt = t.deletedAt!
        markHeldEdit(f.id)
        try putRecord(store.fiches, f.id, LocalRecord.with(t.json, "dirty", true))
        schedule()
    }

    /// `softDeleteProtocol(p)`.
    public func softDelete(_ r: Reference) throws {
        if isAnonymousOffline { store.protocols.delete(r.id); return }
        var t = r
        t.deletedAt = now(); t.updatedAt = t.deletedAt!
        try putRecord(store.protocols, r.id, LocalRecord.with(t.json, "dirty", true))
        schedule()
    }

    // MARK: Notes, catégories, préférences

    /// `saveNote(ficheId, text)` : 10 000 caractères au plus ; une note vide qui n'a jamais existé
    /// n'écrit rien ; une note vidée reste en PIERRE TOMBALE (t:'') pour propager l'effacement.
    public func saveNote(ficheId: String, text: String) {
        let t = JS.prefix(text, 10000)
        var notes = loadNotes()
        if JS.trim(t).isEmpty && notes[ficheId] == nil { return }
        notes[ficheId] = Note(t: JS.trim(t).isEmpty ? "" : t, at: now(), dirty: true)
        saveNotes(notes)
        schedule()
    }

    /// `saveCats(scope)` : écrit TOUTES les catégories et marque le document du périmètre
    /// (nil/'' = Perso, sinon id de bibliothèque) à pousser.
    public func saveCategories(_ cats: [Category], scope: String?) {
        saveCategories(cats)
        prefs.markCatsDirty(scope ?? "", now: now())
        schedule()
    }

    /// `markPrefsDirty()` : document PERSO à pousser (épingles, frecency, préférences).
    public func markPrefsDirty() { prefs.markCatsDirty("", now: now()) }
    /// `schedulePrefsPush()` : après tout changement de préférence utilisateur.
    public func schedulePrefsPush() {
        markPrefsDirty()
        if auth.signedIn { schedule() }
    }

    /// `bumpUsage(id)` : une ouverture de fiche (frecency), 200 entrées au plus ; la poussée est
    /// LIMITÉE à une toutes les 10 minutes — jamais une écriture réseau par simple ouverture.
    public func bumpUsage(_ id: String) {
        guard !id.isEmpty else { return }
        let p = prefs
        var u = p.usage
        let cur = u[id] ?? Usage(n: 0, t: 0)
        u[id] = Usage(n: min(9999, cur.n + 1), t: now())
        p.usage = sanitizeUsage(usageJSON(u))
        let mark = p.number(SpaceKeys.usagePushMark) ?? 0
        if now() - mark > 600_000 {
            p.set(SpaceKeys.usagePushMark, .number(now()))
            schedulePrefsPush()
        }
    }

    // MARK: Historique des sessions

    /// `_putSessionSafe(s)` : TOUTE écriture de session passe ici — `dirty` et `updatedAt` (horloge
    /// de synchro ; `savedAt`, l'heure du soin, n'est jamais réécrite).
    public func putSession(_ s: JSON) throws {
        guard let id = s["id"]?.string else { throw CloudError.localStore("session sans id") }
        var m = s.object ?? [:]
        m["dirty"] = true
        m["updatedAt"] = .number(now())
        try putRecord(store.sessions, id, .object(m))
    }

    /// `deleteSession(id)` : PIERRE TOMBALE si l'historique est synchronisé (sinon la session
    /// reviendrait au prochain pull), suppression DURE sinon.
    public func deleteSession(id: String) throws {
        if prefs.syncSessions, let s = store.sessions.get(id) {
            try putSession(LocalRecord.with(s, "deletedAt", .number(now())))
            schedule()
        } else {
            store.sessions.delete(id)
        }
    }

    /// `setSessSync(on)` : l'opt-in suit le COMPTE (document personnel).
    public func setSessionSync(_ on: Bool) {
        writeSessionSync(on)
        markPrefsDirty()
        schedule()
    }

    /// `_sessSyncWrite(on)` : écriture SANS marquage (chemin du pull). Le RATTRAPAGE — marquer à
    /// pousser tout l'historique déjà archivé — se fait une fois, gardé par une clé DURABLE
    /// (`ac-sess-backfilled`) et non par la transition, pour couvrir l'état déjà acquis.
    func writeSessionSync(_ on: Bool) {
        prefs.setString(SpaceKeys.syncSessions, on ? "1" : "0")
        guard on, prefs.string(SpaceKeys.sessionsBackfilled) != "1" else { return }
        backfillSessionSync()
        prefs.setString(SpaceKeys.sessionsBackfilled, "1")
        schedule()
    }

    /// `backfillSessSync()` : chaque session archivée non marquée devient « à pousser ».
    @discardableResult
    func backfillSessionSync() -> Int {
        var n = 0
        for s in store.sessions.all() {
            if (s["live"]?.truthy ?? false) || LocalRecord.isDirty(s) { continue }
            if (try? putSession(s)) != nil { n += 1 }
        }
        return n
    }

    // MARK: Modifications retenues (appareil partagé)

    /// `markHeldEdit(id)` : SEULEMENT dans l'espace d'un compte ET déconnecté — ces modifications
    /// ne partiront qu'après confirmation du titulaire (`pendingHeldEdits` / `resolveHeldEdits`).
    public func markHeldEdit(_ id: String) {
        if store.space.isEmpty || auth.signedIn { return }
        var a = prefs.heldEdits
        if !a.contains(id) { a.append(id); prefs.heldEdits = a }
    }

    /// Modifications retenues à faire confirmer (ids encore présents et « dirty ») et le message
    /// du dialogue « Modifications hors connexion » — nil s'il n'y a rien à demander (la liste est
    /// alors vidée, comme `confirmHeldEdits`).
    public func pendingHeldEdits() -> (ids: [String], message: String)? {
        var ids: [String] = []
        var recs: [String: JSON] = [:]
        for id in prefs.heldEdits {
            if let r = store.fiches.get(id), LocalRecord.isDirty(r) { ids.append(id); recs[id] = r }
        }
        guard !ids.isEmpty else { prefs.heldEdits = []; return nil }
        let labels = ids.prefix(5).map { id -> String in
            let r = recs[id]!
            let t = JS.trim(Guard.sstr(r["title"], 48))
            return "« " + (t.isEmpty ? "sans titre" : t) + " »" + (LocalRecord.isDeleted(r) ? " (supprimée)" : "")
        }
        let more = ids.count - labels.count
        let n = ids.count
        let msg = "Pendant que ce compte était déconnecté, \(n) fiche" + (n > 1 ? "s ont été modifiées" : " a été modifiée")
            + " sur cet appareil : " + labels.joined(separator: ", ")
            + (more > 0 ? " et \(more) autre" + (more > 1 ? "s" : "") : "")
            + ". Si c'est bien vous, synchronisez-les ; sinon, écartez-les (les versions de votre espace en ligne seront rétablies)."
        return (ids, msg)
    }

    /// Réponse au dialogue : `true` « Les synchroniser », `false` « Les écarter » (les fiches
    /// retenues sont supprimées localement et le curseur est effacé : le pull suivant rétablit les
    /// versions en ligne). Ne pas appeler sur ✕/Échap : la liste est gardée et redemandée.
    /// Rend le message de confirmation à afficher (écarter), ou nil.
    @discardableResult
    public func resolveHeldEdits(sync: Bool) -> String? {
        if sync {
            prefs.heldEdits = []
            schedule()
            return nil
        }
        let ids = pendingHeldEdits()?.ids ?? []
        for id in ids { store.fiches.delete(id); acc.remove(.fiches, id) }
        prefs.remove(SpaceKeys.cursorFiches)
        prefs.heldEdits = []
        flush()
        schedule()
        return "Modifications écartées : les versions de votre espace en ligne seront rétablies à la prochaine synchronisation."
    }
}
