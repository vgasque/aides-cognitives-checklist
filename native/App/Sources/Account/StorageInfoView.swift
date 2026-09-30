import SwiftUI
import AidesCore

// « OÙ SONT ENREGISTRÉES VOS FICHES ? » — port de `storageExplainHtml` (fenêtre `#storageModal`,
// aussi repris dans « Pourquoi créer un compte ? ») et de la ligne de stockage du pied
// (`storageState`).
//
// ADAPTATION NATIVE (question ouverte C1 §21.1, tranchée ici) : pas de navigateur ni de service
// worker. Les textes qui parlaient du NAVIGATEUR disent l'APPLICATION (« si l'application est
// supprimée… ») ; « Réparer l'application » (purge des caches du service worker) n'a pas
// d'équivalent et devient « Relire les fiches de l'appareil » — relecture du stockage local,
// sans rien effacer. Tout le reste est repris verbatim.

/// Le texte d'explication (deux façons d'enregistrer), réutilisé par l'écran de connexion.
struct StorageExplainContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vos fiches peuvent être enregistrées de deux façons :")
                .aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
            WorkCard(padding: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Label { Text("Sur cet appareil (hors-ligne)").aFont(TypeScale.item, .bold) } icon: { Image(systemName: "iphone") }
                        .foregroundStyle(T.ink)
                    BoldText(text: "Gardées **uniquement dans la mémoire de ce téléphone/ordinateur**, comme des notes sur un seul carnet.",
                             size: TypeScale.body, color: T.ink)
                    Text("Elles vivent dans le dossier privé de l'application, inaccessible aux autres apps.")
                        .aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                    BoldText(text: "△ Si l'application est supprimée, ou si l'appareil est perdu, cassé, réinitialisé ou changé, **vos fiches sont perdues** — aucune autre copie.",
                             size: TypeScale.body, color: T.warn)
                    BoldText(text: "Sans compte, pensez à **exporter** régulièrement (bouton Compte → « Exporter mes données ») : un fichier de sauvegarde à garder ailleurs et à réimporter au besoin (dialogue Créer → « Importer un fichier (.json ou .zip) »).",
                             size: TypeScale.body, color: T.ink2)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            WorkCard(padding: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Label { Text("En ligne, avec un compte (synchronisation)").aFont(TypeScale.item, .bold) } icon: { Image(systemName: "icloud") }
                        .foregroundStyle(T.ink)
                    BoldText(text: "En vous connectant, une **copie de sécurité** est aussi gardée dans un **espace en ligne protégé** (le « cloud »).",
                             size: TypeScale.body, color: T.ink)
                    ForEach(["Appareil en panne ou perdu : **rien n'est perdu**.",
                             "Vous **retrouvez vos fiches sur n'importe quel appareil**.",
                             "Vous pouvez **partager** des bibliothèques avec votre équipe."], id: \.self) { b in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("•").aFont(TypeScale.body, .bold).foregroundStyle(T.ink2).accessibilityHidden(true)
                            BoldText(text: b, size: TypeScale.body, color: T.ink)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct StorageInfoView: View {
    /// « Créer un compte / se connecter » : l'appelant ouvre la fenêtre Compte après fermeture.
    var onSignIn: (() -> Void)?

    init(onSignIn: (() -> Void)? = nil) { self.onSignIn = onSignIn }

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var used: Double?
    @State private var reloaded = false

    var body: some View {
        AcctWindow(title: "Où sont enregistrées vos fiches ?", maxWidth: 720, onClose: { dismiss() }) {
            storageLine
            StorageExplainContent()
            if model.auth.signedIn {
                Text("✓ Vous êtes connecté : vos fiches sont sauvegardées en ligne.")
                    .aFont(TypeScale.body, .bold).foregroundStyle(T.ok)
            } else {
                Button("Créer un compte / se connecter") {
                    dismiss()
                    onSignIn?()
                }
                .buttonStyle(.a(.primary, Ctrl.l, full: true))
            }
            VStack(alignment: .leading, spacing: 6) {
                Button(reloaded ? "✓ Fiches relues" : "Relire les fiches de l'appareil") {
                    model.library.load()
                    model.refresh()
                    reloaded = true
                }
                .buttonStyle(.a(.secondary, Ctrl.s))
                Text("Relit les fiches, notes et sessions enregistrées sur cet appareil — utile si l'affichage semble ne pas suivre. Rien n'est effacé ni modifié.")
                    .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 6)
        }
        .task { used = await StorageUsage.bytes(of: model.store.base) }
    }

    /// `storageState` : « Cloud · x sur l'appareil » ou « Cet appareil seulement · x · copie unique »
    /// (le stockage d'une app n'est pas évincé comme celui d'un navigateur : toujours « copie unique »).
    private var storageLine: some View {
        let size = used.map { acctFmtBytes($0) } ?? "…"
        let offline = !model.sync.isOnline()
        let text = (model.auth.signedIn ? "**Cloud** · " + size + " sur l'appareil" : "**Cet appareil seulement** · " + size + " · copie unique")
            + (offline ? " · Hors ligne — tout fonctionne sur l’appareil" : "")
        return HStack(spacing: 8) {
            Image(systemName: model.auth.signedIn ? "icloud" : "iphone").foregroundStyle(T.ink2)
            BoldText(text: text, size: TypeScale.body, color: T.ink)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Octets occupés par les données de l'app sur l'appareil (tous espaces confondus).
enum StorageUsage {
    static func bytes(of url: URL) async -> Double {
        await Task.detached(priority: .utility) { scan(url) }.value
    }
    /// Parcours SYNCHRONE du dossier (l'itération d'un `NSEnumerator` n'a pas sa place dans un contexte asynchrone).
    static func scan(_ url: URL) -> Double {
        let fm = FileManager.default
        guard let e = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]) else { return 0 }
        var total: Double = 0
        while let f = e.nextObject() as? URL {
            let v = try? f.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            if v?.isRegularFile == true { total += Double(v?.fileSize ?? 0) }
        }
        return total
    }
}
