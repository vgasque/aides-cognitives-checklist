import SwiftUI
import AidesCore

// « MOI » / « COMPTE & SYNCHRONISATION » — port de `openAuth`, `renderAuth` et de ses quatre
// écrans (`renderAuthLogin` e-mail puis code, `renderAuthAccount`, `renderAuthPending`,
// `renderAuthDelete` en deux étapes), du bloc de préférences (`accountPrefsHtml`), de la section
// « Bibliothèques » (`acctLibsHtml`), de l'état de l'instance (`loadInstanceStats`) et de la
// fenêtre « Erreur de synchronisation ». Textes repris verbatim (spec D §5, C1 §3.14).
//
// Sur la PWA, une bascule d'espace (connexion d'un AUTRE compte, retour « hors compte »,
// effacement) RECHARGE la page ; ici `AppModel.switchSpace` remplace tout l'état en mémoire —
// même garantie : jamais deux comptes mélangés.

struct AccountView: View {
    init() {}

    fileprivate enum LoginStep { case email, code }

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented

    // Connexion
    @State private var signedIn = false
    @State private var step: LoginStep = .email
    @State private var email = ""
    @State private var code = ""
    @State private var busy = false
    @State private var msg: AcctMessage?
    @State private var anonCount = 0
    // En attente
    @State private var checking = false
    // Suppression du compte
    @State private var deleteStep: Int?
    @State private var deleteWipe = false
    @State private var deleteTyped = ""
    @State private var deleteCode = ""
    @State private var deleteMsg: AcctMessage?
    @State private var deleteBusy: String?
    @State private var orphanWarning: String?
    // Fenêtres
    @State private var sheet: AccountSheet?
    @State private var confirm: AcctConfirm?
    @State private var export: AcctExportRequest?

    var body: some View {
        // Racine de l'onglet « Moi » (dans la NavigationStack de l'onglet) : grand titre, pas de ✕.
        // Présentée en feuille : sa propre NavigationStack, titre de la PWA, ✕ à gauche.
        AcctWindow(title: isPresented ? "Compte & synchronisation" : "Moi", maxWidth: 720,
                   embedded: !isPresented, largeTitle: !isPresented, onClose: closeAction) {
            screen
        }
        .acctConfirm($confirm)
        .background { Color.clear.sheet(item: $sheet) { s in sheetView(s) } }
        .background { Color.clear.acctExporter($export, model: model) }
        .onAppear { opened() }
        .onChange(of: model.syncStatus) { _, _ in signedIn = model.auth.signedIn }
    }

    /// ✕ seulement quand la vue est PRÉSENTÉE (feuille) ; intégrée à la colonne ≥ 780, pas de ✕.
    private var closeAction: (() -> Void)? {
        guard isPresented else { return nil }
        let d = dismiss
        return { d() }
    }

    @ViewBuilder
    private var screen: some View {
        if !signedIn {
            if step == .email { loginEmail } else { loginCode }
        } else if let s = deleteStep {
            if s == 1 { deleteStepOne } else { deleteStepTwo }
        } else if model.profile.accountStatus == .pending || model.profile.accountStatus == .rejected {
            pendingScreen
        } else {
            accountScreen
        }
    }

    @ViewBuilder
    private func sheetView(_ s: AccountSheet) -> some View {
        switch s {
        case .members(let id): MembersView(libraryId: id)
        case .newLibrary: NewLibraryView()
        case .pending: PendingAccountsView()
        case .storage: StorageInfoView()
        case .syncError: SyncErrorView()
        }
    }

    /// `openAuth()` : relit l'état du compte et redemande les modifications retenues.
    private func opened() {
        signedIn = model.auth.signedIn
        if !signedIn {
            email = model.auth.email ?? email
            anonCount = model.acctAnonFicheCount()
            return
        }
        Task { @MainActor in
            await model.sync.refreshAccountStatus()
            confirmHeldEdits()
        }
    }

    private var sessionEmail: String { JS.trim(model.auth.email ?? "") }
    private var accentColor: Color { AcctAccent.color(model.sync.prefs.accent) }

    // MARK: - Connexion : e-mail

    @ViewBuilder
    private var loginEmail: some View {
        WorkCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "envelope").aFont(TypeScale.val, .semibold).foregroundStyle(T.act)
                    .accessibilityHidden(true)
                Text("Recevez un code par e-mail pour vous connecter ou créer votre compte.")
                    .aFont(TypeScale.item, .semibold).foregroundStyle(T.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Adresse e-mail").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                TextField("vous@exemple.fr", text: $email)
                    .modifier(AcctFieldStyle())
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif
                    .submitLabel(.send)
                    .onSubmit { Task { await sendCode() } }
                    .accessibilityLabel("Adresse e-mail")
                Button(busy ? "Envoi du code…" : "Recevoir le code") { Task { await sendCode() } }
                    .buttonStyle(.a(.primary, Ctrl.l, full: true))
                    .disabled(busy)
                AcctMessageLine(message: msg)
                Text("Vos fiches restent votre contenu — n'y stockez jamais de données patient. Synchronisation hébergée sur Supabase (connexion chiffrée).")
                    .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                if anonCount > 0 {
                    Button { model.acctSwitchToAnon(); dismissIfPresented() } label: {
                        Text("Cet appareil contient \(anonCount) fiche\(acctS(anonCount)) hors compte — les consulter sans se connecter")
                            .aFont(TypeScale.body, .bold).multilineTextAlignment(.leading)
                            .frame(minHeight: Ctrl.s).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(T.act)
                }
            }
        }
        DisclosureGroup {
            StorageExplainContent().padding(.top, 8)
        } label: {
            Text("Pourquoi créer un compte ?").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                .frame(minHeight: Ctrl.m)
        }
        AccountPrefsBlock(signedIn: false, onExport: { exportAll() }, onStorage: { sheet = .storage })
    }

    private func sendCode() async {
        let e = JS.trim(email)
        guard acctEmailLooksValid(e) else { msg = .err("E-mail invalide."); return }
        guard model.sync.isOnline() else { msg = .err("Hors ligne : une connexion Internet est nécessaire pour recevoir le code."); return }
        busy = true
        msg = nil
        do {
            try await model.auth.sendCode(email: e)
            email = e
            code = ""
            step = .code
        } catch {
            msg = .err("Échec de l'envoi : " + acctErrorMessage(error))
        }
        busy = false
    }

    // MARK: - Connexion : code

    @ViewBuilder
    private var loginCode: some View {
        WorkCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "lock").aFont(TypeScale.val, .semibold).foregroundStyle(T.act)
                    .accessibilityHidden(true)
                Text("Saisissez le code").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink)
                    .accessibilityAddTraits(.isHeader)
                BoldText(text: "Un code a été envoyé à **" + email + "**.", size: TypeScale.body, color: T.ink)
                codeField($code, onSubmit: { Task { await verify() } })
                Button(busy ? "Vérification…" : "Valider") { Task { await verify() } }
                    .buttonStyle(.a(.primary, Ctrl.l, full: true))
                    .disabled(busy)
                AcctMessageLine(message: msg)
                Button { step = .email; msg = nil; code = "" } label: {
                    Text("← Changer d'e-mail").aFont(TypeScale.body, .bold).frame(minHeight: Ctrl.s).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(T.act)
            }
        }
    }

    /// Champ de code : chiffres seulement (un collage garde les chiffres), 12 au plus.
    private func codeField(_ binding: Binding<String>, onSubmit: @escaping () -> Void) -> some View {
        TextField("••••••••", text: binding)
            .modifier(AcctFieldStyle(mono: true))
            #if os(iOS)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            #endif
            .onChange(of: binding.wrappedValue) { _, v in
                let d = String(v.unicodeScalars.filter { $0.value >= 48 && $0.value <= 57 }.prefix(12).map { Character($0) })
                if d != v { binding.wrappedValue = d }
            }
            .onSubmit(onSubmit)
            .accessibilityLabel("Code reçu par e-mail")
    }

    private func verify() async {
        let digits = code
        guard !digits.isEmpty else { msg = .err("Saisissez le code reçu."); return }
        guard model.sync.isOnline() else { msg = .err("Hors ligne : une connexion Internet est nécessaire pour vérifier le code."); return }
        busy = true
        msg = nil
        do {
            try await model.auth.verifyCode(email: JS.trim(email), code: digits)
        } catch {
            busy = false
            msg = .err("Code invalide ou expiré.")
            return
        }
        let uid = model.auth.userId ?? ""
        // Depuis l'espace « sans compte » AVEC du contenu : proposer d'EMPORTER les fiches (les
        // titres sont listés : sur un appareil partagé, on doit reconnaître ce qu'on emporte).
        // Entre deux comptes : jamais de transfert.
        if !uid.isEmpty && uid != model.store.currentSpace && model.store.currentSpace.isEmpty && !model.fiches.isEmpty {
            let fs = model.fiches
            let n = fs.count
            let labels = fs.prefix(5).map { f -> String in
                let t = JS.trim(JS.prefix(f.title, 48))
                return "« " + (t.isEmpty ? "sans titre" : t) + " »"
            }
            let more = n > 5 ? " et \(n - 5) autre\(acctS(n - 5))" : ""
            let names = labels.joined(separator: ", ") + more
            let verb = n > 1 ? "sont enregistrées" : "est enregistrée"
            confirm = AcctConfirm(title: "Fiches locales",
                                  message: "\(n) fiche\(acctS(n)) (avec notes et sessions) \(verb) sur cet appareil hors compte : \(names)"
                                    + ". Les emporter dans ce compte ? Elles y seront synchronisées (une fois le compte validé, si l'instance exige une validation). Laissées hors compte, elles resteront consultables sans connexion, via le lien « fiches hors compte » de l'écran de connexion.",
                                  yes: "Les emporter dans ce compte", no: "Les laisser hors compte") { r in
                if case .yes = r { model.acctTakeAnonymousData(to: uid) }
                Task { @MainActor in await finishSignIn() }
            }
            return
        }
        await finishSignIn()
    }

    private func finishSignIn() async {
        signedIn = true
        step = .email
        code = ""
        msg = nil
        busy = false
        await model.afterSignIn()
        signedIn = model.auth.signedIn
        confirmHeldEdits()
    }

    /// `confirmHeldEdits()` : modifications faites pendant que CE compte était déconnecté
    /// (appareil partagé) — ✕ garde la liste et la question reviendra.
    private func confirmHeldEdits() {
        guard model.auth.signedIn, let p = model.sync.pendingHeldEdits() else { return }
        confirm = AcctConfirm(title: "Modifications hors connexion", message: p.message,
                              yes: "Les synchroniser", no: "Les écarter") { r in
            switch r {
            case .yes: model.sync.resolveHeldEdits(sync: true)
            case .no:
                if let m = model.sync.resolveHeldEdits(sync: false) { model.toast(m, seconds: 8) }
                model.refresh()
            case .dismissed: break
            }
        }
    }

    private func dismissIfPresented() { if isPresented { dismiss() } }

    // MARK: - Compte validé

    @ViewBuilder
    private var accountScreen: some View {
        identityCard
        BoldText(text: "Votre bibliothèque personnelle suit ce compte sur **tous vos appareils connectés**.", size: TypeScale.body, color: T.ink2)
            .fixedSize(horizontal: false, vertical: true)
        librariesSection
        AccountPrefsBlock(signedIn: true, onExport: nil, onStorage: { sheet = .storage })
        if model.profile.isAppAdmin {
            AcctZoneTitle(text: "Administration")
            AccountStatsBlock(onPending: { sheet = .pending })
            Text("Compte administrateur : la suppression se fait depuis la console d’administration (garde-fou).")
                .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            dangerZone(button: "Supprimer mon compte et mes données…",
                       caption: "Supprime le compte, les fiches synchronisées et les partages. Action irréversible — confirmation demandée.")
        }
    }

    private var identityCard: some View {
        let st = model.syncStatus
        let offline = !model.sync.isOnline()
        let busyNow = st.state == .busy
        return WorkCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    AcctAvatar(email: sessionEmail, size: 48, tint: accentColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sessionEmail).aFont(TypeScale.item, .bold).foregroundStyle(T.ink).lineLimit(2)
                        statusLine
                    }
                }
                ImportFlow(spacing: 8, lineSpacing: 8) {
                    Button("Synchroniser") { Task { await model.sync.full() } }
                        .buttonStyle(.a(.secondary, Ctrl.m))
                        .disabled(offline || busyNow)
                        .help(offline ? "Hors ligne : la synchronisation reprendra automatiquement au retour du réseau." : "")
                    Button("Exporter") { exportAll() }
                        .buttonStyle(.a(.secondary, Ctrl.m))
                    Button("Se déconnecter") { askSignOut() }
                        .buttonStyle(.a(.secondary, Ctrl.m))
                }
            }
        }
    }

    /// Ligne d'état (`authStateHtml`) : pastille + mot ; « · HH:MM » de la dernière synchro réussie.
    private var statusLine: some View {
        let st = model.syncStatus
        let line = st.accountLine(lastSyncAt: model.sync.lastSyncAt)
        return Button { if st.state == .err { sheet = .syncError } } label: {
            HStack(spacing: 6) {
                Circle().fill(AcctSyncDot.color(st.state)).frame(width: 8, height: 8)
                Text(line).aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink2)
                if st.state == .err {
                    Image(systemName: "chevron.right").aFont(TypeScale.cap, .bold).foregroundStyle(T.ink3)
                }
            }
            .frame(minHeight: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(st.state != .err)
        .help(st.state.tooltip)
        .accessibilityLabel("État de la synchronisation : " + line)
    }

    // MARK: Bibliothèques (`acctLibsHtml`)

    private func itemCount(_ lib: String?) -> Int {
        model.fiches.filter { $0.library == lib }.count + model.references.filter { $0.library == lib }.count
    }

    @ViewBuilder
    private var librariesSection: some View {
        AcctZoneTitle(text: "Bibliothèques")
        WorkCard(padding: 0) {
            VStack(spacing: 0) {
                AcctMenuRow(icon: "person", title: "Perso", sub: "votre bibliothèque · " + acctPlural(itemCount(nil), "élément", "éléments"))
                    .padding(.horizontal, 12)
                ForEach(model.profile.libraries.sorted { acctNameLess($0.name, $1.name) }) { l in
                    Divider().overlay(T.line)
                    libraryRow(l)
                }
                if model.profile.isAppAdmin {
                    Divider().overlay(T.line)
                    Button { sheet = .newLibrary } label: {
                        AcctMenuRow(icon: "plus", title: "＋ Nouvelle bibliothèque", tint: T.act).padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func libraryRow(_ l: LibraryInfo) -> some View {
        let name = l.name.isEmpty ? "Bibliothèque partagée" : l.name
        let sub = l.role.label + " · " + acctPlural(itemCount(l.id), "élément", "éléments")
        let icon = l.role == .viewer ? "lock" : "books.vertical"
        if l.role == .admin || model.profile.isAppAdmin {
            Button { sheet = .members(l.id) } label: {
                AcctMenuRow(icon: icon, title: name, sub: sub, chevron: true).padding(.horizontal, 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Modifier la bibliothèque « " + name + " »")
        } else {
            AcctMenuRow(icon: icon, title: name, sub: sub).padding(.horizontal, 12)
                .accessibilityElement(children: .combine)
        }
    }

    // MARK: Zone sensible

    private func dangerZone(button: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            AcctZoneTitle(text: "Zone sensible", color: T.crit)
            Button(button) { startDelete() }
                .buttonStyle(.a(.danger, Ctrl.l))
            Text(caption).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Déconnexion (`confirmLeave` → `doSignOut`)

    private var canReturn: Bool {
        canReturnToAnon(status: model.profile.accountStatus, everSynced: model.sync.accountEverSynced(), liveCount: model.library.liveFicheCount)
    }

    private func askSignOut() {
        let st = model.profile.accountStatus
        let notApproved = st == .pending || st == .rejected
        let offerReturn = notApproved && canReturn
        var c = AcctConfirm(title: "Se déconnecter",
                            message: "Se déconnecter ? Vous pourrez ensuite vous reconnecter, ou utiliser un autre compte.",
                            yes: "Se déconnecter") { r in
            guard case .yes(let checked) = r else { return }
            Task { @MainActor in
                if offerReturn && checked { await returnToAnon() }
                else { await signOut(wipe: !notApproved && checked) }
            }
        }
        if !notApproved {
            c.check = "Effacer aussi les fiches de ce compte sur cet appareil (elles restent disponibles dans votre espace en ligne)"
        } else if offerReturn {
            c.check = "Ramener d'abord les fiches de ce compte « hors compte » sur cet appareil (recommandé : ce compte n'étant pas validé, elles n'existent nulle part ailleurs)"
            c.checkSafe = true
        }
        confirm = c
    }

    private func signOut(wipe: Bool) async {
        if wipe { model.acctDropLiveSessions() }
        await model.signOut(wipe: wipe)
        resetLogin()
    }

    private func returnToAnon() async {
        if await model.acctReturnToAnon() { resetLogin() }
    }

    private func resetLogin() {
        signedIn = model.auth.signedIn
        step = .email
        code = ""
        msg = nil
        busy = false
        deleteStep = nil
        anonCount = model.acctAnonFicheCount()
    }

    // MARK: - Compte en attente / refusé

    @ViewBuilder
    private var pendingScreen: some View {
        let st = model.profile.accountStatus ?? .pending
        WorkCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    AcctAvatar(email: sessionEmail, size: 48, tint: T.ink2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sessionEmail).aFont(TypeScale.item, .bold).foregroundStyle(T.ink).lineLimit(2)
                        Text(either(st == .rejected, "△ ", "○ ") + st.label).aFont(TypeScale.meta, .bold).foregroundStyle(T.warn)
                    }
                }
                Text((st == .rejected
                      ? "Votre demande de compte a été refusée par un administrateur. Vous pouvez supprimer cette demande ci-dessous, ou réessayer avec une autre adresse e-mail."
                      : "Votre e-mail est vérifié. Un administrateur doit maintenant approuver votre compte avant que vos fiches ne soient synchronisées dans le cloud. En attendant, l'app reste pleinement utilisable en local, sur cet appareil.")
                     + either(canReturn, " Vos fiches ne sont enregistrées que sur cet appareil : vous pouvez les ramener « hors compte » pour les garder accessibles sans ce compte.", ""))
                    .aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
                    .fixedSize(horizontal: false, vertical: true)
                ImportFlow(spacing: 8, lineSpacing: 8) {
                    Button(checking ? "Vérification…" : "Vérifier maintenant") { Task { await checkNow() } }
                        .buttonStyle(.a(.primary, Ctrl.m))
                        .disabled(checking)
                    if canReturn {
                        Button("Ramener mes fiches hors compte") { askReturn() }
                            .buttonStyle(.a(.secondary, Ctrl.m))
                    }
                    Button("Se déconnecter") { askSignOut() }
                        .buttonStyle(.a(.secondary, Ctrl.m))
                }
            }
        }
        AccountPrefsBlock(signedIn: true, onExport: nil, onStorage: { sheet = .storage })
        dangerZone(button: "Supprimer cette demande de compte…",
                   caption: "Supprime le compte, les fiches synchronisées et les partages. Action irréversible — confirmation demandée.")
    }

    private func checkNow() async {
        checking = true
        await model.sync.refreshAccountStatus()
        let st = model.sync.profile.accountStatus
        if st == .approved {
            await model.sync.full()
        } else if st == .rejected || st == .pending {
            model.sync.setStatus(st == .rejected ? .rejected : .pending)
        }
        checking = false
    }

    private func askReturn() {
        let n = model.library.liveFicheCount
        let head = n > 1
            ? "Vos \(n) fiches (avec notes et sessions) redeviendront des fiches locales « hors compte » sur cet appareil, consultables sans connexion."
            : "Votre fiche (avec notes et sessions) redeviendra une fiche locale « hors compte » sur cet appareil, consultable sans connexion."
        confirm = AcctConfirm(title: "Ramener les fiches hors compte",
                              message: head + " Vous serez déconnecté de ce compte ; une connexion ultérieure proposera à nouveau de " + either(n > 1, "les ", "l'") + "emporter.",
                              yes: "Ramener hors compte") { r in
            if case .yes = r { Task { @MainActor in await returnToAnon() } }
        }
    }

    // MARK: - Suppression du compte (deux étapes)

    private func startDelete() {
        deleteStep = 1
        deleteWipe = false
        deleteTyped = ""
        deleteCode = ""
        deleteMsg = nil
        deleteBusy = nil
        orphanWarning = nil
    }

    @ViewBuilder
    private var deleteStepOne: some View {
        let delReturn = canReturn
        let typedOK = JS.trim(deleteTyped).uppercased() == "SUPPRIMER"
        WorkCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "exclamationmark.triangle").aFont(TypeScale.val, .semibold).foregroundStyle(T.crit)
                    .accessibilityHidden(true)
                Text("Supprimer le compte ?").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink)
                    .accessibilityAddTraits(.isHeader)
                BoldText(text: delReturn
                         ? "Cette action est **irréversible**. Ce compte n'a jamais été synchronisé : vos fiches n'existent **que sur cet appareil**. Après la suppression, elles redeviendront des fiches locales « hors compte », consultables sans connexion."
                         : "Cette action est **irréversible**. Votre compte et votre bibliothèque personnelle synchronisée seront définitivement supprimés du cloud. Les fiches que vous avez ajoutées à des bibliothèques partagées y resteront.",
                         size: TypeScale.body, color: T.ink)
                    .fixedSize(horizontal: false, vertical: true)
                BoldText(text: "Par sécurité, votre identité doit être vérifiée : un **code de confirmation** vous sera envoyé à **" + sessionEmail + "**, à saisir avant la suppression.",
                         size: TypeScale.body, color: T.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let w = orphanWarning {
                    Text(w).aFont(TypeScale.body, .semibold).foregroundStyle(T.warn)
                        .fixedSize(horizontal: false, vertical: true)
                }
                AcctCheckRow(label: "Effacer aussi les fiches enregistrées sur **cet appareil**" + either(delReturn, " **(attention : elles n'existent nulle part ailleurs)**", ""),
                             isOn: $deleteWipe, danger: true)
                BoldText(text: "Pour confirmer, tapez **SUPPRIMER** ci-dessous :", size: TypeScale.body, color: T.ink)
                TextField("SUPPRIMER", text: $deleteTyped)
                    .modifier(AcctFieldStyle())
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.characters)
                    #endif
                    .accessibilityLabel("Tapez SUPPRIMER pour confirmer")
                AcctMessageLine(message: deleteMsg)
                HStack(spacing: 10) {
                    Button(deleteBusy ?? "Recevoir le code de confirmation") { askDeleteCode() }
                        .buttonStyle(.a(.danger, Ctrl.l, full: true))
                        .disabled(!typedOK || deleteBusy != nil)
                    Button("Annuler") { deleteStep = nil }
                        .buttonStyle(.a(.secondary, Ctrl.l))
                }
            }
        }
        .task {
            // Bibliothèques ORPHELINES : avertissement NON bloquant, chargé en asynchrone.
            guard let uid = model.auth.userId else { return }
            orphanWarning = await model.sync.api.orphanAdminWarning(libraries: model.profile.libraries, myUserId: uid)
        }
    }

    private func askDeleteCode() {
        guard model.sync.isOnline() else { deleteMsg = .err("Hors ligne : une connexion Internet est nécessaire pour recevoir le code."); return }
        let wipe = deleteWipe
        confirm = AcctConfirm(title: "Supprimer le compte",
                              message: "Supprimer DÉFINITIVEMENT votre compte" + either(wipe, " et les données de cet appareil", "") + " ? Un code de confirmation va vous être envoyé par e-mail.",
                              yes: "Recevoir le code", danger: true) { r in
            guard case .yes = r else { return }
            Task { @MainActor in
                deleteBusy = "Envoi du code…"
                do {
                    try await model.auth.sendCode(email: sessionEmail)
                    deleteBusy = nil
                    deleteMsg = nil
                    deleteCode = ""
                    deleteStep = 2
                } catch {
                    deleteBusy = nil
                    deleteMsg = .err("Échec de l'envoi du code : " + acctErrorMessage(error))
                }
            }
        }
    }

    @ViewBuilder
    private var deleteStepTwo: some View {
        WorkCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "lock").aFont(TypeScale.val, .semibold).foregroundStyle(T.crit)
                    .accessibilityHidden(true)
                Text("Confirmez votre identité").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink)
                    .accessibilityAddTraits(.isHeader)
                BoldText(text: "Un code vient d'être envoyé à **" + sessionEmail + "**. Saisissez-le pour confirmer la suppression **définitive et irréversible** de votre compte.",
                         size: TypeScale.body, color: T.ink)
                    .fixedSize(horizontal: false, vertical: true)
                codeField($deleteCode, onSubmit: { Task { await deleteNow() } })
                AcctMessageLine(message: deleteMsg)
                HStack(spacing: 10) {
                    Button(deleteBusy ?? "Supprimer définitivement") { Task { await deleteNow() } }
                        .buttonStyle(.a(.danger, Ctrl.l, full: true))
                        .disabled(deleteBusy != nil)
                    Button("Annuler") { deleteStep = nil; deleteBusy = nil }
                        .buttonStyle(.a(.secondary, Ctrl.l))
                }
                Button { Task { await resendDeleteCode() } } label: {
                    Text("Renvoyer le code").aFont(TypeScale.body, .bold).frame(minHeight: Ctrl.s).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(T.act)
                .disabled(deleteBusy != nil)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func resendDeleteCode() async {
        guard model.sync.isOnline() else { deleteMsg = .err("Hors ligne : une connexion Internet est nécessaire pour recevoir le code."); return }
        deleteMsg = .info("Envoi du code…")
        do {
            try await model.auth.sendCode(email: sessionEmail)
            deleteMsg = .info("Code renvoyé.")
        } catch {
            deleteMsg = .err("Échec de l'envoi : " + acctErrorMessage(error))
        }
    }

    private func deleteNow() async {
        let digits = deleteCode
        guard !digits.isEmpty else { deleteMsg = .err("Saisissez le code reçu par e-mail."); return }
        deleteBusy = "Vérification…"
        // La vérification renouvelle la session (preuve serveur) ; en cas d'échec RIEN n'est supprimé.
        do {
            try await model.auth.verifyCode(email: sessionEmail, code: digits)
        } catch {
            deleteBusy = nil
            deleteMsg = .err("Code invalide ou expiré.")
            return
        }
        deleteBusy = "Suppression…"
        deleteMsg = .info("Suppression…")
        do {
            try await model.acctDeleteAccount(wipe: deleteWipe)
            deleteBusy = nil
            resetLogin()
        } catch {
            deleteBusy = nil
            deleteMsg = .err(AccountAPI.deleteAccountErrorMessage(error))
        }
    }

    // MARK: - Exporter mes données (`exportAll`)

    private func exportAll() {
        let fs = model.fiches, rs = model.references
        let ids = Exporter.attachmentIds(fiches: fs, references: rs)
        guard !ids.isEmpty else {
            export = model.acctBuildExport(fiches: fs, references: rs, categories: model.categories, base: "aides-cognitives", withDocuments: false)
            return
        }
        confirm = AcctConfirm(title: "Exporter", message: Exporter.docsQuestion(ids.count),
                              yes: "Avec les documents (.zip)", no: "Sans les documents (.json)") { r in
            switch r {
            case .yes: export = model.acctBuildExport(fiches: fs, references: rs, categories: model.categories, base: "aides-cognitives", withDocuments: true)
            case .no: export = model.acctBuildExport(fiches: fs, references: rs, categories: model.categories, base: "aides-cognitives", withDocuments: false)
            case .dismissed: break
            }
        }
    }
}

/// Les fenêtres ouvertes depuis « Moi ».
enum AccountSheet: Identifiable {
    case members(String), newLibrary, pending, storage, syncError
    var id: String {
        switch self {
        case .members(let i): return "members:" + i
        case .newLibrary: return "newLibrary"
        case .pending: return "pending"
        case .storage: return "storage"
        case .syncError: return "syncError"
        }
    }
}

/// Champ de saisie des fenêtres du compte (16 pt au toucher : sous 16, iOS zoome au focus — règle 9).
struct AcctFieldStyle: ViewModifier {
    var mono = false
    func body(content: Content) -> some View {
        content
            .aFont(16, .regular, mono ? .mono : .ui)  // design: champ tactile, plancher 16 (règle 9, exemption de check-type)
            .textFieldStyle(.plain)
            .padding(.horizontal, 12)
            .frame(minHeight: Ctrl.l)
            .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.ctlLine))
    }
}

/// Couleur de la pastille d'état : vert = nominal ; ambre = attention (erreur de synchro, compte
/// en attente ou refusé) — une panne de synchro ne TUE pas, elle n'est pas rouge (règle 8) ; le
/// mot, lui, dit toujours l'état.
enum AcctSyncDot {
    static func color(_ s: SyncState) -> Color {
        switch s {
        case .ok: return T.ok
        case .busy: return T.act
        case .off: return T.ink3
        case .err, .pending, .rejected: return T.warn
        }
    }
}

/// Couleurs d'accent (`body[data-accent]`) : elles ne teintent QUE le disque du compte.
enum AcctAccent {
    /// Valeurs GÉNÉRÉES depuis `body[data-accent]` de la PWA (`Accent`, Tokens.generated.swift).
    static func color(_ id: String) -> Color { Accent.color(id) ?? T.act }
}

// MARK: - « Sur cet appareil » et préférences (`accountPrefsHtml`)

struct AccountPrefsBlock: View {
    var signedIn: Bool
    /// « Exporter mes données » (écran de connexion seulement ; connecté, « Exporter » est dans la carte d'identité).
    var onExport: (() -> Void)?
    var onStorage: () -> Void

    @Environment(AppModel.self) private var model
    @State private var accent = ""
    @State private var sessSync = false
    @State private var tags: [JournalTag] = []
    @State private var essaiX1 = false
    @State private var essaiX2 = false
    @State private var confirm: AcctConfirm?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            AcctZoneTitle(text: "Sur cet appareil")
            deviceCard
            AcctZoneTitle(text: "Affichage")
            display
            if signedIn { accentPicker; sessionsSync }
            tagsEditor
        }
        .acctConfirm($confirm)
        .onAppear {
            let p = model.sync.prefs
            accent = p.accent
            sessSync = p.syncSessions
            tags = p.tags
            essaiX1 = model.store.global.string("ac-essai-x1") == "1"
            essaiX2 = model.store.global.string("ac-essai-x2") == "1"
        }
    }

    private var deviceCard: some View {
        let nf = model.fiches.count, np = model.references.count, nl = model.profile.libraryCount
        return WorkCard {
            VStack(alignment: .leading, spacing: 10) {
                BoldText(text: "**\(nf)** aide\(acctS(nf)) · **\(np)** protocole\(acctS(np)) · **\(nl)** bibliothèque\(acctS(nl))",
                         size: TypeScale.item, color: T.ink)
                ImportFlow(spacing: 8, lineSpacing: 8) {
                    if let onExport {
                        Button("Exporter mes données", action: onExport).buttonStyle(.a(.secondary, Ctrl.m))
                    }
                    Button("Un problème ?", action: onStorage).buttonStyle(.a(.secondary, Ctrl.m))
                }
            }
        }
    }

    private func prefRow<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
            content()
        }
    }

    private var display: some View {
        WorkCard {
            VStack(alignment: .leading, spacing: 16) {
                prefRow("Thème") {
                    AcctSegmented(options: ThemePref.allCases.map { AcctSegOption(value: $0, label: $0.label) },
                                  selection: Binding(get: { model.theme }, set: { model.theme = $0; model.sync.schedulePrefsPush() }),
                                  accessibilityLabel: "Thème")
                }
                prefRow("Taille du texte") {
                    AcctSegmented(options: [AcctSegOption(value: 100, label: "A", size: TypeScale.body, a11y: "Taille du texte M · 100 %"),
                                            AcctSegOption(value: 115, label: "A", size: TypeScale.step, a11y: "Taille du texte L · 115 %"),
                                            AcctSegOption(value: 130, label: "A", size: TypeScale.stepL, a11y: "Taille du texte XL · 130 %")],
                                  selection: Binding(get: { model.textScale }, set: { v in
                                      model.textScale = v
                                      model.store.global["ac-zoom"] = .number(Double(v))
                                      model.sync.schedulePrefsPush()
                                  }),
                                  accessibilityLabel: "Taille du texte")
                    AcctHint(text: "S'applique à **toute l'application**.",
                             more: "Enregistrée pour votre compte, comme le thème (bouton de l'en-tête) : vous la retrouvez sur vos autres appareils connectés.")
                }
                prefRow("Ouvrir les aides en") {
                    AcctSegmented(options: [AcctSegOption(value: "overview", label: "Un bloc"), AcctSegOption(value: "static", label: "Toute la fiche")],
                                  selection: Binding(get: { model.readMode }, set: { model.readMode = $0; model.sync.schedulePrefsPush() }),
                                  accessibilityLabel: "Ouvrir les aides en")
                    AcctHint(text: "Le format dans lequel une aide s'ouvre. Pendant un soin, « ⤢ Tout voir » montre la fiche entière et **ramène au bloc** sans changer ce réglage.", more: nil)
                }
                essais
            }
        }
    }

    /// Deux ESSAIS d'affichage (A380), sur cet appareil seulement (`ac-essai-x1` / `ac-essai-x2`, non synchronisés).
    private var essais: some View {
        VStack(alignment: .leading, spacing: 12) {
            prefRow("Essai · Capsule") {
                AcctSegmented(options: [AcctSegOption(value: false, label: "Tuiles"), AcctSegOption(value: true, label: "Horizon")],
                              selection: Binding(get: { essaiX1 }, set: { essaiX1 = $0; model.store.global.set("ac-essai-x1", $0 ? "1" : nil) }),
                              accessibilityLabel: "Essai · Capsule")
            }
            prefRow("Essai · Instruments") {
                AcctSegmented(options: [AcctSegOption(value: false, label: "Colonne"), AcctSegOption(value: true, label: "Bande")],
                              selection: Binding(get: { essaiX2 }, set: { essaiX2 = $0; model.store.global.set("ac-essai-x2", $0 ? "1" : nil) }),
                              accessibilityLabel: "Essai · Instruments")
            }
            AcctHint(text: "Essais d'affichage de la session, sur cet appareil seulement : **Horizon** dessine les minuteurs en cours sur les 5 prochaines minutes ; **Bande** met les instruments sous le titre dès la tablette, la colonne de droite gardant le journal et les repères posologiques.", more: nil)
        }
    }

    private var accentPicker: some View {
        WorkCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Couleur d'accent").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                ImportFlow(spacing: 10, lineSpacing: 10) {
                    ForEach(PrefValues.accents, id: \.self) { id in
                        let on = accent == id
                        let label = PrefValues.accentLabels[id] ?? id
                        Button {
                            accent = id
                            model.sync.prefs.accent = id
                            model.sync.schedulePrefsPush()
                        } label: {
                            VStack(spacing: 4) {
                                Circle().fill(AcctAccent.color(id)).frame(width: 30, height: 30)
                                    .overlay(Circle().strokeBorder(on ? T.ink : Color.clear, lineWidth: 2).padding(-4))
                                    .overlay { if on { Image(systemName: "checkmark").aFont(TypeScale.meta, .heavy).foregroundStyle(T.paper) } }
                                Text(label).aFont(TypeScale.cap, on ? .bold : .medium).foregroundStyle(on ? T.ink : T.ink2)
                            }
                            .frame(minWidth: Ctrl.l, minHeight: Ctrl.l)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(label)
                        .accessibilityAddTraits(on ? [.isSelected] : [])
                    }
                }
                AcctHint(text: "Colore le **disque de votre compte**, en haut à droite — et rien d'autre.",
                         more: "Sur un appareil partagé, il dit d'un coup d'œil à quel compte appartient cette fenêtre. L'accent s'arrête là : dans cette application une couleur porte toujours un sens — rouge ce qui tue si on l'oublie, ambre là où l'on se trompe, vert ce qui est confirmé — et une teinte répandue sur l'écran entrerait en concurrence avec eux.")
            }
        }
    }

    // MARK: Historique des sessions (opt-in, § 15.2)

    private var sessionsSync: some View {
        let n = model.sessions.filter { !($0["live"]?.truthy ?? false) }.count
        return VStack(alignment: .leading, spacing: 8) {
            AcctZoneTitle(text: "Historique des sessions")
            WorkCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Synchroniser entre vos appareils").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                        Spacer(minLength: 8)
                        Button { toggleSessions() } label: {
                            HStack(spacing: 6) {
                                Circle().fill(sessSync ? T.ok : T.ink3).frame(width: 8, height: 8)
                                Text(sessSync ? "Oui" : "Non").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                            }
                            .padding(.horizontal, 12)
                            .frame(minHeight: Ctrl.m)
                            .background(T.amb2, in: Capsule())
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Synchroniser l'historique des sessions entre vos appareils")
                        .accessibilityValue(sessSync ? "Oui" : "Non")
                    }
                    if sessSync {
                        AcctHint(text: "Vos **\(n)** session\(acctS(n)) archivée\(acctS(n)) suivent votre compte — **les sessions en cours ne partent jamais**.",
                                 more: "La **trace de vérification** (do-verify) reste sur l’appareil qui l’a produite : un compte rendu consulté ailleurs le dit explicitement, plutôt que de se lire « aucune vérification n’a été faite ».")
                    } else {
                        AcctHint(text: "Par défaut, un compte rendu de soin **ne quitte pas l’appareil**.",
                                 more: "Activez si vous voulez le retrouver sur votre tablette ou votre téléphone. Seules les sessions **terminées** sont concernées — les sessions en cours ne partent jamais, et la trace de vérification reste sur l’appareil qui l’a produite.")
                    }
                }
            }
        }
    }

    private func toggleSessions() {
        if sessSync {
            model.sync.setSessionSync(false)
            sessSync = false
            return
        }
        confirm = AcctConfirm(title: "Synchroniser l’historique ?",
                              message: "Vos comptes rendus de sessions terminées seront enregistrés sur le serveur de synchronisation et disponibles sur vos autres appareils. Les sessions en cours ne partent jamais, et la trace de vérification reste sur l’appareil qui l’a produite.",
                              yes: "Synchroniser") { r in
            guard case .yes = r else { return }
            model.sync.setSessionSync(true)
            sessSync = true
        }
    }

    // MARK: Vocabulaire du journal (§ 13.4)

    private var tagsEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            AcctZoneTitle(text: "Vocabulaire du journal (\(tags.count))")
            WorkCard(padding: 0) {
                VStack(spacing: 0) {
                    if tags.isEmpty {
                        Text("Aucune étiquette pour l’instant.").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2).padding(12)
                    }
                    ForEach(Array(tags.enumerated()), id: \.element.k) { i, t in
                        if i > 0 { Divider().overlay(T.line) }
                        AcctTagRow(tag: t,
                                   onChange: { nt in updateTag(nt) },
                                   onDelete: { removeTag(t.k) })
                    }
                }
            }
            if tags.count < PrefValues.tagMax {
                Button("＋ Nouvelle étiquette") {
                    tags.append(JournalTag(k: Guard.uid("t"), l: "Nouvelle étiquette", a: []))
                    saveTags()
                }
                .buttonStyle(.a(.secondary, Ctrl.m))
            }
            AcctHint(text: "Vos mots pour le journal — **aucun texte libre ne traverse le réseau**.",
                     more: "Pendant un soin, tapez et choisissez : l’étiquette voyage comme une **référence**, jamais comme du texte. Les abréviations la font remonter (« mru » trouve « Médecin régulateur »). Elle se résout sur **vos** appareils ; un collègue qui ne l’a pas voit un repère horodaté sans mot.")
        }
    }

    private func updateTag(_ t: JournalTag) {
        guard let i = tags.firstIndex(where: { $0.k == t.k }) else { return }
        tags[i] = t
        saveTags()
    }
    private func removeTag(_ k: String) {
        tags.removeAll { $0.k == k }
        saveTags()
    }
    /// Enregistré dans les préférences du compte (assainies par `sanitizeTags`) et poussé.
    private func saveTags() {
        model.sync.prefs.tags = tags
        model.sync.schedulePrefsPush()
    }
}

/// Une étiquette : libellé (40 au plus) · abréviations séparées par des virgules · ×.
private struct AcctTagRow: View {
    var tag: JournalTag
    var onChange: (JournalTag) -> Void
    var onDelete: () -> Void
    @State private var label = ""
    @State private var aliases = ""

    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 6) {
                TextField("Libellé", text: $label)
                    .modifier(AcctFieldStyle())
                    .accessibilityLabel("Libellé de l'étiquette")
                    .onChange(of: label) { _, v in
                        if v.count > 40 { label = String(v.prefix(40)); return }
                        commit()
                    }
                TextField("abréviations, séparées par des virgules", text: $aliases)
                    .modifier(AcctFieldStyle())
                    .accessibilityLabel("Alias de l'étiquette")
                    .onChange(of: aliases) { _, v in
                        if v.count > 200 { aliases = String(v.prefix(200)); return }
                        commit()
                    }
            }
            Button(action: onDelete) {
                Image(systemName: "xmark").aFont(TypeScale.body, .bold)
                    .frame(width: Ctrl.l, height: Ctrl.l).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(T.ink2)
            .accessibilityLabel("Supprimer l'étiquette " + tag.l)
        }
        .padding(12)
        .onAppear { label = tag.l; aliases = tag.a.joined(separator: ", ") }
    }

    private func commit() {
        let a = aliases.split(separator: ",").map { JS.trim(String($0)) }.filter { !$0.isEmpty }
        let t = JournalTag(k: tag.k, l: label, a: Array(a.prefix(PrefValues.tagAliasMax)))
        if t != tag { onChange(t) }
    }
}

// MARK: - État de l'instance (administrateur, `loadInstanceStats`)

struct AccountStatsBlock: View {
    var onPending: () -> Void
    @Environment(AppModel.self) private var model
    @State private var stats: InstanceStats?
    @State private var loading = true

    var body: some View {
        WorkCard {
            if loading {
                HStack(spacing: 8) { ProgressView(); Text("Chargement…").aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2) }
            } else if let s = stats {
                content(s)
            } else {
                EmptyView()
            }
        }
        .task {
            stats = try? await model.sync.api.instanceStats()
            loading = false
        }
    }

    @ViewBuilder
    private func content(_ s: InstanceStats) -> some View {
        let data = s.storageBytes, pdf = s.attachmentsBytes, tot = data + pdf
        let part: Double = tot > 0 ? max(2, min(100, JS.round(data / tot * 100))) : 100
        VStack(alignment: .leading, spacing: 6) {
            Text("État de l'instance").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
            group("Comptes")
            line("Comptes actifs", "\(s.users)")
            HStack {
                Text("En attente de validation").aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
                Spacer()
                Button("Examiner · \(s.pending)", action: onPending).buttonStyle(.a(.secondary, Ctrl.s))
            }
            if s.rejected > 0 {
                detail("\(s.rejected) demande\(acctS(s.rejected)) refusée\(acctS(s.rejected))")
            }
            group("Contenus")
            line("Bibliothèques", "\(s.libraries)")
            line("Fiches", "\(s.fiches)")
            detail("\(s.fichesPerso) personnelle\(acctS(s.fichesPerso)) · \(s.fichesShared) partagée\(acctS(s.fichesShared))")
            line("Protocoles", "\(s.protocols)")
            group("Partage & sessions")
            line("Partages de session", "\(s.sharesRows)")
            detail("dont \(s.sharesLive) en cours en ce moment")
            line("Sessions synchronisées", "\(s.sessions)")
            group("Stockage")
            line("Données", acctFmtBytes(data))
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(T.amb2)
                    Capsule().fill(T.ink2).frame(width: g.size.width * part / 100)
                }
            }
            .frame(height: 6)
            .accessibilityElement()
            .accessibilityLabel(acctFmtBytes(data) + " de données, " + acctFmtBytes(pdf) + " de documents")
            detail("+ " + acctFmtBytes(pdf) + " de documents PDF")
        }
    }

    private func group(_ t: String) -> some View {
        Text(t).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2).padding(.top, 6).accessibilityAddTraits(.isHeader)
    }
    private func line(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
            Spacer()
            Text(v).aFont(TypeScale.body, .bold, .mono).foregroundStyle(T.ink)
        }
        .accessibilityElement(children: .combine)
    }
    private func detail(_ t: String) -> some View {
        Text(t).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
    }
}

// MARK: - « Erreur de synchronisation »

struct SyncErrorView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let info = model.sync.lastError ?? SyncErrorInfo.unknownFallback
        let at = model.sync.lastErrorAt
        AcctWindow(title: "Erreur de synchronisation", maxWidth: 480, onClose: { dismiss() }) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: Self.symbol(info.icon)).aFont(TypeScale.stepL, .semibold).foregroundStyle(T.warn)
                    .accessibilityHidden(true)
                Text(info.title).aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
            }
            Text(info.detail).aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
                .fixedSize(horizontal: false, vertical: true)
            if at > 0 {
                Text("Dernier échec : " + hhmm(at) + either(model.sync.retryPending, " · nouvelle tentative automatique en cours", ""))
                    .aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink2)
            }
            Button("Réessayer maintenant") {
                dismiss()
                Task { @MainActor in await model.sync.full() }
            }
            .buttonStyle(.a(.primary, Ctrl.m))
        }
    }

    /// `SYNC_ERR_ICONS` : un dessin par nature d'erreur.
    static func symbol(_ i: SyncErrorIcon) -> String {
        switch i {
        case .lock: return "lock"
        case .forbidden: return "nosign"
        case .image: return "photo"
        case .warning: return "exclamationmark.triangle"
        case .server: return "server.rack"
        case .offline: return "wifi.slash"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Espaces de compte (spec D § 6)

extension AppModel {
    /// `anonFicheCount()` : aides vivantes de l'espace « hors compte », vu depuis l'espace d'un compte.
    func acctAnonFicheCount() -> Int {
        guard !store.currentSpace.isEmpty, store.spaces.contains("") else { return 0 }
        return store.open("").fiches.all().filter { $0["deletedAt"] == nil || $0["deletedAt"]!.isNull }.count
    }

    /// `switchToAnonSpace()` : seulement déconnecté.
    func acctSwitchToAnon() {
        guard !auth.signedIn else { return }
        engine.persistAll()
        switchSpace(to: "")
    }

    /// « Les emporter dans ce compte » (`moveLocalDataTo(uid)`) : DÉPLACER, jamais copier — un id
    /// de fiche n'appartient qu'à un compte. Un échec est DIT (la PWA le dit après rechargement).
    func acctTakeAnonymousData(to uid: String) {
        engine.persistAll()
        do {
            try store.moveData(from: "", to: uid)
        } catch {
            toast("⚠ Le transfert des fiches locales vers le compte a échoué : elles restent « hors compte », accessibles via le lien de l'écran de connexion.", seconds: 12)
        }
    }

    /// Retire les sessions vives du registre sans les archiver (avant un effacement de l'espace).
    func acctDropLiveSessions() {
        for R in Array(engine.live.values) {
            if let sid = R.sessionId { engine.drop(sessionId: sid) }
        }
        current = nil
    }

    /// `returnLocalDataToAnon()` : un compte NON validé jamais synchronisé rend ses fiches « hors
    /// compte », puis se déconnecte. Rend false (et le dit) si rien n'a pu être déplacé.
    func acctReturnToAnon() async -> Bool {
        engine.persistAll()
        let from = store.currentSpace
        do {
            try store.moveData(from: from, to: "")
        } catch {
            toast("⚠ Échec du retour hors compte : rien n'a été déplacé. Réessayez, ou exportez vos fiches par sécurité (fenêtre Compte → « Exporter mes données »).", seconds: 9)
            return false
        }
        await auth.signOut()
        sync.resetAuthState()
        switchSpace(to: "")
        return true
    }

    /// Suppression du compte (étape 2, après vérification du code) : `goAnon` est évalué AVANT
    /// (`resetAuthState` efface le statut). Effacer = effacement TOTAL de l'appareil (`wipeLocal`).
    func acctDeleteAccount(wipe: Bool) async throws {
        let goAnon = !wipe && canReturnToAnon(status: profile.accountStatus, everSynced: sync.accountEverSynced(), liveCount: library.liveFicheCount)
        try await sync.api.deleteAccount()
        await auth.signOut()
        sync.resetAuthState()
        if wipe {
            acctDropLiveSessions()
            store.wipeAll()
            onboarded = false
            switchSpace(to: "")
        } else if goAnon {
            engine.persistAll()
            if (try? store.moveData(from: store.currentSpace, to: "")) != nil { switchSpace(to: "") }
        }
        toast("Votre compte a été supprimé.")
    }
}
