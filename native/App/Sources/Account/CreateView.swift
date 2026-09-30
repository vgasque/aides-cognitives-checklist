import SwiftUI
import AidesCore

// LA FENÊTRE « CRÉER » — port de `openCreateDlg` / `renderCreateDlg` (écrans « methods », « ia »,
// « import »), de `newFiche()` / `newProtocol()` et de `blankFiche()` / `blankProtocol()`.
// Seule porte de création (en-tête « Créer », état vide, bienvenue). Le type se choisit par DEUX
// CARTES (le segmenté historique `#createSeg` est masqué dans la PWA : il n'est pas porté).
//
// ÉCART NATIF ASSUMÉ : la PWA garde une aide neuve en BROUILLON D'ÉDITEUR jusqu'à son premier
// titre ; ici l'entité vierge est enregistrée tout de suite (`model.save`) et l'éditeur s'ouvre
// dessus (`.editFiche(id)`), comme le prévoit la coque native.

struct CreateView: View {
    /// Bibliothèque affichée à l'accueil (`homeScope()`) : nil ou « * » = Perso.
    var scope: String?

    init(scope: String? = nil) { self.scope = scope }

    /// Les écrans « ia » et « import » sont des pages POUSSÉES : le retour est celui du système
    /// (« ‹ Autres méthodes » de la PWA), jamais un bouton texte.
    private enum Screen: Hashable { case ia, importer }

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var path: [Screen] = []
    @State private var workshop: ImportRequest?
    @State private var confirm: AcctConfirm?

    var body: some View {
        if let w = workshop {
            ImportWorkshopView(request: w) { last in finishImport(last) }
        } else {
            NavigationStack(path: $path) {
                AcctWindow(title: "Créer", maxWidth: 480, embedded: true, onClose: { dismiss() }) { methods }
                    .navigationDestination(for: Screen.self) { s in destination(s) }
            }
            .acctConfirm($confirm)
            .presentationSizing(.form)
            .acctSheetSize(480)
        }
    }

    @ViewBuilder
    private func destination(_ s: Screen) -> some View {
        switch s {
        case .ia:
            PromptIAView(embedded: true) { urls in workshop = ImportRequest(urls: urls, openLast: true) }
        case .importer:
            AcctWindow(title: "Importer un fichier", maxWidth: 480, embedded: true) { importer }
        }
    }

    // MARK: Écran « methods »

    /// Le type proposé d'office suit le filtre de section de l'accueil (`ac-section`) — sans le modifier.
    private var kind: String { model.library.space.prefs["ac-section"]?.string == "protocols" ? "p" : "f" }
    private var targetScope: String? { (scope == nil || scope == "*") ? nil : scope }

    @ViewBuilder
    private var methods: some View {
        Text("Choisissez le type. Vous pourrez tout modifier ensuite.")
            .aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
        VStack(spacing: 8) {
            if let slot = parkedDraft {
                Button { restoreDraft(slot) } label: {
                    CreateCard(badge: nil, icon: "arrow.uturn.backward", title: "Reprendre le brouillon en cours", sub: draftSub(slot))
                }
                .buttonStyle(.plain)
            }
            Button { newFiche() } label: {
                CreateCard(badge: "✓", icon: nil, title: "Aide de crise",
                           sub: "Un parcours à cocher en situation : blocs d'étapes, décisions, minuteurs et compteurs.")
            }
            .buttonStyle(.plain)
            Button { newProtocol() } label: {
                CreateCard(badge: "≡", icon: nil, title: "Protocole",
                           sub: "Un texte de référence à lire, sans chrono : posologies, procédures, consignes de service.")
            }
            .buttonStyle(.plain)
        }
        Divider().overlay(T.line)
        VStack(spacing: 0) {
            NavigationLink(value: Screen.ia) {
                AcctMenuRow(icon: "sparkles", title: "Rédiger avec l'IA à partir d'un document",
                            sub: "PDF ou texte → brouillon à relire avant usage.", chevron: true)
            }
            .buttonStyle(.plain)
            NavigationLink(value: Screen.importer) {
                AcctMenuRow(icon: "square.and.arrow.down", title: "Importer un fichier (.json ou .zip)", chevron: true)
            }
            .buttonStyle(.plain)
        }
        BoldText(text: "Tout import arrive en état **○ Brouillon** — jamais « Validée » d'office.", size: TypeScale.meta, color: T.ink2)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Écran « import »

    @ViewBuilder
    private var importer: some View {
        ImportDropZone(title: "Importer un fichier", large: true) { urls in
            workshop = ImportRequest(urls: urls, openLast: false)
        }
        BoldText(text: "Un export de l'app (.json, ou .zip avec les documents PDF) ou une génération IA (.json). Tout le contenu importé arrive en **○ Brouillon** — jamais « Validée » d'office.",
                 size: TypeScale.meta, color: T.ink2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func finishImport(_ last: String?) {
        workshop = nil
        dismiss()
        if let last { openLater(.fiche(last), fiche: last) }
    }

    // MARK: Brouillon parqué (A-model §15)

    /// Brouillon de CRÉATION auto-enregistré pour le type courant (`slot.isNew`).
    private var parkedDraft: JSON? {
        guard let s = model.library.draftPark(kind), s["isNew"]?.truthy == true, s["draft"]?.object != nil else { return nil }
        return s
    }
    private func draftSub(_ s: JSON) -> String {
        let t = JS.trim(s["draft"]?["title"]?.string ?? "")
        let ts = s["ts"]?.number ?? 0
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "HH:mm:ss"
        return (t.isEmpty ? "Sans titre" : t) + " — auto-enregistré à " + f.string(from: Date(timeIntervalSince1970: ts / 1000))
    }
    /// Le brouillon repasse par `migrate` (Sanitize), garde son id, rejoint la bibliothèque et
    /// l'éditeur s'ouvre dessus ; l'emplacement du parc est vidé.
    private func restoreDraft(_ s: JSON) {
        guard let raw = s["draft"] else { return }
        let forId = s["forId"]?.string ?? ""
        if kind == "p" {
            var p = Sanitize.reference(raw)
            if Guard.isSafeId(forId) { p.id = forId }
            guard model.save(p) else { return }
            model.library.setDraftPark("p", nil)
            dismiss()
            openLater(.editReference(p.id), fiche: nil)
        } else {
            var f = Sanitize.fiche(raw)
            if Guard.isSafeId(forId) { f.id = forId }
            guard model.save(f) else { return }
            model.library.setDraftPark("f", nil)
            dismiss()
            openLater(.editFiche(f.id), fiche: nil)
        }
    }

    // MARK: Création (`newFiche` / `newProtocol`)

    private func newFiche() {
        let lib = targetScope
        if let lib, !model.library.canEdit(scope: lib) {
            dismiss(); model.toast("Lecture seule : vous ne pouvez pas créer de fiche dans cette bibliothèque."); return
        }
        guard let lib else { createFiche(in: nil); return }
        let name = model.library.libraryName(lib)
        confirm = AcctConfirm(title: "Publier dans la bibliothèque partagée",
                              message: "Cette fiche va être créée dans « " + (name.isEmpty ? "la bibliothèque partagée" : name) + " » : elle sera visible par tous les membres.",
                              yes: "Créer la fiche") { r in
            if case .yes = r { createFiche(in: lib) }
        }
    }
    private func newProtocol() {
        let lib = targetScope
        if let lib, !model.library.canEdit(scope: lib) {
            dismiss(); model.toast("Lecture seule : vous ne pouvez pas créer de protocole dans cette bibliothèque."); return
        }
        guard let lib else { createProtocol(in: nil); return }
        let name = model.library.libraryName(lib)
        confirm = AcctConfirm(title: "Publier dans la bibliothèque partagée",
                              message: "Ce protocole va être créé dans « " + (name.isEmpty ? "la bibliothèque partagée" : name) + " » : il sera visible par tous les membres.",
                              yes: "Créer le protocole") { r in
            if case .yes = r { createProtocol(in: lib) }
        }
    }
    private func createFiche(in lib: String?) {
        var f = CreateBlank.fiche()
        f.library = lib
        guard model.save(f) else { return }
        dismiss()
        openLater(.editFiche(f.id), fiche: nil)
    }
    private func createProtocol(in lib: String?) {
        var p = CreateBlank.reference()
        p.library = lib
        guard model.save(p) else { return }
        dismiss()
        openLater(.editReference(p.id), fiche: nil)
    }

    /// Navigue APRÈS la fermeture de la feuille (pousser pendant l'animation de fermeture peut
    /// se perdre). `fiche` : ouvrir une aide en lecture passe par `openFiche` (runtime, fréquence).
    private func openLater(_ r: Route, fiche: String?) {
        let m = model
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            if let fiche { m.openFiche(fiche) } else { m.path.append(r) }
        }
    }
}

/// `blankFiche()` / `blankProtocol()` — le JSON exact de la PWA, repassé par `migrate` (Sanitize).
enum CreateBlank {
    /// Un bloc « Prise en charge » avec une étape vide ; le contexte local porte « à compléter »
    /// À DESSEIN (il déclenche la pastille « À compléter », `completionSpots`).
    /// (Dictionnaires TYPÉS, valeurs en cas explicites : un littéral hétérogène de vingt clés
    /// épuiserait le vérificateur de types.)
    static func fiche() -> Fiche {
        let bid = Guard.uid("b")
        var item: [String: JSON] = [:]
        item["id"] = .string(Guard.uid("i"))
        item["role"] = .string("do")
        item["do"] = .string("")
        item["expect"] = .string("")
        item["level"] = .number(1)
        item["memory"] = .bool(false)
        item["dual"] = .bool(false)
        item["note"] = .string("")
        var block: [String: JSON] = [:]
        block["id"] = .string(bid)
        block["kind"] = .string("do")
        block["title"] = .string("Prise en charge")
        block["items"] = .array([.object(item)])
        block["image"] = .null
        block["next"] = .null
        let empty: JSON = .array([.string("")])
        var o: [String: JSON] = [:]
        o["id"] = .string(Guard.uid())
        for k in ["title", "code", "category", "validatedAt"] { o[k] = .string("") }
        o["local"] = .string("Tél renfort : à compléter\nTél régulation : à compléter")
        for k in ["excursions", "images", "docs", "timers", "counters"] { o[k] = .array([]) }
        for k in ["confirmation", "verify", "posology", "notForget", "differentials", "sources"] { o[k] = empty }
        o["blocks"] = .array([.object(block)])
        o["start"] = .string(bid)
        o["order"] = .number(JS.now())
        return Sanitize.fiche(.object(o))
    }
    static func reference() -> Reference {
        let now = JS.now()
        var o: [String: JSON] = [:]
        o["id"] = .string(Guard.uid("p"))
        for k in ["title", "code", "category", "validatedAt", "body", "status", "updatedBy"] { o[k] = .string("") }
        for k in ["images", "docs", "links", "sources"] { o[k] = .array([]) }
        o["order"] = .number(now)
        o["updatedAt"] = .number(now)
        for k in ["deletedAt", "ownerId", "library"] { o[k] = .null }
        return Sanitize.reference(.object(o))
    }
}

/// Carte de type (« Aide de crise », « Protocole ») : pastille, titre gras, description, chevron.
private struct CreateCard: View {
    var badge: String?
    var icon: String?
    var title: String
    var sub: String
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Group {
                if let badge {
                    Text(badge).aFont(TypeScale.stepL, .bold).foregroundStyle(T.act)
                } else if let icon {
                    Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(T.act)
                }
            }
            .frame(width: Ctrl.m, height: Ctrl.m)
            .background(T.primarySoft, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                Text(sub).aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(T.ink3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: Ctrl.xl, alignment: .leading)
        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.line))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}
