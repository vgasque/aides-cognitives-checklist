import SwiftUI
import AidesCore

/// PROVISOIRE — remplacé par l'implémentation de la zone « Aide ».
struct ReadFicheView: View {
    let ficheId: String
    var body: some View {
        Text("Aide").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink)
    }
}
