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

**Décision.** Au téléphone, Créer, Affichage, Partager, Moniteur s'ouvrent en **feuille du bas** (mi-hauteur ou
pleine), poignée en tête, fermeture en la tirant vers le bas ou par « ✕ » ; le voile absorbe le tap (A497). Le menu
**⋯** devient un **menu contextuel ancré à son bouton** (verre, sections séparées, « Terminer la session… » en rouge
en dernier), la session restant visible dessous. Rien de cela ne s'ouvre sans geste de l'utilisateur pendant une
session (règle 11). En large, les feuilles restent des fenêtres centrées ou des vues de la colonne, comme
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
