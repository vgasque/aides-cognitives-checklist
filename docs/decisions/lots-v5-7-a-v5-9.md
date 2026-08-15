# Archive doctrinale — extraite d'AGENTS.md (v5.10.3)

> Contenu repris À L'OCTET depuis AGENTS.md (patron du découpage du changelog, v5.0.0) —
> aucune réécriture. Ces entrées restent NORMATIVES : elles portent les décisions et leurs
> raisons ; AGENTS.md garde les règles vivantes et renvoie ici. Empreinte du bloc extrait :
> sha256:4ed217b01343.

## Lot v5.7 — « la bonne information, au bon moment, au bon endroit »

> Huit propositions d'un audit transverse, plus deux retraits qui font jurisprudence. Chacune
> répond à l'un de trois tests : le LIEU (l'information est-elle où le geste a lieu ?), le MOMENT
> (arrive-t-elle avant la décision ?), le GESTE (le plus fréquent est-il le moins cher ?).
> **Rien n'y déduit quoi que ce soit d'un paramètre patient** : toutes font une soustraction
> d'horodatages, un comptage de cases, ou un déplacement d'information déjà présente.

**A113. LA BARRE DE RETOUR AU BLOC COURANT (v5.7).** Trois mécanismes ramenaient au soin, et aucun
ne couvrait le cas le plus fréquent : `landOnBout` ne joue qu'à la RÉENTRÉE dans la fiche,
`ovAdvanceRender` qu'au GESTE D'AVANCEMENT, `cxScrollTo` qu'à l'entrée sur complication. Défiler à
la main pour relire une étape, vérifier une dose plus bas, regarder le journal — et l'on remontait
en cherchant la carte à bordure bleue. `#blkReturn` n'existe que tant que la carte du bloc courant
est **entièrement** hors de la zone utile (sous les couches collantes, au-dessus du dock) et nomme
sa destination (A15 : une excursion sait revenir).
· **PRÉCÉDENT DÉJÀ ACCEPTÉ** : `.sess-start.afloat` (v4.73.0) — transitoire, aucune hauteur au
  flux, critère le plus étroit possible. Elle ne défile JAMAIS toute seule : c'est une porte.
· **UN OBSERVATEUR, PAS UN ÉCOUTEUR DE DÉFILEMENT**, et IDEMPOTENT (on ne réinstalle que si la
  carte a changé) — la fonction tourne à chaque tick, elle doit être gratuite quand rien ne bouge.
· ⚠ **DEUX ALTERNATIVES ÉCARTÉES** : une cinquième touche de dock (A18 le fixe à quatre de largeur
  égale ; une cinquième ferait tomber les étiquettes sous 320 px) ; surcharger « ⤢ Tout voir », qui
  a déjà deux états — un troisième ferait qu'une même touche à une même place ferait trois choses
  selon un état invisible, c'est-à-dire de la mode confusion (FAA).
· ⚠ **LE CLIQUET `pointer-events:none` DE `check-anim` EST PASSÉ DE 18 À 19, et c'est une
  DÉCISION** : la coque couvre toute la largeur et ne doit rien intercepter (seul `.bkr` est
  tapable), sinon elle volerait les taps sur la colonne d'action précisément quand on défile.

**A113b. UN NŒUD DÉTACHÉ N'EST PAS « HORS ZONE », IL N'EST PLUS LÀ (v5.7, signalé à l'usage :
« à chaque fois que la vue se met à jour, le bandeau vert s'affiche quelques ms — c'est moche et
très perturbant »).** Entre un rendu du journal et le prochain passage de `syncBlkReturn`,
l'`IntersectionObserver` surveillait encore l'ANCIENNE carte, désormais détachée. Un élément
détaché ne coupe aucune zone : `isIntersecting` vaut FAUX, donc « hors zone », donc la barre
paraissait — puis disparaissait dès l'observateur repointé. **Mesuré : visible de 146 à 214 ms, à
chaque re-rendu.**
· **DEUX EXPLICATIONS PLAUSIBLES ÉCARTÉES PAR LA MESURE, ET C'EST L'INTÉRÊT DU DOSSIER** :
  (a) « la première notification porte une géométrie transitoire » — j'ai tranché moi-même en
  synchrone, avec les mêmes bornes que la marge de racine : toujours faux ; (b) « la page se pose
  encore » — échantillonnée de 0 à 300 ms, la géométrie est INVARIANTE (rTop 243, rBot 802,
  `stickBase` 127, `--dock-h` 72). C'est en constatant que rien ne bougeait qu'il est devenu clair
  que le verdict portait sur un AUTRE NŒUD que celui qu'on regarde.
· **UN DÉLAI DE CONFIRMATION A ÉTÉ ÉCRIT PUIS RETIRÉ** : masquer immédiat, montrer après 140 ms de
  verdict stable. Il supprimait le symptôme et aurait masqué la cause — et la cause aurait ressurgi
  ailleurs. On ignore les notifications d'un nœud détaché, et `renderOvOnly` repointe l'observateur
  au lieu d'attendre le tick : aucun seuil, aucun délai. *Borner le symptôme n'est pas corriger la
  cause* (A100).
· **LA CLÉ D'IDEMPOTENCE PORTE LE CONTENU, PAS LE NŒUD** : elle valait le nœud de la carte, que
  tout rendu remplace — on reconstruisait donc la barre à chaque fois, animation d'entrée comprise.
  Le COMPTE en est exclu et se peint sur place : l'y mettre aurait rendu le clignotement au premier
  cochage, le défaut signalé par une autre porte.

**A114. « TERMINER LA SESSION ? » DIT CE QUI RESTE OUVERT (v5.7).** La fenêtre portait le titre, la
durée et les conséquences — **aucun état**. C'est pourtant le seul instant où « il reste deux étapes
vitales non cochées au bloc 3 » sert encore : une seconde plus tard, la session est archivée.
`endSessOpenTxt(R)` est PURE et ne rend que des faits COMPTÉS, deux lignes au plus.
· **« Terminer » reste rouge plein et ACTIF** : une checklist annonce son incomplétude, elle
  n'interdit pas de la quitter (ECAM/QRH). Aucune condition ajoutée à la sortie.
· **NI SCORE, NI POURCENTAGE, NI « CONFORMITÉ »** — le § 2 du dossier de conformité nomme ce
  vocabulaire comme celui à ne jamais employer. Registre ATTENTION en CONTOUR, jamais un aplat (A11).
· ⚠ **ON NE COMPTE QUE LES BLOCS VISITÉS** : une étape vitale d'un bloc où l'on n'est jamais passé
  n'est pas oubliée, elle est HORS CHEMIN — la compter ferait paraître incomplète toute session
  qui a pris une branche. Rien à dire → le bloc n'existe pas.

**A115. UN COMPTEUR DIT « IL Y A », PAS SEULEMENT « À » (v5.7) — ET SON CHIFFRE POUSSE (M1).**
`cnLogTxt` rendait « consigné T+04:12 » : l'instant du dernier incrément. C'est juste, et ce n'est
pas la question qu'on se pose — en réanimation elle est toujours « ça fait combien de temps ? », et
on la calculait de tête sur un chrono qui est à l'autre bout de l'écran. La ligne porte les DEUX :
le T+ se relit (compte rendu, débriefing), le « il y a » décide maintenant.
· **AUCUN SEUIL, AUCUNE COULEUR QUI VARIE** : c'est la même soustraction d'horodatages qu'A81, sur
  les gestes de l'ÉQUIPE. Un seuil serait un JALON, et les jalons sont un champ d'AUTEUR (v5.5.0).
· **VIVANT PAR LE CHEMIN CHIRURGICAL** (`paintCnAgo`, anti-churn) : jamais un re-rendu, donc la
  carte ne change pas de hauteur (A9) — le texte s'écrit sur une ligne DÉJÀ là.
· **M1** : le chiffre pousse au tap (`cnPop`, 130 ms, `transform` seul). L'état est écrit AVANT
  (A68/2), l'animation est REMPLACÉE et jamais mise en file (A68/4 — retrait, calcul forcé,
  repose), et sa règle vit dans le bloc `no-preference`, donc l'inertie est acquise par
  construction. Elle ne joue QUE si la valeur a changé : un re-rendu ne la rejoue pas.

**A116. L'IMMINENCE EST UN ÉTAT, ET LE TRI DES MINUTEURS EST VIVANT (v5.7, deux décisions de
l'auteur, dont une qui rouvre mon arbitrage).**
· ⚠ **UN CONSTAT FAUX D'ABORD, ET IL FAUT LE DIRE** : j'avais annoncé que la capsule « triait déjà
  par temps restant ». Le tri existe (`withRem.sort((a,b)=>a.rem-b.rem)`) mais **il ne gouverne
  qu'une SÉLECTION** : `want` vaut `dueList.slice(0,2)` en voie large — où `dueList` ne retient que
  les ÉCHUS, donc un minuteur qui tourne n'y entre jamais — et `withRem.slice(0,1)` en étroit, qui
  n'en montre qu'un. Rien ne se réordonnait sous l'œil. J'avais lu la ligne, pas ce qu'elle
  alimente. Conséquence : mon premier marquage d'imminence était INERTE au-delà de 780 px.
· **L'IMMINENT ENTRE DANS LA CAPSULE EN VOIE LARGE**, juste derrière les échus. C'est un AJOUT à la
  doctrine v4.23.0 (« le rail porte déjà tous les minuteurs »), pas un oubli qu'on rattrape :
  celle-ci réserve l'exception à l'ALARME, et l'imminence est l'annonce d'une alarme qui va
  survenir — l'argument vaut mot pour mot, le rail DÉFILE. **« +n » ne change pas** : il ne compte
  que les échus non montrés.
· **VINGT SECONDES, ET C'EST UN SEUIL D'AFFICHAGE** (`TM_SOON_MS`) : il ne dit rien du patient et
  ne déclenche rien. Plus court, on voit l'imminence trop tard pour préparer un geste ; plus long,
  elle devient l'état PERMANENT d'un cycle de 2 min — 20 s valent 17 % du cycle réaliste le plus
  court, donc le signal reste rare, donc il signale encore.
· **MÊME REGISTRE QUE L'ÉCHU, UNE INTENSITÉ EN DESSOUS** : `△` + encre ambre, **sans aplat**, sans
  battement — A11 réserve la masse colorée à ce qui exige une action MAINTENANT, et le battement
  est la grammaire de l'alarme, pas de son annonce. Le glyphe survit à l'ellipse (patron du quai).
· **LE TRI DEVIENT VIVANT** (`tmLiveOrder`, une seule fonction pour le rendu ET le tick ; l'alarme,
  puis ce qui tourne par temps restant, puis le reste dans l'ordre de l'AUTEUR). `tmPanelOrder` est
  PURGÉ avec la version précédente (règle 14). **J'avais argumenté l'inverse** (« ne pas déplacer
  une cible sous le doigt ») et l'auteur a rouvert la décision : c'est la sienne.
· **CE QUI RESTE DE L'OBJECTION EST LE GARDE, ET IL EST DEVENU MEILLEUR** (demande de l'auteur :
  « un tout petit temps de latence pour comprendre qu'on a bien touché le bon minuteur »). Le geste
  le plus fréquent sur une carte est « Relancer », qui remet le temps restant au MAXIMUM : la carte
  tombait au bas de la liste À L'INSTANT où on venait de la toucher, et son accusé disparaissait
  sous le doigt. Le tri attend la fin du geste **plus 1,2 s** (`TM_HOLD_MS`) — assez pour lire la
  réponse de la carte, sous la seconde et demie à partir de laquelle un mouvement différé
  ressemble à un raté. Le focus clavier tient la liste immobile comme un doigt.
· **NON BLOQUANT PAR CONSTRUCTION** : le délai ne suspend QUE la réorganisation. Les minuteurs
  courent, les valeurs se peignent, les boutons répondent, la capsule annonce. Au pire l'ordre de
  la liste est en retard de 1,2 s sur celui de la capsule, qui, elle, ne bouge pas.
· **LE MOUVEMENT EST UN FLIP EN `transform` PUR** (180 ms) : on mesure avant, on réordonne le DOM,
  on repose chaque carte par une translation, la transition la ramène. L'ordre du DOM est juste dès
  la première image — un lecteur d'écran ne voit jamais l'état intermédiaire. ⚠ La translation est
  **divisée par `zoomF()`** (règle 10 : `getBoundingClientRect` rend des px VISUELS). ⚠ On ne
  réordonne que des cartes CONTIGUËS, via un marqueur : le conteneur porte aussi des rangées
  compactes et des compteurs, qu'un `appendChild` renverrait à la fin.
· ⚠ **POURQUOI C'ÉTAIT « MOCHE » DANS LE VOLET, et ce n'était pas la durée** (signalé à l'usage) :
  une carte y a un fond TRANSLUCIDE (`--sys-2`, blanc à 7 %). Pendant le croisement, deux cartes se
  superposent et **leurs deux voiles s'additionnent** — une tache plus claire traverse le volet et
  les filets se croisent. Sur la matière de TRAVAIL le fond est opaque, d'où un mouvement propre là
  et sale ici. Le temps du mouvement, la carte prend un fond OPAQUE (`--sys-hi`) et passe au-dessus.
· **LE VOLET S'OUVRE SUR LE MINUTEUR QUI SONNE** : l'ordre est calculé au RENDU, donc le volet
  ouvert ne se réordonne pas au tick — c'est le tri vivant qui s'en charge, avec son garde.

**A117. LE RETOUR D'INTERRUPTION RESTITUE LA CONSCIENCE DE SITUATION (v5.7).** Vérifié avant
d'écrire : **zéro occurrence** d'un « temps depuis le dernier geste » dans le fichier. Les cinq
écouteurs de `visibilitychange` persistaient, reprenaient l'audio, redemandaient la veille — aucun
ne disait à quelqu'un qui revient depuis combien de temps il n'était plus là. C'est pourtant le cas
nominal : on pose le téléphone, on intube, on transporte. Une ligne, en tête de la carte du bloc
courant : « ⏱ Reprise — dernier geste il y a 6:12 ».
· **L'HORODATAGE VIT DANS `persistLive`, ET NULLE PART AILLEURS** — le point d'étranglement de
  toute mutation de session (c'est déjà ce qui donne au partage un seul crochet plutôt que soixante
  verbes). Un geste ajouté demain sera horodaté sans qu'on y pense.
· **IL N'ENTRE PAS DANS L'INSTANTANÉ** : après un rechargement il n'y a plus d'interruption à
  annoncer (les minuteurs disent déjà « arrêté depuis », A81). Rien ne change au format ni à ce
  qui voyage.
· **A9** : revenir au premier plan EST un geste de l'utilisateur, la ligne a donc le droit de
  paraître ; et elle ne pousse rien d'autre qu'elle-même (elle s'insère en TÊTE de la carte, jamais
  entre deux étapes). **Deux minutes est un seuil d'AFFICHAGE**, qui évite d'annoncer une absence
  de quinze secondes. Le texte est FIGÉ à l'instant du retour : c'est la durée de l'interruption
  qu'on annonce, pas un second chronomètre.
· **ELLE S'EFFACE AU GESTE SUIVANT**, jamais après un délai — c'est le geste qui la périme.

**A117b. UN OBJET SANS BOÎTE N'EXPLIQUE RIEN — LA LIGNE DE REPRISE REFAITE (v5.7, signalé à
l'usage : « très mauvaisement implanté niveau design, collé à la bordure en haut à gauche ; le
temps ne bouge pas ; difficile de comprendre ce que c'est, d'où ça vient et comment le faire
partir ; et pourquoi l'icône ne passe pas par uiIcon ? »).** Quatre reproches, tous justes, et le
premier explique les autres : c'était un `<div>` de texte NU inséré AVANT `.ov-head`, donc hors du
rembourrage de la carte.
· **UNE RANGÉE DANS LA CARTE**, au rembourrage de l'en-tête (18 px), séparée du titre par un
  filet — la grammaire de tout ce qui vit dans une carte de bloc. Registre ATTENTION en TEXTE,
  jamais en aplat (A11) : c'est une lecture, pas une alarme.
· **LE NOMBRE VIT — A117 EST CORRIGÉE SUR CE POINT.** Il était figé « pour ne pas ajouter un
  second chronomètre » ; mais un nombre figé qui annonce « il y a 6:12 » MENT dès la minute
  suivante, et c'est la donnée périmée présentée comme vivante que ce dossier combat partout
  ailleurs. Ce qu'on annonce est « depuis combien de temps rien n'a été fait », et cela croît
  tant que rien n'est fait. Aucune hauteur ne change (A9) ; le tick le peint déjà pour les
  compteurs, donc aucune horloge nouvelle.
· **ELLE DIT D'OÙ ELLE VIENT** (« Reprise après interruption ») et **elle a une SORTIE** : un ✕ à
  44 px de cible. Elle s'effaçait au geste suivant — vrai, mais rien ne le disait, et vouloir
  s'en débarrasser n'a pas à passer par cocher une étape. Le geste reste la sortie naturelle, le
  ✕ la sortie explicite.
· **GLYPHE TRACÉ** (`uiIcon('stopwatch')`), jamais le caractère « ⏱ » — règle A106, qui n'avait
  pas été appliquée à cet ajout.

**A117c. LES ÉPINGLÉES ONT LE RYTHME DU RÉPERTOIRE (v5.7, signalé à l'usage : « les cartes
épinglées prennent toute la largeur de la page — inutile ? autant en mettre plusieurs colonnes
quand la largeur le permet »).** Leurs rangées vivaient DIRECTEMENT dans le livre, sans le
`.dir-grid` que porte chaque groupe de lettre. Mesuré à 1280 px : une rangée du répertoire fait
**320 px** (trois colonnes), une épinglée **976** — pleine largeur, pour l'accès le plus rapide du
produit, celui qu'on vise sans lire. Elles prennent la MÊME grille : mesuré identique à 390 · 1100
· 1280 · 1600 px. C'est la règle « un seul dessin de rangée » (A16) — le rythme de l'annuaire ne
doit pas changer d'une section à l'autre, sans quoi on le réapprend à chaque écran.

**A117d. LE PARCOURS INERTE, SECONDE PASSE — ET LE PLANCHER EST DIT (v5.7, signalé à l'usage :
« essaie de rétrécir en hauteur encore plus sans perte d'information : il n'y a pas assez qui
s'affiche »).** A79 avait descendu la rangée de 44 à 38 px ; elle passe à **34**, la pastille de 24
à **22**, le rembourrage de 4 à 2, et les séparations de section de 20/4 et 16/2 à 12/2 et 10/2.
**Mesuré : 416 → 368 px, −11,5 %**, sans un mot ni un corps de texte retiré.
· **LE PLANCHER EST 32 px** (cible hors crise) et il n'est pas négociable : c'est LUI qui borne
  l'exercice, pas le goût. Le dire évite qu'on cherche encore six pixels la prochaine fois.
· **CE QUI RESTE N'EST PAS DU VIDE, ET IL FAUT LE NOMMER** (A56) : les deux écarts survivants de
  36 et 41 px sont du CONTENU — une chip de branche (28 px) et un intertitre de section (19 px)
  avec la respiration que A70 lui impose. Les compresser serait retirer de l'information, ce que
  la demande exclut. Idem pour les rangées de surveillance à 48 px : leur texte passe sur deux
  lignes (A79 le disait déjà).

**A117e. BALAYAGE DES GLYPHES LITTÉRAUX — SIX SITES, ET DEUX FAMILLES À NE PAS CONFONDRE (v5.7,
prolongement d'A106).** La règle « un glyphe vient d'`uiIcon`, jamais écrit en clair » avait été
appliquée aux deux sites signalés ; le balayage en a trouvé **six autres** : les deux `⤓` des
surfaces de dépôt et quatre `↺` de BOUTONS (revenir à l'heure d'origine, rétablir un repère
annulé, « Repartir d'ici », « ↺ Refaire »).
· **CE QUI RESTE LITTÉRAL, ET C'EST DÉLIBÉRÉ** (A56 : nommer ses non-défauts) : les `↺` du
  VOCABULAIRE des renvois du plan (`↺2`, « ↺ reprendre à 3 », `optAbbr`) — c'est du TEXTE abrégé,
  pas une icône, et le remplacer par un tracé casserait une chaîne mono ; les `⚡︎`/`⏱︎` du dock,
  que A13 range explicitement parmi les glyphes de commande porteurs du sélecteur U+FE0E ; et le
  `×` de fermeture, convention de la maison sans tracé.
· **⚠ LA COQUE STATIQUE NE PEUT PAS APPELER `uiIcon`** : y écrire `${…}` produit un texte brut (et
  ici une ERREUR DE SYNTAXE, la substitution étant tombée dans une chaîne à guillemets simples —
  attrapée par `check-syntax`, pas par la relecture). Le porteur y reste VIDE et le peintre le
  remplit une fois : recopier le SVG en aurait fait un second dessin à tenir.
· **⚠ ET UN TÉMOIN MESURAIT LE CARACTÈRE** : « le × est devenu un retour (↺) » exigeait le glyphe
  écrit en clair, donc il rougissait sur l'application d'A106. Ce que la règle promet est qu'après
  une annulation le bouton propose de RÉTABLIR — c'est le nom accessible qui le dit, et c'est ce
  qu'il mesure désormais.

**A117f. EN SESSION, MÊME DESSIN — MAIS LE PAS RESTE 44 px, ET C'EST DE L'ARITHMÉTIQUE (v5.7,
signalé à l'usage : « en mode session, le parcours inerte est resté à la taille antérieure :
compresse et harmonise »).** Le resserrement d'A117d était borné à `:not(.crisis-live)`. Tout ce
qui est GRAPHIQUE s'aligne désormais sur l'avant-session — pastille 22, rembourrage 2/10, écart
interne 8, étiquette de branche 28, marges hautes de section. **Mesuré : 435 → 411 px.**
· **CE QUI NE PEUT PAS CÉDER EST LE PAS.** Ces rangées sont TAPABLES : la règle 9 impose 44 px en
  crise, et deux cibles voisines ne sont disjointes que si le pas vaut au moins 44. Le DESSIN
  descend donc à 38 px et la cible vient du HALO (A8), 3 px de chaque côté sur la gouttière de
  6 px que la crise portait déjà — les halos se touchent sans se mordre (A66). Pas = 38 + 6 = 44,
  exactement. **L'écart résiduel avec l'avant-session (411 contre 370) EST ce pas** : six rangées
  à 44 au lieu de 38. Le dire évite qu'on cherche encore à les rapetisser — `audit-a11y` rougit
  aussitôt (« cible trop petite », vérifié).
· **⚠ LE PAS SE PREND SUR LA RANGÉE, JAMAIS SUR L'ÉCART.** J'avais commencé par porter la
  gouttière à 6 px — où elle était déjà — et par réduire la marge BASSE des titres. Un témoin a
  rougi aussitôt : « chaque titre a le même écart avec ses rangées », **[10, 8] mesurés**, parce
  qu'en session un des deux titres échappe au sélecteur `.rail-lad`. La marge basse appartient au
  rythme des sections ; la respiration se prend au-DESSUS, où elle n'engage personne. La règle
  d'avant-session a reçu la même discipline, qui portait le même risque latent.

**A118. CE QUE LA FICHE EMBARQUE SE DIT AVANT QU'ON ENTRE (v5.7).** Mesuré : `preStartHtml` (« Ce
qui démarrera ») ne se rend que dans le RAIL, donc à partir de 780 px ; en voie ÉTROITE le panneau
n'existe que dans le volet du quai, qui exige une session vive (v5.4.2), et la capsule n'existe pas
non plus avant le premier geste. **Sur la cible principale déclarée**, un minuteur à cycles de 2 min
écrit par l'auteur était donc invisible tant qu'on n'avait pas démarré — et le néophyte
chronométrait de tête, ce que l'aide existait pour éviter. Une LIGNE dérivée (`carryLineHtml`,
pure) : « 6 blocs · 2 minuteurs · 1 complication déclarée ».
· **PAS UNE SECONDE COPIE DU DÉTAIL** : le rail garde sa liste, l'étroit reçoit le compte.
· **RIEN À DIRE → AUCUNE LIGNE** : un panneau qui affirmerait « 0 minuteur » serait le bruit que ce
  dossier refuse partout. Aucun champ nouveau, aucune migration.

**A119. UNE AIDE RÉVISÉE DEPUIS VOTRE DERNIER PASSAGE LE DIT (v5.7).** `aidRev` existe depuis le lot
T1 et ne servait qu'au compte rendu. Or dans une bibliothèque PARTAGÉE, un collègue révise une aide
qu'on croit connaître par cœur, et l'on déroule de mémoire. `revisedSinceTxt(f,sessions)` est PURE.
· **AVANT le geste d'entrée, jamais pendant le soin** (la rangée de méta est déjà masquée en
  session depuis la v4.31.0). **Elle ne conditionne rien** : « Confirmé — démarrer » ne bouge pas.
· **ELLE NE DIT PAS CE QUI A CHANGÉ** — le dire exigerait de rendre un diff clinique à l'écran,
  donc de résumer une modification de dose. « Versions » est dans le menu ⋯ pour cela.
· **RIEN SUR UNE AIDE JAMAIS DÉROULÉE** : il n'y a alors pas de « dernier passage », et « révisée »
  serait du bruit. C'est le DERNIER passage qui compte, pas le premier trouvé.

**A120. LE COMPTE RENDU DONNE L'ÉCART, ET RIEN D'AUTRE (v5.7, décision de l'auteur : « juste
l'écart sans analyse »).** Au débriefing la question est presque toujours « combien de temps entre
les deux ? », et on la soustrayait à la main. `evDeltas` (pure) ajoute une colonne « Écart ».
· ⚠ **LA LIGNE À NE PAS FRANCHIR EST PROCHE, ET C'EST POUR ÇA QUE LA COLONNE EST NUE** : un écart
  BRUT est un fait. Une MOYENNE, un « intervalle cible », une couleur qui vire au rouge au-delà
  d'une valeur, ou le mot « conformité » feraient basculer le document du côté de l'ÉVALUATION PAR
  LE LOGICIEL — ce que le § 2 nomme comme le vocabulaire à ne jamais employer.
· **L'ÉCART EST PAR OBJET** : « 3:56 » n'a de sens qu'entre deux doses du MÊME produit ; un repère
  libre n'ouvre pas de série. **Un repère ANNULÉ ne compte pas et ne coupe pas la série** : il
  reste dans la chronologie (une décision a bien eu lieu), l'écart se mesure entre les gestes qui
  TIENNENT.

**A121. DEUX PROPOSITIONS RETIRÉES APRÈS VÉRIFICATION — ET C'EST LA MÊME LEÇON (v5.7).**
· **« Télécharger les documents des aides épinglées »** : `Sync._syncAttachments()` étape 4 le fait
  DÉJÀ, et son commentaire le dit — « télécharge en ARRIÈRE-PLAN tout document référencé manquant
  (hors-ligne d'urgence : systématique) ». La proposition aurait RESTREINT aux épinglées une
  garantie volontairement universelle : une régression. J'avais vérifié la présence des SURFACES
  (la ligne d'A82, son bouton) sans vérifier le MÉCANISME derrière — le bouton n'est pas le chemin
  nominal, c'est le filet.
· **« Fondre le virage au vert de Continuer »** : `ovAfterCheck` fait déjà tout le changement
  d'état (`classList.toggle('okay',all)`, libellé remplacé, `aria-disabled` retiré). Il ne restait
  que 140 ms de fondu — et le LIBELLÉ bascule au même instant : on obtiendrait une couleur qui
  s'attarde sous des mots qui ont déjà sauté, **moins** cohérent que l'instantané.
· **LA LEÇON EST A97, MOT POUR MOT** : « une proposition juste peut porter sur un manque qui
  n'existe plus : on vérifie avant d'implémenter ». Les deux constats sont venus de l'auteur, pas
  de moi. **QUESTION OUVERTE, laissée telle** : le téléchargement de fond est NON BORNÉ (ni volume,
  ni égard pour une connexion mesurée) — le borner affaiblirait la garantie hors-ligne, c'est un
  arbitrage à prendre, pas un défaut à corriger.

**A122. LA RELECTURE DEVIENT FORCE DE PROPOSITION (v5.7, Q1).** Vérifié avant d'écrire : les six
détections de `reviewNotes`/`reviewNotesProto` sont TOUTES des manques — titre absent, « à
compléter » résiduel, aucune source, chapeau trop long, bloc de plus de sept étapes, challenge trop
long. Aucune ne disait jamais « votre texte décrit un cycle : voulez-vous le minuteur qui va
avec ? » Or c'est là que tout se joue pour un néophyte-AUTEUR : il écrit « renouveler toutes les
3 min » EN TEXTE, et n'apprendra jamais que l'application sait armer un minuteur à cycles, poser un
compteur ou marquer un memory item. La fiche qu'il publie n'emploie alors qu'une part du produit —
et c'est EN CRISE que la différence se paie. `reviewOffers(f)` est PURE ; le volet gagne un SECOND
registre, séparé des manques par un filet et son intertitre (un défaut et une occasion ne se lisent
pas de la même façon, et les mêler ferait passer l'occasion pour un reproche).
· **TROIS DÉTECTEURS, ET LE NOMBRE VIENT DE LA PHRASE DE L'AUTEUR, JAMAIS D'UN BARÈME** : une
  cadence (« toutes les 3 min », « à 5 min », « q4h ») → minuteur à cycles, période PRÉ-REMPLIE ;
  « renouveler / seconde dose / nouveau choc » → compteur ; une étape vitale alors qu'aucune ★
  n'existe → memory item. C'est de la lecture de TEXTE, à froid, dans l'éditeur — hors session,
  hors patient. Aucun seuil clinique n'est inventé : c'est l'interdit que le prompt IA porte déjà.
· **RIEN N'EST CRÉÉ AUTOMATIQUEMENT**, jamais : une proposition est une rangée avec un bouton, et
  le texte de l'auteur n'est PAS réécrit — l'objet s'ajoute, la phrase reste.
· **LA PROPOSITION N'INVENTE PAS DE NOM** (A85, A99) : le compteur naît SANS libellé, et c'est le ✎
  de sa carte qui le nomme. Deviner un mot serait la dégénérescence de « PA 2 » sous un autre visage.
· **UN SEUL CHEMIN DE CRÉATION** : accepter passe par `edAdd`, qui gagne un paramètre `pre`
  facultatif. Un second créateur divergerait au premier réglage. Seul ★ n'y passe pas — il ne CRÉE
  rien, il marque un item qui existe.
· **ELLES SE TAISENT DÈS QUE L'OBJET EXISTE** (aucun drapeau à tenir) et **un refus ne revient pas
  de la séance** (`state.edOffNo`, transitoire comme `state.edGrab` : c'est un geste, pas un état
  du brouillon — le graver dans le modèle ajouterait un champ pour mémoriser un NON).
· **LE VOLET EXISTE MÊME SANS DÉFAUT** : une fiche sans remarque est précisément celle à qui il
  reste le plus à apprendre.
· ⚠ **DEUX DÉFAUTS TROUVÉS PAR LES TÉMOINS, ET LE PREMIER EST UN PIÈGE DE REGEX GÉNÉRAL** :
  `\b` devant un caractère ACCENTUÉ ne matche JAMAIS — en JS, `à` n'est pas un caractère de mot,
  donc `\bà` est mort-né et « Renouveler à 5 min » passait au travers. Et le registre d'une étape
  vit dans la CHAÎNE (préfixe « ⚠ ») autant que dans `level` : `migrate` ne dérive pas le niveau du
  préfixe, `stepIsCrit` est LA source de vérité — un détecteur qui ne lit que `level` est aveugle
  au format historique. Corollaire de fixture : un témoin qui poserait ★ en filtrant sur
  `level===3` ne poserait rien et mesurerait le vide.
· **CE QUI N'EST PAS FAIT, ET POURQUOI** : trois autres détecteurs étaient proposés (« si échec »
  → bloc de décision, « en cas de … » → complication, une dose écrite sans repère posologique).
  Les deux premiers exigent de DÉCOUPER des étapes existantes, c'est-à-dire de réécrire le texte de
  l'auteur — exactement ce que la règle ci-dessus interdit. À rouvrir séparément, avec un dessin
  qui ne touche pas à ses phrases.

**A123. LES TÉMOINS DYNAMIQUES DE P1 ET Q2 — ET LES DEUX QUI N'ONT PAS DE CAS À RENCONTRER
(v5.7).** Les fonctions pures du lot ont 47 témoins ; le CÂBLAGE, lui, n'était mesuré par rien.
Deux sections entrent dans `audit-doctrine` (`P1 · le retour au bloc courant`, `Q2 · la reprise
après interruption`), vérifiées CAPABLES D'ÉCHOUER — défauts réintroduits → 7 rouges, fichier
restauré à l'octet.
· **LE PRÉDICAT DU TÉMOIN EST CELUI DE L'APPLICATION, PAS UN AUTRE** (A109/4, rejouée ici) : ma
  première version lisait « hors de vue » en `r.bottom<0||r.top>innerHeight` alors que la barre se
  règle sur la ZONE UTILE — sous les couches collantes, au-dessus du dock. Le témoin rougissait sur
  un comportement juste, la carte étant bien hors de la zone utile mais dépassant encore derrière
  le chrome. Deux définitions concurrentes d'un même régime : la divergence que ce dépôt a déjà
  payée cinq fois.
· **UN TÉMOIN NE DOIT JAMAIS POUVOIR PENDRE** (A89) : `page.click('.bkr')` attend 30 s quand la
  barre n'est pas là — c'est-à-dire précisément quand le défaut couvert est présent — et ce blocage
  emporte la tranche entière, sans un mot. On prend la poignée (`page.$`), on la teste, et
  l'absence devient un rouge lisible.
· **CE QUE Q2 MESURE EN PROPRE** : la ligne ne paraît PAS sous le seuil d'affichage, elle paraît
  au-delà, elle dit « il y a m:ss », elle ne déplace pas la page, elle ne s'efface PAS toute seule
  avec le temps, et elle s'efface AU GESTE. C'est le geste qui la périme, jamais une horloge.
· **LES DEUX TROUS SONT FERMÉS DEPUIS (v5.7), ET LE CHEMIN EST LA LEÇON** : on a d'abord réparé
  le DÉCOR, ensuite écrit le témoin. `P4b · le tri vivant des minuteurs` mesure l'ordre par temps
  restant, le marquage d'imminence sur la CARTE (glyphe + mot, jamais la couleur seule), le garde
  du doigt posé et le délai de grâce qui le suit ; `Q1 · les propositions de relecture` mesure que
  la rangée paraît, que son tap crée l'objet AVEC la période lue dans la phrase, qu'elle se tait
  ensuite, et qu'un refus ne revient pas de la séance sans rien créer. Vérifiés capables d'échouer
  (tri neutralisé et `pre` ignoré → 2 rouges, fichier restauré à l'octet).
· ⚠ **CE QUI A DÛ ÊTRE FAIT AVANT, ET QUI EST LA VRAIE LEÇON DE CE LOT.**
  **P4b (le réordonnancement vivant)** : il ne s'observe qu'à partir de DEUX minuteurs déclarés
  dans la même liste, or aucune fiche d'exemple n'en déclare deux — et un minuteur ad hoc se rend
  en rangée compacte (`minis`), jamais en `.tmcard`. Le cas n'existe donc pas dans le décor.
  **LE CORRECTIF ÉTAIT DANS LE DÉCOR, PAS DANS LE TÉMOIN** : la fiche ACR porte désormais un
  SECOND minuteur déclaré (« Adrénaline (cycle) », 4 min) — ce que le lot T13 recommandait déjà
  (« les deux fiches d'exemple exercent la doctrine qu'elles enseignent »), et le second est
  clinique, pas décoratif : deux cadences (2 min / 4 min) sont précisément le cas où l'ordre par
  temps restant change sous l'œil. Écrire la section AVANT aurait produit un vert qui ne mesure
  rien.
  **Un trou NOMMÉ vaut mieux qu'un vert obtenu sur un cas qui n'existe pas** — c'est la leçon que
  ce fichier redit le plus souvent.

**A124. ROUVRIR L'APP PENDANT UN SOIN, C'EST VOULOIR LE SOIN (v5.7, volet 3 / F5).** Rouvrir
l'application pendant une session vive déposait sur l'accueil, où une carte propose de reprendre :
un tap de plus dans le seul moment où l'on n'en a aucun à donner. On atterrit désormais DANS le
soin.
· **CE QUE ÇA ROMPT** : « on s'oriente avant d'agir » — mais cette règle vaut pour une session
  qu'on COMMENCE (c'est la condition d'entrée QRH) ; ici elle est déjà en cours, et l'orientation
  a eu lieu.
· **LES TROIS BORNES** : une SEULE session vive (à deux, on ne choisit pas à la place de
  l'utilisateur) ; **dix minutes** sans le moindre geste au plus (au-delà, l'accueil reprend son
  office et sa carte) ; et jamais quand un fragment d'URL est présent — l'invité a son propre
  écran d'entrée, décidé avant le chargement.
· **LE RETOUR EST À SA PLACE CONSTANTE** : le « ‹ » d'en-tête ramène à la bibliothèque, donc
  personne n'est piégé — c'est ce qui distingue un atterrissage d'un enfermement (A15).

**A125. LE PLAN DE VOL : REFUSÉ SUR LE CHROME DE CRISE, RETENU DANS LE MONITEUR (v5.7, volet 3 /
F2).** La proposition la plus séduisante du volet exploratoire a été RETIRÉE de l'écran de soin
après mesure, et c'est la trajectoire qu'il faut retenir autant que le résultat : trois questions
de l'auteur ont suffi à la retourner.
· **CE QUI L'A FAIT TOMBER SUR LE TÉLÉPHONE** — ses quatre bénéfices, éprouvés contre le contenu
  RÉEL des fiches : la COLLISION est théorique (cadences 2/4 min que l'équipe enchaîne de toute
  façon) ; l'angle mort du minuteur en PAUSE est un défaut de la CAPSULE (`run` filtre sur
  `running || (échu && !ack)`), réparable pour zéro pixel ; le JALON hors de son bloc appartient au
  volet ; et le PASSÉ est déjà porté par le journal et par « il y a » (A115). Ne restait que la
  simultanéité — cas rare et à faible enjeu — pour ~52 px permanents dans une colonne dont le
  budget de chrome est tenu à 30 % par `audit-budget`.
· **CE QUI LA FAIT GAGNER DANS LE MONITEUR** : l'écran entier est un afficheur, les pixels sont
  gratuits, on regarde à deux mètres, et une bande de temps y est la bonne forme. C'est un objet de
  MONITEUR, pas un objet de chrome — et cela donne au mode moniteur (v4.60.0, que personne ne
  trouve) un contenu qui vaut le détour.
· **TROIS REGISTRES DE TRAIT, ET ILS PORTENT TOUT LE SENS** : point derrière la ligne de vie =
  c'est ARRIVÉ ; trait plein devant = c'est DATÉ (un minuteur qui TOURNE, échéance calculable au
  milliseconde près) ; tiret = c'est PROJETÉ, si rien n'est touché. On ne peut pas confondre un
  fait avec une promesse : c'est la seule chose que cette bande doive garantir.
· **CE QUI N'A PAS D'HEURE N'A PAS DE POSITION** : minuteur en pause (un reste, pas une date),
  échu non acquitté (déjà passé), chronomètre (ne finit jamais) — rangée « sans heure », sous
  l'axe. Et **un jalon compté n'y entre JAMAIS**, même quand un minuteur cadence les passages :
  dater le 3ᵉ choc reviendrait à prédire le rythme auquel L'ÉQUIPE va agir.
· **AU MOINS DEUX OBJETS, SINON RIEN** : avec un seul, le grand chiffre au-dessus dit déjà tout et
  l'axe est une redite. C'est l'objection qui l'a chassée du chrome ; elle vaut ici aussi.
· ⚠ **AUCUN 11 px, ET LE CLIQUET DE `check-type` A EU RAISON DE LE REFUSER** : le plancher
  typographique est une exception motivée pour ce qu'on lit à trente centimètres. Sur un afficheur
  qu'on lit à deux mètres, il n'a aucun sens — tout part du cran au-dessus.
· **CE QUI RESTE À FAIRE, ET C'EST DIT** : la progression d'un jalon dans la rangée « sans heure »
  n'est pas portée (elle demande le bloc courant) ; et les deux correctifs à zéro pixel que cette
  piste a RÉVÉLÉS — le minuteur en pause dans le rappel du quai, le jalon dans le volet — ne sont
  pas faits non plus. Ils valent mieux que la bande sur le téléphone : c'est le sens du refus.

**A126. LE PASSAGE QU'ON INTERROMPT SE REPLIE — ET LE TÉMOIN A TRANCHÉ AVANT LE CODE (v5.7,
signalé à l'usage : « on tape une complication, on appuie sur reprendre, on avance d'un bloc et le
précédent s'affiche en haut comme un doublon »).**
· **DEUX LECTURES OPPOSÉES, ET ELLES APPELAIENT DES CORRECTIONS CONTRAIRES** : soit `cxResume`
  redéposait sur le bloc SUIVANT (défaut net, à réparer), soit le second passage était VOULU et
  seule sa présentation était fautive. Corriger sans trancher aurait risqué d'effacer une trace de
  soin pour un symptôme mal lu — la faute qu'A100, A107 et A113b ont déjà documentée. Un témoin a
  donc été écrit AVANT toute correction : il mesure quel bloc est au bout du journal après reprise.
· **VERDICT : la navigation était JUSTE.** `cxResume` redépose bien sur le bloc interrompu, et le
  second passage est la doctrine d'interruption (AC 120-71B, v4.26.0 — on re-vérifie après une
  interruption, l'ancienne carte reste lisible).
· **CE QUI ÉTAIT FAUTIF EST LA PRÉSENTATION** : le passage quitté est INCOMPLET, donc `ovPresList`
  le garde en CARTE OUVERTE (« un passage incomplet n'est jamais une chip » — l'invariant qui fait
  la conformité du journal). On se retrouvait avec DEUX cartes ouvertes du même bloc, l'une
  au-dessus de l'autre, portant les mêmes étapes.
· **L'INVARIANT N'EST PAS TOUCHÉ** : on ne transforme pas le passage en chip, on pose le REPLI
  MANUEL, que la doctrine autorise déjà (« repli manuel = ligne d'état au maximum ») et qui
  persiste. Rien n'est perdu — les mêmes étapes sont dans la carte neuve juste en dessous, et un
  tap rouvre l'ancienne.
· **TÉMOIN** : entrer sur complication, reprendre, et vérifier (a) que le bout est le bloc
  INTERROMPU, (b) qu'il y a bien DEUX cartes de ce bloc, (c) qu'une SEULE reste ouverte. Vérifié
  capable d'échouer (repli neutralisé → 1 rouge, fichier restauré à l'octet).

**A127. LE VOLET PROLONGE LA CAPSULE — ENCORE FAUT-IL SAVOIR OÙ ELLE EST (v5.7, signalé à l'usage,
captures à l'appui : « en mode exercice le volet s'affiche mal »).** MESURÉ : en exercice, le volet
recouvrait le quai de **63 px** — la capsule disparaissait entièrement sous lui (z 16 contre 15).
· **LA CAUSE** : `--stick-top` est une SOMME DE HAUTEURS (en-tête + quai), donc elle suppose le
  quai collé DIRECTEMENT sous l'en-tête. C'est vrai en crise ordinaire, où le bandeau-titre
  n'existe plus depuis la v5.0.0 ; c'est FAUX en exercice et chez l'INVITÉ, où le bandeau SURVIT
  pour porter le placard et vit dans le FLUX : il pousse le quai vers le bas, et le volet — posé
  sur la somme — venait se dessiner par-dessus.
· **LE REMÈDE EST BORNÉ AU VOLET** (`--quai-b`, bas RÉEL du quai, ÷ `zoomF()`) : `--stick-top`
  reste une somme de hauteurs pour tout le reste — le rail, l'ancrage, le `scroll-padding` —, donc
  **la leçon v5.0.9 tient toujours là où elle protège** (« une géométrie de chrome ne se dérive
  jamais d'une position de défilement », le tremblement du rebond iOS). Le volet, lui, est une
  surface TRANSITOIRE qu'on ouvre d'un tap : suivre la capsule où qu'elle soit est exactement ce
  qu'on lui demande.
· **TÉMOIN** : il compare les DEUX modes plutôt que d'affirmer une valeur — le recouvrement doit
  être le même en crise et en exercice. Vérifié capable d'échouer (63 px contre 8 avant correction),
  et il exige d'abord que l'exercice montre son bandeau, sinon le cas n'existe pas.

**A128. LA PROGRESSION D'UN JALON SORT DE SON BLOC (v5.7, second correctif à zéro pixel révélé par
le refus de F2).** Un jalon ne s'affichait que sur la carte du bloc qui le déclare (`jalonsHtml`) :
dès qu'on est ailleurs — une complication, un bloc plus loin, la feuille « Tout voir » —
« Chocs 2/3 » disparaissait, alors que le COMPTE, lui, continuait d'avancer. Il rejoint le volet,
là où l'état vit déjà, en quatrième famille après minuteurs, compteurs et journal.
· **UNE LIGNE, JAMAIS UNE CARTE** : ce n'est pas un objet qu'on manipule, c'est un compte qu'on lit
  (A16 — ce qui se LIT prend une ligne, ce qui se COMPTE prend une carte).
· **LE MÊME CALCUL QUE LA CARTE** (`jalonProg`, `jalonCondLbl`) : deux progressions écrites
  séparément finiraient par diverger, et ce fichier a payé cette leçon cinq fois.
· **RIEN À DIRE → AUCUNE SECTION** : une fiche sans jalon n'en voit pas la trace.
· **LE SEUIL FRANCHI SE MARQUE** en ambre comme sur la carte — jamais un aplat (A11), et le glyphe
  △ accompagne l'encre (règle 8). Sur la matière SYSTÈME du volet, le registre prend sa valeur
  propre (`--warn-sys`).
· **AUCUN GESTE N'Y EST POSÉ** : le renvoi ⚡ du jalon reste sur la carte du bloc, où l'action vit
  au pied de l'alerte (ECAM). Le volet en donne la LECTURE, pas la commande — sinon le même verbe
  aurait deux adresses (§ 5.5).

**A129. LE GRAIN DE L'IMPORT EST L'ENTITÉ — L'ATELIER (v5.7, plan A/F7).** Un fichier entrait EN
BLOC : on répondait à trois questions (destination, fusion, doublons) sans avoir jamais vu ce
qu'il contenait. Sur un export de bibliothèque, c'est dix-huit aides qu'on accepte sur la foi d'un
nom de fichier — et le seul recours après coup est de les supprimer une par une. L'atelier
renverse l'ordre : d'abord **CE QUE** l'on importe, ensuite **OÙ**. Une rangée par entité (type,
titre, état, ce qu'il reste à relire), tout coché au départ — l'atelier sert à RETIRER, il ne
demande pas de tout re-cocher.
· **CE N'EST PAS UN ÉCRAN DE PLUS SUR UN CHEMIN DE CRISE** : l'import est un geste d'AUTEUR, à
  froid, et c'est le SEUL moment où le contenu d'un fichier est encore inspectable. La règle 11
  vise ce qui s'impose pendant un soin ; ici rien ne surgit — on a demandé à importer.
· **LE FILTRAGE PRÉCÈDE TOUTE ÉCRITURE, ET C'EST LE POINT DUR** : les deux listes sont réduites à
  la sélection AVANT les questions, donc avant `migrate`, `persist` et surtout `importAtts`. Un
  binaire du .zip n'entre JAMAIS pour une entité décochée — non pas par un filtre posé après coup,
  mais parce que **la liste filtrée est la seule qui existe** ensuite. Le témoin le mesure sur un
  vrai .zip : `IDB.getAtt` répond pour la cochée, pas pour l'autre.
· **LA RANGÉE EST L'OBJET QUI SERA ÉCRIT** : on migre dans l'atelier, une fois, et l'on repose
  l'objet migré dans le lot. `migrate` étant idempotent (il tourne à chaque chargement), la boucle
  d'import le rejoue sans conséquence : la règle 5 tient — le point d'assainissement reste unique,
  il est seulement atteint plus tôt. Une prévisualisation calculée à côté serait une seconde
  vérité, donc une divergence en attente.
· **LA PASTILLE « △ n » EST LE MÊME CALCUL QUE LE VOLET DE L'ÉDITEUR** (`reviewNotes` /
  `reviewNotesProto`) : deux comptes écrits séparément divergeraient, et l'auteur apprendrait deux
  fois le même signe (§ 5.5). Registre ATTENTION, **jamais un aplat rouge** : elle ne conditionne
  rien — on importe ce qu'on veut, et une remarque de relecture n'est pas un refus (A11).
· **L'ÉTAT ENTRANT EST PRÉSERVÉ, ET `importForceDraft` EST PURGÉ** (règle 14). Les TROIS portes
  forçaient « Brouillon » — c'était un proxy de « vous n'avez pas encore relu ceci ». L'atelier
  montre désormais cet état AVANT l'écriture, rangée par rangée, avec ce qu'il reste à relire :
  forcer en plus, c'était mentir sur la donnée. Et le coût était réel — **restaurer une sauvegarde
  ramenait dix-huit aides validées en brouillon**, donc hors de l'accès de crise (un brouillon ne
  s'épingle pas, et il est masqué aux lecteurs d'une bibliothèque partagée).
  ⚠ **L'OBJECTION EST NOMMÉE** : un fichier peut déclarer « Validée » sans avoir été relu. Ce qui
  la tient n'est pas le forçage mais (a) la rangée, qui DIT l'état avant d'écrire, et (b) le
  prompt IA, qui impose `"status":"draft"` et dont `audit-prompt` vérifie le contrat — le cas
  « contenu généré » arrive donc en brouillon par sa source, pas par une réécriture chez nous.
· **UN FICHIER QUI NE PORTE QUE DES RÉFÉRENCES PASSE ENFIN** : il franchissait la garde de
  structure puis tombait sur `imp.fiches.length` — « Import interrompu », pour un fichier
  parfaitement valide. Les deux tableaux sont normalisés à l'entrée de l'atelier ; et les
  questions qui suivent comptent la SÉLECTION, jamais le fichier (annoncer dix-huit fiches pour
  deux cochées mesurerait le fichier, pas ce qu'on est en train de faire).
· **UN CONTENU VIDE SE DIT** : un export sans aide ni référence produisait « 0 fiche importée » —
  une phrase qui ne désigne pas sa cause. Il est annoncé avant d'ouvrir quoi que ce soit.
· **GABARIT ATELIER (720), RANGÉES ET NON CARTES** (A25, A16) : c'est une liste qu'on parcourt,
  pas un choix borné ; la CIBLE est la rangée entière (`<label>`), jamais la case de 24 px.
  « Tout cocher / Tout décocher » écrit sur les cases EN PLACE — un re-rendu ferait perdre le
  focus et remonterait le défilement (leçon v4.78.0).
· **TÉMOINS** : section `A129 · l'atelier d'import` dans `audit-doctrine` (fichier .zip fabriqué
  par `zipBuild`, entré par `readImportFile` — l'entonnoir RÉEL des trois portes), vérifiée
  CAPABLE D'ÉCHOUER (filtrage neutralisé + forçage réintroduit → 3 rouges, fichiers restaurés à
  l'octet) ; plus une surface `atelier d'import` dans `audit-a11y`, qui construit son cas avec les
  deux natures ET une pastille — sans elles, la moitié des objets de la rangée ne serait pas
  mesurée. ⚠ Le contrôle « rien n'est écrit tant qu'on n'a pas validé » est un GARDE d'ordre : il
  ne peut rougir que si une écriture précédait l'ouverture ; celui qui discrimine est le filtrage.

**A130. LE FILTRE ATTEINT TOUT CE QUI S'ÉCRIT, ET LA RANGÉE DIT DE QUOI DÉCIDER (v5.8.0, reste du
plan A/F7).** A129 avait posé le grain — l'entité — sans le tenir jusqu'au bout : trois choses
raisonnaient encore en BLOC derrière l'atelier.
· **LES CATÉGORIES SUIVENT LA SÉLECTION.** Elles entraient TOUTES, y compris celles que seules les
  entités décochées employaient : on repartait avec des catégories vides dans son rail, créées par
  un import qu'on venait justement de restreindre. *Le filtrage doit atteindre tout ce qui
  s'écrit, pas seulement les entités* — c'est la formulation générale de la règle, et elle vaut
  pour ce qu'on ajoutera demain au format (jeux de tags, réglages).
· **LA QUESTION DESTRUCTIVE ANNONCE LA SÉLECTION, PAS LE FICHIER** (« remplacé(e)s par les n
  éléments cochés »). Depuis l'atelier les deux ne sont plus la même chose, et c'est la SEULE
  question destructive du parcours : y annoncer le fichier ferait croire qu'on récupère ce qu'on
  vient d'écarter.
· **« ⟳ DÉJÀ PRÉSENT » SE DIT AVANT LA QUESTION « DOUBLONS ».** La rangée porte le fait ; le sort
  reste décidé par la question groupée. ⚠ Elle n'apparaît QUE là où la collision peut avoir lieu —
  ids conservés, donc **même espace** (`sameSpace`, remonté AVANT l'atelier pour cela) : sur un
  fichier venu d'ailleurs les ids sont régénérés à l'écriture, et annoncer un doublon que
  l'écriture ne verra pas serait un mensonge. Le prédicat est le MÊME que celui de la boucle
  d'import — un second, écrit à côté, divergerait.
· ⚠ **UN CONTRÔLE PAR RANGÉE A ÉTÉ ÉCARTÉ, ET C'EST UNE DÉCISION** : la sélection porte déjà le
  grain (décocher = ne pas importer), tandis que « remplacer ou garder les deux » est une
  STRATÉGIE, globale par nature — la poser dix-huit fois ferait payer à chaque rangée un choix que
  personne ne fait entité par entité. À rouvrir si l'usage montre le cas mixte ; il n'a pas été
  constaté.
· **CE QUE LA RANGÉE EMBARQUE, DANS LES MOTS DE L'ÉCRAN D'ENTRÉE** (`carryParts`, PURE, 4 témoins) :
  « 2 blocs · 1 minuteur · 1 complication déclarée ». C'est la seule chose qui distingue un
  algorithme complet d'une ébauche sans ouvrir le fichier. **Une phrase, deux lecteurs** — A118 et
  l'atelier —, donc un seul calcul : recopié, il aurait fini par compter autre chose ici que là
  (§ 5.5). ⚠ Le SEUIL, lui, diffère et chacun est motivé : avant le soin, une fiche sans minuteur
  ni compteur ni complication n'a rien à annoncer (A118 : « rien à dire → aucune ligne ») ; dans
  l'atelier, le compte des BLOCS est précisément l'information qu'on cherche. Ce n'est pas une
  divergence — c'est deux questions différentes servies par le même compte.
· **TÉMOINS** : deux sections d'`audit-doctrine` — `A130 · doublons annoncés, catégories filtrées`
  (décor propre : fichier de MÊME espace, un id déjà présent, deux catégories dont une n'appartient
  qu'à l'entité décochée) et `A130 · « remplacer » annonce la sélection` (qui lit le texte de la
  question destructive et en SORT par « Annuler » — on ne vide pas une bibliothèque pour vérifier
  une phrase). Vérifiées CAPABLES D'ÉCHOUER : quatre défauts réintroduits → **5 rouges**, fichiers
  restaurés à l'octet.

**A131. « DÉJÀ PRÉSENT » NE SUFFIT PAS À DÉCIDER — LEQUEL DES DEUX EST LE PLUS RÉCENT ? (v5.9.0,
suite d'A130).** La rangée annonçait la COLLISION sans dire ce que la question SUIVANTE demande
pourtant de trancher — « remplacer » ou « garder les deux ». Or remplacer, quand le fichier est
plus ANCIEN que ma version, écrase une révision locale par une copie périmée : **en silence**, et
c'est précisément le genre de geste que l'atelier existe pour rendre visible. La rangée dit donc la
RELATION en toutes lettres (« le fichier est plus récent » · « votre version est plus récente » ·
« même version »).
· **ON N'INVENTE PAS DE NUMÉRO DE RÉVISION** : `updatedAt` EST la révision — c'est déjà ce dont
  `aidRev` se sert pour dire sur quelle version un soin a été conduit (v5.0.0). Aucun champ
  nouveau, aucune migration, rien de plus à synchroniser.
· ⚠ **ET ON LIT L'HORODATAGE AVANT `migrate`.** C'est le piège du lot, et il est INVISIBLE au
  témoin de la section A130 : `migrate` POSE un `updatedAt` quand il manque, avec `Date.now()` en
  dernier recours. Un fichier ancien qui n'en portait pas se retrouverait donc daté de **l'instant
  de l'import**, donc annoncé « plus récent » que tout ce qu'on possède — un mensonge, sur la seule
  question destructive du parcours. Le prédicat travaille sur l'objet BRUT ; sans horodatage des
  DEUX côtés, la rangée **se tait** (A83 : elle ne dit que ce qu'elle sait). Mesuré à la
  réintroduction du défaut : « le fichier est plus récent » sur un fichier sans aucune date.
· **AUCUNE TOLÉRANCE, AUCUN SEUIL** : un objet exporté puis réimporté sans avoir été touché porte
  le MÊME horodatage à la milliseconde. « À une minute près » serait un seuil inventé.
· **LE SEUL CAS AMBRE EST CELUI OÙ L'ON PERD DU TRAVAIL** — « votre version est plus récente »,
  registre ATTENTION en TEXTE avec son glyphe △, jamais un aplat (A11) et jamais la couleur seule
  (règle 8). Les deux autres sont des faits neutres et prennent l'encre de la rangée.
· **ELLE NE CONDITIONNE RIEN, ET LE SORT RESTE GLOBAL** : la stratégie est décidée par la question
  « Doublons », où le contrôle par rangée a été écarté et motivé (A130). La rangée informe.
· **ON NE DIT PAS LA DATE, seulement la relation** : la décision ne demande que « lequel gagne » ;
  une date de plus serait un second nombre à lire sur une rangée déjà dense, pour rien.
· **TÉMOINS** : les trois contrôles de relation rejoignent la section A130, dont le décor porte
  déjà la collision (le fichier y est volontairement daté de `1`) ; le PIÈGE a **sa** section,
  `A131 · sans horodatage, la rangée se tait`, et sa manœuvre le justifie — elle finit par
  ANNULER quand A130 va jusqu'à l'écriture, et l'on ne fusionne pas deux verdicts qui ne
  s'arrêtent pas au même endroit. Elle RENCONTRE SON CAS d'abord (la collision doit être annoncée,
  sinon l'absence de relation ne prouverait rien). Vérifiées CAPABLES D'ÉCHOUER dans les deux
  sens : lecture après `migrate` → 1 rouge ; relation neutralisée → 2 rouges ; fichier restauré à
  l'octet.
· ⚠ **CE QUI N'EST PAS FAIT, ET POURQUOI — le « grain BLOC ».** Le plan A/F7 prévoyait de
  descendre d'un cran : choisir les BLOCS d'une aide à l'import. C'est refusé, et pas par
  prudence : depuis l'étape B (v5.0.0) un bloc ne porte que des **identifiants** d'items d'un pool
  partagé, et il se relie aux autres par `next`/`options`. Importer un sous-ensemble produit donc
  des références pendantes — c'est-à-dire, à l'écran, **un bloc vide et des branches qui ne mènent
  nulle part**, exactement le défaut de contrat corrigé en v5.0.0. Un algorithme partiel n'est pas
  un algorithme allégé, c'est un algorithme cassé. Le grain juste pour un import reste l'ENTITÉ ;
  ce qui manque à quelqu'un qui ne veut qu'un morceau, c'est l'import PUIS la suppression de ce
  qu'il n'a pas voulu — un geste d'éditeur, à froid, avec l'anneau d'annulation pour filet.

**A132. SAVOIR LEQUEL EST LE PLUS RÉCENT NE DIT PAS CE QU'ON PERDRAIT (v5.9.0, dernier étage de
l'atelier).** A131 met la RELATION sur la rangée ; il restait à pouvoir regarder. Sur une entité
déjà présente, « Comparer » déplie ce que « remplacer » ajouterait et ce qu'il supprimerait — et la
promesse « voir avant d'écrire » est alors tenue de bout en bout : ce qu'on importe (A129), ce que
le filtre atteint (A130), laquelle des deux versions est la plus fraîche (A131), et ce que le geste
destructif coûterait (ici).
· **AUCUN COMPARATEUR NEUF** : c'est celui de « Versions » (`flattenFiche` + différence
  d'ensembles), inchangé. Un second, écrit à côté, finirait par répondre autre chose ici que là sur
  la même paire d'objets. Seule l'ORIENTATION change, et elle est nommée : on part de MA version,
  l'entrant est la cible, donc « + » = ce que le fichier apporte.
· **UNE RÉFÉRENCE A SON APLATISSEMENT** (`flattenProto`) : elle n'a ni bloc ni minuteur, son corps
  est du texte, et ses lignes SONT ses unités de comparaison. La taire aurait laissé sans réponse
  exactement la même question destructive sur l'autre moitié de la bibliothèque.
· **CE N'EST PAS LE DIFF CLINIQUE REFUSÉ EN A119.** Celui-là aurait résumé une modification de dose
  à quelqu'un qui s'apprête à SOIGNER. Ici c'est un geste d'AUTEUR, à froid, et la surface est celle
  que « Versions » lui montre déjà — même public, même dessin, mêmes mots.
· **CALCULÉ À L'OUVERTURE, jamais au rendu de la liste** : sur dix-huit entités, ce serait dix-huit
  aplatissements pour un dépliant qu'on n'ouvrira peut-être pas. Replié par défaut : la rangée
  reste une rangée.
· ⚠ **UNE LIGNE ÉCRITE PUIS RETIRÉE, ET C'EST LA LEÇON DU LOT.** J'avais posé un `preventDefault`
  au motif que « le bouton vit dans un `<label>`, donc l'ouvrir cocherait la rangée ». **C'est
  faux** : un descendant de contenu INTERACTIF n'active pas son label — mesuré sur les DEUX moteurs
  en réintroduisant le défaut, témoin resté vert. La ligne est partie avec la croyance qu'elle
  servait : un commentaire qui affirme un mécanisme inexistant finit par le faire « réparer »
  (A72), et *une déclaration qu'on croit nécessaire peut n'être que du bruit* (A73, pris par
  l'autre bout).
· ⚠ **ET UNE ASSERTION TROP LÂCHE EST RESTÉE VERTE SUR UNE ORIENTATION INVERSÉE** : elle cherchait
  le titre entrant « quelque part » dans le panneau — or les deux colonnes existent encore quand on
  inverse, seul le SENS est faux, et le panneau se lit très bien. Elle lit désormais les colonnes
  SÉPARÉMENT (`.diff-line.add` contre `.diff-line.del`). *Un témoin qui mesure la présence d'un mot
  ne mesure pas la place de ce mot.*
· **TÉMOINS** : quatre contrôles rejoignent la section A130, dont le décor porte déjà la collision.
  Deux DISCRIMINENT (le dépliant s'ouvre ; le sens est le bon — vérifié capable d'échouer,
  orientation inversée → 1 rouge) ; un troisième — « ouvrir ne change pas la sélection » — est un
  **GARDE** qui ne peut pas rougir aujourd'hui, et il le dit sur place : on le garde parce qu'il
  mesure la PROPRIÉTÉ et non le mécanisme, donc il verrait le jour où ce bouton cesserait d'être un
  élément interactif.

