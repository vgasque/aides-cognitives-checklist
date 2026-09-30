import SwiftUI
import AidesCore

// Point d'entrée de l'application native (iPhone, iPad, Mac).
@main
struct AidesCognitivesApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Aides cognitives — \(Library.defaultCategories().count) catégories")
                .font(.title(TypeScale.stepL))
                .foregroundStyle(T.ink)
                .padding()
                .background(T.amb)
        }
    }
}
