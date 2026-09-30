import SwiftUI
import AidesCore

// GÉRER LES CATÉGORIES — port de `openCatMgr`, `catMgrScopes`, `catMgrRowsHtml`, `catPickHtml`,
// `catPrevHtml`, `catRegHtml` et des maths de couleur (`hexToOklch`, `catHueHex`, `catHueSnap`,
// `dEok`, `catLisible`, `catSafeTwin`) — reproduites À L'IDENTIQUE (index.html l. 8744-8772,
// 26127-26137) : un degré du curseur doit rendre la MÊME couleur que la PWA, sinon deux appareils
// d'un même compte ne s'accorderaient plus sur la teinte d'une catégorie synchronisée.
//
// UNE SECTION PAR BIBLIOTHÈQUE (A298/A311) : sur « Toutes » (« * »), chaque périmètre ÉDITABLE a
// son intertitre, son « Ajouter » en tête (A308), ses rangées de 44 pt ; la palette ne s'ouvre que
// pour UNE catégorie à la fois. La couleur est un GARDE-FOU, jamais une migration (A408, C3) : une
// couleur trop proche d'un registre se signale, rien n'est réécrit d'office.

// MARK: - Maths de couleur (OKLab / OKLCH, sans dépendance)

enum CatColor {
    static let palette = Library.palette
    /// `CAT_REGS` : rouge critique, rouge de trait, ambre, ambre de trait, vert.
    static let registers = ["#a32e1f", "#c43d34", "#7a5900", "#b45309", "#1d7a38"]
    /// `CAT_OLD` : anciennes couleurs du nuancier → leur remplaçante.
    static let legacy: [String: String] = ["#b23240": "#7a2f6b", "#8d5c39": "#905a39", "#786824": "#6f684a",
                                           "#4f6b1e": "#4f6727", "#096e50": "#116b4c"]

    /// `hexToRgb` : « #rgb » ou « #rrggbb » → [0…1]³.
    static func rgb(_ hex: String) -> [Double] {
        var h = String(hex.dropFirst())
        if h.count < 6 { h = h.map { "\($0)\($0)" }.joined() }
        let chars = Array(h)
        return [0, 2, 4].map { i -> Double in
            guard i + 2 <= chars.count, let v = UInt8(String(chars[i..<i + 2]), radix: 16) else { return 0 }
            return Double(v) / 255
        }
    }
    /// `rgbToHex` : arrondi `Math.round`, bornes [0,1].
    static func hex(_ rgb: [Double]) -> String {
        "#" + rgb.map { v -> String in
            let n = Int(JS.round(max(0, min(1, v)) * 255))
            let s = String(n, radix: 16)
            return s.count < 2 ? "0" + s : s
        }.joined()
    }
    static func lin(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
    static func gam(_ x: Double) -> Double {
        let v = max(0, min(1, x))
        return v <= 0.0031308 ? 12.92 * v : 1.055 * pow(v, 1 / 2.4) - 0.055
    }
    static func oklab(_ c: [Double]) -> [Double] {
        let R = lin(c[0]), G = lin(c[1]), B = lin(c[2])
        let l = cbrt(0.4122214708 * R + 0.5363325363 * G + 0.0514459929 * B)
        let m = cbrt(0.2119034982 * R + 0.6806995451 * G + 0.1073969566 * B)
        let s = cbrt(0.0883024619 * R + 0.2817188376 * G + 0.6299787005 * B)
        return [0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
                1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
                0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s]
    }
    static func rgbFromOklab(_ L: Double, _ a: Double, _ b: Double) -> [Double] {
        let l_ = L + 0.3963377774 * a + 0.2158037573 * b
        let m_ = L - 0.1055613458 * a - 0.0638541728 * b
        let s_ = L - 0.0894841775 * a - 1.2914855480 * b
        let l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_
        return [gam(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
                gam(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
                gam(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)]
    }
    static func oklchHex(_ L: Double, _ C: Double, _ h: Double) -> String {
        let r = h * Double.pi / 180
        return hex(rgbFromOklab(L, C * cos(r), C * sin(r)))
    }
    /// `hexToOklch` : (L, C, h en degrés dans [0, 360)).
    static func oklch(_ hexStr: String) -> (L: Double, C: Double, h: Double) {
        let o = oklab(rgb(hexStr))
        var h = atan2(o[2], o[1]) * 180 / Double.pi
        if h < 0 { h += 360 }
        return (o[0], (o[1] * o[1] + o[2] * o[2]).squareRoot(), h)
    }
    /// `catHueDeg` : degré entier de la teinte.
    static func hueDeg(_ hexStr: String) -> Int { Int(JS.round(oklch(hexStr).h)) % 360 }
    /// `dEok` : ΔE OKLab × 100.
    static func dE(_ a: String, _ b: String) -> Double {
        let A = oklab(rgb(a)), B = oklab(rgb(b))
        let d0 = A[0] - B[0], d1 = A[1] - B[1], d2 = A[2] - B[2]
        return 100 * (d0 * d0 + d1 * d1 + d2 * d2).squareRoot()
    }
    static func relY(_ hexStr: String) -> Double {
        let c = rgb(hexStr).map(lin)
        return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
    }
    static func wcag(_ a: String, _ b: String) -> Double {
        let A = relY(a), B = relY(b)
        return (max(A, B) + 0.05) / (min(A, B) + 0.05)
    }
    /// `catLisible` : blanc sur la couleur ET la couleur sur sa teinte à 15 % — tous deux ≥ 4,5.
    static func lisible(_ col: String) -> Bool {
        let tint = hex(rgb(col).map { $0 * 0.15 + 0.85 })
        return wcag("#ffffff", col) >= 4.5 && wcag(col, tint) >= 4.5
    }
    /// `CAT_ANK` : les presets triés par teinte (l'anneau passe PAR eux, A314).
    static let anchors: [(L: Double, C: Double, h: Double)] = palette.map { oklch($0) }.sorted { $0.h < $1.h }
    /// `catHueHex(h)` : L et C interpolées entre les deux presets voisins, clarté abaissée par
    /// pas de 0,004 jusqu'à la lisibilité (plancher 0,40).
    static func hueHex(_ deg: Double) -> String {
        let h = (deg.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let n = anchors.count
        var i = anchors.firstIndex { h < $0.h } ?? -1
        if i < 0 { i = 0 }
        let b = anchors[(i - 1 + n) % n], c = anchors[i]
        let hb = b.h
        var hc = c.h
        if hc <= hb { hc += 360 }
        var hh = h
        if hh < hb { hh += 360 }
        let t = (hh - hb) / (hc - hb)
        var L = b.L + (c.L - b.L) * t
        let C = b.C + (c.C - b.C) * t
        var out = oklchHex(L, C, h)
        while !lisible(out) && L > 0.40 { L -= 0.004; out = oklchHex(L, C, h) }
        return out
    }
    /// `catHueSnap(h, orig)` : à un degré, TOUJOURS la même couleur — l'origine, puis un preset, puis l'anneau.
    static func hueSnap(_ h: Int, original: String?) -> String {
        if let o = original, hueDeg(o) == h { return o }
        if let p = palette.first(where: { hueDeg($0) == h }) { return p }
        return hueHex(Double(h))
    }
    static func nearRegister(_ col: String) -> Bool { registers.contains { dE(col, $0) < 6.2 } }
    /// `catSafeTwin` : la teinte voisine sûre.
    static func safeTwin(_ col: String) -> String {
        if let o = legacy[col] { return o }
        let h = hueHex(Double(hueDeg(col)))
        if nearRegister(h) {
            return palette.sorted { dE(col, $0) < dE(col, $1) }.first { !nearRegister($0) } ?? palette[0]
        }
        return h
    }
    /// Dégradé du curseur : `catHueHex` tous les 15°.
    static let ringStops: [Color] = stride(from: 0, through: 360, by: 15).map { Color(cssHex: hueHex(Double($0))) }
}

// MARK: - Le gestionnaire

struct CategoryManagerView: View {
    /// nil = Perso ; « * » = tous les périmètres ÉDITABLES ; sinon l'id d'une bibliothèque.
    var scope: String?

    init(scope: String?) { self.scope = scope }

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    /// Nom saisi dans « Ajouter », par périmètre ('' = Perso).
    @State private var newNames: [String: String] = [:]
    /// Rangée dont la palette est ouverte (clé « périmètre|id »).
    @State private var openKey: String?
    /// Couleur de la rangée à l'ouverture de sa palette (`catPickOrig`).
    @State private var openOriginal: String?
    /// Curseur de teinte déplié (nil = d'office : ouvert si la couleur n'est pas un preset).
    @State private var hueOpen: Bool?
    /// Rangée dont la suppression est demandée, et sa cible de déplacement.
    @State private var deleteKey: String?
    @State private var moveTarget = ""
    /// Ordre des rangées, figé à l'ouverture et aux ajouts/suppressions : renommer ne fait pas sauter la liste.
    @State private var order: [String: [String]] = [:]

    var body: some View {
        AcctWindow(title: "Gérer les catégories", maxWidth: 720, onClose: { dismiss() }) {
            let scopes = managedScopes
            if scopes.isEmpty {
                Text("Cette bibliothèque est en lecture seule : ses catégories sont gérées par ses administrateurs.")
                    .aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(scopes, id: \.self) { s in
                    section(s.isEmpty ? nil : s)
                }
            }
        }
        .onAppear { resort() }
    }

    /// `catMgrScopes()` : « * » → Perso puis chaque bibliothèque triée par nom ; ne restent que les
    /// périmètres ÉDITABLES (un prédicat unique, A305). '' représente Perso.
    private var managedScopes: [String] {
        var all: [String]
        if scope == "*" {
            all = [""] + model.profile.libraries.sorted { acctNameLess($0.name, $1.name) }.map(\.id)
        } else {
            all = [scope ?? ""]
        }
        all = all.filter { model.library.canEdit(scope: $0.isEmpty ? nil : $0) }
        return all
    }

    private func key(_ c: Category) -> String { (c.library ?? "") + "|" + c.id }

    private func resort() {
        var o: [String: [String]] = [:]
        for s in [""] + model.profile.libraries.map(\.id) {
            let lib: String? = s.isEmpty ? nil : s
            o[s] = model.categories.filter { $0.library == lib }.sorted { acctNameLess($0.name, $1.name) }.map(\.id)
        }
        order = o
    }

    /// Catégories d'un périmètre dans l'ordre figé (les nouvelles venues en fin, jusqu'au prochain tri).
    private func rows(_ lib: String?) -> [Category] {
        let cats = model.categories.filter { $0.library == lib }
        let ids = order[lib ?? ""] ?? []
        var out: [Category] = ids.compactMap { id in cats.first { $0.id == id } }
        for c in cats where !ids.contains(c.id) { out.append(c) }
        return out
    }

    /// `catItems(id, scope)` : aides ET protocoles de ce périmètre portant cette catégorie.
    private func count(_ c: Category) -> Int { model.library.items(inCategory: c.id, scope: c.library) }

    // MARK: Section

    @ViewBuilder
    private func section(_ lib: String?) -> some View {
        let list = rows(lib)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: lib == nil ? "person" : "books.vertical").font(.system(size: 12, weight: .semibold)).foregroundStyle(T.ink2)
                Text(lib == nil ? "Espace personnel" : libName(lib)).aFont(TypeScale.body, .bold).foregroundStyle(T.ink)
                if lib != nil { Text("partagée").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2) }
                Spacer()
                Text("\(list.count)").aFont(TypeScale.meta, .bold, .mono).foregroundStyle(T.ink2)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            addRow(lib)
            WorkCard(padding: 0) {
                VStack(spacing: 0) {
                    if list.isEmpty {
                        Text("Aucune catégorie pour le moment.").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                            .padding(12)
                    }
                    ForEach(Array(list.enumerated()), id: \.element.id) { i, c in
                        if i > 0 { Divider().overlay(T.line) }
                        CatManagerRow(category: c,
                                      count: count(c),
                                      siblings: list,
                                      open: openKey == key(c),
                                      hueOpen: hueOpen ?? !CatColor.palette.contains(c.color),
                                      asking: deleteKey == key(c),
                                      moveTarget: $moveTarget,
                                      original: openOriginal,
                                      onToggle: { toggle(c) },
                                      onToggleHue: { hueOpen = !(hueOpen ?? !CatColor.palette.contains(c.color)) },
                                      onRename: { rename(c, $0) },
                                      onColor: { setColor(c, $0) },
                                      onAskDelete: { deleteKey = key(c); moveTarget = "" },
                                      onCancelDelete: { deleteKey = nil },
                                      onConfirmDelete: { confirmDelete(c) })
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    private func libName(_ lib: String?) -> String {
        let n = model.library.libraryName(lib)
        return n.isEmpty ? "Bibliothèque partagée" : n
    }

    private func addRow(_ lib: String?) -> some View {
        let k = lib ?? ""
        let binding = Binding<String>(get: { newNames[k] ?? "" }, set: { newNames[k] = $0 })
        return HStack(spacing: 8) {
            TextField(lib == nil ? "Nouvelle catégorie…" : "Nouvelle catégorie partagée…", text: binding)
                .aFont(TypeScale.item, .regular)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(minHeight: Ctrl.m)
                .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                .accessibilityLabel("Nom de la nouvelle catégorie")
                .submitLabel(.done)
                .onSubmit { add(lib) }
            Button("Ajouter") { add(lib) }
                .buttonStyle(.a(.primary, Ctrl.m))
        }
    }

    // MARK: Opérations (chacune finit par `saveCats(scope)`)

    private func add(_ lib: String?) {
        let k = lib ?? ""
        let name = JS.trim(newNames[k] ?? "")
        guard !name.isEmpty else { return }
        var cats = model.categories
        let n = cats.filter { $0.library == lib }.count
        cats.append(Category(id: model.library.newCategoryId(name, scope: lib), name: name,
                             color: CatColor.palette[n % CatColor.palette.count], library: lib))
        model.setCategories(cats, scope: lib)
        newNames[k] = ""
        resort()
    }
    /// Renommer EN DIRECT (valeur brute, comme `c.name = e.target.value`).
    private func rename(_ c: Category, _ name: String) {
        var n = c
        n.name = name
        model.library.updateCategory(n)
        model.refresh()
    }
    private func setColor(_ c: Category, _ col: String) {
        var n = c
        n.color = col
        model.library.updateCategory(n)
        model.refresh()
    }
    private func toggle(_ c: Category) {
        if openKey == key(c) { openKey = nil } else { openKey = key(c); openOriginal = c.color; hueOpen = nil }
    }
    private func confirmDelete(_ c: Category) {
        model.library.deleteCategory(c, moveTo: moveTarget)
        model.refresh()
        deleteKey = nil
        if openKey == key(c) { openKey = nil }
        resort()
    }
}

// MARK: - Une rangée (44 pt) : pastille · nom · compte · ×, puis palette ou confirmation

private struct CatManagerRow: View {
    var category: Category
    var count: Int
    var siblings: [Category]
    var open: Bool
    var hueOpen: Bool
    var asking: Bool
    @Binding var moveTarget: String
    var original: String?
    var onToggle: () -> Void
    var onToggleHue: () -> Void
    var onRename: (String) -> Void
    var onColor: (String) -> Void
    var onAskDelete: () -> Void
    var onCancelDelete: () -> Void
    var onConfirmDelete: () -> Void

    @State private var name = ""
    @State private var hue: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            top
            if CatColor.nearRegister(category.color) { registerWarning }
            if open { palette }
            if asking { deleteConfirm }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(asking ? T.amb2 : Color.clear)
        .onAppear { name = category.name; hue = Double(CatColor.hueDeg(category.color)) }
        .onChange(of: category.color) { _, col in hue = Double(CatColor.hueDeg(col)) }
    }

    private var top: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Circle().fill(Color(cssHex: category.color))
                    .frame(width: 22, height: 22)
                    .overlay(Circle().strokeBorder(open ? T.act : Color.clear, lineWidth: 2).padding(-4))
                    .frame(width: Ctrl.l, height: Ctrl.l)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Couleur de « " + category.name + " »")
            .accessibilityValue(open ? "palette ouverte" : "palette fermée")
            TextField("", text: $name)
                .aFont(TypeScale.item, .semibold)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .frame(minHeight: Ctrl.m)
                .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
                .accessibilityLabel("Nom de la catégorie")
                .onChange(of: name) { _, v in if v != category.name { onRename(v) } }
            Text(acctPlural(count, "élément", "éléments"))
                .aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
                .frame(width: 84, alignment: .trailing)
                .lineLimit(1)
            Button(action: onAskDelete) {
                Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                    .frame(width: Ctrl.l, height: Ctrl.l).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(T.ink2)
            .accessibilityLabel("Supprimer")
        }
        .frame(minHeight: Ctrl.l)
    }

    private var registerWarning: some View {
        let twin = CatColor.safeTwin(category.color)
        return HStack(spacing: 8) {
            Text("△ Proche d’une couleur d’alerte").aFont(TypeScale.meta, .bold).foregroundStyle(T.warn)
            Button { onColor(twin) } label: {
                HStack(spacing: 6) {
                    Circle().fill(Color(cssHex: twin)).frame(width: 12, height: 12)
                    Text("Prendre la teinte voisine").aFont(TypeScale.meta, .bold)
                }
                .frame(minHeight: Ctrl.s)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(T.act)
        }
    }

    // MARK: Palette : 12 presets + « Autre teinte », curseur sur l'anneau, aperçu

    private var palette: some View {
        VStack(alignment: .leading, spacing: 10) {
            ImportFlow(spacing: 8, lineSpacing: 8) {
                ForEach(Array(CatColor.palette.enumerated()), id: \.offset) { i, col in
                    swatch(col, index: i)
                }
                Button(action: onToggleHue) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(hueOpen ? T.primarySoft : T.amb2, in: Circle())
                        .overlay(Circle().strokeBorder(hueOpen ? T.act : T.ctlLine))
                }
                .buttonStyle(.plain)
                .foregroundStyle(T.ink)
                .accessibilityLabel("Autre teinte")
                .accessibilityValue(hueOpen ? "déplié" : "replié")
                .help("Autre teinte")
            }
            if hueOpen { hueSlider; preview }
        }
        .padding(.bottom, 6)
    }

    private func swatch(_ col: String, index i: Int) -> some View {
        let on = category.color == col
        return Button { onColor(col) } label: {
            Circle().fill(Color(cssHex: col))
                .frame(width: 32, height: 32)
                .overlay(Circle().strokeBorder(T.work, lineWidth: on ? 3 : 0).padding(2))
                .overlay(Circle().strokeBorder(on ? T.ink : Color.clear, lineWidth: 2))
                .overlay { if on { Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy)).foregroundStyle(.white) } }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Teinte \(i + 1)")
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }

    private var hueSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Autre teinte").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink)
                Spacer()
                Text("\(Int(hue))°").aFont(TypeScale.meta, .bold, .mono).foregroundStyle(T.ink2)
            }
            Slider(value: $hue, in: 0...359, step: 1, onEditingChanged: { editing in
                // Peint en direct pendant le geste, enregistré au relâchement (`onchange`).
                if !editing { onColor(CatColor.hueSnap(Int(hue), original: original)) }
            })
            .tint(Color(cssHex: CatColor.hueSnap(Int(hue), original: original)))
            .background(
                LinearGradient(colors: CatColor.ringStops, startPoint: .leading, endPoint: .trailing)
                    .frame(height: 6)
                    .clipShape(Capsule())
            )
            .accessibilityLabel("Teinte, en degrés")
            .accessibilityValue("\(Int(hue)) degrés")
        }
    }

    /// `catPrevHtml` : pastille teintée + pastille pleine au texte blanc + note.
    private var preview: some View {
        let col = CatColor.hueSnap(Int(hue), original: original)
        let near = siblings.filter { $0.id != category.id }
            .map { ($0, CatColor.dE(col, $0.color)) }
            .filter { $0.1 < 4 }
            .sorted { $0.1 < $1.1 }
            .first
        let note: (String, Bool) = near.map { ("△ proche de « " + $0.0.name + " »", false) }
            ?? (CatColor.lisible(col) ? ("✓ lisible", true) : ("△ contraste faible", false))
        let tint = CatColor.hex(CatColor.rgb(col).map { $0 * 0.15 + 0.85 })
        return ImportFlow(spacing: 8) {
            Text(category.name.isEmpty ? " " : category.name).aFont(TypeScale.meta, .bold)
                .foregroundStyle(Color(cssHex: col))
                .padding(.horizontal, 10).frame(minHeight: 26)
                .background(Color(cssHex: tint), in: Capsule())
            Text(category.name.isEmpty ? " " : category.name).aFont(TypeScale.meta, .bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 10).frame(minHeight: 26)
                .background(Color(cssHex: col), in: Capsule())
            Text(note.0).aFont(TypeScale.meta, .bold).foregroundStyle(note.1 ? T.ok : T.warn)
        }
    }

    // MARK: Confirmation de suppression (sous la rangée, fond gris `.ask`)

    private var deleteQuestion: String {
        let what = count > 1 ? "ces éléments" : "cet élément"
        return "« \(category.name) » contient **\(count)** élément\(acctS(count)). Choisissez où déplacer \(what) avant de supprimer la catégorie :"
    }

    @ViewBuilder
    private var deleteConfirm: some View {
        let others = siblings.filter { $0.id != category.id }
        VStack(alignment: .leading, spacing: 8) {
            if count > 0 {
                BoldText(text: deleteQuestion,
                         size: TypeScale.body, color: T.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Picker("Destination", selection: $moveTarget) {
                    Text("Laisser sans catégorie").tag("")
                    ForEach(others) { o in Text("Déplacer vers « " + o.name + " »").tag(o.id) }
                }
                .labelsHidden()
            } else {
                Text("Supprimer « " + category.name + " » ? (catégorie vide)")
                    .aFont(TypeScale.body, .regular).foregroundStyle(T.ink)
            }
            HStack(spacing: 8) {
                Button(count > 0 ? "Déplacer puis Supprimer" : "Supprimer", action: onConfirmDelete)
                    .buttonStyle(.a(.danger, Ctrl.m))
                Button("Annuler", action: onCancelDelete)
                    .buttonStyle(.a(.secondary, Ctrl.m))
            }
        }
        .padding(.bottom, 6)
    }
}
