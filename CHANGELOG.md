# Journal des modifications

## [5.73.0] — 2026-11-01
L'accueil retouché (A537-A539, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Accès direct en tuiles** : les aides épinglées s'affichent en grille, deux par ligne au téléphone, autant que la
  largeur en tient ailleurs. Une tuile montre le titre, la catégorie et l'état.
- **Vue compacte redessinée** : même dessin que la vue détaillée, mais chaque entrée tient sur une hauteur fixe —
  deux lignes serrées au téléphone et sur tablette, une seule ligne sur grand écran.
- **Barre du bas** : l'onglet actif est une pastille bleue pleine, bien visible dans les deux thèmes ; l'avatar de
  « Moi » et le point de session en cours se détachent mieux. La recherche a la même hauteur que la barre d'onglets.
- **Grand écran** : « Affichage » et « Sélectionner » sont alignés.

## [5.72.1] — 2026-11-01
Bords au téléphone, signalés sur iPhone (A536, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Accueil** : la barre du haut, quand elle reste collée en défilant, va jusqu'au bord droit de l'écran (elle
  s'arrêtait 8 px avant).
- **Page** : « Fermer » n'est plus collé en haut ni contre le titre.
- **Safari** : sous la Page (et toute feuille plein écran), la bande du bas ne prend plus la couleur du bouton bleu
  « Démarrer » ou de la bulle du guide restés dessous.

## [5.72.0] — 2026-11-01
Le rail de la session à la maquette Natif (A535, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Compteurs** : « − 1 + », la valeur entre ses deux boutons.
- **Minuteurs** : cartes grises, sans bordure (un minuteur échu garde son bord ambre).
- **Jalons** : une jauge à points à côté du compte, et le texte de l'aide en dessous (« → envisager une FV
  réfractaire »).

## [5.71.0] — 2026-11-01
Conformité aux maquettes Natif (A534, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **La colonne « Parcours »** (avant et pendant la session, sur grand écran) devient une liste légère : le bloc en
  cours en bleu, la décision sans fond ambre, les chevrons discrets. Replier et déplier marchent comme avant.
- **Le bouton du bloc** dit « Cochez les 3 restantes » (une ligne au lieu de deux).
- **La colonne de gauche** affiche le nombre d'aides et de sessions.

## [5.70.0] — 2026-11-01
Remesure complète de la refonte « Natif » sur 18 formats (A530-A533, doctrine `docs/decisions/lot-v6-0.md`). Rien à
rejouer côté serveur.
- **Survols** : une quinzaine de boutons et de rangées ne réagissaient pas au passage de la souris ; ils réagissent
  tous, selon leur famille. Les rangées ne se soulèvent plus, elles se teintent.
- **Intertitres en minuscules partout** (colonnes de la session, éditeur, Moi, menu ⋯, Affichage) ; seuls les mots
  d'état (« Critique », « Vigilance », « ● Session », « En cours ») restent en capitales.
- **Téléphone tourné** : le titre de l'aide n'est plus coupé dans l'en-tête (« Schéma » passe au menu ⋯).
- **Moniteur** : en portrait, le grand chiffre est nettement plus grand (220 px sur iPad, 109 px sur iPhone).
- Petits écrans : « Avant la session » ne passe plus sous « Page » à 320 px ; la pastille « À compléter » a une cible
  de 44 px ; le sélecteur de sections d'Administration reste sur une ligne.

## [5.69.0] — 2026-11-01
Refonte « Natif » : trois arbitrages de forme tranchés sur planche (A527-A529, doctrine `docs/decisions/lot-v6-0.md`).
Rien à rejouer côté serveur.
- **Rangées de l'accueil** : une aide n'écrit plus « Aide » ; un protocole garde « Protocole ».
- **Au téléphone, « Affichage » est la première pastille** sous le titre ; la ligne du compte disparaît (« Tout · n »
  dit le compte).
- **La Page n'a plus qu'un bouton « Imprimer ou PDF »** (le dialogue du système propose les deux).

## [5.68.0] — 2026-11-01
Refonte « Natif », fin des suites d'A510 (A525-A526, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté
serveur.
- **Menu ⋯ sur grand écran** : le tap qui le ferme ne coche plus l'étape qui se trouve dessous.
- **iPhone SE tourné** : l'accueil prend la colonne de gauche, comme les autres téléphones tournés et les tablettes
  (il n'avait ni onglets ni colonne).

## [5.67.1] — 2026-11-01
Correctif (A524, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Une seule recherche au téléphone** : le champ sous le titre « Aides », qui ne faisait qu'ouvrir la recherche du
  bas, disparaît. On cherche par le rond de la barre d'onglets, au-dessus du clavier.
- « ● Session » ne traîne plus un « · » seul en début de ligne quand la rangée passe à la ligne.

## [5.67.0] — 2026-11-01
Refonte « Natif » : le groupe « En cours » à l'accueil (A523, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer
côté serveur.
- **Une aide en session monte en tête de l'accueil**, dans un groupe « En cours », avec « ● Session 04:12 » en vert ;
  elle quitte sa catégorie le temps de la session. Un tap la rouvre.
- **La carte sombre « Session en cours » disparaît** (elle doublait la rangée). « Terminer » se fait dans la
  session, par « Fin ». La carte d'une session partagée reste.

## [5.66.0] — 2026-11-01
Lot 11 de la refonte « Natif » : Administration au bureau et la Page (A522, doctrine `docs/decisions/lot-v6-0.md`).
Rien à rejouer côté serveur.
- **Administration** : les sections (Vue d'ensemble, Comptes, Bibliothèques, Règles) sont un sélecteur segmenté ;
  les intertitres passent en minuscules ; le statut d'un compte est une pastille (ambre « En attente ») ; la fiche
  d'un compte, à côté de la liste, s'ouvre sur une carte d'en-tête.
- **La Page** : « Fermer » en mot à gauche, l'échelle en segmenté dans la barre, puis **Imprimer** et **Exporter en
  PDF** (au téléphone, ils restent dans le menu ⋯). La feuille est centrée sur un fond gris.

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
