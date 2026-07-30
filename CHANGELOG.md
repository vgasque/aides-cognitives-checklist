# Journal des modifications

## [4.76.0] — 2026-07-30
### Lot 3 : la porte devient celle de l'aide entière

#### La porte « ＋ » quitte « Prise en charge »
Signalé à l'usage : *« le bouton s'arrête avant les blocs minuteurs & compteurs, repères
posologiques, schémas et captures, documents PDF… ce qui n'est pas logique »*. Le constat était plus
juste encore que sa formulation : la porte créait **déjà** des minuteurs, des compteurs, des
complications et des repères posologiques, tout en vivant **à l'intérieur** du fieldset « Prise en
charge ». Ce n'était donc pas une porte de bloc, c'était la porte de l'aide, mal rangée.

Elle sort du fieldset, se pose à la fin du formulaire, colle sur toute sa hauteur, et se répartit en
quatre groupes dans l'ordre de **lecture** de la fiche : Structure · Pendant la session · Contenu
clinique · Annexes. Nouvelles entrées : « À vérifier », « Diagnostic différentiel », « Référence »,
« Schéma ou capture ».

**Elle redescend dans le flux pendant un déplacement** (`.ed-door.flat`) : collée, elle masque le
dernier « Poser ici », et « créer » n'a rien à faire sous le doigt de quelqu'un qui cherche où
**poser**.

**Le dessin répond à « peu identifiable »** : le pointillé reste (grammaire de « créer », inchangée
depuis la v4.3.0) mais sur un fond **tonal** au lieu du blanc — le blanc était la couleur de toutes
les cartes autour d'elle, donc son seul trait la distinguait ; le « ＋ » entre dans une pastille
ronde ; un filet haut la détache du flux, ce qui rend son comportement collant lisible sans qu'on
ait à le deviner. **Elle reste tonale, jamais remplie** : l'unique bouton rempli de l'écran demeure
« ▶ Essayer ».

#### Une règle nouvelle, et ses deux exceptions nommées
**« Présent dans la porte ⇔ masqué quand vide ».** « À vérifier », « Diagnostics différentiels »,
« Références », « Repères posologiques », « Schémas & captures » et « Documents » disparaissent quand
ils sont vides et se recréent par la porte, avec le focus dans le champ neuf.

**Deux exceptions** : le chapeau « Ne pas oublier » et la « Confirmation diagnostique » restent
affichés même vides, et n'ont donc **pas** d'entrée dans la porte. Ce ne sont pas des extras : en
QRH, la condition d'entrée et les memory items sont ce qui rend une checklist **sûre**. Un champ vide
y est une **invitation** — la règle « un panneau vide est du bruit » vise ce qui *affirme* quelque
chose (« 0 remarque »), pas un champ qui attend du texte. Un auteur qui ne **voit** pas « Ne pas
oublier » ne l'inventera pas.

« Étape » n'entre pas dans la porte : un « ＋ » = une **portée**, et l'étape a la sienne, entre les
blocs, plus le ⏎ (MK-flux). Piège résolu au passage : `_edImgMode` a dû monter au module, la porte
devant ouvrir le sélecteur de fichier alors que la section « Schémas » est masquée — donc son bouton
absent.

#### Une image s'associe à un bloc depuis la galerie
On ne pouvait joindre une image que **depuis** un bloc : partir de l'image était impossible, alors
que c'est l'ordre naturel quand on vient d'en importer trois. Un sélecteur par vignette liste les
blocs, montre celui qui la porte, et « Aucun bloc » la détache. **Une image ne peut être que sur un
seul bloc** : on détache partout avant de rattacher, sinon deux sélecteurs afficheraient deux
porteurs pour un même état.

**Ce que cela copie, et il faut le savoir** : `b.image` porte la **donnée**, pas une référence —
c'est le format existant, et le changer serait un champ modèle de plus (règle 12) que les clients
antérieurs ne sauraient pas lire. Associer duplique donc l'image, et retoucher la vignette de la
galerie **après** coup ne suivra pas dans le bloc.

#### Le placard de l'essai est une hachure, et rien d'autre
Signalé à l'usage : *« le mode essayer ne se distingue pas beaucoup d'un mode fiche normal »*. Et le
« rien d'autre » est le vrai contenu de la décision. La v4.72.0 avait retiré l'étiquette de bandeau
parce qu'elle répétait mot pour mot la pilule de la barre ; **vérifié à l'écran, la barre porte déjà
les deux énoncés** — la pilule « ■ Aperçu » *et* le badge « Essai — rien n'est enregistré ». Les mots
sont donc couverts deux fois ; ce qui manquait était le canal **périphérique**, celui qui se
reconnaît sans lire. On n'ajoute donc que la **texture**. La règle 8 (« la couleur n'est jamais
seule ») est tenue par la barre, permanente et immobile — pas par une troisième copie de la phrase.
Bénéfice mesuré : **coût nul en hauteur et en largeur**, alors qu'une étiquette de trente caractères
repoussait le titre sur deux lignes à 400 px.

Hachure **neutre** (`--surface-3`), registre MEMO : le bleu est pris par l'invité et par l'exercice,
et un essai d'auteur n'est ni un rôle ni une répétition clinique. La justification a changé de poids
depuis K5 : « ▶ Essayer » déroule une **vraie** session (les minuteurs tournent, on coche, le chrono
avance), donc l'écran ressemble trait pour trait à un soin — le risque n'est plus esthétique, c'est
croire qu'une session est en cours ou qu'elle est enregistrée. L'exercice garde la priorité.

#### Douzième piège de cascade : une couleur aussi se vérifie
Trouvé en posant le placard d'essai à côté de celui de l'invité. `#crisisBand .cb-tag` vaut
**(1,1,0)** et écrasait le bleu du placard invité, écrit `.cb-tag.inv` = (0,2,0) : **« ▪ Vous
suivez » s'affichait en rouge depuis la v4.55.4**, sur un cadre bleu, dans le seul registre qu'elle
ne devait pas emprunter. La règle d'exercice, elle, était déjà préfixée par `#crisisBand` et gagnait
— d'où deux placards jumeaux dont un seul avait la bonne couleur.

Corollaire : la doctrine « pour une **géométrie**, ne jamais dépendre de l'ordre de déclaration »
vaut aussi pour les **couleurs**. Un témoin d'`audit-partage` compare désormais l'encre **résolue**
à `--primary-dk` au lieu de l'affirmer.

#### Le compte de relecture monte dans la barre
Le volet-bilan vit en pied de formulaire — c'est sa place, on le lit en fermant — mais rien ne
disait, pendant qu'on écrit, qu'il y avait quelque chose à relire. Le **compte** (« △ n ») rejoint
donc la barre, le seul endroit qui ne défile jamais, et ancre vers le volet **en le dépliant** ; le
détail reste en bas et sous la ligne qu'il vise. Registre ATTENTION, jamais rouge — rien n'est
bloqué, et le volet le dit en toutes lettres. Masqué à zéro remarque.

#### Vérifications
809 tests × 2 moteurs, `npm run check` vert, **seize harnais verts** (`npm run audit` en sortie 0),
a11y **301/301** dans les deux thèmes, doctrine 159/159, `audit-k5` **76/76**, partage **298/298**.
**Vingt-deux nouveaux témoins**, tous vérifiés **capables d'échouer** : masquage-si-vide neutralisé,
porte laissée collante pendant un déplacement, placard désarmé, compte bridé, préfixe `#crisisBand`
retiré → six rouges dans `audit-k5` et un dans `audit-partage` ; fichiers restaurés à l'octet.
La porte vérifiée sans débordement à **320 px** (contenu à 205 px sur 284 disponibles).

## [4.75.0] — 2026-07-30
### Lot 2 : « prendre / poser » s'étend aux listes — et l'aperçu d'algorithme s'entrebâille

#### L'aperçu d'algorithme est entrebâillé, jamais fermé
Demande utilisateur, et l'argument est doctrinal : *« un néophyte de l'application ne verra pas
qu'il existe »*. Un titre replié dit qu'une chose **existe**, il ne dit pas **ce qu'elle est** — et
un schéma est précisément ce qui ne se raconte pas. On en montre donc la tête : 168 px, avec un
fondu vers `--paper`, le fond du **canevas** (c'est le dessin qu'on estompe, pas la page). Assez
pour reconnaître un organigramme, pas assez pour repousser la première étape à écrire.

**Ce n'est plus un `<details>`**, et c'est une contrainte technique, pas un choix : un `details`
fermé ne rend **rien** de son contenu, et révéler un enfant d'un `details` fermé n'est pas fiable
d'un moteur à l'autre (le contenu vit dans un slot du shadow tree). Conteneur ordinaire + vrai
bouton ≥ 44 px, entrebâillement par `max-height`, **aucune transition** (c'est une propriété de
mise en page — `check-anim` l'interdit, et rien ici n'animerait une hauteur), **aucun re-rendu** au
dépliage : le SVG est déjà dans le DOM, donc pas une ligne ne bouge et le zoom garde ses écouteurs.
Mesuré 168 → 618 px, chevron et `aria-expanded` suivis, choix mémorisé, `scrollY` inchangé.

#### « Prendre / poser » s'étend aux huit listes
Les ↑ ↓ étaient un reste d'avant MK5-b — plus lents **et** moins sûrs : dix taps pour remonter une
rangée de dix rangs, un re-rendu à chaque tap. Et surtout, **cinq listes n'avaient aucun moyen de
réordonner** (« À vérifier », « Diagnostics différentiels », « Références », « Ne pas oublier »,
repères posologiques) : elles s'écrivaient dans l'ordre où l'on y pensait, définitivement.

**Une seule sorte `'l'`, adressée par la clé du modèle.** Les listes de chaînes et les listes
d'objets (`timers`, `counters`) se réordonnent par le même `splice` : elles n'ont pas besoin de deux
mécaniques, et un `kind` par type aurait produit huit chemins à tenir. Points d'entrée uniques —
`edGrabRows` enrobe les rangées de leurs interstices, la liste passe son gabarit de rangée et n'a
rien à savoir du déplacement.

**Confiné à sa propre boîte, et cela simplifie au lieu de compliquer** : les interstices ne sont
émis que pour la clé prise, donc un objet ne peut pas changer de contexte — le garde-fou QRH
d'`edGrabIsCrit` (« une étape ⚠ tirée hors de son bloc change de sens ») n'a ici rien à annoncer,
par construction. Il reste réservé aux étapes, qui franchissent des blocs.

Pas de poignée à une seule rangée (aucun bouton mort). Ancrage `keepAnchor` aux deux bouts :
**0 px de dérive à la prise**, mesuré, comme pour les blocs et les étapes.

#### Le glisser amorce le mode — il n'est pas le mécanisme
MK5-b a écarté le glisser comme **mécanisme** pour de bonnes raisons (gants, une seule main,
appareil qui bouge : c'est le point de défaillance du drag au doigt). Mais l'écarter comme
**amorce** était une décision par défaut, jamais raisonnée — or quelqu'un qui essaie de glisser une
poignée fait le geste que tout le reste du monde logiciel lui a appris, et le refuser **en silence**
lui laisse croire que rien n'est déplaçable.

On intercepte donc `dragstart` sur la poignée, on **annule** le glisser natif (pas question d'avoir
deux mécaniques de dépôt) et l'on entre dans « prendre / poser » en réutilisant le **clic** de la
poignée : l'utilisateur apprend le bon geste en faisant le mauvais. `dragstart` n'existe qu'au
pointeur — sur tactile rien ne change, et **aucun `touch-action` n'est posé** sur la poignée : en
poser un empêcherait de faire défiler la page depuis elle, ce qui coûterait plus que ça ne rapporte.

#### Micro-animations du passage en mode déplacement
Les deux idées proposées sont retenues, la seconde avec une borne. Les interstices « Poser ici »
entrent en **fondu cascadé** (22 ms par rang, borné à six — au-delà, un décalage n'informe plus, il
fait attendre) ; l'objet pris fait **une oscillation amortie** ; et le bandeau collant entre par le
haut, dans le sens où il arrive.

**L'oscillation ne boucle pas.** Le mouvement continu est réservé à l'alarme dans cette app (ECAM),
et un objet qui se balance indéfiniment finirait par se lire comme une alerte — or prendre un objet
n'est ni une erreur ni un danger. `transform` et `opacity` seulement, tout sous
`prefers-reduced-motion: no-preference`.

#### `--soft` n'est pas une encre, et la sonde l'a enfin vu
Les trois poignées ⠿ étaient en `--soft` — **2,62:1 mesuré**, sous le seuil AA de 4,5:1 — alors que
la règle est écrite depuis la v4.5 : « `--soft` est décoratif seulement, jamais une couleur de
texte ; texte secondaire = `--ink-soft` ». Le glyphe ⠿ **est** le contenu du bouton.

Le défaut datait de MK5-b et personne ne **pouvait** le voir : les poignées ne vivaient que dans
`.blk`, qui n'est pas dans le SCOPE d'`audit-a11y`. En les posant dans `.list-edit` (lot 2), elles y
sont entrées et la sonde a parlé aussitôt. Leçon de méthode : **un défaut hors scope n'est pas un
défaut absent** — quand un composant déménage, la sonde peut se mettre à voir ce qu'elle ne voyait
pas, et c'est un bon jour, pas une régression.

#### Vérifications
809 tests × 2 moteurs, `npm run check` vert, **seize harnais verts** (`npm run audit` en sortie 0),
a11y **301/301**, doctrine 159/159, `audit-k5` **55/55**. **Seize nouveaux témoins** pour le lot 2
(confinement, ancrage à 0 px, dépôt réellement publié, Échap qui repose sans déplacer, liste
d'objets par le même chemin, glisser-amorce, cascade, oscillation unique), vérifiés **capables
d'échouer** : confinement neutralisé, amorce neutralisée et cascade aplatie → 7 rouges ; fichier
restauré à l'octet.

## [4.74.2] — 2026-07-30
### Lot 1 des améliorations d'éditeur — et un garde-fou qui a trouvé un mort-né

#### Le contrôle qui manquait : une erreur de parse CSS ne disait rien
`npm run check` ne regardait que du JavaScript. Or dans une app monofichier, une erreur de parse
**CSS** est aussi grave et beaucoup plus silencieuse : un fermeur de commentaire en trop laisse du
texte à nu dans la feuille, et le parseur, pour se resynchroniser, **avale la règle suivante**.
C'est arrivé deux fois de suite, sur des commentaires coupés en deux — et la seconde fois, **la
v4.74.0 avait livré un correctif mort** : la règle `.hs-wrap>.hs-row:hover`, celle du survol des
bibliothèques, était mangée par le parseur depuis sa publication, avec `npm run check` vert de bout
en bout. Seule une mesure dans le navigateur l'a montré.

`check-syntax.mjs` vérifie donc maintenant la feuille : commentaires jamais imbriqués et tous
fermés, accolades équilibrées, les chaînes retirées d'abord (une accolade dans un `content:"…"` ne
compte pas). On ne réécrit pas un parseur CSS — on attrape la classe d'erreur qui fait disparaître
des règles sans rien dire. Vérifié capable d'échouer dans les deux sens.

#### Le trou entre deux paliers : 430 → 441 px
Signalé à l'usage (« à 435-440 px, Se repérer et Cons. passent sous Guidé/Statique, puis ça revient
à une ligne si on élargit ou rétrécit un peu »). Le diagnostic est arithmétique : le palier de
compression suivant est à **430**, donc entre 430 et ~441 la rangée n'a plus la place de la recette
large et n'a pas encore **droit** à la recette compressée — et l'enroulement, qui est le dernier
recours de la v4.73.1, y devenait le premier.

**On ne déplace pas le seuil** : les seuils en dur pour cette rangée se sont déjà révélés faux deux
fois, et un seuil juste ici dépendrait de la fonte du système et de la longueur des libellés.
`fitCtrlRow` **mesure** déjà : il descend donc d'un palier, re-mesure, descend encore, et n'enroule
qu'après avoir épuisé la compression. Les classes posées sont **celles de `syncZoomWidth`** — aucune
recette dupliquée, donc rien qui puisse diverger — et elles ne stylent que cette rangée. Témoin :
six largeurs de 429 à 460 px, hauteur de rangée **et** libellés intacts ; défaut réintroduit → rouge
à 431 et 435, exactement la bande signalée.

#### La carte du parcours est une surface
« Pourquoi les étapes de blocs sont de la même couleur que le fond de page et pas en fond blanc
comme les autres blocs ? » — ce n'était pas une décision : `.ov-block` n'avait **aucun
`background`**, quand `.conf-block`, `.local`, `.forget-strip` et les cartes de l'éditeur sont tous
en `--surface`. Rien ne justifiait l'exception, et le précédent existe en sens inverse : la v4.59.0
a mis l'Échelle sur une surface parce qu'elle était « la seule zone de la vue lecture à ne pas être
une surface, ses filets se lisant comme des restes de trait ». C'est la colonne d'**action** : elle
mérite le niveau 2. Les registres ne bougent pas (`.dec` garde son ambre, une étape signalée sa
boîte).

#### Le relief des étapes revient au registre
Chaque étape était en graisse **800** — le poids d'un titre appliqué à un paragraphe : plus rien ne
ressortait, ce qui est mot pour mot le reproche fait à l'inflation du rouge. **600** pour une étape
ordinaire, **800 conservé** pour les seules étapes `⚠`/`△`. Même geste que la v4.73.0 sur les
chronos (700 → 500) et pour la même raison : l'état ne crie pas plus fort que l'action. Le corps ne
bouge pas (16,5 px, palier de l'échelle fermée).

#### L'algorithme de l'éditeur étroit se replie
Mesuré à 820 px : le schéma commence haut (812 px) mais `.flow-scroll` monte à `75vh`, donc on
traversait ~1400 px de préambule avant la première étape à écrire. Il devient un dépliant **replié
par défaut**, avec son compte en sous-titre (« · 4 blocs » — un plafond qu'on voit sans l'ouvrir), et
le choix de l'auteur **persiste** : gabarit exact de `.crit-guide` (v4.31.0), rien à inventer. À
≥ 1000 px le schéma vit dans la colonne collante et n'a pas de dépliant.

#### La bascule guidé ↔ statique garde le bloc courant
Avant : `scrollTo(0,0)`, systématique — et conserver `scrollY` n'aurait rien voulu dire non plus,
les deux vues n'ayant pas la même hauteur. La seule ancre qui **existe des deux côtés** est le bloc
courant, et les deux vues le marquent avec la même classe `.cur`. C'est donc `keepAnchor`, la
mécanique ECAM du projet, appliquée au bon élément : dérive mesurée à **0 px** dans les deux sens.
Deux replis vers le haut, tous deux voulus : pas de session démarrée (rien à retrouver) et bloc
courant hors de l'écran avant la bascule (même test de visibilité qu'`ovAdvanceRender`).

#### « Essayer » est rond
`.hdr-act2` garde `border-radius:18px` pour 36 px de haut — un cercle parfait à 36 px de large, une
pilule à toute autre largeur. Le rembourrage de 10 px laissait ~32 px : plus haut que large, donc un
ovale couché. Largeur fixée à la hauteur, glyphe centré. Passé par un `#id`, les paliers plus
étroits redéclarant `padding` plus bas dans la feuille.

#### Les repères posologiques disent leur classement
C'est exact, et plus fort que demandé : `posoRank`/`posoSplit` **réordonnent selon le bloc en cours
et ne filtrent jamais** — c'est cette garantie qui autorise un rapprochement volontairement
permissif. Un auteur qui l'ignore ordonne ses repères à la main et s'étonne de les voir bouger.

#### L'anneau d'annulation
Le « Annuler » de l'éditeur est parti avec le bouton « Enregistrer » (K5, v4.72.0) : rien ne
défaisait plus une fausse manœuvre, et l'écriture étant continue, une suppression était publiée
avant qu'on ait le temps de la regretter. Bouton « ↶ » contre l'état d'enregistrement (son pendant :
l'un dit ce qui est écrit, l'autre le défait) et **Cmd/Ctrl-Z hors champ de saisie** — dans un champ,
le raccourci reste au navigateur, qui fait l'annulation fine mieux que nous.

**Il empile des points de reprise, pas des commandes**, et il a fallu **mesurer** pour comprendre
qu'il en fallait deux sortes. La première version ne couvrait que les gestes **structurels**, au
motif que les champs texte ont déjà le Cmd-Z natif. C'était vrai, mais la conséquence ne l'était
pas : annuler une suppression après avoir tapé trois mots **rendait aussi ces trois mots**, puisqu'un
instantané pris avant le geste ne peut pas contenir ce qui a été écrit après. La frappe pose donc
son propre point, **à la pause** (une rafale = un point, pas un point par caractère).

**Second défaut trouvé à la mesure** : annuler jusqu'à l'état d'ouverture ne republiait **rien**. La
garde anti-réécriture d'`edTouch` (celle qui évite qu'ouvrir une fiche la marque modifiée) sortait la
première, si bien que la bibliothèque gardait la version modifiée pendant que l'écran affichait
l'originale. L'annulation passe donc par `edCommit` : c'est un geste explicite, il écrit toujours.

**Aucun geste à recenser** : les gestes structurels se terminent tous par un re-rendu de l'éditeur,
la frappe passe toute par `edTouch` — les deux points d'étranglement existaient déjà. **Jamais
persisté, jamais synchro** : c'est un geste, pas un état du brouillon (même statut que
`state.edGrab`). Plafond 20 ; au-delà, ce n'est plus une annulation mais une restauration, et elle a
déjà son outil (« Versions », plus le point de version posé à chaque ouverture).

#### Vérifications
809 tests × 2 moteurs, `npm run check` vert (avec le nouveau contrôle CSS), **seize harnais verts**
(`npm run audit` en sortie 0), a11y 301/301, doctrine 159/159, `audit-k5` 39/39. **Quinze nouveaux
témoins** (huit pour l'anneau, trois pour l'ancrage de la bascule, douze mesures pour la bande
430-441), tous vérifiés **capables d'échouer** : défauts réintroduits un par un, fichiers restaurés à
l'octet.

## [4.74.0] — 2026-07-30
### L'éditeur dit la vérité, et il rend l'écran à ce qu'on écrit

Onze points signalés à l'usage, tous dans l'éditeur ou à sa lisière. Deux sont des indicateurs
qui **mentaient**, les autres de la place et de la lisibilité rendues.

#### L'état d'enregistrement annonçait l'inverse de ce qui se passait
`edCommit` refuse depuis la v4.72.0 d'écrire une fiche **sans titre** — une fiche anonyme n'a pas
de nom sous lequel apparaître, et une rangée « Sans titre » se rangerait sous « # » dans un
répertoire A→Z. Mais il sortait **en silence** : la barre restait sur « ⟳ Enregistrement… » et la
pastille sur « auto-enregistré », c'est-à-dire exactement l'inverse de la réalité. C'est le pire
mode de défaillance d'un indicateur d'état, et celui que ce dossier combat partout ailleurs (la
donnée périmée présentée comme vivante, danger n° 2 du palmarès ECRI 2015).

Deux moitiés, et la seconde était la moins évidente : **il fallait le dire AVANT le test « rien
n'a bougé »**. Quand on ajoute puis supprime, le brouillon revient *exactement* à son instantané
d'ouverture — la garde anti-écriture sortait la première et le badge restait figé sur le
« ✓ Enregistré » de la frappe précédente. L'ordre des deux tests suffisait à produire le défaut.

L'état est donc « ○ Sans titre — rien n'est enregistré » (abrégé « ○ sans titre » sous 560 px,
même troncature du même énoncé que le reste de la barre) et la pastille dit « brouillon gardé —
titre manquant » : registre **neutre**, comme le brouillon — il ne manque rien, il reste un geste
à faire, et le parc protège bel et bien la saisie en attendant.

#### Le dépliant « Identité » se refermait tout seul
Il s'ouvre d'office sur une fiche neuve et reste replié sur une fiche existante — la distinction
se fait sur le **titre vide**. Mais elle était **recalculée à chaque rendu** : `vide` devenant
faux dès la première lettre, le premier geste structurel (ajouter un bloc, changer d'état)
refermait le panneau sous les yeux de l'auteur qui y remplissait encore la catégorie et la date.
L'ouverture se DÉCIDE désormais à l'entrée dans l'éditeur (clé = l'id du brouillon : changer de
fiche redécide, un re-rendu jamais) et le repli n'appartient plus qu'au geste de l'auteur.
Au passage, le premier champ ne se colle plus au filet du sommaire : un en-tête de carte n'est pas
la première ligne du formulaire.

#### La colonne de droite porte l'algorithme, plus une maquette
Demande utilisateur, et le constat découle de K1 : depuis la v4.64.0 la colonne du **milieu** EST
le rendu — le chapeau est le cadre rouge, un bloc est sa carte, une étape est sa rangée. Une
carte-maquette de trois étapes à côté n'ajoutait plus qu'une seconde version, forcément moins
fidèle, de ce qu'on avait déjà sous les yeux. Ce qui, lui, ne se voit nulle part en écrivant,
c'est la **structure** que les blocs dessinent : le schéma monte donc dans la colonne collante,
où il reste sous les yeux pendant qu'on descend les blocs, et libère la hauteur qu'il prenait en
tête de « Prise en charge ». Sous 1000 px, il reprend sa place dans le flux, inchangé.
Il ne se redessine pas à la frappe — c'est le comportement d'avant, pas une régression :
`buildFlowSVG` reconstruit toute la géométrie, et le faire à chaque pause de frappe ferait sauter
le schéma. Toute la **maquette miniature** est purgée avec ses treize classes (règle 14).

#### La porte « + » reste à portée — et elle ne devient pas une zone fixe
La question posée était la bonne. SPEC §5 dit « une seule zone fixe, et en HAUT », et pour les
éditeurs elle dit en propre « **aucun pied d'éditeur** » : un bouton `fixed` en bas de l'écran est
exactement ce que cette ligne interdit, clavier mobile compris. La réponse est donc `sticky` : la
porte reste le dernier enfant de son fieldset, se colle au bas de l'écran **tant qu'on est dans
« Prise en charge »** et se décroche d'elle-même à la fin de la section — bornage natif, comme les
bandes-questions du mode statique. Elle ne prend aucune hauteur de plus, rien ne se décale, et
aucune couche fixe ne s'ajoute au chrome. Fond plein + élévation, sans quoi un bouton transparent
se lirait par-dessus le texte d'un bloc. **Pendant un déplacement, elle redescend dans le flux** :
collée, elle masquait le dernier « Poser ici », et « créer » n'a rien à faire sous le doigt de
quelqu'un qui cherche où poser.

#### K1, le membre qui manquait : quatre listes sans coquille
« Confirmation diagnostique », « Repères posologiques », « À vérifier », « Diagnostics
différentiels » (et « Références », de même nature) étaient à nu sur le fond de page, entre un
chapeau à cadre rouge et des blocs en cartes. En lecture, chacune est une `<section class="block">`
— surface, filet, rayon. La grammaire de la v4.64.0 n'était donc appliquée qu'à moitié, et une
moitié de grammaire n'en est pas une. Coquille **neutre** : la couleur reste aux registres.

#### Une section vide n'enseigne plus rien
Depuis la porte unique « ＋ » de la v4.65.0, c'est elle qui présente les types disponibles avec
leur glyphe et leur phrase : « Minuteurs & compteurs » et « ⚡ Complications » ne portaient plus
qu'un titre au-dessus du néant. Même règle que le volet de relecture (« un panneau vide qui
affirme 0 remarque est du bruit permanent ») et que le pied de l'accueil. La capacité vit dans la
porte ; la section réapparaît au premier objet créé.

#### La poignée ⠿ d'un bloc vit en tête, à droite du titre
Elle était en pied, **au contact de « Supprimer le bloc »** — précisément ce que la v4.68.0 avait
corrigé pour les étapes (« un geste destructeur ne se met jamais au contact d'un autre bouton,
sinon le pouce corrige et supprime du même geste »). La règle n'avait pas été appliquée à
l'échelon du bloc ; elle rejoint l'anatomie déjà retenue pour l'étape.

#### Le bandeau « déplacement » tenait sur un mot par ligne
Signalé avec capture, sur iPhone. Troisième occurrence du même défaut de rangée flex :
« TOUCHEZ UNE DESTINATION » (majuscules + interlettrage) et le ✕ de 44 px sont **incompressibles**,
et le seul objet qui pouvait céder — le libellé, seul `min-width:0` de la rangée — cédait jusqu'à
la largeur d'un mot (**12 px sur 284**, mesuré). Remède déjà écrit deux fois dans ce fichier (croix
du panneau minuteurs v4.55.3, ligne d'état v4.56.3) : on **empile**, et le ✕ est **ancré** en haut
à droite avec sa place réservée par un rembourrage.

#### Une rangée de bibliothèque, un seul survol
Depuis que l'aplat de sélection vit sur le **conteneur** (v4.73.0), la micro-réponse E5 du
bouton-titre (lévitation d'1 px + ombre au survol) le décollait de son propre fond : le titre
montait, le crayon restait, et l'ombre se peignait par-dessus le bleu — deux objets là où il n'y a
qu'une bibliothèque. C'est le conteneur qui répond au geste, comme c'est lui qui porte l'état.

#### Points examinés sans changement de code
- **Le discriminant est déjà borné** à 60 caractères, dans le champ (`maxlength`) comme dans
  `migrate` (`sstr(x.discriminant,60)`) — le libellé le dit maintenant, il ne le disait pas.
- **« Essayer » qui entassait tout dans la colonne de gauche** : non reproductible, vérifié à
  1250, 1400 et 1600 px, en dynamique comme en statique, sur fiche et sur protocole — la grille se
  pose bien en `860 | 360`. C'était le défaut de piste corrigé en v4.73.0 (`cockpit` conditionné à
  l'existence de la colonne).
- **Le plafond des rappels** reste non bloquant : déjà en place, et c'est la doctrine (on suggère,
  on n'empêche rien).

#### Une exemption au harnais a11y, nommée et motivée
Le schéma `buildFlowSVG` (`.flow-scroll`) est entré dans une surface mesurée le jour où la colonne
droite a cessé d'être une maquette. Il n'a jamais été conforme au plancher de 11 px, **nulle part**
— ni dans le flux de l'éditeur, ni dans le panneau « Algorithme » de lecture, ni en plein écran :
simplement, aucun de ces logements n'était dans le SCOPE. Il en est exempté parce que ce n'est pas
du **texte** mais un **dessin à échelle variable** (zoom 25–400 %, plein écran, pincement natif) et
que chacun de ses mots existe en taille pleine dans le contenu qu'il résume — même frontière que
`check-type`, qui borne l'échelle fermée au texte. Tout le reste de `#editSide` reste mesuré.

#### Vérifications
809 tests × 2 moteurs, `npm run check` vert, **seize harnais verts** (`npm run audit` en sortie 0),
a11y 301/301, doctrine 144/144. **Douze nouveaux témoins** dans `scripts/audit-k5.mjs` (28 contrôles),
vérifiés **capables d'échouer** : défauts réintroduits un par un → 5 rouges, dont le libellé du
bandeau retombé à 12 px ; fichier restauré à l'octet. Rien à rejouer côté serveur.

## [4.73.3] — 2026-07-30
### Le prompt IA rattrape la structure — et il devient un contrat vérifié

> Cette version a d'abord été préparée sous le numéro **4.73.0**, en parallèle des 4.73.0 à
> 4.73.2 faites ailleurs. Deux versions ne peuvent pas porter le même numéro : `APP_VERSION` et
> `CACHE` sont un couple, et un décalage casse la mise à jour du service worker (règle 1). Elle a
> donc été renumérotée au merge, et republiée par `./release.sh` pour que les cinq fichiers
> d'artefacts restent cohérents. Le contenu est inchangé.

#### Le gabarit qu'il montrait n'était pas du JSON valide
Trouvé en écrivant le contrôle, pas en relisant : le `\n` de `localInfo` vivait dans un littéral
gabarit, donc JavaScript le transformait en **vrai saut de ligne**. Le JSON d'exemple affiché à
l'IA contenait une chaîne coupée par une fin de ligne — invalide. Une IA qui recopie fidèlement ce
qu'on lui montre produisait un fichier que l'import refuse, et la faute paraissait venir d'elle.
Il faut `\\n` dans la source pour afficher `\n`.

#### Deux champs manquaient depuis trois versions
`discriminant` (v4.70.0) et `onDue` (v4.70.0) n'étaient pas dans le prompt : une IA ne pouvait donc
pas les produire, et le champ créé pour éviter deux titres identiques sur un écran de crise restait
vide sur toute fiche générée.

- **`discriminant`** — la population ou le contexte (« adulte », « pédiatrique », « femme
  enceinte ») sort du titre pour rejoindre son champ. Le titre devient la **situation seule**, aussi
  court que possible : c'est lui qui est tronqué partout où la place manque. Et la consigne est
  explicite — **ne le devine jamais** : aucune migration ne découpe le titre d'un auteur pour en
  extraire un discriminant supposé, le prompt ne doit pas le faire non plus.
- **`onDue`** — ce qu'il faut faire quand le minuteur sonne, annoncé à la place du seul nom. Une
  alarme qui se contente de nommer dit **quoi** a sonné, jamais **quoi faire**.

#### Peu de texte — avec les seuils réels de l'éditeur
La contrainte est désormais énoncée d'abord, avant l'exhaustivité : un écran de téléphone tenu à
bout de bras pendant une réanimation ne rend pas un paragraphe, et une étape qui déborde sur trois
lignes repousse d'autant les suivantes sous le bas de l'écran. Les budgets ne sont pas des vœux :
ce sont **les seuils que l'éditeur signale lui-même** — challenge ≤ 110 caractères, bloc ≤ 7 étapes,
au plus deux séparateurs « · »/« + » par étape, rappel ≤ 110 caractères et 4 maximum, titres de
bloc de 2 à 4 mots. Les seuils du prompt et ceux de l'application ne doivent jamais diverger, sinon
l'IA produit exactement ce que l'éditeur va signaler.

#### Ce que « :: » fait à l'écran
Le prompt disait à quoi le séparateur **sert** (challenge-réponse, confirmation à deux voix) mais
pas ce qu'il **fait** : tout ce qui suit « :: », jusqu'à la fin de la ligne, sort du texte principal
et s'affiche en **gris, dans une bulle, à chasse fixe**. C'est donc un outil de mise en page autant
que de méthode — les chiffres passés après « :: » raccourcissent la ligne de moitié à l'œil. Une
étape de quatre-vingts caractères dont soixante sont des valeurs se lit très bien ; la même sans
« :: » est un pavé.

#### Un seizième harnais
`scripts/audit-prompt.mjs` extrait le schéma **du prompt lui-même**, le parse, le passe par
`migrate()` et vérifie qu'aucun champ ne tombe — puis que le prompt dit bien les trois choses que
cette version y ajoute. Il est **pur** : aucun rendu, aucun clic. Il mesure un contrat, pas un
écran. Règle qui en découle : tout champ modèle ajouté entre dans le prompt **et** dans ce harnais.

809 tests × 2 moteurs, a11y 301/301, doctrine 112/112, les seize harnais verts, `npm run audit` en
sortie 0. Rien à rejouer côté serveur.
## [4.73.2] — 2026-07-29
### Le menu ⋯ : une hauteur qu'on mesure, pas qu'on calcule

Le menu ⋯ restait tronqué en grande taille de texte — sa dernière rangée passait **sous
l'indicateur d'accueil de l'iPhone**.

La v4.73.0 l'avait clampé en CSS : `var(--vvh) / var(--zf) - var(--hdr-h) - 16px`. Le calcul est
juste sur Blink et restait faux à l'usage, pour deux raisons. La première est de méthode : il repose
sur trois hypothèses de plateforme à la fois — ce que `visualViewport.height` compte sous `zoom`,
comment le zoom d'`<html>` se combine aux unités de fenêtre, et ce que vaut la hauteur d'en-tête
quand `env(safe-area-inset-top)` s'y ajoute. Le dossier « bande basse iOS » avait déjà établi
qu'aucune de ces trois-là ne se déduit : elles se mesurent. La seconde est le terme manquant : **la
hauteur visible d'iOS inclut la bande de l'indicateur d'accueil**, si bien qu'un menu calé dessus y
fait passer sa dernière rangée — précisément ce que montrait la capture.

La hauteur est donc posée par la mesure : hauteur réellement visible, moins la position **réelle**
du menu — qui absorbe sans aucun calcul la hauteur d'en-tête, le safe-area du haut et le décalage de
6 px —, moins la marge basse du matériel, désormais exposée au script par une propriété
personnalisée (`env()` ne se lit pas depuis un script). Un plancher de 180 px garantit qu'une mesure
pathologique — menu ouvert pendant une transition, clavier virtuel déployé — ne réduira jamais le
menu à une bande inutilisable : mieux vaut un menu qui dépasse un peu et qu'on peut faire défiler
qu'un menu disparu. La mesure est rejouée au redimensionnement et au changement de taille du texte,
puisque le menu peut être ouvert à cet instant.

Nouveau témoin de doctrine : 390 et 430 px × deux tailles de texte × **avec et sans marge matérielle
simulée** (34 px), et il vérifie en plus que la dernière rangée est atteignable après défilement.
Vérifié capable d'échouer dans les deux sens — terme de marge retiré : 4 rouges, exactement les
quatre configurations avec marge ; clamp entier retiré : 8 rouges. 809 tests, doctrine **144/144**,
a11y 301/301, quinze harnais verts.

## [4.73.1] — 2026-07-29
### La grande police était un trou de couverture

**Les commandes de crise étaient tronquées en grande taille de texte** — « ⤢ Se repérer » coupé net,
« ⤢ Consulter » hors écran. Deux causes, et la seconde n'avait jamais été nommée dans le projet.

D'abord, **les paliers de compression ne se déclenchaient pas**. Le réglage de taille du texte est un
`zoom` sur `<html>` : la place réellement disponible pour la mise en page vaut *largeur ÷ zoom* —
331 px sur un écran de 430 à 130 % — alors qu'une media query continue de mesurer la fenêtre du
périphérique et répond 430. Les quatre paliers calibrés en v4.30.0 et v4.43.0 restaient donc inertes
au moment précis où ils sont le plus nécessaires : mesuré, une rangée exigeant **594 px pour 430
disponibles**, soit 164 px inaccessibles, dans la zone de crise. C'est la règle 10 sous une forme
qu'on n'avait pas rencontrée — on savait que les *hauteurs* relatives à la fenêtre devaient être
divisées par le zoom ; les *seuils de largeur* aussi, et le CSS n'a aucun moyen de le faire. Ils
passent maintenant par des classes posées depuis `innerWidth ÷ zoomF()`. À zoom 1, c'est exactement
la valeur que la media query lisait : rien ne change là où rien n'allait mal.

Ensuite, **la recette de compression est calibrée pour 320 px**, le plancher servi. À 130 % sur un
écran de 390, il ne reste que 300 px effectifs — sous ce plancher — et aucune marge ne peut plus
rendre les pixels manquants. Le choix n'est alors plus « compresser ou déborder » mais « un libellé
inaccessible ou une seconde ligne ». On prend la seconde ligne, et **la décision est une mesure, pas
un seuil** : la rangée est remise à plat, son débordement réel est lu, et elle n'enroule que s'il
existe — même méthode que l'ajustement du quai, où les seuils en dur s'étaient déjà révélés faux. La
coupure tombe sur l'écart de Gestalt, qui devient le saut de ligne : le mode d'un côté, les deux
ouvertures de l'autre. Rien n'est sacrifié pour tenir — ni l'ordre, ni un libellé, ni une cible de
44 px. La doctrine « pas de 2ᵉ ligne » n'est pas enfreinte : elle vise le coût *permanent* d'une
rangée qui s'épaissirait pour tout le monde, alors qu'ici la seconde ligne n'apparaît que sur une
configuration où la rangée débordait vraiment. Les paliers restent utiles : mesuré, ils évitent
l'enroulement dans 4 configurations sur 20.

**Et « VOUS ÊTES ICI » était coupée par le bord gauche de sa carte.** Les trois objets de la ligne
d'état sont tous insécables, donc incompressibles, et `justify-content:flex-end` fait déborder par le
côté opposé : c'était le *premier* objet qui sortait de la carte — là où aucun défilement ne peut le
rattraper. La ligne s'enroule, s'aligne au début, et c'est le premier bouton qui pousse les autres à
droite : aspect identique tant que tout tient sur une ligne, et la pilule ne se déplace jamais,
puisque c'est un état.

Le témoin de doctrine ne mesurait qu'à zoom 1 — c'était le trou. Il mesure désormais 390 et 430 px
**aux quatre paliers de taille du texte**, et vérifie en plus que les libellés sont intacts : sans
cette seconde moitié, un futur « correctif » passerait le contrôle en masquant les mots. Vérifié
capable d'échouer. 809 tests, doctrine **128/128** (les 5 rognages que la v4.73.0 laissait rouges
dans l'environnement d'intégration sont couverts par la mesure), a11y 301/301, quinze harnais verts.

## [4.73.0] — 2026-07-29
### Douze retours d'usage : sept défauts, cinq améliorations

Aucune fonctionnalité nouvelle — une passe de correction et d'affinage, entièrement pilotée par des
retours d'usage.

**Le mode statique s'affichait dans une colonne de 240 px.** La classe `cockpit` pose une grille de
trois pistes fixes (plan | action | état), mais le plan n'est émis que s'il y a un plan à montrer —
jamais en statique, où le tableau EST la vue d'ensemble. Les deux colonnes restantes glissaient donc
d'un rang : la checklist atterrissait dans la piste du plan (mesuré à 1280 px : `main` w=240,
`side` w=592). Trois pistes n'ont de sens que s'il y a trois colonnes — la classe suit désormais
l'existence du plan, pas la seule largeur.

**Le plan latéral ne se mettait pas à jour**, et le défaut datait de la v4.23.0 : son HTML vivait
dans une IIFE de `renderRead`, donc hors d'atteinte des re-rendus ciblés — il gardait l'état du
moment où la fiche avait été *ouverte*. Le cockpit de la v4.59.0 n'a fait que le mettre sous les
yeux. `railLadHtml` est extraite et `repaintRailLad()` la rejoue à la navigation comme au cochage
(y compris distant), défilement de la colonne préservé, écouteurs recâblés — et le renvoi d'un
bloc défile enfin dans le conteneur réel, pas dans un rail droit supposé. Une seule peinture, pas
deux qui divergeraient. **Harmonie** : l'Échelle était la seule zone de la vue lecture posée à nu
sur le fond ; elle devient une surface, dans ses deux logements, et son en-tête ne casse plus le
titre en « PLAN — / ÉCHELLE » à 240 px.

**Le miroir laissait l'invité derrière.** Ne jamais défiler sur un geste qui n'est pas le sien
protégeait un cas et en cassait un autre : celui de quelqu'un qui suit la progression et que l'hôte
distance, carte après carte, jusqu'à perdre le bloc en cours. Le critère n'est plus « qui a appuyé »
mais **où regardait-il** : le bout du journal était à l'écran → on l'y garde ; il avait défilé
ailleurs → rien ne bouge, comme avant. Le témoin d'audit mesure maintenant les deux régimes — et il
a fallu placer le bout en bas de l'écran pour qu'il soit **capable d'échouer**.

**« Partage en cours (n) » : un mécanisme n'est pas un correctif.** La v4.55.2 avait donné au menu ⋯
le moyen de se refaire sans re-rendre, et ne s'en servait que sur une offre de passation. Le compte
restait celui de l'ouverture de la fiche — c'est-à-dire zéro dans le cas normal, où l'on ouvre le
partage avant que le collègue rejoigne. Il se rafraîchit désormais là où la donnée change, sur
comparaison de signature (un participant coupé ou promu change l'affichage sans changer le nombre).

**Le rail alphabétique montait et descendait.** Les lettres étaient centrées dans une boîte fixée
haut et bas : toute variation de la hauteur visible les déplaçait de la moitié — et cette hauteur
varie précisément *pendant* un défilement, quand la barre d'outils du navigateur mobile se replie.
Le glisser devenait un asservissement instable. Ancrées en haut : 30 px de déplacement mesurés
avant, **0 px** après.

**Le menu ⋯ ne s'adaptait pas à une fenêtre basse** : jusqu'à seize rangées, ~740 px, et les
dernières — dont « Terminer la session… » — hors écran *sans défilement*, donc inatteignables en
silence.

**Le titre changeait de police au défilement** : le serif de la v4.61.0 avait été posé sur le
bandeau, pas sur son relais dans la barre. Un seul libellé porté tour à tour par deux éléments doit
se lire pareil des deux côtés. (Réponse à la question posée : non, ce n'était pas exprès.)

**L'état criait plus fort que l'action** : temps de minuteur et décomptes de compteurs en gras
quasi noir passaient devant la checklist. Graisse ramenée (700 → 500 pour les valeurs, 700 → 600
pour le nom) ; l'encre, elle, ne bouge pas — la hiérarchie passe par la graisse, jamais par la
couleur, qui reste le canal de l'état.

**Le démarrage reste atteignable** : sur une fiche à critères longs, « Confirmé — démarrer la
session » naît sous le pli. Il se détache alors au bas de l'écran — une zone fixe en bas, ce que la
doctrine réserve, mais bornée par trois propriétés vérifiables : avant la première action
seulement, transitoire, et à coût nul en hauteur de flux.

**Lien mort : l'écran de l'invité le dit, et ses contrôles le montrent.** Avant, rien ne changeait —
un jeton de sept caractères dans le quai, et une annonce invisible quand un geste était tenté : la
seule façon d'apprendre qu'on ne recevait plus rien était d'essayer, et de ne rien voir se passer.
Un bandeau dans le flux (jamais une modale — règle 11), la cause dite, la sortie à portée, et les
contrôles à l'apparence désactivée. Le texte clinique, lui, n'est **pas** grisé : il reste vrai et
utile, et l'estomper passerait sous AA. Aucune désaturation d'ensemble non plus, qui éteindrait le
rouge des étapes vitales.

**L'objet pris se voit** : anneau primaire, teinte et mention « ⠿ en déplacement » sur le bloc ou
l'étape soulevée — sans l'estomper, puisqu'on doit relire ce qu'on déplace.

**La sélection d'une bibliothèque va jusqu'au bord droit**, sous le bouton « modifier » qui
appartient à la même rangée.

809 tests, a11y 301/301, partage 297/297 (+1), quatorze harnais verts. `design/ds` régénéré.
Rien à rejouer côté serveur.

## [4.72.0] — 2026-07-29
### K5 — l'enregistrement se dit, il ne se demande pas

L'éditeur s'auto-enregistrait **déjà** depuis la v4.5 — mais dans un parc, et il fallait quand même
appuyer sur « Enregistrer ». L'écran portait donc une action primaire dont le seul effet était de
tenir une promesse que la machine tenait déjà. Ce qui change ici, c'est la **promesse affichée**,
pas la mécanique.

#### Un seul point d'écriture, deux accroches
`edCommit` est à l'éditeur ce que `persistLive` est à la session et `_putSessionSafe` à
l'historique : au point d'étranglement, toute mutation ajoutée demain est couverte sans qu'on y
pense. Il n'y a que **deux** accroches — la saisie par délégation `input` sur `main` (elle bulle,
donc tout champ futur est couvert) et les gestes structurels, qui se terminent tous par un
re-rendu de l'éditeur. Chercher un à un les cinquante gestes de mutation aurait produit la même
liste à tenir à jour que celle des soixante verbes que `persistLive` a précisément permis de **ne
pas** écrire.

Il commit une **copie normalisée**, jamais le brouillon : la normalisation retire les lignes vides,
et appliquée au brouillon vivant elle supprimerait la ligne où l'auteur est en train de taper. Et
**rien ne s'écrit si rien n'a bougé** — `renderEditor()` court aussi à l'ouverture : sans ce test,
ouvrir une fiche pour la relire la ré-écrirait, la ferait remonter dans la file de synchro et
gagner toute résolution LWW. Une fiche « modifiée » pour avoir été regardée.

#### Le cycle de vie, en trois réponses
**Quand ça entre dans la bibliothèque ?** Dès qu'il y a un **titre**. Une fiche anonyme n'a pas de
nom sous lequel apparaître, et une rangée « Sans titre » se rangerait sous « # » dans un répertoire
A→Z : un piège plutôt qu'une aide. Tant que le titre manque, c'est le parc qui sert de filet — il
n'a plus d'autre rôle.

**Quand ce n'est plus un brouillon ?** Par un **acte éditorial** : le statut passe de
« ○ Brouillon » à « △ À relire » ou « ✓ Validée ». Le modèle a ces trois états depuis la v4.3.0 ;
inventer une seconde notion de « pas encore enregistré » à côté de « pas encore validé » ferait
deux vocabulaires pour une idée.

**Et en attendant ?** Le répertoire le montre avec sa pastille, la recherche le trouve — on ne
cache rien —, mais **il ne s'épingle pas** : la rangée de tuiles est l'accès de crise. Il se
**désépingle** toujours, sinon une fiche épinglée puis repassée en brouillon resterait coincée là.

#### Trois choses vivaient dans « Enregistrer » et ont dû trouver un autre foyer
C'est le vrai travail de cette version.

1. **La confirmation de publication** suit désormais le geste qui la déclenche — le sélecteur de
   bibliothèque, refus compris (retour à la valeur d'avant). À chaque pause de frappe, ce serait
   une fenêtre toutes les quatre secondes.
2. **La session vive** se termine à l'**ouverture** de l'éditeur, au registre danger. Avec
   l'écriture continue, le premier caractère tapé la tuerait en silence — peut-être pendant que
   quelqu'un la déroule.
3. **Le ménage destructif** (images d'un protocole que plus aucune ligne ne référence, blobs d'un
   brouillon jamais publié) reste à la **sortie**. Le faire pendant la frappe effacerait une image
   à l'instant précis où l'auteur en retire la référence pour la remettre trois mots plus loin.

Et le filet qui remplace le « Annuler » disparu : **un point de version posé à l'ouverture**, un
seul par séance d'édition. Un point par écriture noierait l'historique sous le bruit de la frappe,
ce qui reviendrait au même que pas de filet du tout.

#### « ▶ Essayer » — une session qui ne laisse rien
L'aperçu refusait toute session : on voyait un rendu inerte, donc jamais le **comportement** de ce
qu'on venait d'écrire — or c'est exactement ce que l'auteur vient vérifier (« mon cycle de 2 min
sonne-t-il au bon moment ? »). Il a maintenant son propre Runtime. Sans lui, cocher et naviguer
marchaient déjà, mais ni minuteurs, ni compteurs, ni chrono : ils vivent sur le Runtime, et
l'aperçu n'en avait pas.

**L'étanchéité tient en trois points, tous en tête des fonctions qui écrivent** : la session
n'entre pas dans `liveSessions` ; `persistLive` sort **avant** `shareEmitDiff` — placée après, un
auteur qui essaie son brouillon pendant qu'il partage une session enverrait ses coches d'essai sur
l'écran d'en face ; `endSession` arrête les minuteurs et s'en va sans rien archiver.

**Ce n'est pas le mode exercice**, et il ne faut pas les confondre : l'exercice est une répétition
**réelle**, enregistrée, ségrégée dans l'historique et restituée au débriefing, sur une fiche
publiée. L'essai porte sur un brouillon en cours d'écriture ; il n'a rien à restituer à personne.

#### L'aperçu cesse de se dire deux fois
La v4.70.1 avait rangé « Aperçu » parmi les exceptions du bandeau — erreur de classement. Une
exception, au sens de cette règle, est ce que la pilule de la barre ne dit pas à elle seule :
« ▪ Vous suivez » porte une phrase et une hachure, « ▲ Exercice » protège d'une méprise clinique.
« Aperçu » n'a ni l'une ni l'autre — c'était le même mot, écrit deux fois. La barre suffit.

Nouveau harnais `scripts/audit-k5.mjs` (16 contrôles), le quinzième. Il tient le cycle de vie, et
ses trois contrôles les plus importants sont ceux qui garantissent qu'un essai d'auteur ne
contamine pas l'historique clinique de quelqu'un. Il a d'ailleurs attrapé, en cours de route,
l'abréviation de l'état sous 560 px : le témoin mesure désormais **les deux largeurs**, accepter
« l'une ou l'autre » ne prouvant rien sur celle qu'on ne regarde pas.

809 tests × 2 moteurs, a11y 301/301, doctrine 112/112, les quinze harnais verts, `npm run audit` en
sortie 0. Rien à rejouer côté serveur.

## [4.71.1] — 2026-07-29
### L'échelle typographique se ferme, la taille du texte devient un segmenté, l'admin se lit en lignes

#### Sept paliers, et un garde-fou qui les tient
`19 · 18 · 16,5 · 15,5 · 13,5 · 12 · 11`. Avant, la feuille portait **seize** corps différents
entre 10 et 19 px. Le problème n'est pas la pureté : **deux textes à 13 et 13,5 px ne se lisent pas
comme deux niveaux, ils se lisent comme une inattention** — et une hiérarchie qu'on ne peut pas lire
ne hiérarchise rien. 238 déclarations réécrites, dont un 10 px qui passait sous le plancher de 11.

**Périmètre : le texte, c'est-à-dire sous 20 px.** Au-dessus vivent les affichages — chronos,
challenge du mode lecteur, moniteur, tête de bilan. Chacun occupe sa propre surface, ils ne se
croisent jamais du regard, et les forcer sur l'échelle du texte n'apprendrait rien à personne.
Hors périmètre, délibérément.

**Deux valeurs de service, qui ne sont pas des paliers** : `16` = plancher des champs sur écran
tactile (règle 9 — sous 16, Safari iOS zoome au focus et les taps se perdent) ; `14` = l'un des
quatre « A » du sélecteur de taille, dont l'écart de corps **est** l'information.

`scripts/check-type.mjs` entre dans `npm run check` et rend la règle auto-exécutoire, comme
`check-colors` pour les couleurs. Toute valeur hors échelle échoue, sauf exemption **nommée par son
sélecteur et motivée** dans le script — une exemption anonyme rouvrirait la porte qu'on vient de
fermer. Vérifié capable d'échouer : 13,2 px introduit, contrôle rouge, fichier restauré à l'octet.

#### La taille du texte devient le sélecteur segmenté de l'app
Quatre « A » séparés deviennent le composant à pastille glissante — celui de Guidé / Statique.
Le composant ne savait compter que jusqu'à deux : il accepte maintenant N segments (`--seg-n` /
`--seg-i`), et **la mécanique à deux est laissée strictement intacte** (`.seg.i1` continue de
piloter la tab bar, « Créer » et le sélecteur de mode). Le cas N passe par un `#id` et non par une
classe de plus : à spécificité égale, ce serait l'ordre de déclaration qui trancherait — le projet
a déjà payé cinq fois ce piège. Le glisser au doigt marche à quatre paliers (mesuré : glissé du
palier 1 au palier 4, le zoom suit).

**Le tap ne re-rend pas la fenêtre** : un `renderAuth()` reconstruirait le sélecteur et la pastille
sauterait au lieu de glisser. Rien d'autre de la fenêtre ne dépend du zoom — on peint sur place.
`.ts-seg` et son halo sont purgés avec le composant qu'ils habillaient.

#### État de l'instance — quatre groupes, une donnée par ligne
Douze tuiles en grille obligeaient à balayer un damier pour trouver un chiffre. Désormais :
**Comptes / Contenus / Partage & sessions / Stockage**, libellé en toutes lettres à gauche, valeur
en mono tabulaire à droite, détail dessous en encre douce.

**La seule action est un bouton** — « Examiner · n » — et il rejoint **la ligne dont il est le
geste** au lieu de flotter au-dessus du bloc. Il est donc câblé par `loadInstanceStats` : le
câbler depuis `renderAuthAccount` ne trouverait rien, le bouton n'existant pas encore à ce moment.

Le constat P3-1 de la v4.56 (« la teinte `--primary-soft` donnait à de la lecture seule l'air d'être
actionnable ») allait dans le bon sens mais s'arrêtait à la couleur : c'est la **forme de tuile**
qui promettait un objet. `.inst-stats` / `.inst-stat` sont purgés. La barre de stockage montre la
**part des documents dans le total** — un dénominateur réel : une jauge sans dénominateur est un
ornement qui a l'air d'une mesure.

#### Deux détails trouvés en chemin
« Partage &amp; sessions » s'affichait littéralement : le `&` était échappé deux fois. Et `fmtBytes`
écrivait « 3.0 Mo » avec un point décimal au milieu d'un texte français. **Un test tenait ce
format et l'a attrapé** — c'est exactement pour ça qu'il existe ; le changement est donc délibéré
et son attendu a été mis à jour, pas contourné.

809 tests × 2 moteurs, a11y 301/301 sur Chromium **et** WebKit, doctrine 112/112, `modeseg` 2/2 sur
les deux moteurs, les quatorze harnais verts, `npm run audit` en sortie 0. Rien à rejouer côté
serveur.

## [4.71.0] — 2026-07-29
### Le sombre descend au noir, le geste répond partout où c'est calme, et la porte « + » ne ment plus

#### Le thème sombre passe en vraie nuit, surfaces neutres
`--bg` #0c1420 → **#000000**, surfaces #0d0d0f / #070708 / #191a1d, filets #33363b, champs #000,
et les hors-teintes de survol suivent — sans elles, le « gris pur » se lirait bleu au premier
passage de souris. Motif d'usage : un écran OLED n'allume pas ses pixels noirs, ce qui vaut de
l'autonomie sur un appareil tenu trois heures en intervention, et le contenu d'alerte y détache
d'un cran de plus — le cadre rouge « Ne pas oublier » est ce qu'on doit voir en premier.

**Ce que le noir oblige à déplacer, et c'est le vrai travail :** sur #000, **une ombre ne dit plus
rien** — assombrir du noir ne produit aucun contraste. Les trois niveaux d'élévation écrits en
v4.57.0 ne peuvent donc plus reposer sur elle : c'est la **surface** qui monte et le **filet** qui
borde. Les ombres restent déclarées et ne sont pas du gaspillage — une modale se détache encore de
la carte qu'elle recouvre, qui n'est pas noire.

**Aucune encre, aucun registre ne bouge** : le noir est un changement de fond, pas de sémantique.
Le gris strictement neutre a un mérite qu'il faut nommer — toute couleur à l'écran y porte un sens
(registre, catégorie ou accent), ce qui est exactement la règle 8. La variante « famille bleue sur
les surfaces » a été maquettée à côté et écartée par l'utilisateur.

L'a11y a été rejouée avec la palette **réellement posée dans le fichier**, pas injectée à chaud :
301/301 sur Chromium et WebKit, contraste calculé sur le fond effectif.

#### E5 s'étend aux surfaces calmes, et à elles seules
La restriction de la v4.57.0 aux tuiles d'accueil était un reste de chantier, pas une doctrine.
Ce qui **est** une doctrine, et qui borne la liste : en crise, le mouvement est réservé à l'alarme.
La moitié survol ne pourrait de toute façon pas s'y déclencher (`pointer:fine` = une souris, pas le
téléphone du terrain) ; c'est la moitié **appui** qui impose la borne.

Pas de balayage en gros sur `.btn` ni sur `.ai-card` : ces sélecteurs attrapent aussi « Terminer la
session ? » et l'index des complications, qui s'ouvrent pendant un soin. La liste est nominative —
sidebar d'accueil, palette d'ajout, volet de relecture, rangées de document et de sélecteur,
versions, porte « + ».

#### Fenêtre Compte — M5
L'identité et les trois actions qui en dépendent vivent dans une **carte**, et « Synchroniser »
**perd son remplissage** : on n'ouvre pas ses réglages pour agir, et il était le seul bouton rempli
d'un écran qui n'a pas d'action primaire.

**Ce qui n'est pas repris de la maquette** : elle range les trois boutons sur une rangée, ce qui
remettrait « Se déconnecter » au contact du bouton le plus tapé de la fenêtre. La v4.5 avait posé un
tampon là exprès — « un tap légèrement trop bas ne doit pas déconnecter », défaut vécu comme un
bug. La déconnexion garde sa ligne, son tampon et sa confirmation.

« Sur cet appareil » devient une **ligne** (~64 px rendus). La v4.56.3 avait rendu les tuiles
neutres, mais une tuile reste la forme d'un **objet**, et trois nombres qu'on ne peut ni taper ni
régler n'en sont pas. Les tuiles **restent** pour « État de l'instance » (admin), où il y en a dix
et où une ligne ne se lirait plus. Groupe « Affichage », libellé et contrôle sur la même ligne tant
que la place existe.

#### La porte « + » était incomplète, donc elle mentait
Elle promet « voici tout ce que vous pouvez ajouter » — il en manquait **deux** que la fiche accepte
pourtant : le **tableau de doses** et le **document**. Une porte unique qui ne montre pas tout est
pire que six portes dispersées : avant on cherchait, maintenant on renonce.

Le document est le seul type qui n'ajoute pas une ligne au brouillon : il ouvre le sélecteur de
fichier. Le clic doit partir **dans la même tâche** que celui de la palette (`renderEditor()` est
synchrone), sinon l'activation utilisateur est perdue et le navigateur refuse d'ouvrir le sélecteur.
La rangée disparaît en repli KV, qui ne sait pas stocker de binaire — un bouton mort vaut moins
qu'une absence.

**Ce qui reste hors de la porte** : « Étape / Étape critique / Étape vigilance », que la maquette y
range. Un « + » = une **portée** — la palette ne vit qu'entre les blocs, où une étape n'a pas de
bloc d'accueil ; dans un bloc, « ＋ Étape » et ⏎ s'en chargent. L'intention pédagogique de la
maquette (« les registres s'apprennent ici, avant la crise ») n'est pas perdue : elle vit dans le
dépliant en tête de chaque bloc, c'est-à-dire là où l'on **choisit** le registre.

Deux défauts de dessin corrigés au passage : « ⏱ » servait **deux** entrées de la même liste
(règle du menu ⋯ : jamais le même dessin deux fois) — le minuteur qui **sonne** et le temps qui
**monte** ont maintenant chacun le leur ; et le document passe par l'icône de trait de la famille,
pas par « 📎 », un emoji en **couleur** dans une liste monochrome, quand la couleur ne décore jamais
ici.

808 tests × 2 moteurs, a11y 301/301 sur Chromium **et** WebKit, doctrine 112/112 sur les deux
moteurs, les quatorze harnais verts, `npm run audit` en sortie 0. Rien à rejouer côté serveur.

## [4.70.1] — 2026-07-29
### Le mode ne se dit plus deux fois — et un harnais qui plantait en emportait cinq

#### Deux annonciateurs, deux offices
La v4.58.0 avait ancré la pilule de mode au coin haut-droit, à côté de `◐ ⋯`, pour qu'elle cesse
de sauter de place au défilement. Elle avait laissé en place celle du bandeau : on lisait donc
**« ■ CRISE » en barre et « ■ MODE CRISE » en bandeau, en même temps, sur le même écran**. La
doctrine du projet l'admettait comme une troncature du même mot (« Cons. » pour « Consulter »),
mais la troncature sert à faire tenir **un** libellé dans une place étroite — elle n'a jamais servi
à écrire deux fois la même chose côte à côte.

La règle devient explicite, et vérifiable : **la barre dit le MODE, le bandeau dit l'EXCEPTION.**
`#hdrCrisis` est permanente, immobile, et le seul énoncé du mode. `.cb-tag` ne paraît que
lorsqu'il y a quelque chose que la pilule ne dit pas déjà à elle seule :
- **« ▪ Vous suivez »** — l'invité SUIT une session qu'il ne conduit pas et qui peut s'arrêter sans
  lui (v4.55.4, décision utilisateur : en toutes lettres, à l'endroit le plus lu). La pilule dit
  « Suivi » ; le bandeau dit la PHRASE, et porte la hachure.
- **« ▲ Exercice »** — « ceci est une répétition », la seule annonce qui protège d'une méprise
  CLINIQUE ; elle garde sa hachure et sa priorité sur le placard d'invité.
- **« ■ Aperçu »** — on regarde un brouillon, rien n'est enregistré.

Ce n'est donc pas la redondance de l'alarme (quai + rail), qui répète une valeur **vive** en deux
endroits pour qu'elle ne puisse pas être manquée : ici les deux canaux disaient la même constante.
En crise ordinaire le bandeau ne porte plus que le titre et son discriminant.

#### Ce que ça rend, et ce que ça coûte — mesuré
Le titre récupère la largeur de l'étiquette : à 360 / 390 / 430 px il **retombe sur une ligne**,
le bandeau passe de **63,7 px à 44 px**. À 320 px il occupait déjà deux lignes et n'en gagne
aucune — mais c'est précisément là que `#crisisCtrl` n'a que 2,1 px de marge, donc **le placard de
l'invité y reste à coût nul**, ce qu'un nouveau témoin mesure désormais au lieu de l'affirmer.
Au-dessus de 320 px, poser un placard peut repousser le titre à la ligne : c'est sans effet de
bord, parce qu'il n'existe **aucune transition sur place** vers ces états — on arrive en invité par
l'écran d'entrée, un lien coupé passe par `freeze` (qui garde `mode === 'guest'`), et l'exercice
est un acte local qui ré-annonce tout l'écran.

La miniature de l'aperçu d'éditeur n'a pas de barre d'application : sa pilule tient lieu de
`#hdrCrisis` et porte donc le **même mot** (« ■ Crise »). Un seul libellé dans tout le fichier.

#### Deux témoins ont changé de propriété, pas de sujet
`audit-partage` lisait « l'hôte affiche *Mode crise* » et `audit-exercice` « ■ Mode crise +
● Session inchangés » — deux assertions qui encodaient le défaut. Elles vérifient maintenant
l'invariant réel : en crise ordinaire le bandeau n'annonce **aucune** exception (étiquette vide,
pas de hachure) et le mode est dit **une** fois, par la barre.

#### Le harnais des complications plantait depuis la v4.65.0 — et il n'était pas seul
`audit-complications` cliquait `#addCx`, l'un des **six** boutons d'ajout que la v4.65.0 a
remplacés par une porte unique. Il levait donc une exception depuis cinq versions — et comme
`npm run audit` chaîne les quatorze harnais par `&&`, **il emportait les cinq suivants avec lui**
(exercice, lecteur, QR, partage, historique). Ils étaient verts, mais parce que je les lançais un
par un : la commande d'ensemble, elle, s'arrêtait au neuvième. Leçon, et elle est bête : on lit le
**code de sortie**, pas la dernière ligne d'un `grep`. La sonde passe désormais par la porte
réelle, c'est-à-dire par le chemin de l'auteur.

808 tests × 2 moteurs, a11y 301/301, doctrine 112/112, complications 20/20, exercice 20/20,
lecteur 14/14, QR 9/9, partage 296/296 (+2), historique 16/16 — **les quatorze harnais de bout en
bout, `npm run audit` en sortie 0**. Rien à rejouer côté serveur.

## [4.70.0] — 2026-07-29
### Fin de la phase K — le minuteur dans sa carte, le poste d'écriture, le discriminant

> **⚠ Cette version exige de rejouer `supabase/schema.sql`** — la première du chantier dans ce
> cas. La liste blanche des champs de fiche du serveur doit connaître `discriminant`, sinon il est
> filtré à l'arrivée et l'invité voit une fiche sans son discriminant.

### K7 — le minuteur se règle dans sa carte, et l'alarme dit l'action
La rangée de champs devient la **carte du rail** : nom en casse de phrase, précision en méta,
durée, type. S'y ajoute **« à l'échéance »** — nouveau champ `onDue`, facultatif, défaut vide.

C'est le point important : `onTimerFired` annonce désormais **l'action** quand l'auteur l'a
écrite, au lieu du seul nom. Une alarme qui nomme le minuteur dit **quoi a sonné**, jamais **quoi
faire** — poser l'action au pied de l'alerte est la règle ECAM, et c'est l'auteur qui la connaît,
pas l'application. Sans `onDue`, le comportement est inchangé.

### K11 — le poste d'écriture à 1200 px
**Structure | la fiche | aperçu.** La colonne structure **est** le futur « Se repérer » de la
fiche : l'auteur ne dessine jamais le plan, il découle de la structure. Une ligne par bloc, son
compte d'étapes, un tap pour ancrer le bloc au centre.

Elle **n'agit jamais** : ni champ, ni geste destructeur — la même règle que le plan inerte en
lecture. Elle est posée *après* la colonne de travail dans le DOM et ramenée à gauche par `order`,
pour que ni lecteur d'écran ni tabulation ne la traversent avant d'atteindre les champs. Palier
1200, comme le cockpit de lecture.

### K6 — le discriminant a son champ
« adulte », « pédiatrique », « femme enceinte » : c'est **lui** que la troncature mange en
premier, et deux titres identiques sur un écran de crise sont un piège. Champ `discriminant`,
facultatif, 60 caractères.

- **Aucune migration ne devine.** On ne découpe pas le titre d'un auteur pour en extraire un
  discriminant supposé — ce serait réécrire son texte.
- **Affiché là où le titre se tronque** : rangée du répertoire, tuile d'accès direct, et bandeau
  de crise — dans sa propre pilule, jamais dans la chaîne qui se coupe.
- **Il voyage** (client et serveur). Il fait partie du **nom** : un invité lisant « Arrêt
  cardiaque » là où l'hôte lit « adulte » serait exposé au piège même que ce champ supprime. La
  règle 15 (« aucun texte libre ne traverse le réseau ») vise ce qu'on **saisit pendant un soin**
  — repères, notes, contexte local — pas l'identité de l'aide, dont le titre et le code voyagent
  déjà.

Vérifié : 808 tests × 2 moteurs, a11y 301/301, doctrine 112/112, partage 294/294, `check-sql`
(19 capacités identiques client/serveur).

## [4.69.0] — 2026-07-29
### Identité compacte, volet de relecture d'une ligne, et les raccourcis à la frappe

### La ligne Identité
Le **titre domine** (16,5 px, la taille qu'il aura en lecture), le **code** le suit en pilule mono
— c'est l'identité de crise, elle se lit d'un coup d'œil sans se confondre avec le titre — et
« Identité ▾ » n'est plus une étiquette posée *devant* mais le **déclencheur à droite** : le mot
ne prend la place du titre que là où il agit.

### Le volet de relecture
Il devient un **dépliant d'une ligne** : replié, le compte et les cibles abrégées ; déplié, ses
rangées d'ancrage. Il dit **combien** il reste à relire, pas une seconde fois **quoi** — le détail
vit sous la ligne qu'il vise depuis la v4.68.0.

### K10 — les raccourcis à la frappe
« ! » ou « ? » en tête d'étape, suivis d'une espace, **posent le registre** (⚠ / △) et
**disparaissent du texte**. Le champ est réécrit sur place, la rangée reçoit sa classe, aucun
re-rendu.

Un éditeur markdown **libre** reste refusé : il casserait les registres, le style télégraphique et
l'une-action-par-ligne. C'est la **vitesse** du texte qu'on récupère, pas sa liberté. Deux
caractères, et **seulement en tête** : un « ? » au milieu d'une phrase (« Rythme choquable ? »)
n'est pas un raccourci — l'oublier transformerait le texte d'un auteur sans qu'il comprenne
pourquoi.

**Piège majeur découvert à la mesure** : `STEP_CRIT_RX` reconnaît **déjà** « ! » comme marqueur
critique (format historique, documenté). Déduire le registre du modèle *avant* d'évaluer le
raccourci le rendait donc inatteignable — et laissait le « ! » dans le texte, cumulé avec le ⚠ :
« ⚠ ! Choc immédiat », mesuré. Le raccourci s'évalue **avant**.

Vérifié : **808 tests × 2 moteurs** (+7), a11y 301/301, doctrine 112/112. Rien à rejouer côté
serveur.

## [4.68.0] — 2026-07-29
### Le dessin des box et des boutons de l'éditeur, d'après la maquette

- **L'en-tête de bloc porte la pastille numérotée de la lecture** — ronde et bleue, losange ambre
  pour une décision — au lieu d'une pilule « ÉTAPES ». C'est le même repère qu'en crise.
- **Le chapeau porte son compte « n/4 »**, et la porte dit ce qui **reste** :
  « ＋ Rappel (1 restant) ». Un plafond qu'on voit approcher informe ; il n'a pas à crier avant
  d'être franchi — le garde-fou ambre ne parle qu'**au-delà** de 4.
- **Le ✕ s'écarte des réglages.** Un geste destructeur ne se met jamais au contact d'un
  interrupteur d'état : sinon le pouce corrige et supprime du même geste.
- **La poignée ⠿ vit à droite de la ligne et reste visible au repos** : c'est une affordance de
  réordonnancement, elle ne se découvre pas au tap.
- **Le champ actif porte la bordure d'accent.** En thème sombre, `--input-bg` seul est trop proche
  du fond de la rangée pour se voir — c'est le trait qui dit « ici on écrit ».

### La remarque vit sous la ligne qu'elle vise
Le volet du pied dit **combien** il reste à relire ; il ne dit pas **où** pendant qu'on écrit.
`stepNote` (pure, testée) rend la remarque qui concerne une étape, affichée sous elle et
seulement en édition — au repos, la page reste du texte.

Corollaire appliqué : `stepGuardTxt(steps,'bloc')` ne rend plus que la remarque de **bloc** (son
nombre d'étapes). Afficher la même remarque d'étape à deux endroits pour un seul défaut, c'était
du bruit — et cela se voyait à l'écran.

Vérifié : **801 tests × 2 moteurs** (+7), a11y 301/301, doctrine 112/112. Rien à rejouer côté
serveur.

## [4.67.0] — 2026-07-29
### L'éditeur d'étapes en quatre états — au repos, aucun chrome

Deux tentatives ont échoué avant celle-ci, et il faut savoir pourquoi : la v4.64 mettait les
outils sous le champ au focus (43 → 123 px, et ils poussaient le contenu à l'instant où le doigt
y entrait) ; la v4.66 réservait leur espace en permanence (plus rien ne bougeait, mais le champ
tombait à 173 px et chaque étape gardait son cadre — l'écran restait un formulaire dense).

La maquette retenue règle le problème **en amont**.

**1 · Repos — aucun chrome.** La ligne est du **texte** : ni bordure, ni fond, ni outils.
Exactement ce que le soignant lira. **38 px de hauteur, champ à 295 px** (contre 173). La rangée
entière est la cible : un tap n'importe où passe en édition.

**2 · Édition.** Le texte devient champ (≥ 16 px, donc pas de zoom iOS), curseur en place, et les
outils apparaissent **sous la ligne**. Une seule étape est en édition à la fois : la page au repos
reste aussi calme que la fiche en lecture. L'`<input>` reste dans le DOM en permanence — il porte
la valeur et l'auto-enregistrement ; c'est son **habillage** qui change, donc rien à re-rendre au
tap et rien qui saute.

**3 · ⏎ = item suivant.** Une checklist **se dicte** : la saisie en rafale ne doit jamais passer
par un menu. Entrée crée l'étape **juste en dessous**, vide, focus dedans, en étape **normale** —
les registres ⚠ et △ se posent après, par l'interrupteur, parce qu'on écrit d'abord et qu'on
qualifie ensuite. Et **un champ quitté vide fait disparaître l'item, sans dialogue** : jamais
pendant la frappe (effacer pour reformuler supprimerait la ligne sous le doigt), jamais la
dernière (un bloc garde une ligne où écrire), jamais pendant un déplacement.

**4 · Un « + » = une portée.** La palette ne vit qu'**entre** les blocs et ne liste que les objets
de niveau bloc — « Étape » n'y figure pas : dans un bloc, « + Étape » et ⏎ s'en chargent. La
position du bouton choisit la portée **à la place de l'auteur**, qui n'a jamais à se demander où
va atterrir ce qu'il ajoute. Chaque type dit sa **conséquence** en deux mots (« 2 branches »,
« durée + libellé »), pas sa définition.

Vérifié par une sonde dédiée sur **Chromium et WebKit** : repos sans cadre ni outils avec poignée
visible, outils sous la ligne et champ ≥ 16 px en édition, ⏎ qui crée une étape vide avec le focus
dedans, disparition au blur, palette sans « Étape ». Plus 794 tests × 2 moteurs, a11y 301/301,
doctrine 112/112. Rien à rejouer côté serveur.

## [4.66.0] — 2026-07-29
### Deux défauts d'usage de l'éditeur sur smartphone — signalés, puis mesurés

### La rangée d'outils poussait le contenu
Signalé : « c'est compliqué sur smartphone, la bande attention/déplacer/supprimer qui apparaît
prend beaucoup de place ». Mesuré : la rangée faisait passer l'étape de **43 à 123 px** — et
surtout elle **poussait le contenu à l'instant précis où le doigt entrait dans le champ**, ce que
la doctrine du projet interdit (« rien ne bouge sous le doigt »).

Les outils se **révèlent** désormais au lieu d'apparaître : `visibility` et non `display`. Leur
espace est réservé en permanence, donc la hauteur de la rangée et la largeur du champ ne changent
**jamais** — seule l'encre paraît. C'est le précédent des pilules d'option du mode statique,
masquées en `visibility:hidden` précisément pour que l'espace cesse d'osciller. `pointer-events`
suit la visibilité : un bouton invisible ne capte pas le tap voisin.

Les pixels rendus au champ sous 400 px viennent du **cadre** (rembourrage du bloc 14 → 9 px, case
26 → 22 px), jamais d'une cible tactile — les boutons gardent 32 px. Le champ passe de 161 à
**173 px**, et la rangée reste à **43 px, focus ou non**.

### Le bouton « déplacer » faisait sauter l'écran de 326 px
Signalé aussi. Deux causes cumulées : le re-rendu insère les interstices de dépôt **au-dessus** du
point regardé, et un `scrollIntoView` visait ensuite le bandeau « en main » — qui est *sticky*,
donc déjà visible sans qu'on défile.

Prendre et poser passent maintenant par **`keepAnchor`**, la mécanique d'ancrage du projet :
l'objet pris ne bouge plus que de **0,7 px**, le bloc receveur de **0,6 px**. Les cibles
apparaissent autour de ce que l'auteur regarde, au lieu de l'emporter ailleurs.

Vérifié : 794 tests × 2 moteurs, a11y 301/301, doctrine 112/112, aucun débordement horizontal à
390 px. Rien à rejouer côté serveur.

## [4.65.0] — 2026-07-29
### La porte « + » — une seule, et chaque type se présente

Six boutons d'ajout vivaient dispersés dans trois sections de l'éditeur : « + Bloc d'étapes »,
« + Décision (si… alors…) », « + Chronomètre », « + Minuteur (cycle) », « + Ajouter un compteur »,
« ＋ Complication ». Pour savoir ce qu'on **pouvait** ajouter, il fallait faire défiler la page
entière — et rien ne disait à quoi chaque type sert.

Une seule porte pointillée les rassemble : **« ＋ Étape · décision · minuteur… »**. Elle ouvre une
palette où **chaque type se présente** — le glyphe, le nom, et une ligne dans les mots du
soignant :

- **Bloc d'étapes** — une suite d'actions à cocher, l'unité de base d'une checklist
- **Décision (si… alors…)** — une question et ses branches : « Choquable ? » → chaque réponse mène
  à son bloc
- **Minuteur à cycles** — un temps qui se relance et compte les tours (ex. RCP 2 min)
- **Chronomètre** — un temps qui monte, sans échéance
- **Compteur** — ce qu'on compte pendant le soin : chocs, doses d'adrénaline…
- **Complication** — un événement qui peut survenir à tout moment, le retour est prévu

**C'est là que les registres s'apprennent, avant la crise.** Les explications sont écrites au
moment où l'auteur choisit, pas dans un guide qu'on replie une fois pour toutes.

La fenêtre passe par le gestionnaire de modales commun (Échap, clic de voile, piège de focus,
retour système d'Android) et se ferme à l'insertion, l'éditeur se re-rendant aussitôt — sinon la
porte demanderait un geste pour ouvrir et un autre pour retrouver ce qu'elle vient de créer. Les
six gestes sont intacts : on a supprimé les **portes**, pas les capacités.

**K5 est reporté** sur décision de l'utilisateur (« l'enregistrement se dit, ne se demande pas » :
auto-enregistrement horodaté dans la barre, « ▶ Essayer » promu bouton rempli unique). Il déplace
l'action primaire de l'écran, et l'éditeur s'auto-enregistre déjà sans le dire — c'est la promesse
affichée qui changerait, pas la mécanique.

Vérifié : 794 tests × 2 moteurs, a11y 301/301, doctrine 112/112. Rien à rejouer côté serveur.

## [4.64.0] — 2026-07-29
### K1 — on édite dans la grammaire de lecture

L'éditeur était un formulaire : champs empilés d'un côté, aperçu de l'autre. L'auteur composait à
l'aveugle et ne découvrait le rendu qu'en basculant. Désormais **le chapeau EST le cadre rouge**,
**un bloc EST sa carte**, **une étape EST sa rangée** — les champs prennent la place exacte du
texte final, aux mêmes corps et aux mêmes registres. Ce que l'auteur voit est ce que le soignant
verra : le garde-fou le plus puissant est visuel.

- Le bloc d'édition reprend l'anatomie de la carte de lecture : mêmes bordures, liseré gauche de
  4 px, même rayon — **ambre pour une décision**, neutre pour un bloc d'étapes, comme en lecture.
- Une étape ⚠ porte sa boîte rouge, une étape △ sa boîte ambre, avec la case à gauche.
- **Ce qui n'est pas copié, délibérément** : la case reste un **glyphe inerte**. Un éditeur où
  l'on pourrait cocher ferait croire qu'on prépare un état ; on rédige une aide, on ne la déroule
  pas.

### K3 — les outils suivent le focus
Trois boutons par étape multipliés par huit étapes, cela faisait vingt-quatre cibles pour un écran
où l'on écrit **une ligne à la fois**. La rangée ⚠ ✕ ⠿ n'existe désormais que sur l'étape
**active** — atteignable au clavier (`:focus-within` s'ouvre dès que la tabulation entre dans le
champ), et le survol est neutralisé sur pointeur grossier, où l'étape active est celle où l'on
écrit. Mesuré : **43 px au repos, 123 px active**.

### MK5-b — réordonner par « prendre / poser », deux taps, zéro maintien
Un tap sur la poignée ⠿ **soulève** l'objet et réécrit la page en cibles pleine largeur ≥ 44 px ;
un tap sur un interstice le **pose**. Pas de maintien ni de glisser — c'est le point de
défaillance du drag au doigt (gants, une seule main, véhicule qui bouge). Les boutons ↑ ↓
deviennent redondants et quittent la rangée d'outils.

- L'objet « en main » n'est **jamais persisté** : c'est un geste, pas un état du brouillon.
- **Échap ou ✕ le reposent** là où il était : un geste interrompu ne déplace rien.
- **Garde-fou QRH** : sortir une étape ⚠ de son bloc change son contexte — la cible s'annonce
  alors en △ **avant** le dépôt, sans jamais l'interdire. L'auteur reste l'expert de sa fiche.

### Deux pièges
- Les étapes d'un bloc vivent **hors** de `.list-edit` : leur rangée n'avait donc aucune règle de
  flex, et les trois objets (case, champ, outils) s'empilaient dès l'ajout de la case.
- La bibliothèque est **vide au premier démarrage** : une sonde d'éditeur doit passer par
  « Commencer » puis « Ajouter les fiches d'exemple », comme les autres harnais — sans quoi elle
  mesure une page sans fiche et conclut à tort que tout échoue.

Vérifié : 794 tests × 2 moteurs, a11y 301/301, doctrine 112/112, et une sonde dédiée sur
**Chromium et WebKit** (outils au focus, 12 cibles ≥ 44 px, garde-fou QRH, déplacement effectif,
Échap sans effet de bord, cadre rouge du chapeau). Rien à rejouer côté serveur.

## [4.63.0] — 2026-07-29
### Phase K — la doctrine relit par-dessus l'épaule, et la page revient au contenu clinique

L'éditeur est l'envers de la crise : on y travaille au calme, et chaque minute investie là achète
des secondes ici. Deux changements, sur l'éditeur existant.

### K2 — la relecture doctrinale, en une seule grammaire
Les garde-fous existaient déjà (chapeau à 4 rappels, bloc à 7 étapes, challenge trop long, étape
qui cumule des actions) — mais **dispersés**, chacun sous son champ. L'auteur ne savait pas, en
fermant l'éditeur, ce qu'il laissait derrière lui.

`reviewNotes(f)` (pure, testée) les rassemble : chaque remarque **nomme sa cible** et l'action
proposée. Un volet « △ Relecture · n » en pied de page les liste et **ancre** vers la ligne
concernée, qui clignote une fois — sans voler le curseur : l'auteur vient de lire le bilan, c'est
à lui de choisir ce qu'il corrige.

**Jamais bloquant, jamais rouge**, et le volet le dit en toutes lettres : « aucune de ces
remarques n'empêche d'enregistrer — c'est vous qui connaissez votre service ». L'ambre est le
registre du « c'est là qu'on se trompe » ; le rouge reste à ce qui tue. Le volet **disparaît**
quand il n'y a rien à dire : un panneau affichant « 0 remarque » serait du bruit permanent pour
une information qu'on lit une fois.

### K4 — « Identité » se replie
Titre, catégorie, bibliothèque, code, date de validation et état occupaient tout le haut de
l'éditeur : on traversait six champs administratifs avant d'atteindre ce qu'on vient écrire. Ils
vivent maintenant dans un dépliant dont l'en-tête **porte déjà le titre et le code** — replié, il
n'escamote donc rien qu'on vérifie d'un coup d'œil.

**Ouvert d'office en création, replié en modification** : sur une fiche neuve, le titre est le
premier geste ; sur une fiche existante, il est déjà écrit et ce qu'on vient corriger est le
contenu. La distinction se fait sur le **titre vide**, pas sur l'existence de la fiche — dupliquer
donne un titre, repartir de zéro n'en donne pas. Le statut éditorial reste **en plus** dans la
barre : c'est un état, il ne se replie pas.

### Piège mesuré
`scrollIntoView({behavior:'smooth'})` **ne défilait pas du tout** sur 6 400 px d'écart — et aucun
défilement de l'application n'est animé. L'ancrage est direct.

### Non engagé, et pourquoi
K1 (éditer dans la grammaire de lecture) et K5 (« ▶ Essayer » comme bouton rempli unique) changent
le **geste** d'édition ; K10 (raccourcis à la frappe, import/export markdown structuré) ouvre un
parseur ; K6 (le discriminant en champ séparé) ajoute un **champ modèle**, donc touche `migrate`,
l'export v3 et l'affichage des titres partout. Chacun se décide séparément.

Vérifié : **794 tests × 2 moteurs** (+9), a11y 301/301, doctrine 112/112, lecteur 14/14,
consulter 8/8. Rien à rejouer côté serveur.
