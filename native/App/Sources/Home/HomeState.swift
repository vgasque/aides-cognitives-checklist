import SwiftUI
import Observation
import AidesCore

// ÉTAT DE L'ACCUEIL (C1 §3.2) et CORPUS AFFICHABLE (§3.1, §3.7.1).
// L'état de VUE (onglet, filtres, requête, sélection) vit le temps de l'écran, comme dans la
// PWA (`state.homeTab`, `homeLib`, `cat`, `q`, `selOn`) ; les réglages de PRÉSENTATION
// (type affiché, rangement, tri, densité) sont persistés par espace (clés `ac-section`,
// `ac-home-group`, `ac-home-sort`, `ac-home-compact`).

enum HomeTab: String { case aides, sessions, me }

/// Type affiché (« Afficher »), `state.section`.
enum HomeSection: String, CaseIterable {
    case all, fiches, protocols
    /// `SEC_T` : libellés des puces de recherche.
    var chip: String { switch self { case .all: return "Tout"; case .fiches: return "Aides"; case .protocols: return "Protocoles" } }
}
/// `HOME_GROUPS`.
enum HomeGroup: String, CaseIterable {
    case none, kind, cat, bib, az
    /// Libellés du segmenté « Regrouper ».
    var seg: String { switch self { case .none: return "Non"; case .kind: return "Type"; case .cat: return "Catég."; case .bib: return "Biblio."; case .az: return "A–Z" } }
    /// Mot de l'aria « Affichage — rangé par … ».
    var word: String { switch self { case .none: return "aucun"; case .kind: return "type"; case .cat: return "catégorie"; case .bib: return "bibliothèque"; case .az: return "A–Z" } }
}
enum HomeSort: String, CaseIterable { case alpha, recent }

/// Fenêtre que l'accueil doit ouvrir en arrivant (demandée par l'écran de bienvenue, dont les
/// portes s'ouvrent APRÈS qu'il a cédé la place à l'accueil).
enum HomeRequest: Equatable { case create, account, join }

@MainActor
@Observable
final class HomeState {
    var tab: HomeTab = .aides
    var section: HomeSection = .all
    /// « Afficher : À relire ».
    var rev = false
    /// Filtre de BIBLIOTHÈQUE : nil = toutes (défaut), '' = Perso, sinon l'id.
    var lib: String? = nil
    /// Filtre de CATÉGORIE : NOM normalisé (`txNorm`) ; nil = toutes.
    var cat: String? = nil
    var q = ""
    var group: HomeGroup = .cat
    var sort: HomeSort = .alpha
    var compact = false
    /// Pagination des résultats de recherche (`LIB_PAGE = 60`).
    var libLimit = 60
    var selOn = false
    var sel: Set<String> = []

    init() {}

    /// Relit les réglages persistés de l'espace courant.
    func load(from model: AppModel) {
        let p = model.library.space.prefs
        section = HomeSection(rawValue: p.string("ac-section") ?? "") ?? .all
        group = HomeGroup(rawValue: p.string("ac-home-group") ?? "") ?? .cat
        sort = HomeSort(rawValue: p.string("ac-home-sort") ?? "") ?? .alpha
        compact = p.string("ac-home-compact") == "1"
    }

    /// Nombre de filtres actifs (badge du bouton rond, `filtersList`).
    var activeFilterCount: Int {
        (rev || section != .all ? 1 : 0) + (lib != nil ? 1 : 0) + (cat != nil ? 1 : 0)
    }
    /// `dropFilter('all')`.
    func dropAllFilters() { rev = false; section = .all; lib = nil; cat = nil }
    func endSelection() { selOn = false; sel = [] }
}

// MARK: - Élément de liste (aide ou référence)

/// Une rangée de l'accueil : l'union des aides et des références (`renderAll`).
struct HItem: Identifiable {
    let id: String
    let fiche: Fiche?
    let ref: Reference?
    var isFiche: Bool { fiche != nil }
    var title: String { fiche?.title ?? ref?.title ?? "" }
    var displayTitle: String { title.isEmpty ? "Sans titre" : title }
    var code: String { fiche?.code ?? ref?.code ?? "" }
    var discriminant: String { fiche?.discriminant ?? "" }
    var category: String { fiche?.category ?? ref?.category ?? "" }
    var library: String? { fiche?.library ?? ref?.library }
    /// '' = Perso (clé de bibliothèque du web).
    var libKey: String { library ?? "" }
    var status: Status { fiche?.status ?? ref?.status ?? .validated }
    var validatedAt: String { fiche?.validatedAt ?? ref?.validatedAt ?? "" }
    var docCount: Int { fiche?.docs.count ?? ref?.docs.count ?? 0 }
    /// « À relire » (§3.7.1) : brouillon, à revérifier, ou validation de plus de 2 ans.
    var needsReview: Bool { status == .draft || status == .review || (status == .validated && HomeSearch.staleDate(validatedAt)) }
}

/// Le corpus VISIBLE (règle de visibilité : un lecteur ne voit pas les brouillons d'une
/// bibliothèque partagée) et les résolutions dont chaque rangée a besoin, calculés une fois par
/// rendu de l'accueil.
@MainActor
struct HomeCorpus {
    let fiches: [HItem]
    let refs: [HItem]
    let libraries: [LibraryInfo]
    /// Toutes les catégories, toutes bibliothèques (les ids ne sont uniques QUE par bibliothèque).
    let categoriesAll: [Category]
    private let catByKey: [String: Category]
    private let editable: Set<String>
    /// Titres normalisés présents dans au moins deux bibliothèques (`_homeDup`).
    private let dupTitles: Set<String>

    init(model: AppModel) {
        let lib = model.library
        var ed = Set<String>([""])
        for l in lib.libraries where l.role.canEdit { ed.insert(l.id) }
        editable = ed
        func vis(_ key: String, _ s: Status) -> Bool { ed.contains(key) || s != .draft }
        let fs = model.fiches.filter { vis($0.library ?? "", $0.status) }.map { HItem(id: $0.id, fiche: $0, ref: nil) }
        let rs = model.references.filter { vis($0.library ?? "", $0.status) }.map { HItem(id: $0.id, fiche: nil, ref: $0) }
        fiches = fs
        refs = rs
        var m: [String: Category] = [:]
        for c in model.categories { m[(c.library ?? "") + "|" + c.id] = c }
        catByKey = m
        categoriesAll = model.categories
        libraries = lib.libraries.sorted { HomeSearch.compareTitles($0.name, $1.name) == .orderedAscending }
        var seen: [String: Set<String>] = [:]
        for x in fs + rs { seen[HomeSearch.txNorm(x.title), default: []].insert(x.libKey) }
        dupTitles = Set(seen.filter { $0.value.count >= 2 }.map(\.key))
    }
    func isDuplicateTitle(_ x: HItem) -> Bool { dupTitles.contains(HomeSearch.txNorm(x.title)) }

    var all: [HItem] { fiches + refs }
    func items(_ s: HomeSection) -> [HItem] {
        switch s { case .all: return all; case .fiches: return fiches; case .protocols: return refs }
    }
    /// `catOf(x)` : la catégorie de même id DANS la bibliothèque de l'élément.
    func cat(of x: HItem) -> Category? { x.category.isEmpty ? nil : catByKey[x.libKey + "|" + x.category] }
    func catName(_ x: HItem) -> String { cat(of: x)?.name ?? "" }
    func canEdit(_ x: HItem) -> Bool { editable.contains(x.libKey) }
    func canEdit(scope key: String) -> Bool { editable.contains(key) }
    func libraryInfo(_ key: String) -> LibraryInfo? { key.isEmpty ? nil : libraries.first { $0.id == key } }
    /// Nom affiché d'une bibliothèque (« Perso », son nom, ou « Bibliothèque partagée »).
    func libraryName(_ key: String) -> String {
        if key.isEmpty { return "Perso" }
        let n = libraryInfo(key)?.name ?? ""
        return n.isEmpty ? "Bibliothèque partagée" : n
    }
    /// Groupes de bibliothèques PRÉSENTS dans le corpus visible (Perso d'abord, puis par nom) —
    /// un contenu orphelin n'est pas une rangée de filtre (sa clé est inconnue).
    var libraryKeys: [String] {
        let present = Set(all.map(\.libKey))
        var out: [String] = present.contains("") ? [""] : []
        for l in libraries where present.contains(l.id) { out.append(l.id) }
        return out
    }
    var hasSharedLibrary: Bool { !libraries.isEmpty }

    /// `homeLibOn(x) && catFilterOn(x)` (+ « À relire »).
    func passes(_ x: HItem, _ st: HomeState, ignoreCat: Bool = false, ignoreRev: Bool = false) -> Bool {
        if let l = st.lib, x.libKey != l { return false }
        if !ignoreCat, let c = st.cat, HomeSearch.txNorm(catName(x)) != c { return false }
        if st.rev && !ignoreRev && !x.needsReview { return false }
        return true
    }
}

// MARK: - Gestes de l'accueil sur le modèle

extension AppModel {
    /// `togglePin` : un BROUILLON ne s'épingle pas (désépingler reste toujours permis).
    func homeTogglePin(_ x: HItem) {
        if !pins.contains(x.id) && x.status == .draft {
            toast("Un brouillon ne s’épingle pas en accès direct — passez-le à « À relire » ou « Validée ».", seconds: 5)
            return
        }
        togglePin(x.id)
    }
    /// Ouvre une aide ou une référence depuis l'accueil (`openRead` / `openProtocolRead`).
    func homeOpen(_ x: HItem) {
        if x.isFiche { openFiche(x.id) } else { openReference(x.id) }
    }
    /// Réglage de présentation persisté par espace. `ac-home-group` voyage aussi dans les
    /// préférences synchronisées : le document de préférences devient « à pousser ».
    func setHomePref(_ key: String, _ value: String) {
        library.space.prefs[key] = .string(value)
        if key == "ac-home-group" {
            library.space.prefs["ac-cats-updated:"] = .number(JS.now())
            library.space.prefs["ac-cats-dirty:"] = "1"
            library.onLocalWrite()
        }
    }
    /// « Voir des fiches d'exemple » depuis l'accueil ou la bienvenue : le message passe dans
    /// le BANDEAU SYSTÈME (§1.2, « J’ai compris ») plutôt que dans un toast qui s'efface.
    func addExamplesFromHome() {
        addExamples()
        toast = nil
        homeSysBanner = "2 fiches d’exemple ajoutées. Relisez-les et validez-les : vous êtes responsable du contenu clinique."
    }
    /// Sessions vives DÉMARRÉES (cartes « Session en cours »), dans un ordre stable.
    var homeLiveSessions: [RuntimeSession] {
        engine.live.values.filter { $0.started && !$0.guest }.sorted { $0.startedAt < $1.startedAt }
    }
}

/// `liveWhereText(R)` : « {n · }{bloc} — dernier repère 14h05 » (parties connues seulement).
/// ⚠ Le numéro de bloc de la PWA vient de `flowPlan(f).order` (numérotation « le tronc
/// d'abord ») ; faute de ce port dans le cœur, on prend le rang du bloc dans l'aide.
@MainActor
func homeLiveWhereText(_ R: RuntimeSession) -> String {
    var p: [String] = []
    if let id = R.nav.last, !id.isEmpty, let i = R.fiche.blocks.firstIndex(where: { $0.id == id }) {
        let b = R.fiche.blocks[i]
        let t = b.title.trimmingCharacters(in: .whitespaces)
        p.append("\(i + 1) · " + (t.isEmpty ? (b.kind == .decision ? "Décision" : "Étapes") : t))
    }
    if let last = R.events.last(where: { $0.t != 0 }) {
        p.append("dernier repère " + Fmt.hm(last.t).replacingOccurrences(of: ":", with: "h"))
    }
    return p.joined(separator: " — ")
}
