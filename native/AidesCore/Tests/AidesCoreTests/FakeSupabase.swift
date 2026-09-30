import Foundation
@testable import AidesCore

/// Faux Supabase EN MÉMOIRE pour les tests : GoTrue (otp/verify/token/logout), un PostgREST minimal
/// (select, filtres eq/gt/is/in, order, limit, upsert « merge-duplicates » avec la pince serveur
/// `clamp_updated_at`, PATCH/DELETE), des RPC scriptables et le bucket Storage `attachments`.
/// Chaque requête est JOURNALISÉE (méthode, URL, en-têtes, corps) pour les assertions ; `intercept`
/// injecte une réponse (403, 500…) ou une erreur de transport (délai, réseau).
final class FakeSupabase: HTTPTransport, @unchecked Sendable {
    private let lock = NSLock()
    var tables: [String: [JSON]] = [:]
    var storage: [String: Data] = [:]
    var rpcs: [String: (JSON) throws -> HTTPResponse] = [:]
    /// Horloge du serveur (ms) : `updated_at` futur ramené à « maintenant ».
    var serverNow: Double = 1_800_000_000_000
    var requests: [HTTPRequest] = []
    var intercept: ((HTTPRequest) throws -> HTTPResponse?)?
    /// RLS simplifiée : false → 403 pour la requête entière (upsert atomique).
    var writeAllowed: ((String, JSON) -> Bool)?
    var userId = "5b7c1f0e-8a1d-4c0e-9f00-0123456789ab"
    var email = "soignant@exemple.fr"
    var tokenCounter = 0
    /// Réponse de `/auth/v1/token` (nil = une rotation normale).
    var refreshResponse: ((String) throws -> HTTPResponse)?
    /// Délai simulé (secondes) avant de répondre au rafraîchissement.
    var refreshDelayNs: UInt64 = 0
    var memberships: [(user: String, lib: String, role: String)] = []
    var libraries: [String: String] = [:]

    func locked<T>(_ f: () throws -> T) rethrows -> T { lock.lock(); defer { lock.unlock() }; return try f() }

    func log(_ path: String) -> [HTTPRequest] { locked { requests.filter { $0.url.absoluteString.contains(path) } } }
    func paths() -> [String] {
        locked { requests.map { "\($0.method) " + $0.url.absoluteString.replacingOccurrences(of: "https://x.supabase.co", with: "") } }
    }
    func reset() { locked { requests = [] } }
    func rows(_ t: String) -> [JSON] { locked { tables[t] ?? [] } }
    func row(_ t: String, _ id: String) -> JSON? { rows(t).first { $0["id"]?.string == id } }

    func session(token: String, expiresIn: Double = 3600) -> JSON {
        ["access_token": .string(token), "refresh_token": .string("rt-" + token), "expires_in": .number(expiresIn),
         "token_type": "bearer", "user": ["id": .string(userId), "email": .string(email)]]
    }

    // MARK: HTTPTransport

    func send(_ r: HTTPRequest) async throws -> HTTPResponse {
        locked { requests.append(r) }
        if let i = intercept, let resp = try i(r) { return resp }
        let comps = URLComponents(url: r.url, resolvingAgainstBaseURL: false)!
        let path = comps.path
        let items = comps.queryItems ?? []
        if path.hasPrefix("/auth/v1/") { return try await auth(path, r, items) }
        if path.hasPrefix("/storage/v1/object/attachments/") {
            let key = String(path.dropFirst("/storage/v1/object/attachments/".count))
            return locked {
                switch r.method {
                case "POST": storage[key] = r.body ?? Data(); return HTTPResponse(status: 200, headers: ["content-type": "application/json"], body: Data("{\"Key\":\"x\"}".utf8))
                case "GET": if let d = storage[key] { return HTTPResponse(status: 200, headers: ["content-type": "application/pdf"], body: d) }
                    return HTTPResponse(status: 400, body: Data("{\"statusCode\":\"404\",\"error\":\"not_found\"}".utf8))
                case "DELETE": if storage.removeValue(forKey: key) != nil { return HTTPResponse(status: 200) }
                    return HTTPResponse(status: 404, body: Data("not found".utf8))
                default: return HTTPResponse(status: 405)
                }
            }
        }
        if path.hasPrefix("/rest/v1/rpc/") {
            let name = String(path.dropFirst("/rest/v1/rpc/".count))
            guard let f = locked({ rpcs[name] }) else { return HTTPResponse(status: 404, body: Data("no rpc".utf8)) }
            return try f(r.jsonBody ?? .null)
        }
        if path.hasPrefix("/rest/v1/") {
            var table = String(path.dropFirst("/rest/v1/".count))
            if table == "fiches" { table = "cognitive_aids" }   // vue de compatibilité 4.x
            return locked { restCall(table, r, items) }
        }
        return HTTPResponse(status: 404)
    }

    private func auth(_ path: String, _ r: HTTPRequest, _ items: [URLQueryItem]) async throws -> HTTPResponse {
        switch path {
        case "/auth/v1/otp": return .json(.object([:]))
        case "/auth/v1/verify":
            let code = r.jsonBody?["token"]?.string ?? ""
            if code != "12345678" { return .json(["msg": "Token has expired or is invalid"], status: 403) }
            let t = locked { tokenCounter += 1; return "at\(tokenCounter)" }
            return .json(session(token: t))
        case "/auth/v1/token":
            if refreshDelayNs > 0 { try await Task.sleep(nanoseconds: refreshDelayNs) }
            let rt = r.jsonBody?["refresh_token"]?.string ?? ""
            if let f = refreshResponse { return try f(rt) }
            let t = locked { tokenCounter += 1; return "at\(tokenCounter)" }
            return .json(session(token: t))
        case "/auth/v1/logout": return HTTPResponse(status: 204)
        case "/auth/v1/health": return .json(["name": "GoTrue"])
        default: return HTTPResponse(status: 404)
        }
    }

    // MARK: PostgREST minimal

    private func pk(_ table: String) -> [String] {
        switch table {
        case "category_sets": return ["scope_key"]
        case "aid_notes": return ["user_id", "fiche_id"]
        default: return ["id"]
        }
    }

    private func matches(_ row: JSON, _ filters: [(String, String)]) -> Bool {
        for (col, expr) in filters {
            let v = row[col]
            if expr.hasPrefix("eq.") { if (v?.jsString ?? "") != String(expr.dropFirst(3)) || v == nil || v!.isNull { return false } }
            else if expr.hasPrefix("gt.") {
                let arg = String(expr.dropFirst(3))
                if col.hasSuffix("_at") {
                    guard let a = JSDate.parse(arg), let s = v?.string, let b = JSDate.parse(s), b > a else { return false }
                } else if !((v?.string ?? "") > arg) { return false }
            } else if expr == "is.null" { if !(v == nil || v!.isNull) { return false } }
            else if expr.hasPrefix("in.(") {
                let list = expr.dropFirst(4).dropLast().split(separator: ",").map(String.init)
                if !list.contains(v?.jsString ?? "\u{0}") { return false }
            }
        }
        return true
    }

    private func restCall(_ table: String, _ r: HTTPRequest, _ items: [URLQueryItem]) -> HTTPResponse {
        var filters: [(String, String)] = []
        var select = "*", order: String?, limit: Int?
        for it in items {
            let v = it.value ?? ""
            switch it.name {
            case "select": select = v
            case "order": order = v
            case "limit": limit = Int(v)
            default: filters.append((it.name, v))
            }
        }
        switch r.method {
        case "GET":
            if table == "memberships" {
                let out: [JSON] = memberships.filter { m in matches(["user_id": .string(m.user), "library_id": .string(m.lib)], filters) }.map { m in
                    ["role": .string(m.role), "library_id": .string(m.lib),
                     "libraries": libraries[m.lib].map { ["id": .string(m.lib), "name": .string($0)] } ?? .null]
                }
                return .json(.array(out))
            }
            var rows = (tables[table] ?? []).filter { matches($0, filters) }
            if let order {
                let col = String(order.split(separator: ".")[0])
                rows.sort { a, b in
                    if col.hasSuffix("_at") { return (JSDate.parse(a[col]?.string ?? "") ?? 0) < (JSDate.parse(b[col]?.string ?? "") ?? 0) }
                    return (a[col]?.jsString ?? "") < (b[col]?.jsString ?? "")
                }
            }
            if let limit { rows = Array(rows.prefix(limit)) }
            if select != "*" {
                let cols = select.split(separator: ",").map(String.init)
                rows = rows.map { row in .object(Dictionary(uniqueKeysWithValues: cols.map { ($0, row[$0] ?? .null) })) }
            }
            return .json(.array(rows))
        case "POST":
            let body = r.jsonBody?.array ?? []
            if let w = writeAllowed, body.contains(where: { !w(table, $0) }) {
                return HTTPResponse(status: 403, headers: ["content-type": "application/json"],
                                    body: Data("{\"code\":\"42501\",\"message\":\"new row violates row-level security policy\"}".utf8))
            }
            var rows = tables[table] ?? []
            let keys = pk(table)
            for var row in body {
                if case .object(var o) = row, let s = o["updated_at"]?.string, let t = JSDate.parse(s), t > serverNow {
                    o["updated_at"] = .string(JSDate.iso(serverNow)); row = .object(o)
                }
                if let i = rows.firstIndex(where: { ex in keys.allSatisfy { ex[$0] == row[$0] } }) {
                    var merged = rows[i].object ?? [:]
                    for (k, v) in row.object ?? [:] { merged[k] = v }
                    rows[i] = .object(merged)
                } else { rows.append(row) }
            }
            tables[table] = rows
            return HTTPResponse(status: 201)
        case "PATCH":
            let patch = r.jsonBody?.object ?? [:]
            tables[table] = (tables[table] ?? []).map { row in
                guard matches(row, filters), var o = row.object else { return row }
                for (k, v) in patch { o[k] = v }
                return .object(o)
            }
            return HTTPResponse(status: 204)
        case "DELETE":
            tables[table] = (tables[table] ?? []).filter { !matches($0, filters) }
            return HTTPResponse(status: 204)
        default: return HTTPResponse(status: 405)
        }
    }
}

/// RPC scalaire (PostgREST rend du JSON nu).
func rpcValue(_ j: JSON) -> (JSON) throws -> HTTPResponse { { _ in .json(j) } }
