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

### Mettre à jour un actif vendorisé (pdf.js, police) — la marche à suivre

**⚠ CHANGER LES FICHIERS NE SUFFIT PAS À CHANGER CE QUI TOURNE (v5.0.0, audit).** Le service
worker range pdf.js dans un cache versionné par pdf.js lui-même (`PDFJS_CACHE`), et son
installation n'écrit **que ce qui manque** (`if (await c.match(a)) continue;`). Remplacer
`vendor/pdfjs/` sans toucher `PDFJS_CACHE` laisse donc la clé inchangée, les entrées déjà
présentes, et **rien n'est re-téléchargé** : chaque appareil déjà installé garde l'ANCIENNE
bibliothèque, indéfiniment et sans un mot. Pour une bibliothèque qui analyse du contenu non
maîtrisé — les PDF joints par l'utilisateur — c'est le pire mode de défaillance : la mise à jour
de sécurité qui n'atteint personne. `scripts/check-vendor.mjs` relie désormais les deux sources et
échoue si elles divergent (vérifié capable d'échouer sur les deux).

1. Vérifier l'amont **et les avis de sécurité**, qui ne se déduisent pas du numéro de version :
   `npm view pdfjs-dist version` et les *security advisories* de `mozilla/pdf.js`. Un avis dit
   toujours sa **plage affectée** ET sa version de correction : lire les deux, une version plus
   ancienne que la plage n'est pas concernée.
2. Remplacer les fichiers (`legacy/build/pdf.min.mjs` → `pdf.min.js`, idem worker), **mettre à
   jour `vendor/pdfjs/README.txt`** (c'est la seule trace de ce qui est réellement sur le disque)
   **et `PDFJS_CACHE` dans `sw.js`**.
3. `npm run check` (`check-vendor` + `check-sw`), puis le **test hors-ligne complet** : mode
   avion, PDF de 50+ pages, iPhone — et sur un appareil **DÉJÀ INSTALLÉ**, seul cas où le piège
   du cache se manifeste.

Même discipline pour la police (`vendor/fonts/README.txt` annonce sa taille en octets ;
`check-vendor` la compare au fichier). **`playwright` ne suit pas cette règle** : c'est une
dépendance de DÉVELOPPEMENT, elle n'est ni servie, ni précachée, ni exécutée chez un utilisateur —
`npm outdated` et `npm audit` suffisent, et la CI installe le lock à l'identique (`npm ci`).

## Si vous ne lisez qu'une chose

Quinze règles qui ne se négocient pas. Le reste de ce fichier les explique et les étend ; **aucune
ne s'apprend en lisant le code** — elles viennent d'incidents mesurés, et plusieurs ont déjà été
« corrigées » par erreur faute d'être lues.

1. **Publier** = `./release.sh X.Y.Z`, puis rédiger le `CHANGELOG`, puis committer avec de vraies
   notes et taguer. Ne JAMAIS éditer les numéros de version à la main (un décalage entre
   `APP_VERSION` et `CACHE` casse la mise à jour du service worker). **Jamais de `git push` sans
   demande explicite.**
2. **Avant chaque commit** : `npm run check` (syntaxe · couleurs · classes émises **et stylées** ·
   animations · service worker · **actifs vendorisés** · **entrées de fichier** · SQL · harnais ·
   hashs CSP) et
   `npm test` (Chromium **et** WebKit). Si le CSS a changé : `npm run design:build`.
   **La passe d'audit qui vaut avant un commit est la COMPLÈTE** (`npm run audit` sans argument) ;
   `npm run audit -- <noms>` n'est qu'un accélérateur d'itération et s'annonce « PARTIELLE ».
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
   **`migrate()` NE LIT PLUS QU'UN SEUL FORMAT (v5.0.0, étape D)** : le v4 à pool. Il normalise, il
   borne, il convertit EN PLACE les renommages internes du chantier v5 — mais il ne sait plus lire
   un fichier v3, et c'est délibéré : un convertisseur embarqué serait du code mort dès la
   migration finie, et du code mort dans un logiciel d'urgence vitale est une dette qu'on finit par
   payer. La reprise d'un export v3 vit **hors** de l'application (`docs/conversion-v3-vers-v4.md`).
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
    **ET LES SEUILS DE LARGEUR NE SONT PAS DES MEDIA QUERIES (v4.73.1)** : sous zoom, la mise en
    page dispose de `largeur ÷ zoom` (331 px sur un écran de 430 à 130 %) alors qu'une media query
    mesure la fenêtre du PÉRIPHÉRIQUE et répond 430 — un palier de compression ne se déclenche donc
    jamais quand on en a le plus besoin. Les paliers de la rangée de commandes passent par les
    classes `html.zw560/430/400/360` posées par `syncZoomWidth()` ; à zoom 1 elles sont l'équivalent
    exact des `max-width` qu'elles remplacent. `@container` est ÉCARTÉ : `container-type` implique
    `contain:layout`, donc casserait tout descendant `fixed`.
11. **Le mode crise n'est jamais interrompu** : aucune modale, aucune synchro intrusive, aucun
    défilement automatique, aucune notification flottante. Une alarme s'annonce sur place.
12. **~~Ne jamais supprimer un champ du modèle~~ — RÈGLE LEVÉE EN v5.0.0, par décision explicite
    de l'auteur, et remplacée par celle-ci** : *un changement de modèle qui casse les clients
    antérieurs exige un CHEMIN DE REPRISE écrit AVANT le changement, et hors de l'application.*
    La règle d'origine — « un export v3 doit rester lisible par un client antérieur » — a tenu
    tant que le modèle s'AJOUTAIT. Elle est devenue le principal obstacle au modèle v4, où six
    champs devaient DISPARAÎTRE : la respecter aurait exigé un miroir par champ renommé, donc de
    doubler la surface du modèle pour toujours.
    **CE QUI LA REMPLACE N'EST PAS « on casse quand on veut »** : (a) le chemin de reprise existe
    et il est écrit d'abord (`docs/conversion-v3-vers-v4.md`) ; (b) les données LOCALES ne sont
    jamais cassées par une mise à jour que l'utilisateur n'a pas choisie — les renommages internes
    se convertissent EN PLACE dans `migrate` ; (c) la rupture est annoncée dans les notes de
    version. Ajouter un champ reste libre ; en retirer un engage ces trois obligations.
13. **Aucune dépendance runtime**, à l'unique exception de pdf.js vendorisé (chargé paresseusement,
    précaché). Tout fichier servi doit entrer dans `ASSETS` (`sw.js`). **Une POLICE embarquée
    depuis v4.61.0** (`vendor/fonts/source-serif-4-latin-600.woff2`, 21 Ko, SIL OFL) : ce n'est
    pas une dépendance runtime — aucun code, aucun appel réseau — mais un ACTIF SERVI, donc soumis
    à la même règle (entrée dans `ASSETS`, `font-src 'self'`, mise à jour = décision explicite
    comme pdf.js).
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
| **Mode crise — parcours et vues** | Parcours de soin · Journal de parcours · Plan de l'aide · PLAN = UNE SEULE VUE · Mode statique · Challenge-response · COMPLICATIONS · JALONS DE BOUCLE · MODE EXERCICE · Alarme de minuteur · Dialogue « Terminer la session ? » · PORTÉE D'UNE ACTION DE REPRISE |
| **Chrome, navigation, géométrie** | ON ANIME LA COMPOSITION · En-têtes V5 · ZONE HAUTE DE CRISE · DEUX RANGÉES COLLANTES · RAIL DE LECTURE · ANCRAGE ET DÉFILEMENT · DÉFILEMENT PRÉSERVÉ · RÉENTRÉE · HAUTEURS RELATIVES À LA FENÊTRE · Largeurs & échelles fermées · PILE DE RETOUR · RETOUR SYSTÈME · Sélecteur segmenté · Repli de l'étape ① · LOGO DE MARQUE · Pieds de page · Indicateur de mode des éditeurs · Interactif |
| **Accueil (bibliothèques)** | ACCUEIL « POSTE ACCÈS DIRECT » |
| **Consultation et références** | FEUILLE « CONSULTER » · FEUILLE CONSULTER = UN DOCUMENT · REPÈRES POSOLOGIQUES · SORTIE PDF UNIFIÉE · LE COMPTE-RENDU S'ENREGISTRE EN PDF |
| **Données, stockage, sécurité** | Documents PDF · CHERCHER DANS LES DOCUMENTS PDF · Export/import « avec documents » · TOUTE ENTRÉE DE FICHIER · LE DÉPÔT HORS ZONE · Nommage SQL · (et les points 4 à 6 ci-dessus) |
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
**Le CHANGELOG garde les 20 dernières versions** ; au-delà, déplacer les plus anciennes dans
**`docs/changelog/vN.md`, un fichier par VERSION MAJEURE** — telles quelles, sans réécriture. La
règle existait et n'avait servi qu'une fois en 112 entrées : le fichier pesait alors 221 Ko, la
moitié de toute la documentation.
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
  au rail, aux feuilles Plan/Consulter ou à un token de couleur. **DIX-HUIT harnais Playwright qui
  MESURENT au lieu d'affirmer (liste exacte dans `scripts/audit-run.mjs` : a11y, doctrine,
  budget, verify, session-card, zoom-scroll, verify-live, modeseg, consulter, complications, exercice,
  **k5**, **prompt**, retour, qr, partage, historique, **stockage**).
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
  joue doctrine en 4 processus `--shard k/n` (découpe au modulo, ordre gardé), a11y en 2 (tranches
  du tableau SURFACES ; la sonde focus 2.4.11 ne tourne que dans la tranche 1), partage en 2 —
  temps mural de la passe complète ~217 → ~120 s. GARDE-FOU : chaque tranche imprime
  `##SEC joues=j total=N` et le lanceur VÉRIFIE que la somme couvre le total — une tranche qui
  perdrait des sections serait une troncature silencieuse, rouge fabriqué. (3) **`--rouges`**
  rejoue les seuls harnais rouges de la dernière passe (état dans `.audit-etat.json`, racine,
  gitignoré), annoncé PARTIELLE. (4) **CACHE DE PASSE VERTE** : une passe complète verte
  enregistre le SHA-256 de tout ce qui peut influencer un verdict (servables de la racine,
  vendor/, scripts/*.mjs, moteur) ; si rien n'a changé, `npm run audit` LE DIT au lieu de rejouer
  (entrées identiques → même verdict), `--force` rejoue quand même ; une passe partielle n'écrit
  ni ne consomme jamais ce cache.
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

## Refonte v5.6 — direction « verre clinique, mat »

> Ces entrées sont la **passation** de la refonte (planches Claude Design, phases 0 à 6). Elles
> ROUVRENT des décisions consignées : chacune est nommée avec ce qu'elle achète et ce qu'elle
> coûte. Une règle non consignée est une règle que la prochaine itération prudente défera.

**TROIS MATIÈRES, TROIS NATURES.** Sombre (`--sys`) = SYSTÈME : la capsule d'état et le dock, les
deux seuls objets sombres du produit — trouvables sans lire. Blanc (`--work`) = TRAVAIL : carte,
historique, feuilles, éditeurs ; seule matière qui projette une ombre. Gris (`--amb`) = AMBIANCE :
le fond, ce qui attend.
**ROUVRE** les bandes et filets empilés du chrome de crise (v4.25.0 et suivantes) : la séparation
commandes/affichage passe désormais par la MATIÈRE, plus par des rangées superposées.
**⚠ TROIS TOKENS NE SONT PAS DES ALIAS, et chacun l'a appris au prix d'un contrôle rouge** :
`--paper` reste un BLANC FIXE des deux thèmes (aliasé sur `--work`, le QR se peignait en encre
sombre sur fond sombre — indéchiffrable, et le défaut ne se serait vu qu'au moment de scanner) ;
`--shadow-up` garde son décalage NÉGATIF (une ombre montante qui descend fait paraître l'objet
enfoncé) ; `--ctl-line` tient 3:1 là où `--line-strong` du système n'en fait que 1,6 — WCAG 2.2
§ 1.4.11 vise les BORDURES DE COMPOSANT, c'est-à-dire la case qu'on vise avec des gants.
Sur la matière système, les registres ont leurs valeurs propres (`--ok-sys`, `--warn-sys` sur
`--warn-sys-bg`, `--crit-sys`, `--on-sys-fill`) : la capsule et le dock sont sombres dans les DEUX
thèmes, un registre du thème clair n'y tiendrait pas 4,5:1.

**A1. CLAVIER VS DOCK.** Au focus d'un champ, le dock s'efface (le clavier EST la surface de
saisie) ; il revient à la fermeture. Ne jamais empiler dock + clavier. Le champ du volet ⏱ est
EXCLU : il vit dans le dock, s'effacer sous les doigts de qui écrit dedans serait absurde.

**A2. 320 px.** Les touches d'excursion perdent leur étiquette (glyphe seul, `aria-label`
conservé). Hors du contrat « le mot Crise jamais au glyphe seul », qui ne vise que le STATUT, pas
les commandes — et les deux GESTES (⚡︎, ⏱) gardent leurs mots, parce qu'ils ÉCRIVENT.

**A5. THÈME SOMBRE — OLED GRIS.** Fond `#0d0f13` (gris vrai, pas un noir théâtral : sur OLED le
noir pur fait « trou » et le halo des textes clairs fatigue), travail `#171a20` bordé, encres
remontées, signaux éclaircis, zéro ombre — la nuit ne projette pas, elle borde.

**A6. ÉCHELLE TYPOGRAPHIQUE FERMÉE — SEPT CRANS, UNE SEULE BANDE.** `11 / 12 / 13,5 / 15 / 17,5 /
21 / 24`, graisses 500-800. L'ancienne bande d'AFFICHAGE (20 · 24 · 26 · 34 · 40) disparaît avec sa
raison d'être : un chrono à 40 px pendant qu'une étape vitale plafonnait à 15,5 était l'enjeu
INVERSÉ. Seule dérogation, le multiplicateur global `--zf`, qui garde les crans solidaires.
`check-type` le vérifie ; son CLIQUET de plancher est remonté de 166 à 170 déclarations à 11 px —
les quatre étiquettes du dock (A13) —, et c'est un ÉCHANGE, pas une tolérance : l'étape critique
passe de 15,5 à 17,5 px dans le même mouvement.
ACHÈTE : le grand corps appartient à l'ACTE, plus au chrono.

**A7. « VÉRIFIER » EST UN GESTE DE BLOC.** Il rejoue les challenges « :: » du bloc courant
(Do-Verify, FAA Order 8900.1) : il vit dans la carte, en rangée de pied, à gauche de « Continuer »,
et SEULEMENT si le bloc porte des challenges. Le dock reste pur session.

**A8. CIBLES.** Aucun contrôle sous 44 px de cible en crise — ± des compteurs, RELANCER/PAUSE et ✕
compris. La cible vient du HALO, jamais du dessin : c'est ce qui permet à la capsule de se
compacter à 36 px dans l'en-tête sans perdre ses 44 px de cible.

**A9. HAUTEURS D'ÉTAT FIXES.** Un changement d'état NON commandé (un minuteur qui devient échu, une
alarme qui s'éveille) ne modifie JAMAIS une hauteur : capsule (50 px) et cartes de minuteur ont un
gabarit constant entre leurs états ; seuls matière, couleur et texte changent. L'expansion reste
permise quand elle est COMMANDÉE par un tap. ⚠ Le piège n'est pas la structure — elle est identique
d'un état à l'autre — c'est le LIBELLÉ : « Adrénaline » devient « Adrénaline — échu », un mot de
plus passe le nom sur deux lignes, et la carte grandit sous le doigt. D'où le clamp à deux lignes.

**A10. UNE ÉTAPE FAITE NE SE BARRE JAMAIS.** Le fait se marque (✓ + encre atténuée), il ne
s'ampute pas. Trois raisons : une checklist en boucle fait relire l'étape au passage suivant ; la
passe Do-Verify exige de pouvoir RELIRE ce qu'on a fait ; ni l'ECAM ni le QRH ne rayent une ligne
exécutée. Le barré reste admis hors crise, sur des listes non séquentielles, et pour ce qui est
ANNULÉ (repère annulé, participant déconnecté) — annulé n'est pas fait.

**A11. APLAT VS MARQUE.** La teinte en APLAT est réservée à ce qui exige une action MAINTENANT
(alarme active) — une seule masse colorée à l'écran, et le nominal s'éteint. Une étape critique se
MARQUE : case rouge + ⚠ + corps 17,5 px + cadence mono ambre, **sans cadre ni fond**. Mesuré à
l'usage : à cinq étapes, l'aplat happe l'œil et détruit la lecture de la séquence. Le CORPS est le
canal du danger — il ne hiérarchise que si toutes les lignes ne l'ont pas, d'où l'étape ordinaire à
`--t-item` et la seule critique à `--t-step`. La vigilance △ ne prend PAS le gain de corps : le
grand corps dit « ceci tue », l'étendre à « on s'y trompe » remettrait les deux à égalité.

**A12. « ICI » N'EXISTE QUE DANS UNE LISTE.** Sur la carte, le bloc ouvert est déjà désigné par
trois signaux (seul bloc ouvert, tête de journal, bordure d'accent) et par `aria-current="step"` :
l'étiquette y est redondante, seul le compte subsiste. Elle reste dans le rail Structure,
l'excursion « ⤢ Tout voir » et l'étiquette de retour du dock — là où elle sert à SE RETROUVER.

**A13. DEUX CRANS DE GLYPHE.** Glyphe de commande 15 px (‹ ◐ ⋯ ⤢ ▤ ⚡︎ ⏱ ✕ ±) ; micro-glyphe inline
(✓ ⚠ △ ●) au corps du texte qu'il accompagne. Étiquettes de touches à `--t-cap` 11 px. Tout glyphe
susceptible de basculer en emoji couleur (⚡︎ notamment) porte le sélecteur de présentation texte
U+FE0E : une couleur non contrôlée casse la sémantique du danger.

**A14. EN-TÊTE À TROIS ZONES ANCRÉES.** Identité à gauche — **sur-titre `.brand-sur` AU-DESSUS du
titre**, parce qu'accolé au nom de la fiche le statut se lisait comme un fragment de ce nom ; état
au CENTRE en position absolue à partir de 1000 px (un titre long ne déplace plus l'alarme) ;
réglages à droite. Hauteur constante quel que soit l'état. **La pilule `#hdrCrisis` est PURGÉE** :
deux énoncés du même mode sur le même écran, c'est la duplication que la v4.70.1 proscrit — la
question n'était plus QUE supprimer mais LEQUEL, et le sur-titre gagne parce qu'il est du côté où
l'œil arrive et qu'il ne dispute plus sa place aux réglages.

**A15b. « PARCOURS » EST LA SÉQUENCE, « PAGE » EST LE CONTENU (v5.6).** Les deux onglets du cran
« Toute la fiche » montraient l'un et l'autre chaque étape de chaque bloc, dans deux mises en page —
deux vocabulaires pour une idée (§5.5). « Parcours » devient une rangée par bloc (état dans la
marque, renvois à droite) et seul le bloc COURANT développe ses items : c'est la rangée qui répond
à « où j'en suis », les autres n'ont rien à dire de plus que leur compte. « Quand l'utiliser » y
reste — la maquette ne la montre pas, mais retirer une condition d'entrée d'une vue « toute la
fiche » serait une perte sèche.

**A15. « CONSULTER » N'ÉVINCE PAS LE BLOC AU COCKPIT.** À partir de 1200 px la référence s'ouvre
dans la colonne d'état : le bloc reste sous les yeux et cochable (l'ECAM ne remplace que la zone
concernée). Sous 1200 px elle reste une excursion, retour nommé « ↩ REVENIR · n » à position
constante, même vert que « ↩ UN BLOC ». « Tout voir » garde le remplacement à tous les paliers :
c'est la même matière que le bloc — la fiche.

**A16. UNE LIGNE OU UNE CARTE — LA FORME DIT LA NATURE (v5.6, deuxième passe de fidélité).**
Ce qui se COMPTE prend une carte (les blocs d'une séquence : on les dénombre d'un coup d'œil) ; ce
qui se LIT prend une ligne (repères posologiques, surveillances, différentiels, documents,
références). Corollaires appliqués partout :
· **Un repère posologique est une RANGÉE** — nom à gauche, valeur mono à droite, MÊME grammaire
  dans le flux et dans le rail (deux habillages en feraient deux composants). Le registre △ se
  marque (glyphe + encre), il ne prend jamais d'aplat.
· **Plus aucune case inerte dans « Consulter »** — une case qu'on ne peut pas cocher, dans une
  surface dont l'INERTIE est la propriété qu'un harnais vérifie, invite au geste qu'elle refuse
  (même argument qu'en v5.0.0/M1 pour l'éditeur, où `.li-box` a été purgée pour cette raison).
  Ses sections sont des INTERTITRES 11 px dans leur carte, plus des rangées-menu de 52 px — la
  cible de 44 px est rendue par le rembourrage, jamais par un halo (sur une rangée pleine largeur
  il recouvrirait la première ligne de contenu, et un tap destiné à lire replierait la section).
· **Les surveillances de la colonne d'orientation restent des lignes** : elles n'ont pas de rang,
  et un item ellipsé y perd son contenu clinique là où un bloc se retrouve par son numéro.

**A17. UNE DÉCISION N'EST PAS UNE ALERTE (v5.6, maquette « cas difficiles »).** La carte de
décision était un APLAT ambre : dans une fiche à branches, c'est le bloc courant une fois sur
deux — la moitié du soin se déroulait sur un fond d'alerte, et l'ambre cessait de vouloir dire
« c'est là qu'on se trompe » (A11). Elle redevient une carte de TRAVAIL ; le registre est porté
par l'étiquette du bloc et le liseré gauche, qui restent ambre (v4.24.0 : un registre n'est jamais
masqué par un état). **Les issues prennent le registre de l'ACTION** — contour `--act` de 2 px,
poids strictement égal, aucune n'est suggérée — **et chacune ANNONCE SA DESTINATION** (« → bloc 4 ·
Stabilisé ») : un chevron dit que ça mène quelque part, pas OÙ, et c'est ce qu'on veut savoir avant
de choisir sous stress. Numéro du plan (numérotation commune) + titre tronqué : un numéro seul ne
parle pas à un humain (v4.16.2).

**A18. LE DOCK EST LA BARRE DE COMMANDE DE LA SESSION (v5.6, maquette 1c).** Ses quatre touches
n'apparaissent qu'une fois le soin DÉMARRÉ. Avant le premier geste, deux d'entre elles
DÉMARRERAIENT la session implicitement par un contrôle qui ne le dit pas (⏱, ⚡), et les deux
autres doublonnent ce que la page montre déjà — hors session la fiche est ENTIÈRE sous les yeux.
« Consulter » reste à un tap par la rangée d'annexes et par le renvoi de la condition d'entrée.
⚠ CE QUI N'EST PAS REPRIS DE LA MAQUETTE, ET POURQUOI : elle loge « Démarrer la session » DANS le
dock. Le bouton reste dans le flux, sous les critères — c'est le geste qui PORTE la confirmation
(« Confirmé — démarrer la session », v4.3.2) ; le déplacer en ferait un second énoncé du même verbe
(§5.5) ou obligerait à supprimer celui du flux, donc à rouvrir l'ordre « critères → memory items →
geste » (v5.0.8) et la zone flottante qui garantit qu'on l'atteint (v4.73.0). Trois décisions
mesurées pour un gain de position : à décider séparément, jamais par effet de bord.

**A19. LA CONDITION D'ENTRÉE A DEUX ÉTATS, DONC DEUX DESSINS.** Avant la session, « suis-je au bon
endroit ? » EST la question : carte au dessin de la maquette (« ■ Quand l'utiliser », un ■ rouge
par critère, renvoi discret vers les différentiels), sans chevron — il n'y a rien à replier quand
on n'a pas encore répondu. Après, c'est une ligne de traçabilité : le dépliant d'avant, inchangé.
⚠ CADRE NEUTRE, PAS ROUGE (maquette 1c contre 1b — les deux existent) : le chapeau « Ne pas
oublier » juste dessous EST un encadré rouge, et deux cadres rouges qui se suivent sont
l'inflation que ce dossier combat depuis la v4.23.0. Le registre vit dans le titre et les
marqueurs.

**A20. LE VOLET DU QUAI EST UN ÉTAGE DU CHROME, DONC IL EST SOMBRE.** La v5.4.1 en avait fait un
étage plutôt qu'une carte flottante — bonne structure, matière d'avant. Depuis les trois matières,
un étage du quai en blanc annoncerait qu'on est revenu dans le TRAVAIL. Cartes `--sys-2`, échu sur
`--warn-sys-bg`. Aucun contenu clinique n'y vit : ce sont des ÉTATS (temps, décomptes, repères),
c'est-à-dire ce que le quai porte déjà.

**A21. « NOTER L'HEURE » N'A QU'UNE ADRESSE.** C'est une touche du dock. Le panneau du journal ne
la porte plus : deux adresses pour un verbe, c'est ce que §5.5 proscrit, et la seconde vivait
derrière un dépliant — donc invisible à l'instant où l'on en a besoin. Le panneau redevient la
LECTURE du journal.

**A22. TROIS FAMILLES, TROIS TOKENS — ET UN GARDE-FOU (`check-fonts.mjs`).** Manrope (`--f-ui`),
IBM Plex Mono (`--f-mono`), Source Serif 4 (`--f-title`). Une `font-family` écrite en clair est
SILENCIEUSE : le texte s'affiche, dans la mauvaise voix, et sur un système où `system-ui` ressemble
à Manrope on ne le voit pas même en regardant. Deux sites l'enfreignaient depuis la refonte — la
pilule de discriminant du titre et les sept textes du schéma SVG, tous deux posés du temps où
l'interface ELLE-MÊME était en `system-ui`. ⚠ Un attribut SVG `font-family="…"` n'hérite pas d'une
propriété personnalisée : il porte la pile en clair, famille embarquée en tête. Le compte rendu
TÉLÉCHARGÉ est exempté par la RÉGION où il vit (pas par une liste de valeurs) : c'est un document
autonome, sans serveur, et ses polices système sont une décision (v5.2.0).

**A23. L'ÉCHELLE FERMÉE SE VÉRIFIE AU RENDU, PAS SEULEMENT DANS LA FEUILLE (v5.6, balayage).**
`check-type`/`check-space`/`check-radius` lisent le bloc `<style>` : un `style=` EN LIGNE dans la
coque statique leur échappe entièrement, et une règle qui ne s'applique pas dans un logement
(`.ai-card ol` quand la feuille s'ouvre dans la COLONNE du cockpit) laisse le navigateur poser son
défaut de 16 px. Le balayage du rendu (7 surfaces × 320/390/1280 × zoom 90/100/130) a trouvé
exactement quatre dérives, toutes invisibles au statique : `#confirmMsg` à 14,5 px et un `gap:9px`
en ligne, `.sv-band.sv-cxband` qui héritait du 16 px par défaut (texte NU, sans `.sv-t` pour le
porter), et la liste des références en colonne. Après : **zéro** taille et **zéro** rayon hors
échelle, l'espacement n'ayant plus que des compensations négatives documentées et la réserve du
dock — qui est une HAUTEUR MESURÉE, pas un espacement choisi, et ne doit pas être arrondie.

**A24. LE DOCK EST FLOTTANT PARTOUT, À LA LARGEUR DE SA COLONNE (v5.6, décision de l'auteur CONTRE
la planche 7c).** 7c le voulait en pied de colonne au-delà de 780 px ; à l'usage, une colonne de
lecture fait plusieurs milliers de pixels et le geste d'entrée comme les quatre touches de session
se retrouvaient à un défilement complet de ce qu'ils commandent, quand tout le dispositif est
adossé à la promesse d'une position CONSTANTE. Ce qu'on garde de 7c est sa vraie trouvaille : sa
LARGEUR. Le dock s'aligne sur la COLONNE D'ACTION, jamais sur la fenêtre — géométrie prise sur la
grille canonique, désormais en TOKENS (`--col-orient` 240 · `--col-state` 320 · `--col-gap` 20),
calculée en CSS : aucune mesure JS, rien à resynchroniser au redimensionnement. La mécanique
NOMADE du dock est purgée avec ce qu'elle servait (règle 14).

**A25. TROIS GABARITS DE FENÊTRE, DEUX RÉGIMES DE PLACEMENT (v5.6, planches 7e/8d).**
LARGEURS : CONFIRMATION 420 (`.dlg-confirm`) · DIALOGUE 480 (`.dlg-480`) · ATELIER 720 (défaut).
⚠ Une largeur écrite EN LIGNE (`style="max-width:…"`) échappe à TOUS les garde-fous statiques
(ils lisent le bloc `<style>`, leçon A23) : il n'y en a plus aucune, et un témoin le mesure au
RENDU. STRUCTURE : en-tête fixe, corps qui défile, pied fixe — la carte est le défileur, plafonnée
à la hauteur visible, et le corps SE NOMME (`.ai-body`) ; un « dernier enfant flexible » deviné en
CSS ferait de tout ajout futur un défileur par accident. Bornée par `:has(>.ai-body)` : les
fenêtres à contenu court et hétérogène gardent la modale pour défileur.
PLACEMENT — ET C'EST UNE NATURE, PAS UNE QUATRIÈME LARGEUR : « sous 780 px, toute fenêtre devient
une feuille pleine hauteur » (SPEC §6) vaut pour un DOCUMENT (long, non borné, qu'on parcourt) ;
un CHOIX (court, borné, dont on sort au geste suivant) reste centré, à la hauteur de son contenu
(`.dlg-center`, et `.dlg-confirm` qui l'avait déjà compris). Un titre unique partout :
`--t-step` / 800.

**A26. LES FILTRES SONT UNE FEUILLE (v5.6, planche 8c).** Le dépliant d'en-tête faisait GRANDIR le
chrome collant au moment précis où l'on demande à voir la liste — on ouvrait les filtres, l'écran
rendait MOINS de contenu —, les trois familles ne s'y voyaient jamais ensemble, et un dépliant ne
peut pas ANNONCER son résultat. La feuille le peut : « Voir les 11 résultats », c'est-à-dire savoir
ce qu'on obtient avant de refermer pour regarder. `state.filtersOpen` garde son nom et son statut
(le temps de la page, ni persisté ni synchronisé) : seule sa FORME change. Mesuré : ouvrir déplace
le contenu de 0 px et le chrome de 0 px.
⚠ CE QUI N'EST PAS REPRIS DE LA PLANCHE : « Créer » en bouton FLOTTANT sous 600 px. Une barre
flottante donne la place la plus saillante de l'écran, en permanence, à l'action la plus FROIDE de
l'accueil — l'inversion de saillance que l'audit A3-1 a relevée sur cet écran —, et le seul objet
flottant du produit porte des gestes d'URGENCE. Le besoin réel (ne pas remonter tout l'annuaire
pour créer) est déjà tenu : « ＋ » vit dans la rangée persistante et survit au défilement.

**A27. L'EN-TÊTE DE L'ACCUEIL SE RESSERRE AU DÉFILEMENT, ET RIEN N'Y BOUGE (v5.6, planche 7a).**
`body.home-slim`, posée par `syncHdrScroll` avec hystérésis (80 px vers le bas, 40 au retour) :
partent la marque, le logo et la rangée de chips ; restent le champ, « ＋ », le déclencheur de
filtre et le compte. Mesuré : 114 → 62 px à 390 (110 → 62 à 320), le champ à l'abscisse 18 dans
les deux états.
⚠ LA MICRO-ANIMATION EST DE PEINTURE, ET CE N'EST PAS UNE TIMIDITÉ : l'en-tête prend son ÉLÉVATION
(ombre + filet, ~160 ms, inerte sous reduced-motion). Faire FONDRE ce qui part a été essayé puis
mesuré faux — pour être fondus, la marque et le logo doivent rester dans le flux, or un élément de
largeur nulle CONSOMME QUAND MÊME les deux `column-gap` qui l'entourent, et le champ se déplaçait
de 18 à 34 px. Animer la HAUTEUR n'a jamais été une option (check-anim, et v4.41.0).
⚠ ET TOUTE GÉOMÉTRIE ANCRÉE À L'EN-TÊTE DOIT S'ANCRER À SON ÉTAT DÉPLOYÉ : le rail A→Z se posait
sur la hauteur DU MOMENT, si bien que tout re-rendu pendant qu'on avait défilé agrandissait sa
boîte de 52 px et déplaçait les lettres centrées de 26 px sous le doigt (règle de v5.0.9,
appliquée à un second objet).

**A28. DEUX NIVEAUX DE SÉPARATION DANS LE RAIL (v5.6, signalé à l'usage).** Une FAMILLE se sépare
par l'ESPACE et par son titre — petites capitales, graisse 800, son compte : un marqueur bien plus
fort qu'un filet, et ajouter un trait par-dessus est l'inflation de trait, la même faute que le
rouge permanent. Le FILET reste à l'ITEM, qui n'a que lui. ⚠ Une carte (`.rs-sec`) ne reçoit PAS ce
traitement : lui retirer son `border-top` lui ouvrirait le haut — une carte se sépare d'une autre
par un écart, point.

**A29. LE VOLET DU QUAI PROLONGE LA CAPSULE (v5.6, signalé à l'usage).** La v5.4.1 en avait fait un
ÉTAGE du chrome : bonne structure, géométrie d'avant — posé sous TOUT le bandeau et de bord à
bord, il se lisait comme une seconde barre. Il prend la largeur de la CAPSULE et se colle à elle,
coins vifs en haut, arrondis en bas : un seul objet, deux étages. Les deux valeurs viennent du
rembourrage du bandeau et vivent contre lui, sans une mesure JS. V1 et V2 inchangés et mesurés :
rien ne bouge derrière, la capsule reste en place et au-dessus.

**A30. LE THÈME A DEUX ADRESSES, ET C'EST UNE EXCEPTION ASSUMÉE (v5.6, décision utilisateur).** Le
réglage canonique est à froid, dans Compte › Affichage ; un RACCOURCI vit dans l'en-tête, en
LECTURE d'une aide ou d'une référence seulement. Deux contrôles pour une même valeur enfreint
§5.5 — l'exception se justifie par le MOMENT, pas par la commodité : une chambre qu'on éteint au
chevet pendant un soin, où ouvrir une fenêtre de réglages n'est pas envisageable. Il n'existe donc
PAS sur l'accueil, où la fenêtre Compte est à un tap. Trois crans, dans l'ordre du réglage : une
bascule à deux laisserait « Auto » inatteignable depuis la fiche. Sa condition est la VUE, jamais
la largeur (v4.31.0).
COROLLAIRE — LA RANGÉE D'ACTIONS N'A QU'UN GABARIT : 36 px de dessin, 44 de cible par le halo,
pour les quatre contrôles. Le menu ⋯ était le seul à 44 px de DESSIN (sur une rangée de glyphes,
le plus gros se lit comme le plus important) et l'avatar portait un halo calibré du temps où il
faisait 30 px — sa cible montait à 50 et CHEVAUCHAIT celle de son voisin. Et « Créer » ne change
plus d'habit selon l'état du CONTENU : la règle « un seul bouton rempli » vise les boutons de
TEXTE du flux, pas un glyphe du chrome sur la seule rangée qui ne doit jamais se réapprendre.

**A31. LES HACHURES SONT UN FILET, PAS UNE BANDE (v5.6, maquettes).** Fond `--primary-soft`, filet
d'UN pixel tous les dix à 12 % de l'encre primaire, à −45°. ⚠ La mise en phase de v5.0.5 CONTRAINT
la géométrie : la période s'écrit en POURCENTAGE de la ligne de dégradé — sur une tuile carrée de
31 px cette ligne vaut 43,84 px, donc 25 % donne un pas de 10,96 px et 2,3 % un filet de 1,0 px,
soit le dessin de la maquette ET quatre périodes exactes par tuile. Écrire « 1px / 10px » en dur
casserait le raccord entre l'en-tête et le bandeau. Jamais le raccourci `background`.

**A32. ⏱ UN COMPTEUR S'INCRÉMENTE DEPUIS LE VOLET — UN GESTE, DEUX FAITS, UNE SEULE LIGNE (v5.6,
demande utilisateur).** Incrémenter pose DÉJÀ son propre repère horodaté (v4.52.0) : appeler le
chemin du « + » depuis le volet ⏱ produirait DEUX lignes à la même seconde pour un seul acte —
le doublon que « ✓ Consigné à … » existe pour supprimer. La chip ATTACHE donc le compteur au
repère que le tap vient de poser, avec la valeur ATTEINTE ; le minuteur lié est armé comme au
« + » (même acte clinique, il ne peut pas avoir deux comportements selon l'endroit). TRANSPARENCE :
la chip dit sa destination AVANT le tap (« 0 → 1 »), et `#srLive` l'annonce après.
⚠ UN RANG NE GARANTIT RIEN, IL ORDONNE : sur un bloc de six étapes les compteurs tombaient au
septième rang et disparaissaient d'une liste bornée à six. `tagSuggest` reçoit un paramètre
FACULTATIF `garantis` qui leur réserve les premières places.

**A33. EN CRISE, LE HARNAIS D'ACCESSIBILITÉ MESURE TOUT — LES EXEMPTIONS SE NOMMENT (v5.6, planche
8f).** Une liste de racines est un contrôle par liste blanche : elle ne mesure que ce qu'on a pensé
à y mettre, et le dossier a payé ce trou trois fois. Dès qu'une session est à l'écran, `audit-a11y`
scanne la page entière ; hors crise la liste demeure (ces écrans n'ont pas le contrat des 44 px).
L'inversion a trouvé QUATRE violations AA qu'aucune racine ne contenait — `.skiplink` à 40 px,
trois textes de la carte de bloc en `--ink-3` à 2,32:1, la réponse attendue d'une étape cochée, et
un séparateur « · » à 1,33:1 (supprimé : un séparateur qui doit rester discret ne s'écrit pas en
lettres, c'est un ÉCART). Trois invariants entrent en même temps dans `audit-doctrine` : **A9**
(un changement d'état non commandé ne modifie aucune hauteur), **A6 au RENDU** (ce que check-type
ne peut pas voir), **A11** (au plus une masse colorée). ⚠ Un minuteur à CYCLES n'est jamais échu —
il se relance : couper la boucle avant de forcer l'échéance, sinon le témoin ne rencontre pas son
cas et mesure deux fois le nominal.

**A34. ACQUITTER N'EST NI RELANCER NI REMETTRE À ZÉRO (v5.6, signalé à l'usage : « un minuteur
sans relance, une fois échu, s'affiche dans le bandeau session et tout, c'est super ; mais aucun
moyen de le faire disparaître que de le relancer »).** La doctrine v4.2.0 disait « acquittement par
l'ACTION », et elle a raison sur le fond — une alarme ne se referme pas d'un revers de main. Mais
elle ne prévoyait qu'UNE façon d'agir, alors que l'action juste est parfois « c'est noté, je n'ai
plus besoin de ce minuteur ». Une TROISIÈME sortie s'ajoute donc, sur la carte du minuteur
concerné : « ✓ Vu » (`t.ack`). C'est le **master caution de l'ECAM** — on l'acquitte à SA station,
la panne reste écrite.
· **L'ÉTAT NE CHANGE PAS** : la carte continue de dire « échu », le compte rendu n'y perd rien ;
  seule l'ANNONCIATION cesse — le minuteur quitte la capsule. ⚠ Le filtre vit dans `run` et pas
  seulement dans `dueList` : en ÉTROIT le quai porte la liste ENTIÈRE (`withRem.slice(0,1)`), et
  filtrer plus bas ne changeait rien sur le format où le défaut a été signalé (mesuré).
· **LE DRAPEAU MEURT AVEC L'ALARME** : `toggleTimer` et `resetTimer` le remettent à faux — une
  nouvelle échéance est une nouvelle alarme, elle s'annonce.
· **LE BOUTON PARAÎT AU TICK, PAS AU RENDU** (`syncTimerBtns`) : une échéance survient sans qu'on
  touche à rien ; posé seulement par `timerCard`, il n'apparaîtrait qu'au prochain rendu complet,
  c'est-à-dire peut-être jamais. Le clic est donc DÉLÉGUÉ, jamais câblé au rendu.
· **GESTE OUVERT À TOUS LES RÔLES et LOCAL** : acquitter n'efface rien et ne conduit rien. Rien ne
  diverge, puisque l'état du minuteur est inchangé — c'est la même échéance, silencée ici et pas
  là-bas, ce que fait tout acquittement d'alarme.
· **⚠ A9 — IL NE PREND PAS UNE LIGNE DE PLUS** : mesuré d'abord à **214 → 264 px**. Dans une
  colonne de 136 px la rangée de commandes a DÉJÀ ses deux boutons l'un sous l'autre ; un
  troisième y ajoutait mécaniquement une ligne, quelle que soit sa largeur. « ✓ Vu » **se sert donc
  dans la part de la remise à zéro** (52 px pris, 62 px laissés au lieu de 120) : les seuils
  d'enroulement des deux états coïncident AU PIXEL — sans cette soustraction, il existerait une
  bande de largeurs où la carte échue serait plus COURTE que la nominale, le même défaut à
  l'envers. Il se glisse ENTRE le bouton principal et la remise à zéro : en tête, c'est lui qui
  aurait chassé le principal à la ligne suivante. Δ = 0 px mesuré à 136, 200, 250 et 320 px.
· **VINGT-ET-UNIÈME PIÈGE DE CASCADE** : `.rt-dock .tm-btn` (0,2,0) pose `flex:1 1 120px` — la
  règle du bouton, écrite en (0,1,0), perdait et la ligne de plus revenait. Portée à (0,2,0)
  ET (0,3,0), jamais par l'ordre de déclaration.
· **UN SEUL TÉMOIN POUR UNE SEULE MANŒUVRE** : l'acquittement est mesuré DANS la section A9, qui
  fait déjà échoir un minuteur volet ouvert — une section à part aurait rechargé le même contexte
  pour le même geste, et deux sections qui montent le même décor finissent par diverger.
· **⚠ LE TÉMOIN NE RENCONTRE SON CAS QU'EN COLONNE ÉTROITE** (vérifié : à 1280 il reste VERT sur
  le défaut, la rangée du rail ne s'enroulant pas), et il compare **les deux états ÉCHUS** — avec
  et sans le bouton — jamais l'échu au nominal : dans le rail, une carte nominale replie ses
  commandes et les rouvre en échéant, ce qui est une décision antérieure et une autre question.
· **LE LIBELLÉ RÉSERVE SES DEUX LIGNES (corrigé dans la foulée)** : en échéant, « Réévaluation
  après adrénaline » devient « ■ … — à réévaluer » et passait de UNE ligne à DEUX — carte 200 →
  214 px à 320. Le clamp à deux lignes BORNE le maximum, il ne fixe pas la hauteur : c'est
  `min-height:2lh` qui la fixe, sur `.rt-dock .tmcard .tm-label` (pas sur les compteurs, qui ne
  changent pas d'état). **On ne raccourcit pas le libellé à la place** — le suffixe dit ce qu'il
  faut FAIRE (action au pied de l'alerte), et le retirer ne garantirait rien : un nom qui tient
  tout juste sur une ligne se remettrait à enrouler pour le seul glyphe « ■ ». Coût dit : +14 px
  sur une carte à libellé court en colonne unique ; à 390 px la carte valait DÉJÀ 214 des deux
  côtés — la réserve harmonise plus qu'elle ne coûte.
· **EXCEPTION NOMMÉE, DANS LE RAIL** : une carte de minuteur y replie ses commandes et les ROUVRE
  en échéant (+6 px, mesurés). C'est une décision antérieure et elle est juste — les commandes
  d'une alarme doivent être sous la main à l'instant où elle sonne (ECAM : l'action au pied de
  l'alerte). Ne pas la « corriger » en supprimant la révélation.
· **⚠ MESURER LE CAS, PAS LE CORRECTIF** : depuis la réserve, la BOÎTE du libellé fait deux lignes
  dans les deux états — un témoin qui mesurerait sa hauteur mesurerait le correctif. On compte les
  lignes du TEXTE (`Range.getClientRects()`), insensibles au `min-height`, et **à 320 px seulement**
  (à 390 la colonne fait 136 px, le libellé y occupe déjà deux lignes des deux côtés : le contrôle
  y resterait vert sur le défaut).

**A35. LE SÉLECTEUR SEGMENTÉ EST UN COMPOSANT À N SEGMENTS (v5.6, signalé à l'usage : « le fond qui
glisse est trop large », « A–Z / Catégories devrait être comme les autres »).** La mécanique à N
vivait sur un `#id` (le sélecteur de taille de texte, v4.71.1) : ailleurs, la pastille était
dimensionnée par `flex:1`, **qui n'égalise pas deux libellés de longueurs différentes**
(`min-width:auto` recale chaque item sur son texte — mesuré 79 px de pastille pour un bouton de
43). Le composant porte désormais des PISTES DE GRILLE (`--seg-n`, `--seg-i`, `--seg-gap`) : la
pastille vaut une piste, par construction, quel que soit le nombre de segments. La mécanique à
DEUX est laissée intacte (`.seg.i1` continue de piloter la tab bar historique et « Créer »).
· **`.grp-seg` est un HABILLAGE, pas une seconde mécanique** : le groupement de l'accueil garde son
  fond et son contour, il ne réimplémente rien.
· **⚠ PIÈGE DE CASCADE** : `.seg` est déclarée ~4 000 lignes plus bas que la variante ; à
  spécificité égale, l'écart de gouttière était silencieusement ignoré — d'où `.seg.grp-seg`.
· **⚠ ET LA PASTILLE PREND LE REGISTRE DU COMPOSANT, jamais un aplat sombre** : mesuré 1,04:1 sur
  le libellé actif, la sonde d'`audit-a11y` remontant les ancêtres et trouvant un fond sombre sous
  une encre claire. Un objet en position absolue derrière du texte est un FOND, pas une décoration.

**A36. L'EN-TÊTE A UNE SEULE HAUTEUR, QUELLE QUE SOIT LA VUE (v5.6, signalé à l'usage).** Accueil et
lecture ne s'accordaient pas : le champ de recherche imposait sa hauteur propre à la rangée
d'identité. La rangée porte un `min-height` et le champ se règle en REMBOURRAGE — une rangée de
chrome dont la hauteur dépend de son contenu est une rangée qui se déplace en changeant de vue, et
tout le chrome de crise s'y ancre (`--hdr-h`, `stickBase()`).

**A37. LE VOLET DU DOCK A LA BOÎTE DE LA BARRE FLOTTANTE, ET IL EN EST SÉPARÉ (v5.6, signalé à
l'usage : « n'est plus adapté à la nouvelle taille de la barre, et est décalé »).** Depuis A24 la
barre s'aligne sur la COLONNE D'ACTION : le volet de ⏱/⚡ suit donc la même géométrie — mêmes
marges de grille, jamais la largeur de la fenêtre. Il se pose AU-DESSUS de la barre, à `--dock-h`
(hauteur MESURÉE, posée par `syncDock`) plus un écart : la maquette le montre légèrement détaché,
et un volet qui recouvrirait ses propres touches masquerait le geste qu'on vient de faire. Mesuré
identique à 390, 900 et 1280 px.

**A38. L'EXERCICE S'ARME, ET CE QUI S'ARME SE DÉSARME (v5.6, décision utilisateur).** Taper
« Exercice » ne démarre rien — comportement attendu, conservé —, mais il n'existait alors AUCUN
moyen de revenir en arrière : le mode restait armé jusqu'au démarrage. Re-taper la touche l'annule
(`cancelExercise`), et **le geste d'entrée dit ce qu'il va démarrer** (« Confirmé — démarrer
l'exercice » / « … la session ») : un bouton qui nomme autre chose que ce qu'il fait est la
première cause de mode confusion (FAA).

**A39. UN FILTRE POSÉ AGIT AUSSI EN RECHERCHE (v5.6, signalé à l'usage : « quand on change de
catégorie, rien ne se passe »).** Le cran (bibliothèque, catégorie) n'était appliqué qu'au
RÉPERTOIRE ; dès qu'on tapait, la liste passait en tri par pertinence et l'ignorait. Un filtre
visible qui ne filtre pas est pire qu'un filtre absent — c'est la règle « un filtre posé ne doit
jamais être invisible », prise par l'autre bout.

**A40. UNE FICHE D'UN SEUL BLOC EST UNE FICHE COMME LES AUTRES (v5.6, signalé à l'usage : « bloc mal
affiché, parcours inerte absent »).** Deux causes, une seule leçon. `hasFlow(f)` — « y a-t-il un
embranchement ? » — décidait de choses qu'il ne gouverne pas : l'existence du PARCOURS INERTE (une
fiche d'un bloc a un parcours : un bloc) et le mode de rendu. Et **le mode était résolu DEUX FOIS**,
au rendu et dans le binder, chacun avec sa formule : le compteur d'avancement restait figé sur
« 1/2 ». `readModeOf(f)` est la source UNIQUE, et la colonne d'orientation se conditionne à
l'existence de BLOCS, jamais à celle d'un embranchement.

**A41. UN CLIC QUI DÉPLACE LE FOCUS SE VOLE LUI-MÊME — LA LISTE DE LA v4.77.0 S'ÉTEND AUX PORTES
D'AJOUT (v5.6, signalé à l'usage : « ＋ Rappel n'enregistre pas ce que je viens de taper »).** Entre
`pointerdown` et `mouseup`, le champ perd le focus, la rangée referme ses outils (`:focus-within`),
la page se resserre — le bouton n'est plus sous le pointeur et **aucun `click` n'est émis**. Tout
contrôle voisin d'un champ éditable entre donc dans le `preventDefault` de `pointerdown`.
· **⚠ LEÇON DE SONDE, payée ici** : ma première mesure cliquait le bouton sans avoir fait défiler
  jusqu'à lui (y = 5 367) et concluait « ＋ n'ajoute jamais rien » — un diagnostic faux sur un
  défaut réel. Une sonde qui clique hors écran mesure l'écran, pas l'application.
· **⚠ ET UN `.click()` PROGRAMMATIQUE NE DÉPLACE AUCUN FOCUS** : le témoin doit cliquer pour de
  vrai, sinon il reste vert sur les sept familles de listes.

**A42. UN LOT DISTANT S'APPLIQUE TOUJOURS ; SEULE LA PEINTURE DÉPEND DE LA VUE (v5.6, signalé à
l'usage : « en session partagée, les blocs disparaissent chez l'hôte et ne reviennent pas »).**
`onEvents` sortait sans rien appliquer dès que la vue n'était pas `read`, et **la perte était
DÉFINITIVE** : le curseur est avancé par l'appelant AVANT cet appel, donc le lot n'est jamais relu.
Il suffisait que l'hôte revienne à la bibliothèque pendant que le collègue avance. Le commentaire
disait « le pli suffit » — vrai chez l'INVITÉ, dont l'état EST le pli ; chez l'hôte la session
locale fait autorité et rien ne la rattrape. On applique donc toujours, et l'on MUSELLE la seule
queue qui pouvait déclencher un rendu complet, c'est-à-dire arracher quelqu'un à l'écran qu'il
regarde. Le `catch` vide disparaît avec : il laissait un lot à moitié appliqué sur un curseur déjà
avancé.

**A43. UN OBJET PLEIN DOIT SE DÉTACHER DE SON FOND — LA PASTILLE DU COMPTE EN SOMBRE (v5.6,
signalé à l'usage).** Mesuré : le bouton Compte et la barre valent tous deux `--sys` en thème
sombre, soit **1,00:1**. Les initiales restent lisibles (14,4:1) — ce n'est donc pas un défaut de
TEXTE, et `audit-a11y`, qui mesure le texte, ne pouvait pas le voir : c'est la LIMITE DU COMPOSANT
que WCAG 2.2 § 1.4.11 protège. C'est le seul contrôle de la rangée à porter un APLAT (ses voisins
sont transparents et se lisent par leur glyphe, ce qui est leur nature) ; il reste un DISQUE
d'identité, on lui rend donc un filet plutôt qu'on ne le vide. `--ctl-line` (3,68:1 mesuré), en
ombre INTERNE et non en bordure — 36 px de dessin pour 44 px de cible, une bordure changerait la
boîte et l'alignement des quatre contrôles (A30). Le thème clair n'en a pas besoin : 15,8:1.

**A44. LE RAIL A→Z EST CENTRÉ SUR L'ÉCRAN, PAS DANS SA PROPRE BOÎTE (v5.6, signalé à l'usage).**
Sa boîte commence sous l'en-tête — la v5.0.0 l'y avait bornée pour qu'aucune lettre ne passe
derrière lui —, si bien que des lettres centrées DEDANS tombaient 58 px sous l'axe médian de
l'écran à 390 px (55 à 1280). On ne déplace pas la boîte : elle garde toute la place disponible,
donc le rail continue de s'afficher sur un alphabet complet. C'est le DÉCALAGE du premier
caractère qui est posé (`azrCentrer` : la colonne passe en `flex-start`), **clampé à la place
réellement disponible** — rendre plus rognerait des lettres, et une lettre coupée est injoignable
en silence.
· **LA CIBLE SE MESURE, ELLE NE SE DÉDUIT PAS** : le haut de la boîte vaut le bas de l'en-tête en
  voie étroite, mais PAS en voie large (110 px mesurés pour un en-tête de 61) — une formule
  « rends la hauteur de l'en-tête » y laissait 24 px d'écart.
· **LA HAUTEUR DE RÉFÉRENCE EST `documentElement.clientHeight`** : la seule qui ne suive NI la
  barre d'outils NI le clavier. Le calcul ne tourne qu'au rendu et au redimensionnement — rien qui
  bouge pendant qu'on vise (leçon v5.0.2, et c'est le même objet qui l'avait enseignée).
· **LA CLASSE N'EST POSÉE QU'UNE FOIS LE DÉCALAGE CALCULÉ** : avant, les lettres restent centrées
  dans leur boîte — jamais collées en haut le temps d'une image.

**A45. « VÉRIFIER » EXISTE SUR TOUT BLOC D'ÉTAPES — CORRECTION DE A7 (v5.6, signalé à l'usage :
« où est passé le bouton vérifier ?? »).** En écrivant A7 j'avais ajouté une condition que la
maquette ne demande pas : « seulement si le bloc porte des challenges “::” », au motif que « sans
::, il n'y a rien à rejouer ». **C'est faux**, et la doctrine v4.11.0 le dit depuis toujours : la
passe Do-Verify « redéroule TOUTES les étapes, déjà cochées comprises », et ses deux réponses —
« Constaté ✓ » qui coche, « △ Écart » qui avance sans cocher — ne dépendent d'aucune réponse
attendue. Le « :: » ENRICHIT la passe, il ne la conditionne pas. La condition rendait le bouton
invisible sur toute fiche qui n'écrit pas de challenges, c'est-à-dire presque toutes. Le libellé
perd son « :: » avec elle : un bouton ne nomme pas une syntaxe que le bloc n'emploie peut-être pas.
La PLACE ne change pas (pied de carte, à gauche de « Continuer ») et un bloc de DÉCISION en reste
exclu — il n'a pas d'étapes à re-constater.

**A46. UN TÉMOIN D'ANCRAGE NE MESURE RIEN S'IL EST COLLÉ AU BAS DE LA PAGE (v5.6, trouvé en
restaurant « Vérifier »).** Le témoin d'ancrage travaillait sur une fiche de six étapes : 982 px de
document pour une fenêtre de 900, donc un défilement collé au MAXIMUM. Décocher après la fin retire
la bannière de fin, la page raccourcit, **le navigateur rabat le défilement** — et les 22 px de
rabat étaient imputés à l'ancrage, qui ne peut rien contre une fin de page. Un simple bouton rendu
à la carte déplaçait cette limite et faisait rougir un correctif juste. Le témoin vérifie
désormais qu'il n'est PAS au bout, et sa fiche a de quoi défiler.
⚠ ET IL FAUT DIRE CE QU'IL PROUVE : sur ce chemin, rien ne change au-dessus de l'ancre — neutraliser
la compensation le laisse vert. Le contrôle de dérive est donc un GARDE ; celui qui est capable
d'échouer est « le remplacement est ANCRÉ » (un re-rendu nu le fait rougir).

**A47. UNE SORTIE DE MODE SE MET AU BOUT DE LA LIGNE QU'ELLE FERME (v5.6, signalé à l'usage : « sur
vérifier, l'option pour fermer ne tient pas sur une ligne — texte et croix ne sont pas sur la même
ligne, même en desktop »).** L'en-tête d'une carte de bloc est fait pour porter le titre sur toute
la largeur et les gestes DESSOUS (`.ov-tgl{flex:1 1 100%}`) : c'est juste pour « ↺ Refaire », qui
est une action de la LISTE, et faux pour la sortie d'un MODE — mesuré, le ✕ tombait seul sur une
seconde ligne, y compris à 1280 px, pour 133 px d'en-tête (89 après). Sa cible passe en outre à
44 px de LARGE : elle n'en faisait que 31, la règle n'ayant jamais été vérifiée sur un bouton qui
ne porte qu'un glyphe. Modificateur préfixé par son composant (`.ov-block.vfy`), en (0,3,0) :
il gagne quel que soit l'ordre de déclaration.

**A48. VINGT-DEUXIÈME DÉFAUT DE RANGÉE FLEX — L'EN-TÊTE DE BLOC DE L'ÉDITEUR (v5.6, trouvé au
BALAYAGE, pas signalé).** `nowrap` avec DEUX objets incompressibles (pastille, sélecteur de phase
à 191 px) et un seul capable de céder : le champ TITRE tombait à **26 px** pendant que la poignée ⠿
sortait de **35 px** du cadre, à 320. Même famille que la v4.74.0 (bandeau de déplacement) et la
v4.55.3 (croix du panneau) — quand tout est incompressible sauf un, c'est cet un-là qui paie, et le
débordement part par le côté opposé. **On enroule, on ne tronque jamais** : à l'étroit, phase et
poignée descendent d'une ligne et le titre garde 221 px ; à 1280 tout revient sur une rangée.

**A49. UN RENDU NE DOIT PAS S'INTERROMPRE LUI-MÊME (v5.6, trouvé au balayage).** Un champ d'étape
VIDE se supprime au départ du focus (MK-flux) — mais ce `blur` peut être celui du RENDU : remplacer
le contenu de `main` retire le champ focalisé, donc l'émet. Re-rendre depuis là revient à écrire
dans `main` pendant qu'on y écrit ; Chrome lève « The node to be removed is no longer a child of
this node », **le rendu extérieur avorte en plein milieu**, et ce qui le suivait — câblage des
écouteurs, restitution du focus, ancrage — ne s'exécute jamais. Un simple redimensionnement suffit
à le produire.
· **DEUX GARDES, ET LA SECONDE EST LA VRAIE** : on sort de la pile courante (`setTimeout`), et l'on
  ne supprime QUE si aucun rendu n'a eu lieu **depuis la POSE de l'écouteur** (`_renderN`).
· **⚠ DEUX DISCRIMINANTS ÉCARTÉS À LA MESURE** : `inp.isConnected` — au moment où l'évènement part,
  le nœud est encore attaché ; et le compteur lu AU BLUR — la trace est « render → renderEditor →
  blur », donc le rendu fautif a déjà incrémenté. Seule la valeur capturée au BIND répond à la
  vraie question : cet élément appartient-il encore au rendu courant ?
· **CE QUE CELA CHANGE POUR L'AUTEUR** : une ligne vide survit à un re-rendu qu'il n'a pas demandé.
  C'est voulu — ce n'est pas lui qui a quitté le champ.

**A50. DEUX BOÎTES QUI SE TOUCHENT NE FONT PAS DEUX NOIRS QUI SE TOUCHENT (v5.6, signalé à l'usage :
« le noir du bandeau ne touche pas le noir du début du menu »).** Le bas de la capsule et le haut du
volet étaient DÉJÀ au même pixel, mêmes bords, même largeur — mesuré. Ce qui se voyait n'était pas
un écart de géométrie mais un écart de PEINTURE : le quai porte 8 px de rembourrage sous la capsule,
il est de la matière d'AMBIANCE, et il peignait par-dessus le haut du volet (z 15 contre 14).
Le volet monte donc à **z 16**, entre le quai et l'en-tête.
· **V2 EST INTACTE** : le volet COMMENCE au bas de la capsule, il ne peut rien couvrir d'elle — il
  ne recouvre que le rembourrage, qui n'affiche rien.
· **⚠ ET LE TÉMOIN DE V2 MESURAIT LE MÉCANISME** : il exigeait `z(quai) > z(volet)`, donc il a
  rougi sur un correctif juste. Il mesure désormais la PROPRIÉTÉ que V2 promet — la capsule ne
  bouge pas et rien ne la recouvre (`elementFromPoint` en son centre).
· **ON MESURE LA COULEUR EFFECTIVE, PAS LES RECTANGLES** : c'est en remontant jusqu'au premier fond
  opaque que le défaut se voit ; comparer les boîtes laissait le témoin aveugle.

**A51. LE VOLET SE DÉROULE, EN `transform` PUR (v5.6, proposition de l'auteur).** L'animation répond
à un GESTE — elle ne survient pas toute seule : c'est la distinction que le dossier fait déjà pour
l'élévation de l'en-tête (A27) et la chip épinglée. **On ne peut pas animer une hauteur**
(`check-anim` : une propriété de mise en page coûte une passe de layout par image, v4.41.0), donc le
déroulé est un `scaleY` depuis le HAUT, **avec le contre-scale exact sur le contenu** — la boîte se
déroule, le texte ne s'étire pas. 180 ms, aucun résidu à la fin (mesuré), inerte sous
`prefers-reduced-motion` (la règle vit dans le bloc `no-preference`, donc l'inertie est acquise par
construction et non par une seconde règle à tenir).

**A52. « VÉRIFIER :: » GARDE SON LIBELLÉ DE MAQUETTE (v5.6, décision de l'auteur).** A45 avait
retiré la CONDITION (le bouton existe sur tout bloc d'étapes) et, dans la foulée, le « :: » du
libellé. C'était une correction de trop : le « :: » nomme la PASSE — challenge-réponse —, il
n'annonce pas un pré-requis du bloc. La maquette l'écrit ainsi ; le mot revient.

**A53. DEUX BOÎTES QUI SE TOUCHENT DOIVENT AUSSI S'ACCORDER PAR LEURS COINS (v5.6, signalé à
l'usage : « il reste des px blancs »).** Après A50, capsule et volet se touchaient au pixel, même
largeur, même noir — et il restait deux encoches claires : la capsule est ARRONDIE en bas, le volet
VIF en haut, et le fond de page passait dans les angles. Tant que le volet est ouvert, la capsule
perd ses coins bas (`body:has(.rt-dock)`). Un seul objet à deux étages : arrondi en haut, arrondi
en bas, jointure franche.

**A54. « ✓ VU » NE DOIT PAS COUPER SES VOISINS (v5.6, signalé à l'usage : « le texte est un petit
peu tronqué »).** Deux endroits, deux réponses, et la même règle — un mot COUPÉ est moins lisible
qu'un mot absent, et personne ne doit deviner un libellé.
· **DANS LE VOLET**, la remise à zéro porte deux lignes (« ↺ 05:00 » et l'indice « maintenir »),
  ~118 px de texte ; à côté de « ✓ Vu », dans une colonne de 160 px, il lui en restait 75 et
  l'indice sortait en « MAINTEN… ». L'indice s'efface TANT QUE l'acquittement est là — le maintien
  reste, son `title` et son nom accessible le disent, et l'indice revient dès l'alarme acquittée.
· **DANS LE RAIL**, la rangée fait 140 px et ne s'enroule pas : « Relancer » y tenait à ZÉRO pixel
  près (90 px de bouton pour 78 de contenu et 12 de rembourrage), donc coupé dès qu'une fonte rend
  deux pixels plus large. Rétrécir l'acquittement ne rendait que quatre pixels — dans une colonne
  de 301 px la valeur du minuteur prend déjà la moitié. La rangée ENROULE donc tant que « ✓ Vu »
  est là, ce qui est cohérent avec la décision antérieure du rail (une carte échue ouvre ses
  commandes) ; le coût d'une ligne est TRANSITOIRE, il disparaît au premier acquittement.

**A55. LE CHEVRON DU CHAPEAU VIT DANS LA PASTILLE DU COMPTE (v5.6, demande de l'auteur).**
« 4 › » est UN objet : la pastille dit à la fois combien il reste de rappels et qu'elle se déplie.
⚠ CONSÉQUENCE IMMÉDIATE, mesurée : le repli écrivait `textContent` sur la pastille, ce qui EFFACE
son enfant — le chevron disparaissait au premier dépliage. Le compte a donc son propre porteur
(`.fs-cnt`), et l'on n'écrit plus que dedans. Règle générale : **dès qu'un nœud gagne un enfant,
tout `textContent` posé sur lui devient une suppression.**

**A56. 43 px, C'EST UN PIXEL DE TROP PEU (v5.6, trouvé au balayage étendu).** En lecture, le retour
d'en-tête se resserre et son halo de −6 px rendait une cible de **43 × 52** — sous les 44 px de la
zone haute, invisible à l'œil et hors du champ d'`audit-a11y`, qui mesure les surfaces AU REPOS et
non la barre en session. Un pixel de halo de plus, aucune géométrie déplacée : c'est exactement ce
pour quoi le halo existe. Il a désormais son contrôle dans la section de la rangée d'actions.
⚠ **CE QUE LE BALAYAGE A ÉCARTÉ, ET POURQUOI C'EST À DIRE** : le ✕ des fenêtres « sort » de 10 px
de l'en-tête de sa carte — c'est le halo compensé qui lui donne ses 44 px, son bord reste DANS la
carte (mesuré) ; et les contrôles de l'accueil à 32/38 px sont au plancher HORS crise, où la règle
des 44 ne s'applique pas. Un balayage qui ne nomme pas ses non-défauts finit par les faire
« corriger ».

**A57. « T+ » SE COMPTE DEPUIS LE DÉBUT DE LA SESSION, PARTOUT (v5.6, signalé à l'usage : « passé
minuit, le journal ne montre la différence qu'à partir de minuit »).** Ce n'était PAS un défaut de
minuit — toutes les durées du fichier sont des différences d'horodatages, insensibles au changement
de date, et `fmtMs` tient au-delà de 24 h (vérifié : un repère à 00:30 d'une session de 23:30
affiche « +1:00:00 »). C'était une RÉFÉRENCE divergente : le journal partait du PREMIER REPÈRE,
quand le compte rendu, l'accusé du volet ⏱ et la trace d'un compteur partent tous de `startedAt`.
Deux origines pour un même « T+ », donc deux vocabulaires pour une idée (§ 5.5) — et celle du
journal trompait dès qu'on notait le premier repère longtemps après le début.

**A58. UN OBJET SANS NOM EXISTE QUAND MÊME (v5.6, signalé à l'usage : « un compteur sans nom ne
s'affiche pas dans Noter l'heure »).** Confirmé : `tagAll` jetait tout objet dont le libellé est
vide, alors que sa CARTE affiche un nom par défaut — l'objet était donc visible à l'écran et
introuvable au moment de l'horodater. Le vivier reprend LE MÊME défaut que la carte (« Compteur »,
« Minuteur », « Chronomètre »), jamais un mot inventé pour l'occasion. Un REPÈRE sans étiquette,
lui, garde sa règle propre (« Action n ») : c'est une trace, pas un objet de la fiche.

**A59. UN MENU QUI S'OUVRE NE DÉPLACE PAS LA PAGE (v5.6, signalé à l'usage).** `focus()` sur la
première rangée du menu ⋯ faisait remonter le document de **399 px** à 390 px — le navigateur amène
l'élément focalisé dans la vue en respectant le `scroll-padding`, et il le fait même pour un menu
`fixed`. `focus({preventScroll:true})` : le menu s'ouvre sous le doigt, à position constante, et
rien ne bouge derrière lui. Même remède qu'au re-rendu d'une ligne d'éditeur (v4.78.0).

**A60. UNE LIGNE-BILAN BASCULE, ELLE NE FAIT PAS QUE DÉPLIER (v5.6, signalé à l'usage).** Le geste
écrivait `false` en dur : le groupe des blocs faits s'ouvrait et ne se refermait plus, alors que sa
TÊTE reste à l'écran avec un chevron « ⌃ » qui promet l'inverse. Un contrôle qui survit à son geste
doit pouvoir le défaire, sinon c'est un bouton mort qui ment. Le repli reste PERSISTANT et le
dépliage une consultation transitoire (`ovDropOpens`) : seul le sens du tap change.

**A61. UNE PLACE RÉSERVÉE VAUT LA TAILLE DE L'OBJET RÉSERVÉ (v5.6, signalé à l'usage : « le ✕ se
superpose à “Son activé” »).** L'en-tête du panneau réserve un couloir à droite pour son ✕ ancré :
40 px, quand celui du volet en fait 48 — les 8 px manquants ÉTAIENT le recouvrement, mesuré à 600,
700 et 768 px (le seul régime où la rangée tient sur une ligne). La réserve vaut désormais 48 + 8
d'écart : deux cibles de 44 px qui se TOUCHENT sont déjà un défaut (règle du rail A→Z).

**A62. LA SORTIE D'UN MODE SE MET SUR LA LIGNE QUI NOMME LE MODE (v5.6, signalé à l'usage — suite
d'A47).** Le ✕ avait rejoint la ligne du TITRE du bloc ; l'auteur visait plus loin : le seul texte
qui nomme la passe est « Vérification — lisez le challenge… », et un glyphe nu ne dit pas ce qu'il
ferme. La sortie descend donc sur cette ligne et porte son VERBE (« ✕ Quitter ») ; le NOM du mode et
sa sortie tiennent sur une rangée à toutes les largeurs, la consigne passe dessous en casse normale
(mesuré : 85 → 44 px de rangée sous 780 px), et l'en-tête du bloc perd une rangée.

**A63. LE CHEVRON DU CHAPEAU N'ÉTAIT PAS TRONQUÉ, IL ÉTAIT ÉTOUFFÉ (v5.6, signalé à l'usage).**
`line-height:1` lui donnait une boîte de 11 px pour un glyphe qui en occupe 14 : il débordait des
deux côtés et se posait 3 px sous le chiffre. Il prend l'interligne de la pastille, et les deux
enfants s'alignent sur leur milieu.

**A64. LE DÉCLENCHEUR DE FILTRES EST UN BOUTON ROND, GLYPHE SEUL (v5.6, demande de l'auteur, « comme
sur Apple »).** Trois filets horizontaux qui RÉTRÉCISSENT de haut en bas (16 · 10 · 4 dans une boîte
de 24, écart constant de 5 px), 38 px de dessin — la hauteur du sélecteur d'en face, deux contrôles
d'une même rangée qui ne font pas la même hauteur se lisant comme deux niveaux — et 46 px de cible
par le halo. Le mot « Filtres » disparaît (`.filt-l` purgée, règle 14) : sur la rangée la plus
disputée du produit, un contrôle à POSITION CONSTANTE s'apprend par sa forme.
⚠ **LA RÈGLE 8 TIENT PAR LE NOMBRE** : l'état actif est dit par le COMPTE de filtres posés, en
pastille sur le coin — jamais par la seule couleur —, et le nom accessible l'écrit en toutes
lettres. La pastille est POSÉE SUR le bouton et ne l'allonge plus : la position du déclencheur ne
doit pas dépendre du nombre de filtres.

**A65. UN COMPOSANT À N SEGMENTS N'EMPORTE PAS LE RACCOURCI À DEUX (v5.6, signalé à l'usage : « la
bulle ne glisse pas d'une option à l'autre »).** Deux causes, et la seconde est un piège de
spécificité : (a) le rejeu du glissement appelait `.seg-replay`, classe PURGÉE en v5.0.0 avec le
composant qu'elle servait — l'appel était resté, donc un no-op ; (b) le sélecteur émettait AUSSI
`.i1`, dont la règle `.seg.i1 .seg-pill` (0,3,0) bat le transform piloté par `--seg-i` : tant que la
classe est là, reposer la variable ne déplace RIEN. Le composant à N ne porte donc plus `.i1`, et le
rejeu repose la pastille à l'ANCIEN cran sans transition, force le calcul, puis pose le nouveau —
c'est la transition CSS qui fait le trajet (mesuré : 21 → 46 → 74 → 94 → 102).
⚠ **ET LA LEÇON DE SONDE** : ma première mesure gardait une référence à la pastille À TRAVERS le
re-rendu — un nœud détaché, qui rend une position figée et une transition vide. On re-interroge le
DOM à chaque échantillon.

**A66. UN HALO NE MORD JAMAIS SUR LA CIBLE DU VOISIN — ET UNE CIBLE PARTAGÉE EST FICTIVE (v5.6,
BALAYAGE DE COLLISIONS, rien de signalé).** Une sonde nouvelle : elle compare deux à deux les zones
tactiles (dessin + halo) de tous les contrôles d'un même PLAN — un dock, un volet ou une fenêtre
recouvre le contenu par construction, c'est son office, et ces paires-là sont écartées. Elle a
trouvé quatre recouvrements, tous invisibles à l'œil :
· **en-tête de l'accueil**, « Créer » ∩ « Compte » : **10 px à 320**, 4 à 390 — deux halos de 6 px
  pour 2 px d'écart. Dans cette bande, c'est le DERNIER élément du DOM qui reçoit le tap : on
  visait Créer, on ouvrait le Compte ;
· **barre de l'éditeur**, « ▶ Essayer » ∩ « ⋯ » : 4 px à 320, 2 à 390 ;
· **rangée de l'annuaire**, le bouton-titre ∩ la pastille « △ à compléter » : 13 px ;
· **volet du quai**, deux boutons de minuteur empilés : 2 px (halos de 4, écart de 6).
**LA RÈGLE QUI EN SORT** : un halo se borne à la MOITIÉ de l'écart qui le sépare de son voisin, et
un écart vaut au moins la somme des halos qu'il sépare. Le halo VERTICAL, lui, reste entier quand
rien ne le dispute — c'est la direction où l'on a de la place.
**⚠ ET UN ARBITRAGE À CONNAÎTRE, car il RELÂCHE une règle écrite** : à 320 px, deux cibles de 44 px
de large ne tiennent pas dans une rangée qui n'a que 2 px d'écart. On garde donc les **44 px de
HAUTEUR** et l'on borne la LARGEUR à la place réellement disponible (34 px à 320, 40 à 390) — au
-dessus du plancher de 32 px, qui est la règle HORS crise, et c'est bien de l'accueil qu'il s'agit.
Le témoin de la rangée d'identité mesure désormais les trois choses : hauteur ≥ 44, largeur ≥ 32,
et AUCUN recouvrement. Il exigeait 44 en largeur — une exigence qu'aucune géométrie ne pouvait
honorer sans voler la cible d'à côté.
**⚠ UN CAS RÉSISTE, ET IL EST DIT** : dans la rangée de l'annuaire, le titre et la pastille
« △ à compléter » sont séparés de 4 px de texte, et la rangée a un RYTHME fixe de 71 px. Les deux
cibles ne peuvent pas être conformes (≥ 24) ET disjointes ; réduire le titre le fait tomber à 22 px
(`audit-a11y` l'a dit immédiatement). On garde les deux conformes, et les 5 px résiduels se
résolvent en faveur de la pastille, qui est AU-DESSUS — la cible la plus petite et la plus précise
gagne, le titre gardant 38 px de bande franche.
**⚠ LEÇON DE SONDE, deux fois** : (a) « visible » ne veut pas dire « peint » — un élément dans un
panneau replié ou une boîte clipée garde un rectangle non nul, et la sonde a d'abord vu une puce de
catégorie « recouvrir » une poignée qui vit 200 px plus haut ; on exige donc que l'élément soit la
cible du point en son centre. (b) Le halo se lit par axe : `insetBlockStart` est le VERTICAL, et
mesurer une largeur avec lui laisse la sonde aveugle à sa propre correction.

**A67. `--line-strong` N'EST PLUS LE TOKEN DES BORDURES DE COMPOSANT — C'EST `--ctl-line` (v5.6,
trouvé au balayage).** La doctrine écrit depuis la v4.5 que « cases à cocher et bordures de champs
= `--line-strong` (3:1, WCAG 1.4.11) », et la v5.0.0 le mesurait à 3,93 / 4,94. **La palette v5.6
l'a re-valué** : il ne tient plus que **1,62:1 en clair et 1,33 en sombre** sur la matière de
travail. Celui qui tient le seuil est `--ctl-line` — c'est d'ailleurs ce que dit A43. Les contrôles
qui s'appuyaient sur `--line-strong` pour leur LIMITE passent donc à `--ctl-line` : la rangée
« Consulter » (un bouton pleine largeur dont ni le fond — 1,09:1 — ni le filet ne se voyaient), le
déclencheur de filtres, « Vérifier :: » et la sortie de la passe.
· **`--ctl-line` EST ASSOMBRI D'UN CRAN EN CLAIR** (#8a94a0 → #828c98) : il tenait 3,08 sur le blanc
  du travail mais 2,82 sur le gris d'AMBIANCE, où vivent aussi des contrôles bordés. 3,13 et 3,41
  après ; le sombre tenait déjà (3,68 / 4,05).
· **CE QUI N'EST PAS CHANGÉ, ET POURQUOI C'EST À VOUS** : en thème SOMBRE, la matière de travail et
  l'ambiance ne sont séparées que de **1,10:1**, et le filet des cartes (`--work-line`) de 1,33 —
  une carte de bloc n'a donc, la nuit, ni ombre (doctrine : « la nuit ne projette pas, elle borde »)
  ni bord perceptible. Idem pour la capsule sur son quai. Renforcer ces filets « grillagerait » tout
  le thème sombre : c'est une décision de signature, pas un correctif, et elle vous revient.

**A68. LA NUIT, LA MATIÈRE DE TRAVAIL SE DÉTACHE ET SON FILET TIENT LE SEUIL (v5.6, variante C
choisie sur maquettes).** Mesuré avant : travail contre ambiance **1,10:1**, filet contre travail
**1,21:1** — une carte n'avait donc, la nuit, ni ombre (« la nuit ne projette pas, elle borde ») ni
bord perceptible, et sur une colonne de cartes c'est le COMPTAGE qui échoue, pas la lecture.
`audit-a11y` ne pouvait pas le voir : il mesure le TEXTE, et le texte était à 14:1.
Après : `--work` #171a20 → **#1e232b** (matière 1,22:1) et `--work-line` #262a31 → **#667080**
(filet **3,15:1**, seuil de WCAG 2.2 § 1.4.11).
· **DEUX CANAUX PLUTÔT QU'UN, ET C'EST LE MOTIF DU CHOIX** : renforcer le seul filet (variante A,
  3,68:1 sur la matière inchangée) tenait le seuil aussi, mais chargeait le TRAIT — sur des cartes
  empilées le dessin se rapproche d'une grille, ce que « verre clinique » cherche à éviter. Ici la
  matière fait la moitié du travail, donc le trait peut rester fin.
· **`--sys` NE BOUGE PAS** : la capsule et le dock sont de la matière SYSTÈME. Effet second et
  bienvenu — les deux matières, jusque-là identiques la nuit (1,00:1), se distinguent désormais.
· **COÛT MESURÉ** : l'encre principale passe de 14,4 à **13,1:1** sur la carte. Le thème clair
  n'est pas touché.
· **⚠ CE QU'UNE MATIÈRE PLUS CLAIRE ENTRAÎNE, ET QU'UN TÉMOIN A ATTRAPÉ** : le placard d'exercice
  est un aplat `--primary-soft` posé SUR cette matière — l'écart entre les deux bandes est tombé de
  44 à 26 (seuil 30), c'est-à-dire que la hachure d'exercice redevenait douteuse la nuit, le défaut
  même que la v4.28.0 avait corrigé. `--primary-soft` se creuse donc par le BLEU (#13233a →
  #12263f, écart 35) : on rend l'écart sans rendre la teinte plus claire.
· **TÉMOIN** : dans la section A9/A6/A11, qui monte déjà le décor — on bascule le thème, on mesure,
  on le rend. Quatre contrôles : limite ≥ 3:1, matière détachée de l'ambiance, SYSTÈME ≠ TRAVAIL,
  et l'encre qui ne paie pas la note. Vérifié capable d'échouer (tokens d'avant → 3 rouges).

**A69. REPLIÉE, LA CARTE EST UN STATUT D'UNE LIGNE — ET CETTE LIGNE EST CENTRÉE DANS LA CARTE
(v5.6, signalé à l'usage, puis re-signalé).** L'en-tête d'une carte OUVERTE est fait pour deux
rangées — l'étiquette et le compte au-dessus, le grand titre en dessous (`.ov-t{flex:1 1 100%}`,
aligné sur les BASELINES). Replié, la même mise en page donnait une boîte de **73 px** où le numéro
et le compte flottaient 23 px au-dessus du milieu et le titre 7 en dessous.
· **UNE SEULE LIGNE, ALIGNÉE SUR LE MILIEU** : tout y tient côte à côte, le titre prend la taille du
  texte courant et s'ellipse — il revient en entier au dépliage, qui est à un tap. 73 → 44 px.
· **ET L'ORDRE SUIT LA LECTURE** : les `order` de l'en-tête ouvert placent le compte et le chevron
  AVANT le titre, parce qu'ils y vivent sur la rangée du dessus ; sur une seule ligne cela donnait
  « BLOC 1 · 0/5 ▾ · Mesures immédiates », l'état inséré au milieu de l'identité. Replié, on lit
  d'abord ce que c'est, ensuite où ça en est.
· **⚠ CENTRER LA RANGÉE NE SUFFIT PAS, IL FAUT CENTRER LA CARTE** (le second signalement) :
  `.ov-head` porte `padding:18px 18px 0` — juste quand le corps suit en dessous, faux quand
  l'en-tête EST la carte. Mesuré : 31 px au-dessus du texte contre 13 en dessous, soit 9 px sous
  l'axe. Rembourrage symétrique en replié, retrait à gauche inchangé.
· **RÈGLE GÉNÉRALE** : un alignement se mesure sur les CENTRES, jamais sur les hauts — deux objets
  de tailles différentes n'ont pas le même haut. Et une mise en page pensée pour un état ne se
  transporte pas telle quelle dans l'autre.

**A70. UNE SECTION RESPIRE AUTANT DES DEUX CÔTÉS DE SON FILET (v5.6, signalé à l'usage : « le
journal replié s'affiche avec plus d'espace en bas qu'en haut — et même déplié vide »).** Le panneau
du journal posait toute sa respiration d'un seul côté (12 px sous son filet, rien après son contenu,
`padding:12px 0 0`) : replié, il n'a qu'un TITRE, et ce qu'on lisait alors était 12 px au-dessus
contre les 16 px de fin de volet en dessous. Rembourrage symétrique — dans le volet ET dans le rail
(`.rail-fold`, qui portait la même faute) —, et la fin du volet passe de 16 à 12 px pour cesser
d'être comptée comme la respiration de la dernière section.
⚠ **UN PANNEAU QUI PEUT ÊTRE VIDE SE JUGE VIDE** : c'est l'état où l'asymétrie se voit le plus,
puisqu'il n'y a aucun contenu pour la masquer — le témoin mesure donc le panneau REPLIÉ.

**A71. LE LOGO SE CALIBRE SUR LE FÛT DU MOT, ET IL S'AMINCIT VERS L'INTÉRIEUR (v5.6, signalé à
l'usage : « le logo contraste avec l'épaisseur du texte “aides cognitives” »).** Mesuré au canevas
avec la police réellement embarquée : le fût de la Source Serif 4 à 17,5 px / 600 vaut **2,20 px**
(« A » perpendiculaire au jambage, « d » 2,20 ; « I » 2,35), quand le trait du glyphe en rendait
**2,70** — soit 123 % du fût. Un monolinéaire paraissant plus lourd qu'une romane à épaisseur
égale, la cible est 85-90 % : trait 56 → **40**, qui rend 1,93 px (88 %).
· **AUCUNE PROPRIÉTÉ CSS NE PEUT LE FAIRE** : `.brand-logo` pose `logo-glyph.svg` en MASQUE, dont
  seul le canal alpha compte — l'épaisseur vit dans le fichier. Et le fichier est GÉNÉRÉ
  (`scripts/build-icons.mjs`, une seule géométrie pour les onze sorties) : l'éditer à la main,
  c'est écrire une divergence que la prochaine génération effacera.
· **ON AMINCIT VERS L'INTÉRIEUR, RAYON EXTÉRIEUR GELÉ** (`R = R_OUT − SW/2`, R_OUT=228) : l'emprise
  d'encre GAUCHE est ce sur quoi la marge de page s'aligne, via les marges négatives calibrées de
  `.brand-logo`. Mesurée après : **x0 = 181, inchangée**. La borne droite, portée par la pointe de
  la coche, recule de 0,35 px à 34 — sous le demi-pixel, les marges restent au cran, et les
  chiffres du commentaire sont mis à jour (il documente des mesures, il ne doit pas mentir).
· **⚠ ET L'ONGLET N'A PAS SURVÉCU À L'AMINCISSEMENT — « le bouton sur le dessus dépasse »** : son
  pied était une corde HORIZONTALE calée sur le bord INTÉRIEUR d'un trait de 56. Une corde n'est
  contenue dans la bande que si `dy ≥ R_in` au milieu ET `hypot(144,dy) ≤ R_OUT` au bord : à 56 la
  fenêtre est [172 ; 176,8] et le dessin y tenait au pixel près ; à 40 elle est VIDE (188 > 176,8).
  Le pied pointait donc dans le vide de l'anneau. Il suit désormais le cercle **MÉDIAN**, donc il
  est enfoui de SW/2 de chaque côté quel que soit le trait, et ses extrémités sont CALCULÉES.
· **MÉDIAN ET NON EXTÉRIEUR, et c'est une leçon de rendu** : posés sur le même arc, l'onglet et la
  bande partagent une frontière EXACTE — chacun n'y couvre que la moitié du pixel et
  l'anticrénelage rend un LISERÉ CLAIR le long de la jonction. **Deux encres qui se touchent
  doivent se RECOUVRIR.**
· **UNE SEULE ÉPAISSEUR POUR LES ONZE SORTIES — SAUF SOUS UN PIXEL DE TRAIT, OÙ L'ON HINTE.** Deux
  épaisseurs CHOISIES feraient diverger le glyphe entre l'en-tête, l'onglet et l'écran d'accueil ;
  une compensation de RENDU n'est pas de ce genre. Sur la tuile, un pixel vaut 51,2 unités : à 40
  l'anneau du raster de 16 px ne rend que **0,78 px**, c'est-à-dire aucune ligne pleine — il se
  délave en gris et la coche disparaît. Ce raster garde donc le trait de 56 (1,09 px). C'est le
  hinting d'une fonte : sous ~1 px on ne choisit plus une épaisseur, on subit une grille, et le
  dessin doit s'y poser. La borne est étroite et elle le reste — 32 px rend déjà 1,56 px à 40, net
  et plus juste ; toutes les autres sorties partagent SW ; et personne ne compare un onglet de
  16 px à l'en-tête. **La variante n'est pas un second dessin** : la géométrie entière (rayon
  médian, coupure, pied de l'onglet) DÉCOULE de `sw`, donc les deux rasters sortent de la même
  fonction — un dessin recopié finirait par diverger.
· **CE QUI A ÉTÉ MESURÉ PUIS ÉCARTÉ** : « aligner le sommet de l'anneau sur la hauteur de capitale
  plutôt que sur la hauteur d'x ». La prémisse est fausse — mesuré à 390 px, l'anneau commence à
  **20,3** et la capitale à **21,2** : ils sont déjà alignés à 0,9 px près. Ce qui reste est un
  centre d'anneau 3 px sous le centre de la bande capitale, et c'est JUSTE : le mot porte un
  jambage descendant (« cognitives »), les deux boîtes sont centrées l'une sur l'autre, et une
  forme ronde doit déborder pour paraître de la même taille qu'une capitale à sommet plat.
· **⚠ CHANGER CES OCTETS NE CHANGE PAS CE QUI EST INSTALLÉ** : le nom de fichier ne bouge pas et le
  cache du service worker est versionné par `APP_VERSION` — un appareil déjà installé garde
  l'ANCIEN glyphe jusqu'au prochain `./release.sh X.Y.Z` (même piège que pdf.js, règle 1 : on
  n'édite JAMAIS `CACHE` à la main).

**A72. UN COMMENTAIRE QUI DÉCRIT UN ÉLÉMENT MORT LE FERA RÉINTRODUIRE — LES PURGES ONT UNE ÉPITAPHE
(v5.6, audit externe 9c).** Un commentaire affirmait AU PRÉSENT que « la POSITION reste portée par
la pilule `.ov-here` », purgée six lots plus tôt par A12 : zéro émission dans le fichier. Dans ce
dépôt les commentaires SONT la documentation de conception — celui-là aurait fini par faire remettre
la pilule, quelqu'un lisant la phrase, constatant l'absence, et « réparant » une régression.
· **LE CONTRÔLE EST DANS `check-classes`, PAS DANS UN DIX-HUITIÈME SCRIPT** : il y possède déjà les
  trois ensembles (émises · stylées · commentaires). Toute classe citée dans un commentaire de la
  feuille est VIVANTE, ou porte au moins une ÉPITAPHE — une mention de purge — quelque part.
· **⚠ CE QU'ON NE PEUT PAS MESURER, ET POURQUOI LA RÈGLE EST CELLE-LÀ** : la moitié des citations de
  classes mortes sont des RÉCITS (« cf. `.mode-seg` v4.25.1 » comme précédent de cascade), et elles
  sont légitimes. Distinguer un récit d'une affirmation au présent demanderait de lire le TEMPS des
  verbes — aucune regex ne le fait. On exige donc le vérifiable : purger sans épitaphe redevient
  bruyant, citer l'histoire reste libre. Deux classes en manquaient (`.mode-seg`, `.pl-cxh`).

**A73. LES TROIS GABARITS DE FENÊTRE SONT DES TOKENS, ET LE TÉMOIN BALAIE AU LIEU DE LISTER (v5.6,
audit externe 9b).** A25 avait FIXÉ les trois largeurs — 420 · 480 · 720 — mais en littéraux
répartis dans la feuille, et sept surfaces s'en étaient écartées. `--dlg-confirm` / `--dlg-std` /
`--dlg-atelier` : une surface DIT quel gabarit elle prend, elle ne recopie plus un nombre.
· **CE QUI EST RATTACHÉ** : `.boot-card` 440 → confirmation (une phrase, aucun champ),
  `.up-drag-card` (elle avait la bonne valeur, elle a maintenant le TOKEN), `#shareBody` 460 → 480
  (le commentaire disait déjà « la lecture redevient celle d'un dialogue » — le nombre ne le disait
  pas), et `.endsess-dlg` perd sa largeur propre : terminer une session EST une confirmation.
· **DEUX EXCEPTIONS NOMMÉES SUR PLACE, jamais rabattues** : `.alert-toast` (520) mesure une PHRASE
  et n'est pas une fenêtre — elle ne se ferme pas pour révéler ce qu'il y a derrière ; `.lightbox
  .cap` (600) est une mesure de LISIBILITÉ (~70 signes). La règle générale : *une largeur libre
  n'est légitime que si elle mesure autre chose qu'une fenêtre — un texte, un champ, une colonne —
  et le dit sur place.*
· **DEUX DES « SEPT » ÉTAIENT DES FAUX POSITIFS D'UN AUDIT STATIQUE** : `560px` apparaissait dans
  deux `@media`. Un palier n'est pas une largeur de modale, et rien dans le texte ne les sépare.
· **⚠ ET `.endsess-dlg` N'AVAIT AUCUN EFFET** : `.dlg-confirm .ai-card` (0,2,0) battait `.endsess-dlg`
  (0,1,0), donc ses 400 px étaient morts depuis toujours. C'est ce qui a fait que le témoin est
  resté VERT quand j'ai réintroduit le défaut pour l'éprouver — il a fallu un défaut qui MORD
  (`#endSessModal .ai-card`) pour le voir rougir. Une déclaration qu'on croit fautive peut n'être
  que du bruit ; on le vérifie avant d'en tirer une leçon.
· **LE TÉMOIN BALAIE (même leçon que 8f)** : il n'ouvrait que cinq fenêtres NOMMÉES, et c'est par là
  que les sept étaient entrées. Il mesure désormais le `max-width` calculé de TOUTES les `.ai-card`
  du document — `getComputedStyle` résout `var()` même sur un élément `display:none`, donc sans en
  ouvrir aucune.

**A74. LA GOUTTIÈRE DU RAIL A→Z APPARTIENT À LA PAGE, PAS AU RAIL (v5.6, signalé à l'usage :
« l'absence de rail redistribue la largeur des cartes… c'est moche quand ça repasse à plusieurs
cartes »).** La v5.0.3 avait déjà tranché cela pour la RECHERCHE, et la voie LARGE le tient sans
condition depuis toujours — mais la règle étroite était accrochée à `.azr-on`, c'est-à-dire à
l'EXISTENCE du rail. Bibliothèque vide, une seule lettre, ou rail retiré faute de hauteur : la
colonne récupérait ses 16 px, tout s'élargissait, puis rétrécissait au retour. `.azr-on` est PURGÉE
avec la condition qu'elle servait (règle 14, plus aucun lecteur).
· **ET LA RANGÉE DE CONTRÔLES PORTE SA PROPRE RESPIRATION** (second volet du même signalement : « le
  bouton filtre peut se coller au bloc du dessous »). `.grp-row` n'avait de marge qu'EN HAUT : avec
  des cartes l'écart venait du titre de section — donc d'un VOISIN —, et le bloc « Aucune aide »
  n'en apporte aucun (0 px mesuré). 12 px en bas, et cela ne coûte rien là où l'écart existait :
  **les marges de frères adjacents FUSIONNENT**, max(12,16)=16, donc le répertoire ne bouge pas d'un
  pixel. C'est un plancher, pas une addition.
· **⚠ UN TÉMOIN VOISIN A ROUGI SUR CE CORRECTIF JUSTE, ET IL AVAIT TORT** : il exigeait du
  déclencheur de filtres un bord droit à ≤ 20 px de la FENÊTRE — la géométrie du cas SANS rail.
  Avec la gouttière réservée il vaut 34 px avec rail comme sans, ce qui EST la constance
  recherchée. Il mesure désormais l'écart à la COLONNE (affleurement, ±2), qui ne dépend d'aucun
  rail. Un témoin calé sur un repère extérieur mesure autre chose que sa propriété.

**A75. LA QUESTION D'UNE DÉCISION EST SOUS SON TITRE DANS LA HIÉRARCHIE, DONC SOUS LUI DANS
L'ÉCHELLE (v5.6, signalé à l'usage : « titre du bloc et question s'affichent en même grandeur ->
perturbant »).** Les deux étaient à 21 px / 700. La question descend à `--t-step`, LE MÊME cran que
ses options `.opt` : une question et ses réponses sont un seul objet de lecture, et c'est le CADRE
des options qui les distingue, pas leur corps.
· **AUCUN GARDE-FOU STATIQUE NE POUVAIT LE VOIR** : 21 est sur l'échelle fermée, donc `check-type`
  était vert — ce n'était pas la VALEUR qui était fausse, c'était le RAPPORT. Une hiérarchie ne se
  mesure qu'au rendu et par comparaison ; le témoin compare les trois corps entre eux.
· **⚠ UNE RÈGLE DE PALIER QUI RÉPÈTE LA VALEUR DE BASE EST UNE MINE** : un `@media (max-width:560px)`
  reposait `.question` à 21 px. No-op tant que la base valait 21 — et il aurait ANNULÉ la descente
  exactement sur le format où le défaut a été signalé.
· **ET LE TÉMOIN DE LA DÉCISION NE RENCONTRAIT PAS SON CAS** : « un bloc de décision n'a pas de
  “Vérifier” » cherchait `.ov-block.dec [data-ovverify]` alors qu'aucune décision n'était encore
  POSTÉE au journal — absent parce qu'absent, vert sans rien mesurer. La section avance désormais
  jusqu'à une décision et le vérifie d'abord. ⚠ Corollaire payé sur place : la trace do-verify se
  relève AVANT d'avancer, le journal condensant un passage terminé en ligne-bilan.

**A76. CE QUE L'AUDIT STATIQUE NE POUVAIT PAS VOIR, ET QUI ÉTAIT DÉJÀ FAIT (v5.6, réponses aux
points 9d et 9e).** Un audit qui lit `index.html` ne voit ni les harnais ni les gardes JS ; trois de
ses constats se règlent en ÉCRIVANT ce qui était vrai, au lieu de changer le code.
· **`.pdf-fnav` — LE SEUL VRAI DÉSACCORD, ET IL EST RETENU** : la pilule d'occurrences n'apparaît
  que si la visionneuse a été ouverte depuis un résultat, mais elle reste alors posée sur le
  document, page après page — et un document consulté pendant un soin peut porter EN BAS DE PAGE
  une posologie. Le geste qui l'a fait naître était « trouve ce mot », pas « couvre le bas de mes
  pages ». Sa bande est désormais RÉSERVÉE dans le défileur (`--pdfhl-r`, hauteur MESURÉE, 0 quand
  la pilule n'est pas là) : le document se TERMINE au-dessus d'elle, il n'y a plus rien à occulter.
  C'est la doctrine du dock — une bande réservée, jamais une superposition au contenu clinique.
· **`.alert-toast` NE SURGIT JAMAIS SUR L'ÉCRAN DE SOIN** (vérifié) : `onTimerFired` ne l'appelle que
  dans la branche `!activeVisible` — session hors de vue, autre fiche, ou app en arrière-plan. Sous
  les yeux, l'alarme reste sur place. Le noyau §2 vise ce qui SURGIT pendant qu'on regarde ; ici
  l'alerte est ROUTÉE vers quelqu'un qui regarde ailleurs, ce qui est l'exigence inverse. C'était
  écrit côté JS, pas au site CSS où l'audit a regardé : ça l'est maintenant.
· **`.sys-banner` EST EXEMPTÉ D'A11, EXPLICITEMENT** : A11 vise la surface de CRISE, où une masse
  colorée de plus vole l'œil à une étape vitale. Ce bandeau ne vit que sur l'ACCUEIL, sa teinte est
  INFORMATION, et rien d'autre ne peut s'y afficher en même temps (la notice d'auteur attend son
  acquittement). Étendre A11 à l'accueil interdirait la carte de session vive et les épinglées.
· **`.mi-sc` / `.mi-ins` (40 px) SONT CONSIGNÉS comme `.st-seg` l'a été** : galerie de l'ÉDITEUR,
  hors contrat des 44 px, très au-dessus des 24×24 de WCAG 2.2 § 2.5.8.
· **8f EST LIVRÉ** (A33) : dès qu'une session est à l'écran, `audit-a11y` scanne la page ENTIÈRE et
  compte le halo `::after` dans la zone tapable. L'audit le croyait ouvert parce qu'il ne lit pas
  `scripts/`.
· **LES DEUX CIBLES À 24 px NE RÉTRÉCISSENT PAS AU ZOOM** (`.azrail button`, `.rel-x`) : mesurées
  24,00 × 24,00 à 100 % comme à 200 % — ce sont des px CSS fixes, le zoom les agrandit visuellement
  au lieu de les rogner. La crainte de l'arrondi vise une taille DÉRIVÉE ; il n'y en a pas ici.

**A77. L'ÉCRAN D'ENTRÉE NE PORTE QUE CE QUI SERT À DÉCIDER D'ENTRER (v5.6, signalé à l'usage).**
Trois retraits et un déplacement, tous sur l'écran d'avant le soin — jamais sur le déroulé.
· **« Surveillances & pièges » N'Y EST PLUS** : c'est par définition ce qui vient APRÈS les gestes.
  Sur la page où l'on décide d'entrer, il n'est ni actionnable ni décisif, et il repousse d'autant
  le geste d'entrée. Il revient au PREMIER geste — rien n'est perdu, c'est différé au moment où
  cela sert —, et en voie large il n'a même pas disparu : la colonne d'orientation porte
  « Surveiller ensuite » en permanence. AC 120-71B veut les surveillances dans le FLUX ; cette
  règle vise le déroulé du soin, pas la page de garde.
· **NI LA RANGÉE « CONSULTER »** : elle appartient au soin. Elle reste à un tap par le renvoi
  « le tableau ne colle pas ? » de la condition d'entrée et par le menu ⋯ — aucun accès perdu.
· **« TABLEAU » ET « SCHÉMA » PASSENT AU-DESSUS DE « PRISE EN CHARGE »**, en boutons de contour de
  44 px au lieu de liens de texte de 12 px. Ils ouvrent la fiche ENTIÈRE : ce n'est pas un détail
  de cet étage, cela se lit avant lui. Contour et non rempli — le seul bouton rempli de l'écran
  reste le geste d'entrée (règle du bouton unique).

**A78. CE SONT DES EXCURSIONS, ET UNE EXCURSION SAIT REVENIR (v5.6, signalé à l'usage : « cliquer
sur tableau mène au tableau SFAR mais impossible de revenir, et on perd les sidebars ; cliquer sur
schéma ne fonctionne pas »).** Deux défauts, une cause commune : ces deux portes n'avaient pas été
traitées comme des excursions.
· **« Tableau » écrivait `state.readMode='static'` et re-rendait.** La page d'entrée était donc
  REMPLACÉE — or le retour d'excursion vit dans le DOCK (« ↩ Un bloc », lot A), et le dock n'existe
  pas avant le premier geste (A18) : on était enfermé. Et le format statique n'ayant pas de colonne
  de plan, le cockpit perdait ses DEUX colonnes au passage. Les deux portes ouvrent désormais une
  FEUILLE plein écran, qui se referme par son ✕, Échap, le voile et le retour système ; la page
  d'entrée reste dessous, intacte, colonnes comprises.
· **`state.readMode` N'EST PLUS TOUCHÉ** : on MONTRE la page, on ne bascule pas le format de
  lecture — « regarder n'est pas régler » (lot A). Le commentaire qui interdisait « Tableau » dans
  cette feuille (« ce serait une seconde porte vers le mode statique, dont #readTopSeg est le seul
  maître ») est caduc des deux côtés : `#readTopSeg` a été purgé au lot A, et il ne s'agit pas
  d'une porte vers un ÉTAT.
· **⚠ « Schéma » NE FAISAIT RIEN, EN SILENCE** : `openFlowFull(f)` prend la fiche en paramètre et
  l'appel l'omettait — `buildFlowSVG(undefined)` ne rend rien et ne lève pas. Un argument oublié
  ne se voit ni au `check`, ni aux tests : seul un témoin qui CLIQUE le trouve.
· **UNE COQUE, DEUX VUES** : la feuille « Se repérer » accepte `openPlanSheet('page')` — même ✕,
  même Échap, même retour système, rien de neuf à tenir. Et `svPaintArrows(racine)` est
  paramétrée : un second peintre recopié divergerait au premier réglage de flèche.

**A79. AVANT LE SOIN, LE PARCOURS SE RESSERRE — LES MARGES CÈDENT, JAMAIS LE CONTENU (v5.6, signalé
à l'usage : « le parcours inerte est trop long »).** Rangée 44 → 38 px, rembourrage 6/12 → 4/10,
écart de grille 6 → 4, pastille 26 → 24, étiquette de branche 38 → 28. **Mesuré : 454 → 388 px,
soit 15 %** — aucun mot retiré, aucun corps de texte changé.
· **POURQUOI SEULEMENT AVANT** : 44 px est le plancher de la CRISE et il ne se négocie pas une fois
  le soin démarré. Ici il n'y a pas de crise — `audit-a11y` mesure d'ailleurs cet écran sur la
  liste HORS crise, plancher 24 — et le geste qui fait basculer les deux géométries est le bouton
  de démarrage, donc COMMANDÉ : A9 interdit qu'une hauteur change sans qu'on l'ait demandé, pas
  qu'un écran se réorganise quand on entre dedans (c'est déjà ce que fait T5). 38 px reste au-dessus
  du plancher hors crise (32).
· **CE QUI N'A PAS ÉTÉ TOUCHÉ, ET POURQUOI C'EST À DIRE** : les rangées de surveillance à 48 px le
  sont parce que leur texte passe sur DEUX lignes — c'est du contenu, pas du rembourrage. Le
  raccourcir serait la perte d'information que la demande exclut.

**A80. CHANGER DE CRAN N'EST PAS NAVIGUER (v5.6, demande de l'auteur).** La bascule Tout / Aides /
Protocoles faisait glisser la liste (`.sec-anim-l/r`, PURGÉES avec leur mécanique — règle 14).
C'est un changement de FILTRE : la liste reste la même liste, seule sa clé change, et l'animer lui
donnait l'allure d'un changement d'écran. Le glissement de la PASTILLE du sélecteur suffit à accuser
le geste, et il est, lui, de la manipulation directe. Les keyframes `secInL/R` restent : elles
servent la pile de retour et la bascule de format en lecture, qui sont deux vraies navigations.

**A81. UN MINUTEUR ARRÊTÉ DIT DEPUIS QUAND (v5.6, planche 11j — le point le plus critique de la
série « intelligence »).** Au rechargement les minuteurs sont restaurés EN PAUSE et le temps passé
application fermée n'est PAS rattrapé : c'est juste, le rattraper fabriquerait un temps que personne
n'a mesuré. Mais rien ne disait **combien**. Un minuteur figé à 4:22 se lit d'un coup d'œil comme un
minuteur qui tourne à 4:22, et la décision qui suit — « ça fait quatre minutes, je redonne » — est
prise sur un chiffre qui a cessé d'avancer. C'est le seul endroit du produit où un chiffre commande
un geste médicamenteux, et c'est pour cela que cette ligne passe avant tout le reste.
· **UNE PHRASE, DEUX CAUSES** : « △ arrêté depuis 4:10 — application fermée, le temps n'a pas été
  rattrapé » s'il TOURNAIT à l'enregistrement (l'arrêt date de `savedAt`) ; « △ arrêté depuis 4:10 »
  s'il était déjà en pause. Une pause dont on a perdu le compte est le même piège, et distinguer
  les deux par deux formulations ferait deux phrases à lire.
· **AMBRE TEXTUEL, JAMAIS UN APLAT** (A11) : c'est une LECTURE, pas une alarme. Sur la matière
  SYSTÈME (le volet), le registre prend sa valeur propre `--warn-sys`.
· **⚠ AUCUN SEUIL, ET C'EST A9 QUI L'IMPOSE** : « n'afficher qu'au-delà de 30 s » ferait apparaître
  une ligne — donc grandir la carte — SANS geste. Elle paraît au tap de pause (geste commandé, la
  carte a le droit d'y gagner une ligne) ou est déjà là au chargement, et seul son NOMBRE avance
  ensuite. Un minuteur ÉCHU n'en reçoit aucune : il le devient tout seul, et l'alarme dit déjà ce
  qu'il faut savoir.
· **ELLE NAÎT AU TICK, PAS AU RENDU** — précédent exact d'A34 : la mise en pause passe par le
  chemin chirurgical (`syncTimerBtns`), pas par un re-rendu ; posée seulement par `timerCard`, la
  ligne n'apparaîtrait qu'au prochain rendu complet, c'est-à-dire peut-être jamais.
· **DEUX CHAMPS FACULTATIFS DANS L'INSTANTANÉ** (`running`, `stoppedAt`) : sans eux on ne peut pas
  distinguer « fermée pendant qu'il tournait » d'« en pause depuis dix minutes ». Un instantané
  ANTÉRIEUR retombe sur `savedAt` — au pire la durée annoncée est trop COURTE, jamais inventée
  (`tmStopFrom`, pure, 6 témoins).

**A68. MICRO-ANIMATION NON BLOQUANTE — CINQ CONDITIONS, ET UNE ANIMATION QUI EN MANQUE UNE NE SE
DISCUTE PAS (v5.6, planche 10d).** La règle était énoncée trois fois, à trois endroits, en trois
formulations — le déroulé du volet (A51), l'oscillation du bloc saisi (v4.75.0), l'élévation de
l'en-tête (A27). Écrite une fois, elle devient opposable.
1. **ELLE RÉPOND À UN GESTE.** Le mouvement non commandé est réservé à l'alarme (ECAM) : ce qui
   bouge tout seul dit « danger », ou ne dit rien.
2. **L'ÉTAT EST APPLIQUÉ D'ABORD, L'ANIMATION LE DÉCORE.** Aucune mutation n'attend un
   `animationend` — il ne sert qu'à NETTOYER (retirer une classe, un style, un `hidden`).
3. **`transform` ET `opacity` SEULEMENT** (check-anim) : aucune passe de mise en page par image.
   Une hauteur qui doit « se dérouler » se fait en `scaleY` + contre-scale du contenu (A51).
4. **INTERRUPTIBLE.** Un second geste pendant l'animation est honoré IMMÉDIATEMENT : l'animation
   est REMPLACÉE, jamais mise en file. Rien n'est `pointer-events:none` sauf un annonciateur qui
   ne reçoit rien (halo, dégradé, flash, coque du dock, fenêtre de dépôt, surlignage PDF).
5. **BORNÉE** : ≤ 200 ms, une seule oscillation amortie, JAMAIS de boucle — la boucle appartient à
   `alarmPulse` et au point de session. Et inerte sous `prefers-reduced-motion`, sans exception.
· **LA CONDITION 4 EST LA SEULE QUI N'ÉTAIT ÉCRITE NULLE PART**, et c'est celle que la demande
  formule (« pouvoir continuer à utiliser l'app pendant l'animation »). Elle était respectée PAR
  CONSTRUCTION, pas par règle : rien n'empêchait le prochain lot d'accrocher une mutation d'état à
  une fin d'animation. `check-anim` la mesure désormais — le corps d'un `animationend` ne peut
  contenir ni rendu, ni écriture sur `state`/`Runtime`, ni persistance —, plus un CLIQUET sur le
  nombre de `pointer-events:none` (18 aujourd'hui, tous des annonciateurs) : une nouvelle
  occurrence est une décision, et elle doit se voir dans un diff.
· **⚠ LA PORTÉE EST DITE** : la sonde lit le corps littéral du gestionnaire. Un `animationend` qui
  appellerait une fonction NOMMÉE écrivant l'état passerait au travers — elle attrape l'écriture
  directe, pas l'indirection. Un contrôle qui tait sa limite laisse croire à une couverture totale.
· **TROIS ANIMATIONS REFUSÉES, ET LE REFUS FAIT JURISPRUDENCE** : le chrono qui fond à chaque
  seconde (mouvement non commandé, permanent, sur la zone qui ne quitte jamais l'écran — la
  définition du bruit) ; le squelette de chargement animé du répertoire (il fabrique une attente là
  où il n'y en avait pas) ; le glissement d'écran sur un changement de filtre, déjà purgé en v5.6
  (A80) — la liste reste la même liste, seule sa clé change.

**A82. « PRÊT » SE DIT SUR LA FICHE, PAS SUR L'ACCUEIL (v5.6, planche 11a).** La jauge
`#attOffline` annonce sur l'ACCUEIL que des documents manquent — alors que la question se pose sur
la FICHE qu'on est en train d'ouvrir. C'est le test du LIEU pris en défaut : une information juste,
au mauvais endroit, qu'on découvre en perdant le réseau. Une ligne de corps sous la rangée des
excursions : « ✓ 3 documents · tous disponibles hors ligne », ou son ambre TEXTUEL avec le NOM de
ce qui manque et le geste (`dlMissingAtts` existe déjà).
· **ELLE NE CONDITIONNE RIEN, et c'est la propriété que le témoin mesure** : « Confirmé — démarrer »
  reste actif avec des pièces manquantes. Un soin ne s'arrête pas parce qu'un PDF n'est pas là — le
  manque est une INFORMATION, jamais une condition. Pas de bandeau, pas de fenêtre, pas de pastille.
· **LE NOM QUAND IL Y EN A UN SEUL** : « un document » n'aide pas à décider s'il faut attendre le
  réseau, « Protocole SFAR 2024 » oui. Au-delà d'un, on compte.
· **ET L'ABSENCE DE BOUTON S'EXPLIQUE** : sans compte ni chemin de stockage il n'y a rien à
  télécharger — on dit pourquoi, dans les mots exacts de la jauge d'accueil. Une absence non
  expliquée se lit comme une panne.
· **⚠ LA MOITIÉ « RÉVISION » DE LA PLANCHE N'EST PAS REPRISE, ET C'EST UNE CORRECTION DE PRÉMISSE** :
  elle la croyait absente de la page d'entrée, or la rangée de méta y porte déjà « Validation :
  01/2025 » — elle n'est masquée qu'EN SESSION (v4.31.0). L'écrire une seconde fois serait la
  duplication que § 5.5 proscrit. Une proposition juste peut reposer sur un constat faux ; on
  vérifie le constat avant de livrer la proposition.

**A83. LA CARTE DE SESSION DIT OÙ L'ON VA RETOMBER, AVANT LE GESTE (v5.6, planche 11c).**
« Bloc 7 · Reprise du massage — dernier repère 15h47 », sous le titre. `resumeSession` restaure
déjà le runtime entier ; ce qui manquait est le MOT qui permet de savoir, avant de toucher, où l'on
atterrit — sans quoi on reprend, puis on relit le journal pour se retrouver. Encore le test du
lieu : l'information qui décide du geste n'était disponible qu'APRÈS lui.
· **AUCUNE SURFACE NOUVELLE** : deux données déjà en mémoire, sur une carte qui existe. C'est la
  moins chère des propositions de la série.
· **ELLE NE DIT QUE CE QU'ELLE SAIT** (`liveWhereText`, pure, 6 témoins) : pas de bloc courant → pas
  de fragment de bloc ; aucun repère → pas d'heure ; rien des deux → chaîne vide et la ligne
  n'existe pas. Un « — » à la place d'une donnée absente serait du bruit à décoder.

**A84. L'ÉCRAN NE S'ÉTEINT PAS PENDANT UNE SESSION, ET IL LE DIT UNE FOIS (v5.6, planche 11k).**
Aucune occurrence de `wakeLock` dans le fichier : pendant une réanimation de vingt minutes l'écran
s'éteignait seul, et le geste suivant commençait par réveiller un téléphone — l'outil se retire
pendant qu'on s'en sert. Une ligne dans l'en-tête du volet, au registre et à la place de « Son
activé / Son coupé », qui règle déjà exactement ce genre de question.
· **QUATRE RÈGLES, ET CE SONT ELLES QUI ÉCRIVENT LE CODE** : demandé seulement en session vive,
  relâché à la fin et au masquage, redemandé au retour ; aucune fenêtre, aucune permission ;
  une ligne, dans le volet, sur geste ; un interrupteur, parce que c'est un réglage (batterie
  faible, transport long, tablette partagée) et que l'état se VOIT au lieu de se deviner.
· **`wakeApply` EST IDEMPOTENT, ET C'EST LE POINT DUR** : « un verrou redemandé en boucle est un
  bogue de consommation ». Il sort si la demande correspond déjà au verrou tenu, donc on peut
  l'appeler à chaque rendu de lecture sans rien redemander. **MESURÉ : 1 demande, et 5 rendus
  successifs n'en ajoutent aucune** — c'est le nombre de demandes que le témoin compte, pas la
  présence d'un interrupteur.
· **⚠ ON TESTE LA CAPACITÉ, PAS LA CLÉ** : `'wakeLock' in navigator` est VRAI même quand la
  propriété vaut `undefined`. Sans cela la ligne s'affichait là où rien ne peut se produire —
  l'inverse de la dégradation silencieuse. Un refus du système ne dit rien non plus : il laisse
  l'interrupteur sur « veille normale ».
· Le choix est PERSISTÉ par utilisateur, comme le thème et le son : le rallumer à chaque session
  serait un réglage qu'on ne peut pas régler.

**A85. LE MINUTEUR AD HOC DIT CE QU'IL CRÉE, ET SA DURÉE SE CHOISIT (v5.6, planche 11h).** Le geste
existait et il était juste — un tap, un objet déjà réglé, démarré, supprimable : *le risque n'est
pas la création, c'est la saisie*. Deux limites mesurées : la durée valait **300 s en dur**, et le
nom DÉGÉNÉRAIT (`'PA'+(n+1)` → « PA, PA 2, PA 3 »), c'est-à-dire trois minuteurs qui ne disaient
plus ce qu'ils surveillaient.
· Le bouton porte le **nom pressenti du dernier repère** (`tkLabels`, vocabulaire déjà normalisé) et
  l'annonce AVANT le tap ; son tap déplie **quatre durées**. Deux taps, **zéro clavier, zéro champ**,
  et UN seul ＋ qui déplie — jamais quatre ＋ dans une rangée que la largeur du volet ne supporte pas.
· **⚠ UN LIBELLÉ DE REPLI N'EST PAS UN NOM** (trouvé à la mesure, puis signalé à l'usage : « ne le
  nomme pas ＋ Minuteur Compteur »). Le dernier repère se résout parfois sur « Action 3 », ou sur le
  nom PAR DÉFAUT d'un objet sans nom (« Compteur », « Minuteur », « Chronomètre », A58) — repris
  tel quel, cela donnait « ＋ Minuteur Compteur » : la dégénérescence de « PA 2 » sous un autre
  visage. Sans nom réel, le bouton reprend son libellé d'avant : *la proposition n'invente pas de
  mot quand elle n'en a pas.*
· **ET LE LIBELLÉ NE PROMET PLUS « 5:00 »** : la durée n'est plus décidée d'avance. Un bouton qui
  annonce une valeur qu'il ne pose pas est de la mode confusion (A38).
· **RÈGLE 15 — VÉRIFIÉE, PAS SUPPOSÉE** : la planche demandait de trancher avant d'écrire si un nom
  tiré d'un repère voyage. Mesuré : `shareSnap` n'envoie d'un minuteur que
  `{running, elapsedMs, cycles, anchor}` sous sa CLÉ, et un minuteur ad hoc n'existe pas chez
  l'invité — il vit dans la session, qui ne voyage pas. La contrainte est donc tenue par
  CONSTRUCTION, pas par une garde à maintenir.

**A86. LE COMPTEUR AD HOC — L'ASYMÉTRIE MESURÉE, ET LE PLUS SÛR DES DEUX (v5.6, planche 11i).**
Les compteurs ne venaient que de `f.counters` : rien n'en créait en session, alors que les MINUTEURS
l'avaient depuis toujours. Or un compteur **ne sonne pas, n'échoit pas, n'entre jamais dans le
registre d'alarme** — c'est l'objet le moins risqué du volet, et le seul qu'on ne pouvait pas poser
quand il manquait (chocs, doses non prévues par l'auteur, relais de masseur : on comptait de tête).
· **CRÉÉ À 1, JAMAIS À 0** : on appuie parce que l'événement vient d'avoir lieu. Le premier incrément
  est donc déjà compté, et il pose son repère horodaté comme n'importe quel « ＋ » — même sans nom,
  le compte rendu garde l'heure de chaque unité.
· **NOMMER EST FACULTATIF ET DIFFÉRÉ** (doctrine du repère horodaté), et « — nommer » n'existe QUE
  sur un compteur ad hoc : celui de l'auteur porte un nom décidé au calme.
· **⚠ AUCUN `timerId`, ET ON NE LUI EN INVENTE PAS** : ce lien relance une alarme, c'est une
  décision d'AUTEUR.
· Ils vivent dans la session (`extraCounters`), exactement comme `extraTimers` — donc hors de
  l'export de la fiche, et hors du réseau.

**A87. UN VOLET QUI VIT DANS `main` SE FAIT REMONTER PAR CHAQUE RENDU (v5.6, signalé à l'usage :
« ajouter un minuteur/compteur réinitialise le contenu : on perd le fil et ça fait un fondu blanc
moche »).** Trois conséquences d'une même cause, et la première est une violation d'A68.
· **LE DÉROULÉ REJOUAIT À CHAQUE GESTE** : l'animation était portée par le MONTAGE de `.rt-dock`, or
  tout rendu complet le remonte. A68/1 dit que le mouvement répond au GESTE qui l'a demandé — la
  classe `.rt-roll` est donc posée UNE FOIS, par le tap du quai, et consommée par le rendu qui suit.
  Mesuré : `dockRoll` à l'ouverture, `none` après un ajout.
· **LE VOLET A SON DÉFILEMENT PROPRE**, et il repartait en haut. Même règle que `.read-side` depuis
  la v4.23.5 : on capture avant, on restaure après — la moitié étroite n'avait jamais été écrite.
· **LE DÉFILEMENT DE PAGE, LUI, NE BOUGEAIT PAS** (mesuré : 0 px). Ce qui « fait perdre le fil » est
  le volet qui se replie et se redéroule sous les doigts, pas la page — on corrige ce qu'on mesure.

**A89. UN TÉMOIN NE DOIT JAMAIS POUVOIR PENDRE — ET ON LIT LE CODE DE SORTIE, PAS LA DERNIÈRE LIGNE
(v5.6, deux heures perdues).** Changer la porte du minuteur (un tap déplie, le second crée) a cassé
un témoin du QUAI qui comptait sur « un tap = un minuteur » : sa boucle `while(ids.length<3)` dans
un `page.evaluate` ne se terminait plus, et la tranche `doctrine 1/4` restait vivante indéfiniment —
emportant la passe entière, sans un mot.
· **UNE BOUCLE DE SONDE EST BORNÉE, TOUJOURS.** `if(!b)break` ne suffit pas : le bouton EXISTE, il
  ne fait simplement plus ce qu'on croit. Une borne d'itérations transforme un blocage silencieux
  en rouge lisible.
· **⚠ ET J'AI ÉTÉ TROMPÉ PAR LE PIÈGE QUE CE FICHIER DOCUMENTE DÉJÀ** (v4.70.1) : `npm run audit |
  tail -6` rend le statut de `tail`, pas celui de l'audit. La tâche de fond a donc rapporté
  « exit 0 » sur une passe qui pendait, et j'ai cru la porte verte. **On lit le code de sortie de
  la CHAÎNE**, ou l'on redirige et l'on cherche la ligne de bilan.
· **ET LE TÉMOIN VOISIN NE RENCONTRAIT PLUS SON CAS** : il faisait « varier l'état » en cliquant la
  porte trois fois — depuis le dépliage, l'état ne variait plus du tout, et « le quai ne bouge pas
  quand l'état varie » se vérifiait sur un état constant. Il compte désormais les minuteurs avant
  et après, et échoue si rien n'a bougé.

**A88. LE PANNEAU NE SE TAIT PAS QUAND LA FICHE N'A RIEN À MONTRER (v5.6, signalé à l'usage :
« lorsque la session n'a pas de minuteur ou chronomètre pré-défini, l'option d'ajouter ne s'affiche
pas »).** En voie large, le rail sortait à vide dès que la fiche ne déclarait ni minuteur ni
compteur — emportant les deux PORTES avec lui, et rendant impossible de poser un objet ad hoc
précisément sur les fiches qui en ont le plus besoin : celles où l'auteur n'en a prévu aucun.
· **LA RÈGLE « UN PANNEAU VIDE EST DU BRUIT » VISE CE QUI AFFIRME**, pas ce qui INVITE. « 0 minuteur »
  est du bruit ; deux boutons qui ouvrent une capacité sont une porte. C'est exactement la
  distinction déjà tranchée pour le chapeau « Ne pas oublier », affiché vide (v4.76.0).
· Le panneau ne disparaît donc plus que **hors session** : sans soin en cours, il n'y a rien à créer.

**A90. LA RANGÉE DE REPÈRE QUI VIENT D'ÊTRE ÉCRITE SE DÉSIGNE (v5.6, planche 11g/1).** Le panneau du
journal est remplacé EN PLACE à chaque ajout : l'information est déjà à l'écran, mais rien ne disait
LAQUELLE des rangées est nouvelle — et sous stress on relit la liste entière pour s'en assurer.
L'animation ne fait que la désigner ; elle n'apporte aucune information de plus. C'est le cas le plus
net des quatre proposées, et le seul dont le gain ne se discute pas.
· **A68 EN ENTIER** : elle répond à un GESTE ; l'état est écrit AVANT (le repère est dans
  `Runtime.events` quand le panneau se rend) ; 140 ms, opacité + 5 px, `cbIn` qui existait déjà ;
  rien ne l'attend — le tap suivant écrit pendant qu'elle entre encore ; inerte sous
  `prefers-reduced-motion`.
· **⚠ LE DRAPEAU EST CONSOMMÉ PAR LE PREMIER RENDU** (`_tkFresh`, lu puis remis à null dans
  `timekeeperPanel`) : le panneau se repeint aussi au tick et à l'arrivée d'un évènement DISTANT, et
  une rangée qui re-clignoterait à chaque passage serait exactement le mouvement non commandé
  qu'A68/1 interdit. Le témoin mesure les DEUX moitiés — une seule rangée animée, et plus aucune
  après une repeinture.

**A91. LA SECONDE MICRO-ANIMATION EST REFUSÉE — SA PRÉMISSE NE TIENT PAS DANS CE BUILD (v5.6,
planche 11g/2, mesuré).** La proposition était : « depuis A12, la position est portée par la
BORDURE D'ACCENT du seul bloc ouvert, et elle apparaît sans transition, donc l'œil doit la
chercher » — 120 ms d'opacité sur la bordure seule.
· **MESURÉ** : `.ov-block.cur` ne porte AUCUNE bordure d'accent. Sa bordure vaut `--work-line`
  (`rgba(20,24,29,.08)`, la même que toute carte de travail) ; ce qui le désigne est son
  ÉLÉVATION (`--shadow-work`) et le fait d'être **le seul bloc ouvert** — mesuré : 1 carte ouverte.
· **ET L'ŒIL N'A PAS À LE CHERCHER** : la carte qui devient courante est POSTÉE au bout du journal,
  `ovAdvanceRender` y ancre le geste et défile jusqu'à elle si elle n'est pas déjà entière à
  l'écran ; et le changement visuel est massif (la précédente se condense, la nouvelle ouvre ses
  étapes). Une animation de plus n'ajouterait rien qu'on ne voie déjà.
· **CE QUI RESTERAIT POSSIBLE, ET POURQUOI ON NE LE FAIT PAS** : fondre l'ÉLÉVATION. Ce serait
  imperceptible à côté de l'ouverture de la carte, et cela ajouterait du mouvement à la surface de
  soin — là où l'ECAM le réserve à l'alarme. **Une proposition juste peut reposer sur un constat
  faux ; on vérifie le constat avant de livrer la proposition** (même leçon qu'A82 sur la révision
  déjà affichée).

**A92. UNE CLASSE POSÉE AU FOCUS ET RETIRÉE AU BLUR EST ORPHELINE SI LE CHAMP EST DÉTRUIT (v5.6,
signalé à l'usage : « renommer un nouveau compteur fait disparaître la barre flottante »).** A1
efface le dock au focus d'un champ (`kb-open`) — le clavier EST la surface de saisie. Le champ de
nommage vit dans le VOLET et son commit RE-REND : le champ disparaît **avant** que son `focusout`
ne parte, la classe reste posée, et le dock — donc « Noter l'heure », « ⚡ » et le geste d'entrée —
restait `display:none` jusqu'au prochain focus.
· **ON NE CORRIGE PAS EN EXEMPTANT LE CHAMP FAUTIF** : le prochain champ ajouté ailleurs rejouerait
  le défaut. La classe est **réévaluée à chaque rendu**, sur la seule question qui compte — y a-t-il
  un champ focalisé, MAINTENANT ? Même famille que la liste de placards d'A78 et que le compteur de
  rendu d'A49 : un état qui dépend d'un évènement de sortie doit avoir une seconde source de vérité.

**A93. LES OBJETS AD HOC SONT DES OBJETS DE LA SESSION, PAS DE LA FICHE (v5.6, signalé à l'usage :
« un nouveau compteur n'apparaît pas dans Noter l'heure »).** `tagAll` et `tagLabel` lisaient
`f.timers` / `f.counters` — or un objet créé EN SESSION vit dans le Runtime. Il était donc visible à
l'écran et introuvable au moment de l'horodater : **exactement le défaut qu'A58 avait corrigé pour
les objets SANS NOM, revenu par une autre porte** — et le minuteur ad hoc, lui, l'avait depuis
toujours.
· **LES DEUX FONCTIONS RESTENT PURES** : la session passe ses objets en PARAMÈTRE (`tagSrc`), elle
  n'est pas lue depuis leur corps. C'est ce qui permet au compte rendu d'une session ARCHIVÉE de
  résoudre les mêmes noms, en lisant `extraTimers`/`extraCounters` de l'instantané — un compte rendu
  se relit longtemps après, éventuellement pendant une autre session.
· **UN SEUL POINT DE LECTURE DU RUNTIME** (`rtExtra`) : six appelants, une expression — recopiée,
  elle aurait divergé.
· **LA SUPPRESSION SUIT SANS RIEN ÉCRIRE** : le vivier est CALCULÉ à chaque appel, donc un compteur
  supprimé en sort par construction. C'est la seconde moitié de la demande, et elle était acquise —
  on la mesure quand même, parce qu'« acquis par construction » se vérifie.

**A94. LE RÉPERTOIRE TOLÈRE LA FAUTE DE FRAPPE — ON CORRIGE LA REQUÊTE, JAMAIS LA LISTE (v5.6,
décision de l'auteur : « tolérance seule, sans table »).** Sous stress et avec des gants,
« anafilaxie » ne trouvait RIEN — et un répertoire qui répond « aucun résultat » sur une faute de
frappe fait renoncer à chercher là où le contenu est. QUATRE BORNES, et ce sont elles qui rendent
la chose admissible dans un logiciel d'urgence :
1. **ELLE NE SE DÉCLENCHE QUE SUR ZÉRO RÉSULTAT, DOCUMENTS COMPRIS.** Une liste littérale non vide
   n'est ni réordonnée ni complétée — le rapprochement flou est un DERNIER recours, jamais un
   classement (même garantie que `posoRank` et `tagRank`, prise par l'autre bout). Un mot trouvé
   dans un PDF joint EST un résultat : corriger par-dessus le masquerait.
2. **LES CANDIDATS VIENNENT DE VOTRE PROPRE BIBLIOTHÈQUE**, et de la liste VISIBLE sous les filtres
   du moment. Un lexique médical livré serait une seconde source de vérité à tenir, et du poids
   (règle 13) ; surtout, corriger vers un mot que le cran courant écarte rendrait zéro résultat.
3. **ELLE SE DÉCLARE EN TOUTES LETTRES** (« Aucun résultat pour X · affiché : Y »). Une recherche
   qui corrige en silence ment sur ce qu'elle montre, et l'on croirait avoir tapé juste. Registre
   INFORMATION, jamais ambre : la liste en dessous est juste, on dit seulement d'où elle vient.
4. **ELLE NE RÉÉCRIT PAS LE CHAMP.** Le texte tapé reste celui de l'utilisateur ; c'est le RÉSULTAT
   qui est élargi, pas la saisie corrigée sous les doigts.
· **UN PRÉFIXE N'EST JAMAIS CORRIGÉ** : on tape « anaph » en cours de frappe, et le corriger ferait
  sauter la liste sous le doigt. Un terme qui est sous-chaîne d'un mot du vocabulaire est laissé.
· **⚠ LE BUDGET SUIT LA LONGUEUR, ET IL LE FAUT (mesuré)** : à deux éditions, « anafilaxie » — la
  graphie PHONÉTIQUE, donc la faute la plus probable sur un mot qu'on n'écrit jamais — restait sans
  réponse (elle est à TROIS d'« anaphylaxie »). 1 · 2 · 3 selon la longueur, soit un tiers du mot au
  plus : au-delà ce n'est plus une faute de frappe, c'est un autre mot. Le risque d'un rapprochement
  FAUX est tenu par les quatre bornes, pas par l'étroitesse du budget — il ne coûte qu'une liste
  visiblement à côté, sous une ligne qui dit exactement ce qui a été cherché.
· **LA TRANSPOSITION COMPTE POUR UNE ÉDITION** (Damerau) : deux lettres voisines interverties sont
  la faute la plus fréquente au clavier, et deux substitutions la surestiment. La distance est
  BORNÉE — on sort dès qu'une ligne dépasse le budget, sinon un vocabulaire de plusieurs milliers
  de mots coûterait une passe complète par candidat, à chaque frappe.
· **DÉTERMINISTE** : à égalité de distance, l'ordre alphabétique tranche — sinon deux frappes
  identiques donneraient deux listes.
· **TÉMOINS AUX DEUX ÉTAGES** : `libVocab`/`spellFix`/`dlev` sont PURES (14 témoins dans
  `tests.html`), et une section d'`audit-doctrine` mesure le CÂBLAGE au rendu — c'est lui qui peut
  se tromper de cas. Elle RENCONTRE SON CAS d'abord (la requête juste doit trouver quelque chose),
  et elle est vérifiée capable d'échouer (déclenchement neutralisé → 2 rouges).

**A95. LES DEUX DERNIÈRES MICRO-ANIMATIONS — ET CE QU'ELLES ONT FAIT TROUVER (v5.6, planche 10d,
propositions 3 et 4).**
· **LE MINUTEUR ARMÉ REJOINT LA CAPSULE** : le geste a lieu EN BAS, dans le volet, et le segment
  naît EN HAUT — rien ne reliait les deux. `capIn`, 140 ms, `scaleY` depuis le bas + opacité.
  A68 en entier : elle répond à un geste ; l'état est écrit avant ; transform et opacité seulement ;
  rien ne l'attend ; bornée, une fois, inerte sous `prefers-reduced-motion` par construction.
  ⚠ **UN SEGMENT ÉCHU EN EST EXCLU** : l'alarme a sa grammaire — elle PULSE. Lui prêter l'entrée
  douce du nominal mêlerait deux registres dans la seule zone où l'ECAM réserve le mouvement à
  l'alerte.
  ⚠ **LE DRAPEAU SE CONSOMME QUAND LE SEGMENT EST PEINT, PAS QUAND ON LE LIT** (trouvé à la
  mesure) : la capsule sort tôt quand elle n'a rien à montrer, et sa boucle d'ajustement peut
  CACHER le segment — brûlé à la lecture, le drapeau perdait l'animation dans les deux cas.
· **LA PILULE D'OCCURRENCES PDF NAÎT EN FONDU**, sa RÉSERVE non : animer la bande réservée serait
  animer un rembourrage (A68/3). Et l'entrée ne joue qu'au passage caché → visible — `pdfHlSync`
  est appelée à chaque page peinte, une classe laissée en place rejouerait l'entrée pendant tout
  le défilement.
· **CE QUE LA MESURE A FAIT TROUVER, ET QUI VAUT PLUS QUE LES DEUX ANIMATIONS** — cf. A96.

**A96. LE QUAI ANNONCE CE QU'IL CACHE, MÊME QUAND C'EST LUI QUI L'A RETIRÉ (v5.6, défaut
PRÉEXISTANT trouvé en mesurant A95).** Le rappel du chevron (« n minuteurs · n compteurs ») était
conditionné à `!want.length` — « aucun minuteur ne prend la place ». Or `want` est ce que le quai
VEUT montrer, pas ce qu'il montre : la boucle d'ajustement retire des segments quand la place
manque. Mesuré à 390 px, un minuteur NOMINAL armé était donc retiré **sans un mot** — « +n » ne
compte que les ÉCHUS depuis la v5.6, et le rappel se taisait parce que le minuteur était « voulu ».
C'est la promesse ECAM prise en défaut dans la seule zone qui ne quitte jamais l'écran.
· **LE COMPTE SUIT CE QUI EST PEINT** : le libellé devient une fonction de `n` (`chevLblOf`). À
  `n=0` il rend exactement ce qu'il rendait, donc le cas nominal est inchangé au caractère près ;
  à `n=1` le minuteur montré ne se recompte pas — il ne peut pas concurrencer son propre segment.
· **UN TÉMOIN VOISIN A ROUGI, ET IL AVAIT TORT** : il exigeait que « le rappel s'efface » dès qu'un
  minuteur est armé — c'est-à-dire le MÉCANISME d'alors, avec son trou. La propriété recherchée n'a
  jamais été là : c'est « montré OU annoncé, jamais tu » et « jamais les deux à la fois ».
· **L'INTERMITTENCE EST CORRIGÉE EN A98** — le paragraphe qui la disait « mesurée, non corrigée »
  est caduc ; ce qui suit en tient lieu.
· **⚠ ET LE TÉMOIN ATTEND QUE LA CAPSULE SE STABILISE** avant de mesurer : à 140 ms fixes il
  mesurait l'instant, pas l'application. S'il n'obtient jamais son segment, il ROUGIT — il ne
  saute pas son cas (première version : l'assertion était conditionnelle, donc neutraliser
  l'animation la faisait simplement disparaître, et le témoin restait vert).

**A97. « P2 DOCUMENTS » ÉTAIT DÉJÀ LIVRÉ — VÉRIFIÉ, PAS SUPPOSÉ (v5.6, planche 10c).** La
proposition demandait qu'un mot cherché en session sorte les DOCUMENTS joints qui le portent, avec
leur page, sans ouvrir le document ni indexer à la demande. C'est la v5.3.0 (`#pfDocs`, rangées
`.doc-hit`), et `audit-pdfsearch` le mesure de bout en bout depuis : la feuille « Toute la fiche »
trouve dans le PDF joint, le tap ouvre à la bonne page avec surlignage, un mot absent replie la
zone, et l'index n'est jamais construit à la frappe. Rien n'a été réécrit ; trois témoins
s'ajoutent seulement pour l'entrée en fondu de la pilule. **Une proposition juste peut porter sur
un manque qui n'existe plus : on vérifie avant d'implémenter** (même leçon qu'A82 et A91).

**A98. LE QUAI SE MESURE SUR UN FANTÔME, ET NON EN S'ÉCRIVANT DESSUS (v5.6, demande de l'auteur —
suite d'A96).** La boucle d'ajustement ÉCRIVAIT ses candidats dans `#cbTimers` pour les mesurer :
chaque mesure détruisait et recréait les nœuds du quai. C'est ce qui obligeait à MÉMORISER la
décision — donc ce qui rendait une mauvaise mesure définitive. Le fantôme découple les deux.
· **IL EST UN ENFANT DE `#cbTimers`, et c'est ce qui le rend fidèle sans dupliquer une ligne de
  CSS** : les règles du quai sont toutes DESCENDANTES (`#cbTimers .seg` — vérifié, zéro
  combinateur enfant), donc elles s'appliquent à son contenu, et police comme couleurs s'héritent
  par l'arbre. `position:fixed` hors écran : pris hors flux, il n'est pas un item de la rangée,
  n'ajoute aucune zone défilable et ne peut rien recouvrir. Posé, mesuré, retiré dans la MÊME
  tâche — aucune image intermédiaire.
· **⚠ IL DOIT PORTER LES VALEURS, sinon il mesure un gabarit vide et croit que tout tient.** Le
  quai peint ses chiffres à part (`textContent`), donc la chaîne ne les contient pas : la première
  version du fantôme a fait DÉBORDER le quai à 320-430 px, et quatre témoins l'ont dit. Une seule
  liste de valeurs (`valsFor`) sert désormais le vivant et le fantôme.
· **UNE MESURE SANS MISE EN PAGE NE SE RETIENT PAS — c'était la cause principale.**
  `updateRtStrip` peut courir alors que la capsule n'a pas de géométrie (largeur nulle : premier
  rendu, ancêtre masqué) ; le test « ça tient » répond alors OUI à tout, et la décision prise sur
  du vide était mémorisée pour de bon. On ne mesure que si la largeur existe, et l'on ne touche
  pas à la clé sinon.
· **L'ÉTAT DE CHARGEMENT DES POLICES EST UN TERME DE LA CLÉ** : une largeur mesurée avec la fonte
  de repli n'est pas celle qu'on aura. Deux valeurs possibles, donc au plus une re-mesure.
· **ET LE QUAI RÉPOND AU GESTE, PLUS AU TICK** : armer un minuteur ne rafraîchissait que sa CARTE ;
  le segment n'entrait dans la capsule qu'au tick suivant — mesuré, 4 fois sur 8 il manquait encore
  150 ms après le tap. Dans une zone d'état, un changement COMMANDÉ se voit tout de suite, et c'est
  ce qui fait coïncider l'entrée du segment avec le geste (A68/1).
· **⚠ PAS DE RE-MESURE SPÉCULATIVE, ET C'EST LE HARNAIS QUI L'A TRANCHÉ** : un filet « re-mesurer
  une fois quand on cache quelque chose » a été écrit puis retiré — le fantôme vivant un instant
  DANS `#cbTimers`, une passe déclenchée hors changement de structure compte comme une destruction
  pour le témoin « aucun ÉLÉMENT du quai n'est détruit pendant les ticks », qui l'observe en
  `subtree`. Les trois causes étant traitées en amont, la boucle ne tourne plus qu'au changement de
  STRUCTURE — le seul moment où le quai est réécrit de toute façon.
· **MESURÉ APRÈS** : 8/8 le segment paraît immédiatement, 8/8 l'entrée joue pendant l'animation et
  ne laisse aucun résidu, 0 px de débordement de 320 à 700. Et le segment ne s'affiche que là où il
  TIENT (700) : à 320-430 il est retiré et l'annonce prend le relais — ce qui est le comportement
  juste, et non celui qu'un fantôme mal rempli faisait croire.
· **⚠ LA CLASSE D'ENTRÉE NE VIT PAS DANS LA CHAÎNE MÉMORISÉE** : posée dans le HTML, elle en fait
  partie — le tick suivant produit une chaîne différente, réécrit le quai et ARRACHE le segment en
  pleine animation (mesuré : elle survivait 5 fois sur 8). Elle est donc ajoutée au NŒUD après
  écriture, et `animationend` ne fait que la retirer (A68/2). La chaîne reste alors identique d'un
  tick à l'autre : le quai n'est pas réécrit et le nœud survit à son animation.

**A99. UNE PORTE NE DEVINE PAS UN NOM — ELLE DIT SA NATURE, ET L'ON NOMME APRÈS (v5.6, signalé à
l'usage : « comment as-tu trouvé l'intitulé automatique après ＋ Minuteur, c'est très mauvais et ça
ne se met pas à jour à chaque bloc »).** Le nom pressenti venait du DERNIER REPÈRE horodaté
(`tmAddName` → `tkLabels`) — une source qui n'a aucun rapport avec le bloc courant, donc incapable
de le suivre, et dont la qualité dépendait entièrement de ce qu'on avait étiqueté avant.
A85 avait déjà écrit la moitié de la règle (« la proposition n'invente pas de mot quand elle n'en a
pas ») ; elle vaut aussi pour la SOURCE : deviner à partir d'un objet sans rapport, c'est fabriquer
un mot. La porte ne dit plus que « ＋ Minuteur ».
· **LE NOM SE POSE SUR L'OBJET**, comme pour le compteur ad hoc (A86) : un ✎ sur la rangée du
  minuteur ouvre le même champ, avec le même commit. Le geste de création reste deux taps sans
  clavier ; le clavier n'entre que si l'on VEUT nommer.
· **⚠ LES GESTES VONT LÀ OÙ L'OBJET VIT** : un minuteur ad hoc n'est PAS rendu par `timerCard` —
  `runtimePanel` sépare `tl` (les minuteurs de la fiche, en cartes) de `minis` (les ad hoc, en
  rangées compactes). Ma première pose était donc du code MORT dans une branche que `t.adhoc` ne
  peut jamais atteindre. Et la SUPPRESSION existait déjà sur cette rangée (`data-tmrm`) : mon
  second gestionnaire l'écrasait silencieusement — deux `onclick` sur le même sélecteur, le
  dernier gagne. On lit le composant avant d'y greffer quoi que ce soit.
· `tmAddName`, `TM_GENERIQUE` et `.tm-add-n` (« d'après votre dernier repère ») sont PURGÉS avec la
  devinette qu'ils servaient — `check-classes` a d'ailleurs immédiatement signalé la règle morte.
· **DEUX TÉMOINS MESURAIENT LA DEVINETTE** et ont été réécrits sur la propriété : la porte ne dit
  que sa nature *quel que soit ce qu'on a horodaté avant*, le minuteur naît SANS nom, et sa rangée
  porte de quoi le nommer.

**A100. UN DÉFILEMENT LATÉRAL SE CORRIGE PAR LE GESTE, PAS PAR UN CLIP (v5.6, signalé à l'usage :
« fenêtre compte & synchronisation : le scroll se déplace de gauche à droite, surtout sur
smartphone »).**
· **PREMIÈRE TENTATIVE, ANNULÉE** : `overflow-x:hidden` sur la fenêtre. Rejetée à l'écran par
  l'auteur — « des éléments sont tronqués, notamment la barre d'input, et la ligne de scroll dans
  Safari tronque le contenu ». Il a raison : un `overflow:hidden` COUPE ce qui dépasse au lieu
  d'empêcher ce qui dépasse, et sur un défileur WebKit y réserve en plus sa gouttière. *Borner le
  symptôme n'est pas corriger la cause, et ici cela abîmait davantage que le défaut.*
· **CE QUE LA MESURE A ÉTABLI, ET C'EST ELLE QUI DÉSIGNE LE REMÈDE** : sous WebKit comme sous
  Chromium, à 320 / 390 / 430 px, déconnecté, connecté, avec un courriel de 70 caractères, avec le
  bloc admin « État de l'instance » rendu, et avec une chaîne INSÉCABLE injectée tour à tour dans
  seize conteneurs — **aucun élément de cette fenêtre n'est défilable en X, et rien ne dépasse de
  la carte**. Le contenu n'est donc pas en cause : le seul « débordement » visible est le halo
  compensé du ✕, voulu, et dont le bord reste dans le rembourrage (A76).
· **CE QUI RESTE EST LE GESTE** : `.ai-modal` est `overflow:auto`, donc un défileur sur les DEUX
  axes, et iOS laisse traîner un tel défileur horizontalement — avec rebond — même sans rien à
  faire défiler. `touch-action:pan-y` interdit ce panoramique **sans toucher à la géométrie** :
  aucun clip, aucune gouttière, aucune troncature possible. C'est exactement ce que la première
  tentative n'a pas su faire.
· **⚠ BORNÉ À LA FENÊTRE SIGNALÉE, DÉLIBÉRÉMENT** : `touch-action` se résout en prenant la
  contrainte la PLUS STRICTE de la chaîne d'ancêtres — un enfant ne peut donc pas rendre le
  panoramique horizontal à un tableau du mini-Markdown, à un bloc de code ou à une page de PDF
  zoomée. La fenêtre Compte n'héberge aucun défileur horizontal (vérifié) ; on étendra fenêtre par
  fenêtre, sur signalement, jamais d'un coup.
· **LEÇON GÉNÉRALE** : quand une mesure ne rencontre pas le défaut signalé, on ne borne pas le
  symptôme au jugé. Ou l'on cherche jusqu'à trouver ce qui, dans la MÉCANIQUE et non dans le
  contenu, peut le produire — ou l'on dit qu'on ne l'a pas trouvé.

**A101. UN FOND DE RANGÉE VA D'UN BORD À L'AUTRE DE SA CARTE (v5.6, signalé à l'usage, captures à
l'appui : « le fond de sélection ne s'affiche pas sur toute la largeur », « session en cours : le
vert ne prend pas toute la largeur »).** En voie étroite les rangées vivent dans une carte par
lettre, et c'est la CARTE qui porte les 16 px de rembourrage horizontal : la rangée commençait donc
17 px après son bord gauche et s'arrêtait 17 px avant le droit. Invisible tant qu'elle est
transparente — mais dès qu'elle prend un fond (survol, vert d'une session vive), le rectangle teinté
flotte au milieu avec deux bandes nues de part et d'autre. Mesuré à 390 px : **304 px de rangée dans
une carte de 338**. La rangée reprend les 16 px en marges NÉGATIVES et les rend en rembourrage : sa
BOÎTE va d'un bord à l'autre, son CONTENU ne bouge pas d'un pixel (titre à x=35 et épingle 285→315,
identiques avant/après). `.dir-book` reçoit `overflow:hidden` — sans quoi la première et la dernière
rangée dépasseraient des coins arrondis (aucun titre de lettre n'est collant : rien à casser).
· **⚠ UNE COMPENSATION VIT AVEC CE QU'ELLE COMPENSE (signalé dans la foulée : « tu as cassé
  l'affichage des cartes en 2/3 colonnes »)** : `.dir-book` perd son rembourrage à partir de 780 px.
  Posée au niveau racine, la marge négative y tirait les rangées 16 px HORS de leur colonne. Elle
  est bornée à `max-width:779.98px`, le palier même où le rembourrage existe. Vérifié à 390, 700,
  900, 1280 et 1600 : plus rien ne sort de sa carte, et la teinte va bien d'un bord à l'autre en
  voie étroite.

**A102. QUAND L'ALPHABET NE TIENT PAS CENTRÉ, ON L'ÉCLAIRCIT (v5.6, décision de l'auteur après
mesure).** Le clamp d'`azrCentrer` pousse les lettres aussi haut que la boîte l'autorise, et c'est
l'optimum — mais l'optimum n'est pas le centre. MESURÉ à 390 × 844 : la boîte commence à 121 px
(sous l'en-tête, pour qu'aucune lettre ne passe derrière lui), l'axe de l'écran est à 422, et un
alphabet complet mesure 650 px — il devrait donc commencer à 97. Il reste **24 px trop bas**, et
descendre les cibles au plancher WCAG de 24 px n'en rendrait que 13 : c'est géométriquement
impossible sans cacher des lettres.
· **LA SOLUTION EST CELLE DE L'INDEX DE CONTACTS D'iOS** : montrer MOINS d'entrées, un « · » à la
  place de deux lettres. L'index raccourci se centre alors exactement (mesuré : **écart 1 px** à
  320 et 390 px avec 26 lettres, contre 24 avant), les cibles gardent leurs **24 px**, et rien
  n'est injoignable — un point mène à la première lettre qu'il porte et son nom accessible les cite
  toutes les deux (« Aller à B ou C »).
· **ON NE FUSIONNE QUE DES PAIRES, ET SEULEMENT CE QU'IL FAUT** : un point qui avalerait cinq
  lettres ne serait plus un index. S'il en faudrait plus que la moitié de l'alphabet, on renonce —
  le rail se replie déjà tout seul quand il ne tient pas, ce qui vaut mieux qu'un index illisible.
· **RÉSERVÉ AUX LETTRES** : le rail des CATÉGORIES porte des pastilles de couleur, qui ne se
  remplacent pas par un point sans perdre ce qu'elles disent.
· **LA RÉCURSION EST BORNÉE À UN TOUR** (`azrCentrer(rail,true)`) : la seconde passe ne peut plus
  rien éclaircir puisque l'index tient désormais, et une boucle ici serait une boucle de rendu.
· **LES GESTES IGNORENT LES LETTRES REPLIÉES** : `snap()` filtrait sur `[data-azl]`, qui inclut les
  masquées — leurs rectangles nuls auraient faussé le mapping du glisser.
· **⚠ CE QUI N'ÉTAIT PAS EN CAUSE, ET QU'IL FAUT DIRE** : les bulles de session en tête de liste.
  Mesuré avec et sans, à 390 et à 1280 : **écart 1 px dans les quatre cas**. Le décentrage ne
  dépend que du NOMBRE de lettres, jamais du contenu de la liste.
· **TÉMOIN** : trois configurations, et il RENCONTRE SON CAS des deux côtés — à 26 lettres sur
  téléphone il exige des points, à 16 (ou en voie large) il exige qu'il n'y en ait AUCUN. Vérifié
  capable d'échouer (éclaircissement neutralisé → 2 rouges).

**A103. CINQ DÉFAUTS DU VOLET ET DE L'ACCUEIL, TOUS MESURÉS (v5.6, signalés à l'usage).**
· **« VOIR LE COMPTE-RENDU » ÉTAIT UN BOUTON MORT** : il portait `data-prelast`, un attribut émis
  UNE FOIS et câblé NULLE PART — un nom inventé à côté du `data-report` que `bindReadEvents` relie
  déjà à `exportSessionReport`. On ne rajoute pas un gestionnaire, on donne au bouton le nom du
  geste qu'il fait. *Règle : avant d'inventer un attribut, chercher celui qui nomme déjà l'action —
  un verbe qui a deux noms finit par n'en avoir aucun.*
· **LES RANGÉES COMPACTES DE MINUTEUR NE SE COLLENT PLUS** : le rail les posait à `margin-top:0`
  — mesuré, **0 px** entre deux rangées ET sous la carte qui précède, quand le volet leur donne
  8 px. Deux objets distincts qui se touchent se lisent comme un seul.
· **LA CROIX DU COMPTEUR AD HOC TENAIT SES 24 px EN HAUTEUR, PAS EN LARGEUR** : `min-height:32px`
  bornait un seul axe, la largeur valant le glyphe plus 12 px de rembourrage — **20 px** mesurés,
  sous WCAG 2.2 § 2.5.8. Le plancher se pose sur les DEUX axes.
· **LE CHAMP DE NOMMAGE AVAIT BESOIN D'UNE RANGÉE QUI ENROULE** : `.tm-label` est `nowrap`, donc
  `flex:1 1 100%` ne pouvait rien et le champ se partageait la ligne avec le nom et les deux
  boutons — **84 px de champ dans une rangée de 182**. `:has(.cn-input)` ouvre l'enroulement
  seulement quand le champ est là : 84 → **182 px**, et la rangée au repos ne change pas.
· **LE VERROU DE VEILLE PREND LE VOCABULAIRE DE SON VOISIN** : « Écran maintenu / Veille normale »
  disait deux choses différentes selon l'état et coûtait 131 px. Le bouton du SON dit « Son
  activé / Son coupé » ; celui-ci dit donc « Veille coupée / Veille active » — même grammaire, même
  longueur, l'état se lit sans réfléchir.
· **ET L'EN-TÊTE DU VOLET CESSE DE DONNER UNE LIGNE À UN SEUL BOUTON** : mesuré à 390 px, les trois
  contrôles demandaient 330 px pour 294 et « Veille coupée » tombait SEULE sur une troisième ligne.
  `#soundWarn` passe au glyphe seul sous 560 px (règle A2 : la touche perd son étiquette, jamais son
  nom accessible) — c'est le bon candidat, étant une CAUTION dont le texte entier s'affiche au tap,
  pas un contrôle dont le libellé porte l'état. **152 → 100 px** à 390, 430 et 560 ; 48 px au-delà.
  ⚠ **DEUX ESSAIS ÉCARTÉS PAR LA MESURE, ET ILS DISENT LA MÊME CHOSE** : déplacer le couloir du ✕
  sur le TITRE — en rembourrage, puis en largeur maximale — a été pire dans les deux cas (le titre
  s'enroulait SOUS le ✕, 176 px ; puis un autre contrôle montait à sa droite, donc sous le ✕).
  *Une réserve de rangée protège la ligne ENTIÈRE ; aucune borne posée sur un seul enfant ne le
  fait.* Coût dit : à 320 px le titre du volet ne tient pas sur une ligne, l'en-tête y reste à
  176 px — c'est le titre qui est long, pas la rangée qui est mal faite.

**A104. LE DÉCLENCHEUR DE FILTRE N'A QU'UNE ADRESSE : CONTRE LA RECHERCHE (v5.6, demande de
l'auteur : « il devrait apparaître à droite de la barre de recherche en tout temps »).** Il
changeait d'adresse selon le DÉFILEMENT — dans la rangée de groupement en haut de page, contre le
champ une fois l'en-tête resserré. Or les deux répondent à la même question (restreindre ce qu'on
voit), et un contrôle dont la place dépend de l'endroit où l'on se trouve dans la page est un
contrôle qu'on cherche à chaque fois. C'est le raisonnement de la planche 7b pour la recherche
elle-même, appliqué à son voisin.
· **⚠ IL Y AVAIT DEUX PLACEMENTS, ET C'EST LE SECOND QUI DÉCIDAIT** : `syncHomeNew` au défilement,
  et un `row.appendChild(ft)` à CHAQUE rendu. Corriger le premier seul laissait le défaut entier au
  chargement — le témoin l'a dit aussitôt (`dansChamp:false`). *Quand un objet est placé par deux
  chemins, corriger l'un ne corrige rien.*
· **IL PREND LA HAUTEUR DU CHAMP** (`align-self:stretch` + `aspect-ratio:1`) : il valait 38 px face
  à un champ de 48, et deux objets d'une même rangée qui ne s'alignent pas se lisent comme deux
  niveaux. Rond par construction, sans écrire un second nombre.
· **LE TÉMOIN A CHANGÉ DE VOISIN, PAS DE SUJET** : il mesurait le déclencheur contre le sélecteur de
  groupement — son adresse d'alors. Il mesure désormais « contre le champ, à sa droite, aligné », et
  **dans les deux états de défilement** : c'est cette seconde moitié qui couvre le défaut signalé.

**A105. DEUX RÉGLAGES JUMEAUX NE SE SÉPARENT JAMAIS (v5.6, signalé à l'usage : « le bouton veille
apparaît toujours en dessous du bouton son », puis « aussi en desktop dans la sidebar »).** Les deux
interrupteurs tenaient sur la même ligne à partir de 390 px et pas en dessous — mesuré : à 375 il
manquait DEUX pixels, à 360 dix-sept, à 320 trente-trois. Espérer qu'ils tiennent est une erreur de
méthode : ce qu'on veut n'est pas « qu'ils rentrent » mais qu'ils ne se séparent PAS — deux réglages
de même grammaire dont l'un tombe seul sous l'autre se lisent comme deux objets sans rapport.
Enveloppés (`.rt-togs`), ils enroulent ENSEMBLE. Mesuré : même ligne à 320 · 360 · 375 · 390 · 414 ·
430 · 560 · 700 · 900 · 1280, et dans le RAIL aussi, où le groupe (311 px) dépasse la colonne
(301 px) et enroule donc d'un bloc au lieu de se couper en deux.
· **ET LE GABARIT PORTAIT ENCORE LES ANCIENS LIBELLÉS** : seul `syncWakeBtn` avait été corrigé, si
  bien que la PREMIÈRE peinture disait « Écran maintenu » et la suivante « Veille coupée ». Quand un
  libellé est écrit à deux endroits, corriger l'un ne corrige que la moitié du temps.

**A106. UN GLYPHE VIENT DE `uiIcon`, JAMAIS ÉCRIT EN CLAIR (v5.6, signalé à l'usage : « il y a des
doublons d'icônes — le crayon pour modifier un minuteur créé existe déjà, pareil pour le
recommencer »).** La règle est posée depuis la v4.71.0 (« les anciens glyphes texte ✎ ✦ ⤓ ↺ rendaient
un dessin différent selon la police du système ») ; mes ajouts l'avaient enfreinte en réintroduisant
« ✎ » et « ⟲ » littéraux à côté des tracés `pen` et `undo` qui existaient déjà dans la table. Deux
dessins pour une même idée, c'est deux choses à apprendre — et `check-icons` ne peut pas le voir : il
vérifie que tout nom passé à `uiIcon` existe, pas qu'on ait pensé à l'appeler.

**A107. « DIAGNOSTIC CONFIRMÉ » RESTE UN ÉTAGE — TENTATIVE ANNULÉE, ET LA MESURE EST LA RAISON
(v5.6, demande de l'auteur : « déplace diagnostic confirmé dans le dépliant “x blocs faits —
diagnostic confirmé” »).** Le déplacement a été écrit et il FONCTIONNAIT : condition d'entrée avant
le démarrage (A19), trace dans l'historique après, repliée dans « ✓ n blocs faits · diagnostic
confirmé », jamais perdue entre les deux. `audit-partage` l'a rougi sur un invariant de crise — « il
regardait ailleurs : ce qu'il regarde ne bouge pas » — avec **457 px de dérive**.
· **⚠ LA CAUSE QUE J'AVAIS ÉCRITE ÉTAIT FAUSSE, ET LA MESURE L'A DÉFAITE.** J'avais attribué les
  457 px au bloc de confirmation changeant de logement : il fait **50 px replié** (mesuré), il ne
  peut pas produire cela. Ce qui vaut ~450-515 px dans cette scène, c'est la CONDENSATION R6 d'un
  passage achevé — carte de bloc 559 px à 390, 495 à 1100, contre 44 px de rangée.
· **CE QUE LA MESURE ÉTABLIT VRAIMENT, ET C'EST PLUS INSTRUCTIF** — deux faits, chacun vérifié :
  1. **`keepAnchor` NE COMPENSE RIEN DANS CE SCÉNARIO.** Il s'ancre sur la DERNIÈRE carte de bloc
     (`.ov-block[data-ovi]`) — précisément celle que le lot condense. Après le re-rendu le
     sélecteur ne matche plus, et la fonction sort par `if(!nl)return null` sans toucher au
     défilement. Mesuré `ancreSurvit:false` dans les DEUX versions du code. Tout changement de
     hauteur au-dessus du regard est donc transmis tel quel.
  2. **LE TÉMOIN EST GARÉ AU BAS DE LA PAGE** : il fait `scrollTo(0, scrollHeight)` pour signifier
     « il regarde ailleurs ». Ce qu'il mesure ensuite est donc la façon dont le NAVIGATEUR
     réconcilie un défilement collé au bout avec un document qui change de hauteur — c'est le piège
     que ce dossier a déjà consigné en **A46**, à 22 px près ; ici il vaut plusieurs centaines.
  Reproduit dans un état voisin : SANS le déplacement, dérive **79 px**, rabat 0 ; AVEC, dérive
  **1 px**, rabat −78. L'écart ne va donc même pas dans le sens que je supposais.
· **CE QUI RESTE VRAI MALGRÉ TOUT** : je n'ai pas reproduit l'état EXACT du témoin (le mien dérive
  déjà de 79 px sur le code livré, le sien de 0), donc je ne peux pas conclure que ses 457 px sont
  un artefact — ni qu'ils sont une régression. **On ne re-livre pas le déplacement sur une
  incertitude**, et l'annulation reste la bonne décision par défaut.
· **DEUX CHANTIERS SÉPARÉS EN SORTENT, ET ILS VALENT PLUS QUE LA FONCTIONNALITÉ** : (a) appliquer
  A46 à ce témoin — il ne doit pas mesurer depuis le bout de la page, sinon il mesure le navigateur ;
  (b) `keepAnchor` devrait savoir se rabattre sur un ancêtre survivant quand sa carte est condensée,
  au lieu de renoncer en silence — c'est un trou réel, indépendant de cette fonctionnalité.
· **CE QU'IL FAUDRAIT POUR LE FAIRE PROPREMENT** : que la confirmation soit une ligne-bilan DÈS le
  démarrage (« ✓ diagnostic confirmé »), qui gagne ensuite le compte des blocs dans son libellé —
  alors elle ne déménage jamais, seul son texte s'allonge. C'est une refonte de l'assemblage du
  journal, à décider séparément et à mesurer contre ce même témoin.
· **TROIS ORDONNANCEMENTS APPRIS EN CHEMIN, ET ILS RESTENT VRAIS** : le journal est construit
  ~200 lignes AVANT que la confirmation ne soit calculée dans `renderRead` (un drapeau posé après
  n'arrive qu'au rendu suivant) ; `renderOvOnly` re-rend le journal SEUL, bien plus souvent que
  `renderRead`, donc un drapeau à usage unique y est brûlé au premier passage ; et une décision
  prise dans `renderRead` ne se met pas à jour aux re-rendus du journal.

**A108. QUAND L'ANCRE DISPARAÎT, ON SE RABAT SUR CE QUE L'ŒIL REGARDE (v5.6, trouvé en cherchant
la cause des 457 px d'A107).** `keepAnchor` sortait par `if(!nl)return null` dès que son ancre
n'existait plus après le re-rendu — **sans compenser quoi que ce soit**, et en silence. Ce n'est pas
un cas rare : un lot distant qui fait avancer le parcours CONDENSE la dernière carte de bloc (R6),
or c'est exactement elle que `shareApplyAnchored` prend pour ancre. Mesuré `ancreSurvit:false`, donc
les ~500 px que la condensation retire au-dessus du regard partaient droit dans l'œil de quelqu'un
qui n'avait rien demandé. **Mesuré après : dérive 79 → 1 px.**
· **LE REPLI EST LA PROPRIÉTÉ, PAS UN SECOND SÉLECTEUR** : on capture, avant le re-rendu,
  **l'élément sous le centre de l'écran**. C'est la définition littérale de « rien ne bouge sous les
  yeux » — et c'est ce que le témoin de partage mesure, donc l'instrument et le remède visent enfin
  la même chose. Un second sélecteur écrit à la main aurait été un troisième endroit à tenir.
· **⚠ ON LE CHERCHE DANS `main`** (`elementsFromPoint`, premier élément du flux) : au centre de
  l'écran on tombe volontiers sur une couche FIXE — capsule, volet, dock — qui ne bouge JAMAIS, donc
  compenserait zéro tout en ayant l'air de compenser. Un repli qui ne peut pas échouer ne vaut rien.
· **⚠ ET SI L'ŒIL MEURT AUSSI, ON REMONTE SES ANCÊTRES** : un sous-arbre détaché garde sa chaîne
  `parentNode`, donc le premier ancêtre encore `isConnected` est un nœud réel du NOUVEAU document.
  Au pire on atteint `main`, dont le haut ne bouge pas : la compensation vaut alors zéro — c'est
  -à-dire exactement le comportement d'avant. **Ce repli ne peut rien dégrader**, ce qui est la
  condition pour toucher une fonction que tout le fichier appelle.
· **PORTÉE** : le chemin nominal est INCHANGÉ au caractère près (ancre présente → même calcul, même
  valeur de retour). Seul le cas « ancre absente ou disparue », qui rendait `null` sans rien faire,
  gagne un comportement. 983 témoins × 2 moteurs et les 25 tâches d'audit sont verts.

**A109. LE TÉMOIN DE DÉRIVE MESURAIT LE NAVIGATEUR — QUATRE DÉFAUTS D'INSTRUMENT, AUCUN DE PRODUIT
(v5.6, A46 appliqué au témoin de partage).** Il accusait 457 px sur un correctif juste. Reconstruit,
il en trouve zéro et rougit à 120 px quand on casse vraiment la propriété. Les quatre :
1. **IL SE GARAIT SUR LA BORNE** (`scrollTo(0, scrollHeight)`) : à défilement saturé, un document
   qui rétrécit se fait RABATTRE par le navigateur, et le rabat est imputé à l'app. **⚠ ET LA
   PARADE N'EST PAS UNE MARGE** — exiger 80 px de bande était géométriquement impossible (il n'y a
   qu'une centaine de pixels sous la rangée « Consulter »). On mesure LE RABAT lui-même : la borne
   d'après atteint-elle encore la position d'avant ?
2. **IL TENAIT UN NŒUD, PAS UN SÉLECTEUR** : un `innerHTML` détruit l'élément regardé, la mesure
   rendait `null`, et `null` était compté comme un échec — un rouge qui ne dit rien du produit.
3. **SON PRÉDICAT DE RÉGIME N'ÉTAIT PAS CELUI DE L'APPLICATION** : le témoin lisait « bout hors de
   vue » en `top >= 0 && top < vh-4`, l'app décide en `bottom > stickBase() && top < innerHeight`.
   Une carte HAUTE dont le bas dépasse encore est « sous les yeux » pour l'app et « ailleurs » pour
   le témoin : il exigeait l'immobilité pendant que l'app suivait le bord vif — **273 px mesurés,
   imputés à un comportement juste**. Deux définitions concurrentes d'un même régime, la divergence
   que ce dépôt a déjà payée quatre fois.
4. **SON LOT NE CHANGEAIT RIEN** : avec un seul bloc, la carte qui se condense et celle qui s'ouvre
   ont la même hauteur — journal à **30 px** près, donc le contrôle restait VERT même en retirant
   TOUT l'ancrage. L'hôte avance désormais de plusieurs blocs (le cas réel du retard rattrapé à la
   jointure) et le témoin **refuse de conclure** si le journal n'a pas bougé d'au moins 50 px.
· **⚠ ET LE FAIT LE PLUS UTILE DE TOUT LE DOSSIER : CE RÉGIME EST TENU PAR LE NAVIGATEUR.**
  Neutraliser `keepAnchor` ENTIÈREMENT laisse le témoin vert — l'ancrage natif (`overflow-anchor`)
  garde le contenu stable quand la hauteur change au-dessus. Ce n'est PAS un témoin cassé : il
  mesure la PROPRIÉTÉ (règle 11), pas le mécanisme du jour, et c'est ce que la doctrine demande.
  Corollaire à connaître avant d'écrire du code d'ancrage : **notre compensation ne sert que là où
  l'ancrage natif ne peut pas** — défilement à la borne, ou nœud d'ancrage supprimé. Partout
  ailleurs elle est un filet, pas le porteur.
· **BALAYAGE DES AUTRES TÉMOINS GARÉS SUR UNE BORNE — UN SEUL AUTRE CAS, ET TROIS NON-DÉFAUTS
  QU'IL FAUT NOMMER** (règle A56 : un balayage qui tait ses non-défauts finit par les faire
  « corriger »). Le piège n'est PAS « se garer au bout » : c'est **comparer une position de part et
  d'autre d'un changement de hauteur alors qu'on est au bout**. Sont donc légitimes, et le restent :
  le menu ⋯ défilé à son extrémité (`m.scrollTop=m.scrollHeight`) — la borne EST le sujet, « la
  dernière rangée est-elle atteignable », et rien ne change de hauteur ensuite ; la sonde qui écrit
  `scrollTop=999999` pour LIRE le maximum puis le restaure ; la sidebar de l'accueil, dont on
  vérifie précisément que le bas est joignable. Le seul à corriger était la barre de référence :
  son `scrollTo(0,1200)` est ÉCRÊTÉ sur un document plus court, donc « la barre reste visible loin
  dans la page » pouvait se vérifier sans qu'on soit jamais parti — il mesure désormais qu'il a
  bien défilé. Là non plus la borne ne fausse rien (la barre est FIXE) : c'est le CAS qui manquait.
· **CE QU'AUCUN TÉMOIN NE COUVRE, ET IL FAUT LE DIRE** : le repli d'A108 et l'ancre sur l'œil en
  régime 2 sont mesurés utiles à la borne (79 → 1 px) — précisément la position que ce témoin
  s'interdit désormais. Les deux sont conservés parce qu'ils **retombent sur un no-op** quand ils
  ne trouvent rien, jamais parce qu'un contrôle les prouve.

**A110. « DIAGNOSTIC CONFIRMÉ » EST UNE LIGNE DU JOURNAL, ET ELLE N'Y DÉMÉNAGE JAMAIS (v5.6,
demande de l'auteur — re-livré après l'annulation d'A107).** Avant le soin, la condition d'entrée
EST la question et reste une carte en tête du flux (A19). Une fois démarré, elle ne conduit plus
rien : c'est une TRACE, et sa place est celle des traces — la tête du journal, dont elle est
chronologiquement le premier élément.
· **CE QUI MANQUAIT À LA PREMIÈRE TENTATIVE, ET QUI EST ICI** : la garantie de non-déménagement.
  La ligne ouvre le journal dès le démarrage (« ✓ diagnostic confirmé ») ; quand le premier
  passage s'achève, la ligne-bilan des blocs faits **l'absorbe** au lieu de la pousser — seule sa
  légende s'allonge (« ✓ n blocs faits · a→b · diagnostic confirmé »). Mesuré : **y = 191 px avant
  comme après**. La fusion n'a lieu que si la ligne-bilan commence au PREMIER passage ; sinon la
  confirmation garde sa propre ligne, à la même place.
· **DANS LE DÉPLIANT, C'EST UNE RANGÉE COMME LES BLOCS** (demande de l'auteur) : verser les
  critères en vrac mettait sur le même plan quatre lignes de contenu et n rangées de blocs. Elle
  prend donc UNE rangée de la même anatomie (✓ · titre · compte · chevron), qui déroule ses
  critères d'un tap. Deux niveaux, une seule grammaire.
· **ELLE SE CALCULE DANS LE JOURNAL, JAMAIS PAR UN DRAPEAU** : `renderOvOnly` re-rend le journal
  SEUL, bien plus souvent que `renderRead` — un drapeau à usage unique y serait brûlé au premier
  passage. Les trois pièges d'ordonnancement d'A107 sont ainsi désarmés plutôt que contournés.
· **⚠ ET LE HARNAIS A IMMÉDIATEMENT TROUVÉ UN DÉFAUT PRÉEXISTANT** : `.ovr-chev` mesurait
  **2,13:1**. Rien ne pouvait le voir — la ligne-bilan n'existait qu'après un passage achevé, donc
  sur aucune des surfaces qu'`audit-a11y` monte. Le chevron prend l'encre de sa ligne
  (`color:inherit`). *Un défaut HORS PORTÉE n'est pas un défaut absent* (leçon v4.75.0, rejouée à
  l'identique) — et `aria-hidden` n'exempte pas du seuil, le glyphe reste peint.

**A111. LES RÉGLAGES DESCENDENT AU PIED — L'ÉTAT VIVANT PASSE DEVANT (v5.6, signalé à l'usage :
« deux boutons utilisés périodiquement prennent autant de place avant les minuteurs-compteurs-
journal d'action »).** A105 avait raison de rendre les deux interrupteurs INSÉPARABLES, et tort de
les laisser dans l'en-tête de famille : enveloppés, ils enroulaient ensemble — **ensemble sur une
SECONDE LIGNE**, y compris dans le rail de 301 px où le groupe en demande 311. Une rangée entière
au-dessus du contenu vivant, pour deux réglages qu'on touche une ou deux fois par soin.
· **C'EST UNE QUESTION DE NATURE, PAS DE PLACE** : le son et le verrou de veille sont des
  RÉGLAGES ; les minuteurs, les compteurs et le journal sont de l'ÉTAT. L'ordre ECAM met l'état
  d'abord, et le rail applique déjà la même idée (« l'illimité en dernier »). Ils descendent donc
  au PIED du panneau (`.rt-set`), après ce qu'ils règlent, séparés par un filet — jamais par un
  titre : deux interrupteurs se reconnaissent à leur forme, les annoncer serait du bruit.
· **ILS Y GARDENT LEURS MOTS** (A103) : l'état se lit sans réfléchir, et l'on n'a pas eu à les
  compacter au glyphe seul — ce qui aurait été la mauvaise réponse, puisque c'est le LIBELLÉ qui
  porte l'état d'un interrupteur. Mesuré à 320 · 390 · 430 · 1280 : jumeaux sur une même ligne,
  0 px de débordement, en-tête du rail ramené à **19 px**.
· **UNE RÈGLE MEURT AVEC SA CAUSE** : `.rt-wl` masquait « silencieux ? » sous 560 px parce que la
  rangée d'en-tête était pleine. Elle ne l'est plus — l'avertissement retrouve ses mots (une
  CAUTION muette n'avertit de rien) et la classe est PURGÉE, épitaphes posées aux deux sites qui
  la citaient (règle 14 + A72). Au pied, à 320 px, il prend sa propre ligne : **là, cela ne coûte
  rien.**

**A112. UN ATTRIBUT ÉMIS SANS LECTEUR EST UN CONTRÔLE QUI A L'AIR VIVANT — `check-actions`
(v5.6, généralisation du défaut « Voir le compte-rendu »).** A103 avait corrigé le cas d'espèce :
`data-prelast`, émis UNE fois et câblé NULLE PART, à côté du `data-report` que `bindReadEvents`
relie déjà à `exportSessionReport`. **Rien dans le dispositif ne pouvait le voir** — ce n'est ni
une classe, ni une icône, ni une couleur ; le bouton s'affiche, se survole, se focalise, et ne
fait RIEN. Dans une aide d'urgence, c'est le pire mode de défaillance.
· **LA RÈGLE EST AUTO-EXÉCUTOIRE DEPUIS** : tout `data-x=` écrit dans un gabarit doit avoir un
  LECTEUR dans le fichier — sélecteur `[data-x]` ou `[data-x="…"]` (les règles CSS comptent),
  `dataset.x`, ou `get/set/has/removeAttribute('data-x')`. Vérifié CAPABLE D'ÉCHOUER en
  réintroduisant `data-prelast` : rouge, avec le nom de l'attribut.
· **TROIS ATTRIBUTS MORTS SONT PARTIS AVEC** (règle 14) : `data-ai` (rangée de document de
  l'éditeur), `data-jli` (jalon, aux deux sites), `data-tgk` (vocabulaire du journal) — des
  repères d'index que plus rien ne lisait.
· **LES EXEMPTIONS NOMMENT LEUR LECTEUR, jamais leur raison** : `data-upkind` existe pour
  `audit-upload`, `data-i` comme poignée de mesure. Une liste d'exemptions sans lecteur nommé
  devient l'endroit où l'on range ce qu'on n'a pas compris — et le contrôle échoue aussi quand une
  exemption n'a plus d'objet, sinon la liste finirait par mentir.
· **⚠ CE QU'IL NE VOIT PAS, ET C'EST DIT DANS SA SORTIE** : un attribut lu par une expression
  CALCULÉE (`el.dataset[nom]`, un sélecteur assemblé) sort de la portée d'un contrôle statique —
  même limite que les noms d'icône calculés de `check-icons`. Il attrape l'ORPHELIN, pas
  l'indirection ; c'est exactement le cas qui l'a fait écrire.

**R6. LE PASSÉ S'ANNONCE ET SE TIRE.** Tout passage complet et non courant devient une chip, et la
rangée de chips se replie DÈS QU'ELLE EXISTE en ligne-bilan « ⌄ fait · ✓ n passages · a→b », qu'un
tap déplie sur place. Les deux invariants du journal sont intacts, et ce sont eux qui rendent le
repli admissible : un passage INCOMPLET n'est jamais une chip, le BOUT est toujours une carte.
ACHÈTE : le bloc seul au centre, ~11 objets à l'écran contre 25.
⚠ v5.6 — LE COMPOSANT CHIP EST PURGÉ (règle 14, zéro émission vérifiée) : DÉPLIÉE, la ligne-bilan
rend une CARTE DE RANGÉES (« ✓ n · titre · passage k/n · compte mono »), pas une rangée de chips.
Une chip abrège à treize caractères — sans importance tant qu'elle est repliée, rédhibitoire à
l'instant où l'on DÉPLIE, puisqu'on vient justement relire ce qui a été fait. Même grammaire que le
parcours : « la liste des blocs » se lit pareil partout.
⚠ CONSÉQUENCE MESURÉE : le journal ne grandit plus, donc à 390 px le contrôle d'avancement est
souvent DÉJÀ visible à la réouverture — `landOnBout` a alors raison de ne pas défiler, et le témoin
de réentrée mesure les DEUX régimes plutôt que d'exiger un atterrissage qui n'a plus lieu d'être.

**R9. LE PIED DE CARTE NE PORTE PLUS QU'UN GESTE.** Il en portait trois (⚡︎, ⏱, Vérifier) et la
pile dépassait le plafond de 25 % de la hauteur de carte sur un bloc court. Deux ne sont pas des
gestes de BLOC par nature — une complication survient quand elle survient, un horodatage se pose à
n'importe quel moment : ils sont partis au dock. **L'ACCUSÉ DE RÉCEPTION LES A SUIVIS** : la règle
« la réponse vit là où le geste a eu lieu » (M11) n'a pas bougé d'un mot, c'est le geste qui s'est
déplacé — le laisser derrière aurait produit DEUX réponses à un seul geste. `tkAckHtml`,
`state.tkAck` et les règles `.tk-ack*` sont purgés (règle 14).

**DEUX OBJETS, DEUX NATURES — ÉTAT EN HAUT, COMMANDES EN BAS.** Ceci ROUVRE la v4.25.0 (« deux
rangées, deux natures ») et la règle « une seule zone fixe, en haut ». L'ESPRIT de v4.25.0 est
conservé — commandes ≠ état, c'est l'architecture ECP/ECAM — mais la FORME est inversée : l'ÉTAT
monte dans une CAPSULE, les COMMANDES descendent dans un DOCK au pouce. La règle du chrome bas
visait les NOTIFICATIONS FLOTTANTES (règle 11), pas une surface de commandes stable ; trois risques
nommés et traités au code : safe-area iOS, clavier virtuel (A1), 320 px (A2).
GAIN MESURÉ : chrome haut **175 → 131 px** à 390 px, trois `border-bottom` empilés en moins.
⚠ `fitCtrlRow` est SUPPRIMÉE avec la rangée qu'elle ajustait — mais son appelant enchaînait
`fitCtrlRow()` puis `syncHdrScroll()`, et **le second appel reste** : `--hdr-h` et `--stick-top`
sont consommés par la capsule, le rail A→Z, le rail de lecture, `stickBase()` et le `scroll-margin`
qui empêche le masquage total d'une cible d'ancre (exigence AA, sonde 2.4.11).

**VOLETS SYSTÈME — DOCTRINE D'OCCULTATION.** L'occultation COMMANDÉE est conforme ECAM/QRH
(appeler une page remplace la page affichée) ; ce que la doctrine interdit, c'est l'occultation non
commandée et l'occultation piégeante.
- **V1.** Un volet ne s'ouvre que sur tap d'une touche du dock. Fermeture TRIPLE : re-tap, ✕ ≥ 44 px,
  tap hors volet — plus le retour système, qui passe par le même chemin. Rien ne bouge derrière (le
  volet est `fixed` : il ne change aucune géométrie de flux, le témoin M11 tient par construction).
- **V2.** L'alarme reste TOUJOURS en vue : capsule en HAUT, volets en BAS. Même volet ouvert,
  l'ambre qui pulse est visible (règle FMA de l'ECAM).
- **V3.** Hauteur plafonnée à ~45 % de la hauteur VISIBLE : jamais plein écran, le contexte reste
  lisible. Si une étape critique est non cochée, le volet l'annonce EN TÊTE (gestion d'interruption,
  AC 120-71B §5.5) — ce qu'on allait faire doit survivre à ce qu'on vient d'ouvrir.
- **⏱ L'HEURE PRIME.** Le tap pose l'horodatage IMMÉDIATEMENT au journal (l'instant du TAP, pas
  celui de la saisie) ; le volet n'est que la nomination facultative, annulable et renommable après
  coup. Pas de modale en crise. `tkNoteNow` reste le point d'écriture unique — on l'APPELLE, on ne
  le réécrit pas.
- **⚡︎ BIFURCATION ANNONCÉE.** Rangées ≥ 56 px : nom en toutes lettres + condition d'entrée +
  destination (« → bloc 9 · retour ↩ 7 »). On sait AVANT de taper où l'on va et qu'on reviendra.
  **À UN SEUL ÉVÉNEMENT, IL N'Y A PAS D'INDEX** : la touche porte son NOM et l'on entre d'un tap —
  ouvrir une liste d'un élément pour y choisir cet élément est le bouton mort de la doctrine, en
  plus lent. Et l'on ne propose pas d'entrer là où l'on est déjà : à un événement la touche
  disparaît, à deux la rangée courante s'annonce et cesse d'être tapable.

**NAVIGATION D'ACCUEIL UNIFORMISÉE — UNE LISTE, DEUX CLÉS.** Le sélecteur « A–Z | Catégories »
choisit la CLÉ DE GROUPEMENT de la MÊME liste, et le rail droit est le MÊME index dans les deux
modes (lettres ↔ pastilles de catégorie). On ne perd jamais de fiche en changeant de clé : c'est un
changement d'ordre, pas de contenu — et c'est ce qui distingue un groupement d'un FILTRE. Les
filtres, eux, gardent leur déclencheur à badge chiffré, et leur RÉSUMÉ en toutes lettres rejoint
l'en-tête de section (« · filtres : Perso · aides ») : un filtre posé ne doit jamais être invisible.
La SESSION VIVE est le seul objet sombre de l'accueil — c'est le même objet que la capsule de crise,
on le reconnaît sans lire.

**PARTAGE — CE QUI EST FERMÉ AU SCRIBE.** Exactement quatre gestes (`SHARE_KINDS_LEAD`) : décocher,
remettre un minuteur à zéro, démarrer, terminer — tous destructeurs ou structurants. Cocher
appartient au scribe : l'avancement est PARTAGÉ et chaque ligne porte son attribution. Une commande
fermée au scribe **n'apparaît pas éteinte : elle n'apparaît pas** (la touche ⚡︎ du dock n'existe pas
pour lui ; promu lead, elle paraît sans qu'aucune géométrie ne bouge).

## Lot v5.7 — « la bonne information, au bon moment, au bon endroit »

> Huit propositions d'un audit transverse, plus deux retraits qui font jurisprudence. Chacune
> répond à l'un de trois tests : le LIEU (l'information est-elle où le geste a lieu ?), le MOMENT
> (arrive-t-elle avant la décision ?), le GESTE (le plus fréquent est-il le moins cher ?).
> **Rien n'y déduit quoi que ce soit d'un paramètre patient** : toutes font une soustraction
> d'horodatages, un comptage de cases, ou un déplacement d'information déjà présente.

**A113. LA BARRE DE RETOUR AU BLOC COURANT (v5.7).** Trois mécanismes ramenaient au soin, et aucun
ne couvrait le cas le plus fréquent : `landOnBout` ne joue qu'à la RÉENTRÉE dans la fiche,
`ovAdvanceRender` qu'au GESTE D'AVANCEMENT, `cxScrollTo` qu'à l'entrée sur complication. Défiler à
la main pour relire une étape, vérifier une dose plus bas, regarder le journal — et l'on remontait
en cherchant la carte à bordure bleue. `#blkReturn` n'existe que tant que la carte du bloc courant
est **entièrement** hors de la zone utile (sous les couches collantes, au-dessus du dock) et nomme
sa destination (A15 : une excursion sait revenir).
· **PRÉCÉDENT DÉJÀ ACCEPTÉ** : `.sess-start.afloat` (v4.73.0) — transitoire, aucune hauteur au
  flux, critère le plus étroit possible. Elle ne défile JAMAIS toute seule : c'est une porte.
· **UN OBSERVATEUR, PAS UN ÉCOUTEUR DE DÉFILEMENT**, et IDEMPOTENT (on ne réinstalle que si la
  carte a changé) — la fonction tourne à chaque tick, elle doit être gratuite quand rien ne bouge.
· ⚠ **DEUX ALTERNATIVES ÉCARTÉES** : une cinquième touche de dock (A18 le fixe à quatre de largeur
  égale ; une cinquième ferait tomber les étiquettes sous 320 px) ; surcharger « ⤢ Tout voir », qui
  a déjà deux états — un troisième ferait qu'une même touche à une même place ferait trois choses
  selon un état invisible, c'est-à-dire de la mode confusion (FAA).
· ⚠ **LE CLIQUET `pointer-events:none` DE `check-anim` EST PASSÉ DE 18 À 19, et c'est une
  DÉCISION** : la coque couvre toute la largeur et ne doit rien intercepter (seul `.bkr` est
  tapable), sinon elle volerait les taps sur la colonne d'action précisément quand on défile.

**A114. « TERMINER LA SESSION ? » DIT CE QUI RESTE OUVERT (v5.7).** La fenêtre portait le titre, la
durée et les conséquences — **aucun état**. C'est pourtant le seul instant où « il reste deux étapes
vitales non cochées au bloc 3 » sert encore : une seconde plus tard, la session est archivée.
`endSessOpenTxt(R)` est PURE et ne rend que des faits COMPTÉS, deux lignes au plus.
· **« Terminer » reste rouge plein et ACTIF** : une checklist annonce son incomplétude, elle
  n'interdit pas de la quitter (ECAM/QRH). Aucune condition ajoutée à la sortie.
· **NI SCORE, NI POURCENTAGE, NI « CONFORMITÉ »** — le § 2 du dossier de conformité nomme ce
  vocabulaire comme celui à ne jamais employer. Registre ATTENTION en CONTOUR, jamais un aplat (A11).
· ⚠ **ON NE COMPTE QUE LES BLOCS VISITÉS** : une étape vitale d'un bloc où l'on n'est jamais passé
  n'est pas oubliée, elle est HORS CHEMIN — la compter ferait paraître incomplète toute session
  qui a pris une branche. Rien à dire → le bloc n'existe pas.

**A115. UN COMPTEUR DIT « IL Y A », PAS SEULEMENT « À » (v5.7) — ET SON CHIFFRE POUSSE (M1).**
`cnLogTxt` rendait « consigné T+04:12 » : l'instant du dernier incrément. C'est juste, et ce n'est
pas la question qu'on se pose — en réanimation elle est toujours « ça fait combien de temps ? », et
on la calculait de tête sur un chrono qui est à l'autre bout de l'écran. La ligne porte les DEUX :
le T+ se relit (compte rendu, débriefing), le « il y a » décide maintenant.
· **AUCUN SEUIL, AUCUNE COULEUR QUI VARIE** : c'est la même soustraction d'horodatages qu'A81, sur
  les gestes de l'ÉQUIPE. Un seuil serait un JALON, et les jalons sont un champ d'AUTEUR (v5.5.0).
· **VIVANT PAR LE CHEMIN CHIRURGICAL** (`paintCnAgo`, anti-churn) : jamais un re-rendu, donc la
  carte ne change pas de hauteur (A9) — le texte s'écrit sur une ligne DÉJÀ là.
· **M1** : le chiffre pousse au tap (`cnPop`, 130 ms, `transform` seul). L'état est écrit AVANT
  (A68/2), l'animation est REMPLACÉE et jamais mise en file (A68/4 — retrait, calcul forcé,
  repose), et sa règle vit dans le bloc `no-preference`, donc l'inertie est acquise par
  construction. Elle ne joue QUE si la valeur a changé : un re-rendu ne la rejoue pas.

**A116. L'IMMINENCE EST UN ÉTAT, ET LE TRI DES MINUTEURS EST VIVANT (v5.7, deux décisions de
l'auteur, dont une qui rouvre mon arbitrage).**
· ⚠ **UN CONSTAT FAUX D'ABORD, ET IL FAUT LE DIRE** : j'avais annoncé que la capsule « triait déjà
  par temps restant ». Le tri existe (`withRem.sort((a,b)=>a.rem-b.rem)`) mais **il ne gouverne
  qu'une SÉLECTION** : `want` vaut `dueList.slice(0,2)` en voie large — où `dueList` ne retient que
  les ÉCHUS, donc un minuteur qui tourne n'y entre jamais — et `withRem.slice(0,1)` en étroit, qui
  n'en montre qu'un. Rien ne se réordonnait sous l'œil. J'avais lu la ligne, pas ce qu'elle
  alimente. Conséquence : mon premier marquage d'imminence était INERTE au-delà de 780 px.
· **L'IMMINENT ENTRE DANS LA CAPSULE EN VOIE LARGE**, juste derrière les échus. C'est un AJOUT à la
  doctrine v4.23.0 (« le rail porte déjà tous les minuteurs »), pas un oubli qu'on rattrape :
  celle-ci réserve l'exception à l'ALARME, et l'imminence est l'annonce d'une alarme qui va
  survenir — l'argument vaut mot pour mot, le rail DÉFILE. **« +n » ne change pas** : il ne compte
  que les échus non montrés.
· **VINGT SECONDES, ET C'EST UN SEUIL D'AFFICHAGE** (`TM_SOON_MS`) : il ne dit rien du patient et
  ne déclenche rien. Plus court, on voit l'imminence trop tard pour préparer un geste ; plus long,
  elle devient l'état PERMANENT d'un cycle de 2 min — 20 s valent 17 % du cycle réaliste le plus
  court, donc le signal reste rare, donc il signale encore.
· **MÊME REGISTRE QUE L'ÉCHU, UNE INTENSITÉ EN DESSOUS** : `△` + encre ambre, **sans aplat**, sans
  battement — A11 réserve la masse colorée à ce qui exige une action MAINTENANT, et le battement
  est la grammaire de l'alarme, pas de son annonce. Le glyphe survit à l'ellipse (patron du quai).
· **LE TRI DEVIENT VIVANT** (`tmLiveOrder`, une seule fonction pour le rendu ET le tick ; l'alarme,
  puis ce qui tourne par temps restant, puis le reste dans l'ordre de l'AUTEUR). `tmPanelOrder` est
  PURGÉ avec la version précédente (règle 14). **J'avais argumenté l'inverse** (« ne pas déplacer
  une cible sous le doigt ») et l'auteur a rouvert la décision : c'est la sienne.
· **CE QUI RESTE DE L'OBJECTION EST LE GARDE, ET IL EST DEVENU MEILLEUR** (demande de l'auteur :
  « un tout petit temps de latence pour comprendre qu'on a bien touché le bon minuteur »). Le geste
  le plus fréquent sur une carte est « Relancer », qui remet le temps restant au MAXIMUM : la carte
  tombait au bas de la liste À L'INSTANT où on venait de la toucher, et son accusé disparaissait
  sous le doigt. Le tri attend la fin du geste **plus 1,2 s** (`TM_HOLD_MS`) — assez pour lire la
  réponse de la carte, sous la seconde et demie à partir de laquelle un mouvement différé
  ressemble à un raté. Le focus clavier tient la liste immobile comme un doigt.
· **NON BLOQUANT PAR CONSTRUCTION** : le délai ne suspend QUE la réorganisation. Les minuteurs
  courent, les valeurs se peignent, les boutons répondent, la capsule annonce. Au pire l'ordre de
  la liste est en retard de 1,2 s sur celui de la capsule, qui, elle, ne bouge pas.
· **LE MOUVEMENT EST UN FLIP EN `transform` PUR** (180 ms) : on mesure avant, on réordonne le DOM,
  on repose chaque carte par une translation, la transition la ramène. L'ordre du DOM est juste dès
  la première image — un lecteur d'écran ne voit jamais l'état intermédiaire. ⚠ La translation est
  **divisée par `zoomF()`** (règle 10 : `getBoundingClientRect` rend des px VISUELS). ⚠ On ne
  réordonne que des cartes CONTIGUËS, via un marqueur : le conteneur porte aussi des rangées
  compactes et des compteurs, qu'un `appendChild` renverrait à la fin.
· ⚠ **POURQUOI C'ÉTAIT « MOCHE » DANS LE VOLET, et ce n'était pas la durée** (signalé à l'usage) :
  une carte y a un fond TRANSLUCIDE (`--sys-2`, blanc à 7 %). Pendant le croisement, deux cartes se
  superposent et **leurs deux voiles s'additionnent** — une tache plus claire traverse le volet et
  les filets se croisent. Sur la matière de TRAVAIL le fond est opaque, d'où un mouvement propre là
  et sale ici. Le temps du mouvement, la carte prend un fond OPAQUE (`--sys-hi`) et passe au-dessus.
· **LE VOLET S'OUVRE SUR LE MINUTEUR QUI SONNE** : l'ordre est calculé au RENDU, donc le volet
  ouvert ne se réordonne pas au tick — c'est le tri vivant qui s'en charge, avec son garde.

**A117. LE RETOUR D'INTERRUPTION RESTITUE LA CONSCIENCE DE SITUATION (v5.7).** Vérifié avant
d'écrire : **zéro occurrence** d'un « temps depuis le dernier geste » dans le fichier. Les cinq
écouteurs de `visibilitychange` persistaient, reprenaient l'audio, redemandaient la veille — aucun
ne disait à quelqu'un qui revient depuis combien de temps il n'était plus là. C'est pourtant le cas
nominal : on pose le téléphone, on intube, on transporte. Une ligne, en tête de la carte du bloc
courant : « ⏱ Reprise — dernier geste il y a 6:12 ».
· **L'HORODATAGE VIT DANS `persistLive`, ET NULLE PART AILLEURS** — le point d'étranglement de
  toute mutation de session (c'est déjà ce qui donne au partage un seul crochet plutôt que soixante
  verbes). Un geste ajouté demain sera horodaté sans qu'on y pense.
· **IL N'ENTRE PAS DANS L'INSTANTANÉ** : après un rechargement il n'y a plus d'interruption à
  annoncer (les minuteurs disent déjà « arrêté depuis », A81). Rien ne change au format ni à ce
  qui voyage.
· **A9** : revenir au premier plan EST un geste de l'utilisateur, la ligne a donc le droit de
  paraître ; et elle ne pousse rien d'autre qu'elle-même (elle s'insère en TÊTE de la carte, jamais
  entre deux étapes). **Deux minutes est un seuil d'AFFICHAGE**, qui évite d'annoncer une absence
  de quinze secondes. Le texte est FIGÉ à l'instant du retour : c'est la durée de l'interruption
  qu'on annonce, pas un second chronomètre.
· **ELLE S'EFFACE AU GESTE SUIVANT**, jamais après un délai — c'est le geste qui la périme.

**A118. CE QUE LA FICHE EMBARQUE SE DIT AVANT QU'ON ENTRE (v5.7).** Mesuré : `preStartHtml` (« Ce
qui démarrera ») ne se rend que dans le RAIL, donc à partir de 780 px ; en voie ÉTROITE le panneau
n'existe que dans le volet du quai, qui exige une session vive (v5.4.2), et la capsule n'existe pas
non plus avant le premier geste. **Sur la cible principale déclarée**, un minuteur à cycles de 2 min
écrit par l'auteur était donc invisible tant qu'on n'avait pas démarré — et le néophyte
chronométrait de tête, ce que l'aide existait pour éviter. Une LIGNE dérivée (`carryLineHtml`,
pure) : « 6 blocs · 2 minuteurs · 1 complication déclarée ».
· **PAS UNE SECONDE COPIE DU DÉTAIL** : le rail garde sa liste, l'étroit reçoit le compte.
· **RIEN À DIRE → AUCUNE LIGNE** : un panneau qui affirmerait « 0 minuteur » serait le bruit que ce
  dossier refuse partout. Aucun champ nouveau, aucune migration.

**A119. UNE AIDE RÉVISÉE DEPUIS VOTRE DERNIER PASSAGE LE DIT (v5.7).** `aidRev` existe depuis le lot
T1 et ne servait qu'au compte rendu. Or dans une bibliothèque PARTAGÉE, un collègue révise une aide
qu'on croit connaître par cœur, et l'on déroule de mémoire. `revisedSinceTxt(f,sessions)` est PURE.
· **AVANT le geste d'entrée, jamais pendant le soin** (la rangée de méta est déjà masquée en
  session depuis la v4.31.0). **Elle ne conditionne rien** : « Confirmé — démarrer » ne bouge pas.
· **ELLE NE DIT PAS CE QUI A CHANGÉ** — le dire exigerait de rendre un diff clinique à l'écran,
  donc de résumer une modification de dose. « Versions » est dans le menu ⋯ pour cela.
· **RIEN SUR UNE AIDE JAMAIS DÉROULÉE** : il n'y a alors pas de « dernier passage », et « révisée »
  serait du bruit. C'est le DERNIER passage qui compte, pas le premier trouvé.

**A120. LE COMPTE RENDU DONNE L'ÉCART, ET RIEN D'AUTRE (v5.7, décision de l'auteur : « juste
l'écart sans analyse »).** Au débriefing la question est presque toujours « combien de temps entre
les deux ? », et on la soustrayait à la main. `evDeltas` (pure) ajoute une colonne « Écart ».
· ⚠ **LA LIGNE À NE PAS FRANCHIR EST PROCHE, ET C'EST POUR ÇA QUE LA COLONNE EST NUE** : un écart
  BRUT est un fait. Une MOYENNE, un « intervalle cible », une couleur qui vire au rouge au-delà
  d'une valeur, ou le mot « conformité » feraient basculer le document du côté de l'ÉVALUATION PAR
  LE LOGICIEL — ce que le § 2 nomme comme le vocabulaire à ne jamais employer.
· **L'ÉCART EST PAR OBJET** : « 3:56 » n'a de sens qu'entre deux doses du MÊME produit ; un repère
  libre n'ouvre pas de série. **Un repère ANNULÉ ne compte pas et ne coupe pas la série** : il
  reste dans la chronologie (une décision a bien eu lieu), l'écart se mesure entre les gestes qui
  TIENNENT.

**A121. DEUX PROPOSITIONS RETIRÉES APRÈS VÉRIFICATION — ET C'EST LA MÊME LEÇON (v5.7).**
· **« Télécharger les documents des aides épinglées »** : `Sync._syncAttachments()` étape 4 le fait
  DÉJÀ, et son commentaire le dit — « télécharge en ARRIÈRE-PLAN tout document référencé manquant
  (hors-ligne d'urgence : systématique) ». La proposition aurait RESTREINT aux épinglées une
  garantie volontairement universelle : une régression. J'avais vérifié la présence des SURFACES
  (la ligne d'A82, son bouton) sans vérifier le MÉCANISME derrière — le bouton n'est pas le chemin
  nominal, c'est le filet.
· **« Fondre le virage au vert de Continuer »** : `ovAfterCheck` fait déjà tout le changement
  d'état (`classList.toggle('okay',all)`, libellé remplacé, `aria-disabled` retiré). Il ne restait
  que 140 ms de fondu — et le LIBELLÉ bascule au même instant : on obtiendrait une couleur qui
  s'attarde sous des mots qui ont déjà sauté, **moins** cohérent que l'instantané.
· **LA LEÇON EST A97, MOT POUR MOT** : « une proposition juste peut porter sur un manque qui
  n'existe plus : on vérifie avant d'implémenter ». Les deux constats sont venus de l'auteur, pas
  de moi. **QUESTION OUVERTE, laissée telle** : le téléchargement de fond est NON BORNÉ (ni volume,
  ni égard pour une connexion mesurée) — le borner affaiblirait la garantie hors-ligne, c'est un
  arbitrage à prendre, pas un défaut à corriger.

**A122. LA RELECTURE DEVIENT FORCE DE PROPOSITION (v5.7, Q1).** Vérifié avant d'écrire : les six
détections de `reviewNotes`/`reviewNotesProto` sont TOUTES des manques — titre absent, « à
compléter » résiduel, aucune source, chapeau trop long, bloc de plus de sept étapes, challenge trop
long. Aucune ne disait jamais « votre texte décrit un cycle : voulez-vous le minuteur qui va
avec ? » Or c'est là que tout se joue pour un néophyte-AUTEUR : il écrit « renouveler toutes les
3 min » EN TEXTE, et n'apprendra jamais que l'application sait armer un minuteur à cycles, poser un
compteur ou marquer un memory item. La fiche qu'il publie n'emploie alors qu'une part du produit —
et c'est EN CRISE que la différence se paie. `reviewOffers(f)` est PURE ; le volet gagne un SECOND
registre, séparé des manques par un filet et son intertitre (un défaut et une occasion ne se lisent
pas de la même façon, et les mêler ferait passer l'occasion pour un reproche).
· **TROIS DÉTECTEURS, ET LE NOMBRE VIENT DE LA PHRASE DE L'AUTEUR, JAMAIS D'UN BARÈME** : une
  cadence (« toutes les 3 min », « à 5 min », « q4h ») → minuteur à cycles, période PRÉ-REMPLIE ;
  « renouveler / seconde dose / nouveau choc » → compteur ; une étape vitale alors qu'aucune ★
  n'existe → memory item. C'est de la lecture de TEXTE, à froid, dans l'éditeur — hors session,
  hors patient. Aucun seuil clinique n'est inventé : c'est l'interdit que le prompt IA porte déjà.
· **RIEN N'EST CRÉÉ AUTOMATIQUEMENT**, jamais : une proposition est une rangée avec un bouton, et
  le texte de l'auteur n'est PAS réécrit — l'objet s'ajoute, la phrase reste.
· **LA PROPOSITION N'INVENTE PAS DE NOM** (A85, A99) : le compteur naît SANS libellé, et c'est le ✎
  de sa carte qui le nomme. Deviner un mot serait la dégénérescence de « PA 2 » sous un autre visage.
· **UN SEUL CHEMIN DE CRÉATION** : accepter passe par `edAdd`, qui gagne un paramètre `pre`
  facultatif. Un second créateur divergerait au premier réglage. Seul ★ n'y passe pas — il ne CRÉE
  rien, il marque un item qui existe.
· **ELLES SE TAISENT DÈS QUE L'OBJET EXISTE** (aucun drapeau à tenir) et **un refus ne revient pas
  de la séance** (`state.edOffNo`, transitoire comme `state.edGrab` : c'est un geste, pas un état
  du brouillon — le graver dans le modèle ajouterait un champ pour mémoriser un NON).
· **LE VOLET EXISTE MÊME SANS DÉFAUT** : une fiche sans remarque est précisément celle à qui il
  reste le plus à apprendre.
· ⚠ **DEUX DÉFAUTS TROUVÉS PAR LES TÉMOINS, ET LE PREMIER EST UN PIÈGE DE REGEX GÉNÉRAL** :
  `\b` devant un caractère ACCENTUÉ ne matche JAMAIS — en JS, `à` n'est pas un caractère de mot,
  donc `\bà` est mort-né et « Renouveler à 5 min » passait au travers. Et le registre d'une étape
  vit dans la CHAÎNE (préfixe « ⚠ ») autant que dans `level` : `migrate` ne dérive pas le niveau du
  préfixe, `stepIsCrit` est LA source de vérité — un détecteur qui ne lit que `level` est aveugle
  au format historique. Corollaire de fixture : un témoin qui poserait ★ en filtrant sur
  `level===3` ne poserait rien et mesurerait le vide.
· **CE QUI N'EST PAS FAIT, ET POURQUOI** : trois autres détecteurs étaient proposés (« si échec »
  → bloc de décision, « en cas de … » → complication, une dose écrite sans repère posologique).
  Les deux premiers exigent de DÉCOUPER des étapes existantes, c'est-à-dire de réécrire le texte de
  l'auteur — exactement ce que la règle ci-dessus interdit. À rouvrir séparément, avec un dessin
  qui ne touche pas à ses phrases.

**A123. LES TÉMOINS DYNAMIQUES DE P1 ET Q2 — ET LES DEUX QUI N'ONT PAS DE CAS À RENCONTRER
(v5.7).** Les fonctions pures du lot ont 47 témoins ; le CÂBLAGE, lui, n'était mesuré par rien.
Deux sections entrent dans `audit-doctrine` (`P1 · le retour au bloc courant`, `Q2 · la reprise
après interruption`), vérifiées CAPABLES D'ÉCHOUER — défauts réintroduits → 7 rouges, fichier
restauré à l'octet.
· **LE PRÉDICAT DU TÉMOIN EST CELUI DE L'APPLICATION, PAS UN AUTRE** (A109/4, rejouée ici) : ma
  première version lisait « hors de vue » en `r.bottom<0||r.top>innerHeight` alors que la barre se
  règle sur la ZONE UTILE — sous les couches collantes, au-dessus du dock. Le témoin rougissait sur
  un comportement juste, la carte étant bien hors de la zone utile mais dépassant encore derrière
  le chrome. Deux définitions concurrentes d'un même régime : la divergence que ce dépôt a déjà
  payée cinq fois.
· **UN TÉMOIN NE DOIT JAMAIS POUVOIR PENDRE** (A89) : `page.click('.bkr')` attend 30 s quand la
  barre n'est pas là — c'est-à-dire précisément quand le défaut couvert est présent — et ce blocage
  emporte la tranche entière, sans un mot. On prend la poignée (`page.$`), on la teste, et
  l'absence devient un rouge lisible.
· **CE QUE Q2 MESURE EN PROPRE** : la ligne ne paraît PAS sous le seuil d'affichage, elle paraît
  au-delà, elle dit « il y a m:ss », elle ne déplace pas la page, elle ne s'efface PAS toute seule
  avec le temps, et elle s'efface AU GESTE. C'est le geste qui la périme, jamais une horloge.
· **LES DEUX TROUS SONT FERMÉS DEPUIS (v5.7), ET LE CHEMIN EST LA LEÇON** : on a d'abord réparé
  le DÉCOR, ensuite écrit le témoin. `P4b · le tri vivant des minuteurs` mesure l'ordre par temps
  restant, le marquage d'imminence sur la CARTE (glyphe + mot, jamais la couleur seule), le garde
  du doigt posé et le délai de grâce qui le suit ; `Q1 · les propositions de relecture` mesure que
  la rangée paraît, que son tap crée l'objet AVEC la période lue dans la phrase, qu'elle se tait
  ensuite, et qu'un refus ne revient pas de la séance sans rien créer. Vérifiés capables d'échouer
  (tri neutralisé et `pre` ignoré → 2 rouges, fichier restauré à l'octet).
· ⚠ **CE QUI A DÛ ÊTRE FAIT AVANT, ET QUI EST LA VRAIE LEÇON DE CE LOT.**
  **P4b (le réordonnancement vivant)** : il ne s'observe qu'à partir de DEUX minuteurs déclarés
  dans la même liste, or aucune fiche d'exemple n'en déclare deux — et un minuteur ad hoc se rend
  en rangée compacte (`minis`), jamais en `.tmcard`. Le cas n'existe donc pas dans le décor.
  **LE CORRECTIF ÉTAIT DANS LE DÉCOR, PAS DANS LE TÉMOIN** : la fiche ACR porte désormais un
  SECOND minuteur déclaré (« Adrénaline (cycle) », 4 min) — ce que le lot T13 recommandait déjà
  (« les deux fiches d'exemple exercent la doctrine qu'elles enseignent »), et le second est
  clinique, pas décoratif : deux cadences (2 min / 4 min) sont précisément le cas où l'ordre par
  temps restant change sous l'œil. Écrire la section AVANT aurait produit un vert qui ne mesure
  rien.
  **Un trou NOMMÉ vaut mieux qu'un vert obtenu sur un cas qui n'existe pas** — c'est la leçon que
  ce fichier redit le plus souvent.

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
  #c43d34 = BORDURES des cartes/bandeaux rouges ; PALETTE « Urgences » #b23240 (ex-#b6382f,
  re-résolution OKLCH v5.1.1 — écarté de --critical-bd, dont il n'était qu'à dE_OK 3,1) = couleur de
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
  une normale — la coche verte, l'encre douce et la graisse suffisent ; **NI OPACITÉ NI BARRÉ,
  cf. « UNE ÉTAPE COCHÉE RESTE LISIBLE » plus bas — la formulation d'origine disait « texte grisé
  barré + opacité » et c'est elle qui produisait 1,95:1** ; une étape signalée
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
  **aperçu du brouillon** (bouton « ▶ Essayer » de la barre ; à ≥ 1000 px la colonne droite porte
  l'ALGORITHME, cf. « LA COLONNE DE DROITE PORTE L'ALGORITHME » plus bas) via `state.previewFrom`.
  Une session d'ESSAI y démarre depuis la v4.72.0 (K5), marquée `essai`, et ne laisse rien.
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
- **Parcours de soin (v4.4.0 ; ⚠ ROUVERT EN SESSION PAR LE LOT T5, v5.0.0 — lire « EN SESSION,
  L'ACTION PASSE DEVANT L'ORIENTATION » plus bas : le rail décrit ci-dessous vaut HORS session ;
  une fois le soin démarré il cesse d'être l'ossature et perd sa numérotation)** : la vue lecture
  d'une fiche est structurée par un rail vertical
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
  **~~Mode lecteur~~ — SURFACE RETIRÉE AU LOT T14 (v5.0.0).** Le paragraphe qui suit décrit ce qui
  a existé de la v4.11.0 à la v4.79.0 et n'a plus d'équivalent dans le code ; il est conservé parce
  qu'il porte le raisonnement challenge-réponse, qui lui reste vrai. Ce que la surface portait vit
  désormais dans la carte de bloc : pilule de réponse attendue, passe Do-Verify et cochage sont les
  mêmes verbes, dans la même liste (I4, v4.62.0). ~~(binôme, plein écran `#readerMode`) : un
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
  non confirmées). Harnais `scripts/audit-retour.mjs`.
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
- **JALONS DE BOUCLE (v5.5.0 — P1+P2+P3+P4, audit « déroulé de l'algorithme », demande
  utilisateur : « au bout de 3 CEE se poser la question d'une FV réfractaire, puis l'analyse
  reste toutes les 2 minutes »)** : le déroulé en boucle était couvert (↺, ×n, convergence) mais
  RIEN ne savait dire un contenu qui ÉVOLUE au k-ième passage ou au n-ième choc — l'auteur
  n'avait que du texte statique (bruit avant le seuil) ou une excursion dont l'ENTRÉE reposait
  sur la mémoire du compte, l'inverse de la doctrine QRH, alors que le runtime CONNAÎT les deux
  nombres (`passInfo`, `Runtime.counters`). **`b.milestones` : [{at:'pass'|'count', n, counter,
  text, go}]**, facultatif, ≤ 3/bloc, texte ≤ 140 ; assaini dans `migrate` APRÈS compteurs et
  excursions (seul point où leurs ids finaux existent) — compteur non résolu → rangée REJETÉE
  (un jalon qui ne mesure pas est mort), `go` hors des cibles d'excursion DÉCLARÉES → retiré.
  **Modèle ECL sur la carte du BOUT** (`jalonsHtml`, blocs do ET décisions — le cas canonique est
  une décision) : la ligne existe dès le premier passage, estompée, **condition en toutes
  lettres + progression vivante** (« Chocs délivrés 2/3 » en mono) ; au seuil elle passe au
  registre ATTENTION (paire `--verify`/`--verify-soft` des étapes △, déjà auditée) — **ambre,
  jamais rouge** (« c'est là qu'on se trompe »), **≥ et jamais ==** (un fait ne s'acquitte pas,
  doctrine « Consigné »), **rien ne se déclenche** (règle 11 : pas de son, pas de saut — mesuré
  Δ=0 px au franchissement ; l'annonce passe par `#srLive`). Repeinture CHIRURGICALE par
  `paintJalons()` appelée dans **`setCounterVal`, AVANT le garde `!el`** : en étroit le panneau
  des compteurs peut être ABSENT du DOM (volet fermé) pendant qu'un évènement DISTANT
  incrémente — la valeur n'a nulle part où s'écrire, le jalon, lui, est sur la carte et doit
  suivre. **P2 — le renvoi `go` réutilise `data-cxgo`**, donc `cxEnter`, ses gardes et son
  retour prévu (↩ Reprendre) : AUCUNE navigation nouvelle ; le bouton n'est TAPABLE qu'au seuil
  (avant, la rangée ⚡ constante du pied suffit — deux moments, pas une duplication : l'action au
  pied de l'alerte est la règle ECAM d'`onDue`). **Les vues de structure l'annoncent d'emblée**
  (« rien de caché qui ne s'annonce ») : Échelle = marqueur △ (FORME neutre — colonne désaturée)
  + détail déplié `.pl-jll` ; Parcours `.pc-jl` et Statique `.sv-jl`, inertes, condition en
  toutes lettres. **P4** : `cycleHint`/`cycleTxt` — quand la fiche déclare **UN SEUL** minuteur à
  cycles (interval+autoloop), sa période annote les renvois de boucle TEXTUELS (« ↺ reprendre à
  2 · toutes les 2 min », statique `linkH` + pied du parcours) ; à deux, rien (annoter serait
  une devinette), et les renvois COMPACTS de l'Échelle (« ↺1 » mono) restent nus (largeur
  comptée v4.55.3). Éditeur : rangées par bloc (`jalonEditor`, condition · seuil · compteur ·
  renvoi vers une excursion déclarée), porte d'ajout masquée au plafond ; bascule vers 'count'
  pré-pointe le premier compteur (on ne fabrique jamais l'état que migrate rejette). **La fiche
  d'exemple ACR exerce le mécanisme** (lot T13) : excursion « FV réfractaire », bloc hors
  chaîne, jalon `Chocs ≥ 3`. Le prompt IA documente `milestones` et **interdit d'inventer un
  seuil clinique** (vérifié par `audit-prompt`) ; `SHARE_KEEP` couvre déjà (`blocks` voyage
  entier, comme `items` — schema.sql inchangé). **Qualification réglementaire écrite AVANT le
  développement** (`docs/deploiement-et-conformite.md` § 2, « Le cas des jalons de boucle ») :
  règle d'auteur affichée au moment défini, aucun paramètre patient (les compteurs comptent des
  GESTES de l'équipe) — la ligne à ne pas franchir y est nommée (paramètre patient, seuil déduit
  par le logiciel, déclenchement autonome). Témoins : section doctrine « QRH · jalons de
  boucle » (construit son cas sur l'ACR, vérifiée CAPABLE D'ÉCHOUER — activation neutralisée →
  4 rouges, fichier restauré à l'octet), 17 témoins purs dans `tests.html`, 2 dans
  `audit-prompt`.
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
  complication glisse en place (`.ov-block.cx-return`). Harnais : `scripts/audit-retour.mjs`.
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
- **UNE RÉFÉRENCE A DES CASES COCHABLES, ET ELLES NE S'ENREGISTRENT PAS — C'EST VOULU (rappel
  explicite, v5.0.0)** : une référence n'est pas une session. Les coches servent à ne pas perdre sa
  place pendant qu'on la parcourt ; elles vivent dans `state.protoTasks`, sont remises à zéro à
  chaque `openProtocolRead`, et **ne touchent AUCUN champ du modèle** (l'export est strictement
  inchangé — un client antérieur affiche « [ ] tâche » en item de liste, dégradation lisible).
  Sortir de la page les efface, et c'est la propriété qui rend le geste sans conséquence : rien à
  nettoyer, rien à synchroniser, rien qui puisse être pris pour une trace de soin. **Ce qui garde
  une trace, ce sont les FICHES** — sessions, journal, compte rendu. Confondre les deux ferait
  croire qu'une référence cochée enregistre quelque chose.
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
- **LE DÉMARRAGE RESTE ATTEIGNABLE — UNE ZONE FIXE EN BAS, BORNÉE (v4.73.0, proposition
  utilisateur : « et si “confirmé — démarrer la session” était sticky quand on ne l'atteint pas
  encore et qu'on doit scroller car c'est long ? »)** : sur une fiche à critères longs, le bouton
  naît SOUS le pli — on lit, on défile, et la condition d'entrée QRH n'est plus à portée de pouce.
  `.sess-start.afloat` détache alors le bouton au bas de l'écran. **CE QUI REND CETTE ZONE FIXE
  ADMISSIBLE** malgré SPEC §5 (« en crise, une seule zone fixe, et en HAUT ») — trois bornes, toutes
  vérifiables : elle n'existe qu'AVANT la première action (donc jamais pendant un soin, là où la
  règle protège la colonne d'action), elle est TRANSITOIRE (elle s'efface au démarrage comme au
  retour du bouton à l'écran), et elle ne prend **aucune hauteur au flux** — `min-height` garde la
  place exacte du bouton sorti, donc rien ne se décale au basculement (mesuré : boîte 50 px avant
  comme après). **Critère le plus étroit possible** : le bouton doit être ENTIÈREMENT sous le pli ;
  s'il est passé AU-DESSUS, on ne le rappelle pas — il n'a pas été manqué, il a été dépassé, et une
  barre qui reparaîtrait en remontant serait un mouvement qu'aucun geste n'explique. **Sous 780 px
  seulement** (c'est là que le problème existe) et **jamais en STATIQUE**, où le bouton est une
  RANGÉE du carrelage : l'extraire du flux ouvrirait un trou dans la grille.
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
- **PLACARD DE L'INVITÉ (v4.55.4, demande utilisateur ; l'hôte n'a PLUS d'étiquette depuis la
  v4.70.1 — cf. « DEUX ANNONCIATEURS, DEUX OFFICES »)** : il lisait « ■ Mode crise », exactement
  ce que lisait alors l'hôte, alors que sa situation est autre — il SUIT une session qu'il ne conduit pas et
  qui peut s'arrêter sans lui. Le bandeau-titre porte donc « **▪ Vous suivez** » et une hachure
  BLEUE, l'en-tête relayant « ▪ Suivi » au pixel où le titre passe dessous. **Même mécanique que le
  placard d'exercice, au trait près** (`::before` en fondu, relais au défilement, enfants en
  `z-index:1`) : rien de neuf à inventer, donc rien de neuf à casser — et **coût nul en hauteur**,
  seule condition qui vaille là où `#crisisCtrl` n'a que 2,1 px de marge à 320 px. **L'EXERCICE
  GARDE LA PRIORITÉ** et ce n'est pas négociable : « ceci est une répétition » prime sur « vous
  suivez » — le premier protège d'une méprise clinique, le second est une information de rôle que
  le quai porte en permanence de toute façon.
- **UN PLACARD EST UN PLACARD, ET SA HACHURE TRAVERSE (v5.0.5, signalé à l'usage)** : il est porté
  par DEUX boîtes — l'en-tête et le bandeau —, dont chacune générait son dégradé depuis SON propre
  coin, si bien que les rayures se brisaient net à la frontière. Chaque hachure appartient à SA
  barre et l'on met la seconde en phase par un décalage MESURÉ (`background-position` de la valeur
  de `--hdr-h` : les deux boîtes de rembourrage ont le même bord gauche, et un écart vertical qui
  vaut exactement la hauteur de l'en-tête). Un décalage PAVE, or un dégradé répétitif se dimensionne
  sur sa boîte et sa phase s'ancre à son coin BAS-DROIT : la tuile est donc CARRÉE
  (`background-size:31px`) et ses bandes s'expriment en **pourcentage de la ligne de dégradé** —
  une période de 50 % en met deux par tuile exactement, ce qui la rend raccordable à n'importe
  quelle taille sans jamais écrire √2 dans une feuille de style. Contrepartie assumée : la phase
  n'est commune qu'au REPOS ; en défilant, chaque texture suit sa barre, ce que fait toute texture
  peinte sur un objet. **⚠ Une variante de hachure s'écrit en `background-image`**, jamais avec le
  raccourci `background`, qui remettrait taille et position à leur défaut — et ne casserait QUE ce
  placard-là, donc en silence.
  **⚠ ET LA LEÇON DE MÉTHODE, PAYÉE UNE VERSION** : la première solution était
  `background-attachment:fixed` — l'ancrage au viewport, qui est le raisonnement JUSTE (deux boîtes
  dont l'écart change à chaque frame ne partagent une phase que par un repère tiers), vert aux deux
  moteurs en headless, et **faux sur l'appareil** : WebKit ne repeint pas un fond fixé en même temps
  qu'il défile, la texture retarde puis se recale. Même famille que le rebond du rail A→Z et que le
  dossier « bande basse iOS » : **ce que le compositeur fait du rendu n'est visible dans AUCUNE
  mesure de la page**, donc un harnais vert ne prouve rien sur cette classe de propriétés — on
  n'ancre jamais à un repère qu'on ne contrôle pas. Corollaire pour les témoins : mesurer la
  PROPRIÉTÉ (les deux grilles partent du même point) et non le MÉCANISME du jour, sinon le témoin
  rougit le jour où l'on doit en changer.
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
- **UNE ÉTAPE COCHÉE RESTE LISIBLE — NI OPACITÉ NI BARRÉ (v5.0.0, audit design A1-1 ; RÈGLE
  ROUVERTE, et c'était la SEULE violation AA du fichier)** : `ol.steps li.done{opacity:.6}` plus
  `--done-ink` et `line-through` composaient un texte à **2,55:1 en clair et 1,95:1 en SOMBRE**,
  quand l'étape non cochée juste en dessous mesure 17,36 / 16,65 — un facteur 7 à 9 entre deux
  lignes voisines, sur **l'état le plus fréquent de toute l'application** (en réanimation, la
  moitié des lignes à l'écran sont cochées). L'exemption WCAG « composant inactif » ne joue PAS :
  une étape cochée reste un `role="checkbox"` `tabindex="0"` décochable.
  **TROIS SOURCES CONVERGENTES, ET LA TROISIÈME EST CE FICHIER.** (a) **ECAM** : une action
  accomplie passe au vert et RESTE pleinement lisible — le decluttering retire ce qui n'est plus
  PERTINENT, il ne rend pas illisible ce qu'on vient de faire, parce que la relecture est le
  mécanisme de reprise. (b) **AC 120-71B §5.4 + Degani & Wiener** : « perdre sa place est un mode
  de défaillance premier », que ce dossier cite déjà pour justifier l'abandon du un-item-à-la-fois
  (v4.28.0) — une ligne à 1,95:1 barrée EST une ligne perdue. (c) **LA CONTRADICTION INTERNE** :
  `.sv-stp li.done` porte le commentaire « coché = ✓ vert, texte JAMAIS barré (relecture) » et les
  listes cochables des références disent « on doit pouvoir relire » ; la vue de SOIN, seule des
  trois à compter en crise, était la seule à barrer ET estomper. Deux vocabulaires pour une idée,
  ce qu'AC 120-71B §5.5 proscrit.
  APRÈS : **5,93:1 en clair, 11,15:1 en sombre**. Rien n'est perdu — la distinction fait/à faire
  garde TROIS canaux (case verte pleine, graisse 400 contre 600, encre douce), donc la couleur
  n'est jamais seule (règle 8). L'exception `@media print` qui remettait `opacity:1` et
  `text-decoration:none` **a disparu avec sa cause** : l'écran et le papier disent la même chose.
  `--done-ink` est PURGÉ (règle 14) — il valait exactement `--ink-soft` en clair, et 3,11:1 en
  sombre sur les listes cochables des références, où il portait la même violation.
- **⚠ LE HARNAIS D'ACCESSIBILITÉ IGNORAIT `opacity` — ET C'EST POUR ÇA QUE 443 CONTRÔLES ÉTAIENT
  VERTS SUR UNE VIOLATION (v5.0.0, audit design A1-2)** : la sonde composait bien l'alpha de la
  COULEUR (`rgba(…)`) mais lisait `getComputedStyle().color` sans tenir compte de la propriété
  `opacity` de l'élément ni de ses ancêtres. Or `opacity` compose le rendu exactement comme un
  alpha : un texte réellement peint à 2,55:1 était mesuré à 5,93 et déclaré conforme, **partout
  dans l'application à la fois**. Le défaut n'était donc pas qu'il manquait un état à la liste :
  **l'instrument ne POUVAIT PAS le voir**, et ajouter l'état sans corriger la sonde n'aurait
  produit qu'un vert de plus, et un vert faux. On multiplie désormais les opacités jusqu'à la
  racine avant de composer.
  **CE QUE LA CORRECTION A RÉVÉLÉ IMMÉDIATEMENT**, et qui était là depuis longtemps : « MAINTENIR »
  (`.tmr-hint`), l'affordance qui dit qu'une remise à zéro exige un appui prolongé, était à 11 px
  avec `opacity:.65` — **2,81:1**. L'information la plus utile du bouton était la moins lisible.
  Corrigée par l'ENCRE (`--ink-soft`), jamais par l'effacement : c'est la règle déjà écrite pour
  `--soft`.
  **CINQ ÉTATS D'ITEM ENTRENT DANS LE HARNAIS** (étape cochée, trace do-verify, bloc hors chemin,
  contrôles fermés du scribe, plus les cinq états de surface d'avant), chacun avec son `must:` qui
  échoue bruyamment si l'état ne se construit pas — ce qui est arrivé à l'écriture, et c'est ce
  qu'on veut. **Vérifié capable d'échouer** : défaut réintroduit → rouge sur les deux moteurs,
  fichier restauré à l'octet. 443 → 499 contrôles.
- **LE PREMIER GARDE-FOU DE DISTRIBUTION : LE QUOTA DU PLANCHER (v5.0.0, audit design A5-1)** —
  les six échelles fermées répondent toutes à « cette valeur est-elle ADMISE ? » ; aucune ne
  répondait à « **est-elle TROP UTILISÉE ?** ». C'est par là que le plancher typographique a
  glissé : **173 déclarations à 11 px sur ~520**, soit la taille la plus utilisée de toute la
  feuille, devant 13,5 px (138) et 12 px (107) — 81 % des corps à 13,5 px ou moins, et **14 des 26
  éléments visibles de l'accueil au plancher**. Chaque déclaration prise isolément était
  parfaitement légale, donc rien ne pouvait le voir. Or un plancher est une EXCEPTION MOTIVÉE :
  employé 173 fois, ce n'est plus un plancher, c'est le corps de texte du produit.
  `check-type` porte désormais un **CLIQUET** (`PLANCHER_MAX`), posé au niveau ATTEINT : la valeur
  ne peut que descendre, l'augmenter est un échec bruyant, la baisser est un geste explicite. Même
  dispositif qu'`audit-budget` pour la répartition d'écran. **⚠ CE QU'IL NE MESURE PAS** : une
  DÉCLARATION n'est pas un ÉLÉMENT À L'ÉCRAN — c'est un proxy statique, il empêche la dérive de
  s'aggraver, il ne prouve pas qu'elle a cessé. Vérifié capable d'échouer.
- **L'ACCUEIL — LA MARQUE NE DOMINE PLUS LE CONTENU (v5.0.0, audit design A3-1)** : mesuré à
  390 × 844, **12 éléments de texte et 439 px sur 844 (52 % de l'écran) précédaient le premier
  contenu clinique**, et le plus gros glyphe après la marque était un **« × » de fermeture à
  19 px** quand le titre d'une aide vitale faisait 15,5. L'importance visuelle était inversement
  proportionnelle à l'importance réelle — sous stress on ne lit pas, on scanne les masses, et la
  masse dominante était le nom du logiciel, information de valeur nulle pour qui vient de
  l'ouvrir. C'est le diagnostic qui a déclenché les lots T2–T5 sur la vue LECTURE, jamais posé sur
  l'écran qu'on ouvre EN PREMIER.
  Trois gestes, aucun composant nouveau : **marque 20/18 → 16,5 px** (le palier de `#brandTitle`,
  son relais dans la barre — le même libellé cesse de changer de corps selon la vue, comme il a
  cessé de changer de police en v4.73.0 ; l'abaissement à 18 px sous 430 px est PURGÉ, il ferait
  désormais GRANDIR le mot) ; **titre de rangée 15,5 → 16,5** ; **méta 11 → 12** (le principal
  gisement de plancher de l'accueil) ; **croix de bandeau 19 → 15,5**, cible inchangée.
  **⚠ LA TUILE RESTE À 15,5, ET CE N'EST PAS UNE INCOHÉRENCE** (montée puis REVENUE, signalée à
  l'usage) : la RANGÉE a un clamp à 2 lignes dans une boîte FIXE de 71 px où la mesure laisse 6 à
  7 px ; la TUILE a un clamp à 3 lignes et une hauteur FLUIDE — mesuré, 16,5 px la portait de 72 à
  **107 px** et, les tuiles étant des éléments de grille, la rangée ENTIÈRE suivait. C'est la
  CONTRAINTE qui décide du palier. Et le constat d'audit ne s'y applique pas : dans une tuile, le
  titre est déjà l'élément dominant de sa carte.
- **⚠ UN `-webkit-line-clamp` SUR UN `<button>` NE S'APPLIQUE PAS — ET IL ÉTAIT INERTE DEPUIS LA
  v4.56.0 (v5.0.0, signalé à l'usage, capture à l'appui)** : `.dir-row .card-open` portait
  `display:-webkit-box; -webkit-line-clamp:2`, mais le display CALCULÉ y valait `flow-root`. Le
  clamp ne « marchait » que parce que les titres tenaient sur deux lignes ; monter le corps à
  16,5 px ne l'a pas cassé, il l'a **révélé** — un titre réel passait à trois lignes dans une
  boîte de hauteur FIXE et poussait la méta hors du cadre. La TUILE ne l'avait pas, et c'est ce
  qui met sur la piste : elle clampe `.qa-t`, un `<span>` INTERNE. Le titre de rangée vit donc
  désormais dans un `<span class="dir-t">` — le bouton garde sa boîte, son rembourrage compensé
  (cible ≥ 24 px) et son nom de classe, que quatorze harnais utilisent pour ouvrir une fiche.
  **⚠ NE PAS AJOUTER la propriété standard `line-clamp` à côté de l'héritée** : déclarée ensuite,
  elle fait basculer Chromium sur son nouvel algorithme et recalcule `display` (essayé, mesuré —
  erreur commise puis retirée). Un `max-height` double la garantie sans dépendre d'aucun moteur.
  **⚠ ET LE PIÈGE DE MESURE QUI VA AVEC** : sous zoom, `getBoundingClientRect` rend des px VISUELS
  (71 × 1,3 ≈ 92) — on lit un débordement qui n'existe pas si l'on oublie de diviser par `--zf`
  (règle 10). Le témoin le fait ; il mesure le `<span>`, jamais le `<button>` (dont la
  `line-height` vaut `normal`), et il balaie **130 %**, seule taille où le défaut se produisait.
  Vérifié capable d'échouer sur le défaut d'origine, aux deux moteurs.
- **LES CARTES CLIQUABLES SE DÉLIMITENT AVEC `--line-strong` (v5.0.0, audit design A1-3,
  WCAG 2.2 § 1.4.11)** : mesuré, en thème sombre une carte (`--surface` #0d0d0f) contre la page
  (`--bg` #0a0a0c) vaut **1,02:1**, et il ne restait que le filet `--line` à **1,60:1** (clair :
  1,18 et 1,39). Le TEXTE se lit parfaitement ; c'est le COMPTAGE qui échoue — où finit une
  rangée, combien y en a-t-il —, et c'est précisément ce que 1.4.11 protège. `--line-strong` donne
  3,93:1 en clair et 4,94:1 en sombre, et ce n'est pas un token neuf : la doctrine l'assigne DÉJÀ
  aux « bordures de composants ». Posé sur `.dir-row`, `.qa-tile`, `.mem-row` et le cadre de
  `.dir-grid` en voie étroite, dont le séparateur interne passe de `--surface-2` à `--line` (une
  SURFACE employée comme filet est invisible par construction). Le survol passe à `--ink-soft` :
  `--line-hover` ÉCLAIRCISSAIT le bord en thème clair une fois la base renforcée.
  **⚠ UN TOKEN `--line-card` A ÉTÉ ÉCRIT PUIS ÉCARTÉ** : il valait `var(--line-strong)` dans les
  deux thèmes, c'est-à-dire un ALIAS — exactement le défaut relevé sur `--done-ink` dans le même
  audit. On ne corrige pas une duplication en en créant une autre.
- **LES FILTRES SE REPLIENT TANT QU'AUCUN N'EST POSÉ (v5.0.0, audit design A3-1/A5-3)** : les
  trois rangées (biblio, type, catégorie) coûtaient ~90 px permanents au premier écran pour un
  geste qu'on ne fait JAMAIS sous stress — en urgence on cherche un SUJET, on n'affine pas un
  corpus. Elles vivent derrière un déclencheur unique « Filtrer », qui reprend la grammaire des
  chips (`.scopebtn`) et non celle des boutons d'action : c'est un objet de la même famille que ce
  qu'il déplie. **UN ÉTAT ACTIF NE SE CACHE JAMAIS** — un filtre caché serait bien pire que trois
  rangées permanentes : on chercherait une aide dans un corpus restreint sans savoir pourquoi elle
  n'apparaît pas. `state.filtersOpen` VIT LE TEMPS DE LA PAGE
  (ni persisté ni synchronisé, même statut que `state.allTab`) et n'est PAS remis à zéro au retour
  de fiche : replier sous le doigt de quelqu'un qui vient de les ouvrir serait le punir de son
  geste. L'ordre et les libellés sont INCHANGÉS (lot M4b) ; seule leur présence au repos change.
  **⚠ UN TÉMOIN DE T9 A DÛ APPRENDRE À DÉPLIER** : il cliquait une chip désormais repliée et
  emportait la passe entière. Un contrôle qui mesure ce que font les CRANS doit passer par le VRAI
  geste, comme l'utilisateur.
  **L'ÉTAT ACTIF A CHANGÉ DE PORTEUR — LE DÉCLENCHEUR NE DISPARAÎT PLUS (v5.0.3, signalé à
  l'usage : « le bouton filtrer ne s'affiche pas toujours quand on a sélectionné »)** : la v5.0.0
  tenait la règle ci-dessus en FORÇANT les rangées ouvertes dès qu'un filtre agissait et en
  RETIRANT le déclencheur (« plus rien à basculer, donc aucun bouton mort »). Elle achetait donc la
  garantie au prix d'un contrôle qui apparaît et disparaît selon l'état — exactement ce que la
  constance positionnelle proscrit (v4.31.0 : « une commande qui apparaît/disparaît romprait la
  constance ») — et le gain de ~90 px n'existait plus dès qu'on avait filtré quoi que ce soit.
  **CE QUI REMPLACE LE FORÇAGE** : le déclencheur PORTE l'état. Registre de sélection PLEIN plus
  le **NOMBRE** de filtres posés (`filtersCount`), donc la couleur n'est jamais seule (règle 8) —
  un chiffre n'est pas une couleur —, et le nom accessible le dit en toutes lettres. L'état actif
  n'est pas caché : il est porté par un objet PERMANENT et IMMOBILE au lieu de trois rangées
  permanentes, et l'on ne peut toujours pas se retrouver dans un corpus restreint sans savoir
  pourquoi. Replier avec un filtre actif redevient donc permis.
  **ET IL DÉMÉNAGE CONTRE LA RECHERCHE** (proposition utilisateur) : les deux répondent à la même
  question — restreindre ce qu'on voit —, et posé là il ne coûte plus une ligne au premier écran.
  **GLYPHE SEUL**, la place horizontale d'une rangée d'en-tête étant la plus disputée du produit :
  mesuré à 320 px, 38 px de bouton (45 avec le chiffre) et 0 px de débordement. Il est **STATIQUE**
  comme le champ (il vit hors de `main`, `syncFiltTog` le PEINT au lieu de le reconstruire) : sa
  position s'apprend une fois pour toutes, et c'est le **bord droit** qui est constant — il grossit
  du chiffre, il ne se déplace pas. **Il n'existe qu'en voie ÉTROITE** : en large les filtres vivent
  dans la colonne gauche, déjà visible, et un bouton pour déplier ce qui est déplié serait mort.
- **⚠ L'EN-TÊTE D'ACCUEIL N'AVAIT JAMAIS ÉTÉ MESURÉ À 320 px (v5.0.3, signalé à l'usage :
  « pourquoi ça ne passe pas en 320 px ? »)** : la v4.43.0 a déclaré ce plancher SERVI et l'a
  mesuré sur la rangée de crise et sur la barre des éditeurs — jamais sur l'écran qu'on ouvre en
  PREMIER. Mesuré : logo 30 + mot-marque 126 + actions 136 = 292 px, plus deux écarts, soit 308 px
  pour 284 disponibles. `.id-row` est en `flex-wrap`, et **le flex CASSE LA LIGNE avant de
  rétrécir** (leçon v4.23.4) : le déficit ne se voit donc PAS comme un débordement, il se paie en
  38 px de HAUTEUR d'en-tête, là où elle est la plus rare. Recette sur les écarts et la taille des
  boutons — ni le mot-marque ni le logo, que l'audit A3-1 vient de calibrer — plus un **halo porté
  de 4 à 6 px** : rétrécir le DESSIN sans rétrécir la CIBLE est tout l'objet d'un halo en zone
  haute (44 px conservés au pixel). En-tête **148 → 106 px**.
  **ET C'EST LA MARGE QU'ON MESURE, PAS LE TENU-DE-PEU** : à 360 px la rangée tenait avec **6 px**
  de réserve, et le mot-marque mesure **126 px sur Chromium complet contre 136 sur le headless
  shell** — 10 px d'écart pour le même code, davantage que la réserve. Un booléen « ça tient »
  reste vert jusqu'au dernier pixel puis casse d'un coup ; le témoin exige donc ≥ 8 px, et un
  palier LÉGER à 400 px (les écarts seuls) porte la réserve de 6 à 22 px. **Toute addition à cette
  rangée se re-mesure ainsi**, jamais à l'œil.
  **⚠ DIX-NEUVIÈME PIÈGE DE CASCADE, rencontré en l'écrivant** : `header.bar.home .id-row` vaut
  (0,3,1) — la MÊME spécificité que la règle `column-gap` du bloc 429.98. Déclaré au-dessus, le
  bloc était silencieusement sans effet (8 px obtenus pour 4 demandés) ; il vit donc APRÈS, comme
  la v4.43.0 l'avait déjà fait pour la barre des éditeurs.
- **LA GOUTTIÈRE DU RAIL A→Z N'EST PAS UN TAMPON ANTI-FAUSSE-MANŒUVRE (v5.0.3, question
  utilisateur : « l'espace entre les cartes et le rail me paraît grand — est-ce fait exprès ? »)** :
  en voie étroite le rail est `position:fixed`, donc sans rembourrage réservé il RECOUVRIRAIT le
  bord droit des rangées, c'est-à-dire l'épingle. Il n'en fallait jamais 24 px — le rail fait 27 px
  de large et mord déjà sur les 18 px de marge de page, il n'en faut que **9** pour ne rien
  couvrir ; le reste était du vide. **16 px** laissent 8 px entre la carte et le rail et 9 px entre
  la ZONE TACTILE de l'épingle (halo compris, qui finit 4 px avant le bord de la carte) et la
  première lettre : la seule contrainte réelle est que les deux cibles ne se TOUCHENT pas, et c'est
  elle que le témoin mesure — des deux côtés (rien de couvert, rien d'adjacent).
- **⚠ `check-space` NEUTRALISE LES COMMENTAIRES DEPUIS LA v5.0.3** : il les lisait, et cette
  feuille CITE ses propres déclarations à longueur de commentaires doctrinaux. Un `column-gap:8px`
  écrit dans une explication faisait courir la capture `[^;}]+` jusqu'à l'accolade suivante — donc
  à travers le commentaire ET la règle d'après, où elle ramassait le `359.98px` d'une media query
  et le signalait comme un espacement de « 98 px ». Les commentaires deviennent des espaces de
  MÊME LONGUEUR (indices et numéros de ligne intacts). Même précaution que `check-upload`, pour la
  même raison : **un contrôle qui lit les commentaires d'un fichier qui documente ses propres
  règles finira par mesurer la doctrine au lieu du code.**
- **LA CROIX D'EFFACEMENT DE LA RECHERCHE (v5.0.3, demande utilisateur)** : elle vit DANS la boîte
  du champ (`.srch-box`, le repère de position absolue — la rangée porte en plus le déclencheur de
  filtre, s'ancrer sur elle poserait la croix au bord du BOUTON). Sa place est **réservée en
  permanence** par un `padding-right` constant : elle paraît et disparaît à la frappe, et un
  rembourrage qui bougerait ferait sauter le texte sous le curseur. **Peinte à la FRAPPE, pas au
  rendu** — le rendu de la recherche est débouncé de 150 ms, et une croix qui paraîtrait un sixième
  de seconde après la lettre se lirait comme une latence ; le témoin mesure donc AVANT le débounce,
  sans quoi il resterait vert sur ce défaut (vérifié capable d'échouer). **Le focus RESTE dans le
  champ** : on efface pour retaper, pas pour partir.
- **⚠ UN TÉMOIN QUI FIGE UN CHIFFRE ROUGIT SUR UN CHANGEMENT JUSTE (v5.0.0)** : le contrôle du
  titre de rangée exigeait `15.5px` en dur — bonne réaction à ce qui l'avait motivé (deux
  maquettes posant 15 puis 14,5 px, dont aucun n'est un palier), mauvaise expression de son
  intention, qui a toujours été « ce titre est SUR L'ÉCHELLE FERMÉE et il ne redescend pas ». Un
  littéral pousse à contourner le garde-fou, ce qui est la pire chose qu'on puisse lui faire. Il
  vérifie désormais l'appartenance à l'échelle plus un PLANCHER, et garde l'exigence de cohérence
  entre toutes les rangées, qui est ce qui donne son rythme à l'annuaire.

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
- **LA GRANDE POLICE ÉTAIT LE TROU DE COUVERTURE (v4.73.1, signalé à l'usage : « en mode grande
  police, souci d'affichage de l'en-tête, les boutons sont tronqués »)** — « ⤢ Se repérer » coupé net
  et « ⤢ Consulter » hors écran. Deux causes, et la seconde n'avait jamais été nommée :
  (1) **les paliers de compression ne se déclenchaient pas** — cf. règle 10, une media query mesure
  le périphérique et non la place réellement disponible sous `zoom` ; mesuré à 430 × 130 % : rangée
  exigeant **594 px** pour 430, soit 164 px inaccessibles, dans la zone de crise. (2) **La recette de
  compression est calibrée pour 320 px**, le plancher servi : à 130 % sur un écran de 390 il ne reste
  que 300 px effectifs, sous ce plancher, et aucune marge ne peut plus rendre les pixels manquants.
  **DERNIER RECOURS : LA RANGÉE S'ENROULE, ET C'EST MESURÉ, PAS SEUILLÉ.** `fitCtrlRow()` remet la
  rangée à plat, lit son débordement RÉEL (bord droit du dernier enfant contre le bord de la BOÎTE DE
  CONTENU — `scrollWidth` ne compte pas le rembourrage de droite et ratait un rognage de 3 px que la
  sonde de doctrine voyait) et n'enroule que s'il existe. Aucun seuil de largeur en dur : ceux
  essayés pour le quai s'étaient révélés FAUX, et ici ils dépendraient en plus de la fonte du
  système et de la longueur des libellés. La coupure tombe sur `.ctrl-sp`, qui devient le SAUT DE
  LIGNE : il sépare toujours le MODE des OUVERTURES, et mieux que 4 px — sans cela la coupure
  séparait les deux ouvertures, c'est-à-dire les deux contrôles de MÊME nature.
  **LA DOCTRINE « PAS DE 2ᵉ LIGNE » N'EST PAS ENFREINTE** : elle vise le coût PERMANENT d'une rangée
  qui s'épaissirait pour tout le monde ; ici la seconde ligne n'existe que quand la rangée déborde
  vraiment, donc jamais sur une configuration où la compression suffit. Les paliers RESTENT et ne
  sont pas redondants — mesuré, ils évitent l'enroulement dans 4 configurations sur 20. Rien n'est
  sacrifié pour tenir : ordre, libellés entiers, cibles de 44 px, positions constantes.
  Témoin : `audit-doctrine` mesure désormais **390 et 430 px aux quatre paliers de taille du
  texte**, et vérifie EN PLUS que les libellés sont intacts — sans cette seconde moitié, un futur
  « correctif » passerait le contrôle en masquant les mots. Vérifié capable d'échouer (enroulement
  neutralisé → 10 rouges, dont 5 des nouveaux).
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
- **RÉENTRÉE — ON REVIENT SUR LE SOIN, PAS SUR LE PRÉAMBULE (v5.0.0, `landOnBout`)** : `render()`
  posait `scrollTo(0,0)` à toute arrivée en lecture, sans distinguer les deux arrivées qui n'ont
  rien à voir — OUVRIR une aide (on s'oriente avant d'agir : condition d'entrée QRH, le haut de
  fiche est la bonne arrivée) et Y REVENIR alors qu'une session TOURNE (on reprend un geste
  interrompu). **MESURÉ** sur la fiche d'exemple en boucle, après six avancées : la réouverture
  depuis l'accueil déposait à **456 px du bout à 320 × 640** (355 à 390 × 844), **zéro étape
  cochable** à l'écran à 320 et le contrôle « Continuer » hors écran aux deux formats. Après :
  **8 px, 4 étapes cochables**. Le retour d'une FEUILLE (« Consulter », PDF) n'était pas concerné
  et ne l'est toujours pas — `_bgUnlock` restaure déjà la position au pixel.
  **CE N'EST PAS UN DÉFILEMENT AUTOMATIQUE (règle 11)** : la règle vise l'écran qui bouge tout seul
  sous quelqu'un qui n'a rien demandé ; ici la page vient d'être rendue de neuf, il n'y a AUCUNE
  position à préserver — on choisit le point d'arrivée d'une navigation demandée d'un tap. C'est la
  distinction déjà tranchée pour `cxEnter` (« entrer sur une complication est une navigation
  DEMANDÉE »). **MÊME RÈGLE DE VISIBILITÉ QU'`ovAdvanceRender`** : si le bout est déjà entièrement
  à l'écran depuis le haut (aide courte, session à peine démarrée), rien ne bouge — un saut qui
  n'apporte rien escamoterait le chapeau et les critères pour rien. Vaut aussi pour l'INVITÉ
  (`crisisOnScreen` couvre les deux rôles). L'atterrissage est posé **après `syncHdrScroll()`** :
  il se mesure contre `stickBase()`, dont les trois couches collantes viennent d'y être
  resynchronisées — placé avant, il viserait la géométrie de la vue précédente.
  ⚠ **LE TÉMOIN A DÛ ÊTRE CORRIGÉ DEUX FOIS, ET C'EST LA LEÇON** : « le bout est hors écran depuis
  le haut » puis « 0 étape cochable depuis le haut » étaient tous deux FAUX à 390 px, où le haut de
  la carte dépasse sous le pli et où deux de ses étapes se voient. Ce qu'on perdait réellement est
  le **contrôle d'avancement**, et c'est lui que le contrefactuel mesure (on repose la page en haut
  et l'on recompte). Un critère « rencontre son cas » mal choisi rend rouge un correctif juste.
  **L'ORDRE DU JOURNAL N'A PAS ÉTÉ INVERSÉ, ET LA QUESTION EST TRANCHÉE PAR LA MESURE.** Le rebours
  (le plus récent en haut) a été étudié : il achèterait exactement cette réentrée, en payant quatre
  choses. (1) Il n'y a **rien à récupérer sur la croissance** — la condensation (`ovPresList` puis
  ligne-bilan ECL) plafonne le journal : 13 passages tiennent en 3 cartes + 1 ligne et la distance
  du bout au haut de page se STABILISE à 482 px dès le 4ᵉ passage. (2) Le sens du défilement
  s'inverserait par rapport à l'avancement : mesuré sur 20 avancées, le chronologique demande
  « descendre » 13 fois et « remonter » **0**, le rebours « remonter » 12 fois et « descendre »
  **0** — pendant que l'historique, lui, continue de s'étendre vers le bas. (3) Le temps
  descendrait DANS une carte (étapes puis « Continuer » au pied) et monterait ENTRE les cartes :
  deux axes pour une séquence. (4) Plan, statique, schéma et compte rendu lisent tous vers le bas
  via `flowPlan().order` — inverser le seul journal serait deux vocabulaires pour une même chose
  (AC 120-71B §5.5), exactement ce que le retrait du rail ①②③ a supprimé au lot M2a.
  **Ni ECAM ni AC 120-71B ne prescrivent d'ordre d'affichage d'un journal** : ils décrivent une
  procédure, qui se lit de haut en bas parce que c'est le sens de lecture — le leur attribuer serait
  la même erreur de source que « Do-Verify »/AC 120-71A. Ce qui EST contraignant est plus étroit :
  les procédures se POSTENT (ECAM) et une même chose ne se dit pas de deux façons.
- **LE CHAPEAU SE GLISSE ENTRE LES CRITÈRES ET LE BOUTON (v5.0.8, décision utilisateur)** : la
  séquence hors session est désormais **condition d'entrée → memory items → geste d'entrée**, qui
  est l'ordre CANONIQUE — un QRH imprime le titre et la condition AU-DESSUS des recall items, et
  sur ECAM le titre de l'alerte (qui EST la condition) précède les lignes d'action. C'est l'ordre
  d'avant (memory items → condition) qui s'en écartait.
  **⚠ LE CHAPEAU NE PASSE PAS SOUS LE BOUTON, ET C'EST TOUT L'ARBITRAGE** : le descendre sous
  l'ÉTAGE de la condition d'entrée le mettrait APRÈS « Confirmé — démarrer la session », puisque le
  bouton vit dans cet étage — on l'aurait rangé derrière le geste qu'il doit précéder.
  **CE QUE CELA COÛTE, MESURÉ** : le chapeau quitte le premier écran dès que les critères sont
  longs (8 critères, 390 × 844 : y = 130 → **y = 813**) ; sur une fiche ordinaire il y reste ENTIER
  (571 → 786). Et le bouton FLOTTANT (v4.73.0) permet de démarrer sans avoir défilé jusqu'à lui.
  **CE QUI REND CE COÛT ACCEPTABLE EST LE LOT T7** : un memory item ★ RESTE dans son bloc — le
  chapeau AGRÈGE, il ne possède pas ; l'item se re-vérifie à sa place dans la checklist, ce qui est
  le geste QRH (réciter de mémoire, puis confirmer sur la liste). Si un jour le chapeau redevenait
  le SEUL porteur des memory items, cet arbitrage serait à rouvrir.
  **LA CONDITION EST LA PRÉSENCE DU BOUTON, PAS L'ÉTAT DE LA SESSION** : chez l'invité et en aperçu
  d'essai `sessStartH` est vide, et une séquence qui mène à un bouton absent n'a rien à ordonner —
  le chapeau reprend alors sa place en tête (idem sans critères, idem en statique). **En session,
  rien ne change de ce qui existait** : le chapeau replié revient en tête et la condition d'entrée
  descend avec son étage (T3 + T5) — le débat ne portait que sur l'écran d'AVANT.
  **⚠ LA CONSTANTE SE DÉCLARE AVANT LE `if(useSv)`** : la coque de `main.innerHTML` la lit aussi
  (c'est elle qui décide si le chapeau est encore rendu en tête de colonne) — posée dans la
  branche, elle serait en zone morte, la faute exacte payée au lot T3.
- **UNE CONNEXION INDEXEDDB FERMÉE N'EST PAS UNE PANNE, C'EST UN ÉTAT À RECONNAÎTRE (v5.0.10,
  signalé à l'usage sur un appareil synchronisé : « Erreur inattendue — Détail technique : Failed
  to execute 'transaction' on 'IDBDatabase' : The database connection is closing »)** : une
  connexion se ferme SANS que l'application le demande — `onversionchange` la libère quand un
  autre onglet migre ou appelle `deleteDatabase` (c'est NOUS qui appelons `close()` là), une page
  qui commence à se recharger les ferme toutes (la bascule d'espace et l'écouteur `storage` font
  `location.reload()` sans arrêter la synchro), et un moteur mobile peut les reprendre en
  arrière-plan. Le handle restait dans `IDB.db`, et **toute transaction ultérieure levait
  `InvalidStateError`** : la synchro échouait, et le message affiché ne désignait pas sa cause.
  **TROIS GESTES, ET LE PREMIER EST UN POINT D'ÉTRANGLEMENT** : (a) toute méthode PUBLIQUE d'IDB
  est enveloppée dans `_try` **par une boucle, jamais par une liste** — une méthode ajoutée demain
  est couverte sans qu'on y pense (patron `persistLive`/`edCommit` : une liste recopiée finit
  toujours par diverger, et le trou est SILENCIEUX) ; (b) un handle mort n'est jamais gardé
  (écouteurs `versionchange`/`close`, et `_try` le lâche au premier appel qui échoue) ; (c) on
  rouvre et on réessaie **UNE** fois — au-delà l'erreur remonte, une base réellement indisponible
  devant se voir. **`IDB.sealed` interdit la reprise pendant un effacement** (`wipeLocal`,
  `wipeCurrentSpace`) : rouvrir recréerait la base qu'on efface, ou bloquerait le
  `deleteDatabase`.
  **⚠ PIÈGE DE SPEC** : l'événement `close` ne se déclenche PAS sur un `close()` explicite — il
  est réservé aux fermetures ANORMALES. Un correctif qui n'écouterait que lui serait inerte sur
  le chemin le plus fréquent, et un témoin qui attendrait cette notification mesurerait le moteur
  au lieu de l'application.
  **ET LE MESSAGE CESSE DE LIVRER LE LIBELLÉ DU MOTEUR** : `explainSyncError` a sa branche —
  ce n'est ni le réseau ni le serveur, **rien n'est perdu**, la synchro reprend seule ; le dire
  vaut mieux qu'un « Détail technique » qui envoie chercher la panne du mauvais côté.
  **`scripts/audit-stockage.mjs` FERME LE DERNIER ANGLE MORT DU DOSSIER** : le stockage local
  n'était mesuré que par ses parties PURES — `check` lit du texte, `npm test` charge
  `index.html?__actest`, **qui n'amorce pas** et n'ouvre donc aucune base réelle. Les deux
  garde-fous étaient verts pendant que la synchro échouait chez l'utilisateur. Le harnais coupe la
  connexion SOUS l'application et vérifie que l'appel suivant réussit (lecture ET `applyRows`, par
  où passe le pull). Vérifié capable d'échouer aux deux moteurs (enveloppe neutralisée →
  3 rouges), fichier restauré à l'octet.
- **UNE GÉOMÉTRIE DE CHROME NE SE DÉRIVE JAMAIS D'UNE POSITION DE DÉFILEMENT (v5.0.9, signalé à
  l'usage en PWA : « barre d'en-tête inférieure, scroll pas très réactif, beaucoup d'à-coups »,
  vidéo à l'appui)** : `--hdr-h` est le `top` collant de `#crisisCtrl`, donc du quai empilé dessus,
  et il était dérivé du **`bottom`** de l'en-tête. Au rebond de fin de course, iOS TRANSLATE tout
  le document, en-tête collant compris : `bottom` grandit, `--hdr-h` grandit avec lui, les deux
  rangées descendent puis reviennent — à la cadence du doigt, c'est un tremblement, et sur
  certaines images la rangée de commandes laisse une bande vide à sa place. On mesure la
  **HAUTEUR**, qui ne dépend d'aucun défilement ; `--stick-top` devient une SOMME DE HAUTEURS
  (`stickHeight()`). **`stickBase()` reste et garde ses rectangles** là où c'est juste :
  `ovScrollEl`, qui vise une position d'écran à l'instant du saut. Même famille que le rail A→Z
  (v5.0.2) et la hachure des placards (v5.0.6) — **on n'ancre jamais à un repère qu'on ne contrôle
  pas**, et ce que le compositeur fait du rendu n'est visible dans AUCUNE mesure de la page, donc
  un harnais Blink reste vert : le témoin DÉPLACE l'en-tête sans changer sa hauteur (stand-in
  fidèle) et vérifie que la géométrie ne bouge pas d'un pixel.
  **BÉNÉFICE SECOND, ET IL COMPTE AUTANT** : la valeur devenant CONSTANTE, la garde d'écriture
  devient un vrai no-op — on cesse d'invalider le style de tout le document (une propriété
  personnalisée posée sur `<html>`) à chaque évènement de défilement. Et la passe est **coalescée
  par IMAGE** (`requestAnimationFrame`) au lieu d'être branchée sur l'évènement : elle lit quatre
  rectangles puis écrit trois propriétés, couple lecture/écriture qu'on n'intercale plus dans le
  pipeline de défilement (discipline de `svPaintArrows`, v4.14.10). ⚠ L'appel DIRECT de
  `syncHdrScroll()` reste SYNCHRONE — `render()` en dépend, `landOnBout` se mesurant contre
  `stickBase()` juste après.
- **LE PARCOURS MONTRE TOUT CE QU'IL PROMET (v5.0.9, trois signalements à l'usage)** :
  (a) **la réponse attendue enroule au lieu d'écraser le geste** — `.pc-r` était `flex:none` dans
  une rangée qui n'enroulait pas, donc le seul objet compressible était le GESTE (`.pc-t`,
  `min-width:0`) : mesuré, il tombait à quelques pixels pendant que la pilule sortait de la carte,
  et l'on perdait l'information principale ET la secondaire. Le remède est déjà écrit dans le
  fichier pour ce défaut exact, sur la feuille « Consulter » (`.rs-v`) : la pilule prend sa propre
  ligne, avec le retrait de la case. Une seule grammaire — **on enroule, on ne tronque jamais**.
  (b) **chaque branche porte son étiquette** — elle était mise en attente puis posée devant la
  première CARTE de la branche, or `flowPlan` n'en émet pas toujours (une branche qui rejoint le
  point de convergence, ou qui reboucle sur un bloc déjà décrit, ne produit qu'un `link`). Mesuré
  sur la fiche d'exemple Anaphylaxie : « OUI — STABILISÉ » n'était JAMAIS rendue. `bropen` précède
  toujours immédiatement le contenu de sa branche : émettre là met l'étiquette exactement où elle
  était, et AUSSI dans les cas où elle manquait.
  (c) **une branche sans carte affiche son renvoi** (« → n », « ↺ n », « ▪ fin » — le vocabulaire
  abrégé de l'Échelle) au lieu de RIEN, dans une vue qui promet la fiche entière. ⚠ Uniquement
  quand la branche n'a PAS de carte : sinon le pied de la carte précédente (`.pc-foot`) le dit
  déjà, et l'on écrirait deux fois la même chose sur deux lignes qui se suivent. Tout y reste
  INERTE (doctrine du plan, re-vérifiée avec le reste).
  ⚠ **LE TÉMOIN CONSTRUIT SON CAS** : sur les fiches d'exemple aucune réponse attendue ne déborde
  et une seule branche est sans carte — il serait resté vert sur les trois défauts.
- **⚡ LES CIBLES DE COMPLICATION SE RECONNAISSENT DANS LE SCHÉMA (v5.0.9, proposition de
  l'auteur : « mettre un éclair et en rouge ? »)** : le SVG était la SEULE des quatre vues de
  structure où une cible de complication se dessinait comme un bloc d'étapes ordinaire — donc comme
  l'étape d'après, le défaut exact mesuré en v4.26.0 (« 5 Laryngospasme ») ; l'Échelle, le Statique
  et la vue Parcours ont toutes leur section « À tout moment ». Registre **ALERTE EN CONTOUR**
  (v4.26.1) : bandeau d'en-tête teinté, liseré et cadre rouges, **corps du bloc INCHANGÉ** — un
  aplat rouge permanent désensibilise au rouge, qui appartient ici aux étapes vitales dessinées à
  l'intérieur. La couleur n'est jamais seule (règle 8) : pastille « ⚡ À TOUT MOMENT » en toutes
  lettres, reprise dans le nom accessible du nœud. ⚠ **L'éclair est un TRACÉ**, pas le caractère
  « ⚡ » : celui-ci sort en emoji COULEUR sur iOS, dans un dessin qui n'a pas d'autre couleur que
  ses registres (même arbitrage que le trombone de la porte « ＋ », v4.71.0). ⚠ Et la réachabilité
  est calculée SUR PLACE dans `_buildFlowSVG`, jamais par `cxDetached` : celui-ci appelle
  `flowPlan`, dont le cache est indexé par OBJET fiche et que l'éditeur — qui mute son brouillon en
  place — ne doit jamais peupler.
- **UN BLOC COMPLET L'EST SUR TOUTE SA BORDURE (v5.0.9, signalé à l'usage : « uniquement le bord
  gauche devient vert et pas le reste »)** : `.ov-block.done` n'écrivait que `border-left-color`,
  si bien qu'un bloc COURANT ET COMPLET portait un cadre bleu avec une seule arête verte — deux
  registres sur un même trait, exactement ce que la v4.24.0 a corrigé en sens inverse pour la
  décision. Et c'est la configuration NOMINALE : on finit de cocher le bloc où l'on est. La carte
  REPLIÉE le faisait déjà (`.closed.done`) — le même bloc changeait donc de registre selon qu'il
  était plié. La POSITION reste portée sans ambiguïté par la pilule « VOUS ÊTES ICI » : un canal
  par signification. **PAS DE FOND TEINTÉ** sur la carte ouverte, contrairement à `.closed.done` :
  c'est la colonne d'ACTION, ses étapes ⚠/△ doivent garder leur boîte lisible sur `--surface` ;
  repliée, la carte n'est plus qu'un statut d'une ligne et l'aplat y dit « c'est fait ». **UNE
  DÉCISION EST EXCLUE** (`:not(.dec)`) : son ambre prime sur l'état.
  ⚠ **ET LE PIÈGE DE CASCADE A ÉTÉ REJOUÉ EN L'ÉCRIVANT** : le commentaire qui explique cette
  règle portait un `*/` EN TROP, le texte restait à nu et le parseur **avalait la règle suivante**
  — le correctif était livré INERTE, et `.done` ne peignait plus rien du tout. C'est la mesure qui
  l'a dit, pas la relecture. `check-syntax` le nomme précisément (« fermeur de commentaire sans
  ouvreur, le parseur avalera la règle suivante ») : il suffisait de le lancer avant de mesurer.
- **LE DÉMARRAGE DÉPOSE SUR LE HAUT DU PREMIER BLOC (v5.0.7, signalé à l'usage)** : presser
  « Confirmé — démarrer la session » retire ou rétrécit TOUT ce qui est au-dessus du doigt — chapeau
  replié en une ligne (T3), condition d'entrée refermée, « Prise en charge » remontée en tête (T5) —
  sans que le défilement bouge : on atterrissait AU MILIEU de la carte du bloc. Mesuré sur le cas
  pour lequel `.sess-start.afloat` existe (8 critères d'entrée, lus en défilant) : haut de carte à
  **−206 px à 320 × 640** et **+20 px à 390 × 844** (98 px SOUS l'en-tête collant) — numéro, titre et
  « Vous êtes ici » invisibles. Après : **+8 px sous le quai**, 2 → 5 étapes cochables à 320.
  **CE N'EST PAS UN DÉFILEMENT AUTOMATIQUE (règle 11)** : la page vient d'être rendue de neuf, il n'y
  a aucune position à préserver — c'est le point d'arrivée d'une navigation DEMANDÉE d'un tap, même
  arbitrage que `landOnBout` et `cxEnter`. UN SEUL POINT D'ÉCRITURE (`startSessionGesture`), partagé
  par le bouton du parcours et celui du tableau statique.
  **⚠ CE CHEMIN EST CELUI DU BOUTON, JAMAIS CELUI DU COCHAGE** : un démarrage IMPLICITE passe par
  `renderKeepAnchor` et doit continuer de ne pas déplacer d'un pixel l'élément touché (v4.4.0).
  **⚠ ET LA RÈGLE DE VISIBILITÉ DE `landOnBout` A ÉTÉ ESSAYÉE PUIS MESURÉE FAUSSE ICI** : elle exige
  la carte ENTIÈRE à l'écran, or une carte de bloc dépasse presque toujours le pli (615 px sur 640) —
  elle défilait donc même quand le haut était DÉJÀ à sa place, et laissait la page décalée pour les
  gestes suivants (deux témoins de dépliant l'ont dit, à **−51 px** : le panneau du quai ne se posait
  plus sous le quai). On ne garantit que ce que l'usage demande : LE HAUT de la carte sous les couches
  collantes, et rien ne bouge s'il y est déjà. **Les trois densités ont chacune leur porteur** —
  `.ov-block`, `.sv-cell.cur`, `.nav-wrap` (fiche sans algorithme) : oublier le troisième, c'est ne
  rien faire précisément sur les fiches mono-bloc, sans que rien ne le dise.
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
  et PDF —, `.lightbox`, `#flowFull`, `#monMode`) reçoivent sous `@supports (height:100dvh)`
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
- **LE COMPTE-RENDU S'ENREGISTRE EN PDF, PAS EN .html (v5.2.0, demande utilisateur)** : la
  fenêtre portait « Télécharger » (.html) et « Imprimer », et c'est le second qui produisait déjà
  un PDF complet — le bouton nommait son MÉCANISME, pas sa destination. Il devient
  « **Enregistrer en PDF** » (rempli) et reste le chemin d'impression (iframe A4 hors écran,
  réutilisée) : **le seul producteur de PDF du projet est le navigateur**, la règle 13 interdit
  une bibliothèque de génération et pdf.js est un LECTEUR. **UN SEUL bouton pour ce chemin** —
  « Imprimer » à côté aurait été deux mots pour un seul geste (AC 120-71B §5.5), le dialogue
  ouvert portant l'imprimante papier juste à côté du choix « PDF ». Le **fichier .html RESTE**,
  en secondaire et sous son vrai nom : document autonome, lisible sans visualiseur, et **seule
  sortie qui ne dépende pas du dialogue d'impression du système** — donc le repli quand celui-ci
  manque, ce que le message d'échec NOMME désormais au lieu de dire « indisponible » sec.
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
  sous-ligne à 1 ligne ellipsée ; le nom accessible et l'info-bulle gardent le texte entier ;
  **grille = MÊME règle fluide que le répertoire**, `auto-fill minmax(290px,1fr)` et gouttière
  8 px — v4.56.1, retour utilisateur : le nombre de colonnes FIGÉ (2 < 780, 3 au-delà) faisait
  chuter une tuile de ~360 à ~140 px au franchissement du seuil, la sidebar mangeant l'espace,
  et son rythme ne coïncidait jamais avec celui des rangées ; désormais tuiles et rangées
  s'alignent colonne pour colonne et une transition ne change que le NOMBRE de colonnes — la
  redistribution en dents de scie bornée vers 1520 px, 3×~390 → 4×~296, est le comportement
  normal d'une grille fluide, ne pas la « corriger »), **RÉPERTOIRE A→Z**
  (`azGroups`/`azLetter`, purs testés : lettre désaccentuée, hors A-Z → `#` rangé en fin ; tri
  alphabétique STRICT dans les groupes — l'épinglée a sa tuile, la hisser casserait la lecture
  d'annuaire) en rangées compactes `.dir-row` (< 640 px : liste à filets dans une carte par
  lettre), et **RAIL ALPHABÉTIQUE** `.azrail` (tap = saut, glisser = parcourir façon index iOS ;
  dès 2 lettres ; s'il ne tient pas en hauteur il DISPARAÎT — jamais de lettres coupées ni de
  cibles < 24 px ; en étroit il est FIXE, ancré entre `--hdr-h` et la tab bar — un centrage
  fenêtre passait sous l'en-tête à 320×640).
  **LES LETTRES SONT ANCRÉES EN HAUT, ET CE N'EST PAS UN CHOIX ESTHÉTIQUE (v4.73.0, signalé à
  l'usage : « la liste de lettres monte et descend en même temps, par moment »)** : elles étaient
  CENTRÉES dans une boîte fixée par son haut ET son bas, donc toute variation de la hauteur
  réellement visible les déplaçait de la MOITIÉ de cette variation. Or cette hauteur varie
  précisément pendant un défilement — la barre d'outils du navigateur mobile se replie, et
  `position:fixed` se dimensionne sur le grand viewport (même mécanique que le dossier « bande
  basse iOS »). Le glisser devenait un asservissement instable : le rail défile, la barre bouge,
  les lettres se décalent sous le doigt, la lettre visée change. **Mesuré** : 30 px de déplacement
  pour 60 px de hauteur en moins, contre **0 px** en `flex-start` — la hauteur passe désormais par
  `--vvh` (la seule mesure qu'iOS ne fausse pas), ce qui rend fiable le test de débordement.
  Décisions utilisateur figées : la recherche RESTE
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
  (émissions vérifiées au grep, démo `design/build.mjs` refaite — règle 14). **BUG WEBKIT À
  CONNAÎTRE (v4.56.2, reproduit à la sonde sur WebKit SEUL)** : au redimensionnement continu,
  quand un changement de nombre de colonnes fait ré-enrouler la sous-ligne d'une rangée, WebKit
  ne regrandit pas la piste de grille — contenu rogné (titre 11 px, date 5 px, mesurés) et état
  corrompu PERSISTANT. Remède en place : à la traînée du resize (120 ms), chaque
  `.dir-grid`/`.qa-grid` passe par block→grid dans la même frame (aucun repaint intermédiaire) —
  ne pas retirer ce listener, et re-mesurer sur WebKit si l'on retouche la structure des grilles.
- **AUDIT DE DESIGN v4.56 — CE QUI A ÉTÉ RETENU, ET CE QUI A ÉTÉ ÉCARTÉ (v4.56.3)** : audit
  externe sur 25 captures (1 P1, 7 P2, 12 P3, plus des pistes D/E/F/G/H/I/K). **Appliqué** :
  critères diagnostiques de l'étape ① en **lignes à filet** au lieu d'une boîte par critère
  (doctrine des listes « normal = ligne, signalé = boîte » — 53 px rendus, mesurés, sur une fiche
  à critères de deux lignes) ; garde-fou du chapeau étendu au **rappel trop long** (110 c., même
  seuil télégraphique que les challenges — mesuré, c'est la LONGUEUR autant que le nombre qui
  pousse le CTA sous le pli) ; **une action par ligne** signalé dans l'éditeur (G1 : « · » ou
  « + » entourés d'espaces, ≥ 2 dans la partie CHALLENGE — la réponse « :: » a le droit
  d'énumérer, c'est une valeur) ; nom de minuteur en **casse de phrase** 13,5/700 avec la
  précision entre parenthèses reléguée en méta 12 px (`tmLabelParts`, pure testée — un nom long
  en petites capitales se déchiffre lettre à lettre) ; **temps d'un minuteur : encre à l'arrêt,
  `--link` EN COURS** (P2-7 — le canal couleur disait le contraire de l'état ; **graisse ramenée à
  500 en v4.73.0**, cf. « L'ÉTAT NE CRIE PAS PLUS FORT QUE L'ACTION » ci-dessous) ; « + » de compteur
  **tonal et large**, « − » contour compact (on incrémente 10 fois pour 1 correction) ;
  « Vous êtes ici » et Lecteur/Vérifier sur **une seule ligne d'état** (−52 px par bloc actif ;
  **elle s'ENROULE depuis la v4.73.1** — signalé à l'usage en grande police, où « VOUS ÊTES ICI »
  était coupée par le bord GAUCHE de la carte. Ses trois objets sont tous en `nowrap` et ne peuvent
  donc pas se rétrécir, et `justify-content:flex-end` fait déborder par le côté OPPOSÉ, c'est-à-dire
  par le DÉBUT : c'était le PREMIER objet qui sortait de la carte, là où aucun défilement ne peut le
  rattraper. On enroule, on aligne au début, et c'est le premier BOUTON qui porte le
  `margin-left:auto` — aspect identique tant que tout tient sur une ligne, boutons toujours à droite
  quand ils passent à la ligne, et la pilule ne se déplace jamais : c'est un état) ;
  rangées d'étape à **60 px** (D1 — le 44 px doctrinal est un minimum, pas un optimum, et un
  pouce ganté ne vise pas une case de 24 px) ; **acquittement haptique** ~18 ms au cochage et à
  l'incrément (D10, `tick()` — inerte sur iOS, qui n'expose pas l'API) ; pilule posologique du
  statique **insécable** (D8) ; `tabular-nums` sur les nombres d'état (D11) ; fenêtre Compte —
  tuiles d'état **neutres** (P3-1 : `--primary-soft` est la teinte des boutons TONALS, de la
  lecture seule s'y donnait l'air cliquable) et **une ligne de conséquence par réglage**, le
  reste conservé sous « En savoir plus » (P2-6, `.acct-more`) ; **hors ligne annoncé en neutre**
  au pied (D7 — état nominal, jamais ambre ; `o.offline` entre par l'instantané pour que
  `storageState` reste PURE) ; P3-2/3/4/5/6/8/11/12/13/14 (registres, micro-copies, secondes
  retirées des listes, `sessStamp`). **Écarté** : **G2** (« ✓ Bloc n complet — Continuer vers X »)
  — implémenté puis retiré sur décision utilisateur : le bouton passe déjà au registre
  CONFIRMATION quand tout est coché, et deux formules pour le même geste sont exactement ce
  qu'AC 120-71B proscrit ; le libellé reste **« Continuer — X → », identique aux deux sites**.
  **Constat P2-3 = doctrine périmée, pas défaut de code** (cf. « ORDRE FIXE » plus haut).
  **P2-4 vérifié conforme** (placard invité livré en v4.55.4). Les pistes marquées DÉCISION dans
  l'audit (D2 « Contraste + »/vraie nuit, D3 mode moniteur, E7 valeur de `--bg`, F4 cockpit 3
  zones, F5 police embarquée, F6 tête de bilan, H concepts B/C d'en-tête, I restructuration
  complète, K refonte des éditeurs) **ne sont PAS engagées** : elles créent une capacité, touchent
  un token ou ouvrent un chantier — à trancher une par une, jamais par effet de bord.
- **PASSE ESTHÉTIQUE v4.57.0 (audit design, axes D/E/F — phase 1 de « tout »)** :
  **`--bg` d'un cran plus profond** (#f2f5f8 → #e9edf2, E7) — les surfaces blanches « portent »
  sans ombre supplémentaire, ce qui rend l'élévation à 3 niveaux possible. **LE THÈME SOMBRE
  ADOPTE LES CODES COULEUR DE L'EX-« CONTRASTE + »** (D2, décision utilisateur « c'est le nouveau
  mode sombre » — pas de 4ᵉ cran au cycle) : encre secondaire relevée (#93a5b5 → #b7c6d6, ~7:1 au
  lieu de ~4,9:1) et filets renforcés (#24303f → #3b4b5d, 3:1 = seuil WCAG 1.4.11). **PAS**
  l'encre pleine du bloc `prefers-contrast: more` (là c'est l'utilisateur qui demande d'APLATIR la
  hiérarchie) ni les **graisses +100** que proposait l'audit : la graisse porte déjà l'état sur
  les segmentés, et l'élargir changerait toutes les largeurs de texte — donc les mesures à 320 px
  que quatre harnais surveillent. **TROIS NIVEAUX D'ÉLÉVATION, ÉCRITS** (E1/D6) : plat + filet =
  contenu clinique ; `--shadow` = surfaces VIVES (session, minuteurs, bande-question épinglée) ;
  `--shadow-lg` = overlays — une modale était au niveau 2, donc au même plan qu'une carte de
  session. **Interlettrage des capitales unifié à `.07em`** (E2, 64 déclarations) : relatif et non
  px, il suit la taille du texte. **Micro-réponses au geste** (E5) : lévitation d'1 px au survol
  (POINTEUR FIN seulement — sur tactile le premier tap pose le hover, leçon v4.4.4) et
  `scale(.99)` à l'appui, transform/opacity seulement, inertes sous `prefers-reduced-motion`.
  **Le ⤢ devient un dessin de trait** (E6) — même dessin, même doctrine (grammaire des ouvertures
  plein écran), au trait de la famille d'icônes ; **PIÈGE MESURÉ** : un SVG occupe sa largeur
  pleine là où le glyphe Unicode en occupait moins — 4 px de débordement de la rangée de commandes
  à 320 px, attrapés par `audit-doctrine`, rendus sur la taille de l'ICÔNE (13 px, 11 sous 400 px)
  et jamais sur `.ctrl-sp` (v4.43.0 : ce n'est pas un poste d'économie). **TÊTE DE BILAN du
  compte-rendu** (F6) : durée totale en mono 40 px + compteurs de la fiche en tuiles neutres
  (plafond 4 ; les compteurs à ZÉRO sont montrés — « 0 choc » est une information de débriefing,
  souvent LA question), identique à l'écran et à l'impression.
- **LE SOMBRE DESCEND PRESQUE À ZÉRO, SURFACES EN GRIS NEUTRE (v4.71.0, décision utilisateur sur
  maquette comparative — puis **#0a0a0c au lieu de #000000 en v5.0.0**, sur validation explicite de
  l'audit design : le noir PUR maximise la halation autour du texte clair sur OLED, un effet gênant
  pour les personnes astigmates ; #0a0a0c garde le bénéfice perçu du « vrai noir » sans elle, et
  l'argument du gris neutre — sur un fond aussi sombre, toute couleur porte un sens — tient
  identiquement. ⚠ C'est UN TOKEN : revenir à #000 est un mot si l'essai à l'écran déplaît)** :
  `--bg` #0c1420 → **#0a0a0c**, surfaces #0d0d0f / #070708 / #191a1d, filets
  #33363b, `--input-bg` #000, plus les hors-teintes de survol (`--hover-dk`) — sans elles le
  « gris pur » se lirait bleu au premier passage de souris. **CE QUE LE NOIR OBLIGE À DÉPLACER,
  et c'est le vrai travail** : sur #000 une OMBRE NE DIT PLUS RIEN (assombrir du noir ne produit
  aucun contraste), donc les trois niveaux d'élévation de la v4.57.0 ne peuvent plus reposer sur
  elle — c'est la SURFACE qui monte et le FILET qui borde. Les ombres restent déclarées et ne
  sont pas du gaspillage : une modale se détache encore de la carte qu'elle recouvre, qui n'est
  pas noire. **Aucune encre, aucun registre ne bouge** : le noir est un changement de FOND, pas
  de sémantique. **MÉRITE DU GRIS NEUTRE, à nommer** : sur du gris strictement neutre, TOUTE
  couleur à l'écran porte un sens — registre, catégorie ou accent —, ce qui est exactement la
  règle 8 ; j'avais proposé de garder la famille bleue sur les surfaces (l'app y garde son
  caractère clinique), les deux ont été mesurées côte à côte et le neutre a été choisi.
  **A11Y REJOUÉE avec la palette RÉELLEMENT POSÉE dans le fichier** (et non injectée à chaud) :
  301/301 sur Chromium ET WebKit, contraste calculé sur le fond EFFECTIF.
- **E5 S'ÉTEND AUX SURFACES CALMES, ET À ELLES SEULES (v4.71.0)** : la restriction de la v4.57.0
  aux tuiles d'accueil était un reste de chantier, pas une doctrine — l'audit écrivait E5 pour
  toute l'app. Ce qui EST une doctrine, et qui borne la liste : **en crise, le mouvement est
  réservé à l'alarme** (ECAM). La moitié SURVOL ne pourrait de toute façon pas s'y déclencher
  (`pointer:fine` = une souris, pas le téléphone du terrain) ; c'est la moitié APPUI qui impose
  la borne. **PAS DE BALAYAGE EN GROS** sur `.btn` ni sur `.ai-card` : ces sélecteurs attrapent
  aussi « Terminer la session ? » et l'index des complications, qui s'ouvrent PENDANT un soin.
  La liste est nominative : `.hs-row`, `.ep-row`, `.rev-row`, `.att-row`, `.vers-row`, `.ed-door`
  (+ `.qa-tile`/`.dir-row` d'origine).
- **FENÊTRE COMPTE — M5 (v4.71.0)** : l'identité et les trois actions qui en dépendent vivent
  dans une **carte** `--surface-2` (un groupement, pas une élévation) ; « Synchroniser » **perd
  son remplissage** — on n'ouvre pas ses réglages pour agir, et il était le seul bouton rempli
  d'un écran qui n'a pas d'action primaire. **CE QUI N'EST PAS REPRIS DE LA MAQUETTE** : elle
  range les trois boutons sur UNE rangée, ce qui remettrait « Se déconnecter » au contact du
  bouton le plus tapé de la fenêtre — la v4.5 avait posé un tampon là exprès (« un tap
  légèrement trop bas ne doit pas déconnecter », défaut vécu comme un bug) ; la déconnexion garde
  sa ligne, son tampon et sa confirmation. « Sur cet appareil » devient une **ligne** (~64 px
  rendus) : la v4.56.3 avait rendu les tuiles neutres (P3-1), mais une tuile reste la forme d'un
  OBJET et trois nombres qu'on ne peut ni taper ni régler n'en sont pas ; **les tuiles RESTENT
  pour « État de l'instance » (admin)**, où il y en a dix et où une ligne ne se lirait plus.
  Groupe « Affichage », libellé et contrôle sur la même ligne tant que la place existe.
- **LA PORTE « + » ÉTAIT INCOMPLÈTE, DONC ELLE MENTAIT (v4.71.0, signalé par l'utilisateur)** :
  elle promet « voici tout ce que vous pouvez ajouter » et il en manquait DEUX que la fiche
  accepte pourtant — **le tableau de doses et le document** (maquette MK4 les liste tous les
  deux). Une porte unique qui ne montre pas tout est **pire que six portes dispersées** : avant
  on cherchait, maintenant on renonce. Le document est le seul type qui n'ajoute pas une ligne au
  brouillon — il ouvre le sélecteur de fichier, et le clic doit partir DANS LA MÊME TÂCHE que
  celui de la palette (`renderEditor()` est synchrone), sinon l'activation utilisateur est perdue
  et le navigateur refuse d'ouvrir le sélecteur ; la rangée disparaît en repli KV, qui ne sait
  pas stocker de binaire (un bouton mort vaut moins qu'une absence). **CE QUI RESTE HORS DE LA
  PORTE** : « Étape / Étape critique / Étape vigilance », que MK4 y range — un « + » = une
  PORTÉE (MK-flux), la palette ne vit qu'ENTRE les blocs où une étape n'a pas de bloc d'accueil.
  L'intention pédagogique de MK4 (« les registres s'apprennent ici, avant la crise ») n'est pas
  perdue : elle vit dans `.crit-guide`, en tête de chaque bloc, c'est-à-dire là où l'on CHOISIT
  le registre. Deux entrées d'une même liste n'ont jamais le même dessin (règle du menu ⋯) :
  `alarm` pour le minuteur qui SONNE, `stopwatch` pour le temps qui MONTE — elles portaient
  toutes deux « ⏱ ». Et le document passe par l'icône de trait, pas par « 📎 » : un emoji en
  COULEUR dans une liste monochrome, quand la couleur ne décore jamais ici.
- **ÉCHELLE TYPOGRAPHIQUE FERMÉE — SEPT PALIERS, ET UN GARDE-FOU (v4.71.1, audit design E2)** :
  `19 · 18 · 16,5 · 15,5 · 13,5 · 12 · 11`. Avant, la feuille portait **seize** corps entre 10 et
  19 px (11 / 11,5 / 12 / 12,5 / 13 / 13,5 / 14 / 14,5 / 15 / 15,5 / 16 / 16,5 / 17 / 18 / 19,
  plus un 10 sous le plancher). Le problème n'était pas la pureté : **deux textes à 13 et 13,5 px
  ne se lisent pas comme deux NIVEAUX, ils se lisent comme une inattention** — et une hiérarchie
  qu'on ne peut pas lire ne hiérarchise rien. 238 déclarations réécrites.
  **PÉRIMÈTRE : le TEXTE, c'est-à-dire sous 20 px.** Au-dessus vivent les AFFICHAGES (chronos,
  challenge du lecteur, moniteur, tête de bilan) : chacun occupe sa propre surface, ils ne se
  croisent jamais du regard, et les forcer sur l'échelle du texte n'apprendrait rien — hors
  périmètre, délibérément. **DEUX VALEURS DE SERVICE, qui ne sont pas des paliers** : `16` =
  plancher des champs sur écran tactile (règle 9, contrainte du moteur) ; `14` = l'un des quatre
  « A » du sélecteur de taille, dont l'écart de corps EST l'information.
  **`scripts/check-type.mjs` (dans `npm run check`)** rend la règle auto-exécutoire, comme
  `check-colors` pour les couleurs : toute valeur hors échelle échoue, sauf exemption **nommée
  par son sélecteur et motivée** dans le script — une exemption anonyme rouvrirait la porte qu'on
  vient de fermer. Vérifié CAPABLE D'ÉCHOUER (13,2 px introduit, contrôle rouge, fichier restauré
  à l'octet — leçon v4.31.1).
- **LE SÉLECTEUR SEGMENTÉ ACCEPTE N SEGMENTS (v4.71.1)** : `--seg-n` / `--seg-i`, pour la TAILLE
  DU TEXTE qui en a quatre (demande utilisateur : « comme Statique/Dynamique »). **La mécanique à
  DEUX est laissée strictement intacte** — `.seg.i1` continue de piloter la tab bar, « Créer » et
  `#modeSeg` ; le cas N passe par un **`#id`** et non par une classe de plus, parce qu'à
  spécificité égale ce serait l'ORDRE de déclaration qui trancherait (cinquième piège de cascade
  du projet). `bindSegDrag` compte désormais jusqu'à N (`nmax` sort du DOM, l'index de départ du
  bouton ACTIF au lieu de `.i1`, commit à `Math.round`) : le glisser au doigt marche à quatre
  paliers. **LE TAP NE RE-REND PAS** la fenêtre Compte — un `renderAuth()` reconstruirait le
  sélecteur et la pastille SAUTERAIT au lieu de glisser (le défaut que `.seg-replay` avait dû
  contourner ailleurs) ; rien d'autre de la fenêtre ne dépend du zoom, on peint sur place.
  `.ts-seg`/`.st-seg.ts-seg` sont PURGÉS avec le composant qu'ils habillaient (règle 14).
- **ÉTAT DE L'INSTANCE — QUATRE GROUPES, UNE DONNÉE PAR LIGNE (v4.71.1, M5)** : douze tuiles en
  grille obligeaient à balayer un damier pour trouver un chiffre. Libellé en toutes lettres à
  gauche, valeur en mono tabulaire à droite, détail dessous en encre douce ; **la seule action est
  un bouton** — « Examiner · n », qui rejoint LA LIGNE dont il est le geste au lieu de flotter
  au-dessus du bloc (il est donc câblé par `loadInstanceStats`, pas par `renderAuthAccount` : le
  bouton n'existe pas encore quand celui-ci s'exécute). Le constat P3-1 de la v4.56 (« la teinte
  `--primary-soft` donnait à de la lecture seule l'air d'être actionnable ») allait dans le bon
  sens mais s'arrêtait à la couleur : c'est la **forme de tuile** qui promettait un objet.
  `.inst-stats`/`.inst-stat`/`.is-v`/`.is-k` purgés (règle 14). **La barre de stockage montre la
  PART des documents dans le total** — un dénominateur réel : une jauge sans dénominateur est un
  ornement qui a l'air d'une mesure.
- **L'ÉTAT DE MODE S'ANCRE AU COIN HAUT-DROIT (v4.58.0, audit design — concept H/B)** : la pilule
  « ■ Crise » vivait à droite de la bande-titre quand elle était dépliée, puis **sautait au milieu
  de la ligne fusionnée** au défilement — position ET libellé changeaient (« ■ MODE CRISE » ici,
  « ■ CRISE » là). Or c'est l'objet qui doit se lire en moins d'une seconde : il devrait être LE
  plus stable de l'écran. Il est désormais **dans `.hdr-acts`, contre ◐ ⋯** — les deux seuls
  objets qui ne bougent dans aucun des deux états — et **ne dépend plus de `.ttl-on`** : même
  pixel, même mot, déplié comme condensé (vérifié : `hcLeft` identique, 231 px à 360). **CE QUE
  LE CONCEPT B N'APPORTE PAS** : les ~90 px rendus au titre étaient le mérite du concept A (la
  pilule descendait au QUAI), écarté parce que le quai est la rangée de la télémétrie VIVE et que
  pour l'invité il doublonnerait les jetons de partage. Le gain de B est la STABILITÉ, pas la
  largeur — ne pas le vendre pour autre chose. **DEUX AMENDEMENTS À L'AUDIT, tous deux mesurés** :
  (1) il voulait vider la bande-titre de son état ; **cet amendement a été LEVÉ en v4.70.1, cf.
  le point suivant** ; (2) un repli au GLYPHE SEUL sous 430 px rendait
  ~41 px au titre, mais en condensé le bandeau est parti : il ne resterait qu'un carré rouge, la
  couleur et la forme seules pour dire le mode — WCAG 1.4.1 et « la couleur n'est jamais seule »
  l'interdisent. Annulé. **Le liseré de mode 10 px** proposé par l'audit n'est PAS posé : le
  placard hachuré de v4.55.4 est déjà le canal périphérique d'exercice et d'invité, à coût de
  hauteur NUL — un liseré serait un troisième dispositif pour la même information.
- **DEUX ANNONCIATEURS, DEUX OFFICES — LA BARRE DIT LE MODE, LE BANDEAU DIT L'EXCEPTION
  (v4.70.1, demande utilisateur)** : la v4.58.0 avait ancré la pilule au coin haut-droit SANS
  retirer celle du bandeau, si bien qu'on lisait **« ■ CRISE » en barre et « ■ MODE CRISE » en
  bandeau, en même temps, sur le même écran**. La doctrine l'admettait comme une troncature du
  même mot (« Cons. » pour « Consulter ») — mais la troncature sert à faire tenir UN libellé dans
  une place étroite, jamais à écrire deux fois la même chose côte à côte. Règle désormais
  explicite : `#hdrCrisis` est **le seul énoncé du mode**, permanent et immobile ; `.cb-tag` ne
  paraît QUE s'il y a une exception que la pilule ne dit pas à elle seule — « ▪ Vous suivez »
  (la PHRASE + la hachure, là où la pilule ne dit que « Suivi »), « ▲ Exercice », « ■ Aperçu ».
  **Ce n'est pas la redondance de l'alarme** (quai + rail), qui répète une valeur VIVE pour
  qu'elle ne puisse pas être manquée : ici les deux canaux disaient la même CONSTANTE.
  **MESURÉ** : le titre récupère la largeur de l'étiquette et retombe sur une ligne à 360/390/430
  (bandeau 63,7 → 44 px) ; à **320 px** il occupait déjà deux lignes, donc le placard de l'invité
  y reste à **coût nul** — c'est la largeur qui compte (2,1 px de marge à `#crisisCtrl`), et un
  témoin d'`audit-partage` la mesure au lieu de l'affirmer. Au-dessus, poser un placard peut
  repousser le titre d'une ligne : sans effet de bord, car **aucune transition sur place** ne mène
  à ces états (on arrive en invité par l'écran d'entrée ; un lien coupé passe par `freeze`, qui
  garde `mode === 'guest'` ; l'exercice est un acte local). (La miniature de l'aperçu d'éditeur,
  qui portait ici sa propre pilule `.ep-tag`, est SUPPRIMÉE en v4.74.0 avec toute la maquette.)
- **UN HARNAIS QUI PLANTE EN EMPORTE CINQ (v4.70.1)** : `audit-complications` cliquait `#addCx`,
  l'un des SIX boutons d'ajout que la v4.65.0 a remplacés par une porte unique — il levait donc
  une exception depuis cinq versions, et comme `npm run audit` chaîne les quatorze harnais par
  `&&`, **il emportait les cinq suivants** (exercice, lecteur, QR, partage, historique). Ils
  étaient verts parce qu'on les lançait un par un ; la commande d'ensemble, elle, s'arrêtait au
  neuvième. **On lit le CODE DE SORTIE, jamais la dernière ligne d'un `grep`** — un `| grep` rend
  le statut du grep, pas celui de la chaîne. Corollaire de la règle 14 : une suppression de
  composant emporte aussi les SONDES qui le désignaient.
- **COCKPIT TROIS ZONES EN LECTURE, DÈS 1200 px (v4.59.0, audit design F4)** : orientation |
  action | état de front — l'idéal ECAM (E/WD et SD sous les yeux en même temps), et pour un
  binôme hospitalier un poste fixe où l'aide-lecteur voit plan, parcours et minuteurs sans un
  tap. **PALIER 1200, PAS 1000** : l'audit proposait 1000 « puisque le palier existe » ; mesuré,
  à 1000 px les trois colonnes laissent **~390 px** au contenu clinique — moins qu'une tablette
  en portrait, pour ce qu'on lit sous stress. À 1200 : plan 240, action 594 (plafond 860 au-delà),
  rail 360. **Aucun palier nouveau.** Le plan **QUITTE le rail droit** à cette largeur : l'afficher
  aux deux endroits ferait deux sources pour la même structure (la règle qui vaut déjà pour les
  minuteurs nominaux). **L'ORDRE DU DOM RESTE CELUI DE LA LECTURE** — `.read-plan` est posé APRÈS
  `.read-main` et ramené à gauche par `order:-1` : ni un lecteur d'écran ni une tabulation ne
  doivent traverser le plan pour atteindre la checklist. Le plan de gauche est le MÊME
  `ovPlanLadderHtml` désaturé, INERTE au cochage (décision figée) — seul son logement change.
  Le franchissement du palier **re-rend** (`mqCock`), comme `mqRail` et `mqReadWide` : c'est un
  changement de STRUCTURE, pas de style. **PIÈGE VÉCU** : la règle du palier 1200 est déclarée
  DEUX fois (en tête § LARGEURS, puis réaffirmée plus bas — piège de cascade documenté) ; la
  variante `.cockpit` doit suivre aux DEUX sites, sinon elle perd à l'ordre.
  **TROIS PISTES EXIGENT TROIS COLONNES — LA CLASSE SUIT LE PLAN, PAS LA LARGEUR (v4.73.0,
  signalé à l'usage : « le mode statique s'affiche en entier dans une sidebar à gauche »)** :
  `cockpit` pose une grille de trois pistes FIXES, mais l'`<aside class="read-plan">` n'est émis
  que s'il y a un plan à montrer — jamais en STATIQUE (le tableau EST la vue d'ensemble), ni en
  aperçu de brouillon, ni sur une fiche sans algorithme. Les deux colonnes restantes glissaient
  alors d'un rang : **la checklist atterrissait dans la piste de 240 px** et le rail dans celle de
  860 (mesuré à 1280 px : `main` x=18 w=240, `side` x=284 w=592). La condition est donc l'existence
  du plan lui-même — d'où le calcul de `ladRail` AVANT celui de `cockpit` dans `renderRead`.
  **ET LE PLAN SE REPEINT (même version, même signalement : « le plan de gauche ne se met pas à
  jour »)** : son HTML vivait dans une IIFE de `renderRead`, donc hors d'atteinte des re-rendus
  CIBLÉS — il gardait l'état du moment où la fiche avait été OUVERTE. Le défaut datait de la
  v4.23.0 (rail droit) et le cockpit n'a fait que le mettre sous les yeux. `railLadHtml(f)` est
  extraite, `repaintRailLad()` la rejoue depuis `renderOvOnly` (navigation) ET `ovAfterCheck`
  (cochage, y compris DISTANT — il y passe) ; le défilement propre de la colonne est capturé et
  restauré (règle « DÉFILEMENT PRÉSERVÉ, PAS RECONSTRUIT »), et les écouteurs délégués sont
  recâblés par `bindRailLad`, dont le renvoi `[data-plref]` défile désormais dans le conteneur
  RÉEL (`.read-plan` en cockpit, `.read-side` sinon — viser le rail droit en dur ne déplaçait rien).
  **UNE SEULE PEINTURE, jamais deux** : rien ne bouge dans la colonne d'ACTION, donc rien sous le
  doigt, et l'on n'introduit pas une seconde peinture qui divergerait (leçon v4.42.0).
  **HARMONIE — L'ÉCHELLE EST UNE SURFACE** : elle était posée à NU sur `--bg`, seule zone de la vue
  lecture à ne pas être une surface, entre une colonne d'action et un rail faits de cartes blanches ;
  ses filets se lisaient comme des restes de trait. `--surface` + filet + rayon, **dans les DEUX
  logements** (c'est le même composant — deux habillages en feraient deux composants), sans
  rétablir aucun aplat d'état : la désaturation reste entière. Et l'en-tête de zone passe en
  `flex-wrap` avec un titre INSÉCABLE : à 240 px, c'est « PLAN — » / « ÉCHELLE » qui cassait — un
  titre haché n'est plus un titre, tandis qu'un contrôle qui descend d'un rang reste un contrôle.
- **MODE MONITEUR (v4.60.0, audit design D3)** : le téléphone POSÉ devient un afficheur — chariot,
  tableau de bord d'ambulance, second appareil de l'invité. C'est l'ECAM au sens propre : un écran
  d'état qu'on lit **sans le toucher**, à deux mètres. Chrono de session, PROCHAIN minuteur (nom
  en casse de phrase + temps en `clamp(64px,20vw,190px)`), dernier repère horodaté.
  **AUCUN CONTRÔLE, ET C'EST LA PROPRIÉTÉ QUI COMPTE** : un tap n'importe où revient à la fiche —
  une surface sans commande ne peut pas être actionnée par mégarde, ce qu'on veut précisément d'un
  appareil posé. Coquille plein écran à z 92 (sous le flash d'alarme à 99 ; elle était partagée
  avec le mode lecteur jusqu'à son retrait au lot T14 — le moniteur en est désormais le SEUL
  porteur, et ses règles ne doivent pas partir avec une purge du lecteur), `_histArm()` à
  l'ouverture et entrée dans `_histBackAction()` (doctrine v4.30.0 : toute surface plein écran).
  `monPick` est PURE (testée) : un minuteur **ÉCHU l'emporte toujours** (annonciateur ECAM —
  l'écart passe avant le nominal), sinon le plus proche de son échéance parmi ceux qui TOURNENT.
  Registres inchangés : échu = ambre **+ le mot « échu »**, jamais la couleur seule. Le dernier
  repère passe par `tkLabels`, la même source que le compte rendu — aucune seconde vérité, et un
  repère sans étiquette retombe sur « Repère n » plutôt que sur un mot inventé. Rafraîchi par
  `tickAll`, **aucune horloge en plus**. Entrée : menu ⋯ des DEUX rôles, groupe conduite en cours,
  visible seulement session démarrée — jamais dans le chrome de crise (2,1 px de marge à 320 px).
  **PIÈGE DE TEST rencontré** : `lastStart` est un HORODATAGE, pas un délai — posé à 0 sur un
  minuteur qui tourne, il fait croire à `now` millisecondes écoulées et le test mesure alors
  l'ordre de la fiche, pas le tri.
- **UNE VOIX TYPOGRAPHIQUE POUR LES TITRES (v4.61.0, audit design F5)** : le système roulait tout
  en `system-ui` — sûr, mais anonyme. **Source Serif 4** (SIL OFL, sous-ensemble **latin seul**,
  graisse **600 seule**, 21 Ko) prend le titre de fiche, la marque et le titre du compte rendu, et
  **rien d'autre** : les titres sont les seuls survivants du scan sous stress, ils méritent un
  dessin ; le texte courant reste `system-ui`, la police que l'appareil rend le mieux — changer le
  corps d'une aide lue en réanimation n'a jamais été l'objet. **EMBARQUÉE, jamais appelée** :
  l'app fonctionne hors ligne par construction, une police de CDN ne s'afficherait pas là où elle
  sert, et `font-src 'self'` l'interdirait de toute façon. `font-display:swap` — le texte
  s'affiche immédiatement dans le repli, jamais d'écran de titre vide. **Graisse 600 et non 800**
  aux endroits qui étaient en 800 : c'est la seule graisse embarquée, en demander une autre
  produirait une graisse SYNTHÉTIQUE (plus lourde, moins nette). Le compte rendu TÉLÉCHARGÉ
  retombe sur Georgia — voulu : un document autonome ne dépend d'aucun serveur. **PIÈGE `sw.js`**
  rencontré : `check-sw` lit les chaînes d'`ASSETS` littéralement — un commentaire À L'INTÉRIEUR
  du tableau est pris pour une entrée de cache (25 faux problèmes) ; il vit donc au-dessus.
  **LE RELAIS DE LA BARRE PARLE DE LA MÊME VOIX (v4.73.0, question utilisateur : « le texte en
  police serif ne se met pas à jour dans les fiches quand l'en-tête se replie — c'est fait
  exprès ? » — non, c'était un oubli)** : le serif avait été posé sur `#crisisBand .cb-ttl`, et son
  RELAIS `#brandTitle` était resté en `system-ui`. Or c'est **un seul libellé porté tour à tour par
  deux éléments** (« le titre n'est jamais absent, seulement porté par l'un ou l'autre ») : il
  changeait donc de typographie au défilement. `#brandTitle` passe au serif, **graisse 600** (la
  seule embarquée — 700 produirait une graisse synthétique) et **corps inchangé** (16,5 px, un
  palier de l'échelle fermée) : c'est la voix qui s'aligne, pas la hiérarchie.
- **I4 — UNE SEULE GRAMMAIRE DE PROGRESSION (v4.62.0 ; ABOUTIE AU LOT T14, v5.0.0)** : guidé,
  journal et mode lecteur ne sont plus trois surfaces mais **une grammaire à trois densités** — et
  depuis le retrait du lecteur, **il ne reste qu'une surface**. Ce que la v4.62.0 avait unifié
  (structure, verbes, point d'écriture unique) rendait la coquille superflue ; le lot T14 l'a
  constaté à la mesure et l'a retirée.
  **POURQUOI, ET C'EST DOCTRINAL** (argumentaire de l'utilisateur, retenu tel quel) : **ECAM** —
  l'affichage Airbus repose sur UN format unique pour tous les états ; le pilote n'apprend pas
  trois écrans, il apprend UNE grammaire qui se décline. Trois surfaces de progression, c'est
  l'anti-ECAM : trois cartographies mentales pour la même information ; harmonisées, celui qui a
  appris l'écran hôte SAIT déjà lire l'écran invité. **QRH** — un manuel n'a qu'UNE mise en page
  de checklist : celui qui LIT et celui qui EXÉCUTE regardent le MÊME document, et c'est ce qui
  rend possible le cross-check à voix haute (« bloc 2, ligne 2 ») ; si le lecteur voit une autre
  structure que l'hôte, la vérification croisée se désynchronise. **FAA (facteurs humains)** — la
  MODE CONFUSION naît d'un même écran qui se comporte différemment selon le mode SANS signal
  univoque ; la réponse canonique est structure CONSTANTE + annonciateur saillant, pas des écrans
  différents. Ici l'interactivité et le placard changent, la structure jamais.
  **ET L'ARGUMENT D'INGÉNIERIE** : trois surfaces = trois endroits où un correctif peut diverger.
  Ce fichier a payé DEUX FOIS — les copies du cœur de cochage avaient divergé (v4.42.0), et un
  invité scribe CONDUISAIT la checklist depuis le lecteur parce que ses verbes portaient d'autres
  noms (v4.55.0). **CE QUI EST DÉSORMAIS UNIQUE** : (1) `applyCheck` — LE point d'écriture de
  `state.checked` (garde de rôle, trace do-verify, haptique, drapeau de fin) ; les trois appelants
  ne font plus que PEINDRE. (2) Le **vocabulaire** : le lecteur ÉMET `data-ovnext`, `data-ovopt`,
  `data-cxback` — plus de synonymes, donc plus de liste de gardes à tenir en double ; `data-rmok`
  et `data-rmgap` restent propres à la passe challenge-réponse (pas de jumeau ailleurs).
  (3) La **structure** : `stepsListHtml` génère l'unique `ol.steps > li[data-ck]`, la trace de
  vérification comprise — elle était écrite trois fois et avait déjà divergé (le journal peignait
  la trace, la vue guidée non). Le lecteur en est la **densité** `.rm-steps` : bloc entier, ligne
  courante en 22 px sur `.cur-step` — modèle **ECL Boeing** (liste entière + curseur), que
  l'audit v4.28.0 opposait déjà au un-item-à-la-fois (perdre sa place est un mode de défaillance
  premier, Degani & Wiener). **SUPPRIMÉS avec la structure qui les exigeait** (règle 14) :
  `.rm-r` (la réponse vit dans la pilule de la ligne) et `.rm-ctx` (le contexte « précédent /
  suivant » était une reconstruction manuelle de ce que la liste donne).
  **DEUX PIÈGES VÉCUS** : (a) `applyCheck` remet `state.flowEnded` à false, donc le test
  « la fin était actée, il faut re-rendre » de la vue guidée ne se déclenchait plus jamais — il
  faut capturer l'état AVANT l'appel (le journal, lui, teste la PRÉSENCE de `.flow-end` dans le
  DOM, il y était insensible) ; `audit-doctrine` l'a attrapé. (b) `data-rmopt` était un
  **HOMONYME** : « reader option » dans le lecteur, « remove option » dans l'éditeur — et
  `[data-rmopt]` figurant dans `MUTE_SEL`, le bouton « supprimer une réponse » de l'ÉDITEUR était
  bridé en mode invité. Renommé `data-optdel` (leçon « collision de noms », v4.23.2).
- **PHASE K — L'ÉDITEUR (v4.63.0, audit design)** : l'éditeur est l'envers de la crise — on y
  travaille AU CALME, et chaque minute investie là achète des secondes ici. **DEUX CHANGEMENTS
  LIVRÉS, sur l'éditeur existant** (les renversements de geste, K1/K5/K10, ne sont PAS engagés —
  voir plus bas). **K2, LA RELECTURE DOCTRINALE EN UNE SEULE GRAMMAIRE** : les garde-fous
  existaient (`nfGuardTxt`, `stepGuardTxt`) mais DISPERSÉS, chacun sous son champ — l'auteur ne
  savait pas, en fermant, ce qu'il laissait derrière lui. `reviewNotes(f)` (PURE, testée) les
  rassemble : chaque remarque nomme sa CIBLE et l'action proposée ; un volet « △ Relecture · n »
  en pied les liste et **ancre** vers la ligne concernée (flash, sans voler le curseur : l'auteur
  vient de LIRE le bilan, il choisit ce qu'il corrige). **JAMAIS BLOQUANT, JAMAIS ROUGE** — et
  le volet le DIT en toutes lettres (« aucune de ces remarques n'empêche d'enregistrer — c'est
  vous qui connaissez votre service ») : l'ambre est le registre du « on se trompe ici », le rouge
  reste à ce qui tue. Le volet **disparaît quand il n'y a rien à dire** : un panneau qui affirme
  « 0 remarque » est du bruit permanent. **K4, « IDENTITÉ » REPLIABLE** : titre, catégorie,
  bibliothèque, code, validation et état occupaient tout le haut — l'auteur traversait six champs
  administratifs avant d'atteindre ce qu'il vient écrire. Ils vivent dans un dépliant dont
  l'en-tête PORTE déjà titre + code (donc replié, il n'escamote rien qu'on vérifie d'un coup
  d'œil). **Ouvert d'office en CRÉATION, replié en MODIFICATION**, la distinction étant faite sur
  le TITRE VIDE et non sur l'existence de la fiche : dupliquer donne un titre, repartir de zéro
  n'en donne pas. Le statut éditorial reste EN PLUS dans la barre (doctrine v4.3.0 : c'est un
  état, il ne se replie pas). **PIÈGE MESURÉ** : `scrollIntoView({behavior:'smooth'})` ne défilait
  PAS du tout sur 6 400 px d'écart — et aucun défilement du fichier n'est animé ; l'ancrage est
  direct. **NON ENGAGÉ, et pourquoi** : K1 (éditer DANS la grammaire de lecture) et K5
  (l'enregistrement se dit, « ▶ Essayer » devient le bouton rempli) changent le GESTE d'édition,
  K10 (raccourcis à la frappe, import/export markdown structuré) ouvre un parseur ; K6 (le
  discriminant en champ séparé) ajoute un CHAMP MODÈLE, donc touche `migrate`, l'export v3 et
  l'affichage des titres partout. Chacun se décide séparément.
- **K1 + K3 + MK5-b — ON ÉDITE DANS LA GRAMMAIRE DE LECTURE (v4.64.0, maquettes MK de l'audit)** :
  l'éditeur était un FORMULAIRE — champs empilés d'un côté, aperçu de l'autre : l'auteur composait
  à l'aveugle. Désormais **le chapeau EST le cadre rouge**, **un bloc EST sa carte** (anatomie de
  `.ov-block` : mêmes bordures, liseré gauche 4 px, rayon ; ambre pour une décision, neutre pour
  un bloc d'étapes) et **une étape EST sa rangée** (case à gauche, champ à la place du texte, la
  boîte teintée des registres ⚠/△). Ce que l'auteur voit est ce que le soignant verra — le
  garde-fou le plus puissant est visuel. **CE QUI N'EST PAS COPIÉ, DÉLIBÉRÉMENT** : la case reste
  un GLYPHE INERTE. Un éditeur où l'on peut cocher ferait croire qu'on prépare un état ; on rédige
  une aide, on ne la déroule pas.
  **K3 — LES OUTILS SUIVENT LE FOCUS** : trois boutons × huit étapes = vingt-quatre cibles pour un
  écran où l'on écrit UNE ligne à la fois. La rangée ⚠ ✕ ⠿ n'existe que sur l'étape ACTIVE
  (`:focus-within`, donc atteignable au clavier ; le survol est neutralisé sur pointeur grossier —
  sur tactile l'étape active est celle où l'on écrit). Mesuré : **43 px au repos, 123 px active**.
  **MK5-b — RÉORDONNER PAR « PRENDRE / POSER », DEUX TAPS, ZÉRO MAINTIEN** : un tap sur ⠿ soulève
  l'objet et réécrit la page en CIBLES pleine largeur ≥ 44 px ; un tap sur un interstice le pose.
  Pas de maintien ni de glisser — c'est le point de défaillance du drag au doigt (gants, une main,
  véhicule qui bouge). Les boutons ↑ ↓ deviennent redondants et QUITTENT la rangée d'outils.
  `state.edGrab` n'est JAMAIS persisté (c'est un geste, pas un état du brouillon) ; **Échap ou ✕
  reposent l'objet là où il était**.
  **L'OBJET PRIS SE VOIT (v4.73.0, proposition utilisateur : « difficile de l'identifier dans la
  page »)** : le bandeau le NOMME, mais un titre de bloc ressemble à un titre de bloc et une étape à
  une étape — il fallait relire pour retrouver l'original au milieu des interstices. `.grabbed`
  (posée PAR LE MODÈLE, jamais peinte après coup : prendre re-rend l'éditeur) porte un anneau
  primaire, la teinte `--primary-soft` et la mention **« ⠿ EN DÉPLACEMENT »** — la couleur n'est
  jamais seule (règle 8), et le registre est celui de l'ACTION EN COURS, jamais une alerte : prendre
  un objet n'est ni une erreur ni un danger. L'objet reste **pleinement lisible** (on ne l'estompe
  pas : l'auteur doit relire ce qu'il déplace, et un texte à demi-opacité tombe sous AA), rien ne
  clignote, et c'est un `outline` — pas une bordure — pour ne déplacer aucun pixel du contenu. **GARDE-FOU QRH** : sortir une étape ⚠ de son bloc change son
  contexte — la cible s'annonce alors en △ AVANT le dépôt, sans jamais l'interdire (l'auteur reste
  l'expert de sa fiche). **PIÈGE DE MISE EN PAGE** : les étapes d'un bloc vivent HORS de
  `.list-edit` — leur rangée n'avait donc aucune règle de flex, et les trois objets s'empilaient
  dès l'ajout de la case. **PIÈGE DE SONDE** : la bibliothèque est VIDE au premier démarrage ; une
  sonde d'éditeur doit passer par « Commencer » puis « Ajouter les fiches d'exemple », comme les
  autres harnais — sans quoi elle mesure une page sans fiche et conclut à tort.
  **K5 — L'ENREGISTREMENT SE DIT, IL NE SE DEMANDE PAS (v4.72.0 ; reporté en v4.64.0, livré sur
  accord explicite)**. L'éditeur s'auto-enregistrait DÉJÀ depuis la v4.5 — mais dans un PARC, et
  il fallait quand même appuyer sur « Enregistrer » : l'écran portait une action primaire dont le
  seul effet était de tenir une promesse que la machine tenait déjà. Ce qui change est la
  PROMESSE AFFICHÉE, pas la mécanique.
  **UN SEUL POINT D'ÉCRITURE, `edCommit`** — à l'éditeur ce que `persistLive` est à la session et
  `_putSessionSafe` à l'historique : toute mutation ajoutée demain est couverte sans qu'on y
  pense. **DEUX ACCROCHES, et deux seulement** : la SAISIE par délégation `input` sur `main` (elle
  bulle, donc tout champ futur est couvert) et les gestes STRUCTURELS par `renderEditor()` /
  `renderProtocolEdit()`, qui les terminent tous. Chercher un à un les cinquante gestes de
  mutation aurait produit la même liste à tenir à jour que celle des soixante verbes que
  `persistLive` a précisément permis de NE PAS écrire.
  **IL COMMIT UNE COPIE NORMALISÉE, JAMAIS LE BROUILLON** : la normalisation retire les lignes
  vides — appliquée au brouillon vivant, elle supprimerait la ligne où l'auteur est en train de
  taper. **ET RIEN NE S'ÉCRIT SI RIEN N'A BOUGÉ** : `renderEditor()` court aussi à l'ouverture,
  sans ce test ouvrir une fiche pour la relire la ré-écrirait (updatedAt + dirty), la ferait
  remonter dans la file de synchro et gagner toute résolution LWW — « modifiée » pour avoir été
  regardée.
  **SANS TITRE, RIEN N'ENTRE** : une fiche anonyme n'a pas de nom sous lequel apparaître, et une
  rangée « Sans titre » se rangerait sous « # » dans un répertoire A→Z. Tant que le titre manque,
  c'est le PARC qui sert de filet — il n'a plus d'autre rôle.
  **CE QUI NE FAIT PLUS UN BROUILLON** : un ACTE éditorial, le statut passant de « ○ Brouillon »
  à « △ À relire » ou « ✓ Validée ». Le modèle a ces trois états depuis la v4.3.0 ; inventer une
  seconde notion de « pas encore enregistré » à côté de « pas encore validé » ferait deux
  vocabulaires pour une idée. **UN BROUILLON NE S'ÉPINGLE PAS** (la rangée de tuiles est l'accès
  de CRISE) — mais il se DÉSÉPINGLE toujours, sinon une fiche épinglée puis repassée en brouillon
  resterait coincée là. Le répertoire le montre et la recherche le trouve : on ne cache rien.
  **TROIS CHOSES QUI VIVAIENT DANS « ENREGISTRER » ONT DÛ TROUVER UN AUTRE FOYER** — et c'est le
  vrai travail de cette version : (1) la CONFIRMATION DE PUBLICATION suit désormais le geste qui
  la déclenche, le sélecteur de bibliothèque (refus → retour à la valeur d'avant) ; à chaque pause
  de frappe ce serait une fenêtre toutes les quatre secondes. (2) La SESSION VIVE se termine à
  l'OUVERTURE de l'éditeur, au registre danger — avec l'écriture continue, le premier caractère
  la tuerait en silence, peut-être pendant que quelqu'un la déroule. (3) Le MÉNAGE DESTRUCTIF
  (images d'un protocole que plus rien ne référence, blobs d'un brouillon jamais publié) reste à
  la SORTIE : le faire pendant la frappe effacerait une image à l'instant où l'auteur en retire la
  référence pour la remettre trois mots plus loin.
  **LE FILET QUI REMPLACE LE « ANNULER »** : un point de version posé à l'OUVERTURE, un seul par
  séance. Un point par écriture noierait l'historique sous le bruit de la frappe, ce qui
  reviendrait au même que pas de filet du tout.
  **« ▶ ESSAYER » — UNE SESSION QUI NE LAISSE RIEN.** L'aperçu refusait toute session : on voyait
  un rendu inerte, donc jamais le COMPORTEMENT de ce qu'on venait d'écrire. Il a maintenant son
  propre Runtime (`freshRuntime` sur la copie, `essai:true`) — sans lui, cocher et naviguer
  marchaient (`state` suffit) mais ni minuteurs, ni compteurs, ni chrono, qui vivent sur le
  Runtime. **L'ÉTANCHÉITÉ TIENT EN TROIS POINTS, tous en tête des fonctions qui écrivent** :
  `ensureStarted` n'entre pas dans `liveSessions` ; `persistLive` sort AVANT `shareEmitDiff`
  (placée après, un auteur qui essaie pendant un partage enverrait ses coches sur l'écran d'en
  face) ; `endSession` arrête les minuteurs et s'en va sans rien archiver. Écraser le Runtime
  global ne perd rien : une session réelle vive n'y est pas rangée, elle vit dans `liveSessions`.
  **CE N'EST PAS LE MODE EXERCICE** : l'exercice est une répétition RÉELLE, enregistrée, ségrégée
  et restituée au débriefing, sur une fiche publiée ; l'essai porte sur un brouillon en cours
  d'écriture et n'a rien à restituer. Harnais : `scripts/audit-k5.mjs` (16 contrôles).
  **L'APERÇU CESSE DE SE DIRE DEUX FOIS** : la v4.70.1 l'avait rangé parmi les EXCEPTIONS du
  bandeau — erreur de classement. Une exception est ce que la pilule de la barre ne dit pas à elle
  seule (« ▪ Vous suivez » porte une phrase et une hachure, « ▲ Exercice » protège d'une méprise
  clinique) ; « Aperçu » n'a ni l'une ni l'autre. La barre suffit, comme pour la crise ordinaire.
  **K3/K8/K9 — LA PORTE « + », UNE SEULE (v4.65.0, maquette MK4)** : six boutons d'ajout vivaient
  dispersés dans trois fieldsets (bloc d'étapes, décision, chronomètre, minuteur à cycles,
  compteur, complication) — pour savoir ce qu'on POUVAIT ajouter il fallait faire défiler la page
  entière, et rien ne disait à quoi chaque type sert. Une seule porte pointillée les rassemble, et
  **chaque type se présente** : glyphe, nom, et UNE ligne dans les mots du soignant. **C'est là
  que les registres s'apprennent, avant la crise** — « ce qui TUE si on l'oublie » et « là où l'on
  se TROMPE » sont écrits au moment où l'auteur choisit, pas dans un guide qu'on replie. La
  fenêtre passe par `bindModalDismiss` comme toutes les autres (Échap, voile, focus, retour
  système) ; elle se ferme à l'insertion et l'éditeur se re-rend, sinon la porte demanderait un
  geste pour ouvrir et un autre pour trouver ce qu'elle vient de créer. Les six gestes sont
  intacts : on a supprimé les PORTES, pas les capacités.
  **MK-flux — LE CYCLE EN QUATRE ÉTATS (v4.67.0, maquette Claude Design, décision utilisateur
  après DEUX tentatives ratées)** : (a) v4.64 mettait les outils sous le champ au focus — 43 →
  123 px, et ils poussaient le contenu à l'instant où le doigt y entrait ; (b) v4.66 réservait
  leur espace en permanence — plus rien ne bougeait, mais le champ tombait à 173 px et chaque
  étape gardait son cadre : l'écran restait un formulaire dense. **LA MAQUETTE RÈGLE LE PROBLÈME
  EN AMONT** — au **REPOS, AUCUN CHROME** : la ligne est du TEXTE (ni bordure, ni fond, ni
  outils), exactement ce que le soignant lira ; **38 px, champ à 295 px**. Le champ ne se dessine
  QU'À L'ÉDITION, les outils avec lui, **SOUS la ligne** — et une seule étape est en édition à la
  fois, donc la page au repos est aussi calme que la fiche en lecture. L'`<input>` reste dans le
  DOM en permanence (il porte la valeur et l'auto-enregistrement) : c'est son HABILLAGE qui
  change, donc rien à re-rendre au tap et rien qui saute. **⏎ = ITEM SUIVANT** (une checklist se
  DICTE : la saisie en rafale ne passe jamais par un menu) — l'étape naît JUSTE EN DESSOUS, vide,
  focus dedans, en étape NORMALE : les registres ⚠/△ se posent APRÈS, par l'interrupteur, parce
  qu'on écrit d'abord et qu'on qualifie ensuite. **CHAMP QUITTÉ VIDE = L'ITEM DISPARAÎT, SANS
  DIALOGUE** — jamais pendant la frappe (effacer pour reformuler supprimerait la ligne sous le
  doigt), jamais la dernière (un bloc garde une ligne où écrire), jamais pendant un déplacement.
  **UN « + » = UNE PORTÉE** : la palette ne vit qu'ENTRE les blocs et ne liste que le niveau BLOC
  — « Étape » n'y figure PAS, le « + Étape » du bloc et ⏎ s'en chargent ; la position du bouton
  choisit la portée à la place de l'auteur. Chaque type dit sa CONSÉQUENCE en deux mots
  (« 2 branches », « durée + libellé »), pas sa définition.
  **LE DESSIN DES BOX ET DES BOUTONS (v4.68.0, d'après la maquette MK)** : l'en-tête de bloc porte
  la **pastille numérotée** de la lecture (ronde et bleue ; losange ambre pour une décision) au
  lieu d'une pilule « ÉTAPES » ; le **chapeau porte son compte « n/4 »** et la porte dit ce qui
  RESTE (« ＋ Rappel (1 restant) ») — un plafond qu'on voit approcher informe, il n'a pas à crier
  avant d'être franchi, et le garde-fou ambre ne parle qu'AU-DELÀ ; le **✕ s'écarte** des réglages
  (`.li-sp` le pousse au bord) parce qu'un geste destructeur ne se met jamais au contact d'un
  interrupteur d'état — sinon le pouce corrige et supprime du même geste ; la **poignée ⠿** vit à
  droite de la ligne et reste visible au repos (c'est une affordance, elle ne se découvre pas au
  tap) ; le champ actif porte la **bordure d'accent** — en sombre `--input-bg` seul est trop
  proche du fond de rangée pour se voir, c'est le TRAIT qui dit « ici on écrit ».
  **LA REMARQUE VIT SOUS LA LIGNE QU'ELLE VISE** (`stepNote`, pure testée) : le volet du pied dit
  COMBIEN il reste à relire, il ne dit pas OÙ pendant qu'on écrit. Corollaire appliqué —
  `stepGuardTxt(steps,'bloc')` ne rend plus QUE la remarque de bloc (nombre d'étapes) : afficher
  la même remarque d'étape à deux endroits pour un seul défaut, c'est du bruit.
  **LIGNE IDENTITÉ ET VOLET DE RELECTURE, COMPACTS (v4.69.0)** : dans le dépliant « Identité », le
  TITRE domine (16,5 px, la taille qu'il aura en lecture), le CODE le suit en pilule mono
  (identité de crise, lisible d'un coup d'œil sans se confondre avec le titre), et « Identité ▾ »
  n'est plus une étiquette posée DEVANT mais le déclencheur à DROITE — le mot ne prend la place du
  titre que là où il agit. Le volet de relecture devient un **dépliant d'une ligne** : replié,
  compte + cibles abrégées ; déplié, ses rangées d'ancrage. Il dit COMBIEN il reste à relire, pas
  une seconde fois QUOI — le détail vit sous la ligne visée.
  **K10 — LES RACCOURCIS À LA FRAPPE (v4.69.0)** : « ! » ou « ? » en tête d'étape, suivis d'une
  ESPACE, posent le registre (⚠ / △) et **disparaissent du texte** ; le champ est réécrit sur
  place, la rangée reçoit sa classe, aucun re-rendu. Un éditeur markdown LIBRE reste refusé (il
  casserait registres, style télégraphique et une-action-par-ligne) — c'est la VITESSE du texte
  qu'on récupère, pas sa liberté. Deux caractères, et **seulement en tête** : un « ? » au milieu
  (« Rythme choquable ? ») n'est pas un raccourci. **PIÈGE MAJEUR DÉCOUVERT À LA MESURE** :
  `STEP_CRIT_RX` reconnaît DÉJÀ « ! » comme marqueur critique (format historique). Déduire le
  registre du modèle AVANT d'évaluer le raccourci le rendait donc inatteignable — et laissait le
  « ! » dans le texte, cumulé avec le ⚠ (« ⚠ ! Choc immédiat », mesuré). Le raccourci s'évalue
  AVANT ; ne pas réinverser.
  **K7 — LE MINUTEUR SE RÈGLE DANS SA CARTE, ET L'ALARME DIT L'ACTION (v4.70.0)** : la rangée de
  champs devient la CARTE du rail (nom, précision en méta, durée, type) plus un champ **« à
  l'échéance »** — nouveau champ modèle `onDue`, FACULTATIF, défaut vide (règle 12), borné à 120
  caractères. `onTimerFired` l'annonce alors à la place du seul nom : **une alarme qui nomme le
  minuteur dit QUOI a sonné, jamais QUOI FAIRE** — poser l'action au pied de l'alerte est la règle
  ECAM, et c'est l'auteur qui la connaît. Sans `onDue`, comportement inchangé.
  **K11 — LE POSTE D'ÉCRITURE À 1200 px** : structure | la fiche | aperçu. La colonne STRUCTURE
  EST le futur « Se repérer » (K9 : l'auteur ne dessine jamais le plan, il DÉCOULE de la
  structure) — une ligne par bloc, son compte d'étapes, tap = ancrage au centre. Elle n'agit
  jamais : ni champ, ni geste destructeur — même règle que le plan inerte en lecture. Posée APRÈS
  la colonne de travail dans le DOM et ramenée à gauche par `order` (le clavier ne la traverse
  pas), au palier **1200** comme le cockpit de lecture, et masquée sous ce seuil.
  **K6 — LE DISCRIMINANT A SON CHAMP (v4.70.0)** : « adulte », « pédiatrique », « femme
  enceinte » — c'est LUI que la troncature mange en premier, et deux titres identiques sur un
  écran de crise sont un piège. Champ modèle `discriminant`, FACULTATIF, 60 caractères ; **aucune
  migration ne DEVINE** — on ne découpe pas le titre d'un auteur pour en extraire un discriminant
  supposé, ce serait réécrire son texte. Affiché **là où le titre se tronque** : rangée du
  répertoire, tuile, et bandeau de crise (pilule à part, jamais dans la chaîne qui se coupe).
  **IL VOYAGE** (`SHARE_KEEP` + liste blanche SQL) : il fait partie du NOM, et un invité lisant
  « Arrêt cardiaque » là où l'hôte lit « adulte » serait exposé au piège même que ce champ
  supprime. La règle 15 vise ce qu'on SAISIT PENDANT un soin, pas l'identité de l'aide — dont le
  titre et le code voyagent déjà. **⚠ CE CHAMP EXIGE DE REJOUER `supabase/schema.sql`** : la
  liste blanche du serveur est l'autorité, sans elle le discriminant serait filtré à l'arrivée.
  **RESTE ACQUIS DE v4.66** : **326 px de saut au clic sur « déplacer »** — le re-rendu insère les interstices AU-DESSUS du point regardé, et un
  `scrollIntoView` visait ensuite le bandeau, qui est STICKY donc déjà visible. Prendre et poser
  passent par **`keepAnchor`** (mécanique ECAM du projet) : l'objet pris ne bouge plus que de
  **0,7 px**, le bloc receveur de **0,6 px**. Ne pas réintroduire de `scrollIntoView` ici.
- **L'ÉDITEUR NE PROMET QUE CE QU'IL FAIT (v4.74.0, signalé à l'usage)** — deux INDICATEURS
  d'état mentaient. `edCommit` refuse depuis la v4.72.0 d'écrire une fiche **sans titre**, mais il
  sortait EN SILENCE : la barre restait sur « ⟳ Enregistrement… » et la pastille sur
  « auto-enregistré ». C'est la donnée périmée présentée comme vivante, que ce dossier combat
  partout ailleurs. **ET IL FAUT LE DIRE AVANT LE TEST « rien n'a bougé »** : quand on ajoute puis
  supprime, le brouillon revient EXACTEMENT à son instantané d'ouverture, la garde anti-écriture
  d'`edTouch` sortait la première, et le badge restait figé sur le « ✓ Enregistré » d'avant —
  l'ORDRE des deux tests suffisait à produire le défaut. Registre NEUTRE (« ○ »), jamais ambre :
  il ne manque rien, il reste un geste à faire, et le parc protège la saisie en attendant.
- **UN PANNEAU NE SE FERME QUE SUR LE GESTE DE QUI L'A OUVERT (v4.74.0)** : l'ouverture d'office du
  dépliant « Identité » (K4) se DÉCIDE à l'entrée dans l'éditeur, elle ne se RECALCULE pas à chaque
  rendu. `vide` devenant faux dès la première lettre du titre, le premier geste STRUCTUREL refermait
  le panneau sous les yeux de l'auteur qui y remplissait encore la catégorie et la date. La clé est
  l'ID du brouillon (`state.edIdentFor`/`edIdentOpen`) : changer de fiche redécide, un re-rendu
  jamais. Vaut pour tout dépliant dont l'état d'ouverture dépend d'une donnée que l'auteur ÉDITE.
- **LA COLONNE DE DROITE PORTE L'ALGORITHME (v4.74.0, demande utilisateur)** : depuis K1 (v4.64.0)
  la colonne du MILIEU est le rendu — la carte-maquette « Aperçu en direct » n'ajoutait plus qu'une
  seconde version, forcément moins fidèle, de ce qu'on avait déjà sous les yeux. Ce qui ne se voit
  nulle part en écrivant, c'est la STRUCTURE : le schéma quitte la tête de « Prise en charge » pour
  la colonne COLLANTE (≥ 1000 px ; sous ce seuil il reprend sa place dans le flux, inchangé).
  **IL NE SE REDESSINE PAS À LA FRAPPE** et c'est le comportement d'avant : `buildFlowSVG`
  reconstruit toute la géométrie, le faire à chaque pause de frappe ferait sauter le schéma — d'où
  `bindEditSide` qui ne rafraîchit à l'`input` que le PROTOCOLE (textarea markdown, seul cas où
  l'auteur écrirait vraiment à l'aveugle). Toute la maquette est PURGÉE (13 classes, règle 14).
  **UNE EXEMPTION AJOUTÉE À `audit-a11y` À CETTE OCCASION, nommée et motivée** : `.flow-scroll` est
  hors du plancher de 11 px — ce n'est pas du texte mais un DESSIN à échelle variable (zoom
  25-400 %, plein écran), et chacun de ses mots existe en taille pleine dans le contenu qu'il
  résume. Il n'a jamais été conforme nulle part ; il n'était simplement dans aucun SCOPE avant.
- **LA PORTE « ＋ » EST COLLANTE, ELLE N'EST PAS FIXE (v4.74.0, proposition utilisateur)** : la
  question « pas interdit par ECAM puisqu'on n'est pas en crise ? » a la bonne réponse — SPEC §5
  dit « une seule zone fixe, et en HAUT », et pour les ÉDITEURS elle dit en propre « AUCUN pied
  d'éditeur » : un bouton `fixed` en bas est exactement ce que cette ligne interdit, clavier mobile
  compris. `sticky` n'y touche pas : la porte reste le DERNIER ENFANT de son fieldset, se colle tant
  qu'on est dans « Prise en charge » et se décroche à la fin de la section (bornage natif, comme les
  bandes-questions du statique) — aucune hauteur de plus, aucune couche ajoutée au chrome. Fond
  PLEIN + élévation, sans quoi elle se lirait par-dessus le texte d'un bloc. **Pendant un
  déplacement elle redescend dans le flux** (`.ed-door.flat`) : collée, elle masque le dernier
  « Poser ici », et « créer » n'a rien à faire sous le doigt de qui cherche où POSER.
- **K1, LE MEMBRE QUI MANQUAIT (v4.74.0)** : « Confirmation diagnostique », « Repères
  posologiques », « À vérifier », « Diagnostics différentiels » et « Références » étaient à nu sur
  le fond de page, entre un chapeau à cadre rouge et des blocs en cartes — alors qu'en lecture
  chacune est une `<section class="block">`. La grammaire de la v4.64.0 n'était appliquée qu'à
  moitié. Coquille `.ed-card`, NEUTRE : la couleur reste aux registres.
  **ET UNE SECTION VIDE NE S'AFFICHE PLUS** (« Minuteurs & compteurs », « ⚡ Complications ») :
  depuis la porte unique de la v4.65.0, c'est ELLE qui présente les types disponibles — un titre
  au-dessus du néant n'enseigne plus rien. Même règle que le volet de relecture et que le pied de
  l'accueil (« masqués à zéro session : aucun bouton mort »).
- **LA POIGNÉE ⠿ D'UN BLOC VIT EN TÊTE, À DROITE DU TITRE (v4.74.0)** : elle était en pied, AU
  CONTACT de « Supprimer le bloc » — précisément ce que la v4.68.0 avait corrigé pour les étapes
  (« un geste destructeur ne se met jamais au contact d'un autre bouton »). La règle n'avait pas
  été appliquée à l'échelon du BLOC.
- **ONZIÈME DÉFAUT DE RANGÉE FLEX — LE BANDEAU « DÉPLACEMENT » (v4.74.0, capture à l'appui)** : sur
  iPhone, le nom de l'objet pris tombait à UN MOT PAR LIGNE sur six lignes. « TOUCHEZ UNE
  DESTINATION » (majuscules + interlettrage) et le ✕ de 44 px sont INCOMPRESSIBLES ; le seul objet
  qui pouvait céder — le libellé, seul `min-width:0` de la rangée — cédait jusqu'à 12 px sur 284.
  Remède déjà écrit deux fois (croix du panneau minuteurs v4.55.3, ligne d'état v4.56.3) : on
  EMPILE, et le ✕ est ANCRÉ en haut à droite avec sa place réservée par un rembourrage.
- **UNE RANGÉE DE BIBLIOTHÈQUE, UN SEUL SURVOL (v4.74.0, signalé à l'usage)** : depuis que l'aplat
  de sélection vit sur le CONTENEUR (v4.73.0), la micro-réponse E5 du bouton-titre le décollait de
  son propre fond — le titre montait, le crayon restait, l'ombre se peignait par-dessus le bleu.
  C'est `.hs-wrap` qui répond au geste, comme c'est lui qui porte l'état ; `.hs-row` reste inscrit
  dans les listes E5 pour les rangées SANS conteneur (sections, catégories, historique).
- **L'ANNEAU D'ANNULATION DE L'ÉDITEUR (v4.74.2, décision utilisateur)** — le « Annuler » est parti
  avec le bouton « Enregistrer » (K5, v4.72.0) : rien ne défaisait plus une fausse manœuvre, et
  l'écriture étant continue, une suppression était PUBLIÉE avant qu'on ait le temps de la regretter.
  Bouton « ↶ » contre l'état d'enregistrement, plus **Cmd/Ctrl-Z HORS champ de saisie** — dans un
  champ le raccourci reste au NAVIGATEUR, qui fait l'annulation fine mieux que nous ; l'anneau est
  l'outil grossier.
  **IL EMPILE DES POINTS DE REPRISE, ET IL EN FAUT DEUX SORTES — trouvé à la MESURE, pas en
  relisant.** La première version ne couvrait que les gestes STRUCTURELS, au motif que les champs
  ont déjà le Cmd-Z natif : vrai, mais la conséquence ne l'était pas — annuler une suppression après
  avoir tapé trois mots RENDAIT AUSSI ces trois mots, puisqu'un instantané pris avant le geste ne
  peut pas contenir ce qui a été écrit après. La frappe pose donc son propre point, **à la PAUSE**
  (une rafale = un point). **ET L'ANNULATION PASSE PAR `edCommit`, JAMAIS `edTouch`** : la garde
  anti-réécriture d'`edTouch` (celle qui évite qu'ouvrir une fiche la marque modifiée) sort la
  première quand on annule jusqu'à l'état d'ouverture — la bibliothèque gardait alors la version
  modifiée pendant que l'écran affichait l'originale.
  **AUCUN GESTE À RECENSER** : les gestes structurels se terminent TOUS par un re-rendu de
  l'éditeur, la frappe passe TOUTE par `edTouch` — les deux points d'étranglement existaient déjà
  (leçon `persistLive`). **JAMAIS PERSISTÉ, JAMAIS SYNCHRO** : c'est un geste, pas un état du
  brouillon — même statut que `state.edGrab`. Plafond 20 : au-delà ce n'est plus une annulation mais
  une restauration, et elle a son outil (« Versions » + le point de version de chaque ouverture).
- **LES PALIERS AVANT L'ENROULEMENT — LE TROU DE 430 À 441 px (v4.74.2, signalé à l'usage)** : le
  palier de compression suivant est à 430 (`ZOOM_W_STEPS`), donc entre 430 et ~441 la rangée de
  commandes n'a plus la place de la recette large et n'a pas encore DROIT à la recette compressée —
  l'enroulement, qui est le dernier recours de la v4.73.1, y devenait le premier. **ON NE DÉPLACE
  PAS LE SEUIL** (ceux essayés pour cette rangée se sont révélés faux deux fois, et un seuil juste
  ici dépendrait de la fonte du système et de la longueur des libellés) : `fitCtrlRow` MESURE déjà,
  il descend donc d'un palier, re-mesure, et n'enroule qu'après avoir épuisé la compression. Les
  classes posées sont CELLES de `syncZoomWidth` — aucune recette dupliquée, donc rien qui puisse
  diverger — et elles ne stylent que cette rangée. Témoin : six largeurs de 429 à 460 px.
- **LA CARTE DU PARCOURS EST UNE SURFACE (v4.74.2, signalé à l'usage)** : `.ov-block` n'avait AUCUN
  `background`, donc le fond de page, quand `.conf-block`, `.local`, `.forget-strip` et les cartes de
  l'éditeur sont tous en `--surface`. Ce n'était pas une décision — rien ici ne la justifiait — et le
  précédent existe en sens inverse (v4.59.0, l'Échelle « seule zone de la vue lecture à ne pas être
  une surface, ses filets se lisant comme des restes de trait »), plus fort encore depuis que le
  sombre est à #000. C'est la colonne d'ACTION : niveau 2.
- **LE RELIEF DES ÉTAPES REVIENT AU REGISTRE (v4.74.2, signalé à l'usage)** : chaque étape était en
  graisse 800 — le poids d'un titre appliqué à un paragraphe, donc plus rien ne ressortait, ce qui
  est le reproche fait à l'inflation du rouge. **600 pour une étape ordinaire, 800 pour les seules
  `⚠`/`△`** : la hiérarchie passe par le TYPE, ce que la doctrine dit déjà vouloir. Même geste que
  la v4.73.0 sur les chronos. Le CORPS ne bouge pas (16,5 px, palier de l'échelle fermée).
- **LA BASCULE GUIDÉ ↔ STATIQUE GARDE LE BLOC COURANT (v4.74.2, signalé à l'usage)** : c'était
  `scrollTo(0,0)` systématique — et conserver `scrollY` n'aurait rien voulu dire non plus, les deux
  vues n'ayant pas la même hauteur. La seule ancre qui EXISTE des deux côtés est le bloc courant, que
  les deux vues marquent avec la MÊME classe `.cur` (`.ov-block.cur` / `.sv-cell`-`.sv-band`) : c'est
  donc `keepAnchor`. Deux replis vers le haut, tous deux voulus — pas de session démarrée (rien à
  retrouver) et bloc courant hors de l'écran (même test de visibilité qu'`ovAdvanceRender`).
- **L'APERÇU D'ALGORITHME SE REPLIE SUR ÉCRAN ÉTROIT (v4.74.2)** : `.flow-scroll` monte à `75vh`,
  si bien qu'on traversait ~1400 px de préambule avant la première étape à écrire (mesuré à 820 px).
  Dépliant `details.flow-prev` REPLIÉ par défaut, compte en sous-titre, choix de l'auteur PERSISTÉ —
  gabarit exact de `.crit-guide` (v4.31.0). À ≥ 1000 px le schéma vit dans la colonne collante et
  n'a pas de dépliant du tout.
- **« PRENDRE / POSER » S'ÉTEND AUX HUIT LISTES (v4.75.0, lot 2)** : les ↑ ↓ étaient un reste
  d'avant MK5-b — plus lents ET moins sûrs (dix taps pour remonter une rangée de dix rangs, un
  re-rendu à chaque tap) — et surtout **CINQ listes n'avaient AUCUN moyen de réordonner** (« À
  vérifier », « Diagnostics différentiels », « Références », « Ne pas oublier », repères
  posologiques) : elles s'écrivaient dans l'ordre où l'on y pensait, définitivement.
  **UNE SEULE SORTE `'l'`, ADRESSÉE PAR LA CLÉ DU MODÈLE** (`{kind:'l',key,i}`) : les listes de
  CHAÎNES et les listes d'OBJETS (`timers`, `counters`) se réordonnent par le même `splice`, donc
  elles n'ont pas besoin de deux mécaniques — un `kind` par type aurait produit huit chemins à
  tenir. Points d'entrée uniques : `edGrabRows` (enrobe les rangées de leurs interstices),
  `edGrabHandleL`, `edDropL`, et un seul binder dans `bindListEditors`.
  **CONFINÉ À SA PROPRE BOÎTE, ET CELA SIMPLIFIE** : les interstices ne sont émis que pour la clé
  prise, donc un objet ne peut PAS changer de contexte — le garde-fou QRH d'`edGrabIsCrit` n'a ici
  rien à annoncer, par construction ; il reste réservé aux ÉTAPES, qui franchissent des blocs.
  **PAS DE POIGNÉE À UNE SEULE RANGÉE** (aucun bouton mort). Ancrage `keepAnchor` aux deux bouts :
  **0 px de dérive à la prise** (mesuré), et au dépôt sur la poignée de la nouvelle place.
- **LE GLISSER AMORCE LE MODE, IL N'EST PAS LE MÉCANISME (v4.75.0)** : MK5-b a écarté le glisser
  comme MÉCANISME pour de bonnes raisons (gants, une main, appareil qui bouge — c'est le point de
  défaillance du drag au doigt), mais l'écarter comme AMORCE était une décision par défaut, jamais
  raisonnée. Or quelqu'un qui essaie de glisser une poignée fait le geste que tout le reste du
  monde logiciel lui a appris : le refuser EN SILENCE laisse croire que rien n'est déplaçable. On
  intercepte donc `dragstart` sur la poignée, on ANNULE le glisser natif (`preventDefault` — pas
  question d'avoir deux mécaniques de dépôt) et l'on entre dans « prendre / poser » en réutilisant
  le CLIC de la poignée : l'utilisateur apprend le bon geste EN FAISANT le mauvais. `dragstart`
  n'existe qu'au POINTEUR — sur tactile rien ne change, et **aucun `touch-action` n'est posé sur la
  poignée** : en poser un empêcherait de faire défiler la page depuis elle.
- **MICRO-ANIMATIONS DU PASSAGE EN MODE DÉPLACEMENT (v4.75.0, proposition utilisateur)** : les
  interstices « Poser ici » entrent en FONDU CASCADÉ (22 ms par rang, borné à six — au-delà, un
  décalage n'informe plus, il fait attendre), l'objet pris fait **UNE oscillation AMORTIE**, et le
  bandeau collant entre par le haut. **L'oscillation ne BOUCLE PAS** : le mouvement continu est
  réservé à l'alarme (ECAM), et un objet qui se balance indéfiniment finirait par se lire comme une
  alerte — or prendre un objet n'est ni une erreur ni un danger. `transform`/`opacity` seulement,
  tout sous `prefers-reduced-motion: no-preference`.
- **L'APERÇU D'ALGORITHME EST ENTREBÂILLÉ, JAMAIS FERMÉ (v4.75.0, demande utilisateur : « un
  néophyte ne verra pas qu'il existe »)** : un titre replié dit qu'une chose EXISTE, il ne dit pas
  CE QU'ELLE EST — et un schéma est précisément ce qui ne se raconte pas. On en montre la tête
  (168 px + fondu vers `--paper`, le fond du CANEVAS : c'est le dessin qu'on estompe, pas la page).
  **PAS UN `<details>`** : un `details` fermé ne rend RIEN de son contenu, et révéler un enfant d'un
  `details` fermé n'est pas fiable d'un moteur à l'autre (le contenu vit dans un slot du shadow
  tree). Conteneur ordinaire + vrai bouton, `max-height`, **aucune transition** (c'est une propriété
  de MISE EN PAGE — check-anim l'interdit) et **aucun re-rendu** au dépliage : le SVG est déjà dans
  le DOM, donc pas une ligne ne bouge et le zoom garde ses écouteurs.
- **`--soft` N'EST PAS UNE ENCRE, ET LA SONDE L'A ENFIN VU (v4.75.0)** : les trois poignées ⠿
  étaient en `--soft` — **2,62:1 mesuré**, sous le seuil AA — alors que la règle est écrite depuis
  la v4.5 (« --soft est DÉCORATIF seulement, jamais une couleur de TEXTE ; texte secondaire =
  --ink-soft »). Le défaut datait de MK5-b et personne ne POUVAIT le voir : les poignées ne vivaient
  que dans `.blk`, qui n'est pas dans le SCOPE d'`audit-a11y`. En les posant dans `.list-edit`
  (lot 2), elles y sont entrées et la sonde a parlé aussitôt. Leçon de méthode : **un défaut hors
  scope n'est pas un défaut absent** — quand un composant déménage, la sonde peut se mettre à voir
  ce qu'elle ne voyait pas, et c'est un bon jour, pas une régression.
- **LA PORTE « ＋ » EST CELLE DE L'AIDE, PAS DU BLOC (v4.76.0, lot 3, signalé à l'usage)** : elle
  créait DÉJÀ des minuteurs, des compteurs, des complications et des repères posologiques tout en
  vivant DANS le fieldset « Prise en charge » — ce n'était donc pas une porte de bloc, c'était la
  porte de l'aide, mal rangée. Elle sort du fieldset, se pose à la FIN du formulaire et colle sur
  toute sa hauteur. Quatre groupes (Structure · Pendant la session · Contenu clinique · Annexes),
  dans l'ordre de LECTURE de la fiche.
  **RÈGLE NOUVELLE, ET SON PENDANT : « PRÉSENT DANS LA PORTE ⇔ MASQUÉ QUAND VIDE ».** Les sections
  « À vérifier », « Diagnostics différentiels », « Références », « Repères posologiques »,
  « Schémas & captures » et « Documents » disparaissent quand elles sont vides et se recréent par la
  porte (avec le focus dans le champ neuf). **DEUX EXCEPTIONS NOMMÉES** : le chapeau « Ne pas
  oublier » et la « Confirmation diagnostique » restent AFFICHÉS même vides et n'ont PAS d'entrée
  dans la porte — ce ne sont pas des extras, c'est la condition d'entrée et les memory items, et en
  QRH ce sont eux qui rendent une checklist SÛRE. Un champ vide y est une INVITATION : la règle « un
  panneau vide est du bruit » vise ce qui AFFIRME quelque chose (« 0 remarque »), pas un champ qui
  attend du texte. Un auteur qui ne VOIT pas « Ne pas oublier » ne l'inventera pas.
  **« Étape » n'entre pas dans la porte** (MK-flux : un « ＋ » = une PORTÉE, l'étape a la sienne
  ENTRE les blocs, plus le ⏎). **Dessin** : pointillé conservé (grammaire de « créer ») mais fond
  TONAL et pastille ronde — le blanc était la couleur de toutes les cartes autour d'elle, donc son
  seul trait la distinguait ; elle reste TONALE, jamais remplie (l'unique bouton rempli de l'écran
  est « ▶ Essayer »). **Elle redescend dans le flux pendant un déplacement** (`.ed-door.flat`) :
  collée, elle masque le dernier « Poser ici », et « créer » n'a rien à faire sous le doigt de qui
  cherche où POSER. Piège résolu au passage : `_edImgMode` avait dû monter au MODULE, la porte
  devant ouvrir le sélecteur de fichier alors que la section « Schémas » est masquée (son bouton
  absent). **`_edImgMode` est PURGÉ en v5.0.0** (chantier des entrées de fichier) : la destination
  voyage désormais avec le geste — `pickFile(kind, onFiles)` prend un callback — au lieu d'être
  mémorisée à côté dans un drapeau qu'il fallait penser à remettre à zéro.
- **UNE IMAGE S'ASSOCIE À UN BLOC DEPUIS LA GALERIE (v4.76.0, demande utilisateur)** : on ne pouvait
  joindre une image QUE depuis un bloc — partir de l'image était impossible, alors que c'est l'ordre
  naturel quand on vient d'en importer trois. Un `<select>` par vignette liste les blocs, montre
  celui qui la porte, et « Aucun bloc » la détache ; **une image ne peut être que sur UN bloc** (on
  détache partout avant de rattacher, sinon deux sélecteurs afficheraient deux porteurs pour un même
  état). **CE QUE CELA COPIE, ET IL FAUT LE SAVOIR** : `b.image` porte la DONNÉE, pas une référence
  — c'est le format existant, et le changer serait un champ modèle de plus (règle 12) illisible par
  les clients antérieurs. Associer duplique donc l'image, et retoucher la vignette APRÈS coup ne
  suivra pas dans le bloc.
- **LE PLACARD DE L'ESSAI EST UNE HACHURE, ET RIEN D'AUTRE (v4.76.0, signalé à l'usage : « le mode
  essayer ne se distingue pas beaucoup d'un mode fiche normal »)** — et le « rien d'autre » est le
  vrai contenu de la décision. La v4.72.0 avait retiré l'étiquette de bandeau parce qu'elle répétait
  mot pour mot la pilule de la barre ; **vérifié à l'écran, la barre porte DÉJÀ les deux énoncés** :
  la pilule « ■ Aperçu » ET le badge « Essai — rien n'est enregistré ». Les mots sont donc couverts
  deux fois ; ce qui manquait était le canal PÉRIPHÉRIQUE, celui qui se reconnaît sans lire. On
  n'ajoute donc que la TEXTURE. La règle 8 (« la couleur n'est jamais seule ») est tenue par la
  barre, permanente et immobile — pas par une troisième copie de la phrase. Bénéfice mesuré : coût
  NUL en hauteur ET en largeur, alors qu'une étiquette de trente caractères repoussait le titre sur
  deux lignes à 400 px. **Hachure NEUTRE (`--surface-3`), registre MEMO** : le bleu est pris par
  l'invité et par l'exercice, et un essai d'auteur n'est ni un rôle ni une répétition clinique.
  La justification a changé de poids depuis K5 : « ▶ Essayer » déroule une VRAIE session (minuteurs,
  cochage, chrono), donc l'écran ressemble trait pour trait à un soin — le risque n'est plus
  esthétique, c'est croire qu'une session est en cours ou qu'elle est enregistrée.
  **L'exercice garde la priorité** ; un essai ne peut pas être un invité (`previewFrom` l'exclut).
- **DOUZIÈME PIÈGE DE CASCADE — UNE COULEUR AUSSI SE VÉRIFIE (v4.76.0)** : `#crisisBand .cb-tag`
  vaut **(1,1,0)** et écrasait le bleu du placard INVITÉ, écrit en `.cb-tag.inv` = (0,2,0) —
  « ▪ Vous suivez » sortait donc en **ROUGE**, dans le seul registre qu'elle ne devait pas emprunter,
  depuis la v4.55.4. La règle d'exercice, elle, était déjà préfixée par `#crisisBand` et gagnait :
  deux placards jumeaux dont un seul avait la bonne couleur. Trouvé en posant le placard d'essai à
  côté. Corollaire : la doctrine « pour une GÉOMÉTRIE, ne jamais dépendre de l'ordre de déclaration »
  **vaut aussi pour les COULEURS** — et un témoin d'`audit-partage` compare désormais l'encre
  résolue à `--primary-dk`, au lieu de l'affirmer.
- **LE COMPTE DE RELECTURE MONTE DANS LA BARRE (v4.76.0)** : le volet-bilan vit en PIED de formulaire
  — c'est sa place, on le lit en fermant — mais rien ne disait, pendant qu'on écrit, qu'il y avait
  quelque chose à relire. Le COMPTE (« △ n ») rejoint donc la barre, le seul endroit qui ne défile
  jamais, et ancre vers le volet en le DÉPLIANT ; le DÉTAIL reste en bas et sous la ligne qu'il vise.
  Registre ATTENTION, jamais rouge (rien n'est bloqué) ; masqué à zéro remarque.
- **TOUTE VUE DONT LA STRUCTURE DÉPEND D'UN PALIER DOIT ÊTRE DANS `_onReadBp` (v4.77.0, signalé à
  l'usage)** : il ne re-rendait qu'en vue `read`, alors que les ÉDITEURS changent de structure au
  même seuil (≥ 1000 px le schéma vit dans la colonne collante, en dessous il est entrebâillé dans le
  flux). Redimensionner laissait la page telle qu'elle avait été RENDUE. Le trou préexistait — les
  trois colonnes de K11 l'avaient aussi — et le lot 1 l'a rendu visible en donnant au schéma deux
  logements très différents.
  **⚠ PIÈGE DE VÉRIFICATION À CONNAÎTRE** : le pane du navigateur intégré ne déclenche **NI `resize`
  NI `matchMedia change`** sur un redimensionnement CDP (vérifié à la sonde). Un franchissement de
  palier n'y est donc PAS éprouvable, et c'est exactement le genre de trou où un défaut survit à une
  vérification manuelle. Playwright, lui, les émet : tout témoin de palier passe par un harnais.
- **UN DÉPLACEMENT EST UN GESTE MODAL (v4.77.0, signalé à l'usage)** — trois moitiés manquaient à
  MK5-b. (1) **ABANDONNER S'ANCRE COMME PRENDRE ET POSER** : le ✕ et Échap faisaient un
  `renderEditor()` nu, et le retrait des interstices remontait l'écran de leur hauteur cumulée
  (mesuré : −223 px au ✕, −446 px à Échap). Un geste ANNULÉ ne doit rien déplacer, pas même le
  regard — d'où `edGrabDrop()`, seul point de sortie, et `edGrabAnchorSel()`. (2) **LA MÊME POIGNÉE
  REPOSE L'OBJET** : un interrupteur qui ne s'éteint que par un ✕ ailleurs à l'écran n'est pas un
  interrupteur. (3) **LE RESTE DU FORMULAIRE EST INERTE**, et c'était le plus coûteux : on pouvait
  modifier ou SUPPRIMER l'objet tenu lui-même, ou celui qui précède la destination, et l'index gardé
  dans `state.edGrab` désignait alors autre chose. Par l'attribut natif `disabled` (grisé + hors
  tabulation + geste bloqué, sans apparence à inventer), pas par du CSS ; seuls restent actifs les
  organes DU déplacement. Ce n'est PAS le patron `share-scribe`, qui garde les contrôles cliquables
  pour ANNONCER un refus — ici il n'y a rien à annoncer.
  **ET LE BANDEAU VIT HORS DU FIELDSET** : émis dans « Prise en charge », il ne s'affichait qu'à
  partir de là — donc pas pour les listes du haut. Il est désormais en tête de formulaire.
  **COROLLAIRE POUR LES TÉMOINS** : un contrôle qui laisse un objet « en main » éteint TOUT ce qui
  est mesuré ensuite. Un témoin doit reposer l'objet avant de sortir (un état laissé derrière soi
  fait échouer les autres pour la mauvaise raison).
  **ET CE QUI EST INERTE DOIT EN AVOIR L'AIR (v4.79.0, demande utilisateur)** : `disabled` suffisait à
  EMPÊCHER le geste, pas à le DIRE — nos boutons portent leurs propres `background` et `color`, si
  bien que le grisé par défaut du navigateur n'apparaissait nulle part. Un ✕ rouge vif et un B
  contrasté qui ne répondent plus, c'est la pire configuration : on croit à une panne, pas à un mode.
  Apparence reprise TRAIT POUR TRAIT du scribe (`body.share-scribe`) — encre douce, filet neutre,
  fond `--surface-2`, ombre retirée, `cursor:not-allowed` : une seule grammaire de « fermé » dans tout
  le fichier. **PAS D'`opacity`** (elle affadirait aussi les registres rouge et ambre des rangées
  signalées, et la doctrine l'écarte pour du texte) ; WCAG 1.4.3 exempte explicitement les composants
  INACTIFS du seuil de contraste, donc on baisse le contraste par l'ENCRE, franchement.
  **LE DÉGRISAGE EST STRUCTUREL, PAS UN GESTE À NE PAS OUBLIER** : la règle porte sur `:disabled`, et
  l'attribut n'est posé que par le rendu où `state.edGrab` existe — reposer l'objet re-rend sans lui,
  l'état visuel s'en va avec l'attribut. Rien à défaire à la main, donc rien à oublier : c'est
  exactement ce que la liste de placards de la v4.78.0 a appris au prix d'un bug.
- **UN CONTENEUR AFFICHÉ EN `:focus-within` VOLE SON PROPRE CLIC (v4.77.0, signalé à l'usage : « le
  bouton ⚠ et le bouton supprimer ne fonctionnent pas, ça replie juste le menu »)** — et le
  diagnostic est une SÉQUENCE, pas un style. `.li-tools` n'existe qu'en `:focus-within` (MK-flux) ;
  presser un outil déplace le focus hors du champ, `:focus-within` devient faux, les outils passent
  en `display:none`, et le `mouseup` retombe dans le vide : **aucun `click` n'est émis**. On voyait
  le menu se replier parce que c'est littéralement ce qui se passait. Remède : `preventDefault()` sur
  `pointerdown`, qui annule la mise au point sans annuler le clic. **Tout ce qu'on logera demain dans
  un conteneur `:focus-within` doit entrer dans ce sélecteur.**
  **ET POUR LE MESURER, DE VRAIS CLICS** : un `.focus()` programmatique ne déclenche pas
  `:focus-within` de façon fiable en headless (même leçon que l'anneau de focus d'`audit-a11y`, qui a
  dû passer par de vraies touches Tab).
- **LE GUIDE ROUGE/AMBRE EST REPLIÉ PAR DÉFAUT (v4.77.0, demande utilisateur)** : la v4.31.0
  l'ouvrait d'office pour qu'un nouveau venu voie la leçon, mais il se répète sur CHAQUE bloc
  d'étapes — une fiche à quatre blocs affichait quatre fois le même paragraphe. La pédagogie est
  ailleurs depuis la v4.65.0 : c'est la porte « ＋ » qui présente les registres au moment où l'on
  CHOISIT. Clé RENOMMÉE (`ac-cg-open`) : réutiliser `ac-cg-folded` aurait rouvert le guide chez tous
  ceux qui l'avaient replié — punir ceux qui ont déjà fait le geste.
- **L'ANCRE D'UNE BASCULE DE VUE EST CE QU'ON REGARDE, PAS L'ÉTAT (v4.77.0, signalé à l'usage)** :
  la v4.74.2 ancrait sur le bloc COURANT, ce qui n'existe que session démarrée — sans elle on
  retombait sur `scrollTo(0,0)`, donc un saut en haut avec l'en-tête qui se redéploie. L'ancre juste
  est le PREMIER BLOC dont le bas passe sous les couches collantes, et elle se TRADUIT d'une vue à
  l'autre par l'id de bloc (`data-ovb` en dynamique, `data-svgo` en statique) — d'où le troisième
  paramètre de `keepAnchor` (ancre d'ARRIVÉE distincte de celle de départ).
- **ON AMÈNE L'AUTEUR SUR CE QU'IL VIENT DE CRÉER — POUR TOUS LES TYPES (v4.77.0, signalé à l'usage :
  « quand je clique sur ajouter une complication, rien ne se passe »)** : rien n'était masqué, mais
  seules les LISTES avaient droit à l'ancrage ; un minuteur, un compteur, une complication ou un bloc
  naissaient hors de l'écran, en bas d'un formulaire de plusieurs milliers de pixels. La règle valait
  depuis la v4.65.0, elle n'était appliquée qu'au quart.
- **DEUX RÈGLES DE SAILLANCE REMISES D'APLOMB (v4.77.0)** : « Noter l'heure » (`.tk-add`) était un
  APLAT BLEU alors que l'écran porte déjà « Continuer — … → », qui fait avancer le soin — un
  horodatage n'a pas le même rang qu'un geste de checklist ; il passe TONAL, cible et place
  inchangées. Et **la porte « ＋ » devient l'unique bouton REMPLI de l'éditeur, « ▶ Essayer » passant
  en tonal** : l'action primaire d'un ÉDITEUR est d'écrire, la porte est l'entrée de l'écriture,
  dérouler son brouillon vient après. La règle « un seul bouton rempli par écran » (v4.0.3) est tenue
  dans l'autre sens. **REFUSÉ** : un second `＋` dans l'en-tête — ce serait la dispersion que la
  v4.65.0 a supprimée. **REFUSÉ AUSSI** : une liste des cinq derniers gestes dans l'anneau
  d'annulation — nommer chaque point de reprise exigerait un libellé PAR SITE DE MUTATION, la liste
  à tenir que `edCommit` et `persistLive` ont permis de ne pas écrire ; trois pressions de « ↶ »
  donnent le même résultat sans ce coût.
- **LES LIBELLÉS DE MINUTEURS ET DE COMPTEURS SE RELISENT APRÈS LE SOIN (v4.77.0, remarque
  utilisateur — exacte)** : ils nomment les repères du JOURNAL DES ACTIONS (la fiche est l'une des
  quatre sources de vocabulaire) et les compteurs du COMPTE-RENDU, où ils sont lus HORS CONTEXTE,
  parfois par quelqu'un qui n'était pas là. Le prompt IA le dit désormais — 2 à 4 mots, l'unité entre
  parenthèses (« Adrénaline (mg) »), jamais « Compteur 1 », jamais une phrase — et `audit-prompt`
  le vérifie. Un réglage d'ÉTAT se présente en LIGNE, pas en bouton pleine largeur : la bascule de
  synchro d'historique rejoint le gabarit des autres réglages (M5), pastille + MOT (règle 8).
- **« SCHÉMAS & CAPTURES » EST UN AGRÉGATEUR (v4.78.0, signalé à l'usage)** : « une image ajoutée
  depuis un bloc via ＋ Image/Capture ne s'affiche pas dans la galerie, alors que l'inverse est
  vrai ». C'était une asymétrie de MODÈLE — la galerie est `f.images[]`, l'image d'un bloc est
  `b.image` (la donnée elle-même), et « ＋ Image » n'écrivait que la seconde : la galerie ne pouvait
  pas montrer ce qu'elle prétend rassembler, et le sélecteur de bloc de la v4.76.0 n'avait rien à
  sélectionner. `edSyncGallery(f)` réconcilie **AU RENDU**, pas au point d'ajout — c'est ce qui
  rattrape les fiches DÉJÀ ÉCRITES, dont les images de bloc n'ont jamais eu d'entrée de galerie.
  Idempotente, purement ADDITIVE, aucun champ nouveau (export v3 inchangé).
  **ELLE N'EST PAS DANS `migrate()`, À DESSEIN** : `migrate` court sur toute donnée ENTRANTE, pull de
  synchro compris, et grossirait `images` sur des fiches qu'on ne fait que LIRE. Ici le geste est une
  ÉDITION — l'auteur a ouvert l'éditeur, l'écriture est déjà sa décision.
  **LE COROLLAIRE, ET C'EST L'AGRÉGATEUR QUI L'IMPOSE (signalé à l'usage : « cliquer sur retirer une
  image ne la retire pas, elle apparaît toujours dans la liste »)** : « Retirer » DANS LA GALERIE
  retire l'image de l'aide ENTIÈRE — galerie ET tout bloc qui la porte. Sinon `edSyncGallery` la
  remet au rendu suivant, et le geste se défait tout seul. Les deux gestes ne font donc PAS la même
  chose, et c'est la seule lecture cohérente de l'agrégateur : « Aucun bloc » (ou le « Retirer » d'un
  BLOC) ne fait que DÉTACHER, la vignette restant disponible pour un autre bloc ; sortir de la
  galerie, c'est ne plus faire partie de l'aide. **Toute réconciliation au rendu crée ce risque** —
  un geste qui retire doit retirer la SOURCE, pas seulement la vue.
- **LE COMPTEUR PREND L'ANATOMIE DE LA CARTE DE MINUTEUR (v4.78.0, signalé à l'usage)** : c'était une
  rangée flex PLATE de sept objets avec `flex-wrap` — sur écran étroit, ⠿ et ✕ atterrissaient
  n'importe où dans l'enroulement, jamais au même endroit d'une rangée à l'autre. K7 (v4.70.0) avait
  déjà résolu le problème pour le minuteur : un EN-TÊTE (nom · ⠿ · ✕) puis les réglages dessous. On
  reprend la même carte, aux MÊMES classes — pas une ligne de CSS nouvelle. `.trow` est PURGÉ
  (règle 14, zéro émission vérifiée), et la poignée s'aligne sur la croix par `align-self:stretch`
  (deux boutons voisins de hauteurs différentes se lisent comme deux objets sans rapport).
- **UN `::before` EST UN ÉLÉMENT DE FLEX (v4.78.0, signalé à l'usage : « tout le champ texte est
  rétréci au profit d'un “En déplacement” qui prend beaucoup de place pour rien »)** : la marque de
  l'objet pris est un `::before` en `width:100%`, donc un ITEM de la rangée comme les autres. Dans
  `.blk .li`, `flex-wrap:wrap` l'envoyait sur sa propre ligne ; `.list-edit .li` n'avait pas cette
  règle, et la marque volait la largeur au champ — **mesuré 712 px → 28 px**. Corollaire : tout
  conteneur flex qui reçoit une marque en `::before` doit enrouler.
- **UNE LISTE DE PLACARDS SE PARCOURT, ELLE NE S'ÉNUMÈRE PAS (v4.78.0, signalé à l'usage :
  « appuyer sur Essayer puis revenir en édition — quand on scrolle, l'en-tête reste hachurée »)** :
  la branche de nettoyage retirait `exo` et `inv` mais pas `ess`, ajoutée en v4.76.0 — le troisième
  placard avait été posé à quatre endroits et oublié au cinquième. La liste est désormais UNIQUE et
  parcourue (`['exo','inv','ess'].forEach`) : ajouter un placard demain n'exige plus de retrouver ce
  site. C'est la même leçon que `MUTE_SEL`/`LEAD_ONLY_SEL` — une liste tenue en double finit par
  diverger, et le défaut est SILENCIEUX.
- **UN BLOC SANS TITRE SE NOMME, IL NE S'IDENTIFIE PAS (v4.78.0, signalé à l'usage)** : le sélecteur
  de cible de complication affichait `b_lz8q3`, qui ne dit rien à personne — et surtout pas lequel des
  deux blocs sans titre on choisit. On donne le RANG (« Bloc sans titre (2) »), seule information qui
  les distingue effectivement, et c'est la position que l'auteur voit à l'écran. `targetSelect`
  (« Étape suivante ») écrivait « (bloc sans titre) » sans rang : il reçoit la même règle.
- **UN RE-RENDU REND LE FOCUS AU CHAMP QU'IL VIENT DE REMPLACER (v4.78.0, signalé à l'usage :
  « appuyer sur le bouton critique/vigilance referme le bandeau — il faut de nouveau sélectionner »)**
  : la bascule ⚠/△ re-rend l'éditeur, donc l'`<input>` est un NOUVEAU nœud, le focus est perdu,
  `:focus-within` tombe et les outils disparaissent. Or qualifier une étape est un geste qu'on
  ENCHAÎNE (⚠ puis △ pour comparer, ou ⚠ puis corriger le mot). `focus({preventScroll:true})` sur
  l'ancre reconstruite — `preventScroll` parce que la position est déjà la bonne : c'est le geste de
  l'auteur, pas une navigation. Vaut pour tout geste qui re-rend PENDANT une édition de ligne.
- **LA PROFONDEUR D'UN OBJET ARRONDI EST SON OMBRE, PAS UN VOILE (v4.78.0, question puis correction
  de l'utilisateur : « l'effet d'ombre blanc est très mal fait et probablement à l'envers ou pas
  adapté à un bouton à bords arrondis »)** — les deux reproches étaient justes, et ils invalident la
  première tentative. J'avais posé un dégradé en `::before` au-dessus de la porte : (1) un dégradé
  ainsi posé est un **RECTANGLE**, ses angles ne suivent pas le rayon du bouton et sur une carte
  blanche il se lit comme une bande grise à bords vifs ; (2) il montait vers `--bg`, la couleur du
  FOND DE PAGE, donc il ÉCLAIRCISSAIT au lieu d'assombrir — à l'envers, littéralement.
  Le bon outil pour un objet arrondi qui flotte est **sa propre ombre**, qui épouse le rayon par
  construction ; et pour une barre collée EN BAS elle doit se répandre **vers le HAUT**, du côté d'où
  vient le contenu. D'où le token `--shadow-up` (les valeurs d'ombre sont tokenisées depuis la
  v4.37.0, jamais écrites en clair dans une règle) : mêmes encres et mêmes alphas que `--shadow-lg`,
  décalage inversé. **ET RIEN D'AUTRE** : pas de voile, pas de translation, pas de second contour —
  une porte qui bougerait attirerait l'œil pendant qu'on écrit.
- **DEUX RÈGLES `:hover` DE MÊME SPÉCIFICITÉ, L'ANCIENNE GAGNE (v4.78.0, signalé à l'usage)** : en
  passant « Noter l'heure » en tonal j'avais ajouté `.tk-add:hover{--primary-100}` SANS retirer
  l'ancien `.tk-add:hover{--primary-hi}`, le remplissage de survol d'un bouton PLEIN — d'où un survol
  SOMBRE sur un fond clair, l'inverse du sens de lecture. Corollaire du piège de cascade déjà
  documenté : quand on change le REGISTRE d'un composant, chercher toutes ses règles d'état, pas
  seulement sa règle de base.
- **UN CHRONOMÈTRE NE SONNE PAS, ET L'ÉDITEUR DOIT LE DIRE (v4.78.0, signalé à l'usage : « un
  chronomètre n'arrive pas à échéance, donc ne sonne pas »)** : le champ « À l'échéance » (`onDue`,
  K7) lui était pourtant proposé — on demandait à l'auteur d'écrire l'annonce d'une alarme qui ne se
  déclencherait jamais. Un chronomètre COMPTE, un cycle SONNE : le champ n'appartient qu'au second, et
  la carte du chronomètre DIT désormais pourquoi (mieux que de le laisser découvrir en session).
- **`input[type=number]` N'HÉRITE DE RIEN (v4.78.0, signalé à l'usage : « il s'est passé quoi avec
  les sélecteurs de chiffres ? »)** : `.field input[type=text]` porte le rembourrage, le filet et le
  rayon de TOUS les champs du projet — mais il est borné à `[type=text]`. Les compteurs vivaient donc
  sur une règle `.trow input[type=number]`, partie avec `.trow`, et les minuteurs sur le style par
  DÉFAUT du navigateur (bordure 2 px « inset ») depuis toujours. Aggravé par une addition à la liste
  qui pose `--line-strong` : **sur une bordure UA, changer la seule COULEUR donne un cadre épais et
  sombre**. Règle : un champ numérique reçoit le gabarit explicitement, il ne le trouve pas.
- **QUAND DEUX OBJETS SE METTENT À PARTAGER UNE CLASSE, TOUT SÉLECTEUR « PAR LA CLASSE » DEVIENT
  AMBIGU (v4.78.0, signalé à l'usage : « le scroll nous ramène en bas du bloc mais pas au bloc
  ajouté »)** : le compteur ayant pris la carte `.tmedit` du minuteur, viser `.tmedit` amenait au
  DERNIER du formulaire — donc au dernier COMPTEUR, les compteurs étant rendus après les minuteurs.
  On distingue par l'attribut qui porte l'index (`data-ti` / `data-ci`). L'ambiguïté ne se voit pas,
  elle se SUBIT — et le témoin ne la rencontre que si l'ORDRE du contrôle l'y expose (créer un
  minuteur alors qu'un compteur existe déjà ; l'inverse tomberait juste par hasard).
- **LA RANGÉE D'ITEM DE L'ÉDITEUR (v5.0.0, lot M1, maquettes `proto-large`)** — quatre écarts de
  maquette corrigés d'un coup, parce qu'ils vivent sur la même rangée. **DEUX CHAMPS, `do` ET
  `expect`** : l'auteur tapait « :: » à la main pour dire une chose que le modèle porte depuis que
  l'étape est un OBJET — une convention à apprendre, et un « :: » écrit dans un texte clinique pris
  pour une séparation. ⚠ PIÈGE MESURÉ : `setStepStr` écrivait `expect = cr.r || ''`, donc retaper le
  geste EFFAÇAIT la réponse attendue — une chaîne SANS « :: » ne dit rien de la réponse, elle ne doit
  pas la détruire ; un « :: » collé depuis un ancien contenu reste reconnu, seul cas où cette
  écriture a encore un sens. **PLUS AUCUNE CASE DANS L'ÉDITEUR** : la v4.64.0 posait « la case reste
  un GLYPHE INERTE » ; la maquette est plus juste — une case inerte dans un éditeur invite au geste
  qu'elle refuse. La MARQUE de registre (`.li-mk`) la remplace : elle DIT le registre au lieu de
  mimer l'action ; `.li-box` purgé, CSS compris (règle 14). En LECTURE les cases restent.
  **LA POIGNÉE ⠿ PASSE À GAUCHE** (décision utilisateur, revirement assumé de la v4.68.0, qui l'avait
  mise à droite pour éloigner le geste destructeur du ✕) : l'écart `.li-sp` fait ce travail, et à
  gauche la poignée est le PREMIER objet de la ligne — là où l'œil la cherche avant même d'avoir lu.
  **LES OUTILS PORTENT LEUR MOT** (`registre`/`vital`/`vérifier`, `mémoire`, `double`) : c'est la
  règle 8 étendue aux glyphes — ★ et ×2 ne s'apprennent nulle part ; le mot s'efface sous 400 px, où
  la rangée n'a plus la place et où le `title` reste. Mesuré : **0 px de débordement à 320 px**.
- **LE RAIL ①②③ N'EXISTE PLUS NULLE PART (v5.0.0, lot M2a, décision utilisateur « le retirer
  partout »)** : le lot T5 l'avait retiré EN SESSION, les maquettes ne le montrent nulle part — hors
  session comprise — et les numéros y vivent sur les BLOCS. **Deux numérotations concurrentes dans la
  même colonne sont deux vocabulaires pour situer un même geste**, ce qu'AC 120-71B proscrit ; celle
  des blocs reste, étant commune au journal, au plan, au statique et au SVG (`flowPlan().order`),
  quand le rail ne parlait qu'à lui-même. Les étages demeurent des SECTIONS titrées (`.care-flat` /
  `.cf-stage`), et la PERMUTATION reste conditionnée au démarrage (avant d'agir on s'oriente).
  `.care-path`, `.cp-stage`, `.cp-n` purgés avec leurs règles et leurs media queries (règle 14) ;
  `.cp-h` survit, c'est le titre d'étage. ⚠ PIÈGE RENCONTRÉ : les intitulés d'étage sont des
  LITTÉRAUX du code, déjà écrits en entités (`Surveillances &amp; pièges`) — les passer par `esc()`
  les affiche tels quels à l'écran. `esc()` est pour la DONNÉE, pas pour le gabarit.
- **LE TYPE EST UN FILTRE, PLUS UNE NAVIGATION (v5.0.0, lot M4, décision utilisateur)** : il vivait
  dans une TAB BAR BASSE fixe, c'est-à-dire dans la grammaire d'une navigation entre SECTIONS — un
  reste du temps où « Aides » et « Protocoles » étaient deux bibliothèques. Depuis qu'elles n'en font
  qu'une (lot T9), le type est un filtre comme la bibliothèque et la catégorie : il prend leur forme
  (`.typebar`, mêmes chips), se pose AU-DESSUS d'elles, et l'on lit du plus large au plus étroit —
  **Type · Biblio · Catég.** Ce que cela rend : **62 px de hauteur permanents** en bas de l'accueil
  (la place que la barre fixe réservait) et une grammaire de moins. `#tabBar`/`#tabSeg` purgés avec
  leur CSS, leur câblage et leur `bindSegDrag` (règle 14) ; la colonne gauche de l'accueil LARGE
  portait déjà les sections, rien n'y change. Le filtre est **délégué** (la rangée est re-rendue avec
  le chrome), là où la tab bar était statique et câblée une fois.
- **UN SEUL RAIL, ET SES COMPTES DISENT LA VÉRITÉ (v5.0.0, lot M4b, demande utilisateur)** : la
  colonne gauche de l'accueil large n'avait que DEUX rangées de type (« Aides cognitives »,
  « Protocoles ») alors que le filtre a TROIS crans depuis le lot T9 — elle ne pouvait donc pas
  exprimer « Tout », c'est-à-dire la vue par DÉFAUT. Pire, `kindArr` retombait sur `fiches` en mode
  « Tout » : **tous les comptes du rail — bibliothèques comme catégories — ignoraient les
  protocoles**. Un compte faux dans un rail d'orientation est pire qu'un compte absent, il fait
  renoncer à chercher là où le contenu est. Le rail porte désormais, de haut en bas : **Type ·
  Bibliothèques (avec le ✎ pour celles qu'on administre, et « ＋ Nouvelle bibliothèque ») ·
  Catégories (avec « Gérer les catégories ») · Historique** — tout ce qui oriente, au même endroit.
  **LE TITRE DE GROUPE DE TÊTE EST SUPPRIMÉ** (une ligne rendue) : « Tout / Aides cognitives /
  Protocoles » se lisent sans qu'on les annonce, quand « Bibliothèques » et « Catégories » nomment
  des collections dont les rangées ne disent pas la nature. L'icône de « Tout » est **celle que
  portait la tab bar** : le geste change de forme, pas de signe.
- **LA LÉGENDE DES REGISTRES VIT SUR LA CARTE, ET ELLE NE DIT QUE CE QUE LE BLOC PORTE (v5.0.0,
  lot M2, maquettes `proto-r4`)** : `⚠`, `△` et la bulle mono ne s'apprenaient QUE dans l'éditeur
  (`.crit-guide`) — donc nulle part pour qui LIT une fiche sans jamais l'écrire, c'est-à-dire pour
  la majorité de ceux qui l'utilisent en soin. C'est le seul endroit du produit où ces trois signes
  se rencontrent. **ELLE EST CONDITIONNELLE, et c'est ce qui la rend admissible** : annoncer « △ à
  vérifier » sur un bloc sans aucune vigilance n'enseigne rien et coûte une ligne à chaque carte —
  c'est la règle « un panneau vide est du bruit », appliquée signe par signe. Un bloc qui n'a aucun
  des trois n'a pas de légende du tout.
- **« ⏱ NOTER » VIT DANS LA CARTE DU BLOC (v5.0.0, lot M2)** : le lot T2 avait rapproché le
  JOURNAL (il se pose juste sous la carte) sans rapprocher le GESTE, qui restait un bouton du
  panneau — donc à lire et à viser ailleurs que là où l'on agit. Horodater EST un geste de bloc :
  on note l'heure de ce qu'on vient de faire ICI. **UN SEUL POINT D'ÉCRITURE** (`tkNoteNow`) : le
  bouton du panneau et celui de la carte appellent la même fonction — deux copies auraient divergé,
  c'est arrivé au cœur de cochage (v4.42.0) et aux verbes du lecteur (v4.55.0). Il ne paraît
  **qu'au BOUT du journal** : noter l'heure depuis une carte passée daterait le présent au nom du
  passé. Il entre dans `MUTE_SEL` (un lien mort le refuse et l'annonce) mais **pas** dans
  `LEAD_ONLY_SEL` — poser un repère est additif, donc ouvert à tous les rôles (v4.55.0).
- **« CONDITION D'ENTRÉE » RÉUNIT LES DEUX MOITIÉS D'UNE MÊME DÉCISION (v5.0.0, lot M3)** : les
  critères de confirmation et les diagnostics à éliminer vivaient dans deux sections de l'éditeur
  éloignées de ~1 200 px, alors qu'ils répondent à UNE question, à un seul instant — « est-ce bien
  cela, et si non, quoi d'autre ? ». C'est le geste QRH de la condition d'entrée : on entre dans la
  procédure, ou l'on n'y entre pas. **RIEN NE CHANGE EN LECTURE** (les critères restent en tête, les
  différentiels dans « Consulter ») : c'est l'ÉCRITURE qu'on rapproche de la décision qu'elle sert,
  et les deux gardent leur clé, donc leur rôle (`entry` et `ddx`). Les sous-listes sont **nues**
  dans le fieldset commun — deux cartes imbriquées feraient croire à deux sections, ce que la
  fusion vient de supprimer. La règle « présent dans la porte ⇔ masqué quand vide » vaut toujours
  pour les différentiels ; les critères restent une INVITATION visible même vide (exception nommée,
  v4.76.0).
- **LES COMPLICATIONS SE RÉORDONNENT COMME TOUT LE RESTE (v5.0.0, lot M3)** : le lot 2 de la
  v4.75.0 avait étendu « prendre / poser » à huit listes en les adressant par la clé du modèle ;
  `excursions` avait été oubliée alors qu'elle a exactement la même forme qu'une liste d'objets.
  Or l'ORDRE compte : c'est celui des rangées de l'index qui s'ouvre en pleine réanimation, et
  l'auteur n'avait aucun moyen de le changer — il était celui où les événements lui étaient venus
  à l'esprit. Aucun mécanisme nouveau, `edGrabRows('excursions', …)` comme les sept autres.
- **LE SOMMAIRE D'UNE RÉFÉRENCE (v5.0.0, lot M5, maquettes `proto-r4`)** : une aide cognitive se
  DÉROULE, une référence se CONSULTE — on y vient chercher UNE section, et sans sommaire il faut
  faire défiler plusieurs milliers de pixels pour savoir ce que le document contient. C'est la
  contrepartie exacte de la colonne « structure » de l'éditeur et du plan de la lecture : un
  document long a besoin d'une carte. **CONSTRUIT APRÈS LE RENDU, jamais dans `mdRender`** — le
  parseur reste PUR et NON interactif (les aperçus sont inertes, et un id posé au parsing
  voyagerait dans tout rendu markdown, aperçus d'éditeur compris) ; les ancres sont posées sur les
  nœuds réels. **Trois titres au minimum** (un sommaire de deux lignes n'épargne pas un défilement,
  il ajoute une colonne) et **jamais sous 1000 px**, où il prendrait la place du texte qu'il indexe.
- **DÉFAUT TROUVÉ À LA RELECTURE — `completionSpots` LISAIT DES CHAMPS SUPPRIMÉS (v5.0.0)** : les
  cinq clés de liste ne sont plus des champs de la fiche depuis que les listes sont un POOL D'ITEMS
  À RÔLE (étape B) ; `f.confirmation` valait donc `undefined` et le volet de relecture ne signalait
  **plus aucun « à compléter » de liste**. Le panneau restait vert sur une fiche qui ne l'était pas
  — la donnée périmée présentée comme vivante. Règle : **après une migration de modèle, tout accès
  par CHAMP est suspect ; on lit par l'accesseur** (`listOf`), et un accès survivant ne lève aucune
  erreur, il rend simplement `undefined` et se tait.
- **UNE RÉFÉRENCE QUI NE RÉSOUT PAS NE SORT PAS VIVANTE DE `migrate` (v5.0.0, défaut de contrat
  mesuré)** : depuis l'étape B, un bloc ne porte que des IDENTIFIANTS d'items. Une **chaîne** dans
  `b.items` était recopiée telle quelle comme identifiant — ne désignant aucun item du pool, elle
  produisait une **RÉFÉRENCE PENDANTE** : le bloc s'affichait **VIDE**, sans un mot, et le contenu
  était perdu à l'import. Or c'est exactement la forme qu'une IA écrit spontanément, et c'est celle
  que le prompt enseignait (« la forme SIMPLE, `"steps": [...]` »). RÈGLE : **une chaîne qui
  correspond à un id du pool est une RÉFÉRENCE ; toute autre chaîne est le TEXTE d'une étape et
  devient un item.** Ce n'est pas une tolérance v3 — le format v4 est inchangé — c'est la forme
  ABRÉGÉE que le prompt documente désormais, et le refus d'avaler une donnée en silence (règle 5 :
  `migrate` est le point d'ASSAINISSEMENT, pas seulement de compatibilité).
  **LE PROMPT EST UN CONTRAT ET IL AVAIT DÉRIVÉ** : `"version": 3`, `"type": "steps"`, `"steps"`,
  `localInfo`, `references`, `complications[]` — tout le vocabulaire d'avant les renommages. Une IA
  fidèle produisait donc un fichier que l'import mutile, et la faute paraissait venir d'elle
  (précédent exact : le `\n` mal échappé de la v4.73.0). Le schéma est désormais en v4 —
  `"kind": "do"|"decision"`, `items` unique clé d'étapes, `local`/`sources`/`excursions`. Trois
  témoins neufs dans `audit-prompt` (23/23), vérifiés capables d'échouer.
  ⚠ **Un témoin qui ne rencontre pas son cas ne prouve rien** : les deux formes vivant maintenant
  sous la même clé `items`, le contrôle de la forme ENRICHIE attrapait le premier bloc — abrégé —
  et mesurait la forme qu'il ne couvre pas. Il sélectionne désormais le bloc dont les entrées sont
  des OBJETS.
- **LA PHASE — CHAMP LIBRE, VALEURS SUGGÉRÉES, HÉRITÉE (v5.0.0, lot M6, décision utilisateur)** :
  la maquette posait trois valeurs FIXES et posait elle-même l'objection — rien n'établit que les
  cliniciens pensent en exactement ces trois-là. On garde le MÉCANISME (regrouper la structure) et
  l'on retire l'IMPOSITION : `b.phase` est un champ LIBRE borné à 40 caractères, `PHASE_CORE` n'est
  qu'une liste de **suggestions** de saisie (Immédiate · 2ᵉ intention · Surveillance · Vérification ·
  Orientation), exactement le patron `TAG_CORE` + `data.prefs.tags` des libellés de journal.
  **ELLE EST HÉRITÉE** (`phaseOf`) : un bloc sans phase reprend celle du bloc précédent, donc
  l'auteur ne la déclare QUE là où elle CHANGE — sans cet héritage il faudrait une décision par
  bloc, c'est-à-dire le coût exact que l'objection reprochait au champ. **Aucune migration ne
  devine** : défaut vide, et une fiche qui n'en déclare aucune se lit comme avant.
- **LE PARCOURS INERTE PORTE LA FICHE ENTIÈRE (v5.0.0, lot M6, maquette `proto-r4`)** : il ne
  montrait que la chaîne des blocs. Trois sections l'encadrent désormais — « ✓ Quand l'utiliser »
  (condition d'entrée + « ça ne colle pas ? → n diagnostics à éliminer »), « ⚡ À tout moment »
  (déjà là) et « △ Surveiller — après les gestes » — et les intertitres de PHASE le regroupent.
  La colonne d'orientation taisait exactement les trois choses qu'on ne trouve pas dans la colonne
  d'action au moment où l'on s'oriente. **LES ÉTAPES SE LISENT SANS DÉPLIER** : un plan qui ne
  montre que des titres et des comptes dit ce qu'il y a, jamais CE QUE C'EST. Le dépliage reste le
  DÉTAIL plus le geste (« → aller à ce bloc ») — deux niveaux, pas un doublon. **Tout y reste
  INERTE** (doctrine du plan, re-confirmée quatre fois). ⚠ PIÈGE : `listOf` s'adresse par la CLÉ du
  modèle (`confirmation`, `verify`, `differentials`), **pas par le rôle** (`entry`, `watch`, `ddx`) —
  la première version lisait du vide et les trois sections ne s'affichaient jamais.
- **L'ACCUSÉ DE RÉCEPTION VIT DANS LE BLOC (v5.0.0, lot M7, maquette + capture utilisateur)** :
  « ✓ 02:16 noté · sans étiquette », les étiquettes proposées, puis « Journal des actions (n) ▾ ».
  **Ce n'est PAS une notification flottante** (règle 11) : rien ne surgit, rien ne recouvre — c'est
  la RÉPONSE à un bouton qu'on vient de presser, dans le flux, sous ce bouton (même distinction que
  `toast(msg,ms,direct)`, v4.55.4). **L'heure est le TEMPS ÉCOULÉ**, comme le chrono du quai : à
  côté d'un « noté », le nombre qui parle est « combien de temps après le début ». État
  TRANSITOIRE (`state.tkAck`), jamais persisté, effacé par `ovDropOpens` au prochain geste de
  navigation — on ne traîne pas un accusé de réception. ⚠ Depuis la CARTE, il faut `renderOvOnly` :
  `renderTkOnly` ne remplace que le panneau du journal, plus bas, et l'accusé n'y apparaîtrait
  jamais.
- **PROPOSER UNE ÉTIQUETTE SANS QU'ON AIT TAPÉ (v5.0.0, lot M7, signalé à l'usage)** : `tkPaintSug`
  n'ouvrait la bouche qu'à partir de DEUX caractères — donc jamais dans le geste le plus fréquent,
  qui est UN TAP et rien d'autre. `tagSuggest` classe par CONTEXTE : étapes du bloc COURANT, puis
  minuteurs et compteurs, puis le reste de la fiche, puis les repères posologiques, puis le noyau
  universel. **AUCUN FILTRE — on RÉORDONNE** (même garantie que `posoRank` et `tagRank`) : un faux
  positif coûte un rang, un faux négatif coûte le mot au moment où on le cherche. `tagShort` abrège
  **à l'AFFICHAGE seulement** : la RÉFÉRENCE voyage entière et se résout en toutes lettres dans le
  journal et le compte rendu — abréger la donnée serait perdre de l'information, abréger la chip ne
  perd rien.
- **L'ORDRE DU RAIL DE FILTRES : BIBLIOTHÈQUE, TYPE, CATÉGORIE (v5.0.0, décision utilisateur)** —
  du plus large au plus étroit. Une bibliothèque est un CORPUS (le vôtre, celui du service) ; le
  type n'est qu'une propriété des objets qui s'y trouvent. La mettre en tête affirme la doctrine du
  lot T9 : **on choisit d'abord OÙ l'on cherche, jamais DE QUEL TYPE est ce qu'on cherche.** Vaut
  pour les chips (étroit) comme pour la colonne gauche (large), qui portent déjà l'une et l'autre le
  ✎ des bibliothèques qu'on administre et le « Gérer » des catégories.
- **LE VOLET DE RELECTURE MONTE DANS LA COLONNE DE DROITE À ≥ 1000 px (v5.0.0, demande
  utilisateur)** : il vivait en PIED, ce qui est sa place quand il n'y a qu'une colonne — on lit un
  bilan en fermant. Mais dès qu'une colonne COLLANTE existe, le reléguer au pied revient à ne le
  montrer qu'au bout d'un défilement de plusieurs milliers de pixels, alors que ce qu'il dit sert
  PENDANT qu'on écrit. **Il ne concurrence pas le schéma** qui occupe la même colonne : l'un est un
  DESSIN qu'on regarde, l'autre une LISTE COURTE qu'on lit — et il est replié par défaut, donc il
  coûte une ligne. Sous 1000 px il reprend sa place au pied : il n'y a alors pas de colonne où le
  mettre.
- **LA BARRE D'ACTIONS DU COMPTE-RENDU (v5.0.0, lot M8)** : sous 560 px elle est COLLANTE au bas de
  la feuille et les boutons occupent toute la largeur — un compte-rendu fait plusieurs écrans, et
  l'action ne doit pas se chercher au bout d'un défilement. **Elle n'enfreint pas « aucune zone fixe
  en bas »** (SPEC §5), qui vise le CHROME d'une vue de CRISE : ici on est dans une feuille de
  débriefing, hors session, et la barre appartient à la feuille, pas à l'application. Au-dessus,
  rangée alignée à droite : la place existe, le geste est rare.
- **TROIS SURFACES REDESSINÉES SUR MAQUETTE (v5.0.0, lots M9/M10, captures fournies)** — et la
  première leçon est un écart que j'avais introduit : **la colonne d'orientation et la vue « toute
  la fiche » ne montrent PAS la même chose**, alors que je les faisais partager le même rendu.
  **(0) ⚠ UN HÉRITAGE DE DESSIN NE SE CORRIGE PAS AU CAS PAR CAS, IL SE REPREND.** Le bloc de
  désaturation `.rail-lad` datait du dessin PLAT, où l'état n'était porté que par la COULEUR DU
  TEXTE du marqueur. Avec la pastille PLEINE de la maquette, sa règle `.pl-line.cur .n{color:
  var(--link)}` peignait l'encre en bleu **sur un fond bleu** : le numéro du bloc courant était
  INVISIBLE (mesuré `color === background === rgb(31,95,166)`). Et **`audit-a11y` ne pouvait pas
  le voir** — la pastille est `aria-hidden`, donc hors de son champ. D'où trois témoins dans
  `audit-doctrine` : un marqueur n'est jamais de la couleur de son propre fond, la colonne n'est
  pas une carte, et **le contrôle rencontre son cas** (au moins une pastille PLEINE mesurée — sur
  des contours gris il resterait vert sur le défaut).
  **PLUS DE CARTE BLANCHE** (maquette) : les rangées vivent sur le fond de la colonne, séparées par
  un filet — une carte ajoutait un cadre autour de ce qui est déjà une colonne, soit deux niveaux
  de surface pour un seul objet. La DÉSATURATION reste, et elle est même plus nette : aucun aplat
  de rangée sauf la courante, aucun texte coloré — **tout l'état vit dans la pastille**, qui est le
  marqueur. Un bloc de DÉCISION n'émet pas de numéro (le losange EST le marqueur) : rien à masquer,
  donc plus de `font-size:0`. Les rangées de queue (complication, surveillance) n'ont pas de
  pastille — un liseré rouge suffit pour la première, rien pour la seconde. L'en-tête tient sur UNE
  rangée (« Parcours inerte » + compte + « ⤢ complet ») : le titre cède par ellipse avant que le
  bouton ne passe à la ligne — **40 px de colonne rendus, mesurés** ; un titre ellipsé se devine, un
  bouton renvoyé à la ligne coûte une rangée entière.
  **(1) LE PARCOURS INERTE (colonne)** : une ligne par bloc — pastille RONDE numérotée (verte ✓
  faite, bleue pleine ICI, contour gris à venir), titre, renvois en MONO dans une colonne de
  droite. La chip de branche est **SEULE sur sa ligne**, au-dessus et en retrait : partagée avec le
  titre elle le comprimait et se lisait comme une étiquette DU bloc, alors qu'elle nomme la BRANCHE
  qui y mène. Pas de liseré coloré sur une rangée ordinaire (l'état vit dans la pastille, la
  position dans le fond) ; le liseré ROUGE est réservé aux complications, seul registre de la
  colonne. Sections de queue : « ⚡ À tout moment · hors numérotation » et « Surveiller après les
  gestes » (mêmes RANGÉES que les blocs — nom, valeur mono : une liste à puces aurait été une
  seconde grammaire pour des objets qui se lisent pareil). **NI « Quand l'utiliser » NI les étapes
  en ligne** : la maquette ne les y met pas, et la colonne tient dans 240 px parce qu'elle ne
  montre rien du contenu.
  **(2) L'ONGLET « PARCOURS » DE « TOUTE LA FICHE » N'EST PAS L'ÉCHELLE** (`ovParcoursHtml`) : on y
  dispose de toute la largeur et l'on vient voir LA FICHE ENTIÈRE — donc des CARTES de blocs
  empilées avec leurs items, imbrication comprise, précédées de la carte « Quand l'utiliser » (la
  condition d'entrée n'a de sens QUE là). ⚠ **LES CASES Y SONT DESSINÉES, ET C'EST UN ÉCART ASSUMÉ**
  à « jamais de cases dans le plan » : cette vue n'est pas un plan mais la fiche montrée d'un bloc,
  et une étape sans sa case ne ressemblerait pas à ce qu'on lira en soin. L'inertie est portée par
  l'ABSENCE de `data-ck` (aucun geste possible, cases `aria-hidden`) et le sous-titre le dit —
  « rien ne s'y coche ». Vérifié : 0 `data-ck`, `state.checked` inchangé après clic.
  **(3) LA FEUILLE « CONSULTER »** : une RANGÉE par entrée — case inerte, intitulé, et la valeur en
  PILULE MONO. C'est la forme d'une référence qu'on CONSULTE : le nom sert à trouver, la pilule à
  lire ; une entrée signalée devient une carte teintée (« normal = ligne, signalé = boîte »).
  ⚠ **CE QUI N'A PAS ÉTÉ REPRIS DE LA MAQUETTE** : elle y remet « DOSES » et « SURVEILLANCES ». La
  v4.25.3 les avait retirées SUR MESURE — 57 % de la hauteur (451 px sur 790) pour du contenu qui
  existe déjà dans le flux, le rail et le Statique, soit QUATRE exemplaires, repoussant de ~450 px
  le seul contenu unique (les différentiels), c'est-à-dire le motif même de l'ouverture. Le DESSIN
  est repris, la duplication non ; à rouvrir ensemble si l'arbitrage a changé. La maquette affiche
  aussi « role: dose » à côté des intitulés — nom INTERNE du modèle, jamais montré à un clinicien.
- **UN DÉPLIANT APPARTIENT À SON GESTE (v5.0.0, lot M11, maquette — mesuré puis corrigé)** : la
  règle 11 interdit le DÉFILEMENT AUTOMATIQUE en session — l'écran ne bouge que sous le doigt de
  celui qui le fait bouger. **Deux gestes l'enfreignaient**, et tous deux étaient invisibles à la
  relecture parce que le code disait simplement « `scrollIntoView` » :
  · taper le **QUAI** ouvrait le panneau minuteurs, qui vit en bas de colonne depuis le lot T5, et
  s'y rendait — **1120 px de saut mesurés à 320 px** (988 à 390), soit plus d'un écran et demi, en
  pleine réanimation, en perdant de vue le bloc qu'on exécutait ;
  · « Journal des actions (n) ▾ » de l'accusé de réception y allait aussi — **484 px**.
  **LE « ▾ » DIT UN DÉPLIANT, PAS UNE NAVIGATION.** Le panneau ouvert PAR LE QUAI se rend juste
  SOUS lui, en tête de la colonne d'action ; le journal se déplie DANS la carte. `state.rtOpen`
  porte donc **l'ENDROIT du geste** (`'dock'` | `'flow'`), pas seulement l'état ouvert/fermé :
  ouvert par la rangée du bas, le panneau s'ouvre en bas — la réponse vit là où le geste a eu lieu
  (même règle que l'accusé « ✓ noté », lot M7). Mesuré après : **0 px de saut pour les deux**, le
  panneau à 19 px sous le quai, le quai immobile.
  **CE QUI A RENDU CECI POSSIBLE** est le correctif du quai (structure séparée des valeurs) : tant
  que le sous-arbre était détruit deux fois par seconde, aucun dépliant ne pouvait lui appartenir.
  ⚠ **ON MESURE LE SAUT, PAS LA PRÉSENCE DU PANNEAU** : un panneau présent 1120 px plus bas est un
  panneau qu'on a perdu, et un témoin qui vérifie seulement qu'il existe reste vert sur le défaut.
  **CE QUI N'ENTRE PAS DANS LE QUAI** : le journal des actions. La maquette ne l'y met pas, et il a
  déjà son entrée là où il sert — dans la carte du bloc (« Journal des actions (n) ▾ », lot M7).
  Le quai NOMME les minuteurs et compteurs depuis le lot T2 ; il n'a pas à nommer un troisième
  objet dont le geste vit ailleurs.
- **EN ÉTROIT, LE JOURNAL VIT DANS LE DÉPLIANT MINUTEURS (v5.4.0, décision utilisateur, vécu en
  situation réelle : « ne pas mettre les compteurs et le journal d'action au même endroit m'a
  perturbé — pour changer l'un puis l'autre on doit passer au-dessus des étapes »)** : minuteurs,
  compteurs et journal des actions sont les trois outils de TRAÇABILITÉ, et ils vivaient à deux
  endroits séparés par toute la hauteur des étapes. UN dépliant désormais (rangée « Minuteurs ·
  compteurs · journal — comptes ») : ouvert du quai, tout arrive ensemble sous le quai (M11
  inchangé, quai immobile) ; ouvert de la rangée, tout arrive sous la carte du bloc — la place
  que T2 avait donnée au journal. **Le geste FRÉQUENT n'y perd rien** : « ⏱ Noter » et l'accusé
  vivent dans la CARTE du bloc (M7) ; le panneau est la vue de DÉTAIL, une consultation, comme
  les minuteurs. En LARGE rien ne change (rail : minuteurs → posologie → Échelle → journal) ;
  une fiche SANS minuteur ni compteur garde le panneau journal autonome. `rtRowLabel` est la
  SOURCE UNIQUE du libellé de la rangée repliée : `renderTkOnly`, quand le panneau n'est pas dans
  le DOM, REPEINT ce libellé au lieu de rendre false — sans quoi un repère posé depuis la carte
  (ou arrivé d'une session partagée) laisserait un compte périmé affiché comme vivant.
  ⚠ COROLLAIRE POUR LES TÉMOINS, payé deux fois en l'écrivant : toute sonde qui cherche `#tkAdd`
  ou compte des rangées `.tk-*` en ÉTROIT doit OUVRIR le dépliant par le vrai geste (`#rtOpen`)
  — l'état, lui, se mesure sur `Runtime`, pas sur le DOM replié (deux témoins d'`audit-partage`
  corrigés ainsi).
- **À ≥ 1200 px, LE CHROME DE CRISE VIT DANS L'EN-TÊTE (v5.4.1, option A′ choisie sur maquette,
  après DEUX itérations refusées — retenir le chemin autant que l'arrivée)** : la bande pleine
  largeur réservait ~110 px pour des contrôles qui ne vivaient qu'à gauche (« du contenu du centre
  perdu », retour utilisateur) ; la première réponse — les loger en tête de la COLONNE DU PLAN —
  a été refusée à l'usage (« trois boutons empilés, peu pratique, on perd de la hauteur ») : elle
  déplaçait le coût au lieu de le supprimer. La destination juste est le CRÉNEAU STATIQUE de
  l'en-tête (`#hdrCrisisSlot`, entre le titre et `.hdr-acts`), qui a l'espace à ce palier : coût
  de hauteur STRICTEMENT NUL — mesuré, l'en-tête reste à 65 px grâce à une COMPACTION du dessin
  (segment 6→2 px, ouvertures 46→36 px, halo ::after maintenant la cible de 44) — une seule
  rangée de chrome au total, et l'« effet de tronquage » disparaît avec la bande, pour TOUTE
  lecture de fiche à ce palier (statique et mono-bloc comprises : le créneau ne dépend d'aucune
  colonne). MÊME PATRON QUE LE PIED DE PAGE NOMADE (`placeCrisisChrome`/`rescueCrisisChrome`) :
  déplacés, jamais recréés — ids, écouteurs et mises à jour chirurgicales (updateRtStrip,
  syncDock) restent vivants ; `body.chrome-hdr` porte l'état, le CSS y neutralise le sticky de
  bande, et `stickBase()`/`stickHeight()` cessent d'additionner des rangées dont la hauteur est
  DÉJÀ celle de l'en-tête (les compter serait les compter deux fois ; `--stick-top` retombe à
  l'en-tête seul, les trois colonnes commencent à ~83 px). **L'exigence ECAM ne bouge pas** :
  l'en-tête est permanent et collant — chrono et minuteur échu ne quittent jamais l'écran,
  vérifié à 800 px de défilement ; la constance positionnelle vaut À L'INTÉRIEUR de chaque
  palier, et 1200 restructure déjà la page (cockpit, v4.59.0). Sous 1200 px, rien ne change :
  les bandes restent la forme du chrome.
- **LE DÉPLIANT DU QUAI EST UN VOLET FIXE — IL SUIT, ET C'EST ADMISSIBLE (v5.4.1, question posée
  par l'auteur : « c'est contraire à ECAM/QRH ? » — non, et voici la ligne)** : ouvert PAR LE
  QUAI, le panneau (minuteurs · compteurs · journal) est `position:fixed` sous les couches
  collantes (`--stick-top`) — il suit le défilement, on garde l'état sous les yeux en parcourant
  les étapes, au prix ASSUMÉ de recouvrir tant qu'il est ouvert. Ce qu'ECAM/QRH interdisent
  n'est pas le recouvrement : c'est le mouvement AUTONOME (règle 11), la zone d'état qui bouge,
  et l'alarme masquée. D'où les bornes, toutes tenues : ouvert et fermé par l'utilisateur SEUL
  (re-tap du quai, ✕, Échap, retour système — `_histArm()` à l'ouverture, entrée dans
  `_histBackAction` AVANT le moniteur), **jamais d'auto-ouverture** (l'échéance s'annonce sur
  place), z-index **14 sous le quai (15)** — même statut de consultation que le menu ⋯, qui est
  déjà un volet fixe de l'en-tête. Hauteur bornée sur `--vvh ÷ --zf` (règle 10), défilement
  INTERNE (`overscroll-behavior:contain`).
  **2ᵉ PASSE, SUR TROIS RETOURS UTILISATEUR (« pas une continuité du quai », « fixed dans
  fixed », « deuxième niveau de scroll »)** : le volet n'est PAS une carte flottante — c'est un
  ÉTAGE de plus du bloc de chrome, comme la barre d'une référence (#refBar : « le fond commun
  fait le BLOC, le filet dit les étages »). PLEINE LARGEUR, collé au quai (le filet bas du quai
  fait la séparation), fond `--surface`, coins vifs, filet bas + ombre pour dire qu'il recouvre ;
  le panneau intérieur PERD sa boîte (bordure 0, rayon 0, fond transparent — deux cadres emboîtés
  se liraient comme deux objets, règle du journal niché) ; et c'est le VOLET lui-même qui défile,
  UN SEUL défileur — l'en-tête ✕/son passe avec le contenu, AUCUN épinglage interne (la fermeture
  vit de toute façon sur le quai, Échap et le retour). **La rangée du
  FLUX garde sa géométrie de poussée** : les deux accès coexistent, chacun son arbitrage
  (pousser sans couvrir / suivre en couvrant) — ne pas les unifier. Le témoin M11
  (« un tap ne déplace pas l'écran ») tient par construction : un volet fixe ne change AUCUNE
  géométrie de flux.
- **LES FAMILLES DU PANNEAU SE NOMMENT (v5.4.1, signalé à l'usage : « minuteurs / compteurs /
  journal peu identifiables — tout se colle et se mélange »)** : une seule zone « Minuteurs &
  compteurs » couvrait TROIS familles — les compteurs n'avaient aucun en-tête et « ＋ Minuteur
  PA » se rangeait APRÈS eux alors qu'il crée un minuteur. Un sous-titre PAR famille désormais —
  MINUTEURS (cartes + minis + « ＋ Minuteur PA »), COMPTEURS, et le JOURNAL qui portait déjà le
  sien — dans la grammaire EXISTANTE de chaque logement : `.tk-head` petites capitales + compte
  `.fam-n` dans le panneau/volet, `.rail-head` + `.rail-n` dans le rail large. Chaque objet
  rejoint sa famille ; l'annonce des comptes (exigence ECAM du rail) devient PAR famille, la
  somme est préservée. Aucun composant nouveau — deux dessins pour une même idée seraient le
  défaut que ce chantier corrige.
- **LE RAIL DROIT SE RÉÉQUILIBRE À 780-1199 px — R1+R2 (v5.4.3, audit demandé par l'auteur puis
  décision sur maquette chiffrée)** : MESURÉ en session réelle (fenêtre du rail 642 px), le rail
  portait 1 625 px de contenu — **60 % enterré sous un pli invisible** (barres de défilement
  masquées au repos), le journal à 583 px dessous, séparé des compteurs par la posologie et toute
  l'Échelle — la séparation exacte que la v5.4.0 avait corrigée en étroit, jamais portée au rail.
  **R1** : le JOURNAL remonte CONTRE les compteurs, en dépliant d'une ligne (`details.rail-fold`,
  résumé = grammaire `.rail-head` + compte `.rail-n`) — les trois familles de traçabilité
  voisines à TOUTES les largeurs ; replié par défaut sous 1200, DÉPLIÉ par défaut en cockpit
  (rail à 4 zones, la place existe). **R2** : sous 1200, l'ÉCHELLE devient un dépliant d'une
  ligne annonçant compte ET position (« ici : ① … », mis à jour par `repaintRailLad` à chaque
  navigation — le résumé est REGÉNÉRÉ, l'attribut `open` du `<details>` survit de lui-même).
  L'ordre v4.23.0 (« l'illimité en dernier ») tient : replié, l'illimité est BORNÉ. CONFORMITÉ
  argumentée à l'auteur : une zone repliée qui S'ANNONCE est plus fidèle à l'ECAM qu'un contenu
  enterré muet (modèle ECL v4.16.4) ; l'état VIVANT (chronos, compteurs, échu) reste déplié en
  permanence ; rien ne se replie tout seul (règle 11) ; même grammaire de dépliant que le chapeau
  et l'index ⚡ (AC 120-71B §5.5) ; cibles 44 px, `<details>` natif (clavier, aria-expanded),
  focus visible, dépliage dans le rail. État TRANSITOIRE par fiche
  (`state.railTkOpen`/`railLadOpen`, SHARE_LOCAL, remis à zéro par openRead) — regarder n'est pas
  régler. DIVERGENCE ASSUMÉE avec la maquette : « Surveiller ensuite » vit DANS le corps de
  l'Échelle et se replie avec elle (sa source reste le flux ③, le rail n'en portait qu'une
  copie). Le titre interne du panneau journal se TAIT dans le dépliant (le résumé le porte —
  deux fois le même mot est ce que §5.5 proscrit). ⚠ LEÇON DE SONDE, payée trois fois en
  l'écrivant : compter les `.rail-title` sans distinguer résumés et corps repliés mesure
  l'intérieur des plis ; et une référence DOM capturée avant un re-rendu est un nœud détaché.
- **LE QUAI EST L'ACCÈS UNIQUE AU PANNEAU EN ÉTROIT (v5.4.2, décision utilisateur : « pourquoi on
  a encore un bloc minuteurs·compteurs·journal sous les étapes ? il appartient maintenant au
  rail »)** : le DOUBLE accès de la v5.4.1 (rangée du flux qui POUSSE sans couvrir / volet du quai
  qui SUIT en couvrant) a perdu sa moitié de flux le jour où le volet a su suivre le défilement —
  la rangée ne payait plus qu'en hauteur permanente sous la carte et en seconde grammaire.
  SUPPRIMÉE (`.rt-collapsed`, `#rtOpen`, `rtRowLabel`, la branche de repeinture de `renderTkOnly`
  — règle 14, émissions vérifiées au grep) ; en étroit, le panneau n'existe plus QUE dans le
  volet, **qui se rend même sans minuteur ni compteur** (le journal y loge — une fiche sans
  minuteur garde son accès par le quai, présent dès qu'une session vit) ; « ＋ Minuteur PA »
  n'écrit plus `rtOpen` (il vit DANS le panneau, déjà ouvert là où l'on appuie). Le rappel du
  quai (« 1 minuteur · 1 compteur ▾ », v5.0.0) devient le SEUL annonciateur de ce qui est caché —
  sa raison d'être renforcée. En LARGE, rien ne change. Limite dite : sur une fiche MONO-BLOC en
  étroit, « Noter l'heure » n'est plus dans le flux (la carte mono-bloc n'a jamais porté le
  bouton M2) — un tap de quai l'atteint ; donner le bouton M2 à cette carte serait le vrai
  alignement, à décider séparément. ⚠ Les témoins qui ouvraient par `#rtOpen` passent par le
  quai (deux dans audit-partage, un dans audit-doctrine).
- **UN DÉPLIANT SE RECONNAÎT AVANT DE SE LIRE (v5.4.0, signalé à l'usage : « j'ai eu du mal à
  identifier les blocs — c'est affiché comme si ça faisait partie du reste de la page ») —
  [v5.4.2 : la rangée qui a motivé cette règle est supprimée (cf. bullet précédent) ; la
  grammaire reste, pour tout dépliant à venir, et la moitié « journal niché » vaut toujours
  dans le volet]** : la
  rangée repliée était une carte BLANCHE `--surface`, le dessin exact du contenu clinique qui
  l'entoure ; son seul signal était un petit « ▾ Afficher ». Elle passe en `--surface-3` — le ton
  du CHROME, distinct de la surface dans les DEUX thèmes ; le contenu clinique reste seul en
  carte blanche — et le déclencheur devient une PILULE bordée `--line-strong`. Niché dans le
  panneau, le journal est une SECTION à filet, jamais une carte dans la carte (deux cadres
  emboîtés se liraient comme deux objets).
- **LA CORRECTION D'HEURE ACCEPTE CE QUI A UN SENS, ET REFUSE EN LE DISANT (v5.4.0, signalé à
  l'usage : « entrer 1547 pour 15h47 ne fonctionne pas — trop strict, en urgence on n'a pas le
  temps »)** : l'ancien format exigeait `H:MM[:SS]` — or le champ est `inputmode=numeric` et le
  clavier numérique d'iOS N'A PAS de deux-points : le format canonique était intapable sur la
  cible principale déclarée. Et l'échec était MUET (saisie jetée, retour silencieux à l'ancienne
  heure) — c'est lui qui faisait croire à un format « encore plus strict » qu'il n'était.
  `tkParseTime` (PURE, 19 témoins) lit les séparateurs libres (`:`, `h`, `.`, espace…) ET les
  chiffres nus par longueur (« 1547 » → 15:47:00, « 154723 » → 15:47:23) ; une valeur IMPOSSIBLE
  est REFUSÉE, plus écrêtée — l'ancien code transformait « 15:87 » en 15:59, une heure FABRIQUÉE
  dans une trace de soin. Sur Entrée, l'illisible laisse le champ OUVERT et le dit (registre
  ATTENTION : glyphe △ + phrase + exemple) ; sur blur on revient à l'ancienne heure mais on
  l'ANNONCE (`#srLive`). **CHIPS DE RECUL « −1 · −2 · −5 min »** pendant l'édition seulement
  (une rangée permanente par repère serait du bruit) : le cas réel est « rattraper un geste noté
  en retard », un tap vaut mieux qu'une heure retapée — même mécanique non destructive (`origT`
  + « ↺ revenir »). ⚠ Le tap d'une chip passe par `preventDefault` au `pointerdown` (le blur du
  champ détruirait la chip avant son click — leçon `.li-tools` v4.77.0) et le commit du blur
  s'abstient quand `relatedTarget` est une chip (chemin CLAVIER).
- **APRÈS UNE MIGRATION DE MODÈLE, UNE COMPARAISON À UNE ANCIENNE VALEUR NE LÈVE RIEN — ELLE SE
  TAIT (v5.0.0, deux défauts signalés à l'usage, même faute)** : `buildFlowSVG` comparait `kind` à
  `'steps'`, valeur disparue à l'étape C (`kind:'do'`) — tout bloc non-décision retombait dans la
  branche « décision », `options` valait `[]`, et **aucune flèche n'était tracée pour les liens
  `next`** ; les branches d'une décision, qui passent par `options`, continuaient de s'afficher,
  d'où un symptôme partiel donc déroutant. On teste désormais `!== 'decision'` : le jeu de valeurs
  de `kind` peut s'étendre, la décision reste le seul cas particulier, et un renommage futur du cas
  GÉNÉRAL ne pourra plus faire disparaître les flèches en silence. Même famille que
  `completionSpots` (`f.confirmation`). **Corollaire de méthode** : après un renommage, chercher les
  comparaisons à l'ANCIENNE valeur, pas seulement les accès au champ.
- **UN BINDER PAR CARTE N'ATTEINT PAS CE QUI VIT ENTRE LES CARTES (v5.0.0)** : les interstices de
  niveau BLOC (`data-drop="B:n"`) sont émis ENTRE les `.blk`, donc FRÈRES — le binder tournait
  `main.querySelectorAll('.blk').forEach(card=>card.querySelectorAll('[data-drop]'))` et ne les
  câblait jamais : **déplacer un bloc ne faisait rien**, tandis que déplacer une ÉTAPE (interstice
  INTERNE à la carte) fonctionnait. La moitié du geste marchait, ce qui rendait le défaut
  déroutant. Binder hissé au niveau de `main` et SORTI de la boucle. ⚠ Piège rencontré en le
  déplaçant : **`imgInput.onchange` existait DEUX fois** dans le fichier (fiche et protocole) — une
  ancre textuelle a fait atterrir le binder dans la mauvaise portée, trouvé à la sonde. (Cette
  duplication n'existe plus depuis le chantier des entrées de fichier, v5.0.0 : un seul `<input>`,
  un seul point d'entrée.)
- **UN ÉLÉMENT TOURNÉ DÉBORDE SA PROPRE BOÎTE (v5.0.0)** : 26 px de côté font 36,8 px de diagonale,
  soit 5,4 px de chaque côté — le losange d'une décision était rogné par la colonne (−3 px mesurés).
  On tourne un **pseudo-élément plus petit à l'intérieur** d'une boîte qui, elle, ne bouge pas.
- **LA MARQUE DE REGISTRE EST EN SUPERPOSITION, ET C'EST CE QUI ALIGNE LES FLÈCHES (v5.0.0)** :
  chaque `.li` est sa propre boîte — une marque qui est un ITEM de la rangée décale tout ce qui
  suit, et les flèches partent en escalier. Posée en superposition sur le rembourrage gauche du
  champ, la boîte du champ commence au même x sur toutes les rangées, donc la flèche aussi ; et
  l'on ne paie pas les ~50 px qu'une colonne réservée prendrait au texte à 320 px.
  **ET LA RÉPONSE ATTENDUE NE SE MONTRE QUE SI ELLE EXISTE**, ou pendant qu'on écrit la ligne :
  répétée à vide sur chaque rangée, « réponse attendue (facultatif) » disait cinq fois la même
  chose et volait un tiers de la largeur au GESTE, qui est le contenu. C'est la grammaire MK-flux
  du dossier — au REPOS aucun chrome, à l'ÉDITION les outils paraissent.
- **LA CIBLE EST LA RANGÉE, PAS LE MOT (v5.0.0, demande utilisateur — gants, stress, WCAG 2.2
  § 2.5.8)** : le déclencheur du chapeau « Ne pas oublier » était un bouton de la largeur de son
  texte (~90 px) au bout d'une ligne qui, elle, fait toute la largeur. Le TITRE devient le bouton —
  patron déjà appliqué à « Confirmation diagnostique » et à `.crit-guide`. Mesuré : **352 × 48 px**
  au lieu de ~90 × 44. Hors session rien n'est repliable : c'est alors un simple titre, un bouton
  qui n'agit pas serait un bouton mort.
- **« ■ CRISE » NE S'ANNONCE QU'UNE FOIS LA SESSION DÉMARRÉE (v5.0.0, maquette)** : ouvrir une fiche
  pour la RELIRE n'est pas être en crise, et l'annoncer alors use le mot — la même inflation que
  celle du rouge, sur le seul annonciateur de MODE de l'écran. Le bandeau-titre reste (il porte le
  TITRE, vrai dans les deux cas) ; c'est la PILULE qui attend le premier geste. Prédicat unique
  `crisisOnScreen()`.
- **« ✓ CONSIGNÉ À … » — LA TRACE SE VOIT, POUR NE PAS ÊTRE REFAITE (v5.0.0, demande utilisateur :
  « éviter de le faire 2 fois »)** : incrémenter un compteur POSE DÉJÀ un repère horodaté
  (`ref:{type:'counter'}`, v4.52.0) — mais rien ne le disait, et l'on pouvait « Noter l'heure »
  par-dessus, donc doubler la ligne du compte rendu. **PAS D'ANIMATION** : le mouvement est réservé
  à l'ALARME (ECAM), et une valeur qui s'envolerait vers le journal serait le seul mouvement
  autonome de l'écran — sous stress il se lirait comme un signal. **PAS DE SNACKBAR** : elles sont
  mises en attente en session (règle 11). Ce qu'il faut est une INFORMATION PERMANENTE et muette, à
  l'endroit du geste — même grammaire que l'accusé « ✓ 02:16 noté » (M7), pour qu'on n'apprenne
  qu'un seul patron. Elle n'existe que s'il y a quelque chose à dire (`:empty` → aucune hauteur).
- **LE VOLET DE RELECTURE PASSE AU-DESSUS DU SCHÉMA (v5.0.0, demande utilisateur)** : dans la
  colonne de droite de l'éditeur, il est ce qu'on CONSULTE (une liste courte, repliée), le schéma
  ce qu'on REGARDE (un dessin haut). Le second poussait le premier hors de vue sur un écran de
  hauteur ordinaire.
- **LE BANDEAU-TITRE N'EXISTE PLUS EN CRISE ORDINAIRE (v5.0.0, demande utilisateur)** : il pesait
  **64 px à 320 et 390 px** (44 à 430) en haut de la colonne, et le RELAIS de la barre
  (`#brandTitle`, v4.23.0) sait déjà porter le titre — on ne le supprime donc pas, on le fait
  porter EN PERMANENCE par l'objet qui le portait déjà la moitié du temps. Bénéfice second : la
  barre a la **même hauteur repliée et dépliée**, donc le chrome de lecture ne change plus jamais
  de taille. Mesuré : chrome collant du premier écran **239,7 → 176 px**, et une étape entièrement
  visible de plus à 390 px.
  **⚠ ET C'EST INCONDITIONNEL, POUR UNE RAISON MESURÉE — MA PREMIÈRE VERSION ÉTAIT FAUSSE.** Je
  l'avais effacé AU DÉMARRAGE (pour garder le titre entier pendant qu'on lit les critères) :
  `audit-doctrine` a rougi sur « l'étape tapée ne bouge pas à la première action » (invariant ECAM
  depuis la v4.4.0), et à juste titre — c'était la **TRANSITION** qui retirait 64 px AU-DESSUS de
  l'étape touchée, au moment précis du tap, et l'ancrage ne peut pas compenser vers le haut quand
  on est déjà en haut de page. **Sans transition, pas de saut** : le bandeau n'existe à aucun
  moment, donc rien ne change de hauteur sous le doigt. La remarque qui a corrigé cela vient de
  l'auteur, pas de moi.
  **IL SURVIT AUX MODES D'EXCEPTION, ET SEULEMENT À EUX** (`bandOff`) : il porte la **PHRASE** et
  la **HACHURE** de l'exercice, de l'invité et de l'essai — précisément ce que la pilule de la
  barre ne sait pas dire, qui n'a que le MOT (« Suivi », « Exercice »). La v4.70.1 a réparti ces
  deux offices ; le supprimer partout supprimerait la moitié du dispositif, **et aucun harnais
  n'aurait crié** — `getComputedStyle` répond encore sur un élément masqué. Aucun saut non plus :
  être en exercice ou invité ne CHANGE PAS au premier geste, la condition est stable pendant toute
  la session. ⚠ Le témoin d'`audit-partage` a dû être **remis sur son sujet** : il comparait la
  hauteur du bandeau HÔTE vs INVITÉ, donc mesurait désormais l'EXISTENCE du bandeau et non le coût
  du PLACARD. Il compare maintenant le bandeau de l'invité **avec et sans son étiquette**, et
  vérifie d'abord qu'il RENCONTRE SON CAS (bandeau présent, étiquette visible).
- **LE LIBELLÉ DU RETOUR SUIT L'INFORMATION, PAS LA PLACE (v5.0.0, proposition utilisateur —
  mesurée, et déplacée là où elle mord)** : « enlever Bibliothèque pour récupérer de la largeur »
  était juste, mais **pas où on le croyait**. Mesuré : sous 560 px le libellé n'est PAS affiché
  (bouton de 31 px, flèche seule) — il n'y avait donc rien à récupérer là où la place manque.
  AU-DESSUS, il en prend 95 et **fait RÉTRÉCIR le titre** : 204 px de titre à 430, **179 seulement
  à 560**, sur un écran pourtant plus large. Or « Bibliothèque » est la destination PAR DÉFAUT
  d'une flèche de retour — elle se devine, et la nommer ne dit rien qu'on ne sache. Le TITRE D'UNE
  FICHE D'ORIGINE, lui, dit d'où l'on vient (pile de retour, v4.28.0) et vaut sa largeur. Le
  libellé est donc **présent quand la pile n'est pas vide, absent sinon**. Mesuré après : titre
  **179 → 276 px** à 560, et le libellé revient bien nommer la fiche d'origine (224 px).
- **LA RANGÉE DE RÉPERTOIRE — V2 (v5.0.0, maquette validée)** : le défaut réel n'était pas le style
  mais la **HAUTEUR VARIABLE**. La sous-ligne était une rangée `flex-wrap` de six à sept pilules de
  largeurs quelconques : chaque fiche se repliait différemment (**52 à 86 px** mesurés) et
  l'annuaire n'avait aucun rythme. Elle est désormais **à hauteur fixe (71 px)**, avec un **titre
  sur deux lignes** et une **méta sur une seule**, ellipsée — dont l'ORDRE est celui de
  l'importance, puisque c'est la QUEUE qui tombe : état (chrono, statut, à compléter), puis
  discriminant, puis catégorie, et enfin code et date, qui sont ce qu'on peut perdre.
  **⚠ LES 71 px SONT LE RYTHME DE L'ANNUAIRE, PAS UNE PROPRIÉTÉ DE LA RANGÉE (v5.0.0, signalé à
  l'usage : « en mode recherche le texte dépasse des cartes d'accueil »)** : ils ont été posés sur
  un contenu BORNÉ par construction — titre à 2 lignes, méta à 1. En RECHERCHE la rangée porte EN
  PLUS l'extrait contextuel (`.card-snip`, 2 lignes), et la boîte ne peut pas le contenir : mesuré
  à 360 px, `.dir-main` atteint **81 à 99 px pour 71 disponibles**, l'extrait dépassant de 10 à
  29 px. Il était donc CLIPÉ en plein milieu d'une ligne (`overflow:hidden`) — et la rangée étant
  centrée, le titre l'était aussi par le haut : on promettait un extrait et on le rendait
  illisible. La liste de recherche **n'est pas le répertoire** (elle est plate, triée par
  pertinence, et son contenu est variable par nature) : sous `.dir-grid.flat`, la rangée reprend sa
  hauteur naturelle. **Le rythme n'est pas abandonné pour autant** — `min-height` garde le pas de
  71 px, donc une rangée SANS extrait (le cas nominal d'une recherche par titre, où
  `searchSnippet` rend une chaîne vide) ne bouge pas d'un pixel, et l'extrait RÉSERVE ses deux
  lignes : il n'existe que DEUX hauteurs possibles, jamais N. Spécificité (0,3,0), pour gagner sur
  `.dir-row` et sa variante < 640 px quel que soit l'ordre de déclaration. Témoins dans
  `audit-doctrine` (320/360/390/700/1400 px) : ils **rencontrent leur cas deux fois** — un extrait
  doit être RENDU, et il doit faire deux lignes, sinon on mesurerait une rangée ordinaire ou un
  extrait qui tenait de toute façon. Vérifiés capables d'échouer (règle retirée → 5 rouges).
  **⚠ LE CORPS RESTE SUR L'ÉCHELLE FERMÉE**, et c'est la contrainte qui a fait échouer DEUX
  maquettes de ma main (15 px et 14,5 px — aucun n'étant un palier ; l'auteur l'a vu, pas moi).
  Le titre est à **15,5 px**, un palier : ce qui se resserre pour tenir en 71 px est l'**INTERLIGNE**
  et le **REMBOURRAGE**, jamais la police. Descendre à 13,5 mettrait le titre d'une fiche au corps
  du TEXTE COURANT et lui ferait perdre le relief que l'échelle existe pour tenir.
  **DEUX ÉCONOMIES GRATUITES** rendent la place des deux lignes : la pastille de catégorie est
  REDONDANTE avec le liseré (même couleur, même information — la catégorie reste nommée en toutes
  lettres dans la méta ; `.cat-dot` purgée de la rangée, règle 14), et l'épingle passe de 34 à 26 px
  en gardant sa cible de 44 par un halo `::before`.
  **« SESSION EN COURS » — TROIS CANAUX CUMULÉS, 0 px DE COÛT** : le liseré passe au registre
  CONFIRMATION, la rangée en prend la teinte, et **la DATE cède la place au CHRONO VIVANT**. Le
  troisième est le plus juste : il occupe une place DÉJÀ prise (une date de validation n'apprend
  rien pendant qu'une session tourne), un temps qui s'incrémente est un signal non ambigu — la
  couleur n'est donc jamais seule (règle 8) — et l'on apprend en plus DEPUIS COMBIEN DE TEMPS.
  Il est **peint sur place par `tickAll`** (`paintDirLive`), jamais par un re-rendu : reconstruire
  l'annuaire chaque seconde détruirait le nœud sous le doigt (leçon du quai). Le point bat en
  OPACITÉ seule, 2,4 s, sous `prefers-reduced-motion: no-preference` uniquement — sur l'ACCUEIL,
  jamais dans la vue de crise où le mouvement est réservé à l'alarme (ECAM), et très loin du seuil
  de 3 Hz de WCAG 2.3.1.
  **DEUX PIÈGES RENCONTRÉS, TOUS DEUX SILENCIEUX** : (a) la rangée a **TROIS** enfants (contenu,
  code, épingle) — avec une grille à deux colonnes le troisième passait à la ligne, donc HORS d'une
  boîte à hauteur fixe, sans que rien ne le dise (épingle mesurée à 244 px de large) ; (b) retirer
  le `padding:6px` compensé par marges négatives du bouton-titre a fait tomber sa cible mesurable
  de 29 à **18 px** — sous le seuil WCAG 2.5.8, attrapé par `audit-a11y`. Le rembourrage compensé
  n'est pas décoratif : il EST la cible.
  **LA MÉTA EST DU TEXTE SÉPARÉ PAR DES POINTS, PAS UNE SUITE DE CHIPS** (signalé à l'usage : la
  première livraison avait gardé les chips existantes). **Une chip a une largeur INCOMPRESSIBLE** :
  dans une grille qui compte de deux à quatre colonnes, elle se coupait net dès que la piste
  rétrécissait, et c'est elle qui poussait la catégorie hors du cadre. Du texte, lui, s'ellipse
  proprement et **par la queue**, donc dans l'ordre d'importance choisi. Les composants partagés
  (`.tag`, `.status-tag`) sont **déshabillés dans la rangée, et là seulement** — ailleurs la chip a
  un sens. Le CODE a lui aussi rejoint la méta : en colonne séparée, il prenait une piste au titre
  et se retrouvait au milieu de la rangée, loin de ce qu'il nomme.
  **⚠ QUATORZIÈME PIÈGE DE CASCADE** : `.tag.todo` vaut (0,2,0) et est déclarée PLUS BAS que
  `.dir-sub .tag` — à spécificité égale c'est l'ORDRE qui tranche, et le fond gris de la chip
  revenait. On passe par `.dir-row` (0,3,0), qui gagne quel que soit l'ordre.
  **LE MOT CÈDE, LE GLYPHE RESTE** : « △ À compléter » coûtait ~95 px sur une piste de 292 —
  c'est-à-dire la catégorie entière. Il devient « △ » + étiquette `.sr-only`, exactement le patron
  du quai (v4.23.0 : « le mot ne peut pas être écrit en clair ici, il serait le premier rogné »).
  La règle 8 est tenue : le △ est une FORME, pas une couleur, et il porte son nom accessible.
  Mesuré après : **0 méta tronquée** en 1, 2, 3 et 4 colonnes.
  **⚠ ET LES LARGEURS QUI COMPTENT SONT CELLES DES PISTES, PAS DES ÉCRANS** : la grille est fluide
  (`auto-fill minmax(290px,1fr)`), donc un écran de 1600 px donne QUATRE pistes de **319 px** —
  plus étroites qu'un téléphone de 390. Mesurer 330 et 390 ne prouvait rien sur ordinateur ; les
  témoins balayent les six largeurs qui produisent 1, 2, 3 et 4 colonnes.
  **⚠ CE QUI DÉBORDE NE DOIT PAS AFFAMER LE RESTE** (signalé à l'usage : avec un code long, la DATE
  disparaissait). Ellipser la LIGNE entière fait tomber la QUEUE — donc l'élément le moins large,
  quel que soit le coupable. On distingue donc **deux natures** : les items **DURS** (chrono,
  registre, statut, date) ne rétrécissent jamais — ils sont courts, bornés, et *un chiffre amputé
  est pire qu'absent* (règle du quai) ; les items **SOUPLES** (discriminant, bibliothèque,
  catégorie, code) rétrécissent chacun **pour soi**, avec leur propre ellipse — le flex répartit le
  manque au prorata, donc c'est le PLUS LONG qui cède le plus, et tous restent présents. Un code de
  vingt-trois caractères s'abrège lui-même au lieu d'effacer la date. Mesuré à 4 colonnes avec un
  cas volontairement adverse : ligne non ellipsée, 0 item hors boîte, date intacte.
  **TÉMOINS** : on ne mesure pas « la rangée fait 71 px » (vrai sur une liste d'UNE fiche) mais que
  TOUTES ont la MÊME hauteur, après avoir vérifié qu'il y en a plusieurs. Et **ils construisent un
  CAS ADVERSE** — code de 23 caractères, catégorie de 33, discriminant de 29 : mesurer les fiches
  d'EXEMPLE ne prouvait rien, leur code faisant trois caractères et leur catégorie un mot. Le
  témoin restait vert pendant que la date disparaissait chez l'utilisateur. **Un contrôle qui ne
  rencontre pas son cas ne le couvre pas** — c'est la leçon la plus souvent redite de ce dossier, et
  elle s'est encore vérifiée ici. Et le débordement de la
  RANGÉE ne suffit pas à prouver que la méta tient : `.dir-sub` est en `overflow:hidden`, donc la
  rangée reste propre pendant que l'information disparaît — **on mesure l'ellipse elle-même**.
- **LA PHASE VIT DANS L'EN-TÊTE DU BLOC, À DROITE (v5.0.0, maquette)** — et ⚠ ma première pose ne
  l'avait mise que dans la branche DÉCISION : un `replace(…, 1)` avait pris la première occurrence
  des deux branches de `blockEditor`. Signalé à l'usage (« ça ne s'affiche que sur les blocs
  conditionnels »). Le champ est FACULTATIF et HÉRITÉ : vide, il affiche **en filigrane** la phase
  du bloc précédent, de sorte que l'auteur voit ce qui s'appliquera sans avoir à la retaper ; un
  `datalist` propose le noyau sans l'imposer. Dessin discret (filet pointillé, aligné à droite) :
  c'est une étiquette d'ORGANISATION, jamais un registre — aucune couleur sémantique.
- **UN SEUL DESSIN D'INTERTITRE DANS LA COLONNE (v5.0.0, signalé à l'usage)** : il y en avait DEUX —
  `.pl-cxh` (9 px de retrait, `space-between` qui renvoyait « hors numérotation » sur sa propre
  ligne) et `.pl-sech` (2 px). D'où « à tout moment plus à droite que le reste » et « hors
  numérotation qui sort de nulle part ». Un seul demeure : même retrait que les rangées, et la
  précision suit le titre **dans la même phrase**. Le titre d'une complication ne colle plus à son
  liseré (13 px). ⚠ Une purge d'intertitre emporte le SÉLECTEUR des harnais : `audit-complications`
  visait `.pl-cxh` et serait resté vert sans rien mesurer (règle 14).
- **LE DÉPLIANT D'UNE LIGNE DU PARCOURS N'EST PLUS UNE CARTE BLANCHE (v5.0.0, signalé à l'usage :
  « est-ce voulu ? » — non)** : il datait du temps où la colonne ÉTAIT une carte blanche, où il se
  fondait. Depuis que les rangées vivent sur le fond de la colonne, c'était la seule surface
  blanche de l'écran, donc la plus saillante — alors qu'elle porte du DÉTAIL. Surface de second
  plan et retrait, comme un contenu subordonné.
- **L'ÉTOILE ★ REVIENT DANS LE CHAPEAU (v5.0.0, retour utilisateur : « avant c'était beaucoup plus
  clair »)** — je l'avais retirée en la croyant redondante. Elle ne l'est pas : elle dit POURQUOI
  cette ligne est là sans être éditable (elle a été posée sur une ÉTAPE). Ce qui était mal fait
  n'était pas le glyphe mais le RENVOI en rangée, qui mangeait la moitié de la largeur et se
  tronquait en plein titre de bloc. Il reste sur sa propre ligne, pleine largeur, ≥ 44 px.
- **UN SEUL REGISTRE PAR SURFACE (v5.0.0, signalé à l'usage : « gris puis bleu sur du vert »)** :
  les chips de suggestion de l'accusé héritaient du dessin du PANNEAU (fond neutre, survol bleu),
  pensé pour un fond blanc — posées sur la teinte de CONFIRMATION, deux registres se superposaient.
  Dans l'accusé elles prennent la SURFACE (blanc franc, qui se détache de la teinte) et le filet du
  registre courant ; le survol reste dans ce registre.
- **« CONSIGNÉ » EST UN MEMO, PAS UNE CONFIRMATION (v5.0.0, question de l'auteur, relecture ECAM)** :
  le vert du dossier dit « ce que l'on VIENT DE FAIRE est acquis » — étape cochée, algorithme
  terminé —, c'est-à-dire la réponse à un GESTE. La trace d'un compteur est un **fait passif**,
  affiché en permanence sur chaque carte : en vert, elle diluerait le vert des étapes cochées
  exactement comme un rouge permanent dilue le rouge des étapes vitales. Registre **MEMO** (neutre),
  et le ✓ tombe avec lui. **ET ELLE RESTE, C'EST VOULU** : un fait n'expire pas — c'est l'analogue du
  « last actuation » d'un synoptique ECAM, un état de l'objet et non une alerte à acquitter. La
  faire disparaître au bout de n secondes rendrait la question « ai-je consigné ? » à nouveau sans
  réponse, ce qu'elle vient précisément réparer.
- **UNE RÈGLE ÉCRITE POUR UNE LIGNE NE DOIT PAS S'APPLIQUER À UNE BOÎTE (v5.0.0, signalé à
  l'usage)** : `.pos-card.vig + .pos-card{border-top:0}` datait du temps où le repère ORDINAIRE
  était une LIGNE à filet — après une boîte ambre, ce filet aurait fait double trait. Mais deux
  BOÎTES qui se suivent — le cas dès que deux repères sont signalés △, donc sur les deux fiches
  d'exemple depuis le lot T13 — n'ont pas ce problème : la seconde perdait son bord haut
  (`border-top-width: 0px` mesuré) et se lisait comme rognée. La règle est bornée par `:not(.vig)`.
  C'est le corollaire de « normal = ligne, signalé = boîte » : quand la doctrine distingue deux
  formes, **toute règle qui vise l'une doit le dire dans son sélecteur**.
- **LA RÉFÉRENCE — PLAN À GAUCHE, RECHERCHE DEDANS (v5.0.0, refonte des protocoles)** : le sommaire
  vit **à gauche** ≥ 1000 px, comme le plan d'une aide en cockpit et pour la même raison — on
  s'oriente à gauche, on lit au milieu. **Sous 1000 px il n'y a pas de colonne** : il devient un
  DÉPLIANT replié en tête du corps, qui dit son nombre de sections — un sommaire qu'on ouvre,
  jamais une liste qui pousse le texte. **L'ORDRE DU DOM RESTE CELUI DE LA LECTURE** : le sommaire
  est ajouté APRÈS le corps et ramené à gauche par `order` — ni un lecteur d'écran ni une
  tabulation ne traversent un sommaire pour atteindre le texte (règle de `.read-plan`, v4.59.0).
  **CHERCHER DANS LA RÉFÉRENCE** : un protocole peut faire plusieurs milliers de mots, et la
  recherche de l'accueil trouve la FICHE, jamais l'endroit. ⚠ **LE SURLIGNAGE NE PASSE JAMAIS PAR
  `innerHTML`** — il parcourt les NŒUDS DE TEXTE et n'insère que des nœuds créés
  (`createElement`/`createTextNode`) : réinjecter du balisage produit par `mdRender` ouvrirait une
  seconde occasion de se tromper là où `esc()` est la SEULE barrière (règle 4). Le témoin vérifie
  donc aussi qu'après effacement **le document revient à l'identique**. **La recherche ne FILTRE
  pas, elle surligne et saute** : masquer des sections laisserait croire qu'elles n'existent pas —
  même garantie que `posoRank` et `tagRank`.
- **LA RELECTURE D'UNE RÉFÉRENCE (v5.0.0)** : le volet des AIDES lit des garde-fous de checklist
  (memory items, longueur des challenges) qui n'ont aucun sens ici — une référence n'a ni bloc ni
  étape. `reviewNotesProto` dit ce qui MANQUE pour qu'elle serve : contenu vide, « à compléter »
  résiduel, aucune source citée, titre absent. **MÊME DESSIN, MÊME GRAMMAIRE** que le volet des
  aides (`reviewPanelHtml` est partagé, il prend les notes en paramètre) : qui a appris à lire l'un
  lit l'autre — doctrine I4 appliquée à l'édition. Il vit **au-dessus de l'aperçu** dans la colonne
  de droite, en pied sous 1000 px.
- **UNE COLONNE D'ORIENTATION S'AJOUTE AU PLAFOND, ELLE NE S'Y PRÉLÈVE PAS (v5.0.0, refonte des
  protocoles, signalé à l'usage)** : la référence est plafonnée à 780 px « à toutes les largeurs » —
  poser la grille du sommaire DEDANS le mettait dans la colonne de lecture, et l'on n'avait plus
  780 px de texte mais 496. C'est la règle déjà écrite pour la fiche (« le rail prend l'espace
  EXCÉDENTAIRE ») : le corps garde ses 780, le sommaire s'ajoute.
  **DEUX RÉGIMES, PAS UN SEUIL** — et il a fallu deux signalements pour y arriver : (a) la colonne
  passait PAR-DESSUS le texte entre 1000 et 1064 px (la grille demande 260 + 24 + 780 = 1064, et la
  piste du corps était FIXÉE) ; (b) remonter le seuil à 1200 faisait disparaître le sommaire « alors
  qu'il y a encore de la place ». D'où : **≥ 1000** deux pistes `260 + souple`, la paire centrée
  donc le corps un peu à droite du milieu — mieux vaut un léger décalage qu'un sommaire qui
  s'efface ; **≥ 1200** trois pistes, le corps reprend ses 780 px et se recentre PROGRESSIVEMENT ;
  **< 1000** le dépliant. Le sommaire ne disparaît jamais, **il change de forme**.
  **LE RAIL A UN PLANCHER** (`minmax(260px,1fr)`) : sans lui la piste valait 168 px à 1200 — le
  sommaire rétrécissait au moment PRÉCIS où l'on gagne de la place, l'inverse de ce qu'on attend.
  C'est la piste de DROITE qui absorbe, et le décalage décroît en continu (142 → 92 → 0 vers
  1370) : **un mouvement continu, jamais un saut**.
  **LES ANNEXES SONT RECOPIÉES, PAS DÉPLACÉES** (correction : ma première version les sortait du
  corps) — documents et « Voir aussi » restent à leur place dans le document, ce sont des parties
  de la référence ; la colonne n'en offre qu'un ACCÈS RAPIDE. Les copies sont insérées AVANT le
  câblage (`main.querySelectorAll` court plus bas), donc bindées comme les originales : aucune
  seconde vérité, aucun second écouteur à tenir.
  **LE SOMMAIRE NE S'IMPRIME PAS** : sur papier on TOURNE les pages, on ne saute pas à une ancre —
  une table des matières qui ne mène nulle part est du bruit, et sa colonne rétrécirait le texte.
- **LA PORTE D'UNE RÉFÉRENCE (v5.0.0)** : même composant, même fenêtre, même grammaire que celle des
  aides — mais une AUTRE liste, parce qu'une référence n'a ni bloc, ni étape, ni minuteur : elle a
  un CORPS, des DOCUMENTS, des RENVOIS et des SOURCES. Proposer les types d'une checklist ici
  serait promettre ce qui n'existe pas. Même règle **« présent dans la porte ⇔ masqué quand
  vide »**, et même contrainte de tâche : le document ouvre le sélecteur de fichier DANS LA MÊME
  TÂCHE que le clic de la palette, sinon l'activation utilisateur est perdue (leçon v4.71.0).
  ⚠ **UNE LISTE SE TROUVE PAR SON BOUTON D'AJOUT**, pas par un `data-key` — `listEditor` n'en émet
  pas : viser un attribut inexistant ne lève rien, le focus reste où il était, et l'auteur ne voit
  pas ce qu'il vient de créer. Trouvé à la sonde.
- **UNE SÉPARATION SE LIT À SA SYMÉTRIE, PAS À SON TRAIT (v5.0.0, signalé à l'usage)** : le
  rembourrage bas de la zone de recherche s'ajoutait à la marge du titre — 24 px au-dessus du filet
  contre 12 en dessous, et « Sommaire » paraissait collé à la barre. Même valeur des deux côtés.
  ⚠ **QUINZIÈME PIÈGE DE CASCADE** au passage : `.rt-h2` posait un `padding-top` LONGHAND, et
  `.rt-h` — même spécificité, déclarée plus bas — repose un `padding` RACCOURCI qui l'écrase
  intégralement. Mesuré : 14 px demandés, **0 obtenu**. Passer par `.ref-toc .rt-h2` (0,2,0).
- **L'AIDE-MÉMOIRE DE SYNTAXE SE REPLIE (v5.0.0, signalé à l'usage : « c'est moche »)** : c'était un
  paragraphe de vingt lignes sous le champ, **permanent** — on le lit une fois, on le subit ensuite.
  Replié il tient en une ligne ; déplié, l'interligne l'aère et les exemples en mono se détachent.
  Même gabarit que les autres dépliants (`.crit-guide`, `.rev-panel`).
- **LE VOLET DE RELECTURE EST OUVERT PAR DÉFAUT (v5.0.0, demande utilisateur)** — dans les DEUX
  éditeurs, aide et référence : un seul dessin, une seule habitude. C'est cohérent parce qu'il
  **n'existe pas** quand il n'a rien à dire (`if(!n.length)return ''`) : il ne peut donc jamais être
  du bruit permanent, et la règle « un panneau vide est du bruit » est déjà tenue par son absence.
  Replié, il demandait un clic pour lire un BILAN — c'est-à-dire exactement la chose qu'on ne clique
  pas. Il reste repliable, et l'état n'est pas persisté : c'est une consultation, pas un réglage.
- **LE SOMMAIRE D'UNE RÉFÉRENCE EST DU CHROME, PAS DU FLUX (v5.0.0, signalé à l'usage : « mets-le
  directement en en-tête plutôt que sticky », « lorsque ça colle ça ne fusionne pas à l'en-tête et
  ça fait moche »)** : un `sticky` vit d'abord dans le flux PUIS se colle — à cet instant il TOUCHE
  la barre sans en faire partie, deux surfaces séparées par un liseré de fond. `#refBar` est donc
  **sœur de `.app` et `position:fixed`**, comme `#crisisCtrl` et `#crisisDock` : il ne transitionne
  jamais, il EST la seconde rangée de l'en-tête dès le premier pixel. Même fond, même rembourrage
  de 18 px, aucun rayon — et **un filet par ÉTAGE** (demande utilisateur : « marque tout de même
  une petite ligne de séparation, comme pour les aides ») : le fond commun fait le BLOC, le filet
  dit qu'il a deux rangées. Ombre **seulement OUVERT**, c'est-à-dire au seul moment où il recouvre
  le texte. `syncRefBar` mesure sa hauteur réelle et la pose en `--refbar-h` (÷ zoom) : une barre
  fixe ne prend aucune place au flux, donc sans réservation MESURÉE le texte naîtrait derrière elle.
  **⚠ ON NE REFERME PAS UN DÉPLIANT POUR LE MESURER** (défaut vécu : « scroll de la partie dépliée
  bug ») : `toggle` est ASYNCHRONE, donc écrire `open=false` puis `open=true` dans son propre
  handler le rappelle — le panneau bat et le défilement acquis repart à zéro. La hauteur repliée
  vaut l'intitulé plus les filets, tous deux présents quel que soit l'état. **Le témoin compte les
  `toggle`**, il ne regarde pas l'état final : la première version restait VERTE sur le défaut,
  l'état final étant bien « ouvert ».
- **TOUTE VUE DONT LA STRUCTURE DÉPEND D'UN PALIER DOIT ÊTRE DANS `_onReadBp`** — `protocolRead` y
  manquait, d'où « non responsive, pas d'adaptation » : le sommaire est un `<aside>` au-dessus de
  1000 px et un `<details>` en dessous, c'est-à-dire une STRUCTURE décidée au rendu. Corollaire déjà
  écrit en v4.77.0, à ne pas re-perdre à chaque vue nouvelle.
- **LES TROIS RANGÉES DE FILTRES PARTENT DU MÊME x (v5.0.0, signalé à l'usage : « Tout » pas
  aligné)** : les intitulés ont des longueurs différentes — TYPE 33 px, CATÉG. 46 —, donc chaque
  rangée de chips commençait ailleurs (63 px contre 76, mesurés). Un `min-width` commun sur
  `.scope-lbl` les aligne sans toucher aux mots. Trois colonnes de départ pour trois filtres qui se
  lisent du plus large au plus étroit brouillaient la hiérarchie qu'on venait d'établir.
- **LE RAIL A→Z EST ANCRÉ EN HAUT PARTOUT (v5.0.0, signalé à l'usage : « sa position bouge sans
  cesse »)** : la v4.73.0 avait posé `flex-start` sur la seule variante ÉTROITE ; en vue LARGE le
  rail restait `justify-content:center`, donc la position des lettres dépendait de LEUR NOMBRE —
  filtrer ou chercher en changeait la quantité et déplaçait toute la colonne (première lettre
  mesurée à 307 px, ailleurs dès qu'une lettre disparaît). Un index d'annuaire doit être là où l'on
  a appris à le viser, quel que soit ce qu'il contient. **Le témoin ne rencontrait pas son cas** :
  le rail n'existe qu'à partir de deux lettres distinctes, et les deux fiches d'exemple n'en
  donnent pas assez — il construit donc son répertoire.
- **REJOINDRE UNE SESSION NE DÉPEND PAS DU FILTRE DE TYPE (v5.0.0, signalé à l'usage)** : la ligne
  « code de session reconnu » vivait dans la configuration des FICHES, donc « Tout » l'héritait par
  raccroc et « Protocoles » ne l'avait pas du tout — alors qu'un code ne désigne ni une aide ni une
  référence : il désigne une SESSION. Elle est hissée dans le rendu commun, avec son câblage, avant
  tout ce qui dépend d'une configuration.
- **EN VUE « TOUT », PAS DE RENVOI VERS L'AUTRE TYPE (v5.0.0, signalé à l'usage)** : `crossKind` y
  vaut `null`, et le test `other==='protocols'` retombait alors sur la branche FICHES — on annonçait
  « n aides correspondent AUSSI » à quelqu'un qui les avait déjà sous les yeux. Un renvoi vers là où
  l'on est n'est pas un renvoi, c'est du bruit.
- **LA NATURE DE L'OBJET SE LIT SUR LA RANGÉE (v5.0.0, demande utilisateur, d'après la maquette)** :
  en vue « Tout » les deux types se mêlent et rien ne disait lequel on allait ouvrir — une checklist
  qui se DÉROULE ou un document qu'on CONSULTE, deux gestes différents. Repris dans les vues
  filtrées à la demande : un seul dessin de rangée partout, donc rien à réapprendre en changeant de
  filtre. **C'est du TEXTE en petites capitales, pas une pastille**, et ce n'est pas un détail de
  goût : mesuré, la pastille coûtait 16 px de chrome par rangée et faisait basculer la méta dans
  l'ellipse à quatre colonnes **sur des données ordinaires**. Item DUR — il ne s'abrège jamais.
  **LES CINQ PIXELS MANQUANTS SE TROUVENT DANS LE CHROME, PAS DANS UNE COLONNE EN MOINS** : élargir
  la piste minimale les rendait, mais en supprimant une colonne entière entre 1600 et 1690 px, soit
  25 % de fiches en moins à l'écran pour la queue d'un mot. On les prend sur les écarts (gap 10 → 5,
  retrait 14 → 12). Mesuré après : **0 item tronqué de 360 à 1900 px**, sauf 3 items à 2 px dans la
  seule bande des quatre colonnes serrées. Et **sous 400 px le plancher des items souples descend à
  1,6 em** : le tag est un item dur de plus, et la somme des durs et des quatre planchers de 2,5 em
  poussait la DATE hors de la boîte — un item ne disparaît pas, il s'abrège.
- **REPLIÉ, LE CHAPEAU « NE PAS OUBLIER » EST TOUT ENTIER SON DÉCLENCHEUR (v5.0.0, signalé à
  l'usage)** : le bouton fait 48 px et centre son texte, mais le chapeau gardait ses 10 px de
  rembourrage bas — le texte se trouvait donc au-dessus du milieu du bloc. On absorbe ce
  rembourrage comme le haut, par une marge négative. **Le texte ne bouge pas au dépliage** : dans
  les deux états il est centré dans les mêmes 48 px, ancrés en haut du chapeau.
- **LA PHASE SE CHOISIT DANS UNE LISTE, ELLE NE SE RETAPE PAS (v5.0.0, demande utilisateur)** : le
  champ libre demandait de RÉÉCRIRE le mot à l'identique d'un bloc à l'autre — une faute de frappe
  créait une phase jumelle, et rien ne le disait. Le sélecteur supprime la classe d'erreur entière.
  **Il reste OUVERT** — la décision du lot M6 tient, rien n'établit que les cliniciens pensent en
  cinq phases fixes : « ＋ Nouvelle phase… » ouvre un champ, la valeur entre dans la liste, et une
  phase déjà écrite y figure même hors noyau. **LE RAPPEL VIT DANS LES INTITULÉS** (« Immédiate
  (3 blocs) ») : c'est l'information qu'on cherche au moment où l'on choisit, et elle ne coûte pas
  une surface de plus ; la colonne « Structure » la double en intertitres, posés AU CHANGEMENT de
  phase seulement — c'est-à-dire là où l'auteur a effectivement décidé quelque chose.
  ⚠ **Ce qui est HÉRITÉ est la phase du bloc PRÉCÉDENT, pas l'effective** : `phaseOf` rend la phase
  qui s'APPLIQUE, celle du bloc comprise — s'en servir faisait dire « hérite : Immédiate » au bloc
  qui déclare lui-même « Immédiate ».
- **SEIZIÈME PIÈGE DE CASCADE — UN LONGHAND NE SURVIT PAS À UN RACCOURCI ULTÉRIEUR (v5.0.0,
  signalé à l'usage, capture à l'appui : « les icônes dans la zone de texte se superposent avec le
  texte »)** : la marque ⚠/△ d'une étape est réservée par un `padding-left` LONGHAND ; 1 350 lignes
  plus bas, `.blk .li input[type=text]:focus` repose un `padding` RACCOURCI — même spécificité
  (0,4,1), déclaré APRÈS, donc gagnant. **Le défaut n'existait donc qu'AU FOCUS**, ce qui explique
  qu'il ait survécu : mesuré à 390 px, rembourrage 11 px, texte commençant à 96 px pour une icône
  finissant à 101. Même mécanisme que le quinzième piège (`.rt-h2`). On passe par `:is()` à (0,5,1)
  et l'on couvre le repos ET le focus. **Le témoin doit FOCALISER** — sans cela il mesure l'état où
  le défaut n'est pas.
- **UNE CLASSE POSÉE AU RENDU NE SUIT PAS LA FRAPPE (v5.0.0, signalé à l'usage)** : `has-exp`
  décide de l'affichage de la « réponse attendue » hors focus. Écrire ne re-rend pas (et ne DOIT
  pas : un re-rendu détruirait le champ sous le curseur) — une réponse ajoutée disparaissait donc à
  la sortie du champ, et une réponse effacée laissait le champ vide affiché pour toujours. On peint
  la classe SUR PLACE dans le handler de saisie.
- **UNE SEULE VOIX PAR RANGÉE (v5.0.0, signalé à l'usage)** : les deux champs d'une étape sont au
  MÊME corps (16 px, plancher tactile) mais l'un était en chasse fixe — à taille égale, une chasse
  fixe a une hauteur d'x plus grande et paraît plus grosse. Le champ prend la police du geste ; **la
  chasse fixe reste où elle porte du sens**, c'est-à-dire sur la PILULE de lecture (`.stp-r`).
- **LE CHAPEAU « NE PAS OUBLIER » EST UNE SEULE LISTE, ORDONNÉE PAR LE POOL (v5.0.0, signalé à
  l'usage : « il faut pouvoir les mettre ENTRE les autres, pas tout en bas »)** : il agrégeait deux
  familles en les CONCATÉNANT — rappels de portée fiche d'abord, ★ des étapes ensuite —, si bien
  qu'un memory item posé sur un geste vital arrivait toujours DERNIER. Or les deux vivent dans le
  MÊME pool : son ordre est l'ordre naturel, et c'est celui que l'auteur manipule déjà. La rangée
  est la même pour les deux ; ce qui change est ce que le champ AUTORISE — une ligne portée par une
  étape est un champ `:disabled`, dans la grammaire de « fermé » du dossier (v4.79.0), suivi du
  renvoi vers son bloc. **Le chapeau AGRÈGE, il ne possède pas** : on ne duplique pas le lieu
  d'écriture. ⚠ **`setList` écrit désormais EN PLACE** : il reposait la tranche en FIN de pool, donc
  une simple frappe renvoyait les rappels derrière les ★ et défaisait l'entrelacement tout seul.
- **LA GOUTTIÈRE DU RAIL A→Z EST RÉSERVÉE, MÊME SANS RAIL (v5.0.0, signalé à l'usage : « les cartes
  sont de taille différente selon Tout / Aides / recherche »)** : le rail n'existe qu'en RÉPERTOIRE ;
  en recherche il disparaissait, la colonne gagnait ses 30 px et la grille fluide pouvait changer de
  nombre de colonnes — 312 px de rangée d'un côté, 322 de l'autre, mesurés. Un annuaire dont le pas
  change quand on tape est un annuaire qu'on réapprend à chaque geste. Mesuré après : **319 px dans
  les six configurations** (trois filtres × répertoire/recherche).
- **UN SEUL LIBELLÉ POUR « CONSULTER », À TOUTES LES LARGEURS (v5.0.0, demande utilisateur)** :
  l'abréviation « Cons. » datait d'avant la mesure. Depuis que `fitCtrlRow` mesure le débordement
  RÉEL et descend d'un palier de compression avant d'enrouler (v4.74.2), la place existe — vérifié
  de 320 à 430 px aux quatre tailles de texte. Un bouton qui change de mot selon la largeur est un
  bouton qu'on relit : la constance du libellé est la même exigence que la constance de sa position.
- **LES DEUX PORTES « ＋ » PARTAGENT LEUR FABRIQUE DE RANGÉE *ET* LEUR REGISTRE D'ÉCRITURE (v5.0.0,
  signalé à l'usage)** : celle des références avait son propre gabarit (`.ep-grp`/`.ep-tx`, sans
  aucune règle CSS — d'où son dessin fautif). Une seule fabrique désormais. **Et le gabarit ne
  suffisait pas** : ses gloses étaient des PHRASES là où celles des aides disent la CONSÉQUENCE en
  deux mots — elles enroulaient, et la rangée passait de 52 à 56 px. Deux portes qui n'écrivent pas
  dans le même registre ne se ressemblent pas, quel que soit leur CSS.
- **DEUX RANGÉES DE FILTRES VOISINES RÉPONDENT AU GESTE DE LA MÊME FAÇON (v5.0.0)** : les chips de
  TYPE n'avaient aucune micro-réponse au survol, celles de CATÉGORIE oui — même grammaire, même
  geste, deux comportements.
- **UNE RANGÉE D'ÉDITEUR S'ENROULE PLUTÔT QUE DE TRONQUER (v5.0.0, signalé à l'usage)** : la rangée
  de complication tenait trois objets incompressibles sur une ligne, et sur écran étroit la CIBLE
  tombait à 46 % de rien et se coupait en plein nom de bloc — c'est-à-dire précisément sur
  l'information qui dit OÙ l'on va. Même remède que le bandeau de déplacement et que la ligne
  d'état : on empile, la croix reste ancrée avec sa place réservée.
- **LE BANDEAU-TITRE N'EST PLUS QU'UN PLACARD (v5.0.0, signalé à l'usage : « en mode Essayer le
  bandeau inférieur avec le titre apparaît encore, alors que le titre est déjà à côté du ‹ »)** :
  depuis que la barre porte le titre EN PERMANENCE, le répéter dans le bandeau était la duplication
  même que la v4.70.1 proscrit — et sur deux lignes de serif, au prix le plus fort. Il ne porte donc
  plus que ce que la barre ne sait pas dire : la PHRASE d'une exception et sa hachure. `.cb-ttl` et
  `.cb-disc` sont PURGÉS (règle 14) ; **le discriminant suit le titre dans la barre**, en pilule à
  part — jamais dans la chaîne qui se tronque, c'est tout son objet (K6).
  **ET IL NE SURVIT QU'À DEUX EXCEPTIONS, PAS TROIS** : l'ESSAI n'en est pas une — la v4.76.0 a
  établi que la barre y porte déjà les deux énoncés (pilule « ■ Aperçu » ET badge « rien n'est
  enregistré ») et qu'il ne manquait que la TEXTURE, laquelle vit sur l'en-tête. Un bandeau sans
  titre et sans phrase n'y serait plus qu'une bande hachurée vide. Restent l'exercice et l'invité.
  Corollaire : **la hachure de l'en-tête ne dépend plus du relais `.ttl-on`** — la barre porte le
  titre dès le premier pixel, il n'y a plus de relais à attendre.
- **LA COLONNE D'ORIENTATION EST DÉSATURÉE, Y COMPRIS SES CHIPS DE BRANCHE (v5.0.0, signalé à
  l'usage : « ça ressort beaucoup, je ne suis pas sûr que ce soit approuvé ECAM/QRH/FAA »)** — la
  remarque est juste. La chip nomme la BRANCHE qui mène au bloc : ni alerte, ni point de vigilance.
  En ambre plein elle empruntait le registre ATTENTION dans une colonne dont toute la doctrine est
  la désaturation (v4.23.0 : « l'état n'y est porté que par le marqueur, aucun texte coloré ») —
  elle criait donc plus fort que le contenu clinique qu'elle indexe, exactement l'inflation que le
  dossier combat pour le rouge. Pastille NEUTRE ; le registre reste au point où l'on CHOISIT,
  c'est-à-dire sur les options `.opt` de la carte de décision.
- **UN RAIL POUR LE GROUPE, PAS UNE BORDURE PAR RANGÉE (v5.0.0, signalé à l'usage : « la bordure
  rouge sort un peu de nulle part »)** : le liseré des complications commençait SOUS l'intertitre,
  donc après le mot qui annonce le groupe — il paraissait surgir. Il court désormais du titre à la
  dernière rangée : c'est le GROUPE qui est hors séquence, pas chaque ligne prise séparément.
  ⚠ **Et l'intertitre s'aligne sur les rangées DE SA COLONNE** : ma première correction l'avait
  aligné sur le retrait de la carte de LECTURE (9 px) alors que la colonne désaturée retire de
  2 px — soit le défaut signalé, à l'envers. On mesure, on n'extrapole pas d'une surface à l'autre.
  Le rail est le SEUL retrait du groupe (aucun rembourrage en plus) : il reste 3 px, ce qu'un
  liseré coûte partout ailleurs.
- **« CONSULTER » A LA MÊME HAUTEUR PARTOUT, ET ELLE NE COÛTE RIEN (v5.0.0, signalé à l'usage :
  « en dessous de 780 px il se rétrécit encore, sans raison valable » — vérifié, il n'y en avait
  pas)** : il tombait de 46 à 38 px sous ce seuil et s'en remettait au halo `::after` pour atteindre
  les 44 px de cible. Or **mesuré, la rangée fait 59 px des deux côtés** : c'est le sélecteur de
  mode (46 px) qui la dimensionne. Le rétrécissement ne rendait aucun pixel — il désalignait les
  deux contrôles de la même rangée et faisait dépendre la cible d'un halo qui ne se mesure pas.
  Le libellé abrégé « Cons. » est PURGÉ avec lui (balisage mort depuis que le mot tient partout).
- **PRENDRE DU RECUL EST UNE EXCURSION, PAS UN CHANGEMENT DE FORMAT (v5.0.0, lot A — audit design
  + retour d'usage : « ça arrive de basculer en cours de session, notamment pour prendre du recul
  et avoir une vision d'ensemble », « difficile de trouver la bonne information en mode guidé
  parfois »)** : le besoin est réel et fréquent — il a donc gagné sa place dans le chrome de crise.
  Ce qui était faux, c'est le MÉCANISME. Un sélecteur segmenté **remplace la vue de travail et ne
  ramène personne** : on prend du recul, on trouve son information, et si l'on n'y repense pas on
  **termine le soin dans un format qu'on n'avait pas choisi**. C'est de la mode confusion au sens
  FAA (un même écran qui se comporte autrement sans signal univoque), et c'est plus grave que les
  151 px que le segmenté coûtait.
  **LE CONTRÔLE NOMME SA DESTINATION, JAMAIS SON ÉTAT** — « ⤢ Tout voir » à l'aller, « ↩ Un bloc »
  au retour, à la MÊME position, avec le registre CONFIRMATION au retour. C'est le patron déjà
  éprouvé de l'excursion sur complication (`↩ Reprendre — <bloc> →`, v4.26.0) : le retour fait
  partie du dispositif, il n'est jamais laissé à la mémoire (AC 120-71B). Mesuré : **0 px** de
  déplacement du bouton ET de la rangée dans les trois états.
  **ET L'EXCURSION N'ÉCRIT PAS LA PRÉFÉRENCE** : regarder n'est pas régler — prendre du recul dix
  fois dans un soin ne doit pas finir par changer le format d'ouverture de toutes les fiches (même
  règle que `state.allTab`, transitoire par nature). Le format PAR DÉFAUT se choisit **à froid**,
  dans Compte › Affichage, à côté du thème et de la taille du texte, c'est-à-dire au seul endroit
  du produit où l'on règle. `#modeSeg` et `.ctrl-sp` sont PURGÉS (règle 14) — l'écart de Gestalt
  ne séparait le MODE des OUVERTURES que parce qu'il y avait un mode ; il n'en reste que deux
  ouvertures de même nature, et l'enroulement de `fitCtrlRow` coupe naturellement entre elles.
  ⚠ **`audit-modeseg` N'EST PAS SUPPRIMÉ, IL EST RETARGÉ** sur `#dispSeg` : ses trois contrôles
  (pastille alignée, libellés immobiles, glisser au doigt) valent pour TOUS les segmentés du
  fichier et n'ont rien à voir avec la crise — même leçon que `audit-lecteur` → `audit-retour`.
  ⚠ **COLLISION DE NOMS DE CLASSE, REJOUÉE AU PRIX D'UNE MESURE** : j'avais nommé le modificateur
  d'état `.back`, qui est une classe AUTONOME du projet (le retour d'en-tête) portant
  `margin-bottom:14px`. La rangée de commandes gagnait donc **14 px de haut à l'instant de la
  bascule** (59 → 73 px) et les deux boutons se désalignaient de 7 px — un saut de chrome sous le
  doigt. Un modificateur d'état porte TOUJOURS le préfixe de son composant (`.dp-back`) : c'est la
  leçon v4.23.2, et elle se re-perd dès qu'on ne la relit pas.
- **LE VERT NE DIT QU'UNE CHOSE : « VOUS ÊTES LOIN DE CHEZ VOUS, CECI VOUS Y RAMÈNE » (v5.0.0,
  lot A, signalé à l'usage : « si j'ai choisi “toute la fiche” par défaut, je vois en permanence un
  gros bouton vert “retour au bloc” — c'est perturbant »)** : la remarque est juste et elle touche à
  la sémantique du registre. Le CONFIRMATION rempli est celui du RETOUR D'EXCURSION ; l'afficher en
  permanence à quelqu'un qui n'est parti nulle part, c'est l'inflation qui vide le vert de son sens
  — exactement ce que le dossier reproche au rouge permanent. La condition n'est donc pas « je suis
  en statique » mais **« je ne suis pas dans MON format d'ouverture »**. C'est symétrique par
  construction : qui lit d'ordinaire la fiche entière voit un ⤢ neutre au repos, et un ↩ vert quand
  il est allé voir un bloc. Le témoin mesure les DEUX préférences — sans quoi il ne rencontrerait
  que la moitié de son cas.
- **CHERCHER DANS L'AIDE PENDANT LE SOIN (v5.0.0, lot B — retour d'usage : « difficile de trouver
  la bonne information en mode guidé parfois »)** : c'était CE besoin qui faisait basculer de
  format, et le format n'y répondait qu'en montrant tout d'un coup. La feuille « Toute la fiche »
  reçoit donc le composant de recherche de la lecture de référence, à **racine variable**
  (`_pfRoot`) : aucun second parseur, aucun second surlignage, un seul jeu d'identifiants — les
  deux surfaces ne coexistent jamais à l'écran.
  **TROIS GARDE-FOUS, tous nécessaires ici** : (a) elle **ne filtre pas**, elle surligne et saute —
  masquer laisserait croire que le reste n'existe pas, et dans une aide de crise c'est le pire mode
  de défaillance ; (b) elle **ne passe jamais par `innerHTML`** — le surlignage parcourt les nœuds
  de texte et n'insère que des nœuds créés (règle 4 : on ne rouvre pas une seconde occasion de se
  tromper), et le témoin vérifie qu'après effacement **le document revient à l'identique** ;
  (c) elle **n'est pas le chemin obligé** — taper avec des gants sous adrénaline n'est pas fiable,
  c'est un accélérateur pour qui SAIT ce qu'il cherche, la vue d'ensemble reste entière dessous.
  **PAS SUR LE SCHÉMA** : ses textes vivent dans un SVG, où un `<mark>` n'est pas un nœud valide —
  on abîmerait le dessin pour surligner un mot. L'onglet le dit en n'offrant pas le champ, plutôt
  qu'en offrant un champ qui ne trouve rien.
  **LA RACINE SUIT L'ONGLET, ET LA REQUÊTE EST REJOUÉE** : les deux onglets textuels n'ont pas le
  même conteneur (`.pc-wrap` / `.sv-tb`), chercher dans l'ancien ne trouverait rien et laisserait
  croire que le mot n'y est pas. La requête vit le temps de la feuille (`_pfQ`), n'est ni persistée
  ni synchronisée — c'est une consultation. Cibles **44 px** et champ à **16 px** (règle 9) :
  mesuré à 320 px, 0 px de débordement.
- **⚠ LE HARNAIS D'ACCESSIBILITÉ MESURE DES SURFACES, PAS DES ÉTATS (v5.0.0, audit de design — et
  ce sont MES deux régressions qu'il a laissé passer)** : `audit-a11y` ouvre chacune des 25
  surfaces AU REPOS. Or le surlignage de recherche n'existe qu'une fois une requête tapée, et le
  vert du bouton d'excursion qu'une fois parti — ni l'un ni l'autre n'était donc dans son champ, et
  ses 301 contrôles restaient verts pendant que deux violations AA vivaient à l'écran.
  **Mesuré avant correction** : surlignage **3,64:1 en clair et 1,76:1 en sombre** (texte de
  11 px), bouton vert **1,9:1 en sombre**.
  **DEUX CAUSES, DEUX RÈGLES** : (a) `color:inherit` sur un fond FIXE fait dépendre le contraste de
  l'endroit où le mot se trouve — un surlignage définit ses DEUX couleurs, jamais une seule ;
  (b) en sombre, `--ok` est un REMPLISSAGE CLAIR, donc son encre est `--bg`, jamais `--on-primary`
  (règle déjà écrite pour les pastilles du rail, qui vaut pour tout aplat vert).
  Et l'occurrence COURANTE se distingue désormais par la **forme** (contour + graisse) et non par
  une seconde paire de couleurs, qui rouvrait le même problème à l'envers. Témoins ajoutés dans
  `audit-doctrine` : ils CONSTRUISENT l'état avant de mesurer, dans les deux thèmes.
- **L'ENTRÉE SUR COMPLICATION — B, C, D (v5.0.0, audit design)** : trois défauts mesurés.
  **(B) À UN SEUL ÉVÉNEMENT, IL N'Y A PAS D'INDEX.** Ouvrir une liste d'UN élément pour y choisir
  cet élément est le bouton mort de la doctrine, en plus lent. L'événement DEVIENT le bouton, on
  entre d'un tap. **L'arbitrage est nommé et il a été tranché par l'auteur** : le libellé devient
  variable d'une fiche à l'autre, alors que la doctrine dit « un mot constant à position constante
  s'apprend » — mais à UN seul événement, lire un mot n'est pas scanner cinq boutons, ce qui est
  précisément le reproche fait aux N boutons rouges ; le glyphe ⚡ et la POSITION restent constants.
  ⚠ **Une complication peut être une PORTE vers une autre aide** : le libellé le dit alors par
  « ↗ », sinon on croirait rester dans la fiche et l'on se retrouverait ailleurs sans l'avoir voulu.
  **(C) L'INDEX EST UN DÉPLIANT, PAS UNE FENÊTRE.** La doctrine QRH invoquée porte sur l'INDEX
  UNIQUE (un objet plutôt qu'un bouton par urgence), **pas sur la modalité** : un dépliant est aussi
  un index unique. Mesuré, la fenêtre couvrait **38 % de l'écran à 320 px, pendant un soin** — et
  c'est la leçon du lot M11, payée là-bas au prix de sauts de 1120 px et 484 px. `#cxModal`,
  `openCxDlg`, `closeCxDlg`, `#cxList` et `data-cxpick` sont PURGÉS (règle 14) ; le menu ⋯ ouvre le
  dépliant et amène la carte courante à l'écran — c'est une navigation DEMANDÉE par un tap, pas un
  défilement autonome. `state.cxOpen` est transitoire (`SHARE_LOCAL`), comme `state.allTab`.
  **(D) LE RETOUR D'EXCURSION EST EN TÊTE DE CARTE.** Il vivait après les étapes : mesuré à
  320 × 640, il naissait à **y = 738**, c'est-à-dire hors écran, alors que la doctrine le décrit
  comme « LE contrôle rempli de l'écran pendant l'excursion ». Après : **y = 329**, visible.
  ⚠ **L'ENTRÉE, ELLE, N'A PAS BOUGÉ — décision de l'auteur, et le raisonnement est le sien** : la
  mettre en tête de carte donnerait la position de plus forte saillance à l'événement le MOINS
  probable et repousserait les cases à cocher vers le bas. La dissymétrie entrée/retour n'est pas
  une inconséquence : une fois DANS l'excursion, revenir EST l'action principale, et ce que le
  retour repousse, ce sont les étapes de la complication où l'on vient d'entrer.
  ⚠ **La surface « excursions » d'`audit-a11y` change de PORTEUR, pas de nature** : elle vise
  `.cx-list` et construit désormais son cas (deux événements — à un seul, il n'y a pas d'index).
- **LE HARNAIS D'ACCESSIBILITÉ MESURE DÉSORMAIS DES ÉTATS ET CINQ SURFACES DE PLUS (v5.0.0,
  audit design, action 1 et 2)** : il ouvrait ses 25 surfaces AU REPOS, et à 1100/1280/390 px.
  Manquaient donc **la bibliothèque en voie étroite** (chips de filtre, rail A→Z, rangées du
  répertoire), **la lecture d'une référence**, **le mode statique**, **le moniteur**, **l'éditeur
  de protocole** — et **320 px**, le plancher que le dossier déclare servir, n'était mesuré que sur
  l'écran d'entrée invité. Cinq **ÉTATS** entrent aussi : recherche active, excursion (retour),
  minuteur échu, index ⚡ déplié, lien de partage mort.
  **CHAQUE ÉTAT DÉCLARE CE QUI DOIT EXISTER (`must`), ET SON ABSENCE EST UN ÉCHEC** — sans quoi la
  sonde mesure le repos en croyant mesurer autre chose, la leçon la plus redite du dossier. Elle a
  immédiatement payé : deux états ne se construisaient pas, et l'un des deux a révélé un **défaut
  préexistant** (voir ci-dessous).
  **TROIS DÉFAUTS TROUVÉS PAR L'EXTENSION**, tous corrigés : le champ de recherche n'avait **aucun
  anneau de focus** (`outline:none` + un simple changement de teinte de filet d'1 px — WCAG 2.4.11
  et la règle « tout nouvel élément interactif reçoit un `:focus-visible` ») ; `#hdrBack` était à
  **39 px de cible** (voir plus bas) ; et le retour d'excursion **n'existait pas sur un bloc de
  décision**.
- **LE RETOUR D'EXCURSION EXISTE AUSSI SUR UN BLOC DE DÉCISION (v5.0.0, défaut PRÉEXISTANT)** :
  `↩ Reprendre` n'était émis que dans la branche « bloc d'étapes ». Entrer sur une complication
  dont la cible est une DÉCISION laissait donc sans retour — le dispositif promet que le retour
  n'est jamais laissé à la mémoire (AC 120-71B), il ne le tenait qu'à moitié. Une seule fabrique
  (`cxBackHtml`) sert les deux natures de bloc : un gabarit écrit deux fois finit par diverger, et
  c'est exactement ce qui s'était produit.
- **DIX-SEPTIÈME PIÈGE DE CASCADE — UN MEMBRE DE LISTE `:is()` DÉCLARÉ PLUS BAS (v5.0.0)** :
  `.hdr-back` faisait 31 × 40 px avec un halo de 4 → **39 px de cible**, sous les 44 de la doctrine
  et de HIG. Son halo propre à -7 px ne s'appliquait pas : la liste générique
  `:is(.hdr-new,.hdr-theme,.hdr-act2,.bar-acct,.hdr-back)::after{inset:-4px}` est déclarée plus bas
  et gagnait par l'ORDRE. On règle en **RETIRANT le membre de la liste**, pas en ajoutant une
  exception encore plus bas. Après : **45 px de cible, hauteur d'en-tête inchangée** — c'est tout
  l'objet du halo, admis en zone haute précisément pour ne pas l'épaissir.
- **LES TROIS ÉCHELLES QUI MANQUAIENT SONT FERMÉES ET GARDÉES (v5.0.0, audit design, actions 4, 5
  et 8)** : le dossier verrouillait les couleurs, le texte et les paliers responsive — mais
  **l'espacement n'avait aucun token ni aucun garde-fou** (valeurs de 1 à 26 px prises au cas par
  cas : 138 usages de 8, 112 de 6, 89 de 10, 65 de 9, 55 de 7…), le **rayon avait dix-neuf valeurs
  pour trois tokens**, et **neuf tailles d'affichage** vivaient hors de toute échelle. Ce n'est pas
  une question de pureté : deux rembourrages à 1 px d'écart ne sont pas deux niveaux, ce sont deux
  inattentions — l'argument qui a fermé l'échelle typographique en v4.71.1, mot pour mot.
  **LES ÉCHELLES SONT CHOISIES SUR LA DISTRIBUTION RÉELLE, pas dans l'abstrait** : la migration
  n'a déplacé aucune valeur de plus d'1 px (espacement) ou 2 px (rayons, affichages), ce qui la
  rend vérifiable par les harnais existants — cibles de 44, rangées de 71, budgets d'écran — au
  lieu de reposer sur une relecture.
  **ET ELLE A IMMÉDIATEMENT COÛTÉ CE QU'ELLE DEVAIT COÛTER** : le halo de l'épingle du répertoire
  est passé de -9 à -8 px, donc sa cible de 44 à **42** — six harnais rouges. Deux contraintes s'y
  rencontrent (cible ≥ 44 ET halo ≤ rembourrage droit de la rangée, sinon l'épingle sort du cadre),
  et c'est la BOÎTE qui monte à 28 px : 28 + 2 × 8 = 44 pile. **C'est exactement ce qu'une échelle
  fermée doit provoquer — un déplacement mécanique se VOIT, il ne se subit pas.**
- **LE PRÉAMBULE AVANT LA PREMIÈRE ÉTAPE — DEUX TITRES REDONDANTS EN SESSION (v5.0.0, audit
  design, action 3)** : mesuré à 320 × 640, session démarrée, la première case à cocher naissait à
  **y = 438 px**, soit **68 % de l'écran** consommés avant la première ligne actionnable. Deux
  titres y disaient la même chose que la carte qu'ils surmontent — l'intitulé de l'étage COURANT
  (« Prise en charge ») et le sous-titre « Parcours » — alors que la carte porte déjà son numéro et
  son titre. Ils disparaissent **en session seulement** : hors session ils restent, parce qu'on
  s'oriente avant d'agir et que les étages sont alors une vraie séquence à lire.
  **Mesuré après : 387 px (−51), 60 % de l'écran à 320, et 2 étapes entièrement visibles au lieu
  d'1 — 5 au lieu de 4 à 390 px.**
  **CE QUI RESTE, ET QUI N'EST PAS À MOI DE TRANCHER** : la rangée d'en-tête de carte
  (« Vous êtes ici » + « Vérifier ») coûte **54 px à 320 px** parce qu'elle passe sous le titre.
  Déplacer « Vérifier » au pied de la carte — sa place logique, la seconde passe commençant quand
  la première est finie — rendrait ces 54 px et amènerait le préambule sous 340. C'est un
  déplacement de geste, donc une décision de conception.
- **ACTION 7 (DÉSATURER LES CATÉGORIES) : MESURÉE, PUIS REFUSÉE — et c'est la mesure qui l'a
  refusée (v5.0.0)**. L'objectif était d'éloigner les treize couleurs de catégorie des registres
  (la rouge « Urgences » #b6382f est la plus proche de `--critical-bd`). Une désaturation d'ensemble
  (× 0,72, luminance bornée) l'éloigne bien — mais **elle rapproche deux catégories l'une de
  l'autre au point de les confondre** (écart minimal 32,4 → **11,6**) et **fait tomber le contraste
  des pastilles en thème sombre à 2,29**, sous le seuil de 3:1 des composants (WCAG 1.4.11). Une
  recherche sous contraintes (≥ 45 d'écart aux autres catégories, ≥ 4,5:1 en clair, ≥ 3:1 en
  sombre) ne trouve **aucune** position meilleure pour la rouge : la palette est déjà à sa limite
  de distinction. **Le remède serait donc pire que le mal**, et la protection existante n'est pas
  la couleur mais la RÈGLE (la catégorie est un liseré et une pastille, jamais un signal ; elle est
  toujours nommée en toutes lettres). À rouvrir seulement si l'on accepte de réduire le NOMBRE de
  catégories offertes.
  **ROUVERTE EN OKLCH ET TRANCHÉE PAR LA MESURE (v5.1.1, audit direction A, point 1)** : la
  conclusion de v5.0.0 était juste pour une désaturation D'ENSEMBLE, mais la métrique sRGB
  masquait que le problème était PONCTUEL. Re-mesuré en dE_OK (distance OKLab ×100) : trois
  COLLISIONS DE REGISTRE (l'olive #806311 à **3,0** de `--verify` — perceptuellement le registre
  ambre —, le vermillon à 3,1 de `--critical-bd`, le vert #1d7449 à 3,3 de `--ok`), une PAIRE
  confusable (les deux sarcelle/bleu à 5,1 l'une de l'autre) et **quatre teintes sous 3:1 sur
  surface sombre** (2,26 à 2,56 — la couleur stockée est rendue BRUTE dans les deux thèmes).
  Correction CHIRURGICALE au solveur sous contraintes : seules les SIX teintes à problème nommé
  bougent (0, 2, 4, 5, 6, 9), déplacement borné à dE_OK ≤ 8 — et les retenus sont MINUSCULES
  (1,3 à 2,8, sauf l'indigo 9 à 6,2 pour son contraste sombre) —, chroma quasi inchangée (le
  caractère sourd est voulu — un premier solveur qui maximisait les distances librement proposait
  des néons : objectif corrigé en lexicographique sur les plus petites distances).
  **⚠ LES CONTRAINTES DE CLAIR SONT CELLES DU TEST DE RÉGRESSION #3, PAS « SUR BLANC »** : texte
  couleur sur sa teinte à 15 % ≥ 4,5 ET blanc sur couleur pleine ≥ 4,5 (`tint15`/`ratio` de
  tests.html, repris à l'identique dans le solveur). Un premier jet contraint « sur blanc » a
  produit trois teintes que `npm test` refusait (3,74-3,95) — le garde-fou a fait exactement son
  travail, et la leçon est générale : un solveur de couleurs REPREND les contraintes du test qui
  le jugera, il ne les redevine pas. **Plancher des distances : 3,0 → 4,0** (cat2~verify 3,0→4,0,
  cat0~critical-bd 3,1→4,9, paire sarcelle 5,1→5,9) ; le sombre de la n° 9 passe de 2,37 à 3,10.
  **TROIS teintes restent < 3:1 en sombre** (#45556b, #0d5b56, #7a2f6b) : le solveur ne trouve
  AUCUN candidat conforme dans le budget de reconnaissabilité — dit, pas caché, et atténué par
  « la couleur n'est jamais seule ». **SANS RUPTURE par construction** : la couleur vit DANS la
  catégorie stockée — les choix existants ne changent pas, seuls la palette proposée et
  `defaultCats` (nouvelles installations) sont corrigés. Corollaire assumé : la pastille `.sw.on`
  d'une catégorie ancienne ne se surligne plus dans le nuancier (sa couleur n'y figure plus) —
  cosmétique, et préférable à réécrire les données.
- **ON NE PROPOSE PAS D'ENTRER LÀ OÙ L'ON EST DÉJÀ (v5.0.0, signalé à l'usage : « j'ai cliqué sur
  complication bronchospasme réfractaire, et sur la fiche j'ai encore le bouton bronchospasme
  réfractaire »)** : à UN SEUL événement, le bouton PORTE son nom depuis le lot B — le voir pendant
  qu'on exécute ce bloc laisse croire qu'on n'y est pas encore. Il **disparaît** donc, et c'est
  « aucun bouton mort » ; la carte n'est pas pour autant sans contrôle, `↩ Reprendre` est en tête,
  juste au-dessus. **À DEUX OU PLUS, l'index RESTE** (décision de l'auteur : on peut vouloir passer
  d'un événement à l'autre) — mais la rangée où l'on se trouve **s'y annonce (« vous y êtes ») et
  n'est plus tapable**, plutôt que d'être retirée : une liste dont les rangées disparaissent selon
  l'endroit où l'on est ne s'apprend pas. Apparence de FERMÉ reprise du scribe et du mode
  déplacement — une seule grammaire de « fermé » dans le fichier.
  ⚠ **Piège de témoin rencontré** : la première version rouvrait l'index puis cliquait la rangée
  courante — laquelle est justement DÉSACTIVÉE. Le clic ne faisait rien et le tap suivant
  REFERMAIT l'index : zéro rangée mesurée. On mesure l'état là où il existe DÉJÀ.
- **L'ACCENT SE CONFINE À L'AVATAR (v5.0.0, audit design — l'auteur a défendu la fonction, et il a
  raison)** : sur un ordinateur PARTAGÉ, reconnaître d'un coup d'œil à quel compte appartient cette
  fenêtre est un vrai besoin, et les initiales du bouton Compte ne se lisent pas de loin. **Ce qui
  change est la PORTÉE, pas la fonction** : l'accent teintait l'accueil ENTIER et l'en-tête de
  toutes les vues — soit la seule couleur du produit qui ne portait aucun sens, dans un système
  dont la règle fondatrice est que la couleur en porte toujours un, et **70 hex sur 104**. Réduit
  au DISQUE de l'avatar, il en porte un : « cette fenêtre appartient au compte X ». La
  reconnaissance périphérique est conservée (un disque coloré à position constante), la concurrence
  avec les registres disparaît partout ailleurs, et la palette d'accent tombe à **10 hex**.
  Un token `--accent` par accent et par thème, une seule règle qui le consomme.
- **TOUS LES INTERTITRES DE LA COLONNE D'ORIENTATION PARTENT DU MÊME x (v5.0.0, demande
  utilisateur)** : « ⚡ À tout moment » et « Surveiller après les gestes » s'alignent sur
  « Parcours inerte » — et, en rail unique, sur « Minuteurs & compteurs » et « Repères
  posologiques ». Mesuré avant : 18 / 20 / 23 px ; après : 18 partout, dans les deux régimes.
  **ET LE LISERÉ ROUGE EST AUX RANGÉES, PAS AU TITRE** (après essai de l'inverse) : posé sur le
  GROUPE il décalait l'intertitre du reste de la colonne, et un titre est un repère de LECTURE,
  pas un objet du registre — ce qui est hors séquence, ce sont les complications elles-mêmes.
- **ENTRER SUR UNE COMPLICATION AMÈNE EN HAUT DU BLOC (v5.0.0, signalé à l'usage)** : le
  défilement n'existait que dans UNE des trois branches de `cxEnter` — ni au tout premier geste de
  la session (qui re-rend tout), ni en mode « Toute la fiche », où l'on restait exactement où l'on
  était. Une seule fabrique (`cxScrollTo`) sert les deux vues : deux défilements écrits séparément
  finiraient par diverger, et l'un des deux manquait déjà. **Et le menu ⋯ n'avait AUCUN effet en
  vue statique** (`renderOvOnly` n'y rend rien) : il amène désormais à la section « ⚡ À tout
  moment » du tableau. Entrer sur une complication est une NAVIGATION demandée, pas un tap sur ce
  qu'on a déjà sous les yeux : la règle « rien ne bouge sous le doigt » vise le second cas.
- **« ⤢ COMPLET » EST SUPPRIMÉ (v5.0.0, demande utilisateur, après vérification MESURÉE)** : il
  ouvrait la feuille `#planModal`, laquelle rend `ovPlanHtml` — c'est-à-dire **exactement ce que la
  colonne montre déjà** : 8 rangées identiques, 281 caractères dans la colonne contre 326 dans la
  feuille (l'écart n'est que l'ellipse des titres). Sa seule valeur ajoutée était la LARGEUR
  (223 → 1280 px). ⚠ **Et l'onglet « Parcours » NE fait PAS doublon avec elle**, contrairement à ce
  qu'on pouvait croire : il rend `ovParcoursHtml`, soit **7 cartes et 22 items pour 1 321
  caractères** — un autre objet, pas un autre habillage. C'est la FEUILLE qui doublonne la COLONNE.
  La feuille reste joignable par le menu ⋯ « Se repérer » : rien n'est perdu, sauf un tap.
  `.rail-exp` est purgée avec le bouton (règle 14).
- **« VÉRIFIER » DESCEND AU PIED DE LA CARTE (v5.0.0, demande utilisateur, après mesure)** : il
  vivait dans l'EN-TÊTE, à côté de « Vous êtes ici » — et cette rangée passe SOUS le titre à
  320 px, où elle coûtait **54 px au-dessus de la première case à cocher**. Sa place logique est le
  pied : la seconde passe (Do-Verify) commence quand la première est FINIE, elle ne la précède pas.
  L'en-tête ne garde que ce qui dit OÙ l'on est ; le pied porte ce qui fait AVANCER, ce qui RAMÈNE
  et ce qui RE-VÉRIFIE. **« ↺ Refaire » RESTE en tête**, et ce n'est pas une inconséquence : il ne
  s'applique qu'aux cartes PASSÉES, qui n'ont pas de pied d'action. Mesuré : en-tête **106 → 81 px**,
  première étape **387 → 361** (cumul depuis le début de l'audit : **438 → 361**, soit 68 % → 56 %
  de l'écran à 320 × 640).
- **UN SEUL DESSIN D'ÉTAT VIDE (v5.0.0, audit design, action 10)** : il y en avait DEUX grammaires
  — `.empty` (cadre pointillé, titre, action, pour un écran entier vide) et un simple paragraphe
  posé au fil de l'eau, tantôt `.auth-msg` tantôt `.ai-note` selon l'endroit, donc deux corps, deux
  couleurs et deux marges pour la même chose. `.empty-line` est le composant, `emptyLine()` son
  point d'écriture unique. **La distinction entre les deux reste** : `.empty` quand l'écran n'a
  rien d'autre à montrer ET qu'il y a une ACTION à proposer ; `.empty-line` dans un panneau ou une
  fenêtre, où le reste de l'interface tient déjà debout.
  ⚠ **Ma formulation d'audit était fausse** : j'avais écrit « deux états vides seulement » en ne
  comptant qu'une classe. Le défaut n'était pas qu'il en manquait, c'est qu'il y en avait deux
  formes.
- **LE RAIL A→Z EST CENTRÉ VERTICALEMENT (v5.0.0, demande utilisateur — REVIREMENT ASSUMÉ de
  l'ancrage en haut)** : la v4.73.0 puis la v5.0.0 l'avaient ancré en `flex-start` sur un défaut
  signalé (« sa position bouge sans cesse »). ⚠ **CE QUE LE CENTRAGE RÉOUVRE, ET IL FAUT LE
  SAVOIR** : la position des lettres dépend alors de LEUR NOMBRE — filtrer ou chercher en change
  la quantité et déplace la colonne. C'est INHÉRENT au centrage, aucune technique ne l'évite ;
  c'est un arbitrage de l'auteur, pas un oubli. **CE QUI RESTE GARANTI** est l'autre moitié du
  problème d'origine, et c'est ce que les témoins mesurent : le rail ne bouge NI au défilement NI
  pendant qu'on s'en sert (clic, glisser) — vérifié à six largeurs de 320 à 1440 px, déplacement
  0 px sur les trois gestes. Sa BOÎTE est stable : bornée par `--hdr-h` (constante dans une vue)
  en étroit, par la coque fixe de l'accueil en large ; un centrage dans une boîte qui ne bouge pas
  ne bouge pas non plus.
  **⚠ ET C'EST `100svh`, SURTOUT PAS `--vvh` NI `dvh` (v5.0.1, signalé à l'usage : « il bouge sous
  mon doigt alors qu'il est censé rester fixe »)** — la moitié « garantie » ci-dessus ne l'était
  pas : le recentrage avait laissé la hauteur en `--vvh`, c'est-à-dire `visualViewport.height`, LA
  mesure qui suit la barre d'outils du navigateur mobile. Le défaut de la v4.73.0 était donc revenu
  tel quel, et par le pire chemin : le glisser fait DÉFILER, le défilement replie la barre, la
  boîte grandit, les lettres descendent de la MOITIÉ de l'écart, la lettre visée change — un
  asservissement qui s'entretient lui-même. `100svh` est le **small viewport**, la hauteur qu'a la
  fenêtre barre d'outils DÉPLOYÉE : une constante. La boîte ne peut alors jamais dépasser le bord
  visible, et le test de débordement de `bindAzRail` en devient plus fiable, n'étant plus mesuré
  sur une hauteur qui change d'un instant à l'autre. Le clavier n'est pas un cas (le rail n'existe
  qu'en RÉPERTOIRE ; saisir bascule sur la liste plate, où il n'est pas rendu).
  **RÈGLE GÉNÉRALE** : `--vvh` est la mesure d'une surface qu'on veut voir ENTIÈREMENT MAINTENANT
  (overlays, fenêtres, menu ⋯) ; une surface PERSISTANTE dont la position doit être APPRISE se
  borne au `svh`, sinon elle suit la barre d'outils et se déplace pendant qu'on s'en sert.
  Corollaire pour le geste : le mapping doigt → lettre est relevé UNE FOIS à la prise, jamais
  re-mesuré à chaque mouvement — insensible par construction à une géométrie qui bougerait demain.
  **⚠ ET `svh` NE SUFFISAIT PAS — LE SECOND TERME EST LA MARGE BASSE DU MATÉRIEL (v5.0.2, signalé
  à l'usage : « ça persiste en partie, surtout quand on scroll vers le bas sur le rail : il
  remonte »)** : dans Safari iOS, `env(safe-area-inset-bottom)` n'est **pas une constante** — la
  barre d'outils du bas COUVRE la bande de l'indicateur d'accueil, donc l'inset vaut 0 barre
  déployée et saute à ~34 px dès qu'elle se replie, c'est-à-dire au défilement. La hauteur perdait
  34 px et les lettres centrées remontaient de 17. Le terme est retiré : `100svh` est déjà la
  hauteur *barre déployée*, son bord bas est donc au-dessus de cette barre, donc au-dessus de
  l'indicateur. **EN APP INSTALLÉE l'arbitrage s'inverse** — sans barre d'outils, `svh` descend au
  bord de l'écran, indicateur compris, mais l'inset y est CONSTANT : il est retranché sous
  `@media (display-mode:standalone)`, et là seulement.
  **RÈGLE : dans une hauteur qui doit être stable, `env(safe-area-inset-bottom)` est aussi suspect
  que `--vvh`** — le vérifier avant de l'écrire.
  ⚠ **ET LE TÉMOIN EST STATIQUE, DÉLIBÉRÉMENT** : les deux termes fautifs sont INVISIBLES en
  headless (`--vvh` y vaut une hauteur qui ne varie jamais, l'inset y vaut 0 et aucune API ne le
  simule) — un contrôle dynamique serait resté vert sur le défaut. On mesure la SOURCE.
  **⚠ ET CE N'ÉTAIT TOUJOURS PAS LA CAUSE — signalé DEPUIS LA PWA, donc sans barre d'outils ni
  inset qui bougent (v5.0.2, second correctif)** : les deux points ci-dessus étaient justes et ne
  pouvaient rien expliquer chez quelqu'un dont l'environnement n'a ni l'un ni l'autre. Deux
  entrées dynamiques restaient, toutes deux INVISIBLES sur Blink :
  **(1) UN SAUT SE CALCULE EN ABSOLU, JAMAIS EN RELATIF.** Le saut était un déplacement RELATIF
  (`scrollBy`, `scrollTop +=`) dont le pas se déduisait d'un `getBoundingClientRect()` — la
  position DÉJÀ RENDUE — puis s'ajoutait à la position COURANTE. Sur Blink les deux sont la même
  chose (défilement synchrone ; sonde : course monotone, 0 oscillation). **Sur iOS le défilement
  est ASYNCHRONE** : le rect peut refléter une position que le compositeur n'a pas appliquée alors
  que `scrollY` est à jour — on ajoute un pas déjà parcouru, on dépasse, le mouvement suivant
  corrige en négatif, et à 60 Hz c'est une oscillation : **on descend, ça remonte**. La cible se
  calcule donc dans les OFFSETS DE MISE EN PAGE (indépendants de tout défilement) et se pose en
  absolu — idempotent par construction. **RÈGLE : un geste RÉPÉTÉ à la cadence du doigt ne se
  déplace jamais en relatif ; un pas relatif suppose que la mesure et la position sont de la même
  frame, ce qu'aucun moteur ne garantit.**
  **(2) LA BOÎTE EST GELÉE DANS `--azr-top`, POSÉE AU RENDU.** Le haut valait `--hdr-h`, propriété
  que `syncHdrScroll` RÉÉCRIT à chaque défilement depuis un rect de l'en-tête COLLANT. Sur Blink un
  sticky est repositionné avant l'évènement, la mesure est donc toujours juste (vérifié :
  constante sur toute la course) ; sur iOS, où défilement et collants sont composités, rien ne le
  garantit — et le rail étant FIXE, une valeur transitoire lui déplace le haut ET la hauteur, donc
  son centre. Reposée au redimensionnement et à la rotation seulement ; le repli CSS garde
  `--hdr-h` pour la toute première peinture.
  **CE QUI EST MESURÉ** : géométrie INCHANGÉE au repos (168/670 px à 390), atterrissage à 8 px
  sous les couches collantes, et **deux sauts de suite ne déplacent plus rien** — l'idempotence
  est ce qui casse l'oscillation, et c'est la seule moitié du dossier qu'un moteur headless sait
  voir.
  **⚠ ET LA CAUSE RESTANTE N'EST PAS UNE MESURE — C'EST LE REBOND DE FIN DE PAGE (v5.0.2, signalé
  à l'usage : « ça se produit quand on arrive en fin de scroll de page, quand il y a le bounce »)** :
  pendant le rubber-band, WebKit TRANSLATE le document ET les éléments `position:fixed` — le rail
  part avec le rebond puis revient, sous le doigt qui le vise. Ce n'est pas une valeur qui change,
  c'est une transformation appliquée au rendu par le compositeur, **en dehors de toute mesure
  lisible en JS** : voilà pourquoi aucune des trois corrections de formule ne pouvait suffire.
  `overscroll-behavior-y:none` supprime le rebond DU DOCUMENT, et il est **borné à l'accueil en
  voie étroite** — le seul endroit où une surface FIXE se vise au pixel et à la cadence du doigt.
  Ailleurs le rebond RESTE (affordance native « fin de liste ») ; en voie large l'accueil est une
  coque fixe et le rail y est `absolute`, donc jamais concerné ; les fenêtres gardent leur
  `contain`. ⚠ La déclaration vit sur `html` (via `:has()`) ET sur `body` : la propagation vers le
  viewport part de la racine, la poser sur le corps seul est sans effet.
  **RÈGLE : une surface FIXE qu'on VISE doit vivre dans un document sans rebond** — sinon le
  compositeur la déplace pendant qu'on s'en sert, et rien, côté application, ne peut le voir.
  **⚠ MAIS LA SUPPRESSION NE DURE QUE LE GESTE (signalé à l'usage : « le scroll des cartes n'est
  plus très ergonomique, s'arrête, est lent »)** : posée en permanence sur l'accueil, la règle
  corrigeait le rail et cassait le défilement — sur WebKit, `overscroll-behavior` n'ampute pas que
  le REBOND, il ampute aussi l'INERTIE. Le geste le plus fréquent de l'écran payait alors le
  confort d'un geste rare. La classe `azr-aim` est posée au `pointerdown` du rail (donc AVANT que
  WebKit ne fige les propriétés du défileur pour la séquence tactile — les évènements pointeur y
  précèdent les tactiles) et retirée au relâchement ; un FILET la retire au niveau du document en
  capture et au passage en arrière-plan, une classe restée posée étant le défaut d'origine en pire,
  parce que rien ne le dirait. C'est aussi la portée JUSTE : le rebond ne gêne que pendant qu'on
  vise.
  **⚠ UNE GOUTTIÈRE FANTÔME DE 68 px** : le rail réservait la hauteur de la **tab bar**, supprimée
  au lot M4 (`grep tabBar` : 0 occurrence). Invisible tant que les lettres étaient ancrées en
  haut ; en les centrant, ce vide décalait tout le rail. Corollaire de la règle 14 — **une
  suppression emporte ce qui RÉSERVE sa place, pas seulement ce qui la cite.**
  ⚠ **LE TÉMOIN A CHANGÉ DE PROPRIÉTÉ, PAS DE SUJET** : il exigeait `justify-content:flex-start`,
  un LITTÉRAL CSS — donc un témoin qui rougit sur un changement JUSTE et pousse à le contourner
  (leçon déjà payée sur le corps du titre de rangée). Il mesure désormais ce qui reste vrai :
  collé à droite, et sans gouttière fantôme.
- **LE LOGO EST CENTRÉ ENTRE LE BORD ET LE MOT-MARQUE (v5.0.0, demande utilisateur)** : mesuré,
  **18 px du bord contre 8-10 du texte** — il collait au texte. Trois contraintes posées par
  l'auteur : ne pas élargir le logo, ne pas déplacer le texte, ne bouger que le logo. La SEULE
  façon de les tenir toutes les trois est un décalage **HORS FLUX** (`position:relative; left`) —
  une marge négative décalerait le logo mais le flex ramènerait le texte avec lui, et élargir sa
  boîte pour l'y centrer pousserait le texte à droite. La valeur est la MOITIÉ de l'écart à
  combler, donc elle suit le gap de la rangée (4 px, 5 px sous 430 px où le gap tombe à 8).
  `left` n'entre pas dans l'échelle d'espacement : ce n'est ni une marge ni un rembourrage, c'est
  une correction OPTIQUE dérivée de deux valeurs qui, elles, sont sur l'échelle. Vérifié par
  comparaison directe avant/après : position du texte et largeur du logo **inchangées au pixel**.
- **L'IMPORT REFUSAIT LE FICHIER QUE L'APPLICATION FAIT FABRIQUER (v5.0.0, signalé à l'usage :
  « .zip ou .json de v4 → Fichier illisible »)** — mesuré sur un export RÉEL de l'auteur, 18 aides
  converties. **DEUX défauts, et le second était SILENCIEUX.**
  **(1) LA CLÉ RACINE.** Un export v3 porte `fiches` ; le format v4 porte `aids`. `readImportFile`
  exigeait `imp.fiches` et répondait « Fichier illisible » — sur un JSON parfaitement valide. Le
  prompt de conversion, lui, ne DISAIT pas quelle clé produire tout en imposant « chaque fiche
  devient une AIDE » et `ficheId → aidId` : **une IA fidèle produit donc `aids`, et l'application
  refuse le fichier qu'elle a elle-même fait fabriquer.** Le contrat est désormais écrit dans le
  prompt (racine EXACTE, et « n'invente aucune autre clé »).
  **(2) LE TYPE EST UNE PROPRIÉTÉ, PLUS UNE LISTE.** Depuis le lot T9 la bibliothèque est unique et
  le type est un attribut (`kind`) : le format v4 fusionne donc légitimement aides et références
  dans `aids[]`. L'import avait encore deux listes — et il aurait passé les références par
  `migrate()`, **qui force `kind:'procedure'`**. Six protocoles seraient devenus six aides VIDES,
  **sans le moindre message** : le premier défaut criait, celui-ci se serait tu. On répartit
  désormais par `kind`, à l'entrée et en UN seul endroit (`normalizeImport`, pure et testée).
  **ET « FICHIER ILLISIBLE » CESSE DE MENTIR** : un JSON valide dont la racine est inconnue reçoit
  son propre message, qui NOMME les clés attendues. Un message qui ne désigne pas sa cause envoie
  chercher la panne du mauvais côté — on soupçonne l'encodage, l'archive, la conversion, jamais un
  nom de champ.
  ⚠ **DEUX PIÈGES DE SONDE, tous deux commis ici.** (a) `attBuf` prend l'ENREGISTREMENT, pas
  l'identifiant : ma première mesure annonçait « 0/7 PDF restaurés » sur un import parfaitement
  sain — l'instrument était mal branché, pas l'application (7/7 après correction). (b) Le parcours
  réel POSE DES QUESTIONS (destination, fusionner/remplacer, doublons) : une sonde qui ne clique
  pas `#confirmYes` reste bloquée sur un dialogue et mesure zéro import, ce qui ressemble
  exactement à un échec. Un import de plus d'une fiche n'est pas mesurable sans répondre.
  ⚠ **ET UN PIÈGE DE TEST** : `r.protocols[0].id` LÈVE quand le correctif est absent, `run()`
  s'arrête et toute la suite perd son résumé — un test qui plante en emporte cinquante. Les accès
  y sont défensifs (`(x||[])[0]||{}`) pour produire un ROUGE lisible. Vérifié capable d'échouer :
  4 rouges sur les deux moteurs.
- **UN NOM D'ICÔNE ABSENT NE LÈVE RIEN — IL REND UN BLANC À LA BONNE TAILLE (v5.0.0,
  `scripts/check-icons.mjs`)** : `uiIcon` retombe sur `${P[name]||''}`, donc un nom fantôme produit
  un `<svg>` correctement dimensionné et **sans aucun tracé**. Invisible à la relecture, invisible
  à `check-classes` (la classe `.tic` est bien émise), invisible aux harnais (l'élément existe et
  se mesure). C'est ainsi qu'`user` a vécu dans la pastille de provenance : « 🕮 Partagée » portait
  son dessin, « Perso » portait **11 px de vide**. Le tracé posé est celui du **bouton Compte**, au
  caractère près — deux silhouettes différentes pour une même idée (« vous ») seraient deux dessins
  à apprendre là où il n'y a qu'une notion ; la coque HTML étant statique, elle ne peut pas lire de
  constante partagée, la duplication est donc ASSUMÉE et signalée **des deux côtés**.
  Le contrôle a deux sens (patron `check-harnais`) : tout nom littéral passé à `uiIcon`/
  `headerIcon` existe dans sa table, et toute entrée de table a un tracé non vide. **Il dit ce
  qu'il ne voit pas** : dix appels passent une variable et sortent par construction du champ d'un
  contrôle statique — le dire vaut mieux que de laisser croire à une couverture totale. ⚠ Piège
  d'écriture rencontré : prendre tous les littéraux du premier argument fait entrer la CONDITION
  d'un ternaire (`relKindOf(id)==='p'?'book':'doc'`) — quatre faux positifs ; on retire les
  opérandes de comparaison avant d'extraire. Vérifié capable d'échouer.
- **UNE CONSTANTE DE TRACÉ NE SE JUSTIFIE QU'À PARTIR DU DEUXIÈME LECTEUR (v5.0.0, demande
  utilisateur)** : cinq tracés vivaient en constantes au motif d'être « partagés entre uiIcon,
  headerIcon et les gabarits ». Vérifié : `WARN_GLYPH`, `DOC_GLYPH` et `IMG_GLYPH` le sont
  réellement (les deux tables) et **restent** — les inliner recréerait la duplication qu'elles
  évitent. `BOOK_GLYPH` et `INFO_GLYPH` n'avaient qu'UN lecteur, la table d'`uiIcon` : une
  constante à lecteur unique n'évite aucune duplication, elle éloigne seulement le tracé de sa
  table. Inlinés, et le commentaire qui les couvrait rendu exact — il affirmait un partage qui
  n'existait pas pour deux des cinq.
- **LA BIBLIOTHÈQUE VIDE EST LE SEUL ÉCRAN QUI PEUT ENSEIGNER LA DIFFÉRENCE (v5.0.0, maquette
  d'audit + signalé à l'usage)** : en vue « Tout », l'état vide affichait un titre neutre
  (« Bibliothèque vide ») mais un texte et un bouton **spécifiques des AIDES** — on proposait un
  type là où l'on venait de dire qu'il n'y en avait aucun. La correction ne s'arrête pas à
  neutraliser le libellé : depuis le lot T9 l'accueil MÊLE les deux types, et la NATURE écrite sur
  chaque rangée les **nomme sans les expliquer** — le produit ne dit nulle part ailleurs ce qui
  distingue une aide d'un protocole. Le vide est le seul moment où l'on a la place ET l'attention
  pour le faire : il n'y a rien d'autre à regarder, et personne à interrompre.
  `cfg.kinds` décide du nombre de cartes — **les DEUX en « Tout », une seule dans une vue
  filtrée** : le nombre de cartes est exactement le nombre de choses créables ICI, et le bouton
  d'une carte ouvre la création DE SON type (`state.section` est la source unique du type dans le
  dialogue « Créer », v4.4.2 — même aiguillage que son sélecteur segmenté).
  **MÊME COMPOSANT, MÊME ANATOMIE POUR LES DEUX** (une phrase qui donne le VERBE, puis les objets
  qu'on y trouvera) : deux cartes de formes différentes se liraient comme deux objets sans
  rapport, alors qu'on les met côte à côte précisément pour être COMPARÉES. Le verbe est le seul
  mot en encre pleine de la phrase — « se **déroule** » contre « se **lit** » —, et deux lignes
  se répondent d'une carte à l'autre avec le **même glyphe** (la coche, le chronomètre) : la
  répétition EST la comparaison.
  **⚠ UN PROTOCOLE N'EST PAS « CE QUI NE SE COCHE PAS » — la maquette avait tort, l'auteur l'a
  corrigée** : une référence A des cases cochables (syntaxe GFM `- [ ]`, v4.5.4) ; elles servent à
  ne pas perdre sa place, et c'est leur **NON-ENREGISTREMENT** qui est la propriété
  (`state.protoTasks`, remis à zéro à chaque ouverture, aucun champ du modèle touché). Écrire
  « rien ne s'y coche » aurait enseigné l'inverse de ce que l'écran fait, à l'endroit même où l'on
  prétend l'expliquer.
  **LA LEÇON NE S'AFFICHE PAS SOUS UN FILTRE** : qui cherche sait déjà ce qu'est une aide, on lui
  doit un résultat et pas un cours. Restent alors le `.empty` ordinaire et « Aucun résultat » — le
  titre spécifique par type y a été retiré, « Bibliothèque vide » au-dessus de « aucun résultat
  pour ce filtre » disant deux choses différentes du même écran.
  **PURGÉS avec le composant qu'ils servaient** (règle 14) : `#emptyNew`, `empty.anon`,
  `empty.libEdit`, `empty.cta` — les cartes couvrent EXACTEMENT leur condition d'affichage
  (`!q && !cat && canEdit`), et `canEditScope(null)` valant toujours vrai, aucun des trois textes
  n'était plus atteignable. Il ne reste que `{title, libRead}`.
  **⚠ DIX-HUITIÈME PIÈGE DE CASCADE, ET IL VENAIT DU COMPOSANT RÉUTILISÉ** : `.empty b` pose
  `display:block` (c'est le TITRE d'un état vide) et attrape **tous** les `b` descendants — chaque
  ligne d'anatomie se coupait en deux, le nom sur une ligne et sa glose sur la suivante, alors
  qu'elles se lisent d'un trait. Réparé en (0,2,1), jamais par l'ordre de déclaration. Le TON des
  glyphes passe par un **attribut** et non par `.crit`/`.vig`, qui sont des classes AUTONOMES du
  produit : un modificateur ne prend jamais un nom déjà pris (leçon v4.23.2).
  Témoins : `audit-doctrine` (nombre de cartes par vue, ligne non coupée, glyphe non vide,
  ouverture du dialogue sur le bon type, disparition sous filtre) et une surface
  `état · bibliothèque vide` dans `audit-a11y` — l'accueil y était ouvert AVEC les fiches
  d'exemple, donc cet écran n'était mesuré nulle part.
  **⚠ ET LA CARTE EST PLAFONNÉE À 780 px, CENTRÉE (signalé à l'usage : « ils prennent toute la
  place en mode desktop »)** : elle s'étirait à ~1870 px sur un écran large, pour trois lignes de
  texte — une ligne de cette longueur se lit mal, et l'état vide s'affirmait plus fort que
  n'importe quel contenu réel de l'accueil, dont les rangées sont plafonnées et grillées. **780
  n'est pas un pourcentage arbitraire** : c'est la largeur de lecture d'une référence et un palier
  déclaré, la même valeur pour la même raison. `max-width` ne contraint QUE si la place existe :
  mesuré, la carte occupe **100 % de son conteneur de 320 à 640 px** — le responsive est acquis
  par construction, sans media query ni palier nouveau.
- **LA COLONNE D'ORIENTATION — UN EN-TÊTE, UNE RANGÉE, UN MARQUEUR (v5.0.0, maquette C validée)** :
  elle empilait **deux composants de titre** (`.rail-head` avec compte pour « Parcours inerte »,
  `.pl-sech` texte seul — parfois sur deux lignes — pour les sections de queue) et **trois
  anatomies de rangée** (pastille + titre + colonne droite ; liseré rouge et AUCUNE pastille ;
  ni l'un ni l'autre). La seule section qui portait un registre coloré était donc aussi la seule
  sans marqueur, dans une colonne dont toute la doctrine est la désaturation.
  Désormais : **l'en-tête du rail droit partout** (titre + COMPTE — exigence ECAM : une zone qui
  peut être tronquée annonce ce qu'elle contient), **un marqueur par rangée dans la même colonne**,
  et **aucun liseré**. « Surveiller après les gestes » → « Surveiller ensuite » (sur 240 px
  l'ancien passait sur deux lignes ; un titre haché n'est plus un titre).
  **LE LOSANGE D'UNE DÉCISION PORTE SON NUMÉRO ET A LE STYLE DE LA PASTILLE** : même filet, même
  fond, mêmes états — seule la FORME change. La doctrine disait « la décision est un embranchement,
  elle n'a pas de numéro à porter » ; or `flowPlan` lui en attribue un, il est cité par le journal
  et par le statique, et le taire obligeait à compter les rangées pour retrouver « le bloc 2 ».
  L'ambre part avec : c'était le seul registre du marqueur dans une colonne désaturée.
  **LES MARQUEURS DE QUEUE SONT NEUTRES** (demande utilisateur : « attention aux couleurs qui
  peuvent détourner l'attention du bloc central ») — le registre y est porté par la FORME du glyphe.
  ⚠ **« À TOUT MOMENT » A ENSUITE QUITTÉ LA COLONNE** (« c'est inutile ») : elle oriente dans la
  SÉQUENCE, or une complication n'y est justement pas, et l'endroit où on l'attend est la carte du
  bloc ou la vue « Toute la fiche », qui la gardent toutes deux. `.pl-sec.cx` et `.pl-line.cxl` sont
  purgés ; `audit-complications` SUIT le composant plutôt que de disparaître avec lui (règle 14).
  **Écart uniforme titre → rangées** : 10 px sous chaque titre, 20 px au-dessus.
  **La chip de branche s'aligne sur le marqueur du bloc qu'elle ouvre** : elle portait les retraits
  du PLAN (20/32/48) quand la colonne resserre les siens (16/28/40) — 4 px d'écart, mesurés,
  exactement là où l'œil cherche une verticale. Aligné SANS ajouter de retrait.
- **LES TROIS GESTES DE BLOC PARTAGENT UNE SEULE BOÎTE (v5.0.0, signalé à l'usage)** :
  « ⚡ Complication », « ⏱ Noter l'heure » et « Vérifier » différaient sur TROIS axes — corps
  13,5 / 13,5 / **12** px, rembourrage 8-14 / 8-12 / **6-10**, et trois traitements de fond. Le
  troisième perdait en plus contre `.ov-redo`, déclarée ailleurs à spécificité égale : le gabarit
  qu'on lui avait écrit ne s'appliquait qu'à moitié. Ils sont de MÊME RANG (trois actions qu'on
  prend après avoir déroulé les étapes), donc même boîte — 44 px de cible, 13,5/700, rembourrage et
  rayon identiques. **Seul le REGISTRE distingue, et il porte du sens** : « Noter l'heure » est
  TONAL (le geste le plus fréquent), la complication est en CONTOUR d'alerte (jamais remplie — un
  aplat rouge permanent désensibilise), « Vérifier » est neutre. Sélecteur en (0,2,0) pour battre
  `.ov-redo` quel que soit l'ordre.
- **LES DEUX RANGÉES COLLANTES PARTENT DU MÊME x (v5.0.0, signalé à l'usage : « aligne le compteur
  de session sur Tout voir »)** — et la mesure a inversé la demande au-dessus de 780 px. Relevé :
  à 900, « Tout voir » à **10**, la session à **18**, le contenu à **18** : c'est donc la RANGÉE DE
  COMMANDES qui était décalée, pas le quai, et l'on aligne les commandes sur les deux autres.
  **Sous 780 px, l'inverse** : la session était à **0**, alignée sur rien — et on ne peut pas la
  porter à 18 sans voler 14 px à une rangée dont chaque pixel est compté à 320 (cf. `fitCtrlRow`) ;
  elle prend donc le retrait des commandes, palier par palier (4 / 8 / 10). **Une verticale
  au-dessus de 780, une au-dessous — jamais deux.** Vérifié à sept largeurs, aucun débordement.
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
  **ORDRE FIXE (ECAM — invariant à ne jamais casser). ⚠ CETTE FORMULATION A ÉTÉ CORRIGÉE en
  v4.56.3** : elle disait `⤢ Plan · ● Session · minuteurs` alors que **« Se repérer » a quitté le
  quai en v4.25.0** pour la rangée de COMMANDES `#crisisCtrl` (architecture ECP/ECAM : les
  commandes vivent sur un panneau DISTINCT de l'affichage). L'audit design v4.56 a d'ailleurs
  relevé le segment « ⤢ Plan » comme ABSENT de toutes les captures (P2-3) — il l'était en effet,
  et c'est la doctrine qui était périmée, pas le code : deux sections de ce fichier se
  contredisaient depuis v4.25.0. Ordre réel du quai : **`● Session · minuteurs`**, la rangée de
  commandes portant au-dessus `mode · ⤢ Se repérer · ⤢ Consulter`. Le raisonnement géométrique
  ci-dessous vaut tel quel pour la partie CONSTANTE (Session) devant la partie VARIABLE
  (minuteurs) : Session est AVANT la partie variable. C'est **géométrique** : un contrôle placé
  APRÈS un nombre variable de minuteurs ne peut rester immobile qu'ancré au bord (→ vide central
  qui varie) ou avec des créneaux réservés vides (→ trou) ; placé AVANT, il est immobile ET sans
  vide, les minuteurs coulant à sa droite (le blanc part au bord droit — barre d'outils normale).
  Session est 1ᵉʳ (constant), les minuteurs suivent. La règle cardinale d'une zone de statut ECAM est la CONSTANCE POSITIONNELLE : on
  apprend où regarder, l'œil y va sans lire. NE PAS remettre Plan à droite « pour la logique
  d'action » — ni, aujourd'hui, l'y remettre tout court : il se remettrait à glisser (bug corrigé
  v4.23.0), et le vide central marronnait les deux extrémités (proximité Gestalt rompue — retour
  d'usage). L'alarme n'a pas besoin de la 1ʳᵉ
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
  la CONDUITE EN COURS d'abord (⚡ Complications, Se repérer, Schéma, Consulter — « Mode lecteur »
  en est sorti avec la surface, lot T14),
  puis le CYCLE DE VIE de la session (Répéter en exercice, Recommencer le parcours, Historique),
  puis la GESTION (Modifier, Versions, Dupliquer), puis les EXPORTS ; la rangée `danger`
  (Terminer…) ferme toujours la liste. Avant, « Modifier »/« Versions » — DÉSACTIVÉES pendant
  une session — trônaient en tête : deux rangées mortes au moment où le menu sert le plus.
  `setMoreMenu` NORMALISE les séparateurs (jamais en tête/queue, jamais deux de suite : un groupe
  conditionnel vide disparaît sans que l'appelant s'en soucie).
  **IL NE DÉPASSE JAMAIS L'ÉCRAN, ET SA HAUTEUR EST UNE MESURE (v4.73.0 puis v4.73.2, signalé DEUX
  fois à l'usage : « si le menu est grand et la hauteur de la fenêtre réduite, il ne s'adapte pas »,
  puis « pareil, menu ⋯ tronqué » en GRANDE POLICE)** : en lecture il porte jusqu'à seize rangées, et
  à 130 % chacune passe sur deux ou trois lignes — les dernières (dont « Terminer la session… »)
  tombaient hors de l'écran SANS défilement, donc **inatteignables en silence**.
  La v4.73.0 l'a clampé en CSS (`var(--vvh) / var(--zf) - var(--hdr-h) - 16px`) : le calcul est juste
  sur Blink et **restait faux à l'usage**, parce qu'il repose sur trois hypothèses de plateforme à la
  fois — ce que `visualViewport.height` compte sous `zoom`, comment le zoom d'`<html>` se combine aux
  unités de fenêtre, et ce que vaut `--hdr-h` quand `env(safe-area-inset-top)` s'y ajoute — et
  surtout parce qu'il **oubliait la marge basse du MATÉRIEL** : la hauteur visible d'iOS INCLUT la
  bande de l'indicateur d'accueil, si bien que la dernière rangée y passait dessous.
  `fitMoreMenu()` **mesure** : hauteur réellement visible (`visualViewport.height`, la seule que
  iOS ne fausse pas — dossier « bande basse iOS ») moins la position RÉELLE du menu — qui absorbe
  sans aucun calcul la hauteur d'en-tête, le safe-area du haut et le décalage de 6 px — moins
  `--sab`, la marge basse exposée au JS par une propriété personnalisée (`env()` ne se lit pas
  depuis un script). Plancher de 180 px : une mesure pathologique ne doit jamais réduire le menu à
  une bande inutilisable. Rejouée au redimensionnement et au changement de taille du texte, puisque
  le menu peut être ouvert à cet instant. Témoin : `audit-doctrine` mesure 390 et 430 px × deux
  tailles de texte × **avec et sans marge matérielle simulée** (34 px), et vérifie que la DERNIÈRE
  rangée est atteignable après défilement — vérifié capable d'échouer dans les deux sens (terme
  `--sab` retiré → 4 rouges ; clamp retiré → 8). **ICÔNES : jamais deux entrées
  d'un même menu avec le même dessin, ni deux dessins quasi identiques côte à côte** —
  « Historique des sessions » a reçu `archive` (boîte, distinct de l'horloge-flèche `history`
  gardée par Versions) et « Se repérer » a reçu `ladder` (rail + lignes indentées = l'Échelle
  elle-même ; l'ex-icône `plan` — nœud + deux branches, quasi identique à `flow` juste
  en-dessous — est SUPPRIMÉE). Couvert par `scripts/audit-retour.mjs`. **Pied de page nomade** : `#appFooter` (Installer l'app, version, pastille synchro,
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
  section). Breakpoints : **360 / 400 / 430 / 480 / 560 / 640 / 780 / 924 / 1000 / 1200 px** — pas de
  nouveau palier sans décision explicite. **CETTE LISTE EST AUTO-EXÉCUTOIRE DEPUIS LA v5.0.0**
  (`scripts/check-paliers.mjs`, dans `npm run check` — lot T0) : elle était DÉCLARATIVE, et elle
  avait FUI. Mesuré : **douze** paliers réels pour **neuf** déclarés — `479.98` (`.tg-row`) et `924`
  (`.rs-bar`) n'y figuraient pas, et **900 était déclaré sans exister nulle part**. Une échelle
  fermée qui a fui est une échelle ouverte qu'on croit fermée, et rien ne pouvait le voir. Le
  contrôle ne lit que les conditions de `@media` (un `min-width:44px` de cible tactile n'est pas un
  palier) et arrondit les bornes en `.98` au supérieur : `779.98` et `780` sont UN palier. Ajouter
  un palier exige de l'écrire ICI **et** dans `PALIERS` du script — c'est précisément le but (360 et 400 étaient DÉJÀ dans le code, décidés en v4.30.0
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
- **L'ÉTAT NE CRIE PAS PLUS FORT QUE L'ACTION (v4.73.0, signalé à l'usage : « le texte du minuteur
  en gras très noir saute aux yeux plus que le contenu du milieu — confirmation diagnostique,
  étapes… ; c'est pareil pour les décomptes de compteurs »)** : le constat est juste et c'est une
  inversion de saillance. Le temps et les décomptes sont de l'ÉTAT, la checklist est l'ACTION —
  `.tm-val`/`.cn-val` passent de **700 à 500** (mono tabulaire à 26 px, 34 px dans le rail : la
  lisibilité ne dépend pas de la graisse à ces corps ; à 700 c'était une masse noire de la largeur de
  la carte) et `.tm-label` de 700 à 600 (il reste le titre de sa carte, sans peser autant qu'un titre
  de bloc clinique). **LA HIÉRARCHIE PASSE PAR LA GRAISSE, JAMAIS PAR L'ENCRE** — la règle est déjà
  écrite pour la posologie (« la DOSE reste en encre PLEINE ») : adoucir la couleur d'un temps serait
  l'inversion à ne pas faire, et `--tcol` reste le canal de l'ÉTAT (encre à l'arrêt, `--link` en
  cours, ambre échu). Rien de sémantique ne bouge.
- **LA SÉLECTION D'UNE BIBLIOTHÈQUE VA JUSQU'AU BORD DROIT (v4.73.0, demande utilisateur)** : l'aplat
  bleu s'arrêtait avant le bouton « modifier » (ou le cadenas) de la même rangée, coupant la ligne en
  deux et laissant croire que ce bouton visait autre chose que la rangée sélectionnée. C'est le
  CONTENEUR `.hs-wrap` qui porte l'état (`:has(>.hs-row.on)`), le bouton gardant le sien — même
  couleur, donc aucune couture ; seul son survol s'assombrit au lieu de se teinter, une teinte
  primaire à 8 % étant invisible sur du primaire plein.
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
- **TOUTE ENTRÉE DE FICHIER PASSE PAR `UP_KINDS` ET `acceptFile` (v5.0.0, chantier des uploads)** :
  quatre chemins cohabitaient avec quatre niveaux de rigueur — le PDF vérifiait sa signature,
  l'import la sienne, les DEUX chemins d'image ne vérifiaient qu'un `accept`, **c'est-à-dire une
  INDICATION donnée au sélecteur de fichier et jamais une garantie** (ni un renommage ni un dépôt
  ne la respectent). Et ils avaient déjà divergé : 60 images maximum côté référence, aucun plafond
  côté aide, **aucun plafond du tout à l'import**.
  **CE QUI REND LA RÈGLE EXÉCUTOIRE** : l'`accept` AFFICHÉ, la SIGNATURE vérifiée et le PLAFOND
  sortent de la **même ligne** de `UP_KINDS`. « Un champ de PDF n'accepte ni JSON ni image » cesse
  d'être une intention pour devenir une propriété du code — on ne peut plus changer l'un sans
  l'autre. **Trois natures, pas une de plus** (`pdf` · `image` · `data`) ; une quatrième s'ajoute
  LÀ, ou nulle part. Un seul `<input type="file">` dans tout le fichier (il y en avait cinq), et
  `pickFile(kind, onFiles)` prend un **callback** : la destination voyage avec le geste, ce qui a
  permis de purger `_edImgMode` (règle 14).
  **⚠ LE HEIC EST DANS LA LISTE BLANCHE, ET CE N'EST PAS UN DÉTAIL** : c'est le format de la
  photothèque iPhone, donc de la cible principale déclarée — une liste PNG/JPEG/WebP aurait cassé
  « joindre une photo » sur iOS **en silence**, seule vraie régression qu'aurait pu produire ce
  chantier. **⚠ ET LE SVG N'Y EST PAS, DÉLIBÉRÉMENT** : seul format image à contenu ACTIF, et seul
  à pouvoir n'avoir aucune dimension intrinsèque (il produisait alors un canvas 0×0, donc une image
  vide enregistrée sans un mot). L'ancien `accept="image/*"` l'admettait.
  **LA SECONDE BARRIÈRE RESTE `downscale()`**, et c'est la plus utile : le canvas RÉ-ENCODE, donc
  les octets d'origine n'atteignent jamais le stockage et les métadonnées (EXIF, position GPS d'une
  photo de terrain) partent avec. La porte ne la remplace pas, elle la précède.
  **AUCUNE TRONCATURE SILENCIEUSE** : on prenait `files[0]` et rien d'autre — déposer cinq documents
  en ajoutait UN sans un mot. Le compte des ignorés se dit, comme le « +n » du quai. Et **un refus
  se dit toujours** (`toast(msg, ms, true)` + `announce`) : un fichier refusé en silence est pire
  qu'un fichier accepté à tort, on croit avoir joint quelque chose.
- **LE DÉPÔT HORS ZONE EST NEUTRALISÉ — LE DANGER EST DEVENU LA FONCTIONNALITÉ (v5.0.0)** : il n'y
  avait **aucun garde global**, si bien qu'un fichier lâché à 3 px d'une zone faisait NAVIGUER le
  navigateur vers ce fichier — l'écran d'édition, ou une session de soin en cours, disparaissait.
  La fenêtre `#upDrag` n'existe que pendant un glisser RÉEL, annonce ce que l'écran accepte, et le
  `preventDefault` de `window.drop` fait le reste.
  **ELLE EST `pointer-events:none` — UN ANNONCIATEUR, PAS UN RÉCEPTEUR** : sans cela elle volerait
  tous les dépôts et il faudrait lui apprendre la géométrie des zones qu'elle recouvre. Le fichier
  traverse et atteint la zone du dessous ; le garde ne ramasse que ce qui tombe à côté.
  **⚠ TOUT EST GATÉ SUR `dataTransfer.types` CONTENANT `Files`** : MK5-b amorce « prendre / poser »
  sur un `dragstart` de poignée (v4.75.0) — sans ce garde, glisser une poignée ⠿ ouvrirait la
  fenêtre de dépôt, deux gestes qui se ressemblent se déclenchant l'un l'autre.
  **LE ROUTAGE SE FAIT PAR LE TYPE SNIFFÉ**, jamais par la zone visée ni par l'extension : dans un
  éditeur, un PDF va aux documents et une image à la galerie. Les cibles sont déclarées par les
  BINDERS (`upTarget`) et non par la présence d'un bouton — un dépôt marche donc même quand la
  section est masquée parce qu'elle est vide (v4.76.0). `render()` les remet à zéro avant le
  dispatch. **Coût NUL sur mobile**, où le glisser-déposer n'existe pas : la fenêtre ne s'y ouvre
  jamais, et les zones restent ouvrables au clic — aucun tap ajouté à aucun geste.
  Harnais : `scripts/audit-upload.mjs` (39 contrôles, écrit AVANT les correctifs — rouge à 4/27,
  vert à 39/39 ; vérifié capable d'échouer en réintroduisant les deux défauts).
- **CHERCHER DANS LES DOCUMENTS PDF — UN INDEX INVERSÉ, JAMAIS UNE COPIE DU TEXTE (v5.2.0,
  demande utilisateur)** : la recherche trouvait la FICHE, jamais l'endroit — un protocole de
  service joint en PDF pouvait porter la seule mention d'une dilution, et rien ne la trouvait.
  **LA PREMIÈRE PROPOSITION A ÉTÉ REFUSÉE, ET À RAISON** : conserver le texte extrait et le
  balayer n'est pas un index, c'est une photocopie sur laquelle on fait un `grep` — mesuré
  **546 Ko pour un document de 200 pages**, soit ~100 % du texte, ce qui obligeait à inventer un
  PLAFOND, donc des documents indexés à moitié.
  **CE QUE FONT SPOTLIGHT, FINDER ET LUCENE, ET CE QU'ON FAIT ICI** : on ne garde pas le texte, on
  garde le **DICTIONNAIRE** des mots distincts (trié, front-codé : chaque mot ne stocke que ce qui
  le distingue du précédent) et, pour chacun, la **LISTE DES PAGES**, en écarts successifs sur un
  octet — ou en **BITMAP** quand le mot est trop fréquent pour que les écarts soient rentables
  (choix de Roaring/Lucene). Le poids suit alors le VOCABULAIRE, **qui sature**, et non la
  longueur : mesuré sur du français technique réel, 49 Ko de texte donnent un index à **34 %**,
  626 Ko un index à **13,4 %** (texte ×13, mots distincts ×3,7). **Aucun plafond n'est donc
  nécessaire : l'indexation est INTÉGRALE, toujours.**
  **ET L'EXTRAIT N'EST PAS STOCKÉ NON PLUS** — Finder montre le FICHIER, pas la phrase. C'est ce
  qui garantit que **pdf.js n'est JAMAIS chargé pendant qu'on tape** (1 773 Ko, règle 13) : la
  rangée de résultat donne le nombre de passages et les PAGES, le contexte se lit dans le
  document, qu'un tap ouvre à la bonne page (`openPdfViewer(att,entity,page)`).
  **⚠ POURQUOI PAS L'INDEX DU NAVIGATEUR, QUI EXISTE — question posée par l'auteur, tranchée par
  la MESURE.** IndexedDB sait faire un index inversé seul (`createIndex(...,{multiEntry:true})` +
  `IDBKeyRange` pour les préfixes), sans une ligne de notre part. Sur le même corpus et le même
  découpage : **3 521 Ko contre 74 Ko**, soit **×47** — et **×39** encore pour la variante mixte
  (notre dictionnaire, ses postings sur des entiers). Le coût est le sur-poids par entrée du
  moteur (~55 octets par couple mot-page, 54 024 couples), qu'aucun encodage de notre côté ne
  retire. C'était donc exactement le poids refusé, en quatorze fois pire.
  **⚠ ET PAS SQLITE FTS5** : il n'existe aucun SQLite dans un navigateur (Web SQL retiré depuis
  Chrome 119). L'y amener, c'est embarquer SQLite en WASM — une SECONDE dépendance runtime, que la
  règle 13 interdit, avec tout l'appareillage de pdf.js (vendorisation, `ASSETS`, clé de cache
  versionnée, veille d'avis de sécurité) — pour obtenir « mot → pages ». FTS5, c'est aussi BM25,
  les requêtes de phrase, `snippet()`, les tokeniseurs et la fusion incrémentale : rien de ce dont
  il s'agit ici.
  **STORE `attidx` (base v6), À PART DE `attachments`, et c'est la raison du bump** : les index
  doivent pouvoir être chargés TOUS au démarrage, or un `getAll` sur `attachments` matérialiserait
  chaque ArrayBuffer de PDF — le pic mémoire que `gcAttachments` évite déjà explicitement.
  Contenu **DÉRIVÉ** : jamais poussé dans Storage, jamais dans l'export ni le ZIP ; le perdre ne
  perd rien. Il suit son document (`gcAttachments` le supprime) et déménage avec lui
  (`moveLocalDataTo`).
  **L'INDEX NE VOYAGE PAS, NI ENTRE UTILISATEURS NI ENTRE APPAREILS — c'est un choix, et le motif
  principal est la CONFIDENTIALITÉ.** Un dictionnaire EST la liste des mots d'un document : le
  synchroniser, ce serait faire sortir de l'appareil le vocabulaire d'un document clinique,
  c'est-à-dire du CONTENU, alors que seul le binaire que l'utilisateur a explicitement joint
  monte aujourd'hui (Storage, RLS, périmètre encodé dans le chemin). Ce serait donc une catégorie
  NOUVELLE de donnée sortante, à porter au registre RGPD opposable (§ 3.1), pour zéro gain
  fonctionnel — l'index se reconstruit en ~4 ms par page, juste après le téléchargement dont il
  dépend de toute façon. S'y ajoutent deux raisons d'ingénierie : une donnée dérivée n'a pas à
  être répliquée, et la synchroniser ouvrirait un risque de divergence index/binaire.
  **PORTÉE EXACTE** : le store vit dans la base de l'ESPACE (`dbNameFor`), donc un second compte
  sur le même ordinateur a la sienne ; `moveLocalDataTo` l'emporte lors du passage sans-compte →
  compte ; `deleteDatabase` l'efface avec le reste. Un document d'une bibliothèque PARTAGÉE est
  donc indexé indépendamment chez chaque membre — travail redondant, aucun chemin de donnée
  entre eux. Et un INVITÉ de partage de session tourne sur le backend mémoire
  (`supportsAttachments()` faux) : il n'a ni store ni index, conformément à « l'invité ne dépose
  rien ».
  **INDEXATION À L'ARRIVÉE DU BINAIRE, ET IL Y EN A CINQ.** ⚠ Le défaut, trouvé en vérifiant la
  portée : l'indexation n'était accrochée qu'à DEUX d'entre elles (ajout par l'éditeur,
  téléchargement de fond de la synchro). Manquaient le **« Télécharger » manuel** du pied de page,
  le **téléchargement immédiat** déclenché en ouvrant un document absent, et l'**import d'un
  .zip** — trois chemins par lesquels un document arrivait sans jamais devenir trouvable, en
  silence. `attPut(rec)` est désormais le point d'étranglement unique (patron `persistLive` /
  `edCommit`) : il écrit ET met en file, `ixQueue` étant idempotente. **`check-stores` compte les
  sites** — `IDB.putAtt(` ne doit apparaître QUE dans `attPut` —, donc un sixième chemin ajouté
  demain échoue bruyamment au lieu de créer un trou muet. Vérifié capable d'échouer. File d'attente à l'inactivité, un document à
  la fois (`_idle`, comme les vignettes) : indexer ne dispute jamais le fil principal à un geste.
  **Le rattrapage des documents déjà là est AUTOMATIQUE — REVIREMENT v5.3.0, décision utilisateur
  après l'avoir vécu sur sa PWA** (« l'indexation ne s'est pas lancée automatiquement, j'ai dû
  cliquer ») : la v5.2.0 exigeait un geste explicite pour ne jamais lancer de tâche de fond
  spontanée ; à l'usage, l'état nominal attendu est « mes documents sont trouvables », pas un
  bouton pour un travail que la machine sait faire seule. `ixLoadAll` met en file les documents
  en attente au démarrage — coût mesuré ~4 ms/page, un à la fois, à l'inactivité ; **pdf.js ne se
  charge QUE s'il existe des documents à indexer** (un démarrage ordinaire n'y touche pas : la
  lettre de la règle 13 tient pour le cas nominal). La ligne `#attIdx` du pied (jumelle de
  `#attOffline`) devient un indicateur d'avancement ; son bouton « Indexer » reste, filet des cas
  où la file s'est arrêtée (essais épuisés, stockage plein).
  **CORRESPONDANCE PAR SOUS-CHAÎNE, pas par préfixe** : c'est ce que fait `hayMatch` pour les
  fiches, et une même frappe ne peut pas se comporter autrement selon qu'elle vise une aide ou un
  document. Le dictionnaire étant UNE chaîne, c'est un `indexOf` par occurrence — sous la
  milliseconde, là où une dichotomie de préfixe aurait imposé une seconde grammaire.
  **RÉSILIENCE — DEUX FAMILLES D'ÉCHEC, ET ELLES NE SE TRAITENT PAS PAREIL.** *Transitoire*
  (binaire pas encore téléchargé, pdf.js hors cache et hors réseau, stockage saturé) : on ne
  RETIENT rien, le document reste « à indexer » — état visible, avec son geste. *Durable* (pdf.js
  ouvre le document et n'en tire aucun texte, ou le refuse) : on ENREGISTRE l'état
  (`none:'scan'` / `none:'illisible'`) — sans quoi un PDF que rien ne peut lire serait « pas
  encore indexé » à chaque démarrage, pour toujours : un compte qui ne descend jamais et un bouton
  qui ne fait rien. Le distinguo se joue sur `pdfLib()` : s'il échoue, c'est NOTRE bibliothèque
  qui manque, jamais le document — on relance, on ne condamne pas.
  **UN ÉCHEC TRANSITOIRE NE BOUCLE PAS** : trois essais par document et par SESSION (`_ixTry`,
  jamais persisté) ; au-delà la ligne dit « n document PDF non indexé (échec) · Réessayer ». Une
  panne qui ne s'arrête pas est la plus coûteuse de toutes.
  **⚠ LE DÉFAUT QUE L'AUDIT DE RÉSILIENCE A TROUVÉ, ET IL AURAIT FRAPPÉ TOUT LE MONDE D'UN COUP** :
  `attIx.set(id, ixOpen(rec))` rangeait **null** quand `ixOpen` refuse l'enregistrement — or
  `ixQueue` sort sur `attIx.has(id)`. Le document devenait donc **indéfiniment non ré-indexable**,
  et la recherche l'ignorait sans un mot. C'est exactement ce qui serait arrivé **au premier
  `IX_V` suivant, sur tous les documents à la fois**. `ixAdopt` est désormais l'unique point
  d'adoption : un enregistrement qu'on ne sait pas ouvrir est JETÉ, le document redevient « à
  indexer ». Témoin dédié dans le harnais (index d'une autre version → jeté → repasse en attente).
  **RÉINITIALISER — POUR TOUT, ET POUR UN SEUL.** Un index est dérivé : le jeter ne perd rien.
  `ixResetAll` (bouton « Réindexer » de la ligne du pied, avec confirmation) reconstruit tout ;
  `ixReset(id)` refait UN document, depuis sa rangée dans l'éditeur — là où l'on gère un document.
  La pastille de rangée n'apparaît QUE si l'état est anormal (« sans texte », « illisible », « non
  indexé », « indexation… ») : une rangée qui annoncerait « indexé » à chaque ligne serait le bruit
  permanent que ce dossier refuse partout. ⚠ `ixReset` remet le compteur d'essais **lui-même**,
  jamais chez l'appelant — un second appelant l'oublierait ; et `ixResetAll` vide `_ixTry`, sans
  quoi un document bloqué ne repartirait jamais.
  **UNE SEULE TABLE D'ÉTATS** (`ixStateOf`) lue par la pastille de rangée ET par la ligne du pied :
  elles disaient la même chose avec deux enchaînements de conditions écrits séparément — la
  duplication qui diverge en silence, déjà payée quatre fois ici (`MUTE_SEL`, les placards, les
  verbes du lecteur, le cœur de cochage). Même discipline pour le décodeur de varint (UN lecteur,
  partagé par le survol de `ixOpen` et la lecture de `ixPagesOf`), pour `docOwners` (partagé par
  `ixPending` et `docHits`) et pour `ixAdopt`.
  **LE DÉCODEUR EST TOTAL** : un enregistrement tronqué ou incohérent est refusé EN BLOC (jamais
  « à moitié ouvert »), un octet hors tampon vaut 0 donc aucune boucle de varint ne part à
  l'infini, et aucune page rendue ne peut sortir du document. Cinq témoins unitaires.
  **⚠ ET LE DÉCODAGE DU DICTIONNAIRE SE FAIT EN OCTETS, PUIS EN UN SEUL `TextDecoder`** : la
  première version concaténait `String.fromCharCode` caractère par caractère — ~63 000
  concaténations par document, donc des centaines de millisecondes de fil principal AU DÉMARRAGE
  d'une application qu'on ouvre en urgence.
  **INJECTION — CE QUI TRAVERSE, ET CE QUI NE TRAVERSE PAS.** Le contenu des PDF **n'atteint jamais
  le DOM** : c'est une propriété de l'architecture, pas un filtrage — on ne stocke aucun texte et
  la rangée de résultat n'affiche aucun extrait. Le seul texte non maîtrisé du chantier est le
  **NOM du document** (il vient d'un fichier, et il est éditable) : `safeFileName` ne retire ni
  `<` ni `>` ni `"`, c'est bien `esc()` qui protège (règle 4), dans le libellé comme dans les
  attributs. Un témoin du harnais joint un document au nom hostile
  (`x"><img src=x onerror=…>'&<b>…</b>`) et vérifie d'abord **qu'il atteint le DOM** — sinon rien
  ne serait mesuré — puis qu'aucune balise, aucun attribut et aucun script n'en sortent. Les ids
  servent de clés de `Map`, jamais d'objet (règle 6).
  **LIMITES DITES, JAMAIS TUES** : (a) un PDF **scanné** n'a aucune couche de texte — il n'y a
  rien à indexer, la ligne le dit (« n document PDF sans texte (scanné) ») ; l'OCR embarqué de
  Spotlight depuis Monterey est un modèle de plusieurs dizaines de Mo, hors règle 13. Ce n'est pas
  un index partiel, c'est un document sans texte. (b) Un nombre décimal isolé (« 0,5 ») se découpe
  en chiffres isolés, qui n'entrent pas au dictionnaire (< 2 caractères) — encodé dans un témoin
  de `tests.html` plutôt que découvert à l'usage.
  **LE GROUPE DE RÉSULTATS EST À PART**, après la liste : fondu dans les rangées, on ne saurait
  plus si le mot est dans l'aide ou dans une annexe, et un document porté par deux fiches
  apparaîtrait deux fois. Quand rien d'autre ne correspond, l'état vide ne dit PAS « Aucun
  résultat » — ce serait faux, il y en a un juste en dessous.
  **ET LE PORTEUR DU DOCUMENT EST LUI AUSSI UN RÉSULTAT (v5.3.0, demande utilisateur)** : une aide
  et ses annexes forment UN objet de soin — chercher un mot qui ne vit que dans le PDF joint sort
  l'AIDE dans la liste (les trois vues, `entityDocHit` dans les filtres, le renvoi croisé compte
  pareil), avec l'extrait « dans ‹nom› · p. n » (`docSnipHtml` — le OÙ, jamais le contenu, qui
  n'est pas stocké). Le groupe « Dans les documents » reste : il porte le geste d'ouverture À LA
  page, la rangée d'aide porte l'ouverture de l'aide — deux objets, deux gestes.
  **LA RECHERCHE D'UNE ENTITÉ COUVRE SES ANNEXES (v5.3.0, demande utilisateur)** : le champ d'une
  référence et celui de la feuille « Toute la fiche » listent sous le champ (`#pfDocs`, rangées
  `.doc-hit`) les documents JOINTS de l'entité où tous les termes apparaissent — `_pfEnt` posée
  par l'appelant avec `_pfRoot`, même durée de vie. Un mot absent replie la zone.
  **LES OCCURRENCES SE SURLIGNENT DANS LA VISIONNEUSE, ET SE NAVIGUENT (v5.3.0, demande
  utilisateur « comme le texte des fiches »)** : ouverte depuis un résultat, la visionneuse reçoit
  les termes (`openPdfViewer(att,entity,page,hl)`) — les PAGES viennent de l'index déjà en mémoire
  (aucun coût), les POSITIONS sont retrouvées au rendu de chaque page visible (`pdfPaintHl` :
  `getTextContent` ~3 ms, mis en cache sur le slot) et posées en rectangles `--verify-soft` en
  `mix-blend-mode:multiply` (même registre que `mark.pf-h`). La position DANS un item est
  approchée au prorata des caractères — suffisant pour guider l'œil, et c'est le compromis qui
  évite d'embarquer la couche texte entière de pdf.js. Pilule flottante ‹ n/N · p. x › en bas de
  la visionneuse (`#pdfHl`) : on navigue par PAGE d'occurrence — l'index connaît les pages, pas
  les positions, et le surlignage rend la navigation fine inutile. **Ouvert depuis sa RANGÉE, ni
  surlignage ni pilule** : on vient LIRE, pas chercher — un témoin le tient.
  Harnais `scripts/audit-pdfsearch.mjs` (26 contrôles, PDF fabriqué par le harnais, xref calculé) :
  il mesure le CHEMIN que les tests unitaires ne peuvent pas voir — joindre, indexer, relire au
  démarrage suivant, trouver, ouvrir à la page. **Son témoin le plus important est « pdf.js n'est
  pas chargé par la frappe », et il se mesure sur une page RECHARGÉE** : dans la session qui vient
  d'indexer, pdf.js est légitimement en mémoire et le contrôle passerait au vert sans rien prouver.
  Vérifié capable d'échouer (groupe et atterrissage neutralisés → 6 rouges ; adoption du `null`
  réintroduite → 2 rouges), vert sur les DEUX moteurs.
  ⚠ **DEUX PIÈGES DU FIXTURE, tous deux trouvés à la mesure** : avec une `MediaBox` de 300 pt, une
  ligne de 56 caractères DÉBORDE la page et **pdf.js clippe les glyphes qui en sortent** —
  « dilution » devenait « dilut », donc un corpus tronqué en silence ; et un document qui TIENT
  dans la fenêtre rend « ouvre à la page 2 » vrai sans rien faire. La page est donc large ET
  haute, et deux témoins vérifient que le corpus est intact et que le document déborde.
- **Documents PDF** : le PDF vit en ArrayBuffer dans le store IndexedDB `attachments` (base v6 ; Blob historique accepté en lecture), JAMAIS en
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
- **LA BIBLIOTHÈQUE EST UNIQUE, LE TYPE EST UN FILTRE (v5.0.0, lot T9 — R4).** Choisir « Aides »
  ou « Protocoles » était une DÉCISION PRÉALABLE : il fallait savoir de quel TYPE était ce qu'on
  cherchait avant de pouvoir le chercher. Or le type est une propriété de l'AUTEUR (« ai-je écrit
  une checklist ou un document ? »), pas du lecteur, qui cherche un SUJET. Le répertoire A→Z réunit
  donc les deux, et le type devient un filtre à trois crans — **« Tout » par défaut** — c'est-à-dire
  quelque chose qu'on applique APRÈS avoir vu, jamais avant.
  **CE N'EST PAS UNE FUSION DES DEUX RENDUS** : `renderFiches` et `renderProtocols` restent et
  servent les deux crans filtrés ; une TROISIÈME configuration (`renderAll`) délègue rangée, tuile
  et ouverture au type de chaque objet. Les fusionner aurait produit un rendu unique truffé de
  conditions — et un seul endroit à casser pour les trois vues. Les deux configurations sont
  EXTRAITES (`_homeCfgF` / `_homeCfgP`) et lues par les trois : trois descriptions qui
  divergeraient seraient trois endroits à corriger.
  **UN SEUL TRI POUR LES DEUX TYPES**, surtout pas « les aides d'abord » — ce serait rétablir la
  séparation qu'on vient de supprimer, en plus discret. Épinglés, puis frecency en recherche, puis
  alphabétique, exactement comme chaque liste séparée. **La PROVENANCE reste écrite sur la rangée**
  (décision D4) : elle ne dépend d'aucun filtre, parce qu'une bibliothèque partagée et une fiche
  perso ne s'engagent pas de la même façon.
  **`paintSeg` ACCEPTE UN INDEX ET LA MÉCANIQUE À DEUX RESTE INTACTE** : le booléen d'avant vaut
  0/1 (`#createSeg`, `#modeSeg` le passent toujours), `.i1` continue d'être posée pour eux, et
  au-delà de deux crans on passe par `--seg-i` comme le sélecteur de taille depuis la v4.71.1 —
  avec une règle CSS scopée par **`#id`**, jamais par une classe de plus : à spécificité égale ce
  serait l'ORDRE de déclaration qui trancherait (cinquième piège de cascade du projet).
- **⚠ LA TABLE `fiches` DEVIENT `cognitive_aids` (v5.0.0, lot T9) — ET IL FAUT REJOUER
  `supabase/schema.sql` AVANT DE PUBLIER LE CLIENT.** La règle « ne JAMAIS renommer un identifiant
  existant » tenait par son motif : « sans gain fonctionnel ». Le lot T9 fait disparaître ce motif —
  la bibliothèque est unique, le type n'est plus qu'un filtre, et « fiches » cesse de nommer son
  contenu. Un nom qui ment coûte plus cher qu'un renommage. `fiche_notes` devient `aid_notes`.
  **LE RENOMMAGE EST UN BLOC IDEMPOTENT EN TÊTE DE `schema.sql`**, et c'est ce qui le rend sûr : il
  n'agit que si l'ancienne table existe ET que la nouvelle n'existe pas. Sur une instance NEUVE il
  ne fait rien ; sur une instance EN PLACE il **RENOMME**, donc données, index, contraintes et
  politiques suivent — là où un `create table if not exists` sous le nouveau nom aurait créé une
  table VIDE à côté et fait paraître les données disparues.
  **LES CLIENTS 4.x NE CASSENT PAS** : deux vues de compatibilité (`fiches`, `fiche_notes`) en
  **`security_invoker = true`** — sans cette option une vue contourne la RLS, ce qui serait ici une
  fuite entre comptes ; et une vue simple sur une seule table est nativement MODIFIABLE, donc ils
  continuent d'écrire sans règle ni trigger à maintenir. À supprimer quand plus aucun 4.x ne tourne.
  **⚠ DÉFAUT VÉCU À LA PREMIÈRE EXÉCUTION, ET SA LEÇON** : le fichier livré contenait
  `alter table public.cognitive_aids rename to cognitive_aids` — Postgres répond « relation does
  not exist » et **toute la migration s'arrête**, sur l'instance de PRODUCTION, seul endroit où ce
  fichier s'exécute. La cause n'est pas une faute de frappe mais une MÉTHODE : le renommage avait
  été fait par remplacement en masse de l'ancien nom par le nouveau, et ce remplacement a réécrit
  **l'intérieur de la chaîne `execute`** du bloc de migration — c'est-à-dire la seule ligne du
  fichier qui devait garder l'ANCIEN nom. Même famille que le piège `String.replace()` / « $$ »
  déjà consigné : **un patch scripté mutile en silence ce qu'il ne distingue pas.**
  `check-sql.mjs` refuse désormais tout `rename to` dont la source et la cible portent le même
  identifiant — c'est toujours une faute, jamais une intention. Vérifié capable d'échouer.
  **COROLLAIRE DE MÉTHODE** : après un renommage scripté, relire les lignes qui doivent CITER
  l'ancien nom (migrations, vues de compatibilité, commentaires normatifs) — ce sont exactement
  celles que le remplacement casse, et les seules.
    **LES COLONNES NE SONT PAS RENOMMÉES** (`fiche_id` reste `fiche_id`) : arbitrage de rayon
  d'explosion, pas oubli — renommer une colonne oblige à reprendre chaque politique, chaque index
  et chaque appel REST, pour un gain de lisibilité que personne ne lit hors du SQL.
  **CÔTÉ CLIENT, CINQ APPELS SEULEMENT** — et le piège à connaître : `'fiches'` apparaît **339
  fois** dans `index.html`, mais l'immense majorité désigne le **store IndexedDB**, pas la table
  Supabase. Renommer au motif ne casserait pas la synchro, il casserait le stockage LOCAL et
  exigerait une montée de version de base. Ne remplacer que ce qui porte `/rest/v1/` ou `table:`.
  **⚠ ET C'EST EXACTEMENT LÀ QUE LE RENOMMAGE A COÛTÉ (v5.0.4, signalé à l'usage : « Erreur
  synchronisation — One of the specified object stores was not found »)** : `table:` était l'un des
  cinq appels à remplacer, mais `cfg.table` de `_pullTable` servait à DEUX choses — la table REST
  **et** le store LOCAL où la page est écrite (`Data.applyRows`). Le renommer côté REST a donc
  envoyé le pull des aides écrire dans un store `cognitive_aids` qui n'existe nulle part, et **la
  synchronisation ENTIÈRE échouait** dès la première page portant une ligne. Les deux noms sont
  désormais distincts (`cfg.store`, défaut = `cfg.table`).
  **LE DÉFAUT JUMEAU ÉTAIT SILENCIEUX, ET C'EST LE PLUS INSTRUCTIF** : dans le repli KV,
  `store==='protocols'?'protocols_v1':'fiches_v1'` faisait tomber **tout le reste** dans les
  fiches — le pull de l'historique de sessions (v4.54.0) y rangeait ses sessions dans la
  bibliothèque, sans un mot. `SYNC_KV_KEY` est une table explicite et **un nom inconnu ÉCHOUE
  bruyamment**, comme le fait IndexedDB : corrompre en silence est la pire des deux options, et
  c'est ce qui a laissé ce défaut vivre pendant que l'autre criait.
  **RÈGLE, ET ELLE VAUT POUR TOUT RENOMMAGE** : chercher les endroits où l'ancien nom servait à
  DEUX choses, pas seulement ceux qui le citent. `scripts/check-stores.mjs` (dans `npm run check`)
  la rend auto-exécutoire : tout store visé par la synchro existe dans le schéma d'`openSpaceDb`
  (le schéma fait autorité — aucune liste recopiée), et `SYNC_KV_KEY` couvre exactement les stores
  écrits. Vérifié capable d'échouer dans les deux sens. **Aucun garde-fou ne pouvait le voir
  avant** : `npm run check` ne lisait pas ce couplage, et **aucun harnais n'exerce un pull réel** —
  le seul point du dossier où une fonction critique n'est mesurée que par ses parties pures.
- **v3 A QUITTÉ L'APPLICATION — ÉTAPE D (v5.0.0).** Sont partis : le **miroir `b.steps`** (regénéré
  à chaque écriture depuis l'étape T6), les fonctions **`v3ToV4` / `v4ToV3`** et `V4_PERTES`, la
  **détection de format** dans `migrate`, et les quatre-vingts témoins qui mesuraient la conversion
  (règle 14 : une suppression emporte ce qui la mesurait). **`stepsOf(b)` reste** — c'est la lecture
  des items, pas du miroir.
  **UNE FICHE ENTRANTE SANS `items` EST UNE FICHE VIDE**, et c'est la conséquence assumée de la
  rupture : `migrate` ne retombe plus sur des chaînes. Un fichier v3 se convertit par
  `docs/conversion-v3-vers-v4.md`, jamais dans l'application.
  **CE QUI RESTE N'EST PAS DU « CODE v3 »** : `V5_RENOMMAGES` convertit EN PLACE un format v5
  intermédiaire (celui des étapes B et C) vers le format final — c'est une migration ordinaire, et
  elle protège les données LOCALES d'une mise à jour que l'utilisateur n'a pas choisie.
  **LES FIXTURES DES HARNAIS ONT DÛ SUIVRE, ET LA LEÇON EST GÉNÉRALE** : une fixture bâtie côté
  NODE ne peut pas appeler les fonctions de l'application — d'où `items()` dans `harness.mjs`, qui
  fait la même lecture (`⚠`/`△` → `level`, `::` → `expect`) ; une fixture bâtie DANS `page.evaluate`
  utilise `v4MakeItem`, la vraie. Confondre les deux contextes donne un `ReferenceError` qui
  ressemble à un défaut de l'application.
- **LES RENOMMAGES — ÉTAPE C DU PASSAGE À v4 COMPLET (v5.0.0).** `libraryId`→`library`,
  `validation`→`validatedAt`, `references`→`sources`, `attachments`→`docs`, `related`→`links`,
  `localInfo`→`local`, `complications`→`excursions` ; le BLOC passe de `type` `'steps'`/`'decision'`
  à `kind` `'do'`/`'decision'` ; l'aide se DÉCLARE (`v:4`, `kind:'procedure'`) ; et le statut prend
  son vocabulaire (`''` → `'validated'`).
  **UN STATUT INCONNU RETOMBE SUR `validated`, JAMAIS SUR `draft`** — c'est le défaut historique, et
  l'inverser ferait passer en brouillon des fiches validées à la première donnée douteuse, donc les
  **retirerait de l'accès de crise** (un brouillon ne s'épingle pas). J'ai écrit l'inverse d'abord ;
  trois témeoins l'ont attrapé.
  **LA CONVERSION EN PLACE (`V5_RENOMMAGES`) N'EST PAS DU « CODE v3 »**, et la distinction décide de
  ce que l'étape D supprime : ces huit lignes convertissent un format v5 **intermédiaire** (celui de
  l'étape B, qui portait encore les anciens noms) vers le format v5 final. C'est une migration en
  place ordinaire — celle que fait toute application qui renomme un champ. Sans elles, une mise à
  jour que l'utilisateur n'a pas choisie rendrait ses données locales illisibles : ce serait lui
  faire payer une décision d'architecture.
  **TROIS NOMS N'ONT PAS BOUGÉ, ET IL FAUT SAVOIR POURQUOI** : la colonne SQL `library_id` (le
  mapping `rowConverters` fait le pont), le **store IndexedDB `'attachments'`** (renommer un store
  exige une montée de version de base et casse le stockage LOCAL — c'est le piège déjà rencontré
  avec `'fiches'`), et le bucket Storage. **Ne jamais renommer au motif : distinguer le CHAMP du
  STORE.**
- **LE POOL `items[]` — ÉTAPE B DU PASSAGE À v4 COMPLET (v5.0.0).** `f.items[]` est désormais LA
  liste des items de l'aide, toutes portées confondues, et **un bloc ne porte plus que des
  IDENTIFIANTS**. Les cinq listes v3 `confirmation`, `notForget`, `verify`, `posology`,
  `differentials` **n'existent plus comme champs** : leurs lignes sont des items à `role`
  (`entry`, `do`+`memory`, `watch`, `dose`, `ddx`). **`references` n'en fait PAS partie** — c'est
  une métadonnée bibliographique, pas du contenu de crise, et la spécification en fait `sources`.
  **⚠ LA RÈGLE 12 EST LEVÉE ICI, PAR DÉCISION EXPLICITE DE L'AUTEUR** : un client 4.x ne peut plus
  lire ces aides. Le chemin de reprise existe et vit **hors** de l'application —
  `docs/conversion-v3-vers-v4.md`.
  **POURQUOI UN POOL, alors que le lot T6 avait mis les items DANS les blocs** : sans pool, les
  items de rôle `entry`/`watch`/`dose`/`ddx` n'ont nulle part où vivre — ils restaient dans leurs
  champs v3, c'est-à-dire que le modèle n'était pas v4. Le pool est ce qui donne un logement à
  TOUS les items.
  **RÉSOUDRE UN ID DEMANDE DE CONNAÎTRE L'AIDE**, et vingt-deux sites appellent `bItems(b)` sans
  l'avoir sous la main. Plutôt que de threader `f` à travers vingt-deux signatures — donc d'ouvrir
  vingt-deux occasions de se tromper — chaque bloc connaît son aide par une **WeakMap** posée dans
  `migrate` (`poolOwn`). Elle ne touche pas la donnée : rien de neuf ne se sérialise, rien ne part
  en synchro. Un bloc oublié se retrouve par un balayage de repli (`ownerOf`) — c'est un **filet,
  pas un chemin** : s'il servait souvent, c'est qu'un site construirait des blocs sans les
  normaliser, et c'est CE défaut-là qu'il faudrait corriger.
  **⚠ `bItems` REND UNE COPIE RÉSOLUE, PAS LE TABLEAU VIVANT — et c'est le piège de cette étape** :
  `bItems(b).splice(...)` compile, s'exécute, et **ne fait RIEN**. Toute mutation passe donc par
  trois verbes et par eux seuls — `bItemAdd`, `bItemDel`, `bItemMove` — qui tiennent les DEUX côtés
  (le pool ET la liste d'identifiants). Les séparer rouvrirait la porte à un pool qui garde des
  items que plus aucun bloc ne référence. **Déplacer une étape entre deux blocs ne bouge PAS l'item
  du pool** : seule sa référence change de bloc — c'est tout l'intérêt d'une identité.
  **LES CINQ LISTES SE LISENT ENCORE COMME DES LISTES DE CHAÎNES** (`listOf(f,clé)`), et c'est ce
  qui permet aux soixante-quinze sites de rendu de ne pas changer d'un caractère. Ce ne sont plus
  des champs : c'est une **VUE** sur le pool. L'éditeur écrit par `edList`/`edPut` → `setList`, qui
  **conserve les identités** des lignes inchangées — sinon une simple frappe casserait tout ce qui
  s'y accroche.
  **`listEditor` EST DÉFENSIF DEPUIS CETTE ÉTAPE** : un appelant qui passerait encore `f.verify`
  transmettrait `undefined` et **tout le rendu de l'éditeur tomberait**. C'est arrivé, et ni
  `npm run check` ni la suite ne l'ont vu — **aucun des deux n'exerce un rendu**. Troisième fois de
  ce chantier.
  **LE PARTAGE SUIT** : `SHARE_KEEP` emporte `items` à la place des cinq champs, et **la liste
  blanche de `share_fiche` a été mise à jour dans `supabase/schema.sql`** — c'est ELLE l'autorité,
  et sans elle un invité recevrait des blocs pleins d'identifiants ne résolvant vers rien,
  c'est-à-dire **une checklist vide en pleine réanimation, sans le moindre signal**.
  **⚠ `supabase/schema.sql` EST DONC À REJOUER.**
- **L'ITEM EST LA SOURCE, `steps` N'EST PLUS QU'UN MIROIR (v5.0.0, lot T6 côté RENDU).** Une étape
  était une CHAÎNE À UNE POSITION (`b.steps[3]`), et l'on a payé cela deux fois : un compte rendu
  qui nomme le mauvais geste après une insertion (lot T1, rustiné en archivant le texte), et
  l'impossibilité d'accrocher quoi que ce soit À UNE ÉTAPE autrement que par son rang —
  c'est-à-dire par la chose même qui bouge.
  **`b.items[]` EST DÉSORMAIS LA SOURCE ; `b.steps[]` EST RÉGÉNÉRÉ À CHAQUE ÉCRITURE.** Ce n'est
  **pas** une seconde source de vérité, et la distinction est tout le dispositif : **le miroir est
  ÉCRIT, jamais LU par ce client** (`stepsOf(b)` lit les items). Il existe pour UNE raison — un
  client antérieur qui reçoit la fiche par la synchro doit continuer d'afficher la checklist. Le
  jour où plus personne ne tourne en 4.x, il s'enlève en une ligne. **Ne jamais le réconcilier**
  (« laquelle des deux formes est la plus fraîche ? ») : les items gagnent toujours, sans quoi on
  reproduirait le défaut d'`edSyncGallery` (v4.78.0), où un geste qui retirait se défaisait au
  rendu suivant.
  **ÉCART ASSUMÉ AVEC LA SPÉCIFICATION v4, ET RÉVERSIBLE** : la spec range les items dans un POOL
  `f.items[]` que les blocs référencent par id. Cette indirection sert un cas qu'aucune
  fonctionnalité n'a (un item porté par deux blocs, ou par aucun) et se paierait à CHACUN des
  **quarante-huit** sites de lecture. Les items d'un bloc vivent donc DANS leur bloc ;
  `v3ToV4` / `v4ToV3` continuent d'écrire et de lire la forme à pool pour l'ÉCHANGE.
  **TOUT PASSE PAR TROIS VERBES**, et il n'y en aura pas un quatrième : `bItems(b)` (les items,
  dérivés une fois du miroir si la fiche est ancienne), `stepsOf(b)` (les chaînes, pour les
  quarante-huit lectures), `syncSteps(b)` (régénérer le miroir). Toute écriture d'étape passe par
  `setStepStr` ou par une mutation de `bItems`, **suivie de `syncSteps`** — c'est le point
  d'étranglement, au même titre que `edCommit` pour le brouillon et `persistLive` pour la session.
  **UN ITEM ENTRANT EST BORNÉ, JAMAIS RECOPIÉ** (`v4SanItem`, appelé depuis `migrate`) : `safeId`
  sur l'identité (règle 6), niveau ramené dans 1-3, rôle dans la liste fermée, booléens coercés,
  textes bornés. Un `level:99` ou un `dual:"oui"` venus d'un import ne franchissent pas la porte.
- **`aidRev` — LA RÉVISION DE L'AIDE RÉELLEMENT LUE PENDANT LE SOIN (v5.0.0).** La spécification
  v4 écrit « `aidRev` + `texts` réparent le défaut mesuré » ; **le lot T1 n'avait livré que
  `texts`** — le compte rendu ne nommait plus le mauvais geste, mais il taisait toujours SUR
  QUELLE VERSION de la fiche le soin avait été conduit. À la relecture d'un dossier six mois plus
  tard, sur une aide révisée entre-temps, la question restait sans réponse.
  **ON N'INVENTE PAS UN NUMÉRO DE RÉVISION** : `updatedAt` **EST** la révision — il change à chaque
  écriture, il est déjà stocké, déjà synchronisé, et les points de version (`backups`) portent le
  **même horodatage**, donc la version exacte se retrouve. Un compteur maison serait un second
  mécanisme pour la même chose.
  **CAPTURÉE AU DÉMARRAGE, JAMAIS AU SNAPSHOT** : c'est la révision qu'on a EUE SOUS LES YEUX. La
  question ne se pose qu'une fois — ouvrir l'éditeur TERMINE la session (K5), donc la fiche ne peut
  pas changer sous une session vive. **Et REPRENDRE une session archivée ne la re-lit pas** : le
  soin a été conduit sur la révision archivée, pas sur celle d'aujourd'hui.
  **UNE SESSION ANTÉRIEURE LE DIT** (« non enregistrée ») au lieu de se taire : un blanc laisserait
  croire à une fiche jamais modifiée, et une absence annoncée est une information — même doctrine
  que le drapeau `vElsewhere` de l'historique synchronisé.
- **LES DEUX FICHES D'EXEMPLE EXERCENT LA DOCTRINE QU'ELLES ENSEIGNENT (v5.0.0, lot T13 —
  constat 3 de l'audit J0).** Elles sont le **seul** matériel pédagogique du produit (la contrainte
  de l'audit interdit d'en livrer une troisième), et elles n'exerçaient qu'un TIERS de ses
  mécanismes : zéro repère posologique, zéro complication, aucun `discriminant`, aucun `onDue`,
  aucun `code` — et le registre **AMBRE n'apparaissait qu'UNE FOIS dans tout le produit**, au
  sixième geste d'un bloc terminal. Pire : elles ne respectaient pas les règles que `AI_PROMPT`
  **impose à une IA**. On enseignait une doctrine qu'on n'appliquait pas.
  **CE N'EST PAS UNE TROISIÈME FICHE** : on enrichit le CONTENU des deux existantes, ce que la
  contrainte autorise explicitement. `discriminant:'adulte'` et un `code` sur les deux, deux
  repères posologiques chacune (toujours **△**, jamais rouge — une dose est une RÉFÉRENCE),
  `onDue` sur les deux minuteurs, une **complication « à tout moment »** sur l'anaphylaxie avec son
  bloc HORS chaîne, et un **△ dès le premier écran** de chaque fiche.
  **★ ET ×2 SE POSENT APRÈS `migrate`**, sur l'ITEM : ces deux propriétés n'ont aucune écriture
  possible dans une chaîne `steps`, c'est tout l'objet du modèle v4. **UNE SEULE de chacune par
  fiche**, et le choix n'est pas décoratif — l'adrénaline IM est LE memory item de l'anaphylaxie et
  LE geste où une erreur de dose ou de voie coûte, donc le cas canonique du double contrôle ; la
  RCP immédiate est le memory item de l'ACR, mais **sans ×2** (un geste continu n'est pas un produit
  à double-contrôler). S'ils étaient partout, ils ne diraient plus rien.
  **LE CHAPEAU RESTE SOUS SON PLAFOND** : `forgetAll` agrège `notForget` ET les étoiles — les deux
  fiches sont à 4 rappels, exactement au plafond doctrinal, et un témoin le tient.
- **J0-D6 — LE MESSAGE DES EXEMPLES N'EST PAS UNE SNACKBAR (v5.0.0, lot T13).** Mesurée à l'audit
  J0, elle recouvrait **60,7 % du bouton d'action primaire** à l'instant où un nouveau venu venait
  de le presser. Une snackbar ACCUSE un geste et s'efface ; ceci **AVERTIT** (« relisez-les avant
  tout usage clinique ») et doit tenir jusqu'à lecture. Le bandeau système est exactement ce canal —
  « information persistante, visible sur l'accueil seulement » (v4.20.0) — et il vit AU-DESSUS du
  contenu au lieu de le couvrir : **recouvrement mesuré à 0 %**.
- **DIRECTION A « INSTRUMENT CLINIQUE » (audit UX post-v5.0.10) — six lots de matière, aucun
  contrôle déplacé.**
  (1) **UN SEUL CRÉNEAU DE MESSAGE SYSTÈME À LA FOIS** : mesuré à 390×844, le bandeau J0-D6 et la
  notice auteur s'empilaient au premier lancement — premier contenu clinique à **39 % de
  l'écran**, et les deux textes énonçaient la même responsabilité éditoriale. Le texte du bandeau
  ABSORBE la notice (« Relisez-les et validez-les : vous êtes responsable du contenu clinique ») ;
  tant que `#sysBanner` est visible, la notice attend (`sysBannerOn()`), et l'acquittement re-rend
  l'accueil pour la laisser paraître. ⚠ Le prédicat des gardes est la CLASSE `body.view-home` —
  la même que la visibilité CSS du bandeau ; `state.view` vaut `'library'` sur l'accueil, un test
  sur lui serait silencieusement toujours faux (payé à la première livraison). Ne pas réintroduire
  un second bandeau simultané.
  (2) **LA RECHERCHE EST UN CREUX** (`--surface-2`, filet 1 px — les 2 px de bordure rendus au
  rembourrage, paliers d'espacement respectés) : une zone de SAISIE se distingue d'une carte de
  contenu par le renfoncement, et en sombre `--surface-2` est PLUS FONCÉ que la surface, le creux
  tient dans les deux thèmes. **Le placeholder GARDE sa phrase entière** (décision utilisateur —
  première version raccourcie à « Rechercher », annulée) : quand la place manque il s'ELLIPSE
  (`text-overflow:ellipsis`, y compris `::placeholder`) au lieu de se couper en plein mot (défaut
  mesuré à 390 px).
  (3) **LA LETTRE DE CLASSEMENT DU RÉPERTOIRE EST EN SERIF** (13,5 px/600 — `var(--serif)`, donc
  la Source Serif 4 DÉJÀ embarquée dans `vendor/fonts/`, aucun actif nouveau) : un index
  d'ouvrage, pas du chrome. Le rail A→Z reste en mono (cibles minuscules, la lisibilité prime).
  (4) **LES ÉLÉVATIONS DU THÈME CLAIR SONT TEINTÉES PRIMAIRE** (23,71,127 — comme l'étaient déjà
  `--shadow-primary`) : une seule famille d'ombres au lieu de deux encres ; les VOILES restent à
  l'encre (un voile assombrit, il n'élève pas), le sombre garde ses ombres noires (sur #0a0a0c
  une teinte est invisible).
  (5) **NEUF VARIANTES TONALES SE DÉRIVENT DE LEUR BASE** (`@supports color-mix`, bloc après les
  tokens sombres) : les pourcentages sont MESURÉS pour reproduire le hex actuel à ≤ 4/255 par
  canal — aucun changement visible, mais changer une base met à jour sa famille sur tout moteur
  moderne. **Les écarts plus grands sont des ACCORDS DE TEINTE et restent en hex** :
  `--primary-300` (Δ 8,8), `--critical-soft` (5,2), `--verify-soft` (9,5) en clair, les `-soft`
  rouge/ambre du sombre (6-16). Le repli hex de `:root` est un INSTANTANÉ : changer une base
  exige de re-régler les hex pour les moteurs sans color-mix. Les ACCENTS ne sont pas concernés
  (spécificité).
  (6) **AU PALIER COCKPIT (≥ 1200), LE CHROME S'EFFACE DERRIÈRE SES CONTRÔLES** : mesuré à
  1280 px, la rangée de commandes était une bande blanche de bord à bord au contenu arrêté à
  x=256 (1024 px de vide). `#crisisCtrl` et `#crisisDock` prennent le fond de PAGE
  (`border-bottom-color:transparent` — les hauteurs ne bougent pas d'un pixel), boutons et cartes
  portant déjà leurs bordures. Aucune position ne change.
  (7) **PILOTE VIEW TRANSITIONS** (`vtWrap`) : traversée accueil→fiche (sans session vive) et
  fiche→bibliothèque en fondu de 180 ms piloté par l'UA. Trois gardes : API présente (sinon rendu
  direct — comportement d'avant au caractère près), `!crisisOnScreen()` (en session, le mouvement
  est réservé à l'alarme), et reduced-motion. ⚠ Sous VT le rendu est ASYNCHRONE d'une frame : ne
  jamais l'employer dans un chemin qui relit le DOM juste après ; le retour de PILE garde
  `_backAnim`, qui anime déjà.
  **DEUX LOTS ÉTUDIÉS ET NON LIVRÉS, avec la raison** : les entrées `@starting-style` — l'app a
  DÉJÀ `veilIn`/`riseIn`/`menuIn` (keyframes d'entrée des fenêtres et du menu ⋯), un second
  mécanisme pour la même chose serait la divergence que ce dépôt combat ; la duplication des
  neutres en oklch — une copie par token est la liste tenue en double de v4.37.0 (la dérivation
  color-mix du point 5 obtient le bénéfice sans la copie). `text-wrap:balance` est posé sur les
  titres NON clampés seulement (`.ai-top h3`, `.empty b`) : sur un titre clampé, balance pousse du
  texte vers la ligne que `-webkit-line-clamp` tronque. L'écran de bienvenue étroit est COMPOSÉ :
  le glyphe de marque (masque `logo-glyph.svg`, couleur de FILET, `aria-hidden`) habite le vide
  mesuré (~430 px à 390×844) entre le texte et « Commencer » — étroit seulement, sur ordinateur la
  carte est à hauteur de contenu., ET LE GAIN N'EST PAS CELUI QU'ON
  ATTENDAIT (v5.0.0, lot T13).** Deux paragraphes sont partis : décrire les étapes cochables, les
  minuteurs et les compteurs, c'est raconter ce que la première fiche ouverte MONTRE d'elle-même —
  la contrainte « aucun tutoriel » appliquée à cet écran.
  **MAIS LA MESURE CORRIGE L'ATTENDU** : sur téléphone la carte est une **feuille pleine hauteur**
  (règle « sous 780 px, toute fenêtre est une feuille plein écran »), donc le bouton était **déjà
  visible** et le retrait ne rend que **6 px à 390, 1 px à 320**. Le gain réel est à **1100 px**
  (350 → 261 px, −25 %) et surtout : **moins à lire avant d'agir**. Ne pas revendiquer un gain de
  pixels sur téléphone — il n'existe pas.
  **UNE PHRASE N'A PAS ÉTÉ RETIRÉE alors que la décision le prévoyait** (« le seul paragraphe
  réglementaire ») : la promesse de confidentialité, conservée en une ligne. Retirer une PROMESSE
  faite à l'utilisateur n'est pas la même chose que retirer une explication de fonctionnalité.
- **LE PROMPT IA APPREND LA FORME ENRICHIE (v5.0.0, lot T12) — SANS REMPLACER LA SIMPLE.** Le
  schéma v3 à chaînes (`"steps"`, préfixe `⚠`/`△`, séparateur `::`) reste la forme de référence et
  **continue de fonctionner** : `migrate` dérive les items du miroir quand ils manquent. Ce qui
  s'ajoute est une forme **facultative**, bloc par bloc — `"items"` — pour les deux propriétés
  qu'une chaîne ne peut pas porter : **`memory`** (★, l'étape reste dans son bloc ET rejoint « Ne
  pas oublier ») et **`dual`** (×2, AC 120-71B §5.2.2.5). Plus `level` 3/2/1, qui rend le registre
  **ordonné donc comparable**, ce qu'un préfixe ne permet pas.
  **LES DEUX FORMES NE SE MÉLANGENT PAS DANS UN MÊME BLOC** : si `items` est présent il fait foi, et
  `steps` est régénéré par l'application — c'est la règle du miroir, énoncée au prompt pour qu'une
  IA ne tente pas de tenir les deux à jour.
  **LE PROMPT DIT AUSSI DE NE PAS INVENTER** : `memory` et `dual` ne se posent que si la SOURCE les
  désigne (memory items d'un QRH, double-contrôle explicite d'un protocole) ; sinon on les omet et
  l'auteur les pose d'un tap. Même refus que pour le `discriminant` — une IA qui devine écrit du
  contenu clinique à la place de quelqu'un.
  **ET C'EST UN CONTRAT VÉRIFIÉ** : `audit-prompt` EXTRAIT le bloc enrichi du schéma **affiché** et
  le fait entrer par `migrate()`. Si l'import le refusait, une IA fidèle produirait un fichier
  irrecevable et la faute paraîtrait venir d'elle — c'est exactement ce qui s'est produit en
  v4.73.0 avec le `\n` mal échappé. 19/19 contrôles (13 → 19).
- **LE MODE LECTEUR EST RETIRÉ (v5.0.0, lot T14 — décision de l'auteur, sur mesures).** Il ne
  gagnait qu'à **320 px** (63 % de l'écran aux étapes contre 36 % pour la carte de bloc, 5 étapes
  contre 3) et **perdait à 390** (47 % contre 59 %) : son propre chrome — titre, rôle, chrono,
  Quitter, en-tête de bloc, pastilles, bouton de 72 px — coûtait alors plus qu'il ne rendait.
  **SA JUSTIFICATION S'ÉTAIT ÉRODÉE DANS SA PROPRE DOCTRINE** : la v4.28.0 a explicitement
  abandonné le « un item à la fois » (Degani & Wiener : perdre sa place est un mode de défaillance
  premier ; modèle ECL Boeing = liste entière + curseur), et la v4.62.0 a unifié la structure
  (`stepsListHtml`, `applyCheck`, le vocabulaire des verbes). Il ne restait qu'une coquille.
  **ET LE CAS QUI LE MOTIVAIT LE MIEUX N'A PAS BESOIN DE LUI** (argument de l'auteur, retenu) :
  McEvoy 2014 (99,5 % contre 70 %) décrit un **rôle de lecteur tenant l'unique appareil** — cela se
  résout en **tendant le téléphone**, que la carte de bloc sert déjà. Le binôme à DEUX appareils,
  lui, est servi par le partage de session, avec attribution tracée.
  **PERTE ASSUMÉE, CHIFFRÉE** : à 320 px la part d'écran consacrée aux étapes retombe de 63 % à
  36 %, et la cible de réponse de 72 px redevient une case de 44. Bornée au plus petit écran servi.
  **CE QUE LE RETRAIT A EMPORTÉ** : 221 lignes de JS, 49 règles CSS, le balisage `#readerMode`, la
  bande de minuteurs et le chrono PROPRES au lecteur (`#rmTimers`/`#rmTime` — ils n'existaient que
  parce que l'overlay couvrait le quai), deux entrées du menu ⋯, le bouton de la carte de bloc,
  l'entrée de `_histBackAction`, `state.readerI`, et **le régime de refus de navigation distante**
  (`_rmOn`) avec sa bannière : sans overlay, une navigation distante s'applique normalement.
  **TROIS PIÈGES DE RÈGLE 14, DONT UN DANS LEQUEL JE SUIS TOMBÉ** : (1) le **mode moniteur** vivait
  DANS la plage de code retirée — supprimé par erreur, la page démarrait encore et `npm run check`
  était vert, seul le hook `?__actest` a crié (« monPick is not defined ») ; restauré à
  l'identique. (2) `audit-lecteur.mjs` portait **quatorze** contrôles dont **six** ne mesuraient
  pas le lecteur — il est **taillé et renommé `audit-retour.mjs`** (menu ⋯ : ordre, séparateurs,
  icônes distinctes ; pile de retour : titre de l'origine, garde anti double-tap 700 ms, sortie
  vers la bibliothèque). Le supprimer aurait emporté six invariants sans rapport. (3) `audit-partage`
  portait deux sections entières sur le lecteur (le régime de refus, et le bridage du scribe dans
  l'overlay) : retirées avec le régime qu'elles mesuraient.
- **⚠ LE RÉGIME « deferred » NE TENAIT AUCUNE DE SES DEUX MOITIÉS (v5.0.0 — défaut PRÉEXISTANT,
  trouvé en préparant le retrait du mode lecteur).** `SHARE_APPLY` classe `verify` et `gap` en
  `'deferred'`, et la doctrine promet « mis en file, appliqué **au prochain geste LOCAL DE
  NAVIGATION** ». Les deux moitiés étaient fausses :
  1. **LE DRAIN** — le seul site qui vidait `Share._defer` était `rmResume`, c'est-à-dire le bouton
     « reprendre » **du mode lecteur**. Un invité qui n'ouvrait jamais le lecteur ne recevait donc
     **JAMAIS** la trace do-verify de l'hôte : elle s'empilait indéfiniment, en silence.
  2. **L'APPLICATION** — et même quand le drain tournait, `shareApplyAnchored` ne connaissait que
     `nav`, `flow_end`, `check` et `uncheck`. Les `verify`/`gap` **sortaient de la file puis étaient
     JETÉS**. Le drain « marchait » sans rien appliquer, ce qui est le pire des deux mondes : la
     file se vidait, donc rien ne signalait le problème.
  **LE DRAIN VIT DÉSORMAIS DANS `ovAdvanceRender`, ET NULLE PART AILLEURS** — c'est littéralement
  ce que la doctrine décrivait : ses trois appelants sont `ovAnswer` (choisir une branche),
  `ovNewPass` (↺ Refaire) et le handler de « Continuer ». **L'application distante n'y repasse
  pas** (elle appelle `keepAnchor` directement), donc le drain ne peut pas se déclencher sur un
  évènement distant — ce qui serait exactement l'interruption que le régime existe pour éviter.
  **ON DRAINE AVANT DE RENDRE** : la trace entre dans l'état, puis le rendu du geste local peint
  les deux d'un coup. C'est « l'acquittement par l'action » au sens propre.
  **L'ÉCRITURE EST CELLE DU PLI** (`shareFold`) : `{a,t}` posé et le registre opposé effacé — une
  étape ne peut pas être à la fois constatée et en écart. Deux écritures différentes feraient
  diverger l'état appliqué en direct et l'état recalculé depuis le journal, ce qui est précisément
  ce que l'empreinte de partage vérifie.
  **UN CONSTAT DE MÉTHODE, TROUVÉ EN ÉCRIVANT LE TÉMOIN** : un scribe au milieu d'un bloc n'a
  **aucun** geste de navigation disponible (« Continuer » est `aria-disabled` tant que le bloc
  n'est pas coché). La file attend donc légitimement — mais il a fallu **constituer l'état** où le
  geste existe pour mesurer quoi que ce soit. Un témoin qui se contente de cliquer un bouton
  désactivé mesure le vide.
- **★ MÉMOIRE — UN MEMORY ITEM EST UN ITEM DE LA LISTE, PAS UN CHAMP À PART (v5.0.0, lot T7).**
  C'est la doctrine QRH, et le modèle v4 l'écrit ainsi : `memory:true` sur l'item, qui **RESTE dans
  son bloc**. Le chapeau « Ne pas oublier » AGRÈGE désormais `notForget` (la liste historique,
  conservée — règle 12) et les étoiles posées sur les étapes.
  **IL APPARAÎT DEUX FOIS, ET CE N'EST PAS LA DUPLICATION QUE LA v4.70.1 PROSCRIT** : celle-là vise
  deux canaux qui énoncent la même CONSTANTE en même temps et à demeure. Ici les deux moments sont
  distincts, et c'est exactement le geste QRH — on lit le chapeau **AVANT** d'agir (condition
  d'entrée ; il se replie dès le démarrage, lot T3), puis on **RE-VÉRIFIE** l'item à sa place dans
  la checklist. Un memory item se récite de mémoire, puis se confirme sur la liste.
  **UN SEUL CALCUL** (`forgetAll`, `memItemsOf`) : le chapeau, son garde-fou de 4 rappels et le
  volet de relecture comptent la MÊME chose — trois calculs séparés divergeraient, et ce dépôt a
  déjà payé cette leçon quatre fois.
  **REGISTRE ALERTE POUR L'ÉTOILE, et ici c'est justifié** : un memory item est par définition « ce
  qui tue si on l'oublie », le registre même du chapeau qu'il rejoint.
- **⚠ UN RUNTIME CONSERVÉ GARDAIT UNE FICHE PÉRIMÉE (v5.0.0, trouvé à la sonde du lot T7 ;
  DÉFAUT ANTÉRIEUR).** Quand on rouvre une fiche déjà chargée et non démarrée, `openRead` ne
  reconstruit pas le Runtime — c'est voulu, il n'y a rien à jeter. Mais `edCommit` **REMPLACE**
  l'objet dans `fiches` par sa copie normalisée : la référence gardée par le Runtime désignait
  alors la version d'AVANT l'édition, et la lecture affichait un contenu périmé **sans que rien ne
  le dise** — la donnée périmée présentée comme vivante, danger n°2 du palmarès ECRI 2015, que ce
  dossier combat partout ailleurs. Une ligne : re-pointer `Runtime.fiche`, sans rien reconstruire.
  **CE QUI L'A RÉVÉLÉ EST UNE LEÇON DE MÉTHODE** : le témoin unitaire du calcul était vert et le
  serait resté. C'est le contrôle qui suit le CHEMIN RÉEL — poser l'étoile dans l'éditeur, revenir
  en lecture, regarder le chapeau — qui a parlé. Mesurer une fonction ne mesure pas un parcours.
- **« ×2 » — L'ITEM CONFIRMÉ PAR LES DEUX (v5.0.0, lot T7 ; AC 120-71B §5.2.2.5).** La source
  exige que les items critiques soient vérifiés par les DEUX membres d'équipage. C'était **la seule
  exigence explicite de la doctrine que le modèle ne savait pas EXPRIMER** — une chaîne n'a pas de
  place où accrocher une propriété. Elle en a une depuis que l'item porte une identité.
  **REGISTRE NEUTRE, jamais rouge ni ambre** : ce n'est ni un danger (⚠) ni un piège (△), c'est une
  consigne de PROCÉDURE sur la façon de confirmer. Lui donner une couleur de registre la mettrait
  en concurrence avec le contenu clinique (règle 8) ; et le glyphe seul ne suffirait pas
  (WCAG 1.4.1), d'où le mot pour le lecteur d'écran.
  **LE MIROIR N'EN PORTE AUCUNE TRACE, ET C'EST VOULU** : un client antérieur lit le texte de
  l'étape, sans marque parasite. La propriété voyage dans `items`, qu'il ignore.
  **ELLE SURVIT À L'EXPORT** : `v3ToV4` part des ITEMS quand ils existent (lire le miroir aurait
  perdu `dual`, `note` et les identités au premier export — la conversion aurait annulé le lot qui
  les introduit), et `v4ToV3` réémet les items du bloc en plus du miroir.
  **LE PARTAGE LES EMPORTE DÉJÀ, ET IL FALLAIT LE VÉRIFIER** : `items` vit DANS `blocks`, qui
  figure sur la liste blanche de `share_fiche` — la liste borne les champs de PREMIER NIVEAU de la
  fiche, pas la forme interne des blocs. **`supabase/schema.sql` n'est donc pas à rejouer** pour ce
  lot. C'est la question qu'on oublie (précédent `discriminant`, v4.70.0) : ici elle a été posée et
  la réponse mesurée, au lieu d'être supposée dans un sens ou dans l'autre.
  **CE QUI RESTE DE T7, ET POURQUOI** : `★ mémoire` et `phase` ne sont PAS livrés. Ce ne sont pas
  des champs à écrire mais des changements de ce qu'une SURFACE AFFICHE — `memory` recompose le
  chapeau « Ne pas oublier », `phase` pilote le decluttering. Un éditeur qui les écrirait sans que
  rien ne les montre promettrait ce qu'il ne fait pas, défaut corrigé en v4.74.0.
- **LE MODÈLE v4 EXISTE ET IL EST RÉVERSIBLE — MAIS L'APPLICATION TOURNE ENCORE EN v3
  (v5.0.0, lot T6, LIVRÉ PARTIELLEMENT ET IL FAUT LE SAVOIR).** Ce qui est livré : deux fonctions
  PURES `v3ToV4` / `v4ToV3`, et la reconnaissance du format v4 **dans `migrate()`**. Ce qui n'est
  PAS livré : le rendu, l'éditeur, l'export et le partage lisent toujours v3 — aucune donnée
  stockée n'a changé, aucune surface n'a bougé, et **rien ne PRODUIT encore de v4**.
  **CE QUE v4 CHANGE, EN UNE PHRASE** : un item cesse d'être une CHAÎNE À UNE POSITION pour devenir
  un OBJET À UNE IDENTITÉ. C'est la réparation structurelle du défaut du lot T1 — une clé
  `visite:bloc:INDEX` désigne un autre geste dès qu'on insère une ligne, et T1 n'a pu que poser une
  rustine (archiver le texte). Avec `id`, la question ne se pose plus.
  **SIX CHAMPS v3 DEVIENNENT DES RÔLES** : `confirmation` → `entry`, `notForget` → `do` +
  `memory:true`, `verify` → `watch`, `posology` → `dose`, `differentials` → `ddx` ; les étapes de
  bloc restent `do`. **`references` N'EST PAS un rôle** (`sources[]`, métadonnée — ce n'est pas du
  contenu de crise). Le préfixe `⚠`/`△`, convention DANS la chaîne, devient `level` 3/2/1 —
  **ordonné, donc comparable**, ce qu'un préfixe ne permet pas ; `::` devient `do`/`expect`.
  **LA LOSSLESSNESS EST UN MÉCANISME, PAS UNE INTENTION** : on ne recopie pas une liste de champs
  (une liste se périme — le dépôt l'a payé quatre fois : `MUTE_SEL`, `LEAD_ONLY_SEL`, la liste des
  placards, les deux listes de verbes de partage). On PART de l'objet entier, on RETIRE ce que l'on
  convertit, **tout le reste voyage tel quel** — un champ ajouté demain traversera sans qu'une
  ligne soit écrite. Deux témoins mesurent exactement cela sur un champ inconnu, à l'aller et au
  retour.
  **RIEN N'EST DEVINÉ** : `dual` (AC 120-71B §5.2.2.5, inexprimable en v3), `phase`, `concl` et
  `note` naissent VIDES. Deviner qu'un premier bloc est « immediate » écrirait du contenu clinique
  à la place de l'auteur — même refus que pour le `discriminant` (« aucune migration ne DEVINE »).
  Seul `hors` est CALCULÉ, parce qu'il se DÉDUIT du graphe (un bloc qu'aucun chemin n'atteint depuis
  le départ est une excursion) et ne demande donc rien à personne.
  **LE RETOUR v4 → v3 EST À PERTE, ET LA LISTE EST DANS LE CODE** (`V4_PERTES`) : `dual`, `phase`,
  `concl`, `note`, les identités d'items. **Elle est acceptable AUJOURD'HUI parce que rien ne
  produit ces champs** ; elle cessera de l'être au lot T7, quand l'éditeur les écrira — ce jour-là
  c'est le RENDU qui devra passer en v4, **et surtout pas cette conversion qui devra ruser**.
  **LA DÉTECTION VIT DANS `migrate()`, ET NULLE PART AILLEURS** — règle 5 appliquée telle quelle :
  la poser au point d'IMPORT aurait laissé dehors le chargement, le ZIP, la duplication et le pull
  cloud, et le défaut aurait été SILENCIEUX (une aide v4 tombée du cloud lue comme une v3 vide :
  aucun bloc, aucune étape, et rien pour le dire).
  **`supabase/schema.sql` N'EST PAS À REJOUER POUR CE LOT** : la liste blanche du serveur borne ce
  qui VOYAGE en partage de session, or rien n'émet de v4 sur le réseau. Elle le deviendra au lot
  où le partage portera des items — et ce sera alors l'étape qu'on oublie (précédent
  `discriminant`, v4.70.0).
  **ALLER-RETOUR : LA PROPRIÉTÉ VÉRIFIÉE EST LA STABILITÉ, PAS L'IDENTITÉ AU CARACTÈRE PRÈS.**
  « a::b » revient en « a :: b » — une normalisation d'espaces n'est pas une perte de sens, et
  exiger l'identité stricte ferait échouer un témoin sur un non-défaut. On mesure donc que deux
  passages donnent exactement ce que donne un seul : une perte RÉELLE se verrait au second.
- **L'AXE DE DENSITÉ — « UN BLOC » / « TOUTE LA FICHE », ET TROIS FAÇONS DE REGARDER LA SECONDE
  (v5.0.0, lot T8, LIVRÉ PARTIELLEMENT).** Le sélecteur demandait d'arbitrer entre deux
  PRÉSENTATIONS (« Guidé » / « Statique ») — un choix qu'aucun néophyte et aucun expert sous stress
  ne devrait avoir à faire. Il nomme désormais une **DENSITÉ** : combien de la fiche on veut voir.
  **CE QUI EST LIVRÉ** : les deux crans du haut, et le cran « Toute la fiche » devenu un conteneur à
  **trois onglets** — **Parcours** (l'Échelle, qui vivait derrière le bouton « Se repérer » de la
  rangée de commandes), **Page** (le tableau statique) et **Schéma** (`buildFlowSVG`, qui vivait
  dans le menu ⋯). **CE QUI NE L'EST PAS** : le cran « Une étape » (le mode lecteur reste une
  SURFACE, il n'est pas encore une densité de la colonne) et la page SFAR en tant que document
  distinct — le tableau statique en tient lieu.
  **AUCUN DES TROIS RENDUS N'EST RÉÉCRIT, ET C'EST UNE CONTRAINTE, PAS UNE PRÉFÉRENCE** : réécrire
  le générateur SVG reperdrait les flèches mesurées, la contre-inversion sombre, le cache de
  géométrie et la navigation par nœud — la classe de régression exacte que la règle 14 existe pour
  empêcher.
  **MAIS LES REPRENDRE NE SUFFIT PAS : IL FAUT REBRANCHER LEURS ÉCOUTEURS.** Posé dans un onglet
  sans `bindFlowZoom` / `flowPaintState` / `bindSvgNav`, le schéma n'est plus qu'une IMAGE —
  **mesuré à la première passe : zoom figé à 100 % au clic, état de session non peint**. Trois
  témoins mesurent donc le zoom, la peinture et l'invariant « taper un nœud NAVIGUE et ne coche
  rien » (v4.7.0) ; vérifiés capables d'échouer.
  **LA PAGE RESTE LE DÉFAUT DU CRAN 3, DÉLIBÉRÉMENT** : c'est ce que ce cran affichait déjà, et un
  lot qui AJOUTE deux façons de regarder n'a pas à changer par surprise ce que voit celui qui n'a
  rien demandé. L'onglet n'est pas persisté (`state.allTab`, classé `SHARE_LOCAL`) : c'est une
  consultation, pas un réglage — même règle que l'ancien sélecteur de vue du plan.
  **RETIRER UN ÉLÉMENT, C'EST BALAYER SES RÉFÉRENCES (règle 14, payée ici)** : `#planBtn` supprimé
  de la rangée, `syncDock` faisait toujours `pb.hidden=…` sur `null` → **le démarrage entier
  échouait**, sans une ligne de console, `.boot-load` figée. **Ni `npm test` ni `npm run check` ne
  pouvaient le voir** — la suite charge la page avec `?__actest`, qui n'amorce pas. C'est la
  deuxième fois de ce chantier qu'un défaut de RENDU passe sous les deux garde-fous (cf. la zone
  morte du lot T3) : après une modification du chrome de lecture, seule une sonde qui AMORCE
  l'application prouve que l'écran s'affiche.
  **⚠ LE CRAN « UNE ÉTAPE » NE TIENT PAS DANS LA RANGÉE, ET C'EST ARITHMÉTIQUE (mesuré)** : un
  troisième segment porte l'axe de **151 à 220 px**, donc la rangée de commandes de 267 à
  **336 px pour 320 disponibles** — elle s'enroulerait EN PERMANENCE sur le plus petit écran
  servi, en pleine zone de crise, là où la doctrine tient la hauteur pour un coût permanent. À
  360 px : 372 pour 360. Elle ne tient qu'à partir de ~380 px, et **un contrôle qui n'existe
  qu'au-delà d'une largeur est exactement ce que la v4.31.0 refuse** (constance positionnelle :
  « une commande qui apparaît/disparaît selon la largeur romprait la constance »).
  **LA VOIE QUI RESTE OUVERTE NE TOUCHE PAS LA RANGÉE** : garder l'entrée actuelle du lecteur (le
  bouton de la carte de bloc) et le rendre **EN LIGNE** au lieu d'un overlay — « le lecteur cesse
  d'être une surface » sans élargir quoi que ce soit. Son coût est ailleurs : reprise
  d'`audit-retour` et de la règle de partage « lecteur ouvert refuse la navigation distante »,
  qui tient à la façon dont le curseur calcule sa clé d'étape, pas à l'overlay lui-même.
  **⚠ T5b EST DÉFINITIVEMENT BLOQUÉ EN L'ÉTAT, re-mesuré après T8 et T9** : rangée **267 px** +
  quai **243 px** = **510 pour 320** sans aucun minuteur armé, **591** avec un minuteur (le quai
  monte alors à 324). Le lot T8 a bien libéré « Se repérer » (313 → 267), mais l'hypothèse du plan
  — « l'axe libère la rangée » — était fausse **dans son ampleur** : il manque encore 190 à 271 px.
  Et compléter T8 l'AGGRAVE (axe à trois crans : 336 + 243 = 579). La fusion ne redeviendra
  arbitrable que si un contrôle QUITTE la zone de crise — c'est une décision de conception, pas
  d'ingénierie, et elle n'est pas prise ici.
- **EN SESSION, L'ACTION PASSE DEVANT L'ORIENTATION — ET LE RAIL ①②③ CESSE D'ÊTRE L'OSSATURE
  (v5.0.0, lot T5 ; règle v4.4.0 ROUVERTE).** Le rail numérote un PARCOURS : il oriente quelqu'un
  qui découvre la fiche, et c'est exactement ce dont on n'a plus besoin une fois qu'on exécute.
  Mesuré à 320 × 640 : **la première étape cochable naissait à y = 721 px pour un pli à 640** —
  **zéro** étape à l'écran à l'instant où l'on démarre le soin. Une checklist qui n'affiche aucune
  ligne à cocher au démarrage n'est pas une checklist, c'est un sommaire.
  **RIEN N'EST SUPPRIMÉ, RIEN NE CHANGE DE VUE** : c'est la SUITE VERTICALE qui est réécrite, et
  **seulement une fois la session démarrée** (`agirDabord = Runtime.started && !useSv`). Hors
  session, pas un pixel ne bouge — avant d'agir on s'oriente, et le chapeau entier, les critères
  diagnostiques et le rail restent en tête (condition d'entrée QRH). La bascule se fait au moment
  précis où l'on presse « Confirmé — démarrer la session ».
  **LA NUMÉROTATION DISPARAÎT AVEC LE RAIL, ET CE N'EST PAS UN DÉTAIL** : permuter les étages en
  gardant les pastilles afficherait « ② Prise en charge » au-dessus de « ① Diagnostic confirmé » —
  **une séquence qui se lit à l'envers est pire que pas de séquence du tout**. Les étages restent
  des sections TITRÉES (`.care-flat` / `.cf-stage`), dans l'ordre ACTION → ce qui est fait → ce qui
  suivra ; aucune couleur, aucun registre, aucun écart ne change.
  **DEUX OBJETS DESCENDENT AVEC LUI** : la carte « Minuteurs & compteurs » (elle ne conduit pas le
  geste, et depuis la v5.0.0 **le quai la NOMME en permanence** — c'est cette permanence qui autorise
  à la faire descendre) et l'aperçu d'algorithme. **LE FIL D'ARIANE, LUI, RESTE COLLÉ À SA CARTE** :
  il ne situe pas dans la fiche, il dit où l'on est DANS le bloc qu'on exécute.
  **MESURÉ** : première étape à **525 px à 320 × 640** (−196) et **453 px à 390 × 844** (−158) ;
  au moins une étape entièrement cochable sous le chrome collant dans les deux formats.
  C'est l'application au téléphone de ce que la v4.59.0 admet déjà au-dessus de 1 200 px avec le
  cockpit : **la structure était juste, son seuil était faux**.
- **`audit-budget.mjs` — LE PREMIER HARNAIS QUI MESURE UNE RÉPARTITION (v5.0.0, lot T4).** Les
  seize autres mesurent des PROPRIÉTÉS : un contraste, une cible, un ordre, un débordement. Or le
  défaut central relevé par l'audit structurel n'est visible dans **aucune propriété prise
  isolément** — chaque objet de la colonne est légitime, c'est leur SOMME qui ne l'était pas. Trois
  budgets, mesurés à **320 × 640** (plancher servi) et **390 × 844**, session démarrée, **sans
  jamais défiler** : chrome permanent ≤ **30 %** de la hauteur (en-tête + rangée de commandes +
  quai) ; **au moins UNE étape cochable entièrement visible** ; pile d'actions ≤ **25 %** de la
  carte du bloc.
  **LE DEUXIÈME EST LE SEUL DONT L'ÉCHEC EST CLINIQUE** et pas esthétique — les deux autres sont
  des indicateurs de dérive. Il est **borné au cas DOCTRINAL** (bloc ≥ 4 items) pour le troisième :
  un bloc de deux lignes rend n'importe quelle pile d'actions proportionnellement énorme, et l'on
  mesurerait alors la fiche d'exemple, pas l'application.
  **CE QU'IL NE MESURE PAS, DÉLIBÉRÉMENT** : ni l'ordre, ni l'utilité d'aucun objet — deux
  dispositions opposées peuvent tenir le même budget. Un harnais qui encoderait un ORDRE figerait
  une décision de conception dans un contrôle automatique, et le prochain arbitrage se ferait
  contre l'outil au lieu de se faire contre la doctrine.
  **ÉCRIT AVANT LE CORRECTIF QU'IL COUVRE**, et c'est la seule façon de savoir qu'il mesure quelque
  chose : livré seul (T4), il était **rouge** sur le défaut de T5 (0 étape visible à 320) ; vérifié
  capable d'échouer ensuite dans l'autre sens (`agirDabord` neutralisé → rouge, fichier restauré à
  l'octet).
- **LE CHAPEAU « NE PAS OUBLIER » SE REPLIE EN SESSION (v5.0.0, lot T3) — RÈGLE ROUVERTE.** La
  v4.4.0 posait qu'il reste le CHAPEAU, entier, jamais replié. L'argument d'origine est juste — un
  memory item qu'on replie est un memory item qu'on oublie — mais il vise **le moment de la décision
  d'entrée**, pas les quarante minutes qui suivent, pendant lesquelles le chapeau ne conduit plus
  rien et **repousse ce qui conduit**. Mesuré : **172 px à 320, 133 à 390, 223 à 130 %**, en
  permanence, au-dessus de la première étape à exécuter. **Entier tant que la session n'a pas
  démarré** (condition d'entrée QRH : on le lit AVANT d'agir) ; **replié en une ligne ensuite**,
  dépliable d'un tap. Gain mesuré : **126 px à 320, 87 à 390, 164 à 130 %**. **RÈGLE 8 TENUE** : le
  registre (rouge), le glyphe ■ et le mot restent — seule la surface part ; le compte est ANNONCÉ
  (« 3 rappels ▾ »), même vocabulaire que le « +n » du quai. **LE DÉPLIAGE NE RE-REND RIEN** (bascule
  de classe en place) : un `render()` reconstruirait tout le DOM au-dessus du doigt, et le chapeau
  est le premier objet de la colonne — mesuré, la dérive du défilement est de **0 px**. `state.fsOpen`
  est TRANSITOIRE, remis à zéro à l'ouverture d'une fiche et classé dans `SHARE_LOCAL` : replier chez
  soi ne doit pas replier chez l'autre.
  **PIÈGE VÉCU, ET IL EST INSTRUCTIF** : la première version lisait la constante `started`, déclarée
  **24 lignes plus bas** dans `renderRead` — zone morte temporelle, donc `ReferenceError`, donc
  **tout le rendu échouait**. Ni `npm test` ni `npm run check` ne l'ont vu : **aucun des deux
  n'exerce un rendu**. C'est la sonde de mesure qui a parlé. Corollaire de méthode : après une
  modification de `renderRead`, le vert de la suite ne prouve pas que l'écran s'affiche.
- **LE JOURNAL DES ACTIONS REMONTE SOUS LA CARTE DU BLOC (v5.0.0, lot T2).** Il vivait en FIN de
  colonne : mesuré, « Noter l'heure » était à **y = 1829 px** sur un écran de 640 et **1588** sur
  844 — le geste de traçabilité le plus fréquent d'une réanimation était le plus loin de la main. Il
  se pose désormais **juste sous la carte du bloc courant** : c'est là que le geste se produit, donc
  là qu'on l'horodate. **PAS AU-DESSUS** — le mettre avant repousserait l'action, ce que le lot T5
  existe pour corriger. Mesuré après : **1305 px à 320** (−524) et **1101 à 390** (−487). Il reste
  sous le pli parce que la carte du bloc est haute : **T5 le fera remonter davantage**, et il ne faut
  pas vendre ce lot pour plus qu'il ne donne. En rail (≥ 780 px), rien ne change.
  **UN CONSTAT D'AUDIT CORRIGÉ AU PASSAGE** : le constat 6 de l'audit J0 affirmait que « le quai ne
  nomme pas ce qu'il cache » et que le minuteur d'une fiche est invisible. **C'est faux, et la faute
  vient de l'instrument** : j'avais mesuré `.tm-label` — le libellé d'une CARTE de minuteur, qui
  n'existe que panneau ouvert. La rangée `.rt-collapsed` dit en réalité, dans le flux,
  « Minuteurs & compteurs · 1 minuteur · 1 compteur ▾ Afficher », **visible sans défiler à 390 px**
  (y = 494 pour un pli à 844). Rien n'était donc à ajouter au quai — et l'y ajouter aurait
  **dupliqué une constante sur deux canaux**, ce que la v4.70.1 proscrit.
- **UN COMPTE RENDU NE SE DÉCALE PLUS — LE TEXTE DES ÉTAPES EST ARCHIVÉ AVEC LA SESSION (v5.0.0,
  lot T1)** : une clé de cochage vaut `visite:bloc:INDEX`, et `exportSessionReport` la résolvait
  contre la fiche **ACTUELLE** (`stepTextFromKey`), `snapshotSession` n'archivant que `ficheId` et
  `ficheTitle`. **Mesuré, preuve pure** : après une insertion d'étape en tête de bloc, la clé
  `1:b1:2` ne désigne plus « ⚠ Adrénaline IM » mais « Appeler à l'aide » — un enregistrement de soin
  archivé nommait donc **le mauvais geste, en silence**. Le défaut était ancien ; **MK5-b (v4.64.0)
  l'a rendu atteignable en deux taps**, réordonner une étape étant devenu un geste ordinaire.
  `snapshotSession` archive désormais `stepTexts` — le texte des seules étapes **touchées** (cochées,
  constatées, en écart) et le titre de leur bloc. **Pas la fiche entière** : une session doit rester
  légère, et ce qu'on n'a pas touché n'a pas à être figé. `stepTextFromKey(f,key,snap)` lit
  l'archive **d'abord**, la fiche en repli — les sessions archivées AVANT le correctif n'ont pas de
  `stepTexts` et gardent l'ancien comportement, qui est tout ce qu'on peut faire pour elles.
  **ET CE TEXTE NE MONTE JAMAIS** : `stepTexts` rejoint `SESS_LOCAL`, comme la trace do-verify depuis
  la v4.54.0 — c'est du contenu **clinique**, il reste sur l'appareil qui l'a produit, et le drapeau
  `vElsewhere` **dit** son absence au compte rendu distant au lieu de la taire. Sept témoins, dont
  trois qui vérifient d'abord que **le défaut existe** : un contrôle qui ne rencontre pas le défaut
  ne le couvre pas.
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
- **LE PROMPT IA EST UN CONTRAT, ET IL SE VÉRIFIE (v4.73.0)** : `AI_PROMPT` promet un format
  d'import ; rien ne vérifiait que l'application l'accepte, ni que le gabarit MONTRÉ soit
  lui-même correct. **IL NE L'ÉTAIT PAS** : le `\n` de `localInfo` vivait dans un littéral
  gabarit, donc JavaScript le transformait en VRAI saut de ligne — le JSON d'exemple affiché à
  l'IA contenait une chaîne coupée par une fin de ligne, donc invalide. Une IA qui recopie
  fidèlement ce qu'on lui montre produisait un fichier que l'import refuse, et la faute
  paraissait venir d'elle. Il faut `\\n` dans la source pour afficher `\n`.
  `scripts/audit-prompt.mjs` EXTRAIT le schéma du prompt lui-même, le parse, le passe par
  `migrate()` et vérifie qu'aucun champ ne tombe ; il est PUR (aucun rendu, aucun clic) — il
  mesure un contrat, pas un écran. **Tout champ modèle ajouté doit entrer dans le prompt ET dans
  ce harnais** : `discriminant` (v4.70.0) et `onDue` (v4.70.0) y étaient absents pendant trois
  versions, donc jamais produits par une IA.
  **CE QUE LA v4.73.0 A AJOUTÉ AU PROMPT, sur demande utilisateur** : (1) la population et le
  contexte vont dans `discriminant`, PAS dans le titre — et « ne le devine jamais » (aucune
  migration ne découpe un titre, le prompt ne doit pas le faire non plus) ; (2) `onDue`, l'action
  que l'alarme annoncera ; (3) **des BUDGETS DE LONGUEUR chiffrés sur les seuils RÉELS des
  garde-fous** (challenge ≤ 110 c., bloc ≤ 7 étapes, ≤ 2 séparateurs « · »/« + » par étape,
  rappel ≤ 110 c. et 4 max, titres de bloc 2-4 mots) — les seuils du prompt et ceux de l'éditeur
  ne doivent JAMAIS diverger, sinon l'IA produit ce que l'app signale ; (4) **ce que « :: » fait
  À L'ÉCRAN** : tout ce qui suit, jusqu'à la fin de la ligne, sort du texte principal et
  s'affiche en gris, en bulle, à chasse fixe. C'est un outil de MISE EN PAGE autant que de
  méthode : les chiffres passés après « :: » raccourcissent la ligne de moitié à l'œil.
- **Nommage SQL** : ne JAMAIS renommer un identifiant existant **sans gain fonctionnel** — et
  quand le gain existe, le faire par un bloc de renommage IDEMPOTENT plus une vue de compatibilité
  `security_invoker` (précédent : `fiches` → `cognitive_aids`, lot T9 v5.0.0, décrit plus haut).
  `category_sets`, `sessions`… restent historiquement en français ; un renommage gratuit casserait
  les instances déployées et le client pour rien ; tout **nouvel** objet (table, fonction, politique,
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
  **UN MÉCANISME N'EST PAS UN CORRECTIF : IL FAUT AUSSI L'APPELER (v4.73.0, signalé à l'usage —
  « dans le menu ⋯, partage en cours (n) : n ne se met toujours pas à jour »)** : la v4.55.2 avait
  donné au menu le moyen de se refaire, et ne s'en servait QUE sur une offre de passation. Le compte
  de participants, lui, restait celui de l'ouverture de la fiche — c'est-à-dire **zéro** dans le cas
  normal, où l'on ouvre le partage AVANT que le collègue rejoigne. `shareMenuRefresh()` est donc
  appelée là où la donnée change : à l'affectation de `Share.participants`, dans le sondage. On
  compare une **SIGNATURE** et non la longueur (un participant coupé, détaché ou promu change ce que
  le menu affiche sans changer le nombre de lignes) et on ne refait rien si elle n'a pas bougé — le
  sondage passe là toutes les deux secondes.
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
- **LIEN MORT — L'ÉCRAN DE L'INVITÉ LE DIT, ET SES CONTRÔLES LE MONTRENT (v4.73.0, proposition
  utilisateur : « améliorer le mode invité lorsque la session est coupée / se termine → tout griser
  avec un message »)**. Avant, RIEN ne changeait : le quai remplaçait un jeton de sept caractères
  (« suit » → « fini »), et un geste tenté produisait une annonce INVISIBLE sur `#srLive` — la seule
  façon d'apprendre qu'on ne recevait plus rien était donc d'essayer quelque chose, et de ne rien
  voir se passer. C'est le pire mode de défaillance nommé par le plan (« cocher dans le vide en
  croyant contribuer ») et la donnée périmée présentée comme vivante (ECRI 2015, danger n°2).
  Le hook `onStatus` **existait sans corps ni assignataire** : rien, dans toute l'interface, ne
  réagissait à la mort du lien. Il porte désormais `shareOverPaint()`.
  **TROIS DÉCISIONS ET DEUX REFUS.** (1) Un **bandeau DANS LE FLUX** en tête du contenu, jamais une
  modale ni une banderole (règle 11 — et l'invité tient encore une fiche qu'il doit pouvoir LIRE) ;
  il porte la SORTIE (« Quitter le partage… », le geste qui existe déjà), parce qu'un écran figé sans
  porte est ce que la v4.47.0 s'était donné pour tâche de supprimer. Registre **ATTENTION**, pas
  ALERTE : une liaison qui s'arrête n'est pas un geste clinique manqué. (2) Les **contrôles prennent
  l'apparence désactivée**, au patron EXACT de `share-scribe` — c'est cela que « griser » veut dire
  ici, et c'est le seul greying que WCAG exempte de son seuil. Ils restent CLIQUABLES : la garde doit
  garder la main pour annoncer le refus. (3) La liste est celle de `MUTE_SEL`, **doublée en CSS avec
  la mention qui l'exige** (même dispositif que `LEAD_ONLY_SEL`) : si l'une bouge, l'autre doit
  bouger. **REFUS 1 — le texte clinique n'est PAS grisé** : ce qui est écrit là reste VRAI et utile
  (c'est le dernier état connu du soin), et l'estomper passerait sous AA — on ne rend pas illisible
  ce qu'on demande à quelqu'un de continuer à lire. **REFUS 2 — aucune désaturation d'ensemble** :
  un filtre éteindrait le rouge des étapes vitales et l'ambre des vigilances (règle 8). La CAUSE est
  dite (« terminé » / « retiré » / « expiré ») parce qu'on n'en tire pas les mêmes conclusions.
  Peinture **chirurgicale** (`render()` reste interdit sur évènement distant) et à la MÊME place que
  dans `renderRead`, sinon un re-rendu ultérieur ferait sauter le bandeau de place.
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
  **ON SUIT LE BORD VIF, ET SEULEMENT SI ON Y ÉTAIT (v4.73.0, signalé à l'usage : « quand la session
  se synchronise et que des cases sont cochées ou des blocs passés, pas de scroll — donc on finit par
  perdre le bloc actuel »)** : la doctrine d'origine — ne JAMAIS défiler sur un geste qui n'est pas
  le sien — protégeait un cas et en cassait un autre, celui de quelqu'un qui SUIT la progression et
  que l'hôte laisse derrière, carte après carte. Le critère n'est donc plus « qui a appuyé » mais **OÙ
  REGARDAIT-IL** : si le bout du journal était à l'écran avant l'application, il suivait le bord vif
  et on l'y garde ; s'il avait défilé ailleurs (il consulte un passage antérieur), **rien ne bouge** —
  `#srLive` et la carte l'informent, comme avant. C'est la règle de visibilité d'`ovAdvanceRender`,
  appliquée à l'intention CONSTATÉE au lieu de l'être au geste. Le témoin d'`audit-partage` a donc
  changé de PROPRIÉTÉ, pas de sujet : il mesure désormais les **deux** régimes, et il a fallu placer
  le bout EN BAS de l'écran pour qu'il soit **capable d'échouer** — centré, `keepAnchor` laissait la
  nouvelle carte visible même sans suivi, et le contrôle passait au vert sur le défaut qu'il couvre
  (leçon v4.31.1, vérifié dans les deux sens).
  **~~LE LECTEUR INVERSAIT LE RÉGIME~~ — CADUC DEPUIS LE LOT T14 (v5.0.0).** Ce régime existait
  parce que la clé d'étape du lecteur était calculée AU CLIC depuis `state.nav` : une navigation
  distante arrivée entre le `pointerdown` et le `click` aurait fait cocher la mauvaise étape. La
  carte de bloc n'a pas cette exposition — son `data-ck` est inscrit dans le DOM AU RENDU, donc une
  navigation distante le remplace au lieu de le décaler. **Une navigation distante s'applique
  désormais normalement** (régime `anchored`), et la file `deferred` ne sert plus qu'à `verify` et
  `gap`, drainés au prochain geste local de navigation (cf. `shareDrainDefer`).
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

## Se repérer dans `index.html` (monofichier, ~18 800 lignes)
Le fichier s'ouvre sur un **grand commentaire d'architecture** (objectif, règles de conception,
modèle de données, règles de sécurité) : le lire en premier. Ensuite, dans l'ordre.

> **Le tableau ci-dessous est un RÉSUMÉ, pas un index** : il décrit une vingtaine de sections sur
> les **63** bannières `/* ===== … ===== */` du fichier, et volontairement sans numéros de ligne —
> ils seraient périmés au commit suivant. Pour l'index EXACT et à jour, une commande :
>
> ```bash
> grep -n '^/\* ===== \|^  /\* ===== ' index.html
> ```
>
> Découpage global : CSS ≈ lignes 273-3379, coque HTML statique ≈ 3381-3697 (dont **22 fenêtres
> modales** déclarées en dur — `grep -c 'class="ai-modal' index.html`, toutes auditées par
> `audit-a11y.mjs` —, plus deux surfaces plein écran qui n'en sont pas : `#monMode` et
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
