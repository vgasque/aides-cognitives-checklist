# Lot v5.40 — la coche qui compte dit aussi ce que son compteur relance (A440)

> Fichier normatif, suite de [`lot-v5-39.md`](lot-v5-39.md) (A418-A439). Les numéros A sont des adresses :
> ne jamais renuméroter. Demande de l'auteur du 02/10/2026, sur maquette (canevas « Coche liée : compteur qui relance »).

## A440 — une étape qui compte ET relance : visible, réversible, signalée (v5.40.0)

**La question de l'auteur.** « Pourquoi on peut soit choisir un compteur soit un minuteur à relier à une étape ? pourquoi
pas les deux ? » La règle « un seul lien par étape » (A377) était posée sans motif écrit. La combinaison existait déjà,
par le compteur : `counters[].timerId` (v4.5) fait relancer un minuteur par le « + » d'un compteur, donc aussi par toute
coche qui compte sur lui — l'exemple Anaphylaxie s'en sert (A379). Mais ce chemin était un manque d'ergonomie :

1. **Introuvable à l'écriture.** La feuille « Réglages » de l'étape proposait « rien / lance / compte » ; le réglage
   « Le ＋ relance » vivait sur la carte du compteur, sans renvoi.
2. **Muet en session.** La légende disait « 1 → 2 · Adrénaline IM » ; rien ne disait que la coche remettait la
   réévaluation à zéro — ni qu'il lui restait 02:41, ce que la coche efface.
3. **Non réversible** (défaut). La grâce de 10 s d'A377 rendait le minuteur d'un lien DIRECT ; par le compteur, décocher
   retirait le + 1 mais le minuteur restait relancé : le délai de la dose précédente était perdu.
4. **Sans garde-fou.** Rien ne signalait un minuteur CYCLIQUE relancé par un geste — la configuration exacte qu'A379 a
   corrigée dans la fiche Anaphylaxie.

**Décision (de l'auteur, sur recommandation).** On GARDE un seul lien par étape : le lien compteur → minuteur reste sur
le compteur, parce que c'est lui qui porte le sens clinique (chaque dose relance le délai, qu'on la note par la coche
ou par le « + » de la tuile). Un second lien sur l'étape ferait deux manières de dire la même chose, qui finiraient par
diverger. On rend en revanche ce chemin visible, réversible et signalé.

**La légende : deux lignes, pas une.** La maquette proposait UNE ligne de 24 px enrichie (« 1 → 2 · Adrénaline IM ·
relance Réévaluation · reste 02:41 »). Mesuré à 390 px : la ligne dispose de 268 px ; même resserrée (« 0 → 1 · Rééval.
adrén. 02:41 → 05:00 », nom court, sans le verbe) l'essentiel en demandait ~275 — coupé, et pire sous zoom de texte. Une
variante où les segments secondaires tombent en entier (retour à la ligne masqué) a été écrite puis retirée : elle
laissait tomber justement ce qu'on voulait dire au téléphone. Retenu : **une étape qui compte sur un compteur qui relance
a DEUX lignes de légende, réservées dans tous les états** (A9 : la hauteur dépend de la fiche, jamais de l'état) —
la ligne du compte, inchangée, puis **la ligne du minuteur relancé, au dessin EXACT d'un lien direct** (`wtModelFor`
spec `r|…`, `wtTimerModel`) : « 05:00 à la coche · Rééval. adrén. », en cours « ◔ 02:40 · la coche relance à 05:00 »,
cochée « ○ 04:58 · décocher annule · 9 s » avec sa jauge, échue « Échu · ‹ligne d'action› ». Aucune grammaire nouvelle.
Cyclique : « la coche recale le cycle ».

**Le nom court de la tuile.** Les lignes de minuteur liées (lien direct ET relance) prennent `tmShort` — le nom de la
capsule, celui que l'équipe voit sur la tuile — au lieu du libellé complet : « Réévaluation après adrénaline » était
coupé à 390 px. `wtTimerModel` accepte `ctx.nm` ; sans lui, rien ne change.

**La grâce de 10 s couvre la relance.** `linkOnCheck` mémorise l'état du minuteur que relance le compteur avant
`cnBump` (`linkGrace[k]` porte `tid` et `prev`) et le rend à la décoche dans le délai — comme un lien direct. Toujours en
mémoire seulement : elle ne survit pas à un rechargement.

**L'éditeur.** (a) Feuille « Réglages » : sous « ＋1 Adrénaline IM », une rangée en lecture seule « et relance
« Réévaluation après adrénaline » · 5 min — réglé sur le compteur : son ＋ le relance aussi » et un bouton « Compteur »
qui ferme la feuille et pose le focus sur le nom du compteur (`stepSetChainHtml`, `data-sstcn`). (b) La pastille de
l'étape le dit : « +1 Adrénaline IM · relance … ». (c) Carte du compteur : « Compté par n étapes », une rangée par étape
(libellé, bloc), chacune rouvre ses réglages (`cnUsesHtml`, `data-cuse`), et la phrase « Chaque coche de ces étapes, comme
le ＋ de la tuile, relance … ». (d) Un minuteur cyclique relancé par un geste — lien direct ou par le compteur — se signale
par une carte ambre `.lk-warn` « △ Minuteur cyclique » (dans la feuille et sur la carte du compteur) : elle INFORME sans
interdire, recaler le cycle RCP après un choc étant un usage légitime (A379 garde le cycle RCP à cycles). Changer le
minuteur relancé ou « se relance » re-rend l'éditeur ancré, focus gardé (`edRowRedo`).

**Partage de session — rien de nouveau ne voyage.** Les effets restent dans le geste LOCAL (A377) : celui qui coche
— hôte, ou invité dont le rôle l'autorise — compte, relance, et c'est l'ÉTAT qui part (`counter`, `timer_arm`, `mark`) ;
l'autre écran ne rejoue rien. Chaque écran calcule ses deux lignes depuis son propre état : même valeur, même minuteur.
La restitution sous 10 s est elle aussi un état (`timer_arm` à l'ancre d'avant, `counter`, `mark_void`). Limite connue et
assumée, la même que pour un lien direct : la grâce vit sur l'appareil qui a coché — décocher depuis l'AUTRE écran retire
le + 1 mais laisse le minuteur relancé (sa ligne le montre : « la coche relance à 05:00 », valeur courante). L'invité figé
(A385) applique ses effets localement et les envoie au retour.

**Formes écartées.** Deux liens sur l'étape (`starts` ET `counts`) ; la ligne unique enrichie (mesurée trop longue) ; les
segments qui tombent en entier ; « 02:41 → 05:00 » sans verbe (illisible hors contexte) ; un avertissement qui
interdirait le cyclique.

**Témoins.** `audit-doctrine`, section « v5.31 · A377 — liens de coche et minuteur de bloc », fiche Anaphylaxie à 390 px :
deux lignes de 24 px au repos, en cours (« 02:4x · la coche relance à 05:00 »), cochée (« décocher annule », même hauteur
de rangée), et la réévaluation RENDUE à son état d'avant après une décoche dans les 10 s.
