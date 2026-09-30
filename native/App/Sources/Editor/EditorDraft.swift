import SwiftUI
import Observation
import AidesCore

// L'ÉTAT D'UNE SÉANCE D'ÉDITION — port de `state.draft`/`state.pdraft`, `draftBase`,
// `edTouch`/`edCommit`/`edSnapshot` (K5 : l'enregistrement se DIT, il ne se demande pas),
// `edUndoNote`/`edUndoDo` (anneau d'annulation), `parkDraftNow`/`clearDraftParkIf` (parc des
// brouillons), `purgeDraftAtts`, `redirtyAttsOnLibChange`.
//
// DEUX ACCROCHES, ET DEUX SEULEMENT (comme la PWA) : toute mutation passe par `typing { }`
// (frappe : écriture à la PAUSE, 420 ms) ou `structural { }` (geste : point de reprise + écriture
// immédiate). Chercher un à un les cinquante gestes de mutation produirait une liste à tenir à
// jour ; les deux points d'étranglement couvrent tout geste ajouté demain.

/// État d'enregistrement affiché dans la barre (`edSaySave`).
enum EdSaveState: Equatable { case none, saving, saved, err, untitled }

/// Listes réordonnables par « prendre / poser » (`state.edGrab.key`).
enum EdListKind: String, Equatable {
    case notForget, confirmation, posology, verify, differentials, sources, timers, counters, excursions
    var poolKey: EdKit.ListKey? {
        switch self {
        case .confirmation: return .confirmation
        case .posology: return .posology
        case .verify: return .verify
        case .differentials: return .differentials
        default: return nil
        }
    }
}

/// L'objet « en main » (`state.edGrab`) — transitoire, jamais persisté.
enum EdGrab: Equatable {
    case block(String)
    case step(block: String, item: String)
    case list(EdListKind, Int)
}

/// Demande ponctuelle (focus, défilement, éclair) : le `n` la rend unique même si la clé se répète.
struct EdRequest: Equatable {
    var key: String
    var n: Int
}

/// Fenêtres de l'éditeur d'aide (une seule à la fois, comme les `.ai-modal` de la PWA).
enum FicheSheet: Identifiable, Equatable {
    case palette
    case step(block: String, item: String)
    case links
    case cxTarget(Int)
    case attPicker
    case versions
    case category
    var id: String {
        switch self {
        case .palette: return "palette"
        case .step(let b, let i): return "step:" + b + ":" + i
        case .links: return "links"
        case .cxTarget(let i): return "cx:" + String(i)
        case .attPicker: return "att"
        case .versions: return "versions"
        case .category: return "category"
        }
    }
}
/// Fenêtres de l'éditeur de référence.
enum ReferenceSheet: Identifiable, Equatable {
    case palette, links, attPicker, category
    var id: String {
        switch self {
        case .palette: return "palette"
        case .links: return "links"
        case .attPicker: return "att"
        case .category: return "category"
        }
    }
}
/// Où va une image importée : la galerie (fiche), un bloc, ou le texte d'une référence.
enum EdImageTarget: Equatable { case gallery, block(String), body }
/// Le sélecteur de fichier unique (un seul `.fileImporter` par écran : plusieurs se contrarient).
enum EdImport: Equatable { case pdf, image(EdImageTarget) }

/// Intervalles de la PWA.
enum EdTiming {
    static let saveMs: UInt64 = 420          // ED_SAVE_MS
    static let parkMs: UInt64 = 2500         // intervalle du parc
    static let undoMax = 20                  // ED_UNDO_MAX
    static let flashMs: UInt64 = 1300        // revGoFlash
}

// MARK: - Aide cognitive

@MainActor
@Observable
final class FicheDraft {
    @ObservationIgnored let model: AppModel
    /// Le brouillon VIVANT (lignes vides comprises) — jamais normalisé en place.
    var d: Fiche
    /// Heure du brouillon parqué restauré à l'ouverture (`state.draftRestored`).
    var restoredAt: Double?
    /// Blobs PDF ajoutés pendant cette séance, pas encore référencés par du publié (`draftNewAtts`).
    var newAtts: [String] = []
    var save: EdSaveState = .none
    var savedAt: Double = 0
    /// « auto-enregistré » : le parc a pris le brouillon (titré) depuis la dernière écriture.
    var parked = false
    private(set) var undo: [JSON] = []
    var grab: EdGrab?
    /// Bat à chaque changement NON tapé (geste, annulation, restauration) : les champs se recalent
    /// alors même qu'ils ont le focus (le texte qu'ils montrent a changé sous eux).
    var syncTick = 0

    // Transitoire d'interface (jamais persisté)
    var identOpen = true
    var tocOpen = false
    var blockOptOpen: [String: Bool] = [:]
    var phaseNewFor: String?
    var offersDismissed: Set<String> = []
    var focusRequest: EdRequest?
    var scrollRequest: EdRequest?
    var flashKey: String?
    var noteEditing = false
    var sheet: FicheSheet?
    var fileImport: EdImport?
    var photoTarget: EdImageTarget?
    /// Choix « Photothèque / Fichiers » en attente pour une image.
    var imageChoice: EdImageTarget?
    var askDelete = false
    /// Aperçu « ▶ Essayer » ouvert (brouillon figé au moment de l'ouverture).
    var trial: Fiche?
    @ObservationIgnored private var reqN = 0

    @ObservationIgnored private var prev: JSON?
    /// Instantané à l'ouverture (`draftBase`) ; nil pour un brouillon de création repris.
    @ObservationIgnored var base: JSON?
    @ObservationIgnored private var lastParked: JSON?
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    /// Brouillon (brut) au dernier commit réussi.
    @ObservationIgnored private var lastWritten: JSON?

    init(model: AppModel, draft: Fiche, base: JSON?) {
        self.model = model
        self.d = draft
        self.base = base
        self.prev = draft.json
    }

    // MARK: Lecture

    var existsInLibrary: Bool { model.fiches.contains { $0.id == d.id } }
    var untitled: Bool { JS.trim(d.title).isEmpty }
    var grabbing: Bool { grab != nil }
    func block(_ id: String) -> Block? { d.blocks.first { $0.id == id } }
    func item(_ id: String) -> Item? { d.items.first { $0.id == id } }

    // MARK: Les deux accroches

    /// Frappe : le brouillon change, l'écriture attend la pause.
    func typing(_ mutate: (inout Fiche) -> Void) {
        mutate(&d)
        touch(now: false)
    }
    /// Geste structurel : point de reprise (l'état d'AVANT) puis écriture immédiate.
    func structural(_ mutate: (inout Fiche) -> Void) {
        mutate(&d)
        syncTick &+= 1
        undoNote()
        touch(now: true)
    }
    func updateBlock(_ id: String, typing isTyping: Bool, _ f: (inout Block) -> Void) {
        if isTyping {
            typing { fi in if let i = fi.blocks.firstIndex(where: { $0.id == id }) { f(&fi.blocks[i]) } }
        } else {
            structural { fi in if let i = fi.blocks.firstIndex(where: { $0.id == id }) { f(&fi.blocks[i]) } }
        }
    }
    func updateItem(_ id: String, typing isTyping: Bool, _ f: (inout Item) -> Void) {
        if isTyping {
            typing { fi in if let i = fi.items.firstIndex(where: { $0.id == id }) { f(&fi.items[i]) } }
        } else {
            structural { fi in if let i = fi.items.firstIndex(where: { $0.id == id }) { f(&fi.items[i]) } }
        }
    }

    // MARK: Écriture continue (`edTouch`, `edCommit`)

    /// `edTouch(now)`. SANS TITRE, ON LE DIT — avant le test « rien n'a bougé ».
    func touch(now: Bool) {
        if untitled { saveTask?.cancel(); save = .untitled; return }
        if let base, d.json == base { return }
        saveTask?.cancel()
        if now { commit(); return }
        save = .saving
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: EdTiming.saveMs * 1_000_000)
            guard let self, !Task.isCancelled else { return }
            self.undoNote()
            self.commit()
        }
    }

    /// `edCommit('f')` : UN SEUL point d'écriture — une copie NORMALISÉE, jamais le brouillon.
    @discardableResult
    func commit() -> Bool {
        let snap = EdKit.snapshot(d)
        if snap.title.isEmpty { save = .untitled; return false }
        let orig = model.fiches.first { $0.id == snap.id }
        save = .saving
        guard model.save(snap) else { save = .err; return false }
        FicheDraft.redirtyAttachments(model: model, docs: snap.docs, from: orig?.library, to: snap.library, existed: orig != nil)
        newAtts = []
        clearParkIf()
        lastParked = nil
        lastWritten = d.json
        parked = false
        savedAt = JS.now()
        save = .saved
        return true
    }

    /// `edFlush()` : la frappe peut être plus récente que la dernière pause. Écart assumé : rien
    /// n'est réécrit si le brouillon égale ce qui est DÉJÀ écrit (la PWA réécrivait toujours,
    /// ce qui touchait `updatedAt` à la simple sortie d'un éditeur seulement regardé).
    func flush() {
        saveTask?.cancel(); saveTask = nil
        if let ref = lastWritten ?? base, d.json == ref { return }
        commit()
    }

    /// `redirtyAttsOnLibChange` : le chemin cloud des PDF encode le périmètre — au changement de
    /// bibliothèque, leurs blobs repartent « à pousser ».
    static func redirtyAttachments(model: AppModel, docs: [Attachment], from: String?, to: String?, existed: Bool) {
        guard existed, from != to else { return }
        for a in docs {
            if var r = model.library.space.attachmentRecord(a.id) {
                r.dirty = true
                model.library.space.updateAttachmentRecord(r)
            }
        }
    }

    // MARK: Anneau d'annulation (`edUndoNote`, `edUndoDo`)

    func undoNote() {
        let snap = d.json
        guard let p = prev else { prev = snap; return }
        if p == snap { return }
        undo.append(p)
        if undo.count > EdTiming.undoMax { undo.removeFirst() }
        prev = snap
    }
    /// Annuler le dernier geste : la donnée qui rentre repasse par `migrate` (règle 5), et on
    /// ÉCRIT toujours (annuler jusqu'à l'état d'ouverture doit publier l'original).
    func undoLast() {
        guard let snap = undo.popLast() else { return }
        saveTask?.cancel()
        d = Sanitize.fiche(snap)
        grab = nil
        prev = d.json
        syncTick &+= 1
        commit()
        model.toast("↶ Geste annulé.", seconds: 2)
    }

    // MARK: Parc des brouillons (A §15)

    /// Toutes les 2,5 s : si le brouillon diffère de l'ouverture ET du dernier parcage, on le parque.
    func parkTick() {
        let snap = d.json
        if let base, snap == base { return }
        if let lastParked, snap == lastParked { return }
        parkNow()
    }
    func parkNow() {
        let snap = d.json
        lastParked = snap
        let slot: JSON = .object([
            "forId": .string(d.id), "isNew": .bool(!existsInLibrary), "draft": snap,
            "newAtts": .array(newAtts.map { .string($0) }), "ts": .number(JS.now()),
        ])
        model.library.setDraftPark("f", slot)
        parked = !untitled
    }
    /// `clearDraftParkIf('f', id)` : seulement si l'emplacement concerne CE brouillon.
    func clearParkIf() {
        if model.library.draftPark("f")?["forId"]?.string == d.id { model.library.setDraftPark("f", nil) }
    }

    /// « Repartir de la version enregistrée » (sortie du brouillon restauré).
    func dropRestored() {
        guard let orig = model.fiches.first(where: { $0.id == d.id }) else { return }
        clearParkIf()
        saveTask?.cancel()
        d = orig
        newAtts = []
        base = d.json
        lastParked = nil
        prev = d.json
        restoredAt = nil
        parked = false
        lastWritten = nil
        syncTick &+= 1
    }
    /// Après une restauration de version : le brouillon repart de la version restaurée.
    func reload(from f: Fiche) {
        saveTask?.cancel()
        d = f
        base = d.json
        prev = d.json
        lastParked = nil
        lastWritten = nil
        parked = false
        syncTick &+= 1
    }

    // MARK: Sortie (`bindEditorExit`)

    /// Écrit ce qui reste, puis nettoie ce qui ne se ramasse qu'à la SORTIE : un brouillon jamais
    /// entré dans la bibliothèque perd son emplacement de parc, ses blobs PDF orphelins et sa note.
    func leave() {
        flush()
        if !existsInLibrary {
            clearParkIf()
            FicheDraft.purgeAttachments(model: model, ids: newAtts)
            newAtts = []
            model.saveNote(d.id, "")
        } else if let f = model.fiches.first(where: { $0.id == d.id }), let c = model.current, c.ficheId == d.id, !c.started {
            // La lecture qu'on retrouve en revenant repart de la version ÉCRITE (`openRead`
            // reconstruit son Runtime) : l'aide non démarrée ne garde pas l'ancienne structure.
            model.current = model.engine.runtimeFor(f, keepIfNotStarted: nil)
            model.touch()
        }
    }
    /// `purgeDraftAtts()` : retire les blobs ajoutés pendant une édition abandonnée, sauf s'ils
    /// sont référencés par une entité publiée.
    static func purgeAttachments(model: AppModel, ids: [String]) {
        guard !ids.isEmpty else { return }
        var ref = Set<String>()
        for f in model.library.allFiches { for a in f.docs { ref.insert(a.id) } }
        for p in model.library.allProtocols { for a in p.docs { ref.insert(a.id) } }
        for id in ids where !ref.contains(id) { model.library.space.deleteAttachment(id) }
    }

    // MARK: Demandes ponctuelles d'interface

    func requestFocus(_ key: String) { reqN += 1; focusRequest = EdRequest(key: key, n: reqN) }
    /// Amène un élément à l'écran et le fait clignoter UNE fois (`revGoFlash`), sans voler le curseur.
    func goFlash(_ key: String) {
        reqN += 1
        scrollRequest = EdRequest(key: key, n: reqN)
        flashKey = key
        let k = key
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: EdTiming.flashMs * 1_000_000)
            if self?.flashKey == k { self?.flashKey = nil }
        }
    }
    func scrollTo(_ key: String) { reqN += 1; scrollRequest = EdRequest(key: key, n: reqN) }

    // MARK: Gestes structurels partagés

    /// Nouvelle étape vide à la position `i` d'un bloc ; focus sur elle.
    func addStep(block bid: String, at i: Int) {
        let it = EdKit.newStepItem()
        structural { f in EdKit.bItemAdd(&f, blockId: bid, at: i, it) }
        requestFocus("s:" + it.id)
    }
    /// Supprime une étape (jamais la dernière d'un bloc : une vide la remplace).
    func deleteStep(block bid: String, item iid: String) {
        structural { f in
            EdKit.bItemDel(&f, blockId: bid, itemId: iid)
            if let b = f.blocks.first(where: { $0.id == bid }), b.items.isEmpty {
                EdKit.bItemAdd(&f, blockId: bid, at: 0, EdKit.newStepItem())
            }
        }
    }
    /// §6.8 — supprimer un bloc : suites et cibles vers lui remises à « fin », départ réparé.
    /// Écart assumé : les étapes non-★ du bloc quittent aussi le pool (la PWA les y laissait,
    /// invisibles) ; les ★ restent, comme sur le web, en rappels de portée fiche.
    func deleteBlock(_ bid: String) {
        structural { f in
            guard let b = f.blocks.first(where: { $0.id == bid }) else { return }
            let own = Set(b.items)
            f.blocks.removeAll { $0.id == bid }
            let stillRef = Set(f.blocks.flatMap(\.items))
            f.items.removeAll { own.contains($0.id) && !stillRef.contains($0.id) && !$0.memory }
            for i in f.blocks.indices {
                if f.blocks[i].next == bid { f.blocks[i].next = nil }
                for j in f.blocks[i].options.indices where f.blocks[i].options[j].target == bid { f.blocks[i].options[j].target = nil }
            }
            for i in f.items.indices where f.items[i].review == bid { f.items[i].review = nil }
            if f.start == bid { f.start = f.blocks.first?.id }
            if f.blocks.isEmpty {
                let nb = EdKit.newDoBlock(&f, title: "Prise en charge")
                f.start = nb
            }
        }
    }
}

// MARK: - Référence (protocole)

@MainActor
@Observable
final class ReferenceDraft {
    @ObservationIgnored let model: AppModel
    var d: Reference
    var restoredAt: Double?
    var newAtts: [String] = []
    var save: EdSaveState = .none
    var savedAt: Double = 0
    var parked = false
    private(set) var undo: [JSON] = []
    var syncTick = 0
    var identOpen = true
    var focusRequest: EdRequest?
    var scrollRequest: EdRequest?
    var flashKey: String?
    /// Sélection courante du champ « Contenu rédigé » (unités UTF-16).
    var bodySelection = NSRange(location: 0, length: 0)
    var sheet: ReferenceSheet?
    var fileImport: EdImport?
    var photoTarget: EdImageTarget?
    /// Choix « Photothèque / Fichiers » en attente pour une image.
    var imageChoice: EdImageTarget?
    var askDelete = false
    var trial: Reference?
    @ObservationIgnored private var reqN = 0
    @ObservationIgnored private var prev: JSON?
    @ObservationIgnored var base: JSON?
    @ObservationIgnored private var lastParked: JSON?
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    /// Brouillon (brut) au dernier commit réussi.
    @ObservationIgnored private var lastWritten: JSON?

    init(model: AppModel, draft: Reference, base: JSON?) {
        self.model = model
        self.d = draft
        self.base = base
        self.prev = draft.json
    }

    var existsInLibrary: Bool { model.references.contains { $0.id == d.id } }
    var untitled: Bool { JS.trim(d.title).isEmpty }

    func typing(_ mutate: (inout Reference) -> Void) { mutate(&d); touch(now: false) }
    func structural(_ mutate: (inout Reference) -> Void) { mutate(&d); syncTick &+= 1; undoNote(); touch(now: true) }

    func touch(now: Bool) {
        if untitled { saveTask?.cancel(); save = .untitled; return }
        if let base, d.json == base { return }
        saveTask?.cancel()
        if now { commit(); return }
        save = .saving
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: EdTiming.saveMs * 1_000_000)
            guard let self, !Task.isCancelled else { return }
            self.undoNote()
            self.commit()
        }
    }
    @discardableResult
    func commit() -> Bool {
        let snap = EdKit.snapshot(d)
        if snap.title.isEmpty { save = .untitled; return false }
        let orig = model.references.first { $0.id == snap.id }
        save = .saving
        guard model.save(snap) else { save = .err; return false }
        FicheDraft.redirtyAttachments(model: model, docs: snap.docs, from: orig?.library, to: snap.library, existed: orig != nil)
        newAtts = []
        clearParkIf()
        lastParked = nil
        lastWritten = d.json
        parked = false
        savedAt = JS.now()
        save = .saved
        return true
    }
    func flush() {
        saveTask?.cancel(); saveTask = nil
        if let ref = lastWritten ?? base, d.json == ref { return }
        commit()
    }
    func undoNote() {
        let snap = d.json
        guard let p = prev else { prev = snap; return }
        if p == snap { return }
        undo.append(p)
        if undo.count > EdTiming.undoMax { undo.removeFirst() }
        prev = snap
    }
    func undoLast() {
        guard let snap = undo.popLast() else { return }
        saveTask?.cancel()
        d = Sanitize.reference(snap)
        prev = d.json
        syncTick &+= 1
        commit()
        model.toast("↶ Geste annulé.", seconds: 2)
    }
    func parkTick() {
        let snap = d.json
        if let base, snap == base { return }
        if let lastParked, snap == lastParked { return }
        lastParked = snap
        let slot: JSON = .object([
            "forId": .string(d.id), "isNew": .bool(!existsInLibrary), "draft": snap,
            "newAtts": .array(newAtts.map { .string($0) }), "ts": .number(JS.now()),
        ])
        model.library.setDraftPark("p", slot)
        parked = !untitled
    }
    func clearParkIf() {
        if model.library.draftPark("p")?["forId"]?.string == d.id { model.library.setDraftPark("p", nil) }
    }
    func dropRestored() {
        guard let orig = model.references.first(where: { $0.id == d.id }) else { return }
        clearParkIf()
        saveTask?.cancel()
        d = orig
        newAtts = []
        base = d.json
        lastParked = nil
        prev = d.json
        restoredAt = nil
        parked = false
        lastWritten = nil
        syncTick &+= 1
    }
    /// Sortie : écriture, puis ménage DESTRUCTIF qu'on ne fait qu'ici — les images de la galerie
    /// que plus aucune ligne `![](img:ID)` ne référence (`leaveGC`), et les blobs d'un brouillon
    /// jamais publié.
    func leave() {
        flush()
        let used = EdKit.referencedImageIds(d.body)
        if d.images.contains(where: { !used.contains($0.id) }) {
            d.images.removeAll { !used.contains($0.id) }
            if existsInLibrary { commit() }
        }
        if !existsInLibrary {
            clearParkIf()
            FicheDraft.purgeAttachments(model: model, ids: newAtts)
            newAtts = []
        }
    }
    func requestFocus(_ key: String) { reqN += 1; focusRequest = EdRequest(key: key, n: reqN) }
    func scrollTo(_ key: String) { reqN += 1; scrollRequest = EdRequest(key: key, n: reqN) }
    func goFlash(_ key: String) {
        reqN += 1
        scrollRequest = EdRequest(key: key, n: reqN)
        flashKey = key
        let k = key
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: EdTiming.flashMs * 1_000_000)
            if self?.flashKey == k { self?.flashKey = nil }
        }
    }
}

// MARK: - Portes d'entrée de l'éditeur (pour les autres zones : accueil, « Créer », lecture)

extension AppModel {
    /// `newFiche()` : ouvre l'éditeur sur une aide NEUVE dans `library` (nil = Perso).
    /// Le contrôle des droits et la confirmation « Publier dans la bibliothèque partagée » (texte
    /// dans `EditorTexts.confirmNewInLib`) restent à l'appelant, qui connaît la bibliothèque affichée.
    func startNewFiche(library: String?) {
        let id = Guard.uid()
        editorNewScopes[id] = library ?? ""
        path.append(.editFiche(id))
    }
    /// `newProtocol()`.
    func startNewReference(library: String?) {
        let id = Guard.uid("p")
        editorNewScopes[id] = library ?? ""
        path.append(.editReference(id))
    }
    /// Brouillon de CRÉATION parqué (carte « Reprendre le brouillon en cours ») : kind "f" ou "p".
    func parkedNewDraft(kind: String) -> (id: String, title: String, ts: Double)? {
        guard let slot = library.draftPark(kind), slot["isNew"]?.truthy == true,
              let id = slot["forId"]?.string, Guard.isSafeId(id) else { return nil }
        let t = JS.trim(slot["draft"]?["title"]?.string ?? "")
        return (id, t.isEmpty ? "Sans titre" : t, slot["ts"]?.number ?? 0)
    }
    /// « Reprendre le brouillon en cours » : l'éditeur retrouve l'emplacement par son id.
    func resumeParkedDraft(kind: String) {
        guard let p = parkedNewDraft(kind: kind) else { return }
        path.append(kind == "p" ? .editReference(p.id) : .editFiche(p.id))
    }
    /// `openEdit(id)` : droits vérifiés ici ; la question « Terminer la session et modifier ? »
    /// est posée par l'éditeur lui-même (donc aussi quand on y arrive par un autre chemin).
    func openFicheEditor(_ id: String) {
        guard let f = fiches.first(where: { $0.id == id }) else { toast("⚠ Fiche introuvable."); return }
        if !library.canEdit(f) { toast(EditorTexts.readOnly); return }
        path.append(.editFiche(id))
    }
    func openReferenceEditor(_ id: String) {
        guard let p = references.first(where: { $0.id == id }) else { return }
        if !library.canEdit(p) { toast(EditorTexts.readOnly); return }
        path.append(.editReference(id))
    }
}

/// Textes partagés (verbatim de la PWA).
enum EditorTexts {
    static let readOnly = "Lecture seule : vous n'avez pas les droits d'édition sur cette bibliothèque."
    static let roNewFiche = "Lecture seule : vous ne pouvez pas créer de fiche dans cette bibliothèque."
    static let roNewReference = "Lecture seule : vous ne pouvez pas créer de protocole dans cette bibliothèque."
    /// `confirmNewInLib(lib, fem)` : (titre, message, oui).
    static func confirmNewInLib(_ libName: String, fiche: Bool) -> (title: String, message: String, yes: String) {
        let n = libName.isEmpty ? "la bibliothèque partagée" : libName
        return ("Publier dans la bibliothèque partagée",
                fiche ? "Cette fiche va être créée dans « \(n) » : elle sera visible par tous les membres."
                      : "Ce protocole va être créé dans « \(n) » : il sera visible par tous les membres.",
                fiche ? "Créer la fiche" : "Créer le protocole")
    }
    /// Horodatage court « HH:MM » / « HH:MM:SS ».
    static func hm(_ t: Double) -> String { Fmt.hm(t) }
}
