import SwiftUI
import AidesCore

// LE FORMULAIRE D'UNE AIDE, DANS L'ORDRE DE LECTURE (`renderEditor`, v4.4.1 : on rédige dans
// l'ordre où l'équipe lira). Règle « présent dans la porte ＋ ⇔ masqué quand vide » ; exceptions
// toujours montrées : « Ne pas oublier », « Condition d’entrée », « Prise en charge »,
// « Contexte local », « Voir aussi », la note.

struct FicheForm: View {
    @Bindable var ed: FicheDraft
    var wide: Bool

    var body: some View {
        let f = ed.d
        VStack(alignment: .leading, spacing: 16) {
            if let t = ed.restoredAt {
                EdRestoredNotice(ts: t, canDrop: ed.existsInLibrary) { ed.dropRestored() }
            }
            FicheIdentity(ed: ed)
            ForgetEditor(ed: ed)
            EntryConditionCard(ed: ed)
            CareCard(ed: ed, wide: wide)
            if !f.timers.isEmpty || !f.counters.isEmpty { TimersCountersCard(ed: ed) }
            if !f.excursions.isEmpty { ComplicationsCard(ed: ed) }
            if f.blocks.contains(where: { $0.kind == .review }) { ReviewBlocksCard(ed: ed) }
            LocalContextCard(ed: ed)
            if !EdKit.listItems(f, .posology).isEmpty {
                EdCard(title: "Repères posologiques",
                       hint: "classés automatiquement en lecture selon le bloc en cours (aucun n’est jamais masqué) · bouton △ = carte ambre (dose à vérifier) · le rouge reste aux memory items · **gras** possible · le détail sous la ligne reste derrière un second geste") {
                    PoolListEditor(ed: ed, key: .posology, legend: "Repères posologiques", crit: true, note: true)
                }
            }
            if !EdKit.listItems(f, .verify).isEmpty {
                EdCard(title: "À vérifier", hint: "surveillances et pièges — affichés en ③") {
                    PoolListEditor(ed: ed, key: .verify, legend: "À vérifier", crit: false, note: false)
                }
            }
            if !f.images.isEmpty { GalleryCard(ed: ed) }
            if !f.docs.isEmpty { FicheDocsCard(ed: ed) }
            if !f.sources.isEmpty {
                EdCard(title: "Références", hint: "sources de la fiche") {
                    SourcesEditor(ed: ed)
                }
            }
            FicheLinksCard(ed: ed)
            EdNoteBlock(ficheId: f.id)
            if !wide { FicheReviewPanel(ed: ed) }
            // « Supprimer cette fiche » vit dans le menu « Plus » de la barre (iOS 26).
            Spacer(minLength: 72)
        }
    }
}

// MARK: - Notice du brouillon restauré (§5.1)

struct EdRestoredNotice: View {
    var ts: Double
    var canDrop: Bool
    var onDrop: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Brouillon auto-enregistré (" + Fmt.hms(ts) + ") restauré — vos modifications non publiées ont été reprises.")
                .aFont(TypeScale.body, .semibold).foregroundStyle(T.ink)
                .fixedSize(horizontal: false, vertical: true)
            if canDrop {
                EdLinkButton(text: "Repartir de la version enregistrée", action: onDrop)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(T.primarySoft, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Identité (partagée par les deux éditeurs : `editorMetaFieldsHtml`)

/// Ce que l'identité lit et écrit — construit par chaque éditeur (aide ou référence).
struct EdIdentityModel {
    var fiche: Bool
    var id: String
    var title: String
    var discriminant: String
    var code: String
    var validatedAt: String
    var category: String
    var library: String?
    var status: Status
    var resync: Int
    var request: EdRequest?
    var setTitle: (String) -> Void
    var setDiscriminant: (String) -> Void
    var setCode: (String) -> Void
    var setValidation: (String) -> Void
    var setStatus: (Status) -> Void
    var setLibrary: (String?) -> Void
    var openCategory: () -> Void
}

struct FicheIdentity: View {
    @Bindable var ed: FicheDraft
    var body: some View {
        EdIdentityFold(m: EdIdentityModel(
            fiche: true, id: ed.d.id, title: ed.d.title, discriminant: ed.d.discriminant, code: ed.d.code,
            validatedAt: ed.d.validatedAt, category: ed.d.category, library: ed.d.library, status: ed.d.status,
            resync: ed.syncTick, request: ed.focusRequest,
            setTitle: { v in ed.typing { $0.title = v } },
            setDiscriminant: { v in ed.typing { $0.discriminant = v } },
            setCode: { v in ed.typing { $0.code = v } },
            setValidation: { v in ed.structural { $0.validatedAt = v } },
            setStatus: { s in ed.structural { $0.status = s } },
            setLibrary: { lib in
                ed.structural { f in
                    f.library = lib
                    if !f.category.isEmpty && !ed.model.categories.contains(where: { $0.id == f.category && $0.library == lib }) { f.category = "" }
                }
            },
            openCategory: { ed.sheet = .category }),
            open: $ed.identOpen)
    }
}

struct EdIdentityFold: View {
    var m: EdIdentityModel
    @Binding var open: Bool
    @Environment(AppModel.self) private var model
    @Environment(\.widthClass) private var wc
    @State private var valText = ""
    @State private var valBad = false
    @State private var valLoaded = false
    @FocusState private var valFocus: Bool
    // Changement de bibliothèque : deux confirmations possibles (sortie, puis entrée).
    @State private var pendingLib: String?? = nil
    @State private var askOut = false
    @State private var askInto = false

    var body: some View {
        WorkCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                summary
                if open { fields }
            }
        }
        .id(m.fiche ? "f-ident" : "p-title")
        .alert("Retirer de la bibliothèque partagée", isPresented: $askOut) {
            Button(m.fiche ? "Déplacer la fiche" : "Déplacer le protocole", role: .destructive) { afterOut() }
            Button("Annuler", role: .cancel) { pendingLib = nil }
        } message: { Text(outMessage) }
        .alert("Publier dans la bibliothèque partagée", isPresented: $askInto) {
            Button(m.fiche ? "Publier la fiche" : "Publier le protocole") { applyLib() }
            Button("Annuler", role: .cancel) { pendingLib = nil }
        } message: { Text(intoMessage) }
    }

    // Résumé du pli : titre + code, ou « Nouvelle fiche » ; mot déclencheur « Identité ».
    private var summary: some View {
        Button { open.toggle() } label: {
            HStack(spacing: 8) {
                if JS.trim(m.title).isEmpty {
                    Text("Nouvelle fiche").aFont(TypeScale.item, .semibold).foregroundStyle(T.ink3)
                } else {
                    Text(m.title).aFont(TypeScale.item, .bold).foregroundStyle(T.ink).lineLimit(1)
                }
                if !JS.trim(m.code).isEmpty {
                    Text(m.code).aFont(TypeScale.meta, .bold, .mono).foregroundStyle(T.ink2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(T.amb2, in: Capsule())
                }
                Spacer(minLength: 8)
                Text("Identité").aFont(TypeScale.meta, .bold).foregroundStyle(T.act)
                Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundStyle(T.act)
            }
            .frame(minHeight: Ctrl.m).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Identité")
        .accessibilityValue(open ? "déplié" : "replié")
    }

    @ViewBuilder private var fields: some View {
        labeled(m.fiche ? "Titre de la situation" : "Titre du protocole", "") {
            EdField(value: m.title, placeholder: m.fiche ? "ex. Intoxication aux anesthésiques locaux" : "ex. Douleur thoracique — protocole de service",
                    label: m.fiche ? "Titre de la situation" : "Titre du protocole", focusKey: "title", request: m.request,
                    maxLength: 200, size: TypeScale.item, weight: .semibold, resync: m.resync, onChange: m.setTitle)
        }
        labeled("Discriminant", "ce qui distingue cette fiche d’une voisine — deux ou trois mots (60 caractères au plus), jamais tronqué à l’affichage") {
            EdField(value: m.discriminant, placeholder: "ex. adulte · pédiatrique · femme enceinte", label: "Discriminant",
                    maxLength: 60, resync: m.resync, onChange: m.setDiscriminant)
        }
        labeled("Catégorie", "") { categoryPicker }
        if model.auth.signedIn {
            labeled("Bibliothèque", m.fiche ? "où ranger cette fiche" : "où ranger ce protocole") { libraryPicker }
        }
        // Une seule instance de chaque champ (le focus de la date ne doit pas avoir deux cibles).
        if wc == .phone {
            codeField
            validationField
        } else {
            HStack(alignment: .top, spacing: 12) { codeField; validationField }
        }
        labeled("État", "") {
            VStack(alignment: .leading, spacing: 6) {
                EdSeg(options: [(Status.draft, "○ Brouillon"), (Status.review, "△ À relire"), (Status.validated, m.fiche ? "✓ Validée" : "✓ Validé")],
                      selection: m.status, accessibility: "État", onSelect: m.setStatus)
                Text(statusHint).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var codeField: some View {
        labeled("Code", "référence courte facultative") {
            EdField(value: m.code, placeholder: m.fiche ? "ex. URG-ANA-01" : "ex. PRO-ISR-01", label: "Code",
                    mono: true, maxLength: 40, resync: m.resync, onChange: m.setCode)
        }
    }

    /// Date de validation : « MM/AAAA » à l'écran, « AAAA-MM » au modèle (`parseValidation`).
    /// Une saisie illisible garde le champ, borde en ambre, et ne touche PAS au modèle.
    private var validationField: some View {
        labeled("Date de validation", "mois/année") {
            TextField("", text: $valText, prompt: Text("MM/AAAA").foregroundColor(T.ink3))
                .focused($valFocus)
                .textFieldStyle(.plain)
                .aFont(TypeScale.item, .regular, .mono)
                .padding(.horizontal, 12)
                .frame(minHeight: Ctrl.m)
                .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous)
                    .strokeBorder(valBad ? T.warnLine : (valFocus ? T.act : Color.clear), lineWidth: 1.5))
                #if os(iOS)
                .keyboardType(.numbersAndPunctuation)
                #endif
                .edLock()
                .accessibilityLabel("Date de validation")
                .accessibilityHint(valBad ? "Date illisible — mois/année" : "mois/année")
                .onAppear { if !valLoaded { valText = Validation.display(m.validatedAt); valLoaded = true } }
                .onChange(of: m.validatedAt) { _, v in if !valFocus { valText = Validation.display(v); valBad = false } }
                .onChange(of: valFocus) { _, f in if !f { commitValidation() } }
                .onSubmit { commitValidation() }
        }
    }
    private func commitValidation() {
        let raw = JS.trim(valText)
        if raw.isEmpty { valBad = false; if !m.validatedAt.isEmpty { m.setValidation("") }; return }
        let p = Validation.parse(.string(raw))
        if p.isEmpty { valBad = true; return }
        valBad = false
        valText = Validation.display(p)
        if p != m.validatedAt { m.setValidation(p) }
    }

    private var statusHint: String {
        let shared = m.library != nil
        switch m.status {
        case .draft:
            return "Visible par vous seulement" + (shared ? (m.fiche ? " (masquée aux lecteurs de la bibliothèque)" : " (masqué aux lecteurs de la bibliothèque)") : "")
        case .review:
            return "Visible" + either(shared, " par l’équipe", "") + either(m.fiche, ", signalée à relire", ", signalé à relire")
        case .validated:
            return m.fiche ? "Publiée — utilisable en situation" : "Publié — utilisable en situation"
        }
    }

    // Catégorie : pastille + nom, ou « Sans catégorie » ; « Autre… » ouvre le même choix.
    private var categoryPicker: some View {
        let cat = model.categories.first { $0.id == m.category && $0.library == m.library }
        return HStack(spacing: 8) {
            Button(action: m.openCategory) {
                HStack(spacing: 6) {
                    if let cat { CategoryDot(color: cat.color, size: 10) }
                    Text(cat?.name ?? "Sans catégorie").aFont(TypeScale.body, .bold).foregroundStyle(cat == nil ? T.ink2 : T.ink)
                }
                .padding(.horizontal, 12).frame(minHeight: Ctrl.m)
                .background(T.amb2, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .edLock()
            .help(cat == nil ? "Choisir une catégorie" : "Changer de catégorie")
            .accessibilityLabel("Catégorie : " + (cat?.name ?? "Sans catégorie"))
            Button("Autre…", action: m.openCategory).buttonStyle(.a(.quiet, Ctrl.m)).edLock()
        }
    }

    // Bibliothèque : Perso + celles où je rédige ; changer se CONFIRME (conséquences pour les autres).
    private var libraryPicker: some View {
        let mine = model.profile.libraries.filter { $0.role.canEdit }
        let binding = Binding<String>(
            get: { m.library ?? "" },
            set: { v in requestLib(v.isEmpty ? nil : v) })
        return Picker("Bibliothèque", selection: binding) {
            Text("Perso (privé)").tag("")
            ForEach(mine) { l in Text(l.name + " (partagée)").tag(l.id) }
            if let cur = m.library, !mine.contains(where: { $0.id == cur }) {
                Text(model.library.libraryName(cur).isEmpty ? "Bibliothèque" : model.library.libraryName(cur)).tag(cur)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .edLock()
    }
    private func libName(_ id: String?) -> String { model.library.libraryName(id) }
    private func requestLib(_ to: String?) {
        guard to != m.library else { return }
        let existed = m.fiche ? model.fiches.contains { $0.id == m.id } : model.references.contains { $0.id == m.id }
        pendingLib = .some(to)
        if !existed { applyLib(); return }   // `confirmDraftLibChange` : rien à confirmer pour un brouillon neuf
        if m.library != nil { askOut = true } else if to != nil { askInto = true } else { applyLib() }
    }
    private func afterOut() {
        if case .some(let to) = pendingLib, to != nil { askInto = true } else { applyLib() }
    }
    private func applyLib() {
        guard case .some(let to) = pendingLib else { return }
        pendingLib = nil
        m.setLibrary(to)
    }
    private var outMessage: String {
        let n = libName(m.library).isEmpty ? "partagée" : libName(m.library)
        return m.fiche
            ? "Cette fiche va quitter la bibliothèque partagée « \(n) » : les autres membres n'y auront plus accès, et les notes personnelles qu'ils y avaient attachées ne leur seront plus visibles. Prévenez-les avant si besoin."
            : "Ce protocole va quitter la bibliothèque partagée « \(n) » : les autres membres n'y auront plus accès. Prévenez-les avant si besoin."
    }
    private var intoMessage: String {
        var to: String? = nil
        if case .some(let t) = pendingLib { to = t }
        let n = libName(to).isEmpty ? "la bibliothèque partagée" : libName(to)
        let dr = m.status == .draft ? " pouvant éditer (brouillon masqué aux lecteurs)" : ""
        return either(m.fiche, "Cette fiche va être publiée dans « \(n) » : elle sera visible par tous les membres", "Ce protocole va être publié dans « \(n) » : il sera visible par tous les membres") + dr + "."
    }

    @ViewBuilder private func labeled<C: View>(_ label: String, _ hint: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(label).aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                if !hint.isEmpty { Text(hint).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true) }
            }
            c()
        }
    }
}

// MARK: - « Ne pas oublier » (`forgetEditorHtml`)

/// Une rangée du chapeau (`forgetPool`) : l'item, et le bloc qui le porte s'il est une étape ★.
struct ForgetRow: Identifiable {
    var item: Item
    var source: String?
    var blockId: String?
    var id: String { item.id }
}

struct ForgetEditor: View {
    @Bindable var ed: FicheDraft

    var body: some View {
        let rows: [ForgetRow] = Pool.forget(ed.d).map { ForgetRow(item: $0.item, source: $0.source, blockId: $0.blockId) }
        let n = rows.count, reste = max(0, 4 - n)
        EdCard(title: "Ne pas oublier", hint: "4 rappels maximum — ils s’affichent en permanence, en tête de fiche", flash: ed.flashKey == "nf") {
            Text("\(n)/4").aFont(TypeScale.meta, .bold, .mono).foregroundStyle(n > 4 ? T.warn : T.ink2)
                .accessibilityLabel("\(n) rappels sur 4")
        } content: {
            VStack(alignment: .leading, spacing: 6) {
                if rows.isEmpty {
                    EdField(value: "", placeholder: "…", label: "Ne pas oublier — ligne 1", resync: ed.syncTick) { v in
                        let it = Steps.makeItem(id: Guard.uid("i"), role: .do, raw: v, memory: true)
                        ed.structural { $0.items.append(it) }
                        ed.requestFocus("fg:" + it.id)
                    }
                }
                ForEach(Array(rows.enumerated()), id: \.element.id) { i, r in
                    drop(i, total: rows.count)
                    row(i, r.item, blockId: r.blockId, source: r.source ?? "", total: rows.count)
                }
                drop(rows.count, total: rows.count)
                EdLinkButton(text: "＋ Rappel" + (reste > 0 ? " (\(reste) restant" + either(reste > 1, "s", "") + ")" : "")) {
                    let it = Steps.makeItem(id: Guard.uid("i"), role: .do, raw: "", memory: true)
                    ed.structural { $0.items.append(it) }
                    ed.requestFocus("fg:" + it.id)
                }
                EdGuardLine(text: EdKit.nfGuardTxt(EdKit.forgetAll(ed.d)))
            }
        }
        .id("nf")
    }

    @ViewBuilder private func row(_ i: Int, _ it: Item, blockId: String?, source: String, total: Int) -> some View {
        let owned = blockId != nil
        HStack(spacing: 6) {
            if total >= 2 {
                EdGrabHandle(active: ed.grab == .list(.notForget, i), label: "Déplacer le rappel \(i + 1)") { toggleGrab(i) }
            }
            if owned { Text("★").aFont(TypeScale.item, .bold).foregroundStyle(T.ink2).accessibilityHidden(true) }
            EdField(value: Steps.text(it.legacyString), placeholder: "…",
                    label: "Ne pas oublier — ligne \(i + 1)" + either(owned, " (posée sur une étape)", ""),
                    focusKey: "fg:" + it.id, request: ed.focusRequest, disabled: owned, resync: ed.syncTick) { v in
                let cr = Steps.challengeResponse(Steps.text(v))
                ed.updateItem(it.id, typing: true) { x in x.do = cr.c; if let r = cr.r { x.expect = r } }
            }
            if let bid = blockId {
                EdIconButton(system: "arrow.right", label: "Aller au bloc « \(source) » où cette ligne se modifie") { ed.goFlash("b:" + bid) }
                    .help("Se modifie dans « \(source) »")
            } else {
                EdIconButton(system: "xmark", label: "Supprimer la ligne") {
                    ed.structural { $0.items.removeAll { $0.id == it.id } }
                }
            }
        }
    }
    @ViewBuilder private func drop(_ to: Int, total: Int) -> some View {
        if case .list(.notForget, let from)? = ed.grab {
            if to != from && to != from + 1 {
                EdDropTarget(label: to == 0 ? "Poser en tête" : (to >= total ? "Poser en fin" : "Poser ici")) {
                    ed.grab = nil
                    ed.structural { EdListOps.move(&$0, .notForget, from: from, to: to) }
                }
            }
        }
    }
    private func toggleGrab(_ i: Int) {
        ed.grab = ed.grab == .list(.notForget, i) ? nil : .list(.notForget, i)
    }
}

// MARK: - Opérations des listes (prendre / poser, libellés)

enum EdListOps {
    static func poolSlice(_ f: Fiche, _ k: EdListKind) -> [Item]? {
        if k == .notForget { return Pool.forget(f).map(\.item) }
        if let pk = k.poolKey { return EdKit.listItems(f, pk) }
        return nil
    }
    /// Libellé de la rangée tenue (bannière).
    static func label(_ f: Fiche, _ k: EdListKind, _ i: Int) -> String {
        if let s = poolSlice(f, k) { return i < s.count ? JS.trim(Steps.text(s[i].legacyString)) : "" }
        switch k {
        case .sources: return i < f.sources.count ? JS.trim(f.sources[i]) : ""
        case .timers: return i < f.timers.count ? JS.trim(f.timers[i].label) : ""
        case .counters: return i < f.counters.count ? JS.trim(f.counters[i].label) : ""
        case .excursions: return i < f.excursions.count ? JS.trim(f.excursions[i].label) : ""
        default: return ""
        }
    }
    /// Déplace la rangée `from` devant la rangée `to` (`to == n` : en fin). Les listes du pool se
    /// réordonnent DANS LE POOL, identités conservées (écart assumé : la PWA réécrivait les chaînes
    /// par position, ce qui détachait le détail d'un repère posologique de sa ligne).
    static func move(_ f: inout Fiche, _ k: EdListKind, from: Int, to: Int) {
        if let slice = poolSlice(f, k) {
            guard from < slice.count else { return }
            let src = slice[from]
            guard let pf = f.items.firstIndex(where: { $0.id == src.id }) else { return }
            var cible = to >= slice.count ? f.items.count : (f.items.firstIndex(where: { $0.id == slice[to].id }) ?? f.items.count)
            f.items.remove(at: pf)
            if pf < cible { cible -= 1 }
            f.items.insert(src, at: max(0, min(cible, f.items.count)))
            return
        }
        switch k {
        case .sources: arrMove(&f.sources, from, to)
        case .timers: arrMove(&f.timers, from, to)
        case .counters: arrMove(&f.counters, from, to)
        case .excursions: arrMove(&f.excursions, from, to)
        default: break
        }
    }
    static func arrMove<E>(_ a: inout [E], _ from: Int, _ to: Int) {
        guard from >= 0, from < a.count else { return }
        let o = a.remove(at: from)
        var t = to
        if from < t { t -= 1 }
        a.insert(o, at: max(0, min(t, a.count)))
    }
}

/// Destinations « Poser » d'une liste ordinaire (même liste seulement).
struct EdListDrop: View {
    @Bindable var ed: FicheDraft
    var kind: EdListKind
    var to: Int
    var total: Int
    var body: some View {
        if case .list(let k, let from)? = ed.grab, k == kind, to != from, to != from + 1 {
            EdDropTarget(label: to == 0 ? "Poser en tête" : (to >= total ? "Poser en fin" : "Poser ici")) {
                ed.grab = nil
                ed.structural { EdListOps.move(&$0, kind, from: from, to: to) }
            }
        }
    }
}

// MARK: - Listes du pool (`listEditor` : critères, diagnostics, posologie, à vérifier)

struct PoolListEditor: View {
    @Bindable var ed: FicheDraft
    var key: EdKit.ListKey
    var legend: String
    var crit: Bool
    var note: Bool

    private var kind: EdListKind {
        switch key {
        case .confirmation: return .confirmation
        case .posology: return .posology
        case .verify: return .verify
        case .differentials: return .differentials
        case .notForget: return .notForget
        }
    }

    var body: some View {
        let items = EdKit.listItems(ed.d, key)
        VStack(alignment: .leading, spacing: 6) {
            if items.isEmpty {
                EdField(value: "", placeholder: "…", label: legend + " — ligne 1", resync: ed.syncTick) { v in
                    ed.structural { EdKit.setList(&$0, key, [v]) }
                    if let it = EdKit.listItems(ed.d, key).first { ed.requestFocus("li:" + it.id) }
                }
            }
            ForEach(Array(items.enumerated()), id: \.element.id) { i, it in
                EdListDrop(ed: ed, kind: kind, to: i, total: items.count)
                row(i, it, total: items.count)
            }
            EdListDrop(ed: ed, kind: kind, to: items.count, total: items.count)
            EdLinkButton(text: "+ Ajouter une ligne") {
                ed.structural { f in EdKit.setList(&f, key, EdKit.listOf(f, key) + [""]) }
                if let last = EdKit.listItems(ed.d, key).last { ed.requestFocus("li:" + last.id) }
            }
        }
    }

    @ViewBuilder private func row(_ i: Int, _ it: Item, total: Int) -> some View {
        let s = it.legacyString
        let on = Steps.isCrit(s) || Steps.isVigil(s)
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if total >= 2 {
                    EdGrabHandle(active: ed.grab == .list(kind, i), label: "Déplacer la ligne \(i + 1)") {
                        ed.grab = ed.grab == .list(kind, i) ? nil : .list(kind, i)
                    }
                }
                EdField(value: crit ? Steps.text(s) : s, placeholder: "…", label: legend + " — ligne \(i + 1)",
                        focusKey: "li:" + it.id, request: ed.focusRequest, resync: ed.syncTick) { v in
                    write(i, v)
                }
                EdIconButton(system: "bold", label: "Mettre la sélection en gras") { toggleBold(i) }
                    .help("Gras — sélectionnez du texte puis cliquez (ou Ctrl/Cmd-B). Réservez-le aux doses et interdictions critiques.")
                if crit {
                    Button { ed.updateItem(it.id, typing: false) { $0.level = on ? 1 : 2 } } label: {
                        Text("△").aFont(TypeScale.item, .bold).foregroundStyle(on ? T.warn : T.ink3)
                            .frame(width: Ctrl.m, height: Ctrl.m)
                            .background(on ? T.warnSoft : Color.clear, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .edLock()
                    .accessibilityLabel(on ? "Repère à vérifier" : "Repère normal")
                    .help(on ? "Repère à VÉRIFIER (carte ambre : risque d’erreur — dose, dilution, voie) — toucher : normal"
                             : "Repère normal — toucher : à vérifier (carte ambre)")
                }
                EdIconButton(system: "xmark", label: "Supprimer la ligne") { remove(it) }
            }
            if note {
                EdField(value: it.note, placeholder: "Préparation, dilution, administration (facultatif)",
                        label: legend + " — détail de la ligne \(i + 1)", maxLength: 500, size: TypeScale.body, resync: ed.syncTick) { v in
                    ed.updateItem(it.id, typing: true) { $0.note = v }
                }
                .padding(.leading, total >= 2 ? Ctrl.s + 6 : 0)
            }
        }
        .padding(.vertical, 2)
        .overlay(alignment: .leading) {
            if crit && on { Rectangle().fill(T.warnLine).frame(width: 3).offset(x: -8) }
        }
        .id("li:" + it.id)
    }
    /// Frappe : le préfixe de registre de la chaîne stockée est RE-POSÉ (le champ montre le texte nu).
    private func write(_ i: Int, _ v: String) {
        ed.typing { f in
            var a = EdKit.listOf(f, key)
            guard i < a.count else { return }
            let pfx = crit ? (Steps.isCrit(a[i]) ? "⚠ " : (Steps.isVigil(a[i]) ? "△ " : "")) : ""
            a[i] = pfx + v
            EdKit.setList(&f, key, a)
        }
    }
    /// Gras : sans accès à la sélection d'un champ d'une ligne, le geste porte sur la ligne entière
    /// (écart assumé ; `wrapBold` complet dans les champs multi-lignes).
    private func toggleBold(_ i: Int) {
        ed.structural { f in
            var a = EdKit.listOf(f, key)
            guard i < a.count else { return }
            let pfx = Steps.isCrit(a[i]) ? "⚠ " : (Steps.isVigil(a[i]) ? "△ " : "")
            let t = Steps.text(a[i])
            let e = EdKit.wrapBold(t, NSRange(location: 0, length: (t as NSString).length))
            a[i] = pfx + e.text
            EdKit.setList(&f, key, a)
        }
    }
    /// Supprimer une ligne : l'item quitte le pool par son IDENTITÉ ; la liste garde au moins une ligne.
    private func remove(_ it: Item) {
        ed.structural { f in
            f.items.removeAll { $0.id == it.id }
            if EdKit.listItems(f, key).isEmpty { EdKit.setList(&f, key, [""]) }
        }
    }
}

// MARK: - Références (sources — un champ, pas le pool)

struct SourcesEditor: View {
    @Bindable var ed: FicheDraft
    var body: some View {
        let src = ed.d.sources
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(src.enumerated()), id: \.offset) { i, s in
                EdListDrop(ed: ed, kind: .sources, to: i, total: src.count)
                HStack(spacing: 6) {
                    if src.count >= 2 {
                        EdGrabHandle(active: ed.grab == .list(.sources, i), label: "Déplacer la ligne \(i + 1)") {
                            ed.grab = ed.grab == .list(.sources, i) ? nil : .list(.sources, i)
                        }
                    }
                    EdField(value: s, placeholder: "…", label: "Références — ligne \(i + 1)", focusKey: "src:\(i)",
                            request: ed.focusRequest, resync: ed.syncTick) { v in
                        ed.typing { f in if i < f.sources.count { f.sources[i] = v } }
                    }
                    EdIconButton(system: "xmark", label: "Supprimer la ligne") {
                        ed.structural { f in
                            if i < f.sources.count { f.sources.remove(at: i) }
                            if f.sources.isEmpty { f.sources = [""] }
                        }
                    }
                }
                .id("src:\(i)")
            }
            EdListDrop(ed: ed, kind: .sources, to: src.count, total: src.count)
            EdLinkButton(text: "+ Ajouter une ligne") {
                let n = ed.d.sources.count
                ed.structural { $0.sources.append("") }
                ed.requestFocus("src:\(n)")
            }
        }
        .id("f-sources")
    }
}

// MARK: - Condition d'entrée (critères + diagnostics à éliminer)

struct EntryConditionCard: View {
    @Bindable var ed: FicheDraft
    var body: some View {
        EdCard(title: "Condition d’entrée", hint: "quand déclencher cette procédure") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("Critères").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                        Text("ce qui confirme le tableau").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                    }
                    PoolListEditor(ed: ed, key: .confirmation, legend: "Critères", crit: false, note: false)
                }
                if !EdKit.listItems(ed.d, .differentials).isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Diagnostics à éliminer").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                        Text("« le tableau ne colle pas » — premier motif d’ouverture de « Consulter »").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                        PoolListEditor(ed: ed, key: .differentials, legend: "Diagnostics à éliminer", crit: false, note: false)
                    }
                }
            }
        }
    }
}

// MARK: - Prise en charge (blocs d'étapes et décisions, `renderEditor`)

struct CareCard: View {
    @Bindable var ed: FicheDraft
    var wide: Bool
    @AppStorage("ac-flowprev-open") private var flowOpen = false
    @AppStorage("ac-cg-open") private var guideOpen = false

    var body: some View {
        let blocks = ed.d.blocks
        let n = blocks.count
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Prise en charge").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink)
                Text("listes d'étapes + décisions conditionnelles").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
            }
            if !wide && n > 0 { flowFold(n) }
            critGuide
            ForEach(Array(blocks.enumerated()), id: \.element.id) { bi, b in
                if b.kind != .review {
                    blockDrop(bi)
                    BlockEditorCard(ed: ed, bid: b.id)
                }
            }
            blockDrop(blocks.count)
        }
    }

    @ViewBuilder private func flowFold(_ n: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { flowOpen.toggle() } label: {
                HStack {
                    Text("Algorithme — aperçu automatique").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                    Text("\(n) bloc" + either(n > 1, "s", "")).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                    Spacer()
                    Image(systemName: flowOpen ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundStyle(T.ink2)
                }
                .frame(minHeight: Ctrl.m).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .edLock()
            if flowOpen { EditorFlowPreview(fiche: ed.d) }
        }
    }

    private var critGuide: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { guideOpen.toggle() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle").foregroundStyle(T.act)
                    Text("Rouge, ambre, réponse attendue").aFont(TypeScale.body, .semibold).foregroundStyle(T.act)
                    Spacer()
                }
                .frame(minHeight: Ctrl.m).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .edLock()
            if guideOpen {
                Text(guideText).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private var guideText: AttributedString {
        var a = AttributedString("⚠ ")
        var crit = AttributedString("Critique"); crit.inlinePresentationIntent = .stronglyEmphasized; crit.foregroundColor = T.crit
        a += crit
        a += AttributedString(" : ce qui tue si on l'oublie (memory item, geste vital). ")
        var vig = AttributedString("△ Vigilance"); vig.inlinePresentationIntent = .stronglyEmphasized; vig.foregroundColor = T.warn
        a += vig
        a += AttributedString(" : là où l'on risque de se tromper (dose/dilution à vérifier avant injection, contre-indication à écarter, confusion voie/site/produit, seuil à contrôler avant de poursuivre). « ! » ou « ? » en tête d'étape pose le registre. ")
        var rep = AttributedString("Réponse attendue"); rep.inlinePresentationIntent = .stronglyEmphasized
        a += rep
        a += AttributedString(" : sous l'étape (ex. « Adrénaline IM » → « 0,01 mg/kg — max 0,5 mg ») — elle devient la pilule à confirmer en lecture (challenge-response).")
        return a
    }

    /// Destinations « Poser avant le bloc 1 » / « Poser ici » / « Poser en fin de fiche ».
    @ViewBuilder private func blockDrop(_ to: Int) -> some View {
        if case .block(let bid)? = ed.grab, let from = ed.d.blocks.firstIndex(where: { $0.id == bid }), to != from, to != from + 1 {
            EdDropTarget(label: to >= ed.d.blocks.count ? "Poser en fin de fiche" : (to == 0 ? "Poser avant le bloc 1" : "Poser ici")) {
                ed.grab = nil
                ed.structural { f in EdListOps.arrMove(&f.blocks, from, to) }
                ed.scrollTo("b:" + bid)
            }
        }
    }
}

// MARK: - Minuteurs & compteurs (§7.1, §7.2)

struct TimersCountersCard: View {
    @Bindable var ed: FicheDraft
    var body: some View {
        let ts = ed.d.timers, cs = ed.d.counters
        EdCard(title: "Minuteurs & compteurs", hint: "disponibles pendant la session") {
            VStack(alignment: .leading, spacing: 10) {
                if !ts.isEmpty {
                    EdSub(text: "Minuteurs")
                    ForEach(Array(ts.enumerated()), id: \.element.id) { i, t in
                        EdListDrop(ed: ed, kind: .timers, to: i, total: ts.count)
                        TimerCardEditor(ed: ed, timerId: t.id, index: i, total: ts.count)
                    }
                    EdListDrop(ed: ed, kind: .timers, to: ts.count, total: ts.count)
                }
                if !cs.isEmpty {
                    EdSub(text: "Compteurs").padding(.top, ts.isEmpty ? 0 : 8)
                    ForEach(Array(cs.enumerated()), id: \.element.id) { i, c in
                        EdListDrop(ed: ed, kind: .counters, to: i, total: cs.count)
                        CounterCardEditor(ed: ed, counterId: c.id, index: i, total: cs.count)
                    }
                    EdListDrop(ed: ed, kind: .counters, to: cs.count, total: cs.count)
                }
            }
        }
    }
}

struct TimerCardEditor: View {
    @Bindable var ed: FicheDraft
    var timerId: String
    var index: Int
    var total: Int

    var body: some View {
        if let t = ed.d.timers.first(where: { $0.id == timerId }) {
            let cyc = t.type == .interval
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(cyc ? "Cycle" : "Chrono").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
                        .padding(.horizontal, 8).frame(minHeight: 24).background(T.amb2, in: Capsule())
                    EdField(value: t.label, placeholder: cyc ? "ex. Cycle adrénaline (5 à 10 min)" : "ex. Temps écoulé",
                            label: cyc ? "Nom du cycle" : "Nom du chronomètre", focusKey: "t:" + t.id, request: ed.focusRequest,
                            maxLength: 120, weight: .semibold, resync: ed.syncTick) { v in update { $0.label = v } }
                    if total >= 2 {
                        EdGrabHandle(active: ed.grab == .list(.timers, index), label: "Déplacer le minuteur \(index + 1)") {
                            ed.grab = ed.grab == .list(.timers, index) ? nil : .list(.timers, index)
                        }
                    }
                    EdIconButton(system: "xmark", label: "Supprimer ce minuteur") {
                        ed.structural { f in f.timers.removeAll { $0.id == timerId } }
                    }
                }
                row("Nom court") {
                    EdField(value: t.short ?? "", placeholder: EdKit.autoShort(t.label, EdKit.shortTM),
                            label: "Nom court sur la capsule (facultatif — abrégé d’office sinon)", maxLength: 24, resync: ed.syncTick) { v in
                        update { $0.short = v.isEmpty ? nil : v }
                    }
                }
                if cyc {
                    row("Durée") {
                        HStack(spacing: 6) {
                            EdField(value: String(t.seconds / 60), placeholder: "0", label: "Durée — minutes", maxLength: 4,
                                    resync: ed.syncTick, numeric: true) { v in
                                let m = max(0, Int(v) ?? 0)
                                update { $0.seconds = min(86400, m * 60 + $0.seconds % 60) }
                            }
                            .frame(width: 72)
                            Text("min").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                            EdField(value: String(t.seconds % 60), placeholder: "0", label: "Durée — secondes", maxLength: 2,
                                    resync: ed.syncTick, numeric: true) { v in
                                let s = min(59, max(0, Int(v) ?? 0))
                                update { $0.seconds = min(86400, ($0.seconds / 60) * 60 + s) }
                            }
                            .frame(width: 60)
                            Text("s").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                        }
                    }
                    Toggle(isOn: Binding(get: { t.autoloop }, set: { v in ed.structural { f in
                        if let i = f.timers.firstIndex(where: { $0.id == timerId }) { f.timers[i].autoloop = v } } })) {
                        Text("se relance").aFont(TypeScale.body, .semibold).foregroundStyle(T.ink)
                    }
                    .toggleStyle(.switch).tint(T.act).edLock()
                    .accessibilityLabel("Relancer le cycle automatiquement")
                    row("À l’échéance") {
                        EdField(value: t.onDue, placeholder: "ex. Renouveler l’adrénaline si pas de réponse", label: "Ligne d’action annoncée par l’alarme",
                                maxLength: 120, resync: ed.syncTick) { v in update { $0.onDue = v } }
                    }
                    Text("Ce que l’alarme dira quand elle sonnera — l’action, pas le nom du minuteur.")
                        .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Un chronomètre COMPTE le temps écoulé : il ne sonne pas. Pour une alarme, prenez un minuteur ou un cycle.")
                        .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(T.amb2.opacity(0.5), in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
            .id("t:" + timerId)
        }
    }
    private func update(_ g: @escaping (inout TimerDef) -> Void) {
        ed.typing { f in if let i = f.timers.firstIndex(where: { $0.id == timerId }) { g(&f.timers[i]) } }
    }
    @ViewBuilder private func row<C: View>(_ l: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(l).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
            c()
        }
    }
}

struct CounterCardEditor: View {
    @Bindable var ed: FicheDraft
    var counterId: String
    var index: Int
    var total: Int

    var body: some View {
        if let c = ed.d.counters.first(where: { $0.id == counterId }) {
            let intervals = ed.d.timers.filter { $0.type == .interval }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("Compteur").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
                        .padding(.horizontal, 8).frame(minHeight: 24).background(T.amb2, in: Capsule())
                    EdField(value: c.label, placeholder: "ex. Adrénaline (mg)", label: "Nom du compteur", focusKey: "n:" + c.id,
                            request: ed.focusRequest, maxLength: 120, weight: .semibold, resync: ed.syncTick) { v in update { $0.label = v } }
                    if total >= 2 {
                        EdGrabHandle(active: ed.grab == .list(.counters, index), label: "Déplacer le compteur \(index + 1)") {
                            ed.grab = ed.grab == .list(.counters, index) ? nil : .list(.counters, index)
                        }
                    }
                    EdIconButton(system: "xmark", label: "Supprimer ce compteur") {
                        ed.structural { f in f.counters.removeAll { $0.id == counterId } }
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nom court").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
                    EdField(value: c.short ?? "", placeholder: EdKit.autoShort(c.label, EdKit.shortCN),
                            label: "Nom court sur la capsule (facultatif — abrégé d’office sinon)", maxLength: 24, resync: ed.syncTick) { v in
                        update { $0.short = v.isEmpty ? nil : v }
                    }
                }
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pas").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
                        EdField(value: String(c.step), placeholder: "1", label: "Pas", maxLength: 4, resync: ed.syncTick, numeric: true) { v in
                            update { $0.step = min(9999, max(1, Int(v) ?? 1)) }
                        }
                        .frame(width: 96)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Départ").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
                        EdField(value: String(c.start), placeholder: "0", label: "Départ", maxLength: 9, resync: ed.syncTick, numeric: true) { v in
                            update { $0.start = max(0, Int(v) ?? 0) }
                        }
                        .frame(width: 120)
                    }
                }
                if !intervals.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Le ＋ relance").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
                        Picker("Minuteur relancé par le ＋ du compteur", selection: Binding<String>(
                            get: { c.timerId },
                            set: { v in ed.structural { f in if let i = f.counters.firstIndex(where: { $0.id == counterId }) { f.counters[i].timerId = v } } })) {
                            Text("rien").tag("")
                            ForEach(intervals) { t in Text("« " + (t.label.isEmpty ? "Minuteur" : t.label) + " »").tag(t.id) }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .edLock()
                        .help("Le « ＋ » du compteur relance ce minuteur (ex. bolus -> cycle)")
                    }
                }
                Text("Son libellé nomme les repères du journal des actions et le compteur du compte-rendu : court et lisible hors contexte.")
                    .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(T.amb2.opacity(0.5), in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
            .id("n:" + counterId)
        }
    }
    private func update(_ g: @escaping (inout CounterDef) -> Void) {
        ed.typing { f in if let i = f.counters.firstIndex(where: { $0.id == counterId }) { g(&f.counters[i]) } }
    }
}

// MARK: - Complications « à tout moment » (§7.3)

struct ComplicationsCard: View {
    @Bindable var ed: FicheDraft
    @Environment(AppModel.self) private var model

    var body: some View {
        let cx = ed.d.excursions
        EdCard(title: "⚡ Complications — à tout moment",
               hint: "1 à 3 : l'essentiel — chaque bouton de plus dilue les autres. Cible = un bloc dédié de cette fiche, ou une autre aide") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(cx.enumerated()), id: \.offset) { i, c in
                    EdListDrop(ed: ed, kind: .excursions, to: i, total: cx.count)
                    row(i, c, total: cx.count)
                }
                EdListDrop(ed: ed, kind: .excursions, to: cx.count, total: cx.count)
            }
        }
    }
    @ViewBuilder private func row(_ i: Int, _ c: Excursion, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if total >= 2 {
                    EdGrabHandle(active: ed.grab == .list(.excursions, i), label: "Déplacer la complication \(i + 1)") {
                        ed.grab = ed.grab == .list(.excursions, i) ? nil : .list(.excursions, i)
                    }
                }
                Image(systemName: "bolt.fill").foregroundStyle(T.bolt).accessibilityHidden(true)
                EdField(value: c.label, placeholder: "Événement (ex. Laryngospasme)", label: "Complication \(i + 1)",
                        focusKey: "cx:\(i)", request: ed.focusRequest, maxLength: 120, weight: .semibold, resync: ed.syncTick) { v in
                    ed.typing { f in if i < f.excursions.count { f.excursions[i].label = v } }
                }
                EdIconButton(system: "xmark", label: "Supprimer cette complication") {
                    ed.structural { f in if i < f.excursions.count { f.excursions.remove(at: i) } }
                }
            }
            HStack(spacing: 8) {
                EdField(value: c.short ?? "", placeholder: EdKit.cxShort(c.label),
                        label: "Nom court sur le quai (facultatif — abrégé d’office sinon)", maxLength: 24, resync: ed.syncTick) { v in
                    ed.typing { f in if i < f.excursions.count { f.excursions[i].short = v.isEmpty ? nil : v } }
                }
                .frame(maxWidth: 200)
                Button { ed.sheet = .cxTarget(i) } label: {
                    Text(targetName(c)).aFont(TypeScale.body, .semibold)
                        .foregroundStyle(c.target.isEmpty ? T.act : T.ink)
                        .lineLimit(1)
                        .padding(.horizontal, 12).frame(minHeight: Ctrl.m)
                        .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .edLock()
                .accessibilityLabel("Cible de la complication : " + targetName(c))
            }
        }
        .id("cx:\(i)")
    }
    private func targetName(_ c: Excursion) -> String {
        if c.target.isEmpty { return "Choisir la cible…" }
        if let b = ed.d.blocks.first(where: { $0.id == c.target }) {
            let t = JS.trim(b.title)
            return "Bloc — " + (t.isEmpty ? b.id : t)
        }
        if let f = model.fiches.first(where: { $0.id == c.target }) { return f.title.isEmpty ? "Sans titre" : f.title }
        if let p = model.references.first(where: { $0.id == c.target }) { return p.title.isEmpty ? "Sans titre" : p.title }
        return "Sans titre"
    }
}

// MARK: - Revues « à tout moment » (A396)

struct ReviewBlocksCard: View {
    @Bindable var ed: FicheDraft
    var body: some View {
        EdCard(title: "▦ Revues — à tout moment",
               hint: "une liste cochable pendant la session, dans sa boîte ; posée dans un bloc par les Réglages d’une étape") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(ed.d.blocks.filter { $0.kind == .review }) { b in
                    BlockEditorCard(ed: ed, bid: b.id)
                }
            }
        }
    }
}

// MARK: - Contexte local (gras sur la SÉLECTION : champ multi-lignes natif)

struct LocalContextCard: View {
    @Bindable var ed: FicheDraft
    @State private var ctl = EdTextController()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Contexte local").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                Text("numéros utiles, particularités").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                Spacer()
                EdIconButton(system: "bold", label: "Mettre la sélection en gras") {
                    ctl.onEdit = { v in ed.typing { $0.local = JS.prefix(v, 4000) } }
                    ctl.apply(EdKit.wrapBold(ed.d.local, ctl.selection))
                }
                .help("Gras — sélectionnez du texte puis cliquez (ou Ctrl/Cmd-B). Réservez-le aux doses et interdictions critiques.")
            }
            EdTextView(text: ed.d.local, placeholder: "Réanimateur de garde, pharmacie…", accessibility: "Contexte local",
                       minHeight: 64, controller: ctl) { v in
                ed.typing { $0.local = JS.prefix(v, 4000) }
            }
        }
        .id("f-local")
    }
}

// MARK: - Schémas & captures (§5.12)

struct GalleryCard: View {
    @Bindable var ed: FicheDraft

    var body: some View {
        EdCard(title: "Schémas & captures", hint: "stockées hors ligne dans l'app") {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], alignment: .leading, spacing: 12) {
                    ForEach(ed.d.images) { im in tile(im) }
                }
                EdDropZone(title: "Ajouter une image / capture", sub: "PNG · JPEG · WebP · HEIC — glissez ici ou cliquez · plusieurs à la fois") {
                    ed.imageChoice = .gallery
                }
            }
        }
    }
    @ViewBuilder private func tile(_ im: ImageRef) -> some View {
        let holder = ed.d.blocks.first { $0.image == im.data }
        VStack(alignment: .leading, spacing: 6) {
            EdDataImage(key: im.id, dataURI: im.data)
                .frame(maxWidth: .infinity, minHeight: 90, maxHeight: 140)
                .clipShape(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                .accessibilityLabel(im.caption.isEmpty ? "Image" : im.caption)
            EdField(value: im.caption, placeholder: "Légende…", label: "Légende", maxLength: 300, size: TypeScale.body, resync: ed.syncTick) { v in
                ed.typing { f in if let i = f.images.firstIndex(where: { $0.id == im.id }) { f.images[i].caption = v } }
            }
            Picker("Bloc qui affiche cette image", selection: Binding<String>(
                get: { holder?.id ?? "" },
                set: { v in attach(im, to: v) })) {
                Text("— Aucun bloc —").tag("")
                ForEach(ed.d.blocks) { b in Text(blockName(b)).tag(b.id) }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .edLock()
            Button("Retirer") { remove(im) }.buttonStyle(.a(.danger, Ctrl.s)).edLock()
        }
    }
    private func blockName(_ b: Block) -> String {
        let t = JS.trim(EdKit.stripBold(b.title))
        return t.isEmpty ? (b.kind == .decision ? "Décision" : "Sans titre") : t
    }
    /// Une image → au plus un bloc : détachée de TOUS, puis posée sur le bloc choisi (copie de la donnée).
    private func attach(_ im: ImageRef, to bid: String) {
        ed.structural { f in
            for i in f.blocks.indices where f.blocks[i].image == im.data { f.blocks[i].image = nil; f.blocks[i].imageW = 0; f.blocks[i].imageH = 0 }
            if let i = f.blocks.firstIndex(where: { $0.id == bid }) {
                f.blocks[i].image = im.data; f.blocks[i].imageW = im.w; f.blocks[i].imageH = im.h
            }
        }
    }
    /// « Retirer » de la galerie : l'image quitte la fiche ENTIÈRE (galerie et bloc qui la porte).
    private func remove(_ im: ImageRef) {
        ed.structural { f in
            f.images.removeAll { $0.id == im.id }
            for i in f.blocks.indices where f.blocks[i].image == im.data { f.blocks[i].image = nil; f.blocks[i].imageW = 0; f.blocks[i].imageH = 0 }
        }
    }
}

// MARK: - Documents (PDF) — partagé (§18.1)

struct EdDocsCard: View {
    var docs: [Attachment]
    var attachable: Int
    var resync: Int
    var onRename: (Int, String) -> Void
    var onRemove: (Int) -> Void
    var onAdd: () -> Void
    var onPickExisting: () -> Void

    var body: some View {
        EdCard(title: "Documents (PDF)", hint: "protocoles, recommandations — lisibles hors ligne") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(docs.enumerated()), id: \.element.id) { i, a in
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text").foregroundStyle(T.ink2).accessibilityHidden(true)
                        EdField(value: a.name, placeholder: "Nom du document", label: "Nom du document", maxLength: 150, resync: resync) { v in onRename(i, v) }
                        Text(EdKit.fmtBytes(a.size)).aFont(TypeScale.meta, .regular, .mono).foregroundStyle(T.ink2)
                        EdIconButton(system: "xmark", label: "Retirer le document") { onRemove(i) }
                    }
                }
                EdDropZone(title: "Ajouter un PDF (" + EdKit.fmtBytes(Guard.maxPdfBytes) + " max)", sub: "PDF — glissez ici ou cliquez · plusieurs à la fois", action: onAdd)
                if attachable > 0 {
                    EdLinkButton(text: "+ Joindre un document existant (\(attachable) disponible" + either(attachable > 1, "s", "") + ")…", action: onPickExisting)
                }
            }
        }
    }
}

struct FicheDocsCard: View {
    @Bindable var ed: FicheDraft
    @Environment(AppModel.self) private var model
    var body: some View {
        EdDocsCard(docs: ed.d.docs,
                   attachable: EdKit.attachablePdfs(selfId: ed.d.id, docs: ed.d.docs, library: ed.d.library, fiches: model.fiches, references: model.references).count,
                   resync: ed.syncTick,
                   onRename: { i, v in ed.typing { f in if i < f.docs.count { f.docs[i].name = v } } },
                   onRemove: { i in ed.structural { f in if i < f.docs.count { f.docs.remove(at: i) } } },
                   onAdd: { ed.fileImport = .pdf },
                   onPickExisting: { ed.sheet = .attPicker })
    }
}

// MARK: - Voir aussi — partagé (§5.15)

struct LinkChip: Identifiable {
    var id: String
    var title: String
    var isRef: Bool
}

struct EdLinksCard: View {
    var links: [String]
    var candidates: Int
    var onRemove: (String) -> Void
    var onAdd: () -> Void
    @Environment(AppModel.self) private var model

    var body: some View {
        EdCard(title: "Voir aussi", hint: "aides cognitives et protocoles liés — raccourcis en lecture") {
            VStack(alignment: .leading, spacing: 10) {
                let chips: [LinkChip] = links.compactMap { id in target(id).map { LinkChip(id: id, title: $0.0, isRef: $0.1) } }
                if chips.isEmpty {
                    Text("Aucun lien pour le moment.").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                } else {
                    EdFlow(spacing: 8) {
                        ForEach(chips) { c in chip(c.id, c.title, c.isRef) }
                    }
                }
                if candidates > 0 {
                    EdLinkButton(text: "+ Lier une aide ou un protocole (\(candidates) disponible" + either(candidates > 1, "s", "") + ")…", action: onAdd)
                } else {
                    Text("Rien d’autre à lier dans ce périmètre (Perso ou même bibliothèque).").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                }
            }
        }
    }
    private func target(_ id: String) -> (String, Bool)? {
        if let f = model.fiches.first(where: { $0.id == id }) { return (f.title, false) }
        if let p = model.references.first(where: { $0.id == id }) { return (p.title, true) }
        return nil
    }
    @ViewBuilder private func chip(_ id: String, _ title: String, _ isRef: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isRef ? "book" : "doc.text").font(.system(size: 12)).foregroundStyle(T.ink2)
            Text(title.isEmpty ? "Sans titre" : title).aFont(TypeScale.body, .semibold).foregroundStyle(T.ink).lineLimit(1)
            Button { onRemove(id) } label: {
                Image(systemName: "xmark").font(.system(size: 11, weight: .bold)).foregroundStyle(T.ink2)
                    .frame(width: Ctrl.s, height: Ctrl.s).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .edLock()
            .accessibilityLabel("Retirer")
        }
        .padding(.leading, 10)
        .background(T.amb2, in: Capsule())
    }
}

struct FicheLinksCard: View {
    @Bindable var ed: FicheDraft
    @Environment(AppModel.self) private var model
    var body: some View {
        EdLinksCard(links: ed.d.links,
                    candidates: EdKit.relCandidates(selfId: ed.d.id, links: ed.d.links, library: ed.d.library, fiches: model.fiches, references: model.references).count,
                    onRemove: { id in ed.structural { $0.links.removeAll { $0 == id } } },
                    onAdd: { ed.sheet = .links })
    }
}

// MARK: - Note personnelle (`noteBlockHtml`) — jamais partagée, enregistrée à part du brouillon

struct EdNoteBlock: View {
    var ficheId: String
    @Environment(AppModel.self) private var model
    @State private var text = ""
    @State private var loaded = false
    @State private var editing = false
    @State private var state = ""
    @State private var task: Task<Void, Never>?

    var body: some View {
        Group {
            if !editing && JS.trim(text).isEmpty {
                Button { editing = true } label: {
                    Text("✎ Ajouter une note personnelle").aFont(TypeScale.body, .bold).foregroundStyle(T.act)
                        .frame(minHeight: Ctrl.l).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .edLock()
            } else {
                WorkCard(padding: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Notes personnelles").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                            Spacer()
                            if editing {
                                Button("Terminer") { finish() }.buttonStyle(.a(.primary, Ctrl.s)).edLock()
                            } else {
                                Button("Modifier") { editing = true }.buttonStyle(.a(.secondary, Ctrl.s)).edLock()
                            }
                        }
                        if editing {
                            TextField("", text: $text, prompt: Text("Vos notes sur cette fiche.").foregroundColor(T.ink3), axis: .vertical)
                                .lineLimit(3...12)
                                .textFieldStyle(.plain)
                                .aFont(TypeScale.item, .regular)
                                .padding(10)
                                .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                                .accessibilityLabel("Notes personnelles")
                                .onChange(of: text) { _, _ in schedule() }
                        } else {
                            BoldText(text: text, size: TypeScale.item)
                        }
                        Text("Jamais partagée : visible par vous seulement." + (state.isEmpty ? "" : " " + state))
                            .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                    }
                }
            }
        }
        .onAppear { if !loaded { text = model.library.note(ficheId); loaded = true } }
        .onDisappear { if editing { task?.cancel(); model.saveNote(ficheId, text) } }
    }
    private func schedule() {
        guard loaded else { return }
        state = "Enregistrement…"
        task?.cancel()
        let t = text
        task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            model.saveNote(ficheId, t)
            state = "Enregistrée à l’instant"
        }
    }
    private func finish() {
        task?.cancel()
        model.saveNote(ficheId, text)
        state = ""
        editing = false
    }
}

// MARK: - La porte « ＋ » (collante au pied du formulaire)

struct FicheDoor: View {
    @Bindable var ed: FicheDraft
    var body: some View {
        if ed.grab == nil {
            Button { ed.sheet = .palette } label: {
                HStack(spacing: 12) {
                    Text("＋").aFont(TypeScale.stepL, .bold).foregroundStyle(T.onPrimary)
                        .frame(width: Ctrl.m, height: Ctrl.m).background(T.act, in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Ajouter à cette aide").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                        Text("bloc · minuteur · dose · schéma…").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: 760, minHeight: Ctrl.xl)
                .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.workLine))
                .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .accessibilityLabel("Ajouter à cette aide")
            .accessibilityHint("bloc · minuteur · dose · schéma…")
        }
    }
}
