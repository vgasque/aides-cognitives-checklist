# Journal des modifications

## [5.79.0] — 2026-11-03
Rétablir une modification annulée, dans les deux éditeurs (A553, doctrine `docs/decisions/lot-v6-0.md`). Rien à
rejouer côté serveur.
- **Nouveau bouton ↷ « Rétablir »**, à côté de ↶ : il apparaît dès qu'on a annulé et refait ce qui vient d'être
  annulé. Au clavier, hors d'un champ : Maj-Cmd-Z (Mac), Maj-Ctrl-Z ou Ctrl-Y (Windows). Une nouvelle modification
  le fait disparaître.
- **Éditeur des références** : quand un texte collé se découpe en plusieurs passages, un message le dit — « Découpé
  en n blocs — ↶ annule le collage. »
- Les messages de confirmation (annulé, rétabli, découpé) se remplacent au lieu de s'empiler.

## [5.78.3] — 2026-11-03
Correctif de l'éditeur des références, mise en forme en direct (A552, doctrine `docs/decisions/lot-v6-0.md`). Rien à
rejouer côté serveur.
- **Toucher en dehors du passage ouvert le referme.** Un texte Markdown collé (titres, listes, encadrés, tableaux) se
  découpe alors de lui-même en passages, sans avoir à toucher « Terminé ».
- La barre de mise en forme, ses menus et les fenêtres (tableau, collage depuis Word) laissent le passage ouvert ; faire
  défiler la page ne ferme rien ; toucher un autre champ (le titre…) y laisse le curseur.
- ↶ après un collage défait le collage entier : la référence revient à son état d'avant.

## [5.78.2] — 2026-11-02
Le bouton ↶ (annuler) apparaît après toute modification (A551, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer
côté serveur.
- Dans l'éditeur des références, **supprimer, déplacer, dupliquer ou ajouter un passage**, changer le type d'un encadré
  ou la taille d'une image faisaient la modification sans proposer ↶ ni enregistrer tout de suite : c'est corrigé.
- **La taille d'une image** réglée dans la liste « Images » et **la date de validation** (références et aides) ne
  proposaient pas non plus ↶ : corrigé, pour tout réglage de ce genre.
- Vérifié geste par geste : chaque modification fait paraître ↶ en haut de l'éditeur, et ↶ rend l'état d'avant.

## [5.78.1] — 2026-11-02
Correctif de mise en page de l'éditeur des références, mise en forme en direct (A550, doctrine
`docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- Les espacements sont ceux de la lecture : titres, paragraphes et listes respirent comme dans la référence lue.
- Plus de « ＋ » entre chaque passage ; pour insérer un passage, « ＋ Bloc après » sur le passage ouvert, ou « Ajouter
  un bloc » en bas.
- Le survol encadre le passage sans rien décaler ; ⠿ et le crayon se rangent ensemble en haut à droite.
- Le passage ouvert est plus léger : fond blanc, une seule bordure, texte en police normale (plus en gras).

## [5.78.0] — 2026-11-02
Déplacer un passage d'une référence comme une étape d'aide (A549, doctrine `docs/decisions/lot-v6-0.md`). Rien à
rejouer côté serveur.
- **« Prendre / Poser »**, le même geste que dans l'éditeur d'une aide : touchez ⠿ (à gauche d'un passage, sur
  ordinateur) ou « ⠿ Déplacer » sur le passage ouvert (au doigt), puis touchez « Poser ici » à l'endroit voulu. Le
  bandeau du haut dit ce que vous déplacez ; ✕ ou Échap annule.
- « Monter » et « Descendre » disparaissent, comme dans l'éditeur d'aide ; sur ordinateur, on peut aussi commencer à
  glisser la poignée.

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
