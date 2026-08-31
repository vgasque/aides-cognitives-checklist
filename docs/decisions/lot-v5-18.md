# Lot v5.18 — l'accueil sans mécanisme (A238-A268)

> Conçu sur l'artefact « Accueil — la barre d'en-tête » (canvas Claude Design, 29/08/2026),
> chaque décision mesurée au rendu avant d'être retenue. Point de départ : « le principe de
> l'en-tête qui se rétrécit est bien mais l'implémentation est mauvaise ».

**A238. L'EN-TÊTE D'ACCUEIL N'A PLUS D'ÉTATS.** Le repli 7a (`home-slim`, seuil 80/40,
hystérésis, gel `azr-aim` de l'en-tête, re-mesure après bascule, `syncHomeNew`,
`rescueFiltTog`/`rescueHomeSearch`, `syncSrchH`/`--srch-h`, keyframes `hdrDeplie`/`hdrReplie`)
est PURGÉ : huit rouages pour 52 px mesurés (115 → 63). L'en-tête est `position:static` sur
l'accueil — le défilement EST l'état. La marque y prend 24 px (c'est un titre de document, plus
du chrome) et « Créer » garde son mot en étroit.

**A239. L'ACCÈS VIT DANS `#homeDock`, STATIQUE.** Pilule de recherche + îlot de filtre : FIXES en
bas en voie étroite (zone du pouce — Safari/Maps ; 75 % des interactions mobiles sont au pouce),
rangée statique sous l'en-tête en voie large (au clavier, le bas d'écran n'est pas une zone de
pouce). Matière OPAQUE (A222 : un fond translucide rend le contraste invérifiable — NN/g
« Liquid Glass Is Cracked » le confirme du dehors) ; l'îlot flotte seul → contour `--ctl-line`
(A43). La bande sous la pilule COUVRE (fondu de 20 px sur la seule arête haute) : un fondu ne
dissimule que ce qui va vers SA couleur, et ce qui défile est une carte, pas le fond. Sous
clavier, le dock LOGE le champ qu'on tape : il se cale au viewport visuel (`--vvt`/`--vvh`),
il ne se retire jamais (v5.13).

**A240. LA LISTE EST L'UNION DES BIBLIOTHÈQUES.** `state.scope` ne filtre plus l'accueil ; les
brouillons se décident PAR FICHE (`canEditFiche`). Une bibliothèque n'est pas un filtre : elle
DÉFINIT un corpus (doctrine T9) — `scopeBarHtml` est purgée de la feuille de filtres, qui ne
porte plus que ce qui RESTREINT (type, catégorie). Le cran catégorie se compare PAR NOM
(`catFilterOn`) : chaque bibliothèque a ses propres ids, « Anesthésie » est un seul cran.

**A241. TROIS RANGEMENTS, UN SEUL CONTENU.** Le sélecteur (3 crans : Bibliothèque · Catégories ·
A–Z, `bib` par défaut) choisit les INTERTITRES de la même liste, jamais son contenu. Intertitres
COLLANTS (`position:sticky` — zéro JS, ils collent au défileur de leur largeur) ; celui d'une
bibliothèque porte compte, cadenas (lecture seule) ou ✎ (administrée). Le contenu orphelin
(bibliothèque perdue) va en UNE file de queue, jamais une section par id inconnu.

**A242. LA PROVENANCE COUVRE UN RISQUE CLINIQUE.** Deux fiches HOMONYMES de deux bibliothèques
sont deux fiches différentes. Règle à trois régimes (`searchLibTag`) : en recherche (liste
plate) et hors rangement « bibliothèque », TOUTE rangée dit sa bibliothèque ; en rangement
« bibliothèque », seules les homonymes la portent. Et la catégorie de la méta porte sa PASTILLE
(la couleur n'est jamais seule, le nom est là). ⚠ Aucune heuristique de « risque » inventée :
une regex pédiatrique a été écrite puis RETIRÉE dans l'heure — le périmètre réglementaire
interdit toute sémantique clinique déduite ; l'ambre reste aux données (brouillon, périmé).

**A243. LE RAIL A→Z N'INDEXE QUE L'ALPHABET.** Il n'existe qu'en rangement A–Z et en voie
étroite ; ses deux ancres sont des CONSTANTES (haut 120 px — plus d'en-tête à mesurer ; bas
96 px — le dock borne). Le hack « en-tête fixe pendant la visée » (v5.10.5) est purgé avec sa
cause. En voie large, l'INDEX est la colonne gauche : des mots, pas des lettres — et il EMMÈNE
(défilement vers la section), il ne filtre jamais. La gouttière étroite de 8 px reste
inconditionnelle ; celle de 32 px en large part avec le rail.

**A244. ≥ 1200 px, LE RÉPERTOIRE SE LIT EN TABLEAU** (`rowT`) : titre · discriminant ·
catégorie · bibliothèque · validée — la méta en colonnes comparables d'un balayage vertical,
plus les comptes de tenue à jour (« n brouillons · n à revérifier ») dans l'en-tête de section.
Même modèle, autre DENSITÉ : mêmes sections, même `.card-open`, mêmes épingles. Palier par
`html.zw1200` (règle 10 — jamais une media query pour un seuil de commande), re-rendu au
franchissement. La recherche et la sélection gardent les rangées classiques (extraits, cases).
Une grille à colonnes fixes se VÉRIFIE PAR LA SOMME : 682 px fixes+gouttières, mesuré — un
`minmax(0,1fr)` peut tomber à zéro sans bruit (vu deux fois en maquette).

**A245. « ACCÈS DIRECT » (tuiles épinglées) N'EXISTE QU'À ≥ 1200 px** (`.qa-sec`) : en étroit,
les étoiles des rangées suffisent et une section de plus retardait la liste.

**A246. LA SESSION EN COURS EST LE SEUL APLAT TEINTÉ DE L'ACCUEIL** (registre CONFIRMATION,
`--ok-soft`) : c'est sa RARETÉ qui la fait voir — quatre marques dispersées criaient sans être
trouvables (mesuré en maquette). En sombre, l'aplat ne borne plus rien (`--ok-soft` ≈ fond) :
périmètre `inset 1px --ok` (A222).

**A247. CE QUE LE CHANTIER A COÛTÉ EN DOCTRINE.** Trois entrées antérieures sont REMPLACÉES par
ce lot : 7a (« ce qui se retire au défilement » — plus rien ne se retire), la moitié « + Créer
ne part jamais » de 7a (il vit dans un en-tête qui défile : décision de l'auteur), et A170
(« l'en-tête est déjà saturé » — il n'y a plus d'en-tête saturé). La v5.6 « le répertoire est un
livre » est remplacée par « les sections sont le livre » (la carte est la grille de section, les
intertitres collent dehors). Diagnostic d'origine, à garder : la doctrine et le CSS décrivaient
un en-tête à quatre rangées que le rendu n'émettait plus depuis la v5.6 (`#homeChrome` vidé sans
condition) — AUCUN des vingt garde-fous ne mesure l'en-tête d'accueil.

**A248. LE RANGEMENT EST UNE PHRASE, PAS UN SÉLECTEUR** (maquette, signalé à l'usage : « le
rangé par n'est pas ce qui a été décidé ») : « Rangé par **bibliothèque** ⌄ » ouvre le menu
maison (`openPickMenu` — listbox ancrée, feuille sous 780 px). Le segmenté 3 crans et son replay
de pastille (`_grpSegI`, `.seg-jump`) sont purgés. Trois options : Par bibliothèque · Par
catégorie · Par ordre A–Z.

**A249. EN VOIE LARGE, LA RECHERCHE EST LA BARRE DU HAUT** (maquettes Bureau/Tablette, signalé :
« tout l'en-tête ne correspond pas à ce qui a été convenu ») : `#homeDock` vit DANS la rangée
d'identité — en étroit, `position:fixed` le sort du flux (rien ne change) ; en large il est la
barre de la maquette : marque à gauche (largeur de la sidebar : la recherche commence au bord de
la colonne de contenu), champ au centre (rayon de composant, ⌘K affiché), Créer et Compte à
droite. UNE seule ligne de séparation. Le champ étroit reste une pilule (forme du pouce).

**A250. LA SIDEBAR PORTE TOUJOURS LES DEUX CLÉS** (décision utilisateur : « on affichait
toujours les bibliothèques et catégories ») : BIBLIOTHÈQUES **emmènent** (défilement vers la
section, en basculant d'abord le rangement « bibliothèque » si besoin — la section doit exister
pour être visée) ; CATÉGORIES **filtrent** (même cran que la feuille du pouce, `state.cat`,
re-tap = retirer, `aria-pressed`, compte par catégorie sur la liste rendue). Conséquence : **le
déclencheur de filtre n'existe pas en voie large** (`display:none` ≥ 780) — la feuille reste
l'outil du pouce. Le compte de la ligne « Répertoire » continue d'annoncer les filtres actifs
(un type posé en étroit puis élargi ne devient jamais invisible).

**A251. LA SECTION EST LA CARTE, L'INTERTITRE COLLE DEDANS** (signalé : « la bordure supérieure
des cartes s'affiche mal ») : `.dir-g` porte bordure + rayon + `overflow:clip` (clip, PAS
hidden : hidden ferait de la carte le scrollport des sticky, qui ne colleraient plus jamais) ;
`.dir-l` colle à 0 SUR la carte, fond `--surface` — au défilement il coiffe la carte au lieu de
laisser les rangées passer à nu sous un intertitre flottant. Même dessin que le tableau ≥ 1200,
dont l'en-tête de colonnes est la première rangée de SA carte (34 px, fond `--bg`, Validée
alignée à droite).

**A252. LA TABLETTE (780-1199) LIT DES RANGÉES** (signalé : « le format tablette hérite encore
de l'ancien affichage ») : la grille fluide de cartes (maquette 2f, une exploration
intermédiaire) est purgée — mêmes rangées qu'en étroit, sidebar à gauche, mêmes cartes de
section. Trois densités, un seul modèle : rangées (< 1200), tableau (≥ 1200), pilule/étoiles en
étroit.

**A253. PALIER 390 DÉCLARÉ** (`check-paliers`) : sous 390 px, l'en-tête d'accueil n'a la place
ni du mot « Créer » ni de la marque à 24 px — marque 21, « ＋ » seul. Au-dessus (≤ 779), le mot
et les 24 px (maquette Zero, 390 px). En voie large la marque garde 17,5 px : l'en-tête y est du
chrome, même hauteur que partout (v5.6).

**A254. LE PIED DE PAGE FINIT AU-DESSUS DU DOCK, PAGE COURTE COMME LONGUE** (signalé : « bas de
page non visible à cause de la barre flottante ») : la réserve est le REMBOURRAGE du pied
(`calc(96px + var(--sab))`, < 780) — le `::after` d'avant l'étendait SOUS le viewport : une page
courte défilait de 96 px pour un pied qui restait sous le dock, et `--sab` n'était pas compté
(78 px de dock + 34 d'inset > 96). Question posée « l'afficher en haut si la page est courte ? »
— non : `main{flex:1}` l'ancre déjà au bas ; il reste un pied, simplement au-dessus du dock.
Corollaires du même passage : la VISÉE du rail A→Z ne soustrait plus `stickHeight()` (l'en-tête
d'accueil défile — la lettre atterrissait 65 px trop bas, témoin doctrine) et l'îlot filtre
S'ÉTIRE à la hauteur du champ (`align-self:stretch` + `aspect-ratio:1` — 44 px figés contre un
champ de 48 : deux niveaux au lieu d'une rangée).

**A255. LES FILTRES VIVENT DANS LA FONCTION RECHERCHE** (décision utilisateur, rappelée deux
fois — une première application « bouton fantôme dans la pilule » a été REPRISE : ce n'était pas
la décision). Hors recherche, la pilule est SEULE (maquette Zero — aucun déclencheur nulle
part) ; **chercher fait paraître la rangée de filtres au-dessus de la pilule** : crans de type
(Tout · Aides · Protocoles, agissant en direct SANS perdre la requête — `setSection(k, true,
{keepCat:true})`, dans la rangée comme dans la feuille) + « Filtrer (n) » qui ouvre la feuille.
Sous clavier, le dock monte de 44 px de plus quand la rangée est là (`:has`). HORS recherche, un
filtre actif reste annoncé ET modifiable : le fragment « filtres : … » de la ligne Répertoire
est un bouton discret (`.dir-hf`, halo de cible) qui ouvre la feuille — l'état n'est jamais
piégé. En voie large, la rangée n'existe pas (A250 — la sidebar filtre). Dans la foulée, les
chips TYPE (`.scopebtn`) partagent les règles de `.catchip` — leur habillage était parti en
silence avec la purge de `.scopebar` : une famille, une recette.

**A256. LE RANGEMENT SE RETIENT, D'UN LANCEMENT ET D'UN APPAREIL À L'AUTRE** (demande de
l'auteur). `setHomeGroup()` est le poseur unique (menu « Rangé par » ET bascule par la sidebar) :
état + `localStorage` par compte (`ac-home-group`, spaceKey) + `schedulePrefsPush()`. La
préférence voyage dans `data.prefs.homeGroup` du document perso de synchro, comme `readMode` —
et suit sa doctrine : la synchro n'ÉCRIT que la préférence, elle ne re-range JAMAIS la liste
sous les yeux (l'état ne suit que si l'accueil n'est pas la vue courante ; sinon au prochain
lancement). Valeurs bornées `bib|cat|az` à l'écriture comme à la lecture.

**A257. LA SIDEBAR FILTRE, « RANGÉ PAR » LIT — un verbe par commande** (décision utilisateur,
sur captures : « les bibliothèques ne filtrent plus rien et les catégories de toutes les
bibliothèques sont mélangées »). Remplace la moitié « les bibliothèques EMMÈNENT » d'A250 —
c'était le mélange des deux verbes (le clic basculait même le rangement pour pouvoir défiler).
Désormais : **Bibliothèques** = « Toutes » (défaut, l'union d'A240 intacte) ou UNE — un filtre
de VUE (`state.homeLib` : null | '' Perso | id ; patron Finder), qui ne touche jamais ni au
rangement ni à l'ancien `scope` ; re-tap = retour à Toutes ; la file orpheline ne se filtre pas
(`key:null`). **Catégories** = celles du PÉRIMÈTRE choisi (fin du mélange), même cran que la
feuille. Comptes STABLES (visibilité seule, pas les filtres courants — un compte qui bouge sous
le geste se lit comme une erreur). Le filtre est COMPTÉ (`filtersCount`), ANNONCÉ (« filtres :
Perso · … ») et « Tout effacer » le lève — indispensable en voie étroite, où la sidebar n'existe
pas et où l'état serait sinon piégé. Le rôle « emmener » revient aux intertitres collants, au
« Rangé par » et au rail A–Z. Vérifié : filtre + catégorie s'empilent, le rangement retenu (A256)
ne bouge pas.

**A257a (finitions sur captures).** (1) À ≥ 1200 px, la phrase « Rangé par » vit SUR la ligne
RÉPERTOIRE (maquette Bureau : « Répertoire · Rangé par x · n éléments ») — « Accès direct »
s'intercalait entre elle et la liste qu'elle gouverne dès qu'une fiche était épinglée, et elle
paraissait déplacée ; sous 1200 (pas de tuiles, maquette Zero) elle garde sa ligne, déjà
adjacente. (2) ⌘K au bord droit du champ (`right:10px`) et EFFACÉ au focus ou dès qu'un texte
vit dans le champ (`:focus-within`/`:has(.srch-x:not([hidden]))`) : une invite, pas un meuble.
(3) « Sélectionner » aussi rejoint la ligne RÉPERTOIRE à ≥ 1200 (bord droit, son
`margin-left:auto` d'origine) — il restait seul sur une rangée devenue vide après le départ de
la phrase « Rangé par » ; la rangée `.grp-row` ne s'émet plus au bureau (`:empty` la masquait
déjà, ne pas l'émettre est plus honnête). UNE ligne de commandes : titre · rangement · comptes ·
sélection. Vérifié : entrée/sortie du mode sélection intactes.

**A258. OUVRIR ET FERMER UNE AIDE/RÉFÉRENCE SE FAIT SEC** (demande de l'auteur, 30/08/2026) :
le pilote View Transitions (fondu de vue .18 s, direction A lot 6) est PURGÉ — `vtWrap`, sa
garde et son CSS `::view-transition-*` : ses deux seuls sites étaient précisément l'ouverture
depuis l'accueil et le retour à l'accueil. Le retour de PILE garde son glissement (`_backAnim`,
`secInL`) : c'est un repère de navigation, pas un fondu. Au passage, le compte de « Toutes »
rejoint la colonne des comptes de bibliothèques (même coquille `hs-wrap` + entretoise que les
rangées à crayon — il filait au bord droit, signalé sur capture).

**A259. LA MARQUE ÉTROITE REDESCEND D'UN CRAN : 21 px, logo 30** (ressenti utilisateur,
30/08/2026 : « peut-être un peu trop gros » — la maquette Zero posait 23/32, appliqués 24/34).
Une seule valeur sous 780 px désormais : le repli ≤ 389 d'A253 (21 px) devient la règle et se
purge en tant que palier distinct ; le mot « Créer » garde son seuil 390. En voie large, rien
ne change (17,5 — l'en-tête y est du chrome).

**A260. L'ACCÈS DIRECT REVIENT EN ÉTROIT — remplace A245** (retour d'usage, 30/08/2026 : « les
épinglées ont disparu sur smartphone »). A245 pariait que l'étoile des rangées suffisait sous
1200 px ; à l'usage, des fiches épinglées enfouies dans l'ordre alphabétique de leur section ne
sont plus un accès direct — or l'épingle sert exactement ça, sous stress. Sous 1200 px,
« Accès direct » est une CARTE DE RANGÉES en tête de liste (le dessin v5.7 dans la coquille de
section v5.18 : intertitre collant dedans, `.pin-g`, 16 px d'air avant le répertoire) ; à
≥ 1200 les TUILES demeurent. Dans les deux cas, la fiche reste AUSSI à sa place dans le
répertoire — un raccourci ne déménage rien. Témoin doctrine réécrit dans les deux sens (rangées
présentes ET même largeur que le répertoire).

**A261. LES TUILES D'ACCÈS DIRECT À TOUTES LES LARGEURS — remplace A260** (décision utilisateur
sur capture, 30/08/2026 : « garder ce style sur smartphone et tablette, pour en mettre plusieurs
par ligne, tout en gérant bien les longs titres »). La carte de rangées d'A260 n'aura vécu
qu'une itération : sous 780 px la grille passe à `minmax(165px,1fr)` — DEUX tuiles par ligne dès
390 px — et le titre long gagne une 4e ligne à 13,5 px (l'ellipse reste la borne, la tuile ouvre
la fiche). Le masquage `zw1200` et `.pin-g` sont purgés. Témoins : tuiles présentes partout,
deux sur une ligne à ≤ 430, plafond de croissance 110 px (large, 3 lignes) / 132 (étroit, 4).

**A261a. LA LIGNE DE COMMANDES PARLE D'UNE SEULE VOIX : 12 px** (signalé : « pas de la même
taille »). RÉPERTOIRE/ACCÈS DIRECT (caps), « Rangé par » (13,5 → 12, c'était l'intrus), comptes
et « filtres : … » (11 → 12), « Sélectionner » (11 → 12) : un seul palier pour toute la ligne —
11 est le plancher, petit pour des boutons.

**A262. LA LISTE ÉDITORIALE REMPLACE LE TABLEAU — remplace A244** (direction A retenue sur le
canvas « Accueil épuré », 30/08/2026, après rejet des quatre retouches ponctuelles). Le tableau
≥ 1200 (rowT, en-tête de colonnes, grille 6 colonnes) est PURGÉ : ses colonnes répétaient ce que
le rangement disait déjà (9 × « CH Le Mans » sous l'intertitre CH Le Mans), et ses cases vides
s'écrivaient en tirets. UN SEUL dessin de rangée à toutes les largeurs — titre + ligne de méta
(nature · discriminant · catégorie · code · date seulement si elle existe) — le dessin déjà
validé en étroit : plus rien à réapprendre en changeant d'écran. `desk` (≥ 1200 hors sélection)
ne gouverne plus que la COMPOSITION : « Rangé par » et « Sélectionner » sur la ligne RÉPERTOIRE
(A257a), tuiles au-dessus (A261). Et au POINTEUR FIN, l'étoile ne vit qu'au survol de sa rangée
(ou au focus clavier) — onze étoiles creuses étaient du bruit ; l'épinglée reste pleine, le
tactile ne change pas (pas de survol). Opacité seule : peinture, boîte et cible intactes.

**A263. L'ORDRE DES BLOCS EST LE MÊME À TOUTES LES LARGEURS** (signalé après publication :
« pourquoi Rangé par apparaît au-dessus des épinglées, contrairement au bureau ? ») : tuiles
d'accès direct D'ABORD, puis les commandes, puis le répertoire. La rangée « Rangé par +
Sélectionner » s'émettait avant les tuiles en deçà de 1200 px — un vestige de l'ordre d'avant
A257a, jamais réaligné. En large, les commandes vivent SUR la ligne RÉPERTOIRE ; en étroit,
sur leur rangée juste au-dessus d'elle — mais toujours SOUS les épinglées : l'accès direct est
la première chose de la liste, à toutes les largeurs.

**A264. LE DOCK ÉPOUSE LE CLAVIER — sans constante, et la classe se pose vraiment** (signalé
sur iPhone après publication : « clavier ouvert, la barre de recherche est très moche » —
pilule flottant à ~130 px au-dessus du clavier, contenu nu dans l'entre-deux). DEUX racines :
(1) la garde v5.14.1 « champ dans l'en-tête → ne jamais poser `html.kbd` » datait d'avant
A249 — le champ vit désormais dans #homeDock, DANS l'en-tête : la classe ne se posait JAMAIS
sur la recherche d'accueil, et tout l'habillage clavier était mort ; la garde apprend le dock
(un champ de #homeDock POSE la classe — le dock gère sa propre géométrie), et l'en-tête
d'ACCUEIL est exempté du retrait `html.kbd` (il est statique — il défile —, et le cacher
détruirait le champ tapé : la spirale v5.14.1 exactement). (2) l'ancrage par CONSTANTE
(top = bas du viewport − 84/128 px) cassait dès que la géométrie réelle divergeait — remplacé
par `top:calc(--vvt + --vvh)` + `translateY(-100%)` : le bas du dock épouse EXACTEMENT le bas
du viewport visuel, quelle que soit sa hauteur (rangée de filtres comprise). Et clavier
ouvert, le dock devient OPAQUE avec un filet haut (A222) : le fondu est la robe du bas
d'écran, pas d'une barre ancrée au clavier. Mesuré : dockBas = vvBottom au pixel.

**A265. TROIS FINITIONS DU CLAVIER ET DE LA RESPIRATION (v5.18.2, sur iPhone réel).** (1) La
bande translucide sous la barre d'accessoires iOS (flèches + ✓) laissait voir les rangées :
la barre est au SYSTÈME (ni retirable ni mesurable — le viewport visuel s'arrête au-dessus
d'elle), mais le sol est à nous — un ::after opaque de 240 px sous le dock couvre tout
l'entre-deux (annonciateur A68/4, cliquet pointer-events monté à 21). (2) Taper la pilule
faisait défiler la page vers le bas : le défilement automatique d'iOS « amène en vue » un champ
FIXE qui se repositionne déjà seul (html.kbd) — en étroit sur l'accueil, preventDefault sur
pointerdown puis focus({preventScroll:true}) : même geste, zéro défilement. (3) L'écart
en-tête → « Accès direct » valait 34 px en étroit contre 18 en large (le rembourrage de main
s'ajoutait aux 16 du titre de section) : main passe à 2 px de rembourrage haut sur l'accueil
étroit — 18 partout, mesuré.

**A266. TROIS SUITES DU TERRAIN iPHONE (v5.18.3).** (1) **Défiler referme le clavier** (patron
iOS Mail/Safari) — suivre le viewport visuel PENDANT un défilement clavier-ouvert est
structurellement saccadé (les variables --vvt/--vvh sont sondées) : plutôt que courir, on
constate que l'utilisateur qui défile a fini de taper — blur de #q au premier défilement
(fenêtre + visualViewport, garde de 600 ms : l'ouverture du clavier émet ses propres
évènements). La barre « qui saute » et la bande « qui disparaît » partent AVEC le clavier,
proprement. (2) **Zone sûre du haut** : l'en-tête statique ne coiffe plus l'écran une fois
défilé — le bandeau de sélection et les intertitres collants passaient SOUS l'heure/batterie
en PWA installée, et le contenu défilait dans la bande de l'encoche. Un SOL fixe
(body.view-home::before, hauteur env(safe-area-inset-top)/­--zf — règle 10) couvre la bande,
et les deux collants s'arrêtent dessous ; inerte en navigateur (env = 0). Cliquet
pointer-events → 22. (3) **Le rythme sous l'en-tête est UN** : le titre « Résultats — … »
naissait à margin-top:0 (« très collé ») — 16 px comme les titres de section : 18 px sous
l'en-tête partout, recherche comprise, mesuré.

**A267. ON ÉCOUTE LE GESTE, JAMAIS L'ÉVÈNEMENT DE DÉFILEMENT** (signalé le jour même :
« si la page rétrécit pendant une recherche qui s'affine, le clavier disparaît ? »). A266
refermait le clavier sur `scroll` — mais une liste qui RACCOURCIT sous la frappe fait recaler
le défilement par le navigateur, qui émet `scroll` sans qu'aucun doigt n'ait bougé : le clavier
se fermait en pleine saisie, c'est-à-dire au pire moment. La garde de 600 ms n'y pouvait rien
(le cas arrive bien après). Seul un GLISSEMENT réel referme désormais : `touchmove` de plus de
10 px vertical, né HORS de #homeDock (dans le champ, le geste est celui du curseur ; dans la
rangée de crans, un défilement horizontal). Une remise en page n'émet jamais de touchmove.
Vérifié dans les deux sens : le focus TIENT sur un recalage programmatique, il PART sur un
glissement de 70 px. Leçon générale : pour distinguer « l'utilisateur a fait X » d'« il s'est
passé X », écouter l'entrée, pas la conséquence.

**A268. UN DÉFILEUR NE DOIT PAS ROGNER L'ANNEAU DE FOCUS** (v5.18.5, signalé sur captures :
« l'encadré de sélection des champs est coupé par la fenêtre »). Le corps des fenêtres
(`.ai-card>.ai-body`) ferme son axe horizontal depuis v5.10.5 — décision juste, gardée : un
champ y occupe TOUTE la largeur, donc son anneau (2 px + 2 px de décalage) tombait pile sur le
bord de découpe et se voyait amputé à gauche et à droite. Un état de focus amputé est un défaut
d'accessibilité, pas une coquetterie. On n'a PAS rouvert l'axe : le bord de découpe s'écarte de
4 px (`padding-inline:4px`) et ces 4 px sont rendus par une marge négative — le contenu ne bouge
pas d'un pixel (mesuré 423..857 avant et après), la découpe respire. `overflow-clip-margin` ne
pouvait pas servir : la propriété est ignorée sur un conteneur de défilement, ce qu'un
`overflow-y:auto` fait de l'élément. `scroll-padding-block:4px` fait le même office en HAUTEUR
(un champ atteint au clavier ne se colle plus au bord du scrollport). Trouvé en chemin et
corrigé : `.auth-why>summary` n'avait AUCUNE règle de focus — il rendait l'anneau par défaut du
navigateur, couleur hors palette, seul de sa famille dans ce cas.
