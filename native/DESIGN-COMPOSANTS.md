# Composants jumeaux PWA ↔ app native

> ⚠ Fichier GÉNÉRÉ depuis `design/components.json` (`node scripts/check-components.mjs --doc`) — ne pas éditer.

Chaque composant relie une famille de classes CSS d'`index.html` à ses types SwiftUI. Si le CSS
d'un composant change, `scripts/check-components.mjs` (CI) échoue et désigne le jumeau à revoir ;
une fois relu : `node scripts/check-components.mjs --ack <id>`.

| Composant | Statut | Classes CSS (préfixes) | Règles | Fiche du design system | Types SwiftUI |
|---|---|---|---:|---|---|
| **Boutons** (`boutons`) | porté | `.btn` `.primary` `.danger` `.ghost` `.linkbtn` `.hold` `.holding` `.cont` `.outline` `.solid` | 106 | `design/ds/components/buttons.html` | `AButtonStyle`, `HoldButton` |
| **Sélecteur segmenté** (`segmente`) | porté | `.seg` `.statuseg` `.st` | 65 | `design/ds/components/buttons.html` | `EdSeg`, `AcctSegmented`, `HomeSeg` |
| **Pastilles, tags & états** (`pastilles`) | porté | `.chip` `.chiprow` `.tag` `.catchip` `.libtag` `.status` `.pinbtn` `.sync` `.ss` `.acc` `.a` `.accent` | 93 | `design/ds/components/chips.html` | `Chip`, `StatusLabel`, `RegisterTag`, `CategoryDot`, `HomePinButton`, `HomeSyncDot`, `HomeProvenanceTag` |
| **Accueil : liste et cartes** (`accueil-liste`) | porté | `.dir` `.card` `.home` `.emp` `.qa` `.azrail` `.azr` `.compact` `.dense` `.ls` `.lsr` `.hj` `.list` `.empty` `.gthumb` `.gcap` `.rang` `.live` `.sess` `.pin` `.cross` | 331 | `design/ds/components/cards.html` | `HomeListArea`, `HomeBrowseList`, `HomeGroupView`, `HomeRow`, `HomeRowMeta`, `HomeTiles`, `HomeSummaryRow`, `HomeEmptyState`, `HomeTeachingCard`, `HomeAZRail`, `HomeLiveCards`, `HomeRecapCard`, `HomeJoinLine` |
| **Accueil : colonne et feuille Affichage** (`accueil-filtres`) | porté | `.hs` `.filt` `.af` `.dp` `.catmenu` `.scopebtn` `.fam` | 119 | `design/ds/components/cards.html` | `HomeSidebar`, `HomeDisplaySheet`, `HomeFilterChips` |
| **Sélection multiple** (`accueil-selection`) | porté | `.sel` `.selon` `.selm` `.pick` | 41 | `design/ds/components/cards.html` | `HomeSelectionBar`, `HomeSelActionsSheet`, `HomeSelMoveLibSheet`, `HomeSelCategorySheet`, `HomeSelDeleteSheet` |
| **Menus et rangées de menu** (`menus`) | porté | `.popmenu` `.mm` `.pm` `.more` | 60 | `design/ds/components/header.html` | `HomeMenuRow`, `AcctMenuRow`, `EdMenuRow`, `CrMoreMenu` |
| **Barre d'en-tête** (`en-tete`) | plateforme | `.hdr` `.brand` `.chrome` `.tools` `.bar` `.skiplink` `.back` | 241 | `design/ds/components/header.html` | `RootView`, `HomeView`, `ReadFicheView` |
| **Fenêtres et dialogues** (`fenetres`) | plateforme | `.ai` `.dlg` `.modal` `.sheet` `.conf` `.confirm` `.ask` `.endsess` `.sh` | 139 | `design/ds/components/modal.html` | `AcctWindow`, `EdSheetShell`, `CrEndDialog`, `HomeEndSessionSheet`, `AcctConfirmView` |
| **Notices, alertes & toasts** (`notices`) | porté | `.notice` `.alert` `.toast` `.sys` `.info` `.err` `.warn` `.crit` `.ok` `.sb` `.busy` `.rejected` `.pending` `.boot` `.at` | 106 | `design/ds/components/notices.html` | `HomeNotices`, `HomeSystemBanner`, `HomeSyncNotice`, `ToastView`, `AlarmBannerView`, `AcctMessage`, `SyncErrorView` |
| **Formulaires** (`formulaires`) | porté | `.field` `.auth` `.srch` `.search` `.kbd` `.kb` `.code` `.tg` `.q` | 116 | `design/ds/components/forms.html` | `AccountView`, `EdField`, `AcctFieldStyle` |
| **Écran de bienvenue** (`bienvenue`) | porté | `.wl` | 14 | — | `WelcomeView` |
| **Compte, bibliothèques, stockage** (`compte`) | porté | `.acct` `.storage` `.stg` `.invite` `.roles` `.rs` `.mc` `.k` | 89 | — | `AccountView`, `MembersView`, `NewLibraryView`, `PendingAccountsView`, `StorageInfoView`, `AccountPrefsBlock` |
| **Gestionnaire de catégories** (`categories`) | porté | `.cm` `.cat` | 74 | `design/ds/foundations/categories.html` | `CategoryManagerView` |
| **Créer, importer, prompt IA** (`creer-importer`) | porté | `.crt` `.imp` `.atyp` `.up` `.attpick` `.ist` `.diff` | 107 | — | `CreateView`, `ImportWorkshopView`, `PromptIAView`, `ImportDropZone`, `AcctDiffView` |
| **Lecture d'une aide : mise en page** (`lecture-aide`) | porté | `.read` `.rail` `.cockpit` `.crisis` `.exo` `.pre` `.cf` `.ovh` `.care` `.fs` `.ff` `.fz` `.cb` `.note` | 224 | `design/ds/components/lists.html` | `ReadFicheView`, `CrRail`, `CrEntryView`, `CrCockpitColumn`, `CrActionColumn`, `CrExerciseBand`, `CrNoteBlock` |
| **Journal de parcours et étapes** (`journal`) | porté | `.ov` `.blk` `.block` `.steps` `.stp` `.li` `.done` `.alg` `.titled` `.faite` `.last` `.bkr` `.rsm` `.jl` `.num` `.todo` `.vigil` `.vig` `.mk` | 374 | `design/ds/components/journal.html` | `CrJournalView`, `CrBlockCard`, `CrCardHead`, `CrCardBody`, `CrStepRow`, `CrControls`, `CrProgressLine`, `CrRunPill`, `CrHistoryCard`, `CrMilestones` |
| **Nœud de décision** (`decision`) | porté | `.dec` `.opt` `.options` `.optedit` | 40 | `design/ds/components/decision.html` | `CrDecisionBody` |
| **Parcours (liste à plat, se repérer)** (`parcours`) | provisoire | `.pf` `.mini` `.flat` `.plan` `.pl` | 144 | `design/ds/components/carepath.html` | `CrParcoursList`, `CrPfBlockRow`, `ParcoursSheetView` |
| **Cartes dépliables (quand l'utiliser, ne pas oublier…)** (`cartes-depliables`) | porté | `.md` `.fold` `.mem` `.memory` `.forget` `.closed` `.open` | 178 | `design/ds/components/lists.html` | `CrFoldCard`, `CrSessionFolds`, `CrItemRows`, `CrForgetRows` |
| **Capsule, quai et panneau temps réel** (`temps-reel`) | porté | `.rt` `.tm` `.tmcard` `.tmm` `.tme` `.tmr` `.tmedit` `.cn` `.cncard` `.due` `.soon` `.dock` `.sd` `.cur` `.run` `.tic` `.t` `.m` `.bolt` `.hz` `.cbt` `.ds` | 433 | `design/ds/components/runtime.html` | `CrCapsule`, `CrDock`, `CrTimersSection`, `CrTimerCard`, `CrAdhocTimerRow`, `CrCountersSection`, `CrCounterCard`, `CrPanelSheet`, `CrReturnBar` |
| **Légendes des liens (témoins) et moments** (`temoins`) | porté | `.wt` `.mo` | 41 | `design/ds/components/lists.html` | `CrWitnessLine`, `CrStepRow` |
| **Horodater et journal des actions** (`horodatage`) | porté | `.tk` `.ts` `.ep` | 80 | `design/ds/components/runtime.html` | `CrStampSheet`, `CrEventJournal`, `CrEventRow` |
| **Repères posologiques** (`reperes`) | porté | `.pos` `.pb` `.pband` `.pip` | 54 | `design/ds/components/lists.html` | `CrPosoBand`, `CrPosoCards`, `CrPosoRows` |
| **Complications** (`complications`) | porté | `.cx` | 20 | `design/ds/components/journal.html` | `CrCxSheet` |
| **Revue « à tout moment »** (`revue`) | porté | `.rev` `.rv` | 54 | `design/ds/components/journal.html` | `CrReviewDoor`, `CrReviewGrid` |
| **Vérification (Do-Verify, challenge-response)** (`verification`) | porté | `.v` `.vfy` `.verify` `.vcur` `.vgap` `.vs` `.vstp` `.ok2` `.ko` `.okay` `.sst` `.h` | 87 | `design/ds/components/challenge.html` | `CrVerifyView` |
| **Mode moniteur** (`moniteur`) | porté | `.mon` `.mb` | 37 | `design/ds/components/runtime.html` | `CrMonitorView`, `CrMonBand` |
| **Sessions et compte-rendu** (`sessions`) | porté | `.report` | 18 | `design/ds/components/session.html` | `SessionsHistoryView`, `ReportView` |
| **La Page (mode statique)** (`page`) | provisoire | `.sv` `.sf` `.page` `.print` `.carry` | 203 | `design/ds/components/static.html` | `PageView` |
| **Schéma (organigramme SVG)** (`schema`) | provisoire | `.flow` `.fn` `.fnode` | 43 | `design/ds/components/plan.html` | `SchemaView` |
| **Lecture d'une référence** (`reference`) | porté | `.ref` `.toc` `.lightbox` `.lb` `.refs` `.related` `.rel` `.mi` | 81 | — | `ReferenceReadView`, `RefBlockView`, `RefHeadingView`, `RefLightbox`, `RefLinksCard`, `RefSourcesCard` |
| **Visionneuse PDF et documents** (`pdf`) | porté | `.pdf` `.att` `.dh` `.doc` | 80 | — | `PDFViewerView`, `RefDocsCard`, `RefDocRow`, `RefDocHitRow` |
| **Éditeurs (aide et référence)** (`editeur`) | porté | `.ed` `.eds` `.edd` `.eg` `.bo` `.grab` `.grabbed` `.sc` `.fq` `.fh` `.vers` `.fp` | 144 | — | `FicheEditorView`, `FicheForm`, `BlockEditorCard`, `StepRow`, `StepSettingsSheet`, `ReferenceEditorView`, `MarkdownToolbar`, `EdCard`, `EdPillsRow`, `VersionsView`, `EdVersionsSheet` |
| **Partage de session** (`partage`) | à porter | `.sl` `.share` `.qr` `.join` `.solo` `.lk` | 74 | — | `JoinSessionView` |
| **Vues et paliers de largeur** (`mise-en-page`) | plateforme | `.view` `.zw1200` `.zw640` `.zw560` `.zw430` `.zw400` `.zw360` `.zw300` `.zh500` `.foot` | 243 | `design/ds/foundations/shape.html` | `WidthClass`, `RootView` |

## Traduction PWA → iOS 27

Ce qui n'est PAS recopié mais TRADUIT vers un composant ou un réglage du système. Les registres
(rouge / ambre / vert / bleu, toujours avec un mot), les échelles et les tokens restent identiques.

| PWA | App native | Règle |
|---|---|---|
| En-tête (`hdr`, `brand`, `tools`) | Barre de navigation système : `.navigationTitle`, `.toolbar` en symboles SF, une seule action `.glassProminent` | HIG iOS 27 (Toolbars) |
| Fenêtre `.ai-modal` et dialogues | Feuille `.sheet` à détentes, ✕ en `.cancellationAction`, ✓ en `.confirmationAction` ; formulaire centré sur iPad/Mac | HIG iOS 27 (Sheets) |
| Matière système `--sys` (quai, capsule, bandeaux flottants) | Liquid Glass « regular » (`.floatingGlass`), teinté seulement par un ÉTAT (alarme ambre, session verte) | Verre = couche fonctionnelle seulement |
| Matières `--work` / `--amb` (cartes, fond) | Surfaces OPAQUES aux mêmes tokens (`T.work`, `T.amb`) — jamais de verre dans le contenu | Deux couches (HIG Materials) |
| Accueil : colonne gauche, onglets Sessions / Moi | `TabView` adaptable (barre d'onglets au téléphone, barre latérale iPad/Mac) + onglet de recherche `role: .search` | HIG iOS 27 (Tab bars, Sidebars) |
| Zoom `--zf` sur `<html>` (100 / 115 / 130 %) | `\.textScale` appliqué par `.aFont` à tous les corps et glyphes | Règle 10 de la PWA |
| Paliers `zw…` / 780 / 1200 (largeur ÷ zoom) | `WidthClass` (phone < 780 ≤ tablet < 1200 ≤ cockpit), mesuré sur la largeur ÷ taille du texte | Règle 10 de la PWA |
| `@media (prefers-contrast:more)` | Variantes « contraste élevé » des couleurs générées (trait d'accessibilité du système) | Généré par build-tokens |
| `prefers-reduced-motion` | `accessibilityReduceMotion` : aucune animation d'arrivée ni de jauge | A378 |
| Halo tactile `::after` (cible ≥ 44 px en crise) | `contentShape` + cadre ≥ `Ctrl.l` (44 pt) | Règle 9 |
| Champs à 16 px sur écran tactile | `.aFont(16…)` avec exemption motivée (`// design: champ tactile…`) | Règle 9, exemption de check-type |
| Polices embarquées (Manrope, IBM Plex Mono, Source Serif 4) | Polices système (SF, SF Mono, New York) : cohérence avec la plateforme, rendu Dynamic Type | Décision native (HIG Typography) |

## Familles CSS hors catalogue (écartées nommément)

- `.on` — classe d'ÉTAT générique (.on) : toujours composée avec la classe d'un composant, qui porte l'empreinte
