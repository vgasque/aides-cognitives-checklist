# Journal des modifications

## [5.154.0] — 2026-11-22
L'éditeur d'aide, plus léger au téléphone : des aides d'une ligne, et des listes vides qui disent quoi ajouter (A806,
A807). Aucune mise à jour du serveur.
- **Une aide d'une ligne, le détail quand on est dans le champ** (A806). Les explications sous les intitulés faisaient
  jusqu'à six lignes. Elles tiennent maintenant en quelques mots (« Discriminant · deux ou trois mots », « Code ·
  facultatif », « Repères posologiques · classés selon le bloc en cours »…). La phrase complète apparaît sous le champ
  dès qu'on le touche, et les lecteurs d'écran la lisent toujours. Même chose pour « Nom court » et « À l'échéance »
  d'un minuteur. Vaut aussi pour l'identité d'un protocole.
- **Une liste vide invite** (A807). Plus de rangée « … » ni de « + Ajouter une ligne » : « Ne pas oublier », les
  critères de la condition d'entrée et les références montrent une seule invitation qui dit ce qu'on ajoute et où ça
  s'affiche (« ＋ Ajouter un rappel — affiché en haut de l'aide, 4 au plus »). La toucher ouvre la première ligne,
  curseur dedans. Avec du contenu, le bouton dit aussi ce qu'il ajoute : « ＋ Ajouter un critère », « un repère »,
  « une surveillance »…
- **Le schéma attend deux blocs** : au téléphone, une aide d'un seul bloc ne montre plus de schéma.
- **« ＋ Lier une aide ou un protocole » tient sur une ligne**, le nombre disponible dans une pastille à droite.
- **Correctif : le détail d'un repère posologique passe sous sa ligne.** Il s'affichait à côté, et la dose comme le
  détail étaient coupés.
- Complications : l'aide devient « 1 à 3, à tout moment », avec une ligne fixe sous les rangées, « Chaque bouton de plus
  dilue les autres. »

## [5.153.0] — 2026-11-20
La carte « Contenu rédigé » d'un protocole, plus claire au téléphone, surtout quand elle est vide (A805). Aucune mise à
jour du serveur.
- **Protocole vide : une seule chose à faire** (A805). La carte montre « Écrire le contenu » en pleine largeur, avec en dessous ce qu'on peut écrire (titres, listes, tableaux, images). L'interrupteur « Mise en forme en direct » et la consigne « touchez un passage pour le modifier » n'apparaissent qu'au premier bloc : avant, ils n'avaient rien à régler ni à toucher.
- **« Coller du Markdown… »** sous l'invitation ouvre directement le champ de texte brut, pour coller un long texte d'un coup. C'est le même mode que l'interrupteur coupé.
- **Avec du contenu, la tête tient sur une ligne** : « Contenu rédigé facultatif » et l'interrupteur côte à côte, le Plan dessous au téléphone. L'interrupteur dit « Mise en forme » au téléphone ; les lecteurs d'écran entendent toujours le nom complet. La consigne « Touchez un passage pour le modifier » a sa propre petite ligne.

## [5.152.0] — 2026-11-20
Dans les menus, les définitions ne s'affichent plus en bandeau bleu (A804). Aucune mise à jour du serveur.
- **Une définition devient une note grise** (A804). Dans « Choisir la catégorie » (« Une seule par aide, avec sa couleur… ») et « Ajouter à une collection » (« Vos collections sont à vous seul… »), la phrase reste à sa place, sous le titre, mais sans cadre ni fond bleu. Elle ne se confond plus avec le choix en cours, l'anneau de sélection ou le bouton « Terminé », qui sont bleus eux aussi. Au téléphone, les catégories montent d'une trentaine de pixels.
- **Ce qui dit la conséquence d'un geste reste en bleu** : quand on range des éléments de deux bibliothèques à la fois, l'avertissement « 2 bibliothèques différentes… » garde son bandeau. C'est lui qu'il faut lire avant de choisir.

## [5.151.0] — 2026-11-20
Les menus déroulants du bureau et de la tablette ne répètent plus le bouton qui les ouvre, et leur titre ne se confond
plus avec les choix (A803). Aucune mise à jour du serveur.
- **Plus de titre qui redit le bouton** (A803). Un menu ouvert par un bouton qui dit déjà ce qu'on fait (« Ajouter un bloc », les filtres « Type », « Bibliothèque », « Catégorie » de « Tout », « Mettre en grille »…) s'ouvre directement sur ses choix. Ouvert depuis une icône (＋, ···, ⋮) ou un bouton qui dit autre chose (« Autre… », « Bloc après », « A → Z »), il garde son titre.
- **Le titre qui reste est posé** : plus petit (15 au lieu de 17,5), avec de l'air au-dessus et un filet qui le sépare des choix. Il ne se lit plus comme une rangée de plus. Tous les menus déroulants ont désormais la même tête que le menu des catégories.
- **Rien ne se perd** : un titre ne disparaît que si les mêmes mots sont sur le bouton qu'on vient de toucher. La ligne de contexte, les notices et le champ de recherche restent, et les lecteurs d'écran annoncent toujours le nom du menu.
- **Au téléphone, rien ne change** : les feuilles du bas gardent leur titre.

## [5.150.2] — 2026-11-20
Après une mise en veille, l'en-tête ne disparaît plus (A802). Aucune mise à jour du serveur.
- **Le haut de l'écran revient au déverrouillage** (A802). Sur iPad et iPhone, après une mise en veille, l'en-tête pouvait rester caché : la page commençait sous l'heure, sans retour, sans « Enregistrer », et sans moyen d'y remonter. L'app croyait le clavier encore ouvert, car au réveil iOS signale parfois un écran raccourci, comme si un clavier était affiché. Elle ne le croit plus que si un champ de saisie est réellement actif. **À vérifier sur iPad et iPhone.**
- Si un champ était en cours de saisie au moment de la veille, l'en-tête revient dès qu'on touche ailleurs que dans le champ.

## [5.150.1] — 2026-11-20
Deux correctifs pour la tablette : la liste des catégories défile seule, et « Ajouter un bloc » ne se referme plus en
ouvrant le clavier (A800-A801). Aucune mise à jour du serveur.
- **La colonne des catégories défile d'elle-même** (A800). Dans Bibliothèques, sur tablette et au bureau, une bibliothèque qui a beaucoup de catégories ne montrait le bas de sa colonne qu'une fois la liste des aides et protocoles défilée jusqu'en bas. La colonne reste en place, tient dans la hauteur de l'écran et se fait défiler seule ; choisir une catégorie en bas ne la remonte plus.
- **« Ajouter un bloc » ne se referme plus tout seul sur tablette** (A801). Depuis la v5.150.0, ses dix choix faisaient apparaître un champ « Filtrer… » qui prenait le focus : le clavier montait, puis se refermait avec le menu. Le menu n'a plus de filtre : c'est une courte liste d'actions.
- **Au doigt, aucun menu n'ouvre plus le clavier tout seul** : le champ de recherche d'un menu (catégorie, collection, document à joindre…) reste là, mais il ne prend le focus que si on le touche. À la souris, au trackpad ou au clavier, rien ne change : on tape aussitôt.
- **Un menu déroulant ne se ferme plus quand le clavier de tablette fait défiler la page** pour montrer le champ où l'on écrit.

## [5.150.0] — 2026-11-19
La barre d'onglets ne descend plus sous l'écran en faisant défiler, l'éditeur de protocole propose trois niveaux de titre,
et la fenêtre « Tableau » a un retour (A797-A799). Aucune mise à jour du serveur.
- **La barre d'onglets ne descend plus** (A797, d'après une vidéo d'iPhone). En faisant défiler une page de l'accueil, elle sautait parfois de 30 à 40 px vers le bas, jusqu'à sortir en partie de l'écran, et y restait. Le saut avait lieu à l'instant exact où la barre du haut devient « collée » (le petit titre paraît, le verre arrive). Ce verre est maintenant toujours en place, seule sa couleur change, et iOS n'a plus de raison de déplacer la barre d'onglets. Par précaution, la barre se recale aussi d'elle-même dès que le défilement s'arrête. **À vérifier sur iPhone.**
- **Trois niveaux de titre dans « Ajouter un bloc »** (A798) : Grand titre (`#`), Titre de section (`##`) et Sous-titre (`###`), marqués H1, H2, H3. Jusqu'ici, le menu ne proposait que « Titre de section », donc toujours `##`. **Un titre ouvert change de niveau sur place** : trois pastilles au-dessus du texte, sans retaper les `#`.
- **« Modifier le Markdown » a maintenant un retour** (A799). Le tableau ouvert en texte porte **« Revenir à la grille »**, qui rouvre la fenêtre « Tableau » sur le texte. Dans la grille, « Mettre à jour » écrit et referme ; « Annuler » vous ramène au texte.
- **Ce qu'on a tapé dans la grille n'est plus perdu** en passant au Markdown : la saisie est écrite d'abord. Si la grille n'a pas changé, rien n'est réécrit.

## [5.149.0] — 2026-11-19
Les brouillons d'une bibliothèque partagée ne vont plus sur les appareils des lecteurs, ni leurs fichiers (A796).
**Serveur à rejouer.**
- **Un lecteur ne reçoit plus les brouillons** (A796). Un brouillon d'une bibliothèque partagée (aide ou protocole) n'est envoyé qu'aux éditeurs et aux administrateurs de la bibliothèque — c'est le serveur qui l'applique. Ses images, vidéos et documents suivent : un lecteur ne lit un fichier que s'il sert à un élément qu'il peut voir. Jusqu'ici, l'appareil d'un lecteur recevait tout, brouillons et fichiers compris, et les masquait seulement à l'affichage.
- **Même avant la mise à jour du serveur**, l'appareil d'un lecteur ne télécharge plus les fichiers d'un brouillon qu'il ne peut pas ouvrir.
- **Un protocole repassé en brouillon disparaît des appareils des lecteurs** à leur synchro suivante — jamais pendant une session en cours, ni pendant qu'on le consulte : il attend la synchro d'après.
- **Rejoindre une bibliothèque, ou y devenir éditeur, apporte tout son contenu** : les éléments plus anciens que la dernière synchro n'arrivaient pas jusqu'ici. Une première fois aussi après cette mise à jour, pour rattraper ce qui a pu manquer.
- **Serveur à rejouer** : `supabase/schema.sql` (règles de lecture des aides, des protocoles et des fichiers de bibliothèque). Tant qu'il ne l'est pas, rien ne casse : l'app se comporte comme avant, avec le filet de l'appareil en plus.

## [5.148.3] — 2026-11-18
Les vidéos d'un protocole ne repartent plus de zéro à chaque modification, prennent bien moins de mémoire, et une seule
joue à la fois (A795). Aucune mise à jour du serveur.
- **Modifier un bloc ne réinitialise plus les vidéos** (A795) : dans l'éditeur de protocole, les vidéos restent en place pendant que vous écrivez et reprennent où elles en étaient. Rien n'est relu ni recopié à chaque modification ; l'enregistrement automatique ne relit plus les fichiers des vidéos à chaque sauvegarde.
- **Moins de mémoire** : une seule copie par vidéo pour toute la page, chargée seulement quand la vidéo approche de l'écran et libérée quand elle s'en éloigne beaucoup (sa vignette reste à sa place). Une vidéo pas encore sur l'appareil le dit toujours tout de suite.
- **Une seule vidéo joue à la fois en lecture** : celle qui est la plus au centre de l'écran. Les vidéos d'un même tableau jouent ensemble, pour comparer côte à côte. Lancer une vidéo à la main la fait passer devant ; l'arrêter à la main la laisse arrêtée. « Réduire les animations » : rien ne se lance seul, comme avant.

## [5.148.2] — 2026-11-18
Les vignettes des vidéos se voient enfin sur iPhone, et celles des vidéos déjà envoyées se font d'elles-mêmes, une fois
(A794). Aucune mise à jour du serveur.
- **Les vignettes des vidéos ne sont plus noires sur iPhone et sous Safari** (A794). La vidéo est maintenant posée dans la page, invisible, et lancée en muet le temps d'une image avant la capture : Safari ne fournissait aucune image autrement, et la vignette était noire. L'image est aussi prise vers 1 s au lieu de 0 s, pour éviter le noir d'un fondu d'ouverture ; une image noire ou unie est refusée et retentée plus loin.
- **Vos vidéos déjà envoyées reçoivent leur vignette d'elles-mêmes** : il suffit d'ouvrir l'app sur un appareil qui peut modifier le protocole et qui a la vidéo. Une vidéo à la fois, quand l'app est au calme, jamais pendant une session. La vignette part ensuite avec le protocole vers vos autres appareils.
- **Un seul essai par appareil** : une vidéo dont la vignette ne peut pas être prise ici (par exemple une vidéo HEVC d'iPhone que ce navigateur ne lit pas) n'est plus relue à chaque lancement ; elle sera retentée après une mise à jour de l'app, ou prise par un autre appareil.
- **Lire une vidéo suffit** : si une vidéo sans vignette joue à l'écran, sa vignette est prise sur l'image affichée, sans rien relire.

## [5.148.1] — 2026-11-18
La grille d'un tableau au téléphone : la colonne collée seulement si c'est un en-tête, et plus de clavier qui s'ouvre
tout seul (A793). Aucune mise à jour du serveur.
- **La 1ʳᵉ colonne de la grille n'est plus collée que si c'est une colonne d'en-tête** (A793), comme en lecture, et « Tout défile » (Moi › Affichage) la libère aussi dans la grille. Une 1ʳᵉ colonne de texte large occupait plus de la moitié de l'écran une fois collée ; le nom de la case reste dans la barre au pouce.
- **Au téléphone, le clavier ne monte plus tout seul** : ouvrir la fenêtre « Tableau » ne place plus le curseur dans la première case, et un choix dans « ⋯ » (en-tête, largeur, ligne ou colonne ajoutée) ne le place pas non plus. On touche la case pour écrire.
- **Plus de champ « Filtrer » dans les menus de la fenêtre « Tableau »** : il paraissait dans « ⋯ » d'une grille d'images et ouvrait le clavier. Le choix d'une image ou d'une vidéo garde sa recherche, sans clavier d'office.

## [5.148.0] — 2026-11-18
La fenêtre « Tableau » ne montre plus chaque bouton deux fois : les réglages du tableau sont en haut, le média s'ajoute
dans la case (A792). Aucune mise à jour du serveur.
- **La fenêtre « Tableau » range ses boutons (A792, planche « Fenêtre Tableau »).** Au bureau, une seule **ligne d'outils au-dessus de la grille** : « En-tête » avec ses deux bascules (1ʳᵉ ligne · 1ʳᵉ colonne), puis « Largeur · choisie ▾ » (ou « auto ») qui ouvre un menu — montrer ou masquer la règle, ajuster au contenu, colonnes égales, et « Même hauteur » seulement sur une grille d'images. La rangée d'options sous la grille et les trois boutons de largeur au-dessus disparaissent ; l'aide du clavier descend au pied, en petit.
- **Au téléphone, plus rien en double.** Une **ligne d'état** au-dessus de la grille (« En-tête : ligne · colonne | Largeur : choisie › ») ouvre la feuille « Tableau », la même que « ⋯ » : en-têtes, largeur des colonnes, ajouter en fin, Modifier le Markdown. Sous la grille, il ne reste que la barre au pouce ; la grille arrive plus haut.
- **Le média s'ajoute dans la case** : un « ＋ » sur la case active, et seulement elle (Image ou Vidéo, puis le choix du média), dans tout tableau. Il est posé à cheval sur le filet de la case : il ne cache aucun texte, n'épaissit aucune ligne, et reste visible quand la case dépasse de l'écran (il passe alors à gauche). « ＋ Image » et « ＋ Vidéo » ne sont plus ni sous la grille ni dans « ⋯ ».
- Rien ne change pour les protocoles enregistrés.

## [5.147.0] — 2026-11-18
La largeur des colonnes se règle sur les colonnes elles-mêmes, et une vidéo montre sa première image (A790-A791). Aucune
mise à jour du serveur.
- **La règle des colonnes est au-dessus des colonnes** : dans la grille d'un tableau, « Largeur » change les petits
  onglets en une règle, un segment par colonne avec sa part, et une pastille sur chaque filet. On tire la pastille : la
  colonne s'élargit sous vos yeux.
- **La grille d'édition prend les proportions de la lecture** : vous voyez ce que vous réglez. Une colonne trop étroite
  pour y écrire garde 112 px dans la grille et le dit (« 15 % · min. ») ; en lecture, elle aura bien sa part.
- **Une vidéo montre sa première image** au lieu du mot « Vidéo » : dans la grille d'un tableau, dans le texte tant
  qu'elle n'est pas arrivée sur l'appareil, et dans le choix d'un média, avec ▶ et sa durée. Elle est capturée quand vous
  ajoutez la vidéo ; pour les vidéos déjà là, l'appareil qui a le fichier la capture de lui-même.
- La première image voyage avec le protocole : sur un autre appareil, elle s'affiche avant que la vidéo soit arrivée.
- Une vidéo que le navigateur ne sait pas lire (un MOV hors de Safari) garde le mot « Vidéo ».

## [5.146.1] — 2026-11-18
Correctifs du réglage de la largeur, après vos retours (A789). Aucune mise à jour du serveur.
- **Un seul réglage** : une image ou une vidéo ouverte par « Modifier… » ne montre plus ses anciens pictogrammes de
  taille, qui faisaient doublon. Elle s'affiche à sa largeur, et une ligne rappelle qu'elle se règle en touchant l'image
  dans le document puis en tirant son bord. La fiche d'une image (« Images du texte ») garde le réglage, pour tous ses
  passages à la fois.
- **La barre de l'image sélectionnée se voit en mode sombre** : elle se fondait dans le contenu, surtout sur iPhone.
  Elle a maintenant un bord clair la nuit. Au téléphone, elle reste en bas de l'écran.
- **Sur iPhone, tirer une poignée ou une pastille ne sélectionne plus de texte.**
- Dans un tableau qu'on fait défiler de côté, le cadre de l'image sélectionnée suit l'image.
- Vérifié sur Chrome et Edge (le même moteur), Safari (le moteur WebKit, avec un iPhone et un iPad simulés, en clair et
  en sombre) et Firefox.

## [5.146.0] — 2026-11-18
Une liste écrite dans une case de tableau s'affiche en liste (A788). Aucune mise à jour du serveur.
- **Dans une case**, des lignes qui commencent par « - », « * » ou « 1. » deviennent une vraie liste, à puces ou
  numérotée — elles s'affichaient avec leur tiret. Une ligne décalée fait un sous-niveau (c'est aussi la forme que garde
  l'import de Notion). Un libellé au-dessus reste au-dessus.
- Rien ne change pour une case sans liste, ni pour « 5 - 10 mg » (un tiret au milieu d'une ligne n'est pas une liste).

## [5.145.0] — 2026-11-18
Les anciennes tailles d'image rejoignent la largeur qu'on tire, et l'import de Notion garde les largeurs (A787). Aucune
mise à jour du serveur.
- **Une image dont la taille avait été réglée** (¼, ½, ¾…) garde cette taille quand vous ouvrez le protocole dans
  l'éditeur : elle devient la largeur de son passage dans le texte, qu'on tire ensuite comme les autres. Rien ne change
  tant que vous n'enregistrez pas, et rien ne change en lecture.
- **La fiche d'une image** (« Images du texte ») règle maintenant sa largeur à tous ses passages — dans le texte, dans
  une liste et dans une case — et dit combien il y en a.
- **Import de l'export HTML de Notion** : une image que vous aviez réduite dans Notion garde sa taille, et des colonnes
  de largeurs différentes gardent leurs proportions.

## [5.144.0] — 2026-11-18
On choisit la largeur des colonnes de n'importe quel tableau, et la colonne d'en-tête d'un tableau large reste visible
quand on le fait défiler (A786). Aucune mise à jour du serveur.
- **La largeur des colonnes** : dans la grille d'un tableau, « Largeur » ouvre une barre qui représente le tableau, une
  part par colonne. Tirez une pastille entre deux colonnes : ce que l'une gagne, l'autre le perd (par pas de 5 %, ou au
  clavier avec ← →). Puis « Mettre à jour le tableau ». Vaut pour une posologie comme pour une grille d'images.
- **Boutons rapides** : « Ajuster au contenu » (comme avant), « Colonnes égales », « Même hauteur » (dans une grille
  d'images, chaque colonne prend la place qu'il faut pour que les images aient la même hauteur).
- En lecture, une colonne ne descend jamais sous son mot le plus long : une dose ne se coupe pas au milieu. Si le tableau
  ne tient pas, il défile de côté, comme avant.
- **Les filets restent** : un tableau de texte qui porte une photo (une boîte de médicament, par exemple) garde ses
  lignes et ses colonnes ; seule une vraie grille d'images s'affiche sans filets. Les tableaux concernés changent donc
  d'aspect.
- **La colonne d'en-tête reste visible** quand on fait défiler de côté un tableau plus large que l'écran (au téléphone
  surtout), si sa première colonne est une colonne d'en-tête. Réglage : Moi › Affichage › « Tableaux larges » — En-tête
  fixe (par défaut) ou Tout défile.
- La largeur s'écrit dans le texte, sur la ligne qui suit le tableau (`{widths="30 25 45"}`).
- ⚠ Un appareil resté sur une version **antérieure à la 5.142** affiche cette ligne en clair sous le tableau : mettez à
  jour vos appareils.

## [5.143.0] — 2026-11-18
On règle la largeur d'une image ou d'une vidéo en tirant son bord, dans le texte, dans une liste et dans un tableau
(A785). Aucune mise à jour du serveur.
- **Touchez une image ou une vidéo** en mise en forme en direct : elle se sélectionne (un cadre bleu, une poignée sur
  son bord, une petite barre). Tirez la poignée : la largeur suit, par pas de 5 %, aimantée au quart, au tiers, à la
  moitié… et à la largeur de sa voisine. La part s'affiche pendant le geste. ↶ annule.
- **Partout** : une image seule dans le texte, une image sous une étape de liste, une image dans une case de tableau.
  Dans une liste, deux ou trois images réduites se placent côte à côte sous l'étape.
- **Boutons rapides** : « Même largeur » et « Même hauteur » (les images d'une étape s'alignent sur une même hauteur,
  chacune selon sa forme). Le menu de la part propose ¼, ⅓, ½, ⅔, ¾, Pleine ou « Par défaut ». « Modifier… », un double
  clic ou Entrée ouvrent le bloc (la grille pour un tableau).
- **Au téléphone**, la barre se pose en bas, sous le pouce, et la proportion choisie est gardée — une image n'est jamais
  affichée sous 80 px de large.
- La largeur appartient à l'endroit où l'image est posée : la même image peut être grande dans le texte et petite dans
  une case. Elle s'écrit dans le texte (`{width=45%}` collé à la ligne de l'image).
- Les tailles déjà réglées ne changent pas. La taille réglée dans la fiche d'une image (« Images du texte ») vaut là où
  aucune largeur n'est écrite.
- ⚠ Un appareil resté sur une version **antérieure à la 5.142** n'affiche pas une image dont la largeur a été réglée :
  mettez à jour vos appareils.

## [5.142.0] — 2026-11-18
Préparation de la taille des images et des vidéos partout, et de la largeur des colonnes d'un tableau (A784). Rien ne
change à l'écran. Aucune mise à jour du serveur.
- **Pourquoi cette version d'abord** : les prochaines versions écriront la largeur d'une image ou d'une vidéo, et celle
  des colonnes, directement dans le texte du protocole (`![](img:…){width=45%}`, `{widths="30 25 45"}` sous un
  tableau). Sur une version d'avant celle-ci, une image ainsi écrite **disparaîtrait** de l'écran. Cette version sait
  déjà les lire : installée partout avant les suivantes, aucun appareil ne perdra d'image.
- Elle lit ces deux indications partout (texte, élément de liste, case de tableau, recherche, export, import) sans en
  tenir compte encore, et ne les affiche jamais en clair.

## [5.141.0] — 2026-11-18
Les vidéos ont leurs dimensions, et la dernière carte d'une recherche retrouve son bord bas (A782-A783). Aucune mise à
jour du serveur.
- **Une vidéo a sa largeur et sa hauteur** : elles sont mesurées quand on l'ajoute (bouton, glisser-déposer, collage,
  import Notion). Les vidéos déjà là sont mesurées d'elles-mêmes sur l'appareil qui les a, puis repartent avec leur
  protocole vers vos autres appareils.
- **Son cadre a donc sa vraie forme** tant qu'elle n'est pas arrivée (16:9, portrait…), au lieu d'un 4:3 imposé : la
  vidéo prend sa place sans faire bouger la page.
- **Recherche depuis l'accueil** : sur un écran large, la dernière carte des résultats avait perdu son bord bas (elle
  paraissait coupée). Elle l'a retrouvé.
- Une vidéo que le navigateur ne sait pas lire (un MOV hors de Safari) garde le cadre 4:3.
