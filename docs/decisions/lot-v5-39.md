# Lot v5.39 — le sommaire d'un PDF joint, optionnel (A418) ; filtre de catégorie par nom, connexion par Entrée (A419) ; retour système en pile réelle (A430)

> Fichier normatif, suite de [`lot-v5-38.md`](lot-v5-38.md) (A400-A417). Les numéros A sont des adresses :
> ne jamais renuméroter. Demande de l'auteur du 28/09/2026.

## A418 — le sommaire d'un PDF, comme celui d'un protocole, mais qu'on peut replier

**Demande.** « S'il y a un sommaire, faire un sommaire cliquable en sticky ou en sidebar selon la largeur d'écran, comme
pour le texte des protocoles », puis « repliable, car ça doit rester une option », et « repliable en un petit bouton ».
Jusqu'ici (A392), les signets d'un PDF s'ouvraient dans une feuille `openPickMenu`, qui se refermait à chaque choix.

**Deux régimes, au seuil des protocoles (`mqReadWide`, 1000 px).** Le sommaire n'existe que si le PDF a des signets
(`getOutline`, trois niveaux, 200 entrées au plus, titres posés par `textContent`).
- **Dès 1000 px : une colonne à gauche des pages** (`.pdf-card.toc-side`, grille `--col-orient` + pages), sur
  l'ambiance, séparée par un filet. Elle est **ouverte d'office** et se **replie en un bouton ≡ de 40 px**
  (colonne de 56 px, `.toc-min`). Le bouton de la colonne dit ce qu'il fait (« Replier le sommaire », chevron ‹ ;
  replié, « Afficher le sommaire », ≡). L'appareil retient le choix (`ac-pdf-toc`, `localStorage`, simple
  confort d'affichage). Replier ou déplier élargit les pages : on remet à l'échelle en gardant la même place dans le
  document.
- **Sous 1000 px : une bande sous la barre**, bornée à 56 % de la hauteur. Elle est **fermée d'office**, s'ouvre par
  le bouton « Sommaire » (icône ≡, `aria-expanded`) et **se referme après un choix**, puisqu'elle prend la place du
  document. Le bouton quitte la rangée d'outils et monte sur la ligne du titre : à 390 px, avec lui, la rangée
  débordait (« Largeur » coupé, ⤓ hors de l'écran — défaut né en A392).
- En large, le bouton « Sommaire » de la barre est masqué : la colonne porte son propre bouton.

**Chaque titre porte son numéro de page**, et **la section en cours est en bleu** (registre du bloc courant,
`aria-current`) : dernier titre passé sous la ligne de lecture (haut du défileur + min(96 px, 20 %)), le dernier
visible en bas du document. Après un choix, c'est ce titre qui reste en cours tant qu'on n'a pas défilé
(`tocPin`), même si un titre voisin est sur la même ligne.

**On arrive sur le titre, plus en haut de sa page.** `pdfDestPos` lit la hauteur de la destination (XYZ, FitH, FitBH)
en plus de sa page, et `pdfPosY` la convertit par le viewport de la page. Cela vaut pour le sommaire et pour les
renvois internes du document (A392). **Au passage, un défaut de toujours** : les hauteurs des pages se lisaient par
`offsetTop` depuis la CARTE (premier ancêtre positionné), donc en comptant la barre. Chaque saut de la visionneuse
(liens, sommaire, occurrences d'une recherche, ouverture à une page) arrivait environ 60 px trop bas. `.pdf-scroll`
est désormais positionné, et les hauteurs se lisent depuis le défileur.

**Formes écartées.** Colonne permanente non repliable (demande explicite : le sommaire reste une option) ; bande
étroite ouverte d'office (elle mange la moitié du document au téléphone).

**Témoins** (section `audit-doctrine` « Page · A392 … », PDF fabriqué par Chromium) :
- à 1280 px, la colonne est ouverte, les numéros de page sont justes, la section en cours suit un choix ;
- repliée, il ne reste qu'un bouton de 56 px au plus, les pages s'élargissent, la position est gardée et le choix
  retenu ; la colonne se rouvre ;
- à 390 px, la bande est fermée d'office, s'ouvre sous la barre, n'a pas de bouton de repli et se referme après un
  choix qui fait défiler.

Ces contrôles échouent sur la version précédente, qui n'avait pas de `#pdfTocNav`.

## A419 (v5.39.1) — le filtre de catégorie retient un NOM ; Entrée envoie l'e-mail

**1. Signalé : « sur Toutes, en large, les filtres n'ont pas l'air de fonctionner tout le temps ».** Reproduit au banc.
L'id d'une catégorie dérive de son nom D'ORIGINE (`detCatId`, « Urgences » → `c-urgences`). Renommée (« Urgences
adultes » dans le Perso), elle garde cet id, que porte aussi « Urgences » d'une autre bibliothèque. Depuis la v5.18, le
filtre compare par NOM à travers l'union (A299), mais il retrouvait ce nom par « la première catégorie qui porte cet
id » (`_catFiltName`). Taper « Urgences » filtrait donc sur « Urgences adultes », et c'est cette rangée qui s'allumait.
Même défaut dans la feuille « Affichage », dont les pastilles portaient l'id.

**Correctif : `state.cat` retient le nom normalisé (`catKey` = `txNorm(nom)`)**, la clé que le filtre, la colonne
(une rangée par nom) et les pastilles utilisaient déjà pour regrouper. Plus aucune lecture ne passe par un id. Deux
suites nécessaires :
- **renommer** la catégorie filtrée fait suivre le filtre si plus aucune catégorie ne porte l'ancien nom. Sans cela,
  le filtre deviendrait invisible, ce que la doctrine interdit (« un filtre posé ne doit jamais être invisible ») ;
- **supprimer** une catégorie en déplaçant ses éléments reporte le filtre sur la catégorie cible.

Un id reste la bonne clé partout où l'on agit sur UNE catégorie précise (gestionnaire, sélecteur de l'éditeur,
déplacement) : il y est toujours lu avec sa bibliothèque (`catOf`, `catItems`).

**2. Signalé : à l'écran de connexion, Entrée dans le champ e-mail n'envoyait rien.** Le champ du code avait son geste
Entrée (A373), pas celui de l'adresse. Il a maintenant le même (`keydown` Entrée → le bouton, hors composition IME),
et `enterkeyhint="send"` pour que le clavier du téléphone affiche « Envoyer ».

**Témoins** (section `audit-doctrine` « Accueil · A419 … ») : deux homonymes au même id d'origine, chacune ne montre
que ses aides et n'allume que sa rangée, dans la colonne ET la feuille ; « Afficher » (Aides / Protocoles) sur « Toutes »,
avec une aide et un protocole d'une bibliothèque partagée, donne le bon type dans les cinq rangements (vérifié à la
demande de l'auteur : ce filtre n'avait pas le défaut, il ne passe par aucun id) ; Entrée dans le champ e-mail déclenche l'envoi
(appel réseau remplacé). Trois contrôles sur quatre échouent sur la v5.39.0 : le quatrième, la rangée Perso, passait
déjà par chance, puisque c'est elle que la recherche par id trouvait en premier.

## A420 (v5.39.2) — le temps des audits se MESURE : presque aucune attente n'est inutile

**Demande de l'auteur : « optimiser le temps des audits sans supprimer de choses », puis « ces temps sont-ils vraiment
inutiles ? méfie-toi des harnais ».** Une première relecture du code (huit lectures, 22 harnais) estimait à −430 s ce que
rapporterait la conversion des attentes fixes en attentes sur condition, en supposant que `render`, `openRead`,
`tickAll`… produisent leur effet sur-le-champ. **La mesure l'a démentie**, et c'est elle qui fait foi.

**Méthode (copies jetables, sondes intactes).** Les 491 sommeils et 121 `waitForTimeout` des harnais ont été transformés
puis les 2 619 contrôles comparés un à un à une passe de référence (bruit de fond mesuré entre deux passes normales : nul).

| Attentes | Temps cumulé | Contrôles qui changent |
|---|---|---|
| telles quelles | 1 189 s | 0 |
| ≈ 2 images | 427 s | 66 au rouge, 5 harnais plantent (416 contrôles non joués) |
| divisées par 2 | 767 s | 31 (doctrine, partage, k5, a11y, pdfsearch, retour) |
| triplées | 2 732 s | 6, et un plantage (partage) |

Transitions, anti-rebonds, écritures IndexedDB, ticks et réseau sont réels : **les attentes fixes ne se raccourcissent pas
en masse**. Écartés aussi, mesures à l'appui : bloquer le service worker (0 s de gagné sur une tranche de 96 s), passer le
pool à 6 (trois rouges de charge), retirer les « attentes mortes » (relues : chacune laisse finir une transition avant le
geste suivant). La machine reste peu chargée (≈ 2 cœurs sur 8) : les harnais attendent l'app, ils ne calculent pas.

**Ce qui est prouvé et appliqué.**
1. **pdfsearch payait 60 s de délais par un défaut de condition.** `waitForFunction` de toute la passe chronométrés
   (1 693 appels) : les trois seuls qui expirent en vert sont ceux de pdfsearch, qui testaient `window.attIx` — `attIx`
   est un `const` du script classique, jamais propriété de `window`. L'index est prêt en 1 à 85 ms. Le témoin « pdf.js
   pas chargé » (règle 13) profitait par accident de 10 s d'observation après le démarrage : **elles sont gardées,
   explicitement**, pour ne pas l'affaiblir. 66 → 16 s, 40/40 contrôles identiques.
2. **Tranches équilibrées par durée.** Le modulo groupait les lourdes (doctrine 3/4 : 168 s contre 95 ; partage 1/5 : 98
   contre 32). `audit-run` enregistre la durée ⏱ de chaque section et de chaque tâche (`mesures`, par moteur, dans
   `.audit-etat.json`) et transmet aux tranches un plan glouton (la plus longue d'abord, tranche la moins chargée)
   `AC_PLAN` ; une section absente du plan retombe au modulo, un plan illisible ou hors bornes ÉCHOUE, un `AC_PLAN` du
   terminal n'atteint jamais un enfant, et le contrôle ##SEC de couverture est inchangé. **Préalable : les 155 sections
   de doctrine et partage, jouées SEULES, sont toutes vertes** — l'ordre de regroupement ne change aucun verdict.
   Mesuré : doctrine 119-120 s par tranche, partage 58-67 s, passe complète ~295 → 279 s, 2 619 contrôles identiques.
   Le gain sur la passe complète est modeste parce que le pool de 4 est plein : il porte surtout sur les passes ciblées.
3. **Poids d'ordonnancement re-mesurés** (doctrine déclaré 217 pour 478 réels) ; ils ne servent plus qu'à défaut de mesure.

**Les biais trouvés dans les harnais — un vert qui ne tenait qu'à la vitesse du harnais.**
- A387 « … et son compteur aussi » : le compteur, parti 200 ms après la coche, était lu dès l'arrivée de la coche. Il est
  maintenant attendu lui aussi.
- « Le billet mort ne traîne pas » : `Share.resume` interrogeait le VRAI Supabase après rechargement. La requête est
  désormais refusée par le banc (`page.route`) ; l'app efface le billet sur tout échec, réseau comme refus.
- Grammaire des fenêtres : une largeur lue 250 ms après une animation de 220 ms (357 contre 358 px sous charge). Le
  harnais attend désormais la fin des animations finies, EN PLUS des attentes existantes (plafond 1 s).
- « Continuer seul » : l'évènement « rejoué » recalculait `Date.now()`. L'identité d'une annexe étant `ax-<t>-<seq>`, une
  milliseconde d'écart en faisait un autre évènement, et le doublon observé sous charge était légitime : le harnais avait
  tort, pas le dédoublonnage. L'heure est fixée une fois.
Ces quatre corrections tiennent à attentes divisées par deux ET triplées (58/58 contrôles).

**Restent ouverts, signalés et non corrigés.** pdfsearch compte tantôt 1, tantôt 2 rectangles surlignés d'une passe à
l'autre (le contrôle passe dans les deux cas).

**v5.39.3 — le rouge WebKit d'A387 était un biais du harnais, pas une fuite.** Sous WebKit, « une session locale sur
l'autre aide n'émet RIEN sur le fil de l'invité » échouait déjà sur la v5.39.1 (3/3, deux ou trois évènements reçus ;
la passe par défaut, sous Chromium, ne le voyait pas). Relevé de la NATURE des évènements lus par l'invité pendant la
fenêtre : deux `sig` (offre et réponse de négociation du canal direct de secours, que WebKit achève plus tard), aucune
coche ni navigation ; sous Chromium, aucun. Le contrôle comptait `Share.applied`, qui additionne aussi cette plomberie
(`sig` est routé à `slSbOnSig`, jamais peint). Il compte désormais les seuls évènements d'état lus au fil (tout sauf
`sig`), avec un TÉMOIN — l'invité a lu le fil au moins une fois pendant la fenêtre — sans lequel un zéro ne prouverait
rien. Vérifié capable d'échouer : `Share.hostedRt` neutralisé chez l'hôte (le défaut d'origine d'A387), le contrôle rougit
sur les deux moteurs et nomme `uncheck, counter, timer_stop, nav, session_start, check`.

**Formes REFUSÉES** : convertir les attentes fixes en masse (le gain supposé ne résiste pas à la mesure, et la moindre
réduction casse des contrôles) ; accélérer les délais de l'app au banc (`page.clock`, réglages ad hoc) — cela changerait ce
qui est prouvé ; regrouper les petits harnais dans un seul processus (2 à 3 s pour un rouge moins lisible).

## A421 — « Afficher » suit le type choisi ; l'anneau d'arrivée ne repeint plus (v5.39.4)

**Signalé à l'usage** : « problème de filtrage persistant entre Aides et Protocoles dans le menu
Affichage, ça ne filtre pas » ; « rendre l'animation autour de Commencer la session plus fluide ».

**Le filtre. Cause mesurée.** La feuille « Affichage » a DEUX portes : le bouton rond de la recherche
(`[data-filttog]`, `openViewSheet()` sans rappel) et le bouton « Affichage » de la liste (`#rangBtn`,
`openViewSheet(cfg.rerender)`). Par la seconde, la feuille gardait la vue d'OUVERTURE comme rappel
(`renderAll` sur « Tout ») : « Aides » appelait `setSection`, qui rendait la bonne liste, puis ce rappel
figé repeignait l'union par-dessus. Tout geste suivant de la même feuille (tri, regroupement, densité,
catégorie) ramenait aussi la vue d'ouverture. Le témoin d'A419 (« vérifié sans défaut ») ouvrait par le
bouton rond, le seul chemin sain : il ne pouvait pas voir celui-ci.
**Correctif** : `viewSheetRedo()`, seule porte de re-rendu de la feuille ; à l'accueil elle appelle
`renderLibrary`, qui aiguille selon `state.section` ; ailleurs le rappel reçu, sinon `render()`.
**Témoin** (`audit-doctrine`, section A419) : quatre crans par `#rangBtn`, chacun suivi d'un tri dans la
même feuille, comptes d'aides et de protocoles attendus. Rouge sur le code d'avant, vert après.

**L'anneau (amende A331 sur la TECHNIQUE, pas sur le signal).** Il animait un `box-shadow` d'étalement
0 → 12 px : une peinture par image sur le fil principal, précisément pendant le rendu d'une fiche neuve
(les saccades se voyaient sur iPhone). Il surgissait aussi à pleine encre au bord de la capsule, et le
palier immobile 60-100 % de chaque itération hachait le rythme. Désormais :
- `.sd-in::after` est un TRAIT de 2 px (`--dock-ring`) dessiné une fois à sa place finale : un
  `outline` décalé de 10 px sur une boîte à la taille de la capsule (`inset:0`), et non une bordure à
  `inset:-12px` — celle-ci entrait dans le débordement de la capsule et le témoin ECAM « sans rognage »
  rougissait (12 px, à toutes les largeurs) ; un contour n'y entre jamais et suit le rayon de la boîte ; il part de la capsule par `transform:scale(--sd-sx,--sd-sy)`
  et s'efface par `opacity` — deux propriétés composées, rien n'est repeint ;
- l'échelle de départ est MESURÉE par axe dans `syncDock` au moment où `sd-arrive` se pose, après la
  sous-ligne du bouton (qui change la hauteur) : 12 px pèsent 3 % sur 360 px de large, 30 % sur 56 de
  haut, une échelle uniforme décollerait le trait du bord. Ratio sans unité : les 12 px sont ramenés à
  l'écran par `zoomF()` (vérifié à 130 % : 0,70 en hauteur comme à 100 %) ;
- fondu d'entrée (0 → 1 sur 20 %), puis un seul mouvement décéléré (`cubic-bezier(.22,.61,.36,1)`)
  jusqu'à l'effacement, sans palier.
Inchangé : trois anneaux, départ à 800 ms, 1,3 s chacun, fini à 4,7 s (WCAG 2.2.2), autour de la
CAPSULE entière et jamais du bouton seul, rien sous `prefers-reduced-motion`. Mesuré à 390 (clair et
sombre, images figées à 0, 10, 25, 50, 80 %) et à 1440 px.
**Forme refusée ici** : garder l'ombre en changeant seulement la courbe — le coût de peinture, cause des
saccades, restait entier.

## A422 — l'état d'une carte d'accueil est une méta (v5.39.5)

**Signalé à l'usage** : « pourquoi les bulles Brouillon, Sans date… ont une police presque aussi grande
voire plus grande que le titre des cartes ? »

**Mesuré** (390 et 1280 px, détaillée et compacte) : titre `.dir-t` 15/700 (15/600 en compacte) ;
état `.dir-st` 13,5 hérité du corps de `.dir-sub`, et le badge `.dir-st.b` le portait à **800** sur un
aplat `--amb-2` — plus gras que le titre, et l'aplat ajoutait de la masse. « AIDE » (`.dir-kind`), à
12/800 en capitales, était déjà au palier méta : la ligne mêlait deux paliers.

**Décision** : `.dir-st` prend `--t-meta` (12) ; 700 pour ce qui attend quelque chose (`.b`, `.w`
« À revérifier », `.dir-live` « En cours »), poids de la ligne pour le nominal (« Validée + date ») —
un état nominal ne s'affiche pas en gras (poste de pilotage sombre). Hiérarchie de la carte :
titre 15 > discriminant 13,5 > méta 12. Glyphe, mot, aplat et couleurs d'A338/A347 inchangés ; plancher
11 px respecté.

## A423 — au téléphone, la recherche et le filtre FLOTTENT sur un bord doux (amende A222 sur ce seul lieu)

**Demande de l'auteur** : « pourquoi la barre de recherche et le bouton filtre ont un fond gris en dessous ?
On ne pouvait pas laisser transparent comme sur les design récents d'app ? »

**Ce qui était là.** `#homeDock` (< 780 px) posait une BANDE de la couleur du fond (`--amb`) sous le cercle
filtre et la recherche, fondu de 20 px sur l'arête haute. Elle paraissait grise parce que ce qui défile
dessous est une carte blanche. Ce n'était pas une exigence WCAG : les commandes sont opaques, leur texte
garde son contraste quel que soit le fond ; c'était l'application d'A222 (« matière opaque »).

**Vérifié sur les systèmes (sources dans la conversation d'origine, 29/09/2026).** iOS 26 : la recherche
descend en bas (Safari, Musique, Plans, Notes, Mail), les commandes sont des éléments SÉPARÉS qui flottent
— une capsule pour la recherche, des cercles pour les boutons (Mail : filtre à gauche, recherche à côté) —
et, dessous, un « effet de bord » doux (flou et estompage progressifs), pas une bande. L'ombre de ces
éléments est DISCRÈTE et gérée par le système (plus faible sur fond clair). Material 3 Expressive : barres
d'outils flottantes, élevées par défaut. Le VERRE translucide, lui, est écarté : son contraste dépend de ce
qui passe dessous (NN/G a mesuré 1,5:1 là où il faut 4,5:1) — A222 tient pour la matière des commandes.

**Décision.** Plus de bande. Le cercle filtre et la capsule de recherche restent OPAQUES et SÉPARÉS ; ils
flottent avec `--shadow-float` (plus légère que `--shadow-work`, `none` la nuit) et, la nuit, le contour
`--ctl-line` (3:1) les borde — ils passent sur des cartes de leur propre teinte. Sous eux, `#homeDock::before`
dessine le bord doux : flou 12 px, voile du fond à 94 → 86 % derrière les commandes (le texte ne transparaît
ni entre les puces de type pendant une recherche, ni sous la capsule), puis estompage sur les 40 px au-dessus,
masqué (`--edge-mask`). Commandes à L 44 toutes deux (paires de la même rangée, échelle A375) ; la capsule
prend le rayon 999 (la pilule, jusqu'ici réservée aux chips et jetons ronds, s'étend à cette capsule).
Clavier ouvert : le bord doux s'efface, le dock reprend sa matière opaque d'A249 (`html.kbd`). ≥ 780 px :
rien ne change (le dock est une rangée de l'en-tête).

**Formes écartées** : la bande seule allongée (fondu long, B) ; la capsule UNIQUE qui avale le filtre (îlot,
C/D) — ce n'est pas le modèle des systèmes, qui séparent les éléments ; le fond totalement transparent sans
voile — le texte des cartes passait entre les deux commandes ; une ombre marquée — les systèmes ne la
portent pas.

**Mesuré** (390 px, jour et nuit, au repos · filtre actif · pendant une recherche) ; check complet, tests,
audit complet (seuls les deux rouges d'environnement connus). ⚠ Le flou (`backdrop-filter`) est à juger sur
iPhone, en défilement : le navigateur de test ne le rend que faiblement.

## A424 — ranger une sélection éparpillée : par nom, dans la bibliothèque de chacun

**Signalé** : « pourquoi on ne peut plus modifier une catégorie sur la sélection multiple ? » L'acte n'avait
pas disparu : il n'était offert que si les cochés partageaient UNE bibliothèque (lot v5.12) — toujours vrai
tant que l'accueil montrait une bibliothèque à la fois, rarement depuis qu'il montre leur union (v5.18).
La rangée s'effaçait alors de la feuille « Actions », et seul le compte (« · deux bibliothèques ») le disait.

**Décision.** L'acte est toujours offert. Une catégorie n'existant que dans une bibliothèque, on choisit un
NOM : chaque élément va dans la catégorie de ce nom de SA bibliothèque ; là où le nom manque, il reste
INCHANGÉ (rien n'est créé, rien n'est vidé). Le sélecteur le dit AVANT le geste, dans la grammaire des
feuilles existantes (A360/A361) :
- en-tête : « Ranger 3 éléments » / « Perso · SMUR 75 », puis une NOTICE douce (patron `.notice` de
  l'accueil, ⓘ, sans croix) : « 2 bibliothèques différentes. Chacun ira dans la catégorie du même nom de la
  sienne ; là où ce nom n'existe pas, il ne change pas. » ; sous-ligne de l'acte dans « Actions » : « par nom,
  dans la bibliothèque de chacun » ;
- les noms se RANGENT sous des intertitres qui disent où ils existent (`.mm-head` du menu ⋯, option `{head,n}`
  de `openPickMenu`) : « DANS LES DEUX BIBLIOTHÈQUES » (« Dans toutes… » au-delà de deux), « SEULEMENT DANS
  PERSO », « DANS PERSO ET SMUR 75 » ; le partage, identique pour tout le groupe, est dit UNE fois sous
  l'intertitre (« 1 dans Perso · 2 dans SMUR 75 », « 1 rangé · 2 inchangés ») — les rangées ne portent que le
  nom (la première version répétait une sous-ligne par rangée : illisible, signalé) ; les groupes « partout »
  d'abord ; le filtre masque un intertitre dont le groupe est vide ; aucune rangée cochée quand les catégories
  actuelles diffèrent (défaut antérieur : « Sans catégorie » se cochait) ;
- le toast reprend le partage : « 3 éléments rangés dans « Urgences » — 1 dans Perso, 2 dans SMUR 75 »,
  et ce qui est resté inchangé, en avertissement.
Une seule bibliothèque : le sélecteur d'avant (ni en-tête, ni sous-ligne).

**Code.** `selCatPlan` est la seule source du partage (sous-lignes avant, toast après) ; `catNamed` est la
seule correspondance par nom, partagée avec « Déplacer vers une bibliothèque » (`selMoveLib` la recopiait) ;
les noms de bibliothèque passent par `impLibName`. La barre ne ferme plus « Catégorie… » (`catOk` purgé).

**Témoin** : `audit-doctrine`, section « A424 » (8 contrôles : compte, acte, notice, intertitres et partage, ordre, geste, une seule bibliothèque) — rouge sur le code d'avant (7/8), vert après.

## A425 — sur un écran très large, la colonne de l'accueil se centre (amende A389)

**Demande de l'auteur**, après exploration de six mises en page du bureau (une grille par groupe, groupes en
marge, liste + aperçu, groupes en colonnes façon magazine, carte étalée, Compacte) : garder la colonne unique
d'A389 — c'est la seule qui se lit de haut en bas sans rompre l'ordre (le « magazine » doublait la densité mais
coupait l'alphabet en colonnes) — et la **centrer**. Elle collait à gauche de l'espace principal, un vide à droite.

**Règle.** ≥ 780 px, tout ce que porte `.home-main` (sélection, session en cours, notices, liste) partage la colonne
de 960 px, centrée (`margin-inline:auto`). L'en-tête (recherche, « Créer ») et le bandeau système suivent le même
axe par `--home-g` = max(24 px, (largeur − colonne gauche − 960) / 2) — un pourcentage de marge se prend sur la
largeur du corps, la même base que l'espace principal. En dessous d'environ 1260 px, `--home-g` vaut 24 px : rien
ne change. La carte « Session en cours » perd son plafond de 780 px et prend la largeur de la colonne. Les vues
Sessions et Moi gardent leur gabarit document (A365), déjà centré.

**Mesuré** (1024, 1440, 1920 px) : liste, ligne de compte, session en cours et barre de sélection au même bord ;
barre de sélection sur UNE ligne de 56 px, ses quatre actes visibles ≥ 1200. **Limite dite** : avec une barre de
défilement CLASSIQUE (Windows, navigateur de test), l'en-tête est décalé de la moitié de cette barre (7 px) — la
colonne se centre dans le défileur, l'en-tête dans la page ; nul sur iPad et Mac (barres superposées). Réserver la
gouttière des deux côtés (`scrollbar-gutter: stable both-edges`) l'annulerait au prix d'un décalage de 15 px entre
780 et 1260 px, là où tout est aligné aujourd'hui : écarté.

## A426 — deux défauts d'affichage : le cadenas des bibliothèques, la couleur d'accent

- **Cadenas de la colonne gauche** : il précède le nombre (`hsRow` : acte puis queue), et le nombre n'avait pas
  de largeur fixe — le cadenas bougeait entre 1 et 2 chiffres. `.hs-n` prend une colonne de 3 ch, alignée à droite
  (le « nombre au bord droit » d'A275 le dit déjà). Mesuré : cadenas au même x avec 12 et 1.
- **Couleur d'accent (Moi)** : `.set-row` a 2 px de rembourrage vertical, pensé pour un contrôle en ligne ; quand
  les pastilles passent à la ligne, elles touchaient le bord bas, et l'anneau de la choisie (4 px, ×1,08)
  débordait. La rangée de pastilles prend 6 px de marge verticale et son cadre 8 px (`:has(>.accent-row)`).

## A427 — au retour dans l'app installée, les deux viewports se recollent

**Signalé (captures iPhone)** : après avoir quitté puis rouvert l'app, une bande vide en haut de l'accueil (la
recherche poussée sous l'écran), ou, sur une fiche, le quai « Confirmé — démarrer la session » au milieu de l'écran.
**Lecture** : le viewport visuel décalé par rapport à celui de mise en page — vers le haut dans le premier cas, vers
le bas dans le second ; les couches fixes suivent le second, le contenu se voit dans le premier. Le recollage
`unpan` (v5.10.4) avait trois angles morts : il n'écoutait pas `visibilitychange` (une app installée rouverte depuis
le sélecteur n'émet pas `pageshow`) ; il renonçait dès qu'un champ avait le focus, même clavier fermé ; il ne
traitait qu'un décalage positif. **Correctif** : recollage au retour visible (à 60 et 400 ms, iOS repose sa
géométrie en retard, `--vvh`/`--vvt`/`html.kbd` relus d'abord) ; garde réduite à sa définition (clavier ouvert =
viewport visuel plus court de plus de `VVT_MIN_CLAVIER`) ; décalage négatif recollé par un aller-retour d'un pixel.
**Non reproductible hors appareil** : Chromium ne décale jamais les deux viewports sans pincement — à confirmer sur
l'iPhone, en quittant l'app champ de recherche actif puis sans.

## A428 — filtrer par bibliothèque dans la feuille « Affichage »

Au téléphone et à la tablette, la bibliothèque ne se choisissait que par son RANGEMENT (regrouper par
bibliothèque) ; seule la colonne gauche du bureau la FILTRAIT. La feuille gagne la famille « Bibliothèque », avant
« Catégorie », au dessin de ses puces : « Toutes », « Perso », chaque bibliothèque (livre, ou cadenas en lecture
seule) — le même cran que la colonne (`state.homeLib`), donc « Tout effacer », le compte des filtres et la phrase
« filtres : … » le prennent déjà en compte. Absente s'il n'y a qu'une bibliothèque. `homeVis()` devient la source
unique de « ce que l'accueil peut montrer » (colonne et feuille).

## A429 — la feuille « Affichage » en deux parties ; les filtres posés en puces sur la page (P1 + P4)

**Demande de l'auteur**, sur cinq propositions maquettées (actuel, deux parties, deux onglets, liste de réglages,
filtres posés sur la page) : P1 + P4. Avec la bibliothèque (A428), la feuille empilait six familles sans ordre lisible.

**P1 — deux parties nommées.** « Filtrer » (Afficher, Bibliothèque, Catégorie : ce qui RESTREINT) puis « Présenter »
(Trier, Regrouper, Densité : ce qui RANGE). Chacune est une SECTION ENCADRÉE (`.vs-sec`, filet `--work-line`, `--r-4`)
dont l'en-tête porte une pastille d'icône (`filter`, `ladder`) et un titre au corps de rangée, filet dessous : un simple
filet entre les deux ne se lisait pas comme deux structures (retour de l'auteur). Le titre de « Filtrer » porte le compte (« 2 actifs ») et
« Tout effacer », qui quitte le pied ; le pied ne dit plus que le résultat (« Voir les 12 résultats »). Focus
d'ouverture sur le cran actif d'« Afficher » (`data-dlgfocus`) — jamais sur « Tout effacer ».

**P4 — les filtres posés en puces.** Sous la ligne de compte, une puce par filtre (« Bibliothèque : CH Le Mans × ») :
la puce rouvre la feuille, sa croix retire ce filtre seul, « Tout effacer » à partir de deux. Elles remplacent la
phrase « filtres : … » (`.dir-hf`, purgée avec son CSS — A278 visait sa cible ; les puces portent 32 px, la croix sa
propre cible). **Elles restent dans l'état « Aucun résultat »** : c'est là qu'on retire un filtre (la phrase y
disparaissait). Bleu : un état actif, jamais un registre de danger (règle 8).

**Une source.** `filtersList()` décrit les filtres posés ; le compte du déclencheur (`filtersCount`), les puces et
« Tout effacer » la lisent ; `dropFilter(k)` retire un filtre ou tous. **Défaut corrigé au passage** : « À relire »
n'était pas compté (il passe par `homeRev`, `section` restant à « all ») — le déclencheur disait 0 sur une liste
restreinte. **Témoins** : `audit-a11y` mesure la surface « filtres posés » sur `.af-bar`, `audit-doctrine` ouvre la
feuille par une puce (`.af-l`) et « Tout effacer » par son id, désormais dans le corps de la feuille.

## A430 — le retour système devient une vraie pile : une entrée d'historique par niveau (amende v4.30.0)

**Demande de l'auteur.** « Lorsqu'on swipe vers la droite sur iPhone, Android ou même tablette/desktop, qu'il ait un
comportement comme une app : retour à la page hiérarchiquement avant, sans devoir recharger la page ni faire freeze
l'app. »

**Cause (hypothèse, non mesurable ici).** v4.30.0 gardait UNE entrée sentinelle, ré-armée par `pushState` DANS le
popstate. Le bouton retour d'Android n'en demande pas plus. Le balayage d'iOS, lui (et le retour prédictif des
Chrome Android récents), fait glisser la CAPTURE de l'entrée précédente, prise quand on l'a quittée : avec une seule
entrée, la capture montre souvent un autre écran que celui où l'on arrive. Et WebKit laisse cette capture par-dessus
la page jusqu'à des signaux de rendu, au plus 3 s (`swipeSnapshotRemovalWatchdogDuration`, `ViewGestureController`) :
une entrée poussée pendant le retour peut les retarder, d'où l'app « gelée » qui tourne en dessous.

**Ce qui change — le seul point 3 de J238.** Une entrée `{ac, d}` par NIVEAU ouvert, poussée en microtâche (avant la
peinture, donc la capture est celle de l'écran qu'on QUITTE) ; une fermeture par l'app redescend l'historique
(`history.go`, popstate ignoré) ; aucune entrée n'est poussée dans le retour lui-même (on laisse la vue se poser,
800 ms, puis on se recale). `ac` est propre au document : les entrées d'un chargement précédent se lisent « sous la
base » — accueil nu, le retour les traverse et sort, comme avant.

**Ce qui ne change pas.** Pas de routage (l'adresse reste `index.html`) ; le retour emprunte le chemin de l'affordance
visible (✕, voile sans ✕ = « Poursuivre », « ‹ » avec sa pile d'origine et sa garde 700 ms) ; un geste AVANT ne
rouvre rien ; en session, le retour n'arrête jamais la session.

**Une table, pas deux listes.** `_H_LAYERS` range les couches du dessus vers le dessous — écran d'entrée, fenêtres,
volet du quai, dépliant des minuteurs, moniteur, schéma plein écran, visionneuse, vue — chacune avec son nombre de
niveaux ET sa fermeture : `_histLevels` et `_histBackAction` la lisent, ils ne peuvent pas diverger. Niveaux de la
vue (`_hViewLevels`) : accueil 0 (1 sur Sessions/Moi), lecture 1 + pile d'origine, éditeur = sa lecture + 1 (1 s'il
crée), aperçu = son éditeur + 1 — exactement ce que fait « ‹ ». Les ouvertures et fermetures ne s'en souviennent
plus : l'observateur des fenêtres (classe ET `hidden`) et `render()` appellent `_histSync` — sept appels
`_histArm()` dispersés sont partis.

**Limites dites.** Un retour bloqué par la garde 700 ms (double balayage nerveux) est ré-empilé : c'est un geste
mort, comme avant, pas une désynchronisation. Safari fait toujours glisser une image figée ; seule une app native
montre l'écran vivant. **À vérifier sur l'appareil** (iPhone installé, Android à retour prédictif) : accueil → fiche
→ retour ; fiche → fiche liée → retour ×2 ; une fenêtre ouverte → retour ; la même chose en session.

**Témoins.** `audit-retour` (section A430) : trois niveaux = trois entrées, retour ×3 aligné à chaque pas, fermeture
par ✕ qui retire l'entrée, geste avant qui ne rouvre rien — rouge sur le code d'avant.

