import XCTest
@testable import AidesCore

let testConfig = SupabaseConfig(url: "https://x.supabase.co/", key: "pk_test")

final class AuthClientTests: XCTestCase {
    func makeAuth(_ fake: FakeSupabase, store: SecureStore = InMemorySecureStore(), now: Double = 1_800_000_000_000) -> AuthClient {
        AuthClient(config: testConfig, transport: fake, secureStore: store, clock: { now })
    }

    func testDefaultConfigIsTheWebOne() {
        XCTAssertEqual(SupabaseConfig.standard.url, "https://xhvgiwcxaqcnacuiovhh.supabase.co")
        XCTAssertEqual(SupabaseConfig.standard.key, "sb_publishable_X6kvCMh6XiCvKQEOc1c0PQ_BrMZDIQd")
        XCTAssertEqual(testConfig.url, "https://x.supabase.co")
    }

    func testSendCodeRequestShape() async throws {
        let fake = FakeSupabase()
        let auth = makeAuth(fake)
        try await auth.sendCode(email: "a@b.fr")
        let r = try XCTUnwrap(fake.requests.first)
        XCTAssertEqual(r.method, "POST")
        XCTAssertEqual(r.url.absoluteString, "https://x.supabase.co/auth/v1/otp")
        XCTAssertEqual(r.headers["apikey"], "pk_test")
        XCTAssertEqual(r.headers["Authorization"], "Bearer pk_test")   // hors connexion : rôle anon
        XCTAssertEqual(r.headers["Content-Type"], "application/json")
        XCTAssertEqual(r.jsonBody, ["email": "a@b.fr", "create_user": true])
        XCTAssertEqual(r.timeoutMs, 25_000)
    }

    func testSendCodeErrorIsServerMessage() async {
        let fake = FakeSupabase()
        fake.intercept = { _ in .json(["msg": "For security purposes, you can only request this after 42 seconds."], status: 429) }
        do { try await makeAuth(fake).sendCode(email: "a@b.fr"); XCTFail() } catch {
            XCTAssertEqual((error as? CloudError), .api(status: 429, message: "For security purposes, you can only request this after 42 seconds."))
        }
        fake.intercept = { _ in HTTPResponse(status: 500, body: Data("oops".utf8)) }
        do { try await makeAuth(fake).sendCode(email: "a@b.fr"); XCTFail() } catch {
            XCTAssertEqual((error as? CloudError)?.message, "HTTP 500")
        }
    }

    func testVerifyStoresSessionInWebShape() async throws {
        let fake = FakeSupabase()
        let store = InMemorySecureStore()
        let auth = makeAuth(fake, store: store, now: 1_800_000_000_500)
        do { try await auth.verifyCode(email: "a@b.fr", code: "000"); XCTFail() } catch {
            XCTAssertEqual((error as? CloudError)?.message, "Token has expired or is invalid")
        }
        XCTAssertFalse(auth.signedIn)
        let s = try await auth.verifyCode(email: "a@b.fr", code: "1234 5678")   // chiffres seuls
        XCTAssertEqual(fake.requests.last?.jsonBody, ["type": "email", "email": "a@b.fr", "token": "12345678"])
        XCTAssertTrue(auth.signedIn)
        XCTAssertEqual(auth.userId, fake.userId)
        XCTAssertEqual(auth.email, "soignant@exemple.fr")
        XCTAssertEqual(s.expiresAt, 1_800_000_000 + 3600)
        XCTAssertEqual(s.initials, "SO")
        let saved = try JSON.parse(XCTUnwrap(store.load()))
        XCTAssertEqual(Set(saved.object!.keys), ["access_token", "refresh_token", "expires_at", "user"])
        // Relu au démarrage suivant.
        let again = makeAuth(fake, store: store)
        XCTAssertEqual(again.session, s)
        XCTAssertEqual(again.headers()["Authorization"], "Bearer " + s.accessToken)
    }

    func testEnsureFreshRefreshesOnlyNearExpiry() async throws {
        let fake = FakeSupabase()
        let auth = makeAuth(fake, now: 1_800_000_000_000)
        await auth.adopt(AuthSession(accessToken: "old", refreshToken: "rt-old", expiresAt: 1_800_000_000 + 61, user: ["id": "u1"]))
        let ok1 = await auth.ensureFresh()
        XCTAssertTrue(ok1)
        XCTAssertTrue(fake.requests.isEmpty)
        await auth.adopt(AuthSession(accessToken: "old", refreshToken: "rt-old", expiresAt: 1_800_000_000 + 59, user: ["id": "u1"]))
        let ok2 = await auth.ensureFresh()
        XCTAssertTrue(ok2)
        let r = try XCTUnwrap(fake.requests.last)
        XCTAssertEqual(r.url.absoluteString, "https://x.supabase.co/auth/v1/token?grant_type=refresh_token")
        XCTAssertEqual(r.jsonBody, ["refresh_token": "rt-old"])
        XCTAssertEqual(auth.session?.accessToken, "at1")
        XCTAssertEqual(auth.userId, fake.userId)
    }

    func testRefreshIsSingleFlight() async throws {
        let fake = FakeSupabase()
        fake.refreshDelayNs = 50_000_000
        let seen = TestBox<[String]>([])
        fake.refreshResponse = { rt in
            seen.mutate { $0.append(rt) }
            // GoTrue fait tourner le jeton : un second usage du même jeton serait refusé.
            if seen.value.filter({ $0 == rt }).count > 1 { return .json(["error": "invalid_grant"], status: 400) }
            return .json(fake.session(token: "fresh"))
        }
        let auth = makeAuth(fake)
        await auth.adopt(AuthSession(accessToken: "old", refreshToken: "rt-old", expiresAt: 1, user: ["id": "u1"]))
        let results = await withTaskGroup(of: Bool.self) { g -> [Bool] in
            for _ in 0..<8 { g.addTask { await auth.ensureFresh() } }
            var out: [Bool] = []
            for await r in g { out.append(r) }
            return out
        }
        XCTAssertEqual(results, Array(repeating: true, count: 8))
        XCTAssertEqual(fake.log("/auth/v1/token").count, 1)
        XCTAssertTrue(auth.signedIn)
        XCTAssertEqual(auth.session?.accessToken, "fresh")
    }

    func testRefreshFailureModes() async {
        let fake = FakeSupabase()
        let auth = makeAuth(fake)
        let s = AuthSession(accessToken: "old", refreshToken: "rt", expiresAt: 1, user: ["id": "u1"])
        // Réseau / délai : JAMAIS de déconnexion (promesse hors ligne).
        await auth.adopt(s)
        fake.intercept = { r in if r.url.path.hasSuffix("/token") { throw CloudError.timeout(ms: 25000) }; return nil }
        var ok = await auth.refresh()
        XCTAssertFalse(ok); XCTAssertTrue(auth.signedIn)
        // 5xx : session gardée.
        fake.intercept = { r in r.url.path.hasSuffix("/token") ? HTTPResponse(status: 503) : nil }
        ok = await auth.refresh()
        XCTAssertFalse(ok); XCTAssertTrue(auth.signedIn)
        // Refus explicite : déconnexion (et logout best-effort avec l'ancien jeton).
        for st in [400, 401, 403] {
            await auth.adopt(s)
            fake.intercept = { r in r.url.path.hasSuffix("/token") ? .json(["error": "invalid_grant"], status: st) : nil }
            ok = await auth.refresh()
            XCTAssertFalse(ok); XCTAssertFalse(auth.signedIn, "statut \(st)")
        }
        // Sans jeton de rafraîchissement : rien n'est tenté.
        fake.reset()
        await auth.adopt(AuthSession(accessToken: "a", refreshToken: nil, expiresAt: 1, user: .null))
        ok = await auth.refresh()
        XCTAssertFalse(ok); XCTAssertTrue(fake.requests.isEmpty)
    }

    func testSignOutClearsFirstThenLogout() async throws {
        let fake = FakeSupabase()
        let store = InMemorySecureStore()
        let auth = makeAuth(fake, store: store)
        await auth.adopt(AuthSession(accessToken: "tok", refreshToken: "rt", expiresAt: 9e9, user: ["id": "u1"]))
        let observed = TestBox<[AuthSession?]>([])
        auth.setSessionObserver { s in observed.mutate { $0.append(s) } }
        fake.intercept = { r in
            if r.url.path == "/auth/v1/logout" { XCTAssertFalse(auth.signedIn, "session effacée AVANT le logout") }
            return nil
        }
        await auth.signOut()
        XCTAssertNil(store.load())
        let r = try XCTUnwrap(fake.requests.last)
        XCTAssertEqual(r.url.path, "/auth/v1/logout")
        XCTAssertEqual(r.headers, ["apikey": "pk_test", "Authorization": "Bearer tok"])
        XCTAssertNil(r.body)
        XCTAssertEqual(observed.value.count, 1)
        XCTAssertNil(observed.value[0] ?? nil)
        // Échec du logout : sans effet.
        await auth.adopt(AuthSession(accessToken: "tok", refreshToken: "rt", expiresAt: 9e9, user: ["id": "u1"]))
        fake.intercept = { _ in throw CloudError.network("down") }
        await auth.signOut()
        XCTAssertFalse(auth.signedIn)
    }

    func testRestWrapperErrorsAndContentType() async throws {
        let fake = FakeSupabase()
        let auth = makeAuth(fake)
        await auth.adopt(AuthSession(accessToken: "tok", refreshToken: "rt", expiresAt: 9e9, user: ["id": "u1"]))
        let long = String(repeating: "é", count: 300)
        fake.intercept = { _ in HTTPResponse(status: 403, body: Data(long.utf8)) }
        do { try await auth.rest("GET", "/rest/v1/cognitive_aids?select=*"); XCTFail() } catch {
            let e = try XCTUnwrap(error as? CloudError)
            XCTAssertEqual(e.httpStatus, 403)
            XCTAssertEqual(e.message, "REST 403 " + String(repeating: "é", count: 200))
            XCTAssertEqual(restErrStatus(e.message), 403)
        }
        fake.intercept = { _ in HTTPResponse(status: 204) }
        let none = try await auth.rest("POST", "/rest/v1/aid_notes", body: [], extra: ["Prefer": "return=minimal"])
        XCTAssertNil(none)
        let r = try XCTUnwrap(fake.requests.last)
        XCTAssertEqual(r.headers["Prefer"], "return=minimal")
        XCTAssertEqual(r.headers["Authorization"], "Bearer tok")
        XCTAssertEqual(r.headers["Content-Type"], "application/json")
        fake.intercept = { _ in .json("approved") }
        let v = try await auth.rpc("my_status")
        XCTAssertEqual(v, "approved")
        XCTAssertEqual(fake.requests.last?.jsonBody, .object([:]))
        XCTAssertEqual(fake.requests.last?.url.absoluteString, "https://x.supabase.co/rest/v1/rpc/my_status")
        fake.intercept = { _ in throw CloudError.timeout(ms: 25000) }
        do { try await auth.rest("GET", "/rest/v1/x"); XCTFail() } catch { XCTAssertEqual(error as? CloudError, .timeout(ms: 25000)) }
    }

    func testStorageHeaders() async throws {
        let fake = FakeSupabase()
        let auth = makeAuth(fake)
        await auth.adopt(AuthSession(accessToken: "tok", refreshToken: "rt", expiresAt: 9e9, user: ["id": "u1"]))
        try await auth.storage("POST", "u/u1/a1.pdf", body: Data("%PDF-1".utf8), contentType: "application/pdf", extra: ["x-upsert": "true"])
        let r = try XCTUnwrap(fake.requests.last)
        XCTAssertEqual(r.url.absoluteString, "https://x.supabase.co/storage/v1/object/attachments/u/u1/a1.pdf")
        XCTAssertEqual(r.headers, ["apikey": "pk_test", "Authorization": "Bearer tok", "Content-Type": "application/pdf", "x-upsert": "true"])
        XCTAssertEqual(r.timeoutMs, 120_000)
        try await auth.storage("GET", "u/u1/a1.pdf")
        XCTAssertEqual(fake.requests.last?.headers, ["apikey": "pk_test", "Authorization": "Bearer tok"])
        do { try await auth.storage("DELETE", "u/u1/nope.pdf"); XCTFail() } catch {
            XCTAssertEqual((error as? CloudError)?.httpStatus, 404)
        }
    }

    func testDeleteAccountUsesPostWithoutRefresh() async throws {
        let fake = FakeSupabase()
        let auth = makeAuth(fake)
        // Jeton « expiré » : `_post` ne rafraîchit PAS (le code OTP vient d'en donner un frais).
        await auth.adopt(AuthSession(accessToken: "tok", refreshToken: "rt", expiresAt: 1, user: ["id": "u1"]))
        fake.rpcs["delete_my_account"] = { _ in .json(["code": "P0001", "message": "recent otp verification required"], status: 400) }
        do { try await auth.deleteAccount(); XCTFail() } catch {
            XCTAssertEqual(AccountAPI.deleteAccountErrorMessage(error),
                           "Confirmation expirée : cliquez sur « Renvoyer le code » puis saisissez le nouveau code.")
        }
        XCTAssertEqual(fake.log("/auth/v1/token").count, 0)
        fake.rpcs["delete_my_account"] = { _ in HTTPResponse(status: 204) }
        try await auth.deleteAccount()
        XCTAssertEqual(fake.requests.last?.headers["Authorization"], "Bearer tok")
        XCTAssertEqual(AccountAPI.deleteAccountErrorMessage(CloudError.api(status: 400, message: "super-admin account cannot be self-deleted")),
                       "Échec de la suppression : super-admin account cannot be self-deleted")
    }

    func testFileSecureStoreRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("sec-\(UUID().uuidString)")
        let s = FileSecureStore(url: dir.appendingPathComponent("auth.json"))
        XCTAssertNil(s.load())
        s.save(Data("x".utf8))
        XCTAssertEqual(s.load(), Data("x".utf8))
        s.save(nil)
        XCTAssertNil(s.load())
    }

    func testHealthProbe() async {
        let fake = FakeSupabase()
        let auth = makeAuth(fake)
        let up = await auth.probeHealth()
        XCTAssertTrue(up)
        XCTAssertEqual(fake.requests.last?.headers, ["apikey": "pk_test"])
        XCTAssertEqual(fake.requests.last?.timeoutMs, 3500)
        fake.intercept = { _ in HTTPResponse(status: 503) }
        let up503 = await auth.probeHealth()
        XCTAssertTrue(up503)   // tout statut HTTP = serveur joignable
        fake.intercept = { _ in throw CloudError.timeout(ms: 3500) }
        let down = await auth.probeHealth()
        XCTAssertFalse(down)
    }
}

final class AccountAPITests: XCTestCase {
    func signedIn(_ fake: FakeSupabase) async -> (AuthClient, AccountAPI) {
        let auth = AuthClient(config: testConfig, transport: fake, secureStore: InMemorySecureStore())
        await auth.adopt(AuthSession(accessToken: "tok", refreshToken: "rt", expiresAt: 9e9, user: ["id": .string(fake.userId), "email": "a@b.fr"]))
        return (auth, AccountAPI(auth: auth))
    }

    func testMembershipsDedupAndSort() async throws {
        let fake = FakeSupabase()
        fake.libraries = ["L2": "Zèbre", "L1": "Équipe", "L3": "Absente"]
        fake.memberships = [("u", "L2", "viewer"), ("v", "L2", "admin"), ("u", "L1", "editor"), ("w", "L1", "viewer")]
        fake.intercept = { r in
            // Une adhésion dont la bibliothèque n'est plus lisible (`libraries: null`) est écartée.
            if r.url.path == "/rest/v1/memberships" {
                return .json([["role": "editor", "library_id": "L2", "libraries": ["id": "L2", "name": "Zèbre"]],
                              ["role": "admin", "library_id": "L2", "libraries": ["id": "L2", "name": "Zèbre"]],
                              ["role": "viewer", "library_id": "L1", "libraries": ["id": "L1", "name": "Anesthésie"]],
                              ["role": "admin", "library_id": "L3", "libraries": .null]])
            }
            return nil
        }
        let (_, api) = await signedIn(fake)
        let libs = try await api.memberships()
        XCTAssertEqual(libs, [LibraryInfo(id: "L1", name: "Anesthésie", role: .viewer), LibraryInfo(id: "L2", name: "Zèbre", role: .admin)])
        XCTAssertEqual(fake.requests.last?.url.absoluteString, "https://x.supabase.co/rest/v1/memberships?select=role,library_id,libraries(id,name)")
    }

    func testMembersAndLibrariesCalls() async throws {
        let fake = FakeSupabase()
        let (_, api) = await signedIn(fake)
        fake.rpcs["invite_member"] = { b in
            XCTAssertEqual(b, ["p_library": "L1", "p_email": "x@y.fr", "p_role": "editor"])
            return .json("not_found")
        }
        let inv = try await api.inviteMember(library: "L1", email: "x@y.fr")
        XCTAssertEqual(inv, .notFound)
        XCTAssertEqual(inv.message, "Aucun compte avec cet e-mail. La personne doit d'abord se connecter une fois à l'application.")
        fake.rpcs["invite_member"] = rpcValue("not_approved")
        let inv2 = try await api.inviteMember(library: "L1", email: "x@y.fr", role: .viewer)
        XCTAssertEqual(inv2, .notApproved)
        fake.rpcs["invite_member"] = rpcValue("ok")
        let inv3 = try await api.inviteMember(library: "L1", email: "x@y.fr")
        XCTAssertEqual(inv3, .ok)

        try await api.setMemberRole(library: "L 1", user: "u2", role: .admin)
        var r = try XCTUnwrap(fake.requests.last)
        XCTAssertEqual(r.method, "PATCH")
        XCTAssertEqual(r.url.absoluteString, "https://x.supabase.co/rest/v1/memberships?library_id=eq.L%201&user_id=eq.u2")
        XCTAssertEqual(r.jsonBody, ["role": "admin"])
        XCTAssertEqual(r.headers["Prefer"], "return=minimal")
        try await api.removeMember(library: "L1", user: "u2")
        r = try XCTUnwrap(fake.requests.last)
        XCTAssertEqual(r.method, "DELETE"); XCTAssertNil(r.body)
        XCTAssertEqual(r.headers["Prefer"], "return=minimal")
        try await api.renameLibrary(id: "L1", name: "Nouveau")
        XCTAssertEqual(fake.requests.last?.url.absoluteString, "https://x.supabase.co/rest/v1/libraries?id=eq.L1")
        XCTAssertEqual(fake.requests.last?.jsonBody, ["name": "Nouveau"])
        try await api.deleteLibrary(id: "L1")
        XCTAssertEqual(fake.requests.last?.method, "DELETE")
        let id = try await api.createLibrary(name: "SMUR Nord")
        XCTAssertTrue(id.hasPrefix("lib-smur-nord-"))
        XCTAssertEqual(fake.requests.last?.jsonBody, [["id": .string(id), "name": "SMUR Nord"]])
        XCTAssertEqual(fake.requests.last?.headers["Prefer"], "return=minimal")

        fake.rpcs["list_members"] = { b in
            XCTAssertEqual(b, ["p_library": "L1"])
            return .json([["user_id": "u1", "email": "moi@x.fr", "role": "admin"], ["user_id": "u2", "email": "toi@x.fr", "role": "bogus"]])
        }
        let m = try await api.listMembers(library: "L1")
        XCTAssertEqual(m.map(\.role), [.admin, .viewer])
        XCTAssertEqual(m[0].initials, "MO")
        let warn = await api.orphanAdminWarning(libraries: [LibraryInfo(id: "L1", name: "Équipe", role: .admin)], myUserId: "u1")
        XCTAssertEqual(warn, "Vous êtes le seul administrateur de : Équipe. Nommez un autre administrateur avant de partir (fenêtre « Gérer » de la bibliothèque), sinon seul l'administrateur de l'instance pourra en gérer les membres.")
    }

    func testAdminCalls() async throws {
        let fake = FakeSupabase()
        let (_, api) = await signedIn(fake)
        fake.rpcs["get_approval_required"] = rpcValue(.null)
        let req = try await api.approvalRequired()
        XCTAssertTrue(req)                                            // `!== false`
        fake.rpcs["get_approval_required"] = rpcValue(false)
        let req2 = try await api.approvalRequired()
        XCTAssertFalse(req2)
        fake.rpcs["set_approval_required"] = { b in XCTAssertEqual(b, ["p_value": false]); return HTTPResponse(status: 204) }
        try await api.setApprovalRequired(false)
        fake.rpcs["set_user_status"] = { b in XCTAssertEqual(b, ["p_user": "u9", "p_status": "rejected"]); return HTTPResponse(status: 204) }
        try await api.setUserStatus(user: "u9", approved: false)
        fake.rpcs["delete_rejected_user"] = { b in XCTAssertEqual(b, ["p_user": "u9"]); return HTTPResponse(status: 204) }
        try await api.deleteRejectedUser(user: "u9")
        fake.rpcs["list_unapproved_users"] = rpcValue([["user_id": "u9", "email": "e@x.fr", "status": "rejected", "created_at": "2026-01-01"]])
        let pend = try await api.listUnapprovedUsers()
        XCTAssertEqual(pend.first?.badge, "Refusé")
        fake.rpcs["get_instance_stats"] = rpcValue(["users": 12, "fiches_perso": 3, "fiches_shared": 4, "storage_bytes": 1024])
        let st = try await api.instanceStats()
        XCTAssertEqual(st?.users, 12); XCTAssertEqual(st?.fiches, 7); XCTAssertEqual(st?.storageBytes, 1024)
        fake.rpcs["get_instance_stats"] = rpcValue(.null)
        let st2 = try await api.instanceStats()
        XCTAssertNil(st2)
        fake.rpcs["my_status"] = rpcValue("pending")
        let ms = try await api.myStatus()
        XCTAssertEqual(ms, .pending)
    }
}

/// Boîte partagée thread-safe pour les observateurs des tests.
final class TestBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _v: T
    init(_ v: T) { _v = v }
    var value: T { lock.lock(); defer { lock.unlock() }; return _v }
    func mutate(_ f: (inout T) -> Void) { lock.lock(); f(&_v); lock.unlock() }
}
