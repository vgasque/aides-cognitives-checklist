# Lot v5.30 — la refonte v5 (maquettes smartphone + planche large, grille A) : A345-A348

> Fichier normatif, suite de [`lot-v5-29.md`](lot-v5-29.md) (A344). Les numéros A sont des
> adresses : ne jamais renuméroter. Demande de l'auteur (22/09/2026) : implémenter la maquette v5
> (« smartphone : fidélité haute ; planche large : haute pour la structure, moyenne pour le
> détail ») dans l'ordre tokens → étapes critiques → accueil → fiche → session → protocole →
> paliers → pliables, **sans nouveau token ni valeur hors échelle**, en réutilisant l'existant.
> La décision typographique qui l'accompagne est NORMATIVE : l'échelle A6 reste fermée (sept
> crans), seule l'AFFECTATION monte d'un cran.

## A345 — la marque d'une étape critique : le MOT, la BORDURE, le lecteur d'écran (variante « 6b »)

**A11 est rouvert, et c'est une décision de l'auteur sur maquette.** Depuis la v5.6, l'étape
critique se marquait par un corps différent (17,5 contre 15) et un glyphe ⚠ en tête ; la vigilance
par △. Mesuré sur les maquettes comparées : la marque en tête et le corps différent DÉSALIGNAIENT
le texte d'une liste, et le glyphe rendait mal selon la fonte. Le gain de corps est abandonné.

**La règle.** Toutes les étapes d'une liste partagent le MÊME corps et la MÊME colonne de texte :
`--t-step` (17,5) en session, `--t-item` (15) en lecture. Le danger est porté par trois canaux à
alignement nul :
- le MOT, en étiquette au-dessus du libellé — `CRITIQUE` (`--crit` sur `--crit-soft`) ou
  `VIGILANCE` (`--warn` sur `--warn-soft`), 11 px/800, `--r-1` ; cochée, l'étiquette s'éteint
  (`--amb-2`/`--ink-2`) mais le mot reste ;
- la BORDURE de la case (36 px, `--r-3`, 2,5 px) au registre : `--crit`, `--warn-line`, ou
  `--ctl-line` ;
- le préfixe `.sr-only` « Étape critique. » / « Vigilance. ».
Aucun glyphe ⚠/△ rendu, aucune encre colorée sur le texte, aucune teinte de rangée. La marque est
fabriquée UNE fois (`stepMarkHtml`) pour la rangée cochable (`ol.steps`) et l'aperçu à plat
(`.pl-stp`) ; la légende du bloc n'annonce plus que la réponse attendue.

**Écart mesuré à la lettre de la décision** : l'encre de `VIGILANCE` est `--warn`, pas
`--warn-line` — `--warn-line` sur `--warn-soft` tient 4,53:1 le jour et **3,19:1 la nuit** (calculé
avant d'écrire) ; `--warn` tient 5,8 / 9,6. Même registre, même mot, et le seuil AA tient dans les
deux thèmes.

**Ce qui monte d'un cran avec elle** (décision typo v5) : rangée d'étape en session 64 px, `--r-4`,
fond `--amb-2` (cochée `--ok-soft`, case verte pleine + ✓) ; titre de bloc `--t-step-l` (21) ;
question d'une décision `--t-step-l` — sur une carte de DÉCISION, le titre redescend à `--t-step`
pour situer la question, qui est l'acte (A75 garde sa raison, la hiérarchie s'inverse dans le
seul cas où le contenu de la carte est une question) ; options 15/800 avec leur destination en
12, l'issue prise à la matière SYSTÈME ; la carte de décision est AMBRE DOUX (`--warn-soft`,
maquette v5 — l'aplat de registre PLEIN reste interdit, A11 mesure toujours « au plus une masse »).
Le glyphe de commande `--g-cmd` passe à 17,5 ; `--shadow-cur` (0 12 32 à 12 %, `none` la nuit)
est l'ombre du seul bloc COURANT.

**Témoin** (`audit-doctrine`, « v5.30 · A345 ») : sur la fiche d'exemple, corps unique 17,5 et
colonne unique pour toutes les rangées, mots `Critique`/`Vigilance`, aucun caractère ⚠/△, préfixe
lecteur d'écran, bordure de case au registre à épaisseur constante ; cochée, l'étape critique garde
corps, colonne et hauteur (A9).

## A346 — « Fin » au quai, et la confirmation se MAINTIENT

`#endKey` (« Fin », glyphe stop + mot, `--crit-sys` sur la matière système, largeur de contenu)
ouvre la fenêtre « Terminer la session ? » — SEULE porte de sortie, inchangée (A336). Parce que le
quai est la zone de tap la plus fréquente de l'écran, la confirmation de la fenêtre passe au
MAINTIEN de 1,2 s (relâcher annule ; Entrée/Espace confirment sans geste — WCAG 2.5.1), par la
mécanique déjà en place pour la remise à zéro d'un minuteur (`holdToReset`, désormais paramétrée
en durée). C'est exactement le cas qu'A336 réservait (« si le terrain montrait un tap accidentel
malgré la fenêtre ») : le terrain, ici, c'est la maquette qui déplace la porte au pouce. La rangée
« Terminer la session… » du volet et du rail RESTE (A336) : deux sites pour une seule porte, le
quai en étant le bouton permanent. Jamais chez l'invité.

**« Journal · n » (demande de l'auteur après la première livraison).** La touche « Noter l'heure »
devient « Journal · n » : le TAP pose l'heure (ECAM, « l'heure prime » — la mécanique de v5.4 est
intacte) puis ouvre la feuille, qui nomme le repère ET relit le journal (liste chronologique,
lecture seule ; la correction d'une heure reste dans le volet). Une touche « Journal » qui
n'écrirait pas serait une seconde porte vers la même feuille. Les autres touches constantes
(« Tout voir », « Consulter », « Complication ») restent — la constance positionnelle du quai est
mesurée ; « Outils » est la capsule elle-même (un tap ouvre le volet). « Se repérer · Schéma » prennent une rangée SOUS le bloc courant (`.rd-tools`, session, < 1200 :
au cockpit la colonne d'orientation les porte) — au-dessus, elle repoussait la première étape
sous le pli à 320 × 640 × 130 % (budget d'écran mesuré) ; « Mode écran » de la maquette n'a pas
d'équivalent (la bascule Page/Un bloc reste « Tout voir »).

## A347 — accueil, fiche, session : ce qui suit la maquette

**Accueil.** Plus d'intertitre « Répertoire » : une ligne de compte, « Affichage » (menu à
pastille : rangement par bibliothèque / catégorie / A–Z, et « Gérer les catégories » en voie
étroite — la colonne large porte déjà « Gérer ») et « Sélectionner ». Rangement par CATÉGORIE par
défaut (une préférence enregistrée prime). Rangées de 64 px, méta à 13,5. Les états d'attente sont
des badges ACHROMATIQUES (`○ Brouillon`, `△ À relire`, `△ À compléter`, `△ Sans date` sur
`--tag-bg`) ; seul « À revérifier » (plus de deux ans) garde l'ambre — A338 est amendé sur ce point
(le glyphe revient, la couleur ne reste qu'à ce qui périme). Tuiles épinglées de 76 px, liseré
6 px, point vert PULSANT (`.sess-dot`, nom accessible) à la place du badge « ● En cours ». En
large, le répertoire est une grille de LIVRES (`auto-fit minmax(min(100 %, 320 px), 1fr)`, gap 16).

**Fiche — lecture.** Le sur-titre s'ouvre sur CATÉGORIE · CODE (pastille carrée de la couleur,
encre neutre, incompressible), puis le mot du mode (A330) et le discriminant, seul à s'ellipser.
Chips méta à 12/800 : bibliothèque en bleu doux, statut et catégorie sur l'ambiance, code et date
en mono. Les trois chapitres de l'écran d'entrée deviennent trois CARTES DÉPLIABLES au même en-tête
(badge 26 px, titre 15/700, compte, chevron) : « Quand l'utiliser » (critères à 17,5), « Ne pas
oublier » (rappels à 17,5), « Parcours » (n blocs · n décisions, Tableau/Schéma et l'aperçu à plat
dedans) ; l'état de repli est PAR FICHE et mémorisé avec les replis de lecture (`mdFold*`, clés
`when`/`forget`/`flow`), ouvert par défaut. ⚠ Ceci reprend deux formes qu'A330 avait refusées
(les intitulés dans leurs cadres, le parcours derrière une rangée dépliable) : c'est la maquette
v5 de l'auteur qui tranche, et le défaut OUVERT garde l'aperçu à plat visible sans geste.

**Fiche — édition.** Le statut est un segmenté à PASTILLE GLISSANTE (composant `.seg`, peint sur
place par `paintSeg` — le curseur glisse, la phrase d'aide et le badge d'en-tête suivent sans
re-rendu).

**Session.** Capsule de 64 px sur UNE ligne : chrono (24 px mono) séparé d'un filet, minuteurs en
tuiles `--sys-2` (libellé 11, valeur 17,5, barre 3 px `--ok-sys` qui se vide — même `barTf` que la
carte, ambre échue) ; l'ordre et le sacrifice des segments à l'étroit ne changent pas ; montée
dans l'en-tête, la capsule reprend sa forme compacte. « + Minuteur » propose 1 · 2 · 3 · 5 min et
le minuteur créé porte sa durée en libellé (« 3 min »). Le numéro de bloc est une PASTILLE de la
matière système (30 px) sur la ligne du titre (vert quand le bloc est complet) ; le mot « Bloc »
vit dans le nom accessible. Le PREMIER compteur entre dans la capsule en tuile (libellé + valeur, `data-cntval` repeint par
`setCounterVal`) en voie étroite — demande de l'auteur après la première livraison ; il est
sacrifié avant tout minuteur (`kc`), le rappel ne compte que ce qui n'est pas montré. Coût mesuré
(`audit-budget`) : +14 px de chrome permanent, 31,4 % à 320 × 640 — le cliquet du budget est
reposé au niveau atteint (32 / 39 %), et l'en-tête de carte sur une ligne rend 6 px.

## A348 — paliers larges (grille A) et pliables

La grille canonique existait déjà (sidebar 250 ; état 280 puis 320 ; orientation 240 au
cockpit ; plafonds 1622 / 1440 / 1064 → 1622 / 1282). Deux choses changent : la capsule ne monte
dans l'en-tête qu'au COCKPIT (≥ 1200, `mqCock`) — entre 1000 et 1199 elle reste sous l'en-tête à
sa forme pleine ; et la colonne du protocole lit `--col-orient`/`--col-gap` au lieu de littéraux.
Le dépliant du protocole en voie étroite dit « Sommaire · n sections » ; en recherche, chaque
titre du sommaire porte son COMPTE de résultats et les sections sans résultat se replient
(transitoire, jamais mémorisé). PLIABLES : `@media (horizontal-viewport-segments:2)` — deux
volets égaux, gouttière 24 px sur la pliure, quai et feuille bornés au volet gauche, options d'une
décision en une colonne, colonne du plan masquée. Fermé, rien ne change. (`check-paliers` ne
mesure que les largeurs : cette condition n'est pas un palier.)

## A349 — seconde passe sur les captures (« revérifie absolument tout »)

L'auteur a comparé la première livraison aux captures et signalé des écarts sur l'accueil, les
sessions, les protocoles, la création, l'écran d'accueil et le parcours. Ce qui a suivi :

- **Accueil (voie étroite)** : vue DÉTAILLÉE = une CARTE par rangée (liseré 6 px, titre 17,5,
  discriminant sur sa ligne, méta 13,5, ombre de travail) ; la vue COMPACTE garde le livre à filets.
  Feuille « **Affichage** » (`#viewSheet`) à quatre segmentés à pastille : Afficher (Tout / Aides /
  Protocoles / À relire), Trier (A → Z / Plus récentes — `homeSort`, par appareil), Regrouper (Non /
  Type / Catégorie / Biblio. / A–Z — `HOME_GROUPS`, synchronisé), Densité (Détaillée / Compacte —
  `homeCompact`, par appareil) ; « Gérer les catégories » en pied en voie étroite. « Sessions »
  (horloge) rejoint « Créer » dans l'en-tête ; sous 430 px effectifs le mot « Créer » s'efface pour
  garder la ligne. Le champ de recherche prend le rayon `--r-1`.
- **Bienvenue** : dégradé `--primary-soft → --amb`, marque 64 px, titre 38 px (exception NOMMÉE dans
  `check-type`), corps 17,5, trois portes — « Découvrir avec 2 exemples » (ajoute les fiches
  d'exemple), « Créer une aide… », « Me connecter · Rejoindre une session ». Les deux phrases
  réglementaires (responsabilité du contenu, confidentialité) restent, condensées. `amorce()`
  (harness) passe par la première porte.
- **Créer** : le TYPE se choisit par deux cartes (✓ Aide de crise, ≡ Protocole → éditeur
  directement), puis deux rangées (Rédiger avec l'IA, Importer) ; le segmenté de type reste dans
  la coque, caché (les témoins lisent son cran).
- **Parcours de l'écran d'entrée** (`preFlowFlatHtml`, remplace l'échelle à plat en voie étroite ;
  le cockpit garde la sienne) : liste numérotée comme un algorithme papier — pastille système,
  losange pour une décision, titre 17,5, étapes marquées, renvois écrits (« → aller à n », « ↺ retour
  à n », « ↓ ci-dessous », « ↳ puis n », « ▪ Fin du parcours »), « ← aussi depuis n », « Chemin k » ;
  numérotation `flowPlan` (A344). Témoin CHAPEAU adapté (`.pf-row`, compacité mesurée au cockpit).
- **Session** : « Parcours · x/y étapes » coiffe le journal (toutes les étapes de l'aide) ; le bloc
  courant ouvert porte la pilule « EN COURS » (le compte par bloc reste sur les cartes repliées) ;
  « Ne pas oublier » est une carte de travail au même en-tête que l'écran d'entrée — elle RESTE en
  tête, au-dessus de la carte (memory items d'abord, AC 120-71B, témoin CHAPEAU : la maquette la
  posait dessous) ; « Se repérer · Schéma » SOUS le bloc courant. Sous 360 px effectifs (320 px, ou 320 × 130 %)
  la ligne « Parcours », la pilule et la légende s'effacent, le compte revient sur la carte, la
  capsule descend à 56 px et TOUTES les rangées d'étape descendent d'un cran (`--t-item`, 56 px) :
  la première étape doit rester au-dessus du pli (`audit-budget`, 320 × 640 × 130 %). Palier de
  compression (`html.zw360`), pas une hiérarchie — A345 tient, les rangées descendent ensemble.
- **Sessions** (historique) : une session = une carte (titre 21, détail 15, actions 52 px).
- **Protocole** : dépliant « Sommaire · n sections » en carte collée sous l'en-tête (badge ≡) ;
  titres 17,5/800 en bas de casse, chevron à gauche, filet entre sections ; en recherche, compte par
  titre et sections sans résultat repliées.
- **Éditeur** : les champs d'identité sont visibles d'emblée ; code et date côte à côte dès 360 ; la
  porte « Ajouter à cette aide » devient le BOUTON FLOTTANT tonal de la maquette (60 px, `--r-4`,
  glyphe 21 sur `--primary-soft`), et le menu qu'elle ouvre — la palette — garde TOUTES ses options
  (demande de l'auteur : ne rien supprimer de ce menu). De même, « Créer » garde ses portes
  (Aide, Protocole, IA, import, reprise du brouillon) : seule leur présentation suit la maquette.

**Grille B de la planche large : à NE PAS implémenter** (exploration).

## A350 — troisième passe : la COHÉRENCE du style, pas seulement les écrans

Demandes de l'auteur : « Assure-toi que l'ENSEMBLE du style est respecté (style et taille des
bordures, ombre, texte, hiérarchie) — recréer la cohérence qui en fait un design complet, clair,
lisible et moderne » ; « pour les sélecteurs à pastille glissante prends le design de la maquette :
c'est à ce genre de détails qu'il faut faire attention » ; « sur smartphone il n'y a plus d'en-tête
blanche ». Chaque écran de la maquette (quinze planches smartphone, sept planches larges, feuilles
Outils/Journal/⋯ rendues depuis la source) a été relu contre une capture de l'app à 390 × 844.

- **Une seule pastille glissante.** Le segmenté `.seg` (thème, taille du texte, format d'ouverture,
  statut de l'éditeur, feuille « Affichage », « Créer ») prend le dessin de la maquette : piste
  `--amb-2` à 4 px de marge et `--r-3`, pastille `--work` à filet `--work-line` et `--shadow-work`,
  écart 2 px, encre `--ink` sur le cran actif et `--ink-2` ailleurs — plus de `--primary-soft`.
  `:has(>.seg-pill)` réserve la piste au segmenté : les tuiles de la capsule partagent la classe
  `.seg` sans en être. `#zoomSeg` 144 px. Témoin modeseg inchangé (la pastille épouse le cran à
  2 px près, sur les deux thèmes).
- **L'en-tête vit sur l'ambiance.** Plus d'aplat blanc ni de filet sous la barre (`header.bar` sur
  `--amb`) ; ses commandes sont des PASTILLES de 40 px `--r-4` : retour, ⋯, thème et historique en
  `--work` à ombre, « + » rempli `--act`, le compte sur `--primary-soft`/`--act`. Le titre de
  lecture passe en sans 15/700 (la marque de l'accueil garde son serif) ; le sur-titre garde
  CATÉGORIE · MODE sous 430 px effectifs (code et discriminant vivent dans la page — le nom de
  catégorie s'ellipse, le MOT du mode ne tombe jamais).
- **Quai hors session.** Plus de matière système avant le premier geste : deux boutons posés sur la
  page — « Démarrer la session » rempli `--act`/`--on-primary`, 60 px, `--r-4`, ombre ; « Exercice »
  `--work` au contour POINTILLÉ `--act`. En session le quai garde sa matière. `--act-sys` n'avait
  plus de lecteur : purgé (check-tokens).
- **Lecture d'une aide.** Titre 24/800 DANS la page et discriminant 17,5/600 dessous (la barre
  garde le sien pour le défilement — `.wl-card .wl-t` et `.read-head` : une classe posée sur un
  `h2`/`h3` de fenêtre perd contre `.ai-card h3`, le titre de bienvenue était rendu à 17,5) ; la
  méta se lit en UNE ligne 13,5 `--ink-2` (statut en gras, dates en sans) ; options d'une décision
  sur deux colonnes sous 1000 ; « Continuer » rempli 60 px ; rangée « Se repérer · Schéma · Mode
  écran » (`html.read-compact`, persistée par appareil `ac-read-compact`) — le « Mode écran » de la
  maquette est donc bien là. Taille du texte à TROIS crans (100 · 115 · 130), le 90 % est retiré.
- **Éditeur.** Champs sur `--amb-2` à filet 1,5 px `--ctl-line` et `--r-3` (titre 52 px 17,5/700,
  les autres 48) ; intitulés 12/800 `--ink-2` à indication 600 en bas de casse ; cartes de section
  blanches (`--work`, `--work-line`, `--r-4`, `--shadow-work`) — le chapeau « Ne pas oublier »
  quitte son cadre rouge pour le badge « ! » de la lecture (la couleur reste aux étapes) ;
  « + Rappel » / « + Ajouter une ligne » en pointillé 44 px.
- **Fenêtre Compte, fenêtre Sessions.** Carte d'identité blanche, avatar carré `--primary-soft`/
  `--act`, intitulés de zone 12/800 `--ink-2`, chaque réglage en rangée-carte de 60 px (libellé
  15/700, segmenté à droite) ; « Sessions » (titre), une session = une carte (kicker d'état, titre
  21, « Durée · n étapes cochées », actions 52 px) ; phrase de compte de l'accueil « n parcours ·
  n protocoles · n à relire ».
- **Carte « Session en cours » de l'accueil** (demande de l'auteur : « je n'aime pas la barre verte
  fluo de session en cours, clair et sombre — prends celle de la maquette ») : carte de travail
  blanche comme la carte « EN COURS » de l'écran Sessions de la maquette — le vert ne reste qu'au
  point et au mot du kicker, « Reprendre » est l'action bleue de la page (`--act`), plus d'anneau
  vert la nuit. La bande verte tenait à `--ok-soft` + `--ok-sys`, un registre de confirmation posé
  sur toute une carte.
- **Ce que les témoins ont exigé** : la pastille du compte, posée sur `--primary-soft` contre
  `--amb`, ne tenait plus la limite de composant (1,09:1) — elle porte un filet interne `--ctl-line`
  dans les deux thèmes (3,1:1 le jour, 4:1 la nuit) ; les commandes de 40 px ne gardent que 2 px de
  halo (cible de 44, jamais au-delà du voisin) et le palier 360 les ramène à 32 comme avant ; sous
  430 en lecture, le compte s'efface (il est à un tap sur l'accueil) pour laisser le sur-titre
  entier. Les témoins k5 de la porte d'ajout (bouton REMPLI à ombre montante, v4.77-78) sont
  réécrits pour la porte TONALE à ombre de carte de la maquette (A349) ; les champs numériques
  prennent le gabarit des champs texte. Trois autres témoins encodaient la barre disparue : le
  geste d'entrée se mesure désormais contre la PAGE (aplat 3:1, ombre de carte, contour pointillé,
  filet 3:1 la nuit) ; la barre de référence PROLONGE l'en-tête à « même filet » (ni l'un ni l'autre
  n'en a) ; le témoin A6 ignore ce qui n'a pas de boîte (le titre 38 de bienvenue, fenêtre fermée).
  Une pastille BORDÉE porte son halo depuis le padding-box : 3 px pour 2 hors du dessin.
- **Écarts restants, nommés et À DÉCIDER avec l'auteur** (la maquette les demande, ils touchent une
  décision antérieure ou un garde-fou) : (1) les VOLETS Outils et Journal sont blancs sur la
  maquette, le ⋯ une FEUILLE basse titrée (tuiles Se repérer · Schéma · Mode écran) — l'app garde la
  matière système des volets (v5.6, trois matières) et un menu ancré ; (2) le quai en session a
  TROIS tuiles sur la maquette (Fin · Journal · n · Outils au téléphone, Fin · Complication ·
  Consulter en large) sans glyphe, 15/700 — l'app garde ses cinq touches (Tout voir, Consulter et
  ⚡ à un tap, A336) ; (3) « Aides » 24/800 en titre d'accueil contre la marque en serif ; (4) le
  socle de l'accueil (Rejoindre · Gérer · état) n'existe pas sur la maquette, dont « Rejoindre »
  vit dans Sessions et « Gérer les catégories » dans Moi ; (5) le sommaire d'un protocole est SOUS
  le titre sur la maquette, l'app le garde en barre collée (la recherche y vit) ; (6) la fenêtre Moi
  de la maquette liste les bibliothèques avec leur rôle.

## A351 — relecture de l'auteur sur les captures : douze points, et la planche large

Retours de l'auteur (23/09/2026), tranchés un à un :

1. **La pastille se glisse partout.** `bindSegDrag` n'était posé que sur trois segmentés de la fenêtre
   Compte ; la feuille « Affichage » et le statut de l'éditeur ne se laissaient que cliquer. Posé à la
   peinture de chacun (un glissement relâché clique le cran visé).
2. **Carte « Session en cours » identifiable** : au téléphone une carte blanche à LISERÉ vert de 6 px,
   kicker vert à point pulsant, titre 21, « Reprendre » bleu pleine largeur ; ≥ 780 la BANDE système
   de la planche large (« Reprendre » en tuile). Le vert ne teinte plus une carte entière.
3. **Le titre n'est jamais écrit deux fois.** Au téléphone il vit DANS la page (24/800, discriminant
   dessous) et la barre ne porte que le sur-titre (catégorie · mode) tant qu'il est visible ; le relais
   de titre (`ttl-on`) s'allume quand `.read-head` passe sous la barre. Dès 780 le titre vit dans la
   BARRE (21/800) et la page ne le répète pas — protocoles compris. Le discriminant suit le titre SUR SA
   LIGNE (« Titre · adulte », `#brandDisc`, hors de la chaîne ellipsée : K6 tient) ; il quitte le sur-titre.
4. **Réponse attendue ≠ registre** : la valeur « :: » d'une étape passe en mono `--ink-2` — l'ambre ne dit
   plus que VIGILANCE. (Alternative écartée : la garder ambre et changer VIGILANCE — le mot de registre
   prime sur une valeur à relire.)
5. **Colonne gauche de l'accueil (planche large)** : elle porte la MARQUE (serif gardé, décision de
   l'auteur), la navigation Aides · Sessions (point vert si une session vit) · Moi, les bibliothèques et
   les catégories (comptes en mono, « Gérer » en lien de l'intertitre), et le COMPTE à son pied ; elle
   tient toute la hauteur (`position:fixed`, largeur `--side-w`), l'en-tête et le bandeau système
   commencent après elle et ne portent que la recherche et « Créer ». « Historique » et « Rejoindre »
   quittent la colonne (Sessions les porte).
6. **Pliables** : `@media (horizontal-viewport-segments:2)` (A348) — deux volets, gouttière 24 px sur la
   pliure, quai borné au volet gauche, comme la planche Duo ; vérifié à la lecture du CSS seulement (aucun
   moteur de test n'émule les segments : à éprouver dans DevTools, profil Surface Duo / Galaxy Fold).
7. **Bordure bleue du bloc courant** : `--act` en bordure + 1 px interne (2 px visibles), sans déplacer
   le contenu, plus l'ombre `--shadow-cur`.
8. **En session, ce qui n'est pas le bloc vit SOUS lui, en cartes dépliables fermées** : « Ne pas
   oublier » EN PREMIER (décision de l'auteur — les memory items restent dans le flux, après le geste en
   cours ; le témoin CHAPEAU est retourné : le chapeau est la première carte sous le bloc), puis « À
   vérifier », « Diagnostics différentiels », « Repères posologiques » (ce dernier reste au rail en
   large). État transitoire `state.sessFold`, jamais persisté ; l'étage « Surveillances & pièges »
   n'existe plus en session (la carte le remplace).
9. **« Se repérer · Schéma · Mode écran »** quittent le flux : « Mode écran » devient une tuile du menu ⋯
   (`toggleReadCompact`), à côté de Moniteur · Se repérer · Schéma.
10. **Titres d'un protocole** : chevron à DROITE, aucune indentation du corps ; le sommaire ne numérote
    rien (les numéros sont ceux que l'auteur écrit).
11. **Décisions sur les écarts d'A350** : (3) la marque « Aides cognitives » en serif RESTE ; (4) le socle
    de l'accueil DISPARAÎT au téléphone — « Rejoindre une session en cours » vit en tête de la fenêtre
    Sessions quand rien ne tourne, « Gérer… » dans la feuille Affichage (vers la feuille « Gérer » d'A287
    ou le gestionnaire), l'état de l'appareil dans Moi ; `#joinBtn`, `#histBtn`, `#mgrBtn` et
    `syncMgrBtn` purgés (règle 14) ; (5) le sommaire d'un protocole vit SOUS le titre et la méta, dans
    une enveloppe COLLANTE (`.ref-tocwrap`, `top:var(--hdr-h)`) qui prolonge l'en-tête une fois
    défilée — la barre fixée `#refBar`, `syncRefBar`, `--refbar-h` sont purgés, le témoin RÉFÉRENCE
    mesure « sous le titre » puis « collé » après défilement ; (1), (2), (6) restent à décider (analyse
    remise à l'auteur : volets blancs et ⋯ en feuille basse, quai à trois tuiles, bibliothèques dans Moi).
12. **Le compte d'une carte dépliable se pose contre le chevron** (`.conf-sub{margin-left:auto}`), et le
    chapeau de session prend le même chevron ▾/▴ que les autres cartes.

### A352 — cinquième passe (relecture de l'auteur, 23/09/2026) : les fenêtres ont deux matières

Huit remarques sur les captures de la quatrième passe, toutes MESURÉES avant d'agir.

1. **La barre de sélection ≥ 780 était « attachée à un en-tête qui n'existe plus »** : conçue sous
   l'en-tête blanc (bord haut supprimé, coins hauts carrés), elle flottait, tranchée, sur l'ambiance.
   Elle redevient une carte de travail entière (`--work`, `--work-line`, `--r-4`, `--shadow-work`),
   toujours collée au bord du défileur `.home-main` (`top:0`, le rembourrage cède, cf. v5.17).
2. **Le logo est déjà à côté de « Aides cognitives »** (colonne : 32 px ; en-tête du téléphone : 30) —
   mesuré, rien à remettre ; il reçoit dans la colonne le même verrou d'encre que l'en-tête
   (`margin:0 -4px 0 -6px`, témoin « verrou logo » étendu à `.hs-brand` à 1280).
3. **Rejoindre par le code dans la recherche fonctionne** (mesuré à 1024 et 390 : bandeau « Code de
   session reconnu »). Ses conditions, à connaître : huit caractères de l'alphabet du partage (ni 0, ni
   1, ni I, ni O — `SHARE_ALPHA`), et jamais en mode Sélectionner. Aucun changement de code.
4. **Bords et anneaux rognés** : scan de tous les boutons contre leur premier ancêtre à `overflow`
   (rect + 4 px d'anneau). Trois familles : le PREMIER bouton d'un corps de fenêtre (`.ai-body` n'avait de
   respiration qu'en ligne — `padding:4px;margin:-4px` désormais sur les deux axes, `check-ring`
   inchangé) ; les boutons pleine largeur d'un bloc à `overflow:hidden` (`.atyp-link`, `.pre-link` : anneau
   INTÉRIEUR `outline-offset:-3px`, comme `.conf-head` déjà) ; la dernière rangée de la colonne
   (`.hs-scroll` gagne 4 px en bas). Et l'harmonisation demandée : `.btn` prend la matière v5 (travail
   blanc, filet `--work-line`, `--r-3`, `--shadow-work`, survol `--amb-2`, anneau `--act`) ; `.btn.primary` =
   `--act` plein sans ombre (`--shadow-primary` purgé, `check-tokens` l'a signalé).
5. **Cartes de l'historique un cran plus serrées** : 12/14 px, titre 17,5, boutons 44 (elles étaient à
   16/18, 21 et 52).
6. **Fond blanc des fenêtres contre pages grises de la maquette — la réflexion demandée.** Sur la
   maquette, Sessions et Moi sont des PAGES (fond `--amb`, cartes blanches, tête « ‹ » + titre 24) ; dans
   l'application ce sont des fenêtres `.ai-modal` à carte blanche, comme les 20 autres. Le conflit n'est
   pas une couleur, c'est une NATURE : parmi les 22 fenêtres, six sont des DESTINATIONS (on y va, on y
   parcourt des listes, on en revient : Sessions, Compte, Gérer les catégories, Stockage, Gérer la
   bibliothèque, Versions) et seize sont des DIALOGUES (une question, un choix, un réglage court :
   confirmer, Terminer, Affichage, ⋯, partage, créer, importer…). Décision : DEUX MATIÈRES DE FENÊTRE,
   `.ai-modal.page` pour les destinations — fond d'ambiance, contenu en cartes de travail, titre 24/800,
   fermeture en pastille de 40 px (halo à 44) ; plein écran au téléphone (règle < 780 inchangée), panneau au
   gabarit DOCUMENT (`--dlg-atelier`, pas un quatrième gabarit) dès 780 : c'est le form-sheet d'iOS (fond groupé gris, cellules blanches), et c'est exactement le
   langage de la maquette. Les dialogues restent des cartes blanches sur voile. Ce qui HARMONISE les
   trois largeurs : la même matière à toute largeur, seule la coque change (écran entier / panneau).
   **Étape suivante, À DÉCIDER par l'auteur** : la grille A fait de Sessions et Moi des entrées de la
   colonne (Aides · Sessions · Moi) — en faire de VRAIES vues de la colonne principale ≥ 780 (plus de
   voile, la colonne reste active) suppose un `state.view` par destination, une pile de retour et les
   ~22 surfaces d'audit qui les ouvrent par `openSessHist()`/`openAuth()` ; la page-fenêtre est le pas
   qui ne casse rien et qui reste juste au téléphone quoi qu'on décide ensuite.
7. **Fenêtre Compte** : « Sur cet appareil » (ligne + export), le formulaire de connexion et le vocabulaire
   du journal passent en `.acct-card`, comme le reste ; champ e-mail sur `--amb-2` (gabarit des champs
   d'A350). `.stg-card` et `.cm-list` prennent la carte de travail (fenêtres Stockage et Catégories).
8. **Recherche plus haute en large** : 36 → 40 px, la hauteur des pastilles de sa rangée — pas 44 : la
   maquette y met 44, mais la rangée d'A350 est à 40 et l'en-tête doit garder 60 px accueil et lecture
   (témoin « MÊME hauteur », mesuré 67 contre 60 avec 44).

Témoins adaptés à A351 (quatre rouges de la passe complète, tous lus) : « verrou logo » mesure le logo
AFFICHÉ (colonne dès 780) ; « Diagnostic confirmé » ne compte plus les cartes de session
(`.conf-block.sess-fold`) comme carte du flux ; « P1 · retour au bloc » DÉPLIE les cartes avant de défiler
(page trop courte sinon : 448 px de défilement pour 530 de carte — cas non rencontré) et ne PEND plus
(`page.$('.bkr')` d'une barre cachée faisait attendre `click()` 30 s et emportait la tranche 3/4 — leçon
A89 rejouée) ; « rangée d'actions » admet un seul contrôle à l'accueil ≥ 780 (grille A). Le rouge
« billet mort » du partage était la charge machine (vert seul). Après la page-fenêtre : « trois gabarits »
lit 24/800 sur une `.page`, la bande collante des catégories se mesure au bord de CONTENU du corps (qui
respire de 4 px), et le témoin de partage compare l'appariement à un DIALOGUE (« Affichage »), plus au
gestionnaire devenu page.

### A353 — sixième passe (relecture de l'auteur, 23/09/2026 soir) : onze remarques, toutes mesurées

1. **Les préférences d'affichage se retiennent** — vérifié dans le code : « Afficher » (`ac-section`,
   par espace), « Trier » (`ac-home-sort`), « Regrouper » (`ac-home-group` + `data.prefs.homeGroup`,
   qui voyage), « Densité » détaillée/compacte (`ac-home-compact`), « Mode écran » confort/compact
   (`ac-read-compact`) — tous par `spaceKey`, donc par compte. Aucun mode fantôme dans l'interface ;
   un commentaire de `syncZoomWidth` décrivait encore le tableau ≥ 1200 (mort en v5.18) : corrigé.
2. **Le bandeau système (« 2 fiches d'exemple… ») devient une BULLE** : il était une bande
   bord-à-bord sous l'en-tête blanc, qui n'existe plus ; dans la matière v5 tout ce qui n'est pas
   l'ambiance est une carte posée dessus — même dessin aux trois largeurs (marge 12 au téléphone,
   alignée sur la colonne principale dès 780), filet `--primary-200`, `--r-4`, 12-14 px avant la
   carte « Session en cours » (c'était la marge manquante).
3. **Changement d'avis de l'auteur : le filtre revient à GAUCHE de la recherche, en bouton rond
   permanent** (52 px, comme la recherche, qui monte de 48 à 52 au téléphone). Les chips de type ne
   paraissent qu'en recherche (rangée du dessus, inchangée) ; ≥ 780 le bouton est masqué, la colonne
   filtre. `.ft-lbl` purgé (règle 14). Renverse la moitié « déclencheur dans la recherche » d'A238.
4. **Dialogue Terminer** : 14 px entre les boutons et « Maintenir 1,2 s » (l'anneau de focus de
   « Poursuivre », à +2 px, touchait la consigne).
5. **Tableau · Schéma** dans la carte Parcours : gouttière 16, alignés sur le texte de la tête.
6. **État vide** : un seul « ＋ Créer » (la feuille de création choisit le type depuis A349 —
   `data-emptynew="any"` ouvre la feuille sans forcer le cran).
7. **Colonne large** : « Moi » porte les initiales du compte connecté ; le pied « Compte »
   doublonnait (même fenêtre) et disparaît — le socle garde la ligne d'état.
8. **En-tête d'aide** : « · discriminant » à 6 px du titre (l'espace de tête d'un nœud texte se
   compressait), 13,5 px sur la ligne de base du titre.
9. **« Mode écran »** (menu ⋯ en session) = la bascule confort ↔ compact des rangées d'étapes
   (`toggleReadCompact`, ex-rangée `.rd-tools` sous les étapes, remontée au menu en A351 à la
   demande de l'auteur : 52 px et corps 15 au lieu de 64 et 17,5). Elle reste ; si l'auteur la juge
   sans objet depuis A345, elle se retire d'un bloc (deux règles CSS, une tuile, une clé).
10. **Bilan « Session terminée »** : croix centrée sur la hauteur de la carte (`inset-block:0;
    margin:auto`), carte à la matière v5.
13. **Logo au téléphone** : MESURÉ PRÉSENT à 320 et 390 px, thème clair et sombre (30 px, encre à
    la marge). Rien changé ; la capture de l'auteur (rognée en haut) ne permet pas de dire quel
    écran manquait — à revoir sur une capture entière.
14. **La recherche du téléphone prend le rayon des cartes** (`--r-4`, la maquette) et le bouton de filtre
    prend SA matière (filet `--work-line`, encre `--ink-2`, ombre courte) : il portait un filet de
    composant et une encre d'action au repos — deux voisins de même rangée qui ne disaient pas la
    même chose. Le bleu ne revient qu'à l'état « filtres posés » (`.act`), où il est une information.
15. **UNE feuille « Affichage » pour le rangement ET les filtres** (proposition de l'auteur : « fusionne
    filtre et affichage dans ce même bouton »). Les deux feuilles se recouvraient déjà : « Afficher »
    (Tout · Aides · Protocoles · À relire) ÉTAIT la famille type de la feuille Filtrer. La feuille Filtrer
    est donc PURGÉE (règle 14 : `#filtSheet`, `paintFiltSheet`, `openFiltSheet`/`closeFiltSheet`,
    `paintFiltFoot`, `filterbarHtml`/`typebarHtml`/`catbarHtml`, `updateHdrSec`, `state.filtersOpen`,
    `.typebar`/`.catbar`/`.scope-lbl`/`.catchip.mgr`) et la feuille Affichage reçoit ce qui lui manquait :
    le groupe « Catégorie » (chips, `catChipsHtml`) après « Afficher », et le PIED « Tout effacer (n) ·
    Voir les n résultats » (le compte est celui de la liste réellement rendue, `paintViewFoot`). Chaque
    geste agit en direct derrière la feuille, qui se repeint ; « Tout effacer » remet type, catégorie,
    bibliothèque et « à relire » à zéro. La PORTE au téléphone est le bouton rond du dock (`#filtTog`,
    « Affichage et filtres — n actif(s) », badge chiffré, `.act` filtres posés) ; « Affichage » de la
    rangée de liste (`#rangBtn`) s'efface sous 780 (deux portes pour une feuille, § 5.5) et reste la
    porte ≥ 780, où la colonne filtre. Le fragment « filtres : … » de la ligne Répertoire ouvre la même
    feuille. Dès 780 le groupe « Catégorie » ne paraît pas : la colonne filtre déjà (comme « Gérer »).
    Témoins : « la feuille de filtres » (familles = groupes `.vs-h`, crans = segment
    `[data-vs="filt:…"]`, bouton À GAUCHE de la recherche sur sa rangée), « trois crans » (quatre avec
    « À relire »), « trois gabarits » (`viewSheet` = le CHOIX centré), a11y « feuille affichage &
    filtres », état vide (`any`).
16. **La fenêtre Compte relue à la mesure (demande de l'auteur), et les boutons de toute l'application
    avec elle.** Six incohérences : une même classe à deux corps (`.st-hint` 11 sous les réglages, 13,5 sous
    l'identité — `.ai-card p` l'emportait), une graisse 650 hors du jeu (e-mail, dépliant « Pourquoi »), deux
    corps d'intertitre en capitales (12 et 13,5), une étiquette de champ à 11, des segments à trois corps
    (12 · 13,5 · `--t-meta`), et les boutons `.btn` restés à 13,5/600 d'avant la refonte — plus petits que
    le libellé « Thème » qu'ils accompagnent. Décision (échelle A6, quatre paliers dans une fenêtre, rien
    sous 12) : libellés 15/700, corps 13,5/400, légendes et capitales 12 (`.st-hint`, `.danger-caption`,
    `.acct-more`, `.auth-label`, `.mem-section-h` — règle `.ai-card :is(p.st-hint,…)` qui bat `.ai-card p`),
    650 → 700, segments 13,5/700 partout (12 sous 360 px effectifs dans la feuille Affichage : « Protocoles »
    débordait de 5 px à 320, mesuré ; « Catégorie » y devient « Catég. », comme « Biblio. »), **`.btn` à
    15/700 pour toute l'application** (`.btn.sm` 13,5/700, `.btn.outline-danger` et les deux boutons du
    dialogue Terminer alignés). Débordement vérifié à 320 px sur accueil, sélection, Affichage, Compte,
    Sessions, lecture, session, Terminer et menu : aucun bouton à texte ne déborde (les 2-8 px des pastilles
    à glyphe sont leur halo `::after`, compté dans `scrollWidth`).

### A354 — septième passe (24/09/2026) : « Références » en carte, « Consulter » quitte la session

1. **« Références » est une carte dépliable sous À vérifier · Diagnostics différentiels · Repères**
   (schémas, documents, sources, renvois « Voir aussi » — le contenu de la feuille Consulter SANS les
   différentiels, qui ont leur carte : `refSheetHtml(f,sansDiff)`). Elle se câble à l'OUVERTURE
   (`bindRefsCard`, `WeakSet`) : ses vignettes PDF comptent comme une ouverture, une carte fermée n'en
   demande aucune. Avec elle disparaissent la touche « Consulter » du quai (`#refBtn`), la rangée
   « Consulter » sous la fiche (`.annex-row`, purgée ; `annexRowHtml` → prédicat `refContentKinds`)
   et la colonne « Consulter » du cockpit (A15 : `refInCol`/`renderRefCol`/`.ref-col`, purgées) — en
   session il n'y a plus qu'UNE porte, la carte. La feuille reste la porte d'AVANT la session (tuile
   du menu ⋯) et se ferme à l'entrée en session. Le quai passe à QUATRE touches de largeur égale ;
   « Fin » prend le gabarit de ses voisines (glyphe sur mot, `flex:1`) et ne garde que son registre.
   Témoins : audit-consulter réécrit (feuille avant, carte pendant, aucune carte morte), « pile du
   quai » d'audit-retour retiré avec l'excursion, dock « quatre touches », a11y et pdfsearch ouvrent
   la feuille par `openRefSheet()`, repère du harnais de partage = `.local`.
2. **« Mode écran » retiré** (l'auteur visait le Moniteur, qui existe) : une seule taille, celle
   d'A345 (rangées 64, corps 17,5) ; `toggleReadCompact`, la clé `ac-read-compact` et ses deux règles
   sont purgées.
3. **Le rail (≥ 780) n'a plus « Terminer la session… »** : « Fin » au quai est la porte à toute
   largeur ; le volet étroit garde sa rangée (non demandé). Amende A336 sur le rail.
4. **La capsule ne monte dans l'en-tête qu'au BUREAU (≥ 1440, `mqHdrCap`)** : une tablette en
   paysage (1180-1366) garde la bande sous l'en-tête, comme en portrait — l'auteur voyait deux
   dessins pour un même appareil. Le créneau `#hdrCrisisSlot` n'existe qu'à ce palier (déclaré dans
   `check-paliers`) ; le cockpit à trois colonnes reste à 1200. Amende A348.

### A355 — huitième passe (24/09/2026, canevas « Quai et carte de session v5 ») : filets du quai, rangée vive sans aplat

Deux explorations dessinées sur canevas (Claude Design), l'auteur a choisi la planche A des deux.

1. **Le quai sépare ses touches par un FILET discret** : 1 px, 28 px de haut, `--sys-line` (la matière
   des filets du quai), centré dans l'écart de 4 px, par pseudo-élément `::before` sur toute touche
   visible qui a une touche visible avant elle (`.sd-key:not([hidden])~.sd-key:not([hidden])`) — aucun
   nœud, aucune touche ne change de forme ; hors session (Démarrer · Exercice à air) aucun filet.
   Écartée : une tuile par touche (7 % de blanc), qui aurait créé une seconde famille de surface dans
   le quai.
2. **La rangée « session en cours » perd son aplat vert** (`--ok-soft`, jugé obsolète par l'auteur) :
   carte blanche comme ses voisines, liseré au registre CONFIRMATION porté à 6 px (celui de la carte
   « Session en cours » juste au-dessus), et l'état « ● En cours 12:04 » en vert à point — un glyphe et
   un mot, jamais un fond (règle 8). Vue compacte (livre à filets) : même dessin, liseré 4 px, mesuré à
   390 px dans les deux densités. Écartées : la pastille système du chrono (deux matières sur une
   rangée), l'anneau vert (un second contour de « courant » à côté du bleu du bloc).

### A356 — neuvième passe (24/09/2026) : légende « réponse attendue », volet sans « Terminer », contraste de la carte vive

1. **La légende « réponse attendue » d'un bloc parle avec la voix des réponses** (`.stp-r` : mono,
   capitales, 13,5/600, `--ink-2`) — plus de pilule `.lg-r` (purgée) : un seul dessin pour un seul
   objet, celui qu'A351 a fixé pour les réponses en mono neutre.
2. **Le volet du quai (étroit) n'a plus « Terminer la session… »** : après le rail (A354), la rangée
   du volet part aussi — « Fin » au quai est la seule porte à toute largeur, la fenêtre « Terminer la
   session ? » reste la confirmation. `.rt-sess`, `.rt-since`, `.rt-end*`, `.rt-endtag` et `#rtEndSess`
   purgés (règle 14). A336 est ainsi amendée en entier : la session se termine au QUAI.
3. **Contraste des boutons de la carte « Session en cours » de l'accueil, mesuré à la composition
   alpha** : au téléphone le bord de « Terminer » tenait 1,62:1 (clair) et 1,21:1 (sombre) — bord de
   1,5 px au registre critique (7,1 / 6,2:1) ; sur la BANDE ≥ 780 l'encre de « Terminer » héritait
   de `--critical` (2,24:1 en clair sur la matière système) — encre et bord `--crit-sys` ; et
   « Reprendre » (fond `--sys-2` à 12 %, 1,45:1) prend un fond `--sys-ink` à encre `--sys` (9,4 /
   13,1:1). ⚠ Un bord en `color-mix(… , transparent)` s'évalue mais ne contraste pas (1,3-1,9:1
   mesurés) — le bord se dit en plein.
4. **La bande de session ne s'étire plus sur le rail (≥ 780)** : elle s'étirait de bord à bord (806 px à
   834, 1152 à 1180 — « trop grande ») ; elle garde la largeur de la colonne principale
   (`100% − --col-state − --col-gap`, gouttière 18 : 498 px à 834, 804 à 1180), alignée sur les cartes
   du bloc, comme la planche tablette — et la même HAUTEUR qu'au téléphone (64 px : son rembourrage
   de 10 px la faisait 72). Au bureau (≥ 1440) elle monte dans l'en-tête (A354).
5. **La carte « Session en cours » de l'accueil est la MÊME bande système au téléphone** qu'à la tablette
   et au bureau (demande de l'auteur) : matière `--sys`, encre `--sys-ink`, « Reprendre » plein clair,
   « Terminer » au registre critique système ; seule la composition diffère (grille à deux rangées sous
   780). La carte blanche à liseré vert d'A351 est retirée — un seul dessin pour un seul objet.
6. **La légende « réponse attendue » descend d'un cran** (« ça saute trop aux yeux ») : mono, 12 px,
   minuscules, `--ink-2` — même voix que les réponses, un ton plus bas.
7. **La Page (feuille A4) ne défile plus en elle-même à la souris** : A343 ne clôturait l'axe vertical
   qu'au média tactile (`hover:none and pointer:coarse`) ; au pointeur fin `.sv-scroll{overflow:auto}`
   gardait un défileur interne — mesuré `overflow-y:auto` en pointeur fin, `clip` en tactile. L'axe
   vertical est clos dans la base, l'horizontal reste celui de la feuille.
8. Le bouton « ↩ Reprendre — ‹bloc› → » en tête d'une carte de complication est MESURÉ présent (390 et
   1024, `cxBackHtml`) ; l'écran où il manquerait reste à montrer.

### A357 — dixième passe (24/09/2026, canevas « Dépliants de session v5 ») : une grammaire pour cinq dépliants

Mesuré d'abord : les cinq dépliants de session portaient cinq dessins — rangées nues à 17,5 (« Ne pas
oublier », en retrait de 56 px), tuiles à filet gris avec le « :: » resté en clair (« À vérifier »,
« Diagnostics »), nom ambre à △ et corps (« Repères »), une carte DANS la carte avec un second intertitre
« RÉFÉRENCES » (« Références ») ; et la tête de « Ne pas oublier » (bouton `.fs-btn` à part) avait son
propre compte en pilule et son propre chevron, en gris, à 48 px — les autres, 54 px, encre pleine, compte
et chevron bleus. L'auteur a choisi la planche A du canevas, SANS marque de registre sur les rangées (la
tête dit déjà la famille — A345 tient), et SANS filet sous la tête (elle borne déjà la liste).

1. **Une tête** : `foldHeadHtml` (badge, titre, compte `.conf-sub`, chevron `.conf-chev`) prend un `id`
   optionnel ; « Ne pas oublier » en session l'emploie (`#fsTgl`, `data-sessfold` inerte), son gestionnaire
   ne repeint plus que le chevron ; `.fs-k/.fs-btn/.fs-kt/.fs-tgl/.fs-cnt/.fs-chev/.fs-sp` purgées (règle 14 ;
   `check-ids` apprend la fabrique).
2. **Une rangée** : texte 15 dès la gouttière de 16, 44 px, un filet `--work-line` ENTRE les rangées et
   aucun sous la tête, réponse ou dose en mono dessous (`.sf-ans` : la voix des réponses attendues,
   `--t-body`/600, capitales, `--ink-2`) ; `staticBlock` sépare « :: » (`stepCR`) et le libellé qui porte
   une réponse passe en 700. Repères : nom en encre pleine sans △, dose en mono. Références : plus de
   carte imbriquée, un intertitre 12 capitales par famille (`summary` gardé à 44 px), sources numérotées
   en mono sur 28 px (compteur CSS), documents et renvois inchangés.
3. Écartée : la variante B (tuiles des étapes sans case) — ces cartes se lisent, la tuile est réservée
   au geste (A345).

### A358 — onzième passe (24/09/2026) : une seule carte dépliable, avant et pendant la session

L'auteur : « ce serait donc un code différent, pourquoi ne pas éviter les doublons ? Il y a un rationnel
contraire ? » — Non. L'écran d'entrée (A347 : « Quand l'utiliser », « Ne pas oublier », « Parcours ») et
la session (A351 : À vérifier, différentiels, repères, références) partageaient déjà la TÊTE
(`foldHeadHtml`) mais pas la carte : trois conteneurs (`.conf-block.entry`, `.forget-strip.pre` /
`.fs-foldable` avec son propre bouton `#fsTgl`, `.fold-card` de session), trois habillages de rangées, et
« Ne pas oublier » avait son propre gestionnaire de pli. Le seul rationnel qui tienne est l'ÉTAT : par
fiche et persistant avant la session (mdFold, ouvert par défaut), transitoire et fermé pendant
(`state.sessFold`). Il ne justifie pas trois dessins.

1. **`foldCardHtml(k,ic,title,count,open,inner,{crit,cls,attr})`** : UNE fabrique — tête `foldHeadHtml`
   + `.sf-body` — pour « Quand l'utiliser » (classe `entry` gardée pour les témoins), « Ne pas oublier »
   (classe `forget-strip` gardée, dans les DEUX régimes) et les cartes de session. La porte dit le régime :
   `data-prefold` re-rend (état par fiche), `data-sessfold` bascule sur place (état transitoire).
   `#fsTgl`, `state.fsOpen`, `fsChev`, `.fs-foldable`, `.fs-closed`, `.forget-strip.pre`, `.cf-mk` (le ● par
   critère) et les colonnes `.many` sont purgés (règle 14) ; `.sess-fold` devient `.fold-card`.
2. **La grammaire de rangée d'A357 vaut aux deux régimes** : filet ENTRE les rangées, aucun sous la tête
   (la liste ne porte plus le filet de tête du bloc de confirmation), « Le tableau ne colle pas ? » est la
   dernière rangée de « Quand l'utiliser ».
3. **Seconde ligne des différentiels et des repères en corps 13,5 sans, encre secondaire** (demande de
   l'auteur : la mono en capitales pesait trop sur des phrases) et en ENCRE PLEINE (« pourquoi en gris ? » : c'est
   le contenu clinique, pas une méta) — la mono reste aux réponses courtes des étapes. **Références** : l'intertitre de la famille des sources s'appelle « Sources » dans la carte
   (« Références » redoublait le titre), et un intertitre seul s'efface (la tête suffit).

### A359 — douzième passe (24/09/2026) : les boutons de gestion, le champ de recherche, un bord de carte

1. **Tous les boutons d'action sur la matière v5** (demande de l'auteur, « ex. ceux de la fenêtre
   historique ») : la barre de sélection (segment Tout cocher / décocher à filet `--work-line` et ombre
   courte, corps 15, « Supprimer… » en rouge doux), les boutons des dialogues (`.dlg-actions`, `--r-3`,
   corps 15, blanc à filet au lieu du contour 1,5 px transparent), « Rejoindre » du bandeau de code
   (`--act`, `--r-3`), le contour danger (`--r-3`). Les touches du quai, les chips et les liens ne sont pas
   des boutons d'action et ne changent pas.
2. **Champ de recherche du téléphone** : le texte suit la hauteur du champ (17,5 dans 52 px — le 15 y
   paraissait petit), l'icône de filtre passe à 24 px ; le champ large de 40 px garde 15.
3. **Bord bas des cartes de l'accueil** (signalé en sombre) : le livre à filets efface le filet du dernier
   rang de chaque groupe (`:last-child{border-bottom:0}`), règle qui atteignait les CARTES de la vue
   détaillée — la dernière carte d'un groupe perdait son bord bas (visible surtout en sombre, où le bord
   est le seul contour). Une carte garde ses quatre bords.

### A360 — treizième passe (24/09/2026) : la feuille « Actions » de la sélection parle la grammaire du menu ⋯

Demande de l'auteur (maquette comparative validée) : « mets à jour le menu qui s'affiche sur
smartphone/tablette quand on clique sur Actions […] avec le nouveau langage design ». La feuille
était restée au dessin de v4.4.4 (rangées 48 px de corps 13,5 à coins 8, en-tête 13,5/11 sous un
filet, libellés nus).

1. **Une rangée dit ce qu'elle ouvre** : icône 24 px en `--act` (livre, étiquette, corbeille — deux
   entrées de table neuves, `tag` et `trash`), libellé 15/600, sous-ligne 13,5/500 `--ink-2` (« choisir
   la bibliothèque de destination », « confirmation demandée »), chevron `--ink-3` quand l'acte ouvre
   un second choix. `openPickMenu` gagne trois clés de rangée facultatives (`ic`, `sub`, `chev`) — la
   même fabrique sert toujours les sélecteurs de catégorie et de bibliothèque, qui n'y touchent pas.
2. **La feuille sur la matière de travail** : `--work`, coins `--r-4` en haut, ombre `--shadow-up`,
   gouttière 16 ; en-tête « n cochés » 17,5/700 + portée 13,5 en colonne, SANS filet (le contexte se
   lit avant l'acte, l'espace suffit à l'en sortir) ; rangées 52 px, filets `--work-line` ENTRE les
   rangées seulement ; la rangée danger tenue à l'écart par 10 px et son filet, corps 700 ; « ＋
   Nouvelle catégorie » à 52 px et `--r-3`. Le menu ANCRÉ (≥ 780, éditeur) garde son dessin : la
   règle vit sous `.catmenu.sheet`.
3. **Le témoin doctrine « sans critères »** lisait `.conf-block`, devenue depuis A357 la classe de
   TOUTE carte dépliable : il vérifie désormais l'absence de la carte « Quand l'utiliser »
   (`.fold-card[data-sf="when"]`).

### A361 — quatorzième passe (24/09/2026) : un seul dessin de menu, et le menu ⋯ en feuille basse

Question de l'auteur après A360 : « on reprend les mêmes éléments design pour optimiser le code ? »
Réponse mesurée : non — la grammaire « icône · libellé · sous-ligne · chevron · danger » existait
DEUX fois (menu ⋯ et sélecteurs) avec des valeurs divergentes (13,5/20 px/`--link`/sous-ligne 12
contre 15/24/`--act`/13,5), et le menu ⋯ restait un menu ancré blanc sous le pouce. Décision de
l'auteur : « fais les deux ».

1. **Une rangée, une fabrique** : `menuRowHtml({label,sub,ic,dot,col,danger,disabled,attrs,tail})`
   émet la rangée `.mm-row` des deux menus — icône dans un slot de 24 (`ic:''` garde le slot pour
   l'alignement, le SVG est normalisé à 20 par le CSS quel que soit le nombre passé) OU pastille de
   catégorie, `.mm-tx` (libellé `.mm-lb` + sous-ligne `.mm-sub`), queue (coche `.mm-ck`, chevron
   `.mm-chev`). `mmRowHtml` (⋯) et le `row` d'`openPickMenu` ne sont plus que des adaptateurs de
   données ; `.catmenu-row`, `.cm-nm/.cm-ic/.cm-sub/.cm-chev/.cm-ck` et `.mm-row.two` sont purgés.
2. **Une coque, deux états** : `.popmenu` (ancrée : liste blanche à coins 12, rangées 48 à coins 8)
   et `.popmenu.sheet` (feuille basse : `--work`, coins `--r-4`, `--shadow-up`, gouttière 16,
   poignée dans `.popmenu-head`, rangées 52 à filets ENTRE elles, `--sab` dans la marge basse,
   plafond `85dvh ÷ zf`). `.more-menu` et `.catmenu` ne gardent que leur ancrage. Le contexte d'une
   feuille (« n cochés · portée ») s'appelle `.mm-ctx` — `.mm-head` reste l'intertitre de groupe.
3. **Le menu ⋯ devient une feuille sous 780 px** — la décision « ⋯ en feuille basse » (A350) est
   PRISE : `openMoreMenu` monte le nœud `#moreMenu` sur `<body>` (même raison que les sélecteurs :
   fixé dans l'en-tête collant il hériterait de son contexte d'empilement), pose `.sheet` et un
   voile `.popmenu-veil`, le rend à l'en-tête au-delà ; `fitMoreMenu` s'efface devant le CSS en
   feuille ; clavier, focus, plis, tuiles et intertitres inchangés (le nœud garde son id, les six
   harnais qui le lisent aussi). Un 'sep' précède toujours une rangée danger (`mmNorm` le garantit ;
   la feuille le masque et pose sa marge + son filet) — **A337 amendée** : le pied encadré
   `.mm-end` a vécu, le danger n'est qu'une encre.
4. **Témoins** : « le menu ⋯ reste flottant sous un placard » se mesure à 1000 px (le seul état
   exposé à la règle) puis vérifie la feuille à 390 (fixée sur `<body>`, au bas de l'écran, barre
   inchangée) ; « le menu ⋯ tient dans l'écran » admet qu'une feuille descend jusqu'au bord (sa
   marge porte `--sab`) et borne la DERNIÈRE RANGÉE au-dessus de l'indicateur.

### A362 — quinzième passe (24/09/2026) : l'espace entre les cartes rangées ensemble

Demande de l'auteur : « revois l'espacement entre les cartes rangées ensemble dans le tri sur la
page d'accueil ». Mesuré à 390 px : les cartes d'un groupe se TOUCHAIENT (0 px — `.dir-grid` en
bloc, coins 14 qui se chevauchaient) et un groupe n'était séparé du suivant que par 10 px plus son
intertitre — ni les cartes ni les groupes ne se distinguaient. Planche A choisie (« de toute
manière c'est pour ça que la vue compactée existe aussi ») : **8 px entre les cartes d'un groupe,
24 px avant chaque intertitre, 10 px sous lui** — `.dir-grid` devient une colonne flex dans la vue
détaillée étroite, le livre compact à filets ne change pas. Planche B (une pile par groupe, filets
intérieurs) écartée : c'est l'idiome du compact.

Au passage, le témoin partage « rien ne bouge » mesure la dérive DANS le fil (par rapport à
`.ov-journal`) : sous charge, la sonde de lien déclarait « Connexion perdue » pendant la mesure et
posait sa rangée de 41 px dans le quai — le fil descendait d'un bloc sans être reconstruit (dérive
absolue 41 sur deux passes complètes, 0 en isolation). L'absolue et l'état du lien restent en
diagnostic dans le message du témoin.

## Lot v5.30.1 — les décisions restantes sont prises

### A363 — deux signalements et deux écarts clos (24/09/2026)

Décisions de l'auteur sur les écarts d'A350 : **(1) les volets Outils et Journal RESTENT sur la
matière système** (« volets restent en fond sombre ») — clos, la maquette n'est pas suivie sur ce
point ; **(2) le quai garde ses quatre touches** (« on a déjà enlevé une tuile dans le 5.30 »,
A354) — clos. Restent (3) et (4), traités ci-dessous.

Deux signalements : le **titre de la carte « Session en cours » de l'accueil** était plus grand au
téléphone (21/700, A351) qu'en large (17,5/800) — « ça me paraît trop grand » : même corps partout,
17,5/800. Et la ligne **« Minuteurs à disposition en session »** collait au bord gauche de la carte
« Parcours » (marge 0 contre une gouttière de 16 pour tout le reste, 19 px sous elle contre 0 au-
dessus) : elle prend la gouttière des rangées (`.pre-flow>.carry-line{margin:10px 16px 4px}`).

### A364 — Moi liste les bibliothèques avec leur rôle

Écart (6) d'A350, tranché « ok pour rapatrier ». Dans la fenêtre Compte (et la vue Moi, A365), une
zone « Bibliothèques » après la carte d'identité : Perso (« votre bibliothèque · n éléments ») puis
les partagées triées par nom, chacune une RANGÉE DE MENU (`menuRowHtml`, A361 — icône, nom,
sous-ligne « Rôle · n éléments ») ; seule une bibliothèque ADMINISTRÉE est un bouton (chevron,
ouvre « Modifier la bibliothèque »), les autres sont des rangées INERTES (`inert` : un `<div>`,
jamais un bouton mort — A305) ; « ＋ Nouvelle bibliothèque » pour l'administrateur de l'instance.
Connecté seulement : sans compte il n'y a ni rôle ni partage à lister. Les filets entre rangées
sont la règle de la feuille (`:is(.popmenu.sheet,.acct-list) .mm-row`).

### A365 — Sessions et Moi sont des VUES de la colonne ≥ 780

Écart (4), « OK go sur ce lot ». La grille A fait d'Aides · Sessions · Moi les entrées de la colonne
gauche ; jusqu'ici Sessions et Moi ouvraient une page-fenêtre PAR-DESSUS l'accueil, juste au
téléphone, mais un voile sur une planche large qui garde sa colonne. Désormais :

1. **Les portes ne changent pas** : `openSessHist()` (sans fiche) et `openAuth()` décident —
   sur l'accueil ≥ 780 (`homeTabsOn`) elles posent `state.homeTab` et re-rendent ; partout ailleurs
   (téléphone, depuis une fiche, historique d'UNE fiche) elles ouvrent la page-fenêtre comme avant.
   Le contenu est rendu par les MÊMES fonctions : `renderSessHist`/`renderAuth` visent la vue
   (`#sessView`/`#meView`) si elle est rendue, la fenêtre sinon — aucun second rendu.
2. **La vue** (`renderHomeTab`) : colonne gauche intacte et ACTIVE, colonne principale au gabarit
   DOCUMENT de la page-fenêtre (720, titre 24/800 — une seule déclaration avec `.ai-modal.page h3`).
   La rangée de navigation active porte `aria-current`, plus d'`aria-haspopup` (ce ne sont plus des
   dialogues). « Créer » se cache hors de la liste ; un filtre de la colonne ou une saisie dans la
   recherche RAMÈNENT à la liste (chercher, c'est chercher une aide) ; le retour système ferme la vue
   vers la liste (`_histBackAction`, sentinelle armée à l'ouverture) ; la sélection multiple se
   termine en changeant de vue.
3. **Au franchissement de 780** (`syncHomeTabs`, sur le `change` de `mqHomeWide`) la surface change
   de peau sans se perdre : une vue ouverte devient la page-fenêtre correspondante en étroit, une
   page-fenêtre globale ouverte devient la vue en large. ⚠ Le pane du navigateur de l'éditeur
   n'émet PAS ce `change` sous émulation (mesuré) : la conversion se vérifie en appelant
   `_onHomeBp()` à la main, un vrai redimensionnement l'émet.
4. **Témoins** : « trois gabarits de fenêtre » (1100) et « le bouton focalisé se voit » (1280)
   ouvraient Compte et Sessions depuis l'accueil — la page-fenêtre, seule mesurée, s'ouvre désormais
   depuis une fiche ; `audit-modeseg` (900) lit `#dispSeg` dans la vue Moi sans y toucher ; les
   surfaces a11y à 390 restent des fenêtres.

### A366 — troisième liste de l'auteur (24/09/2026) : onze points

1. **Pied de la colonne gauche** : deux traits et rien entre (le `.hs-sep` du pied ET le
   `border-top` du pied de page) — le pied de page perd son trait.
2. **La feuille « Affichage » a le MÊME contenu à toutes les largeurs** : les chips de catégorie et
   la rangée « Gérer » n'étaient émises qu'en étroit (la colonne filtre déjà en large, A238) ; les
   deux conditions de largeur tombent — un seul contenu, la colonne reste un raccourci.
3. **« Affichage » et « Sélectionner » sont voisins** : un seul dessin (matière `.btn`, 40 px,
   13,5/700, `--r-3`) — l'un faisait 44 px sans bord en bleu, l'autre 32 px à filet en 12/700.
4. **Les vues Sessions et Moi se centrent** dans la colonne principale (720, `margin-inline:auto`),
   comme la page-fenêtre.
5. **Les quatre cartes de la session existent AVANT la session** (À vérifier, différentiels,
   repères, Références) sous « Parcours » — une fabrique `foldCardsH(attr,isOpen)` sert les deux
   moments ; avant la session elles sont FERMÉES D'OFFICE, « Parcours » aussi (demande de
   l'auteur) : `PRE_CLOSED`, ouverture mémorisée par fiche sous la clé « o:‹k› » (« Quand
   l'utiliser » et « Ne pas oublier » restent ouvertes d'office, clé nue = fermée ; aucune
   inversion pour les appareils qui portent l'ancienne clé « flow »). La carte Références se câble à
   l'ouverture par le même `bindRefsCard`.
6. **Tuiles du menu ⋯ en feuille** : un filet coupait « Se repérer » et « Schéma » — la règle des
   filets pèse (0,4,0) avec son `:not(:first-child)`, l'exemption des tuiles pesait (0,3,0) ;
   `.mm-row.mm-tile`.
7. **« Parcours » repliée mesurait 62 px** contre 56 : l'étage `.cf-stage` ajoutait ses 6 px de
   `:last-child`, et le premier étage ses 20 — les cartes portent leur marge (10), les étages n'en
   ajoutent plus (le premier garde 10, la marge d'une carte).
8. **✕ de « Session terminée »** (rappel de l'accueil) : centrée par `top:0;bottom:0;margin:auto`,
   elle s'étirait sur toute la hauteur et son survol le montrait — 32 × 32, `top:calc(50% - 16px)`.
9. **« ‹ Actions » dans les sous-feuilles** (bibliothèque, catégorie) ouvertes depuis la feuille
   Actions : `openPickMenu` accepte `back:{label,sub,fn}` (rangée `menuRowHtml` dans l'en-tête
   collant, icône `backto`) ; `_selFromSheet` ne le propose que depuis la feuille.
10. « Consulter » : analyse remise à l'auteur (non tranché).
11. **Plus de pied de page en lecture** d'une aide ou d'un protocole (état de l'appareil, version)
    : `body.view-read`/`.view-pread` le masquent ; il reste à l'accueil et dans Moi.
12. **« Repères posologiques » avait un trait persistant sous son titre** (téléphone et tablette
    portrait, où la carte existe) : chaque `.pos-card` porte un trait `::before` de séparation et
    l'exemption `:first-child` ne visait plus la première carte, précédée du titre de bloc masqué —
    `.block-h+.pos-card::before{display:none}` (mesuré à 375 et 768, avant et pendant la session).
    Témoin « Tableau/Schéma vivent sous Parcours » : il ouvre la carte, repliée d'office.

### A367 — la feuille « Consulter » a vécu (24/09/2026, décision de l'auteur)

Analyse remise (A366 point 10) puis « fais-le, et vérifie que rien ne mène à elle ». Depuis A366 la
page porte les quatre cartes avant la session : la feuille ne montrait plus que ce que la page a
déjà, un étage plus bas. Purge au grep, règle 14 : la fenêtre `#refModal` et ses six fonctions
(`refSheetOpen`, `renderRefSheet`, `openRefSheet`, `closeRefSheet`, `refOpenNow`, `syncRefBtn`),
`refContentKinds`, le CSS `.ref-modal/.rs-bar/.rs-ttl/.rs-body/.rs-flash` (la feuille Plan garde
les siens), le palier 924 (il ne servait qu'à elle — `check-paliers` l'a vu), l'attribut `data-rs`
que plus personne ne lisait (`check-actions`), la tuile « Consulter » du menu ⋯ et la surface
a11y « feuille Consulter ». **Ses trois portes mènent désormais à LA CARTE de la page**
(`openFoldCard(k)` : ouverte SEULE, les six autres repliées, amenée en haut de l'écran) : « Le
tableau ne colle pas ? » → différentiels ; « Documents · n » → Références (qui porte les
documents) ; la tuile disparaît. **Rien d'autre n'y menait** — la recherche de l'accueil ouvre
un document trouvé DIRECTEMENT dans la visionneuse (`data-docgo`), la recherche d'un protocole
vit dans son sommaire ; vérifié au grep (`openRefSheet` : trois appelants, tous reroutés).
`bindRefBody(root,f)` perd son défilement de section, `refSheetHtml` reste la fabrique des cartes.
Harnais : `audit-consulter` réécrit autour des cartes (fermées d'office, lien → carte seule et en
haut, documents dans Références, plus de tuile ni de feuille, carte Références inerte en session,
aucune carte morte) ; `audit-pdfsearch` ouvre le document par « Documents · n » ; doctrine
« memory items » mesure l'inertie de la carte Références.

### A368 — barre d'état iOS 27, et la recherche du bas (24/09/2026)

**Bande floue en haut sur iOS 27** (absente d'iOS 26, « ça floute un peu le début du contenu ») :
le code n'a aucun `backdrop-filter` — c'est le système qui pose un verre flou sur la zone de barre
d'état quand le contenu passe dessous (`viewport-fit=cover` sans style de barre d'état déclaré).
`apple-mobile-web-app-status-bar-style: default` : le contenu commence SOUS la barre d'état, que
le système peint à la `theme-color` (déjà suivie par le thème) ; la zone sûre basse est
inchangée. ⚠ Non mesurable au pane ni au simulateur iOS 26.5 : à VÉRIFIER sur l'iPhone en iOS 27
(l'auteur), et si la bande reste, la piste suivante est la couleur de thème seule.
**Recherche et filtre du bas** : l'auteur revient sur les 52 px d'A359 (« un peu trop grands ») —
44 (la cible tactile), texte 15, icône 20 ; `height` posé, le rembourrage du champ le portait à 47.

### A369 — la bulle d'historique sur la ligne « Parcours » (24/09/2026, planche A)

Demande de l'auteur : diminuer l'espace entre « PARCOURS · x/12 étapes » et le premier bloc, où
vivait la ligne-bilan « ✓ … diagnostic confirmé ⌄ » (44 px + marges : 76 px avant le bloc,
mesurés). Planche A retenue, avec une exigence : « il faut que ce soit clair que c'est bien
l'HISTORIQUE des étapes — on coche les étapes dessous puis ça va dans l'historique au-dessus ».

- **Une phrase de gauche à droite** : PARCOURS (ce que c'est) · la BULLE (ce qui est fait et
  replié — icône d'historique, « Fait · 1→2 · diagnostic confirmé », chevron ; un tap l'ouvre)
  · le compte (où l'on en est). Pilule blanche de 28 px sur la ligne, cible 44 par halo ; le
  libellé s'abrège par points de suspension, le compte ne se coupe jamais (`flex:none`). La
  pilule mesure son TEXTE (`flex:0 1 auto`) — grandissante, elle s'étirait sur toute la ligne en
  large et son chevron partait au bout (signalé sur capture) ; elle se CENTRE entre le titre et
  le compte (marges auto, sélecteur à trois classes pour passer devant la marge de session) ; le
  chevron est UN SEUL DESSIN pour toute la page de lecture (`chevHtml` : `uiIcon('chev', 20)` en trait 2,2,
  gris `--ink-2`, tourné vers le bas fermé et vers le haut ouvert par la classe `open` — cartes, bloc,
  historique, bulle, rails, aperçu du schéma ; capture de l'auteur : « un trait plein, pas rempli », la
  flèche fine « › » d'avant v5.30. Les triangles ▾/▴ et le caractère ⌄ ont vécu ; jamais `--ink-3`, un
  glyphe `aria-hidden` reste peint et mesuré 2,13:1 en v5.6) ; la carte ouverte
  n'a pas de filet sous son bord ; le texte 12/700 est descendu d'un pixel face à l'icône, avec un
  interligne de 1,35 (à 1, le débordement masqué des points de suspension tronquait les jambages) ;
  matière DISCRÈTE (`--amb-2`, sans ombre — elle faisait de l'ombre au bloc). Un seul
  bloc fait s'écrit « 1 », pas « 1→1 ». 36 px avant le premier bloc au lieu de 76.
- **Le mouvement se voit** : quand un bloc coché rejoint la bulle, elle s'allume une fois
  (`.bump`, ombre `--ok-soft` 0,7 s — peinture seule, rien de mis en page ; éteinte sous
  `prefers-reduced-motion`). `renderOvOnly` compare le texte de la bulle d'un rendu à l'autre.
- **Une seule bulle** : la PREMIÈRE série de blocs faits (avant tout bloc affiché) et la
  confirmation d'entrée montent sur la ligne (`histPill`), ouvertes elles déposent leurs rangées
  en carte en tête du journal (`histRows`) ; une série plus bas (après une excursion) reste une
  ligne du fil, même fabrique `runPill`. Sans ligne « Parcours » (aucune étape comptée) la bulle
  reprend la tête du fil. Sous 360 px effectifs la ligne RESTE (elle porte l'historique), seul le
  mot « Parcours » cède (amende la règle « écarts du préambule »).
- **Les colonnes latérales ne bougent plus à l'ouverture** (signalé « surtout avec plusieurs
  blocs dans l'historique », mesuré +50 px à 1280 page défilée) : une colonne collante plus haute
  que l'espace sous elle bute contre le bas de sa rangée de grille et SUIT toute croissance de la
  colonne principale. Elles passaient 64 px sous le quai : leur hauteur retire désormais
  `--dock-h`, elles s'arrêtent au-dessus du quai (mesuré : 148 px avant, pendant, après, page en
  haut, défilée et au bout). Deux voies écartées et mesurées : un plancher de hauteur sur la grille
  (la marge basse de `main` fait scroller plus loin que la rangée ne peut absorber) et l'ancrage du
  bloc courant (`renderOvOnlyKeepAnchor` : page courte, la compensation se cogne au défilement
  maximal et les colonnes non collées montent).
- **Une seule écriture pour compter et déplier** (demande de l'auteur) : le compte du bloc
  (`.ov-c`) et celui des rangées d'historique (`.ovh-n`) s'écrivent comme celui des cartes
  dépliables (13,5/600 `--ink-2`, plus de mono 11) ; le chevron du bloc (`.ov-chev`) et celui des
  rangées d'historique (elles en gagnent un, `.conf-chev` ▾) sont celui des cartes (17,5/800
  `--link`) — une règle commune `.conf-chev,.ov-chev` ; les rangées d'historique se centrent
  (`align-items:center`, la coche et le chevron ne s'alignaient pas sur une ligne de base).
- Témoin « Diagnostic confirmé vit dans le journal, en tête » : « en tête » = sur la ligne
  « Parcours » ; le libellé absorbé se reconnaît à « Fait ».

### A370 — iOS 27 : le verre flou du bord haut, mesuré (24/09/2026)

**Le signalement.** « Sur iOS 27 sur iPhone il y a une bande floue » en haut de l'app installée, encore
là après la réinstallation d'A368. Piste de l'auteur : un fil Reddit « iOS 27 beta blurs the top edge
of installed PWAs ».

**Ce que disent les forums et les dépôts** (MacRumors, MeshMonitor #5286, grappa-irc #2190, dozzle
#5222, fin-app #411, holy-grails #191, mono-agent #1028, Frigate #24414) : depuis iOS 26 le système
remplit l'inset de la barre d'état d'un « scroll edge effect » Liquid Glass — un voile + flou en
DÉGRADÉ, pas un filet — et iOS 27 l'a rendu franc. Aucune balise ni propriété ne l'éteint ;
`env(safe-area-inset-top)` ne grandit pas pour l'absorber. Deux camps de remède, tous deux contestés
par leurs propres auteurs : (a) sol opaque fixé sous l'heure (MeshMonitor, mono-agent — « à confirmer
sur appareil ») ; (b) retirer `black-translucent` pour `default` (fin-app, holy-grails) — dozzle l'a
fait puis mesuré « amélioration négligeable : la bande est ancrée à la zone sûre, où que la page
dessine ». Certains mainteneurs (Frigate) classent le sujet côté Apple et ne corrigent pas.

**Ce qui a été mesuré ici, au simulateur iOS 27.0 (iPhone 17, app ajoutée à l'écran d'accueil).**
1. Le style `default` d'A368 n'a JAMAIS été en vigueur : le `<head>` portait DEUX balises
   `apple-mobile-web-app-status-bar-style`, `default` (A368) puis `black-translucent` (historique),
   et la seconde l'emportait — « réinstallée, la bande est toujours là » mesurait donc l'état
   d'avant. Une seule balise désormais, `black-translucent`, avec son commentaire.
2. Sonde rouge : le sol fixé sous l'heure (`body::before`, hauteur `env(safe-area-inset-top)`,
   opaque, pleine largeur, z 90, PAS `pointer-events:none` pour ce test) est bien peint — et lu
   rgb(245,136,137) au lieu de rouge pur : le système compose SA couche PAR-DESSUS la page (voile
   blanc ≈ 50 %), sur l'inset entier (0 → 60 pt) puis en fondu jusqu'à ≈ 76 pt, où le titre d'une
   carte qui passe dessous est flouté. Rendre le sol testable au toucher n'a rien changé, et un VRAI
   `<div>` fixé (l'hypothèse « WebKit ramène un `::before` à son hôte au hit-test ») non plus : mêmes
   mesures. La sonde `LocalFrameView::fixedContainerEdges` de WebKit (un fixé opaque ≥ 90 % de large
   au point (centre, 4 px) colore la bande) ne SUPPRIME pas cette couche dans une app installée
   iOS 27. Et la bande se voit AU REPOS aussi (signalement de l'auteur, page tout en haut) : le voile
   éclaircit l'inset et son fondu s'arrête à ≈ 76 pt, juste au-dessus de l'en-tête — c'est le bord
   de ce fondu qu'on voit, pas du contenu flouté.
3. Le remède retenu est donc celui d'un voile qu'on ne peut pas retirer : le rendre INVISIBLE. Sur
   un aplat uni (`--bg`), voile et flou ne se voient pas ; reste le fondu de ~16 pt sous l'inset,
   là où une carte qui défile passe dessous — c'est le comportement de toute app native iOS 26+
   (Réglages, Mail). Le sol couvre TOUTES les vues (accueil, lecture, édition, aides et
   protocoles), z 90 au-dessus des fenêtres (55) et des feuilles (70) : une page-fenêtre (Moi,
   Sessions) fait défiler son contenu sous l'heure. Coût nommé : sous un voile de feuille, la
   bande de l'heure reste claire pendant que la page s'assombrit.
4. Le style `default`, MESURÉ cette fois (seconde icône « Aides cog. D » ajoutée depuis Safari avec la
   balise unique à `default`) : la barre d'état devient un verre gris OPAQUE — plus sombre que la page
   d'environ 15 niveaux (rgb 223-233 contre 244), dégradé de ~10 pt sous son bord — et le contenu
   n'est plus JAMAIS flouté au défilement (coupé net au bord de la vue web). Donc pas « rien »
   comme dozzle, mais une autre bande : sombre et nette au lieu de claire et fondue. Et l'app n'est
   pas écrite pour `env(safe-area-inset-top)` = 0 : sur la fiche, l'en-tête collant a disparu et
   la page a débordé à droite au premier défilement — choisir `default` demanderait une passe sur
   tous les lecteurs de l'inset (`--sab`, paliers, chrome collant). Reste au choix de l'auteur.
5. Écartés : allonger le sol de 16-20 pt sous l'inset pour effacer aussi le fondu — sur l'accueil
   l'en-tête est STATIQUE (A238) et son titre commence à ≈ 81 pt, le sol le couperait ; il
   faudrait descendre tout l'accueil de 20 px. Retirer `viewport-fit=cover` — la page ne passerait
   plus sous l'heure, mais dozzle a mesuré la bande au même endroit et l'app perdrait le bord à
   bord. Les deux restent des choix possibles de l'auteur, pas des corrections.

En THÈME SOMBRE au repos, colonne de pixels : rgb(13,16,19) de 10 à 87 pt, identique au fond — le
voile du système suit le thème et ne se voit pas ; la bande est un sujet du thème clair.
⚠ À VÉRIFIER SUR L'IPHONE après mise à jour (le sol arrive par la mise à jour, la balise unique
exige une réinstallation) ; une capture de l'iPhone au repos dirait si le voile y est plus fort qu'au
simulateur.

### A371 — le pied de lecture qu'on croyait masqué (24/09/2026)

A366, point 11 (« plus de pied de page en lecture ») avait posé `body.view-read footer.tools
{display:none}` — une règle DÉJÀ présente depuis des versions (`:is(body.view-read,…) footer.tools`),
donc un correctif mort : le pied visible en lecture n'était pas `footer.tools` mais une rangée
`.crisis-footer` émise par `readFooterHtml()` dans le rendu de la fiche ET du protocole (état de
stockage à gauche, version à droite). Trouvé parce que l'app installée du simulateur montrait encore
« Cet appareil seulement · 4,7 Mo · v5.30.1 » alors que toutes ses copies en cache portaient la
règle : quand une règle « ne prend pas », vérifier D'ABORD que l'élément visible est celui qu'elle
vise. Purgé (règle 14) : la fabrique, ses deux sites d'émission, son rafraîchissement dans
`updateStorageInfo` (et les deux appels qui ne servaient qu'à lui), les quatre règles CSS dont celle
d'impression, et le doublon de v5.30.1. Le papier perd sa ligne de version : la validation et le
code sont déjà dans la méta du haut de page (raison même de cette ligne, v5.0).

### A372 — « Recevoir le code » : la fenêtre qui disparaît sous le clavier (24/09/2026)

Signalé sur iPhone : après « Recevoir le code », la page-fenêtre « Compte & synchronisation » a
disparu ; fermer et rouvrir a montré l'étape du code. L'état (`_authStep.mode='code'`) avait donc
bien été posé et la fenêtre rendue — c'est sa POSITION qui était perdue. NON reproduit au
simulateur (chemin d'erreur, adresse invalide puis délai réseau : la fenêtre reste), ni en WebKit
de bureau (envoi simulé : fenêtre en place, étape du code présente). Cause la plus probable, par
la doctrine du viewport visuel (J208, `unpan`) : le champ e-mail est encore ACTIF sous le clavier
quand `renderAuth()` remplace le DOM ; un champ retiré ne fait ni `blur` ni `focusout`, le clavier
se ferme sans passer par la voie normale, et WebKit peut laisser les deux viewports décollés —
la fenêtre fixée reste remontée hors écran. Correctif défensif : `renderAuth()` relâche le champ
actif (`blur()`) AVANT de remplacer le DOM, sur tous ses chemins (succès, échec, invalide). Au
passage, une adresse refusée par le contrôle local n'efface plus le champ (`_authStep.email`
gardé). ⚠ À CONFIRMER sur l'iPhone : si la fenêtre disparaît encore, mesurer `visualViewport.offsetTop`
au moment du re-rendu.

### A373 — le contenu descend sous le fondu d'iOS 27, et c'est réversible en une ligne (24/09/2026)

Retour de l'auteur sur 5.30.2 : « c'est encore un peu gênant » au repos. Le sol d'A370 rend le voile
invisible sur l'inset, mais son FONDU (~16 pt au-delà, mesuré) tombe sur le haut de l'en-tête. Décision
de l'auteur : descendre le contenu d'autant, **en le nommant** pour pouvoir revenir en arrière si Apple
corrige. Mécanisme : un token `--ios27-top:min(env(safe-area-inset-top,0px),16px)` — nul partout où il
n'y a pas d'inset (navigateur, Mac), 16 px dès qu'il y en a un — et `--sat:calc(env(safe-area-inset-top)
+ var(--ios27-top))`, que lisent DÉSORMAIS tous les consommateurs de l'inset haut (quinze sites : en-tête,
sol `::before`, `.dir-l`/`.sel-bar`, alertes, plein écran du schéma, moniteur, croix de la lightbox,
fenêtres et pages-fenêtres, barres PDF et Page, lien d'évitement). Le sol couvre donc l'inset ET le
fondu ; l'en-tête commence sous les deux. **Retour arrière : `--ios27-top:0px`, rien d'autre.** Les
navigateurs ne changent pas d'un pixel (sonde : sol 0 et en-tête inchangés sans inset ; sous un inset
simulé de 62 + 16 = 78 px, sol 78 px, en-tête à 90 px de rembourrage). `--sab` reste l'inset bas nu.

**Le pied de l'accueil au téléphone retrouve le numéro de version** (rangée `.foot-min`, visible au seul
accueil < 780 ; le socle complet reste la règle en large), et **« Un problème ? » vit dans Moi / Mon
compte** (carte « Sur cet appareil », dans les deux états, connecté ou non) : il ouvre la fenêtre de
stockage, qui porte « Réparer l'application » — la maquette v5 avait masqué tout le socle au téléphone
(A347), et avec lui la seule issue d'une app installée bloquée sur une vieille version. Première
version au pied de page, déplacée dans Moi à la demande de l'auteur.

**Le code de connexion se colle** : signalé « je ne peux plus coller mon code dans la barre ». Aucun
bloqueur trouvé dans le code (pas de `user-select`, pas de `paste` intercepté, pas de re-rendu au
focus) ; non reproductible sans appareil. Durcissement : un collage ne garde que les CHIFFRES (un
code copié depuis Mail arrive souvent avec des espaces ou du texte autour), `enterkeyhint="done"` et
Entrée valide. Le chemin prévu reste la suggestion d'iOS au-dessus du clavier
(`autocomplete="one-time-code"`, que Mail alimente depuis iOS 17). Précision de l'auteur : **la bulle « Coller » est ABSENTE**. Sur iOS, c'est
la signature d'un `-webkit-touch-callout:none` au-dessus du champ — et le seul qui couvre TOUTE la page
est `body.hold-noselect` (posée par `holdToReset` pendant un « Maintenir », qui bloque sélection et
bulles autour du bouton). Sa fin ne s'écoutait que SUR LE BOUTON : un bouton de remise à zéro re-rendu
pendant l'appui (tick des minuteurs, `renderKeepAnchor`) est DÉTACHÉ avant son pointerup, la classe
reste collée au body pour toute la session, et plus aucune bulle « Coller » n'apparaît nulle part —
jusqu'au rechargement. Correctif : la fin du geste s'écoute aussi sur le document (capture), et un
champ qui prend le focus retire la classe par ceinture (un champ au focus n'est jamais sous un
« Maintenir »). Témoin : appui, bouton retiré du DOM, pointerup sur le document → classe retirée.

### A374 — les tailles de texte, mesurées sur 46 surfaces, et six écarts refermés (24/09/2026)

Demande de l'auteur : « refais un audit pour vérifier divergence/cohérence taille des polices sur
absolument toutes les fenêtres » (exemple : cartes d'accueil contre bandeau de recherche). MESURÉ, pas
lu : tailles calculées par le navigateur sur 46 surfaces (accueil, feuilles, fenêtres, lecture,
session, éditeurs, protocole, invité) à 390 px avec pointeur tactile émulé et à 1100 px, 1 632
textes ; Partage et Moniteur non ouverts par la sonde (à mesurer). Artefact Design : tableau rôle ×
surface, histogramme, écarts (https://claude.ai/artifact/TeXKDLV6Ra6rwGc5SjRmHd).

**Ce que la mesure dit.** L'échelle fermée (11 · 12 · 13,5 · 15 · 17,5 · 21 · 24) est respectée —
une seule valeur hors échelle, 16 px, qui est le PLANCHER DES CHAMPS (règle 9, `input,textarea,select
{font-size:16px}` : Safari iOS zoome en dessous) et reste tel quel : le remplacer par 15 + bloc tactile
rapetisserait les champs au bureau pour rien. Mais l'échelle est lue par le bas : 11, 12 et 13,5 px
portent 60 % des textes. Lecture, session et protocole sont conformes à A345 (24 · 21 · 17,5 en session,
15 en lecture · cartes 15 · méta 12-13,5 · sur-titres 11) et ne bougent pas.

**Six écarts refermés, tous vérifiés à la sonde après correction (390 tactile et 1100).**
1. Accueil : titre de carte 17,5/700 contre recherche du dock 15/400 au téléphone — A359 annonçait
   17,5, la règle `#homeDock .hdr-search input` disait item. → step (17,5) SOUS 780 seulement ; en
   large la carte est à 15/600 (A359) et la recherche reste à item.
2. Feuille « Se repérer » : nœuds 12, renvois 11, et le titre de rail n'était stylé qu'AU-DESSUS de
   780 (11 px) — au téléphone il tombait sur le 16 px du navigateur, un élément non stylé. → nœuds
   body (13,5), renvois meta (12), titre de rail meta (12) aux deux largeurs, une seule règle
   (« adapte un peu en restant cohérent », demande de l'auteur).
3. Menu ⋯ : tuiles « Se repérer » / « Schéma » à 11 px, le corps d'un sur-titre, contre 15 pour les
   rangées. → body (13,5/700). Les intertitres restent à 11 : c'est le corps de TOUS les sur-titres.
4. Méta qui rétrécissaient en large sans décision écrite : catégorie de rangée 12 → 11, note de
   confidentialité du compte 13,5 → 11. → 12 et 13,5 aux deux largeurs. Le titre de carte 17,5 → 15
   (A359) est la seule exception écrite et reste.
5. Nature de rangée « AIDE / PROTOCOLE » 11 → 12 (meta), sur la ligne de la catégorie qu'elle précède.
6. Éditeur : libellé de champ et texte d'aide au même corps (12). → libellé body (13,5/800, approche
   .05em), aide inchangée (12).

**Question posée et réponse de l'auteur.** Stockage, Versions et Catégories titrent à 24 px comme des
pages-fenêtres (A352), Créer et Confirmer à 17,5 comme des dialogues. Réponse : « utilise ceux de la
doctrine, je ne suis pas sûr, n'en fais pas une règle absolue » — rien ne change, A352 fait foi, et le
classement page/dialogue de ces trois fenêtres reste ouvert.

### A375 — une échelle fermée pour les CONTRÔLES : S 32 · M 40 · L 44 · XL 56, rangées 52 (25/09/2026)

Retour de l'auteur après A374 : « la différence de taille des polices n'est pas cohérente… sur
l'accueil la taille des boutons est beaucoup plus petite que les cartes, la barre de recherche paraît
petite bien qu'elle soit de la bonne taille, Sélectionner beaucoup plus gros que les boutons
d'en-tête », puis « bigger is not better ». MESURÉ (sonde de contrôles : boîte de chaque bouton,
champ, segment, rangée, carte sur 46 surfaces à 390 px tactile) : les LETTRES tenaient leur échelle,
les BOÎTES n'en avaient aucune — 18 hauteurs de bouton (28 → 70 px), champs 40 · 44 · 48 selon la
fenêtre, segments 35 · 36 · 40 · 44, rangées 52 · 54 · 70 · 103 ; sur le seul accueil : en-tête 36,
Sélectionner 40 × 130 avec icône et fond plein, filtre 44, recherche 44, carte 115.

**L'échelle** (comme les 7 corps de texte et les 21 pas d'espacement) : S 32 (discret, en ligne :
mini-boutons de l'éditeur, chips, ✕ de bandeau, épingle, bulle d'historique) · M 40 (CHROME : boutons
d'en-tête de toutes les vues, pilules d'accueil « Sélectionner » et filtre, `.btn.sm`, ✕ des fenêtres)
· L 44 (action standard et saisie : `.btn`, champs, segments, touches du quai en session — halo 44) ·
XL 56 (l'action primaire d'un écran : Démarrer, Exercice, Continuer, Découvrir, porte « Ajouter à
cette aide ») · rangées de liste 52 (menu ⋯ et ses tuiles, cartes dépliables, réglages du compte,
bloc du journal). Corps : 12 · 13,5 · 15 · 17,5 ; icônes 14 · 18 · 20 ; rayons 8 · 12 · 12 · 14.
**Tout descend ou s'aligne** ; la seule montée est l'en-tête d'accueil 36 → 40, choisie par l'auteur
(« essaie 40 et on verra »), pour un seul chrome avec la page de lecture.

**Trois décisions de l'auteur.** Chrome 40. Titre de carte d'accueil au téléphone 17,5 → **15/700**,
comme en large (renverse A359 sur ce point ; « bigger is not better » : la carte cessait d'être
l'objet le plus haut de l'écran pour une raison de lettres — mesurée 115 → 92 px). « Sélectionner » :
pilule M 40 SANS icône, sur la matière du chrome (`--amb-2`, sans ombre) — « tant qu'il y a une
cohérence ».

**Mesuré après** (390 px) : boutons 32 · 40 · 44 · 52 · 56 · 64 pour 190 des 202 mesurés ; les
restes sont des libellés sur DEUX lignes (« Cochez les étapes restantes », « + Jalon de boucle », « Le
tableau ne colle pas ? », « Rédiger avec l'IA ») dont la boîte suit le texte, et deux champs
en ligne de l'éditeur. Champs 40 · 44 (65 des 103). Segments 32 · 44 seulement. Accueil : 40 · 40 ·
40 · 40 · 44 · 92. Le garde-fou `check-ctrl` (hauteurs de contrôle sur la liste fermée) reste À
ÉCRIRE : sans lui, les dix-huit hauteurs reviendront — noté comme dette, pas comme fait.

**Addendum A375 — les paliers étroits de l'en-tête d'accueil.** Trois boutons de 40 ne tiennent pas avec
la marque sous 400 px (réserve mesurée : 0 px à 360, contre ≥ 8 exigés par le témoin) : aux paliers
`zw400` et `zw360` ils restent à 36 et 32, c'est leur rôle de compression (règle 10), et le HALO fait
le reste de la cible — 40 + 2 × 2, 36 + 2 × 4, 32 + 2 × 6 = 44, chaque palier son halo. À 430-559, où
« Créer » porte son mot, l'écart entre boutons passe à 6 pour rendre 4 px à la réserve. Les croix des
fenêtres (M 40) portent un halo de 2 pour rester des cibles de 44 en session (a11y « compte-rendu »,
« feuille Plan » rouges avant).

### A376 — huit retouches de cohérence après 5.30.5, et l'Échelle s'en va (25/09/2026)

Liste de l'auteur, dans l'ordre. **1 · Une bulle pour toutes les notices** : « 2 exemples ajoutés »
(bandeau système, A353) et « Vous êtes l'auteur… » (`.notice`) avaient deux dessins — liseré gauche
de 4 px, bord `--primary` plein, rayon petit d'un côté ; bulle `--primary-200`, rayon `--r-4` de
l'autre. `.notice` prend le dessin de la bulle. **2 · Moi** : les actions de « Sur cet appareil »
s'espacent (12) et, dès 780, se posent en rangée à largeur de contenu — un bouton de 720 px pour
« Un problème ? » ne disait rien de plus. **3 · Cockpit** : la ligne « Parcours · Fait · n étapes »
collait à 4 px de l'en-tête qui porte la capsule (mesuré ; 12 sous la capsule ailleurs) — 16 px de
marge sous `body.chrome-hdr`. **4 · Une seule barre d'outils** : Schéma en ligne (`.fz`), Schéma
plein écran (`.ff-bar`), Page (`.sv-zb`) et les ‹ › de toute recherche (`.rt-fnav .mini`) avaient
chacun leur boîte (42 × 40 surface/line, 44 ctl-line r-1, 32 et 44) — une règle commune : M 40,
matière de travail v5.30 (`--work`, `--work-line`, ombre de travail, `--r-3`), corps 13,5/700,
valeur mono 13,5. **5 · « Vérifier :: »** : secondaire de la rangée de flux, à la hauteur de la
primaire (XL 56), matière calme `--amb-2`, corps 15 — il était un bouton 12/700 à bordure de
contrôle d'un autre âge. **6 · Options d'une décision** : le corps des étapes en session (17,5,
A345) au lieu de 15/800, et le renvoi « → bloc n · titre » ne coupe plus le titre à 17 caractères
en JS — l'ellipse CSS prend la place disponible (« tronqué très tôt même sur ordinateur »).
**7 · « Le tableau ne colle pas ? »** : la carte où l'on est amené se signale 2,4 s (anneau `--act`
qui s'efface, peinture seule ; sous `prefers-reduced-motion` l'anneau reste posé le même temps) —
l'ouverture et le défilement restent l'information, l'anneau la souligne (AA : jamais une couleur
seule). **8 · Le parcours n'a plus qu'UN dessin** : la liste numérotée à renvois écrits (A349,
`preFlowFlatHtml`) rend désormais aussi la feuille « Se repérer », la colonne du cockpit (avant et
pendant la session) et le rail 780-1199 ; elle accepte l'état de session (`{md, off}` de
`planCtx`) et marque la rangée courante `cur` (fond `--primary-soft`, numéro bleu, `aria-current`),
un bloc coché `done` (numéro vert), un bloc hors chemin `off` (numéro pointillé, 0,62). Le plan
reste INERTE (rien ne se coche là). `ovPlanLadderHtml` (l'« Échelle », v4.25.0) n'avait plus
d'appelant : purgée avec ses 65 règles et treize classes (`.pl-line`, `.pl-lx`, `.pl-ref`, `.pl-x`,
`.pl-stp`…), épitaphe dans la feuille ; `.pl-brc`, `.pl-here`, `.pl-sech`, `.pl-r` restent, émises
par « Toute la fiche ». Le repli par ligne de la feuille (`state.ovFold['l:…']`) part avec elle.
Corollaire : l'item 2 d'A374 (nœuds 13,5, renvois 12 de l'Échelle) est sans objet — la liste a ses
corps (titre 17,5, étapes 15, renvois 13,5).

**Addendum A376 — ce que la purge a déplacé.** (a) Le losange d'une décision porte SON numéro dans
la liste (il portait « ? ») : un renvoi « → aller à 2 » doit trouver un 2. (b) Les jalons de boucle
s'annoncent dans la liste (`.pf-jl`, condition en toutes lettres, registre VIGILANCE) comme dans
« Toute la fiche » — l'Échelle les portait, la liste ne pouvait pas les taire. (c) Cibles de la règle
9 : la barre d'outils M 40 et les renvois en ligne (32) de la liste portent un halo (2 et 6) qui fait
44 dans les surfaces de session (feuille Plan, statique, recherche active) ; les ‹ › d'une recherche
passent à 44, hauteur du champ qu'ils accompagnent. (d) Neuf sections de `audit-doctrine.mjs`
mesuraient l'Échelle ; adaptées à la liste — « le retrait dit la profondeur » (A339) devient « la
liste écrit les chemins » : deux décisions nommées, un segment « Chemin n » signé, une seule colonne
de numéros ; « registres et cohérence » mesure désormais le registre de la DÉCISION (ambre doux,
A345) au lieu d'interdire l'ambre à une chip ; la « rangée compacte » du parcours d'entrée (32 ≤ h <
44) est sans objet, la liste est lisible (h ≥ 44).
