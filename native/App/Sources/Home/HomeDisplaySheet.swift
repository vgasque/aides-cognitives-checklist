import SwiftUI
import AidesCore

// FEUILLE « AFFICHAGE » — port de `openViewSheet` / `paintViewSheet` (C1 §3.9, A353, A429).
// Deux sections encadrées : « Filtrer » (type, bibliothèque, catégorie) et « Présenter » (tri,
// rangement, densité). Tout s'applique EN DIRECT : la liste se refait derrière la feuille.

/// Segmenté à pastille GLISSANTE (`.seg:has(>.seg-pill)`, A350) : la pastille glisse, le
/// contrôle n'est jamais reconstruit au changement.
struct HomeSeg<V: Hashable>: View {
    var options: [(V, String)]
    @Binding var value: V
    var label: String
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, o in
                let on = o.0 == value
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { value = o.0 }
                } label: {
                    Text(o.1).aFont(TypeScale.body, on ? .bold : .semibold)
                        .lineLimit(1).minimumScaleFactor(0.8)
                        .foregroundStyle(on ? T.ink : T.ink2)
                        .frame(maxWidth: .infinity, minHeight: Ctrl.s)
                        .background {
                            if on {
                                RoundedRectangle(cornerRadius: Radius.r1, style: .continuous)
                                    .fill(T.work)
                                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                                    .matchedGeometryEffect(id: "pill", in: ns)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(4)
        .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}

struct HomeDisplaySheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.widthClass) private var wc
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?

    /// « Afficher » : Tout · Aides · Protocoles · À relire (`homeRev` + `setSection`).
    private var showBinding: Binding<String> {
        Binding(get: { st.rev ? "review" : st.section.rawValue },
                set: { v in st.rev = v == "review"; st.section = v == "review" ? .all : (HomeSection(rawValue: v) ?? .all) })
    }
    private var groupBinding: Binding<HomeGroup> { Binding(get: { st.group }, set: { st.group = $0 }) }
    private var sortBinding: Binding<HomeSort> { Binding(get: { st.sort }, set: { st.sort = $0 }) }
    private var compactBinding: Binding<Bool> { Binding(get: { st.compact }, set: { st.compact = $0 }) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Affichage").aFont(TypeScale.step, .heavy).foregroundStyle(T.ink).accessibilityAddTraits(.isHeader)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").aFont(TypeScale.item, .bold).frame(width: Ctrl.m, height: Ctrl.m)
                }
                .buttonStyle(.plain).foregroundStyle(T.ink2)
                .accessibilityLabel("Fermer")
            }
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 6)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    filterSection
                    presentSection
                    managementRow
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            footer
        }
        .background(T.amb.ignoresSafeArea())
    }

    // MARK: Filtrer

    private var filterSection: some View {
        let k = st.activeFilterCount
        return section(icon: "line.3.horizontal.decrease", title: "Filtrer", trailing: {
            if k > 0 {
                HStack(spacing: 10) {
                    Text(verbatim: "\(k) actif" + either(k > 1, "s", "")).aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink2)
                    Button("Tout effacer") { withAnimation(.easeOut(duration: 0.15)) { st.dropAllFilters() } }
                        .buttonStyle(.plain).aFont(TypeScale.meta, .bold).foregroundStyle(T.act)
                        .frame(minHeight: Ctrl.s)
                }
            }
        }) {
            field("Afficher") {
                HomeSeg(options: [("all", "Tout"), ("fiches", "Aides"), ("protocols", "Protocoles"), ("review", "À relire")],
                        value: showBinding, label: "Afficher")
            }
            if corpus.libraryKeys.count >= 2 {
                field("Bibliothèque") { libChips }
            }
            field("Catégorie") { catChips }
        }
    }

    private var libChips: some View {
        HomeFlow(spacing: 6) {
            chipButton("Toutes", icon: nil, dot: nil, on: st.lib == nil) { st.lib = nil }
            ForEach(corpus.libraryKeys, id: \.self) { key in
                let icon: String = key.isEmpty ? "person" : (corpus.canEdit(scope: key) ? "book.closed" : "lock.fill")
                chipButton(corpus.libraryName(key), icon: icon, dot: nil, on: st.lib == key) { st.lib = key }
            }
        }
    }

    /// `catsUtilesAll()` : une puce par NOM de catégorie ayant au moins un élément visible dans le
    /// corpus du type affiché (ou active), triées par nom.
    private var catChipsList: [(key: String, name: String, color: String)] {
        var seen: [String: (String, String)] = [:]
        for x in corpus.items(st.section) where st.lib == nil || x.libKey == st.lib! {
            guard let c = corpus.cat(of: x) else { continue }
            let k = HomeSearch.txNorm(c.name)
            if seen[k] == nil { seen[k] = (c.name, c.color) }
        }
        if let a = st.cat, seen[a] == nil, let c = corpus.categoriesAll.first(where: { HomeSearch.txNorm($0.name) == a }) {
            seen[a] = (c.name, c.color)
        }
        return seen.map { (key: $0.key, name: $0.value.0, color: $0.value.1) }
            .sorted { HomeSearch.compareTitles($0.name, $1.name) == .orderedAscending }
    }

    private var catChips: some View {
        HomeFlow(spacing: 6) {
            chipButton("Toutes", icon: nil, dot: nil, on: st.cat == nil) { st.cat = nil }
            ForEach(catChipsList, id: \.key) { c in
                chipButton(c.name, icon: nil, dot: c.color, on: st.cat == c.key) { st.cat = st.cat == c.key ? nil : c.key }
            }
        }
    }

    private func chipButton(_ text: String, icon: String?, dot: String?, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let d = dot {
                    Circle().fill(Color(cssHex: d)).frame(width: 8, height: 8)
                        .overlay(Circle().strokeBorder(on ? T.onPrimary : Color.clear, lineWidth: 1))
                }
                if let i = icon { Image(systemName: i).aFont(TypeScale.cap, .semibold) }
                Text(text).aFont(TypeScale.meta, .bold).lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: Ctrl.s)
            .foregroundStyle(on ? T.onPrimary : T.ink)
            .background(on ? T.act : T.work, in: Capsule())
            .overlay(Capsule().strokeBorder(on ? Color.clear : T.workLine))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: Présenter

    private var presentSection: some View {
        section(icon: "list.bullet.indent", title: "Présenter", trailing: { EmptyView() }) {
            field("Trier") {
                HomeSeg(options: [(HomeSort.alpha, "A → Z"), (HomeSort.recent, "Plus récentes")], value: sortBinding, label: "Trier")
            }
            field("Regrouper") {
                HomeSeg(options: HomeGroup.allCases.map { ($0, $0.seg) }, value: groupBinding, label: "Regrouper")
            }
            field("Densité") {
                HomeSeg(options: [(false, "Détaillée"), (true, "Compacte")], value: compactBinding, label: "Densité")
            }
        }
    }

    // MARK: Gestion

    @ViewBuilder
    private var managementRow: some View {
        let cats = st.lib == nil || corpus.canEdit(scope: st.lib!)
        let libs = model.profile.isAppAdmin || model.profile.libraries.contains { $0.role == .admin }
        if cats || libs {
            Button {
                if cats { sheet = .catMgr(st.lib) }
                else { model.rootTab = .me; sheet = nil }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape").aFont(TypeScale.item, .semibold)
                    Text(cats && libs ? "Gérer les catégories et les bibliothèques" : (libs ? "Gérer les bibliothèques" : "Gérer les catégories"))
                        .aFont(TypeScale.body, .bold).multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right").aFont(TypeScale.body, .bold).foregroundStyle(T.ink3)
                }
                .foregroundStyle(T.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: Ctrl.row)
                .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.workLine))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Pied

    private var resultCount: Int {
        var list = corpus.items(st.section).filter { corpus.passes($0, st) }
        let T = HomeSearch.qTerms(st.q)
        if !T.isEmpty {
            list = list.filter { x in
                let hay: String
                if let f = x.fiche { hay = HomeSearch.ficheHaystack(f, categoryName: corpus.catName(x)) }
                else if let p = x.ref { hay = HomeSearch.protocolHaystack(p, categoryName: corpus.catName(x)) }
                else { hay = "" }
                return HomeSearch.hayMatch(hay, T)
            }
        }
        return list.count
    }

    private var footer: some View {
        let n = resultCount
        let label = n == 0 ? "Aucun résultat" : (n == 1 ? "Voir le résultat" : "Voir les \(n) résultats")
        return Button(label) { dismiss() }
            .buttonStyle(.a(.primary, Ctrl.l, full: true))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(T.amb)
    }

    // MARK: Gabarits

    private func section<Tr: View, C: View>(icon: String, title: String, @ViewBuilder trailing: () -> Tr, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).aFont(TypeScale.body, .bold).foregroundStyle(T.ink2)
                Text(title).aFont(TypeScale.item, .bold).foregroundStyle(T.ink).accessibilityAddTraits(.isHeader)
                Spacer()
                trailing()
            }
            content()
        }
        .padding(14)
        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.workLine))
    }

    private func field<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
            content()
        }
    }
}

/// Disposition « en ligne qui passe à la ligne » (puces de filtres).
struct HomeFlow: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0, widest: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0 && x + sz.width > maxW { x = 0; y += lineH + spacing; lineH = 0 }
            x += sz.width + spacing
            lineH = max(lineH, sz.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, maxW), height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + sz.width > bounds.maxX { x = bounds.minX; y += lineH + spacing; lineH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            lineH = max(lineH, sz.height)
        }
    }
}
