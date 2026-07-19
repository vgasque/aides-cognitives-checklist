# Instructions projet — Aides cognitives

> Fichier d'instructions **canonique**, destiné à tout contributeur, humain ou IA
> (Claude, Codex, Cursor, Gemini…). `CLAUDE.md` ne fait que l'importer.

PWA médicale **monofichier** (`index.html`), JavaScript vanille, **aucune dépendance runtime**.
Stockage local-first (IndexedDB) ; synchro cloud Supabase optionnelle (RLS). Utilisée en urgence
vitale, sous stress : clarté et robustesse priment.

> **Exception UNIQUE à la règle zéro-dépendance : pdf.js** (visionneuse des documents PDF).
> Vendorisé dans `vendor/pdfjs/` (version figée, notée dans `vendor/pdfjs/README.txt`), chargé
> **paresseusement** (`import()` au premier document ouvert — jamais au démarrage), **précaché
> par `sw.js`** (hors ligne dès l'installation). Mettre à jour pdf.js = décision explicite +
> test hors-ligne complet (mode avion, PDF 50+ pages, iPhone). **Aucune autre dépendance runtime
> n'est autorisée** ; tout nouveau fichier servi doit être ajouté à `ASSETS` (`sw.js`).

## Règle de publication (IMPÉRATIF)
Publier une version = trois étapes, dans cet ordre :

1. `./release.sh X.Y.Z` — synchronise `APP_VERSION` (`index.html`) et `CACHE` (`sw.js`), ébauche
   l'entrée `CHANGELOG.md`, vérifie syntaxe et tests. **Ne jamais éditer ces numéros à la main**
   (un décalage casse la mise à jour du service worker). Le script **ne committe pas**.
2. Rédiger l'entrée `CHANGELOG.md` (contenu réel, pas de « à compléter » laissé en place).
3. Committer avec de **vraies notes de version** — format des messages du dépôt :
   `vX.Y.Z : <résumé en français des changements>` — puis taguer `vX.Y.Z`.

Les étapes 2 et 3 sont le travail de l'IA (ou de l'humain), jamais du script.
Versionnage sémantique : correctif → patch (Z), nouvelle fonctionnalité → mineure (Y).
Ne jamais pousser (`git push`) sans demande explicite de l'utilisateur.

## Avant chaque commit
- `npm run check` — vérifie la syntaxe des scripts inline (attrape les templates mal fermés).
- `npm test` — exécute `tests.html` en headless (Playwright). À défaut de npm, ouvrir `tests.html`
  **servi en http** (pas en `file://` : les iframes cross-origin y sont bloquées).
- L'intégration continue (`.github/workflows/ci.yml`) rejoue check + tests sur chaque push/PR.

## Conventions de code
- **Design tokens** : aucune nouvelle couleur hex hors `:root` (tokens CSS) et `PALETTE`
  (catégories) — **y compris dans les overrides `html[data-theme="dark"]`** (pas de copie hex
  d'un token : la duplication désaccorde les palettes ; fond de champ de saisie = `--input-bg`).
  Palette **V5 « bleu clinique »** (canvas « V5 Explorations », v4.0.4) : `--primary` bleu =
  identité/action ; **`--ok` vert = confirmation/issue positive** (pastilles d'état, fin
  d'algorithme) ; erreur/danger = `--critical`, attente/avertissement/décision = `--verify`,
  jamais l'inverse. `--critical` couvre la destruction **et l'arrêt d'un processus vivant**
  (ex. « Terminer » une session : archivante et réversible, mais stoppe les minuteurs — registre
  du rouge « raccrocher » ; ne pas le « corriger » en ambre). TROIS ROUGES distincts, ne pas
  les fusionner : `--critical` #a32e1f = TEXTE/icônes vital-destructif ; `--critical-bd`
  #c43d34 = BORDURES des cartes/bandeaux rouges ; PALETTE « Urgences » #b6382f = couleur de
  CATÉGORIE (liseré/pastille, jamais un signal d'alerte) ; états (pastilles compte/synchro) :
  ok = `--ok`, attente = `--verify`, erreur = `--critical`, inactif = `--line-strong`, synchro
  EN COURS = anneau tournant (`.acct-dot.busy`, v4.5.3 : activité ≠ alerte — mouvement discret,
  jamais en crise, le bouton Compte y est masqué) ; survol
  des boutons remplis = `--primary-hi` (en sombre, `--primary-dk` est l'accent **texte** clair).
  Contraste texte ≥ 4.5:1, composants ≥ 3:1 (WCAG AA). Depuis l'audit v4.5 : `--soft` est
  **décoratif seulement** (jamais une couleur de TEXTE — texte secondaire = `--ink-soft`) ;
  cases à cocher et bordures de champs = `--line-strong` (3:1, WCAG 1.4.11). Tokens ajoutés
  v4.5 : `--verify-bd`/`--verify-hi` (bordure/emphase du registre ATTENTION, ex. minuteur
  échu), `--critical-bd`, `--done-bg/-line/-ink` (étape cochée), `--tag-bg/-ink` (pilules
  neutres), `--link` (liens ET temps d'un minuteur en cours — ancien `--timer-run` fusionné).
- **Taxonomie des notices (V5)** : 5 registres, du plus au moins impérieux — ALERTE
  (`--critical`), ATTENTION (`--verify`), INFORMATION (`--primary` : `.notice`, `#sysBanner`),
  CONFIRMATION (`--ok` : `.flow-end`, étape cochée), MEMO (neutre). Grammaire : bord gauche 4 px + bordure de la
  couleur sémantique ; la couleur n'est jamais seule. **Statuts achromatiques** : pilule `.status-tag` unique
  pour les 3 états (✓ Validé(e) — affiché lui aussi depuis v4.5 —, △ À compléter, ○ Brouillon ;
  tokens `--tag-bg`/`--tag-ink`) — la couleur reste réservée au danger et aux catégories
  (liserés de cartes ; sur les cartes d'accueil la pilule de catégorie est NEUTRE, la couleur
  ne vit que dans le liseré). Surfaces : bandeau système persistant (`#sysBanner`, INFO), snackbar
  transitoire (`.toast`, ardoise `--rt-*` fixe dans les deux thèmes) ; **en session de crise,
  aucune notification flottante** — snackbars mis en attente (cf. `toast()`), bandeau système
  masqué (`body.crisis-live`). Le panneau minuteurs suit le THÈME depuis V5 (plus de panneau
  sombre forcé en clair).
- **Statuts, code, étapes critiques (V5)** : fiches ET protocoles portent un statut à 3 états
  (`''` = validé(e) — défaut historique, `'review'` = à relire, `'draft'` = brouillon ;
  sélecteur segmenté dans les éditeurs, badges achromatiques, un ancien client traite `review`
  comme validé) et un `code` court facultatif (mono, indexé par la recherche). **Étape
  critique** = préfixe `⚠ ` (ou `!`) DANS la chaîne d'étape (`stepIsCrit`/`stepText` — le format
  reste une chaîne : exports v3 et anciens clients inchangés) ; rendue rouge en lecture et dans
  le SVG, bascule ⚠ dans l'éditeur de blocs. **Doctrine d'usage (v4.2.2)** : rouge = ce qui TUE
  si on l'oublie (memory item, geste vital) ; ambre (`△`, vigilance) = là où l'on risque de SE
  TROMPER (dose/dilution à vérifier, contre-indication, confusion voie/site/produit, seuil) ;
  une étape des deux registres → rouge. Le **gras est exclu des étapes** (texte déjà en gras à
  l'affichage — le relief passe par le TYPE d'étape) ; il reste disponible dans les listes.
  Le cochage passe au **vert `--ok`** et
  « Continuer » au registre CONFIRMATION quand tout le bloc est coché. Les éditeurs offrent un
  **aperçu du brouillon** (bouton « Aperçu » + colonne « Aperçu en direct » à ≥ 1000 px) via
  `state.previewFrom` : AUCUNE session ne démarre en aperçu (garde dans `ensureStarted`).
  **Auto-enregistrement des brouillons (v4.5)** : les éditeurs se sauvent en continu dans le
  store meta `draftpark` (`getDraftPark`/`setDraftPark`) — « ‹ Retour » remplace « Annuler »,
  un brouillon interrompu est proposé en « fantôme » (carte « Reprendre le brouillon » du
  dialogue Créer, lien « Repartir de la version enregistrée ») ; badge d'état
  « auto-enregistré » (+ « · synchro en attente » si le push a échoué).
- **Parcours de soin (v4.4.0)** : la vue lecture d'une fiche est structurée par un rail vertical
  numéroté (`<ol class="care-path">`, `aria-current="step"`) — ① **Confirmer le diagnostic**
  (ex-bloc repliable « Confirmation diagnostique », son en-tête EST le titre d'étape :
  « Confirmer le diagnostic » avant session, « Diagnostic confirmé » après ; bouton
  « Confirmé — démarrer la session » ; lien « Tableau atypique ? » vers les différentiels) →
  ② **Prise en charge** (minuteurs en étroit, carte des blocs SVG repliable en tête, fil
  d'Ariane, bloc courant, contexte local, posologie en étroit) → ③ **Surveillances & pièges**
  (À vérifier + différentiels, REMONTÉS sous l'algorithme) ; puis les annexes (journal, galerie,
  documents, références, voir aussi, note). Pastilles du rail : bleu = active, vert ✓ = faite,
  neutre cerclé = à venir — **jamais d'ambre/rouge dans le rail** (registres d'alerte) ; en
  sombre l'encre des pastilles = `--bg` (AA). Étapes vides omises (numérotation recalculée) ;
  une seule étape → pas de rail. La séquence est SUGGÉRÉE, jamais bloquante (1ʳᵉ action =
  démarrage, inchangé) ; « Ne pas oublier » reste le CHAPEAU hors numérotation (> 4 rappels :
  2 colonnes ≥ 780 px — jamais de repli — et garde-fou non bloquant dans l'éditeur,
  `nfGuardTxt`). Tout re-rendu de DÉMARRAGE passe par `renderKeepAnchor` (l'élément déclencheur
  ne bouge pas d'un pixel à l'écran — ECAM).
- **Journal de parcours du mode crise (v4.9.0, remplace la vue spatiale v4.6.0)** : la lecture
  d'une fiche À ALGORITHME a TROIS modes (v4.13.0) — `overview` « Journal » (défaut : JOURNAL
  chronologique) ↔ `guided` « Guidé » (bloc à bloc historique, inchangé) ↔ `static`
  « Statique » (TABLEAU compact façon SFAR, cf. bullet dédié) ; bascule à DEUX NIVEAUX
  (v4.14.0, décision utilisateur) : « Dynamique ↔ Statique » (`#readTopSeg`) EN TÊTE de fiche
  — le statique absorbe confirmation/chapeau/surveillances — puis « Journal ↔ Guidé »
  (`#readModeSeg`) dans l'étape ② en dynamique seulement ; revenir en dynamique restaure le
  dernier sous-mode (clé LOCALE `ac-read-dyn`, non synchronisée) ; masquées si `!hasFlow` ;
  préférence PAR UTILISATEUR (`spaceKey('ac-read-mode')` + `data.prefs.readMode`
  — le pull de synchro n'écrit QUE la préférence locale, il ne bascule JAMAIS la vue ouverte).
  Les trois vues partagent le MÊME Runtime : `nav`/`navSeq`/`checked` et l'export v3
  STRICTEMENT inchangés. **Doctrine du journal (leçon v4.6→v4.9 : ne PAS poser
  un état temporel sur une carte spatiale — un bloc à plusieurs passages y perd l'utilisateur)** :
  `nav[]` EST la chronologie — chaque passage est une CARTE POSTÉE à la suite (modèle ECAM),
  rien ne mute au-dessus, on lit toujours vers le bas ; le journal n'a PAS de curseur (la
  position est le BOUT, `state.navPos=fin` — la vue guidée garde le sien) ; une instance
  COMPLÈTE non-courante se replie en LIGNE D'ÉTAT verte relisible — repli appliqué AU RENDU
  d'un geste de navigation, JAMAIS sous le doigt pendant le cochage ; une instance incomplète
  reste dépliée ; une décision repliée garde sa réponse en toutes lettres (`.ov-ans`) et ses
  options restent actives partout (changer d'avis = nouveau passage décision+cible en bout de
  journal, traçabilité complète) ; l'avancement (« Continuer — … → » / « Terminer ») n'existe
  QUE sur l'instance du bout — une boucle est un simple Continuer ; « ↺ Refaire » poste
  volontairement une nouvelle carte, tout ce qui précède reste tel quel. Cocher dans une
  instance ne re-rend JAMAIS (délégation sur `.ov-wrap`, chirurgie `ovAfterCheck`/`ovPaintLive` ;
  `renderOvOnly` = pendant de `renderNavOnly`, qui dispatche). Fonctions pures : `passInfo`
  (rang du passage), `instComplete` ; `minimapData` = source UNIQUE de l'état PAR BLOC.
- **Plan de l'aide (v4.10.0 arbre, v4.12.0 organigramme hybride)** : sous le journal, la
  STRUCTURE COMPLÈTE façon algorithme papier / checklist conditionnelle QRH — `flowPlan(f)`
  (pure, cache WeakMap par objet fiche, jamais l'éditeur) : DFS depuis le départ, le TRONC
  reprend au POINT DE CONVERGENCE (post-dominateur immédiat — itératif, graphes minuscules),
  cible déjà décrite = lien « ↺ reprendre à n » (les BOUCLES deviennent une structure lisible,
  ex. cycles 2 min d'un ACR), chaque bloc n'apparaît qu'UNE fois. `flowPlan().order` =
  NUMÉROTATION COMMUNE (plan, journal, chips, rail — `minimapData` la suit). Le plan est
  IMMUABLE et INERTE côté cochage (leçon v4.6, décision RE-CONFIRMÉE en maquettes v4.12 :
  jamais de cases — la trace vit dans le journal) ; il porte un état LÉGER (✓ dernier passage
  complet, ● ici, ×n passages, `offPathSet`) et sert à NAVIGUER : taper un bloc = `jumpToBlock`,
  un lien →/↺ défile DANS le plan (flash). **Organigramme hybride (v4.12.0)** : branches d'une
  décision côte à côte quand l'écran le permet, empilées sinon — règle CSS PURE, locale et
  récursive : `.pl-cols` grid `auto-fit minmax(148px,1fr)` (148 px = deux colonnes tiennent à
  375 px, seuil validé en maquette), plafonnée par `c1…c4` (nombre de branches EN COLONNE —
  sans lui, une branche pleine largeur force des pistes de 148 px sur grand écran) ; branche
  PROFONDE (`deep` : > 2 blocs ou décision imbriquée) = pleine largeur toujours, `deepv`
  (> 3 étapes) = pleine largeur sous 640 px seulement. RAIL de branche 3 px étiqueté
  (bleu = prise, pointillé estompé + mention « hors chemin » = écartée, la couleur jamais
  seule) avec COUDE de convergence (`.pl-elbow`) ; REPLI PAR BRANCHE en ligne-bilan
  (`state.ovFold['b:…']`, chip-bouton ≥ 44 px « n blocs · k ✓ · → n ») — hors chemin
  auto-repliée, JAMAIS bloquant ; FIL D'ANCÊTRES v4 (v4.14.0, après TROIS itérations sur
  retours d'usage — pile sticky superposée v4.12, épingle unique = mauvaise question
  v4.13.2, bulle unique = niveaux perdus v4.13.3) : PILE de bulles flottantes SYNTHÉTIQUES
  (`#plPin`, `position:fixed`, flex column — la superposition est IMPOSSIBLE par
  construction), UNE bulle PAR DÉCISION ANCÊTRE de la ligne de lecture, INDENTÉE selon sa
  position réelle dans l'arbre (décision utilisateur), chacune portant « › option » de SA
  branche (le Oui/Non reste attaché à sa question — jamais d'ambiguïté entre niveaux) ;
  pilotée à CHAQUE défilement par `ovPlanPin` — ENTRÉE/SORTIE en CUMUL DÉTERMINISTE
  (v4.14.3 : le seuil de chaque bulle = bas de la pile au-dessus d'elle, hauteurs réelles
  mémorisées `pin._hm`) + HYSTÉRÉSIS (~16 px entre seuils d'entrée et de sortie — le point
  fixe précédent BATTAIT en fin de branche) ; « › option » seulement si la branche est SEULE
  SUR SA RANGÉE (v4.14.2 : des colonnes côte à côte sont toutes sous les yeux) ; contenu
  reconstruit seulement quand la chaîne change ; décroche à la convergence et en mode
  Échelle, tap =
  `data-plgo` (délégation `.ov-wrap`), masquée à l'impression ; les classes pdN restent
  posées par le walker (inertes) ; `--pl-stick` mesuré sur `header.bar` par `ovPlanStick` —
  ÷ `zoomF()` et RECALÉ à chaque variation de hauteur de l'en-tête (repli
  `.condensed`/`.ttl-on` au défilement, taille du texte, v4.13.1).
  **Échelle ECAM** (mode compact, remplace « Titres seuls » ;
  `state.ovPlanCompact`, jamais persisté, impression = détails) : une ligne par bloc, retraits
  d0-3 AVEC chips d'étiquette (`OUI ›`), renvois mono abrégés (`optAbbr` pure : `OUI→5`,
  `↺1`, `▪fin`), ligne dépliable in-place (étapes lecture seule + « → aller à ce bloc »).
  DOCTRINE DU GUIDÉ (v4.14.4, ECAM) : le remplacement du bloc courant est ANCRÉ (le nouveau
  bloc apparaît là où était l'ancien — compensation `scrollBy` dans `renderNavOnly` ; le
  scroll-anchoring du navigateur seul faisait dériver de ~70 px) et `scrollNavIntoView` ne
  bouge PLUS RIEN quand fil d'Ariane + bloc sont déjà entièrement visibles.
  Registres : chips d'option au registre ATTENTION (`--verify`, comme `.opt`) ; liens neutres
  (`--tag-bg`), reprise `↺` en `--primary-soft` ; nœuds = même grammaire que les cartes
  (liseré bleu = ici, vert = fait, ambre = décision).
- **Challenge-response (v4.11.0, AC 120-71B / Do-Verify)** : trois briques, AUCUN champ modèle.
  **« challenge :: réponse »** = séparateur explicite DANS la chaîne d'étape (même philosophie
  que ⚠/△ : opt-in, export v3 inchangé, ancien client lisible) — `stepCR` (pure, APRÈS
  `stepText`, première occurrence) ; rendu `stepTxtHtml` (guidé + journal : pilule mono
  `.stp-r` = réponse attendue, readback « ✓ » vert au cochage porté par le CSS seul), plan
  (`.pl-r`), SVG (« challenge — réponse ») ; le compte-rendu garde la chaîne brute.
  **Mode Vérification** (Do-Verify, journal) : `state.ovVerify={idx,i,gaps}` transitoire ;
  la passe redéroule TOUTES les étapes (déjà cochées comprises) — « Constaté ✓ » coche la
  MÊME clé, « △ Écart » avance SANS cocher et ne DÉCOCHE JAMAIS (la coche est la trace ;
  décocher = geste manuel dans le parcours) ; résumé final = liste des non-cochées.
  **Mode lecteur** (binôme, plein écran `#readerMode`, statique + délégation unique) : un
  challenge à la fois (26 px, réponse mono 20 px, zone verte ≥ 72 px), piloté sur le BOUT du
  journal — « Répondu » coche la même clé, fin de bloc = mêmes règles que « Continuer »
  (jamais d'avance tant que tout n'est pas confirmé, « Revoir » ramène au premier écart),
  décision = même chemin qu'une option ; Échap/✕ quitte sans rien perdre ; z-index 92 SOUS
  `#screenFlash` (99) — le flash d'alarme reste visible ; chrono de session via
  `updateRtStrip` (`#rmTime`) ; entrées : bouton « Lecteur » sur l'instance du bout + menu ⋯.
  **Garde-fou télégraphique** (`stepGuardTxt`, non bloquant, patron `nfGuardTxt`) : bloc
  > 7 étapes ou challenge > 110 caractères (la réponse « :: » ne compte pas).
  **Minimap (v4.8.0)** : bande de chips-blocs `#ovChips` STATIQUE dans l'en-tête sous
  `#crisisBand` (< 1000 px ; délégation posée UNE fois, contenu peint par `paintMinimaps` —
  masquée/vidée hors lecture par `applyViewChrome`) + panneau `#ovMap` du rail droit
  (≥ 1000 px, sous les minuteurs — l'alarme reste dominante) ; chips « Dg ✓ » / « ③ Surv. » =
  saut vers les sections ① et ③ ; taper un bloc = `jumpToBlock` (même geste que le SVG) ;
  chip courante auto-centrée ; états : `.done` vert, `.cur` fond `--link` (indicateur de
  sélection, pas un bouton rempli), `.dec` bordure `--verify`, `.off` pointillé estompé —
  jamais la couleur seule (n° + compteur en texte). **SVG navigable (v4.7.0)** : taper un nœud de
  l'organigramme = y ALLER (`jumpToBlock` : visité → curseur, sinon extension — JAMAIS de
  cochage dans le SVG, JAMAIS de démarrage de session : naviguer ≠ agir) ; l'état est peint par
  classes (`flowPaintState`), la géométrie n'est plus JAMAIS reconstruite à la navigation
  (cache `_flowCache` sans état) ; toute nouvelle peinture SVG exige sa règle de
  contre-inversion sombre (précédent `.flow-hl`). L'impression force la
  vue d'ensemble (blocs repliés rouverts par CSS `@media print` ; le SVG s'y imprime entier —
  fix du `max-height:300px`). L'aperçu d'éditeur reçoit un BAC À SABLE de navigation détaché
  du Runtime (les coches d'un brouillon ne polluent jamais une session vive d'une autre fiche).
- **Mode statique (v4.13.0, DOCUMENT complet v4.14.0)** : TOUTE l'aide en TABLEAU compact
  façon aide SFAR/CAMR — cellules télégraphiques carrelées à joint 3 px. `svExtras` (v4.14.0)
  absorbe les SECTIONS de la fiche en cellules INERTES : confirmation + différentiels côte à
  côte en tête, chapeau « ⚠ Ne pas oublier » (bord `--critical-bd`), « △ À vérifier » en pied
  (bord `--verify-bd`) — en statique, PAS de rail ①②③ ni de `forget-strip` (une seule étape),
  le bouton « démarrer la session » est une RANGÉE du carrelage sous
  Confirmation/Éliminer (v4.14.2-3 : condition d'entrée QRH, coins 3 px, unique bouton
  rempli, délégation `#sessStart` dans `bindStaticEvents`). L'algorithme est GÉNÉRÉ depuis
  `flowPlan` (numérotation commune) par `svTableHtml` : tronc = cellules pleine largeur
  (`.sv-cell`, titre en petites capitales, étapes ❑), décision = BANDE au registre ATTENTION
  (`.sv-band` : titre + question) + branches en colonnes (`.sv-cols` auto-fit minmax(148px)
  plafonné `c1…c4` ; **UNE SEULE COLONNE sous 640 px** — retour d'usage v4.13.1 : des
  colonnes de ~145 px sur téléphone rendaient la lecture difficile ; **PAS de règle `deep`**
  depuis v4.14.0, décision utilisateur : même une branche profonde reste EN COLONNE ≥ 640 —
  l'arbre dans l'arbre garde ses fourches gauche/droite au 1ᵉʳ niveau, esprit SFAR ; une
  décision imbriquée dans une colonne étroite retombe d'elle-même en pile, auto-fit
  récursif). INERTE côté cochage (doctrine du plan,
  RE-CONFIRMÉE) : l'état de session est PEINT en lecture seule (✓/k coché du dernier passage,
  `● ici` = bout du journal, `aria-current`, hors chemin estompé + mention, chip d'option
  `✓ prise`) ; taper une cellule = `svJump` (jamais visité → ENTRE au bout du journal ; JAMAIS
  de démarrage de session, JAMAIS de défilement — rien ne bouge sous le doigt, flash
  d'acquittement) ; renvoi `→ n` / `↺ n` = défilement + flash DANS le tableau. **AUCUN texte
  bleu dans les cellules (décision utilisateur)** : réponse « :: » = pilule mono NEUTRE
  (`.sv-r`, ≠ `.stp-r` bleu du journal), renvois neutres — le bleu ne marque que la position
  (`● ici`) et la reprise `↺` (`--primary-soft`). **Flèches (svPaintArrows, mesures réelles
  APRÈS rendu, redessin au resize + ResizeObserver sur `.sv-tb`)** : toute mesure est divisée
  par `zoomF()` — **le réglage de taille du texte est un zoom CSS sur `<html>` :
  `getBoundingClientRect` rend des px VISUELS (× zoom) alors que les styles/SVG posés sont en
  px CSS ; toute mesure réinjectée doit être ÷ zoom (v4.13.1, vaut aussi pour `--pl-stick`)**.
  FOURCHE ambre (`--verify-bd`) de la bande vers chaque chip d'option, CONVERGENCE grise
  (`--line-strong`) fusionnant les branches dont l'issue terminale (`svBranchIssue`, pure) est
  le bloc de reprise du tronc (pilules masquées ; brins partant du BAS RÉEL de chaque branche
  dans la superposition `.sv-gut` — jamais de segment flottant sous une colonne courte),
  RETOURS bleus (`--link`) en GOUTTIÈRE gauche (16 px, `svLoopTargets` pure : plafond 2 voies) ;
  ÉLARGISSEMENT des arbres imbriqués (v4.14.3-4, décision utilisateur — esprit papier QRH) :
  une décision imbriquée s'ÉTEND dans l'espace libéré, DANS LES DEUX SENS (sur les fiches
  réelles la branche courte est souvent à GAUCHE) — critère = test de COLLISION global
  (aucun contenu extérieur au sous-arbre dans le rectangle convoité, toutes profondeurs
  d'imbrication), appliqué dans `svPaintArrows` (remise à zéro d'abord, extérieur ->
  intérieur, width + margin-left négatif) ; si la bande chevauche encore une sœur, seules
  fourche + colonnes s'élargissent ;
  branches empilées (étroit) → `.stacked` : fourche/convergence masquées, les pilules
  re-suffisent — la flèche n'est JAMAIS seule (aria-hidden, l'info reste textuelle). En mode
  statique : pas de panneau « Algorithme » ni de minimap (le tableau EST la vue d'ensemble) ;
  minuteurs/alarmes/sessions INCHANGÉS (emplacements constants, alarme = mêmes règles ECAM
  que le journal) ; l'impression force toujours le plan détaillé (`beforeprint` inchangé).
  Re-rendu ciblé `renderSvOnly` (délégation sur `.sv-wrap`) ; préfixe CSS `sv-` (st- était
  PRIS par le sélecteur de statut).
- **Couleur dans le contenu rédigé (v4.4.3)** : la SEULE couleur admise y est celle des REGISTRES,
  via des ENCADRÉS TYPÉS — jamais de couleur décorative libre (dans cette app, rouge = « ça tue si
  on l'oublie », ambre = « c'est là qu'on se trompe » : un rouge de mise en page dégraderait la
  crédibilité du rouge des étapes critiques). Syntaxe = les **alerts de GitHub** (`> [!CAUTION]`
  alerte, `> [!WARNING]` attention, `> [!NOTE]` information, `> [!TIP]` confirmation), tapable au
  clavier et rendue nativement par GitHub/GitLab/pandoc/Typora — les boutons produisent la forme
  CANONIQUE (marqueur seul sur sa ligne, MAJUSCULES) ; alias tolérés en lecture seulement
  (`[!alerte]`… et les glyphes ⚠ △ ℹ ✓). La couleur n'est JAMAIS seule : icône + libellé du
  registre en toutes lettres. `==surligné==` = surligneur ACHROMATIQUE (registre MEMO) : faire
  ressortir un mot sans emprunter une couleur qui a un sens vital.
- **Taille des images du contenu rédigé (v4.4.3)** : PAR IMAGE, dans le MODÈLE (`p.images[i].scale`,
  jeu fermé 25/33/50/66/75/100, défaut posé dans `migrate`), réglée par la galerie de l'éditeur —
  JAMAIS dans la syntaxe (un `=50%` dans `![](img:ID)` casserait la regex des clients antérieurs :
  les images DISPARAÎTRAIENT en bibliothèque partagée). Rendu par une CLASSE (`.md-fig.w50`), jamais
  un nombre interpolé dans un style. La réduction ne s'applique qu'au-dessus de 560 px (sur
  téléphone, une image à 25 % serait illisible sous stress).
- **Listes cochables des protocoles (v4.5.4)** : syntaxe GFM `- [ ] tâche` / `- [x] cochée`
  (aussi en liste numérotée), pour la **vérification rapide en lecture** — coches **ÉPHÉMÈRES
  par ouverture** (`state.protoTasks`, remis à zéro par `openProtocolRead` ; survivent aux
  re-rendus de synchro via l'overlay de `bindProtoTasks`, invalidées si le corps change).
  **AUCUN champ modèle, export v3 strictement inchangé** (le body reste la seule vérité ; un
  ancien client affiche « [ ] tâche » en item de liste — dégradation lisible). `mdRender` reste
  PUR et NON interactif (aperçus inertes) ; l'interactivité n'existe qu'en lecture. Case cochée =
  registre CONFIRMATION `--ok`, texte JAMAIS barré (on doit pouvoir relire). Une seule source de
  syntaxe : `MD_TASK_RX`/`mdTask` (parseur, `mdStrip`, nettoyage de `mdPrefixLines`). Pas de
  session/minuteur/trace : c'est le rôle des fiches, liables par « Voir aussi » (`related`).
- **Sélecteur segmenté `.seg` (v4.4.2)** : composant UNIQUE à pastille glissante, partagé par la
  tab bar basse (Aides ↔ Protocoles) et le dialogue « Créer » (Aide cognitive ↔ Protocole).
  L'état vit sur la RACINE (`.seg.i1` = 2ᵉ segment) et la racine n'est JAMAIS re-rendue — sinon
  la pastille saute au lieu de glisser (`paintSeg` est le seul point d'écriture). Le segment du
  dialogue pilote `state.section` : choisir un type y bascule aussi l'onglet de l'accueil.
- **Pieds de page (v4.4.2)** : UNE source de vérité pour l'état de stockage (`storageState`,
  pure) — variante LONGUE dans la sidebar de l'accueil (+ info-bulle), variante COURTE dans le
  pied des vues de LECTURE (fiche ET protocole, `readFooterHtml`). Le pied de lecture ne répète
  ni le code court ni la date de validation (déjà dans la méta du haut). En session de crise,
  l'état de stockage disparaît des deux pieds (aucun signal non actionnable pendant un soin).
- **Repli de l'étape ① (doctrine, v4.4.2)** : un démarrage IMPLICITE (cochage, minuteur,
  compteur, horodatage) ne replie JAMAIS « Confirmation diagnostique » — `ensureStarted` fige
  l'état ouvert. `renderKeepAnchor` ne peut compenser le scroll que si `window.scrollY ≥ hauteur
  retirée` : sur une page courte ou en haut de fiche, replier ferait sauter le contenu sous le
  doigt (bug v4.3.2, en pire). Le repli n'appartient qu'aux gestes qui l'ACQUITTENT : le bouton
  « Confirmé — démarrer la session » et la première navigation « Continuer → ».
- **En-têtes V5** : rangée principale unique (`.id-row` : retour ‹, marque, recherche FIXE de
  l'accueil, minuteurs de crise segmentés `#cbTimers` avec chrono **GLOBAL** — temps écoulé
  depuis la 1ʳᵉ action de session, décision produit —, badge de statut, Créer, thème, compte) ;
  en crise, bandeau TITRE teinté au registre ALERTE (`#crisisBand`, titre permanent +
  « ■ MODE CRISE »). Le sélecteur de section vit dans la tab bar basse (< 780) ou la colonne
  gauche (≥ 780), jamais dans la barre. **Menu ⋯ (v4.5)** : en lecture, toutes les actions
  secondaires (Modifier, Versions, Dupliquer, Export .json, Exporter en PDF, Historique des
  sessions, Terminer la session… — rangée `danger` en dernier, séparateurs entre groupes)
  vivent dans le menu ⋯ de la barre — il remplace les anciennes barres « Autorat » de bas de
  page. **Pied de page nomade** : `#appFooter` (Installer l'app, version, pastille synchro,
  jauge de stockage) ne vit plus qu'en bas de la sidebar de l'accueil — il est DÉPLACÉ
  (`placeFooter`/`rescueFooter`), jamais recréé (écouteurs vivants) ; « Exporter mes données »
  est dans la fenêtre Compte, l'import dans le dialogue Créer.
- **Largeurs & échelles fermées** (consignes Claude Design, v5/6 — la présente section est la
  référence) : cadre `.app` FLUIDE (en-tête/pied pleine largeur partout), contenus
  plafonnés ET centrés par vue — accueil = sidebar 240 px + grille ≤ 1320 px (auto-fill
  minmax(300px,1fr), gap 12 px, 1 colonne < 640) ; fiche = checklist ≤ 860 px (≥ 1200) + rail
  320 → 360 px (chiffres 34 px) ; protocole ≤ 780 px partout ; éditeurs alignés sur leur vue
  de lecture (fiche ≤ 860 px, protocole ≤ 780 px) + aperçu sticky 360 px
  (≥ 1000). L'accueil ≥ 780 est une COQUE FIXE (`body.view-home` : 100dvh, overflow hidden ;
  seuls `.home-side` et `.home-main` défilent — la sidebar ne bouge jamais à la bascule de
  section). Breakpoints : 430 / 560 / 640 / 780 / 900 / 1000 / 1200 px — pas de
  nouveau palier sans décision explicite. En-têtes (SPEC §5) : marque uniquement sur l'accueil ;
  éditeurs = actions dans la barre (Enregistrer à droite), AUCUN pied d'éditeur ; crise = une
  seule zone fixe en haut, jamais en bas. Plancher typographique **11 px** (app consultée sous
  stress : rien en dessous, nulle part) ; cibles tactiles ≥ 44 px (halo sur les contrôles 36 px
  de la barre).
- **Saillance & registres (audit v4.0.3)** : **un seul bouton rempli** (`--primary` plein) par
  écran — si deux actions coexistent, la moins critique passe en tonal (`--primary-soft`,
  cf. `.btn-new.tonal` : « Créer » s'efface quand « Reprendre » est affiché). **Un seul registre
  de titres de section** (petites capitales grasses, cf. `.block-h`), repris par les titres du
  contenu rédigé des protocoles (`.md-h1`/`.md-h2`) — pas de nouveau style de titre.
- **Couleur d'accent par utilisateur (v4.5)** : 5 accents prédéfinis AA (sarcelle, violet,
  indigo, framboise, ardoise) + bleu clinique par défaut ; **connecté seulement** (l'accent
  tombe à la déconnexion). Portée : l'accueil ENTIER (`body.view-home`) + l'EN-TÊTE de toutes
  les vues (`header.bar`) ; le CONTENU clinique (fiches en crise, protocoles, éditeurs) reste
  bleu clinique. Jamais de vert/ambre/rouge en accent (registres réservés). Persistance :
  `spaceKey('ac-accent')` local + `data.prefs.accent` cloud (avec thème et taille du texte).
- **Code couleur des catégories (SPEC crise §1, v4.3.0)** : la couleur de catégorie (choisie
  par l'utilisateur) n'apparaît qu'en **pastille** (`.cat-dot`, anneau à la couleur du fond
  porteur), **liseré** (cartes, 4 px) ou **teinte ≤ 15 %** avec texte de la couleur — JAMAIS en
  aplat saturé (les surfaces pleines sont réservées aux états système) et jamais seule (toujours
  le nom en toutes lettres). La **sélection** (sidebar, chips) = **bleu système**, jamais la
  couleur de la catégorie. Le bandeau de crise ne porte pas la couleur de catégorie. Sélecteur
  des éditeurs = « **une sélectionnée + Autre…** » : chip teinté 14 % (la seule teinte autorisée
  — prévisualise liseré/pastille) + menu ancré (bottom sheet < 780) avec « ＋ Nouvelle
  catégorie » ; plus jamais la rangée de toutes les catégories.
- **Dialogue « Terminer la session ? » (SPEC crise §3, v4.3.0)** : SEULE porte de sortie d'une
  session (menu ⋯, fin d'algorithme, ✕ du bandeau sessions — jamais d'arrêt direct). Contexte
  (titre + durée) et **conséquences annoncées avant le choix** ; « Poursuivre » = action sûre
  (contour, focus initial, Échap) ; « Terminer » = un des SEULS rouges pleins de l'app
  (`--critical-bd`). Terminer depuis l'écran de crise ramène à l'accueil. **Même registre pour
  les confirmations destructrices (v4.3.1)** : le bouton principal de `confirmDlg` en mode
  `danger` (supprimer une fiche, un protocole, la bibliothèque…) est rouge plein
  `--critical-bd` + texte blanc — uniquement dans la fenêtre de CONFIRMATION finale ; les
  boutons « Supprimer » de fin de formulaire et des zones sensibles restent en contour.
- **Marqueur d'étape hors du champ (v4.3.0)** : dans les éditeurs, le préfixe `⚠ `/`△ ` ne vit
  plus DANS l'input (il était effaçable à la main = changement de type accidentel) — champ =
  texte nu, rangée **encadrée** au registre, préfixe re-posé par le handler (la CHAÎNE stockée
  garde le préfixe : format v3 inchangé). Les repères posologiques ont la même bascule ⚠ par
  bouton (le signe est intapable au clavier).
- **Indicateur de mode des éditeurs (v4.3.0)** : la barre affiche en permanence
  « ÉDITION/CRÉATION — AIDE COGNITIVE/PROTOCOLE » (micro-titre 11px/800, encre douce — informe,
  n'alerte pas), tronqué au mode seul < 560 px ; le badge de statut n'y disparaît JAMAIS
  (thème et compte s'effacent à sa place en étroit). Pas de barre d'actions flottante en bas
  d'éditeur (SPEC §5/§6 : une seule zone fixe, en haut ; clavier mobile ; Supprimer reste isolé
  en fin de formulaire).
- **Alarme de minuteur (règle QRH/ECAM, v4.2.0)** : une alarme ne DÉPLACE JAMAIS le contexte de
  travail quand la session est sous les yeux — pas d'auto-défilement, pas d'ouverture de panneau,
  pas de fenêtre par-dessus la checklist. Attention par bip/vibration + flash bref (master
  caution), puis **persistance en segment ambre** dans la barre `#cbTimers` tant que le minuteur
  échu n'est ni relancé ni réarmé (acquittement par l'action, cf. `onTimerFired`/`updateRtStrip`).
  Banderole cliquable + flash écran + notification système : **réservés à la session hors de
  vue** (autre vue/fiche, app en arrière-plan) — l'alerte est alors ROUTÉE vers l'utilisateur.
- **Liens « Voir aussi » (v4.2.0)** : `related` peut référencer des aides ET des protocoles
  (mêmes ids ; export v3 inchangé — un ancien client ignore les ids qu'il ne résout pas), même
  périmètre uniquement (Perso ou même bibliothèque, comme les documents partagés) ; sélecteur
  filtrable commun aux deux éditeurs, au design de « Joindre un document existant ».
- **Interactif** : cible tactile ≥ 32 px (44 px pour les contrôles du mode crise) ; tout nouvel
  élément interactif reçoit un état `:focus-visible` et un équivalent clavier (Entrée/Espace).
  Action destructrice en situation de crise = geste « maintenir » (`holdToReset`), pas un simple
  tap. Deux boutons « retour » empilés (aperçu → éditeur → bibliothèque) reçoivent une
  **inhibition temporelle** de 700 ms contre le double-tap (`.guarded`, opacité réduite —
  logique ECAM). Grammaire des boutons de gestion : **pointillé** = créer, **contour** = gérer/
  secondaire, **plein** = action primaire (un seul par écran). **Tactile (v4.3.1)** : tous les
  contrôles portent `touch-action:manipulation` (supprime le délai double-tap de Safari iOS) ;
  champs et menus ≥ **16 px sur écrans tactiles** (sous 16 px, Safari iOS zoome la page au
  focus — taps « perdus » ; un compact < 16 px n'est admis qu'au pointeur fin, cf. fenêtre
  bibliothèque).
- Toute donnée affichée passe par `esc()` (contenu potentiellement importé/partagé). C'est la
  **seule** barrière anti-XSS (la CSP monofichier impose `script-src 'unsafe-inline'`) : ne jamais
  la relâcher ; les liens/images du mini-Markdown sont en plus nettoyés AU POINT D'INSERTION
  (`mdInline` href, `mdRender` via `safeImg`) pour ne pas dépendre d'un invariant d'ordre. La CSP
  est durcie par hashs SHA-256 des scripts inline (`scripts/csp-hashes.mjs`, rejoué par
  `release.sh`) : un inline injecté est bloqué sur navigateur récent. Risque résiduel documenté
  dans `docs/deploiement-et-conformite.md` (§ 1.1).
- Toute donnée importée/chargée passe par `migrate()` / `sanitizeCats()` (point d'entrée unique de
  compatibilité et de sécurité) ; nouveaux champs = facultatifs, avec défaut posé dans `migrate()`.
- **Documents PDF** : le PDF vit en ArrayBuffer dans le store IndexedDB `attachments` (base v5 ; Blob historique accepté en lecture), JAMAIS en
  base64 dans la fiche ni dans l'export JSON ; la fiche ne porte que `attachments:[{id,name,size}]`
  (validé par `safeAttachment` — id jamais régénéré, entrée invalide rejetée ; plafonds
  `MAX_PDF_BYTES`/`MAX_ATT_PER_ENTITY`). En repli KV l'ajout est refusé (`supportsAttachments`).
  Un document peut être **partagé** entre plusieurs fiches du même périmètre (même id référencé) :
  les documents ne sont supprimés que par `gcAttachments` (comptage de références au démarrage).
- **Export/import « avec documents » (v4.5.0)** : quand le contenu exporté référence des PDF,
  l'utilisateur choisit — `.zip` qui les embarque (`donnees.json` STRICTEMENT identique au JSON
  v3 + `documents/<attId>.pdf`) ou `.json` seul (métadonnées, comme avant). ZIP **maison** zéro
  dépendance (`zipBuild` écrit en STORE — les PDF sont déjà compressés ; `zipParse` lit STORE +
  DEFLATE via `DecompressionStream` natif, CRC vérifié, bornes anti-zip-bomb) ; import détecté à
  la **signature**, jamais à l'extension. RÈGLE de restauration (`importAtts`) : un import
  n'écrase **JAMAIS** un binaire existant (même id → le document présent fait foi) ; binaire du
  zip posé seulement s'il manque, signé `%PDF-` (`isPdfBytes`) et sous plafond ; référence sans
  binaire gardée seulement si le fichier vient du même espace (elle peut suivre par la synchro).
- Fonctions pures testables : les exposer via le hook `?__actest` (fin de `index.html`) et ajouter
  un test dans `tests.html`.
- Ne jamais supprimer un champ du modèle fiche/catégorie (compatibilité ascendante).
- **Hygiène de suppression** : retirer un composant = retirer AUSSI son CSS orphelin ET mettre à
  jour la doc qui le cite (AGENTS.md, `design/`). Une classe morte documentée (`.endcap` après
  V5) fait diverger doc et code. Toute suppression de fichier référencé (ex. une SPEC) implique de
  purger la référence.
- **Nommage SQL** : ne JAMAIS renommer un identifiant existant (`fiches`, `category_sets`,
  `fiche_notes`… sont historiquement en français : un renommage casserait les instances déployées
  et le client, sans gain fonctionnel) ; tout **nouvel** objet (table, fonction, politique,
  colonne) est nommé **en anglais** (`protocols`, `list_orphan_attachments`…). Le français reste
  la langue des commentaires et des textes visibles.
- La sécurité réelle est **côté serveur** (politiques RLS de `supabase/schema.sql`, y compris
  celles du bucket Storage `attachments` — le **chemin encode le périmètre** : `u/<uid>/…` perso,
  `l/<libId>/…` partagé) ; les contrôles client ne sont que de l'ergonomie. Toute évolution du
  schéma OU des politiques du bucket doit être revalidée avec `supabase/rls-tests.sql`.

## Périmètre réglementaire
L'app est un **support de contenu** rédigé et validé par l'utilisateur, sans calcul ni
recommandation individualisée : voir `docs/deploiement-et-conformite.md` (§ 2, statut
non-dispositif-médical). Toute fonctionnalité qui produirait une sortie individualisée
(ex. calcul de doses) doit être évaluée au regard de ce statut **avant** développement.

## Se repérer dans `index.html` (monofichier, ~5 600 lignes)
Le fichier s'ouvre sur un **grand commentaire d'architecture** (objectif, règles de conception,
modèle de données, règles de sécurité) : le lire en premier. Ensuite, dans l'ordre :

| Section (bannières `/* ===== … ===== */`) | Contenu |
|---|---|
| `<style>` | Tout le CSS (variables dans `:root`, thème sombre via `html[data-theme="dark"]`) |
| Backends | `KV` / `IDB` / `MEM` : trois stockages locaux interchangeables derrière `Data` ; **un espace local par compte** (`currentSpace`/`dbNameFor`/`spaceKey`, bascule par reload à la connexion d'un autre compte, jamais de mélange entre comptes) ; stores IndexedDB v5 : `fiches`, `meta`, `sessions`, `backups`, `attachments` (ArrayBuffer PDF), `protocols` |
| State & Runtime | `state` (quoi afficher) ; `Runtime` (état vivant du mode crise) ; garde-fous `safeId`/`safeColor`/`safeImg`/`safeAttachment`/`sstr`/`sarr` |
| Modèle | `blankFiche`, `migrate` (point d'entrée sécurité/compat), `seed`/`seed2`, catégories |
| Load | `chooseBackend`, `load()` (démarrage), `persist`, `softDelete` |
| Runtime | minuteurs/compteurs/audio (`tickAll`, `beep`), sessions vives (`liveSessions`) |
| Sessions | auto-enregistrement (`persistLive`), reprise, compte-rendu |
| Render | `render()` → `applyViewChrome` (chrome d'en-tête) puis `renderFiches`/`renderProtocols` / `renderRead` / `renderEditor` (template strings + écouteurs) ; en lecture de fiche, `overviewSection` (JOURNAL de parcours + PLAN de l'aide, défaut) ou `navSection` (vue guidée), re-rendus ciblés `renderOvOnly`/`renderNavOnly` |
| Flow SVG | `buildFlowSVG(f,cache)` : organigramme auto — géométrie PURE sans état (v4.7.0) ; l'état de session est PEINT par classes après insertion (`flowPaintState` : `fn-cur`/`fn-ok`/`fn-off`, halo et badge ✓ bakés masqués) et les nœuds sont NAVIGABLES en lecture (`bindSvgNav` → `jumpToBlock` — jamais de cochage dans le SVG, jamais de démarrage de session ; inerte dans l'éditeur) |
| Visionneuse PDF | `pdfLib` (chargement paresseux de `vendor/pdfjs`), `openPdfViewer` (rendu virtualisé par IntersectionObserver ; zoom d'OUVERTURE = « page entière » calculé d'après le ratio du document et la fenêtre, `pdfFitPageZ`, bornes 25–400 %, boutons « Page »/« Largeur »), fenêtre `#pdfModal` ; miniatures de la 1ʳᵉ page dans les listes « Documents » (`attThumbHtml`/`genAttThumb` : paresseuses, une à la fois, cache mémoire de session — jamais de chargement de pdf.js au démarrage) ; badge « △ à télécharger » si le binaire n'est pas encore sur l'appareil (`hydrateAttThumbs`/`refreshAttRow` — état décidé sur la lecture IndexedDB, rafraîchi en direct par le téléchargement de fond de la synchro) |
| Mini-Markdown | `mdBlocks`/`mdInline`/`mdRender`/`mdStrip`/`mdCells`/`mdCallout`/`mdTask` : parseur maison XSS-safe (esc() d'abord) du contenu rédigé des protocoles — titres, listes, citation, code, image, TABLEAUX (v4.4.2), ENCADRÉS TYPÉS et `==surligné==` (v4.4.3), LISTES COCHABLES `- [ ]` (v4.5.4). Registre et alignement viennent toujours d'un jeu FERMÉ posé en CLASSE, jamais d'un attribut piloté par l'utilisateur |
| Protocoles | `blankProtocol`/`migrateProtocol` (point d'entrée sécurité/compat), `renderProtocols`/`renderProtocolRead`/`renderProtocolEdit`, sélecteur de section dans l'en-tête (`#hdrSec` statique, `state.section`) |
| Export / Import | JSON `version: 3` + conteneur `.zip` « avec documents » (`zipBuild`/`zipParse` maison, `importAtts`) ; règles de rétrocompatibilité documentées sur place |
| Compte & synchro | `Auth` (OTP e-mail), `Sync` (pull/push local-first), fenêtres associées |
| Accessibilité | gestion centralisée des modales (focus, Échap, Tab) |
| Mode test | hook `?__actest` : expose les fonctions pures pour `tests.html` |
