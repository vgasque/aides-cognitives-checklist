import SwiftUI
import AidesCore

// BIBLIOTHÈQUES PARTAGÉES — port d'`openMembers`/`renderMembers` (« Modifier la bibliothèque »),
// `openNewLib`/`renderNewLib` (« Nouvelle bibliothèque ») et `openPending` (« Comptes en attente »).
// RAPPEL : les rôles lus ici ne servent qu'à l'ERGONOMIE ; la seule autorité est la RLS du
// serveur. Ajouts, rôles et retraits s'appliquent IMMÉDIATEMENT (seul le NOM s'enregistre).

// MARK: - « Modifier la bibliothèque »

struct MembersView: View {
    var libraryId: String

    init(libraryId: String) { self.libraryId = libraryId }

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var originalName = ""
    @State private var nameMsg: AcctMessage?
    @State private var saving = false
    @State private var members: [Member] = []
    @State private var loading = true
    @State private var loadFailed = false
    @State private var inviteEmail = ""
    @State private var inviteRole: LibraryRole = .editor
    @State private var memMsg: AcctMessage?
    @State private var confirm: AcctConfirm?

    private var api: AccountAPI { model.sync.api }
    private var me: String? { model.auth.userId }
    /// Admin de CETTE bibliothèque, ou administrateur de l'instance.
    private var isAdmin: Bool { model.profile.role(of: libraryId) == .admin || model.profile.isAppAdmin }
    private var nameDirty: Bool { JS.trim(name) != originalName }

    var body: some View {
        AcctWindow(title: "Modifier la bibliothèque", maxWidth: 720, onClose: { close() },
                   confirm: isAdmin ? AcctBarAction(title: "Enregistrer", systemImage: "checkmark", disabled: saving) { Task { await saveName() } } : nil) {
            nameBlock
            BoldText(text: "Bibliothèque partagée : les droits d'accès sont appliqués **côté serveur** ; elle reste consultable hors ligne une fois synchronisée.",
                     size: TypeScale.meta, color: T.ink2)
                .fixedSize(horizontal: false, vertical: true)
            membersBlock
            if model.profile.isAppAdmin { dangerZone }
        }
        .acctConfirm($confirm)
        .interactiveDismissDisabled(nameDirty)
        .task { await load(first: true) }
    }

    private func close() {
        if nameDirty {
            confirm = AcctConfirm(message: "Abandonner les modifications ?", yes: "Abandonner", danger: true) { r in
                if case .yes = r { dismiss() }
            }
        } else { dismiss() }
    }

    private func load(first: Bool) async {
        if first {
            let n = JS.trim(model.library.libraryName(libraryId))
            name = n
            originalName = n
        }
        loading = true
        do {
            members = try await api.listMembers(library: libraryId)
            loadFailed = false
        } catch {
            loadFailed = true
        }
        loading = false
    }

    // MARK: Nom

    @ViewBuilder
    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nom").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
            TextField("Ex. Équipe déchocage", text: $name)
                .aFont(TypeScale.item, .regular)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(minHeight: Ctrl.l)
                .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.ctlLine))
                .disabled(!isAdmin)
                .onChange(of: name) { _, v in if v.count > 60 { name = String(v.prefix(60)) } }
                .accessibilityLabel("Nom de la bibliothèque")
            AcctMessageLine(message: nameMsg)
            // « Annuler » = ✕ (à gauche), « Enregistrer » = ✓ (à droite) : ils ne portent QUE sur le nom.
        }
    }

    private func saveName() async {
        let nn = JS.trim(name)
        // CTA verrouillé mais jamais muet : le toucher dit pourquoi.
        if nn.isEmpty { nameMsg = .err("Le nom ne peut pas être vide."); return }
        if nn == model.library.libraryName(libraryId) { dismiss(); return }
        saving = true
        do {
            try await api.renameLibrary(id: libraryId, name: nn)
            await model.sync.loadProfile()
            originalName = nn
            dismiss()
        } catch {
            saving = false
            nameMsg = .err("Renommage impossible : " + acctErrorMessage(error))
        }
    }

    // MARK: Membres

    @ViewBuilder
    private var membersBlock: some View {
        HStack(spacing: 4) {
            Text("Membres").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
            Text("· \(members.count)").aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        if loading && members.isEmpty {
            HStack(spacing: 8) {
                ProgressView()
                Text("Chargement des membres…").aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2)
            }
        } else if loadFailed {
            Text("Erreur de chargement des membres.").aFont(TypeScale.body, .semibold).foregroundStyle(T.crit)
        } else {
            WorkCard(padding: 0) {
                VStack(spacing: 0) {
                    if members.isEmpty {
                        Text("Aucun membre pour le moment.").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2).padding(12)
                    }
                    ForEach(Array(members.enumerated()), id: \.element.id) { i, m in
                        if i > 0 { Divider().overlay(T.line) }
                        memberRow(m)
                    }
                }
            }
        }
        if isAdmin { inviteRow }
        AcctMessageLine(message: memMsg)
    }

    private func memberRow(_ m: Member) -> some View {
        let mine = m.userId == me
        return HStack(spacing: 10) {
            AcctAvatar(email: m.email, size: 34, tint: T.ink2)
            (Text(m.email).foregroundColor(T.ink) + Text(mine ? " (vous)" : "").foregroundColor(T.ink2))
                .aFont(TypeScale.body, .semibold)
                .lineLimit(2)
            Spacer(minLength: 6)
            if mine {
                Text(m.role.label).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
                    .padding(.horizontal, 10).frame(minHeight: 26)
                    .background(T.amb2, in: Capsule())
            } else {
                Picker("Rôle de " + m.email, selection: Binding<LibraryRole>(get: { m.role }, set: { r in Task { await setRole(m, r) } })) {
                    ForEach(LibraryRole.allCases, id: \.self) { r in Text(r.label).tag(r) }
                }
                .labelsHidden()
                .fixedSize()
                .accessibilityLabel("Rôle de " + m.email)
                Button { askRemove(m) } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        .frame(width: Ctrl.l, height: Ctrl.l).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(T.ink2)
                .help("Retirer de la bibliothèque")
                .accessibilityLabel("Retirer " + m.email)
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: Ctrl.row)
    }

    private func setRole(_ m: Member, _ r: LibraryRole) async {
        guard r != m.role else { return }
        do {
            try await api.setMemberRole(library: libraryId, user: m.userId, role: r)
            if let i = members.firstIndex(where: { $0.userId == m.userId }) { members[i].role = r }
            await model.sync.loadProfile()
        } catch {
            memMsg = .err("⚠ Modification du rôle impossible : " + acctErrorMessage(error))
            await load(first: false)
        }
    }

    private func askRemove(_ m: Member) {
        confirm = AcctConfirm(message: "Retirer ce membre de la bibliothèque ?", yes: "Retirer", danger: true) { r in
            guard case .yes = r else { return }
            Task { @MainActor in
                do {
                    try await api.removeMember(library: libraryId, user: m.userId)
                    await load(first: false)
                } catch {
                    memMsg = .err("⚠ Retrait impossible : " + acctErrorMessage(error))
                }
            }
        }
    }

    private var inviteRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                TextField("email@exemple.fr", text: $inviteEmail)
                    .aFont(TypeScale.item, .regular)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif
                    .padding(.horizontal, 12)
                    .frame(minHeight: Ctrl.l)
                    .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.ctlLine))
                    .accessibilityLabel("E-mail du nouveau membre")
                    .onSubmit { Task { await invite() } }
                Picker("Rôle du nouveau membre", selection: $inviteRole) {
                    ForEach(LibraryRole.allCases, id: \.self) { r in Text(r.label).tag(r) }
                }
                .labelsHidden()
                .fixedSize()
                Button { Task { await invite() } } label: {
                    Text("＋").aFont(TypeScale.stepL, .bold).frame(width: Ctrl.l, height: Ctrl.l)
                }
                .buttonStyle(.a(.primary, Ctrl.l))
                .help("Inviter (la personne doit s'être connectée une fois à l'app)")
                .accessibilityLabel("Inviter ce membre")
            }
            BoldText(text: "Rôles : Lecteur (consulte) · Éditeur (rédige) · Admin (gère les membres). La personne doit s'être **connectée une fois** à l'app. Ajouts, rôles et retraits s'appliquent **immédiatement**.",
                     size: TypeScale.meta, color: T.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func invite() async {
        let email = JS.trim(inviteEmail)
        guard acctEmailLooksValid(email) else { memMsg = .err("Saisissez un e-mail valide."); return }
        memMsg = .info("Invitation…")
        do {
            let r = try await api.inviteMember(library: libraryId, email: email, role: inviteRole)
            if let m = r.message {
                memMsg = .err(m)
            } else {
                memMsg = nil
                inviteEmail = ""
                await load(first: false)
                await model.sync.loadProfile()
            }
        } catch {
            memMsg = .err("Échec : " + acctErrorMessage(error))
        }
    }

    // MARK: Zone sensible (administrateur de l'instance)

    private var dangerZone: some View {
        let nFi = model.fiches.filter { $0.library == libraryId }.count
        let nPr = model.references.filter { $0.library == libraryId }.count
        let scope = (nFi > 0 || nPr > 0) ? "Supprime \(nFi) aide\(acctS(nFi)) et \(nPr) protocole\(acctS(nPr)) pour tous les membres. " : ""
        let caption = scope + "Action irréversible — confirmation demandée."
        return VStack(alignment: .leading, spacing: 8) {
            Divider().overlay(T.line)
            AcctZoneTitle(text: "Zone sensible", color: T.crit)
            Button("Supprimer la bibliothèque…") { askDelete() }
                .buttonStyle(.a(.danger, Ctrl.l))
            Text(caption)
                .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
        }
    }

    private func askDelete() {
        let n = model.library.libraryName(libraryId)
        confirm = AcctConfirm(title: "Supprimer la bibliothèque",
                              message: "Supprimer DÉFINITIVEMENT la bibliothèque « " + n + " » et TOUTES ses fiches partagées ? Action irréversible.",
                              yes: "Supprimer définitivement", danger: true) { r in
            guard case .yes = r else { return }
            Task { @MainActor in
                do {
                    try await api.deleteLibrary(id: libraryId)
                    originalName = JS.trim(name)
                    dismiss()
                    await model.sync.loadProfile()
                    model.toast("Bibliothèque supprimée.")
                    // La réconciliation retire les copies locales de la bibliothèque disparue.
                    await model.sync.full()
                } catch {
                    memMsg = .err("⚠ Suppression impossible : " + acctErrorMessage(error))
                }
            }
        }
    }
}

// MARK: - « Nouvelle bibliothèque » (administrateur de l'instance seulement)

struct NewLibraryView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var msg: AcctMessage?
    @State private var busy = false
    @State private var confirm: AcctConfirm?
    @FocusState private var focused: Bool

    var body: some View {
        AcctWindow(title: "Nouvelle bibliothèque", maxWidth: 480, onClose: { close() }) {
            BoldText(text: "Une **bibliothèque** est un espace partagé : les fiches qu'elle contient sont accessibles aux membres que vous y invitez (rôle lecteur, éditeur ou admin), pour travailler à plusieurs sur les mêmes aides cognitives — une équipe, un service...",
                     size: TypeScale.body, color: T.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Nom").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
            TextField("Ex. Équipe déchocage", text: $name)
                .aFont(TypeScale.item, .regular)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(minHeight: Ctrl.l)
                .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.ctlLine))
                .focused($focused)
                .onChange(of: name) { _, v in if v.count > 60 { name = String(v.prefix(60)) } }
                .onSubmit { Task { await create() } }
                .accessibilityLabel("Nom de la bibliothèque")
            BoldText(text: "Les droits d'accès sont appliqués **côté serveur** ; la bibliothèque reste consultable hors ligne une fois synchronisée.",
                     size: TypeScale.meta, color: T.ink2)
                .fixedSize(horizontal: false, vertical: true)
            AcctMessageLine(message: msg)
            Button("Créer la bibliothèque") { Task { await create() } }
                .buttonStyle(.a(.primary, Ctrl.l, full: true))
                .opacity(JS.trim(name).isEmpty ? 0.55 : 1)
                .help(JS.trim(name).isEmpty ? "Donnez d’abord un nom à la bibliothèque" : "")
                .disabled(busy)
        }
        .acctConfirm($confirm)
        .interactiveDismissDisabled(!JS.trim(name).isEmpty)
        .onAppear { focused = true }
    }

    private func close() {
        if !JS.trim(name).isEmpty {
            confirm = AcctConfirm(message: "Abandonner les modifications ?", yes: "Abandonner", danger: true) { r in
                if case .yes = r { dismiss() }
            }
        } else { dismiss() }
    }

    private func create() async {
        let n = JS.trim(name)
        guard !n.isEmpty else { msg = .err("Donnez un nom à la bibliothèque."); return }
        guard model.profile.isAppAdmin else { msg = .err("Seul un administrateur peut créer une bibliothèque."); return }
        busy = true
        msg = .info("Création…")
        do {
            try await model.sync.api.createLibrary(name: n)
            await model.sync.loadProfile()
            name = ""
            dismiss()
            model.toast("Bibliothèque « " + n + " » créée.")
        } catch {
            busy = false
            msg = .err("Création impossible : " + acctErrorMessage(error))
        }
    }
}

// MARK: - « Comptes en attente » (administrateur de l'instance)

struct PendingAccountsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var users: [PendingUser] = []
    @State private var required = true
    @State private var loading = true
    @State private var failed = false
    @State private var msg: AcctMessage?
    @State private var confirm: AcctConfirm?

    private var api: AccountAPI { model.sync.api }

    var body: some View {
        AcctWindow(title: "Comptes en attente", maxWidth: 480, onClose: { dismiss() }) {
            if loading {
                HStack(spacing: 8) { ProgressView(); Text("Chargement…").aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2) }
            } else if failed {
                Text("Erreur de chargement.").aFont(TypeScale.body, .semibold).foregroundStyle(T.crit)
            } else {
                AcctCheckRow(label: "Exiger une validation pour les nouveaux comptes",
                             isOn: Binding(get: { required }, set: { v in Task { await setRequired(v) } }))
                Text(required ? "Chaque nouveau compte reste « en attente » jusqu'à votre approbation ci-dessous."
                              : "Désactivé : les nouveaux comptes sont approuvés automatiquement, sans validation de votre part.")
                    .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Ces comptes ont vérifié leur e-mail (code reçu)"
                     + (required ? " mais attendent votre approbation pour synchroniser leurs fiches dans le cloud" : "") + ".")
                    .aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if users.isEmpty {
                    Text("Aucun compte en attente.").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                } else {
                    WorkCard(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(users.enumerated()), id: \.element.id) { i, u in
                                if i > 0 { Divider().overlay(T.line) }
                                row(u)
                            }
                        }
                    }
                }
                AcctMessageLine(message: msg)
            }
        }
        .acctConfirm($confirm)
        .task { await load() }
    }

    private func load() async {
        loading = true
        do {
            async let u = api.listUnapprovedUsers()
            async let r = api.approvalRequired()
            users = try await u
            required = try await r
            failed = false
        } catch {
            failed = true
        }
        loading = false
    }

    private func row(_ u: PendingUser) -> some View {
        HStack(spacing: 10) {
            AcctAvatar(email: u.email, size: 34, tint: T.ink2)
            VStack(alignment: .leading, spacing: 2) {
                Text(u.email).aFont(TypeScale.body, .semibold).foregroundStyle(T.ink).lineLimit(2)
                Text(u.badge).aFont(TypeScale.meta, .bold).foregroundStyle(u.status == .rejected ? T.ink2 : T.warn)
            }
            Spacer(minLength: 6)
            Button("Approuver") { Task { await approve(u) } }.buttonStyle(.a(.primary, Ctrl.s))
            if u.status == .rejected {
                Button("Supprimer") { askDeleteRejected(u) }
                    .buttonStyle(.a(.secondary, Ctrl.s))
                    .help("Supprimer la demande pour laisser une 2e chance")
            } else {
                Button { askReject(u) } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        .frame(width: Ctrl.l, height: Ctrl.l).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(T.ink2)
                .help("Refuser")
                .accessibilityLabel("Refuser " + u.email)
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: Ctrl.row)
    }

    private func setRequired(_ v: Bool) async {
        let before = required
        required = v
        do {
            try await api.setApprovalRequired(v)
            msg = .info(v ? "Validation des nouveaux comptes réactivée." : "Validation désactivée : les nouveaux comptes seront approuvés automatiquement.")
        } catch {
            required = before
            msg = .err("⚠ Échec : " + acctErrorMessage(error))
        }
    }

    private func approve(_ u: PendingUser) async {
        do {
            try await api.setUserStatus(user: u.userId, approved: true)
            await load()
            await model.sync.loadProfile()
            msg = .info("Compte approuvé.")
        } catch { msg = .err("⚠ Échec : " + acctErrorMessage(error)) }
    }

    private func askReject(_ u: PendingUser) {
        confirm = AcctConfirm(message: "Refuser ce compte ?", yes: "Refuser", danger: true) { r in
            guard case .yes = r else { return }
            Task { @MainActor in
                do {
                    try await api.setUserStatus(user: u.userId, approved: false)
                    await load()
                    await model.sync.loadProfile()
                } catch { msg = .err("⚠ Échec : " + acctErrorMessage(error)) }
            }
        }
    }

    private func askDeleteRejected(_ u: PendingUser) {
        confirm = AcctConfirm(message: "Supprimer définitivement ce compte refusé ? La personne pourra recréer un compte avec cette adresse e-mail (nouvelle demande à valider).",
                              yes: "Supprimer") { r in
            guard case .yes = r else { return }
            Task { @MainActor in
                do {
                    try await api.deleteRejectedUser(user: u.userId)
                    await load()
                    msg = .info("Compte supprimé.")
                } catch { msg = .err("⚠ Échec : " + acctErrorMessage(error)) }
            }
        }
    }
}
