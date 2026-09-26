# Lot v5.31 — des minuteurs et compteurs liés aux étapes, et leur légende (A377)

> Fichier normatif, suite de [`lot-v5-30.md`](lot-v5-30.md) (A345-A376). Les numéros A sont des
> adresses : ne jamais renuméroter. Demande de l'auteur (25/09/2026) : « explore l'idée de mettre
> des minuteurs dans des blocs d'étapes et/ou des blocs conditionnels », avec pour exemple une
> tentative de laryngoscopie bornée à 1:00 et rebouclée par « Intubation réussie ? — Non ». Puis :
> « pourquoi ne pas afficher un petit compteur / minuteur en bas d'une ligne d'étape ». Trois
> versions de maquettes sur canevas (v1 pastilles, v2 légende 12 px, v3 légende 13,5 px), la v3
> retenue AVEC un ajustement proposé et accepté : pas de fond bleu pour ce qui tourne.

## A377 — la coche lance, la coche compte, le bloc minute ; une ligne le dit (v5.31.0)

**Le constat.** Aucun lien n'existait entre une étape et un minuteur ou un compteur. L'équipe
cochait « Choc », puis tapait le « + » du compteur ; cochait « Adrénaline », puis lançait la tuile
« prochaine dose ». Deux gestes pour un fait, et le second s'oublie sous stress. Le seul précédent
était le compteur qui relance un minuteur (`counters[].timerId`, v4.5).

**Le modèle (trois champs, tous facultatifs, ajoutés — règle 12 inchangée).**

- `item.starts` : id d'un minuteur de la fiche. Cocher l'étape le lance depuis zéro.
- `item.counts` : id d'un compteur de la fiche. Cocher l'étape compte + pas, avec son repère au
  journal (le geste du « + », factorisé dans `cnBump` : le bouton et la coche font la même chose,
  relance du minuteur lié au compteur comprise).
- `block.timer` : id d'un minuteur. Il repart à CHAQUE ENTRÉE par un geste de conduite
  (« Continuer », réponse à une décision, nouveau passage, complication, « Recommencer ») ; au bloc
  où la session démarre, AVEC elle. Décision de l'auteur, qui **amende A330 sur ce seul cas** : ce
  minuteur-là n'est plus « à lancer ».

Un seul lien par étape (`starts` l'emporte si les deux arrivent). Les références se RÉSOLVENT dans
`migrate`, après les minuteurs et compteurs — seul point où leurs ids finaux existent, même règle
que les jalons ; une référence qui ne résout pas ne sort jamais vivante (règle 5). Un item sans lien
n'a AUCUNE clé de lien : il reste identique à l'octet. L'éditeur purge les liens d'un objet
supprimé à l'enregistrement (`edCommit`, patron de `timerId`).

**Les effets vivent dans le geste LOCAL, jamais dans l'application d'un état reçu.**
`linkOnCheck` est appelé par `applyCheck` — le cœur UNIQUE du cochage local (I4), après la garde de
rôle — et `linkEnter` par les portes de conduite. Le partage n'a rien à apprendre : `shareDiff`
compare des instantanés, l'effet part comme n'importe quel état (compteur, minuteur, repère). Le
rejouer à la réception compterait deux fois. Rien ne change côté serveur : la liste blanche
`share_fiche` filtre les champs de PREMIER niveau, et `items`/`blocks` y figurent déjà.

**Naviguer n'est pas conduire.** Taper un nœud du plan, une cellule de la Page ou un bloc jamais
visité passe aussi par `navAdvance` : l'armement n'est donc PAS dans `navAdvance`, il est aux portes
de conduite seulement. Une complication arme le minuteur de son bloc mais ne fait sortir d'aucune
boucle (`noExit`) : elle interrompt, elle revient. « Reprendre » ramène un passage, ce n'est pas
une entrée.

**Trois garde-fous, validés par l'auteur sur maquettes.**

1. **Annulable par la case.** Décocher retire le + pas et BARRE le repère de cette coche (voidAt,
   réversible — jamais effacé ; repli pour une coche venue d'un autre écran : le dernier repère
   vivant à cette valeur, car la clé `ck` ne voyage pas). Décocher dans les **10 s** rend le
   minuteur à son état EXACT d'avant (`LINK_GRACE_MS`, grâce en mémoire seulement : elle ne survit
   pas à un rechargement). Après, décocher ne coupe pas une alarme : le minuteur continue et
   s'arrête depuis sa tuile, et la légende le dit (« décochée, le minuteur continue »).
2. **Sortie de boucle.** Un minuteur de BLOC s'arrête quand le parcours arrive sur un bloc depuis
   lequel son bloc n'est plus atteignable, SI ce bloc est dans une boucle (`loopExitStops`, pure).
   C'est structurel, jamais clinique : sans lui, « Tentative 1:00 » sonnerait après une intubation
   réussie. Un bloc hors boucle n'arrête jamais le sien ; un minuteur armé par une étape non plus.
   Échu et quitté : son alarme est acquittée (elle n'a plus d'objet). La carte des armements
   (`linkArm`) persiste avec la session (`linkArmSnap`, assainie à l'entrée) mais ne monte pas au
   serveur (`sessionToRow` la retire — mécanique d'une session vivante).
3. **Rien ne décide.** À l'échéance d'un minuteur de bloc, AUCUNE réponse n'est choisie, rien ne
   défile, aucune fenêtre ; l'alarme est celle, inchangée, de tout minuteur. Qualification écrite
   AVANT le code : `docs/deploiement-et-conformite.md` § 2, « minuteurs et compteurs liés ».

**La légende (`wtTimerModel`, `wtCountModel` — pures, testées ; `paintWitness` au tick).**
La maquette v3 ajustée, au pixel :

- UNE ligne de **24 px réservés dans tous les états**, 6 px sous le libellé, corps **13,5**
  (deux crans sous l'étape à 17,5, qui reste le texte fort). Glyphe 14. Le débord de 8 px à gauche
  garde le texte aligné sur le libellé quand la pastille s'allume.
- **La valeur d'abord** (mono 700, jamais tronquée), le texte ensuite (ellipse). La valeur vient de
  `timerDisplay` — le calcul de la tuile : deux horloges ne peuvent pas diverger.
- **Gris au repos** (montre, « 04:00 à la coche · Adrénaline… »). **Bleu SANS FOND quand ça
  tourne** : anneau qui se vide et valeur en bleu — pas d'aplat, parce qu'A11 réserve l'aplat à ce
  qui exige une action maintenant, et qu'un minuteur qui tourne n'exige rien. Deux fonds bleus dans
  une carte déjà bordée de bleu auraient aussi noyé l'échéance, et le bleu pâle posé sur une rangée
  cochée (vert pâle) disparaissait la nuit. **Pastille ambre pâle à l'échéance** (`--warn-soft`,
  filet `--warn-line`), le mot « Échu » et la ligne d'action de l'auteur en encre pleine.
- **Aucune hauteur ne change sans geste (A9)** : l'échéance et la fin des 10 s changent le TEXTE de
  la ligne, jamais sa hauteur. La v1 des maquettes ajoutait une ligne à l'échéance — défaut relevé
  et corrigé dès la v2.
- **Aucun seuil de durée** : « il y a 1:20 » ne change jamais de couleur. Une légende date un geste
  FAIT ; elle ne dit jamais « en attente depuis » (l'interdit du partage, rappelé au § 2).
- **Compteur** : « 2 → 3 · Choc · il y a 1:20 » ; au moment de la coche, SEUL le chiffre neuf
  bouge (monte d'une demi-ligne, vert vers encre en 1,8 s, transform/opacity/couleur, rien sous
  mouvement réduit). `paintWitness` ne réécrit une légende que si son modèle a changé
  (`data-wth`) : une réécriture relancerait l'animation.
- **Lecture seule** : le témoin ne se tape pas, la case reste le seul geste.
- **Où** : sous l'étape, sur le passage LE PLUS RÉCENT du bloc (un passage ancien est replié) ;
  sous le titre du bloc pour son minuteur. Annoncée SANS ÉTAT dans le parcours à plat (`wt-flat` ; en mots depuis A388, `pfStepQual`),
  la Page (`wt-sv`) et l'éditeur, sous la ligne liée (`wt-ed`).

**Éditeur.** Dans les outils d'une étape (au focus), un sélecteur « Coche : rien d'autre / La coche
lance… / La coche compte… » — pointillé tant que rien n'est lié (grammaire « créer »), plein et bleu
quand un lien existe ; sous le bloc, « Minuteur du bloc » et sa phrase d'usage. Aucun contrôle mort :
sans minuteur ni compteur dans la fiche, rien n'est proposé.

**Parcimonie — le mot de l'auteur : « pas partout, aux choses essentielles ».** Le prompt IA de
création gagne une section « MINUTEURS ET COMPTEURS LIÉS AUX ÉTAPES » : 0 à 3 liens par fiche,
0 ou 1 minuteur de bloc, seulement quand la source associe explicitement le geste et le délai (ou
le compte), jamais sur une surveillance ; un cycle continu (RCP) reste un minuteur de fiche ; une
vérification finale (n° 17). **Les deux fiches d'exemple** (proposées au premier lancement)
montrent l'usage, chacune avec au plus trois liens :

- **ACR** — « Choc immédiat » compte les chocs (le jalon « 3 CEE » suit seul), les deux
  « Adrénaline » lancent « prochaine dose ». Le cycle RCP reste un minuteur de fiche (règle du
  prompt, et `cycleHint` n'annote qu'un minuteur à cycles unique).
- **Anaphylaxie** — les deux injections IM (bloc initial, bloc réfractaire) comptent sur
  « Adrénaline IM », et ce compteur relance la « Réévaluation après adrénaline » par son
  `timerId` déjà existant (v4.5) : une coche = le compte + les 5 min, sans lien nouveau.

Aucune des deux ne porte de minuteur de BLOC, et c'est voulu : aucune n'a de tentative bornée par
passage (le cas de la laryngoscopie). En inventer une pour la montrer contredirait la parcimonie ;
le témoin d'audit l'exerce sur une fiche injectée.

**Réutilisation, pas de doublon.** Demande de l'auteur : commentaires courts, fonctions
existantes réemployées. `tmRestart` est LE geste « relancer depuis zéro » (lien de coche, minuteur de
bloc, compteur lié, ⟲ d'un ad hoc — quatre copies auparavant, dont deux qui oubliaient de lever
l'acquittement). `cnInc` / `cnBump` portent le « + » d'un compteur (bouton, coche liée, chip du
journal). `cnEvents` sert le compte rendu de la carte et la légende. `tmName` remplace sept copies de
« nom ou Minuteur/Chronomètre ». `blkReach` (graphe des blocs) sert aussi `offPathSet`. Les glyphes
de la légende viennent de `uiIcon` (`stopwatch`, et `counter` ajouté à la table), sauf l'anneau, qui
porte une valeur. La doctrine vit ici ; le code ne garde qu'une ligne et le renvoi.

**Formes écartées, à ne pas reproposer.** La v1 (pastille pleine largeur, piste, bande de bloc à
24 px — le plus gros chiffre de la carte était un minuteur) ; la pastille bleue de la v3 brute
(raisons ci-dessus) ; un témoin tapable (faux tap garanti à côté de la case) ; l'échéance qui
choisit la réponse (refusée par l'auteur) ; un bloc « hybride » étapes + question (double la
grammaire des blocs — la décision qui suit remplit ce rôle).

**Témoins.** `tests.html`, groupe « Témoins d'étape » : résolution et rejet des liens dans
`migrate`, un seul lien par étape, `linkOf`, `blkInLoop`, `loopExitStops` (sortie, question dans la
boucle, lien d'étape, pas deux fois), `wtTimerModel` (repos, en cours = valeur de la tuile, anneau,
échu, indice, chronomètre, sortie), `wtCountModel`, `linkArmSnap` (prototype banni). Sondes
navigateur (Chromium) : ACR — coche du choc 0 → 1 puis retour et repère barré, adrénaline lancée
puis rendue à l'arrêt dans les 10 s ; intubation — minuteur de bloc lancé avec la session, réarmé
à « Non », arrêté à « Oui » (sortie de boucle), annoncé dans la Page ; Anaphylaxie — deux liens
exactement, et la coche de l'adrénaline IM compte 1 et lance la réévaluation ; éditeur — sélecteur à 32 px
(une règle `.field select` l'emportait en spécificité), légendes annoncées sous les étapes liées.

## A378 — les micro-mouvements de la légende disent ce que le geste a fait (v5.31.0)

**La demande.** « Des micro-animations très discrètes, non bloquantes mais LOGIQUES […] dans
l'objectif d'améliorer la compréhension des mécanismes de ces ajouts, et une cohérence globale,
à la Apple. » La règle retenue : **chaque mouvement répond à UN geste et en dit l'effet** ; aucun
ne s'anime seul, aucun ne boucle (le vocabulaire des micro-animations v4.3.2 et, en crise, « le
geste et l'alarme seuls », token § 8).

| Geste | Mouvement | Ce qu'il enseigne |
|---|---|---|
| Cocher une étape qui compte | le chiffre neuf MONTE, vert puis encre (existant) ; la tuile du compteur pousse (`cnPop`, existant) | la coche a ajouté 1, et ce 1 est dans la tuile |
| Cocher une étape qui lance / entrer dans un bloc minuté | l'anneau se REMPLIT depuis vide (`wtArm`, 360 ms) ; la tuile du minuteur entre (`seg-in`, existant) | relancé DEPUIS ZÉRO, et c'est ce minuteur-là |
| Chronomètre lancé | la valeur monte (`wtRoll`) | il part |
| Décocher (compte, ou minuteur dans les 10 s) | la valeur REDESCEND (`wtBack`, miroir de `wtRoll`) | le geste est défait, on revient à l'état d'avant |
| Fenêtre d'annulation | une JAUGE de 2 px sous « décocher annule · N s » se vide en 10 s (`tLife`, le dessin de la barre de vie des bulles) | combien de temps reste pour défaire |
| Échéance | la pastille ambre se pose en fondu (`--dur-2`) — l'alarme, elle, reste celle du minuteur | un état, pas un deuxième signal |
| Éditeur : choisir « La coche lance / compte » | la légende NAÎT sous la ligne (`cbIn`), sans attendre un re-rendu | ce que la coche fera, dit tout de suite |

**Mécanique.** Le modèle porte l'ÂGE du mouvement (`arm`, `gr`, `back`, en ms, seulement pendant
`WT_MV_MS` ou la fenêtre de grâce) et la légende l'écrit en délai NÉGATIF (`--wt-d`) : la
réécriture au tick ne relance donc rien, elle reprend en phase (mesuré : jauge à 0,69 à 3 s).
Le retour se date au runtime (`linkBack`, en mémoire comme `linkGrace`). transform, opacité et
peinture seulement (`check-anim`), jamais de hauteur (A9) ; tout vit sous
`prefers-reduced-motion:no-preference` — en mouvement réduit l'état change, rien ne bouge, la jauge
disparaît (le « N s » écrit reste). La jauge n'est PAS un soulignement : un souligné se lirait
« tapable », et le témoin ne se tape pas (piste pâle + remplissage, décalée après le « · »).

**Écarté.** L'anneau qui se vide en continu (mouvement permanent : la légende change par seconde,
c'est assez) ; un pouls à l'échéance (l'alarme existe, deux pouls se disputeraient — et A331 a
refusé les boucles) ; un fondu à chaque seconde du texte.

**Témoins.** `audit-doctrine` A377 : monter, redescendre, remplir + jauge, remplissage à l'entrée
du bloc, rien sous mouvement réduit (l'état change quand même) ; `tests.html` : âge porté puis
retiré du modèle.

## A379 — ne pas anticiper : un délai repart au geste, jamais à la sonnerie (v5.31.0)

**Le signalement de l'auteur.** « Il ne faut pas surautomatiser. Le minuteur a sonné : il peut se
passer 30 s entre l'analyse du rythme et l'administration du mg — il peut aussi y avoir un CEE
entre-temps. Donc ne pas redémarrer le minuteur automatiquement, et ne pas vouloir anticiper les
choses. »

**Ce que le code faisait.** Un minuteur à cycles (`autoloop`) se remet à zéro À LA SONNERIE
(`tickAll`) et n'est jamais « Échu » (`timerDue` l'exclut). La fiche d'exemple Anaphylaxie, en
v5.31.0, cumulait les deux : « Réévaluation après adrénaline » repartait seule toutes les 5 min
ET à chaque injection cochée — l'intervalle affiché dérivait donc de l'intervalle réel dès le
premier retard d'administration.

**La règle.** Un délai qui court DEPUIS un geste (prochaine dose, réévaluation après injection)
n'a pas `autoloop` : il repart à la COCHE de ce geste (`starts`, ou `counts` sur un compteur dont
`timerId` le relance) — le moment réel de l'administration, dit par l'équipe. À l'échéance il reste
« Échu », sans compter le temps écoulé depuis (l'interdit « en attente depuis », § 2), jusqu'au
geste suivant ou à un arrêt à la main. L'application ne prédit rien : ni la dose suivante, ni son
heure. Fiche Anaphylaxie corrigée (`autoloop:false`), prompt IA : section « NE PAS ANTICIPER » et
nuance sur les boucles de cycle.

**Tranché par l'auteur.** Le cycle RCP de l'ACR RESTE à cycles (un rythme de relais, décision de
l'auteur). Dans l'éditeur, un minuteur d'intervalle NEUF naît sans `autoloop` (il était coché
d'office) : reboucler devient un choix, jamais un défaut. Les fantômes des cycles suivants du
moniteur (`monBandData`) restent en l'état, non tranchés.

**Témoin.** `audit-doctrine` A377 : sonnerie simulée sur la fiche Anaphylaxie, la réévaluation
reste échue et arrêtée.

## A380 — deux essais d'affichage, à juger en conditions réelles (v5.31.0)

**La demande.** « X1 : une option pour switcher en utilisation telle, je n'arrive pas à choisir. X2
pareil. Il faut utiliser en conditions réelles. Et fais en sorte que je puisse ensuite te dire
quelle proposition conserver, et que tu puisses garder ou supprimer l'une ou l'autre très
facilement. » Maquettes : canevas « Session — instruments et parcours », page « Pistes ».

**Où l'on choisit.** Moi › Affichage, deux segmentés : « Essai · Capsule » (Tuiles | Horizon) et
« Essai · Instruments » (Colonne | Bande). Réglage d'APPAREIL (`ac-essai-x1`, `ac-essai-x2`), jamais
synchronisé : on compare sur sa tablette sans rien imposer au reste de l'équipe. Défaut : les deux
éteints, l'application est alors identique à l'octet près de son comportement d'avant.

**X1 — capsule « horizon ».** Là où la capsule a la composition du téléphone, les tuiles de
minuteurs laissent place à un AXE de 5 min : un point par minuteur d'intervalle EN COURS (au plus
trois), posé à son temps restant, son nom court et sa valeur (celle de `timerDisplay`) en
étiquette ; l'échu se pose sur « maintenant » (ambre, △, « échu ») et y reste. **Rien n'est
extrapolé** (règle de l'auteur, A379) : l'axe ne lit pas le parcours, ne dessine ni cycle suivant ni
échéance à venir ; au-delà de 5 min le point reste au bord et la valeur dit le reste. Les
étiquettes alternent au-dessus et au-dessous et sont calées par la mesure dans l'axe (jamais sur
le chrono). La tuile du premier compteur reste si la capsule fait 360 px ou plus. Structure sans
valeurs (aucune réécriture au tick), positions et textes peints à part, comme la capsule d'origine.

**X2 — instruments en bande.** Dès 780 px la capsule garde la composition du TÉLÉPHONE (chrono,
jusqu'à trois minuteurs par échéance, deux compteurs, rappel de ce qui est caché) au lieu de ne
porter que les échéances imminentes ; la toucher ouvre le VOLET des corrections, comme au
téléphone, aligné sur la colonne d'action ; le rail ne garde que le journal, les repères
posologiques et le parcours. La bande garde la largeur de la colonne d'action (A356 : la bande
étirée sur le rail avait été jugée trop grande) et ne monte pas dans l'en-tête à 1440.

**Procédure — le jour où l'auteur tranche.** Tout le code d'un essai est entre ses balises
`ESSAI Xn ▼ … ▲` (CSS et JS) ou derrière `essaiOn('xn')` ; `grep -n "ESSAI X1\|essaiOn('x1')"`
les liste tous.
- **Retirer X1** : supprimer le bloc JS et le bloc CSS balisés « ESSAI X1 » ; retirer `x1` de `ESSAIS`
  et la partie X1 de la section d'audit A380.
- **Garder X1** : dans `updateRtStrip`, la condition devient `if(!wideRail&&started)` ; retirer `x1`
  de `ESSAIS`, les balises deviennent un commentaire ordinaire ; la partie X1 de l'audit reste,
  sans `addInitScript`.
- **Retirer X2** : remplacer chaque `essaiOn('x2')` par `false` et simplifier (`bande` disparaît,
  `wideRail=mqRail.matches`, tranches `slice(0,1)`, `rail=mqRail.matches`, `timekeeperPanel()`
  inconditionnel dans le volet, `renderRead` et `placeCrisisChrome` d'origine) ; supprimer le bloc
  CSS « ESSAI X2 » et la partie X2 de l'audit.
- **Garder X2** : remplacer `essaiOn('x2')` par `true` ; la composition « large » de la capsule
  (échéances imminentes seulement) et la section « Minuteurs / Compteurs » du rail deviennent du
  code mort et PARTENT au grep (règle 14), leurs témoins d'audit avec.
- **Quand les deux sont tranchés** : supprimer `ESSAIS`, `essaiOn`, `essaiSet`, la boucle de
  démarrage, les rangées « Essai · » de Moi et leur liaison, la famille `essai-` de
  `check-classes.mjs`, et purger les clés `ac-essai-*` au démarrage.

**Témoins.** `audit-doctrine` A380 : X1 — un point par minuteur lancé et pas un de plus, ordre des
échéances, étiquettes dans l'axe, l'échu sur « maintenant », retour aux tuiles ; X2 — instruments
dans la bande à 820 px, rail sans minuteurs, volet au toucher, un seul journal.

## A381 — quatre retouches mesurées (v5.31.1)

**La croix d'une notice se centre sur la première ligne.** `.notice-x` était posée à 4 px du haut
avec une cible de 32 px, dans une notice d'une ligne de 34 px : elle débordait de 2 px vers le bas
et paraissait décentrée. Elle est maintenant à 1 px du haut, donc centrée sur la première ligne,
quelle que soit la hauteur de la notice.

**Recherche de l'accueil : 16 px au téléphone.** Le 17,5 d'A374 datait d'un accueil plus gros.
16 px est le plancher tactile (règle 9, Safari iOS zoome en dessous). Le champ rejoint donc la liste
du bloc `(hover:none) and (pointer:coarse)` et quitte le palier < 780. Sans écran tactile, il reste
à 15 px (`--t-item`).

**L'étiquette CRITIQUE / VIGILANCE sort du flux.** La rangée d'étape centre sa case
(`align-items:center`). Avec l'étiquette dans `.txt`, la case se centrait sur étiquette + libellé
+ détail et descendait de ~10 px par rapport aux rangées voisines, ce qui était visible à la
lecture. L'étiquette est désormais en `position:absolute` dans une marge haute réservée de 32 px
(`li:has(.stp-mk)`), alignée sur la colonne du texte (60 / 58 / 56 px selon le palier `zw`). La
case reste centrée sur le libellé.
- **Écarté** : aligner toutes les cases sur la première ligne (`flex-start`). Cela déplace aussi
  les pastilles `.stp-x2` / `.stp-vf` et change toutes les rangées pour corriger celles qui
  portent une étiquette.
- ⚠ **Piège** : les raccourcis `padding` des paliers `zw360` / `zw300` sont plus spécifiques et
  remettaient la marge haute à 8 px. La réserve est donc redite sous ces deux paliers.

**Le parcours du rail se plie bloc par bloc.** `preFlowFlatHtml(f,{md,off,fold:true})`, appelé
seulement par la colonne du cockpit et le rail 780-1199, fait de chaque titre un bouton
(`data-plfold`, `aria-expanded`, chevron de la famille `.conf-chev`).
- **Une décision ne se plie pas** : ses branches (« → aller à n », « ↓ ci-dessous ») SONT le
  chemin ; les masquer rendrait la colonne muette sur ce qu'elle doit dire. Quatre témoins
  (branches nommées, registre ambre, destinations, décisions imbriquées) l'ont rappelé à la
  première passe.
- **Déplié d'office** : le bloc courant seul. Un choix explicite vit dans
  `state.ovFold['l:'+id]`, remis à zéro par `openRead`.
- **Titre en 15 px** (`--t-item`) dans ce seul mode : à 17,5 px, un mot long (« Reconnaissance »)
  débordait sous le chevron dans une colonne de 220 px.
- **La feuille « Se repérer » et l'écran d'entrée ne plient pas** : ce sont des lectures
  complètes, pas une colonne d'orientation.
- **Pourquoi c'était mort** : `bindRailLad` basculait déjà `ovFold['l:'+id]` au toucher d'une
  rangée, mais depuis A376 plus personne ne lisait cette clé. Le geste re-rendait la vue à
  l'identique. Il est maintenant porté par un vrai bouton : Entrée et Espace passent par le clic
  natif (le `keydown` du rail l'ignore) et le focus se repose sur le bouton après le repeint.

**Mesuré** (1512 × 945, ACR en session) : 3 blocs d'étapes pliables, 1 déplié, la décision ouverte, parcours entier visible ; un clic, puis
Entrée : 2, puis 1 déplié ; focus conservé. 340 px (`zw360`) : rangées à étiquette 98 et 80 px,
étiquette à 58 px, case centrée sur le libellé.
