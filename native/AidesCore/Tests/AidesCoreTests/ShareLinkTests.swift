import XCTest
@testable import AidesCore

/// « Serveur » en ligne simulé par un hub (mêmes verbes, même sémantique de journal) ; `down`
/// simule une panne réseau (exception = cycle raté).
@MainActor
final class HubRestIO: ShareIO {
    nonisolated var kind: ShareIOKind { .rest }
    let hub: ShareHub
    var down = false
    init(hub: ShareHub) { self.hub = hub }
    func check() throws { if down { throw ShareError.transport("réseau coupé") } }
    func open(id: String, sessionId: String, ficheId: String, snap: JSON, guestRole: String, ttlMin: Int) async throws -> JSON {
        try check(); return ["ok": true, "share": .string(hub.shareId), "code": "K7M2QX9P", "server_time": .string(ShareJS.isoString(1_727_697_600_000))]
    }
    func admit(share: String, seconds: Int) async throws -> JSON { try check(); return ["ok": true, "code": "ZZZZ2222"] }
    func join(code: String, label: String) async throws -> JSON { try check(); return hub.join(label: label) }
    func pull(secret: String?, share: String?, since: Int) async throws -> JSON { try check(); return hub.pull(secret: secret ?? hub.hostSecret, since: Double(since)) }
    func push(secret: String?, share: String?, events: [JSON]) async throws -> JSON { try check(); return hub.push(secret: secret ?? hub.hostSecret, events: events) }
    func revoke(share: String, pid: String) async throws -> JSON { try check(); return hub.revoke(pid: pid) }
    func setRole(share: String, pid: String, role: String) async throws -> JSON { try check(); return hub.setRole(pid: pid, role: role) }
    func end(share: String) async throws -> JSON { try check(); return hub.end() }
}
@MainActor
final class FakeSource: ShareSessionSource {
    let d: RuntimeDelegate
    init(_ d: RuntimeDelegate) { self.d = d }
    var sharedFiche: JSON? { d.fiche }
    var sharedSessionId: String? { "s-host" }
    func sharedSnapshot() -> JSON? { ShareCore.snap(d.runtime, flowEnded: false) }
    var signedIn: Bool { true }
}

final class ShareLinkTests: XCTestCase {
    @MainActor func settle() async { for _ in 0..<30 { await Task.yield() } }

    /// Secours chaud complet : formation du canal dormant par `sig`, panne du serveur côté hôte,
    /// bascule en direct (bouée), puis retour AUTOMATIQUE en ligne sur le MÊME partage.
    @MainActor
    func testHotStandbyFailoverAndReturn() async throws {
        let env = ManualEnv()
        let cloud = ShareHub(.init(now: { env.t }, uid: { Guard.uid("p") }, secret: { ShareHub.newSecret() }, shareId: "sh-cloud", fiche: ShareCore.payload(sampleFiche())))
        let hostIO = HubRestIO(hub: cloud), guestIO = HubRestIO(hub: cloud)
        let net = FakeNet()
        var netUp = true
        // Hôte
        let host = ShareEngine(env: env, restIO: hostIO)
        let hostD = RuntimeDelegate(runtime: sampleRuntime(), fiche: sampleFiche())
        host.delegate = hostD
        let src = FakeSource(hostD)
        let hc = ShareLinkCoordinator(engine: host, env: env, source: src, stack: FakeStack(net: net), probe: { netUp })
        _ = await host.host(fiche: sampleFiche(), sessionId: "s-host", snapshot: src.sharedSnapshot())
        XCTAssertEqual(host.share, "sh-cloud")
        // Invité
        let guest = ShareEngine(env: env, restIO: guestIO)
        let guestD = RuntimeDelegate(runtime: ["checked": [:], "counters": ["c1": 0], "timers": [:], "events": [], "nav": ["b1"], "navSeq": [1]], fiche: sampleFiche())
        guest.delegate = guestD
        let gc = ShareLinkCoordinator(engine: guest, env: env, source: nil, stack: FakeStack(net: net), probe: { netUp })
        _ = try await guest.joinByCode("K7M2QX9P", label: "IDE")
        func pump(_ e: ShareEngine, _ c: ShareLinkCoordinator, _ d: RuntimeDelegate) async {
            let seen = d.signals.count, h = d.healthy
            await e.cycle()
            for s in d.signals.dropFirst(seen) { await c.onSignal(s) }
            if d.healthy > h { await c.guestKick() }
        }
        await pump(host, hc, hostD)
        await pump(guest, gc, guestD)          // sain → l'invité propose (sig o)
        await pump(guest, gc, guestD)          // pousse l'offre
        await pump(host, hc, hostD)            // l'hôte répond (sig a)
        await pump(host, hc, hostD)            // pousse la réponse
        await pump(guest, gc, guestD)          // l'invité accepte → canal ouvert, dormant
        XCTAssertTrue(hc.isReady); XCTAssertTrue(gc.isReady)
        XCTAssertEqual(hc.log.first?.txt, ShareStrings.sayStandbyReady)
        XCTAssertFalse(hc.link().lost)
        // Le geste d'invité avant la panne part au serveur.
        guest.emit("check", ["k": "1:b1:3"])
        // PANNE côté hôte : premier raté → la sonde tranche → bascule en direct, bouée criée.
        hostIO.down = true; netUp = false
        await host.cycle()
        XCTAssertEqual(host.fails, 1)
        await hc.onCycleFailed()
        await settle()
        XCTAssertEqual(host.share, "local"); XCTAssertTrue(hc.auto); XCTAssertTrue(hc.liveOk)
        XCTAssertEqual(hc.cloudHost?.share, "sh-cloud")
        XCTAssertEqual(hc.sayWord, ShareStrings.sayDirect)
        // L'invité a suivi la bouée : il sert désormais par le canal, sa file non transmise l'a suivi.
        XCTAssertEqual(guest.io.kind, .rpcClient)
        XCTAssertEqual(guest.share, hc.hub?.shareId)
        XCTAssertEqual(guest.cloudGuestTicket?.share, "sh-cloud")
        XCTAssertEqual(guest.queue.first?["payload"]?["k"]?.string, "1:b1:3")
        XCTAssertEqual(gc.sayWord, ShareStrings.sayFollowDirect)
        await guest.cycle(); await host.cycle()
        XCTAssertEqual(hostD.runtime["checked"]?["1:b1:3"], true, "le geste arrive par le direct")
        await guest.cycle()
        XCTAssertEqual(guest.fold?["checked"]?["1:b1:0"], true, "l'invité a reçu l'état complet rembobiné")
        // RETOUR : 3 sondes OK et ≥ 60 s en direct.
        netUp = true; hostIO.down = false
        for _ in 0..<3 { env.t += 25_000; await hc.probe(); await hc.backTick() }
        XCTAssertEqual(host.share, "sh-cloud", "le MÊME partage reprend")
        XCTAssertEqual(host.io.kind, .rest)
        XCTAssertFalse(hc.auto); XCTAssertEqual(hc.dwellMs, 120_000)
        XCTAssertTrue(cloud.events.contains { $0["payload"]?["k"]?.string == "1:b1:3" }, "les gestes du direct rejoignent le journal")
        // L'invité lit `sig rc` sur le hub (encore servi 20 s) et reprend SON billet cloud.
        await pump(guest, gc, guestD)
        XCTAssertEqual(guest.io.kind, .rest); XCTAssertEqual(guest.share, "sh-cloud")
        XCTAssertNil(guest.cloudGuestTicket)
        XCTAssertEqual(gc.sayWord, ShareStrings.sayBackOnline)
        keepAlive.append(cloud)
    }

    @MainActor
    func testLinkLostAndExpiredResume() async throws {
        let env = ManualEnv()
        let io = ScriptedIO()
        let e = ShareEngine(env: env, restIO: io)
        let c = ShareLinkCoordinator(engine: e, env: env, source: nil, probe: { false })
        io.joinReply = ["ok": true, "share": "sh1", "me": "p2", "secret": "0123456789abcdef0123", "role": "scribe", "fiche": sampleFiche()]
        _ = try await e.joinByCode("K7M2QX9P", label: "IDE")
        io.pulls = []   // tout sondage échoue
        await e.cycle(); await c.onCycleFailed()
        XCTAssertEqual(e.fails, 2, "premier raté + sonde muette : panne tranchée d'office")
        XCTAssertTrue(c.link().lost); XCTAssertEqual(c.link().why, .net)
        XCTAssertTrue(c.backArmed)
        // Invité en direct avec billet cloud expiré : « Partage expiré ».
        e.cloudGuestTicket = ShareGuestTicket(share: "old", secret: "0123456789abcdef0123", me: "p2", role: "scribe")
        io.pulls = [["ok": false, "err": "refused"]]
        let ok = await c.resumeCloud()
        XCTAssertFalse(ok); XCTAssertTrue(c.expired)
        XCTAssertEqual(c.link().why, .expired)
        XCTAssertEqual(c.log.first?.txt, ShareStrings.sayExpired)
    }

    @MainActor
    func testDirectPairingByQR() async throws {
        let env = ManualEnv()
        let net = FakeNet()
        let host = ShareEngine(env: env, restIO: nil)
        let hostD = RuntimeDelegate(runtime: sampleRuntime(), fiche: sampleFiche())
        host.delegate = hostD
        let src = FakeSource(hostD)
        let hc = ShareLinkCoordinator(engine: host, env: env, source: src, stack: FakeStack(net: net), probe: { false })
        let qr = await hc.offerPairing()
        XCTAssertTrue(qr?.hasPrefix("SO:") ?? false); XCTAssertEqual(hc.pairPhase, .offer)
        XCTAssertLessThan(qr!.count, 200, "un seul code QR")
        let guest = ShareEngine(env: env, restIO: nil)
        let guestD = RuntimeDelegate(runtime: ["checked": [:], "counters": ["c1": 0], "timers": [:], "events": [], "nav": ["b1"], "navSeq": [1]], fiche: sampleFiche())
        guest.delegate = guestD
        let gc = ShareLinkCoordinator(engine: guest, env: env, source: nil, stack: FakeStack(net: net), probe: { false })
        var joined: Bool?
        let answer = await gc.answerPairing(offerText: qr!, label: "Médecin") { joined = $0 }
        XCTAssertTrue(answer?.hasPrefix("SA:") ?? false)
        // Une réponse d'un appariement périmé est refusée.
        var stale = SharePairing.unpack(String(answer!.dropFirst(3)))!
        stale.k = "zzzz"
        let st = await hc.acceptPairingAnswer("SA:" + stale.pack()!)
        XCTAssertEqual(st, .stale)
        let ok = await hc.acceptPairingAnswer(answer!)
        XCTAssertEqual(ok, .connecting)
        await settle()
        XCTAssertEqual(joined, true)
        XCTAssertTrue(hc.liveOk); XCTAssertEqual(host.share, "local")
        XCTAssertEqual(guest.role, "scribe")
        await host.cycle(); await guest.cycle()
        XCTAssertEqual(guest.fold?["sessId"]?.string, "s-host")
        XCTAssertEqual(hc.hub?.parts.last?.label, "Médecin")
        await hc.stopDirect()
        XCTAssertEqual(host.mode, .off); XCTAssertNil(hc.hub)
    }
}
