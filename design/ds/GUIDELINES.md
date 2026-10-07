# Aides cognitives — Lignes directrices du design (v5.0, relu v5.51.0)

PWA médicale monofichier, utilisée **en urgence vitale, sous stress** : la clarté et la
robustesse priment sur toute considération esthétique. Tout choix de design se juge à
l'aune d'une question : *est-ce lisible et actionnable par un soignant en crise ?*
La grammaire s'inspire des normes aéronautiques (ECAM/QRH) : état annoncé en texte,
jamais la couleur seule, conditions d'entrée visibles, anti-accident systématique.

## Source de vérité

Les tokens (`tokens/tokens.css`) et le CSS des fiches de ce projet sont **extraits
automatiquement** de `index.html` par `design/build.mjs` — ne jamais les éditer ici.
Toute évolution se fait dans l'app, puis se resynchronise.

**Les fiches du mode crise et de l'accueil sont des CAPTURES du DOM réel** (`design/capture.mjs`,
v5.51.1) : écrites à la main, elles avaient montré pendant des versions des composants purgés. La
fiche Couleurs se construit sur les tokens ACTUELS et `build.mjs` échoue si l'un disparaît.

**Ce fichier-ci fait exception : il est rédigé à la main.** Aucun script ne le régénère,
donc rien ne signale sa péremption — il était resté à la v4.34 pendant vingt et une
versions, dont tout le chantier du partage de session, **puis à la v4.55 pendant tout le
chantier v5** : il a décrit trois surfaces supprimées (le rail ①②③, le mode lecteur, la
bascule Guidé/Statique) jusqu'à ce que l'auteur le demande. À relire à chaque lot qui
touche une surface — c'est la seule protection dont il dispose.

> **RELECTURE v5.51.0 (07/10/2026).** Vingt-deux lots depuis la précédente (v5.30 à v5.51,
> A345-A479). **Faits devenus FAUX, corrigés ci-dessous** — tous du type « surface remplacée » :
> - **les noms de couleur** : `--primary`, `--critical`, `--verify`, `--soft`, `--surface*`,
>   `--input-bg`, `--link`, `--alert-*`, `--rt-*`… sont PURGÉS (A416 : 38 alias purs). Les registres
>   s'écrivent `--act` · `--ok` · `--warn` · `--crit`, les matières `--amb` · `--work` · `--sys` ; et la
>   règle 8 elle-même a été RÉÉCRITE (A406-A408 : rien de permanent n'est rouge) — § Couleur ;
> - **le quai** : quatre touches Fin · Tout voir · Complications · Horodater (A346, A354, A412) ;
>   « ▤ Consulter » a vécu (A367) — § Patterns signés ;
> - **les paliers** : 390 et 924 sont purgés, 1440 est déclaré — § Grille & formes ;
> - **l'Échelle** du plan est purgée (A376) : le parcours n'a plus qu'UN dessin, en trois LIEUX (A388) ;
> - **la barre de sélection** ne se déplie plus sur la ligne (A476) : « Actions » à toutes les largeurs ;
> - **« Tableau »** s'appelle **« Page »** (A461), et « fiche » est banni du texte affiché.
>
> Sections AJOUTÉES : § Contrôles (échelle S·M·L·XL, A375) · § Lexique fermé (A461) · § Ce que fait la
> coche, et quand (A377-A382, A474) · § La revue « à tout moment » (A396, A449) · § Ranger : collections
> et bibliothèques (A475-A479) · § L'exercice guidé (A467). Le détail vit dans `docs/decisions/`.

> **RELECTURE v5.29.4 (13/09/2026).** Dix lots depuis la relecture précédente (v5.20 à v5.29,
> A286-A344). Les sections dont la SURFACE a changé sont réécrites ci-dessous, et **cinq faits
> carrément FAUX** ont été corrigés — aucun n'était visible à la relecture, parce que le fichier
> ne décrivait pas une surface DISPARUE mais une surface REMPLACÉE :
> - **l'échelle typographique** s'est refermée sur SEPT AUTRES crans en v5.6 (§ Typographie) —
>   le fichier donnait encore `19 · 18 · 16,5 · 15,5` et une bande d'affichage séparée ;
> - **la largeur du rail de lecture** est un token unique depuis A310 (§ Grille & formes) ;
> - **`#crisisCtrl` / `#crisisDock`**, encore donnés ici comme l'architecture du mode crise,
>   sont purgés depuis la v5.6 : l'état est monté dans une CAPSULE, les commandes sont
>   descendues dans un DOCK (§ Patterns signés) ;
> - **« police système »** : trois familles sont EMBARQUÉES depuis la v5.6 (§ Typographie) ;
> - **l'échelle des rayons** tient en quatre crans `--r-1..4`, la pilule n'existe plus
>   (§ Grille & formes).
>
> Ce qui a été repris, avec son adresse dans `docs/decisions/` (index : `docs/README.md`) :
> - **Le mode crise** — capsule + dock (refonte v5.6), arrivée du quai (A331, lot v5.26), fin
>   de session au pied du volet et du rail (A336), menu ⋯ qui cesse de répéter le dock (A337).
> - **La Page** — l'ancien « mode statique » n'existe plus : l'arbre EST le fil (A344, lot
>   v5.29), une colonne de largeur A4 dont la colonne des numéros est la surface de dessin.
> - **Le partage** — le sans-serveur (A198-A221, lot v5.14) et tout le chantier « seamless »
>   (A317-A329, A332) : l'app choisit le canal, l'état visible tient en UN mot.
> - **L'accueil** — méta d'une rangée refaite (A338), gestion descendue au pouce (A287),
>   gestionnaire de catégories en liste et palette OKLCH (A308-A316), `homeScope()` (A304).
> - **Les garde-fous** — 24 contrôles `check-*`, 21 harnais d'audit (§ Les garde-fous).

> **RELECTURE v5.19.5 (audit, 31/08/2026).** Les PRINCIPES de ce fichier (couleur, registres,
> typographie, saillance, cascade, garde-fous) restent exacts ; sa nomenclature a été vérifiée
> au grep. QUATRE surfaces décrites ici ont été REFONDUES depuis — pour elles, la vérité vit
> dans `docs/decisions/` (index : `docs/README.md`) :
> - **L'ACCUEIL** (§ ci-dessous, v4.56/v5.0) — refondu au lot v5.18 (A238-A268) : en-tête
>   statique, accès dans `#homeDock`, UNION des bibliothèques, sidebar-filtres ; `home-slim`
>   et les rescues sont PURGÉS. Puis colonne gauche à trois étages et pied unifié au lot
>   v5.19 (A269-A277).
> - **Les barres flottantes** (quai, dock) — matière et périmètre revus au lot v5.15
>   (A222-A224).
> - **La barre de sélection** — refaite planche 20 au lot v5.17 (A227-A230, une ligne de
>   56 px).
> - **Les paliers de largeur** — la chaîne de compression de la rangée d'ÉDITEUR passe par
>   les classes `html.zw640/430/360`, plus par des media queries (v5.19.5, règle 10).

## Couleur — sémantique FIXE

- **Aucune couleur hex hors DÉCLARATION DE TOKEN** (propriété `--…`, où qu'elle vive :
  `:root`, thème sombre, blocs `data-accent`) et `PALETTE` (13 teintes de catégories).
  La règle n'est plus déclarative : `scripts/check-colors.mjs` la fait respecter à chaque
  commit. Seule exception listée, les nuanciers littéraux `.acc-sw` — et l'exemption
  porte sur la **règle**, pas sur la ligne (un hex collé en fin de ligne était admis, il
  ne l'est plus).
- **LES REGISTRES NE SE MÉLANGENT PAS** (règle 8, RÉÉCRITE en v5.38, A406-A408) :
  - **rouge `--crit`** = ce qui TUE si on l'oublie (le mot CRITIQUE) et l'**alarme active** — **rien
    de permanent n'est rouge** ; bords `--crit-line`, fonds `--crit-soft` ;
  - **ambre `--warn`** = là où l'on risque de SE TROMPER (dose, dilution, seuil) et l'ÉCHÉANCE
    (minuteur échu) ; bords `--warn-line`, fonds `--warn-soft`, alarme de minuteur `--alarm-bd` ;
  - **vert `--ok`** = fait, ou système nominal (« ● SESSION ») ; `--ok-rgb` en est la version
    décomposée (le pouls) ;
  - **bleu `--act`** = l'action et le bloc courant ; fonds `--primary-soft`, survol `--primary-100`.
  Ce qui tourne normalement et ne demande rien n'a PAS de couleur (poste de pilotage sombre). Une
  catégorie n'est jamais plus proche d'un registre que deux catégories entre elles (A408 — le
  vermillon de la palette est retiré). « Terminer ? » est NEUTRE, l'étape vitale rouge (A409).
- **TROIS MATIÈRES** : `--amb` (ambiance, le fond) · `--work` (travail — cartes, feuilles,
  champs ; bord `--work-line`) · `--sys` (système — quai, capsule, toasts : `--sys-ink`,
  `--sys-line`, et les registres déclinés `--ok-sys` · `--warn-sys` · `--crit-sys`). `--amb-2`
  porte les pistes de segmenté et les fonds neutres ; `--paper` est la Page.
- **TROIS ROUGES distincts, jamais fusionnés** : `--crit` = texte, mot CRITIQUE, alarme ;
  `--crit-line` = bords ; le rouge d'une CATÉGORIE de la palette = liseré/pastille, jamais un signal.
- `--ink-3` = **décoratif seulement** (jamais une couleur de texte) ; texte secondaire = `--ink-2`
  (4.5:1). Bordures de champs et cases = `--line-strong` ; **contour de composant = `--ctl-line`**,
  seul token qui tienne 3:1 dans les deux thèmes (A67) — une case de choix multiple le prend.
- Les **toasts** sont en matière SYSTÈME (`--sys`/`--sys-ink`), comme le quai.
- Statuts éditoriaux **achromatiques** : pilule `.status-tag` unique (△ À relire,
  ○ Brouillon, △ À revérifier — `--amb-2`/`--ink-2`). **« ✓ Validé(e) » ne s'affiche
  PAS là où la DATE de validation est visible** : la date dit la même chose en plus
  précis, et une carte ne porte un statut que si elle ATTEND quelque chose. Sans date, la
  pastille reste — sinon rien ne distinguerait une fiche validée d'une fiche sans statut.
  Sur les cartes d'accueil, la pilule de catégorie est NEUTRE : la couleur de catégorie
  ne vit que dans le liseré. Les badges d'attente sont ACHROMATIQUES — seul « À revérifier » est
  ambre (A347) ; l'état d'une carte est au palier méta 12, gras s'il attend quelque chose (A422).
- Pastilles d'état (compte/synchro) : ok = `--ok`, attente = `--warn`,
  erreur = `--crit`, inactif = `--line-strong`, synchro EN COURS = anneau tournant
  (activité ≠ alerte).
- Fond des champs de saisie = `--amb-2` (A350), partout.
- Contraste : texte ≥ 4.5:1, composants ≥ 3:1 (WCAG 2.2 AA), dans les DEUX thèmes.
- La couleur n'est **jamais le seul canal** : toujours texte, forme ou position en plus.
- **Modes de contraste système.** Sous `forced-colors` (Windows High Contrast) : filet
  MINIMAL — `.acct-dot`, `.cat-dot` et `.seg-pill` gardent leur couleur
  (`forced-color-adjust:none` : l'information EST la couleur) ; le reste s'appuie sur
  « la couleur jamais seule ». Sous `prefers-contrast: more`, `--ink-soft` passe à
  `--ink` et `--line` à `--line-strong` — **bloc déclaré en FIN de feuille** : à
  spécificité égale il doit gagner sur les tokens des deux thèmes.

## Couleur d'accent par utilisateur (v4.5 — CONFINÉE À L'AVATAR en v5.0.0)

5 accents prédéfinis AA (sarcelle, violet, indigo, framboise, ardoise) + bleu clinique par
défaut. **Connecté seulement** (l'accent tombe à la déconnexion). Jamais de vert/ambre/rouge
en accent : les registres sémantiques sont réservés.

**La PORTÉE a changé, pas la fonction.** L'accent teintait l'accueil ENTIER et l'en-tête de
toutes les vues : c'était **la seule couleur du produit qui ne portait aucun sens**, dans un
système dont la règle fondatrice est que la couleur en porte toujours un — et **70 hex sur
104**. Il est désormais réduit au **DISQUE de l'avatar**, où il en porte un : « cette fenêtre
appartient au compte X ». La reconnaissance périphérique est conservée (un disque coloré à
position constante, ce qui est le vrai besoin sur un ordinateur PARTAGÉ), la concurrence avec
les registres disparaît partout ailleurs, et la palette d'accent tombe à **10 hex** — un
token `--accent` par accent et par thème, une seule règle qui le consomme.

Le **logo de marque** (accueil seulement) est posé en **masque CSS** sur un aplat de
`currentColor`, donc l'ENCRE : il suit le thème tout seul et ne concurrence rien.

## Typographie

- **TROIS FAMILLES EMBARQUÉES** (refonte v5.6), donc identiques hors ligne et d'un appareil à
  l'autre : `--f-ui` (Manrope) pour l'interface, `--f-mono` (IBM Plex Mono, tabular-nums) pour
  les valeurs qui DÉFILENT — chronos, compteurs, numéros d'étape — et les codes courts,
  `--f-title` (Source Serif 4) pour la marque. Chacune a sa pile de repli système déclarée, et
  les anciens noms (`--sans`, `--mono`, `--serif`) y pointent. ⚠ Ce n'est plus « police
  système », comme ce fichier l'a écrit jusqu'à la v5.29.4 — et une `font-family` posée en
  clair est SILENCIEUSE : `check-fonts.mjs` l'interdit.
- **Les sept crans sont des TOKENS, jamais des nombres** : `--t-cap` 11 · `--t-meta` 12 ·
  `--t-body` 13,5 · `--t-item` 15 · `--t-step` 17,5 · `--t-step-l` 21 · `--t-val` 24. Le nom
  dit l'EMPLOI — l'étape courante est `--t-step`, l'étape critique `--t-step-l`.
- **ÉCHELLE FERMÉE — sept paliers, UNE SEULE BANDE** (refonte v5.6, A6) :
  `24 · 21 · 17,5 · 15 · 13,5 · 12 · 11`. ⚠ **Ce n'est plus l'échelle `19 · 18 · 16,5 · 15,5`
  décrite ici jusqu'à la v5.29.4**, ni la bande d'AFFICHAGE séparée (`20 · 24 · 26 · 34 · 40`)
  qui la coiffait : le grand corps appartient désormais à l'ACTE et non au chrono — l'étape
  courante monte à 17,5 px et l'étape critique à 21, là où un chrono trônait à 40 pendant
  qu'une étape vitale plafonnait à 15,5. 24 px reste, comme cran haut des VALEURS mono
  (`--t-val`, chrono d'alarme du volet). La feuille portait
  **seize** corps entre 10 et 19 px : deux textes à 13 et 13,5 px ne se lisent pas comme deux
  NIVEAUX, ils se lisent comme une inattention. `scripts/check-type.mjs` la fait respecter ;
  toute exemption est **nommée par son sélecteur et motivée** dans le script.
- **Plancher : 11 px** pour tout texte courant. ⚠ **ET UN QUOTA, depuis la v5.0.0** : un
  plancher employé **173 fois sur ~520 déclarations** n'est plus un plancher, c'est le corps
  de texte du produit — chaque déclaration était pourtant légale, donc rien ne pouvait le
  voir. `check-type` porte un CLIQUET (`PLANCHER_MAX`) posé au niveau atteint : la valeur ne
  peut que descendre. Il mesure des DÉCLARATIONS, pas des éléments à l'écran — il empêche la
  dérive de s'aggraver, il ne prouve pas qu'elle a cessé. **Le cliquet est à 177 (v5.29.4), et
  il a REMONTÉ**, ce que la règle interdit — chaque fois contre un ÉCHANGE écrit sur place :
  les étiquettes des touches du dock, l'intitulé « ▤ Consulter », l'en-tête de la carte de bloc.
  Du chrome REMPLACÉ, jamais ajouté, dans la refonte qui fait justement monter l'étape courante
  à 17,5 px. Une remontée sans échange écrit est un échec.
- **Deux valeurs de SERVICE qui ne sont pas des paliers** : `16` (plancher des champs sur
  écran tactile, contrainte du moteur) et `14` (l'un des quatre « A » du sélecteur de taille,
  dont l'écart de corps EST l'information).
- **Un seul registre de titres de section** : petites capitales grasses (`.block-h`),
  repris par les titres du contenu rédigé (`.md-h1`/`.md-h2`). Pas de nouveau style de titre.
- Le contenu (15–16 px) reste plus grand que ses titres de section.
- **Champs ≥ 16 px sur écran tactile** : sous 16 px, Safari iOS zoome la page au focus et
  les taps se perdent. Un compact < 16 px n'est admis qu'au pointeur fin.

## Saillance

- **Un seul bouton rempli** (`--act` plein) par écran. Si deux actions coexistent,
  la moins critique passe en tonal (`--primary-soft`) ou au contour.
- Grammaire des boutons de gestion : **pointillé** = créer, **contour** = gérer /
  secondaire, **plein** = action primaire.
- En lecture, les actions secondaires vivent dans le **menu ⋯** : rangées de hauteur
  PRÉVISIBLE (44 px, 52 avec sous-titre), intertitres, ouvertures en TUILES, action
  destructrice DERNIÈRE. **UN dessin de menu** (`menuRowHtml`, A361) : feuille BASSE sous 780 px,
  menu ancré au-delà — plus de pied encadré ; les sous-feuilles portent « ‹ Actions » (A366). **Ordre = logique ECAM
  E/WD → SD** : la conduite EN COURS d'abord, puis le cycle de vie de la session, puis la
  gestion, puis les exports. **Jamais deux entrées d'un même menu avec le même dessin**, ni
  deux dessins quasi identiques côte à côte.
- **EN SESSION, LE MENU NE RÉPÈTE PAS LE DOCK** (A337, lot v5.28) : Complications et Consulter
  en SORTENT — ils sont à deux touches au pouce, et une double entrée fait hésiter sur laquelle
  fait quoi (c'est la double entrée de la v4.26.1, reprise à l'envers). Ce qui décrit l'aide se
  replie derrière « L'aide › ». Mesuré : **14 rangées → 7** pendant le soin.
- En crise, le chrome s'efface : **aucune notification flottante qui ARRIVE**. La règle
  « une seule zone fixe, en haut, jamais en bas » a été LEVÉE en v5.6, et il faut le dire —
  elle visait les notifications, pas une surface de commandes stable : l'état vit en haut
  (capsule), les commandes en bas (dock), sous le pouce (§ Patterns signés).

## Interaction

- Cible tactile ≥ 32 px ; **≥ 44 px pour les contrôles du mode crise**. Quand le
  contrôle visuel est plus petit (36–40 px), halo cliquable en `::after`.
- **ÉCHELLE FERMÉE DES CONTRÔLES** (A375) : **S 32 · M 40 · L 44 · XL 56**, rangées de menu **52** —
  le chrome est à 40 partout (18 hauteurs de bouton mesurées avant, 6 après). « Bigger is not
  better » : la carte d'accueil du téléphone est à 15/700, pas plus.
- Tout élément interactif : `:focus-visible` (outline 2 px `--act`) + équivalent
  clavier (Entrée/Espace). Le focus ne doit **jamais être masqué par une couche
  collante** (WCAG 2.2 § 2.4.11) : le défilement induit par le focus est celui du
  NAVIGATEUR, il ne se pilote que par `scroll-padding-top`.
- **DANS UNE FENÊTRE, LE PIÈGE À TABULATION DÉPLACE LUI-MÊME LE FOCUS** (A313) : WebKit saute
  les boutons par défaut et l'ordre natif SORTAIT de la fenêtre. Il pose aussi l'anneau à la
  main — `:focus-visible` ne s'allume pas sur un focus programmatique ouvert à la souris
  (A237), et un état juste mais invisible ne vaut rien. **Le halo est réservé aux boutons ; un
  champ s'allume par sa BORDURE.** Le focus d'ouverture va sur l'ACTION, jamais sur la croix.
- **Un halo de cible se vérifie en CAPTURE, pas en géométrie** (A278) : `elementFromPoint` au
  centre et aux quatre coins. Un `::after` de 44 px peut être parfaitement dimensionné et ne
  rien recevoir — c'est ce qui rendait deux survols inertes pendant des versions.
- Action destructrice en crise = geste **« maintenir »** (jauge qui se remplit ; « Terminer »
  se maintient 1,2 s, et le dit DANS le bouton — A346, A460), jamais un simple tap ; la réinitialisation d'un minuteur ANNONCE ce qu'elle
  redonnera (« ↺ 05:00 »).
- **Garde temporelle 700 ms** (`.guarded`, opacité réduite) entre deux boutons
  « retour » empilés — un double-tap ne doit jamais franchir deux niveaux (ECAM). La
  même garde couvre le retour SYSTÈME (geste Android), qui emprunte le chemin de
  l'affordance visible plutôt qu'un routage parallèle.
- Un bouton désactivé n'est jamais muet : il DIT pourquoi et combien il reste
  (« Cochez les étapes restantes (2) ») ; actif, il ANNONCE sa destination
  (« Continuer — réévaluation à 5 min → »).
- Les éditeurs s'auto-enregistrent (brouillon « fantôme » restaurable) : « ‹ Retour »
  remplace « Annuler ».
- **Un sélecteur segmenté se GLISSE** : la pastille se laisse traîner au doigt (seuil
  6 px, commit au relâchement seulement). Elle suit le doigt même sous
  `prefers-reduced-motion` — une manipulation directe EST le geste, pas un mouvement
  autonome ; seul le rattrapage final passe par la transition.
- **La graisse ne change pas avec l'état** dans un segmenté : 800 contre 700 élargit le
  mot et décale les DEUX libellés à chaque bascule. L'état est porté par la pastille et
  la couleur.
- Tous les contrôles portent `touch-action:manipulation` (supprime le délai double-tap
  de Safari iOS).

## Grille & formes

- **320 px est SERVI** (v4.43.0) — c'est le plancher de WCAG 1.4.10 « Reflow », et donc
  la largeur à laquelle toute nouvelle addition au chrome se mesure. Deux surfaces y
  rognaient en silence avant qu'on ne le décide. On rend les pixels par la **recette des
  écarts et rembourrages**, jamais par un renommage ni une seconde ligne.
- **Paliers — ÉCHELLE FERMÉE ET AUTO-EXÉCUTOIRE depuis la v5.0.0** :
  **360 · 400 · 430 · 480 · 560 · 640 · 780 · 1000 · 1200 · 1440** (dix, mesurés par
  `scripts/check-paliers.mjs` à chaque commit — ajouter un palier exige de l'écrire ICI et dans le
  script). ⚠ **390 et 924 sont PURGÉS** (A461 : les pastilles de l'accueil portent leur mot sous
  780 ; A367 : la feuille Consulter, seule lectrice de 924, a vécu). **1440** = le bureau large :
  la capsule de session monte dans l'en-tête (A354). 780 = colonne gauche de l'accueil et rail de
  lecture ; 1000 = rail à 320 et aperçu des éditeurs ; 1200 = cockpit (trois colonnes).
  ⚠ **Un palier de COMPOSITION n'est pas une media query** (règle 10) : sous zoom de texte, il passe
  par les classes `html.zw…` posées par `syncZoomWidth()` (largeur ÷ zoom).
- Largeurs par vue : accueil = colonne gauche + **UNE colonne d'au plus 960 px** à toutes les
  largeurs (A389 ; coque FIXE ≥ 780 : seuls la colonne et le contenu défilent) ; fiche ≤ 860 px + **rail de lecture dès
  780 px**, dont la largeur est un TOKEN UNIQUE `--col-state` — **280 px de 780 à 999, 320 px
  ≥ 1000** (A310 : le dock flottant lit le même token ; quand la valeur avait été recopiée en
  littéral, il s'arrêtait 42 px avant la colonne). Au-delà de **1200**, une TROISIÈME colonne
  d'orientation (`--col-orient`, 240 px) : plan | checklist | état. Protocole ≤ 780 px.
- **Les éditeurs ne sont PAS alignés sur leur vue de lecture** — cette ligne l'affirmait,
  c'était faux et mesuré tel quel (1400 px rend 900 + 320, jamais 860 + 360). L'éditeur
  de FICHE est une colonne d'édition **fluide** (1fr) + aperçu sticky 320 px dès 1000 px ;
  seul l'éditeur de PROTOCOLE est plafonné (780 + 360). Aligner l'un sur l'autre serait un
  changement visible, à décider séparément.
- **Deux seuils distincts, à ne jamais refusionner** : 780 = rail de LECTURE ;
  1000 = aperçu en direct des ÉDITEURS.
- **Rayons — ÉCHELLE FERMÉE À QUATRE CRANS** (v5.6) : `--r-1` 8 · `--r-2` 10 · `--r-3` 12 ·
  `--r-4` 14 px (cartes `--r-4`, boutons et champs `--r-3` ; les anciens alias `--radius*` sont
  purgés, A416). **La pilule n'existe pas** : `999` ne
  survit que pour les chips de filtre, où la pilule EST la forme du composant, et `3` pour les
  plus petits contrôles. Il y avait **dix-neuf valeurs distinctes pour trois tokens** ;
  `scripts/check-radius.mjs` ferme la liste (`3 · 8 · 10 · 12 · 14 · 999`).
- **Espacement — ÉCHELLE FERMÉE** (v5.0.0) : `0 · 1 · 2 · 4 · 6 · 8 · 10 · 12 · 14 · 16 ·
  18 · 20 · 24 · 28 · 32 · 40 · 48 · 56 · 64 · 72 · 96` px. C'était la **moitié ouverte** du
  design system — 1 356 déclarations, aucun token, aucun garde-fou. L'échelle a été choisie
  sur la distribution RÉELLE : la migration n'a déplacé aucune valeur de plus d'1 px, ce qui
  la rend vérifiable par les harnais existants (cibles de 44, rangées de 71, budgets d'écran)
  plutôt que par relecture. `scripts/check-space.mjs`.
- **DEUX MATIÈRES DE FENÊTRE** (A352) : les DESTINATIONS (Moi, Sessions…) sont des page-fenêtres
  (`.ai-modal.page`, fond d'ambiance, cartes ; form-sheet dès 780) ; les DIALOGUES sont des cartes
  blanches. ≥ 780 px, Sessions et Moi sont des VUES de la colonne de l'accueil (A365).
- Fenêtres : gabarit unique `dlg-480` (480 px, titre 17/800, croix 44 px) ; plein écran
  < 640 px SAUF les confirmations `dlg-confirm` (420 px, toujours centrées) ; la ZONE
  SENSIBLE est séparée par un filet et vient en dernier.
- **Feuilles plein écran** (`.sheet-full` : Se repérer — « Consulter » a vécu, A367) : rembourrage haut nul,
  leur barre de titre étant collante et devant affleurer le bord. L'exclusion se fait sur
  la CLASSE, jamais sur les fenêtres nommément — la prochaine feuille en hérite.
- **Tout overlay défilable** reçoit une hauteur bornée au viewport VISIBLE
  (`--vvh`, repli `calc(100dvh / var(--zf,1))`) : un `inset:0` se dimensionne sur le grand
  viewport iOS et sa fin devient inatteignable derrière la barre d'outils.
- **Toute hauteur relative à la fenêtre s'écrit `calc(100dvh / var(--zf,1))`** : le réglage
  de taille du texte est un `zoom` sur `<html>`, un `vh` nu se fait agrandir par lui.

## Débordement — abréger, enrouler, ou annoncer

Trois réponses, et le choix se déduit de ce que coûte l'information cachée :

- **Une zone d'ÉTAT abrège et ANNONCE.** Le quai retire un segment, qui repasse dans le
  « +n » — jamais un chiffre, jamais le « +n » lui-même. Elle n'ampute jamais un NOMBRE
  (`fmtMs` passe en `h:mm:ss` au-delà de l'heure) ; un MOT, oui.
- **Une STRUCTURE enroule.** Dans le plan, une branche cachée est une branche qu'on ne
  saura pas prendre : une rangée de branches du parcours passe à la ligne plutôt que de
  tronquer ses renvois (réponse, flèche et « · » forment une unité insécable, A448). La place existe verticalement — l'argument du quai ne s'y transpose pas.
- **Une COMMANDE ne se tronque pas** : la croix d'un panneau s'ancre en haut à droite et
  le reste s'enroule dessous, plutôt que de la pousser hors écran.
- Abréger, quand il le faut, c'est **tronquer le MÊME mot** (« Cons. »), jamais en choisir
  un autre : deux noms pour un bouton, « on s'y perd ».

## Patterns signés

- **Barre d'en-tête claire** (couleur du fond) : la couleur d'identité se retire dans
  les accents ; en lecture le titre remplace la marque, et le « ‹ » porte le TITRE de la
  fiche d'origine quand on est arrivé par un lien (pile de retour, plafond 8).
- **LE MODE CRISE A DEUX OBJETS : une CAPSULE d'état en haut, un DOCK de commandes au pouce**
  (refonte v5.6, lot 2). ⚠ Ceci REMPLACE les « deux rangées collantes » `#crisisCtrl` /
  `#crisisDock` (v4.25.0) décrites ici jusqu'à la v5.29.4 — la rangée de commandes est purgée
  depuis la v5.6, et `check-ids` a trouvé trois lecteurs fantômes qui la cherchaient encore.
  L'ESPRIT de la v4.25.0 est conservé — commandes ≠ état, c'est l'architecture ECP/ECAM d'un
  Airbus — mais sa FORME est inversée : l'état MONTE dans la capsule (matière système, jamais
  occultée), les commandes DESCENDENT sous le pouce. Mesuré : chrome haut **175 → ~112 px** à
  390 px, trois `border-bottom` empilés en moins.
  - **« Chrome bas proscrit » a été rouverte FRONTALEMENT**, et la règle visait autre chose :
    les NOTIFICATIONS FLOTTANTES (règle 11), pas une surface de commandes STABLE. Trois risques
    nommés et traités au code : zone sûre iOS, clavier virtuel (le dock s'efface au focus d'un
    champ — le clavier EST la surface de saisie) et 320 px (touches au glyphe seul,
    `aria-label` conservé).
  - **Quatre touches de largeur égale, à position CONSTANTE** (A346, A354, A412) : **Fin · Tout
    voir · Complications · Horodater**. **« Horodater » est la seule touche REMPLIE** — le geste
    le plus fréquent d'une réanimation, le seul qui ÉCRIVE sans rien ouvrir. **« Fin »** porte le
    ■ au rouge système (`--crit-sys`), son mot au gris : elle ouvre la fenêtre dont la confirmation
    se MAINTIENT 1,2 s. « ▤ Consulter » a quitté le quai (A354) puis vécu (A367 : ses portes mènent
    à la carte de la page). Filets entre les touches (A355). Sous 360 px effectifs les mots restent,
    sur deux lignes à 12 px, jamais coupés (A465). Hors session : « Démarrer » REMPLI, « Exercice »
    en pointillé ; les deux jeux ne coexistent jamais. Règle du ⚡ : une seule complication → son
    NOM, plusieurs → « Complications · n » — un nombre n'est jamais nu.
  - **Les volets montent du dock sur GESTE, jamais spontanément** : fermeture triple (re-tap de
    la touche, ✕ ≥ 44 px, tap hors volet), hauteur plafonnée à **~45 % de la fenêtre** — jamais
    plein écran, le contexte reste lisible au-dessus. L'alarme reste TOUJOURS en vue, la
    capsule étant en HAUT et les volets en BAS (règle FMA de l'ECAM). L'occultation COMMANDÉE
    est conforme ECAM/QRH ; ce que la doctrine interdit est l'occultation NON commandée.
  - **Dans la capsule, l'ordre des segments est FIXE, les constants AVANT la partie variable**
    (les minuteurs) : un contrôle placé après un nombre variable de segments ne peut rester
    immobile qu'ancré au bord (vide central) ou avec des créneaux vides (trou). La constance
    positionnelle est la règle cardinale d'une zone d'état. Au **bureau large** (≥ 1440 px, A354),
    la capsule monte DANS l'en-tête : même contenu, même ordre. Elle accueille deux compteurs au
    nom entier, jamais ellipsé, et le rappel dit « +n » (A462, A473).
  - **Le bandeau de crise reste BLANC** : un aplat rouge permanent désensibilise au rouge. Le
    statut s'annonce en TEXTE (« ■ Mode crise »). Il porte en outre l'étape ① du partage,
    COMPRESSÉE (A327-A328) — jamais une seconde pilule.
  - **LA FIN DE SESSION EST UNE TOUCHE DU QUAI** (A346, qui remplace la rangée d'A336 au pied
    du volet et du rail — A356 l'en retire) : UN SEUL bouton permanent, la fenêtre reste la seule
    porte, aucun rappel.
- **Une bascule de mode est un SÉLECTEUR SEGMENTÉ, jamais un interrupteur** : deux modes PAIRS
  (« Un bloc » / « Tout voir » à l'ouverture, Tout · Aides · Protocoles…) — aucun n'est la négation
  de l'autre. Une seule pastille glissante, piste `--amb-2`, pastille blanche (A350). Un bouton d'état
  y serait ambigu — dit-il où je suis ou où je vais ? — et l'erreur coûterait le
  remplacement de toute la vue de travail en pleine réanimation.
- **Aucun contrôle ne vit dans le quai.** Il réécrit son `innerHTML` une fois par seconde :
  un tap sur un élément vivant y est AVALÉ dans 13 % des cas, mesuré, sur les deux
  moteurs. Les commandes vivent dans la colonne d'ACTION et au menu ⋯.
- **Cartes minuteur** : l'état change le TEXTE de l'étiquette (« — en pause »,
  « ■ … — à réévaluer »), barre 4 px du temps restant qui SE VIDE, échu = ambre + glyphe
  `△` en PRÉFIXE (il survit à l'ellipse) + étiquette lecteur d'écran. Minuteurs AD HOC en
  rangées compactes (ajoutés en session sans modifier la fiche).
- **Condition d'entrée** (QRH) : la « Confirmation diagnostique » est VISIBLE hors
  session, repliée en session — jamais supprimée, et jamais repliée par un démarrage
  IMPLICITE.
- **Notes personnelles** : carte en pointillés (registre « annotation informelle »,
  distinct du contenu clinique validé). Actions d'ajout = bordures pointillées.
- **Toast** : non bloquant, matière système (`--sys`/`--sys-ink`), barre de vie. **En session de crise, ce
  qui ARRIVE est mis en attente ; ce qui RÉPOND à un bouton pressé s'affiche** (v4.55.4).
  La distinction est explicite dans l'appel, jamais déduite d'une proximité temporelle
  avec un clic — une nouvelle de fond tombant dans la seconde suivant un tap serait alors
  affichée par accident, exactement ce que la règle interdit.
- **Le « non protégé » est NEUTRE** : un état PERMANENT en ambre s'use et émousse l'ambre
  des états réellement actionnables. L'ambre est réservé à « presque plein » et aux
  documents manquants.

## L'ACCUEIL — une bibliothèque unique, le type n'est qu'un filtre (v4.56.0 / v5.0.0)

C'est le premier écran, et il n'avait aucune section ici jusqu'à la v5.

**Le TYPE a cessé d'être une navigation.** Choisir « Aides » ou « Protocoles » était une
DÉCISION PRÉALABLE : il fallait savoir de quel type était ce qu'on cherchait avant de pouvoir
le chercher. Or le type est une propriété de l'AUTEUR (« ai-je écrit une checklist ou un
document ? »), pas du lecteur, qui cherche un SUJET. Le répertoire A→Z réunit donc les deux,
et le type devient un filtre à trois crans — **« Tout » par défaut** —, c'est-à-dire quelque
chose qu'on applique APRÈS avoir vu, jamais avant. **Ordre du rail de filtres : Bibliothèque,
Type, Catégorie** — du plus large au plus étroit ; on choisit d'abord OÙ l'on cherche.

**Trois étages** : tuiles **épinglées ★** (les favoris SEULS — jamais de remplissage par
fréquence d'usage), **répertoire A→Z**, **rail alphabétique** (tap = saut, glisser = parcours ;
il DISPARAÎT s'il ne tient pas en hauteur — jamais de lettres coupées). En recherche : liste
plate triée par pertinence, avec extraits contextuels.

**Le PAS de la rangée est régulier, sa hauteur ne l'est pas** — le défaut d'origine n'était pas
le style mais la hauteur VARIABLE (52 à 86 px mesurés selon le repli des pilules) : un annuaire
sans pas régulier ne se parcourt pas. Mais une hauteur FIXE clippait l'extrait de recherche en
plein milieu d'une ligne. La rangée est donc bornée PAR LE BAS et jamais figée : **60 px** dans
la liste éditoriale, **71** en recherche (l'extrait s'ajoute), **76** sous 360 px effectifs, où
la méta prend deux lignes.

**La méta dit UNE IDENTITÉ à gauche et UN ÉTAT à droite** (A338, lot v5.28) — et cet ordre-là
n'est plus celui d'une queue qui tombe :

- à gauche, l'**identité** : nature · discriminant · ● catégorie, alignés sur la LIGNE DE BASE
  (nature 11 px, texte 12 px) ;
- à droite, **un seul état, en MOTS**, le plus urgent l'emportant :
  *En cours* (chrono vivant) › *Brouillon* › *À relire* › *À compléter* › *Sans date* ›
  *À revérifier* › *Validée + date*. **Sans glyphe, sans point, sans mono** : l'ambre y signifie
  « cela attend quelque chose de VOUS », rien d'autre.
- ce qui s'abrège est **la catégorie, puis le discriminant — jamais la nature, jamais l'état**.
  Sous 360 px effectifs, identité et état ne tiennent pas sur une ligne (mesuré : 268 px pour
  208) : l'état passe SOUS l'identité, sur TOUTES les rangées — jamais sur certaines seulement.

La méta reste du **texte séparé par des points, jamais une suite de chips** : une chip a une
largeur incompressible et se coupe net, un texte s'ellipse proprement.

**« Session en cours » cumule trois canaux à coût nul** : liseré au registre CONFIRMATION,
teinte de rangée, et la DATE qui cède la place au **chrono vivant** (une place déjà prise —
une date de validation n'apprend rien pendant qu'une session tourne). Peint sur place par le
tick, jamais par un re-rendu : reconstruire l'annuaire chaque seconde détruirait le nœud sous
le doigt.

**LA REFONTE v5.30 (A347-A353, A389)** : plus d'intertitre « Répertoire » — une ligne de COMPTE
(« 12 aides · 4 protocoles · 9 à relire ») porte « Affichage » et « Sélectionner » ; UNE colonne
d'au plus 960 px à toutes les largeurs ; « Détaillée » = cartes (76 px au téléphone), « Compacte » =
liste à filets, sur UNE ligne au bureau. **La feuille « Affichage »** (bouton rond à gauche de la
recherche, A353) a deux sections encadrées : **Filtrer** (Afficher · Mes collections · Bibliothèque ·
Catégorie, compte et « Tout effacer » à son titre) et **Présenter** (Trier · Regrouper · Densité,
A429). Les filtres posés deviennent des **PUCES retirables** sous la ligne de compte (A428). Au
téléphone, recherche et filtre FLOTTENT, opaques, sur un bord doux (A423). En-tête : Sessions · Créer
· Moi, pastilles de 40 px portant leur mot dessous sous 780 (A461). Les rangements PERSONNELS
(collections) ont leur section : § Ranger.

**L'ÉTAT VIDE ENSEIGNE, et c'est le seul écran qui le puisse** (v5.0.0). Depuis que l'accueil
mêle les deux types, la NATURE écrite sur chaque rangée les nomme sans les expliquer — le
produit ne dit nulle part ailleurs ce qui distingue une aide d'un protocole. Le vide est le
seul moment où l'on a la place ET l'attention pour le faire. Le nombre de cartes est
exactement le nombre de types créables dans la vue courante (les deux en « Tout »), et le
bouton d'une carte ouvre la création de SON type. Même composant, même anatomie pour les
deux — elles sont côte à côte pour être COMPARÉES ; le verbe est le seul mot en encre pleine
(« se **déroule** » / « se **lit** ») et deux lignes se répondent avec le même glyphe : la
répétition EST la comparaison. **La leçon disparaît sous un filtre** : qui cherche sait déjà
ce qu'est une aide, on lui doit un résultat et pas un cours.

**Les filtres se replient tant qu'aucun n'est posé** : ~90 px permanents au premier écran pour
un geste qu'on ne fait jamais sous stress. Mais **un état actif ne se cache JAMAIS** — dès
qu'un filtre est posé, les rangées sont rendues en permanence et le déclencheur disparaît ;
un filtre caché serait bien pire que trois rangées permanentes.

**LA GESTION** : la colonne gauche (≥ 780) porte « Gérer » pour les bibliothèques (vers Moi ›
Bibliothèques, A389 — plus de ✎ par rangée ni de « Nouvelle bibliothèque » dans la colonne) et pour
les catégories ; en dessous, la feuille Affichage y mène (A287 amendé).

**Le gestionnaire de catégories est une LISTE** (A308-A316, lot v5.22) : rangées de 44 px,
« Ajouter » en tête, **une seule palette ouverte à la fois**, repliée derrière un bouton
« palette » quand la couleur est un preset. Les couleurs se choisissent sur un anneau **OKLCH
L 0,48 · C 0,08** — la chroma maximale tenable dans le gamut, où les deux contrastes tiennent
par construction, avec un garde-fou de proximité de 4,0 ΔE ; l'anneau est ANCRÉ sur les presets
(écart nul aux treize degrés), un degré ne rendant jamais deux couleurs. Sur « Toutes », une
BANDE COLLANTE par bibliothèque reprend le dessin d'une rangée d'accueil.

**Une seule source dit OÙ l'on est** : `homeScope()` (A304). Le champ `state.scope` est MORT à
l'accueil depuis la refonte v5.18 — sept de ses lecteurs ont survécu et disaient faux (une
commande « Sélectionner » morte, une destination qui vidait la liste). Corollaire de méthode :
**rendre VARIABLE une condition jusque-là constante oblige à re-vérifier qui la rejoue** — le
bouton de création restait périmé au tap de la colonne.

## Les placards — exercice, invité (v4.27.0 / v4.55.4)

Un placard dit **dans quel régime on est**, à l'endroit le plus lu de l'écran. Deux
existent, ils partagent le même mécanisme au trait près : hachure sur un `::before` en
**fondu d'opacité** (~300 ms), portée par le bandeau-titre tant qu'il est visible, puis
relayée par l'EN-TÊTE au pixel où le titre passe dessous, enfants en `z-index:1`.
**Coût nul en hauteur** — seule condition qui vaille là où la rangée de commandes n'a que
2,1 px de marge à 320 px.

- **Exercice** — « ▲ Exercice », hachure `--work`/`--primary-soft`, pilule BLEUE
  pointillée. Ni rouge ni ambre : ce n'est pas une alerte, c'est le placard TRAINING de
  l'aviation. Le « ● Session » vert reste réservé au réel.
- **Invité** — « ▪ Vous suivez » / « ▪ Suivi » en relais, hachure BLEUE. Il lisait
  « ■ Mode crise », exactement ce que lit l'hôte, alors que sa situation est autre : il
  SUIT une session qu'il ne conduit pas et qui peut s'arrêter sans lui.
- **L'EXERCICE GARDE LA PRIORITÉ**, non négociable : « ceci est une répétition » prime sur
  « vous suivez » — le premier protège d'une méprise clinique, le second est une
  information de rôle que le quai porte en permanence de toute façon.
- **Ce qu'on ne hachure pas** : le QUAI. Il a été essayé et annulé (« immonde ») — des
  chiffres n'ont pas à vivre sur une texture.

## Parcours de soin — des ÉTAGES, plus un rail numéroté (v4.4.0, refondu en v5.0.0)

La vue lecture est structurée par trois étages titrés (`.care-flat` / `.cf-stage`) :
**Confirmer le diagnostic** → **Prise en charge** → **Surveillances & pièges**, puis les
annexes (journal, galerie, documents, note).

- **Le rail vertical numéroté ①②③ (`.care-path`) N'EXISTE PLUS** (lot M2a). Les numéros
  vivent désormais sur les **BLOCS**, et deux numérotations concurrentes dans la même
  colonne sont deux vocabulaires pour situer un même geste — ce qu'AC 120-71B proscrit.
  Celle des blocs reste parce qu'elle est COMMUNE au journal, au plan, au tableau et au
  schéma (`flowPlan().order`) ; le rail ne parlait qu'à lui-même.
- **En session, l'ACTION passe devant l'ORIENTATION** (lot T5). Un rail numérote un
  parcours : il oriente qui DÉCOUVRE la fiche, c'est-à-dire exactement ce dont on n'a plus
  besoin quand on exécute. Mesuré à 320 × 640 avant correction : la première étape cochable
  naissait à **y = 721 px pour un pli à 640** — zéro étape à l'écran au démarrage du soin.
  Une fois la session démarrée, la suite verticale est donc réécrite (action d'abord, ce qui
  est fait ensuite, ce qui suivra en dernier) ; **hors session rien ne bouge**, car avant
  d'agir on s'oriente (condition d'entrée QRH).
- La séquence est **SUGGÉRÉE, jamais bloquante** : la 1ʳᵉ action démarre la session, où
  qu'elle soit.
- « Ne pas oublier » est une **CARTE DÉPLIABLE** (`foldCardHtml`, une seule fabrique avant et
  pendant la session — A357/A358) : avant la session elle se lit sur l'écran de démarrage ;
  **pendant, elle vit SOUS le bloc courant, en tête des cartes** (A351 — l'ancien chapeau au-dessus
  de la séquence est retourné). Les cartes de session sont fermées d'office AVANT la session (A366)
  et annoncent leur compte ; le registre et le mot restent, seule la surface se replie.

## L'écran de démarrage d'une aide (A330, lot v5.25)

Avant la session, l'écran d'entrée se lit comme un **écran de démarrage**, pas comme une fiche
en réduction : **trois chapitres de même niveau, SANS numéro** — « ■ Quand l'utiliser »,
« ■ Ne pas oublier », « Parcours » —, dont les intitulés SORTENT de leurs cadres (un titre
enfermé dans sa carte se lit comme une étiquette, pas comme un chapitre).

- **L'aperçu du plan est À PLAT** : ni carte, ni « 0/4 », ni « ICI ». Rien n'a commencé —
  afficher un compteur à zéro ou une position, c'est annoncer un état qui n'existe pas.
- **Rien ne démarre tant qu'on consulte**, et le rail « En session » le dit : les minuteurs y
  sont « à lancer ». Seul le chrono de session part au démarrage.
- Sur-titre « Avant la session », Tableau et Schéma à largeur de CONTENU sous le titre, queue
  sous filet. Les formes REFUSÉES par l'auteur sont listées dans le lot — ne pas les
  reproposer.

**IL RESTE UN GESTE APRÈS AVOIR OUVERT UNE CARTE, ET LE QUAI LE DIT** (A331, lot v5.26) : à
l'arrivée sur une fiche, la capsule se relève UNE FOIS, puis trois anneaux s'en éloignent —
**fini à 4,8 s**, sous les 5 s de WCAG 2.2.2, et **jamais de boucle**. L'anneau entoure la
CAPSULE, jamais le bouton seul. Tant qu'aucune session n'a été démarrée sur l'appareil, une
bulle d'apprentissage vit 16 px au-dessus du dock — statique, donc hors 2.2.2 — puis plus
jamais. Formes refusées : fondu en boucle, onde débordante, anneau DANS le bouton, marque
rouge sur le bouton.

## Le rail de LECTURE, dès 780 px (v4.23.0)

Action et orientation de front — l'idéal ECAM (E/WD et SD simultanés). De haut en bas :
minuteurs épinglés → repères posologiques → parcours (bloc courant seul déplié, A381/A388) →
horodatage.

- **Une colonne ENTIÈREMENT CONTINUE, aucun sous-défileur.** Trois essais ont échoué avant
  celui-là : un défileur unique enterrait la posologie ; trois zones bornées faisaient de
  chacune un HUBLOT ; une seule zone bornée a fait **disparaître** le compteur et le bouton
  « ＋ Minuteur PA » (327 px affichés pour 413 de contenu, barre de défilement invisible au
  repos). **Dans une colonne déjà défilante, un sous-conteneur borné ne range pas, il
  ESCAMOTE.** Le seul dispositif retenu est l'ORDRE : ce qui est de longueur ILLIMITÉE en
  DERNIER.
- **Chaque en-tête de zone annonce son TOTAL** (`.rail-n`) : sans ce compte, une zone
  tronquée paraît complète — ce que l'ECAM interdit.
- **Chrome désaturé, registre CONSERVÉ** : le rail oriente, la colonne agit. Les repères
  ordinaires sont des LIGNES ; un repère signalé garde sa carte teintée. La DOSE reste en
  encre pleine — la hiérarchie passe par la GRAISSE, jamais par l'encre.
- **Un repère posologique est AMBRE, jamais rouge** : c'est une RÉFÉRENCE, pas un geste.
  Trois masses rouges d'égale valeur à l'écran faisaient perdre leur prééminence aux
  memory items. Une seule masse rouge par écran.

## L'axe de DENSITÉ — « Un bloc » / « Toute la fiche » (v5.0.0, lots T8 et A)

La bascule ne demande plus d'arbitrer entre deux PRÉSENTATIONS (« Guidé » / « Statique ») —
un choix qu'aucun néophyte, et aucun expert sous stress, ne devrait avoir à faire. Elle
nomme une **densité** : combien de la fiche on veut voir.

- **Un bloc** — le journal chronologique : ce que je fais, maintenant.
- **Tout voir** — un conteneur à **deux onglets** : **Page** (l'aide entière sur une feuille de
  largeur A4, l'arbre tracé dans la colonne des numéros — § La Page) et **Schéma** (le SVG
  navigable, avec son zoom et son plein écran). L'onglet « Parcours » a vécu (A389) : il redisait
  « Se repérer ». **Un nom et une icône par vue** (A461) : Tout voir · Page · Schéma · Se repérer ·
  Moniteur.
  ⚠ **La Page n'a qu'UN axe vertical** (A343) : la fenêtre qui la porte défilait elle-même en
  plus du document, sur les deux moteurs. Le défileur du SCHÉMA, lui, garde le sien — il a un
  contenu plus large que l'écran, ce que la Page n'a jamais.

**Le sélecteur segmenté `#modeSeg` a été SUPPRIMÉ**, et c'est le cœur de la décision : un
segmenté **remplace la vue de travail et ne ramène personne**. On prend du recul, on trouve
son information, et si l'on n'y repense pas on **termine le soin dans un format qu'on n'avait
pas choisi** — de la mode confusion au sens FAA. Le contrôle **nomme sa destination, jamais
son état** : « ⤢ Tout voir » à l'aller, « ↩ Un bloc » au retour, à la **même position**
(0 px de déplacement mesuré), avec le registre CONFIRMATION au retour. C'est le patron de
l'excursion sur complication : le retour fait partie du dispositif, jamais de la mémoire.

**Une excursion n'écrit pas la préférence** — regarder n'est pas régler. Le format par défaut
se choisit **à froid**, dans Compte › Affichage. Corollaire : le vert du retour n'apparaît que
si l'on n'est PAS dans son format d'ouverture — l'afficher en permanence à quelqu'un qui n'est
parti nulle part viderait le vert de son sens, l'inflation même qu'on reproche au rouge.

**Chercher DANS l'aide pendant le soin** (lot B) : la feuille « Toute la fiche » porte le
composant de recherche de la lecture de référence. Elle **ne filtre pas** — elle surligne et
saute : masquer laisserait croire que le reste n'existe pas. Jamais sur le Schéma, dont les
textes vivent dans un SVG où un `<mark>` n'est pas un nœud valide.

## Journal de parcours & fil condensé (v4.9.0 / v4.16.0 — modèle ECAM)

**Doctrine fondatrice (leçon v4.6→v4.9)** : ne JAMAIS poser un état temporel sur une carte
spatiale — un bloc parcouru plusieurs fois y perd l'utilisateur. La chronologie EST la
structure : chaque passage est une **carte POSTÉE à la suite**, rien ne mute au-dessus, on
lit toujours vers le bas. Pas de curseur : la position est le BOUT.

Trois présentations par passage, calculées par une fonction pure :

1. **carte dépliée** — le bout, et tout passage incomplet ;
2. **ligne d'état** relisible — un passage complet récent ;
3. **chip** — n° + titre abrégé + ✓, ou n° + « › réponse » **en toutes lettres** pour une
   décision (le numéro seul ne parle pas à un humain).

**Invariants** : le BOUT est toujours une carte ; un passage **INCOMPLET n'est JAMAIS une
chip** (c'est ce qui fait la conformité) ; une rangée de plus de 4 chips se replie en
**ligne-bilan ECL** (« ✓ n passages · a→b ») — modèle Boeing : une checklist terminée se
referme en un statut d'une ligne. Le repli manuel PERSISTE ; le dépliage est une
**consultation transitoire**, effacée au geste de navigation suivant.

Changer d'avis ne réécrit jamais le passé : c'est un **nouveau passage** en bout de journal.

**Le journal des actions ANNULE, il ne supprime pas** (v4.49.0) : le `×` barre la ligne et
la conserve, et devient `↺` pour se raviser. Deux règles l'imposaient déjà — un geste
destructeur en crise se fait en « maintenant », et la correction d'heure est non
destructive depuis toujours. Le « maintenir » a été envisagé puis écarté : il protège du
geste accidentel mais laisse la perte définitive, et ne dit rien à celui qui relit. Or le
journal alimente le compte-rendu : une trace qu'un tap efface sans laisser de marque n'est
pas une trace. **L'heure reste en encre pleine** — c'est la donnée clinique.

## Plan de l'aide (v4.10.0 / v4.12.0 / v4.18.0 / v4.25.0)

Sous le journal, la **structure complète** façon algorithme papier / checklist
conditionnelle QRH. Le tronc reprend au point de convergence, une cible déjà décrite
devient « ↺ reprendre à n » (les BOUCLES deviennent lisibles), chaque bloc n'apparaît
qu'UNE fois. Sa numérotation est **COMMUNE** à toutes les vues (journal, chips, statique).

- **Le plan est IMMUABLE et INERTE côté cochage** (leçon v4.6, re-confirmée v4.12) :
  jamais de cases — la trace vit dans le journal. Il porte un état LÉGER (✓, ● ici, ×n)
  et sert à **NAVIGUER**.
- **LE PARCOURS N'A PLUS QU'UN DESSIN** (A376 — l'Échelle est PURGÉE, avec ses 65 règles) :
  `preFlowFlatHtml` rend la carte d'entrée, la feuille « Se repérer », la colonne du cockpit et le
  rail, avec l'état de session. **Trois LIEUX** fixent densité et repli, jamais la session (A388) :
  la colonne naît REPLIÉE (titre seul, « Tout déplier »), carte et feuille dépliées. Les réglages de
  coche s'écrivent EN MOTS (« Si seuil : », « toutes les 4 min », « +1 Chocs délivrés »). **Le
  parcours SUIT L'ARBRE, borné à deux crans** (A450) : chaque réponse ouvre SA branche sous elle,
  « SI réponse » à l'ambre des réponses ; au-delà, à plat et « à ◇n ».
- **Le fil d'ancêtres sticky est mort avec elle** — il n'existait que pour ses cartes-questions, et
  l'Échelle n'a pas d'ancêtres à épingler. Son idée SURVIT ailleurs et en mieux : en mode STATIQUE
  sur petit écran (v4.32.0), les bandes-questions RÉELLES s'épinglent, chaque niveau imbriqué se
  rangeant sous son ancêtre, avec le même z-ordre décroissant (modèle ECL : une sous-procédure
  terminée se referme dans sa procédure mère). Différence décisive : une seule mesure par rendu au
  lieu d'un recalcul à chaque événement de défilement — la hauteur n'est pas forcée, car compacter
  à une ligne tronquerait une question longue, et la question EST l'information.
- **Registre jamais masqué par un état** : un bloc de DÉCISION garde sa bordure ambre même
  quand il est le bloc courant. La POSITION est portée, elle, par la pilule « VOUS ÊTES
  ICI » — un canal par signification.
- **La numérotation vient de `flowPlan`, et elle numérote LE TRONC D'ABORD** (A344) : les
  arêtes de retour sortent de la post-dominance, une convergence est le post-dominateur commun
  à DEUX options au moins, et les sorties se chaînent APRÈS le tronc. Elle est COMMUNE au
  journal, au Parcours, à la Page et au Schéma — c'est ce qui autorise « ↺ reprendre à n ».
- *(Historique — le token est parti avec l'Échelle en A376 ; le parcours indente ses branches à
  deux crans au plus, A450. La leçon reste.)* **LE RETRAIT DE PROFONDEUR ÉTAIT UN TOKEN ADDITIF** (`--pl-ind` : 12 · 24 · 32, A339) ajouté à
  la gouttière de CHAQUE régime, jamais une échelle absolue. Quatre échelles absolues
  coexistaient et chaque régime les effaçait par un raccourci `padding` plus spécifique :
  étiquettes de branche toutes au même x avant le soin, **toutes les rangées à 10 px en
  session — un arbre plat**, et les trois retraits de l'aperçu n'avaient JAMAIS rien fait. Le
  témoin qui gardait l'alignement était vert PARCE QUE tout était à plat : il ne comparait pas
  les niveaux ENTRE EUX.

## La Page — l'arbre EST le fil (A344, lot v5.29)

Toute l'aide sur **une feuille de largeur A4 (740 px)**, référence en pied. Elle remplace le
« mode statique » en cellules carrelées décrit ici jusqu'à la v5.29.4 : mesuré avant, une aide
à quinze blocs faisait **2 432 px de large** à 1130 px de fenêtre, ajustée à 32 % sur un
téléphone — corps de 3,5 px, c'est-à-dire illisible. Après : 740 × 2 992, et **48 % à 390 px**.

- **Le NUMÉRO est l'ancre de tout trait** : une entrée arrive par le haut, un retour par la
  gauche. La **colonne des numéros EST la surface de dessin** — tronc plein, fourche = barre +
  descentes, rail à équerres au-delà de deux branches. Tronc, fourche et rail sont en CSS à
  géométrie locale, **sans aucune mesure** ; seules les voies se mesurent.
- **Une sortie s'ÉCRIT avant de se tracer** : « SI … ALLER À n », puis un pointillé par la voie
  de droite. La ligne écrite est la vérité ; le trait la confirme.
- **La destination est une PASTILLE encadrée** — « CONTINUER ↓ 4 » au registre de la décision
  (ambre plein), « ALLER À 7 » / « REVENIR À 2 » au registre des voies (bleu pointillé). Elle
  donne au trait un bord d'où partir : **une sortie part du bord de la PASTILLE, un retour du
  bord de la BOÎTE** (depuis la pastille, il barrait le libellé de sa propre ligne).
- **UN BUS, PAS N TRAITS SUPERPOSÉS** : trois décisions qui sortent vers le même bloc
  descendent dans UN couloir (615 px l'un sur l'autre, mesurés, avant correction) ; les lignes
  le rejoignent par un tiret. Registre de couloirs partagé — une abscisse prise glisse de 5 px.
- **Un trait ne croise jamais rien**, et ce n'est pas une intention : la sonde d'audit compare
  chaque segment du calque à chaque cellule des deux fiches réelles, et le compte doit être
  ZÉRO. ⚠ Sa première écriture était AVEUGLE (recouvrement sur deux axes pour un segment
  d'épaisseur nulle) ; corrigée, vérifiée capable d'échouer, elle a trouvé deux vrais défauts.
- **Cellules façon ECAM** : case · libellé · points de conduite · réponse mono à droite, ou
  dessous quand la largeur manque. « ▪ FIN » est un mot dans le bloc terminal, jamais un
  symbole isolé au milieu de la feuille.
- **INERTE côté cochage**, comme le plan : l'état de session y est PEINT en lecture seule.
  Taper une cellule = y aller ; jamais de démarrage de session, jamais de défilement sous le
  doigt (flash d'acquittement).
- **AUCUN texte bleu dans les cellules** : le bleu ne marque QUE la position (● ici) et la
  reprise ↺. La réponse attendue est une pilule mono **neutre**.

**À l'impression, la feuille EST la page** (210 mm, rembourrage calculé pour garder la largeur
d'auteur au pixel près — sinon reflux, et les voies mesurées désignent le mauvais bloc). Les
marges horizontales ne viennent pas de `@page`, qu'un moteur peut ignorer en ajoutant les
siennes puis en réduisant la feuille. **« Exporter en PDF » imprime LA PAGE**, jamais la vue
d'ensemble d'une session en cours (le gestionnaire `beforeprint` la forçait depuis la v4.18.0 :
on imprimait le journal du soin en croyant imprimer l'aide).

**Le paginateur MESURE, donc il connaît ses sauts** : hauteur utile mesurée par un témoin en
millimètres, blocs insécables dans l'ordre du flux, saut posé avant celui qui déborderait — et
les chemins, écrits en POINTS, sont **coupés aux frontières et décalés** : un trait sort en bas
d'une page et reprend en haut de la suivante, à la bonne cellule. Il **renonce et le dit** si un
bloc dépasse une page entière ; un intitulé de branche ne finit jamais une page seul.

## Listes d'étapes — un corps, une colonne, le danger en MOT (A345, A11 rouvert)

- **Toutes les étapes d'une liste partagent le même corps** (17,5 en session, 15 en lecture) et la
  même colonne : rangées de 64 px sur `--amb-2`, case de 36 px, sans numéro (on coche dans
  n'importe quel ordre).
- **Le danger est un MOT, pas un glyphe** : étiquette **CRITIQUE** (`--crit`) ou **VIGILANCE**
  (`--warn`) au-dessus du libellé (dans le parcours : calée à DROITE de la première ligne, sans
  aplat — A388), plus la bordure de case au registre et un texte `.sr-only`. ⚠ **Les glyphes ⚠/△
  d'avant ont vécu** — `stepMarkHtml` est l'unique fabrique (rangée et aperçu à plat).
- Sous l'étape, en gris : la réponse attendue (« challenge :: réponse »), et la **LÉGENDE** de ce
  que fait la coche (§ Ce que fait la coche).
- Étape COCHÉE = aplatie ; une étape signalée cochée garde son mot, cadre vert doux.

## Challenge-response (v4.11.0 — FAA Order 8900.1 Vol. 3 Ch. 32 §3-3403.A)

**Correction de source, vérifiée sur le texte primaire** : « Do-Verify » et
« Challenge-Do-Verify » ne figurent NULLE PART dans l'AC 120-71B — ils viennent de
l'AC 120-71A (2003), que la révision B ANNULE, et n'y sont que des INTITULÉS d'une liste de
sujets. La méthode se cite par l'Order 8900.1 ; la répartition à deux, par l'AC 120-71B
§5.2.2.1. La pratique ne change pas d'un pixel — seule la référence était fausse.

Trois briques, **aucun champ ajouté au modèle** (l'export reste inchangé, un ancien client
reste lisible) :

1. **« challenge :: réponse »** — séparateur explicite DANS la chaîne d'étape (même
   philosophie opt-in que ⚠/△). Rendu en pilule mono : la **réponse attendue**.
2. **Mode Vérification** — la passe redéroule TOUTES les étapes, déjà cochées comprises.
   « Constaté ✓ » coche ; « △ Écart » avance **sans cocher** et ne **DÉCOCHE JAMAIS** (la
   coche est la trace). **Retour immédiat** : le résultat s'affiche dès qu'il est prononcé,
   pas en fin de bloc — la boucle est challenge → réponse → CONFIRMATION.
3. **~~Mode lecteur~~ — SURFACE RETIRÉE (v5.0.0, lot T14).** L'overlay plein écran « un
   challenge à la fois » ne gagnait qu'à **320 px** (63 % de l'écran aux étapes contre 36 %)
   et **perdait à 390** (47 % contre 59 %) : son propre chrome coûtait plus qu'il ne rendait.
   Sa justification s'était d'ailleurs érodée dans sa propre doctrine — la v4.28.0 avait
   abandonné le un-item-à-la-fois (ECL Boeing = liste entière + curseur ; perdre sa place est
   un mode de défaillance premier), et la v4.62.0 avait unifié structure et verbes. Il ne
   restait qu'une coquille. Le cas qui le motivait le mieux (McEvoy 2014 : 99,5 % contre 70 %,
   un lecteur tenant l'UNIQUE appareil) se résout en **tendant le téléphone**, ce que la carte
   de bloc sert déjà ; le binôme à deux appareils est servi par le partage de session.

**La trace de vérification est un état DISTINCT du cochage** : une étape cochée à
l'exécution doit rester discernable d'une étape CONSTATÉE par observation — c'est
précisément ce que la seconde passe existe pour produire. **Même libellé pendant et après
la passe**, celui du GESTE (« constaté ») : deux mots pour un même état, c'est ce que
l'AC 120-71B proscrit. **Aucun bandeau ambre sur l'étape en écart** : le liseré est le canal
du REGISTRE, l'écart est un ÉTAT DE LA PASSE — la pilule, mot + glyphe, suffit.

**Garde-fou télégraphique** non bloquant : un bloc > 7 étapes ou un challenge > 110
caractères est signalé à la rédaction — une checklist ne se lit pas en paragraphes.

## Lexique fermé du texte affiché (A461)

Trois mots, jamais d'autres : **aide** (un parcours à cocher), **protocole** (un texte à lire),
**données** (les deux, pour le compte, la synchro, le stockage). **« Fiche » est BANNI de la prose
affichée** — `check-lexique.mjs` le refuse (le prompt de rédaction IA est exempté). Le code et la
doctrine gardent leurs anciens noms (`fiches`, `openRead`) : ce sont des identifiants, pas du texte
lu. Un nom et une icône par vue : Tout voir · Page · Schéma · Se repérer · Moniteur ; `expand` est
réservé à « Plein écran ».

## Ce que fait la coche, et quand (A377-A382, A440, A474)

- **La coche peut AGIR** : lancer un minuteur (`item.starts`), compter (`item.counts`), et un bloc
  peut minuter à chaque ENTRÉE par un geste de conduite (`block.timer`). Les effets ne naissent que
  d'un GESTE (jamais à la réception d'un état partagé) ; décocher les annule, et un minuteur relancé
  revient à son état d'avant pendant 10 s.
- **Une LÉGENDE d'une ligne** sous l'étape (24 px réservés dans tous les états) dit l'effet, valeur
  d'abord : grise au repos, bleue SANS FOND en cours, pastille ambre à l'échéance. Un compteur qui
  relance un minuteur réserve DEUX lignes (A440).
- **Ne pas anticiper** (A379) : un délai qui court depuis un geste repart à la coche de ce geste,
  jamais à la sonnerie ; il reste « Échu » entre les deux.
- **Le MOMENT d'une étape** dans un bloc parcouru plusieurs fois (A382, A474) : à partir d'un seuil
  de compteur, ou à l'échéance d'un minuteur. Avant son moment, l'étape reste visible, sa case
  ESTOMPÉE, et sa jauge vit DANS l'étiquette du seuil (« CHOCS DÉLIVRÉS ≥ 3 ●○□ ») ; « Faire
  maintenant » au bout de la rangée ; jamais elle ne retient « Continuer ».
- Micro-mouvements (A378) : cocher fait MONTER le chiffre ou REMPLIR l'anneau, décocher fait
  redescendre ; rien sous mouvement réduit.

## La revue « à tout moment » (A396, A449)

Un bloc `review` hors tronc, posé dans le fil par une ÉTAPE-REVUE : sa grille se déplie DANS sa
boîte, une revue par session, faite d'elle-même à n/n, jamais de « Continuer » retenu. Elle se
DESSINE sans un mot (A449) : fermée d'office, contour pointillé, **JAUGE de n segments** au lieu
d'une case, ligne k/n neutre ; ouverte, des JETONS à coche à droite dont le libellé ne bouge pas.
La **bande des repères** du bloc (`item.poso`) dit « fait · à faire · à préparer », venus de la
coche — jamais d'un état de minuteur.

## Ranger : collections et bibliothèques (A475-A479, A483-A484)

**Une bibliothèque, c'est AVEC QUI ; une collection, c'est POUR MOI.** Aucune phrase ne le dit
telle quelle — chaque écran le dit à sa façon :

- **La collection** est une liste nommée d'aides et de protocoles venus de n'importe quelle
  bibliothèque, **même en lecture seule** — sans copie, une aide pouvant être dans plusieurs.
  Personnelle, synchronisée sur les appareils du compte, invisible des autres. **L'Accès direct
  est la première** (les épingles ★, inchangées). Icône : le **SIGNET** (`bookmark`), jamais le
  livre de la bibliothèque.
- **Le CONTRÔLE dit « plusieurs »** : « Ajouter à une collection… » ouvre des CASES (vide · tiret
  « une partie » · coche, contour `--ctl-line`), la feuille reste ouverte, chaque case agit
  aussitôt ; « Déplacer vers une bibliothèque… » est un choix UNIQUE et dit « change qui y a accès ».
- **Le VERBE** : Déplacer (bibliothèque) · Ranger (catégorie, commune aux lecteurs) · Ajouter à
  (collection) · **Retirer** de la collection — jamais « Supprimer » une aide depuis une collection.
- **La PLACE** : au téléphone, une rangée « Mes collections · à vous seul » sous l'Accès direct
  (absente tant qu'il n'y en a aucune) ; au bureau, une section de la colonne gauche ; une famille
  de la feuille Affichage ; une zone de Moi. Une collection ouverte a un EN-TÊTE « COLLECTION · À
  VOUS SEUL », son compte, « venus de k bibliothèques — rien n'a été déplacé », et ses gestes
  (Ajouter des aides · ⋯ Renommer, Retirer les indisponibles, Supprimer). « aussi dans … » sous une
  rangée, seulement dans une collection ouverte.
- **La preuve par le geste** : au menu ⋯ d'une aide en lecture seule, « Modifier » est grisé et
  « Ajouter à une collection… » juste dessous reste actif.
- **Créer une bibliothèque demande d'abord « Avec qui ? »** (A477) ; sans invité, la fenêtre
  propose une collection. Le droit de créer est une règle d'instance (administrateurs · personnes
  autorisées · tout compte approuvé, A478) ; les autres DEMANDENT par la même fenêtre (A479).
- **L'administrateur de l'instance voit tout** (A483), dans Moi › Administration et sans fenêtre
  neuve : « Comptes · n » (une rangée par compte, qui se DÉPLIE sur place — statut et son geste,
  droit de créer, rôle par bibliothèque) et « Bibliothèques de l'instance · n » (la rangée ouvre
  la fenêtre Membres, qui gère aussi une bibliothèque dont l'administrateur n'est pas membre et le
  dit en tête, A484). Un champ « Filtrer… » au-delà de 8 rangées.
- **La barre de sélection** est UNE ligne de 56 px à toutes les largeurs : case maîtresse à trois
  états, compte, « Actions » qui ouvre la feuille (Ajouter à une collection · Déplacer · Ranger ·
  Exporter · Supprimer), sortie en croix. Cinq libellés entiers ne tiennent jamais dans 960 px :
  le dépliage sur la ligne a vécu (A476) — **un libellé ne se réduit jamais à son glyphe**.

## L'exercice guidé (A467)

En EXERCICE seulement (règle 11) : une bulle par geste sur la VRAIE commande — démarrer, cocher,
capsule, continuer et répondre, revue, complication puis « Reprendre », horodater, terminer
maintenu. On avance par le geste fait (lu dans l'état) ; tout le reste s'estompe sous UN voile
percé autour de la cible. La bulle est une CARTE ANCRÉE au-dessus du quai, dans sa largeur (colonne
d'action au bureau, un côté de la charnière sur un pliable), immobile au défilement. **Le guide suit
l'app** : `check-guide` et `audit-guide` rougissent si un geste change sans lui.

## Partage de session en direct (v4.46.0 → v5.26, A198-A221 et A317-A332)

Une session de crise se remplit à plusieurs : l'hôte partage, un invité rejoint par code
ou QR, **sans avoir installé l'app**. C'est le premier chantier qui fait sortir une
session de l'appareil.

**IL PEUT SE PASSER DE SERVEUR** (A198-A221, lot v5.14) : quand le cloud est injoignable, la
session voyage en direct entre deux appareils du même réseau, ou **PAR L'ÉCRAN** — des QR
affichés et lus d'un téléphone à l'autre, décodés par une bibliothèque vendorisée. C'est la
deuxième exception à la règle zéro-dépendance du projet, et elle a été prise comme telle. Ce
qui ne change pas d'un pixel : le format transmis. Un secours optique ne transporte pas plus
que le cloud.

**Règle fondatrice : le partage est un miroir ADDITIF, jamais une dépendance.** Aucun
chemin d'interface n'attend un appel réseau — ni au tap, ni au rendu, ni à la fin de
session. Couper le réseau ne change, sur l'écran de l'hôte, **qu'un mot dans le quai**.

**Aucun texte libre ne traverse le réseau.** Un repère de journal voyage comme une
**référence** ({bloc, index} · minuteur · compteur · étiquette du noyau), jamais comme un
mot ; chaque appareil rend le libellé depuis SA copie. Le vocabulaire personnel (avec
alias : « mru », « regul », « dbase ») s'édite **à froid**, dans la fenêtre Compte — on ne
rédige pas son vocabulaire en réanimation. Le filet qui rend ce vocabulaire non critique :
le geste primaire reste **« Noter l'heure »**, un tap, qui pose un repère SANS étiquette.
L'heure — ce qui compte cliniquement — est capturée toujours.

**Ce que l'invité peut faire** (v4.55.0, après une objection d'usage qui a renversé la
conception) : cocher, constater, écart, incrémenter, **armer ET arrêter** un minuteur,
poser un repère, **AVANCER, choisir une branche, terminer un bloc**, entrer sur une
complication. **Ce qui reste au lead** : décocher, remettre à zéro, terminer le partage,
dater le début du soin. Le critère est celui que le dépôt avait déjà écrit pour
l'annulation d'un repère — **annuler CONSERVE, décocher DÉTRUIT** : naviguer est
append-only, arrêter un minuteur conserve son temps écoulé.
*Pourquoi ce renversement :* la conception initiale bridait le scribe au motif que « celui
qui lit ne décide pas ». C'était une mauvaise lecture — l'AC 120-71B §5.2.2.1 décrit une
répartition de LA PAROLE, et dans ce modèle c'est **celui qui lit qui fait avancer la
liste**, le lead étant celui dont les mains sont prises. Le lecteur (« lire et
GUIDER »), l'ECAM (le pilot monitoring actionne l'ECP) et surtout McEvoy 2014 — 99,5 %
contre 70 %, où **le lecteur tenait l'unique appareil** — convergent.

**Sur l'ambiguïté « qui fait quoi »** (§5.5, qu'Airbus supprime en n'ayant qu'un seul ECP),
la réponse constante du projet : **on n'interdit pas, on ANNONCE** — une avance venue d'en
face pose « avancé par ‹rôle› » sur la carte courante, à côté de « Vous êtes ici ».

### Le canal se choisit TOUT SEUL, et il se DIT (A317-A329, lots v5.23-v5.24)

Demande de l'auteur : « le maître mot c'est seamless ». Le transport a donc cessé d'être une
question posée à l'utilisateur — mais il n'est jamais devenu invisible pour autant.

- **UN SEUL ÉTAT VISIBLE : « ● Partagé »**, quel que soit le canal. Le transport se lit dans la
  feuille et aux transitions, pas dans la zone d'état — un soignant n'a pas à savoir par quel
  tuyau passe sa session.
- **L'app décide** : serveur joignable → en ligne ; serveur muet + adresse locale → en direct ;
  sinon PAR L'ÉCRAN d'office (QR). Plus de sélecteur en tête de feuille, mais une **ligne
  d'état (mode + raison)** et des **étapes NUMÉROTÉES dont le bouton EST l'étape** (hôte
  ① Montrer ② Recevoir ; invité ① Recevoir ② Renvoyer ; ③ refaire). La porte de secours est
  nommée : « Mode : automatique › ».
- **Une panne se détecte en moins de 5 s** (la sonde tranche au premier raté) et **la transition
  se VOIT** : un mot de 8 s au quai, par une PORTE UNIQUE (`slSay`) — jamais deux chemins qui
  annoncent le même fait. Les cinq dernières transitions sont horodatées dans un **journal du
  lien**, en mémoire seulement, montré dans les deux feuilles.
- **Le retour en ligne se fait SEUL** après une panne (trois sondes OK, ≥ 60 s en direct, feuille
  fermée, invités à ramener) — **jamais contre un choix manuel**. Au réveil, un hôte aux canaux
  morts revient seul si le retour est armé ; sinon il lit « ● Lien à refaire ».
- **« Connexion perdue » est un ÉTAT, pas un silence** (A324-A325) : une source unique, une
  rangée ambre de 41 px dans le quai collant, quatre gestes nommés (Recevoir · Renvoyer ·
  Montrer la progression · Se reconnecter) et un « ⓘ Pourquoi ». L'hôte comme l'invité
  retrouvent leur session après un rechargement, par un billet de reprise.
- **Ce que la panne fait aux GESTES** (A332) : l'arrêt d'un minuteur est daté à l'heure de
  l'ÉVÈNEMENT chez l'autre, jamais à l'heure de la charge ; l'hôte n'est jamais refusé pour
  péremption (sa coche, faite lien figé, était perdue) ; et le bridage d'un invité périmé **se
  VOIT et se DIT**. Un invité que plus rien n'atteint lit « △ Hôte silencieux · ① Recevoir » —
  l'absence de nouvelles est une information, pas un écran qui ment.

**LA PASSATION DE LA MAIN EST BORNÉE** (A302) : le rôle ne borne QUE le fil. Les droits de
PROPRIÉTÉ — arrêter, couper, rouvrir, réécrire un rôle — ne se transfèrent jamais, et l'hôte
n'est jamais bridé sur son propre écran. « Reprendre la main » existe comme PORTE : un
mécanisme sans porte est un piège.

### Ce que le partage n'a PAS le droit de faire à l'écran

Ces contraintes ont été **mesurées** avant d'être écrites ; ce sont elles qui ont dessiné
les surfaces.

- **Aucun `render()` sur événement distant.** Application chirurgicale seule ; les verbes
  qui re-rendent sont mis en FILE et appliqués au prochain geste **local** de navigation.
- **Rien ne mute au-dessus** : la condensation du fil ne se recalcule jamais sur un
  événement distant.
- **Aucun contrôle dans le quai** (13 % de taps avalés, cf. Patterns signés).
- **Aucun segment `⇄` supplémentaire** : son insertion déplace le segment d'ALARME de 45 à
  57 px selon la largeur, à l'apparition ET à la disparition, **sur événement distant** —
  exactement ce que la constance positionnelle interdit. Le compte de participants devient
  un jeton du libellé de chrono, ou n'existe pas.
- **Jetons FERMÉS et courts** dans le libellé du chrono, jamais de prose : `main`, `suit`,
  `⇄n`, `figé`, `coupé`, `fini`, `seul` — 8 caractères au plus. Mesuré à 320 px : « · main »
  passe (42 px), « · vous conduisez » déborde de 15 px. **Le lien REMPLACE la main** quand
  il n'est plus nominal : ce n'est pas une économie de place, c'est que le rôle et le
  compte ne sont alors PLUS CONNUS — les afficher serait de la donnée périmée présentée
  comme vivante (danger n° 2 du palmarès ECRI 2015). Le vert `--ok` cesse alors d'affirmer :
  encre neutre, jamais l'ambre, réservé au minuteur échu.
- **Le bridage se fait par DÉSACTIVATION VISIBLE, jamais par masquage** : masquer les
  commandes du quai ferait sauter la géométrie (mesuré au temps de l'ancienne rangée
  `#crisisCtrl` : **46 px** de contenu clinique remontés) — la hauteur d'une ligne d'étape, sous les yeux de quelqu'un qui n'a rien demandé, et sur
  événement distant si le rôle change. La boîte reste, la géométrie ne bouge pas.
- **Rien n'est ajouté aux touches du quai** (position constante, A346) ni à `#crisisBand`
  (une 2ᵉ pilule fait tomber le titre de fiche de 172 à 58 px).
- **La fenêtre d'appariement de l'hôte n'est pas une `.ai-modal` ordinaire** : elle
  gèlerait le défilement de sa propre checklist pendant toute la fenêtre d'admission.
- **Rejoindre se tape dans la barre de RECHERCHE de l'accueil** : pas de champ dédié, pas
  de bouton de plus — le code est reconnu à sa forme.
- **Aucun toast, aucune modale, aucun défilement** à l'arrivée d'un invité, à la passation,
  à la coupure. Un COMPTE change de valeur dans la zone d'état ; le détail vit au menu ⋯.

### Voir la trace PENDANT l'action

Une trace lisible seulement dans le compte-rendu ne sert à rien au moment où elle compte.
Quatre niveaux, du permanent au demandé — discipline ECAM : ce qui sert la conduite en
cours est PERMANENT et sur place, le reste s'appelle.

1. **Sur la ligne, sans geste** : *attribution* (marque neutre, seulement pour ce qu'un
   AUTRE a touché — quarante pilules « moi » seraient du bruit) et *divergence* (pilule au
   registre ATTENTION). **Surtout pas le liseré inset de 3 px** : ce trait est le canal du
   REGISTRE de l'étape, le réutiliser rendrait le signal ambigu.
2. **L'historique d'une ligne, à un tap, EN PLACE** — mécanisme des chips du fil condensé,
   jamais une modale.
3. **Le brin annexe** : les relevés d'un participant détaché s'insèrent à leur place
   chronologique, visuellement distincts — ce sont des rapports, pas des passages.
4. **Le journal complet attribué, à la demande**, depuis le menu ⋯. C'est le SD.

### Hors réseau, et le repli

**« Continuer seul »** : si le réseau ne revient pas, l'instantané que l'invité a déjà en
main devient une session locale normale — le repli hors dispositif qu'exige l'AC 120-64
§9.a. **Aucune fusion automatique au retour** : on peut toujours réunir deux JOURNAUX, on
ne peut pas réunir deux ÉTATS (les clés de cochage portent un numéro de visite minté
indépendamment de chaque côté — ce n'est pas un conflit arbitrable, c'est une collision
d'espace de noms, et le résultat serait faux ET plausible, ce qui est pire). Le relevé
revient donc **en ANNEXE**, daté à l'heure du geste, jamais plié dans l'état.

**La péremption est un contrat affiché**, pas une propriété émergente : le seuil est
solidaire de la cadence COURANTE (`max(4 s, 2,5 × période)` — 2,5 signifie « deux cycles
manqués », la gigue étant de ±20 %), et c'est le **quai entier** qui change d'état, pas un
segment. Un invité périmé perd VISIBLEMENT ses capacités d'écriture ; ses cartes de
minuteur portent « non confirmé » — la valeur reste **affichée** (une zone d'état n'ampute
jamais un nombre), elle est simplement marquée comme non garantie.

**Un seul appareil sonne** : bip et flash appartiennent au lead. L'invité voit le segment
ambre « échu » — l'ÉTAT ne disparaît jamais, le SON est unique.

## Historique de sessions synchronisé (v4.54.0)

**Opt-in, défaut fermé**, bascule dans la fenêtre Compte : cela inverse un invariant
documenté (« les sessions vivent en local, jamais synchro »), donc cela se décide, jamais
par effet de bord. Sessions ARCHIVÉES seulement — une session vive resynchronisée serait
un second mécanisme de partage, sans code, sans rôle et sans péremption.

**La trace do-verify (`verified`/`vgaps`) ne monte pas**, et **son absence est DITE** : le
compte-rendu distant porte « trace de vérification disponible sur l'appareil d'origine ».
Une absence qui ne s'annonce pas se lirait « aucune vérification n'a été faite ».

Les sessions d'**exercice** restent strictement ségrégées (colonne dédiée) : la propriété
« zéro contamination clinique » était jusque-là DÉRIVÉE de la localité des sessions.

## Mouvement & ancrage (doctrine ECAM)

Le mouvement est un signal, pas une décoration. En situation de soin :

- **Rien ne bouge sous le doigt.** Tout re-rendu de démarrage ou d'avancement est **ANCRÉ** :
  l'élément déclencheur ne se déplace pas d'un pixel à l'écran (compensation mesurée).
  Le motif « mesurer, re-rendre, compenser » vit dans **une seule** fonction depuis
  v4.45.0 — il existait en quatre copies, et **une seule des quatre mesurait son résidu**.
  Le résidu est RENVOYÉ, jamais corrigé en silence : la compensation est bornée par le haut
  de page, et masquer cette limite rouvrirait un bug de saut de contenu.
- **Un `0` de dérive doit être discernable d'une ancre PERDUE.** Sinon le contrôle qui
  vérifie « dérive 0 px » est vert sur le cas exact qu'il prétend couvrir.
- On ne défile vers une nouvelle carte que si elle n'est **pas déjà entièrement visible**.
- Une **alarme ne déplace jamais le contexte de travail** quand la session est sous les yeux :
  bip/vibration + flash bref, puis persistance en segment ambre. Banderole, flash écran et
  notification système sont **réservés à la session hors de vue** — et l'alarme routée
  s'annonce aussi sur `#srLive` : le bip seul ne dit ni QUEL minuteur ni SUR QUELLE FICHE.
- **ON ANIME LA COMPOSITION, JAMAIS LA MISE EN PAGE** (v4.41.0, `scripts/check-anim.mjs`) :
  une `transition` ou une `@keyframes` ne porte que sur `transform` et `opacity`. Animer
  `width`/`height`/`top`/`margin` force une passe de mise en page **par image**. Mesuré sur
  la barre de progression d'un minuteur : `transition:width` coûtait **126,8 ms/s** de fil
  principal à CPU nominal et jusqu'à 38 % d'un cœur à ×6, sans qu'aucun geste ne soit fait ;
  en `transform:scaleX()` + `transform-origin:left`, 13,3 ms/s — **autant que supprimer
  l'animation, sans changer le rendu d'un pixel**. Le gain est de la MARGE CPU et de
  l'AUTONOMIE sur appareil lent, pas de la fluidité : ne pas le vendre pour autre chose.
  Les propriétés de PEINTURE seule (couleurs, ombres, contours) ne sont pas concernées.
- Le mouvement est réservé à l'alarme et à **une seule invitation, bornée** : l'arrivée du
  quai (A331 — une relevée, trois anneaux, fini à 4,8 s, jamais de boucle). Minuteurs et
  chapeau « Ne pas oublier » n'animent jamais. Tout est inerte sous `prefers-reduced-motion`.
- **RESTAURER UNE POSITION DE DÉFILEMENT, C'EST LE FAIRE DEUX FOIS** (A340) : tout en bas d'un
  protocole, fermer une photo remontait la page — la restauration n'était pas fausse mais TROP
  TÔT. Mesuré sur iPhone : la position est juste juste après la fermeture, puis WebKit repose
  la sienne (0) à la frame SUIVANTE. Elle se repose donc aussi APRÈS le layout, sans jamais
  contrarier un geste en cours, et pour TOUTES les fenêtres. Corollaire de témoin : trente
  configurations de banc étaient vertes — **un témoin doit MODÉLISER l'anomalie du moteur**,
  pas seulement rejouer le geste.
- **Piège de mesure** : le réglage de taille du texte est un zoom CSS — toute mesure relue
  doit être divisée par ce zoom avant d'être réinjectée.
- **Toute sonde qui lit une géométrie après `focus()` doit ATTENDRE** (v4.45.0) : sur
  WebKit, le défilement induit par un focus PROGRAMMATIQUE est asynchrone. Une sonde
  pressée mesure la synchronicité du moteur, pas l'application — elle a signalé 8 défauts
  d'accessibilité qui n'existaient pas.

## Contenu rédigé (v4.4.3 / v4.5.4)

- La **seule couleur admise** y est celle des registres, via des **encadrés typés** (syntaxe
  des alerts GitHub) — jamais de couleur décorative libre : ici, rouge = « ça tue si on
  l'oublie », ambre = « c'est là qu'on se trompe ». Un rouge de mise en page dégraderait la
  crédibilité du rouge des étapes critiques.
- `==surligné==` = surligneur **achromatique** (registre MEMO) : faire ressortir un mot sans
  emprunter une couleur qui a un sens vital.
- **Listes cochables** `- [ ]` pour la vérification rapide en lecture : coches **éphémères**
  par ouverture, case cochée au registre CONFIRMATION, **texte jamais barré** (on doit
  pouvoir relire).
- Taille des images réglée **par image dans le modèle** (jeu fermé), jamais dans la syntaxe,
  et rendue par une CLASSE — jamais un nombre interpolé dans un style.

## La cascade — dix-huit pièges, et ce qu'ils ont en commun

Dix-huit fois, une règle a été silencieusement annulée par une autre. La majorité par
l'ORDRE de déclaration à spécificité égale (`.read-grid`, `.cbt-n`, `.mode-seg`, les
largeurs d'éditeur, les paliers 320 px…), les autres par la SPÉCIFICITÉ :

- `.ai-card p` (0,1,1) l'emportant sur `.sh-code` (0,1,0) ;
- un `#id` (1,1,0) battant un sélecteur de classes plus long (0,2,1) — le geste était bloqué
  mais le bouton restait vert plein et **invitait au geste refusé** ;
- **`:not()` compte la spécificité de son argument** :
  `.ai-modal:not(.pdf-modal):not(.dlg-confirm) .ai-card` vaut (0,3,0) et bat (0,2,0) ;
- **un `>*` qui impose `position`** : le placard levait les enfants directs de l'en-tête en
  `position:relative` (0,2,1) et écrasait `.more-menu{position:absolute}` (0,1,0) — le menu ⋯
  s'ouvrait DANS la barre au lieu de flotter dessous.
- **une COULEUR aussi se vérifie** : `#crisisBand .cb-tag` (1,1,0) écrasait le bleu du
  placard invité écrit en `.cb-tag.inv` (0,2,0) — « ▪ Vous suivez » sortait en ROUGE, le seul
  registre qu'il ne devait pas emprunter, pendant plusieurs versions.
- **un LONGHAND ne survit pas à un RACCOURCI ultérieur** : la marque ⚠/△ d'une étape réserve
  sa place par un `padding-left`, qu'un `padding` raccourci déclaré 1 350 lignes plus bas
  écrasait intégralement — le défaut n'existait qu'AU FOCUS, ce qui explique qu'il ait
  survécu. Même mécanique sur `.rt-h2` : 14 px demandés, **0 obtenu**.
- **le composant RÉUTILISÉ ramène ses règles** : `.empty b{display:block}` (le titre d'un
  état vide) attrapait tous les `b` descendants et coupait en deux chaque ligne de la carte
  pédagogique, nom sur une ligne et glose sur la suivante.
- **un membre de liste `:is()` déclaré plus bas** : `.hdr-back` avait son propre halo, mais
  la liste générique qui le nomme est déclarée après et gagnait par l'ordre — cible à 39 px
  au lieu de 44. On règle en RETIRANT le membre de la liste, jamais en ajoutant une exception
  encore plus bas.

**Deux règles qui en découlent.** Pour une GÉOMÉTRIE, ne jamais dépendre de l'ordre de
déclaration : passer par un `#id`, ou vérifier la position dans la feuille — et compter les
`:not()`. Et **ne jamais imposer `position` par un sélecteur d'enfants** : tout enfant qui se
positionne lui-même en meurt. Quand un `::before` décoratif doit passer sous le contenu, on
**l'enfonce** (`z-index:-1`, si l'élément est bien un contexte d'empilement) plutôt que de
**lever** ses frères — l'un ne demande rien aux enfants, l'autre les contraint tous.

## Les garde-fous — ce qui rend ces règles AUTO-EXÉCUTOIRES

La leçon constante du dossier : **partout où une règle est restée déclarative, elle a fui.**
Les paliers avaient douze valeurs pour neuf déclarées ; l'espacement n'avait aucun token ;
le plancher typographique était employé 173 fois. Aucun de ces écarts n'était visible à la
relecture — chaque déclaration prise isolément était parfaitement légale.

Un garde-fou ne rend pas le système pur, il **l'empêche de dériver**. Ceux du design, joués
à chaque commit par `npm run check` :

| Contrôle | Ce qu'il ferme |
|---|---|
| `check-colors` | aucun hex hors DÉCLARATION de token |
| `check-type` | sept paliers de texte, **et un QUOTA du plancher** (cliquet) |
| `check-space` · `check-radius` | 21 valeurs d'espacement · sept rayons |
| `check-paliers` | les dix paliers de largeur, comparés au code |
| `check-fonts` | trois familles embarquées, trois tokens (une `font-family` en clair est muette) |
| `check-anim` | aucune propriété de MISE EN PAGE animée |
| `check-classes` | toute classe émise est stylée, et réciproquement |
| `check-ids` · `check-tokens` · `check-fns` | un id, un token, une fonction : **déclaré ↔ lu**, dans les deux sens |
| `check-icons` | aucun nom d'icône fantôme (un nom absent rend un `<svg>` VIDE, en silence) |
| `check-syntax` | la feuille de style parse (un commentaire mal fermé AVALE la règle suivante) |
| `check-ring` | la respiration du bord de découpe d'une fenêtre (l'anneau de focus entier) |
| `check-stick` | rien ne s'ancre sur `--hdr-h` sans compter le décalage du clavier |
| `check-actions` · `check-actest` | un `data-*` émis a un lecteur ; une clé de test est citée |
| `check-lexique` | « fiche » banni du texte affiché (A461) |
| `check-guide` | l'exercice guidé cite des libellés, des cibles et des icônes qui existent (A467) |

Les vingt-six `check-*` (dont, hors design, `check-sw`, `check-vendor`, `check-sql`, `check-upload`,
`check-stores`, `check-harnais`, `check-changelog`) jouent en une seconde, sans dépendance : c'est ce qui permet de les
exiger à CHAQUE commit. Les trois symétriques (`ids`, `tokens`, `fns`) sont nés ROUGES — ils
ont trouvé, le jour de leur écriture, un token LU mais jamais déclaré (`--hover` : deux survols
inertes en production) et vingt croix mortes.

Et côté mesure, `npm run audit` (**23 harnais** qui MESURENT au lieu d'affirmer, joués en
parallèle et en TRANCHES — une passe complète tient en ~4 min là où la chaîne séquentielle en
coûtait 10 et cachait tout ce qui suivait le premier rouge) : `audit-a11y`
balaye les surfaces **et les états** — il n'ouvrait que le repos, et deux violations AA ont
vécu à l'écran sans qu'il les voie ; `audit-budget` mesure une **répartition** (chrome ≤ 30 %
de la hauteur, au moins une étape cochable visible), le seul qui ne juge pas une propriété
isolée mais leur SOMME.

**Deux règles de méthode, payées cher.** Un contrôle doit être **vérifié capable d'échouer**
(défaut réintroduit → rouge, fichier restauré à l'octet) : un garde-fou qui ne peut pas
échouer ne prouve rien. Et il doit **rencontrer son cas** : mesurer les fiches d'exemple ne
prouvait rien sur la rangée du répertoire, leur code faisant trois caractères — le témoin
restait vert pendant que la date disparaissait chez l'utilisateur.

## Ce qui a été RETIRÉ (ne pas réintroduire sans besoin constaté)

- **Minimaps** (v4.17.0) : la bande de chips-blocs de l'en-tête et le panneau « Algorithme —
  position » du rail droit sont supprimés — redondants depuis que le fil condensé et le plan
  portent la numérotation commune, l'état par bloc et le saut vers un bloc.
- **Panneau « Algorithme » avant le journal** (v4.18.0) : le SVG est devenu un affichage du plan,
  puis (v4.25.0) une entrée du menu ⋯ en plein écran ; il ne subsiste en tête que pour les fiches
  SANS algorithme.
- **Vue « Détails » du plan** (v4.25.0) : supprimée — voir ci-dessus. Son CSS orphelin et ses
  vestiges JS n'ont été purgés qu'en v4.32.0 : une suppression annoncée doit être VÉRIFIÉE au grep,
  faute de quoi la doctrine affirme un nettoyage qui n'a pas eu lieu.
- **Bulles d'ancêtres synthétiques** du plan (v4.22.1) : remplacées par l'épinglage des cartes
  RÉELLES — quatre itérations ont montré qu'une copie flottante coûte plus qu'elle ne rend.
- **Surveillances et posologie dans la feuille « Consulter »** (v4.25.3) : elles pesaient
  **57 % de sa hauteur** alors qu'elles existent déjà ailleurs (jusqu'à quatre exemplaires).
  Ces copies repoussaient de ~450 px le contenu réellement unique : on faisait défiler ce
  qu'on avait déjà sous les yeux pour atteindre ce qu'on venait chercher — l'inverse du
  decluttering ECAM.
- **La méta de lecture en session vive** (v4.31.0) : statut, catégorie et validation sont
  masqués pendant le soin — vus à l'ouverture, ils ne conduisent rien.
- **La pastille « ▲ Exercice : date » dans la méta** (v4.29.0) : elle captait l'œil à côté
  de la date de validation pour une information non clinique.

**Retraits du chantier v5.0.0** (chacun mesuré, aucun par simple goût) :

- **Le mode LECTEUR** (lot T14) : ne gagnait qu'à 320 px et perdait à 390 — son chrome
  coûtait plus qu'il ne rendait, et sa doctrine avait déjà été abandonnée en v4.28.0.
- **Le rail ①②③ `.care-path`** (lot M2a) : deux numérotations concurrentes dans la même
  colonne. Celle des blocs reste, étant commune à toutes les vues.
- **Le sélecteur segmenté « Guidé / Statique » `#modeSeg`** (lot A) : un segmenté remplace la
  vue et ne ramène personne — remplacé par une EXCURSION qui nomme sa destination.
- **La tab bar basse Aides / Protocoles** (lot M4) : le type est devenu un FILTRE, pas une
  navigation entre sections — **62 px de hauteur permanents** rendus sur l'accueil.
- **La fenêtre `#cxModal` des complications** (lot audit design) : devenue un DÉPLIANT — la
  doctrine QRH porte sur l'INDEX UNIQUE, pas sur la modalité, et la fenêtre couvrait **38 %
  de l'écran à 320 px, pendant un soin**. À UN seul événement, il n'y a d'ailleurs plus
  d'index du tout : l'événement DEVIENT le bouton.
- **Le bandeau-titre en crise ORDINAIRE** : 64 px en haut de colonne pour un titre que la
  barre porte déjà en permanence. Il ne survit qu'aux deux exceptions dont la barre ne sait
  dire que le MOT — exercice et invité, qui ont une PHRASE et une hachure.
- **Le bouton « ⤢ complet » de la colonne d'orientation** : il ouvrait une feuille qui rendait
  **exactement ce que la colonne montrait déjà** (8 rangées identiques) ; sa seule valeur
  ajoutée était la largeur. La feuille reste joignable par le menu ⋯.
- **L'accent hors de l'avatar** : voir « Couleur d'accent ».
- **Les cinq listes v3 comme CHAMPS** (`confirmation`, `notForget`, `verify`, `posology`,
  `differentials`) : elles sont devenues des items à RÔLE dans le pool `items[]`. C'est la
  levée explicite de la règle 12, avec un chemin de reprise écrit AVANT le changement et
  vivant hors de l'application (`docs/conversion-v3-vers-v4.md`).

**Retraits des lots v5.30 à v5.51** (vérifiés au grep) :

- **L'Échelle du plan** (`ovPlanLadderHtml`, A376) : le parcours n'a plus qu'un dessin.
- **La feuille « Consulter »** (A367) et le palier 924 qu'elle seule lisait ; **l'onglet
  « Parcours » de Tout voir** (A389, `ovParcoursHtml`, `.pc-*`).
- **Les glyphes ⚠/△ des étapes** (A345) : le danger est un MOT (CRITIQUE / VIGILANCE).
- **Les 38 alias purs de la refonte v5.6** (A416 : `--primary`, `--critical`, `--verify`,
  `--surface*`…) — `check-tokens` refuse désormais tout alias pur.
- **Les essais d'affichage X1/X2** (A380, tranchés en A433) et le palier 390 (A461).
- **Le dépliage de la barre de sélection sur la ligne** (A476) : le tiroir « Actions » à toute
  largeur.

**Retraits des lots v5.6 à v5.29** (tous vérifiés au grep — une purge à moitié faite est pire
qu'aucune purge, règle 14) :

- **La rangée de commandes `#crisisCtrl`** (v5.6) : ses ouvertures sont devenues deux touches du
  dock. Trois lecteurs la cherchaient encore en v5.10.2, dont un qui recalculait sa hauteur à
  chaque évènement de défilement — pour un élément inexistant.
- **Le tableau de l'accueil ≥ 1200 px, `home-slim` et les « rescues »** (lot v5.18) : une seule
  liste éditoriale, quelle que soit la largeur.
- **Le bouton de filtres ≥ 780 px** (lot v5.18) : les deux clés de la sidebar FILTRENT
  directement — un filtre posé ne se cache jamais derrière un bouton.
- **Le pied du moniteur** (`.mon-foot`, `.mb-dot b` — A342) : la bande portait déjà un point par
  repère, mais ANONYME, pendant que le pied disait quoi et quand sans position — deux objets
  pour un fait. Le dernier repère se pose désormais SUR la bande, à son instant.
- **La grille de la feuille et sa colonne latérale** (`svGridPlan`, `.sv-fk`, `.sv-r`, A344),
  avec les paliers d'écran qui l'ajustaient : la Page a une largeur d'auteur, elle ne s'ajuste
  plus.
- **L'emoji ⚡** (A335) : remplacé sur quinze sites par un glyphe REMPLI (`--bolt`) — un emoji
  change de dessin avec le système, ce qu'un registre ne peut pas se permettre. Il survit dans
  les `<option>` d'un sélecteur natif, qui n'accepte pas de SVG.
- **Six tokens morts et vingt `#id` morts** (A280, A289) : trouvés par les garde-fous
  symétriques le jour de leur écriture. Le cas inverse valait plus cher encore — `--hover`
  était LU par deux règles et n'avait jamais été DÉCLARÉ : deux survols inertes en production,
  invisibles à toute relecture, puisque chaque ligne prise isolément était légale.
- **L'instrumentation des relances iOS** (A307) : elle part avec son diagnostic, clos par la
  mesure — 33 relances complètes pour 109 reprises sur 7 jours, aucune cause d'éviction
  retenue. **Le poids du monofichier est un non-sujet runtime** : les octets de source pèsent
  quelques pour cent d'un processus WebKit.
