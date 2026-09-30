import SwiftUI
import AidesCore

// PROVISOIRE — vues que d'autres zones fourniront (lecture de crise, schéma, rendu Markdown).
// L'éditeur ne fait que les RÉFÉRENCER ; elles seront remplacées sans toucher à l'éditeur.

/// PROVISOIRE — « ▶ Essayer » (`openDraftPreview`) : dérouler le brouillon comme en session, dans
/// un Runtime d'ESSAI (`engine.trialRuntime`) — minuteurs et compteurs tournent, RIEN n'est
/// enregistré, les sessions vives ne sont pas touchées. À remplacer par la lecture de crise hébergée.
struct TrialPreviewView: View {
    let draft: Fiche
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var runtime: RuntimeSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Essai — rien n’est enregistré").aFont(TypeScale.meta, .bold).foregroundStyle(T.warn)
                    Text(draft.title.isEmpty ? "Nouvelle fiche" : draft.title).aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink)
                    ForEach(draft.blocks.filter { $0.kind != .review }) { b in
                        WorkCard(padding: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(b.title.isEmpty ? (b.kind == .decision ? "Décision" : "Sans titre") : b.title)
                                    .aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                                if b.kind == .decision {
                                    Text(b.question).aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                                } else {
                                    ForEach(Pool.blockItems(draft, b)) { it in
                                        BoldText(text: "☐ " + it.do + (it.expect.isEmpty ? "" : " :: " + it.expect), size: TypeScale.body)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(T.amb)
            .navigationTitle("■ Aperçu")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Retour à l’édition")
                }
            }
        }
        .onAppear { if runtime == nil { runtime = model.engine.trialRuntime(draft) } }
    }
}

/// PROVISOIRE — aperçu d'une RÉFÉRENCE en brouillon (`openPDraftPreview`, badge « Mode aperçu »).
struct ReferenceTrialPreviewView: View {
    let draft: Reference
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mode aperçu").aFont(TypeScale.meta, .bold).foregroundStyle(T.warn)
                    Text(draft.title.isEmpty ? "Nouveau protocole" : draft.title).aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink)
                    EditorMarkdownPreview(markdown: draft.body, images: draft.images)
                }
                .padding(16)
            }
            .background(T.amb)
            .navigationTitle("■ Aperçu")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Retour à l’édition")
                }
            }
        }
    }
}

/// PROVISOIRE — « Algorithme — aperçu automatique » (`flowBlock`, schéma SVG §23) : ici un plan
/// textuel des blocs et de leurs suites, en attendant le schéma natif.
struct EditorFlowPreview: View {
    let fiche: Fiche
    var body: some View {
        let flow = fiche.blocks.filter { $0.kind != .review }
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(flow.enumerated()), id: \.element.id) { i, b in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(b.kind == .decision ? "◆" : "\(i + 1)").aFont(TypeScale.meta, .bold, .mono).foregroundStyle(T.ink2).frame(width: 20)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(b.title.isEmpty ? (b.kind == .decision ? "Décision" : "Sans titre") : b.title)
                            .aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink)
                        Text(next(b)).aFont(TypeScale.cap, .regular).foregroundStyle(T.ink2)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
    private func name(_ id: String?) -> String {
        guard let id, let b = fiche.blocks.first(where: { $0.id == id }) else { return "Fin" }
        return b.title.isEmpty ? "Sans titre" : b.title
    }
    private func next(_ b: Block) -> String {
        if b.kind == .decision {
            return b.options.map { ($0.label.isEmpty ? "—" : $0.label) + " → " + name($0.target) }.joined(separator: " · ")
        }
        return "→ " + name(b.next)
    }
}

/// PROVISOIRE — rendu du mini-Markdown (`mdRender`) : la zone « Référence » fournira le vrai rendu
/// (titres repliables, tableaux, encadrés typés, listes cochables, images `img:ID`).
struct EditorMarkdownPreview: View {
    let markdown: String
    let images: [ImageRef]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(markdown.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                Text(render(line)).aFont(line.hasPrefix("#") ? TypeScale.item : TypeScale.body, line.hasPrefix("#") ? .bold : .regular)
                    .foregroundStyle(T.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private func render(_ line: String) -> AttributedString {
        var l = line
        while l.hasPrefix("#") { l.removeFirst() }
        let t = JS.trim(l)
        return (try? AttributedString(markdown: t, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(t)
    }
}
