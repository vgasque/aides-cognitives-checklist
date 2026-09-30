import XCTest
@testable import AidesCore

/// Environnement FACTICE : horloge manuelle, minuteries notées (jamais déclenchées d'elles-mêmes —
/// le test appelle `cycle()` ou `fireDue()`), attentes qui AVANCENT l'horloge.
@MainActor
final class ManualEnv: ShareEnvironment {
    var t: Double = 1_727_697_600_000
    var rnd = 0.5
    final class Item: ShareTimer {
        let due: Double; let fn: @MainActor () -> Void; var cancelled = false
        init(due: Double, fn: @escaping @MainActor () -> Void) { self.due = due; self.fn = fn }
        func cancel() { cancelled = true }
    }
    var items: [Item] = []
    func now() -> Double { t }
    func random() -> Double { rnd }
    func schedule(afterMs: Double, _ fn: @escaping @MainActor () -> Void) -> ShareTimer {
        let it = Item(due: t + afterMs, fn: fn); items.append(it); return it
    }
    func sleep(ms: Double) async { t += ms }
    /// Avance l'horloge et déclenche les minuteries échues (dans l'ordre d'échéance).
    func advance(_ ms: Double) {
        t += ms
        let due = items.filter { !$0.cancelled && $0.due <= t }.sorted { $0.due < $1.due }
        items.removeAll { $0.cancelled || $0.due <= t }
        for it in due { it.fn() }
    }
}

/// Délégué de test : tient une session JSON (forme du `Runtime` web) et y applique les lots par
/// `ShareApply`, comme le fera l'app.
@MainActor
final class RuntimeDelegate: ShareEngineDelegate {
    var runtime: JSON
    var fiche: JSON
    var announces: [String] = []
    var statuses: [(String, String)] = []
    var signals: [JSON] = []
    var desyncs: [String] = []
    var failures = 0, healthy = 0
    var shown = true
    weak var engine: ShareEngine?
    init(runtime: JSON, fiche: JSON) { self.runtime = runtime; self.fiche = fiche }
    func share(_ engine: ShareEngine, apply events: [JSON]) -> ShareApplyResult? {
        guard shown else { return nil }
        let p = ShareApply.partition(events, me: engine.me)
        var n = 0
        for e in p.live where ShareApply.stateLive(&runtime, e, serverNow: engine.now(), offset: engine.offset) { n += 1 }
        for e in p.anchored where e["kind"]?.string == "nav" { if ShareApply.navState(&runtime, e["payload"] ?? [:], fiche: fiche) != nil { n += 1 } }
        for e in p.deferred where ShareApply.vfState(&runtime, e) { n += 1 }
        return ShareApplyResult(painted: n)
    }
    func shareCurrentSnapshot(_ engine: ShareEngine) -> JSON? { ShareCore.snap(runtime, flowEnded: false) }
    func share(_ engine: ShareEngine, announce text: String) { announces.append(text) }
    func share(_ engine: ShareEngine, statusChanged new: String, from old: String) { statuses.append((new, old)) }
    func share(_ engine: ShareEngine, signal event: JSON) { signals.append(event) }
    func shareCycleFailed(_ engine: ShareEngine) { failures += 1 }
    func shareCycleHealthy(_ engine: ShareEngine) { healthy += 1 }
    func share(_ engine: ShareEngine, desync reason: String) { desyncs.append(reason) }
}

/// Transport HTTP factice : note chaque requête, répond par une fermeture.
final class FakeHTTP: ShareHTTP, @unchecked Sendable {
    var requests: [ShareHTTPRequest] = []
    var respond: (ShareHTTPRequest) throws -> ShareHTTPResponse = { _ in ShareHTTPResponse(status: 204, contentType: "", body: Data()) }
    func send(_ r: ShareHTTPRequest) async throws -> ShareHTTPResponse { requests.append(r); return try respond(r) }
}

/// Canal factice pour la pile directe (paire en mémoire, ouverture commandée par le test).
@MainActor
final class FakeChannel: ShareDataChannel {
    weak var peer: FakeChannel?
    var isOpen = false
    var onOpen: (() -> Void)?
    var onClose: (() -> Void)?
    var onMessage: ((String) -> Void)?
    var sent: [String] = []
    func send(_ text: String) { sent.append(text); if isOpen, let p = peer, p.isOpen { p.onMessage?(text) } }
    func close() { isOpen = false; onClose?() }
    static func pair() -> (FakeChannel, FakeChannel) { let a = FakeChannel(), b = FakeChannel(); a.peer = b; b.peer = a; return (a, b) }
    static func open(_ a: FakeChannel, _ b: FakeChannel) { a.isOpen = true; b.isOpen = true; a.onOpen?(); b.onOpen?() }
}
@MainActor
final class FakeOffer: ShareDirectOffer {
    let quintuple: ShareSDPQuintuple
    let channel: ShareDataChannel
    let local: FakeChannel
    var accepted: ShareSDPQuintuple?
    var onAccept: (() -> Void)?
    init(q: ShareSDPQuintuple, ch: FakeChannel) { quintuple = q; channel = ch; local = ch }
    func accept(answer: ShareSDPQuintuple) async throws { accepted = answer; onAccept?() }
    func close() {}
}
@MainActor
final class FakeAnswer: ShareDirectAnswer {
    let quintuple: ShareSDPQuintuple
    var onChannel: ((ShareDataChannel) -> Void)?
    init(q: ShareSDPQuintuple) { quintuple = q }
    func close() {}
}
/// Pile directe factice : deux piles partagent un « réseau » où une offre trouve sa réponse par l'ufrag.
@MainActor
final class FakeNet {
    var offers: [String: (FakeOffer, FakeChannel)] = [:]
    var n = 0
}
@MainActor
final class FakeStack: ShareDirectStack {
    let net: FakeNet
    init(net: FakeNet) { self.net = net }
    static let fp = String(repeating: "AB", count: 32)
    func makeOffer() async throws -> ShareDirectOffer {
        net.n += 1
        let (a, b) = FakeChannel.pair()
        let o = FakeOffer(q: ShareSDPQuintuple(u: "off\(net.n)", p: "pw", f: Self.fp, s: "actpass", c: ["192.168.1.2~5000"]), ch: a)
        net.offers["off\(net.n)"] = (o, b)
        return o
    }
    func makeAnswer(to offer: ShareSDPQuintuple) async throws -> ShareDirectAnswer {
        let ans = FakeAnswer(q: ShareSDPQuintuple(u: "ans-" + (offer.u ?? ""), p: "pw", f: Self.fp, s: "active", c: []))
        if let (o, remote) = net.offers[offer.u ?? ""] {
            o.onAccept = { [weak ans] in
                ans?.onChannel?(remote)
                FakeChannel.open(o.local, remote)
            }
        }
        return ans
    }
}

@MainActor var keepAlive: [AnyObject] = []

func sampleFiche() -> JSON {
    ["id": "f1", "title": "ACR", "status": "validated", "start": "b1",
     "blocks": [["id": "b1", "title": "B1", "image": "x"], ["id": "b2", "title": "B2"]],
     "timers": [["id": "t1", "label": "RCP", "seconds": 120]], "counters": [["id": "c1", "label": "Chocs"]], "items": [],
     "category": "c", "sources": ["s"]]
}
func sampleRuntime() -> JSON {
    ["checked": ["1:b1:0": true], "verified": [:], "vgaps": [:], "counters": ["c1": 2],
     "timers": ["t1": ["id": "t1", "running": true, "elapsedMs": 0, "cycles": 0, "lastStart": 1_727_697_590_000, "stoppedAt": 0]],
     "events": [["id": "e1", "t": 1_727_697_595_000, "label": "MOT PRIVÉ", "ref": ["type": "core", "k": "bilan"]]],
     "nav": ["b1"], "navSeq": [1], "seq": 1, "cxBack": [:], "startedAt": 1_727_697_580_000, "exercise": false]
}

/// Monte un hôte « en direct » (hub) et un invité relié par un canal RPC en mémoire.
@MainActor
func makeDirectPair() async throws -> (env: ManualEnv, hub: ShareHub, host: ShareEngine, hostD: RuntimeDelegate, guest: ShareEngine, guestD: RuntimeDelegate) {
    let env = ManualEnv()
    let hub = ShareHub.make(fiche: sampleFiche(), now: { env.t })
    let host = ShareEngine(env: env, restIO: nil)
    let hostD = RuntimeDelegate(runtime: sampleRuntime(), fiche: sampleFiche())
    host.delegate = hostD
    host.setIO(ShareHostIO(hub: hub, clock: { env.t }))
    let r = await host.host(fiche: sampleFiche(), sessionId: "s-host", snapshot: ShareCore.snap(hostD.runtime, flowEnded: false))
    XCTAssertEqual(r["share"]?.string, "local")
    let pair = ShareWirePair()
    keepAlive.append(pair); keepAlive.append(hub); keepAlive.append(host)   // le canal d'en face n'est tenu que faiblement (comme un RTCDataChannel par sa pile)
    ShareRPCServer.serve(hub, on: pair.a)
    let guest = ShareEngine(env: env, restIO: nil)
    let guestD = RuntimeDelegate(runtime: ["checked": [:], "verified": [:], "vgaps": [:], "counters": ["c1": 0],
                                           "timers": ["t1": ["id": "t1", "running": false, "elapsedMs": 0, "cycles": 0, "lastStart": 0, "stoppedAt": 0]],
                                           "events": [], "nav": ["b1"], "navSeq": [1], "seq": 1, "cxBack": [:]], fiche: sampleFiche())
    guest.delegate = guestD
    guest.setIO(ShareRPCClient(wire: pair.b, env: env))
    let j = try await guest.joinByCode(ShareRPC.dummyCode, label: "IDE")
    XCTAssertEqual(j["ok"]?.bool, true)
    return (env, hub, host, hostD, guest, guestD)
}

