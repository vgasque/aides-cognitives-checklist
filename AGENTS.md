# Instructions projet — Aides cognitives

> Fichier d'instructions **canonique**, destiné à tout contributeur, humain ou IA
> (Claude, Codex, Cursor, Gemini…). `CLAUDE.md` ne fait que l'importer.

PWA médicale **monofichier** (`index.html`), JavaScript vanille, **aucune dépendance runtime**.
Stockage local-first (IndexedDB) ; synchro cloud Supabase optionnelle (RLS). Utilisée en urgence
vitale, sous stress : clarté et robustesse priment.

> **Exceptions à la règle zéro-dépendance : pdf.js** (visionneuse des documents PDF) **et,
> depuis v5.14, jsQR** (décodeur des QR d'appariement et de synchro optique du partage sans
> serveur — même régime : vendorisé dans `vendor/jsqr/`, version notée dans son `README.txt`,
> chargé paresseusement au premier scan, cache séparé `JSQR_CACHE` gardé par `check-vendor`,
> témoin encodeur-maison→décodeur dans `tests.html` ; décision explicite de l'auteur,
> 17/08/2026).
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
   **ids lus** · **exports de test** · hashs CSP) et
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
13. **Aucune dépendance runtime**, aux exceptions vendorisées près : pdf.js et, depuis v5.14,
    jsQR (chacune chargée paresseusement, précachée dans son cache versionné, gardée par
    `check-vendor`). Tout fichier servi doit entrer dans `ASSETS` (`sw.js`). **Une POLICE embarquée
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

**LA DOCTRINE DÉTAILLÉE VIT DANS `docs/decisions/` DEPUIS LA v5.10.3** — ce fichier avait atteint
797 Ko, au-delà de la fenêtre de contexte de tout outil IA : les instructions canoniques étaient
tronquées EN SILENCE à chaque session, l'exact défaut que le découpage du changelog avait guéri
(v5.0.0, « l'archive avait dépassé le fichier qu'elle soulage »). Le déplacement est À L'OCTET
(empreintes sha256 dans chaque fichier, 164 entrées A réconciliées) ; rien n'est réécrit, et ces
fichiers restent **normatifs** — on les consulte À LA DEMANDE avant de toucher leur sujet :

| Fichier | Contenu |
|---|---|
| [`docs/decisions/conventions-de-code.md`](docs/decisions/conventions-de-code.md) (498 Ko) | **La doctrine par composant** — tous les intitulés du tableau ci-dessous |
| [`docs/decisions/doctrine-css.md`](docs/decisions/doctrine-css.md) (254 Ko) | **C1-C135** — les commentaires longs du `<style>` d'index.html, repris À L'OCTET (v5.20.5, A292) : le commentaire en place est resserré et renvoie « doctrine-css.md C‹n› » ; le détail intégral se retrouve ici sous l'id cité |
| [`docs/decisions/doctrine-js.md`](docs/decisions/doctrine-js.md) (408 Ko) | **J1-J239** — les commentaires longs du grand script d'index.html, repris À L'OCTET (v5.20.6, A293), même contrat que doctrine-css.md : renvoi « doctrine-js.md J‹n› » en place, détail intégral ici |
| [`docs/decisions/refonte-v5-6.md`](docs/decisions/refonte-v5-6.md) (149 Ko) | Refonte « verre clinique » — **A1-A112**, capsule/dock, trois matières |
| [`docs/decisions/lots-v5-7-a-v5-9.md`](docs/decisions/lots-v5-7-a-v5-9.md) (54 Ko) | **A113-A132** — retour au bloc, tri vivant, atelier d'import |
| [`docs/decisions/lot-v5-10.md`](docs/decisions/lot-v5-10.md) (13 Ko) | **A133-A138** — la Page devient un document (grille unique) |
| [`docs/decisions/lot-v5-10-1.md`](docs/decisions/lot-v5-10-1.md) (30 Ko) | **A139-A153** — audit design externe |
| [`docs/decisions/lot-v5-10-2.md`](docs/decisions/lot-v5-10-2.md) (4 Ko) | **A154-A158** — audit de code externe |
| [`docs/decisions/lot-v5-11.md`](docs/decisions/lot-v5-11.md) (8 Ko) | **A159-A169** — l'atelier d'import dit aussi **où** ça va (destination par rangée) |
| [`docs/decisions/lot-v5-12.md`](docs/decisions/lot-v5-12.md) | **A170-A197** — sélection multiple à l'accueil, titres repliables des références (v5.12, A170-A191) ; puis, **en second chapitre du même fichier**, le **lot v5.13 (A192-A197)** — clavier ouvert : le chrome cesse de poursuivre le viewport visuel (l'index annonçait « A170-A179 » et le lot v5.13 n'était indexé nulle part — corrigé à l'audit v5.19.3) |
| [`docs/decisions/lot-v5-14.md`](docs/decisions/lot-v5-14.md) | **A198-A221** — partage sans serveur, CLOS et validé terrain (couture `_io`, ShareLocal/QR/optique, secours chaud, bascules seamless deux sens, aller-retour et relais optiques, modèle de menace § 3.2) |
| [`docs/decisions/lot-v5-15.md`](docs/decisions/lot-v5-15.md) | **A222-A224** — les barres flottantes deviennent lisibles (planches 17-18) : la matière système MONTE la nuit + périmètre `--sys-edge`, ombre du quai élargie au token, registre `--act-sys` du geste d'entrée |
| [`docs/decisions/lot-v5-16.md`](docs/decisions/lot-v5-16.md) | **A225-A226** — plusieurs `.json`/`.zip` d'un geste (file d'ateliers nommés, `readImportFile` promissifié) ; QR agrandis d'un cran (240/260 px, palier < 360 intact) |
| [`docs/decisions/lot-v5-17.md`](docs/decisions/lot-v5-17.md) | **A227-A237** — la barre de sélection tient sur UNE LIGNE de 56 px (planche 20) : actes dans un tiroir, palier de dépliage mesuré à 1200 px et non 560, libellés qui disent ce qu'ils déclenchent. Puis le plan de vol du MONITEUR tient à plusieurs minuteurs (une rangée par échéance ; corriger une collision horizontale en ouvrait une verticale). **A233-A236 (v5.17.4)** : quatre écrans qui affirmaient du faux — l'état volatil se relit à la PEINTURE (pied de stockage), une décision montre TOUTES ses branches même celles sans bloc, un cran fermé dit sa VRAIE cause et répond au tap (`aria-disabled`), les dialogues prennent le focus sur l'action et non sur la croix. **A237 (v5.17.5)** : l'anneau de focus d'une fenêtre se POSE À LA MAIN (`:focus-visible` ne s'allume pas sur un focus programmatique ouvert à la souris — un état juste mais invisible) |
| [`docs/decisions/lot-v5-18.md`](docs/decisions/lot-v5-18.md) | **A238-A268** — l'accueil sans mécanisme : en-tête statique, accès dans `#homeDock` (pilule au pouce en étroit, BARRE DU HAUT en large), UNION des bibliothèques en une liste à trois rangements (phrase « Rangé par… », sections-cartes à intertitre collant DEDANS), sidebar deux clés qui FILTRENT (« Toutes » ou une bibliothèque, catégories du périmètre — pas de bouton filtre ≥ 780), provenance des homonymes, liste éditoriale unique (le tableau ≥ 1200 a vécu), palier 390, purge de home-slim et des rescues |
| [`docs/decisions/lot-v5-19.md`](docs/decisions/lot-v5-19.md) | **A269-A285** — la colonne gauche à TROIS ÉTAGES (un seul défile : le pied ne peut plus être coupé), densité 32/34 px, remise à zéro « Toutes les catégories », commandes distinctes des filtres ; le pied fusionne ses deux ✓ en UNE rangée dépliable — sans aucun aplat (« nominal = neutre ») — et devient une COLONNE de rangées à une seule colonne de texte (20 px), au lieu d'une coulée qui enjambe ; UN SEUL dessin de marque (la pastille de synchro perd sa pilule et prend un glyphe), commandes du pied en boutons discrets ; puis la colonne passe à TROIS VERTICALES (marque 24 · libellé 44 · nombre au bord droit, fabrique `hsRow`) et le socle se replie en UNE ligne « Tout est prêt » dépliable sur place ; le type à créer cesse de filtrer la liste (et DEUX harnais s'appuyaient sur ce défaut), un seul bandeau présente les deux natures ; la PILE DU QUAI se purge à toute fermeture quelle que soit la porte de sortie, et une seule primaire verte — le sommet (A277). **A278-A279 (audit design externe)** : le halo de cible se vérifie en CAPTURE (`elementFromPoint`), plus seulement en géométrie — sonde d'audit-a11y + surface « filtres posés », et `.dir-hf` porte ses 24 px dans le dessin ; la Page SFAR ANNONCE son débordement horizontal dans la barre d'échelle (l'ajustement d'office reste refusé). **A280-A282 (audit interne v5.19.3)** : un token se vérifie déclaré ET lu (`--hover` n'existait pas — deux survols inertes, prouvés réparés à la sonde ; six tokens morts purgés), la règle des 20 du CHANGELOG devient exécutoire (`check-changelog.mjs`, né rouge), et le périmètre de déploiement est TRANCHÉ — dépôt servi en entier, ce qui ne doit pas être public SORT du dépôt (`sonde/` supprimée). **A283 (v5.19.4)** : les trois trous se ferment en garde-fous — `check-tokens` (déclaré ↔ lu), `check-ids` sens inverse (#id stylé → émis), `check-fns` (déclaration → citée), tous nés rouges ; le pli QR passe par `slFoldSan`, `ltSnapUnpack` borné, purge SW par préfixe, cinq duplications factorisées. **A284 (v5.19.5)** : la chaîne d'ÉDITEUR (640→430→360) passe aux paliers `zw` — sous zoom, la recette anti-chevauchement des halos ne s'appliquait pas à la largeur effective ; équivalence exacte à zoom 1 prouvée ; les quatre paliers de composition restants ne se convertissent pas d'office (arbitrage écrit). **A285 (v5.19.6)** : un `#id` reprenait EN SILENCE la respiration d'A268 — `#filtSheetBody{padding:0 0 4px}` l'emporte sur `.ai-card>.ai-body` et remet l'axe inline à zéro, la marge négative survivant seule : anneau de focus rasé et chips 4 px à gauche du titre, sur la SEULE fenêtre qu'aucun harnais n'ouvrait. Corrigé en une propriété (`padding-block`), gardé par `check-ring.mjs`, et la feuille de filtres entre dans les surfaces d'`audit-a11y` |
| [`docs/decisions/lot-v5-20.md`](docs/decisions/lot-v5-20.md) | **A286-A296** — un saut du rail A→Z se pose sous CE QUI COIFFE le haut du défileur (barre de sélection collante, bande de zone sûre de l'iPhone installé : `env` vaut 0 en navigateur, d'où vingt et un harnais aveugles — témoin à trois cas, dont l'encoche simulée) ; et la GESTION descend au pouce — rangée au socle masquée ≥ 780, patron de « Rejoindre une session » (v5.14.3), qui n'invente aucune fenêtre. **A288** : en voie large les défileurs de l'accueil (`.home-main`, `.hs-scroll`) vivent dans `main.innerHTML` — ils repartaient de zéro à chaque re-rendu, là où la voie étroite gardait la position ; capture/restauration au patron de `.read-side`, et un piège de mesure de la famille A267 évité en route (nœud détaché). **A289 (v5.20.2)** : assainissement mesuré — trois garde-fous nés ROUGES (`check-fns` sens 2 : let écrit jamais lu ; `check-ids` sens 3 : id émis → lu, 20 croix mortes dont une née pendant l'inventaire ; `check-icons` sens 3 : entrée de table jamais citée), purges CSS/JS prouvées au grep, vingt factorisations à sortie identique (récepteur optique, memOps, cœur de cochage…), verdict perf « rien à optimiser, le boot est parse-bound », et le ✓ de « Quand l'utiliser » retrouve son vert (`:not` d'états morts qui écrasait `.pc-n.ok`, prouvé à la sonde deux moteurs). **A290 (v5.20.3)** : `ac-held-edits` survivait à `wipeLocal()` (deux listes recopiées avaient divergé) — liste UNIQUE `WIPE_SPACE_KEYS` consommée par les deux effacements, prouvé rouge→vert à la sonde |
| [`docs/decisions/lot-v5-21.md`](docs/decisions/lot-v5-21.md) | **A297-A304** — trois signalements ont la MÊME cause de fond : la refonte v5.18 a remplacé `state.scope` par `state.homeLib` sans que tous ses lecteurs suivent. **A297** : `onclick=openCatMgr` en référence NUE passait l'ÉVÈNEMENT de clic comme bibliothèque (`_catScopeForce` = MouseEvent, zéro catégorie) — et derrière, `activeCatScope` lisait un champ mort. **A298** : le gestionnaire suit le filtre et montre une SECTION PAR BIBLIOTHÈQUE sur « Toutes » (comptes, cibles de déplacement et clé de suppression bornés à leur périmètre, `data-cscope` plutôt qu'une fermeture ; lecture seule exclue). **A299** : une rangée par NOM dans la colonne (le filtre compare par nom depuis la v5.18 — deux homonymes filtraient à l'identique), pastille MULTICOLORE quand les couleurs divergent. **A300** : `.rt-dock .tm-btn:hover` (0,3,0) battait `.tm-reset.holding` (0,2,0) et son raccourci `background:` effaçait la jauge de « Maintenir » — invisible à toute sonde qui dispatche un `pointerdown` SANS amener le pointeur, et le survol reste collé au toucher iOS. **A301** : l'anneau nocturne `--sys-edge` s'arrêtait à la capsule ; le volet, sans ombre la nuit, n'avait aucun bord — trois côtés, le haut étant la jointure. **A302** : la passation de la main, mesurée — le rôle ne borne QUE le fil, les droits de PROPRIÉTÉ (arrêter, couper, rouvrir, réécrire un rôle) ne se transfèrent jamais, et l'hôte n'est jamais bridé sur son écran ; l'arrêt gelait donc celui qui CONDUISAIT (`Share.soloLead`), le dialogue disait faux, et `_reclaimLead` existait SANS PORTE (« Reprendre la main »). **A303** : « la destination devient la vue » écrivait `state.scope` — no-op, et la liste tombait de deux rangées à ZÉRO ; six autres lecteurs de `state.scope` restent faux, mesurés et listés. **A304 (v5.21.1)** : ces six lecteurs sont ralliés à une SOURCE UNIQUE (`homeScope()`) — plus de « Sélectionner »/« Créer » morts sur une bibliothèque en lecture seule, création DANS la bibliothèque affichée mais ANNONCÉE (une entité neuve naît `validated`, donc publiée aussitôt), import et renvoi croisé qui suivent ; ⚠ rendre VARIABLE une condition jusque-là constante oblige à re-vérifier qui la rejoue — `#hdrNew` restait périmé au tap de la colonne, d'où `syncNewBtn` sur le patron de `syncMgrBtn`, et `newFiche()` reste synchrone par court-circuit AVANT l'await (trois harnais en dépendent) |

Le classement des A-entrées est CHRONOLOGIQUE (par lot) et non thématique, à dessein : la doctrine
se cite elle-même par numéro (« cf. A140 ») — le numéro EST l'adresse, et une dispersion par thème
casserait chaque renvoi. **La carte plage → fichier vit aussi dans `docs/README.md`** (audit
v5.19.3) : un outil qui explore `docs/` sans passer par ce fichier — une IA générique — y résout
tout renvoi A-xxx sans grep intégral. Pour chercher par SUJET, la carte ci-dessous donne les intitulés à
retrouver (grep) dans `conventions-de-code.md` :

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

Restent dans CE fichier, en entier : les **15 règles**, la **règle de publication**, **Avant
chaque commit** (garde-fous et audits), le **Périmètre réglementaire** (statut
non-dispositif-médical — à consulter AVANT toute fonctionnalité produisant une sortie
individualisée) et **Se repérer dans `index.html`** (carte du monofichier, avec la commande qui en
donne l'index exact). **Toute NOUVELLE entrée A va dans le fichier de son lot** sous
`docs/decisions/`, jamais ici — c'est ce qui borne la croissance de ce fichier par construction.

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

## Refonte v5.6 — direction « verre clinique, mat »

> **Déplacée dans [`docs/decisions/refonte-v5-6.md`](docs/decisions/refonte-v5-6.md)** (v5.10.3) — contenu repris à
> l'octet, rien n'est réécrit : La refonte « verre clinique, mat » — A1 à A112 (+ R6, R9, dock, volets, partage résumé).

## Lot v5.7 — « la bonne information, au bon moment, au bon endroit »

> **Déplacée dans [`docs/decisions/lots-v5-7-a-v5-9.md`](docs/decisions/lots-v5-7-a-v5-9.md)** (v5.10.3) — contenu repris à
> l'octet, rien n'est réécrit : Lots v5.7 à v5.9 — A113 à A132 (retour au bloc, tri vivant, atelier d'import).

## Lot v5.10 — « Page » : la feuille SFAR devient un document

> **Déplacée dans [`docs/decisions/lot-v5-10.md`](docs/decisions/lot-v5-10.md)** (v5.10.3) — contenu repris à
> l'octet, rien n'est réécrit : Lot v5.10 « Page » — A133 à A138 (grille unique, largeur d'auteur).

## Lot v5.10.1 — audit design externe : ce que les garde-fous ne voyaient pas

> **Déplacée dans [`docs/decisions/lot-v5-10-1.md`](docs/decisions/lot-v5-10-1.md)** (v5.10.3) — contenu repris à
> l'octet, rien n'est réécrit : Lot v5.10.1 — audit design externe, A139 à A153.

## Lot v5.10.2 — audit de code externe : ce que les dix-huit garde-fous ne voyaient pas

> **Déplacée dans [`docs/decisions/lot-v5-10-2.md`](docs/decisions/lot-v5-10-2.md)** (v5.10.3) — contenu repris à
> l'octet, rien n'est réécrit : Lot v5.10.2 — audit de code externe, A154 à A158.

## Lot v5.12 — agir sur plusieurs fiches, replier un document

> **Vit dans [`docs/decisions/lot-v5-12.md`](docs/decisions/lot-v5-12.md)** — A170 à A191 (et le
> lot **v5.13**, A192-A197, en second chapitre du même fichier) : sélection
> multiple à l'accueil (déplacer, ranger, supprimer avec confirmation forte), titres H1/H2/H3
> repliables et mémorisés par protocole, et le chrome collant qui suit enfin le viewport visuel.
> **Le CONTENU de la barre a été refait en v5.17** (planche 20, A227-A230) : hauteur constante de
> 56 px, actes dans un tiroir sous les 1200 px, libellés entiers — cf.
> [`docs/decisions/lot-v5-17.md`](docs/decisions/lot-v5-17.md). La coque décrite ici n'a pas bougé.

## Lot v5.11 — l'atelier d'import dit aussi « où » ça va

> **Vit dans [`docs/decisions/lot-v5-11.md`](docs/decisions/lot-v5-11.md)** — A159 à A169 : destination
> (bibliothèque **et** catégorie) réglable RANGÉE PAR RANGÉE dans l'atelier, bandeau qui commande les
> cochées, « garder celle du fichier » par défaut, menus en feuille à toute largeur.

## Conventions de code

> **Déplacée dans [`docs/decisions/conventions-de-code.md`](docs/decisions/conventions-de-code.md)** (v5.10.3) — contenu repris à
> l'octet, rien n'est réécrit : Conventions de code — la doctrine détaillée par composant (registres, chrome, accueil, partage, stockage…).

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
