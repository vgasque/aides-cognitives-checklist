# Lot v5.33 — l'éditeur : écrire d'abord, régler ensuite (A383)

> Fichier normatif, suite de [`lot-v5-32.md`](lot-v5-32.md) (A382). Les numéros A sont des adresses :
> ne jamais renuméroter. Demande de l'auteur (26/09/2026) : « le mode édition ne doit pas être trop
> superflu d'informations et de clics — un novice qui veut juste cocher des cases et écrire ne doit pas
> être perdu ; l'utilisateur aguerri doit trouver les réglages sans sous-sous-menus ». Audit mesuré
> (ACR, 390 px : 9 200 px d'éditeur, 196 commandes ; une étape touchée passait de 70 à plus de 500 px),
> puis maquettes sur canevas (page « Éditeur », E1-E7) revues fil par fil, et captures réelles validées.

## A383 — une étape s'écrit sans rien ouvrir ; ses réglages sont à UN toucher (v5.33.0)

**Le défaut.** Toucher le texte d'une étape dépliait onze commandes (registre, ★, ×2, lien de coche,
« Commence », seuil, « Puis », supprimer…) ; certaines ne pouvaient servir à rien (le moment dans un bloc
qui ne se répète pas — régression de la v5.32) ; les listes empilées n'avaient pas d'intitulé.

**La rangée d'étape** (`blockEditor`) : poignée · texte 17,5/700 · bouton « Réglages » (`.li-set`, 40 px,
bleu doux quand quelque chose est réglé) ; dessous la réponse attendue, puis ce qui est réglé en
PASTILLES (`edStepSum` : Critique / Vigilance, ★ Mémoire, ×2 en chasse fixe, « ⏱ lance … » / « +1 … »,
« Chocs délivrés ≥ 3 », « à l'échéance » / « une seule fois » / « au besoin »). Le registre se dit par la
pastille, plus par une marque ni une teinte dans le champ (`.li-mk`, `.li-crit` purgés). Écrire n'allume
que les champs (`:has(input:focus)`, jamais le focus du bouton). Filet entre étapes, marges de 4 px :
≈ −20 % de hauteur, cibles tenues (champ 32 px, réponse ≥ 24 px, bouton 40 px, corps ≥ 16 px).

**La feuille « Réglages de l'étape »** (`#stepSetModal`, `stepSetHtml`) : feuille basse au téléphone
(grammaire de la feuille ⋯), fenêtre centrée dès 780 (celle de « Affichage » — un panneau latéral sous
voile ne montrait rien de plus). « OK » ferme. Trois sections nommées : IMPORTANCE (segmenté Normale ·
Vigilance · Critique, interrupteurs Mémoire et ×2), CE QUE FAIT LA COCHE (la liste ; sans minuteur ni
compteur, deux boutons « ＋ Créer » qui créent ET lient, nommés d'après l'étape), MOMENT (segmenté « Dès le
1ᵉʳ passage / À partir d'un compte », compteur + pas −/+, grille « Puis revient » en quatre cases ; « À
l'échéance » dit de quel minuteur, ou pourquoi il est fermé — son toucher mène à la coche, A235).
« Supprimer l'étape » en bouton danger. Chaque réglage re-rend l'éditeur ancré sur la rangée et garde le
focus dans la feuille ; fermer le rend au bouton « Réglages ».

**Point 2 — ce qui ne peut servir à rien n'est pas montré** : le Moment, le minuteur du bloc et les jalons
n'existent que si le bloc SE RÉPÈTE (`blkInLoop`, déduit du parcours — rien à déclarer) ou s'ils sont déjà
posés (on ne cache jamais une donnée). Hors boucle, une phrase dit où le moment se règle. Le bloc qui se
répète le dit (« ↺ Se répète » sous le titre).

**Le bloc** : titre en texte au repos (21/800), étapes, « + Ajouter une étape », étape suivante, puis
« Options du bloc » — la carte dépliable de l'app (`foldCardHtml`), résumé à droite, ouverte d'office
quand une option est posée (le départ seul ne compte pas) : rangées libellé | valeur (bloc de départ en
interrupteur, phase, libellé de « Continuer », minuteur du bloc, jalons, image). La phase QUITTE l'en-tête.
« Supprimer le bloc » hors de la carte, en bouton danger. Les règles d'usage (« Rouge, ambre, réponse
attendue ») : une fois, en tête de « Prise en charge ».

**Le jalon se lit comme une phrase** : [Passages du bloc | compteur ▾] ≥ [− n +] — la même forme que le
moment et que la pastille « Chocs délivrés ≥ 3 » (l'ancien « quand un compteur atteint n » tronqué, puis
un nombre, puis le compteur, n'avait pas de lecture).

**Refusés** (à ne pas reproposer sans l'auteur) : un mode « simple / expert » global (l'utilisateur qui
change d'avis ne retrouve rien) ; un menu ⋯ à sous-menus ; un panneau latéral au bureau.

**Écart nommé aux maquettes** : la réponse attendue reste dans la police du texte à 16 px (la maquette
la voulait en chasse fixe 13,5 : sous 16 px, iOS zoome au toucher — règle 9).

**Témoins.** `audit-doctrine` A383 (écrire n'ouvre rien, boucle, point 2, pastilles, feuille qui écrit le
brouillon et garde le focus, retour du focus, phrase hors boucle, feuille basse à 390 / centrée à 1280) ;
T7 pose l'étoile par la feuille ; `audit-k5` (suppression d'étape par la feuille, registre, phase dans
les options) ; `audit-a11y` mesure la feuille.

## A384 — v5.33.1 : retours d'usage sur l'éditeur allégé

**La rangée d'étape reste ouverte tant que le focus reste en elle** (`.ed-on`, posée en JS au
`focusin`, retirée au `focusout` seulement si `relatedTarget` sort de la rangée). Mesuré : cliquer
la réponse attendue VIDE repliait l'étape. `:has(input:focus)` se relâchait ENTRE le blur du titre et
le focus du champ — le champ passait à `display:none`, le navigateur abandonnait le focus (trace :
`focusout rel=li-exp`, aucun `focusin`) et le clic tombait sur l'étape suivante. ⚠ Tout champ qui ne
paraît « qu'au focus de sa rangée » a ce défaut s'il est piloté par `:has(:focus)` ou `:focus-within`.

**Le gabarit des champs du bloc est celui des listes du chapeau** (« Condition d'entrée », « Ne pas
oublier ») : 15 px, rembourrage 8, ≈ 40 px (M) ; 16 px au toucher (règle 9, liste du bloc
`pointer:coarse`). Vaut pour le titre d'étape (700), la réponse attendue À L'ÉDITION, la question
d'une décision (son style en ligne est parti), les réponses et les cibles (`select` à 40 : son
rembourrage le portait à 41,5). Au REPOS la réponse attendue reste une ligne de texte serrée sous le
titre (marge −8 qui reprend le rembourrage du titre) ; à l'édition elle devient un champ, 6 px dessous.
Amende l'« écart nommé » d'A383 : 15 px au pointeur fin, 16 au toucher. La réponse s'arrête avant
« Réglages » (marge droite 48), qui ne déborde plus sur le filet du dessus.

**Le glisser de la pastille est délégué une fois au document** : `bindSegDrag` n'existe plus. Chaque
sélecteur devait l'appeler à sa naissance, et chaque sélecteur neuf l'oubliait (« Importance »). Tout
`.seg` à `.seg-pill` directe glisse ; l'engagement reste un click synthétique sur le cran visé.

**Un seul dessin pour les boutons d'outil de l'éditeur** (`.ed-ic`) : M 40 sur la matière blanche des
boutons de l'app (`.fz` — fond `--work`, filet, ombre). Une première version SANS fond (celle de
« Réglages ») a été refusée à l'usage : sur le gris de la ligne éditée, le B ne se lisait plus comme un bouton. Il remplace QUATRE dessins nés à des époques différentes : la case blanche bordée
(`.mini.del`, rappels · réponses · minuteurs · compteurs · documents), sa variante rouge des listes, le pavé
gris `.tk-del` (complications, jalons) et les cases B / △ des listes (`.mini.bld`, `.crit-tgl`, purgés
avec `.fg-go` et `.li-tools .mini.del`). La croix rougit au SURVOL seulement (un rouge au repos répété sur
chaque ligne criait plus fort que les étapes critiques) ; le △ posé prend le fond ambre du registre. Le
`.mini.bld` de la barre Markdown du protocole reste : c'est une barre d'outils à libellés, pas une rangée.
**La croix d'une complication chevauchait la cible** : `padding-right:32px` pour une croix de 38 ;
réservé désormais à 48 (40 + 8). Le champ « Événement » n'avait pas `type="text"` — aucune règle de
champ ne l'atteignait (bordure carrée du navigateur) ; la cible se dessine comme le `<select>` d'une réponse.

**Textes** : « ×2 Confirmée par les deux » dit sa portée (« en session, marquée ×2 : les deux soignants
la vérifient à voix haute ») ; « Libellé de « Continuer » » est dit facultatif ; 8 px sous
« Importance ».

## A385 — l'invité figé garde ses gestes ; sa propre session reste la sienne (v5.33.2)

**Signalé par l'auteur** (26/09/2026) : (1) « invité d'un partage en ligne, la connexion se coupe →
il ne peut plus rien modifier » ; (2) « l'invité quitte la session en cours, rouvre la même aide sur
son profil, lance un exercice ou une session normale → il revient sur la page de la session
partagée ».

**Mesuré d'abord** (sonde sur le banc relais d'`audit-partage`) :

| Situation | Avant | Cause |
|---|---|---|
| Invité en ligne, lien figé (> `staleLimit`) | coche refusée, rien en file, contrôles grisés (`body.share-stale`) | `canWrite` exigeait `!isStale()` — arbitrage d'A332 (« ne pas rouvrir les coches à l'invité figé ») |
| Invité revenu à l'accueil, même aide rouverte, SA session démarrée ; l'hôte coche 4 étapes et avance | les 4 coches et le bloc de l'hôte s'inscrivent dans la session LOCALE de l'invité (même fiche, mêmes clés) — elle devient la session partagée | `Share.onEvents` appliquait au `Runtime` courant, quel qu'il soit |
| Hôte qui consulte une AUTRE aide pendant le partage ; l'invité coche | la coche entre dans l'autre aide, et manque à la session partagée | même cause, côté hôte — **non corrigé ici** (voir plus bas) |

**Ce qui change** :
1. **L'invité figé écrit** (renverse l'arbitrage d'A332, décision de l'auteur) : `canWrite` ne regarde
   plus la péremption, seulement le statut et le rôle — l'invité suit la règle de l'hôte (A332 point 2).
   Ses gestes entrent dans la file persistée et partent au retour du réseau, par n'importe quel
   transport (la file voyage déjà aux bascules, v5.14.22). Le quai dit toujours « figé » ; la classe
   `share-stale` et son grisé sont purgés (le grisé reste celui de `share-dead`, statuts morts) ; la
   feuille et le bandeau disent « vos gestes partiront au retour du réseau » au lieu de « coches
   suspendues ». L'objection d'A332 — « écrasées à la resynchronisation » — est levée : `_cycle`
   POUSSE avant de tirer, `resume()` ne touche pas la file, et « Recevoir » par l'écran rejoue
   désormais la file par-dessus l'instantané de l'hôte (`slOptiqueGot`). Un « Quitter » avec des gestes
   non partis le dit déjà (`shareUnsent`). Ordre : le journal range par ARRIVÉE ; une coche faite
   figé arrivée après un décochage du conducteur sur la même étape la recoche — un geste additif,
   et décocher reste au conducteur.
2. **Chez l'invité, un lot ne s'applique qu'à la session partagée** (`onEvents` : `Runtime.started`
   et sans dossier local — la seule session sans `sessionId`). Le pli continue d'accumuler dans
   `_cycle`, `openSharedFiche` reconstruit au retour (« Revenir à la session partagée »). Les
   rangées de passation et de départ (menu, annonces) restent traitées.
3. **Une bascule automatique n'arrache plus l'invité à SA session** : `slSbGuestSwitch` et `slGcJoin`
   n'ouvrent la session partagée que si elle est à l'écran (`sharedShown()`).
4. **« Démarrer » / « Exercice » au quai suivent `ensureStarted`** : un invité sur son appareil les
   voit sur SES aides (v5.14.18 l'autorisait, le quai les cachait — seul le menu ⋯ y menait) ; seul
   l'invité sans trace n'a rien à démarrer.

**Reste dit et non corrigé** : côté HÔTE, consulter une autre aide pendant un partage expose la même
fuite (le lot s'applique au `Runtime` affiché) — la cible juste est `liveSessions[fiche partagée]`,
mais les appliqueurs lisent l'état global (`state`, `Runtime`) : correctif à part. **Corrigé en A387** (ci-dessous).

**Garde-fous** : `tests.html` — un invité périmé GARDE l'écriture ; `audit-partage` — section
« l'invité sur SA session de la même aide » (3 contrôles : Démarrer visible et session locale, zéro
coche de l'hôte dedans, retour qui les montre) et section « lien figé » réécrite (l'invité figé coche,
file à 1, quai « figé » ; au retour les coches se croisent — clé de l'invité distincte de celle de
l'hôte, sans quoi le contrôle était vert par la coche de l'hôte). Rejoués sur le code d'avant : 4
rouges.

## A386 — le volet du quai sous le clavier, et le rail en paysage (v5.33.2)

**Signalé par l'auteur** (26/09/2026, iPhone) : (1) « toucher l'heure dans le journal d'actions
referme le volet au premier coup, puis ça marche mais tout le contenu saute à chaque fois » ;
(2) « en paysage, la colonne de droite a un contenu tronqué » (capture : deux cartes de minuteur, la
seconde coupée).

**Mesuré** — au banc (deux moteurs, tactile émulé) puis sur le **simulateur iOS 27** (iPhone 17 Pro,
Safari, vrai clavier) :
1. Clavier ouvert, `html.kbd` rendait le volet (`.rt-dock`) au flux (`position:static`, décision
   v5.13 « rien n'est épinglé ») : il quittait l'écran pour sa place dans le DOM, en tête de colonne,
   emportant le champ touché — d'où « refermé ». L'en-tête avait déjà son exception (v5.14.1 : le
   champ qui ouvre le clavier y vit, il reste le chrome de frappe) ; le volet ne l'avait pas.
2. Valider l'heure re-rend le panneau (`renderTkOnly`) PENDANT le blur du champ : son `focusout`
   n'atteint plus le document, `body.kb-open` restait posée — dock masqué (`display:none`) et bas de
   `main` qui change (`body.dock-on.kb-open main{padding-bottom:0}`) : le saut. Mesuré aux deux
   moteurs : `kb-open` vraie et dock `none` après validation.
3. Le volet est fixe et de hauteur constante (`svh`, v5.4.2) : Safari ne remonte pas un champ d'une
   couche fixe — une rangée basse du journal finissait sous la barre du clavier, pastilles
   « −1/−2/−5 min » comprises (vu au simulateur).
4. Paysage 844 × 340 : le rail collant a pour hauteur la fenêtre moins en-tête, quai et dock — **110 px
   pour 1 058 px de contenu**.

**Ce qui change** :
1. La garde de `html.kbd` s'étend au volet : un champ qui y vit garde le volet (et le chrome) en place.
2. `renderTkOnly` resynchronise `kb-open` (`_kbSync`, le poseur unique déjà rejoué à chaque rendu).
3. Un champ du volet qui prend le focus fait défiler **le volet seul** (jamais la page), une fois, du
   strict nécessaire pour passer au-dessus du clavier — rembourrage provisoire s'il manque de course,
   retiré à la sortie du champ.
4. `zh500` (hauteur effective < 500 = `innerHeight ÷ zoom`, classe posée par `syncZoomWidth` comme
   les `zw*`, règle 10) : le rail redevient du flux (`position:static`, hauteur de son contenu). Les
   téléphones en paysage sont tous sous 440 px, une tablette au-dessus de 670 : aucun basculement au
   repli de la barre d'outils.

**Garde-fous** : `audit-doctrine`, section « volet du quai : corriger une heure rend le dock ; rail en
paysage » (5 contrôles, 2 rouges sur le code d'avant). Le comportement sous clavier réel (points 1 et
3) ne se pilote pas en headless : vérifié au simulateur iOS — volet ouvert, champ et pastilles
au-dessus du clavier, « −2 min » appliqué, dock revenu.

## A387 — l'hôte qui consulte une autre aide : les gestes de l'invité vont à la session partagée

**Trouvé en corrigeant A385** (le pendant côté hôte, reproduit au banc relais d'`audit-partage`) :
pendant un partage, l'hôte ouvre une AUTRE aide (`openRead(autre)`). Deux défauts :

| Situation | Avant | Cause |
|---|---|---|
| L'invité coche, incrémente | la coche entre dans l'aide AFFICHÉE ; la session partagée (`liveSessions[fiche partagée]`) ne la reçoit jamais — curseur avancé, geste perdu ; au retour, l'étape est vide | `Share.onEvents` applique au `Runtime` courant |
| L'hôte démarre une session locale sur l'autre aide et coche | 2 évènements partent sur le fil de l'invité (coches et navigation d'une AUTRE fiche) | `shareEmitDiff` n'avait de garde que chez l'invité ; `persistAllLive` (passage en arrière-plan) exposait le même trou dès deux sessions vives |
| En plus, à chaque lot reçu hors écran | `shareRebase()` recalait la base de diff sur l'AUTRE aide | idem |

**Ce qui change** :
1. **`Share.hostedRt()`** : la session que l'hôte partage = `liveSessions[Share.fiche.id]`, qu'elle
   soit à l'écran ou non (une recherche, pas une référence gardée : pas d'objet périmé).
2. **L'état se sépare de la peinture** dans les appliqueurs : `shareStateLive(R,e)` (coche,
   compteur, minuteur, repère, annexe, début de session), `shareNavState(R,p)` et `shareVfState(R,e)`
   écrivent l'état sur une session DONNÉE ; `sharePaintLive` et `shareApplyAnchored` les appellent
   sur `Runtime` puis peignent, exactement comme avant. L'état n'est écrit qu'une fois (leçon
   v4.42.0 : deux copies d'un même cœur divergent).
3. **`onEvents`, hôte hors de sa session** : `shareApplyAway` applique le lot à la session hébergée
   en état seul — rien ne se peint, rien de la VUE ne bouge (replis, mention « avancé par… »,
   `flowEnded`, état de vue que `openRead` remet de toute façon à faux) —, puis la base de diff
   suit la session hébergée et elle s'enregistre (`persistLive`). Aucune annonce : l'écran parle
   d'autre chose. La prise de main reste inscrite.
4. **`shareEmitDiff`, hôte** : seule la session hébergée émet. `flowEnded` ne se lit que sur la
   session affichée (sinon celui de la base).

**Garde-fous** : `audit-partage`, section « A387 · l'hôte sur une autre aide » (5 contrôles : témoin
d'aide affichée, coche et compteur dans la session partagée et pas dans l'aide affichée, zéro
évènement émis par la session locale de l'autre aide, coche peinte au retour). Sur le code d'avant :
4 rouges. Le contrôle du compteur passait À VIDE dans sa première écriture (le « + » vit dans le
volet replié sous 1000 px) : il passe par le cœur du geste (`cnInc`) et exige une valeur > 0.
