# Lot v5.20 — ce qui coiffe le haut, ce qui manque au pouce (A286-A290)

> Deux signalements à l'usage du 01/09/2026, tous deux nés de la refonte d'accueil v5.18 : le rail
> A→Z qui pose sa lettre SOUS un objet collant, et la gestion (catégories, bibliothèques) devenue
> injoignable sur téléphone faute de colonne gauche. Mesurés sur l'app SERVIE avant tout correctif.

**A286. UN SAUT DU RAIL A→Z SE POSE SOUS CE QUI COIFFE LE HAUT DU DÉFILEUR, PAS SOUS LE BORD DE
L'ÉCRAN.** Signalé mot pour mot : « depuis la refonte de l'en-tête, le premier résultat de la
lettre est masqué ». Le mécanisme est un reste de la v5.18 : l'en-tête d'accueil y est devenu
STATIQUE, la cible du saut a donc cessé de soustraire quoi que ce soit (`offY(g) - 8`) — ce qui
était juste ce jour-là. Deux objets ont continué, eux, à coiffer ce haut :

- la **barre de sélection** (`.sel-bar`, collante à 0) — mesuré : intertitre de lettre entièrement
  avalé, **17 px de la première rangée** sous la barre ;
- la **bande de zone sûre** de l'iPhone INSTALLÉ (`body.view-home::before`, posée dans le même lot
  v5.18 pour que le contenu ne défile plus sous l'heure ; l'intertitre collant s'arrête dessous).
  Le saut posait la section à 8 px du bord d'écran, donc SOUS la bande : l'intertitre s'épinglait
  alors à 47 px et recouvrait la rangée qu'il annonce — **39 px de 60 mesurés**.

Correctif : la cible ôte la coiffe, LUE au moment du saut (`coiffe(g)`) et jamais écrite en
constante — le `top` calculé de l'intertitre porte déjà `env ÷ --zf`, la hauteur de la barre est
une mesure visuelle donc divisée par `zoomF()` (règle 10). Les deux branches (page en étroit,
`.home-main` en large) partagent la même soustraction. **Équivalence prouvée là où rien ne
coiffe** : nominal inchangé au pixel, en étroit comme en large, sur les deux moteurs.

⚠ **POURQUOI VINGT ET UN HARNAIS N'ONT RIEN VU, ET CE QUI CHANGE.** `env(safe-area-inset-top)`
vaut **0** dans un navigateur : la moitié du défaut n'existait que sur un appareil installé, et
l'autre moitié demandait le mode SÉLECTION, qu'aucune sonde du rail n'activait. Le témoin
(`audit-doctrine`, section « le rail A→Z pose sous ce qui coiffe ») joue donc TROIS cas — nominal,
sélection, et **encoche simulée** : on substitue la même géométrie par un littéral de 47 px, sans
toucher au code mesuré. Il est né ROUGE sur les trois assertions qu'il fallait (l'intertitre
coiffé en sélection, la rangée recouverte dans les deux cas), vert après correctif sur Chromium et
WebKit.

**A287. LA GESTION DESCEND AU POUCE — MÊME PATRON, MÊME CAUSE QUE « REJOINDRE UNE SESSION »
(v5.14.3).** Signalé : « sur smartphone il n'y a pas de sidebar : je ne peux plus gérer les
catégories, et les bibliothèques je ne peux les gérer qu'en vue *Rangé par bibliothèque* ».
Constaté au relevé : sous 780 px, « Gérer les catégories » n'était atteignable QUE par la feuille
de filtres — dont le déclencheur `#filtTog` n'existe que PENDANT une recherche (v5.18) ; et le ✎
d'une bibliothèque administrée ne paraît que sur l'intertitre de section, donc dans un seul
rangement sur trois. La colonne gauche portait les deux entrées ; elle n'existe pas ici.

Une **rangée au socle** (`#mgrBtn`), masquée ≥ 780 px où la colonne gauche reprend la main —
exactement le patron de `#joinBtn`, né du même signalement en v5.14.3. Elle **n'invente aucune
fenêtre** : la feuille `#mgrSheet` est faite des rangées de la colonne (`hsRow`), avec les mêmes
attributs et les mêmes lecteurs (`data-catmgr` → `#catModal`, `data-libedit` → `#membersModal`,
`data-newlib` → `#newLibModal`). Deux règles de politesse, écrites parce qu'elles se discutent :

- **le socle n'ouvre jamais une feuille d'UNE rangée** : sans bibliothèque à administrer — le cas
  de tout usage solo —, la rangée dit « Gérer les catégories » et va DROIT au gestionnaire.
  Libellé et destination disent alors la même chose, et l'on n'ajoute pas un tap pour rien ;
- **on ne liste que ce qui se gère** : une bibliothèque en lecture seule n'a rien à modifier, une
  rangée pour elle serait une commande morte (règle 14). Elle reste lisible partout ailleurs
  (intertitres, colonne gauche), avec son cadenas.

La feuille rejoint les surfaces d'`audit-a11y` **par son vrai point d'entrée** (`#mgrBtn`, profil
posé dans l'état que l'application lit elle-même puis `render()` — jamais un `classList.add('on')`
sur une fenêtre vide, doctrine v4.40.0) : contraste, cibles et anneau de focus mesurés dans les
deux thèmes.

**A288. EN VOIE LARGE, LES DÉFILEURS DE L'ACCUEIL VIVENT DANS `main.innerHTML` — DONC ILS
REPARTAIENT DE ZÉRO.** Signalé : « si on clique sur *modifier bibliothèque* dans la liste de cartes
(pas dans la fenêtre) puis qu'on ferme la fenêtre, on ne revient pas au scroll initial : on revient
en haut de la page ». Le ✎ n'y est pour rien : c'est la fermeture qui, après un enregistrement de
nom, appelle `renderLibrary()`. Or à partir de 780 px la page ne défile plus — ce sont
**`.home-main`** (la liste) et **`.hs-scroll`** (les catégories de la colonne) qui portent
`overflow-y`, et tous deux sont RECONSTRUITS par `main.innerHTML` : leur position retombait à 0.
Mesuré : **600 → 0** pour la liste, **80 → 0** pour la colonne, à chaque re-rendu — donc aussi en
épinglant, en filtrant, en cochant. En voie ÉTROITE le défileur est la PAGE, que `innerHTML` ne
touche pas : le navigateur gardait la position tout seul. **Le même geste n'avait pas le même
effet à 390 et à 1280**, et c'est cette asymétrie qui tranche la question « faut-il préserver ? ».

Correctif au patron de `.read-side` (v4.23.5, même défaut sur le rail de lecture) : capture avant,
restauration après, **bornée au nouveau contenu** — une liste raccourcie par un filtre ne doit pas
poser hors borne. `setSection` garde SA mémoire par section : elle repose sa valeur après ce
rendu, donc elle l'emporte, et deux crans ne partagent toujours pas une position.

⚠ **PIÈGE DE MESURE, ÉVITÉ EN ROUTE (famille A267).** La première sonde interrogeait le nœud
capturé AVANT le re-rendu — un nœud DÉTACHÉ, qui répond `scrollTop = 0` quoi qu'il arrive. Elle
aurait donc affiché « rouge » même une fois le défaut corrigé, et « vert » nulle part. Le témoin
re-interroge le document à chaque lecture, et le défaut a été re-mesuré une seconde fois avec
cette sonde-là avant tout correctif (600 → 0 confirmé). Le témoin d'`audit-doctrine` (« le
défilement survit au re-rendu ») joue les deux défileurs ET le geste signalé par son vrai chemin
(`openMembers` → `closeMembers(true)` + `renderLibrary()`) ; né ROUGE sur ses trois assertions.

## A289 — assainissement mesuré : trois garde-fous nés rouges, purges prouvées, vingt factorisations (v5.20.2)

**Le chantier part d'un inventaire, pas d'une intuition** (phase 0, 31/08/2026) : chaque candidat
« code mort » vérifié au grep toutes formes confondues (destructuration, indexation dynamique,
`tests.html` en `grep -a`, harnais compris), chaque doublon relu dans le code réel, chaque piste
de performance chiffrée à la sonde (médianes, deux moteurs, CPU ×6). Verdict perf : rien à
optimiser — boot dominé par le PARSE (510 ms sur 673 à ×6, le JS applicatif pèse ~40 ms),
interactions à 10-16 ms même bridées, écouteurs délégués (+0 par coche), timers déjà gatés (R6).
Le seul levier mesurable est la masse de commentaires (55,6 % du fichier ; borne haute −70 ms à
×6 sur la variante dépouillée) — le resserrement reste un chantier documentaire, pas une
optimisation.

**Trois trous de garde-fous, fermés et PROUVÉS capables d'échouer** (nés rouges sur l'état
d'avant purge, verts après) :
- `check-fns` sens 2 : un `let` top-niveau ÉCRIT mais jamais LU est mort — le compte de citations
  ne le voit pas, une écriture cite le nom (`_homeGk`, `_selScope` vivaient là ; le second avec un
  commentaire décrivant une comparaison qui n'a jamais existé). ⚠ Leçon en l'écrivant : nommer
  les morts dans le commentaire du contrôle les maintenait en vie — le contrôle est dans son
  propre corpus.
- `check-ids` sens 3 : un id ÉMIS en attribut littéral doit être LU quelque part. Né rouge sur
  **20** croix de fermeture de modales (câblage par la classe `.ai-x`, l'attribut ne servait à
  rien) — dont `mgrSheetX`, née en v5.20.0 PENDANT l'inventaire : le trou fabriquait encore.
- `check-icons` sens 3 : toute entrée de table d'icônes doit être citée hors de la table et hors
  de la feuille (un sélecteur CSS sur une classe jamais émise est une règle morte, pas un usage).
  Né rouge sur `h-main`/`h-forget`/`h-img` — dictionnaire + CSS + un commentaire, zéro émission.

**Purges** (règle 14, zéro citation restante) : côté CSS `.tag.draft`, `.pl-lnk.loop`, cinq états
de `.pc-card` (la vue spatiale v4.6), `.blk-type.steps/.decision`, `.hs-row.hs-cmd` (la classe
vit sur le wrap), la famille `h-*` ci-dessus, quatre écrasements morts (`.options` gap:10 sur
ligne ADJACENTE, `.sv-jl` entière, `.rt-find input` min-height:38, `.pl-line .n` non touché —
PROBABLE) et trois copies de palier strictement incluses. ⚠ `header.bar.home .id-row` L2260 est
GARDÉE : son ordre est le dix-neuvième piège de cascade, seul le double de la plage ≤ 360 part.
Côté JS : `flowCtx.curId` (7 écritures, 0 lecture), les 20 ids, `IMG_PAD` destructuré pour rien,
quatre commentaires menteurs. **Faux positifs écartés et documentés** : FLOWK vivant en entier
(destructuré dans quatre fonctions — l'analyse `.nom` ne voyait pas la destructuration),
POSO_SYN indexé dynamiquement, `ah`/`ahb`/`rt`/`mdsect-`/`catMgrBody`/`selN` vivants par des
chemins dynamiques prouvés.

**Vingt factorisations à sortie identique** (méthode v5.19.4 : le SÛR seulement), dont les
invariants que la doctrine énonçait sans les tenir : `slRxOnText` (récepteur de fontaine optique,
la plus grosse zone dupliquée du fichier, sa divergence de ré-armement neutralisée), `memOps`
(« replaceMem ne ré-insère jamais un supprimé » vivait en six copies), `paintCkLi` +
`rerenderCkAnchored` (le cœur de cochage, v4.42.0), `homeCmp` (« UN SEUL TRI » enfin vrai par
construction), `bindRefBody` (le commun d'A15), `hexDigest` (invariant de protocole),
`_guestReset` (le « pli neuf » identique sur les deux portes), `markPrefsDirty` (six copies qui
se citaient l'une l'autre en commentaire), et les artisanaux : `blocksById`, `sessUpsert`,
`attFetchOne`, `slNewHub`, `decTaken`, `revGoFlash`, `empAnatHtml`, `relRowHtml`, `catOpts`,
`mdSplice`, `blkTopHtml`. Deux contournements résorbés (les fetch bornés artisanaux passent par
`acFetch`) ; l'étanchéité `migrate`/`sanitizeCats`/`acceptFile` vérifiée ligne à ligne — aucun
chemin ne les contourne.

**Et un défaut visible débusqué par la purge elle-même** : `.pc-card:not(.cur):not(.done) .pc-n`
pesait (0,4,0) avec deux `:not` d'états MORTS et écrasait `.pc-n.ok` (0,2,0) — le ✓ de « Quand
l'utiliser » s'affichait sur fond neutre, encre grise. Prouvé à la sonde par le vrai chemin
(session → `#allBtn` → onglet Parcours), deux moteurs, avant ET après : fond `--ok`, encre
`--on-primary` désormais. La règle simplifiée (`.pc-card .pc-n`) rend la main à `.ok` par
l'ordre, à spécificité égale.

**Reste en attente d'arbitrage, sciemment non fait** : les gardes `typeof` toujours vraies
(~40), le resserrement des commentaires (CSS ~250-280 Ko dont la doctrine vit déjà dans docs/ ;
JS : 457 blocs > 6 lignes SANS trace dans docs — migration d'abord, jamais suppression), les
écrasements PROBABLES (`.dir-book .dir-row` au commentaire menteur L2911, `.rt-dock`,
`.hs-wrap.on` sombre), treize groupes de factorisation PROBABLES (dont la quadruple mutation de
navigation, 7 sites), le repli `Math.random` de `uid`, et un effet de bord réel à corriger à
part : `ac-held-edits` survit à `wipeLocal()` (l'effacement TOTAL ne retire pas cette clé, que
`wipeCurrentSpace` retire).

## A290 — l'effacement TOTAL oubliait une clé que l'effacement d'espace retirait (v5.20.3)

Deux effacements, deux listes recopiées : `wipeLocal()` (suppression de compte — TOUT l'appareil)
et `wipeCurrentSpace()` (déconnexion avec « effacer aussi cet appareil » — l'espace courant seul)
énuméraient chacune les clés localStorage NUES du propriétaire de la base historique. La seconde
retirait `ac-held-edits` (éditions retenues), la première non — et sa boucle générique de
rattrapage exige un `@` dans la clé, que la forme nue n'a pas. **Un reliquat d'édition retenue
survivait donc à la suppression de compte**, le geste dont la promesse est précisément de ne rien
laisser. Prouvé à la sonde par le vrai appel (`wipeLocal()` en page, clé semée nue + suffixée,
deux moteurs) : nue SURVIT, tout le reste part ; après correctif, tout part.

Le correctif est STRUCTUREL, pas une ligne ajoutée à une liste : `WIPE_SPACE_KEYS`, LA liste
unique des clés d'espace, consommée par les deux effacements (`wipeLocal` la concatène à ses
extras d'appareil — auth, registre d'espaces, marqueurs). Une clé d'espace nouvelle entre au seul
endroit qui existe ; la divergence qui a produit ce bogue ne peut plus se réinstaller. C'est le
même remède que `MUTE_SEL` (v4.4.2) et `SHARE_KINDS` (A216) : une liste recopiée diverge, une
liste unique non.
