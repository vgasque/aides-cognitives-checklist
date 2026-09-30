import SwiftUI
import AidesCore

// ⚠ PROVISOIRE, À SUPPRIMER À LA FUSION ⚠
// Vues écrites par d'AUTRES zones (Compte, Créer, Catégories, Compte-rendu, Partage). L'accueil
// ne fait que les PRÉSENTER ; ces coquilles vides n'existent que pour que l'app compile avant
// que leurs auteurs livrent. Mêmes noms, mêmes initialiseurs que les vraies.

struct AccountView: View {
    var body: some View { Text("Compte & synchronisation").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink).padding() }
}

struct CreateView: View {
    var body: some View { Text("Créer").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink).padding() }
}

struct CategoryManagerView: View {
    var scope: String?
    var body: some View { Text("Catégories").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink).padding() }
}

struct JoinSessionView: View {
    var body: some View { Text("Rejoindre une session").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink).padding() }
}
