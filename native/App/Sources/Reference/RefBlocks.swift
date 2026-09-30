import SwiftUI
import AidesCore

// LE CORPS RÉDIGÉ D'UNE RÉFÉRENCE — un rendu par bloc de `Markdown.document` (`mdRender`), avec
// la grammaire de lecture de la PWA (`.ref-main .md-body`) : texte 15, titres 17,5/800 en bas de
// casse avec chevron à GAUCHE et filet entre sections (v5.30), encadrés au registre écrit en
// toutes lettres, tableaux qui DÉFILENT au lieu d'écraser leurs colonnes (lisibilité sous
// stress), cases cochables en LECTURE seulement (jamais barrées : on doit pouvoir relire).

/// Ce dont un bloc a besoin pour se peindre (état de la vue, sans la vue).
struct RefBlockContext {
    var layout: RefLayout
    var find: RefFind
    var hits: RefHits
    /// Coches éphémères des listes cochables (`state.protoTasks`), par index de tâche.
    var tasks: [Int: Bool]
    /// Largeur de la colonne de lecture (points déjà divisés par le zoom) — la réduction d'image
    /// ne s'applique qu'au-dessus de 560 (sur un téléphone, 25 % ferait ~90 px : illisible).
    var width: CGFloat
    var closed: Set<String>
    /// Titre brièvement signalé après un saut du sommaire (`.flash`).
    var flash: Int?
    var first: Int?

    func base(_ u: RefUnit, _ parts: [RefPart], _ k: Int) -> Int {
        var b = hits.start[u] ?? 0
        for p in parts.prefix(k) { b += find.count(p) }
        return b
    }
    func text(_ u: RefUnit, _ parts: [RefPart], _ k: Int) -> AttributedString {
        RefInline(find: find, base: base(u, parts, k)).attributed(parts[k])
    }
}

/// Un bloc du corps. `onFold` / `onTask` / `onImage` remontent les gestes à la vue.
struct RefBlockView: View {
    let block: Markdown.RBlock
    let index: Int
    let ctx: RefBlockContext
    var onFold: (Int) -> Void
    var onTask: (Int, Bool) -> Void
    var onImage: (ImageRef, String) -> Void

    var body: some View {
        let units = refUnits(block, at: index)
        switch block {
        case .heading(let h):
            RefHeadingView(h: h, index: index, text: ctx.text(units[0].0, units[0].1, 0),
                           closed: h.foldKey.map { ctx.closed.contains($0) } ?? false,
                           first: ctx.first == index, flash: ctx.flash == index,
                           searchCount: ctx.find.active && h.foldKey != nil ? ctx.hits.inSection(ctx.layout, index) : nil,
                           onFold: { onFold(index) })
                .id(units[0].0.anchor)
        case .paragraph:
            VStack(alignment: .leading, spacing: 0) {
                ForEach(units.indices, id: \.self) { k in
                    line(ctx.text(units[k].0, units[k].1, 0)).id(units[k].0.anchor)
                }
            }
            .padding(.bottom, 10)
        case .list(let ordered, let items):
            RefListView(ordered: ordered, items: items, units: units, ctx: ctx, onTask: onTask)
                .padding(.bottom, 10)
        case .quote(let callout, _):
            RefQuoteView(callout: callout, units: units, ctx: ctx)
                .padding(.bottom, 10)
        case .code:
            ScrollView(.horizontal, showsIndicators: true) {
                Text(ctx.text(units[0].0, units[0].1, 0))
                    .aFont(TypeScale.meta, .regular, .mono)
                    .foregroundStyle(T.ink)
                    .fixedSize(horizontal: true, vertical: false)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12).padding(.vertical, 10)
            }
            .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).strokeBorder(T.line))
            .id(units[0].0.anchor)
            .padding(.bottom, 10)
        case .hr:
            Rectangle().fill(T.line).frame(height: 1).padding(.vertical, 14)
                .accessibilityHidden(true)
        case .image(let im, let caption):
            RefFigure(im: im, caption: caption, width: ctx.width,
                      captionText: units.first.map { ctx.text($0.0, $0.1, 0) }) { onImage(im, caption) }
                .id(units.first?.0.anchor ?? "u\(index)-0")
        case .table(let align, _, _):
            RefTableView(align: align, units: units, ctx: ctx)
                .padding(.bottom, 12)
        }
    }

    private func line(_ a: AttributedString) -> some View {
        Text(a).aFont(TypeScale.item, .regular).foregroundStyle(T.ink)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
    }
}

// MARK: - Titre repliable (A171)

/// Le titre RESTE un titre (trait d'en-tête) ; le bouton vit dedans, sur toute la largeur — sur
/// un document, le geste naturel est de taper le titre, pas de viser un chevron. Chevron à
/// gauche (v5.30) : fermé il pointe à DROITE, ouvert en BAS (convention des arborescences).
struct RefHeadingView: View {
    let h: Markdown.RHeading
    let index: Int
    let text: AttributedString
    let closed: Bool
    let first: Bool
    let flash: Bool
    /// En recherche : occurrences dans la section (0 → section repliée d'office, transitoire).
    let searchCount: Int?
    var onFold: () -> Void

    var body: some View {
        let size: CGFloat = h.level == 3 ? TypeScale.item : TypeScale.step
        let label = Text(text).aFont(size, .heavy).foregroundStyle(T.ink)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        VStack(spacing: 0) {
            if !first { Rectangle().fill(T.line).frame(height: 1) }
            Group {
                if h.foldKey != nil {
                    Button(action: onFold) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(T.ink3)
                                .rotationEffect(.degrees(closed || searchCount == 0 ? 0 : 90))
                                .animation(.easeOut(duration: 0.18), value: closed)
                                .frame(width: 16)
                                .accessibilityHidden(true)
                            label
                        }
                        .frame(minHeight: Ctrl.s)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(closed ? "replié" : "déplié")
                    .accessibilityHint(closed ? "Déplier la section" : "Replier la section")
                } else {
                    label.frame(minHeight: Ctrl.s)
                }
            }
            .padding(.top, 10).padding(.bottom, 4)
            .padding(.horizontal, 6)
            .background(flash ? T.primarySoft : Color.clear, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
            .padding(.horizontal, -6)
            .animation(.easeOut(duration: 0.3), value: flash)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Listes (et listes cochables, v4.5.4)

struct RefListView: View {
    let ordered: Bool
    let items: [Markdown.RItem]
    let units: [(RefUnit, [RefPart])]
    let ctx: RefBlockContext
    var onTask: (Int, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(items.indices, id: \.self) { k in
                item(k).id(units[k].0.anchor)
            }
        }
    }

    @ViewBuilder
    private func item(_ k: Int) -> some View {
        let it = items[k]
        let u = units[k]
        if let t = it.task {
            let done = ctx.tasks[t.index] ?? t.done
            Button { onTask(t.index, !done) } label: {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(done ? T.ok : Color.clear)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(done ? T.ok : T.lineStrong, lineWidth: 2)
                        if done {
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy)).foregroundStyle(T.work)
                        }
                    }
                    .frame(width: 20, height: 20)
                    .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] + 5 }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ctx.text(u.0, u.1, 0)).aFont(TypeScale.item, .regular)
                            .foregroundStyle(done ? T.ink2 : T.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        sub(it, u)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4).padding(.horizontal, 8)
                .frame(minHeight: Ctrl.s)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, -8)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isToggle)
            .accessibilityValue(done ? "coché" : "non coché")
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                marker(k, ordered)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ctx.text(u.0, u.1, 0)).aFont(TypeScale.item, .regular).foregroundStyle(T.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                    sub(it, u)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func sub(_ it: Markdown.RItem, _ u: (RefUnit, [RefPart])) -> some View {
        if let s = it.sub, !s.items.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(s.items.indices, id: \.self) { j in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        marker(j, s.ordered)
                        Text(ctx.text(u.0, u.1, j + 1)).aFont(TypeScale.item, .regular).foregroundStyle(T.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(.top, 2)
        }
    }

    private func marker(_ k: Int, _ ordered: Bool) -> some View {
        Text(ordered ? "\(k + 1)." : "•")
            .aFont(TypeScale.item, ordered ? .semibold : .bold, ordered ? .mono : .ui)
            .foregroundStyle(ordered ? T.ink2 : T.lineStrong)
            .frame(minWidth: 14, alignment: .trailing)
            .accessibilityHidden(!ordered)
    }
}

// MARK: - Citations et encadrés typés (v4.4.3)

/// Grammaire des notices : bord gauche 4 + bordure + teinte du registre, glyphe ET libellé en
/// toutes lettres (la couleur n'est jamais seule, WCAG 1.4.1). Aucune couleur nouvelle.
struct RefQuoteView: View {
    let callout: Markdown.Callout?
    let units: [(RefUnit, [RefPart])]
    let ctx: RefBlockContext

    var body: some View {
        if let c = callout {
            let col = colors(c)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    glyph(c)
                    Text(c.label.uppercased()).aFont(TypeScale.cap, .heavy).tracking(0.8)
                }
                .foregroundStyle(col.ink)
                lines
            }
            .padding(.vertical, 8).padding(.horizontal, 12).padding(.leading, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(col.bg, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).strokeBorder(col.line))
            .overlay(alignment: .leading) {
                UnevenRoundedRectangle(topLeadingRadius: Radius.r1, bottomLeadingRadius: Radius.r1, style: .continuous)
                    .fill(col.edge).frame(width: 4)
            }
            .accessibilityElement(children: .combine)
        } else {
            lines
                .padding(.vertical, 6).padding(.leading, 12)
                .overlay(alignment: .leading) { Rectangle().fill(T.lineStrong).frame(width: 3) }
        }
    }

    private var lines: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(units.indices, id: \.self) { k in
                Text(ctx.text(units[k].0, units[k].1, 0))
                    .aFont(TypeScale.item, .regular)
                    .foregroundStyle(callout == nil ? T.ink2 : T.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .id(units[k].0.anchor)
            }
        }
    }

    @ViewBuilder
    private func glyph(_ c: Markdown.Callout) -> some View {
        switch c {
        case .crit: Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 12, weight: .bold))
        case .vig: Text("△").aFont(TypeScale.meta, .heavy)
        case .ok: Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy))
        case .info: Image(systemName: "info.circle").font(.system(size: 12, weight: .bold))
        }
    }

    private func colors(_ c: Markdown.Callout) -> (bg: Color, line: Color, edge: Color, ink: Color) {
        switch c {
        case .crit: return (T.critSoft, T.criticalLine, T.critLine, T.crit)
        case .vig: return (T.warnSoft, T.verifyLine, T.warnLine, T.warn)
        case .info: return (T.primarySoft, T.act, T.act, T.act)
        case .ok: return (T.okSoft, T.ok, T.ok, T.ok)
        }
    }
}

// MARK: - Tableaux (v4.4.2)

/// Conteneur DÉFILANT (sur iPhone le tableau défile au lieu d'écraser ses colonnes à 40 px) ;
/// en-têtes au registre des titres de section ; colonnes alignées d'un jeu fermé, chiffres
/// tabulaires à droite.
struct RefTableView: View {
    let align: [Markdown.Align]
    let units: [(RefUnit, [RefPart])]
    let ctx: RefBlockContext

    var body: some View {
        let cols = units.map { $0.1.count }.max() ?? 0
        ScrollView(.horizontal, showsIndicators: true) {
            Grid(alignment: .topLeading, horizontalSpacing: 0, verticalSpacing: 0) {
                ForEach(units.indices, id: \.self) { r in
                    GridRow {
                        ForEach(0..<cols, id: \.self) { c in
                            cell(r, c).id(c == 0 ? units[r].0.anchor : units[r].0.anchor + "-c\(c)")
                        }
                    }
                    if r < units.count - 1 {
                        Rectangle().fill(T.line).frame(height: 1).gridCellUnsizedAxes(.horizontal)
                    }
                }
            }
            .frame(minWidth: max(440, ctx.width - 2), alignment: .leading)
        }
        .overlay(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).strokeBorder(T.line))
        .clipShape(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tableau")
    }

    @ViewBuilder
    private func cell(_ r: Int, _ c: Int) -> some View {
        let parts = units[r].1
        let a: Markdown.Align = c < align.count ? align[c] : .none
        let al: Alignment = a == .center ? .top : (a == .right ? .topTrailing : .topLeading)
        let ta: TextAlignment = a == .center ? .center : (a == .right ? .trailing : .leading)
        Group {
            if c < parts.count {
                if r == 0 {
                    Text(ctx.text(units[r].0, parts, c))
                        .aFont(TypeScale.cap, .heavy).tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(T.ink2)
                        .lineLimit(1)
                        .fixedSize()
                } else {
                    Text(ctx.text(units[r].0, parts, c))
                        .aFont(TypeScale.body, .regular, a == .right ? .mono : .ui)
                        .foregroundStyle(T.ink)
                        .multilineTextAlignment(ta)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            } else {
                Text(verbatim: "")
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: al)
        .background(r == 0 ? T.amb2 : Color.clear)
    }
}

// MARK: - Images

/// Figure : taille d'affichage PAR IMAGE (jeu fermé), appliquée au-dessus de 560 de large
/// seulement ; bordure, coins `--r-1`, légende 12. Un tap agrandit (`openLightbox`).
struct RefFigure: View {
    let im: ImageRef
    let caption: String
    let width: CGFloat
    let captionText: AttributedString?
    var open: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let img = RefImages.image(im) {
                Button(action: open) {
                    Image(refPlatform: img)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Radius.r1, style: .continuous).strokeBorder(T.line))
                        .frame(maxWidth: maxW, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(caption.isEmpty ? "Image" : caption)
                .accessibilityHint("Agrandir l’image")
            }
            if let captionText {
                Text(captionText).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var maxW: CGFloat {
        let natural: CGFloat = im.w > 0 ? CGFloat(im.w) : .infinity
        let scaled: CGFloat = (width >= 560 && [25, 33, 50, 66, 75].contains(im.scale)) ? width * CGFloat(im.scale) / 100 : .infinity
        return min(natural, scaled)
    }
}
