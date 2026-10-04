# Journal des modifications

## [5.42.0] — 2026-10-04
La revue « à tout moment » (ex. causes réversibles 4H / 4T) montre, sans un mot, qu'elle ne retient pas la suite (A449, doctrine `docs/decisions/lot-v5-42.md`).
- **Fermée par défaut.** Elle s'ouvrait d'elle-même tant qu'elle n'était pas faite : ses huit cases s'ajoutaient au
  bloc et repoussaient « Continuer » sous le quai. Elle s'ouvre maintenant d'un tap sur sa ligne.
- **Plus de case, une jauge.** À la place de la case pointillée, un anneau d'un segment par hypothèse, qui se remplit au
  fil des coches, dans n'importe quel ordre. La ligne n'a plus de fond d'étape mais un contour pointillé — le même que
  celui d'une étape « pas encore son moment » — et le libellé est un cran plus petit que celui des étapes.
- **Plus de bleu ni de « à faire ».** Le compte « 3/8 » est en gris ; il passe au vert avec « faite » et un ✓ quand
  tout est coché.
- **Ouverte, des jetons au lieu d'une liste** : ni case à gauche ni numéro, un jeton vert pâle à coche à droite une fois
  passé en revue. Cocher ne déplace plus le texte (ni « ✓ » ajouté devant la réponse, ni changement de graisse). La
  réponse suit le libellé sur la même ligne, ce qui rend les jetons plus bas (44 px au lieu de 56).
- **Une ou deux colonnes selon la longueur des libellés** : deux jetons par ligne seulement si le plus long libellé y
  tient (au téléphone, une dizaine de caractères) ; sinon une seule colonne. Le choix suit la largeur réelle, réglage
  de taille du texte compris.
- **« Nouvelle revue » reste au pied des jetons**, loin du chevron qui replie : elle efface toutes les coches de la
  revue pour la session.
- Accessibilité : la ligne de la revue est un vrai bouton (la rangée entière l'était et contenait des cases), et le
  lecteur d'écran entend qu'elle se remplit quand on veut, sans retenir la suite.

## [5.41.1] — 2026-10-04
Le bouton « Ajouter » de l'éditeur se voit, la recherche dit dans quelle bibliothèque elle cherche, et une décision repliée du parcours redevient compacte (A446-A448, doctrine `docs/decisions/lot-v5-41.md`).
- **Le bouton « ＋ Ajouter » de l'éditeur est désormais bleu foncé, plein** (texte blanc), dans l'éditeur d'aide comme
  dans celui de protocole. Cerclé sur fond bleu pâle, il restait trop discret ; et c'est le seul bouton plein de
  l'éditeur, donc l'action principale de la page. De nuit, il prend le bleu clair des boutons principaux (un bleu foncé
  disparaîtrait sur le fond sombre).
- **Recherche + bibliothèque choisie dans la colonne de gauche** (tablette, ordinateur) : la liste était bien filtrée,
  mais le titre affirmait toujours « Résultats — toutes les bibliothèques ». Il dit maintenant « Résultats — Perso »
  (ou le nom de la bibliothèque), et les filtres posés (bibliothèque, catégorie, type) s'affichent sous le titre en
  puces retirables, comme sans recherche.
- **Les résultats « Dans les documents » suivent les mêmes filtres** : un PDF joint à une aide d'une autre bibliothèque
  ou d'une autre catégorie n'y apparaît plus.
- **Parcours (colonne de gauche, en lecture comme en session) : une décision repliée n'est plus plus haute que
  dépliée.** Quand les réponses étaient longues (« Convulsions persistantes »), la ligne repliée passait à la ligne
  morceau par morceau — la réponse, puis la flèche « ↓ 5 » seule, puis le « · » seul. La flèche reste désormais au bout
  de sa réponse ; seul le texte de la réponse passe à la ligne.

## [5.41.0] — 2026-10-04
Le bouton « + » de l'éditeur dit ce qu'il ajoute, et quatre corrections (A441-A445, doctrine `docs/decisions/lot-v5-41.md`).
- **La porte « Ajouter » de l'éditeur devient une pilule nommée** : « ＋ Ajouter », et dessous « bloc · minuteur ·
  dose… », cerclée de bleu pour se détacher du fond, de jour comme de nuit. Le petit carré bleu pâle sans mot était
  peu visible et ne disait pas quoi on ajoute. Même dessin dans l'éditeur de protocole. Tout en bas de la page, elle
  prend sa propre place et ne masque aucun contenu.
- **Colonne gauche : taper le cadenas ou le nombre d'une bibliothèque la sélectionne** (seul le nom répondait).
- **Feuille « Affichage » : la pastille d'« Afficher » suit dès le premier clic** (signalé sous Chrome : elle ne
  suivait qu'au second ; elle se pose désormais avant que la liste se recalcule).
- **Éditeur : « Options du bloc » reste repliée à l'ouverture**, même quand une option est réglée — le résumé à
  droite du titre dit déjà ce qui l'est. Un dépliage reste mémorisé pendant l'édition.
- **Éditeur : le nom d'un minuteur ou d'un compteur est plus grand** (il était plus petit que son « Nom court »), et
  sous « Nom court » une ligne discrète dit qu'il est facultatif et qu'il s'affiche sur la capsule en session.

## [5.40.0] — 2026-10-02
Une étape qui compte, quand le compteur relance lui-même un minuteur, le dit et se défait (A440, doctrine `docs/decisions/lot-v5-40.md`).
- **En session, deux lignes sous l'étape** : le compte (« 0 → 1 à la coche · Adrénaline IM »), puis le minuteur que
  la coche relance, au même dessin qu'une étape qui lance un minuteur directement — « 05:00 à la coche · Rééval.
  adrén. », et s'il tourne déjà « 02:40 · la coche relance à 05:00 » : on voit ce que la coche va remettre à zéro.
  La place des deux lignes est réservée d'office ; rien ne saute à la coche. Une seule ligne ne tenait pas sur un
  téléphone sans couper le texte.
- **Décocher dans les 10 s rend aussi ce minuteur** à son état d'avant. Il restait relancé : une coche posée par
  erreur effaçait le délai de la dose précédente.
- **Les lignes de minuteur prennent le nom court de la tuile** (« Rééval. adrén. ») au lieu du nom complet coupé.
- **Éditeur, Réglages de l'étape** : sous « ＋1 Adrénaline IM », la ligne « et relance « Réévaluation après
  adrénaline » · 5 min — réglé sur le compteur » et un bouton « Compteur » qui y mène. La pastille de l'étape le dit
  aussi.
- **Éditeur, carte du compteur** : « Compté par 2 étapes », chaque étape rouvre ses réglages, et la phrase « Chaque
  coche de ces étapes, comme le ＋ de la tuile, relance … ».
- **Un minuteur cyclique relancé par un geste se signale** (carte ambre « △ Minuteur cyclique ») : voulu pour un cycle
  de relais, à éviter pour un délai qui court depuis un geste. Un avertissement, jamais une interdiction.
- Partage de session : rien de nouveau ne voyage — celui qui coche compte et relance, l'état part vers l'autre écran ;
  l'annulation de 10 s vaut sur l'appareil qui a coché. Registre de conformité § 2 mis à jour.
- Une étape garde un seul lien (lance OU compte) : le lien compteur → minuteur reste sur le compteur, dont le « + »
  relance aussi.

## [5.39.11] — 2026-10-02
Ce que la charge révélait : deux sondes fragiles et deux défauts de l'app (A439, doctrine `docs/decisions/lot-v5-39.md`).
- **Déplacer une étape ou une ligne ne décale plus l'écran.** Reposer ou abandonner une rangée pendant son petit
  tremblement (une demi-seconde) faisait défiler la page de quelques pixels pour de bon — jusqu'à 6 px sur un appareil
  lent, cumulés d'un geste à l'autre. L'ancrage mesure maintenant la rangée posée, pas son tremblement.
- **Les fiches d'exemple ne s'ajoutent plus en double** si l'on touche « Ajouter les fiches d'exemple » pendant que
  « Découvrir avec 2 exemples » est encore en train de les écrire.
- Harnais : l'amorçage commun attend les fiches d'exemple au lieu de presser une seconde fois ; la sonde « à la prise,
  l'objet ne bouge pas » mesure après l'animation. Vérifié en passe complète processeur ralenti (÷3, puis k5 à ÷6) :
  plus aucun rouge dû à la charge.

## [5.39.10] — 2026-10-02
La partie « Administration » de Moi, d'après la maquette validée (A438, doctrine `docs/decisions/lot-v5-39.md`).
- **La seule action en tête** : « 3 demandes de compte · À approuver ou refuser · 2 refusées », toute la rangée
  ouvre l'examen ; sur un écran assez large, « Examiner › » est un bouton plein. Sans demande, la rangée reste
  (« Aucune en attente ») pour consulter les refusées.
- **Quatre chiffres d'un coup d'œil** : comptes actifs, aides, protocoles, partages en cours.
- **Contenus & sessions, et Stockage, en deux cartes** — côte à côte dès que la largeur le permet (ordinateur),
  l'une sous l'autre sinon (téléphone, tablette en portrait). La barre de stockage a sa légende (données / documents
  PDF), et la note « le compte administrateur ne se supprime pas d'ici » vit au pied de la carte Stockage.
- Nombres séparés par milliers (« 1 208 ») ; heure de mise à jour à côté de l'intertitre.
- Témoins : `npm test` 1280/1280 ; l'ancien rendu en rangées (`.ist-*`) est purgé.

## [5.39.9] — 2026-10-02
Sept retours d'usage corrigés, et les deux essais d'affichage tranchés (A431-A437, doctrine `docs/decisions/lot-v5-39.md`).
- **Colonne de gauche : les deux « Gérer » s'alignent.** La liste des catégories réservait la place de sa barre de
  défilement, et tout ce qu'elle porte se tenait 15 px plus à gauche que les bibliothèques. Les trois étages de la
  colonne réservent désormais la même place : un seul bord droit (A431).
- **« Gérer les catégories » respire.** Les pastilles, l'anneau de la couleur choisie, « Autre teinte » et son
  curseur ne touchent plus le bord de la carte, et l'anneau n'y est plus coupé. L'avertissement « △ Proche d'une
  couleur d'alerte » retrouve son ambre et s'aligne sur le nom, « Prendre la teinte voisine » juste dessous (A432).
- **En session, la barre « ↩ Bloc » ne cache plus le bas de la page.** Tant qu'elle est affichée, la page garde sa
  place en bas : on défile jusqu'à la dernière ligne des références (A433).
- **Essais tranchés : capsule en tuiles, instruments en colonne.** « Horizon » et « Bande » sont retirés, avec leurs
  réglages dans Moi › Affichage ; le réglage enregistré sur l'appareil est effacé au démarrage (A434).
- **Couleur d'accent : les pastilles montrent l'avatar qu'elles donneront.** Carré arrondi avec vos initiales ;
  « Par défaut » est enfin le bleu pâle réel, et plus un bleu nuit. L'accent colore aussi « Moi » dans la colonne de
  gauche et la carte d'identité de Moi (A435).
- **« Rejoindre une session », caméra refusée.** Le message, une consigne et les deux boutons (« Autoriser la
  caméra », « Saisir le code à la main ») forment une seule carte ambre avec son icône. « Ce qui est enregistré, et
  par qui » montre la flèche ▾ des autres dépliants (A436).
- **« Affichage » : le bandeau « Filtrer » ne saute plus** quand « n actifs · Tout effacer » apparaît (A437).
- **Maquette à valider** : la partie « Administration » de Moi, sur un canevas Claude Design (rien n'est codé).
- Témoins : section A380 d'`audit-doctrine` retirée avec les essais ; familles `essai-` purgées de `check-classes`.

## [5.39.8] — 2026-09-30
Le geste retour se comporte comme dans une app (A430, doctrine `docs/decisions/lot-v5-39.md`).
- **Balayer vers la droite ramène à l'écran d'avant, sans rechargement ni gel.** L'app gardait une seule entrée
  d'historique, recréée à chaque retour. Or le balayage d'iPhone (et le retour prédictif des Android récents) fait
  glisser une capture de l'écran précédent : elle montrait souvent un autre écran que celui où l'on arrivait, et
  pouvait rester figée à l'écran quelques secondes. L'historique a maintenant une entrée par niveau ouvert (fiche,
  fiche liée, éditeur, fenêtre, volet, visionneuse, schéma, Sessions/Moi), si bien que la capture est celle du bon
  écran, et rien n'est ajouté pendant le retour lui-même.
- Fermer par ✕ ou « ‹ » retire l'entrée correspondante : le balayage suivant tombe juste. Balayer vers l'avant ne
  rouvre rien ; depuis l'accueil, le retour quitte l'app ; en session, il ne l'arrête jamais (inchangé).
- À vérifier sur l'appareil : accueil → fiche → retour ; fiche → fiche liée → retour ×2 ; une fenêtre ouverte →
  retour ; la même chose en session.
- Vérifié : check complet, 1280 tests sous Chromium (WebKit absent de ce poste), `audit-retour` 10/10 (nouvelle
  section, rouge sur le code d'avant), audit complet — seuls restent les deux rouges connus de ce poste (en-tête
  d'accueil à 320 px, barre de sélection).

## [5.39.7] — 2026-09-29
Retours d'usage sur l'accueil et le téléphone (A426 à A429, doctrine `docs/decisions/lot-v5-39.md`).
- **Filtrer par bibliothèque.** La feuille « Affichage » propose une rangée « Bibliothèque » (Toutes, Perso, et
  chaque bibliothèque partagée, cadenas si lecture seule), en plus du regroupement par bibliothèque. Elle
  n'apparaît que s'il y a au moins deux bibliothèques ; le choix est le même que dans la colonne gauche du bureau.
- **Une feuille « Affichage » en deux parties.** « Filtrer » (Afficher, Bibliothèque, Catégorie : ce qui
  restreint) et « Présenter » (Trier, Regrouper, Densité : ce qui range) sont deux sections encadrées, chacune
  avec son icône et son titre. Le compte des filtres actifs et « Tout effacer » passent dans l'en-tête de
  « Filtrer » ; le pied ne dit plus que le résultat. À l'ouverture, le focus va sur le choix actif d'« Afficher ».
- **Les filtres posés en puces sur la liste.** Sous la ligne de compte, une puce par filtre (« Bibliothèque :
  CH Le Mans × ») : toucher la puce rouvre la feuille, sa croix retire ce seul filtre, « Tout effacer » à partir
  de deux. Elles restent visibles quand aucun résultat ne correspond, là où l'on en a besoin. Elles remplacent la
  phrase « filtres : … ».
- **Cadenas alignés dans la colonne gauche** : les nombres ont une colonne de largeur fixe, les cadenas ne
  bougent plus d'une rangée à l'autre.
- **Couleur d'accent dans « Moi »** : la rangée de pastilles ne touche plus le bord de la carte.
- **Retour dans l'app sur iPhone** : en revenant après l'avoir quittée (surtout avec la recherche active), le haut
  de la page pouvait rester hors écran et le quai cessait de flotter. L'app recale la vue au retour au premier
  plan. À vérifier sur l'appareil : le défaut ne se reproduit pas hors de Safari iOS.
- Vérifié : check complet, 1280 tests sous Chromium (WebKit absent de ce poste), audit complet — seuls restent les
  deux rouges connus de ce poste (en-tête d'accueil à 320 px, barre de sélection).

## [5.39.6] — 2026-09-29
Trois retours d'usage (A423 à A425, doctrine `docs/decisions/lot-v5-39.md`).
- **Au téléphone, la recherche flotte sur la liste.** La bande grise sous la recherche et le bouton filtre
  disparaît : les deux commandes, opaques, flottent séparément au-dessus de la liste, qui s'efface doucement en
  passant dessous (flou et voile du fond, sans arête). C'est la disposition des apps récentes (iOS 26, Material 3),
  sans leur verre translucide, dont le contraste dépend de ce qui passe dessous. Ombre légère le jour, contour la
  nuit ; recherche en forme de pilule, filtre et recherche à la même hauteur (44 px).
- **Ranger dans une catégorie une sélection qui mêle plusieurs bibliothèques.** L'action n'était proposée que si
  les cartes cochées étaient dans la même bibliothèque, ce qui arrivait rarement depuis que l'accueil les réunit
  toutes. Elle est maintenant toujours là : on choisit un nom, et chaque carte va dans la catégorie de ce nom de sa
  propre bibliothèque. Avant le geste, une notice dit que les bibliothèques diffèrent, et la liste est rangée sous
  des intertitres (« Dans les deux bibliothèques », « Seulement dans Perso »…) qui disent combien de cartes vont où
  et combien restent inchangées. Rien n'est créé ni vidé en silence ; le message final reprend le partage.
  Au passage, « Sans catégorie » ne se coche plus à tort quand les cartes ont des catégories différentes.
- **Sur un écran très large, l'accueil se centre.** La colonne des cartes (960 px) collait à gauche avec un vide à
  droite ; elle se centre, et la recherche, « Créer », le bandeau et la carte « Session en cours » suivent le même
  axe. Rien ne change sous 1260 px environ.
- Vérifié : check complet, 1280 tests sous Chromium (WebKit absent de ce poste), audit complet — seuls restent les
  deux rouges d'environnement déjà connus ; nouveau témoin « A424 » (8 contrôles), rouge avant, vert après.

## [5.39.5] — 2026-09-29
Signalé à l'usage (A422, doctrine `docs/decisions/lot-v5-39.md`).
- **Cartes d'accueil : l'état ne rivalise plus avec le titre.** Les pastilles « Brouillon », « À compléter »,
  « Sans date », « À relire » étaient en 13,5 px et en gras 800, sur fond gris, alors que le titre est en
  15 px et en gras 700 : plus grasses que lui, elles pesaient presque autant. L'état passe au palier des
  autres informations de la carte (12 px, comme « AIDE »), en gras 700 quand il attend quelque chose
  (pastilles, « À revérifier », « En cours ») et au poids normal quand il est nominal (« Validée »).
  Même règle en liste compacte et au bureau.
- Vérifié : check complet, 1280 tests sous Chromium, audit complet (seuls restent les deux rouges
  d'environnement déjà présents avant ce changement).

## [5.39.4] — 2026-09-29
Deux retours d'usage (A421, doctrine `docs/decisions/lot-v5-39.md`).
- **« Afficher » Aides / Protocoles filtre enfin.** Ouverte par le bouton « Affichage » de la liste, la
  feuille changeait bien de type, puis repeignait aussitôt la liste d'ouverture (« Tout ») par-dessus :
  le choix semblait sans effet. Même chose pour un tri, un regroupement ou une catégorie choisis après
  avoir changé de type. La feuille re-rend désormais la liste du type choisi, quel que soit le bouton qui
  l'a ouverte. Le témoin d'A419 ouvrait la feuille par le bouton rond, le seul chemin sans défaut : un
  second témoin passe par « Affichage », rouge avant le correctif, vert après.
- **L'anneau autour de « Démarrer la session » est plus fluide.** Il animait une ombre, repeinte à chaque
  image pendant l'affichage d'une fiche neuve, d'où les saccades, sur iPhone surtout. C'est maintenant un
  trait de 2 px qui s'éloigne de la capsule par transformation et s'efface en fondu, deux propriétés que
  le processeur graphique compose sans rien repeindre. Il apparaît en fondu au lieu de surgir à pleine
  encre, et s'éloigne d'un seul mouvement, sans temps mort à chaque anneau. Mêmes trois anneaux, même
  départ (800 ms), fini à 4,7 s ; toujours rien sous « réduire les animations ».
- Vérifié : check complet, 1280 tests sous Chromium (WebKit absent de ce poste), audit complet.

## [5.39.3] — 2026-09-28
Outillage d'audit seulement : l'application ne change pas (A420, doctrine `docs/decisions/lot-v5-39.md`).
- **Le rouge WebKit d'A387 n'était pas une fuite.** Sous WebKit, « une session locale sur l'autre aide
  n'émet RIEN sur le fil de l'invité » échouait (2 ou 3 évènements reçus). Mesuré : ce sont des `sig`,
  l'offre et la réponse de négociation du canal direct de secours, que WebKit achève plus tard. Aucune
  coche ni navigation. Le contrôle ne compte plus que les évènements d'état (tout sauf `sig`), avec un
  témoin qui prouve que l'invité a bien lu le fil pendant la fenêtre.
- Vérifié capable d'échouer : la garde d'A387 neutralisée chez l'hôte, le contrôle rougit sur les deux
  moteurs et nomme ce qui fuit (coche, décoche, compteur, minuteur, navigation, démarrage).
- Vérifié : check complet, 1280 tests × 2 moteurs, audit complet après le numéro de version.

## [5.39.2] — 2026-09-28
Outillage d'audit seulement : l'application ne change pas (A420, doctrine `docs/decisions/lot-v5-39.md`).
- **Audit du temps des audits, mesuré.** Toutes les attentes fixes des 22 harnais ont été rejouées
  réduites à deux images, divisées par deux, puis triplées, et les 2 619 contrôles comparés un à un :
  même divisées par deux, 31 contrôles changent. Ces attentes sont donc presque toutes utiles, et aucune
  n'a été raccourcie en masse.
- **pdfsearch : 66 s → 16 s.** Trois attentes testaient `window.attIx`, qui n'existe pas (`attIx` est une
  constante du script), et payaient donc leur plafond entier (60 s) à chaque passe ; l'index est prêt en
  1 à 85 ms. La fenêtre de 10 s dont profitait par accident le témoin « pdf.js pas chargé au démarrage »
  est gardée, explicitement.
- **Tranches équilibrées par durée.** Le lanceur enregistre la durée de chaque section et de chaque
  tâche, et répartit les tranches par durée au lieu du modulo : doctrine 95-168 s → 119-120 s par
  tranche, partage 41-100 s → 58-67 s ; poids d'ordonnancement re-mesurés. Passe complète ~295 → 279 s,
  verdict identique sur les 2 619 contrôles. Sans mesure (CI), rien ne change.
- **Fiabilité de quatre contrôles de partage**, qui dépendaient de la vitesse du harnais : le compteur
  d'A387 est attendu avec la coche ; « le billet mort ne traîne pas » ne dépend plus du vrai serveur ;
  la grammaire des fenêtres se mesure après l'animation d'ouverture ; le rejeu de « continuer seul »
  porte enfin la même heure que l'original. Tous tiennent à attentes divisées par deux et triplées.
- Vérifié : check complet, 1280 tests × 2 moteurs, audit complet après le numéro de version.

## [5.39.1] — 2026-09-28
Deux correctifs signalés à l'usage (A419, doctrine `docs/decisions/lot-v5-39.md`).
- **Connexion.** Appuyer sur Entrée (ou « Envoyer » au clavier du téléphone) dans le champ e-mail envoie
  maintenant le code ; il fallait jusqu'ici toucher le bouton « Recevoir le code ».
- **Filtres de catégorie sur « Toutes ».** Choisir une catégorie (colonne de gauche ou feuille
  « Affichage ») pouvait montrer les aides d'une AUTRE catégorie, et allumer la mauvaise rangée. Cela
  arrivait quand une catégorie avait été renommée dans une bibliothèque alors qu'une autre bibliothèque
  gardait l'ancien nom. Le filtre retient désormais le nom de la catégorie choisie, et suit un
  renommage ou une suppression.

## [5.39.0] — 2026-09-28
Le sommaire d'un PDF joint se consulte comme celui d'un protocole, et reste une option (A418, doctrine
`docs/decisions/lot-v5-39.md`).
- **Sur ordinateur et tablette en paysage (1000 px et plus).** Quand le PDF a des signets, son sommaire
  est une colonne à gauche des pages, avec le numéro de page de chaque titre et la section en cours en
  bleu. Un petit bouton le replie en une icône ≡, qui le rouvre d'un tap ; l'appareil retient le choix.
- **Au téléphone.** Le bouton « Sommaire », sur la ligne du titre, ouvre la liste sous la barre ; elle se
  referme dès qu'on a choisi un titre.
- **On arrive sur le titre, plus en haut de la page.** Un signet ou un renvoi interne du PDF mène
  exactement là où il pointe. Les sauts de la visionneuse (sommaire, liens, occurrences d'une recherche)
  arrivaient aussi environ 60 px trop bas : corrigé.
- **Barre d'outils du téléphone.** Avec un sommaire, elle débordait (« Largeur » coupé, bouton de
  téléchargement hors de l'écran) ; « Sommaire » remonte sur la ligne du titre et tout tient.

## [5.38.2] — 2026-09-28
Le survol bleu pâle devient visible (A417, doctrine `docs/decisions/lot-v5-38.md`).
- **Survol.** Les boutons posés sur le fond bleu pâle (« + » du compteur, « J'ai compris » du bandeau,
  bouton Compte, rangée active de la colonne gauche) changent maintenant nettement de teinte au survol.
  La nuit, ce survol n'était pas visible du tout.
- **Focus.** Le halo autour d'un champ de l'éditeur en cours de saisie est plus lisible ; le bouton
  « Filtrer » actif est un cran plus soutenu.

## [5.38.1] — 2026-09-28
Nettoyage interne des couleurs, sans aucun changement à l'écran (A416, doctrine `docs/decisions/lot-v5-38.md`).
- **Un seul nom par couleur.** Trente-huit anciens noms de couleur (« alias ») gardés depuis la refonte
  v5.6 sont retirés : le code lit désormais partout le nom de référence. Le contrôle automatique des
  tokens refuse qu'un tel doublon réapparaisse.
- **Vérifié identique.** Les styles calculés de 4 714 éléments, sur huit écrans en thème clair, sombre
  et en large, sont les mêmes avant et après.

## [5.38.0] — 2026-09-27
Un audit design de l'application, mesuré puis maquetté sur l'app réelle, et ce qu'il a changé
(A400-A415, doctrine `docs/decisions/lot-v5-38.md`).
- **Lisible à distance.** Les noms de la barre des minuteurs et des touches du bas passent de 11 à
  13,5 px, en casse de phrase sur la barre du bas. Un nom trop long s'abrège tout seul (« Réévaluation
  après adrénaline » devient « Rééval. adrén. », « Bronchospasme réfractaire » devient
  « Bronchospasme ») ; un champ facultatif « Nom court » dans l'éditeur permet de choisir le sien. Les
  mots longs se coupent à la syllabe, avec un tiret, et plus au milieu du mot.
- **Le rouge ne sert plus qu'à ce qui compte.** « Mode crise » n'est plus en rouge, « Fin » garde son
  carré rouge mais son mot passe en gris, la touche de complication et son étiquette passent à
  l'ambre. Dans « Terminer la session ? », l'étape vitale oubliée est maintenant en rouge, avec le mot
  CRITIQUE. La barre d'un minuteur qui tourne est neutre ; il ne prend de couleur qu'à l'échéance.
- **Catégories.** La teinte vermillon, presque identique au rouge d'alerte, quitte le nuancier ;
  « Urgences » passe en prune et quatre teintes proches de l'ambre ou du vert d'alerte glissent un peu.
  Vos catégories existantes gardent leur couleur : « Gérer les catégories » signale celles qui sont trop
  proches d'une couleur d'alerte et propose la teinte voisine d'un tap.
- **Écrans pliables (Surface Duo, Pixel Fold, Galaxy Z Fold).** Rien ne se pose plus sur la charnière :
  la barre des minuteurs, la barre du bas et les fenêtres restent dans le volet gauche. La fenêtre
  « Terminer la session ? » était coupée en deux par la charnière.
- **Mots.** « Journal » devient « Horodater » (le geste reste le même : l'heure est notée d'un tap).
  « ×2 » devient l'étiquette « Double contrôle ». « Vérifier :: » devient « Vérifier ». Les réponses
  attendues s'écrivent en casse de phrase.
- **« Ne pas oublier ».** Le rappel vital de l'arrêt cardiaque s'affichait avec sa syntaxe de saisie
  (« ⚠ RCP immédiate :: 30:2 ») ; il se lit maintenant sur une ligne, CRITIQUE à droite.
- **Avant la session.** La bulle qui masquait le contenu devient une ligne dans le bouton de
  démarrage : « Lance le chrono · minuteurs prêts ».
- **Accueil.** « Créer » n'est plus le bouton le plus visible ; l'étoile d'épinglage et les croix
  répondent au doigt sur 44 px, sans changer de dessin. Sur tablette, la barre des minuteurs ne fait
  plus que la largeur du chrono quand les minuteurs sont dans la colonne de droite.
- **Contraste.** Dans le volet des minuteurs, « Maintenir » et une vingtaine de textes du thème sombre
  étaient sous le seuil de lisibilité ; corrigé. Le contrôle automatique d'accessibilité mesure
  désormais ce volet, calcule juste les fonds semi-transparents empilés, et un nouveau contrôle
  vérifie les écrans pliables.

## [5.37.2] — 2026-09-27
Deux alignements, mesurés (A399, doctrine `docs/decisions/lot-v5-37.md`).
- **Capsule CRITIQUE / VIGILANCE d'une hypothèse** : elle s'aligne exactement sur le début du
  libellé en dessous, à toutes les largeurs et tailles de texte (sur téléphone étroit elle partait
  10 px à gauche du texte).
- **« Repères de ce bloc » replié** : le titre, le résumé (« 2 à préparer ») et les noms des repères
  partent du même bord ; l'icône est dans la même colonne que celle des repères et le compte est sur
  la ligne du titre.
