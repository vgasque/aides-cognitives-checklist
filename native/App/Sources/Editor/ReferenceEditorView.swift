import SwiftUI
import AidesCore

/// PROVISOIRE — remplacé par l'implémentation de la zone « Éditeur de référence ».
struct ReferenceEditorView: View {
    let referenceId: String
    var body: some View {
        Text("Éditeur de référence").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink)
    }
}
