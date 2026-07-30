# Journal des modifications — archive (versions 3.0.0 à 4.59.0)

## [4.59.0] — 2026-07-29
### Grand écran : le cockpit trois zones — orientation | action | état

Phase 3 du chantier d'audit (F4). À partir de **1200 px**, la vue de lecture tient de front la
colonne « Se repérer » (le plan, à gauche), le parcours (au centre) et le rail minuteurs (à
droite) : l'idéal ECAM — E/WD et SD sous les yeux en même temps. Pour un binôme hospitalier,
c'est un poste fixe où l'aide-lecteur voit plan, parcours et minuteurs **sans un tap**.

**Palier 1200, pas 1000.** L'audit proposait 1000 px « puisque le palier existe ». Mesuré : à
1000 px les trois colonnes laissent **~390 px** au contenu clinique — moins qu'une tablette en
portrait, pour ce qu'on lit sous stress. À 1200 px : plan 240, action 594 (son plafond de 860
au-delà), rail 360. Aucun palier nouveau n'est créé.

**Le plan quitte le rail droit** à cette largeur : l'afficher aux deux endroits ferait deux
sources pour la même structure — la règle qui vaut déjà pour les minuteurs nominaux.

**L'ordre du DOM reste celui de la lecture.** La colonne de plan est posée *après* la colonne
d'action et ramenée à gauche par `order` : ni un lecteur d'écran ni une tabulation ne doivent
traverser le plan pour atteindre la checklist. Le plan de gauche est le même
`ovPlanLadderHtml` désaturé, **inerte au cochage** (décision figée) — seul son logement change.

Le franchissement du palier **re-rend** (comme le rail à 780 et l'aperçu d'éditeur à 1000) :
c'est un changement de structure, pas de style. Piège vécu au passage : la règle du palier 1200
est déclarée deux fois (en tête puis réaffirmée plus bas, piège de cascade documenté) — la
variante cockpit doit suivre aux deux sites, sinon elle perd à l'ordre.

Vérifié : 780 tests × 2 moteurs, a11y 301/301, doctrine 112/112, zoom-scroll 6/6, vérification
8/8. Rien à rejouer côté serveur.

## [4.58.0] — 2026-07-29
### L'état de mode cesse de bouger — il s'ancre au coin haut-droit

Phase 2 du chantier ouvert après l'audit de design (concept H/B).

La pilule « ■ Mode crise » vivait à droite de la bande-titre quand celle-ci était dépliée, puis
**sautait au milieu de la ligne fusionnée** dès qu'on faisait défiler — et changeait de mot au
passage (« ■ MODE CRISE » ici, « ■ CRISE » là). Or c'est l'objet qui doit se lire en moins d'une
seconde : il devrait être le plus stable de l'écran, pas le moins.

Il est désormais **accolé à ◐ ⋯**, les deux seuls objets qui ne bougent dans aucun des deux
états, et **ne dépend plus du défilement**. Mesuré : même pixel (231 px à 360), même mot, déplié
comme condensé.

### Ce que ce concept n'apporte pas
Les ~90 px rendus au titre étaient le mérite du **concept A** (la pilule descendait dans le
quai), écarté par l'audit lui-même : le quai est la rangée de la télémétrie vive, et pour
l'invité un jeton de mode y doublonnerait les jetons de partage existants. Le gain de B est la
**stabilité**, pas la largeur.

### Deux amendements à l'audit, mesurés
- Il proposait de **vider la bande-titre de son état**. Cela aurait retiré le placard
  « ▪ Vous suivez » posé sur décision utilisateur en v4.55.4 — précisément parce que le bandeau
  est « l'endroit le plus lu » — et fait tomber deux contrôles de harnais qui encodent cette
  doctrine. Le bandeau garde donc son annonce en toutes lettres : la redondance est **voulue**,
  comme l'alarme au quai et au rail.
- Un **repli au glyphe seul** sous 430 px rendait ~41 px au titre. Annulé : en état condensé le
  bandeau est parti, il ne resterait qu'un carré rouge — la couleur et la forme seules pour dire
  le mode, ce que WCAG 1.4.1 et la règle « la couleur n'est jamais seule » interdisent l'une
  comme l'autre.

Le **liseré de mode 10 px** proposé par l'audit n'est pas posé : le placard hachuré de v4.55.4
est déjà le canal périphérique pour l'exercice et l'invité, à coût de hauteur nul — un liseré
serait un troisième dispositif pour la même information.

Vérifié : 780 tests × 2 moteurs, a11y 301/301, doctrine 112/112, exercice 20/20, partage 294/294.
Rien à rejouer côté serveur.

## [4.57.0] — 2026-07-29
### Passe esthétique — profondeur, contraste, rythme (phase 1 des pistes de l'audit)

Première phase du chantier « tout » ouvert après l'audit de design : la PEAU. Les phases
suivantes (en-tête de lecture, cockpit desktop, mode moniteur, police embarquée, restructuration
de la lecture, éditeurs) viennent ensuite, une version à la fois.

### Le thème sombre devient le « Contraste + »
Décision utilisateur : plutôt qu'un 4ᵉ cran au cycle de thème, **le sombre adopte les codes
couleur de l'ex-« Contraste + »** et garde son nom. Motif d'usage : l'extra-hospitalier — soleil
direct sur un écran sombre, gants, appareil posé sur un chariot. Deux canaux, et deux seulement :
encre secondaire relevée (**~7:1** sur les surfaces au lieu de ~4,9:1) et filets renforcés
(**3:1**, le seuil WCAG 1.4.11 des composants — les cadres de carte se voyaient à peine dans le
noir). **Pas** l'encre pleine du bloc `prefers-contrast: more` : là c'est l'utilisateur qui demande
d'aplatir la hiérarchie, ici c'est le défaut de tous. **Pas** les graisses +100 que proposait
l'audit : la graisse porte déjà l'état sur les segmentés, et l'élargir changerait toutes les
largeurs de texte — donc les mesures à 320 px que quatre harnais surveillent.

### Profondeur, fond, rythme
- **`--bg` d'un cran plus profond** (E7) : les surfaces blanches « portent » sans ombre en plus.
- **Trois niveaux d'élévation, écrits** (E1/D6) : plat + filet = contenu clinique ; `--shadow` =
  surfaces vives (session, minuteurs) ; `--shadow-lg` = overlays. Une modale était au niveau 2,
  donc au même plan visuel qu'une carte de session — corrigé. La règle tient en trois lignes dans
  AGENTS.md ; toute surface ajoutée doit s'y ranger.
- **Interlettrage des capitales unifié à `.07em`** (E2, 64 déclarations) : relatif et non px, il
  suit la taille du texte au lieu de se dénaturer quand le corps change.
- **Micro-réponses au geste** (E5) : lévitation d'1 px au survol — **pointeur fin seulement**, car
  sur tactile le premier tap pose l'état hover et un hover qui bouge favorise le double-tap
  (leçon v4.4.4) — et `scale(.99)` à l'appui. Transform/opacity uniquement, inertes sous
  `prefers-reduced-motion`.
- **Le ⤢ devient un dessin de trait** (E6) : même dessin, même doctrine (grammaire des ouvertures
  plein écran), au trait de la famille d'icônes. **Piège mesuré** : un SVG occupe sa largeur
  pleine là où le glyphe Unicode en occupait moins — **4 px de débordement de la rangée de
  commandes à 320 px**, attrapés par `audit-doctrine`. Rendus sur la taille de l'icône (13 px,
  11 sous 400 px), jamais sur `.ctrl-sp` ni par un renommage.

### La tête de bilan du compte-rendu (F6)
Le document commençait par la chronologie : les totaux se reconstituaient de tête, au moment
précis — le débriefing d'équipe — où l'on veut les lire d'un regard. Il s'ouvre désormais sur la
**durée totale en mono 40 px** et les **compteurs de la fiche en tuiles neutres** (plafond 4).
Les compteurs à **zéro sont montrés** : « 0 choc » est une information de débriefing, souvent LA
question. Identique à l'écran et à l'impression.

Vérifié : `npm run check`, 780 tests × 2 moteurs, a11y **301/301 sur Chromium ET WebKit**
(contrastes recalculés sur le fond effectif dans les deux thèmes), doctrine 112/112, zoom-scroll
6/6, consulter 8/8, modeseg 2/2, lecteur 13/13. Rien à rejouer côté serveur.

## [4.56.3] — 2026-07-29
### Audit de design externe — le lot applicable, mesuré et posé

Audit sur 25 captures (1 constat P1, 7 P2, 12 P3, plus des pistes D/E/F/G/H/I/K). Tout ce qui
tenait aux tokens existants, sans rouvrir de décision figée ni créer de capacité, est appliqué ;
les pistes marquées DÉCISION restent à trancher une par une.

### Zone de crise
- **Critères diagnostiques en lignes à filet** (P1-1) — une boîte encadrée par critère
  contredisait la doctrine des listes (« normal = ligne, signalé = boîte ») et repoussait
  « ▶ Confirmé — démarrer la session » loin sous le pli. **53 px rendus, mesurés** sur une fiche à
  critères de deux lignes. Le reste de la distance tient à la RÉDACTION, désormais outillée :
- **le garde-fou du chapeau dit aussi le rappel TROP LONG** (110 c., le seuil télégraphique des
  challenges). Mesuré : quatre rappels dont un composé pèsent 221 px à 360 px — c'est la longueur
  autant que le nombre qui pousse la première action hors de l'écran. Non bloquant, registre
  ATTENTION. `nfGuardTxt` accepte désormais le tableau (le nombre reste toléré).
- **G1 — une action cochable = une ligne** : l'éditeur signale une étape qui cumule des actions
  (« · » ou « + » entourés d'espaces, ≥ 2 dans la partie CHALLENGE ; la réponse « :: » a le droit
  d'énumérer, c'est une valeur). Doctrine QRH : sinon on coche « à moitié fait ».
- **Cartes minuteur** (P2-1) : le nom passe en casse de phrase 13,5/700 et la précision entre
  parenthèses finales est reléguée en méta 12 px (`tmLabelParts`, pure testée) — un nom long en
  petites capitales se déchiffre lettre à lettre, l'inverse du besoin en crise. Le libellé complet
  reste dans les `aria-label`.
- **Le temps dit l'état** (P2-7) : encre à l'arrêt, `--link` EN COURS, ambre échu. `--link` est
  doctrinalement « le temps d'un minuteur en cours » — le défaut disait le contraire.
- **Compteurs** (P2-5) : « + » tonal et large, « − » contour compact (≥ 44 px). En session on
  incrémente dix fois pour une correction ; l'action fréquente prend la masse, jamais un rempli.
- **Une seule ligne d'état** dans le bloc actif (P2-2) : « Vous êtes ici » à gauche,
  Lecteur/Vérifier à droite — **−52 px par bloc actif**, là où deux rangées de chrome flottaient
  entre le titre et la première étape.
- **Rangées d'étape à 60 px** (D1) : le 44 px doctrinal est un minimum, pas un optimum — un pouce
  ganté dans une ambulance en mouvement ne vise pas une case de 24 px. La rangée entière cochait
  déjà ; seule sa hauteur change.
- **Acquittement haptique** (D10) : ~18 ms au cochage et à l'incrément (`tick()`). Avec des gants,
  dans le bruit, la confirmation tactile évite le double-tap de doute — qui sur un compteur
  FAUSSE la donnée. Inerte sur iOS, qui n'expose pas l'API Vibration.
- **Pilule posologique insécable** en statique (D8) ; `tabular-nums` sur les nombres d'état (D11).

### Hors crise
- **Fenêtre Compte** : tuiles d'état **neutres** (P3-1 — `--primary-soft` est la teinte des
  boutons tonals : de la lecture seule s'y donnait l'air cliquable) et **une ligne de conséquence
  par réglage**, la garantie clé en gras, le texte existant CONSERVÉ sous « En savoir plus ».
- **Hors ligne annoncé en neutre** (D7) : « Hors ligne — tout fonctionne sur l'appareil » au pied.
  C'est un état NOMINAL — l'ambre reste à l'échec d'action réseau explicite. `storageState` reste
  PURE : l'état entre par l'instantané, relu à la peinture et aux évènements réseau.
- P3-2 (glyphe « Avec l'IA » au registre INFORMATION), P3-3 (« Cycle »/« Chrono » en pilule
  neutre), P3-4 (« Synchronisé · 11:12 » — le mot ne se dit qu'une fois), P3-5 (« console
  d'administration » remplace le jargon d'infrastructure), P3-6 (colonnes de temps du compte-rendu
  en mono tabulaire), P3-8 (secondes retirées des listes de sessions, `sessStamp`), P3-11 (pied
  d'accueil : le nominal permanent n'affirme plus en vert), P3-12 (pilule de catégorie neutre dans
  Consulter), P3-13 (« Terminer » du bandeau de reprise en contour, cible 44 px), P3-14
  (placeholder de date, compte à rebours du code en `--verify` sous 30 s).

### Écarté, et pourquoi
**G2** — « ✓ Bloc n complet — Continuer vers X » — a été implémenté puis **retiré sur décision
utilisateur** : le bouton passe déjà au registre CONFIRMATION quand tout est coché, les cases le
disent, et deux formules pour un même geste sont exactement ce qu'AC 120-71B proscrit. Le libellé
reste « Continuer — X → », **identique aux deux sites** (journal et vue guidée).

### Un constat d'audit qui visait la doctrine, pas le code
**P2-3** signalait le segment « ⤢ Plan » absent du quai sur toutes les captures. Il l'était en
effet : « Se repérer » a quitté le quai en **v4.25.0** pour la rangée de commandes (architecture
ECP/ECAM). C'est AGENTS.md qui était périmé — deux de ses sections se contredisaient depuis. La
formulation « ORDRE FIXE ⤢ Plan · ● Session · minuteurs » est corrigée. **P2-4** (invité lisant
« ■ MODE CRISE ») est vérifié **conforme** : le placard « ▪ Vous suivez » est livré depuis v4.55.4.

### Non engagé
Les pistes marquées DÉCISION dans l'audit — D2 (« Contraste + », thème vraie nuit), D3 (mode
moniteur), E7 (valeur de `--bg`), F4 (cockpit 3 zones), F5 (police embarquée), F6 (tête de bilan),
H (concepts d'en-tête B/C), I (restructuration de la vue de lecture), K (refonte des éditeurs) —
créent une capacité, touchent un token ou ouvrent un chantier : à trancher séparément.

Vérifié : `npm run check`, **780 tests × 2 moteurs** (+14), a11y **301/301 sur Chromium ET
WebKit**, doctrine 112/112, vérification 8/8, lecteur 13/13, historique 16/16, partage 294/294,
et les 14 harnais verts. Rien à rejouer côté serveur.

## [4.56.2] — 2026-07-28
### Le badge « En cours » trouve sa place — et un bug WebKit de grille est neutralisé

### Badge « ● En cours » à droite de la tuile
Glissé dans la sous-ligne de 11 px, le badge l'étirait et semblait rapporté (« on a l'impression
qu'elle n'est pas adaptée », retour utilisateur). Il vit désormais À DROITE de la tuile, centré
verticalement, hors du bloc de texte — la structure de la maquette desktop : colonne
titre + sous-ligne à gauche (`.qa-tx`), badge en frère à droite. Les rangées du répertoire, qui
alignent déjà leurs pastilles sur une ligne dédiée, ne changent pas.

### Pistes de grille figées au redimensionnement — bug WebKit, reproduit puis neutralisé
Signalé à l'usage : « bug lorsqu'on diminue la largeur puis qu'on ré-augmente » — une rangée du
répertoire restait trop courte, titre rogné en haut, date en bas. IRREPRODUCTIBLE sur Chromium
(sondes discrètes puis fines, 100 % et 130 % de taille du texte : rien) ; reproduit sur WebKit
SEUL, au redimensionnement CONTINU : quand un changement du nombre de colonnes d'une grille
`auto-fill` fait ré-enrouler la sous-ligne d'une rangée, WebKit ne regrandit pas la piste — le
contenu centré dépasse (titre +11 px, date +5 px, mesurés, aux valeurs exactes de la capture
utilisateur) et l'état corrompu PERSISTE, y compris après re-rendu.

Remède : à la TRAÎNÉE du redimensionnement (120 ms, accueil seulement), chaque
`.dir-grid`/`.qa-grid` passe par `block` puis `grid` dans la même frame — écriture-lecture-
écriture synchrones, aucun repaint intermédiaire, donc aucun clignotement — et WebKit recalcule
ses pistes. On ne paie pas un reflow par évènement pendant le geste : l'artefact transitoire de
Safari peut fugacement apparaître pendant la traînée et se répare seul 120 ms après la pause.
Vérifié à la sonde sur les deux moteurs et les deux réglages de taille : état final propre
partout, Chromium jamais affecté. Piège documenté dans AGENTS.md (ne pas retirer ce listener ;
re-mesurer sur WebKit à toute retouche des grilles).

Vérifié : 766 tests × 2 moteurs, a11y 301/301 sur Chromium ET WebKit, doctrine 112/112,
`npm run check`. Rien à rejouer côté serveur.

## [4.56.1] — 2026-07-28
### Les tuiles rejoignent la grille fluide du répertoire

Retour utilisateur immédiat sur la v4.56.0 : « la gestion de la largeur des tuiles en responsive
est extrêmement mauvaise pour toutes les transitions de taille ». Mesuré, et confirmé : les
tuiles « Épinglée(s) » avaient un nombre de colonnes FIGÉ (2 sous 780 px, 3 au-delà) — au
franchissement du seuil, la sidebar et le rail mangent ~330 px d'un coup et une tuile passait de
~360 px à **~140 px** ; et leur rythme ne coïncidait jamais avec celui des rangées du répertoire,
posées juste dessous.

**Une seule règle fluide, partagée** : `.qa-grid` adopte l'`auto-fill minmax(290px,1fr)` et la
gouttière 8 px de `.dir-grid`. Tuiles et rangées ont désormais la MÊME largeur à toutes les
fenêtres et s'alignent colonne pour colonne ; mesuré sur toute l'échelle — 320 → 290 px (1 col),
779 → 2 × 356, 780 → 1 × 451, 1000 → 2 × 332, 1460 → 3 × 372, 1620 → 4 × 317 : tout vit dans la
bande ~290-450 px, une transition ne change plus que le NOMBRE de colonnes, jamais l'échelle.

La question qui a ouvert le dossier (« pourquoi la bulle rétrécit au-delà de ~1480 px ? ») a sa
réponse documentée dans AGENTS.md : c'est la redistribution d'une grille fluide quand une colonne
de plus tient (3 × ~390 → 4 × ~296 vers 1520 px) — bornée par le minimum de 290 px, c'est le
comportement normal, à ne pas « corriger ».

Vérifié : 766 tests × 2 moteurs, a11y 301/301, `npm run check`, design system régénéré (la démo
n'impose plus un nombre de colonnes que le vrai CSS n'a plus). Rien à rejouer côté serveur.

> Entrées anciennes déplacées depuis [`CHANGELOG.md`](CHANGELOG.md) pour garder le journal
> courant lisible. Même format (keep-a-changelog).

## [4.56.0] — 2026-07-28
### L'accueil devient un « poste accès direct » : épinglées, répertoire A→Z, rail alphabétique

Refonte des listes d'aides ET de protocoles d'après la maquette « 2c — poste accès direct » du
canvas Claude Design « Accueil bibliothèques » (modèle du téléphone d'urgence : les favoris sous
le pouce, l'annuaire complet derrière, l'index de tranche pour y sauter).

### Trois étages à la place de la grille de cartes
- **« Épinglée(s) ★ »** — les fiches épinglées en TUILES (liseré de catégorie, code · catégorie,
  « ● En cours »). Libellé accordé au type et au nombre ; **les épinglées seules**, décision
  utilisateur « juste les favoris » — la fréquence d'usage reste un critère de tri de RECHERCHE,
  jamais de mise en avant ; aucune épingle → la section disparaît. Titre en 15 px borné à
  **3 lignes** puis ellipse (2 lignes tronquaient trop pour reconnaître la fiche ;
  `overflow-wrap:break-word`, pas `anywhere` qui coupait « Anaphylaxie » en plein mot) ; le nom
  accessible et l'info-bulle gardent le texte entier.
- **RÉPERTOIRE A→Z** — rangées compactes groupées par lettre (hors A-Z → « # », rangé en fin),
  tri alphabétique STRICT (l'épinglée a sa tuile — la hisser en tête de sa lettre casserait la
  lecture d'annuaire) ; sous 640 px, chaque lettre devient une liste à filets dans une carte
  (maquette mobile). Les rangées gardent l'épingle ☆, le statut en attente, « À revérifier »,
  « À compléter », la catégorie EN TOUTES LETTRES (la couleur d'une pastille n'est jamais seule)
  et la date de validation en forme COURTE (`fmtDateShort` — « Validation : » pèserait plus que
  la donnée sur une sous-ligne de 11 px). Le répertoire ne se pagine JAMAIS : le rail promet
  « A→Z sous le doigt », un « Afficher plus » ferait des lettres injoignables.
- **RAIL ALPHABÉTIQUE** — tap = saut à la lettre, GLISSER le long des lettres = parcourir
  (index iOS ; pointer capture). Dès 2 lettres ; s'il ne tient pas en hauteur il DISPARAÎT
  (jamais de lettres coupées ni de cibles < 24 px). En étroit il est FIXE, ancré entre le bas
  de l'en-tête (`--hdr-h`) et la tab bar — un centrage sur la fenêtre passait sous l'en-tête
  à 320×640, mesuré puis corrigé.

### Ce qui ne change PAS (décisions utilisateur explicites)
La recherche RESTE dans l'en-tête (champ statique : le focus survit aux re-rendus, raccourci
« / » — la grande recherche du corps de la maquette est écartée) ; le filtre catégorie FILTRE
(l'« estompage sans déplacer » de la maquette est refusé) ; en recherche, liste plate triée par
pertinence (épinglées > frecency > titre), extraits contextuels et pagination inchangés.

### Historique GLOBAL des sessions
Le compte « n sauvegardées » des cartes disparaît ; à sa place, la fenêtre Historique gagne un
mode « toutes les fiches » (chaque rangée nomme la sienne, cliniques et exercices toujours
séparés) : rangée « Historique des sessions (n) » en bas de la sidebar en large, lien du pied de
page en étroit — masqués à zéro session (aucun bouton mort). L'entrée PAR FICHE du menu ⋯ est
inchangée. `openSessHist()` sans argument = mode global `'*'`.

### Sous le capot
- Fonctions pures testées : `azLetter`/`azGroups` (lettre désaccentuée, table en
  `Object.create(null)` — la clé vient d'un titre saisi) et `qaPick` ; +10 tests (766 × 2 moteurs).
- L'ancien composant `.card`/`.cards` est PURGÉ (émissions vérifiées au grep, règle 14 ; démo
  `design/build.mjs` refaite ; `newTonal`, champ mort d'avant la refonte, retiré). Le bouton-titre
  GARDE le nom `.card-open` : quatorze harnais ouvrent une fiche par ce sélecteur.
- Périmètre accueil d'`audit-a11y` : `.dir-wrap,.azrail` remplace `.cards` — un sélecteur mort
  ferait passer l'accueil sans le mesurer (leçon v4.31.1). Le bouton-titre des rangées porte un
  padding 6 px compensé : sa BOÎTE atteint 29 px (l'ancien titre passait la mesure parce qu'il
  s'enroulait sur deux lignes ; le `::after` étendu, lui, ne se mesure pas).
- Vérifié : `npm run check`, 766 tests × Chromium + WebKit, a11y **301/301 sur les deux
  moteurs**, doctrine 112/112, zoom-scroll 6/6, zéro débordement horizontal à 320 px, clair et
  sombre. Rien à rejouer côté serveur.

## [4.55.5] — 2026-07-28
### Deux défauts signalés à l'usage — un menu qui tombait dans la barre, une attribution qui suivait la mauvaise personne

### Le menu ⋯ s'ouvrait DANS l'en-tête — dixième piège de cascade
Dès qu'un placard était posé (exercice ou invité), ouvrir le menu ⋯ ne produisait plus une
fenêtre flottante : il retombait **dans le flux de la barre**, qu'il rallongeait d'autant.

Le placard, pour faire passer le contenu au-dessus de sa hachure, levait **tous les enfants
directs** de l'en-tête en `position:relative; z-index:1`. Or `.more-menu` est un enfant direct
**et se positionne lui-même** : `header.bar.exo>*` vaut (0,2,1) contre (0,1,0) pour
`.more-menu{position:absolute}`. La règle décorative écrasait la règle structurelle.

**On retire l'exigence plutôt que de l'assortir d'exceptions.** Nommer le menu dans un `:not()`
n'aurait fait que déplacer le piège au prochain calque ajouté là — c'est la leçon de la v4.55.3,
une version plus tôt. `header.bar` porte déjà `position:sticky; z-index:20`, donc elle **est** un
contexte d'empilement : un `::before` en `z-index:-1` s'y peint au-dessus du fond de la barre et
sous tout son contenu, **sans qu'aucun enfant ait à être positionné**. On **enfonce** la hachure
au lieu de **lever** ses frères ; l'un ne demande rien aux enfants, l'autre les contraint tous.

`#crisisBand` garde l'ancienne mécanique, et ce n'est pas une inconséquence : il est
`position:relative` **sans `z-index`**, donc pas un contexte d'empilement — un `z-index:-1` y
passerait sous son propre fond et la hachure disparaîtrait. Ses enfants sont tous statiques.

### « Avancé par … » nommait l'hôte pour les gestes de l'invité
La mention était un drapeau **global** qu'un seul site du fichier remettait à zéro : `cxEnter`,
l'entrée sur complication. **Aucun avancement ordinaire ne l'effaçait.** Posée une fois —
typiquement par le backlog rattrapé à la jointure, où toutes les navigations de l'hôte défilent
d'un coup — elle **suivait ensuite l'invité de carte en carte** et attribuait à « Hôte » les blocs
qu'il venait lui-même d'avancer.

Encore un demi-chemin : un effacement écrit d'un seul côté. Le remède n'est donc pas d'ajouter les
N sites manquants — c'est de **supprimer le besoin de s'en souvenir**. La mention porte désormais
le **numéro de visite** que l'avance distante a créé et ne s'affiche que sur celui-là ; le premier
passage minté localement en porte un autre, donc elle disparaît **par construction**.

Elle est posée **dans `shareApplyAnchored`**, seul point où une navigation distante devient la
position courante. `onEvents` le manquait dans un cas (le drain de la file par `rmResume` n'y
repasse pas) et le posait dans un autre où il ne fallait pas : une navigation **refusée** par le
mode lecteur nommait déjà son auteur alors que rien n'avait bougé. L'annonce au lecteur d'écran
garde, elle, une variable **locale au lot** — elle n'a ni la même durée de vie ni la même
condition que la mention affichée.

### Ce que le diagnostic a écarté en chemin
Deux hypothèses ont été **mesurées puis abandonnées** avant d'arriver à la bonne, et c'est ce qui
a évité de « corriger » du code sain : l'attribution est juste quand la liste des participants
est à jour (« avancé par Infirmier », vérifié), et il n'y a **aucun écho** — l'hôte ne repousse
pas sous son nom ce qu'il vient de recevoir. Le défaut n'était ni dans la résolution serveur de
l'acteur (le secret l'emporte sur l'identité, y compris quand les deux appareils sont connectés au
même compte) ni dans le rebasage du diff.

### Vérification
**294/294 contrôles partage** (+14, sur les deux moteurs), 756 tests × 2 moteurs, 14 harnais verts
sur Chromium **et** WebKit, 301 contrôles d'accessibilité, 112/112 doctrine.

Les deux défauts réintroduits en font tomber **sept** ; fichier restauré à l'octet. **Un témoin a
dû être refait** : la première version de la sonde d'attribution avançait par `next`, nul sur le
dernier bloc de la fiche d'exemple — l'avance locale n'avait donc jamais lieu et les deux contrôles
suivants mesuraient du vide. C'est le témoin lui-même qui l'a signalé. De même, la hachure est
mesurée par son **image de fond** et non par l'opacité : sur un en-tête sans placard le
pseudo-élément n'a pas de `content`, et `getComputedStyle` rend alors l'opacité par défaut `1` —
un témoin fondé sur l'opacité aurait été vert des deux côtés.

**Rien à rejouer côté serveur.**

## [4.55.4] — 2026-07-28
### L'invité sait qu'il est invité — et un bouton pressé répond enfin

Les deux derniers signalements du lot. Avec eux, les dix remontés à l'usage sont traités.

### Le placard de l'invité
Il lisait « ■ Mode crise » — **exactement ce que lit l'hôte** — alors que sa situation est autre :
il **suit** une session qu'il ne conduit pas et qui peut s'arrêter sans lui. Le quai le disait déjà
par un jeton de sept caractères ; le bandeau le dit maintenant en toutes lettres, à l'endroit le
plus lu de l'écran : « **▪ Vous suivez** », hachure **bleue**, l'en-tête relayant « ▪ Suivi » au
pixel où le titre passe dessous.

**Même mécanique que le placard d'exercice, au trait près** — `::before` en fondu, relais au
défilement, enfants en `z-index:1`. Rien de neuf à inventer, donc rien de neuf à casser. Et **coût
nul en hauteur**, mesuré : c'est la seule condition qui vaille dans une zone où la rangée de
commandes n'a que 2,1 px de marge à 320 px.

Registre **bleu**, jamais l'ambre ni le rouge : suivre la session d'un collègue n'est ni une alerte
ni une vigilance, c'est un état. Le mot le porte ; la hachure ne fait que le rendre reconnaissable
d'un coup d'œil.

**L'exercice garde la priorité**, et ce n'est pas négociable : *« ceci est une répétition »* prime
sur *« vous suivez »* — le premier protège d'une méprise clinique, le second est une information de
rôle que le quai porte en permanence de toute façon. Un contrôle l'encode.

### Répondre à un geste n'est pas interrompre
La règle 11 — *« en session de crise, aucune notification flottante »* — vise ce qui **arrive** :
une erreur de synchro, un conflit, une nouvelle de fond, quelque chose qui s'impose à quelqu'un qui
n'a rien demandé, au pire moment. Elle ne visait pas la **réponse** à un bouton qu'on vient de
presser.

Or la file les retenait tous : taper « silencieux ? », ou « Partager la session » sur une fiche en
brouillon, ne produisait **rien du tout** — et le message surgissait plus tard, au retour à
l'accueil, détaché de son geste, donc incompréhensible.

Le troisième argument de `toast()` marque une réponse directe. Il est **explicite**, et non déduit
d'une proximité temporelle avec un clic : une nouvelle de fond qui tomberait dans la seconde suivant
un tap serait alors affichée par accident — exactement ce que la règle interdit. Quatre sites
marqués, tous atteignables pendant un soin.

### Vérification
**280/280 contrôles partage** (+9, sur les deux moteurs), 756 tests × 2 moteurs, 14 harnais verts,
301 contrôles d'accessibilité sur les deux moteurs, 112/112 doctrine. Les deux défauts réintroduits
en font tomber quatre ; fichier restauré à l'octet. Le contrôle du placard mesure l'opacité du
`::before` — pas la classe : c'est la hachure qu'on veut voir, pas l'intention de la poser.

**Rien à rejouer côté serveur.** Les dix signalements d'usage de ce lot sont traités.

## [4.55.3] — 2026-07-28
### Trois rognages que personne ne mesurait

Les trois défauts d'affichage signalés à l'usage, tous reproduits au pixel avant correction.

### Le titre décalé : neuvième piège de cascade, premier par `:not()`
Sur écran étroit, une règle transforme toute fenêtre en feuille pleine largeur et lui pose **18 px
de rembourrage haut**. Or « Se repérer » et « Consulter » se donnent `padding:0` — leur barre de
titre est `sticky top:0` et doit affleurer le bord.

Elles perdaient, et pas par l'ordre : `.ai-modal:not(.pdf-modal):not(.dlg-confirm) .ai-card` vaut
**(0,3,0)**, parce que **`:not()` compte la spécificité de son argument** — contre (0,2,0) pour
`:is(.plan-modal,.ref-modal) .ai-card`. Résultat mesuré : 18 px de fond nu au-dessus du titre, et
**65 px sur un iPhone à encoche** où `env(safe-area-inset-top)` s'ajoute — bande qui restait
visible au défilement, la barre étant collante.

On exclut désormais la **classe** `.sheet-full` plutôt que les deux fenêtres nommément : la
prochaine feuille plein écran héritera de l'exclusion au lieu de rejouer le défaut.

### La croix qui sortait du cadre
**110 px hors du cadre à 320 px**, 70 à 360, 40 à 390, 7 à 430 — et seulement sur écran **tactile**,
où « silencieux ? » et le bouton son montent à 44 px de cible. `.rt-head` est une rangée flex sans
retour à la ligne et dont rien n'est compressible : son contenu exige 331 px pour 221 disponibles.

Remède = le patron déjà éprouvé de la carte-bilan (v4.29.2) : conteneur `relative`, croix **ancrée**
en haut à droite, et un `padding-right` qui lui réserve sa place à toutes les largeurs. Le reste
s'enroule dessous plutôt que de la pousser hors de l'écran — on ne tronque pas un libellé de
commande, on lui donne une seconde ligne.

### La ligne d'Échelle qui sortait du plan
Débordement dès **quatre options à 320 px**, cinq à 390, six à 430, et jusqu'à **280 px dehors à
huit** — le titre de la décision étant écrasé à 0 px de large bien avant. Les renvois abrégés
(`FIBRIL→2 ASYSTO→3 …`) sont en `flex:none` et `nowrap` : leur largeur croît avec le nombre de
branches, sans borne.

On **enroule** plutôt que de tronquer. Dans un plan, une branche cachée est une branche qu'on ne
saura pas prendre — c'est la différence avec le quai, où l'on abrège et où l'on annonce « +n » :
ici la place existe, verticalement.

### Les contrôles ont dû être refaits, et c'est le point
Six contrôles permanents dans `audit-doctrine.mjs` (112/112, sur les deux moteurs). **La première
version restait verte avec les trois défauts réintroduits** : elle mesurait la fiche d'exemple —
deux options, donc jamais de débordement — et un contexte non tactile, où les cibles ne gonflent
pas. Elle ne rencontrait pas le défaut, donc elle ne le couvrait pas.

La version retenue **construit le cas** : une décision à huit branches, un contexte `hasTouch`, et
la mesure prise contre le bord **intérieur** du cadre — un bouton qui touche la bordure est déjà
coupé. Réépreuve : les cinq défauts réintroduits à l'identique en font tomber **huit** ; fichier
restauré à l'octet.

756 tests × 2 moteurs, 14 harnais verts, 301 contrôles d'accessibilité, 271/271 partage.
**Rien à rejouer côté serveur.** Restent deux signalements : le bandeau d'en-tête de l'invité et les
notifications retenues jusqu'à l'accueil.

## [4.55.2] — 2026-07-28
### Le menu ne suivait pas l'état du partage — et « Prendre la main » n'était nulle part

Trois signalements d'usage, deux causes. La première explique pourquoi la passation semblait sans
effet : **le geste n'avait pas de porte.**

### Un menu construit au rendu, dans un dispositif qui interdit de rendre
Les rangées du menu ⋯ sont bâties **au rendu** et stockées telles quelles. Or la règle 3 interdit de
re-rendre sur évènement distant — c'est elle qui empêche qu'un écran bouge sous le doigt de
quelqu'un qui coche. Conséquence : « Partage en cours **(n)** » gardait le compte du moment où la
fiche avait été ouverte, et **« Prendre la main » ne paraissait jamais**, puisqu'une offre arrive
par le réseau.

On mémorise donc le **constructeur** des rangées, pas seulement son résultat, et on le rejoue quand
l'état du partage change. Le menu vit dans l'en-tête, hors de `main` : **pas une ligne de la
checklist ne bouge** — vérifié, le nœud témoin est le même objet avant et après, à 0 px.

Et la rangée elle-même était **au mauvais endroit** : posée dans le menu de l'hôte, où sa condition
`Share.mode === 'guest'` ne pouvait jamais être vraie. Elle n'existait donc nulle part. Elle vit
maintenant dans le menu de l'invité, le seul où elle ait un sens.

### Un lien mort qui laissait agir sans rien dire
Après « Couper », l'invité ne pouvait plus cocher — mais il pouvait encore **incrémenter un
compteur**. Le geste ne partait pas, et **rien ne le lui disait**. C'est mot pour mot le pire mode
de défaillance nommé au plan : *« un invité qui continue de cocher dans le vide en croyant
contribuer à une réanimation en cours »*.

La garde couvrait les gestes **réservés** ; il en manquait une pour le cas où le **lien est mort**,
qui n'a rien à voir avec le rôle. Toute mutation est désormais refusée et **annoncée** sur `#srLive`
— seul canal admis pendant un soin (règle 11 : ni modale, ni banderole).

**`detached` n'en fait pas partie, et c'est délibéré** : celui qui a poursuivi seul travaille sur
*sa* session. Lui refuser ses gestes reviendrait à lui retirer le repli hors dispositif qu'on vient
de lui donner (AC 120-64 §9.a). Un contrôle l'encode.

### Vérification
**271/271 contrôles partage** (+8, sur les deux moteurs), 756 tests × 2 moteurs, 14 harnais verts,
301 contrôles d'accessibilité, 94/94 doctrine. Les trois défauts réintroduits à l'identique en font
tomber trois ; fichier restauré à l'octet.

Deux sondes ont encore dû être corrigées avant de conclure : l'une cherchait un bouton de compteur
dans un panneau **replié** — elle ne mesurait rien et concluait que le geste était bloqué ; l'autre
lisait la zone d'annonce **sans la vider**, et y trouvait le message précédent. Même travers que
depuis le début de ce chantier : mesurer le mécanisme au lieu de la propriété.

**Rien à rejouer côté serveur.** Restent trois signalements : le bandeau d'en-tête de l'invité, les
trois défauts de mise en page, et les notifications retenues jusqu'à l'accueil.

## [4.55.1] — 2026-07-28
### CORRECTIF — les assertions ajoutées en v4.55.0 lisaient une table sous le rôle `anon`

`ERROR: 42501: permission denied for table shared_sessions`. Les trois vérifications que la v4.55.0
ajoutait au § 14.5 — « nommer ce qui doit passer plutôt que compter » — interrogent la table en
direct, alors que le bloc est encore sous le rôle **`anon`**, posé au § 14.3 et jamais rendu.

Correction : on reprend les droits le temps de la lecture, puis **on restitue le rôle exactement
comme on l'a trouvé** — les sections suivantes s'appuient dessus.

### Le troisième rejeu perdu, et le garde-fou qui ferme cette famille
C'est la troisième fois qu'une erreur SQL vous coûte un aller-retour : un `$$` mutilé (v4.44.1), une
variable non déclarée (v4.54.1), et maintenant un accès de table sous un rôle sans privilèges.
Toutes trois ont la même cause de fond : **`supabase/*.sql` n'est ni servi ni chargé par les
tests**, sa seule épreuve était le collage dans l'éditeur.

`check-sql.mjs` gagne un troisième contrôle statique. Il est **volontairement borné à `anon`** :
ce rôle n'a aucun privilège de table par construction — c'est tout l'objet du § 13 —, donc toute
lecture directe pendant qu'il est actif est une erreur **certaine**. Sous `authenticated`,
interroger une table est légitime, et c'est même ainsi qu'on prouve que la RLS filtre (le § 14.19
lit l'historique d'Alice sous Bob et attend zéro ligne). Une règle plus large aurait produit des
faux positifs **sur les tests mêmes qui font le travail** — un garde-fou qui crie sur du code juste
finit ignoré. Les appels de fonction ne comptent pas : `share_join`, `share_pull` et `share_push`
sont `security definer`, et c'est précisément leur raison d'être.

**Vérifié capable d'échouer** en réintroduisant le défaut vécu à l'identique : il nomme la table, la
ligne, et le remède. Fichier restauré à l'octet.

`schema.sql` de la v4.55.0 était correct et **n'a pas à être rejoué** ; **`rls-tests.sql` est à
rejouer**. 756 tests × 2 moteurs, 14 harnais verts, `npm run check` 6/6.

## [4.55.0] — 2026-07-28
### Le scribe conduit — j'avais mal lu ma propre source

Objection d'usage, et elle porte : le médecin partage **pour se libérer les mains** — faire des
gestes, téléphoner, parler à l'équipe. Si un infirmier demande au scribe « c'est quoi les étapes
d'après ? mets le minuteur en pause, il reprend un rythme », le scribe ne pouvait rien faire, et le
médecin devait reprendre son téléphone pour valider avant de repasser la main.

### Ce que la source dit vraiment
AC 120-71B §5.2.2.1 — « one crewmember reading the checklist and the second confirming and
responding » — décrit une répartition de **la parole**, pas un système de permissions. Et dans ce
modèle, **c'est celui qui lit qui fait avancer la liste** ; le lead est celui dont les mains sont
prises. J'avais transposé l'inverse.

Les autres sources convergent : la **SFAR** (« le lecteur : sa seule tâche est de lire et de
**guider** »), l'**ECAM** (le pilot monitoring actionne l'ECP, le pilot flying pilote), et surtout
**McEvoy 2014** — 99,5 % contre 70 % d'adhérence, la meilleure donnée du dossier — où **le lecteur
tenait l'unique appareil**. La conception précédente empêchait exactement la configuration la mieux
documentée.

Et le critère juste était **déjà écrit dans ce dépôt**, pour `mark_void` : « annuler CONSERVE,
décocher DÉTRUIT — ce n'est donc pas une action destructrice, et la règle qui réserve celles-ci au
lead ne s'y applique pas. » Naviguer est append-only ; arrêter un minuteur conserve son `elapsedMs`.
Rien ne les réservait.

### La nouvelle ligne
| Ouvert au scribe | Réservé |
|---|---|
| cocher · constater · écart · incrémenter · armer · repère | **décocher** — efface une information |
| **avancer · choisir une branche · terminer un bloc** | **remettre à zéro** — efface un décompte que personne ne restitue |
| **arrêter un minuteur** · entrer sur une complication | **terminer le partage** · dater le début du soin |

**L'objection d'ambiguïté** (§5.5, « qui fait quoi », qu'Airbus supprime par un ECP unique) reçoit
la réponse constante du projet : **on n'interdit pas, on annonce.** Une avance venue d'en face pose
une mention « avancé par ‹rôle› » sur la carte courante, à côté de « Vous êtes ici » — même
information, vue par l'autre angle. Elle s'efface au geste de navigation suivant.

### Le lecteur était une troisième copie, jamais recensée
Signalé aussi : « pourquoi l'invité peut passer de bloc en bloc en mode lecteur mais pas sur la
page ? ». C'était vrai — `data-rmnext` et `data-rmopt` sont les mêmes verbes que `data-ovnext` et
`data-ovopt` sous d'autres noms, et la liste ne les nommait pas. Ce n'était **pas** un défaut de
portée (la garde en capture atteint bien `#readerMode`, prouvé en injectant `data-plgo` sur un de
ses boutons) mais de **prédicat**.

Trois choses en sont sorties, indépendantes du redécoupage :

- **`data-rmok` écrivait `state.checked` en direct**, sans passer par le prédicat unique. La
  doctrine annonce **deux** copies du cœur de cochage ; le lecteur en était une **troisième**.
  Mesuré : un invité au lien **arrêté** cochait quand même depuis le lecteur alors que le même
  geste était refusé sur la page.
- **Huitième piège de cascade du projet, second par spécificité** : `#readerMode .rm-ok` porte un
  **id** (1,1,0) et l'emportait sur `body.share-scribe :is([data-rmnext])` (0,2,1). Le geste était
  bloqué, mais le bouton restait vert plein, 72 px, graisse 800 — il **invitait** à un geste refusé.
- **Une émission refusée laissait le miroir divergent en silence** : la base de diff avance *avant*
  l'émission, si bien qu'un genre refusé n'était jamais renvoyé, même après promotion. Le miroir se
  déclare désormais périmé et redemande tout.

### Deux correctifs d'usage
**L'intitulé du journal ne se propageait pas.** `shareDiff` ne comparait que l'annulation d'un
repère : **étiqueter après coup** — le geste normal, puisque « Noter l'heure » ne demande rien — ou
corriger l'heure n'émettait rien. En le réparant, un second défaut est apparu : la réception
**empilait** un repère déjà connu au lieu de le mettre à jour ; le correctif seul aurait doublé la
ligne. Un test encodait le défaut (son couple de comparaison changeait la référence *et*
l'annulation) — variable isolée.

**Couper celui qui tient la main la rend à l'hôte.** Après « donner la main » puis « couper », le
partage gardait un lead révoqué et un hôte resté scribe : plus personne pour conduire, l'état que
l'invariant 1 interdit (« jamais deux, **jamais zéro** »). Ce n'est pas bloquant — les gardes de
l'hôte sortent sur `mode !== 'guest'` — mais faire reposer un invariant affiché sur la porte de
sortie d'une garde, c'est le laisser dépendre d'un détail d'implémentation.

### Le garde-fou qui manquait
`SHARE_KINDS_ANY`/`_LEAD` et `share_kind_allowed` sont **la même règle en deux langages**. Elles ont
divergé : le redécoupage a été porté des deux côtés, mais l'assertion qui l'éprouve ne l'a pas été —
et le défaut n'est apparu qu'au collage dans l'éditeur SQL. Une divergence est **silencieuse et
asymétrique** : client plus permissif, un geste part et le serveur le jette sans que l'auteur le
sache ; serveur plus strict, un geste légitime est refusé sans raison lisible.

`check-sql.mjs` compare désormais les deux listes à chaque commit. **Vérifié capable d'échouer** en
reproduisant la divergence exacte de cette version (serveur redécoupé, client en arrière) : il nomme
les quatre genres des deux côtés ; fichier restauré à l'octet.

### Vérification
756 tests × 2 moteurs (+9), **263/263 contrôles partage** (+13, sur les deux moteurs), 14 harnais
verts, 301 contrôles d'accessibilité, 94/94 doctrine. Quatre contrôles du harnais encodaient
l'ancienne ligne : retournés plutôt que supprimés, ils affirment la nouvelle et disent pourquoi.
Quatre sondes ont dû être corrigées avant de rien conclure — l'une relevait les boutons **avant**
d'ouvrir leur panneau, une autre cochait « tant que Continuer n'existe pas » alors que le bouton est
rendu d'emblée : elle mesurait la règle d'avancement, pas le bridage.

**`supabase/schema.sql` est à rejouer** (`share_kind_allowed` change), puis `rls-tests.sql`.

## [4.54.2] — 2026-07-28
### CORRECTIF — l'historique synchronisé de la v4.54.0 ne synchronisait rien

Signalé à l'usage, et exact sur les trois points : la bascule ne suivait pas d'un appareil à
l'autre, les sessions antérieures à l'activation ne montaient pas, celles terminées après non plus.
**La table existait, les politiques RLS étaient vertes, la bascule s'allumait — et pas une ligne ne
partait.** Une fonctionnalité entièrement livrée, entièrement inerte.

### Une cause et demie
`_pushTable` ne pousse que les objets portant `dirty`, et **aucun site n'en posait jamais sur une
session**. Explique les deux symptômes de fond. Le troisième — la bascule qui ne suit pas — venait
d'un oubli distinct : le réglage n'entrait pas dans les préférences synchronisées, alors que le
vocabulaire personnel ajouté à la même version, lui, y entrait.

Le marquage vit désormais au **point d'étranglement de l'écriture** (`_putSessionSafe`), comme
l'émission du partage vit dans `persistLive` : toute mutation ajoutée demain sera couverte sans
qu'on y pense. La pierre tombale de la suppression y passe aussi — elle posait ses champs à la
main, ce qui rendait fausse, dès la ligne où elle était écrite, la doctrine « ici, et nulle part
ailleurs ».

### Deux pièges que la contre-expertise a trouvés, et qui auraient annulé le correctif
**`updatedAt` doit être posé en même temps que `dirty`.** Une session n'en portait pas — seulement
`savedAt`, qui ne bouge plus après l'archivage. Posé seul, `dirty` aurait fait gagner
**inconditionnellement** la copie distante à la résolution du dernier écrivain (`savedAt > 0`,
toujours vrai) — et **effacé la trace do-verify de chaque session à la première synchro**. Le
correctif du push, seul, aurait donc détruit des données.

**Le rattrapage ne peut pas se garder sur une transition.** Qui a activé l'option en v4.54.0 —
quand elle ne poussait rien — a déjà la clé à « 1 » : il ne reverra **jamais** le passage
éteint→allumé. Un rattrapage gardé par cette transition aurait donc raté **exactement les personnes
qui ont signalé le défaut**. La garde est une clé durable, et un réveil de synchro suit le
balayage : quand l'option est apprise par le pull des préférences, la poussée de la même passe est
déjà sortie par son garde d'entrée.

### Vérification
Nouveau harnais **`scripts/audit-historique.mjs`** — quatorzième —, **16/16 sur les deux moteurs**.
Il mesure ce qui **partirait** (transport bouchonné) plutôt que ce que le code déclare : rien sans
l'option, l'existant rattrapé, une session terminée après qui part, la trace do-verify qui reste et
dont l'absence est dite, une session **vive** qui ne part jamais, le réglage qui voyage et qu'une
préférence distante éteint — et le cas « déjà activé en v4.54.0 », qui a son propre contrôle.

**Vérifié capable d'échouer** : les trois défauts réintroduits à l'identique en font tomber six,
fichier restauré à l'octet. Une sonde a dû être corrigée en route — elle avait perdu son bouchon de
transport et accusait l'application de son propre oubli. 747 tests × 2 moteurs, 14 harnais verts,
301 contrôles d'accessibilité, 250/250 partage. **Rien à rejouer côté serveur.**

## [4.54.1] — 2026-07-28
### CORRECTIF — `rls-tests.sql` de la v4.54.0 ne s'exécutait pas, et rien ne pouvait le dire

Signalé au rejeu : `ERROR: 42703: column "v_share" does not exist`. Les trois sections ajoutées en
v4.54.0 (§ 14.15 à 14.17) employaient une variable qui n'existe pas dans le bloc — les conventions
de nommage du fichier n'avaient pas été relues avant d'y écrire.

**Deuxième rejeu perdu par la même famille de faute** (après le `$$` mutilé de la v4.44.1), et pour
la même raison de fond : `supabase/*.sql` n'est ni servi, ni chargé par les tests — sa seule épreuve
est le **collage dans l'éditeur SQL**, donc sur une instance réelle. Pire, PostgreSQL ne signale une
variable inconnue qu'à l'**exécution de la ligne fautive** : un test placé en fin de bloc casse
après trois minutes de travail réussi, et laisse croire que le reste est en cause.

### Les sections sont désormais AUTONOMES
Elles ouvrent leur propre partage et font rejoindre leur propre participant, au lieu de s'appuyer
sur l'état laissé par les tests précédents. Une assertion qui dépend de ce qu'un test antérieur a
bien voulu laisser derrière lui casse au premier réordonnancement — et c'est exactement ce qui
vient d'arriver. Un préalable explicite y a été ajouté : le § 14.12 remplit le quota de partages
vivants d'Alice, il faut donc les expirer avant d'en ouvrir un neuf, sinon l'ouverture échouerait
**pour une raison qui n'a rien à voir avec ce qu'on mesure**.

Deux assertions s'y ajoutent, qui manquaient : § 14.18 (la passation s'annonce des deux côtés) et
§ 14.19 (l'historique de sessions ne se prête pas — Bob ne lit ni n'écrit celui d'Alice).

### Le garde-fou qui aurait attrapé cela
`check-sql.mjs` collecte les variables **déclarées** d'un bloc `do $$ … declare … begin`, collecte
celles qui y sont **employées**, et compare. Statique, donc instantané, donc joué à chaque commit —
là où l'erreur coûtait jusqu'ici un aller-retour complet sur une instance de production.

**Vérifié capable d'échouer** en réintroduisant le défaut vécu à l'identique (`v_share`) : le
contrôle le nomme et donne sa ligne ; fichier restauré à l'octet. Il ne prétend pas remplacer un
analyseur plpgsql — il attrape la faute qui a été commise, ce qui est le seul critère qui vaille.

`schema.sql` de la v4.54.0 était correct et n'a pas à être rejoué ; **`rls-tests.sql` est à
rejouer**. 747 tests × 2 moteurs, 13 harnais verts.

## [4.54.0] — 2026-07-28
### La main se passe, l'historique suit le compte, et le serveur cesse de faire confiance au client

Lot 6 du chantier, la passation de la main, et les trois durcissements serveur annoncés en v4.53.1 —
un seul rejeu de schéma pour l'ensemble.

### La passation de la main
Le scribe ne conduit pas : il ne navigue pas, n'arrête pas un minuteur, ne termine pas. C'est la
forme canonique du travail à deux (AC 120-71B §5.2.2.1) — mais **sans passation, quelqu'un qui a
besoin de conduire n'a aucun recours**, et l'asymétrie devient une impasse. Le genre `handoff`
existait dans le vocabulaire depuis la v4.46.0 ; rien ne l'émettait, aucune surface ne l'offrait.

Trois temps, comme l'exige AC 61-115 « Positive Exchange of Flight Controls » : l'hôte **propose**,
l'autre **prend**, et le changement de rôle vaut confirmation. **Un `handoff` reçu n'accorde rien à
personne : il affiche** (invariant 2 — aucun écran ne change de capacité sans un geste effectué sur
cet écran). Le rôle lui-même ne vient **jamais** d'un évènement, toujours de la lecture suivante :
un rôle qu'un évènement suffirait à changer serait un rôle que n'importe qui s'accorderait.

`handoff` passe donc **aux deux rôles**, client et serveur. Ce n'est pas un relâchement : il ne
change aucun état, et la frontière de sécurité est l'écriture du rôle — un `UPDATE` que la RLS
réserve déjà au propriétaire du partage. Le réserver au lead aurait interdit à l'invité d'**accepter**,
c'est-à-dire d'accomplir le temps que la doctrine exige de lui.

**L'offre se dit dans le quai, le geste vit dans le menu** — doctrine de « Recommencer le parcours » :
une rangée qui apparaîtrait dans la colonne d'action ferait remonter le contenu clinique, sur
évènement distant. Jeton `offert`, sept caractères, position constante. Et `grantLead` **rétrograde
d'abord, promeut ensuite** : dans l'autre sens, une coupure réseau entre les deux écritures
laisserait **deux** leads ; ici le pire cas en laisse **zéro** — dégradé, mais jamais ambigu.

### L'historique de sessions suit le compte
La table lève un invariant écrit du projet — « les sessions vivent en local, jamais synchro » — dont
le **mode exercice tirait sa garantie de non-contamination clinique**. Une bascule qui inverse une
promesse doit dire ce qu'elle change : elle est **opt-in, défaut fermé**, dans la fenêtre Compte,
avec une confirmation qui énonce la portée. Par **utilisateur**, pas par appareil — l'activer ici et
la découvrir éteinte ailleurs serait la pire des surprises.

Ce qui remplace l'invariant :

- **Seules les sessions archivées montent.** Une session **vive** resynchronisée serait un second
  canal de partage — sans code, sans rôle, sans péremption, et sans aucun des garde-fous du premier.
- **L'exercice est ségrégé par une colonne**, plus par la localité : la propriété devient une donnée
  que l'on filtre et que le serveur voit.
- **La trace do-verify ne monte pas**, et **son absence est dite**. Un drapeau fait écrire au compte
  rendu consulté ailleurs : « son détail reste sur l'appareil qui l'a produite ». Une trace absente
  qui ne s'annonce pas se lit *« aucune vérification n'a été faite »* — l'exact contraire de ce que
  la seconde passe existe pour établir.
- **`data` accepte dès aujourd'hui `{v:2, enc:<blob>}`.** C'est la seule décision de forme qu'il
  fallait prendre maintenant : elle devient irréversible dès qu'il y a des données en place, et
  passer au chiffrement de bout en bout ne demandera donc aucune migration.

Suppression = **pierre tombale** dès que la synchro est active (sinon la session effacée revient au
pull suivant depuis l'appareil qui l'ignore), suppression franche sinon. Le tableau de bord compte
les sessions et leurs octets — l'exploitant ne doit pas être aveugle au poste que l'option fait
croître (leçon v4.49.0).

### Le serveur cesse de faire confiance au client
Trois durcissements, annoncés comme ouverts en v4.53.1 :

1. **Liste blanche des clés de payload.** Le serveur ne validait que le **type** et la **taille** —
   c'est de là que partaient les deux injections de la v4.53.1. Il ne garde désormais que seize clés
   nommées. **`label` n'y est pas, et c'est le point** : la promesse « aucun texte libre ne traverse
   le réseau » cesse de dépendre d'une discipline de client. Liste blanche, jamais noire.
2. **Le libellé d'un participant** perd tout métacaractère de balisage. On ne recopie pas en SQL la
   liste des neuf rôles (elle dériverait) : on retire ce qui n'a rien à faire dans un nom.
3. **La coupure mord au serveur.** `share_pull` renvoyait `status: revoked` **et le flux complet** —
   c'était l'application du coupé qui gelait son écran, donc un client modifié continuait de lire.
   Il ne reçoit plus ni évènements ni participants ; le **statut**, lui, reste renvoyé — il faut
   qu'il sache, sinon la coupure passerait pour une panne de réseau. Le § 3.1 du registre, qui
   signalait ce point comme « à durcir », est mis à jour.

### Vérification
747 tests × 2 moteurs (+8), **250/250 contrôles partage** (+18, sur les deux moteurs), 13 harnais
verts, 301 contrôles d'accessibilité sur les deux moteurs, 94/94 doctrine, `npm run check` vert.
Trois assertions RLS nouvelles (§ 14.15 à 14.17) couvrent les trois durcissements — dont une qui
pousse un `label` et vérifie qu'il **ne survit pas à l'insertion**. Un test qui encodait l'ancien
contrat (`handoff` réservé au lead) a été retourné plutôt que supprimé : il affirme désormais la
règle inverse et dit pourquoi.

**`supabase/schema.sql` est à rejouer**, puis `rls-tests.sql`.

## [4.53.1] — 2026-07-28
### SÉCURITÉ — un participant pouvait injecter du balisage dans la checklist des autres

Trouvé en cherchant à répondre à la question « un tiers malveillant peut-il faire voyager du
texte ? ». La réponse est pire que la question : **pas seulement du texte, du balisage**. Deux
injections d'attribut, reproduites avant correction, fermées ici. Aucune ne demande de compte : il
suffit d'avoir rejoint une session avec un client modifié — la console du navigateur suffit.

### Deux routes, et la barrière n'était que sur l'une
Un évènement distant atteint l'écran par **deux chemins distincts** :

- la **peinture** (`sharePaintLive`), en direct — elle normalisait déjà (`safeId`, `tkRefNorm`) ;
- le **pli** (`shareFold` → `buildRuntime` → rendu), qu'empruntent **tout invité qui rejoint** — il
  reçoit l'historique depuis le début — et **tout invité qui recharge**. Il recopiait **brut**.

Une barrière sur une branche et pas sur l'autre ne protège rien. C'est la même leçon que la v4.42.0
(deux copies du cœur de cochage qui avaient divergé), à un endroit qui touche la sécurité.

**Défaut A — l'identifiant d'un repère.** `payload.id` d'un `mark`, recopié tel quel par le pli,
puis interpolé **sans échappement** dans cinq attributs du journal. Le genre `mark` est ouvert au
scribe : n'importe quel participant pouvait donc poser un identifiant qui **sort de son attribut**
et ouvre une balise dans le journal de tous les autres.

**Défaut B — les numéros de visite.** Seuls `Array.isArray` et l'égalité des longueurs étaient
vérifiés ; les **éléments** de `navSeq` ne l'étaient pas. Or `navSeq[i]` fabrique la clé de cochage
écrite dans `data-ck`, et le régime de `nav` est « anchored » — donc appliqué **en direct, sans
rechargement**, sur l'écran de chacun, **dans la liste d'étapes elle-même**. C'est du code que
j'avais écrit trois versions plus tôt.

### Ce que la CSP faisait, et ce qu'elle ne faisait pas
La CSP porte les hashs SHA-256 des scripts inline : sur un navigateur à jour, `'unsafe-inline'` est
ignoré et un `onerror=` injecté **ne s'exécute pas**. Mais `style-src 'unsafe-inline'` est accordé,
lui — du balisage et du CSS arbitraires **dans la colonne d'action d'une réanimation** (masquer une
étape, en superposer une fausse avec une autre dose) suffisent à qualifier le défaut. On ne s'abrite
donc pas derrière la CSP : elle est le second rempart, pas le premier.

### Trois couches, et chacune vérifiée SEULE
1. **Assainir à l'entrée.** Le pli passe désormais par les mêmes fonctions que la peinture, cas par
   cas : identifiants par `safeId`, horodatages par une conversion numérique explicite, références
   par `tkRefNorm`. Les valeurs fautives ne sont pas **rejetées** mais **ramenées** à quelque chose
   d'inoffensif — un évènement perdu en pleine réanimation serait pire qu'un identifiant régénéré.
2. **Borner les formes.** Une clé de cochage vaut `visite:bloc:index` et rien d'autre — un jeu de
   caractères fermé la rend sûre **comme index d'objet** (règle 6, `__proto__` compris) **et comme
   valeur d'attribut**, d'un seul geste. `shareNavNorm` est la barrière **unique** du couple
   `nav`/`navSeq`, partagée par le pli et l'application ancrée.
3. **Échapper à la sortie.** Sept interpolations d'attribut reçoivent `esc()`. Un attribut
   s'échappe même quand l'entrée est assainie : les deux barrières couvrent des chemins différents.

**Les deux couches ont été éprouvées indépendamment** : en retirant l'assainissement d'entrée,
l'échappement de sortie bloque encore l'injection ; en retirant l'échappement, l'assainissement la
bloque aussi. C'est ce qui distingue une défense en profondeur d'un empilement de précautions.

### Vérification
Dix contrôles permanents dans `audit-partage.mjs` (242/242 sur les deux moteurs), **vérifiés
capables d'échouer** : les défauts réintroduits à l'identique en font tomber trois, fichier restauré
à l'octet. Ils mesurent la **sortie de balise**, jamais l'exécution — c'est la propriété qui compte,
l'exécution n'en est qu'une conséquence parmi d'autres. 738 tests × 2 moteurs, 13 harnais verts,
301 contrôles d'accessibilité, 94/94 doctrine. **Rien à rejouer côté serveur** — mais le serveur ne
valide toujours que le **type** et la **taille** d'un payload, jamais ses clés : c'est le client qui
doit se défendre, et c'est désormais le cas aux deux entrées.

## [4.53.0] — 2026-07-28
### Le partage survivait à la session qu'il reflétait — et la cadence supposait qu'un soin fait du bruit

Trois signalements d'usage, dont un qui n'a été trouvé qu'en cherchant à répondre à une question
sur la fréquence de rafraîchissement.

### Terminer la session ne coupait pas le partage
Signalé : *« la fenêtre hôte affiche toujours partage en cours »*. Vérifié — `endSession` ne touchait
pas au partage. Celui-ci **survivait à la session qu'il reflétait** : la fenêtre continuait
d'annoncer un partage vivant, l'invité sondait un miroir que plus rien n'alimentait, et le code
d'appariement restait valide jusqu'à son terme. Un partage sans session n'a pas d'objet.

L'arrêt est **annoncé** au serveur mais jamais **attendu** (règle 12) : fermer sa session ne doit
pas dépendre du réseau. Si l'annonce échoue, la ligne expire et sera purgée — c'est exactement à
cela que sert un relais transitoire. Cinq contrôles, **vérifiés capables d'échouer** (le correctif
retiré en fait tomber quatre, fichier restauré à l'octet).

### L'inactivité du support n'est pas l'inactivité du soin
En répondant à la question *« à quelle fréquence, sans websocket ? »*, la mesure a montré un trou.
La cadence se dégrade avec l'inactivité : 2 s dans les trente secondes d'un geste, 5 s ensuite,
**10 s au-delà de deux minutes**. Or pendant un cycle de compressions de deux minutes, **personne ne
touche l'écran, des deux côtés** — et le premier geste à la fin du cycle, c'est-à-dire au moment
précis où le rythme se réévalue, pouvait mettre jusqu'à 10 s à apparaître chez l'autre.

Plancher de 5 s tant qu'une crise est à l'écran. Le surcoût est de six requêtes vides par minute ;
le coût inverse était un miroir qui retarde au pire instant. `crisisOnScreen` sert de prédicat —
le même que le quai et la mise en attente des banderoles, pas un second critère qui divergerait.

Latences réelles, calculées sur les constantes du fichier (poussée débouncée à 250 ms, gigue ±20 %) :

| Situation | Période | Latence moyenne | Pire cas |
|---|---|---|---|
| Dans les 30 s d'un geste | 2 s | 1,25 s | 2,65 s |
| De 30 s à 2 min | 5 s | 2,75 s | 6,25 s |
| Au-delà de 2 min, **crise à l'écran** | 5 s | 2,75 s | 6,25 s |
| Au-delà de 2 min, hors crise | 10 s | 5,25 s | 12,25 s |

**Ce que la cadence ne retarde pas, et c'est l'essentiel** : les minuteurs voyagent avec une **ancre
absolue**, donc les deux appareils calculent la même valeur en continu **sans rien échanger** — un
cycle de deux minutes est exact des deux côtés même hors réseau, et le passage à « échu » ne dépend
d'aucun sondage.

### « Exporter » ne disait pas quoi
Signalé : dans le menu ⋯, *« exporter PDF et json, pas clair si on parle d'exporter la fiche ou une
session »*. Le doute portait précisément sur ce qui compte, dans une vue où une session tourne et où
« Compte-rendu » est à portée. Les libellés nomment désormais leur objet — « Exporter **l'aide**
(.json) », « Exporter **le protocole** en PDF » — et le sous-titre nomme l'autre chemin plutôt que
de laisser le chercher : pendant une session, « la session s'exporte par *Compte-rendu* ».

### Vérification
738 tests × 2 moteurs (+4), **232/232 contrôles partage** (+5, sur les deux moteurs), 13 harnais
verts, 301 contrôles d'accessibilité, 94/94 doctrine, `npm run check` vert. Un contrôle du harnais
qui visait un libellé exact (`Exporter (.json)`) a été élargi au groupe : il aurait échoué au moindre
renommage sans que rien ne soit cassé. **Rien à rejouer côté serveur.**

## [4.52.0] — 2026-07-28
### Le journal parle enfin des deux côtés — sans qu'un seul mot traverse le réseau

Lot 5 du chantier de partage. Un repère du journal voyageait comme `{identifiant, heure}` et rien
d'autre : chez l'invité, il s'affichait « Action 3 ». L'heure était juste — c'est ce qui compte
cliniquement — mais le mot manquait, et le compte rendu d'un même soin devenait difficile à
recouper.

### Une référence, jamais un mot
Un repère porte désormais une **référence**, et chaque appareil rend le libellé depuis **sa** copie
de la fiche. C'est ce qui tient la règle 15 sans condamner le journal au mutisme. Quatre sources,
cumulatives :

1. **La fiche elle-même** — minuteurs, compteurs, étapes, repères posologiques. Toute aide apporte
   son vocabulaire sans qu'on ait rien à déclarer, et il suit ses mises à jour.
2. **Un noyau universel livré** — ce qui se note dans toute intervention : renfort, régulation,
   départ de la base, arrivée sur place, bilan, transmission, relève, départ, arrivée à l'hôpital.
   **« Autre » n'y est pas, et ce n'est pas un oubli** : l'absence de référence *est* « autre », et
   une étiquette qui ne distingue rien n'apprend rien à qui relit.
3. **Le vocabulaire personnel, avec alias** — édité **à froid** dans la fenêtre Compte, synchronisé
   comme le thème. C'est là que vivent les abréviations qu'on se découvre à l'usage : « mru »
   trouve « Médecin régulateur ».
4. **Rien du tout**, et c'est le cas nominal. « Noter l'heure » reste **un tap** : l'heure est
   capturée, toujours, sans dépendre d'aucun vocabulaire. L'étiquetage est facultatif. Pire cas
   d'un vocabulaire incomplet : un repère non étiqueté côté partagé, et le mot exact **en local**
   chez celui qui l'a tapé.

**La résolution échoue proprement**, et c'est cette garantie qui autorise à faire voyager des
références : fiche d'une autre version, étape supprimée, étiquette effacée — le repère retombe sur
« Action n », **jamais sur un mot inventé**. Six contrôles l'encodent.

**On réordonne, on ne filtre jamais** — la règle des repères posologiques, appliquée telle quelle,
avec la même machinerie (troncature à partir de quatre caractères, table de synonymes). Un faux
positif coûte un rang ; un faux négatif coûte un mot au moment où on le cherche.

### Ce qui ne pouvait pas être une fenêtre
La règle 11 interdit les modales pendant un soin. Les propositions sont donc une rangée de chips
**sous** la ligne du journal — lequel vit en fin de rail, si bien que ce qui apparaît pousse vers le
bas et jamais vers le haut. Cibles 44 px, rien sous deux caractères saisis (tout ressemble à tout),
quatre propositions au plus.

Tant qu'aucune proposition n'est choisie, **le texte tapé reste strictement local** : mesuré, il
n'entre pas dans ce qui est émis. Choisir pose la référence et efface le libellé manuel — le mot
devient dérivé, donc identique sur les deux écrans.

**Une asymétrie est dite plutôt que tue** : une étiquette *personnelle* se résout sur les appareils
du même compte, pas chez un collègue qui ne l'a pas. Pendant un partage, elle est donc marquée
« · vous seul ». La taire aurait laissé croire à un mot partagé.

### La règle 15 vaut aussi à la réception
La réception d'un repère distant lisait un `label` venu du réseau. Inoffensif entre deux clients de
cette version — aucun émetteur n'en met — mais c'était une **porte** : un client modifié aurait
affiché un mot arbitraire sur l'écran d'en face. La lecture est supprimée ; le libellé se dérive de
la référence, et de rien d'autre. Le contrôle du harnais qui vérifiait l'inverse — il **encodait le
trou** — a été retourné : il pousse maintenant un `label` hostile et vérifie qu'il n'apparaît nulle
part.

### Un défaut d'accessibilité sur iOS, trouvé en jouant le harnais sur le bon moteur
Le `<select>` de rôle de l'écran d'entrée mesurait **23 px de haut sur WebKit** contre 44 sur Blink
— sous le plancher de cible, sur le seul écran qu'un invité sans compte verra jamais, et sur la
cible principale déclarée du projet. Invisible tant que le harnais d'accessibilité ne tournait que
sur Chromium : c'est la leçon de la v4.45.0, redite. Hauteur explicite et chevron dessiné
(`appearance:none` — sans lui, imposer une hauteur à un select natif iOS ne déplace pas son texte).

### Vérification
734 tests × 2 moteurs (+28), **227/227 contrôles partage** (+13, sur les deux moteurs), 13 harnais
verts, 301 contrôles d'accessibilité **sur les deux moteurs**, 94/94 doctrine, `npm run check` vert.
Le contrôle « le texte tapé n'est pas émis » est vérifié **capable d'échouer** (le libellé remis
dans l'instantané le fait tomber, fichier restauré à l'octet). Le commentaire de modèle du fichier,
qui décrivait un repère par trois clés depuis l'origine, en décrit désormais les huit — et dit
lesquelles voyagent. **Rien à rejouer côté serveur.**

## [4.51.0] — 2026-07-27
### Le miroir se figeait au premier « Continuer » de l'hôte

Annoncé en fin de v4.50.0, corrigé ici. Deux défauts, et le second n'était visible que parce que le
premier le masquait.

### La file était remplie et jamais vidée
`SHARE_APPLY` distingue trois régimes et les motive : `live` (chirurgie pure dans la checklist),
`anchored` (« reconstruit le journal, **donc** ancré et annoncé »), `deferred` (attend un geste
local). **Une seule ligne rangeait `anchored` et `deferred` dans la même file** — laquelle n'était
drainée nulle part.

Conséquence, mesurée : après une navigation distante, `Runtime.nav` ne contenait pas le bloc cible ;
au grep, aucun site de drainage. **L'invité voyait les coches du bloc courant, et plus rien
ensuite** — le contraire d'un miroir, et la fonction même pour laquelle le partage existe. C'est la
quatrième moitié de chemin de ce chantier, après `canWrite()` sans appelant, l'annexe d'un détaché
que personne ne lisait, et `fold.exercise` sans émetteur.

Une navigation distante s'applique désormais **ancrée** : on mesure la position d'un repère, on
re-rend, on compense le résidu — dérive **0 px** mesurée. Et on ne défile **pas** vers la nouvelle
carte : le geste n'est pas le sien. C'est la différence exacte avec `ovAdvanceRender`, qui défile
parce que c'est l'utilisateur qui vient d'appuyer sur « Continuer ».

Deux pièges rencontrés, tous deux attrapés par la sonde et non par la relecture : `state.nav` est un
**alias** du tableau de `Runtime` — lui affecter un tableau neuf casse l'alias en silence, et
l'application se met à lire deux navigations différentes selon l'endroit ; et `Runtime.seq` doit
être relevé au maximum des numéros reçus, faute de quoi une visite locale ultérieure réutiliserait
un numéro déjà pris — **deux passages partageraient alors leurs clés de cochage**.

### Le mode lecteur inverse la règle, et il le dit
Sa clé d'étape est calculée **au clic** depuis `state.nav`, jamais depuis le DOM peint : une
navigation distante arrivant entre le `pointerdown` et le `click` ferait cocher **la mauvaise
étape**, et le compte rendu l'imprimerait comme réalisée. Tant que le lecteur est ouvert, une
navigation distante est donc **refusée** — et **annoncée sur place** : « Le soignant a avancé —
reprendre à sa position », registre INFORMATION, levée par un geste local. Ne pas suivre en silence
était le pire des deux mondes : l'autre a avancé, et celui qui lit à voix haute l'ignore.

### Un rechargement ne perd plus la session
Un onglet mobile meurt tout seul — iOS recycle les onglets en arrière-plan — et l'invité perdait sa
participation **sans retour** : rien n'était persisté, et son code d'appariement est consommé, donc
il ne pouvait pas rejoindre. C'était l'invariant « l'invité ne garde rien » appliqué au-delà de ce
qu'il protège.

Un **billet** est écrit dans le `sessionStorage` : l'identifiant du partage et le secret,
**aucune donnée clinique** — vérifié par un contrôle qui cherche le titre de la fiche dans le
billet. Sa portée est *cet onglet, cette navigation* : effacé à la fermeture, jamais partagé, hors
IndexedDB et hors `localStorage`. L'étanchéité est tenue là où elle compte — rien de **durable** sur
le téléphone d'un tiers. Il survit à `freeze` (le lien meurt, l'écran reste) et meurt avec `stop`
(l'écran est quitté) ; un serveur qui refuse l'efface plutôt que de le laisser traîner.

Côté serveur, `share_pull` renvoie la fiche **uniquement sur une reprise complète** (`p_since = 0`,
et jamais à l'hôte) : les sondages ordinaires passent toutes les deux à dix secondes et n'ont aucun
besoin d'un instantané de plusieurs dizaines de kilo-octets. Aucune donnée nouvelle ne sort — c'est
le même instantané, filtré par la même liste blanche, que la jointure avait déjà remis.

### Vérification
706 tests × 2 moteurs, **214/214 contrôles partage** (+22, sur les deux moteurs), 13 harnais verts,
9/9 QR, 301 contrôles d'accessibilité, 94/94 doctrine, `npm run check` vert. Les dix contrôles du
miroir ont été **vérifiés capables d'échouer** : le défaut réintroduit en fait tomber cinq, fichier
restauré à l'octet. Le registre RGPD (§ 3.1) et `AGENTS.md` sont mis à jour dans le même commit —
le billet est une exception à un invariant écrit, elle se documente là où l'invariant est écrit.

**`supabase/schema.sql` est à rejouer** (`share_pull` seul est modifié), puis `rls-tests.sql`.

## [4.50.0] — 2026-07-27
### La conformité écrite noir sur blanc — et le placard d'exercice qui ne traversait pas le partage

Lot 7 du chantier de partage : la documentation opposable. Traité **avant** les lots 5 et 6, et pas
par ordre de numéro — c'est le seul reliquat qui engage l'établissement. Trois signalements d'usage
sont corrigés au passage, et un défaut a été trouvé **en écrivant la documentation**, ce qui est
exactement à quoi elle sert.

### Le placard d'exercice ne traversait pas
`openSharedFiche` lisait `fold.exercise` — **et aucun émetteur ne l'a jamais posé**. Moitié de
chemin écrite, la ligne se lisant comme si elle marchait : troisième occurrence dans ce chantier,
après `canWrite()` sans appelant et l'annexe d'un détaché que personne ne lisait.

Mesuré, témoin à l'appui : hôte en répétition = bandeau hachuré, en-tête hachuré, pilule
« ▲ Exercice », chrono « ▲ Exercice » ; **invité = « ■ Crise » et « ● Session »**. Un renfort qui
rejoint une répétition en la croyant réelle est précisément ce que le placard TRAINING existe pour
empêcher — l'annonciation **est** la raison d'être du mode exercice (v4.27.0), le reste étant
identique par construction.

Le drapeau voyage désormais sur `session_start`, et ce véhicule n'est pas un pis-aller : le drapeau
est posé par `startExercise`, qui passe par `freshRuntime` — il ne peut donc changer **qu'avec** le
démarrage. Aucun genre nouveau, donc **aucun schéma à rejouer** ; et `session_start` étant déjà
réservé au lead, un scribe ne peut pas déguiser une session réelle en répétition. Cinq tests, dont
**trois tombent** quand on réintroduit le défaut (fichier restauré à l'octet). « Quitter
l'exercice… » disparaît chez l'invité : le bouton appellerait `quitExercise` sur **son** Runtime
sans rien changer chez l'hôte — un contrôle qui ment sur sa portée.

### Trois signalements d'usage
**La fenêtre d'entrée n'avait pas de sortie.** Elle a été conçue comme le *remplacement* de
l'application sur un appareil vierge, où il n'y a rien derrière et où une croix ne mènerait nulle
part. Mais on y arrive aussi **depuis l'accueil**, en tapant le code dans la recherche : une
application tourne alors derrière, et un code mal recopié enfermait l'utilisateur. Croix, Échap et
retour système — les trois par le même chemin, comme le veut la doctrine des fenêtres —, affichés
**uniquement** s'il y a un « derrière ».

**L'hôte dictait un code déjà mort.** `share_join` met `code_hash` et `join_open_until` à NULL : la
porte se referme **derrière celui qui entre**, avant l'échéance des 120 s. L'hôte, lui, gardait sa
copie et affichait le code *avec son décompte* — « ouvert encore 97 s » sur une porte fermée. C'est
la donnée périmée présentée comme vivante, danger n°2 du palmarès ECRI 2015, que la doctrine du quai
nomme déjà pour les minuteurs. Corrigé **sans toucher au schéma** : une jointure est la seule chose
qui consomme un code, donc l'apparition d'un participant *est* l'observation. Le code et son QR
disparaissent, la fenêtre dit « **Untel a rejoint — le code a servi** », et « Nouveau code » devient
l'action évidente. Bénéfice second, non cherché : l'hôte obtient enfin l'**accusé de réception**
d'appariement que l'échange en trois temps suppose (AC 61-115).

**Le mode lecteur ne suivait pas.** Il vit hors de `main`, que `sharePaintLive` est seul à peindre :
mesuré, coche distante appliquée à l'état et peinte dans le journal (témoin `done` posé), **lecteur
inchangé** — le binôme qui lit à voix haute annonçait « suivant : … » sur une étape déjà faite.
Il se repeint désormais **à position conservée** : `_rmSync` remet le curseur à zéro et ferait
sauter le lecteur au premier item non coché, ce qui serait un mouvement autonome sous ses yeux.
La première sonde écrite pour ce défaut mesurait le **chrono** du lecteur et le voyait donc changer
à chaque seconde : elle a été refaite avant toute conclusion.

### La conformité, sourcée ligne à ligne
`docs/deploiement-et-conformite.md` affirmait encore « **Sessions : locales à l'appareil** » — faux
depuis la v4.46.0 — et sous-évaluait la conservation. Nouveau **§ 3.1** qui énumère, avec le SQL en
regard : les **14 champs** de la liste blanche serveur (et ce qu'elle retire — images, documents,
et `localInfo`, pré-rempli des téléphones de renfort et de régulation) ; ce qu'un geste transmet
(une référence et une heure — le libellé d'un repère **reste sur l'appareil qui l'a écrit**) ; ce
qu'est l'identité d'un participant (un identifiant opaque tiré par le serveur, un rôle choisi dans
une liste fermée de neuf intitulés) ; et les durées **mesurées** : fenêtre d'admission 120 s, partage
3 h par défaut borné à 12 h, purge 30 min après expiration, en cascade, déclenchée **en tête de
chaque appel** faute de tâche planifiée sur un hébergement statique.

Deux précisions qu'une lecture rapide du schéma ne donne pas, et qu'un DPO doit avoir : le contrôle
d'accès des invités **ne repose pas sur la RLS** mais sur la possession d'un secret (trois fonctions
`security definer`, seule surface non authentifiée de l'installation) ; et « couper un participant »
retire **l'écriture**, pas la lecture — le serveur lui répond `revoked` et c'est **son application**
qui gèle son écran. La formulation affichée à l'hôte est exacte sur ce point et ne doit pas être
élargie ; le durcissement serveur est identifié.

Le **§ 2** passe le partage à la grille MDCG 2019-11 : il ne calcule rien, il **recopie** un état
d'un écran à l'autre — qualification « communiquer ». L'argument contraire est écrit **et** réfuté
(il prouve trop : il vaudrait pour un tableau blanc), et la ligne à ne pas franchir est nommée — le
jour où le partage **déduirait** quelque chose de l'état partagé, la qualification serait à rouvrir.
Précaution de vocabulaire conservée : ne jamais présenter le partage comme un outil de *supervision*.

`AGENTS.md` reçoit une section « partage de session » complète et une **règle 15** — miroir additif,
jamais une dépendance ; aucun texte libre sur le réseau. Ses compteurs périmés sont corrigés :
onze → **treize** harnais, ~12 250 → **~14 400** lignes, 20 → **21** fenêtres modales, 22 → **25**
surfaces auditées en accessibilité.

### Ce qui reste, et qui est dit ici plutôt que découvert plus tard
La file `_defer` est **remplie et jamais vidée** : tout ce qui est classé `anchored` (`nav`,
`flow_end`, `cx`) ou `deferred` (`verify`, `gap`) n'atteint jamais l'écran de l'invité — **le miroir
se fige dès que l'hôte change de bloc**. Mesuré (`Runtime.nav` ne contient pas le bloc cible après
une navigation distante) et confirmé au grep (aucun site de drainage). Le commentaire de
`SHARE_APPLY` décrit pourtant le bon comportement. Et un invité qui recharge sa page **perd tout** :
rien n'est persisté, le code est consommé, il ne peut pas revenir. Les deux sont la prochaine
version.

706 tests × 2 moteurs (+5), 13 harnais verts, **192/192 contrôles partage** (+8, sur les deux
moteurs), 9/9 QR, 301 contrôles d'accessibilité, 94/94 doctrine, `npm run check` vert. **Rien à
rejouer côté serveur.**

## [4.49.0] — 2026-07-27
### Le repli hors dispositif, le bridage du scribe, et le filtre de contenu qui n'existait qu'en JavaScript

Dernière version du chantier de partage. Elle apporte les deux fonctions qui manquaient — poursuivre
seul quand le lien tombe, et brider le scribe sans rien lui masquer — et referme côté SERVEUR ce que
seul le client protégeait.

### « Continuer seul » : la trace remonte, l'état non
Le serveur savait tout faire depuis la v4.46.0 — colonne `detached_at`, genre `detach` autorisé,
règle « un lot qui porte un detach ne porte que lui », assertions RLS — mais **aucun code client ne
l'appelait**, et l'annexe qu'un détaché peut remonter n'était lue par personne. Quatre murs, tous
tombés :

**Au détachement, la file était JETÉE.** Au moment précis où la bifurcation devient officielle, on
détruisait la seule chose qui devait encore remonter. Elle est désormais **convertie** : chaque
geste en attente devient un `offline_mark`, qui rejoint le journal de l'hôte en annexe. Un détaché
ne peut plus écrire d'ÉTAT — ses coches porteraient sur des passages que l'hôte a quittés — mais il
peut écrire des repères horodatés : une heure reste une heure.

**Un détaché cessait de sonder.** Ses annexes n'auraient donc jamais atteint l'hôte. Un cycle lent
reste armé tant que sa file n'est pas vide.

**Chez l'hôte, l'annexe entre au journal et NULLE PART ailleurs**, à sa place chronologique, inerte
(ni champ ni bouton — on ne corrige pas le relevé d'un autre), avec la mention « rapporté — poursuit
seul ». L'état ne fusionne jamais : après la bifurcation, les numéros de visite sont mintés
indépendamment des deux côtés, si bien que « la visite 6 » de l'un et celle de l'autre désignent
deux passages différents. Ce n'est pas un conflit arbitrable, c'est une collision d'espace de noms —
fusionner produirait un résultat non pas discutable mais **faux, et plausible**.

### Le scribe ajoute, il ne défait pas
Forme canonique du travail à deux (AC 120-71B §5.2.2.1), pas un compromis. Ouvert au scribe : cocher,
constater, signaler un écart, **incrémenter** un compteur, **armer** un minuteur, poser et annuler un
repère. Fermé : décocher, avancer, terminer, choisir une branche, sauter à un bloc, **arrêter** ou
remettre à zéro. La distinction n'est pas arbitraire — ajouter est additif et réversible par le
journal, remettre à zéro détruit un décompte que personne ne peut restituer.

**Jamais par masquage** : masquer ferait sauter le contenu clinique de 46 px (mesuré), et sur
évènement DISTANT si le rôle change — sous le doigt de quelqu'un qui n'a rien demandé. La boîte
reste, la géométrie est identique refus ou non (mesuré ≤ 1 px), et le refus s'annonce sur `#srLive`,
seul canal admis pendant un soin.

**Une seule liste de verbes**, consommée par le CSS et par une garde déléguée en phase de capture ;
un contrôle du harnais lit la liste **depuis le script** et vérifie que chaque élément rendu porte
l'apparence désactivée — c'est la faille de la v4.42.0 prise à la racine. Deux gestes dépendent de
leur DIRECTION et ne peuvent pas être bridés en CSS : le cochage (`data-ck` porte cocher *et*
décocher) et le minuteur (armer *ou* arrêter) ; ils sont gardés dans leurs handlers, et pour le
cochage par un prédicat **unique** appelé aux deux copies du cœur.

### Le serveur ne se fiait qu'au client
**La liste blanche des champs de fiche n'existait qu'en JavaScript.** Un appel REST direct la
traversait : `images` (jusqu'à 24 Mo de base64), `localInfo` (les téléphones de renfort et de
régulation), la liste des documents, `ownerId`, `libraryId` — tout pouvait partir. Le schéma avait
pourtant déjà tiré cette leçon pour la TAILLE (« le plafond vaut contre le client ») sans jamais
l'appliquer au CONTENU. C'est une liste **blanche**, pas noire : on ne garde que les quatorze champs
autorisés, une liste noire oubliant ce qu'on ajoutera demain. Les images de BLOC sont retirées
séparément, elles vivent à l'intérieur de `blocks`.

**`is_approved()` traitait un JWT anonyme comme un compte approuvé.** Un tel jeton porte un
`auth.uid()` non nul et n'a aucune ligne dans `user_status` : le `coalesce` retombait sur
`'approved'` — y compris pour ouvrir un partage, c'est-à-dire faire sortir du contenu clinique de
l'instance. La porte n'était fermée que parce que personne n'avait activé l'option au tableau de
bord ; elle l'est maintenant par le schéma.

**`share_admit` ouvrait deux boucles infinies.** Il ne vérifiait ni l'expiration ni le quota : sur un
partage expiré ou plein, il rendait un code NEUF que l'hôte dictait et que `share_join` refusait
aussitôt, sans que personne, des deux côtés, ne puisse comprendre — et il écrasait au passage un code
peut-être encore vivant. Le motif est désormais détaillé, parce que l'appelant est le propriétaire
authentifié : l'argument d'oracle ne vaut que face à un anonyme, et le schéma le promettait sans
l'appliquer nulle part.

S'ajoutent un **plafond de cinq partages vivants par propriétaire** (il n'en existait aucun, alors
qu'un compte coûte une adresse jetable), le bornage de `session_id` — seul champ texte libre non
contraint —, les **octets des partages dans le total de stockage** et leur affichage au tableau de
bord (le serveur les calculait, l'écran ne les montrait pas : l'exploitant était aveugle au seul
poste que le partage fait croître), et le genre **`session_start`** : l'heure du soin voyage,
réservée à celui qui conduit. Un renfort arrivé à 14 h 12 sur une réanimation débutée à 13 h 55 ne
date plus le début du soin à son arrivée.

### Quatre signalements d'usage, et ce qu'ils étaient vraiment
**Le code du partage ne grandissait pas.** Il a été agrandi trois fois sans le moindre effet à
l'écran : `.ai-card p` pèse (0,1,1) — une classe ET un type — et l'emportait sur `.sh-code` (0,1,0)
en le ramenant à 13 px, **quel que soit l'ordre de déclaration**. C'est le 7ᵉ incident de cascade du
projet et le premier par SPÉCIFICITÉ ; les six précédents tenaient à l'ordre. Toute la typographie
des deux fenêtres passe par des sélecteurs à `#id`, et un contrôle mesure désormais la taille
**rendue**, jamais la valeur écrite. Le code fait 40 px (34 sous 360).

**Le QR portait le code seul.** Une « correction » de la veille faisait retomber `localhost` sur le
code, ce qui privait de la fonctionnalité au moment même où on l'essaie : toute origine http(s)
donne à nouveau l'URL complète, et le **lien entier est écrit en clair** sous le QR, sélectionnable
d'un appui — c'est lui qu'on dicte ou qu'on envoie quand la caméra ne sert pas. Le harnais QR, lui,
ne décodait que la MATRICE : il capture maintenant l'**image réellement peinte** et la donne au
décodeur d'Apple, à quatre configurations dont le thème sombre.

**La confirmation d'arrêt s'affichait derrière la fenêtre** (z-index 55 contre 94) : invisible, avec
le focus piégé dedans. Portée à 95.

**Les deux fenêtres du partage étaient les plus étroites de l'application** (420 et 460 px) : elles
prennent `dlg-480`, la largeur standard partagée par cinq autres. Et sous 780 px, où l'app transforme
toute fenêtre en feuille pleine largeur, leur contenu — majoritairement centré — courait d'un bord à
l'autre : mesuré, carte 744 × 1133 px pour 643 px de contenu. Le CORPS est borné à 460 px ; le titre
et le ✕, eux, restent au bord de la feuille, **identiques au pixel à une fenêtre existante** (mesuré
contre `#catModal` à 390, 744 et 1280 px) — fermer une fenêtre est le geste le plus appris de
l'application, le déplacer pour une seule d'entre elles était une faute.

### Rejoindre se tape dans la recherche
La rangée était dans le dialogue « Créer » : rejoindre n'ajoute rien à la bibliothèque, et quelqu'un
à qui l'on dicte un code n'irait pas le chercher sous « + ». Une ligne permanente en tête d'accueil a
été essayée puis écartée — 44 px d'attention à chaque ouverture pour un geste rare, alors que la
doctrine ECAM réserve le permanent à ce qui sert la conduite en cours. **Le code se tape dans le
champ de recherche** : huit caractères d'un alphabet fermé sont reconnaissables sans ambiguïté, la
ligne s'AJOUTE aux résultats sans les remplacer, et l'accueil au repos est **identique au pixel**
(mesuré). Registre INFORMATION, bouton rempli : à l'instant où elle paraît, elle est la seule action
de l'écran.

### Vérification
701 tests × 2 moteurs (+4), 13 harnais verts, **184/184 contrôles partage** (+41, sur les deux
moteurs), 9/9 QR, 301 contrôles d'accessibilité, 94/94 doctrine, `npm run check` vert. Quatre
assertions RLS nouvelles (§14.11 à 14.14) couvrent la liste blanche serveur, le plafond de partages,
les deux refus de `share_admit` et la réserve de `session_start`. `supabase/schema.sql` et
`rls-tests.sql` ont été rejoués sur l'instance avec succès.

Trois contrôles écrits pendant ce chantier ont dû être **corrigés parce qu'ils mesuraient le
mécanisme et non la propriété** : « le mode d'application vaut `none` » là où il fallait vérifier que
l'annexe ne touche pas l'état, « `started` vaut faux » là où il fallait vérifier qu'aucun dossier
n'est créé, et « pas de lien en local » qui encodait une règle infirmée. C'est la même erreur que la
taille du code, sous une autre forme : vérifier ce qu'on a écrit plutôt que ce que ça produit.

## [4.48.0] — 2026-07-27
### Le partage fonctionne enfin de bout en bout — et le miroir de l'invité était en lecture seule

Cette version rend le partage RÉEL : l'hôte peut l'ouvrir, montrer un code, voir qui a rejoint,
couper quelqu'un, arrêter. Et surtout, les gestes voyagent — ce qui n'était pas le cas.

### Le défaut central, trouvé par contre-expertise dans le code de la version précédente
**Les coches de l'invité ne quittaient jamais son téléphone.** L'émission s'accroche à
`persistLive`, qui sort immédiatement si la session locale n'a pas démarré — or l'invité avait
`started=false` par construction, et **une trentaine de sites de mutation sont eux-mêmes gardés par
`if(Runtime.started)`**. Le miroir était donc en lecture seule, silencieusement. C'est mot pour mot
le pire mode de défaillance nommé au plan de ce chantier : *cocher dans le vide en croyant
contribuer à une réanimation en cours*.

Le correctif inverse la logique. Sa session EST vive — c'est celle de l'hôte, il la suit et il y
contribue — donc `started` vaut vrai chez lui. Ce qui lui est refusé n'est pas la session, c'est
l'**enregistrement**, et ce refus vit désormais là où il a un sens, dans `persistLive` : aucune
écriture dans son stockage, aucune entrée dans son historique. Le contrôle censé couvrir cela
mesurait le MÉCANISME (`started === false`) au lieu de la PROPRIÉTÉ ; il mesure maintenant
l'étanchéité réelle — zéro session archivée, zéro session vive, aucun dossier — **et** que ses
gestes partent bien sur le fil.

Trois défauts de la même famille, tous dans du code écrit la veille : `canWrite()` — le prédicat qui
doit retirer l'écriture à un invité coupé ou périmé — **n'avait aucun appelant**, alors que le
commentaire attenant promettait « un invité périmé ou coupé PERD VISIBLEMENT l'écriture » ; le
compte de participants du quai filtrait sur `revoked_at` quand le serveur envoie `revoked`, si bien
que l'hôte aurait lu « ⇄ 2 » avec un seul participant présent ; et l'acteur d'un repère se perdait à
la peinture, rendant tout compte rendu inattribuable.

### Émission par différence — un seul point d'accroche
Le recensement avait trouvé **soixante verbes de mutation** (41 attributs `data-*` et 19 contrôles à
`id`). Les instrumenter un par un garantissait l'oubli, et surtout l'oubli SILENCIEUX de toute
mutation ajoutée plus tard. On DIFFE donc l'état, en un seul endroit : ce qui est couvert par
l'enregistrement local l'est mécaniquement par le partage. `shareSnap` et `shareDiff` sont PURS,
donc testables sans navigateur, sans réseau et sans horloge — et le test qui compte est
l'**aller-retour** : émettre puis plier redonne l'état de départ (coches, compteurs, minuteurs,
navigation, repères, annulations, trace do-verify). L'ouverture d'un partage **verse l'état courant
dans le fil** : l'instantané transmis est la FICHE, jamais la session, donc un partage ouvert après
vingt coches aurait sinon laissé l'invité devant une fiche vierge, à jour et fausse.

### La fenêtre d'appariement de l'hôte
Ordre imposé par la mesure, pas par l'esthétique : titre de l'aide et **code** en haut (ce qui se
dicte à voix haute), QR ensuite et plafonné, participants, arrêt en pied. Elle **ne verrouille pas
le fond** (`sheet-live`) : toute `.ai-modal` fige le défilement derrière elle au pointeur grossier,
et celle-ci reste ouverte pendant toute la fenêtre d'admission — la checklist de crise de l'hôte
serait devenue indéfilable au moment où elle sert.

**Couper quelqu'un n'est jamais peint de façon optimiste** : la rangée affiche « coupure… » et
n'accepte « coupé » que lorsque le sondage le rapporte ; le harnais mesure les deux moments, y
compris le RETOUR EN ARRIÈRE quand la requête échoue — un bouton qui laisserait « coupé » affiché
après un échec dirait à l'hôte qu'il a retiré un accès qu'il n'a pas retiré. Et « Arrêter le
partage » ramène `expires_at` à maintenant : le code s'aligne sur la promesse de purge faite à
l'invité, au lieu qu'on affaiblisse la promesse.

### Quatre défauts signalés à l'usage, et ce qu'ils étaient vraiment
**Le QR n'était pas corrompu : il contenait une adresse injoignable.** Il encodait
`location.origin + …` — servi depuis un poste de développement, cela donne une adresse LOCALE, que
l'iPhone décode et ne peut pas ouvrir : « aucune donnée utilisable trouvée ». Désormais, si
l'adresse n'est pas joignable depuis un autre appareil (fichier local, origine nulle, `localhost`),
c'est le **code seul** qui est encodé — le téléphone l'affiche comme texte — et la fenêtre le dit.
Le harnais QR, lui, ne décodait que la MATRICE : il était **aveugle à tout ce qui se passe entre
l'encodeur et l'appareil photo** (génération du SVG, variables CSS, `shape-rendering`, taille en
`vw`, rendu sous-pixel). Il capture maintenant l'IMAGE RÉELLEMENT PEINTE et la donne au décodeur
d'Apple, à quatre configurations dont le thème sombre.

**La confirmation d'arrêt s'affichait DERRIÈRE la fenêtre** : `#confirmModal` héritait du z-index 55
des fenêtres ordinaires alors que l'appariement est à 94 — dialogue invisible, focus piégé dedans.
Porté à 95, au-dessus des deux fenêtres hautes et sous le flash d'alarme.

**L'écran d'entrée ne suivait pas la grammaire de l'app** : il n'utilisait pas `.ai-card`, donc ni
son `margin:auto` (le centrage vertical de toutes les fenêtres), ni son échelle typographique — à
760 px la carte restait collée en haut, au-dessus de 450 px de vide. Et en la recalant, le **6ᵉ
piège de cascade du projet** : `.join-card` et `.ai-card` ont la même spécificité, la
`max-width:720px` déclarée plus bas l'emportait et la carte s'étalait sur 700 px. Sélecteurs par
`#id` pour les deux fenêtres, comme la règle l'impose pour toute géométrie.

**L'écran de saisie du code était introuvable sans QR.** Il est joignable depuis le dialogue
« Créer », sous un filet et formulé comme une question (« Un collègue partage sa session ? — ⇄
Entrer un code ») : c'est le seul point d'entrée atteignable à TOUTES les largeurs, l'accueil n'ayant
ni menu ⋯ ni barre latérale sous 780 px. Et l'**adresse de jointure est écrite en clair sous le QR**
— c'est elle qu'on dicte quand le scan ne peut pas servir.

Le code passe à **40 px** (34 sous 360 px), le champ de saisie de l'invité à 26 px. Cela a fait
tomber un contrôle, et c'est lui qui avait tort : il exigeait « Arrêter le partage » visible sans
défiler à toutes les largeurs, alors qu'à 320×568 la carte fait 734 px — aucune mise en page
honnête ne tient dans 568. L'objection d'origine disait autre chose : ce bouton ne doit jamais se
retrouver DANS une liste qui grandit, et doit rester atteignable. C'est ce qui est mesuré.

### Le miroir de l'invité
Le bouton « Confirmé — démarrer la session » — contrôle plein, le plus visible de l'écran — était
rendu chez lui alors qu'il ne démarre rien : retiré. L'entrée se fait au BOUT du journal et non en
tête de fiche (mesuré : la première étape cochable tombait à y=827 pour un écran de 844, et y=910
pour 568 — hors champ aux deux largeurs) ; le titre reste lisible par le relais d'en-tête, comme
pour tout utilisateur qui défile. Une annonce sans pixel (`#srLive`, seul canal admis pendant un
soin) dit ce qu'il suit.

**Et il a enfin une porte de sortie.** `Share.stop()` n'avait AUCUN appelant : le seul geste
disponible changeait la vue en laissant le mode et le sondage armés, sans chemin de retour. Le menu
⋯ de l'invité porte « Quitter le partage… », et le départ est SILENCIEUX côté serveur —
`Share.stop()`, jamais `emit('detach')` : un `detach` DATE un « je poursuis seul » dans le compte
rendu de l'hôte, or quelqu'un qui ferme son écran n'a rien affirmé de tel. Le même menu perd les
rangées qui, chez lui, étaient fausses ou muettes (exercice, recommencer, modifier, versions,
dupliquer, exports).

**Une incohérence d'étanchéité fermée au passage** : `beforeprint` n'était gardé que par la vue. Un
invité qui faisait Partager → Imprimer obtenait la fiche ENTIÈRE, mise en page pour le papier —
pendant qu'on lui refusait l'export du compte rendu au nom de cette même étanchéité.

### La rangée « Partager la session » n'est plus jamais grisée
La contrainte reste réelle (sans session démarrée, la première action de l'invité déclencherait un
re-rendu complet sous le doigt de l'hôte), mais la faire porter par une rangée MORTE obligeait à
deviner l'ordre des gestes. Elle propose maintenant de démarrer, par un dialogue qui dit ce que cela
engage — chrono, minuteurs, journal, entrée à l'historique : une session ne commence pas par
surprise au détour d'un menu.

### Vérification
691 tests × 2 moteurs (+2), 13 harnais verts, **124/124 contrôles partage** (+69, sur les deux
moteurs), **9/9 QR** (dont 4 sur l'image peinte), 301 contrôles d'accessibilité, 94/94 doctrine,
`npm run check` vert. Les nouveaux contrôles ont chacun été vérifiés capables d'échouer.
`supabase/schema.sql` est INCHANGÉ dans cette version : rien à rejouer.

## [4.47.0] — 2026-07-27
### Le transport du partage, la moitié invité — et ce qu'une contre-expertise a trouvé dans le code existant

Suite du chantier ouvert en v4.46.0. Un collègue peut désormais **rejoindre** une session et la
suivre en miroir ; l'autre moitié — l'écran depuis lequel on ouvre le partage — reste à écrire, si
bien que **rien n'est encore actionnable de bout en bout**. Ce qui l'est, en revanche, ce sont les
défauts que la préparation a mis au jour dans du code qui existait déjà, et qui n'attendaient pas
le partage pour nuire.

### Trois mécanismes existants que le partage rendait dangereux
Deux relectures adverses ont mesuré les surfaces prévues dans le code réel, avant qu'aucune ne soit
écrite. Elles ont invalidé l'ordre de travail : trois corrections devaient précéder toute nouvelle
interface, faute de quoi elle se serait appuyée sur un budget de place faux et sur un indicateur
qui ment.

**Le quai sacrifiait l'ALARME pour garder un chevron.** Quand la place manquait, la boucle
d'ajustement retirait les segments un à un et n'essayait « sans chevron » qu'une fois arrivée à
ZÉRO segment : elle sacrifiait donc le segment ambre du minuteur **échu** — la seule persistance de
l'alarme une fois le bip passé, dans une zone qui ne quitte jamais l'écran — pour garder un glyphe
`aria-hidden` que son propre commentaire qualifiait de « purement décoratif ». Et à court de
solutions, elle **réécrivait un état qu'elle venait de mesurer comme débordant**. Ordre inversé (le
décoratif tombe d'abord, à chaque palier) et plancher explicite.

**La cause de la pénurie était ailleurs : l'ellipse des intitulés n'avait jamais fonctionné.**
`.seg-l` déclare `text-overflow:ellipsis` depuis l'origine et un commentaire l'attribuait à un
« min-width:0 du segment » — qui n'existait pas. Sans plancher explicite, `min-width:auto`
dimensionne le segment sur son contenu le plus large ; en colonne, la règle flex qui annule le
minimum automatique porte sur la HAUTEUR, jamais sur cette largeur. Mesuré : un intitulé de
21 caractères portait le segment à **346 px pour 320 de large**, la boucle voyait un débordement et
expulsait le segment. Plancher chiffré à **112 px** = la valeur réelle la plus large
(« 999:59:59 », 95 px) plus les rembourrages : en dessous, l'intitulé s'ellipse — un MOT se
tronque, c'est admis ; au-dessus, la valeur ne peut jamais être rognée — un NOMBRE ne se tronque
pas — et si la place manque vraiment, le débordement est RÉEL, donc la boucle retire un segment et
le « +n » l'annonce. Le quai ne peut plus déborder en silence à aucune largeur servie.

**Le mot « échu » n'existait pas dans le quai**, alors qu'`AGENTS.md` l'affirmait : `segOf`
n'écrivait que l'intitulé et la valeur, si bien qu'un minuteur échu se distinguait d'un minuteur
nominal par la SEULE teinte — dans la zone la plus critique de l'application. Il ne pouvait pas
être ajouté en clair (l'ellipse l'aurait mangé le premier, et le segment aurait grossi jusqu'à se
faire expulser) : patron déjà retenu pour les étapes signalées — **glyphe `△` en PRÉFIXE**, qui
survit à l'ellipse, plus l'étiquette au lecteur d'écran. Piège trouvé au passage : cette étiquette,
en `position:absolute` sans ancêtre positionné, **échappait au `overflow:hidden`** et se posait à
488 px sur un quai de 320 — elle gonflait `scrollWidth`, c'est-à-dire qu'elle MENTAIT à la boucle
qu'on venait de corriger.

**Le seuil de péremption était INFÉRIEUR à la cadence nominale.** 4 s en constante, alors que la
période de sondage passe à 5 s après 30 s sans action et à 10 s après deux minutes : avec un réseau
PARFAIT, l'écran de l'invité se serait déclaré « figé » environ une seconde sur cinq au repos et
**six secondes sur dix pendant un cycle de compressions de deux minutes** — c'est-à-dire dans le
cas d'usage phare. Un indicateur qui crie au loup les deux tiers du temps n'est plus lu quand la
panne est réelle. Le seuil est désormais solidaire de la cadence courante et signifie « deux cycles
manqués » (facteur 2,5 : la gigue étant de ±20 %, deux périodes consécutives atteignent 2,4 fois la
base). Un statut terminal cesse en outre de sonder — le sondage tournait indéfiniment contre un
partage mort.

**La fin du partage n'est pas la fin du soin.** Le critère « une crise est à l'écran » s'écrivait,
pour un invité, `status === 'active'` : à l'instant EXACT où l'hôte coupait, deux mécanismes se
rallumaient sur la checklist que le collègue tient encore en main — le déversement des snackbars
retenues pendant tout le soin (jusqu'à huit) et la ré-apparition de la méta de lecture, qui décale
le contenu sous son doigt. Le critère juste est la PRÉSENCE d'une fiche de crise, d'où deux sorties
distinctes : `freeze` (le lien meurt, l'écran survit) et `stop` (l'écran est quitté).

### Le quai de l'invité existe, et il dit qui tient la main
Il n'apparaissait que si une session avait démarré **localement** — or un invité qui suit n'a rien
démarré, c'est le principe même du miroir. Les deux informations que la doctrine veut permanentes
(AC 120-71B §6.4 : qui tient la checklist ne souffre aucune ambiguïté ; et si ce qu'on voit est
encore vrai) n'avaient donc **aucun conteneur**. Un prédicat unique — celui-là même qui gouverne
déjà la mise en attente des banderoles — et un jeu **fermé** de jetons dans le libellé du chrono :
`main` / `suit`, `⇄n`, `figé`, `coupé`, `fini`, `seul`.

Trois emplacements ont été mesurés et écartés. Un **segment `⇄` propre** déplace le segment
d'alarme de 45 à 57 px selon la largeur, à son apparition ET à sa disparition — donc sur ÉVÈNEMENT
DISTANT, ce que la constance positionnelle ECAM interdit ; la **rangée de commandes** n'a que 2,1 px
de marge à 320 px ; une 2ᵉ pilule sur le **bandeau** fait tomber le titre de fiche de 172 à 58 px.
Le libellé du chrono, lui, coûte zéro pixel de mise en page : le segment est déjà étiré par le flex.
**Le lien REMPLACE la main**, il ne s'y ajoute pas — ce n'est pas une économie de place : quand le
lien n'est plus nominal, le rôle et le compte de participants ne sont PLUS CONNUS, et les afficher
serait la donnée périmée présentée comme vivante. Le vert cesse alors d'affirmer (encre neutre,
jamais l'ambre, réservé au minuteur échu).

### L'invité ne paie plus rien avant d'avoir lu
Mesuré sur profil vierge : charger `index.html#j=CODE` déposait **3,17 Mo** (le cache applicatif et
les 1 773 Ko de pdf.js), créait une base IndexedDB, écrivait quatre clés `localStorage`,
enregistrait un service worker — et appelait `navigator.storage.persist()`, c'est-à-dire demandait
au navigateur de rendre ce dépôt **non évinçable** — le tout AVANT que le premier mot de la notice
d'information ait pu s'afficher. Une information préalable posée sur une collecte déjà faite
n'informe rien.

Le mode invité devient donc une **décision de démarrage**, pas une classe CSS. Trois cas : pas de
code → démarrage normal ; code sur appareil VIERGE → stockage en mémoire, aucun worker, aucune
persistance demandée, aucun ensemencement, et l'écran d'entrée **à la place** de l'application ;
code sur un appareil qui utilise déjà l'app → démarrage normal (lui refuser son worker ne
protégerait rien et casserait son hors-ligne), écran par-dessus — **sauf si une fiche de crise est
à l'écran**, auquel cas le code est GARÉ et annoncé par le bandeau système, qui est déjà le canal
« information persistante, accueil seulement » (règle 11). Le fragment est retiré de l'historique
immédiatement. `ensureStarted` refuse de démarrer chez un invité : c'est le point exact où
l'étanchéité se joue — sans cette garde, sa première coche créerait un enregistrement de session
sur un téléphone emprunté. `launchQueue` est enfin consommé (le manifeste le déclarait depuis
v4.43.0 ; un lien entrant sur PWA installée était silencieusement perdu).

### Un écran d'entrée, et un refus qui ne prescrit pas l'impossible
L'écran porte l'information de l'article 13 — qui est responsable, ce qui est enregistré, pourquoi,
où, combien de temps, qui d'autre le voit — et il est audité en accessibilité dans les deux thèmes
à 320 px, la largeur la plus contrainte servie.

Le message de refus a été réécrit après mesure, et les trois formulations précédentes étaient
fautives. **« Vérifiez les 8 caractères » était du texte mort** : le contrôle local a déjà exigé
exactement huit caractères pris dans l'alphabet, deux lignes plus haut. **« Demandez de rouvrir
l'accès » est faux ou nuisible dans cinq causes de refus sur sept, dont deux boucles infinies** —
`share_admit` ne vérifie NI l'expiration NI le quota : il rend un code neuf que `share_join`
refusera encore, sans que personne ne comprenne pourquoi ; et sur une simple faute de frappe, il
TUE un code peut-être encore vivant. On nomme donc le RÉSULTAT (« un nouveau code »), jamais le
geste : l'hôte seul voit sa porte, et c'est lui qui décide. **Chiffrer la fenêtre et le nombre de
participants aurait été FAUX** — et l'argument n'est pas l'oracle, une chaîne statique ne portant
aucun état : `max_guests` est une COLONNE PAR PARTAGE (1-8, défaut 3) et la fenêtre vaut 120 s à
l'ouverture mais 15 à 600 s à chaque réadmission ; le client ne reçoit ni l'une ni l'autre. D'où
une règle de tri, écrite au-dessus des constantes : un chiffre n'entre dans un message que s'il est
détenu par le client, identique pour tout partage du déploiement, et capable de changer ce que le
lecteur fait ensuite. « 8 caractères » passe les trois ; « 2 minutes » et « 3 » échouent aux trois.

Trois rédactions, choisies sur la **provenance locale** du code — jamais sur la réponse du serveur,
identique dans les trois cas : code recopié à la main, code venu d'un QR (qu'on ne peut pas mal
recopier), et deuxième soumission du même code, qui coupe la boucle du re-tap puisque le champ
conserve sa valeur après échec. Le harnais vérifie que le serveur bouchonné rend la même chose et
que trois textes différents en sortent : un message qui varierait avec la réponse du serveur serait
un oracle.

Enfin, la géométrie : la rédaction précédente faisait **7 lignes et 145 px**, et à 320×568 le
bouton « Rejoindre » n'était plus visible que sur **23 px de ses 48** — sous le plancher de la
règle 9, et 0 px sur un écran de 480. Le défaut n'apparaissait qu'à la largeur la plus contrainte,
et aucun harnais ne regardait cet écran. Il en existe un désormais, et il échoue sur l'ancienne
rédaction.

### Deux questions tranchées, mesures à l'appui
**Le titre de l'aide sur l'écran d'entrée** : quatre chemins instruits, deux refusés. Une fonction
`share_peek(code)` serait un ORACLE par construction — elle sépare « titre » et « refusé » sans
consommer le code ni prendre de place, là où `share_join` fait les deux, et il n'existe aucune
limitation de débit sur la jointure. Le titre dans le QR rendrait **une photo de l'écran prise de
loin porteuse d'un diagnostic permanent**, là où elle ne porte aujourd'hui qu'un secret de 40 bits
mort en dix minutes au plus. Le titre est de toute façon **déjà peint dans la première image du
miroir** (`#crisisBand`, mesuré visible sans défiler à 320×568 comme à 390×844) : un écran de
confirmation intermédiaire coûterait un tap pour zéro information, et il est inécrivable tel quel —
au retour de `share_join` la liste des participants est vide et l'hôte s'appelle littéralement
« Hôte ». Il ira donc à côté du code sur l'écran de l'hôte.

**Un utilisateur sans compte peut-il OUVRIR un partage ?** Non, et l'arbitrage a été refait sur ses
vrais mérites — deux des trois arguments spontanés ne tiennent pas. « La surface d'abus l'interdit »
est faux comme argument discriminant : `require_approval` valant `false` par défaut, un compte coûte
une adresse jetable et un OTP, et `share_open` n'a de toute façon **aucun plafond par
propriétaire** — les 500 Mo en 40 secondes sont atteignables aujourd'hui, avec un compte.
« Aucun plafond ne peut exister sans `auth.uid()` » est faux aussi : c'est vrai d'un plafond PAR
APPELANT, hors sujet pour un plafond GLOBAL. Ce qui tient : `owner` est la SEULE colonne reliant un
contenu diffusé à une personne (la retirer ferait de l'exploitant l'hébergeur d'un contenu sans
auteur, sans retrait ciblé, et supprimerait la seule prise du droit à l'effacement) ; l'approbation
des comptes deviendrait décorative, le contournement s'appelant « Déconnexion » ; et **un hôte
anonyme serait un hôte infirme** — la qualité d'hôte n'a aucun porteur autre que le JWT, donc ni
réadmission, ni coupure, ni fin de partage : si la mauvaise personne entre, le partage reste vivant
jusqu'à expiration. Si la décision devait s'inverser un jour, le seul chemin défendable est un
compte ANONYME Supabase (vrai identifiant, journal, révocation, cascade d'effacement), jamais un
`owner` nullable, et derrière un interrupteur d'instance par défaut fermé.

### Journal des actions, et fin de session
Incrémenter un compteur **pose désormais un repère horodaté** dans le journal des actions —
« choc n° 3 à 14:32 » est exactement ce qu'on oublie de noter sous stress, et l'heure est ce qui
compte cliniquement. Le repère porte une RÉFÉRENCE, jamais un mot : son libellé se dérive de la
fiche à l'affichage, il traverse donc le partage sans texte libre et suit le compteur si on le
renomme. Le rail ne remonte pas (mise à jour chirurgicale).

Le `×` du journal **annule au lieu de supprimer** : ligne barrée, estompée, conservée, et le `×`
devient `↺` pour se raviser. Deux règles du projet le condamnaient déjà — « action destructrice en
situation de crise = geste maintenir, pas un simple tap », et le précédent `origT`, où la correction
d'heure est non destructive, visible et réversible. Le « maintenir » a été envisagé et écarté : il
protège du geste accidentel mais laisse la perte définitive, et ne dit rien à celui qui relit — or
le journal alimente le compte-rendu. **L'heure reste en encre pleine** (c'est la donnée clinique).
C'est aussi ce qui rend le geste admissible pour un scribe en session partagée : attribué, daté,
réversible — là où un décochage, qui détruit vraiment une information, lui reste fermé.

### Vérification
663 tests × 2 moteurs, 13 harnais verts, **94/94 contrôles doctrine** (+54), **301 contrôles
d'accessibilité** (+12, dont l'écran d'entrée dans les deux thèmes), 55/55 contrôles partage. Les
nouveaux contrôles ont chacun été **vérifiés capables d'échouer**, fichier restauré à l'octet
ensuite. `supabase/schema.sql` et `rls-tests.sql` ont été rejoués sur l'instance (le genre
d'évènement `mark_void` s'ajoute aux capacités du scribe).

**Incident de manipulation, consigné parce qu'il doit servir.** Un `git checkout -- index.html`,
lancé pour annuler une modification temporaire de démonstration, a effacé tout le travail non
committé du fichier — cette commande ne défait pas la dernière modification, elle restaure depuis
le dernier commit. Le fichier a été reconstruit depuis le transcript de session (79 éditions
rejouées dans l'ordre, deux ancrages réparés, deux modifications faites hors outil d'édition
retrouvées et re-appliquées), puis vérifié : audit systématique des 79 éditions (zéro manquante),
cohérence de la réparation manuelle sur ses 5 sites, absence de duplication, et surtout la suite
complète au vert — les tests et les treize harnais, eux, n'avaient pas été touchés, et c'est ce qui
a servi de juge. **Règle : pour annuler une modification expérimentale, restaurer depuis une
sauvegarde vérifiée par empreinte, jamais depuis git tant que le travail n'est pas committé.**

## [4.46.0] — 2026-07-27
### Partage de session en direct — le socle serveur, et six défauts trouvés en chemin

Premier jalon d'un chantier qui fera sortir une **session** de l'appareil : un collègue présent
dans la pièce pourra suivre et remplir une session de crise depuis SON téléphone, avec ou sans
compte, **pour cette session uniquement**. Rien n'est encore visible à l'écran. Cette version pose
le serveur, l'encodeur du code d'appariement et le noyau pur du transport — chacun vérifié
séparément, aucun ne dépendant du suivant.

### Ce que la doctrine dit vraiment, et une citation du projet qui était fausse
Les textes primaires ont été lus, pas leurs résumés — et deux résultats vont contre l'intuition.
**« Do-Verify » et « Challenge-Do-Verify » n'existent NULLE PART dans l'AC 120-71B** (recherche
exhaustive sur le document intégral : 6 chapitres + Appendix A, zéro occurrence ; la révision B
indique elle-même avoir retiré les exemples des appendices). Ces intitulés viennent de
l'**AC 120-71A (2003), que la révision B ANNULE**, où ils ne sont que des titres d'une liste de
sujets, sans définition. Les définitions rédigées qui circulent en ligne ne proviennent d'aucun
document FAA retrouvable. La pratique implémentée ne change pas d'un pixel — seule la référence
était fausse : la source correcte est le **FAA Order 8900.1, Vol. 3, Ch. 32, §3-3403.A**, et pour
la répartition à deux, l'AC 120-71B **§5.2.2.1** (« one crewmember reading the checklist and the
second crewmember confirming and responding »). Corrigé dans `AGENTS.md`, avec l'avertissement de
ne pas ré-inverser. De même, « la réponse porte l'état CONSTATÉ, jamais un *fait* » est de
**Degani & Wiener** (ligne directrice n°1, 1993), pas de la circulaire.

Deuxième résultat, structurant : **la co-édition symétrique n'est décrite nulle part**. Airbus
garantit l'exclusion mutuelle par le MATÉRIEL (un seul ECAM Control Panel) ; là où deux pointeurs
coexistent, l'industrie a écrit un verrou mono-écrivain à propriété visible, jamais une fusion. La
« vue dégradée » de l'invité n'est donc pas un compromis : c'est la forme canonique.

### Socle de sûreté — six défauts du code ACTUEL, sans rapport avec la nouveauté
- **`keepAnchor` confondait « 0 px » et « pas mesuré ».** Les trois sorties sans mesure renvoyaient
  `0`, c'est-à-dire la valeur qui signifie « ancrage parfait ». La plus grave : l'ancre a DISPARU
  pendant le re-rendu (une condensation du journal transforme la carte visée en chip). Démontré en
  réintroduisant le défaut — le cas guidé affiche **dérive 0 px ET résidu null** : l'ancien contrôle
  d'`audit-doctrine` passait au vert **sans avoir rien mesuré**, exactement sur le cas qu'il prétend
  couvrir. Troisième occurrence de la leçon v4.31.1. `keepAnchor` renvoie désormais `null`, que le
  harnais refuse (40/40).
- **La « prohibition ACTIVE » du rôle `anon` ne portait pas sur `PUBLIC`.** `revoke … from anon` ne
  retire que les privilèges accordés NOMMÉMENT à anon ; or PostgreSQL accorde `EXECUTE` à **PUBLIC**
  par défaut sur toute fonction (asymétrie avec les tables, qui n'en reçoivent aucun — d'où un
  revoke efficace côté tables et INOPÉRANT côté fonctions), et tout rôle hérite de PUBLIC. **Les
  20 fonctions du schéma étaient appelables sans compte.** Aucune escalade — chacune se protège par
  `auth.uid()` — mais la garantie annoncée n'existait pas.
- **`is_approved()` renvoyait `true` pour `anon`** : `auth.uid()` étant NULL, le `coalesce` retombait
  sur `'approved'`. Sans conséquence aujourd'hui (les politiques exigent en plus `owner = auth.uid()`),
  mais tout garde-fou futur écrit avec elle aurait été inopérant **en ayant l'air solide**. Règle
  écrite : un gate anon s'écrit `auth.uid() is not null`, jamais `is_approved()`.
- **Le balayage anon de `rls-tests.sql` (§13.5) était aveugle à ce qu'il prétend couvrir** : sept
  tables NOMMÉES EN DUR, zéro fonction. Remplacé par des assertions de **CATALOGUE** — aucun grant
  de table à anon, liste blanche EXACTE des fonctions exécutables par anon, et balayage dynamique de
  toutes les tables. Piège évité en l'écrivant : sous `anon`, `information_schema` ne montre rien,
  la boucle aurait tourné à vide et le test serait passé au vert sans rien balayer.
- **Aucun appel réseau n'avait de délai de garde.** Sur iOS, un `fetch` sans route ne rejette qu'au
  bout de 60 à 75 s : `Sync.running` reste vrai tout ce temps, le repli exponentiel ne peut pas
  s'armer (il ne démarre qu'APRÈS la première erreur), et `Auth.refresh()` — attendu avant CHAQUE
  appel REST — bloque tout ce qui suit. Les cinq `fetch` passent par `acFetch` (25 s, 120 s pour un
  binaire PDF : un téléversement légitime sur réseau lent ne doit pas être cassé par le correctif).

### Serveur — la première surface non authentifiée du projet
Trois tables (`shared_sessions`, `session_participants`, `session_events`) et six fonctions. La
surface `anon` est de **trois portes nommées, et rien d'autre**, ouvertes après la révocation
générale — placées avant, elles seraient effacées en silence quelques lignes plus bas.

Quatre décisions, chacune réparant une faille identifiée AVANT écriture : **aucune identité n'est
jamais un paramètre** (l'acteur se DÉDUIT du secret présenté ; le passer rendrait l'attribution
forgeable par tout porteur du code — or l'attribution EST le contrôle demandé) ; **le secret est
tiré par le serveur** (`gen_random_bytes`), jamais par le client, dont le seul générateur maison
rend ~41 bits et retombe sur `Math.random` ; **fenêtre d'admission** armée par l'hôte, code
**consommé** à la première jointure, ce qui rend la coupure d'un invité EFFECTIVE au lieu de
décorative ; **append-only strict** — un invité n'écrit que des lignes, l'état est un pli calculé
côté client, sinon le verrou de ligne d'un état matérialisé ferait attendre l'hôte derrière la file
d'un invité. La séquence est allouée **sous verrou, par partage** : un `bigserial` alloue à l'INSERT
et non au COMMIT, un évènement validé en retard resterait définitivement sous le curseur du lecteur.
Chaque évènement porte **deux horloges** — l'instant du geste et celui de l'arrivée — sans quoi une
action relevée hors réseau se rangerait au compte-rendu à l'heure du retour du réseau.

**Relais, pas entrepôt** : purge bornée en tête de CHAQUE appel (sur un hébergement statique,
une purge planifiée n'a personne pour la lancer). `delete_my_account` supprime les partages
**explicitement** — sans cela, soit ils survivent, soit la violation de clé étrangère annule toute
la fonction et le droit à l'effacement disparaît pour quiconque a partagé une fois.

**`supabase/schema.sql` est à REJOUER**, puis `rls-tests.sql` — dont le nouveau **§14 porte
31 assertions** : jointure d'un invité sans compte, code consommé, capacités du scribe, acteur non
falsifiable, coupure MOTIVÉE (« revoked », jamais un silence qu'on prendrait pour une panne),
détachement, purge, effacement RGPD.

### Deux garde-fous nés des erreurs de cette version
`check-sql.mjs` gagne deux contrôles, chacun **vérifié capable d'échouer** puis fichier restauré à
l'octet. (1) Tout `grant … to anon` doit citer une fonction de la liste blanche, et
`grant … on all …` est refusé quel que soit le rôle : le scénario visé n'est pas la malveillance
mais le dépannage — PostgREST accompagne un refus 42501 d'un `hint` qui nomme le grant manquant, et
la réponse la plus répandue en ligne est la forme globale. (2) Une fonction `language sql` ne peut
référencer aucun objet déclaré plus bas dans le fichier : elle est intégralement résolue À SA
CRÉATION (`42P01` au collage), là où une `language plpgsql` n'analyse son corps qu'à la première
exécution. Cette asymétrie ne se voit pas à la relecture et avait déjà coûté deux re-créations de
`get_instance_stats` ; elle en a coûté une troisième ici, découverte sur l'instance.

### Encodeur QR — sans dépendance, et relu par le décodeur d'Apple
Le code d'appariement s'affiche en QR sur l'écran de l'hôte : un QR affiché ne peut être scanné que
par quelqu'un qui est **là**, et il ne transite par aucun message, aucun journal d'accès, aucun
historique. L'app n'embarque **aucun décodeur** — iOS et Android décodent nativement depuis
l'appareil photo — et c'est cette asymétrie qui rend la fonctionnalité abordable (règle 13 intacte,
aucun fichier servi de plus). Mode octet, correction M, versions 1 à 10.

Choix de conception central : **une seule table de 20 nombres**, tout le reste se dérive — total de
mots-code par la géométrie, découpage en blocs par la division euclidienne, alignements par formule.
Une table recopiée est une erreur qui dort ; une dérivation se vérifie, et le test recoupe les deux
chemins. **La vérification a payé immédiatement** : le calcul des syndromes Reed-Solomon — qui
ÉVALUE le polynôme là où l'encodeur le DIVISE, donc n'emprunte rien à ce qu'il vérifie — a fait
tomber un polynôme générateur construit **à l'envers** (terme dominant non unitaire). Motifs au bon
endroit, format valide, structure impeccable : aucun contrôle de cohérence interne ne l'aurait vu,
et les codes produits auraient été parfaitement illisibles. Nouveau harnais `scripts/audit-qr.mjs` :
les codes sont relus par **CoreImage**, le décodeur d'Apple, celui de l'appareil photo de l'iPhone —
5 cas, v1 à v6, UTF-8 accentué compris, sur les deux moteurs. macOS seulement : ailleurs il AVERTIT
sans échouer, en disant explicitement que la vérification n'a pas eu lieu. Piège de thème évité :
`--ink` est CLAIR en sombre, un QR peint avec lui serait blanc sur blanc — d'où `--qr-ink`, fixe
dans les deux thèmes, sur le patron de `--paper`.

### Noyau pur du transport
Sept fonctions sans effet de bord. **La projection de fiche** (`sharePayload`) n'est pas la fiche :
deux listes explicites couvrent les **27 champs du modèle migré**, et un test échoue si l'une prend
du retard — ajouter demain un champ sans décider s'il se partage devient impossible (garde-fou
vérifié capable d'échouer). Ne partent pas : le gabarit local (téléphones de renfort et de
régulation, pré-remplis par `blankFiche`), les images (jusqu'à 24 Mo), les documents que l'invité ne
pourrait pas ouvrir, `ownerId`/`libraryId`. `shareFold` exclut l'annexe d'un détaché de l'état —
c'est un rapport, pas une commande. `shareStateHash` détecte la **divergence silencieuse**, celle
qu'un indicateur de péremption ne verra jamais parce que les mises à jour arrivent à l'heure et sont
fausses. `shareOffset` (Cristian) rejette toute mesure dont l'aller-retour dépasse le seuil : un
décalage faux daterait les gestes du compte-rendu et ferait sonner deux minuteurs à des instants
différents dans la même pièce. L'en-tête HTTP `Date` n'étant PAS lisible en fetch cross-origin,
l'heure serveur voyage dans le corps.

**560 tests × 2 moteurs, 12 harnais verts, 289 contrôles a11y, 40/40 doctrine.**

## [4.45.0] — 2026-07-27
### Factorisations — et ce qu'elles ont révélé
Trois duplications du reliquat d'audit, sans effet visible à l'écran. La troisième a fait tomber un
angle mort qu'aucune relecture n'aurait trouvé.

### L'ancrage ECAM : de 4 copies à 1, et enfin mesurable
Le motif « mesurer la position écran d'une ancre, re-rendre, compenser le défilement » existait en
quatre exemplaires — `renderKeepAnchor`, `renderOvOnlyKeepAnchor`, `ovAdvanceRender`, et le
remplacement chirurgical de `renderNavOnly`. C'est **l'invariant le plus cité du projet** (« rien
ne bouge sous le doigt ») et **une seule des quatre mesurait son résidu** : les trois autres
appliquaient le motif sans jamais pouvoir dire si elles y arrivaient. Source unique `keepAnchor`.

Ce qui **n'a pas** été unifié, et pourquoi : le focus clavier (seul le journal le déplace) et la
règle de visibilité (seul `ovAdvanceRender` défile vers la nouvelle carte, et seulement si elle
n'est pas déjà entièrement à l'écran). Le résidu reste **renvoyé, jamais corrigé** — la
compensation est bornée par le haut de page, et c'est cette limite qui fonde la doctrine de
`state.confOpen` ; la masquer rouvrirait le bug v4.3.2.

Deux contrôles permanents ajoutés à `audit-doctrine` (38/38) : dérive 0 px à la première action de
session et au remplacement du bloc en mode guidé. Tolérance 1 px, assumée : WebKit rend 1 px là où
Blink rend 0, arithmétique identique — du sous-pixel de compositeur, pas un défaut d'ancrage.

*Note : un `{preventScroll:true}` s'était glissé dans la restauration de focus. Il serait cohérent
avec les deux autres restaurations du fichier et protégerait l'ancrage qu'on vient d'appliquer —
mais c'est un changement de comportement, et un lot de factorisation n'en embarque pas. Retiré, et
signalé ici pour décision séparée.*

### `updateRtStrip` : un calcul écrit deux fois, un prédicat rédigé de deux façons
Le temps restant (qui sert au tri : échus d'abord, puis les plus urgents) était calculé à
l'identique pour le quai et pour la bande du mode lecteur, mais le prédicat « échu » différait —
`dueDone(t)||(interval && val==='00:00')` d'un côté, `interval && val==='00:00'` de l'autre.
L'extraction est **iso-sortie**, et la démonstration mérite d'être écrite : `dueDone` impose déjà
`type==='interval'`, et un minuteur échu et arrêté donne `within >= per`, donc `fmtMs(max(0,
per-within))` vaut « 00:00 » — le premier disjoint est absorbé par le second. Une **fonction**
appliquée deux fois, jamais un tableau partagé : chaque zone garde son tri et sa troncature.

### Les onze harnais n'auditaient pas la cible principale
`scripts/harness.mjs` : serveur statique, table MIME et choix du moteur, partagés. La duplication
avait déjà dérivé — `audit-lecteur.mjs` était le seul dont la table MIME omettait `.ico`.

Mais le vrai constat est ailleurs : **les onze lançaient `chromium.launch()` en dur**. `npm test`
tourne sur deux moteurs depuis v4.34.0 parce qu'iOS Safari est la cible principale et qu'un
comportement WebKit peut couper l'écran sans qu'aucune mesure ne le voie. Les harnais, eux,
n'auditaient que Blink. Le moteur se choisit désormais par `AC_ENGINE` — `chromium` par défaut,
donc rien ne change sans décision, et un nom inconnu échoue bruyamment plutôt que de retomber en
silence sur chromium.

**Le premier passage sur WebKit a immédiatement payé.** La sonde WCAG 2.4.11 signalait **8
masquages sur 11 cibles** — de quoi croire à un défaut d'accessibilité sur iPhone. La géométrie dit
autre chose : tous avaient un bas **négatif** (−352, −237, −138, −94 px), c'est-à-dire des éléments
pas encore revenus à l'écran. Sur WebKit, le défilement induit par un focus **programmatique** est
asynchrone ; la sonde lisait la position d'avant et mesurait la synchronicité du moteur, pas
l'application. Variable isolée (même sélecteur, même scénario, seule l'attente change) : lecture
immédiate → 8, lecture après 60 ms → **0, sur les deux moteurs**.

Ce n'était donc pas un défaut d'accessibilité — mais **on ne pouvait pas le savoir** tant que les
harnais ne tournaient que sur Blink. Règle ajoutée : toute sonde qui lit une géométrie après
`focus()` doit attendre.

**Les onze harnais passent désormais sur WebKit comme sur Chromium.**

513 tests × 2 moteurs, 11 harnais verts **sur les deux moteurs** (38/38 en doctrine),
289 contrôles d'accessibilité.

## [4.44.1] — 2026-07-27
### Correctif : `schema.sql` de v4.44.0 ne s'exécutait pas
Signalé par l'utilisateur au rejeu sur Supabase :
`ERROR: 42601: syntax error at or near "$"`, ligne 270.

Deux fonctions trigger — `clamp_updated_at` et `stamp_updated_by` — avaient perdu un dollar de
leur délimiteur de corps : `as $$` était devenu `as $`. Réparé, et vérifié qu'il n'en restait
aucun autre.

**La cause est une erreur de méthode de ma part, et elle mérite d'être écrite parce qu'elle se
reproduira.** `String.prototype.replace()` interprète `$$` **dans la chaîne de remplacement**
comme un dollar littéral unique — au même titre que `$&`, `` $` ``, `$'` et `$1`. Le script de
patch qui ajoutait `set search_path` aux deux fonctions réinjectait donc du SQL mutilé, en
silence. Remède : passer une **fonction** de remplacement (aucune substitution n'y est faite), ou
`split().join()`.

**Et le contrôle que j'avais fait ne pouvait pas l'attraper.** J'avais compté les `$$` et vérifié
la parité : 50, pair, vert. Or un `$$` amputé en `$` ne matche plus le motif — il disparaît du
compte **des deux côtés**, et la parité reste vraie. C'est un contrôle aveugle au défaut qu'il
prétend couvrir, exactement ce que la leçon v4.31.1 proscrit ; je l'ai redite au prix fort.

### `scripts/check-sql.mjs`, dans `npm run check`
`supabase/schema.sql` et `supabase/rls-tests.sql` n'étaient couverts par **rien** : ni servis, ni
chargés par les tests. Une erreur ne s'y voyait qu'au collage dans l'éditeur SQL de Supabase —
c'est-à-dire chez l'utilisateur, sur une instance de production. Trois contrôles : les **runs de
dollars** (un délimiteur de corps s'écrit `$$`, un dollar isolé est la signature exacte du défaut),
leur parité, et l'absence de `;` dans un en-tête de fonction avant son corps. Vérifié capable
d'échouer en réintroduisant le défaut vécu — il le signale par les **trois** voies — puis fichier
restauré à l'octet.

### Relecture complète du diff SQL
Toutes les modifications de v4.44.0 sur `schema.sql` ont été relues ligne à ligne :
**zéro ligne supprimée qui ne soit un en-tête de fonction**. Aucune logique, aucune politique,
aucun grant n'a été touché — uniquement l'ajout de `pg_temp` et, pour les deux fonctions trigger,
d'un `search_path`.

> **`supabase/schema.sql` est à rejouer**, cette fois avec succès, puis `rls-tests.sql`.

513 tests × 2 moteurs, 11 harnais verts, 289 contrôles d'accessibilité.

## [4.44.0] — 2026-07-27
### Durcissement, sécurité serveur, purge — et le filet qui manquait sur le service worker
Quatre lots techniques du reliquat d'audit, sans effet visible à l'écran.

### Durcissement
**`esc()` échappe désormais l'apostrophe.** La doctrine en fait « la SEULE barrière anti-XSS » : la
laisser suspendue à l'invariant non vérifié « aucun attribut n'est délimité par une apostrophe »
faisait reposer la sûreté de tout le fichier sur une convention que rien n'impose. Innocuité
établie avant écriture : 278 sites d'appel, dont **0 `textContent`, 0 `setAttribute`, 0 comparaison
de chaîne** — la sortie ne va que dans du HTML, où l'entité est re-décodée.

**Le backtick, lui, reste intact — et c'est une décision, pas un oubli.** Il a été échappé, puis
rétabli : trois tests du mini-Markdown tombent aussitôt, parce que `mdInline` échappe d'abord et
reconnaît la syntaxe ensuite — un backtick devenu `&#96;` n'est plus un délimiteur de code. Et ce
n'est pas un métacaractère HTML. L'échapper coûtait une fonctionnalité documentée pour zéro sûreté.
Les deux tests encodent maintenant la règle **et son exception**.

Le risque réel n'était pas la sûreté mais l'affichage : les textes français sont pleins
d'apostrophes. Balayage de **7 surfaces × 2 moteurs** (accueil, session vive, feuilles Consulter et
Se repérer, statique, éditeur, protocole) — **aucune entité littérale**, la sonde prouvant par
contre-épreuve qu'elle sait en voir une.

**`check-colors` : exemption resserrée à la règle, plus à la ligne.** Elle était `^.*\.acc-sw\..*$`
— ligne entière. Or ce CSS écrit plusieurs règles par ligne : trois lignes exemptées, dont **deux
portant six règles chacune**, et une troisième sans le moindre hex. Un hex collé en fin d'une de
ces lignes passait inaperçu ; il est désormais attrapé (démontré, puis fichier restauré à l'octet).

### Sécurité serveur
`pg_temp` ajouté en fin des **20** `search_path` épinglés, et les **2 fonctions trigger** —
`clamp_updated_at`, `stamp_updated_by` — qui n'en avaient aucune en reçoivent une. Nuance honnête :
`pg_temp` n'est jamais consulté pour résoudre une fonction ou un opérateur, seulement pour les
tables, et toutes les relations sont déjà qualifiées `public.…` — on ferme une porte déjà fermée
par ailleurs. On le fait parce que c'est gratuit et que l'absence est ce qu'un auditeur tiers
relève en premier. Vérifié : **0 `search_path` nu, 0 sans `pg_temp`**.

**`FORCE ROW LEVEL SECURITY` n'est PAS activé, et le piège est désormais écrit dans le schéma.**
L'ajouter par réflexe supprimerait **tous les app-admins** : `app_admins` et `app_settings` n'ont
volontairement ni politique ni grant, et ne sont lues que par `is_app_admin()`/`is_approved()`, qui
sont `security definer` précisément pour traverser cette invisibilité. Sous `force`, le
propriétaire redevient soumis aux politiques — il n'y en a aucune — donc plus aucune création de
bibliothèque ni validation de compte sur toute l'instance.

> ⚠ **`supabase/schema.sql` est à rejouer** sur l'instance Supabase, puis `rls-tests.sql`.

### Purge (règle 14) — zéro pixel changé
- **`state.showSess`** : déclaré, remis à false deux fois, **jamais lu**.
- **`_rtShowDirty`** : quatre écritures, **zéro lecture** — deux écouteurs globaux (`scroll`,
  `resize`) entretenaient une valeur que personne ne consultait, et le commentaire décrivait une
  optimisation qui n'existait plus.
- **Modificateur `compact`** : émis deux fois, **aucune règle CSS** dans tout le fichier.
- **Délégation du plan dans `bindOverviewEvents`** : trois branches inatteignables. Ce gestionnaire
  écoute `.ov-wrap`, le journal ; le plan l'a quitté en v4.23.0. Mesuré avant retrait dans
  **21 configurations** (3 largeurs × 7 états) : `.ov-wrap [data-pl*]` = **0 partout**, pendant que
  le rail en portait 9 dès 800 px et la feuille 9 une fois ouverte.
- **Trois règles CSS strictement dupliquées** (`.dock-plan:hover`, `.catchip{position:relative}`,
  `#crtIA .crt-ic`). Un **quatrième** doublon strict existe — `body.view-read .read-grid` @1200 —
  et il est **délibéré**, réaffirmé exprès après le bloc 1000 pour gagner par l'ordre de cascade.
  Il apparaît dans la même liste que les autres : ne jamais passer d'outil « supprimer les règles
  dupliquées » sur ce fichier.
- **`--pulse`** était la copie décimale **exacte** de `--ok` dans les deux thèmes (29,122,56 et
  55,214,122). Invisible au garde-fou couleurs, puisque c'était une déclaration de token : changer
  `--ok` aurait laissé le halo derrière. Source unique désormais — `--ok-rgb` porte le triplet,
  `--ok` en dérive. Vérifié au calculé : `rgb(29, 122, 56)` / `rgba(29, 122, 56, 0.45)` en clair,
  `rgb(55, 214, 122)` / `rgba(55, 214, 122, 0.45)` en sombre, identique sur les deux moteurs.
- **`#brandSub .sess-dot`** : CSS mort. `.sess-dot` n'est émis que dans les cartes « sessions en
  cours » de l'accueil ; `#brandSub` est un `<span>` de texte. 0 nœud sur 3 états × 2 moteurs.

### Commentaires qui mentaient
- `posoCardsHtml` s'annonçait « source unique **partagée par le flux et la feuille Consulter** — les
  deux rendus ne peuvent pas diverger ». Faux depuis v4.25.3, qui a retiré la posologie de la
  feuille : il ne reste qu'**un** site d'appel. Le commentaire promettait une garantie de
  non-divergence entre deux rendus dont l'un n'existe plus. **AGENTS.md portait la même
  affirmation**, en contradiction avec sa propre section « FEUILLE CONSULTER » deux paragraphes
  plus haut — corrigé aux deux endroits.
- `_vvhSync` annonçait « ~1 s » : il tourne à **3,3 fois par seconde** (`setInterval(…,300)`, appel
  placé avant le garde d'activité). Coût mesuré : **nul** — `vv.height` est déjà calculé, et
  l'écriture n'a lieu qu'au-delà de 0,5 px de variation. Le chiffre est corrigé parce qu'un
  commentaire faux sur une fréquence est ce qui fait ensuite « optimiser » au jugé une boucle qui
  ne coûte rien.

### Le filet manquant : `scripts/check-sw.mjs`
**La fonction dont tout dépend en intervention — exister hors ligne — était la seule que rien ne
mesurait** : aucun des onze harnais ne regardait `sw.js` ni le manifeste, et trois des défauts les
plus graves de cet audit vivaient là, trouvés à la lecture seule. Quatre contrôles **statiques**,
donc instantanés, donc dans `npm run check` à chaque commit : toute entrée d'`ASSETS` /
`CORE_ASSETS` / `PDFJS_ASSETS` existe sur le disque (une entrée fantôme dans `CORE_ASSETS` fait
échouer `addAll`, qui est tout-ou-rien, et supprime le hors-ligne entier) ; `CORE_ASSETS` ⊆
`ASSETS` ; tout fichier servable de la racine est dans `ASSETS` — la règle 13 ne s'auto-exécutait
pas ; `CACHE` aligné sur `APP_VERSION`, c'est-à-dire la règle 1. Vérifié capable d'échouer sur les
deux scénarios, fichier restauré à l'octet.

513 tests × 2 moteurs, 11 harnais verts (34/34 en doctrine), 289 contrôles d'accessibilité.

## [4.43.0] — 2026-07-27
### Deux arbitrages tranchés : 320 px est servi, et la production est GitHub Pages
Décisions utilisateur. Elles débloquent quatre constats du reliquat d'audit.

### 320 px — WCAG 1.4.10, et deux rognages silencieux
C'est le plancher de « Reflow », et deux surfaces y perdaient du contenu sans le dire :

- **rangée de commandes de crise** : 348 px requis pour 320, soit **28 px inatteignables** — le
  bouton restait opérable (44 px visibles, `aria-label` intact) mais se lisait « ⤢ Con », coupé en
  plein mot ;
- **`⋯` de l'éditeur** : **6,2 px hors écran**, bouton pourtant `display:grid` donc bien peint.

Identique sur Chromium et WebKit. Les pixels viennent de la recette v4.23.4 — écarts et
rembourrages — jamais d'un renommage (règle « troncature du même mot ») ni d'une 2ᵉ ligne (la
hauteur de crise est un coût permanent) : **34 px rendus pour 28 nécessaires** dans la crise,
~12 pour 6,2 dans l'éditeur.

Une analyse antérieure concluait que la recette était épuisée et qu'il faudrait sacrifier
`.ctrl-sp`. C'est faux, et pour une raison précise : elle visait les postes déjà compressés en
v4.30.0, jamais le rembourrage des deux segments de mode (12 px à lui seul) ni celui des deux
ouvertures. **`.ctrl-sp` n'est pas touché** — ces 4 px sont l'écart de Gestalt qui sépare le MODE
des OUVERTURES, raison d'être de la séparation ECP/ECAM de v4.25.0.

Le harnais gagne un contrôle qu'il n'avait pas : le **rognage par le conteneur**. Un bouton peut
tenir dans la fenêtre tout en étant coupé par sa boîte de contenu — c'est exactement ce qui se
produisait, et le contrôle « hors écran » seul passait au vert. `audit-doctrine` mesure désormais
320/360/375/390 pour la crise et 320/360 pour l'éditeur (34/34).

### Hébergement : GitHub Pages en production, déployable ailleurs
Décision datée dans `docs/deploiement-et-conformite.md` et en tête de `_headers`. Conséquence
assumée : **`_headers` est maintenu à jour bien que GitHub Pages l'ignore totalement** — il n'est
pas décoratif, c'est la posture servie sur tout autre hébergeur, et le supprimer ferait disparaître
le seul endroit où elle est écrite.

Ajoutés : `Cross-Origin-Opener-Policy` et `Cross-Origin-Resource-Policy` en `same-origin`
(`window.open` est absent du code — vérifié, 0 occurrence — donc aucun échange de fenêtre à
casser), et une `Permissions-Policy` portée de 3 à **21 capacités**.

**COEP `require-corp` est délibérément absent** : aucun `SharedArrayBuffer`, aucune ressource
cross-origin embarquée, donc il ne protège rien — et il casserait au premier ajout. Un en-tête qui
ne protège rien et casse plus tard est une dette.

Trois capacités restent **volontairement ouvertes**, et la liste a été établie par mesure, pas
recopiée d'un modèle :
- **`autoplay`** — le bip d'alarme passe par WebAudio, soumis à la politique d'autoplay. Le fermer
  rendrait l'alarme de minuteur **muette** : la sortie la plus critique de l'application.
- **`screen-wake-lock`** — inutilisé aujourd'hui, mais garder l'écran allumé pendant une
  réanimation est un besoin plausible.
- **`web-share`** — `navigator.share` est le chemin **obligatoire** du téléchargement PDF en PWA
  installée (v4.19.1 : WebKit ignore `download` en standalone).

`launch_handler: {client_mode: "focus-existing"}` ajouté au manifeste — la seule des quatre clés
manquantes qui porte un argument clinique (ne pas ouvrir une seconde fenêtre pendant une session
vive). iOS ne l'implémente pas ; Android et bureau si.

**`"id": "./"` n'est PAS modifié**, et la raison est écrite pour la prochaine fois : `id` se résout
par rapport à l'**origine**, pas au chemin du manifeste. Le changer ferait apparaître l'app comme
une **nouvelle application** chez tout utilisateur l'ayant installée — doublon sur l'écran
d'accueil, ancienne installation figée sur son cache. C'est une porte à sens unique. Contrainte qui
en découle : ne pas héberger une seconde PWA sur la même origine.

510 tests × 2 moteurs, 11 harnais verts (34/34 en doctrine), 289 contrôles d'accessibilité.

## [4.42.0] — 2026-07-27
### Le reliquat d'audit trié : 36 % était périmé
Les 70 constats jamais traités de la Phase 1 ont été reconfrontés au code actuel, chacun sous
contre-expertise. **25 sont tombés** : 2 déjà corrigés, 5 mal fondés, 18 dont la preuve se
reproduit mais dont le verdict s'inverse (victime inexistante ou remède pire que le mal). Restent
45, dont **22 sont des questions à trancher** et 23 des corrections — dont **4 seulement changent
quelque chose pour un soignant**. Ce sont ces quatre-là.

Deux familles se sont effondrées en bloc. Les constats de **performance** mesuraient des *comptes
d'appels* sans chronomètre : le tick de 300 ms coûte 0,5 ms/s de mise en page, le resize PDF
0,26 ms, `syncHdrScroll` 0,10 ms/s de gain potentiel — à comparer aux 126,8 ms/s du seul vrai
levier de v4.41.0. Les constats **« le dépôt ne documente pas X »** reposaient sur des greps qui
excluaient `CHANGELOG-archive.md`, qui est pourtant le canal de décision du projet.

### Décocher ne défaisait pas la fin de l'algorithme, en mode guidé
Le cœur du cochage existe en deux copies, guidé et journal, et elles avaient divergé. Le journal
remet `state.flowEnded` à false puis re-rend si la bannière traîne. Le guidé faisait le reset dans
la branche `else` d'un `if(nn)` — or quand la fin est actée, `#navNext` **n'existe plus** :
`navSection` le remplace par la bannière `.flow-end`. `nn` étant null, le bloc entier était sauté
et le reset ne s'exécutait **jamais dans le seul cas où il sert**. Mesuré sur une fiche mono-bloc
(ce que rend `blankFiche()`, donc toute fiche neuve) : « Algorithme terminé — surveillance en
cours » restait affiché après décochage et « Terminer l'algorithme » ne revenait pas.

**Ce chemin n'était couvert par aucun test** : `grep -rn 'nav-wrap\|navNext\|bindNavEvents'
tests.html scripts/` rendait 0. Cinq contrôles ajoutés à `audit-doctrine.mjs` (27/27), vérifiés
capables d'échouer — défaut réintroduit, 3 échecs, fichier restauré à l'octet.

### L'alarme routée était muette pour les lecteurs d'écran
Session hors de vue (autre fiche, autre vue), un minuteur sonne : banderole visuelle, flash écran,
et notification système **seulement si l'app est en arrière-plan**. Restait le bip — qui dit qu'un
minuteur a sonné, jamais **lequel** ni **sur quelle fiche**. C'est précisément le cas où
l'information manque : une session vive sur une autre fiche pendant qu'on lit un différentiel.
`announce()` écrit désormais dans `#srLive` (`role=alert`, `aria-live=assertive`) : audible côté
lecteur d'écran, **invisible à l'écran** — la règle 11 tient, rien ne bouge et rien ne se pose
par-dessus la checklist. Vérifié : une seule banderole ajoutée, pas deux (WCAG 4.1.3).

### Trois minuteurs de même id n'en armaient qu'un
`migrate()` déduplique les ids de blocs (`while(used[nid])`) mais pas ceux des minuteurs ni des
compteurs. Or `Runtime.timers` est indexé par id : trois entrées de même id, **une seule armée, la
dernière**, sans le moindre signal — et les ids DOM (`tmval-`, `cnval-`) se télescopent. Une fiche
importée, dupliquée ou reçue d'une bibliothèque partagée passe par là, et la règle 5 veut que
`migrate()` soit le point où une donnée entrante devient sûre. Le premier garde son id (les
références `counters[].timerId` continuent de résoudre sur lui) ; les suivants en reçoivent un
neuf. Mesuré : 3/3 ids distincts, 3/3 minuteurs armés, 3/3 cartes, 2/2 compteurs.

### Un pull de synchro avalait un tap en pleine réanimation
`if(applied)render()` reconstruisait tout le DOM dès qu'une seule ligne distante était écrite —
y compris en session vive. La règle 11 l'interdit déjà en toutes lettres (« aucune synchro
intrusive ») : ce n'était donc pas un arbitrage. Il suffisait qu'un coéquipier modifie une ligne
d'une bibliothèque partagée.

Le premier contrôle que j'avais écrit était faux, et il faut le dire : un `.click()` programmatique
sur un nœud détaché déclenche quand même son handler (la fermeture survit), et je comptais des
*clés* de `state.checked` alors que décocher écrit `false` et conserve la clé. Un tap réel est
`pointerdown → pointerup → click`, et le click n'est émis que si les deux atterrissent sur le même
élément : le défaut est donc « DOM remplacé entre les deux ». Reproduit à la vraie souris,
Chromium **et** WebKit — **témoin : 0 → 0 coche** (tap avalé) ; **après correctif : 0 → 1**, sans
re-rendu ; et hors session le rendu se déclenche toujours.

Rien n'est perdu pendant ce temps : la mémoire est déjà à jour, et toute sortie de crise passe par
`render()`. Ce qui reste vrai, et c'est voulu : **la fiche ouverte ne change pas sous les yeux du
soignant** — une aide partagée réécrite à distance en pleine réanimation ne se substitue pas à
celle qu'on déroule ; la nouvelle version arrive à la réouverture.

510 tests × 2 moteurs, 11 harnais verts (dont 27/27 en doctrine), 289 contrôles d'accessibilité.

## [4.41.0] — 2026-07-27
### Phase 3 (optimisation) — premier lot : le seul vrai levier de performance, et deux invariants
La campagne de mesure a couvert six dimensions (démarrage, re-rendus, calcul répété, service
worker, CSS, Web Vitals) sous vérification adversariale. **Le résultat principal est que
l'application est déjà rapide** : 26 « rien à faire » démontrés, 16 constats réfutés, et **un seul**
levier de performance réel. Les chiffres du budget, re-mesurés machine au repos : démarrage 66 ms
(CPU nominal) / 262 ms (×4) ; un parcours clinique complet ne déclenche que 5 `render()` complets ;
`esc()`, appelée 817 fois par rendu, coûte 0,06 ms.

### `transition:width` sur la barre de minuteur → `transform:scaleX()`
`width` est une propriété de **mise en page** : animée en continu, elle force un layout par image.
En session vive avec un minuteur d'intervalle armé et le panneau ouvert, six secondes sans le
moindre geste : **118 layouts/s, 123 recalculs de style/s**, soit 126,8 ms/s de fil principal à CPU
nominal, 206,9 à ×4 et 377,3 à ×6 — **jusqu'à 38 % d'un cœur brûlés pendant toute une réanimation**,
sans qu'aucun JS ne s'exécute.

Mesuré après application, sur le fichier réel contre un témoin `width` réinjecté :
115,0 → **11,4** ms/s (×1), 193,5 → **18,2** (×4), 248,0 → **25,9** (×6) ; 115 → **2** layouts/s.
WebKit, hors CDP : **+9,7 %** de débit utile du fil principal.

Un arbitrage annoncé n'a finalement pas eu lieu d'être. Deux vérificateurs divergeaient sur ce que
rend `scaleX` — l'un mesurait ~120 recalculs de style/s résiduels, ce qui aurait obligé à choisir
entre performance et rendu. L'A/B rejoué à trois variantes (actuel / `scaleX` / sans transition),
servies en mémoire, tranche : **17 recalculs/s**, l'animation est bien composée, et `scaleX` rend
autant que supprimer l'animation *sans changer le rendu*. Le gain est de la **marge CPU et de
l'autonomie**, pas de la fluidité (120 fps et latence de cochage identiques) — ne pas le vendre
autrement.

Rendu vérifié au pixel, et la première sonde était fausse : elle mesurait un minuteur **en marche**,
donc une cible mouvante (le « 0 % » relevait `scaleX(0.9912)` — le minuteur avait rebouclé). Refaite
à minuteur figé : géométrie identique à 0,01 px près, et la comparaison des captures ne diffère que
sur **une colonne de 4 px** — l'anticrénelage du bord mobile, écart max 73/255 — plus les deux
extrémités arrondies à 100 % (≤ 9/255). Identique dans les deux thèmes. Une source unique `barTf()`
sert le gabarit ET le tick : deux formats seulement équivalents (`scaleX(0.76)` vs `scaleX(0.7600)`)
feraient échouer la comparaison anti-churn et réécriraient le style 3,3 fois par seconde. Vérifié :
17 écritures en 5 s pour ~16,7 passages du tick, soit une par tick.

### Garde-fou `scripts/check-anim.mjs`, dans `npm run check`
Aucune propriété de mise en page dans un `transition` ni dans un `@keyframes`. La règle était déjà
respectée partout ailleurs (19 keyframes sur 19) — c'est le profil exact d'une règle qu'un seul oubli
trahit sans que rien ne le signale. Une exemption, motivée : `.skiplink` (glissement de 120 ms une
fois par focus ; le convertir mettrait en jeu une position dépendant d'`env(safe-area-inset-top)`,
soit un risque d'accessibilité pour un gain nul). Le contrôle a été **vérifié capable d'échouer**
(défaut réintroduit, message juste, fichier restauré à l'octet) — leçon v4.31.1 : un garde-fou qui
ne peut pas échouer ne prouve rien.

### `touch-action:manipulation` sur les étapes cochables
AGENTS.md § Interactif énonce que « tous les contrôles » le portent. Mesuré en session vive à
390×844 : **5 cibles en `touch-action:auto`** sur « Anaphylaxie », 3 sur « Arrêt cardiaque » — les
`li[role="checkbox"]` du parcours, que la règle de base ne couvrait pas alors que
`li.md-task[role="checkbox"]` (protocoles) le posait déjà. Après : **0**, sur Chromium et WebKit.
Le gain n'est pas un délai de tap — le délai de ~350 ms n'existe plus pour un viewport
`width=device-width`, et le commentaire qui l'affirmait encore avait servi à justifier de ne pas
étendre la règle : il est corrigé. Ce que le réglage évite est le **zoom parasite** quand deux taps
tombent à moins de ~40 px l'un de l'autre — 12 px mesurés entre deux étapes voisines, et en
réanimation on coche des étapes voisines à la chaîne.

### Un minuteur échu ne peignait pas son état sur les rangées compactes
Trouvé par la sonde du point précédent. `.tm-mini` (rangée compacte d'un minuteur ad hoc, le
« ＋ Minuteur PA ») partage l'id `tmcard-<id>` avec la carte pleine, et `syncTimerBtns` bornait son
basculement d'état à `.tmcard`. Mesuré sur **Chromium ET WebKit** : le modèle disait « échu », la
rangée restait NEUTRE tant qu'aucun re-rendu complet ne passait — alors que `.tm-mini.due` est bien
stylée (cadre et encre ambre). L'alarme n'était pas perdue (le quai porte l'ambre, canal
d'acquittement documenté), mais elle manquait là où l'œil se trouve quand le panneau est ouvert.
`paused` reste réservé à la carte pleine : `.tm-mini.paused` n'a pas de règle.

510 tests × 2 moteurs, 11 harnais verts, 289 contrôles d'accessibilité.

## [4.40.0] — 2026-07-26
### Les 4 dernières fenêtres : le harnais d'accessibilité couvre les 20 sur 20
`attPickModal`, `relPickModal`, `reportModal` et `newLibModal` étaient signalées « résistantes » en
v4.39.0. Elles ne résistaient pas : **mes appels étaient faux**. Les vraies signatures sont
`openAttPicker(entity, rerender)`, `openRelPicker(entity, rerender)` et surtout
`exportSessionReport(sessionId)` — un **ID**, pas l'objet session. `openNewLib()` est par ailleurs
gardée par `myIsAppAdmin` : garde métier légitime, dont la vraie barrière est la RLS serveur ; la
sonde la lève pour auditer le RENDU, ce qui est l'objet du harnais.

Le compte-rendu n'est atteignable que par le parcours COMPLET (ouvrir, démarrer, terminer) puisqu'il
lit `sessions`, les sessions **archivées**. C'est en le déroulant qu'un défaut de sonde plus gênant
est apparu.

### Défaut de sonde corrigé : trois fenêtres mesuraient un contexte FACTICE
Les surfaces « historique sessions », « terminer la session » et « complications » posaient
`state.view='read'; state.fiche=f; render()` à la main. Or ce n'est pas le point d'entrée :
`openRead(id)` appelle `buildRuntime` puis `bindStateToRuntime`, sans quoi **le Runtime n'est pas
installé** — le clic sur « démarrer la session » ne démarrait donc rien. Mesuré :
`Runtime.started=false`, `liveSessions=0`, `sessions=0`. Les trois fenêtres s'ouvraient bien, mais
dans un contexte SANS session vive, pas celui que le harnais annonçait ; une régression propre à la
session vive n'aurait pas été vue. Les trois passent par `openRead(f.id)`.

C'est le même travers que le `classList.add('on')` refusé en v4.39.0, en plus discret : reconstruire
un état à la main au lieu d'emprunter le chemin de l'utilisateur. Défaut du harnais, jamais de l'app.

### Résultat
**289 contrôles, 20 fenêtres × 2 thèmes, aucun défaut.** Les 4 dernières fenêtres n'ont rien révélé —
résultat en soi : les corrections de v4.37→v4.39 (associations `for=`, noms de champs, `[hidden]`
impératif, cibles) tenaient déjà sur les surfaces non encore auditées. Les 11 harnais restent verts,
510 tests sur Chromium et WebKit.

## [4.39.0] — 2026-07-26
### Harnais d'accessibilité : de 6 fenêtres auditées à 16 sur 20
Chaque fenêtre est ouverte par son **vrai point d'entrée**, après CONSTRUCTION de son contexte —
session vive pour « Terminer la session » et l'historique, sauvegarde de version pour « Versions
précédentes », complication déclarée pour l'index ⚡, document joint pour la visionneuse PDF. Jamais
un `classList.add('on')` : une fenêtre forcée vide n'a pas le contenu qu'on veut mesurer et
produirait des verdicts faux. Le mécanisme `prep` accepte donc désormais une **fonction**,
sérialisée par Playwright — la mise au point a d'ailleurs confirmé que la CSP du projet **interdit
bien `eval()`** : la première version de la sonde, qui passait du code en chaîne, a été bloquée.

Les 4 dernières (`attPickModal`, `relPickModal`, `reportModal`, `newLibModal`) résistent encore :
leurs points d'entrée attendent des arguments ou un état non reconstitué. Signalé plutôt que
contourné.

### Ce que ces dix fenêtres ont révélé
- **Un faux positif du harnais — corrigé dans le harnais, pas dans l'app.** `#pendToggle` était
  signalé à 13×13 px, sous le seuil de 24. Mais son `<label>` parent fait **358×65 px** et coche la
  case au clic : la CIBLE au sens de WCAG 2.5.8 (« la zone qui accepte l'action du pointeur ») était
  donc largement conforme. Le harnais mesure désormais le label quand il en existe un — même esprit
  que la recherche de l'anneau de focus sur les ancêtres, déjà en place. Agrandir les cases pour
  faire taire ce contrôle aurait été un changement visible pour un défaut inexistant.
- **Mais les cases se LISAIENT mal** (décision utilisateur) : aucune règle du projet ne les
  dimensionnait, elles gardaient les ~13 px du navigateur — dont l'interrupteur de sécurité
  « Exiger une validation pour les nouveaux comptes ». Passées à **20 px** avec
  `accent-color:var(--primary)` : la case cochée prend le bleu de l'app au lieu du bleu système.
  Appliqué aux **quatre** cases de l'app (confirmation, suppression locale, validation des comptes,
  boucle d'un minuteur) — les styler une par une aurait recréé l'incohérence.
- **Le bruit réseau est filtré nommément** : les fenêtres liées au compte interrogent Supabase et
  crient `ERR_INTERNET_DISCONNECTED` hors réseau. C'est le contexte de la sonde, pas un défaut de la
  page ; seul ce motif est filtré, pour ne pas masquer une vraie erreur.

**241/241** contrôles d'accessibilité — contre 121 avant, sur un périmètre deux fois plus étroit.

510 tests × 2 moteurs, 22/22 doctrine, 241/241 accessibilité, 163 contrôles d'audit, 10 sondes.

## [4.38.0] — 2026-07-26
### Tous les champs de l'éditeur ont enfin un nom
**39 champs sur 53 n'étaient nommés que par leur `placeholder`** — qui disparaît dès qu'on tape.
Concrètement : on revient sur un champ déjà rempli, et plus rien ne dit ce qu'il contient ; un
lecteur d'écran annonce « champ, texte » sur ce qui est peut-être la dose d'un protocole de
réanimation. C'est WCAG 3.3.2 et 4.1.2, et c'est l'antipattern le plus répandu des formulaires.

Le diagnostic a montré que ces 39 champs n'étaient **pas de même nature**, et qu'un `aria-label`
uniforme aurait été la mauvaise réponse :
- **4 gabarits avaient déjà un `<label>` visible ET un `id`** : il suffisait de les associer
  (`for=`). Aucune duplication, et le libellé devient cliquable pour focaliser le champ.
- **Les autres sont des LIGNES DE LISTE** — « Ne pas oublier », étapes d'un bloc, options d'une
  décision — coiffées par un `<label>` de section qui ne peut être associé à aucune en particulier.
  Elles reçoivent un nom qui dit leur liste ET leur rang : « Ne pas oublier — ligne 1 »,
  « Étape 3 », « Libellé de la réponse 2 ».
- **Les rangées de minuteur et de compteur** reçoivent le nom de ce qu'elles règlent (« Nom du
  cycle », « Nom du chronomètre », « Nom du compteur »), et le sélecteur de relance — jusqu'ici
  nommé par un simple `title`, pis-aller que tous les lecteurs ne lisent pas et qui n'existe pas
  sur mobile — reçoit un vrai `aria-label`.

Vérifié : **0 champ anonyme et 0 champ nommé par son placeholder** sur les 53 de l'éditeur, et
**aucun nom n'est une simple copie du placeholder** (contrôlé explicitement — recopier « ex. Oui »
n'aurait rien nommé du tout).

Aucun changement de rendu : le diff est de 11 lignes modifiées pour 11, uniquement des attributs,
et aucune règle CSS du fichier ne cible `label[for]` ni `[aria-label]` (vérifié).

510 tests × 2 moteurs, 22/22 doctrine, 121/121 accessibilité, 143 contrôles d'audit, 10 sondes.

## [4.37.0] — 2026-07-26
Deux garde-fous élargis, et **un bouton fantôme trouvé grâce à l'un d'eux**. Aucun changement de
rendu voulu — et aucun constaté, vérifié par comparaison des couleurs calculées avant/après dans
les deux thèmes.

### Garde-fou couleurs — il ne voyait que la moitié de la règle
`check-colors.mjs` n'inspectait que les **hex**. Un token recopié en DÉCIMAL passait donc au
travers, et c'est exactement la dérive que la règle proscrit : cinq occurrences de `rgba(16,27,40,…)`
— la valeur de `--ink` — vivaient dans les voiles et les élévations. Si `--ink` changeait, elles
seraient restées derrière.

Sur les 34 valeurs littérales du CSS, le tri est net et toutes ne sont pas des dérives :
- **5 étaient de vraies copies de token** → tokenisées, à valeur **strictement identique** :
  `--scrim-soft` (voile du menu de catégories), `--scrim` (fenêtres), `--scrim-full` (visionneuse
  d'image), `--shadow-dock` et `--shadow-bar`. Aucun override sombre ajouté : ces valeurs n'en
  avaient pas, en créer un serait un changement visible.
- **Le reste n'est PAS de la palette** et est exempté avec sa raison dans le script : noir et blanc
  PURS (profondeur, voiles neutres — ils ne portent aucune sémantique de registre) et les deux
  teintes de l'alerte de minuteur, dérivées d'aucun token. Un garde-fou qui crie sur ce qui va bien
  finit ignoré.

Le contrôle accepte désormais `rgb()`, `rgba()`, `hsl()`, `hsla()`. Contre-épreuve faite : remettre
`rgba(16,27,40,.55)` à la place de `var(--scrim)` le fait échouer.

### Harnais d'accessibilité — de 2 fenêtres auditées à 6
Il ne mesurait que `#planModal` et `#refModal` sur les **20** `.ai-modal` de l'application. Quatre
de plus y entrent (dialogue Créer, gérer les catégories, fenêtre Compte, « où sont mes fiches »),
ouvertes par leur **vrai point d'entrée** — jamais par un `classList.add('on')`, qui donnerait une
fenêtre vide et des verdicts faux. Les 16 autres exigent un contexte construit (session vive,
document joint, sélection, erreur de synchro) : mesuré, aucune ne s'ouvre par un simple appel —
c'est un chantier à part, avec une fixture par fenêtre.

**Ces quatre fenêtres ont immédiatement révélé deux défauts réels :**
- **`[hidden]` était une suggestion, pas une instruction.** La feuille du navigateur pose
  `display:none` pour cet attribut, mais avec une spécificité si faible que toute règle de classe
  portant un `display` l'écrase. Le projet compensait par une règle ponctuelle par composant —
  **vingt** au total — qu'il fallait penser à écrire, et `.tlink` avait été oublié : `#authAnon`,
  pourtant marqué `hidden`, s'affichait en **bouton VIDE de 20×32 px** dans la fenêtre Compte.
  Une règle globale `[hidden]{display:none!important}` ferme la classe entière de bugs ; vérifié
  qu'aucune règle du fichier n'affiche volontairement un élément `[hidden]`.
- **`.crt-chev`** (le chevron des cartes du dialogue Créer) était en `--line-strong` : 4,32:1, sous
  le seuil AA. C'est la règle déjà écrite dans `AGENTS.md` — `--line-strong` vise 3:1 pour les
  BORDURES et échoue en couleur de TEXTE — simplement jamais appliquée ici, faute que cette fenêtre
  soit mesurée. Passée à `--ink-soft`.

**121/121** contrôles d'accessibilité (117 avant l'élargissement, sur un périmètre plus étroit).

510 tests × 2 moteurs, 22/22 doctrine, 121/121 accessibilité, 143 contrôles d'audit, 10 sondes.

## [4.36.0] — 2026-07-26
### Corrigé — 1,77 Mo chargés pour ne rien dessiner
Ouvrir une fiche portant un PDF déclenchait le chargement de **pdf.js en entier** — `pdf.min.js`
389 Ko à +106 ms, `pdf.worker.min.js` 1 384 Ko à +181 ms — alors qu'aucun document n'avait été tapé.
Cela contredisait la règle du projet (« pdf.js chargé paresseusement, `import()` au premier document
OUVERT, jamais au démarrage »), sur l'écran de soin lui-même.

**Et c'était pire que ça.** Depuis la v4.23.0, la liste « Documents » d'une FICHE a quitté la colonne
d'action pour la feuille « Consulter », qui ne s'ouvre qu'à la demande. Mesuré à l'ouverture d'une
fiche : **0 rangée `[data-att]`, 0 emplacement `[data-thumb]` dans toute la page** — les 1,77 Mo
n'avaient littéralement rien à peindre. La chaîne `bindReadEvents` → `bindAttList` →
`hydrateAttThumbs` appelait la génération de vignettes **inconditionnellement**, alors que
`bindAttList` cherche ses rangées dans `main`, où il n'y en a plus. Travail intégralement perdu, et
redondant de surcroît : `renderRefSheet` rappelle `hydrateAttThumbs` à l'ouverture de la feuille,
là où les rangées existent.

Correctif d'une ligne — ne générer les vignettes que si une rangée est réellement dans le flux :
`if(main.querySelector('[data-thumb]')) hydrateAttThumbs(entity);`. Vérifié sur les trois cas qui
comptent : fiche seule → **0 Ko au lieu de 1 773** ; feuille « Consulter » ouverte → pdf.js chargé
et vignette peinte (96×128 px) ; **protocole → comportement inchangé** (ses documents sont dans le
flux, la condition est vraie pour lui).

> Nuance conservée pour la suite : ce n'est pas du réseau en usage normal (`sw.js` précache pdf.js à
> l'installation), mais le PARSING de 1,8 Mo de JS minifié et le démarrage d'un worker, en CPU, sur
> la vue utilisée pendant un soin. Le travail était différé par `_idle()` — donc il ne bloquait pas
> le premier rendu — mais une tâche d'idle n'est pas préemptible une fois commencée.

### Sécurité serveur — réserve de v4.34.0 LEVÉE
Les modifications SQL n'avaient pas pu être exécutées ici (ni Postgres ni Docker sur le poste) et
étaient livrées relues à la main. **Elles ont été rejouées sur l'instance réelle** : `schema.sql`
appliqué sans erreur, et `rls-tests.sql` répond « ✅ TOUS LES TESTS RLS PASSENT » — donc la
**section 13** (élévation de privilège, rôle anonyme, invitation à e-mail non vérifié) passe, et le
durcissement (`revoke all … from anon`, `alter default privileges`, `email_confirmed_at` exigé)
n'a rien cassé du flux existant.

510 tests × 2 moteurs, 22/22 doctrine, 73/73 accessibilité, 135 contrôles d'audit, 10 sondes.

## [4.35.0] — 2026-07-26
**Phase 4 de l'audit externe : simplification de la structure**, validée sur plan. Aucune ligne de
code applicatif touchée — documentation, arborescence et maintenance du dépôt. Les mesures ont
contredit l'énoncé de départ sur trois points, et le plus gros gain n'était pas dans la doc.

### Le plus gros gain : 144 Mo dans `.git`
- **151 Mo → 6,2 Mo en 2,8 secondes**, par un simple `git gc`. Mesuré avant : `count: 2922` objets
  **lâches** occupant 152 232 Ko, contre 219 objets packés tenant dans 1,1 Mo. `design/ds/`
  représentait **190 Mo sur 365 Mo** de blobs de l'historique, ses 20 fiches de ~275 Ko étant
  réécrites en bloc à chaque `design:build` (46 commits). Elles sont quasi identiques entre elles et
  d'une version à l'autre : elles se delta-compressent presque parfaitement.
- **Conclusion importante : `design/ds/` n'a AUCUN problème de structure.** L'hypothèse d'une
  dé-duplication de son CSS est ÉCARTÉE — l'autonomie de chaque fiche est intentionnelle (l'outil
  distant les lit isolément), la duplication en est le prix assumé. Ce n'était que de la maintenance
  jamais faite. Vérifié après coup : HEAD identique, 299 commits, 125 tags, `git fsck` sans erreur.

### Documentation — 9 → 8 fichiers, et un point d'entrée
- **`AGENTS.md` reçoit un socle « Si vous ne lisez qu'une chose »** : 14 règles qui ne se négocient
  pas (publication, `npm run check`, hashs CSP, `esc()`, `migrate()`, `safeId()`, tokens de couleur,
  registres, plancher 11 px, hauteurs sous zoom, mode crise jamais interrompu, compatibilité
  ascendante, zéro dépendance, vérification d'une suppression au grep) — suivies d'une **carte
  thématique** qui renvoie aux intitulés existants. Le problème n'était pas la longueur du fichier
  mais sa PLATITUDE : 1 297 lignes en une seule liste, sans point d'entrée, où l'on ne pouvait pas
  savoir ce qui est impératif sans tout lire. **Le diff est un AJOUT PUR** (+64/−0 lignes) : aucune
  règle déplacée ni réécrite, vérifié ligne à ligne contre la version précédente.
- **`CHANGELOG.md` : 221 Ko → 51 Ko** (112 → 20 entrées). Les 92 plus anciennes rejoignent
  `CHANGELOG-archive.md` **telles quelles** — 153 entrées avant, 153 après, zéro ligne de contenu
  absente (vérifié par comparaison exhaustive). La règle d'archivage existait déjà et n'avait servi
  qu'une fois ; elle est maintenant inscrite dans la règle de publication, avec son seuil.
- **`design/icons/README.md` fusionné dans `design/README.md`** — deux fichiers pour un seul sujet.
  Au passage, deux erreurs corrigées : le tableau des icônes listait `icon-512.png` **deux fois**
  avec des origines contradictoires, et `design/README.md` annonçait 15 fiches pour 20.
  `scripts/build-favicons.mjs` pointait vers le fichier supprimé : référence mise à jour.
- **`design/ds/GUIDELINES.md` remis à jour** (daté v4.22) : il décrivait encore au présent les trois
  affichages du Plan et le fil d'ancêtres sticky, supprimés en v4.25.0. Or ce fichier est **poussé
  tel quel** vers le projet Design distant : il documentait un composant inexistant auprès d'un
  outil externe. Son idée survit d'ailleurs ailleurs — l'épinglage des bandes-questions du mode
  statique (v4.32.0) — et c'est dit.

### Ce que je n'ai PAS fait, et pourquoi
- **`GUIDELINES.md` n'est PAS déplacé hors de `ds/`**, contrairement à ce que proposait le plan : la
  configuration de synchro dit « la synchro pousse `design/ds/` tel quel », le sortir d'un niveau
  l'aurait retiré du périmètre envoyé. Le plan annonçait donc −2 fichiers ; le résultat réel est −1.
- **Aucun `GEMINI.md`, `.cursorrules` ni `.github/copilot-instructions.md` ajouté.** `AGENTS.md` est
  le standard convergent (Codex, Cursor, Aider, Copilot le lisent), et `CLAUDE.md` l'importe en six
  lignes au lieu de le dupliquer. Ajouter des copies multiplierait les fichiers — contre la demande —
  pour créer la pire configuration : des sources qui divergent.
- **L'arborescence est inchangée.** Six dossiers thématiques, profondeur 3, aucun fichier égaré :
  « regrouper par fonctionnalité plutôt que par type » ne s'applique pas à un projet dont la seule
  fonctionnalité livrée est `index.html`. Et « réduire les niveaux d'abstraction » présupposait des
  couches qui n'existent pas : les deux seules indirections (`Data` sur trois backends, `Sync`)
  gagnent leur place.
- **Aucune règle supprimée d'`AGENTS.md`.** Le constat de phase 1 « AGENTS.md est un changelog
  déguisé » était EXAGÉRÉ : mesuré, 13 % des lignes citent une version, et ces citations sont de la
  traçabilité (« décision utilisateur v4.25.0 ») — elles disent pourquoi une règle existe et qui l'a
  tranchée, ce qui est précisément ce qui empêche de la « corriger » par ignorance.

### Une honnêteté sur les chiffres
Le plan annonçait « 433 Ko → ~230 Ko » de documentation. **C'est faux, et le total AUGMENTE
légèrement** (464 Ko) : les 92 entrées archivées sont DÉPLACÉES, pas supprimées, et le socle ajoute
6 Ko. Le gain réel porte sur le fichier qu'on LIT et que les outils chargent — `CHANGELOG.md`, −76 %
— et sur la navigabilité, pas sur le volume du dépôt.

510 tests × 2 moteurs, 22/22 doctrine, 73/73 accessibilité, 135 contrôles d'audit, 9 sondes dédiées.

## [4.34.0] — 2026-07-26
Troisième lot de l'audit externe : **sécurité serveur, couverture de test et documentation**. Aucun
changement de rendu. Un point à connaître : les modifications SQL n'ont PAS pu être exécutées ici
(ni Postgres ni Docker sur ce poste) — elles sont relues à la main, et doivent être rejouées sur une
instance de test avant d'atteindre la production.

### Sécurité serveur — trois trous de la suite RLS
- **Un membre invité perdait silencieusement son accès à sa première connexion.** Chaîne complète :
  `invite_member` cherchait le compte par e-mail SANS exiger `email_confirmed_at`, or la simple
  DEMANDE d'un code crée déjà la ligne `auth.users` (le client passe `create_user:true`) ; un tel
  compte n'a pas encore de ligne `user_status`, la garde d'approbation lisait donc NULL →
  `coalesce(…,'approved')` → invitation ACCEPTÉE ; puis sa première vraie connexion créait
  `user_status='pending'`, ce qui déclenchait `revoke_memberships` et EFFAÇAIT l'adhésion. L'admin
  voyait « ok », la personne apparaissait dans la liste des membres, et l'accès disparaissait sans
  trace ni message — le scénario le plus banal (« je t'ajoute, connecte-toi »). L'e-mail vérifié est
  désormais exigé : l'invitation prématurée retourne `not_found`, ce que le message client annonçait
  DÉJÀ (« la personne doit d'abord se connecter une fois ») — c'était le SQL qui ne tenait pas le
  contrat, pas l'interface. Le trigger de purge reste sur `insert or update` à dessein (le
  restreindre à UPDATE ouvrirait un trou) : la cause est fermée à la source, et c'est documenté sur
  place pour que la question ne se rouvre pas.
- **« Rien pour le rôle anonyme » était une ABSENCE de grant, pas une interdiction.** Le schéma
  n'ôtait jamais un privilège (0 `revoke` dans tout le fichier) : ne rien accorder à `anon` ne
  garantit rien si le projet porte des privilèges par défaut hérités de sa création, invisibles
  depuis le dépôt. Or la clé publishable est publiée en clair dans `index.html` : `anon` est
  utilisable par quiconque contre l'API REST. La posture affichée — « grants restrictifs PUIS
  RLS » — n'avait donc qu'un seul rempart démontrable. Ajout de `revoke all … from anon` sur les
  tables et les fonctions, **et sur les privilèges FUTURS** (`alter default privileges`), pour
  qu'une table ajoutée plus tard ne soit pas exposée par oubli.
- **Les politiques d'ÉLÉVATION DE PRIVILÈGE n'étaient jamais exercées.** Les onze écritures de la
  suite sur `memberships` et `user_status` étaient TOUTES faites en tant que propriétaire de table,
  qui CONTOURNE la RLS : `mem_write`, `lib_update`, `lib_delete` et `user_status_write` n'avaient
  jamais été testées, alors que `memberships` est la table dont dépendent toutes les autres
  politiques partagées (`member_role()` est consultée par cinq d'entre elles — une faille d'écriture
  y compromettrait tout d'un coup). **Section 13** ajoutée, chaque test en `set local role
  authenticated` : un viewer ne s'élève pas admin, un non-membre ne s'ajoute pas, un editor ne
  renomme ni ne supprime la bibliothèque, personne ne s'approuve soi-même, `anon` ne lit AUCUNE des
  sept tables publiques, et une invitation à un e-mail non vérifié est refusée.

### Tests — la cible principale n'était pas testée
- **`npm test` joue désormais Chromium ET WebKit.** iOS Safari est la cible principale (PWA
  installée sur iPhone, usage SMUR) et toute la suite tournait sur Blink seul — alors que le dossier
  « bande basse iOS » (v4.29.x) a précisément montré qu'un comportement WebKit peut couper l'écran
  sans qu'aucune mesure web ne le voie. Les fonctions pures ne sont pas à l'abri non plus
  (`DecompressionStream` de l'import .zip, regex, normalisation Unicode). WebKit absent produit un
  AVERTISSEMENT et non un échec, même dégradation douce que pour Playwright lui-même ; la CI
  l'installe. Résultat : **510 tests verts sur les deux moteurs**.
- `run-tests.mjs` ne JETTE plus les erreurs console quand la page ne boote pas : c'est le mode
  d'échec le plus probable (hashs CSP périmés, erreur de syntaxe) et il produisait jusqu'ici la
  sortie la moins lisible — l'exception emportait la seule information utile.

### Sécurité côté document
- **`<meta name="referrer" content="no-referrer">`** : c'est le SEUL des cinq en-têtes de `_headers`
  qui ait un équivalent balise, donc le seul récupérable là où `_headers` est ignoré — GitHub Pages,
  intranet nu. HSTS, `nosniff`, `X-Frame-Options` et `frame-ancestors` n'existent qu'en en-tête HTTP :
  rien à faire côté document, et c'est dit.
- La doc de déploiement sous-estimait la perte sur GitHub Pages : son tableau citait le `no-cache`
  sur `sw.js` mais omettait celui sur `/` et `/index.html`. Or la stratégie « cache d'abord »
  suppose que le rafraîchissement de fond atteigne le SERVEUR : servi depuis un cache
  intermédiaire, il peut réécrire une copie périmée dans le cache hors-ligne. Deux lignes ajoutées
  au tableau, et la conséquence expliquée.

### Documentation — trois affirmations fausses
- « **éditeurs alignés sur leur vue de lecture (fiche ≤ 860 px)** » : mesuré faux — l'éditeur rend
  1fr+320 au-delà de 1200 px. La règle du palier listait bien `body.view-edit`, mais le bloc 1000 la
  reprend **2 293 lignes plus bas** à spécificité ÉGALE (`:is()` prend le max de ses arguments) et
  gagne par l'ORDRE : la règle était MORTE tout en donnant l'illusion d'être appliquée. **4ᵉ incident
  de ce type** après `.read-grid`, `.cbt-n` et `.mode-seg`. Le membre inopérant est RETIRÉ de la
  règle du palier — zéro changement visuel, prouvé à 1400 px — plutôt que réaffirmé plus bas :
  aligner réellement l'éditeur sur 860+360 serait un changement VISIBLE, à décider séparément.
- Le **plan du monofichier** annonçait « ~5 600 lignes » pour 12 250 et décrivait 16 sections sur
  **54**. Il est présenté pour ce qu'il est — un RÉSUMÉ, pas un index — avec la commande `grep` qui
  donne l'index exact et à jour, et le découpage global en lignes. Des numéros de ligne figés dans
  la doc seraient périmés au commit suivant : mieux vaut la commande.
- `AGENTS.md` disait `npm test` sur un seul moteur.

510 tests × 2 moteurs, 22/22 doctrine, 73/73 accessibilité, 135 contrôles d'audit, 9 sondes dédiées.

## [4.33.0] — 2026-07-26
Second lot de l'audit externe : les correctifs dont le RENDU change, volontairement séparés du lot
invisible de v4.32.0. Chacun restaure une doctrine que le code violait, ou rend audible une surface
qui ne l'était pas. Deux découvertes faites en cours de route, hors du relevé initial.

### Corrigé — registres perdus
- **`.pl-stp` : la régression jumelle de v4.25.0.** La purge du Plan « Détails » avait emporté les
  cinq règles de cette classe alors que `ovPlanLadderHtml` l'émet TOUJOURS : pendant six versions,
  une étape **⚠ (memory item)** s'affichait en encre ordinaire dans le détail de « Se repérer »,
  avec les puces disque du navigateur, indiscernable d'une étape banale — dans une surface visible
  en permanence dans le rail dès 780 px et ouvrable d'un tap du quai de crise. Le pendant statique
  (`.sv-stp li.crit`), lui, n'avait jamais cessé d'être peint : deux surfaces de la même app
  donnaient une lecture différente du même contenu vital. Règles restaurées à l'identique de
  v4.24.0 ; vérifié dans les deux thèmes (⚠ = `--critical`, △ = `--verify`, graisse renforcée en
  second canal non chromatique, corps 11,5 px, puces « · »).
- **`.sv-x`** (compteur de passages « ×n » du statique) était émis sans aucune règle. Stylé en encre
  DOUCE et non bleue, contrairement à son jumeau `.pl-x` : dans le statique, « aucun texte bleu dans
  les cellules » — le bleu n'y marque que la position et la reprise. Copier `.pl-x` aurait réparé la
  taille en cassant la doctrine.

### Corrigé — contenu qui sortait de l'écran
- **Cinq `vh` NUS** subsistaient malgré la règle « toute hauteur relative à la fenêtre s'écrit
  `calc(…/var(--zf))` » : le réglage de taille du texte est un `zoom` sur `<html>`, qui agrandit la
  valeur APRÈS sa résolution. Conséquence mesurée à 130 % : dans la visionneuse d'image, 8 px
  d'image et **51 px de légende hors écran**, sans aucun défilement possible — et c'est précisément
  l'utilisateur qui a AGRANDI le texte qui voit mal. Corrigés (visionneuse, schéma, compte-rendu,
  feuille de catégories, sélecteur de documents) ; vérifié à 100 / 115 / 130 %.
- Le harnais qui prétendait couvrir cette règle ne regardait que deux surfaces nommées : il reçoit
  une **sonde générique** qui balaie le CSS résolu de tout élément visible et échoue sur toute
  hauteur bornante dépassant la fenêtre, quel que soit son nom.

### Accessibilité
- **La vue de lecture n'avait AUCUN titre.** Son unique `<h2>` était éteint par `display:none` à
  l'écran (il ne servait qu'à l'impression) — donc absent de l'arbre d'accessibilité — et les sept
  intertitres de section sont des `<div>`/`<span>`. Sur la surface CLINIQUE, il n'y avait donc rien
  à parcourir : il fallait traverser toute la fiche linéairement pour atteindre « Repères
  posologiques ». Le titre passe HORS ÉCRAN (propriétés de `.sr-only`, rien ne change à l'œil) et
  les intertitres reçoivent `role="heading" aria-level="2"` — sémantique sans changer la balise ni
  le CSS. Mesuré : **0 → 25 titres** parcourables, en portrait comme en paysage.
- **`#flowFull` et `.lightbox` : calques OPAQUES plein écran sans sémantique de dialogue.** Ni rôle,
  ni nom, ni déplacement du focus : mesuré, **14 tabulations sur 14 sortaient derrière le calque**,
  atterrissant sur « ⤢ Se repérer » ou des étapes cochables invisibles, en pleine session. C'est
  WCAG 2.4.11, le défaut corrigé en v4.30.0 pour les couches collantes et resté entier pour les
  overlays. Rôle + `aria-modal` + nom, focus déplacé à l'ouverture et RENDU à la fermeture, verrou
  de fond, piège Tab. Ils ne deviennent pas des `.ai-modal` (CSS distinct, et Échap leur est câblé
  nommément — les inscrire dans `_topModal()` aurait cassé leur fermeture, qui cherche un `.ai-x`
  qu'ils n'ont pas) : de nouvelles primitives `_layerEnter`/`_layerLeave` réutilisent les mêmes
  briques. L'image agrandie reçoit enfin un `alt` — sa LÉGENDE : `alt=""` la rendait décorative
  alors qu'elle est le contenu même de la couche. Vérifié : 0 sortie sur 14.
- **`--primary` en couleur de TEXTE** sur trois contrôles (lien d'évitement, pilule du mode lecteur,
  « Pourquoi créer un compte ? ») : 3,44:1 en thème sombre, sous le seuil AA. La règle du projet
  l'énonce déjà — en sombre `--primary` est un REMPLISSAGE, l'accent TEXTE est `--link` (8,24:1).
  Les trois y échappaient parce qu'ils vivent hors du périmètre du harnais.
- **Plancher typographique 11 px** : `.status-tag` (présent sur les cartes d'accueil, les vues de
  lecture et les éditeurs) et `.cx-tag` étaient à 10,5 px. Plus rien sous 11 px dans tout le fichier.
- **Six gabarits sans nom accessible** → 0 contrôle anonyme sur 53 (13 avant) : sélecteur de bloc
  suivant, durée d'un cycle (minutes/secondes), pas et valeur de départ d'un compteur, case
  « boucle », boutons de suppression. Les libellés « min », « s », « pas », « départ » étaient des
  `<span>` VOISINS, jamais associés — un lecteur d'écran annonçait « champ numérique, vide » sur la
  durée d'un cycle de réanimation. Reste 39 champs nommés par leur seul `placeholder` (antipattern
  connu : il disparaît à la saisie) — chantier distinct, consigné.
- **Orientation libérée** (`"any"`, décision utilisateur) : le manifeste verrouillait le portrait, si
  bien que l'app INSTALLÉE refusait le paysage — WCAG 1.3.4, et une tablette fixée au chariot
  d'urgence était inutilisable. Mesuré à 844×390 : aucun débordement, et le rail d'orientation
  APPARAÎT, donnant « action + structure de front » — l'idéal ECAM que le portrait n'atteint pas
  à 390 px.

### Découvert en cours de route (hors relevé initial)
- **Une cible tactile sous le seuil DANS la zone de crise** : `.dock-plan` (« Se repérer » /
  « Consulter ») mesurait **38 px** là où la crise exige 44. Le défaut avait échappé au harnais
  parce que son périmètre listait `#crisisDock` — le quai d'ÉTAT — mais pas `#crisisCtrl`, la rangée
  de COMMANDES qui en a été séparée en v4.25.0 : le trou de couverture cachait un défaut réel sur la
  surface la moins permissive de l'app. Corrigé par **halo** (`inset:-3px 0`) et non par
  grossissement : la hauteur de la zone haute est un coût PERMANENT en crise (177 px sur 640 déjà)
  et passer à 44 px l'aurait épaissie de 6 px ; c'est le patron déjà employé pour les contrôles de
  36 px de la barre. Vérifié à 360/390/1280 : cible 44 px, visuel inchangé, rangée toujours à
  59 px, aucun empiètement sur le quai. `#crisisCtrl` entre dans le périmètre du harnais.
- **GARDE-FOU « une classe émise a une règle »** (`scripts/check-classes.mjs`, dans `npm run check`).
  C'est le contrôle qui manquait pour attraper une purge ASYMÉTRIQUE — celle qui retire du CSS mort
  et, dans le même geste, du CSS vivant. Contre-épreuve faite : retirer les cinq règles `.pl-stp` le
  fait échouer. Il a d'ailleurs trouvé seul le défaut `.sv-x`. Trois exemptions documentées, toutes
  des CROCHETS de délégation JS (`.ov-wrap`, `.ov-journal`, `.seg-ic`). Son premier jet portait le
  faux négatif exact qu'il combat — il extrayait les sélecteurs commentaires COMPRIS, or les
  commentaires citent les classes qu'ils expliquent : noté dans le fichier.

510 tests, 22/22 doctrine, 73/73 accessibilité, 135 contrôles d'audit, 9 sondes dédiées.

## [4.32.0] — 2026-07-26
Premier lot d'un audit externe complet (phase 1 : relevé de 138 constats mesurés, 3 réfutés par
contre-audit ; phase 2 : correctifs à comportement INCHANGÉ). Trois défauts critiques éliminés,
chacun reproduit AVANT correction puis vérifié APRÈS par sonde Playwright — plus une demande
utilisateur : l'intitulé d'une décision reste sous les yeux en mode statique sur téléphone.

### Corrigé — trois chemins vers une page blanche
- **« Réparer l'application » pouvait rendre l'app INDISPONIBLE hors ligne.** Sa sonde réseau
  (`fetch('./sw.js')`) était interceptée par le service worker qu'elle s'apprêtait à détruire :
  `cache:'no-store'` pilote le cache HTTP, PAS le Cache API. Dès qu'un appel avait réussi une fois
  en ligne, `sw.js` était dans le cache stale-while-revalidate ; hors ligne la sonde répondait 200,
  la purge s'exécutait, et le rechargement donnait un écran blanc — en intervention, sans réseau.
  Le commentaire du code énonçait exactement ce risque et croyait s'en prémunir. Deux verrous :
  jeton unique par appel (`?_probe=`+Date.now(), clé de cache inédite) et **le worker refuse
  désormais de se mettre lui-même en cache**. Reproduit hors ligne, serveur arrêté : la sonde
  rejette maintenant avec ET sans jeton.
- **Un échec sur pdf.js supprimait TOUT le hors-ligne, silencieusement.** Le précache de 1,73 Mio
  vivait dans le même `waitUntil` que le noyau ; un 503 ou une coupure faisait rejeter
  l'installation entière (mesuré : `{active:false, controller:false}`, app non servie hors ligne),
  et le `.catch(()=>{})` de l'enregistrement rendait la panne invisible. Précache pdf.js
  best-effort ; `addAll` (tout-ou-rien) réservé à `CORE_ASSETS` = index.html + manifest, les
  10 icônes passant en best-effort — un favicon en 404 ne peut plus emporter l'app avec lui.
- **Le bouton « Recharger » de l'écran d'échec de démarrage était MORT.** Seul attribut `onclick=`
  du fichier, il était inerte : dès qu'un hash figure dans `script-src`, les navigateurs ignorent
  `'unsafe-inline'` et un gestionnaire inline exigerait `'unsafe-hashes'` (absent). C'était le
  dernier recours quand IndexedDB ne répond pas — et en PWA installée, il n'y a ni barre d'adresse
  ni bouton de rechargement. Câblé en DOM (jamais en assouplissant la CSP), avec témoin de
  non-régression : un `onclick` inline reste bloqué, violation CSP journalisée.

### Sécurité
- **`zipParse` : les bornes anti-« zip bomb » annoncées n'existaient qu'à moitié.** Rien ne bornait
  la SOMME des tailles, et N entrées de noms distincts pouvaient pointer sur le MÊME en-tête local
  (PoC exécuté : **18 Ko → 256 Mio**). Un `.zip` est le format de partage d'une bibliothèque : il
  circule par mail ou clé USB, sans contrôle. Trois bornes ajoutées — 256 Mo cumulés, offsets
  locaux dédoublonnés, et `inflateBounded` qui **arrête net la décompression** au-delà de la taille
  déclarée (`usize` est lu DANS le fichier : il peut mentir, et la vérification d'après ne servait
  à rien puisque la mémoire était déjà consommée). **Sept tests** ajoutés : la fonction, qui lit
  des octets étrangers, n'était couverte par aucun.

### Ajouté
- **INTITULÉ DE DÉCISION COLLANT en mode statique sous 640 px** (demande utilisateur, `svStickBands`).
  En pile, la bande-question sortait de l'écran pendant qu'on lisait encore ses étapes : **844 px
  de contenu lus sans elle** sur une décision imbriquée à 360×640, contre **0 px côte à côte** —
  le bornage à ce palier est donc celui du problème, pas un réglage esthétique. La bande s'épingle
  sous `--stick-top`, chaque niveau imbriqué se rangeant SOUS son ancêtre.
  **La hauteur n'est PAS forcée** : compacter à une ligne aurait rendu les décalages arithmétiques
  (donc CSS pur) mais TRONQUÉ toute question de plus de deux lignes — or la question EST
  l'information. D'où une mesure, réduite à UNE passe par rendu en fin de `svPaintArrows`
  (lectures groupées puis écritures, ÷ `zoomF()`), là où l'ex-fil d'ancêtres de la vue « Détails »
  recalculait à chaque événement de défilement. Décrochage NATIF (bornage par `.sv-decwrap`),
  z-ordre décroissant (modèle ECL : un niveau se replie DERRIÈRE son ancêtre), plafond 3 niveaux,
  `scroll-margin-top` pour le focus clavier (WCAG 2.4.11). Six contrôles au harnais de doctrine.
- **Garde-fou de fraîcheur des hashs CSP** (`csp-hashes.mjs --check`, dans `npm run check`) : le
  piège « on édite le script inline, on oublie de rejouer csp-hashes, la CSP bloque le seul script
  de l'app » s'était produit trois fois, dont une pendant cette session. Le même contrôle refuse
  tout attribut `on*=`, ce qui rend le correctif ci-dessus non-régressable. Contre-épreuve faite.
- CI : `npm run check` EN ENTIER (elle n'appelait que son premier maillon — `check-colors.mjs`,
  présenté comme « auto-exécutoire », ne tournait dans AUCUNE barrière automatique), `npm ci` au
  lieu de `npm install` (CI reproductible), cache des navigateurs Playwright, et les **11 harnais
  d'audit** en mode non bloquant — la doctrine était jusqu'ici vérifiée seulement si quelqu'un y
  pensait, mais un échec y demande un arbitrage humain, pas un blocage de merge.

### Supprimé — la purge v4.25.0, achevée
`AGENTS.md` affirmait la suppression du Plan « Détails » faite alors qu'elle l'était à moitié : la
pire configuration, puisque celui qui lit la doctrine croit le terrain propre. Étaient restés
**20 classes CSS mortes** (38 lignes, avec 45 lignes de commentaires décrivant en détail un
composant inexistant) : `.pl-cols`, `.pl-decwrap`, `.pl-nd*`, `.pm-views`, `.ovs-tgl`, `.pinchip`,
`.stuck`, `@keyframes pinIn`, `.pd0…pd3`, `.pl-end`, `.pl-offtag`, `.svgv`, `.diff-anchor`,
`.rail-sep`, `.ov-offtag`, `.ov-block.off` — chacune vérifiée à ZÉRO émission dans tout le dépôt
avant retrait. Plus quatre branches de délégation `data-plfold` inatteignables, deux
`querySelector('.pl-nd[data-plgo]')` qui ne pouvaient que renvoyer `null` (leur repli `||` faisait
croire à deux structures possibles), `ovPlanStick()` vide appelée depuis quatre sites, et la démo
`planDemo` de `design/build.mjs` qui PUBLIAIT le composant disparu — sept de ses classes n'ayant
plus aucune règle, le design system le documentait cassé (réécrite sur l'Échelle, à partir du
balisage réellement émis).
- **Un faux positif du harnais, plus grave que le CSS mort** : `audit-doctrine.mjs` cliquait sur
  `.pl-nd`, classe plus jamais émise — le contrôle passait SANS avoir rien cliqué, si bien que
  l'invariant « taper un nœud du plan ne DÉMARRE ni ne COCHE » n'était plus vérifié depuis v4.25.0.
  Corrigé sur `.pl-line[data-plln]`, avec une assertion qui vérifie que le clic a bien eu lieu :
  un contrôle qui ne peut pas échouer ne prouve rien.
- `.condensed` : le repli d'en-tête au défilement était décrit au présent par trois commentaires,
  renvoi « cf. CSS » compris, et la classe était posée par le JS — mais **la règle n'a jamais
  existé dans tout l'historique du dépôt** (vérifié). Ce n'était donc pas une régression mais une
  intention jamais implémentée : le toggle est retiré (aucun changement visuel possible) et la
  hauteur d'en-tête constante est désormais énoncée pour ce qu'elle est.

### Performance
- **`index.html` était téléchargé DEUX FOIS par publication** : `ASSETS` listait `'./'` ET
  `'./index.html'`, soit le même document sous deux URL que le cache HTTP ne peut pas dédupliquer —
  290 Ko en double, pour une entrée JAMAIS servie (le repli de navigation cherche
  `'./index.html'` d'abord). Entrée retirée : une seule copie en cache au lieu de deux.
- **La synchro reconstruisait tout le DOM après VOS PROPRES modifications.** `_pullTable` comptait
  les lignes REÇUES et non APPLIQUÉES : or `_pushTable` pousse l'horodatage LOCAL et, dans `full()`,
  le pull précède le push — la ligne qu'on vient de pousser revient au pull suivant, n'est pas
  appliquée (horodatages égaux) et déclenchait quand même un `render()` complet, focus perdu et
  journal de plusieurs milliers de nœuds réécrit, en pleine session. Le compteur porte désormais
  sur les écritures effectives (`puts`+`dels`).
- Une réponse que le cache REFUSE d'enregistrer (quota, réponse partielle) devenait un ÉCHEC RÉSEAU
  pour la page : `respondWith` recevait la promesse qui contenait le `put`. Découplé, comme le fait
  déjà la branche de navigation — reproduit avec une réponse 206, qui atteint maintenant la page.

### Documentation
- `AGENTS.md` et `README.md` disaient que la CI rejouait `check` (faux pour sa moitié) et
  annonçaient « deux harnais Playwright » là où il y en a onze. Corrigé, avec la leçon de la purge
  incomplète consignée à l'endroit fautif.
- Six blocs de commentaires décrivaient au présent des symboles inexistants (`ovPlanTreeHtml`,
  `ovPlanPin`, `state.ovPlanView`, `#ovPlanD`, `data-plview`, `--pl-stick`) : un commentaire qui
  décrit un mécanisme absent est pire qu'absent — il envoie le lecteur suivant, humain ou IA,
  chercher ce qui n'existe pas.
- `release.sh` synchronise désormais `package-lock.json` (resté figé à 4.3.0 pendant 28 versions,
  alors que `npm ci` installe d'après ce fichier) — édité comme du JSON, jamais par regex.

510 tests (503 + 7), 22/22 contrôles de doctrine (16 avant), 133 contrôles d'audit, 3 sondes
dédiées (critiques 9/9, service worker 6/6, intitulé collant 8/8).

## [4.31.0] — 2026-07-26
Second lot de l'audit design externe (axes couleurs / hiérarchie / priorisation), décisions
utilisateur.

### Ajouté
- **Garde-fou couleurs auto-exécutoire** (`scripts/check-colors.mjs`, dans `npm run check`) :
  un hex n'est admis dans le CSS que dans une déclaration de token (`--…`), où qu'elle vive
  (`:root`, bloc sombre, blocs d'accent) ; seuls les nuanciers littéraux `.acc-sw` sont
  exemptés. La règle d'AGENTS.md n'est plus déclarative. Le garde-fou a d'ailleurs trouvé PLUS
  que les 4 hex de l'audit : des `#fff` de canevas et deux `stroke:#1f5fa6` — copie hex du
  token primaire, la dérive exacte que la règle proscrit.
- **Raccourci clavier vers la recherche** : « / » et Cmd/Ctrl+K focalisent la recherche de
  l'accueil (inerte dans un champ, sous une fenêtre, ou hors accueil).
- **`prefers-contrast: more`** : texte secondaire à l'encre pleine, filets au gris de composant.

### Modifié
- **Tokenisation complète** : `--shadow-primary(-sm)` (les cinq `rgba(23,71,127,…)` éparses),
  `--hover-dk(-hi)` et `--flow-hl-dk` (ex-hex des overrides sombres), `--lb-cap`/`--lb-ink`
  (lightbox), `--paper` (canevas SVG, pages PDF, impression), `--flow-cur` (nœud courant du
  SVG), `--on-primary` sur les remplissages verts/rouges. Zéro changement visuel (valeurs
  identiques), zéro hex hors token.
- **En session vive, la rangée méta de lecture s'efface** (statut, catégorie, validation —
  vus à l'ouverture, ils ne conduisent rien pendant le soin ; même doctrine que l'état de
  stockage retiré des pieds en crise). Sélecteur `:has(#cbTimers)`, écran seulement, saut
  absorbé par `renderKeepAnchor`.
- **« Non protégé » du pied d'accueil : registre NEUTRE** — un état permanent en ambre s'use
  (banner blindness) et émousse l'ambre des états actionnables (« presque plein », PDF
  manquants), qui le gardent. Le test unitaire encode la nouvelle règle.
- **Guide rouge/ambre de l'éditeur de blocs : `<details>` repliable** — ouvert tant qu'on ne
  l'a pas replié, puis le choix persiste (`ac-cg-folded`).
- **Bouton du mode lecteur : « ⤢ Lecteur »** — le glyphe des ouvertures plein écran (même
  grammaire que Se repérer/Consulter) le fait lire comme une surface. Décision d'audit : pas
  d'entrée dans le chrome de crise (12 px libres à 360 px, et une commande qui apparaît selon
  la largeur romprait la constance positionnelle) — les entrées restent la carte du bout et
  le menu ⋯.

503 tests (dont le test du registre de stockage mis à jour), 11 harnais verts.

## [4.30.0] — 2026-07-26
Correctifs P0/P1/P2 de l'audit design externe (axe « conformité aux normes »).

### Corrigé (P0 — mesurés avant/après)
- **WCAG 2.2 § 2.4.11 « Focus Not Obscured » (AA) : NON-CONFORMITÉ levée.** Un Shift+Tab
  remontant déposait l'élément focalisé ENTIÈREMENT sous les couches collantes (en-tête +
  commandes + quai : 238 px mesurés à 360 px en session — dont la case « Alerter, appeler du
  renfort » et l'étape critique « ⚠ RCP immédiate », masquées à 100 %). Le défilement déclenché
  par le focus clavier est celui du navigateur, que `stickBase()` ne voit pas : seul
  `scroll-padding` le pilote — `html{scroll-padding-top:calc(var(--stick-top,64px)+8px)}`
  (la variable existait déjà, mesurée et divisée par le zoom). Corollaire : le
  `scroll-margin-top:130px` forfaitaire de `.rt-panel` (qui s'ADDITIONNE désormais) est ramené
  à 6 px. Vérifié : 0 masquage après correctif ; sonde 2.4.11 ajoutée à `audit-a11y.mjs`
  (73/73).
- **Rangée de commandes `#crisisCtrl` rognée sur les deux largeurs mobiles les plus répandues.**
  Elle exigeait 386 px : « Cons. » perdait 11 px à 375 (iPhone SE/mini) et 26 px à 360 (Android
  standard), sans défilement horizontal — pixels INACCESSIBLES, débordement silencieux dans la
  zone de crise. Compression mesurée sous 400 px (gaps/paddings, recette v4.23.4) : ~346 px à
  360 après, positions constantes conservées. Sondes « sans rognage » à 360/375/390 ajoutées à
  `audit-doctrine.mjs` (15/15).

### Ajouté (P1)
- **Le retour SYSTÈME (Android, geste/bouton) ne sort plus de l'app en pleine session.**
  History API branchée (0 pushState/popstate jusqu'ici) : une entrée sentinelle ré-armée, le
  popstate empruntant le MÊME chemin que l'affordance visible — fenêtre du dessus (✕ ou clic de
  voile : « Terminer la session ? » ferme sur Poursuivre, jamais Terminer), sinon lecteur,
  schéma plein écran, visionneuse, sinon le « ‹ » d'en-tête (pile readStack + garde double-tap
  700 ms héritées). À l'accueil nu, le retour sort réellement (aucun appui mort) ; une
  sentinelle survivant à un rechargement est neutralisée au boot. Vérifié en scénario réel :
  dialogue fermé sans terminer la session, puis retour à la bibliothèque, puis sortie.

### Ajouté (P2)
- **Filet `forced-colors` (Windows High Contrast)** : `.acct-dot`, `.cat-dot` et `.seg-pill`
  gardent leur couleur (`forced-color-adjust:none`) — le reste s'appuie sur « la couleur jamais
  seule ». Filet minimal, à valider sur machine Windows réelle.
- **Dialogue de bienvenue : « Commencer » ancré en bas de la feuille sur mobile** (zone du
  pouce). Sous 780 px la fenêtre est plein écran : le bouton flottait à mi-écran dans ~700 px
  de vide. Carte en colonne flex, action au bord bas ; ordinateur inchangé.

503 tests, 11 harnais verts (a11y 73/73 avec la sonde 2.4.11, doctrine 15/15 avec les sondes
anti-rognage).

## [4.29.10] — 2026-07-26
### Retiré
- **Dossier « bande basse iOS » clos — correctif v4.29.9 confirmé sur appareil.**
  L'instrumentation temporaire est retirée : ligne de diagnostic de la fenêtre Compte
  (`ih/vv/dvh/sab/sat/scr/vvV/sc/ot`) et règle visuelle (`_vvRuler`, calque rouge + trait bleu
  au toucher). Pour ré-instrumenter un jour : tags v4.29.5 à v4.29.9. Restent en place, acquis
  durables du dossier : le verrou de fond par `overflow:hidden` (jamais de `position:fixed` sur
  `body`), les overlays dimensionnés par `--vvh` (visualViewport, resynchronisée en continu),
  et le fond peint sur `html` (ceinture rebond).

503 tests, 11 harnais verts.

## [4.29.9] — 2026-07-26
### Corrigé (bande basse iOS — LE COUPABLE)
- La règle visuelle (v4.29.8) a produit la preuve : sur l'ACCUEIL, `bottom:0` touche le bord
  physique de l'écran — la WebView est saine ; **fenêtre ouverte, il flotte ~60 px au-dessus**.
  Ce qui change entre les deux états : le verrou de fond passait `body` en
  `position:fixed; top:-scrollY` (v4.21.0). Sur iPhone, un body fixé RÉTRÉCIT le rendu des
  éléments fixés qui en descendent (~60 px coupés en bas) sans qu'aucune mesure web ne le voie
  (`ih/vv/dvh/vvV` disaient tous 874) — et cette bande était MASQUÉE depuis v4.23.3 par le fond
  peint sur `html` (le commentaire de l'époque décrivait déjà « une bande vide en bas à
  l'ouverture de n'importe quelle fenêtre » : il masquait le symptôme, le rétrécissement
  restait). **Le verrou change de technique** : `overflow:hidden` sur `html` et `body` (fiable
  depuis iOS 16), qui bloque le défilement de fond sans toucher au repère des fixés ; position
  restaurée au pixel en ceinture ; même périmètre qu'avant (toucher pour les dialogues, tous
  pointeurs pour les feuilles opaques). Vérifié par sonde : couverture 0→874, fond immobile au
  geste, position restaurée, déverrouillage propre (Chromium et WebKit).
- La bascule de la barre d'état vers `default` (entamée en cours d'investigation) est ANNULÉE :
  l'accueil est parfait en `black-translucent`, la meta n'était pas en cause.
- Diag + règle visuelle CONSERVÉS jusqu'à confirmation sur l'appareil ; retrait prévu ensuite.

503 tests, 11 harnais verts.

## [ [4.29.8] — 2026-07-26
### Diagnostic (bande basse iOS — instrumentation visuelle)
- Le diag v4.29.7 sur appareil est PARFAIT (`vvV 874px · sc 1.00 · ot 0` — la variable effective
  n'était même pas périmée) et la bande persiste, indépendante du défilement (confirmé
  utilisateur ET par sonde : fond verrouillé après défilement, fenêtre au pixel sur les
  3 moteurs). Toutes les hypothèses mesurables par des NOMBRES sont épuisées : les métriques
  disent « parfait », l'écran dit « coupé ». **Règle visuelle** : toucher la ligne diag dessine
  un calque ROUGE = la boîte que le CSS croit poser de `top:0` à `--vvh` (géométrie des
  overlays, graduée tous les 100 px, bords pleins) et un trait BLEU = là où le CSS croit que
  `bottom:0` se trouve. Une capture d'écran comparera la croyance CSS à la réalité physique :
  bord rouge bas au-dessus du bord d'écran = boîte déplacée/raccourcie au RENDU ; trait bleu
  au-dessus du bord = c'est `bottom:0` lui-même qui ment. Re-toucher retire la règle.

## [4.29.7] — 2026-07-26
### Corrigé (bande basse iOS, suite du dossier)
- Les captures en thème clair montrent DEUX anomalies : la bande basse (~60 px, les trois
  fenêtres) et les feuilles Se repérer/Consulter décalées vers le bas. Or le diag lit 874
  partout… au moment où il se calcule. Suspect principal : **`--vvh` posée au lancement (quand
  iOS annonçait encore 812) et jamais rafraîchie** — iOS corrige la géométrie de la WebView
  SANS émettre `resize` sur `visualViewport`. La variable est désormais resynchronisée sur tous
  les canaux (resize/scroll du visualViewport, resize fenêtre, orientation, retour au premier
  plan) ET à chaque tic d'horloge (~1 s, écriture seulement si la valeur change) : une hauteur
  périmée ne peut plus survivre plus d'une seconde.
- Diag enrichi : `vvV` (valeur EFFECTIVE de `--vvh`, celle que les fenêtres utilisent — si elle
  diverge de `vv`, l'obsolescence est prouvée), `sc` (échelle du viewport visuel — un zoom
  automatique résiduel se verrait ici) et `ot` (décalage vertical du viewport visuel — piste du
  décalage des feuilles). Champ e-mail vérifié à 16 px (pas d'auto-zoom iOS).

503 tests, 11 harnais verts.

## [4.29.6] — 2026-07-26
### Diagnostic (bande basse iOS, suite du dossier)
- Après réinstallation de la PWA, le diag sur appareil est redevenu SAIN : `ih 874 · vv 874 ·
  dvh 874 · sat 62 · scr 874` — la WebView couvre à nouveau l'écran entier (la géométrie était
  bien figée à l'installation, bug iOS `black-translucent`). **Mais une bande résiduelle est
  encore rapportée malgré ces mesures saines** : la cause est donc ailleurs (piste : padding
  bas de sécurité des cartes ? autre fenêtre ? viewport rétréci après clavier non restauré ?).
  La ligne de diag est CONSERVÉE dans la fenêtre Compte tant que le dossier n'est pas clos ;
  une capture de la bande actuelle (fenêtre concernée, thème clair de préférence) est attendue
  pour trancher.

## [4.29.5] — 2026-07-26
### Diagnostic (bande basse iOS, suite)
- Le diag v4.29.4 sur l'appareil tranche : `ih 812 · vv 812 · dvh 812 · scr 874` — les trois
  mesures CONCORDENT. La WebView de la PWA fait réellement 812 px sur un écran de 874 : il
  manque exactement la hauteur de la barre d'état (62 px), **hors de la zone accordée par iOS**
  — aucun contenu web ne peut s'y peindre (la tab bar s'arrête à la même ligne, invisible en
  sombre). Les fenêtres remplissent depuis v4.29.4 100 % de ce qu'iOS accorde ; le reste est un
  problème de coquille PWA (géométrie figée à l'installation ou style de barre d'état), pas de
  CSS. Ajout de `sat` (safe-area haut) au diag pour départager : `sat ≈ 59` = WebView ancrée en
  haut de l'écran et AMPUTÉE en bas (bug iOS `black-translucent`, se corrige souvent en
  réinstallant la PWA) ; `sat = 0` = WebView déjà sous la barre d'état (le style
  `black-translucent` est alors à abandonner).

## [4.29.4] — 2026-07-26
### Corrigé
- **Fenêtres coupées en bas (iOS, suite)** : la capture sur appareil montre que le défaut existe
  aussi en **PWA installée** — sans barre d'outils dynamique, donc `100dvh` (v4.29.3) ne suffit
  pas : cette unité ment sur cet appareil. Les overlays sont désormais dimensionnés par la seule
  source de vérité, **`window.visualViewport.height`** (variable `--vvh`, tenue à jour à chaque
  changement du viewport visuel — barre Safari, clavier, PWA), `100dvh` ne servant plus que de
  repli avant la première mesure. Effet secondaire bienvenu : clavier ouvert, les fenêtres se
  redimensionnent au lieu de passer dessous. Vérifié au pixel sur Chromium et WebKit à
  90/100/130 %.
- **Ligne de diagnostic temporaire** dans la fenêtre Compte (sous « Sur cet appareil ») :
  `ih / vv / dvh / sab / scr` — les quatre mesures de hauteur de l'appareil ; celle qui diverge
  désignera le coupable si la coupure persiste. À retirer une fois le bug clos.

503 tests, 11 harnais verts.

## [4.29.3] — 2026-07-25
### Corrigé
- **iOS Safari/PWA : les fenêtres plein écran n'étaient pas seulement recouvertes d'une bande —
  elles étaient COUPÉES en bas** (retour utilisateur : « le contenu ne scrolle pas sur cette
  bande »). Cause : un overlay `position:fixed; inset:0` se dimensionne sur le *grand* viewport
  iOS (barre d'outils repliée) ; barre visible, le bas de l'overlay passe derrière elle — et
  comme l'overlay est aussi le défileur, la fin du contenu est inatteignable : on peut scroller
  jusqu'au bout, mais le bout vit sous la barre. Correctif : tous les overlays défilables
  (dialogues, feuilles Plan/Consulter, visionneuse PDF, lightbox, mode lecteur, schéma plein
  écran) passent en `height:100dvh` (viewport *dynamique* : la fenêtre s'arrête au bord
  réellement visible et suit la barre), divisé par `--zf` (règle zoom v4.24.0), sous
  `@supports` — les navigateurs sans `dvh` gardent le comportement antérieur. Vérifié au pixel
  sur Chromium et WebKit à 90/100/130 % ; à confirmer sur l'appareil.

503 tests, 11 harnais verts.

## [4.29.2] — 2026-07-25
### Corrigé
- **Le ✕ de la carte-bilan de fin de session est ancré en haut à droite** (retour utilisateur) :
  sur petit écran, la carte passe en plusieurs lignes et le ✕ « dans le flux » (contournement
  v4.23.2) atterrissait au milieu, collé au bouton « Compte-rendu ». Rétabli proprement : carte
  `position:relative`, ✕ ancré `top/right`, place réservée par le padding — vérifié à 320/360/390
  et couvert par le harnais (contrôle « coin haut-droit » à 360 px).
- **Piste bande vide en bas (iOS Safari/PWA)** : les dialogues plein écran (< 780 px) avaient un
  conteneur au fond `--bg` sous une carte `--surface` — le rebond de défilement iOS révélait ce
  fond au-delà de la carte (bande étrangère en bas, invisible sur Chromium où le rebond n'existe
  pas). Le conteneur prend le fond de la carte. **À confirmer sur appareil** : si la bande
  persiste, une capture d'écran (quelle vue, quelle fenêtre ouverte) permettra de viser juste.

### Modifié
- **« Répéter en exercice » est grisé pendant une session réelle** (sous-titre « session en
  cours » — même patron que « Modifier ») : modèle *inhibit* ECAM, on ne propose pas
  l'entraînement pendant un soin. La rangée reste active pendant un exercice (la recommencer
  est justement son usage) ; la confirmation danger « Terminer et exercer » reste dans le code
  en garde-fou, mais n'a plus de chemin d'accès accidentel.

503 tests, 11 harnais verts.

## [4.29.1] — 2026-07-25
### Corrigé
- **L'entrée et la sortie du mode exercice ne sautent plus** (retour utilisateur) : la hachure
  vit désormais sur un `::before` en **fondu d'opacité** (~300 ms) — l'apparition, le retrait,
  **et le passage bandeau → en-tête au défilement** sont fondus au lieu d'un aplat instantané ;
  le fondu est neutralisé sous `prefers-reduced-motion`. Et le **saut de hauteur** est éliminé :
  à ≥ 780 px le bouton « Quitter l'exercice… » épaississait le bandeau de 12 px (bouton 36 px
  dans un bandeau de 44) — compacté à ce palier, halo conservant la cible de 44 px. Δ mesuré à
  **0 px** sur 360/390/430/780.

503 tests, 11 harnais verts (les sondes lisent la hachure sur le `::before`).

## [4.29.0] — 2026-07-25
Cinq retours utilisateur : le placard exercice suit le titre, le sélecteur ne bouge plus d'un
pixel, la pastille se glisse au doigt, trois micro-animations, et la méta de lecture se désencombre.

### Modifié
- **Le placard exercice SUIT LE TITRE** (retour utilisateur : hachurer le quai était illisible —
  annulé) : tant que le bandeau-titre est visible, lui seul porte la hachure ; au pixel où il
  passe sous la barre, c'est **l'en-tête** qui la prend — même mécanique de relais que la pilule
  « ▲ Exercice ». Le quai redevient une zone d'état propre : des chiffres n'ont pas à vivre sur
  une texture. Vérifié en capture dans les deux thèmes.
- **Guidé/Statique : les libellés ne bougent plus d'un pixel** à la bascule — la graisse passait
  de 700 à 800 sur le segment actif, ce qui élargissait le mot et décalait les deux libellés.
  Graisse constante partout (tab bar comprise, qui passait de 600 à 800) : l'état est porté par
  la pastille et la couleur. Mesuré à 0 px par le harnais.
- **La méta de lecture perd la pastille « ▲ Exercice : date »** (retour utilisateur : elle
  captait l'œil à côté de la date de validation pour une information non clinique) — la date du
  dernier exercice vit désormais en sous-titre de « Répéter en exercice » au menu ⋯
  (« dernier : ‹date› », sinon « aucune trace clinique ») et dans l'historique scindé.

### Ajouté
- **Glisser la pastille au doigt** (HIG iOS) sur les trois sélecteurs segmentés — Guidé/Statique,
  la tab bar Aides/Protocoles de l'accueil et le dialogue Créer (aucun n'est une vraie tab bar
  iOS : le geste y fait sens partout). Engagement au relâchement seulement (≥ moitié du trajet —
  rien de lourd ne se re-rend pendant le geste), un tap reste un tap (seuil 6 px), un drag
  n'émet jamais le clic du bouton sous le doigt.
- **Micro-animations non bloquantes** (transform/opacité/fond seulement, l'app reste utilisable
  pendant l'effet, inertes sous `prefers-reduced-motion`) : entrée/sortie du mode exercice
  (glissement de la hachure + pop de la pilule), retour par la pile d'origine (la vue entre dans
  le sens du geste), reprise après complication (la carte de reprise glisse en place).

`audit-modeseg` mesure désormais l'immobilité des libellés et rejoue un drag réel ;
`audit-exercice` vérifie le placard suiveur (en-tête hachuré au défilement, quai propre).
503 tests, 11 harnais verts.

## [4.28.0] — 2026-07-25
Quatre retours utilisateur d'un coup : pile de retour, mode lecteur enrichi, placard exercice
visible partout + bouton Quitter, menu ⋯ réordonné.

### Ajouté
- **Pile de retour fiche → fiche** : ouvrir une autre aide depuis une fiche (« Voir aussi »,
  complication externe, feuille Consulter) mémorise l'origine — le « ‹ » d'en-tête porte le
  **titre de la fiche d'origine** et y ramène ; il ne dit « Bibliothèque » que quand la pile est
  vide (AC 120-71B : le retour d'une interruption est prévu par le dispositif, pas laissé à la
  mémoire — les bandeaux de l'accueil restent la redondance, mais ils n'existent que si une
  session a démarré). **Garde anti double-tap 700 ms** (même mécanique que le retour d'aperçu) :
  deux taps nerveux ne traversent jamais deux niveaux.
- **Mode lecteur enrichi** (audit : le « un item à la fois » n'est pas le modèle aviation — l'ECL
  Boeing montre la liste entière avec un curseur, et le binôme soignant anticipe) :
  **bande minuteurs propre** — l'overlay couvrait le quai, or l'état ne disparaît jamais : tous
  les minuteurs, échus d'abord en ambre avec le mot « échu », sans « +n » (la bande passe à la
  ligne) ; **carte des blocs** (pastilles ✓/●/○ du rail, même `minimapData`) + **contexte local**
  (item précédent avec ✓, « suivant : … ») autour du challenge courant qui reste seul en 26 px ;
  **⚡ Complication(s)** accessible sans quitter le lecteur — l'index passe au-dessus de
  l'overlay, le lecteur reste ouvert pendant l'excursion (doctrine QRH : on change de checklist,
  pas de support) et la fin d'un bloc d'excursion propose « ↩ Reprendre », jamais « Terminer ».
- **« Quitter l'exercice… »** directement sur le placard hachuré ; le dialogue de fin est titré
  « Terminer l'exercice ? » (une action dit sa portée).

### Modifié
- **Placard exercice visible partout et dans les deux thèmes** (retour utilisateur) : les
  hachures alternent désormais surface/`--primary-soft` (le couple surface/surface-2 était quasi
  invisible en sombre — delta mesuré par le harnais dans les deux thèmes), et le **quai collant
  est hachuré aussi** : l'annonciation TRAINING ne quitte plus l'écran au défilement ; le relais
  d'en-tête devient la même pilule bleu pointillé.
- **Menu ⋯ réordonné** (retour utilisateur) : conduite en cours d'abord (⚡, Lecteur, Se repérer,
  Schéma, Consulter), puis cycle de vie de session (Exercice, Recommencer, Historique), puis
  gestion (Modifier, Versions, Dupliquer), puis exports ; Terminer… ferme toujours la liste.
  Avant, Modifier/Versions — désactivées en session — trônaient en tête : deux rangées mortes au
  moment où le menu sert le plus. `setMoreMenu` normalise les séparateurs (un groupe vide
  disparaît). **Icônes désambiguïsées** : « Historique des sessions » reçoit une boîte d'archives
  (elle partageait l'horloge-flèche de « Versions » — deux entrées, même dessin) et
  « Se repérer » reçoit un rail à lignes indentées, l'Échelle elle-même (l'ex-icône « plan »,
  quasi identique au « flow » du Schéma juste en dessous, est supprimée).

Nouveau harnais `scripts/audit-lecteur.mjs` (13 contrôles) ; `audit-exercice.mjs` passe à
20 contrôles (placard collant, delta des hachures par thème, bouton Quitter). 503 tests,
11 harnais verts.

## [4.27.1] — 2026-07-25
### Modifié
- **L'« Aperçu en direct » des éditeurs (colonne droite ≥ 1000 px) rattrape trois versions de
  retard** : la miniature rendait encore la grammaire d'avant v4.23.0 — numéros `01/02` devant les
  étapes (supprimés du rendu réel), chaque étape en boîte bordée (le réel est « normal = ligne,
  signalé = boîte »), case à cocher à droite (elle est à gauche), bandeau teinté rouge (le bandeau
  réel est blanc depuis v4.23.0 : jamais d'aplat rouge permanent). Une miniature qui montre
  l'ancienne grammaire apprend le mauvais rendu à l'auteur pendant qu'il rédige. Elle suit
  désormais le rendu réel : lignes à filet, boîtes teintées avec glyphe ⚠/△ en tête, pilule de
  réponse « challenge :: réponse », et la rangée « ⚡ Complication(s) » apparaît dès qu'une
  complication est déclarée. (L'aperçu PLEIN ÉCRAN, lui, passe par le vrai moteur de rendu et
  n'a jamais dérivé — seule la miniature était figée.)

Vérifié par sonde : glyphes, pilule, ligne plate, case à gauche, bandeau blanc, rangée ⚡.
503 tests, 10 harnais verts.

## [4.27.0] — 2026-07-25
Mode exercice — le second manque identifié par l'audit doctrinal (piliers EMIC : après « utiliser »
et « débriefer », voici « s'entraîner ») — et compte-rendu enrichi pour TOUTES les sessions.

### Ajouté
- **« Répéter en exercice » (menu ⋯)** : rejoue la fiche dans l'écran RÉEL, à l'identique — même
  journal, mêmes minuteurs, mêmes gestes. C'est un choix doctrinal, pas une facilité : Greig 2023
  montre que le transfert de l'entraînement exige la **fidélité de format** — un mode « simplifié »
  entraînerait au mauvais outil. Seule l'**annonciation** change, sur le modèle du placard TRAINING
  aviation : bandeau de titre **hachuré** + pilule « ▲ Exercice » en bleu pointillé (ni rouge ni
  ambre : un exercice n'est pas une alerte), et le chrono d'état dit « ▲ Exercice » — le
  « ● Session » **vert reste réservé au réel**. Démarrer un exercice par-dessus une session réelle
  vive exige une confirmation au registre danger (« Terminer et exercer »).
- **Zéro contamination clinique** : la session d'exercice est marquée `exercise` (les sessions
  vivent en local seulement — jamais dans l'export v3, jamais synchronisées : le drapeau est sûr) ;
  l'historique **sépare** « Sessions cliniques (n) » et « Exercices (n) », badge « ▲ EXERCICE » sur
  chaque rangée ; carte-bilan « **Exercice terminé** » au registre exercice ; compte-rendu
  **filigrané « EXERCICE »** avec la mention « répétition sans patient ». « Terminer » dit sa
  portée : « Terminer l'exercice… » vs « Terminer la session… » (AC 120-71B : une action dit
  exactement ce qu'elle fait).
- **Méta de fiche : « ▲ Exercice : ‹date› »** — seulement quand un exercice existe. **Aucun rappel
  « jamais répétée », aucune relance** (décision utilisateur : pas de nudge) ; le harnais vérifie
  l'ABSENCE de ce texte dans le DOM rendu.
- **Compte-rendu enrichi pour toutes les sessions, réelles comprises** (support du débrief) :
  section « ⚡ Complications » — chaque excursion horodatée (l'heure d'entrée est désormais
  mémorisée : `cxBack[seq]={id,t}`, les sessions v4.26.x en format chaîne sont normalisées à la
  lecture) — et section « Vérification (do-verify) » : n étapes constatées ✓✓ + chaque
  « △ écart » horodaté avec le texte de l'étape.
- Harnais `scripts/audit-exercice.mjs` (16 contrôles, dans `npm run audit`) — dont « la session
  réelle est INCHANGÉE » et un contrôle d'absence de nudge. Piège consigné : le `<script>` inline
  est un enfant de `body`, donc `document.body.textContent` remonte les commentaires du code —
  borner ce genre de sonde à `main`.

503 tests, 10 harnais verts.

## [4.26.1] — 2026-07-25
Deux retours d'usage sur les complications, tous deux retenus.

### Modifié
- **Un seul déclencheur constant, « ⚡ Complication(s) (n) », qui ouvre un index par événement** —
  au lieu d'un bouton par complication. C'est le retour utilisateur, et il est plus doctrinal que
  la version initiale : le QRH est **un** objet à index par onglets, le manuel de Stanford **un**
  manuel à onglets d'événements — on ne met pas un bouton de cockpit par urgence. L'appel
  automatique de l'ECAM ne vaut que pour les pannes *captées*, ce que l'application ne fait pas ;
  l'analogue honnête est donc l'index. Bonus : mot et position constants quelle que soit la fiche
  (plusieurs boutons rouges qui se ressemblent obligeraient à lire chacun sous stress), et l'écran
  d'action se désencombre. Coût assumé : un tap de plus, payé en grandes rangées dans l'index
  (événement + « interrompt le parcours — retour prévu » ou « ouvre : ‹aide› ↗ »).
  - Le menu ⋯ porte la même entrée unique « Complications (n) ».
  - **Le déclencheur vit désormais aussi sur un bloc de décision courant** (limite de la 4.26.0,
    levée).
- **Éditeur : la cible s'ouvre dans le sélecteur filtrable partagé** (même patron que « Voir
  aussi » et « Joindre un document ») au lieu d'un menu déroulant — la liste des aides peut être
  très longue. Deux groupes : **blocs de cette fiche** d'abord, puis **aides & protocoles** ;
  contrairement à « Voir aussi », une aide déjà liée reste sélectionnable.

### Interne
- Harnais `audit-complications.mjs` réécrit pour le nouveau flux : 20 contrôles, dont l'index
  (ouverture, contenu, Échap), le bloc de décision courant et le sélecteur d'éditeur.

---

Les versions **antérieures à 4.26.1** (jusqu'à 4.26.0 incluse) sont dans
[`CHANGELOG-archive.md`](CHANGELOG-archive.md), déplacées **telles quelles** — aucune ligne
réécrite ni perdue.

> **Règle d'archivage** : ce fichier garde les **20 dernières versions**. Au-delà, déplacer les plus
> anciennes dans l'archive au moment de la publication. Elle n'avait été appliquée qu'une fois en
> 112 entrées, et ce fichier pesait alors 221 Ko — la moitié de toute la documentation du projet.

## [4.26.0] — 2026-07-25
### Ajouté
- **Complications « à tout moment »** — l'aboutissement de l'audit sur la fonction de l'app : une
  complication (laryngospasme pendant une sédation, ACR pendant une analgésie…) ne s'entre pas par
  la séquence mais **quand l'événement survient**. C'est le modèle des procédures non-normales du
  QRH et du mode *failure-related* de l'ECAM, et l'écart le plus net que l'audit doctrinal avait
  identifié.
  - **Nouveau champ facultatif** `complications` sur la fiche : libellé d'événement + cible — un
    **bloc dédié de la fiche** ou **une autre aide cognitive entière** (demande explicite : une
    complication peut ouvrir une nouvelle aide ; la session en cours reste vive).
  - **Déclencheur** : boutons `⚡ Événement` sur la carte du bloc courant, à côté de l'avance — la
    bifurcation non-nominale près de l'avance nominale — plus une entrée par complication au
    menu ⋯ (accès constant si l'on est perdu). Registre alerte en contour, jamais rempli. Aucun
    chrome si la fiche n'en déclare pas.
  - **Excursion tracée** : chaque occurrence crée un **nouveau passage** au bout du journal (un
    événement qui se reproduit est un nouvel événement), marqué « ⚡ complication » en toutes
    lettres. « Terminer l'algorithme » disparaît pendant l'excursion — le parcours n'est pas fini,
    il est interrompu.
  - **Retour prévu, jamais laissé à la mémoire** : « ↩ Reprendre — ‹bloc interrompu› → », toujours
    actif (non bloquant). La reprise ouvre un **nouveau passage à cases neuves** : c'est la
    doctrine d'interruption d'AC 120-71B — après une interruption, on re-vérifie ; l'ancienne
    carte reste lisible juste au-dessus.
  - **Structure honnête** : un bloc de complication hors séquence ne prend **pas** de numéro de
    tronc (avant, il se lisait « l'étape d'après ») ; il vit dans une section « ⚡ À tout moment »
    de l'Échelle et du mode Statique.
  - Éditeur dédié (libellé + cible, blocs de la fiche puis autres aides), prompt IA mis à jour
    (bloc dédié hors séquence, 1 à 3 max, un événement relevant d'une autre aide se signale).
  - Export v3 inchangé : champ facultatif, un ancien client l'ignore et le bloc reste un bloc.

### Interne
- 9 tests purs (`migrate`, `cxAll`, `cxDetached`, exclusion `flowPlan`) — 503 au total — et nouveau
  harnais `scripts/audit-complications.mjs` (15 contrôles de bout en bout, dans `npm run audit`).

## [4.25.3] — 2026-07-24
### Modifié
- **La fenêtre « Consulter » ne contient plus que ce qui n'existe nulle part ailleurs.**
  Surveillances et repères posologiques en sont retirés : mesuré, ils pesaient **57 % de sa
  hauteur** (451 px sur 790) alors qu'ils sont déjà présents dans le fil de la prise en charge, en
  mode Statique, et — pour la posologie — dans la barre latérale sur grand écran, soit **quatre
  exemplaires**. Ces copies repoussaient de ~450 px le contenu réellement unique : on faisait
  défiler ce qu'on avait déjà sous les yeux pour atteindre ce qu'on venait chercher.
  - Elle contient désormais : différentiels → schémas → documents → références → voir aussi.
  - Hauteur mesurée sur une fiche réelle : **790 → 339 px**.
  - **Le nom « Consulter » est conservé** : ce sont les différentiels qui justifient son bouton
    permanent, et l'appeler « Documents » découragerait de l'ouvrir quand le tableau ne colle pas —
    précisément le cas où elle sert.

### Corrigé
- **Bouton mort possible** : la rangée d'accès (qui conditionne aussi le bouton de la barre)
  annonçait « Surveillances » et « Posologie ». Une fiche n'ayant que ces deux contenus aurait donc
  affiché le bouton… et ouvert une fenêtre vide. La condition suit désormais exactement le contenu
  de la fenêtre.

### Interne
- Nouveau harnais `scripts/audit-consulter.mjs` (ajouté à `npm run audit`) : composition, hauteur,
  présence des contenus retirés dans le flux, et invariant « aucun bouton sans contenu ».

## [4.25.2] — 2026-07-24
### Corrigé
- **Le bandeau ambre qui restait sur une étape en écart est supprimé.** Ce liseré de 3 px est le
  canal du **registre** de l'étape (⚠ critique / △ vigilance — une propriété de son *contenu*),
  alors qu'un écart est un **état de la passe de vérification**. Réutiliser le même trait pour les
  deux rendait le signal ambigu : impossible de dire si l'ambre annonçait « étape de vigilance » ou
  « écart constaté ». L'état de la passe reste porté, sans ambiguïté, par la pilule « △ écart ».
- **Le libellé est désormais identique pendant et après la vérification.** La passe disait
  « constaté », la trace durable disait « vérifié », et les glyphes n'apparaissaient qu'après :
  deux mots pour un même état. Partout « **✓✓ constaté** » et « **△ écart** » — le mot retenu est
  celui du geste (le bouton dit « Constaté ✓ »), car un compte rendu reflète la réponse donnée
  plutôt que de la reformuler.

### Interne
- Les deux points sont couverts par des tests dans `scripts/audit-verify-live.mjs`.

## [4.25.1] — 2026-07-24
### Corrigé
- **La pastille du sélecteur « Guidé / Statique » ne tombait pas en face du segment actif**
  (retour d'usage, capture à l'appui). Trois causes cumulées, toutes mesurées :
  - le composant de base porte un écart de 8 px entre segments — dont la tab bar a besoin, mais qui
    décalait la pastille ici ; et ma règle, de même spécificité que celle de base mais déclarée plus
    haut dans le fichier, perdait **par l'ordre de déclaration** (3ᵉ piège de ce type dans le
    projet — les règles de géométrie passent désormais par un identifiant, insensible à l'ordre) ;
  - les deux libellés n'ont pas la même longueur (64 px contre 81 px), et une répartition en flex ne
    peut pas les égaliser : chaque bouton reste calé sur son propre texte. Le sélecteur passe donc
    en **grille à deux colonnes égales**, dont la largeur s'aligne sur le libellé le plus long ;
  - en **thème sombre**, le fond de la pastille était plus foncé que sa piste — l'inverse du thème
    clair — et le segment actif se lisait donc comme inactif. Elle adopte le registre de sélection
    de l'application (teinte + bordure d'accent), lisible quel que soit le sens du contraste.
  - Écart mesuré désormais **nul** dans les deux positions et les deux thèmes.

### Interne
- Nouveau harnais `scripts/audit-modeseg.mjs` (ajouté à `npm run audit`) : mesure l'alignement de la
  pastille sur le segment actif, en thème clair **et** sombre.

## [4.25.0] — 2026-07-24
Refonte de la zone haute et de la couche de consultation, à partir d'un audit qui a montré que
l'application proposait **quatre représentations de la même structure** et mélangeait, dans une
seule rangée, ce qu'on **commande** et ce qui **se passe**.

### Modifié
- **Deux rangées collantes au lieu d'une : les commandes au-dessus, l'état en dessous.** C'est
  l'architecture ECAM à la lettre — sur un avion, les commandes vivent sur un panneau distinct de
  l'affichage. Les deux étaient fusionnés, d'où une bagarre pour la place à chaque ajout. Séparés,
  l'arbitrage disparaît, et la rangée d'état retrouve la place d'afficher deux minuteurs étiquetés
  sur téléphone au lieu d'un seul. Coût assumé : ~50 px permanents, soit 6 % de la colonne d'action.
- **La bascule Guidé / Statique rejoint la rangée de commandes, en première position.** Elle était
  dans le flux et **disparaissait au défilement** : être perdu en cours de soin obligeait à remonter
  toute la fiche pour changer de vue. Elle est désormais joignable à tout instant.
  - Elle passe **devant** « Se repérer », qu'elle gouverne (ce bouton s'efface en mode Statique) :
    le dessiner après était une inversion de hiérarchie.
  - Elle reste un **sélecteur segmenté**, pas un bouton à bascule : Guidé et Statique sont deux
    modes de rang égal, dont aucun n'est la négation de l'autre.
  - « Dynamique » devient « **Guidé** » — le mot dit ce que c'est.
- **« Plan » devient « Se repérer », et n'a plus qu'une vue : l'Échelle.** L'affichage « Détails »
  est supprimé : c'était la seule des trois vues à **recopier les étapes** (12 listes affichées
  contre 0 pour les autres). Elle rejouait donc la vue d'action au lieu d'être une vue d'ensemble —
  et, étant la vue par défaut, c'est elle qui faisait ressembler « Plan » à « Statique ».
  - **Le Schéma n'est pas perdu** : il rejoint le menu ⋯ et s'ouvre en **plein écran avec zoom**.
    Un accès direct chacun, plutôt qu'un sélecteur à faire défiler.
- **« Se repérer » et « Consulter » partagent le même glyphe ⤢** — elles font exactement la même
  chose, ouvrir une feuille plein écran ; l'un des deux affichait un ▸ qui suggérait « avancer ».
- **La feuille « Consulter » devient un document, plus un menu.** Toutes les sections sont dépliées
  par défaut : quatre sur cinq étaient repliées, et la seule ouverte d'office était une copie de ce
  qui est déjà dans le flux — on ouvrait donc une liste de choses à ouvrir. Tout déplié tient en
  ~977 px, soit une chiquenaude de défilement, contre quatre taps.
  - **Réordonnée par utilité** : différentiels d'abord (le motif principal d'ouverture en cours de
    soin, et le seul contenu clinique qu'on ne trouve nulle part ailleurs), puis surveillances et
    posologie (des copies), puis documentation et traçabilité.

### Interne
- Suppression du code devenu orphelin avec « Détails » : l'organigramme, tout le fil d'ancêtres
  collant, le sélecteur d'affichage, la préférence de vue, le défilement par vue de la 4.23.6, et
  ~51 règles CSS. L'historique reste dans git (tag `v4.24.0`) si la question devait être rouverte.

## [4.24.0] — 2026-07-24
### Ajouté
- **Mode « Vérifier » : le résultat s'affiche immédiatement**, item par item, au lieu d'attendre la
  fin du bloc. Chaque étape prend sa pilule « constaté » ou « écart » dès qu'elle est prononcée, et
  un **bilan vivant** (« n constatés · n écarts · n restantes ») coiffe la passe.
  - Plus conforme, pas moins : la boucle do-verify d'AC 120-71B est *challenge → réponse →
    confirmation*, et différer la confirmation à la fin du bloc casse la boucle.
  - Le marqueur lit la trace de la passe, **pas** l'état des cases : une étape cochée **avant** la
    vérification n'affiche donc plus un ✓ trompeur — elle reste « à constater » tant qu'elle n'a pas
    été observée, ce qui est tout le sens du Do-Verify.

### Corrigé
- **« Exporter en PDF » rend enfin le même document sur tous les appareils.** La sortie variait sur
  trois axes, mesurés : le réglage « taille du texte » s'appliquait au papier (0,9 / 1 / 1,3), le
  **rail de lecture s'imprimait** dès que la page atteignait 780 px — soit toujours sur A4 (≈ 794 px),
  donc son contenu sortait **en double** — et le titre changeait de corps (21 / 24 px). Les trois
  sont neutralisés à l'impression. Vérifié : pagination identique depuis un téléphone en texte XL,
  une tablette en texte M et un grand écran en texte S.
- **Défilement cassé quand la taille du texte est augmentée.** Le réglage est un zoom sur la page, et
  une hauteur en `vh`/`dvh` est calculée **avant** le zoom puis agrandie par lui : à 130 %, une
  hauteur « plein écran » occupait 1,3 écran. D'où les deux symptômes signalés — le bas des barres
  latérales (accueil et lecture) devenait **inatteignable**, et une fiche courte défilait **dans le
  vide** (240 px mesurés). Corrigé partout où une hauteur dépend de la fenêtre : rails, coque de
  l'accueil, feuilles plein écran, visionneuse PDF, fenêtre de catégories.
- **Un bloc de décision changeait de couleur selon qu'on y arrivait ou qu'on y remontait** (bordure
  bleue quand il était le bloc courant, ambre sinon). Il garde désormais **toujours son ambre** : le
  registre appartient au contenu, pas à un état de passage. La position reste marquée, toujours en
  bleu, par la pilule « VOUS ÊTES ICI » — un canal par signification.
- **Les options de branche (Oui / Non) étaient plus petites que les étapes cochables** (15 px contre
  16,5). Aucune raison documentée : choisir une branche engage au moins autant que cocher une étape.
  Alignées à 16,5 px.

### Interne
- Deux harnais ajoutés à `npm run audit` : `audit-zoom-scroll.mjs` (hauteurs de fenêtre sous zoom)
  et `audit-verify-live.mjs` (retour immédiat, registre des décisions, taille des options).

## [4.23.8] — 2026-07-24
### Modifié
- **« Recommencer » devient « Recommencer le parcours » et rejoint le menu ⋯.** Deux gestes voisins
  portaient presque le même nom : `↺ Refaire` ne reprend **qu'un bloc**, tandis que « Recommencer »
  effaçait **tout le chemin parcouru** — le libellé laissait croire à une action locale. Il annonce
  désormais sa portée, et quitte le haut du journal où il flottait, rattaché à rien.
  - Justification : ECAM réserve l'affichage permanent à ce qui sert la conduite **en cours** et
    appelle le reste à la demande ; AC 120-71B veut que la checklist montre ce qui aide à exécuter
    l'**étape courante** — « repartir du début » ne conduit rien. La constance positionnelle ECAM
    est mieux servie par le menu que par un bouton flottant.
  - Le geste « maintenir » n'existant pas dans un menu, la protection passe par une **fenêtre de
    confirmation** en registre danger, qui annonce ce qui est effacé **et ce qui est conservé**
    (chrono de session, minuteurs, compteurs, compte-rendu).

### Corrigé
- **« Lecteur » / « Vérifier » / « ↺ Refaire » touchaient le bord droit et le bas de la carte** du
  bloc : en les groupant sur une rangée (v4.23.7), leur marge individuelle avait disparu sans être
  reportée sur la rangée. Rembourrage rétabli, aligné sur la gouttière du titre.

### Interne
- CSS orphelin retiré avec le composant : `.ov-controls`, `.btn.btn-hold` et son exception dans
  `holdToReset` (les seuls boutons « maintenir » restants sont ceux des minuteurs et compteurs) ;
  démo du design system mise à jour.

## [4.23.7] — 2026-07-24
### Modifié
- **En-tête d'un bloc du journal : « Lecteur » et « Vérifier » ne s'empilent plus.** Quand le titre
  prenait la largeur, chaque bouton passait sur sa propre ligne (deux rangées gaspillées). Ils sont
  désormais **groupés sur une seule rangée sous le titre** (titre + « 0/5 » sur la 1ʳᵉ ligne,
  actions côte à côte sur la 2ᵉ), aligné à droite. Vérifié de 390 à 820 px.

## [4.23.6] — 2026-07-24
### Corrigé
- **L'ordre des bibliothèques changeait de façon intermittente à la sélection** (ordi et téléphone).
  Elles étaient triées par USAGE, et sélectionner une bibliothèque incrémentait son usage → elle
  remontait dans la liste. Tri désormais **par nom**, exactement comme les catégories : une liste de
  navigation doit être prévisible. (Le compteur d'usage `libUsage`/`bumpLibUsage`, devenu inutile,
  est supprimé.)
- **Le Plan partageait un seul défilement entre Détails / Échelle / Schéma.** Chaque vue **mémorise
  maintenant sa propre position** : scroller au milieu dans Détails, aller tout en bas dans Échelle,
  revenir à Détails → on retrouve le milieu. Chaque ouverture de la feuille repart du haut.

### Modifié
- **Icônes du quai (⤢ Plan, ▸ Consulter) et « ⤢ complet » agrandies.** Ces glyphes remplissent peu
  leur cadre et paraissaient petits ; portés de 15 à 18 px (quai) et le ⤢ de « complet » à 17 px,
  pour équilibrer le libellé.

## [4.23.5] — 2026-07-24
### Corrigé
- **La barre latérale de lecture « remontait » dès qu'on touchait n'importe quel bouton** (minuteur,
  compteur, son, « +Minuteur PA », « Noter l'heure »). Le rail a son propre `overflow-y:auto`, et
  un re-rendu reconstruit tout le DOM : son `scrollTop` retombait à 0. On capture la position avant
  et on la restaure après (comme le défilement du schéma). Le journal des actions passe en plus par
  une mise à jour **chirurgicale** (le seul panneau, sans re-rendu global).
- **Sélectionner une bibliothèque sur l'accueil faisait sauter le défilement horizontal** de la
  bande, contrairement aux catégories. On **re-centrait** la bibliothèque active à chaque rendu ;
  désormais la bande reste où on l'a laissée — même comportement que les catégories.
- **Minuteurs : libellé débordant et boutons tronqués sur écrans étroits** (retour d'usage, capture
  à l'appui). Un libellé à token long sans espace (« CUTANÉS/MUQUEUX/DIGESTIFS ») débordait la carte
  (→ `overflow-wrap:anywhere`) ; « Démarrer » et « Remettre à zéro » côte à côte tronquaient leur
  texte (« 05… », « MAIN… ») dès que deux cartes se partageaient une vue étroite — ils s'empilent
  maintenant sous 780 px (le palier 430 ne couvrait pas la bande 431-779 : tablette, fenêtre
  réduite, paysage). Cartes moins étroites en milieu de gamme (grille minmax 140 → 160 px).
- **« Recommencer » laissait « Algorithme terminé — surveillance en cours » affiché** : l'état
  `flowEnded` n'était pas remis à zéro (dans les deux modes, guidé et journal).
- **Espacements « collés »** : « +Minuteur PA » contre les cartes (un `margin-top:0` du rail écrasait
  le `margin-top` de base), la ✕ de suppression d'heure contre le filet du dessous (rangée à
  padding-bas nul), « Algorithme terminé » et le bloc « Contexte local » (numéros utiles) contre ce
  qui les précède.

### Modifié
- **« Son coupé » adopte la même forme que « Son activé »** dans le rail (fantôme, sans pilule) —
  l'état reste porté par l'icône barrée, le mot « coupé » et l'encre ambre (jamais la couleur seule).

## [4.23.4] — 2026-07-24
### Modifié
- **Le logo de l'accueil ne coûte plus un seul pixel de hauteur d'en-tête sur petit écran.**
  La rangée d'identité est en `flex-wrap:wrap`, et le flex **casse la ligne avant de rétrécir** :
  un dépassement de **7 px** suffisait donc à renvoyer les boutons d'action à la ligne entière et à
  ajouter **42 px** d'en-tête à 375 px (iPhone SE) — 38 px à 360 px. Trois réglages rendent les
  pixels manquants sans rapetisser le glyphe outre mesure :
  - logo **34 → 30 px** (il reste parfaitement lisible ; n'étant pas interactif, aucune règle de
    cible tactile ne s'y applique) ;
  - écart de colonne de la rangée **10 → 8 px** ;
  - mot-marque **20 → 18 px** sous 430 px — nécessaire pour 360 px, une largeur Android très
    répandue, et très au-dessus du plancher typographique de 11 px.
  Vérifié à **0 px de surcoût de 360 à 431 px**, le logo restant visible et le nom entier.

## [4.23.3] — 2026-07-24
### Corrigé
- **Bande vide en bas de page à l'ouverture de n'importe quelle fenêtre** (retour d'usage : Safari
  iOS et PWA installée). Cause : le canevas n'était peint que par **propagation** depuis `body` —
  or le verrou de fond des fenêtres met `body` en `position:fixed` sur écran tactile, donc **hors
  du flux** ; la zone qu'il ne couvre plus restait non peinte. En PWA standalone, la zone d'accueil
  (`env(safe-area-inset-bottom)`) est précisément une bande que `body` ne peint pas. `html` porte
  désormais le fond `--bg` lui aussi (il suit le thème, le token vivant sur `:root`), et le `body`
  verrouillé reçoit `min-height:100%`.
  - Non reproductible dans le harnais (Playwright n'émule ni la barre d'URL d'iOS ni les zones de
    sécurité) : la correction vise le mécanisme, vérifiée par la mesure que le canevas est bien
    peint et identique au fond de `body` dans les deux thèmes.
- **Le ✕ de la carte « Session terminée » était invisible** — il existait depuis la v4.16.3 mais
  `.notice-x` est `position:absolute` alors que la carte n'est pas `position:relative` : il se
  calait sur un ancêtre lointain, hors de la carte. Remis **dans le flux**, à la fin de la rangée.
  (Rien à trancher côté ECAM/QRH : fermer un bilan **consultatif** est un geste sûr et réversible —
  la vérité archivée reste la session ; le bandeau n'est pas une alarme.)
- **La carte « Session terminée » survivait à la suppression de sa session** dans l'historique, et
  son bouton « Compte-rendu » menait alors à un rapport introuvable. Garde posée **au rendu**
  (`!sessions.some(...)`) plutôt que dans chaque chemin de suppression — il y en a trois (session
  seule, suppression de fiche, purge) et un quatrième aurait été oublié.

### Interne
- Nouveau harnais `scripts/audit-session-card.mjs` (ajouté à `npm run audit`) : couvre les deux
  régressions ci-dessus — ✕ visible, dans la carte et cliquable ; carte retirée quand sa session
  disparaît.

## [4.23.2] — 2026-07-24
### Corrigé
Quatre défauts d'affichage du **rail de lecture**, tous signalés à l'usage et mesurés avant/après.
- **« Son activé » collait à la carte du dessous** : l'en-tête d'une zone du rail (`.rail-head`)
  n'avait aucune marge basse — le bouton, haut de 44 px, touchait la première carte. Écart mesuré
  0 px → **10 px**.
- **Cartes de minuteurs collées** : la remise à zéro `margin-top` du rail visait à la fois
  `.rt-grid` **et** `.rt-counters` ; elle ne doit viser que la première (celle qui suit l'en-tête).
  La dernière carte de minuteur et la première de compteur se touchaient. Écarts mesurés
  `[0, 10]` → **`[10, 10]`**.
- **« Journal des actions » non centré verticalement** quand le journal est vide — cause réelle :
  une **collision de noms de classe**. `.tk-panel.empty` réutilisait la classe générique `.empty`
  (états vides « Protocole vide ») et en héritait `.empty b{display:block;margin-bottom:6px}` ;
  comme `align-items:center` centre la boîte de **marge**, le titre montait de 3 px. Le
  modificateur est renommé `.tk-slim`. Centre du texte 19 → **22**, exactement celui de l'en-tête.
  - Cette même collision faisait aussi hériter `html[data-theme="dark"] .empty{background:…}`, de
    spécificité supérieure à `.tk-panel` : le panneau du journal avait donc un **mauvais fond en
    thème sombre**. Corrigé par le même renommage.
- **« ⤢ complet » et « Son activé » ne se ressemblaient pas** alors qu'ils occupent le même
  emplacement (fin d'en-tête de zone, même hauteur) : pilule blanche bordée d'un côté, texte nu de
  l'autre. Même **forme** désormais (fantôme, même rembourrage, même graisse) ; c'est la **couleur**
  qui porte le rôle — bleu = action (ouvrir la feuille), encre douce = état (un interrupteur).
  Le **son coupé** garde volontairement sa pilule ambre : c'est l'état risqué en crise, il doit
  ressortir ; le calme est réservé au nominal.

### Interne
- **`.gitignore`** : les sondes jetables écrites à la racine (`.nom.mjs`, `.nom.png`) sont désormais
  ignorées. Huit captures temporaires s'étaient glissées dans le commit v4.23.1 via un `git add -A` ;
  ce commit (non poussé) a été corrigé à la source. Les harnais qui restent vivent dans `scripts/`.

## [4.23.1] — 2026-07-24
### Ajouté
- **Logo de marque sur l'accueil**, à gauche du nom de l'application. Posé en **masque CSS**
  (`logo-glyph.svg`, le master sans tuile — seul son canal alpha sert) sur un aplat de couleur :
  un `<img>` ne se teinte pas, or un bleu fixe jurait avec les accents violet/framboise et pesait
  en thème sombre. Sa couleur est l'**encre** (`currentColor`), donc il suit le thème tout seul et
  ne concurrence aucun accent — l'accent colore déjà la loupe, les boutons et les liens de
  l'accueil. Le fichier est servi depuis la racine et **précaché** (`sw.js`) : hors ligne comme le
  reste. Affiché sur l'accueil uniquement, comme le nom qu'il accompagne.
  - Écartée sur mesure : la variante « tuile teintée » — à 34 px la tuile ne se détache pas du fond
    et le glyphe s'y noie.

### Modifié
- **Liseré des étapes signalées supprimé** (retour d'usage). Le vrai défaut n'était pas l'épaisseur
  du bord du bloc mais un **doublement** : la bande d'une étape ⚠/△ portait en plus son propre
  liseré de 3 px, collé au bord du bloc — deux traits verticaux parallèles. Les **fusionner** a été
  envisagé puis écarté : le bord du bloc est le canal de l'état du BLOC (le bleu « vous êtes ici »
  doit rester continu), le liseré d'une bande celui du registre de l'ÉTAPE ; les confondre ferait
  porter deux sens au même trait et hacherait le bleu. C'est donc le liseré de la bande qui part —
  teinte, case colorée, texte coloré et glyphe ⚠/△ marquent déjà l'étape sans ambiguïté.
- Le liseré gauche de 4 px des cartes reste **inchangé** (décision utilisateur) : l'asymétrie sur le
  bloc courant est réelle, mais uniformiser sur cette seule surface casserait la signature partagée
  avec les notices, la carte de fin de session et les cartes d'accueil.

## [4.23.0] — 2026-07-24
Refonte du chrome de crise à partir des maquettes hi-fi (téléphone / tablette / ordinateur),
conduite en lots vérifiés un à un, puis audit transverse. Chaque décision ci-dessous a été
**mesurée** sur l'app réelle, pas seulement affirmée.

### Ajouté
- **Zone haute de crise** hors de `header.bar` : `#crisisBand` (le TITRE, information constante,
  qui s'en va au défilement) et `#crisisDock` (l'ÉTAT VIVANT, rangée pleine largeur COLLANTE qui
  ne quitte jamais l'écran). La hauteur d'en-tête reste constante — zéro saut, rien à inhiber sous
  `prefers-reduced-motion`. **Ordre fixe `⤢ Plan · ▸ Consulter · ● Session · minuteurs`** : les
  contrôles constants sont AVANT la partie variable, sans quoi ils glissent (constance
  positionnelle ECAM).
- **Feuille « Plan » plein écran** (`#planModal`) — trois affichages persistés : Détails, Échelle,
  Schéma.
- **Feuille « Consulter »** (`#refModal`) : surveillances, différentiels, schémas, documents,
  références, voir aussi quittent la colonne d'action et s'ouvrent **en pull** (rangée de fin
  d'action, bouton du quai, menu ⋯) — jamais d'ouverture automatique. Restent DANS le flux :
  « Ne pas oublier », « △ À vérifier » et les repères posologiques (ce qui se consulte PENDANT un
  geste reste près du geste ; ce qui se consulte ENTRE deux gestes part dans la feuille).
- **Rail de lecture dès 780 px** : minuteurs → repères posologiques → Plan « Échelle » →
  horodatage. Colonne **entièrement continue, sans aucun sous-défileur borné**.
- **Rapprochement des repères posologiques** du bloc courant (`posoRank`/`posoSplit`) : troncature
  (« Adré » trouve « Adrénaline ») et table des voies dans les deux sens (« IM » ↔
  « intramusculaire »). Ce classement **RÉORDONNE, il ne FILTRE JAMAIS**.
- **Trace de vérification** (Do-Verify) : `verified` et `vgaps`, **distincts de `checked`**.
  Une passe laisse enfin un résultat consultable — « ✓✓ vérifié » (constaté par observation) et
  « △ écart » qui **survit à la sortie** de la passe. Stocké dans la SESSION seulement : export v3
  des fiches et format des clés inchangés.
- **Trois harnais d'audit** (`npm run audit`) qui MESURENT au lieu d'affirmer : `audit-a11y.mjs`
  (6 surfaces × 2 thèmes), `audit-doctrine.mjs` (ECAM/QRH/AC 120-71B en invariants observables),
  `audit-verify.mjs`.

### Modifié
- **Liste d'étapes épurée** : la box parente à bord bleu porte l'emphase « ici l'action », donc les
  étapes n'ont plus à être des boîtes elles-mêmes (ce double encadrement était la faute d'origine).
  Lignes plates uniformes à filet fin ; une étape signalée est une **bande intégrée** (teinte +
  liseré) qui file jusqu'aux bords du bloc. **Numéro `01/02/03` supprimé** (on coche dans n'importe
  quel ordre, et les renvois →/↺ visent le numéro de BLOC, conservé). **Case à cocher à gauche**,
  en colonne alignée au pixel — les listes cochables des protocoles l'avaient déjà à gauche, les
  deux sont désormais cohérentes. Glyphe ⚠/△ obligatoire : sans lui, rouge et ambre ne se
  distingueraient que par la teinte (WCAG 1.4.1).
- **Repère posologique = registre AMBRE, jamais rouge.** L'app se contredisait : la doctrine range
  « dose/dilution à vérifier » dans la vigilance et réserve le rouge à ce qui TUE si on l'oublie.
  Résultat constaté : trois masses rouges d'égale valeur à l'écran, donc inflation du rouge. Un `⚠`
  hérité reste LU et s'affiche en ambre — aucune migration de données.
- **« ✓ Validé(e) » ne s'affiche plus là où la DATE de validation est visible** (la date dit la même
  chose, en plus précis) ; sans date, la pastille reste. Les cartes affichent désormais la date.
- **Prompt IA** : règle d'or « la couleur est l'exception » avec **plafond de 2 étapes colorées par
  bloc, ⚠ + △ confondus** (souvent zéro) ; conséquences de la feuille Consulter et du rail sur la
  rédaction ; format porteur des repères posologiques.
- Bouton d'accès aux annexes nommé **« Consulter »** (abrégé « Cons. » sous 560 px — troncature du
  même mot, jamais un autre nom).

### Corrigé
- **Une zone d'état n'ampute jamais un nombre** : `fmtMs` ne bornait pas les minutes (3 h 25
  s'écrivait « 205:13 », illisible et assez large pour être rogné) → `h:mm:ss` au-delà de l'heure.
  Le quai **ajuste par la mesure** : tant que ça déborde il retire un segment (qui repasse dans
  « +n », donc annoncé), puis en dernier recours le chevron (décoratif) — jamais le « +n », jamais
  un chiffre. Des seuils de largeur en dur avaient été essayés et se sont révélés faux.
- **Débordement du quai jamais silencieux** : le « +n » n'était calculé qu'en étroit — à ≥ 780 px,
  trois minuteurs échus n'en montraient que deux, le troisième disparaissait sans un mot.
- **Ancrage et défilement** : `stickBase()` devient la source UNIQUE du « bas de ce qui est collé
  en haut » (un saut déposait le bloc visé ~52 px SOUS le quai, donc masqué), et `scrollWithin`
  remplace `scrollIntoView` pour toute navigation interne à un panneau (un renvoi tapé dans le rail
  déplaçait la PAGE de 261 px).
- **Verrou de fond des feuilles plein écran** (`.sheet-full`) à TOUS les pointeurs : la règle
  existante était bornée au tactile, la page continuait donc de défiler derrière sur ordinateur.
- **Un repère signalé n'est jamais replié — `⚠` ET `△`** : la protection ne testait que `⚠`, or la
  doctrine v4.23.0 marque la posologie en `△` ; elle ne couvrait donc plus rien, et une dilution à
  vérifier pouvait se replier.
- **Accessibilité (audit) — écarts anciens que le rail a mis sous les yeux** : `.tm-label`
  10,5 → 11 px ; cibles portées à 44 px (`.cn-btn`, `.tm-reset` — qui ÉCRASAIT le `min-height` de
  `.cn-reset` —, `.rt-add`, `.tk-add`, `.pl-nd`, `.pl-lnk`, `.rail-exp`) ; `--line-strong` retiré
  comme couleur de TEXTE (3,93:1) et `--primary` remplacé par `--link` en thème sombre (3,75:1).
- Chevron dupliqué sur les cartes d'accueil ; variables mortes (`gallery`/`docs`/`refs`) du flux
  fiche, orphelines depuis le déplacement vers la feuille Consulter.

## [4.22.5] — 2026-07-23
### Modifié
- **Icône plus grande sur macOS** (retour d'usage : « nickel sur iPhone, plus petite sur le Mac »).
  Le fichier n'avait pas rétréci — c'est le **conteneur** qui diffère : iOS pose l'icône plein
  bord, tandis que macOS (Safari « Ajouter au Dock », Chrome installé) place l'icône du manifest
  dans une tuile qui n'occupe que ~80 % du canevas du Dock. Un glyphe à 72 % du fichier n'y faisait
  plus que ~58 % de la case.
  - `icon-192.png` / `icon-512.png` (icônes `any` du manifest, celles que lit le Mac) portent
    désormais un glyphe à **~88 %** du fichier : après la marge macOS il retrouve ~70 % de la case,
    très proche du rendu iPhone.
  - **`apple-touch-icon.png` est inchangé** (glyphe ~72 %) : l'iPhone était déjà à la bonne taille,
    et il lit un fichier distinct — l'agrandissement macOS ne l'affecte pas.
  - Nouveau **`scripts/build-app-icons.mjs`** : régénère ces deux icônes depuis le master vectoriel
    (glyphe centré à 88 %, carré plein). Dev seulement, aucune dépendance runtime.

## [4.22.4] — 2026-07-22
### Modifié
- **Favicon : coins arrondis, et un jeu complet pour tous les moteurs** (le liseré persistait sur
  Safari seul après la v4.22.3). Deux causes distinctes, corrigées ensemble :
  - **Forme.** Un carré à angles vifs posé dans un emplacement déjà arrondi jure avec le fond de
    la case — c'est ce désaccord qui se lisait comme un liseré, pas un défaut du fichier. Le
    favicon prend donc le rayon du master d'aperçu (22,5 %). **Divergence assumée et documentée** :
    les icônes d'**application** restent des carrés pleins (iOS/Android posent leur propre masque,
    les pré-arrondir donnerait le double arrondi corrigé en v4.22.2) ; seul le favicon s'arrondit,
    parce que personne ne le masque.
  - **Sélection par le navigateur.** WebKit exploite `sizes` moins finement que Blink et peut
    retenir la dernière déclaration comprise — soit, en v4.22.3, `icon-192.png` et sa réduction
    ×12. Ce `<link>` est **supprimé** (le manifest porte déjà le 192 pour l'installation, seul
    endroit où cette taille sert) et la liste se termine désormais par le 32 px, si bien qu'un
    repli naïf reste correct.
### Ajouté
- `favicon.ico` (**16+32+48**, entrées PNG) pour les moteurs anciens et la requête implicite de
  `/favicon.ico`, et `favicon.svg` (vectoriel, net à toute taille). Avec les PNG 16/32, quatre
  déclarations couvrent l'ensemble des moteurs. Les deux nouveaux fichiers entrent dans `ASSETS`
  (`sw.js`) : hors ligne comme le reste.
- **`scripts/build-favicons.mjs`** : les favicons sont désormais **générés** depuis le master
  vectoriel de `design/icons/` (rendu à la taille finale — jamais un downscale de PNG —, `.ico`
  écrit à la main). Dev seulement : ni CI, ni dépendance runtime.
### Corrigé
- `.claude/serve.js` : types MIME manquants (`.svg`, `.ico`, `.pdf`). Un type absent retombait sur
  `application/octet-stream` — le fichier arrivait en 200 mais le navigateur refusait de le
  décoder, ce qui faisait échouer une vérification locale alors que l'hébergeur, lui, sert le bon
  type. Faux négatif rencontré en vérifiant ce correctif.

## [4.22.3] — 2026-07-22
### Corrigé
- **Liseré blanc autour du favicon dans l'onglet** (retour d'usage) : l'onglet ne recevait que
  `icon-192.png`, soit une réduction **×12** pour un emplacement de 16 px. À ce facteur, le
  filtre du rasteriseur échantillonne au-delà du bord de l'image (traité comme du noir
  transparent) et laisse une arête d'un pixel semi-transparente — lue comme un fin liseré
  blanc sur la barre d'onglets claire. Le fichier lui-même était sain (contour 100 % opaque,
  vérifié pixel à pixel sur les cinq PNG).
  - Ajout des **tailles natives** `favicon-16.png` et `favicon-32.png` (mêmes masters), déclarées
    avec leur attribut `sizes` ; `icon-192.png` reste déclaré en `192x192` pour les surfaces qui
    demandent grand (favoris, tuiles). Plus aucun rééchantillonnage dans l'onglet.
  - Les deux fichiers sont ajoutés à `ASSETS` (`sw.js`) : disponibles hors ligne comme le reste.
  - Règle ajoutée à `design/icons/README.md` : **servir la taille native de l'emplacement**, et
    vérifier qu'aucun pixel du contour n'a un alpha < 255 avant de livrer un export.

## [4.22.2] — 2026-07-22
### Modifié
- **Nouvelle icône de l'application** (handoff design) : un **cerveau** (cognition,
  mémoire) fusionné avec une **croix médicale**, glyphe blanc sur **bleu clinique
  `#1F5FA6`** — elle remplace le bouclier au tracé ECG. Le glyphe est *plein* : il
  reste lisible jusqu'à 16 px, sans variante simplifiée séparée.
  - **Carré plein, jamais de coins pré-arrondis** : iOS et Android appliquent leur
    propre masque. L'ancienne icône arrondissait elle-même ses angles — le masque du
    système venait alors *par-dessus* cet arrondi (double arrondi, glyphe rogné).
  - Les variantes **maskable** (192 et 512) sont construites sur le calque *adaptive
    foreground* aplati sur le bleu de marque : le glyphe occupe ≈ 62 % du canvas,
    donc reste dans le cercle sûr de 66 % quel que soit le masque du lanceur Android.
    L'ancienne paire ne respectait pas cette zone.
  - **Noms de fichiers inchangés** (`icon-192.png`, `icon-512.png`,
    `icon-{192,512}-maskable.png`, `apple-touch-icon.png`) : ni `ASSETS` (`sw.js`) ni
    `manifest.webmanifest` ne bougent — aucun risque sur la mise à jour du service
    worker. Les couleurs du manifest (`theme_color`, `background_color`) restent
    `#f2f5f8` : le splash garde la continuité avec l'app en thème clair, et la barre
    système continue d'être pilotée par `index.html` (thème + flash d'alarme) sans
    clignotement bleu à l'ouverture.
  - Masters vectoriels archivés dans **`design/icons/`** (avec les règles d'export :
    toute nouvelle taille se génère depuis les SVG, jamais par agrandissement d'un
    PNG). Ce dossier n'est **ni servi ni précaché**, et reste hors du périmètre
    généré par `design/build.mjs`.

## [4.22.1] — 2026-07-20
### Modifié
- **Fil d'ancêtres du plan : STICKY CONTINU** (retour d'usage — « ce serait mieux si
  elle suivait de manière continue ») : les cartes-questions **réelles** du plan
  s'épinglent désormais sous l'en-tête (`position:sticky`, top cumulé **mesuré** =
  base + hauteurs des cartes ancêtres — les hauteurs réelles de v4.14.3 résolvent la
  superposition qui avait fait abandonner le sticky v4.12). Plus de moment discret :
  la carte est *attrapée* par la pile, en continu, réversible au pixel — et plus
  **aucun mouvement autonome** (tout mouvement est le geste de défilement).
  - **Chaque niveau se replie DERRIÈRE son ancêtre** au décrochage (z-ordre `pd0…pd3`
    décroissant — modèle ECL : une sous-procédure terminée se referme dans sa
    procédure mère, et ré-émerge symétriquement à la remontée) ; le décrochage à la
    convergence est natif (sticky borné par le conteneur de la décision).
  - Carte épinglée : **compactée sur une ligne** (hauteurs stables) avec le chip
    « › option » de la branche en cours de lecture injecté dans la carte — calé
    **au pixel** sur la disparition de l'étiquette d'option (il la remplace à
    l'instant où elle passe derrière la carte ; tant qu'elle est visible, elle porte
    la réponse elle-même) et sans clignotement entre branches (zones jointives) ;
    apparition et changement animés (micro-animation v4.22.0, inerte sous
    `prefers-reduced-motion`), disparition instantanée.
  - **La pile synthétique `#plPin` est supprimée** (avec sa clé, son hystérésis, ses
    hauteurs mémorisées et la garde v4.21.0 « fixed dans un ancêtre transformé » —
    le sticky y est insensible). La carte épinglée est le vrai élément : tap = y
    aller, comme partout dans le plan. Sur papier : carte complète, sans chip.

## [4.22.0] — 2026-07-20
### Ajouté
- **Micro-animation d'entrée des bulles du fil d'ancêtres** (`#plPin`), **non
  bloquante** (doctrine v4.21.0 : transform/opacité seulement — compositeur —,
  ~200 ms, courbe de décélération type HIG) : à l'instant où la carte-question
  quitte l'écran (seuil corrigé en v4.21.2), sa bulle « se dépose » depuis le haut —
  continuité d'identité, la bulle vient d'où la carte est partie.
  - S'applique UNIQUEMENT à ce qui est nouveau d'un re-rendu : bulle absente du
    rendu précédent, ou chip « › option » seul quand l'option change dans une
    bulle conservée. La **sortie n'anime jamais** (esprit ECAM : l'attention
    revient à la carte réelle qui réapparaît, pas au chrome).
  - Inerte sous `prefers-reduced-motion` ; sans effet sur les hauteurs mémorisées
    de la pile (translation seule) ni sur les seuils d'entrée/sortie.

## [4.21.2] — 2026-07-20
### Corrigé
- **Fil d'ancêtres du plan (`#plPin`) : plus de bulle posée sur sa propre carte**
  (retour d'usage réel sur téléphone, suite du signalement v4.21.1). L'entrée d'une
  bulle dans la pile se mesurait sur le **haut du conteneur** de la décision : la
  bulle apparaissait pendant que la carte-question était encore à l'écran — et aux
  niveaux imbriqués (seuil plus bas d'une pile), par-dessus une carte **pleinement
  visible** qui dépassait autour de la bulle indentée (« doublon »). L'entrée se
  mesure désormais sur le **bas de la carte-question réelle** : la bulle n'apparaît
  que quand la carte qu'elle remplace a quitté l'écran. Hystérésis, cumul
  déterministe et sortie à la convergence inchangés.
  - Mesuré sur fiche à décisions imbriquées (393 px) : 4 positions de défilement en
    doublon avant (jusqu'à 58 px de carte visible sous sa bulle), 0 après ; la pile
    (1 puis 2 bulles selon la profondeur) se comporte à l'identique.

## [4.21.1] — 2026-07-20
### Corrigé
- **Plan de l'aide, mode « Détails » : une seule colonne sous 640 px** (retour d'usage
  réel sur téléphone — capture à l'appui) : les branches d'une décision s'affichaient
  côte à côte dès que deux pistes de 148 px tenaient, et une fois retirés rails,
  indentation et pastille numérotée, il ne restait que ~70–110 px de texte — les mots
  cliniques se cassaient lettre à lettre (« Conver / sion », « appare / illé »).
  Même décision que le mode statique en v4.13.1 : sous 640 px les branches
  s'empilent, la structure est portée par les rails de branche et les chips
  d'option ; à partir de 640 px, colonnes côte à côte inchangées.
  - La classe `deepv` (branche pleine largeur sous 640 px par volume d'étapes,
    v4.12.0) est absorbée par la règle une-colonne et supprimée (CSS + rendu) —
    elle ne couvrait pas les branches courtes au texte long, précisément celles
    de la capture.

## [4.21.0] — 2026-07-19
### Ajouté
- **Micro-animations de la bascule Dynamique ↔ Statique** (lecture d'une fiche à
  algorithme), **non bloquantes** : transform/opacité seulement (compositeur — la vue
  reste utilisable pendant les 300 ms), jouées après le re-rendu, jamais avant.
  - La **pastille glisse** désormais au lieu de se reposer : le composant étant
    re-rendu avec la fiche, le glissement est rejoué (`.seg-replay` : pastille posée
    sans transition sur l'ancien segment, reflow, retrait) — même geste visuel que la
    tab bar.
  - Le **contenu entre dans le sens du geste** (journal depuis la gauche, tableau
    statique depuis la droite — mêmes keyframes que la bascule de section de
    l'accueil). La bascule elle-même ne bouge pas d'un pixel sous le doigt.
  - Registres respectés : **minuteurs et chapeau « Ne pas oublier » n'animent
    jamais** (le mouvement y est réservé à l'alarme, ECAM) ; tout est inerte sous
    `prefers-reduced-motion` ; le fil d'ancêtres (`#plPin`, fixed dans un ancêtre
    transformé) est masqué le temps de l'animation.
### Corrigé
- **Mobile : le défilement ne « fuit » plus vers la page de fond quand une fenêtre
  est ouverte** (retour d'usage : en lisant une fenêtre longue — ex. Compte &
  synchronisation — l'accueil défilait derrière à son insu, et se retrouvait déplacé
  à la fermeture). Deux ceintures : l'enchaînement de défilement s'arrête au voile
  (`overscroll-behavior:contain` sur `.ai-modal`, même garde-fou que le menu des
  catégories) et, **au toucher seulement**, la page de fond est figée en place par
  l'accessibilité centralisée des modales tant qu'au moins une fenêtre est ouverte —
  position **restaurée au pixel** à la fermeture de la dernière (fenêtres empilées
  couvertes ; au pointeur fin, rien ne change : figer la page décalerait le fond
  visible derrière le voile).

## [4.20.3] — 2026-07-19
### Modifié
- **Prompt IA raccourci de ~15 % à information constante** (21,5 k → 18,3 k
  caractères) : réécriture télégraphique — justifications répétées et tournures
  longues resserrées — sans supprimer une seule règle, un seul seuil ni un seul
  exemple. Couverture vérifiée automatiquement (≈ 80 éléments-clés recherchés dans la
  nouvelle version) ; les formulations-invariants gardées par les tests (parcimonie du
  gras, une interdiction par ligne, gras exclu des étapes…) sont conservées à
  l'identique.

## [4.20.2] — 2026-07-19
### Modifié
- **Prompt IA — règle de cohérence des décisions** (piège rapporté sur une fiche
  générée) : les vues abrégées de l'app n'affichent que le **titre** du bloc et la
  **réponse** choisie — un titre « Stabilité hémodynamique » posé sur une question qui
  liste les signes d'*instabilité* fait lire « Oui » comme « stable », l'inverse du
  sens réel. Le prompt exige désormais que titre, question et options pointent dans le
  même sens, recommande des libellés qui portent la conclusion (« Instable » /
  « Stable ») plutôt que Oui/Non, et ajoute le point de contrôle final : chaque option
  relue **seule sous le titre** doit donner la bonne conclusion.

## [4.20.1] — 2026-07-19
### Modifié
- **Prompt IA de création mis à jour** (dialogue Créer → « Avec l'IA ») — il ignorait
  les évolutions d'affichage depuis v4.11 :
  - **Format « challenge :: réponse »** enseigné avec exemples concrets de réécriture
    (position des pads, test de fuite au ballonnet, réglages du respirateur, contrôle
    de dilution) : à utiliser dès qu'une étape attend un constat ou une valeur
    vérifiable — jamais sur une simple action ; combinable avec ⚠/△. L'app affiche la
    réponse en pilule, la fait confirmer en lecture à deux voix et la redemande en
    passe de vérification.
  - **Titres de blocs courts** (2-4 mots, discriminants dès les premiers mots) et
    **libellés d'options au premier mot distinctif** (« Choquable / Non choquable ») :
    les vues compactes (chips du fil, plan, tableau statique) tronquent.
  - Seuil de densité aligné sur le garde-fou de l'éditeur (**plus de 7 étapes par
    bloc** = signal), exemple « :: » ajouté au schéma JSON, point de contrôle final
    correspondant, et dédoublonnage des invites localInfo (énumérées trois fois).
  Vérifié dans l'app : le prompt s'affiche et se copie correctement.

## [4.20.0] — 2026-07-19
### Ajouté
- **Vérification hors-ligne des documents PDF** (besoin SMUR : en intervention, il n'y a
  parfois aucun réseau) : le pied de la barre latérale de l'accueil affiche désormais l'état
  des documents référencés par vos fiches et protocoles — **✓ « Documents PDF : tous sur cet
  appareil (n) »** quand tout est téléchargé (confirmation positive, consultable en zone
  blanche), ou **△ « k document(s) pas encore sur cet appareil »** avec un bouton
  **« Télécharger »** immédiat, sans attendre le téléchargement d'arrière-plan de la
  prochaine synchronisation. La ligne se met à jour en direct à l'arrivée des fichiers.
### Corrigé
- **Bandeau « Nouvelle version disponible » en collision avec le bandeau rouge du titre**
  (retour d'usage) : en lecture d'une aide, le bandeau de mise à jour glissait sous
  l'en-tête épinglé au défilement et se retrouvait à moitié masqué par le bandeau rouge.
  Il n'apparaît plus que **sur la page d'accueil** — recharger l'app depuis un écran de
  soin n'est de toute façon jamais souhaitable ; l'invitation attend le retour à l'accueil
  et la nouvelle version s'applique quoi qu'il arrive à l'ouverture suivante.

## [4.19.2] — 2026-07-19
### Corrigé
- **Visionneuse PDF sur écran étroit : le titre du document n'était plus lisible** (retour
  d'usage sur v4.19.0 : avec le bouton ⤓, la rangée unique écrasait le titre à quelques
  caractères). Sous 560 px, la barre d'outils passe sur **deux rangées** : titre + ✕ en
  haut, outils (zoom, Page, Largeur, ⤓) en pleine largeur dessous. Le pourcentage de zoom —
  masqué depuis v4.4.4 faute de place — retrouve au passage sa place sur téléphone.
  Au-dessus de 560 px, rien ne change.

## [4.19.1] — 2026-07-19
### Corrigé
- **PWA iPhone : « Télécharger » affichait le PDF par-dessus l'app, sans retour possible**
  (retour d'usage sur v4.19.0) : en application installée sur l'écran d'accueil, WebKit
  ignore l'attribut `download` et **navigue** vers l'adresse `blob:` du fichier — le PDF
  remplaçait l'app en plein écran, sans barre de navigation pour revenir (l'app semblait
  corrompue ; rien n'était perdu, la relancer suffisait). Désormais, **en app installée,
  tout téléchargement passe par la feuille de partage native** (Enregistrer dans Fichiers,
  AirDrop, Imprimer…) — corrigé au point unique `dlBlob`, donc aussi pour les exports
  `.json`/`.zip` et les comptes-rendus de session qui avaient le même défaut latent.
  Annuler la feuille de partage ne fait rien (aucune erreur) ; dans un navigateur classique,
  le téléchargement direct reste inchangé.

## [4.19.0] — 2026-07-19
### Ajouté
- **Télécharger un document PDF joint** : la visionneuse gagne un bouton **⤓ Télécharger**
  dans sa barre d'outils (fiches ET protocoles, y compris en mode crise — action passive,
  déclenchée seulement au toucher : elle ne déplace ni ne masque rien du contexte de soin).
  Le fichier téléchargé reprend le nom du document (extension `.pdf` garantie, jamais
  dupliquée) et est relu **directement depuis le stockage local de l'appareil** — aucun
  réseau nécessaire ; le bouton fonctionne même quand le rendu échoue (fichier endommagé :
  on peut le récupérer pour l'examiner ailleurs). Détail technique : le binaire est relu
  frais depuis IndexedDB — le buffer déjà confié à pdf.js est *transféré* à son worker et
  laissé détaché, un blob resservi de mémoire serait vide (constaté en test de bout en bout).

## [4.18.2] — 2026-07-19
### Corrigé
- **Mode Statique sur téléphone — le 3ᵉ niveau de blocs conditionnels n'était plus
  indenté** : ce n'était pas un plafond de lisibilité mais un bug — la passe
  d'**élargissement** des arbres imbriqués (pensée pour les colonnes ≥ 640 px) s'appliquait
  aussi en pile étroite, et sa marge négative compensatoire (jusqu'à −34 px) décalait la
  décision imbriquée vers la gauche, annulant l'indentation. L'élargissement est désormais
  **désactivé sous 640 px** (le palier même qui force la pile) : les niveaux profonds
  retrouvent leurs +17 px et leur rail par niveau (6 → 23 → 40 px mesurés à 375 px), sans
  débordement. Au-dessus de 640 px, rien ne change — vérifié **identique au pixel** à
  v4.18.1 (largeurs 700/1024/1280 px, fiches SVT à 4 niveaux). Le plafond volontaire du
  4ᵉ niveau (v4.15.0) reste en place.

## [4.18.1] — 2026-07-19
### Corrigé
- **Icônes floues (retour d'usage sur v4.16.3)** : l'agrandissement bitmap du glyphe
  produisait du flou et des pixels parasites au raccord. Les cinq icônes (tuiles 192/512,
  apple-touch, maskable 192/512) sont **redessinées en vectoriel** — même identité
  (tuile bleue arrondie, bouclier, tracé de pouls, couleurs d'origine), tracés nets à
  toutes les tailles, proportions harmonisées conservées (glyphe ~74 %, maskable ~60 %
  dans la zone sûre). Sur iPhone, réinstaller l'app sur l'écran d'accueil si l'ancienne
  icône reste en cache.

## [4.18.0] — 2026-07-19
### Modifié
- **Le schéma SVG rejoint le Plan de l'aide** (décision utilisateur sur maquette — ordre
  ECAM : l'écran d'actions au-dessus, les synoptiques en dessous, jamais l'inverse) : en
  mode dynamique, le panneau « Algorithme ▾ » qui précédait le journal disparaît — le bloc
  courant remonte d'autant — et le Plan gagne un **troisième affichage** : « **Détails /
  Échelle / Schéma** ». « Schéma » est le SVG spatial complet, avec zoom, plein écran et
  navigation par nœud conservés, et l'état de session peint en direct (✓, position, hors
  chemin) comme dans les deux autres affichages. Une seule section « structure », sous
  l'action, trois densités de la même donnée.
- Le panneau « Algorithme » ne subsiste que pour les fiches **sans** algorithme (rendu
  bloc-à-bloc, pas de Plan). L'impression force toujours le plan Détails (le SVG ne
  s'imprime plus en mode dynamique). Le fil d'ancêtres flottant ne s'épingle qu'en
  affichage Détails. Vérifié à 375 et 1280 px (sélecteur à la ligne en étroit, zéro
  débordement).

## [4.17.0] — 2026-07-19
### Supprimé
- **Minimaps (v4.8.0) retirées** (décision utilisateur — devenues redondantes) : la bande
  de chips-blocs de l'en-tête de crise (< 1000 px) et le panneau « Algorithme — position »
  du rail droit (≥ 1000 px) faisaient double emploi depuis que le **fil condensé** (chips
  titrées, lignes-bilan, v4.16) et le **Plan de l'aide** (v4.10) portent la même
  numérotation, les mêmes états et le même geste de navigation. L'en-tête de crise regagne
  une rangée entière sur téléphone ; le rail droit se recentre sur les minuteurs et la
  posologie. `minimapData` (la source de l'état par bloc) reste — elle nourrit le plan, le
  mode statique et le SVG. CSS et délégations retirés avec le composant.

## [4.16.4] — 2026-07-19
### Modifié
- **Fil condensé — ligne-bilan façon ECL** (retour d'usage : sur téléphone, une rangée de
  15 chips titrées occupait tout l'écran) : une rangée de **plus de 4 chips** se replie en
  une seule ligne de statut verte « **✓ 17 passages · 1→5 ▸** » — le modèle des ECL
  Boeing, où une checklist terminée se referme en une ligne, le détail restant à la
  demande. Un tap déplie la rangée de chips sur place (les titres complets sont aussi en
  info-bulle) ; comme pour les chips, le dépliage est une consultation transitoire — le
  prochain geste de navigation referme la ligne. L'impression déplie toujours tout.

## [4.16.3] — 2026-07-19
### Corrigé
- **Journal — fin des « scrolls incessants » en avançant** (retour d'usage) : le re-rendu
  d'un geste d'avancement (Continuer, réponse, ↺ Refaire) **ancre la vue sur la carte d'où
  part le geste** (compensation du rétrécissement dû à la condensation en chips), puis ne
  défile vers la nouvelle carte **que si elle n'est pas déjà entièrement visible**. Mesuré :
  dérive visuelle 0 px sous le doigt — les chips restent en place.
- **Mise à jour non proposée sur iPhone/Mac (PWA installée)** : une app installée peut
  rester des jours sans « navigation », or c'est elle qui déclenche la vérification de
  `sw.js` — la nouvelle version n'était donc jamais détectée. La vérification est désormais
  forcée **à chaque retour au premier plan** (+ filet horaire). Ce correctif prendra effet
  après une dernière mise à jour manuelle (Recharger).
### Ajouté
- **Carte-bilan de fin de session** (décision utilisateur — le débriefing est disponible,
  jamais imposé) : après « Terminer », l'accueil affiche une carte éphémère au registre
  confirmation — titre · durée · blocs réalisés ✓ — avec un bouton **Compte-rendu** (ouvre
  le compte-rendu complet : chronologie, étapes, minuteurs). Elle disparaît d'un tap (✕)
  ou au démarrage de la session suivante ; jamais persistée (la vérité reste la session
  archivée, dans l'historique).
### Modifié
- **Icônes harmonisées et agrandies** : le glyphe (bouclier) passe de ~62 % à ~74 % du
  cadre sur l'icône iPhone (apple-touch) et les tuiles favicon/PWA 192 et 512 (coins
  arrondis préservés), et de ~49 % à ~60 % sur les icônes maskable (zone sûre respectée) —
  l'icône paraît désormais de taille comparable sur iPhone, Mac et Android.

## [4.16.2] — 2026-07-19
### Modifié
- **Chips du fil condensé — titre abrégé** (décision utilisateur : « le numéro seul ne
  parle pas à un humain ») : une chip de bloc d'étapes affiche désormais **n° + titre
  tronqué (~13 caractères) + ✓** (« 13 Non choquable… ✓ ») au lieu du numéro seul ; les
  chips de décision gardent leur réponse en toutes lettres (« 5 › Choquable (FV/… »), qui
  est la trace. Titre complet toujours en info-bulle ; vérifié à 375 px (1-2 chips par
  rangée, aucun débordement) et en thème sombre.

## [4.16.1] — 2026-07-19
### Corrigé
- **Fil condensé — une carte dépliée puis actée ne restait jamais recondensée** (retour
  d'usage : visible surtout sur les décisions déjà répondues) : taper une chip posait une
  surcharge « déplié » **permanente** — la condensation automatique n'avait plus jamais la
  main sur cette carte. Le dépliage manuel (chip tapée, ligne rouverte) est désormais une
  **consultation transitoire** : tout geste de navigation (Continuer, réponse à une décision,
  ↺ Refaire, entrée d'un bloc par le plan/SVG) rend la main à la condensation automatique
  (`ovDropOpens`). Le **repli** manuel, lui, persiste toujours. Rien ne bouge sous le doigt :
  l'effacement n'a lieu qu'au rendu du geste de navigation, jamais pendant le cochage —
  une carte dépliée reste donc ouverte tant qu'on lit ou qu'on coche.
- Rappel des règles inchangées : un passage **incomplet** n'est jamais condensé en chip
  (invariant — un bloc abandonné en cours reste visible ; son repli manuel s'arrête à la
  ligne d'état), et les 2 passages complets les plus récents restent en ligne d'état.

## [4.16.0] — 2026-07-19
### Modifié
- **Fusion des modes Journal et Guidé — le journal devient un FIL CONDENSÉ** : le mode
  « Guidé » (bloc à bloc) disparaît pour les fiches à algorithme — le journal reprend son
  rôle en condensant automatiquement l'historique. Trois présentations par passage
  (`ovPresList`, pure) : le **bout** est toujours une carte dépliée (la surface d'action) ;
  les 2 passages complets les plus récents restent en **ligne d'état** verte relisible ;
  les plus anciens deviennent des **chips** regroupées en rangées chronologiques — n° + ✓
  vert pour un bloc d'étapes, « › réponse » en toutes lettres (tronquée) pour une décision,
  « ×n » pour les passages multiples. **Invariant de conformité (ECAM/QRH/AC 120-71B,
  validé)** : un passage incomplet n'est JAMAIS condensé en chip — le travail non fait
  reste sous les yeux ; le repli manuel d'un incomplet s'arrête à la ligne d'état.
- **Taper une chip = déplier la carte sur place** (surcharge manuelle, prioritaire sur la
  condensation automatique jusqu'au choix inverse via le chevron) ; la condensation ne
  s'applique qu'au rendu d'un geste de navigation, jamais sous le doigt pendant le cochage.
- **Bascule simplifiée** : un seul sélecteur « Dynamique ↔ Statique » en tête de fiche
  (le sous-sélecteur « Journal ↔ Guidé » et la clé locale `ac-read-dyn` sont supprimés) ;
  une préférence « Guidé » enregistrée est lue comme « Dynamique ». Les fiches SANS
  algorithme gardent le rendu bloc-à-bloc historique (les deux vues y étaient identiques).
- L'impression déplie l'intégralité du fil (aucune chip sur le papier). Session, cochage,
  export v3, mode Vérification, mode Lecteur, plan et mode Statique inchangés.
### Corrigé
- 5 tests ajoutés (`ovPresList` : bout toujours déplié, incomplet jamais chip, 2 récents
  en ligne, surcharges manuelles) — 461 au total.

## [4.15.0] — 2026-07-19
### Ajouté
- **Mode Statique — indentation des branches sur écran étroit** : sous 640 px (une seule
  colonne), les blocs enfants d'une décision sont désormais **indentés** (~17 px par
  niveau) et portent un **rail de branche** de 3 px — bleu = chemin pris, pointillé = hors
  chemin, la même grammaire que le plan. L'imbrication redevient visible en pile (les
  fourches y sont masquées : rail + étiquette d'option portent la structure), le tronc
  reprend à gauche à chaque convergence. Plafonné au 4ᵉ niveau ; au plus profond il reste
  ~289 px de largeur de lecture sur un écran de 375 px. CSS pur, récursif.

## [4.14.12] — 2026-07-19
### Corrigé
- **Mode Statique — arrivée horizontale des retours ↺** : la voie bleue de la gouttière
  remonte puis **entre horizontalement dans le bord gauche du bloc cible** (pointe vers la
  droite), au lieu d'une pointe verticale posée sur son sommet — symétrique des départs.
  Gouttière inchangée (16 px) : aucune largeur de contenu sacrifiée.

## [4.14.11] — 2026-07-19
### Corrigé
- **Mode Statique — départ du brin gris lisible** : le brin sort désormais du bloc par un
  **tronçon vertical de 10 px** avant tout coude (le départ collé au bloc n'était pas
  lisible), et le **détour par la voie de bord ne se fait que si le couloir central est
  réellement obstrué** — descente droite sinon (fin des détours inutiles). Vérifié :
  anaphylaxie (1 coude légitime, 1 droit), ACR (2 droits, 1 coude légitime).
- **Mode Statique — le contexte local (téléphones utiles) ne colle plus au tableau**
  (marge de 18 px).

## [4.14.10] — 2026-07-19
### Amélioré
- **Mode Statique — peinture des flèches ~3,5× plus rapide** : la passe de mesure/dessin
  alternait lectures et écritures de géométrie, forçant le navigateur à recalculer la mise
  en page des dizaines de fois (30-50 ms par passe sur ordinateur, bien plus sur
  téléphone). Elle est réorganisée en phases groupées — un instantané de géométrie par
  phase, écritures en bloc — soit ~4 recalculs fixes (~12 ms sur la fiche la plus
  ramifiée). Le recalcul automatique ignore en outre les notifications sans changement de
  taille. Comportement strictement identique : mêmes élargissements, mêmes flèches, zéro
  collision sur les 8 fiches, fourches centrées au pixel.

## [4.14.9] — 2026-07-19
### Corrigé
- **Mode Statique — le brin gris part du bon bloc** : il démarrait sous la rangée invisible
  de la pilule remplacée (~40 px trop bas, comme venant d'un bloc d'en dessous). Il part
  désormais directement sous le **dernier bloc visible** de sa branche et traverse la zone
  réservée. Vérifié au pixel sur l'anaphylaxie (bloc 11) et l'ACR (chip « Non »), zéro
  collision.

## [4.14.8] — 2026-07-19
### Corrigé
- **Mode Statique — départs de flèches recentrés** : depuis l'élargissement, la tige des
  fourches (ambre) partait du centre du bandeau élargi et non de la bande-question, et les
  brins gris se référaient au centre de colonnes décalées. Chaque tracé est désormais ancré
  sur l'élément réel : tige de fourche au **centre de la bande-question**, départ du brin
  gris au **centre du dernier bloc de sa branche**, flèche d'arrivée au **centre de la
  cellule de convergence**. Vérifié sur les 8 fiches : écart maximal de 1 px, zéro
  collision.

## [4.14.7] — 2026-07-19
### Modifié
- **Mode Statique — hybride flèche + élargissement** : plus besoin de choisir. Chaque
  flèche de convergence descend désormais par une **voie de bord** (le long du bord droit
  de sa colonne, rejointe par un petit coude sous la pilule), et l'élargissement **s'écrête
  au plus proche obstacle** au lieu d'y renoncer : les blocs s'étendent jusqu'à ~24 px de
  la voie, la flèche passe à côté. Sur l'anaphylaxie : blocs élargis **et** flèche 11 → 12,
  zéro superposition.

### Corrigé
- **Régression contenue avant publication** : l'élément élargi héritait de toute la piste
  de sa grille de branche, ce qui étirait aussi ses cellules sœurs sur les colonnes
  voisines (vu sur l'ACR) — compensé par des marges négatives : la piste garde sa largeur
  d'origine. Audit final : zéro collision sur les 8 fiches (ACR, anaphylaxie, les 6
  tachycardies), élargissements et flèches coexistant partout.

## [4.14.6] — 2026-07-19
### Corrigé
- **Mode Statique — la flèche descendante prime sur l'élargissement** : la 4.14.5 évitait
  la superposition en gardant la pilule « → 12 » au lieu de la flèche — mais la flèche de
  convergence (ex. bloc 11 « symptômes gastro-intestinaux » → 12) doit être conservée.
  Désormais les **couloirs des flèches sont réservés avant** le calcul d'élargissement :
  chaque branche qui convergera en flèche réserve sa colonne de descente (de la pilule au
  coude), et l'élargissement y renonce. Résultat sur l'anaphylaxie : flèche 11 → 12
  dessinée, zéro superposition ; les fiches tachycardies conservent leurs élargissements
  (leurs branches courtes se terminent sans flèche de convergence).

## [4.14.5] — 2026-07-19
### Corrigé
- **Mode Statique — la flèche de convergence ne traverse plus les blocs élargis**
  (ex. anaphylaxie : la flèche du bloc 11 « symptômes gastro-intestinaux » vers le bloc 12
  passait sur les blocs élargis de la branche voisine). Cause : la pilule « → 12 »
  remplacée par le brin libérait sa place, l'élargissement s'y étendait, puis le brin
  redessiné traversait les cellules. Désormais : un brin n'est dessiné que si son **couloir
  vertical est libre** — sinon la branche **garde sa pilule** (l'information reste locale au
  bloc) ; et une pilule remplacée reste invisible **sans libérer son espace** (plus
  d'oscillations de recalcul). Vérifié sur les 6 fiches tachycardies + ACR + anaphylaxie :
  zéro superposition, élargissements et brins légitimes conservés.

## [4.14.4] — 2026-07-19
Corrections issues des essais sur les fiches tachycardies/SVT (6 algorithmes très
ramifiés, imbrications à 4 niveaux).

### Corrigé
- **Mode Statique — l'élargissement fonctionne dans les deux sens** : sur ces fiches, la
  branche courte (« instable → choc ») est à **gauche** et la longue à droite — l'extension
  ne s'appliquait jamais (elle ne regardait qu'à droite) et l'algorithme restait coincé
  dans une demi-colonne avec tout le côté gauche vide. Le critère devient un **test de
  collision global** (l'espace convoité ne doit contenir aucun contenu extérieur, à toute
  profondeur d'imbrication) et l'extension se fait à gauche comme à droite. Vérifié sur les
  6 fiches : « Régularité du rythme » s'étend à pleine largeur, zéro collision, zéro
  débordement, y compris sur l'orage rythmique à 4 niveaux.
- **Fil d'ancêtres — hauteur stable** : l'apparition du « › Oui / › Non » dans une bulle ne
  décale plus le texte vers le haut/bas (hauteur de ligne réservée).
- **Vue guidée — plus de saut au « Continuer »** : valider une étape faisait défiler la vue
  (~200 px d'alignement systématique + ~70 px de dérive du navigateur) même quand tout
  était visible. Le remplacement du bloc est désormais **ancré** (le nouveau bloc apparaît
  exactement là où était l'ancien) et le rattrapage ne se produit plus que si le fil
  d'Ariane ou le bloc ne sont pas entièrement à l'écran. Mesuré sur 4 validations
  successives : mouvement visuel nul.

## [4.14.3] — 2026-07-19
### Corrigé
- **Fil d'ancêtres — plus de battements** : en fin de branche, les bulles pouvaient
  apparaître et disparaître en rafale (la hauteur de la pile modifiait la ligne qui
  décidait du contenu de la pile — boucle de rétroaction). L'entrée/sortie est désormais un
  **cumul déterministe** (le seuil de chaque bulle est le bas de la pile au-dessus d'elle,
  hauteurs réelles mémorisées) avec **hystérésis** (~16 px entre seuils d'entrée et de
  sortie) : les transitions sont uniques et monotones, le décrochage est propre.

### Modifié
- **Mode Statique — les arbres imbriqués s'étendent** : quand toutes les branches sœurs à
  droite d'une décision imbriquée sont terminées au-dessus d'elle (colonne devenue vide),
  la décision **s'élargit** dans l'espace libéré — ses sous-branches gagnent en largeur,
  comme sur un algorithme papier ; si la bande-question fait encore face à une sœur, seules
  la fourche et les colonnes s'élargissent (jamais de collision). Recalculé au rendu et au
  redimensionnement, flèches repeintes sur la géométrie finale.
- **Mode Statique — bouton « démarrer la session » intégré au carrelage** : coins de 3 px,
  pleine largeur de rangée, espacement du joint de la grille — il s'aligne avec les
  cellules tout en restant l'unique bouton rempli de la page (≥ 44 px).

## [4.14.2] — 2026-07-19
### Corrigé
- **Fil d'ancêtres — rangée partagée** : quand deux branches sont côte à côte et que l'une
  est plus longue, la bulle réaffichait son option dès que la ligne de lecture dépassait le
  bas de la plus courte — trompeur, la rangée parallèle étant encore à l'écran. L'option ne
  s'affiche désormais que si la branche est **seule sur sa rangée** (aucun chevauchement
  vertical avec une sœur).
- **Fil d'ancêtres — entrée dans la pile** : une bande de décision pouvait disparaître
  **derrière** la pile de bulles avant d'y être représentée (la détection se faisait à
  hauteur fixe, sous une pile devenue plus haute) — on perdait la question et ses options.
  La ligne de lecture vit maintenant au **bas réel de la pile** : tout ce que la pile
  recouvre y est représenté, une bande y entre à l'instant où elle glisse dessous.

### Modifié
- **Mode Statique — bouton « Confirmé — démarrer la session »** déplacé dans le tableau,
  **sous « Confirmer le diagnostic » et « Éliminer »** et avant « ⚠ Ne pas oublier »
  (condition d'entrée : on confirme le tableau avant d'agir). Consulter reste inerte ;
  démarrer est l'unique action de la page.

## [4.14.1] — 2026-07-19
### Corrigé
- **Fil d'ancêtres du plan** : quand les branches d'une décision sont affichées **côte à
  côte**, la ligne de lecture traverse plusieurs branches à la fois — la bulle épinglée
  affichait pourtant « › Oui » ou « › Non » arbitrairement, ce qui induisait en erreur.
  Désormais l'option ne s'affiche que si la ligne de lecture ne traverse **qu'une seule**
  branche (pile ou branche pleine largeur) ; sur une rangée de branches parallèles, la
  bulle ne montre que la question.

## [4.14.0] — 2026-07-19
Trois évolutions demandées à l'usage : le fil d'ancêtres du plan retrouve ses niveaux, le
mode Statique devient un document complet choisi dès l'entrée de la fiche, et les branches
profondes s'affichent en colonnes.

### Modifié
- **Plan de l'aide — fil d'ancêtres à plusieurs niveaux (sans superposition)** : en
  défilant dans les branches, une **pile de bulles flottantes** montre chaque décision
  ancêtre, **indentée selon sa position dans l'arbre** comme avant — mais les bulles
  s'empilent désormais selon leurs hauteurs réelles (le chevauchement est impossible), et
  chaque bulle porte son « › Oui / › Non » **dans la même bulle** : deux niveaux avec des
  options homonymes ne peuvent plus se confondre. Un tap sur une bulle va à sa décision.
- **Mode Statique = document complet** : le tableau inclut désormais « Confirmer le
  diagnostic » et « Éliminer — tableau atypique ? » côte à côte, le chapeau « ⚠ Ne pas
  oublier », et « △ À vérifier — surveillances » en pied — comme la maquette validée ; le
  bouton « démarrer la session » reste au-dessus. Le choix se fait dès l'entrée de la
  fiche : **« Dynamique ↔ Statique »** en tête, et en Dynamique la bascule
  **« Journal ↔ Guidé »** reste à sa place dans la prise en charge. Revenir en Dynamique
  restaure le dernier sous-mode utilisé.
- **Branches profondes en colonnes** : dans le tableau statique (dès 640 px), une branche
  contenant plusieurs blocs ou une décision imbriquée reste **côte à côte** avec ses sœurs
  — l'arbre dans l'arbre garde ses fourches gauche/droite au premier niveau (une colonne
  courte à côté d'une longue, esprit SFAR papier) ; une décision imbriquée dans une colonne
  étroite s'empile d'elle-même. Sur téléphone, tout reste en pile pleine largeur.

## [4.13.3] — 2026-07-19
### Corrigé
- **Plan de l'aide (vue journal) — le fil d'ancêtres retrouve la bonne bulle** : la
  simplification 4.13.2 épinglait la question de premier niveau — donc la mauvaise dès
  qu'on lisait une branche imbriquée, et sans le Oui/Non. Désormais **une bulle flottante
  unique** suit le défilement : toujours la question la plus **proche** de ce qu'on lit,
  avec « › Oui / › Non » de la branche où l'on se trouve. Elle se remplace en traversant
  les décisions (jamais d'empilement), disparaît aux convergences, et un tap y va
  directement. Alignée quelle que soit la taille du texte ; absente du mode Échelle et de
  l'impression.

## [4.13.2] — 2026-07-19
### Corrigé
- **Plan de l'aide — fil collant simplifié** : la pile de questions et d'options épinglées
  en haut de l'écran (v4.12) se superposait — les décalages étaient figés à 48 px alors
  qu'une question sur deux lignes est plus haute — et, même correcte, une pile de 3-4
  boîtes gênait la lecture sur téléphone. Désormais **une seule épingle** : la question de
  premier niveau reste visible pendant qu'on défile dans ses branches et se décroche à la
  convergence ; le contexte de branche reste porté par les rails et les étiquettes
  d'option, qui défilent normalement.
- **Textes qui débordaient de leur cadre** : dans les bulles « À vérifier —
  surveillances », les diagnostics différentiels, les options d'une décision, les rappels
  « Ne pas oublier » et les questions, un mot long pouvait sortir du cadre ou pousser la
  case/le chevron hors de la carte (journal ET vue guidée). Les textes peuvent maintenant
  rétrécir et se couper proprement (césure française), comme les étapes en v4.13.1.

## [4.13.1] — 2026-07-19
Audit design complet après retours d'usage sur v4.13.0 : taille du texte, petits écrans,
flèches du mode statique et en-têtes du journal.

### Corrigé
- **Réglage « Taille du texte » (cause racine de deux bugs)** : ce réglage est un zoom CSS,
  et les positions mesurées à l'écran sont en pixels « visuels » (× zoom) alors que les
  styles écrits sont en pixels CSS. Dès que la taille n'était pas à 100 %, le fil d'ancêtres
  collant du plan dérivait (pastilles flottant sous l'en-tête ou glissant dessous) et les
  flèches du mode statique se désalignaient. Toutes les mesures sont désormais ramenées en
  pixels CSS (`zoomF()`), et la base du fil collant est recalée à chaque variation de
  hauteur de l'en-tête (repli au défilement, bandeau de crise, changement de taille).
- **Mode statique sur petit écran** : sous 640 px, les branches ne s'affichent plus côte à
  côte (colonnes de ~145 px illisibles — retour d'usage) : tout s'empile en pleine largeur,
  les pilules « → n » / « ↺ n » portent la structure. La pilule de réponse « :: » peut se
  replier sur plusieurs lignes (elle débordait du cadre en nowrap), comme les titres et
  étapes des cellules.
- **Flèches de convergence** : les brins partent maintenant du bas réel de chaque branche
  (chip comprise pour une branche vide) et traversent l'espace libre jusqu'au coude — plus
  de segments flottants sous une colonne courte. Redessin automatique à tout changement de
  géométrie du tableau (taille du texte, rotation, resize).
- **Journal — en-tête d'instance** : sur petit écran, les boutons « Lecteur » et
  « Vérifier » passent sous le titre (deux rangées) au lieu de l'écraser ; le chip « Vous
  êtes ici » ne recouvre plus la ligne du dessus ; la réponse d'une décision repliée peut
  se replier sur plusieurs lignes.
- **Étapes de la checklist** : un mot long (« compressions ») ne pousse plus la case à
  cocher hors du cadre en étroit / grande taille de texte (césure française automatique).

## [4.13.0] — 2026-07-19
Un **troisième mode de lecture « Statique »** rejoint le Journal et la vue guidée : tout
l'algorithme d'un coup d'œil, en tableau compact façon aide cognitive SFAR/CAMR — généré
automatiquement depuis les blocs de la fiche, consultable sur téléphone, tablette et
ordinateur. Direction visuelle et arbitrages (tableau à joints fins, petites flèches sur les
décisions, aucun texte bleu dans les cellules) validés en séances de maquettes.

### Ajouté
- **Mode Statique** : bascule à trois segments « Journal · Guidé · Statique » en tête de la
  prise en charge (préférence mémorisée et synchronisée, comme avant). Le tableau carrelle
  des cellules télégraphiques — titre en petites capitales, étapes ❑, valeurs « :: » en
  pilule mono **neutre** (le bleu ne marque plus que la position « ● ici » et les reprises
  ↺) ; les décisions sont des bandes ambre pleine largeur (titre + question) dont les
  branches s'affichent côte à côte quand l'écran le permet et s'empilent sinon (mêmes règles
  de profondeur que le plan v4.12).
- **Petites flèches dessinées** : fourche ambre de chaque décision vers ses options,
  convergence grise qui fusionne les branches retombant sur le tronc, retours ↺ en trait
  bleu dans la gouttière gauche (2 voies maximum). Dessinées sur les positions réelles après
  le rendu et au redimensionnement ; quand les branches s'empilent, elles s'effacent et les
  pilules « → n » / « ↺ n » — toujours présentes — reprennent seules le relais : la flèche
  n'est jamais la seule information (accessibilité, impression).
- **Navigation seule, aucune case** : le tableau est inerte côté cochage (la trace vit dans
  le journal) mais montre l'état de session en lecture seule — ✓ du dernier passage, bloc
  courant cerclé de bleu, réponse prise « ✓ » sur son option, hors chemin estompé avec la
  mention en toutes lettres. Taper une cellule = y aller (un bloc jamais visité entre au
  bout du journal, sans défilement ni démarrage de session) ; taper un renvoi = défiler
  vers sa cible dans le tableau. Clavier : Entrée/Espace sur toute cellule.
- Minuteurs, chrono, alarmes et sessions inchangés : mêmes emplacements dans les trois
  modes, mêmes règles d'alarme (rien ne bouge sous les yeux) ; en Statique, le panneau
  « Algorithme » et la minimap disparaissent — le tableau est la vue d'ensemble.

### Détails techniques
- `svTableHtml` (walker de `flowPlan`), `svPaintArrows` (mesures réelles + resize rAF),
  `svBranchIssue`/`svLoopTargets` (pures, testées), `svJump`, `renderSvOnly` ;
  `READ_MODES` accepte `static` ; préfixe CSS `sv-` (collision `st-` évitée) ; aucun
  changement de modèle, de session ni d'export ; 456 tests ; vérifié de bout en bout sur
  les deux fiches réelles (375/810/1280 px, thème sombre, synchro journal ↔ tableau).

## [4.12.0] — 2026-07-18
Le « Plan de l'aide » devient un **organigramme hybride** : la forme de l'arbre se voit
enfin (branches côte à côte quand l'écran le permet), chaque branche est lisible et
repliable, et un mode compact « Échelle » montre tout l'algorithme en une ligne par bloc,
façon ECAM. Décisions figées en séances de maquettes sur fiches réelles (ACR adulte,
anaphylaxie enfant) : le plan reste **inerte** (pas de cases — le cochage vit dans le
parcours) ; la structure `flowPlan` (post-dominateurs, numérotation commune) est inchangée.

### Ajouté
- **Branches côte à côte (organigramme hybride)** : les branches d'une décision s'affichent
  en colonnes quand au moins deux colonnes de 148 px tiennent, et s'empilent sinon — règle
  CSS pure, locale et récursive (une décision imbriquée dans une colonne étroite retombe
  d'elle-même en pile). Une branche **profonde** (plus de 2 blocs ou décision imbriquée)
  s'étale toujours sur toute la largeur ; une branche **volumineuse** (plus de 3 étapes)
  ne s'étale que sur téléphone, où une colonne de 150 px émietterait son texte. Le nombre
  de pistes est plafonné au nombre réel de branches en colonne (sans quoi une branche
  pleine largeur coinçait ses sœurs dans des colonnes étroites même sur grand écran).
- **Rails de branche étiquetés** : chaque branche porte un rail continu de 3 px né sous son
  option et raccordé à un coude de convergence (`→ n` / `↺ n`) — bleu = chemin pris,
  pointillé estompé + mention « hors chemin » = branche écartée (la couleur n'est jamais
  seule).
- **Repli par branche** : le chip d'option est un bouton (≥ 44 px) ; replié, la branche
  devient une ligne-bilan « n blocs · k ✓ · → n ». Les branches hors chemin se replient
  d'elles-mêmes après une réponse ; un tap les rouvre — jamais verrouillées, jamais
  bloquantes.
- **Fil d'ancêtres collant** : en défilant dans une longue branche, la question et l'option
  en cours restent épinglées sous l'en-tête (pile façon éditeur de code, 4 niveaux max) et
  se décrochent d'elles-mêmes à la convergence — on sait toujours « dans quelle branche
  on est », même au fond d'un ACR sur téléphone.
- **Échelle ECAM (mode compact, remplace « Titres seuls »)** : une ligne par bloc — retrait
  de profondeur avec chip d'étiquette (`OUI ›`), n°, titre, renvois abrégés en mono
  (`OUI→5`, `↺1`, `▪fin`) — l'algorithme entier tient sur un écran de téléphone (14 lignes
  pour l'ACR). Taper une ligne la déplie sur place (étapes en lecture seule + « → aller à
  ce bloc ») ; taper un renvoi défile vers la ligne cible et la fait clignoter. Bascule
  « Échelle » ↔ « Détails » ; l'impression sort toujours le plan détaillé.

### Détails techniques
- `ovPlanTreeHtml` (walker imbriqué), `ovPlanLadderHtml` (marche plate), `optAbbr` (pure,
  abréviation des étiquettes de renvoi avec désambiguïsation, testée) ; état de repli dans
  `state.ovFold` (`'b:…'` branches, `'l:…'` lignes de l'échelle), `state.ovPlanTitles` →
  `state.ovPlanCompact` ; `--pl-stick` mesuré sur l'en-tête réel (`ovPlanStick`). Aucun
  changement de modèle, de session ni d'export ; 448 tests.

## [4.11.1] — 2026-07-17
### Corrigé
- **Menu ⋯ déformé** : les entrées du menu s'affichaient comme des cartes à bord gauche marqué
  — la minimap du rail (v4.8.0) avait réutilisé par accident le nom de classe des items du
  menu (`.mm-row`). Les classes de la minimap sont renommées (`.ovm-*`), le menu retrouve son
  apparence.

### Modifié
- **Fiches d'exemple mises à niveau** : les deux exemples (Anaphylaxie, Arrêt cardiaque)
  illustrent désormais les registres ⚠/△ et le format « challenge :: réponse » (« ⚠ Choc
  immédiat :: puis reprise RCP 2 min », « Adrénaline :: 1 mg après le 3ᵉ choc… ») — les
  valeurs restent des placeholders à relire et adapter avant tout usage clinique.

## [4.11.0] — 2026-07-17
Le mode crise devient un vrai support **challenge-response** au sens des checklists
aviation (FAA AC 120-71B, philosophie Do-Verify) : la réponse attendue est séparée du
challenge, une passe de vérification redéroule un bloc, et un mode lecteur plein écran
outille le travail en binôme.

### Ajouté
- **Réponse attendue « challenge :: réponse »** : dans une étape, tapez `::` entre l'action et
  sa valeur (`Adrénaline IM :: 0,01 mg/kg — max 0,5 mg`). En lecture, la réponse devient une
  pilule distincte ; **cocher = confirmer la réponse constatée** (elle passe en readback vert
  « ✓ … »), pas un simple « fait ». Visible aussi dans le plan et le schéma ; une étape sans
  `::` est inchangée, un ancien client affiche le texte tel quel. Rien ne change au format.
- **Mode Vérification (Do-Verify)** : sur tout bloc du parcours, « Vérifier » redéroule les
  challenges **un à un** — « Constaté ✓ » coche l'étape, « △ Écart » passe **sans cocher**
  (jamais de coche inventée, jamais de coche effacée) ; résumé final avec les écarts, qui
  restent visibles dans le parcours. Quitter à tout moment : l'état est celui des cases.
- **Mode lecteur (binôme)** : plein écran, un challenge à la fois en très grand, réponse
  attendue en dessous, zone de validation géante (mains gantées) — le lecteur désigné lit à
  voix haute, l'exécutant répond, le lecteur valide. Fin de bloc et décisions suivent les
  mêmes règles que la checklist (pas d'avance tant que tout n'est pas confirmé, « Revoir »
  ramène au premier écart) ; le chrono de session reste affiché, le flash d'alarme des
  minuteurs reste visible par-dessus ; Échap/✕ quitte sans rien perdre. Entrées : bouton
  « Lecteur » sur le bloc en cours et menu ⋯.
- **Garde-fou télégraphique** dans l'éditeur (non bloquant) : signale un bloc de plus de
  7 étapes ou un challenge de plus de 110 caractères, avec la marche à suivre (« une action
  courte, la valeur en réponse :: »). 8 tests ajoutés (444).

## [4.10.0] — 2026-07-16
La **structure globale** de l'aide devient enfin visible : sous le parcours, le nouveau
**Plan de l'aide** affiche tout l'algorithme en arbre indenté, comme sur un algorithme papier —
retour d'usage sur les fiches à décisions enchaînées (anaphylaxie enfant, ACR), où la liste
plate « Suite de l'algorithme » ne montrait pas qui mène où.

### Ajouté
- **Plan de l'aide** (remplace la « Suite de l'algorithme ») : l'algorithme complet en arbre —
  les branches d'une décision s'indentent sous leur option (« Oui », « Non — digestifs
  isolés »), le tronc reprend au **point de convergence** (calculé automatiquement : sur une
  anaphylaxie, toutes les branches retombent sur « Suivi post-critique », qui s'affiche donc
  au niveau racine), et une boucle est une flèche explicite « ↺ reprendre à n » — la boucle
  des cycles de 2 minutes d'un ACR devient une structure lisible. Chaque bloc n'apparaît
  qu'une fois ; étapes visibles par défaut, bascule « Titres seuls » pour la structure pure.
- Le plan est **immuable et sans cases à cocher** (la trace vit dans le parcours) ; il porte
  un état léger — ✓ bloc fait, ● position, ×n passages, branche écartée « hors chemin »
  estompée — et sert à naviguer : taper un bloc = y aller (un bloc jamais visité entre au
  bout du parcours) ; les liens → / ↺ défilent dans le plan.
- La **numérotation des blocs est désormais commune** au plan, au parcours, aux pastilles
  mobiles et à la minimap du rail : l'ordre de lecture du plan.

### Modifié
- L'impression inclut le plan complet avec ses étapes (structure + contenu sur papier).
- 6 tests ajoutés (436) sur `flowPlan` (convergence, boucles, orphelins, unicité).

## [4.9.0] — 2026-07-16
La vue d'ensemble devient un **journal de parcours** : sur les algorithmes à boucles et à
décisions, l'ancienne présentation (chaque bloc affiché une fois, remis à neuf à chaque passage)
perdait l'utilisateur — retour d'usage immédiat. Le journal suit le modèle ECAM : les étapes
faites restent à l'écran, ce qui vient se poste à la suite.

### Modifié
- **La « Vue d'ensemble » est désormais chronologique** : chaque passage d'un bloc est une carte
  postée à la suite — on lit toujours vers le bas, rien ne se réécrit au-dessus, rien ne
  disparaît. Un bloc terminé se replie en **ligne d'état verte** relisible d'un tap (le repli
  n'arrive jamais sous le doigt : il attend le geste suivant) ; un bloc quitté incomplet reste
  déplié. Une décision repliée garde **sa réponse en toutes lettres** (« → Non — réfractaire »),
  passage par passage — plus de décision amnésique. Reboucler = une nouvelle carte en bas avec
  des cases neuves (tag « passage 2/2 »), l'ancien passage reste intact au-dessus.
- **« Suite de l'algorithme »** : sous le journal, tous les blocs pas encore visités restent
  lisibles en entier (dépliés par défaut — tout l'algorithme d'un coup dès l'ouverture) et
  actifs : cocher une étape ou « Commencer ici → » fait entrer le bloc dans le journal, sans
  que rien ne bouge sous le doigt. La branche écartée par une décision est marquée « hors
  chemin », grisée mais jamais verrouillée.
- Le schéma navigable (v4.7.0) et la minimap (v4.8.0) sont inchangés et suivent le journal ;
  y taper un bloc déjà visité défile vers sa dernière carte, un bloc jamais visité y entre.
- Format de session et export inchangés ; la vue guidée reste identique. 5 tests ajoutés (430).

## [4.8.0] — 2026-07-16
La vue d'ensemble gagne sa **minimap** : où que l'on soit dans la page, la position dans
l'algorithme reste visible et chaque bloc est à un tap.

### Ajouté
- **Bande de pastilles-blocs sur téléphone et tablette** (< 1000 px) : sous le bandeau de crise,
  une ligne collante de pastilles d'état — vert ✓ = bloc fait, bleu = position actuelle,
  cerclé ambre = décision, pointillé estompé = hors chemin — avec la pastille courante
  auto-centrée. Taper une pastille = aller au bloc ; « Dg ✓ » et « ③ Surv. » sautent vers la
  confirmation diagnostique et les surveillances. C'est la table des matières de crise.
- **Minimap dans le rail droit sur ordinateur** (≥ 1000 px) : liste verticale des blocs
  (n°, titre, avancement) sous les minuteurs, synchronisée en direct avec chaque coche et
  chaque navigation — mêmes états, mêmes sauts.

## [4.7.0] — 2026-07-16
L'organigramme devient **navigable** : taper un bloc dans le schéma y emmène directement, et le
schéma se peint selon l'avancement de la session.

### Ajouté
- **Nœuds cliquables dans le schéma de l'algorithme** (panneau « Algorithme » et plein écran) :
  taper un bloc = s'y rendre dans la checklist (bloc déjà visité → on y retourne sans rien
  perdre ; bloc jamais visité → le parcours s'y étend). Jamais de cochage dans le schéma — la
  coche reste un geste de la checklist, sur ses grandes cibles ; naviguer ne démarre pas de
  session. Accessible au clavier (Tab + Entrée/Espace) ; l'aperçu de l'éditeur reste inerte.
- **Le schéma montre l'avancement** : halo bleu = bloc où l'on est, badge ✓ vert = bloc
  entièrement coché, blocs « hors chemin » atténués — mis à jour en direct à chaque coche et
  chaque navigation, en thème clair comme sombre.

### Modifié
- **Performances** : la mise en page du schéma n'est plus jamais reconstruite pendant la crise
  (elle l'était à chaque changement de bloc) — l'état est désormais peint par-dessus une
  géométrie en cache.

## [4.6.0] — 2026-07-16
Réfection du mode crise des aides cognitives : une **vue d'ensemble** montre désormais TOUT
l'algorithme d'un coup — tous les blocs cochables à la suite, démarrage possible n'importe où,
retour en arrière jamais bloquant (doctrine QRH/ECAM).

### Ajouté
- **Vue d'ensemble de la prise en charge** (nouveau défaut des fiches à algorithme) : tous les
  blocs affichés dans l'ordre du parcours (BFS depuis le départ), chacun avec sa ligne d'état
  repliable (n°, titre, compteur x/y, ✓ vert quand complet) et ses étapes cochables. La position
  « Vous êtes ici » suit la dernière action ; cocher dans un bloc jamais visité y déplace le
  parcours (le chemin s'étend, rien n'est présumé). Boutons « Tout replier / Tout déplier » et
  « ↺ Recommencer » (maintenir).
- **Bascule « Vue d'ensemble ↔ Vue guidée »** en tête de l'étape ② : le mode bloc à bloc
  historique reste disponible tel quel ; les deux vues partagent la même session (coches,
  chemin, minuteurs — basculer ne perd rien). Préférence mémorisée par utilisateur et
  synchronisée (elle s'applique à la prochaine ouverture, jamais à l'écran en cours).
- **Décisions jamais bloquantes** : les options restent actives en permanence — changer d'avis
  = un tap ; l'option prise est marquée ✓, la branche écartée est **grisée « hors chemin » mais
  toujours cochable** (un bloc où l'on a agi n'est jamais grisé : les coches sont la trace du
  soin).
- **Boucles maîtrisées** : reboucler par l'algorithme (option de décision, arête « ↺ … —
  nouveau passage ») redonne des cases neuves ; un simple coup d'œil en arrière ne modifie
  JAMAIS les coches ; « ↺ Refaire ce bloc » permet de re-dérouler volontairement un bloc
  (tag « passage n/N », l'ancien passage reste au compte-rendu).
- 19 tests ajoutés (422) sur les nouvelles fonctions pures (`flowOrder`, `latestPass`,
  `offPathSet`, `minimapData`).

### Modifié
- **Exporter en PDF / imprimer** : la fiche s'imprime désormais en vue d'ensemble (tous les
  blocs, dans l'ordre, blocs repliés rouverts le temps de l'impression).
- **Aperçu de l'éditeur** : l'aperçu d'un brouillon utilise un bac à sable de navigation —
  cocher dans un aperçu ne touche plus jamais la session vive d'une autre fiche.

### Corrigé
- **Algorithme tronqué à l'impression** : le schéma SVG était coupé à 300 px de haut dans le
  PDF ; il s'imprime désormais en entier.

## [4.5.4] — 2026-07-16
Les protocoles gagnent des listes cochables `- [ ]` pour les vérifications rapides en lecture.

### Ajouté
- **Listes cochables dans le contenu rédigé des protocoles** : syntaxe GitHub `- [ ] tâche`
  (`- [x]` déjà cochée), aussi en liste numérotée — pour cocher du matériel ou des critères en
  lisant (bouton dédié dans la barre d'outils de l'éditeur, case au registre CONFIRMATION,
  texte jamais barré : on doit pouvoir relire). Les coches sont **éphémères** : elles survivent
  aux re-rendus tant qu'on reste sur le protocole et repartent de l'état écrit à chaque
  ouverture — pas de session, pas de trace (pour une checklist tracée avec minuteurs et
  compte-rendu, créer une aide cognitive et la lier par « Voir aussi »). **Rien ne change dans
  le format** : le corps reste une chaîne, export JSON identique ; une version antérieure de
  l'app (ou tout lecteur Markdown qui ignore la syntaxe) affiche « [ ] tâche » en liste
  normale, GitHub la rend en case native. Les aperçus de l'éditeur dessinent les cases sans les
  rendre cliquables. 14 tests ajoutés (403), vérifié en conditions réelles (cochage
  clic/clavier, lien dans une tâche, re-rendu de synchro, remise à zéro à la ré-ouverture).

### Corrigé
- **Curseur perdu après les boutons de mise en forme** (éditeur de protocole) : poser un titre,
  une liste, une citation ou une liste cochable sur une ligne du milieu du texte modifiait bien
  la ligne, mais la frappe suivante partait tout en bas du document (réécrire le contenu du
  champ remet le curseur à la fin). Le curseur est désormais reposé en fin de ligne modifiée —
  comme le faisaient déjà les boutons gras/encadrés/tableau.

### Décision d'architecture
- **Pas de section « Checklists » à part** : les aides cognitives SONT les checklists de l'app
  (sessions, minuteurs, reprise, compte-rendu). Une troisième section aurait dupliqué ce
  concept pour un coût élevé (stockage, synchronisation, navigation, import/export).

## [4.5.3] — 2026-07-16
L'app dit quand elle travaille : « Chargement… » au démarrage, anneau tournant sur le bouton
Compte pendant la synchronisation.

### Ajouté
- **Indicateur d'activité de la synchronisation** : pendant qu'une synchro tourne, la pastille
  d'état du bouton Compte (en-tête) devient un **anneau tournant** discret — un seul endroit,
  constant, visible dans toutes les vues. C'est un signal d'**activité**, pas une alerte :
  registre INFORMATION (mouvement calme, bleu `--link`), les autres états gardent leur pastille
  statique (vert en phase, rouge erreur, gris hors-ligne). Aucune nouvelle logique : l'anneau
  est piloté par la source d'état existante (`setSyncChip`), en CSS seul ; il ralentit sous
  `prefers-reduced-motion` et disparaît en session de crise (le bouton Compte y est déjà
  masqué — jamais de signal non actionnable pendant un soin, doctrine ECAM). Le bandeau
  système reste réservé à l'information actionnable (« Nouvelle version — Recharger ») : pas de
  bandeau furtif à chaque ouverture.
- **« Chargement… » au démarrage** : pendant la lecture initiale des données (IndexedDB), la
  page affiche une petite roue et « Chargement… » au lieu d'une zone vide — placé dans le HTML
  statique, remplacé par le tout premier rendu, zéro JavaScript ajouté.

## [4.5.2] — 2026-07-16
L'accueil ne se reconstruit plus inutilement juste après l'ouverture : les premiers taps ne
sont plus « avalés ».

### Corrigé
- **App qui semble ne pas répondre à l'ouverture** : la synchronisation se lance à chaque
  ouverture (et à chaque retour au premier plan), et son chargement de profil se terminait par
  une reconstruction **inconditionnelle** de l'accueil — environ une seconde après
  l'affichage, pile quand on commence à s'en servir. Comme le profil (bibliothèques, rôle) est
  déjà restauré depuis le cache au démarrage, cette reconstruction ne changeait rien à l'écran…
  mais remplaçait l'élément sous le doigt entre le toucher et le clic : le tap était perdu,
  d'où l'impression d'une app « bloquée pendant le chargement ». Désormais le re-rendu n'a lieu
  que si le profil a **réellement changé** (bibliothèque ajoutée/retirée, rôle modifié, comptes
  en attente). Les autres re-rendus de synchro étaient déjà conditionnés à un vrai changement ;
  à l'ouverture sans nouveauté distante, plus **aucune** reconstruction ne suit l'affichage
  initial. Vérifié en conditions réelles (profil inchangé = zéro re-rendu).

## [4.5.1] — 2026-07-16
L'animation de bascule Aides ↔ Protocoles ne se rejoue plus quand un re-rendu tombe pendant
qu'elle joue.

### Corrigé
- **Animation d'apparition rejouée plusieurs fois** à la bascule de section : un re-rendu
  survenant pendant les 300 ms de l'animation (typiquement une synchronisation qui se termine —
  jusqu'à trois re-rendus d'affilée : catégories, contenu, documents téléchargés) remplaçait la
  liste en plein vol, ce qui relançait l'animation depuis zéro à chaque fois — et laissait la
  classe d'animation posée (la fin de l'animation de l'élément détruit n'arrivait jamais), donc
  chaque re-rendu suivant la rejouait encore. Désormais tout rendu neutralise la classe de
  bascule : l'animation voulue joue toujours sa fois unique (elle est posée après le rendu de
  `setSection`), et un re-rendu en plein vol pose simplement le contenu, sans rejouer
  l'apparition. Vérifié en conditions réelles : 1 seul départ d'animation, même avec deux
  re-rendus parasites dans la fenêtre.

## [4.5.0] — 2026-07-16
Les documents PDF voyagent enfin avec les exports : nouveau format `.zip` « avec documents »,
au choix à l'export, accepté à l'import — et visionneuse plus robuste face aux PDF endommagés.

### Ajouté
- **Export « avec documents » (.zip)** : quand le contenu exporté référence des PDF joints,
  l'app demande — **« Avec les documents (.zip) »** ou **« Sans les documents (.json) »**
  (✕/Échap = export abandonné). Le `.zip` contient `donnees.json` (strictement le JSON
  historique, format `version: 3` inchangé — un client antérieur peut l'extraire à la main et
  l'importer) et `documents/<id>.pdf` (les binaires, dédoublonnés : un document partagé entre
  plusieurs fiches n'est embarqué qu'une fois). Proposé partout où l'on exporte : fiche seule,
  protocole seul, brouillons des éditeurs et « Exporter mes données » (fenêtre Compte). Un
  document pas encore téléchargé sur l'appareil est exporté en référence seule, avec un
  avertissement chiffré.
- **Import du `.zip`** aux deux points d'entrée existants (sélecteur de fichier du dialogue
  Créer et glisser-déposer), détecté à la **signature** du fichier, jamais à l'extension.
  Règles de restauration : un import **n'écrase jamais** un document déjà présent (même
  identifiant → le document local fait foi — importer ne peut pas modifier les PDF des autres
  fiches) ; un binaire du zip n'est posé que s'il manque, signé `%PDF-` et sous le plafond de
  15 Mo ; il repart ensuite vers le cloud à la synchronisation suivante. Venu d'un autre
  espace, un export `.zip` transporte désormais ses documents (avant : références vidées).
- **ZIP maison, zéro dépendance** : écriture sans compression (les PDF le sont déjà), lecture
  STORE + DEFLATE via l'API native du navigateur (un export dézippé puis re-zippé par
  macOS/Windows reste importable), CRC de chaque entrée vérifié (une archive endommagée est
  rejetée d'un bloc — jamais d'import à moitié), bornes anti-« zip bomb ». 12 tests ajoutés
  (389), vérifié de bout en bout (import, non-écrasement, export des deux formats).

### Corrigé
- **Visionneuse : PDF endommagé après un en-tête valide** — la lecture de la première page est
  désormais sous le même garde-fou que l'ouverture du document : le message « fichier
  endommagé » s'affiche au lieu d'un « Ouverture du document… » sans fin.
- La taille affichée d'un document importé reflète le fichier réellement présent sur
  l'appareil, pas celle déclarée par le fichier d'import.

## [4.4.7] — 2026-07-16
Frecency synchronisée entre appareils, arrivée sur les éditeurs bien en haut de page, et
recherche débarrassée des cartes « Session en cours ».

### Modifié
- **Frecency synchronisée** (connecté) : le classement par usage des résultats de recherche
  (v4.4.6) voyage désormais entre vos appareils, dans le document personnel — comme les
  épingles et les préférences, mais **fusionné** au lieu d'être remplacé : chaque appareil
  compte ses propres ouvertures, et à la synchronisation c'est l'entrée au compte le plus
  grand qui gagne, par fiche (fusion idempotente : jamais de double-compte, assainie à
  l'import — ids sûrs, bornes, plafond 200 entrées). L'envoi est **espacé d'au moins
  10 minutes** : ouvrir une fiche ne coûte jamais une écriture réseau. 10 tests ajoutés (377).
- **En mode recherche, les cartes « Session en cours » s'effacent** : quand on tape une
  requête, on cherche autre chose. La session reste signalée par le tag « ● En cours » sur sa
  carte-résultat et par la barre de minuteurs de l'en-tête ; les cartes reviennent dès que la
  requête se vide.

### Corrigé
- **Arrivée sur un éditeur légèrement « descendue » (iOS)** : le haut de page était bien posé
  au rendu, mais Safari pouvait re-décaler la page juste après (fermeture asynchrone du
  clavier de la recherche, restauration de focus à la fermeture du dialogue Créer). Double
  correctif : le champ actif est défocalisé dès l'ouverture du dialogue Créer, et le haut de
  page est ré-affirmé dans les instants qui suivent l'arrivée — uniquement à l'arrivée (jamais
  pendant l'édition) et seulement pour un petit décalage (< 160 px : on corrige un artefact,
  jamais un défilement volontaire).

## [4.4.6] — 2026-07-16
Ouverture instantanée (cache d'abord), visibilité des documents pas encore téléchargés, et
résultats de recherche classés par usage réel (frecency).

### Modifié
- **Ouverture instantanée — « cache d'abord »** : dès qu'une copie locale existe, l'app
  s'affiche **immédiatement**, quel que soit l'état du réseau (la v4.4.4 avait réduit
  l'attente réseau-d'abord de 3,5 s à 1,5 s ; cette version la supprime). Le réseau est
  toujours consulté **en arrière-plan** : la copie hors-ligne est rafraîchie pour l'ouverture
  suivante, et quand une nouvelle version s'installe, le bandeau persistant « Nouvelle version
  disponible — **Recharger** » propose de l'appliquer tout de suite — invite **non bloquante**
  (✕ pour ignorer, jamais de rechargement forcé, masquée pendant une session de crise) ; sans
  action, la nouvelle version arrive de toute façon à l'ouverture suivante.

### Ajouté
- **Badge « △ à télécharger » sur les documents PDF** : un document ajouté sur un autre
  appareil, dont le fichier n'est pas encore arrivé ici, l'annonce désormais **à froid** dans
  la liste « Documents » (fiches et protocoles) — on ne découvre plus en pleine crise qu'un
  PDF n'est pas consultable hors ligne. L'état est décidé sur la vraie lecture du stockage
  local (un PDF endommagé mais présent garde l'icône générique **sans** badge — message
  juste), et le badge disparaît **sous les yeux** (vignette posée dans la foulée) dès que le
  téléchargement de fond de la synchronisation fait arriver le fichier — téléchargement déjà
  retenté à chaque synchronisation avec du réseau.
- **Frecency dans la recherche** : les résultats sont classés par usage réel — les fiches et
  protocoles qu'on **ouvre le plus, récemment**, remontent en premier (compte d'ouvertures
  amorti par l'ancienneté : pleine valeur ≤ 15 j, demi-valeur ≤ 60 j, quart au-delà). Préférence
  **locale à l'appareil** (même famille que les épingles), plafonnée aux 200 usages les plus
  récents. Les épingles restent toujours premières ; la **liste par défaut reste alphabétique**
  (décision v4.3.2) ; le classement ne dépend pas de la requête, donc **les cartes ne se
  réordonnent pas pendant la frappe** (calme sous stress). 7 tests ajoutés (367).

## [4.4.5] — 2026-07-16
Navigation entre blocs instantanée : la mise à jour ciblée du cochage (v4.2) est étendue au
geste de navigation lui-même.

### Modifié
- **Naviguer dans l'algorithme ne reconstruit plus toute la vue** : « Continuer → », le choix
  d'une option de décision, « Bloc précédent », le fil d'Ariane, « Repartir d'ici » et
  « Recommencer » ne re-rendent plus que le nécessaire — fil d'Ariane, bloc courant, rangée de
  navigation, compteur du panneau algorithme et halo du SVG (`renderNavOnly`). La galerie
  d'images base64, le parcours de soin, les documents et la note ne sont plus reconstruits à
  chaque pas (des dizaines de ms par tap sur mobile — or c'est le geste répété d'un arbre
  décisionnel). La section navigation et ses écouteurs sont extraits de `renderRead` en
  briques partagées (`navSection`/`bindNavEvents`) : rendu complet et rendu ciblé produisent
  le MÊME HTML par construction.
- **Les cas qui changent l'état global restent des rendus complets** (doctrine inchangée) :
  fin d'algorithme (« Terminer l'algorithme ✓ » — les étapes ②/③ du rail changent d'état),
  premier « Continuer » d'une session quand l'étape ① était ouverte (repli différé, v4.4.2),
  démarrage de session par première action (`renderKeepAnchor`). Structure inattendue
  (aperçu, fiche sans bloc) : repli automatique sur le rendu complet.

## [4.4.4] — 2026-07-16
Documents PDF plus lisibles (miniatures, zoom d'ouverture « page entière »), recherche
multi-mots avec extraits contextuels, démarrage plus rapide en réseau dégradé, et une salve
de corrections (onglet Protocoles, bottom sheet des catégories, ombre fantôme, tactile).

### Ajouté
- **Miniatures des documents PDF** : dans les listes « Documents » des vues lecture (fiches ET
  protocoles), chaque rangée montre la **première page en vignette** — on reconnaît un document
  d'un coup d'œil avant de l'ouvrir, d'autant plus utile quand il y en a plusieurs. Génération
  **paresseuse** (pdf.js n'est chargé qu'à la première vignette manquante, différée à
  l'inactivité — jamais au démarrage), une seule à la fois (plafond mémoire canvas d'iOS),
  cache mémoire de session. Document pas encore téléchargé ou repli KV : icône générique.
- **Zoom d'ouverture « page entière »** : la visionneuse s'ouvre au zoom qui montre la première
  page **en entier**, calculé d'après le ratio réel du document (portrait comme paysage) et la
  fenêtre — borné à 100 % (sur téléphone, rien ne change : le calcul y retombe sur la pleine
  largeur). Nouveau bouton **« Page »** à côté de « Largeur » pour retrouver ce cadrage, et
  **plancher de dézoom abaissé de 50 % à 25 %** (survoler un long document).
- **Recherche multi-mots** : chaque mot de la requête doit être présent, où qu'il soit —
  « choc anaph » trouve la fiche dont le titre porte « anaphylactique » et une étape « choc » ;
  l'ancien comportement exigeait les mots contigus.
- **Extraits contextuels dans les résultats** : sous le titre de chaque carte-résultat, la
  première ligne de contenu où la requête matche, termes en **graisse** — on comprend pourquoi
  le résultat est là sans ouvrir la fiche. Relief par la graisse SEULE (doctrine du projet : la
  couleur est un registre — rouge = vital, ambre = vigilance — jamais un simple relief) ; le
  titre est exclu des sources d'extrait (déjà affiché sur la carte). 17 tests ajoutés (360).

### Modifié
- **Démarrage en réseau dégradé** : le service worker basculait sur la copie hors-ligne après
  **3,5 s** de réseau muet (« lie-fi » : Wi-Fi hospitalier qui accepte la connexion mais ne
  répond pas) — jusqu'à 3,5 s d'écran blanc à chaque ouverture. Délai abaissé à **1,5 s** ; la
  fraîcheur n'est pas sacrifiée (le fetch continue en arrière-plan pour l'ouverture suivante).
- **Réactivité de la vue fiche** : le SVG de l'algorithme n'est plus reconstruit (mesure + BFS +
  routage) à chaque re-rendu de session quand le panneau est ouvert — mémo par objet fiche +
  bloc courant, réservé à la lecture (l'éditeur, qui mute son brouillon en place, recalcule
  toujours) ; l'image d'un bloc passe en `loading="lazy" decoding="async"` (plus de re-décodage
  synchrone à chaque navigation).
- **Bottom sheet des catégories** (éditeurs, « Autre… ») : poignée et champ « Filtrer… » sont
  désormais **épinglés en haut** (ils partaient hors écran avec la liste), le défilement est
  **confiné à la feuille** (`overscroll-behavior:contain` — arrivé en butée, le glissement ne
  faisait défiler toute la page derrière) et un glissement sur le voile ne défile plus rien.
- **Tactile** : le « soulèvement » des cartes au survol est neutralisé sur écran tactile
  (`@media (hover:none)`) — sur iOS, le premier tap pose l'état hover, et un hover qui bouge
  l'élément favorise le double-tap. Seule règle `:hover` du fichier qui changeait la géométrie.

### Corrigé
- **Onglet Protocoles qui « retombait » sur les aides** : créer/modifier une catégorie puis
  fermer la fenêtre (ou ouvrir/fermer « Gérer les catégories », fermer la fenêtre Compte,
  modifier/créer/supprimer une bibliothèque) re-rendait toujours la liste des AIDES sous
  l'onglet Protocoles. Tout re-rendu de l'accueil passe désormais par un répartiteur unique
  (`renderLibrary`) qui respecte l'onglet courant.
- **Ombre fantôme en haut à gauche** : le lien d'évitement clavier (« Aller au contenu »), garé
  hors écran, laissait « suinter » son ombre portée sous le bord supérieur (très visible en
  thème sombre). L'ombre ne vit plus que sur l'état focalisé.

## [4.4.3] — 2026-07-15
De la couleur dans les protocoles — mais seulement celle des registres : encadrés typés à la
syntaxe GitHub, surligneur achromatique, et taille d'affichage réglable image par image.

### Ajouté
- **ENCADRÉS TYPÉS dans le contenu rédigé** : une citation peut porter un registre, exactement
  comme une étape de fiche porte « ⚠ » ou « △ ». Quatre registres, aucun nouveau code couleur :
  `> [!CAUTION]` **alerte** (rouge), `> [!WARNING]` **attention** (ambre), `> [!NOTE]`
  **information** (bleu), `> [!TIP]` **confirmation** (vert) ; une citation sans marqueur reste
  neutre. La couleur n'est **jamais seule** : bord gauche 4 px + icône + libellé du registre en
  toutes lettres (WCAG 1.4.1).
  **Syntaxe = celle des « alerts » de GitHub**, entièrement tapable au clavier — donc rendue
  nativement par GitHub, GitLab, pandoc et Typora, et dégradée en simple citation lisible partout
  ailleurs. Les quatre boutons de la barre d'outils produisent la **forme canonique** (marqueur
  seul sur sa ligne, mot-clé en MAJUSCULES : seul dénominateur commun des implémentations tierces).
  En lecture, l'app accepte aussi les alias `[!alerte]` / `[!attention]` / `[!info]` / `[!ok]`,
  les glyphes ⚠ △ ℹ ✓ (copier-coller depuis une fiche), la forme d'une seule ligne, et les cinq
  mots-clés GitHub (`IMPORTANT` est rendu au registre INFORMATION). Sécurité : le registre vient
  d'un **jeu fermé** posé en classe — un mot-clé inconnu redonne une citation neutre, aucune
  valeur utilisateur n'atteint jamais une classe ni un attribut.
- **`==surligné==`** : surligneur **achromatique** (registre MEMO) — faire ressortir un mot sans
  emprunter une couleur qui, dans cette app, veut dire « ça tue si on l'oublie » (rouge) ou « c'est
  là qu'on se trompe » (ambre). Syntaxe répandue (Obsidian, Typora, pandoc) ; ailleurs, elle
  s'affiche telle quelle. Bouton « S » dans la barre d'outils.
- **Taille d'affichage des images, réglable IMAGE PAR IMAGE** : chaque image insérée apparaît dans
  une galerie sous l'éditeur, avec son propre sélecteur (25 / 33 / 50 / 66 / 75 / 100 %) et une
  vignette qui insère une nouvelle référence à la même image (une image peut illustrer deux
  passages). La taille vit dans le **modèle** (`p.images[i].scale`), jamais dans la syntaxe : un
  `=50%` glissé dans `![](img:ID)` casserait la regex des clients antérieurs et **ferait
  disparaître les images** en bibliothèque partagée. Rendu par une classe issue d'un jeu fermé
  (jamais un nombre interpolé dans un style) ; la réduction ne s'applique qu'au-dessus de 560 px
  (sur téléphone, une image à 25 % serait illisible sous stress). Export v3 inchangé : un ancien
  client ignore le champ et affiche l'image à 100 %.

### Modifié
- **Barre d'outils du protocole** : ajout des 4 boutons d'encadré (chacun coloré à son registre)
  et du surligneur. Poser un encadré sur un encadré **remplace** son registre au lieu d'empiler
  les marqueurs — comme un titre posé sur un titre remplace son niveau (v4.4.2).
- Légende de syntaxe complétée (encadrés, surlignage, taille d'image) avec une note de
  **portabilité** : ce qui est rendu ailleurs, ce qui dégrade — et en quoi rien n'est jamais perdu.

### Sécurité / tests
- 27 tests ajoutés (343 au total) : reconnaissance des 4 registres + 5 mots-clés GitHub + alias FR
  + glyphes, marqueur inconnu → citation neutre, registre lu sur la seule 1ʳᵉ ligne, forme
  canonique, absence de classe issue du texte utilisateur, surlignage échappé et neutralisé dans
  du code, jeu fermé des échelles d'image, valeur par défaut posée par `migrate`, et deux images
  aux tailles indépendantes.

## [4.4.2] — 2026-07-14
Tableaux dans les protocoles, sélecteur de type dans le dialogue « Créer », pieds de page
harmonisés, icônes agrandies, et deux correctifs iOS (zoom au focus, colonnes du bandeau).

### Ajouté
- **TABLEAUX dans le contenu rédigé des protocoles** (mini-Markdown) : syntaxe pipe
  `| a | b |` avec ligne de séparation obligatoire `|---|` en 2ᵉ ligne, qui porte l'**alignement**
  (`|:-:|` centré, `|---:|` à droite) ; gras, italique, `code` et liens fonctionnent dans les
  cellules ; pipe littéral en `\|`. Bouton dédié dans la barre d'outils, légende de syntaxe
  complétée (y compris `att:` et `img:`, jusqu'ici non documentés). Rendu dans un **conteneur
  défilant focusable** (`role="region"`, tabindex, `:focus-visible`) : sur iPhone le tableau
  défile au lieu d'écraser ses colonnes ; il se déploie à l'impression. Sécurité : le contenu
  des cellules passe par `mdInline` (donc `esc()` d'abord) et l'alignement vient d'une **table
  blanche fermée** posée en classe — aucune valeur utilisateur n'atteint jamais un attribut.
  Pipes ouvrant ET fermant exigés (plus strict que GFM) : une phrase clinique contenant un « | »
  ne peut pas devenir un tableau par accident. Export v3 inchangé (un ancien client affiche des
  lignes de texte à pipes — dégradation lisible). 14 tests ajoutés.
- **Bouton H1 dans la barre d'outils du protocole** (le niveau existait dans le parseur mais
  n'était pas atteignable) ; poser un titre sur un titre **remplace** son niveau au lieu
  d'empiler les `#`.
- **Sélecteur de type dans le dialogue « Créer »** : « Aide cognitive » / « Protocole » via le
  **même composant segmenté à pastille glissante** que la tab bar basse (`.seg`, généralisé —
  aucun CSS dupliqué, `prefers-reduced-motion` couvert). Choisir un type bascule aussi l'onglet
  de l'accueil : au retour de l'éditeur, on retrouve la bonne liste. Clavier : flèches ← →,
  `aria-selected`, tabindex itinérant.

### Modifié
- **Pieds de page harmonisés** (fiche ET protocole — le protocole n'en avait aucun) : la chaîne
  morte « ● Local — hors ligne OK », qui affirmait « Local » même synchronisé au cloud, est
  remplacée par l'**état réel de stockage**, désormais produit par une source unique
  (`storageState`, pure et testée) partagée avec le pied de la barre latérale : « ☁ Cloud ·
  3 Mo sur l'appareil » ou « Cet appareil seulement · 3 Mo ». Le « maj MM/AAAA » et le code
  court disparaissent du pied (tous deux déjà en tête de page) : il ne reste que l'état et la
  version. En session de crise, l'état de stockage s'efface — comme il s'efface du pied de la
  sidebar (aucun signal non actionnable pendant un soin).
- **Rail « parcours de soin » agrandi sur grand écran** (≥ 1000 px) : pastilles 28 → 34 px,
  chiffres 12,5 → 15 px, ✓ des étapes faites à l'échelle, ligne de liaison et titres recalés
  (géométrie liée, documentée dans le CSS). Lisible à distance sur un poste de déchocage.
- **Hiérarchie des titres du contenu rédigé corrigée** : elle était **inversée** (H3 14 px >
  H1 13 px > H2 12,5 px — un `###` paraissait plus important qu'un `#`). La saillance passe
  désormais par le poids, l'encre et un filet, jamais par la seule taille : H1 = capitales
  encre pleine + filet, H2 = capitales encre douce, H3 = casse normale. Les titres restent
  volontairement plus petits que le corps (15 px) — le texte prime, le titre jalonne.
- **Logotype de l'accueil** 18 → 20 px (sans élargir la barre : la hauteur est fixée par le
  bouton Compte) et **glyphe des icônes de l'app agrandi** : 53 % → 63 % du canevas pour les
  icônes iOS/PWA, 44 % → 49 % pour les icônes maskable Android (zone sûre respectée : le
  bouclier n'est jamais rogné par un masque circulaire). Coins arrondis et opacité préservés.
- **Repli de l'étape ① « Confirmation diagnostique » : doctrine figée** (audit QRH/ECAM). Un
  démarrage **implicite** (cocher une étape, lancer un minuteur…) ne replie **jamais** le bloc —
  `renderKeepAnchor` ne peut compenser le scroll que si la page est assez défilée ; en haut de
  fiche ou sur une page courte, replier ferait sauter le contenu sous le doigt (c'est le bug
  v4.3.2, en pire). Le repli est désormais **différé à la première navigation « Continuer → »**,
  qui l'acquitte et déplace déjà le contexte à la demande de l'utilisateur : l'écran de crise
  s'épure sans qu'aucun contenu ne bouge sous le doigt. `renderKeepAnchor` renvoie le résidu de
  compensation (garde-fou testable).

### Corrigé
- **iPhone — zoom automatique au focus de la barre de recherche** : Safari iOS zoome dès qu'un
  champ fait moins de 16 px. Le correctif v4.3.1 existait mais était **inopérant** — placé trop
  haut dans la feuille, il était écrasé par les règles suivantes (une media query n'ajoute
  aucune spécificité, seul l'ordre source tranche). Bloc unique reposé en fin de feuille et
  **étendu à tous les champs concernés** après audit : recherche, corps du protocole, notes,
  filtre de catégories, journal de session, renommage de catégorie, légende d'image, invitations
  et rôles. Aucun `maximum-scale` au viewport (WCAG 2.2 §1.4.4).
- **Bandeau « Ne pas oublier » en 2 colonnes — décalage vertical** : la grille faisait **partager
  les rangées** aux deux colonnes (hauteur = plus grand item), si bien qu'un rappel sur deux
  lignes creusait un trou en face. Passage en **multi-colonnes CSS** : deux colonnes de flux
  indépendantes, remplissage compact, ordre de lecture (et d'annonce aux lecteurs d'écran)
  inchangé, et un rappel n'est jamais coupé entre deux colonnes.

### Vérifié (aucun changement)
- **Contraste du texte des boutons rouges pleins en thème sombre** : déjà conforme. Le blanc sur
  `--critical-bd` sombre (#ff5a52) donnerait 3,07:1 (échec AA) — mais les deux seuls boutons
  concernés (« Terminer la session », confirmation destructrice) passent déjà à l'encre du fond
  en sombre, soit 6,02:1. Aucun autre bouton à fond rouge plein n'existe dans l'app.

## [4.4.1] — 2026-07-14
Finitions du parcours de soin : fil d'Ariane à hauteur fixe, encadrés de session unifiés,
bouton de démarrage au gabarit « Continuer », mémoire de défilement de l'accueil, éditeur
réordonné, prompt IA durci et fiches d'exemple allégées.

### Modifié
- **Encadrés de session unifiés** : « Minuteurs & compteurs » (rangée repliée et panneau) et
  « Journal des actions » suivent le gabarit commun des blocs de la fiche (surface, bordure
  fine, rayon 8, sans ombre — comme « Confirmation » et « Algorithme ») : un seul langage
  d'encadré dans le parcours de soin.
- **« Confirmé — démarrer la session » au gabarit de « Continuer »** : pleine largeur du bloc,
  50 px, typographie 15/800 — la rangée d'action d'une étape a partout la même forme. Il reste
  bleu `--primary` (démarrer = action primaire ; le vert reste la CONFIRMATION d'un bloc
  entièrement coché) ; l'aide passe dessous, centrée.
- **Éditeur de fiche réordonné dans l'ordre de LECTURE** du parcours de soin : identité →
  Ne pas oublier (avec la mention « 4 rappels maximum ») → Confirmation diagnostique →
  Prise en charge → Minuteurs & compteurs → Contexte local → Repères posologiques →
  À vérifier → Diagnostics différentiels → annexes. On rédige dans l'ordre où l'équipe lira.
- **Prompt IA** : « notForget » est désormais borné à **4 rappels maximum** (limite stricte,
  alignée sur le garde-fou de l'éditeur) avec consigne de reclassement (étape ⚠ du bloc
  concerné, ou « verify ») — l'ancienne consigne commune « ≤ 7 items » laissait passer des
  bandeaux-fleuves.
- **Fiches d'exemple** : le chronomètre « Temps écoulé » est retiré d'Anaphylaxie et d'ACR —
  le chrono global de session (en-tête) le rend redondant. Micro-libellé : « Schéma = vue
  d'ensemble · étapes à cocher en-dessous ↓ » (raccourci).

### Corrigé
- **Fil d'Ariane à HAUTEUR FIXE sur mobile** (règle ECAM : un long parcours ne doit jamais
  allonger la page ni repousser les étapes hors de l'écran) : les jalons ne passent plus à la
  ligne — une seule rangée à défilement horizontal (même geste que la barre de minuteurs de
  l'en-tête), position COURANTE auto-centrée à chaque rendu, historique consultable d'un
  glissement. Testé sur 6 tours de boucle ACR : 32 px de haut, constants.
- **Défilement de l'accueil par section** : basculer Aides ↔ Protocoles n'hérite plus du
  défilement de l'autre liste (la nouvelle section arrive EN HAUT) — mais revenir à une
  section retrouve l'endroit exact où on l'avait laissée (mémoire par section, fenêtre en
  étroit / colonne centrale en large).

## [4.4.0] — 2026-07-14
Parcours de soin numéroté dans la vue fiche : la séquence « ① confirmer le diagnostic →
② dérouler l'algorithme → ③ surveiller » devient la structure visible de l'écran de crise
(option B des maquettes, prérequis QRH / ECAM / WCAG 2.2 AA).

### Ajouté
- **Rail « parcours de soin »** (`<ol class="care-path">`) dans la vue lecture d'une aide
  cognitive : ① **Confirmer le diagnostic** → ② **Prise en charge** → ③ **Surveillances &
  pièges**. Pastilles : bleu = étape active (`aria-current="step"`), vert ✓ = faite, neutre
  cerclé = à venir — jamais d'ambre ni de rouge dans le rail (registres réservés à l'alerte,
  ECAM « un signal = un sens ») ; en thème sombre l'encre des pastilles passe à l'encre du
  fond (contrastes AA vérifiés dans les deux thèmes, ≥ 4.9:1). L'état est aussi porté par le
  texte (« Diagnostic confirmé ») et le glyphe ✓ — jamais la couleur seule (WCAG 1.4.1).
  Étapes vides omises (numérotation recalculée) ; une seule étape non vide → pas de rail.
  La séquence est **suggérée, jamais bloquante** (QRH) : la première action clinique démarre
  toujours la session.
- **Lien « Tableau atypique ? → Diagnostics différentiels »** dans l'étape ① (affiché si la
  fiche a des différentiels) : saut direct à l'étape ③, cible tactile 44 px, défilement
  instantané (pas d'animation de déplacement — `prefers-reduced-motion` de fait respecté).
- **Garde-fou « Ne pas oublier » dans l'éditeur** (non bloquant, registre ATTENTION) : au-delà
  de 4 rappels, une note suggère de reclasser (étape ⚠ du bloc concerné, ou « À vérifier ») —
  les memory items sont rares par construction. Recompté à la frappe.
- **`renderKeepAnchor`** : tout re-rendu de démarrage de session (cocher, minuteur, compteur,
  horodatage) compense le scroll pour que l'élément touché **ne bouge pas d'un pixel** à
  l'écran (le bouton « Confirmé — démarrer » disparaît du flux au démarrage — sans ancrage,
  le contenu remontait sous le doigt ; ECAM : le contexte de travail ne bouge jamais).

### Modifié
- **Étape ① = l'ex-bloc « Confirmation diagnostique »** : son en-tête repliable devient le
  titre d'étape — « Confirmer le diagnostic » avant la session, « Diagnostic confirmé »
  ensuite ; critères ré-ouvrables d'un tap à tout moment (doute en cours d'algorithme), la
  session et les minuteurs continuent. Le bouton de démarrage devient « **Confirmé — démarrer
  la session** » quand la fiche a des critères (le geste porte la confirmation) et REPLIE
  délibérément l'étape ① (acquittement par l'action) ; sans critères, il reste « Démarrer la
  session » en tête de l'étape ②.
- **« À vérifier » et « Diagnostics différentiels » remontent ensemble** dans l'étape ③, juste
  sous la prise en charge (ils étaient dispersés sous la galerie et les documents) ; la carte
  des blocs (SVG) reste repliée en tête de l'étape ② — vue d'ensemble de la phase d'action,
  pas une étape. Galerie, documents, références, voir aussi et note personnelle deviennent
  les annexes de fin de page. En large (≥ 1000 px), minuteurs / posologie / journal restent
  dans la colonne droite collante ; en étroit ils vivent dans l'étape ②.
- **Bandeau « Ne pas oublier » long** : au-delà de 4 rappels, passage en **2 colonnes**
  ≥ 780 px pour contenir la hauteur du chapeau — jamais de repli ni de troncature (un rappel
  caché n'existe plus) ; une colonne en étroit et au zoom 400 % (reflow WCAG 1.4.10). Le
  bandeau reste le chapeau de la fiche, hors numérotation (memory items transversaux),
  visible avant et pendant la session.

## [4.3.2] — 2026-07-14
Micro-animations harmonisées, bouton « Démarrer la session », tri alphabétique par défaut,
et correctifs d'affichage (bandeau de bibliothèque partagée, contraste de la barre latérale,
scroll perdu au premier cochage).

### Ajouté
- **Bouton « ▶ Démarrer la session »** dans la vue lecture d'une aide cognitive, sous la
  confirmation diagnostique (doctrine QRH : on confirme le tableau, puis on agit). Il lance
  chrono, minuteurs et journal par le même chemin que la première action (`ensureStarted`) —
  laquelle continue de démarrer la session implicitement. Seul bouton `--primary` plein de
  l'écran avant session ; il disparaît dès la session démarrée.
- **Micro-animations cohérentes** (registre unique, aligné Apple HIG / Material 3) : voile en
  fondu + légère levée des fenêtres (`veilIn`/`riseIn`), dépliage ancré du menu ⋯ (`menuIn`),
  entrée du bandeau système (réutilise `cbIn`), fondu court des survols (rangées de la barre
  latérale, menu ⋯, documents), levée adoucie des cartes. Règles de sûreté (aviation/QRH) :
  transform/opacity seulement (compositeur — l'app reste utilisable pendant l'animation),
  **aucune animation de sortie** (fermer = immédiat), aucune boucle hors alarmes, pas
  d'animation d'entrée sur les surfaces re-rendues en session (elles rejoueraient à chaque
  action), visionneuse PDF exclue ; tout est neutralisé sous `prefers-reduced-motion`.

### Modifié
- **La date de validation quitte les CARTES** (elle doublait le badge « ✓ Validée ») : sur
  l'accueil, une carte ne porte plus que le badge de statut ; seul un **dépassement** (validation
  de plus de 2 ans) est signalé par une pastille « △ à revoir » au registre ATTENTION (la date
  exacte reste dans son info-bulle). La vue lecture conserve « Validation : 01/2025 » inchangée.
- **Bandeau « Bibliothèque partagée » supprimé** à l'ouverture d'une bibliothèque partagée :
  l'information vit désormais dans le titre de liste — « Nom de la bibliothèque — partagée
  (· lecture seule le cas échéant) — n aides cognitives / documents » — affiché aussi sur
  l'accueil étroit quand une bibliothèque partagée est ouverte. Le titre de la section
  Protocoles porte lui aussi le nom de la bibliothèque ouverte.
- **Tri alphabétique par défaut** des aides cognitives, des protocoles et du sélecteur
  « Voir aussi » (collation française : accents ignorés, numérique naturel — « Bloc 2 » avant
  « Bloc 10 ») ; les épinglés restent en tête. Remplace le tri par récence (`order`, conservé
  dans le modèle pour la compatibilité). Fonction `byTitle` exposée au mode test et couverte
  par tests.html.
- **Pied de page synthétisé** (bas de la barre latérale) : la ligne de stockage devient
  compacte — « ☁ Cloud · 3 Mo sur l'appareil », « Cet appareil seulement · 3 Mo · copie
  unique / non protégé » — le message de sécurité complet reste dans l'info-bulle et la
  fenêtre « Où sont enregistrées vos fiches ? » (inchangées).

### Corrigé
- **Scroll perdu au premier cochage** : cocher la première étape (= démarrage de session)
  re-rendait la vue avec « Confirmation diagnostique » repliée — le contenu remontait et le
  point de tap était perdu. L'état d'ouverture du bloc est désormais figé au démarrage de la
  session (`ensureStarted`) ; le repli par défaut ne vaut plus que pour une session reprise.
- **Contraste de la barre latérale (WCAG 2.2 AA)** : sur une rangée de bibliothèque
  sélectionnée (fond bleu système), le sous-texte « La vôtre · lecture-écriture » /
  « Partagée · rôle » gardait son encre douce (contraste insuffisant) — il hérite désormais
  de l'encre inversée (opacité .92, ≥ 4.5:1 sur tous les accents), comme le compte d'éléments.

## [4.3.1] — 2026-07-13
Correctifs mobile (fiabilité des taps, taille du texte sur iPhone) et harmonisation des
confirmations destructrices sur le registre du dialogue « Terminer la session ».

### Modifié
- **États vides → dialogue Créer** : sur un accueil vide, « Créer un protocole » et le bouton
  de création de fiche ouvrent désormais le dialogue « Créer » (mêmes méthodes — Manuellement,
  Avec l'IA, Importer un fichier .json — que le bouton « ＋ Créer » de l'en-tête), au lieu de
  sauter directement dans l'éditeur.
- **« Créer une fiche » renommé « Créer une aide cognitive »** (bouton d'appel à l'action de
  l'accueil vide), aligné sur le vocabulaire du reste de l'app.
- **Confirmations destructrices au registre « Terminer la session »** : dans la fenêtre de
  confirmation (`confirmDlg`), le bouton principal d'une action destructrice (supprimer une
  fiche, un protocole, la bibliothèque, une session, retirer un membre…) est désormais **rouge
  plein `--critical-bd` + texte blanc**, comme « Terminer » du dialogue de fin de session. Les
  boutons « Supprimer » de fin de formulaire et des zones sensibles restent en contour (le
  rouge plein est réservé à la confirmation finale).

### Corrigé
- **iPhone — taille du texte sans effet sur le texte** : dans « Compte & synchronisation »,
  changer la taille (S/M/L/XL) agrandissait les cadres mais pas la police. Cause : le `zoom`
  CSS posé sur `<html>` n'agrandit pas le texte sur iOS/iPadOS quand
  `-webkit-text-size-adjust:100%` (anti font-boosting) est actif — ce réglage recale chaque
  texte à sa taille spécifiée. Correctif : sur iOS uniquement, `-webkit-text-size-adjust` est
  aligné sur le pourcentage de zoom choisi.
- **iPhone — taps « ignorés » dans « Modifier la bibliothèque »** : le sélecteur de rôle
  (Lecteur/Éditeur/Admin) et les boutons voisins ne répondaient pas toujours. Deux causes
  traitées : (1) champs et menus de cette fenêtre en 12.5–13.5 px — sous 16 px, Safari iOS
  **zoome automatiquement la page au focus** et le tap semble perdu (16 px sur écrans
  tactiles) ; (2) délai du double-tap zoom — `touch-action:manipulation` posé sur tous les
  contrôles (boutons, champs, menus) de l'app. Le bouton « retirer le membre » (×) reçoit un
  halo portant sa cible tactile à 44 px.
- **Fenêtre Compte — boutons jumeaux inégaux sur mobile** : « Exporter mes données » et
  « Se déconnecter » n'avaient pas la même taille en étroit (le libellé le plus long élargissait
  son bouton, et pouvait le rehausser en passant sur deux lignes). Les jumeaux demi-largeur
  (`.dlg-actions`) partagent désormais la largeur à parts égales et s'étirent à la même hauteur.

## [4.3.0] — 2026-07-13
Code couleur des catégories unifié (SPEC crise §1), sélecteur de catégorie « une sélectionnée
+ Autre… » (§2), dialogue « Terminer la session ? » (§3), marqueurs d'étapes sortis du champ
texte, indicateur de mode dans les éditeurs.

### Ajouté
- **Sélecteur de catégorie « une sélectionnée + Autre… »** dans les deux éditeurs : le
  formulaire n'affiche plus que la décision prise (chip teinté qui prévisualise liseré et
  pastille) et la porte de sortie « Autre… » — menu ancré au patron du menu ⋯ (rangées 44 px
  pastille + nom + ✓ sur la courante, champ de filtre au-delà de 8 catégories, « ＋ Nouvelle
  catégorie » en pointillé qui ouvre le gestionnaire sans perdre le brouillon), **bottom
  sheet** avec poignée et voile sous 780 px. Listbox ARIA (flèches, Entrée, Échap). Remplace
  la rangée de toutes les catégories (largeur non bornée, faux air de choix multiple).
  Correction au passage : fermer le gestionnaire de catégories re-rend désormais aussi
  l'éditeur de protocole.
- **Dialogue « Terminer la session ? »** : seule porte de sortie d'une session (menu ⋯, fin
  d'algorithme, ✕ du bandeau SESSIONS EN COURS — jamais d'arrêt direct). Il annonce le
  **contexte** (titre de la fiche + durée) puis les **conséquences avant le choix** (chrono et
  minuteurs stoppés, session retirée de l'accueil, déroulé conservé dans l'historique) ;
  « Poursuivre » = action sûre (contour, focus initial, Échap) ; « Terminer » = rouge système
  plein — l'un des seuls de l'app. Terminer depuis l'écran de crise ramène à l'accueil.
- **Indicateur de mode des éditeurs** : « ÉDITION/CRÉATION — AIDE COGNITIVE/PROTOCOLE » en
  micro-titre permanent dans la barre (11 px/800, encre douce — informe, n'alerte pas),
  tronqué au mode seul en étroit ; le **badge de statut ne disparaît plus jamais** (il
  s'ellipse, plancher 40 px ; thème et compte s'effacent à sa place sous 640 px, « Aperçu »
  passe en icône ⛶ sous 430 px). Pas de barre d'actions flottante en bas (une seule zone
  fixe — en haut ; clavier mobile ; Supprimer reste isolé en fin de formulaire).
- **Bascule ⚠ sur les repères posologiques** : le signe étant intapable au clavier, chaque
  ligne porte le même bouton que les étapes (carte rouge en lecture).

### Modifié
- **Code couleur des catégories (règle unique, partout)** : la couleur choisie par
  l'utilisateur n'apparaît qu'en **pastille** (`.cat-dot` ronde à anneau), **liseré** de carte
  (ramené de 8 à 4 px) ou **teinte ≤ 15 %** avec texte de la couleur — jamais en aplat saturé
  (réservé aux états système), jamais seule (toujours le nom en toutes lettres). La
  **sélection** (rangées de la sidebar, chips mobiles) passe au **bleu système** — plus de
  chips remplis de la couleur de catégorie ni de pilule noire « Toutes » ; la pastille reste
  lisible sur le bleu grâce à son anneau. Le bandeau MODE CRISE ne porte pas la couleur de
  catégorie (rouge système).
- **Marqueur d'étape sorti du champ texte** (éditeur) : le préfixe ⚠/△ ajouté par la bascule
  apparaissait DANS le champ — l'effacer à la main changeait le type par accident. Le champ
  affiche désormais le texte nu, la rangée est **encadrée à la couleur du registre** (bordure,
  fond doux, numéro coloré) et le préfixe est re-posé par le code à chaque frappe (la chaîne
  stockée le garde : exports v3 et anciens clients inchangés).

## [4.2.2] — 2026-07-13
Étapes : doctrine rouge/ambre affichée, gras retiré, chiffres plus lisibles ; références sur
les protocoles ; prompt IA actualisé.

### Corrigé
- **Étape vigilance (ambre) invisible dans l'« Aperçu en direct »** de l'éditeur : la colonne
  d'aperçu ne traitait que les étapes critiques (rouges) — une étape `△` s'y affichait comme
  une étape normale. Elle apparaît désormais au registre ATTENTION (fond et texte ambre),
  comme en lecture.

### Ajouté
- **Consigne d'usage rouge/ambre dans l'éditeur de blocs** (affichée au-dessus des étapes, là
  où se prend la décision) : **rouge** = ce qui tue si on l'oublie (memory item, geste vital) ;
  **ambre** = là où l'on risque de se tromper (dose/dilution à vérifier avant injection,
  contre-indication à écarter, confusion voie/site/produit, seuil à contrôler avant de
  poursuivre) ; une étape des deux registres → rouge. Les infobulles du bouton ⚠/△ reprennent
  la doctrine, ainsi que le prompt IA et AGENTS.md.
- **Références sur les protocoles** : même section « Références » que les aides cognitives —
  liste dans l'éditeur (sous le contenu rédigé), affichée en bas de la lecture, indexée par la
  recherche. Champ facultatif, export v3 inchangé (un ancien client l'ignore).

### Modifié
- **Gras retiré des étapes** (bouton « B » et raccourci Ctrl/Cmd-B) : le texte des étapes est
  déjà affiché en gras — un **fragment** y était invisible ; le relief d'une étape passe par
  son TYPE (rouge/ambre). Le gras reste disponible dans les listes (À vérifier, Ne pas
  oublier, Repères posologiques…) ; l'ancien contenu contenant `**` reste rendu (compat).
- **Chiffres des étapes** (mode crise) : 14 → 16 px et **centrés verticalement** sur l'axe de
  la case à cocher — le numéro est l'ancre de suivi de position de la lecture à voix haute
  (challenge-response, logique QRH) ; il reste en encre douce pour ne pas concurrencer le
  texte, et suit les registres rouge/ambre/coché.
- **Prompt IA actualisé** : le gras y est désormais exclu des étapes (réservé aux listes) ;
  la doctrine rouge/ambre ci-dessus remplace l'ancienne définition du `△` ; nouvelle règle —
  **ne jamais générer de chronomètre « Temps écoulé »** (l'app affiche déjà un chrono global
  de session qui démarre à la première action), un `stopwatch` ne servant qu'à une durée
  spécifique explicitement demandée par la source (garrot, no-flow…) ; l'exemple du schéma
  est corrigé en conséquence. Déjà à jour et vérifiés : `code`, types d'étapes ⚠/△, repères
  posologiques.

## [4.2.1] — 2026-07-13
### Corrigé
- **App tronquée à droite sur certains navigateurs** : sur les navigateurs à barres de
  défilement classiques (Windows/Linux — pas macOS/iOS, d'où le « certains »),
  `scrollbar-gutter: stable` posé sur `html` réservait ~15 px à droite **en permanence**, même
  quand rien ne défile (accueil = coque fixe, fiche courte) : l'en-tête, le bandeau MODE CRISE
  et tout le contenu s'arrêtaient avant le bord de la fenêtre — alors que les éléments fixes
  (tab bar, notifications) allaient, eux, jusqu'au bord. La réservation est retirée de `html` ;
  l'anti-décalage qu'elle assurait (bascule Aides ↔ Protocoles) est déplacé **dans les panneaux
  défilants de l'accueil large** (`.home-side`/`.home-main`), seul endroit où il agit encore
  depuis la coque fixe V5. Vérifié : l'app atteint désormais exactement le bord droit à toutes
  les largeurs, sans débordement horizontal.

## [4.2.0] — 2026-07-13
Liens croisés « Voir aussi », alarmes de minuteur au standard aviation (QRH/ECAM), thème
accessible en mode crise.

### Ajouté
- **Liens croisés « Voir aussi »** : une aide cognitive OU un protocole peut désormais être lié
  aux deux (et plus seulement des fiches). Le choix se fait dans un **sélecteur filtrable au
  même design que « Joindre un document existant »** (icône par nature — feuille = aide,
  livre = protocole —, nature en 2ᵉ ligne, code en colonne droite), commun aux deux éditeurs ;
  il remplace l'ancien menu déroulant. En lecture, la section s'appelle « Voir aussi » partout
  (fiches ET protocoles), chaque raccourci porte l'icône de sa nature et ouvre la bonne vue.
  Compatibilité : `related` reste un tableau d'ids (export v3 inchangé) — un ancien client
  ignore simplement les ids de protocole qu'il ne résout pas. Même périmètre uniquement
  (Perso ou même bibliothèque), comme les documents partagés.

### Modifié
- **Alarme de minuteur en mode crise — règle QRH/ECAM** : un minuteur qui arrive à échéance ne
  **déplace plus jamais le contexte de travail** quand la session est sous les yeux — plus
  d'ouverture automatique du panneau minuteurs (qui décalait la checklist en cours de lecture),
  plus de banderole jaune par-dessus l'écran de travail. À la place : bip/vibration + flash
  bref (l'attention, façon *master caution*), puis un **segment ambre persistant** dans la
  barre de minuteurs de l'en-tête — le minuteur échu y reste affiché « 00:00 » tant qu'il n'est
  ni relancé ni réarmé (l'acquittement passe par l'action, pas par un « OK » de plus). La
  banderole cliquable, le flash écran et la notification système sont **réservés à la session
  hors de vue** (autre vue, autre fiche, app en arrière-plan) : là, l'alerte doit être routée.
- **Bouton thème en mode crise (mobile)** : il reste visible pendant une session (retour sur la
  v4.1.2 — décision : la luminosité ambiante change pendant une intervention, extérieur/
  intérieur) ; seule la pastille de compte s'efface. Les intitulés de minuteurs s'ellipsent un
  peu plus tôt (< 430 px) pour que barre + thème + menu ⋯ tiennent ensemble sur 375 px.

## [4.1.2] — 2026-07-13
Correctifs d'affichage et retouches de design, surtout sur mobile.

### Corrigé
- **Fenêtre « Modifier la bibliothèque »** : Annuler / Enregistrer remontent **sous le champ
  Nom** (ils ne portent que sur lui) au lieu de suivre la liste des membres — placés en bas,
  ils laissaient croire qu'un ajout ou un retrait de membre devait être « enregistré », alors
  que ces changements s'appliquent immédiatement (précisé aussi dans la légende des rôles).
  Les messages du renommage s'affichent désormais sous le champ Nom, ceux des membres restent
  sous la rangée d'invitation.
- **Minuteurs de l'en-tête sur mobile** : un intitulé de minuteur long poussait le temps hors
  du cadre (coupé net) sur les écrans < 430 px — l'intitulé s'ellipse à nouveau (« ● Session »
  reste toujours entier) et les segments se resserrent. En complément, pendant une session de
  crise sur écran étroit, les boutons **thème** et **compte** s'effacent de la barre (inutiles
  en pleine prise en charge, accessibles partout ailleurs) : toute la place revient aux
  minuteurs. Le menu ⋯ reste.
- **Badge d'état fantôme dans l'en-tête** : après « Enregistrer » dans l'éditeur, le badge
  « ✓ Validée · auto-enregistré » survivait au retour en lecture de la fiche — redondant avec
  la pastille de statut du haut de page et envahissant sur mobile. L'en-tête masque désormais
  son badge à chaque rendu ; seules les vues qui en déclarent un (éditeurs, lecture de
  protocole, aperçus) le réaffichent.

### Modifié
- **Tab bar basse de l'accueil (mobile)** : hauteur réduite (~72 → ~55 px hors encoche) —
  boutons 44 px (cible tactile minimale conservée), paddings resserrés.
- **« Supprimer mon compte et mes données »** (et « Supprimer cette demande de compte ») :
  même grammaire destructrice que « Supprimer la bibliothèque… » — zone sensible avec bouton
  **contour rouge**, à la place de l'ancien lien discret (`.auth-danger` retiré).
- **Bouton thème de l'en-tête** : rond (40 px) en format compact sans libellé, comme le bouton
  Créer — il était ovale ; la forme pilule revient avec le libellé (≥ 780 px).
- **Dialogue « Créer » (aide ET protocole)** : icônes des cartes remplacées par des **icônes
  SVG uniformes 26 px** (crayon, étincelles, import, reprise de brouillon) — les anciens
  glyphes texte ✎ ✦ ⤓ ↺ rendaient à des tailles inégales selon la police du système.
- **Fenêtre « Où sont mes fiches ? »** mise à jour des évolutions V5 : le conseil d'export
  pointe vers « Compte → Exporter mes données » (l'ancien bouton « Exporter tout » du pied de
  page n'existe plus) et mentionne le chemin d'import (dialogue Créer). Mêmes corrections dans
  la fenêtre de bienvenue et deux messages d'erreur qui citaient encore « Exporter tout ».
- Lanceur de tests : variable `AC_CHROMIUM` pour pointer un Chromium déjà installé
  (environnements distants/CI sans téléchargement Playwright).

## [4.1.1] — 2026-07-12
Correctifs et nettoyage issus d'un audit complet (code mort, duplication, sécurité, PWA/perf).
Aucun changement de comportement visible : mêmes écrans, mêmes données.

### Corrigé
- **Droits perdus en cours d'utilisation** (rétrogradé lecteur ou retiré d'une bibliothèque
  pendant que l'app est ouverte) : une modification locale non poussée d'une bibliothèque où
  l'on ne peut plus écrire divergeait en silence pour toujours (jamais poussée, jamais
  réconciliée, pastille verte). Désormais : la modification est **copiée dans « Perso »**
  (rien ne se perd), la copie partagée **revient à la version de l'équipe** (ou disparaît si
  l'on n'est plus membre), et l'utilisateur est **prévenu**. Une suppression bloquée est
  annulée (version de l'équipe restaurée). En complément, l'ouverture de l'éditeur d'une
  fiche/protocole **partagé** revérifie le rôle auprès du serveur quand on est en ligne.
  Rappel : il n'y a pas de synchro périodique — droits et contenus se rafraîchissent au
  démarrage, après chaque écriture locale, au retour au premier plan et au retour en ligne.
- **Fuite d'écouteurs de l'aperçu d'édition** : un écouteur `input` s'empilait sur `#main` à
  chaque ouverture d'éditeur — un seul est désormais posé (les frappes ne déclenchaient plus,
  après plusieurs éditions, qu'un seul aperçu au lieu de N).
- **Service worker** : le handler de navigation ne met plus en cache que la page de l'app —
  visiter `tests.html` ou une fiche de `design/` ne peut plus remplacer la copie hors-ligne.
- **Défense en profondeur du mini-Markdown** : liens et images nettoyés au point d'insertion
  (`href`, `safeImg`) — la sûreté ne dépend plus d'un invariant d'ordre.

### Ajouté
- **Réservation d'espace des images** (anti-décalage de mise en page) : chaque image mémorise ses
  dimensions ; `width`/`height` émis en lecture réservent le bon ratio avant décodage, sans
  jamais déformer un schéma. Import ancien sans dimensions : inchangé.
- **Manifest** : `orientation` portrait, `categories`, `dir` — fiche d'installation plus complète.

### Modifié
- **Recherche transverse à toutes les bibliothèques** : dès qu'on tape une recherche, elle porte
  sur la bibliothèque perso ET toutes les bibliothèques partagées accessibles (plus seulement
  celle affichée) ; chaque résultat porte une pastille indiquant sa bibliothèque (si l'on a des
  bibliothèques partagées). Les brouillons restent masqués là où l'on n'a pas le droit d'éditer.
  Sans recherche, la navigation par bibliothèque/catégorie est inchangée.
- **Correctifs mobile** : la loupe de la recherche ne chevauche plus le placeholder ; le crayon ✎
  d'édition de bibliothèque ne déborde plus de la chip et réagit au tap.
- **Facteur commun fiche/protocole** : sanitisation des entités (`sanitizeEntityCommon`), en-tête
  et sortie des éditeurs mutualisés — une évolution ne peut plus diverger d'un seul côté.
- `render()` allégé (chrome d'en-tête extrait dans `applyViewChrome`) ; `renderLibrary` renommée
  `renderFiches` (elle rend les fiches, pas les bibliothèques).

### Supprimé
- Code mort : `timeAgo()`, variable `_rtShow`, 17 règles CSS orphelines (vestiges des
  remplacements V5). Chaîne de build `dist/` retirée (dossier, `build-dist.mjs`, `terser`) : le
  dépôt est la seule forme servie.

### Sécurité
- **CSP durcie** : `release.sh` calcule les hashs SHA-256 des scripts inline
  (`scripts/csp-hashes.mjs`) et les injecte dans la CSP (`<meta>` + `_headers`). Sur navigateur
  récent (CSP 2+), `'unsafe-inline'` est ignoré et seuls ces scripts s'exécutent : un `<script>`
  ou un handler `on*=` injecté est bloqué (repli `'unsafe-inline'` conservé pour les très vieux
  navigateurs). `style-src 'unsafe-inline'` demeure (attributs `style=` non hachables). Risque
  résiduel restant documenté (`docs/deploiement-et-conformite.md` § 1.1 : jetons Supabase en
  `localStorage`, discipline `esc()`).

### Documentation
- `CHANGELOG.md` allégé : les versions 3.x déplacées dans `CHANGELOG-archive.md` (rien de
  fusionné ni perdu — le journal courant ne garde que le 4.x). Références mortes purgées
  (`dist/`, `renderLibrary`) dans AGENTS.md, README, kit de déploiement et `design/`.

## [4.1.0] — 2026-07-12
Version consolidée : intégration complète du design Claude Design « V5 Explorations » et des
spécifications écrites qui l'ont suivi (largeurs, écrans de gestion, mode crise, dialogue
bibliothèque), plus l'audit UX/ECAM/WCAG appliqué. Remplace les versions locales 4.0.4 → 4.4.1,
jamais publiées, écrasées en une seule entrée.

### Ajouté
- **Écrans de gestion** : dialogue « Créer » (3 méthodes — rédiger, avec l'IA, importer un
  fichier ; tout import par ce dialogue arrive en Brouillon ; carte « Reprendre le brouillon ») ;
  **menu ⋯** en lecture (Modifier, Versions, Dupliquer, Exports, Historique des sessions en
  modale, « Terminer la session… » — remplace les barres d'autorat et le bandeau session) ;
  **auto-enregistrement des brouillons** (store meta `draftpark`, fantôme restaurable,
  « ‹ Retour » remplace « Annuler ») ; dialogue bibliothèque unifié (membres + zone sensible).
- **Mode crise V5** : bandeau TITRE au registre ALERTE (« ■ MODE CRISE »), minuteurs segmentés
  dans la barre à toutes les largeurs + chrono GLOBAL « ● Session », rail droit ≥ 1000 px,
  cartes minuteur refondues (état TEXTUEL, barre 4 px du temps restant, échu = ambre,
  « ↺ durée »), **minuteurs ad hoc** (`extraTimers`), compteur lié (`counters[].timerId`),
  bouton Continuer à 2 états (destination annoncée, champ `nextLbl`), confirmation diagnostique
  = condition d'entrée visible hors session, colonne de contenu au canvas (SPEC-crise).
- **Statuts 3 états** (validé / à relire / brouillon, pilule achromatique unique), champ `code`
  court indexé, étapes critiques « ⚠ » et vigilance « △ », section « Repères posologiques »,
  aperçu d'édition en direct (colonne ≥ 1000 px).
- **Couleur d'accent par utilisateur** (5 nuances AA + bleu clinique, connecté seulement :
  accueil entier + en-têtes ; le contenu clinique reste bleu) ; préférences par utilisateur
  (thème + taille du texte + accent) synchronisées via `data.prefs`.
- Fenêtre Compte restructurée (gabarit dlg-480, « synchronisé à HH:MM », zones Cet appareil /
  Administration / Zone sensible, avatar en initiales de l'e-mail).

### Modifié
- **Palette V5 « bleu clinique »** et tokens (trois rouges distincts, `--ok` confirmation,
  `--soft` décoratif seulement, `--done-*`/`--tag-*`/`--link`/`--verify-bd`) ; taxonomie des
  notices à 5 registres ; nouveau logo (bouclier + tracé ECG) ; icônes SVG harmonisées.
- **Largeurs fermées par vue** (breakpoints 430→1200) : accueil = sidebar 255 px sur coque FIXE
  + grille ≤ 1320 px ; fiche ≤ 860 px + rail 320→360 px ; protocole ≤ 780 px ; éditeurs alignés
  sur leur lecture + aperçu sticky 360 px. Pied de page nomade en bas de la sidebar de
  l'accueil ; export via la fenêtre Compte, import via le dialogue Créer.
- **Audit ECAM/WCAG appliqué** : contrastes (texte secondaire `--ink-soft`, champs/cases
  `--line-strong`), plancher typographique 11 px, garde 700 ms anti double-tap sur les retours
  empilés, halos tactiles 44 px, cartes d'accueil sobres (pilule de catégorie neutre, couleur
  au liseré seul), impression qui déplie les sections repliées.
- Docs consolidées : la spécification des largeurs vit dans AGENTS.md (le fichier
  `docs/SPEC-largeurs.md` est supprimé) ; export Design System (`design/`) régénéré.

### Supprimé
- **Chaîne de build `dist/`** (dossier, `scripts/build-dist.mjs`, dépendance `terser`, étape 6
  de `release.sh`) : le dépôt est la seule forme servie — l'entre-deux « build optionnel
  jamais déployé » était le pire des deux mondes.


## [4.0.3] — 2026-07-11
Lot de cohérence issu de l'audit design v4 (registres visuels, saillance, accessibilité).

### Modifié
- **Les protocoles parlent la même langue visuelle que les fiches.** Les titres de section du
  contenu rédigé (`#`, `##`) reprennent le registre des en-têtes de section des fiches (petites
  capitales grasses espacées) au lieu d'un simple gras : une seule grammaire de titres dans
  toute l'app, en lecture comme dans l'aperçu de l'éditeur.
- **Le titre n'apparaît dans la barre d'en-tête qu'au défilement** (fiches et protocoles,
  lecture et édition). En haut de page, le corps affiche déjà le titre : la barre garde la
  marque, puis bascule sur « titre + nature du contenu » une fois le titre du corps sorti de
  l'écran — le motif « grand titre » d'iOS, déjà utilisé par l'accueil, appliqué entièrement.
  Hauteur de barre inchangée entre les deux états ; plus jamais deux titres affichés à la fois.
- **Un seul bouton rempli par écran.** Quand l'accueil affiche « Reprendre » (session en cours,
  teal plein), « Créer » — action d'autorat, rare en situation d'urgence — passe en ton doux ;
  il reste plein quand aucune session n'est affichée. Règle notée dans AGENTS.md.
- **« Validation : MM/AAAA »** remplace « Validée MM/AAAA » : le même libellé sert aux fiches
  (féminin) et aux protocoles (masculin), l'accord unique était fautif pour l'un des deux.
- **Doc — sémantique du vermillon régularisée** (`:root` + AGENTS.md) : `--critical` couvre la
  destruction **et l'arrêt d'un processus vivant** (« Terminer » une session stoppe les
  minuteurs — registre du rouge « raccrocher ») ; le bouton, volontairement vermillon, n'est
  plus une exception à la règle.

### Corrigé
- **Cartes de liste accessibles au lecteur d'écran.** La carte entière était un « bouton »
  contenant d'autres boutons (épingle, badge « À compléter ») — structure proscrite (ARIA).
  Le titre est désormais le vrai bouton, sa zone de tap étendue à toute la carte ; épingle et
  badge restent des commandes indépendantes, au clavier comme au doigt. Aucun changement visuel.
- **Pastilles de catégories : zone de tap portée à ~44 px** (halo invisible autour de chaque
  pastille, filtres de l'accueil et choix de catégorie des éditeurs) — taille visuelle inchangée.

## [4.0.2] — 2026-07-11
### Corrigé
- **Synchronisation : certains contenus n'arrivaient jamais sur un appareil déjà synchronisé**
  (constaté sur des protocoles, mais valable pour les fiches). Le rattrapage incrémental ne
  demandait au serveur que les lignes **plus récentes que la dernière synchro** ; or deux cas
  réels produisent des lignes « dans le passé » : du contenu créé **avant votre adhésion** à une
  bibliothèque partagée (l'accès le révèle d'un coup, avec ses dates d'origine), et un appareil
  à l'**horloge en retard** (l'horodatage vient de l'appareil qui enregistre). Ces contenus
  n'apparaissaient qu'en repartant de zéro (nouveau navigateur) — même la synchro manuelle ne
  les ramenait pas. Chaque synchro effectue désormais un **repêchage de complétude** : un
  inventaire léger (identifiants + dates) de tout ce qui est visible, puis récupération ciblée
  des seules lignes manquées, appliquées avec les mêmes règles qu'avant (la version la plus
  récente gagne, une saisie locale plus fraîche n'est jamais écrasée).

### Modifié
- **Barre d'en-tête harmonisée entre fiches et protocoles en lecture.** Un protocole ouvert
  affichait « Protocole » sous son titre, mais une fiche ouverte n'affichait rien sous le sien.
  La lecture d'une fiche porte désormais le libellé « Aide cognitive » au même endroit — les
  deux barres ont la même structure (titre + nature du contenu). Le bandeau teal reste dédié à
  l'état (mode crise, session en cours) et ne change pas.

## [4.0.1] — 2026-07-11
### Corrigé
- **Titre dans la barre d'en-tête : comportement unifié entre fiches et protocoles, lecture et
  édition.** En lecture de protocole, le titre s'affichait en petite troisième ligne sous
  « Aides cognitives / Protocole » et se retrouvait **coupé par le bas de la barre** (rangée
  d'identité plafonnée à 44 px) ; en édition (fiche comme protocole), aucun titre n'apparaissait.
  Désormais, dans toute vue fiche/protocole, le titre **remplace la marque** sur une seule ligne
  ellipsée à l'échelle du titre d'accueil (17 px), avec le libellé « Protocole » ou « Édition »
  dessous — même géométrie qu'avant, la hauteur de barre ne change pas. En édition, le titre de
  la barre **suit la saisie en direct** dans le champ « Titre » ; champ vidé, la marque revient
  (création d'une nouvelle fiche). Le mode crise est inchangé (même motif, désormais partagé).

## [4.0.0] — 2026-07-09
### Ajouté
- **Documents PDF joints aux fiches.** Chaque fiche peut porter jusqu'à 10 PDF (15 Mo max
  chacun : protocoles de service, recommandations…), ajoutés depuis l'éditeur (le contenu du
  fichier est vérifié, pas seulement son extension) et lisibles hors ligne. Un document peut
  être **partagé entre plusieurs fiches/protocoles du même périmètre** (« Joindre un document
  existant ») : le remplacer le met à jour partout, il n'est supprimé que quand plus rien ne le
  référence. Les PDF sont stockés en Blob natif dans IndexedDB (jamais en base64 dans la fiche)
  et n'alourdissent pas l'export JSON (seules leurs métadonnées y figurent). Le binaire est
  stocké en ArrayBuffer (fiable sur tous les navigateurs, y compris Safari/iOS où le stockage
  de Blob dans IndexedDB a des bugs connus) ; en cas de problème, la visionneuse distingue
  clairement « composant non téléchargé » (hors-ligne avant première utilisation) de
  « fichier endommagé ».
- **Visionneuse PDF intégrée, toutes pages, tous appareils.** Lecture dans l'app (iPhone, iPad,
  Android, ordinateur) : défilement de toutes les pages, zoom −/+/Largeur, plein écran, Échap
  pour fermer. Rendu par pdf.js **vendorisé** (`vendor/pdfjs`, version figée 4.10.38, précaché
  par le service worker → fonctionne hors ligne dès l'installation, chargé paresseusement →
  aucun coût au démarrage) : **exception unique et documentée à la règle zéro-dépendance**
  (AGENTS.md). Rendu virtualisé (les pages éloignées de l'écran sont libérées : un long PDF ne
  sature pas la mémoire d'un iPhone).
- **Synchronisation cloud des documents.** Bucket privé Supabase Storage avec politiques RLS
  strictes : le chemin encode le périmètre (`u/<compte>/…` personnel — propriétaire approuvé
  seul ; `l/<bibliothèque>/…` partagé — lecture pour tout membre, écriture éditeur/admin),
  plafonds de taille et de type appliqués par le serveur, aucun accès sans session. Les
  documents manquants sont **téléchargés systématiquement** en arrière-plan à la synchro
  (disponibles hors ligne en urgence), déplacements entre bibliothèques et suppressions
  propagés, orphelins listés pour l'app-admin (`list_orphan_attachments`, purge manuelle).
  Nouveaux tests RLS (section 9) : lecture croisée refusée, usurpation de chemin refusée,
  rôles respectés, anonyme sans accès.
- **Nouvelle section « Protocoles ».** Le **titre de la page d'accueil devient le sélecteur**
  dans la barre fixe : « Aides cognitives | Protocoles » en titres à onglets — une ligne de
  base court sous les deux titres et un indicateur ajusté au titre actif glisse de l'un à
  l'autre avec un léger ressort — transition de contenu fluide et jamais bloquante, bascule à
  tout moment, mémorisée par compte. Sépare les aides cognitives de crise des protocoles de
  référence.
  Un protocole = titre, catégorie (jeu partagé avec les fiches), bibliothèque (perso ou
  partagée), date de validation, état brouillon/validé, **un ou plusieurs PDF** et/ou un
  **contenu rédigé dans l'app**. Recherche plein texte, export/import JSON (champ
  rétrocompatible), synchronisation cloud complète (table `protocols`, mêmes politiques RLS
  que les fiches — tests section 10).
- **Contenu rédigé en mise en forme simple (mini-Markdown maison, sans dépendance).** Titres
  (`#`/`##`/`###`), listes à puces et numérotées avec **sous-listes** (2 espaces d'indentation),
  **citations** (`>`), **code** en ligne et en bloc (```` ``` ````), séparateur (`---`),
  **gras**, *italique*, liens web, liens vers un PDF joint, images intégrées (réduites et
  stockées hors ligne). Éditeur avec barre d'outils (B, I, H2, H3, listes, citation, code,
  lien, image) et aperçu en direct. Rendu sûr par construction (échappement d'abord,
  `javascript:` et identifiants hostiles refusés, aucun balisage interprété dans le code —
  testés) ; balisage non reconnu laissé visible, le rendu ne casse jamais.
- **Recherche transversale.** La recherche de l'accueil évalue aussi la requête sur l'autre
  section : un bloc discret « N protocoles correspondent aussi à cette recherche » (et
  inversement) bascule de section en conservant la recherche — en urgence, pas besoin de se
  souvenir d'où vit un contenu.

### Modifié
- **En-tête clair (inversion) + identité d'accueil.** La barre fixe prend la couleur du fond de
  page (hairline de séparation), le teal se retire dans les **accents**. L'accueil retrouve la
  **ligne d'identité** « Aides cognitives » + compte, avec en dessous la rangée d'onglets
  « **Aides | Protocoles** » (la section est renommée pour lever le doublon avec le nom de
  l'app). Le **mode crise** ne recolore plus la barre : il s'annonce par un **bandeau d'état
  étiqueté** sous la barre (« Mode crise · session en cours… », pattern des systèmes
  critiques — texte + couleur + position), le titre de la fiche gardant l'emplacement et le
  corps du titre d'accueil ; le **rappel minuteurs y est fusionné** (chrono compact cliquable à
  droite du bandeau — un seul bloc d'état, apparition en fondu discret jamais bloquant). Sur
  l'accueil, la **ligne d'identité se replie au défilement** (pattern grand titre : espaces
  confortables en haut de page, barre minimale en navigation). Propagé partout : bouton Compte
  et pastille d'état, thème sombre, couleur de la barre d'état système.
- **Base locale IndexedDB v4 → v5** (stores `attachments` et `protocols`). Migration
  automatique et silencieuse ; si un vieil onglet de l'app bloque la mise à jour du stockage,
  un message invite à le fermer (au lieu d'un repli silencieux vers une bibliothèque vide).
- La jauge de stockage indique le poids des documents PDF ; le tableau de bord app-admin
  affiche protocoles et poids du bucket ; le message d'erreur « contenu trop volumineux »
  couvre les documents.
- Chrome de l'accueil (sélecteur de section, barre de bibliothèques, catégories, recherche)
  et composants Documents **factorisés** entre fiches et protocoles (aucune logique dupliquée).
- **Correctifs de l'audit design 4.0.0** (conformité WCAG 2.2 AA + cohérence des palettes) :
  - **Pastilles d'état du compte et de la synchro** : couleurs sémantiques qui suivent le thème
    (ok = teal, attente = ambre, erreur = vermillon, inactif = gris) — les anciennes valeurs
    vives, calibrées pour l'en-tête sombre d'avant l'inversion, tombaient à 1,3–2,4:1 sur la
    barre claire (3:1 requis) ; désormais ≥ 3:1 dans les deux thèmes.
  - **Manifest et barre système alignés sur le chrome clair** : `theme_color`/`background_color`
    du manifest et balise `theme-color` initiale = fond de page (plus de barre teal au-dessus
    d'une app claire à l'installation) ; la couleur suit le thème sombre dès avant le premier
    rendu. Le **verrou portrait est retiré** (usage tablette en paysage possible).
  - **Plancher typographique 11 px** (étiquettes du bandeau de crise, indice « maintenir »,
    numéros du fil d'Ariane, badges) et **zones de tap** : chrono du bandeau de crise ≥ 44 px,
    jauge de stockage ≥ 24 px (WCAG 2.5.8).
  - **Palettes dé-dupliquées** : les overrides du thème sombre qui recopiaient des valeurs de
    tokens en hex sont supprimés (les tokens suivent seuls le thème) ; nouveau token
    `--input-bg` pour tous les fonds de champs ; plus aucun style inline sur les pastilles de
    catégorie (classes `.on`/`.mgr` tokenisées) ; le panneau de navigation garde son liseré
    teal en thème sombre (perdu jusqu'ici par un override trop large).
  - **Sémantique** : la marque devient le `h1` du document, les titres de cartes des `h2`
    (plan de titres propre pour lecteurs d'écran) ; le sélecteur de section est un vrai
    `tablist` (flèches ←/→, focus itinérant, `aria-selected`) ; badge « À compléter » souligné
    en pointillés (affordance d'action) ; **bouton « Créer » dans les états vides** ;
    breakpoints consolidés sur une échelle fermée (430/560/640/780/900 px, notée AGENTS.md).

### Sécurité
- Nouveaux garde-fous : `safeAttachment` (id jamais régénéré, entrée invalide rejetée,
  extension `.pdf` garantie même après renommage), `safeFileName`, validateurs du
  mini-Markdown — tous testés (246 tests). Un PDF endommagé affiche un message clair et ne
  bloque jamais la navigation (rendu isolé dans un worker, jamais de code exécuté depuis un
  document). La suppression de compte (RGPD) emporte aussi les protocoles personnels.

### À savoir
- Le schéma serveur doit être re-exécuté (`supabase/schema.sql`) puis validé avec
  `supabase/rls-tests.sql` pour activer bucket et table `protocols`.
- Multi-onglets : si la bibliothèque semble vide après la mise à jour, fermez les autres
  onglets de l'app puis rechargez (migration de la base locale en attente).

## [3.5.5] — 2026-07-09
### Corrigé
- **La barre Enregistrer/Supprimer s'efface pendant la saisie sur téléphone.** Le retrait de
  l'encart bas (3.5.4) ne suffisait pas : selon les navigateurs, un espace résiduel subsistait
  au-dessus du clavier virtuel, et la barre elle-même mangeait un écran déjà réduit de moitié.
  Sur écran tactile, la barre est donc masquée tant qu'un champ de saisie texte a le focus
  (clavier ouvert) et réapparaît dès la fin de la saisie. Sur ordinateur (pas de clavier
  virtuel), elle reste visible pendant la frappe, comportement inchangé.

## [3.5.4] — 2026-07-09
### Corrigé
- **Plus d'espace vide entre la barre Enregistrer/Supprimer et le clavier.** Dans l'éditeur, la
  barre collée en bas conservait son encart `env(safe-area-inset-bottom)` (zone du geste système,
  ~34 px sur iPhone) pendant la saisie : quand la fenêtre est réduite au-dessus du clavier
  virtuel (PWA installée notamment), cet encart s'intercalait en bandeau vide entre les boutons
  et le clavier. L'encart est maintenant retiré tant qu'un champ de saisie texte a le focus
  (clavier à l'écran, il recouvre la zone du geste système) et rétabli dès la fin de la saisie ;
  sans clavier virtuel (ordinateur), l'encart vaut 0 et rien ne change. Les champs sans clavier
  (cases à cocher, boutons) sont exclus de la détection.

## [3.5.3] — 2026-07-09
### Corrigé
- **Ouvrir une fiche affiche son début.** Après avoir défilé dans la bibliothèque, ouvrir une
  fiche conservait la position de défilement (on arrivait au milieu de la fiche). Le défilement
  est désormais géré par transition de vue : haut de page à l'ouverture d'une fiche (ou au
  changement de fiche via une banderole d'alerte) et à l'entrée en édition ; au retour à la
  bibliothèque, la position de la liste est restaurée là où on en était. Les re-rendus en lecture
  (cocher une étape, minuteurs) ne provoquent toujours aucun saut, usage en crise oblige.

### Modifié
- **Icône « attention » unifiée.** Le triangle arrondi du bandeau « Brouillon » devient le dessin
  unique de l'avertissement : bandeau « Ne pas oublier », toasts, fenêtre de suppression de compte
  et erreurs de synchro l'utilisent désormais via un tracé partagé (`WARN_GLYPH`, servi par
  `uiIcon('warn')`) — plus de SVG dupliqués en dur (quatre copies divergentes supprimées). Dans le
  badge d'en-tête de section (« Ne pas oublier »), le tracé est recentré optiquement pour rester
  aligné avec le titre.

## [3.5.2] — 2026-07-08
### Ajouté
- **Barre de vie des notifications.** Une fine barre en bas des toasts se vide de gauche à droite
  sur la durée d'affichage : on voit d'un coup d'œil quand la notification va disparaître. Elle
  équipe le toast bas d'écran (durée variable selon le message) et la banderole ambre de fin de
  minuteur (10 s). Barre en `currentColor` (contraste garanti sur fond sombre comme ambre, aucune
  nouvelle couleur), purement décorative pour les lecteurs d'écran (`aria-hidden`), durée
  synchronisée avec la temporisation de disparition.

## [3.5.1] — 2026-07-07
### Corrigé
- **Message de mise à jour exact.** Le toast introduit en 3.5.0 annonçait « la nouvelle version
  sera utilisée à la prochaine ouverture » alors que, dans le cas normal (en ligne), la stratégie
  « réseau d'abord » venait déjà de servir le nouvel index.html : l'utilisateur ÉTAIT déjà sur la
  nouvelle version. Le service worker annonce désormais sa version à la page (postMessage à
  l'activation) ; la page la compare à `APP_VERSION` et affiche le bon message — « vous utilisez
  déjà la nouvelle version » (versions égales, cas normal) ou « rechargez la page pour l'utiliser »
  (page encore servie par l'ancien cache hors-ligne).
- Au passage : la file des messages du worker est démarrée explicitement
  (`navigator.serviceWorker.startMessages()`) — indispensable avec `addEventListener`, sans quoi
  les messages restaient en file indéfiniment et aucun toast ne s'affichait. Les deux branches du
  message ont été vérifiées en navigateur.

## [3.5.0] — 2026-07-07
Version issue d'un audit complet (qualité de code, PWA, sécurité, performance). L'audit sécurité
n'a trouvé aucune faille exploitable (échappement et assainissement complets, RLS couvrante).

### Ajouté
- **Notification de mise à jour** : un toast « Application mise à jour » s'affiche quand une
  nouvelle version du service worker s'active — la mise à jour n'est plus silencieuse ; jamais de
  rechargement forcé (l'onglet ouvert continue sur la version en cours).
- **Build optionnel `npm run build`** : produit `dist/` (copie déployable allégée d'~25 %,
  commentaires du code retirés via terser sans aucune transformation du code ; devDependency
  uniquement, le runtime reste sans dépendance). Le dépôt servi tel quel reste le défaut.
- **Manifest** : champ `id` (identité d'installation stable) et icône maskable 192 px
  (`icon-192-maskable.png`, aussi pré-cachée par le service worker).
- **Tests** : couverture directe de `flattenFiche` et de `buildFlowSVG`/`wrapText`
  (structure du SVG, échappement, boucle de décision ambrée pointillée) — 179 tests.

### Performance
- **Démarrage** : les lectures IndexedDB (catégories, fiches, sessions, notes) se font en
  parallèle, et la lecture des fiches faite par le test « base vide ? » est réutilisée au lieu
  d'un second `getAll` complet.
- **Recherche débouncée (150 ms)** : la bibliothèque n'est plus re-rendue à chaque frappe.
- **Rappel minuteurs de l'en-tête** : la géométrie (`getBoundingClientRect`, reflow forcé) n'est
  relue qu'au défilement/redimensionnement/re-rendu, plus toutes les 300 ms.

### Modifié
- **Refactor sans changement de comportement** (vérifié : sortie SVG identique octet pour octet
  sur jeux d'essai, 179 tests, parcours complet en navigateur) :
  `buildFlowSVG` scindé en quatre étapes nommées (`flowMeasure`/`flowPlace`/`flowRoute`/
  `flowNodesSVG`) ; `renderAuth` scindé par écran (suppression, en attente/refusé, connecté,
  connexion) ; `renderRead`/`renderEditor` scindés en gabarit + câblage (`bindReadEvents`,
  `bindEditorEvents`) ; calcul d'affichage des minuteurs unifié (`timerDisplay`, une seule
  formule pour carte/tick/en-tête) ; pastilles de catégorie unifiées (`catChipHtml`) ;
  bandeau « Ne pas oublier » rendu via `staticBlock`.
- **`release.sh` synchronise aussi `package.json`** (bloqué à 3.1.0 depuis plusieurs versions).
- **Docs hébergement** : comparatif explicite GitHub Pages vs Netlify/Cloudflare Pages —
  `_headers` (CSP HTTP, HSTS, `no-cache` sur `sw.js`) n'est appliqué que par ces derniers.
- **CHANGELOG** : les versions 3.0.0 → 3.3.7 sont déplacées dans `CHANGELOG-archive.md`.

### Retiré (code mort, aucun impact visible)
- Helper `textTrunc` jamais appelé ; `ficheNeedsCompletion` (doublon de
  `completionSpots().length`, tests réécrits sur cette dernière) ; classes CSS orphelines
  (`.auth-who`, `.bar-act`, `.fiche-img`, `.h-steps`, `.read-actions`, `.read-img`, `.ro-hint`,
  `.tk-empty`, `.thumb` — dont une règle sombre `filter:brightness(.92)` qui ne ciblait plus
  aucune classe émise depuis un renommage passé ; à réintroduire sur `.gthumb img` si
  l'atténuation des images en thème sombre est souhaitée).

## [3.4.9] — 2026-07-07
### Corrigé
- **Contraste des boutons d'action en thème sombre.** Le texte blanc sur fond `--primary` (devenu
  un teal clair en sombre) tombait à 2,6:1 — illisible sous WCAG AA. Nouveau token `--on-primary`
  (blanc en clair, encre foncée en sombre) appliqué aux boutons primaires, cases cochées et avatar.
- **Minuteurs visibles pendant tout le déroulé des étapes.** Le panneau « Minuteurs & compteurs »
  disparaissait de l'écran dès qu'on descendait dans les étapes cochables ; un bandeau apparaît
  maintenant dans l'en-tête (collant) dès qu'un minuteur tourne et que le panneau est hors champ —
  le temps restant reste toujours lisible, un tap ramène au panneau.
- **L'algorithme (schéma) ne masque plus la première étape.** Il s'affichait déplié par défaut à
  l'ouverture d'une fiche, poussant la première case cochable sous ~700 px de contenu ; replié par
  défaut désormais (reste à un tap via « Voir l'algorithme »), déplié à la demande seulement.
- **Cibles tactiles remontées à 44 px** en mode crise et dans les fenêtres : fermeture des
  modales, boutons minuteurs/compteurs/son/réinit., bouton compte de l'en-tête, croix des
  banderoles d'alerte.
- **Bouton Son ambigu** : affichait juste « Son »/« Muet » sans dire si c'était l'état ou l'action.
  Libellé d'état explicite (« Son activé »/« Son coupé », `aria-pressed`), et l'état coupé — un
  choix risqué en crise — passe en ambre pour rester visible.
- **Horodatage du journal des actions** : l'heure cliquable (correction manuelle) n'avait pas
  d'équivalent clavier ; Entrée/Espace fonctionnent désormais.
### Modifié
- **Couleurs consolidées vers les tokens existants** : les rouges « erreur » (4 valeurs), les ors
  « attente/décision » et les teals « identité/temps réel » dispersés en dur convergent vers
  `--critical`, `--verify`, `--live` (nouveau) ; nouveau `--line-hover` unique pour les survols de
  boutons/chips ; l'état « minuteur en cours » passe du chaud (orange, proche de l'alarme) à un
  teal froid — le chaud reste réservé aux alarmes et aux gestes de remise à zéro.
- **Bordures des champs de saisie** relevées à `--line-strong` (contraste composant ≥ 3:1) ;
  `::placeholder` stylé explicitement (n'était pas maîtrisé sur les fonds personnalisés).
- **Wording clarifié** : « Reprendre » (session vive de l'accueil), « Rouvrir » (session archivée
  de l'historique) et « Relancer » (minuteur en pause) ne se recouvrent plus ; « Réinit. » /
  « Recommencer » unifiés en « Remettre à zéro » ; retour de l'éditeur renommé
  « Quitter sans enregistrer » (il jette bien le brouillon en cours).
- **Fil d'Ariane masqué au premier bloc** de la prise en charge (faisait doublon avec le titre du
  bloc sans offrir de retour possible) ; apparaît dès le 2ᵉ bloc visité.
- **Enregistrer (éditeur) collant en bas de l'écran** sur le formulaire, désormais long à faire
  défiler ; pied de page réduit à l'état (masque Exporter/Importer/Thème) pendant une session en
  cours, pour ne pas ajouter de cibles non pertinentes en crise.
- Couleur de catégorie retirée de la palette (`#0d5b56`, identique à `--primary` — une catégorie
  sélectionnée ne doit jamais ressembler à un bouton d'action).
- Ajout d'un lien d'évitement clavier (« Aller au contenu »).

## [3.4.8] — 2026-07-06
### Corrigé
- **Le gras n'éclate plus les lignes des listes de fiche.** Les puces de « Ne pas oublier »,
  « Confirmation diagnostique », « À vérifier » et « Diagnostics différentiels », ainsi que les
  boutons d'option des nœuds de décision, sont des conteneurs flex : un `**gras**` au milieu du
  texte le découpait en plusieurs éléments flex séparés par l'espacement de la puce (espaces
  parasites autour du gras, texte rendu en « colonnes » sur les lignes longues). Le texte formaté
  est désormais toujours enveloppé dans un `<span>` unique (même schéma que les étapes) ;
  suppression au passage du paramètre `forget` de `staticBlock` et de la règle CSS `ul.forget`,
  vestiges jamais utilisés de ce correctif.

## [3.4.7] — 2026-07-06
### Modifié
- **Un seul bouton « Se déconnecter » dans la fenêtre Compte.** « Changer de compte » faisait
  exactement la même chose (déconnexion → écran de connexion, où l'on peut saisir n'importe
  quel e-mail) : la v3.3.5 avait déjà regroupé leurs gestionnaires en un seul point de code,
  les deux boutons visibles n'avaient plus de raison d'être. Le message de confirmation couvre
  le cas « autre compte » (« Vous pourrez ensuite vous reconnecter, ou utiliser un autre
  compte. ») ; retiré des deux écrans (connecté, en attente/refusé).
- **Champ « Saisissez le code » : 8 points.** L'espace réservé des deux saisies de code
  (connexion, suppression de compte) affichait 6 points alors que le code reçu par e-mail
  compte 8 chiffres.

## [3.4.6] — 2026-07-06
### Ajouté
- **Retour des fiches « hors compte » pour un compte non validé.** Les fiches emportées à la
  connexion dans un compte **en attente de validation** ou **refusé** restaient dans l'espace
  local de ce compte : en suivant le conseil « réessayer avec une autre adresse e-mail », elles
  devenaient inaccessibles (aucun chemin d'interface n'y menait plus). Trois chemins de retour,
  réservés aux comptes jamais synchronisés depuis l'appareil (garde `canReturnToAnon`, pure et
  testée : jamais pour un compte déjà synchronisé, dont les ids sont réclamés dans le cloud) :
  - bouton **« Ramener mes fiches hors compte »** sur l'écran Compte (en attente / refusé) ;
  - case « Ramener d'abord les fiches… » dans la confirmation de **« Changer de compte »** et
    **« Se déconnecter »** (nouvelle option `checkSafe` de la fenêtre de confirmation : une case
    protectrice ne peint plus le bouton en rouge) ;
  - retour **automatique** après « Supprimer cette demande de compte » (sans lui, l'espace du
    compte supprimé devenait définitivement orphelin, l'OTP ne fonctionnant plus).
  Le déplacement précède toujours la déconnexion et la bascule d'espace : en cas d'échec, rien
  ne bouge. 6 tests ajoutés (162 tests).

### Modifié
- **Textes honnêtes pour les comptes non validés.** Le dialogue « emporter dans ce compte » dit
  « synchronisées une fois le compte validé, si l'instance exige une validation » (au lieu d'une
  promesse de synchro immédiate) ; l'écran de suppression d'une demande n'évoque plus de
  « bibliothèque synchronisée supprimée du cloud » (rien n'y a jamais été envoyé) et la case
  « Effacer aussi les fiches de cet appareil » avertit qu'elles n'existent nulle part ailleurs.

## [3.4.5] — 2026-07-06
### Modifié
- **Prompt IA : cinq règles ajoutées, tirées de la relecture d'une fiche ACR (ERC 2025) générée
  avec le prompt 3.4.1.** Les défauts observés remontaient à des règles absentes :
  1. *Une étape = un seul moment* : interdiction de fusionner deux temps distincts sur une ligne
     (ex. « après 3ᵉ choc : amiodarone 300 mg ; après 5ᵉ choc : 150 mg ») — cochée au premier
     temps, la case masquait le rappel du second.
  2. *Gestes uniques hors des boucles* : une boucle de réévaluation ne contient que ce qui se
     refait à chaque cycle ; les gestes uniques (accès vasculaire, intubation…) sortent de la
     boucle, sinon l'app les re-propose à cocher à chaque tour.
  3. *Pas de gouvernance dans les étapes* : les positions d'organisation non actionnables en
     situation (« technique X seulement si taux de succès > 95 % ») vont dans « Ne pas
     oublier » ou sont exclues.
  4. *Critères d'arrêt / limitation* : s'ils existent dans la source, ils figurent dans la
     fiche (« quand s'arrêter » est le point de bascule le plus difficile) ; sinon invite locale.
  5. *Une interdiction par ligne* dans « Ne pas oublier » (fini les lignes qui en empilent trois).
  Liste de vérification finale du prompt mise à jour en conséquence ; 4 invariants de test
  ajoutés (156 tests).

## [3.4.4] — 2026-07-05
### Modifié
- **Message du badge « À compléter » reformulé sans jargon.** « Invites “à compléter” dans :
  Références » employait « invite » (calque de l'anglais *prompt*), incompréhensible pour
  l'utilisateur. Le toast et l'infobulle disent désormais « Reste à compléter : Références »,
  et en lecture « — remplacez les mentions “à compléter” par vos informations locales. »
  (règle du projet : aucun jargon technique dans les textes visibles).

## [3.4.3] — 2026-07-05
### Ajouté
- **Le badge « À compléter » est tapable.** L'emplacement des invites n'était donné que par
  l'infobulle `title`, invisible sur mobile (pas de survol). Un tap / clic / Entrée ou Espace
  sur le badge affiche désormais un toast listant les emplacements (« Invites “à compléter”
  dans : Références · Bloc “Traitement” »). Le badge reste visuellement discret : la cible
  tactile (~36 px) est étendue par un pseudo-élément invisible ; `role="button"`, `tabindex`
  et `:focus-visible` posés. Sur une carte de la bibliothèque, taper le badge n'ouvre PAS la
  fiche (même garde que l'épingle `data-pin`).

## [3.4.2] — 2026-07-05
### Corrigé
- **Cliquer le libellé « Contexte local » déclenchait le bouton « B » (gras).** Le bouton était
  placé DANS le `<label>` : sans attribut `for`, un label adopte comme contrôle implicite son
  premier élément de formulaire descendant — le bouton — et tout clic sur le libellé le
  déclenchait. Le bouton est sorti du label (ligne `lab-row` label + bouton) ; cliquer le
  libellé est redevenu inerte, le bouton et Ctrl/Cmd-B fonctionnent comme avant.
- **Badge « À compléter » : fin des faux positifs et emplacement des invites affiché.** Le badge
  se déclenchait sur n'importe quel « ⚠ », alors que ce symbole sert aussi de simple marqueur
  d'avertissement clinique (« ⚠ NE PAS associer… ») : ces fiches paraissaient « à compléter »
  sans qu'aucune invite ne soit visible. Seul le texte « à compléter » (accents facultatifs)
  compte désormais — le marqueur IA « ⚠ À COMPLÉTER : … » le contient et reste détecté. Et comme
  une invite peut être discrète (ex. « Exemple à compléter » dans les références des fiches
  d'exemple), l'infobulle du badge liste maintenant les emplacements concernés (« Invites
  “à compléter” dans : Références · Bloc “Traitement” »). Nouvelle fonction pure
  `completionSpots`, testée (152 tests).

## [3.4.1] — 2026-07-05
### Ajouté
- **Gras dans les textes de fiche.** Un fragment entouré de `**double astérisque**` s'affiche en
  gras en lecture et en mode crise (étapes, listes Confirmation / À vérifier / Ne pas oublier /
  Différentiels / Références, question et options des décisions, contexte local, compte-rendu de
  session). Réservé aux doses time-critical et aux interdictions. Données stockées inchangées
  (chaînes brutes : export/import et anciennes versions inchangés) ; balisage non apparié affiché
  tel quel (la coquille reste visible, le rendu ne casse jamais) ; échappement `esc()` appliqué
  avant la conversion ; l'algorithme SVG et la recherche plein texte ignorent les `**`.
  Dans l'éditeur : bouton « B » à côté des champs concernés (entoure/retire sur la sélection)
  et raccourci Ctrl/Cmd-B. Fonctions pures `fmt`/`stripBold` testées.
- **Badge « À compléter ».** En bibliothèque et en tête de fiche, un badge discret (couleur
  avertissement) signale une fiche contenant des invites laissées en suspens (« à compléter »,
  marqueur ⚠) — gabarit local non renseigné ou manque signalé par la génération IA. Fonction
  pure `ficheNeedsCompletion` testée.
- **Fin de parcours explicite.** Le bout d'une branche sans suite affiche « FIN — fin de cette
  branche de prise en charge. » (lève le doute « ai-je tout déroulé ? »).
- **Gabarit de contexte local.** Une fiche créée à la main part avec les invites « Tél renfort :
  à compléter » et « Tél régulation : à compléter » (les deux contextes d'exercice : structure
  et SMUR).

### Modifié
- **Prompt IA refondu** (fenêtre « Créer via IA »), aligné sur les référentiels d'aides
  cognitives de crise (Stanford Emergency Manual, fiches CAMR/SFAR) : double contexte
  structure/SMUR (renfort sur place ou régulation) avec renfort imposé dans le premier bloc ;
  critères de priorisation de l'extraction (time-critical d'abord, cibles chiffrées dans
  « À vérifier », interdictions dans « Ne pas oublier », causes réversibles traitées comme des
  actions) ; traçabilité obligatoire (source datée + ligne « Fiche générée par IA le … ») ;
  manques marqués « ⚠ À COMPLÉTER » et contradictions de la source signalées, jamais tranchées ;
  verbes flous (« envisager / considérer ») remplacés par une forme conditionnelle ou de
  vérification active ; dilutions de la source recopiées mais jamais calculées, avec invite
  locale « Dilutions / protocoles locaux si différents » ; gras `**…**` autorisé avec parcimonie ;
  consignes par type de source (page web, PDF long, image/scan). Invariants du prompt testés.

## [3.4.0] — 2026-07-05
### Ajouté
- **Les fiches « hors compte » restent accessibles depuis l'écran de connexion.** L'espace local
  suivant le dernier compte connecté, les fiches créées sans compte puis « laissées hors compte »
  à la connexion devenaient définitivement invisibles sur l'appareil (rien ne ramenait jamais à
  l'espace sans compte). L'écran de connexion affiche désormais, si cet espace contient des
  fiches, un lien « Cet appareil contient N fiches hors compte — les consulter sans se
  connecter » : il bascule sur l'espace sans compte (même bascule atomique qu'un changement de
  compte, proposée uniquement déconnecté — jamais de mélange entre bibliothèques). Une connexion
  ultérieure depuis cet espace re-propose de les emporter dans le compte : ce choix n'est plus
  définitif, et le dialogue « Fiches locales » l'explique désormais.

### Modifié
- Le comptage des fiches hors compte est sans effet de bord (n'attribue jamais la base
  historique à un espace, ne crée aucune base fantôme) ; fonction pure `liveFicheCount` testée.


---
Versions antérieures (3.0.0 → 3.3.7) : voir [CHANGELOG-archive.md](CHANGELOG-archive.md).

## [3.3.7] — 2026-07-04
### Corrigé
- **« Changer de compte » (ou « Se déconnecter ») avec l'option d'effacement cochée n'ouvrait
  plus l'écran de connexion.** Sans l'option, la fenêtre Compte restait ouverte sur le formulaire
  de connexion — on pouvait enchaîner directement sur un autre compte. Avec l'option cochée,
  l'effacement passe par un rechargement de la page (nécessaire : l'état en mémoire pointe sur des
  données supprimées) qui refermait la fenêtre et laissait l'utilisateur sur la bibliothèque. Le
  rechargement rouvre désormais l'écran de connexion : l'option « effacer » ne change plus que les
  données locales, jamais la destination après l'action.

## [3.3.6] — 2026-07-04
### Corrigé
- **L'option « effacer aussi les fiches de ce compte sur cet appareil » n'est plus proposée à un
  compte en attente de validation ou refusé.** Les écritures d'un tel compte sont bloquées côté
  serveur (RLS) tant qu'un administrateur ne l'a pas approuvé : ses fiches locales ne sont donc
  **pas** dans le cloud, et la case promettait à tort qu'« elles restent disponibles dans votre
  espace en ligne » — les effacer les aurait perdues définitivement. La case n'apparaît désormais
  que pour un compte approuvé (dont les fiches sont réellement sauvegardées) ; pour un compte en
  attente/refusé, « Se déconnecter » et « Changer de compte » redeviennent une simple confirmation
  sans option d'effacement.

## [3.3.5] — 2026-07-04
### Modifié
- **L'option « effacer aussi les fiches de ce compte sur cet appareil » (3.3.4) passe dans la
  fenêtre de confirmation.** Elle était une case permanente affichée sous les boutons de l'écran
  Compte, dupliquée dans chaque variante de l'écran (connecté / en attente / refusé). Elle est
  désormais portée par la fenêtre de confirmation qui s'ouvre au clic sur « Se déconnecter » ou
  « Changer de compte » : moins de bruit dans l'écran, et l'option apparaît au moment de décider.
  Cocher la case fait passer le bouton de validation en rouge (convention « action destructrice »).
### Interne
- **`confirmDlg` accepte une case à cocher optionnelle** (`opts.check`) : dans ce mode, la
  promesse se résout avec `{checked}` sur validation (et `null` sur abandon) ; sans `opts.check`,
  le retour booléen habituel est conservé (rétrocompatibilité de tous les appels existants,
  vérifiée). Les gestionnaires « Se déconnecter » / « Changer de compte », auparavant dupliqués
  quatre fois (deux écrans × deux boutons) avec leurs variantes de message, sont regroupés en un
  seul point de code (`confirmLeave` + `doSwitch`/`doOut`).

## [3.3.4] — 2026-07-04
### Ajouté
- **« Se déconnecter » et « Changer de compte » proposent d'effacer aussi les fiches de ce
  compte sur cet appareil.** Jusqu'ici, ni l'un ni l'autre ne touchait aux données locales
  (promesse hors-ligne : les fiches restaient visibles sans compte connecté) — de la valeur sur
  un appareil personnel, mais un vrai risque sur un appareil partagé (tablette d'équipe), où
  elles restaient lisibles par la personne suivante tant que personne d'autre ne se connectait
  à un compte différent. Une case à cocher (facultative, décochée par défaut) permet désormais
  d'effacer la copie locale du compte courant au moment de partir ; les fiches restent intactes
  dans le cloud, à re-synchroniser à la prochaine connexion. Nouvelle fonction `wipeCurrentSpace`
  — distincte de `wipeLocal` (effacement total de l'appareil, réservé à la suppression de
  compte) : seul l'espace du compte courant est effacé, les autres comptes déjà utilisés sur cet
  appareil ne sont pas touchés. Même case et mêmes boutons pour les deux actions (elles
  appellent la même fonction en interne) : proposer l'effacement seulement à l'une des deux
  aurait été redondant et propice à l'erreur.

## [3.3.3] — 2026-07-04
### Tests
- **Vérification du finding #1 de l'audit sécurité (3.3.2) : un lecteur seul ne peut pas déplacer
  une fiche partagée vers son espace perso, seul un editor/admin de la bibliothèque le peut.**
  Rejoué pour de vrai contre une instance Postgres locale (schéma + politiques RLS réels, pas
  seulement une relecture) : un viewer échoue bien (RLS -> 0 ligne, aucune modification), un
  editor réussit (fonctionnalité voulue, non-régression). Ce rejeu a mis au jour un bug dans le
  test ajouté en 3.3.2 (compte de test « gina » référencé dans `user_status` sans ligne
  `auth.users` correspondante — violation de contrainte de clé étrangère) : corrigé.
- **Découverte en marge de cette vérification :** le message de confirmation final de
  `rls-tests.sql` (`select '✅ TOUS LES TESTS RLS PASSENT'`, après le `rollback`) s'affiche même
  après l'échec d'un test — reproduit à la main en cassant délibérément une politique. Le
  `raise notice` émis en fin de bloc `do $$…$$` reste fiable (il ne s'affiche que si tout a
  réussi) ; c'est la ligne décorative qui ne l'est pas. Non corrigé dans cette version — à
  discuter avant de retoucher la structure de sécurité du fichier de tests.

## [3.3.2] — 2026-07-04
### Sécurité
- **Bibliothèque partagée : un compte non approuvé (liste d'attente/refusé) ne peut plus y être
  invité.** La validation des comptes (liste d'attente) n'était jusqu'ici câblée que sur l'espace
  perso ; un admin de bibliothèque pouvait, sans le savoir, donner un accès lecture/écriture
  immédiat à une bibliothèque d'équipe à un compte jamais validé. `invite_member()` applique
  désormais la même règle pour l'invité que pour l'espace perso ; l'écran « Gérer les membres »
  explique le refus.
### Tests
- **Bibliothèques partagées : première couverture RLS des rôles.** Aucun test ne créait jusqu'ici
  une vraie bibliothèque avec des membres pour vérifier viewer/editor/non-membre et l'étanchéité
  entre bibliothèques — c'est cette lacune qui avait laissé passer la faille ci-dessus. Ajout
  d'une section dédiée (`supabase/rls-tests.sql`), y compris une non-régression sur l'invitation
  d'un compte non approuvé.
- **`Sync._push` : la classification « fiche perso à réparer » (403 sur une fiche sans
  bibliothèque, cf. 3.3.1) est extraite en fonction pure testée** (`restErrStatus`,
  `isPersoRepairCandidate`), conformément à la règle du projet sur les fonctions pures.
### Corrigé
- **Appareil partagé, deux onglets ouverts sur deux comptes différents : un onglet resté sur
  l'ancien compte pouvait continuer d'écrire (épingles, curseur de synchro, modifications
  retenues) sous le nouvel espace actif de l'appareil**, sous l'effet d'un changement de compte
  fait dans un autre onglet. Un onglet est maintenant averti (évènement `storage` sur
  `ac-space`) et se recharge aussitôt, comme s'il venait de se connecter lui-même.
### Documentation
- Kit de déploiement : rappel que l'anti-spam de la liste d'attente n'est pas une limite de
  débit — à configurer côté Supabase (*Authentication → Rate Limits*).

## [3.3.1] — 2026-07-04
### Corrigé
- **Changement de compte : une seule fiche refusée n'immobilisait plus toute la synchro.** La
  clé primaire du cloud est globale (tous comptes confondus) : une fiche transférée entre
  comptes (export/import, qui conservait l'identifiant) était refusée par le serveur (RLS) au
  moment de la publier, et l'envoi se faisait en un seul lot — une fiche refusée bloquait alors
  indéfiniment *toute* la bibliothèque, avec un message l'attribuant à tort à des droits perdus
  sur une bibliothèque partagée. La synchro réessaie désormais fiche par fiche pour isoler la
  fautive ; une fiche personnelle ainsi bloquée est réparée automatiquement (nouvel identifiant,
  note/épingle/sessions/versions déplacées) puis repoussée. Un refus partiel n'empêche plus la
  réconciliation des bibliothèques partagées ni la synchro des catégories et des notes. Le
  message d'erreur distingue maintenant les deux causes réelles (droits partagés / identifiant
  déjà pris) sans promettre à tort que "le reste continue normalement".
- **Export / import entre comptes : identifiants régénérés.** Un fichier exporté embarque une
  empreinte (non réversible) de l'espace d'origine ; l'import ne conserve les identifiants que
  s'il provient du même espace (vraie restauration/fusion multi-appareils) — dans tous les
  autres cas, ils sont régénérés pour ne plus jamais entrer en collision avec une fiche
  possédée par un autre compte dans le cloud.
- **Compte approuvé mais synchro refusée en boucle (cas rare).** Les comptes sans ligne de
  statut connue (installations antérieures à la validation des comptes) étaient déclarés
  « Connecté » par l'app alors que la politique serveur refusait malgré tout chaque écriture.
  Alignement du schéma sur la même règle des deux côtés.
- **Appareil partagé : moins de surprises.** Le dialogue « Les emporter dans ce compte ? »
  (fiches créées avant toute connexion) liste désormais leurs titres. Les fiches créées,
  modifiées ou supprimées pendant qu'un compte était déconnecté sur l'appareil ne sont plus
  synchronisées en silence à la reconnexion : le titulaire du compte est d'abord invité à les
  reconnaître (synchroniser ou écarter et rétablir les versions du cloud).

Toutes les versions notables de l'application. Format inspiré de *Keep a Changelog* ;
versionnage sémantique. La version affichée en pied de page (`APP_VERSION` dans `index.html`)
et le cache du service worker (`sw.js`) sont tenus synchronisés par `release.sh`.

## [3.3.0] — 2026-07-04
### Ajouté
- **Espaces locaux par compte (multi-profils).** Tout le stockage local (fiches, notes
  personnelles, sessions, versions, épingles, catégories, curseur de synchro) est désormais
  cloisonné par compte : changer de compte ne mélange plus jamais deux bibliothèques, et revenir
  à un compte retrouve instantanément son cache local. L'espace suit le **dernier compte
  connecté** : une déconnexion — même forcée par un jeton révoqué — ne change rien à l'affichage
  (promesse hors-ligne intacte) ; la bascule n'a lieu qu'à la connexion d'un **autre** compte,
  par un rechargement propre. Migration **sans copie** : la base historique est attribuée à son
  propriétaire actuel, les installations existantes ne voient aucune différence. Passage
  « sans compte -> premier compte » : dialogue « Les emporter dans ce compte ? » (déplacement des
  fiches, notes, sessions et épingles). Entre deux comptes : jamais de transfert (export/import
  si besoin). Garde-fous : la synchro refuse structurellement de tourner sur l'espace d'un autre
  compte, et une bascule interrompue (app fermée au mauvais moment) est reprise au démarrage.
  Avant : les fiches de l'ancien compte restaient affichées chez le nouveau, pouvaient être
  versées dans son cloud, et les identifiants déjà synchronisés provoquaient une erreur de
  synchro permanente.
- **Bouton « Réparer l'application »** (fenêtre « Où sont mes fiches ? ») : désinscrit le
  service worker et vide ses caches (le code de l'app, pas les données) puis recharge une copie
  neuve — remède au cas « l'app semble bloquée sur une ancienne version ». Fiches, notes et
  sessions intactes (et le texte le dit).

### Corrigé
- **Suppression hors-ligne : plus de divergence entre appareils.** Supprimer une fiche en étant
  déconnecté posait une suppression locale dure, sans tombstone : la fiche restait dans le cloud
  et sur les autres appareils, définitivement. Dans l'espace d'un compte, la suppression
  hors-ligne pose désormais un tombstone « à pousser », propagé à la reconnexion. (La
  suppression dure ne subsiste que dans l'espace « sans compte », où il n'y a aucun cloud.)
- **Jauge rouge du « maintenir pour réinitialiser » enfin constante.** En mode sombre, la règle
  de survol générique (raccourci `background:`) effaçait la jauge de progression du bouton
  « Recommencer » pendant l'appui (le tap déclenche `:hover` sur mobile) — visible en clair,
  invisible en sombre. La règle exclut désormais les boutons en cours d'appui, et l'animation
  de jauge redémarre à coup sûr (reflow forcé entre deux appuis rapprochés).
- **Barre d'état iOS (heure/batterie) à jour.** iOS ne relit pas un meta `theme-color` modifié
  sur place : la balise est désormais **remplacée** (helper unique `setThemeColorMeta`). Au
  changement de thème, la barre suit immédiatement ; pendant le flash d'alarme, elle passe
  volontairement au jaune d'alerte puis est explicitement restaurée (fin d'animation + filet
  temporisé). À confirmer sur appareil réel.
- **Note personnelle : plus de saut en haut de page.** « + Ajouter » et « Terminer »
  reconstruisaient la vue et renvoyaient le défilement en haut ; la position est mémorisée et
  restaurée, et le focus de la zone de saisie est pris sans défilement.

## [3.2.5] — 2026-07-03
### Tests
- **`rls-tests.sql` : faux échec corrigé** (« ÉCHEC : un compte pending a pu écrire une note »).
  La section 5bis, ajoutée en 3.2.3, se termine en rôle propriétaire (nécessaire pour semer
  `auth.users`) ; la section 6 (notes personnelles), écrite avant elle, supposait encore le rôle
  `authenticated` — en propriétaire, la RLS est contournée par définition et le test concluait
  à tort à une faille. La section 6 rétablit désormais explicitement rôle et claims, avec un
  commentaire de garde pour les prochaines insertions de sections. Aucun changement de schéma ni
  de politique : les déploiements existants sont sains, seul le harnais de test était en cause.

## [3.2.4] — 2026-07-03
### Corrigé
- **Fenêtre Compte : zone tampon anti-mauvais-tap.** « Changer de compte » commençait 9 px sous
  « Synchroniser maintenant » — un tap légèrement trop bas déconnectait (avec la confirmation de
  la 3.2.3 en second filet). L'action fréquente est maintenant séparée des actions de compte par
  24 px d'espace inerte ; les boutons restent cliquables sur toute leur surface (44 px).
- **Icône « Aa » alignée sur la ligne de base, mesures à l'appui.** Le viewBox gardait 1,4 px de
  vide sous les lettres : tout recentrage du cadre laissait les « A » trop bas. ViewBox recadré
  au ras du dessin, puis bas des « A » calé sur la ligne de base réelle du texte voisin
  (métriques de police vérifiées au pixel dans le navigateur) ; calibration documentée dans le
  CSS pour éviter les futurs ajustements à l'aveugle.

## [3.2.3] — 2026-07-03
### Corrigé
- **« Ma version écrasée » fonctionne enfin dans le cas courant.** La sauvegarde locale n'était
  créée qu'en cas de conflit (modification locale non poussée) : une fiche partagée mise à jour
  par un collègue remplaçait votre copie sans rien archiver. La version locale est désormais
  archivée à **chaque** remplacement par une version distante (5 versions max par fiche).
- **Déconnexions intempestives.** (1) `Auth.refresh()` est désormais *single-flight* : deux
  rafraîchissements simultanés du jeton (synchro de démarrage + fenêtre Compte + « Synchroniser
  maintenant ») partaient avec le même refresh token — GoTrue rejetait le second (« déjà
  utilisé ») et déconnectait. (2) « Changer de compte », voisin de « Synchroniser maintenant »,
  déconnectait instantanément sans confirmation : il en demande une désormais.
- **Journal des actions** : valider un horaire sans le changer n'affiche plus de fausse mention
  « à l'origine HH:MM:SS » (posée pour un simple écart de millisecondes).
- **Bibliothèque partagée vide** : le texte s'adapte aux droits — un lecteur voit « Cette
  bibliothèque partagée est vide. » au lieu de l'appel à « créer votre première aide cognitive ».
- **Icône « Aa »** recentrée d'un pixel supplémentaire.

### Modifié
- **Import : destination explicite.** Perso par défaut ; si une bibliothèque partagée éditable
  est sélectionnée, l'app demande où importer (publier à l'équipe n'est jamais silencieux).
  Les catégories importées rejoignent le jeu de la bibliothèque de destination, « REMPLACER »
  ne touche plus que la destination (avant : toutes les bibliothèques !), l'app bascule sur la
  destination et le toast la nomme.
- **Déplacement de fiche entre bibliothèques : confirmations.** Sortir une fiche d'une
  bibliothèque partagée prévient que les membres perdront l'accès à la fiche et à leurs notes
  personnelles ; la déplacer vers une bibliothèque partagée confirme la publication à l'équipe.
- **« dernière modification par … »** remplace « modifiée par … » sur les fiches partagées
  (l'ancien libellé laissait croire à un auteur unique de la fiche).
- **« Synchroniser maintenant » laisse la fenêtre ouverte** : la ligne d'état au-dessus montre
  « Synchro en cours » puis le résultat — un vrai retour, au lieu d'une fermeture muette.
- **« Reprendre »** remplace « Ouvrir » pour les sessions (bandeau d'accueil et historique) :
  le bouton recharge l'état complet (étapes, minuteurs, compteurs), pas une simple ouverture.
- **Rappel de session dans l'en-tête** : « MODE CRISE · ● session en cours » (point pulsé),
  visible en permanence pendant une session — sans recolorer l'en-tête ni exposer de bouton
  « Terminer » en zone de tap fréquente (action destructrice = jamais rendue plus accessible).
- **Suppression de compte : avertissement « seul administrateur »** — si vous êtes l'unique
  admin de bibliothèques partagées, l'écran vous invite à nommer un remplaçant avant de partir
  (sinon seul l'administrateur de l'instance pourra en gérer les membres). Non bloquant.

### Serveur (à rejouer dans Supabase : `schema.sql` puis `rls-tests.sql`)
- **Anti-spam de la liste d'attente** : un compte n'entre dans `user_status` (« Comptes en
  attente ») qu'une fois son e-mail **vérifié** (code OTP saisi). Avant, demander un code
  suffisait : n'importe qui pouvait remplir la liste de fausses adresses, approuvables par
  erreur. La migration du script ignore les e-mails non vérifiés (un rejeu ne les ressuscite
  pas) et un nettoyage purge les inscriptions fantômes existantes. Test RLS ajouté (5bis).

## [3.2.2] — 2026-07-03
### Corrigé
- **Anti double-clic sur tout le parcours compte.** Les boutons « Recevoir le code »,
  « Valider » (connexion) et ceux de la suppression de compte (envoi, renvoi, suppression)
  se désactivent pendant l'appel réseau avec un libellé d'attente (« Envoi du code… »,
  « Vérification… », « Suppression… ») et se réactivent en cas d'échec. Un double clic
  envoyait deux requêtes : le 2ᵉ code OTP invalidait le 1ᵉʳ reçu par e-mail (« Code invalide »
  incompréhensible) et GoTrue rate-limitait l'envoi. Le champ SUPPRIMER ne peut plus réactiver
  le bouton au milieu d'une requête.
- **La fenêtre Compte dit la vérité sur la synchro.** « Synchronisation active » était codé en
  dur alors que le pied de page affichait « Hors-ligne » ou « Erreur de synchro ». La ligne
  d'état de la fenêtre reflète désormais exactement le même état que la pastille (source
  unique `_syncUi` posée par setSyncChip — aucune logique dupliquée), mise à jour en direct
  si la fenêtre est ouverte quand l'état change.

### Modifié
- **Hors-ligne dit clairement son nom.** Tenter de se connecter/s'inscrire (ou de recevoir un
  code de suppression) sans réseau affiche « Hors ligne : une connexion Internet est
  nécessaire… » avant tout appel, au lieu d'un échec réseau cryptique. Le bouton
  « Synchroniser maintenant » est grisé hors-ligne — légitime ici car la ligne d'état juste
  au-dessus explique pourquoi, et il se réactive en direct au retour du réseau ; les boutons
  de connexion, eux, restent actifs (pas d'indicateur réseau sur cet écran : un clic → message
  vaut mieux qu'un bouton grisé inexpliqué).
- **Suppression de compte : le processus est annoncé avant le bouton.** Le texte explique
  désormais « Par sécurité, votre identité doit être vérifiée : un code de confirmation vous
  sera envoyé à votre-adresse@… » — le bouton « Recevoir le code de confirmation » n'introduit
  plus le concept de code sans prévenir, et l'utilisateur sait quelle boîte mail surveiller.

## [3.2.1] — 2026-07-03
### Corrigé
- **iPhone en paysage : plus de textes agrandis de façon disproportionnée** (jauge de stockage,
  en-têtes de section, bandeaux…) : le « font boosting » de Safari iOS est désactivé
  (`-webkit-text-size-adjust:100%`). À confirmer sur appareil réel.
- **Mode sombre : survol correct des boutons pleins.** La règle de survol sombre générique
  écrasait aussi celle des boutons `primary` (« Créer via IA », « Ajouter les fiches
  d'exemple »…) et `danger`, posant un fond quasi noir sous leur texte ; ils retrouvent leurs
  survols propres (teal éclairci / teinte rouge douce).
- **Journal des actions : plus de fausse « correction » d'heure.** Cliquer sur un horaire puis
  valider sans le changer affichait quand même « à l'origine HH:MM:SS » (identique) — la
  mention n'apparaît plus que si l'heure a réellement changé.

### Modifié
- **Session en cours = fiche verrouillée.** Pendant une session active, la note personnelle
  passe en lecture seule avec un renvoi explicite (« pour annoter la session, utilisez le
  journal des actions » — évite de la confondre avec une note de session) et le bouton
  « + Ajouter une note » disparaît ; les boutons **Modifier** et **Versions** sont désactivés
  (badge « session en cours : modification suspendue ») — modifier la fiche mettrait fin à la
  session en cours. Imprimer / Dupliquer / Exporter restent disponibles (lecture seule).
  Tout redevient actif dès que la session est terminée.

## [3.2.0] — 2026-07-02
### Ajouté
- **Notes personnelles par fiche.** En bas de chaque fiche, une carte en pointillés permet
  d'attacher une note privée : toujours PERSONNELLE (hors de la fiche — un éditeur qui modifie
  une fiche partagée n'y touche jamais ; chaque membre d'une bibliothèque a la sienne, invisible
  des autres), synchronisée entre les appareils du même compte (nouvelle table `fiche_notes`,
  RLS « chacun ne lit/écrit que les siennes »), jamais exportée ni imprimée ni dupliquée.
  Lecture seule par défaut (rien d'éditable par accident en mode crise) : l'édition demande un
  geste explicite (« Modifier » / « + Ajouter une note personnelle »), avec auto-enregistrement.
  Même composant en lecture et dans l'éditeur, y compris dès la création d'une fiche (note
  nettoyée si la création est annulée). La suppression d'une fiche efface la note attachée et
  propage l'effacement ; supprimer une fiche de bibliothèque partagée prévient l'éditeur que
  les notes personnelles des membres seront perdues.
- **Suppression de compte confirmée par code e-mail (OTP).** Le parcours exige désormais, après
  le garde-fou « SUPPRIMER », un code envoyé à l'adresse de la session (jamais une adresse
  saisie — aucune injection possible) ; côté serveur, la RPC `delete_my_account` refuse tout
  jeton sans vérification OTP de moins de 10 minutes (claim `amr` — un jeton volé, même
  rafraîchi, ne suffit plus). Message clair et « Renvoyer le code » si le code a expiré.
- **Confirmation d'import** : un message confirme le nombre de fiches importées.

### Modifié
- **Prompt « Créer via IA » durci** : les fiches générées arrivent obligatoirement en
  **brouillon**, sans date de validation (relecture et validation humaines dans l'app) ; le
  document source est traité comme données, jamais comme instructions (anti-injection) ; doses,
  unités et voies recopiées à l'identique (aucune conversion ni arrondi) ; en cas d'algorithmes
  multiples (adulte/pédiatrie), l'IA demande lequel traiter ; les blocs suivent les phases
  cliniques (jamais de découpage arbitraire). L'import tolère désormais une réponse d'IA
  enrobée de clôtures Markdown (```json) au lieu d'échouer « Fichier illisible ».
- **Pied de page réorganisé** : actions (Exporter/Importer/Thème/taille du texte) d'abord,
  puis la ligne d'état (nombre de fiches · version, pastille de synchro), puis le message de
  stockage. Icône « Aa » recentrée ; étoiles « Créer via IA » dorées et pleines.

### Corrigé
- Synchronisation des notes : re-rendu limité à la fiche affichée (pas de vol de focus) et
  marqueur « à pousser » protégé contre une frappe pendant l'envoi (aucune perte silencieuse).

### Serveur (à rejouer dans Supabase : `schema.sql` puis `rls-tests.sql`)
- `schema.sql` désormais **entièrement rejouable** (drop policy if exists devant chaque
  politique) ; nouvelle table `fiche_notes` (+ RLS, gate d'approbation, trigger anti-postdatage) ;
  `delete_my_account` exige un OTP récent. `rls-tests.sql` : isolation des notes entre
  utilisateurs, gate d'approbation, refus d'usurpation, cascade à la suppression de compte,
  et exigence d'OTP récent (absent/périmé/frais) — 2 sections nouvelles.

### Tests
- `sanitizeNotes` et `stripJsonFences` exposées au hook de test ; 13 tests ajoutés (100 au total).

## [3.1.5] — 2026-07-02
### Corrigé
- **Impression du compte-rendu de session fiable.** L'iframe d'impression (hors écran) était
  recréée à chaque clic puis retirée au bout d'une seconde : recliquer sur « Imprimer » (ou un
  navigateur lent à ouvrir l'aperçu) imprimait une page blanche. L'iframe est désormais
  conservée et réutilisée tant que le compte-rendu affiché est le même, puis retirée à la
  fermeture de la fenêtre.
- **Flash d'alarme : plus de bande jaune persistante en bas d'écran (iPhone).** L'overlay du
  flash restait composité (animation `forwards`) après la fin du clignotement et Safari iOS
  s'en servait pour teinter la barre du bas en jaune. Il est maintenant retiré du rendu
  (`display:none`) dès la fin de l'animation.
- **Le filtre de catégories ne perd plus sa position.** Sur l'accueil, cliquer un filtre en fin
  de liste ne ramène plus la rangée de catégories à son début : le défilement horizontal est
  restauré après le re-rendu.
- **Synchronisation : deux trous colmatés.** (1) Le curseur de pull est remis à zéro à la
  déconnexion — en se connectant ensuite avec un autre compte, l'app ne rapatriait que les
  fiches plus récentes que l'ancien curseur et ratait l'historique du compte. (2) La migration
  des catégories au démarrage ré-enregistrait des fiches sans leur marqueur « à pousser » :
  une fiche importée hors connexion pouvait ainsi ne jamais être synchronisée.

### Modifié
- **Les fiches d'exemple ne sont plus créées automatiquement.** À la première ouverture (ou
  bibliothèque perso vide), un bandeau « Besoin d'exemples pour commencer ? » propose d'ajouter
  les deux fiches d'exemple (Anaphylaxie, Arrêt cardiaque) ; il est masquable. Les fiches
  ajoutées par ce bouton passent par le circuit normal d'enregistrement : elles se synchronisent
  si un compte est connecté (l'ancien amorçage silencieux ne le faisait pas). Les bibliothèques
  existantes ne sont pas concernées.
- **Emojis remplacés par des icônes SVG** dans toute l'interface (bouton thème, son 🔔/🔕 →
  cloche, « ⚙ Gérer », « Noter l'heure », « Créer via IA / manuellement », bandeau d'alarme,
  jauge de stockage, fenêtre « Où sont mes fiches ? », plein écran de l'algorithme, préfixe des
  toasts d'avertissement) : rendu identique sur tous les appareils, couleur du thème respectée.
  Restent : les symboles typographiques (✓ ✕ ›) et le « ⏰ » des notifications système, où le
  SVG est impossible.

## [3.1.4] — 2026-07-02
### Modifié — exemples réorientés médecine d'urgence
- Fiche de démarrage « Anaphylaxie peropératoire » remplacée par **« Anaphylaxie (choc
  anaphylactique) »** (urgences / pré-hospitalier : adrénaline IM, réévaluation à 5 min, boucle
  en cas de forme réfractaire), catégorie **Urgences**. La fiche « Arrêt cardiaque » (ERC),
  valable en médecine d'urgence, est conservée et rangée en catégorie **SMUR**.
  (Ne concerne que les nouvelles installations : les fiches d'exemple ne sont créées qu'à la
  première ouverture, aucune bibliothèque existante n'est modifiée.)
- Fiches importables `exemples/` remplacées : LAST et hémorragie du post-partum (contextes
  anesthésie/réanimation) cèdent la place à **« Accouchement inopiné en pré-hospitalier »**
  (SMUR) et **« État de mal épileptique de l'adulte »** (urgences). Leurs catégories embarquées
  (`c-smur`, `c-urgences`) correspondent aux ids déterministes des catégories par défaut :
  l'import se rattache aux catégories existantes sans doublon.
- Comme toujours pour les exemples : contenu générique (« protocole local »), statut
  **brouillon**, à relire et valider avant tout usage clinique.
- **Correction de certains bugs design**

## [3.1.3] — 2026-07-02
### Corrigé
- **Bibliothèques partagées accessibles hors-ligne.** La liste des bibliothèques (et vos rôles)
  est désormais mise en cache localement à chaque synchro réussie et restaurée au démarrage :
  sans réseau, la barre « Bibliothèque » et les fiches partagées (déjà stockées sur l'appareil)
  restent consultables et éditables. Un simple échec réseau ne fait plus « disparaître » les
  bibliothèques (la dernière liste connue est conservée) ; une révocation réelle continue, elle,
  d'être appliquée à la synchro suivante. Le cache est purement ergonomique : les droits réels
  restent arbitrés par la RLS côté serveur.
- **Plus de déconnexion intempestive hors-ligne.** Le rafraîchissement du jeton ne déconnecte
  plus sur un échec réseau (mode avion, Wi-Fi captif) — rester hors-ligne plus d'une heure
  pouvait déconnecter et rendre les bibliothèques partagées inaccessibles sans possibilité de
  se reconnecter. Seul un refus du serveur (jeton révoqué) déconnecte désormais.

### Tests
- Nouvelle fonction pure `sanitizeLibs` (assainissement du cache de profil) exposée au hook de
  test ; 5 tests ajoutés (91 au total).

## [3.1.2] — 2026-07-02
### Modifié
- Éditeur, champ « État » : l'option affiche simplement **« Brouillon »** pour une fiche
  personnelle ; la précision « (masquée aux lecteurs) » n'apparaît que si la fiche est dans une
  **bibliothèque partagée**, et le libellé se met à jour immédiatement quand on déplace la fiche
  d'une bibliothèque à l'autre.

### Corrigé
- Le choix Validée/Brouillon est désormais conservé pendant l'édition : auparavant, tout
  re-rendu du formulaire (changement de bibliothèque ou de catégorie, ajout d'étape…) le
  réinitialisait silencieusement à la valeur enregistrée.

## [3.1.1] — 2026-07-02
### Corrigé
- **Service worker** : les réponses d'erreur (404/500) et les pages interceptées par un portail
  captif Wi-Fi (hôtel, hôpital) ne sont **plus jamais mises en cache** — la copie hors-ligne de
  l'application ne peut plus être écrasée par une page cassée.
- Effacement local (« Supprimer mon compte ») : les épingles et le marqueur d'accueil sont
  désormais aussi effacés.

### Optimisé
- **Recherche plein texte** : le contenu indexé de chaque fiche est mis en cache — plus de
  re-parcours de toute la bibliothèque à chaque frappe.
- **Synchronisation** : le rapatriement (pull) est paginé — une très grosse bibliothèque arrive
  entière dès la première synchro (au lieu d'être plafonnée à 1 000 fiches par passage).
- Vignettes de la galerie chargées en différé (`loading="lazy"`), favicon ajouté.

### Nettoyé (audit de code, comportement identique)
- Gestionnaire de catégories **unifié** : l'éditeur ouvre la même fenêtre que l'accueil (avec le
  déplacement des fiches avant suppression), au lieu d'un panneau dupliqué.
- Fermeture des fenêtres (✕ / fond / Échap) factorisée (`bindModalDismiss`), suppression de code
  mort (`state.id`, alias `updateTimers`, CSS orphelin), `fileSlug` réutilise `catSlug`.

### Documentation
- `AGENTS.md` devient le fichier d'instructions **canonique**, lisible par tout outil IA
  (`CLAUDE.md` l'importe) ; il inclut un plan de navigation du monofichier.
- Docs consolidées : `docs/deploiement-et-conformite.md` regroupe kit de déploiement, statut
  non-dispositif-médical, modèles RGPD et CGU, et l'annexe « calcul de doses (écarté) »
  (5 fichiers → 1). `prompt-IA-creation-fiche.md` supprimé (doublon du prompt embarqué dans
  l'app, source unique désormais) ; `exemples/README.md` fusionné dans le README, lui-même
  allégé (le kit de déploiement n'y est plus dupliqué).

## [3.1.0] — 2026-07-02
### Ajouté
- Recherche **plein texte** : la recherche porte désormais sur tout le contenu des fiches (étapes,
  décisions, « ne pas oublier »…), pas seulement le titre et la catégorie.
- **Épinglage** de fiches en tête de bibliothèque, **synchronisé** entre les appareils d'un même
  utilisateur (par-utilisateur, via le document de catégories perso).
- **Compte-rendu de session** (chronologie horodatée, étapes réalisées, compteurs, minuteurs)
  depuis l'historique d'une fiche : **aperçu dans l'app**, puis **Imprimer** ou **Télécharger** —
  sans impression automatique ni nouvel onglet.
- **Comparaison de versions** dans la fenêtre « Versions » (ce qu'une restauration changerait).
- **Fiches liées** (« Voir aussi ») et **statut brouillon/validée** (les brouillons sont masqués
  aux lecteurs d'une bibliothèque partagée).
- **Attribution des modifications** : les fiches partagées indiquent le dernier modificateur.
- **Réglage de la taille du texte** (icône « Aa », 100/110/125 %), persistant par appareil.
- **Écran d'accueil** à la première ouverture (3 repères).
- **État de l'instance** dans l'écran Compte de l'app-admin (comptes, fiches, stockage) via la RPC
  `get_instance_stats`.
- Deuxième fiche d'exemple intégrée (« Arrêt cardiaque ») et fiches importables dans `exemples/`.
- Annonces **aria-live** (fin de minuteur, toasts) pour les lecteurs d'écran.

### Modifié
- Les `confirm()` bloquants natifs sont remplacés par une fenêtre de confirmation accessible.
- Compression des images en **WebP** (repli JPEG) — fichiers plus légers.
- Palette de catégories : 7 teintes assombries pour respecter le contraste WCAG AA.
- Cibles tactiles agrandies (boutons ≥ 44 px, navigation en mode crise).
- Fenêtre « Versions » : masquée aux lecteurs (jamais de version pour eux) et recadrée en
  bibliothèque partagée (« Récupérer ma version écrasée » — sauvegardes locales, pas un historique
  d'équipe).

### Outillage & docs
- `release.sh` (synchronise les numéros de version, vérifie syntaxe + tests ; ne committe pas),
  `CHANGELOG.md`, `CLAUDE.md`, intégration continue GitHub Actions, en-têtes de sécurité (`_headers`).
- Suite de tests étendue (`tests.html`) aux nouvelles fonctions pures.
- Tests des politiques RLS (`supabase/rls-tests.sql`) et documentation
  (statut non-dispositif-médical, kit de déploiement, modèles RGPD/CGU).

## [3.0.4] — 2026-07-01
### Ajouté
- Accessibilité des fenêtres (rôle dialog, piège de focus, Échap), libellés des minuteurs/compteurs.
- Runner de tests autonome (`tests.html`).
### Modifié
- Version du cache du service worker alignée sur `APP_VERSION`.
- Contrastes WCAG AA, cibles tactiles, `alert()` remplacés par des toasts, pagination de la bibliothèque.

## [3.0.3] — antérieur
- Validation des comptes désactivée par défaut ; correctif du statut « en attente » affiché à tort.

## [3.0.2] — antérieur
- Correctif de la pastille de synchro affichée à tort après déconnexion/suppression de compte.

## [3.0.1] — antérieur
- Nettoyage du code (doublons regroupés), garde-fou de taille SQL, correctifs de pastilles de statut,
  largeur de l'éditeur sur petit écran iOS.

## [3.0.0] — antérieur
- Synchronisation cloud (Supabase) optionnelle, multi-utilisateur, bibliothèques partagées, RLS.
