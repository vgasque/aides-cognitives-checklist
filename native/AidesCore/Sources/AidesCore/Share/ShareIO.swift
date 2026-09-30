import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// PARTAGE — LA COUTURE `_io` ET L'ENVIRONNEMENT INJECTABLE.
//
// La PWA isole ses appels réseau derrière un objet remplaçable, `Share._io`, à HUIT verbes
// (open, admit, join, pull, push, revoke, setRole, end). Trois implémentations s'y branchent sans
// que le moteur change d'une ligne : le serveur Supabase (`_ioRest`), le hub de l'HÔTE en direct
// (`slHostIo`) et le client RPC de l'INVITÉ en direct (`slClient(wire).io`). Le natif garde
// exactement ce découpage — c'est lui qui rend le moteur testable sans réseau (faux transport,
// fausse horloge) et qui permettra de brancher un canal WebRTC natif plus tard.
//
// Ce module est AUTONOME (demande explicite) : il ne dépend pas du client Supabase général du
// dossier `Cloud/`. `ShareHTTP` est un protocole minimal ; l'app peut l'implémenter sur son propre
// client, ou utiliser `URLSessionShareHTTP`.

/// Nature de la couture en place — l'équivalent natif de `Share._io === Share._ioRest` et de
/// `Share.share === 'local'`.
public enum ShareIOKind: String, Sendable { case rest, hostHub, rpcClient, other }

/// Les huit verbes. Chaque réponse est le `jsonb` du serveur (ou son double du hub), tel quel :
/// le moteur lit les mêmes champs que la PWA (`ok`, `err`, `status`, `server_time`…).
public protocol ShareIO: AnyObject {
    var kind: ShareIOKind { get }
    func open(id: String, sessionId: String, ficheId: String, snap: JSON, guestRole: String, ttlMin: Int) async throws -> JSON
    func admit(share: String, seconds: Int) async throws -> JSON
    func join(code: String, label: String) async throws -> JSON
    func pull(secret: String?, share: String?, since: Int) async throws -> JSON
    func push(secret: String?, share: String?, events: [JSON]) async throws -> JSON
    func revoke(share: String, pid: String) async throws -> JSON
    func setRole(share: String, pid: String, role: String) async throws -> JSON
    func end(share: String) async throws -> JSON
}

public enum ShareError: Error, Equatable, CustomStringConvertible {
    case http(Int, String)      // « REST <code> <texte> »
    case timeout                // délai dépassé (réseau ou RPC direct)
    case transport(String)      // erreur réseau
    case refused(String)        // refus local (verbe interdit sur cette couture)
    public var description: String {
        switch self {
        case .http(let c, let t): return "REST \(c) \(t)"
        case .timeout: return "timeout"
        case .transport(let m): return m
        case .refused(let m): return m
        }
    }
}

// MARK: - Environnement : horloge, aléa, minuteries

/// Minuterie annulable (`setTimeout` / `clearTimeout`).
@MainActor
public protocol ShareTimer: AnyObject { func cancel() }

/// Tout l'IMPUR que le moteur consomme — injecté, pour que les machines à états se testent avec
/// une horloge et des minuteries factices (`ShareManualEnvironment` dans les tests).
@MainActor
public protocol ShareEnvironment: AnyObject {
    /// `Date.now()` — millisecondes locales.
    func now() -> Double
    /// `Math.random()` — gigue de la cadence.
    func random() -> Double
    /// `setTimeout(fn, ms)` — le rappel s'exécute sur l'acteur principal.
    @discardableResult func schedule(afterMs: Double, _ fn: @escaping @MainActor () -> Void) -> ShareTimer
    /// Attente dans une orchestration (tentatives espacées, sondage d'admission).
    func sleep(ms: Double) async
}

/// Environnement réel : horloge système, minuteries en tâches sur l'acteur principal (le moteur
/// n'est pas réentrant, il vit sur UN exécuteur, comme le JS).
@MainActor
public final class SystemShareEnvironment: ShareEnvironment {
    public init() {}
    public func now() -> Double { JS.now() }
    public func random() -> Double { Double.random(in: 0..<1) }
    final class Item: ShareTimer {
        var task: Task<Void, Never>?
        func cancel() { task?.cancel(); task = nil }
    }
    public func schedule(afterMs: Double, _ fn: @escaping @MainActor () -> Void) -> ShareTimer {
        let it = Item()
        it.task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(max(0, afterMs) * 1_000_000))
            if !Task.isCancelled { fn() }
        }
        return it
    }
    public func sleep(ms: Double) async { try? await Task.sleep(nanoseconds: UInt64(max(0, ms) * 1_000_000)) }
}

// MARK: - HTTP minimal

public struct ShareHTTPRequest: Equatable, Sendable {
    public var method: String
    public var url: String
    public var headers: [String: String]
    public var body: Data?
    public var timeoutMs: Double
    public init(method: String, url: String, headers: [String: String], body: Data?, timeoutMs: Double) {
        self.method = method; self.url = url; self.headers = headers; self.body = body; self.timeoutMs = timeoutMs
    }
}
public struct ShareHTTPResponse: Equatable, Sendable {
    public var status: Int
    public var contentType: String
    public var body: Data
    public init(status: Int, contentType: String = "application/json", body: Data = Data()) {
        self.status = status; self.contentType = contentType; self.body = body
    }
}
/// Le transport HTTP injectable — le seul point de contact du partage avec le réseau.
public protocol ShareHTTP: AnyObject {
    func send(_ r: ShareHTTPRequest) async throws -> ShareHTTPResponse
}

/// Implémentation `URLSession` (Apple et Linux).
public final class URLSessionShareHTTP: ShareHTTP {
    let session: URLSession
    public init(session: URLSession = .shared) { self.session = session }
    public func send(_ r: ShareHTTPRequest) async throws -> ShareHTTPResponse {
        guard let url = URL(string: r.url) else { throw ShareError.transport("URL invalide") }
        var q = URLRequest(url: url)
        q.httpMethod = r.method
        q.httpBody = r.body
        q.timeoutInterval = r.timeoutMs / 1000
        q.cachePolicy = .reloadIgnoringLocalCacheData   // `cache:'no-store'` de la sonde
        for (k, v) in r.headers { q.setValue(v, forHTTPHeaderField: k) }
        return try await withCheckedThrowingContinuation { cont in
            session.dataTask(with: q) { data, resp, err in
                if let err = err as? URLError, err.code == .timedOut { cont.resume(throwing: ShareError.timeout); return }
                if let err { cont.resume(throwing: ShareError.transport(err.localizedDescription)); return }
                let h = resp as? HTTPURLResponse
                cont.resume(returning: ShareHTTPResponse(status: h?.statusCode ?? 0,
                                                         contentType: h?.value(forHTTPHeaderField: "Content-Type") ?? "",
                                                         body: data ?? Data()))
            }.resume()
        }
    }
}

/// Instance Supabase du déploiement : le natif et le web ne se rencontrent QUE sur la même
/// instance (même URL, même clé publiable — spec E § 21 Q1).
public struct ShareCloudConfig: Equatable, Sendable {
    public var url: String
    public var publishableKey: String
    public init(url: String, publishableKey: String) { self.url = url; self.publishableKey = publishableKey }
}

// MARK: - Couture Supabase (`_ioRest`)

/// Les RPC `share_*` et les trois PATCH REST, au fil près : mêmes URL, mêmes corps, mêmes en-têtes
/// que `rpc()`/`rest()` de la PWA (`apikey` = clé publiable ; `Authorization: Bearer` = jeton
/// utilisateur, ou la clé publiable si déconnecté — rôle anon, qui n'a droit qu'à join/pull/push).
public final class ShareRESTIO: ShareIO {
    public var kind: ShareIOKind { .rest }
    let config: ShareCloudConfig
    let http: ShareHTTP
    /// Jeton d'accès de l'utilisateur, rafraîchi au besoin (`Auth.ensureFresh`) ; nil = anonyme.
    let accessToken: () async -> String?
    /// Horloge pour les dates écrites par les PATCH (`new Date().toISOString()`).
    let clock: () -> Double
    public static let timeoutMs: Double = 25_000   // NET_TIMEOUT_MS (acFetch)

    public init(config: ShareCloudConfig, http: ShareHTTP, clock: @escaping () -> Double = JS.now,
                accessToken: @escaping () async -> String? = { nil }) {
        self.config = config; self.http = http; self.clock = clock; self.accessToken = accessToken
    }

    func headers(_ extra: [String: String] = [:]) async -> [String: String] {
        let tok = await accessToken()
        var h = ["apikey": config.publishableKey, "Authorization": "Bearer " + (tok ?? config.publishableKey),
                 "Content-Type": "application/json"]
        for (k, v) in extra { h[k] = v }
        return h
    }
    /// `rest(method, path, body, extra)` : lève sur un statut non 2xx ; rend le JSON si le
    /// serveur en envoie, sinon `null` (204 des PATCH).
    public func rest(_ method: String, _ path: String, _ body: JSON?, _ extra: [String: String] = [:]) async throws -> JSON {
        let req = ShareHTTPRequest(method: method, url: config.url + path, headers: await headers(extra),
                                   body: body.map { $0.data() }, timeoutMs: Self.timeoutMs)
        let r = try await http.send(req)
        guard (200..<300).contains(r.status) else {
            throw ShareError.http(r.status, JS.prefix(String(decoding: r.body, as: UTF8.self), 200))
        }
        guard r.contentType.contains("application/json"), !r.body.isEmpty else { return .null }
        return (try? JSON.parse(r.body)) ?? .null
    }
    public func rpc(_ name: String, _ body: JSON) async throws -> JSON { try await rest("POST", "/rest/v1/rpc/" + name, body) }

    static func enc(_ s: String) -> String {
        // encodeURIComponent : tout sauf A-Z a-z 0-9 - _ . ! ~ * ' ( )
        var allowed = CharacterSet.alphanumerics.intersection(CharacterSet(charactersIn: "\u{0}"..."\u{7f}"))
        allowed.insert(charactersIn: "-_.!~*'()")
        return s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s
    }
    static func str(_ s: String?) -> JSON { s.map { .string($0) } ?? .null }

    public func open(id: String, sessionId: String, ficheId: String, snap: JSON, guestRole: String, ttlMin: Int) async throws -> JSON {
        try await rpc("share_open", ["p_id": .string(id), "p_session_id": .string(sessionId), "p_fiche_id": .string(ficheId),
                                     "p_fiche_snap": snap, "p_guest_role": .string(guestRole), "p_ttl_min": .number(Double(ttlMin))])
    }
    public func admit(share: String, seconds: Int) async throws -> JSON {
        try await rpc("share_admit", ["p_share": .string(share), "p_seconds": .number(Double(seconds))])
    }
    public func join(code: String, label: String) async throws -> JSON {
        try await rpc("share_join", ["p_code": .string(code), "p_label": .string(label)])
    }
    public func pull(secret: String?, share: String?, since: Int) async throws -> JSON {
        try await rpc("share_pull", ["p_secret": Self.str(secret), "p_share": Self.str(share), "p_since": .number(Double(since))])
    }
    public func push(secret: String?, share: String?, events: [JSON]) async throws -> JSON {
        try await rpc("share_push", ["p_secret": Self.str(secret), "p_share": Self.str(share), "p_events": .array(events)])
    }
    /// Couper : pas de RPC dédiée, la RLS `sparts_own` donne l'écriture au propriétaire.
    public func revoke(share: String, pid: String) async throws -> JSON {
        try await rest("PATCH", "/rest/v1/session_participants?share_id=eq." + Self.enc(share) + "&participant=eq." + Self.enc(pid),
                       ["revoked_at": .string(ShareJS.isoString(clock()))], ["Prefer": "return=minimal"])
    }
    public func setRole(share: String, pid: String, role: String) async throws -> JSON {
        try await rest("PATCH", "/rest/v1/session_participants?share_id=eq." + Self.enc(share) + "&participant=eq." + Self.enc(pid),
                       ["role": .string(role)], ["Prefer": "return=minimal"])
    }
    /// Arrêter : `status='ended'` ET `expires_at` ramené à maintenant (la purge suit 30 min plus
    /// tard — c'est la promesse de la notice affichée à l'invité).
    public func end(share: String) async throws -> JSON {
        try await rest("PATCH", "/rest/v1/shared_sessions?id=eq." + Self.enc(share),
                       ["status": "ended", "expires_at": .string(ShareJS.isoString(clock()))], ["Prefer": "return=minimal"])
    }
}

// MARK: - Sonde de joignabilité (`slNetProbe`)

/// `navigator.onLine` ne dit pas « le serveur répond » (Wi-Fi sans internet = vrai) : la sonde
/// fait un GET (jamais HEAD — l'endpoint répond 405) sur `/auth/v1/health`, 3,5 s au plus.
/// TOUT statut HTTP vaut « joignable » : on mesure la joignabilité, pas la santé du service.
public enum ShareNetProbe {
    public static let timeoutMs: Double = 3500
    public static let periodMs: Double = 8000
    public static func probe(config: ShareCloudConfig, http: ShareHTTP) async -> Bool {
        let req = ShareHTTPRequest(method: "GET", url: config.url + "/auth/v1/health",
                                   headers: ["apikey": config.publishableKey], body: nil, timeoutMs: timeoutMs)
        guard let r = try? await http.send(req) else { return false }
        return r.status > 0
    }
}
