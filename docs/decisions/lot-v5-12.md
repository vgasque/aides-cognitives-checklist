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

**A180. UNE MESURE DU VIEWPORT VISUEL N'EST PAS STABLE PENDANT LE DÉFILEMENT.** Régression de la
v5.12.0, signalée à l'usage sur les trois familles d'écran : en rendant le chrome collant tributaire
de `--vvt`, on l'a rendu tributaire d'une valeur que le REBOND ÉLASTIQUE de fin de course et le
pincement font varier — sans qu'aucun clavier ne soit ouvert. L'en-tête suivait ces micro-décalages :
il sautait, et il descendait avec le rebond. La garde est la définition même du cas à couvrir : **un
clavier occupe de la hauteur**, donc le panoramique n'est retenu que si le viewport visuel est
réellement plus COURT que celui de mise en page. Pendant de la garde d'`unpan()` (v5.10.4), qui
refuse d'agir tant qu'un champ est focalisé : les deux décrivent la même frontière, chacune de son
côté. ⚠ Règle générale qui en sort : **avant de brancher une géométrie sur une mesure du viewport,
se demander ce qui d'AUTRE la fait bouger.**

**A181. UNE COQUE DE HAUTEUR FIXE NE SE « SUIT » PAS — ELLE SE RECADRE.** En accueil large il n'y a
aucune couche collante : la coque est calée sur `100dvh` et les colonnes défilent dedans. Or `dvh`
ne rétrécit PAS quand le clavier s'ouvre (il suit le chrome du navigateur, pas le clavier) — le
cadre restait à pleine hauteur, le clavier en recouvrait le bas, et le panoramique emportait le haut
hors de l'écran. On borne donc la coque à la hauteur RÉELLEMENT visible et on la descend du
panoramique : elle occupe exactement le rectangle visible. Corollaire de méthode : un correctif qui
déplace des couches collantes ne couvre PAS un écran qui n'en a aucune — vérifier la nature du
logement avant de généraliser un remède.

**A182. UNE PORTE STATIQUE NE REMPLACE PAS UN DÉMARRAGE RÉEL.** La constante de garde d'A180 a
d'abord été référencée sans être déclarée : `npm run check` restait VERT — une `ReferenceError`
n'est pas une erreur de syntaxe — et l'application ne démarrait plus. C'est `npm test` qui
l'attrape, comme il attrape le piège des hashs CSP. Les dix-neuf contrôles statiques mesurent des
FORMES ; seul un démarrage mesure qu'elle vit.

**A183. IL Y A DEUX TOKENS D'ANCRAGE DU CHROME, PAS UN — ET UN GARDE-FOU QUI N'EN VOIT QU'UN LAISSE
PASSER L'AUTRE.** `--hdr-h` (l'en-tête seul) et `--stick-top` (toute la pile collante, quai de crise
compris). La v5.12.1 a créé `--hdr-off` et son contrôle ; les CINQ colonnes ancrées sur le second —
sommaire d'une référence, rail de lecture, plan de l'aide — ont donc continué de disparaître clavier
ouvert pendant une version de plus (« lorsqu'on doit scroller en bas avec le mode recherche, la
sidebar ne suit pas »). `--stick-off` est leur ORIGINE ; `--stick-top` reste la HAUTEUR qu'il a
toujours été — une hauteur ne se décale pas, seule une origine le fait, et les mélanger
raccourcirait les colonnes en plus de les déplacer. Le contrôle étendu aux deux tokens a
immédiatement attrapé un SIXIÈME site jamais soupçonné (le volet du quai). ⚠ Leçon de méthode :
quand on écrit un garde-fou pour une famille de règles, **énumérer la famille avant de coder le
contrôle** — sinon il gèle la moitié qu'on connaissait et certifie l'autre.

**A184. UN ÉLÉMENT SE CENTRE SUR LA RÉFÉRENCE QUE L'ŒIL UTILISE, PAS SUR LA BOÎTE LA PLUS FACILE À
INTERROGER.** La croix d'effacement d'une recherche était centrée sur le CONTENEUR du champ — or ce
conteneur est une colonne qui grandit avec ce qu'on tape (navigation d'occurrences, puis documents
trouvés) : mesuré 52 px à vide, 88 px dès la première occurrence, donc une croix qui descend de
14 px à la deuxième lettre, et qui dépasse de 2 px le bord droit du champ (le conteneur a 8 px de
rembourrage que le champ n'a pas). Signalé deux fois — « pas centrée » puis « change de position en
fonction de ce qu'on écrit », la seconde phrase désignant la cause. Le repère est désormais une
boîte qui n'enveloppe QUE l'input. ⚠ ET LE COROLLAIRE DE MÉTHODE : mes premiers témoins mesuraient
le centrage CONTRE LE CONTENEUR — ils étaient donc VERTS sur le défaut même qu'ils prétendaient
couvrir. Même famille que le témoin géométrique aveugle à l'écrêtage (A167) : un témoin doit mesurer
contre la référence de l'utilisateur, et se vérifier sur quatre ÉTATS successifs quand la propriété
en jeu est la stabilité.
