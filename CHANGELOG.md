# Journal des modifications

## [4.56.2] — 2026-07-28
### Le badge « En cours » trouve sa place — et un bug WebKit de grille est neutralisé

### Badge « ● En cours » à droite de la tuile
Glissé dans la sous-ligne de 11 px, le badge l'étirait et semblait rapporté (« on a l'impression
qu'elle n'est pas adaptée », retour utilisateur). Il vit désormais À DROITE de la tuile, centré
verticalement, hors du bloc de texte — la structure de la maquette desktop : colonne
titre + sous-ligne à gauche (`.qa-tx`), badge en frère à droite. Les rangées du répertoire, qui
alignent déjà leurs pastilles sur une ligne dédiée, ne changent pas.

### Pistes de grille figées au redimensionnement — bug WebKit, reproduit puis neutralisé
Signalé à l'usage : « bug lorsqu'on diminue la largeur puis qu'on ré-augmente » — une rangée du
répertoire restait trop courte, titre rogné en haut, date en bas. IRREPRODUCTIBLE sur Chromium
(sondes discrètes puis fines, 100 % et 130 % de taille du texte : rien) ; reproduit sur WebKit
SEUL, au redimensionnement CONTINU : quand un changement du nombre de colonnes d'une grille
`auto-fill` fait ré-enrouler la sous-ligne d'une rangée, WebKit ne regrandit pas la piste — le
contenu centré dépasse (titre +11 px, date +5 px, mesurés, aux valeurs exactes de la capture
utilisateur) et l'état corrompu PERSISTE, y compris après re-rendu.

Remède : à la TRAÎNÉE du redimensionnement (120 ms, accueil seulement), chaque
`.dir-grid`/`.qa-grid` passe par `block` puis `grid` dans la même frame — écriture-lecture-
écriture synchrones, aucun repaint intermédiaire, donc aucun clignotement — et WebKit recalcule
ses pistes. On ne paie pas un reflow par évènement pendant le geste : l'artefact transitoire de
Safari peut fugacement apparaître pendant la traînée et se répare seul 120 ms après la pause.
Vérifié à la sonde sur les deux moteurs et les deux réglages de taille : état final propre
partout, Chromium jamais affecté. Piège documenté dans AGENTS.md (ne pas retirer ce listener ;
re-mesurer sur WebKit à toute retouche des grilles).

Vérifié : 766 tests × 2 moteurs, a11y 301/301 sur Chromium ET WebKit, doctrine 112/112,
`npm run check`. Rien à rejouer côté serveur.

## [4.56.1] — 2026-07-28
### Les tuiles rejoignent la grille fluide du répertoire

Retour utilisateur immédiat sur la v4.56.0 : « la gestion de la largeur des tuiles en responsive
est extrêmement mauvaise pour toutes les transitions de taille ». Mesuré, et confirmé : les
tuiles « Épinglée(s) » avaient un nombre de colonnes FIGÉ (2 sous 780 px, 3 au-delà) — au
franchissement du seuil, la sidebar et le rail mangent ~330 px d'un coup et une tuile passait de
~360 px à **~140 px** ; et leur rythme ne coïncidait jamais avec celui des rangées du répertoire,
posées juste dessous.

**Une seule règle fluide, partagée** : `.qa-grid` adopte l'`auto-fill minmax(290px,1fr)` et la
gouttière 8 px de `.dir-grid`. Tuiles et rangées ont désormais la MÊME largeur à toutes les
fenêtres et s'alignent colonne pour colonne ; mesuré sur toute l'échelle — 320 → 290 px (1 col),
779 → 2 × 356, 780 → 1 × 451, 1000 → 2 × 332, 1460 → 3 × 372, 1620 → 4 × 317 : tout vit dans la
bande ~290-450 px, une transition ne change plus que le NOMBRE de colonnes, jamais l'échelle.

La question qui a ouvert le dossier (« pourquoi la bulle rétrécit au-delà de ~1480 px ? ») a sa
réponse documentée dans AGENTS.md : c'est la redistribution d'une grille fluide quand une colonne
de plus tient (3 × ~390 → 4 × ~296 vers 1520 px) — bornée par le minimum de 290 px, c'est le
comportement normal, à ne pas « corriger ».

Vérifié : 766 tests × 2 moteurs, a11y 301/301, `npm run check`, design system régénéré (la démo
n'impose plus un nombre de colonnes que le vrai CSS n'a plus). Rien à rejouer côté serveur.

## [4.56.0] — 2026-07-28
### L'accueil devient un « poste accès direct » : épinglées, répertoire A→Z, rail alphabétique

Refonte des listes d'aides ET de protocoles d'après la maquette « 2c — poste accès direct » du
canvas Claude Design « Accueil bibliothèques » (modèle du téléphone d'urgence : les favoris sous
le pouce, l'annuaire complet derrière, l'index de tranche pour y sauter).

### Trois étages à la place de la grille de cartes
- **« Épinglée(s) ★ »** — les fiches épinglées en TUILES (liseré de catégorie, code · catégorie,
  « ● En cours »). Libellé accordé au type et au nombre ; **les épinglées seules**, décision
  utilisateur « juste les favoris » — la fréquence d'usage reste un critère de tri de RECHERCHE,
  jamais de mise en avant ; aucune épingle → la section disparaît. Titre en 15 px borné à
  **3 lignes** puis ellipse (2 lignes tronquaient trop pour reconnaître la fiche ;
  `overflow-wrap:break-word`, pas `anywhere` qui coupait « Anaphylaxie » en plein mot) ; le nom
  accessible et l'info-bulle gardent le texte entier.
- **RÉPERTOIRE A→Z** — rangées compactes groupées par lettre (hors A-Z → « # », rangé en fin),
  tri alphabétique STRICT (l'épinglée a sa tuile — la hisser en tête de sa lettre casserait la
  lecture d'annuaire) ; sous 640 px, chaque lettre devient une liste à filets dans une carte
  (maquette mobile). Les rangées gardent l'épingle ☆, le statut en attente, « À revérifier »,
  « À compléter », la catégorie EN TOUTES LETTRES (la couleur d'une pastille n'est jamais seule)
  et la date de validation en forme COURTE (`fmtDateShort` — « Validation : » pèserait plus que
  la donnée sur une sous-ligne de 11 px). Le répertoire ne se pagine JAMAIS : le rail promet
  « A→Z sous le doigt », un « Afficher plus » ferait des lettres injoignables.
- **RAIL ALPHABÉTIQUE** — tap = saut à la lettre, GLISSER le long des lettres = parcourir
  (index iOS ; pointer capture). Dès 2 lettres ; s'il ne tient pas en hauteur il DISPARAÎT
  (jamais de lettres coupées ni de cibles < 24 px). En étroit il est FIXE, ancré entre le bas
  de l'en-tête (`--hdr-h`) et la tab bar — un centrage sur la fenêtre passait sous l'en-tête
  à 320×640, mesuré puis corrigé.

### Ce qui ne change PAS (décisions utilisateur explicites)
La recherche RESTE dans l'en-tête (champ statique : le focus survit aux re-rendus, raccourci
« / » — la grande recherche du corps de la maquette est écartée) ; le filtre catégorie FILTRE
(l'« estompage sans déplacer » de la maquette est refusé) ; en recherche, liste plate triée par
pertinence (épinglées > frecency > titre), extraits contextuels et pagination inchangés.

### Historique GLOBAL des sessions
Le compte « n sauvegardées » des cartes disparaît ; à sa place, la fenêtre Historique gagne un
mode « toutes les fiches » (chaque rangée nomme la sienne, cliniques et exercices toujours
séparés) : rangée « Historique des sessions (n) » en bas de la sidebar en large, lien du pied de
page en étroit — masqués à zéro session (aucun bouton mort). L'entrée PAR FICHE du menu ⋯ est
inchangée. `openSessHist()` sans argument = mode global `'*'`.

### Sous le capot
- Fonctions pures testées : `azLetter`/`azGroups` (lettre désaccentuée, table en
  `Object.create(null)` — la clé vient d'un titre saisi) et `qaPick` ; +10 tests (766 × 2 moteurs).
- L'ancien composant `.card`/`.cards` est PURGÉ (émissions vérifiées au grep, règle 14 ; démo
  `design/build.mjs` refaite ; `newTonal`, champ mort d'avant la refonte, retiré). Le bouton-titre
  GARDE le nom `.card-open` : quatorze harnais ouvrent une fiche par ce sélecteur.
- Périmètre accueil d'`audit-a11y` : `.dir-wrap,.azrail` remplace `.cards` — un sélecteur mort
  ferait passer l'accueil sans le mesurer (leçon v4.31.1). Le bouton-titre des rangées porte un
  padding 6 px compensé : sa BOÎTE atteint 29 px (l'ancien titre passait la mesure parce qu'il
  s'enroulait sur deux lignes ; le `::after` étendu, lui, ne se mesure pas).
- Vérifié : `npm run check`, 766 tests × Chromium + WebKit, a11y **301/301 sur les deux
  moteurs**, doctrine 112/112, zoom-scroll 6/6, zéro débordement horizontal à 320 px, clair et
  sombre. Rien à rejouer côté serveur.

## [4.55.5] — 2026-07-28
### Deux défauts signalés à l'usage — un menu qui tombait dans la barre, une attribution qui suivait la mauvaise personne

### Le menu ⋯ s'ouvrait DANS l'en-tête — dixième piège de cascade
Dès qu'un placard était posé (exercice ou invité), ouvrir le menu ⋯ ne produisait plus une
fenêtre flottante : il retombait **dans le flux de la barre**, qu'il rallongeait d'autant.

Le placard, pour faire passer le contenu au-dessus de sa hachure, levait **tous les enfants
directs** de l'en-tête en `position:relative; z-index:1`. Or `.more-menu` est un enfant direct
**et se positionne lui-même** : `header.bar.exo>*` vaut (0,2,1) contre (0,1,0) pour
`.more-menu{position:absolute}`. La règle décorative écrasait la règle structurelle.

**On retire l'exigence plutôt que de l'assortir d'exceptions.** Nommer le menu dans un `:not()`
n'aurait fait que déplacer le piège au prochain calque ajouté là — c'est la leçon de la v4.55.3,
une version plus tôt. `header.bar` porte déjà `position:sticky; z-index:20`, donc elle **est** un
contexte d'empilement : un `::before` en `z-index:-1` s'y peint au-dessus du fond de la barre et
sous tout son contenu, **sans qu'aucun enfant ait à être positionné**. On **enfonce** la hachure
au lieu de **lever** ses frères ; l'un ne demande rien aux enfants, l'autre les contraint tous.

`#crisisBand` garde l'ancienne mécanique, et ce n'est pas une inconséquence : il est
`position:relative` **sans `z-index`**, donc pas un contexte d'empilement — un `z-index:-1` y
passerait sous son propre fond et la hachure disparaîtrait. Ses enfants sont tous statiques.

### « Avancé par … » nommait l'hôte pour les gestes de l'invité
La mention était un drapeau **global** qu'un seul site du fichier remettait à zéro : `cxEnter`,
l'entrée sur complication. **Aucun avancement ordinaire ne l'effaçait.** Posée une fois —
typiquement par le backlog rattrapé à la jointure, où toutes les navigations de l'hôte défilent
d'un coup — elle **suivait ensuite l'invité de carte en carte** et attribuait à « Hôte » les blocs
qu'il venait lui-même d'avancer.

Encore un demi-chemin : un effacement écrit d'un seul côté. Le remède n'est donc pas d'ajouter les
N sites manquants — c'est de **supprimer le besoin de s'en souvenir**. La mention porte désormais
le **numéro de visite** que l'avance distante a créé et ne s'affiche que sur celui-là ; le premier
passage minté localement en porte un autre, donc elle disparaît **par construction**.

Elle est posée **dans `shareApplyAnchored`**, seul point où une navigation distante devient la
position courante. `onEvents` le manquait dans un cas (le drain de la file par `rmResume` n'y
repasse pas) et le posait dans un autre où il ne fallait pas : une navigation **refusée** par le
mode lecteur nommait déjà son auteur alors que rien n'avait bougé. L'annonce au lecteur d'écran
garde, elle, une variable **locale au lot** — elle n'a ni la même durée de vie ni la même
condition que la mention affichée.

### Ce que le diagnostic a écarté en chemin
Deux hypothèses ont été **mesurées puis abandonnées** avant d'arriver à la bonne, et c'est ce qui
a évité de « corriger » du code sain : l'attribution est juste quand la liste des participants
est à jour (« avancé par Infirmier », vérifié), et il n'y a **aucun écho** — l'hôte ne repousse
pas sous son nom ce qu'il vient de recevoir. Le défaut n'était ni dans la résolution serveur de
l'acteur (le secret l'emporte sur l'identité, y compris quand les deux appareils sont connectés au
même compte) ni dans le rebasage du diff.

### Vérification
**294/294 contrôles partage** (+14, sur les deux moteurs), 756 tests × 2 moteurs, 14 harnais verts
sur Chromium **et** WebKit, 301 contrôles d'accessibilité, 112/112 doctrine.

Les deux défauts réintroduits en font tomber **sept** ; fichier restauré à l'octet. **Un témoin a
dû être refait** : la première version de la sonde d'attribution avançait par `next`, nul sur le
dernier bloc de la fiche d'exemple — l'avance locale n'avait donc jamais lieu et les deux contrôles
suivants mesuraient du vide. C'est le témoin lui-même qui l'a signalé. De même, la hachure est
mesurée par son **image de fond** et non par l'opacité : sur un en-tête sans placard le
pseudo-élément n'a pas de `content`, et `getComputedStyle` rend alors l'opacité par défaut `1` —
un témoin fondé sur l'opacité aurait été vert des deux côtés.

**Rien à rejouer côté serveur.**

## [4.55.4] — 2026-07-28
### L'invité sait qu'il est invité — et un bouton pressé répond enfin

Les deux derniers signalements du lot. Avec eux, les dix remontés à l'usage sont traités.

### Le placard de l'invité
Il lisait « ■ Mode crise » — **exactement ce que lit l'hôte** — alors que sa situation est autre :
il **suit** une session qu'il ne conduit pas et qui peut s'arrêter sans lui. Le quai le disait déjà
par un jeton de sept caractères ; le bandeau le dit maintenant en toutes lettres, à l'endroit le
plus lu de l'écran : « **▪ Vous suivez** », hachure **bleue**, l'en-tête relayant « ▪ Suivi » au
pixel où le titre passe dessous.

**Même mécanique que le placard d'exercice, au trait près** — `::before` en fondu, relais au
défilement, enfants en `z-index:1`. Rien de neuf à inventer, donc rien de neuf à casser. Et **coût
nul en hauteur**, mesuré : c'est la seule condition qui vaille dans une zone où la rangée de
commandes n'a que 2,1 px de marge à 320 px.

Registre **bleu**, jamais l'ambre ni le rouge : suivre la session d'un collègue n'est ni une alerte
ni une vigilance, c'est un état. Le mot le porte ; la hachure ne fait que le rendre reconnaissable
d'un coup d'œil.

**L'exercice garde la priorité**, et ce n'est pas négociable : *« ceci est une répétition »* prime
sur *« vous suivez »* — le premier protège d'une méprise clinique, le second est une information de
rôle que le quai porte en permanence de toute façon. Un contrôle l'encode.

### Répondre à un geste n'est pas interrompre
La règle 11 — *« en session de crise, aucune notification flottante »* — vise ce qui **arrive** :
une erreur de synchro, un conflit, une nouvelle de fond, quelque chose qui s'impose à quelqu'un qui
n'a rien demandé, au pire moment. Elle ne visait pas la **réponse** à un bouton qu'on vient de
presser.

Or la file les retenait tous : taper « silencieux ? », ou « Partager la session » sur une fiche en
brouillon, ne produisait **rien du tout** — et le message surgissait plus tard, au retour à
l'accueil, détaché de son geste, donc incompréhensible.

Le troisième argument de `toast()` marque une réponse directe. Il est **explicite**, et non déduit
d'une proximité temporelle avec un clic : une nouvelle de fond qui tomberait dans la seconde suivant
un tap serait alors affichée par accident — exactement ce que la règle interdit. Quatre sites
marqués, tous atteignables pendant un soin.

### Vérification
**280/280 contrôles partage** (+9, sur les deux moteurs), 756 tests × 2 moteurs, 14 harnais verts,
301 contrôles d'accessibilité sur les deux moteurs, 112/112 doctrine. Les deux défauts réintroduits
en font tomber quatre ; fichier restauré à l'octet. Le contrôle du placard mesure l'opacité du
`::before` — pas la classe : c'est la hachure qu'on veut voir, pas l'intention de la poser.

**Rien à rejouer côté serveur.** Les dix signalements d'usage de ce lot sont traités.

## [4.55.3] — 2026-07-28
### Trois rognages que personne ne mesurait

Les trois défauts d'affichage signalés à l'usage, tous reproduits au pixel avant correction.

### Le titre décalé : neuvième piège de cascade, premier par `:not()`
Sur écran étroit, une règle transforme toute fenêtre en feuille pleine largeur et lui pose **18 px
de rembourrage haut**. Or « Se repérer » et « Consulter » se donnent `padding:0` — leur barre de
titre est `sticky top:0` et doit affleurer le bord.

Elles perdaient, et pas par l'ordre : `.ai-modal:not(.pdf-modal):not(.dlg-confirm) .ai-card` vaut
**(0,3,0)**, parce que **`:not()` compte la spécificité de son argument** — contre (0,2,0) pour
`:is(.plan-modal,.ref-modal) .ai-card`. Résultat mesuré : 18 px de fond nu au-dessus du titre, et
**65 px sur un iPhone à encoche** où `env(safe-area-inset-top)` s'ajoute — bande qui restait
visible au défilement, la barre étant collante.

On exclut désormais la **classe** `.sheet-full` plutôt que les deux fenêtres nommément : la
prochaine feuille plein écran héritera de l'exclusion au lieu de rejouer le défaut.

### La croix qui sortait du cadre
**110 px hors du cadre à 320 px**, 70 à 360, 40 à 390, 7 à 430 — et seulement sur écran **tactile**,
où « silencieux ? » et le bouton son montent à 44 px de cible. `.rt-head` est une rangée flex sans
retour à la ligne et dont rien n'est compressible : son contenu exige 331 px pour 221 disponibles.

Remède = le patron déjà éprouvé de la carte-bilan (v4.29.2) : conteneur `relative`, croix **ancrée**
en haut à droite, et un `padding-right` qui lui réserve sa place à toutes les largeurs. Le reste
s'enroule dessous plutôt que de la pousser hors de l'écran — on ne tronque pas un libellé de
commande, on lui donne une seconde ligne.

### La ligne d'Échelle qui sortait du plan
Débordement dès **quatre options à 320 px**, cinq à 390, six à 430, et jusqu'à **280 px dehors à
huit** — le titre de la décision étant écrasé à 0 px de large bien avant. Les renvois abrégés
(`FIBRIL→2 ASYSTO→3 …`) sont en `flex:none` et `nowrap` : leur largeur croît avec le nombre de
branches, sans borne.

On **enroule** plutôt que de tronquer. Dans un plan, une branche cachée est une branche qu'on ne
saura pas prendre — c'est la différence avec le quai, où l'on abrège et où l'on annonce « +n » :
ici la place existe, verticalement.

### Les contrôles ont dû être refaits, et c'est le point
Six contrôles permanents dans `audit-doctrine.mjs` (112/112, sur les deux moteurs). **La première
version restait verte avec les trois défauts réintroduits** : elle mesurait la fiche d'exemple —
deux options, donc jamais de débordement — et un contexte non tactile, où les cibles ne gonflent
pas. Elle ne rencontrait pas le défaut, donc elle ne le couvrait pas.

La version retenue **construit le cas** : une décision à huit branches, un contexte `hasTouch`, et
la mesure prise contre le bord **intérieur** du cadre — un bouton qui touche la bordure est déjà
coupé. Réépreuve : les cinq défauts réintroduits à l'identique en font tomber **huit** ; fichier
restauré à l'octet.

756 tests × 2 moteurs, 14 harnais verts, 301 contrôles d'accessibilité, 271/271 partage.
**Rien à rejouer côté serveur.** Restent deux signalements : le bandeau d'en-tête de l'invité et les
notifications retenues jusqu'à l'accueil.

## [4.55.2] — 2026-07-28
### Le menu ne suivait pas l'état du partage — et « Prendre la main » n'était nulle part

Trois signalements d'usage, deux causes. La première explique pourquoi la passation semblait sans
effet : **le geste n'avait pas de porte.**

### Un menu construit au rendu, dans un dispositif qui interdit de rendre
Les rangées du menu ⋯ sont bâties **au rendu** et stockées telles quelles. Or la règle 3 interdit de
re-rendre sur évènement distant — c'est elle qui empêche qu'un écran bouge sous le doigt de
quelqu'un qui coche. Conséquence : « Partage en cours **(n)** » gardait le compte du moment où la
fiche avait été ouverte, et **« Prendre la main » ne paraissait jamais**, puisqu'une offre arrive
par le réseau.

On mémorise donc le **constructeur** des rangées, pas seulement son résultat, et on le rejoue quand
l'état du partage change. Le menu vit dans l'en-tête, hors de `main` : **pas une ligne de la
checklist ne bouge** — vérifié, le nœud témoin est le même objet avant et après, à 0 px.

Et la rangée elle-même était **au mauvais endroit** : posée dans le menu de l'hôte, où sa condition
`Share.mode === 'guest'` ne pouvait jamais être vraie. Elle n'existait donc nulle part. Elle vit
maintenant dans le menu de l'invité, le seul où elle ait un sens.

### Un lien mort qui laissait agir sans rien dire
Après « Couper », l'invité ne pouvait plus cocher — mais il pouvait encore **incrémenter un
compteur**. Le geste ne partait pas, et **rien ne le lui disait**. C'est mot pour mot le pire mode
de défaillance nommé au plan : *« un invité qui continue de cocher dans le vide en croyant
contribuer à une réanimation en cours »*.

La garde couvrait les gestes **réservés** ; il en manquait une pour le cas où le **lien est mort**,
qui n'a rien à voir avec le rôle. Toute mutation est désormais refusée et **annoncée** sur `#srLive`
— seul canal admis pendant un soin (règle 11 : ni modale, ni banderole).

**`detached` n'en fait pas partie, et c'est délibéré** : celui qui a poursuivi seul travaille sur
*sa* session. Lui refuser ses gestes reviendrait à lui retirer le repli hors dispositif qu'on vient
de lui donner (AC 120-64 §9.a). Un contrôle l'encode.

### Vérification
**271/271 contrôles partage** (+8, sur les deux moteurs), 756 tests × 2 moteurs, 14 harnais verts,
301 contrôles d'accessibilité, 94/94 doctrine. Les trois défauts réintroduits à l'identique en font
tomber trois ; fichier restauré à l'octet.

Deux sondes ont encore dû être corrigées avant de conclure : l'une cherchait un bouton de compteur
dans un panneau **replié** — elle ne mesurait rien et concluait que le geste était bloqué ; l'autre
lisait la zone d'annonce **sans la vider**, et y trouvait le message précédent. Même travers que
depuis le début de ce chantier : mesurer le mécanisme au lieu de la propriété.

**Rien à rejouer côté serveur.** Restent trois signalements : le bandeau d'en-tête de l'invité, les
trois défauts de mise en page, et les notifications retenues jusqu'à l'accueil.

## [4.55.1] — 2026-07-28
### CORRECTIF — les assertions ajoutées en v4.55.0 lisaient une table sous le rôle `anon`

`ERROR: 42501: permission denied for table shared_sessions`. Les trois vérifications que la v4.55.0
ajoutait au § 14.5 — « nommer ce qui doit passer plutôt que compter » — interrogent la table en
direct, alors que le bloc est encore sous le rôle **`anon`**, posé au § 14.3 et jamais rendu.

Correction : on reprend les droits le temps de la lecture, puis **on restitue le rôle exactement
comme on l'a trouvé** — les sections suivantes s'appuient dessus.

### Le troisième rejeu perdu, et le garde-fou qui ferme cette famille
C'est la troisième fois qu'une erreur SQL vous coûte un aller-retour : un `$$` mutilé (v4.44.1), une
variable non déclarée (v4.54.1), et maintenant un accès de table sous un rôle sans privilèges.
Toutes trois ont la même cause de fond : **`supabase/*.sql` n'est ni servi ni chargé par les
tests**, sa seule épreuve était le collage dans l'éditeur.

`check-sql.mjs` gagne un troisième contrôle statique. Il est **volontairement borné à `anon`** :
ce rôle n'a aucun privilège de table par construction — c'est tout l'objet du § 13 —, donc toute
lecture directe pendant qu'il est actif est une erreur **certaine**. Sous `authenticated`,
interroger une table est légitime, et c'est même ainsi qu'on prouve que la RLS filtre (le § 14.19
lit l'historique d'Alice sous Bob et attend zéro ligne). Une règle plus large aurait produit des
faux positifs **sur les tests mêmes qui font le travail** — un garde-fou qui crie sur du code juste
finit ignoré. Les appels de fonction ne comptent pas : `share_join`, `share_pull` et `share_push`
sont `security definer`, et c'est précisément leur raison d'être.

**Vérifié capable d'échouer** en réintroduisant le défaut vécu à l'identique : il nomme la table, la
ligne, et le remède. Fichier restauré à l'octet.

`schema.sql` de la v4.55.0 était correct et **n'a pas à être rejoué** ; **`rls-tests.sql` est à
rejouer**. 756 tests × 2 moteurs, 14 harnais verts, `npm run check` 6/6.

## [4.55.0] — 2026-07-28
### Le scribe conduit — j'avais mal lu ma propre source

Objection d'usage, et elle porte : le médecin partage **pour se libérer les mains** — faire des
gestes, téléphoner, parler à l'équipe. Si un infirmier demande au scribe « c'est quoi les étapes
d'après ? mets le minuteur en pause, il reprend un rythme », le scribe ne pouvait rien faire, et le
médecin devait reprendre son téléphone pour valider avant de repasser la main.

### Ce que la source dit vraiment
AC 120-71B §5.2.2.1 — « one crewmember reading the checklist and the second confirming and
responding » — décrit une répartition de **la parole**, pas un système de permissions. Et dans ce
modèle, **c'est celui qui lit qui fait avancer la liste** ; le lead est celui dont les mains sont
prises. J'avais transposé l'inverse.

Les autres sources convergent : la **SFAR** (« le lecteur : sa seule tâche est de lire et de
**guider** »), l'**ECAM** (le pilot monitoring actionne l'ECP, le pilot flying pilote), et surtout
**McEvoy 2014** — 99,5 % contre 70 % d'adhérence, la meilleure donnée du dossier — où **le lecteur
tenait l'unique appareil**. La conception précédente empêchait exactement la configuration la mieux
documentée.

Et le critère juste était **déjà écrit dans ce dépôt**, pour `mark_void` : « annuler CONSERVE,
décocher DÉTRUIT — ce n'est donc pas une action destructrice, et la règle qui réserve celles-ci au
lead ne s'y applique pas. » Naviguer est append-only ; arrêter un minuteur conserve son `elapsedMs`.
Rien ne les réservait.

### La nouvelle ligne
| Ouvert au scribe | Réservé |
|---|---|
| cocher · constater · écart · incrémenter · armer · repère | **décocher** — efface une information |
| **avancer · choisir une branche · terminer un bloc** | **remettre à zéro** — efface un décompte que personne ne restitue |
| **arrêter un minuteur** · entrer sur une complication | **terminer le partage** · dater le début du soin |

**L'objection d'ambiguïté** (§5.5, « qui fait quoi », qu'Airbus supprime par un ECP unique) reçoit
la réponse constante du projet : **on n'interdit pas, on annonce.** Une avance venue d'en face pose
une mention « avancé par ‹rôle› » sur la carte courante, à côté de « Vous êtes ici » — même
information, vue par l'autre angle. Elle s'efface au geste de navigation suivant.

### Le lecteur était une troisième copie, jamais recensée
Signalé aussi : « pourquoi l'invité peut passer de bloc en bloc en mode lecteur mais pas sur la
page ? ». C'était vrai — `data-rmnext` et `data-rmopt` sont les mêmes verbes que `data-ovnext` et
`data-ovopt` sous d'autres noms, et la liste ne les nommait pas. Ce n'était **pas** un défaut de
portée (la garde en capture atteint bien `#readerMode`, prouvé en injectant `data-plgo` sur un de
ses boutons) mais de **prédicat**.

Trois choses en sont sorties, indépendantes du redécoupage :

- **`data-rmok` écrivait `state.checked` en direct**, sans passer par le prédicat unique. La
  doctrine annonce **deux** copies du cœur de cochage ; le lecteur en était une **troisième**.
  Mesuré : un invité au lien **arrêté** cochait quand même depuis le lecteur alors que le même
  geste était refusé sur la page.
- **Huitième piège de cascade du projet, second par spécificité** : `#readerMode .rm-ok` porte un
  **id** (1,1,0) et l'emportait sur `body.share-scribe :is([data-rmnext])` (0,2,1). Le geste était
  bloqué, mais le bouton restait vert plein, 72 px, graisse 800 — il **invitait** à un geste refusé.
- **Une émission refusée laissait le miroir divergent en silence** : la base de diff avance *avant*
  l'émission, si bien qu'un genre refusé n'était jamais renvoyé, même après promotion. Le miroir se
  déclare désormais périmé et redemande tout.

### Deux correctifs d'usage
**L'intitulé du journal ne se propageait pas.** `shareDiff` ne comparait que l'annulation d'un
repère : **étiqueter après coup** — le geste normal, puisque « Noter l'heure » ne demande rien — ou
corriger l'heure n'émettait rien. En le réparant, un second défaut est apparu : la réception
**empilait** un repère déjà connu au lieu de le mettre à jour ; le correctif seul aurait doublé la
ligne. Un test encodait le défaut (son couple de comparaison changeait la référence *et*
l'annulation) — variable isolée.

**Couper celui qui tient la main la rend à l'hôte.** Après « donner la main » puis « couper », le
partage gardait un lead révoqué et un hôte resté scribe : plus personne pour conduire, l'état que
l'invariant 1 interdit (« jamais deux, **jamais zéro** »). Ce n'est pas bloquant — les gardes de
l'hôte sortent sur `mode !== 'guest'` — mais faire reposer un invariant affiché sur la porte de
sortie d'une garde, c'est le laisser dépendre d'un détail d'implémentation.

### Le garde-fou qui manquait
`SHARE_KINDS_ANY`/`_LEAD` et `share_kind_allowed` sont **la même règle en deux langages**. Elles ont
divergé : le redécoupage a été porté des deux côtés, mais l'assertion qui l'éprouve ne l'a pas été —
et le défaut n'est apparu qu'au collage dans l'éditeur SQL. Une divergence est **silencieuse et
asymétrique** : client plus permissif, un geste part et le serveur le jette sans que l'auteur le
sache ; serveur plus strict, un geste légitime est refusé sans raison lisible.

`check-sql.mjs` compare désormais les deux listes à chaque commit. **Vérifié capable d'échouer** en
reproduisant la divergence exacte de cette version (serveur redécoupé, client en arrière) : il nomme
les quatre genres des deux côtés ; fichier restauré à l'octet.

### Vérification
756 tests × 2 moteurs (+9), **263/263 contrôles partage** (+13, sur les deux moteurs), 14 harnais
verts, 301 contrôles d'accessibilité, 94/94 doctrine. Quatre contrôles du harnais encodaient
l'ancienne ligne : retournés plutôt que supprimés, ils affirment la nouvelle et disent pourquoi.
Quatre sondes ont dû être corrigées avant de rien conclure — l'une relevait les boutons **avant**
d'ouvrir leur panneau, une autre cochait « tant que Continuer n'existe pas » alors que le bouton est
rendu d'emblée : elle mesurait la règle d'avancement, pas le bridage.

**`supabase/schema.sql` est à rejouer** (`share_kind_allowed` change), puis `rls-tests.sql`.

## [4.54.2] — 2026-07-28
### CORRECTIF — l'historique synchronisé de la v4.54.0 ne synchronisait rien

Signalé à l'usage, et exact sur les trois points : la bascule ne suivait pas d'un appareil à
l'autre, les sessions antérieures à l'activation ne montaient pas, celles terminées après non plus.
**La table existait, les politiques RLS étaient vertes, la bascule s'allumait — et pas une ligne ne
partait.** Une fonctionnalité entièrement livrée, entièrement inerte.

### Une cause et demie
`_pushTable` ne pousse que les objets portant `dirty`, et **aucun site n'en posait jamais sur une
session**. Explique les deux symptômes de fond. Le troisième — la bascule qui ne suit pas — venait
d'un oubli distinct : le réglage n'entrait pas dans les préférences synchronisées, alors que le
vocabulaire personnel ajouté à la même version, lui, y entrait.

Le marquage vit désormais au **point d'étranglement de l'écriture** (`_putSessionSafe`), comme
l'émission du partage vit dans `persistLive` : toute mutation ajoutée demain sera couverte sans
qu'on y pense. La pierre tombale de la suppression y passe aussi — elle posait ses champs à la
main, ce qui rendait fausse, dès la ligne où elle était écrite, la doctrine « ici, et nulle part
ailleurs ».

### Deux pièges que la contre-expertise a trouvés, et qui auraient annulé le correctif
**`updatedAt` doit être posé en même temps que `dirty`.** Une session n'en portait pas — seulement
`savedAt`, qui ne bouge plus après l'archivage. Posé seul, `dirty` aurait fait gagner
**inconditionnellement** la copie distante à la résolution du dernier écrivain (`savedAt > 0`,
toujours vrai) — et **effacé la trace do-verify de chaque session à la première synchro**. Le
correctif du push, seul, aurait donc détruit des données.

**Le rattrapage ne peut pas se garder sur une transition.** Qui a activé l'option en v4.54.0 —
quand elle ne poussait rien — a déjà la clé à « 1 » : il ne reverra **jamais** le passage
éteint→allumé. Un rattrapage gardé par cette transition aurait donc raté **exactement les personnes
qui ont signalé le défaut**. La garde est une clé durable, et un réveil de synchro suit le
balayage : quand l'option est apprise par le pull des préférences, la poussée de la même passe est
déjà sortie par son garde d'entrée.

### Vérification
Nouveau harnais **`scripts/audit-historique.mjs`** — quatorzième —, **16/16 sur les deux moteurs**.
Il mesure ce qui **partirait** (transport bouchonné) plutôt que ce que le code déclare : rien sans
l'option, l'existant rattrapé, une session terminée après qui part, la trace do-verify qui reste et
dont l'absence est dite, une session **vive** qui ne part jamais, le réglage qui voyage et qu'une
préférence distante éteint — et le cas « déjà activé en v4.54.0 », qui a son propre contrôle.

**Vérifié capable d'échouer** : les trois défauts réintroduits à l'identique en font tomber six,
fichier restauré à l'octet. Une sonde a dû être corrigée en route — elle avait perdu son bouchon de
transport et accusait l'application de son propre oubli. 747 tests × 2 moteurs, 14 harnais verts,
301 contrôles d'accessibilité, 250/250 partage. **Rien à rejouer côté serveur.**

## [4.54.1] — 2026-07-28
### CORRECTIF — `rls-tests.sql` de la v4.54.0 ne s'exécutait pas, et rien ne pouvait le dire

Signalé au rejeu : `ERROR: 42703: column "v_share" does not exist`. Les trois sections ajoutées en
v4.54.0 (§ 14.15 à 14.17) employaient une variable qui n'existe pas dans le bloc — les conventions
de nommage du fichier n'avaient pas été relues avant d'y écrire.

**Deuxième rejeu perdu par la même famille de faute** (après le `$$` mutilé de la v4.44.1), et pour
la même raison de fond : `supabase/*.sql` n'est ni servi, ni chargé par les tests — sa seule épreuve
est le **collage dans l'éditeur SQL**, donc sur une instance réelle. Pire, PostgreSQL ne signale une
variable inconnue qu'à l'**exécution de la ligne fautive** : un test placé en fin de bloc casse
après trois minutes de travail réussi, et laisse croire que le reste est en cause.

### Les sections sont désormais AUTONOMES
Elles ouvrent leur propre partage et font rejoindre leur propre participant, au lieu de s'appuyer
sur l'état laissé par les tests précédents. Une assertion qui dépend de ce qu'un test antérieur a
bien voulu laisser derrière lui casse au premier réordonnancement — et c'est exactement ce qui
vient d'arriver. Un préalable explicite y a été ajouté : le § 14.12 remplit le quota de partages
vivants d'Alice, il faut donc les expirer avant d'en ouvrir un neuf, sinon l'ouverture échouerait
**pour une raison qui n'a rien à voir avec ce qu'on mesure**.

Deux assertions s'y ajoutent, qui manquaient : § 14.18 (la passation s'annonce des deux côtés) et
§ 14.19 (l'historique de sessions ne se prête pas — Bob ne lit ni n'écrit celui d'Alice).

### Le garde-fou qui aurait attrapé cela
`check-sql.mjs` collecte les variables **déclarées** d'un bloc `do $$ … declare … begin`, collecte
celles qui y sont **employées**, et compare. Statique, donc instantané, donc joué à chaque commit —
là où l'erreur coûtait jusqu'ici un aller-retour complet sur une instance de production.

**Vérifié capable d'échouer** en réintroduisant le défaut vécu à l'identique (`v_share`) : le
contrôle le nomme et donne sa ligne ; fichier restauré à l'octet. Il ne prétend pas remplacer un
analyseur plpgsql — il attrape la faute qui a été commise, ce qui est le seul critère qui vaille.

`schema.sql` de la v4.54.0 était correct et n'a pas à être rejoué ; **`rls-tests.sql` est à
rejouer**. 747 tests × 2 moteurs, 13 harnais verts.

## [4.54.0] — 2026-07-28
### La main se passe, l'historique suit le compte, et le serveur cesse de faire confiance au client

Lot 6 du chantier, la passation de la main, et les trois durcissements serveur annoncés en v4.53.1 —
un seul rejeu de schéma pour l'ensemble.

### La passation de la main
Le scribe ne conduit pas : il ne navigue pas, n'arrête pas un minuteur, ne termine pas. C'est la
forme canonique du travail à deux (AC 120-71B §5.2.2.1) — mais **sans passation, quelqu'un qui a
besoin de conduire n'a aucun recours**, et l'asymétrie devient une impasse. Le genre `handoff`
existait dans le vocabulaire depuis la v4.46.0 ; rien ne l'émettait, aucune surface ne l'offrait.

Trois temps, comme l'exige AC 61-115 « Positive Exchange of Flight Controls » : l'hôte **propose**,
l'autre **prend**, et le changement de rôle vaut confirmation. **Un `handoff` reçu n'accorde rien à
personne : il affiche** (invariant 2 — aucun écran ne change de capacité sans un geste effectué sur
cet écran). Le rôle lui-même ne vient **jamais** d'un évènement, toujours de la lecture suivante :
un rôle qu'un évènement suffirait à changer serait un rôle que n'importe qui s'accorderait.

`handoff` passe donc **aux deux rôles**, client et serveur. Ce n'est pas un relâchement : il ne
change aucun état, et la frontière de sécurité est l'écriture du rôle — un `UPDATE` que la RLS
réserve déjà au propriétaire du partage. Le réserver au lead aurait interdit à l'invité d'**accepter**,
c'est-à-dire d'accomplir le temps que la doctrine exige de lui.

**L'offre se dit dans le quai, le geste vit dans le menu** — doctrine de « Recommencer le parcours » :
une rangée qui apparaîtrait dans la colonne d'action ferait remonter le contenu clinique, sur
évènement distant. Jeton `offert`, sept caractères, position constante. Et `grantLead` **rétrograde
d'abord, promeut ensuite** : dans l'autre sens, une coupure réseau entre les deux écritures
laisserait **deux** leads ; ici le pire cas en laisse **zéro** — dégradé, mais jamais ambigu.

### L'historique de sessions suit le compte
La table lève un invariant écrit du projet — « les sessions vivent en local, jamais synchro » — dont
le **mode exercice tirait sa garantie de non-contamination clinique**. Une bascule qui inverse une
promesse doit dire ce qu'elle change : elle est **opt-in, défaut fermé**, dans la fenêtre Compte,
avec une confirmation qui énonce la portée. Par **utilisateur**, pas par appareil — l'activer ici et
la découvrir éteinte ailleurs serait la pire des surprises.

Ce qui remplace l'invariant :

- **Seules les sessions archivées montent.** Une session **vive** resynchronisée serait un second
  canal de partage — sans code, sans rôle, sans péremption, et sans aucun des garde-fous du premier.
- **L'exercice est ségrégé par une colonne**, plus par la localité : la propriété devient une donnée
  que l'on filtre et que le serveur voit.
- **La trace do-verify ne monte pas**, et **son absence est dite**. Un drapeau fait écrire au compte
  rendu consulté ailleurs : « son détail reste sur l'appareil qui l'a produite ». Une trace absente
  qui ne s'annonce pas se lit *« aucune vérification n'a été faite »* — l'exact contraire de ce que
  la seconde passe existe pour établir.
- **`data` accepte dès aujourd'hui `{v:2, enc:<blob>}`.** C'est la seule décision de forme qu'il
  fallait prendre maintenant : elle devient irréversible dès qu'il y a des données en place, et
  passer au chiffrement de bout en bout ne demandera donc aucune migration.

Suppression = **pierre tombale** dès que la synchro est active (sinon la session effacée revient au
pull suivant depuis l'appareil qui l'ignore), suppression franche sinon. Le tableau de bord compte
les sessions et leurs octets — l'exploitant ne doit pas être aveugle au poste que l'option fait
croître (leçon v4.49.0).

### Le serveur cesse de faire confiance au client
Trois durcissements, annoncés comme ouverts en v4.53.1 :

1. **Liste blanche des clés de payload.** Le serveur ne validait que le **type** et la **taille** —
   c'est de là que partaient les deux injections de la v4.53.1. Il ne garde désormais que seize clés
   nommées. **`label` n'y est pas, et c'est le point** : la promesse « aucun texte libre ne traverse
   le réseau » cesse de dépendre d'une discipline de client. Liste blanche, jamais noire.
2. **Le libellé d'un participant** perd tout métacaractère de balisage. On ne recopie pas en SQL la
   liste des neuf rôles (elle dériverait) : on retire ce qui n'a rien à faire dans un nom.
3. **La coupure mord au serveur.** `share_pull` renvoyait `status: revoked` **et le flux complet** —
   c'était l'application du coupé qui gelait son écran, donc un client modifié continuait de lire.
   Il ne reçoit plus ni évènements ni participants ; le **statut**, lui, reste renvoyé — il faut
   qu'il sache, sinon la coupure passerait pour une panne de réseau. Le § 3.1 du registre, qui
   signalait ce point comme « à durcir », est mis à jour.

### Vérification
747 tests × 2 moteurs (+8), **250/250 contrôles partage** (+18, sur les deux moteurs), 13 harnais
verts, 301 contrôles d'accessibilité sur les deux moteurs, 94/94 doctrine, `npm run check` vert.
Trois assertions RLS nouvelles (§ 14.15 à 14.17) couvrent les trois durcissements — dont une qui
pousse un `label` et vérifie qu'il **ne survit pas à l'insertion**. Un test qui encodait l'ancien
contrat (`handoff` réservé au lead) a été retourné plutôt que supprimé : il affirme désormais la
règle inverse et dit pourquoi.

**`supabase/schema.sql` est à rejouer**, puis `rls-tests.sql`.

## [4.53.1] — 2026-07-28
### SÉCURITÉ — un participant pouvait injecter du balisage dans la checklist des autres

Trouvé en cherchant à répondre à la question « un tiers malveillant peut-il faire voyager du
texte ? ». La réponse est pire que la question : **pas seulement du texte, du balisage**. Deux
injections d'attribut, reproduites avant correction, fermées ici. Aucune ne demande de compte : il
suffit d'avoir rejoint une session avec un client modifié — la console du navigateur suffit.

### Deux routes, et la barrière n'était que sur l'une
Un évènement distant atteint l'écran par **deux chemins distincts** :

- la **peinture** (`sharePaintLive`), en direct — elle normalisait déjà (`safeId`, `tkRefNorm`) ;
- le **pli** (`shareFold` → `buildRuntime` → rendu), qu'empruntent **tout invité qui rejoint** — il
  reçoit l'historique depuis le début — et **tout invité qui recharge**. Il recopiait **brut**.

Une barrière sur une branche et pas sur l'autre ne protège rien. C'est la même leçon que la v4.42.0
(deux copies du cœur de cochage qui avaient divergé), à un endroit qui touche la sécurité.

**Défaut A — l'identifiant d'un repère.** `payload.id` d'un `mark`, recopié tel quel par le pli,
puis interpolé **sans échappement** dans cinq attributs du journal. Le genre `mark` est ouvert au
scribe : n'importe quel participant pouvait donc poser un identifiant qui **sort de son attribut**
et ouvre une balise dans le journal de tous les autres.

**Défaut B — les numéros de visite.** Seuls `Array.isArray` et l'égalité des longueurs étaient
vérifiés ; les **éléments** de `navSeq` ne l'étaient pas. Or `navSeq[i]` fabrique la clé de cochage
écrite dans `data-ck`, et le régime de `nav` est « anchored » — donc appliqué **en direct, sans
rechargement**, sur l'écran de chacun, **dans la liste d'étapes elle-même**. C'est du code que
j'avais écrit trois versions plus tôt.

### Ce que la CSP faisait, et ce qu'elle ne faisait pas
La CSP porte les hashs SHA-256 des scripts inline : sur un navigateur à jour, `'unsafe-inline'` est
ignoré et un `onerror=` injecté **ne s'exécute pas**. Mais `style-src 'unsafe-inline'` est accordé,
lui — du balisage et du CSS arbitraires **dans la colonne d'action d'une réanimation** (masquer une
étape, en superposer une fausse avec une autre dose) suffisent à qualifier le défaut. On ne s'abrite
donc pas derrière la CSP : elle est le second rempart, pas le premier.

### Trois couches, et chacune vérifiée SEULE
1. **Assainir à l'entrée.** Le pli passe désormais par les mêmes fonctions que la peinture, cas par
   cas : identifiants par `safeId`, horodatages par une conversion numérique explicite, références
   par `tkRefNorm`. Les valeurs fautives ne sont pas **rejetées** mais **ramenées** à quelque chose
   d'inoffensif — un évènement perdu en pleine réanimation serait pire qu'un identifiant régénéré.
2. **Borner les formes.** Une clé de cochage vaut `visite:bloc:index` et rien d'autre — un jeu de
   caractères fermé la rend sûre **comme index d'objet** (règle 6, `__proto__` compris) **et comme
   valeur d'attribut**, d'un seul geste. `shareNavNorm` est la barrière **unique** du couple
   `nav`/`navSeq`, partagée par le pli et l'application ancrée.
3. **Échapper à la sortie.** Sept interpolations d'attribut reçoivent `esc()`. Un attribut
   s'échappe même quand l'entrée est assainie : les deux barrières couvrent des chemins différents.

**Les deux couches ont été éprouvées indépendamment** : en retirant l'assainissement d'entrée,
l'échappement de sortie bloque encore l'injection ; en retirant l'échappement, l'assainissement la
bloque aussi. C'est ce qui distingue une défense en profondeur d'un empilement de précautions.

### Vérification
Dix contrôles permanents dans `audit-partage.mjs` (242/242 sur les deux moteurs), **vérifiés
capables d'échouer** : les défauts réintroduits à l'identique en font tomber trois, fichier restauré
à l'octet. Ils mesurent la **sortie de balise**, jamais l'exécution — c'est la propriété qui compte,
l'exécution n'en est qu'une conséquence parmi d'autres. 738 tests × 2 moteurs, 13 harnais verts,
301 contrôles d'accessibilité, 94/94 doctrine. **Rien à rejouer côté serveur** — mais le serveur ne
valide toujours que le **type** et la **taille** d'un payload, jamais ses clés : c'est le client qui
doit se défendre, et c'est désormais le cas aux deux entrées.

## [4.53.0] — 2026-07-28
### Le partage survivait à la session qu'il reflétait — et la cadence supposait qu'un soin fait du bruit

Trois signalements d'usage, dont un qui n'a été trouvé qu'en cherchant à répondre à une question
sur la fréquence de rafraîchissement.

### Terminer la session ne coupait pas le partage
Signalé : *« la fenêtre hôte affiche toujours partage en cours »*. Vérifié — `endSession` ne touchait
pas au partage. Celui-ci **survivait à la session qu'il reflétait** : la fenêtre continuait
d'annoncer un partage vivant, l'invité sondait un miroir que plus rien n'alimentait, et le code
d'appariement restait valide jusqu'à son terme. Un partage sans session n'a pas d'objet.

L'arrêt est **annoncé** au serveur mais jamais **attendu** (règle 12) : fermer sa session ne doit
pas dépendre du réseau. Si l'annonce échoue, la ligne expire et sera purgée — c'est exactement à
cela que sert un relais transitoire. Cinq contrôles, **vérifiés capables d'échouer** (le correctif
retiré en fait tomber quatre, fichier restauré à l'octet).

### L'inactivité du support n'est pas l'inactivité du soin
En répondant à la question *« à quelle fréquence, sans websocket ? »*, la mesure a montré un trou.
La cadence se dégrade avec l'inactivité : 2 s dans les trente secondes d'un geste, 5 s ensuite,
**10 s au-delà de deux minutes**. Or pendant un cycle de compressions de deux minutes, **personne ne
touche l'écran, des deux côtés** — et le premier geste à la fin du cycle, c'est-à-dire au moment
précis où le rythme se réévalue, pouvait mettre jusqu'à 10 s à apparaître chez l'autre.

Plancher de 5 s tant qu'une crise est à l'écran. Le surcoût est de six requêtes vides par minute ;
le coût inverse était un miroir qui retarde au pire instant. `crisisOnScreen` sert de prédicat —
le même que le quai et la mise en attente des banderoles, pas un second critère qui divergerait.

Latences réelles, calculées sur les constantes du fichier (poussée débouncée à 250 ms, gigue ±20 %) :

| Situation | Période | Latence moyenne | Pire cas |
|---|---|---|---|
| Dans les 30 s d'un geste | 2 s | 1,25 s | 2,65 s |
| De 30 s à 2 min | 5 s | 2,75 s | 6,25 s |
| Au-delà de 2 min, **crise à l'écran** | 5 s | 2,75 s | 6,25 s |
| Au-delà de 2 min, hors crise | 10 s | 5,25 s | 12,25 s |

**Ce que la cadence ne retarde pas, et c'est l'essentiel** : les minuteurs voyagent avec une **ancre
absolue**, donc les deux appareils calculent la même valeur en continu **sans rien échanger** — un
cycle de deux minutes est exact des deux côtés même hors réseau, et le passage à « échu » ne dépend
d'aucun sondage.

### « Exporter » ne disait pas quoi
Signalé : dans le menu ⋯, *« exporter PDF et json, pas clair si on parle d'exporter la fiche ou une
session »*. Le doute portait précisément sur ce qui compte, dans une vue où une session tourne et où
« Compte-rendu » est à portée. Les libellés nomment désormais leur objet — « Exporter **l'aide**
(.json) », « Exporter **le protocole** en PDF » — et le sous-titre nomme l'autre chemin plutôt que
de laisser le chercher : pendant une session, « la session s'exporte par *Compte-rendu* ».

### Vérification
738 tests × 2 moteurs (+4), **232/232 contrôles partage** (+5, sur les deux moteurs), 13 harnais
verts, 301 contrôles d'accessibilité, 94/94 doctrine, `npm run check` vert. Un contrôle du harnais
qui visait un libellé exact (`Exporter (.json)`) a été élargi au groupe : il aurait échoué au moindre
renommage sans que rien ne soit cassé. **Rien à rejouer côté serveur.**

## [4.52.0] — 2026-07-28
### Le journal parle enfin des deux côtés — sans qu'un seul mot traverse le réseau

Lot 5 du chantier de partage. Un repère du journal voyageait comme `{identifiant, heure}` et rien
d'autre : chez l'invité, il s'affichait « Action 3 ». L'heure était juste — c'est ce qui compte
cliniquement — mais le mot manquait, et le compte rendu d'un même soin devenait difficile à
recouper.

### Une référence, jamais un mot
Un repère porte désormais une **référence**, et chaque appareil rend le libellé depuis **sa** copie
de la fiche. C'est ce qui tient la règle 15 sans condamner le journal au mutisme. Quatre sources,
cumulatives :

1. **La fiche elle-même** — minuteurs, compteurs, étapes, repères posologiques. Toute aide apporte
   son vocabulaire sans qu'on ait rien à déclarer, et il suit ses mises à jour.
2. **Un noyau universel livré** — ce qui se note dans toute intervention : renfort, régulation,
   départ de la base, arrivée sur place, bilan, transmission, relève, départ, arrivée à l'hôpital.
   **« Autre » n'y est pas, et ce n'est pas un oubli** : l'absence de référence *est* « autre », et
   une étiquette qui ne distingue rien n'apprend rien à qui relit.
3. **Le vocabulaire personnel, avec alias** — édité **à froid** dans la fenêtre Compte, synchronisé
   comme le thème. C'est là que vivent les abréviations qu'on se découvre à l'usage : « mru »
   trouve « Médecin régulateur ».
4. **Rien du tout**, et c'est le cas nominal. « Noter l'heure » reste **un tap** : l'heure est
   capturée, toujours, sans dépendre d'aucun vocabulaire. L'étiquetage est facultatif. Pire cas
   d'un vocabulaire incomplet : un repère non étiqueté côté partagé, et le mot exact **en local**
   chez celui qui l'a tapé.

**La résolution échoue proprement**, et c'est cette garantie qui autorise à faire voyager des
références : fiche d'une autre version, étape supprimée, étiquette effacée — le repère retombe sur
« Action n », **jamais sur un mot inventé**. Six contrôles l'encodent.

**On réordonne, on ne filtre jamais** — la règle des repères posologiques, appliquée telle quelle,
avec la même machinerie (troncature à partir de quatre caractères, table de synonymes). Un faux
positif coûte un rang ; un faux négatif coûte un mot au moment où on le cherche.

### Ce qui ne pouvait pas être une fenêtre
La règle 11 interdit les modales pendant un soin. Les propositions sont donc une rangée de chips
**sous** la ligne du journal — lequel vit en fin de rail, si bien que ce qui apparaît pousse vers le
bas et jamais vers le haut. Cibles 44 px, rien sous deux caractères saisis (tout ressemble à tout),
quatre propositions au plus.

Tant qu'aucune proposition n'est choisie, **le texte tapé reste strictement local** : mesuré, il
n'entre pas dans ce qui est émis. Choisir pose la référence et efface le libellé manuel — le mot
devient dérivé, donc identique sur les deux écrans.

**Une asymétrie est dite plutôt que tue** : une étiquette *personnelle* se résout sur les appareils
du même compte, pas chez un collègue qui ne l'a pas. Pendant un partage, elle est donc marquée
« · vous seul ». La taire aurait laissé croire à un mot partagé.

### La règle 15 vaut aussi à la réception
La réception d'un repère distant lisait un `label` venu du réseau. Inoffensif entre deux clients de
cette version — aucun émetteur n'en met — mais c'était une **porte** : un client modifié aurait
affiché un mot arbitraire sur l'écran d'en face. La lecture est supprimée ; le libellé se dérive de
la référence, et de rien d'autre. Le contrôle du harnais qui vérifiait l'inverse — il **encodait le
trou** — a été retourné : il pousse maintenant un `label` hostile et vérifie qu'il n'apparaît nulle
part.

### Un défaut d'accessibilité sur iOS, trouvé en jouant le harnais sur le bon moteur
Le `<select>` de rôle de l'écran d'entrée mesurait **23 px de haut sur WebKit** contre 44 sur Blink
— sous le plancher de cible, sur le seul écran qu'un invité sans compte verra jamais, et sur la
cible principale déclarée du projet. Invisible tant que le harnais d'accessibilité ne tournait que
sur Chromium : c'est la leçon de la v4.45.0, redite. Hauteur explicite et chevron dessiné
(`appearance:none` — sans lui, imposer une hauteur à un select natif iOS ne déplace pas son texte).

### Vérification
734 tests × 2 moteurs (+28), **227/227 contrôles partage** (+13, sur les deux moteurs), 13 harnais
verts, 301 contrôles d'accessibilité **sur les deux moteurs**, 94/94 doctrine, `npm run check` vert.
Le contrôle « le texte tapé n'est pas émis » est vérifié **capable d'échouer** (le libellé remis
dans l'instantané le fait tomber, fichier restauré à l'octet). Le commentaire de modèle du fichier,
qui décrivait un repère par trois clés depuis l'origine, en décrit désormais les huit — et dit
lesquelles voyagent. **Rien à rejouer côté serveur.**

## [4.51.0] — 2026-07-27
### Le miroir se figeait au premier « Continuer » de l'hôte

Annoncé en fin de v4.50.0, corrigé ici. Deux défauts, et le second n'était visible que parce que le
premier le masquait.

### La file était remplie et jamais vidée
`SHARE_APPLY` distingue trois régimes et les motive : `live` (chirurgie pure dans la checklist),
`anchored` (« reconstruit le journal, **donc** ancré et annoncé »), `deferred` (attend un geste
local). **Une seule ligne rangeait `anchored` et `deferred` dans la même file** — laquelle n'était
drainée nulle part.

Conséquence, mesurée : après une navigation distante, `Runtime.nav` ne contenait pas le bloc cible ;
au grep, aucun site de drainage. **L'invité voyait les coches du bloc courant, et plus rien
ensuite** — le contraire d'un miroir, et la fonction même pour laquelle le partage existe. C'est la
quatrième moitié de chemin de ce chantier, après `canWrite()` sans appelant, l'annexe d'un détaché
que personne ne lisait, et `fold.exercise` sans émetteur.

Une navigation distante s'applique désormais **ancrée** : on mesure la position d'un repère, on
re-rend, on compense le résidu — dérive **0 px** mesurée. Et on ne défile **pas** vers la nouvelle
carte : le geste n'est pas le sien. C'est la différence exacte avec `ovAdvanceRender`, qui défile
parce que c'est l'utilisateur qui vient d'appuyer sur « Continuer ».

Deux pièges rencontrés, tous deux attrapés par la sonde et non par la relecture : `state.nav` est un
**alias** du tableau de `Runtime` — lui affecter un tableau neuf casse l'alias en silence, et
l'application se met à lire deux navigations différentes selon l'endroit ; et `Runtime.seq` doit
être relevé au maximum des numéros reçus, faute de quoi une visite locale ultérieure réutiliserait
un numéro déjà pris — **deux passages partageraient alors leurs clés de cochage**.

### Le mode lecteur inverse la règle, et il le dit
Sa clé d'étape est calculée **au clic** depuis `state.nav`, jamais depuis le DOM peint : une
navigation distante arrivant entre le `pointerdown` et le `click` ferait cocher **la mauvaise
étape**, et le compte rendu l'imprimerait comme réalisée. Tant que le lecteur est ouvert, une
navigation distante est donc **refusée** — et **annoncée sur place** : « Le soignant a avancé —
reprendre à sa position », registre INFORMATION, levée par un geste local. Ne pas suivre en silence
était le pire des deux mondes : l'autre a avancé, et celui qui lit à voix haute l'ignore.

### Un rechargement ne perd plus la session
Un onglet mobile meurt tout seul — iOS recycle les onglets en arrière-plan — et l'invité perdait sa
participation **sans retour** : rien n'était persisté, et son code d'appariement est consommé, donc
il ne pouvait pas rejoindre. C'était l'invariant « l'invité ne garde rien » appliqué au-delà de ce
qu'il protège.

Un **billet** est écrit dans le `sessionStorage` : l'identifiant du partage et le secret,
**aucune donnée clinique** — vérifié par un contrôle qui cherche le titre de la fiche dans le
billet. Sa portée est *cet onglet, cette navigation* : effacé à la fermeture, jamais partagé, hors
IndexedDB et hors `localStorage`. L'étanchéité est tenue là où elle compte — rien de **durable** sur
le téléphone d'un tiers. Il survit à `freeze` (le lien meurt, l'écran reste) et meurt avec `stop`
(l'écran est quitté) ; un serveur qui refuse l'efface plutôt que de le laisser traîner.

Côté serveur, `share_pull` renvoie la fiche **uniquement sur une reprise complète** (`p_since = 0`,
et jamais à l'hôte) : les sondages ordinaires passent toutes les deux à dix secondes et n'ont aucun
besoin d'un instantané de plusieurs dizaines de kilo-octets. Aucune donnée nouvelle ne sort — c'est
le même instantané, filtré par la même liste blanche, que la jointure avait déjà remis.

### Vérification
706 tests × 2 moteurs, **214/214 contrôles partage** (+22, sur les deux moteurs), 13 harnais verts,
9/9 QR, 301 contrôles d'accessibilité, 94/94 doctrine, `npm run check` vert. Les dix contrôles du
miroir ont été **vérifiés capables d'échouer** : le défaut réintroduit en fait tomber cinq, fichier
restauré à l'octet. Le registre RGPD (§ 3.1) et `AGENTS.md` sont mis à jour dans le même commit —
le billet est une exception à un invariant écrit, elle se documente là où l'invariant est écrit.

**`supabase/schema.sql` est à rejouer** (`share_pull` seul est modifié), puis `rls-tests.sql`.

## [4.50.0] — 2026-07-27
### La conformité écrite noir sur blanc — et le placard d'exercice qui ne traversait pas le partage

Lot 7 du chantier de partage : la documentation opposable. Traité **avant** les lots 5 et 6, et pas
par ordre de numéro — c'est le seul reliquat qui engage l'établissement. Trois signalements d'usage
sont corrigés au passage, et un défaut a été trouvé **en écrivant la documentation**, ce qui est
exactement à quoi elle sert.

### Le placard d'exercice ne traversait pas
`openSharedFiche` lisait `fold.exercise` — **et aucun émetteur ne l'a jamais posé**. Moitié de
chemin écrite, la ligne se lisant comme si elle marchait : troisième occurrence dans ce chantier,
après `canWrite()` sans appelant et l'annexe d'un détaché que personne ne lisait.

Mesuré, témoin à l'appui : hôte en répétition = bandeau hachuré, en-tête hachuré, pilule
« ▲ Exercice », chrono « ▲ Exercice » ; **invité = « ■ Crise » et « ● Session »**. Un renfort qui
rejoint une répétition en la croyant réelle est précisément ce que le placard TRAINING existe pour
empêcher — l'annonciation **est** la raison d'être du mode exercice (v4.27.0), le reste étant
identique par construction.

Le drapeau voyage désormais sur `session_start`, et ce véhicule n'est pas un pis-aller : le drapeau
est posé par `startExercise`, qui passe par `freshRuntime` — il ne peut donc changer **qu'avec** le
démarrage. Aucun genre nouveau, donc **aucun schéma à rejouer** ; et `session_start` étant déjà
réservé au lead, un scribe ne peut pas déguiser une session réelle en répétition. Cinq tests, dont
**trois tombent** quand on réintroduit le défaut (fichier restauré à l'octet). « Quitter
l'exercice… » disparaît chez l'invité : le bouton appellerait `quitExercise` sur **son** Runtime
sans rien changer chez l'hôte — un contrôle qui ment sur sa portée.

### Trois signalements d'usage
**La fenêtre d'entrée n'avait pas de sortie.** Elle a été conçue comme le *remplacement* de
l'application sur un appareil vierge, où il n'y a rien derrière et où une croix ne mènerait nulle
part. Mais on y arrive aussi **depuis l'accueil**, en tapant le code dans la recherche : une
application tourne alors derrière, et un code mal recopié enfermait l'utilisateur. Croix, Échap et
retour système — les trois par le même chemin, comme le veut la doctrine des fenêtres —, affichés
**uniquement** s'il y a un « derrière ».

**L'hôte dictait un code déjà mort.** `share_join` met `code_hash` et `join_open_until` à NULL : la
porte se referme **derrière celui qui entre**, avant l'échéance des 120 s. L'hôte, lui, gardait sa
copie et affichait le code *avec son décompte* — « ouvert encore 97 s » sur une porte fermée. C'est
la donnée périmée présentée comme vivante, danger n°2 du palmarès ECRI 2015, que la doctrine du quai
nomme déjà pour les minuteurs. Corrigé **sans toucher au schéma** : une jointure est la seule chose
qui consomme un code, donc l'apparition d'un participant *est* l'observation. Le code et son QR
disparaissent, la fenêtre dit « **Untel a rejoint — le code a servi** », et « Nouveau code » devient
l'action évidente. Bénéfice second, non cherché : l'hôte obtient enfin l'**accusé de réception**
d'appariement que l'échange en trois temps suppose (AC 61-115).

**Le mode lecteur ne suivait pas.** Il vit hors de `main`, que `sharePaintLive` est seul à peindre :
mesuré, coche distante appliquée à l'état et peinte dans le journal (témoin `done` posé), **lecteur
inchangé** — le binôme qui lit à voix haute annonçait « suivant : … » sur une étape déjà faite.
Il se repeint désormais **à position conservée** : `_rmSync` remet le curseur à zéro et ferait
sauter le lecteur au premier item non coché, ce qui serait un mouvement autonome sous ses yeux.
La première sonde écrite pour ce défaut mesurait le **chrono** du lecteur et le voyait donc changer
à chaque seconde : elle a été refaite avant toute conclusion.

### La conformité, sourcée ligne à ligne
`docs/deploiement-et-conformite.md` affirmait encore « **Sessions : locales à l'appareil** » — faux
depuis la v4.46.0 — et sous-évaluait la conservation. Nouveau **§ 3.1** qui énumère, avec le SQL en
regard : les **14 champs** de la liste blanche serveur (et ce qu'elle retire — images, documents,
et `localInfo`, pré-rempli des téléphones de renfort et de régulation) ; ce qu'un geste transmet
(une référence et une heure — le libellé d'un repère **reste sur l'appareil qui l'a écrit**) ; ce
qu'est l'identité d'un participant (un identifiant opaque tiré par le serveur, un rôle choisi dans
une liste fermée de neuf intitulés) ; et les durées **mesurées** : fenêtre d'admission 120 s, partage
3 h par défaut borné à 12 h, purge 30 min après expiration, en cascade, déclenchée **en tête de
chaque appel** faute de tâche planifiée sur un hébergement statique.

Deux précisions qu'une lecture rapide du schéma ne donne pas, et qu'un DPO doit avoir : le contrôle
d'accès des invités **ne repose pas sur la RLS** mais sur la possession d'un secret (trois fonctions
`security definer`, seule surface non authentifiée de l'installation) ; et « couper un participant »
retire **l'écriture**, pas la lecture — le serveur lui répond `revoked` et c'est **son application**
qui gèle son écran. La formulation affichée à l'hôte est exacte sur ce point et ne doit pas être
élargie ; le durcissement serveur est identifié.

Le **§ 2** passe le partage à la grille MDCG 2019-11 : il ne calcule rien, il **recopie** un état
d'un écran à l'autre — qualification « communiquer ». L'argument contraire est écrit **et** réfuté
(il prouve trop : il vaudrait pour un tableau blanc), et la ligne à ne pas franchir est nommée — le
jour où le partage **déduirait** quelque chose de l'état partagé, la qualification serait à rouvrir.
Précaution de vocabulaire conservée : ne jamais présenter le partage comme un outil de *supervision*.

`AGENTS.md` reçoit une section « partage de session » complète et une **règle 15** — miroir additif,
jamais une dépendance ; aucun texte libre sur le réseau. Ses compteurs périmés sont corrigés :
onze → **treize** harnais, ~12 250 → **~14 400** lignes, 20 → **21** fenêtres modales, 22 → **25**
surfaces auditées en accessibilité.

### Ce qui reste, et qui est dit ici plutôt que découvert plus tard
La file `_defer` est **remplie et jamais vidée** : tout ce qui est classé `anchored` (`nav`,
`flow_end`, `cx`) ou `deferred` (`verify`, `gap`) n'atteint jamais l'écran de l'invité — **le miroir
se fige dès que l'hôte change de bloc**. Mesuré (`Runtime.nav` ne contient pas le bloc cible après
une navigation distante) et confirmé au grep (aucun site de drainage). Le commentaire de
`SHARE_APPLY` décrit pourtant le bon comportement. Et un invité qui recharge sa page **perd tout** :
rien n'est persisté, le code est consommé, il ne peut pas revenir. Les deux sont la prochaine
version.

706 tests × 2 moteurs (+5), 13 harnais verts, **192/192 contrôles partage** (+8, sur les deux
moteurs), 9/9 QR, 301 contrôles d'accessibilité, 94/94 doctrine, `npm run check` vert. **Rien à
rejouer côté serveur.**

## [4.49.0] — 2026-07-27
### Le repli hors dispositif, le bridage du scribe, et le filtre de contenu qui n'existait qu'en JavaScript

Dernière version du chantier de partage. Elle apporte les deux fonctions qui manquaient — poursuivre
seul quand le lien tombe, et brider le scribe sans rien lui masquer — et referme côté SERVEUR ce que
seul le client protégeait.

### « Continuer seul » : la trace remonte, l'état non
Le serveur savait tout faire depuis la v4.46.0 — colonne `detached_at`, genre `detach` autorisé,
règle « un lot qui porte un detach ne porte que lui », assertions RLS — mais **aucun code client ne
l'appelait**, et l'annexe qu'un détaché peut remonter n'était lue par personne. Quatre murs, tous
tombés :

**Au détachement, la file était JETÉE.** Au moment précis où la bifurcation devient officielle, on
détruisait la seule chose qui devait encore remonter. Elle est désormais **convertie** : chaque
geste en attente devient un `offline_mark`, qui rejoint le journal de l'hôte en annexe. Un détaché
ne peut plus écrire d'ÉTAT — ses coches porteraient sur des passages que l'hôte a quittés — mais il
peut écrire des repères horodatés : une heure reste une heure.

**Un détaché cessait de sonder.** Ses annexes n'auraient donc jamais atteint l'hôte. Un cycle lent
reste armé tant que sa file n'est pas vide.

**Chez l'hôte, l'annexe entre au journal et NULLE PART ailleurs**, à sa place chronologique, inerte
(ni champ ni bouton — on ne corrige pas le relevé d'un autre), avec la mention « rapporté — poursuit
seul ». L'état ne fusionne jamais : après la bifurcation, les numéros de visite sont mintés
indépendamment des deux côtés, si bien que « la visite 6 » de l'un et celle de l'autre désignent
deux passages différents. Ce n'est pas un conflit arbitrable, c'est une collision d'espace de noms —
fusionner produirait un résultat non pas discutable mais **faux, et plausible**.

### Le scribe ajoute, il ne défait pas
Forme canonique du travail à deux (AC 120-71B §5.2.2.1), pas un compromis. Ouvert au scribe : cocher,
constater, signaler un écart, **incrémenter** un compteur, **armer** un minuteur, poser et annuler un
repère. Fermé : décocher, avancer, terminer, choisir une branche, sauter à un bloc, **arrêter** ou
remettre à zéro. La distinction n'est pas arbitraire — ajouter est additif et réversible par le
journal, remettre à zéro détruit un décompte que personne ne peut restituer.

**Jamais par masquage** : masquer ferait sauter le contenu clinique de 46 px (mesuré), et sur
évènement DISTANT si le rôle change — sous le doigt de quelqu'un qui n'a rien demandé. La boîte
reste, la géométrie est identique refus ou non (mesuré ≤ 1 px), et le refus s'annonce sur `#srLive`,
seul canal admis pendant un soin.

**Une seule liste de verbes**, consommée par le CSS et par une garde déléguée en phase de capture ;
un contrôle du harnais lit la liste **depuis le script** et vérifie que chaque élément rendu porte
l'apparence désactivée — c'est la faille de la v4.42.0 prise à la racine. Deux gestes dépendent de
leur DIRECTION et ne peuvent pas être bridés en CSS : le cochage (`data-ck` porte cocher *et*
décocher) et le minuteur (armer *ou* arrêter) ; ils sont gardés dans leurs handlers, et pour le
cochage par un prédicat **unique** appelé aux deux copies du cœur.

### Le serveur ne se fiait qu'au client
**La liste blanche des champs de fiche n'existait qu'en JavaScript.** Un appel REST direct la
traversait : `images` (jusqu'à 24 Mo de base64), `localInfo` (les téléphones de renfort et de
régulation), la liste des documents, `ownerId`, `libraryId` — tout pouvait partir. Le schéma avait
pourtant déjà tiré cette leçon pour la TAILLE (« le plafond vaut contre le client ») sans jamais
l'appliquer au CONTENU. C'est une liste **blanche**, pas noire : on ne garde que les quatorze champs
autorisés, une liste noire oubliant ce qu'on ajoutera demain. Les images de BLOC sont retirées
séparément, elles vivent à l'intérieur de `blocks`.

**`is_approved()` traitait un JWT anonyme comme un compte approuvé.** Un tel jeton porte un
`auth.uid()` non nul et n'a aucune ligne dans `user_status` : le `coalesce` retombait sur
`'approved'` — y compris pour ouvrir un partage, c'est-à-dire faire sortir du contenu clinique de
l'instance. La porte n'était fermée que parce que personne n'avait activé l'option au tableau de
bord ; elle l'est maintenant par le schéma.

**`share_admit` ouvrait deux boucles infinies.** Il ne vérifiait ni l'expiration ni le quota : sur un
partage expiré ou plein, il rendait un code NEUF que l'hôte dictait et que `share_join` refusait
aussitôt, sans que personne, des deux côtés, ne puisse comprendre — et il écrasait au passage un code
peut-être encore vivant. Le motif est désormais détaillé, parce que l'appelant est le propriétaire
authentifié : l'argument d'oracle ne vaut que face à un anonyme, et le schéma le promettait sans
l'appliquer nulle part.

S'ajoutent un **plafond de cinq partages vivants par propriétaire** (il n'en existait aucun, alors
qu'un compte coûte une adresse jetable), le bornage de `session_id` — seul champ texte libre non
contraint —, les **octets des partages dans le total de stockage** et leur affichage au tableau de
bord (le serveur les calculait, l'écran ne les montrait pas : l'exploitant était aveugle au seul
poste que le partage fait croître), et le genre **`session_start`** : l'heure du soin voyage,
réservée à celui qui conduit. Un renfort arrivé à 14 h 12 sur une réanimation débutée à 13 h 55 ne
date plus le début du soin à son arrivée.

### Quatre signalements d'usage, et ce qu'ils étaient vraiment
**Le code du partage ne grandissait pas.** Il a été agrandi trois fois sans le moindre effet à
l'écran : `.ai-card p` pèse (0,1,1) — une classe ET un type — et l'emportait sur `.sh-code` (0,1,0)
en le ramenant à 13 px, **quel que soit l'ordre de déclaration**. C'est le 7ᵉ incident de cascade du
projet et le premier par SPÉCIFICITÉ ; les six précédents tenaient à l'ordre. Toute la typographie
des deux fenêtres passe par des sélecteurs à `#id`, et un contrôle mesure désormais la taille
**rendue**, jamais la valeur écrite. Le code fait 40 px (34 sous 360).

**Le QR portait le code seul.** Une « correction » de la veille faisait retomber `localhost` sur le
code, ce qui privait de la fonctionnalité au moment même où on l'essaie : toute origine http(s)
donne à nouveau l'URL complète, et le **lien entier est écrit en clair** sous le QR, sélectionnable
d'un appui — c'est lui qu'on dicte ou qu'on envoie quand la caméra ne sert pas. Le harnais QR, lui,
ne décodait que la MATRICE : il capture maintenant l'**image réellement peinte** et la donne au
décodeur d'Apple, à quatre configurations dont le thème sombre.

**La confirmation d'arrêt s'affichait derrière la fenêtre** (z-index 55 contre 94) : invisible, avec
le focus piégé dedans. Portée à 95.

**Les deux fenêtres du partage étaient les plus étroites de l'application** (420 et 460 px) : elles
prennent `dlg-480`, la largeur standard partagée par cinq autres. Et sous 780 px, où l'app transforme
toute fenêtre en feuille pleine largeur, leur contenu — majoritairement centré — courait d'un bord à
l'autre : mesuré, carte 744 × 1133 px pour 643 px de contenu. Le CORPS est borné à 460 px ; le titre
et le ✕, eux, restent au bord de la feuille, **identiques au pixel à une fenêtre existante** (mesuré
contre `#catModal` à 390, 744 et 1280 px) — fermer une fenêtre est le geste le plus appris de
l'application, le déplacer pour une seule d'entre elles était une faute.

### Rejoindre se tape dans la recherche
La rangée était dans le dialogue « Créer » : rejoindre n'ajoute rien à la bibliothèque, et quelqu'un
à qui l'on dicte un code n'irait pas le chercher sous « + ». Une ligne permanente en tête d'accueil a
été essayée puis écartée — 44 px d'attention à chaque ouverture pour un geste rare, alors que la
doctrine ECAM réserve le permanent à ce qui sert la conduite en cours. **Le code se tape dans le
champ de recherche** : huit caractères d'un alphabet fermé sont reconnaissables sans ambiguïté, la
ligne s'AJOUTE aux résultats sans les remplacer, et l'accueil au repos est **identique au pixel**
(mesuré). Registre INFORMATION, bouton rempli : à l'instant où elle paraît, elle est la seule action
de l'écran.

### Vérification
701 tests × 2 moteurs (+4), 13 harnais verts, **184/184 contrôles partage** (+41, sur les deux
moteurs), 9/9 QR, 301 contrôles d'accessibilité, 94/94 doctrine, `npm run check` vert. Quatre
assertions RLS nouvelles (§14.11 à 14.14) couvrent la liste blanche serveur, le plafond de partages,
les deux refus de `share_admit` et la réserve de `session_start`. `supabase/schema.sql` et
`rls-tests.sql` ont été rejoués sur l'instance avec succès.

Trois contrôles écrits pendant ce chantier ont dû être **corrigés parce qu'ils mesuraient le
mécanisme et non la propriété** : « le mode d'application vaut `none` » là où il fallait vérifier que
l'annexe ne touche pas l'état, « `started` vaut faux » là où il fallait vérifier qu'aucun dossier
n'est créé, et « pas de lien en local » qui encodait une règle infirmée. C'est la même erreur que la
taille du code, sous une autre forme : vérifier ce qu'on a écrit plutôt que ce que ça produit.

## [4.48.0] — 2026-07-27
### Le partage fonctionne enfin de bout en bout — et le miroir de l'invité était en lecture seule

Cette version rend le partage RÉEL : l'hôte peut l'ouvrir, montrer un code, voir qui a rejoint,
couper quelqu'un, arrêter. Et surtout, les gestes voyagent — ce qui n'était pas le cas.

### Le défaut central, trouvé par contre-expertise dans le code de la version précédente
**Les coches de l'invité ne quittaient jamais son téléphone.** L'émission s'accroche à
`persistLive`, qui sort immédiatement si la session locale n'a pas démarré — or l'invité avait
`started=false` par construction, et **une trentaine de sites de mutation sont eux-mêmes gardés par
`if(Runtime.started)`**. Le miroir était donc en lecture seule, silencieusement. C'est mot pour mot
le pire mode de défaillance nommé au plan de ce chantier : *cocher dans le vide en croyant
contribuer à une réanimation en cours*.

Le correctif inverse la logique. Sa session EST vive — c'est celle de l'hôte, il la suit et il y
contribue — donc `started` vaut vrai chez lui. Ce qui lui est refusé n'est pas la session, c'est
l'**enregistrement**, et ce refus vit désormais là où il a un sens, dans `persistLive` : aucune
écriture dans son stockage, aucune entrée dans son historique. Le contrôle censé couvrir cela
mesurait le MÉCANISME (`started === false`) au lieu de la PROPRIÉTÉ ; il mesure maintenant
l'étanchéité réelle — zéro session archivée, zéro session vive, aucun dossier — **et** que ses
gestes partent bien sur le fil.

Trois défauts de la même famille, tous dans du code écrit la veille : `canWrite()` — le prédicat qui
doit retirer l'écriture à un invité coupé ou périmé — **n'avait aucun appelant**, alors que le
commentaire attenant promettait « un invité périmé ou coupé PERD VISIBLEMENT l'écriture » ; le
compte de participants du quai filtrait sur `revoked_at` quand le serveur envoie `revoked`, si bien
que l'hôte aurait lu « ⇄ 2 » avec un seul participant présent ; et l'acteur d'un repère se perdait à
la peinture, rendant tout compte rendu inattribuable.

### Émission par différence — un seul point d'accroche
Le recensement avait trouvé **soixante verbes de mutation** (41 attributs `data-*` et 19 contrôles à
`id`). Les instrumenter un par un garantissait l'oubli, et surtout l'oubli SILENCIEUX de toute
mutation ajoutée plus tard. On DIFFE donc l'état, en un seul endroit : ce qui est couvert par
l'enregistrement local l'est mécaniquement par le partage. `shareSnap` et `shareDiff` sont PURS,
donc testables sans navigateur, sans réseau et sans horloge — et le test qui compte est
l'**aller-retour** : émettre puis plier redonne l'état de départ (coches, compteurs, minuteurs,
navigation, repères, annulations, trace do-verify). L'ouverture d'un partage **verse l'état courant
dans le fil** : l'instantané transmis est la FICHE, jamais la session, donc un partage ouvert après
vingt coches aurait sinon laissé l'invité devant une fiche vierge, à jour et fausse.

### La fenêtre d'appariement de l'hôte
Ordre imposé par la mesure, pas par l'esthétique : titre de l'aide et **code** en haut (ce qui se
dicte à voix haute), QR ensuite et plafonné, participants, arrêt en pied. Elle **ne verrouille pas
le fond** (`sheet-live`) : toute `.ai-modal` fige le défilement derrière elle au pointeur grossier,
et celle-ci reste ouverte pendant toute la fenêtre d'admission — la checklist de crise de l'hôte
serait devenue indéfilable au moment où elle sert.

**Couper quelqu'un n'est jamais peint de façon optimiste** : la rangée affiche « coupure… » et
n'accepte « coupé » que lorsque le sondage le rapporte ; le harnais mesure les deux moments, y
compris le RETOUR EN ARRIÈRE quand la requête échoue — un bouton qui laisserait « coupé » affiché
après un échec dirait à l'hôte qu'il a retiré un accès qu'il n'a pas retiré. Et « Arrêter le
partage » ramène `expires_at` à maintenant : le code s'aligne sur la promesse de purge faite à
l'invité, au lieu qu'on affaiblisse la promesse.

### Quatre défauts signalés à l'usage, et ce qu'ils étaient vraiment
**Le QR n'était pas corrompu : il contenait une adresse injoignable.** Il encodait
`location.origin + …` — servi depuis un poste de développement, cela donne une adresse LOCALE, que
l'iPhone décode et ne peut pas ouvrir : « aucune donnée utilisable trouvée ». Désormais, si
l'adresse n'est pas joignable depuis un autre appareil (fichier local, origine nulle, `localhost`),
c'est le **code seul** qui est encodé — le téléphone l'affiche comme texte — et la fenêtre le dit.
Le harnais QR, lui, ne décodait que la MATRICE : il était **aveugle à tout ce qui se passe entre
l'encodeur et l'appareil photo** (génération du SVG, variables CSS, `shape-rendering`, taille en
`vw`, rendu sous-pixel). Il capture maintenant l'IMAGE RÉELLEMENT PEINTE et la donne au décodeur
d'Apple, à quatre configurations dont le thème sombre.

**La confirmation d'arrêt s'affichait DERRIÈRE la fenêtre** : `#confirmModal` héritait du z-index 55
des fenêtres ordinaires alors que l'appariement est à 94 — dialogue invisible, focus piégé dedans.
Porté à 95, au-dessus des deux fenêtres hautes et sous le flash d'alarme.

**L'écran d'entrée ne suivait pas la grammaire de l'app** : il n'utilisait pas `.ai-card`, donc ni
son `margin:auto` (le centrage vertical de toutes les fenêtres), ni son échelle typographique — à
760 px la carte restait collée en haut, au-dessus de 450 px de vide. Et en la recalant, le **6ᵉ
piège de cascade du projet** : `.join-card` et `.ai-card` ont la même spécificité, la
`max-width:720px` déclarée plus bas l'emportait et la carte s'étalait sur 700 px. Sélecteurs par
`#id` pour les deux fenêtres, comme la règle l'impose pour toute géométrie.

**L'écran de saisie du code était introuvable sans QR.** Il est joignable depuis le dialogue
« Créer », sous un filet et formulé comme une question (« Un collègue partage sa session ? — ⇄
Entrer un code ») : c'est le seul point d'entrée atteignable à TOUTES les largeurs, l'accueil n'ayant
ni menu ⋯ ni barre latérale sous 780 px. Et l'**adresse de jointure est écrite en clair sous le QR**
— c'est elle qu'on dicte quand le scan ne peut pas servir.

Le code passe à **40 px** (34 sous 360 px), le champ de saisie de l'invité à 26 px. Cela a fait
tomber un contrôle, et c'est lui qui avait tort : il exigeait « Arrêter le partage » visible sans
défiler à toutes les largeurs, alors qu'à 320×568 la carte fait 734 px — aucune mise en page
honnête ne tient dans 568. L'objection d'origine disait autre chose : ce bouton ne doit jamais se
retrouver DANS une liste qui grandit, et doit rester atteignable. C'est ce qui est mesuré.

### Le miroir de l'invité
Le bouton « Confirmé — démarrer la session » — contrôle plein, le plus visible de l'écran — était
rendu chez lui alors qu'il ne démarre rien : retiré. L'entrée se fait au BOUT du journal et non en
tête de fiche (mesuré : la première étape cochable tombait à y=827 pour un écran de 844, et y=910
pour 568 — hors champ aux deux largeurs) ; le titre reste lisible par le relais d'en-tête, comme
pour tout utilisateur qui défile. Une annonce sans pixel (`#srLive`, seul canal admis pendant un
soin) dit ce qu'il suit.

**Et il a enfin une porte de sortie.** `Share.stop()` n'avait AUCUN appelant : le seul geste
disponible changeait la vue en laissant le mode et le sondage armés, sans chemin de retour. Le menu
⋯ de l'invité porte « Quitter le partage… », et le départ est SILENCIEUX côté serveur —
`Share.stop()`, jamais `emit('detach')` : un `detach` DATE un « je poursuis seul » dans le compte
rendu de l'hôte, or quelqu'un qui ferme son écran n'a rien affirmé de tel. Le même menu perd les
rangées qui, chez lui, étaient fausses ou muettes (exercice, recommencer, modifier, versions,
dupliquer, exports).

**Une incohérence d'étanchéité fermée au passage** : `beforeprint` n'était gardé que par la vue. Un
invité qui faisait Partager → Imprimer obtenait la fiche ENTIÈRE, mise en page pour le papier —
pendant qu'on lui refusait l'export du compte rendu au nom de cette même étanchéité.

### La rangée « Partager la session » n'est plus jamais grisée
La contrainte reste réelle (sans session démarrée, la première action de l'invité déclencherait un
re-rendu complet sous le doigt de l'hôte), mais la faire porter par une rangée MORTE obligeait à
deviner l'ordre des gestes. Elle propose maintenant de démarrer, par un dialogue qui dit ce que cela
engage — chrono, minuteurs, journal, entrée à l'historique : une session ne commence pas par
surprise au détour d'un menu.

### Vérification
691 tests × 2 moteurs (+2), 13 harnais verts, **124/124 contrôles partage** (+69, sur les deux
moteurs), **9/9 QR** (dont 4 sur l'image peinte), 301 contrôles d'accessibilité, 94/94 doctrine,
`npm run check` vert. Les nouveaux contrôles ont chacun été vérifiés capables d'échouer.
`supabase/schema.sql` est INCHANGÉ dans cette version : rien à rejouer.

## [4.47.0] — 2026-07-27
### Le transport du partage, la moitié invité — et ce qu'une contre-expertise a trouvé dans le code existant

Suite du chantier ouvert en v4.46.0. Un collègue peut désormais **rejoindre** une session et la
suivre en miroir ; l'autre moitié — l'écran depuis lequel on ouvre le partage — reste à écrire, si
bien que **rien n'est encore actionnable de bout en bout**. Ce qui l'est, en revanche, ce sont les
défauts que la préparation a mis au jour dans du code qui existait déjà, et qui n'attendaient pas
le partage pour nuire.

### Trois mécanismes existants que le partage rendait dangereux
Deux relectures adverses ont mesuré les surfaces prévues dans le code réel, avant qu'aucune ne soit
écrite. Elles ont invalidé l'ordre de travail : trois corrections devaient précéder toute nouvelle
interface, faute de quoi elle se serait appuyée sur un budget de place faux et sur un indicateur
qui ment.

**Le quai sacrifiait l'ALARME pour garder un chevron.** Quand la place manquait, la boucle
d'ajustement retirait les segments un à un et n'essayait « sans chevron » qu'une fois arrivée à
ZÉRO segment : elle sacrifiait donc le segment ambre du minuteur **échu** — la seule persistance de
l'alarme une fois le bip passé, dans une zone qui ne quitte jamais l'écran — pour garder un glyphe
`aria-hidden` que son propre commentaire qualifiait de « purement décoratif ». Et à court de
solutions, elle **réécrivait un état qu'elle venait de mesurer comme débordant**. Ordre inversé (le
décoratif tombe d'abord, à chaque palier) et plancher explicite.

**La cause de la pénurie était ailleurs : l'ellipse des intitulés n'avait jamais fonctionné.**
`.seg-l` déclare `text-overflow:ellipsis` depuis l'origine et un commentaire l'attribuait à un
« min-width:0 du segment » — qui n'existait pas. Sans plancher explicite, `min-width:auto`
dimensionne le segment sur son contenu le plus large ; en colonne, la règle flex qui annule le
minimum automatique porte sur la HAUTEUR, jamais sur cette largeur. Mesuré : un intitulé de
21 caractères portait le segment à **346 px pour 320 de large**, la boucle voyait un débordement et
expulsait le segment. Plancher chiffré à **112 px** = la valeur réelle la plus large
(« 999:59:59 », 95 px) plus les rembourrages : en dessous, l'intitulé s'ellipse — un MOT se
tronque, c'est admis ; au-dessus, la valeur ne peut jamais être rognée — un NOMBRE ne se tronque
pas — et si la place manque vraiment, le débordement est RÉEL, donc la boucle retire un segment et
le « +n » l'annonce. Le quai ne peut plus déborder en silence à aucune largeur servie.

**Le mot « échu » n'existait pas dans le quai**, alors qu'`AGENTS.md` l'affirmait : `segOf`
n'écrivait que l'intitulé et la valeur, si bien qu'un minuteur échu se distinguait d'un minuteur
nominal par la SEULE teinte — dans la zone la plus critique de l'application. Il ne pouvait pas
être ajouté en clair (l'ellipse l'aurait mangé le premier, et le segment aurait grossi jusqu'à se
faire expulser) : patron déjà retenu pour les étapes signalées — **glyphe `△` en PRÉFIXE**, qui
survit à l'ellipse, plus l'étiquette au lecteur d'écran. Piège trouvé au passage : cette étiquette,
en `position:absolute` sans ancêtre positionné, **échappait au `overflow:hidden`** et se posait à
488 px sur un quai de 320 — elle gonflait `scrollWidth`, c'est-à-dire qu'elle MENTAIT à la boucle
qu'on venait de corriger.

**Le seuil de péremption était INFÉRIEUR à la cadence nominale.** 4 s en constante, alors que la
période de sondage passe à 5 s après 30 s sans action et à 10 s après deux minutes : avec un réseau
PARFAIT, l'écran de l'invité se serait déclaré « figé » environ une seconde sur cinq au repos et
**six secondes sur dix pendant un cycle de compressions de deux minutes** — c'est-à-dire dans le
cas d'usage phare. Un indicateur qui crie au loup les deux tiers du temps n'est plus lu quand la
panne est réelle. Le seuil est désormais solidaire de la cadence courante et signifie « deux cycles
manqués » (facteur 2,5 : la gigue étant de ±20 %, deux périodes consécutives atteignent 2,4 fois la
base). Un statut terminal cesse en outre de sonder — le sondage tournait indéfiniment contre un
partage mort.

**La fin du partage n'est pas la fin du soin.** Le critère « une crise est à l'écran » s'écrivait,
pour un invité, `status === 'active'` : à l'instant EXACT où l'hôte coupait, deux mécanismes se
rallumaient sur la checklist que le collègue tient encore en main — le déversement des snackbars
retenues pendant tout le soin (jusqu'à huit) et la ré-apparition de la méta de lecture, qui décale
le contenu sous son doigt. Le critère juste est la PRÉSENCE d'une fiche de crise, d'où deux sorties
distinctes : `freeze` (le lien meurt, l'écran survit) et `stop` (l'écran est quitté).

### Le quai de l'invité existe, et il dit qui tient la main
Il n'apparaissait que si une session avait démarré **localement** — or un invité qui suit n'a rien
démarré, c'est le principe même du miroir. Les deux informations que la doctrine veut permanentes
(AC 120-71B §6.4 : qui tient la checklist ne souffre aucune ambiguïté ; et si ce qu'on voit est
encore vrai) n'avaient donc **aucun conteneur**. Un prédicat unique — celui-là même qui gouverne
déjà la mise en attente des banderoles — et un jeu **fermé** de jetons dans le libellé du chrono :
`main` / `suit`, `⇄n`, `figé`, `coupé`, `fini`, `seul`.

Trois emplacements ont été mesurés et écartés. Un **segment `⇄` propre** déplace le segment
d'alarme de 45 à 57 px selon la largeur, à son apparition ET à sa disparition — donc sur ÉVÈNEMENT
DISTANT, ce que la constance positionnelle ECAM interdit ; la **rangée de commandes** n'a que 2,1 px
de marge à 320 px ; une 2ᵉ pilule sur le **bandeau** fait tomber le titre de fiche de 172 à 58 px.
Le libellé du chrono, lui, coûte zéro pixel de mise en page : le segment est déjà étiré par le flex.
**Le lien REMPLACE la main**, il ne s'y ajoute pas — ce n'est pas une économie de place : quand le
lien n'est plus nominal, le rôle et le compte de participants ne sont PLUS CONNUS, et les afficher
serait la donnée périmée présentée comme vivante. Le vert cesse alors d'affirmer (encre neutre,
jamais l'ambre, réservé au minuteur échu).

### L'invité ne paie plus rien avant d'avoir lu
Mesuré sur profil vierge : charger `index.html#j=CODE` déposait **3,17 Mo** (le cache applicatif et
les 1 773 Ko de pdf.js), créait une base IndexedDB, écrivait quatre clés `localStorage`,
enregistrait un service worker — et appelait `navigator.storage.persist()`, c'est-à-dire demandait
au navigateur de rendre ce dépôt **non évinçable** — le tout AVANT que le premier mot de la notice
d'information ait pu s'afficher. Une information préalable posée sur une collecte déjà faite
n'informe rien.

Le mode invité devient donc une **décision de démarrage**, pas une classe CSS. Trois cas : pas de
code → démarrage normal ; code sur appareil VIERGE → stockage en mémoire, aucun worker, aucune
persistance demandée, aucun ensemencement, et l'écran d'entrée **à la place** de l'application ;
code sur un appareil qui utilise déjà l'app → démarrage normal (lui refuser son worker ne
protégerait rien et casserait son hors-ligne), écran par-dessus — **sauf si une fiche de crise est
à l'écran**, auquel cas le code est GARÉ et annoncé par le bandeau système, qui est déjà le canal
« information persistante, accueil seulement » (règle 11). Le fragment est retiré de l'historique
immédiatement. `ensureStarted` refuse de démarrer chez un invité : c'est le point exact où
l'étanchéité se joue — sans cette garde, sa première coche créerait un enregistrement de session
sur un téléphone emprunté. `launchQueue` est enfin consommé (le manifeste le déclarait depuis
v4.43.0 ; un lien entrant sur PWA installée était silencieusement perdu).

### Un écran d'entrée, et un refus qui ne prescrit pas l'impossible
L'écran porte l'information de l'article 13 — qui est responsable, ce qui est enregistré, pourquoi,
où, combien de temps, qui d'autre le voit — et il est audité en accessibilité dans les deux thèmes
à 320 px, la largeur la plus contrainte servie.

Le message de refus a été réécrit après mesure, et les trois formulations précédentes étaient
fautives. **« Vérifiez les 8 caractères » était du texte mort** : le contrôle local a déjà exigé
exactement huit caractères pris dans l'alphabet, deux lignes plus haut. **« Demandez de rouvrir
l'accès » est faux ou nuisible dans cinq causes de refus sur sept, dont deux boucles infinies** —
`share_admit` ne vérifie NI l'expiration NI le quota : il rend un code neuf que `share_join`
refusera encore, sans que personne ne comprenne pourquoi ; et sur une simple faute de frappe, il
TUE un code peut-être encore vivant. On nomme donc le RÉSULTAT (« un nouveau code »), jamais le
geste : l'hôte seul voit sa porte, et c'est lui qui décide. **Chiffrer la fenêtre et le nombre de
participants aurait été FAUX** — et l'argument n'est pas l'oracle, une chaîne statique ne portant
aucun état : `max_guests` est une COLONNE PAR PARTAGE (1-8, défaut 3) et la fenêtre vaut 120 s à
l'ouverture mais 15 à 600 s à chaque réadmission ; le client ne reçoit ni l'une ni l'autre. D'où
une règle de tri, écrite au-dessus des constantes : un chiffre n'entre dans un message que s'il est
détenu par le client, identique pour tout partage du déploiement, et capable de changer ce que le
lecteur fait ensuite. « 8 caractères » passe les trois ; « 2 minutes » et « 3 » échouent aux trois.

Trois rédactions, choisies sur la **provenance locale** du code — jamais sur la réponse du serveur,
identique dans les trois cas : code recopié à la main, code venu d'un QR (qu'on ne peut pas mal
recopier), et deuxième soumission du même code, qui coupe la boucle du re-tap puisque le champ
conserve sa valeur après échec. Le harnais vérifie que le serveur bouchonné rend la même chose et
que trois textes différents en sortent : un message qui varierait avec la réponse du serveur serait
un oracle.

Enfin, la géométrie : la rédaction précédente faisait **7 lignes et 145 px**, et à 320×568 le
bouton « Rejoindre » n'était plus visible que sur **23 px de ses 48** — sous le plancher de la
règle 9, et 0 px sur un écran de 480. Le défaut n'apparaissait qu'à la largeur la plus contrainte,
et aucun harnais ne regardait cet écran. Il en existe un désormais, et il échoue sur l'ancienne
rédaction.

### Deux questions tranchées, mesures à l'appui
**Le titre de l'aide sur l'écran d'entrée** : quatre chemins instruits, deux refusés. Une fonction
`share_peek(code)` serait un ORACLE par construction — elle sépare « titre » et « refusé » sans
consommer le code ni prendre de place, là où `share_join` fait les deux, et il n'existe aucune
limitation de débit sur la jointure. Le titre dans le QR rendrait **une photo de l'écran prise de
loin porteuse d'un diagnostic permanent**, là où elle ne porte aujourd'hui qu'un secret de 40 bits
mort en dix minutes au plus. Le titre est de toute façon **déjà peint dans la première image du
miroir** (`#crisisBand`, mesuré visible sans défiler à 320×568 comme à 390×844) : un écran de
confirmation intermédiaire coûterait un tap pour zéro information, et il est inécrivable tel quel —
au retour de `share_join` la liste des participants est vide et l'hôte s'appelle littéralement
« Hôte ». Il ira donc à côté du code sur l'écran de l'hôte.

**Un utilisateur sans compte peut-il OUVRIR un partage ?** Non, et l'arbitrage a été refait sur ses
vrais mérites — deux des trois arguments spontanés ne tiennent pas. « La surface d'abus l'interdit »
est faux comme argument discriminant : `require_approval` valant `false` par défaut, un compte coûte
une adresse jetable et un OTP, et `share_open` n'a de toute façon **aucun plafond par
propriétaire** — les 500 Mo en 40 secondes sont atteignables aujourd'hui, avec un compte.
« Aucun plafond ne peut exister sans `auth.uid()` » est faux aussi : c'est vrai d'un plafond PAR
APPELANT, hors sujet pour un plafond GLOBAL. Ce qui tient : `owner` est la SEULE colonne reliant un
contenu diffusé à une personne (la retirer ferait de l'exploitant l'hébergeur d'un contenu sans
auteur, sans retrait ciblé, et supprimerait la seule prise du droit à l'effacement) ; l'approbation
des comptes deviendrait décorative, le contournement s'appelant « Déconnexion » ; et **un hôte
anonyme serait un hôte infirme** — la qualité d'hôte n'a aucun porteur autre que le JWT, donc ni
réadmission, ni coupure, ni fin de partage : si la mauvaise personne entre, le partage reste vivant
jusqu'à expiration. Si la décision devait s'inverser un jour, le seul chemin défendable est un
compte ANONYME Supabase (vrai identifiant, journal, révocation, cascade d'effacement), jamais un
`owner` nullable, et derrière un interrupteur d'instance par défaut fermé.

### Journal des actions, et fin de session
Incrémenter un compteur **pose désormais un repère horodaté** dans le journal des actions —
« choc n° 3 à 14:32 » est exactement ce qu'on oublie de noter sous stress, et l'heure est ce qui
compte cliniquement. Le repère porte une RÉFÉRENCE, jamais un mot : son libellé se dérive de la
fiche à l'affichage, il traverse donc le partage sans texte libre et suit le compteur si on le
renomme. Le rail ne remonte pas (mise à jour chirurgicale).

Le `×` du journal **annule au lieu de supprimer** : ligne barrée, estompée, conservée, et le `×`
devient `↺` pour se raviser. Deux règles du projet le condamnaient déjà — « action destructrice en
situation de crise = geste maintenir, pas un simple tap », et le précédent `origT`, où la correction
d'heure est non destructive, visible et réversible. Le « maintenir » a été envisagé et écarté : il
protège du geste accidentel mais laisse la perte définitive, et ne dit rien à celui qui relit — or
le journal alimente le compte-rendu. **L'heure reste en encre pleine** (c'est la donnée clinique).
C'est aussi ce qui rend le geste admissible pour un scribe en session partagée : attribué, daté,
réversible — là où un décochage, qui détruit vraiment une information, lui reste fermé.

### Vérification
663 tests × 2 moteurs, 13 harnais verts, **94/94 contrôles doctrine** (+54), **301 contrôles
d'accessibilité** (+12, dont l'écran d'entrée dans les deux thèmes), 55/55 contrôles partage. Les
nouveaux contrôles ont chacun été **vérifiés capables d'échouer**, fichier restauré à l'octet
ensuite. `supabase/schema.sql` et `rls-tests.sql` ont été rejoués sur l'instance (le genre
d'évènement `mark_void` s'ajoute aux capacités du scribe).

**Incident de manipulation, consigné parce qu'il doit servir.** Un `git checkout -- index.html`,
lancé pour annuler une modification temporaire de démonstration, a effacé tout le travail non
committé du fichier — cette commande ne défait pas la dernière modification, elle restaure depuis
le dernier commit. Le fichier a été reconstruit depuis le transcript de session (79 éditions
rejouées dans l'ordre, deux ancrages réparés, deux modifications faites hors outil d'édition
retrouvées et re-appliquées), puis vérifié : audit systématique des 79 éditions (zéro manquante),
cohérence de la réparation manuelle sur ses 5 sites, absence de duplication, et surtout la suite
complète au vert — les tests et les treize harnais, eux, n'avaient pas été touchés, et c'est ce qui
a servi de juge. **Règle : pour annuler une modification expérimentale, restaurer depuis une
sauvegarde vérifiée par empreinte, jamais depuis git tant que le travail n'est pas committé.**
