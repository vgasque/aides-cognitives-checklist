# Journal des modifications

## [5.55.4] — 2026-10-10
Essai « Étapes » : deux dessins pour les onglets de S6c et S6f (A499, doctrine `docs/decisions/lot-v5-55.md`).
- **Moi › Affichage › Essai · Onglets** : Pleins (comme jusqu'ici), **Légende** ou **Filigrane**. Réglage de cet
  appareil, valable avec S6c et S6f.
- Pourquoi : les onglets gris, de la couleur de l'étape, remplissaient une partie de l'espace entre deux étapes. Là où
  un onglet du bas et un onglet du haut se suivent, l'espace paraissait serré ; entre deux étapes sans onglet, il
  paraissait large. L'écart réel, lui, est le même partout.
- **Légende** : l'onglet prend la couleur du fond de la carte et coupe le bord de l'étape, comme la légende d'un cadre.
- **Filigrane** : l'onglet garde sa forme, de la couleur du fond, cerné d'un filet fin.
- Rien d'autre ne bouge : même place pour les onglets, la case et le texte, même écart entre les étapes.

## [5.55.3] — 2026-10-09
Essai « Étapes » : S6c et S6f resserrés (A498, doctrine `docs/decisions/lot-v5-55.md`).
- **Moins d'espace entre les étapes** : les onglets du haut et du bas passent de 20 à 16 px de haut, toujours à cheval
  à moitié sur le bord de l'étape ; l'écart entre deux étapes passe de 24 à 20 px. Entre deux onglets voisins, comme
  entre l'onglet et la case, il reste partout le même petit jour de 4 px.
- **S6f** : la case remonte de 4 px et retrouve la même place qu'en S6c.
- Sur un bloc de cinq étapes, à 390 px : 18 px gagnés en S6c, 38 px en S6f.

## [5.55.2] — 2026-10-09
Essai « Étapes » : choisir où se lit CRITIQUE (A497, doctrine `docs/decisions/lot-v5-55.md`).
- **Moi › Affichage › Essai · Critique** : En tête (comme jusqu'ici), **À droite** de l'intitulé, ou **Au-dessus**,
  collé à l'intitulé. Réglage de cet appareil, valable avec les quatre dessins de l'essai.
- Dans les deux nouvelles positions, CRITIQUE (ou VIGILANCE) quitte l'onglet du haut, qui ne porte plus que la
  condition (« Chocs délivrés ≥ 3 ») et disparaît quand il n'y en a pas. La case ne bouge pas.
- « À droite » : le mot se cale au bout de la première ligne de l'intitulé, les lignes suivantes gardent toute la
  largeur. « Au-dessus » : l'intitulé garde toute sa largeur et descend d'une petite ligne sous le mot.

## [5.55.1] — 2026-10-09
Essai « Étapes » : une quatrième option, S6f (A496, doctrine `docs/decisions/lot-v5-55.md`).
- **Moi › Affichage › Essai · Étapes** propose maintenant Actuel, V1, V2, S6c et **S6f**.
- **S6f** reprend les onglets de S6c, mais collés aux bords de l'étape, comme des intercalaires : l'onglet du haut part
  du bord gauche (CRITIQUE s'aligne sur la case), celui du bas touche le bord droit. Le coin de l'étape s'efface sous
  chaque onglet, si bien que le bord reste continu, pointillé compris. La case descend de 4 px dans toutes les étapes
  pour laisser de l'air sous l'onglet.

## [5.55.0] — 2026-10-08
Essai « Étapes » : trois dessins des étapes en session, à comparer sur votre appareil (A494-A495, doctrine
`docs/decisions/lot-v5-55.md`).
- **Moi › Affichage › Essai · Étapes** : Actuel, V1, V2 ou S6c, sur cet appareil seulement. « Actuel » garde le
  dessin d'aujourd'hui ; changer redessine aussitôt l'aide ouverte.
- **Ce que les trois essais ont en commun** : chaque étape se lit en trois parties — en tête ce qui précède la coche
  (CRITIQUE, VIGILANCE, la condition comme « Chocs délivrés ≥ 3 »), au milieu la case, l'intitulé et sa réponse
  (en exergue), en pied ce que fait la coche (minuteur ou compteur, avec son nom : « +1 Chocs délivrés », « 04:00
  Adrén. dose »). La case est toujours au même endroit à côté de l'intitulé ; « Faire maintenant » est un lien à
  droite de l'intitulé.
- **V1** : en-tête et pied en bandeaux teintés, dans l'étape. **V2** : les mêmes bandeaux, séparés par un filet.
  **S6c** : en-tête et pied en onglets sur les bords de l'étape, CRITIQUE dans une pastille.
- **Revue « à tout moment »** : son anneau a maintenant la taille exacte d'une case et son intitulé se centre dessus,
  dans tous les dessins — il paraissait un peu plus haut que les cases voisines.

## [5.54.0] — 2026-10-08
Anneaux bleus, retour à l'accueil et colonne (A490-A493, doctrine `docs/decisions/lot-v5-54.md`).
- **Anneaux bleus** : une fenêtre ouverte au doigt ou à la souris n'encadre plus rien. Une confirmation met
  toujours son action par défaut sous Entrée, les autres fenêtres (Créer, Affichage, Moi, Catégories, Sessions,
  Prendre en main…) ne présélectionnent plus rien et n'ouvrent plus le clavier du téléphone. Au clavier, l'anneau
  reste — dès l'ouverture, et au premier Tab.
- **Retour à l'accueil** : en tablette et au bureau, revenir d'une aide repose la liste là où vous l'aviez laissée
  (comme au téléphone). Après « Terminer la session », l'accueil s'ouvre en haut, sur la carte-bilan.
- **Colonne gauche** : une bibliothèque que vous venez de créer y apparaît même vide (compte 0) ; les collections
  ont leur remise à zéro « Tout », comme les bibliothèques et les catégories.

## [5.53.0] — 2026-10-07
Retours d'usage après les collections, et une colonne gauche qui dit avec qui (A485-A489, doctrine
`docs/decisions/lot-v5-53.md`).
- **Colonne gauche (bureau)** : chaque bibliothèque dit avec qui — Perso « vous seul », une bibliothèque partagée
  « partagée » ou « lecture », avec une icône de personnes ; les collections gardent leur signet sous « Collections ·
  pour vous », avec « Gérer » vers Moi. Avec une seule bibliothèque, une seule rangée, et « ＋ Partager avec une
  équipe… » pour en créer ou en demander une.
- **Collections** : le bouton « Ajouter » ouvre « Ajouter à « ‹collection› » », et chaque aide ou protocole y montre
  sa catégorie ; le menu ⋯ d'une collection s'ouvre sous son bouton en tablette et au bureau.
- **Ranger › Nouvelle catégorie…** : on nomme la catégorie, « Créer et ranger », et la sélection y est rangée.
- **Accès direct** : une sélection qui contient un brouillon ne bloque plus la case « Accès direct » (un brouillon ne
  s'épingle pas, la rangée le dit) ; toucher une étoile n'anime plus toutes les autres.
- **Catégories homonymes** : l'intertitre d'une section prend la couleur de sa propre bibliothèque (bicolore sur
  « Toutes » quand les couleurs diffèrent).
- Moi : le survol d'une première rangée ne touche plus le bord de la carte.

## [5.52.1] — 2026-10-07
L'administrateur gère aussi les bibliothèques dont il n'est pas membre (A484, doctrine `docs/decisions/lot-v5-52.md`).
Rien à rejouer côté serveur au-delà de la 5.52.0.
- **Administration › Bibliothèques de l'instance** : toucher une bibliothèque ouvre sa fenêtre de gestion, même
  si vous n'en êtes pas membre — inviter quelqu'un, changer un rôle, retirer un membre, la renommer ou la supprimer.
  Un bandeau en tête le dit : vous la gérez comme administrateur de l'instance, et son contenu ne s'affiche pas
  chez vous tant que vous ne vous y ajoutez pas.
- La suppression annonce le vrai nombre d'aides et de protocoles qu'elle emporte (elle disait 0 pour une
  bibliothèque dont vous n'étiez pas membre).
- Fermer la fenêtre met à jour les listes d'Administration (membres, administrateurs, bibliothèques de chaque compte).
- Dans la liste des bibliothèques de l'instance, les vôtres disent « vous : Admin » (ou votre rôle).
- « Convertir en collection » n'est plus proposé sur une bibliothèque dont vous n'êtes pas membre.

## [5.52.0] — 2026-10-07
L'administrateur de l'instance voit tous les comptes et toutes les bibliothèques, et en règle les droits (A483,
doctrine `docs/decisions/lot-v5-52.md`). **⚠ Rejouer `supabase/schema.sql`** (§ 9ter) puis `rls-tests.sql` (§ 15.7) ;
sans cela, Administration le signale et rien d'autre ne change.
- **Administration › Comptes** : tous les comptes, approuvés, en attente ou refusés, avec leur nombre de
  bibliothèques. Toucher un compte le déplie sur place : son statut et le geste qui va avec (Approuver, Refuser,
  Suspendre l'accès…, Réapprouver, Supprimer le compte…), « Peut créer des bibliothèques », et chacune de ses
  bibliothèques avec son rôle à changer ou ✕ pour l'en retirer.
- **Administration › Bibliothèques de l'instance** : toutes les bibliothèques partagées, même celles dont vous n'êtes
  pas membre, avec membres, administrateurs, éléments et créateur ; toucher une bibliothèque ouvre ses Membres
  (inviter, changer un rôle, retirer).
- Un champ « Filtrer… » apparaît au-delà de huit comptes ou bibliothèques.
- Correctif : un administrateur ne voit plus les bibliothèques des autres comptes parmi les siennes.

## [5.51.1] — 2026-10-07
Les feuilles de la sélection disent ce qu'on fait, la règle de création se confirme, et le design system rattrape
l'app (A480-A482, doctrine `docs/decisions/lot-v5-51.md`).
- **Feuilles ouvertes depuis « Actions »** (Ajouter à une collection, Déplacer, Ranger) : « ‹ Actions » devient un
  petit lien de retour, le titre de la feuille est le geste, et une seule ligne dit sur quoi l'on agit (« 2 éléments ·
  deux bibliothèques ») — la même partout, collections comprises.
- **« Ajouter à une collection »** : chaque case porte son icône — l'étoile pour l'Accès direct, le signet pour les
  collections — et la case vide se voit enfin en thème sombre.
- **« Déplacer vers une bibliothèque »** ne coche plus « Ma bibliothèque perso » quand la sélection est répartie sur
  deux bibliothèques.
- **Administration › Création de bibliothèques** : changer de règle ouvre un bandeau qui dit ce que cela changera,
  avec Annuler / Confirmer ; rien n'est appliqué avant « Confirmer ».
- **Design system (claude.ai/design)** : la fiche Couleurs suit les couleurs actuelles (31 pastilles étaient vides),
  neuf fiches sont désormais relevées sur l'app elle-même (démarrage, étapes, Vérifier, journal, parcours, Page,
  accueil, en-tête et quai, menu ⋯) au lieu de montrer des composants retirés, une fiche « Rangement » s'ajoute, et
  les lignes directrices sont à jour de la v5.51.

## [5.51.0] — 2026-10-07
Qui peut créer une bibliothèque, et comment la demander (A478-A479, doctrine `docs/decisions/lot-v5-51.md`).
**⚠ Rejouer `supabase/schema.sql`** (§ 9 et 9bis) pour en profiter ; sans cela, l'app garde l'ancienne règle
(administrateurs seulement) et Administration le signale.
- **Administration › Création de bibliothèques** : trois réglages — *Administrateurs seulement*, *Personnes
  autorisées*, *Tout compte approuvé*. Par défaut, « Personnes autorisées » avec une liste vide : rien ne change tant
  que vous n'autorisez personne. « ＋ Autoriser une personne… » choisit parmi les comptes approuvés ; « Retirer » rend
  la règle commune. Une personne autorisée devient administratrice de ce qu'elle crée, et ne peut créer qu'à son nom.
- **Les autres demandent** : « ＋ Demander une bibliothèque… » ouvre la même fenêtre que la création (nom, avec qui,
  rôle des invités ; sans invité, elle rappelle qu'une collection suffit pour ranger). La demande apparaît en tête
  d'Administration : « Créer » ouvre la bibliothèque au nom du demandeur et y invite les personnes indiquées ;
  « Refuser » la classe. Dans Moi, chacun voit ses demandes en attente (Annuler) ou refusées (Effacer).
- **Données** : les adresses des personnes à inviter ne sont gardées que jusqu'à la décision (registre RGPD § 3).

## [5.50.0] — 2026-10-07
Les collections : ranger ses aides sans rien déplacer (A475-A477, doctrine `docs/decisions/lot-v5-50.md`).
- **Une collection est votre rangement, à vous seul** : une liste nommée d'aides et de protocoles venus de n'importe
  quelle bibliothèque, même en lecture seule. Rien n'est copié ni déplacé, et une même aide peut être dans plusieurs
  collections. Elles suivent votre compte sur tous vos appareils ; les autres membres d'une bibliothèque ne les voient pas.
- **Où les trouver** : au téléphone, une rangée « Mes collections » sous l'Accès direct ; au bureau, dans la colonne de
  gauche ; dans la feuille Affichage ; dans Moi. L'Accès direct est la première collection.
- **Ranger** : « Ajouter à une collection… » dans le menu ⋯ de chaque aide et protocole (même quand « Modifier » est
  grisé) et en tête de la feuille Actions d'une sélection. Des cases : cocher range, décocher retire.
- **Une collection ouverte** dit qu'elle est à vous seul et d'où vient son contenu, propose « Ajouter des aides » et,
  par ⋯, Renommer, Retirer les indisponibles, Supprimer — les aides restent toujours où elles sont.
- **La barre de sélection ouvre ses actes par « Actions » à toutes les largeurs** : avec « Collection… », les cinq actes
  en toutes lettres ne tiennent plus sur la ligne au bureau.
- **« Nouvelle bibliothèque » demande d'abord « Avec qui ? »** et invite ces personnes à la création. Sans invité, elle
  propose une collection, qui suffit pour ranger. Une bibliothèque partagée avec personne peut être **convertie en
  collection** depuis sa fenêtre : ses éléments passent dans Perso, rien n'est supprimé.
- **Mettez à jour tous vos appareils** : une version antérieure ne connaît pas les collections (elle ne les efface pas).

## [5.49.0] — 2026-10-06
L'étape qui attend un seuil dit enfin ce qui est compté et quand sa case s'ouvre (A474), et quatre retours d'usage corrigés (A473, doctrine `docs/decisions/lot-v5-48.md`).
- **La jauge d'un seuil vit dans son étiquette.** « CHOCS DÉLIVRÉS ≥ 3 ●○□ » : les points comptent le compteur
  nommé juste avant, et le dernier repère a la forme d'une case — c'est là que l'étape devient cochable. Sous le
  libellé, les points et « encore 3 » se lisaient comme le compte de l'étape (« cochable encore 3 fois »).
- **Avant son seuil, la case de l'étape est là, estompée** (pleine et pâle) au lieu d'un pointillé qui se lisait
  « inatteignable » — « Faire maintenant » la coche à tout moment, à droite de la rangée. Au seuil, l'étiquette
  passe au vert, jauge pleine, et la case reprend son trait.
- **L'instant du seuil se voit** : au choc qui atteint le seuil, l'étape qui s'ouvre rebondit et s'éclaire brièvement
  de vert, une fois — seulement sur l'appareil qui a fait le geste, et jamais avec « réduire les animations ».
- **« Se déconnecter » ne déconnecte plus que cet appareil.** Il révoquait toutes les sessions du compte : les autres
  appareils se retrouvaient déconnectés au rafraîchissement suivant.
- **La capsule de session montre deux compteurs quand ils tiennent, toujours avec leur nom entier.** Le rappel à côté
  du chevron dit « +1 compteur » (ou « +1 minuteur ») quand une partie est déjà montrée : « 1 compteur » à côté d'une
  tuile de compteur se lisait comme le total. Un nom de compteur n'est plus jamais coupé (« Chocs délivr… » quand un
  minuteur tournait) : la tuile cède la place plutôt que de s'abréger. Les minuteurs restent prioritaires.
- **« Relâcher avant la fin annule »** se pose 14 px sous les boutons de la fenêtre de fin (il les touchait).
- **Moi : « Exporter mes données », « Prendre en main » et « Un problème ? »** sont espacés de la même façon (12 px).

## [5.48.9] — 2026-10-06
Au téléphone, dans Safari, toucher juste sous les boutons de la barre d'outils marche (A472, doctrine `docs/decisions/lot-v5-48.md`).
- **Ce qui se passait** : sous la barre, la bande blanche jusqu'à la barre « ⌃ ⌄ ✓ » du clavier n'appartient pas à la
  page mais à Safari (sa barre d'adresse flottante, environ 43 px). Un toucher y déplie Safari et ferme le clavier ;
  l'app ne le reçoit jamais, donc ne peut ni l'empêcher ni le rendre au bouton visé.
- **Une bande de 12 px sous les boutons fait désormais partie de la barre**, dans Safari seulement : un doigt qui vise un
  peu bas tombe chez l'app et va au bouton le plus proche. Elle prend 12 px au texte.
- **App installée sur l'écran d'accueil** : la bande de Safari n'existe pas, la barre reste à 41 px.

## [5.48.8] — 2026-10-06
Au téléphone, toucher un peu à côté d'un bouton de la barre d'outils ne ferme plus le clavier (A471, doctrine `docs/decisions/lot-v5-48.md`).
- **Mesuré avant correction** : un toucher sur sept à un sur quatre dans la barre (entre deux boutons, sur les bords,
  dans le vide avant « Insérer ») et environ 40 % des touchers entre les lignes d'un menu ouvert faisaient perdre la
  main au texte, donc fermaient le clavier.
- **Toute la barre et tout le menu gardent maintenant le clavier ouvert**, et un toucher à côté d'un bouton (jusqu'à
  12 px) va au bouton le plus proche ; une bande de 8 px au-dessus de la barre fait de même.
- **La barre garde sa hauteur de 41 px** : clavier et barre de Safari ouverts, elle laisse au texte la même place
  qu'avant (sur iPhone 15, environ 12 lignes visibles).

## [5.48.7] — 2026-10-06
Au téléphone, toucher la barre d'outils au-dessus du clavier marche à chaque fois (A470, doctrine `docs/decisions/lot-v5-48.md`).
- **Le clavier ne se ferme plus quand on touche un bouton de la barre ou une ligne de ses menus.** Sur iPhone, il se
  fermait une fois sur deux : le toucher retirait parfois le focus au texte avant que l'app ait pu l'en empêcher, et le
  bouton touché ne répondait alors pas toujours.
- **Retoucher le bouton d'un menu ouvert le ferme** (avant, il se refermait et se rouvrait aussitôt).
- Un glissé du doigt sur la barre ne déclenche rien.

## [5.48.6] — 2026-10-06
Au téléphone, les menus de la barre d'outils fonctionnent pendant qu'on écrit (A469, doctrine `docs/decisions/lot-v5-48.md`).
- **Titre, Liste, Encadré et Insérer s'ouvrent juste au-dessus de la barre**, sur toute sa largeur, quand elle est posée
  au-dessus du clavier. Avant, toucher l'un d'eux fermait le clavier : la barre redescendait sous le doigt et le menu
  s'ouvrait en bas de l'écran, sous le clavier.
- **Le clavier reste ouvert** pendant le choix, et après : on reprend la frappe là où l'on était. Toucher le texte
  referme le menu.

## [5.48.5] — 2026-10-06
Deux retouches de l'éditeur des références signalées à l'usage (A468, doctrine `docs/decisions/lot-v5-48.md`).
- **Sur tablette (780 à 999 px), l'aperçu sort de la carte** : il passe dans une colonne à droite, comme sur
  ordinateur, au lieu de s'afficher dans un cadre à l'intérieur du cadre « Contenu rédigé ». La barre d'outils prend
  alors le format compact (icônes) et tient sur une ligne.
- **Au téléphone, la barre d'outils se pose au-dessus du clavier** pendant qu'on écrit, comme la recherche de
  l'accueil. Le texte ne bouge pas quand elle se détache. Toucher un outil (B, I, S) n'abaisse plus le clavier ;
  les menus (Titre, Liste, Encadré, Insérer) l'abaissent le temps du choix, puis le texte reprend la main. À
  vérifier sur iPhone réel : le rendu dépend du clavier d'iOS.

## [5.48.4] — 2026-10-06
- **Exercice guidé, « Cochez les étapes restantes » :** le bloc en cours reste entièrement net, sans anneau, et le
  reste de l'écran (en-tête, capsule, quai) s'estompe — on voit d'un coup d'œil où cocher (A467).

## [5.48.3] — 2026-10-06
- **La proposition d'exercice guidé saute aux yeux.** Sur les aides d'exemple, la rangée « Apprendre avec cette
  aide » prend le dessin du mode Exercice : fond hachuré bleu pâle, bord en pointillé, titre et bouton en bleu —
  comme la bande d'exercice et la touche « ▲ Exercice ». Elle se distingue des cartes de l'aide en clair comme en
  sombre ; « Démarrer la session » reste le seul bouton plein de l'écran (A467).
