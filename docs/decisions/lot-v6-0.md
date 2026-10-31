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
