import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// TRANSPORT SUPABASE — port de `SUPA`, `acFetch`, des en-têtes d'`Auth.headers` et du format
// d'erreur de `rest()` / `storageReq()`.
//
// Le client web parle à Supabase par des `fetch` NUS (pas de supabase-js) : GoTrue pour le code
// e-mail, PostgREST pour les tables et les RPC, Storage pour les PDF. Le natif fait EXACTEMENT les
// mêmes appels, avec les mêmes en-têtes et les mêmes corps, pour lire et écrire les MÊMES lignes
// que la PWA sur le même projet : deux clients, une bibliothèque.
//
// Tout passe par `HTTPTransport`, un protocole à UNE méthode : le moteur de synchro entier se
// teste donc sans réseau, avec un faux serveur qui enregistre chaque requête (méthode, chemin,
// en-têtes, corps) et rejoue les réponses voulues (403, 401, délai dépassé…).

/// Projet Supabase — `SUPA` de la PWA. L'URL et la clé « publishable » sont PUBLIQUES par
/// conception (la sécurité vit dans la RLS). Un installateur qui déploie sa propre instance les
/// change par configuration de build ; la valeur par défaut est celle de la PWA, à l'octet.
public struct SupabaseConfig: Equatable, Sendable {
    public var url: String
    public var key: String
    public init(url: String, key: String) {
        // Pas de « / » final : les chemins commencent tous par « / » (`SUPA.url + path`).
        var u = url
        while u.hasSuffix("/") { u.removeLast() }
        self.url = u
        self.key = key
    }
    public static let standard = SupabaseConfig(url: "https://xhvgiwcxaqcnacuiovhh.supabase.co",
                                                key: "sb_publishable_X6kvCMh6XiCvKQEOc1c0PQ_BrMZDIQd")
    /// Lit `SupabaseURL` / `SupabaseKey` dans l'Info.plist de l'app (clés vides ou absentes : la
    /// valeur standard). Le bundle est injectable pour les tests.
    public static func fromBundle(_ bundle: Bundle = .main) -> SupabaseConfig {
        let u = (bundle.object(forInfoDictionaryKey: "SupabaseURL") as? String).map(JS.trim) ?? ""
        let k = (bundle.object(forInfoDictionaryKey: "SupabaseKey") as? String).map(JS.trim) ?? ""
        return SupabaseConfig(url: u.isEmpty ? standard.url : u, key: k.isEmpty ? standard.key : k)
    }
}

/// Délais de garde (`NET_TIMEOUT_MS`, `NET_TIMEOUT_BLOB_MS`) : sur iOS une requête sans route ne
/// rejette qu'après 60 à 75 s — `Sync.running` resterait bloqué et le repli exponentiel serait
/// inopérant pendant la première minute. JSON court, binaire long (25 s casserait un téléversement
/// légitime de PDF sur réseau lent).
public enum NetTimeout {
    public static let jsonMs = 25_000
    public static let blobMs = 120_000
    /// Sonde de joignabilité du module de partage (`slNetProbe`).
    public static let probeMs = 3_500
}

public struct HTTPRequest: Equatable, Sendable {
    public var method: String
    public var url: URL
    public var headers: [String: String]
    public var body: Data?
    /// Délai TOTAL en millisecondes (et non un délai d'inactivité).
    public var timeoutMs: Int
    public init(method: String, url: URL, headers: [String: String], body: Data?, timeoutMs: Int) {
        self.method = method; self.url = url; self.headers = headers; self.body = body; self.timeoutMs = timeoutMs
    }
    /// Corps relu en JSON (tests).
    public var jsonBody: JSON? { body.flatMap { try? JSON.parse($0) } }
}

public struct HTTPResponse: Equatable, Sendable {
    public var status: Int
    /// Clés en MINUSCULES (les en-têtes HTTP ne sont pas sensibles à la casse).
    public var headers: [String: String]
    public var body: Data
    public init(status: Int, headers: [String: String] = [:], body: Data = Data()) {
        self.status = status
        var h: [String: String] = [:]
        for (k, v) in headers { h[k.lowercased()] = v }
        self.headers = h
        self.body = body
    }
    public var ok: Bool { status >= 200 && status <= 299 }
    public var text: String { String(decoding: body, as: UTF8.self) }
    /// Réponse JSON (tests et faux serveurs).
    public static func json(_ j: JSON, status: Int = 200) -> HTTPResponse {
        HTTPResponse(status: status, headers: ["Content-Type": "application/json; charset=utf-8"], body: j.data())
    }
}

/// Le SEUL point de contact avec le réseau. Une implémentation lève `CloudError.timeout` quand le
/// délai est dépassé et `CloudError.network` quand la requête n'a pas atteint le serveur ; toute
/// réponse HTTP (même 500) est RENDUE, jamais levée — c'est l'appelant qui décide.
public protocol HTTPTransport: Sendable {
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}

/// Erreurs typées du client cloud. `message` reproduit À L'IDENTIQUE le message d'erreur de la
/// PWA (« REST 403 … », « NET timeout 25000 ms ») : l'interface et `restErrStatus` en dépendent.
public enum CloudError: Error, Equatable, Sendable, CustomStringConvertible {
    /// Réponse HTTP non 2xx de PostgREST/Storage : statut + 200 premiers caractères du corps.
    case http(status: Int, body: String)
    /// Délai de garde dépassé (`acFetch`).
    case timeout(ms: Int)
    /// La requête n'a pas atteint le serveur (pas de route, DNS, TLS…) — `TypeError: Failed to fetch`.
    case network(String)
    /// Erreur du stockage local de l'appareil (écriture refusée, disque plein).
    case localStore(String)
    /// Refus de GoTrue ou d'une RPC appelée par `Auth._post` : message du serveur tel quel
    /// (`j.msg || j.message || j.error_description || j.error || 'HTTP '+status`).
    case api(status: Int, message: String)
    /// Réponse illisible (JSON annoncé mais invalide).
    case badResponse(String)
    /// Opération qui exige un compte connecté.
    case notSignedIn

    /// Message au format de la PWA.
    public var message: String {
        switch self {
        case .http(let s, let b): return "REST \(s) " + b
        case .timeout(let ms): return "NET timeout \(ms) ms"
        case .network(let m): return "Failed to fetch" + (m.isEmpty ? "" : " (" + m + ")")
        case .localStore(let m): return m
        case .api(_, let m): return m
        case .badResponse(let m): return m
        case .notSignedIn: return "not signed in"
        }
    }
    public var description: String { message }
    /// Statut HTTP d'une réponse PostgREST/Storage refusée (nil pour le reste — même règle que
    /// `restErrStatus` : un délai dépassé n'est PAS un refus du serveur).
    public var httpStatus: Int? { if case .http(let s, _) = self { return s }; return nil }
}

extension CloudError {
    /// `String(t).slice(0,200)` du corps d'une réponse refusée.
    static func fromResponse(_ r: HTTPResponse) -> CloudError {
        .http(status: r.status, body: JS.prefix(r.text, 200))
    }
}

/// `encodeURIComponent` : tout est échappé sauf `A-Z a-z 0-9 - _ . ! ~ * ' ( )`.
public func jsEncodeURIComponent(_ s: String) -> String {
    var out = ""
    for b in s.utf8 {
        let c = Character(Unicode.Scalar(b))
        if (b >= 48 && b <= 57) || (b >= 65 && b <= 90) || (b >= 97 && b <= 122) || "-_.!~*'()".contains(c) {
            out.append(c)
        } else {
            out += String(format: "%%%02X", b)
        }
    }
    return out
}

// MARK: - Transport par défaut

/// Transport réel, sur `URLSession`. DEUX sessions : leur `timeoutIntervalForResource` borne la
/// durée TOTALE d'un échange (le `timeoutInterval` d'une requête n'est qu'un délai d'inactivité —
/// un serveur qui répond au goutte-à-goutte ne le déclencherait jamais).
public final class URLSessionTransport: HTTPTransport, @unchecked Sendable {
    let jsonSession: URLSession
    let blobSession: URLSession

    public init() {
        func make(_ ms: Int) -> URLSession {
            let c = URLSessionConfiguration.ephemeral
            c.timeoutIntervalForRequest = Double(ms) / 1000
            c.timeoutIntervalForResource = Double(ms) / 1000
            // `cache: 'no-store'` : une réponse de synchro n'est jamais servie depuis un cache.
            c.requestCachePolicy = .reloadIgnoringLocalCacheData
            c.urlCache = nil
            c.httpCookieStorage = nil
            c.httpShouldSetCookies = false
            return URLSession(configuration: c)
        }
        jsonSession = make(NetTimeout.jsonMs)
        blobSession = make(NetTimeout.blobMs)
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var r = URLRequest(url: request.url)
        r.httpMethod = request.method
        r.timeoutInterval = Double(request.timeoutMs) / 1000
        r.httpBody = request.body
        r.cachePolicy = .reloadIgnoringLocalCacheData
        for (k, v) in request.headers { r.setValue(v, forHTTPHeaderField: k) }
        let session = request.timeoutMs > NetTimeout.jsonMs ? blobSession : jsonSession
        let ms = request.timeoutMs
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<HTTPResponse, Error>) in
            let task = session.dataTask(with: r) { data, resp, err in
                if let err {
                    let code = (err as? URLError)?.code ?? URLError.Code(rawValue: (err as NSError).code)
                    if code == .timedOut { cont.resume(throwing: CloudError.timeout(ms: ms)) } else { cont.resume(throwing: CloudError.network(err.localizedDescription)) }
                    return
                }
                guard let h = resp as? HTTPURLResponse else {
                    cont.resume(throwing: CloudError.network("réponse non HTTP")); return
                }
                var headers: [String: String] = [:]
                for (k, v) in h.allHeaderFields { headers[String(describing: k).lowercased()] = String(describing: v) }
                cont.resume(returning: HTTPResponse(status: h.statusCode, headers: headers, body: data ?? Data()))
            }
            task.resume()
        }
    }
}

// MARK: - Verrou minimal (état lisible hors acteur)

/// Boîte protégée par un verrou : permet de lire la session SANS `await` (en-têtes, garde
/// « connecté ? » de `Sync.schedule()`, interface) tout en gardant l'écriture sérialisée.
final class LockedBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T
    init(_ v: T) { _value = v }
    var value: T {
        get { lock.lock(); defer { lock.unlock() }; return _value }
        set { lock.lock(); _value = newValue; lock.unlock() }
    }
}
