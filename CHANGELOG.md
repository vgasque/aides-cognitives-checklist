# Journal des modifications

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

## [4.62.0] — 2026-07-29
### I4 — une seule grammaire de progression : guidé, journal et lecteur ne font plus qu'une

Le chantier structurant de l'audit. Guidé, journal et mode lecteur n'étaient pas trois vues d'une
même chose : c'étaient **trois écritures** de la même chose.

### Pourquoi — c'est doctrinal
- **ECAM.** L'affichage d'Airbus repose sur UN format unique pour tous les états de l'avion : le
  pilote n'apprend pas trois écrans, il apprend UNE grammaire (position fixe, registres,
  priorités) qui se décline. Trois surfaces de progression, c'est l'anti-ECAM — trois
  cartographies mentales pour la même information. Harmonisées, celui qui a appris l'écran hôte
  **sait déjà** lire l'écran invité.
- **QRH.** Un manuel n'a qu'une mise en page de checklist, quel que soit le lecteur : celui qui
  lit et celui qui exécute regardent le **même document**, et c'est ce qui permet le cross-check à
  voix haute. Si le lecteur voit une autre structure que l'hôte, « bloc 2, ligne 2 » ne désigne
  plus la même chose et la vérification croisée se désynchronise.
- **FAA, facteurs humains.** La *mode confusion* naît d'un même écran qui se comporte
  différemment selon le mode sans signal univoque. La réponse canonique est : structure
  **constante** + annonciateur de mode saillant — pas des écrans différents. Ici l'interactivité
  et le placard changent ; la structure, jamais.
- **Et l'ingénierie qui en découle** : trois surfaces = trois endroits où un correctif peut
  diverger. Ce fichier a payé **deux fois** — les copies du cœur de cochage avaient divergé
  (v4.42.0), et un invité scribe **conduisait** la checklist depuis le lecteur parce que ses
  verbes portaient d'autres noms (v4.55.0).

### Ce qui est désormais unique
- **Le cœur** — `applyCheck` est LE point d'écriture de `state.checked` : garde de rôle, trace
  do-verify, acquittement haptique, drapeau de fin. Les trois appelants ne font plus que peindre.
  Le lecteur écrivait `state.checked` **en direct** ; c'était la troisième copie, jamais recensée.
- **Le vocabulaire** — le lecteur émet `data-ovnext`, `data-ovopt`, `data-cxback`. Plus de
  synonymes, donc plus de liste de gardes à tenir en double : un verbe ajouté demain est couvert
  des deux côtés d'office, parce qu'il n'y a plus de « deux côtés ».
- **La structure** — `stepsListHtml` génère l'unique `ol.steps > li[data-ck]`, trace de
  vérification comprise. Elle était écrite trois fois, et avait déjà divergé : le journal peignait
  la trace, la vue guidée non, pour la même donnée.

### Ce que ça change à l'écran
Le mode lecteur montre désormais **le bloc entier**, ligne courante en 22 px sur fond d'accent,
au lieu d'un paragraphe isolé. C'est le modèle **ECL Boeing** — liste entière + curseur — que
l'audit v4.28.0 opposait déjà au un-item-à-la-fois : perdre sa place est un mode de défaillance
premier (Degani & Wiener). Supprimés avec la structure qui les exigeait : `.rm-r` (la réponse
attendue vit dans la pilule de la ligne) et `.rm-ctx` (le contexte « précédent / suivant » était
une reconstruction manuelle de ce que la liste donne par construction).

### Deux pièges vécus
- `applyCheck` remet `state.flowEnded` à false — donc le test « la fin était actée, il faut
  re-rendre » de la vue guidée ne se déclenchait **plus jamais**. Il faut capturer l'état avant
  l'appel. Le journal, lui, teste la présence de `.flow-end` dans le DOM : il y était insensible.
  C'est `audit-doctrine` qui l'a attrapé.
- `data-rmopt` était un **homonyme** : « reader option » dans le lecteur, « remove option » dans
  l'éditeur — et comme `[data-rmopt]` figurait dans la liste des gestes muets, le bouton
  « supprimer une réponse » de l'**éditeur** était bridé en mode invité. Renommé `data-optdel`.

Un contrôle de harnais a été **réécrit, pas supprimé** : il cherchait `.rm-ctx` (le mécanisme) ; il
mesure désormais la propriété — le contexte est visible, l'étape précédente est marquée faite, et
toutes les lignes portent le même verbe. Il échouerait si la liste redevenait un item isolé.

Vérifié : 785 tests × 2 moteurs, a11y **301/301 sur les deux moteurs**, doctrine 112/112, lecteur
**14/14** (+1), partage 294/294, vérification 8/8, complications 20/20, exercice 20/20.
Rien à rejouer côté serveur.

## [4.61.0] — 2026-07-29
### Une voix typographique — Source Serif 4 pour les titres

Phase 5 du chantier d'audit (F5). Le système roulait tout en `system-ui` : sûr, mais anonyme.
**Source Serif 4** (licence SIL OFL, sous-ensemble latin seul, graisse 600 seule, **21 Ko**)
prend le **titre de fiche**, la **marque** et le **titre du compte rendu** — et rien d'autre.

Ce n'est pas une décoration : les titres sont les seuls survivants du scan sous stress, ils
méritent un dessin. Le texte courant reste `system-ui`, la police que l'appareil rend le mieux —
changer le corps d'une aide lue en réanimation n'a jamais été l'objet.

- **Embarquée, jamais appelée.** L'app fonctionne hors ligne par construction : une police de CDN
  ne s'afficherait pas là où elle sert, et `font-src 'self'` l'interdirait de toute façon. Elle
  entre dans `ASSETS` (précachée dès l'installation, règle 13) avec son README de provenance et
  de licence, sur le modèle de pdf.js.
- `font-display: swap` : le texte s'affiche immédiatement dans la police de repli et bascule
  quand la police est prête — jamais d'écran de titre vide, même au premier chargement.
- **Graisse 600, pas 800**, aux endroits qui étaient en 800 : c'est la seule graisse embarquée,
  en demander une autre produirait une graisse synthétique (plus lourde, moins nette).
- Le compte rendu **téléchargé** retombe sur Georgia — voulu : un document autonome ne dépend
  d'aucun serveur.

Piège rencontré : `check-sw` lit les chaînes d'`ASSETS` littéralement — un commentaire placé *à
l'intérieur* du tableau est pris pour une entrée de cache (25 faux problèmes). Il vit au-dessus.

Vérifié : 785 tests × 2 moteurs, a11y 301/301, doctrine 112/112, zoom-scroll 6/6, `check-sw`
13 assets. Rien à rejouer côté serveur.

## [4.60.0] — 2026-07-29
### Mode moniteur — le téléphone posé devient un afficheur

Phase 4 du chantier d'audit (D3). Sur un chariot, sur le tableau de bord d'une ambulance, ou sur
le second téléphone de l'invité, **personne ne tient l'appareil**. Le mode moniteur en fait un
écran d'état lisible **à deux mètres** : chrono de session, prochain minuteur (nom + temps en
très grand), dernier repère horodaté. C'est l'ECAM au sens propre — un écran qu'on lit sans le
toucher.

**Aucun contrôle, et c'est la propriété qui compte.** Un tap n'importe où revient à la fiche :
une surface sans commande ne peut pas être actionnée par mégarde, ce qu'on veut précisément d'un
appareil posé au milieu d'un soin.

- Le minuteur montré est choisi par `monPick` (pure, testée) : un **échu l'emporte toujours**
  (annonciateur ECAM — l'écart passe avant le nominal), sinon le plus proche de son échéance
  parmi ceux qui tournent.
- Registres inchangés : un échu s'y affiche en ambre **et avec le mot « échu »**, jamais la
  couleur seule.
- Le dernier repère passe par `tkLabels`, la même source que le compte rendu : aucune seconde
  vérité, et un repère sans étiquette retombe sur « Repère n » plutôt que sur un mot inventé.
- Coquille du mode lecteur (z-index 92, sous le flash d'alarme), armement du retour système à
  l'ouverture — toute surface plein écran doit se fermer au geste retour d'Android.
- Rafraîchi par le tick existant : **aucune horloge en plus**.
- Entrée par le menu ⋯ des deux rôles, groupe « conduite en cours », visible seulement quand la
  session est démarrée — jamais dans le chrome de crise, qui n'a que 2,1 px de marge à 320 px.

Piège de test rencontré : `lastStart` est un **horodatage**, pas un délai — posé à 0 sur un
minuteur qui tourne, il fait croire à `now` millisecondes écoulées, et le test mesure alors
l'ordre de la fiche au lieu du tri.

Vérifié : 785 tests × 2 moteurs (+5), a11y 301/301, doctrine 112/112, lecteur 13/13, exercice
20/20. Rien à rejouer côté serveur.

## [4.59.0] — 2026-07-29
### Grand écran : le cockpit trois zones — orientation | action | état

Phase 3 du chantier d'audit (F4). À partir de **1200 px**, la vue de lecture tient de front la
colonne « Se repérer » (le plan, à gauche), le parcours (au centre) et le rail minuteurs (à
droite) : l'idéal ECAM — E/WD et SD sous les yeux en même temps. Pour un binôme hospitalier,
c'est un poste fixe où l'aide-lecteur voit plan, parcours et minuteurs **sans un tap**.

**Palier 1200, pas 1000.** L'audit proposait 1000 px « puisque le palier existe ». Mesuré : à
1000 px les trois colonnes laissent **~390 px** au contenu clinique — moins qu'une tablette en
portrait, pour ce qu'on lit sous stress. À 1200 px : plan 240, action 594 (son plafond de 860
au-delà), rail 360. Aucun palier nouveau n'est créé.

**Le plan quitte le rail droit** à cette largeur : l'afficher aux deux endroits ferait deux
sources pour la même structure — la règle qui vaut déjà pour les minuteurs nominaux.

**L'ordre du DOM reste celui de la lecture.** La colonne de plan est posée *après* la colonne
d'action et ramenée à gauche par `order` : ni un lecteur d'écran ni une tabulation ne doivent
traverser le plan pour atteindre la checklist. Le plan de gauche est le même
`ovPlanLadderHtml` désaturé, **inerte au cochage** (décision figée) — seul son logement change.

Le franchissement du palier **re-rend** (comme le rail à 780 et l'aperçu d'éditeur à 1000) :
c'est un changement de structure, pas de style. Piège vécu au passage : la règle du palier 1200
est déclarée deux fois (en tête puis réaffirmée plus bas, piège de cascade documenté) — la
variante cockpit doit suivre aux deux sites, sinon elle perd à l'ordre.

Vérifié : 780 tests × 2 moteurs, a11y 301/301, doctrine 112/112, zoom-scroll 6/6, vérification
8/8. Rien à rejouer côté serveur.

## [4.58.0] — 2026-07-29
### L'état de mode cesse de bouger — il s'ancre au coin haut-droit

Phase 2 du chantier ouvert après l'audit de design (concept H/B).

La pilule « ■ Mode crise » vivait à droite de la bande-titre quand celle-ci était dépliée, puis
**sautait au milieu de la ligne fusionnée** dès qu'on faisait défiler — et changeait de mot au
passage (« ■ MODE CRISE » ici, « ■ CRISE » là). Or c'est l'objet qui doit se lire en moins d'une
seconde : il devrait être le plus stable de l'écran, pas le moins.

Il est désormais **accolé à ◐ ⋯**, les deux seuls objets qui ne bougent dans aucun des deux
états, et **ne dépend plus du défilement**. Mesuré : même pixel (231 px à 360), même mot, déplié
comme condensé.

### Ce que ce concept n'apporte pas
Les ~90 px rendus au titre étaient le mérite du **concept A** (la pilule descendait dans le
quai), écarté par l'audit lui-même : le quai est la rangée de la télémétrie vive, et pour
l'invité un jeton de mode y doublonnerait les jetons de partage existants. Le gain de B est la
**stabilité**, pas la largeur.

### Deux amendements à l'audit, mesurés
- Il proposait de **vider la bande-titre de son état**. Cela aurait retiré le placard
  « ▪ Vous suivez » posé sur décision utilisateur en v4.55.4 — précisément parce que le bandeau
  est « l'endroit le plus lu » — et fait tomber deux contrôles de harnais qui encodent cette
  doctrine. Le bandeau garde donc son annonce en toutes lettres : la redondance est **voulue**,
  comme l'alarme au quai et au rail.
- Un **repli au glyphe seul** sous 430 px rendait ~41 px au titre. Annulé : en état condensé le
  bandeau est parti, il ne resterait qu'un carré rouge — la couleur et la forme seules pour dire
  le mode, ce que WCAG 1.4.1 et la règle « la couleur n'est jamais seule » interdisent l'une
  comme l'autre.

Le **liseré de mode 10 px** proposé par l'audit n'est pas posé : le placard hachuré de v4.55.4
est déjà le canal périphérique pour l'exercice et l'invité, à coût de hauteur nul — un liseré
serait un troisième dispositif pour la même information.

Vérifié : 780 tests × 2 moteurs, a11y 301/301, doctrine 112/112, exercice 20/20, partage 294/294.
Rien à rejouer côté serveur.
