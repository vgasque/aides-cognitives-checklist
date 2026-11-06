# Journal des modifications

## [5.89.0] — 2026-11-06
La session, deuxième passe « Natif » : ce qui entoure les étapes se rapproche d'iOS et de Material 3 (A571, doctrine
`docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Le titre de l'aide n'est plus coupé** en session : il passe sur deux lignes, et « · adulte » le suit.
- **L'historique redevient discret** : une ligne de texte gris, sans pastille, jamais coupée. Elle dit
  « Historique · diagnostic confirmé », puis « Historique · 2 blocs ». Le mot « Parcours » a disparu ; le compte des
  étapes reste à droite. Ouvert, il montre une boîte grise en retrait : la confirmation et ses critères, puis les blocs faits.
- **Les boutons « Vérifier » et « Cochez les n restantes »** tiennent sur une ligne, en pilules.
- **Le quai du bas est aligné et plus compact** : plus de séparateurs, une barre en pilule. Au téléphone, toutes les
  icônes sur une même ligne et chaque mot sur la sienne ; sur tablette et au bureau, l'icône à gauche du mot. Avec plusieurs complications, la touche dit « Complications » et le nombre s'affiche dans une
  pastille sur l'éclair.
- **Sous le bloc, une seule liste « Pendant toute l'aide »** remplace les six cartes (Ne pas oublier, revue,
  À vérifier, diagnostics, repères, références) ; chaque section se déplie sur place. La note locale s'intitule
  « Contexte local ».
- **Au bureau, la colonne de droite passe en listes** : chaque minuteur a son bouton « Démarrer » visible, chaque
  compteur une pilule « − n + », « Ajouter un minuteur » et « Ajouter un compteur » sont au pied de leur liste, le son
  et la veille deviennent des interrupteurs.

## [5.88.1] — 2026-11-06
Retours sur la v5.88.0 : la confirmation d'une étape qui attend son moment dit ce qui reste, plus de lignes vides, et
l'exercice guidé l'enseigne (A570 §10, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- Toucher la case d'une étape en attente affiche maintenant **ce qui reste** : « Prévue dans 2 chocs délivrés. »,
  « Prévue dans 1 choc délivré. », ou « Prévue dans 03:56. » (le temps défile), puis **« Cocher »** ou **« Annuler »**.
- **Plus de ligne vide** sous une étape en attente : sous une étape qui lance un minuteur ou compte, la ligne dit ce
  que fera la coche (« ◷ 04:00 Adrén. dose ») ; sinon, il n'y a pas de ligne.
- **L'exercice guidé** montre une étape qui attend son moment et la question de sa case ; « Prendre en main » gagne le
  geste « Une étape qui attend son moment », et le glossaire le terme « Moment d'une étape ».

## [5.88.0] — 2026-11-06
Les étapes « complexes » en session (registre, compteur ou minuteur liés, étapes qui attendent leur moment) sont
redessinées sur une seule grammaire, plus légère (A570, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté
serveur.
- **Une place pour chaque chose.** Au-dessus du libellé, en petits mots : quand et quel risque (CRITIQUE, VIGILANCE,
  DOUBLE CONTRÔLE, « CHOCS DÉLIVRÉS ≥ 3 ●○○ », « À L'ÉCHÉANCE ◯ 03:57 », ✓✓ CONSTATÉ). Dessous : ce que fait
  la coche.
- **Une liste, sans cadres.** Les étapes sont séparées par un simple filet. Plus de cadre pointillé autour des étapes
  qui attendent, plus de fond vert sous les étapes faites : la case et la couleur du texte disent l'état, et seule
  l'étape à faire maintenant reste en noir.
- **Une seule taille de libellé**, revue des causes réversibles comprise.
- **Des mots plus courts** : « +1 Chocs délivrés » au lieu de « 3 → 4 à la coche · Chocs délivrés », « annulable 9 s »
  au lieu de « décocher annule · 9 s », « relance à 05:00 ».
- Le minuteur qu'attend une étape « à l'échéance » s'affiche à côté de sa condition ; quand il arrive au bout, l'étape
  dit **« ✓ À L'ÉCHÉANCE »** en vert, comme un seuil atteint (au lieu de « Échu », qui disait l'état du minuteur).
- Une étape à faire une seule fois, déjà faite à un passage précédent, dit **« ✓ DÉJÀ FAITE »**.
- **Une seule coche** : l'icône de la case, reprise en petit dans les mots du dessus ; le « ✓ » devant la réponse d'une
  étape cochée disparaît (il doublait la case verte).
- Une étape garde sa hauteur quand son moment arrive (rien ne bouge sans geste).
- La trace de vérification (« ✓✓ constaté », « △ écart ») rejoint les autres mots au-dessus du libellé.
- **Une seule police dans l'étape** : la réponse attendue et les valeurs quittent la police à chasse fixe ; la réponse
  reste distincte du libellé par sa taille et sa couleur.
- **Plus de bouton « Faire maintenant ».** Pour cocher une étape avant son moment, on touche sa case : la ligne du
  dessous dit « Pas encore le moment. » et propose « Cocher quand même » ou « Annuler ». Une coche par erreur (qui
  lancerait un minuteur) est ainsi rattrapée, et rien n'encombre la rangée au repos.
- Audit : un témoin mesure la nouvelle grammaire, dont l'écart entre le mot de registre et son libellé.

## [5.87.0] — 2026-11-05
Les étapes « complexes » en session — celles qui attendent leur moment, comptent, lancent un minuteur — retrouvent
leurs couleurs et s'allègent (A569, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Correctif : trois étiquettes d'étape avaient perdu leur couleur** depuis la v5.61. Au 3ᵉ choc, l'étiquette
  « ✓ Chocs délivrés ≥ 3 » de l'étape qui devient faisable redevient **verte** ; « Échu » (l'échéance du minuteur
  de l'étape) redevient **ambre** ; « Faite » (une étape à faire une seule fois, déjà faite) redevient verte. Elles
  sortaient toutes grises, comme une règle encore en attente.
- **Correctif : l'étape qui s'ouvre au seuil ne vire plus au gris.** Son éclairage vert finissait sur l'ancien fond
  gris des étapes, puis disparaissait d'un coup ; il s'éteint maintenant en douceur vers la rangée nue.
- L'étape « faite une fois » vit à plat, comme les autres étapes : son cadre gris disparaît. Seule l'étape qui
  attend son moment garde un cadre, en pointillé.
- Les règles de moment s'écrivent en phrase (« Chocs délivrés ≥ 3 », « À l'échéance », « Au besoin ») au lieu de
  capitales espacées ; les mots d'état (« Échu », « Faite »), comme CRITIQUE et VIGILANCE, restent en capitales —
  la règle et l'état se distinguent d'un coup d'œil.
- « passage 4/4 » ne se coupe plus entre le mot et le compte au téléphone.
- Audit : un témoin lit désormais la couleur et la casse de ces étiquettes (aucun ne le faisait).

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
