import Foundation

// COMPTE, BIBLIOTHÈQUES ET ADMINISTRATION — appels « serveur direct » de la PWA : statut du compte
// (`my_status`), profil (adhésions + rôles + app-admin), membres d'une bibliothèque, création /
// renommage / suppression de bibliothèque, comptes en attente, état de l'instance.
//
// RAPPEL DE SÉCURITÉ : les rôles lus ici ne servent qu'à l'ERGONOMIE (griser « Modifier », ne pas
// pousser ce que la RLS refuserait). La seule autorité est la RLS du serveur ; un rôle périmé en
// cache ne donne AUCUN accès.

/// `my_status()` : `pending` | `approved` | `rejected` (nil = hors connexion / inconnu).
public enum AccountStatus: String, Sendable, Equatable {
    case pending, approved, rejected
    /// Libellé de l'écran d'attente.
    public var label: String {
        switch self { case .pending: return "En attente de validation"; case .rejected: return "Demande refusée"; case .approved: return "Validé" }
    }
}

/// `memberships.role`. Rang : viewer 1 < editor 2 < admin 3.
public enum LibraryRole: String, Sendable, Equatable, CaseIterable {
    case viewer, editor, admin
    public var rank: Int { switch self { case .viewer: return 1; case .editor: return 2; case .admin: return 3 } }
    /// `ROLE_FR`.
    public var label: String { switch self { case .viewer: return "Lecteur"; case .editor: return "Éditeur"; case .admin: return "Admin" } }
    public var canEdit: Bool { self == .editor || self == .admin }
    /// Légende des rôles.
    public static let caption = "Rôles : Lecteur (consulte) · Éditeur (rédige) · Admin (gère les membres)."
}

/// Une bibliothèque partagée dont je suis membre (`myLibraries`).
public struct LibraryInfo: Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var role: LibraryRole
    public init(id: String, name: String, role: LibraryRole) { self.id = id; self.name = name; self.role = role }
    public var json: JSON { ["id": .string(id), "name": .string(name), "role": .string(role.rawValue)] }

    /// `sanitizeLibs` : 200 au plus, id `safeMetaId` (sinon écartée), nom ≤ 120, rôle inconnu → lecteur.
    public static func sanitize(_ v: JSON?) -> [LibraryInfo] {
        (v?.array ?? []).prefix(200).compactMap { l in
            guard let id = Guard.safeMetaId(l["id"]) else { return nil }
            return LibraryInfo(id: id, name: Guard.sstr(l["name"], 120), role: LibraryRole(rawValue: l["role"]?.string ?? "") ?? .viewer)
        }
    }
}

/// L'état du compte vu par l'app — `myLibraries`, `myIsAppAdmin`, `myPendingCount`, `myAccountStatus`.
public struct Profile: Equatable, Sendable {
    public var libraries: [LibraryInfo] = []
    public var isAppAdmin = false
    /// Comptes en attente (app-admin seulement).
    public var pendingCount = 0
    public var accountStatus: AccountStatus? = nil
    public init() {}

    public func role(of library: String?) -> LibraryRole? {
        guard let library else { return nil }
        return libraries.first(where: { $0.id == library })?.role
    }
    /// `canEditScope(scope)` : Perso toujours, une bibliothèque si éditeur ou admin.
    public func canEdit(scope library: String?) -> Bool {
        guard let library, !library.isEmpty else { return true }
        return role(of: library)?.canEdit ?? false
    }
    /// Un lecteur ne voit pas les brouillons d'une bibliothèque partagée.
    public func canSee(library: String?, status: Status) -> Bool { canEdit(scope: library) || status != .draft }
    /// Nombre de bibliothèques de la ligne « Sur cet appareil » (Perso compte).
    public var libraryCount: Int { libraries.count + 1 }

    /// Forme du cache `ac-profile-<uid>` : `{libraries, isAppAdmin}`.
    public var cacheJSON: JSON { ["libraries": .array(libraries.map(\.json)), "isAppAdmin": .bool(isAppAdmin)] }
    /// `loadProfileCache` : restaure bibliothèques et drapeau app-admin (assainis).
    public mutating func restore(cache j: JSON) {
        libraries = LibraryInfo.sanitize(j["libraries"])
        isAppAdmin = j["isAppAdmin"] == .bool(true)
    }
    /// Empreinte de `loadProfile` (re-rendu seulement si elle change).
    var fingerprint: String { JSON.array([.array(libraries.map(\.json)), .bool(isAppAdmin), .number(Double(pendingCount))]).text() }
}

public struct Member: Equatable, Sendable, Identifiable {
    public var userId: String
    public var email: String
    public var role: LibraryRole
    public var id: String { userId }
    public var initials: String { JS.prefix(JS.trim(email), 2).uppercased() }
}

public struct PendingUser: Equatable, Sendable, Identifiable {
    public var userId: String
    public var email: String
    public var status: AccountStatus
    public var createdAt: String
    public var id: String { userId }
    /// Badge de la liste.
    public var badge: String { status == .rejected ? "Refusé" : "En attente" }
}

/// Réponse de `invite_member`.
public enum InviteResult: Equatable, Sendable {
    case ok, notFound, notApproved, other(String)
    /// Message à afficher (nil pour `ok`).
    public var message: String? {
        switch self {
        case .ok: return nil
        case .notFound: return "Aucun compte avec cet e-mail. La personne doit d'abord se connecter une fois à l'application."
        case .notApproved: return "Ce compte est en attente de validation (ou a été refusé) : il ne peut pas être ajouté à une bibliothèque tant qu'un administrateur ne l'a pas approuvé."
        case .other(let s): return "Échec : " + s
        }
    }
}

/// `get_instance_stats()` (app-admin).
public struct InstanceStats: Equatable, Sendable {
    public var users = 0, pending = 0, rejected = 0, libraries = 0
    public var fichesPerso = 0, fichesShared = 0, protocols = 0
    public var sharesLive = 0, sharesRows = 0, sessions = 0
    public var storageBytes: Double = 0, attachmentsBytes: Double = 0
    public init() {}
    public init(json j: JSON) {
        func n(_ k: String) -> Int { let v = JS.number(j[k]); return v.isFinite ? Int(v) : 0 }
        users = n("users"); pending = n("pending"); rejected = n("rejected"); libraries = n("libraries")
        fichesPerso = n("fiches_perso"); fichesShared = n("fiches_shared"); protocols = n("protocols")
        sharesLive = n("shares_live"); sharesRows = n("shares_rows"); sessions = n("sessions")
        let sb = JS.number(j["storage_bytes"]), ab = JS.number(j["attachments_bytes"])
        storageBytes = sb.isFinite ? sb : 0; attachmentsBytes = ab.isFinite ? ab : 0
    }
    public var fiches: Int { fichesPerso + fichesShared }
}

/// Appels « serveur direct » du compte et de l'administration. Aucun état : chaque méthode est un
/// appel REST/RPC au format EXACT de la PWA (mêmes chemins, mêmes corps, `Prefer` compris).
public struct AccountAPI: Sendable {
    public let auth: AuthClient
    public init(auth: AuthClient) { self.auth = auth }

    static let minimal = ["Prefer": "return=minimal"]
    func enc(_ s: String) -> String { jsEncodeURIComponent(s) }

    // MARK: Statut

    /// R1 `my_status` (null → nil ; valeur inconnue → nil).
    public func myStatus() async throws -> AccountStatus? {
        guard let s = try await auth.rpc("my_status")?.string else { return nil }
        return AccountStatus(rawValue: s)
    }
    /// R2 `is_app_admin` — `=== true`.
    public func isAppAdmin() async throws -> Bool { try await auth.rpc("is_app_admin") == .bool(true) }
    /// R4 `is_approved` — `=== true`.
    public func isApproved() async throws -> Bool { try await auth.rpc("is_approved") == .bool(true) }
    /// R6 `get_instance_stats` (nil si l'appelant n'est pas app-admin).
    public func instanceStats() async throws -> InstanceStats? {
        guard let j = try await auth.rpc("get_instance_stats"), j.object != nil else { return nil }
        return InstanceStats(json: j)
    }

    // MARK: Profil

    /// T12 : mes adhésions, DÉDOUBLONNÉES par bibliothèque au rôle le plus élevé, triées par nom.
    /// Comme le web, la requête n'est PAS filtrée sur `user_id` (spec D, Q3) : la RLS rend aussi
    /// les adhésions des AUTRES membres des bibliothèques que j'administre (et toutes pour un
    /// app-admin) — la déduplication garde alors le rôle le plus élevé de la bibliothèque.
    public func memberships() async throws -> [LibraryInfo] {
        let rows = try await auth.rest("GET", "/rest/v1/memberships?select=role,library_id,libraries(id,name)")?.array ?? []
        var by: [String: LibraryInfo] = [:]
        var order: [String] = []
        for r in rows {
            guard let lib = r["libraries"], lib.object != nil, let id = r["library_id"]?.string else { continue }
            // Rôle inconnu : lu comme lecteur (le web le garderait brut, puis `sanitizeLibs` le
            // ramène à « viewer » au cache — même résultat à la relecture).
            let role = LibraryRole(rawValue: r["role"]?.string ?? "") ?? .viewer
            let name = lib["name"].map { $0.isNull ? "" : $0.jsString } ?? ""
            if let cur = by[id] {
                if role.rank > cur.role.rank { by[id] = LibraryInfo(id: id, name: name, role: role) }
            } else {
                by[id] = LibraryInfo(id: id, name: name, role: role)
                order.append(id)
            }
        }
        let libs = order.compactMap { by[$0] }
        return libs.sorted { $0.name.compare($1.name, options: [], range: nil, locale: Locale.current) == .orderedAscending }
    }

    // MARK: Membres (admin de la bibliothèque, ou app-admin)

    /// R7 `list_members` — `[{user_id, email, role}]`, trié par rôle puis e-mail côté serveur.
    public func listMembers(library: String) async throws -> [Member] {
        let rows = try await auth.rpc("list_members", ["p_library": .string(library)])?.array ?? []
        return rows.compactMap { r in
            guard let u = r["user_id"]?.string else { return nil }
            return Member(userId: u, email: r["email"]?.string ?? "", role: LibraryRole(rawValue: r["role"]?.string ?? "") ?? .viewer)
        }
    }
    /// R8 `invite_member` — rôle par défaut de l'interface : ÉDITEUR. La personne doit s'être
    /// connectée une fois (le compte doit exister) et être approuvée.
    public func inviteMember(library: String, email: String, role: LibraryRole = .editor) async throws -> InviteResult {
        let r = try await auth.rpc("invite_member", ["p_library": .string(library), "p_email": .string(email), "p_role": .string(role.rawValue)])
        switch r?.string {
        case "ok": return .ok
        case "not_found": return .notFound
        case "not_approved": return .notApproved
        default: return .other(r?.jsString ?? "")
        }
    }
    /// T13 : changer le rôle d'un membre.
    public func setMemberRole(library: String, user: String, role: LibraryRole) async throws {
        try await auth.rest("PATCH", "/rest/v1/memberships?library_id=eq." + enc(library) + "&user_id=eq." + enc(user),
                            body: ["role": .string(role.rawValue)], extra: Self.minimal)
    }
    /// T14 : retirer un membre.
    public func removeMember(library: String, user: String) async throws {
        try await auth.rest("DELETE", "/rest/v1/memberships?library_id=eq." + enc(library) + "&user_id=eq." + enc(user), extra: Self.minimal)
    }

    // MARK: Bibliothèques

    /// T15 : renommer (admin de la bibliothèque ou app-admin).
    public func renameLibrary(id: String, name: String) async throws {
        try await auth.rest("PATCH", "/rest/v1/libraries?id=eq." + enc(id), body: ["name": .string(name)], extra: Self.minimal)
    }
    /// T16 : supprimer (app-admin) — fiches, protocoles, catégories et adhésions suivent en cascade.
    public func deleteLibrary(id: String) async throws {
        try await auth.rest("DELETE", "/rest/v1/libraries?id=eq." + enc(id), extra: Self.minimal)
    }
    /// T17 : créer (app-admin) ; le déclencheur serveur `lib_add_creator` fait du créateur un admin.
    /// Rend l'identifiant créé.
    @discardableResult
    public func createLibrary(name: String) async throws -> String {
        let id = Self.newLibraryId(name: name)
        try await auth.rest("POST", "/rest/v1/libraries", body: [["id": .string(id), "name": .string(name)]], extra: Self.minimal)
        return id
    }
    /// `'lib-' + (catSlug(name).slice(0,32) || 'x') + '-' + 4 caractères base 36 aléatoires`.
    public static func newLibraryId(name: String) -> String {
        let slug = JS.prefix(catSlug(name), 32)
        let alphabet = Array("0123456789abcdefghijklmnopqrstuvwxyz")
        var g = SystemRandomNumberGenerator()
        let r = String((0..<4).map { _ in alphabet[Int.random(in: 0..<36, using: &g)] })
        return "lib-" + (slug.isEmpty ? "x" : slug) + "-" + r
    }

    // MARK: Comptes en attente (app-admin)

    /// R3 `list_unapproved_users` — comptes en attente OU refusés.
    public func listUnapprovedUsers() async throws -> [PendingUser] {
        let rows = try await auth.rpc("list_unapproved_users")?.array ?? []
        return rows.compactMap { r in
            guard let u = r["user_id"]?.string else { return nil }
            return PendingUser(userId: u, email: r["email"]?.string ?? "",
                               status: AccountStatus(rawValue: r["status"]?.string ?? "") ?? .pending,
                               createdAt: r["created_at"]?.string ?? "")
        }
    }
    /// R9 `get_approval_required` — `!== false` (toute autre réponse compte comme « exigée »).
    public func approvalRequired() async throws -> Bool { try await auth.rpc("get_approval_required") != .bool(false) }
    /// R10 `set_approval_required`.
    public func setApprovalRequired(_ value: Bool) async throws { try await auth.rpc("set_approval_required", ["p_value": .bool(value)]) }
    /// R11 `set_user_status` — approuver ou refuser (le refus purge les adhésions côté serveur).
    public func setUserStatus(user: String, approved: Bool) async throws {
        try await auth.rpc("set_user_status", ["p_user": .string(user), "p_status": .string(approved ? "approved" : "rejected")])
    }
    /// R12 `delete_rejected_user`.
    public func deleteRejectedUser(user: String) async throws { try await auth.rpc("delete_rejected_user", ["p_user": .string(user)]) }

    // MARK: Suppression du compte

    /// Libère le compte côté serveur (R5). Le message d'erreur « recent otp verification
    /// required » se traduit par `deleteAccountErrorMessage`.
    public func deleteAccount() async throws { try await auth.deleteAccount() }

    /// Message de l'étape 2 de la suppression après un échec.
    public static func deleteAccountErrorMessage(_ e: Error) -> String {
        let m = (e as? CloudError)?.message ?? String(describing: e)
        if m.lowercased().contains("otp verification") {
            return "Confirmation expirée : cliquez sur « Renvoyer le code » puis saisissez le nouveau code."
        }
        return "Échec de la suppression : " + m
    }

    /// Avertissement « seul administrateur » (étape 1 de la suppression) : pour chaque bibliothèque
    /// que j'administre, un autre admin existe-t-il ? Rend le message, ou nil. Non bloquant.
    public func orphanAdminWarning(libraries: [LibraryInfo], myUserId: String) async -> String? {
        var names: [String] = []
        // Comme le web : le moindre échec abandonne l'avertissement (jamais bloquant).
        for l in libraries where l.role == .admin {
            guard let rows = try? await listMembers(library: l.id) else { return nil }
            if !rows.contains(where: { $0.role == .admin && $0.userId != myUserId }) { names.append(l.name.isEmpty ? l.id : l.name) }
        }
        guard !names.isEmpty else { return nil }
        return "Vous êtes le seul administrateur de : " + names.joined(separator: ", ") + ". Nommez un autre administrateur avant de partir (fenêtre « Gérer » de la bibliothèque), sinon seul l'administrateur de l'instance pourra en gérer les membres."
    }
}

/// `canReturnToAnon(status, everSynced, liveCount)` : le retour « hors compte » n'est offert qu'à
/// un compte NON APPROUVÉ que cet appareil n'a JAMAIS synchronisé — ses ids n'ont jamais été
/// réclamés dans le cloud, leur adoption par un autre compte ne peut pas entrer en collision.
public func canReturnToAnon(status: AccountStatus?, everSynced: Bool, liveCount: Int) -> Bool {
    (status == .pending || status == .rejected) && !everSynced && liveCount > 0
}
