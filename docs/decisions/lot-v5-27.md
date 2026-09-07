# Lot v5.27 — reprendre, c'est revenir (A333) ; la barre de retour ne survit pas à la fiche (A334)

> Fichier normatif, suite de [`lot-v5-26.md`](lot-v5-26.md) (A331-A332). Les numéros A sont des
> adresses : ne jamais renuméroter. Deux signalements de l'auteur (07/09/2026), mesurés avant
> d'être corrigés.

## A333 — « Reprendre » ramène le passage interrompu, la carte ⚡ juste avant lui (v5.27.0)

**Le signalement.** « Complication puis retour à l'étape : ouvre une nouvelle étape, devrait
revenir vers l'ancienne étape et placer le bloc complication juste avant, car si on laisse un bloc
ouvert c'est perturbant. »

**Mesuré avant correction** (sonde jetable, fiche d'exemple Anaphylaxie, une coche posée avant
l'évènement) : journal `[A(replié, incomplet, 1 coche) · ⚡CX · A'(neuf, 0 coche)]`, visites
`[1, 2, 3]`. Trois passages pour un seul geste, et la coche d'avant l'évènement vit dans une carte
repliée que rien ne ramène.

**Ce n'était pas un « nouveau passage » en soi — le bouton le disait déjà** (remarque de l'auteur
après livraison) : « ↩ Reprendre — ‹bloc› → » annonce un RETOUR, et la barre collante dit
« Revenir au bloc en cours ». Poster un passage neuf contredisait le libellé du geste ; la
correction aligne le comportement sur ce que le bouton a toujours promis.

**Ce qui est renversé, et par qui.** A126 (v5.7) avait tranché la lecture inverse : « Reprendre =
NOUVEAU passage, cases neuves (AC 120-71B : on re-vérifie après une interruption) » et n'avait
corrigé que la présentation (repli manuel du passage quitté). Le témoin d'alors mesurait
« deux cartes de ce bloc, une seule ouverte ». L'auteur renverse ce verdict : le passage interrompu
est LE passage en cours, ses coches sont des gestes faits, et une checklist n'en repart pas à zéro
parce qu'un évènement l'a coupée — on reprend là où l'on était, l'excursion restant tracée juste
avant. La doctrine « cases neuves » est barrée dans `conventions-de-code.md` (le texte d'origine
reste lisible), et les deux témoins qui l'affirmaient sont réécrits.

**Le mécanisme — `navRestore(k)`.** `cxResume` cherche, en remontant depuis la carte ⚡ (le bout,
qui porte l'ancre `cxBack`), le dernier passage du bloc interrompu ; il le DÉPLACE au bout du fil,
EN PLACE (`splice`/`push` : `state.nav` est l'alias de `Runtime.nav`, un tableau neuf casserait
l'alias en silence — leçon de `shareApplyAnchored`), avec SA visite, donc SES clés de cochage
(`visite:bloc:index`). Résultat mesuré : `[⚡CX · A]`, visites `[2, 1]`, la coche est là, aucun
tag « passage 1/2 ». Sans ancre ou sans passage à retrouver (journal reçu d'un autre écran, ancien
enregistrement), l'ancien chemin reste : `navAdvance`, passage neuf — jamais un journal cassé.

**Ce que le réordonnement oblige à revoir, et c'est écrit.**
- **Les replis sont indexés par POSITION** (`state.ovFold[i]`, `r:i`). `ovFoldRemap(avant, après)`
  fait suivre chaque repli à sa VISITE (numéro unique par passage) ; fil identique → no-op ;
  passage disparu → repli oublié. Le passage ramené est rouvert d'office (le repli d'A126 tombe).
  L'invité qui reçoit un fil réordonné (`shareApplyAnchored`) rejoue le même remap : ses replis
  locaux ne glissent pas d'une rangée.
- **« L'entrée suivante du fil »** avait trois lecteurs qui lisaient `nav[idx+1]` : `instComplete`
  (une décision est complète si l'entrée suivante est l'une de ses cibles), `decTaken` (la réponse
  prise) et `ovAnswer` (re-taper une réponse déjà prise = défiler, pas reposter). Depuis A333 une
  carte ⚡ peut se ranger ENTRE une décision et la cible qu'elle a désignée : sans rien changer, la
  décision redevenait « non répondue » et se rouvrait. `navNextIdx(nav, navSeq, idx, cxb)` saute
  les passages d'excursion (ancre `cxBack` sur leur visite) ; PURE, les ancres sont passées et
  jamais lues dans `Runtime` — `instComplete` reste testable telle quelle (témoin ajouté).
  Sur un journal d'AVANT (jamais réordonné), le saut ne change aucun verdict : une carte ⚡ n'y
  suit une décision que si celle-ci n'était pas répondue.
- **Le partage** n'a rien à apprendre : l'évènement `nav` voyage ENTIER (nav + navSeq + cxb), il
  n'est pas un ajout au bout ; l'invité reçoit le fil réordonné et le rend tel quel.
- **Le compte-rendu** lit les excursions par leur ancre (`cxBack` → visite → bloc) et les trie par
  heure : indépendant de l'ordre du fil.

**Mesuré après** (sonde, Arrêt cardiaque : décision répondue puis complication sur sa cible) :
`[A · D · ⚡CX · C]`, visites `[1, 2, 4, 3]`, D reste une chip ✓ (répondue, cible retrouvée par-delà
la carte ⚡), C est le bout avec sa coche, ⚡ juste avant ; un second évènement puis reprise :
`[A · D · ⚡CX · ⚡CX · C]`, les deux excursions portent « passage 1/2, 2/2 », C toujours seul.

**Témoins.** `audit-complications` (retour = même visite, coches gardées, bout ouvert, seul de son
bloc, ⚡ juste avant) ; `audit-doctrine` « ⚡ la reprise après complication redépose sur le bloc
interrompu » (une seule carte, ouverte, ⚡ avant) ; `tests.html` (`instComplete` saute une
excursion rangée entre une décision et sa cible ; sans ancre, elle compte).

## A334 — la barre « ↩ Bloc… » se resynchronise à tout changement de vue (v5.27.0)

**Le signalement.** « Bouton retour au bloc apparaît sur la page d'accueil lorsqu'on termine la
session et qu'il est visible. Est-ce la seule situation de bug ? »

**Mesuré** (sonde jetable, quatre portes de sortie, barre visible avant le geste) :

| Porte | Avant | Après |
|---|---|---|
| (a) « Terminer la session… » par le menu ⋯, confirmé | barre visible sur l'accueil, **pour toujours** | masquée |
| (b) retour d'en-tête, session vive | visible **≈ 1 s** sur l'accueil, puis masquée | masquée d'emblée |
| (c) « Tout voir » (vue statique) | visible | visible — voulu : `.sv-cell.cur` est dans son sélecteur |
| (d) « Terminer » depuis la carte de l'accueil | masquée | masquée |

**La cause.** `syncBlkReturn` n'avait que deux appelants : le cœur de cochage (re-rendu du
journal) et le TICK des minuteurs. Or le tick sort avant tout travail dès qu'aucune session ni
minuteur n'est actif — c'est précisément l'état qui suit « Terminer ». La barre, `position:fixed`,
restait donc peinte sur l'accueil, et (b) ne se masquait qu'au tick suivant, une seconde plus tard.
Ce n'est donc pas la seule situation : toute sortie de la fiche par un re-rendu (en-tête, éditeur,
tuile d'une autre aide) laissait la barre le temps d'un tick, et « Terminer » la laissait sans
limite parce qu'il coupait aussi le tick.

**Le remède** : `render()` appelle `syncBlkReturn()` en fin de course — c'est LE point de passage
de tout changement de vue (la doctrine du retour système le dit déjà). Hors lecture, la fonction
trouve `card = null` et masque ; en lecture elle est idempotente (« ne réinstalle rien tant que la
carte courante ne change pas »). Le tick garde son appel : le défilement ne passe pas par
`render()`.
