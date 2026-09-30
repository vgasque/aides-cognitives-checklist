import SwiftUI
import AidesCore

// CAPTURES D'ÉCRAN (CI) — `-ac-demo <écran>` en argument de lancement pose l'app dans un état
// connu pour la photographier dans le simulateur (`xcrun simctl launch … -ac-demo session`).
// Inerte sans cet argument : aucune donnée n'est touchée en usage normal.
//
// Écrans : home · search · fiche · session · sessions · me · edit · reference.
extension AppModel {
    func applyDemoIfAsked() {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-ac-demo"), i + 1 < args.count else { return }
        let screen = args[i + 1]
        if fiches.isEmpty { addExamples() }
        finishOnboarding()
        paths = [:]
        rootTab = .aides
        guard let f = fiches.first(where: { $0.deletedAt == nil }) else { return }
        switch screen {
        case "search":
            rootTab = .search
            home.q = "choc"
        case "sessions":
            rootTab = .sessions
        case "me":
            rootTab = .me
        case "fiche":
            if let R = engine.live[f.id] { endSession(R) }
            openFiche(f.id)
        case "session":
            openFiche(f.id)
            guard let R = current, R.ficheId == f.id else { return }
            if !R.started, let b = R.nav.first ?? f.blocks.first?.id {
                act(R) { e, R in _ = e.toggleStep(R, "1:\(b):0") }
                act(R) { e, R in _ = e.toggleStep(R, "1:\(b):1") }
            }
        case "edit":
            path = [.editFiche(f.id)]
        case "reference":
            if let p = references.first { openReference(p.id) }
        default:
            break
        }
    }
}
