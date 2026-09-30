import SwiftUI
import AidesCore

// L'ÉCRAN D'ENTRÉE « Avant la session » (A330/A347/A358) et les CARTES DÉPLIABLES de session.
// Ordre QRH : condition (« Quand l'utiliser ») → memory items (« Ne pas oublier ») → action.
// Le parcours y est INERTE : aucune case, et le toucher ne démarre jamais la session.

struct CrEntryView: View {
    let ctx: CrCtx
    let vs: CrisisViewState

    var body: some View {
        let f = ctx.f
        let crit = Pool.list(f, .entry)
        let forget = Pool.forget(f)
        let watch = Pool.list(f, .watch)
        let ddx = Pool.list(f, .ddx)
        let dose = Pool.list(f, .dose)
        let nDec = f.blocks.filter { $0.kind == .decision }.count
        let nBlk = f.blocks.count - nDec
        VStack(alignment: .leading, spacing: 0) {
            if !crit.isEmpty {
                CrFoldCard(icon: CrIconSquare(glyph: "◎", fg: T.act, bg: T.primarySoft), title: "Quand l’utiliser",
                           count: "\(crit.count)", open: isOpen("when", true), toggle: { toggle("when", true) }) {
                    CrItemRows(items: crit)
                    if !ddx.isEmpty {
                        Button {
                            for k in ["when", "forget", "flow", "verify", "poso", "refs"] { set(k, false) }
                            set("diff", true)
                            vs.pendingScroll = "!pre-diff"
                        } label: {
                            Text("Le tableau ne colle pas ? → \(ddx.count) " + either(ddx.count > 1, "diagnostics", "diagnostic") + " à éliminer ▸")
                                .aFont(TypeScale.item, .semibold).foregroundStyle(T.act)
                                .frame(maxWidth: .infinity, minHeight: Ctrl.l, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .id("pre-when")
            }
            if !forget.isEmpty {
                CrFoldCard(icon: CrIconSquare(glyph: "!", fg: T.crit, bg: T.critSoft), title: "Ne pas oublier",
                           count: "\(forget.count)", open: isOpen("forget", true), toggle: { toggle("forget", true) }) {
                    CrForgetRows(items: forget.map(\.item))
                }
                .id("pre-forget")
            }
            CrFoldCard(icon: CrIconSquare(glyph: "⇣", fg: T.ink, bg: T.amb2), title: "Parcours",
                       count: "\(nBlk) bloc" + either(nBlk > 1, "s", "") + (nDec > 0 ? " · \(nDec) décision" + either(nDec > 1, "s", "") : ""),
                       open: isOpen("flow", false), toggle: { toggle("flow", false) }) {
                VStack(alignment: .leading, spacing: 10) {
                    CrLinksRow(ctx: ctx, vs: vs)
                    if ctx.wc != .cockpit {
                        CrParcoursList(ctx: ctx, vs: vs, place: .card)
                    } else {
                        Text("Aperçu dans la colonne de gauche.").aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
                    }
                    let carry = f.timers.map { Fmt.timerName(label: $0.label, type: $0.type) + ($0.type == .interval ? " " + Fmt.ms(Double($0.seconds) * 1000) : "") }
                    if !carry.isEmpty {
                        Text("Minuteurs à disposition en session : " + carry.joined(separator: " · ") + ".")
                            .aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink2)
                    }
                }
                .padding(.vertical, 8)
            }
            .id("pre-flow")
            if !watch.isEmpty {
                CrFoldCard(icon: CrIconSquare(glyph: "△", fg: T.warn, bg: T.warnSoft), title: "À vérifier", count: "\(watch.count)",
                           open: isOpen("verify", false), toggle: { toggle("verify", false) }) { CrItemRows(items: watch, withExpect: true) }
                    .id("pre-verify")
            }
            if !ddx.isEmpty {
                CrFoldCard(icon: CrIconSquare(glyph: "?", fg: T.ink, bg: T.amb2), title: "Diagnostics différentiels", count: "\(ddx.count)",
                           open: isOpen("diff", false), toggle: { toggle("diff", false) }) { CrItemRows(items: ddx, withExpect: true) }
                    .id("pre-diff")
            }
            if !dose.isEmpty && ctx.wc == .phone {
                CrFoldCard(icon: CrIconSquare(glyph: "pills", system: true, fg: T.act, bg: T.primarySoft), title: "Repères posologiques",
                           count: "\(dose.count)", open: isOpen("poso", false), toggle: { toggle("poso", false) }) { CrPosoRows(items: dose) }
                    .id("pre-poso")
            }
            CrFoldCard(icon: CrIconSquare(glyph: "▤", fg: T.ink, bg: T.amb2), title: "Références", count: refCount(f),
                       open: isOpen("refs", false), toggle: { toggle("refs", false) }) { CrRefsBody(ctx: ctx) }
                .id("pre-refs")
            CrTail(ctx: ctx)
        }
        .onAppear { load() }
    }

    // États mémorisés PAR AIDE sur l'appareil (clés « when »/« forget » ouvertes d'office).
    private func isOpen(_ k: String, _ def: Bool) -> Bool { vs.preOpen[k] ?? def }
    private func set(_ k: String, _ v: Bool) {
        vs.preOpen[k] = v
        CrLocal.set("pre:\(ctx.f.id):\(k)", v)
    }
    private func toggle(_ k: String, _ def: Bool) { set(k, !isOpen(k, def)) }
    private func load() {
        guard vs.entryFoldLoaded != ctx.f.id else { return }
        vs.entryFoldLoaded = ctx.f.id
        for k in ["when", "forget", "flow", "verify", "diff", "poso", "refs"] {
            if let v = CrLocal.bool("pre:\(ctx.f.id):\(k)") { vs.preOpen[k] = v }
        }
    }
}

func refCount(_ f: Fiche) -> String {
    let n = f.images.count + f.docs.count + f.sources.filter { !JS.trim($0).isEmpty }.count + f.links.count
    return n > 0 ? "\(n)" : ""
}

/// Rangées plates d'une liste (critères, à vérifier, différentiels) — réponse attendue dessous.
struct CrItemRows: View {
    let items: [Item]
    var withExpect = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, it in
                VStack(spacing: 0) {
                    if i > 0 { Rectangle().fill(T.line).frame(height: 1) }
                    VStack(alignment: .leading, spacing: 2) {
                        BoldText(text: it.do, size: TypeScale.item, weight: .regular, color: T.ink)
                        if withExpect && !it.expect.isEmpty {
                            Text(it.expect).aFont(TypeScale.body, .semibold).foregroundStyle(T.ink2)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.vertical, 6)
                }
            }
        }
    }
}

/// « Ne pas oublier » : le texte, le MOT du registre à droite, la réponse après « · ».
struct CrForgetRows: View {
    let items: [Item]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, it in
                VStack(spacing: 0) {
                    if i > 0 { Rectangle().fill(T.line).frame(height: 1) }
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        (Text(BoldText.attributed(it.do)) + Text(it.expect.isEmpty ? "" : " · " + it.expect).foregroundColor(T.ink2))
                            .aFont(TypeScale.item, .regular).foregroundStyle(T.ink)
                        Spacer(minLength: 6)
                        if it.level == 3 { Text("CRITIQUE").aFont(TypeScale.cap, .heavy).foregroundStyle(T.crit).accessibilityLabel("Étape critique.") }
                        else if it.level == 2 { Text("VIGILANCE").aFont(TypeScale.cap, .heavy).foregroundStyle(T.warn).accessibilityLabel("Vigilance.") }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.vertical, 6)
                }
            }
        }
    }
}

/// Repères posologiques (carte du téléphone) : NOM + corps.
struct CrPosoRows: View {
    let items: [Item]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, it in
                let p = CrisisPure.posoParts(it.legacyString)
                VStack(spacing: 0) {
                    if i > 0 { Rectangle().fill(T.line).frame(height: 1) }
                    VStack(alignment: .leading, spacing: 2) {
                        if !p.name.isEmpty { Text(p.name).aFont(TypeScale.item, .bold).foregroundStyle(it.level >= 2 ? T.warn : T.ink) }
                        if !p.body.isEmpty { BoldText(text: p.body, size: TypeScale.body, weight: .semibold, color: T.ink2) }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.vertical, 6)
                }
            }
        }
    }
}

/// Repères posologiques ordonnés pour le BLOC COURANT (rail) : signalés d'abord, jamais filtrés ;
/// au-delà de 3, le reste se replie derrière « ＋ n autres repères ».
struct CrPosoCards: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    var body: some View {
        let dose = Pool.list(ctx.f, .dose).map { JS.trim($0.legacyString) }.filter { !$0.isEmpty }
        let hay = ctx.tipBlock.map { b in b.title + " " + Graph.cleanSteps(ctx.f, b).joined(separator: " ") } ?? ""
        let sp = CrisisPure.posoSplit(dose, hay: hay)
        let rest = sp.rest
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(sp.head.enumerated()), id: \.offset) { _, r in card(r.s, r.crit) }
            if !rest.isEmpty {
                Button { vs.posoMoreOpen.toggle() } label: {
                    Text(either(vs.posoMoreOpen, "− ", "＋ ") + "\(rest.count) autres repères").aFont(TypeScale.body, .bold).foregroundStyle(T.act)
                        .frame(minHeight: Ctrl.l).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if vs.posoMoreOpen { ForEach(Array(rest.enumerated()), id: \.offset) { _, r in card(r.s, r.crit) } }
            }
        }
    }
    private func card(_ s: String, _ flagged: Bool) -> some View {
        let p = CrisisPure.posoParts(s)
        return VStack(alignment: .leading, spacing: 2) {
            if !p.name.isEmpty || flagged {
                Text(either(flagged, "△ ", "") + p.name.uppercased()).aFont(TypeScale.meta, .bold).foregroundStyle(flagged ? T.warn : T.ink2)
            }
            if !p.body.isEmpty { BoldText(text: p.body, size: TypeScale.body, weight: .semibold, color: T.ink) }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r2, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r2, style: .continuous).strokeBorder(T.workLine, lineWidth: 1))
    }
}

/// Corps de la carte « Références » : schémas & captures, documents, sources, voir aussi.
struct CrRefsBody: View {
    let ctx: CrCtx
    @Environment(AppModel.self) private var model
    var body: some View {
        let f = ctx.f
        let sources = f.sources.filter { !JS.trim($0).isEmpty }
        VStack(alignment: .leading, spacing: 10) {
            if f.images.isEmpty && f.docs.isEmpty && sources.isEmpty && f.links.isEmpty {
                Text("Cette fiche n’a pas encore de contenu à consulter.").aFont(TypeScale.body, .medium).foregroundStyle(T.ink2)
                    .padding(.vertical, 10)
            }
            if !f.images.isEmpty {
                Overline(text: "Schémas & captures")
                ForEach(f.images, id: \.id) { im in
                    VStack(alignment: .leading, spacing: 4) {
                        CrDataImage(dataURI: im.data, maxHeight: 360)
                        if !im.caption.isEmpty { Text(im.caption).aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2) }
                    }
                }
            }
            if !f.docs.isEmpty {
                Overline(text: "Documents (\(f.docs.count))")
                ForEach(f.docs, id: \.id) { d in
                    Button { model.path.append(.pdf(d.id, d.name)) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.richtext").foregroundStyle(T.act)
                            Text(d.name).aFont(TypeScale.item, .semibold).foregroundStyle(T.ink).lineLimit(2)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(T.ink2)
                        }
                        .frame(minHeight: Ctrl.l).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            if !sources.isEmpty {
                Overline(text: "Sources")
                ForEach(Array(sources.enumerated()), id: \.offset) { _, s in
                    BoldText(text: s, size: TypeScale.body, weight: .regular, color: T.ink)
                }
            }
            if !f.links.isEmpty {
                Overline(text: "Voir aussi (\(f.links.count))")
                ForEach(f.links, id: \.self) { id in
                    Button { model.openLinked(id) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.right.square").foregroundStyle(T.act)
                            Text(linkTitle(id)).aFont(TypeScale.item, .semibold).foregroundStyle(T.ink).lineLimit(2)
                            Spacer()
                        }
                        .frame(minHeight: Ctrl.l).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 6)
    }
    private func linkTitle(_ id: String) -> String {
        if let f = model.fiches.first(where: { $0.id == id }) { return f.title.isEmpty ? "Aide" : f.title }
        if let p = model.references.first(where: { $0.id == id }) { return p.title.isEmpty ? "Protocole" : p.title }
        return "Élément introuvable"
    }
}

/// Cartes dépliables SOUS le journal en session (A351/A357) : toutes fermées d'office, transitoires,
/// « Ne pas oublier » d'abord.
struct CrSessionFolds: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    var body: some View {
        let f = ctx.f
        let forget = Pool.forget(f)
        let watch = Pool.list(f, .watch)
        let ddx = Pool.list(f, .ddx)
        let dose = Pool.list(f, .dose)
        let crit = Pool.list(f, .entry)
        let reviews = f.blocks.filter { $0.kind == .review }
        VStack(alignment: .leading, spacing: 0) {
            if !ctx.started && !crit.isEmpty {
                // Aide sans embranchement, avant le premier geste : la condition reste lisible.
                fold("when", CrIconSquare(glyph: "◎", fg: T.act, bg: T.primarySoft), "Quand l’utiliser", "\(crit.count)", openDefault: true) {
                    CrItemRows(items: crit)
                }
            }
            if !forget.isEmpty {
                fold("forget", CrIconSquare(glyph: "!", fg: T.crit, bg: T.critSoft), "Ne pas oublier", "\(forget.count)") {
                    CrForgetRows(items: forget.map(\.item))
                }
            }
            ForEach(reviews, id: \.id) { rb in
                let st = ctx.e.reviewState(ctx.R, rb)
                fold("rev:" + rb.id, CrIconSquare(glyph: "square.grid.2x2", system: true, fg: T.act, bg: T.primarySoft),
                     rb.title.isEmpty ? "Revue" : rb.title, "\(st.k)/\(st.n)") {
                    CrReviewGrid(ctx: ctx, vs: vs, rb: rb).padding(.vertical, 8)
                }
            }
            if !watch.isEmpty {
                fold("verify", CrIconSquare(glyph: "△", fg: T.warn, bg: T.warnSoft), "À vérifier", "\(watch.count)") {
                    CrItemRows(items: watch, withExpect: true)
                }
            }
            if !ddx.isEmpty {
                fold("diff", CrIconSquare(glyph: "?", fg: T.ink, bg: T.amb2), "Diagnostics différentiels", "\(ddx.count)") {
                    CrItemRows(items: ddx, withExpect: true)
                }
            }
            if !dose.isEmpty && ctx.wc == .phone {
                fold("poso", CrIconSquare(glyph: "pills", system: true, fg: T.act, bg: T.primarySoft), "Repères posologiques", "\(dose.count)") {
                    CrPosoRows(items: dose)
                }
            }
            fold("refs", CrIconSquare(glyph: "▤", fg: T.ink, bg: T.amb2), "Références", refCount(f)) { CrRefsBody(ctx: ctx) }
            if ctx.R.flowEnded && !watch.isEmpty {
                Text("Surveillances & pièges").aFont(TypeScale.step, .heavy).foregroundStyle(T.ink)
                    .padding(.top, 20).accessibilityAddTraits(.isHeader)
                CrItemRows(items: watch, withExpect: true)
            }
        }
    }

    private func fold<C: View>(_ k: String, _ icon: CrIconSquare, _ title: String, _ count: String, openDefault: Bool = false,
                               @ViewBuilder _ content: @escaping () -> C) -> some View {
        let open = openDefault ? !vs.sessFold.contains("-" + k) : vs.sessFold.contains(k)
        return CrFoldCard(icon: icon, title: title, count: count, open: open, toggle: {
            let key = openDefault ? "-" + k : k
            if vs.sessFold.contains(key) { vs.sessFold.remove(key) } else { vs.sessFold.insert(key) }
        }, content: content)
        .id("sess-" + k)
    }
}

/// « Tout voir » (mode statique, en session) : onglets « Page » · « Schéma » + « Références » dessous.
struct CrAllView: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                tab("Page", 0)
                tab("Schéma", 1)
                Spacer()
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Façon de regarder l'aide entière")
            Group {
                if vs.allTab == 0 { PageView(ficheId: ctx.f.id) } else { SchemaView(ficheId: ctx.f.id) }
            }
            .frame(minHeight: 420)
            CrSessionFoldsRefsOnly(ctx: ctx, vs: vs)
        }
    }
    private func tab(_ label: String, _ i: Int) -> some View {
        Button { vs.allTab = i } label: {
            Text(label).aFont(TypeScale.body, vs.allTab == i ? .bold : .semibold)
                .foregroundStyle(vs.allTab == i ? T.act : T.ink2)
                .padding(.horizontal, 14)
                .frame(minHeight: Ctrl.l)
                .overlay(alignment: .bottom) { if vs.allTab == i { Rectangle().fill(T.act).frame(height: 2) } }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(vs.allTab == i ? .isSelected : [])
    }
}

/// En mode Page, seule « Références » reste sous la feuille (A392).
struct CrSessionFoldsRefsOnly: View {
    let ctx: CrCtx
    let vs: CrisisViewState
    var body: some View {
        CrFoldCard(icon: CrIconSquare(glyph: "▤", fg: T.ink, bg: T.amb2), title: "Références", count: refCount(ctx.f),
                   open: vs.sessFold.contains("refs"), toggle: {
            if vs.sessFold.contains("refs") { vs.sessFold.remove("refs") } else { vs.sessFold.insert("refs") }
        }) { CrRefsBody(ctx: ctx) }
    }
}
