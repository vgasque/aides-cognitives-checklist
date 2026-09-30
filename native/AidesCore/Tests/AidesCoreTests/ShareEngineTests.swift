import XCTest
@testable import AidesCore

/// Machines à états du partage : faux transport, fausse horloge.
final class ShareEngineTests: XCTestCase {

    @MainActor
    func testHostEmitsFullStateAndGuestFolds() async throws {
        let (_, hub, host, hostD, guest, guestD) = try await makeDirectPair()
        XCTAssertEqual(host.mode, .host); XCTAssertEqual(host.role, "lead")
        // « rembobinage initial » : tout l'état courant en évènements, AUCUN libellé.
        let kinds = host.queue.map { $0["kind"]!.string! }
        XCTAssertEqual(kinds, ["check", "counter", "timer_arm", "mark", "nav", "session_start"])
        XCTAssertFalse(host.queue.map { $0.text() }.joined().contains("MOT PRIVÉ"), "règle 15 : aucun texte libre ne traverse")
        XCTAssertEqual(host.queue.last?["payload"]?["id"]?.string, "s-host")
        for e in host.queue { XCTAssertNotNil(ShareJS.isoMs(e["ts"]!.string!)); XCTAssertEqual(e["event_id"]!.string!.count, 36) }
        await host.cycle()
        XCTAssertEqual(host.queue.count, 0)
        XCTAssertEqual(hub.events.count, 6)
        // L'invité tire le journal, plie, applique, et reste EN ACCORD (compte + empreinte).
        await guest.cycle()
        XCTAssertEqual(guest.applied, 6); XCTAssertEqual(guest.cursor, 6)
        XCTAssertTrue(guestD.desyncs.isEmpty)
        XCTAssertEqual(guest.fold?["checked"]?["1:b1:0"], true)
        XCTAssertEqual(guest.fold?["sessId"]?.string, "s-host")
        XCTAssertEqual(guestD.runtime["counters"]?["c1"], 2)
        XCTAssertEqual(guestD.runtime["timers"]?["t1"]?["running"], true)
        XCTAssertEqual(guestD.runtime["events"]?[0]?["label"], nil, "un repère reçu n'a pas de libellé")
        XCTAssertEqual(ShareCore.stateHash(guest.fold!), ShareCore.stateHash(ShareCore.fold(hub.events)))
        XCTAssertTrue(guestD.announces.contains(ShareStrings.actions(6)))
        XCTAssertEqual(guest.quaiTag, "suit")
        // L'hôte voit l'invité présent.
        await host.cycle()
        XCTAssertEqual(host.quaiTag, "⇄1")
        XCTAssertEqual(host.quaiLabel(exercise: false, sayWord: nil), "● Partagé · ⇄1")
        _ = hostD
    }

    @MainActor
    func testGuestGestureReachesHostWithoutEcho() async throws {
        let (_, _, host, hostD, guest, guestD) = try await makeDirectPair()
        await host.cycle(); await guest.cycle()
        // L'invité coche : diff contre sa base (posée par la rebase de l'application).
        var o = guestD.runtime.object!
        var ch = o["checked"]!.object!; ch["1:b1:1"] = true; o["checked"] = .object(ch)
        let rt = JSON.object(o)
        guestD.runtime = rt
        XCTAssertEqual(guest.emitDiff(snapshot: ShareCore.snap(rt, flowEnded: false), sessionId: nil), 1)
        XCTAssertEqual(guest.lastKickMs, 250)
        await guest.cycle()
        await host.cycle()
        XCTAssertEqual(hostD.runtime["checked"]?["1:b1:1"], true)
        // Pas d'écho : la base de l'hôte suit ce qu'il vient d'appliquer.
        XCTAssertEqual(host.emitDiff(snapshot: ShareCore.snap(hostD.runtime, flowEnded: false), sessionId: "s-host"), 0)
    }

    @MainActor
    func testScribeCannotUncheckAndRefusalResyncs() async throws {
        let (_, _, _, _, guest, guestD) = try await makeDirectPair()
        await guest.cycle()
        XCTAssertNil(guest.emit("uncheck", ["k": "1:b1:0"]))
        XCTAssertEqual(guestD.desyncs, ["geste refusé"])
        XCTAssertEqual(guest.cursor, 0, "le miroir se refait depuis zéro")
        XCTAssertEqual(guest.refusal(forKind: "uncheck"), ShareStrings.refuseUncheck)
        XCTAssertEqual(guest.refusal(forKind: "timer_reset"), ShareStrings.refuseLeadOnly)
        XCTAssertNil(guest.refusal(forKind: "check"))
    }

    @MainActor
    func testLeadHandoverThreeSteps() async throws {
        let (_, hub, host, hostD, guest, guestD) = try await makeDirectPair()
        await host.cycle(); await guest.cycle(); await host.cycle()
        let gid = guest.me!
        XCTAssertTrue(host.offerLead(gid))
        await host.cycle(); await guest.cycle()
        XCTAssertTrue(guest.hoOffer); XCTAssertEqual(guest.quaiTag, "offert")
        XCTAssertTrue(guest.takeLead())
        XCTAssertTrue(guestD.announces.contains(ShareStrings.tookLead))
        await guest.cycle()
        await host.cycle()
        // L'inscription est asynchrone (non attendue) : laisser la tâche s'exécuter.
        for _ in 0..<5 { await Task.yield() }
        XCTAssertEqual(host.role, "scribe")
        XCTAssertEqual(hub.parts.first { $0.owner }?.role, "scribe", "rétrograder d'abord…")
        XCTAssertEqual(hub.parts.first { $0.id == gid }?.role, "lead", "…promouvoir ensuite")
        await guest.cycle()
        XCTAssertEqual(guest.role, "lead"); XCTAssertEqual(guest.quaiTag, "main")
        XCTAssertTrue(hostD.announces.contains(ShareStrings.gaveLead))
        // Reprendre la main.
        await host.cycle()
        let ok = await host.reclaimLead(gid)
        XCTAssertTrue(ok); XCTAssertEqual(host.role, "lead")
        await guest.cycle()
        XCTAssertTrue(guestD.announces.contains(ShareStrings.leadReturnedToHost) || guest.role == "lead",
                      "la PWA ne rétrograde pas l'autre (spec § 20.7)")
    }

    @MainActor
    func testRevokeMakesGuestFail() async throws {
        let (_, _, host, _, guest, guestD) = try await makeDirectPair()
        await host.cycle(); await guest.cycle(); await host.cycle()
        let ok = await host.revoke(guest.me!)
        XCTAssertTrue(ok)
        await guest.cycle()
        XCTAssertEqual(guestD.failures, 1, "hub : un coupé reçoit err:'auth' (vu comme une panne — spec § 20.4)")
        XCTAssertEqual(guest.fails, 1)
        await host.cycle()
        XCTAssertEqual(host.participantState(host.participants.first { !ShareJS.truthy($0["owner"]) }!).word, "coupé")
    }

    @MainActor
    func testDetachConvertsQueueToAnnex() async throws {
        let (_, hub, _, _, guest, _) = try await makeDirectPair()
        await guest.cycle()
        guest.emit("check", ["k": "1:b1:2"])
        guest.emit("mark", ["id": "e5", "t": 5, "ref": ["type": "timer", "id": "t1"]])
        let pending = guest.queue
        // Le détachement pousse `detach` directement, puis convertit la file (le hub, lui, ne
        // marque pas le participant détaché — écart documenté).
        _ = await guest.detach()
        XCTAssertEqual(guest.status, "detached")
        XCTAssertEqual(guest.queue.map { $0["kind"]!.string! }, ["offline_mark", "offline_mark"])
        XCTAssertEqual(guest.queue[1]["payload"]?["was"]?.string, "mark")
        XCTAssertEqual(guest.queue[1]["payload"]?["ref"]?["type"]?.string, "timer")
        XCTAssertEqual(guest.queue[0]["ts"], pending[0]["ts"])
        XCTAssertNotEqual(guest.queue[0]["event_id"], pending[0]["event_id"])
        XCTAssertEqual(guest.lastKickMs, 2000)
        XCTAssertTrue(hub.events.contains { $0["kind"]?.string == "detach" })
        XCTAssertTrue(guest.canWrite("check") == false)
    }

    @MainActor
    func testStreamHashMismatchResyncs() async throws {
        let env = ManualEnv()
        let io = ScriptedIO()
        let e = ShareEngine(env: env, restIO: io)
        let d = RuntimeDelegate(runtime: sampleRuntime(), fiche: sampleFiche())
        e.delegate = d
        io.joinReply = ["ok": true, "share": "sh1", "me": "p2", "secret": "0123456789abcdef0123", "role": "scribe", "fiche": sampleFiche(),
                        "server_time": .string(ShareJS.isoString(env.t))]
        _ = try await e.joinByCode("k7m2-qx9p ", label: nil)
        XCTAssertEqual(io.lastJoin?.code, "K7M2-QX9P", "majuscules et espaces retirés ; le tiret est la saisie telle quelle")
        XCTAssertEqual(io.lastJoin?.label, "Invité")
        io.pulls = [["ok": true, "status": "active", "role": "scribe", "me": "p2", "seq": 2, "n_events": 2, "stream": "faux",
                     "events": [["seq": 1, "id": "u1", "actor": "p1", "kind": "check", "payload": ["k": "1:b1:3"], "ts": "2026-09-30T12:00:00Z"],
                                ["seq": 2, "id": "u2", "actor": "p1", "kind": "check", "payload": ["k": "1:b1:4"], "ts": "2026-09-30T12:00:00Z"]],
                     "participants": [], "server_time": .string(ShareJS.isoString(env.t))]]
        await e.cycle()
        XCTAssertEqual(d.desyncs, ["empreinte"])
        XCTAssertEqual(e.cursor, 0)
        // Le compte faux se voit aussi (trous comblés par `seq`).
        io.pulls = [["ok": true, "status": "active", "seq": 5, "n_events": 3, "events": [], "participants": [],
                     "stream": .string(ShareSHA256.hex(""))]]
        e.resetResyncForTest()
        await e.cycle()
        XCTAssertEqual(e.cursor, 0)
        XCTAssertEqual(d.desyncs.last, "compte")
    }

    @MainActor
    func testCadenceAndStaleness() async throws {
        let env = ManualEnv()
        let e = ShareEngine(env: env, restIO: ScriptedIO())
        final class D: ShareEngineDelegate { var crisis = false; var hidden = false
            func shareCrisisOnScreen(_ engine: ShareEngine) -> Bool { crisis }
            func shareIsHidden(_ engine: ShareEngine) -> Bool { hidden } }
        let d = D(); e.delegate = d
        e.actForTest(env.t)
        XCTAssertEqual(e.baseMs(), 2000)
        env.t += 60_000; XCTAssertEqual(e.baseMs(), 5000)
        env.t += 120_000; XCTAssertEqual(e.baseMs(), 10000)
        d.crisis = true; XCTAssertEqual(e.baseMs(), 5000)
        d.hidden = true; XCTAssertEqual(e.baseMs(), 15000)
        d.hidden = false
        XCTAssertEqual(e.staleLimit, 12500)
        env.rnd = 0.5; XCTAssertEqual(e.delayMs(), 5000)
        e.failsForTest(3); XCTAssertEqual(e.delayMs(), 16000)
        e.failsForTest(9); XCTAssertEqual(e.delayMs(), 30000)
        env.rnd = 0; XCTAssertEqual(e.delayMs(), 24000)
    }

    @MainActor
    func testCristianOffsetMedian() async throws {
        let env = ManualEnv()
        let io = ScriptedIO()
        let e = ShareEngine(env: env, restIO: io)
        io.joinReply = ["ok": true, "share": "sh1", "me": "p2", "secret": "0123456789abcdef0123", "role": "scribe", "fiche": sampleFiche(),
                        "server_time": .string(ShareJS.isoString(env.t + 3000))]
        _ = try await e.joinByCode("K7M2QX9P", label: "IDE")
        XCTAssertEqual(e.offset, 3000, "rtt nul : décalage = serveur − local")
        XCTAssertEqual(e.now(), env.t + 3000)
        // Un échantillon trop lent (> 400 ms) est ignoré.
        io.env = env
        io.pullDelay = 900
        io.pulls = [["ok": true, "status": "active", "seq": 0, "n_events": 0, "events": [], "participants": [],
                     "server_time": .string(ShareJS.isoString(env.t + 9000))]]
        await e.cycle()
        XCTAssertEqual(e.offset, 3000)
    }

    @MainActor
    func testGuestTicketAndResume() async throws {
        let env = ManualEnv()
        let io = ScriptedIO()
        let tickets = MemoryShareTicketStore()
        let e = ShareEngine(env: env, restIO: io, tickets: tickets)
        io.joinReply = ["ok": true, "share": "sh1", "me": "p2", "secret": "0123456789abcdef0123", "role": "scribe", "fiche": sampleFiche()]
        _ = try await e.joinByCode("K7M2QX9P", label: "IDE")
        XCTAssertEqual(tickets.get("ac-share-tk"), ["s": "sh1", "k": "0123456789abcdef0123", "m": "p2", "r": "scribe"])
        // Rechargement : un moteur neuf reprend par le billet, depuis zéro.
        let e2 = ShareEngine(env: env, restIO: io, tickets: tickets)
        XCTAssertEqual(ShareBoot.decide(guestTicket: e2.guestTicket, cloudTicket: nil, fragment: "#j=K7M2QX9P"), .resumeGuest)
        io.pulls = [["ok": true, "status": "active", "role": "scribe", "me": "p2", "fiche": sampleFiche(), "seq": 1, "n_events": 1,
                     "events": [["seq": 1, "id": "u1", "actor": "p1", "kind": "session_start", "payload": ["t": 5, "id": "s-host"]]], "participants": []]]
        let ok = await e2.resume()
        XCTAssertTrue(ok)
        XCTAssertEqual(io.lastPull?.since, 0); XCTAssertEqual(io.lastPull?.secret, "0123456789abcdef0123")
        XCTAssertEqual(e2.fold?["sessId"]?.string, "s-host"); XCTAssertEqual(e2.cursor, 1)
        // Refus : le billet meurt.
        io.pulls = [["ok": false, "err": "refused"]]
        let e3 = ShareEngine(env: env, restIO: io, tickets: tickets)
        let ok3 = await e3.resume()
        XCTAssertFalse(ok3)
        XCTAssertNil(tickets.get("ac-share-tk"))
        XCTAssertEqual(ShareBoot.decide(guestTicket: nil, cloudTicket: nil, fragment: "#j=k7m2-qx9p"), .join(code: "K7M2QX9P"))
    }

    @MainActor
    func testFreezeOnStatusAndSoloLead() async throws {
        let env = ManualEnv()
        let io = ScriptedIO()
        let e = ShareEngine(env: env, restIO: io)
        let d = RuntimeDelegate(runtime: sampleRuntime(), fiche: sampleFiche())
        e.delegate = d
        io.joinReply = ["ok": true, "share": "sh1", "me": "p2", "secret": "0123456789abcdef0123", "role": "lead", "fiche": sampleFiche()]
        _ = try await e.joinByCode("K7M2QX9P", label: "IDE")
        e.emit("check", ["k": "1:b1:0"])
        io.pushReply = ["ok": false, "err": "ended", "status": "ended"]
        io.pulls = [["ok": true, "status": "ended", "role": "lead", "seq": 0, "n_events": 0, "events": [], "participants": []]]
        await e.cycle()
        XCTAssertEqual(e.status, "ended"); XCTAssertTrue(e.soloLead)
        XCTAssertTrue(e.queue.isEmpty, "file jetée : elle ne sera jamais délivrée")
        XCTAssertFalse(e.isFrozenGuest, "le conducteur garde son écran")
        XCTAssertEqual(e.quaiTag, "fini")
        XCTAssertEqual(d.statuses.first?.0, "ended")
    }

    @MainActor
    func testRESTWireFormat() async throws {
        let http = FakeHTTP()
        let cfg = ShareCloudConfig(url: "https://x.supabase.co", publishableKey: "sb_publishable_K")
        let io = ShareRESTIO(config: cfg, http: http, clock: { 1_727_697_600_000 }, accessToken: { "JWT" })
        http.respond = { r in
            r.method == "PATCH" ? ShareHTTPResponse(status: 204, contentType: "", body: Data())
                : ShareHTTPResponse(status: 200, contentType: "application/json; charset=utf-8", body: Data("{\"ok\":true}".utf8))
        }
        _ = try await io.pull(secret: nil, share: "sh 1", since: 7)
        var r = http.requests.last!
        XCTAssertEqual(r.method, "POST"); XCTAssertEqual(r.url, "https://x.supabase.co/rest/v1/rpc/share_pull")
        XCTAssertEqual(r.headers["apikey"], "sb_publishable_K"); XCTAssertEqual(r.headers["Authorization"], "Bearer JWT")
        XCTAssertEqual(r.headers["Content-Type"], "application/json")
        XCTAssertEqual(try JSON.parse(r.body!), ["p_secret": .null, "p_share": "sh 1", "p_since": 7])
        _ = try await io.revoke(share: "sh 1", pid: "a/b")
        r = http.requests.last!
        XCTAssertEqual(r.method, "PATCH")
        XCTAssertEqual(r.url, "https://x.supabase.co/rest/v1/session_participants?share_id=eq.sh%201&participant=eq.a%2Fb")
        XCTAssertEqual(r.headers["Prefer"], "return=minimal")
        XCTAssertEqual(try JSON.parse(r.body!), ["revoked_at": "2024-09-30T12:00:00.000Z"])
        _ = try await io.end(share: "sh1")
        XCTAssertEqual(try JSON.parse(http.requests.last!.body!), ["status": "ended", "expires_at": "2024-09-30T12:00:00.000Z"])
        _ = try await io.open(id: "sh1", sessionId: "s1", ficheId: "f1", snap: ["id": "f1"], guestRole: "scribe", ttlMin: 180)
        XCTAssertEqual(try JSON.parse(http.requests.last!.body!),
                       ["p_id": "sh1", "p_session_id": "s1", "p_fiche_id": "f1", "p_fiche_snap": ["id": "f1"], "p_guest_role": "scribe", "p_ttl_min": 180])
        // Anonyme : Bearer = clé publiable. Non-2xx : exception (cycle raté).
        let anon = ShareRESTIO(config: cfg, http: http)
        http.respond = { _ in ShareHTTPResponse(status: 401, contentType: "application/json", body: Data("{}".utf8)) }
        do { _ = try await anon.join(code: "K7M2QX9P", label: "IDE"); XCTFail("doit lever") } catch let e as ShareError {
            XCTAssertEqual(e, .http(401, "{}"))
        }
        XCTAssertEqual(http.requests.last!.headers["Authorization"], "Bearer sb_publishable_K")
        // Sonde : GET /auth/v1/health, tout statut = joignable.
        http.respond = { _ in ShareHTTPResponse(status: 503) }
        let up = await ShareNetProbe.probe(config: cfg, http: http)
        XCTAssertTrue(up)
        XCTAssertEqual(http.requests.last!.method, "GET"); XCTAssertEqual(http.requests.last!.url, "https://x.supabase.co/auth/v1/health")
        http.respond = { _ in throw ShareError.timeout }
        let down = await ShareNetProbe.probe(config: cfg, http: http)
        XCTAssertFalse(down)
    }

    @MainActor
    func testHostCloudFlowWithScriptedServer() async throws {
        let env = ManualEnv()
        let io = ScriptedIO()
        let tickets = MemoryShareTicketStore()
        let e = ShareEngine(env: env, restIO: io, tickets: tickets)
        let d = RuntimeDelegate(runtime: sampleRuntime(), fiche: sampleFiche())
        e.delegate = d
        let refused = await e.host(fiche: sampleFiche(), sessionId: "s1", snapshot: nil)
        XCTAssertEqual(refused["err"], "not_started")
        io.openReply = ["ok": true, "share": "shX", "code": "K7M2QX9P", "join_open_until": .string(ShareJS.isoString(env.t + 120_000)),
                        "expires_at": .string(ShareJS.isoString(env.t + 3 * 3600_000)), "server_time": .string(ShareJS.isoString(env.t))]
        let r = await e.host(fiche: sampleFiche(), sessionId: "s1", snapshot: ShareCore.snap(d.runtime, flowEnded: false))
        XCTAssertEqual(r["ok"], true)
        XCTAssertEqual(io.lastOpen?.snap["blocks"]?[0]?["image"], nil, "image retirée des blocs")
        XCTAssertNil(io.lastOpen?.snap["category"]); XCTAssertEqual(io.lastOpen?.guestRole, "scribe"); XCTAssertEqual(io.lastOpen?.ttl, 180)
        XCTAssertEqual(e.doorOpenMs, 120_000)
        XCTAssertEqual(e.hostTicket?.share, "shX"); XCTAssertEqual(e.hostTicket?.ficheId, "f1")
        // Un participant apparaît : le code est mort (consommé par share_join).
        io.pushReply = ["ok": true, "accepted": 6, "rejected": 0, "seq": 6, "status": "active"]
        io.pulls = [["ok": true, "status": "active", "role": "lead", "seq": 6, "n_events": 0, "events": [],
                     "participants": [["id": "o", "owner": true, "role": "lead", "seen": .string(ShareJS.isoString(env.t))],
                                      ["id": "g1", "label": "IDE", "owner": false, "role": "scribe", "seen": .string(ShareJS.isoString(env.t))]]]]
        await e.cycle()
        XCTAssertNil(e.code); XCTAssertEqual(e.codeTakenBy, "IDE")
        XCTAssertTrue(d.announces.contains("IDE a rejoint la session."))
        XCTAssertEqual(io.lastPush?.count, 6)
        // Silence : « sans nouvelles » après 45 s, « absent » après 3 min.
        env.t += 60_000
        XCTAssertEqual(e.participantState(e.participants[1]).quietMin, 1)
        env.t += 150_000
        XCTAssertEqual(e.participantState(e.participants[1]).word, "absent")
        XCTAssertEqual(e.quaiTag, "figé", "210 s sans sondage réussi : figé")
        // Arrêt : PATCH end, billet effacé, moteur éteint.
        let ok = await e.endShare()
        XCTAssertTrue(ok); XCTAssertEqual(io.ended, ["shX"]); XCTAssertEqual(e.mode, .off); XCTAssertNil(e.hostTicket)
    }
}

/// Serveur scénarisé : rend les réponses préparées par le test.
@MainActor
final class ScriptedIO: ShareIO {
    nonisolated var kind: ShareIOKind { .rest }
    var joinReply: JSON = ["ok": false, "err": "refused"]
    var openReply: JSON = ["ok": false, "err": "refused"]
    var pushReply: JSON = ["ok": true]
    var pulls: [JSON] = []
    var pullDelay: Double = 0
    var lastJoin: (code: String, label: String)?
    var lastOpen: (snap: JSON, guestRole: String, ttl: Int)?
    var lastPull: (secret: String?, since: Int)?
    var lastPush: [JSON]?
    var ended: [String] = []
    var env: ManualEnv?
    func open(id: String, sessionId: String, ficheId: String, snap: JSON, guestRole: String, ttlMin: Int) async throws -> JSON { lastOpen = (snap, guestRole, ttlMin); return openReply }
    func admit(share: String, seconds: Int) async throws -> JSON { ["ok": true, "code": "ZZZZ2222"] }
    func join(code: String, label: String) async throws -> JSON { lastJoin = (code, label); return joinReply }
    func pull(secret: String?, share: String?, since: Int) async throws -> JSON {
        lastPull = (secret, since)
        env?.t += pullDelay
        return pulls.isEmpty ? ["ok": false] : pulls.removeFirst()
    }
    func push(secret: String?, share: String?, events: [JSON]) async throws -> JSON { lastPush = events; return pushReply }
    func revoke(share: String, pid: String) async throws -> JSON { .null }
    func setRole(share: String, pid: String, role: String) async throws -> JSON { .null }
    func end(share: String) async throws -> JSON { ended.append(share); return .null }
}
