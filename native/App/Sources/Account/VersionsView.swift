import SwiftUI
import AidesCore

// VERSIONS PRÉCÉDENTES — port d'`openVersions`, `renderVersions`, `diffFiches` (réversibilité).
// Sauvegardes LOCALES d'une aide (5 au plus) : à l'ouverture de l'éditeur, avant qu'une version
// venue d'ailleurs ne remplace la vôtre (synchro), avant une restauration. « Comparer » aplatit
// les deux versions en lignes « Section · contenu » et en montre la différence d'ensembles ;
// « Restaurer » sauvegarde d'abord la version actuelle, puis la remplace (elle part à la synchro).

struct VersionsView: View {
    var ficheId: String

    init(ficheId: String) { self.ficheId = ficheId }

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var backups: [Backup] = []
    @State private var open: Set<String> = []
    @State private var confirm: AcctConfirm?

    private var fiche: Fiche? { model.fiches.first { $0.id == ficheId } }
    /// En bibliothèque partagée, ces sauvegardes ne sont QUE vos versions écrasées par un coéquipier.
    private var shared: Bool { fiche?.library != nil }

    var body: some View {
        AcctWindow(title: shared ? "Récupérer ma version écrasée" : "Versions précédentes", maxWidth: 720, onClose: { dismiss() }) {
            if backups.isEmpty {
                Text("Aucune version précédente conservée pour cette fiche.")
                    .aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
            } else {
                WorkCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(backups.enumerated()), id: \.element.bid) { i, b in
                            if i > 0 { Divider().overlay(T.line) }
                            row(b)
                        }
                    }
                }
            }
            Text(shared
                 ? "Vos versions écrasées par une modification d’un coéquipier (dernière écriture appliquée). Sauvegardes locales à cet appareil — ce n’est pas l’historique partagé de l’équipe. Restaurer remplace la fiche actuelle par la version choisie."
                 : "Sauvegardes locales créées avant qu’une version venue d’un autre appareil ne remplace la vôtre. Restaurer remplace la fiche actuelle par la version choisie.")
                .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .acctConfirm($confirm)
        .onAppear { backups = model.library.backups(of: ficheId) }
    }

    /// Date « fr-FR » (`toLocaleString('fr-FR')` : 30/09/2026 14:05:03).
    private func stamp(_ ms: Double) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return f.string(from: Date(timeIntervalSince1970: ms / 1000))
    }

    @ViewBuilder
    private func row(_ b: Backup) -> some View {
        let isOpen = open.contains(b.bid)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(stamp(b.at)).aFont(TypeScale.item, .semibold, .mono).foregroundStyle(T.ink)
                Spacer(minLength: 6)
                Button(isOpen ? "Masquer" : "Comparer") {
                    if isOpen { open.remove(b.bid) } else { open.insert(b.bid) }
                }
                .buttonStyle(.a(.secondary, Ctrl.s))
                .accessibilityValue(isOpen ? "déplié" : "replié")
                Button("Restaurer") { askRestore(b) }
                    .buttonStyle(.a(.primary, Ctrl.s))
            }
            .frame(minHeight: Ctrl.row)
            if isOpen { diff(b) }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, isOpen ? 12 : 0)
    }

    /// `diffFiches(cur, old)` : « rétablirait » = dans l'ancienne et pas dans l'actuelle.
    @ViewBuilder
    private func diff(_ b: Backup) -> some View {
        if let cur = fiche, let old = backupFiche(b) {
            let d = AcctFlatten.diff(AcctFlatten.fiche(cur), AcctFlatten.fiche(old))
            if d.plus.isEmpty && d.minus.isEmpty {
                Text("Aucune différence de contenu (les images ne sont pas comparées).")
                    .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
            } else {
                AcctDiffView(plusTitle: "Restaurer rétablirait :", minusTitle: "Restaurer supprimerait :",
                             plus: d.plus, minus: d.minus,
                             note: "Images non comparées. La version actuelle est sauvegardée avant toute restauration.")
            }
        } else {
            Text("Version illisible.").aFont(TypeScale.meta, .bold).foregroundStyle(T.crit)
        }
    }

    /// Relecture d'une sauvegarde : `migrate(Object.assign({}, b.data, {id: ficheId}))`.
    private func backupFiche(_ b: Backup) -> Fiche? {
        guard var o = b.data.object else { return nil }
        o["id"] = .string(b.ficheId)
        return Sanitize.fiche(.object(o))
    }

    private func askRestore(_ b: Backup) {
        confirm = AcctConfirm(message: "Restaurer cette version ? La fiche actuelle sera remplacée (et sauvegardée à son tour).",
                              yes: "Restaurer") { r in
            guard case .yes = r else { return }
            // Le cœur sauvegarde la version actuelle d'abord, puis persiste la restaurée (migrate).
            if model.library.restore(b) != nil {
                model.refresh()
                dismiss()
            } else {
                model.toast("⚠ Fiche introuvable.")
            }
        }
    }
}
