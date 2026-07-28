# Instructions projet — Aides cognitives

> Fichier d'instructions **canonique**, destiné à tout contributeur, humain ou IA
> (Claude, Codex, Cursor, Gemini…). `CLAUDE.md` ne fait que l'importer.

PWA médicale **monofichier** (`index.html`), JavaScript vanille, **aucune dépendance runtime**.
Stockage local-first (IndexedDB) ; synchro cloud Supabase optionnelle (RLS). Utilisée en urgence
vitale, sous stress : clarté et robustesse priment.

> **Exception UNIQUE à la règle zéro-dépendance : pdf.js** (visionneuse des documents PDF).
> Vendorisé dans `vendor/pdfjs/` (version figée, notée dans `vendor/pdfjs/README.txt`), chargé
> **paresseusement** (`import()` au premier document ouvert — jamais au démarrage), **précaché
> par `sw.js`** (hors ligne dès l'installation).
> **LA VIGNETTE D'UN DOCUMENT COMPTE COMME UNE OUVERTURE** et suit donc la même règle (v4.36.0) :
> `bindAttList` appelait `hydrateAttThumbs` inconditionnellement, si bien qu'ouvrir une FICHE
> portant un PDF chargeait 1 773 Ko de pdf.js — pour 0 rangée à l'écran, les documents ayant
> déménagé dans la feuille « Consulter » en v4.23.0. Ne générer une vignette que si une rangée est
> réellement dans le flux : `if(main.querySelector('[data-thumb]'))`. Mettre à jour pdf.js = décision explicite +
> test hors-ligne complet (mode avion, PDF 50+ pages, iPhone). **Aucune autre dépendance runtime
> n'est autorisée** ; tout nouveau fichier servi doit être ajouté à `ASSETS` (`sw.js`).

## Si vous ne lisez qu'une chose

Quinze règles qui ne se négocient pas. Le reste de ce fichier les explique et les étend ; **aucune
ne s'apprend en lisant le code** — elles viennent d'incidents mesurés, et plusieurs ont déjà été
« corrigées » par erreur faute d'être lues.

1. **Publier** = `./release.sh X.Y.Z`, puis rédiger le `CHANGELOG`, puis committer avec de vraies
   notes et taguer. Ne JAMAIS éditer les numéros de version à la main (un décalage entre
   `APP_VERSION` et `CACHE` casse la mise à jour du service worker). **Jamais de `git push` sans
   demande explicite.**
2. **Avant chaque commit** : `npm run check` (syntaxe · couleurs · classes émises · animations ·
   service worker · SQL · hashs CSP) et
   `npm test` (Chromium **et** WebKit). Si le CSS a changé : `npm run design:build`.
3. **Toute édition du script inline exige `node scripts/csp-hashes.mjs`.** Sans cela, la CSP par
   hashs bloque le seul script de l'application et **elle ne démarre plus**. Le piège s'est produit
   trois fois ; `npm run check` le détecte désormais.
4. **`esc()` sur toute donnée affichée.** C'est la SEULE barrière anti-XSS (la CSP monofichier
   impose `'unsafe-inline'` pour les styles). Ne jamais interpoler une valeur externe brute dans un
   attribut ou un `style=` : couleur → `safeColor()`, image → `safeImg()`, identifiant → `esc()`.
   Depuis v4.44.0 elle échappe aussi **l'apostrophe** (`&#39;`) : elle ne pouvait pas rester
   suspendue à l'invariant non vérifié « aucun attribut n'est délimité par une apostrophe ». Le
   **backtick reste intact**, et c'est une décision mesurée, pas un oubli — l'échapper tuait le
   code en ligne du mini-Markdown (`mdInline` échappe d'abord, reconnaît ensuite : 3 tests rouges)
   pour zéro sûreté, le backtick n'étant pas un métacaractère HTML.
5. **Toute donnée entrante passe par `migrate()` / `sanitizeCats()`** — chargement, import, ZIP,
   duplication ET pull cloud. N'ajoutez jamais un chemin qui contourne ces points d'entrée.
6. **Tout identifiant servant de CLÉ d'objet passe par `safeId()`** (`__proto__` banni) et les
   tables temporaires par `Object.create(null)` : sinon, pollution de prototype.
7. **Aucune couleur littérale hors déclaration de token** (`--…`). Vérifié par
   `scripts/check-colors.mjs`.
8. **Les registres ne se mélangent pas** : `--critical` rouge = ce qui TUE si on l'oublie ;
   `--verify` ambre = là où l'on risque de SE TROMPER (dose, dilution, seuil) ; `--ok` vert =
   confirmation. Une couleur n'est JAMAIS seule : toujours un glyphe et un mot.
9. **Plancher typographique 11 px, partout.** Cibles tactiles ≥ 44 px dans le mode crise (halo
   `::after` admis pour ne pas épaissir la zone haute), ≥ 32 px ailleurs. Champs ≥ 16 px sur écran
   tactile (sous 16 px, Safari iOS zoome au focus et les taps se perdent).
10. **Toute hauteur relative à la fenêtre s'écrit `calc(100dvh / var(--zf,1))`.** Le réglage de
    taille du texte est un `zoom` sur `<html>` : un `vh` nu se fait agrandir par lui et le bas de
    l'écran devient inatteignable. Idem pour toute mesure JS réinjectée : diviser par `zoomF()`.
11. **Le mode crise n'est jamais interrompu** : aucune modale, aucune synchro intrusive, aucun
    défilement automatique, aucune notification flottante. Une alarme s'annonce sur place.
12. **Ne jamais supprimer un champ du modèle** fiche / catégorie / protocole : un export v3 doit
    rester lisible par un client antérieur.
13. **Aucune dépendance runtime**, à l'unique exception de pdf.js vendorisé (chargé paresseusement,
    précaché). Tout fichier servi doit entrer dans `ASSETS` (`sw.js`).
14. **Une suppression de composant se VÉRIFIE au grep** (zéro émission hors CSS) et emporte son CSS,
    ses commentaires et la doc qui le cite. Une purge à moitié faite est pire qu'aucune purge : la
    doctrine affirme alors un nettoyage qui n'a pas eu lieu — c'est arrivé en v4.25.0, et le CSS
    d'une classe encore ÉMISE (`.pl-stp`) est parti avec, faisant disparaître le registre ⚠ d'une
    étape vitale pendant six versions.
15. **Le partage de session est un miroir ADDITIF, jamais une dépendance.** Aucun chemin
    d'interface n'attend jamais un appel réseau du partage — ni au tap, ni au rendu, ni à la fin de
    session ; couper le réseau ne doit changer, chez l'hôte, **qu'un mot dans le quai d'état**. Et
    **aucun texte libre ne traverse le réseau** : ce n'est pas un filtrage mais une propriété du
    format transmis (`shareSnap`/`shareDiff` ne portent que des références et des heures — le
    libellé d'un repère reste sur l'appareil qui l'a écrit). Une seule chaîne saisie voyage, et ce
    n'est pas un texte libre dans l'application : le **rôle** du participant, choisi dans un
    `<select>` de neuf intitulés — le serveur le borne à 24 caractères sans imposer la liste, donc
    ne jamais transformer ce `<select>` en champ. Les deux moitiés de cette règle sont
    la promesse faite aux utilisateurs dans la notice de l'écran d'entrée et au registre RGPD
    (`docs/deploiement-et-conformite.md` § 3.1) : les changer, c'est changer un document opposable.

## Où trouver quoi

Ce fichier est dense à dessein — chaque règle porte la trace de ce qui l'a motivée. Les intitulés
en gras de « Conventions de code » sont ses vraies entrées ; voici la carte, par sujet :

| Sujet | Chercher les intitulés |
|---|---|
| **Couleur, registres, accents** | Design tokens · Taxonomie des notices · Couleur dans le contenu rédigé · Saillance & registres · Couleur d'accent · Code couleur des catégories |
| **Étapes, statuts, contenu clinique** | Statuts, code, étapes critiques · Liseré gauche 4 px · Taille des images · Listes cochables · Marqueur d'étape hors du champ · Liens « Voir aussi » |
| **Mode crise — parcours et vues** | Parcours de soin · Journal de parcours · Plan de l'aide · PLAN = UNE SEULE VUE · Mode statique · Challenge-response · COMPLICATIONS · MODE EXERCICE · Alarme de minuteur · Dialogue « Terminer la session ? » · PORTÉE D'UNE ACTION DE REPRISE |
| **Chrome, navigation, géométrie** | ON ANIME LA COMPOSITION · En-têtes V5 · ZONE HAUTE DE CRISE · DEUX RANGÉES COLLANTES · RAIL DE LECTURE · ANCRAGE ET DÉFILEMENT · DÉFILEMENT PRÉSERVÉ · HAUTEURS RELATIVES À LA FENÊTRE · Largeurs & échelles fermées · PILE DE RETOUR · RETOUR SYSTÈME · Sélecteur segmenté · Repli de l'étape ① · LOGO DE MARQUE · Pieds de page · Indicateur de mode des éditeurs · Interactif |
| **Accueil (bibliothèques)** | ACCUEIL « POSTE ACCÈS DIRECT » |
| **Consultation et références** | FEUILLE « CONSULTER » · FEUILLE CONSULTER = UN DOCUMENT · REPÈRES POSOLOGIQUES · SORTIE PDF UNIFIÉE |
| **Données, stockage, sécurité** | Documents PDF · Export/import « avec documents » · Nommage SQL · (et les points 4 à 6 ci-dessus) |
| **Partage de session en direct** | PARTAGE DE SESSION · CE QUI VOYAGE · RÔLES ET CAPACITÉS · L'INVITÉ NE DÉPOSE RIEN · CONTINUER SEUL · TROIS RÉGIMES D'APPLICATION · JOURNAL RÉFÉRENTIEL · BILLET DE REPRISE · PASSATION DE LA MAIN · HISTORIQUE DE SESSIONS SYNCHRONISÉ |
| **Leçons de maintenance** | Collision de noms de classe · Hygiène de suppression |

Les deux autres sections : **Périmètre réglementaire** (statut non-dispositif-médical — à consulter
AVANT toute fonctionnalité produisant une sortie individualisée) et **Se repérer dans `index.html`**
(carte du monofichier, avec la commande qui en donne l'index exact).

## Règle de publication (IMPÉRATIF)
Publier une version = trois étapes, dans cet ordre :

1. `./release.sh X.Y.Z` — synchronise `APP_VERSION` (`index.html`) et `CACHE` (`sw.js`), ébauche
   l'entrée `CHANGELOG.md`, vérifie syntaxe et tests. **Ne jamais éditer ces numéros à la main**
   (un décalage casse la mise à jour du service worker). Le script **ne committe pas**.
2. Rédiger l'entrée `CHANGELOG.md` (contenu réel, pas de « à compléter » laissé en place).
3. Committer avec de **vraies notes de version** — format des messages du dépôt :
   `vX.Y.Z : <résumé en français des changements>` — puis taguer `vX.Y.Z`.

Les étapes 2 et 3 sont le travail de l'IA (ou de l'humain), jamais du script.
**Le CHANGELOG garde les 20 dernières versions** ; au-delà, déplacer les plus anciennes
dans `CHANGELOG-archive.md` — telles quelles, sans réécriture. La règle existait et n'avait servi
qu'une fois en 112 entrées : le fichier pesait alors 221 Ko, la moitié de toute la documentation.
Versionnage sémantique : correctif → patch (Z), nouvelle fonctionnalité → mineure (Y).
Ne jamais pousser (`git push`) sans demande explicite de l'utilisateur.

## Avant chaque commit
- `npm run check` — trois garde-fous sans dépendance : **syntaxe** des scripts inline (attrape les
  templates mal fermés), **couleurs** (`check-colors.mjs`, cf. Conventions), et **fraîcheur des
  hashs CSP** (`csp-hashes.mjs --check`). Ce dernier existe parce que le piège s'est produit trois
  fois : on édite le script inline, on oublie de rejouer `node scripts/csp-hashes.mjs`, et la CSP
  bloque le SEUL script de l'app — elle ne démarre plus, et le symptôme (page blanche, ou
  « `__ac_test__` introuvable » côté tests) ne désigne pas sa cause. Le même contrôle refuse tout
  attribut `on*=` dans `index.html` : sous une CSP à hashs, `'unsafe-inline'` est ignoré et un
  gestionnaire inline est du code MORT et silencieux (c'est arrivé au bouton « Recharger » de
  l'écran d'échec de démarrage, seul recours d'une app installée).
  `check-anim.mjs` (v4.41.0) complète la série : **aucune propriété de MISE EN PAGE dans un
  `transition` ni dans un `@keyframes`** (cf. « ON ANIME LA COMPOSITION » dans Conventions). Les
  propriétés de PEINTURE seule (couleurs, ombres, contours) ne sont pas concernées — elles
  repeignent, elles ne remettent pas en page. UNE exemption, motivée dans le fichier :
  `.skiplink` (glissement de 120 ms, une fois par focus — pas une animation continue, et le
  convertir mettrait en jeu une position dépendant d'`env(safe-area-inset-top)`, soit un risque
  d'accessibilité pour un gain nul). Le contrôle a été vérifié CAPABLE D'ÉCHOUER (défaut
  réintroduit puis fichier restauré à l'octet) : un garde-fou qui ne peut pas échouer ne prouve
  rien — leçon v4.31.1.
  `check-sw.mjs` (v4.44.0) ferme le trou le plus gênant du dispositif : **la fonction dont tout
  dépend en intervention — exister hors ligne — était la seule que rien ne mesurait**, aucun des
  onze harnais ne regardant `sw.js` ni le manifeste (trois des défauts les plus graves de l'audit
  vivaient là et n'ont été trouvés qu'à la lecture). Quatre contrôles STATIQUES, donc instantanés,
  donc jouables à chaque commit : (1) toute entrée d'`ASSETS`/`CORE_ASSETS`/`PDFJS_ASSETS` existe
  sur le disque — une entrée fantôme dans `CORE_ASSETS` fait échouer `addAll`, qui est
  tout-ou-rien, et supprime le hors-ligne ENTIER ; (2) `CORE_ASSETS` ⊆ `ASSETS` ; (3) tout fichier
  servable de la RACINE est dans `ASSETS` — la règle 13 ne s'auto-exécutait pas (les fichiers en
  point sont exclus : ce sont les sondes gitignorées) ; (4) `CACHE` aligné sur `APP_VERSION`,
  c'est-à-dire la règle 1. Le comportement DYNAMIQUE (install, fetch, hors-ligne réel) reste hors
  de portée : il demande un navigateur et deux précautions documentées — désinscrire le worker et
  purger les caches entre exécutions (piège v4.30.0), sans quoi on teste la version précachée.
- `npm test` — exécute `tests.html` en headless sur **DEUX moteurs, Chromium ET WebKit** (v4.34.0 :
  iOS Safari est la cible principale et n'était jamais testé — toute la suite tournait sur Blink
  seul, alors que le dossier « bande basse iOS » a montré qu'un comportement WebKit peut couper
  l'écran sans qu'aucune mesure ne le voie). WebKit manquant = AVERTISSEMENT, pas échec
  (`npx playwright install webkit`). À défaut de npm, ouvrir `tests.html` **servi en http**
  (pas en `file://` : les iframes cross-origin y sont bloquées).
- **Si le CSS d'`index.html` a changé** : `npm run design:build` régénère `design/ds/` (source
  de vérité = le monofichier) — puis committer la régénération. `npm run design:check` échoue si
  `design/ds/` a dérivé du code (le CI le rejoue ; `release.sh` régénère automatiquement). Pousser
  le résultat vers le projet Claude Design distant reste un geste explicite (skill `/design-sync`).
- `npm run audit` — **audit transverse (v4.23.0 ; SOCLE COMMUN + MOTEUR CHOISISSABLE v4.45.0)**.
  Les harnais partagent `scripts/harness.mjs` (serveur statique, table MIME, choix du
  moteur) : ils recopiaient le même bloc, et la DIVERGENCE avait déjà commencé —
  `audit-lecteur.mjs` était le seul dont la table MIME omettait `.ico`. Surtout, les onze d'alors
  lançaient `chromium.launch()` EN DUR : **iOS Safari, la cible principale déclarée, n'était
  auditée par AUCUN harnais**, alors que `npm test` tourne sur deux moteurs depuis v4.34.0. Le
  moteur se choisit désormais par `AC_ENGINE` (`chromium` par défaut, donc rien ne change sans
  décision ; un nom inconnu échoue bruyamment plutôt que de retomber en silence sur chromium) :
  `AC_ENGINE=webkit npm run audit`.
  **Le premier passage sur WebKit a immédiatement payé** : la sonde WCAG 2.4.11 signalait 8
  masquages sur 11 cibles, tous avec un bas NÉGATIF — les éléments n'étaient pas encore revenus
  à l'écran. Sur WebKit, le défilement induit par un focus PROGRAMMATIQUE est **asynchrone** ;
  la sonde lisait la géométrie d'avant et mesurait la synchronicité du moteur, pas
  l'application. Avec 60 ms d'attente : 0 sur les deux moteurs, à sélecteur et scénario
  identiques (variable isolée). RÈGLE : toute sonde qui lit une géométrie après `focus()` doit
  attendre. Il ne s'agissait donc pas d'un défaut d'accessibilité — mais on ne pouvait pas le
  savoir tant que les harnais ne tournaient que sur Blink., à rejouer dès qu'on touche au chrome de crise,
  au rail, aux feuilles Plan/Consulter ou à un token de couleur. **QUATORZE** harnais Playwright qui
  MESURENT au lieu d'affirmer (liste exacte dans `package.json`, script `audit` : a11y, doctrine,
  verify, session-card, zoom-scroll, verify-live, modeseg, consulter, complications, exercice,
  lecteur, qr, partage, **historique**). Ils tournent en CI en mode **NON BLOQUANT** (`continue-on-error`) : visibles à chaque
  push, mais un échec y demande un arbitrage humain, pas un blocage de merge. Les trois plus
  anciens, en détail :
  - `scripts/audit-a11y.mjs` — **25 surfaces × 2 thèmes, dont les 21 `.ai-modal` du monofichier
    et l'écran d'entrée de l'invité** (v4.40.0) : plancher typographique 11 px, contraste
    calculé sur le fond EFFECTIF (remontée des ancêtres + composition alpha, exemption « grand
    texte »), cibles (44 px en crise, 24 px ailleurs, halo `::after` compté), `--soft` en couleur
    de texte, « hors chemin » signalé par la seule opacité, et **focus visible sous de VRAIES
    touches Tab** — un `.focus()` programmatique ne déclenche pas `:focus-visible` et produisait
    des faux positifs en série. L'anneau est cherché sur l'élément ET ses ancêtres (motif
    `.card:has(.card-open:focus-visible)` : le bouton pose `outline:none`, la CARTE porte
    l'anneau, 3 niveaux plus haut) — mais sur un ancêtre on n'accepte QUE l'outline, son
    `box-shadow` étant en général une élévation permanente qui masquerait un vrai défaut.
    **UNE SONDE OUVRE PAR LE VRAI POINT D'ENTRÉE, ELLE NE RECONSTRUIT JAMAIS L'ÉTAT (v4.40.0)** :
    ni `classList.add('on')` sur une fenêtre (elle serait vide — rien à mesurer, verdicts faux), ni
    `state.view='read'; state.fiche=f; render()` à la main — c'est `openRead(id)` qui appelle
    `buildRuntime` + `bindStateToRuntime`, et sans lui le clic sur « démarrer la session » ne
    démarre RIEN (mesuré : `Runtime.started=false`, `liveSessions=0`). Trois surfaces ont ainsi
    mesuré pendant une version un contexte SANS session vive tout en annonçant l'inverse. Chaque
    fenêtre CONSTRUIT donc son contexte par les fonctions de l'app (session vive, sauvegarde de
    version, document joint, complication déclarée, session archivée pour le compte-rendu — qui
    exige le parcours complet, `exportSessionReport` prenant un **ID** et lisant les sessions
    ARCHIVÉES). `prep` accepte une FONCTION, sérialisée par Playwright : la CSP du projet interdit
    `eval()`, une sonde qui passe du code en chaîne est bloquée.
  - `scripts/audit-doctrine.mjs` — ECAM/QRH/AC 120-71B traduits en invariants observables :
    ordre du quai et position en px des boutons Plan/Réf. INCHANGÉS quel que soit l'état,
    débordement annoncé, memory items dans le flux et non recopiés dans la feuille, feuille
    Consulter inerte (0 coche, 0 démarrage), taper un nœud du plan ne démarre ni ne coche,
    snackbar mis en attente en session, mouvement nul sous `prefers-reduced-motion`.
  - `scripts/audit-verify.mjs` — la passe Do-Verify laisse un résultat CONSULTABLE (cf. trace de
    vérification). **Les sondes JETABLES s'écrivent à la racine en `.nom.mjs`** (pour trouver
    `playwright` dans `node_modules`) et sont ignorées par git ; seuls les harnais qui RESTENT
    vivent dans `scripts/`.
  - `check-sql.mjs` (v4.44.1) — `supabase/*.sql` n'était couvert par RIEN : ni servi, ni chargé
    par les tests, l'erreur ne se voyant qu'au collage dans l'éditeur SQL de Supabase, donc **sur
    une instance de production**. Vérifie les runs de dollars (un délimiteur de corps s'écrit
    `$$`), leur parité, et qu'aucun en-tête de fonction ne contient un `;` avant son corps.
    **PIÈGE À CONNAÎTRE AVANT TOUT PATCH SCRIPTÉ** : `String.prototype.replace()` interprète
    `$$` DANS LA CHAÎNE DE REMPLACEMENT comme un dollar littéral unique — comme `$&`, `` $` ``,
    `$'` et `$1`. Un script qui réinjecte du SQL contenant `$$` le mutile donc **en silence** :
    c'est arrivé en v4.44.0 sur deux fonctions trigger, et l'utilisateur l'a découvert en rejouant
    le schéma. Remède : passer une **fonction** de remplacement (aucune substitution n'y est
    faite), ou `split().join()`. Corollaire de méthode : le contrôle qui avait été fait à
    l'époque comptait les `$$` et vérifiait la PARITÉ — or un `$$` amputé ne matche plus le
    motif, il disparaît du compte des deux côtés et la parité reste vraie. Un contrôle aveugle au
    défaut qu'il prétend couvrir ne vaut rien (leçon v4.31.1, redite ici au prix fort).
- L'intégration continue (`.github/workflows/ci.yml`) rejoue, sur chaque push/PR :
  `npm run check` (syntaxe + couleurs + hashs CSP), `design:check --strict`, `npm ci`, `npm test`,
  puis `npm run audit` **en non bloquant**. `npm ci` (et non `npm install`) : la CI installe
  exactement le contenu du lock, donc reproductible — `release.sh` synchronise désormais la
  version de `package-lock.json` avec les trois autres fichiers (elle était restée à 4.3.0).

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
  Sous `forced-colors` (Windows High Contrast, v4.30.0) : filet MINIMAL — `.acct-dot`, `.cat-dot`
  et `.seg-pill` gardent leur couleur (`forced-color-adjust:none`, l'information EST la couleur) ;
  le reste s'appuie sur « la couleur jamais seule » (glyphe + mot). Non testé sur Windows réel —
  à valider sur machine avant d'étendre. Sous `prefers-contrast: more` (v4.31.0) : `--ink-soft`
  passe à `--ink` et `--line` à `--line-strong` (bloc déclaré en FIN de feuille — à spécificité
  égale il doit gagner sur les tokens des deux thèmes).
  **GARDE-FOU AUTO-EXÉCUTOIRE (v4.31.0, `scripts/check-colors.mjs`, dans `npm run check`)** : un
  hex n'est admis dans le CSS que dans une DÉCLARATION DE TOKEN (propriété `--…`, où qu'elle
  vive — `:root`, bloc sombre, blocs `data-accent`) ; seule exception listée, les nuanciers
  littéraux `.acc-sw`. La règle ci-dessus n'est donc plus déclarative. Tokens ajoutés à cette
  occasion : `--shadow-primary(-sm)` (élévation teintée des boutons remplis — les
  `rgba(23,71,127,…)` éparses), `--hover-dk(-hi)` et `--flow-hl-dk` (ex-hex des overrides
  sombres), et les FIXES deux-thèmes `--lb-cap`/`--lb-ink` (lightbox), `--paper` (canevas SVG,
  pages PDF, impression), `--flow-cur` (nœud courant du SVG — primaire CLAIR baké, le sombre
  passe par la contre-inversion).
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
  **UN REGISTRE N'EST JAMAIS MASQUÉ PAR UN ÉTAT (v4.24.0, décision utilisateur)** : un bloc de
  DÉCISION garde sa bordure ambre même quand il est le bloc courant (`.ov-block.dec.cur`). Avant,
  `.cur` était déclarée après `.dec` et repeignait la bordure en bleu : le même bloc changeait de
  couleur selon qu'on venait d'y arriver ou qu'on y remontait. La POSITION reste portée, toujours
  en bleu et sans ambiguïté, par la pilule « VOUS ÊTES ICI » (`.ov-here`, visible sur `.cur` seul) —
  un canal par signification. Les **options de branche** (`.opt`) sont à **16,5 px** comme
  `ol.steps li .txt` : choisir une branche engage au moins autant que cocher une étape, rien ne
  justifiait de le rendre moins lisible (graisse 700, pas 800 : c'est un choix, pas une action).
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
- **Challenge-response (v4.11.0, FAA Order 8900.1 Vol. 3 Ch. 32 §3-3403.A / Do-Verify)** : trois
  briques, AUCUN champ modèle.
  > **CORRECTION DE SOURCE (vérifiée sur le texte primaire, ne pas re-inverser).** Ce fichier
  > attribuait « Do-Verify » et « Challenge-Do-Verify » à l'**AC 120-71B**. Ces chaînes n'y
  > figurent NULLE PART (recherche exhaustive sur le document intégral : 6 chapitres + Appendix A,
  > 0 occurrence) — la révision B indique elle-même avoir « removed many of the examples previously
  > found in the appendices ». Elles viennent de l'**AC 120-71A (2003), que la révision B ANNULE**,
  > où elles ne sont que des INTITULÉS d'une liste de sujets qu'un SOP devrait couvrir, sans
  > définition ni prescription. Les définitions rédigées qui circulent en ligne (« The DV method
  > allows the flightcrew to use flow patterns from memory… ») ne proviennent d'aucun document FAA
  > retrouvable. La source correcte pour la MÉTHODE est le **FAA Order 8900.1, Vol. 3, Ch. 32,
  > §3-3403.A** ; pour la répartition à deux, l'AC 120-71B **§5.2.2.1** dit bien « one crewmember
  > reading the checklist and the second crewmember confirming and responding ».
  > La pratique implémentée ne change pas d'un pixel — seule la référence était fausse.
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
  passe existe pour produire. La règle « la réponse porte l'état CONSTATÉ, jamais un simple *fait* »
  est de **Degani & Wiener** (ligne directrice n°1 de « Cockpit Checklists: Concepts, Design, and
  Use », Human Factors 35(2), 1993, établie à partir d'un rapport ASRS) — et non de l'AC 120-71B,
  qui exige seulement que l'autre pilote vérifie que l'item a été correctement accompli (§5.2.2.2)
  et que les items critiques le soient par les DEUX (§5.2.2.5). Aucune de ces sources ne prescrit
  de MODÈLE DE DONNÉES : enregistrer la trace est une décision de conception, pas une exigence
  littérale. L'argument empirique de la distinction est ailleurs : au CVR de l'accident Delta 1141,
  la réponse au challenge « flaps » arrive en moins d'une seconde — matériellement trop vite pour
  avoir été constatée.
  Rendu durable : pilule « ✓✓ constaté » / « △ écart » sur la ligne — **MÊME libellé pendant et
  après la passe** (v4.25.2) : la trace disait « vérifié » là où la passe disait « constaté », et
  les glyphes n'apparaissaient qu'après. Deux mots pour un même état, c'est ce qu'AC 120-71B
  proscrit ; le mot retenu est celui du GESTE (le bouton dit « Constaté ✓ »), car un compte rendu
  reflète la réponse donnée, il ne la reformule pas. **AUCUN bandeau ambre sur l'étape en écart** :
  le liseré inset de 3 px est le canal du REGISTRE (⚠/△, une propriété du CONTENU — doctrine
  « normal = ligne, signalé = boîte », v4.24.0), l'écart est un ÉTAT DE LA PASSE. Réutiliser le même
  trait rendait le signal ambigu — on ne pouvait plus dire si l'ambre annonçait « étape de
  vigilance » ou « écart constaté ». La pilule, mot + glyphe, suffit. Un geste MANUEL invalide la
  trace (cocher lève l'écart, décocher retire la constatation) — et comme le cochage est
  CHIRURGICAL (sans re-rendu), le marqueur doit être repeint sur place par `paintStepTrace`, sinon
  il reste périmé à l'écran alors que l'état est juste (défaut trouvé par `scripts/audit-verify.mjs`).
  **RETOUR IMMÉDIAT (v4.24.0, demande utilisateur — et PLUS conforme AC 120-71B)** : le résultat de
  chaque item s'affiche DÈS qu'il est prononcé (pilule « constaté » / « écart » + bilan vivant
  « n constatés · n écarts · n restantes »), au lieu d'attendre la fin du bloc. La boucle do-verify
  est challenge → réponse → CONFIRMATION ; différer la confirmation à la fin du bloc casse la
  boucle. Le marqueur lit `verified`/`vgaps`, PAS `checked` : une étape cochée AVANT la passe
  n'affiche donc plus un ✓ trompeur — elle reste « à constater » tant qu'on ne l'a pas observée,
  ce qui est tout le sens du Do-Verify.
  Portée : stocké dans la SESSION seulement — l'export v3 des fiches et le format des clés
  (`seq:blocId:index`) sont inchangés ; un client antérieur ignore les deux champs.
  **Mode lecteur** (binôme, plein écran `#readerMode`, statique + délégation unique) : un
  challenge à la fois (26 px, réponse mono 20 px, zone verte ≥ 72 px), piloté sur le BOUT du
  journal — « Répondu » coche la même clé, fin de bloc = mêmes règles que « Continuer »
  (jamais d'avance tant que tout n'est pas confirmé, « Revoir » ramène au premier écart),
  décision = même chemin qu'une option ; Échap/✕ quitte sans rien perdre ; z-index 92 SOUS
  `#screenFlash` (99) — le flash d'alarme reste visible ; chrono de session via
  `updateRtStrip` (`#rmTime`) ; entrées : bouton « ⤢ Lecteur » sur l'instance du bout + menu ⋯
  (v4.31.0 : le glyphe ⤢ — grammaire des ouvertures plein écran, cf. Se repérer/Consulter — le
  fait lire comme une SURFACE et non un mode ; décision d'audit : PAS d'entrée dans le chrome de
  crise — 12 px libres mesurés à 360, et une commande qui apparaît/disparaît selon la largeur
  romprait la constance positionnelle).
  **ENRICHI v4.28.0 (audit + décision utilisateur, 3 volets)** — le public du lecteur est un
  PROFESSIONNEL qui connaît à peu près le contenu (l'anticipation a de la valeur), et le
  un-item-à-la-fois N'EST PAS le modèle aviation (ECL Boeing = liste entière + curseur, ECAM =
  actions restantes sous les yeux ; Degani & Wiener : perdre sa place est un mode de défaillance
  premier) : (1) **bande minuteurs propre** `#rmTimers` (l'overlay couvrait le quai — or l'ÉTAT ne
  disparaît jamais : le segment ambre d'un échu est le canal d'acquittement de l'alarme) — TOUS
  les minuteurs, échus d'abord en ambre + mot « échu », PAS de « +n » (la bande passe à la ligne,
  rien n'est caché) ; chrono `#rmTime` en « ▲ » bleu pendant un exercice ; (2) **carte des blocs**
  `#rmMap` (pastilles du rail : vert ✓ fait, bleu ● ici, neutre à venir — jamais d'alerte ; même
  `minimapData`) + **contexte local** `.rm-ctx` (précédent avec « ✓ », « suivant : … » — le
  challenge courant reste SEUL en 26 px) ; (3) **⚡ Complication(s)** dans la rangée de bloc —
  même index `#cxModal`, monté à `z-index:94` (AU-DESSUS du lecteur, sous le flash 99) ; le
  lecteur RESTE OUVERT pendant l'excursion (doctrine QRH : le binôme change de checklist, pas de
  support — `_rmSync` le repilote depuis `cxEnter`/`cxResume`, y compris vers une fiche EXTERNE :
  `rmTitle` est re-posé à chaque `readerRender`) ; en fin de bloc d'excursion, JAMAIS
  « Terminer » — « ↩ Reprendre — bloc → » (rempli, non bloquant : présent même avec des étapes
  non confirmées). Harnais `scripts/audit-lecteur.mjs`.
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
- **COMPLICATIONS « À TOUT MOMENT » (v4.26.0 — entrée PAR L'ÉVÉNEMENT)** : champ FACULTATIF
  `complications:[{label,target}]` sur la fiche — `target` = bloc de la fiche (laryngospasme) OU
  autre aide/protocole (ACR pendant une sédation ; résolution `relTarget`, id = référence JAMAIS
  régénérée : invalide → rangée rejetée par `migrate`). Modèle : QRH non-normal / mode
  failure-related ECAM — une complication ne s'entre pas par la position mais quand l'ÉVÉNEMENT
  survient, et **le RETOUR fait partie du dispositif** (jamais laissé à la mémoire).
  DÉCLENCHEUR (v4.26.1, décision utilisateur — UN bouton CONSTANT, pas un par événement) :
  `⚡ Complication(s) (n)` sur la carte du BOUT — étapes ET décision — qui ouvre l'INDEX
  `#cxModal` (grandes rangées : événement + « interrompt le parcours — retour prévu » ou
  « ouvre : <aide> ↗ ») + la MÊME entrée au menu ⋯. C'est le modèle QRH/Stanford : UN objet à
  index par onglets, pas un bouton de cockpit par urgence — l'appel automatique ECAM ne vaut que
  pour les pannes CAPTÉES, ce que l'app ne fait pas ; et N boutons rouges qui se ressemblent
  obligeraient à LIRE chacun sous stress, quand un mot constant à position constante s'apprend.
  Coût assumé : un tap de plus, payé en rangées larges. Registre ALERTE en CONTOUR, jamais rempli
  (un aplat rouge permanent désensibilise).
  COMPORTEMENT : `cxEnter` = TOUJOURS un nouveau passage au bout — même bloc déjà visité, un
  événement qui se REproduit est un nouvel événement (≠ `jumpToBlock`, où revoir = défiler) ;
  passage marqué « ⚡ complication » en toutes lettres, pastille `⚡` si le bloc est hors tronc ;
  « Terminer l'algorithme » SUPPRIMÉ pendant l'excursion (le parcours n'est pas fini, il est
  INTERROMPU) ; `↩ Reprendre — <bloc> →` TOUJOURS actif (non bloquant : on reprend quand
  l'événement est maîtrisé, pas quand les cases sont cochées) = LE contrôle rempli de l'écran
  pendant l'excursion. `cxResume` = NOUVEAU passage du bloc interrompu, cases neuves — doctrine
  d'interruption AC 120-71B : on RE-vérifie après une interruption, l'ancienne carte reste
  lisible juste au-dessus. `Runtime.cxBack={seq→blocId}` persiste dans la SESSION (export v3 des
  fiches inchangé ; un ancien client ignore le champ ET la carte — le bloc reste un bloc).
  STRUCTURE : un bloc cible HORS séquence ne prend PAS de numéro de tronc (`flowPlan` l'exclut —
  numéroté, il se lisait « l'étape d'après », mesuré avant correction) ; il vit dans une section
  « ⚡ À tout moment » de l'Échelle ET du Statique. Les orphelins NON déclarés gardent le
  comportement historique. Éditeur (v4.26.1) : rangées libellé + bouton-cible ouvrant le
  SÉLECTEUR FILTRABLE partagé (`openCxTargetPicker` sur `relPickModal` — même patron que « Voir
  aussi »/« Joindre un document », demande utilisateur : la liste des aides peut être longue),
  DEUX groupes — blocs de CETTE fiche d'abord, puis aides & protocoles ; contrairement à « Voir
  aussi », une aide déjà liée reste sélectionnable ; garde-fou 1-3. Prompt IA : bloc dédié hors séquence, label = nom d'événement, 1-3 max, un
  événement relevant d'une AUTRE aide se SIGNALE (le JSON ne connaît pas les ids des autres
  fiches). Helpers purs `cxAll`/`cxDetached` (testés) ; harnais `scripts/audit-complications.mjs`.
- **MODE EXERCICE (v4.27.0 — pilier EMIC « s'entraîner » ; Greig 2023 : le transfert exige la
  FIDÉLITÉ DE FORMAT)** : « Répéter en exercice » (menu ⋯) rejoue la fiche dans l'ÉCRAN RÉEL,
  À L'IDENTIQUE — même journal, mêmes minuteurs, mêmes gestes ; un mode « simplifié » entraînerait
  au mauvais outil. SEULE l'ANNONCIATION change (placard TRAINING aviation) : bandeau HACHURÉ
  (`#crisisBand.exo`, repeating-linear-gradient) + pilule « ▲ Exercice » en BLEU pointillé — ni
  rouge ni ambre (ce n'est pas une alerte), et le « ● Session » VERT reste réservé au réel (le
  chrono d'état dit « ▲ Exercice », `.seg.glb.exo`). **v4.28.0 (deux retours utilisateur)** :
  les hachures alternent `--surface`/`--primary-soft` (surface/surface-2 était quasi invisible en
  SOMBRE — delta mesuré par le harnais dans les DEUX thèmes ; le registre bleu porte la texture).
  **v4.29.0 — LE PLACARD SUIT LE TITRE (retour utilisateur : hachurer le QUAI était illisible,
  « immonde » — annulé)** : tant que le bandeau-titre est visible, LUI SEUL est hachuré ; au pixel
  où il passe sous la barre, c'est L'EN-TÊTE qui prend la hachure (`header.bar.exo.ttl-on` — même
  mécanique de relais que `#hdrCrisis`, qui reste la pilule bleu pointillé sur fond `--surface`
  plein). Le QUAI reste une zone d'état PROPRE : des chiffres n'ont pas à vivre sur une texture.
  **v4.29.1 (retour utilisateur « ça saute »)** : la hachure vit sur un `::before` en FONDU
  d'opacité (~300 ms) — l'entrée/sortie du mode ET le passage bandeau → en-tête au défilement
  sont fondus, plus d'aplat instantané (les sondes lisent donc `getComputedStyle(el,'::before')`,
  pas l'élément) ; les enfants passent en `z-index:1` (le ::before couvre le fond, jamais le
  contenu) ; et le bouton Quitter est COMPACTÉ à ≥ 780 px (24 px + halo → cible 44) : le bandeau
  réel y fait 44 px de haut, un bouton de 36 px l'épaississait de 12 px à l'entrée en exercice —
  Δ mesuré à 0 px sur 360/390/430/780. Micro-animation d'entrée/sortie du mode (`_exoPulse` :
  glissement de la hachure + pop de la pilule, inerte sous reduced-motion) ;
  bouton « **Quitter l'exercice…** » sur le bandeau
  (`#cbExoQuit` → `quitExercise` : avant la 1ʳᵉ action on repose une fiche neuve, après c'est le
  MÊME dialogue Terminer que le menu ⋯ — titré « Terminer l'exercice ? » par `confirmEndSession`,
  qui dit désormais la portée). Le drapeau `Runtime.exercise` est posé par
  `startExercise(f)` AVANT le démarrage (1ʳᵉ action → session marquée `exercise:true`) ; démarrer
  un exercice sur une session réelle vive exige la confirmation danger « Terminer et exercer ».
  **ZÉRO CONTAMINATION CLINIQUE** : les sessions vivent en IndexedDB local (jamais dans l'export
  v3, jamais synchro — le drapeau y est donc sûr) ; l'historique les SÉPARE en deux groupes
  « Sessions cliniques (n) » / « Exercices (n) » avec badge `▲ EXERCICE` par rangée (jamais
  mélangés) ; carte-bilan « Exercice terminé » au registre exercice (`.last-sess.exo`) ;
  compte-rendu FILIGRANÉ « EXERCICE » + méta « répétition sans patient ». **v4.29.0 : PAS de
  pastille « ▲ Exercice : date » dans la méta de lecture** (retour utilisateur : elle captait
  l'œil à côté de la date de validation pour une information non clinique) — la date du dernier
  exercice vit en SOUS-TITRE de la rangée « Répéter en exercice » du menu ⋯ (« dernier : ‹date› »,
  sinon « aucune trace clinique ») et dans l'historique scindé. **AUCUN rappel « jamais
  répétée », aucune relance d'aucune sorte (décision utilisateur : pas de nudge)** ; le harnais
  vérifie l'ABSENCE de ce texte dans le DOM rendu (piège : `document.body.textContent` remonte
  le `<script>` inline — borner la sonde à `main`). **COMPTE-RENDU ENRICHI POUR TOUTES LES
  SESSIONS, réelles comprises** (support du DÉBRIEF, 4ᵉ pilier EMIC) : section « ⚡ Complications »
  (heure d'entrée mémorisée par `cxEnter` — `cxBack[seq]={id,t}`, les valeurs chaîne v4.26.x sont
  normalisées à la lecture) et « Vérification (do-verify) » (n constatées ✓✓ + écarts △
  horodatés, depuis `verified`/`vgaps` du snapshot). Terminer dit sa portée : « Terminer
  l'exercice… » vs « Terminer la session… ». Harnais `scripts/audit-exercice.mjs` (16 contrôles,
  dont « la session réelle est INCHANGÉE »).
- **PILE DE RETOUR fiche → fiche (v4.28.0, décision utilisateur)** : naviguer vers une autre
  fiche/protocole (« Voir aussi », complication EXTERNE, feuille Consulter — tout passe par
  `openRel`, qui pousse l'origine) mémorise D'OÙ l'on vient dans `state.readStack` (plafond 8,
  vidée à CHAQUE rendu de l'accueil) : le « ‹ » d'en-tête porte le TITRE de la fiche d'origine
  (ellipse CSS `.hdr-back span`) et y RAMÈNE ; pile vide → « Bibliothèque », inchangé. Doctrine :
  AC 120-71B — le retour d'une interruption est PRÉVU par le dispositif, jamais laissé à la
  mémoire ; les bandeaux de session de l'accueil restent la REDONDANCE, mais ils n'existent que
  si une session a DÉMARRÉ (une fiche consultée sans cocher n'y laisse aucune trace — c'est le
  cas que la pile couvre). **GARDE ANTI DOUBLE-TAP 700 ms** (demande utilisateur explicite,
  même mécanique `_backGuardT`/`.guarded` que le retour d'aperçu) : deux taps nerveux ne
  traversent JAMAIS deux niveaux — on ne se retrouve pas à la bibliothèque sans l'avoir voulu ;
  la garde est vérifiée par les DEUX handlers (fiche et protocole), origine supprimée
  entre-temps = repli bibliothèque silencieux. Micro-animations v4.29.0 (non bloquantes,
  inertes sous reduced-motion) : le retour par la pile fait entrer la vue d'origine dans le sens
  du geste (`main.back-anim`, keyframes `secInL` réutilisées) et la carte de reprise d'une
  complication glisse en place (`.ov-block.cx-return`). Harnais : `scripts/audit-lecteur.mjs`.
- **RETOUR SYSTÈME (History API, v4.30.0 — P1 de l'audit externe)** : avant, 0 pushState/popstate —
  sur Android (PWA ou navigateur), le geste retour SORTAIT de l'app depuis une fiche en pleine
  session, le lecteur, un PDF ou une feuille plein écran (les données survivaient via
  `persistAllLive`, mais l'écran disparaissait en pleine réanimation). Contrat implémenté SANS
  routing (cohérent monofichier) : UNE entrée SENTINELLE (`_histArm`, état `{ac:1}`), ré-armée à
  chaque consommation ; le popstate emprunte le MÊME chemin que l'affordance visible (doctrine du
  gestionnaire de modales : « réutilise son ✕, donc ses effets de bord ») — fenêtre du dessus
  (✕, ou CLIC DE VOILE synthétique si pas de ✕ : « Terminer la session ? » ferme sur Poursuivre,
  JAMAIS Terminer), sinon lecteur, sinon schéma plein écran, sinon visionneuse d'image, sinon le
  « ‹ » d'en-tête — qui porte déjà la pile `readStack` ET la garde anti double-tap 700 ms : le
  retour système en hérite. Accueil nu = sortie réelle (on traverse l'entrée d'origine — aucun
  « appui mort »). Une sentinelle SURVIVANT à un rechargement est neutralisée au boot
  (`replaceState(null)`) — sans ça, le premier retour tombait dessus, était lu comme un geste
  « avant » et ne fermait rien (constaté à la sonde). `history.scrollRestoration='manual'` (deux
  entrées, même document : une « restauration » de défilement entre elles ferait sauter la page).
  Toute nouvelle surface plein écran doit appeler `_histArm()` à l'ouverture et entrer dans
  `_histBackAction()`. **PIÈGE (vécu deux fois cette version)** : toute édition du script inline
  exige `node scripts/csp-hashes.mjs` — sinon la CSP par hashs bloque le script et l'app ne boote
  plus ; et en DEV le service worker ressert l'ancien HTML tant qu'on ne l'a pas désinscrit
  (caches purgés) — tester un correctif sur la version précachée fait conclure à tort qu'il ne
  marche pas.
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
  la fourche étant masquée en pile, rail + chip portent la structure ;
  **INTITULÉ DE DÉCISION COLLANT SOUS 640 px (décision utilisateur, `svStickBands`)** : en PILE,
  la bande-question sortait de l'écran pendant qu'on lisait encore ses étapes — MESURÉ à 844 px
  de contenu lus sans elle sur une décision imbriquée à 360×640, contre **0 px côte à côte**
  (≥ 640 px). Le bornage à ce palier n'est donc pas esthétique : c'est la borne du problème.
  La bande s'épingle sous `--stick-top` (source UNIQUE du bas de ce qui est déjà collé), chaque
  niveau imbriqué se rangeant SOUS son ancêtre. **La hauteur n'est JAMAIS forcée** : compacter à
  une ligne rendrait le décalage arithmétique (donc CSS pur) mais TRONQUERAIT une question de
  plus de deux lignes — or la question EST l'information de cette bande. D'où une MESURE, mais
  réduite à UNE passe par rendu, en fin de `svPaintArrows` (lectures groupées puis écritures,
  ÷ `zoomF()` — règle v4.13.1) ; l'ex-fil d'ancêtres de la vue « Détails » recalculait, lui, à
  chaque évènement de défilement. Décrochage NATIF (chaque bande est bornée par son
  `.sv-decwrap`, elle se détache seule à la convergence) ; z-index DÉCROISSANT avec la
  profondeur et sous `#crisisDock` (15) — un niveau imbriqué se replie DERRIÈRE son ancêtre
  pendant l'approche, modèle ECL retenu en v4.22.1, ce n'est pas un chevauchement fautif ;
  **PLAFOND 3 niveaux** (au-delà, `position:static` : la zone haute atteint déjà 177 px sur 640
  en session) ; `scroll-margin-top` sur les cellules SOUS une décision (WCAG 2.4.11 — le
  défilement du focus est celui du NAVIGATEUR, et scroll-margin s'AJOUTE au scroll-padding de
  `html`, d'où une valeur qui ne compte QUE la pile de bandes). Couvert par
  `scripts/audit-doctrine.mjs` (balayage complet du défilement à 360 px : aucune étape lue sans
  sa question ; et à 1280 px, AUCUN épinglage). **PAS de règle `deep`**
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
  **REGISTRE DU « NON PROTÉGÉ » = NEUTRE (v4.31.0, audit externe — décision utilisateur)** : un
  état PERMANENT en ambre s'use (banner blindness) et émousse l'ambre des états réellement
  actionnables. Le mot « non protégé » + la bulle d'aide portent l'information ; `pers-warn`
  (ambre) est réservé à « presque plein » et aux documents PDF manquants — un test unitaire
  encode cette règle (ne pas « re-corriger » en ambre). MÊME DOCTRINE côté lecture (v4.31.0) :
  en SESSION VIVE, la rangée `.read-meta` (statut, catégorie, validation) est masquée — vue à
  l'ouverture, elle ne conduit rien pendant le soin ; sélecteur
  `body.view-read:has(#cbTimers:not([hidden]))`, écran seulement (le papier garde la méta), saut
  absorbé par `renderKeepAnchor`.
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
  **COÛT NUL EN HAUTEUR D'EN-TÊTE SOUS 430 px (v4.23.4)** : la rangée d'identité est en
  `flex-wrap:wrap`, or le flex CASSE LA LIGNE avant de rétrécir — un dépassement de 7 px suffisait
  donc à renvoyer les ACTIONS à la ligne et à ajouter 42 px d'en-tête à 375 px (iPhone SE), 38 px à
  360 px. Trois réglages rendent les pixels manquants sans rapetisser le glyphe outre mesure :
  logo 34 → 30 px, écart de colonne 10 → 8 px, mot-marque 20 → 18 px (très au-dessus du plancher
  de 11 px ; le logo n'étant pas interactif, aucune règle de cible ne s'y applique). Vérifié à 0 px
  de surcoût de 360 à 431 px. Toute addition à cette rangée doit être re-mesurée à **320 px**
  (v4.43.0 — c'était 360 jusque-là) : c'est désormais la largeur la plus contrainte servie.
- **PLACARD DE L'INVITÉ (v4.55.4, demande utilisateur)** : il lisait « ■ Mode crise », exactement
  ce que lit l'hôte, alors que sa situation est autre — il SUIT une session qu'il ne conduit pas et
  qui peut s'arrêter sans lui. Le bandeau-titre porte donc « **▪ Vous suivez** » et une hachure
  BLEUE, l'en-tête relayant « ▪ Suivi » au pixel où le titre passe dessous. **Même mécanique que le
  placard d'exercice, au trait près** (`::before` en fondu, relais au défilement, enfants en
  `z-index:1`) : rien de neuf à inventer, donc rien de neuf à casser — et **coût nul en hauteur**,
  seule condition qui vaille là où `#crisisCtrl` n'a que 2,1 px de marge à 320 px. **L'EXERCICE
  GARDE LA PRIORITÉ** et ce n'est pas négociable : « ceci est une répétition » prime sur « vous
  suivez » — le premier protège d'une méprise clinique, le second est une information de rôle que
  le quai porte en permanence de toute façon.
- **RÉPONDRE À UN GESTE N'EST PAS INTERROMPRE (v4.55.4)** : la règle 11 (« aucune notification
  flottante en session ») vise ce qui **ARRIVE** — erreur de synchro, conflit, nouvelle de fond :
  ce qui s'impose à quelqu'un qui n'a rien demandé, au pire moment. Elle retenait aussi la
  **RÉPONSE** à un bouton qu'on venait de presser : taper « silencieux ? » ou « Partager la
  session » sur une fiche en brouillon ne produisait RIEN, et le message surgissait à l'accueil,
  détaché de son geste, donc incompréhensible. `toast(msg, ms, direct)` — le troisième argument est
  **explicite**, jamais déduit d'une proximité temporelle avec un clic : une nouvelle de fond
  tombant dans la seconde suivant un tap serait alors affichée par accident, exactement ce que la
  règle interdit.
- **DIXIÈME PIÈGE DE CASCADE — UN `>*` QUI IMPOSE `position` (v4.55.4, signalé à l'usage)** : le
  placard levait tous les enfants DIRECTS de l'en-tête en `position:relative; z-index:1` pour les
  faire passer au-dessus de sa hachure. Or `.more-menu` est un enfant direct **et se positionne
  lui-même** : la règle valant (0,2,1) contre (0,1,0), le menu ⋯ retombait dans le flux de la
  barre et s'y **ouvrait au lieu de flotter dessous**, dès qu'un placard était posé. Nommer le
  menu dans un `:not()` n'aurait fait que déplacer le piège au prochain calque ajouté là : on
  **retire l'exigence** au lieu de l'assortir d'exceptions. `header.bar` porte déjà
  `position:sticky; z-index:20`, donc elle EST un contexte d'empilement — un `::before` en
  `z-index:-1` s'y peint au-dessus du fond de la barre et sous TOUT son contenu, sans qu'aucun
  enfant ait à être positionné. **`#crisisBand` garde l'ancienne mécanique**, et ce n'est pas une
  inconséquence : il est `position:relative` **sans `z-index`**, donc pas un contexte
  d'empilement — un `z-index:-1` y passerait sous son propre fond et la hachure disparaîtrait.
- **UNE ATTRIBUTION S'AMARRE À CE QU'ELLE DÉCRIT (v4.55.4)** : « avancé par ‹rôle› » était un
  drapeau GLOBAL qu'un seul site du fichier effaçait — `cxEnter`, l'entrée sur complication.
  Aucun avancement ordinaire ne l'effaçait : posée une fois (typiquement par le backlog rattrapé
  à la jointure, où toutes les navigations de l'hôte défilent d'un coup), la mention **suivait
  l'invité de carte en carte** et attribuait à « Hôte » les blocs qu'il venait lui-même
  d'avancer. Encore un **demi-chemin** : un effacement écrit d'un seul côté. Remède : ne pas
  ajouter les N sites manquants mais **supprimer le besoin de s'en souvenir** — la mention porte
  le **numéro de VISITE** que l'avance distante a créé et ne s'affiche que sur celui-là ; le
  premier passage minté localement en porte un autre, donc elle disparaît par construction. Elle
  est posée **dans `shareApplyAnchored`**, seul point où une navigation distante devient la
  position courante : `onEvents` le manquait dans un cas (le drain de la file par `rmResume` n'y
  repasse pas) et le posait dans un autre où il ne fallait pas (une navigation REFUSÉE par le
  mode lecteur nommait déjà son auteur alors que rien n'avait bougé). L'annonce au lecteur
  d'écran, elle, garde une variable **locale au lot** : elle n'a ni la même durée de vie ni la
  même condition que la mention.
- **NEUVIÈME PIÈGE DE CASCADE, ET LE PREMIER PAR `:not()` (v4.55.3)** : la règle qui transforme
  toute fenêtre en feuille pleine largeur sur écran étroit vaut
  `.ai-modal:not(.pdf-modal):not(.dlg-confirm) .ai-card` = **(0,3,0)**, parce que **`:not()` compte
  la spécificité de son argument**. Elle battait `:is(.plan-modal,.ref-modal) .ai-card` = (0,2,0) et
  reposait 18 px de rembourrage haut sur des feuilles qui se donnent `padding:0` — leur barre de
  titre est `sticky top:0` et doit affleurer le bord. Mesuré : 18 px de fond nu au-dessus du titre,
  **65 px sur un iPhone à encoche** où `env(safe-area-inset-top)` s'ajoute, et la bande restait
  visible au défilement puisque la barre est collante. On exclut désormais la CLASSE `.sheet-full`
  plutôt que les deux fenêtres nommément, pour que la prochaine hérite de l'exclusion.
- **DEUX ROGNAGES QUE PERSONNE NE MESURAIT (v4.55.3, retours d'usage)** : la **croix du panneau
  minuteurs** sortait de **110 px du cadre à 320 px** sur écran TACTILE (`.rt-head` est une rangée
  flex sans `wrap` et sans rien de compressible ; « silencieux ? » et le bouton son y montent à
  44 px de cible) — remède = le patron de la carte-bilan (v4.29.2) : conteneur `relative`, croix
  ANCRÉE en haut à droite, `padding-right` qui lui réserve sa place. Et une **ligne d'Échelle**
  sortait du plan dès **quatre options à 320 px**, jusqu'à 280 px dehors à huit, le titre de la
  décision étant écrasé à 0 px bien avant : les renvois abrégés étaient `flex:none; nowrap`, leur
  largeur croissant sans borne. On ENROULE plutôt que de tronquer — dans un PLAN, une branche
  cachée est une branche qu'on ne saura pas prendre ; c'est la différence avec le quai, où l'on
  abrège et où l'on annonce « +n », parce qu'ici la place existe verticalement.
  **LES DEUX CONTRÔLES ONT DÛ ÊTRE REFAITS** : la première version restait VERTE avec les défauts
  réintroduits — elle mesurait la fiche d'exemple (deux options, jamais de débordement) et un
  contexte non tactile (aucun gonflement des cibles). Un contrôle qui ne rencontre pas le défaut ne
  le couvre pas : il faut construire le CAS, pas seulement la mesure.
- **320 px EST SERVI (v4.43.0, décision utilisateur)** — c'est le plancher de WCAG 1.4.10
  « Reflow », et deux surfaces y rognaient en silence : la **rangée de commandes de crise**
  exigeait 348 px pour 320 (28 px inatteignables, « ⤢ Cons. » coupé en plein mot) et le **`⋯` de
  l'éditeur** sortait de 6,2 px, bouton pourtant `display:grid` — mesuré identique sur Chromium et
  WebKit. Les pixels viennent de la recette v4.23.4 (écarts et rembourrages), jamais d'un
  renommage ni d'une 2ᵉ ligne : 34 px rendus pour 28 nécessaires dans la crise, ~12 pour 6,2 dans
  l'éditeur. **`.ctrl-sp` n'est PAS un poste d'économie** : ces 4 px sont l'écart de Gestalt qui
  sépare le MODE des OUVERTURES (raison d'être de la séparation ECP/ECAM de v4.25.0) ; une analyse
  antérieure concluait à tort qu'il fallait le sacrifier, faute d'avoir regardé les rembourrages
  des segments et des boutons. Deux paliers `359.98` ajoutés, DÉCLARÉS APRÈS les blocs `429.98`
  et `399.98` (spécificité égale : l'ordre décide — 5ᵉ piège de cascade du projet). Harnais :
  `audit-doctrine` mesure la rangée de crise à **320/360/375/390** avec, en plus du hors-écran, un
  contrôle de **rognage par le conteneur** (un bouton peut tenir dans la fenêtre tout en étant
  coupé par sa boîte de contenu — c'est ce qui se produisait), et la barre d'éditeur à 320/360.
- **DÉFILEMENT PRÉSERVÉ, PAS RECONSTRUIT (v4.23.5, plusieurs retours d'usage)** — trois surfaces
  ont chacune leur propre défilement qu'un `render()` (qui reconstruit le DOM) remettait à zéro :
  (1) le RAIL de lecture `.read-side` (`overflow-y:auto`) « remontait » dès qu'on touchait un bouton
  (minuteur, compteur, son, « +Minuteur PA », « Noter l'heure ») — capture/restaure `scrollTop`
  autour de `main.innerHTML` dans `renderRead` (`_railY`), et le journal des actions passe par une
  mise à jour CHIRURGICALE `renderTkOnly` (le panneau étant en fin de rail, ajouter une ligne pousse
  vers le bas sans rien déplacer au-dessus) ; (2) la bande horizontale des BIBLIOTHÈQUES
  `.scopebar .chiprow` SAUTAIT à chaque sélection car on RE-CENTRAIT la biblio active — désormais
  on restaure la position laissée (`_scopeScroll`) et on suit les défilements, exactement comme les
  catégories (qui, elles, n'ont jamais eu de recentrage). Règle : une zone à défilement propre doit
  voir sa position CAPTURÉE avant un re-rendu et RESTAURÉE après — jamais recalculée.
- **ON ANIME LA COMPOSITION, JAMAIS LA MISE EN PAGE (v4.41.0, phase 3)** : une `transition` ou une
  `@keyframes` ne porte que sur `transform` et `opacity`. Animer `width`, `height`, `top`/`left`,
  `margin` ou `padding` force une passe de mise en page **par image**, pendant toute la durée de
  l'animation. Le cas mesuré : `.tm-bar`, la barre de progression d'un minuteur, était en
  `transition:width 1s linear` — donc en réanimation, avec un minuteur d'intervalle armé et le
  panneau ouvert, **118 layouts/s et 123 recalculs de style/s en continu**, soit 126,8 ms/s de fil
  principal à CPU nominal, 206,9 à ×4 et 377,3 à ×6 : jusqu'à **38 % d'un cœur** consommés sans
  qu'aucun geste ne soit fait et sans qu'aucun JS ne s'exécute. En `transform:scaleX()` +
  `transform-origin:left` : 2 layouts/s, 17 recalculs/s, 13,3 / 14,3 / 27,7 ms/s — **autant que
  supprimer l'animation** (11,7 / 14,7 / 21,5) mais **sans changer le rendu d'un pixel**. WebKit,
  hors CDP : +9,7 % de débit utile du fil principal, contre +9,3 % pour la suppression. Le gain
  est de la MARGE CPU et de l'AUTONOMIE sur appareil lent, pas de la fluidité (120 fps et latence
  de cochage identiques dans les deux cas) — ne pas le vendre pour autre chose. Précédent interne
  antérieur : `.t-life` (barre de vie des toasts) était déjà en `scaleX`. **Corollaire de
  cohérence** : quand un gabarit et un tick écrivent la même valeur, elle passe par UNE fonction
  (`barTf`) — le tick compare avant d'écrire (anti-churn, ~3,3 passages/s), et deux formats
  seulement équivalents (`scaleX(0.76)` vs `scaleX(0.7600)`) feraient échouer la comparaison et
  réécriraient le style à chaque passage. Le reste de la feuille est déjà conforme : 19 keyframes
  sur 19 n'animent que des propriétés composées.
- **HAUTEURS RELATIVES À LA FENÊTRE SOUS ZOOM (v4.24.0)** : le réglage « taille du texte » est un
  `zoom` sur `<html>` ; une hauteur en `vh`/`dvh` se résout AVANT le zoom puis se fait agrandir par
  lui. À 130 %, `100dvh` occupait donc **1,3 écran** : le bas des rails (accueil ET lecture) devenait
  inatteignable, et `min-height:100vh` faisait défiler **dans le vide** une page courte (240 px
  mesurés sur 800 px de haut). Toute hauteur relative à la fenêtre s'écrit donc
  `calc(100dvh / var(--zf,1))` — `--zf` est posée par `applyZoom`, pendant CSS de `zoomF()` pour le
  JS (règle v4.13.1). Corollaire : **ne jamais réintroduire un `vh`/`dvh` nu** ; couvert par
  `scripts/audit-zoom-scroll.mjs`. **OVERLAYS PLEIN ÉCRAN (v4.29.3, retour utilisateur iOS)** :
  un overlay `position:fixed; inset:0` se dimensionne sur le GRAND viewport iOS (barre d'outils
  Safari repliée) — barre visible, son bas passe DERRIÈRE elle, et comme l'overlay est aussi le
  DÉFILEUR, la fin du contenu est INATTEIGNABLE (« le contenu ne scrolle pas sur cette bande, la
  fenêtre est coupée »). Tous les overlays défilables (`.ai-modal` — donc feuilles Plan/Consulter
  et PDF —, `.lightbox`, `#readerMode`, `#flowFull`) reçoivent sous `@supports (height:100dvh)`
  un `bottom:auto; height:calc(100dvh / var(--zf,1))` : la fenêtre s'arrête au bord réellement
  VISIBLE et suit la barre dynamique ; sans dvh, `inset:0` inchangé. Vérifié au pixel sur
  Chromium ET WebKit à 90/100/130 % ; tout NOUVEL overlay plein écran doit entrer dans cette
  liste. **ÉPILOGUE (v4.29.4-6, mesuré sur appareil)** : la hauteur est en réalité pilotée par
  `--vvh` (= `window.visualViewport.height`, tenue à jour par JS — la seule mesure qu'iOS ne
  fausse jamais ; `100dvh` n'est que le repli avant la première mesure). Le résidu constaté
  (WebView de 812 px sur un écran de 874 — amputée d'exactement la hauteur de la barre d'état,
  bug iOS du mode `black-translucent` où la géométrie est FIGÉE À L'INSTALLATION de la PWA) se
  répare en RÉINSTALLANT l'app sur l'écran d'accueil, pas en CSS : diag avant `ih/vv/dvh 812`,
  après réinstallation `874` partout. Si une « bande morte » réapparaît en bas d'une PWA :
  vérifier d'abord ces mesures avant de toucher au code. DÉNOUEMENT (v4.29.9) : la bande
  résiduelle malgré géométrie saine venait du VERROU DE FOND (`body{position:fixed}` — iOS
  rétrécit le rendu des fixés descendant d'un body lui-même fixé : accueil parfait, fenêtres
  coupées, aucune mesure web ne le voit) ; verrou remplacé par `html{overflow:hidden}`. CONFIRMÉ
  RÉSOLU sur appareil (v4.29.10) — l'instrumentation (diag + règle visuelle) est RETIRÉE ; pour
  ré-instrumenter un jour : tags v4.29.5-9 (ligne diag ih/vv/dvh/sat/vvV/sc/ot dans la fenêtre
  Compte, règle visuelle `_vvRuler` rouge/bleu au tap).
- **SORTIE PDF UNIFIÉE (v4.24.0)** : « Exporter en PDF » doit rendre le MÊME document quel que soit
  l'appareil. Mesurée avant correction, la sortie variait sur trois axes — le ZOOM s'appliquait au
  papier (0,9 / 1 / 1,3), le RAIL s'imprimait dès que la page faisait ≥ 780 px (soit toujours sur A4
  ≈ 794 px, donc contenu EN DOUBLE), et le titre changeait de corps (21 / 24 px). `@media print`
  neutralise les trois (`html{zoom:1}`, `.read-side{display:none}`, `.read-grid` en bloc, titre
  22 px). Vérifié : pagination identique sur trois configurations opposées.
- **DEUX RANGÉES COLLANTES, DEUX NATURES (v4.25.0, décision utilisateur)** — `#crisisCtrl`
  (COMMANDES : bascule de mode, ⤢ Se repérer, ⤢ Consulter) **au-dessus** de `#crisisDock` (ÉTAT :
  chrono de session, minuteurs). C'est l'architecture ECAM à la lettre : sur un Airbus les commandes
  vivent sur l'**ECP**, un panneau DISTINCT de l'affichage — on n'appelle pas un synoptique depuis
  l'écran. Les deux étaient fusionnés, d'où une bagarre pour la place à **chaque** ajout ; séparés,
  l'arbitrage disparaît (et l'état retrouve la place d'afficher deux minuteurs étiquetés à 390 px
  au lieu d'un). Coût assumé : ~50 px permanents de plus sur téléphone, soit 6 % de la colonne
  d'action — mesuré, aucune étape ne disparaît de l'écran.
  **ORDRE DANS LA RANGÉE DE COMMANDES** : le MODE d'abord — il **gouverne l'existence** de
  « Se repérer » (masqué en Statique) ; le dessiner après serait une inversion de hiérarchie. Puis
  un ÉCART FIXE (`.ctrl-sp`, 22 px / 12 px en étroit), puis les deux ouvertures. L'écart sépare les
  deux natures sans ajouter de trait (Gestalt de proximité) ; il est FIXE et non `flex:1` — pousser
  les ouvertures au bord droit les éloignerait de tout sur grand écran et contredirait la règle
  « le cluster se groupe à gauche, le blanc part au bord droit ». Positions donc identiques quelle
  que soit la largeur.
  **SOUS 400 px (v4.30.0, audit externe — MESURÉ)** : la rangée exigeait 386 px — « Cons. » rogné
  de 11 px à 375 (iPhone SE/mini) et de 26 px à 360 (Android standard), sans défilement
  horizontal : pixels INACCESSIBLES, un débordement SILENCIEUX dans la zone de crise elle-même.
  Pixels rendus par COMPRESSION (gaps/paddings, recette v4.23.4 de la rangée d'identité — ~346 px
  à 360 après), JAMAIS par un renommage (règle « troncature du même mot ») ni une 2ᵉ ligne (la
  hauteur de crise est un coût permanent). Harnais : audit-doctrine « rangée de commandes sans
  rognage » (360/375/390) — toute addition à cette rangée se re-mesure là, comme la rangée
  d'identité se re-mesure à 360.
  **BASCULE DE MODE = SÉLECTEUR SEGMENTÉ, JAMAIS UN INTERRUPTEUR** : « Guidé » et « Statique » sont
  deux modes PAIRS, aucun n'est la négation de l'autre — contrairement à « Son activé/coupé », qui
  est une propriété binaire. Un bouton d'état y serait ambigu (dit-il où je suis ou où je vais ?),
  et l'erreur coûterait le remplacement de toute la vue de travail en pleine réanimation.
  **GÉOMÉTRIE DE LA PASTILLE — trois pièges cumulés (v4.25.1, retour d'usage)**, tous mesurés :
  (1) `.seg` porte `gap:8px` (la tab bar en a besoin, sa pastille compense par
  `translateX(calc(100% + 8px))`) — hérité tel quel, il décalait la pastille de 8 px ; et
  `.mode-seg` ayant la MÊME spécificité que `.seg`, déclarée bien plus bas, c'est `.seg` qui
  gagnait **par l'ordre** — d'où des règles passées par **`#modeSeg`** (un id l'emporte quel que
  soit l'ordre). C'est le **3ᵉ piège de cascade de ce type** dans le projet (cf. `.read-grid`
  v4.23.0, `.cbt-n` v4.23.5) : pour une GÉOMÉTRIE, ne jamais dépendre de l'ordre de déclaration.
  (2) `flex:1 1 0` NE SUFFIT PAS à égaliser deux libellés de longueurs différentes : `min-width:auto`
  recale chaque item sur son propre texte (mesuré : « Guidé » 64 px, « Statique » 81 px) — d'où une
  **grille `1fr 1fr`**, dont les pistes égales adoptent la largeur du plus exigeant.
  (3) Le fond de la pastille ne peut pas être `--surface` : il **s'inverse** d'un thème à l'autre
  (plus clair que la piste en clair, plus SOMBRE qu'elle en sombre — elle s'y lisait comme
  inactive). Registre de SÉLECTION (teinte `--primary-soft` + bordure `--primary`), lisible dans
  les deux sens de contraste. **(4) v4.29.0 — la GRAISSE ne change pas avec l'état** :
  `.seg-btn.on` en 800 contre 700 élargissait le mot, les DEUX libellés se décalaient à chaque
  bascule (retour utilisateur) — l'état est porté par la pastille + la couleur, graisse constante
  partout (vaut aussi pour la tab bar, qui passait de 600 à 800). **GLISSER LA PASTILLE (v4.29.0,
  HIG iOS, demande utilisateur)** : `bindSegDrag` — la pastille se laisse traîner au doigt (seuil
  6 px, un tap reste un tap), commit au RELÂCHEMENT seulement (≥ moitié du trajet — rien de lourd
  ne se re-rend pendant le geste), un drag n'émet jamais le click du bouton sous le doigt (garde
  `isTrusted` ; le commit programmatique passe). Posé sur `#modeSeg`, la tab bar `#tabSeg`
  Aides/Protocoles ET `#createSeg` : les trois sont des sélecteurs segmentés à pastille (pas de
  vraies tab bars iOS — le glisser y fait sens partout). La pastille suit le doigt MÊME sous
  reduced-motion (direct manipulation = le geste lui-même, pas un mouvement autonome) ; seul le
  rattrapage final passe par la transition CSS. Couvert par `scripts/audit-modeseg.mjs` : écart
  pastille/segment actif dans les DEUX thèmes + immobilité des libellés à la bascule + drag réel.
  `#modeSeg` vit hors de `main` : câblé UNE FOIS, il survit aux re-rendus — donc plus besoin de
  rejouer le glissement de la pastille (`.seg-replay` n'a plus lieu d'être ici).
  **`--ctrl-h`** (posée par `syncHdrScroll`, ÷ `zoomF()`) = hauteur de la rangée de commandes : le
  quai d'état s'y colle. Toute couche collante ajoutée en haut doit entrer dans `stickBase()`.
- **PLAN = UNE SEULE VUE, L'ÉCHELLE (v4.25.0, audit Plan/Statique)** — « Détails » (l'organigramme
  hybride) est SUPPRIMÉ. Mesuré : c'était la seule des trois vues à **recopier les étapes** (12
  listes affichées, contre 0 pour Échelle et Schéma) — elle rejouait donc la vue d'action au lieu
  d'être un synoptique, or un SD ECAM montre AUTRE CHOSE que l'E/WD, pas la même chose autrement
  disposée. Étant la vue PAR DÉFAUT, c'est elle qui faisait ressembler « Plan » à « Statique »
  (66 % de son contenu s'y retrouve, sections en plus). Supprimés avec elle : `ovPlanTreeHtml`, tout
  le FIL D'ANCÊTRES COLLANT (`ovPlanPin`, tops cumulés, chips injectés, z-ordre pdN — `ovPlanStick`
  reste en **no-op** : appelée depuis le défilement et les re-rendus), le sélecteur `data-plview`,
  `PLAN_VIEWS`/`currentPlanView`/`setPlanViewPref`/`state.ovPlanView`, le scroll par vue de v4.23.6,
  et ses règles CSS (`.pl-cols`, `.pl-br`, `.pl-bl`, `.pl-elbow`, `.pl-decwrap`, `.pl-nd*`,
  `.pm-views`, `.ovs-tgl`, `.read-seg`…). **NETTOYAGE ACHEVÉ SEULEMENT EN v4.31.1** — cette
  section affirmait la suppression faite alors qu'elle l'était à moitié, ce qui est la pire
  configuration : qui lisait AGENTS.md croyait le terrain propre. Étaient restés ~20 règles CSS
  avec 45 lignes de commentaires décrivant en détail un composant inexistant, deux `querySelector`
  qui ne pouvaient que renvoyer `null` (`.pl-nd[data-plgo]`), quatre branches de délégation
  `data-plfold` inatteignables, `ovPlanStick()` vide appelée depuis quatre sites, la démo
  `planDemo` de `design/build.mjs` qui PUBLIAIT le composant disparu (sept de ses classes sans
  aucune règle), et — plus grave — un contrôle d'`audit-doctrine.mjs` qui cliquait sur `.pl-nd` :
  ne matchant plus rien, il passait sans avoir rien testé, si bien que l'invariant « taper un nœud
  du plan ne démarre ni ne coche » n'était plus vérifié depuis v4.25.0. Leçon : une suppression
  annoncée doit être VÉRIFIÉE au grep (émissions hors CSS = 0), et un contrôle qui ne peut pas
  échouer ne prouve rien. **Le SCHÉMA n'est pas perdu** : il rejoint le menu ⋯ et
  s'ouvre en PLEIN ÉCRAN avec zoom (`openFlowFull`, visionneuse préexistante) — un accès direct
  chacun, comme l'ECP a une touche par page plutôt qu'un onglet à faire défiler.
  **NOMMAGE PAR LA FONCTION** : « Se repérer » et « Consulter » (deux verbes) au lieu de « Plan »
  (nom) + « Consulter » (verbe) ; **même glyphe ⤢** pour les deux, puisqu'elles font exactement la
  même chose — ouvrir une feuille plein écran. Abréviation sous 560 px : « Cons. », **troncature du
  même mot** (jamais un autre nom — cf. « Réf. », retiré en v4.23.5).
- **FEUILLE CONSULTER = UN DOCUMENT, PAS UN MENU (v4.25.0)** — toutes les sections sont **dépliées
  par défaut**. Audit : quatre sur cinq étaient repliées (216 px de titres pour ~380 px de vide), et
  la seule ouverte d'office était une COPIE de ce qui est déjà dans le flux. Mesuré, tout déplié
  tient en ~977 px, soit une chiquenaude de défilement — contre quatre taps et l'invisibilité
  totale. En QRH, la section amplifiée est un document qu'on FAIT DÉFILER.
  **ELLE NE PORTE QUE L'UNIQUE (v4.25.3, audit d'utilité)** : différentiels → schémas → documents
  → références → voir aussi. Surveillances et posologie en sont RETIRÉES — mesuré, elles pesaient
  **57 % de la hauteur** (451 px sur 790) alors qu'elles existent déjà ailleurs : les surveillances
  dans le flux (③) et en Statique, la posologie dans le flux, le rail (≥ 780) ET en Statique, soit
  QUATRE exemplaires. Ces copies repoussaient de ~450 px le contenu réellement unique : on faisait
  défiler ce qu'on avait déjà sous les yeux pour atteindre ce qu'on venait chercher — l'inverse du
  decluttering ECAM, qui montre ce qui manque et tait ce qu'on a déjà.
  **CE SONT LES DIFFÉRENTIELS QUI JUSTIFIENT LE BOUTON DU QUAI** : de la documentation seule irait
  au menu ⋯ ; le « ça ne colle pas » mérite un tap. C'est aussi pourquoi le nom « **Consulter** »
  est CONSERVÉ — « Documents » ou « Annexes » sous-vendrait les différentiels, et personne dont le
  tableau ne colle pas n'ouvrirait un bouton nommé « Documents » : le pire mode de défaillance
  serait un nom qui décourage l'usage qui compte.
  **INVARIANT — AUCUN BOUTON MORT** : `annexRowHtml` (qui conditionne AUSSI le bouton du quai) doit
  lister EXACTEMENT ce que la feuille contient. Sans ça, une fiche n'ayant que des surveillances et
  une posologie afficherait le bouton et ouvrirait une feuille VIDE. Couvert par
  `scripts/audit-consulter.mjs`. L'UNIQUE avant les COPIES (surveillances et posologie restent dans le
  flux, la feuille n'en porte qu'une copie), l'urgent avant la traçabilité : les différentiels sont
  le motif principal d'ouverture en cours de soin (« ça ne colle pas ») et le seul contenu clinique
  qu'on ne trouve nulle part ailleurs. **« Voir aussi » est CONSERVÉ** (décision utilisateur) bien
  qu'il relève de la navigation vers une AUTRE fiche plutôt que de l'amplification de celle-ci.
- **ACCUEIL « POSTE ACCÈS DIRECT » (v4.56.0, maquette 2c du canvas « Accueil bibliothèques »)** :
  les listes d'aides ET de protocoles partagent trois étages — tuiles **« Épinglée(s) ★ »**
  (libellé ACCORDÉ au type et au nombre, `cfg.pinnedLbl` — l'intitulé « Accès direct » de la
  maquette a été renommé sur demande utilisateur ; `qaPick` : les ÉPINGLÉES SEULES, décision
  « juste les favoris » ; aucune épingle → la section disparaît, jamais de remplissage par
  fréquence d'usage ; titre de tuile en 15 px borné à **3 lignes** + ellipse — 2 lignes
  tronquaient trop pour reconnaître la fiche, demande utilisateur « un peu plus de titre » ;
  `overflow-wrap:break-word`, pas `anywhere`, qui coupait « Anaphylaxie » en plein mot ;
  sous-ligne à 1 ligne ellipsée ; le nom accessible et l'info-bulle gardent le texte entier),
  **RÉPERTOIRE A→Z**
  (`azGroups`/`azLetter`, purs testés : lettre désaccentuée, hors A-Z → `#` rangé en fin ; tri
  alphabétique STRICT dans les groupes — l'épinglée a sa tuile, la hisser casserait la lecture
  d'annuaire) en rangées compactes `.dir-row` (< 640 px : liste à filets dans une carte par
  lettre), et **RAIL ALPHABÉTIQUE** `.azrail` (tap = saut, glisser = parcourir façon index iOS ;
  dès 2 lettres ; s'il ne tient pas en hauteur il DISPARAÎT — jamais de lettres coupées ni de
  cibles < 24 px ; en étroit il est FIXE, ancré entre `--hdr-h` et la tab bar — un centrage
  fenêtre passait sous l'en-tête à 320×640). Décisions utilisateur figées : la recherche RESTE
  dans l'en-tête (statique — le focus survit aux re-rendus, raccourci « / ») ; le filtre
  catégorie FILTRE (l'estompage de la maquette a été refusé) ; les rangées gardent épingle ☆,
  date COURTE (`fmtDateShort` — « Validation : » pèserait plus que la donnée à 11 px), statut en
  attente, « À revérifier », « À compléter » ; le COMPTE DE SESSIONS des cartes disparaît,
  remplacé par l'**HISTORIQUE GLOBAL** : `openSessHist()` sans argument = mode `'*'` de la
  fenêtre existante (rangée `data-sesshist` de la sidebar en large, lien `#histBtn` du pied de
  page en étroit — masqués à zéro session : aucun bouton mort ; l'entrée PAR FICHE du menu ⋯ est
  inchangée). En RECHERCHE : liste plate triée pertinence (épinglées > frecency > titre),
  extraits, pagination `LIB_PAGE` — le répertoire, lui, ne se pagine JAMAIS (le rail promet
  « A→Z sous le doigt », un « Afficher plus » ferait des lettres injoignables). La couleur de
  catégorie sur rangées/tuiles = pastille/liseré + NOM en toutes lettres dans la sous-ligne
  (jamais seule, SPEC crise §1). PIÈGES : le bouton-titre garde le NOM `.card-open` — quatorze
  harnais ouvrent une fiche par ce sélecteur ; le périmètre accueil d'`audit-a11y` est
  `.dir-wrap,.azrail` (ex-`.cards` : un sélecteur mort ferait passer l'accueil sans le mesurer,
  v4.31.1) ; la boîte du bouton-titre porte un padding 6px compensé (cible mesurable ≥ 24 px —
  le `::after` étendu ne se mesure pas) ; l'ancien composant `.card`/`.cards` est PURGÉ
  (émissions vérifiées au grep, démo `design/build.mjs` refaite — règle 14).
- **En-têtes V5** : rangée principale unique (`.id-row` : retour ‹, marque, recherche FIXE de
  l'accueil, badge de statut, Créer, thème, compte, + `#hdrCrisis` en crise). Le sélecteur de
  section vit dans la tab bar basse (< 780) ou la colonne gauche (≥ 780), jamais dans la barre.
  **Raccourci clavier (v4.31.0)** : « / » et Cmd/Ctrl+K focalisent la recherche — inerte dans un
  champ, sous une fenêtre ouverte, et hors accueil (la recherche n'existe que là).
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
  **FOCUS CLAVIER (v4.30.0, WCAG 2.2 § 2.4.11 « Focus Not Obscured », audit externe)** : le
  défilement déclenché par le focus est celui du NAVIGATEUR — `stickBase()` ne le voit jamais,
  seul `scroll-padding` le pilote. `html{scroll-padding-top:calc(var(--stick-top,64px)+8px)}` :
  sans lui, un Shift+Tab remontant déposait l'élément focalisé ENTIÈREMENT sous les couches
  collantes (238 px mesurés à 360 en session, dont l'étape critique « ⚠ RCP immédiate » —
  masquage TOTAL, interdit au niveau AA). Corollaire : `scroll-margin` s'ADDITIONNE au
  scroll-padding — l'ancien `scroll-margin-top:130px` forfaitaire de `.rt-panel` est ramené à
  6 px, sinon le panneau atterrissait ~130 px trop bas. Sonde dédiée dans `audit-a11y.mjs`
  (élément envoyé AU-DESSUS du viewport puis focalisé, masquage total = échec).
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
  l'auteur est conservé. `posoCardsHtml` a UN SEUL site d'appel, dans le flux (`renderRead`) —
  cette ligne disait « source unique partagée par le flux et la feuille », ce qui contredisait le
  paragraphe « FEUILLE CONSULTER » deux sections plus haut : v4.25.3 a précisément RETIRÉ la
  posologie de la feuille. Corrigé en v4.44.0, avec le commentaire du code qui portait la même
  affirmation. **Menu ⋯ (v4.5 ; ORDRE REFAIT v4.28.0, retour utilisateur)** : en lecture, toutes les
  actions secondaires vivent dans le menu ⋯ de la barre. **Ordre = logique ECAM E/WD → SD** :
  la CONDUITE EN COURS d'abord (⚡ Complications, Mode lecteur, Se repérer, Schéma, Consulter),
  puis le CYCLE DE VIE de la session (Répéter en exercice, Recommencer le parcours, Historique),
  puis la GESTION (Modifier, Versions, Dupliquer), puis les EXPORTS ; la rangée `danger`
  (Terminer…) ferme toujours la liste. Avant, « Modifier »/« Versions » — DÉSACTIVÉES pendant
  une session — trônaient en tête : deux rangées mortes au moment où le menu sert le plus.
  `setMoreMenu` NORMALISE les séparateurs (jamais en tête/queue, jamais deux de suite : un groupe
  conditionnel vide disparaît sans que l'appelant s'en soucie). **ICÔNES : jamais deux entrées
  d'un même menu avec le même dessin, ni deux dessins quasi identiques côte à côte** —
  « Historique des sessions » a reçu `archive` (boîte, distinct de l'horloge-flèche `history`
  gardée par Versions) et « Se repérer » a reçu `ladder` (rail + lignes indentées = l'Échelle
  elle-même ; l'ex-icône `plan` — nœud + deux branches, quasi identique à `flow` juste
  en-dessous — est SUPPRIMÉE). Couvert par `scripts/audit-lecteur.mjs`. **Pied de page nomade** : `#appFooter` (Installer l'app, version, pastille synchro,
  jauge de stockage) ne vit plus qu'en bas de la sidebar de l'accueil — il est DÉPLACÉ
  (`placeFooter`/`rescueFooter`), jamais recréé (écouteurs vivants) ; « Exporter mes données »
  est dans la fenêtre Compte, l'import dans le dialogue Créer.
- **Largeurs & échelles fermées** (consignes Claude Design, v5/6 — la présente section est la
  référence) : cadre `.app` FLUIDE (en-tête/pied pleine largeur partout), contenus
  plafonnés ET centrés par vue — accueil = sidebar 240 px + grille ≤ 1320 px (auto-fill
  minmax(300px,1fr), gap 12 px, 1 colonne < 640) ; fiche = checklist ≤ 860 px (≥ 1200) + rail
  320 → 360 px (chiffres 34 px) ; protocole ≤ 780 px partout ; éditeurs = colonne d'édition
  FLUIDE (1fr) + aperçu sticky 320 px dès 1000 px — l'éditeur de PROTOCOLE, lui, est bien plafonné
  (780 px + aperçu 360). **Cette ligne affirmait « éditeurs alignés sur leur vue de lecture
  (fiche ≤ 860 px) » : c'était FAUX, et mesuré tel quel (1400 px → 900+320, jamais 860+360).** La
  règle du palier 1200 listait bien `body.view-edit`, mais le bloc 1000 la reprend
  2 293 lignes plus bas à spécificité ÉGALE (`:is()` prend le max de ses arguments) et gagne par
  l'ORDRE — 4ᵉ incident de ce type après `.read-grid` (v4.23.0), `.cbt-h` (v4.23.5) et
  `.mode-seg` (v4.25.1). Le membre inopérant a été RETIRÉ de la règle du palier plutôt que
  réaffirmé plus bas : aligner l'éditeur sur 860+360 serait un changement VISIBLE, à décider
  séparément. Règle générale : pour une GÉOMÉTRIE, ne jamais dépendre de l'ordre de déclaration —
  passer par un `#id` ou vérifier la position dans la feuille. L'accueil ≥ 780 est une COQUE FIXE (`body.view-home` : 100dvh, overflow hidden ;
  seuls `.home-side` et `.home-main` défilent — la sidebar ne bouge jamais à la bascule de
  section). Breakpoints : **360** / 400 / 430 / 560 / 640 / 780 / 900 / 1000 / 1200 px — pas de
  nouveau palier sans décision explicite (360 et 400 étaient DÉJÀ dans le code, décidés en v4.30.0
  et v4.43.0 ; c'est cette liste qui n'avait pas suivi). En-têtes (SPEC §5) : marque uniquement sur l'accueil ;
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
- **PORTÉE D'UNE ACTION DE REPRISE (v4.23.8, question utilisateur)** : deux gestes voisins ne
  doivent PAS porter le même nom. **`↺ Refaire`** = UN bloc (nouvelle carte au bout du journal, le
  reste intact) ; **« Recommencer LE PARCOURS »** = TOUT le chemin effacé, retour au bloc de départ.
  L'ancien libellé « Recommencer », seul, laissait croire à un geste local alors qu'il était global
  (AC 120-71B : une action dit exactement ce qu'elle fait). Ce bouton FLOTTAIT en tête du journal,
  rattaché à rien : il vit désormais dans le **menu ⋯**, avec les autres actions de portée globale.
  Justification : ECAM réserve l'affichage permanent (E/WD) à ce qui sert la conduite EN COURS et
  appelle le reste à la demande (SD) ; AC 120-71B veut que la checklist montre ce qui aide à
  exécuter l'ÉTAPE COURANTE — « repartir du début » ne conduit rien. La règle ECAM de constance
  positionnelle n'est pas enfreinte : elle exige qu'un contrôle soit TOUJOURS AU MÊME ENDROIT, ce
  que le menu garantit mieux qu'un bouton flottant. **Le geste « maintenir » n'existant pas dans un
  menu, la protection passe par `confirmDlg` en registre danger** (doctrine v4.3.1) et l'annonce dit
  ce qui est effacé ET ce qui est CONSERVÉ (chrono, minuteurs, compteurs, compte-rendu) — une action
  destructive s'annonce AVANT le choix. `restartCourse(f)` est le point d'entrée unique des deux
  modes. CSS retiré avec le composant : `.ov-controls`, `.btn.btn-hold` et son exception dans
  `holdToReset` (les seuls « maintenir » restants sont `.tm-reset`/`.cn-reset`).
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
  disparaît d'un tap (✕) ou au démarrage de la session suivante. **✕ ANCRÉ EN HAUT À DROITE
  (v4.29.2)** : le ✕ était invisible de v4.16.3 à v4.23.2 (`.notice-x` absolute sans ancêtre
  positionné) ; le contournement v4.23.2 (« dans le flux ») le laissait atterrir AU MILIEU de la
  carte dès qu'elle passait en plusieurs lignes sur petit écran (retour utilisateur). Le geste
  standard est rétabli proprement : la carte est `position:relative`, le ✕ ancré `top/right`,
  et le `padding-right:40px` de la carte lui réserve la place à toutes les largeurs. **La carte disparaît aussi quand SA session est supprimée de l'historique** :
  garde posée AU RENDU (`!sessions.some(...)`), pas dans chaque chemin de suppression — il y en a
  trois (session seule, suppression de fiche, purge) et un quatrième serait oublié ; sans elle, le
  bouton « Compte-rendu » menait à un rapport introuvable — le débriefing est
  DISPONIBLE, jamais imposé (ECAM).
- **Marqueur d'étape hors du champ (v4.3.0)** : dans les éditeurs, le préfixe `⚠ `/`△ ` ne vit
  plus DANS l'input (il était effaçable à la main = changement de type accidentel) — champ =
  texte nu, rangée **encadrée** au registre, préfixe re-posé par le handler (la CHAÎNE stockée
  garde le préfixe : format v3 inchangé). Les repères posologiques ont la même bascule ⚠ par
  bouton (le signe est intapable au clavier). **Le guide rouge/ambre de l'éditeur de blocs
  (`.crit-guide`) est un `<details>` (v4.31.0, audit externe)** : ouvert tant que l'utilisateur
  ne l'a pas replié, puis son CHOIX persiste (clé `ac-cg-folded`, listener `toggle` global en
  capture — l'événement ne bulle pas) : un utilisateur régulier ne relit pas la leçon à chaque
  session d'édition, un nouveau la voit d'office.
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

- **PARTAGE DE SESSION EN DIRECT (v4.46.0 → v4.49.0)** — un soignant ouvre le partage de la session
  qu'il déroule ; un collègue **présent auprès de lui** rejoint par un code à 8 caractères montré à
  l'écran (porté par un QR, alphabet de 32 symboles sans `0/1/I/O`) et voit la même checklist se
  remplir. **CE N'EST PAS UN PARTAGE D'AIDE COGNITIVE** — les bibliothèques partagées font cela,
  avec adhésions et RLS : ici la portée est **une** session, elle meurt avec elle, l'invité ne
  conserve rien, et `auth.uid()` ne sert QU'À L'ATTRIBUTION, jamais à l'accès (qui vient toujours du
  secret de participant). Il n'existe donc **qu'un seul chemin d'accès à auditer**. Doctrine :
  AC 120-71B §5.2.2.1 — « one crewmember reading the checklist and the second confirming and
  responding ». La co-édition symétrique **n'existe dans aucune source** ; toutes décrivent une
  asymétrie, et Airbus la garantit par le MATÉRIEL (un seul ECAM Control Panel). La « vue dégradée »
  de l'invité n'est pas un compromis, c'est la forme canonique.
- **CE QUI VOYAGE — un vocabulaire FERMÉ, et un seul point d'émission.** `shareSnap(R,flowEnded)` et
  `shareDiff(a,b)` sont PURES et testées : deux instantanés donnent une suite d'évènements
  (`check`, `uncheck`, `verify`, `gap`, `counter`, `timer_arm`, `timer_stop`, `mark`, `mark_void`,
  `nav`, `flow_end`, `session_start`, plus `detach`/`offline_mark`). L'émission est accrochée à
  **`persistLive`** — un seul crochet, et non les **soixante** verbes de mutation recensés (41
  attributs `data-*` en vue lecture + 19 contrôles à `id` sans aucun `data-*`) : ce qui est couvert
  par l'enregistrement local l'est mécaniquement par le partage, et toute mutation ajoutée demain
  aussi. **`shareRebase()` après application d'un lot distant**, sans quoi ce qu'on vient de
  recevoir serait re-diffé et RENVOYÉ — un écho qui compterait double au compte-rendu.
  **AUCUN TEXTE LIBRE (règle 15)** : le libellé d'un repère de journal n'est pas dans le format —
  seuls `{id, t, ref, voidAt}` voyagent —, `localInfo` et les images sont retirés de la fiche, et
  `SHARE_TRAVELS`/`SHARE_LOCAL` classent explicitement chaque champ (un test échoue si un champ de
  `snapshotSession` n'est classé nulle part). `flowEnded` EST un état de session et voyage ; `nav`
  et `navSeq` voyagent **indissociables** — les clés de cochage valent `visite:bloc:index`, et
  transmettre l'un sans l'autre orphelinerait toutes les coches.
- **RÔLES ET CAPACITÉS — LA LIGNE PASSE SUR LA DESTRUCTION, PAS SUR LA HIÉRARCHIE (v4.55.0,
  décision utilisateur).** Elle passait sur « conduire ou suivre », et c'était une MAUVAISE LECTURE
  de la source : AC 120-71B §5.2.2.1 décrit une répartition de la PAROLE, et dans ce modèle **c'est
  celui qui LIT qui fait avancer la liste** — le lead est celui dont les mains sont prises. La SFAR
  (« le lecteur : sa seule tâche est de lire et de GUIDER »), l'ECAM (le pilot monitoring actionne
  l'ECP, le pilot flying pilote) et surtout **McEvoy 2014** — 99,5 % contre 70 %, la meilleure
  donnée du dossier, où **le lecteur tenait l'UNIQUE appareil** — disent tous la même chose : la
  conception précédente empêchait exactement la configuration la mieux documentée.
  Le critère était d'ailleurs DÉJÀ ÉCRIT dans le schéma pour `mark_void` (« annuler CONSERVE,
  décocher DÉTRUIT »). Il vaut désormais pour tous : **ouvert** = cocher, constater, écart,
  incrémenter, armer **et arrêter** un minuteur (l'`elapsedMs` est conservé), poser/annuler un
  repère, **naviguer, choisir une branche, terminer un bloc, entrer sur une complication** — tout
  cela est append-only ou réversible. **Réservé** = décocher (efface une information), remettre à
  zéro (efface un décompte que personne ne restitue), terminer le partage, dater le début du soin.
  Cas d'usage qui a tranché : le médecin partage POUR SE LIBÉRER les mains ; un scribe qui ne peut
  pas relayer « pause le minuteur, il reprend un rythme » l'oblige à reprendre son téléphone.
  **L'OBJECTION D'AMBIGUÏTÉ** (§5.5, « qui fait quoi », qu'Airbus supprime par un ECP unique) reçoit
  la réponse constante du projet : **on n'interdit pas, on ANNONCE** — une avance venue d'en face
  pose une mention « avancé par ‹rôle› » sur la carte courante, à côté de « Vous êtes ici ».
  **LE MENU ⋯ SE REFAIT SANS RE-RENDRE (v4.55.2)** : ses rangées sont construites AU RENDU, que la
  règle 3 interdit sur évènement distant — « Partage en cours (n) » restait donc figé au compte du
  moment où la fiche a été ouverte, et « Prendre la main » ne paraissait JAMAIS, puisqu'une offre
  arrive par le réseau. On mémorise le CONSTRUCTEUR (`_moreBuild`), pas seulement son résultat, et
  `shareMenuRefresh()` le rejoue : le menu vit dans l'en-tête, hors de `main`, donc pas une ligne
  de la checklist ne bouge. La rangée « Prendre la main » vit dans le menu de L'INVITÉ — elle avait
  été posée dans celui de l'hôte, où sa condition ne pouvait jamais être vraie.
  **UN LIEN MORT REFUSE TOUT, ET LE DIT** (`MUTE_SEL` + `SHARE_DEAD`) : un invité coupé pouvait
  encore incrémenter un compteur ; le geste ne partait pas et RIEN ne le lui disait — mot pour mot
  le pire mode de défaillance du plan. `detached` n'en est PAS : celui qui a poursuivi seul
  travaille sur SA session, et lui refuser ses gestes lui retirerait le repli hors dispositif qu'on
  vient de lui donner (AC 120-64 §9.a).
  **LES DEUX LISTES SONT LA MÊME RÈGLE EN DEUX LANGAGES** (`SHARE_KINDS_ANY`/`_LEAD` et
  `share_kind_allowed`) : leur divergence est SILENCIEUSE et asymétrique — client plus permissif, un
  geste part et le serveur le jette sans que l'auteur le sache ; serveur plus strict, un geste
  légitime est refusé sans raison lisible. `check-sql.mjs` les compare désormais à chaque commit.
- **RÔLES ET CAPACITÉS — le scribe AJOUTE, il ne DÉFAIT pas.** `SHARE_KINDS_ANY` (cocher, constater,
  signaler un écart, **incrémenter** un compteur, **armer** un minuteur, poser et annuler un repère)
  contre `SHARE_KINDS_LEAD` (décocher, avancer, terminer, choisir une branche, **arrêter** ou
  remettre à zéro, passer la main). La distinction n'est pas arbitraire : ajouter est additif et
  réversible par le journal, remettre à zéro détruit un décompte que personne ne peut restituer.
  **JAMAIS PAR MASQUAGE** : masquer `#modeSeg`/`#planBtn`/`#refBtn` replie `#crisisCtrl` et fait
  remonter le contenu clinique de **46 px** — sous les yeux de quelqu'un qui n'a rien demandé, et
  sur évènement DISTANT si le rôle change. La boîte reste, la géométrie est identique refus ou non
  (mesuré ≤ 1 px), et le refus s'annonce sur `#srLive` (règle 11 : aucune notification flottante).
  **UNE SEULE LISTE de verbes** (`LEAD_ONLY_SEL`) consommée par le CSS (`body.share-scribe`) ET par
  une garde déléguée en capture (`bindLeadGuard`) ; un contrôle du harnais lit la liste **depuis le
  script**. Deux gestes dépendent de leur DIRECTION et ne peuvent pas être bridés en CSS —
  `data-ck` porte cocher *et* décocher, le minuteur armer *ou* arrêter : gardés dans les handlers,
  et pour le cochage par le prédicat **unique** `canToggleStep(on)` appelé aux **deux** copies du
  cœur, celles qui avaient divergé en v4.42.0.
- **L'INVITÉ NE DÉPOSE RIEN, ET C'EST UNE DÉCISION DE DÉMARRAGE.** Mesuré avant correction :
  `index.html#j=CODE` déposait **3,17 Mo** (deux caches dont pdf.js), une base IndexedDB, quatre
  clés `localStorage`, un service worker, et appelait `navigator.storage.persist()` — **avant** que
  le premier mot de la notice puisse s'afficher. `shareBootDecide()` tranche donc AVANT `load()` :
  code sur appareil vierge → backend **mémoire**, aucun worker, aucune persistance demandée, écran
  d'entrée **à la place** de l'application. `openRead(id)` est inutilisable ici (il cherche la fiche
  dans `fiches`, où elle ne doit JAMAIS entrer, puis appelle `bumpUsage` qui écrit chez l'invité) :
  chemin distinct `openSharedFiche()`. `ensureStarted` **refuse de démarrer** chez un invité — c'est
  le point exact où l'étanchéité se joue, sans quoi sa première coche créerait un enregistrement de
  session sur un téléphone emprunté. Le fragment `#j=` est retiré de l'historique immédiatement
  (`_histArm()` fait un `pushState` **sans URL**, donc recopie l'URL courante, fragment compris).
  **Un seul message de refus** pour les six causes que le serveur ne distingue pas : les séparer
  ferait de `share_join` un oracle (« ce code existe », « la session est pleine »).
- **CONTINUER SEUL — la trace remonte, l'état NON (AC 120-64 §9.a).** Si le réseau ne revient pas,
  l'invité bascule sa copie en session locale normale. `Share.detach()` est un ACTE, jamais un
  accident : le serveur le date (`detached_at`), ce qui donne à l'hôte l'heure à laquelle il a cessé
  d'être suivi. **La file en attente est CONVERTIE, pas jetée** — chaque geste devient un
  `offline_mark` qui rejoint le journal de l'hôte en **annexe**, à sa place chronologique, INERTE
  (ni champ ni bouton : on ne corrige pas le relevé d'un autre). **L'état ne fusionne JAMAIS**, et
  la raison est structurelle et non doctrinale : après la bifurcation, les numéros de visite sont
  mintés **indépendamment** des deux côtés — « la visite 6 » de l'un et celle de l'autre désignent
  deux passages différents. Ce n'est pas un conflit arbitrable, c'est une **collision d'espace de
  noms**, et fusionner produirait un résultat non pas discutable mais FAUX ET PLAUSIBLE. Un
  participant **coupé** par l'hôte, lui, ne rapporte rien : la coupure est une décision, pas une
  panne. Distinguer `Share.freeze(status)` (le lien meurt, l'écran survit, le mode `guest` reste)
  de `Share.stop()` (l'écran est quitté) : à l'instant où l'hôte coupait, `crisisOnScreen()` tombait
  et déversait jusqu'à 8 snackbars retenues sur la checklist que le collègue tient encore en main.
  **`crisisOnScreen()` est LE prédicat unique** de « une crise est à l'écran » (quai, mise en
  attente des banderoles, masquage de la méta) — deux critères concurrents finiraient par diverger.
- **LE SERVEUR EST L'AUTORITÉ, PAS LE CLIENT.** Cinq règles écrites dans `schema.sql`, chacune
  réparant une faille identifiée : (1) **aucune identité en paramètre** — l'acteur est DÉDUIT du
  secret présenté, sinon tout porteur du code signerait du nom d'un autre, or l'attribution EST le
  contrôle demandé ; (2) **un secret par participant**, tiré par `gen_random_bytes`, seul son
  SHA-256 stocké — c'est ce qui rend la coupure EFFECTIVE, sans quoi le coupé rejoindrait avec le
  même code ; (3) **fenêtre d'admission de 120 s** et code **consommé** à la première jointure ;
  (4) **append-only strict** — l'état est un PLI calculé par chaque client (doctrine du journal de
  parcours), un état matérialisé imposerait un verrou derrière lequel **l'hôte attendrait ses
  propres écritures** ; (5) **liste BLANCHE des 14 champs de fiche, côté serveur** (v4.49.0) — elle
  n'existait qu'en JavaScript, et un appel REST direct la traversait avec `images` et `localInfo`
  (les téléphones de renfort et de régulation). Liste blanche, jamais noire : une liste noire oublie
  ce qu'on ajoutera demain. La séquence est allouée **sous verrou de ligne, par partage** — surtout
  pas un `bigserial`, qui alloue à l'INSERT et non au COMMIT : un évènement validé en retard
  resterait sous le curseur, définitivement et en silence. Purge auto-exécutoire **en tête de chaque
  RPC** (l'hébergement est statique : personne ne lance de tâche planifiée, et une durée annoncée
  sans mécanisme serait fausse au registre). `is_approved()` refuse le rôle `anon` **et** les JWT
  anonymes (qui portent un `auth.uid()` non nul et retombaient sur `'approved'`).
- **TROIS RÉGIMES D'APPLICATION, ET ILS NE SE CONFONDENT PAS (`SHARE_APPLY`)** : `live` = chirurgie
  pure dans `main` ; `anchored` = le journal est reconstruit, donc **ancré** (`keepAnchor`) et
  **annoncé**, appliqué tout de suite ; `deferred` = attend un geste local. Une seule ligne rangeait
  `anchored` et `deferred` dans la même file — **jamais vidée** : l'invité voyait les coches du bloc
  courant et plus rien ensuite, **le miroir se figeait au premier « Continuer » de l'hôte**. Deux
  pièges à connaître si l'on y retouche : `state.nav` est un **ALIAS** du tableau de `Runtime`
  (`bindStateToRuntime`) — lui affecter un tableau neuf casse l'alias en silence et l'application
  lit alors deux navigations différentes selon l'endroit ; et `Runtime.seq` doit être relevé au
  maximum des numéros reçus, sinon une visite locale ultérieure réutiliserait un numéro déjà pris,
  donc **deux passages partageraient leurs clés de cochage**.
  **LE LECTEUR INVERSE LE RÉGIME** : sa clé d'étape est calculée AU CLIC depuis `state.nav`, jamais
  depuis le DOM peint — une navigation distante arrivant entre le `pointerdown` et le `click` ferait
  cocher **la mauvaise étape**, et le compte-rendu l'imprimerait comme réalisée. Tant que
  `#readerMode` est ouvert, une navigation distante est donc REFUSÉE, mise en attente, et
  **annoncée sur place** (`rmBanHtml`, registre INFORMATION) ; `rmResume` l'applique au geste local.
  Le repaint du lecteur sur évènement distant passe par `readerRepaint` (position CONSERVÉE), jamais
  par `_rmSync`, qui repositionne le curseur et ferait sauter le lecteur sous ses yeux.
- **JOURNAL RÉFÉRENTIEL (v4.52.0) — UN REPÈRE VOYAGE COMME UNE RÉFÉRENCE, JAMAIS COMME UN MOT.**
  `ref` n'existait que pour les compteurs : un repère posé par l'hôte s'affichait « Action 3 » chez
  l'invité — l'heure juste, le mot manquant. **QUATRE SOURCES** cumulatives : la FICHE elle-même
  (minuteurs, compteurs, étapes, repères posologiques — toute aide apporte donc son vocabulaire
  sans qu'on déclare rien), un NOYAU UNIVERSEL livré (`TAG_CORE`, 9 entrées), le VOCABULAIRE
  PERSONNEL avec alias (`data.prefs.tags`, déjà synchronisé, édité **à froid** dans la fenêtre
  Compte), et **rien du tout** — le cas nominal : « Noter l'heure » reste UN TAP qui capture
  l'heure, ce qui compte cliniquement, sans dépendre d'aucun vocabulaire. Pire cas d'un vocabulaire
  incomplet : un repère non étiqueté côté partagé, et le mot exact EN LOCAL chez celui qui l'a tapé.
  **« AUTRE » N'EST PAS DANS LE NOYAU** : l'absence de référence EST « autre », et une étiquette
  qui ne distingue rien n'apprend rien à qui relit.
  **LA RÉSOLUTION ÉCHOUE PROPREMENT** — `tagLabel` rend `null` (fiche d'une autre version, étape
  supprimée, étiquette effacée) et le repère retombe sur « Action n », jamais sur un mot inventé :
  c'est CETTE garantie qui autorise à faire voyager des références.
  **ON RÉORDONNE, ON NE FILTRE JAMAIS** (`tagRank`, machinerie de `posoScore`) : un faux positif
  coûte un rang, un faux négatif coûte un mot au moment où on le cherche. Les ALIAS sont notés
  comme le libellé — c'est tout l'objet du champ (« mru » doit trouver « Médecin régulateur »).
  **LA RÈGLE 15 VAUT AUSSI À LA RÉCEPTION** : aucun `label` n'est lu d'un payload distant. La ligne
  qui le faisait était inoffensive entre deux clients de cette version, mais c'était une PORTE —
  un client modifié aurait affiché un mot arbitraire sur l'écran d'en face.
  **PAS DE FENÊTRE POUR CHOISIR** : la règle 11 les interdit pendant un soin. Les propositions sont
  une rangée de chips SOUS la ligne, et le journal vit en fin de rail — ce qui apparaît pousse vers
  le bas, jamais vers le haut. Une étiquette PERSONNELLE se résout sur les appareils du même compte
  seulement : pendant un partage elle est marquée « · vous seul », parce que la taire laisserait
  croire à un mot partagé.
- **PASSATION DE LA MAIN — TROIS TEMPS, ET AUCUN ÉCRAN NE CHANGE SEUL (v4.54.0).** Le scribe ne
  conduit pas ; sans passation, quelqu'un qui a BESOIN de conduire n'a aucun recours, et
  l'asymétrie devient une impasse. Modèle : AC 61-115 « Positive Exchange of Flight Controls » —
  l'hôte **propose** (`handoff {to}`), l'autre **prend** (`handoff {take}`), et le changement de
  rôle vaut confirmation. **`handoff` est ouvert aux DEUX rôles**, côté client comme côté serveur,
  et ce n'est pas un relâchement : il ne change AUCUN état, il ANNONCE. Le rôle lui-même est un
  UPDATE de `session_participants` que la RLS réserve au propriétaire du partage — la frontière de
  sécurité est là, sur l'écriture du rôle, pas sur l'annonce ; le réserver au lead aurait interdit
  à l'invité d'accomplir le temps que la doctrine exige de LUI. **Le rôle ne vient JAMAIS d'un
  évènement** (il serait alors auto-attribuable), toujours de la lecture suivante. **L'offre se dit
  dans le QUAI** (jeton `offert`, position constante) **et le geste vit dans le menu ⋯** — doctrine
  de « Recommencer le parcours » : une rangée qui apparaîtrait dans la colonne d'action ferait
  remonter le contenu clinique sur évènement DISTANT. L'inscription est **automatique** à la
  prise : l'hôte a consenti en proposant, et lui redemander confirmation ajouterait un quatrième
  temps à un échange qui en compte trois. `grantLead` **rétrograde d'abord, promeut ensuite** — dans
  l'autre sens, une coupure entre les deux laisserait DEUX leads ; ici le pire cas en laisse ZÉRO,
  dégradé mais non ambigu (invariant 1).
- **HISTORIQUE DE SESSIONS SYNCHRONISÉ (v4.54.0) — L'INVARIANT LEVÉ, ET CE QUI LE REMPLACE.**
  « Les sessions vivent en local, jamais synchro » était une propriété ÉCRITE dont le mode
  EXERCICE tirait sa garantie de non-contamination. Elle est levée **sur opt-in, défaut fermé**
  (bascule dans la fenêtre Compte, par UTILISATEUR — l'activer ici et la découvrir éteinte ailleurs
  serait la pire des surprises). Ce qui la remplace : **seules les sessions ARCHIVÉES montent**
  (`live:false` — une session vive resynchronisée serait un second canal de partage, sans code,
  sans rôle et sans péremption) ; **l'exercice est ségrégé par une COLONNE**, plus par la localité ;
  **`verified`/`vgaps` ne montent pas** (décision d'étape) mais leur absence est **DITE** — un
  drapeau `vElsewhere` fait écrire au compte rendu distant « son détail reste sur l'appareil qui
  l'a produite », car une trace absente qui ne s'annonce pas se lit « aucune vérification n'a été
  faite » ; **`data` accepte dès aujourd'hui `{v:2, enc:<blob>}`**, seule décision de forme
  irréversible une fois des données en place. Suppression = **pierre tombale** dès que la synchro
  est active (sinon la session effacée revient au pull suivant), suppression franche sinon.
  **CE QUI L'A FAIT ÉCHOUER À LA LIVRAISON (v4.54.2)** : `_pushTable` ne pousse que les objets
  portant `dirty`, et **aucun site n'en posait sur une session** — la table existait, les politiques
  étaient vertes, la bascule s'allumait, et pas une ligne ne partait. Le marquage vit désormais au
  point d'étranglement de l'ÉCRITURE (`_putSessionSafe`), comme l'émission du partage vit dans
  `persistLive` : toute mutation ajoutée demain sera couverte sans qu'on y pense — et la pierre
  tombale de `deleteSession` y passe aussi, sans quoi la doctrine « ici, et nulle part ailleurs »
  serait fausse dès la ligne où elle est écrite. `updatedAt` s'y pose **en même temps** que
  `dirty` : posé seul, `dirty` ferait gagner inconditionnellement la copie distante à la résolution
  LWW (`savedAt > 0` toujours vrai) et **effacerait la trace do-verify de chaque session à la
  première synchro**. Ne jamais les séparer.
  **LE RATTRAPAGE NE SE GARDE PAS SUR UNE TRANSITION** : qui a activé l'option quand elle ne
  poussait rien a déjà la clé à « 1 » et ne reverra jamais le passage éteint→allumé — le correctif
  raterait donc exactement les personnes qui ont signalé le défaut. Garde = une clé DURABLE
  (`ac-sess-backfilled`), plus un `Sync.schedule()` après le balayage : quand l'option est apprise
  par le PULL, `_pushSessions` de la même passe est déjà sortie par son garde d'entrée.
  Harnais : `scripts/audit-historique.mjs`.
- **LE BILLET DE REPRISE (`sessionStorage`)** — un onglet mobile meurt tout seul, et l'invité
  perdait sa participation SANS RETOUR (rien n'était persisté, et son code est consommé). Le billet
  ne porte que l'identifiant du partage et le secret : **aucune donnée clinique**. Sa portée est
  *cet onglet, cette navigation* — effacé à la fermeture, jamais partagé, hors IndexedDB et hors
  `localStorage` : l'invariant d'étanchéité est tenu là où il compte, rien de DURABLE sur le
  téléphone d'un tiers. Il survit à `freeze` (le lien meurt, l'écran reste) et meurt avec `stop`
  (l'écran est quitté). `share_pull` ne renvoie la fiche **que sur une reprise complète**
  (`p_since = 0`) : les sondages ordinaires n'ont aucun besoin d'un instantané de plusieurs dizaines
  de kilo-octets toutes les deux secondes.
- **CE QU'ON NE FAIT JAMAIS** : (a) un `render()` sur évènement distant — application chirurgicale
  ou ancrée seulement, jamais un rendu complet ; (b) recalculer la condensation `ovPresList` sur un évènement distant — rien ne mute
  au-dessus ; (c) attendre un appel réseau du partage dans un chemin d'interface (**règle 15**) ;
  (d) loger un contrôle dans le quai — il réécrit son `innerHTML` une fois par seconde, et un tap y
  est AVALÉ dans 13 % des cas, mesuré identique sur les deux moteurs ; (e) ajouter un segment au
  quai — l'insertion déplace le segment d'alarme de 45 à 57 px selon la largeur, sur évènement
  distant, ce que la constance positionnelle ECAM interdit ; le jeu de jetons est **fermé**
  (`main`, `suit`, `⇄n`, `figé`, `coupé`, `fini`, `seul` — 8 caractères maximum), et **le lien
  REMPLACE la main** quand il n'est plus nominal, parce qu'alors le rôle n'est plus CONNU :
  l'afficher serait la donnée périmée présentée comme vivante (danger n°2 du palmarès ECRI 2015).
  Harnais : `scripts/audit-partage.mjs` (deux pages, bus en processus, les deux moteurs) et
  `scripts/audit-qr.mjs` (décodage par CoreImage de l'image **réellement peinte**, macOS seulement,
  avertit sans échouer ailleurs).

## Périmètre réglementaire
L'app est un **support de contenu** rédigé et validé par l'utilisateur, sans calcul ni
recommandation individualisée : voir `docs/deploiement-et-conformite.md` (§ 2, statut
non-dispositif-médical). Toute fonctionnalité qui produirait une sortie individualisée
(ex. calcul de doses) doit être évaluée au regard de ce statut **avant** développement.

**Le partage de session a été passé à la grille explicitement** (§ 2, sous-section dédiée) : il ne
calcule rien, il **recopie** un état d'un écran à l'autre — qualification MDCG 2019-11
« communiquer ». La ligne à ne pas franchir est nommée : le jour où le partage **déduirait** quelque
chose de l'état partagé (score d'adhérence, alerte « étape non cochée depuis n minutes », suggestion
de reprise), la qualification serait à rouvrir. Et **ne jamais présenter le partage comme un outil
de supervision ou de contrôle de qualité** : ce vocabulaire suggère une évaluation par le logiciel.

**Le registre RGPD est un document opposable, et il est à jour** : `docs/deploiement-et-conformite.md`
§ 3 et surtout **§ 3.1**, qui énumère ce qui sort de l'appareil (les 14 champs de fiche, les
références, l'identifiant opaque + le rôle déclaré), les durées mesurées (fenêtre 120 s, partage 3 h
par défaut borné à 12 h, purge 30 min après expiration) et ce qui ne sort jamais. **Il doit rester
cohérent avec la notice affichée à l'invité** (`#joinScreen`) : les deux évoluent ensemble, ou
aucun.

## Se repérer dans `index.html` (monofichier, ~14 400 lignes)
Le fichier s'ouvre sur un **grand commentaire d'architecture** (objectif, règles de conception,
modèle de données, règles de sécurité) : le lire en premier. Ensuite, dans l'ordre.

> **Le tableau ci-dessous est un RÉSUMÉ, pas un index** : il décrit une vingtaine de sections sur
> les **57** bannières `/* ===== … ===== */` du fichier, et volontairement sans numéros de ligne —
> ils seraient périmés au commit suivant. Pour l'index EXACT et à jour, une commande :
>
> ```bash
> grep -n '^/\* ===== \|^  /\* ===== ' index.html
> ```
>
> Découpage global : CSS ≈ lignes 273-3379, coque HTML statique ≈ 3381-3697 (dont **21 fenêtres
> modales** déclarées en dur — `grep -c 'class="ai-modal' index.html`, toutes auditées par
> `audit-a11y.mjs` —, plus deux surfaces plein écran qui n'en sont pas : `#readerMode` et
> `#joinScreen`), JavaScript ≈ 3699 à la fin.

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
| Partage de session | `Share` (sondage REST, cadence adaptative, file hors-ligne, horloge de Cristian), noyau PUR `shareSnap`/`shareDiff`/`shareFold`/`shareCan`, application chirurgicale `SHARE_APPLY`/`sharePaintLive`, décision de démarrage `shareBootDecide` + écran `#joinScreen`, fenêtre d'appariement `#shareModal` et encodeur QR maison. Le serveur (`supabase/schema.sql`, section « partage de session ») est l'autorité : liste blanche des champs, secret par participant, code consommé, append-only, purge |
| Accessibilité | gestion centralisée des modales (focus, Échap, Tab ; v4.21.0 : verrou du défilement de fond `_bgLock`/`_bgUnlock` + `overscroll-behavior:contain` sur `.ai-modal`, position restaurée au pixel à la dernière fermeture ; **TECHNIQUE CHANGÉE v4.29.9** : le verrou est `overflow:hidden` sur `html` ET `body` (classes posées sur LES DEUX éléments), plus JAMAIS `body{position:fixed;top:-scrollY}` — sur iPhone, un body fixé RÉTRÉCISSAIT le rendu des fenêtres fixées de ~60 px en bas [« bande morte », dossier v4.29.x prouvé à la règle visuelle : accueil sain, fenêtre coupée dès le verrou] sans qu'AUCUNE mesure web ne le voie, et la bande était MASQUÉE depuis v4.23.3 par le fond peint sur html ; ne pas réintroduire de position:fixed sur body). **v4.23.0** : une fenêtre marquée `.sheet-full` (OPAQUE et plein écran, ex. feuille Plan) verrouille le fond à **TOUS les pointeurs** (`body.modal-full`) — la restriction au toucher n'existe que parce que figer `body` au pointeur fin décale le fond visible AUTOUR d'un petit dialogue ; une feuille opaque ne laisse rien voir du fond, et sans verrou la page continue de défiler derrière (constaté sur ordinateur) |
| Mode test | hook `?__actest` : expose les fonctions pures pour `tests.html` |
