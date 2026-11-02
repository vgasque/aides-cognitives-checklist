# Journal des modifications

## [5.77.0] — 2026-11-02
Les passages se règlent sur place (A548, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Encadré** : ouvert, il propose ses quatre types en pastilles — Alerte, Attention, Information, Confirmation. Un
  toucher change le type, rien à taper.
- **Image** : ouverte, elle s'affiche au-dessus du texte avec ses tailles (25 à 100 %) et « Remplacer… » pour changer
  la photo.
- **Sur ordinateur**, la poignée ⋮⋮ à gauche d'un passage permet de le glisser ailleurs ; une ligne bleue montre où il
  se pose. Au doigt, « Monter » et « Descendre » restent le geste.

## [5.76.0] — 2026-11-02
L'éditeur des références met en forme pendant qu'on écrit (A547, doctrine `docs/decisions/lot-v6-0.md`). Rien à
rejouer côté serveur.
- **Mise en forme en direct** (par défaut) : le contenu rédigé s'affiche comme à la lecture — titres, gras, encadrés,
  tableaux, images. Touchez un passage : lui seul s'ouvre en Markdown, le reste reste mis en forme. « Terminé » (ou
  Échap) le referme.
- Sur le passage ouvert : **Monter, Descendre, Dupliquer, Supprimer** (↶ annule). **« Ajouter un bloc »** propose
  paragraphe, titre, encadré, liste, cases, tableau, image ou séparateur.
- **Copier plusieurs passages** copie leur Markdown : la mise en forme suit au collage.
- L'interrupteur **« Mise en forme en direct »** ramène au texte Markdown entier, pour les longs copier-coller ; ce choix
  est retenu sur l'appareil.
- La bande d'aperçu au-dessus du clavier (5.75) est retirée.

## [5.75.0] — 2026-11-02
L'éditeur des références : voir en écrivant (A546, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté
serveur.
- **Au téléphone, clavier ouvert**, le passage où vous écrivez s'affiche rendu juste au-dessus de la barre d'outils :
  encadré, tableau ou image, sans basculer sur « Aperçu ». L'œil de la barre le masque ou le remet ; ce choix est
  retenu sur l'appareil.
- **Sur ordinateur et tablette en paysage**, le texte et son rendu sont à parts égales, et le rendu suit le défilement
  du texte.
- **Les images** : au bout de la ligne `![…](img:…)`, une vignette montre laquelle et à quelle taille (à la souris).
- **Déplacer une section** : le menu « Plan » propose Monter, Descendre, Dupliquer ou Supprimer la section où vous
  écrivez. ⌘Z ou ↶ annule.
- Le copier-coller et l'annulation restent ceux du texte, comme avant.

## [5.74.0] — 2026-11-02
Au téléphone, choisir une collection ou une catégorie (A545, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer
côté serveur.
- **Le titre choisit** : touchez « Aides ⌄ » pour ouvrir la feuille « Afficher » — Tout afficher, Accès direct, vos
  collections et les catégories, chacune avec son nombre. Un tap applique le choix et ferme la feuille.
- **Le titre dit ce qui est affiché** : il devient le nom de la collection ou de la catégorie choisie, avec
  « Collection · à vous seul » ou « Catégorie » au-dessus ; « Tout afficher » revient à toute la liste.
- **Plus de rangée de pastilles** qui défilait de côté (trois visibles sur quinze, et celle choisie partait hors de
  l'écran). « Affichage » (ranger, densité) devient le bouton rond au bout de la ligne du titre.
- Au téléphone, un filtre à la fois : choisir une catégorie retire la collection, et l'inverse. En large, rien ne
  change.

## [5.73.4] — 2026-11-01
Correctif de la recherche au téléphone (A544, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- Après avoir ouvert la recherche puis le bouton filtre, quitter rend bien la barre d'onglets du bas (la recherche
  restait affichée à sa place).

## [5.73.3] — 2026-11-01
Le haut et le bas de l'accueil au téléphone (A542-A543, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Une seule bande en haut** une fois la liste défilée : la bande sous l'heure prend la teinte de la barre du haut,
  plus de coupure entre les deux.
- **La barre du bas descend** à la hauteur d'une barre d'onglets iOS (24 pt du bord sur un iPhone à Face ID, au lieu de
  47) ; la recherche suit.

## [5.73.2] — 2026-11-01
Correctif de l'app installée sur iPhone (A541, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Accueil, Sessions et Moi** ne sont plus tronqués en haut : même page au repos, le contenu commençait sous l'heure et
  la barre du haut recouvrait le grand titre et les pastilles.

## [5.73.1] — 2026-11-01
Correctif de l'app installée sur iPhone (A540, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Accueil** : en défilant, la barre du haut prend son fond de verre dès que le titre « Aides » passe dessous ;
  « Sélectionner » et « Créer » ne chevauchent plus le titre ni les pastilles.
- La hauteur de la barre d'état et de la zone basse est désormais lue correctement (menu ⋯, barre du bas).

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
