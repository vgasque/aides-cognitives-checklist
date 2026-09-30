import SwiftUI
import AidesCore

// LES FENÊTRES DE L'ACCUEIL — une seule présentée à la fois (`.sheet(item:)`). Les vues des
// AUTRES zones (Compte, Créer, Catégories, Compte-rendu, Rejoindre) sont seulement présentées ici.

struct HomeSheetHost: View {
    let sheet: HomeSheet
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheetBinding: HomeSheet?
    let exporter: HomeExportJob

    var body: some View {
        switch sheet {
        case .display:
            HomeDisplaySheet(st: st, corpus: corpus, sheet: $sheetBinding)
                .presentationDetents([.medium, .large])
        case .create:
            CreateView()
        case .account:
            AccountView()
        case .sessions:
            SessionsHistoryView(ficheId: nil, embedded: false)
        case .join:
            JoinSessionView()
        case .syncError:
            HomeSyncErrorSheet()
                .presentationDetents([.medium])
        case .catMgr(let scope):
            CategoryManagerView(scope: scope)
        case .report(let id):
            ReportView(sessionId: id)
        case .endSession(let fid):
            HomeEndSessionSheet(ficheId: fid)
                .presentationDetents([.medium])
        case .selActions:
            HomeSelActionsSheet(st: st, corpus: corpus, sheet: $sheetBinding, exporter: exporter)
        case .selMoveLib:
            HomeSelMoveLibSheet(st: st, corpus: corpus, sheet: $sheetBinding)
        case .selCategory:
            HomeSelCategorySheet(st: st, corpus: corpus, sheet: $sheetBinding)
        case .selDelete:
            HomeSelDeleteSheet(st: st, corpus: corpus, sheet: $sheetBinding)
        }
    }
}

/// « Terminer la session ? » depuis la carte « Session en cours » de l'accueil (`confirmEndSession`,
/// B2 §17) : la confirmation se MAINTIENT 1,2 s ; « Poursuivre » est le geste sûr.
struct HomeEndSessionSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let ficheId: String

    var body: some View {
        if let R = model.engine.live[ficheId], R.started {
            content(R)
        } else {
            Color.clear.onAppear { dismiss() }
        }
    }

    private func content(_ R: RuntimeSession) -> some View {
        let title = R.fiche.title.isEmpty ? "Aide cognitive" : R.fiche.title
        let dur = Fmt.ms(JS.now() - R.startedAt)
        let open = model.engine.openAtEnd(R)
        return VStack(alignment: .leading, spacing: 14) {
            Text(R.exercise ? "Terminer l’exercice ?" : "Terminer la session ?")
                .aFont(TypeScale.step, .heavy).foregroundStyle(T.ink)
                .accessibilityAddTraits(.isHeader)
            ((R.exercise ? Text("▲ Exercice").bold() + Text(" — ") : Text(""))
             + Text(verbatim: title + " — durée ") + Text(verbatim: dur).bold())
                .aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
            if open.crit > 0 || open.running > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    if open.crit > 0 {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            RegisterTag(level: 3)
                            Text(verbatim: "\(open.crit)" + (open.crit > 1 ? " étapes vitales non cochées" : " étape vitale non cochée") + (open.`where`.isEmpty ? "" : " — " + open.`where`))
                                .aFont(TypeScale.body, .semibold).foregroundStyle(T.crit)
                        }
                    }
                    if open.running > 0 {
                        Text(verbatim: "⏱ \(open.running)" + (open.running > 1 ? " minuteurs en cours" : " minuteur en cours"))
                            .aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.line))
            }
            Text("Le chrono global et tous les minuteurs s'arrêtent. La session quitte l'accueil. Le déroulé horodaté reste consultable dans l'historique.")
                .aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
            HStack(spacing: 10) {
                Button("Poursuivre") { dismiss() }.buttonStyle(.a(.secondary, Ctrl.l, full: true))
                HoldButton(label: "Terminer", ms: 1200, kind: .danger, height: Ctrl.l) {
                    model.endSession(R)
                    dismiss()
                }
            }
            Text("Maintenir 1,2 s. Relâcher annule.").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
        }
        .padding(20)
        .background(T.work.ignoresSafeArea())
    }
}

/// « Erreur de synchronisation » (C1 §12.2) : titre et détail de `explainSyncError`, heure du
/// dernier échec, « Réessayer maintenant ».
struct HomeSyncErrorSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let info = model.sync.lastError ?? SyncErrorInfo.unknownFallback
        let at = model.sync.lastErrorAt
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Erreur de synchronisation").aFont(TypeScale.step, .heavy).foregroundStyle(T.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).frame(width: Ctrl.m, height: Ctrl.m)
                }
                .buttonStyle(.plain).foregroundStyle(T.ink2)
                .accessibilityLabel("Fermer")
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(T.warn).accessibilityHidden(true)
                Text(info.title).aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
            }
            Text(info.detail).aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
            if at > 0 {
                Text(verbatim: "Dernier échec : " + hhmm(at) + (model.sync.retryPending ? " · nouvelle tentative automatique en cours" : ""))
                    .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
            }
            Button("Réessayer maintenant") {
                dismiss()
                Task { await model.sync.full() }
            }
            .buttonStyle(.a(.primary, Ctrl.m))
        }
        .padding(20)
        .background(T.work.ignoresSafeArea())
    }
}
