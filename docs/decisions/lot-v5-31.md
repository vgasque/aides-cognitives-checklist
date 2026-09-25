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
  sous le titre du bloc pour son minuteur. Annoncée SANS ÉTAT dans le parcours à plat (`wt-flat`),
  la Page (`wt-sv`) et l'éditeur, sous la ligne liée (`wt-ed`).

**Éditeur.** Dans les outils d'une étape (au focus), un sélecteur « Coche : rien d'autre / La coche
lance… / La coche compte… » — pointillé tant que rien n'est lié (grammaire « créer »), plein et bleu
quand un lien existe ; sous le bloc, « Minuteur du bloc » et sa phrase d'usage. Aucun contrôle mort :
sans minuteur ni compteur dans la fiche, rien n'est proposé.

**Parcimonie — le mot de l'auteur : « pas partout, aux choses essentielles ».** Le prompt IA de
création gagne une section « MINUTEURS ET COMPTEURS LIÉS AUX ÉTAPES » : 0 à 3 liens par fiche,
0 ou 1 minuteur de bloc, seulement quand la source associe explicitement le geste et le délai (ou
le compte), jamais sur une surveillance ; un cycle continu (RCP) reste un minuteur de fiche ; une
vérification finale (n° 17). La fiche d'exemple ACR montre l'usage : trois liens sur quatorze
étapes — « Choc immédiat » compte les chocs (et le jalon « 3 CEE » suit seul), les deux
« Adrénaline » lancent « prochaine dose ».

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
à « Non », arrêté à « Oui » (sortie de boucle), annoncé dans la Page ; éditeur — sélecteur à 32 px
(une règle `.field select` l'emportait en spécificité), légendes annoncées sous les étapes liées.
