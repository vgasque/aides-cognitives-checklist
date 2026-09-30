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
        if references.isEmpty { addDemoReference() }
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
            // Une session vive ferait d'abord demander « Terminer la session et modifier ? ».
            if let R = engine.live[f.id] { endSession(R) }
            path = [.editFiche(f.id)]
        case "reference":
            if let p = references.first { openReference(p.id) }
        default:
            break
        }
    }

    /// Une référence d'exemple (les exemples livrés ne sont que des aides).
    private func addDemoReference() {
        var p = Reference(id: Guard.uid("p"))
        p.title = "Anaphylaxie — repères de l'adulte"
        p.category = categories.first { $0.name == "Urgences" }?.id ?? categories.first?.id ?? ""
        p.status = .draft
        p.body = """
        # Reconnaître
        Atteinte **cutanéo-muqueuse** brutale associée à une atteinte respiratoire, circulatoire ou digestive.

        > [!ALERTE] L'adrénaline IM ne se diffère pas.

        # Traiter
        ## Adrénaline IM
        - Face antérolatérale de cuisse
        - Répéter toutes les **5 min** si besoin
        - [ ] Dose tracée sur la feuille

        ## Remplissage
        | Situation | Volume |
        |:--|--:|
        | Hypotension | 20 mL/kg |
        | Persistance | à répéter |

        # Surveiller
        Réaction biphasique possible : ==surveillance prolongée==.
        """
        _ = save(p)
        refresh()
    }
}
