# Journal des modifications

## [5.86.2] — 2026-11-05
Le quai garde ses mots à 320 px avec le texte à 130 % (A568, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer
côté serveur.
- **Correctif : « FV réfractaire » et « Horodater » pouvaient être coupés** dans la barre du bas pendant une session,
  sur un écran étroit (320 px) avec le texte agrandi à 130 %. Quand un mot ne tient toujours pas à la plus petite
  taille de texte autorisée, les touches « Fin » et « Tout voir », dont les mots sont courts, se resserrent à 44 px
  (la taille minimale d'une touche en session) et rendent cette place aux mots longs. Rien ne change ailleurs.
- Audit : la sonde du partage qui vérifie les gestes réservés attend que l'invité ait vraiment rejoint au lieu
  d'une durée fixe ; la sonde des mots du quai dit, quand elle échoue, ce qui manque et dans quelle police.

## [5.86.1] — 2026-11-05
Le retour système ne recule plus jamais deux fois (A563, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté
serveur.
- **Correctif : l'application pouvait se quitter toute seule en fermant une fenêtre ou un écran**, sur un appareil
  très chargé. Quand le navigateur tardait plus d'une seconde à revenir d'un cran dans l'historique, l'application
  croyait la demande perdue et la répétait : elle reculait de deux crans et sortait de son propre écran (vers la page
  précédente, voire hors de l'application installée). Elle attend désormais que le premier recul arrive, et ne le
  répète jamais.
- Audit : trois sondes ne dépendent plus de la vitesse de la machine (atelier d'import, voile du guide pendant le
  défilement) ou disent où en était l'application quand elles échouent (recherche dans les PDF). Aucun seuil changé.

## [5.86.0] — 2026-11-04
Importer une page Notion (A562, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Le .zip d'un export Notion (« Markdown & CSV ») s'importe tel quel** par « Importer un fichier » ou en le
  déposant : chaque page devient une **référence en brouillon**, avec ses images (retrouvées dans le dossier de la
  page, réduites comme une photo prise dans l'éditeur). L'atelier d'import la montre avant d'écrire.
- Le titre de la page devient celui de la référence ; les propriétés Notion (« Statut », « Date »…) sont retirées ;
  le souligné passe en gras, les encadrés Notion deviennent des encadrés (« Attention » quand ils commencent
  par ⚠️).
- Un **.md seul** s'importe aussi ; ses images, restées à côté, sont signalées absentes — le .zip est conseillé.
- Rien ne se perd en silence : une image introuvable est nommée dans le texte, et ce qui n'a pas pu entrer est dit
  avant l'import.

## [5.85.0] — 2026-11-04
Éditeurs : le dépliant « Identité » et le mode « déplacer » (A560-A561, doctrine `docs/decisions/lot-v6-0.md`).
Rien à rejouer côté serveur.
- **Toucher à côté sort du mode « déplacer »**, dans l'éditeur d'une aide (blocs, étapes, listes, minuteurs…) comme
  dans celui d'une référence (blocs) : un tap qui ne tombe pas sur une destination « Poser ici » repose l'élément à
  sa place. Ce tap ne fait rien d'autre (il n'ouvre pas le bloc touché) ; « ‹ Retour » reste actif en un tap.
- **Le menu « Choisir la catégorie » n'est plus coupé** : ouvert depuis « Autre… », il se faisait rogner par le bas
  de la carte « Identité ».
- **Déplier et replier « Identité » se fait d'un seul endroit**, à droite de l'intertitre : « Modifier ⌄ » quand
  la carte est repliée, « Replier ⌃ » quand elle est ouverte. Le chevron qui pendait au bout de la seule rangée
  « Catégorie » est retiré ; toucher une rangée repliée déplie toujours.

## [5.84.0] — 2026-11-04
Pincer pour zoomer l'aperçu du schéma dans la page (A559, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté
serveur.
- **L'aperçu du schéma dans une aide se pince** comme le plein écran : il suit les doigts, l'endroit pincé reste sous
  les doigts, et il redevient net au lâcher (de 40 à 400 %). Le zoom est commun à l'aperçu et au plein écran.
- Sur ordinateur : Ctrl + molette, ou le pincer du pavé tactile.
- Lever les doigts après un pincer n'ouvre pas de bloc par accident, et changer la taille de la fenêtre garde
  l'endroit regardé.

## [5.83.0] — 2026-11-04
Pincer pour zoomer le schéma en plein écran (A558, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Le schéma en plein écran se pince comme la Page, les PDF et les images** : il suit les doigts sans délai, l'endroit
  pincé reste sous les doigts, et il redevient net au lâcher (de 40 à 400 %).
- Sur ordinateur : Ctrl + molette, ou le pincer du pavé tactile.
- Lever les doigts après un pincer n'ouvre plus un bloc par accident, et changer la taille de la fenêtre garde
  l'endroit regardé.

## [5.82.0] — 2026-11-04
Accueil au téléphone : un bouton pour choisir QUOI afficher, un pour COMMENT le présenter (A556) ; le zoom survit au
redimensionnement (A557). Doctrine `docs/decisions/lot-v6-0.md`. Rien à rejouer côté serveur.
- **« Aides ⌄ » choisit ce qu'on voit** : la feuille « Afficher » commence par le **Type** (Tout · Aides · Protocoles ·
  À relire) et, s'il y en a plusieurs, la bibliothèque — ils agissent tout de suite, la feuille reste ouverte. Puis
  l'accès direct, les collections, les catégories et **« Gérer les catégories »**.
- **Le bouton rond ↑↓ devient « Trier et présenter »** : trier, regrouper, densité — plus aucun filtre en double. On
  le ferme par « Terminé ».
- **Le bouton filtre à côté de la recherche disparaît** : il ouvrait la même feuille que le bouton rond. Le champ
  prend toute la largeur ; les crans Tout · Aides · Protocoles restent quand on tape.
- Un filtre posé reste annoncé par sa puce sous le titre, qui rouvre « Afficher ».
- **Zoom et taille de fenêtre** : agrandir ou réduire la fenêtre pendant qu'une image, un PDF ou la Page est zoomé
  garde l'endroit regardé (le PDF restait sur une autre page).
- En large (tablette, ordinateur), l'accueil ne change pas.

## [5.81.0] — 2026-11-04
Pincer pour zoomer une image ouverte (A555, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Une image jointe qu'on ouvre se pince comme la Page et les PDF** : elle s'ouvre ajustée à l'écran, le pincer
  l'agrandit jusqu'à ×6 en gardant l'endroit pincé sous les doigts, et l'on s'y déplace au doigt. Nette au lâcher.
- Sur ordinateur : Ctrl + molette, ou le pincer du pavé tactile.
- Toucher le fond autour de l'image la ferme toujours ; lever les doigts après un pincer ne ferme rien.

## [5.80.0] — 2026-11-04
Pincer pour zoomer, comme sur une feuille : la Page d'une aide et les documents PDF (A554, doctrine
`docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Pincer à deux doigts agrandit ou réduit la Page** (fenêtre « Tableau » et Page dans l'aide) **et les documents
  PDF**, en suivant les doigts sans délai ; l'endroit pincé reste sous les doigts, et l'on peut déplacer la feuille
  en pinçant. Au lâcher, le texte redevient net à la nouvelle taille.
- Le glisser à un doigt ne change pas. Les boutons − / ＋ / ⤢ restent.
- **Sur ordinateur** : Ctrl + molette, ou le pincer du pavé tactile, font le même geste.
- **PDF** : plus de page blanche le temps du rendu après un zoom (l'ancienne image reste jusqu'à la nouvelle), et
  un document très agrandi ne s'affiche plus en blanc sur iPhone (taille d'image plafonnée).
- Lever les doigts après un pincer n'ouvre plus par accident un bloc ou un lien.

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
