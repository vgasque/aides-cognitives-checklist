import XCTest
@testable import AidesCore

/// Hôte de test : enregistre tout ce que le moteur lui dit.
@MainActor
final class RecordingHost: SyncHost {
    var statuses: [SyncStatus] = []
    var changes: [SyncChanges] = []
    var notices: [SyncNotice] = []
    var profiles: [Profile] = []
    var prefs: [RemotePrefsChange] = []
    var reassigned: [(SyncEntityKind, String, String)] = []
    var protected: Set<String> = []
    var downloaded: [[String]] = []
    func syncStatusDidChange(_ status: SyncStatus) { statuses.append(status) }
    func syncDidApply(_ c: SyncChanges) { changes.append(c) }
    func syncNotice(_ n: SyncNotice) { notices.append(n) }
    func syncProfileDidChange(_ p: Profile) { profiles.append(p) }
    func syncPrefsDidChange(_ c: RemotePrefsChange) { prefs.append(c) }
    func syncDidReassign(_ k: SyncEntityKind, from o: String, to n: String) { reassigned.append((k, o, n)) }
    func syncProtectedAttachmentIds() -> Set<String> { protected }
    func syncAttachmentsDidDownload(_ ids: [String]) { downloaded.append(ids) }
    var allChanges: SyncChanges {
        var a = SyncChanges()
        for c in changes {
            a.fiches += c.fiches; a.removedFicheIds += c.removedFicheIds; a.references += c.references
            a.removedReferenceIds += c.removedReferenceIds; a.sessions += c.sessions; a.removedSessionIds += c.removedSessionIds
            a.categories = a.categories || c.categories; a.pins = a.pins || c.pins; a.notes.formUnion(c.notes)
        }
        return a
    }
}

let T0: Double = 1_790_000_000_000
let PDF = Data("%PDF-1.4\n%fake\n".utf8)

/// Classe NON isolée (XCTestCase ne l'est pas) ; chaque test tourne sur l'acteur principal et
/// monte son décor par `boot()`.
final class SyncEngineTests: XCTestCase {
    var fake: FakeSupabase!
    var base: URL!
    var local: LocalStore!
    var store: SpaceStore!
    var auth: AuthClient!
    var host: RecordingHost!
    var clock: TestBox<Double>!
    var sched: ManualSyncScheduler!
    var online = true
    var engine: SyncEngine!
    var uid: String { fake.userId }

    @MainActor func boot() async {
        fake = FakeSupabase()
        fake.serverNow = T0 + 3_600_000
        fake.rpcs["my_status"] = rpcValue("approved")
        fake.rpcs["is_app_admin"] = rpcValue(false)
        fake.rpcs["is_approved"] = rpcValue(true)
        fake.rpcs["list_unapproved_users"] = rpcValue([])
        base = FileManager.default.temporaryDirectory.appendingPathComponent("sync-\(UUID().uuidString)")
        local = LocalStore(base: base)
        local.currentSpace = fake.userId
        store = local.open(fake.userId)
        clock = TestBox(T0)
        let c = clock!
        auth = AuthClient(config: testConfig, transport: fake, secureStore: InMemorySecureStore(), clock: { c.value })
        await auth.adopt(AuthSession(accessToken: "tok", refreshToken: "rt", expiresAt: 9e9,
                                     user: ["id": .string(fake.userId), "email": "soignant@exemple.fr"]))
        host = RecordingHost()
        sched = ManualSyncScheduler()
        online = true
        engine = SyncEngine(auth: auth, local: local, store: store, host: host, scheduler: sched,
                            isOnline: { [unowned self] in self.online }, clock: { c.value })
    }
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: base)
    }

    // MARK: Aides

    func fiche(_ id: String, title: String = "Aide", updatedAt: Double = T0, library: String? = nil, dirty: Bool = true,
               deleted: Double? = nil, docs: [Attachment] = []) -> JSON {
        var f = Fiche(id: id)
        f.title = title; f.updatedAt = updatedAt; f.order = 1; f.library = library; f.deletedAt = deleted; f.docs = docs
        var j = f.json.object!
        if dirty { j["dirty"] = true }
        return .object(j)
    }
    func put(_ j: JSON) { try! store.fiches.put(j["id"]!.string!, j) }
    func serverFiche(_ id: String, title: String = "Distante", updatedAt: Double, library: String? = nil, deleted: Double? = nil) -> JSON {
        var f = Fiche(id: id); f.title = title; f.order = 1; f.library = library
        return ["id": .string(id), "owner": .string(uid), "library_id": library.map { .string($0) } ?? .null,
                "data": f.json, "updated_at": .string(JSDate.iso(updatedAt)),
                "deleted_at": deleted.map { .string(JSDate.iso($0)) } ?? .null]
    }
    func seedServer(_ table: String, _ rows: [JSON]) { fake.locked { fake.tables[table, default: []] += rows } }
    /// Le serveur n'est pas vide : première synchro = adoption du cloud.
    func markInitDone() { local.global.set(GlobalKeys.syncInit(uid), "1") }

    // MARK: Séquence

    @MainActor func testFirstSyncOnEmptyCloudUploadsLocalLibraryInOrder() async throws {
        await boot()
        put(fiche("f1", title: "Anaphylaxie", dirty: false))
        put(fiche("f2", title: "Partagée", library: "L1", dirty: false))
        try store.protocols.put("p1", LocalRecord.with(Reference(id: "p1").json, "updatedAt", .number(T0)))
        await engine.full()
        XCTAssertEqual(engine.status, .synced)
        XCTAssertEqual(host.statuses.first, .busy)
        let seq = fake.paths()
        func idx(_ p: String) -> Int { seq.firstIndex { $0.contains(p) } ?? -1 }
        XCTAssertEqual(seq[0], "POST /rest/v1/rpc/my_status")
        XCTAssertLessThan(idx("/rest/v1/rpc/my_status"), idx("/rest/v1/memberships"))
        XCTAssertLessThan(idx("/rest/v1/memberships"), idx("rpc/is_app_admin"))
        XCTAssertLessThan(idx("rpc/is_app_admin"), idx("cognitive_aids?select=id&library_id=is.null&limit=1"))
        XCTAssertLessThan(idx("library_id=is.null"), idx("GET /rest/v1/cognitive_aids?select=*&updated_at=gt."))
        XCTAssertLessThan(idx("GET /rest/v1/cognitive_aids?select=*"), idx("GET /rest/v1/protocols?select=*&updated_at"))
        XCTAssertLessThan(idx("GET /rest/v1/protocols?select=*"), idx("POST /rest/v1/cognitive_aids"))
        XCTAssertLessThan(idx("POST /rest/v1/cognitive_aids"), idx("POST /rest/v1/protocols"))
        XCTAssertLessThan(idx("POST /rest/v1/protocols"), idx("GET /rest/v1/cognitive_aids?select=id&order=id.asc"))
        XCTAssertLessThan(idx("GET /rest/v1/protocols?select=id&order"), idx("category_sets?select=*&scope_key=eq.personal%3A"))
        XCTAssertLessThan(idx("POST /rest/v1/category_sets"), idx("aid_notes?select=fiche_id,note,updated_at"))
        XCTAssertEqual(idx("/sessions"), -1)   // historique non activé : rien ne monte ni ne descend
        XCTAssertTrue(seq.contains("GET /rest/v1/cognitive_aids?select=*&updated_at=gt.1970-01-01T00%3A00%3A00Z&order=updated_at.asc&limit=1000"))
        // Ligne poussée : format EXACT du web.
        let post = try XCTUnwrap(fake.requests.first { $0.method == "POST" && $0.url.path == "/rest/v1/cognitive_aids" })
        XCTAssertEqual(post.headers["Prefer"], "resolution=merge-duplicates,return=minimal")
        let rows = try XCTUnwrap(post.jsonBody?.array)
        XCTAssertEqual(rows.count, 1)   // la fiche d'une bibliothèque non partagée avec moi n'est pas marquée
        let row = rows[0]
        XCTAssertEqual(Set(row.object!.keys), ["id", "owner", "library_id", "data", "updated_at", "deleted_at"])
        XCTAssertEqual(row["owner"], .string(uid))
        XCTAssertEqual(row["library_id"], .null)
        XCTAssertEqual(row["updated_at"], .string(JSDate.iso(T0)))
        XCTAssertEqual(row["deleted_at"], .null)
        XCTAssertNil(row["data"]?["dirty"])
        XCTAssertEqual(row["data"]?["title"], "Anaphylaxie")
        XCTAssertEqual(row["data"], Sanitize.fiche(fiche("f1", title: "Anaphylaxie", dirty: false)).json)
        // Local : plus « dirty » ; marqueur de première synchro posé ; document perso poussé.
        XCTAssertEqual(store.fiches.get("f1")?["dirty"], false)
        XCTAssertEqual(local.global.string(GlobalKeys.syncInit(uid)), "1")
        XCTAssertNil(engine.prefs.kv[SpaceKeys.catsDirty("")])
        let cs = try XCTUnwrap(fake.rows("category_sets").first)
        XCTAssertEqual(cs["scope_key"], .string("personal:" + uid))
        XCTAssertEqual(Set(cs["data"]!.object!.keys), ["categories", "pins", "usage", "prefs"])
        XCTAssertEqual(cs["data"]?["prefs"], ["theme": "auto", "zoom": 100, "accent": "", "readMode": "overview", "tags": [], "syncSessions": false, "homeGroup": "cat"])
        // Curseur : rien vu → pas de curseur.
        XCTAssertNil(engine.prefs.string(SpaceKeys.cursorFiches))
        XCTAssertEqual(engine.retryDelay, 0)
        XCTAssertGreaterThan(engine.lastSyncAt, 0)
    }

    @MainActor func testCloudNotEmptyIsAdoptedNotOverwritten() async throws {
        await boot()
        seedServer("cognitive_aids", [serverFiche("r1", updatedAt: T0 - 1000)])
        put(fiche("f1", dirty: false))
        await engine.full()
        XCTAssertEqual(fake.log("POST").filter { $0.url.path == "/rest/v1/cognitive_aids" }.count, 0)
        XCTAssertNotNil(store.fiches.get("r1"))
        XCTAssertEqual(host.allChanges.fiches.map(\.id), ["r1"])
        XCTAssertEqual(engine.prefs.string(SpaceKeys.cursorFiches), JSDate.iso(T0 - 1000))
    }

    @MainActor func testPendingAndRejectedStopWithoutRetry() async throws {
        await boot()
        fake.rpcs["my_status"] = rpcValue("pending")
        await engine.full()
        XCTAssertEqual(engine.status, .pending)
        XCTAssertEqual(engine.status.text, "En attente de validation")
        XCTAssertEqual(fake.paths(), ["POST /rest/v1/rpc/my_status"])
        XCTAssertFalse(engine.retryPending)
        XCTAssertEqual(engine.profile.accountStatus, .pending)
        fake.rpcs["my_status"] = rpcValue("rejected")
        await engine.full()
        XCTAssertEqual(engine.status, .rejected)
        XCTAssertEqual(engine.status.text, "Compte refusé")
        // Un échec réseau GARDE le dernier statut connu.
        fake.rpcs["my_status"] = { _ in throw CloudError.network("x") }
        await engine.refreshAccountStatus()
        XCTAssertEqual(engine.profile.accountStatus, .rejected)
    }

    @MainActor func testGuardsSpaceOfflineAndSignedOut() async throws {
        await boot()
        let other = SyncEngine(auth: auth, local: local, store: local.open(""), host: host, scheduler: sched, clock: { T0 })
        await other.full()
        XCTAssertTrue(fake.requests.isEmpty, "jamais un compte dans l'espace d'un autre")
        online = false
        await engine.full()
        XCTAssertEqual(engine.status, .offline)
        XCTAssertTrue(fake.requests.isEmpty)
        online = true
        await auth.signOut()
        fake.reset()
        await engine.full()
        engine.schedule()
        XCTAssertTrue(fake.requests.isEmpty)
        XCTAssertTrue(sched.pendingDelays.isEmpty)
    }

    @MainActor func testDebounceAndRetryBackoff() async throws {
        await boot()
        markInitDone()
        engine.schedule(); engine.schedule(); engine.schedule()
        XCTAssertEqual(sched.pendingDelays, [900])
        await sched.advance(by: 899)
        XCTAssertTrue(fake.requests.isEmpty)
        await sched.advance(by: 1)
        XCTAssertEqual(engine.status, .synced)
        // Serveur en panne : relances 5 s, 10 s, 20 s, 40 s, 80 s, 120 s, 120 s.
        fake.intercept = { r in r.url.path.contains("cognitive_aids") ? HTTPResponse(status: 503, body: Data("down".utf8)) : nil }
        await engine.full()
        XCTAssertEqual(engine.status, .error)
        XCTAssertEqual(engine.lastError?.title, "Service indisponible")
        XCTAssertEqual(engine.lastError?.icon, .server)
        var delays: [Double] = []
        for _ in 0..<7 {
            delays.append(sched.pendingDelays.first ?? -1)
            await sched.advance(by: sched.pendingDelays.first ?? 0)
        }
        XCTAssertEqual(delays, [5000, 10000, 20000, 40000, 80000, 120000, 120000])
        XCTAssertTrue(engine.retryPending)
        // Hors ligne à l'échéance : pas de synchro, pas de nouvelle relance (le retour du réseau relancera).
        online = false
        let n = fake.requests.count
        await sched.advance(by: 120000)
        XCTAssertEqual(fake.requests.count, n)
        XCTAssertFalse(engine.retryPending)
        // Retour du réseau : synchro complète, délai remis à zéro.
        online = true
        fake.intercept = nil
        await engine.networkDidChange(online: true)
        XCTAssertEqual(engine.status, .synced)
        XCTAssertEqual(engine.retryDelay, 0)
        XCTAssertEqual(host.statuses.suffix(3), [.synced, .busy, .synced])
    }

    // MARK: Pull

    @MainActor func testPullCursorOverlapSweepAndChunks() async throws {
        await boot()
        markInitDone()
        seedServer("cognitive_aids", [serverFiche("r1", updatedAt: T0), serverFiche("r2", updatedAt: T0 + 500)])
        await engine.full()
        XCTAssertEqual(engine.prefs.string(SpaceKeys.cursorFiches), JSDate.iso(T0 + 500))
        XCTAssertEqual(fake.log("select=id,updated_at,deleted_at").count, 0)   // sans curseur : pas de repêchage
        // Une ligne « dans le passé » (horloge en retard) apparaît : seul le repêchage la voit.
        seedServer("cognitive_aids", [serverFiche("late", updatedAt: T0 - 100_000), serverFiche("new", updatedAt: T0 + 9000)])
        fake.reset()
        await engine.full()
        let paths = fake.paths()
        XCTAssertTrue(paths.contains("GET /rest/v1/cognitive_aids?select=*&updated_at=gt." + jsEncodeURIComponent(JSDate.iso(T0 + 500 - 2000)) + "&order=updated_at.asc&limit=1000"))
        XCTAssertTrue(paths.contains("GET /rest/v1/cognitive_aids?select=id,updated_at,deleted_at&order=id.asc&limit=1000"))
        XCTAssertTrue(paths.contains("GET /rest/v1/cognitive_aids?select=*&id=in.(late)"))
        XCTAssertNotNil(store.fiches.get("late"))
        XCTAssertNotNil(store.fiches.get("new"))
        XCTAssertEqual(engine.prefs.string(SpaceKeys.cursorFiches), JSDate.iso(T0 + 9000))
        // Écho sans changement : aucune écriture, aucun changement annoncé.
        host.changes = []
        await engine.full()
        XCTAssertTrue(host.allChanges.fiches.isEmpty)
    }

    @MainActor func testPullPaginatesAndChunksBySixty() async throws {
        await boot()
        markInitDone()
        let many = (0..<1100).map { serverFiche(String(format: "r%04d", $0), updatedAt: T0 + Double($0)) }
        seedServer("cognitive_aids", many)
        await engine.full()
        XCTAssertEqual(store.fiches.all().count, 1100)
        let pages = fake.log("cognitive_aids?select=*&updated_at=gt.")
        XCTAssertEqual(pages.count, 2)
        XCTAssertTrue(pages[1].url.absoluteString.contains(jsEncodeURIComponent(JSDate.iso(T0 + 999))))
        // 130 lignes révélées d'un coup, antérieures au curseur : trois lots (60, 60, 10).
        let late = (0..<130).map { serverFiche(String(format: "z%04d", $0), updatedAt: T0 - 50_000) }
        seedServer("cognitive_aids", late)
        fake.reset()
        await engine.full()
        let chunks = fake.log("select=*&id=in.(")
        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(fake.log("select=id,updated_at,deleted_at").count, 2)   // 1230 lignes : deux pages
        XCTAssertEqual(store.fiches.all().count, 1230)
    }

    @MainActor func testConflictKeepsBackupAndNotifies() async throws {
        await boot()
        markInitDone()
        put(fiche("f1", title: "Ma version", updatedAt: T0, dirty: true))
        seedServer("cognitive_aids", [serverFiche("f1", title: "Version distante", updatedAt: T0 + 60_000)])
        await engine.full()
        XCTAssertEqual(store.fiches.get("f1")?["title"], "Version distante")
        XCTAssertNil(store.fiches.get("f1")?["dirty"])
        let bks = engine.backups(ficheId: "f1")
        XCTAssertEqual(bks.count, 1)
        XCTAssertEqual(bks[0]["data"]?["title"], "Ma version")
        XCTAssertEqual(host.notices, [.conflicts(["Ma version"])])
        XCTAssertEqual(host.notices[0].message, "⚠ 1 fiche modifiée sur un autre appareil. Version la plus récente appliquée ; votre version précédente est conservée (bouton « Versions » dans la fiche).")
        XCTAssertEqual(fake.log("POST").filter { $0.url.path == "/rest/v1/cognitive_aids" }.count, 0)
        // Cinq versions au plus par fiche.
        for i in 1...7 {
            clock.mutate { $0 += 1 }
            put(fiche("f1", title: "v\(i)", updatedAt: T0 + 60_000 + Double(i), dirty: false))
            fake.locked { fake.tables["cognitive_aids"] = [serverFiche("f1", updatedAt: T0 + 70_000 + Double(i) * 1000)] }
            engine.prefs.remove(SpaceKeys.cursorFiches)
            await engine.full()
        }
        XCTAssertEqual(engine.backups(ficheId: "f1").count, 5)
        XCTAssertEqual(engine.backups(ficheId: "f1").first?["data"]?["title"], "v7")
    }

    @MainActor func testLocalNewerIsKeptAndPushed() async throws {
        await boot()
        markInitDone()
        put(fiche("f1", title: "Locale", updatedAt: T0 + 5000, dirty: true))
        seedServer("cognitive_aids", [serverFiche("f1", title: "Ancienne", updatedAt: T0)])
        await engine.full()
        XCTAssertEqual(fake.row("cognitive_aids", "f1")?["data"]?["title"], "Locale")
        XCTAssertEqual(store.fiches.get("f1")?["dirty"], false)
        XCTAssertTrue(host.notices.isEmpty)
    }

    @MainActor func testRemoteTombstoneDeletesEvenDirtyAndClearsNote() async throws {
        await boot()
        markInitDone()
        put(fiche("f1", updatedAt: T0 + 99_999, dirty: true))
        store.meta["notes"] = ["f1": ["t": "ma note", "at": .number(T0)]]
        seedServer("cognitive_aids", [serverFiche("f1", updatedAt: T0, deleted: T0)])
        await engine.full()
        XCTAssertNil(store.fiches.get("f1"))
        XCTAssertTrue(host.allChanges.removedFicheIds.contains("f1"))
        // La note vidée est poussée (pierre tombale de note), puis n'est plus « dirty ».
        let n = try XCTUnwrap(fake.rows("aid_notes").first)
        XCTAssertEqual(n["note"], "")
        XCTAssertEqual(n["user_id"], .string(uid))
        XCTAssertEqual(engine.loadNotes()["f1"]?.dirty, false)
    }

    // MARK: Push

    @MainActor func testTombstoneIsPushedThenPurged() async throws {
        await boot()
        markInitDone()
        let f = Sanitize.fiche(fiche("f1", dirty: false))
        try engine.softDelete(f)
        XCTAssertEqual(store.fiches.get("f1")?["deletedAt"], .number(T0))
        await sched.advance(by: 900)
        let row = try XCTUnwrap(fake.row("cognitive_aids", "f1"))
        XCTAssertEqual(row["deleted_at"], .string(JSDate.iso(T0)))
        XCTAssertNil(store.fiches.get("f1"))
    }

    @MainActor func testPerso403IsRepairedWithNewIdAndAttachmentsFollow() async throws {
        await boot()
        markInitDone()
        put(fiche("taken", title: "Importée", dirty: true))
        put(fiche("ok1", title: "Normale", dirty: true))
        store.meta["notes"] = ["taken": ["t": "note", "at": .number(T0)]]
        engine.prefs.pins = ["taken", "ok1"]
        try store.sessions.put("s1", ["id": "s1", "ficheId": "taken", "live": false, "savedAt": .number(T0)])
        try store.backups.put("bk1", ["bid": "bk1", "ficheId": "taken", "at": .number(T0), "data": [:]])
        // L'id « taken » appartient à un autre compte : la RLS refuse.
        fake.writeAllowed = { t, row in !(t == "cognitive_aids" && row["id"] == "taken") }
        await engine.full()
        XCTAssertEqual(engine.status, .synced)
        XCTAssertNil(store.fiches.get("taken"))
        let newId = try XCTUnwrap(host.reassigned.first?.2)
        XCTAssertEqual(host.reassigned.first?.1, "taken")
        XCTAssertTrue(newId.hasPrefix("f"))
        XCTAssertNotNil(fake.row("cognitive_aids", newId))
        XCTAssertNotNil(fake.row("cognitive_aids", "ok1"))
        XCTAssertEqual(store.fiches.get(newId)?["dirty"], false)
        XCTAssertEqual(engine.loadNotes()[newId]?.t, "note")
        XCTAssertNil(engine.loadNotes()["taken"])
        XCTAssertEqual(engine.prefs.pins, [newId, "ok1"])
        XCTAssertEqual(store.sessions.get("s1")?["ficheId"], .string(newId))
        XCTAssertEqual(store.backups.get("bk1")?["ficheId"], .string(newId))
        // Les épingles ont changé : le document perso est repoussé avec la nouvelle.
        XCTAssertEqual(fake.rows("category_sets").first?["data"]?["pins"], [.string(newId), "ok1"])
        // Séquence : lot refusé, puis un par un, puis la réparation.
        let posts = fake.log("/rest/v1/cognitive_aids").filter { $0.method == "POST" }
        XCTAssertEqual(posts.map { $0.jsonBody?.array?.count ?? 0 }, [2, 1, 1, 1])
    }

    @MainActor func testPerso403WithoutWriteRightsDoesNotRenameEverything() async throws {
        await boot()
        markInitDone()
        put(fiche("a", dirty: true))
        fake.writeAllowed = { _, _ in false }
        fake.rpcs["is_approved"] = rpcValue(false)
        await engine.full()
        XCTAssertEqual(engine.status, .error)
        XCTAssertEqual(engine.lastError?.title, "Écriture refusée")
        XCTAssertNotNil(store.fiches.get("a"))
        XCTAssertTrue(host.reassigned.isEmpty)
        XCTAssertTrue(engine.retryPending)
    }

    @MainActor func testRightsLostCopiesToPersoAndRestoresTeamVersion() async throws {
        await boot()
        markInitDone()
        fake.libraries = ["L1": "Équipe"]
        fake.memberships = [(uid, "L1", "viewer")]
        put(fiche("sh1", title: "Protocole équipe", library: "L1", dirty: true))
        put(fiche("sh2", title: "Supprimée", library: "L1", dirty: true, deleted: T0))
        seedServer("cognitive_aids", [serverFiche("sh1", title: "Version équipe", updatedAt: T0 - 1, library: "L1"),
                                      serverFiche("sh2", title: "Toujours là", updatedAt: T0 - 1, library: "L1")])
        await engine.full()
        XCTAssertEqual(store.fiches.get("sh1")?["title"], "Version équipe")
        XCTAssertEqual(store.fiches.get("sh2")?["title"], "Toujours là")
        let copies = store.fiches.all().filter { $0["title"] == "Protocole équipe" }
        XCTAssertEqual(copies.count, 1)
        let copy = copies[0]
        XCTAssertEqual(copy["library"], .null)
        XCTAssertEqual(copy["updatedBy"], "")
        XCTAssertNotNil(fake.row("cognitive_aids", copy["id"]!.string!), "la copie Perso part dans le même passage")
        XCTAssertEqual(host.notices.count, 1)
        XCTAssertEqual(host.notices[0].message, "Vos modifications sur « Protocole équipe » (et 1 autre) n’ont pas pu être publiées : vos droits sur la bibliothèque ont changé. Votre version a été copiée dans « Perso ». La suppression a été annulée (version de l’équipe restaurée).")
        XCTAssertTrue(fake.log("cognitive_aids?id=eq.sh1&select=*").count == 1)
    }

    @MainActor func testHeldEditsAreNotPushedUntilConfirmed() async throws {
        await boot()
        markInitDone()
        await auth.signOut()
        let f = Sanitize.fiche(fiche("h1", title: "Hors connexion", dirty: false))
        try engine.persist(f)
        XCTAssertEqual(engine.prefs.heldEdits, ["h1"])
        await auth.adopt(AuthSession(accessToken: "tok", refreshToken: "rt", expiresAt: 9e9, user: ["id": .string(uid), "email": "x@y.fr"]))
        await engine.full()
        XCTAssertNil(fake.row("cognitive_aids", "h1"))
        let pending = try XCTUnwrap(engine.pendingHeldEdits())
        XCTAssertEqual(pending.ids, ["h1"])
        XCTAssertEqual(pending.message, "Pendant que ce compte était déconnecté, 1 fiche a été modifiée sur cet appareil : « Hors connexion ». Si c'est bien vous, synchronisez-les ; sinon, écartez-les (les versions de votre espace en ligne seront rétablies).")
        engine.resolveHeldEdits(sync: true)
        await sched.advance(by: 900)
        XCTAssertNotNil(fake.row("cognitive_aids", "h1"))
        // « Les écarter » : suppression locale + curseur effacé.
        await auth.signOut()
        try engine.persist(Sanitize.fiche(fiche("h2", dirty: false)))
        engine.prefs.setString(SpaceKeys.cursorFiches, "2026-01-01T00:00:00.000Z")
        let msg = engine.resolveHeldEdits(sync: false)
        XCTAssertEqual(msg, "Modifications écartées : les versions de votre espace en ligne seront rétablies à la prochaine synchronisation.")
        XCTAssertNil(store.fiches.get("h2"))
        XCTAssertNil(engine.prefs.string(SpaceKeys.cursorFiches))
        XCTAssertTrue(engine.prefs.heldEdits.isEmpty)
    }

    @MainActor func testPersistSignsAndSchedules() async throws {
        await boot()
        let f = try engine.persist(Sanitize.fiche(fiche("p1", dirty: false)))
        XCTAssertEqual(f.updatedBy, "soignant@exemple.fr")
        XCTAssertEqual(store.fiches.get("p1")?["dirty"], true)
        XCTAssertEqual(store.fiches.get("p1")?["updatedAt"], .number(T0))
        XCTAssertEqual(sched.pendingDelays, [900])
        XCTAssertTrue(engine.prefs.heldEdits.isEmpty, "connecté : rien à retenir")
    }

    @MainActor func testAnonymousSpaceDeletesHard() async throws {
        await boot()
        await auth.signOut()
        let anon = SyncEngine(auth: auth, local: local, store: local.open(""), host: host, scheduler: sched, clock: { T0 })
        try anon.store.fiches.put("a1", fiche("a1"))
        anon.store.meta["notes"] = ["a1": ["t": "x", "at": 1]]
        try anon.softDelete(Sanitize.fiche(fiche("a1")))
        XCTAssertNil(anon.store.fiches.get("a1"))
        XCTAssertNil(anon.loadNotes()["a1"])
        // Espace d'un compte, même déconnecté : pierre tombale (la suppression doit se propager).
        try engine.softDelete(Sanitize.fiche(fiche("b1")))
        XCTAssertEqual(store.fiches.get("b1")?["deletedAt"], .number(T0))
        XCTAssertEqual(engine.prefs.heldEdits, ["b1"])
    }

    // MARK: Réconciliation

    @MainActor func testReconcileRemovesInaccessibleSharedOnly() async throws {
        await boot()
        markInitDone()
        fake.libraries = ["L1": "Équipe"]
        fake.memberships = [(uid, "L1", "editor")]
        put(fiche("gone", library: "L1", dirty: false))
        put(fiche("kept", library: "L1", dirty: false))
        put(fiche("perso", dirty: false))
        seedServer("cognitive_aids", [serverFiche("kept", updatedAt: T0, library: "L1")])
        await engine.full()
        XCTAssertNil(store.fiches.get("gone"))
        XCTAssertNotNil(store.fiches.get("kept"))
        XCTAssertNotNil(store.fiches.get("perso"))
        XCTAssertTrue(host.allChanges.removedFicheIds.contains("gone"))
        // Échec réseau de la liste : RIEN n'est supprimé.
        put(fiche("gone2", library: "L1", dirty: false))
        fake.intercept = { r in r.url.absoluteString.contains("cognitive_aids?select=id&order") ? HTTPResponse(status: 500) : nil }
        await engine.full()
        XCTAssertNotNil(store.fiches.get("gone2"))
        XCTAssertEqual(engine.status, .synced)
    }

    // MARK: Catégories et préférences

    @MainActor func testRemoteCategoryDocumentWinsAndAppliesPrefs() async throws {
        await boot()
        markInitDone()
        engine.saveCategories([Category(id: "c-old", name: "Old", color: "#111111"), Category(id: "cL", name: "Lib", color: "#222222", library: "L1")], scope: nil)
        engine.prefs.set(SpaceKeys.catsUpdated(""), .number(T0))
        engine.prefs.usage = ["f1": Usage(n: 5, t: 10)]
        seedServer("category_sets", [["scope_key": .string("personal:" + uid), "owner": .string(uid), "library_id": .null,
                                      "updated_at": .string(JSDate.iso(T0 + 1000)),
                                      "data": ["categories": [["id": "c-urgences", "name": "Urgences", "color": "#7a2f6b", "library": "X"]],
                                               "pins": ["f9", "bad id"], "usage": ["f1": ["n": 2, "t": 99], "f2": ["n": 1, "t": 5]],
                                               "prefs": ["theme": "dark", "zoom": 130, "accent": "teal", "readMode": "static",
                                                         "tags": [["k": "t1", "l": "Renfort SMUR", "a": ["rs"]]], "syncSessions": true, "homeGroup": "az"]]]])
        await engine.full()
        let cats = engine.loadCategories()
        XCTAssertEqual(cats.map(\.id).sorted(), ["c-urgences", "cL"])
        XCTAssertNil(cats.first { $0.id == "c-urgences" }?.library, "bibliothèque forcée au périmètre du document")
        XCTAssertEqual(engine.prefs.pins, ["f9"])
        XCTAssertEqual(engine.prefs.usage["f1"], Usage(n: 5, t: 10))   // fusion : max n
        XCTAssertEqual(engine.prefs.usage["f2"], Usage(n: 1, t: 5))
        XCTAssertEqual(engine.prefs.theme, "dark")
        XCTAssertEqual(engine.prefs.zoom, 130)
        XCTAssertEqual(engine.prefs.accent, "teal")
        XCTAssertEqual(engine.prefs.readMode, "static")
        XCTAssertEqual(engine.prefs.homeGroup, "az")
        XCTAssertEqual(engine.prefs.tags, [JournalTag(k: "t1", l: "Renfort SMUR", a: ["rs"])])
        XCTAssertTrue(engine.prefs.syncSessions)
        XCTAssertEqual(engine.prefs.string(SpaceKeys.sessionsBackfilled), "1")
        let ch = try XCTUnwrap(host.prefs.first)
        XCTAssertEqual(ch.theme, "dark"); XCTAssertEqual(ch.zoom, 130); XCTAssertEqual(ch.accent, "teal"); XCTAssertTrue(ch.tags)
        XCTAssertEqual(engine.prefs.catsUpdated(""), T0 + 1000)
        XCTAssertFalse(engine.prefs.catsDirty(""), "document distant plus récent : le local (même « dirty ») est remplacé")
        XCTAssertTrue(host.allChanges.categories)
        XCTAssertEqual(fake.log("POST").filter { $0.url.path == "/rest/v1/category_sets" }.count, 0, "pas d'écho")
    }

    @MainActor func testCategoryPushPerScopeAndViewerReadOnly() async throws {
        await boot()
        markInitDone()
        fake.libraries = ["LE": "Éditée", "LV": "Lue"]
        fake.memberships = [(uid, "LE", "editor"), (uid, "LV", "viewer")]
        engine.saveCategories([Category(id: "c1", name: "A", color: "#123456", library: "LE"),
                               Category(id: "c2", name: "B", color: "#654321", library: "LV")], scope: "LE")
        engine.prefs.markCatsDirty("LV", now: T0)
        await engine.full()
        let docs = fake.rows("category_sets")
        let le = try XCTUnwrap(docs.first { $0["scope_key"] == "lib:LE" })
        XCTAssertEqual(le["library_id"], "LE")
        XCTAssertEqual(le["owner"], .string(uid))
        XCTAssertEqual(le["data"], ["categories": [["id": "c1", "name": "A", "color": "#123456", "library": "LE"]]])
        XCTAssertEqual(le["updated_at"], .string(JSDate.iso(T0)))
        XCTAssertNil(docs.first { $0["scope_key"] == "lib:LV" }, "un lecteur ne pousse jamais")
        XCTAssertTrue(engine.prefs.catsDirty("LV"))
        XCTAssertNotNil(docs.first { $0["scope_key"] == .string("personal:" + uid) }, "document perso absent du serveur : poussé")
    }

    // MARK: Notes

    @MainActor func testNotesLastWriterWinsLocalDirtyAlwaysWins() async throws {
        await boot()
        markInitDone()
        store.meta["notes"] = ["mine": ["t": "locale", "at": .number(T0), "dirty": true],
                               "clean": ["t": "vieille", "at": .number(T0)]]
        seedServer("aid_notes", [["user_id": .string(uid), "fiche_id": "mine", "note": "distante", "updated_at": .string(JSDate.iso(T0 + 5000))],
                                 ["user_id": .string(uid), "fiche_id": "clean", "note": "nouvelle", "updated_at": .string(JSDate.iso(T0 + 5000))],
                                 ["user_id": .string(uid), "fiche_id": "__proto__", "note": "x", "updated_at": .string(JSDate.iso(T0))]])
        await engine.full()
        let n = engine.loadNotes()
        XCTAssertEqual(n["clean"]?.t, "nouvelle")
        XCTAssertEqual(n["clean"]?.at, T0 + 5000)
        XCTAssertEqual(n["mine"]?.t, "locale")
        XCTAssertEqual(n["mine"]?.dirty, false)
        XCTAssertNil(n["__proto__"])
        XCTAssertEqual(fake.rows("aid_notes").first { $0["fiche_id"] == "mine" }?["note"], "locale")
        XCTAssertEqual(host.allChanges.notes, ["clean"])
        let post = try XCTUnwrap(fake.log("/rest/v1/aid_notes").first { $0.method == "POST" })
        XCTAssertEqual(post.jsonBody, [["user_id": .string(uid), "fiche_id": "mine", "note": "locale", "updated_at": .string(JSDate.iso(T0))]])
        XCTAssertEqual(post.headers["Prefer"], "resolution=merge-duplicates,return=minimal")
    }

    @MainActor func testNotesPushErrorAbortsFull() async throws {
        await boot()
        markInitDone()
        engine.saveNote(ficheId: "f1", text: "texte")
        fake.intercept = { r in (r.method == "POST" && r.url.path == "/rest/v1/aid_notes") ? HTTPResponse(status: 413) : nil }
        await engine.full()
        XCTAssertEqual(engine.status, .error)
        XCTAssertEqual(engine.lastError?.title, "Contenu trop volumineux")
        XCTAssertEqual(fake.log("storage").count, 0, "les documents ne tournent pas après l'échec des notes")
        XCTAssertEqual(engine.loadNotes()["f1"]?.dirty, true)
    }

    // MARK: Historique des sessions

    @MainActor func testSessionHistoryOptInOnlyArchivedAndNoVerifyTrace() async throws {
        await boot()
        markInitDone()
        try store.sessions.put("live", ["id": "live", "ficheId": "f1", "live": true, "dirty": true, "updatedAt": .number(T0)])
        try store.sessions.put("done", ["id": "done", "ficheId": "f1", "live": false, "savedAt": .number(T0 - 5000),
                                        "verified": ["1:b1:0": true], "linkArm": ["t1": ["b": "b1", "x": 0]], "checked": ["1:b1:0": true]])
        await engine.full()
        XCTAssertEqual(fake.log("/rest/v1/sessions").count, 0)
        engine.setSessionSync(true)   // rattrapage : l'historique déjà archivé part aussi
        XCTAssertEqual(store.sessions.get("done")?["dirty"], true)
        XCTAssertEqual(store.sessions.get("done")?["savedAt"], .number(T0 - 5000), "l'heure du soin n'est jamais réécrite")
        seedServer("sessions", [["id": "remote1", "owner": .string(uid), "exercise": true, "updated_at": .string(JSDate.iso(T0 - 1)), "deleted_at": .null,
                                 "data": ["ficheId": "f2", "ficheTitle": "Distante", "live": false, "vElsewhere": true]]])
        await sched.advance(by: 900)
        XCTAssertEqual(engine.status, .synced)
        let rows = fake.rows("sessions")
        XCTAssertNil(rows.first { $0["id"] == "live" }, "une session vive ne part JAMAIS")
        let done = try XCTUnwrap(rows.first { $0["id"] == "done" })
        XCTAssertNil(done["data"]?["verified"]); XCTAssertNil(done["data"]?["linkArm"]); XCTAssertNil(done["data"]?["dirty"])
        XCTAssertEqual(done["data"]?["vElsewhere"], true)
        XCTAssertEqual(done["exercise"], false)
        XCTAssertEqual(done["updated_at"], .string(JSDate.iso(T0)))
        let pulled = try XCTUnwrap(store.sessions.get("remote1"))
        XCTAssertEqual(pulled["exercise"], true)
        XCTAssertEqual(pulled["verified"], .object([:]))
        XCTAssertEqual(pulled["ficheTitle"], "Distante")
        XCTAssertEqual(engine.prefs.string(SpaceKeys.cursorSessions), JSDate.iso(T0 - 1))
        // Suppression : pierre tombale poussée puis purgée.
        try engine.deleteSession(id: "done")
        await sched.advance(by: 900)
        XCTAssertNotNil(fake.row("sessions", "done")?["deleted_at"]?.string)
        XCTAssertNil(store.sessions.get("done"))
    }

    // MARK: Documents PDF

    @MainActor func testAttachmentsUploadMoveDeleteAndDownload() async throws {
        await boot()
        markInitDone()
        fake.libraries = ["L1": "Équipe", "LV": "Lue"]
        fake.memberships = [(uid, "L1", "editor"), (uid, "LV", "viewer")]
        let att = Attachment(id: "a1", name: "doc.pdf", size: PDF.count)
        put(fiche("f1", dirty: false, docs: [att]))
        try store.putAttachment(id: "a1", data: PDF, dirty: true)
        try store.putAttachment(id: "orph", data: PDF, dirty: false, remotePath: "u/\(uid)/orph.pdf")
        try store.putAttachment(id: "draft", data: PDF, dirty: true)
        host.protected = ["draft"]
        put(fiche("fv", library: "LV", dirty: false, docs: [Attachment(id: "av", name: "v.pdf", size: 1)]))
        seedServer("cognitive_aids", [serverFiche("fv", updatedAt: T0 - 5, library: "LV")])
        try store.fiches.put("fv", LocalRecord.with(fiche("fv", library: "LV", dirty: false, docs: [Attachment(id: "av", name: "v.pdf", size: 1)]), "updatedAt", .number(T0)))
        fake.storage["l/LV/av.pdf"] = PDF
        fake.storage["u/\(uid)/orph.pdf"] = PDF
        await engine.full()
        await engine.waitForAttachmentDownloads()
        XCTAssertEqual(engine.status, .synced)
        // Téléversé au chemin perso, en-têtes Storage.
        let up = try XCTUnwrap(fake.requests.first { $0.method == "POST" && $0.url.path.hasSuffix("/a1.pdf") })
        XCTAssertEqual(up.url.path, "/storage/v1/object/attachments/u/\(uid)/a1.pdf")
        XCTAssertEqual(up.headers["Content-Type"], "application/pdf")
        XCTAssertEqual(up.headers["x-upsert"], "true")
        XCTAssertEqual(store.attachmentRecord("a1")?.dirty, false)
        XCTAssertEqual(store.attachmentRecord("a1")?.remotePath, "u/\(uid)/a1.pdf")
        // Orphelin purgé ici, sa copie cloud en file (supprimée à la synchro suivante).
        XCTAssertNil(store.attachmentRecord("orph"))
        XCTAssertEqual(engine.prefs.attachmentDeleteQueue, ["u/\(uid)/orph.pdf"])
        XCTAssertNotNil(store.attachmentRecord("draft"), "brouillon protégé")
        // Document d'une bibliothèque en lecture : téléchargé en fond, jamais téléversé.
        XCTAssertEqual(store.attachmentData("av"), PDF)
        XCTAssertEqual(store.attachmentRecord("av")?.remotePath, "l/LV/av.pdf")
        XCTAssertEqual(host.downloaded.last, ["av"])
        XCTAssertFalse(fake.requests.contains { $0.method == "POST" && $0.url.path.contains("/l/LV/") })
        // Déplacement de périmètre : re-téléversement + ancien chemin en file.
        put(fiche("f1", updatedAt: T0 + 1, library: "L1", dirty: true, docs: [att]))   // déplacée (persist → dirty)
        await engine.full()
        XCTAssertEqual(fake.storage["l/L1/a1.pdf"], PDF)
        XCTAssertNil(fake.storage["u/\(uid)/orph.pdf"], "file rejouée")
        XCTAssertEqual(engine.prefs.attachmentDeleteQueue, ["u/\(uid)/a1.pdf"])
        await engine.full()
        XCTAssertNil(fake.storage["u/\(uid)/a1.pdf"])
        XCTAssertTrue(engine.prefs.attachmentDeleteQueue.isEmpty)
    }

    @MainActor func testAttachmentDeleteQueueErrorHandling() async throws {
        await boot()
        markInitDone()
        engine.prefs.attachmentDeleteQueue = ["u/\(uid)/gone.pdf", "u/\(uid)/flaky.pdf", "not a path"]
        XCTAssertEqual(engine.prefs.attachmentDeleteQueue.count, 2)
        fake.intercept = { r in
            if r.url.path.hasSuffix("flaky.pdf") { return HTTPResponse(status: 502) }
            return nil   // gone.pdf : 404 du faux Storage → retiré de la file
        }
        await engine.full()
        XCTAssertEqual(engine.prefs.attachmentDeleteQueue, ["u/\(uid)/flaky.pdf"])
        XCTAssertEqual(engine.status, .error)
        XCTAssertEqual(engine.lastError?.title, "Service indisponible")
    }

    // MARK: Profil

    @MainActor func testProfileIsCachedAndNotifiedOnlyOnChange() async throws {
        await boot()
        fake.libraries = ["L1": "Équipe"]
        fake.memberships = [(uid, "L1", "admin")]
        fake.rpcs["is_app_admin"] = rpcValue(true)
        fake.rpcs["list_unapproved_users"] = rpcValue([["user_id": "x", "status": "pending"], ["user_id": "y", "status": "rejected"]])
        await engine.loadProfile()
        XCTAssertEqual(engine.profile.libraries, [LibraryInfo(id: "L1", name: "Équipe", role: .admin)])
        XCTAssertTrue(engine.profile.isAppAdmin)
        XCTAssertEqual(engine.profile.pendingCount, 1)
        XCTAssertEqual(host.profiles.count, 1)
        await engine.loadProfile()
        XCTAssertEqual(host.profiles.count, 1, "profil inchangé : aucune notification")
        XCTAssertEqual(local.global[GlobalKeys.profile(uid)], ["libraries": [["id": "L1", "name": "Équipe", "role": "admin"]], "isAppAdmin": true])
        // Hors ligne : la dernière liste est GARDÉE et le cache n'est pas écrasé.
        fake.intercept = { _ in throw CloudError.network("x") }
        await engine.loadProfile()
        XCTAssertEqual(engine.profile.libraries.count, 1)
        // Redémarrage : le cache restaure les bibliothèques avant tout réseau.
        let e2 = SyncEngine(auth: auth, local: local, store: store, scheduler: sched, clock: { T0 })
        e2.restoreProfileCache()
        XCTAssertEqual(e2.profile.libraries.first?.role, .admin)
        XCTAssertTrue(e2.profile.canEdit(scope: "L1"))
        XCTAssertFalse(e2.profile.canEdit(scope: "L2"))
        XCTAssertTrue(e2.profile.canEdit(scope: nil))
        e2.resetAuthState()
        XCTAssertNil(local.global[GlobalKeys.profile(uid)])
    }

    @MainActor func testCanReturnToAnonUsesSyncInitMarker() async throws {
        await boot()
        XCTAssertFalse(engine.accountEverSynced())
        markInitDone()
        XCTAssertTrue(engine.accountEverSynced())
    }

    @MainActor func testStatusStrings() async throws {
        await boot()
        XCTAssertEqual(SyncStatus.error.state.tooltip, "Cliquer pour voir le détail de l'erreur")
        XCTAssertEqual(SyncStatus.pending.state.icon, "lock")
        XCTAssertEqual(SyncStatus.offline.state.icon, "pause")
        XCTAssertEqual(SyncStatus.synced.accountLine(lastSyncAt: Date(timeIntervalSince1970: 3600 * 14 + 5 * 60).timeIntervalSince1970 * 1000,
                                                     timeZone: TimeZone(identifier: "UTC")!), "Synchronisé · 14:05")
        XCTAssertEqual(SyncStatus.error.accountLine(lastSyncAt: 1), "Erreur de synchro")
        XCTAssertEqual(SyncStatus.pending.homeBanner(lastError: nil)?.bold, "Compte en attente de validation")
        XCTAssertEqual(SyncStatus.error.homeBanner(lastError: SyncErrorTexts.server)?.rest, " — Service indisponible · Nouvelle tentative automatique en cours")
    }

    @MainActor func testEditDuringPushStaysDirty() async throws {
        await boot()
        markInitDone()
        put(fiche("f1", title: "Avant", updatedAt: T0, dirty: true))
        let s = store!
        let edited = fiche("f1", title: "Pendant l'envoi", updatedAt: T0 + 7, dirty: true)
        fake.intercept = { r in
            // L'utilisateur modifie la fiche PENDANT la requête de push.
            if r.method == "POST" && r.url.path == "/rest/v1/cognitive_aids" { try? s.fiches.put("f1", edited) }
            return nil
        }
        await engine.full()
        XCTAssertEqual(store.fiches.get("f1")?["title"], "Pendant l'envoi")
        XCTAssertEqual(store.fiches.get("f1")?["dirty"], true, "la version tapée pendant l'envoi repartira")
        fake.intercept = nil
        await engine.full()
        XCTAssertEqual(fake.row("cognitive_aids", "f1")?["data"]?["title"], "Pendant l'envoi")
        XCTAssertEqual(store.fiches.get("f1")?["dirty"], false)
    }

    @MainActor func testExpiredSessionMapsTo401Message() async throws {
        await boot()
        fake.intercept = { r in r.url.path.hasSuffix("/memberships") || r.url.path.contains("cognitive_aids") ? HTTPResponse(status: 401, body: Data("JWT expired".utf8)) : nil }
        await engine.full()
        XCTAssertEqual(engine.status, .error)
        XCTAssertEqual(engine.lastError?.title, "Session expirée")
        XCTAssertEqual(engine.lastErrorAt, T0)
        XCTAssertEqual(sched.pendingDelays, [5000])
        XCTAssertEqual(engine.status.homeBanner(lastError: engine.lastError)?.rest, " — Session expirée · Nouvelle tentative automatique en cours")
    }

    @MainActor func testUsageBumpThrottlesPrefsPush() async throws {
        await boot()
        engine.bumpUsage("f1")
        XCTAssertEqual(engine.prefs.usage["f1"], Usage(n: 1, t: T0))
        XCTAssertTrue(engine.prefs.catsDirty(""))
        engine.prefs.remove(SpaceKeys.catsDirty(""))
        clock.mutate { $0 += 60_000 }
        engine.bumpUsage("f1")
        XCTAssertEqual(engine.prefs.usage["f1"]?.n, 2)
        XCTAssertFalse(engine.prefs.catsDirty(""), "au plus une poussée toutes les 10 minutes")
    }
}
