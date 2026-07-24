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
- **Si le CSS d'`index.html` a changé** : `npm run design:build` régénère `design/ds/` (source
  de vérité = le monofichier) — puis committer la régénération. `npm run design:check` échoue si
  `design/ds/` a dérivé du code (le CI le rejoue ; `release.sh` régénère automatiquement). Pousser
  le résultat vers le projet Claude Design distant reste un geste explicite (skill `/design-sync`).
- `npm run audit` — **audit transverse (v4.23.0)**, à rejouer dès qu'on touche au chrome de crise,
  au rail, aux feuilles Plan/Consulter ou à un token de couleur. Deux harnais Playwright qui
  MESURENT au lieu d'affirmer (hors CI : plus lents, et un échec y demande un arbitrage humain,
  pas un blocage de merge) :
  - `scripts/audit-a11y.mjs` — 6 surfaces × 2 thèmes : plancher typographique 11 px, contraste
    calculé sur le fond EFFECTIF (remontée des ancêtres + composition alpha, exemption « grand
    texte »), cibles (44 px en crise, 24 px ailleurs, halo `::after` compté), `--soft` en couleur
    de texte, « hors chemin » signalé par la seule opacité, et **focus visible sous de VRAIES
    touches Tab** — un `.focus()` programmatique ne déclenche pas `:focus-visible` et produisait
    des faux positifs en série. L'anneau est cherché sur l'élément ET ses ancêtres (motif
    `.card:has(.card-open:focus-visible)` : le bouton pose `outline:none`, la CARTE porte
    l'anneau, 3 niveaux plus haut) — mais sur un ancêtre on n'accepte QUE l'outline, son
    `box-shadow` étant en général une élévation permanente qui masquerait un vrai défaut.
  - `scripts/audit-doctrine.mjs` — ECAM/QRH/AC 120-71B traduits en invariants observables :
    ordre du quai et position en px des boutons Plan/Réf. INCHANGÉS quel que soit l'état,
    débordement annoncé, memory items dans le flux et non recopiés dans la feuille, feuille
    Consulter inerte (0 coche, 0 démarrage), taper un nœud du plan ne démarre ni ne coche,
    snackbar mis en attente en session, mouvement nul sous `prefers-reduced-motion`.
  - `scripts/audit-verify.mjs` — la passe Do-Verify laisse un résultat CONSULTABLE (cf. trace de
    vérification). **Les sondes JETABLES s'écrivent à la racine en `.nom.mjs`** (pour trouver
    `playwright` dans `node_modules`) et sont ignorées par git ; seuls les harnais qui RESTENT
    vivent dans `scripts/`.
- L'intégration continue (`.github/workflows/ci.yml`) rejoue check + tests + `design:check` sur
  chaque push/PR.

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
  pour les 3 états. **v4.23.0 — « ✓ Validé(e) » ne s'affiche PLUS là où la DATE de validation est
  visible** (cartes et vues de lecture) : la date dit la même chose, en plus précis, et une carte
  ne porte un statut que si elle ATTEND quelque chose (Brouillon, À relire, À compléter,
  À revérifier). **CONDITION** : sans date, la pastille RESTE — sinon rien ne distinguerait une
  fiche validée d'une fiche sans statut. `statusChip(st,fem,{validation})`, `opts.always` pour les
  éditeurs et le badge d'en-tête où le statut est l'objet du réglage. (Le commentaire du code
  décrivait cette règle depuis v4.5 sans que la fonction ait le paramètre pour l'appliquer, et
  AGENTS.md affirmait le contraire : contradiction levée.) Les cartes affichent désormais la DATE
  (elle en était absente) ; périmée > 2 ans = « △ À revérifier » (ex-« △ à revoir ») + date en
  ambre. Le chevron d'ouverture EXISTAIT déjà (`uiIcon('chev')`) — ne pas en ajouter un second.
  Anciennement (△ À compléter, ○ Brouillon ;
  tokens `--tag-bg`/`--tag-ink`) — la couleur reste réservée au danger et aux catégories
  (liserés de cartes ; sur les cartes d'accueil la pilule de catégorie est NEUTRE, la couleur
  ne vit que dans le liseré). Surfaces : bandeau système persistant (`#sysBanner`, INFO), snackbar
  transitoire (`.toast`, ardoise `--rt-*` fixe dans les deux thèmes) ; **en session de crise,
  aucune notification flottante** — snackbars mis en attente (cf. `toast()`), bandeau système
  visible SEULEMENT sur l'accueil (`body.view-home`, v4.20.0 — en lecture il glissait sous
  l'en-tête sticky, à moitié masqué par le bandeau rouge du titre ; recharger pendant un soin
  n'est jamais souhaitable : l'invitation attend le retour à l'accueil). Le panneau minuteurs suit le THÈME depuis V5 (plus de panneau
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
  une étape des deux registres → rouge.
  **LISTE D'ÉTAPES — normal = LIGNE, signalé = BOÎTE (lot 8, v4.23.0, décision utilisateur ;
  même doctrine app-wide que le rail et la posologie)** : `ol.steps li` normale est une LIGNE À
  FILET (`border-top`), sans cadre, sans fond, sans liseré — et **sans le numéro `01/02/03`**
  (retiré : on coche dans n'importe quel ordre, et les renvois →/↺ visaient le numéro de BLOC
  `.ov-n`, conservé, jamais celui des étapes ; `counter` supprimé). Seule une étape `⚠`/`△` est
  une BOÎTE teintée (`.crit`/`.vigil` : fond + cadre + liseré 3px + texte + **glyphe de tête**).
  Ainsi la couleur RESSORT au lieu de se noyer dans des cadres partout — c'est ce qui règle le
  « 3 étapes colorées sur 5 » (retour d'usage). **Le glyphe ⚠/△ est OBLIGATOIRE** (option `mark`
  de `stepTxtHtml`, + étiquette `.sr-only`) : depuis que le normal est plat, `⚠` rouge et `△`
  ambre ne se distingueraient QUE par la hue sans lui (WCAG 1.4.1) ; NON passé au mode lecteur
  (`.vstp`, dont le `△` signifie « écart »). Étape COCHÉE = aplatie (plus de fond de boîte pour
  une normale — la coche verte + texte grisé barré + opacité suffisent ; une étape signalée
  cochée garde sa boîte au cadre vert doux). Le filet d'une ligne juste après une boîte est
  supprimé (la boîte a déjà sa bordure basse), mais deux boîtes consécutives gardent chacune la
  leur (`:is(.crit,.vigil)+li:not(.crit):not(.vigil)`). **Un REPÈRE POSOLOGIQUE est toujours ambre** (jamais rouge,
  v4.23.0) : c'est une référence, pas un geste — cf. la règle détaillée au rail. Le **gras est exclu des étapes** (texte déjà en gras à
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
- **Liseré gauche 4 px — DÉCISION DE NE PAS TOUCHER (v4.23.0)** : le bord gauche épais des cartes
  (`.ov-block`, `.notice`, `.last-sess`, cartes d'accueil…) est une SIGNATURE partagée, et sur
  `.ov-block` sa COULEUR porte l'état (neutre = à venir, bleu = ici, vert = fait, ambre = décision).
  Objection soulevée et RETENUE comme fondée : sur le bloc COURANT (`.cur`) toute la bordure passe
  déjà au bleu, donc les 4 px de gauche n'ajoutent alors aucune information et ne produisent qu'une
  asymétrie. **Statu quo décidé par l'utilisateur** : uniformiser sur le seul bloc courant casserait
  la signature partagée avec les autres cartes. Ne pas « corriger » cette asymétrie sans rouvrir la
  question sur TOUTES les surfaces à la fois.
  **SUITE (v4.23.1) — le vrai défaut était un DOUBLEMENT, pas l'épaisseur** : la bande d'une étape
  signalée portait EN PLUS son propre liseré de 3 px, collé au bord du bloc → deux traits verticaux
  parallèles. FUSIONNER les deux a été envisagé et ÉCARTÉ : le bord du bloc est le canal de l'état
  du BLOC (le bleu « vous êtes ici » doit rester CONTINU), le liseré d'une bande celui du registre
  de l'ÉTAPE — les confondre ferait porter deux sens au même trait et hacherait le bleu. C'est donc
  le liseré de la BANDE qui est supprimé : teinte + case colorée + texte coloré + glyphe ⚠/△
  marquent déjà l'étape sans ambiguïté. Ne pas le réintroduire.
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
- **Journal de parcours du mode crise (v4.9.0 ; FIL CONDENSÉ v4.16.0 — le mode guidé y est
  FUSIONNÉ)** : la lecture d'une fiche À ALGORITHME a DEUX modes — `overview` « Dynamique »
  (défaut : JOURNAL chronologique) ↔ `static` « Statique » (TABLEAU compact façon SFAR, cf.
  bullet dédié) ; bascule UNIQUE `#readTopSeg` en tête de fiche, masquée si `!hasFlow` (fiche
  mono-bloc : rendu guidé `navSection` conservé — les vues y seraient identiques). L'ex-mode
  `guided` n'existe plus en vue : `currentReadMode()` mappe une préférence `'guided'`
  enregistrée vers `'overview'` (la valeur reste tolérée en LECTURE de préférence, jamais
  proposée). Préférence PAR UTILISATEUR (`spaceKey('ac-read-mode')` + `data.prefs.readMode` —
  le pull de synchro n'écrit QUE la préférence locale, il ne bascule JAMAIS la vue ouverte).
  Les vues partagent le MÊME Runtime : `nav`/`navSeq`/`checked` et l'export v3 STRICTEMENT
  inchangés. **Doctrine du journal (leçon v4.6→v4.9 : ne PAS poser un état temporel sur une
  carte spatiale — un bloc à plusieurs passages y perd l'utilisateur)** : `nav[]` EST la
  chronologie — chaque passage est une CARTE POSTÉE à la suite (modèle ECAM), rien ne mute
  au-dessus, on lit toujours vers le bas ; le journal n'a PAS de curseur (la position est le
  BOUT, `state.navPos=fin`). **Fil condensé (v4.16.0, `ovPresList` PURE — décision utilisateur
  validée ECAM/QRH/AC 120-71B)** : trois présentations par passage — carte dépliée `'open'`,
  LIGNE D'ÉTAT verte relisible `'line'`, CHIP `'chip'` (pastille n° + TITRE ABRÉGÉ + ✓ vert,
  ou n° + « › réponse » en toutes lettres tronquée pour une décision — v4.16.2, décision
  utilisateur : « le numéro seul ne parle pas à un humain » ; la couleur jamais seule) ; règles : le BOUT
  est toujours une carte ; un passage INCOMPLET n'est JAMAIS une chip (l'invariant qui fait la
  conformité — repli manuel = ligne d'état au maximum) ; complets non-courants : les 2 plus
  récents en ligne, les plus anciens en chips ; SURCHARGE MANUELLE (v4.16.1) : le repli
  (`ovFold[idx]=true`) PERSISTE, le dépliage (`false`) est une CONSULTATION TRANSITOIRE —
  `ovDropOpens()` l'efface à chaque geste de NAVIGATION (Continuer, réponse, Refaire, entrée
  par plan/SVG ; retour d'usage : une carte dépliée puis actée restait ouverte pour toujours) ;
  chips consécutives regroupées en rangées `.ov-crumbs`
  CHRONOLOGIQUES (une carte/ligne coupe la rangée) ; taper une chip = DÉPLIER la carte sur
  place (`data-ovix` → `ovFold[idx]=false`) ; LIGNE-BILAN ECL (v4.16.4, décision
  utilisateur — modèle Boeing ECL : une checklist terminée se referme en un statut d'une
  ligne) : une rangée de PLUS DE 4 chips se replie en `.ov-runline` « ✓ n passages ·
  a→b ▸ » (titres en info-bulle ; clé `ovFold['r:'+premierIdx]`, dépliage = consultation
  transitoire comme les chips — `ovDropOpens` couvre les clés `r:`) ; l'impression déplie
  tout (`_printingOv`).
  Condensation appliquée AU RENDU d'un geste de navigation, JAMAIS sous le doigt pendant le
  cochage ; une décision repliée garde sa réponse en toutes lettres (`.ov-ans`) et ses options
  restent actives partout (changer d'avis = nouveau passage décision+cible en bout de journal,
  traçabilité complète) ; l'avancement (« Continuer — … → » / « Terminer ») n'existe QUE sur
  l'instance du bout — une boucle est un simple Continuer ; AVANCEMENT ANCRÉ (v4.16.3,
  `ovAdvanceRender` — retour d'usage « scrolls incessants ») : le re-rendu d'un geste
  d'avancement compense la condensation par un `scrollBy` ancré sur l'instance du geste
  (dérive visuelle 0 px) et ne défile vers la nouvelle carte QUE si elle n'est pas déjà
  entièrement visible ; « ↺ Refaire » poste volontairement
  une nouvelle carte, tout ce qui précède reste tel quel. Cocher dans une instance ne re-rend
  JAMAIS (délégation sur `.ov-wrap`, chirurgie `ovAfterCheck`/`ovPaintLive` ; `renderOvOnly` =
  pendant de `renderNavOnly`, qui dispatche). Fonctions pures : `passInfo` (rang du passage),
  `instComplete`, `ovPresList` ; `minimapData` = source UNIQUE de l'état PAR BLOC.
- **Plan de l'aide (v4.10.0 arbre, v4.12.0 organigramme hybride)** : sous le journal, la
  STRUCTURE COMPLÈTE façon algorithme papier / checklist conditionnelle QRH — `flowPlan(f)`
  (pure, cache WeakMap par objet fiche, jamais l'éditeur) : DFS depuis le départ, le TRONC
  reprend au POINT DE CONVERGENCE (post-dominateur immédiat — itératif, graphes minuscules),
  cible déjà décrite = lien « ↺ reprendre à n » (les BOUCLES deviennent une structure lisible,
  ex. cycles 2 min d'un ACR), chaque bloc n'apparaît qu'UNE fois. `flowPlan().order` =
  NUMÉROTATION COMMUNE (plan, journal, chips du fil, statique — `minimapData` la suit). Le plan est
  IMMUABLE et INERTE côté cochage (leçon v4.6, décision RE-CONFIRMÉE en maquettes v4.12 :
  jamais de cases — la trace vit dans le journal) ; il porte un état LÉGER (✓ dernier passage
  complet, ● ici, ×n passages, `offPathSet`) et sert à NAVIGUER : taper un bloc = `jumpToBlock`,
  un lien →/↺ défile DANS le plan (flash). **Organigramme hybride (v4.12.0)** : branches d'une
  décision côte à côte quand l'écran le permet, empilées sinon — règle CSS PURE, locale et
  récursive ; **UNE SEULE COLONNE sous 640 px (v4.21.1, retour d'usage réel — même décision
  que le statique v4.13.1 : des colonnes de ~150 px émiettaient les mots cliniques lettre à
  lettre ; en pile, rails + chips d'option portent la structure)** ; à partir de 640 px,
  `.pl-cols` grid `auto-fit minmax(148px,1fr)` plafonnée par `c1…c4` (nombre de branches EN
  COLONNE — sans lui, une branche pleine largeur force des pistes de 148 px sur grand écran) ;
  branche PROFONDE (`deep` : > 2 blocs ou décision imbriquée) = pleine largeur toujours
  (l'ancienne `deepv` — > 3 étapes, pleine largeur < 640 seulement — est absorbée par la règle
  une-colonne v4.21.1). RAIL de branche 3 px étiqueté
  (bleu = prise, pointillé estompé + mention « hors chemin » = écartée, la couleur jamais
  seule) avec COUDE de convergence (`.pl-elbow`) ; REPLI PAR BRANCHE en ligne-bilan
  (`state.ovFold['b:…']`, chip-bouton ≥ 44 px « n blocs · k ✓ · → n ») — hors chemin
  auto-repliée, JAMAIS bloquant ; FIL D'ANCÊTRES v5 — STICKY CONTINU (v4.22.1, décision
  utilisateur « ce serait mieux si elle suivait de manière continue », après QUATRE
  itérations — pile sticky à décalages FIGÉS superposée v4.12, épingle unique = mauvaise
  question v4.13.2, bulle unique = niveaux perdus v4.13.3, pile de bulles flottantes
  synthétiques `#plPin` v4.14 → v4.22.0) : les cartes-questions RÉELLES du plan s'épinglent
  sous l'en-tête (`position:sticky`, top CUMULÉ MESURÉ posé par `ovPlanPin` = base + Σ
  hauteurs des cartes ancêtres + 3 px — les hauteurs réelles de v4.14.3 résolvent ce qui
  avait tué le sticky v4.12), la superposition étant stabilisée par la COMPACTION une-ligne
  des cartes épinglées (`.stuck` : nowrap + ellipse — le chip injecté ne fait plus passer un
  titre sur deux lignes). AUCUNE copie synthétique (`#plPin` SUPPRIMÉ avec sa clé, son
  hystérésis, ses hauteurs mémorisées et sa garde v4.21.0 « fixed dans un ancêtre
  transformé ») et AUCUN mouvement autonome : tout mouvement est le geste de défilement
  (compositeur, réversible au pixel, rien à inhiber sous `prefers-reduced-motion`) ;
  l'indentation réelle est conservée par construction, le tap = `data-plgo` (la carte est le
  VRAI élément) ; décrochage à la convergence NATIF (sticky borné par `.pl-decwrap`) et
  chaque niveau se replie DERRIÈRE son ancêtre au décrochage (z-ordre `pd0…pd3` décroissant,
  en-tête à z 20 au-dessus — décision utilisateur, modèle ECL : une sous-procédure terminée
  se referme dans sa procédure mère, et ré-émerge symétriquement à la remontée ; les classes
  pdN posées par le walker depuis v4.14, inertes depuis, reprennent du service) ; chip
  « › option » de la branche à la ligne de lecture INJECTÉ dans la carte épinglée (le
  Oui/Non reste attaché à SA question ; règle inchangée v4.14.2 : branche SEULE sur sa
  rangée — des colonnes côte à côte sont toutes sous les yeux), calé « NI AVANT NI APRÈS »
  (mesuré au pixel) : le chip n'apparaît qu'à l'instant où l'ÉTIQUETTE d'option passe
  DERRIÈRE la carte épinglée — il la REMPLACE (même doctrine de continuité que le sticky ;
  tant qu'elle est visible, l'étiquette porte la réponse elle-même) — et les zones de
  branches sont JOINTIVES (la zone d'une branche court jusqu'au haut de la suivante :
  plus de clignotement du chip entre deux branches) — un chip qui APPARAÎT ou
  CHANGE porte la micro-animation `pin-in` (v4.22.0 : transform/opacité ~200 ms, inerte
  sous reduced-motion), sa disparition et les cartes n'animent JAMAIS ; discipline
  lecture/écriture GROUPÉES dans `ovPlanPin` (précédent `svPaintArrows` ; un top qui change
  se corrige à l'événement de défilement suivant) ; `ovPlanStick` reste le point d'entrée
  « géométrie a changé » (re-rendu, repli de branche, hauteur d'en-tête via ResizeObserver,
  taille du texte — l'ancienne variable `--pl-stick` n'existe plus) ; sur papier, carte
  complète sans chip (`@media print`).
  **TROIS AFFICHAGES du Plan (v4.18.0, fusion — décision utilisateur, ordre ECAM E/WD → SD :
  l'ACTION d'abord, la structure en annexe SOUS le journal)** : sélecteur `data-plview`
  (`state.ovPlanView` 'plan'/'ladder'/'svg', jamais persisté, impression = 'plan') —
  **Détails** (organigramme hybride), **Échelle**, **Schéma** (le SVG spatial : l'ex-panneau
  « Algorithme » d'AVANT le journal est SUPPRIMÉ en dynamique — il ne subsiste que pour les
  fiches SANS algorithme ; zoom/plein écran conservés, `renderOvOnly` rebranche
  `bindFlowZoom` et `ovPaintLive` peint `.flow-scroll` où qu'il vive ; le fil d'ancêtres ne
  s'épingle qu'en 'plan'). **Échelle ECAM** : une ligne par bloc, retraits
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
  **TRACE DE VÉRIFICATION (v4.23.0, retour d'usage « une fois vérifié on ne sait plus ce qu'on a
  vérifié »)** : `Runtime.verified` et `Runtime.vgaps` sont des états **DISTINCTS de `checked`**.
  Avant, « Constaté ✓ » écrivait la MÊME clé que le cochage et `vf.gaps` était JETÉ à la sortie :
  une étape cochée à l'exécution devenait indiscernable d'une étape CONSTATÉE par observation, et
  un « △ Écart » d'une étape jamais atteinte — or c'est précisément la distinction que la seconde
  passe existe pour produire (AC 120-71B : en do-verify la réponse vient de l'état CONSTATÉ, pas du
  souvenir d'avoir fait le geste ; la circulaire ne prescrit en revanche AUCUN modèle de données —
  le choix d'enregistrer la trace est une décision de conception, pas une exigence littérale).
  Rendu durable : pilule « ✓✓ vérifié » / « △ écart » sur la ligne. Un geste MANUEL invalide la
  trace (cocher lève l'écart, décocher retire la constatation) — et comme le cochage est
  CHIRURGICAL (sans re-rendu), le marqueur doit être repeint sur place par `paintStepTrace`, sinon
  il reste périmé à l'écran alors que l'état est juste (défaut trouvé par `scripts/audit-verify.mjs`).
  Portée : stocké dans la SESSION seulement — l'export v3 des fiches et le format des clés
  (`seq:blocId:index`) sont inchangés ; un client antérieur ignore les deux champs.
  **Mode lecteur** (binôme, plein écran `#readerMode`, statique + délégation unique) : un
  challenge à la fois (26 px, réponse mono 20 px, zone verte ≥ 72 px), piloté sur le BOUT du
  journal — « Répondu » coche la même clé, fin de bloc = mêmes règles que « Continuer »
  (jamais d'avance tant que tout n'est pas confirmé, « Revoir » ramène au premier écart),
  décision = même chemin qu'une option ; Échap/✕ quitte sans rien perdre ; z-index 92 SOUS
  `#screenFlash` (99) — le flash d'alarme reste visible ; chrono de session via
  `updateRtStrip` (`#rmTime`) ; entrées : bouton « Lecteur » sur l'instance du bout + menu ⋯.
  **Garde-fou télégraphique** (`stepGuardTxt`, non bloquant, patron `nfGuardTxt`) : bloc
  > 7 étapes ou challenge > 110 caractères (la réponse « :: » ne compte pas).
  **Minimaps SUPPRIMÉES (v4.17.0, décision utilisateur)** : la bande de chips-blocs
  `#ovChips` de l'en-tête (< 1000 px) et le panneau « Algorithme — position » `#ovMap` du
  rail droit (≥ 1000 px), tous deux de v4.8.0, sont retirés — redondants depuis que le FIL
  CONDENSÉ (chips titrées, lignes-bilan) et le PLAN portent la numérotation commune, l'état
  par bloc et le saut `jumpToBlock`. `minimapData` RESTE (source unique de l'état par bloc,
  consommée par plan/statique/SVG/tests). Ne pas réintroduire sans besoin d'usage constaté
  (l'historique git — tag v4.16.4 — garde l'implémentation). **SVG navigable (v4.7.0)** : taper un nœud de
  l'organigramme = y ALLER (`jumpToBlock` : visité → curseur, sinon extension — JAMAIS de
  cochage dans le SVG, JAMAIS de démarrage de session : naviguer ≠ agir) ; l'état est peint par
  classes (`flowPaintState`), la géométrie n'est plus JAMAIS reconstruite à la navigation
  (cache `_flowCache` sans état) ; toute nouvelle peinture SVG exige sa règle de
  contre-inversion sombre (précédent `.flow-hl`). L'impression force la
  vue d'ensemble (blocs repliés rouverts par CSS `@media print` ; depuis v4.18.0 la structure
  imprimée est le plan Détails — le SVG ne s'imprime plus en mode dynamique). L'aperçu
  d'éditeur reçoit un BAC À SABLE de navigation détaché
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
  colonnes de ~145 px sur téléphone rendaient la lecture difficile — avec INDENTATION
  (v4.15.0, décision utilisateur) : ~17 px par niveau + RAIL de branche 3 px (grammaire du
  plan : bleu = prise, pointillé = hors chemin), CSS pur récursif, plafonné au 4e niveau ;
  la fourche étant masquée en pile, rail + chip portent la structure ; **PAS de règle `deep`**
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
  APRÈS rendu, redessin au resize + ResizeObserver sur `.sv-tb` — qui IGNORE les
  notifications sans changement de taille)** : la passe est organisée en PHASES
  lecture/écriture GROUPÉES (v4.14.10 : l'alternance mesure/style forçait un recalcul de
  mise en page par décision, 30-50 ms par passe — désormais ~4 recalculs fixes, ~12 ms sur
  le pire cas ; discipline à CONSERVER : dans une phase de lecture, aucune écriture de
  style — les écritures de fork/gutter/hid n'invalident pas la géométrie : hauteurs fixes,
  superposition absolue, visibility) ; toute mesure est divisée
  par `zoomF()` — **le réglage de taille du texte est un zoom CSS sur `<html>` :
  `getBoundingClientRect` rend des px VISUELS (× zoom) alors que les styles/SVG posés sont en
  px CSS ; toute mesure réinjectée doit être ÷ zoom (v4.13.1, vaut aussi pour `--pl-stick`)**.
  FOURCHE ambre (`--verify-bd`) de la bande vers chaque chip d'option, CONVERGENCE grise
  (`--line-strong`) fusionnant les branches dont l'issue terminale (`svBranchIssue`, pure) est
  le bloc de reprise du tronc (pilules masquées ; brins partant du BAS RÉEL de chaque branche
  dans la superposition `.sv-gut` — jamais de segment flottant sous une colonne courte),
  RETOURS bleus (`--link`) en GOUTTIÈRE gauche (16 px, `svLoopTargets` pure : plafond
  2 voies ; ARRIVÉE HORIZONTALE v4.14.12 : la voie remonte puis ENTRE dans le bord gauche
  du bloc cible, pointe vers la droite — symétrique des départs, gouttière inchangée) ;
  ÉLARGISSEMENT des arbres imbriqués (v4.14.3-4, décision utilisateur — esprit papier QRH ;
  v4.18.2 : JAMAIS sous 640 px — au palier une-seule-colonne, la marge négative compensatoire
  décalait la décision imbriquée à gauche et ANNULAIT l'indentation v4.15.0 des niveaux
  profonds ; ≥ 640 vérifié identique au pixel avant/après) :
  une décision imbriquée s'ÉTEND dans l'espace libéré, DANS LES DEUX SENS (sur les fiches
  réelles la branche courte est souvent à GAUCHE) — critère = test de COLLISION global
  (aucun contenu extérieur au sous-arbre dans le rectangle convoité, toutes profondeurs
  d'imbrication), appliqué dans `svPaintArrows` (remise à zéro d'abord, extérieur ->
  intérieur, width + margin-left négatif) ; si la bande chevauche encore une sœur, seules
  fourche + colonnes s'élargissent ; HYBRIDE flèche + élargissement (v4.14.7, décision
  utilisateur) : chaque branche « → join » réserve une VOIE DE BORD (bord droit de sa
  colonne − 12 px, ± 8 px, de la pilule au coude), le brin y est ROUTÉ par un petit coude
  et l'élargissement s'ÉCRÊTE au plus proche obstacle de chaque côté (plus de tout-ou-rien)
  — un couloir interne au sous-arbre élargi ne bloque pas sa propre extension ; PIÈGE
  RÉSOLU : `.sv-br` est une grille — l'élément élargi recevrait sinon toute la piste et ses
  FRÈRES s'étireraient sur les colonnes voisines → marges négatives COMPENSATOIRES
  (contribution à la piste = largeur d'origine) ; garde-fou résiduel : un brin n'est
  dessiné que si sa voie est réellement libre (sinon la branche garde sa pilule) et une
  pilule masquée reste en `visibility:hidden` (espace GARDÉ : pas d'oscillation du
  ResizeObserver) ; ANCRAGES (v4.14.8-11) : la tige de fourche part du centre RÉEL de la
  bande-question, le brin gris sort du bloc par un TRONÇON vertical de 10 px puis ne fait
  le détour par la voie de bord QUE si le couloir central est obstrué (descente droite
  sinon), le brin gris du centre du DERNIER BLOC VISIBLE de sa branche
  (v4.14.9 : la rangée-pilule en visibility:hidden réserve l'espace mais n'est pas le bloc
  de départ — le brin la TRAVERSE), la flèche d'arrivée vise le centre de la cellule de
  convergence — jamais le centre d'un bandeau élargi/décalé ;
  branches empilées (étroit) → `.stacked` : fourche/convergence masquées, les pilules
  re-suffisent — la flèche n'est JAMAIS seule (aria-hidden, l'info reste textuelle). En mode
  statique : pas de panneau « Algorithme » (le tableau EST la vue d'ensemble) ;
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
  **Exception `#readTopSeg` (v4.21.0)** : la bascule Dynamique ↔ Statique est re-rendue avec la
  fiche — le glissement y est REJOUÉ après re-rendu (`.seg-replay` : pastille posée sans
  transition sur l'ancien segment, reflow, retrait) et le contenu (`.care-path`/`.ov-wrap` ou
  `.sv-wrap`) entre dans le sens du geste (keyframes `secInL/R` réutilisées, transform/opacity
  seulement = NON BLOQUANT, classes `rm-anim-l/r` retirées à `animationend`) ; sous
  `prefers-reduced-motion` tout est inerte (règles sous `no-preference` ; l'ancienne garde
  `#plPin` — fixed dans un ancêtre transformé — a disparu avec la pile synthétique en
  v4.22.1, le sticky y est insensible) ; minuteurs et chapeau
  « Ne pas oublier » n'animent jamais (ECAM : le mouvement y est réservé à l'alarme).
- **Pieds de page (v4.4.2)** : UNE source de vérité pour l'état de stockage (`storageState`,
  pure) — variante LONGUE dans la sidebar de l'accueil (+ info-bulle), variante COURTE dans le
  pied des vues de LECTURE (fiche ET protocole, `readFooterHtml`). **Vérification hors-ligne
  des documents PDF (v4.20.0, besoin SMUR — aucun réseau en intervention)** : ligne
  `#attOffline` du pied de la sidebar — ✓ vert « tous sur cet appareil (n) » (CONFIRMATION
  positive) ou △ ambre « k pas encore sur cet appareil » + « Télécharger » immédiat
  (`attMissingInfo` PURE testée — supprimés ignorés, dédoublonnage, chemins = règle de
  `_syncAttachments` ; `refreshAttOffline`/`dlMissingAtts`), rafraîchie avec `updateStorageInfo`
  et à la fin des téléchargements de fond de la synchro. Le pied de lecture ne répète
  ni le code court ni la date de validation (déjà dans la méta du haut). En session de crise,
  l'état de stockage disparaît des deux pieds (aucun signal non actionnable pendant un soin).
- **Repli de l'étape ① (doctrine, v4.4.2)** : un démarrage IMPLICITE (cochage, minuteur,
  compteur, horodatage) ne replie JAMAIS « Confirmation diagnostique » — `ensureStarted` fige
  l'état ouvert. `renderKeepAnchor` ne peut compenser le scroll que si `window.scrollY ≥ hauteur
  retirée` : sur une page courte ou en haut de fiche, replier ferait sauter le contenu sous le
  doigt (bug v4.3.2, en pire). Le repli n'appartient qu'aux gestes qui l'ACQUITTENT : le bouton
  « Confirmé — démarrer la session » et la première navigation « Continuer → ».
- **LOGO DE MARQUE (v4.23.1)** : `.brand-logo` sur l'ACCUEIL seulement (comme le nom qu'il
  accompagne, SPEC §5). Posé en **masque CSS** (`logo-glyph.svg` = le master SANS tuile, seul son
  canal alpha sert) sur un aplat de couleur — un `<img>` ne se teinte pas, or un bleu FIXE jurait
  avec les accents violet/framboise et pesait en thème sombre. Couleur = **`currentColor`, donc
  l'ENCRE** (décision utilisateur) : elle suit le thème toute seule et ne concurrence AUCUN accent
  — l'accent colore déjà la loupe, les boutons et les liens de l'accueil, une marque neutre s'y lit
  comme une marque. Variante « suit l'accent » = remplacer par `var(--primary)` (un seul mot).
  ÉCARTÉE SUR MESURE : la tuile teintée (`--primary-soft` + glyphe `--primary`) — à 34 px elle ne
  se détache pas du fond et le glyphe s'y noie. `logo-glyph.svg` est servi depuis la racine et
  entre dans `ASSETS` (sw.js) : hors ligne comme le reste ; `design/` n'est ni servi ni précaché.
- **En-têtes V5** : rangée principale unique (`.id-row` : retour ‹, marque, recherche FIXE de
  l'accueil, badge de statut, Créer, thème, compte, + `#hdrCrisis` en crise). Le sélecteur de
  section vit dans la tab bar basse (< 780) ou la colonne gauche (≥ 780), jamais dans la barre.
- **ZONE HAUTE DE CRISE (v4.23.0)** : deux éléments **hors de `header.bar`**, frères directs de
  `.app`, aux comportements délibérément opposés — `#crisisBand` (le TITRE, information
  **CONSTANTE**) vit dans le flux et s'en va au défilement, `#hdrCrisis` en prenant le relais
  dans la rangée d'identité au pixel MESURÉ où il passe sous la barre ; `#cbTimers` (l'ÉTAT
  VIVANT — minuteurs segmentés, chrono **GLOBAL** = temps écoulé depuis la 1ʳᵉ action de
  session, segment échu en ambre, « +n » en fin) est une rangée **pleine largeur COLLANTE**
  (`top:var(--hdr-h)`, hauteur d'en-tête mesurée par `syncHdrScroll` ÷ `zoomF()`) qui ne quitte
  jamais l'écran — donc **aucun chrono miniature dans la barre** (une version condensée y était
  illisible, retour d'usage). Le quai `#crisisDock` porte aussi l'accès permanent **⤢ Plan**.
  `#crisisDock` est un frère de `.app`, JAMAIS un enfant du bandeau : un élément collant ne colle
  que dans les bornes de son bloc conteneur.
  **ORDRE FIXE `⤢ Plan · ● Session · minuteurs` (ECAM — invariant à ne jamais casser)** : Plan et
  Session sont AVANT la partie variable (les minuteurs). C'est **géométrique** : un contrôle placé
  APRÈS un nombre variable de minuteurs ne peut rester immobile qu'ancré au bord (→ vide central
  qui varie) ou avec des créneaux réservés vides (→ trou) ; placé AVANT, il est immobile ET sans
  vide, les minuteurs coulant à sa droite (le blanc part au bord droit — barre d'outils normale).
  Plan est 1ᵉʳ (constant), Session 2ᵉ (constant car Plan a une largeur fixe), les minuteurs
  suivent. La règle cardinale d'une zone de statut ECAM est la CONSTANCE POSITIONNELLE : on
  apprend où regarder, l'œil y va sans lire. NE PAS remettre Plan à droite « pour la logique
  d'action » : il se remettrait à glisser (bug corrigé v4.23.0), et le vide central marronnait les
  deux extrémités (proximité Gestalt rompue — retour d'usage). L'alarme n'a pas besoin de la 1ʳᵉ
  place, elle a déjà teinte ambre + mot « échu » + flash + son. Piège CSS résolu :
  `.seg:first-child{border-left:0}` (le filet des bandes étroites) l'emportait en spécificité sur
  la carte `border:1px` ≥ 780 → la 1ʳᵉ carte paraissait coupée à gauche ; la suppression est
  bornée à `< 780 px`.
  **RÉPARTITION QUAI / RAIL** : `.dock-in` plafonne le contenu à 1282 px et le centre sur la
  grille de la vue lecture ; à partir de **780 px** les segments deviennent des CARTES détachées,
  bordées sur leurs 4 côtés (contour neutre — seule l'échue prend le registre ATTENTION : une
  bande de statut ne se colore pas) et le cluster `⤢ Plan · ● Session · minuteurs` se groupe à
  gauche, le blanc au bord droit ; **dès 780 px (`mqRail`, PAS 1000 — la doc l'a affirmé à tort
  jusqu'en v4.23.0 : le seuil suit le RAIL, descendu à 780 au lot 5)** le quai ne garde QUE Plan, le
  chrono de session et le minuteur ÉCHU — les minuteurs nominaux vivent dans le rail, les répéter ferait deux
  sources pour la même valeur. La redondance de l'ALARME à deux endroits est voulue, celle du
  nominal non. **Débordement JAMAIS silencieux (ECAM ; corrigé par l'audit du lot 7)** : le `+n`
  n'était calculé qu'en étroit — à ≥ 1000 px, trois minuteurs échus n'en montraient que deux et
  le troisième disparaissait sans un mot d'une zone d'ÉTAT. Le décompte suit désormais la liste
  réellement affichée (`pool` = les échus en large, tous les minuteurs en étroit). Que le rail
  droit les affiche en grand ne suffit pas : il DÉFILE, donc le 3ᵉ peut être sous la ligne de
  flottaison — une zone de statut annonce ce qu'elle cache, toujours. Le rail et cette réduction
  sont pilotés par LA MÊME media query (`mqRail` = `wideRead`) : les minuteurs ne peuvent donc
  jamais disparaître des deux endroits à la fois — invariant à préserver si l'un des deux bouge.
  **UNE ZONE D'ÉTAT N'AMPUTE JAMAIS UN NOMBRE (v4.23.0, retour d'usage)** : `fmtMs` ne bornait pas
  les minutes (3 h 25 s'écrivait « 205:13 » — illisible, et assez large pour être rogné) ; il passe
  en `h:mm:ss` au-delà de l'heure, `mm:ss` inchangé en dessous. Et le quai AJUSTE PAR LA MESURE :
  on écrit, et tant que ça déborde on retire un segment (il repasse dans « +n », donc annoncé),
  puis en dernier recours le CHEVRON (décoratif, `aria-hidden`) — jamais le « +n », jamais un
  chiffre. Des seuils de largeur en dur avaient été essayés et se sont révélés FAUX (320 et 430
  débordaient encore) ; la décision mesurée est mémorisée sur une clé (largeur + nombre de
  caractères, chiffres tabulaires) et n'est donc pas recalculée à chaque seconde. Le libellé du
  bouton s'abrège en « Cons. » sous 560 px — TRONCATURE du même mot, jamais un autre mot (« Réf. »
  a été retiré pour cette raison : deux noms pour un bouton, « on s'y perd ») — et le rembourrage
  des pastilles « +n »/chevron (des `<span>` DANS le bouton, jamais tapables seuls, donc non
  soumis à la règle des 44 px) est resserré : c'est ce qui rend la place d'un segment de minuteur
  à 390 et 430 px. **Piège de cascade rencontré une seconde fois** : cette media query doit être
  déclarée APRÈS la règle de base de `.cbt-n` — placée avant, à spécificité égale, elle était
  silencieusement sans effet.
  **Pourquoi hors de l'en-tête** : un en-tête qui se replie raccourcit son propre encombrement
  de flux et fait remonter tout le contenu d'un coup. Ici la hauteur d'en-tête est CONSTANTE —
  zéro saut, zéro compensation de scroll, rien à inhiber sous `prefers-reduced-motion` (le seul
  mouvement est le geste de défilement : même doctrine que le fil d'ancêtres collant v4.22.1).
  Corollaire : toute couche collante ajoutée en haut doit entrer dans la base d'épinglage
  d'`ovPlanPin` (`max` des bas de l'en-tête et de `#cbTimers`), sinon les cartes-questions du
  plan passent dessous.
  **BANDEAU BLANC** (décision utilisateur, ECAM) : un bandeau d'état **permanent** teinté en
  rouge désensibilise au rouge — la couleur est réservée aux alertes RÉELLES (minuteur échu en
  ambre, étapes critiques en rouge). Le statut s'annonce en TEXTE : « ■ Mode crise » (glyphe +
  libellé + encre `--critical`), jamais un aplat. Ne pas « corriger » en re-teintant le fond.
- **RAIL DE LECTURE dès 780 px (v4.23.0, décision utilisateur « action + structure de front »)** :
  la largeur suffit à tenir la colonne d'ACTION et le rail d'ORIENTATION côte à côte — l'idéal
  ECAM (E/WD et SD simultanés). Contenu, de haut en bas : **minuteurs ÉPINGLÉS** → **Plan
  « Échelle »** (seule partie qui peut être longue, donc la seule qui défile ; `⤢ complet` ouvre
  la feuille Plan) → **repères posologiques** (déjà classés pour le bloc courant).
  **UNE COLONNE ENTIÈREMENT CONTINUE — AUCUN SOUS-DÉFILEUR** (v4.23.0, trois retours d'usage).
  Étape 1 — un défileur unique : une Échelle longue ou des minuteurs nombreux repoussaient la
  posologie tout en bas. Étape 2 — trois zones bornées défilant chacune sur elle-même : la
  posologie n'était plus repoussée, mais chaque section devenait un HUBLOT (minuteurs à 132 px
  pour 1559 px de contenu) et on perdait la vue d'ensemble. Étape 3 — une seule section bornée
  (les minuteurs) : **le compteur et le bouton « ＋ Minuteur PA » ont DISPARU de l'écran** —
  327 px affichés pour 413 px de contenu, et la barre de défilement étant invisible au repos
  (macOS/iOS), rien ne signalait la troncature.
  **LEÇON À NE PAS REPERDRE : dans une colonne déjà défilante, un sous-conteneur borné ne « range »
  pas, il ESCAMOTE.** Le rail est donc une colonne entièrement continue, et le seul dispositif
  retenu contre l'enterrement de la posologie est l'**ORDRE** : minuteurs → posologie → Échelle →
  horodatage, c'est-à-dire **ce qui est de longueur ILLIMITÉE en DERNIER**. Avec beaucoup de
  minuteurs on défile le rail — c'est normal, et la posologie reste par ailleurs joignable sans
  défilement par la feuille Consulter (`▸ Réf.` du quai). Ne jamais réintroduire de `max-height` +
  `overflow` sur une section du rail.
  **ANNONCE DU TOTAL (`.rail-n`) — exigence ECAM** : chaque en-tête de zone porte le nombre total
  d'éléments. Les barres de défilement sont invisibles au repos (macOS/iOS) : sans ce compte, une
  zone tronquée **paraît complète**, ce que l'ECAM interdit (il signale toujours son débordement).
  Même vocabulaire que « +n » du quai et « n autres repères ». Ne pas retirer ces comptes.
  Vérifié à 6 minuteurs + 8 repères, de 900 px à 560 px de haut et jusqu'au réglage de texte le
  plus grand : 1ʳᵉ carte de posologie entièrement lisible partout, aucun contenu perdu, focus
  atteignable en fin de chaque zone. Largeurs **300 / 320 (≥ 1000) / 360
  (≥ 1200)** ; la checklist reste plafonnée à **860 px** — la règle de largeurs n'est pas amendée,
  le rail prend l'espace EXCÉDENTAIRE.
  **DEUX SEUILS DISTINCTS, à ne pas refusionner** : `mqRail` (780) = rail de LECTURE ; `mqReadWide`
  (1000) = aperçu en direct des ÉDITEURS (règle v4.5 inchangée). Ils partageaient la même règle
  `.read-grid`, d'où la scission par classe de vue. **Piège de cascade rencontré** : la règle du
  palier 1200 est déclarée en tête de fichier (§ LARGEURS) et perdait contre le bloc 1000 ajouté
  plus bas à spécificité égale — elle est RÉAFFIRMÉE après ; toute nouvelle règle `.read-grid`
  doit vérifier cet ordre.
  **REGISTRE D'UN REPÈRE POSOLOGIQUE = AMBRE, JAMAIS ROUGE (v4.23.0, décision utilisateur)** :
  la doctrine v4.2.2 range explicitement « dose/dilution à vérifier » dans le registre VIGILANCE
  (`△`, là où l'on risque de SE TROMPER) et réserve le rouge à ce qui TUE SI ON L'OUBLIE (memory
  item, geste vital). L'app se contredisait : elle offrait « ⚠ = carte au registre ALERTE » sur
  les repères. Résultat constaté à l'écran — trois masses rouges d'égale valeur (chapeau + deux
  repères) : **inflation du rouge**, les memory items perdaient leur prééminence. C'est aussi la
  règle ECAM : une valeur hors limites est une CAUTION ambre, un WARNING rouge appelle une action
  immédiate. Une dose est une RÉFÉRENCE, pas une action.
  Donc : `.pos-card.vig` (ambre) remplace `.pos-card.crit` ; la bascule de l'éditeur écrit `△` et
  n'offre plus `⚠` ; l'amorce IA l'impose aussi. **Compatibilité ascendante** : un `⚠` hérité
  d'une fiche antérieure reste LU comme un signalement et s'affiche en ambre — rien n'est perdu,
  aucune migration de données. **Une seule masse rouge par écran** (le chapeau « Ne pas oublier » ;
  les étapes vitales du journal en sont l'autre, mais ce sont des GESTES).
  **REPÈRES DU RAIL — chrome désaturé, registre CONSERVÉ** : doctrine ECAM appliquée finement — on
  calme la PRÉSENTATION, jamais la sémantique d'une donnée anormale. Les repères ordinaires sont
  des LIGNES (ni cadre, ni fond, nom en `--ink` et non en bleu : le bleu est l'accent d'ACTION, il
  n'a rien à faire dans une colonne qui oriente) ; un repère **`⚠` garde sa carte teintée et son
  encre rouge** — une erreur de dilution tue, c'est une alerte sur la donnée. Le contraste entre
  les deux devient ainsi porteur de sens au lieu d'être uniforme, et des lignes tiennent bien moins
  de place que des cartes (85 px → 58 px, mesuré). **La DOSE reste en encre pleine** : la hiérarchie
  avec le nom passe par la GRAISSE, jamais par l'encre — adoucir un dosage serait l'inversion à ne
  pas faire (erreur commise puis corrigée en v4.23.0).
  **ÉCHELLE DÉSATURÉE (`.rail-lad`)** : le rail oriente, la colonne agit. S'il reprenait les
  aplats bleus/verts/ambre de l'action, deux surfaces se disputeraient le regard au même niveau de
  saillance. L'état n'y est plus porté que par le **marqueur** (✓ vert, ● bleu, ⑂ ambre) —
  l'information reste intégralement, seule la compétition disparaît. Le « hors chemin » n'y est
  **pas** en `opacity` (un texte à 50 % tombe sous AA) mais en encre douce + la **mention en
  toutes lettres**. Lignes à 44 px (cible de navigation). Même `flowPlan`, même numérotation
  commune, même `minimapData` : aucune seconde source de vérité.
  `--stick-top` (posée par `syncHdrScroll`) = bas de tout ce qui est déjà collé en haut (en-tête +
  quai) : le rail s'y accroche, sinon il passerait sous le quai.
- **ANCRAGE ET DÉFILEMENT (v4.23.0, deux bogues corrigés — retour d'usage « le scroll n'est pas
  bon du tout »)** : `stickBase()` est la **source UNIQUE** du « bas de ce qui est collé en haut »
  (en-tête + `#crisisDock`) — consommée par `ovScrollEl`, `syncHdrScroll` (`--stick-top`) et
  `ovPlanPin`. `ovScrollEl` ne comptait que la hauteur de l'en-tête : depuis le quai, tout saut
  déposait le bloc visé ~52 px **sous** le quai, donc masqué. Toute nouvelle couche collante en
  haut doit entrer dans `stickBase()`, nulle part ailleurs.
  **`scrollWithin(box,el)` remplace `scrollIntoView` pour toute navigation INTERNE à un panneau**
  (renvois du rail et de la feuille Plan, ciblage de section de la feuille Consulter) :
  `scrollIntoView` remonte TOUS les ancêtres défilables — mesuré, un renvoi tapé dans le rail
  déplaçait la PAGE de 261 px pendant que la zone du rail ne bougeait pas. `scrollWithin` n'écrit
  que le `scrollTop` du conteneur visé.
- **FEUILLE « CONSULTER » (v4.23.0, `#refModal`)** : la couche de CONSULTATION quitte la colonne
  d'action — différentiels, schémas, documents, références, voir aussi. Accès en **PULL** : rangée
  `#annexRow` en fin d'action, bouton `▸ Réf.` du quai, menu ⋯ ; **jamais d'ouverture automatique**
  (seule l'alarme pousse). **PAS de copie du chapeau « Ne pas oublier »** (décision utilisateur,
  v4.23.0) : il est déjà en tête de fiche, entier et jamais replié ; un pavé rouge rouvert à chaque
  consultation repoussait ce qu'on vient réellement y chercher (une dose, un différentiel) sans
  rien apporter. Feuille plein écran `.sheet-full` (mêmes garanties que le Plan : verrou
  de fond tous pointeurs, focus, Échap, retour au pixel) ; elle vit HORS de `main`, donc survit aux
  re-rendus — d'où le re-câblage local de `[data-att]`/`[data-openrel]`/`img[data-full]` dans
  `renderRefSheet`.
  **CE QUI NE PART JAMAIS (AC 120-71B)** : le chapeau « Ne pas oublier », « △ À vérifier » (③) et
  les **repères posologiques** restent DANS LE FLUX — la feuille n'en porte qu'une COPIE (même
  source, aucune divergence possible). Critère : ce qui se consulte PENDANT un geste reste à côté
  du geste ; ce qui se consulte ENTRE deux gestes part dans la feuille. La NOTE personnelle reste
  aussi dans le flux : seul bloc à état éditable (son bouton re-rend la vue et restaure le
  défilement — logique de flux). Le lien « Tableau atypique ? » de l'étape ① **doit** atterrir
  directement sur les différentiels dépliés (`openRefSheet('diff')`) : sans ce ciblage on
  remplacerait un accès direct par une chasse au trésor.
- **REPÈRES POSOLOGIQUES — rapprochement du bloc courant (v4.23.0)** : `posoRank`/`posoSplit`
  **RÉORDONNENT, ne FILTRENT JAMAIS**. C'est cette garantie qui autorise un rapprochement
  volontairement permissif — troncature (« Adré » trouve « Adrénaline », préfixe ≥ 4 caractères) et
  table des voies dans les deux sens (« IM » ↔ « intramusculaire », `POSO_SYN`/`POSO_PHRASE`). Un
  faux positif coûte un rang, un faux négatif un défilement, **jamais une dose manquante** — un
  filtre silencieux ferait disparaître un repère à l'instant où on le cherche. Liste > 3 : le reste
  se replie derrière un `<details>` qui **annonce son nombre** (un pli muet serait un filtre
  déguisé) ; un repère **SIGNALÉ n'est JAMAIS replié — `⚠` ET `△`** (piège trouvé par l'audit du
  lot 7 : `crit` ne testait que `stepIsCrit`, or la doctrine v4.23.0 réserve `⚠` aux ACTIONS et
  marque la posologie en `△` ; la protection ne couvrait donc plus RIEN, et une dilution à
  vérifier — motif même du registre — pouvait se replier) ; sans rapprochement l'ordre de
  l'auteur est conservé. Source unique `posoCardsHtml` partagée par le flux et la feuille. **Menu ⋯ (v4.5)** : en lecture, toutes les actions
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
  de la barre). **Corrigés par l'audit v4.23.0** — des écarts ANCIENS, que le rail a mis sous
  les yeux : `.tm-label` 10,5 → 11 px ; `.cn-btn` 38 → 44 ; `.tm-reset` 36 → 44 (il ÉCRASAIT le
  `min-height:44px` de `.cn-reset` — un override plus tardif suffit à annuler une règle de
  sûreté, sans que rien ne le signale) ; `.rt-add` 38 → 44 ; `.tk-add` → 44 ; `.pl-nd` 41 → 44 ;
  `.pl-lnk` 32 → 44 ; `.rail-exp` 40 → 44. **Règle de token qui se laisse oublier** :
  `--line-strong` et `--soft` visent 3:1 (BORDURES) — en couleur de TEXTE ils échouent à 4,5:1
  (`.annex-row .ax-ch` mesuré à 3,93:1) ; et en SOMBRE `--primary` est un remplissage (3,75:1 en
  texte), l'accent TEXTE est `--link` (= `--primary-dk`), seul admis pour un numéro ou un
  libellé accentué.
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
  **Carte-bilan de fin de session (v4.16.3, décision utilisateur)** : après « Terminer »,
  l'accueil affiche une carte ÉPHÉMÈRE au registre CONFIRMATION (`.last-sess`,
  `lastEndedSession` en mémoire seulement — jamais persisté, la vérité archivée est la
  session) : titre · durée · k/n blocs ✓ + bouton « Compte-rendu » (`exportSessionReport`) ;
  disparaît d'un tap (✕) ou au démarrage de la session suivante. **Le ✕ doit rester DANS LE FLUX**
  (`.last-sess .notice-x{position:static}`) : `.notice-x` est `position:absolute` et la carte n'est
  pas `position:relative` — le ✕ se calait donc sur un ancêtre lointain et était INVISIBLE de
  v4.16.3 à v4.23.2. **La carte disparaît aussi quand SA session est supprimée de l'historique** :
  garde posée AU RENDU (`!sessions.some(...)`), pas dans chaque chemin de suppression — il y en a
  trois (session seule, suppression de fiche, purge) et un quatrième serait oublié ; sans elle, le
  bouton « Compte-rendu » menait à un rapport introuvable — le débriefing est
  DISPONIBLE, jamais imposé (ECAM).
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
- **Collision de noms de classe (leçon v4.23.2)** : `.tk-panel.empty` réutilisait la classe
  GÉNÉRIQUE `.empty` (états vides « Aucune fiche », « Protocole vide ») et en héritait deux styles
  invisibles à la relecture — `.empty b{display:block;margin-bottom:6px}`, qui décentrait le titre
  « Journal des actions » de 3 px (car `align-items:center` centre la boîte de MARGE), et
  `html[data-theme="dark"] .empty{background:…}` qui, de spécificité SUPÉRIEURE à `.tk-panel`,
  écrasait le fond du panneau en thème sombre. Un modificateur d'état ne doit JAMAIS emprunter le
  nom d'une classe autonome : préfixer par le composant (`.tk-slim`, pas `.empty`).
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
| Visionneuse PDF | `pdfLib` (chargement paresseux de `vendor/pdfjs`), `openPdfViewer` (rendu virtualisé par IntersectionObserver ; zoom d'OUVERTURE = « page entière » calculé d'après le ratio du document et la fenêtre, `pdfFitPageZ`, bornes 25–400 %, boutons « Page »/« Largeur », bouton ⤓ Télécharger v4.19.0 : relecture FRAÎCHE du binaire en IndexedDB via `attDlName` — JAMAIS le buffer déjà passé à pdf.js, `getDocument` le TRANSFÈRE à son worker et le laisse détaché, un blob resservi serait vide ; en PWA INSTALLÉE le téléchargement passe par la FEUILLE DE PARTAGE native — v4.19.1, `dlBlob` : en standalone, WebKit ignore `download` et NAVIGUE vers l'URL blob:, plein écran sans retour), fenêtre `#pdfModal` ; miniatures de la 1ʳᵉ page dans les listes « Documents » (`attThumbHtml`/`genAttThumb` : paresseuses, une à la fois, cache mémoire de session — jamais de chargement de pdf.js au démarrage) ; badge « △ à télécharger » si le binaire n'est pas encore sur l'appareil (`hydrateAttThumbs`/`refreshAttRow` — état décidé sur la lecture IndexedDB, rafraîchi en direct par le téléchargement de fond de la synchro) |
| Mini-Markdown | `mdBlocks`/`mdInline`/`mdRender`/`mdStrip`/`mdCells`/`mdCallout`/`mdTask` : parseur maison XSS-safe (esc() d'abord) du contenu rédigé des protocoles — titres, listes, citation, code, image, TABLEAUX (v4.4.2), ENCADRÉS TYPÉS et `==surligné==` (v4.4.3), LISTES COCHABLES `- [ ]` (v4.5.4). Registre et alignement viennent toujours d'un jeu FERMÉ posé en CLASSE, jamais d'un attribut piloté par l'utilisateur |
| Protocoles | `blankProtocol`/`migrateProtocol` (point d'entrée sécurité/compat), `renderProtocols`/`renderProtocolRead`/`renderProtocolEdit`, sélecteur de section dans l'en-tête (`#hdrSec` statique, `state.section`) |
| Export / Import | JSON `version: 3` + conteneur `.zip` « avec documents » (`zipBuild`/`zipParse` maison, `importAtts`) ; règles de rétrocompatibilité documentées sur place |
| Compte & synchro | `Auth` (OTP e-mail), `Sync` (pull/push local-first), fenêtres associées |
| Accessibilité | gestion centralisée des modales (focus, Échap, Tab ; v4.21.0 : verrou du défilement de fond `_bgLock`/`_bgUnlock` — `body.modal-open` figé en place au toucher + `overscroll-behavior:contain` sur `.ai-modal`, position restaurée au pixel à la dernière fermeture). **v4.23.0** : une fenêtre marquée `.sheet-full` (OPAQUE et plein écran, ex. feuille Plan) verrouille le fond à **TOUS les pointeurs** (`body.modal-full`) — la restriction au toucher n'existe que parce que figer `body` au pointeur fin décale le fond visible AUTOUR d'un petit dialogue ; une feuille opaque ne laisse rien voir du fond, et sans verrou la page continue de défiler derrière (constaté sur ordinateur) |
| Mode test | hook `?__actest` : expose les fonctions pures pour `tests.html` |
