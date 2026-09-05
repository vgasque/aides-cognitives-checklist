# Lot v5.22 — le gestionnaire de catégories en liste, le rail de session à 280 px sur tablette (A308-A313)

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

## A311 — sur « Toutes », une bande collante par bibliothèque dans le gestionnaire (v5.22.3)

**Demande de l'auteur** (05/09/2026) : « améliorer la séparation des bibliothèques dans la fenêtre
de modification des catégories ; design clair ».

**Mesuré avant** (820 × 1180, Perso + deux bibliothèques éditables) : chaque section n'était
introduite que par une phrase (« Catégories de la bibliothèque X (partagées avec ses membres). »)
et un filet ; le champ « Ajouter » de la section suivante se collait visuellement à la liste de la
précédente, et rien ne rappelait la bibliothèque une fois le corps défilé.

**Ce qui change** : chaque bibliothèque devient une `<section class="cm-sec">` ouverte par une bande
`.cm-l` au dessin exact de l'intertitre collant de l'accueil (`.dir-l`, A238-A268 : fond de page,
filet dessous, capitales 11 px espacées, compte en mono à droite) — glyphe `user` pour « Espace
personnel », `book` pour une bibliothèque, mention « partagée » à côté du nom ; 24 px entre deux
sections ; la bande est `sticky` dans le défileur du corps, donc la bibliothèque reste nommée
pendant qu'on fait défiler ses catégories. Le champ d'ajout d'une bibliothèque dit « Nouvelle
catégorie partagée… », là où la phrase supprimée portait l'information. Aucune fenêtre nouvelle,
aucune commande déplacée : « Ajouter » reste en tête (A308), les rangées et la palette sont celles
d'A308.

**Garde-fou** : `audit-doctrine` § « Catégories · une bande collante par bibliothèque »
(5 contrôles : trois sections, texte des bandes, chaque « Ajouter » vise sa bibliothèque, 24 px
d'écart, bande collante qui tient au haut du défileur — à 820 × 640 pour que le corps défile ;
98 → 99 sections), vérifié CAPABLE D'ÉCHOUER (`position:static` sur la bande → rouge, `index.html`
restauré à l'octet).

## A312 — un degré, une couleur : le curseur rend le preset ou la couleur d'origine à leur degré (v5.22.4)

**Signalé par l'auteur** (05/09/2026) : « des fois même si le ° est le même je n'ai pas l'impression
d'avoir la même couleur ; deux catégories marquées « proche de… », je joue avec la molette, je
reviens à la couleur de base : plus de « proche de », et la couleur n'est pas la même ».

**Vérifié par le calcul avant de corriger** : les treize presets ne sont PAS sur l'anneau du
curseur (L 0,48 · C 0,08) — leur clarté va de 0,43 à 0,52 et leur chroma de 0,04 à 0,16. Au même
degré, preset et couleur d'anneau diffèrent de 1,1 à 9,1 ΔE : le vermillon `#b23240` (19°) devient
un brun terne `#854a4b`, l'indigo `#5156b6` (277°) un ardoise `#52598a`. Revenir « au même degré »
rendait donc une AUTRE couleur, et la distance aux voisines changeait avec elle — d'où le
« proche de » qui disparaît. L'observation de l'auteur était exacte.

**Correctif** (`catHueSnap`) : à un degré donné, toujours la même couleur — d'abord la couleur du
pli à son ouverture (`catPickOrig`, à son propre degré : un hex importé hors anneau se retrouve),
puis le preset dont le degré arrondi coïncide (les treize degrés sont distincts), et seulement
sinon l'anneau. Les presets restent les repères ; l'anneau comble les intervalles. Le dégradé du
curseur montre l'anneau, et à un degré de preset le résultat est le preset — c'est le prix d'un
curseur idempotent, et la pastille `.on` du preset s'allume pour le dire.

**Garde-fous** : `tests.html` § « curseur : un degré, une couleur (A312) » (5 témoins, dont « un
preset et son jumeau d'anneau ne sont PAS la même couleur », la raison même du correctif) ; un
contrôle ajouté à la section A308 d'`audit-doctrine` (revenir au degré d'origine rend la couleur
d'origine, 19° rend le vermillon), vérifié CAPABLE D'ÉCHOUER (accrochage retiré → rouge,
`index.html` restauré à l'octet).

## A313 — au clavier, le piège des fenêtres déplace lui-même le focus, l'anneau suit, les champs s'allument par la bordure (v5.22.5)

**Signalé par l'auteur** (05/09/2026) : « Tab : le curseur se déplace mais pas le design autour du
bouton ; et quelquefois le design autour du bouton se met autour des champs texte ».

**Mesuré sur les deux moteurs, à la sonde, avant de corriger.** Le piège Tab des fenêtres ne
prenait la main qu'aux deux BOUTS de la liste des focalisables ; entre les deux, c'est l'ordre
natif du navigateur — et **WebKit saute les boutons par défaut** (réglage « Tab pour mettre chaque
élément en évidence » désactivé). Dans « Gérer les catégories », cinq Tab passaient de champ en
champ sans atteindre un bouton ; dans une confirmation, le troisième Tab sortait de la fenêtre et
se perdait sur le corps de la page. L'anneau posé à l'ouverture (A237) partait au premier blur,
et ce qui suivait ne se dessinait que si le moteur jugeait le focus « visible ». Les champs des
fenêtres n'avaient aucun style de focus à eux : anneau par défaut du navigateur (noir 3 px sur
WebKit, bleu sur Chromium), étranger au dessin ; et le halo de bouton (décalage 2 px) se posait
sur le champ « Nouvelle catégorie… » à l'ouverture.

**Ce qui change.**

1. **Le piège déplace lui-même le focus à chaque Tab et Maj+Tab**, dans l'ordre du DOM des
   focalisables, avec bouclage (`_focusables`) : WebKit ne peut plus sauter les boutons ni sortir
   de la fenêtre. Le focus étant programmatique, **l'anneau est posé explicitement** sur l'élément
   atteint (`_ringFocus`, extrait d'`_dlgEnter`) et retiré au blur suivant — même mécanisme
   qu'A237, généralisé au clavier.
2. **Le halo est réservé aux boutons** (`.dlg-ring:not(input):not(textarea):not(select)`) ; **un
   champ de fenêtre signale son focus par sa bordure** (`outline` 2 px primaire à décalage 0,
   bordure transparente — le dessin exact de `.field input:focus`), curseurs `range`, cases et
   boutons radio exclus. Réponse à la question de l'auteur : oui, un halo de bouton autour d'un
   champ texte est faux ; le focus d'un champ se lit à sa bordure, pas à une auréole.

**Garde-fou** : cinq contrôles ajoutés à la section « Fenêtres · le bouton focalisé se voit, même
ouvert à la souris » (même décor : ouverture à la souris) — quatre Tab restent dans la fenêtre,
chaque arrêt porte l'anneau, les boutons sont atteints, les champs portent la bordure allumée et
jamais l'anneau du navigateur, un bouton est atteint en quatre Tab depuis le gestionnaire ;
joués VERTS sur Chromium ET WebKit, vérifiés CAPABLES D'ÉCHOUER (code d'avant réintroduit → 5 rouges
sur WebKit, `index.html` et `_headers` restaurés à l'octet).
