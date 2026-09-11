# Journal des modifications

## [5.29.4] — 2026-09-11
### La destination devient une pastille, les voies cessent de se superposer, et le papier se pagine avant d'être peint (A344)

- **Signalés à l'usage** : « il reste des soucis de superposition des flèches, et des flèches qui
  passent au-dessus des blocs » ; « les options à droite dans les blocs sont encadrées, contrairement
  à l'app » ; « le bout de la flèche n'est pas visible » ; « puis fais le paginateur mesuré ».
- **La destination est une pastille**, comme sur la maquette retenue : « CONTINUER ↓ 4 » au registre
  de la décision (cadre ambre plein), « ALLER À 7 » et « REVENIR À 2 » au registre des voies (cadre
  bleu pointillé, fond pâle), « ▪ FIN » reste un mot. Elle donne surtout au trait un bord d'où
  partir : une sortie part du bord droit de la pastille, un retour du bord gauche de la boîte — de la
  pastille il traversait le libellé de sa propre ligne (mesuré deux fois sur l'état de mal).
- **Un bus, pas n traits superposés** : trois décisions sortaient vers le même bloc et descendaient
  dans le même couloir, **615 px l'une sur l'autre**. Les lignes rejoignent le couloir par un tiret,
  la descente est unique. Toutes les voies passent par un registre de couloirs partagé (une abscisse
  prise glisse de 5 px), et le collecteur d'une fourche descend dans l'interstice de sa branche au
  lieu de longer la colonne des numéros. Une pointe s'arrête à 5 px du numéro, qui porte un halo et
  passait devant elle.
- **Le paginateur mesuré, et les voies reviennent sur le papier** : `svPaginate` pose lui-même les
  sauts de page, donc il les connaît — hauteur utile mesurée en millimètres, blocs insécables dans
  l'ordre du flux, saut avant celui qui déborderait. Les chemins s'écrivent en points, se coupent aux
  frontières et se décalent : un trait sort en bas d'une page et reprend en haut de la suivante, à la
  bonne cellule. Il peut renoncer et le dit (un bloc plus haut qu'une page), le calque restant alors
  masqué. Coût mesuré : l'état de mal passe de 3 à 4 pages, une fourche insécable laissant du blanc.
- **La feuille imprimée garde sa géométrie d'écran** et se centre dans les 210 mm : un padding
  différent décalait le calque de 28 px, et le couloir de droite passait sur le texte des cellules.
- **Témoin** (`audit-doctrine`) : aucun segment ne pénètre une cellule, un numéro, un intitulé, une
  pilule ou un texte de décision ; aucune superposition ; imprimer une aide imprime la Page ; le
  paginateur a posé ses pages ; l'écran retrouve son état. ⚠ Sa première écriture était **aveugle** —
  elle testait un recouvrement sur les deux axes alors qu'un segment a une épaisseur nulle, donc la
  condition ne pouvait jamais être vraie. Corrigée en testant l'appartenance, vérifiée capable
  d'échouer, elle a immédiatement trouvé deux vrais défauts.
- Doctrine A344 (trois addenda), index, `design/ds` régénéré, CHANGELOG à 20 ([5.24.2] archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.29.3] — 2026-09-11
### Les voies partent du bord de la boîte ; la feuille imprimée EST la page A4 (A344)

- **Signalé à l'usage** : « les flèches commencent encore à l'intérieur du bloc en superposant au
  texte et traversent des blocs », et « l'impression au format PDF rajoute des marges sur A4, quitte
  à ajuster la taille globale proportionnellement ».
- **Mesuré avant** (sonde : chaque segment du calque contre chaque cellule des deux fiches réelles) :
  **six croisements**, tous du même type — une ligne « SI … ALLER À n » occupe toute la largeur
  intérieure de sa boîte, donc partir de son bord droit, c'était partir sur le dernier mot et
  traverser la bordure, 27 px de trait dans la boîte. **Correctif** : une voie garde l'ordonnée de sa
  ligne et prend l'abscisse de sa BOÎTE. Et le collecteur d'une fourche descend désormais dans
  l'interstice de 12 px à gauche de sa branche, 14 px sous la source la plus basse (relevé au besoin
  pour passer sous une colonne sœur) — il descendait au bas de la fourche entière en longeant la
  colonne des numéros, soit un grand rectangle vide lu comme un trait à travers l'algorithme.
  **Mesuré après : zéro croisement.**
- **La feuille imprimée est la page** : `width:210mm` et un padding calculé
  (`calc((210mm - 710px) / 2)`) qui garde la zone de contenu à la largeur d'auteur au pixel près —
  sans quoi le contenu se refluerait. Les marges horizontales ne viennent plus de `@page`, qu'un
  moteur peut ignorer (WebKit) en ajoutant les siennes puis en réduisant la feuille pour l'y faire
  tenir, d'où une image plus petite entourée de blanc. Mesuré : colonne racine 670 px inchangée,
  texte de 11 à 198 mm sur 210, même nombre de pages selon que `@page` est respecté ou non.
- ⚠ **Les voies mesurées ne s'impriment plus, et c'est une question de justesse** : le calque est un
  élément absolu à l'échelle de la feuille, que la pagination coupe net alors qu'elle POUSSE le
  contenu. Mesuré sur l'ACR : le bloc visé descend de 37 à 64 mm sur sa page selon ce qui a été
  repoussé, pendant que la flèche reste où le flux non paginé l'avait mise — elle désigne le mauvais
  bloc. Rien n'est perdu : la ligne « SI … ALLER À n » et la pilule « ↺ revenir à n » sont la vérité
  textuelle depuis A134, et le dessin de structure (tronc, fourche, rail) vit dans le flux, donc il
  suit la pagination et reste juste.
- Doctrine A344 (deux addenda), index, `design/ds` régénéré, CHANGELOG à 20 ([5.24.1] archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.29.2] — 2026-09-11
### Impression : un intitulé de branche ne finit jamais une page seul (A344)

- Suite de la mesure page par page de v5.29.1 : une fourche plus haute qu'une page se déroule
  cellule par cellule comme le tronc (mesuré sur l'état de mal : coupe entre 13 et 14, le trait de
  la colonne reprend page suivante) ; restait le cas de l'intitulé « si ‹option› » en bas de page,
  sa première cellule partant page suivante — `break-after:avoid` sur l'intitulé, comme sur la
  décision. Une cellule plus haute qu'une page reste un problème de contenu (l'éditeur signale au-delà
  de 8 étapes) ; un paginateur mesuré ne s'écrira que sur une fiche réelle qui imprime mal.
- Doctrine A344 (addendum), CHANGELOG à 20 ([5.24.0] archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.29.1] — 2026-09-11
### « Exporter en PDF » imprime la Page (A344, impression)

- **Demande de l'auteur** : « vérifie que quand on clique sur imprimer cette aide ça imprime bien
  cette page — pas les historiques de sessions ». Mesuré avant : le gestionnaire d'impression
  forçait la vue d'ensemble (journal + plan Détails) depuis v4.18.0 ; session en cours, c'est le
  journal de cette session qui partait sur le papier, et le quai de session, fixé, se répétait au
  bas de chaque page.
- **Ce qui s'imprime est la Page** : cran Page forcé au moment d'imprimer pour toute aide à plus
  d'un bloc (une aide mono-bloc garde la vue d'ensemble dépliée), `body.print-page` masque tout ce
  qui n'est pas la feuille (titre d'écran, onglets, recherche, bulle, retour au bloc), le quai est
  masqué sans condition, la coque ne réclame plus une hauteur d'écran et la marge sous la feuille
  n'ouvre plus une page vide.
- **Mesuré page par page** (Chromium, A4, après le vrai `beforeprint`) : état de mal sur 3 pages,
  ACR sur 2 ; les voies mesurées restent alignées d'une page à l'autre (une sortie émise page 1 entre
  dans son bloc page 2). Une cellule et une décision ne se coupent jamais, la décision reste avec ce
  qui la suit, une fourche peut se couper entre deux cellules — la garder entière repoussait la
  moitié de l'algorithme à la page suivante en laissant une demi-page blanche. Ouvert : une fourche
  plus haute qu'une page.
- Doctrine A344 (addendum impression), index, CHANGELOG à 20 ([5.23.9] archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.29.0] — 2026-09-11
### La Page : l'arbre est le fil (A344)

- **Brief de l'auteur** : mieux voir les étapes, mieux voir sur smartphone, garder l'esprit « tout
  sur une page A4 ». Deux fiches réelles fournies pour mesurer les enjeux (arrêt cardiorespiratoire
  2026, état de mal tonico-clonique à quinze blocs), douze planches explorées sur un canevas, la
  douzième retenue : « super on part sur E12 », puis « ok implémente ».
- **Mesuré avant** : à 1130 px la grille à six pistes rendait l'état de mal sur 2 432 px et, ajustée
  à 390 px, tombait à 32 % (corps de 3,5 px) ; chaque décision de l'escalade rejouait une fourche
  pleine largeur dont une branche n'était qu'un renvoi ; la sortie commune portait le numéro 5 et
  « fin de l'algorithme » tombait au milieu de la feuille. À 11 px, une fiche à quinze blocs ne
  tient sur un A4 dans aucune composition : ce qui se garde de l'A4 est la largeur.
- **La composition est l'arbre.** Une colonne de largeur A4 (740 px), la référence en pied partout.
  Le NUMÉRO est l'ancre de tout trait (entrée par le haut, retour par la gauche) ; la colonne des
  numéros est la surface de dessin — tronc plein, fourche = barre + descentes, réunion = barre +
  entrée ; une sortie s'écrit « SI … ALLER À n » dans la décision et se trace en pointillé par la
  voie de droite ; un retour part du bout de la branche vers la voie de gauche (collecteur sous une
  fourche, tiret et ▲ vers un rail) ; deux branches à contenu = fourche côte à côte, au-delà = rail
  en retrait de 32 px avec une équerre par branche ; un trait ne croise jamais rien, sinon la ligne
  écrite suffit. Tronc, fourche et rail se dessinent en CSS à géométrie locale, sans mesure ; seules
  les voies se mesurent (`svPaintArrows`).
- **Les cellules, façon ECAM** : case · libellé · points de conduite · réponse attendue en mono à
  droite, ou sous le libellé quand elle ne tient pas sur la ligne de sa colonne. Registre par le
  glyphe et la couleur, ✓ dans la case, texte jamais barré. « ▪ fin de l'algorithme » dans le bloc
  terminal.
- **La numérotation suit le tronc** (`flowPlan`, partagée par le journal, le Parcours et le
  schéma) : les arêtes de retour ne comptent plus pour la post-dominance, la convergence d'une
  décision est le plus proche post-dominateur commun à deux options au moins, les options hors
  convergence sont des sorties chaînées après le tronc. État de mal : 1-12 puis 13 relais · 14
  surveillance · 15 récidive ; ACR : 4 FV · 5 asystolie · 6 causes · 7 RACS.
- **Mesuré après** (1280 × 900) : état de mal 740 × 2 992, ACR 740 × 1 839, les deux fiches d'exemple
  sur une page A4 (959 et 929 px) ; « Ajusté » à 390 px = 48 %. L'onglet s'appelle « Page ».
- `svTreePlan` (pure) remplace `svGridPlan`/`svDistribute` ; `.sv-fk`, `.sv-r`, les paliers d'écran
  de la feuille et la colonne de référence latérale sont purgés ; `@page{margin:10mm 7mm}` pour
  imprimer la feuille à sa largeur. Témoins : `tests.html` (svTreePlan, flowPlan sur graphe à
  boucle et sur sortie hors convergence), `audit-doctrine` (numéros alignés, aucune cellule sous
  260 px, même image aux trois largeurs ; deux témoins du Parcours suivent la nouvelle convergence).
  Doctrine `docs/decisions/lot-v5-29.md`, index, `design/ds` régénéré, CHANGELOG à 20 ([5.23.8]
  archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.28.4] — 2026-09-08
### La Page n'a qu'un axe vertical, dans la fenêtre « Tableau » comme dans la fiche (A343)

- **Signalé à l'usage** : depuis « Tableau » de l'écran de démarrage d'une aide (ou « Plein écran »
  du cran Toute la fiche), « le scroll vertical à l'intérieur de la page n'est pas bloqué et ça fait
  double scroll » — alors que dans la fiche et dans la feuille Consulter, l'axe est fermé.
- **La cause est une portée** : la règle tactile de la v5.10.5 (C87 — axe vertical fermé par
  `overflow-y:clip`, parce qu'un axe `auto` rebondit sur iOS même vide et capture le pouce) était
  bornée à `main`, « le plein écran garde son défileur ». Vrai du schéma, qui a le sien ; faux de la
  Page, rendue aussi dans la fenêtre « Tableau », qui défile elle-même. Dedans, la feuille
  gardait un second axe : un défileur dans le défileur.
- **Mesuré avant** (390 × 844, pointeur grossier, Chromium et WebKit) : `overflow-y: auto` dans la
  fenêtre, `hidden` dans la fiche. **Correctif** : la portée `main` est retirée pour `.sv-scroll`
  (ses deux sites de rendu vivent dans un défileur de page) ; `.flow-scroll` garde la sienne.
  **Mesuré après** : même axe fermé des deux côtés, l'échelle fait grandir la fenêtre et jamais un
  axe interne, le défilement horizontal des colonnes intact.
- **Témoin** (`audit-doctrine`) : ouvre par le vrai lien « Tableau », vérifie que le régime tactile
  est émulé, lit le style calculé des deux sites, exige que l'échelle grandisse la fenêtre. Vérifié
  capable d'échouer sur l'état d'avant.
- Doctrine A343 + addendum C87, index (`AGENTS.md`, `docs/README.md`), `design/ds` régénéré,
  CHANGELOG à 20 ([5.23.7] archivée).

## [5.28.3] — 2026-09-08
### Le dernier repère quitte le pied du moniteur et se pose sur la bande, à son instant (A342)

- **Demande de l'auteur** : « et si on mettait plutôt le dernier repère sur la timeline de manière
  générale ? ». Ça faisait sens pour une raison précise : la bande portait **déjà** un point par
  repère des deux dernières minutes, mais ils étaient **anonymes** ; le pied disait *quoi* et
  *quand* sans aucune position dans le temps. Deux objets pour un seul fait, chacun amputé de la
  moitié de l'autre.
- **L'échelle est le vrai problème, et elle se mesure** : la zone du passé fait 101 px pour 120 s,
  soit **1 px ≈ 1,2 s**. Quatre repères d'un ACR en 80 s tiennent dans 61 px quand une étiquette en
  fait 90 à 115 : deux repères qui se suivent ne peuvent jamais tenir côte à côte.
- **La règle : l'étiquette COMMENCE à son instant.** Son bord gauche est le moment, il n'y a donc
  aucun segment horizontal — et donc rien à croiser. Le plus récent occupe la rangée du **bas**,
  contre la bande ; les plus anciens montent. La propriété tient par construction, à n'importe quel
  nombre de repères : le trait d'un repère plus ancien est toujours à gauche des étiquettes des plus
  récents, qui commencent plus à droite que lui. (Le premier dessin alignait les étiquettes à
  gauche ; c'est ce segment horizontal qui fabriquait les croisements — l'auteur l'a vu.)
- **Ce qui n'est pas nommé est compté** : « **+ 3 repères avant** », la phrase que la bande dit déjà
  de l'autre côté (« + 1 minuteur plus tard »), retournée vers le passé. Écarté : « 4 gestes en
  1 min 20 » — *geste* est un second mot pour ce que l'app appelle partout un **repère**, et la
  durée est déjà dessinée par l'étalement des points.
- **Sept points de robustesse, tenus et mesurés** : le plus récent ne fusionne **jamais** (la
  fusion des points trop proches ne vaut plus que pour les muets) ; libellé borné à 18 signes ; le
  trait de rappel reste **1 px en encre douce** (2 px en encre pleine est le registre « daté ») ;
  les étiquettes ne dérivent pas l'une par rapport à l'autre ; **hors des −2 min**, demi-point au
  bord gauche et âge en toutes lettres, de sorte que le dernier repère existe toujours quelque part
  — c'est ce que le pied garantissait ; le nombre de noms est une **mesure** (`min(3, rangs)`, le
  budget des échéances : trois en portrait, un seul à 130 % en paysage) ; la bande apparaît dès
  **un** repère, puisqu'il n'a plus d'autre endroit où se dire.
- **Mesuré après, 20 configurations** (390×844, 320×568, 844×390 à 100 et 130 % ; rafale de quatre,
  un seul, deux, huit serrés, dernier hors fenêtre) : zéro croisement, zéro chevauchement, rien hors
  cadre, zéro recouvrement du grand chiffre, compte exact.
- **Témoin** « MONITEUR · le passé se nomme, et il tient en rafale » (12 combinaisons). ⚠ Un trait
  se glisse **sous** sa propre étiquette de 3 px — c'est le rattachement, pas un croisement : le
  contrôle ne compte que les traits qui traversent l'étiquette d'une AUTRE rangée (sa première
  version comptait les siens et rougissait sur un dessin juste). Vérifié capable d'échouer : l'ordre
  inversé donne 8 rouges. Témoins `monBandData` réécrits (trois nommés au plus, ce sont les plus
  récents, eux ne fusionnent jamais).
- **Purge** (règle 14) : `.mon-foot` / `#monFoot` — élément, CSS, rendu et lecture de hauteur — et
  `.mb-dot b`, le compte par point que la phrase remplace. L'afficheur regagne 46 px.
- Doctrine A342 dans `docs/decisions/lot-v5-28.md`, index `AGENTS.md` / `docs/README.md`,
  CHANGELOG à 20 ([5.23.6] archivée).
- Vérifié : `npm run check` complet, 1200 tests × 2 moteurs, audit COMPLET 29/29 après le numéro
  de version.

## [5.28.2] — 2026-09-08
### Fermer une photo garde la page où elle était, et le grand chiffre du moniteur ne recouvre plus la bande (A340-A341)

- **A340 — la photo, tout en bas d'un protocole.** Signalé : « fermeture photo sur protocole remet
  le scroll tout en haut », puis la précision décisive de l'auteur : *seulement page défilée tout en
  bas, par la croix ou par un tap hors image*. **Trente configurations de banc étaient vertes**
  (quatre portes de fermeture, deux moteurs, tactile et souris, zoom 100 et 130, `isMobile` posé
  pour que la garde `(pointer:coarse)` soit celle du téléphone) : le défaut n'existe que sur le vrai
  moteur. Mesuré sur iPhone (simulateur iOS 26.5, Safari réel, copie de banc instrumentée) : juste
  après la fermeture la position est **encore juste** (1886), et c'est **à la frame suivante** que
  WebKit repose la sienne — 0. La restauration de `_bgUnlock` n'était pas fausse, elle était trop
  tôt : tant que `html{overflow:hidden}` tient, le moteur garde une position à lui et la repose au
  layout suivant. Elle se repose donc aussi **après** le layout (deux frames), et seulement si la
  position a bougé — jamais contre un geste de l'utilisateur. Vaut pour **toutes** les fenêtres,
  pas seulement la photo. Prouvé sur l'appareil : +rAF, +100, +400, +900 ms → 1886.
- **A341 — le moniteur en paysage, texte agrandi.** Trouvé en mesurant, puis demandé : le grand
  chiffre **recouvrait la bande de 18 à 60 px** dès 130 % de taille de texte — ce qu'A232 avait
  fermé, rouvert par deux portes. (1) Le chrome de la bande était **estimé par des littéraux** justes
  à 100 % : 167 px rendus pour 90 estimés. Le plafond se prend désormais sur la bande **réellement
  rendue** — ce n'est pas circulaire, sa hauteur ne dépend jamais du chiffre — et le chrome mesuré
  sert au nombre de rangées du tic suivant. (2) Le plancher de 64 px était écrit en pixels de **mise
  en page**, donc il ne cédait jamais sous le réglage de taille du texte, qui est un `zoom`
  (règle 10) : il devient une taille **vue** (64 ÷ zoom), et sous elle le chiffre prend la place
  restante plutôt que de recouvrir la bande (A232 : « un chiffre recouvert ne se lit pas du tout »).
- **Ce que la mesure dit aussi** : à 844×390 avec le texte à 130 % et quatre minuteurs dont un en
  pause et un échu, l'afficheur a 300 px pour 388 px de contenu — **il manque 88 px**, et ils ne sont
  pas du côté du chiffre. Ce qu'il faudrait couper au-delà (pied, chrono de session, légende) est
  une décision d'auteur : elle n'est pas prise ici.
- **Témoins.** « PROTOCOLE · fermer une photo garde la page où elle était » **modèle** le moteur
  (un `requestAnimationFrame` repose 0 après la fermeture) — sans ce modèle, aucun banc ne voit le
  défaut ; deux portes, page tout en bas. « MONITEUR · la bande de temps tient à plusieurs
  minuteurs » gagne la dimension **zoom** (100 et 130 %, sept formats), vérifie le plancher en
  taille VUE, et sur un écran sur-souscrit ne s'exempte pas : il **borne** le recouvrement au manque
  mesuré. Les deux vérifiés capables d'échouer, `index.html` restauré à l'octet.
- Doctrine A340-A341 dans `docs/decisions/lot-v5-28.md`, index `AGENTS.md` / `docs/README.md`,
  CHANGELOG à 20 ([5.23.5] archivée).
- Vérifié : `npm run check` complet, 1196 tests × 2 moteurs, audit COMPLET 29/29 après le numéro
  de version.

## [5.28.1] — 2026-09-08
### Le parcours dit enfin sa profondeur : un retrait par niveau, dans les quatre régimes (A339)

- **Signalé à l'usage** : « parcours dans la page de démarrage d'une aide : indentation pas la
  bonne, notamment avec des blocs conditionnels hiérarchisés ». Reproduit et **mesuré avant
  correction**, sur une fiche à décision imbriquée.
- **Ce qui était faux.** Dans l'aperçu de l'écran de démarrage, les étiquettes de branche étaient
  toutes au MÊME retrait quel que soit leur niveau (« CHOQUABLE », profondeur 2, au même x que
  « OUI », profondeur 1) et le renvoi d'une branche sans rangée se posait à GAUCHE du tronc. En
  session, pire : les onze rangées de la colonne d'orientation à 10 px, étiquettes comprises —
  **aucun retrait du tout**.
- **La cause.** Quatre régimes écrivaient leurs retraits en ABSOLU (plan 24/32/48, colonne
  20/28/40, rail 16/28/40, aperçu à plat 18/32/40), et chacun pose aussi sa gouttière par un
  raccourci `padding` dont le sélecteur est plus spécifique : il remet `padding-left` à la
  gouttière, **où que soient écrites les règles de retrait**. Les trois retraits de l'aperçu à plat
  nés en v5.25.0 n'ont ainsi jamais rien fait.
- **Le correctif.** Le retrait devient un token ADDITIF (`--pl-ind` : 12 / 24 / 32 px, l'échelle
  déjà utilisée par la vue « Parcours »), ajouté à la gouttière de chaque régime
  (`calc(<gouttière> + var(--pl-ind,0px))`). Un raccourci ne peut plus l'effacer sans effacer aussi
  la gouttière ; l'alignement « la chip de branche sur le marqueur du bloc enfant » (v5.6) devient
  STRUCTUREL au lieu d'être recopié ; douze règles de retrait absolu disparaissent pour trois
  déclarations.
- **Mesuré après** : aperçu de démarrage 0/12/24, étiquette et rangée enfant au même x à chaque
  niveau ; session 10/22/34 ; le renvoi d'une branche suit sa branche. Aucune autre géométrie ne
  bouge (gouttières, hauteurs et corps inchangés).
- **Témoin** (`audit-doctrine`, « PARCOURS · le retrait dit la profondeur ») : fiche à décision
  imbriquée, retrait STRICTEMENT croissant avant et pendant la session, étiquettes comprises.
  Vérifié capable d'échouer (5 rouges sur l'état d'avant correctif). L'ancien témoin ne pouvait pas
  voir le défaut : il comparait l'étiquette à sa rangée — quand tout est à plat, elles sont
  alignées, et il était vert PARCE QUE la hiérarchie avait disparu.
- Doctrine A339 dans `docs/decisions/lot-v5-28.md`, index `AGENTS.md` / `docs/README.md`,
  `design/ds` régénéré, CHANGELOG à 20 ([5.23.4] archivée).
- Vérifié : `npm run check` complet, 1196 tests × 2 moteurs, audit COMPLET 29/29 après le numéro
  de version.

## [5.28.0] — 2026-09-08
### « Terminer la session » se trouve là où la session se lit, le menu ⋯ ne répète plus le dock, et la méta des cartes d'accueil dit un état en mots (A336-A338)

- **Demandes de l'auteur**, dessinées d'abord sur un canevas (quatre pistes, puis le menu, puis
  sept options de méta), validées avant tout code.
- **A336 — Terminer la session.** Une rangée « Terminer la session… — confirmation demandée »
  ferme le volet de session (étroit) et le rail d'état (large), sous un intertitre « Session ·
  depuis HH:MM ». Contour, jamais un aplat ; le tap ouvre la fenêtre « Terminer la session ? »,
  qui reste la SEULE porte. Jamais chez l'invité ni en aperçu. Un seul bouton permanent, pas de
  rappels ; formes refusées listées dans la doctrine.
- **A337 — Menu ⋯.** Trois natures de rangée de plus (`{head}`, `{tiles}`, `{fold}`) : les
  ouvertures (Moniteur, Se repérer, Schéma, Consulter hors session) en tuiles, des intertitres
  « Session » / « L'aide », le sous-titre SOUS le libellé sur une ligne (rangées 44 ou 52 px),
  largeur 300 px, la rangée danger en pied encadré. **En session le menu ne répète pas le dock** :
  Complication et Consulter en sortent (remplace la double entrée de v4.26.1) ; la gestion de
  l'aide se replie derrière « L'aide › ». 14 → 7 rangées en session. « Recommencer le parcours »
  n'existe qu'en session. Piège mesuré : le pli re-rend le menu, le clic remontait au document
  et le fermait (`stopPropagation`).
- **A338 — Méta des cartes d'accueil** (option J). À gauche l'identité : nature · discriminant ·
  ● catégorie ; à droite UN état en mots, le plus urgent : En cours 12:04 › Brouillon / À relire ›
  À compléter › Sans date › À revérifier 06/2023 › Validée 01/2025. Une taille, une graisse, aucun
  glyphe ni point, l'ambre pour ce qui attend. « Validé » n'apparaît plus qu'avec sa date ;
  le code sort de la rangée. Ligne de base alignée (écart 1 px mesuré) ; la catégorie s'abrège
  la première, le discriminant ensuite (plancher 4 em), jamais la nature ni l'état. Sous 360 px
  effectifs l'état passe sous l'identité, hauteur de rangée unique 76 px (320 : aucun
  débordement).
- Témoins adaptés : `audit-complications` (aucune rangée Complication en session),
  `audit-retour`, `audit-doctrine` (date lue dans `.dir-st`). Doctrine dans
  `docs/decisions/lot-v5-28.md` (nouveau), index AGENTS.md / docs/README.md, `design/ds/`
  régénéré. CHANGELOG à 20 ([5.23.3] archivée).
- Vérifié : `npm run check` complet, 1196 tests × 2 moteurs, audit COMPLET après le numéro de
  version.

## [5.27.1] — 2026-09-07
### La barre de retour colle au quai, et les deux retours portent l'icône (A335)

- **Demande de l'auteur** : rapprocher un peu la barre verte « retour au bloc » de la barre
  flottante, et remplacer les ↩ par une icône (barre et bouton « Reprendre » d'une complication).
- **Mesuré** : 8 px en navigateur — mais `#blkReturn` et `#dockSheet` ajoutaient
  `env(safe-area-inset-bottom)` à `--dock-h`, qui le contient déjà (hauteur mesurée du quai) :
  42 px sur un iPhone installé. Le terme en double est retiré des deux règles ; 8 px partout,
  prouvé à inset simulé (méthode A286).
- **Icône `backto`** (celle de « Un bloc ») sur la barre et sur « Reprendre — ‹bloc› → », dans
  le flux du texte pour rester collée au mot au passage à la ligne.
- **Deux finitions** vues à la capture : « Bloc Bloc 1 » (préfixe en double) et les tags
  « ⚡ complication » / « passage 1/2 » repris dans le libellé de la barre.
- **L'éclair aussi** (demande de l'auteur) : les quinze « ⚡ » emoji restants passent par la
  fabrique `boltIcon` ; classe `bolt`, seul glyphe REMPLI de la famille (`--bolt`/`--bolt-edge`,
  deux thèmes) pour ressortir autant que l'emoji qu'il remplace. Le sélecteur « renvoi du
  jalon » garde l'emoji dans ses `<option>` (pas de SVG possible, décision de l'auteur).
- Doctrine A335 dans `docs/decisions/lot-v5-27.md`, `design/ds/` régénéré. CHANGELOG à 20
  ([5.23.2] archivée).
- Vérifié : `npm run check` complet, 1196 tests × 2 moteurs, audit COMPLET après le numéro de
  version.

## [5.27.0] — 2026-09-07
### « Reprendre » revient sur l'étape interrompue, et la barre de retour ne survit plus à la fiche (A333-A334)

- **Reprise après complication (A333)** — signalé par l'auteur : « ouvre une nouvelle étape,
  devrait revenir vers l'ancienne et placer le bloc complication juste avant ; un bloc laissé
  ouvert, c'est perturbant ». Mesuré avant : trois passages pour un geste (l'ancien replié avec sa
  coche, la carte ⚡, un neuf vide). Désormais « ↩ Reprendre » RAMÈNE le passage interrompu au
  bout du journal — même visite, coches gardées, plus de « passage 1/2 » — et la carte ⚡ se range
  juste avant lui (`navRestore`, en place : `state.nav` reste l'alias de `Runtime.nav`). Ce
  choix RENVERSE A126 (« nouveau passage, cases neuves ») par décision de l'auteur — et le
  bouton l'a toujours dit : « ↩ Reprendre — ‹bloc› → » annonce un retour, pas un passage neuf ;
  le texte d'origine est barré dans `conventions-de-code.md`, pas effacé.
- **Ce que le réordonnement entraîne** : les replis, indexés par position, suivent leur visite
  (`ovFoldRemap`, rejoué aussi chez l'invité qui reçoit le fil) ; « l'entrée suivante du fil »
  saute les excursions (`navNextIdx`, pure) — sans cela une décision déjà répondue se rouvrait
  parce qu'une carte ⚡ s'était rangée entre elle et sa cible (mesuré : la décision reste une
  chip, sa réponse reste affichée, re-taper la réponse défile au lieu de reposter). Sans ancre
  ni passage à retrouver, l'ancien chemin reste (passage neuf) — jamais un journal cassé.
- **Barre « ↩ Bloc… » (A334)** — signalé : « apparaît sur la page d'accueil lorsqu'on termine la
  session et qu'elle est visible ; est-ce la seule situation ? » Non : mesuré aux quatre portes,
  « Terminer » la laissait pour toujours (le tick des minuteurs, seul à la resynchroniser,
  s'arrête avec la session) et le retour d'en-tête une seconde. `render()` la resynchronise à
  tout changement de vue.
- Garde-fous : `audit-complications` et `audit-doctrine` réécrits sur la nouvelle règle (même
  visite, coches gardées, une seule carte du bloc, ⚡ juste avant), un test unitaire
  (`instComplete` saute une excursion). Doctrine A333-A334 dans `docs/decisions/lot-v5-27.md`
  (nouveau fichier du lot), index AGENTS.md et docs/README.md. CHANGELOG à 20 ([5.23.1]
  archivée).
- Vérifié : `npm run check` complet, 1196 tests × 2 moteurs, audit COMPLET après le numéro de
  version.

## [5.26.5] — 2026-09-07
### « Hôte silencieux » : la phrase passe au registre neutre (A332, addendum)

- **Remarque de l'auteur** : « écran verrouillé, autre appli ou réseau, on ne sait pas » était
  un peu familier. La feuille dit désormais « (écran verrouillé, autre application ou réseau : la
  cause n'est pas connue) », puis ce qui est sûr — rien n'est perdu, ce que vous relevez lui
  parviendra, sa progression se mettra à jour à son retour ; sans réseau de son côté, recevez-la
  par l'écran. Info-bulle et sous-ligne de l'étape alignées.

## [5.26.4] — 2026-09-07
### « Hôte silencieux » ne dit plus la cause (A332, addendum)

- **Question de l'auteur** : et si le téléphone de l'hôte se met en veille ou passe sur une autre
  appli ? Alors l'hôte cesse de sonder et l'invité lit « Hôte silencieux » après 45 s — le fait
  est vrai (son miroir n'est plus rafraîchi), mais le texte accusait le réseau.
- **Ce qui change** : la cause ne s'affirme plus — « écran verrouillé, autre appli ou réseau, on
  ne sait pas » —, puis ce qui est sûr : rien n'est perdu, ce que l'invité relève parviendra, et
  la progression se remet à jour dès le retour de l'hôte. « Recevoir par l'écran » n'est proposé
  que s'il n'a plus de réseau. Le seuil reste 45 s : l'app tient un verrou de veille pendant toute
  session vive, l'écran de l'hôte ne s'éteint pas seul.

## [5.26.3] — 2026-09-07
### La bouée de bascule, et l'invité que rien n'atteint (A332, addendum)

- **Questions de l'auteur** : « et si pas de retour de l'hôte ? une bouée envoyée lors du passage
  de l'hôte en direct pour forcer les autres ? » ; « quid si un invité n'est pas sur le même
  réseau ? » ; « quid de la reprise en ligne après perte totale réseau et Wi-Fi ? ».
- **La bouée** : à sa bascule en direct, l'hôte le crie sur chaque canal dormant — le relais est
  mort pour lui, mais le canal vit. L'invité qui la reçoit suit en direct même si son propre relais
  répond encore, son billet cloud gardé ; au retour de l'hôte, il repasse en ligne seul. Avant, un
  invité dont le relais répondait restait sur un partage que plus personne n'alimentait.
- **L'invité hors du réseau commun**, que ni le direct ni la bouée n'atteignent, lit désormais
  « △ Hôte silencieux · ① Recevoir » dans le quai au-delà de 45 s sans nouvelles de l'hôte, et sa
  feuille dit ce qui reste vrai : ses gestes arrivent au journal et l'hôte les lira à son retour ;
  sa progression à lui se reçoit par l'écran. Rien n'est jugé : une heure recopiée, effacée dès que
  l'hôte reparle. Ses coches ne sont pas suspendues.
- **Reprise après perte totale** : mesurée dans les trois cas (canal mort à la coupure, canal
  survivant quelques secondes, rechargement pendant la panne) — même partage repris des deux côtés,
  gestes de l'hôte gardés ; un partage expiré pendant une longue coupure dit « Se reconnecter ».
- **Garde-fous** : section « hôte seul » réécrite autour de la bouée, section « invité hors du
  réseau commun » (9 contrôles au total), vérifiées capables d'échouer sur le code d'avant.

## [5.26.2] — 2026-09-07
### Ce que la panne fait aux gestes du partage (A332)

- **Signalé par l'auteur** : « arrêté depuis » n'apparaissait que chez celui qui avait arrêté le
  minuteur ; que se passe-t-il quand un participant perd internet mais garde le Wi-Fi, ou perd
  les deux ; et « quand les deux appareils passent hors ligne, l'invité ne peut plus rien cocher,
  puis au retour en ligne chacun avance de son côté ». Tout a été MESURÉ au banc avant de corriger
  (carte des situations dans la doctrine).
- **Le minuteur arrêté est daté chez l'autre** : l'arrêt reçu prend l'heure de l'évènement (jamais
  une clé de charge nouvelle — la liste blanche serveur est intacte), l'armement l'efface ; à la
  jointure et par l'écran aussi. Avant, l'autre écran n'avait rien, ou gardait la date de son
  propre arrêt précédent.
- **L'hôte ne perd plus ses gestes faits pendant une panne** : lien figé, une coche de l'hôte
  n'entrait pas dans la file (refusée pour péremption après que la base de comparaison avait
  avancé) et n'atteignait jamais le journal ni l'invité. L'hôte n'est plus jamais refusé pour
  péremption : la file persistée porte ses gestes au retour.
- **Panne côté hôte seul** (portail captif de l'hôte, invités qui gardent internet) : l'hôte
  basculait en direct sans qu'aucun invité le suive, puis restait en direct pour toujours au retour
  du réseau — chacun avançait de son côté. Il revient désormais seul sur le MÊME partage par son
  billet, même sans invité sur son hub, et les invités restés en ligne rattrapent ses gestes.
- **La reprise de l'invité repeint l'écran** : revenu seul après une panne, il reconstruisait son
  état sans le montrer et gardait l'écran d'avant la coupure. Le journal est rejoué par la voie
  vivante.
- **Le bridage de l'invité périmé se voit** : ses coches restent suspendues tant que le lien est
  figé (décision gardée : elles ne remontent pas par l'écran), mais les contrôles le montrent
  désormais, et la feuille comme le bandeau disent que seuls ses repères datés (« Noter l'heure »)
  repartent.
- **Garde-fous** : 4 tests unitaires (date d'arrêt = heure de l'évènement, aucune clé de charge
  nouvelle, pli optique), 2 sections d'`audit-partage` (9 contrôles), vérifiées capables d'échouer
  (6 rouges sur le code d'avant).

## [5.26.1] — 2026-09-06
### Les anneaux seuls, un temps après l'affichage (A331, addendum)

- **Demande de l'auteur** : plus de relèvement du quai à l'arrivée, seulement les trois anneaux —
  et qu'ils partent un peu après l'affichage de la page, pas d'emblée.
- **Ce qui change** : le premier anneau part à 800 ms, puis 2,1 s et 3,4 s ; tout est fini à
  4,7 s, toujours sous les 5 s. Le quai est simplement là, immobile, dès l'ouverture. Le
  `@keyframes` du relèvement est purgé.

## [5.26.0] — 2026-09-06
### Il reste un geste après avoir ouvert une carte, et le quai le dit (A331)

- **Demande de l'auteur** : attirer l'attention sur le fait qu'après avoir ouvert une aide, il
  faut encore démarrer la session — sans fondu en boucle (WCAG 2.2.2). Maquettes et démonstration
  rejouable validées sur canvas ; les formes refusées sont consignées dans la doctrine.
- **L'arrivée du quai** : à l'ouverture d'une fiche, avant la session, la capsule se relève une
  fois (14 px, 280 ms) puis trois anneaux s'en éloignent de 12 px et s'effacent, à 0,9, 2,2 et
  3,5 s — tout est fini à 4,8 s, rien ne boucle. L'anneau entoure la capsule entière, jamais le
  bouton seul : il ne touche ni la touche Exercice ni le bouton. Sombre le jour, clair la nuit ;
  nul sous « réduire les animations » ; jamais rejoué tant qu'on reste sur la fiche.
- **La bulle d'apprentissage**, 16 px au-dessus du quai, pointée sur le bouton : « Rien n'est
  lancé tant que vous consultez. Étapes, minuteurs, partage : "Démarrer la session". » Elle reste
  tant qu'aucune session n'a été démarrée sur l'appareil, puis disparaît pour de bon. La réserve
  de bas de page suit sa hauteur.
- **« Exo. »** : sous 430 px la touche Exercice garde un mot tronqué au lieu de perdre son libellé.
- **Garde-fous** : cliquet `pointer-events:none` de `check-anim` monté à 23 (l'anneau est un
  annonciateur pur). Doctrine A331 dans `docs/decisions/lot-v5-26.md`, index mis à jour.

## [5.25.1] — 2026-09-06
### La carte « Quand l'utiliser » respire pareil en haut et en bas (A330, addendum)

- **Signalé sur main** : sans diagnostic différentiel, le cadre « Quand l'utiliser » avait moins de
  respiration sous le dernier critère qu'au-dessus du premier (mesuré à 390 px : 15 px contre 4).
  Depuis que le titre vit au-dessus du cadre (v5.25.0), seul le lien « Le tableau ne colle pas ? »
  fermait la carte — et il n'existe que si la fiche déclare des différentiels.
- **Correction** : la carte porte 6 px en haut et en bas, la liste 4/4 ; le lien de sortie, quand
  il existe, reprend les 6 px du bas pour rester au ras du cadre. Mesuré après : 15/15 sans lien,
  lien au ras avec, hauteur de carte inchangée dans ce cas.

## [5.25.0] — 2026-09-06
### L'écran d'entrée d'une aide se lit comme un écran de démarrage (A330)

- **Demande de l'auteur** : « comprendre que c'est juste un écran de démarrage, que l'action se
  situe après ; le plan n'est qu'un plan ». Mesuré avant : « Prise en charge » en titre, des
  rangées blanches numérotées qui invitent au tap, des compteurs « 0/4 », et le seul mot qui disait
  le contraire — « inerte » — à 11 px gris clair. Maquettes itérées sur canvas.
- **Trois chapitres de même niveau, sans numéro** : les intitulés qui existaient sortent de leurs
  cadres — « ■ Quand l'utiliser », « ■ Ne pas oublier », « Parcours » (sous-ligne « Aperçu — se
  déroule après le démarrage ») —, un filet et un blanc ouvrent chacun. En session, rien ne change.
- **Le plan est un aperçu à plat** : ni carte, ni pastille, ni « 0/4 » ; numéros, titres et renvois
  gris ; la rangée de décision se tait quand ses branches sont étiquetées ; rangées de 32 px,
  toujours dépliables. « Surveiller ensuite » reste au rail. Tableau et Schéma vivent sous le titre
  « Parcours », à largeur de contenu, alignés à gauche.
- **Rien ne démarre sauf le chrono** (correction de l'auteur) : le rail « Ce qui démarrera » devient
  « En session » (« démarre avec la session » / « 2:00 cyclique, à lancer ») ; sur téléphone,
  « Minuteurs à disposition en session : Cycle RCP 2:00 · Adrénaline 4:00. » remplace la ligne
  « 5 blocs · 2 minuteurs · … ».
- **Le sur-titre dit l'état** : « Avant la session · adulte », encre neutre, dans le logement que
  « ■ Mode crise » prend au premier geste. Cockpit : même grammaire dans la colonne de gauche, sans
  « ICI ». Notes locales, note personnelle et pied passent en queue sous un filet ; la porte « Le
  tableau ne colle pas ? » à l'encre normale.
- **Garde-fous** : témoins d'audit-doctrine réalignés (boutons sous « Parcours » et au-dessus de
  l'aperçu, zéro « Prise en charge » avant la session), tests Q4 réécrits, `.conf-eh` purgé avec
  épitaphe. Doctrine A330 dans `docs/decisions/lot-v5-25.md` ; formes refusées consignées.
