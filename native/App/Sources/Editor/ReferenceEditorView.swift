import SwiftUI
import AidesCore
import UniformTypeIdentifiers
import PhotosUI

// L'ÉDITEUR DE RÉFÉRENCE (protocole) — port de `openProtocolEdit`/`newProtocol`,
// `renderProtocolEdit`, barre d'outils Markdown (`mdWrapSel`, `mdPrefixLines`, `mdCalloutLines`,
// `mdInsertAt`, `wrapBold`), `mdImagesHtml`, `ED_PALETTE_P`/`edAddProto`, `reviewNotesProto`,
// `leaveGC`. Même tronc que l'éditeur d'aide : écriture continue, parc, anneau d'annulation.
// Mise en page : < 1000 une colonne (aperçu sous le texte) ; ≥ 1000 formulaire | colonne 320
// (relecture + aperçu).

struct ReferenceEditorView: View {
    let referenceId: String
    @Environment(AppModel.self) private var model
    @State private var ed: ReferenceDraft?
    @State private var prepared = false

    var body: some View {
        Group {
            if let ed { ReferenceEditorScreen(ed: ed) } else { T.amb.ignoresSafeArea() }
        }
        .onAppear(perform: prepare)
    }

    private func prepare() {
        guard !prepared else { return }
        prepared = true
        if let p = model.references.first(where: { $0.id == referenceId }) {
            if !model.library.canEdit(p) {
                model.toast(EditorTexts.readOnly)
                DispatchQueue.main.async {
                    model.path.removeAll { $0 == .editReference(referenceId) }
                    if model.path.last != .reference(referenceId) { model.openReference(referenceId) }
                }
                return
            }
            if p.library != nil && model.auth.signedIn { Task { await model.sync.loadProfile() } }
            let draft0 = Sanitize.reference(p.json)
            let base = draft0.json
            var draft = draft0
            var restored: Double? = nil
            var atts: [String] = []
            if let slot = model.library.draftPark("p"), slot["forId"]?.string == p.id, slot["isNew"]?.truthy != true,
               let dj = slot["draft"], dj != base {
                draft = Sanitize.reference(dj)
                atts = (slot["newAtts"]?.array ?? []).compactMap(\.string)
                restored = slot["ts"]?.number ?? JS.now()
            }
            let e = ReferenceDraft(model: model, draft: draft, base: base)
            e.newAtts = atts
            e.restoredAt = restored
            ed = e
            e.touch(now: true)
            return
        }
        if let slot = model.library.draftPark("p"), slot["forId"]?.string == referenceId, slot["isNew"]?.truthy == true,
           let dj = slot["draft"] {
            var draft = Sanitize.reference(dj)
            draft.id = referenceId
            let e = ReferenceDraft(model: model, draft: draft, base: nil)
            e.newAtts = (slot["newAtts"]?.array ?? []).compactMap(\.string)
            e.restoredAt = slot["ts"]?.number
            ed = e
            e.touch(now: true)
            return
        }
        let scope = model.editorNewScopes[referenceId] ?? ""
        let lib: String? = scope.isEmpty ? nil : scope
        if !model.library.canEdit(scope: lib) {
            model.toast(EditorTexts.roNewReference)
            DispatchQueue.main.async { model.path.removeAll { $0 == .editReference(referenceId) } }
            return
        }
        let d = EdKit.blankReference(id: Guard.isSafeId(referenceId) ? referenceId : Guard.uid("p"), library: lib)
        let e = ReferenceDraft(model: model, draft: d, base: d.json)
        ed = e
        e.touch(now: true)
    }
}

struct ReferenceEditorScreen: View {
    @Bindable var ed: ReferenceDraft
    @Environment(AppModel.self) private var model
    @Environment(\.textScale) private var scale
    @Environment(\.scenePhase) private var scenePhase
    @State private var ctl = EdTextController()
    @State private var exportDoc: EditorJSONDocument?
    @State private var exportName = ""
    @State private var exporting = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var photoFor: EdImageTarget = .body

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
        .sheet(item: $ed.sheet) { s in sheetView(s) }
        .fileImporter(isPresented: importerOn, allowedContentTypes: EdIntake.types(ed.fileImport ?? .pdf), allowsMultipleSelection: true) { r in
            let kind = ed.fileImport
            ed.fileImport = nil
            if case .success(let urls) = r, let kind { take(EdIntake.read(urls), kind) }
        }
        .photosPicker(isPresented: photosOn, selection: $photoItems, maxSelectionCount: max(1, Guard.maxImgPerEntity - ed.d.images.count), matching: .images)
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
            Button("Supprimer", role: .destructive) { deleteReference() }
            Button("Annuler", role: .cancel) {}
        }
        .fileExporter(isPresented: $exporting, document: exportDoc, contentType: .json, defaultFilename: exportName) { _ in exportDoc = nil }
        #if os(iOS)
        .fullScreenCover(item: $ed.trial) { p in ReferenceTrialPreviewView(draft: p).environment(model) }
        #else
        .sheet(item: $ed.trial) { p in ReferenceTrialPreviewView(draft: p).environment(model).frame(minWidth: 720, minHeight: 640) }
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
            if model.path.contains(.editReference(ed.d.id)) { ed.flush() } else { ed.leave() }
        }
    }

    private var importerOn: Binding<Bool> { Binding(get: { ed.fileImport != nil }, set: { if !$0 { ed.fileImport = nil } }) }
    private var photosOn: Binding<Bool> { Binding(get: { ed.photoTarget != nil }, set: { if !$0 { ed.photoTarget = nil } }) }
    private var imageChoiceOn: Binding<Bool> { Binding(get: { ed.imageChoice != nil }, set: { if !$0 { ed.imageChoice = nil } }) }
    private var deleteMessage: String {
        ed.d.library != nil
            ? "Supprimer ce protocole définitivement ?\nIl disparaîtra pour tous les membres de la bibliothèque."
            : "Supprimer ce protocole définitivement ?"
    }

    // MARK: Mise en page

    @ViewBuilder private func layout(width w: CGFloat) -> some View {
        let wide = w >= 1000
        ScrollViewReader { proxy in
            HStack(alignment: .top, spacing: 0) {
                ScrollView {
                    ReferenceForm(ed: ed, ctl: ctl, wide: wide)
                        .frame(maxWidth: 760)
                        .padding(16)
                        .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom, spacing: 0) { ReferenceDoor(ed: ed) }
                if wide {
                    Divider()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ReferenceReviewPanel(ed: ed)
                            WorkCard(padding: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Aperçu").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                                    EditorMarkdownPreview(markdown: ed.d.body, images: ed.d.images)
                                    EdLinkButton(text: "⛶ Ouvrir l'aperçu complet") { ed.trial = Sanitize.reference(ed.d.json) }
                                }
                            }
                        }
                        .padding(16)
                    }
                    .frame(width: 320)
                }
            }
            .onChange(of: ed.scrollRequest) { _, r in
                guard let r else { return }
                withAnimation(nil) { proxy.scrollTo(r.key, anchor: .center) }
            }
        }
    }

    // MARK: Barre

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            RefTitleBlock(ed: ed)
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
                Button { duplicate() } label: { Label("Dupliquer dans « Perso »", systemImage: "doc.on.doc") }
                Button { exportReference() } label: { Label("Exporter le protocole (.json)", systemImage: "square.and.arrow.up") }
                if ed.existsInLibrary {
                    Divider()
                    Button(role: .destructive) { ed.askDelete = true } label: { Label("Supprimer ce protocole", systemImage: "trash") }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .accessibilityLabel("Plus d’actions")
        }
        ToolbarItem(placement: .primaryAction) {
            Button { ed.trial = Sanitize.reference(ed.d.json) } label: {
                Label("Essayer", systemImage: "play.fill").labelStyle(.titleAndIcon)
            }
            .buttonStyle(.glassProminent)
            .accessibilityLabel("Essayer")
            .help("Dérouler le brouillon comme en session — rien n'est enregistré")
        }
    }

    @ViewBuilder private func sheetView(_ s: ReferenceSheet) -> some View {
        switch s {
        case .palette:
            ReferencePaletteSheet(ed: ed, ctl: ctl)
        case .links:
            EdLinkPicker(candidates: EdKit.relCandidates(selfId: ed.d.id, links: ed.d.links, library: ed.d.library,
                                                          fiches: model.fiches, references: model.references)) { id in
                if ed.d.links.count >= 20 { model.toast("⚠ 20 liens maximum."); return }
                ed.structural { $0.links.append(id) }
            }
        case .attPicker:
            EdAttPicker(candidates: EdKit.attachablePdfs(selfId: ed.d.id, docs: ed.d.docs, library: ed.d.library,
                                                         fiches: model.fiches, references: model.references)) { a in
                if ed.d.docs.count >= Guard.maxAttPerEntity { model.toast("⚠ \(Guard.maxAttPerEntity) documents maximum.", seconds: 6); return }
                ed.structural { $0.docs.append(Attachment(id: a.id, name: a.name, size: a.size)) }
            }
        case .category:
            EdCategoryPicker(library: ed.d.library, current: ed.d.category) { id in ed.structural { $0.category = id } }
        }
    }

    // MARK: Gestes

    private func duplicate() {
        _ = Importer.duplicateToPerso(Sanitize.reference(ed.d.json), library: model.library)
        model.refresh()
        model.toast("✓ Copie créée dans « Perso » — état Brouillon")
    }
    private func exportReference() {
        let p = Sanitize.reference(ed.d.json)
        let env = Exporter.envelope(fiches: [], references: [p], categories: nil, all: model.categories, space: model.store.currentSpace)
        exportDoc = EditorJSONDocument(data: env.data(pretty: true))
        exportName = String(Exporter.fileName(base: "protocole-" + Exporter.slug(p.title), ext: "json").dropLast(5))
        exporting = true
        if !p.docs.isEmpty { model.toast(Exporter.jsonOnlyNotice, seconds: 8) }
    }
    private func deleteReference() {
        let id = ed.d.id
        ed.clearParkIf()
        if let p = model.references.first(where: { $0.id == id }) { model.delete(p) }
        model.path.removeAll { $0 == .editReference(id) || $0 == .reference(id) }
    }

    /// Fichiers reçus : PDF joints, ou images insérées AU CURSEUR (`pImgTaker`).
    private func take(_ files: [EdIntake.File], _ kind: EdImport) {
        switch kind {
        case .pdf:
            var got: [Attachment] = []
            EdIntake.takePdfs(files, existing: ed.d.docs.count, model: model) { got.append($0) }
            guard !got.isEmpty else { return }
            ed.newAtts.append(contentsOf: got.map(\.id))
            ed.structural { $0.docs.append(contentsOf: got) }
        case .image:
            var imgs: [EdIntake.Img] = []
            EdIntake.takeImages(files, existing: ed.d.images.count, single: false,
                                tooMany: "⚠ \(Guard.maxImgPerEntity) images maximum par référence.", model: model) { imgs.append($0) }
            guard !imgs.isEmpty else { return }
            var refs: [ImageRef] = []
            var ins = ""
            var text = ed.d.body
            var sel = ctl.view == nil ? NSRange(location: (text as NSString).length, length: 0) : ctl.selection
            for im in imgs {
                let r = ImageRef(id: Guard.uid("i"), data: im.data, w: im.w, h: im.h, caption: "", scale: 100)
                refs.append(r)
                ins = (EdKit.atLineStart(text, sel) ? "" : "\n") + "![](img:" + r.id + ")\n"
                let e = EdKit.mdInsert(text, sel, ins)
                text = e.text; sel = e.sel
            }
            ed.structural { p in p.images.append(contentsOf: refs); p.body = JS.prefix(text, Sanitize.mdMaxChars) }
            ctl.select(sel)
        }
    }
}

/// Titre de la barre d'une référence (masculin : « ✓ Validé »).
struct RefTitleBlock: View {
    @Bindable var ed: ReferenceDraft
    @Environment(AppModel.self) private var model
    @Environment(\.widthClass) private var wc
    var body: some View {
        let s = EdSaveText.text(ed.save, at: ed.savedAt, short: wc == .phone)
        var extra: [String] = []
        if ed.parked && !ed.untitled { extra.append("auto-enregistré") }
        if model.auth.signedIn && model.syncStatus.state == .err { extra.append("synchro en attente") }
        let status = EdStatusText.label(ed.d.status, fem: false) + (extra.isEmpty ? "" : " · " + extra.joined(separator: " · "))
        return VStack(spacing: 1) {
            Text(JS.trim(ed.d.title).isEmpty ? "Nouveau protocole" : ed.d.title)
                .aFont(TypeScale.item, .bold).foregroundStyle(T.ink).lineLimit(1)
            HStack(spacing: 6) {
                Text(status).foregroundStyle(ed.d.status == .review ? T.warn : T.ink2)
                if !s.isEmpty {
                    Text("·").foregroundStyle(T.ink3)
                    Text(s).foregroundStyle(ed.save == .err ? T.warn : T.ink2).accessibilityAddTraits(.updatesFrequently)
                }
            }
            .aFont(TypeScale.cap, .semibold)
            .lineLimit(1)
        }
    }
}

// MARK: - Le formulaire

struct ReferenceForm: View {
    @Bindable var ed: ReferenceDraft
    var ctl: EdTextController
    var wide: Bool
    @Environment(AppModel.self) private var model

    var body: some View {
        let p = ed.d
        VStack(alignment: .leading, spacing: 16) {
            if let t = ed.restoredAt {
                EdRestoredNotice(ts: t, canDrop: ed.existsInLibrary) { ed.dropRestored() }
            }
            EdIdentityFold(m: identity, open: $ed.identOpen)
                .edFlash(ed.flashKey == "p-title")
            if !p.docs.isEmpty {
                EdDocsCard(docs: p.docs,
                           attachable: EdKit.attachablePdfs(selfId: p.id, docs: p.docs, library: p.library, fiches: model.fiches, references: model.references).count,
                           resync: ed.syncTick,
                           onRename: { i, v in ed.typing { x in if i < x.docs.count { x.docs[i].name = v } } },
                           onRemove: { i in ed.structural { x in if i < x.docs.count { x.docs.remove(at: i) } } },
                           onAdd: { ed.fileImport = .pdf },
                           onPickExisting: { ed.sheet = .attPicker })
            }
            if !p.links.isEmpty {
                EdLinksCard(links: p.links,
                            candidates: EdKit.relCandidates(selfId: p.id, links: p.links, library: p.library, fiches: model.fiches, references: model.references).count,
                            onRemove: { id in ed.structural { $0.links.removeAll { $0 == id } } },
                            onAdd: { ed.sheet = .links })
            }
            ReferenceBodyCard(ed: ed, ctl: ctl, wide: wide)
            if !p.sources.isEmpty {
                EdCard(title: "Références", hint: "sources du protocole (traçabilité)", flash: ed.flashKey == "p-sources") {
                    RefSourcesEditor(ed: ed)
                }
                .id("p-sources")
            }
            if !wide { ReferenceReviewPanel(ed: ed) }
            Spacer(minLength: 72)
        }
    }
    private var identity: EdIdentityModel {
        EdIdentityModel(
            fiche: false, id: ed.d.id, title: ed.d.title, discriminant: ed.d.discriminant, code: ed.d.code,
            validatedAt: ed.d.validatedAt, category: ed.d.category, library: ed.d.library, status: ed.d.status,
            resync: ed.syncTick, request: ed.focusRequest,
            setTitle: { v in ed.typing { $0.title = v } },
            setDiscriminant: { v in ed.typing { $0.discriminant = v } },
            setCode: { v in ed.typing { $0.code = v } },
            setValidation: { v in ed.structural { $0.validatedAt = v } },
            setStatus: { s in ed.structural { $0.status = s } },
            setLibrary: { lib in
                let cats = ed.model.categories
                ed.structural { p in
                    p.library = lib
                    if !p.category.isEmpty && !cats.contains(where: { $0.id == p.category && $0.library == lib }) { p.category = "" }
                }
            },
            openCategory: { ed.sheet = .category })
    }
}

/// « Contenu rédigé » : barre d'outils Markdown, champ, aide-mémoire, images insérées, aperçu.
struct ReferenceBodyCard: View {
    @Bindable var ed: ReferenceDraft
    var ctl: EdTextController
    var wide: Bool

    var body: some View {
        EdCard(title: "Contenu rédigé", hint: "facultatif — mise en forme simple, aperçu en dessous", flash: ed.flashKey == "p-body") {
            VStack(alignment: .leading, spacing: 10) {
                MarkdownToolbar(ed: ed, ctl: ctl)
                EdTextView(text: ed.d.body, placeholder: "## Indication\n- Critère 1\n- Critère 2\n\nTexte libre, **gras**, *italique*…",
                           accessibility: "Contenu rédigé", minHeight: 260, controller: ctl) { v in
                    ed.typing { $0.body = JS.prefix(v, Sanitize.mdMaxChars) }
                }
                SyntaxHelp()
                ReferenceImagesSection(ed: ed, ctl: ctl)
                if !wide {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Aperçu").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                        EditorMarkdownPreview(markdown: ed.d.body, images: ed.d.images)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(T.amb2.opacity(0.5), in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                    }
                }
            }
        }
        .id("p-body")
    }
}

/// La barre d'outils « Mise en page » : chaque bouton agit sur la SÉLECTION puis rejoue l'écriture.
struct MarkdownToolbar: View {
    @Bindable var ed: ReferenceDraft
    var ctl: EdTextController

    private struct Tool: Identifiable {
        var id: String { aria }
        var glyph: String?
        var icon: String?
        var aria: String
        var help: String
        var act: (String, NSRange) -> EdKit.TextEdit?
    }
    private var tools: [Tool] {
        [
            Tool(glyph: "B", icon: nil, aria: "Gras", help: "Gras — **texte**") { t, s in EdKit.wrapBold(t, s) },
            Tool(glyph: "I", icon: nil, aria: "Italique", help: "Italique — *texte*") { t, s in EdKit.mdWrap(t, s, "*") },
            Tool(glyph: "S", icon: nil, aria: "Surligner", help: "Surligner — ==texte== (neutre : la couleur reste réservée aux registres)") { t, s in EdKit.mdWrap(t, s, "==") },
            Tool(glyph: "H1", icon: nil, aria: "Grand titre", help: "Grand titre — # Titre") { t, s in EdKit.mdPrefixLines(t, s, prefix: "# ") },
            Tool(glyph: "H2", icon: nil, aria: "Titre", help: "Titre — ## Titre") { t, s in EdKit.mdPrefixLines(t, s, prefix: "## ") },
            Tool(glyph: "H3", icon: nil, aria: "Sous-titre", help: "Sous-titre — ### Sous-titre") { t, s in EdKit.mdPrefixLines(t, s, prefix: "### ") },
            Tool(glyph: nil, icon: "list.bullet", aria: "Liste à puces", help: "Liste à puces — - élément (sous-liste : 2 espaces devant)") { t, s in EdKit.mdPrefixLines(t, s, prefix: "- ") },
            Tool(glyph: nil, icon: "list.number", aria: "Liste numérotée", help: "Liste numérotée — 1. élément") { t, s in EdKit.mdPrefixLines(t, s, prefix: "1. ", numbered: true) },
            Tool(glyph: nil, icon: "checklist", aria: "Liste cochable", help: "Liste cochable — - [ ] tâche (- [x] déjà cochée) · coches remises à zéro à chaque ouverture") { t, s in EdKit.mdPrefixLines(t, s, prefix: "- [ ] ") },
            Tool(glyph: nil, icon: "text.quote", aria: "Citation", help: "Citation — > texte") { t, s in EdKit.mdPrefixLines(t, s, prefix: "> ") },
            Tool(glyph: nil, icon: "chevron.left.forwardslash.chevron.right", aria: "Code", help: "Code — `texte` (bloc : ``` sur une ligne)") { t, s in EdKit.mdWrap(t, s, "`") },
            Tool(glyph: nil, icon: "link", aria: "Lien", help: "Lien — [texte](https://…)") { t, s in MarkdownToolbar.link(t, s) },
            Tool(glyph: nil, icon: "exclamationmark.octagon", aria: "Encadré Alerte", help: "Encadré ALERTE (rouge) — > [!CAUTION] texte · ce qui tue si on l'oublie") { t, s in EdKit.mdCallout(t, s, word: "CAUTION") },
            Tool(glyph: nil, icon: "exclamationmark.triangle", aria: "Encadré Attention", help: "Encadré ATTENTION (ambre) — > [!WARNING] texte · là où l'on risque de se tromper") { t, s in EdKit.mdCallout(t, s, word: "WARNING") },
            Tool(glyph: nil, icon: "info.circle", aria: "Encadré Information", help: "Encadré INFORMATION (bleu) — > [!NOTE] texte") { t, s in EdKit.mdCallout(t, s, word: "NOTE") },
            Tool(glyph: nil, icon: "checkmark.circle", aria: "Encadré Confirmation", help: "Encadré CONFIRMATION (vert) — > [!TIP] texte") { t, s in EdKit.mdCallout(t, s, word: "TIP") },
            Tool(glyph: nil, icon: "tablecells", aria: "Tableau", help: "Tableau — | a | b | puis |---|---| (alignement : |:-:| centré, |---:| à droite)") { t, s in
                EdKit.mdInsert(t, s, (EdKit.atLineStart(t, s) ? "" : "\n") + "| Colonne | Colonne |\n|---|---|\n| … | … |\n")
            },
        ]
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tools) { t in button(t) }
                Button { importImage() } label: {
                    Image(systemName: "photo").font(.system(size: 15, weight: .semibold)).foregroundStyle(T.ink2)
                        .frame(width: Ctrl.m, height: Ctrl.m).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Importer une image")
                .help("Importer une NOUVELLE image (réduite et stockée hors ligne) — une image déjà importée se réinsère depuis la liste « Images insérées » sous le texte")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mise en forme")
    }
    @ViewBuilder private func button(_ t: Tool) -> some View {
        Button {
            ctl.onEdit = { v in ed.typing { $0.body = JS.prefix(v, Sanitize.mdMaxChars) } }
            let sel = ctl.view == nil ? NSRange(location: (ed.d.body as NSString).length, length: 0) : ctl.selection
            if let e = t.act(ed.d.body, sel) { ctl.apply(e) }
        } label: {
            Group {
                if let g = t.glyph {
                    Text(g).aFont(TypeScale.body, .heavy)
                } else if let ic = t.icon {
                    Image(systemName: ic).font(.system(size: 15, weight: .semibold))
                }
            }
            .foregroundStyle(T.ink2)
            .frame(minWidth: Ctrl.m, minHeight: Ctrl.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(t.aria)
        .help(t.help)
    }
    /// « Lien » : `[sélection|'texte'](https://)`, l'adresse sélectionnée pour être remplacée.
    static func link(_ text: String, _ sel: NSRange) -> EdKit.TextEdit {
        let v = text as NSString
        let a = max(0, min(sel.location, v.length)), b = max(a, min(sel.location + sel.length, v.length))
        var s = v.substring(with: NSRange(location: a, length: b - a))
        if s.isEmpty { s = "texte" }
        let seg = "[" + s + "](https://)"
        let nv = v.substring(to: a) + seg + v.substring(from: b)
        let urlAt = a + 1 + (s as NSString).length + 2
        return EdKit.TextEdit(text: nv, sel: NSRange(location: urlAt, length: 8))
    }
    private func importImage() {
        if ed.d.images.count >= Guard.maxImgPerEntity { ed.model.toast("⚠ \(Guard.maxImgPerEntity) images maximum par référence.", seconds: 6); return }
        ed.imageChoice = .body
    }
}

/// « Aide-mémoire de syntaxe » — texte repris à l'identique (§25).
struct SyntaxHelp: View {
    @State private var open = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { open.toggle() } label: {
                HStack {
                    Text("Aide-mémoire de syntaxe").aFont(TypeScale.body, .semibold).foregroundStyle(T.act)
                    Spacer()
                    Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundStyle(T.act)
                }
                .frame(minHeight: Ctrl.m).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if open {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Syntaxe : # titre (##, ###), - liste / 1. liste (sous-liste : 2 espaces devant), - [ ] tâche liste cochable (- [x] déjà cochée) — en lecture, les coches repartent à zéro à chaque ouverture, > citation, `code` (bloc : ```), --- séparateur, **gras**, *italique*, ==surligné==, [texte](https://…), [texte](att:ID) ouvre un document joint, ![légende](img:ID) image (taille réglable ci-dessous).")
                    Text("Tableau : | a | b | puis, en 2ᵉ ligne, |---|---| — l'alignement se règle là (|:-:| centré, |---:| à droite). Un | dans une cellule s'écrit \\|.")
                    Text("Encadré coloré — syntaxe GitHub, tapable au clavier, le marqueur seul sur sa ligne puis le texte en dessous : > [!CAUTION] alerte · > [!WARNING] attention · > [!NOTE] information · > [!TIP] confirmation (les boutons ci-dessus les posent). Alias acceptés ici : [!alerte], [!attention], [!info], [!ok], et les glyphes ⚠ △ ℹ ✓.")
                    Text("Portabilité : les mots-clés en MAJUSCULES sont rendus en encadré par GitHub, GitLab, pandoc et Typora, et - [ ] en case native ; ailleurs, encadrés et tâches restent une citation ou un « [ ] tâche » lisibles — rien n'est jamais perdu.")
                        .foregroundStyle(T.ink3)
                }
                .aFont(TypeScale.meta, .regular)
                .foregroundStyle(T.ink2)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// « Images insérées » (`mdImagesHtml`) — TOUJOURS montrée (exception nommée : l'image n'est pas
/// dans la porte « ＋ »). Taille d'affichage au jeu fermé 25…100 %.
struct ReferenceImagesSection: View {
    @Bindable var ed: ReferenceDraft
    var ctl: EdTextController

    var body: some View {
        let used = EdKit.referencedImageIds(ed.d.body)
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(ed.d.images.isEmpty ? "Images" : "Images insérées").aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                Text("taille d'affichage — s'applique au-dessus de 560 px de large").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
            }
            ForEach(Array(ed.d.images.enumerated()), id: \.element.id) { i, im in
                HStack(alignment: .top, spacing: 10) {
                    Button { insert(im) } label: {
                        EdDataImage(key: im.id, dataURI: im.data)
                            .frame(width: 88, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Insérer une nouvelle référence à cette image")
                    .help("Insérer une nouvelle référence à cette image")
                    VStack(alignment: .leading, spacing: 6) {
                        Text(im.caption.isEmpty ? "Image \(i + 1)" : im.caption).aFont(TypeScale.body, .semibold).foregroundStyle(T.ink)
                        HStack(spacing: 8) {
                            Button("＋ Insérer dans le texte") { insert(im) }
                                .buttonStyle(.a(.secondary, Ctrl.s))
                                .help("Insère ![](img:…) à l'endroit du curseur — une image peut illustrer plusieurs passages")
                            Picker("Taille", selection: Binding<Int>(
                                get: { im.scale },
                                set: { v in ed.structural { p in if let k = p.images.firstIndex(where: { $0.id == im.id }) { p.images[k].scale = v } } })) {
                                ForEach(Sanitize.mdScales, id: \.self) { s in Text("\(s) %").tag(s) }
                            }
                            .pickerStyle(.menu)
                            .accessibilityLabel("Taille")
                        }
                        if !used.contains(im.id) {
                            Text("△ absente du texte — sera retirée en quittant l'éditeur").aFont(TypeScale.meta, .semibold).foregroundStyle(T.warn)
                        }
                    }
                }
            }
            EdDropZone(title: "Ajouter une image / capture", sub: "PNG · JPEG · WebP · HEIC — glissez ici ou cliquez · plusieurs à la fois") {
                if ed.d.images.count >= Guard.maxImgPerEntity { ed.model.toast("⚠ \(Guard.maxImgPerEntity) images maximum par référence.", seconds: 6); return }
                ed.imageChoice = .body
            }
        }
    }
    /// Réinsère `![](img:ID)` au curseur, sur sa propre ligne.
    private func insert(_ im: ImageRef) {
        let t = ed.d.body
        let sel = ctl.view == nil ? NSRange(location: (t as NSString).length, length: 0) : ctl.selection
        ctl.onEdit = { v in ed.typing { $0.body = JS.prefix(v, Sanitize.mdMaxChars) } }
        ctl.apply(EdKit.mdInsert(t, sel, (EdKit.atLineStart(t, sel) ? "" : "\n") + "![](img:" + im.id + ")\n"))
    }
}

/// Sources d'une référence (liste simple).
struct RefSourcesEditor: View {
    @Bindable var ed: ReferenceDraft
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(ed.d.sources.enumerated()), id: \.offset) { i, s in
                HStack(spacing: 6) {
                    EdField(value: s, placeholder: "…", label: "Références — ligne \(i + 1)", focusKey: "src:\(i)", request: ed.focusRequest,
                            resync: ed.syncTick) { v in ed.typing { p in if i < p.sources.count { p.sources[i] = v } } }
                    EdIconButton(system: "xmark", label: "Supprimer la ligne") {
                        ed.structural { p in
                            if i < p.sources.count { p.sources.remove(at: i) }
                            if p.sources.isEmpty { p.sources = [""] }
                        }
                    }
                }
            }
            EdLinkButton(text: "+ Ajouter une ligne") {
                let n = ed.d.sources.count
                ed.structural { $0.sources.append("") }
                ed.requestFocus("src:\(n)")
            }
        }
    }
}

struct ReferenceReviewPanel: View {
    @Bindable var ed: ReferenceDraft
    var body: some View {
        EdReviewPanel(notes: EdKit.reviewNotesProto(ed.d), offers: [],
                      onGo: { at in
                          // Question ouverte n° 3 : les ancres mortes du web mènent ici au champ visé.
                          if at == "p-sources" && ed.d.sources.isEmpty { ed.structural { $0.sources = [""] } }
                          ed.goFlash(at)
                      },
                      onTake: { _ in }, onDismiss: { _ in })
    }
}

/// La porte « ＋ » d'une référence.
struct ReferenceDoor: View {
    @Bindable var ed: ReferenceDraft
    var body: some View {
        Button { ed.sheet = .palette } label: {
            HStack(spacing: 12) {
                Text("＋").aFont(TypeScale.stepL, .bold).foregroundStyle(T.onPrimary)
                    .frame(width: Ctrl.m, height: Ctrl.m).background(T.act, in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text("Ajouter à cette référence").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                    Text("document · voir aussi · référence").aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: 760, minHeight: Ctrl.xl)
            .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.workLine))
            .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .accessibilityLabel("Ajouter à cette référence")
    }
}

/// Porte d'une référence (`ED_PALETTE_P`). Titre repris du web (question ouverte n° 1).
struct ReferencePaletteSheet: View {
    @Bindable var ed: ReferenceDraft
    var ctl: EdTextController
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        EdSheetShell(title: "Ajouter à la fiche") {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if JS.trim(ed.d.body).isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Overline(text: "Contenu")
                            EdMenuRow(icon: "doc.text", title: "Contenu rédigé", sub: "titres, listes, tableaux") {
                                close()
                                ed.scrollTo("p-body")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { ctl.select(NSRange(location: 0, length: 0)) }
                            }
                            .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Overline(text: "Annexes")
                        EdMenuRow(icon: "doc.text", title: "Document (PDF)", sub: "lisible hors ligne") {
                            close()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { ed.fileImport = .pdf }
                        }
                        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                        EdMenuRow(icon: "book", title: "Voir aussi", sub: "renvoi vers une autre fiche") {
                            close()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { ed.sheet = .links }
                        }
                        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                        EdMenuRow(icon: "book", title: "Référence", sub: "source citée") {
                            close()
                            let n = ed.d.sources.count
                            ed.structural { $0.sources.append("") }
                            ed.scrollTo("p-sources")
                            ed.requestFocus("src:\(n)")
                        }
                        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                    }
                }
                .padding(16)
            }
        }
    }
    private func close() { dismiss(); ed.sheet = nil }
}
