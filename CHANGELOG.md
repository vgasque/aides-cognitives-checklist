# Journal des modifications

## [5.158.1] — 2026-11-26
Correctifs trouvés à la revue visuelle et à l'audit complet de la v5.158.0 (A826-A827). Aucune mise à jour du serveur.
- **Dans un éditeur, la barre du haut ne reste plus vide.** Après un petit défilement, le titre de la page (« Modifier
  l'aide », ou la rangée « Titre » d'un protocole) était déjà passé sous la barre, mais la barre ne l'affichait pas
  encore : elle attendait 110 px de défilement. Elle reprend maintenant le titre dès qu'il est à moitié caché.
- **Au téléphone, la barre de mise en forme monte au-dessus du clavier dès qu'un bloc s'ouvre**, sans le court délai
  qui pouvait la laisser en haut de page quand on passait d'un bloc à un autre clavier ouvert (A827).

## [5.158.0] — 2026-11-26
Aligner une image ou une vidéo, lui écrire une légende depuis l'éditeur ; et les corrections de la v5.157.0 que vous
avez signalées (A819-A825). Aucune mise à jour du serveur.
- **Aligner une image ou une vidéo : à gauche, au centre ou à droite.** Touchez-la en mise en forme en direct : au
  bureau, trois boutons dans sa barre ; au téléphone, « Gauche · Centre · Droite » dans la barre du bas. Dans le texte,
  l'alignement s'écrit avec la largeur : `![](img:ID){width=45% align=center}`. Il vaut pour une image seule sur sa
  ligne ; dans une liste ou un tableau, l'image suit sa puce ou sa colonne. En pleine largeur, les boutons sont grisés :
  il n'y a rien à aligner. Une image centrée a une poignée de largeur de chaque côté.
  ⚠ Un appareil resté sur une version antérieure n'affiche pas une image alignée (la ligne s'y lit en texte) : mettez
  tous les appareils à jour.
- **Écrire une légende depuis l'image** : « Légende » dans sa barre, ou l'invite « Ajouter une légende » sous l'image
  sélectionnée. La légende s'écrit entre les crochets de cet emplacement (`![Masque haute concentration](img:…)`) et
  s'affiche sous l'image, alignée comme elle. Pareil pour une vidéo.
- **Corrigé — un grand vide au-dessus du passage ouvert** quand on touchait directement un passage sous un autre déjà
  ouvert. La page défile pour garder la ligne touchée sous le doigt ; la mise en page ne bouge plus.
- **Corrigé — « En faire un titre » proposait toujours « ## »** : sous « ## Intoxication au CO », « Physiopathologie »
  devenait sa sœur. La relecture propose maintenant « Titre ## » ou « Sous-titre ### », le bon niveau mis en avant, et
  deux lignes converties à la suite deviennent sœurs.
- **« Tout convertir en titres (n) » et « Tout corriger l'écriture des doses (n) »** dans la relecture d'un protocole,
  dès deux points du même genre : un seul geste, un seul ↶ pour tout défaire. L'éditeur d'aide garde « une par une ».
- **Corrigé — la lecture et la mise en forme en direct avaient encore des écarts différents autour des titres** (4 à
  11 px) : ils sont maintenant identiques, mesurés, au téléphone comme au bureau.
- **Corrigé — le trait des sous-listes** tombait à droite de la puce et faisait un petit « | » isolé sous une seule
  sous-puce : il part maintenant de la puce, et s'arrête au milieu de la première ligne de la dernière sous-puce.
- **Corrigé — au téléphone, le bouton « Ajouter » recouvrait « Supprimer »** sous un passage ouvert : il s'efface tant
  qu'un passage est ouvert.

## [5.157.0] — 2026-11-26
Les protocoles se lisent mieux, et l'éditeur en mise en forme en direct ne « saute » plus (A811-A818). Aucune mise à jour
du serveur.
- **La structure se voit en lisant** :
  - Un titre colle à son contenu : de l'air au-dessus, peu dessous, et un sous-titre posé juste sous son titre s'en
    rapproche. L'interligne passe de 1,7 à 1,55 : les groupes se lisent.
  - **Un « ### » porte maintenant un filet fin dessous.** Il ne se confond plus avec une ligne en gras.
  - **Un trait fin relie une sous-liste à sa puce** : on voit d'un coup d'œil ce qui dépend de quoi.
- **L'éditeur et la lecture ont le même dessin** : interligne, marges, puces et titres sont identiques. Ce qu'on voit en
  écrivant est ce qu'on lira.
- **Toucher un passage l'ouvre sur place** : le texte ne bouge plus (le cadre est dessiné autour, plus dedans), le
  curseur se pose là où l'on a touché, et la ligne touchée reste sous le doigt. Les pastilles du bloc passent sous le
  texte. Au bureau, le bloc ouvert a la même coloration que le Markdown entier (marqueurs grisés, titre et gras plus
  noirs).
- **« Physiopathologie : » en gras devient un vrai titre si vous le voulez** : la relecture repère une ligne faite
  seulement de gras et propose « En faire un titre » (« ## Physiopathologie »). Elle apparaît alors dans le Plan et le
  sommaire, et se replie. Une ligne à la fois ; une phrase qui commence en gras n'est pas concernée.
- **Le Plan suit le défilement** : une fois le titre du protocole sorti de l'écran, l'en-tête écrit la section où vous
  êtes (avec la grande section au-dessus, dans la ligne « Édition »). Le toucher ouvre le Plan. Aucune place prise, et
  rien quand le clavier est ouvert.
- **Passer de la mise en forme en direct au Markdown entier (et retour) garde la même section à l'écran** : avant, on
  se retrouvait ailleurs, parfois au début.
- **Correctif — sélectionner des blocs au cadre, à la souris** : le cadre fait maintenant défiler la page quand on
  approche du bas (ou du haut) de l'écran, et la molette ou le trackpad pendant le geste étend la sélection. On peut
  enfin prendre des blocs qui n'étaient pas à l'écran.

## [5.156.0] — 2026-11-26
Listes plus faciles à manier dans l'éditeur de protocole, et les images se collent (A809, A810). Aucune mise à jour du
serveur.
- **Remonter d'un niveau, enfin facile** :
  - **Entrée sur une sous-puce vide** la remonte d'un niveau, au lieu de terminer toute la liste. Au premier niveau,
    Entrée termine la liste, comme avant. Une sous-puce qui remonte sous « 1. » devient « 2. ».
  - **Effacer juste après le « - »** (ou « 1. », ou la case) remonte la puce d'un niveau ; au premier niveau, la ligne
    redevient du texte.
  - **Deux boutons ⇤ ⇥ dans la barre d'outils**, quand le curseur est dans une liste. Ils prennent la place
    d'« Encadré » (et de « Titre » sur les petits téléphones), qui n'ont pas de sens dans une puce. Indispensables au
    téléphone, où il n'y a pas de touche Tab.
  - Au clavier, Maj+Tab au premier niveau rend aussi la ligne au texte. Une sélection de plusieurs puces monte ou
    descend d'un niveau en gardant sa structure. ⌘Z annule.
- **Les niveaux se voient mieux** : Tab et ⇥ écrivent maintenant 4 espaces par niveau au lieu de 2 — deux fois plus de
  retrait dans le bloc ouvert de la mise en forme en direct. Vos protocoles ne changent pas : un niveau se lit par
  rapport à la puce parente, qu'il soit écrit avec 2, 3 ou 4 espaces, et ⇤ retire toujours un niveau entier. L'import
  HTML de Notion et le collage depuis Word écrivent aussi 4 espaces.
- **Coller une photo ou une capture d'écran** l'ajoute au protocole, comme « Insérer › Image » (réduite, comptée dans
  les 10 Mo). Le curseur est dans une puce : l'image va dans la puce. Ailleurs : un bloc image. Un texte copié avec une
  image (Word, Excel, une page web) se colle toujours en texte. Sur iPhone, selon la version de Safari, une photo
  copiée depuis Photos peut ne pas arriver au collage : « Insérer › Image » reste là.

## [5.155.2] — 2026-11-22
Les intitulés des cartes de l'éditeur d'aide ont tous la même graisse. Aucune mise à jour du serveur.
- **« Minuteurs & compteurs », « Complications » et « Voir aussi »** passent au même gras que « Repères posologiques »,
  « Références » et les champs de l'Identité. Les intertitres posés au-dessus d'un groupe (« Ne pas oublier »,
  « Condition d'entrée ») restent plus légers, comme avant.

## [5.155.1] — 2026-11-22
Correctifs d'alignement dans l'éditeur d'aide, après revue des changements depuis la 5.154 (rectificatif d'A808). Aucune
mise à jour du serveur.
- **Colonne « Structure » du bureau, en mode « Réordonner »** : le numéro de chaque bloc était plus bas que son titre et
  que la poignée ⠿. Les trois sont maintenant sur la même ligne.
- **Intitulés des cartes alignés sur leur contenu** : « Minuteurs & compteurs », « Complications » et « Voir aussi »
  étaient décalés de 16 px vers la droite, contrairement à « Références » ou « Repères posologiques ». La ligne « Chaque
  bouton de plus dilue les autres. » des Complications suit.

## [5.155.0] — 2026-11-22
Les blocs d'une aide se réordonnent depuis la liste « Structure » (A808). Aucune mise à jour du serveur.
- **« Réordonner »** à droite de « Structure · n blocs » (au téléphone dans la liste, au bureau dans la colonne de
  gauche). Chaque bloc devient une rangée d'une ligne : touchez celle à déplacer, puis « Poser ici » à l'endroit
  voulu. Tout tient sur un écran, et l'on peut enchaîner plusieurs déplacements avant « Terminé ».
- Le bloc posé reste sous le doigt. ✕, Échap, toucher à côté ou retoucher la rangée annulent, comme ailleurs.
- **La poignée ⠿ d'un bloc ouvert reste** : elle montre toujours tous les blocs dépliés, pour placer un bloc en voyant
  le contenu de ses voisins.

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
