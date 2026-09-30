// swift-tools-version:5.9
// AidesCore — le cœur métier de l'application native, SANS interface : modèle, assainissement
// (migrate / sanitizeCats), stockage local, import/export (JSON v4 + .zip), moteur de session
// (minuteurs, compteurs, coches, parcours), clients Supabase (compte, synchro, partage).
// Il ne dépend que de Foundation : il compile et se TESTE aussi sous Linux (`swift test`),
// ce qui permet de vérifier la logique hors de Xcode.
import PackageDescription

let package = Package(
    name: "AidesCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AidesCore", targets: ["AidesCore"])],
    targets: [
        .target(name: "AidesCore"),
        .testTarget(name: "AidesCoreTests", dependencies: ["AidesCore"],
                    resources: [.copy("Fixtures")]),
    ]
)
