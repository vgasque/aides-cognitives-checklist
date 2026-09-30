import SwiftUI
import AidesCore

// LA LISTE DE L'ACCUEIL — sans requête : tuiles « Accès direct », ligne de compte, puces de
// filtres, répertoire rangé (C1 §3.7) ; avec requête : résultats à plat, extraits, tolérance
// orthographique, renvoi croisé, « Afficher plus » (§3.8).

/// Un groupe du répertoire (`catGroups`, `bibGroups`, `kindGroups`, `azGroups`).
struct HGroup: Identifiable {
    let id: String
    let title: String
    /// Couleur de catégorie (rangement « catégorie »).
    var color: String? = nil
    /// Clé de bibliothèque (rangement « bibliothèque ») — cadenas si lecture seule.
    var libKey: String? = nil
    /// Lettre d'ancrage du rail A→Z.
    var letter: String? = nil
    let items: [HItem]
}

extension HomeCorpus {
    /// `srt` : « Plus récentes » = date de validation décroissante (chaîne), puis titre.
    func sorted(_ list: [HItem], _ s: HomeSort) -> [HItem] {
        list.enumerated().sorted { a, b in
            if s == .recent && a.element.validatedAt != b.element.validatedAt { return a.element.validatedAt > b.element.validatedAt }
            let c = HomeSearch.compareTitles(a.element.title, b.element.title)
            return c == .orderedSame ? a.offset < b.offset : c == .orderedAscending
        }.map(\.element)
    }
    func groups(_ list0: [HItem], by g: HomeGroup, sort s: HomeSort) -> [HGroup] {
        let list = sorted(list0, s)
        switch g {
        case .none:
            return list.isEmpty ? [] : [HGroup(id: "g-all", title: "", items: list)]
        case .kind:
            let a = list.filter(\.isFiche), b = list.filter { !$0.isFiche }
            var out: [HGroup] = []
            if !a.isEmpty { out.append(HGroup(id: "g-kind-f", title: "Parcours", items: a)) }
            if !b.isEmpty { out.append(HGroup(id: "g-kind-p", title: "Protocoles", items: b)) }
            return out
        case .cat:
            var gm: [String: [HItem]] = [:], keys: [String] = []
            for x in list {
                let n = catName(x)
                if gm[n] == nil { keys.append(n) }
                gm[n, default: []].append(x)
            }
            keys.sort { a, b in a.isEmpty ? false : (b.isEmpty ? true : HomeSearch.compareTitles(a, b) == .orderedAscending) }
            return keys.map { n in
                HGroup(id: "g-cat-" + n, title: n.isEmpty ? "Sans catégorie" : n, color: n.isEmpty ? nil : firstCategory(named: n)?.color, items: gm[n]!)
            }
        case .bib:
            var gm: [String: [HItem]] = [:]
            for x in list { gm[x.libKey, default: []].append(x) }
            var out: [HGroup] = []
            if let p = gm[""] { out.append(HGroup(id: "g-bib-", title: "Perso", libKey: "", items: p)) }
            for l in libraries { if let it = gm[l.id] { out.append(HGroup(id: "g-bib-" + l.id, title: l.name.isEmpty ? "Bibliothèque partagée" : l.name, libKey: l.id, items: it)) } }
            let known = Set(libraries.map(\.id))
            let orph = list.filter { !$0.libKey.isEmpty && !known.contains($0.libKey) }
            if !orph.isEmpty { out.append(HGroup(id: "g-bib-?", title: "Bibliothèque partagée", items: sorted(orph, .alpha))) }
            return out
        case .az:
            return HomeSearch.azGroups(list, title: \.title).map { HGroup(id: "az-" + $0.letter, title: $0.letter, letter: $0.letter, items: $0.items) }
        }
    }
    /// `categories.find(c => c.name === n)`.
    func firstCategory(named n: String) -> Category? { categoriesAll.first { $0.name == n } }
}

// MARK: - Zone de liste

struct HomeListArea: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?

    var body: some View {
        if st.q.trimmingCharacters(in: .whitespaces).isEmpty {
            HomeBrowseList(st: st, corpus: corpus, sheet: $sheet)
        } else {
            HomeSearchResults(st: st, corpus: corpus, sheet: $sheet)
        }
    }
}

/// Liste sans requête (§3.7).
struct HomeBrowseList: View {
    @Environment(AppModel.self) private var model
    @Environment(\.widthClass) private var wc
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?

    var body: some View {
        let list = corpus.items(st.section).filter { corpus.passes($0, st) }
        if list.isEmpty {
            if !st.selOn && st.activeFilterCount > 0 { HomeFilterChips(st: st, corpus: corpus, sheet: $sheet) }
            HomeEmptyState(st: st, corpus: corpus, sheet: $sheet)
        } else {
            let tiles = HomeSearch.qaPick(list, pinIds: model.pins, id: \.id)
            if !tiles.isEmpty && !st.selOn { HomeTiles(tiles: tiles, corpus: corpus) }
            HomeSummaryRow(st: st, corpus: corpus, list: list, sheet: $sheet)
            if !st.selOn && st.activeFilterCount > 0 { HomeFilterChips(st: st, corpus: corpus, sheet: $sheet) }
            ForEach(corpus.groups(list, by: st.group, sort: st.sort)) { g in
                HomeGroupView(group: g, st: st, corpus: corpus)
            }
        }
    }
}

/// Un groupe : intertitre (pastille, nom, cadenas, compte) puis ses rangées — en cartes
/// (« Détaillée ») ou dans UNE carte à filets (« Compacte »).
struct HomeGroupView: View {
    @Environment(\.widthClass) private var wc
    let group: HGroup
    let st: HomeState
    let corpus: HomeCorpus

    var body: some View {
        VStack(alignment: .leading, spacing: st.compact ? 6 : 10) {
            if !group.title.isEmpty { header }
            if st.compact {
                VStack(spacing: 0) {
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { i, x in
                        if i > 0 { Rectangle().fill(T.line).frame(height: 1).padding(.leading, 16) }
                        HomeRow(x: x, st: st, corpus: corpus, compact: true, snippet: nil)
                    }
                }
                .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.workLine))
            } else {
                VStack(spacing: 8) {
                    ForEach(group.items) { x in
                        HomeRow(x: x, st: st, corpus: corpus, compact: false, snippet: nil)
                    }
                }
            }
        }
        .padding(.top, 12)
        .id(group.id)
    }

    private var header: some View {
        let ro = group.libKey.map { !$0.isEmpty && !corpus.canEdit(scope: $0) } ?? false
        return HStack(spacing: 8) {
            if let c = group.color { CategoryDot(color: c, size: 10) }
            Text(group.title).aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                .accessibilityAddTraits(.isHeader)
            if ro {
                Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(T.ink2)
                    .accessibilityLabel("lecture seule")
                    .help("Lecture seule")
            }
            Spacer()
            Text(verbatim: "\(group.items.count)").aFont(TypeScale.meta, .semibold, .mono).foregroundStyle(T.ink2)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Rangée

/// Rangée d'une aide ou d'une référence (`_homeCfgF().row` / `_homeCfgP().row`) :
/// [case de sélection] [titre + méta (identité à gauche, UN état à droite)] [étoile].
struct HomeRow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.widthClass) private var wc
    let x: HItem
    let st: HomeState
    let corpus: HomeCorpus
    var compact: Bool
    var snippet: HomeSearch.Snippet?

    var body: some View {
        let editable = corpus.canEdit(x)
        let selectable = st.selOn && editable
        let selected = selectable && st.sel.contains(x.id)
        let cat = corpus.cat(of: x)
        let live = x.isFiche && (model.engine.live[x.id]?.started ?? false)
        let oneLine = compact && wc == .cockpit && snippet == nil
        let vPad: CGFloat = compact ? (oneLine ? 8 : 10) : 12
        let minH: CGFloat = compact ? (oneLine ? 48 : 64) : 76
        let stripeW: CGFloat = compact ? 3 : (live ? 8 : 6)
        let radius: CGFloat = compact ? 0 : Radius.r4
        let stripe: Color = cat.map { Color(cssHex: $0.color) } ?? Color.clear
        HStack(alignment: .center, spacing: 10) {
            if selectable {
                Image(systemName: selected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(selected ? T.act : T.ctlLine)
                    .frame(width: Ctrl.s, height: Ctrl.s)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                if oneLine {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        titleText.lineLimit(1)
                        Spacer(minLength: 8)
                        HomeRowMeta(x: x, corpus: corpus, cat: cat, showProvenance: showProvenance)
                            .frame(maxWidth: 520, alignment: .trailing)
                    }
                } else {
                    titleText.lineLimit(2)
                    if !x.discriminant.isEmpty {
                        Text(x.discriminant).aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2).lineLimit(1)
                    }
                    HomeRowMeta(x: x, corpus: corpus, cat: cat, showProvenance: showProvenance)
                }
                if let s = snippet {
                    Text(HomeSearch.attributed(s)).aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if !st.selOn {
                HomePinButton(x: x)
            }
        }
        .padding(.vertical, vPad)
        .padding(.leading, compact ? 16 : 20)
        .padding(.trailing, compact ? 8 : 12)
        .frame(minHeight: minH, alignment: .leading)
        .background(alignment: .leading) {
            Rectangle().fill(stripe).frame(width: stripeW)
        }
        .background(background(selected: selected, live: live))
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            if !compact {
                RoundedRectangle(cornerRadius: Radius.r4, style: .continuous)
                    .strokeBorder(selected ? T.act : T.workLine, lineWidth: selected ? 2 : 1)
            }
        }
        .shadow(color: compact ? .clear : .black.opacity(0.05), radius: 8, y: 3)
        .contentShape(Rectangle())
        .onTapGesture { tap(selectable: selectable) }
        .onLongPressGesture(minimumDuration: 0.5) {
            // Appui long (500 ms) : entre en sélection avec cette rangée cochée.
            guard editable, !st.selOn else { return }
            st.selOn = true
            st.sel = [x.id]
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(traits(selected: selected))
        .accessibilityLabel(selectable ? "Sélectionner " + x.displayTitle : x.displayTitle)
        .accessibilityAction(named: "Sélectionner") {
            guard editable else { return }
            st.selOn = true
            st.sel.insert(x.id)
        }
        .accessibilityAction(named: model.pins.contains(x.id) ? "Désépingler" : "Épingler en accès direct") {
            model.homeTogglePin(x)
        }
        .help(x.displayTitle)
    }

    private var titleText: some View {
        Text(x.displayTitle).aFont(TypeScale.item, .bold).foregroundStyle(T.ink).multilineTextAlignment(.leading)
    }
    /// Provenance (§3.7.8) : seulement si l'on a au moins une bibliothèque partagée ; toujours en
    /// recherche et hors rangement « bibliothèque » ; dans ce rangement, sur les seuls homonymes.
    private var showProvenance: Bool {
        guard corpus.hasSharedLibrary else { return false }
        if !st.q.isEmpty || st.group != .bib { return true }
        return corpus.isDuplicateTitle(x)
    }
    private func traits(selected: Bool) -> AccessibilityTraits {
        selected ? [.isButton, .isSelected] : [.isButton]
    }
    private func background(selected: Bool, live: Bool) -> Color {
        if selected { return T.primarySoft }
        if live { return T.okSoft }
        return T.work
    }
    private func tap(selectable: Bool) {
        if selectable {
            if st.sel.contains(x.id) { st.sel.remove(x.id) } else { st.sel.insert(x.id) }
        } else {
            model.homeOpen(x)
        }
    }
}

/// Ligne de méta : nature · discriminant · ● catégorie · n PDF · provenance … ÉTAT.
struct HomeRowMeta: View {
    let x: HItem
    let corpus: HomeCorpus
    let cat: Category?
    var showProvenance: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                identity
                Spacer(minLength: 8)
                HomeDirState(x: x)
            }
            // Sous 360 pt effectifs : identité et état sur deux lignes.
            VStack(alignment: .leading, spacing: 4) {
                identity
                HomeDirState(x: x)
            }
        }
    }

    private var identity: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(x.isFiche ? "AIDE" : "PROTOCOLE").aFont(TypeScale.cap, .heavy).tracking(0.6).foregroundStyle(T.ink2)
                .fixedSize()
            if let c = cat {
                HStack(spacing: 4) {
                    CategoryDot(color: c.color, size: 7)
                    Text(c.name).aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2).lineLimit(1)
                }
                .layoutPriority(c.name.count <= 5 ? 1 : 0)
            }
            if !x.isFiche && x.docCount > 0 {
                Text(verbatim: "\(x.docCount) PDF").aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2).fixedSize()
            }
            if showProvenance { HomeProvenanceTag(key: x.libKey, corpus: corpus) }
        }
    }
}

/// Étiquette de provenance (`searchLibTag`).
struct HomeProvenanceTag: View {
    let key: String
    let corpus: HomeCorpus
    var body: some View {
        let name = key.isEmpty ? "Perso" : (corpus.libraryInfo(key)?.name.isEmpty == false ? corpus.libraryInfo(key)!.name : "Partagée")
        HStack(spacing: 3) {
            Image(systemName: key.isEmpty ? "person" : "book.closed").font(.system(size: 10, weight: .semibold))
            Text(name).aFont(TypeScale.meta, .medium).lineLimit(1)
        }
        .foregroundStyle(T.ink2)
        .help("Bibliothèque : " + name)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bibliothèque : " + name)
    }
}

/// UN mot d'état, par priorité (`dirStateHtml`) : En cours › Brouillon › À relire › À compléter ›
/// Sans date › À revérifier › Validée. Les attentes sont ACHROMATIQUES ; seul « À revérifier »
/// est ambre (A347, A422) ; « En cours » porte le vert du système nominal, avec son mot.
struct HomeDirState: View {
    @Environment(AppModel.self) private var model
    let x: HItem

    var body: some View {
        let spots: [String] = (x.status == .validated) ? (x.fiche.map(HomeSearch.completionSpots) ?? []) : []
        if x.isFiche, let R = model.engine.live[x.id], R.started {
            // Seule la rangée VIVE lit le battement (300 ms) : le chrono se met à jour sur place.
            let _ = model.rev
            let d = Fmt.ms(JS.now() - R.startedAt)
            (Text("● En cours ") + Text(verbatim: d).monospacedDigit())
                .aFont(TypeScale.meta, .bold)
                .foregroundStyle(T.ok)
                .fixedSize()
                .accessibilityLabel("Session en cours depuis " + d)
        } else if x.status == .draft {
            badge("○ Brouillon")
        } else if x.status == .review {
            badge("△ À relire")
        } else if !spots.isEmpty {
            badge("△ À compléter").help("Reste à compléter : " + spots.joined(separator: " · "))
        } else if x.validatedAt.isEmpty {
            badge("△ Sans date")
        } else if HomeSearch.staleDate(x.validatedAt) {
            (Text("À revérifier ") + Text(verbatim: HomeSearch.fmtDateShort(x.validatedAt)))
                .aFont(TypeScale.meta, .bold).foregroundStyle(T.warn).fixedSize()
                .help(HomeSearch.fmtDate(x.validatedAt) + " — plus de 2 ans : à revérifier")
        } else {
            Text(verbatim: either(x.isFiche, "Validée ", "Validé ") + HomeSearch.fmtDateShort(x.validatedAt))
                .aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2).fixedSize()
                .help(HomeSearch.fmtDate(x.validatedAt))
        }
    }

    private func badge(_ s: String) -> some View {
        Text(s).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(T.amb2, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .fixedSize()
    }
}

/// Étoile d'épinglage (18 pt, cible 44).
struct HomePinButton: View {
    @Environment(AppModel.self) private var model
    let x: HItem
    var body: some View {
        let on = model.pins.contains(x.id)
        Button { model.homeTogglePin(x) } label: {
            Image(systemName: on ? "star.fill" : "star")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(on ? T.act : T.ink3)
                .frame(width: Ctrl.l, height: Ctrl.l)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(on ? "Désépingler" : "Épingler en accès direct")
        .help(on ? "Désépingler" : "Épingler en accès direct")
    }
}

// MARK: - Accès direct

/// Tuiles des épinglées (§3.7.2), dans l'ordre des épingles.
struct HomeTiles: View {
    @Environment(AppModel.self) private var model
    @Environment(\.widthClass) private var wc
    let tiles: [HItem]
    let corpus: HomeCorpus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Accès direct").aFont(TypeScale.item, .bold).foregroundStyle(T.ink).accessibilityAddTraits(.isHeader)
                Text(verbatim: "\(tiles.count) épinglée" + either(tiles.count > 1, "s", "")).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: wc == .phone ? 165 : 290), spacing: 8)], spacing: 8) {
                ForEach(tiles) { x in tile(x) }
            }
        }
        .padding(.top, 4)
    }

    private func tile(_ x: HItem) -> some View {
        let cat = corpus.cat(of: x)
        let live = x.isFiche && (model.engine.live[x.id]?.started ?? false)
        return Button { model.homeOpen(x) } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 6) {
                    Text(x.displayTitle).aFont(wc == .phone ? TypeScale.body : TypeScale.item, .bold).foregroundStyle(T.ink)
                        .lineLimit(wc == .phone ? 4 : 3).multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    if live {
                        Circle().fill(T.ok).frame(width: 8, height: 8).padding(.top, 4)
                            .accessibilityLabel("Session en cours")
                    }
                }
                tileSub(x, cat: cat)
            }
            .padding(.leading, 16).padding(.trailing, 10).padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
            .background(alignment: .leading) {
                Rectangle().fill(cat.map { Color(cssHex: $0.color) } ?? T.line).frame(width: 6)
            }
            .background(T.work)
            .clipShape(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.workLine))
        }
        .buttonStyle(.plain)
        .help(x.displayTitle)
    }

    private func tileSub(_ x: HItem, cat: Category?) -> some View {
        var parts: [String] = []
        if !x.discriminant.isEmpty { parts.append(x.discriminant) }
        if !x.code.isEmpty { parts.append(x.code) }
        var s = parts.joined(separator: " ")
        if let c = cat { s += either(s.isEmpty, "", " · ") + c.name }
        return Text(s).aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2).lineLimit(1)
    }
}

// MARK: - Ligne de compte et puces de filtres

/// « n parcours · m protocoles · r à relire » + « Affichage » + « Sélectionner » (§3.7.3).
struct HomeSummaryRow: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    let list: [HItem]
    @Binding var sheet: HomeSheet?

    /// Parties non nulles, jointes par « · » ; « Aucune aide » si tout est à zéro.
    private var summary: String {
        let p = list.filter { !$0.isFiche }.count
        let f = list.count - p
        let r = list.filter { $0.status == .draft || $0.status == .review || HomeSearch.staleDate($0.validatedAt) }.count
        var parts: [String] = []
        if f > 0 { parts.append("\(f) parcours") }
        if p > 0 { parts.append("\(p) protocole" + either(p > 1, "s", "")) }
        if r > 0 { parts.append("\(r) à relire") }
        return parts.isEmpty ? "Aucune aide" : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(verbatim: summary)
                .aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2)
                .lineLimit(1).minimumScaleFactor(0.85)
            Spacer(minLength: 4)
            if !st.selOn {
                Button { sheet = .display } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet.indent").font(.system(size: 13, weight: .bold))
                        Text("Affichage").aFont(TypeScale.body, .bold)
                    }
                    .padding(.horizontal, 12).frame(minHeight: Ctrl.m)
                    .foregroundStyle(T.ink)
                    .background(T.work, in: Capsule())
                    .overlay(Capsule().strokeBorder(T.workLine))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Affichage — rangé par " + st.group.word)
                if corpus.canEdit(scope: st.lib ?? "") {
                    Button { st.selOn = true; st.sel = [] } label: {
                        Text("Sélectionner").aFont(TypeScale.body, .bold)
                            .padding(.horizontal, 14).frame(minHeight: Ctrl.m)
                            .foregroundStyle(T.ink)
                            .background(T.work, in: Capsule())
                            .overlay(Capsule().strokeBorder(T.workLine))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
    }
}

/// Puces des filtres posés (`filtersBarHtml`) : la puce ouvre « Affichage », sa croix retire le
/// SEUL filtre qu'elle nomme ; « Tout effacer » dès deux puces.
struct HomeFilterChips: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?

    private struct F: Identifiable { let id: String; let label: String; let value: String; let color: String? }

    var body: some View {
        let fs = filters
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(fs) { f in chip(f) }
                if fs.count >= 2 {
                    Button("Tout effacer") { st.dropAllFilters() }
                        .buttonStyle(.plain)
                        .aFont(TypeScale.body, .bold).foregroundStyle(T.act)
                        .frame(minHeight: Ctrl.s)
                        .padding(.horizontal, 6)
                }
            }
        }
    }

    private var filters: [F] {
        var out: [F] = []
        if st.rev { out.append(F(id: "type", label: "Afficher", value: "À relire", color: nil)) }
        else if st.section != .all { out.append(F(id: "type", label: "Afficher", value: st.section == .fiches ? "Aides" : "Protocoles", color: nil)) }
        if let l = st.lib { out.append(F(id: "lib", label: "Bibliothèque", value: corpus.libraryName(l), color: nil)) }
        if let c = st.cat {
            let cobj = corpus.categoriesAll.first { HomeSearch.txNorm($0.name) == c }
            out.append(F(id: "cat", label: "Catégorie", value: cobj?.name ?? c, color: cobj?.color))
        }
        return out
    }

    private func chip(_ f: F) -> some View {
        HStack(spacing: 0) {
            Button { sheet = .display } label: {
                HStack(spacing: 4) {
                    if let c = f.color { CategoryDot(color: c, size: 8) }
                    (Text(f.label + " : ") + Text(f.value).bold())
                        .aFont(TypeScale.meta, .regular)
                        .lineLimit(1)
                }
                .padding(.leading, 12).padding(.trailing, 4)
                .frame(minHeight: Ctrl.s)
            }
            .buttonStyle(.plain)
            Button { drop(f.id) } label: {
                Image(systemName: "xmark").font(.system(size: 11, weight: .bold))
                    .frame(width: Ctrl.s, height: Ctrl.s)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Retirer le filtre " + f.label + " : " + f.value)
        }
        .foregroundStyle(T.act)
        .background(T.primarySoft, in: Capsule())
    }

    private func drop(_ k: String) {
        switch k {
        case "type": st.rev = false; st.section = .all
        case "lib": st.lib = nil
        default: st.cat = nil
        }
    }
}

// MARK: - États vides

/// §3.7.9 : « Aucun résultat » quand un filtre écarte tout ; carte pédagogique pour une
/// bibliothèque modifiable vide.
struct HomeEmptyState: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?

    private var emptyTitle: String {
        switch st.section { case .all: return "Bibliothèque vide"; case .fiches: return "Aucune fiche"; case .protocols: return "Aucun protocole" }
    }

    var body: some View {
        let writable = corpus.canEdit(scope: st.lib ?? "")
        if st.cat != nil || st.rev || !writable {
            WorkCard {
                VStack(alignment: .leading, spacing: 4) {
                    if st.cat != nil || st.rev {
                        Text("Aucun résultat").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                        Text("Rien ne correspond à ce filtre.").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                    } else {
                        Text(emptyTitle).aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                        Text(st.section == .protocols ? "Cette bibliothèque partagée ne contient pas encore de protocole." : "Cette bibliothèque partagée est vide.")
                            .aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                if let l = st.lib, !l.isEmpty {
                    Text("Cette bibliothèque partagée est vide.").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                }
                HomeTeachingCard(section: st.section, sheet: $sheet)
            }
        }
    }
}

/// Carte pédagogique d'une bibliothèque vide (`emptyIntroBothHtml` & co).
struct HomeTeachingCard: View {
    var section: HomeSection
    @Binding var sheet: HomeSheet?
    @Environment(\.widthClass) private var wc

    var body: some View {
        WorkCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                switch section {
                case .all:
                    Text("Votre bibliothèque est vide").aFont(TypeScale.stepL, .heavy).foregroundStyle(T.ink)
                    Text("Deux natures de contenu, deux usages — vous pouvez créer les deux.").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                    if wc == .phone {
                        VStack(alignment: .leading, spacing: 16) { aideColumn(extra: false); protoColumn }
                    } else {
                        HStack(alignment: .top, spacing: 20) { aideColumn(extra: false); protoColumn }
                    }
                case .fiches:
                    Text("Aucune aide cognitive").aFont(TypeScale.stepL, .heavy).foregroundStyle(T.ink)
                    BoldText(text: "Une aide cognitive **se déroule** pendant le soin.", size: TypeScale.body, color: T.ink2)
                    aideLines(extra: true)
                case .protocols:
                    Text("Aucun protocole").aFont(TypeScale.stepL, .heavy).foregroundStyle(T.ink)
                    BoldText(text: "Un protocole **se lit** : une référence, une procédure, un PDF.", size: TypeScale.body, color: T.ink2)
                    protoLines
                }
                Button { sheet = .create } label: { Text(verbatim: "＋ Créer") }
                    .buttonStyle(.a(.primary, Ctrl.l))
            }
        }
    }

    private func aideColumn(extra: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aide cognitive").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
            BoldText(text: "**se déroule** pendant le soin.", size: TypeScale.body, color: T.ink2)
            aideLines(extra: extra)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    private var protoColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Protocole").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
            BoldText(text: "**se lit** : une référence, une procédure, un PDF.", size: TypeScale.body, color: T.ink2)
            protoLines
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    @ViewBuilder
    private func aideLines(extra: Bool) -> some View {
        line("checkmark", T.ok, "**Des étapes** qu'on coche une par une, groupées en blocs.")
        line("arrow.triangle.branch", T.ink2, "**Des décisions** qui aiguillent vers la suite.")
        line("exclamationmark.triangle.fill", T.crit, "**Rouge** — ce qui tue si on l'oublie.")
        if extra {
            line("exclamationmark.triangle", T.warn, "**Ambre** — là où l'on risque de se tromper.")
            line("stopwatch", T.ink2, "**Minuteurs et compteurs** qui tournent pendant la session.")
        }
    }
    @ViewBuilder
    private var protoLines: some View {
        line("doc.text", T.ink2, "**Un texte qu'on parcourt** — titres, listes, tableaux, encadrés, et les PDF joints.")
        line("checkmark", T.ok, "**Des cases pour ne pas perdre sa place** — elles s'effacent en sortant : rien ne s'y enregistre.")
        line("stopwatch", T.ink3, "**Aucune session, aucun minuteur** — c'est ce qui le distingue d'une aide cognitive.")
    }
    private func line(_ icon: String, _ c: Color, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(c).frame(width: 18).accessibilityHidden(true)
            BoldText(text: text, size: TypeScale.body, color: T.ink)
        }
    }
}

// MARK: - Résultats de recherche

/// Recherche (§3.8) : liste à plat, extraits, « Afficher plus », renvoi croisé, correction.
struct HomeSearchResults: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?

    var body: some View {
        let r = compute()
        VStack(alignment: .leading, spacing: 8) {
            if let fix = r.fixed {
                (Text("Aucun résultat pour « ") + Text(verbatim: st.q).bold() + Text(" » · affiché : « ") + Text(verbatim: fix).bold() + Text(" »"))
                    .aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
            }
            (Text("Résultats — toutes les bibliothèques ") + Text(verbatim: "— \(r.list.count) " + countLabel(r.list.count)).foregroundColor(T.ink2))
                .aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                .accessibilityAddTraits(.isHeader)
            if r.cross > 0 {
                Button { st.section = st.section == .fiches ? .protocols : .fiches } label: {
                    HStack {
                        Text(verbatim: crossLabel(r.cross)).aFont(TypeScale.body, .bold).multilineTextAlignment(.leading)
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(T.act)
                    .frame(minHeight: Ctrl.m)
                }
                .buttonStyle(.plain)
            }
            if r.list.isEmpty {
                WorkCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aucun résultat").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                        Text("Rien ne correspond à cette recherche.").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                    }
                }
            } else {
                ForEach(r.list.prefix(st.libLimit)) { x in
                    HomeRow(x: x, st: st, corpus: corpus, compact: false, snippet: snippet(x, r.query))
                }
                if r.list.count > st.libLimit {
                    let k = r.list.count - st.libLimit
                    Button("Afficher plus (\(k) " + remainLabel(k) + ")") { st.libLimit += 60 }
                        .buttonStyle(.a(.secondary, Ctrl.l, full: true))
                        .padding(.top, 4)
                }
            }
        }
        .padding(.top, 4)
    }

    private struct R { var list: [HItem]; var query: String; var fixed: String?; var cross: Int }

    private func snippet(_ x: HItem, _ q: String) -> HomeSearch.Snippet? {
        let parts: [String]
        if let f = x.fiche { parts = HomeSearch.ficheSnipParts(f) }
        else if let p = x.ref { parts = HomeSearch.protoSnipParts(p) }
        else { parts = [] }
        return HomeSearch.snippet(parts, q)
    }

    private func haystack(_ x: HItem) -> String {
        if let f = x.fiche { return HomeSearch.ficheHaystack(f, categoryName: corpus.catName(x)) }
        if let p = x.ref { return HomeSearch.protocolHaystack(p, categoryName: corpus.catName(x)) }
        return ""
    }
    private func matches(_ scope: [HItem], _ q: String) -> [HItem] {
        let T = HomeSearch.qTerms(q)
        let pins = Set(model.pins)
        let hits = scope.filter { HomeSearch.hayMatch(haystack($0), T) }
        // `homeCmp(frecency)` : épinglées, puis fréquence d'usage récente, puis titre.
        let scored = hits.map { (x: $0, s: model.library.frecency($0.id), p: pins.contains($0.id)) }
        return scored.enumerated().sorted { a, b in
            if a.element.p != b.element.p { return a.element.p }
            if a.element.s != b.element.s { return a.element.s > b.element.s }
            let c = HomeSearch.compareTitles(a.element.x.title, b.element.x.title)
            return c == .orderedSame ? a.offset < b.offset : c == .orderedAscending
        }.map(\.element.x)
    }
    private func compute() -> R {
        let scope = corpus.items(st.section).filter { corpus.passes($0, st) }
        var q = st.q
        var list = matches(scope, q)
        var fixed: String? = nil
        if list.isEmpty {
            let vocab = HomeSearch.libVocab(scope.map { (title: $0.title, code: $0.code, discriminant: $0.discriminant) },
                                            extra: corpus.categoriesAll.map(\.name))
            if let f = HomeSearch.spellFix(q, vocab: vocab) {
                let l2 = matches(scope, f)
                if !l2.isEmpty { list = l2; fixed = f; q = f }
            }
        }
        var cross = 0
        if st.section != .all {
            let other: HomeSection = st.section == .fiches ? .protocols : .fiches
            let T = HomeSearch.qTerms(q)
            cross = corpus.items(other).filter { corpus.passes($0, st, ignoreRev: true) && HomeSearch.hayMatch(haystack($0), T) }.count
        }
        return R(list: list, query: q, fixed: fixed, cross: cross)
    }
    private func countLabel(_ n: Int) -> String {
        let s = n > 1 ? "s" : ""
        switch st.section {
        case .all: return "élément" + s
        case .fiches: return "aide" + s + " cognitive" + s
        case .protocols: return "document" + s
        }
    }
    private func remainLabel(_ n: Int) -> String {
        let s = n > 1 ? "s" : ""
        switch st.section {
        case .all: return "élément" + s
        case .fiches: return "restante" + s
        case .protocols: return "restant" + s
        }
    }
    private func crossLabel(_ n: Int) -> String {
        let lbl = st.section == .fiches ? "protocole" + either(n > 1, "s", "") : "aide" + either(n > 1, "s", "") + " cognitive" + either(n > 1, "s", "")
        return "\(n) " + lbl + " correspond" + either(n > 1, "ent", "") + " aussi à cette recherche"
    }
}

// MARK: - Rail A→Z (téléphone)

/// Rail A→Z (§3.7.7) : présent en rangement A–Z, liste non vide, au moins deux lettres. Un tap
/// ou un glissé saute au groupe ; jamais pendant une recherche.
struct HomeAZRail: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    let proxy: ScrollViewProxy
    @State private var lastLetter: String?

    var body: some View {
        let letters = currentLetters
        if st.group == .az && st.q.isEmpty && !st.selOn && letters.count >= 2 {
            GeometryReader { g in
                let step = g.size.height / CGFloat(letters.count)
                VStack(spacing: 0) {
                    ForEach(letters, id: \.self) { L in
                        Button { jump(L) } label: {
                            Text(L).aFont(TypeScale.cap, .bold).foregroundStyle(T.act)
                                .frame(width: 28, height: max(step, 12))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Aller à " + L)
                    }
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 4).onChanged { v in
                    let i = Int(v.location.y / max(step, 1))
                    if i >= 0 && i < letters.count { jump(letters[i]) }
                })
            }
            .frame(width: 28)
            .frame(maxHeight: min(CGFloat(letters.count) * 24, 620))
            .background(T.work.opacity(0.85), in: Capsule())
            .padding(.trailing, 2)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Aller à la lettre")
        }
    }

    private var currentLetters: [String] {
        guard st.group == .az else { return [] }
        let list = corpus.items(st.section).filter { corpus.passes($0, st) }
        return HomeSearch.azGroups(list, title: \.title).map(\.letter)
    }
    private func jump(_ L: String) {
        lastLetter = L
        withAnimation(.easeOut(duration: 0.15)) { proxy.scrollTo("az-" + L, anchor: .top) }
    }
}
