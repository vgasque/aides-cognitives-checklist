# Lot v5.22 — le gestionnaire de catégories en liste, le rail de session à 280 px sur tablette (A308-A310)

> Fichier normatif, suite de [`lot-v5-21.md`](lot-v5-21.md) (A297-A307). Les numéros A sont des
> adresses : ne jamais renuméroter.

## A308 — une palette à la fois, « Ajouter » en tête, un curseur de teinte ; le rail de session à 280 px entre 780 et 999 (v5.22.0)

**Demande de l'auteur** (revue design du 04/09/2026, canvas « Catégories et rail tablette ») :
améliorer « Gérer les catégories », permettre plus de couleurs, et juger la colonne droite d'une
session sur tablette en portrait.

**Mesuré avant de décider** (app servie, Chromium, 820 × 1180) :

- la fenêtre répétait la palette sous CHAQUE catégorie — 104 pastilles pour 8 catégories, rangées
  de 140 px, fenêtre de 1 144 px, et le champ « Ajouter », seule action de création, à 1 298 px sous
  le haut, donc hors écran ;
- en session, la grille 780-1199 donnait 444 px à la colonne d'action et 320 au rail (41 % de la
  largeur) : la colonne lue sous stress avait la largeur d'un téléphone, et le rail laissait sa
  moitié basse vide. À 1024 px (648 / 320, 32 %), rien à redire.

**Ce qui change.**

1. **Gestionnaire en liste** : « Ajouter » en tête de chaque section, rangées de 44 px (pastille ·
   nom · compte · ×), plus de cartes bordées. La palette ne s'ouvre que pour la catégorie dont on
   tape la pastille (`catPickKey`, une seule rangée `.open` à la fois), le focus revient sur la
   pastille après re-rendu (A236). Huit catégories tiennent en 715 px, « Ajouter » visible sans
   défiler. Les portes ne changent pas : accueil, feuille « Gérer », atelier d'import ET les deux
   éditeurs (« ＋ Nouvelle catégorie » du menu Catégorie) ouvrent la même fenêtre `#catModal`
   — vérifié au témoin sur l'éditeur de fiche et celui de protocole.
2. **Plus de couleurs, sans toucher au modèle** : `safeColor` accepte déjà tout hex et la synchro
   le transporte tel quel. Le curseur « Autre teinte » parcourt l'anneau OKLCH **L 0,48 · C 0,08**
   — la chroma MAXIMALE qui reste dans le gamut sRGB sur tout le tour (0,081, limitée vers 195°) ;
   à 0,10, le cyan s'écrêtait et l'aller-retour hex → OKLCH sortait de l'anneau (rouge attrapé par
   le témoin, corrigé avant livraison). Sur les 360 degrés : blanc sur teinte pleine ≥ 6,2, teinte
   sur fond à 15 % ≥ 5,0 — les deux contraintes de la régression #3 tiennent PAR CONSTRUCTION.
   Conversion maison (Ottosson), aucune dépendance ; le dégradé du curseur est calculé en JS et posé
   en style inline (aucune couleur littérale dans la feuille, `check-colors` inchangé). Aperçu en
   direct (pastille teintée, chip pleine) et un garde-fou de PROXIMITÉ : « △ proche de « X » » sous
   4,0 ΔE OKLab d'une catégorie du même périmètre — on avertit, on n'interdit pas ; un hex importé
   illisible est dit « △ contraste faible » (`catLisible`). Ce qui n'est pas fait, et pourquoi :
   pas de second anneau plus clair (le texte blanc du chip tomberait sous 4,5), pas de saisie hex
   libre (contraste non garanti). Les presets restent les treize de J1, inchangés.
3. **Rail 280 px entre 780 et 999**, 320 dès 1000 (palier déjà déclaré, aucune addition à l'échelle).
   Rendu mesuré à 280 : cartes minuteur 261 px, repères posologiques même hauteur, aucun
   débordement nouveau. Gain honnête : +40 px pour l'action (9 %). L'épitaphe de `.pg-wide` reste
   vraie — c'est un palier, pas un geste en session.

**Garde-fous** : `tests.html` § « anneau de teinte (A308) » (8 témoins : contrastes sur 120
teintes, `catLisible`, aller-retour, plancher 4,0 entre presets) ; `audit-doctrine` § « Catégories ·
une palette à la fois, Ajouter en tête, même fenêtre depuis les éditeurs » (10 contrôles, 96 → 97
sections), vérifié CAPABLE D'ÉCHOUER (palette forcée ouverte → 3 rouges sur les bonnes assertions,
`index.html` restauré à l'octet).

## A309 — dans le rail, les deux ajouts sur une rangée sous les compteurs (v5.22.1)

**Demande de l'auteur** (04/09/2026, variante A du canvas « Catégories et rail tablette »). En
session, le rail portait « ＋ Minuteur » sous le minuteur puis « ＋ Compteur » sous le compteur,
deux boutons pointillés pleine largeur de 44 px, soit ≈ 118 px avec leurs marges au milieu de la
colonne d'état — à 820 px, là où le rail coûte le plus à la colonne d'action.

**Ce que ce n'est pas** : une rétrogradation. Ces boutons créent un minuteur ad hoc et un compteur
créé à 1 — des gestes DE SESSION, pas de l'édition ; ils gardent 44 px (règle 9) et restent visibles
sans tap supplémentaire. La variante B (« ＋ Ajouter… » qui ouvre un choix) a été écartée pour son
tap de plus en crise.

**Ce qui change** : dans le rail seulement (`mqRail`), les deux boutons partagent UNE rangée
`.rt-adds` placée après les compteurs — même famille de geste (cf. le commentaire de `cnAddHtml`),
gain ≈ 54 px. Le choix de durée (`.tm-add-d`) s'ouvre SOUS la rangée : `tmAddHtml` se scinde en
`tmAddBtn` + `tmAddDur`, et le volet étroit reste inchangé — « ＋ Minuteur » y demeure dans sa
famille (décision v5.4.1, qui vaut toujours là où la colonne ne coûte rien).

**Garde-fou** : `audit-doctrine` § « RAIL · les deux ajouts sur une rangée sous les compteurs »
(5 contrôles : même rangée, après les compteurs, côte à côte ≥ 44 px, durée sous la rangée, volet
étroit inchangé ; 97 → 98 sections), vérifié CAPABLE D'ÉCHOUER (ancien ordre réintroduit → 4 rouges,
`index.html` restauré à l'octet).

## A310 — la grille lit le token que le dock lisait déjà (v5.22.2)

**Signalé par l'auteur** (05/09/2026) : « tu n'as pas adapté la taille de la barre flottante en bas
depuis que tu as diminué la sidebar droite ». Exact, et la cause est une faute contre une règle
écrite à la déclaration des tokens : « une seule source — le dock s'aligne dessus, et un changement
de largeur de colonne n'a plus deux endroits où se faire ». A308 a posé `280px` EN LITTÉRAL dans la
grille de lecture, alors que `#sessionDock .sd-in` et `#dockSheet .ds-card` calculent leur marge
droite sur `--col-state`, resté à 320. Mesuré à 820 px en session : le dock s'arrêtait 42 px avant
le bord de la colonne d'action.

**Correctif** : `--col-state` devient le token PAR PALIER (`:root{--col-state:280px}` dans le bloc
780, `320px` dans le bloc 1000), et les grilles de lecture (780, 1000, 1200, cockpit) lisent
`var(--col-state)` / `var(--col-orient)` / `var(--col-gap)` au lieu de littéraux — grille, dock et
volet ne peuvent plus diverger. Reste, symétrique et préexistant, l'écart de 2 px entre le
rembourrage du dock (20) et celui de la grille (18).

**Garde-fou** : un contrôle ajouté à la section A309 (même décor, une manœuvre une section) —
bord droit du dock à ≤ 3 px du bord de la colonne d'action —, vérifié CAPABLE D'ÉCHOUER sur le
défaut RÉEL (littéral réintroduit, token à 320 → écart −42 px) ; et NON sur un token remis à 320
partout, car grille et dock suivent alors ensemble — c'est précisément ce que le correctif garantit.
