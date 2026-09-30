import SwiftUI
import AidesCore

// ⚠ PROVISOIRE, À SUPPRIMER À LA FUSION ⚠
// Vues écrites par une AUTRE zone (le parcours « Se repérer », la Page, le Schéma). Le mode crise
// ne fait que les PRÉSENTER (menu ⋯, carte « Parcours », « Tout voir ») ; ces coquilles n'existent
// que pour que l'app compile avant leur livraison. Mêmes noms, mêmes initialiseurs que les vraies.

struct ParcoursSheetView: View {
    let ficheId: String
    var body: some View { Text("Se repérer").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink).padding() }
}

struct PageView: View {
    let ficheId: String
    var body: some View { Text("Page").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink).padding() }
}

struct SchemaView: View {
    let ficheId: String
    var body: some View { Text("Schéma").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink).padding() }
}
