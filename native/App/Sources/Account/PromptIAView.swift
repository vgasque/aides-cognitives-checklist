import SwiftUI
import UniformTypeIdentifiers
import AidesCore

// « RÉDIGER AVEC L'IA À PARTIR D'UN DOCUMENT » — port de `renderCreateDlg('ia')` (page poussée de
// la fenêtre « Créer », ou fenêtre autonome).
// Le prompt est le CONTRAT du format JSON que l'importeur lit : il est livré À L'OCTET près
// (`prompt-ia.txt`, extrait par programme de la constante `AI_PROMPT` d'index.html — 552 lignes,
// 40 020 caractères). Aucun réglage : copier, puis importer ce que l'IA a rendu. L'aide importée
// par cette porte s'ouvre à la fin (`pendingOpenImport`).

enum PromptIA {
    /// Le texte de `AI_PROMPT`, tel quel (ressource embarquée : fonctionne hors ligne).
    static let text: String = {
        guard let url = Bundle.main.url(forResource: "prompt-ia", withExtension: "txt"),
              let data = try? Data(contentsOf: url) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }()
}

struct PromptIAView: View {
    /// true = page POUSSÉE dans la fenêtre « Créer » (retour système) ; false = fenêtre autonome (✕).
    var embedded: Bool
    /// Fichiers choisis : l'appelant les passe à l'atelier. Sans lui, la vue présente l'atelier.
    var onFiles: (([URL]) -> Void)?

    init(embedded: Bool = false, onFiles: (([URL]) -> Void)? = nil) {
        self.embedded = embedded
        self.onFiles = onFiles
    }

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var request: ImportRequest?

    var body: some View {
        AcctWindow(title: "Rédiger avec l'IA", maxWidth: 480, embedded: embedded, onClose: closeAction) {
            PromptIAContent(onFiles: handle)
        }
        .sheet(item: $request) { r in
            ImportWorkshopView(request: r) { last in
                request = nil
                dismiss()
                if let last {
                    let m = model
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 450_000_000)
                        m.openFiche(last)
                    }
                }
            }
        }
    }

    private var closeAction: (() -> Void)? {
        guard !embedded else { return nil }
        let d = dismiss
        return { d() }
    }

    private func handle(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        if let onFiles { onFiles(urls) } else { request = ImportRequest(urls: urls, openLast: true) }
    }
}

/// Le contenu de l'écran « ia » (sans coque de fenêtre).
struct PromptIAContent: View {
    var onFiles: ([URL]) -> Void
    @State private var copied = false
    @State private var copyTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("1 · Copiez ce prompt dans votre IA").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                .accessibilityAddTraits(.isHeader)
            BoldText(text: "Collez-le dans une IA (ChatGPT, Claude…) **en y joignant votre source** (PDF, capture d'écran, texte d'une recommandation) : elle renverra un fichier JSON.",
                     size: TypeScale.body, color: T.ink)
                .fixedSize(horizontal: false, vertical: true)
            ScrollView {
                Text(verbatim: PromptIA.text)
                    .aFont(TypeScale.meta, .regular, .mono)
                    .foregroundStyle(T.ink)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(height: 220)
            .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.line))
            .accessibilityLabel("Prompt IA")
            Button(copied ? "✓ Copié" : "Copier le prompt") { copy() }
                .buttonStyle(.a(copied ? .secondary : .primary, Ctrl.l))
                .accessibilityValue(copied ? "copié dans le presse-papiers" : "")
            Text("2 · Importez le fichier").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                .padding(.top, 6)
                .accessibilityAddTraits(.isHeader)
            ImportDropZone(title: "Importer le fichier généré", onFiles: onFiles)
            BoldText(text: "L'aide arrive en **○ Brouillon** : relisez et validez chaque posologie avant publication. Vous restez responsable du contenu.",
                     size: TypeScale.meta, color: T.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func copy() {
        acctCopyToClipboard(PromptIA.text)
        copied = true
        copyTask?.cancel()
        copyTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if !Task.isCancelled { copied = false }
        }
    }
}

/// Zone de dépôt « .json · .zip » : un tap ouvre le sélecteur (plusieurs fichiers à la fois), un
/// glisser-déposer (iPad, Mac) y dépose directement. La porte (`acceptFile('data')`) est tenue par
/// l'atelier, qui NOMME chaque refus.
struct ImportDropZone: View {
    var title: String
    var large = false
    var onFiles: ([URL]) -> Void
    @State private var picking = false
    @State private var targeted = false

    var body: some View {
        Button { picking = true } label: {
            VStack(spacing: 6) {
                Image(systemName: "square.and.arrow.down")
                    .aFont(large ? TypeScale.val : TypeScale.stepL, .semibold)
                    .foregroundStyle(T.act)
                Text(title).aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                Text(".json · .zip — glissez ici ou cliquez · plusieurs à la fois")
                    .aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, large ? 32 : 18)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(targeted ? T.primarySoft : T.work, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous)
                .strokeBorder(targeted ? T.act : T.ctlLine, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title + " — fichiers .json ou .zip")
        .fileImporter(isPresented: $picking, allowedContentTypes: ImportGate.accept, allowsMultipleSelection: true) { result in
            if case .success(let urls) = result, !urls.isEmpty { onFiles(urls) }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard !urls.isEmpty else { return false }
            onFiles(urls)
            return true
        } isTargeted: { targeted = $0 }
    }
}
