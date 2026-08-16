# Lot v5.12 — agir sur plusieurs fiches, replier un document

> Entrées NORMATIVES, comme les autres fichiers de `docs/decisions/`. Deux demandes de l'auteur,
> traitées ensemble, et une série de retours d'usage qui ont corrigé mes premières lectures — ils
> sont consignés avec ce qu'ils ont corrigé, pas seulement avec leur résultat.

> Les deux demandes : « possibilité de déplacer plusieurs fiches (entre bibliothèques, entre
> catégories), supprimer plusieurs fiches à la fois (avec pour la suppression une confirmation
> forte) » et « vue protocoles : titres H1 H2 H3 repliables en mode lecture ».

**A170. LA SÉLECTION MULTIPLE EST UN MODE DE GESTE, PAS UN ÉTAT DE L'APPLICATION.** Chacun de ces
gestes coûtait un aller-retour PAR FICHE — ouvrir, éditer, changer, enregistrer, revenir — et le
seul recours après un import raté était de supprimer une par une (A129 le disait déjà). Trois
propriétés qui ne se négocient pas : (a) **le mode ne survit pas à l'accueil** — l'accueil est aussi
l'écran qu'on ouvre en urgence, le retrouver en gestion après une consultation serait un piège ;
(b) **on ne coche que ce qu'on peut modifier** — sur une bibliothèque dont on est lecteur, le
déclencheur n'existe pas (la RLS est l'autorité, proposer un geste qu'elle refusera serait un
bouton mort doublé d'un mensonge) ; (c) **la sélection appartient à une bibliothèque** et le mode se
ferme quand on en change — les éléments cochés ne sont plus à l'écran, et « Tout » ne prend jamais
que ce que la liste MONTRE.

**A171. LE DÉCLENCHEUR VIT DANS LA RANGÉE DE GROUPEMENT, PAS DANS L'EN-TÊTE** (décision de
l'auteur : « l'en-tête est déjà saturé »). L'en-tête garde ses quatre commandes d'ACCÈS (identité,
recherche, Créer, compte), celles dont on a besoin en urgence. ⚠ Ne pas écrire que cette rangée
« accueille déjà Filtres » : c'était vrai en v5.0.3, le déclencheur a depuis rejoint le champ de
recherche. En sélection, la rangée s'efface entièrement — on ne re-range pas pendant qu'on coche.

**A172. UNE CONFIRMATION FORTE FAIT LIRE, ELLE NE FAIT PAS TAPER.** La suppression en lot énumère
les titres qui vont disparaître et le bouton reste FERMÉ tant que « J'ai lu cette liste » n'est pas
coché (`checkRequired`, ajouté à `confirmDlg` : jusque-là une case ne CONDITIONNAIT rien, elle ne
faisait que peindre le bouton en rouge). Un nombre à retaper se tape sans regarder ce qu'il compte,
un mot à recopier se recopie de même. La liste est bornée à dix titres, le reste compté : on ne peut
pas prétendre faire lire ce qu'on ne montre pas.

**A173. LA COCHE EST UNE COLONNE DE LA GRILLE, PAS UN INTRUS.** `.dir-row` est une grille à deux
pistes ; glisser un troisième enfant en tête le posait dans la piste SOUPLE et rejetait le contenu
dans la piste `auto` — un fossé qui grandissait avec la largeur de la carte (signalé à l'usage :
« encore plus marquant sur plusieurs colonnes »). On déclare la piste.

**A174. UN `sticky` SE RÈGLE SUR SON PROPRE DÉFILEUR — ET L'ACCUEIL EN A DEUX.** Sous 780 px c'est
la PAGE (le décalage vaut la hauteur de l'en-tête fixe) ; au-delà c'est `.home-main` lui-même
(`overflow-y:auto`), et le même décalage s'ajoute alors À L'INTÉRIEUR du défileur, sous un en-tête
qui ne le recouvre pas. Mesuré à 1194 px : 128 px de vide, dont 61 dus au seul `--hdr-h`. Deux
défileurs, deux décalages. ⚠ Corollaire mesuré : une marge négative ne rattrape PAS le rembourrage
du défileur — un élément collant est borné par la boîte de CONTENU de son bloc conteneur. C'est le
rembourrage qui doit céder.

**A175. UN `z-index` NE COMPARE QUE DES FRÈRES DE CONTEXTE.** Une barre `position:sticky` AVEC
`z-index` crée un contexte d'empilement : un menu monté dedans voyait son `z-index:70` ramené au rang
de son hôte (14), et le rail A–Z (`fixed`, z 15 sur `<body>`) passait devant. Une FEUILLE étant
`position:fixed`, son hôte ne lui sert pas à se placer : elle se monte à la racine. Le menu ANCRÉ,
lui, garde son hôte — c'est de lui qu'il tire sa position. Et une feuille se BORNE à 420 px centrés
au-delà de 780 : étalée sur un grand écran, elle cesse de se balayer d'un regard.

**A176. LES TITRES D'UNE RÉFÉRENCE SE REPLIENT — APRÈS LE RENDU, JAMAIS DANS LE PARSEUR.** Un
dépliant posé au parsing voyagerait dans TOUT rendu markdown, aperçus et compte rendu PDF compris
(même règle que le sommaire M5). Le titre RESTE un titre : le bouton vit dedans et n'enveloppe que
son texte — écrire `role="button"` sur un `<h2>` lui retirerait sa sémantique, donc la navigation par
titres, au moment précis où l'on ajoute une raison de s'en servir. Le parcours de pose est INVERSE :
en enveloppant d'abord la section du titre le plus bas, celui du dessus ramasse un paquet déjà
constitué — replier un H1 emporte ses H2 et H3 sans qu'on décrive la hiérarchie nulle part. Un titre
sans corps n'est pas repliable. Sur papier, tout se déploie.

**A177. UN REPLI EST UNE PRÉFÉRENCE LOCALE, PAS UNE DONNÉE.** Mémorisé par protocole (décision de
l'auteur), mais hors du document : il n'a rien à faire dans ce qu'on partage, exporte et synchronise.
La clé est le TITRE (slug + rang d'homonymie), jamais l'index de document — celui-ci se décale dès
qu'on insère une section, et l'on retrouverait « replié » sur une autre. Table bornée aux 50
derniers protocoles. ⚠ Le sommaire et la recherche OUVRENT ce qu'ils visent : un résultat dans une
section repliée est invisible (`hidden` : ni peint, ni défilable), et un sommaire qui mène à un titre
sans son corps ne mène nulle part. Nuance mesurée : le sommaire ouvre AUSSI la section du titre visé
(y aller, c'est demander à la lire) ; la recherche n'ouvre que ce qu'il faut pour montrer le résultat.

**A178. PENDANT UNE RECHERCHE, LE SOMMAIRE S'EFFACE — DÈS LA PREMIÈRE LETTRE.** Sommaire et
résultats répondent à la MÊME question (où aller) et se contredisent à l'écran ; sur écran étroit le
sommaire repoussait en plus le texte qu'on vient de trouver. ⚠ La règle a été ÉTENDUE par l'auteur
après une première version qui ne l'escamotait que sur résultat : à zéro occurrence il réapparaissait
entre deux frappes, et le contenu sautait à chaque lettre. Un écran qui bouge pendant qu'on tape
coûte plus que le sommaire ne rend. Il revient quand le champ se vide — et la croix qui le vide est
CELLE DE L'ACCUEIL (`.srch-x`), pas un second dessin.

**A179. LE CHROME COLLANT SUIT LE VIEWPORT VISUEL.** La v5.10.9 avait laissé le chrome de page hors
de portée du correctif `--vvt` (« il est ancré au viewport de mise en page avec le document qu'il
commande »). L'usage tranche : clavier ouvert, un `sticky` calé sur `top:0` du viewport de mise en
page passe AU-DESSUS de l'écran — on perd la barre de recherche au moment précis où l'on tape dedans.
`header.bar` et ce qui colle sous lui portent donc `+ var(--vvt)`. Restent hors de portée, et c'est
dit : les défileurs INTERNES, dont la colonne `.home-main` de l'accueil large.
