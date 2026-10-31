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
> pdf.js est vendorisé dans `vendor/pdfjs/` (version figée, notée dans `vendor/pdfjs/README.txt`), chargé
> **paresseusement** (`import()` au premier document ouvert — jamais au démarrage), **précaché
> par `sw.js`** (hors ligne dès l'installation).
> **LA VIGNETTE D'UN DOCUMENT COMPTE COMME UNE OUVERTURE** et suit donc la même règle (v4.36.0) :
> `bindAttList` appelait `hydrateAttThumbs` inconditionnellement, si bien qu'ouvrir une FICHE
> portant un PDF chargeait 1 773 Ko de pdf.js — pour 0 rangée à l'écran, les documents ayant
> déménagé dans la feuille « Consulter » en v4.23.0 (feuille elle-même purgée en v5.30, A367). Ne générer une vignette que si une rangée est
> réellement dans le flux : `if(main.querySelector('[data-thumb]'))`. Mettre à jour pdf.js = décision explicite +
> test hors-ligne complet (mode avion, PDF 50+ pages, iPhone). **Aucune autre dépendance runtime
> n'est autorisée** ; tout nouveau fichier servi doit être ajouté à `ASSETS` (`sw.js`).

### Mettre à jour un actif vendorisé (pdf.js, jsQR, polices) — la marche à suivre

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

Même discipline pour jsQR (`vendor/jsqr/README.txt` + `JSQR_CACHE`) et pour les polices
(`vendor/fonts/README.txt` annonce leur taille en octets ; `check-vendor` la compare aux fichiers). **`playwright` ne suit pas cette règle** : c'est une
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
2. **Avant chaque commit** : `npm run check` (les 27 garde-fous statiques du script `check` de
   `package.json` — syntaxe JS **et CSS**, couleurs, classes émises **et stylées**, échelles, service
   worker, actifs vendorisés, entrées de fichier, SQL, ids, exports de test, lexique, guide, tokens,
   fonctions, hashs CSP…) et `npm test` (Chromium **et** WebKit). Si le CSS a changé : `npm run design:build`.
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
8. **Les registres ne se mélangent pas** (tokens `--crit`, `--warn`, `--ok`, `--act` ; réécrite en
   v5.38, A407) : **rouge** = ce qui TUE si on l'oublie, et l'alarme active — rien de permanent n'est
   rouge ; **ambre** = là où l'on risque de SE TROMPER (dose, dilution, seuil), et l'échéance ;
   **vert** = fait, ou système nominal (le « ● SESSION » de l'ECAM) ; **bleu** = l'action et le bloc
   courant. Ce qui tourne normalement et ne demande rien n'a PAS de couleur (poste de pilotage sombre).
   Une catégorie n'est jamais plus proche d'un registre que deux catégories entre elles (A408). Une
   couleur n'est JAMAIS seule : toujours un glyphe et un mot.
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
    `check-vendor`). Tout fichier servi doit entrer dans `ASSETS` (`sw.js`). **Des POLICES
    embarquées** (`vendor/fonts/` : Source Serif 4 depuis v4.61.0, puis Manrope et IBM Plex Mono
    depuis v5.6 — trois familles, quatre fichiers woff2, SIL OFL, tailles en octets dans
    `vendor/fonts/README.txt`) : ce n'est pas une dépendance runtime — aucun code, aucun appel
    réseau — mais des ACTIFS SERVIS, donc soumis à la même règle (entrée dans `ASSETS`,
    `font-src 'self'`, trois tokens de famille gardés par `check-fonts`, mise à jour = décision
    explicite comme pdf.js).
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

## Avant toute modification — la méthode pour tout prendre en compte

**POURQUOI CETTE SECTION (audit des instructions, 31/10/2026).** La doctrine compte plus de 500
décisions numérotées, réparties sur une cinquantaine de fichiers, et **beaucoup s'amendent ou se
renversent** (« amende A383 », « renverse A126 »). Une demande qui ne lit que le code, ou que la
première entrée trouvée, défait une décision récente sans le savoir. Ce fichier ne peut pas tout
contenir (il a déjà été tronqué en silence à 797 Ko) ; il dit donc **comment chercher**, et c'est
non négociable :

1. **Lire la doctrine que le code cite.** Autour de chaque ligne touchée, les commentaires
   renvoient à leur source : `A‹n›` (décisions, `docs/decisions/lot-*.md`), `doctrine-js.md J‹n›`,
   `doctrine-css.md C‹n›`. Ouvrir ces entrées **avant** d'éditer — un commentaire resserré n'est
   qu'un renvoi, le détail (et le piège) est dans le fichier cité.
2. **Chercher par NOM, pas seulement par sujet** : chaque fonction, classe, `#id`, clé de stockage
   ou libellé affiché qu'on touche se cherche dans la doctrine —
   `grep -rn "nomDeFonction\|.classe\|libellé" docs/decisions/` — puis la **carte par sujet**
   ci-dessous donne les lots à relire.
3. **La dernière décision gagne.** Pour toute entrée trouvée, chercher ses amendements :
   `grep -rn "A383\b" docs/decisions/` — une entrée plus récente peut l'amender, la renverser ou la
   clore. Le numéro le plus élevé fait foi.
4. **Ne jamais reproposer une forme refusée.** La plupart des lots de design se terminent par
   des « formes refusées / écartées » (par l'auteur, sur maquette) :
   `grep -rln "refusée\|écartée" docs/decisions/` sur le sujet avant de proposer un dessin.
5. **Suivre les couplages** — une fonctionnalité n'est finie que si ce qui la RÉPÈTE suit
   (garde-fou entre parenthèses quand il existe) :
   - modèle de données : `migrate()`/`sanitizeCats()`/`migrateProtocol()` (règle 5), le commentaire
     « MODÈLE DE DONNÉES » en tête d'`index.html`, le prompt IA `AI_PROMPT` (`audit-prompt`), les
     deux aides d'exemple `seed()`/`seed2()`, et `docs/conversion-v3-vers-v4.md` si un champ part
     (règle 12) ;
   - un geste ou un libellé de session : `GUIDE_ETAPES`/`GUIDE_GESTES`/`GLOSSAIRE`
     (`check-guide`, `audit-guide`) ; tout mot affiché : lexique fermé aide · protocole · données
     (`check-lexique`, A461) ;
   - ce qui sort de l'appareil : registre RGPD `docs/deploiement-et-conformite.md` § 3-3.2 ET
     notice de `#joinScreen` (règle 15) ; toute sortie individualisée : § 2 réglementaire **avant**
     le code ;
   - schéma serveur : `supabase/schema.sql` (à rejouer : le dire dans les notes de version) et
     `supabase/rls-tests.sql` (syntaxe des deux : `check-sql`) ;
   - une clé locale : `WIPE_SPACE_KEYS` (A290) ; un fichier servi : `ASSETS` de `sw.js`
     (`check-sw`) ; une fonction exportée au test : `__ac_test__` (`check-actest`) ;
   - une surface capturée (crise, accueil, quai, menu ⋯) : `node design/capture.mjs` puis
     `npm run design:build` ; une surface décrite : `design/ds/GUIDELINES.md` (rédigé à la main,
     rien ne signale sa péremption).
6. **Écrire la décision.** Toute décision nouvelle prend le numéro A suivant (A510 au lot v6.0 ;
   le plus haut : `grep -rhoE '^#+ A[0-9]+' docs/decisions | grep -oE '[0-9]+' | sort -n | tail -1`)
   dans le fichier de SON lot (`docs/decisions/lot-vX-Y.md`, créé au besoin), avec ses
   formes refusées s'il y en a ; puis une ligne dans la carte ci-dessous ET dans
   `docs/README.md`, et l'entrée `CHANGELOG.md`. Jamais de doctrine détaillée dans CE fichier.

## Où trouver quoi

**LA DOCTRINE DÉTAILLÉE VIT DANS `docs/decisions/`** (depuis la v5.10.3 : ce fichier avait
atteint 797 Ko et était tronqué EN SILENCE par tout outil IA). Ces fichiers sont **normatifs** ;
on les consulte À LA DEMANDE avant de toucher leur sujet (méthode ci-dessus). Le numéro A est
l'adresse (« cf. A140 ») : le classement est CHRONOLOGIQUE, par lot, jamais par thème.
**L'index fin — une ligne par décision, A1 → A510 — est `docs/README.md`.** Ci-dessous : la liste
des fichiers, puis la carte par sujet.

### Les fichiers

| Fichier | Plage | Sujet |
|---|---|---|
| [`conventions-de-code.md`](docs/decisions/conventions-de-code.md) | — | Doctrine PAR COMPOSANT (antérieure à v5.10.3, amendée depuis) : chercher par intitulé, cf. carte par sujet |
| [`doctrine-css.md`](docs/decisions/doctrine-css.md) / [`doctrine-js.md`](docs/decisions/doctrine-js.md) | C1-C135 / J1-J239 | Les commentaires longs du `<style>` et du script, repris à l'octet : un renvoi « C‹n› » / « J‹n› » dans le code se résout ici |
| [`garde-fous-et-audits.md`](docs/decisions/garde-fous-et-audits.md) | — | L'histoire et la raison de chaque garde-fou `check-*` et de chaque piège de harnais (ex-« Avant chaque commit ») |
| [`refonte-v5-6.md`](docs/decisions/refonte-v5-6.md) | A1-A112 | Refonte « verre clinique, mat » : capsule, quai, volets, trois matières |
| [`lots-v5-7-a-v5-9.md`](docs/decisions/lots-v5-7-a-v5-9.md) | A113-A132 | Retour au bloc, tri vivant, atelier d'import |
| [`lot-v5-10.md`](docs/decisions/lot-v5-10.md) · [`-10-1`](docs/decisions/lot-v5-10-1.md) · [`-10-2`](docs/decisions/lot-v5-10-2.md) | A133-A158 | La Page devient un document ; audits design et code externes |
| [`lot-v5-11.md`](docs/decisions/lot-v5-11.md) | A159-A169 | L'atelier d'import dit où ça va (destination par rangée) |
| [`lot-v5-12.md`](docs/decisions/lot-v5-12.md) | A170-A197 | Sélection multiple, titres repliables ; 2ᵉ chapitre = lot v5.13 (clavier ouvert, A192-A197) |
| [`lot-v5-14.md`](docs/decisions/lot-v5-14.md) | A198-A221 | Partage SANS serveur (direct, QR, par l'écran), modèle de menace |
| [`lot-v5-15.md`](docs/decisions/lot-v5-15.md) · [`-16`](docs/decisions/lot-v5-16.md) | A222-A226 | Barres flottantes lisibles ; multi-import, QR agrandis |
| [`lot-v5-17.md`](docs/decisions/lot-v5-17.md) | A227-A237 | Barre de sélection sur une ligne, moniteur multi-minuteurs, écrans véridiques, anneau de focus posé à la main |
| [`lot-v5-18.md`](docs/decisions/lot-v5-18.md) | A238-A268 | L'accueil sans mécanisme : union des bibliothèques, colonne gauche qui filtre |
| [`lot-v5-19.md`](docs/decisions/lot-v5-19.md) | A269-A285 | Colonne à trois étages, halo vérifié en capture, garde-fous tokens/ids/fonctions |
| [`lot-v5-20.md`](docs/decisions/lot-v5-20.md) | A286-A296 | Rail A→Z sous ce qui coiffe, défileurs gardés, assainissement mesuré, `WIPE_SPACE_KEYS` |
| [`lot-v5-21.md`](docs/decisions/lot-v5-21.md) | A297-A307 | `state.scope` → `homeScope()`, gestionnaire de catégories par bibliothèque, passation de la main |
| [`lot-v5-22.md`](docs/decisions/lot-v5-22.md) | A308-A316 | Gestionnaire de catégories en liste, curseur de teinte OKLCH, rail 280 px |
| [`lot-v5-23.md`](docs/decisions/lot-v5-23.md) · [`-24`](docs/decisions/lot-v5-24.md) | A317-A329 | Partage « seamless » : panne détectée, retour seul, « Connexion perdue », feuille qui dit quoi faire |
| [`lot-v5-25.md`](docs/decisions/lot-v5-25.md) · [`-26`](docs/decisions/lot-v5-26.md) | A330-A332 | Écran de démarrage d'une aide ; arrivée sur une aide (anneaux du quai) ; la panne et les gestes |
| [`lot-v5-27.md`](docs/decisions/lot-v5-27.md) | A333-A335 | « Reprendre » après une complication (renverse A126), barre « ↩ Bloc », éclair `bolt` |
| [`lot-v5-28.md`](docs/decisions/lot-v5-28.md) | A336-A343 | Terminer la session, menu ⋯, méta d'accueil, retrait du parcours, moniteur, dernier repère |
| [`lot-v5-29.md`](docs/decisions/lot-v5-29.md) | A344 | La Page : l'arbre est le fil (voies, impression) |
| [`lot-v5-30.md`](docs/decisions/lot-v5-30.md) | A345-A376 | LA REFONTE v5 — échelle typo A6 NORMATIVE, étapes CRITIQUE/VIGILANCE en mots, quai, accueil en cartes, deux matières de fenêtre, échelle des contrôles, un seul dessin du parcours |
| [`lot-v5-31.md`](docs/decisions/lot-v5-31.md) · [`-32`](docs/decisions/lot-v5-32.md) | A377-A382 | La coche lance / compte / le bloc minute ; ne pas anticiper ; le MOMENT d'une étape (`from`, `repeat`) |
| [`lot-v5-33.md`](docs/decisions/lot-v5-33.md) | A383-A387 | Éditeur : « Réglages » par étape ; partage : invité figé, hôte qui consulte une autre aide |
| [`lot-v5-34.md`](docs/decisions/lot-v5-34.md) · [`-35`](docs/decisions/lot-v5-35.md) | A388-A391 | Parcours : un dessin, trois lieux ; accueil en une colonne ; « Essayer » fidèle ; Page (voies) |
| [`lot-v5-36.md`](docs/decisions/lot-v5-36.md) | A392-A395 | Impression de la Page, export d'une sélection, « Branche », jalon en ligne « SI » |
| [`lot-v5-37.md`](docs/decisions/lot-v5-37.md) | A396-A399 | La revue « à tout moment » (bloc `review`), la bande des repères (`item.poso`) |
| [`lot-v5-38.md`](docs/decisions/lot-v5-38.md) | A400-A417 | Audit UX : registres réécrits (règle 8), nom court, pliables, alias de tokens purgés |
| [`lot-v5-39.md`](docs/decisions/lot-v5-39.md) | A418-A439 | Sommaire des PDF, filtre par nom, feuille « Affichage », retour système en pile réelle (A430), Administration, charge |
| [`lot-v5-40.md`](docs/decisions/lot-v5-40.md) · [`-41`](docs/decisions/lot-v5-41.md) | A440-A448 | Compteur qui relance un minuteur ; porte « Ajouter » de l'éditeur, recherche |
| [`lot-v5-42.md`](docs/decisions/lot-v5-42.md) · [`-43`](docs/decisions/lot-v5-43.md) | A449-A451 | La revue se dessine (jauge) ; le parcours suit l'arbre (deux crans) ; case maîtresse, rendu Linux |
| [`lot-v5-44.md`](docs/decisions/lot-v5-44.md) | A452-A459 | L'éditeur Markdown des références (liens PDF, tableaux, collage, relecture `mdLint`) |
| [`lot-v5-45.md`](docs/decisions/lot-v5-45.md) · [`-46`](docs/decisions/lot-v5-46.md) · [`-47`](docs/decisions/lot-v5-47.md) | A460-A466 | Apprentissage : lexique fermé (A461), un nom par vue, brouillon par défaut, lien direct `#a=`, « Prendre en main » |
| [`lot-v5-48.md`](docs/decisions/lot-v5-48.md) | A467-A472 | L'exercice guidé (le guide suit l'app) ; barre Markdown au-dessus du clavier iOS |
| [`lot-v5-49.md`](docs/decisions/lot-v5-49.md) | A473-A474 | Déconnexion d'un seul appareil, deux compteurs dans la capsule ; jauge du seuil dans l'étiquette |
| [`lot-v5-50.md`](docs/decisions/lot-v5-50.md) | A475-A477 | Les COLLECTIONS (rangement personnel), barre de sélection en tiroir, « Avec qui ? » |
| [`lot-v5-51.md`](docs/decisions/lot-v5-51.md) · [`-52`](docs/decisions/lot-v5-52.md) | A478-A484 | Qui crée une bibliothèque, demandes, l'administrateur voit tout ; tête de feuille ; design system relevé |
| [`lot-v5-53.md`](docs/decisions/lot-v5-53.md) · [`-54`](docs/decisions/lot-v5-54.md) | A485-A493 | La colonne dit « avec qui » ; bibliothèques vides ; l'anneau d'ouverture suit la modalité |
| [`lot-v5-55.md`](docs/decisions/lot-v5-55.md) | A494-A495 | Administration devient une page à sections |
| [`lot-v5-56.md`](docs/decisions/lot-v5-56.md) | A496-A498 | La collection se choisit à la création ; le voile d'une feuille absorbe le tap ; tête du menu des catégories |
| [`lot-v5-57.md`](docs/decisions/lot-v5-57.md) | A499-A501 | « Tout est prêt » ; pastille du compte sur l'avatar « Moi » ; colonne gauche sous la barre d'état iPad |
| [`lot-v6-0.md`](docs/decisions/lot-v6-0.md) | A502-A510 | REFONTE « Natif » (cible décidée, implémentation à venir) : verre clair, onglets au téléphone, grand titre, listes groupées, cases rondes, feuilles du bas, moniteur ; arbitrages après mesure (A510) |

### Carte par sujet

Point d'entrée de lecture, pas une liste exhaustive : compléter TOUJOURS par le `grep` de la
méthode (étapes 2-3). Les intitulés de `conventions-de-code.md` sont à chercher tels quels ; les
plages A renvoient au tableau ci-dessus.

| Sujet | `conventions-de-code.md` (intitulés) | Lots postérieurs (A) |
|---|---|---|
| **Couleur, registres, accents, catégories** | Design tokens · Taxonomie des notices · Couleur dans le contenu rédigé · Saillance & registres · Couleur d'accent · Code couleur des catégories | A222-A224, A308-A316, A400, A406-A408, A416-A417, A435, A485, A503, A506 |
| **Typographie, espacement, contrôles** | Largeurs & échelles fermées | A345 (échelle A6 normative), A350, A374-A375, A403-A404, A505-A506 |
| **Étapes, statuts, contenu clinique** | Statuts, code, étapes critiques · Liseré gauche 4 px · Taille des images · Listes cochables · Marqueur d'étape hors du champ · Liens « Voir aussi » | A345, A381, A388, A401-A402, A411, A463 |
| **Mode crise : session, quai, capsule, volet** | Mode statique · Challenge-response · Alarme de minuteur · Dialogue « Terminer la session ? » · ZONE HAUTE DE CRISE | A1-A112, A331, A336-A337, A346, A349, A354-A357, A363, A403, A409-A415, A462, A473, A503, A507-A509 |
| **Minuteurs et compteurs liés, moment d'une étape, moniteur** | JALONS DE BOUCLE | A231-A232, A341-A342, A377-A382, A440, A474 |
| **Parcours, Se repérer, Page, Schéma** | Parcours de soin · Journal de parcours · Plan de l'aide · PLAN = UNE SEULE VUE | A133-A138, A339, A343-A344, A376, A388-A395, A448, A450 |
| **Complications, revue « à tout moment », bande des repères** | COMPLICATIONS · PORTÉE D'UNE ACTION DE REPRISE · REPÈRES POSOLOGIQUES | A333-A335, A396-A399, A449 |
| **Écran d'entrée d'une aide, exercice, guide** | MODE EXERCICE | A330, A347, A358, A366, A460, A463-A467 |
| **Accueil, colonne gauche, sélection, filtres, collections** | ACCUEIL « POSTE ACCÈS DIRECT » (historique) | A170-A191, A227-A230, A238-A307, A338, A347-A353, A365, A389, A419-A431, A443, A447, A451, A475-A477, A485-A493, A496-A500, A504, A506 |
| **Bibliothèques, comptes, Moi, Administration** | — | A364-A365, A389, A438, A473, A477-A484, A489, A494-A495, A499 |
| **Éditeurs (aide et référence)** | Indicateur de mode des éditeurs | A383-A384, A390, A441-A446, A452-A459, A468-A472, A496 |
| **Consultation, références, PDF** | FEUILLE « CONSULTER » (purgée A367) · SORTIE PDF UNIFIÉE · LE COMPTE-RENDU S'ENREGISTRE EN PDF · Documents PDF · CHERCHER DANS LES DOCUMENTS PDF | A367, A392-A393, A418, A452-A459 |
| **Import, export, entrées de fichier** | Export/import « avec documents » · TOUTE ENTRÉE DE FICHIER · LE DÉPÔT HORS ZONE | A113-A132, A159-A169, A225, A392 |
| **Partage de session** | PARTAGE DE SESSION · CE QUI VOYAGE · RÔLES ET CAPACITÉS · L'INVITÉ NE DÉPOSE RIEN · CONTINUER SEUL · TROIS RÉGIMES D'APPLICATION · JOURNAL RÉFÉRENTIEL · BILLET DE REPRISE · PASSATION DE LA MAIN · HISTORIQUE DE SESSIONS SYNCHRONISÉ | A198-A221, A302, A317-A329, A332, A385, A387 |
| **Chrome, fenêtres, clavier, zoom, iOS, retour système** | ON ANIME LA COMPOSITION · En-têtes V5 · DEUX RANGÉES COLLANTES · RAIL DE LECTURE · ANCRAGE ET DÉFILEMENT · DÉFILEMENT PRÉSERVÉ · RÉENTRÉE · HAUTEURS RELATIVES À LA FENÊTRE · PILE DE RETOUR · RETOUR SYSTÈME · Sélecteur segmenté · LOGO DE MARQUE · Pieds de page · Interactif | A192-A197, A237, A284, A313, A335, A340, A352, A361, A368-A373, A386, A405, A427, A430, A480, A492, A497, A501, A502-A504, A508 |
| **Données, stockage, synchro, sécurité** | Nommage SQL (et règles 4 à 6) | A290, A305, A475, A478-A479, A483 |
| **Outillage, garde-fous, audits** | Collision de noms de classe · Hygiène de suppression | A154-A158, A278-A283, A289, A292-A293, A329, A420, A439, A451, A482 ; `garde-fous-et-audits.md` |

## Règle de publication (IMPÉRATIF)
Publier une version = trois étapes, dans cet ordre :

1. `./release.sh X.Y.Z` — synchronise `APP_VERSION` (`index.html`), `CACHE` (`sw.js`),
   `package.json` et `package-lock.json`, recalcule les hashs CSP, régénère `design/ds/`, ébauche
   l'entrée `CHANGELOG.md`, vérifie syntaxe et tests. **Ne jamais éditer ces numéros à la main**
   (un décalage casse la mise à jour du service worker). Le script **ne committe pas**.
2. Rédiger l'entrée `CHANGELOG.md` (contenu réel, pas de « à compléter » laissé en place).
3. Committer avec de **vraies notes de version** — format des messages du dépôt :
   `vX.Y.Z : <résumé en français des changements>` — puis taguer `vX.Y.Z`.

Les étapes 2 et 3 sont le travail de l'IA (ou de l'humain), jamais du script.
**Le CHANGELOG garde les 20 dernières versions** ; au-delà, déplacer les plus anciennes dans
**`docs/changelog/vN.md`, un fichier par VERSION MAJEURE** — telles quelles, sans réécriture, EN
FIN d'archive. `release.sh` insère sans jamais élaguer : `scripts/check-changelog.mjs` rend la
règle exécutoire (≤ 20 entrées, aucune en double avec une archive). Historique de la règle :
`docs/decisions/garde-fous-et-audits.md` et `docs/changelog/v5.md` (v5.0.0, v5.19.3).
Versionnage sémantique : correctif → patch (Z), nouvelle fonctionnalité → mineure (Y). Un commit
de documentation seule (rien de servi ne change de comportement) peut se faire sans version, au
format `doc : …` (précédents dans l'historique).
Ne jamais pousser (`git push`) sans demande explicite de l'utilisateur.

## Avant chaque commit

La procédure. **L'histoire et la raison de chaque garde-fou, et le détail de chaque piège, vivent
dans [`docs/decisions/garde-fous-et-audits.md`](docs/decisions/garde-fous-et-audits.md)** (repris
à l'octet) ; chaque script dit aussi en tête ce qu'il garde et pourquoi.

1. **Script inline édité → `node scripts/csp-hashes.mjs`** (règle 3). Aucun attribut `on*=` dans
   `index.html` : sous la CSP à hashs, c'est du code mort et silencieux.
2. **`npm run check`** — les **27 garde-fous statiques**, sans dépendance (liste exacte : script
   `check` de `package.json`) : syntaxe des scripts ET de la feuille de style, couleurs, classes
   émises et stylées, animations, échelles (typo, polices, espacement, rayons, paliers), service
   worker, actifs vendorisés, entrées de fichier, SQL, stores, icônes, `data-*` lus, ids (lus,
   stylés, émis), exports de test, harnais, collant, anneau, CHANGELOG, lexique, guide, tokens,
   fonctions, hashs CSP. ⚠ Ils travaillent AU MOTIF : après une édition CSS, un commentaire mal
   fermé AVALE la règle suivante sans que `check-colors`/`check-type` ne le voient — c'est
   `check-syntax` qui le garde, ne pas le contourner. Un garde-fou nouveau se vérifie **capable
   d'échouer** (défaut réintroduit → rouge → fichier restauré).
3. **`npm test`** — `tests.html` en headless sur **Chromium ET WebKit** (WebKit absent =
   avertissement : `npx playwright install webkit`). Sans npm : `tests.html` **servi en http**,
   jamais en `file://`. ⚠ `tests.html` se lit en octets : toujours `grep -a`.
4. **CSS changé → `npm run design:build` → `git add design/ds`**, et seulement ensuite (facultatif)
   `npm run design:check`. ⚠ Il porte `--strict`, qui fait `git checkout -- design/ds` : joué entre
   le build et le `git add`, il efface la régénération. Vérifier au `git status` que `design/ds` est
   STAGÉ.
5. **`npm run audit`, passe COMPLÈTE** — les **23 harnais** Playwright (liste : `HARNAIS` dans
   `scripts/audit-run.mjs`), en parallèle, rapport agrégé, cache vert par harnais. Pour itérer :
   `npm run audit -- <noms>` (annoncée PARTIELLE), `--grep <motif>` (sections de doctrine et
   partage), `--rouges` (rejoue les seules sections rouges), `--force` (ignore le cache) ;
   `AC_ENGINE=webkit`, `AC_JOBS=n`. Flux : une passe complète de découverte, des sections ciblées
   pendant la correction, UNE passe complète finale — c'est elle qui vaut.

**Écrire ou modifier un harnais** — pièges payés, à ne pas rejouer :
- tout `scripts/audit-*.mjs` figure dans `HARNAIS` (`check-harnais`) ; l'amorçage passe par
  `amorce()`/`ouvrirFiche()`/`demarrerSession()` de `harness.mjs` — une exception se marque sur
  place « PAS `amorce()` ici » avec sa raison ;
- une sonde ouvre par le **vrai point d'entrée** (`openRead(id)`…), elle ne reconstruit jamais
  l'état à la main ; `prep` est une **fonction** (la CSP interdit `eval`) ;
- sur WebKit, le défilement induit par un `focus()` programmatique est asynchrone : **attendre**
  avant de lire une géométrie ; le focus visible se mesure sous de vraies touches Tab ;
- une manœuvre = une section (une propriété nouvelle sur un décor déjà dressé rejoint sa section ;
  autre largeur : `setViewportSize`, pas de rechargement) ;
- sondes jetables à la racine en `.nom.mjs` (gitignorées) ; seuls les harnais qui restent vivent
  dans `scripts/` ;
- patch scripté de SQL : `String.replace()` interprète `$$` dans la chaîne de remplacement —
  passer une **fonction** de remplacement, ou `split().join()`.

**Intégration continue** (`.github/workflows/ci.yml`, chaque push sur `main` et chaque PR) :
`npm run check`, `design-check --strict`, `npm ci`, `npm test` (deux moteurs), puis
`npm run audit` en **non bloquant** (un rouge d'audit demande un arbitrage humain, pas un blocage).

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

## Se repérer dans `index.html` (monofichier, ~33 400 lignes à la v5.57)
Le fichier s'ouvre sur un **grand commentaire d'architecture** (objectif, règles de conception,
modèle de données, règles de sécurité) : le lire en premier. Ensuite, dans l'ordre.

> **Le tableau ci-dessous est un RÉSUMÉ, pas un index** : il décrit une vingtaine de sections sur
> les **79** bannières `/* ===== … ===== */` du fichier, et volontairement sans numéros de ligne —
> ils seraient périmés au commit suivant. Pour l'index EXACT et à jour, une commande :
>
> ```bash
> grep -n '^/\* ===== \|^  /\* ===== ' index.html
> ```
>
> Découpage global (v5.57 — les chiffres glissent à chaque lot, la commande fait foi) : grand
> commentaire d'architecture ≈ lignes 2-276, CSS ≈ 361-8605, coque HTML statique ≈ 8606-9178 (dont
> **~26 fenêtres modales** déclarées en dur — `grep -c 'class="ai-modal' index.html`, auditées par
> `audit-a11y.mjs` —, plus deux surfaces plein écran qui n'en sont pas : `#monMode` et
> `#joinScreen`), JavaScript ≈ 9179 à la fin.

| Section (bannières `/* ===== … ===== */`) | Contenu |
|---|---|
| `<style>` | Tout le CSS (variables dans `:root`, thème sombre via `html[data-theme="dark"]`) |
| Backends | `KV` / `IDB` / `MEM` : trois stockages locaux interchangeables derrière `Data` ; **un espace local par compte** (`currentSpace`/`dbNameFor`/`spaceKey`, bascule par reload à la connexion d'un autre compte, jamais de mélange entre comptes) ; base IndexedDB version 6 (`openSpaceDb`), stores `fiches`, `meta`, `sessions`, `backups`, `attachments` (ArrayBuffer PDF), `protocols`, `attidx` (index de recherche dans les PDF) — un store neuf exige une montée de version, et tout store LU doit exister (`check-stores`) |
| State & Runtime | `state` (quoi afficher ; la bibliothèque affichée est `state.homeLib`, lue par la SOURCE UNIQUE `homeScope()` — `state.scope` est un champ MORT depuis v5.18, cf. A297-A304) ; collections personnelles `colls`/`sanitizeColls` (A475) ; `Runtime` (état vivant du mode crise) ; garde-fous `safeId`/`safeColor`/`safeImg`/`safeAttachment`/`sstr`/`sarr` |
| Modèle | `blankFiche`, `migrate` (point d'entrée sécurité/compat — SEUL lecteur de format, le v4 à pool), pool d'items (`bItems`/`bItemAdd`/`bItemDel`/`bItemMove`), `seed`/`seed2` (les deux aides d'exemple, seul matériel pédagogique livré), catégories |
| Load | `chooseBackend`, `load()` (démarrage), `persist`, `softDelete` |
| Runtime | minuteurs/compteurs/audio (`tickAll`, `beep`), sessions vives (`liveSessions`) |
| Sessions | auto-enregistrement (`persistLive`), reprise, compte-rendu |
| Render | `render()` → `applyViewChrome` (chrome d'en-tête) puis `renderLibrary` (accueil : `renderHomeList` sur la liste UNIE aides + protocoles, le type est un filtre `state.section` — `renderFiches`/`renderProtocols` n'en sont que des enveloppes ; vues Sessions/Moi/Administration de la colonne par `renderHomeTab`) / `renderRead` / `renderEditor` / `renderProtocolRead` / `renderProtocolEdit` (template strings + écouteurs) ; en lecture d'une aide, `overviewSection` (JOURNAL de parcours) et re-rendus ciblés `renderOvOnly`/`renderSvOnly`/`renderTkOnly` (la vue guidée `navSection`/`renderNavOnly` est PURGÉE depuis v5.20.9) |
| Flow SVG | `buildFlowSVG(f,cache)` : organigramme auto — géométrie PURE sans état (v4.7.0) ; l'état de session est PEINT par classes après insertion (`flowPaintState` : `fn-cur`/`fn-ok`/`fn-off`, halo et badge ✓ bakés masqués) et les nœuds sont NAVIGABLES en lecture (`bindSvgNav` → `jumpToBlock` — jamais de cochage dans le SVG, jamais de démarrage de session ; inerte dans l'éditeur) |
| Visionneuse PDF | `pdfLib` (chargement paresseux de `vendor/pdfjs`), `openPdfViewer` (rendu virtualisé par IntersectionObserver ; zoom d'OUVERTURE = « page entière » calculé d'après le ratio du document et la fenêtre, `pdfFitPageZ`, bornes 25–400 %, boutons « Page »/« Largeur », bouton ⤓ Télécharger v4.19.0 : relecture FRAÎCHE du binaire en IndexedDB via `attDlName` — JAMAIS le buffer déjà passé à pdf.js, `getDocument` le TRANSFÈRE à son worker et le laisse détaché, un blob resservi serait vide ; en PWA INSTALLÉE le téléchargement passe par la FEUILLE DE PARTAGE native — v4.19.1, `dlBlob` : en standalone, WebKit ignore `download` et NAVIGUE vers l'URL blob:, plein écran sans retour), fenêtre `#pdfModal` ; miniatures de la 1ʳᵉ page dans les listes « Documents » (`attThumbHtml`/`genAttThumb` : paresseuses, une à la fois, cache mémoire de session — jamais de chargement de pdf.js au démarrage) ; badge « △ à télécharger » si le binaire n'est pas encore sur l'appareil (`hydrateAttThumbs`/`refreshAttRow` — état décidé sur la lecture IndexedDB, rafraîchi en direct par le téléchargement de fond de la synchro) |
| Mini-Markdown | `mdBlocks`/`mdInline`/`mdRender`/`mdStrip`/`mdCells`/`mdCallout`/`mdTask` : parseur maison XSS-safe (esc() d'abord) du contenu rédigé des protocoles — titres, listes, citation, code, image, TABLEAUX (v4.4.2), ENCADRÉS TYPÉS et `==surligné==` (v4.4.3), LISTES COCHABLES `- [ ]` (v4.5.4). Registre et alignement viennent toujours d'un jeu FERMÉ posé en CLASSE, jamais d'un attribut piloté par l'utilisateur |
| Protocoles (« références » à l'écran) | `blankProtocol`/`migrateProtocol` (point d'entrée sécurité/compat), `renderProtocolRead`/`renderProtocolEdit` (éditeur Markdown, A452-A459) ; plus de sélecteur de section dans l'en-tête — la bibliothèque est UNIQUE depuis v5.0.0 (bannière « R4 ») |
| Export / Import | JSON (enveloppe `version: 3` — numéro de l'ENVELOPPE, le contenu est le modèle v4) + conteneur `.zip` « avec documents » (`zipBuild`/`zipParse` maison, `importAtts`) ; règles de rétrocompatibilité documentées sur place |
| Compte & synchro | `Auth` (OTP e-mail), `Sync` (pull/push local-first), fenêtres associées |
| Partage de session | `Share` (sondage REST, cadence adaptative, file hors-ligne, horloge de Cristian), noyau PUR `shareSnap`/`shareDiff`/`shareFold`/`shareCan`, application chirurgicale `SHARE_APPLY`/`sharePaintLive`, décision de démarrage `shareBootDecide` + écran `#joinScreen`, fenêtre d'appariement `#shareModal` et encodeur QR maison ; partage SANS serveur (v5.14) : noyau pur `sl*` (signalisation compacte, trame RPC, `slHub` — l'hôte tient la sémantique serveur), transports en direct (WebRTC) et « par l'écran » (QR optiques, jsQR), état unique du lien `slLink`, porte de parole `slSay`. Le serveur (`supabase/schema.sql`, section « partage de session ») est l'autorité : liste blanche des champs, secret par participant, code consommé, append-only, purge |
| Accessibilité | gestion centralisée des modales (focus, Échap, Tab ; v4.21.0 : verrou du défilement de fond `_bgLock`/`_bgUnlock` + `overscroll-behavior:contain` sur `.ai-modal`, position restaurée au pixel à la dernière fermeture ; **TECHNIQUE CHANGÉE v4.29.9** : le verrou est `overflow:hidden` sur `html` ET `body` (classes posées sur LES DEUX éléments), plus JAMAIS `body{position:fixed;top:-scrollY}` — sur iPhone, un body fixé RÉTRÉCISSAIT le rendu des fenêtres fixées de ~60 px en bas [« bande morte », dossier v4.29.x prouvé à la règle visuelle : accueil sain, fenêtre coupée dès le verrou] sans qu'AUCUNE mesure web ne le voie, et la bande était MASQUÉE depuis v4.23.3 par le fond peint sur html ; ne pas réintroduire de position:fixed sur body). **v4.23.0** : une fenêtre marquée `.sheet-full` (OPAQUE et plein écran, ex. feuille Plan) verrouille le fond à **TOUS les pointeurs** (`body.modal-full`) — la restriction au toucher n'existe que parce que figer `body` au pointeur fin décale le fond visible AUTOUR d'un petit dialogue ; une feuille opaque ne laisse rien voir du fond, et sans verrou la page continue de défiler derrière (constaté sur ordinateur) |
| Prompt IA · Créer | `AI_PROMPT` (le contrat donné à une IA pour produire une aide importable — à faire suivre à TOUT changement de modèle, gardé par `audit-prompt`), dialogue « Créer » (`renderCreateDlg`) |
| Compte · Moi · Administration | `renderAuth*` (fenêtre/vue Moi), `renderAdm` (page Administration, A494), `renderMembers`, `renderNewLib` (« Avec qui ? », demandes de bibliothèque A477-A479) |
| Guide · Prendre en main | `GUIDE_GESTES`, `GLOSSAIRE`, `GUIDE_ETAPES` (exercice guidé, A467) — gardés par `check-guide` et `audit-guide` |
| Retour système | pile réelle d'historique (`_H_LAYERS`, `_histSync`, A430), lien direct `#a=<id>` (`deepLinkFromHash`, A463) |
| Mode test | hook `?__actest` : expose les fonctions pures pour `tests.html` (`__ac_test__`, gardé par `check-actest`) |
