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
