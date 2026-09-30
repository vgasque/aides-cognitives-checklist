import SwiftUI
import AidesCore

// COLONNE DES FILTRES (≥ 780) — port de `homeSideHtml` / `hsRow` (C1 §3.5, A269-A285, A389).
// iOS 27 : la marque et la navigation (Aides · Sessions · Moi) sont passées à la barre latérale
// SYSTÈME (onglets adaptables) ; cette colonne ne garde que ce qui FILTRE la liste.
// Trois étages, un seul défile : en haut les bibliothèques ; au milieu les catégories (seul étage
// qui défile) ; au pied l'état (synchro, version). Les comptes sont STABLES : ils disent la visibilité, jamais les autres filtres.

struct HomeSidebar: View {
    @Environment(AppModel.self) private var model
    let st: HomeState
    let corpus: HomeCorpus
    @Binding var sheet: HomeSheet?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            top
            Rectangle().fill(T.line).frame(height: 1).padding(.vertical, 8)
            ScrollView { categories.padding(.bottom, 12) }
            Rectangle().fill(T.line).frame(height: 1)
            foot
        }
        .padding(.horizontal, 12)
        .background(T.work.ignoresSafeArea())
    }

    // MARK: Étage du haut

    private var top: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Overline(text: "Bibliothèques")
                Spacer()
                if model.profile.isAppAdmin || model.profile.libraries.contains(where: { $0.role == .admin }) {
                    Button("Gérer") { st.endSelection(); model.rootTab = .me }
                        .buttonStyle(.plain)
                        .aFont(TypeScale.meta, .bold).foregroundStyle(T.act)
                        .frame(minHeight: Ctrl.s)
                        .accessibilityLabel("Gérer les bibliothèques")
                }
            }
            .padding(.top, 14).padding(.horizontal, 6)

            libRow(key: nil, label: "Toutes", count: corpus.all.count)
            ForEach(corpus.libraryKeys, id: \.self) { k in
                libRow(key: k, label: corpus.libraryName(k), count: corpus.all.filter { $0.libKey == k }.count)
            }
        }
    }

    /// Rangée de bibliothèque (`hsRow`) : marque · libellé · accès · compte au bord droit.
    /// Re-toucher la rangée active revient à « Toutes » ; ne touche jamais au rangement.
    private func libRow(key: String?, label: String, count: Int) -> some View {
        let on = st.lib == key
        return Button {
            st.lib = (key == nil || st.lib == key) ? nil : key
        } label: {
            HStack(spacing: 10) {
                Group {
                    if key == nil { Image(systemName: "circle.dashed") }
                    else if key == "" { Image(systemName: "person") }
                    else { Image(systemName: "book.closed") }
                }
                .font(.system(size: 13, weight: .semibold)).frame(width: 24)
                .accessibilityHidden(true)
                Text(label).aFont(TypeScale.body, .semibold).lineLimit(1)
                Spacer(minLength: 4)
                accessIcon(key)
                Text(verbatim: "\(count)").aFont(TypeScale.meta, .semibold, .mono).foregroundStyle(T.ink2)
                    .frame(minWidth: 28, alignment: .trailing)
            }
            .padding(.horizontal, 8)
            .frame(minHeight: Ctrl.s + 2)
            .foregroundStyle(on ? T.act : T.ink)
            .background(on ? T.primarySoft : Color.clear, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    @ViewBuilder
    private func accessIcon(_ key: String?) -> some View {
        if let k = key, !k.isEmpty, let l = corpus.libraryInfo(k) {
            if l.role.canEdit {
                Image(systemName: "lock.open").font(.system(size: 11)).foregroundStyle(T.ink3)
                    .help(l.role == .admin ? "Administrée" : "Lecture-écriture")
                    .accessibilityLabel(l.role == .admin ? "Administrée" : "Lecture-écriture")
            } else {
                Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(T.ink2)
                    .help("Lecture seule — bibliothèque institutionnelle")
                    .accessibilityLabel("Lecture seule — bibliothèque institutionnelle")
            }
        }
    }

    // MARK: Catégories (étage qui défile)

    private struct CatRow: Identifiable {
        let id: String          // nom normalisé
        let name: String
        let colors: [String]
        let count: Int
    }

    /// Une rangée PAR NOM parmi les catégories du périmètre affiché ; les couleurs d'homonymes
    /// divergentes font une pastille multicolore (A299, A306 : seules les catégories du périmètre
    /// qui comptent au moins un élément la teintent).
    private var catRows: [CatRow] {
        let scoped = corpus.all.filter { st.lib == nil || $0.libKey == st.lib! }
        var count: [String: Int] = [:]
        var colorsBy: [String: [String]] = [:]
        var nameBy: [String: String] = [:]
        for x in scoped {
            guard let c = corpus.cat(of: x) else { continue }
            let k = HomeSearch.txNorm(c.name)
            count[k, default: 0] += 1
            if nameBy[k] == nil { nameBy[k] = c.name }
            if !(colorsBy[k] ?? []).contains(c.color) { colorsBy[k, default: []].append(c.color) }
        }
        // Le filtre actif garde sa rangée même à zéro.
        if let a = st.cat, count[a] == nil,
           let c = corpus.categoriesAll.first(where: { HomeSearch.txNorm($0.name) == a && (st.lib == nil || ($0.library ?? "") == st.lib!) }) {
            count[a] = 0; nameBy[a] = c.name; colorsBy[a] = [c.color]
        }
        return count.keys.map { k in CatRow(id: k, name: nameBy[k] ?? k, colors: colorsBy[k] ?? [], count: count[k] ?? 0) }
            .sorted { HomeSearch.compareTitles($0.name, $1.name) == .orderedAscending }
    }

    private var catMgrOn: Bool { st.lib == nil || corpus.canEdit(scope: st.lib!) }

    private var categories: some View {
        let scopedCount = corpus.all.filter { st.lib == nil || $0.libKey == st.lib! }.count
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Overline(text: "Catégories")
                Spacer()
                if catMgrOn {
                    Button("Gérer") { sheet = .catMgr(st.lib) }
                        .buttonStyle(.plain)
                        .aFont(TypeScale.meta, .bold).foregroundStyle(T.act)
                        .frame(minHeight: Ctrl.s)
                        .accessibilityLabel("Gérer les catégories")
                }
            }
            .padding(.horizontal, 6)
            catRowView(key: nil, name: "Toutes les catégories", colors: [], count: scopedCount)
            ForEach(catRows) { r in
                catRowView(key: r.id, name: r.name, colors: r.colors, count: r.count)
            }
        }
    }

    private func catRowView(key: String?, name: String, colors: [String], count: Int) -> some View {
        let on = st.cat == key
        return Button {
            if key == nil { st.cat = nil } else { st.cat = on ? nil : key }
        } label: {
            HStack(spacing: 10) {
                Group {
                    if key == nil { Image(systemName: "circle.dashed").font(.system(size: 13, weight: .semibold)) }
                    else { HomeMultiDot(colors: colors) }
                }
                .frame(width: 24)
                .accessibilityHidden(true)
                Text(name).aFont(TypeScale.body, .semibold).lineLimit(1)
                Spacer(minLength: 4)
                Text(verbatim: "\(count)").aFont(TypeScale.meta, .semibold, .mono).foregroundStyle(T.ink2)
                    .frame(minWidth: 28, alignment: .trailing)
            }
            .padding(.horizontal, 8)
            .frame(minHeight: Ctrl.s + 2)
            .foregroundStyle(on ? T.act : T.ink)
            .background(on ? T.primarySoft : Color.clear, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: Pied

    private var foot: some View {
        VStack(alignment: .leading, spacing: 6) {
            if model.auth.signedIn {
                let s = model.syncStatus
                Button {
                    if s.state == .err { sheet = .syncError }
                    else if s.state == .pending || s.state == .rejected { model.rootTab = .me }
                } label: {
                    HStack(spacing: 6) {
                        HomeSyncDot(state: s.state)
                        Text(s.text).aFont(TypeScale.meta, .semibold).foregroundStyle(s.state.isTappable ? T.warn : T.ink2)
                        Spacer()
                    }
                    .frame(minHeight: Ctrl.s)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!s.state.isTappable)
                .help(s.state.tooltip)
            }
            HStack {
                Text(verbatim: "v" + AppModel.appVersion).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                Spacer()
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
    }
}

/// Pastille de catégorie : une couleur, ou plusieurs secteurs quand des homonymes divergent.
struct HomeMultiDot: View {
    var colors: [String]
    var size: CGFloat = 10
    var body: some View {
        if colors.count <= 1 {
            CategoryDot(color: colors.first ?? Guard.defaultColor, size: size)
        } else {
            let n = Double(colors.count)
            let stops: [Gradient.Stop] = colors.enumerated().flatMap { (i, c) -> [Gradient.Stop] in
                let col = Color(cssHex: c)
                return [Gradient.Stop(color: col, location: Double(i) / n), Gradient.Stop(color: col, location: Double(i + 1) / n)]
            }
            Circle().fill(AngularGradient(gradient: Gradient(stops: stops), center: .center))
                .frame(width: size, height: size)
        }
    }
}
