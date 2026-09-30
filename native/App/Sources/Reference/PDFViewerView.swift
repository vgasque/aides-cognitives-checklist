import SwiftUI
import AidesCore

/// PROVISOIRE — remplacé par l'implémentation de la zone « Document ».
struct PDFViewerView: View {
    let attachmentId: String
    let name: String
    var body: some View {
        Text("Document").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink)
    }
}
