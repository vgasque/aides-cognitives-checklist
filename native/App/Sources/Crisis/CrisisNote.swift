import SwiftUI
import AidesCore

// NOTE PERSONNELLE D'UNE AIDE (`noteBlockHtml` / `bindNoteBlock`, C1 §14) — privée, jamais dans la
// fiche, jamais exportée ni partagée ; synchronisée seulement entre les appareils du même compte.
// Pendant une session vive sur l'aide, elle est EN LECTURE SEULE (on annote la session par le journal).

struct CrNoteBlock: View {
    let ficheId: String
    let locked: Bool
    @Environment(AppModel.self) private var model
    @State private var editing = false
    @State private var text = ""
    @State private var status = ""
    @State private var saveTask: Task<Void, Never>?
    @FocusState private var focused: Bool

    var body: some View {
        let note = model.library.note(ficheId)
        VStack(alignment: .leading, spacing: 8) {
            if locked {
                if !note.isEmpty {
                    header(note: note)
                    Text(note).aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
                    Text("Note de la fiche, non modifiable pendant la session — pour annoter la session, utilisez le journal des actions.")
                        .aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
                }
            } else if note.isEmpty && !editing {
                Button { startEdit(note) } label: {
                    Label("Ajouter une note personnelle", systemImage: "square.and.pencil")
                        .aFont(TypeScale.body, .bold)
                        .frame(minHeight: Ctrl.l)
                }
                .buttonStyle(.a(.quiet, Ctrl.l))
            } else {
                header(note: note)
                if editing {
                    TextField("Vos notes sur cette fiche.", text: $text, axis: .vertical)
                        .lineLimit(3...12)
                        .textFieldStyle(.plain)
                        .aFont(16, .regular)  // design: champ tactile, plancher 16 (règle 9, exemption de check-type)
                        .foregroundStyle(T.ink)
                        .padding(12)
                        .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
                        .focused($focused)
                        .onChange(of: text) { _, _ in schedule() }
                        .onChange(of: focused) { _, f in if !f { save() } }
                        .accessibilityLabel("Notes personnelles")
                    Text(status.isEmpty ? "Jamais partagée : visible par vous seulement." : status)
                        .aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
                } else {
                    Text(note).aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .onDisappear { if editing { save() } }
    }

    @ViewBuilder
    private func header(note: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil").foregroundStyle(T.ink2).accessibilityHidden(true)
            Text("Notes personnelles").aFont(TypeScale.item, .bold).foregroundStyle(T.ink).accessibilityAddTraits(.isHeader)
            Spacer()
            if locked {
                Button("Modifier") {}
                    .buttonStyle(.a(.secondary, Ctrl.s))
                    .disabled(true)
                    .help("Non modifiable pendant une session en cours")
                    .accessibilityHint("Non modifiable pendant une session en cours")
            } else if editing {
                Button("Terminer") { save(); editing = false }
                    .buttonStyle(.a(.primary, Ctrl.s))
            } else {
                Button("Modifier") { startEdit(note) }
                    .buttonStyle(.a(.secondary, Ctrl.s))
            }
        }
    }

    private func startEdit(_ note: String) {
        text = note
        status = ""
        editing = true
        focused = true
    }
    /// Enregistrement 700 ms après la dernière frappe (et à la sortie du champ).
    private func schedule() {
        status = "Enregistrement…"
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            save()
        }
    }
    private func save() {
        saveTask?.cancel()
        guard text != model.library.note(ficheId) else { return }
        model.saveNote(ficheId, JS.prefix(text, 10_000))
        status = JS.trim(text).isEmpty ? "" : "Enregistrée à l’instant"
    }
}
