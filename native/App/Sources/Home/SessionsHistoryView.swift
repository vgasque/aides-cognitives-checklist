import SwiftUI
import AidesCore

// HISTORIQUE DES SESSIONS — port de `renderSessHist` (C1 §3.13, B1 §25).
// Deux présentations, un seul rendu (A365) : VUE de la colonne principale ≥ 780 (`embedded`),
// page-fenêtre partout ailleurs. Mode global (toutes les aides) ou par aide (`ficheId`, depuis le
// menu ⋯ « Historique des sessions (n) » — la session du runtime affiché en est exclue).
// EXERCICES À PART (v4.27.0) : les répétitions ne se mêlent jamais aux sessions cliniques.

struct SessionsHistoryView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var ficheId: String? = nil
    var embedded: Bool = false

    @State private var reportId: HomeReportRef?
    @State private var joinOpen = false
    @State private var toDelete: JSON?

    var body: some View {
        Group {
            if embedded {
                content
            } else {
                // Feuille (iOS 27) : titre système, ✕ en `.cancellationAction`, détentes.
                NavigationStack {
                    ScrollView {
                        content.padding(.horizontal, 20).padding(.bottom, 24)
                    }
                    .navigationTitle("Sessions")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button { dismiss() } label: { Image(systemName: "xmark") }
                                .accessibilityLabel("Fermer")
                                .keyboardShortcut(.cancelAction)
                        }
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .background(T.amb.ignoresSafeArea())
            }
        }
        .sheet(item: $reportId) { r in ReportView(sessionId: r.id) }
        .sheet(isPresented: $joinOpen) { JoinSessionView() }
        .confirmationDialog("Supprimer cette session ?", isPresented: Binding(get: { toDelete != nil }, set: { if !$0 { toDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                if let id = toDelete?["id"]?.string { model.deleteSession(id) }
                toDelete = nil
            }
            Button("Annuler", role: .cancel) { toDelete = nil }
        }
    }

    private var glob: Bool { ficheId == nil }

    /// Sessions de la vue : vives d'abord, puis par `savedAt` décroissant.
    private var rows: [JSON] {
        let curSid = model.current?.sessionId
        return model.sessions
            .filter { s in glob || (s["ficheId"]?.string == ficheId && s["id"]?.string != curSid) }
            .enumerated()
            .sorted { a, b in
                let la = a.element["live"]?.truthy ?? false, lb = b.element["live"]?.truthy ?? false
                if la != lb { return la }
                let sa = a.element["savedAt"]?.number ?? 0, sb = b.element["savedAt"]?.number ?? 0
                return sa != sb ? sa > sb : a.offset < b.offset
            }
            .map(\.element)
    }

    @ViewBuilder
    private var content: some View {
        let ss = rows
        VStack(alignment: .leading, spacing: 10) {
            if glob && model.engine.live.isEmpty {
                Button { joinOpen = true } label: {
                    HStack(spacing: 10) {
                        Text(verbatim: "⇄").aFont(TypeScale.stepL, .bold).foregroundStyle(T.act).accessibilityHidden(true)
                        Text("Rejoindre une session en cours").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                        Spacer()
                        Image(systemName: "chevron.right").aFont(TypeScale.body, .bold).foregroundStyle(T.ink3)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: Ctrl.row)
                    .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.workLine))
                }
                .buttonStyle(.plain)
            }
            if ss.isEmpty {
                Text(glob ? "Aucune session archivée." : "Aucune session archivée pour cette fiche.")
                    .aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                    .padding(.vertical, 12)
            } else {
                let clin = ss.filter { !($0["exercise"]?.truthy ?? false) }
                let exo = ss.filter { $0["exercise"]?.truthy ?? false }
                if !clin.isEmpty {
                    groupTitle("Sessions cliniques (\(clin.count))")
                    ForEach(clin, id: \.self) { s in row(s) }
                }
                if !exo.isEmpty {
                    groupTitle("Exercices (\(exo.count))")
                    ForEach(exo, id: \.self) { s in row(s) }
                }
            }
        }
    }

    private func groupTitle(_ t: String) -> some View {
        Text(t).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2).textCase(.uppercase)
            .padding(.top, 10)
            .accessibilityAddTraits(.isHeader)
    }

    /// Durée et étapes cochées (`det`).
    private func detail(_ s: JSON) -> String {
        let saved = s["savedAt"]?.number ?? JS.now()
        let started = s["startedAt"]?.number ?? saved
        let d = Fmt.ms(max(0, saved - (started == 0 ? saved : started)))
        let n = (s["checked"]?.object ?? [:]).values.filter(\.truthy).count
        return "Durée " + d + (n > 0 ? " · \(n) étape" + either(n > 1, "s", "") + " cochée" + either(n > 1, "s", "") : "")
    }

    private func row(_ s: JSON) -> some View {
        let live = s["live"]?.truthy ?? false
        let exo = s["exercise"]?.truthy ?? false
        let name = s["name"]?.string ?? ""
        let ft = s["ficheTitle"]?.string ?? ""
        let saved = s["savedAt"]?.number ?? 0
        let line2 = (glob && !ft.isEmpty && !name.contains(ft) ? ft + " · " : "") + Fmt.sessStamp(saved)
        return WorkCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle().fill(live ? T.ok : T.ink3).frame(width: 8, height: 8).accessibilityHidden(true)
                    Text(live ? "En cours" : "Terminée").aFont(TypeScale.meta, .bold).foregroundStyle(live ? T.ok : T.ink2)
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if exo {
                        Text("▲ EXERCICE").aFont(TypeScale.cap, .heavy).foregroundStyle(T.act)
                    }
                    Text(name.isEmpty ? "Session" : name).aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                        .lineLimit(2)
                    if live {
                        Text("en cours").aFont(TypeScale.cap, .heavy).foregroundStyle(T.ok)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(T.okSoft, in: Capsule())
                    }
                }
                Text(verbatim: line2).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                Text(verbatim: detail(s)).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                HStack(spacing: 8) {
                    if live {
                        Button("Reprendre") { resume(s) }.buttonStyle(.a(.primary, Ctrl.m))
                    } else {
                        Button("Rouvrir") { resume(s) }.buttonStyle(.a(.secondary, Ctrl.m))
                            .help("Rouvre la session là où elle en était (étapes cochées, minuteurs, compteurs)")
                        Button("Compte-rendu") {
                            if let id = s["id"]?.string { reportId = HomeReportRef(id: id) }
                        }
                        .buttonStyle(.a(.secondary, Ctrl.m))
                        .help("Compte-rendu imprimable")
                        Spacer()
                        Button { toDelete = s } label: {
                            Image(systemName: "xmark").aFont(TypeScale.body, .bold).frame(width: Ctrl.m, height: Ctrl.m)
                        }
                        .buttonStyle(.plain).foregroundStyle(T.ink2)
                        .accessibilityLabel("Supprimer la session « " + name + " »")
                        .help("Supprimer la session (confirmation demandée)")
                    }
                }
            }
        }
    }

    private func resume(_ s: JSON) {
        if !embedded { dismiss() }
        model.resumeSession(s)
    }
}

/// Identifiant de session présentable en feuille.
struct HomeReportRef: Identifiable, Hashable { let id: String }
