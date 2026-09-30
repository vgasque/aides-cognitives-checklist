import SwiftUI
import AidesCore
import UniformTypeIdentifiers
import PhotosUI

// L'ÉDITEUR D'AIDE COGNITIVE — port de `openEdit`/`newFiche`, `renderEditor`, `bindEditorExit`,
// `applyViewChrome` (barre d'éditeur), `edStructHtml`/`edTocHtml`, `reviewPanelHtml`.
//
// Mise en page (`mqReadWide`, `wideEdit`) : < 1000 pt une colonne (Structure en dépliant collant
// en tête, relecture en pied) ; ≥ 1000 formulaire | colonne droite 320 (relecture + aperçu) ;
// ≥ 1200 Structure 220 | formulaire | 320. Largeurs mesurées ÷ taille du texte (règle 10).

struct FicheEditorView: View {
    let ficheId: String
    @Environment(AppModel.self) private var model
    @State private var ed: FicheDraft?
    @State private var prepared = false
    @State private var askEnd = false

    var body: some View {
        Group {
            if let ed {
                FicheEditorScreen(ed: ed)
            } else {
                T.amb.ignoresSafeArea()
            }
        }
        .onAppear(perform: prepare)
        .alert("Terminer la session et modifier ?", isPresented: $askEnd) {
            Button("Terminer et modifier", role: .destructive) { endSessionThenOpen() }
            Button("Annuler", role: .cancel) { leaveRoute() }
        } message: {
            Text("Une session est en cours sur cette aide. La modifier va d’abord la TERMINER (elle sera archivée avec son compte rendu) : la structure de la fiche ne peut pas changer sous quelqu’un qui la déroule.")
        }
    }

    /// `openEdit(id)` / `newFiche()` / reprise d'un brouillon de création.
    private func prepare() {
        guard !prepared else { return }
        prepared = true
        if let f = model.fiches.first(where: { $0.id == ficheId }) {
            if !model.library.canEdit(f) {
                model.toast(EditorTexts.readOnly)
                DispatchQueue.main.async { replaceWithRead() }
                return
            }
            // Bibliothèque partagée : le rôle se revérifie en tâche de fond (jamais bloquant).
            if f.library != nil && model.auth.signedIn { Task { await model.sync.loadProfile() } }
            if model.engine.live[f.id] != nil { askEnd = true; return }
            open(f)
        } else {
            openNew()
        }
    }

    private func endSessionThenOpen() {
        if let R = model.engine.live[ficheId] { model.endSession(R) }
        if let f = model.fiches.first(where: { $0.id == ficheId }) { open(f) } else { leaveRoute() }
    }

    /// Ouvre une aide EXISTANTE : point de version (un par séance), puis brouillon parqué éventuel.
    private func open(_ f: Fiche) {
        model.library.putBackup(f)
        let base = f.json
        var draft = f
        var restored: Double? = nil
        var atts: [String] = []
        if let slot = model.library.draftPark("f"), slot["forId"]?.string == f.id, slot["isNew"]?.truthy != true,
           let dj = slot["draft"], dj != base {
            draft = Sanitize.fiche(dj)
            atts = (slot["newAtts"]?.array ?? []).compactMap(\.string)
            restored = slot["ts"]?.number ?? JS.now()
        }
        EdKit.syncGallery(&draft)
        let e = FicheDraft(model: model, draft: draft, base: base)
        e.newAtts = atts
        e.restoredAt = restored
        ed = e
        e.touch(now: true)
    }

    /// Création : brouillon parqué de CE brouillon neuf, sinon `blankFiche()` dans la bibliothèque visée.
    private func openNew() {
        if let slot = model.library.draftPark("f"), slot["forId"]?.string == ficheId, slot["isNew"]?.truthy == true,
           let dj = slot["draft"] {
            var draft = Sanitize.fiche(dj)
            draft.id = ficheId
            EdKit.syncGallery(&draft)
            let e = FicheDraft(model: model, draft: draft, base: nil)
            e.newAtts = (slot["newAtts"]?.array ?? []).compactMap(\.string)
            e.restoredAt = slot["ts"]?.number
            ed = e
            e.touch(now: true)
            return
        }
        let scope = model.editorNewScopes[ficheId] ?? ""
        let lib: String? = scope.isEmpty ? nil : scope
        if !model.library.canEdit(scope: lib) {
            model.toast(EditorTexts.roNewFiche)
            DispatchQueue.main.async { leaveRoute() }
            return
        }
        let d = EdKit.blankFiche(id: Guard.isSafeId(ficheId) ? ficheId : Guard.uid(), library: lib)
        let e = FicheDraft(model: model, draft: d, base: d.json)
        ed = e
        e.touch(now: true)
    }

    private func leaveRoute() {
        model.path.removeAll { $0 == .editFiche(ficheId) }
    }
    private func replaceWithRead() {
        leaveRoute()
        if model.path.last != .fiche(ficheId) { model.openFiche(ficheId) }
    }
}

// MARK: - L'écran

struct FicheEditorScreen: View {
    @Bindable var ed: FicheDraft
    @Environment(AppModel.self) private var model
    @Environment(\.textScale) private var scale
    @Environment(\.scenePhase) private var scenePhase
    @State private var exportDoc: EditorJSONDocument?
    @State private var exportName = ""
    @State private var exporting = false
    @State private var photoItems: [PhotosPickerItem] = []
    /// Cible de la photothèque, retenue au moment d'ouvrir (le sélecteur se ferme AVANT de livrer).
    @State private var photoFor: EdImageTarget = .gallery

    var body: some View {
        GeometryReader { geo in
            layout(width: geo.size.width / max(scale, 0.5))
        }
        .background(T.amb.ignoresSafeArea())
        .navigationTitle(ed.existsInLibrary ? "Édition" : "Création")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { toolbarContent }
        .environment(\.edLocked, ed.grab != nil)
        .sheet(item: $ed.sheet) { s in FicheSheetHost(ed: ed, sheet: s) }
        .fileImporter(isPresented: importerOn, allowedContentTypes: EdIntake.types(ed.fileImport ?? .pdf), allowsMultipleSelection: true) { r in
            let kind = ed.fileImport
            ed.fileImport = nil
            if case .success(let urls) = r, let kind { take(EdIntake.read(urls), kind) }
        }
        .photosPicker(isPresented: photosOn, selection: $photoItems, maxSelectionCount: photoMax, matching: .images)
        .onChange(of: ed.photoTarget) { _, t in if let t { photoFor = t } }
        .onChange(of: photoItems) { _, items in
            guard !items.isEmpty else { return }
            let target = photoFor
            photoItems = []
            ed.photoTarget = nil
            Task { @MainActor in take(await EdIntake.load(items), .image(target)) }
        }
        .confirmationDialog("Ajouter une image", isPresented: imageChoiceOn, titleVisibility: .visible) {
            Button("Photothèque") { let t = ed.imageChoice; ed.imageChoice = nil; ed.photoTarget = t }
            Button("Fichiers") { if let t = ed.imageChoice { ed.imageChoice = nil; ed.fileImport = .image(t) } }
            Button("Annuler", role: .cancel) { ed.imageChoice = nil }
        }
        .confirmationDialog(deleteMessage, isPresented: $ed.askDelete, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) { deleteFiche() }
            Button("Annuler", role: .cancel) {}
        }
        .fileExporter(isPresented: $exporting, document: exportDoc, contentType: .json, defaultFilename: exportName) { _ in exportDoc = nil }
        #if os(iOS)
        .fullScreenCover(item: $ed.trial) { f in trialView(f) }
        #else
        .sheet(item: $ed.trial) { f in trialView(f).frame(minWidth: 720, minHeight: 640) }
        #endif
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: EdTiming.parkMs * 1_000_000)
                if Task.isCancelled { break }
                ed.parkTick()
            }
        }
        .onChange(of: scenePhase) { _, p in if p != .active { ed.flush(); ed.parkTick() } }
        .onDisappear {
            if model.path.contains(.editFiche(ed.d.id)) { ed.flush() } else { ed.leave() }
        }
    }

    // MARK: Liaisons calculées

    private var importerOn: Binding<Bool> {
        Binding(get: { ed.fileImport != nil }, set: { if !$0 { ed.fileImport = nil } })
    }
    private var photosOn: Binding<Bool> {
        Binding(get: { ed.photoTarget != nil }, set: { if !$0 { ed.photoTarget = nil } })
    }
    private var imageChoiceOn: Binding<Bool> {
        Binding(get: { ed.imageChoice != nil }, set: { if !$0 { ed.imageChoice = nil } })
    }
    private var photoMax: Int? {
        if case .block? = ed.photoTarget { return 1 }
        return max(1, Guard.maxImgPerEntity - ed.d.images.count)
    }
    private var deleteMessage: String {
        ed.d.library != nil
            ? "Supprimer cette fiche définitivement ?\nElle disparaîtra pour tous les membres de la bibliothèque, et les notes personnelles que certains y ont peut-être attachées seront effacées — prévenez-les avant si besoin."
            : "Supprimer cette fiche définitivement ?"
    }

    @ViewBuilder private func trialView(_ f: Fiche) -> some View {
        TrialPreviewView(draft: f)
            .environment(model)
    }

    // MARK: Mise en page

    @ViewBuilder private func layout(width w: CGFloat) -> some View {
        let wide = w >= 1000
        let triple = w >= 1200
        let hasStruct = !ed.d.blocks.isEmpty || !ed.d.excursions.isEmpty
        ScrollViewReader { proxy in
            HStack(alignment: .top, spacing: 0) {
                if triple && hasStruct {
                    ScrollView {
                        EdStructureList(ed: ed, compact: false).padding(16)
                    }
                    .frame(width: 220)
                    Divider()
                }
                ScrollView {
                    FicheForm(ed: ed, wide: wide)
                        .frame(maxWidth: 760)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom, spacing: 0) { FicheDoor(ed: ed) }
                if wide {
                    Divider()
                    ScrollView {
                        FicheAside(ed: ed).padding(16)
                    }
                    .frame(width: 320)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    if !triple && hasStruct { EdTocFold(ed: ed) }
                    if ed.grab != nil { EdGrabBanner(ed: ed) }
                }
                .background(T.amb)
            }
            .onChange(of: ed.scrollRequest) { _, r in
                guard let r else { return }
                withAnimation(nil) { proxy.scrollTo(r.key, anchor: .center) }
            }
        }
    }

    // MARK: Barre d'éditeur

    /// Barre SYSTÈME (iOS 26, Liquid Glass) : retour automatique (la sortie — écriture et ménage —
    /// se fait à la disparition, `bindEditorExit`), titre + état d'enregistrement au centre, UNE
    /// action principale proéminente (« ▶ Essayer »), le reste dans le menu « Plus ».
    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            EdTitleBlock(ed: ed)
        }
        if !ed.undo.isEmpty {
            ToolbarItem(placement: .primaryAction) {
                Button { ed.undoLast() } label: { Image(systemName: "arrow.uturn.backward") }
                    .accessibilityLabel("Annuler le dernier geste")
                    .help("Annuler le dernier geste (\(ed.undo.count) en mémoire) — Cmd/Ctrl-Z")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Menu {
                if ed.existsInLibrary {
                    Button { ed.sheet = .versions } label: {
                        Label(ed.d.library != nil ? "Ma version écrasée" : "Versions", systemImage: "clock.arrow.circlepath")
                    }
                    Divider()
                }
                Button { duplicate() } label: { Label("Dupliquer dans « Perso »", systemImage: "doc.on.doc") }
                Button { exportFiche() } label: { Label("Exporter l’aide (.json)", systemImage: "square.and.arrow.up") }
                if ed.existsInLibrary {
                    Divider()
                    Button(role: .destructive) { ed.askDelete = true } label: { Label("Supprimer cette fiche", systemImage: "trash") }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .accessibilityLabel("Plus d’actions")
        }
        ToolbarItem(placement: .primaryAction) {
            Button { ed.trial = Sanitize.fiche(ed.d.json) } label: {
                Label("Essayer", systemImage: "play.fill").labelStyle(.titleAndIcon)
            }
            .buttonStyle(.glassProminent)
            .accessibilityLabel("Essayer")
            .help("Dérouler le brouillon comme en session — rien n'est enregistré")
        }
    }

    // MARK: Gestes de la barre

    private func duplicate() {
        let src = Sanitize.fiche(ed.d.json)
        _ = Importer.duplicateToPerso(src, library: model.library)
        model.refresh()
        model.toast("✓ Copie créée dans « Perso » — état Brouillon")
    }
    private func exportFiche() {
        let f = Sanitize.fiche(ed.d.json)
        let env = Exporter.envelope(fiches: [f], references: [], categories: nil, all: model.categories, space: model.store.currentSpace)
        exportDoc = EditorJSONDocument(data: env.data(pretty: true))
        exportName = String(Exporter.fileName(base: "fiche-" + Exporter.slug(f.title), ext: "json").dropLast(5))
        exporting = true
        if !f.docs.isEmpty { model.toast(Exporter.jsonOnlyNotice, seconds: 8) }
    }
    /// `deleteDraft()` : tombe, parc vidé, sessions de l'aide effacées, retour à la bibliothèque.
    private func deleteFiche() {
        let id = ed.d.id
        ed.clearParkIf()
        if let f = model.fiches.first(where: { $0.id == id }) { model.delete(f) }
        model.path.removeAll { $0 == .editFiche(id) || $0 == .fiche(id) }
    }

    // MARK: Fichiers reçus

    private func take(_ files: [EdIntake.File], _ kind: EdImport) {
        switch kind {
        case .pdf:
            var got: [Attachment] = []
            EdIntake.takePdfs(files, existing: ed.d.docs.count, model: model) { got.append($0) }
            guard !got.isEmpty else { return }
            ed.newAtts.append(contentsOf: got.map(\.id))
            ed.structural { $0.docs.append(contentsOf: got) }
        case .image(let target):
            var imgs: [EdIntake.Img] = []
            let single: Bool
            if case .block = target { single = true } else { single = false }
            EdIntake.takeImages(files, existing: ed.d.images.count, single: single, tooMany: "⚠ \(Guard.maxImgPerEntity) images maximum par aide.", model: model) { imgs.append($0) }
            guard !imgs.isEmpty else { return }
            ed.structural { f in
                switch target {
                case .block(let bid):
                    if let i = f.blocks.firstIndex(where: { $0.id == bid }), let im = imgs.first {
                        f.blocks[i].image = im.data; f.blocks[i].imageW = im.w; f.blocks[i].imageH = im.h
                    }
                default:
                    for im in imgs { f.images.append(ImageRef(id: Guard.uid("i"), data: im.data, w: im.w, h: im.h, caption: "", scale: 100)) }
                }
                EdKit.syncGallery(&f)
            }
        }
    }
}

// MARK: - Ligne d'état (statut éditorial · enregistrement · relecture)

/// Titre de la barre : le titre vivant du brouillon, puis UNE ligne d'état — statut éditorial
/// (`#hdrBadge`), enregistrement (`#hdrSaved`, forme courte au téléphone) et compte de relecture
/// (`#hdrRev`, qui amène au volet).
struct EdTitleBlock: View {
    @Bindable var ed: FicheDraft
    @Environment(AppModel.self) private var model
    @Environment(\.widthClass) private var wc

    var body: some View {
        let n = EdKit.reviewNotes(ed.d).count
        let s = EdSaveText.text(ed.save, at: ed.savedAt, short: wc == .phone)
        let revLabel: String = "\(n) remarque" + either(n > 1, "s", "") + " de relecture — aucune n’empêche d’enregistrer"
        VStack(spacing: 1) {
            Text(JS.trim(ed.d.title).isEmpty ? "Nouvelle fiche" : ed.d.title)
                .aFont(TypeScale.item, .bold).foregroundStyle(T.ink).lineLimit(1)
            HStack(spacing: 6) {
                Text(statusLine).foregroundStyle(ed.d.status == .review ? T.warn : T.ink2)
                if !s.isEmpty {
                    Text("·").foregroundStyle(T.ink3)
                    Text(s).foregroundStyle(ed.save == .err ? T.warn : T.ink2)
                        .accessibilityAddTraits(.updatesFrequently)
                }
                if n > 0 {
                    Button { ed.goFlash("rev") } label: {
                        Text("△ \(n)").foregroundStyle(T.warn).padding(.horizontal, 6).background(T.warnSoft, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(revLabel)
                    .help(revLabel)
                }
            }
            .aFont(TypeScale.cap, .semibold)
            .lineLimit(1)
        }
    }
    private var statusLine: String {
        var extra: [String] = []
        if ed.parked && !ed.untitled { extra.append("auto-enregistré") }
        if model.auth.signedIn && model.syncStatus.state == .err { extra.append("synchro en attente") }
        return EdStatusText.label(ed.d.status, fem: true) + (extra.isEmpty ? "" : " · " + extra.joined(separator: " · "))
    }
}

// MARK: - Bannière « prendre / poser »

struct EdGrabBanner: View {
    @Bindable var ed: FicheDraft
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Déplacement : " + label).aFont(TypeScale.body, .bold).foregroundStyle(T.onPrimary).lineLimit(1)
                Text("touchez une destination").aFont(TypeScale.meta, .regular).foregroundStyle(T.onPrimary.opacity(0.85))
            }
            Spacer(minLength: 4)
            Button { ed.grab = nil } label: {
                Image(systemName: "xmark").aFont(TypeScale.item, .bold).foregroundStyle(T.onPrimary)
                    .frame(width: Ctrl.l, height: Ctrl.l).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Annuler le déplacement")
            .keyboardShortcut(.cancelAction)
        }
        .padding(.leading, 16)
        .background(T.act)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.updatesFrequently)
    }
    /// Libellé de l'objet tenu (`edGrabBanner`).
    private var label: String {
        let f = ed.d
        switch ed.grab {
        case .block(let bid)?:
            guard let b = f.blocks.first(where: { $0.id == bid }) else { return "" }
            let t = JS.trim(b.title)
            var s = "bloc « " + (t.isEmpty ? "sans titre" : t) + " »"
            if b.kind != .decision {
                let n = Graph.cleanSteps(f, b).count
                s += " · \(n) étape" + either(n > 1, "s", "")
            }
            return s
        case .step(_, let iid)?:
            let t = JS.trim(f.items.first { $0.id == iid }?.do ?? "")
            return "« " + (t.isEmpty ? "étape vide" : t) + " »"
        case .list(let k, let i)?:
            let t = EdListOps.label(f, k, i)
            return t.isEmpty ? "rangée \(i + 1)" : "« " + t + " »"
        case nil:
            return ""
        }
    }
}

// MARK: - Structure (colonne ≥ 1200, dépliant collant en dessous)

struct EdTocFold: View {
    @Bindable var ed: FicheDraft
    var body: some View {
        let n = ed.d.blocks.filter { $0.kind != .review }.count
        VStack(spacing: 0) {
            Button { ed.tocOpen.toggle() } label: {
                HStack {
                    Text("Structure").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                    Text("\(n) bloc" + either(n > 1, "s", "")).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                    Spacer()
                    Image(systemName: ed.tocOpen ? "chevron.up" : "chevron.down").aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2)
                }
                .padding(.horizontal, 16).frame(minHeight: Ctrl.m).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(ed.tocOpen ? [.isSelected] : [])
            if ed.tocOpen {
                ScrollView { EdStructureList(ed: ed, compact: true).padding(.horizontal, 16).padding(.bottom, 12) }
                    .frame(maxHeight: 320)
            }
            Divider()
        }
    }
}

/// Colonne PUREMENT navigationnelle : aucun champ, aucune action destructive (`edStructHtml`).
/// Choix natif (question ouverte n° 4) : les blocs « revue » ne sont pas numérotés ici — ils sont
/// hors du fil, comme en lecture.
struct EdStructureList: View {
    @Bindable var ed: FicheDraft
    var compact: Bool

    var body: some View {
        let f = ed.d
        let flow = f.blocks.filter { $0.kind != .review }
        VStack(alignment: .leading, spacing: 2) {
            if !compact {
                HStack {
                    Text("Structure").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                    Spacer()
                    Text("\(flow.count)").aFont(TypeScale.meta, .bold, .mono).foregroundStyle(T.ink2)
                }
                .padding(.bottom, 6)
            }
            ForEach(Array(flow.enumerated()), id: \.element.id) { i, b in
                phaseHeader(f, flow, i)
                row(f, b, number: i + 1)
            }
            if !f.excursions.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill").foregroundStyle(T.bolt)
                    Text("À tout moment").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
                    Text("hors numérotation").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink3)
                }
                .padding(.top, 10)
                ForEach(Array(f.excursions.enumerated()), id: \.offset) { _, c in cxRow(f, c) }
            }
        }
    }
    @ViewBuilder private func phaseHeader(_ f: Fiche, _ flow: [Block], _ i: Int) -> some View {
        let p = Pool.phase(f, flow[i].id)
        let prevP = i > 0 ? Pool.phase(f, flow[i - 1].id) : ""
        if !p.isEmpty && p != prevP {
            Text(p.uppercased()).aFont(TypeScale.cap, .bold).tracking(0.6).foregroundStyle(T.ink2).padding(.top, 8)
        }
    }
    @ViewBuilder private func row(_ f: Fiche, _ b: Block, number: Int) -> some View {
        let isDec = b.kind == .decision
        let t = JS.trim(b.title)
        let n = isDec ? b.options.count : Graph.cleanSteps(f, b).count
        let count = isDec ? "\(n) branche" + either(n > 1, "s", "") : "\(n) étape" + either(n > 1, "s", "")
        Button {
            ed.tocOpen = false
            ed.goFlash("b:" + b.id)
        } label: {
            HStack(spacing: 8) {
                Text(isDec ? "◆" : "\(number)").aFont(TypeScale.meta, .bold, .mono).foregroundStyle(T.ink2).frame(width: 22)
                Text(t.isEmpty ? (isDec ? "Décision" : "Sans titre") : t).aFont(TypeScale.body, .semibold).foregroundStyle(T.ink).lineLimit(2)
                Spacer(minLength: 4)
                Text(count).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
            }
            .frame(minHeight: Ctrl.m).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    @ViewBuilder private func cxRow(_ f: Fiche, _ c: Excursion) -> some View {
        let inside = f.blocks.contains { $0.id == c.target }
        let l = JS.trim(c.label)
        let content = HStack(spacing: 8) {
            Image(systemName: "bolt.fill").aFont(TypeScale.meta, .regular).foregroundStyle(T.bolt).frame(width: 22)
            Text(l.isEmpty ? "Complication" : l).aFont(TypeScale.body, .semibold).foregroundStyle(T.ink).lineLimit(2)
            Spacer(minLength: 4)
            Text(inside ? "bloc" : "autre aide ↗").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
        }
        .frame(minHeight: Ctrl.m)
        if inside {
            Button { ed.tocOpen = false; ed.goFlash("b:" + c.target) } label: { content.contentShape(Rectangle()) }.buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: - Colonne droite (≥ 1000) : relecture puis aperçu du schéma

struct FicheAside: View {
    @Bindable var ed: FicheDraft
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FicheReviewPanel(ed: ed)
            WorkCard(padding: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Algorithme — aperçu automatique").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                    if ed.d.blocks.isEmpty {
                        Text("Le schéma se dessinera dès le premier bloc.").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                    } else {
                        EditorFlowPreview(fiche: ed.d)
                    }
                }
            }
        }
    }
}

/// Le volet de relecture d'une AIDE (remarques + propositions Q1).
struct FicheReviewPanel: View {
    @Bindable var ed: FicheDraft
    var body: some View {
        EdReviewPanel(notes: EdKit.reviewNotes(ed.d),
                      offers: EdKit.reviewOffers(ed.d, dismissed: ed.offersDismissed),
                      onGo: { at in ed.goFlash(at) },
                      onTake: { o in take(o) },
                      onDismiss: { id in ed.offersDismissed.insert(id) })
            .id("rev")
            .edFlash(ed.flashKey == "rev")
    }
    /// `reviewOfferTake` : l'acceptation passe par la porte « ＋ » (point de création unique) ;
    /// seul ★ n'y passe pas — il ne crée rien, il marque.
    private func take(_ o: EdKit.Offer) {
        switch o.kind {
        case .interval(let sec): FichePalette.add(ed, .interval, seconds: sec)
        case .counter: FichePalette.add(ed, .counter, seconds: nil)
        case .memory(let iid):
            ed.updateItem(iid, typing: false) { $0.memory = true }
            ed.goFlash("nf")
        }
    }
}

/// Volet de relecture — jamais bloquant, jamais rouge ; absent quand il n'a rien à dire.
struct EdReviewPanel: View {
    var notes: [EdKit.RevNote]
    var offers: [EdKit.Offer]
    var onGo: (String) -> Void
    var onTake: (EdKit.Offer) -> Void
    var onDismiss: (String) -> Void
    @State private var open = true

    var body: some View {
        if !notes.isEmpty || !offers.isEmpty {
            WorkCard(padding: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Button { open.toggle() } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Image(systemName: "exclamationmark.triangle").foregroundStyle(T.warn)
                            Text("Relecture · \(notes.count)").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                            Text(notes.map(\.cible).joined(separator: " · ")).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).lineLimit(1)
                            Spacer(minLength: 0)
                            Image(systemName: open ? "chevron.up" : "chevron.down").aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink3)
                        }
                        .frame(minHeight: Ctrl.m).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(.updatesFrequently)
                    if open {
                        ForEach(notes) { n in noteRow(n) }
                        if !offers.isEmpty {
                            Text("Ce que votre texte permettrait d’ajouter").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2).padding(.top, 4)
                            ForEach(offers) { o in offerRow(o) }
                        }
                        Text("Aucune de ces remarques n’empêche d’enregistrer — vous gardez le contrôle.")
                            .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
    @ViewBuilder private func noteRow(_ n: EdKit.RevNote) -> some View {
        Button { onGo(n.at) } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(n.cible).aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                Text(stripped(n.txt)).aFont(TypeScale.meta, .regular).foregroundStyle(T.warn).multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(T.warnSoft, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    @ViewBuilder private func offerRow(_ o: EdKit.Offer) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(o.cible).aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
            Text(o.txt).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button(o.btn) { onTake(o) }.buttonStyle(.a(.secondary, Ctrl.s))
                Spacer()
                Button { onDismiss(o.id) } label: {
                    Image(systemName: "xmark").aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2)
                        .frame(width: Ctrl.l, height: Ctrl.l).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Écarter cette proposition")
            }
        }
        .padding(10)
        .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
    }
    /// La remarque sans son « △ » de tête (le volet le porte déjà).
    private func stripped(_ s: String) -> String {
        var t = s
        if t.hasPrefix("△") { t.removeFirst(); while t.first == " " { t.removeFirst() } }
        return t
    }
}

// MARK: - Export d'une aide (.json)

struct EditorJSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
