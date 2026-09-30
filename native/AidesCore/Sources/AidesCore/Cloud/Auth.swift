import Foundation

// COMPTE — port de l'objet `Auth` de la PWA (GoTrue, connexion par CODE reçu par e-mail) et des
// enveloppes `rest()`, `rpc()`, `storageReq()` qui portent le jeton sur chaque appel.
//
// LA PROMESSE HORS LIGNE : un échec RÉSEAU (mode avion, Wi-Fi captif, délai dépassé) ne
// déconnecte JAMAIS. Seul un REFUS explicite du serveur au rafraîchissement (400/401/403 : jeton
// de rafraîchissement invalide ou révoqué) déconnecte. Sans cette règle, rester hors ligne plus
// d'une heure (durée de vie du jeton) ferait perdre le compte au retour du réseau.

/// La session GoTrue, sous la forme EXACTE de `localStorage['ac-auth']` côté web :
/// `{"access_token", "refresh_token", "expires_at" (secondes Unix), "user"}`.
public struct AuthSession: Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String?
    /// Expiration du jeton d'accès, en SECONDES depuis l'époque.
    public var expiresAt: Double
    /// Objet utilisateur GoTrue, conservé tel quel ; l'app n'en lit que `id` et `email`.
    public var user: JSON

    public init(accessToken: String, refreshToken: String?, expiresAt: Double, user: JSON) {
        self.accessToken = accessToken; self.refreshToken = refreshToken; self.expiresAt = expiresAt; self.user = user
    }
    public var userId: String? { user["id"]?.string }
    public var email: String? { user["email"]?.string }
    /// Initiales du disque de compte : deux premiers caractères de l'e-mail, en capitales.
    public var initials: String { JS.prefix(JS.trim(email ?? ""), 2).uppercased() }

    public var json: JSON {
        var o: [String: JSON] = ["access_token": .string(accessToken), "expires_at": .number(expiresAt), "user": user]
        if let refreshToken { o["refresh_token"] = .string(refreshToken) }
        return .object(o)
    }
    public init?(json j: JSON) {
        guard let at = j["access_token"]?.string, !at.isEmpty else { return nil }
        accessToken = at
        refreshToken = j["refresh_token"]?.string
        expiresAt = j["expires_at"]?.number ?? 0
        user = j["user"] ?? .null
    }

    /// `_setSession(j)` : une réponse SANS `access_token` est ignorée (nil). Expiration :
    /// `j.expires_at || floor(now/1000) + (j.expires_in || 3600)`.
    /// ÉCART VOULU : si la réponse n'apporte pas d'objet `user` (rafraîchissement d'un GoTrue
    /// qui l'omettrait), on GARDE l'utilisateur connu — le web le perdrait, et la garde d'espace
    /// (`user.id === currentSpace()`) bloquerait alors toute synchro jusqu'à la reconnexion.
    static func from(response j: JSON, nowMs: Double, previousUser: JSON?) -> AuthSession? {
        guard let at = j["access_token"], at.truthy else { return nil }
        let exp: Double
        if let e = j["expires_at"], e.truthy, JS.number(e).isFinite { exp = JS.number(e) }
        else {
            let ein = j["expires_in"].map { JS.number($0) } ?? .nan
            exp = (nowMs / 1000).rounded(.down) + ((ein.isNaN || ein == 0) ? 3600 : ein)
        }
        var user = j["user"] ?? .null
        if user.isNull, let p = previousUser { user = p }
        return AuthSession(accessToken: at.jsString, refreshToken: j["refresh_token"]?.string, expiresAt: exp, user: user)
    }
}

// MARK: - Stockage sécurisé de la session

/// UN élément global (pas par espace) — l'app l'adosse au TROUSSEAU (Keychain). `nil` = effacer.
public protocol SecureStore: AnyObject, Sendable {
    func load() -> Data?
    func save(_ data: Data?)
}

/// En mémoire (tests, aperçus).
public final class InMemorySecureStore: SecureStore, @unchecked Sendable {
    private let box = LockedBox<Data?>(nil)
    public init(_ initial: Data? = nil) { box.value = initial }
    public func load() -> Data? { box.value }
    public func save(_ data: Data?) { box.value = data }
}

/// Dans un fichier (Linux, outils). Écriture atomique ; `nil` supprime le fichier.
public final class FileSecureStore: SecureStore, @unchecked Sendable {
    public let url: URL
    private let lock = NSLock()
    public init(url: URL) { self.url = url }
    public func load() -> Data? { lock.lock(); defer { lock.unlock() }; return try? Data(contentsOf: url) }
    public func save(_ data: Data?) {
        lock.lock(); defer { lock.unlock() }
        if let data {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

// MARK: - Client d'authentification + REST

/// Port de `Auth` + `rest()` / `rpc()` / `storageReq()`.
///
/// ACTEUR pour le RAFRAÎCHISSEMENT « single-flight » : GoTrue fait TOURNER le jeton de
/// rafraîchissement (l'ancien devient invalide dès le premier usage) ; deux rafraîchissements
/// simultanés partiraient avec le MÊME jeton, le second recevrait 400 « déjà utilisé » et
/// déconnecterait l'utilisateur. Tous les appelants concurrents attendent donc la MÊME tâche.
///
/// La session courante se lit SANS `await` (`session`, `signedIn`) : les en-têtes, la garde de
/// `Sync.schedule()` et l'interface en ont besoin de façon synchrone.
public actor AuthClient {
    public nonisolated let config: SupabaseConfig
    nonisolated let transport: HTTPTransport
    nonisolated let secure: SecureStore
    nonisolated let clock: @Sendable () -> Double
    private nonisolated let box: LockedBox<AuthSession?>
    private nonisolated let observer = LockedBox<(@Sendable (AuthSession?) -> Void)?>(nil)
    private var refreshTask: Task<Bool, Never>?

    /// `clock` : millisecondes depuis l'époque (injectable pour les tests d'expiration).
    public init(config: SupabaseConfig = .standard, transport: HTTPTransport = URLSessionTransport(),
                secureStore: SecureStore, clock: @escaping @Sendable () -> Double = { JS.now() }) {
        self.config = config
        self.transport = transport
        self.secure = secureStore
        self.clock = clock
        // `Auth._load()` : relue une fois au démarrage.
        var s: AuthSession? = nil
        if let d = secureStore.load(), let j = try? JSON.parse(d) { s = AuthSession(json: j) }
        box = LockedBox(s)
    }

    // MARK: Lecture synchrone

    public nonisolated var session: AuthSession? { box.value }
    /// `signedIn()` = une session avec un jeton d'accès.
    public nonisolated var signedIn: Bool { box.value.map { !$0.accessToken.isEmpty } ?? false }
    public nonisolated var userId: String? { box.value?.userId }
    public nonisolated var email: String? { box.value?.email }
    /// `token()` : le jeton d'accès, ou la clé publishable hors connexion (rôle `anon`).
    public nonisolated var token: String { box.value?.accessToken ?? config.key }

    /// Observateur des changements de session (connexion, rafraîchissement, déconnexion — y
    /// compris la déconnexion SUBIE d'un rafraîchissement refusé). Appelé sur n'importe quel fil.
    public nonisolated func setSessionObserver(_ f: (@Sendable (AuthSession?) -> Void)?) { observer.value = f }

    /// `Auth.headers(extra)` : `apikey` toujours, `Authorization: Bearer <jeton ou clé>`,
    /// `Content-Type: application/json` toujours (même sur un GET), puis les en-têtes en plus.
    public nonisolated func headers(_ extra: [String: String] = [:]) -> [String: String] {
        var h = ["apikey": config.key, "Authorization": "Bearer " + token, "Content-Type": "application/json"]
        for (k, v) in extra { h[k] = v }
        return h
    }

    private nonisolated func setSession(_ s: AuthSession?) {
        box.value = s
        secure.save(s.map { $0.json.data() })
        observer.value?(s)
    }

    /// Pose une session (restauration, tests). Ignorée sans jeton — comme `_setSession`.
    public func adopt(_ s: AuthSession) { setSession(s) }

    nonisolated func url(_ path: String) throws -> URL {
        guard let u = URL(string: config.url + path) else { throw CloudError.badResponse("URL invalide : " + path) }
        return u
    }

    // MARK: GoTrue

    /// `Auth._post(path, body)` : POST JSON, SANS `ensureFresh` (la suppression de compte compte
    /// sur le jeton tout frais de la vérification OTP qui la précède). Erreur :
    /// `j.msg || j.message || j.error_description || j.error || 'HTTP '+status`.
    nonisolated func post(_ path: String, _ body: JSON) async throws -> JSON {
        let r = try await transport.send(HTTPRequest(method: "POST", url: try url(path), headers: headers(), body: body.data(), timeoutMs: NetTimeout.jsonMs))
        let j = (try? JSON.parse(r.body)) ?? .object([:])
        if !r.ok {
            var msg = "HTTP \(r.status)"
            for k in ["msg", "message", "error_description", "error"] {
                if let v = j[k], v.truthy { msg = v.jsString; break }
            }
            throw CloudError.api(status: r.status, message: msg)
        }
        return j
    }

    /// `Auth.sendCode(email)` — POST `/auth/v1/otp` `{email, create_user:true}` : le compte se
    /// crée au premier usage. L'interface montre le message GoTrue brut en cas d'échec.
    public nonisolated func sendCode(email: String) async throws {
        _ = try await post("/auth/v1/otp", ["email": .string(email), "create_user": true])
    }

    /// `Auth.verifyCode(email, code)` — POST `/auth/v1/verify` `{type:'email', email, token}`.
    /// Le code est réduit à ses CHIFFRES (l'interface retire tout le reste, `replace(/\D/g,'')`).
    @discardableResult
    public func verifyCode(email: String, code: String) async throws -> AuthSession {
        let digits = String(String.UnicodeScalarView(code.unicodeScalars.filter { $0.value >= 48 && $0.value <= 57 }))
        let j = try await post("/auth/v1/verify", ["type": "email", "email": .string(email), "token": .string(digits)])
        guard let s = AuthSession.from(response: j, nowMs: clock(), previousUser: nil) else {
            throw CloudError.badResponse("Réponse de vérification sans jeton")
        }
        setSession(s)
        return s
    }

    /// `Auth.refresh()` — SINGLE-FLIGHT (voir l'en-tête du type). Rend `true` si un nouveau jeton
    /// est posé. Réseau ou délai : `false` SANS déconnexion ; 400/401/403 : déconnexion ; autre
    /// statut : `false`, session gardée.
    public func refresh() async -> Bool {
        if let t = refreshTask { return await t.value }
        let t = Task { await self.performRefresh() }
        refreshTask = t
        let r = await t.value
        refreshTask = nil
        return r
    }

    private func performRefresh() async -> Bool {
        guard let s = box.value, let rt = s.refreshToken, !rt.isEmpty else { return false }
        let r: HTTPResponse
        do {
            // Même en-têtes que le web (Bearer = jeton d'accès courant, peut-être expiré : GoTrue
            // l'ignore sur cette route).
            r = try await transport.send(HTTPRequest(method: "POST", url: try url("/auth/v1/token?grant_type=refresh_token"),
                                                     headers: headers(), body: JSON.object(["refresh_token": .string(rt)]).data(),
                                                     timeoutMs: NetTimeout.jsonMs))
        } catch { return false }
        let j = (try? JSON.parse(r.body)) ?? .object([:])
        if !r.ok {
            if r.status == 400 || r.status == 401 || r.status == 403 { await signOut() }
            return false
        }
        guard let ns = AuthSession.from(response: j, nowMs: clock(), previousUser: s.user) else { return false }
        setSession(ns)
        return true
    }

    /// `Auth.ensureFresh()` : hors connexion `false` ; rafraîchit si le jeton expire dans moins de
    /// 60 s ; sinon `true`. Appelé en tête de CHAQUE `rest()` et `storage()`.
    @discardableResult
    public func ensureFresh() async -> Bool {
        guard signedIn, let s = box.value else { return false }
        let now = (clock() / 1000).rounded(.down)
        if s.expiresAt != 0 && s.expiresAt - now < 60 { return await refresh() }
        return true
    }

    /// `Auth.signOut()` : la session est effacée D'ABORD (jamais de fenêtre où l'app se croirait
    /// connectée), puis un `logout` best-effort avec l'ancien jeton (seuls `apikey` et
    /// `Authorization`, sans corps). Ne touche NI aux données locales, NI à l'espace, NI aux
    /// curseurs : les fiches de ce compte restent consultables hors ligne.
    public func signOut() async {
        let tok = box.value?.accessToken
        setSession(nil)
        guard let tok, !tok.isEmpty, let u = try? url("/auth/v1/logout") else { return }
        _ = try? await transport.send(HTTPRequest(method: "POST", url: u,
                                                  headers: ["apikey": config.key, "Authorization": "Bearer " + tok],
                                                  body: nil, timeoutMs: NetTimeout.jsonMs))
    }

    /// `Auth.deleteAccount()` — RPC `delete_my_account` par `_post` (sans `ensureFresh`). Le
    /// serveur exige une vérification OTP de moins de 10 minutes (`recent otp verification
    /// required`) et refuse un super-administrateur.
    public nonisolated func deleteAccount() async throws {
        _ = try await post("/rest/v1/rpc/delete_my_account", .object([:]))
    }

    /// `GET /auth/v1/health` (sonde de joignabilité du partage) : TOUT statut HTTP prouve que le
    /// serveur répond ; seul un échec réseau ou un délai rend `false`.
    public nonisolated func probeHealth(timeoutMs: Int = NetTimeout.probeMs) async -> Bool {
        guard let u = try? url("/auth/v1/health") else { return false }
        do {
            _ = try await transport.send(HTTPRequest(method: "GET", url: u, headers: ["apikey": config.key], body: nil, timeoutMs: timeoutMs))
            return true
        } catch { return false }
    }

    // MARK: PostgREST / Storage

    /// `rest(method, path, body, extra)` : `ensureFresh`, puis l'appel ; une réponse non 2xx lève
    /// `CloudError.http(status, 200 premiers caractères)`. Rend le JSON si la réponse est
    /// `application/json`, sinon `nil` (`Prefer: return=minimal`, RPC `void`).
    @discardableResult
    public nonisolated func rest(_ method: String, _ path: String, body: JSON? = nil, extra: [String: String] = [:]) async throws -> JSON? {
        await ensureFresh()
        let r = try await transport.send(HTTPRequest(method: method, url: try url(path), headers: headers(extra),
                                                     body: body?.data(), timeoutMs: NetTimeout.jsonMs))
        if !r.ok { throw CloudError.fromResponse(r) }
        let ct = r.headers["content-type"] ?? ""
        guard ct.contains("application/json") else { return nil }
        if r.body.isEmpty { return nil }
        do { return try JSON.parse(r.body) } catch { throw CloudError.badResponse("Réponse JSON illisible") }
    }

    /// `rpc(name, body)` = `rest('POST', '/rest/v1/rpc/'+name, body||{})`. Une fonction scalaire
    /// rend du JSON nu (`"approved"`, `true`, `null`), une fonction-table un tableau d'objets.
    @discardableResult
    public nonisolated func rpc(_ name: String, _ body: JSON = .object([:])) async throws -> JSON? {
        try await rest("POST", "/rest/v1/rpc/" + name, body: body)
    }

    /// `storageReq(method, path, body, ctype, extra)` : bucket `attachments`, délai LONG (120 s),
    /// en-têtes `apikey` + `Authorization` (+ `Content-Type` s'il est donné) — jamais le
    /// Content-Type JSON d'`Auth.headers`, le corps est BINAIRE.
    @discardableResult
    public nonisolated func storage(_ method: String, _ path: String, body: Data? = nil, contentType: String? = nil,
                                    extra: [String: String] = [:]) async throws -> HTTPResponse {
        await ensureFresh()
        var h = ["apikey": config.key, "Authorization": "Bearer " + token]
        for (k, v) in extra { h[k] = v }
        if let contentType { h["Content-Type"] = contentType }
        let r = try await transport.send(HTTPRequest(method: method, url: try url("/storage/v1/object/attachments/" + path),
                                                     headers: h, body: body, timeoutMs: NetTimeout.blobMs))
        if !r.ok { throw CloudError.fromResponse(r) }
        return r
    }
}
