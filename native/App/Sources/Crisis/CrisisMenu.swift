import SwiftUI
import AidesCore

// LE MENU ⋯ DE LA LECTURE (`setMoreMenu`, C1 §11.1 + B2 §16) — un `Menu` SYSTÈME de la barre
// d'outils. En session il NE RÉPÈTE PAS LE QUAI (A337) : ni complication (la touche ⚡ la porte),
// ni « Consulter ». « L'aide » se replie en sous-menu en session ; la rangée danger ferme le menu.

struct CrMoreMenu: View {
    let R: RuntimeSession
    let vs: CrisisViewState
    @Environment(AppModel.self) private var model

    var body: some View {
        let f = R.fiche
        let started = R.started
        let cxs = CrisisPure.cxAll(f)
        let hasFlow = CrisisPure.hasFlow(f)
        let act = CrAct(model: model, vs: vs, R: R)
        let nHist = model.sessions.filter { $0["ficheId"]?.string == f.id && $0["id"]?.string != R.sessionId }.count

        if !started && !cxs.isEmpty {
            if cxs.count == 1 {
                Button { act.cxGo(cxs[0]) } label: { row("Complication", "à tout moment", "bolt.fill") }
            } else {
                Menu {
                    ForEach(cxs, id: \.self) { c in
                        Button(HTML.stripBold(c.label) + (c.isBlock ? "" : " ↗")) { act.cxGo(c) }
                    }
                } label: { row("Complications (\(cxs.count))", "à tout moment", "bolt.fill") }
            }
        }
        Section {
            if started {
                Button { vs.monitorOpen = true } label: { row("Moniteur", "appareil posé, lisible à 2 m", "arrow.up.left.and.arrow.down.right") }
            }
            if hasFlow && !vs.showAll {
                Button { vs.sheet = .parcours } label: { row("Se repérer", "échelle des blocs", "list.number") }
            }
            if hasFlow {
                Button { vs.sheet = .schema } label: { row("Schéma", "schéma de l’algorithme, plein écran", "point.3.connected.trianglepath.dotted") }
            }
        }
        Section("Session") {
            Button {
                if started { vs.confirmExercise = true } else { act.armExercise() }
            } label: {
                row("Répéter en exercice", (started && !R.exercise) ? "session en cours" : lastExercise(f.id), "triangle.fill")
            }
            .disabled(started && !R.exercise)
            if started && hasFlow {
                Button { vs.confirmRestart = true } label: { row("Recommencer le parcours", "repart du début", "arrow.counterclockwise") }
            }
            if nHist > 0 {
                Button { vs.sheet = .history } label: { row("Historique des sessions (\(nHist))", nil, "archivebox") }
            }
        }
        if started {
            Menu {
                CrAideRows(R: R, vs: vs)
            } label: { row("L’aide", "modifier, versions, exporter", "doc.text") }
        } else {
            Section("L’aide") { CrAideRows(R: R, vs: vs) }
        }
        if started {
            Section {
                Button(role: .destructive) { vs.endOpen = true } label: {
                    Label(R.exercise ? "Terminer l’exercice…" : "Terminer la session…", systemImage: "stop.fill")
                }
            }
        }
    }

    private func row(_ title: String, _ sub: String?, _ sf: String) -> some View {
        Label {
            Text(title)
            if let sub { Text(sub) }
        } icon: {
            Image(systemName: sf)
        }
    }

    /// « dernier : dd/mm/yyyy » ou « aucune trace clinique ».
    private func lastExercise(_ fid: String) -> String {
        let last = model.sessions
            .filter { $0["ficheId"]?.string == fid && ($0["exercise"]?.truthy ?? false) }
            .compactMap { $0["savedAt"]?.number }.max()
        guard let t = last else { return "aucune trace clinique" }
        return "dernier : " + Txt.frDate(t)
    }
}

/// Les rangées « L'aide » : Modifier, Dupliquer dans « Perso », exports.
struct CrAideRows: View {
    let R: RuntimeSession
    let vs: CrisisViewState
    @Environment(AppModel.self) private var model

    var body: some View {
        let f = R.fiche
        let started = R.started
        let editable = model.library.canEdit(f)
        Button { model.path.append(.editFiche(f.id)) } label: {
            Label {
                Text("Modifier")
                Text(started ? "session en cours" : (editable ? "hors urgence" : "lecture seule"))
            } icon: { Image(systemName: "pencil") }
        }
        .disabled(started || !editable)
        Button { dupToPerso(f) } label: { Label("Dupliquer dans « Perso »", systemImage: "plus.square.on.square") }
        Divider()
        Button { exportJSON(f) } label: {
            Label { Text("Exporter l’aide (.json)"); Text("le contenu, pas la session") } icon: { Image(systemName: "square.and.arrow.down") }
        }
        Button { vs.sheet = .page } label: {
            Label {
                Text("Exporter l’aide en PDF")
                Text(started ? "la session : par « Compte-rendu »" : "le contenu de la fiche")
            } icon: { Image(systemName: "printer") }
        }
    }

    /// `dupToPerso('f')` : copie profonde REPASSÉE PAR `migrate`, nouvel id, « (copie) », Perso, Brouillon.
    private func dupToPerso(_ f: Fiche) {
        var c = Sanitize.fiche(f.json)
        c.id = Guard.uid("f")
        c.title = (f.title.isEmpty ? "Fiche" : f.title) + " (copie)"
        c.library = nil
        c.status = .draft
        c.order = JS.now()
        if model.save(c) { model.toast("✓ Copie créée dans « Perso » — état Brouillon", seconds: 3.5) }
    }

    /// « Exporter l'aide (.json) » : l'enveloppe v3 de la PWA, partagée par la feuille système.
    private func exportJSON(_ f: Fiche) {
        let cats = model.categories.filter { $0.id == f.category }
        let env = Exporter.envelope(fiches: [f], references: [], categories: cats, all: model.categories, space: model.store.currentSpace)
        let name = Exporter.fileName(base: "fiche-" + Exporter.slug(f.title), ext: "json")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try env.data(pretty: true).write(to: url, options: .atomic)
            vs.sheet = .export(url)
        } catch {
            model.toast("⚠ Export impossible : " + error.localizedDescription)
        }
    }
}

/// L'hôte UNIQUE des feuilles de la lecture (une seule à la fois).
struct CrSheetHost: View {
    let sheet: CrSheet
    let R: RuntimeSession
    let vs: CrisisViewState

    var body: some View {
        switch sheet {
        case .stamp(let id):
            CrStampSheet(R: R, vs: vs, evId: id).modifier(CrDockSheetStyle())
        case .cx:
            CrCxSheet(R: R, vs: vs).modifier(CrDockSheetStyle())
        case .panel:
            CrPanelSheet(R: R, vs: vs).modifier(CrDockSheetStyle())
        case .parcours:
            ParcoursSheetView(ficheId: R.ficheId).modifier(CrPageSheetStyle())
        case .page:
            PageView(ficheId: R.ficheId).modifier(CrPageSheetStyle())
        case .schema:
            SchemaView(ficheId: R.ficheId).modifier(CrPageSheetStyle())
        case .report(let id):
            ReportView(sessionId: id).modifier(CrPageSheetStyle())
        case .history:
            SessionsHistoryView(ficheId: R.ficheId).modifier(CrPageSheetStyle())
        case .export(let url):
            CrExportSheet(url: url)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

/// Feuilles du quai : détentes moyenne/grande, poignée visible, et l'écran de crise RESTE ACTIF
/// dessous jusqu'à la détente moyenne (la capsule — l'alarme — reste en vue ; règle 11).
struct CrDockSheetStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            #if os(macOS)
            .frame(minWidth: 420, minHeight: 420)
            #endif
    }
}

/// Destinations (Page, Schéma, Se repérer, compte-rendu, historique) : grande feuille.
struct CrPageSheetStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            #if os(macOS)
            .frame(minWidth: 720, minHeight: 560)
            #endif
    }
}

/// Partage d'un fichier exporté (feuille système).
struct CrExportSheet: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "doc.badge.arrow.up").font(.system(size: 40, weight: .semibold)).foregroundStyle(T.act)
                    .accessibilityHidden(true)
                Text(url.lastPathComponent).aFont(TypeScale.item, .bold).foregroundStyle(T.ink).multilineTextAlignment(.center)
                ShareLink(item: url) {
                    Label("Partager ou enregistrer", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: Ctrl.l)
                }
                .buttonStyle(.glassProminent)
                .tint(T.act)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Exporter")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel("Fermer")
                }
            }
        }
    }
}

// MARK: - « Terminer la session ? » — la SEULE porte de fin (confirmation MAINTENUE 1,2 s)

struct CrEndDialog: View {
    let R: RuntimeSession
    let vs: CrisisViewState
    @Environment(AppModel.self) private var model

    var body: some View {
        let now = JS.now()
        let title = R.essai ? "Terminer l’essai ?" : (R.exercise ? "Terminer l’exercice ?" : "Terminer la session ?")
        let lines = Live.endSessOpenTxt(R.fiche, nav: R.nav, navSeq: R.navSeq, checked: Set(R.checkedKeys),
                                        timers: R.orderedTimers.map(CrisisPure.run))
        ZStack {
            T.scrim.ignoresSafeArea()
                .onTapGesture { vs.endOpen = false }       // voile = « Poursuivre »
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 14) {
                Text(title).aFont(TypeScale.step, .heavy).foregroundStyle(T.ink).accessibilityAddTraits(.isHeader)
                (Text(R.exercise ? "▲ Exercice — " : "").bold()
                 + Text(R.fiche.title.isEmpty ? "Aide cognitive" : R.fiche.title)
                 + Text(" — durée ") + Text(Fmt.ms(max(0, now - R.startedAt))).bold())
                    .aFont(TypeScale.body, .medium).foregroundStyle(T.ink2)
                if !lines.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { _, l in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                if l.crit { CrTag(text: "Critique", fg: T.crit, bg: T.critSoft) }
                                else if let g = l.g { Text(g).aFont(TypeScale.body, .bold) }
                                Text(l.txt).aFont(TypeScale.body, .semibold).foregroundStyle(l.crit ? T.crit : T.ink)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.line, lineWidth: 1))
                }
                Text("Le chrono global et tous les minuteurs s'arrêtent. La session quitte l'accueil. Le déroulé horodaté reste consultable dans l'historique.")
                    .aFont(TypeScale.body, .medium).foregroundStyle(T.ink2)
                HStack(spacing: 10) {
                    Button("Poursuivre") { vs.endOpen = false }
                        .buttonStyle(.a(.secondary, Ctrl.l, full: true))
                        .keyboardShortcut(.cancelAction)
                    HoldButton(label: "Terminer", ms: 1200, kind: .danger, height: Ctrl.l) {
                        CrAct(model: model, vs: vs, R: R).endSession()
                    }
                }
                Text("Maintenir 1,2 s. Relâcher annule.").aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
            }
            .padding(20)
            .frame(maxWidth: 420)
            .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
            .padding(20)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity)
    }
}
