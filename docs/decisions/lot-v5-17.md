# Lot v5.17 — la barre de sélection tient sur une ligne

> Doctrine du lot v5.17 — **A227 à A230**. Une planche de Claude Design (« Barre de sélection —
> planche 20 », 21/08/2026) reprend le CONTENU de `.sel-bar` sous une contrainte unique : **la
> barre ne dépasse jamais 56 px de haut**, à tout écran et dans tout état. La coque ne change pas
> (place collante, matière, périmètre, marge) — c'est ce qu'elle porte qui est refait.
>
> Deux des consignes de la planche ont été **corrigées à la mesure** avant d'être implémentées
> (A228) : elles décrivaient une géométrie que l'application n'a pas. Le reste est appliqué tel
> quel, y compris les renommages, qui sont l'essentiel du gain de lisibilité.

## A227 — l'état sur la ligne, les actes dans un tiroir

**CONSTAT (planche 20a, mesuré).** Le défaut n'était pas la largeur, c'était la **hauteur**. Huit
objets dans un `flex-wrap` avec une entretoise élastique (`.sel-sp{flex:1 1 auto}`) : le rendu
étroit n'était pas dessiné, il était **subi**. Dès que la ligne cassait, l'entretoise n'avait plus
rien à pousser, les commandes se rangeaient dans un ordre que personne n'avait choisi, et
« Supprimer… » atterrissait **juste sous « Tout »**, là où le pouce venait de taper.

Le coût réel se payait sur l'axe vertical : la barre est **collante** sous l'en-tête, donc ses
~100 px de deux étages restaient à l'écran pendant TOUT le défilement — sur le seul axe qui
manque sur téléphone. Toute correction qui ajoute une rangée aggrave le symptôme au lieu de le
traiter ; c'est la contrainte de la planche.

Et cette hauteur était payée pour rien : à l'ouverture du mode, **quatre commandes sur six sont
mortes** (rien n'est coché, donc Aucun, Déplacer, Ranger et Supprimer sont désactivés). Deux
étages pour une seule chose faisable. Enfin, `.sel-bar .btn` descendait à **32 px de haut et
11 px de texte** : les deux planchers que la règle 9 tient partout ailleurs, abaissés ici, sur
des commandes dont l'une est destructrice.

**DÉCISION.** La barre garde ce qui doit rester sous les yeux en permanence — **le compte, la
portée de la coche, la sortie** — et rend ce qui ne sert qu'une fois : les trois actes. Ils
partent dans la feuille que « Bibliothèque… » et « Catégorie… » ouvraient déjà (A170), sous une
touche unique « Actions ». Un tap de plus, une rangée de moins, à l'endroit où la rangée coûte le
plus cher. Hauteur : **56 px, fixe**, contre ~100 px auparavant sur téléphone.

- **`.sel-sp` est PURGÉE, pas masquée**, et `flex-wrap` passe à `nowrap` : c'est le COUPLE des
  deux qui fabriquait l'ordre aléatoire au repli — en retirer un seul aurait laissé l'autre prêt
  à le refaire. Son épitaphe est écrite sur place, dans le CSS de `.sel-bar` (règle 14).
- **Le compte devient le seul élément élastique** (`flex:1 1 auto; min-width:0`, ellipsis) : tout
  ce qui manque à la ligne se prend sur LUI, jamais sur un acte. Il est aussi le seul élément qui
  bouge d'un état à l'autre, et il bouge dans son propre espace.
- **Rien de coché, rien de mort** : la touche d'actes n'est pas grisée, elle **n'existe pas**
  (`n>0`). La barre est alors trois objets sur une ligne courte.
- Les planchers remontent à **40 px** de cible et `var(--t-body)` de corps.
- « Annuler » n'a **pas de contour**, ni sous son mot ni sous sa croix : c'est la SORTIE du mode,
  pas un quatrième acte. En replié il se réduit à sa croix, l'`aria-label` restant entier
  (« Quitter la sélection ») — c'est le libellé VISIBLE qui se replie, pas le nom accessible.
- **Aucun balisage n'est dupliqué.** Les trois actes sont rendus UNE SEULE FOIS, dans `.sel-acts` ;
  en replié la feuille les **rejoue** (`b.click()` sur le bouton masqué). Un acte destructeur
  écrit deux fois, ce sont deux gestionnaires à garder d'accord — et le jour où l'un prend une
  confirmation que l'autre n'a pas, personne ne le voit.

## A228 — le palier de dépliage est à 1200 px, et il ne peut pas être une media query

**LA PLANCHE ÉCRIT `@media (max-width:559.98px)`. LES DEUX MOITIÉS DE CETTE LIGNE SONT FAUSSES
ICI**, et c'est la seule divergence de fond avec le brief. Chacune a été mesurée avant d'être
tranchée.

**1. Pas une media query (règle 10).** Une media query mesure la fenêtre du **périphérique**, pas
la place dont dispose la mise en page. Sur une tablette de 1000 px au plus grand réglage de
texte, la place réelle vaut 769 px et la media query répond 1000 : la barre se déplierait dans
une largeur qu'elle n'a pas, en `nowrap`, donc en débordement **silencieux** — exactement ce que
la règle 10 existe pour empêcher, et que le `nowrap` qu'on vient de poser aggrave. Le seuil passe
donc par `html.zw1200`, posée par `syncZoomWidth()` à partir de `innerWidth ÷ zoomF()`.

**2. Pas 560 px.** Mesuré : la barre **dépliée** réclame **757 px de largeur utile** (compte 58 +
segment 221 + Bibliothèque 121 + Catégorie 104 + Supprimer 107 + filet + Annuler 77 + six écarts
+ rembourrage). Les renommages de la consigne 5 y sont pour beaucoup — « Bibliothèque… » et
« Catégorie… » coûtent 33 px de plus que « Déplacer… » et « Ranger… ». À 560 px de fenêtre la
barre n'a que 514 px : dépliée, elle débordait de **179 px**, le compte écrasé à ZÉRO et tronqué.
La maquette 20b tient parce qu'elle se dessine à 744 px de **barre** ; à 744 px de **fenêtre** la
barre en fait 698.

**3. Et la largeur de la barre n'est pas monotone en largeur de fenêtre.** À 780 px, la colonne de
gauche de l'accueil apparaît et lui prend **224 px d'un coup** : mesuré, la barre tombe de 698 px
(fenêtre 744) à **474 px** (fenêtre 780), et ne repasse 698 qu'à 1000. Aucun palier ne peut donc
être choisi « au plus juste » — il faut celui à partir duquel la barre est large **partout**
au-dessus. Mesures : fenêtre 1000 → barre 694 (insuffisant) ; 1100 → 794 ; 1200 → 894. Le palier
est **1200**, déjà déclaré dans l'échelle fermée, avec 137 px de marge.

**CONSÉQUENCE ASSUMÉE** : sur une tablette et sur beaucoup d'ordinateurs portables, la feuille
n'est pas le détour que la planche annonçait — c'est le régime normal. C'est le prix des
intitulés entiers, et il se paie volontiers : l'alternative mesurée était un compte rogné.

**`@container`, qui mesurerait la vraie contrainte, reste ÉCARTÉ** (règle 10) : `container-type`
implique `contain:layout`, et le projet a déjà payé le piège « fixed dans un ancêtre contenu ».

**COROLLAIRE — `syncZoomWidth()` se repose au REDIMENSIONNEMENT.** Elle ne se posait qu'au rendu
et au réglage de taille du texte : une rotation, une fenêtre tirée, un clavier qui s'ouvre ne
re-rendent rien, et les paliers restaient ceux de la largeur PRÉCÉDENTE jusqu'au rendu suivant —
indéfiniment sur un écran qu'on ne quitte pas. Le trou était latent tant que les paliers ne
servaient qu'au chrome de crise (on n'y arrive pas sans un rendu) ; il devient atteignable dès
qu'une mise en page **vive** en dépend. Coût : une division et cinq `classList.toggle`
idempotents.

**ET 1200 N'EST PAS UN PALIER DE COMPRESSION.** C'est le premier de `ZOOM_W_STEPS` à marquer une
largeur **confortable** plutôt qu'une largeur contrainte, et il est donc posé la plupart du temps.
Dit sur place, pour qu'on ne le lise pas comme ses quatre voisins.

## A229 — sous 430 px : compression, puis départ du segment

**CONSTAT (mesuré après A227).** Le compte étant le seul élément élastique, tout ce qui manque à
la ligne se prend sur lui. À 390 px : réduit à **47 px pour 58 nécessaires** — « 3 cochés »
tronqué, c'est-à-dire **le chiffre de la sélection rogné par les commandes qui agissent dessus**.
À 360 px il ne restait que 17 px, à 320 px zéro et 13 px de débordement.

**DÉCISION, en deux temps, recette v4.23.4 (écarts et rembourrages, jamais un renommage — les
intitulés entiers sont tout l'objet de la planche).**

- **Sous 430 px effectifs** (`html.zw430`) : écarts 8 → 6, rembourrage de barre 10 → 8,
  rembourrage de bouton 12 → 10 (la croix exceptée, qui est carrée). 18 px rendus.
- **Sous 400 px effectifs** (`html.zw400`) : la compression ne suffit plus (337 px nécessaires
  pour 314 disponibles à 360 px de fenêtre, 274 à 320). **Le segment rejoint le tiroir**, qui le
  rejoue comme il rejoue les actes.
  **MAIS SEULEMENT S'IL Y A QUELQUE CHOSE À DÉCOCHER** : à zéro coché il n'y a pas de tiroir (la
  touche d'actes n'existe qu'à partir d'une coche), et le segment est alors la SEULE commande de
  la barre. L'y retirer laisserait un mode de sélection dans lequel on ne peut RIEN cocher.

**LE TIROIR NE NOMME AUCUN PALIER.** Il demande au DOM si le bouton est **rendu**
(`offsetParent` nul sous un ancêtre `display:none`, et aucun de ces boutons n'est `fixed`,
l'autre cas où il l'est). La feuille de style reste seule juge de la largeur ; le jour où le
palier bouge, la ligne suit sans qu'on y touche.

Mesuré après correctif, à zéro comme à plusieurs cochés, de 320 à 1440 px : **hauteur 56 px,
débordement 0, un seul rang, compte jamais tronqué.**

## A230 — les libellés disent ce qu'ils déclenchent, et la fermeture se dit dans le compte

- **« Tout » → « Tout cocher », « Aucun » → « Tout décocher »** (consigne 4). Un adjectif seul
  n'annonce pas ce qu'il déclenche, et « Aucun » se lisait d'abord comme un compte. En replié la
  barre n'en montre qu'**un**, celui qui a un sens dans l'état courant (`data-sel="all|none"` +
  `data-n` sur la barre) : c'est ce qui laisse la place à la touche d'actes sans rien abréger.
- **Les actes nomment leur DESTINATION, pas le geste** (consigne 5) : « Déplacer… » et
  « Ranger… » étaient deux verbes voisins qui ne disaient ni ce qu'on déplace ni où l'on range.
  Sur la ligne : **« Bibliothèque… »**, **« Catégorie… »**, « Supprimer… ». Dans la feuille, où
  la largeur ne coûte rien, la phrase entière : « Déplacer vers une bibliothèque… », « Ranger
  dans une catégorie… », « Supprimer les N éléments… ».
  **UN SEUL NOM ACCESSIBLE PAR ACTE** : celui de la feuille, repris en `aria-label` sur le bouton
  court. Les intitulés longs sont écrits une seule fois (`SEL_ACTES`, `selDelLabel`).
- **Les `title` longs sont RETIRÉS** — un intitulé qui se suffit ne se double pas d'une infobulle
  (0 `title` dans la barre, vérifié).
- **« Catégorie… » fermée sur bibliothèques mêlées : le motif se dit DANS LE COMPTE** (consigne 7)
  — « 3 cochés · deux bibliothèques ». Un `title` n'existe pas au doigt, et en replié le bouton
  vit dans la feuille, où aucune infobulle ne se survole. Le mot plutôt que le chiffre : deux
  nombres collés (« 3 · 2 ») se lisent comme un seul.
  ⚠ **CET ÉTAT EST UNE CEINTURE, PAS UN CAS D'USAGE ATTEIGNABLE** aujourd'hui — la liste d'accueil
  ne montre jamais qu'une bibliothèque à la fois, et `_selScope` ferme le mode au changement de
  périmètre. Il est exercé à la FONCTION (`selBarHtml`), pas par l'interface ; le dire ici évite
  qu'on le croie couvert par un parcours.
- **Le filet de « Supprimer… » passe à `--ctl-line`** (consigne 8) : `--critical-line` est un rose
  pâle à 1,4:1 sur la matière blanche et ne tient pas 1.4.11 — justement sur la commande dont le
  contour doit se voir. Le rouge reste dans l'**encre** et le **fond**. Mesuré après correctif :
  filet 3,41:1 en clair et 3,33:1 en sombre ; encre 6,33:1 et 7,16:1.
- **Dépliée, la ligne se lit en deux groupes** : ce qui décrit la sélection (compte + segment) à
  gauche, ce qui agit sur elle à droite, séparés par une marge automatique sur le segment — **pas**
  par une entretoise (la maquette 20b en dessine une ; la consigne 1 la proscrit, et c'est la
  consigne qui a raison). Le compte cesse alors de POUSSER (`flex:0 1 auto`) sans cesser de
  CÉDER : il reste le seul élément qui rétrécit.
- Le tiroir porte un **rappel de contexte** (`opts.head` de `openPickMenu`, nouveau) : le compte et
  sa portée, redits avant tout acte. ⚠ `head` est du **HTML brut** — c'est l'APPELANT qui échappe
  (règle 4), puisqu'il compose des balises.

## Témoin

`audit-doctrine.mjs`, section **« SÉLECTION · une ligne, 56 px, à tout écran et dans tout état
(planche 20) »** — 320, 390, 560, 744, 1200 et 1280 px, à zéro comme à plusieurs cochés :

- `offsetHeight === 56` (la consigne 9, mot pour mot) ;
- aucun débordement horizontal (`scrollWidth <= clientWidth`) ;
- **un seul rang** (tous les objets visibles centrés sur la même bande — une hauteur juste ne
  prouve pas une ligne juste : une barre peut tenir 56 px en ROGNANT son contenu, et c'est
  précisément le défaut silencieux que ce dépôt s'interdit) ;
- le compte jamais tronqué ; cibles ≥ 40 px ;
- à zéro coché, la touche d'actes **n'est pas rendue** ;
- **le palier se franchit réellement** : les trois actes sur la ligne à partir de 1200 px, la
  touche d'actes en dessous — sans quoi un vert ne dirait que « la barre tient », y compris si
  elle tenait en n'affichant jamais ses actes.

**Vérifié capable d'échouer** (leçon v4.31.1), dans les deux sens : il a trouvé de lui-même le
piège de cascade `.btn.sm{min-height:38px}` (déclarée plus bas, même spécificité — 38 px mesurés
là où 40 étaient écrits, d'où `.sel-bar .btn.sm` à (0,3,0)) ; et l'état d'avant la planche
(`flex-wrap:wrap` + rembourrage vertical) le passe au rouge sur les six largeurs. Fichier restauré
à l'octet après l'essai.

---

## A231 — le plan de vol du moniteur tient à plusieurs minuteurs

**SIGNALÉ À L'USAGE (21/08/2026)** : « bug mode moniteur : lorsque plusieurs minuteurs, timeline
ne s'affichent plus ». Reproduit et mesuré avant d'être touché.

**CONSTAT — DEUX DÉFAUTS, UN SEUL SYMPTÔME.** Toutes les étiquettes d'échéance vivaient au même
`top:8px` sur une ligne unique de 32 px, chacune ancrée à gauche de sa marque et en `nowrap` :

- à quatre minuteurs qui tournent, mesuré à 390 px de large, **quatre chevauchements deux à deux**
  — les libellés se peignaient les uns sur les autres, illisibles ;
- et **deux étiquettes entièrement hors de l'écran** (bords droits à 408 et 438 px pour 390
  disponibles). Elles ne s'affichaient plus, au sens propre.

Sur un afficheur qu'on lit à deux mètres, c'était une bouillie. **Un minuteur seul n'a jamais
montré le défaut** : la bande ne paraît qu'à partir de DEUX objets à relier — d'où « lorsque
plusieurs minuteurs ».

**POURQUOI AUCUN TÉMOIN NE L'A VU.** `monBandData` est pure et couverte par onze témoins, tous
verts. Ils n'exerçaient **qu'un seul minuteur à la fois**, et surtout : aucune fonction pure ne
peut voir que quatre étiquettes se peignent au même endroit. Le défaut était **géométrique**.
C'est la leçon de ce lot — un jeu de témoins qui ne rencontre jamais la pluralité ne prouve rien
sur elle, et une propriété de mise en page se mesure dans un navigateur ou ne se mesure pas.

**DÉCISION — UNE ÉCHÉANCE PAR RANGÉE, SUR LE MÊME AXE.** Deux marques alignées verticalement se
lisent alors comme une simultanéité, ce que la bande existe précisément pour montrer ; la ligne de
« maintenant » traverse toutes les rangées et les tient ensemble. Trois conséquences :

- **L'étiquette bascule à gauche de sa marque passé la moitié de l'axe** : elle grandit toujours
  vers le CENTRE, donc elle ne peut plus sortir de la bande. La garantie est arithmétique et non
  espérée : un libellé est borné à 18 signes (~115 px à 12 px gras) contre 142 px de demi-bande à
  320 px, le plus étroit servi. Le filet change de côté avec elle, sinon la marque ne désignerait
  plus l'instant.
- **Les tours projetés appartiennent désormais à LEUR minuteur** (`dated[].ghosts`) et non plus à
  un tas commun : avec plusieurs minuteurs, un tiret anonyme sur la ligne ne disait plus de qui il
  était le tour suivant — l'information exacte que la bande porte. `monBandData` ne rend donc plus
  de champ `ghosts` de premier niveau.
- **Aucun écart tu** : au-delà de ce que la hauteur permet, la bande garde les échéances les plus
  PROCHES (`dated` est trié) et **dit combien attendent derrière** (`.mb-plus`).

## A232 — corriger une collision horizontale en ouvrait une verticale

**LE CORRECTIF D'A231 A POSÉ SON PROPRE DÉFAUT, et il a fallu le mesurer pour le voir.** La bande
est `flex:none` au-dessus d'un `.mon-main` qui, lui, cède : à quatre rangées sur un téléphone
**couché**, le grand chiffre — l'objet primaire de l'afficheur — se faisait recouvrir de **44 px**
(844×390 ; 54 px à 667×375). En portrait, rien ne paraissait. Le portrait seul aurait signé un
correctif qui déplaçait le défaut au lieu de le fermer.

**DÉCISION — ON MESURE LA PLACE, ON NE DEVINE PAS UN PALIER DE HAUTEUR.** `monPlace` calcule, à
chaque rendu, ce qui reste une fois posés l'en-tête, le pied et ce que `.mon-main` porte **en plus
du chiffre** ; il en déduit le nombre de rangées, puis rend au chiffre tout le reste via
`--mon-vmax`. L'ordre des deux décisions est ce qui évite la boucle : on réserve d'abord le
PLANCHER de 64 px du chiffre (celui de son `clamp`, intouchable), on compte les rangées, on rend
le solde. **Le grand chiffre cède parce qu'il est primaire** : un chiffre recouvert ne se lit pas
du tout, un chiffre plus petit se lit encore très bien à deux mètres (mesuré : 120 → 71-78 px en
paysage, jamais sous 64).

**TROIS ERREURS DE MESURE, TOUTES ATTRAPÉES PAR LA MESURE ELLE-MÊME** — elles valent d'être
écrites, parce que chacune rendait un calcul juste en apparence :

1. **`scrollHeight` d'un conteneur ÉTIRÉ vaut sa boîte, pas son contenu.** `.mon-main` est
   `flex:1` : lire son `scrollHeight` faisait s'effondrer la place libre, et la bande tombait à
   deux rangées là où 534 px restaient. On additionne ses enfants.
2. **`clientHeight` COMPREND le rembourrage**, et celui-ci porte `env(safe-area-inset-*)` — au
   moins 28 px, davantage sur un appareil à encoche. Les enfants vivent dans la boîte de CONTENU :
   le calcul s'offrait 28 px qui n'existaient pas, et le recouvrement revenait (19 px à 844×390).
3. **Un minuteur ÉCHU ajoute une TROISIÈME ligne** à `.mon-main` (« △ échu — à réévaluer »). Ne
   réserver que l'étiquette laissait 8 px de recouvrement dans ce seul cas — que ma sonde à la
   main n'avait pas, et que le témoin d'audit a trouvé.

Corollaire de méthode : **tout en `offset/clientHeight`, jamais en `getBoundingClientRect`** pour
ce calcul — sous le réglage de taille du texte (`zoom` sur `<html>`), le premier rend des pixels
de MISE EN PAGE et le second des pixels PEINTS ; les mélanger comparerait deux unités (règle 10).

## Témoin (A231-A232)

`audit-doctrine.mjs`, section **« MONITEUR · la bande de temps tient à plusieurs minuteurs »** —
deux jeux (six minuteurs qui tournent ; deux datés + une pause + un échu) × quatre géométries dont
**deux en paysage** (320×844, 390×844, 844×390, 667×375) :

- aucune étiquette n'en recouvre une autre ;
- aucune étiquette hors de la bande ni de l'écran ;
- **la bande ne recouvre pas le grand chiffre**, et celui-ci garde son plancher de 64 px ;
- les tours projetés appartiennent tous à un minuteur nommé ;
- ce qui ne tient pas est **compté à l'écran**.

Le paysage est dans la table à dessein : c'est la seule géométrie où A232 se manifeste.
**Vérifié capable d'échouer** : le défaut d'origine réintroduit (étiquettes au même `top`, ancrage
toujours à gauche) rougit les deux familles de contrôles sur les quatre géométries ; `index.html`
restauré à l'octet. Deux témoins de pluralité ont aussi rejoint `tests.html` pour la fonction pure
— c'est le cas qui manquait.

---

# Lot v5.17.4 — quatre défauts signalés à l'usage (A233 à A236)

> Quatre retours d'usage, sans rapport entre eux sauf un : chacun est un écran qui **affirme
> quelque chose de faux** — un pied qui dit « sur cet appareil seulement » alors que la
> synchronisation tourne, une décision qui ne montre qu'une de ses deux branches, un bouton grisé
> qui invoque la mauvaise cause, un dialogue où la première frappe d'Entrée annule au lieu de
> valider. Aucun ne plante ; tous les quatre se lisent comme une panne.

## A233 — l'état volatil se relit à la PEINTURE, jamais à la mesure

**SIGNALÉ.** « Lorsqu'on se connecte, “sur cet appareil seulement” en bas de la page s'affiche
toujours jusqu'à ce qu'on recharge la page. »

**CAUSE.** `storageState()` est PURE et lit un instantané `_stgSnap`, produit par
`updateStorageInfo()` — une mesure ASYNCHRONE (`navigator.storage.estimate`) rejouée au
chargement, à l'enregistrement d'une fiche et au rendu des vues de lecture. `signed` y était figé
**au moment de la mesure**. Or la connexion ne rejoue rien quand l'espace local ne bascule pas :
reconnexion au MÊME compte, ou déconnexion depuis une vue qui ne re-rend pas la bibliothèque. Le
pied continuait donc d'annoncer « copie unique · non protégé » à quelqu'un dont les fiches
partaient déjà dans le cloud — c'est-à-dire l'inverse exact de la vérité, sur la seule ligne de
l'écran qui répond à « suis-je à l'abri ? ».

**CE QUI EST FAIT, ET POURQUOI C'EST LÀ.** Le remède existait déjà à côté, pour le réseau : D7
relit `navigator.onLine` **à la peinture**, parce qu'il change bien plus souvent que le stockage.
La présence d'un compte est de la même nature — un état volatil, pas une mesure coûteuse. On la
relit donc au même endroit (`paintStorage`), et `setSyncChip()` — **le seul point de passage commun
à la connexion ET à la déconnexion** — appelle la peinture. Aucune mesure n'est relancée : deux
`innerHTML` de libellé.

**LA RÈGLE GÉNÉRALE, PUISQU'ELLE VAUT AU-DELÀ D'ICI** : dans un instantané mesuré, tout champ qui
peut changer SANS nouvelle mesure n'a rien à y faire — il se relit à l'affichage. Le confondre
avec les champs coûteux (usage, quota, poids des documents) est ce qui a produit ce défaut.

## A234 — une décision montre TOUTES ses branches, y compris celles qui n'ont pas de bloc

**SIGNALÉ.** « Le parcours (avant début de session, et dans la barre latérale gauche sur
ordinateur ou en bas sur téléphone) s'affiche mal pour les blocs conditionnels : uniquement
certains s'affichent. »

**CAUSE, ET ELLE N'EST PAS UN CAS TORDU.** `flowPlan` indente les branches d'une décision sous leur
option et reprend le tronc au **point de convergence** (post-dominateur immédiat). Quand une option
mène DIRECTEMENT à ce point de convergence — le cas le plus ordinaire qui soit : « oui → on
continue, non → détour » —, elle n'a **aucune rangée à elle** : le plan la rend en un seul `link`.
Or `ovPlanLadderHtml` gardait l'étiquette de branche en attente (`pend[depth]`) jusqu'à ce qu'une
rangée de BLOC la consomme, et `brclose` l'effaçait. La branche disparaissait donc entièrement.

Mesuré sur l'aide d'exemple « Accouchement inopiné » : la décision « Imminence » affichait
« NON — TRANSPORT » et **rien** pour « OUI — SUR PLACE » ; idem pour « État du nouveau-né ». Une
décision à deux issues qui n'en montre qu'une ne se lit pas comme un raccourci, elle se lit comme
un rendu à moitié fait — et dans une colonne d'ORIENTATION, une branche cachée est une branche
qu'on ne saura pas prendre (c'est déjà l'argument de l'enroulement des renvois, v4.55.3).

**CE QUI EST FAIT.** La colonne écrit l'étiquette **et** dit où la branche mène (`.pl-jmp` :
`→ 4 Suite commune`, `↺ 2 …`, `▪ fin`). Ce n'est pas une grammaire nouvelle : la vue « Parcours »
de « Tout voir » (`ovParcoursHtml`) le faisait DÉJÀ, avec `.pc-jmp` — les deux vues divergeaient en
silence, et c'est la plus consultée des deux qui avait tort. Le renvoi reste **inerte** : le saut
tapable vit sur la rangée de la décision juste au-dessus (`.pl-ref`), et deux cibles pour un même
saut se disputeraient le doigt dans une colonne de 223 px. Les liens qui SUIVENT une rangée restent
tus — la colonne de renvois de cette rangée les porte déjà.

## A235 — un cran fermé dit POURQUOI, et le tap répond

**SIGNALÉ.** « Avec le mode direct il est possible de partager des sessions même sans compte
connecté. Mais quand on clique sur “En ligne” (qui est grisé, et c'est normal), on ne sait pas
pourquoi ça ne fonctionne pas : il faudrait une phrase d'erreur du genre “compte nécessaire pour
partage en ligne”, et expliquer comment fonctionne le partage direct/hors ligne — valable aussi si
connecté. »

**DEUX DÉFAUTS, ET LE SECOND EXPLIQUE LE PREMIER.**

1. **La légende ne connaissait qu'une cause.** Le cran « En ligne » est fermé si
   `!Auth.signedIn() || !joignable` — deux réalités —, et la légende disait invariablement
   « “En ligne” reviendra avec internet ». Sans compte, c'est **faux** : attendre le réseau
   n'apportera jamais rien. Le bandeau de la feuille d'appariement faisait la même erreur
   (« Pas d'internet — partage en direct »). Les deux disent désormais la cause exacte.
2. **`disabled` n'émet aucun évènement.** Le seul geste qu'on fait pour comprendre — taper le cran
   — ne produisait littéralement rien. Le cran passe donc en **`aria-disabled`** : même apparence,
   toujours annoncé fermé aux lecteurs d'écran, focalisable au clavier, et le tap **répond**.

**CE N'EST PAS UN RECUL SUR LA DOCTRINE DU « FERMÉ », C'EST SON PROLONGEMENT.** La règle du dépôt
est « un bouton grisé n'est acceptable que si une ligne voisine dit pourquoi » (v4.79.0,
`syncBtnRefresh`). Ici la ligne voisine existait et **se trompait de cause** : la rendre exacte
était nécessaire, pas suffisant — sur un écran d'urgence, on tape avant de lire une légende de
11 px. La réponse au tap (`slCloudWhy`, snackbar `direct:true` — une RÉPONSE à un geste, jamais une
nouvelle de fond, cf. v4.55.4) dit la cause **puis les deux chemins qui marchent** : « En direct »
relie les appareils par un code à scanner sans serveur, « Par l'écran » passe par la caméra sans
aucun réseau. Cette seconde moitié vaut aussi pour qui EST connecté — c'était la demande.

## A236 — les dialogues se conduisent au clavier, avec le comportement système

**DEMANDÉ.** « Rendre les boutons des fenêtres de dialogue navigables au clavier (confirmer une
action, supprimer une fiche/aide/protocole, arrêter une session, et toutes les fenêtres de ce
type) : Tab pour passer d'“Annuler” au bouton d'action, Entrée pour valider. Implémentation
système native, reste simple, ne complexifie rien. »

**CE QUI EXISTAIT DÉJÀ, ET QU'IL NE FALLAIT PAS RÉÉCRIRE.** Le piège Tab, Échap, le retour du focus
au déclencheur et l'activation d'un bouton par Entrée sont en place depuis la v4.21.0 — les trois
derniers sont d'ailleurs le comportement NATIF de `<button>`. Le trou était ailleurs : le
gestionnaire posait le focus d'ouverture sur le **premier** élément focalisable, c'est-à-dire
presque toujours la croix de fermeture. La première frappe d'Entrée **fermait** donc la fenêtre, et
l'on n'atteignait « Confirmer » qu'après deux Tab. Vu de l'usage : « le clavier ne marche pas dans
les dialogues ».

**DEUX RÈGLES, AUCUN COMPOSANT NOUVEAU.**

- **Le point d'entrée.** Une fenêtre peut le désigner (`data-dlgfocus`) ; à défaut on prend le
  premier focalisable qui n'est PAS la croix — et la croix seulement s'il n'y a rien d'autre.
  `confirmDlg` s'en sert pour poser le focus sur **l'action** quand elle est ordinaire, et sur
  **« Annuler »** quand elle est destructrice (`danger`) ou encore fermée par une case
  (`checkRequired`). C'est la convention système, et elle a ici une raison de plus : un Entrée
  réflexe ne doit jamais supprimer une fiche ni arrêter une session.
- **Le bouton par défaut.** `data-dlgdef` (porté par `#confirmYes`) est déclenché par Entrée
  **seulement** quand le focus n'est pas déjà sur un contrôle dont Entrée a son propre sens (autre
  bouton, lien, champ, liste). On n'écrase donc aucun geste natif : on comble le seul trou, la case
  à cocher et le corps de la fenêtre. Un bouton fermé n'est jamais déclenché — le verrou
  `checkRequired` tient au clavier comme à la souris.

**CE QUI N'A PAS ÉTÉ FAIT, ET POURQUOI.** Pas de `<dialog>` natif ni de `<form method="dialog">` :
la migration toucherait les 22 fenêtres, leur CSS, le verrou de fond et le retour système, pour un
gain nul sur ce qui était demandé. Et **`#endSessModal` n'a pas de bouton par défaut** : sa
première touche est « Poursuivre » (l'action sûre) et « Terminer » reste à un geste délibéré —
arrêter une session est l'action la plus lourde de l'app.

## Témoin (A234)

`audit-doctrine.mjs`, section **« Parcours inerte · une décision montre TOUTES ses branches »** :
une fixture minimale au graphe ORDINAIRE (départ → décision → {tronc commun, détour qui reboucle})
et un invariant indépendant du dessin — **le nombre d'étiquettes de branche affichées vaut le
nombre d'options de la décision** —, plus le renvoi de la branche sans rangée. **Vérifié capable
d'échouer** : le défaut réintroduit rend « 1 étiquette pour 2 options » ; `index.html` restauré à
l'octet. A233, A235 et A236 ont été mesurés par une sonde jetable (focus d'ouverture, Tab, Entrée,
Entrée sur bouton fermé, bascule du pied sans rechargement, cause et réponse du cran fermé), verte
sur **les deux moteurs** — elle n'a pas été gardée : ses invariants tiennent au comportement natif
du navigateur, pas à une géométrie qui dérive.

## A237 — l'anneau de focus d'une fenêtre se pose à la main (v5.17.5)

**SIGNALÉ, le lendemain de A236.** « Bug dialogues au clavier : je ne sais pas quel bouton est
sélectionné, et surtout ça paraît inconstant. »

**CAUSE, MESURÉE SUR LES DEUX MOTEURS ET CINQ FENÊTRES.** `:focus-visible` n'est pas un état, c'est
une **heuristique du navigateur** : sur un focus **programmatique** — celui que pose l'ouverture
d'une fenêtre —, elle ne s'allume que si la dernière interaction était au clavier. Ouvrir un
dialogue **à la souris**, c'est-à-dire le geste réel neuf fois sur dix, ne montrait donc **aucun
anneau** ; l'ouvrir juste après une frappe clavier en montrait un. Le même dialogue, deux
apparences, et dans la plus fréquente rien à l'écran ne disait ce qu'Entrée allait faire. A236
avait donné le bon focus **sans le rendre visible** — un état juste, invisible, est indiscernable
d'un état absent.

Le dépôt connaissait déjà ce piège **dans l'autre sens** : `audit-a11y` (v4.40.0) a dû passer aux
vraies frappes Tab parce qu'un `.focus()` programmatique ne déclenche pas `:focus-visible` et
produisait des faux positifs en série. La même propriété produit ici un écran muet.

**⚠ ET LA PREMIÈRE MESURE A MENTI.** Une sonde « y a-t-il un anneau ? » qui accepte
`box-shadow !== none` déclare marqué… `.btn.primary`, qui porte une **élévation permanente**. Le
seul bouton qui semblait indiqué était précisément celui qui ne l'était pas, et la conclusion
inverse (« le ring marche ») a tenu une passe entière. **Un anneau de focus se lit sur `outline`,
jamais sur l'ombre** — c'est de la même famille que « `check-colors` et `check-type` travaillent au
motif et ne voient pas une règle disparue » : une sonde permissive est pire qu'aucune sonde.

**CE QUI EST FAIT.** `_dlgEnter` pose la classe `.dlg-ring` sur le **seul** élément qu'il focalise,
et l'ôte au premier `blur` : au geste suivant, `:focus-visible` reprend la main **avec le même
dessin**, donc l'utilisateur ne voit aucune bascule.

**CE QUI A ÉTÉ ÉCARTÉ, ET POURQUOI.** Un `:focus` nu en cascade sur toute la fenêtre
(`.ai-modal :is(button,[tabindex]):focus`) aurait été plus court d'une ligne et **faux** : à
(0,3,0) il bat les anneaux accordés à leur fond — `.chip-edit` sur aplat primaire, `.ds-x` sur
matière système, tout ce qui vit sur du sombre — où un anneau `--primary` disparaît purement et
simplement. C'est la famille des pièges de cascade du dossier ; on marque **un** élément, pas une
sous-arborescence. `element.focus({focusVisible:true})` a été écarté aussi : Firefox seul
l'implémente, ni Chromium ni WebKit — donc rien sur la cible principale.

**CE QUI RESTE VOLONTAIREMENT DIFFÉRENT D'UNE FENÊTRE À L'AUTRE** : le focus va sur l'**action**
pour une confirmation ordinaire et sur **« Annuler »** pour une confirmation destructrice (A236).
Ce n'est plus une inconstance depuis que l'anneau se voit — c'est la convention système, et elle
se **lit** : on sait, avant de frapper Entrée, si l'on va valider ou renoncer.

## Témoin (A237)

`audit-doctrine.mjs`, section **« Fenêtres · le bouton focalisé se voit, même ouvert à la
souris »** — trois fenêtres (confirmation ordinaire, confirmation destructrice, fenêtre Compte),
chacune ouverte **après un vrai geste souris** : c'est lui qui met le navigateur dans l'état où le
défaut existe, et une sonde qui l'omet mesure un écran qui n'existe pas. La sonde ne lit que
l'`outline`. Elle vérifie aussi qu'**aucun anneau ne reste collé** après la fermeture.
**Vérifiée capable d'échouer** : marquage neutralisé → deux contrôles rouges, dont le cas
discriminant (la première fenêtre, ouverte à la souris) ; `index.html` restauré à l'octet.
