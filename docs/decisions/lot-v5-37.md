# Lot v5.37 — la revue « à tout moment » et la bande des repères (A396-A397)

> Fichier normatif, suite de [`lot-v5-36.md`](lot-v5-36.md) (A392-A395). Les numéros A sont des adresses :
> ne jamais renuméroter. Audit demandé par l'auteur le 27/09/2026, conçu sur maquettes Design
> (dix planches statiques et deux jouables) en six itérations ; les formes REFUSÉES sont listées ici
> pour ne pas être reproposées.

## A396 — la revue : une question qu'on se pose à tout moment, posée dans le fil

**Le besoin.** Certaines étapes sont DIAGNOSTIQUES et se posent à tout moment — les causes réversibles
de l'arrêt cardiaque (4H / 4T). Ni une étape du fil (elle n'est cochable que dans son bloc), ni une
complication (rien ne dévie le parcours, on la refait), ni un différentiel (on la fait PENDANT le soin).
Dans la fiche d'exemple, les causes réversibles vivaient à TROIS endroits sans qu'aucune coche n'en
garde la trace.

**Le modèle.** Un bloc `kind:'review'` (`revBlocks`), HORS TRONC comme une cible de complication :
`flowPlan` ne le chaîne pas en orphelin, le Schéma ne le dessine pas, aucun `next`/`target` ne peut le
viser (`targetSelect`, sélecteur des complications). Ses hypothèses sont des items ordinaires du pool
(l'indice après « :: »). Une étape d'un bloc ordinaire porte `item.review = <id>` : c'est l'ÉTAPE-REVUE,
qui se place dans chaque bloc où l'on doit y penser et porte les MOMENTS de toute étape (A382) — c'est le
moment qui la déclenche. `migrate` résout le renvoi (pendant → retiré) et donne à l'étape le NOM de sa
revue : un seul nom, impossible de diverger (l'éditeur rend son champ `readonly`).

**La coche.** Les hypothèses se cochent sous la clé `visite:revue:index` — le format de toute coche, donc
le partage, la sanitisation et la reprise de session ne changent pas d'un octet. La rangée de l'étape-revue
est la PORTE : case pointillée, un tap déplie la grille DANS sa boîte (jamais entre les rangées — le
« satellite » sous la rangée a été refusé : « des trous blancs dans la liste »). La revue est FAITE quand
toutes ses hypothèses sont cochées à cette visite (`revState`) : la case se remplit d'elle-même, la porte
se referme ; un bouton « Revue faite » a été refusé (il permettait de déclarer faite une revue à 3/8). À
chaque passage de la boucle la visite change, donc les huit sont à recocher. « Nouvelle revue » remet la
visite courante à zéro. L'étape-revue ne retient jamais « Continuer » (`visitNeed`), et ses hypothèses
ne comptent pas dans le k/n du bloc.

**Où elle se lit.** Dans le bloc (la porte, k/n, « faite · en cours · à faire »), sous le bloc en carte de
session (même nom, mêmes coches, `data-revcount` suit), dans la colonne « À tout moment » du parcours
(grille pour badge, jamais un saut), dans la colonne de référence de la Page. Dans l'éditeur : porte « Revue »
de la palette, carte propre (badge grille, hypothèses, sans suite ni options), section « Revue » de la
feuille Réglages d'une étape.

**Périmètre réglementaire (§ 2, écrit d'abord).** Une coche d'hypothèse est un ENREGISTREMENT, jamais une
inférence : l'application ne déduit rien de ce qui est coché ou non, n'alerte pas sur une revue non faite.
Un rappel à l'échéance d'un minuteur, s'il vient un jour, devra être DÉCLARÉ par l'auteur, comme un
minuteur de bloc — jamais déduit.

## A397 — la bande des repères du bloc

**Le lien.** `item.poso = <id d'un item dose>` — un repère est un item du même pool (`role:'dose'`), le
renvoi se résout dans `migrate` comme `starts`/`counts`. Le rapprochement par le nom (`posoRank`) reste
pour les cartes et le rail.

**L'affichage — les rangées ne changent pas.** La boîte grise entière reste la coche, rien de cliquable
dedans (formes REFUSÉES : pastille ℞ dans la rangée, ligne ℞ sous la réponse, satellite sous la rangée).
En SESSION, au pied du bloc courant, une bande « Repères de ce bloc » (`posBandModel`, pure) : un repère
par étape liée, dans l'ordre des étapes, sans doublon — nom · voie · posologie, lisibles sans geste. Un mot
venu de la COCHE et de rien d'autre : « fait » (l'étape est cochée), « à faire » (l'étape à son tour),
« à préparer » (les suivantes — l'amiodarone se lit pendant l'adrénaline). JAMAIS d'état de minuteur :
« un repère est une référence, il ne vieillit pas » — l'échéance vit dans la légende de l'étape et dans
la capsule, qui dit « Échu » sans recopier la dose. Un sous-titre « Bloc suivant » a été refusé ; la
bande n'existe pas avant la session.

**Repliable.** Un tap sur sa tête, un seul état pour la session (`state.pband`), dépliée d'office ; la
tête repliée garde le compte et le résumé (« 1 fait · 1 à faire »). Un tap sur une ligne ouvre le DÉTAIL
du repère (`item.note`, champ qui existait et n'était lu nulle part : préparation, dilution,
administration) — l'éditeur l'écrit sous la ligne du repère.

**L'icône.** Le glyphe ℞ en dur est remplacé par `uiIcon('pill')` (trait 2, boîte 24), et la revue par
`uiIcon('grid')`.
