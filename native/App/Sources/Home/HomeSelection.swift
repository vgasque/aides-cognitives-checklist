import SwiftUI
import UniformTypeIdentifiers
import AidesCore

// SÉLECTION MULTIPLE DE L'ACCUEIL — port de `selBarHtml`, `openSelActs`, `selMoveLib`,
// `openSelCat`/`selSetCat`/`selCatPlan`, `selDelete`, `selExport` (C1 §3.11, A-model §21.2 ;
// A170, A227-A230, A392, A424).
// Seuls les éléments MODIFIABLES se cochent ; une rangée en lecture seule continue de s'ouvrir.
// Chaque écriture repasse par le point de persistance de l'entité (`model.save`), jamais un
// accès direct au disque.

/// `SEL_NUM` : « deux bibliothèques » — le mot, pas le chiffre (deux nombres collés se lisent
/// comme un seul) ; au-delà de neuf, le chiffre.
private let selNum = ["zéro", "une", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf"]
func homeSelLibsWord(_ k: Int) -> String { (k < selNum.count ? selNum[k] : String(k)) + " bibliothèques" }
/// `nb(k, mot)` : « 3 éléments ».
func homeNb(_ k: Int, _ mot: String) -> String { "\(k) " + mot + (k > 1 ? "s" : "") }

extension HomeCorpus {
    /// `selEnt()` : les éléments cochés, dans l'ordre du corpus.
    func selected(_ st: HomeState) -> [HItem] { all.filter { st.sel.contains($0.id) && canEdit($0) } }
    /// `impLibName(lib)`.
    func impLibName(_ key: String) -> String {
        key.isEmpty ? "Perso" : ((libraryInfo(key)?.name).flatMap { $0.isEmpty ? nil : $0 } ?? "Bibliothèque partagée")
    }
    /// `catNamed(lib, name)` : la catégorie de ce nom (comparée par `catSlug`) DANS une bibliothèque.
    func catNamed(_ key: String, _ name: String) -> Category? {
        let s = Library.catSlug(name)
        if s.isEmpty { return nil }
        return categoriesAll.first { ($0.library ?? "") == key && Library.catSlug($0.name) == s }
    }
    /// Catégories d'une bibliothèque, triées par nom.
    func categories(in key: String) -> [Category] {
        categoriesAll.filter { ($0.library ?? "") == key }.sorted { HomeSearch.compareTitles($0.name, $1.name) == .orderedAscending }
    }
}

// MARK: - Barre de sélection

/// Barre de sélection (collante, UNE ligne de 56 pt — A227) : compte, Tout cocher/décocher,
/// « Actions ⌄ » (ou actes en ligne au bureau), Annuler.
struct HomeSelectionBar: View {
    @Environment(AppModel.self) private var model
    @Environment(\.widthClass) private var wc
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?
    let exporter: HomeExportJob

    var body: some View {
        let ent = corpus.selected(st)
        let n = ent.count
        let libs = Set(ent.map(\.libKey))
        let desk = wc == .cockpit
        HStack(spacing: 8) {
            Text(verbatim: (n > 0 ? "\(n) coché" + (n > 1 ? "s" : "") : "Rien de coché") + (n > 0 && libs.count > 1 ? " · " + homeSelLibsWord(libs.count) : ""))
                .aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                .lineLimit(1).minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.updatesFrequently)
            if desk || n == 0 {
                Button("Tout cocher") { selectAllRendered() }.buttonStyle(.a(.secondary, Ctrl.s))
            }
            if n > 0 && (desk || wc == .tablet) {
                Button("Tout décocher") { st.sel = [] }.buttonStyle(.a(.secondary, Ctrl.s))
            }
            if n > 0 {
                if desk {
                    Button("Bibliothèque…") { sheet = .selMoveLib }.buttonStyle(.a(.secondary, Ctrl.s))
                        .accessibilityLabel("Déplacer vers une bibliothèque…")
                    Button("Catégorie…") { sheet = .selCategory }.buttonStyle(.a(.secondary, Ctrl.s))
                        .accessibilityLabel("Ranger dans une catégorie…")
                    Button("Exporter…") { exporter.start(model, items: ent) }.buttonStyle(.a(.secondary, Ctrl.s))
                        .accessibilityLabel("Exporter la sélection…")
                    Button("Supprimer…") { sheet = .selDelete }.buttonStyle(.a(.danger, Ctrl.s))
                        .accessibilityLabel(homeSelDelLabel(n))
                } else {
                    Button { sheet = .selActions } label: {
                        HStack(spacing: 4) {
                            Text("Actions")
                            Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold))
                        }
                    }
                    .buttonStyle(.a(.primary, Ctrl.s))
                }
            }
            Button { st.endSelection() } label: {
                if desk { Text("Annuler") } else { Image(systemName: "xmark").font(.system(size: 14, weight: .bold)) }
            }
            .buttonStyle(.a(.secondary, desk ? Ctrl.s : Ctrl.m))
            .accessibilityLabel("Quitter la sélection")
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.workLine))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        .padding(.vertical, 6)
        .background(T.amb)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Actions sur la sélection")
    }

    /// « Tout » = tout ce que la liste MONTRE (filtres et recherche compris) et qu'on peut modifier.
    private func selectAllRendered() {
        var list = corpus.items(st.section).filter { corpus.passes($0, st) && corpus.canEdit($0) }
        let T = HomeSearch.qTerms(st.q)
        if !T.isEmpty {
            list = list.filter { x in
                if let f = x.fiche { return HomeSearch.hayMatch(HomeSearch.ficheHaystack(f, categoryName: corpus.catName(x)), T) }
                if let p = x.ref { return HomeSearch.hayMatch(HomeSearch.protocolHaystack(p, categoryName: corpus.catName(x)), T) }
                return false
            }
        }
        st.sel.formUnion(list.map(\.id))
    }
}

func homeSelDelLabel(_ n: Int) -> String { "Supprimer " + (n > 1 ? "les \(n) éléments" : "l'élément") + "…" }

// MARK: - Gabarits de feuille (grammaire du menu : icône · libellé · sous-ligne · chevron)

struct HomeSheetHeader: View {
    var title: String
    var sub: String? = nil
    var back: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).aFont(TypeScale.step, .heavy).foregroundStyle(T.ink).accessibilityAddTraits(.isHeader)
                    if let s = sub { Text(s).aFont(TypeScale.body, .regular).foregroundStyle(T.ink2) }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).frame(width: Ctrl.m, height: Ctrl.m)
                }
                .buttonStyle(.plain).foregroundStyle(T.ink2)
                .accessibilityLabel("Fermer")
            }
            if let b = back {
                HomeMenuRow(icon: "arrow.uturn.backward", label: "Actions", sub: "retour aux actions", chevron: false, action: b)
            }
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 8)
    }
}

struct HomeMenuRow: View {
    var icon: String?
    var dot: String? = nil
    var label: String
    var sub: String? = nil
    var chevron = true
    var checked = false
    var danger = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let d = dot { CategoryDot(color: d, size: 12).frame(width: 24) }
                else if let i = icon {
                    Image(systemName: i).font(.system(size: 18, weight: .semibold)).frame(width: 24)
                        .foregroundStyle(danger ? T.crit : T.ink2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).aFont(TypeScale.item, .bold).foregroundStyle(danger ? T.crit : T.ink)
                        .multilineTextAlignment(.leading)
                    if let s = sub, !s.isEmpty {
                        Text(s).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 4)
                if checked {
                    Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(T.act)
                        .accessibilityLabel("choisi")
                }
                if chevron {
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(T.ink3)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: Ctrl.row)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(checked ? .isSelected : [])
    }
}

// MARK: - Feuille « Actions »

struct HomeSelActionsSheet: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?
    let exporter: HomeExportJob

    var body: some View {
        let ent = corpus.selected(st)
        let n = ent.count
        let libs = Array(Set(ent.map(\.libKey)))
        VStack(alignment: .leading, spacing: 0) {
            HomeSheetHeader(title: "\(n) coché" + (n > 1 ? "s" : ""),
                            sub: libs.count == 1 ? corpus.impLibName(libs[0]) : homeSelLibsWord(libs.count))
            ScrollView {
                VStack(spacing: 0) {
                    HomeMenuRow(icon: "arrow.uturn.backward.circle", label: "Tout décocher", chevron: false) {
                        st.sel = []; sheet = nil
                    }
                    HomeMenuRow(icon: "book.closed", label: "Déplacer vers une bibliothèque…", sub: "choisir la bibliothèque de destination") {
                        sheet = .selMoveLib
                    }
                    HomeMenuRow(icon: "tag", label: "Ranger dans une catégorie…",
                                sub: libs.count > 1 ? "par nom, dans la bibliothèque de chacun" : "choisir la catégorie") {
                        sheet = .selCategory
                    }
                    HomeMenuRow(icon: "square.and.arrow.down", label: "Exporter la sélection…", sub: "un seul fichier, réimportable (.json ou .zip)", chevron: false) {
                        sheet = nil
                        exporter.start(model, items: ent, delayed: true)
                    }
                    HomeMenuRow(icon: "trash", label: homeSelDelLabel(n), sub: "confirmation demandée", chevron: false, danger: true) {
                        sheet = .selDelete
                    }
                }
            }
        }
        .background(T.work.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .accessibilityLabel("Actions sur la sélection")
    }
}

// MARK: - Déplacer vers une bibliothèque

struct HomeSelMoveLibSheet: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?
    @State private var pending: String?
    @State private var confirm: (title: String, message: String, danger: Bool)?

    var body: some View {
        let ent = corpus.selected(st)
        let libs = Set(ent.map(\.libKey))
        let current = libs.count == 1 ? libs.first : nil
        let options: [(key: String, name: String)] = [(key: "", name: "Ma bibliothèque perso")]
            + corpus.libraries.filter { $0.role.canEdit }.map { (key: $0.id, name: $0.name + " (partagée)") }
        VStack(alignment: .leading, spacing: 0) {
            HomeSheetHeader(title: "Bibliothèque", back: { sheet = .selActions })
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(options, id: \.key) { o in
                        HomeMenuRow(icon: o.key.isEmpty ? "person" : "book.closed", label: o.name, chevron: false, checked: current == o.key) {
                            ask(o.key, ent)
                        }
                    }
                }
            }
        }
        .background(T.work.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .alert(confirm?.title ?? "", isPresented: Binding(get: { confirm != nil }, set: { if !$0 { confirm = nil } })) {
            Button("Annuler", role: .cancel) { pending = nil }
            Button("Déplacer", role: (confirm?.danger ?? false) ? ButtonRole.destructive : nil) {
                if let k = pending { apply(k, ent) }
            }
        } message: {
            Text(confirm?.message ?? "")
        }
    }

    private func destText(_ key: String) -> String {
        key.isEmpty ? "votre bibliothèque perso" : "« " + corpus.impLibName(key) + " »"
    }

    /// Deux conséquences dites AVANT : entrer dans une partagée = publier à toute l'équipe ; en
    /// sortir = retirer l'accès aux autres.
    private func ask(_ key: String, _ ent: [HItem]) {
        let entrants = ent.filter { !key.isEmpty && $0.libKey != key }
        let sortants = ent.filter { !$0.libKey.isEmpty && $0.libKey != key }
        pending = key
        if !entrants.isEmpty {
            let k = entrants.count
            confirm = ("Publier dans la bibliothèque partagée",
                       "\(k) élément" + (k > 1 ? "s vont" : " va") + " être publié" + (k > 1 ? "s" : "") + " dans " + destText(key)
                        + " : visible" + (k > 1 ? "s" : "") + " par tous les membres.", false)
        } else if !sortants.isEmpty {
            let k = sortants.count
            confirm = ("Retirer de la bibliothèque partagée",
                       "\(k) élément" + (k > 1 ? "s vont" : " va") + " quitter une bibliothèque partagée : les autres membres n'y auront plus accès. Prévenez-les avant si besoin.", true)
        } else {
            apply(key, ent)
        }
    }

    /// La catégorie est RETROUVÉE PAR SON NOM dans la destination, sinon vidée — jamais créée.
    private func apply(_ key: String, _ ent: [HItem]) {
        var lost = 0
        for x in ent where x.libKey != key {
            let before = corpus.cat(of: x)
            let newCat: String
            if let b = before {
                if let eq = corpus.catNamed(key, b.name) { newCat = eq.id } else { newCat = ""; lost += 1 }
            } else { newCat = "" }
            if var f = x.fiche {
                f.library = key.isEmpty ? nil : key
                f.category = newCat
                model.save(f)
            } else if var p = x.ref {
                p.library = key.isEmpty ? nil : key
                p.category = newCat
                model.save(p)
            }
        }
        // LA DESTINATION DEVIENT LA VUE (si un filtre de bibliothèque était posé) ; la catégorie
        // filtrée ne vaut plus rien après un déplacement.
        if st.lib != nil { st.lib = key }
        st.cat = nil
        let n = ent.count
        model.toast("\(n) élément" + (n > 1 ? "s déplacés" : " déplacé") + " dans " + destText(key)
                    + (lost > 0 ? " · \(lost) catégorie" + (lost > 1 ? "s" : "") + " sans équivalent : " + (lost > 1 ? "elles ont" : "elle a") + " été retirée" + (lost > 1 ? "s" : "") : "") + ".",
                    seconds: lost > 0 ? 7 : 4)
        pending = nil
        sheet = nil
    }
}

// MARK: - Ranger dans une catégorie (par NOM)

struct HomeSelCategorySheet: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?

    private struct Plan { var lib: String; var nom: String; var n: Int; var cat: Category? }
    private struct CatGroup: Identifiable { let id: String; let head: String; let count: String; let cats: [Category] }

    /// `selCatPlan(ent, name)` : par bibliothèque, combien d'éléments et la catégorie de ce nom.
    private func plan(_ ent: [HItem], _ name: String) -> [Plan] {
        var order: [String] = [], by: [String: Plan] = [:]
        for x in ent {
            if by[x.libKey] == nil {
                order.append(x.libKey)
                by[x.libKey] = Plan(lib: x.libKey, nom: corpus.impLibName(x.libKey), n: 0, cat: name.isEmpty ? nil : corpus.catNamed(x.libKey, name))
            }
            by[x.libKey]!.n += 1
        }
        return order.map { by[$0]! }
    }

    var body: some View {
        let ent = corpus.selected(st)
        let libs = uniq(ent.map(\.libKey))
        let multi = libs.count > 1
        // Une rangée par NOM (slug) sur les bibliothèques de la sélection.
        var seen: [String: Category] = [:], names: [Category] = []
        for l in libs { for c in corpus.categories(in: l) { let k = Library.catSlug(c.name); if !k.isEmpty && seen[k] == nil { seen[k] = c; names.append(c) } } }
        names.sort { HomeSearch.compareTitles($0.name, $1.name) == .orderedAscending }
        let curSlugs = Set(ent.map { corpus.cat(of: $0).map { Library.catSlug($0.name) } ?? "" })
        let cur = curSlugs.count == 1 ? curSlugs.first! : "-"
        return VStack(alignment: .leading, spacing: 0) {
            HomeSheetHeader(title: multi ? "Ranger " + homeNb(ent.count, "élément") : "Catégorie",
                            sub: multi ? libs.map(corpus.impLibName).joined(separator: " · ") : nil,
                            back: { sheet = .selActions })
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if multi {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle").foregroundStyle(T.ink2).accessibilityHidden(true)
                            (Text(verbatim: "\(libs.count) bibliothèques différentes.").bold()
                             + Text(" Chacun ira dans la catégorie du même nom de la sienne ; là où ce nom n’existe pas, il ne change pas."))
                                .aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
                        }
                        .padding(12)
                        .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
                        .padding(.horizontal, 16).padding(.bottom, 8)
                    }
                    HomeMenuRow(icon: "circle.slash", label: "Sans catégorie",
                                sub: multi ? "retire la catégorie des " + homeNb(ent.count, "élément") : nil,
                                chevron: false, checked: cur == "") { apply("", ent) }
                    if multi {
                        ForEach(groups(ent, names, libs)) { g in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(g.head).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
                                Text(g.count).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                            }
                            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 4)
                            .accessibilityAddTraits(.isHeader)
                            ForEach(g.cats, id: \.id) { c in
                                HomeMenuRow(icon: nil, dot: c.color, label: c.name, chevron: false, checked: cur == Library.catSlug(c.name)) { apply(c.name, ent) }
                            }
                        }
                    } else {
                        ForEach(names, id: \.id) { c in
                            HomeMenuRow(icon: nil, dot: c.color, label: c.name, chevron: false, checked: cur == Library.catSlug(c.name)) { apply(c.name, ent) }
                        }
                    }
                    Rectangle().fill(T.line).frame(height: 1).padding(.vertical, 6)
                    HomeMenuRow(icon: "plus", label: "＋ Nouvelle catégorie", chevron: false) {
                        sheet = .catMgr(multi ? nil : libs.first)
                    }
                }
            }
        }
        .background(T.work.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }

    private func uniq(_ a: [String]) -> [String] { var s = Set<String>(); return a.filter { s.insert($0).inserted } }

    /// Intertitres « où le nom existe » : partout d'abord (« Dans les deux / toutes les
    /// bibliothèques »), puis « Dans A et B » / « Seulement dans A ».
    private func groups(_ ent: [HItem], _ names: [Category], _ libs: [String]) -> [CatGroup] {
        var keys: [String] = [], rows: [String: [Category]] = [:], plans: [String: [Plan]] = [:]
        for c in names {
            let p = plan(ent, c.name)
            let ok = p.filter { $0.cat != nil }, manque = p.filter { $0.cat == nil }
            let k = manque.isEmpty ? "" : ok.map(\.nom).joined(separator: " et ")
            if rows[k] == nil { keys.append(k); plans[k] = p }
            rows[k, default: []].append(c)
        }
        keys.sort { a, b in (a.isEmpty ? 0 : 1, a) < (b.isEmpty ? 0 : 1, b) }
        return keys.map { k in
            let p = plans[k] ?? []
            let ok = p.filter { $0.cat != nil }, manque = p.filter { $0.cat == nil }
            let head = k.isEmpty ? (libs.count > 2 ? "Dans toutes les bibliothèques" : "Dans les deux bibliothèques")
                                 : (k.contains(" et ") ? "Dans " : "Seulement dans ") + k
            let cnt = k.isEmpty ? ok.map { "\($0.n) dans " + $0.nom }.joined(separator: " · ")
                                : homeNb(ok.reduce(0) { $0 + $1.n }, "rangé") + " · " + homeNb(manque.reduce(0) { $0 + $1.n }, "inchangé")
            return CatGroup(id: "g:" + k, head: head, count: cnt, cats: rows[k] ?? [])
        }
    }

    /// `selSetCat(name)` : chacun dans la catégorie de ce nom de SA bibliothèque ; là où le nom
    /// n'existe pas, l'élément reste inchangé — rien n'est créé ni vidé en silence.
    private func apply(_ name: String, _ ent: [HItem]) {
        let p = plan(ent, name)
        let multi = p.count > 1
        var done = 0
        for x in ent {
            guard let pl = p.first(where: { $0.lib == x.libKey }) else { continue }
            if !name.isEmpty && pl.cat == nil { continue }
            let cid = name.isEmpty ? "" : pl.cat!.id
            if var f = x.fiche { f.category = cid; model.save(f) } else if var r = x.ref { r.category = cid; model.save(r) }
            done += 1
        }
        let ok = p.filter { name.isEmpty || $0.cat != nil }, manque = p.filter { !name.isEmpty && $0.cat == nil }
        let lieu = multi && !name.isEmpty && !ok.isEmpty ? " — " + ok.map { "\($0.n) dans " + $0.nom }.joined(separator: ", ") : ""
        let reste = manque.map { homeNb($0.n, "élément") + " inchangé" + ($0.n > 1 ? "s" : "") + " : pas de « " + name + " » dans " + $0.nom }.joined(separator: " · ")
        var msg = ""
        if done > 0 { msg = homeNb(done, "élément") + (done > 1 ? " rangés" : " rangé") + (name.isEmpty ? " sans catégorie" : " dans « " + name + " »") + lieu }
        if done > 0 && !reste.isEmpty { msg += " · " }
        msg += reste + "."
        model.toast(msg, seconds: reste.isEmpty ? 4 : 7)
        sheet = nil
    }
}

// MARK: - Suppression en lot : confirmation FORTE

/// La fenêtre ÉNUMÈRE ce qui va disparaître (dix titres au plus, le reste compté) et la case
/// « J'ai lu cette liste » est l'accusé de lecture : sans elle, le bouton reste FERMÉ.
struct HomeSelDeleteSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?
    @State private var read = false

    var body: some View {
        let ent = corpus.selected(st)
        let n = ent.count
        VStack(alignment: .leading, spacing: 14) {
            Text("Supprimer \(n) élément" + (n > 1 ? "s" : "") + " ?").aFont(TypeScale.step, .heavy).foregroundStyle(T.ink)
                .accessibilityAddTraits(.isHeader)
            ScrollView {
                Text(message(ent)).aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 320)
            Button { read.toggle() } label: {
                HStack(spacing: 10) {
                    Image(systemName: read ? "checkmark.square.fill" : "square").font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(read ? T.crit : T.ctlLine)
                    Text("J'ai lu cette liste").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                    Spacer()
                }
                .frame(minHeight: Ctrl.l)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(read ? [.isButton, .isSelected] : [.isButton])
            HStack(spacing: 10) {
                Button("Annuler") { dismiss() }.buttonStyle(.a(.secondary, Ctrl.l, full: true))
                Button("Supprimer") { apply(ent) }.buttonStyle(.a(.danger, Ctrl.l, full: true))
                    .disabled(!read)
            }
        }
        .padding(20)
        .background(T.work.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }

    private func message(_ ent: [HItem]) -> String {
        let noms = ent.map { $0.title.trimmingCharacters(in: .whitespaces).isEmpty ? "Sans titre" : $0.title.trimmingCharacters(in: .whitespaces) }
        let N = 10
        var liste = noms.prefix(N).map { " · " + $0 }.joined(separator: "\n")
        if noms.count > N { let k = noms.count - N; liste += "\n · … et \(k) autre" + (k > 1 ? "s" : "") }
        let part = ent.filter { !$0.libKey.isEmpty }.count
        var m = "Vont disparaître :\n" + liste
        if part > 0 {
            m += "\n\nDont \(part) dans une bibliothèque partagée : " + (part > 1 ? "ils disparaîtront" : "il disparaîtra") + " aussi pour tous ses membres."
        }
        return m + "\n\nCette action est irréversible."
    }

    private func apply(_ ent: [HItem]) {
        guard read else { return }
        for x in ent {
            // `model.delete` : tombe (ou purge hors compte), sessions de l'aide retirées, session vive close.
            if let f = x.fiche { model.delete(f) } else if let p = x.ref { model.delete(p) }
        }
        let n = ent.count
        st.endSelection()
        model.toast("\(n) élément" + (n > 1 ? "s supprimés" : " supprimé") + ".")
        sheet = nil
    }
}

// MARK: - Export de la sélection

/// Un fichier à enregistrer (.json ou .zip).
struct HomeExportFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .zip] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

/// `selExport` → `exportData` : même enveloppe que l'export global, documents au choix.
@MainActor
@Observable
final class HomeExportJob {
    var askDocs = false
    var docsCount = 0
    var presented = false
    var document: HomeExportFile?
    var contentType: UTType = .json
    var filename = ""
    @ObservationIgnored var fiches: [Fiche] = []
    @ObservationIgnored var refs: [Reference] = []
    @ObservationIgnored var base = ""
    @ObservationIgnored var afterToast: String?

    init() {}

    func start(_ model: AppModel, items: [HItem], delayed: Bool = false) {
        guard !items.isEmpty else { return }
        fiches = items.compactMap(\.fiche)
        refs = items.compactMap(\.ref)
        if items.count == 1 {
            base = (items[0].isFiche ? "fiche-" : "protocole-") + Exporter.slug(items[0].title)
        } else {
            base = "selection-\(items.count)-elements"
        }
        let ids = Exporter.attachmentIds(fiches: fiches, references: refs)
        docsCount = ids.count
        let go: () -> Void = { [weak self] in
            guard let self else { return }
            if ids.isEmpty { self.build(model, withDocs: false) } else { self.askDocs = true }
        }
        if delayed {
            // Laisse la feuille « Actions » se refermer avant d'en présenter une autre.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                go()
            }
        } else { go() }
    }

    func build(_ model: AppModel, withDocs: Bool) {
        let env = Exporter.envelope(fiches: fiches, references: refs, categories: nil, all: model.categories, space: model.store.currentSpace)
        let ids = Exporter.attachmentIds(fiches: fiches, references: refs)
        let r = Exporter.build(envelope: env, withDocuments: withDocs, attachmentIds: ids, store: model.library.space)
        document = HomeExportFile(data: r.data)
        contentType = r.isZip ? .zip : .json
        let full = Exporter.fileName(base: base, ext: r.isZip ? "zip" : "json")
        filename = String(full.dropLast(r.isZip ? 4 : 5))
        if !withDocs && !ids.isEmpty { afterToast = Exporter.jsonOnlyNotice }
        else if r.missing > 0 { afterToast = Exporter.missingNotice(r.missing) }
        else { afterToast = nil }
        presented = true
    }
}

struct HomeExporterModifier: ViewModifier {
    @Environment(AppModel.self) private var model
    @Bindable var job: HomeExportJob

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Exporter", isPresented: $job.askDocs, titleVisibility: .visible) {
                Button("Avec les documents (.zip)") { job.build(model, withDocs: true) }
                Button("Sans les documents (.json)") { job.build(model, withDocs: false) }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text(Exporter.docsQuestion(job.docsCount))
            }
            .fileExporter(isPresented: $job.presented, document: job.document, contentType: job.contentType,
                          defaultFilename: job.filename) { result in
                if case .success = result, let t = job.afterToast { model.toast(t, seconds: 9) }
                if case .failure(let e) = result { model.toast("⚠ Export impossible : " + e.localizedDescription) }
                job.document = nil
            }
    }
}

extension View {
    func homeExporter(_ job: HomeExportJob) -> some View { modifier(HomeExporterModifier(job: job)) }
}
