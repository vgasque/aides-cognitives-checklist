# Journal des modifications

## [5.58.0] — 2026-10-31
Premier lot visible de la refonte « Natif » (A506-A507, A515 ; doctrine `docs/decisions/lot-v6-0.md`). Rien à
rejouer côté serveur.
- **Les cases sont rondes**, partout : étapes en session (même taille, 36 px ; la bordure rouge ou ambre dit
  toujours CRITIQUE ou VIGILANCE), sélection, collections, listes à cocher des références, Administration. Dans
  l'étiquette d'une étape qui attend un seuil (« Chocs délivrés ≥ 3 ●○○ »), le dernier repère devient un rond plus
  grand.
- **L'accueil passe en listes groupées.** La vue détaillée n'est plus une pile de cartes mais un groupe arrondi
  de rangées séparées par un filet, comme la vue compacte. Plus de liseré coloré : la catégorie se lit « ● SMUR »
  sous le titre, et une aide en session « ● En cours 12:04 ».
- **Les épinglées deviennent le premier groupe, « Accès direct »**, avec la même rangée que le reste de la liste
  (les tuiles disparaissent). L'étoile reste à droite.
- Les modes « Détaillée » et « Compacte » restent tous les deux.

## [5.57.3] — 2026-10-31
Trouvé en testant sur le simulateur iOS ce que la mesure n'avait pas pu voir (A512, doctrine
`docs/decisions/lot-v5-57.md`). Rien à rejouer côté serveur.
- **Rien ne passe plus sous l'encoche ou la Dynamic Island en paysage.** iPhone tourné, l'île couvrait le bouton
  retour et coupait « PARCOURS » ; à l'accueil, la marque de la colonne gauche passait dessous, et le quai entrait
  dans les coins arrondis. Le contenu, la colonne gauche, le quai, le moniteur et les fenêtres respectent désormais
  les marges de sécurité latérales de l'écran. Rien ne change en portrait, sur iPad ni sur ordinateur.
- Vérifié sur le simulateur (iPhone, iOS 26.5) : session en paysage, rotation aller-retour pendant une session.

## [5.57.2] — 2026-10-31
Correctifs issus d'une mesure de l'app sans a priori — 38 états, 10 tailles d'écran, 2 à 3 tailles de texte, nuit
et WebKit (A511, doctrine `docs/decisions/lot-v5-57.md`). Rien à rejouer côté serveur.
- **En paysage, la session rend la place aux étapes.** Téléphone tourné, l'en-tête, la rangée des minuteurs et le
  quai prenaient 54 % de l'écran (71 % avec le texte agrandi) : aucune étape n'était visible en entier. La capsule
  des minuteurs monte désormais dans l'en-tête, comme au bureau : 35 % (45 % avec le texte agrandi). Les tablettes
  ne changent pas. À vérifier sur un iPhone tourné, rotation comprise pendant une session.
- **Le quai garde ses mots, à toute taille.** « Horodater » se coupait en « Horo-dater » et « FV réfractaire »
  perdait sa fin avec le texte agrandi, au téléphone en paysage comme au bureau. Plus aucune césure : si un mot ne
  tient pas, tout le quai descend d'un cran de texte.
- **Le bouton retour a un nom** pour les lecteurs d'écran (« Retour »).
- **Plus lisible** : « démarre avec la session », « 2:00 cyclique, à lancer » (écran de démarrage, au bureau) et le
  raccourci « ⌘K » passent d'un gris à 2,1:1 au gris de lecture.
- **Cibles de 44 px en session** pour les renvois du parcours, la croix du volet des minuteurs et les commandes d'un
  repère horodaté.
- **Moniteur** : avec le texte agrandi sur un petit écran, l'étiquette d'une échéance ne peut plus sortir de sa bande.
- Outillage : le harnais d'accessibilité ouvrait le moniteur par une fonction inexistante (son contraste n'était
  jamais mesuré) ; deux témoins nouveaux ou élargis (quai à texte agrandi, paysage bas), vérifiés capables d'échouer.

## [5.57.1] — 2026-10-31
Un signalement sur capture, iPad installé (A501, doctrine `docs/decisions/lot-v5-57.md`). Rien à rejouer côté serveur.
- **La colonne gauche de l'accueil ne passe plus sous la barre d'état de l'iPad.** En app installée, la marque
  « Aides cognitives » en tête de la colonne était coupée et délavée sous l'heure, alors que la recherche et
  « Créer » avaient leur dégagement : la colonne est fixée au bord haut et son premier étage ne lisait pas l'inset
  de zone sûre, que l'en-tête lit depuis toujours. Une propriété ; rien ne change en navigateur ni sur Mac.
  À vérifier sur l'appareil, portrait et paysage.

## [5.57.0] — 2026-10-16
Deux retours de l'auteur sur la pastille du compte et le pied « Tout est prêt » (A499-A500, doctrine
`docs/decisions/lot-v5-57.md`). Rien à rejouer côté serveur.
- **« Tout est prêt » déplié ne répète plus la version.** La première rangée du dépliant redisait « v5.56.0 » juste
  sous la synthèse qui le porte déjà ; sans compte elle ne contenait plus que ce doublon. Sous une synthèse visible
  la version se tait et la rangée vide disparaît ; en erreur ou en attente (synthèse cachée) la version reste,
  calée à droite.
- **La pastille du compte est aussi sur « Moi » de la colonne, au bureau.** Depuis la refonte v5, l'accueil large
  n'a plus de bouton Compte dans l'en-tête : l'état de synchronisation n'y était plus visible. L'avatar à initiales de
  la colonne porte désormais la même pastille (synchronisé, en cours, erreur, en attente), peinte par la même
  porte que l'en-tête.
- **L'anneau « en cours » se voit la nuit** : trait renforcé sur les deux sites.
## [5.56.2] — 2026-10-15
Le menu des catégories dit ce qu'est une catégorie (A498, doctrine `docs/decisions/lot-v5-56.md`).
- **« Choisir la catégorie »** prend la même tête que la feuille des collections : titre, l'aide et sa bibliothèque,
  et une définition d'une ligne qui dit ce qui la distingue d'une collection. Dans une bibliothèque partagée :
  « Une seule par aide, avec sa couleur, vue par toute l'équipe de « SAMU 31 ». Pour un rangement à vous seul : les
  collections. » Dans Perso, où tout est déjà personnel : « Une seule par aide, avec sa couleur, pour classer
  l'accueil. Une aide peut être dans plusieurs collections. »

## [5.56.1] — 2026-10-15
Deux retours de l'auteur sur capture (amende A496, doctrine `docs/decisions/lot-v5-56.md`).
- **Au bureau, « Choisir… » (Collections) ouvre un menu ancré sous ses jetons**, comme « Autre… » pour la catégorie —
  il s'ouvrait en feuille au bas de l'écran. Le titre « Ajouter à une collection » et sa définition restent, d'un cran
  plus serrés ; le menu prend une coque plus large et ne sort plus de l'écran (il se borne à la place disponible sous
  la rangée, et c'est vrai de tous les menus ancrés).
- **Un filtre de texte dès cinq collections**, dans le menu de l'éditeur comme dans la feuille de l'accueil, pour
  retrouver une collection par son nom.

## [5.56.0] — 2026-10-15
Trois retours d'usage (A496-A497, doctrine `docs/decisions/lot-v5-56.md`). Rien à rejouer côté serveur.
- **La collection se choisit à la création.** La pancarte d'identité d'une aide ou d'un protocole porte une rangée
  **Collections**, sous Bibliothèque, dessinée comme la rangée Catégorie : les collections qui contiennent l'aide en
  jetons (ou « Aucune collection »), puis « Choisir… », qui ouvre la même feuille à cases que l'accueil — Accès
  direct, vos collections, « ＋ Nouvelle collection… ». Rien n'est écrit dans l'aide : une collection reste votre
  rangement, à vous seul, et se choisit aussi sur une aide en lecture seule. Créer depuis une collection affichée y
  range la nouvelle aide (la pancarte le montre, un tap le retire). Un brouillon ne s'épingle toujours pas en Accès
  direct, même avant sa première frappe ; un brouillon abandonné sans titre ne laisse rien dans vos collections.
- **« Nouveau protocole »** : la pancarte d'identité d'un protocole neuf disait « Nouvelle aide ».
- **Au téléphone, toucher à côté d'une feuille ne touche plus ce qu'elle couvrait.** Un tap sur le grisé fermait le
  sélecteur (catégorie, bibliothèque, collection, actions…) puis atteignait la rangée ou le bouton situé dessous, et
  l'ouvrait. Le grisé absorbe désormais le tap : la feuille se ferme, et rien d'autre ne bouge.

## [5.55.1] — 2026-10-08
Deux retours sur la page Administration (A495, doctrine `docs/decisions/lot-v5-55.md`).
- **Règles de l'instance** : une seule rangée, « Nouveaux comptes et bibliothèques », qui dit les deux réglages en
  vigueur. Les deux rangées d'avant menaient à la même page.
- **Retour au même endroit à toutes les largeurs** : au téléphone, « ‹ Moi », « ‹ Administration » ou « ‹ Comptes »
  se placent désormais au-dessus du titre, comme au bureau, et la barre de la fenêtre porte le nom de la partie
  ouverte (Comptes, Bibliothèques, Règles de l'instance…). Le titre n'est plus écrit deux fois.

## [5.55.0] — 2026-10-08
Administration devient une page claire, à petite comme à grande échelle (A494, doctrine `docs/decisions/lot-v5-55.md`).
Rien à rejouer côté serveur.
- **Moi** : la carte du compte ne change pas ; juste dessous, une carte **Administration** dit combien de demandes
  attendent (« 13 à traiter »). Tout le reste de l'instance quitte Moi.
- **Une page Administration**, ouverte depuis cette carte — en fenêtre au téléphone, dans la colonne principale en
  tablette et au bureau (la colonne gauche ne change pas). Quatre parties, en onglets sur grand écran :
  - **Vue d'ensemble** : « À traiter » en tête — demandes de compte et de bibliothèque dans une seule liste, les plus
    anciennes d'abord, avec Refuser · Approuver (ou Créer) sur place ; puis l'annuaire, les règles et l'état de
    l'instance (chiffres, contenus, stockage).
  - **Comptes** : recherche, filtres avec leur nombre (En attente, Approuvés, Refusés, Peuvent créer,
    Administrateurs), tri, 40 comptes à la fois ; **« Sélectionner » pour approuver ou refuser plusieurs comptes d'un
    coup**. Un compte s'ouvre à côté de la liste sur grand écran : statut, droit de créer, bibliothèques et rôles,
    « Ajouter à une bibliothèque… », bibliothèques qu'il a créées, suspension ou suppression.
  - **Bibliothèques** : recherche, filtres « △ Sans administrateur » (personne ne peut y inviter), « Vides »,
    « Dont je suis membre » ; toucher une bibliothèque ouvre sa gestion, comme avant.
  - **Règles** : « Valider chaque nouveau compte » (l'interrupteur qui était caché dans « Comptes en attente ») et
    « Création de bibliothèques » (trois choix expliqués). Chaque changement se confirme, et la confirmation dit ce
    qui va se passer — couper la validation donne accès tout de suite aux comptes déjà en attente.
- Avec peu de comptes et de bibliothèques (8 ou moins), tout reste visible sur la vue d'ensemble, sans recherche ni
  filtres.
- La fenêtre « Comptes en attente » disparaît : son contenu est dans « À traiter » et dans « Règles ».
- Le retour (geste ou bouton) remonte d'un compte à la liste, puis à la vue d'ensemble, puis à Moi.

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
