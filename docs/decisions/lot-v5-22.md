# Lot v5.22 — le gestionnaire de catégories en liste, le rail de session à 280 px sur tablette (A308-A316)

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

## A314 — l'anneau du curseur passe par les presets ; la palette elle-même, mesurée, reste (v5.22.6)

**Demande de l'auteur** (05/09/2026) : « concernant la palette de couleur des catégories on ne
pouvait pas mieux faire ? », puis « ok pour ça » devant la planche « Curseur — trois anneaux » du
canvas, et « et pour les couleurs en elles-mêmes / la palette ? ».

**Le curseur, oui : A312 était un pansement.** L'anneau d'A308 (L 0,48 · C 0,08 constantes) ne
passait pas par les presets (clarté 0,43-0,52, chroma 0,04-0,16) ; A312 accrochait le curseur aux
presets à leur degré, mais la barre montrait l'anneau et le résultat sautait à treize endroits.
Trois anneaux chiffrés sur 360° (planche du canvas) : constant (écarts 1,1-9,1 ΔE aux presets),
chroma maximale plafonnée à 0,12 (0,4-8,7 ΔE, plus vif mais toujours à côté), **ancré sur les
presets** (L et C interpolées linéairement en teinte entre presets voisins : écart nul aux treize
degrés, en gamut partout, blanc ≥ 5,50, pastille 4,49 sur un court segment → **clarté bornée** par
descente de 0,004 jusqu'à `catLisible`, pastille ≥ 4,50). Retenu : l'anneau ancré (`CAT_ANK`,
`catHueHex`). Le curseur devient le prolongement continu de la palette ; `catHueSnap` reste (la
couleur d'origine du pli à son degré, et le hex exact du preset), mais n'a plus rien à cacher.
`CAT_L`/`CAT_C` disparaissent.

**La palette, non — et voici pourquoi, mesuré.** Les treize presets satisfont toutes les
contraintes dures : ΔE minimal entre deux presets 5,9 (plancher 4,0), les deux contrastes de la
régression #3 partout, chips lisibles en sombre (≥ 4,65). Deux faiblesses réelles : (1) un
resserrement des teintes vertes-bleues — 166°, 188°, 204° à 16-22° d'écart, contre 41° ailleurs ;
(2) trois presets sous 3:1 en couleur pleine sur fond sombre (`#0d5b56` 2,25, `#45556b` 2,35,
`#7a2f6b` 2,08), déjà connus de J1 et atténués par « la couleur n'est jamais seule ». Ce qui
empêche de « faire mieux » sans coût : la contrainte pastille ≥ 4,5 en clair veut L ≤ ~0,50, le
3:1 en sombre voudrait L ≥ ~0,52 — les deux ne se tiennent pas ensemble à cette chroma (J1 l'avait
établi au solveur) ; et **les couleurs déjà stockées ne changent pas** : une palette re-résolue
coexisterait sur les appareils avec l'ancienne, avec des quasi-doublons sous 4,0 ΔE (deux teals
voisins), soit exactement le défaut qu'on voudrait corriger. Le caractère sourd est une identité
(v5.1.x), pas un défaut. Avec l'anneau ancré, les intervalles entre presets sont désormais
atteignables au curseur : le resserrement des teals se contourne sans re-résoudre la palette.

**Garde-fous** : `tests.html` — « l'anneau passe par chaque preset (A314) », « entre deux presets,
la teinte suit le degré », « l'anneau rend le vermillon à 19° sans accrochage » (remplace le témoin
inverse d'A312 ; 1189 → 1190), contrastes sur 120 teintes et `catLisible` conservés ; vérifiés
CAPABLES D'ÉCHOUER (anneau constant réintroduit → 2 rouges, dont les treize écarts listés,
`index.html` et `_headers` restaurés à l'octet). La section A308 d'`audit-doctrine` reste verte
(11/11).

## A315 — le curseur de teinte se replie derrière un bouton « palette », quatorzième pastille (v5.22.7)

**Demande de l'auteur** (05/09/2026) : « cache la palette derrière un bouton à côté des presets
avec un petit bouton svg montrant la palette », puis « utilise uiIcon ».

**Ce qui change** : dans la palette ouverte d'une catégorie, les treize pastilles sont suivies d'une
quatorzième, un bouton `.sw-more` à icône `palette` — entrée ajoutée à la table d'`uiIcon` (trait,
grille 24, donc tenue par `check-icons` comme les autres), jamais un SVG posé à la main. Le
curseur « Autre teinte » et l'aperçu ne se rendent qu'à la demande (`catHueOpen`), `aria-expanded`
sur le bouton, focus rendu au bouton après re-rendu (A236). **Trois états, un seul principe : l'état
se voit.** Fermé par défaut ; ouvert d'office quand la couleur de la catégorie n'est pas un preset
(le bouton porte alors l'anneau `.on`, comme la pastille d'un preset choisi — c'est SA pastille) ;
et le choix de l'utilisateur, une fois fait, l'emporte jusqu'au prochain pli (`null` = automatique).
Le pli fermé perd ainsi ≈ 110 px, la palette redevient une rangée et demie.

**Garde-fou** : deux contrôles ajoutés à la section A308 d'`audit-doctrine` — quatorze boutons dans
la rangée, curseur absent avant le tap et présent après ; puis, la couleur devenue hors preset, le
pli rouvert montre le curseur d'office avec le bouton en `.on` (13 contrôles) ; vérifié CAPABLE
D'ÉCHOUER (curseur forcé ouvert → rouge sur le bon contrôle, `index.html` restauré à l'octet).

## A316 — la pastille choisie ne mord plus ses voisines ; renommer repeint l'aperçu (v5.22.8)

**Signalés par l'auteur** (05/09/2026) : (1) « revois l'espacement entre les pastilles : lorsque
sélectionnée, [elle mord] toutes les autres pastilles y compris la nouvelle pastille pour ouvrir la
palette » ; (2) « lorsqu'on modifie le nom de la catégorie, le nouveau nom ne s'affiche pas dans
l'aperçu ».

**Mesuré** : la pastille choisie grandit de 12 % (± 1,92 px) et porte un anneau de 4 px, soit
5,92 px de débord pour un écart de 6 px — **0,08 px de jeu**, ce que l'œil lit comme un contact,
horizontalement et sur la rangée du dessous. Et le champ de nom écrivait `c.name` sans repeindre
l'aperçu de la palette ouverte, qui ne se re-rend qu'au tap d'une pastille.

**Correctifs** : écart des pastilles porté à **8 px** (valeur de l'échelle fermée), soit 2,08 px de
jeu ; et le gestionnaire `input` du nom repeint `[data-prev]` par `catPrevHtml` — le nom vit dans
l'aperçu, il doit y suivre la frappe.

**Garde-fous** : deux contrôles ajoutés à la section A308 d'`audit-doctrine` — jeu minimal entre
l'anneau de la pastille choisie et toute voisine ≥ 1,5 px (mesuré au rectangle, palette comprise),
et les deux chips de l'aperçu portent le nom saisi (15 contrôles) ; vérifiés CAPABLES D'ÉCHOUER
(écart remis à 6 px → « jeu 0,08 px » ; repeinture retirée → rouge ; `index.html` restauré à
l'octet). ⚠ Piège de harnais attrapé en route : une rangée RENOMMÉE change de place dans le tri par
nom — la sonde la retrouve par id, jamais par index.
