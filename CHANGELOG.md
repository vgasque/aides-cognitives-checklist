# Journal des modifications

## [5.65.0] — 2026-11-01
Lot 10 de la refonte « Natif » : l'éditeur se parcourt (A521, doctrine `docs/decisions/lot-v6-0.md`). Rien à
rejouer côté serveur.
- **L'Identité se lit en rangées** : « Titre », « Code court », « Catégorie » avec leur valeur à droite. Un tap
  déplie les champs sur place, « Replier » les range.
- **La structure est une liste** sous « Ne pas oublier » au téléphone et sur tablette : une rangée par bloc (numéro,
  titre, nombre d'étapes ou de branches), puis les complications. Le schéma suit la liste.
- **Un bloc s'ouvre sur sa page** : seul le bloc est affiché, avec la porte « Ajouter ». « ‹ Retour » ou le geste
  retour du téléphone ramène à l'aide. Une remarque de relecture ou un rappel « → » ouvre directement la page du
  bloc concerné ; « prendre / poser » montre toute l'aide.
- **Sur grand écran**, la colonne Structure prend le même dessin (deux lignes par bloc, bloc ouvert surligné).

## [5.64.0] — 2026-11-01
Lot 9 de la refonte « Natif » : l'habillage de l'éditeur (A520, doctrine `docs/decisions/lot-v6-0.md`). Rien à
rejouer côté serveur.
- **Un grand titre « Modifier l'aide »** en tête de l'éditeur.
- **Les listes sont des groupes de rangées** sous leur intertitre (« Ne pas oublier », « Critères », « Diagnostics à
  éliminer ») : l'ajout est la dernière rangée, les ✕ sont ronds, la consigne des 4 rappels passe sous le groupe.
- **« ▶ Essayer » garde son mot au téléphone** ; l'état « À relire » quitte l'en-tête étroit (il reste dans
  « État »).
- La façon d'éditer ne change pas : chaque ligne reste un champ, la poignée glisse comme avant.

## [5.63.0] — 2026-11-01
Lot 8 de la refonte « Natif » : Sessions et Moi (A520, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté
serveur.
- **Sessions est une liste groupée par jour** (« Aujourd'hui », « Hier », « Cette semaine », puis le mois) : une
  rangée par session avec sa catégorie, l'heure, la durée et les étapes cochées. Un tap ouvre ses actions
  (Rouvrir, Compte-rendu, Supprimer) ; une session en cours garde « Reprendre » à vue. Les exercices restent à part.
- **Moi** prend la même allure : intertitres en minuscules, groupes sans ombre ; l'Accès direct se décrit « en tête
  de l'accueil ».

## [5.62.0] — 2026-11-01
Lot 7 de la refonte « Natif » : l'écran de démarrage d'une aide (A520, doctrine `docs/decisions/lot-v6-0.md`). Rien à
rejouer côté serveur.
- **« Quand l'utiliser » et « Ne pas oublier » sont des listes groupées** sous leur intertitre, toujours ouvertes
  avant la session (en session, rien ne change).
- **Une seule ligne sous le titre** : « SMUR · adulte · ACR · validation », puis « △ À relire » et « △ À compléter »
  en pastilles ; le bandeau « À relire » disparaît.
- **« Page » (et « Schéma » sur tablette et ordinateur) sont en haut de l'écran.**
- « Apprendre avec cette aide » devient une rangée sobre ; sur ordinateur, les minuteurs prêts sont des tuiles
  (« au démarrage », « à lancer »).

## [5.61.0] — 2026-11-01
Lot 6 de la refonte « Natif » : la session, selon vos quatre arbitrages sur planche (A519, doctrine
`docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Les étapes sont à plat dans la carte du bloc**, sans tuile grise ; seule l'étape faite garde son fond vert.
  CRITIQUE et VIGILANCE s'écrivent seuls, en couleur, sans pastille.
- **La tête du bloc dit « En cours · Bloc 3 »** ; la légende « sous l'étape, en gris : la réponse attendue »
  disparaît.
- **La décision n'a plus de fond ambré** : contour bleu comme tout bloc en cours, et « ◆ Décision · bloc 2 » en
  ambre. Son jalon passe au pied : « SI Chocs délivrés ≥ 3 ●○○ 0/3 », le texte dessous, le raccourci ⚡ au seuil.
- **L'en-tête dit « ● Session »** au lieu de « ■ Mode crise » ; le choix du thème passe dans le menu ⋯ (il reste
  dans l'en-tête d'une référence).
- **Les repères du bloc tiennent sur une ligne** : « △ Adrénaline — IV/IO » en ambre, l'état à droite, la dose
  dessous.
- Gardé : la cellule de compteur de la capsule (valeur, puis nom entier), pour ne jamais abréger son nom.

## [5.60.0] — 2026-10-31
Lot 5 de la refonte « Natif » : le verre clair et le moniteur (A518, doctrine `docs/decisions/lot-v6-0.md`). Rien à
rejouer côté serveur.
- **En thème clair, la capsule des minuteurs, le quai et leurs volets deviennent du verre clair**, comme les
  barres d'iOS, au lieu de la bande sombre. Le contraste a été mesuré au pixel au-dessus des étapes les plus
  chargées (4,9:1 au pire). En thème sombre, rien ne change.
- **Le moniteur est redessiné** sans changer de nature (plein écran, lu à deux mètres) : « ● Session » devant le
  chrono, « Revenir » dans une pilule (toucher n'importe où ferme toujours), une barre de progression sous le
  grand chiffre, et la bande devient une carte où chaque minuteur a sa rangée, son nom en tête et « dans 01:59 »
  sur l'axe. Sur une tablette posée, le grand chiffre monte jusqu'à 220 px.

## [5.59.0] — 2026-10-31
Lot 4 de la refonte « Natif » : la navigation du téléphone (A517, doctrine `docs/decisions/lot-v6-0.md`). Rien à
rejouer côté serveur.
- **Une barre d'onglets en bas au téléphone** : Aides · Sessions · Moi, et la recherche dans un rond à droite. Elle
  flotte en verre, comme les barres d'iOS. « Moi » porte vos initiales et l'état de la synchronisation.
- **Sessions et Moi sont des onglets**, plus des fenêtres qui s'ouvrent par-dessus : le retour du téléphone ne les
  referme plus (on change d'onglet), seule Administration, ouverte depuis Moi, se referme par le retour.
- **Un grand titre « Aides »** en tête de page, qui se replie dans la barre du haut quand on fait défiler.
  « Sélectionner » est en haut à gauche, « ＋ Créer » en haut à droite.
- **Les filtres sont des pastilles** sous le champ de recherche : Tout, Accès direct, vos collections, vos
  catégories. « Affichage » (ranger, densité) est sur la ligne du compte.
- **« Créer » et « Affichage » s'ouvrent en feuille du bas** qu'on referme en la tirant vers le bas (ou ✕).
- Sur tablette et ordinateur, le titre « Aides » ouvre la liste, avant le groupe « Accès direct ».
- Téléphone tourné : rien ne change encore (la colonne gauche viendra plus tard).

## [5.58.1] — 2026-10-31
Le lot 3 de la refonte « Natif » remis sur la maquette (A516, doctrine `docs/decisions/lot-v6-0.md`) : la v5.58.0
s'en écartait. Rien à rejouer côté serveur.
- **La catégorie est un point coloré en tête de chaque rangée**, son nom dans la ligne du dessous ; en sélection,
  la case prend sa place et le point revient devant le nom.
- **La ligne du dessous se lit comme une phrase** : « Aide · SMUR · adulte · △ À relire ». L'état suit l'identité
  au lieu d'être calé à droite dans une pastille, et la ligne passe à la ligne plutôt que de couper un mot.
- **Des rangées plus serrées** (52 px au minimum), un filet qui commence au texte, des groupes sans bord ni ombre,
  des intertitres en minuscules (« Accès direct 1 », « SMUR 1 »).
- La vue compacte garde sa ligne unique avec l'état à droite ; elle perd la pastille et le gras.

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
