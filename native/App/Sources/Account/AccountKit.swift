import SwiftUI
import UniformTypeIdentifiers
import AidesCore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// BOÎTE À OUTILS DE LA ZONE « COMPTE / CRÉER / IMPORT » — les pièces que ses fenêtres partagent :
// coque de fenêtre (titre + ✕), sélecteur segmenté à pastille GLISSANTE, dialogue de
// confirmation (`confirmDlg`, avec sa case à cocher optionnelle), rangée de menu (`menuRowHtml`),
// exportation (`exportData`), formatage des octets (`fmtBytes`) et aplatissement des fiches pour
// les comparaisons (`flattenFiche` / `flattenProto`). Tout est préfixé `Acct` : d'autres zones
// écrivent en parallèle dans le même module, et un nom générique finirait par entrer en collision.

// MARK: - Coque de fenêtre

/// L'action principale d'une fenêtre, à DROITE de la barre (`.confirmationAction`), seule en style
/// proéminent (guide iOS 27 : Annuler ✕ à gauche, action principale à droite).
struct AcctBarAction {
    var title: String
    /// Symbole SF (« checkmark » pour « Enregistrer »/« Terminer ») ; nil = le libellé en texte.
    var systemImage: String?
    var disabled = false
    var action: () -> Void
}

/// Fenêtre de la PWA (`.ai-modal`) portée par les COMPOSANTS SYSTÈME : `NavigationStack`, titre de
/// navigation, ✕ en `.cancellationAction` (le système lui donne le verre), action principale en
/// `.confirmationAction`. Le contenu reste sur la matière OPAQUE (ambiance + cartes) : le verre
/// ne vit que dans la couche fonctionnelle. « Page-fenêtre » 720, « dialogue » 480.
struct AcctWindow<Content: View>: View {
    var title: String
    var maxWidth: CGFloat = 720
    /// true = déjà dans une pile de navigation (racine d'onglet, page poussée) : pas de NavigationStack propre.
    var embedded = false
    /// Grand titre (écran racine d'onglet, iOS).
    var largeTitle = false
    /// nil = pas de ✕ (racine d'onglet, page poussée : le retour est celui du système).
    var onClose: (() -> Void)?
    var closeLabel = "Fermer"
    var confirm: AcctBarAction? = nil
    @ViewBuilder var content: Content

    var body: some View {
        if embedded {
            page
        } else {
            NavigationStack { page }
                .presentationSizing(.form)
                .acctSheetSize(maxWidth)
        }
    }

    private var page: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { content }
                .padding(16)
                .frame(maxWidth: maxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(T.amb.ignoresSafeArea())
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(largeTitle ? .large : .inline)
        #endif
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onClose) { Image(systemName: "xmark") }
                        .accessibilityLabel(closeLabel)
                        .keyboardShortcut(.cancelAction)
                }
            }
            if let c = confirm {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: c.action) {
                        if let img = c.systemImage { Image(systemName: img) } else { Text(c.title) }
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(c.disabled)
                    .accessibilityLabel(c.title)
                }
            }
        }
    }
}

extension View {
    /// Gabarit d'une feuille sur Mac (une feuille macOS se dimensionne sur son contenu).
    func acctSheetSize(_ width: CGFloat) -> some View {
        #if os(macOS)
        return self.frame(minWidth: min(width, 480), idealWidth: width, minHeight: 420, idealHeight: 640)
        #else
        return self
        #endif
    }
}

/// Intitulé de zone dans une fenêtre (« Sur cet appareil », « Affichage », « Zone sensible »).
struct AcctZoneTitle: View {
    var text: String
    var color: Color = T.ink2
    var body: some View {
        Overline(text: text, color: color)
            .padding(.top, 8)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Ligne de message sous un champ (`.auth-msg`) : erreur en rouge (le texte dit l'erreur), sinon neutre.
struct AcctMessage: Equatable {
    var text: String
    var isError: Bool
    static func err(_ s: String) -> AcctMessage { AcctMessage(text: s, isError: true) }
    static func info(_ s: String) -> AcctMessage { AcctMessage(text: s, isError: false) }
}

struct AcctMessageLine: View {
    var message: AcctMessage?
    var body: some View {
        if let m = message, !m.text.isEmpty {
            Text(m.text)
                .aFont(TypeScale.body, .semibold)
                .foregroundStyle(m.isError ? T.crit : T.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.updatesFrequently)
        }
    }
}

/// Indice sous un réglage, avec « En savoir plus » dépliable (`hintMore`).
struct AcctHint: View {
    var text: String
    var more: String?
    @State private var open = false
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            BoldText(text: text, size: TypeScale.meta, color: T.ink2)
                .fixedSize(horizontal: false, vertical: true)
            if let more {
                Button { withAnimation(.easeOut(duration: 0.15)) { open.toggle() } } label: {
                    HStack(spacing: 4) {
                        Text("En savoir plus").aFont(TypeScale.meta, .bold)
                        Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 10, weight: .bold))
                    }
                    .frame(minHeight: Ctrl.s)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(T.act)
                .accessibilityAddTraits(.isButton)
                .accessibilityValue(open ? "déplié" : "replié")
                if open {
                    BoldText(text: more, size: TypeScale.meta, color: T.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Sélecteur segmenté (la pastille GLISSE, elle ne saute pas — A350)

struct AcctSegOption<V: Hashable>: Identifiable {
    var value: V
    var label: String
    /// Corps du libellé (la taille du texte montre trois « A » croissants).
    var size: CGFloat = TypeScale.body
    var a11y: String? = nil
    var id: V { value }
}

struct AcctSegmented<V: Hashable>: View {
    var options: [AcctSegOption<V>]
    @Binding var selection: V
    var accessibilityLabel: String
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options) { o in
                segment(o)
            }
        }
        .padding(3)
        .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func segment(_ o: AcctSegOption<V>) -> some View {
        let on = selection == o.value
        Button {
            withAnimation(.easeOut(duration: 0.2)) { selection = o.value }
        } label: {
            Text(o.label)
                .aFont(o.size, on ? .bold : .semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(on ? T.ink : T.ink2)
                .frame(maxWidth: .infinity, minHeight: Ctrl.m - 6)
                .padding(.horizontal, 6)
                .background {
                    if on {
                        RoundedRectangle(cornerRadius: Radius.r2, style: .continuous)
                            .fill(T.work)
                            .shadow(color: Color.black.opacity(0.08), radius: 3, y: 1)
                            .matchedGeometryEffect(id: "pastille", in: ns)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(o.a11y ?? o.label)
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }
}

/// Case à cocher (rangée entière cliquable, cible ≥ 32).
struct AcctCheckRow: View {
    var label: String
    @Binding var isOn: Bool
    var danger = false
    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isOn ? (danger ? T.crit : T.act) : T.ctlLine)
                BoldText(text: label, size: TypeScale.body, color: T.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(minHeight: Ctrl.s)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label.replacingOccurrences(of: "**", with: ""))
        .accessibilityValue(isOn ? "cochée" : "non cochée")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Rangée de menu (`menuRowHtml`) : icône · libellé · sous-ligne · chevron

struct AcctMenuRow: View {
    var icon: String
    var title: String
    var sub: String = ""
    var chevron = false
    var tint: Color = T.ink
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint == T.ink ? T.ink2 : tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).aFont(TypeScale.item, .bold).foregroundStyle(tint)
                    .fixedSize(horizontal: false, vertical: true)
                if !sub.isEmpty {
                    Text(sub).aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            if chevron {
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(T.ink3)
            }
        }
        .frame(minHeight: Ctrl.row)
        .contentShape(Rectangle())
    }
}

/// Avatar à initiales (2 premiers caractères de l'e-mail, en capitales).
struct AcctAvatar: View {
    var email: String
    var size: CGFloat = 44
    var tint: Color = T.act
    var body: some View {
        Text(JS.prefix(JS.trim(email), 2).uppercased())
            .aFont(size * 0.36, .bold)
            .foregroundStyle(T.onPrimary)
            .frame(width: size, height: size)
            .background(tint, in: Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - Dialogue de confirmation (`confirmDlg`)

enum AcctConfirmResult: Equatable {
    case yes(checked: Bool)
    case no
    /// ✕, glissement, Échap : ni oui ni non (`null` dans la PWA).
    case dismissed
}

/// `confirmDlg(msg, opts)` : titre, message (sauts de ligne gardés), « Annuler » / « Confirmer »,
/// `danger` (primaire rouge), case optionnelle (qui rend la primaire destructive sauf `checkSafe`).
struct AcctConfirm: Identifiable {
    let id = UUID()
    var title = "Confirmer"
    var message: String
    var yes = "Confirmer"
    var no = "Annuler"
    var danger = false
    var check: String? = nil
    var checkSafe = false
    var checkRequired = false
    var onResult: (AcctConfirmResult) -> Void
}

struct AcctConfirmView: View {
    var confirm: AcctConfirm
    @Environment(\.dismiss) private var dismiss
    @State private var checked = false
    @State private var result: AcctConfirmResult?

    var body: some View {
        let red = confirm.danger || (checked && !confirm.checkSafe)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BoldText(text: confirm.message, size: TypeScale.item, color: T.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let c = confirm.check {
                        AcctCheckRow(label: c, isOn: $checked, danger: !confirm.checkSafe)
                    }
                    // Deux capsules, une seule proéminente ; « Annuler » = non, ✕ = ni oui ni non.
                    VStack(spacing: 10) {
                        Button(confirm.yes) { answer(.yes(checked: checked)) }
                            .buttonStyle(.a(red ? .danger : .primary, Ctrl.l, full: true))
                            .disabled(confirm.checkRequired && !checked)
                        Button(confirm.no) { answer(.no) }
                            .buttonStyle(.a(.secondary, Ctrl.l, full: true))
                    }
                }
                .padding(20)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .background(T.amb.ignoresSafeArea())
            .navigationTitle(confirm.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { answer(.dismissed) } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Fermer")
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationSizing(.form)
        .acctSheetSize(480)
        .onDisappear {
            // Le résultat part APRÈS la fermeture : une confirmation peut en enchaîner une autre
            // (fusionner → remplacer → doublons) sans deux feuilles superposées.
            let r = result ?? .dismissed
            let handler = confirm.onResult
            DispatchQueue.main.async { handler(r) }
        }
    }

    private func answer(_ r: AcctConfirmResult) {
        result = r
        dismiss()
    }
}

extension View {
    @MainActor
    /// Présente un `AcctConfirm` (une seule confirmation à la fois).
    func acctConfirm(_ item: Binding<AcctConfirm?>) -> some View {
        sheet(item: item) { c in AcctConfirmView(confirm: c) }
    }
}

// MARK: - Presse-papiers

@MainActor
func acctCopyToClipboard(_ s: String) {
    #if canImport(UIKit)
    UIPasteboard.general.string = s
    #elseif canImport(AppKit)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(s, forType: .string)
    #endif
}

// MARK: - Octets (`fmtBytes`)

/// « {n} o », « {n} Ko », « {x,x} Mo », « {x,xx} Go » (virgule décimale).
func acctFmtBytes(_ v: Double) -> String {
    let n = v.isFinite ? v : 0
    if n < 1024 { return String(Int(n)) + " o" }
    if n < 1_048_576 { return String(Int(JS.round(n / 1024))) + " Ko" }
    if n < 1_073_741_824 { return String(format: "%.1f", n / 1_048_576).replacingOccurrences(of: ".", with: ",") + " Mo" }
    return String(format: "%.2f", n / 1_073_741_824).replacingOccurrences(of: ".", with: ",") + " Go"
}

/// Marque du pluriel (« s » au-delà de 1) — à interpoler : une longue chaîne de `+` et de
/// ternaires épuise le vérificateur de types de Swift.
func acctS(_ n: Int) -> String { n > 1 ? "s" : "" }

/// Pluriel français simple : « 1 élément », « 3 éléments ».
func acctPlural(_ n: Int, _ one: String, _ many: String) -> String { String(n) + " " + (n > 1 ? many : one) }

// MARK: - Export (`exportData`)

/// Le fichier produit par un export (.json ou .zip) — passé tel quel à `.fileExporter`.
struct AcctExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .zip] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

/// Un export prêt à enregistrer (document, type, nom, notices à dire après l'enregistrement).
struct AcctExportRequest: Identifiable {
    let id = UUID()
    var document: AcctExportDocument
    var type: UTType
    var name: String
    var notices: [String]
}

extension AppModel {
    /// Prépare l'export (`exportData`) : enveloppe `version: 3`, puis .json seul ou .zip avec
    /// `documents/<id>.pdf`. `withDocuments` n'a de sens que si des documents sont référencés.
    func acctBuildExport(fiches: [Fiche], references: [Reference], categories: [Category]?, base: String, withDocuments: Bool) -> AcctExportRequest {
        let env = Exporter.envelope(fiches: fiches, references: references, categories: categories,
                                    all: self.categories, space: store.currentSpace)
        let ids = Exporter.attachmentIds(fiches: fiches, references: references)
        let r = Exporter.build(envelope: env, withDocuments: withDocuments && !ids.isEmpty, attachmentIds: ids, store: library.space)
        var notices: [String] = []
        if !ids.isEmpty && !r.isZip { notices.append(Exporter.jsonOnlyNotice) }
        if r.missing > 0 { notices.append(Exporter.missingNotice(r.missing)) }
        let ext = r.isZip ? "zip" : "json"
        var name = Exporter.fileName(base: base, ext: ext)
        if name.hasSuffix("." + ext) { name = String(name.dropLast(ext.count + 1)) }
        return AcctExportRequest(document: AcctExportDocument(data: r.data), type: r.isZip ? .zip : .json, name: name, notices: notices)
    }
}

extension View {
    @MainActor
    /// Enregistre un `AcctExportRequest` (feuille de partage / panneau d'enregistrement du système).
    func acctExporter(_ request: Binding<AcctExportRequest?>, model: AppModel) -> some View {
        let shown = Binding<Bool>(get: { request.wrappedValue != nil }, set: { if !$0 { request.wrappedValue = nil } })
        let r = request.wrappedValue
        return fileExporter(isPresented: shown, document: r?.document, contentType: r?.type ?? .json,
                            defaultFilename: r?.name) { res in
            if case .success = res, let notices = r?.notices, !notices.isEmpty {
                model.toast(notices.joined(separator: " "), seconds: 9)
            }
            request.wrappedValue = nil
        }
    }
}

// MARK: - Aplatissement pour comparer (`flattenFiche`, `flattenProto`)

/// Lignes « Section · contenu » : une comparaison d'ensembles suffit à juger avant de restaurer
/// ou de remplacer (Versions, atelier d'import). Les images et documents ne sont PAS comparés.
enum AcctFlatten {
    private static func add(_ L: inout [String], _ sec: String, _ v: String) {
        let t = JS.trim(v)
        if !t.isEmpty { L.append(sec + " · " + t) }
    }
    /// `flattenFiche(f)` — les cinq listes sont des VUES sur le pool (`listOf`).
    static func fiche(_ f: Fiche) -> [String] {
        var L: [String] = []
        add(&L, "Titre", f.title)
        add(&L, "Validation", f.validatedAt)
        add(&L, "Contexte", f.local)
        add(&L, "État", f.status == .draft ? "brouillon" : "validée")
        let lists: [(Role, String)] = [(.entry, "Confirmation"), (.watch, "À vérifier"), (.do, "Ne pas oublier"),
                                       (.ddx, "Différentiels"), (.dose, "Posologie")]
        for (role, lbl) in lists {
            for it in Pool.list(f, role) { add(&L, lbl, it.legacyString) }
        }
        for s in f.sources { add(&L, "Références", s) }
        for b in f.blocks {
            let t = b.title.isEmpty ? (b.kind == .decision ? "Décision" : "Étapes") : b.title
            if b.kind == .decision {
                add(&L, "Bloc « " + t + " »", b.question)
                for o in b.options { add(&L, "Bloc « " + t + " » — option", o.label) }
            } else {
                for it in Pool.blockItems(f, b) { add(&L, "Bloc « " + t + " »", it.legacyString) }
            }
        }
        for t in f.timers { add(&L, "Minuteur", t.label + (t.type == .interval ? " (\(t.seconds) s)" : " (chrono)")) }
        for c in f.counters { add(&L, "Compteur", c.label) }
        return L
    }
    /// `flattenProto(p)`.
    static func reference(_ p: Reference) -> [String] {
        var L: [String] = []
        add(&L, "Titre", p.title)
        add(&L, "Validation", p.validatedAt)
        add(&L, "État", p.status == .draft ? "brouillon" : "validée")
        for l in p.body.components(separatedBy: "\n") { add(&L, "Corps", l) }
        for s in p.sources { add(&L, "Références", s) }
        return L
    }
    /// Différence d'ensembles, ordre de lecture conservé : (dans `b` et pas dans `a`, dans `a` et pas dans `b`).
    static func diff(_ a: [String], _ b: [String]) -> (plus: [String], minus: [String]) {
        let sa = Set(a), sb = Set(b)
        return (b.filter { !sa.contains($0) }, a.filter { !sb.contains($0) })
    }
}

/// Rendu d'une différence : titres, lignes « + » (vert) et « − » (rouge), note de pied.
struct AcctDiffView: View {
    var plusTitle: String
    var minusTitle: String
    var plus: [String]
    var minus: [String]
    var note: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !plus.isEmpty {
                Text(plusTitle).aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                ForEach(Array(plus.enumerated()), id: \.offset) { _, l in
                    Text(verbatim: "+ " + l).aFont(TypeScale.meta, .medium).foregroundStyle(T.ok)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Ajout : " + l)
                }
            }
            if !minus.isEmpty {
                Text(minusTitle).aFont(TypeScale.body, .bold).foregroundStyle(T.ink).padding(.top, plus.isEmpty ? 0 : 6)
                ForEach(Array(minus.enumerated()), id: \.offset) { _, l in
                    Text(verbatim: "− " + l).aFont(TypeScale.meta, .medium).foregroundStyle(T.crit)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Suppression : " + l)
                }
            }
            Text(note).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
    }
}

// MARK: - Statut d'une entité (`statusLbl`)

/// « ○ Brouillon », « △ À relire », « ✓ Validé(e) » — achromatique (la couleur reste au danger).
func acctStatusLabel(_ s: Status, feminine: Bool) -> String {
    switch s {
    case .draft: return "○ Brouillon"
    case .review: return "△ À relire"
    case .validated: return "✓ Validé" + (feminine ? "e" : "")
    }
}

/// Comparaison de noms « à la française », sans casse ni accents (`localeCompare(fr, base)`).
func acctNameLess(_ a: String, _ b: String) -> Bool {
    a.compare(b, options: [.caseInsensitive, .diacriticInsensitive], range: nil, locale: Locale(identifier: "fr_FR")) == .orderedAscending
}

// MARK: - Message d'erreur réseau (`e.message`)

/// Le message d'une erreur tel que la PWA l'affiche après « Échec : » (`e.message`).
func acctErrorMessage(_ e: Error) -> String {
    (e as? CloudError)?.message ?? String(describing: e)
}

/// E-mail plausible (`!email || email.indexOf('@') < 1` → invalide).
func acctEmailLooksValid(_ s: String) -> Bool {
    guard let at = s.firstIndex(of: "@") else { return false }
    return s.distance(from: s.startIndex, to: at) >= 1
}
