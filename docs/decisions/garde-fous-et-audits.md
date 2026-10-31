# Garde-fous et audits — le détail (extrait d'AGENTS.md, v5.57.2)

> Contenu repris **À L'OCTET** depuis la section « Avant chaque commit » d'AGENTS.md (même patron
> que le découpage v5.10.3) — aucune réécriture. Ces paragraphes restent **NORMATIFS** : ils portent
> l'histoire et la raison de chaque garde-fou et de chaque piège de harnais. AGENTS.md garde la
> **procédure** (commandes, ordre, pièges à ne pas oublier) et renvoie ici pour le pourquoi.
> Empreinte du bloc extrait : sha256:052b1f8fe622.
>
> ⚠ Les chiffres de ce texte sont ceux de leur date (« dix-huit harnais », « onze harnais »…) :
> la liste à jour des contrôles est le script `check` de `package.json`, celle des harnais le
> tableau `HARNAIS` de `scripts/audit-run.mjs`.

## Avant chaque commit
- `npm run check` — garde-fous sans dépendance : **syntaxe** des scripts inline (attrape les
  templates mal fermés) **ET DE LA FEUILLE DE STYLE** (v4.74.2 — commentaires jamais imbriqués et
  tous fermés, accolades équilibrées, chaînes retirées d'abord). Ce dernier volet existe parce que
  le contrôle ne regardait que du JavaScript, alors qu'une erreur de parse CSS est aussi grave et
  BEAUCOUP plus silencieuse : un fermeur de commentaire en trop laisse du texte à nu, et le parseur,
  pour se resynchroniser, **AVALE LA RÈGLE SUIVANTE**. C'est arrivé deux fois de suite sur des
  commentaires coupés en deux, et la seconde fois **la v4.74.0 a livré un correctif mort** — la
  règle `.hs-wrap>.hs-row:hover` était mangée depuis sa publication, `npm run check` vert de bout en
  bout. Corollaire de méthode : après toute édition du CSS, ne pas se fier au vert de `check-colors`
  et `check-type`, qui travaillent au motif et ne voient pas une règle disparue. Puis **couleurs** (`check-colors.mjs`, cf. Conventions), **échelle
  typographique** (`check-type.mjs`, v4.71.1 — sept paliers, exemptions nommées et motivées),
  **polices** (`check-fonts.mjs`, v5.6 — trois familles embarquées, trois tokens ; une
  `font-family` écrite en clair est SILENCIEUSE, cf. A22),
  **espacement** (`check-space.mjs`, v5.0.0 — 1 356 déclarations, échelle fermée à 21 valeurs,
  migration à ≤ 1 px de déplacement : c'était la moitié du système sans aucun garde-fou),
  **rayons** (`check-radius.mjs`, v5.0.0 — dix-neuf valeurs distinctes pour trois tokens, ramenées
  à sept), et `check-type` couvre désormais AUSSI la bande d'AFFICHAGE (≥ 20 px : 20 · 24 · 26 ·
  34 · 40) **ET la liste « 16 px tactile » (v5.4.0, signalé à l'usage iPhone : « quand on clique
  à l'intérieur d'un protocole l'écran zoome »)** : le champ « Chercher dans la référence » était
  né en v5.0.0 à 12 px sans rejoindre le bloc `@media (hover:none) and (pointer:coarse)` de fin
  de feuille — la source de vérité unique des 16 px (v4.4.2), tenue À LA MAIN, donc un champ
  oublié était un trou silencieux (famille MUTE_SEL/placards). Le contrôle exige désormais que
  tout sélecteur posant < 16 px sur un jeton d'élément `input`/`textarea`/`select` figure dans
  cette liste ; il a immédiatement attrapé TROIS autres champs jamais signalés (phase de bloc à
  11 px, lignes du chapeau et nom de minuteur à 13,5). Limite dite : un champ stylé par sa seule
  CLASSE échappe au repérage statique. ⚠ Sa PREMIÈRE version était un no-op silencieux — écrite
  via un heredoc Python, son `\b` de regex était devenu un BACKSPACE (le piège « un patch scripté
  mutile en silence », déjà payé sur les `$$` SQL) et le test de réintroduction restait VERT ;
  rejoué rouge/vert après réparation, et la preuve dynamique (pointeur grossier émulé, corps
  calculé 16 px sur les quatre champs) est passée aux deux moteurs,
  **paliers de largeur** (`check-paliers.mjs`, v5.0.0 — l'échelle responsive cesse d'être
  déclarative ; cf. « Largeurs & échelles fermées »), et
  **fraîcheur des hashs CSP** (`csp-hashes.mjs --check`). Ce dernier existe parce que le piège s'est produit trois
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
  **⚠ PIÈGE VÉCU (v4.74.1) — `npm run design:check` PORTE `--strict`, ET `--strict` FAIT
  `git checkout -- design/ds`.** Il restaure donc les fichiers GÉNÉRÉS pour ne pas polluer l'espace
  de travail du CI ; joué APRÈS un `design:build` local et AVANT le `git add`, il efface la
  régénération qu'il vient lui-même de réclamer — et le commit part sans elle, le CI échoue sur
  exactement le message qu'on croyait avoir traité. L'ordre est donc : `design:build` → `git add
  design/ds` → (facultatif) `design:check`. **Ne jamais intercaler `design:check` entre les deux**,
  et vérifier au `git status` que les fiches sont bien STAGÉES avant de committer.
- `npm run audit` — **audit transverse (v4.23.0 ; SOCLE COMMUN + MOTEUR CHOISISSABLE v4.45.0)**.
  Les harnais partagent `scripts/harness.mjs` (serveur statique, table MIME, choix du
  moteur) : ils recopiaient le même bloc, et la DIVERGENCE avait déjà commencé —
  `audit-retour.mjs` était le seul dont la table MIME omettait `.ico`. Surtout, les onze d'alors
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
  au rail, à la feuille Plan, aux cartes de consultation ou à un token de couleur. **DIX-HUIT harnais Playwright qui
  MESURENT au lieu d'affirmer (liste exacte dans `scripts/audit-run.mjs` : a11y, doctrine,
  budget, verify, session-card, zoom-scroll, verify-live, modeseg, consulter, complications, exercice, **guide** (v5.48, A467),
  **k5**, **prompt**, retour, qr, partage, historique, **stockage**, **pliables** (v5.38, A405)).
  **LANCEUR PARALLÈLE À RAPPORT AGRÉGÉ (v5.0.0, `scripts/audit-run.mjs`)** : la chaîne `&&` de
  `package.json` payait la SOMME des durées (mesuré 9 min 42 s, dont 87 % dans doctrine/a11y/
  partage/k5) et son fail-fast CACHAIT tout ce qui suivait le premier rouge — l'incident « un
  harnais qui plante en emporte cinq » (v4.70.1), revécu à chaque itération. Le lanceur joue les
  dix-huit en concurrence (pool `AC_JOBS`, défaut 4, lourds d'abord — temps mural ≈ le max, pas la
  somme) et rapporte TOUS les échecs d'une passe ; les sondes, leurs seuils et `AC_ENGINE` sont
  inchangés, et chaque harnais reste lançable seul. **CIBLAGE pendant l'itération** :
  `npm run audit -- partage qr` ne joue que les harnais nommés — la passe s'annonce alors
  « PARTIELLE » en toutes lettres (un vert partiel pris pour un complet serait pire que le statu
  quo), un nom inconnu ÉCHOUE bruyamment (une faute de frappe qui lancerait une passe vide aurait
  l'air verte), et la règle « avant chaque commit » reste la passe COMPLÈTE, que la CI rejoue.
  **SECTIONS CIBLABLES ET TRANCHES (v5.4.4, audit du dispositif lui-même — mesuré avant de
  décider)** : la boucle d'itération payait le harnais ENTIER pour confirmer UN témoin corrigé
  (doctrine : 216,7 s mesurées pour 51 sections indépendantes — seul état partagé, les compteurs
  ok/ko), et la passe complète avait doctrine pour temps mural À LUI SEUL (216,7 s = 100 % du
  mural, le pool absorbant les 19 autres pendant qu'il tourne). Quatre réponses, AUCUNE sonde
  changée : (1) **`--grep <motif>`** sur doctrine et partage (`secRunner`, harness.mjs) — chaque
  section est enveloppée dans `await sec('nom', …)`, une section ciblée se confirme en ~2-8 s au
  lieu de 217 ; motif sans correspondance = échec BRUYANT listant les sections (une passe vide
  aurait l'air verte), passe filtrée annoncée « PARTIELLE » jusque dans le bilan final. La
  transformation a été vérifiée par ÉQUIVALENCE DE SORTIE (737/737 et 291/291, diff byte à byte
  contre la sortie d'avant, hors ligne `##SEC`). (2) **`tranches: n`** dans `HARNAIS` : le lanceur
  joue doctrine en 4 processus `--shard k/n` (découpe au modulo, ordre gardé — **équilibrée par
  durées depuis v5.39.2** : le lanceur passe un plan `AC_PLAN` calculé sur les ⏱ de la passe
  précédente, modulo en l'absence de mesure), a11y en 2 (tranches
  du tableau SURFACES ; la sonde focus 2.4.11 ne tourne que dans la tranche 1), partage en 2 —
  temps mural de la passe complète ~217 → ~120 s. GARDE-FOU : chaque tranche imprime
  `##SEC joues=j total=N` et le lanceur VÉRIFIE que la somme couvre le total — une tranche qui
  perdrait des sections serait une troncature silencieuse, rouge fabriqué. (3) **`--rouges`
  REJOUE PAR SECTION (v5.4.4 ; affiné v5.10.5)** : chaque passe enregistre dans
  `.audit-etat.json` (racine, gitignoré) les harnais rouges ET, pour les harnais à secRunner
  (doctrine, partage), les NOMS des sections rouges lus dans la sortie capturée ; `--rouges`
  rejoue alors ces seules sections par `--grep` (noms exacts, ancrés, échappés) — confirmer un
  correctif tombe de ~2 min à quelques secondes. Toujours annoncé PARTIELLE, et TROIS garde-fous :
  l'attribution n'est tentée que si le harnais a atteint son bilan (`##SEC` présent — sinon repli
  sur le harnais ENTIER, jamais trop peu) ; un `--grep` qui rejoue moins de sections qu'attendu
  (renommée depuis ?) est FORCÉ ROUGE ; un rejeu par sections n'écrit JAMAIS de vert au cache.
  (4) **CACHE VERT PAR HARNAIS (v5.4.4 ; par harnais depuis v5.10.5)** : le cache était
  tout-ou-rien (un octet changé dans `audit-qr.mjs` faisait repayer doctrine, 217 s) ; l'empreinte
  SHA-256 est désormais PAR HARNAIS — socle commun (servables de la racine, vendor/,
  `harness.mjs`, `audit-run.mjs`, moteur) + son script + ses `deps` déclarées (audit-qr :
  `qr-decode.swift`). Une passe qui joue un harnais EN ENTIER et le trouve vert enregistre son
  empreinte ; la passe COMPLÈTE suivante ne rejoue que les harnais dont un intrant a changé et
  LISTE les autres « réutilisés » (même argument que le cache d'origine : entrées identiques →
  même verdict). Les `check-*.mjs` sont sciemment HORS empreinte : aucun harnais ne les lit, les
  inclure fabriquait des repasses complètes fantômes. `--force` rejoue tout ; un ciblage par noms
  ÉCRIT le vert du harnais joué mais ne consomme jamais le cache.
  **UNE MANŒUVRE, UNE SECTION (v5.6, demande de l'auteur : « optimise les audits, évite les
  doublons »)** : deux sections qui montent le MÊME décor pour mesurer deux propriétés d'un même
  geste paient deux fois le démarrage — et surtout, elles finissent par diverger (l'une apprend un
  piège que l'autre ignore). Quand une propriété nouvelle se mesure sur un contexte DÉJÀ dressé,
  elle rejoint la section qui le dresse ; quand elle demande une autre LARGEUR, on redimensionne
  (`setViewportSize`) au lieu de recharger — l'état de session et les volets survivent. Précédent :
  « acquitter un minuteur échu » a fusionné dans la section A9, qui fait déjà échoir un minuteur
  volet ouvert. ⚠ La limite est la LISIBILITÉ DU ROUGE : une section est une UNITÉ DE VERDICT, et
  l'on ne fusionne pas des mesures sans rapport pour économiser une page.
  **LE WORKFLOW QUI EN DÉCOULE** : une passe complète de
  DÉCOUVERTE en début de chantier (le rapport agrégé montre tous les rouges d'un coup), puis
  correction → section ciblée en secondes, puis UNE passe complète finale — la porte de commit est
  STRICTEMENT inchangée. **CE QUI N'A PAS ÉTÉ FAIT, et pourquoi** : pas de carte « fichier modifié
  → harnais à jouer » (monofichier + dix-neuf pièges de cascade : une édition CSS anodine casse
  des témoins dans des harnais sans rapport — une carte serait un vert menteur) ; pas de témoins
  auto-régénérés façon snapshots (un contrôle qui ne peut plus échouer ne prouve rien, leçon
  v4.31.1) ; k5 n'est pas découpé (scénario séquentiel monopage, ~67 s incompressibles).
  **GESTES D'AMORÇAGE PARTAGÉS (v5.0.0, `harness.mjs` : `amorce`/`ouvrirFiche`/`demarrerSession`)** :
  les dix-sept recopiaient « Commencer → fiches d'exemple → `.card-open` → `#sessStart` » avec des
  délais déjà divergents (120/350 ici, 200/700 là) — un changement du flux d'accueil coûtait
  jusqu'à dix-sept éditions. Une copie désormais, avec attentes sur CONDITIONS RÉELLES
  (`waitForFunction`) au lieu de délais fixes ; le point d'entrée reste le VRAI (doctrine v4.40.0).
  DEUX sites gardent leur amorçage inline À DESSEIN, commentés sur place dans `audit-doctrine.mjs` :
  la sonde de l'écran de bienvenue (l'amorçage est son SUJET de mesure, pas sa mise en condition)
  et la sonde qui injecte SA fiche sans poser les exemples (autre trajet, pas une copie).
  Ils tournent en CI en mode **NON BLOQUANT** (`continue-on-error`) : visibles à chaque
  push, mais un échec y demande un arbitrage humain, pas un blocage de merge. Les trois plus
  anciens, en détail :
  - `scripts/audit-a11y.mjs` — **25 surfaces × 2 thèmes, dont les 21 `.ai-modal` du monofichier
    et l'écran d'entrée de l'invité** (v4.40.0) : plancher typographique 11 px, contraste
    calculé sur le fond EFFECTIF (remontée des ancêtres + composition alpha, exemption « grand
    texte »), cibles (44 px en crise, 24 px ailleurs, halo `::after` compté), `--ink-3` en couleur
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
    carte Références inerte (0 coche, 0 démarrage), taper un nœud du plan ne démarre ni ne coche,
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
  `check-upload.mjs` (v5.0.0) tient la porte des ENTRÉES DE FICHIER : un seul
  `<input type="file">` dans tout le fichier (il y en avait cinq), aucun `accept` écrit à la main
  (il vient de `UP_KINDS`, sur la même ligne que la signature qui sera vérifiée), aucun `accept`
  fourre-tout du genre « image/étoile » — c'est par là que le SVG entrait —, cinq champs par
  nature, et **le compte des sites qui lisent `.files`** : un quatrième serait, par construction,
  un chemin d'upload qui ne passe pas par `acceptFile`, c'est-à-dire le défaut d'avant ce chantier
  en train de revenir. Il neutralise les commentaires avant de mesurer (le fichier CITE la règle à
  plusieurs endroits) et cette approximation tombe du bon côté : sur-neutraliser fait ÉCHOUER, pas
  passer sous silence. Vérifié capable d'échouer sur ses cinq points, fichier restauré à l'octet.
  `check-actions.mjs` (v5.6) exige qu'un `data-*` ÉMIS ait un LECTEUR (cf. A112).
  `check-ids.mjs` (v5.10.2) est son symétrique pour les IDS : tout `getElementById('X')` littéral
  doit avoir une émission (`id="X"` ou fabrique déclarée — `upDropHtml`, `crtCard`). Quatre
  lecteurs fantômes (#crisisCtrl ×3, #planBtn ×2, #endSess) vivaient dans ce trou, dont un qui
  recalculait `--ctrl-h` à chaque évènement de défilement pour un élément inexistant.
  `check-actest.mjs` (v5.10.2) tient la SURFACE DE TEST : toute clé exportée vers `__ac_test__`
  doit être citée par `tests.html` ou un harnais, et les doublons du littéral échouent — c'est le
  trou par lequel `flattenFiche` (exportée, citée nulle part) est restée verte pendant que le
  diff de versions devenait aveugle sur cinq listes sur six. ⚠ `tests.html` se lit en OCTETS :
  `grep` sans `-a` le croit binaire et répond zéro sur TOUT — le piège qui a fait dire « 0
  test » à un audit entier (toujours `grep -a` sur ce fichier).
  `check-ring.mjs` (v5.19.6, A285) tient LA RESPIRATION DU BORD DE DÉCOUPE : aucune règle ciblant un
  corps de fenêtre par son `#id` ne pose une respiration inline < 4 px — la garde d'A268 qui laisse
  l'anneau de focus entier. Elle avait été reprise en silence par un RACCOURCI `padding` (spécificité
  d'un id contre celle de `.ai-card>.ai-body`), et la marge négative survivant seule décalait le contenu
  de 4 px vers la découpe. Les règles visant un DESCENDANT ne sont pas concernées. Vérifié capable
  d'échouer sur l'état d'avant correctif.
  `check-stick.mjs` (v5.12.1) tient LE DÉCALAGE « SOUS L'EN-TÊTE » : aucune propriété `top` ne
  s'ancre sur `--hdr-h` sans tenir compte de `--vvt` (le décalage du viewport visuel, clavier
  ouvert) — elles lisent `--hdr-off`, qui porte les deux. Il naît d'une récidive : la v5.12.0 a
  fait suivre le clavier au chrome collant mais n'a corrigé que TROIS des CINQ sites qui
  recopiaient le calcul, et `#refBar` — la barre de recherche d'une référence — continuait de
  disparaître dans le cas qu'on venait de réparer. Une exemption nommée (`.azrail`, dont le haut
  est gelé par mesure). Vérifié capable d'échouer.
  `check-tokens.mjs`, le sens inverse de `check-ids` et `check-fns.mjs` (v5.19.4, A283) ferment
  les trois trous de l'audit interne : token CSS déclaré ↔ lu (le cas `--hover`, survol inerte en
  production), sélecteur `#id` stylé → émis, déclaration top-niveau → citée ailleurs que sur sa
  ligne. Commentaires dépouillés d'abord (`strip-comments.mjs`, source unique) : un nom cité dans
  la doctrine n'est pas un usage. Asymétrie choisie : une citation en chaîne compte comme usage —
  jamais de faux rouge, au prix de morts manqués. Détail : A283.
  `check-harnais.mjs` (v5.0.0) rend auto-exécutoire la discipline née avec le lanceur parallèle :
  (1) tout `scripts/audit-*.mjs` sur disque figure dans `HARNAIS` (audit-run.mjs) et
  réciproquement — un harnais créé mais non listé ne tournerait JAMAIS dans `npm run audit`, et le
  trou serait silencieux (la fuite exacte de l'échelle des paliers, rejouée ici) ; (2) aucun
  harnais ne recopie l'amorçage « Commencer » — on passe par `amorce()`/`ouvrirFiche()`/
  `demarrerSession()` de `harness.mjs`, et une exemption se marque SUR PLACE par le commentaire
  « PAS `amorce()` ici » avec sa justification (jamais dans une liste du contrôle, qui se
  périmerait). Vérifié CAPABLE D'ÉCHOUER dans les deux sens (harnais fantôme → rouge ; copie
  d'amorçage réintroduite → rouge ; états restaurés).
- L'intégration continue (`.github/workflows/ci.yml`) rejoue, sur chaque push/PR :
  `npm run check` (syntaxe + couleurs + hashs CSP), `design:check --strict`, `npm ci`, `npm test`,
  puis `npm run audit` **en non bloquant**. `npm ci` (et non `npm install`) : la CI installe
  exactement le contenu du lock, donc reproductible — `release.sh` synchronise désormais la
  version de `package-lock.json` avec les trois autres fichiers (elle était restée à 4.3.0).

---

## Annexe — la section « Règle de publication » d'AGENTS.md avant l'audit des instructions (à l'octet)

### Règle de publication (IMPÉRATIF) — texte d'origine
Publier une version = trois étapes, dans cet ordre :

1. `./release.sh X.Y.Z` — synchronise `APP_VERSION` (`index.html`) et `CACHE` (`sw.js`), ébauche
   l'entrée `CHANGELOG.md`, vérifie syntaxe et tests. **Ne jamais éditer ces numéros à la main**
   (un décalage casse la mise à jour du service worker). Le script **ne committe pas**.
2. Rédiger l'entrée `CHANGELOG.md` (contenu réel, pas de « à compléter » laissé en place).
3. Committer avec de **vraies notes de version** — format des messages du dépôt :
   `vX.Y.Z : <résumé en français des changements>` — puis taguer `vX.Y.Z`.

Les étapes 2 et 3 sont le travail de l'IA (ou de l'humain), jamais du script.
**Le CHANGELOG garde les 20 dernières versions** ; au-delà, déplacer les plus anciennes dans
**`docs/changelog/vN.md`, un fichier par VERSION MAJEURE** — telles quelles, sans réécriture, EN
FIN d'archive (convention constatée des lots déjà déplacés). La
règle existait et n'avait servi qu'une fois en 112 entrées : le fichier pesait alors 221 Ko, la
moitié de toute la documentation. **Et elle refuyait** (21 entrées re-mesurées à l'audit
v5.19.3, `release.sh` insère sans jamais élaguer) : `scripts/check-changelog.mjs` la rend
exécutoire depuis — compte ≤ 20 et aucune entrée en double avec une archive, dans `npm run
check` donc en CI, vérifié capable d'échouer (rouge sur l'état à 21 avant l'archivage).
**L'ARCHIVE UNIQUE AVAIT DÉPASSÉ LE FICHIER QU'ELLE SOULAGE (v5.0.0, audit)** : `CHANGELOG-archive.md`
atteignait **471 Ko pour 196 entrées** — plus que `CHANGELOG.md`, plus que tout `docs/`. La règle
déplaçait donc le volume sans jamais le borner, et l'archive devenait à son tour illisible et
inouvrable. Découpée par majeure, elle borne sa croissance par construction : une majeure close ne
grossit plus jamais. Le contenu est repris **à l'octet** (réconciliation vérifiée : 196 entrées
avant, 196 après, aucun contenu modifié) ; seule une coquille de crochet doublé sur `[4.29.8]` a
été normalisée pour que l'entrée reste analysable.
Versionnage sémantique : correctif → patch (Z), nouvelle fonctionnalité → mineure (Y).
Versionnage sémantique : correctif → patch (Z), nouvelle fonctionnalité → mineure (Y).
Ne jamais pousser (`git push`) sans demande explicite de l'utilisateur.

