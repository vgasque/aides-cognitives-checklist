# Lot v6.0 — refonte « Natif » — A502-A508

Demande de l'auteur (31/10/2026) : « mettre à jour le design pour le moderniser, qu'il puisse rester design dans les
dix prochaines années, et se rapproche d'une application smartphone / tablette / bureau ». Cadrage pris avec lui :
**refonte complète**, **maquettes d'abord**, direction « natif sobre » en explorant d'autres pistes.

Méthode : captures de l'app servie (v5.57.1, 390 · 1024 · 1440 px, jour et nuit : accueil, démarrage, session,
éditeur, Page, Sessions, Moi, Créer, menu ⋯), relevé des formes refusées et des invariants en vigueur, puis trois
planches publiées (artefacts privés de l'auteur) :

- trois directions sur l'accueil et la session, quatre largeurs ;
- la direction retenue déclinée sur démarrage, Page, éditeur, Sessions, Moi, Administration, feuilles ;
- les deux options de chaque question binaire, côte à côte ;
- la rangée groupée éprouvée contre la sélection, une liste cochable, des compteurs, des minuteurs, un réglage.

**Rien n'est encore implémenté.** Ces entrées fixent la cible ; chaque lot d'implémentation les amendera de ses
mesures (règle : mesurer l'app, pas lire le CSS).

## A502 — La direction « Natif » est retenue

**Décision.** L'app suit les conventions d'iOS, d'iPadOS et de macOS de 2026 : grand titre, listes groupées en
cartes arrondies, barres qui FLOTTENT (et elles seules en verre), barre latérale + inspecteur dès la tablette. Raison
retenue : c'est la direction qui vieillit sans effort, parce qu'elle suit l'OS que les soignants pratiquent toute la
journée ; le mode crise garde sa logique.

**Ce qui ne bouge pas** (rappelé ici parce que la refonte touche tout) : les quatre registres et leur mot (règle 8,
A407-A408) ; même corps pour toutes les étapes, danger par le mot et la bordure (A345) ; chrono et minuteurs en cours
toujours visibles en tête (ECAM) ; le quai garde ses mots entiers (A465), « Fin » rouge confirmé par maintien
(A346) ; rien n'interrompt une session (règle 11) ; cibles 44 px en session, plancher 11 px, champs 16 px (règle 9) ;
un seul bouton plein par écran (A375, A441) ; les trois polices embarquées, aucune dépendance nouvelle (règle 13).

**Ordre d'implémentation** : (1) tokens et matières, (2) chrome — barres, onglets, feuilles —, (3) surfaces une à
une (accueil, démarrage, session, éditeur, Sessions/Moi/Administration, Page). Un lot = une version ; captures du
design system relevées à chaque lot (`node design/capture.mjs`).

**Formes écartées (par l'auteur, sur planche)** :
- **B « Cockpit »** — sombre d'abord, chiffres mono, étapes « question …… RÉPONSE » alignées à droite, tuiles
  d'accès direct à code court, touches physiques en bas. Prolonge l'ECAM, mais rouvrait l'accueil en une colonne
  (A389) et passait le chrome en majuscules mono.
- **C « Document »** — manuel imprimé : serif des titres, filets au lieu des cartes, réponse en italique, sommaire
  et minuteurs en marges au bureau. Le plus calme, mais le plus long à parcourir sous stress.
- **Verre généralisé** (cartes, feuilles et barres en verre) — écarté dès le cadrage : daté vite, coûteux en
  lisibilité sous stress.

## A503 — Capsule et quai en verre clair, en thème clair (renverse en partie les trois matières, v5.6)

**Avant.** La capsule des minuteurs et le quai de session portent la matière système `--sys`, SOMBRE dans les deux
thèmes (refonte v5.6, A222).

**Décision.** En thème clair, les deux barres prennent la matière des barres flottantes d'iOS : verre clair
translucide (fond blanc ≈ 78 %, flou, bord fin), ombre douce. En thème sombre **rien ne change**. Les registres
propres à ces barres restent : « Fin » rouge, l'excursion ambre, « ● SESSION » vert, la touche primaire
(Horodater) pleine.

**À vérifier au lot 1** : contraste du texte des touches et des chiffres sur le verre au-dessus du contenu le plus
chargé (étape CRITIQUE, aplat « fait »), ≥ 4,5:1 mesuré, pas estimé ; repli opaque quand `backdrop-filter` manque.

**Forme écartée** : garder la matière sombre en clair avec la seule forme en pilule — elle détache mieux le temps du
contenu, mais fait deux mondes sur un même écran ; l'auteur a choisi le verre.

## A504 — Barre d'onglets en bas au téléphone

**Avant.** Accueil < 780 : trois boutons ronds en haut (Sessions, Créer, Moi), champ de recherche et bouton des
filtres en bas.

**Décision.** Barre d'onglets flottante en bas : **Aides · Sessions · Moi** (icône + mot, jamais le glyphe seul),
recherche dans un rond à droite de la barre, **Créer** en haut à droite, « Sélectionner » en haut à gauche, filtres
en pastilles sous le grand titre. Dès 780 px la colonne gauche reste telle quelle (A269, A501). En sélection, la
barre d'onglets cède la place au tiroir « Actions » (A476). Sessions et Moi deviennent des onglets pleins au
téléphone (aujourd'hui des page-fenêtres, `syncHomeTabs`) : la pile de retour (A430) est à reprendre au lot 2.

**Forme écartée** : garder la navigation actuelle redessinée (aucun changement d'habitude).

## A505 — Grand titre de page, 34 px (amende l'échelle A6)

**Décision.** Un cran au-dessus de 24 dans l'échelle typographique fermée, pour le **seul titre de page** :
34 px / 800 au téléphone (Aides, Sessions, Moi), 28 px en large et pour le titre d'une aide. Au défilement il se
replie en titre de 17,5 px dans la barre du haut. Il ne s'applique à aucun autre texte ; `check-type` devra
l'admettre comme cran nommé, pas comme exception.

## A506 — Listes groupées : une rangée, quatre emplacements

**Avant.** Cartes séparées à liseré de catégorie de 4 px à gauche.

**Décision.** Les listes deviennent des **groupes arrondis** (rayon 14) de rangées séparées par un filet, sous un
intitulé de groupe en 13,5 px. La catégorie passe en **point de 10 px suivi de son nom** (jamais le point seul,
A326). Une seule grille de rangée sert partout, à quatre emplacements fixes :

| Avant | Texte | Valeur | Commande |
|---|---|---|---|
| point de catégorie, case de sélection, case à cocher, icône — cible 44 | titre 17, sous-titre 13,5 ; passe à la ligne | nombre, temps mono, statut en mot | chevron, pas-à-pas − +, Lancer/Pause/Relancer, interrupteur — 44 |

**Vérifié sur planche, à la demande de l'auteur** (compatibilité avec les cases cochables, les compteurs, les
minuteurs) : sélection multiple de l'accueil, liste cochable d'une référence, minuteurs de la colonne d'état (temps +
commande + barre de progression sur la rangée), compteurs (pas-à-pas 44 px), réglage à interrupteur.

**Forme écartée (par l'auteur, sur planche)** : la planche de vérification avait habillé ces rangées de minuteurs en
« Moniteur » — une liste à boutons Pause/Relancer/Lancer. « Ce n'est pas un moniteur » : le moniteur est un
AFFICHEUR plein écran en lecture seule, lu à deux mètres (A231, A232, A341). Il ne prend jamais la rangée groupée ;
sa refonte est dessinée à part (planche « Moniteur Natif » : grand chiffre et chrono de session gardés, bande des
échéances en carte à rangées nommées, « Revenir » nommé en plus du toucher partout). Règles qui en sortent :
hauteur **52 px au minimum** (A375), la rangée grandit avec son texte ; le filet commence au texte quand un élément
« avant » est présent ; registre sur la **bordure de la case et le mot**, jamais en aplat sur la rangée ; rangée
choisie en sélection sur fond bleu pâle ; « fait » = case verte pleine et texte estompé, sans aplat vert à l'accueil
(A270). Piège relevé en maquette : une rangée SANS élément « avant » doit passer sur une grille à trois colonnes,
sinon le texte glisse dans la colonne « avant » et la valeur chevauche la commande.

## A507 — Cases rondes

**Décision.** Les cases d'étape en session deviennent des **cercles de 30 px** (cible 44, halo admis), comme les
rappels d'iOS ; même forme dans les listes cochables des références (`li.md-task`). La bordure garde le registre :
ambre pour VIGILANCE, rouge pour CRITIQUE ; cochée = vert plein + coche. La case de **sélection** (accueil,
Administration) est aussi ronde, 24 px, bleue une fois cochée — elle ne se confond pas avec une case d'étape parce
qu'elle n'apparaît qu'en mode sélection.

## A508 — Feuilles du bas à poignée et menu ⋯ ancré, au téléphone

**Décision.** Au téléphone, Créer, Affichage, Partager s'ouvrent en **feuille du bas** (mi-hauteur ou
pleine), poignée en tête, fermeture en la tirant vers le bas ou par « ✕ » ; le voile absorbe le tap (A497). Le menu
**⋯** devient un **menu contextuel ancré à son bouton** (verre, sections séparées, « Terminer la session… » en rouge
en dernier), la session restant visible dessous. Rien de cela ne s'ouvre sans geste de l'utilisateur pendant une
session (règle 11). Le moniteur n'en est pas une : il reste un afficheur plein écran (A509). En large, les feuilles restent des fenêtres centrées ou des vues de la colonne, comme
aujourd'hui.

## A509 — Le moniteur reste un afficheur ; sa refonte Natif

**Décision (validée par l'auteur sur planche).** Le moniteur garde sa nature : plein écran, lecture seule, lu à deux
mètres, « toucher pour revenir » partout. Gardés tels quels : chrono de session en vert en haut ; le prochain
minuteur en très grand chiffre mono ; une échéance par rangée sur un même axe, la ligne « maintenant » qui les
traverse (A231) ; l'étiquette qui bascule à gauche passé la moitié de l'axe ; « + n » au-delà de la place ; échu en
ambre avec le mot ÉCHU ; les règles de place du grand chiffre (A232, A341).

Ce qui change :
- la bande devient une **carte arrondie à rangées nommées** — le nom du minuteur en tête de sa rangée, plus
  seulement sur l'étiquette ; l'axe dit « maintenant » au-dessus des rangées, « −2 min » et « +5 min » dessous
  (en dessus, « maintenant » chevauchait « −2 min » sur la bande étroite) ; l'étiquette porte un fond de carte
  pour rester lisible quand elle croise la ligne « maintenant » ;
- le passé s'estompe en aplat, les tours suivants d'un minuteur cyclique sont des traits fins ;
- **barre de progression** épaisse et NEUTRE sous le grand chiffre (A407 : jamais bleue) ;
- « **Revenir** » nommé dans une pilule en verre, en plus du toucher n'importe où ;
- « Sans heure » en pastilles ;
- tablette posée sur le chariot : le grand chiffre monte à ~220 px, plafond toujours pris sur la bande rendue (A341).

**Forme écartée** : le moniteur en liste groupée à commandes (cf. A506).

## A510 — Arbitrages après mesure (266 vues) et lecture du code

Avant tout code, l'app a été mesurée sur 14 écrans × 7 largeurs (320 → 1440) × 2 tailles de texte, et chaque
décision A503-A509 relue contre le code et la doctrine. Rapport : planche « Obstacles de la refonte Natif ». Six
points demandaient un arbitrage ; l'auteur a laissé le choix (« pour le reste je te laisse choisir »). Retenus :

1. **Verre (amende A503, renverse A423 en connaissance de cause).** Verre à ≈ 90 % d'opacité, pas 78 % : à 78 %,
   « ● SESSION » tombait à 3,4:1 au-dessus d'un texte foncé. Les VOLETS collés aux barres (capsule, quai) prennent la
   même matière, sinon deux mondes se touchent. Tokens redéclarés EN CONTEXTE (capsule, quai, volets), thème clair
   seulement : `--sys` garde ses douze autres lecteurs (carte de session de l'accueil, bulle du guide, toasts,
   alarme, scanner QR…). Registres propres aux barres claires (les « -sys » font 1,6 à 2:1 sur fond clair). Repli
   opaque sans `backdrop-filter` et sous `prefers-reduced-transparency`. Le contraste se mesure sur le contenu le plus
   chargé qui passe dessous (étape CRITIQUE, aplat « fait »), par une sonde à écrire — `audit-a11y` compose le fond
   par les ancêtres du DOM et donnerait un faux vert sous une barre fixe.
2. **Un onglet n'est pas un niveau de retour (amende A504, A430).** Comme sur iOS : le retour système ne change pas
   d'onglet ; chaque onglet garde sa position de défilement. Témoin de retour à 390 px à ajouter (`audit-retour` ne
   joue que 1000 px).
3. **La recherche au clavier (amende A504, respecte A192-A197).** Au toucher, le rond s'ouvre en champ posé
   au-dessus du clavier, dans sa propre couche ; la barre d'onglets se retire comme tout chrome épinglé.
4. **Titre des rangées (amende A506, respecte A375).** 15 px à l'accueil et dans les listes (A375), 17,5 dans les
   étapes de session (A345 inchangé). Le 17 de la planche n'était pas un cran.
5. **Menu ⋯ au téléphone (amende A508, garde A361).** La feuille basse d'A361 reste au téléphone ; le menu ancré ne
   sert qu'en large, et il gagne un voile transparent qui absorbe le tap de fermeture (A497) : aujourd'hui il se
   ferme au clic du document sans l'arrêter, et ce tap pourrait cocher l'étape dessous.
6. **L'aide en cours à l'accueil (amende A506, remplace le liseré vert de 6 px d'A355).** Elle sort de sa catégorie
   et monte en tête, dans un groupe « En cours », avec « ● Session 04:12 » en vert sur sa rangée.

**Autres corrections issues de la mesure** :
- **Cases rondes (amende A507)** : 36 px comme la case actuelle, pas 30 (A507 l'aurait rendue plus petite) ; dernier
  repère de la jauge d'A474 = un rond plus grand que les autres (il figurait la case par un carré).
- **Grand titre (précise A505)** : deux crans nommés 34 et 28 dans `check-type`, réduits sous `zw430`/`zw360` ;
  jamais en session (budget d'écran). Mécanique : le patron `.titled`/`syncHdrScroll` de la lecture d'une aide — le
  grand titre défile dans le contenu, la barre de hauteur fixe n'affiche que le petit (C16 : jamais d'en-tête qui
  change de hauteur).
- **Progression en session** : pas de « Bloc n sur 4 » ni de segments (aucun total honnête sur une aide ramifiée,
  et prédire le chemin est exclu) ; « Parcours · x/y étapes » et la pilule « En cours » au-dessus du titre (A465).
- **Moniteur (précise A509)** : le nom étant en tête de rangée, l'étiquette d'échéance ne porte plus que le temps ;
  c'est ce qui rend la place que la colonne de nom prend à l'axe.
- **Ordre des lots (remplace celui d'A502)** : (1) correctifs des défauts déjà présents, (2) outillage de mesure
  (sonde de contraste sous barre, témoins étroits avec texte agrandi, retour au téléphone, crans de titre),
  (3) rangée groupée et cases rondes, (4) navigation du téléphone, (5) verre et moniteur.

**Défauts trouvés dans l'app actuelle, indépendants de la refonte** : mots du quai coupés à 320 et 1280 px avec le
texte à 130 % (« FV réfractair », « Horodate » — contraire à A465, dont le témoin ne joue 320 qu'à 115 %) ;
`audit-a11y.mjs` appelle `openMonitor`, qui n'existe pas (`monOpen`), si bien que le contraste du moniteur n'a
jamais été mesuré ; la garantie arithmétique d'A231 est fausse à 130 % (demi-bande de 105 px pour 115 px
d'étiquette) ; le nom de l'aide se réduit à « A… » en session à 320 × 130 %.

**320 px, tranché (l'auteur laisse le choix).** Qui affiche 320 px : iPhone SE 2/3 et 12/13 mini en « Zoom de
l'affichage : Agrandi », iPad en Slide Over ou dans la colonne étroite de Split View, et les iPhone 5/SE 1 devenus
marginaux ; c'est aussi le plancher WCAG 1.4.10, servi depuis la v4.43.0. Mais le cas fréquent sous 320 vient de la
taille du texte de l'app : 390 px à 130 % laissent 300 px, 375 px à 130 % en laissent 288. Règle retenue :
- **320 px à 100 % et 115 %** : servi en entier, comme aujourd'hui (budget de chrome, mots entiers, cibles).
- **375 et 390 px à 130 %** : servis en entier ; c'est là que vit le gros texte réel, et le budget d'écran de
  session (`audit-budget`) s'y mesure.
- **320 px à 130 %** (246 px de place, deux réglages d'agrandissement cumulés) : régime DÉGRADÉ. A465 tient — aucun
  mot coupé, une seconde ligne est permise — mais le plafond de hauteur du chrome ne s'y applique pas. Les témoins
  y vérifient l'absence de mot coupé et de débordement horizontal, rien de plus.

## A513 — Deux questions tranchées avant le lot 2 : la décision en session, l'iPhone SE tourné

**1. La carte de décision perd son fond ambré (renverse la carte « AMBRE DOUX » d'A345).** Depuis la v5.30, la
carte de décision en session est sur `--warn-soft`. La refonte la remet au régime des autres blocs — fond de
travail, contour bleu quand elle est le bloc courant — et ne garde l'ambre que sur le mot « ◆ Décision ». Raison
(choisie par l'auteur sur la planche « Étapes en session Natif ») : la règle 8 réserve l'ambre au risque d'erreur et
à l'échéance ; une question n'en est pas un, et un aplat ambre permanent use le registre qui doit signaler une dose
ou un minuteur échu. La question garde son corps (`--t-step-l`), les réponses disent toujours où elles mènent, la
ligne de jalon « SI … » et sa jauge restent.
*Forme écartée* : garder l'aplat ambre pour repérer la décision de loin.

**2. Un téléphone tourné prend la colonne gauche, quelle que soit sa largeur (précise A504).** La barre d'onglets
d'A504 ne vaut que sous 780 px. Vérifié au simulateur : un iPhone standard tourné (844 px) est déjà au-dessus et
affiche la colonne gauche. Seul l'iPhone SE (667 px) restait dessous. Il suit désormais la même règle : en paysage
bas (`paysageBas()`, A511), l'accueil prend la colonne gauche, jamais la barre d'onglets. Un seul dessin pour « un
téléphone tourné », et la hauteur, déjà rare (A511), reste au contenu. La colonne y loge l'inset latéral (A512).
*Forme écartée* : une barre d'onglets compacte sur une ligne (~44 px) en paysage.

## A514 — Lot 2 de la refonte : l'outillage avant le code (aucun changement servi)

Ordre d'A510 : avant de toucher un pixel, poser ce qui saura dire si la refonte casse quelque chose.

**1. `audit-verre` — le contraste se mesure AU PIXEL sous les barres.** `audit-a11y` compose le fond d'un texte par
ses ancêtres du DOM : juste pour une surface opaque, faux sous une barre translucide (A503), où le fond réel est ce
qui défile dessous. Le nouveau harnais amène l'étape CRITIQUE puis une étape cochée sous la capsule et sous le quai,
masque la barre, capture ce qui passe dessous, y compose la pile de fonds réelle de la barre et garde le PIRE
contraste de chaque texte (seuils WCAG 1.4.3). Téléphone jour et nuit, paysage, bureau : 16 contrôles. Il a déjà
servi : en paysage, la capsule montée dans l'en-tête (A511) repose sur une barre translucide — pire contraste réel
4,94:1. Preuve d'échec rejouable : `AC_VERRE_ESSAI=1` pose un verre clair à 60 % sous l'encre système — 1,0 à 1,1:1,
les 16 rouges (c'est la mesure qu'avait prédite le rapport d'obstacles). Aucun fetch : la CSP de l'app l'interdit
sur `data:`, la capture est décodée par une image.

**2. `audit-retour` joue le téléphone (390 px).** La pile de retour (A430) n'était mesurée qu'à 1000 px. Trois
contrôles figent le comportement d'AVANT la barre d'onglets : Sessions et Moi sont des page-fenêtres d'un niveau,
une aide puis Moi font deux niveaux défaits dans l'ordre. Au lot 4 (A504), un onglet cessera d'être un niveau
(A510 §2) : ce témoin devra changer, sciemment. Preuve d'échec : `AC_RETOUR_ESSAI=1` coupe la synchronisation de
l'historique.

**3. `check-type` admet les deux crans du grand titre, pour le seul `.pg-ttl`.** 34 px (téléphone) et 28 px (large,
titre d'aide), A505 : exemptions NOMMÉES par sélecteur, comme le titre de bienvenue — vérifié, un 34 px hors
`.pg-ttl` reste refusé. L'échelle de tout le reste ne bouge pas.

Le harnais `audit-verre` entre dans `HARNAIS` (24 harnais) ; rien de servi ne change (`index.html` intact).

## A515 — Lot 3 de la refonte : cases rondes et rangées groupées (v5.58.0)

**Cases rondes (A507, précisé par A510).** Toutes les cases deviennent rondes : étape de session (36 px gardés),
case de sélection de l'accueil et case maîtresse, cases du choix de collections, cases d'Administration, listes
cochables des références (`li.md-task`, 20 px, alignement suspendu inchangé). La bordure de l'étape porte toujours
le registre (rouge CRITIQUE, ambre VIGILANCE), la case cochée reste verte pleine. Le dernier repère de la jauge
d'un seuil (A474), qui figurait la case par un carré, devient un rond PLUS GRAND (10 px contre 8). L'anneau de focus
de la case de sélection suit la forme ronde. La Page (`.sv-bx`) garde ses cases : c'est un document imprimé.

**Rangées groupées à l'accueil (A506).** La vue DÉTAILLÉE n'est plus une pile de cartes : un groupe arrondi par
section (`--r-4`, matière de travail, ombre de travail), des rangées séparées par un filet, plus de filet sous la
dernière ; l'intertitre de section reste au-dessus du groupe. La vue COMPACTE l'était déjà (livre à filets) et ne
change que par le liseré. Le LISERÉ de catégorie (3 à 6 px) disparaît partout à l'accueil : la catégorie se dit par
le point suivi de son nom dans la sous-ligne (« ● SMUR », A242) — jamais le point seul (A326). Le liseré vert d'une
aide en session part aussi (amende A355) : l'état reste dit par « ● En cours 12:04 » en vert sur la rangée. Les
états se composent avec la rangée groupée : sélection bleu pâle, survol en teinte, et plus de soulèvement au survol
(c'était le geste d'une carte).

**Arbitrages de l'auteur (sur question, recommandations retenues)** :
1. « Détaillée / Compacte » restent tous deux — deux lignes ou une, dans le même groupe.
2. L'étoile d'accès direct reste à droite, sans chevron : toute la rangée ouvre l'aide.
3. En sélection, la case prend l'avant et le point de catégorie reste dans la sous-ligne.
4. Les épinglées deviennent le PREMIER GROUPE de rangées, « Accès direct » (`.dir-book.pinned`), même rangée que le
   répertoire, à toutes les largeurs — **renverse A261** (tuiles). Le dessin des tuiles (`.qa-tile`, `.qa-grid`,
   `.qa-t`, `.qa-sub`, `cfg.tile`) est PURGÉ (règle 14) ; la fiche reste aussi dans le répertoire.
*Formes écartées* : une seule forme de rangée (sans réglage) ; chevron à droite et épingler au glissement ; point
supprimé en sélection ; grille de tuiles conservée.

**Pas encore fait (dit, pas tu)** : le groupe « En cours » d'A510 §6 — l'aide en session reste à sa place dans sa
catégorie ; c'est la carte « Session en cours » en tête de l'accueil qui la met en avant, comme avant. Les autres
listes (Sessions, Moi, Administration, colonne d'état) gardent leur dessin : elles relèvent des lots suivants.

**Témoins.** `audit-doctrine` « REFONTE · cases rondes et rangées groupées (A506-A507) » (8 contrôles, 5 rouges sur le
code d'avant) ; réécrits sciemment : « les épinglées ont le rythme du répertoire » (groupe de rangées de même largeur,
plus aucune tuile), « titres longs » (cas de la rangée seul), « la rangée a un rythme régulier » (plancher 64 px des
rangées groupées au lieu de 76 des cartes). Captures du design system relevées.

## A516 — Lot 3 réaligné sur la maquette (v5.58.1) : la rangée d'A506 à la lettre

**Signalé par l'auteur à la relecture de la v5.58.0** : « tu es tellement éloigné des maquettes et des décisions ».
Constat : le lot 3 avait été jugé contre la v5.57 (avant/après), jamais contre la maquette Natif ; il gardait des
cartes à trois lignes, « AIDE » en capitales, le point de catégorie dans la sous-ligne, une rangée de 64 px et des
intertitres en capitales espacées. A506 disait autre chose.

**Ce qui change (maquette « trois directions », A · Natif, accueil téléphone et tablette)** :
- **Point de catégorie de 10 px EN TÊTE de rangée** (emplacement « avant » d'A506), son nom dans la sous-ligne ;
  en sélection, la case prend l'avant et le point revient devant le nom (A515 §3). Sans catégorie, pas
  d'emplacement : la rangée garde deux pistes (`has-av`, piège relevé en maquette).
- **Sous-ligne en texte séparé par des points**, 13,5 : « Aide · SMUR · adulte · △ À relire » — nature,
  catégorie, discriminant, puis l'état en mots, à la suite (plus calé à droite, plus de pastille d'aplat). Titre
  15/600 (A510 §4).
- **Rangée de 52 px au minimum** (A506, A375), le **filet commence au texte** (dégradé d'une ligne, aucun élément
  ajouté), le groupe n'a **ni bord ni ombre** (maquette : un aplat de travail sur le fond).
- **Intertitres en phrase**, 13,5/600 (« Accès direct   1 », « SMUR   1 ») ; le groupe « Accès direct » prend le même
  intertitre que les autres (plus de « n épinglées » en capitales). Le point d'un intertitre de catégorie reste :
  c'est lui qui dit les homonymes multicolores (A485).
- **La vue compacte** garde sa ligne unique à état calé à droite (A338) ; elle perd la pastille et le gras.

**Amende A338** (« nature · discriminant · ● catégorie, état calé à droite ») : la nature reste sur CHAQUE rangée
(demande de l'auteur, témoin d'`audit-doctrine` : en vue « Tout » les deux natures se mêlent), mais en minuscules
dans la ligne à points, plus en petites capitales ; la catégorie passe avant le discriminant (ordre de la
maquette) ; l'état suit l'identité en vue détaillée. **Amende A422** : l'état n'a plus d'aplat. **Écart à la
maquette, soumis à l'auteur** : la maquette n'écrivait pas « Aide » (toutes ses rangées étaient des aides).

*Forme écartée* : garder le point dans la sous-ligne hors sélection (v5.58.0) — elle contredisait A506.

## A517 — Lot 4 de la refonte : la navigation du téléphone (v5.59.0)

Implémente A504 et A505 d'après la maquette « trois directions » (A · Natif, accueil téléphone et tablette),
avec les arbitrages d'A510 §2-§3.

**Au téléphone en portrait (< 780 px, hors paysage bas)** — `tabNavOn()`, classe `html.tabnav` :
- **Barre d'onglets flottante en bas** : Aides · Sessions · Moi (icône + mot ; « Moi » porte les initiales et la
  pastille du compte, A500 ; Sessions un point vert quand une session tourne, comme la colonne), et la
  **recherche dans un rond** à droite. Matière : verre ≈ 90 % (`--glass`, A510 §1), repli opaque sans
  `backdrop-filter` et sous `prefers-reduced-transparency`. Elle se retire en sélection (le tiroir « Actions »
  prend le bas, A476).
- **Sessions et Moi deviennent des ONGLETS** : la même vue que la colonne large (`renderHomeTab`), plus des
  page-fenêtres. **Un onglet n'est pas un niveau de retour** (A510 §2). Administration, ouverte depuis Moi, RESTE
  une page-fenêtre au téléphone (un niveau, son dessin de la v5.55.1 : retour au-dessus du titre, titre = section). Retaper l'onglet courant remonte en haut. Depuis une aide, Moi et Sessions restent des fenêtres
  (l'accueil n'est pas à l'écran).
- **La rangée d'en-tête de l'accueil disparaît** (marque, Sessions, Créer, Moi) : « Sélectionner » à gauche et
  « ＋ Créer » à droite montent dans une **rangée du haut collante** de 52 px, au-dessus du **grand titre de
  34 px** (28 sous 360 px effectifs) qui est du contenu. Titre sorti par le haut, la rangée prend le petit titre
  de 17,5 sur fond de verre (`.pg-top.stuck`, IntersectionObserver) — la rangée ne change jamais de hauteur (C16).
- **Champ de recherche sous le titre**, puis **filtres en pastilles** : Tout · n, Accès direct, les collections,
  les catégories (point + nom). Les pastilles écrivent les mêmes crans que la colonne (`state.coll`, `state.cat`)
  et lisent la même liste de catégories (`homeCatGroups`, extraite de `homeSideHtml`). La rangée « Mes
  collections » du téléphone s'efface : les pastilles la remplacent.
- **Rechercher** : le rond (ou le champ sous le titre) fait paraître le dock de recherche existant (#homeDock,
  sa mécanique de clavier A192-A197 intacte) à la place de la barre ; champ vidé et quitté → la barre revient.
- **« Affichage »** (ranger, densité, catégories) monte sur la ligne du compte : au téléphone, sa porte était le
  bouton rond du dock, qui n'est plus là hors recherche.

**En large (≥ 780) et téléphone tourné** : le grand titre de **28 px** « Aides » ouvre la ligne du compte (maquette
tablette) ; la colonne gauche ne change pas.

**Feuilles du bas (A508)** : au téléphone, « Créer » (une page plein écran jusqu'ici) et « Affichage » (une fenêtre
centrée) deviennent des feuilles du bas à poignée, la grammaire de « Réglages de l'étape » et du menu ⋯ (A361) ; ✕,
le voile (A497) et la poignée TIRÉE vers le bas les ferment (`bindSheetDrag`, aussi sur « Réglages de l'étape »).
Un choix ne prend toujours pas toute la hauteur (92 % au plus).

**Pour tous** : la ligne du titre précède désormais le groupe « Accès direct » (avant : l'accès direct d'abord,
v5.19.1) — la maquette ouvre la page sur son titre.

**Pas encore fait (dit, pas tu)** : la colonne gauche du téléphone tourné (A513 §2 — il garde l'en-tête d'avant) ;
le dessin Natif de Moi et de Sessions (maquette « écran par écran » : lot des surfaces) ; le menu ⋯ ancré en large
avec son voile (A510 §5) ; le groupe « En cours » (A510 §6).

*Témoins réécrits sciemment* : `audit-retour` à 390 px (annoncé par A514) — Sessions et Moi sont des onglets sans
niveau, Administration une fenêtre d'un niveau qui ramène à l'onglet Moi ; `audit-doctrine` — la marque est absente de l'accueil en portrait et mesurée au téléphone tourné, la feuille de
filtres s'éprouve recherche ouverte, les page-fenêtres Compte/Sessions s'ouvrent depuis une aide. La barre de
navigation s'appelle `#tabNav` : `#tabBar` reste le nom PURGÉ de l'ancienne barre de filtre par type (M4).

## A518 — Lot 5 de la refonte : le verre clair et le moniteur Natif (v5.60.0)

**1. Capsule, quai et volets en verre clair, en thème clair (A503, A510 §1).** Les tokens de la matière système
(`--sys`, `--sys-ink`, `--sys-2`, `--sys-key`, `--ok-sys`, `--warn-sys`, `--crit-sys`, `--warn-sys-bg`…) sont
REDÉCLARÉS EN CONTEXTE sur `#cbTimers`, `.sd-in`, `.ds-card` et `.rt-dock`, thème clair seulement : verre ≈ 90 %
(`--glass`), flou, bord fin, ombre de flottaison ; encres et registres de la page (« -sys » à 1,6-2:1 sur fond
clair). `--sys` garde ses autres lecteurs. Repli opaque sans `backdrop-filter` et sous
`prefers-reduced-transparency`. Thème sombre : rien ne change. Mesuré au pixel (`audit-verre`, 16/16, pire 4,88:1).
Gardés tels quels, par décision antérieure et non par la maquette : le mot « Fin » en gris et son ■ rouge (C1) ; la
touche « Horodater » pleine en CREUX neutre, pas en bleu — un second bouton plein bleu à l'écran contredirait A375.
Sur le verre, le POULS de l'alarme (minuteur échu dans la capsule) ne fait plus varier l'opacité du texte — à 55 %,
« 00:00 » tombait à 3,4:1 (`audit-a11y`) : il passe sur l'aplat seul, porté par un pseudo-élément.

**Piège de sonde corrigé.** `audit-verre` lisait les fonds en `rgba()` ; `color-mix()` se calcule en
`color(srgb … / a)` : le verre sortait de la pile et le texte se mesurait sur le contenu brut (un faux 1,06:1, et
des verts qui ne prouvaient rien). La sonde lit désormais les deux ; sa preuve d'échec réimpose l'encre système
CLAIRE sous le verre clair (14/16 rouges).

**2. Le moniteur Natif (A509, planche validée).** Il reste un afficheur plein écran, lecture seule. Changent :
« ● Session » nomme le chrono vert (« ▲ Exercice » en exercice) ; « Revenir » est nommé dans une pilule de verre
(le toucher n'importe où ferme toujours) ; une barre de progression épaisse et NEUTRE sous le grand chiffre
(`--ink-2`, jamais bleue, A407) ; la mention ÉCHU en pastille ambre ; la bande devient une CARTE à rangées NOMMÉES —
le nom du minuteur en tête de sa rangée, l'étiquette ne porte plus que le temps (« dans 01:59 », « échu », A510),
« maintenant » au-dessus de sa ligne, « −2 min / +5 min » dessous, le passé estompé par rangée. Grand chiffre jusqu'à
220 px (tablette posée), plafond toujours pris sur la bande rendue (A341). Rangées de 36 px, 28 en paysage bas
(`monRangH`) — à 844 × 390 et texte 130 %, la carte de 36 px recouvrait le chiffre de 25 px (témoin). La garantie
de signes d'A511 (`MAXC`) part avec le nom de l'étiquette : 11 signes au plus.

**Pas encore fait (dit, pas tu)** : le menu ⋯ ancré en large avec son voile (A510 §5) ; le groupe « En cours »
(A510 §6) ; la colonne gauche du téléphone tourné (A513 §2) ; le dessin Natif des surfaces (démarrage, éditeur,
Sessions, Moi, Administration, Page — planche « écran par écran »).

## A519 — La session Natif : quatre arbitrages de l'auteur sur planche (lot 6, v5.61.0)

Planche « La session, l'app contre la cible » (01/11/2026) : captures de la v5.60.0 contre la cible « Étapes en
session Natif », même aide (ACR d'exemple), mêmes états. L'auteur a retenu les quatre recommandations.

1. **Étapes à plat, mot de registre sans fond (amende A345).** Plus de tuile `--amb-2` sous chaque étape : les
   étapes vivent à plat dans la carte du bloc, seule l'étape FAITE garde son aplat `--ok-soft`. CRITIQUE et
   VIGILANCE s'écrivent seuls, en couleur (`--crit`, `--warn`), sans pastille — le dessin des rappels du chapeau
   (A401). Le danger reste dit par le mot, la bordure de la case ronde et le préfixe lecteur d'écran (A345 garde
   ses trois canaux ; seul l'aplat de l'étiquette part).
   *Formes écartées* : retirer les tuiles en gardant la pastille ; garder l'actuel.
2. **Tête du bloc : la légende part, le numéro reste, discret (amende A345).** « sous l'étape, en gris : la réponse
   attendue » disparaît (la réponse se lit d'elle-même, en mono gris). Le numéro du bloc, qui le relie au parcours
   (A388), passe du carré noir à un numéro gris à côté de la pastille « En cours ».
   *Formes écartées* : retirer les deux (la cible à la lettre) ; garder les deux.
3. **En-tête de session : « Session » (amende A14).** Le sur-titre dit « SMUR · Session » (« Exercice » en exercice)
   au lieu de « ■ MODE CRISE » ; le discriminant (« adulte ») suit le nom ; le bouton ◐ de thème quitte l'en-tête
   pour le menu ⋯.
   *Formes écartées* : changer le mot en gardant ◐ dans l'en-tête ; garder l'actuel.
4. **Repères et jalon compacts (amende A397, A450).** Un repère du bloc tient sur une ligne : « △ Adrénaline —
   IV/IO » en ambre, la dose en mono dessous, l'état (« À préparer », « Fait ») à droite, sans icône ni chevron par
   repère. Le jalon d'une carte de décision passe AU PIED : « SI Chocs délivrés ≥ 3 ●●○ » et le raccourci
   ⚡ FV réfractaire.
   *Formes écartées* : repères seuls (jalon en tête) ; garder l'actuel.

**Déjà tranché et entrant dans le même lot** : la carte de décision perd son fond ambré (A513 §1, décidé mais jamais
codé — constaté sur la planche) ; étiquette d'une étape au seuil en aplat neutre sans filet.

**Témoins réécrits sciemment** : `audit-doctrine` (rangée de lecture à un contrôle au téléphone ; thème dans le
menu ⋯ d'une aide), `audit-verify-live` (décision courante : contour bleu et mot ambre, renverse v4.24.0),
`audit-exercice` et `audit-partage` (« ● Session » au sur-titre).

**Implémentation (v5.61.0).** `ol.steps li` sans fond, `.stp-mk` de registre sans aplat (gris une fois cochée) ;
`.stp-legend`/`.lg-it` PURGÉES (règle 14) ; « Bloc n » (`.ov-curn`) à côté de « En cours » et carré masqué
(`.ov-block.numin`), « ◆ Décision · bloc n » en ambre sur une décision courante ; sur-titre « ● Session » ;
`#hdrTheme` ne reste que sur une référence, `themeMenuRow()` dans le menu ⋯ d'une aide ; `jalonsHtml` : « SI »,
condition, jauge (`.mo-pips`), compte, texte de l'auteur dessous, et sur une décision le jalon est rendu APRÈS les
options (renverse l'ordre de la v5.5.0) ; repères : plus d'icône ni de chevron par rangée, nom ambre précédé de △,
état à droite en casse de phrase. **Écarté à l'implémentation, et dit** : la cellule de compteur de la capsule « nom
au-dessus » — A462 promet le nom ENTIER d'un compteur, et cette forme l'abrégeait (« ADRÉN. DO… ») ; elle reste
« valeur, puis nom sur deux lignes ». **Gardés** : « Fin » au mot gris (C1), « Horodater » en creux
(A375), « Parcours · x/y étapes » (A510), le pli « Fait · … », les sections du chapeau sous le bloc.

## A520 — Les surfaces Natif : quatre arbitrages de l'auteur sur planche (lots 7 à 11, à implémenter)

Planche « Les autres écrans, l'app contre la cible » (01/11/2026) : captures de la v5.61.0 contre la planche « Natif,
écran par écran ». L'auteur a retenu les quatre recommandations.

1. **Démarrage d'une aide en listes groupées (amende A330, A376).** Le chapeau quitte ses cartes repliables à icône :
   « Quand l'utiliser » et « Ne pas oublier » deviennent des listes groupées sous un intertitre en phrase ; les
   diagnostics à éliminer restent derrière leur lien repliable. L'état (« △ À relire ») passe dans la sous-ligne
   « ● SMUR · adulte · validée 01/2025 » au lieu d'un bandeau ; « Apprendre avec cette aide » devient une rangée ;
   « Page » (et « Schéma » au bureau) montent en haut ; au bureau, les minuteurs prêts sont des tuiles à droite.
   *Formes écartées* : garder les cartes repliables en ne changeant que la méta ; garder l'actuel.
2. **L'éditeur en rangées de réglages, en DEUX lots (amende A383-A384, A390, A441-A446).** D'abord l'HABILLAGE :
   grand titre « Modifier l'aide », Identité en rangées « Titre · valeur › », rappels en rangées à ✕, structure en
   liste à chevron, relecture en note ambre — sans toucher aux gestes d'édition. Ensuite la NAVIGATION : un bloc
   s'ouvre sur sa propre page ; au bureau, structure à gauche, schéma et relecture à droite.
   *Formes écartées* : tout d'un coup ; pas maintenant.
3. **Sessions en rangées groupées par jour.** Une rangée par session (titre, heure · durée · n/m étapes, chevron)
   sous « Aujourd'hui », « Cette semaine »… ; Rouvrir et Compte-rendu passent dans le détail ouvert d'un tap ;
   « Sélectionner » en haut de l'onglet.
   *Formes écartées* : rangées avec actions visibles ; garder les cartes.
4. **Administration au bureau en liste et fiche (amende A494-A495).** Onglets en segmenté ; au bureau, la fiche d'un
   compte s'ouvre à côté de la liste au lieu d'une page de plus. Au téléphone, rien ne change.
   *Formes écartées* : segmenté seulement ; garder l'actuel.

**Proposés sans question (même grammaire qu'A516)** : Moi en rangées groupées, intertitres en phrase ; la Page en
feuille centrée sur fond gris, zoom en segmenté, Imprimer et Exporter en PDF dans sa barre.

**Ordre des lots** : 7 démarrage, 8 Sessions et Moi, 9 éditeur (habillage), 10 éditeur (navigation), 11
Administration et la Page. Chaque lot se compare à sa planche avant commit (maquette · avant · après).

**Lot 7 implémenté (v5.62.0) — le démarrage.** `foldCardHtml(…,{flat:true})` rend « Quand l'utiliser » et « Ne pas
oublier » en listes groupées sous un intertitre (`.fold-card.flat`, `.pre-lh`), sans porte de repli avant la session
(en session, la carte repliable est inchangée) ; la méta est UNE sous-ligne « ● SMUR · adulte · ACR · validation »
suivie des états en pastilles achromatiques (`.read-disc` ; `.read-sub` PURGÉE ; bandeau « À relire » retiré) ;
« Apprendre avec cette aide » devient une rangée de travail (plus de hachures) ; « Page » et « Schéma » montent dans
l'en-tête (`#hdrPage`, `#hdrSvg` dès 780 ; au téléphone, Schéma reste dans le menu ⋯) et `preLinksHtml` ne garde
que les documents ; au téléphone, la catégorie quitte le sur-titre avant la session (elle est dans la sous-ligne) ;
les objets prêts deviennent des tuiles « Prêts pour la session » (nom, valeur de départ en mono, « au démarrage » /
« à lancer »). Témoins réécrits sciemment : `audit-doctrine` (écran d'entrée : Page et Schéma dans l'en-tête, 44 px
de cible avec halo ; Schéma par le menu au téléphone), `audit-consulter` (les deux listes sont toujours ouvertes).

**Lot 8 implémenté (v5.63.0) — Sessions et Moi.** `renderSessHist` : une rangée par session (`.sess-main` : point de
catégorie, titre, « heure · durée · n étapes cochées », chevron) dans des groupes par jour (« En cours »,
« Aujourd'hui », « Hier », « Cette semaine », puis le mois) ; un tap ouvre le détail (`_sessOpen`) qui porte
Rouvrir · Compte-rendu · Supprimer (en mots, 44 px) ; une session vive garde « Reprendre » à vue ; les exercices
restent dans leur groupe (v4.27.0). `.sess-k`/`.sess-kd` purgées (règle 14). Moi : intertitres en phrase, groupes
sans ombre ; la collection « Accès direct » ne dit plus « les tuiles de l'accueil » (purgées en A515) mais « en tête
de l'accueil ». **Non fait, et dit** : « Sélectionner » en haut de l'onglet Sessions — l'app n'a pas de sélection
de sessions ; l'ajouter serait une fonction nouvelle, pas un habillage.

**Lot 9 implémenté (v5.64.0) — l'éditeur, habillage.** Grand titre « Modifier l'aide » (« Nouvelle aide » à la
création, 24) ; « ▶ Essayer » garde son mot au téléphone (il passait au glyphe seul sous 430 px, contre la règle
« jamais un libellé réduit au glyphe ») et c'est l'état « À relire » qui quitte l'en-tête étroit ; les listes
(chapeau « Ne pas oublier », condition d'entrée : critères, diagnostics à éliminer) deviennent des intertitres en
phrase au-dessus de groupes de rangées (`.le-grp`), l'ajout en dernière rangée en lien bleu, ✕ ronds, la consigne
des 4 rappels en note SOUS le groupe (`.le-foot`) ; libellés de section en phrase ; cartes sans ombre. Gestes
d'édition inchangés. **Laissé au lot 10** : Identité en rangées « Titre · valeur › » (un champ s'ouvre sur sa page),
les blocs, la colonne de structure et le schéma.

## A521 — L'éditeur se parcourt : Identité en rangées, structure en liste, un bloc sur sa page (lot 10, v5.65.0)

*Amende A390 (la structure n'est plus un dépliant collant sous 1200 px) et K4 (le dépliant « Identité »).*

1. **Identité en rangées.** Replié, le sommaire de `details.ed-ident` est un groupe de trois rangées sous
   l'intertitre « Identité » : *Titre · valeur*, *Code court · valeur* (« — » s'il manque), *Catégorie · ● nom ›*.
   Ouvert, il n'est plus qu'un en-tête « Identité · Replier » au-dessus des champs, inchangés.
   **Écart à la maquette, assumé** : la maquette ouvre chaque champ « sur sa page » ; ici, un tap sur une rangée
   déplie les champs sur place. Une page par champ coûtait une navigation de plus par champ pour l'auteur qui
   remplit une aide neuve (titre, discriminant, catégorie, bibliothèque, code, validation, état d'affilée) — et
   ouvrait sept niveaux de retour. À rouvrir si l'auteur le demande.
2. **Structure en liste dans le fil (< 1200 px).** Après « Ne pas oublier » : intertitre « Structure · n blocs »,
   une rangée par bloc (numéro en carré — ambre pour une décision —, titre, sous-ligne « n étapes » /
   « Décision · n branches » / « Revue · n éléments », chevron), puis les complications « À tout moment ». Le schéma
   du téléphone (`.flow-prev`) suit la liste. `edTocHtml` et le CSS `.ed-toc*` sont PURGÉS (règle 14).
   ≥ 1200 px, la colonne `.ed-struct` prend le même dessin (intitulé en phrase, rangées sur deux lignes sans
   filet, bloc ouvert surligné, numéro plein).
3. **Un bloc s'ouvre sur sa page.** Une rangée de structure ouvre le bloc seul (`state.edFocus`,
   `edFocusSet`/`edApplyFocus`). Le DOM de l'éditeur reste ENTIER — deux classes sur `<body>` masquent le reste :
   `ed-ov` (vue d'ensemble : « Prise en charge » se retire, les blocs sont dans la liste) et `ed-focus` (seul le
   bloc `.ed-cur` reste, avec la porte « Ajouter »). Ainsi glisser, porte, relecture, réglages ne changent pas.
   - C'est un niveau du retour système (`_H_LAYERS`) et du « ‹ Retour » de l'en-tête : on revient à l'aide.
   - Ce qu'on amène à l'écran reste visible (`edReveal`) : une remarque de relecture, un rappel « → » ou un
     objet créé par la porte ouvre la page de son bloc ; hors bloc, on revient à l'ensemble.
   - En mode « prendre / poser », TOUT est montré (on pose ailleurs que là où l'on a pris).
   - Les revues (`kind:'review'`) ne vivent pas dans « Prise en charge » : leur rangée amène à la section Revues.
   *Formes écartées* : re-rendre l'éditeur en n'émettant que le bloc (chaque geste aurait à connaître le mode) ;
   une fenêtre par bloc (règle : pas de modale pour écrire ce qui est le cœur de l'aide).

## A522 — Administration au bureau et la Page, à la maquette (lot 11, v5.66.0)

*Applique A520 §4 (Administration) et la Page « proposée sans question » ; amende A494-A495 (dessin des onglets) et
le chrome de la feuille Page (`#planModal`).*

1. **Administration.** La liste et la fiche côte à côte existaient déjà (`.adm-split`, dès 900 px de vue) : le lot
   n'en change que l'habillage. Les sections deviennent un **segmenté** (piste grise, cran courant blanc, compte en
   gris — en bleu pour « À traiter ») ; les intertitres (`.adm-sh`, `.adm-grp`) passent **en phrase** ; le statut
   d'un compte est une **pastille** (ambre « En attente », grise sinon) ; l'en-tête de la fiche (avatar, e-mail)
   devient une carte. Au téléphone, rien ne change de place.
   **Non repris de la maquette, et dit** : les cercles de sélection sur chaque rangée (la sélection reste derrière
   « Sélectionner », A475) et la disparition de l'icône de compte en tête de rangée (rangée de menu partagée).
2. **La Page.** La barre porte, dans l'ordre : **« Fermer »** en mot à gauche (était « × » à droite), le titre,
   l'échelle en **segmenté** (Ajusté · − · % · + · 1:1, déplacée hors de la feuille — `svApplyZoom` lit la valeur
   dans la barre), puis **Imprimer** et **Exporter en PDF**. La feuille est **centrée sur un fond gris**, ombrée.
   L'annonce « la feuille dépasse à droite » sort de la piste et passe sous la barre.
   - Les deux boutons ouvrent le même dialogue d'impression du système (qui propose l'enregistrement en PDF) —
     c'est déjà le cas de « Exporter en PDF » du menu ⋯. Deux mots pour un geste, gardés parce que la maquette les
     nomme ainsi et que l'utilisateur cherche l'un ou l'autre ; **à arbitrer** si l'auteur préfère un seul bouton.
   - Au téléphone (`html.zw560`), Imprimer et Exporter se retirent de la barre : ils restent dans le menu ⋯.
   - Vérifié : imprimer la Page ouverte sort la Page seule (barre et fenêtre absentes du PDF).

## A523 — Le groupe « En cours » en tête de l'accueil (v5.67.0)

*Applique A510 §6 ; amende A355-A356 (carte sombre « Session en cours » de l'accueil) et A506 (liseré vert).*

Une aide dont la session est DÉMARRÉE (`sessionLive`) quitte sa section du répertoire et monte en tête, dans un
groupe « En cours » (`.dir-book.live-grp`), avant l'Accès direct : même rangée que partout, et l'état dit
« ● Session 04:12 » en vert (le chrono vivant de `paintDirLive`). Le groupe montre TOUTES les sessions vives, quel
que soit le filtre posé (la carte les montrait toutes) ; il se retire en sélection, et la recherche garde ses
résultats. L'Accès direct garde la rangée (un raccourci ne déménage rien, A515).

La carte sombre « Session en cours » (chrono, « Reprendre », « Terminer », ligne « Bloc n · … ») est retirée pour une
aide de la liste : elle doublait la rangée. **Ce qu'on perd, et dit** : « Terminer » depuis l'accueil — il reste à
un tap, dans la session (« Fin » du quai). La carte d'une session **partagée** (invité, miroir) reste : ce n'est pas
une aide du répertoire. Purgés (règle 14) : `.ls-w`, `.ls-chrono`, `.ls-end`, `data-openlive`, `data-endlive`, le
battement `data-lschrono`. Le point vert devient un élément (`.dl-dot`) : en vue détaillée, `::before` porte déjà
le séparateur « · » et l'écrasait en trait.

Témoin : `audit-doctrine` « Accueil · A523 groupe « En cours » » (390 et 1280 ; vérifié capable d'échouer).

## A524 — Une seule recherche au téléphone : le rond (v5.67.1)

*Amende A517 (« champ de recherche sous le titre ») ; garde A510 §3. Arbitrage de l'auteur, 01/11/2026.*

Signalé par l'auteur : « deux barres de recherche, dont une totalement inutilisable — celle du haut renvoie à celle
du bas ». La maquette montrait les deux ; A510 §3 voulait la saisie AU-DESSUS du clavier (à portée du pouce) : le
champ sous le titre n'était donc qu'un leurre qui ouvrait le dock du bas. **Retenu : le rond seul** (barre
d'onglets, `#tbSrch`) — un seul endroit, toujours visible, le modèle d'iOS 26. `.pg-srch` et son geste
`[data-tbsrch]` sont PURGÉS (règle 14).
*Forme écartée* : garder le champ du haut en vrai champ et retirer le rond (plus visible, mais en haut de liste et
loin du pouce).

Avec : l'état vivant d'une rangée (« ● Session ») ne prend plus le séparateur « · », qui restait seul en début de
ligne à la coupure au téléphone — le point vert sépare déjà.

Témoin : `audit-doctrine` « Accueil · A523 …, A524 une recherche » (vérifié capable d'échouer).

## A525 — Le menu ⋯ ancré pose un voile transparent, en large (v5.68.0)

*Applique A510 §5 (et A497).* Au-delà de 780 px, le menu ⋯ reste ancré à son bouton (A508, A361 au téléphone
inchangée), mais il se fermait au clic du document SANS l'arrêter : le tap de fermeture cochait l'étape dessous —
mesuré en session à 1280 px. Il gagne un voile **transparent** (`.popmenu-veil.anchor`, `z-index` 19) : sous
l'en-tête (20) qui porte le menu, au-dessus du contenu, de la capsule (15-17) et du quai (18). Le tap tombe sur le
voile, le menu se ferme, rien dessous ne bouge ; le voile part avec le menu. Témoin : `audit-doctrine` « Session ·
A525 » (vérifié capable d'échouer : l'étape se cochait).

## A526 — Un téléphone tourné prend la colonne gauche, quelle que soit sa largeur (v5.68.0)

*Applique A513 §2.* L'iPhone SE tourné (667 × 375) n'avait ni onglets (retirés en paysage bas, A511) ni colonne
(réservée à ≥ 780 px). La condition « accueil large » devient UNE liste de media queries, partagée par le CSS et
`mqHomeWide` : `(min-width:780px), (orientation:landscape) and (max-height:499.98px)` ; les règles propres au
téléphone en portrait prennent son complément. `tabNavOn` ne lit plus que `mqHomeWide`. Sept blocs de l'accueil
seulement (coque, dock de recherche, pied, carte partagée, « Créer », « Affichage ») : la lecture et la session
gardent leurs règles de paysage bas (A511).
*Écart mesuré, accepté* : à 667 px la colonne (255 px) laisse 412 px à la liste — le compte « 2 aides · 2 à relire »
se tronque à côté du titre, comme sur un iPad étroit. Témoin : `audit-doctrine` « Accueil · A526 » (667 × 375 et
375 × 667 ; vérifié capable d'échouer).

## A527-A529 — Trois arbitrages de forme, tranchés par l'auteur sur planche (v5.69.0)

Planche « Trois arbitrages Natif » (état actuel contre proposition, captures de l'app servie) ; l'auteur a retenu les
trois propositions (« B partout »).

**A527 — Seul le protocole dit sa nature (amende A516, A338).** La rangée d'une aide n'écrit plus « Aide » : c'est le
cas courant, le mot se lisait sur presque toutes les rangées sans rien apprendre. Le protocole, l'exception, garde
« Protocole » en tête de sa sous-ligne ; la vue « Tout » distingue toujours les deux. `dirKindHtml('f')` rend vide.
*Forme écartée* : « Aide » sur chaque rangée (demande antérieure de l'auteur, qu'il lève ici).

**A528 — « Affichage » en tête des pastilles, au téléphone (amende A517).** La ligne « n aides · n à relire  ·
Affichage » sous les pastilles disparaît en navigation par onglets ; « Affichage » (ranger, densité, catégories)
devient la PREMIÈRE pastille, même id `#rangBtn` (un seul câblage). « Tout · n » dit le compte. Ce qu'on perd, et
dit : le total « à relire » d'un coup d'œil au téléphone (chaque rangée garde son « △ À relire ») ; en large rien
ne change. *Forme écartée* : garder la ligne.

**A529 — Un seul bouton d'impression dans la Page (amende A522).** « Imprimer » et « Exporter en PDF » ouvraient le
même dialogue du système : un bouton « Imprimer ou PDF ». *Forme écartée* : deux boutons, fidèles à la maquette.

Témoins : `audit-doctrine` « Accueil · … A528 », « Page · A529 », et la nature des rangées réécrite (« chaque
protocole dit « Protocole », une aide ne porte pas de mot ») ; vérifiés capables d'échouer.

## A530-A533 — Remesure complète de la refonte (v5.70.0)

Demande de l'auteur : une fois les lots finis, tout remesurer. Méthode : une sonde sur 13 écrans × 18 formats
(iPhone SE 1 et 2, 390, 430, Galaxy Fold plié 344 et déplié 882 × 1104, Surface Duo simple 540 et double 1114,
téléphones tournés 667/844/932, iPad mini, Air portrait et paysage, 1024, 1280, 1440, 1920) : débordement horizontal,
éléments hors écran, texte rogné, polices < 11 px, cibles, chevauchements de contrôles réellement atteignables
(test de l'élément au point), erreurs de console ; puis, au bureau, chaque contrôle survolé (avant / après, parents
compris) et l'inventaire des transitions ; enfin des planches-contacts relues écran par écran.
**Résultat** : 0 débordement, 0 police < 11 px, 0 erreur de console ; transitions cohérentes (0,12-0,15 s pour les
états, 0,25 s pour les étapes, 0,3 s pour la pastille glissante, toutes coupées sous « réduire les animations »).
Corrigé :

**A530 — Tout ce qui se clique répond au survol ; une rangée ne se soulève plus (étend A506).** 15 contrôles au
curseur « main » restaient inertes (survol absent, ou égal au repos) : « Affichage », « Sélectionner », « Vérifier »,
« Gérer », « Tout déplier », renvois du parcours, têtes de cartes repliables, « Rejoindre une session », bascules son
et veille, « Identité », « À compléter »… Grammaire unique : bouton gris → un cran plus sombre, lien bleu → souligné,
rangée → teinte. Le soulèvement au survol (`translateY` + ombre) quitte toutes les rangées (colonne gauche, palette,
relecture, documents, versions) ; seule la porte « Ajouter », qui flotte, le garde. La pastille « À compléter » de
l'écran de démarrage reçoit un halo de 44 px (rien au-dessus à disputer, contrairement à la liste).

**A531 — Intertitres et étiquettes en phrase, partout (étend A516-A520).** Restaient en petites capitales espacées :
les intertitres des colonnes (« PARCOURS », « MINUTEURS », « COMPTEURS », « JALONS », « BIBLIOTHÈQUE »,
« COLLECTIONS », « CATÉGORIES »), « À TOUT MOMENT », « PARCOURS » en tête de la session, les intertitres et étiquettes
de l'éditeur (« ÉTAPES », « ÉTAPE SUIVANTE », « MINUTEURS », « NOM COURT », « DURÉE », « CONTEXTE LOCAL »,
« SCHÉMA — APERÇU »), « ADRESSE E-MAIL », « J'AI COMPRIS », l'intertitre du menu ⋯ et ceux de la feuille
« Affichage ». **Restent en capitales, à dessein** : les MOTS D'ÉTAT (« Critique », « Vigilance », « ● Session »,
« En cours », « Ici ») — registre ECAM, A345 — et l'eyebrow de l'en-tête ; la Page (document imprimé) garde sa typo.

**A532 — Téléphone tourné : le titre garde sa place.** À 844 et 932 px de large, l'en-tête portait titre + Page +
Schéma + ⋯ + compte, et le titre tombait à « Arrêt car… ». En paysage bas, « Schéma » quitte l'en-tête comme au
téléphone en portrait (il est dans le menu ⋯). Sous 360 px, l'état « Avant la session » passait sous « Page » et se
coupait net : il se retire (un état, pas une alerte ; le grand titre et « Confirmé — démarrer » le disent).

**A533 — Le grand chiffre du moniteur grandit en portrait (précise A341).** Borné par `min(20vw, 32vh)`, il restait
à 164 px sur un iPad en portrait (78 px sur un iPhone) avec une hauteur libre immense. 28 vw : 220 px (le plafond)
sur iPad, 109 px sur iPhone ; il tient en largeur jusqu'à 320 px, et `--mon-vmax` (bande, A232) reste le garde-fou.
Le segmenté d'Administration reste sur UNE ligne (défilable) au lieu de se replier dans sa piste à 667 px.

**Vérifié et laissé** : les chevauchements relevés sont des barres flottantes au-dessus du contenu (voulu ; le bas de
page reste atteignable au-dessus d'elles) ; l'anneau d'ouverture d'une fenêtre ouverte par script (A492 : au doigt,
le focus va au titre) ; la césure de « Caté-gorie » / « Biblio-thèque » sous 430 px (A460) ; « Cochez les étapes
restantes (4) » sur trois lignes à 320 px (libellé entier, A465).
Témoin : `audit-doctrine` « Remesure · A530-A533 » (vérifié capable d'échouer : 5 rouges sur l'avant).

## A534 — Conformité aux maquettes : les trois écarts sans décision (v5.71.0)

Contrôle demandé par l'auteur (« on est bien conforme aux maquettes ? ») : chaque maquette Natif posée à côté de
l'app servie au même format. Les écarts restants étaient tous tranchés (A515 étoile, A524 recherche, A527-A529,
A422 états achromatiques, A510 pas de « Bloc n sur 4 », A375 « Horodater », A462 compteur dans la capsule), sauf
trois, corrigés ici :

1. **La colonne « Parcours » (démarrage et session, ≥ 780 px) devient une liste légère** (amende A388 pour le seul
   habillage) : numéro sur carré gris, bloc courant en teinte bleue (numéro plein, titre bleu) SANS cadre, décision
   SANS aplat ambre — son losange chiffré et ses branches « Oui ↓ 3 · Non ↓ 4 » portent le registre —, chevron
   discret (plein au survol). La mécanique d'A388 est intacte (repli, « Ici », branches visibles, réglages en mots).
   La carte de l'écran d'entrée et la feuille « Se repérer » gardent leur dessin.
2. **Le bouton fermé dit « Cochez les 3 restantes »** (« Cochez la restante » au singulier), les mots de la maquette
   — même cause dite (A235), une ligne au lieu de deux (`cochezLbl`).
3. **La colonne gauche dit le compte de ses sections** : « Aides n », « Sessions n » (si l'historique n'est pas vide).

Les trois détails d'habillage du rail droit, d'abord laissés, sont repris en A535 à la demande de l'auteur.

## A535 — Le rail de session au dessin de la maquette (v5.72.0)

Demande de l'auteur après A534. Dans le rail droit de la session (≥ 1200 px) :
- **compteur « − 1 + »** : la valeur entre ses deux boutons (`.cn-ctrl` en `display:contents`, ordre posé en CSS ; le
  DOM et les cibles de 44 px ne changent pas) ;
- **carte de minuteur en aplat gris** (`--amb-2`), sans filet — l'échu garde son filet ambre ;
- **jalon** : la condition, sa jauge à points (celle des étapes au seuil, A474), le compte, et le texte de l'auteur en
  sous-ligne « → … ». Le △ de tête part (déjà retiré de la colonne en A388).
Témoin : `audit-doctrine` « Session · A535 » (vérifié capable d'échouer).

## A536 — Les bords au téléphone : barre collante pleine largeur, « Fermer » de la Page, bande de Safari (v5.72.1)

Signalé par l'auteur sur iPhone (Safari 26, navigation privée), deux captures : « problème largeur en haut, problème
couleur fond en bas ». Reproduit en WebKit et dans Safari du simulateur iOS 26.5.

1. **La barre collante de l'accueil s'arrêtait à 8 px du bord droit.** Elle déborde de `main` de 18 px de chaque côté
   (`margin:0 -18px`), mais `.home-main` garde à droite la réservation de 8 px du rail A→Z (C53) : le verre finissait à
   422 px sur 430, et le gris de la page passait dessous. Le fond traverse maintenant les 26 px (`margin-right:-26px`) ;
   la réservation reste, et « Créer » reste aligné sur le bord des cartes (`padding-right:26px`).
2. **« Fermer » de la Page était collé en haut et contre le titre.** La règle générique `.ai-card .ai-x` lui donnait
   `margin:-10px -10px -10px 0` (le × d'un dialogue). `.pm-close` remet `margin:0` : 10 px d'air en haut, 12 px avant
   le titre.
3. **La bande du bas de Safari prenait la couleur de ce qui restait sous la feuille.** Safari 26 teint sa barre
   d'outils avec l'élément FIXÉ qui touche le bas de la fenêtre, même entièrement couvert : sous la feuille « Page »,
   c'était le bouton bleu « Démarrer » du quai (bande bleu marine), ou la bulle sombre du guide. Une feuille opaque
   (`.sheet-full`, classe `modal-full`) masque désormais l'app et la bulle du guide (`visibility:hidden` sur `.app`,
   `#gdTip`, `#gdVeil`) : la bande prend la couleur de la feuille. Le verrou est levé AVANT le retour du focus
   (`_bgUnlock` puis `focus()`), donc l'élément d'origine est déjà visible quand il le reçoit. `#alerts` et `#srLive`
   sont hors de `.app` : les annonces continuent.

*Formes écartées* : remettre les boutons symétriques à 18 px des bords (« Créer » se décalait de 8 px par rapport aux
cartes) ; supprimer la réservation de 8 px (C53 : sous 6 px, le fond du rail peint sur les rangées).
Non reproduit : une différence de couleur en bas de l'accueil seul (la bande y a la couleur de la page, mesurée sur la
capture : 242,246,247 partout).
Témoin : `audit-doctrine` « Bords · A536 » (vérifié capable d'échouer : 3 rouges sur l'avant).

## A537 — La vue compacte au dessin Natif, l'accès direct en tuiles, « Affichage » aligné (v5.73.0)

*Amende A517 (« la vue compacte garde sa ligne unique ») et A338 ; renverse A515 §4 (épinglées en rangées) ; décisions
de l'auteur sur planches, 01/11/2026.*

1. **La vue compacte n'avait pas suivi la refonte.** Mesurée : bande grise d'intertitre dans une boîte à bord,
   « PROTOCOLE » en capitales, et au téléphone des rangées PLUS hautes que la détaillée pour une aide courte (64 px
   contre 53). Elle prend désormais le groupe, l'intertitre et la rangée de la détaillée (les règles
   `.dir-book:not(.compact)` du groupe deviennent `.dir-book`) et ne s'en distingue que par une **hauteur fixe** :
   - **sous 1200 px effectifs** (palier `zw1200`, règle 10) : deux lignes serrées, **52 px**. Le titre sur une ligne,
     coupé à la lettre (`white-space:nowrap` + ellipse : `-webkit-line-clamp:1` coupait au mot, « Limitation et arrêt
     des… » suivi de vide) ; la méta sur une ligne, en 12 : nature, discriminant, état. Rangée par catégorie
     (classe `by-cat` sur le livre), la catégorie part — l'intertitre la dit ; le nombre de PDF part toujours.
   - **à partir de 1200 px** : une ligne de **44 px**, la méta entière calée à droite en 13,5.
2. **L'accès direct en tuiles**, plusieurs par ligne, à toutes les largeurs et quelle que soit la densité (le livre
   `pinned` ne prend plus la classe `compact`). Grille `repeat(auto-fill, minmax(min(50% − 4px, 200px), 1fr))` :
   deux tuiles au téléphone, autant que la largeur en tient au-delà. Une tuile dit le **titre** (trois lignes au plus),
   la **catégorie avec son point**, puis l'**état** — ni nature ni discriminant. Au téléphone, **pas d'étoile** sur la
   tuile (elle prenait le tiers de la largeur) : l'aide reste dans la liste, où l'étoile la retire ; césure des mots
   longs au téléphone seulement.
3. **« Affichage » et « Sélectionner » à la même hauteur** en large : la ligne du titre aligne titre et compte sur la
   ligne de base, et « Affichage », dans son enveloppe `.rang-wrap`, tombait 3 px plus haut. Les deux boutons sont
   centrés ensemble (`align-self:center`).

Vérifié : la vue détaillée est inchangée à 320, 402, 820 et 1280 px (chaque boîte comparée avant/après ; seule la
liste remonte de 3 px avec la ligne du titre) — deux règles mortes de la détaillée (`margin-top:4px`,
`.dir-disc{order:-1}`), qui reprenaient la main une fois les sélecteurs simplifiés, sont retirées (règle 14).
*Formes écartées* : la compacte sur une ligne au téléphone (titre réduit à « Limitation et… ») ; supprimer la
compacte ; une tuile avec étoile au téléphone ; la nature et le discriminant sur la tuile.
Témoin : `audit-doctrine` « Accueil · A537 » (vérifié capable d'échouer : 8 rouges sur l'avant).

## A538 — La recherche du bas à la hauteur de la barre d'onglets (v5.73.0)

*Précise A423 (filtre et champ en L 44) sous la navigation par onglets (A513) ; signalé par l'auteur, 01/11/2026.*

Au téléphone, la recherche REMPLACE la barre d'onglets (même bas, 12 px + zone sûre), mais elle tombait de 62 à 44 px
de haut, filtre compris : la barre rétrécissait au tap. Clavier fermé, le champ et le cercle du filtre prennent la
hauteur de la barre d'onglets (62). Clavier ouvert, le dock compact d'A423 reste (44) : il loge le champ au-dessus du
clavier, dans une bande opaque où la hauteur se compte.

**Contraste du dock en thème sombre (mesuré sur capture, WebKit 402 px)** : libellés sur le verre 13,4:1, libellé
actif sur sa pastille 9,3:1, contour de la barre `--ctl-line` sur le fond ≈ 4:1 (le verre lui-même ne se détache du
fond qu'à 1,19:1 : c'est le contour qui borde la barre, comme prévu par A423). Point faible relevé, non tranché ici :
la pastille de l'onglet actif ne se détache de la barre qu'à 1,2:1 (1,15:1 en clair) ; l'état actif tient à la
couleur du libellé et à cette pastille.
Témoin : `audit-doctrine` « Accueil · A538 » (vérifié capable d'échouer).

## A539 — L'onglet actif en pastille pleine ; l'avatar et le point vivant bordés (v5.73.0)

*Amende A513 (pastille grise de la maquette) ; choix de l'auteur sur planche (« pastille pleine »), 01/11/2026.*

Mesuré sur captures (WebKit 402 px) : la pastille grise de l'onglet actif ne se détachait de la barre qu'à 1,2:1 en
sombre (1,15:1 en clair) — sous le 3:1 d'un repère d'état (WCAG 1.4.11) ; l'état tenait à la couleur du libellé,
proche de celle des autres. Écartées sur planche : un libellé gras avec une pastille grise plus franche (1,4:1) ; une
pastille bleue translucide (1,6:1) — toutes deux grisaient aussi les autres onglets. **Retenu : pastille PLEINE**
(`--act`, libellé `--on-primary`) : 7,8:1 en sombre, 9,3:1 en clair ; les autres libellés gardent leur encre. Le bleu
y dit « où l'on est », ce que la règle 8 lui confie.

Mesuré ensuite CONNECTÉ (signalé par l'auteur : « Moi » change) : le disque de l'avatar se perdait dans la barre
(1,06:1 en sombre, 1,18:1 en clair ; les initiales, elles, passent à 7,8 et 9,3:1) → filet intérieur `--ctl-line` ;
le point vert de session en cours, sur la pastille pleine de « Sessions », tombait à 1,2-1,7:1 → anneau de 2 px
dans la teinte de la barre, comme la pastille de synchronisation.
Témoin : `audit-doctrine` « Accueil · A539 » (vérifié capable d'échouer).

## A540 — La barre collante de l'accueil passe en verre dans l'app installée ; la piste « default » mesurée sur iOS 27

*Signalé par l'auteur sur iPhone (app installée, thème sombre, 01/11/2026) : « Sélectionner » et « Créer » chevauchent
le grand titre « Aides » puis les pastilles, sur une barre restée transparente.*

**Cause.** La barre collante prend son verre (`.stuck`) quand le grand titre passe sous elle ; l'observateur retranche
la hauteur de la barre ET l'inset haut (`--sat`). Ce dernier se lisait par `getPropertyValue('--sat')`, qui rend le
TEXTE du token (`calc(env(safe-area-inset-top) + var(--ios27-top))`) : `parseFloat` y lit 0. Dans un navigateur
l'inset vaut 0 et rien ne se voyait ; dans l'app installée (inset ≈ 59 + 16 px) le verre ne venait qu'une fois le
titre passé sous l'HEURE — entre-temps, boutons transparents sur le titre puis sur les pastilles. Même lecture
fausse de `--sab` en deux endroits (hauteur du menu ⋯, ancrage du dock) : `--sab` est un `env()` nu, même défaut.
**Correctif.** `insetPx(tok)` résout un token d'inset en px (un `padding-top:var(--tok)` mesuré), aux trois lectures.
Et le verre vient dès que le titre COMMENCE à passer sous la barre (`intersectionRatio < 0,99`), plus seulement
quand il en est sorti. Vérifié dans l'app installée au simulateur iOS 27.0 (iPhone 17) : à mi-défilement la barre
porte le verre et le petit titre « Aides », les pastilles passent dessous.

**La piste du fil Reddit (« le flou ne touche que `black-translucent` ; avec `default`, un vrai élément fixé de 1 px
en haut donne sa couleur à la barre d'état »), MESURÉE** au même simulateur, sur une copie installée à part
(`default` + `<div>` fixé de 1 px à `--amb`) : la bande de la barre d'état prend bien la couleur de la page à
l'accueil (244,245,247, comme la page ; blanche sur l'écran de bienvenue) ; mais le contenu reste FLOUTÉ sous la
bande, au repos (première ligne de la notice d'accueil), et l'app n'est pas écrite pour un inset haut nul
(A370 §4). Le même fil note que `prefers-color-scheme` est figé par processus en app installée : la bande garderait la
couleur du thème de l'ouverture. **Non retenu** : `black-translucent` reste, avec le sol et la descente d'A370-A373.
Témoin : `audit-doctrine` « Accueil · A540 » (inset de 75 px simulé SOUS FORME DE CALC ; vérifié capable d'échouer).

## A541 — Au téléphone, l'accueil réserve la barre d'état, même page au repos (v5.73.2)

*Signalé par l'auteur sur iPhone (app installée) : « tous les écrans sont tronqués en haut, même non défilés ».
Précise A517 (navigation par onglets) et A373.*

**Cause.** En navigation par onglets, l'en-tête de l'accueil est vidé (`header.bar` réduit à 0 : recherche et onglets
deviennent flottants). Il portait la RÉSERVE de la barre d'état (`calc(12px + var(--sat))`) : à 0, l'accueil, Sessions
et Moi commençaient à y = 0, sous l'heure, et la barre collante (collée à `--sat`) recouvrait le grand titre et les
pastilles, page AU REPOS. Rien ne l'a vu : en navigateur l'inset vaut 0, et dans les mesures la bannière système
(`#sysBanner`, 99 px) occupait justement cette place — c'est elle qui a masqué le défaut en A540.
**Correctif.** L'en-tête vidé garde sa réserve : `padding-top:calc(var(--sat) / var(--zf,1))`, rien d'autre. Vérifié
dans l'app installée au simulateur iOS 27.0 (thème sombre) : au repos, « Sélectionner »/« Créer », le grand titre et les
pastilles sont sous l'heure, visibles ; Moi idem ; en navigateur, rien ne bouge (inset 0).
La planche « une seule bande » (bande sous l'heure teintée comme la barre une fois collée) reste à trancher par l'auteur.
Témoin : `audit-doctrine` « Accueil · A541 » (accueil, Moi, Sessions, sans bannière ; vérifié capable d'échouer : 3 rouges).

## A542 — Une seule bande en haut une fois défilé (v5.73.3)

*Amende A370 (sol opaque couleur de page) ; choix de l'auteur sur planche (« Oui, une bande »), 01/11/2026.*

Une fois l'accueil défilé, deux bandes s'empilaient : le SOL sous l'heure (couleur de page, A370) puis la barre collante
en verre, plus claire — le contenu semblait coupé au bas du sol. Quand la barre est collée (`.stuck`), le sol prend
SA teinte : `color-mix(--work 90 %, --amb)`, le verre de la barre posé sur la page. Une seule bande, de l'heure au bas
de la barre, comme une barre de navigation iOS. Au repos, le sol reste couleur de page. Le sol reste OPAQUE : le flou
qu'iOS 27 pose sur le bord haut reste invisible (A370). *Formes écartées* : retirer la descente de 16 px d'A373 (les
deux bandes restaient) ; garder deux bandes.

## A543 — La barre d'onglets au bas d'iOS (v5.73.3)

*Précise A517 et A538 ; signalé par l'auteur : « le dock n'est-il pas un peu haut ? ».*

Mesuré au simulateur iOS 27.0 (iPhone 17, app installée) contre la barre d'onglets de Photos : la nôtre finissait à
47 pt du bord bas (12 px + zone sûre de 34), celle d'iOS à 23 pt — une barre d'onglets native descend DANS la zone de
la barre d'accueil. Un token unique `--tb-bot: max(12px, var(--sab) − 10px)` place la barre d'onglets ET la recherche
qui la remplace (A538) : 24 pt sur un iPhone à Face ID, 12 px sans zone sûre (navigateur, iPhone SE). La réserve du
pied (96 px + zone sûre) reste plus que suffisante.
Témoin (A542-A543) : `audit-doctrine` « Accueil · A542-A543 » (vérifié capable d'échouer : 2 rouges).

## A544 — Recherche, filtre, quitter : la barre d'onglets revient (v5.73.4)

*Précise A517 (la recherche remplace la barre d'onglets) et A538 ; signalé par l'auteur.*

Au téléphone : ouvrir la recherche, toucher le bouton filtre à gauche du champ, fermer la feuille, puis quitter —
la recherche restait affichée à la place de la barre d'onglets. La fermeture ne s'écoutait qu'au `blur` du CHAMP ;
en fermant la feuille, le focus revient au bouton filtre (dans le dock), puis plus rien ne déclenchait la sortie.
**Correctif.** La sortie du focus s'écoute sur tout le dock (`focusout`), et un tap hors du dock et hors d'une feuille
referme aussi, champ vide (`tbSearchMaybeClose(horsDock)` : Safari iOS ne déplace pas toujours le focus d'un bouton
au tap ailleurs). Un tap DANS une feuille ne compte pas : en revenant des filtres, la recherche reste ouverte.
Témoin : `audit-doctrine` « Accueil · A544 » (vérifié capable d'échouer).

## A545 — Au téléphone, le titre choisit : collections et catégories dans une feuille « Afficher » (v5.74.0)

*Renverse A517 (« filtres en pastilles ») et A528 (« Affichage » en première pastille) ; amende A475 (porte des
collections au téléphone). Signalé par l'auteur (« le choix de catégories/collection sur téléphone est limité et pas
pratique ») ; option B retenue sur planche Claude Design « Filtres de l'accueil au téléphone », 02/11/2026.*

**Mesuré** (390 px, 8 catégories, 4 collections, 24 aides) : la rangée de pastilles tenait **15 pastilles sur
1 741 px**, trois visibles (Affichage, Tout, Accès direct) — collections et catégories hors champ, sans indice ;
après un tap, la rangée se redessinait à 0 et la pastille active (« Urgences », à 1 637 px) disparaissait, d'où une
puce « Catégorie : Urgences × » qui redisait le filtre ; collection « Pédiatrie » et catégorie « Pédiatrie »
voisines, distinguées par la seule icône ; le titre disait « Aides » quel que soit le filtre.

**Décision.** Le grand titre (34 px, A505) **est le sélecteur** (`#pgPick`, `pgPickHtml`) :
- au repos « Aides ⌄ », sous-ligne « Tout · n » ; filtré, il devient le NOM du filtre, coiffé de son œil
  (« Collection · à vous seul » + signet, « Catégorie » + point) ; le petit titre de la rangée collante suit ;
- un tap ouvre la feuille **« Afficher »** (`openHomePick`, sur `openPickMenu`) : Tout afficher, Accès direct, puis
  « Mes collections » et « Catégories » en listes groupées (A506), un **compte** par rangée (`.mm-cnt`), coche sur le
  courant, « ＋ Nouvelle collection… » en pied ; **un tap = appliqué et fermé**, la page remonte en haut ;
- **un filtre à la fois au téléphone** : choisir une collection retire la catégorie, et l'inverse. Une combinaison
  posée en large reste lisible : le titre dit la collection, la catégorie reste en puce (`filtersBarHtml` ne redit
  que l'axe que le titre NE dit PAS, `pgAxis`) ;
- « Tout afficher » (une catégorie : sous le titre ; une collection : dans son en-tête, à côté d'« Ajouter » et ⋯)
  remet « Aides ». Au téléphone l'en-tête de collection perd son œil et son titre, que le grand titre porte ;
- **« Affichage »** (ranger, densité, nature) devient le bouton rond de 44 px au bout de la ligne du titre (même id
  `#rangBtn`, un câblage).
  *(Amendé par A556 : il devient « Trier et présenter » — trier, regrouper, densité ; la nature monte dans « Afficher ».)*

Purgés (règle 14) : `pgChipsHtml`, `.pg-chips`, `.pg-chip`, les gestes `[data-pgcat]`. En large (≥ 780) et au
téléphone tourné, rien ne change : la colonne gauche montre les deux axes.
**Ce qu'on perd, et dit** : filtrer sur l'Accès direct prend deux taps au lieu d'un — ses tuiles sont déjà en tête de
l'accueil (A537) ; combiner collection ET catégorie ne se fait plus au téléphone.
*Formes écartées* (planche) : **A** — deux rangées de pastilles, une par famille, l'active en tête (correctif léger :
on défile encore de côté, une rangée de plus) ; **C** — une pastille « Filtrer · n » et l'état en pastilles, feuille à
pastilles qui vont à la ligne et « Voir les n aides » (un tap de plus pour appliquer) ; l'arborescence « Parcourir »
(un niveau de retour de plus avant la liste, sous stress).
Témoins : `audit-doctrine` « Accueil · A545 le titre choisit » (vérifié capable d'échouer : 6 rouges sur l'avant),
et réécrits sciemment : A475 (la porte des collections au téléphone est le titre), A528 → A545 (« Affichage » au bout
de la ligne du titre), la gouttière du rail (la rangée mesurée est la ligne du titre).

## A546 — L'éditeur de référence : voir en écrivant (v5.75.0)

*Amende A455 (« ≥ 1000 : la colonne d'aperçu, inchangée ») et A459 (le calque) ; garde l'écart d'A452-A459 (pas de
`contenteditable`) et la barre au-dessus du clavier d'A468-A472. Demande de l'auteur (« voir directement les
modifications, la mise en page, les images ») ; option A retenue sur la planche Claude Design « Éditeur de protocoles
— voir en écrivant », 02/11/2026, après arbitrage sur le copier-coller.*

**Constat** (mesuré v5.74) : au téléphone, « Écrire | Aperçu » ne montrait jamais les deux ; vérifier un encadré, un
tableau ou une image obligeait à basculer et à perdre sa place. La source restait brute au doigt (le calque d'A459
n'existe qu'à la souris), et une image n'était qu'un identifiant `![…](img:ID)`. Au bureau, le rendu tenait dans la
colonne de 320 px, sous la relecture, loin de la ligne écrite.

**Décision — un seul champ, natif, et son rendu à côté :**
- **Téléphone, clavier ouvert** : la bande « bloc rendu » au-dessus de la barre (`.md-peek`, `mdPeekPaint`) rend le
  SEUL bloc qui contient le curseur (`mdBlockSrc`, pure) — encadré, tableau, image. Bornée à 96 px (l'écran est compté,
  A471) ; si le curseur passe sous elle, la page remonte d'autant (la ligne écrite reste visible). Un **œil** dans la
  barre la masque (`[data-mdpeek]`, `aria-pressed`) ; le choix est retenu SUR L'APPAREIL (`ac-mdpeek`, réglage
  d'affichage comme le thème, hors espace de compte, donc hors `WIPE_SPACE_KEYS`). Un toucher sur la bande garde le
  champ (surface de la barre, `tapKeepsFocus`) ; 16 px la séparent des boutons, plus que les 12 de rattrapage. Sous 400
  px effectifs, l'œil prend la place du séparateur : la barre tient sur une ligne de 320 à 390 (mesuré).
- **Bureau et tablette paysage (≥ 1000)** : source et rendu **à parts égales** (`body.view-pedit .read-grid` en
  `1fr 1fr`, page bornée à 1440 au lieu de 1202). Le rendu **suit le défilement du champ** (`mdScrollLink`) : la
  section en haut du champ vient en haut de la colonne, par interpolation entre les débuts de blocs, mesurés en une
  fois par un double aux métriques du champ (`mdLineTops`). De 780 à 999, la colonne d'A468 reste.
- **Images** : au pointeur fin, le calque pose au bout d'une ligne `![…](img:ID)` la vignette et la taille de l'image
  (`.hl-imc`, en absolu : aucune place prise dans la ligne ; la taille en `attr(data-s)` : le texte du calque reste
  octet pour octet celui du champ). Au téléphone, la bande montre l'image elle-même.
- **Déplacer sans couper-coller** : le menu **Plan** propose, pour la section où l'on écrit, Monter · Descendre ·
  Dupliquer · Supprimer (seuls les gestes possibles). Une section = son titre jusqu'au prochain titre de niveau égal ou
  supérieur ; ses voisines = même niveau sous le même parent (`mdSecAt`, `mdSecMove`, `mdSecDup`, `mdSecDel`, pures).
  L'écriture passe par `mdSplice` sur la seule plage qui change (`mdReplaceBody`) : ⌘Z natif et ↶ de l'éditeur
  l'annulent ; la suppression le dit dans un toast.

**Ce qui ne change pas, à dessein** : le copier-coller, la sélection et l'annulation restent ceux du champ natif (la
raison du choix de A sur B) ; « Écrire | Aperçu » reste au téléphone pour lire tout le rendu.
*Formes écartées* (planche) : **B — l'édition par blocs** (le rendu devient l'éditeur, un bloc touché s'ouvre en
Markdown, réglages d'encadré et d'image sur place, « ＋ » entre deux blocs) : reportée, pas refusée — elle complique le
copier-coller de plusieurs blocs (une sélection ne traverse pas les champs ; copier le rendu perd le Markdown) et
demande un historique d'annulation propre ; à reprendre si le besoin de modifier sur le rendu se confirme, avec la
source entière à un tap pour les longs copier-coller. Le WYSIWYG `contenteditable` reste écarté (A452-A459).
Témoins : `tests.html` (calque et vignette, sections, bloc au curseur) ; `audit-doctrine` « Éditeur · A546 » (clavier
émulé par `visualViewport.height` ; vérifié capable d'échouer : 5 rouges sur l'avant).

## A547 — Mise en forme en direct : le document s'édite par blocs (v5.76.0)

*Amende A546 (retire la bande au-dessus du clavier) ; reprend l'option B de la planche « Éditeur de protocoles — voir en
écrivant », reportée en A546. Décision de l'auteur, 02/11/2026 : « je ne vois pas les modifs dans l'éditeur », puis
« l'aperçu au-dessus du clavier sur iPhone : non non », puis « pars sur B ».*

**Constat.** A546 gardait un champ de Markdown brut et montrait le rendu À CÔTÉ : l'auteur attendait la mise en forme
DANS l'éditeur. Un champ natif ne sait pas la montrer (une police, une taille, ni image ni tableau) ; le `contenteditable`
reste écarté (A452-A459 : fragile sous iOS, Markdown non portable).

**Décision — le rendu est l'éditeur, un bloc à la fois s'ouvre en Markdown :**
- **« Mise en forme en direct »** (interrupteur de l'en-tête du contenu rédigé, `[data-mdlive]`, `role="switch"`), **par
  défaut**, retenu sur l'appareil (`ac-mdlive`, réglage d'affichage comme le thème, hors espace de compte). Coupé : le
  champ Markdown entier d'A546 (copier-coller long, recherche dans le texte), inchangé.
- **Le document** (`#mdDoc`, `mdDocHtml`) rend chaque bloc de `mdBlocks` séparément (`.mdb`) ; toucher un bloc l'ouvre
  dans SON champ natif (`.mdb-ta`, hauteur ajustée, 16 px au toucher — règle 9) ; le reste reste rendu. Une image absente
  reste lisible en source (`.mdb-raw`). Les liens d'un bloc rendu n'ouvrent rien dans l'éditeur : le toucher ouvre le bloc.
- **Une seule vérité** : chaque frappe recompose le corps entier dans le champ Markdown (masqué, gardé dans le DOM) —
  enregistrement, relecture, Plan, ⌘Z et ↶ voient le même texte ; un changement venu d'ailleurs (relecture, Plan, ↶)
  redessine le document, bloc refermé. `mdSplice` n'écrit plus par `execCommand` dans un champ qui n'a pas le focus (sans
  cette garde, un geste sur le champ masqué partait dans le bloc ouvert).
- **Le champ actif** (`act`) reçoit la barre, ses menus, l'image, le lien vers un document, le collage depuis Word et
  les raccourcis (`bindField`, les gestes d'A453-A457 posés sur chaque champ) ; la barre ne paraît que bloc ouvert, au
  téléphone au-dessus du clavier (A468, place réservée sous `.md-doc` aussi).
- **Gestes du bloc ouvert** : Monter, Descendre, Dupliquer, Supprimer (toast « ↶ pour annuler »), Terminé (Échap,
  ⌘Entrée ; et, depuis A552, un toucher en dehors du bloc). Fonctions PURES : `mdBlockRanges`, `mdBlkMove`, `mdBlkDup`, `mdBlkDel`, `mdBlkIns` — une ligne vide est
  toujours posée entre deux blocs recollés (deux paragraphes ne fusionnent jamais).
- **Ajouter** : « Ajouter un bloc » en pied (et un « ＋ » entre deux blocs, au pointeur fin) ouvre le choix — paragraphe,
  titre, encadré, liste, cases, tableau (grille d'A456 ouverte d'office), image (sélecteur), séparateur ; le mot à
  remplacer arrive SÉLECTIONNÉ.
- **Copier** plusieurs blocs rendus met leur **Markdown** dans le presse-papiers (sinon la mise en forme se perdait au
  collage) ; une sélection dans un seul bloc garde la copie du texte.
- **Bureau** : la colonne de droite ne garde que la relecture (320) — le document EST le rendu ; le rendu à parts égales
  d'A546 ne vaut que l'interrupteur coupé.

**Retiré (règle 14)** : la bande « bloc rendu » au-dessus du clavier d'A546 (`.md-peek`, `.md-peek-t`, `[data-mdpeek]`,
`mdPeekOn`, `mdPeekSet`, `mdPeekPaint`, `mdBlockSrc`, l'icône `eye`, la clé `ac-mdpeek` qui reste orpheline sur les
appareils, sans effet). *Forme refusée par l'auteur* : un aperçu au-dessus du clavier au téléphone.
**Pas encore fait (dit, pas tu)** : registre d'un encadré par pastilles et taille d'une image réglées SUR le bloc (la
barre et la section « Images » s'en chargent) ; glisser un bloc à la souris ; le Plan qui glisse ses sections.
Témoins : `tests.html` (bornes et gestes des blocs) ; `audit-doctrine` « Éditeur · A547 » (téléphone clavier émulé et
bureau ; vérifié capable d'échouer : 7 rouges sur l'avant), « Éditeur · A546 » réécrit en mode Markdown.

## A548 — Le bloc ouvert se règle sur place ; glisser un bloc (v5.77.0)

*Suite d'A547 (« pas encore fait ») et de la planche B (B2, B4). Demande de l'auteur : « poursuis ».*

- **Encadré ouvert** : ses quatre registres en pastilles au-dessus du champ (`[data-mdbreg]`, `role="radio"`) —
  Alerte · Attention · Information · Confirmation, chacune avec son glyphe et son mot (règle 8 : jamais la couleur
  seule), la courante allumée à SON registre. Une pastille réécrit le marqueur du bloc par `mdCalloutLines` (forme
  canonique de GitHub, A453) : rien à taper. Les pastilles suivent le texte : un registre retapé à la main s'allume, un
  encadré défait les retire.
- **Image ouverte** : l'image elle-même au-dessus du champ (`.mdb-imgv`), sa taille en pastilles (`[data-mdbscale]`,
  l'échelle fermée `MD_SCALES`) écrite dans le modèle comme la section « Images » — le texte `![…](img:ID)` ne change
  pas (doctrine « marqueur hors du champ ») — et « Remplacer… » (nouvelle photo, même identifiant : toutes les
  références suivent).
- **Glisser un bloc** (pointeur fin, RENVERSÉ par A549 — « Prendre / Poser ») : la poignée ⋮⋮ (`.mdb-grip`, cachée au toucher, `aria-hidden` : Monter /
  Descendre restent le geste au doigt et au clavier) ; une ligne bleue dit où le bloc se pose (`.mdb-drop-b`,
  `.mdb-drop-a`) ; `mdBlkMoveTo` (pure) déplace par échanges successifs, chacun ne touchant que la paire échangée.
- **Encore à faire (dit)** : glisser une section entière dans le Plan ; glisser au doigt.
Témoins : `tests.html` (`mdBlkMoveTo`) ; `audit-doctrine` « Éditeur · A548 » (vérifié capable d'échouer : 3 rouges sur
l'avant ; le glisser est éprouvé par événements de glisser-déposer).

## A549 — Déplacer un bloc d'une référence : « Prendre / Poser », le geste de l'éditeur d'aide (v5.78.0)

*Renverse la poignée de glisser d'A548 et retire Monter / Descendre d'A547. Demande de l'auteur : « reprends le
déplacement comme lorsqu'on modifie une aide et qu'on déplace des blocs, pour être cohérent ».*

Le déplacement d'un bloc d'une référence prend **exactement** le geste de l'éditeur d'aide (MK5-b et ses suites,
`conventions-de-code.md` : « RÉORDONNER PAR « PRENDRE / POSER » », « UN DÉPLACEMENT EST UN GESTE MODAL ») :
- **Prendre** : la poignée ⠿ du bloc (`.mini.grab.mdb-grab`, au survol au pointeur fin) ou, au doigt, « ⠿ Déplacer » du
  bloc ouvert (les outils suivent le focus, K3). Commencer à glisser la poignée AMORCE le mode (v4.75.0).
- **Le mode** : bandeau `.ed-grab` qui NOMME le bloc (« Déplacement : « … » », « touchez une destination », ✕) ; le bloc
  pris porte `.grabbed` (« ⠿ en déplacement », anneau `--act`, pleinement lisible) ; la page se réécrit en cibles
  `.ed-drop` pleine largeur ≥ 44 px — « Poser en tête », « Poser ici », « Poser en fin ». Le reste du formulaire est
  INERTE par `disabled` natif (Plan, interrupteur), comme l'éditeur d'aide.
- **Poser** : un toucher sur une cible (ou le lâcher d'un glisser sur elle) — `mdBlkMoveTo` ; **annuler** : ✕, Échap ou le
  bloc pris lui-même ; le focus revient à la poignée.
- **Retirés (règle 14)** : Monter / Descendre du bloc ouvert (les ↑ ↓ avaient quitté l'éditeur d'aide pour la même raison :
  plus lents, un rendu par tap), la poignée `.mdb-grip` et sa ligne de dépôt (`.mdb-drop-b`, `.mdb-drop-a`, `.mdb-drag`).
  `mdBlkMove` reste : `mdBlkMoveTo` déplace par échanges successifs.
*Forme écartée* : un appui long au doigt pour glisser (proposée en cours de lot) — MK5-b l'écarte comme mécanisme (gants,
une main, appareil qui bouge).
Témoin : `audit-doctrine` « Éditeur · A548-A549 » (vérifié capable d'échouer sur la v5.77).

## A550 — Le document par blocs garde le rythme de la lecture (v5.78.1)

*Amende A547-A549 ; signalé par l'auteur sur captures : « quelques soucis de design — marges, padding ».*

Mesuré sur ses captures : (1) les « ＋ » entre deux blocs (`.mdb-gap`) apparaissaient TOUS au survol du document et
chevauchaient filets et textes ; (2) le cadre de survol était une BORDURE avec rembourrage — il décalait le contenu et
le crayon mordait le bord ; (3) les marges du rendu étaient mises à zéro dans chaque bloc (`.mdb>*`), et le document
perdait le rythme de la lecture (titre, paragraphe en gras et liste collés) ; (4) le bloc ouvert prenait le style
générique `.field textarea` (spécificité 0,1,1 contre 0,1,0 : fond gris, anneau en second trait) et Plex Mono, embarquée
en 600 seulement, le faisait lire en gras.

**Décision.** Le document est un flux de BLOCS SANS MARGE NI BORDURE propres (`.md-doc` en bloc, plus en flex) : les
marges du rendu se fondent entre blocs comme en lecture — ce que l'auteur voit est la référence lue. Le survol est un
`outline` décalé de 6 px (rien ne bouge) ; ⠿ et le crayon se logent ensemble en haut à droite, dans ce cadre, et le
texte garde l'alignement du formulaire (plus de gouttière de 40 px à gauche). Les « ＋ » entre blocs sont **retirés**
(règle 14) : « ＋ Bloc après » rejoint les gestes du bloc ouvert, « Ajouter un bloc » reste en pied. Le bloc ouvert :
fond de carte, UNE bordure `--act` et l'anneau doux `--primary-soft`, police d'interface (`--f-ui`, 16 px au toucher).
*Forme écartée* : garder les « ＋ » au survol d'un seul interstice (une cible de 20 px entre deux blocs, introuvable au
doigt et bruyante à la souris).

## A551 — Toute modification pose son point de reprise : ↶ paraît, quel que soit le geste (v5.78.2)

*Signalé par l'auteur : « où est le bouton retour en arrière ? », « même après un déplacement de bloc », « vérifie qu'il
s'affiche bien pour toute modification, peu importe laquelle ».*

**Cause.** L'éditeur pose l'enregistrement et le point de reprise (↶, `edUndoNote` / `edTouch`) par DEUX accroches
(`conventions-de-code.md` : « DEUX ACCROCHES, ET DEUX SEULEMENT ») : la saisie, captée par délégation de `input` sur
`#main`, et les gestes structurels, qui se terminent tous par un re-rendu de l'éditeur. Deux familles y échappaient :
(1) **les gestes du document par blocs** (A547-A549 : supprimer, dupliquer, déplacer, ajouter, registre, taille, image
remplacée) écrivent le corps dans le champ masqué sans re-rendre l'éditeur, et l'événement de ce champ ne bulle pas ;
(2) **les réglages par `change`** qui ne re-rendent pas — mesuré : la taille d'une image dans la liste « Images » et la
date de validation (référence ET aide).

**Décision.** (1) Le document par blocs appelle `edTouch` à chaque écriture (`push`). (2) **Une troisième accroche** :
`change` délégué sur `#main` comme `input` — tout sélecteur, case ou interrupteur ajouté demain est couvert sans qu'on y
pense ; sans changement réel du brouillon, `edTouch` ne fait rien.
**Vérifié** (sonde, chaque geste puis ↶) : dans l'éditeur de référence, 15 gestes du document, du Plan, de la relecture,
des images et du mode Markdown, et chacun des champs ; dans l'éditeur d'aide, ses 37 champs ; date de validation des
deux éditeurs. Tous posent ↶, et ↶ rend l'état d'avant.
Témoins : `audit-doctrine` « Éditeur · A547 » (↶ après une duplication) et « A548-A549 » (↶ après un déplacement).

## A552 — Un toucher en dehors referme le bloc, donc découpe un collage (v5.78.3)

*Demandé par l'auteur : « si on copie-colle un texte Markdown de plusieurs lignes, plusieurs styles, il sépare lui-même
dès qu'on clique en dehors de la boîte ? » — mesuré : non, le bloc restait ouvert ; seuls Terminé, Échap et ⌘Entrée le
refermaient.*

**Décision.** Un toucher EN DEHORS du bloc ouvert le referme ; le document se redessine, et un collage de plusieurs
styles y devient ses blocs (titre, paragraphe, liste, encadré, tableau). Terminé, Échap et ⌘Entrée restent.
- **Toucher, pas glisser** : appui puis relâchement à moins de 10 px — un défilement au doigt ne ferme rien. Par
  `pointerdown`/`pointerup` en capture sur le document, pas `click` : Safari iOS n'émet pas de clic sur un fond de page
  inerte. Les écouteurs se retirent d'eux-mêmes quand le document par blocs a quitté la page (comme Échap, A549).
- **Restent DEDANS** (ne ferment rien) : le document lui-même (un autre bloc s'ouvre par son propre geste), la barre
  d'outils et ses menus (`.md-toolbar`, `.popmenu`, `.popmenu-veil`), les fenêtres (grille de tableau, collage depuis
  Word : `.ai-modal`), le toast. En mode « Prendre / Poser », le toucher appartient au dépôt (A549).
- **Rien ne reprend le focus** : toucher le titre y laisse le curseur (contrairement à Terminé, qui rend le focus au bloc
  rendu pour le clavier).
- **↶ après un collage** : il défait le collage entier — le corps revient à son état d'avant, tous les blocs nés du
  découpage disparaissent ensemble. Il ne « recolle » pas le collage en un seul bloc : le découpage n'est qu'un rendu,
  le Markdown est le même avant et après, il n'y a donc pas d'étape à défaire entre les deux.

**Écarté** : fermer sur `blur` (la barre, ses menus et le sélecteur d'image volent le focus : le bloc se fermerait sous
le doigt) ; fermer sur `click` seul (muet sur iOS hors d'un élément interactif).
Témoin : `audit-doctrine` « Éditeur · A547 » — à la souris et au doigt : la barre laisse le bloc ouvert, un toucher dehors
le referme et le collage devient cinq blocs (vérifié capable d'échouer : geste retiré → rouge).

## A553 — « ↷ Rétablir », et le découpage d'un collage s'annonce (v5.79.0)

*Demandé par l'auteur : « peux-tu rajouter un bouton rétablir les modifications ? » ; et, pour le collage, le message
retenu au lieu d'un ↶ en deux temps (ci-dessous, « Écarté »).*

**↷ Rétablir.** Le pendant de l'anneau d'annulation (v4.74.2, A551), dans les deux éditeurs :
- **Une pile `_edRedo`** : ↶ y range l'état qu'il QUITTE (frappe pas encore notée comprise — sinon un ↶ en pleine
  rafale perdait ces mots pour de bon) ; `edRedoDo` le rend, remet l'état présent sur l'anneau (un ↶ le refera), passe
  par `migrate`/`migrateProtocol` (règle 5) et écrit par `edCommit` (même raison que ↶ : la garde d'`edTouch`).
- **Elle se vide** dès qu'un geste NOUVEAU pose un point (`edUndoNote`) : ce qui avait été annulé n'a plus de suite
  logique — la convention de tous les éditeurs. Et avec l'anneau : autre brouillon, sortie de l'éditeur.
- **Le bouton `#hdrRedo`** vit à côté de ↶, même gabarit (`.hdr-undo`), icône `redo` (le miroir d'`undo`) ; **masqué
  tant que la pile est vide** — il n'existe qu'après une annulation, donc l'en-tête du téléphone ne s'alourdit pas au
  repos (mesuré à 390 px).
- **Clavier** : Maj-Cmd/Ctrl-Z, et Ctrl-Y (l'usage Windows), **hors champ de saisie** comme Cmd-Z — dans un champ le
  raccourci reste au navigateur.

**Le découpage d'un collage s'annonce.** Refermer un bloc où l'on a COLLÉ et qui devient plusieurs blocs (A552) dit
« Découpé en n blocs — ↶ annule le collage. » : on voit que le découpage a eu lieu, et ce que fera ↶. Rien quand le
bloc reste un seul bloc, rien quand on a seulement tapé.
**Un accusé de geste remplace le précédent** (`toast(…,…,true)`) : « Découpé… » puis « ↶ Geste annulé » s'empilaient au
même endroit, illisibles (capture à 390 px). Les nouvelles de fond ne sont jamais retirées ainsi.

**Écarté** (proposé par l'auteur, puis retiré d'un commun accord) : un premier ↶ qui « recolle » le collage découpé en
un seul bloc ouvert, le second retirant le collage. Le découpage ne change pas le texte — le Markdown est le même
avant et après —, si bien que ce ↶ aurait été une étape d'AFFICHAGE dans un anneau d'états du brouillon, à invalider
au moindre geste ; et le besoin qu'il servait (reprendre tout le Markdown d'un coup) a déjà son outil : l'interrupteur
« Mise en forme en direct » coupé. À rouvrir sur un cas d'usage concret.
Témoins : `audit-k5` (↷ après ↶, Maj-Ctrl-Z, geste nouveau qui le retire) ; `audit-doctrine` « Éditeur · A547 »
(l'annonce du découpage, souris et doigt).

## A554 — Pincer pour zoomer, comme une feuille : la Page et la visionneuse PDF (v5.80.0)

*Demandé par l'auteur : « le mode Page affiche toute l'aide format A4 : est-ce possible de faire comme un navigateur
PDF, avec pinch to zoom très rapide sans lag, se déplacer, dézoomer rapidement ? Et pareil pour l'affichage d'un
fichier PDF » — puis : « l'idée est de pouvoir le lire et le regarder facilement comme une feuille ».*

**RENVERSE deux refus d'A133 / J175** — « pas de pinch écrit à la main » et « pas d'échelle continue ». Leurs raisons
ne tenaient qu'à une technique, pas au geste :
- *« il exigerait `touch-action:none`, qui tue le défilement »* — non : le défileur porte **`pan-x pan-y`**. Le glisser
  à un doigt reste NATIF (inertie, rebond), seul le pincer du navigateur est retiré, et c'est l'application qui le
  fait. Mesuré : même défilement à un doigt avant et après (fenêtre « Tableau », 390 px).
- *« une échelle qui glisse fait baver le texte »* — seulement PENDANT le geste. On y transforme un **calque**
  (`.sv-calant` pour la Page, `.pdf-pages` pour le PDF) : composition seule, aucune mise en page, d'où l'absence de
  lag. **Au lâcher** l'échelle est fixée puis re-tramée (Page : `svApplyZoom` ; PDF : nouveau rendu des canevas). Au
  repos, rien n'est une image étirée — `audit-doctrine` le vérifie (aucune transformation résiduelle).
- Le pincer du NAVIGATEUR, qu'A133 laissait « marcher par-dessus », agrandissait toute l'application (barres, quai)
  et étirait les canevas PDF sans les re-rendre : c'est ce que l'auteur ressentait comme du lag.

**Le mécanisme, un seul pour les deux surfaces** (`pinchBind`) :
- **Le point pincé reste sous les doigts** : sa place relative est notée dans un repère (la feuille ; la page PDF sous
  les doigts), et après l'échelle on décale le défileur horizontal et le défileur vertical (fenêtre « Tableau »,
  fenêtre du navigateur dans `main`, défileur du PDF) d'autant. Les doigts qui glissent pendant le pincer déplacent
  la feuille. Mesures client = px visuels : division par `zoomF()` (règle 10).
- **Sur ordinateur** : Ctrl + molette, et le pincer du pavé tactile (Chromium/Firefox l'émettent en Ctrl + molette,
  Safari en `gesture*` — sur iPhone ces derniers sont neutralisés, le toucher mène).
- **Lever les doigts ne « tape » rien** : un clic dans les 350 ms qui suivent un pincer est avalé (un nœud de la Page
  mène ailleurs par `svJump`, un lien du PDF ouvre une adresse).
- **Bornes inchangées** : Page 20-300 % (`SV_ZMIN`/`SV_ZMAX`), PDF 25-400 %. Les boutons gardent leurs pas (clavier,
  lecteur d'écran).

**PDF : plus de page blanche après un zoom.** `pdfApplyScale` ne libère plus les canevas : l'ancien reste, étiré, le
temps que le nouveau rendu le remplace ; seuls les calques posés au pixel (surlignage, liens) partent. Et la
**surface d'un canevas est plafonnée** (`PDF_MAX_PX`, 5 Mpx — le plafond de pdf.js sur iOS) : zoomée à 400 %, une page
demandait ~25 Mpx, au-delà de ce qu'iOS accepte, et le rendu échouait en blanc. Au-delà du plafond le canevas est
étiré : un peu moins net, jamais vide.

**CE QUI NE CHANGE PAS.** La largeur d'auteur et l'échelle par `scale` (A133) ; l'ouverture de la Page à la taille
d'auteur (A133, A150 : l'ajustement d'office ferait tomber les cibles sous 13 px — voir la feuille entière reste UN
geste, « ⤢ Ajusté » ou un pincer) ; l'ouverture du PDF en page entière (`pdfFitPageZ`) ; l'échelle jamais mémorisée ;
le mode crise n'est ni interrompu ni défilé d'office (règle 11 : rien ne bouge sans le geste).

**Écarté** : le double-tap pour zoomer. Sur la Page, un tap sur un nœud mène au bloc (`svJump`) et un double-tap
déclencherait d'abord ce saut ; à rouvrir avec un délai de discrimination mesuré, si l'usage le demande.

Témoin : `audit-doctrine` « A554 » — `pan-x pan-y` sur les deux défileurs ; pincer ×2,2 sur la Page, point sous les
doigts à < 1 %, aucune transformation résiduelle ; Ctrl + molette ; pincer sur un PDF, point sous les doigts, page
re-rendue (vérifié capable d'échouer : correction de défilement neutralisée → 2 rouges).

## A555 — Le pincer s'applique aux images ouvertes (lightbox) (v5.81.0)

*Demandé par l'auteur, après A554 : « est-ce qu'il peut appliquer ça aux images jointes qu'on ouvre ? »*

**Même mécanisme qu'A554 (`pinchBind`), même contrat** : le calque transformé pendant le geste est l'image
elle-même ; au lâcher, sa taille est **posée en ligne** (`lbFit`) et le navigateur la re-trame depuis la source — nette
à toute échelle tant que le fichier a les pixels. Le point pincé reste sous les doigts ; Ctrl + molette et le pavé
tactile font le même geste.
- **L'image vit désormais dans un défileur** (`#lbScroll`, `pan-x pan-y`) : agrandie, on s'y déplace au doigt. Elle y
  est centrée par `margin:auto` dans un flex — jamais `justify-content:center`, qui rendrait le bord gauche d'une image
  plus large que l'écran inatteignable.
- **k = 1 est l'image AJUSTÉE à l'écran, et c'est le plancher** (jamais plus grande que nature à l'ouverture, jamais
  plus petite que l'écran au pincer) ; plafond ×6. L'échelle repart de 1 à chaque ouverture, et suit la fenêtre au
  redimensionnement.
- **Un tap sur le fond ferme toujours** : le fond autour de l'image est maintenant le défileur, il ferme comme le voile
  le faisait. Un tap dans les 350 ms d'un pincer est avalé (A554), donc lever les doigts ne ferme rien.
- **La croix passe au-dessus du défileur** (`z-index:1`) : une image agrandie défilait sinon PAR-DESSUS ✕.

**Hors périmètre** : le plein écran de l'algorithme (`#flowFull`) garde ses boutons et le pincer natif — non demandé. *(Clos par A558.)*

Témoin : `audit-doctrine` « A555 » — ouverture ajustée, `pan-x pan-y`, pincer ×3 avec le point sous les doigts à
< 1 %, aucune transformation résiduelle, tap sur le fond qui ferme (vérifié capable d'échouer : échelle ignorée par
`lbFit` → rouge).

## A556 — Au téléphone, un bouton pour QUOI, un pour COMMENT ; le filtre du dock est purgé (v5.82.0)

*Amende A545 (« Affichage » = ranger, densité, nature, au bout de la ligne du titre) et A353 (la porte de la feuille au
téléphone est le bouton rond du dock) ; renverse A423/A538 sur le bouton filtre. Signalé par l'auteur (« que penses-tu
du bouton à côté de “Aides”, du bouton Trier/Affichage et du bouton filtrer à côté du champ de recherche ? ») ;
proposition retenue sur planche Claude Design « Accueil téléphone — Quoi / Comment », 04/11/2026 (« OK pour ta
proposition »).*

**Mesuré** (390 px, captures de l'app servie) : trois boutons, deux feuilles. Le bouton rond du titre (⫶≡) et le
bouton rond à gauche de la recherche (`#filtTog`) ouvraient **la même feuille** « Affichage » — deux portes pour une
feuille, ce que le lot v5.30 interdisait (§ 5.5) et qu'A528/A545 avaient rétabli sans retirer la seconde. Cette
feuille redisait **collections et catégories**, déjà dans « Afficher » (A545 annonçait « ranger, densité, nature » :
le code n'avait pas suivi). « Afficher » et « Affichage », deux noms presque identiques ; la nature (Aides /
Protocoles / À relire) rangée dans la feuille du COMMENT ; une icône (échelle) qui ne disait ni trier ni filtrer.

**Décision — au téléphone (barre d'onglets, `tabNavOn()`) :**
- **« Aides ⌄ » = QUOI.** La feuille « Afficher » reçoit en tête le **Type** (Tout · Aides · Protocoles · À relire,
  segmenté `vsSegHtml` — « Type », le mot de « Regrouper » : « Afficher » est déjà son titre) et, s'il y en a
  plusieurs, la **Bibliothèque** (puces). Ce sont des RÉGLAGES : ils agissent en direct et la feuille reste ouverte ;
  une rangée (collection, catégorie) reste une DESTINATION : un tap applique et ferme (A545). **« Gérer les
  catégories »** rejoint les catégories qu'il gère, en dernière rangée du groupe. `openPickMenu` gagne `top` (sous la
  tête) et `onOpen` (câblage par l'appelant).
- **Le bouton rond = COMMENT.** Icône ↑↓ (`sort`), nom « Trier et présenter » ; sa feuille (`#viewSheet`, même
  câblage) ne montre plus que Trier, Regrouper, Densité, et son pied dit « Terminé » — une feuille qui ne filtre pas
  n'annonce pas de résultats.
- **`#filtTog` est PURGÉ** (règle 14 : bouton, `.filt-tog`/`.filt-n`, les règles de dock qui le dimensionnaient, le
  SVG dupliqué de l'icône `filter`) ; `syncFiltTog` devient `syncDockFilt` et ne garde que les crans de type de la
  recherche, qui agissent sans quitter la requête. La recherche prend toute la largeur.
- **Un filtre posé reste annoncé** : la puce « Afficher : Aides × » sous la ligne de compte, qui rouvre désormais
  « Afficher » ; la sous-ligne « Tout · n » se tait quand le type est restreint (elle contredisait la puce).
  `setHomeNature` : une seule écriture du type depuis les deux feuilles (« Tout » ↔ « À relire » ne changeait pas de
  section, donc ne re-rendait pas).

**En large (≥ 780) rien ne change** : la colonne filtre, la feuille « Affichage » garde Filtrer et Présenter (le type
n'a pas d'autre place) et son pied qui compte.
**Ce qu'on perd, et dit** : le badge chiffré « n filtres actifs » du bouton purgé — le grand titre dit le filtre de
collection ou de catégorie, la puce dit le type.
*Formes écartées* : garder l'entonnoir pour la seule recherche (une porte de plus vers la même chose) ; renommer la
feuille en large « Trier et présenter » (elle y filtre encore).
Témoins : `audit-doctrine` « Audit design · la feuille de filtres » (RÉÉCRIT SCIEMMENT — il mesurait le bouton purgé ;
vérifié capable d'échouer : feuille du bouton rond rendue à ses filtres → rouge), « T9 » (les crans de type sont dans
« Afficher »), « A544 » (la jambe « filtre » passe par un cran de la recherche), « A538 » (le champ seul à la hauteur
des onglets), « trois gabarits », « chemin d'arrivée », « A419 » (porte `#rangBtn`) ; `audit-a11y` : « feuille
affichage & filtres » à 1100, « feuille trier et présenter » et « feuille afficher (titre) » à 390, « feuille gérer »
par la rangée d'« Afficher ».

## A557 — Redimensionner en état zoomé garde ce qu'on regarde (v5.82.0)

*Amende A554-A555. Signalé par l'auteur : « bug pour les images et PDF et Page : si je modifie la taille de la fenêtre
à l'état zoomé, ça me casse tout ».*

**Mesuré** : l'échelle se recalcule sur la nouvelle largeur (image ajustée × k, PDF en % de la largeur, feuille), mais
le défilement restait en px ABSOLUS — après 1280 → 700 px on regardait une autre partie de l'image ; sur un PDF à
200 %, une autre PAGE ; la Page de l'aide, re-rendue au palier de largeur, repartait du bord gauche.

**Décision** (`pinchBind`) : chaque défileur retient en continu le point au **centre de sa part visible**, en
proportion de son repère (la page PDF sous le centre, la feuille, l'image) ; au redimensionnement — une image après
les gestionnaires qui remettent l'échelle — il le remet au centre. Un défilement émis PENDANT le changement de taille
(le navigateur borne la position quand le contenu rétrécit) n'écrase pas le point : on ne note qu'à taille de fenêtre
inchangée. La Page de l'aide, dont le défileur est REMPLACÉ par le re-rendu, reprend le point de l'ancien
(`_svAncre`, par lieu : `main` · fenêtre « Tableau »), s'il est récent et d'une autre taille. Les écouteurs posés sur
la fenêtre se retirent d'eux-mêmes quand leur défileur quitte le document (la Page se re-rend souvent).
Témoin : `audit-doctrine` « A557 » — image ×4, PDF à 200 % page 4, Page « Tableau » à 250 %, Page de l'aide à 200 %
(défileur remplacé) : le point au centre à < 1 % (vérifié capable d'échouer : rattrapage retiré → 4 rouges).

## A558 — Le pincer s'applique au plein écran du schéma (v5.83.0)

*Demandé par l'auteur, après A554-A557 : « fais pareil pour le plein écran du schéma ». Clôt le « hors périmètre »
d'A555.*

Même mécanisme (`pinchBind`), même contrat : le défileur `#flowFull .ff-scroll` porte `pan-x pan-y` ; pendant le geste
le SVG est transformé (il suit les doigts, sans lag) ; au lâcher, l'échelle partagée `flowZoom` est fixée — bornes des
boutons, 40-400 % — et `applyFlowZoom` re-trace le dessin vectoriel net. Le point pincé reste sous les doigts ; Ctrl +
molette et le pavé tactile font le même geste ; le point regardé survit au redimensionnement (A557).
**Lever les doigts ne « tape » aucun nœud** : un nœud tapé ferme le plein écran et mène au bloc (`bindSvgNav`) — le
clic qui suit un pincer est avalé (A554).
**Hors périmètre** : l'aperçu du schéma dans la page (`.flow-scroll`) garde le pincer natif — non demandé. *(Clos par A559.)*
Témoin : `audit-doctrine` « A558 » — `pan-x pan-y`, pincer ×2,5 avec le point sous les doigts à < 1 %, aucune
transformation résiduelle, le plein écran reste ouvert après le lever des doigts (vérifié capable d'échouer :
branchement retiré → 3 rouges).

## A559 — L'aperçu du schéma dans la page se pince aussi (v5.84.0)

*Demandé par l'auteur, après A558 : « fais pareil pour l'aperçu du schéma dans la page ». Clôt le « hors périmètre »
d'A558.*

Un seul branchement pour les deux défileurs du schéma (`flowPinchBind`) : le plein écran (une fois, au démarrage) et
l'aperçu `.flow-scroll`, rebranché par `bindFlowZoom` à chaque rendu (l'aperçu se re-rend à chaque geste de session ;
`pinchBind` est idempotent par élément). `pan-x pan-y` sur `.flow-scroll`.
- **L'échelle `flowZoom` reste PARTAGÉE**, comme avec les boutons : pincer l'aperçu agrandit aussi le plein écran.
- **Le défileur vertical est choisi à la volée** : au tactile, l'aperçu dans `main` n'a pas d'axe vertical à lui
  (A356, `overflow-y:clip`) — c'est la fenêtre qu'on recale ; ailleurs, l'aperçu lui-même (mesuré : sans ce choix,
  le point pincé dérivait de 15 % en hauteur).
- **Le point regardé survit au re-rendu du palier** (`_flowAncre`, par lieu, même patron que `_svAncre` d'A557) :
  mesuré à 1280 → 900 px, le point au centre dérivait de 11 % en largeur.
Témoin : `audit-doctrine` « A559 » — contrôles d'A558 sur l'aperçu (390 px, tactile), et le redimensionnement 1280 →
900 à 250 % (vérifié capable d'échouer : branchement retiré et mémoire coupée → 2 rouges).

## A560 — « Identité » se plie depuis son intertitre ; la carte ouverte ne rogne plus le menu (v5.85.0)

*Amende A521 §1 (le chevron de la rangée « Catégorie » et l'en-tête intérieur « Identité · Replier »).*

Signalé à l'usage, sur capture : « c'est coupé, et je n'aime pas l'emplacement de la flèche pour déplier ».
1. **Le menu des catégories était coupé.** `details.ed-ident` porte `overflow:clip` (pour que les rangées épousent
   l'arrondi) ; le menu ancré de « Autre… » vit DANS la carte (`openPickMenu` monte un menu ancré dans son hôte) et
   se faisait rogner au bas de la carte. Ouverte, la carte n'a plus rien à rogner (le sommaire y est masqué) : elle
   passe en `overflow:visible`. Repliée, elle garde le `clip` — aucun menu ne s'ouvre depuis les rangées.
2. **Un seul déclencheur, à une seule place.** Le chevron ›, posé au bout de la seule rangée « Catégorie », se
   lisait comme celui de la catégorie, et l'état ouvert mettait « Replier » ailleurs (en-tête intérieur, qui
   doublait l'intertitre). Le déclencheur est désormais à droite de l'intertitre, dans les deux états :
   « Modifier ⌄ » / « Replier ⌃ » (`.id-tgl`, `aria-expanded`). Le tap sur les rangées repliées déplie toujours
   (A521) ; le sommaire sort de l'ordre de tabulation (`tabindex="-1"`), le bouton étant LA commande clavier.
   `.id-a`, `.id-x`, `.id-chev` sont purgés (règle 14).

## A561 — Toucher à côté repose l'objet « en main » (v5.85.0)

*Complète MK5-b (« UN DÉPLACEMENT EST UN GESTE MODAL », `conventions-de-code.md`) et A549 : aux trois façons d'annuler
(✕ du bandeau, Échap, l'objet pris lui-même) s'ajoute la plus naturelle.*

Demande de l'auteur : « pour tout type de déplacement […] cliquer en dehors désélectionne et sort du mode déplacer,
c'est plus logique ». Jusqu'ici un tap hors cible ne faisait RIEN (le formulaire est inerte, `disabled`), et l'on
restait en mode sans savoir pourquoi.
- **Un écouteur, en capture sur `document`** (`grabOutBind`, posé une fois) : pendant un déplacement de l'éditeur
  d'aide (`state.edGrab`) ou d'une référence (`_mdGrabCancel`, tenu par `mdDocBind`), un clic qui ne tombe pas sur
  `GRAB_KEEP` (cibles, poignées, bandeau, fenêtres et menus) annule — par `edGrabDrop` (ancré, v4.77.0 : le regard ne
  bouge pas) ou `cancel` (focus rendu à la poignée).
- **Le tap qui repose est ABSORBÉ** (`preventDefault` + `stopPropagation`) : sans cela, dans une référence, le même
  tap ouvrait le bloc touché. **Exception : la barre d'en-tête**, où « ‹ Retour » reste un geste d'un tap (le retour
  vide déjà `state.edGrab`).
- Un glisser n'émet pas de clic : défiler la page pendant le mode ne l'annule pas.
Témoin : `audit-doctrine` « Éditeur · A561 » (vrais clics ; vérifié capable d'échouer : écouteur neutralisé → rouge).

## A562 — Importer une page Notion telle qu'exportée (.zip ou .md) (v5.86.0)

*Complète l'atelier d'import (A129, A159) et la porte des fichiers (`UP_KINDS`, « TOUTE ENTRÉE DE FICHIER »).*

Demande de l'auteur : « importer facilement des protocoles depuis Notion (fichier .md avec dossier contenant les
images, en chemins relatifs) ». Mesuré sur un export réel (« Motifs de recours en cardiologie », 1 page, 48 images,
9 Mo) : 48/48 images retrouvées, 2,6 Mo après réduction, texte de 12 300 caractères.
- **Le .zip de l'export entre tel quel**, par la même porte que les autres (« Importer un fichier », dépôt) : une
  archive SANS `.json` mais avec des `.md` est un export Notion. Notion l'emballe parfois dans un second .zip
  (« …-Part-1.zip ») : un niveau de plus est ouvert, pas davantage. **Chaque `.md` devient une RÉFÉRENCE, en
  brouillon**, qui passe par l'atelier comme toute entité (on voit avant d'écrire).
- **Les images** citées en chemin RELATIF (`![…](Page%20x/Untitled%201.png)`) sont résolues depuis le dossier du
  `.md` (`notionPath` : `%xx`, `./`, `../`, NFC — macOS écrit les noms en NFD), signées (`imgKind`), bornées
  (`MAX_IMG_BYTES`, `MAX_IMG_PER_ENTITY`), réduites par `downscale` comme une photo de l'éditeur, puis rangées dans
  la référence (`img:<id>`). Une image placée en milieu de ligne passe sur sa ligne (le mini-Markdown n'en lit
  qu'une par ligne, en tête). La légende inventée par Notion (« Untitled », nom de fichier, « Capture… ») est tue.
- **Conversion** (`notionMd`, PURE) : le `# Titre` de tête devient le titre (hash de 32 caractères retiré) ; les
  PROPRIÉTÉS de base Notion qui le suivent (« Statut: … », « Date: … ») sont retirées — des champs, pas du contenu ;
  `<u>` → gras, `<mark>` → `==surligné==`, `<aside>` → encadré (« Attention » si ⚠️/❗/🚨 en tête, « Information »
  sinon) ; `####` et plus → `###` ; un lien vers une autre page de l'export garde son texte seul ; le code reste
  littéral.
- **Rien ne se perd en silence** : une image citée mais absente est NOMMÉE dans le texte (« *[Image absente de
  l'archive : x.png]* ») ; images manquantes, au-delà du plafond, texte au-delà de `MD_MAX_CHARS` se disent dans un
  avis avant l'atelier.
- **Un `.md` seul** est reconnu à sa tête (`dataKind` → `'md'` : premier caractère signifiant « # » suivi d'une
  espace ou d'un « # ») — le texte libre reste refusé à la porte (« bonjour » → null, test conservé). Ses images,
  restées dans le dossier, sont nommées absentes et l'avis conseille d'importer plutôt le .zip.
*Forme écartée* : sélectionner le `.md` ET ses images ensemble — le sélecteur de fichiers d'iOS ne prend pas un
dossier, et l'export Notion est déjà un .zip.
Témoins : `tests.html` « Import — page Notion » (pur) ; `audit-doctrine` « Import · A562 » (archive fabriquée,
vrai point d'entrée ; vérifié capable d'échouer : branche Notion retirée → 2 rouges).

## A563 — Le retour système ne recule jamais deux fois : un parcours d'historique en retard n'est pas perdu (v5.86.1)

*Amende A430 (le filet « popstate perdu » de `_histSync`).*

Trouvé en cherchant à raccourcir l'audit : à pool 6 sur 4 cœurs, une tranche de doctrine plantait sur « Execution
context was destroyed, most likely because of a navigation » — l'app avait QUITTÉ son document en pleine sonde.
**Cause.** Quand l'app ferme un niveau, `_histSync` redescend l'historique par `history.go`, qui est ASYNCHRONE, et
arme un filet de 1 s pour le `popstate` « perdu ». Sous charge, le parcours arrive après 1 s : le filet le croyait
perdu, remettait `_hSkip` à zéro et relançait `history.go` sur une profondeur pas encore bougée — **double recul**,
sous la base de l'historique, donc hors de l'application (et le `popstate` tardif, n'étant plus ignoré, pouvait en
outre être lu comme un geste retour de l'utilisateur). **Mesuré** en différant `history.go` dans la page : 1,2 s
→ la page sort sur `about:blank` ; bloquer le thread principal ne reproduit RIEN (il retarde le minuteur ET le
parcours) — c'est le navigateur qui tarde, pas la page. Sur un appareil réel lent, la sortie mène à la page
précédente, voire hors de la PWA : inacceptable dans une app d'urgence.
- **Profondeur inchangée = parcours EN ROUTE** (`_hWatch`) : on attend, par pas de 1 s, 5 s au plus, et on ne
  relance JAMAIS un second `history.go`. Au-delà, on rend la main sans rien relancer : un parcours tardif tombe alors
  sur d = L (sans effet) ; un parcours réellement perdu laisse des entrées au-dessus, que le popstate « d > L »
  redescend déjà.
- **Profondeur changée sans popstate** (le cas que le filet visait) : on se recale comme avant.
*Forme écartée* : allonger le filet (2 s, 5 s) — une autre course, plus rare, même défaut.
Témoin : `audit-retour` « un parcours d'historique EN RETARD ne fait pas reculer deux fois (A563) » (`history.go`
différé de 1,2 s et 2,5 s : un seul recul, l'app reste sur son document, pile alignée ; vérifié capable d'échouer :
rouge sur le code d'avant, la page sort sur `about:blank`).

**Le même lot fiabilise deux sondes que la charge faisait rougir** (aucun seuil ne change) : `audit-doctrine`
« A129 · l'atelier d'import » attend l'aide ET la référence importées avant de lire ; `audit-guide` lit le voile
DANS le premier `scroll` (écouteur posé après celui de l'app) au lieu de 120 ms après la molette — le voile tombe
à chaque `scroll` et revient 220 ms après, la lecture à heure fixe était une course (un observateur de classe,
essayé d'abord, restait vert sur une app qui ne retirait plus le voile : écarté). `audit-pdfsearch` dit désormais
l'état de l'app quand le document joint n'apparaît pas (rouge vu une fois, non reproduit).

## A564 — Les harnais attendent que l'écran se pose, pas une durée (outillage, sans version)

*Piste 2 de l'optimisation de l'audit ; complète A563 (piste 1 : les rouges de charge).*

**Constat mesuré.** L'audit attendait surtout : ~830 pauses fixes (`w(600)`, `waitForTimeout(400)`…) dans doctrine,
a11y et k5, chacune payée en entier même quand l'écran était posé en 80 ms. Essai sans garde-fou (TOUTES les
pauses de doctrine converties) : 708 s → 542 s de sections, et exactement quatre sections rouges — celles où le
temps EST le témoin (ticks du quai, A474, reprise Q2, tri vivant P4b). C'est le signal qui a fixé la règle.
**L'outil.** `__acCalme(max)` (`installeCalme`, `harness.mjs`), posé avant tout code de l'app sur toute page de tout
harnais (`moteur().launch()` ajoute le script d'initialisation à `newPage`/`newContext`). Il rend la main quand :
deux images peintes, aucune mutation du DOM depuis 80 ms, aucun `setTimeout` de l'app échéant avant le plafond,
aucun `requestAnimationFrame` en attente, aucune transaction IndexedDB ouverte, aucun `fetch` en vol, aucune
animation finie d'élément en cours. PLAFOND = l'ancienne durée : jamais plus lent, jamais une lecture plus tardive
qu'avant. Côté Node : `calme(page, N)`.
- **Ignorées, et pourquoi** : l'animation infinie (halo d'alarme : elle ne finit jamais) et celle d'un
  PSEUDO-élément — l'anneau d'ouverture `sd-ring` (A493, 0,8 s + 3 × 1,3 s sur un `::after`) faisait payer son
  plafond entier à toute lecture d'aide hors session (mesuré 602/600 ms) ; aucune sonde ne mesure une boîte de
  pseudo.
- **Non suivi, à dessein** : le `setInterval` (le tick de 300 ms est perpétuel — l'attendre, c'est attendre le
  plafond). D'où la règle ci-dessous.
**La règle de conversion.** Pause de RENDU (< 700 ms) → `__acCalme(N)` / `calme(page, N)`, explicitement dans le
code (on distingue à la lecture une attente de rendu d'une attente d'horloge). Pause d'HORLOGE (≥ 700 ms : garde,
tick, échéance, minute) → durée inchangée, comme toutes celles des quatre sections où le temps est le témoin. Un
repli Node (`const __acCalme = pause`) en tête de chaque harnais converti : le code passé à `page.evaluate` est
sérialisé et y résout le `__acCalme` de la page, le code Node résout le repli — chacun le bon, sans heuristique
(une détection statique « dans un evaluate ? » a été essayée : les littéraux d'expressions régulières faussent
l'appariement des parenthèses, écartée).
**Mesuré, à verdicts identiques** (sections jouées en parallèle, avant → après) : doctrine 708 → 602 s (1 914/1 914
contrôles) ; k5 74 → 56 s ; a11y 217 → 184 s. **Non converti, parce que rien à gagner** (mesuré) : partage
394,6 → 390,5 s (seuils de protocole réels) et guide 84 → 84 s (il attend les délais propres du guide, pas des
pauses de sonde).
*Formes écartées* : remplacer chaque pause par une condition écrite à la main (~830 éditions, autant de risques) ;
une attente au seul DOM (rendait la main avant un anti-rebond, une écriture IndexedDB lente sous charge — c'est-à-
dire refaisait les rouges de charge qu'A563 venait de chasser).
**Témoin** : `audit-calme` (nouveau harnais, dans `HARNAIS`) — minuteur, boucle rAF, animation, transaction
IndexedDB dont l'effet tombe APRÈS 80 ms de silence du DOM, plafond, repos rapide, `calme(page, N)` ; vérifié
capable d'échouer (suivi des minuteurs et des rAF retiré → deux rouges).

## A565 — Le pool d'audit suit la machine : 2 × cœurs, 8 au plus ; doctrine en 6 tranches, a11y en 3, guide en 2 (outillage, sans version)

*Piste 3 de l'optimisation de l'audit. Renverse la prudence du lot v5.24 (« `AC_JOBS` reste à 4 par défaut — à 8 sur
ce Mac une section à attentes fixes a rougi une fois, et rien ne garantit la CI »).*

**Pourquoi c'est devenu possible.** L'audit ATTEND plus qu'il ne calcule (mesuré : 70 % de CPU occupé à 6
navigateurs sur 4 cœurs) : le pool ne doit pas suivre les cœurs, il peut les dépasser. Ce qui l'interdisait, c'étaient
des sondes que la charge faisait mentir ; A563 (retour système, trois courses) et A564 (attendre l'écran posé) les ont
traitées. **Mesuré sur 4 cœurs, passes complètes forcées** : pool 3 (l'ancien défaut ici, `min(4, cœurs − 1)`) 496 s ;
pool 6 281 s (cinq passes vertes) ; pool 8 **225 à 231 s (trois passes vertes sur trois)**, ≈ 300 Mo par navigateur
au pic (3 Go pour 8).
- **Défaut** : `min(8, 2 × cœurs, mémoire libre ÷ 500 Mo)` ; `AC_JOBS` reste souverain. Au-delà de 8, la tranche la
  plus longue borne le temps mural (pool 8 encore saturé : somme des tâches ÷ 8 = 224 s pour 225 s mesurés, mais à
  4 cœurs le CPU devient la limite).
- **Tranches** : doctrine 4 → 6 (130-141 s chacune au lieu de 175-186), a11y 2 → 3, guide 0 → 2. Guide se découpe
  par CAS (`--shard k/n`, modulo, ligne `##SEC` vérifiée par le lanceur) ; son bloc final « Prendre en main », hors
  des cas, est joué par la SEULE tranche 1 — sans cette garde, les tranches le jouaient chacune (468 contrôles au lieu
  de 462 : relevé en comparant les comptes, la somme des tranches doit égaler le harnais entier).
**Ce qui reste vrai** : un rouge obtenu sous forte charge se confirme en rejouant le harnais SEUL avant d'y croire ; un
poste chargé par ailleurs se règle par `AC_JOBS`. **Non mesuré** : la CI GitHub (4 vCPU, comme ce banc : défaut 8)
et un Mac de 8 cœurs et plus (défaut 8, la valeur qui avait rougi en v5.24 — avant A563/A564) ; l'audit de CI étant
non bloquant, un rouge y demande un arbitrage, pas un blocage.
*Forme écartée* : un pool proportionnel aux cœurs seuls (`cœurs − 1`, l'ancien) — il laissait le CPU aux deux tiers
inoccupé ; un pool sans plafond — 12 navigateurs n'apportent rien tant qu'une tranche de doctrine dure 130 s.

## A566 — En CI, l'audit se répartit en trois lots sur trois machines ; un bilan vérifie que leur union est la passe complète (outillage, sans version)

*Piste 4 de l'optimisation de l'audit. Complète A565 : sur une machine, la tranche la plus longue et le CPU bornent la
passe ; seule une autre machine lève les deux.*

**Avant.** L'audit était la DERNIÈRE étape du job `test` : il attendait la fin des tests (deux moteurs), puis jouait
les 37 tâches sur un seul runner.
**Ce qui change.**
- **`audit-run.mjs --lot k/n --rapport f.json`** : la machine k ne joue que SA part de la passe complète. Le partage
  (`partageLots`, glouton LPT, déterministe) porte sur la liste `tachesCompletes()` — chaque harnais ou chacune de
  ses tranches, au POIDS DÉCLARÉ de `HARNAIS`, jamais aux durées apprises de `.audit-etat.json` : deux machines qui
  n'auraient pas le même état découperaient différemment, et perdraient ou doubleraient des tâches. Un lot ne
  consomme pas le cache vert, n'écrit pas l'état, ne vérifie pas seul la somme des tranches (elles sont réparties)
  et s'annonce « LOT k/n … seul le bilan conclut ».
- **`audit-run.mjs --bilan rapports/*.json`** : il RECALCULE lui-même la liste attendue et exige que l'union des
  rapports la couvre EXACTEMENT — chaque tâche jouée une fois, aucune inconnue, lots 1..n tous présents et uniques,
  même commit, même moteur, chaque harnais découpé couvrant toutes ses sections (`##SEC`, la vérification qu'aucun
  lot seul ne peut faire). Un lot perdu (job annulé, artefact manquant, lanceur planté) ne fabrique jamais un vert.
  Vérifié capable d'échouer sur six rapports falsifiés : lot manquant, lot en double, tâche rouge, tranche de
  doctrine tronquée d'une section (157/158), lot d'un autre commit, aucun rapport — six refus motivés.
- **`ci.yml`** : l'audit sort du job `test` ; une matrice `audit` de trois lots (`fail-fast: false`, Chromium
  seul, cache Playwright à clé distincte pour ne pas enregistrer un cache sans WebKit sous la clé de `test`) tourne
  EN MÊME TEMPS que les tests, téléverse ses rapports même rouges, et `audit-bilan` (`if: always()`, Node seul) les
  rassemble. Toujours NON BLOQUANT (`continue-on-error` sur les deux jobs) : un rouge d'audit reste un arbitrage.
- **Poids de `HARNAIS` re-mesurés** (ils avaient dérivé : doctrine déclaré 478 pour 807 mesurés) : ce sont eux, et
  eux seuls, qui partagent la passe ; seul leur rapport compte, à re-mesurer quand un harnais change de taille.
**Mesuré** (sur ce banc à 4 cœurs, chaque lot joué seul, comme sur son runner) : lots 127 s, 126 s et 106 s pour
une passe complète de 219-231 s sur une machine ; bilan 37/37. **Non mesuré** : les runners GitHub eux-mêmes
(nombre de cœurs selon la visibilité du dépôt, temps d'installation) — le premier passage de la CI le dira.
*Formes écartées* : faire confiance à chaque lot sur sa propre part (un lot absent ne dit rien) ; partager sur les
durées apprises (non reproductibles d'une machine à l'autre) ; un lot par harnais (doctrine seul fixerait le temps).

## A567 — Les optimisations de l'audit se gardent seules : cliquet des pauses fixes, alertes de dérive (outillage, sans version)

*Clôt les pistes d'optimisation (A563-A566). Demande de l'auteur : « comment faire en sorte que les prochaines modifs
d'audit suivent ces optimisations ? »*

**Ce qui était déjà automatique** : l'attente de calme est posée sur toute page de tout harnais (`moteur().launch()`,
A564) ; le pool 8 fait rougir à la passe complète une sonde que la charge fait mentir (A565) ; un harnais neuf doit
entrer dans `HARNAIS` (`check-harnais`), donc dans les lots de CI, dont le bilan refuse toute passe incomplète (A566) ;
`audit-calme` garde l'outil. **Ce qui ne reposait que sur une ligne d'AGENTS.md** — et une règle déclarative fuit :
1. **`check-pauses.mjs`, 28ᵉ garde-fou de `npm run check`** : CLIQUET par harnais sur les pauses FIXES de moins de
   700 ms (`waitForTimeout(N)`, `setTimeout(r, N)`, appel d'un utilitaire de pause du fichier). Plafond relevé à
   l'introduction (`scripts/pauses-plafond.json` : 312 — doctrine 21, celles des quatre sections où le temps est le
   témoin ; partage 131 ; a11y et k5 0). Au-dessus → rouge, qui dit quoi écrire ; en dessous → rouge aussi, qui
   demande `--maj` (un plafond resté haut laisserait revenir autant de pauses qu'on vient d'en retirer). Exemption
   NOMMÉE sur place : `// horloge : <raison>` sur la ligne. Le repli Node `const __acCalme = …` a la forme d'un
   utilitaire de pause et en est exclu ; un utilitaire redéfini dans chaque `evaluate` (doctrine : ~125 `const w`)
   ne se compte qu'une fois — deux pièges du premier jet (2 924 puis 2 165 « pauses » au lieu de 312), relevés en
   confrontant le compte au relevé fait à la main. Vérifié capable d'échouer : pause ajoutée → rouge ; pause
   retirée → rouge `--maj` ; même pause marquée `// horloge` → vert.
2. **Alertes de fin de passe complète** (`audit-run.mjs`, jamais un rouge — aucun verdict en cause) :
   `△ poids de X à re-mesurer` quand la PART déclarée d'un harnais (poids de `HARNAIS`) s'écarte de plus de ×1,5 de sa
   part mesurée (parts, pas secondes : une machine plus rapide raccourcit tout, les parts restent ; seuil 2 % pour
   taire les petits) — ce sont ces poids qui partagent les lots de CI ; `△ X dure plus que la plus longue tranche :
   à découper` — une tâche non découpée bornerait seule le temps mural. Vérifié : k5 déclaré 600 au lieu de 60 →
   « 25,3 % déclaré pour 3,3 % mesuré », et aucune alerte sur les 24 autres.
*Forme écartée* : interdire toute pause fixe courte (rouge dès la première) — 312 existantes, dont 131 où la
conversion ne gagne rien (partage, mesuré A564) : le cliquet fait baisser le compte au fil des modifications sans
imposer une conversion en bloc.

## A568 — Le quai à 320 × 130 % : un cran de plus, mesuré, pour les mots longs ; deux sondes que la CI répartie a fait parler (v5.86.2)

*Étend A465 et A511 (`fitQuaiLbls`). Révélé par la première CI répartie (A566), dont les lots rapportent enfin leurs
rouges au lieu de les noyer dans un « succès » (`continue-on-error`).*

**Le quai.** À 320 px et 130 % (246 px effectifs, régime DÉGRADÉ d'A510 où « aucun mot coupé » tient), le quai était
déjà au dernier cran d'A511 (11 px, le plancher) avec ~1 px de marge pour « réfractaire » et ~3 px pour « Horodater »
(mesure locale). Le témoin A465 était ROUGE en CI à chaque passe, `main` compris, avant même A563-A567 — invisible
jusque-là. Le témoin, enrichi pour dire ce qui manque, a rapporté du runner : Manrope **chargée**, mais rendue ~8 %
plus large (« réfractaire » 61,5 px pour une boîte de 58,1 ; « Horodater » 60,0). Un iPhone de 320 px au rendu
différent n'aurait pas eu plus de marge : le défaut est dans l'app, la CI n'a fait que le montrer.
- **Troisième cran `lbl-fit`** : au plancher de 11 px, si un mot déborde ENCORE, « Fin » et « Tout voir » (mots courts,
  48 et 52 px depuis A465) descendent à **44 px — la cible du mode crise (règle 9), jamais en deçà** — et rendent
  ~6 px à chacune des deux touches à mot long. Ni taille ni graisse de texte ne changent. Décidé par la MESURE, comme
  les deux crans d'A511 : un rendu étroit ne le déclenche pas (les autres largeurs sont identiques à l'octet).
- **Vérifié** en reproduisant le rendu du runner (espacement de 0,4 px sur les libellés : exactement 61,5 / 58,1) :
  code d'avant → « FV réfractaire » coupé, comme en CI ; avec `lbl-fit` → touches longues à 66,1 px, boîte 64,1,
  rien de coupé ; 320 × 115, 360 × 130 et 390 × 130 inchangés.
*Formes écartées* : passer les libellés en graisse 700 (≈ 1 px gagné, et un registre typographique de plus) ;
réduire les gouttières du quai (règles d'A512 sur les zones sûres, pour 2 px) ; descendre sous 11 px (règle 9).

**Les sondes** (aucun seuil changé) : `audit-partage` « le bridage se VOIT » attendait 500 ms fixes après `joinGo()` ;
rouge une fois sur un runner très lent (10 min pour installer Chromium) — elle attend désormais ce qui pose la classe
de bridage (invité joint, fiche partagée affichée), plafond 8 s. Le témoin A465 rapporte, quand il rougit, mot,
boîte, touche, police et chargement : sans ces mesures, ce défaut n'était pas corrigeable.

## A569 — Les étapes complexes : chaque étiquette à son registre, « faite une fois » à plat (v5.87.0)

*Demande de l'auteur : « améliore l'affichage des étapes cochables complexes » (registres, compteurs et minuteurs liés,
étapes à moment). Méthode : l'ACR et l'Anaphylaxie d'exemple capturées en session, état par état (attente, seuil
franchi, dose lancée, « une seule fois » faite, échéance), à 390 et 1180 px, clair et sombre. Rien de ce qui a été
tranché sur planche n'est rouvert : le contour pointillé de l'attente (A382, A474), la place de « Faire maintenant »
(A474, A9), la lecture « ✓ » de la réponse (challenge-response), la pastille « Double contrôle » (N3) restent.*

**1. Trois étiquettes avaient perdu leur registre depuis A519 (régression, sans témoin).** La règle d'A519 « l'étiquette
d'un seuil en aplat neutre » était écrite `.stp-mk.mo{…}` — or toutes les étiquettes de moment portent `mo`, et cette
règle venait APRÈS `.mo-ok` / `.mo-due` / `.mo-n` à spécificité égale. Résultat mesuré : « ✓ Chocs délivrés ≥ 3 »
(vert d'A474 — la couleur même de l'instant du seuil), « Échu » (ambre : l'échéance, règle 8) et « Faite » sortaient
tous gris, identiques à une règle en attente. La règle neutre ne vise plus que la règle en attente
(`.stp-mk.mo:not(.mo-ok,.mo-due,.mo-n)`).

**2. L'instant du seuil finit à plat.** `moOpen` (A474) s'achevait sur `--amb-2`, la tuile des étapes d'avant A519 :
pendant 1,2 s la rangée virait du vert au GRIS, puis l'animation finie la coupait net vers le fond nu. Elle finit
désormais sur `transparent`.

**3. « Faite une fois » vit à plat (étend A519).** La rangée `mo-gone` gardait un contour plein `--line`, reste du temps
des tuiles (une rangée sans tuile devait encore se dessiner). À plat, comme toute étape : la case grise pleine ✓ et le
mot « Faite » suffisent. Seule l'ATTENTE garde un contour, et il est pointillé (A382) — trois habillages de rangée
(à plat, pointillé, plein) deviennent deux.

**4. Les règles de moment s'écrivent en phrase (étend A531).** A531 a passé toutes les étiquettes en phrase sauf les
MOTS D'ÉTAT (registre ECAM) ; le témoin exemptait toute la famille `.stp-mk`, si bien que les RÈGLES y étaient restées
en capitales espacées (« CHOCS DÉLIVRÉS ≥ 5 ●●●○○ », jusqu'à 200 px d'étiquette au téléphone). Elles passent en phrase,
12 px graisse 700 (« Chocs délivrés ≥ 3 », « À l'échéance », « Au besoin ») ; les mots d'état gardent les capitales
— « Échu », « Faite » (classe `mo-w`), comme CRITIQUE et VIGILANCE. La règle et l'état se distinguent ainsi d'un coup
d'œil, dans la même rangée.

**5. « passage n/N » ne se coupe plus** entre le mot et le compte (`.pass-n` insécable) : à 390 px, « passage » restait
au bout du titre du bloc et « 4/4 » tombait seul à la ligne.

*Formes écartées* : retirer le contour pointillé des étapes en attente pour les mettre à plat elles aussi (il dit « pas
maintenant, ne retient pas Continuer », A382 — à rouvrir sur planche seulement) ; « Faire maintenant » toujours au bout
de la rangée (le bouton qui part au seuil ferait changer la hauteur, A9 — c'est la raison d'A474) ; passer « Échu » et
« Faite » en phrase (des mots d'état, A531).

**Témoin.** `audit-doctrine` « v5.87 · A569 » (6 contrôles, 6 rouges sur le code d'avant) : encre neutre et phrase de la
règle en attente, « ✓ … ≥ 3 » vert, fin à plat de l'instant du seuil, « Faite » vert en capitales, rangée sans contour,
« Échu » ambre en capitales.

## A570 — Les étapes complexes : une place par chose, une liste à filets, des mots courts (v5.88.0)

*Demande de l'auteur (05-06/11/2026) : « améliore l'affichage des étapes cochables complexes » ; puis, sur planches
successives : « plein d'éléments différents qui n'apportent pas de cohérence », « toutes les infos au même niveau que
le libellé », « encore trop chargé », « pourquoi certains libellés plus gros », « l'écart critique / libellé correspond-il
à la maquette ? ». Six planches (inventaire, v1 à v6, épreuve de charge à 320 px, proposition unique) ; la forme retenue
est la planche « Allégée ». Arbitrages de l'auteur : retirer le pointillé, retirer l'aplat vert de la faite, hauteur
fixe, implémenter.*

**1. Une place par chose (une grammaire, toutes les étapes).**
- **Tête = quand, et quel risque** : registre (CRITIQUE, VIGILANCE, DOUBLE CONTRÔLE), moment (CHOCS DÉLIVRÉS ≥ 3 ●○○,
  À L'ÉCHÉANCE ◯ 03:57, AU BESOIN), état (✓ … ≥ 3, ✓ À L'ÉCHÉANCE, ✓ DÉJÀ FAITE — §6, §8), vérification (✓✓ CONSTATÉ, △ ÉCART).
  Mots nus, une seule typographie (11 px, 600, capitales espacées), séparés par « · ». Aucun mot n'a de fond (§8) (A11 : il exige
  un geste maintenant). La pastille neutre du seuil (A519), le filet de « Double contrôle » (A402) et la pilule de
  vérification à droite de la rangée (v4.23.0) partent. **La casse en phrase d'A569 §4 est renversée** : une seule
  typographie de tête, sinon la règle et l'état reforment deux dessins.
- **Milieu = le geste** : libellé seul en gras, **une seule taille** (A345, revue comprise — amende A449 §4, qui
  descendait l'étape-revue à 15), réponse en mono 600 (les seules graisses mono embarquées sont 600 et 700, règle 13).
- **Pied = ce que fait la coche** : la légende d'A377 (et, depuis le §9, la question de la case d'une étape en
  attente — « Faire maintenant » est retiré).
- **Le minuteur qu'attend une étape « à l'échéance » monte dans la tête**, à côté de sa condition : il en est la jauge,
  comme les points d'un seuil. À l'échéance, la tête dit △ À FAIRE et le pied ne dit pas « Échu » : il dit ce que fera la coche
  (relancer, « ◷ 04:00 Adrén. dose »). « Échu » n'est dit qu'une fois.

**2. Une liste à filets, sans cadre ni aplat de rangée.** Les étapes sont les rangées d'une liste groupée (A506) : un
filet qui commence au texte (60 px), aucun écart entre rangées. **Renverse** l'aplat vert de la faite (A519 §1) et le
contour pointillé de l'attente (A382, A474) et de la revue (A449) : l'état se lit par la case et l'encre — à faire =
case au trait, libellé noir ; faite = case verte pleine, encre douce ; en attente = case estompée, encre douce,
condition en tête. Seule l'étape à faire maintenant reste noire.

**3. Des mots plus courts** (légende d'A377) : « 3 → 4 à la coche · Chocs délivrés » → « +1 Chocs délivrés » ;
cochée « 3 Chocs délivrés · à l'instant » (le chiffre neuf seul, il monte toujours) ; « 04:00 à la coche · … » →
« 04:00 Adrén. dose » ; « la coche relance à 05:00 » → « relance à 05:00 » ; « décocher annule · 9 s » →
« annulable 9 s ». « dernier il y a » part de la légende au repos (l'heure du geste reste au journal). Le minuteur de
BLOC garde « à chaque entrée » (il n'est sous aucune étape).

**4. Hauteur fixe (A9).** Le pied d'une étape à moment est réservé dans tous ses états (bouton, puis légende) — y compris
pour un seuil seul, qui n'en réservait plus depuis A474.

**5. Mesuré contre la maquette** (390 px, 4ᵉ passage de l'ACR, boîtes de texte) : tailles, graisses, encres identiques ;
hauteurs à ±2 px ; tête → libellé 3 px (maquette 3), filet → tête 13-14 px (maquette 14). **Écarts gardés, et pourquoi** :
rembourrage de rangée 12 px (maquette 8 ; C68) ; case centrée sur la 1ʳᵉ ligne du libellé (A381 — la maquette la posait
6 px trop bas) ; légende en 13,5 (A377 a retenu 13,5 contre 12 ; la maquette disait 12,5, hors échelle A6) et débord de
8 px de la légende (A377) ; bouton de 24 px de haut dans la ligne réservée de 24 (cible 44 par halo) ; case estompée à
50 % (A474 ; maquette 40). **Pas fait, et dit** : la paire compte + relance d'A440 reste sur deux lignes (la maquette la
fusionnait) ; le nom de compteur reste entier (A462 ; la maquette disait « Chocs ») ; le glyphe « ▸ » de la maquette
reste le chronomètre de l'app.
**Piège corrigé pendant la mesure** : la tête, posée par rapport au haut de la rangée (A381, `top:8px`), remontait contre
le filet (6 px) et s'éloignait de son libellé (12 px) — CRITIQUE se lisait avec l'étape du dessus. Toute rangée à tête
aligne désormais sa case sur la 1ʳᵉ ligne du libellé (le pas des rangées `has-wt`), réserve 28 px (échelle fermée), tête à 17 px.

**6. Trois mots et une coche, tranchés par l'auteur sur les captures** :
- ~~« △ À faire »~~ et non « Échu » : quand le minuteur qu'attend une étape arrive au bout, « Échu » disait l'état du
  minuteur, pas ce qu'on attend de l'équipe. **Remplacé au §8** par « ✓ À l'échéance » (le fond ambre passait devant
  CRITIQUE). Le minuteur, lui, reste « Échu » dans la capsule et la légende d'une étape déjà cochée.
- **« ✓ Déjà faite »** et non « Faite » : une étape « une seule fois » faite à un passage précédent. « Faite au passage
  3 » et « T+04:12 » ont été jugés illisibles sous stress. **L'heure n'est pas disponible** : une coche n'est pas
  horodatée (seules les coches liées à un compteur posent un repère daté) ; l'horodater serait une donnée de session
  nouvelle, à faire suivre au partage et au registre RGPD — lot séparé, non décidé.
- **Une seule coche** dans l'étape : l'icône de la case, réduite, devant un mot de la tête (seuil atteint, déjà faite,
  constaté doublé). Le « ✓ » texte de la tête part, et **le relevé « ✓ » devant la réponse d'une étape cochée part**
  (challenge-response, conventions-de-code « Statuts… ») : il doublait la case verte, dans un autre dessin.

**7. Une police dans la rangée ; « Faire maintenant › » en texte (planche « Polices et bouton », variante B, action en
gris foncé — arbitrage de l'auteur).** La rangée mélangeait Manrope (libellé, tête) et le mono (réponse, valeurs) : la
réponse attendue passe en Manrope 15 / 500 à l'encre douce — **amende A411** : elle reste distincte du libellé
(17,5 / 700, encre pleine), ce que le défi-réponse exige, par la taille, la graisse et l'encre et non plus par la
police ; les valeurs des légendes et le compte de la revue passent en Manrope à chiffres tabulaires. Le mono ne reste
qu'aux chronos de la capsule et du moniteur. « Faire maintenant » quitte sa pastille grise (lue comme une étiquette)
pour une action en texte, encre pleine, chevron, souligné au survol (A530) — pas de bleu : l'app ne pousse pas le geste
hors de son moment (A382). *Écartées* : le bouton à contour à droite (C : ~140 px de libellé en moins sur une étape en
attente) ; l'action en bleu.

**8. L'échéance atteinte s'écrit « ✓ À l'échéance », en vert, comme un seuil atteint (planche « Cocher avant son
moment », D1 — arbitrage de l'auteur ; remplace le « △ À faire » du §6).** Sur fond ambre, « À faire » était le seul mot
à fond de la tête : il passait devant CRITIQUE et se lisait « la seule chose à faire ». Une condition remplie s'écrit
désormais toujours de la même façon (vert, cochée) ; « c'est maintenant » est dit par la case revenue et le libellé
repassé en noir. L'ambre n'a plus de fond dans la tête ; `.mo-due` est purgée. L'alarme du minuteur reste dans la
capsule, inchangée. *Écartées* : « À faire » en mot nu (D2 : un mot de plus pour la même situation qu'un seuil atteint) ;
le fond ambre (D3).

**9. Plus de « Faire maintenant » : la case demande confirmation sur place (planche, A — arbitrage de l'auteur ;
renverse A382 et A474 pour le bouton).** Ni le texte « Faire maintenant › » ni la pastille grise ne convenaient. La case
d'une étape en attente devient un bouton : la toucher l'ARME, et la ligne réservée du dessous dit « Pas encore le
moment. » avec « Cocher quand même » et « Annuler » (mots revus au §10) — sur place, sans fenêtre (règle 11), la
hauteur ne change qu'au geste (A9). Au repos, rien n'est écrit. Une coche par erreur, qui lancerait « prochaine dose » (A377), est rattrapée.
La phrase dit le fait (« pas encore le moment »), pas l'état du compteur (« Chocs : 1 sur 3 », jugé moins clair par
l'auteur). Au doigt, le focus ne saute pas sur « Cocher quand même » (A492 : l'anneau suit la modalité). *Écartées* :
le lien « Cocher » dans la tête (B : cible petite, coche sans filet) ; la case qui se coche directement (C : la
condition devient décorative).

**10. La question dit ce qui RESTE, et plus de ligne vide (v5.88.1, retours de l'auteur sur la v5.88.0).**
- **« Prévue dans 2 chocs délivrés. »**, « Prévue dans 1 choc délivré. », « Prévue dans ◯ 03:56. » (en direct), puis
  « Cocher » / « Annuler ». « Pas encore le moment » était vague, « Pas avant l'échéance » long et abstrait,
  « Cocher quand même » n'apportait rien : il faut savoir tout de suite POURQUOI ce n'est pas le moment et CE QUI
  RESTE pour que ce le soit. La tête dit déjà la règle et sa jauge ; la question dit l'écart (`momRestLbl`, singulier
  naïf : chaque mot en -s perd son s).
- **Plus de ligne réservée à vide** sous une étape en attente : sous une étape LIÉE, la ligne dit ce que fera la coche
  (`linkEffectHtml`, « ◷ 04:00 Adrén. dose », statique — le minuteur qui court se lit dans la tête), et c'est la même
  ligne avant et après le moment (A9 tenu sans vide) ; sous une étape SANS lien, pas de ligne du tout. Seule la
  question, qui suit un geste, l'ajoute.
- **Le guide l'enseigne** (demande de l'auteur) : une phase « Une étape à son moment » dans l'exercice guidé
  (`GUIDE_ETAPES`, après « Répondre ») montre la case d'une étape en attente, puis, la case touchée, « Ce qui reste »
  (essayer « Annuler ») — faite quand la question se referme ; sans étape en attente à l'écran, elle se lit et
  « Suivant » la compte comme vue. Un geste « Une étape qui attend son moment » dans `GUIDE_GESTES` et le terme
  « Moment d'une étape » dans `GLOSSAIRE`. ⚠ Piège payé : l'état d'armement s'appelle `g.moArm` — `g.mo` est
  l'observateur de mutations du guide (truthy), l'étape se croyait faite d'avance. Témoins : `check-guide`, `audit-guide`.

*Formes écartées (planches)* : glyphe seul à la place de la légende au repos (le `title` n'existe pas au toucher, leçon
d'A402) ; « Faire maintenant » révélé au toucher (action cachée en session ; la rangée en attente est inerte, A382) ; mot
de registre retiré d'une faite (A519 le garde, en gris) ; colonne d'instruments à droite (v5 : libellé à ~14 caractères
par ligne à 390 px, chevauchement à 320) ; instruments dans la tête (v5b : case décrochée du libellé, trois lignes avant
le geste dès deux instruments) ; deux tailles de libellé selon l'état (« Choc immédiat » plus gros qu'« Amiodarone » sans
raison, A345).

**Témoins.** `audit-doctrine` « v5.88 · A570 » (9 contrôles ; 7 rouges sur la v5.87, le 9ᵉ — tête collée à son libellé —
ajouté après la mesure) ; réécrits sciemment : A377 (le compte obtenu), A440 (« +1 », « relance à », « annulable »),
A569 (capitales) ; sonde « DÉMARRAGE » à 390 : le cas est rallongé (étapes plus denses), le seuil n'est pas relâché.
`tests.html` : `wtCountModel` et `wtTimerModel` aux mots d'A570.

## A572 — Le pool d'audit compte la mémoire DISPONIBLE, pas « libre », et dit quand elle le bride (outillage, sans version)

*Amende A565 (borne mémoire du pool par défaut).*

**Le défaut.** A565 bornait le pool à `os.freemem() ÷ 500 Mo`. Sur macOS, `freemem()` ne compte que les pages
LIBRES : le cache récupérable (pages *inactive* et *speculative*, que le noyau rend à la demande) en est exclu, et un
Mac en usage n'a presque rien de « libre ». **Mesuré le 06/11/2026 sur un Mac de 16 Go, 8 cœurs** : `freemem()` =
367 Mo pour ≈ 4,3 Go de pages inactives (`vm_stat`) → pool 1, passe complète **1 282 s** au lieu de **174 s**
(`AC_JOBS=8`), sans autre signal que « pool 1 » dans la ligne de tête.
- **Mesure** : sur darwin, mémoire disponible = (free + inactive + speculative) × taille de page, lue dans `vm_stat`
  (`memDispo()`, sans dépendance, 2 s au plus ; tout échec retombe sur `freemem()`). *Purgeable* n'est PAS ajouté :
  ses pages sont déjà comptées dans active/inactive, l'ajouter compterait deux fois. Ailleurs, `freemem()` reste :
  sous Linux (la CI) il lit `MemAvailable`, qui inclut déjà le cache récupérable.
- **Annonce** : quand le pool par défaut tombe sous `min(8, 2 × cœurs)` À CAUSE de la mémoire, une ligne le dit, avec
  sa mesure et la commande pour passer outre : « △ pool 1 au lieu de 8 : 367 Mo libres mesurés (500 Mo par
  navigateur) — AC_JOBS=8 pour forcer. ». Rien ne s'affiche si `AC_JOBS` est posé (il reste souverain) ni si le pool
  est borné par les cœurs.
- **Vérifié** : sur le même Mac, `memDispo()` lit 4 941 Mo (contre 372 Mo pour `freemem()` au même instant) → pool 8.
  Passe complète forcée sans `AC_JOBS` : **pool 8, 238 s**, sous une charge moyenne de 17 (une autre session travaillait sur la même machine) ; son seul rouge (« 700 · … et il entre en fondu », une sonde d'animation) est vert rejoué seul, et la passe complète suivante est verte. Annonce vérifiée avec un faux `vm_stat` à 367 Mo : « △ pool 1 au lieu de 8 … » ; muette sous `AC_JOBS=3`.
*Forme écartée* : ajouter *purgeable* (double compte) ; abaisser le coût compté par navigateur sous 500 Mo (≈ 300
mesurés au pic, la marge couvre les pics d'un harnais lourd) ; retirer la borne mémoire — elle reste utile sur une
machine réellement à court, c'est la MESURE qui était fausse, pas la borne.
