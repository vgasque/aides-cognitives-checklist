import SwiftUI
import AidesCore

// LECTURE D'UNE RÉFÉRENCE (« protocole » dans la PWA) — port de `renderProtocolRead`.
//
// Ce que l'écran porte, dans l'ordre de lecture : titre (au téléphone ; dans la barre dès 780 —
// A351 : jamais écrit deux fois), méta (bibliothèque, état, catégorie, code, validation), le
// SOMMAIRE (« Sommaire · n sections », dépliant collé sous l'en-tête en voie étroite, colonne à
// gauche dès 1000), la notice d'état, les documents PDF, le corps rédigé (titres repliables
// mémorisés PAR référence, A171), « Voir aussi », « Références ».
// La recherche DANS la référence (`pfRun`) est la recherche SYSTÈME de l'écran : occurrences
// surlignées, ‹ › dans une pastille flottante, sections sans résultat repliées le temps de la
// recherche (jamais mémorisé), compte par titre au sommaire, et les documents joints répondent
// à la même recherche (`pfDocsRun`).
// Une référence est un élément de CONSULTATION : rien n'y démarre, rien n'y est enregistré en
// dehors des replis (préférence locale) — les coches des listes cochables sont éphémères.

struct ReferenceReadView: View {
    let referenceId: String

    @Environment(AppModel.self) private var model
    @Environment(\.widthClass) private var wc
    @Environment(\.textScale) private var zf

    @State private var cache = RefCache()
    @State private var closed: Set<String> = []
    @State private var foldLoaded = false
    @State private var tasks: [Int: Bool] = [:]
    @State private var query = ""
    @State private var find = RefFind()
    @State private var lastTarget: RefUnit?
    /// Sections mises à l'écart par la recherche que l'utilisateur a rouvertes à la main.
    @State private var searchOpened: Set<String> = []
    @State private var tocOpen = false
    @State private var titlePassed = false
    @State private var titleBottom: CGFloat = 60
    @State private var flash: Int?
    @State private var scrollReq: RefScrollRequest?
    @State private var width: CGFloat = 390
    @State private var height: CGFloat = 800
    @State private var bodyWidth: CGFloat = 358
    @State private var lightbox: RefLightboxItem?
    @State private var pdfHit: RefDocHit?
    @State private var docTexts: [String: [String]] = [:]
    @State private var docHits: [RefDocHit] = []
    @State private var confirmDelete = false
    @State private var askDocs = false
    @State private var export: AcctExportRequest?

    var body: some View {
        if let p = model.references.first(where: { $0.id == referenceId }) {
            reading(p)
        } else {
            ContentUnavailableView {
                Label("Protocole introuvable", systemImage: "book.closed")
            } description: {
                Text("Il a peut-être été supprimé, ou vous n’avez plus accès à sa bibliothèque.")
            }
            .background(T.amb.ignoresSafeArea())
        }
    }

    // MARK: Écran

    @ViewBuilder
    private func reading(_ p: Reference) -> some View {
        let layout = cache.layout(p)
        let hits = cache.hits(layout, find)
        let editable = model.library.canEdit(p)
        let wide = width / max(zf, 0.5) >= 1000
        let searchable = !JS.trim(p.body).isEmpty || !p.docs.isEmpty
        ScrollViewReader { proxy in
            Group {
                if wide {
                    HStack(alignment: .top, spacing: 24) {
                        ScrollView {
                            aside(p, layout, hits)
                                .padding(.vertical, 16)
                        }
                        .frame(width: 260)
                        .scrollIndicators(.hidden)
                        mainScroll(p, layout, hits, wide: true)
                            .frame(maxWidth: 780)
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: 1180)
                    .frame(maxWidth: .infinity)
                } else {
                    mainScroll(p, layout, hits, wide: false)
                        // Voie étroite : le sommaire est une carte COLLÉE sous l'en-tête (v5.30,
                        // A351) ; ouverte, elle se borne et laisse l'intitulé à portée.
                        .safeAreaInset(edge: .top, spacing: 0) {
                            if showsToc(layout) {
                                tocCard(p, layout, hits)
                                    .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 6)
                                    .frame(maxWidth: 812)
                            }
                        }
                }
            }
            .onChange(of: scrollReq) { _, r in
                guard let r else { return }
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.25)) { proxy.scrollTo(r.id, anchor: r.anchor) }
                }
            }
        }
        .background(T.amb.ignoresSafeArea())
        .onGeometryChange(for: CGSize.self) { $0.size } action: { width = $0.width; height = $0.height }
        .navigationTitle(p.title.isEmpty ? "Sans titre" : p.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { toolbar(p, layout, editable: editable) }
        .modifier(RefSearchable(on: searchable, text: $query) { go(find.cur + 1, soft: false, layout, hits) })
        .safeAreaInset(edge: .bottom) {
            if find.active { hitPill(layout, hits).padding(.bottom, 8) }
        }
        .environment(\.openURL, OpenURLAction { url in handleURL(url, p) })
        .task(id: query) { await runSearch(p, layout) }
        .onAppear { loadFolds() }
        .onChange(of: referenceId) { _, _ in foldLoaded = false; loadFolds(); tasks = [:] }
        .onChange(of: p.body) { _, _ in tasks = [:] }   // corps remplacé sous la vue : on repart de l'état écrit
        .navigationDestination(item: $pdfHit) { h in
            PDFViewerView(attachmentId: h.id, name: h.name, page: h.pages.first, highlight: h.terms)
        }
        #if os(iOS)
        .fullScreenCover(item: $lightbox) { RefLightbox(item: $0) }
        #else
        .sheet(item: $lightbox) { RefLightbox(item: $0).frame(minWidth: 640, minHeight: 480) }
        #endif
        .confirmationDialog(deleteMessage(p), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                model.delete(p)
                model.toast("Protocole supprimé.")
            }
            Button("Annuler", role: .cancel) {}
        }
        .confirmationDialog("Exporter", isPresented: $askDocs, titleVisibility: .visible) {
            Button("Avec les documents (.zip)") { buildExport(p, withDocs: true) }
            Button("Sans les documents (.json)") { buildExport(p, withDocs: false) }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text(Exporter.docsQuestion(p.docs.count))
        }
        .acctExporter($export, model: model)
    }

    /// La colonne de lecture (et ce qui la suit), dans son défileur.
    private func mainScroll(_ p: Reference, _ layout: RefLayout, _ hits: RefHits, wide: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(p)
                notice(p)
                if !p.docs.isEmpty {
                    RefDocsCard(docs: p.docs) { openDoc($0) }
                }
                if !layout.blocks.isEmpty {
                    bodyCard(layout, hits)
                }
                let rel = related(p)
                if !rel.isEmpty { RefLinksCard(rel: rel) { openLinked($0) } }
                let refs = Txt.clean(p.sources)
                if !refs.isEmpty { RefSourcesCard(sources: refs) }
                if p.docs.isEmpty && layout.blocks.isEmpty {
                    WorkCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Protocole vide").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                            Text("Ajoutez un PDF ou un contenu rédigé via « Modifier ».").aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                        }
                    }
                }
            }
            .padding(.horizontal, wide ? 0 : 16)
            .padding(.top, 12).padding(.bottom, 32)
            .frame(maxWidth: 780, alignment: .leading)
            .coordinateSpace(.named(Self.colSpace))
            .frame(maxWidth: .infinity)
        }
        // Le relais du titre dans la barre : dès que le titre de la page est passé sous elle.
        .onScrollGeometryChange(for: Bool.self) { g in
            g.contentOffset.y + g.contentInsets.top > titleBottom
        } action: { _, passed in
            titlePassed = passed
        }
    }
    static let colSpace = "refcol"

    // MARK: En-tête et méta

    @ViewBuilder
    private func header(_ p: Reference) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if wc == .phone {
                Text(p.title.isEmpty ? "Sans titre" : p.title)
                    .aFont(TypeScale.val, .heavy)
                    .foregroundStyle(T.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(Self.colSpace)).maxY } action: { titleBottom = $0 }
            }
            if !p.discriminant.isEmpty {
                Text(p.discriminant).aFont(TypeScale.item, .semibold).foregroundStyle(T.ink2)
            }
            RefFlow(spacing: 8, lineSpacing: 6) { metaItems(p) }
        }
    }

    @ViewBuilder
    private func metaItems(_ p: Reference) -> some View {
        if let lib = p.library {
            let name = model.library.libraryName(lib)
            let ro = !model.library.canEdit(p)
            Label((name.isEmpty ? "Partagée" : name) + either(ro, " · lecture seule", ""), systemImage: ro ? "lock" : "book")
                .labelStyle(RefMetaLabelStyle())
                .help("Bibliothèque partagée")
        }
        switch p.status {
        case .draft: Text("○ Brouillon").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2)
        case .review: Text("△ À revérifier").aFont(TypeScale.meta, .bold).foregroundStyle(T.warn)
        case .validated:
            if p.validatedAt.isEmpty { Text("✓ Validé").aFont(TypeScale.meta, .bold).foregroundStyle(T.ink2) }
        }
        if let c = model.library.category(of: p) {
            HStack(spacing: 5) {
                CategoryDot(color: c.color)
                Text(c.name).aFont(TypeScale.meta, .semibold).foregroundStyle(T.ink2)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Catégorie : " + c.name)
        }
        if !p.code.isEmpty {
            Text(p.code).aFont(TypeScale.meta, .semibold, .mono).foregroundStyle(T.ink2)
        }
        let stale = Txt.staleDate(p.validatedAt, now: JS.now())
        Text(either(stale, "△ ", "") + Self.fmtDate(p.validatedAt))
            .aFont(TypeScale.meta, stale ? .bold : .regular)
            .foregroundStyle(stale ? T.warn : T.ink2)
            .accessibilityLabel(Self.fmtDate(p.validatedAt) + either(stale, ", validation de plus de deux ans", ""))
        if p.library != nil && !p.updatedBy.isEmpty {
            Text("· dernière modification par " + p.updatedBy).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2)
                .help("Auteur de la dernière modification")
        }
    }

    /// `fmtDate` : « Validation : MM/AAAA » (ou JJ/MM/AAAA), « Sans date de validation ».
    static func fmtDate(_ v: String) -> String {
        if v.isEmpty { return "Sans date de validation" }
        let parts = v.split(separator: "-").map(String.init)
        let digits = parts.allSatisfy { !$0.isEmpty && $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }
        if digits, parts.count == 2 || parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts.count == 2 || parts[2].count == 2 {
            return "Validation : " + (parts.count == 3 ? parts[2] + "/" : "") + parts[1] + "/" + parts[0]
        }
        return "Validation : " + v
    }

    @ViewBuilder
    private func notice(_ p: Reference) -> some View {
        if p.status == .draft || p.status == .review {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: "exclamationmark.triangle").font(.system(size: 14, weight: .bold)).foregroundStyle(T.warn)
                    .accessibilityHidden(true)
                (Text(p.status == .draft ? "Brouillon" : "À revérifier").bold()
                 + Text(p.status == .draft
                        ? " — ce protocole n’a pas encore été validé pour l’usage clinique."
                        : " — ce protocole est signalé à relire avant validation."))
                    .aFont(TypeScale.body, .regular)
                    .foregroundStyle(T.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(T.warnSoft, in: RoundedRectangle(cornerRadius: Radius.r3, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.r3, style: .continuous).strokeBorder(T.verifyLine))
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: Corps rédigé

    private func bodyCard(_ layout: RefLayout, _ hits: RefHits) -> some View {
        let closedNow = closedSet
        let off = offSections(layout, hits)
        let ctx = RefBlockContext(layout: layout, find: find, hits: hits, tasks: tasks, width: bodyWidth,
                                  closed: closedNow.union(off.keys), flash: flash,
                                  first: layout.blocks.indices.first)
        return WorkCard {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(layout.blocks.indices, id: \.self) { j in
                    if visible(j, layout, closedNow, off) {
                        RefBlockView(block: layout.blocks[j], index: j, ctx: ctx,
                                     onFold: { toggleFold($0, layout) },
                                     onTask: { i, v in tasks[i] = v },
                                     onImage: { im, cap in lightbox = RefLightboxItem(image: im, caption: cap) })
                    }
                }
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { bodyWidth = $0 }
        }
    }

    /// Titres repliables mis à l'écart LE TEMPS d'une recherche (aucune occurrence dans leur
    /// section — `.pf-off`, jamais mémorisé). Valeur : la clé de repli.
    private func offSections(_ layout: RefLayout, _ hits: RefHits) -> [String: Int] {
        guard find.active else { return [:] }
        var out: [String: Int] = [:]
        for i in layout.foldable where hits.inSection(layout, i) == 0 {
            if let k = layout.heading(i)?.foldKey, !searchOpened.contains(k) { out[k] = i }
        }
        return out
    }

    private func visible(_ j: Int, _ layout: RefLayout, _ closed: Set<String>, _ off: [String: Int]) -> Bool {
        layout.ancestors[j].allSatisfy { i in
            guard let k = layout.heading(i)?.foldKey else { return true }
            return !closed.contains(k) && off[k] == nil
        }
    }

    // MARK: Replis (`mdFoldToggle`, `mdFoldToggleAll`, `mdFoldReveal`)

    private var closedSet: Set<String> { foldLoaded ? closed : RefFoldStore.get(model, referenceId) }

    private func loadFolds() {
        guard !foldLoaded else { return }
        closed = RefFoldStore.get(model, referenceId)
        foldLoaded = true
    }
    private func setClosed(_ s: Set<String>) {
        closed = s
        foldLoaded = true
        RefFoldStore.set(model, referenceId, s)
    }
    private func toggleFold(_ i: Int, _ layout: RefLayout) {
        guard let k = layout.heading(i)?.foldKey else { return }
        // Une section écartée par la recherche (aucune occurrence) se rouvre pour cette recherche
        // seulement — l'écart est transitoire, il n'écrit rien dans la mémoire des replis.
        if find.active, !searchOpened.contains(k), cache.hits(layout, find).inSection(layout, i) == 0 {
            withAnimation(.easeOut(duration: 0.18)) { searchOpened.insert(k) }
            if closedSet.contains(k) { var s = closedSet; s.remove(k); setClosed(s) }
            return
        }
        var s = closedSet
        if s.contains(k) { s.remove(k) } else { s.insert(k) }
        withAnimation(.easeOut(duration: 0.18)) { setClosed(s) }
    }
    private func allClosed(_ layout: RefLayout) -> Bool {
        let keys = layout.foldable.compactMap { layout.heading($0)?.foldKey }
        return !keys.isEmpty && keys.allSatisfy { closedSet.contains($0) }
    }
    /// La bascule se décide sur l'état RÉEL : tant qu'une section est ouverte, on replie tout.
    private func toggleAll(_ layout: RefLayout) {
        let keys = layout.foldable.compactMap { layout.heading($0)?.foldKey }
        guard !keys.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.18)) { setClosed(allClosed(layout) ? [] : Set(keys)) }
    }
    /// Ouvre ce qu'il faut pour montrer le bloc `j` — et la mémoire suit, parce que c'est devenu
    /// vrai à l'écran.
    private func reveal(_ j: Int, _ layout: RefLayout) {
        var s = closedSet
        var changed = false
        for i in layout.ancestors[j] {
            if let k = layout.heading(i)?.foldKey, s.contains(k) { s.remove(k); changed = true }
        }
        if changed { setClosed(s) }
    }

    // MARK: Sommaire

    private func showsToc(_ layout: RefLayout) -> Bool { !layout.toc.isEmpty || (find.active && !docHits.isEmpty) }

    private func tocCount(_ e: RefTocEntry, _ layout: RefLayout, _ hits: RefHits) -> Int {
        layout.heading(e.block)?.foldKey != nil ? hits.inSection(layout, e.block) : (hits.perBlock[e.block] ?? 0)
    }

    /// Voie étroite : « Sommaire · n sections », carte de travail collée sous l'en-tête. Ouverte,
    /// elle recouvre le texte et se borne (56 % de la hauteur) ; l'intitulé reste à portée.
    private func tocCard(_ p: Reference, _ layout: RefLayout, _ hits: RefHits) -> some View {
        let n = layout.toc.count
        return VStack(alignment: .leading, spacing: 0) {
            if n > 0 {
                Button { withAnimation(.easeOut(duration: 0.18)) { tocOpen.toggle() } } label: {
                    HStack(spacing: 12) {
                        Text("≡").aFont(TypeScale.body, .heavy).foregroundStyle(T.ink2)
                            .frame(width: 26, height: 26)
                            .background(T.amb2, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
                            .accessibilityHidden(true)
                        Text("Sommaire").aFont(TypeScale.item, .bold).foregroundStyle(T.ink)
                        Spacer(minLength: 8)
                        Text(find.active ? Self.resultsLabel(hits.total) : "\(n) section\(n > 1 ? "s" : "")")
                            .aFont(TypeScale.body, .regular).foregroundStyle(T.ink2)
                        Image(systemName: "chevron.down").font(.system(size: 13, weight: .bold)).foregroundStyle(T.ink3)
                            .rotationEffect(.degrees(tocOpen ? 180 : 0))
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: 54)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(tocOpen ? "ouvert" : "fermé")
            }
            if find.active && !docHits.isEmpty {
                if n > 0 { Divider() }
                docHitsList
            }
            if tocOpen && n > 0 {
                Divider()
                ScrollView {
                    tocList(layout, hits, closeAfter: true)
                        .padding(.vertical, 8)
                }
                .frame(maxHeight: height * 0.56)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .padding(.horizontal, 16)
        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.workLine))
        .shadow(color: .black.opacity(tocOpen ? 0.14 : 0.06), radius: tocOpen ? 14 : 8, y: tocOpen ? 8 : 3)
    }

    static func resultsLabel(_ n: Int) -> String {
        n == 0 ? "aucun résultat" : "\(n) résultat\(n > 1 ? "s" : "")"
    }

    @ViewBuilder
    private func tocList(_ layout: RefLayout, _ hits: RefHits, closeAfter: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if !layout.foldable.isEmpty && !find.active {
                HStack {
                    Spacer()
                    Button(allClosed(layout) ? "Tout déplier" : "Tout replier") { toggleAll(layout) }
                        .buttonStyle(.a(.quiet, Ctrl.s))
                }
            }
            ForEach(layout.toc) { e in
                let c = find.active ? tocCount(e, layout, hits) : 0
                if !find.active || c > 0 {
                    Button { jump(e.block, layout, close: closeAfter) } label: {
                        HStack(spacing: 8) {
                            Text(e.title.isEmpty ? "Sans titre" : e.title)
                                .aFont(TypeScale.item, e.level == 1 ? .semibold : .regular)
                                .foregroundStyle(T.ink)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if c > 0 {
                                Text("\(c)").aFont(TypeScale.cap, .heavy).foregroundStyle(T.warn)
                                    .padding(.horizontal, 8).padding(.vertical, 2)
                                    .background(T.warnSoft, in: RoundedRectangle(cornerRadius: Radius.r1, style: .continuous))
                                    .accessibilityLabel(Self.resultsLabel(c))
                            }
                        }
                        .padding(.leading, e.level == 2 ? 14 : 0)
                        .padding(.vertical, 6).padding(.horizontal, 8)
                        .frame(minHeight: Ctrl.s)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var docHitsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(docHits) { h in RefDocHitRow(hit: h) { pdfHit = h } }
        }
        .padding(.vertical, 4)
    }

    /// Voie large (≥ 1000) : la colonne à gauche — sommaire, documents trouvés, puis un ACCÈS
    /// RAPIDE aux documents et à « Voir aussi » (recopiés : ils restent aussi à leur place dans
    /// le document).
    private func aside(_ p: Reference, _ layout: RefLayout, _ hits: RefHits) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if find.active && !docHits.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Overline(text: "Dans les documents")
                    docHitsList
                }
            }
            if !layout.toc.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Overline(text: "Sommaire")
                        Spacer()
                        if find.active { Text(Self.resultsLabel(hits.total)).aFont(TypeScale.meta, .regular).foregroundStyle(T.ink2) }
                    }
                    tocList(layout, hits, closeAfter: false)
                }
            }
            if !p.docs.isEmpty { RefDocsCard(docs: p.docs) { openDoc($0) } }
            let rel = related(p)
            if !rel.isEmpty { RefLinksCard(rel: rel) { openLinked($0) } }
        }
    }

    /// Venir du sommaire, c'est demander à LIRE cette section : on ouvre ses ancêtres ET elle.
    private func jump(_ i: Int, _ layout: RefLayout, close: Bool) {
        reveal(i, layout)
        if let k = layout.heading(i)?.foldKey, closedSet.contains(k) {
            var s = closedSet; s.remove(k); setClosed(s)
        }
        if close { tocOpen = false }
        scrollReq = RefScrollRequest(id: RefUnit(b: i, s: 0).anchor, anchor: .top)
        flash = i
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            if flash == i { flash = nil }
        }
    }

    // MARK: Recherche (`pfRun`, `pfGo`, `pfDocsRun`)

    private func runSearch(_ p: Reference, _ layout: RefLayout) async {
        try? await Task.sleep(nanoseconds: 160_000_000)
        if Task.isCancelled { return }
        let q = RefFind.normalized(query)
        if q != find.q {
            find = RefFind(q: q, cur: 0)
            searchOpened = []
            lastTarget = nil
            let hits = cache.hits(layout, find)
            if hits.total > 0 { go(0, soft: true, layout, hits) }
        }
        // Documents joints : mêmes termes (≥ 2 caractères), pages qui les contiennent tous.
        let terms = Search.qTerms(query).filter { JS.length($0) >= 2 }
        guard !terms.isEmpty, !p.docs.isEmpty else { docHits = []; return }
        var out: [RefDocHit] = []
        for a in p.docs {
            if docTexts[a.id] == nil, let url = model.library.space.attachmentURL(a.id) {
                docTexts[a.id] = await RefPdfText.pages(url)
                if Task.isCancelled { return }
            }
            let pages = RefPdfText.search(docTexts[a.id] ?? [], terms)
            if !pages.isEmpty { out.append(RefDocHit(id: a.id, name: a.name, pages: pages, terms: terms)) }
        }
        docHits = out
    }

    /// `doux` (la frappe) : ne défiler que si la cible a changé — un défilement à chaque lettre
    /// fait bouger l'écran sous les doigts. Les flèches ‹ › visent toujours.
    private func go(_ i: Int, soft: Bool, _ layout: RefLayout, _ hits: RefHits) {
        let n = hits.total
        guard n > 0 else { return }
        let k = ((i % n) + n) % n
        find.cur = k
        let u = hits.units[k]
        reveal(u.b, layout)
        if soft && lastTarget == u { return }
        lastTarget = u
        scrollReq = RefScrollRequest(id: u.anchor, anchor: .center)
    }

    private func hitPill(_ layout: RefLayout, _ hits: RefHits) -> some View {
        HStack(spacing: 4) {
            Button { go(find.cur - 1, soft: false, layout, hits) } label: {
                Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold)).frame(width: Ctrl.l, height: Ctrl.l)
            }
            .disabled(hits.total == 0)
            .accessibilityLabel("Occurrence précédente")
            Text(hits.total == 0 ? "aucun résultat" : "\(find.cur + 1) / \(hits.total)")
                .aFont(TypeScale.body, .bold, .mono)
                .foregroundStyle(T.ink)
                .frame(minWidth: 72)
                .accessibilityAddTraits(.updatesFrequently)
            Button { go(find.cur + 1, soft: false, layout, hits) } label: {
                Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold)).frame(width: Ctrl.l, height: Ctrl.l)
            }
            .disabled(hits.total == 0)
            .accessibilityLabel("Occurrence suivante")
        }
        .buttonStyle(.plain)
        .foregroundStyle(T.act)
        .padding(.horizontal, 6)
        .floatingGlass(interactive: true)
    }

    // MARK: Barre d'outils

    @ToolbarContentBuilder
    private func toolbar(_ p: Reference, _ layout: RefLayout, editable: Bool) -> some ToolbarContent {
        if wc == .phone {
            // Le titre relaie celui de la page seulement quand il est passé sous la barre (A351).
            ToolbarItem(placement: .principal) {
                Text(p.title.isEmpty ? "Sans titre" : p.title)
                    .aFont(TypeScale.item, .bold).foregroundStyle(T.ink).lineLimit(1)
                    .opacity(titlePassed ? 1 : 0)
                    .animation(.easeOut(duration: 0.15), value: titlePassed)
                    .accessibilityHidden(!titlePassed)
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Menu {
                if !editable {
                    Button {} label: { Label("Modifier — lecture seule", systemImage: "lock") }
                        .disabled(true)
                }
                Button { duplicate(p) } label: { Label("Dupliquer dans « Perso »", systemImage: "plus.square.on.square") }
                Button { exportJSON(p) } label: { Label("Exporter le protocole (.json)", systemImage: "square.and.arrow.up") }
                Button { printPDF(p) } label: { Label("Exporter le protocole en PDF", systemImage: "printer") }
                if !layout.foldable.isEmpty {
                    Divider()
                    Button { toggleAll(layout) } label: {
                        Label(allClosed(layout) ? "Tout déplier" : "Tout replier",
                              systemImage: allClosed(layout) ? "chevron.down" : "chevron.up")
                    }
                }
                if editable {
                    Divider()
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Supprimer…", systemImage: "trash") }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .accessibilityLabel("Plus d’actions")
            .help("Plus d’actions")
        }
        if editable {
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItem(placement: .primaryAction) {
                Button("Modifier") { model.path.append(.editReference(p.id)) }
                    .buttonStyle(.glassProminent)
                    .help("Modifier ce protocole (hors urgence)")
            }
        }
    }

    // MARK: Gestes

    private func openDoc(_ a: Attachment) {
        model.path.append(.pdf(a.id, a.name))
    }
    private func openLinked(_ id: String) { model.openLinked(id) }

    private func related(_ p: Reference) -> [RefRelated] {
        p.links.compactMap { id -> RefRelated? in
            if let f = model.fiches.first(where: { $0.id == id }) { return RefRelated(id: id, title: f.title, isReference: false) }
            if let r = model.references.first(where: { $0.id == id }) { return RefRelated(id: id, title: r.title, isReference: true) }
            return nil
        }
    }

    /// Liens du corps : web → système ; `[texte](att:ID)` → la visionneuse, comme « Documents ».
    private func handleURL(_ url: URL, _ p: Reference) -> OpenURLAction.Result {
        if url.scheme == RefInline.attScheme {
            let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "id" }?.value ?? ""
            if let a = p.docs.first(where: { $0.id == id }) { openDoc(a) }
            else { model.toast("⚠ Document lié introuvable dans ce protocole.") }
            return .handled
        }
        guard let s = url.scheme?.lowercased(), s == "http" || s == "https" else { return .discarded }
        return .systemAction
    }

    private func duplicate(_ p: Reference) {
        _ = Importer.duplicateToPerso(p, library: model.library)
        model.refresh()
        model.toast("✓ Copie créée dans « Perso » — état Brouillon", seconds: 3.5)
    }

    private func exportJSON(_ p: Reference) {
        if p.docs.isEmpty { buildExport(p, withDocs: false) } else { askDocs = true }
    }
    private func buildExport(_ p: Reference, withDocs: Bool) {
        export = model.acctBuildExport(fiches: [], references: [p],
                                       categories: model.categories.filter { $0.id == p.category },
                                       base: "protocole-" + Exporter.slug(p.title), withDocuments: withDocs)
    }

    private func printPDF(_ p: Reference) {
        var meta: [String] = []
        if let c = model.library.category(of: p) { meta.append(c.name) }
        if !p.code.isEmpty { meta.append(p.code) }
        meta.append(Self.fmtDate(p.validatedAt))
        let notice: String? = p.status == .draft ? "Brouillon — ce protocole n’a pas encore été validé pour l’usage clinique."
            : (p.status == .review ? "À revérifier — ce protocole est signalé à relire avant validation." : nil)
        let html = RefPrint.html(p, meta: meta.joined(separator: " · "), notice: notice,
                                 docs: p.docs.map(\.name), rel: related(p).map { $0.title.isEmpty ? "Sans titre" : $0.title })
        RefPrint.run(title: p.title, html: html)
    }

    private func deleteMessage(_ p: Reference) -> String {
        p.library != nil
            ? "Supprimer ce protocole définitivement ?\nIl disparaîtra pour tous les membres de la bibliothèque."
            : "Supprimer ce protocole définitivement ?"
    }
}

// MARK: - Recherche système (seulement s'il y a quelque chose à chercher)

private struct RefSearchable: ViewModifier {
    var on: Bool
    @Binding var text: String
    var submit: () -> Void
    func body(content: Content) -> some View {
        if on {
            content
                .searchable(text: $text, prompt: "Chercher dans la référence…")
                .onSubmit(of: .search) { submit() }
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
        } else {
            content
        }
    }
}

// MARK: - Petites pièces

/// Demande de défilement (le `ScrollViewProxy` ne vit que dans son lecteur).
struct RefScrollRequest: Equatable {
    var id: String
    var anchor: UnitPoint
    var nonce = UUID()
}

/// Mémo du document analysé et de l'index des occurrences : le corps (≤ 20 000 caractères) ne se
/// ré-analyse pas à chaque frappe ni à chaque repli. Non observé (aucune vue ne s'y abonne).
final class RefCache {
    private var key = ""
    private var cached = RefLayout([])
    private var hitsKey: String? = nil
    private var cachedHits = RefHits()

    func layout(_ p: Reference) -> RefLayout {
        let k = p.id + "\u{1}" + p.body + "\u{1}" + p.images.map { $0.id + ":" + String($0.data.utf8.count) + ":" + String($0.scale) }.joined(separator: ",")
        if k != key {
            key = k
            cached = RefLayout(Markdown.document(p.body, images: p.images))
            hitsKey = nil
        }
        return cached
    }
    func hits(_ layout: RefLayout, _ find: RefFind) -> RefHits {
        if find.q != hitsKey {
            hitsKey = find.q
            cachedHits = RefHits(layout, find)
        }
        return cachedHits
    }
}

struct RefMetaLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.font(.system(size: 11, weight: .semibold))
            configuration.title.aFont(TypeScale.meta, .semibold)
        }
        .foregroundStyle(T.ink2)
    }
}

/// Mise en ligne qui passe à la ligne (la méta d'une référence : pastilles de longueur libre).
struct RefFlow: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0, w: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(ProposedViewSize(width: maxW, height: nil))
            if x > 0 && x + sz.width > maxW { y += lineH + lineSpacing; x = 0; lineH = 0 }
            x += sz.width + spacing
            lineH = max(lineH, sz.height)
            w = max(w, x - spacing)
        }
        return CGSize(width: proposal.width ?? w, height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x > bounds.minX && x + sz.width > bounds.maxX { y += lineH + lineSpacing; x = bounds.minX; lineH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: min(sz.width, bounds.width), height: sz.height))
            x += sz.width + spacing
            lineH = max(lineH, sz.height)
        }
    }
}
