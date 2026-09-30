import SwiftUI
import AidesCore

/// PROVISOIRE — remplacé par l'implémentation de la zone « Éditeur ».
struct FicheEditorView: View {
    let ficheId: String
    var body: some View {
        Text("Éditeur").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink)
    }
}
