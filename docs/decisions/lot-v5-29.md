# Lot v5.29 — la Page : l'arbre EST le fil (A344)

> Fichier normatif, suite de [`lot-v5-28.md`](lot-v5-28.md) (A336-A343). Les numéros A sont des
> adresses : ne jamais renuméroter. Brief de l'auteur (09/09/2026) : « redesign de la Page —
> améliorer la visualisation des étapes, la visualisation sur smartphone, en gardant l'esprit de
> tout afficher sur une page A4 imprimable » ; puis deux fiches réelles fournies « pour se rendre
> compte des enjeux » (arrêt cardiorespiratoire 2026 : 7 blocs, une fourche, une boucle, une
> sortie ; état de mal tonico-clonique : 15 blocs, cinq décisions sur quatre niveaux, une sortie
> commune). Douze planches explorées sur un canevas (E1 à E12), E12 retenue le 11/09/2026 : « super
> on part sur E12 », puis « ok implémente ».

## A344 — l'arbre est le fil : la feuille dessine sa structure dans la colonne des numéros

**CE QUI N'ALLAIT PAS, MESURÉ SUR LES DEUX FICHES RÉELLES.** À 1130 px, la grille à six pistes
(A134) rendait l'état de mal sur 2 432 px (2,2 A4) et l'ACR sur 1 227 px ; ajustée à 390 px, la
feuille tombait à 32 %, soit un corps de 3,5 px. Surtout, **le déroulement se perdait** : chaque
décision de l'escalade rejouait une fourche pleine largeur dont une branche n'était qu'un renvoi ;
la sortie commune « convulsions arrêtées » portait le numéro 5 et « fin de l'algorithme » tombait au
milieu de la feuille, alors qu'il restait dix blocs — « ça ne va pas : la fin ne peut pas être
affichée alors qu'après il y a encore des blocs ; on perd toujours le déroulement en cas de blocs
imbriqués ». Et une fiche à 15 blocs, à 11 px (règle 9), ne tient sur UN A4 dans aucune
composition : ce qui se garde de l'esprit A4 est la LARGEUR ; la hauteur suit.

**LA COMPOSITION EST L'ARBRE.** Plus de dessin à côté du contenu (E11, un arbre en tête, a été
refusé : « non, intégré dans le fil ») : ce qui descend est le tronc, ce qui est côte à côte est une
fourche, ce qui est en retrait est une branche d'un rail, ce qui part à droite est une sortie. Une
seule colonne de largeur A4 (`--sheet-w` 740 px = 210 mm à 7 mm de marge), la référence en pied, et
**le numéro est l'ancre de tout trait** — cinq règles, dont TOUT le tracé découle :

1. **Le numéro est l'ancre.** Tout trait part d'un numéro ou y entre : par le HAUT quand on continue
   ou qu'on arrive, par la GAUCHE quand on revient. Jamais dans une cellule, jamais sur un texte.
2. **La colonne des numéros est la surface de dessin** (28 px, même x dans chaque colonne). Le tronc
   y est un trait plein entre numéros qui se suivent ; une fourche = une barre sous la décision et
   une descente par branche ; une réunion = une barre et une entrée par le haut du bloc commun. Les
   cellules ne sont jamais traversées.
3. **Une sortie s'écrit** sur la ligne « SI … ALLER À n » de la décision et se trace en pointillé
   bleu : bord droit de la ligne → voie de droite → barre au-dessus du bloc cible → haut de son
   numéro. Quand la cible ouvre une colonne de fourche, la sortie rejoint la barre de la fourche —
   une seule entrée par numéro.
4. **Un retour part du bout de la branche** (« ↺ revenir à n », ou la ligne « SI … REVENIR À n »)
   vers la voie de gauche, remonte, et entre par la GAUCHE du numéro. Deux branches qui reviennent
   au même bloc se réunissent d'abord sur un COLLECTEUR sous la fourche. Depuis une branche de rail,
   le retour rejoint le rail par un tiret et un ▲ : elle « remonte ».
5. **Deux branches à contenu = fourche côte à côte**, à pleine largeur seulement (330 px par
   colonne). Au-delà de deux — ou dans une colonne déjà partagée —, les branches se posent l'une
   sous l'autre en retrait de 32 px, coiffées de « si ‹option› », et la colonne de la décision
   devient un **RAIL** : trait plein qui descend, une ÉQUERRE entrant dans le premier numéro de
   chacune ; les fins de branche « ↓ continuer n » rejoignent le bloc commun par la voie intérieure
   de droite. Mesuré : trois colonnes feraient 225 px, quatre 166 px — plus une ligne « libellé ……
   réponse » n'y tient.

Une **branche qui n'est qu'un renvoi n'ouvre jamais de fourche** : elle est une ligne de la décision.
**Une seule branche à contenu = la suite du tronc**, dans la même colonne, sans pilule (le trait
suffit). Et **un trait n'est tracé que s'il ne croise rien** ; sinon la ligne écrite suffit — la
pilule et la ligne « SI » restent la vérité, le dessin un rappel de trajet (c'est ce qui a coulé
E5, un rail de trajets superposés : « je ne comprends absolument rien aux flèches »).

**LA DÉCISION CONTIENT SES ALTERNATIVES (QRH).** Titre, question, jalons, puis une ligne par option :
« SI Choquable ……… CONTINUER ↓ 4 », « SI RACS ……… ALLER À 7 », « SI Récidive ……… REVENIR À 2 »,
« ▪ FIN ». Les étiquettes de branche `.sv-opt` d'A134 disparaissent ; les lignes ne sont pas des
cibles (la boîte l'est), les pilules « ↺ / ↓ / → » restent des boutons de 32 px + halo.

**LES CELLULES, FAÇON ECAM.** Une ligne par étape : case à cocher · libellé · points de conduite ·
RÉPONSE ATTENDUE en mono à droite (« Choc immédiat …… puis reprise RCP 2 min ») ; quand elle ne
tient pas sur la ligne de sa colonne, la réponse passe SOUS le libellé, alignée à gauche — décidé
au rendu sur la largeur utile de la colonne (`svStepsHtml(list, cw)`), jamais mesuré. Filet fin
entre les lignes ; registre par le glyphe ET la couleur (⚠ rouge, △ ambre, la case prend la bordure
du registre) ; coché = ✓ vert dans la case, texte en encre douce, jamais barré. La pilule `.sv-r`
est purgée. Coût mesuré sur la maquette : +8 % de hauteur ; le bloc terminal porte « ▪ fin de
l'algorithme » DANS sa cellule (jamais en pied de feuille, jamais avant un bloc restant).

**LA NUMÉROTATION SUIT LE TRONC — décision d'app, partagée par le journal, le Parcours et le schéma
(`flowPlan`).** Sur un graphe qui reboucle (récidive → reprise au 2), tout chemin repasse par le
tronc : le post-dominateur d'une décision devenait la PREMIÈRE étape de l'escalade, et « relais et
orientation » — la sortie commune — était numéroté 5, avant l'escalade 6-15. Deux changements dans
`flowPlan` : (a) **les arêtes de retour** (DFS dans l'ordre des options) **valent une sortie pour la
post-dominance**, et rien d'autre ; (b) **la convergence d'une décision est le plus PROCHE
post-dominateur commun à au moins DEUX de ses options** — une option qui n'y passe pas est une
SORTIE, écrite sur la décision et chaînée APRÈS le tronc (« RACS → 7 » après la boucle des 2 min),
jamais parmi les branches. Résultat : état de mal 1-12 puis 13 relais · 14 surveillance · 15
récidive ; ACR 4 FV · 5 asystolie · 6 causes · 7 RACS. Et « ↺ » ou « → » se décide sur le NUMÉRO
(`idx[to] < idx[from]`), plus sur l'ordre de visite : une sortie peut mener à un bloc déjà visité
mais numéroté plus loin. Témoins purs dans `tests.html` (les deux cas ci-dessus, en petit).

**CE QUI SE DESSINE EN CSS ET CE QUI SE MESURE.** Tronc, fourche et rail sont des pseudo-éléments à
géométrie LOCALE (le segment d'une rangée va de son numéro, top 32, au numéro de la suivante, bottom
−12 : 8 d'écart + 4 ; la descente d'une fourche va de la barre au premier numéro, 38 px : intitulé
20 + 6 + 4) — rien n'est mesuré, donc rien ne se décale à l'impression. Seules les VOIES (sorties,
retours, réunions d'un rail) se mesurent dans `svPaintArrows`, avec les précautions d'A134 (÷ zoomF,
÷ échelle, calque DANS la feuille, une passe groupée). A134 refusait le SVG parce qu'un viewBox
déclaré ≠ boîte réelle avait déformé deux fois ; le calque de gouttière d'A134 en avait déjà réglé
la recette (viewBox = taille de la feuille), et c'est elle qui sert. **`svTreePlan` est PURE** (fiche
+ flowPlan → colonnes, rangées, arêtes ; ids et jamais d'objets croisés — un plan sérialisable est
un plan testable) ; `svGridPlan`, `svDistribute`, `SV_TRACKS/SV_TRUNK` sont purgés (règle 14, grep :
`.sv-fk`, `.fk-*`, `.sv-r`, `.sv-band-body.solo` et les paliers d'écran de la feuille partent avec).

**CE QUI NE CHANGE PAS.** L'inertie (aucun `data-ck`, taper une cellule = `svJump`) ; l'ordre du DOM
(cartouche · entrée · algorithme · référence · doses, le même aux trois largeurs — la référence est
en pied PARTOUT désormais, plus seulement sous 1000 px) ; la largeur d'auteur et l'échelle par
`scale` (A133) ; 44 px de cible sur tout ce qui se tape ; l'avertissement de validation ; « ⤢
Ajusté » = un tap, jamais mémorisé (48 % à 390 px, contre 32 % avant).

**IMPRESSION (v5.29.1).** « Exporter en PDF » imprime LA PAGE — demande de l'auteur : « vérifie que
quand on clique sur imprimer cette aide ça imprime bien cette page, pas les historiques de
sessions ». Depuis v4.18.0 le gestionnaire `beforeprint` FORÇAIT la vue d'ensemble (journal + plan
Détails) : avec une session en cours, c'est le journal de cette session qui partait sur le papier.
Il force désormais le cran Page (`readMode='static'`, `allTab='page'`, `body.print-page`) pour toute
aide à plus d'un bloc ; une aide mono-bloc garde la vue d'ensemble dépliée. `body.print-page` masque
tout ce qui n'est pas la feuille (titre d'écran, onglets, recherche, bulle, retour au bloc) ; le quai
`#sessionDock` est FIXÉ, donc il se répétait au bas de chaque page — masqué sans condition ; `.app`
exigeait une hauteur d'écran, donc une page vide grise en fin de document — hauteur libre sur papier.
La feuille GARDE sa largeur d'auteur (`@page{margin:10mm 7mm}` : A4 portrait = 741 px utiles pour
740). **Mesuré page par page** (Chromium, `page.pdf` A4 après le vrai `beforeprint`) : l'état de mal
tient sur 3 pages, l'ACR sur 2 ; les voies mesurées restent ALIGNÉES d'une page à l'autre — le moteur
fragmente le calque absolu avec la feuille, une sortie « aller à 13 » émise page 1 entre dans le 13
page 2. Ce qui se coupe et ce qui ne se coupe pas : une cellule et une décision jamais
(`break-inside:avoid`), la décision reste avec ce qui la suit (`break-after:avoid`), une FOURCHE peut
se couper entre deux cellules — la garder entière repoussait la moitié de l'algorithme à la page
suivante en laissant une demi-page blanche. Ce qui reste vrai d'A138 : l'état de session ne s'imprime
pas. Ouvert : une fourche plus haute qu'une page.

**MESURÉ APRÈS** (Chromium, 1280 × 900) : état de mal 740 × 2 992, ACR 740 × 1 839, les deux fiches
d'exemple sur 959 et 929 px — c'est-à-dire UNE page A4 pour les fiches de cette taille, l'esprit du
brief ; « Ajusté » à 390 px = 48 %. Formes REFUSÉES par l'auteur pendant l'exploration, à ne pas
reproposer : escalier + couloir de sortie (E1, casse sur deux branches à contenu) ; rail de trajets
en gouttière (E5, flèches superposées) ; ligne de temps (E6, délais EXTRAPOLÉS du texte des questions
— faisable seulement avec un `timerId` sur la décision) ; escalier à marches (E8, « à quel moment on
bifurque ? ») ; arbre séparé en tête (E11).
