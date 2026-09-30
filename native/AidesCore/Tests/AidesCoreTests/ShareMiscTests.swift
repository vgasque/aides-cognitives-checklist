import XCTest
@testable import AidesCore

final class ShareMiscTests: XCTestCase {
    func testDeflateRoundTripAndBound() throws {
        var g = SystemRandomNumberGenerator()
        for n in [0, 1, 2, 3, 100, 5000, 70_000] {
            let rand = (0..<n).map { _ in UInt8.random(in: 0...255, using: &g) }
            let text = Array(String(repeating: "{\"k\":\"1:b1:0\",\"v\":true},", count: n / 20 + 1).utf8)
            for d in [rand, text] {
                XCTAssertEqual(try ShareDeflate.inflate(ShareDeflate.deflate(d)), d)
            }
        }
        let big = ShareDeflate.deflate([UInt8](repeating: 65, count: 100_000))
        XCTAssertLessThan(big.count, 2000, "LZ77 effectif sur les répétitions")
        XCTAssertThrowsError(try ShareDeflate.inflate(big, limit: 50_000)) { XCTAssertEqual($0 as? ShareDeflate.Failure, .tooLarge) }
        XCTAssertThrowsError(try ShareDeflate.inflate([0xff, 0xff, 0xff]))
    }

    func testSHA256Vectors() {
        XCTAssertEqual(ShareSHA256.hex(""), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual(ShareSHA256.hex("1:3f2c1a9e-0000-4000-8000-000000000001,2:3f2c1a9e-0000-4000-8000-000000000002"),
                       "6ec9c0f4e2db9a22f0d063c204ce1b4951568174e9b2a7893192d3cf585bb3e5")
        XCTAssertEqual(ShareSHA256.hex(String(repeating: "a", count: 1_000)), "41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3")
    }

    func testUUIDv4Format() {
        for _ in 0..<50 {
            let u = ShareJS.uuidV4()
            let p = u.split(separator: "-").map(String.init)
            XCTAssertEqual(p.map(\.count), [8, 4, 4, 4, 12])
            XCTAssertEqual(p[2].first, "4")
            XCTAssertTrue("89ab".contains(p[3].first!))
            XCTAssertEqual(u, u.lowercased())
        }
        XCTAssertEqual(ShareHub.newSecret([0, 30, 31, 255]), "A9AH", "slSecret : octet % 31")
    }

    func testOpticalRoundTripWithLossAndAcceptance() throws {
        let snap = ShareCore.snap(sampleRuntime(), flowEnded: false)
        let z = ShareOptical.packSnapshot(sess: "s-host", fiche: ShareCore.payload(sampleFiche()), at: 1_727_697_600_000, snap: snap)
        let tx = ShareOptical.transmitter(payload: z, isReturn: false)
        let rx = ShareFountain.Receiver()
        var res = ShareFountain.Feed.ignored, pos = 0
        while res != .done && pos < 10 * tx.cycle {
            let f = tx.frame(at: pos)
            XCTAssertEqual(f.count, 213)
            if pos % 3 != 0 { res = rx.feed(f) }   // une trame sur trois perdue
            pos += 1
        }
        XCTAssertEqual(res, .done)
        XCTAssertTrue(rx.h4Matches)
        XCTAssertEqual(rx.feed(tx.frame(index: 0)), .dup)
        XCTAssertEqual(rx.feed([1, 2, 3]), .ignored)
        let o = try XCTUnwrap(ShareOptical.unpack(rx.bytes()!))
        XCTAssertEqual(o["sess"]?.string, "s-host")
        let fold = ShareOptical.mirrorFold(snap: o["snap"], guestQueue: [["kind": "check", "payload": ["k": "4:b2:0"]]], me: "me")
        XCTAssertEqual(fold["checked"]?["4:b2:0"], true)
        XCTAssertEqual(fold["timers"]?["t1"]?["running"], true)
        XCTAssertFalse(o.text().contains("MOT PRIVÉ"), "aucun libellé ne traverse, même par l'écran")
        // Acceptation : une AUTRE session est refusée, zéro écriture.
        XCTAssertEqual(ShareOptical.acceptSnapshot(sess: "s-host", deviceHasStartedRuntime: false, mirrorSess: nil, guestFoldSessId: nil), .accept)
        XCTAssertEqual(ShareOptical.acceptSnapshot(sess: "s-host", deviceHasStartedRuntime: true, mirrorSess: nil, guestFoldSessId: "s-host"), .accept)
        XCTAssertEqual(ShareOptical.acceptSnapshot(sess: "s-host", deviceHasStartedRuntime: true, mirrorSess: "autre", guestFoldSessId: nil),
                       .refuse(ShareStrings.opticOtherSession))
        // Retour : repères datés seulement.
        let rz = ShareOptical.packReturn(sess: "s-host", at: 5, events: [["id": "e7", "t": 9, "ref": .null, "voidAt": 12, "label": "MOT"], ["t": 1]])
        let ro = try XCTUnwrap(ShareOptical.unpack(rz))
        XCTAssertTrue(ShareOptical.acceptReturn(sess: ro["sess"]!.string!, localSessionId: "s-host"))
        XCTAssertFalse(ShareOptical.acceptReturn(sess: "x", localSessionId: "s-host"))
        let evs = ShareOptical.returnEvents(ro["ret"]!.array!)
        XCTAssertEqual(evs.map { $0["kind"]!.string! }, ["mark", "mark_void"])
        XCTAssertEqual(evs[0]["actor"], "optique")
        XCTAssertNil(ShareOptical.unpack(ShareDeflate.deflate(Array("{\"at\":\"x\",\"ret\":[]}".utf8))), "`at` doit être un nombre")
        XCTAssertNil(ShareOptical.unpack(ShareDeflate.deflate(Array("{\"at\":1,\"snap\":{}}".utf8))), "instantané sans fiche")
    }

    func testScanRouting() {
        XCTAssertEqual(ShareScan.classify(text: nil, binary: [0xF7, 0, 1]), .opticalFrame)
        XCTAssertEqual(ShareScan.classify(text: "https://x.org/app/#j=k7m2-qx9p", binary: nil), .cloudCode("K7M2QX9P"))
        XCTAssertEqual(ShareScan.classify(text: "K7M2-QX9P", binary: nil), .cloudCode("K7M2QX9P"))
        XCTAssertEqual(ShareScan.classify(text: "SO:!!!", binary: nil), .unreadable(ShareStrings.codeIllisible))
        XCTAssertEqual(ShareScan.classify(text: "bonjour", binary: nil), .unknown)
        let p = SharePairing(k: "ab12", sdp: ShareSDPQuintuple(u: "u", p: "p", f: String(repeating: "0F", count: 32), s: "actpass", c: ["10.0.0.2~9"]))
        if case .directOffer(let o) = ShareScan.classify(text: p.qrText(offer: true), binary: nil) { XCTAssertEqual(o, p) } else { XCTFail() }
        XCTAssertEqual(ShareCode.joinURL(webAppURL: "https://aides.example.org/app/index.html#vieux", code: "K7M2QX9P"),
                       "https://aides.example.org/app/index.html#j=K7M2QX9P")
        XCTAssertNil(ShareCode.joinURL(webAppURL: "file:///x.html", code: "K7M2QX9P"))
    }

    @MainActor
    func testRPCClientTimesOutWithoutReply() async throws {
        let env = ManualEnv()
        let pair = ShareWirePair()
        pair.b.closed = true   // l'hôte ne répond jamais
        let cli = ShareRPCClient(wire: pair.a, env: env)
        async let r: JSON = cli.pull(secret: "s", share: nil, since: 0)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(pair.a.sent.count, 1)
        XCTAssertEqual(try JSON.parse(pair.a.sent[0]), ["i": 1, "n": "pull", "p": ["secret": "s", "since": 0]])
        env.advance(8001)
        do { _ = try await r; XCTFail("doit expirer") } catch { XCTAssertEqual(error as? ShareError, .timeout) }
        // Verbe inconnu et paramètres illisibles côté serveur.
        let hub = ShareHub.make(fiche: sampleFiche())
        let w = ShareWirePair()
        ShareRPCServer.serve(hub, on: w.a)
        var got: [String] = []
        w.b.onMessage = { got.append($0) }
        w.b.send("{\"i\":7,\"n\":\"drop\",\"p\":{}}")
        w.b.send("{\"i\":8,\"n\":\"pull\"}")
        w.b.send(ShareRPC.bouee)
        XCTAssertEqual(got.map { try? JSON.parse($0) }, [["i": 7, "e": "verbe"], ["i": 8, "e": "hub"]])
        keepAlive.append(hub)
    }

    @MainActor
    func testQuaiLabelAndTags() async throws {
        let env = ManualEnv()
        let e = ShareEngine(env: env, restIO: nil)
        XCTAssertEqual(e.quaiLabel(exercise: false, sayWord: nil), "● Session")
        XCTAssertEqual(e.quaiLabel(exercise: true, sayWord: "Passe en direct"), "▲ Exercice")
        XCTAssertEqual(e.quaiLabel(exercise: false, sayWord: "Passe en direct"), "● Passe en direct")
        XCTAssertEqual(ShareStrings.countdown(29_001), "encore 30 s")
        XCTAssertEqual(ShareStrings.joinRefusal(code: "A", refusedBefore: "A", scanned: true), ShareStrings.joinRefusedAgain)
        XCTAssertEqual(ShareStrings.unsentSummary(queue: [["kind": "check"], ["kind": "check"], ["kind": "mark_void"], ["kind": "nav"]])?.txt,
                       "2 coches, 1 repère, 1 autre")
        XCTAssertEqual(ShareStrings.roles.count, 9, "liste FERMÉE de neuf intitulés (règle 15)")
    }
}
