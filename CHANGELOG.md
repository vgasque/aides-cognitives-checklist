# Journal des modifications

## [5.0.10] — 2026-08-05
### Une connexion IndexedDB fermée n'est plus une panne : elle se reprend toute seule

Signalé à l'usage sur un appareil synchronisé — « Erreur inattendue · Détail technique : Failed to
execute 'transaction' on 'IDBDatabase' : The database connection is closing ».

- **La cause.** Une connexion IndexedDB se ferme **sans que l'application le demande** : quand un
  autre onglet migre la base ou l'efface, `onversionchange` la libère (c'est nous qui appelons
  `close()` là) ; une page qui commence à se recharger les ferme toutes — et la bascule d'espace
  comme l'écouteur `storage` déclenchent un `location.reload()` sans arrêter la synchronisation ;
  un moteur mobile peut enfin les reprendre en arrière-plan. Le handle mort restait posé, et
  **toute transaction suivante levait `InvalidStateError`** : la synchronisation échouait, et le
  message affiché livrait le libellé brut du moteur — qui ne désigne pas sa cause et envoie
  chercher la panne du mauvais côté (réseau, serveur, compte).
- **Le remède, en un seul point d'écriture.** Toute méthode publique du backend IndexedDB est
  enveloppée **par une boucle, jamais par une liste** : une méthode ajoutée demain est couverte
  sans qu'on y pense (même patron que `persistLive` pour la session et `edCommit` pour le
  brouillon — une liste recopiée finit toujours par diverger, et le trou est silencieux). Un
  handle mort n'est plus jamais gardé, et l'appel qui tombe dessus **rouvre et réessaie une fois**
  — au-delà l'erreur remonte, une base réellement indisponible devant se voir. Un drapeau
  interdit cette reprise pendant un **effacement** de données : rouvrir recréerait la base qu'on
  efface.
- **⚠ Piège de spécification, appris à la mesure** : l'événement `close` ne se déclenche **pas**
  sur une fermeture explicite — il est réservé aux fermetures anormales. Un correctif qui n'aurait
  écouté que lui serait resté inerte sur le chemin le plus fréquent.
- **Le message cesse de livrer le libellé du moteur.** Nouvelle famille d'erreur de
  synchronisation : « Stockage momentanément indisponible » dit la cause probable (application
  ouverte dans un autre onglet, page en cours de rechargement), **qu'aucune donnée n'est perdue**
  et que la synchronisation reprend automatiquement.
- **Le dernier angle mort du dispositif est fermé** (`scripts/audit-stockage.mjs`, 19ᵉ harnais).
  Le stockage local — la fonction dont tout dépend en intervention — n'était mesuré que par ses
  parties **pures** : `npm run check` lit du texte, `npm test` charge `index.html?__actest`, qui
  n'amorce pas l'application et n'ouvre donc **aucune base réelle**. Les deux garde-fous étaient
  verts pendant que la synchronisation échouait chez l'utilisateur. Le harnais coupe la connexion
  *sous* l'application, exactement comme le moteur le ferait, et vérifie que l'appel suivant
  réussit — lecture comme écriture groupée, par où passe le pull de synchronisation. Vérifié
  capable d'échouer sur les deux moteurs.

## [5.0.9] — 2026-08-04
### Quatre défauts d'affichage signalés à l'usage, et l'un d'eux n'était mesurable par aucun harnais

- **La réponse attendue enroule au lieu d'écraser le geste** (vue « Toute la fiche » › Parcours,
  capture à l'appui). `.pc-r` était `flex:none` dans une rangée qui n'enroulait pas : le seul objet
  compressible était donc l'**action** (`.pc-t`, `min-width:0`). Mesuré sur un cas adverse à
  320 px — « Curariser… » tombait à quelques pixels de large pendant que la pilule sortait de la
  carte. On perdait ainsi l'information principale *et* la secondaire. Le remède est déjà écrit
  dans ce fichier pour ce défaut exact, sur la feuille « Consulter » (`.rs-v`) : la pilule prend sa
  propre ligne, alignée sur le texte. **Une seule grammaire — on enroule, on ne tronque jamais.**
- **Chaque branche d'une décision porte son étiquette, et une branche sans carte n'est plus
  muette.** L'étiquette était mise en attente puis posée devant la première *carte* de la branche —
  or `flowPlan` n'en émet pas toujours : une branche qui rejoint le point de convergence ou qui
  reboucle sur un bloc déjà décrit ne produit qu'un renvoi. Mesuré sur la fiche d'exemple
  Anaphylaxie : seule « NON — RÉFRACTAIRE » s'affichait, « OUI — STABILISÉ » n'a **jamais** été
  rendue. L'étiquette s'émet désormais à l'ouverture de la branche (même position dans le cas
  nominal, présente dans les autres), et le renvoi se dessine — « → n », « ↺ n », « ▪ fin », le
  vocabulaire abrégé de l'Échelle — mais **seulement quand la branche n'a pas de carte** : sinon le
  pied de la carte précédente le dit déjà, et l'on écrirait deux fois la même chose. Tout y reste
  **inerte** (doctrine du plan, vérifiée).
- **⚡ Les cibles de complication se reconnaissent dans le schéma** (proposition de l'auteur :
  « mettre un éclair et en rouge ? »). Le SVG était la **seule** des quatre vues de structure où
  une cible de complication se dessinait comme un bloc d'étapes ordinaire — donc comme *l'étape
  d'après*, le défaut exact mesuré en v4.26.0 (« 5 Laryngospasme »). L'Échelle, le tableau Statique
  et la vue Parcours ont toutes leur section « À tout moment ». Registre **ALERTE en CONTOUR**
  (v4.26.1) : bandeau d'en-tête teinté, liseré et cadre rouges, **corps du bloc inchangé** — un
  aplat rouge permanent désensibilise au rouge, qui appartient ici aux étapes vitales dessinées à
  l'intérieur. La couleur n'est jamais seule (règle 8) : pastille « ⚡ À TOUT MOMENT » en toutes
  lettres, reprise dans le nom accessible du nœud. L'éclair est un **tracé** et non le caractère
  « ⚡ », qui sortirait en emoji couleur sur iOS dans un dessin qui n'a d'autre couleur que ses
  registres.
- **Un bloc complet l'est sur toute sa bordure** (« uniquement le bord gauche devient vert et pas
  le reste »). `.done` n'écrivait que `border-left-color` : un bloc **courant et complet** portait
  un cadre bleu avec une seule arête verte — deux registres sur un même trait, exactement ce que la
  v4.24.0 a corrigé en sens inverse pour la décision. Et c'est la configuration **nominale** : on
  finit de cocher le bloc où l'on est. La carte *repliée* le faisait déjà (`.closed.done`) — le
  même bloc changeait donc de registre selon qu'il était plié. Pas de fond teinté sur la carte
  ouverte, qui est la colonne d'action et porte des étapes ⚠/△ dont la boîte doit rester lisible ;
  une **décision reste exclue**, son ambre prime sur l'état.

### ⚠ Le chrome collant ne se dérive plus d'une position de défilement

« Barre d'en-tête inférieure, scroll pas très réactif, beaucoup d'à-coups » — vidéo à l'appui, où
les deux rangées collantes se désolidarisent de l'en-tête et laissent une bande vide à leur place.

`--hdr-h` est le `top` collant de la rangée de commandes, donc du quai empilé dessus. Il était
dérivé du **`bottom`** de l'en-tête, c'est-à-dire d'une *position*. Or, au rebond de fin de course,
iOS **translate tout le document**, en-tête collant compris : `bottom` grandit, `--hdr-h` grandit
avec lui, les deux rangées descendent — puis reviennent. À la cadence du doigt, c'est le
tremblement filmé. C'est la **hauteur** qu'il fallait mesurer : elle ne dépend d'aucun défilement,
et c'est la seule des deux qui exprime ce que la valeur veut dire. Idem pour `--stick-top`, devenu
une somme de hauteurs ; `stickBase()` garde ses rectangles là où c'est juste — `ovScrollEl`, qui
vise une position d'écran à l'instant du saut.

Même famille que le rail A→Z (v5.0.2) et que la hachure des placards (v5.0.6) : **on n'ancre
jamais à un repère qu'on ne contrôle pas**, et ce que le compositeur fait du rendu n'est visible
dans aucune mesure de la page — un harnais Blink reste vert. Le témoin **déplace** donc l'en-tête
sans changer sa hauteur, stand-in fidèle de ce que fait le compositeur, et vérifie que la géométrie
du chrome ne bouge pas d'un pixel (vérifié capable d'échouer : défaut réintroduit → 3 rouges).

Bénéfice second, et il compte autant : la valeur devenant **constante**, la garde d'écriture
devient un vrai no-op — on cesse d'invalider le style de tout le document (une propriété
personnalisée posée sur `<html>`) à chaque évènement de défilement. Et la passe est désormais
**coalescée par image** au lieu d'être branchée sur l'évènement : elle lit quatre rectangles puis
écrit trois propriétés, un couple lecture/écriture qu'on n'intercale plus dans le pipeline de
défilement (même discipline que `svPaintArrows`, v4.14.10). L'appel direct de `render()` reste
synchrone — `landOnBout` se mesure contre `stickBase()`, qui doit avoir été resynchronisé avant.

### Témoins

`audit-doctrine` : trois sections neuves (15 contrôles) — le parcours sur un cas **adverse
construit** (réponse longue, branche qui reboucle, à 320 px : sur les fiches d'exemple aucune
réponse ne déborde, le contrôle serait resté vert sur le défaut), la géométrie du chrome sous
déplacement, et les quatre côtés d'un bloc complet. `audit-complications` : 5 contrôles sur le
schéma, dont un qui vérifie d'abord que le nœud **existe** — et l'on y mesure la *propriété* (le
nœud se distingue par un mot ET par le registre, aucun autre ne l'emprunte), jamais la valeur d'un
hex isolé, qui rougirait sur un changement de token qui serait juste.

**⚠ Une leçon de méthode, payée à l'écriture.** Le correctif du bloc complet a d'abord été livré
inerte : le commentaire qui l'explique portait un **`*/` en trop**, le texte restait à nu et le
parseur avalait la règle suivante — le défaut de cascade décrit dans `AGENTS.md` depuis la
v4.74.2, reproduit à la lettre. C'est la mesure qui l'a dit, pas la relecture ; `check-syntax` le
nomme précisément (« fermeur de commentaire sans ouvreur »), il suffisait de le lancer avant.

## [5.0.8] — 2026-08-04
### Le chapeau se glisse entre les critères et le bouton

Question posée : « remonter *Confirmer le diagnostic* au-dessus de *Ne pas oublier* — est-ce
incompatible ECAM/QRH ? ». **Non — c'est l'ordre canonique, et c'est celui d'avant qui s'en
écartait.** Un QRH imprime le titre et la condition d'entrée au-dessus des recall items ; sur ECAM
le titre de l'alerte — qui *est* la condition — précède les lignes d'action. La séquence est
condition → memory items → read-and-do ; on avait memory items → condition.

- **Le chapeau ne passe pas SOUS le bouton, et c'est tout l'arbitrage.** Le descendre simplement
  sous l'étage de la condition d'entrée le mettrait *après* « Confirmé — démarrer la session », le
  bouton vivant dans cet étage : on l'aurait rangé derrière le geste qu'il doit précéder. Il se
  glisse donc **entre les deux** — la lecture devient exactement celle du QRH, et le bouton porte
  l'acquittement des deux.
- **Une fois la session démarrée, rien ne change de ce qui existait** : le chapeau replié revient
  en tête et la condition d'entrée descend avec son étage (T3 + T5). Le débat ne portait que sur
  l'écran d'avant.
- **⚠ Ce que cela coûte, mesuré, et il faut le savoir** : le chapeau quitte le premier écran dès
  que les critères sont longs (fiche à 8 critères, 390 × 844 : il naissait à y = 130, il naît à
  y = 813). Sur une fiche ordinaire il y reste **entier** (571 → 786 à 390 × 844). Et comme le
  bouton flotte quand il est sous le pli (v4.73.0), on peut démarrer sans avoir défilé jusqu'aux
  memory items.
- **Ce qui rend ce coût acceptable est le lot T7** : un memory item ★ **reste dans son bloc** — le
  chapeau *agrège*, il ne possède pas. Rien n'est perdu : l'item se re-vérifie à sa place dans la
  checklist, ce qui est précisément le geste QRH (réciter de mémoire, puis confirmer sur la liste).
- **La condition est la présence du BOUTON, pas l'état de la session** : chez l'invité et en aperçu
  d'essai `sessStartH` est vide — une séquence qui mène à un bouton absent n'a rien à ordonner, et
  le chapeau reprend sa place en tête. Idem sur une fiche sans critères, et en mode statique, où le
  tableau porte déjà son propre ordre (`svExtras`).
- **⚠ La constante est déclarée avant le `if(useSv)`** : la coque de `main.innerHTML` la lit aussi
  (c'est elle qui décide si le chapeau est encore rendu en tête de colonne). Posée dans la branche,
  elle aurait été hors de portée — même zone morte temporelle que celle payée au lot T3.
- Témoins dans `audit-doctrine` (6 contrôles) : ordre critères → chapeau → bouton, chapeau rendu
  **une seule fois**, retour en tête en session, et la branche sans critères. Vérifiés capables
  d'échouer. La fixture de la section « démarrage » a dû être **rallongée à onze critères** : avec
  le chapeau descendu, huit ne suffisaient plus à faire défiler à 390 px, et le contrôle ne
  rencontrait donc plus son cas.

## [5.0.7] — 2026-08-04
### Démarrer une session dépose sur le haut du premier bloc

Signalé à l'usage : « lorsqu'on clique sur *démarrer la session*, s'assurer que le haut du premier
bloc d'étapes soit visible ».

- **Ce que le geste fait disparaître au-dessus du doigt.** Presser « Confirmé — démarrer la
  session » replie le chapeau « Ne pas oublier » en une ligne (T3), referme la condition d'entrée
  (acquittement par l'action) et remonte l'étage « Prise en charge » en tête (T5). Le défilement,
  lui, ne bougeait pas : on atterrissait **au milieu** de la carte du bloc, son numéro, son titre
  et « Vous êtes ici » au-dessus du pli, à l'instant précis où le soin commence.
- **Mesuré, sur le cas pour lequel `.sess-start.afloat` existe** — une condition d'entrée longue
  (8 critères), qu'on lit en défilant pendant que le bouton suit, flottant : après le clic, le haut
  de la carte tombait à **−206 px à 320 × 640** (324 px au-dessus des couches collantes) et à
  **+20 px à 390 × 844**, soit 98 px *sous* l'en-tête collant. Après : **+8 px sous le quai** dans
  les deux formats, et **2 → 5 étapes cochables** entièrement visibles à 320 px.
- **Ce n'est pas un défilement automatique (règle 11).** La règle vise l'écran qui bouge sous
  quelqu'un qui n'a rien demandé ; ici la page vient d'être rendue de neuf et le geste est une
  navigation demandée d'un tap — même arbitrage que `landOnBout` à la réentrée et que `cxEnter`.
- **Un seul point d'écriture** (`startSessionGesture`), partagé par le bouton du parcours et son
  homologue du tableau statique — les deux copies faisaient déjà la même chose à la ligne près.
- **⚠ Ce chemin est celui du BOUTON, jamais celui du cochage** : un démarrage implicite (cocher une
  étape, armer un minuteur) passe par `renderKeepAnchor` et continue de ne pas déplacer d'un pixel
  l'élément touché (invariant ECAM v4.4.0).
- **⚠ Et la règle de visibilité de `landOnBout` a été essayée puis mesurée fausse ici** : elle exige
  la carte ENTIÈRE à l'écran, or une carte de bloc dépasse presque toujours le pli (615 px sur 640).
  Elle défilait donc même quand le haut était déjà à sa place, y compris sur les fiches courtes, et
  laissait la page décalée pour les gestes suivants — **deux témoins de dépliant l'ont dit, à
  −51 px** (le panneau du quai ne se posait plus sous le quai). On ne garantit que ce que l'usage
  demande : **le HAUT** de la carte sous les couches collantes, et rien ne bouge s'il y est déjà.
- **Les trois densités ont chacune leur porteur** : `.ov-block` (journal), `.sv-cell.cur`
  (statique), `.nav-wrap` (vue guidée d'une fiche sans algorithme) — oublier le troisième, c'était
  ne rien faire précisément sur les fiches mono-bloc, sans que rien ne le dise.
- Témoins dans `audit-doctrine` (11 contrôles) : le cas est **construit** (les fiches d'exemple ne
  le rencontrent pas), il est prouvé par **contrefactuel** (on repose la page où elle était au clic
  et l'on remesure), la vue guidée a le sien, et la **non-régression** est l'autre moitié — sur une
  fiche courte, le démarrage ne déplace pas la page d'un pixel. Vérifiés capables d'échouer.

## [5.0.6] — 2026-08-03
### La hachure ne s'ancre plus à un repère qu'on ne contrôle pas

Signalé à l'usage, sur l'appareil : « le fond hachuré ne traverse la frontière que par moments ;
celui d'en haut bouge lors du scroll ; et ils ne sont pas toujours synchronisés ».

- **La v5.0.5 avait le bon raisonnement et la mauvaise dépendance.** Deux boîtes dont l'écart
  change à chaque frame ne peuvent partager une phase que par un repère tiers : d'où
  `background-attachment:fixed`, l'ancrage au viewport. Vert aux deux moteurs en headless, à
  l'arrêt comme en cours de défilement — et **faux sur l'appareil** : WebKit ne repeint pas un fond
  fixé en même temps qu'il défile, la texture retarde, glisse, puis se recale. Même famille que le
  rebond du rail A→Z (v5.0.2) et que le dossier « bande basse iOS » : **ce que le compositeur fait
  du rendu n'est visible dans AUCUNE mesure de la page**, donc un harnais vert ne prouve rien sur
  cette classe de propriétés.
- **Ce qui tient sa place.** Chaque hachure appartient à SA barre — donc celle du haut ne peut plus
  bouger, l'en-tête ne bougeant pas — et l'on met celle du bas en phase par un décalage **mesuré**,
  `--hdr-h` : les deux boîtes de dégradé sont les boîtes de rembourrage des deux barres, même bord
  gauche, écart vertical égal à la hauteur de l'en-tête. Un `background-position` de cette valeur
  suffit, sans un octet de JS et sans que rien ne dépende du défilement.
- **Le vrai travail est le pavage.** Un décalage pave, or un dégradé répétitif se dimensionne sur
  sa boîte et sa phase s'ancre à son coin BAS-DROIT : deux boîtes de hauteurs différentes ne sont
  jamais en phase, et le report coudrait. La tuile est donc CARRÉE (31 px) et ses bandes
  s'expriment en **pourcentage de la ligne de dégradé** — une période de 50 % en met exactement
  deux par tuile, ce qui la rend raccordable à n'importe quelle taille **sans jamais écrire √2 dans
  une feuille de style**. 31 px redonnent la période d'origine (21,9 px pour 22) au dixième de
  pixel près, et un entier pave net à 1×, 2× et 3× (vérifié en capture à 3×).
- **Contrepartie assumée, et bornée** : la phase n'est commune qu'au REPOS. En défilant, chaque
  texture suit sa barre — ce que fait toute texture peinte sur un objet, rien ne bouge tout seul —
  et le bandeau passe de toute façon sous la barre en moins de 60 px.
- **Le témoin mesure désormais la PROPRIÉTÉ, plus le mécanisme.** Celui de la v5.0.5 exigeait
  `background-attachment:fixed`, c'est-à-dire la solution du jour : il serait passé au rouge sur le
  correctif qui la remplace. Il recompose l'origine de chaque grille (coin de la boîte de
  rembourrage + `background-position`) et compare la phase modulo la tuile, plus le raccord de
  celle-ci. Vérifié capable d'échouer sur les deux points, aux deux moteurs.

## [5.0.5] — 2026-08-03
### Le placard cesse de se briser, le logo se cale sur son dessin

Trois retours d'usage, tous sur des repères visuels que le code posait sur la mauvaise référence.

- **La hachure traverse la frontière des deux barres d'en-tête** (signalé à l'usage, capture à
  l'appui). Un placard est UN placard — porté par deux boîtes, l'en-tête et le bandeau —, mais
  chacune générait son dégradé depuis SON propre coin haut-gauche : les rayures se brisaient net à
  la jointure, deux textures voisines au lieu d'une seule qui traverse.
  `background-attachment:fixed` fait calculer les deux depuis l'origine du **viewport** : la
  continuité devient une propriété du calcul, pas une valeur à tenir à jour.
  **Écartés à la mesure** : un décalage par `background-position:0 calc(-1*var(--hdr-h))` serait
  juste au repos et FAUX dès le premier pixel de défilement — le bandeau glisse sous la barre, son
  offset d'écran change à chaque frame — et il ferait en plus apparaître une couture de pavage, la
  hauteur d'en-tête n'ayant aucune raison d'être un multiple de la période (22 px sur l'axe, soit
  31,11 px en vertical). Effet de bord voulu : le bandeau glisse, sa texture ne bouge pas — aucune
  ligne ne se met à courir sous les yeux (ECAM).
  **⚠ Le piège gardé est SILENCIEUX** : la variante d'essai écrivait sa hachure avec le raccourci
  `background`, qui remet `background-attachment` à `scroll` — elle seule aurait perdu l'alignement.
  Toute variante s'écrit donc en `background-image`. Témoin dans `audit-exercice` sur les **trois**
  placards (exercice · invité · essai) et dans les deux thèmes, après avoir vérifié qu'une hachure
  est bien posée : sans ce préalable on lirait « none / none » et on le déclarerait aligné.
  Vérifié capable d'échouer dans les deux sens ; alignement mesuré à l'arrêt ET en cours de
  défilement, sur Chromium et WebKit.
- **Un logo se cale sur son DESSIN, jamais sur sa boîte** (signalé à l'usage : « rapproche le logo
  de “Aides cognitives”, ça fait très étrange »). La v5.0.0 le CENTRAIT dans le blanc de gauche :
  bonne intention — il paraissait collé au texte —, mauvais repère. Centrer une marque dans une
  gouttière la fait flotter, alors qu'un logo et son mot-marque se lisent comme UN objet ; et la
  mesure disait déjà l'inverse de l'impression, l'écart optique au texte valant **14,5 px** quand
  celui au bord n'en valait que **2**.
  **La cause est dans le masque** : `logo-glyph.svg` porte son propre blanc — mesuré au canvas,
  l'encre occupe x ∈ [181, 889] sur 1024, soit **17,7 % à gauche et 13,1 % à droite**. La boîte de
  34 px n'a donc jamais été le logo : on calait un rectangle dont un cinquième était vide. On la
  rogne sur l'encre par deux marges négatives prises sur l'échelle d'espacement, et les deux
  demandes tombent ensemble — l'encre commence **exactement à la marge de page**, donc alignée sur
  les rangées du répertoire dessous, et le `column-gap` de la rangée devient l'écart optique RÉEL
  (14,5 → 10 px). Rien n'est ajouté ni élargi : le rognage **rend 10 px** à la rangée d'identité,
  celle qui se dispute chaque pixel à 320. Sous 400 px, où le `column-gap` tombe à 4 px pour rendre
  de la largeur à toute la rangée, le rognage de droite est annulé : cet écart-là n'est pas une
  gouttière entre deux objets, c'est la respiration d'un seul, et elle reste proportionnée au
  dessin (8 px optiques, pour 4 px repris sur les 10 rendus).
  Témoin dans `audit-doctrine` (320 · 390 · 430 · 1280) : il **relit les insets d'encre au canvas**
  — un inset écrit en dur périmerait au premier retracé du glyphe — et vérifie d'abord qu'il
  rencontre son cas, le logo n'existant que sur l'accueil. Vérifié capable d'échouer (6 rouges).
- **Le réglage « Couleur d'accent » cesse de promettre ce qu'il ne fait plus.** Il annonçait
  « colore l'accueil et les en-têtes — jamais le contenu de crise », alors que la v5.0.0 a confiné
  l'accent au seul disque de l'avatar. La phrase dit désormais ce qui se passe, et le « En savoir
  plus » dit POURQUOI la portée est si étroite : ici une couleur porte toujours un sens, et une
  teinte répandue sur l'écran entrerait en concurrence avec les registres. Deux commentaires de
  code qui portaient encore l'ancienne portée — dont l'en-tête de la section des palettes, que le
  bloc suivant contredisait mot pour mot — sont remis d'aplomb : une doctrine qui affirme un état
  révolu est pire qu'une doctrine absente.

## [5.0.4] — 2026-08-03
### La table distante et le store local sont deux noms, pas un

Signalé à l'usage : « Erreur synchronisation : Erreur inattendue — Failed to execute 'transaction'
on 'IDBDatabase': One of the specified object stores was not found ». La synchronisation des aides
échouait **entièrement**, dès la première page rapatriée portant une ligne.

- **La cause.** `_pullTable(cfg)` faisait servir `cfg.table` à DEUX choses : la table REST
  (`/rest/v1/<table>`) et le store LOCAL où la page est écrite (`Data.applyRows`). C'était vrai
  tant que les deux noms coïncidaient. Le lot T9 (v5.0.0) a renommé la table Supabase
  `fiches` → `cognitive_aids` — décision motivée, et qui ne pouvait PAS renommer le store
  IndexedDB, une montée de version de base cassant le stockage local. Le pull des aides demandait
  donc une transaction sur un store `cognitive_aids` qui n'existe nulle part. Les deux noms sont
  désormais distincts (`cfg.store`, défaut = `cfg.table`), et le pull des aides écrit dans
  `fiches`.
- **Le défaut jumeau, silencieux, trouvé au passage.** Dans le repli localStorage,
  `KV.applyRows` faisait `store==='protocols' ? 'protocols_v1' : 'fiches_v1'` : **tout le reste
  tombait dans les fiches**. Le pull de l'historique de sessions (v4.54.0) y rangeait donc ses
  sessions dans la bibliothèque, sans un mot — là où IndexedDB, lui, avait au moins crié. Une
  table explicite (`SYNC_KV_KEY`) remplace le repli par défaut, et **un nom inconnu échoue
  bruyamment** : corrompre en silence est la pire des deux options, et c'est précisément ce qui a
  laissé ce défaut vivre. `kvStoreKey` est PURE (testée), et `__proto__` ne traverse pas la table
  (règle 6).
- **`scripts/check-stores.mjs` (dans `npm run check`) rend le couplage auto-exécutoire**, dans les
  deux sens : tout store visé par une écriture de synchro existe RÉELLEMENT dans le schéma créé
  par `openSpaceDb` (le schéma fait autorité — aucune liste recopiée, une liste recopiée diverge) ;
  tout nom de store écrit en toutes lettres ailleurs existe aussi ; et `SYNC_KV_KEY` couvre
  exactement les stores que la synchro écrit. **Vérifié capable d'échouer** dans les deux sens
  (défaut d'origine réintroduit → rouge ; entrée KV retirée → rouge ; fichier restauré à l'octet).
- **Pourquoi rien ne l'avait vu.** Aucun harnais n'exerce un pull réel, et `npm run check` ne
  lisait pas ce couplage : c'est la leçon constante du dossier — partout où une règle est restée
  DÉCLARATIVE (« `cfg.table` = le store local », écrit en commentaire), elle a fini par fuir.
  Corollaire du renommage : **après un renommage, chercher les endroits où l'ancien nom servait à
  DEUX choses**, pas seulement les endroits qui le citent.

## [5.0.3] — 2026-08-03
### Le déclencheur de filtre déménage contre la recherche, et cesse de disparaître

Signalé à l'usage : « le bouton filtrer sur la page d'accueil ne s'affiche pas toujours quand on a
sélectionné », avec deux propositions — le poser à côté de la barre de recherche, en icône seule,
et lui faire dire qu'un filtre agit.

- **Il ne disparaît plus quand un filtre agit — l'état a changé de PORTEUR.** La v5.0.0 tenait la
  règle « un état actif ne se cache jamais » en FORÇANT les trois rangées ouvertes dès qu'un filtre
  était posé, et en retirant le déclencheur (« plus rien à basculer, donc aucun bouton mort »).
  Elle achetait donc la garantie au prix d'un contrôle qui apparaît et disparaît selon l'état —
  ce que la constance positionnelle proscrit — et son gain de ~90 px au premier écran n'existait
  plus dès qu'on avait filtré quoi que ce soit. Désormais c'est le déclencheur qui PORTE l'état :
  registre de sélection plein **plus le nombre de filtres posés**. La couleur n'est jamais seule
  (règle 8) — un chiffre n'est pas une couleur — et le nom accessible le dit en toutes lettres
  (« Afficher les filtres — 2 actifs »). Replier avec un filtre actif redevient donc permis, sans
  qu'on puisse se retrouver dans un corpus restreint sans savoir pourquoi.
- **Il vit contre la recherche, en glyphe seul.** Les deux répondent à la même question —
  restreindre ce qu'on voit — et posé là il ne coûte plus une ligne au premier écran. Mesuré à
  320 px : 38 px de bouton (45 avec le chiffre), **0 px de débordement**, cible 38×36 px plus son
  halo. Il est STATIQUE comme le champ (il vit hors de `main`, on le PEINT au lieu de le
  reconstruire) : sa position s'apprend une fois pour toutes, et c'est son **bord droit** qui est
  constant — il grossit du chiffre, il ne se déplace pas (mesuré : 372 px dans tous les états).
  Il n'existe qu'en voie ÉTROITE : en large les filtres vivent dans la colonne gauche, déjà
  visible, et un bouton pour déplier ce qui est déplié serait mort.
- **Sa hauteur est celle du champ, et elle ne peut pas être écrite** (signalé à l'usage : « la
  taille du bouton filtre est moins longue que le champ de recherche — c'est voulu ? » — non).
  Une hauteur FIXE de 36 px, celle des contrôles ronds de l'en-tête, laissait **4 px de jeu en haut
  comme en bas** : le champ monte à 43 px sur écran TACTILE (police de 16 px, plancher de la
  règle 9) et redescend à 42 px au pointeur fin — il n'existe donc aucun nombre juste à écrire ici.
  La hauteur est portée par la RANGÉE (`align-self:stretch`), `min-height` gardant la cible
  réglementaire. Mesuré à 320/390/430/560/700/779 px : **0 px de jeu**, les deux objets alignés en
  haut et en bas quelle que soit la hauteur du champ.
- **Une croix d'effacement dans le champ de recherche.** Elle n'existe que s'il y a quelque chose à
  effacer, sa place est **réservée en permanence** par un rembourrage constant (un rembourrage qui
  bougerait ferait sauter le texte sous le curseur), et le focus RESTE dans le champ : on efface
  pour retaper, pas pour partir. **Peinte à la FRAPPE, pas au rendu** — celui-ci est débouncé de
  150 ms, et une croix qui paraîtrait un sixième de seconde après la lettre se lirait comme une
  latence.
### Deux mesures que l'usage a réclamées

- **L'en-tête d'accueil ne tenait pas sur une ligne à 320 px.** La v4.43.0 a déclaré ce plancher
  SERVI et l'a mesuré sur la rangée de crise et sur la barre des éditeurs — jamais sur l'en-tête
  d'ACCUEIL, qui est pourtant le premier écran ouvert. Mesuré : logo 30 + mot-marque 126 + actions
  136 = 292 px, plus deux écarts, soit 308 px pour 284 disponibles. `.id-row` étant en `flex-wrap`,
  le flex **casse la ligne avant de rétrécir** : les trois boutons ronds tombaient sur une seconde
  rangée et l'en-tête payait **38 px de haut**, là où la hauteur est la plus rare. Recette sur les
  écarts et la taille des boutons — ni le mot-marque ni le logo ne bougent, l'audit A3-1 venant de
  les calibrer — plus un **halo porté de 4 à 6 px** pour que la cible reste à 44 px au pixel près :
  rétrécir le DESSIN sans rétrécir la CIBLE est tout l'objet d'un halo en zone haute. En-tête
  **148 → 106 px** à 320 px.
- **Un palier intermédiaire à 400 px, trouvé par la mesure de la MARGE.** À 360 px la rangée tenait
  avec **6 px** de réserve — vrai aujourd'hui, faux au premier rendu de police un peu plus large :
  le mot-marque mesure 126 px sur Chromium complet et **136 sur le headless shell**, soit 10 px
  d'écart pour le même code. Un booléen « ça tient » reste vert jusqu'au dernier pixel puis casse
  d'un coup ; le témoin mesure donc la RÉSERVE (≥ 8 px), pas le tenu-de-peu. Recette légère (les
  écarts seuls) : **6 → 22 px** de réserve à 360 px.
- **La gouttière du rail A→Z passe de 24 à 16 px.** Question posée : cet espace est-il un tampon
  anti-fausse-manœuvre ? Non — en voie étroite le rail est `position:fixed`, et la réservation
  l'empêche de RECOUVRIR le bord droit des rangées, donc l'épingle. Il n'en fallait jamais 24 : le
  rail fait 27 px et mord déjà sur les 18 px de marge de page, 9 suffisent à ne rien couvrir ; le
  reste était du vide. Après : **8 px** entre la carte et le rail, **9 px** entre la zone tactile de
  l'épingle et la première lettre — les deux cibles ne se touchent pas, seule contrainte réelle —
  et **8 px rendus à chaque rangée**, à toutes les largeurs étroites.
- **`check-space` neutralise désormais les commentaires.** Il les lisait, et la feuille CITE ses
  propres déclarations à longueur de commentaires doctrinaux : un `column-gap:8px` écrit dans une
  explication faisait courir la capture `[^;}]+` jusqu'à l'accolade suivante, à travers le
  commentaire ET la règle d'après, où elle ramassait le `359.98px` d'une media query et le
  signalait comme un espacement de « 98 px ». Les commentaires deviennent des espaces de MÊME
  LONGUEUR, donc les numéros de ligne restent exacts. Même précaution que `check-upload`.

- **Témoins** (`audit-doctrine`, 643 → 693 contrôles) : le bloc « repli des filtres » mesure
  désormais la géométrie du déclencheur (même rangée que la recherche, à sa droite, dans l'écran),
  sa cible, le fait qu'il RESTE et s'annonce quand un filtre agit, que l'annonce survit à un
  re-rendu complet ET au repli, que sa position ne bouge pas d'un état à l'autre, et que le chiffre
  COMPTE (avec son témoin : sans seconde dimension filtrable, on mesurerait « 1 » en croyant
  mesurer « 2 »), et qu'il fait exactement la hauteur du champ. Un bloc neuf couvre la croix. Les deux sont **vérifiés capables d'échouer**
  (règle v5.0.0 réintroduite → 6 rouges ; peinture à la frappe retirée → 1 rouge ; hauteur fixe
  réintroduite → 1 rouge), et le probe est
  GARDÉ à chaque geste : un déclencheur absent est le défaut qu'il mesure, le laisser lever ferait
  planter le harnais — « un harnais qui plante en emporte cinq ».
  **Deux blocs neufs** mesurent l'en-tête d'accueil (une seule ligne ET sa RÉSERVE, cibles halo
  compris, aucun débordement — 320/360/375/390/430 px) et la gouttière du rail (il ne recouvre
  aucune rangée, la zone tactile de l'épingle reste libre — 320/390/430/640/779 px, après avoir
  CONSTRUIT le répertoire : les fiches d'exemple ne donnent pas assez de lettres pour qu'un rail
  existe, et sans ce témoin on mesurerait un écran sans rail).

## [5.0.2] — 2026-08-02
### Le rail A→Z, deuxième terme : la marge basse du matériel

Signalé à l'usage après la v5.0.1 : « ça persiste en partie, surtout quand on scroll vers le bas
sur le rail — il remonte ». La v5.0.1 avait traité `--vvh` et laissé, dans la même formule, un
second terme qui bouge exactement pour la même raison.

- **`env(safe-area-inset-bottom)` n'est pas une constante dans Safari iOS.** La barre d'outils du
  bas COUVRE la bande de l'indicateur d'accueil : l'inset vaut **0 tant qu'elle est déployée** et
  saute à **~34 px dès qu'elle se replie** — c'est-à-dire au défilement. La hauteur du rail perdait
  alors 34 px et les lettres centrées **remontaient de 17 px**, au mot près ce qui a été rapporté.
  Le terme est retiré : `100svh` est déjà la hauteur *barre déployée*, son bord bas se situe donc
  au-dessus de cette barre, donc au-dessus de l'indicateur — on ne découvre rien.
- **En app INSTALLÉE, l'arbitrage s'inverse, et c'est pourquoi la règle est dédoublée** : sans
  barre d'outils, `svh` descend jusqu'au bord de l'écran, indicateur compris — mais l'inset y est
  constant, faute de chrome qui bouge. Il est retranché sous `@media (display-mode:standalone)`,
  et là seulement.
- **Règle générale** : dans une hauteur qui doit être stable, `env(safe-area-inset-bottom)` est
  aussi suspect que `--vvh`.
- **Témoin STATIQUE, et c'est délibéré** (4 contrôles) : les deux termes fautifs sont **invisibles
  en headless** — `--vvh` y vaut une hauteur qui ne varie jamais faute de barre d'outils, et
  l'inset y vaut 0, qu'aucune API ne permet de simuler. Un contrôle dynamique serait donc resté
  VERT sur le défaut, le pire cas du dossier. On mesure la SOURCE : la hauteur du rail étroit ne
  cite ni `--vvh`, ni `dvh`/`lvh`, ni l'inset bas hors de la branche `standalone`. Vérifié capable
  d'échouer (terme réintroduit → rouge, fichier restauré à l'octet).

#### Et la vraie cause, signalée **depuis la PWA** — donc sans barre d'outils ni inset qui bougent

Les deux points ci-dessus étaient justes mais **ne pouvaient pas expliquer** le défaut chez
quelqu'un qui n'a ni barre d'outils ni marge basse variable. Deux dernières entrées dynamiques
restaient, toutes deux invisibles sur Blink et toutes deux actives en PWA.

- **Un saut se calcule désormais en ABSOLU, jamais en relatif.** Le saut était un déplacement
  RELATIF (`scrollBy`, `scrollTop +=`) dont le pas se déduisait d'un `getBoundingClientRect()` —
  c'est-à-dire de la position **déjà rendue** — puis s'ajoutait à la position **courante**. Sur
  Blink les deux sont la même chose, le défilement étant synchrone : la sonde le confirme (course
  monotone de 0 à 1908 px, aucune oscillation). **Sur iOS le défilement est asynchrone** : pendant
  un glisser, le rect peut refléter une position que le compositeur n'a pas encore appliquée alors
  que `scrollY` est déjà à jour. On ajoute alors un pas déjà parcouru — on dépasse —, le mouvement
  suivant calcule un pas négatif pour corriger, et à 60 évènements par seconde cela devient une
  **oscillation : on descend, ça remonte**. La cible est calculée dans les offsets de mise en page
  (indépendants de toute position de défilement) et posée en absolu : deux appels pour la même
  lettre visent exactement le même point, **idempotent par construction**.
- **La boîte du rail est gelée dans `--azr-top`, posée au rendu.** C'était la dernière entrée
  dynamique de sa géométrie : le haut valait `--hdr-h`, propriété que `syncHdrScroll` **réécrit à
  chaque défilement** depuis un rect de l'en-tête **collant**. Sur Blink un sticky est repositionné
  avant l'évènement, donc la mesure est toujours juste (vérifié : `--hdr-h` constante sur toute la
  course) ; sur iOS, où défilement et collants sont composités, rien ne le garantit — et le rail
  étant FIXE, une seule valeur transitoire lui déplace le haut **et** la hauteur, donc son centre.
  Le haut est mesuré au rendu, puis reposé au redimensionnement et à la rotation seulement.
- **Géométrie inchangée au repos**, mesuré avant/après : boîte à 168 px de haut sur 670 px de
  haut à 390 px, saut atterrissant à 8 px sous les couches collantes dans les deux dispositions.
- **Témoins** (9 de plus) : statiques pour ce qu'aucun moteur headless ne reproduit (le saut ne
  cite ni `scrollBy` ni `scrollTop +=` ; la boîte passe par `--azr-top`), dynamiques pour ce qui
  se mesure (la lettre atterrit sous les couches collantes ; **deux sauts de suite ne déplacent
  plus rien**, l'idempotence étant ce qui casse l'oscillation), à 390 et 1100 px — les deux voies
  de défilement. Vérifiés capables d'échouer, fichier restauré à l'octet.

#### Et la cause restante n'est pas une mesure : c'est le REBOND de fin de page

Signalé à l'usage : « ça se produit quand on arrive en fin de scroll de page, quand il y a le
bounce ». C'est l'observation qui manquait — et elle explique pourquoi aucun des correctifs
précédents ne pouvait suffire.

- **Pendant le rubber-band, WebKit TRANSLATE le document *et* les éléments `position:fixed`.** Le
  rail part avec le rebond, puis revient — sous le doigt qui le vise. Ce n'est pas une valeur qui
  change : c'est une transformation appliquée au rendu, par le compositeur, **en dehors de toute
  mesure lisible en JS**. Aucune formule de hauteur ne s'en protège, et aucun moteur headless ne
  la reproduit.
- **`overscroll-behavior-y:none`, et SEULEMENT PENDANT LA VISÉE** (`html.azr-aim`, posée au
  `pointerdown` sur le rail, retirée au relâchement). ⚠ Le premier jet la posait en permanence sur
  l'accueil : le rail était corrigé, mais **sur WebKit `overscroll-behavior` n'ampute pas que le
  rebond — il ampute aussi l'INERTIE** (signalé à l'usage : « le scroll des cartes n'est plus très
  ergonomique, s'arrête, est lent »). Le geste le plus fréquent de l'écran payait donc le confort
  d'un geste rare. Bornée au geste, la règle a aussi la portée juste : le rebond n'a besoin d'être
  supprimé que pendant qu'on vise une surface fixe. Elle est posée au `pointerdown` — donc avant
  que WebKit ne fige les propriétés du défileur pour la séquence tactile, les évènements pointeur
  y précédant les évènements tactiles — et un **filet** la retire au niveau du document (en
  capture) et au passage en arrière-plan : une classe restée posée serait le défaut d'origine, en
  pire, parce que rien ne le dirait.
- **Borné au palier étroit** : en voie large l'accueil est une coque fixe (le document ne défile
  pas) et le rail y est `absolute` dans le flux — le rebond ne l'a jamais déplacé. Les fenêtres
  gardent leur `contain`. La déclaration vit sur `html` **et** sur `body` : la propagation vers le
  viewport se fait depuis la racine, la poser sur le corps seul est sans effet.
- **Témoins** (9 de plus) : ceux-ci **se mesurent**, et c'est la PORTÉE qui est vérifiée, pas la
  présence — au repos le défilement du document est celui du système, pendant la visée le rebond
  est supprimé, au relâchement il revient ; intact en lecture, intact à 1100 px même pendant la
  visée, `contain` intact sur les fenêtres. Vérifiés capables d'échouer dans les deux sens (règle
  retirée → rouge ; règle reposée en permanence → rouge sur « au repos »). 643 contrôles doctrine.

## [5.0.1] — 2026-08-02
### Le rail A→Z cesse de bouger sous le doigt

Signalé à l'usage, vidéo à l'appui : « il bouge sous mon doigt alors qu'il est censé rester fixe ».

- **La hauteur du rail étroit passe de `--vvh` à `100svh`.** En voie étroite, le rail est
  `position:fixed`, borné en haut par `--hdr-h` et en hauteur par `--vvh` —
  c'est-à-dire `visualViewport.height`, **la mesure qui suit la barre d'outils du navigateur
  mobile**. Or cette barre se replie précisément **pendant** un défilement : la boîte grandit, les
  lettres centrées descendent de la moitié de l'écart, la lettre visée change sous le doigt, le
  rail défile ailleurs — et comme viser une lettre FAIT défiler, l'asservissement s'entretient
  lui-même. C'est le défaut de la v4.73.0, revenu avec le recentrage de la v5.0.0, qui avait gardé
  la hauteur dynamique. `100svh` est le **small viewport** : la hauteur qu'a la fenêtre barre
  d'outils déployée, donc une constante que ni le défilement ni le repli ne touchent. La boîte ne
  peut jamais dépasser le bord visible (elle est bornée par le plus petit des deux états), et le
  test de débordement de `bindAzRail` — celui qui masque le rail plutôt que de couper des lettres —
  devient fiable, n'étant plus mesuré sur une hauteur qui change d'un instant à l'autre.
  **Le centrage vertical est conservé** (décision de l'auteur, v5.0.0) : ce qui est corrigé est la
  BOÎTE, pas l'alignement.
- **Le mapping doigt → lettre est relevé UNE FOIS, à la prise.** Il était re-mesuré à chaque
  mouvement : toute géométrie qui bougeait pendant le geste changeait la lettre visée sans que le
  doigt bouge. La boîte étant désormais constante, ce relevé unique ne change plus rien en
  pratique — il rend le geste insensible **par construction** à une géométrie qui bougerait demain,
  et il tient la discipline du projet (dans une phase de lecture, on ne lit qu'une fois).
- **Témoin** dans `audit-doctrine` (330 · 390 · 700 · 1000 · 1400 · 1600 px) : on simule le repli
  de la barre en posant `--vvh`, et l'on mesure le déplacement de la **première** lettre — c'est
  elle que le doigt vise. Vérifié capable d'échouer : avec l'ancienne règle, **60 px** de
  déplacement sur les trois largeurs étroites ; 0 px après. 620 contrôles doctrine (614 avant).

## [5.0.0] — 2026-08-02
### Le modèle v4, la bibliothèque unique, et six échelles qui cessent d'être déclaratives

Première **majeure** depuis la 4.0.0, et la première **rupture de format** du projet. Elle regroupe
83 livraisons faites sous le numéro 4.79.0 : le chantier v5 était conçu pour sortir d'un seul
tenant, parce que ses lots se conditionnent les uns les autres — le modèle v4 rend énonçable la
bibliothèque unique, qui rend énonçable le retrait du rail ①②③.

---

#### ⚠ AVANT DE DÉPLOYER — deux gestes, dans cet ordre

**1. Convertir les données.** La règle 12 (« ne jamais supprimer un champ du modèle ») a été
**levée explicitement par l'auteur**, et ce qui la remplace exige un chemin de reprise écrit AVANT
la rupture : c'est `docs/conversion-v3-vers-v4.md`. Mesuré : une aide v3 lue par la v5 **perd les
étapes de ses blocs**, en silence — les listes du haut de fiche (critères, « Ne pas oublier »,
surveillances, posologie, différentiels) sont, elles, récupérées. Et la perte devient définitive à
la première écriture, l'éditeur enregistrant en continu depuis la v4.72.0.

La conversion d'un fichier ne convertit ni la base, ni l'IndexedDB des autres appareils. Le
contrôle à passer avant de publier :

```sql
select count(*) filter (where data->'items' is null) as reste_v3, count(*) as total
from public.cognitive_aids;
```

Tant que `reste_v3` n'est pas à zéro, déployer exposerait les autres membres des bibliothèques
partagées à des fiches vides.

**2. Rejouer `supabase/schema.sql`.** Renommage de table (bloc idempotent + vues de compatibilité
`security_invoker`), colonnes `discriminant` et items dans la liste blanche du partage. Sans lui,
un invité recevrait des blocs pleins d'identifiants ne résolvant vers rien — c'est-à-dire une
checklist vide en pleine réanimation, sans le moindre signal.

---

#### Le modèle v4 — l'item devient un objet à identité

Une étape était une **chaîne à une position** (`b.steps[3]`), et le projet l'a payé deux fois : un
compte rendu de soin qui nomme le mauvais geste après une insertion, et l'impossibilité d'accrocher
quoi que ce soit à une étape autrement que par son rang — c'est-à-dire par la chose même qui bouge.

`f.items[]` est désormais **le pool** des items de l'aide, toutes portées confondues, et un bloc ne
porte plus que des **identifiants**. Les cinq listes v3 (`confirmation`, `notForget`, `verify`,
`posology`, `differentials`) n'existent plus comme champs : ce sont des **rôles**
(`entry`, `do`, `watch`, `dose`, `ddx`). Le préfixe `⚠`/`△` devient `level` 1-3 — ordonné, donc
comparable —, et `::` devient `do`/`expect`.

Deux propriétés qu'une chaîne ne pouvait pas porter apparaissent : **`memory`** (★, l'étape reste
dans son bloc *et* rejoint « Ne pas oublier ») et **`dual`** (×2, le double contrôle qu'exige
AC 120-71B §5.2.2.5 — la seule exigence explicite de la doctrine que le modèle ne savait pas
exprimer). Plus `phase` (héritée du bloc précédent), `discriminant`, `onDue`, `aidRev`.

Renommages de l'étape C : `libraryId`→`library`, `validation`→`validatedAt`,
`references`→`sources`, `attachments`→`docs`, `related`→`links`, `localInfo`→`local`,
`complications`→`excursions` ; le bloc passe de `type` à `kind`, et l'aide **se déclare**
(`v:4`, `kind:'procedure'|'reference'`).

#### La bibliothèque est unique, le type est un filtre

Choisir « Aides » ou « Protocoles » était une **décision préalable** : il fallait savoir de quel
type était ce qu'on cherchait avant de pouvoir le chercher. Or le type est une propriété de
l'auteur, pas du lecteur, qui cherche un sujet. Le répertoire A→Z réunit les deux, le type devient
un filtre à trois crans (« Tout » par défaut), et la **tab bar basse disparaît** — 62 px de hauteur
permanents rendus.

Côté serveur, la table `fiches` devient `cognitive_aids` : un nom qui ment coûte plus cher qu'un
renommage, et celui-ci se fait par un bloc idempotent doublé de vues de compatibilité.

#### La vue de crise — l'action passe devant l'orientation

Mesuré à 320 × 640, session démarrée : la première étape cochable naissait à **y = 721 px pour un
pli à 640**. Zéro ligne à cocher à l'écran au moment de démarrer un soin. Une checklist qui
n'affiche aucune ligne actionnable n'est pas une checklist, c'est un sommaire.

Le **rail ①②③** est retiré partout (deux numérotations concurrentes dans la même colonne sont deux
vocabulaires pour situer un même geste), le chapeau « Ne pas oublier » se replie une fois la
session démarrée, le journal des actions remonte sous la carte du bloc, et le bandeau-titre
disparaît en crise ordinaire — la barre porte déjà le titre en permanence. Cumul mesuré : première
étape à **361 px** au lieu de 438, soit 56 % de l'écran au lieu de 68 %.

Le sélecteur « Guidé / Statique » est remplacé par un **axe de densité** — « Un bloc » / « Toute la
fiche », cette dernière à trois onglets (Parcours, Page SFAR, Schéma). Un segmenté **remplace la
vue et ne ramène personne** : on prend du recul, et si l'on n'y repense pas on termine le soin dans
un format qu'on n'avait pas choisi. Le contrôle **nomme sa destination** (« ⤢ Tout voir » /
« ↩ Un bloc »), à position constante, et une excursion **n'écrit pas la préférence** — le format
par défaut se règle à froid, dans Compte › Affichage.

Le **mode lecteur est retiré** : mesuré, il ne gagnait qu'à 320 px (63 % de l'écran aux étapes
contre 36 %) et **perdait à 390** (47 % contre 59 %). Sa doctrine avait d'ailleurs été abandonnée
dès la v4.28.0.

#### Le design system cesse d'être déclaratif

Quatre échelles fermées deviennent **auto-exécutoires**, parce que partout où une règle est restée
déclarative, elle a fui : l'espacement n'avait **aucun token** (1 356 déclarations de 1 à 26 px),
les rayons avaient **dix-neuf valeurs pour trois tokens**, et les paliers de largeur comptaient
**douze valeurs réelles pour neuf déclarées** — dont un palier déclaré qui n'existait nulle part.

S'y ajoute un **quota du plancher typographique** : 11 px était employé **173 fois sur ~520
déclarations**, soit la taille la plus utilisée de toute la feuille. Un plancher employé 173 fois
n'est plus un plancher, c'est le corps de texte du produit. Chaque déclaration prise isolément
était pourtant légale — rien ne pouvait le voir.

L'**accent** est confiné au disque de l'avatar : il teintait l'accueil entier et l'en-tête de
toutes les vues, c'est-à-dire la seule couleur du produit qui ne portait **aucun sens**, dans un
système dont la règle fondatrice est que la couleur en porte toujours un. 70 hex sur 104 ; il en
reste 10. Le thème sombre descend à `#0a0a0c` (le noir pur maximise la halation autour du texte
clair — gênant pour les personnes astigmates).

Et **une étape cochée redevient lisible** : `opacity:.6` + barré + encre douce composaient un texte
à **2,55:1 en clair et 1,95:1 en sombre**, sur l'état le plus fréquent de toute l'application. La
sonde d'accessibilité ne pouvait pas le voir — elle composait l'alpha des couleurs mais ignorait la
propriété `opacity`. Après : **5,93 et 11,15**.

#### Les garde-fous

Sept contrôles neufs, tous statiques donc joués à chaque commit : `check-space`, `check-radius`,
`check-paliers`, `check-upload`, `check-harnais`, `check-icons`, plus `audit-budget` — **le premier
harnais qui mesure une répartition** et non une propriété isolée (chrome permanent ≤ 30 % de la
hauteur, au moins une étape cochable visible sans défiler).

`audit-a11y` mesure désormais des **états** et non seulement des surfaces : il ouvrait tout au
repos, et deux violations AA vivaient à l'écran sans qu'il les voie. `npm run audit` passe à un
lanceur **parallèle à rapport agrégé** : la chaîne `&&` payait la somme des durées (9 min 42 s) et
son fail-fast cachait tout ce qui suivait le premier rouge.

#### Sécurité et données

Toute entrée de fichier passe par **une seule porte** (`UP_KINDS` + `acceptFile`) : quatre chemins
cohabitaient avec quatre niveaux de rigueur, et deux d'entre eux ne vérifiaient qu'un `accept` —
c'est-à-dire une indication donnée au sélecteur, jamais une garantie. Le SVG en est exclu
délibérément (seul format image à contenu actif) ; le HEIC y entre (c'est le format de la
photothèque iPhone). Le **dépôt hors zone** est neutralisé : un fichier lâché à 3 px d'une zone
faisait naviguer le navigateur vers ce fichier, effaçant l'écran — y compris une session en cours.

Et **mettre à jour pdf.js ne mettait pas pdf.js à jour** : le service worker le range dans un cache
versionné par lui-même et n'écrit que ce qui manque. Remplacer les fichiers sans toucher la clé
laissait chaque appareil déjà installé avec l'ancienne bibliothèque, indéfiniment et sans un mot —
le pire mode de défaillance pour un composant qui analyse du contenu non maîtrisé.

#### Identité

La marque devient un **chronomètre coché à onglet** : le temps, la validation et le protocole dans
un seul signe. Toutes les icônes servies sont régénérées depuis **une géométrie unique**
(`scripts/build-icons.mjs`) — dix rasters dessinés à la main divergent.

---

#### Vérification

`npm run check` (13 contrôles) · `npm test` **880 tests, 0 échec, sur Chromium ET WebKit** ·
`npm run audit` **18/18 harnais** (a11y 513, doctrine 614, partage 291) · `design:check` à jour.

Chaque correctif de ce chantier a été **vérifié capable d'échouer** — défaut réintroduit, contrôle
rouge, fichier restauré à l'octet : un garde-fou qui ne peut pas échouer ne prouve rien.

## [4.79.0] — 2026-07-30
### Ce qui est inerte pendant un déplacement en a enfin l'air

Demande utilisateur : *« grise les boutons supprimer et B en mode déplacement pour qu'on comprenne
qu'ils ne sont pas utilisables ; n'oublie pas de les dégriser lorsqu'on sort du mode »*.

#### Le diagnostic : inertes, mais d'aspect actif
Ils étaient bel et bien inertes depuis la **v4.77.0**, qui a rendu le
déplacement **modal** au moyen de l'attribut natif `disabled`. Mais nos boutons portent leurs propres
`background` et `color` : le grisé par défaut du navigateur n'apparaissait donc **nulle part**.
Mesuré avant correction : `disabled:true`, et pourtant `color:rgb(163,46,31)` — le ✕ d'une étape
restait rouge vif — avec `cursor:pointer`.

C'est la pire configuration possible : un contrôle qui ne répond plus **sans dire qu'il est fermé** se
lit comme une panne, pas comme un mode. La v4.77.0 avait choisi `disabled` justement parce qu'il donne
« le grisé, la sortie du parcours de tabulation et le blocage du geste » — deux des trois seulement
étaient vrais, et personne ne l'avait mesuré.

#### L'apparence vient du scribe, au trait près
Encre douce, filet neutre, fond `--surface-2`, ombre retirée, `cursor:not-allowed` : exactement
`body.share-scribe`. **Une seule grammaire de « fermé » dans tout le fichier** — en inventer une
seconde ici obligerait à les tenir accordées, et c'est le genre de dette que ce dossier a déjà payée
plusieurs fois.

**Pas d'`opacity`**, pour deux raisons qui se cumulent : la doctrine du projet l'écarte pour du texte
(un texte à demi-opacité tombe sous AA), et surtout un voile affadirait aussi les registres **rouge et
ambre** des rangées signalées — or ce sont eux qui portent le sens clinique. WCAG 1.4.3 exempte
explicitement les composants **inactifs** du seuil de contraste : on baisse donc le contraste par
l'**encre**, franchement, plutôt que par un filtre.

#### Le dégrisage est structurel, pas un geste symétrique
La règle porte sur `:disabled`, et l'attribut n'est posé que par le rendu où `state.edGrab` existe :
reposer l'objet re-rend sans lui, et l'état visuel s'en va **avec** l'attribut. Il n'y a donc rien à
défaire à la main — donc rien à oublier. C'est précisément la leçon que la liste de placards de la
v4.78.0 a coûtée : un état qu'on pose à la main est un état qu'on oublie de retirer quelque part.

#### Deux choses restent actives, à dessein
La **poignée ⠿** (il faut pouvoir prendre un autre objet, ou reposer celui-ci) et le **✕ du bandeau**.
Le témoin les mesure aussi : « tout griser » sans exception aurait enfermé l'utilisateur dans le mode.

#### Vérifications
809 tests × 2 moteurs, `npm run check` vert, **seize harnais verts** (`npm run audit` en sortie 0),
a11y 301/301, doctrine 159/159, `audit-k5` **123/123**. **Six nouveaux témoins**, dont un qui vérifie
d'abord que le contrôle **rencontre son cas** — que le ✕ d'étape est bien rouge au repos, seul endroit
où la spécificité pouvait échouer (contre `.blk .li .mini`, à (0,3,0)). Défaut réintroduit : trois
rouges, dont la trace `dis:true / rgb(163,46,31) / pointer` qui est exactement le symptôme signalé.

## [4.78.0] — 2026-07-30
### Douze défauts signalés à l'usage — dont huit créés par les trois versions précédentes

Cette version ne fait presque que réparer, et la plupart des réparations portent sur du travail
récent. Deux enseignements en ressortent, plus utiles que les correctifs eux-mêmes : **un `::before`
est un élément de flex comme les autres**, et **toute réconciliation au rendu peut défaire le geste
qu'on vient de faire**.

#### « Schémas & captures » n'agrégeait pas — puis retirait mal
« Une image ajoutée depuis un bloc via ＋ Image/Capture ne s'affiche pas dans la galerie, alors que
l'inverse est vrai. » Asymétrie de **modèle** : la galerie est `f.images[]`, l'image d'un bloc est
`b.image` (la donnée elle-même), et « ＋ Image » n'écrivait que la seconde — la galerie ne pouvait pas
montrer ce qu'elle prétend rassembler, et le sélecteur de bloc de la v4.76.0 n'avait rien à
sélectionner.

`edSyncGallery(f)` réconcilie **au rendu**, pas au point d'ajout : c'est ce qui rattrape les fiches
**déjà écrites**, dont les images de bloc n'ont jamais eu d'entrée de galerie. Idempotente, purement
additive, aucun champ nouveau. Elle n'est **pas** dans `migrate()` à dessein — `migrate` court sur
toute donnée entrante, pull de synchro compris, et grossirait `images` sur des fiches qu'on ne fait
que lire.

**Et elle a immédiatement créé son propre défaut** : « cliquer sur retirer une image ne la retire pas,
elle apparaît toujours dans la liste ». On la sortait de `f.images`, un bloc la portait encore, la
réconciliation la remettait au rendu suivant. Il fallait donc trancher une question que l'agrégateur
pose : **« Retirer » dans la galerie retire l'image de l'aide entière** (galerie *et* tout bloc qui la
porte), tandis que « Aucun bloc » — ou le « Retirer » d'un *bloc* — ne fait que **détacher**, la
vignette restant disponible. Sortir de la galerie, c'est ne plus faire partie de l'aide.

#### Le compteur prend l'anatomie de la carte de minuteur
C'était une rangée flex **plate** de sept objets avec `flex-wrap` : sur écran étroit, ⠿ et ✕
atterrissaient n'importe où dans l'enroulement, jamais au même endroit d'une rangée à l'autre. K7
(v4.70.0) avait déjà résolu le problème pour le minuteur — un en-tête (nom · ⠿ · ✕) puis les réglages
dessous. On reprend la même carte, aux **mêmes classes** : pas une ligne de CSS nouvelle. `.trow` est
purgé (règle 14, zéro émission vérifiée), et la poignée s'aligne sur la croix par `align-self:stretch`.

Deux conséquences, signalées aussitôt. **Les sélecteurs de chiffres** : `.field input[type=text]` porte
le gabarit de tous les champs du projet mais il est borné à `[type=text]` — `input[type=number]` n'en a
**jamais** rien reçu. Les compteurs vivaient sur `.trow input[type=number]`, partie avec `.trow` ; les
minuteurs, sur le style **par défaut du navigateur** (bordure 2 px « inset ») depuis toujours. Aggravé
par une addition à la liste qui pose `--line-strong` : sur une bordure UA, changer la seule *couleur*
donne un cadre épais et sombre. Les minuteurs y gagnent enfin le gabarit qu'ils n'avaient pas.

**Et le défilement vers l'objet créé** : minuteurs et compteurs partageant désormais `.tmedit`, viser
la classe amenait au **dernier** du formulaire — donc au dernier *compteur*. On distingue par
l'attribut d'index (`data-ti` / `data-ci`). Le témoin a dû être renforcé : créer un compteur en dernier
ne prouvait rien, la cible ambiguë tombait juste par hasard.

#### Un `::before` est un élément de flex
« Tout le champ texte est rétréci au profit d'un “En déplacement” qui prend beaucoup de place pour
rien. » La marque de l'objet pris est un `::before` en `width:100%`, donc un **item** de la rangée.
Dans `.blk .li`, `flex-wrap:wrap` l'envoyait sur sa propre ligne ; `.list-edit .li` n'avait pas cette
règle, et la marque volait la largeur au champ — **mesuré 712 px → 28 px**.

#### Une liste de placards se parcourt, elle ne s'énumère pas
« Appuyer sur Essayer puis revenir en édition — quand on scrolle, l'en-tête reste hachurée. » La
branche de nettoyage retirait `exo` et `inv` mais pas `ess`, ajoutée en v4.76.0 : le troisième placard
avait été posé à quatre endroits et oublié au cinquième. La liste est désormais unique et parcourue.
Même leçon que `MUTE_SEL`/`LEAD_ONLY_SEL` — une liste tenue en double finit par diverger, et le défaut
est **silencieux**.

#### Un re-rendu rend le focus au champ qu'il vient de remplacer
« Appuyer sur le bouton critique/vigilance referme le bandeau — il faut de nouveau sélectionner. » La
bascule ⚠/△ re-rend l'éditeur, donc l'`<input>` est un **nouveau** nœud : focus perdu, `:focus-within`
tombé, outils disparus. Or qualifier une étape est un geste qu'on **enchaîne**. `preventScroll` parce
que la position est déjà la bonne : c'est le geste de l'auteur, pas une navigation.

#### Un chronomètre ne sonne pas, et l'éditeur doit le dire
Le champ « À l'échéance » (`onDue`, K7) lui était proposé — on demandait à l'auteur d'écrire l'annonce
d'une alarme qui ne se déclencherait jamais. Un chronomètre **compte**, un cycle **sonne** : le champ
n'appartient qu'au second, et la carte du chronomètre dit maintenant pourquoi elle ne sonne pas.

#### Un bloc sans titre se nomme, il ne s'identifie pas
Le sélecteur de cible de complication affichait `b_lz8q3`, qui ne dit rien à personne — et surtout pas
lequel des deux blocs sans titre on choisit. On donne le **rang** (« Bloc sans titre (2) »), seule
information qui les distingue, et c'est la position que l'auteur voit à l'écran. `targetSelect`
(« Étape suivante ») écrivait « (bloc sans titre) » sans rang : même règle.

#### La profondeur d'un objet arrondi est son ombre, pas un voile
Deux reproches, tous deux justes, qui invalident ma première tentative. Un dégradé posé en `::before`
est un **rectangle** : ses angles ne suivent pas le rayon, et sur une carte blanche il se lit comme une
bande grise à bords vifs. Et il montait vers `--bg`, la couleur du **fond de page** : il *éclaircissait*
au lieu d'assombrir — à l'envers, littéralement.

Le bon outil pour un objet arrondi qui flotte est **sa propre ombre**, qui épouse le rayon par
construction ; et pour une barre collée en bas elle doit se répandre **vers le haut**, du côté d'où
vient le contenu. D'où le token `--shadow-up` (les ombres sont tokenisées depuis la v4.37.0, jamais
écrites en clair) : mêmes encres et mêmes alphas que `--shadow-lg`, décalage inversé. Rien d'autre.

#### Deux règles `:hover` de même spécificité, l'ancienne gagne
En passant « Noter l'heure » en tonal j'avais ajouté `.tk-add:hover{--primary-100}` sans retirer
l'ancien `.tk-add:hover{--primary-hi}`, le remplissage de survol d'un bouton **plein** — d'où un survol
sombre sur un fond clair, l'inverse du sens de lecture. Corollaire du piège de cascade déjà documenté :
quand on change le **registre** d'un composant, chercher toutes ses règles d'état, pas seulement sa
règle de base.

#### Vérifications
809 tests × 2 moteurs, `npm run check` vert, **seize harnais verts** (`npm run audit` en sortie 0),
a11y 301/301, doctrine 159/159, `audit-k5` **117/117**, prompt 13/13, partage 298/298. **Vingt-deux
nouveaux témoins**, tous vérifiés capables d'échouer — dont deux qui ont dû être **refaits** parce
qu'ils ne rencontraient pas leur défaut : l'un mesurait un nœud détaché, l'autre créait ses objets dans
l'ordre où la cible ambiguë tombait juste par hasard. Un contrôle qui ne rencontre pas le défaut ne le
couvre pas.

## [4.77.0] — 2026-07-30
### Ce que les trois lots avaient cassé — et deux règles de saillance remises d'aplomb

Huit défauts signalés à l'usage, sept venant des lots 1 à 3. Le plus instructif n'est pas un défaut
mais un **trou de vérification** : le pane du navigateur intégré ne déclenche **ni `resize` ni
`matchMedia change`** sur un redimensionnement CDP — vérifié à la sonde. Un franchissement de palier
n'y est donc pas éprouvable, et c'est exactement là qu'un défaut survit à une vérification manuelle.
Playwright, lui, les émet : le témoin est passé par lui.

#### L'éditeur ne suivait plus les paliers
`_onReadBp` ne re-rendait qu'en vue `read`, alors que l'éditeur change de **structure** au même seuil
que la lecture : à ≥ 1000 px le schéma vit dans la colonne collante, en dessous il est entrebâillé
dans le flux. Redimensionner laissait donc la page telle qu'elle avait été **rendue** — schéma en bas
d'un formulaire large, ou colonne absente sur un grand écran. Le trou préexistait (les trois colonnes
de K11 l'avaient aussi) ; le lot 1 l'a rendu visible en donnant au schéma deux logements très
différents. Règle : toute vue dont la structure dépend d'un palier doit être listée là.

#### Abandonner un déplacement décalait l'écran
Prendre et poser étaient ancrés depuis MK5-b ; **abandonner ne l'était pas** — le ✕ et Échap
faisaient un `renderEditor()` nu, le retrait des interstices raccourcissait la page de leur hauteur
cumulée, et l'écran remontait d'autant. Défaut réintroduit pour éprouver le témoin : **−223 px au ✕,
−446 px à Échap**. Un geste **annulé** ne doit rien déplacer, pas même le regard.

#### Le déplacement devient un geste modal
Deux défauts en un. La même poignée **repose** maintenant l'objet : un interrupteur qui ne s'éteint
que par un ✕ ailleurs à l'écran n'est pas un interrupteur. Et le reste du formulaire est **inerte** —
c'était le plus coûteux des trois lots : on pouvait modifier ou **supprimer** l'objet tenu lui-même,
ou celui qui précède la destination, et l'index gardé dans `state.edGrab` désignait alors autre chose.

Par l'attribut natif `disabled`, pas par du CSS : il donne le grisé, retire du parcours de tabulation
et empêche le geste — trois propriétés qu'aucune règle de style ne donne ensemble. Ce n'est pas le
patron `share-scribe`, qui garde les contrôles cliquables pour **annoncer** un refus : ici il n'y a
rien à annoncer, un contrôle éteint pendant qu'un objet est « en main » se comprend seul.

Le bandeau de déplacement **quitte** le fieldset « Prise en charge » et couvre tout le formulaire :
déplacer une ligne de « Ne pas oublier » n'affichait son bandeau qu'à partir de « Prise en charge ».

#### Les outils ⚠ et ✕ d'une étape ne fonctionnaient pas
Le diagnostic est une **séquence**, pas un style. `.li-tools` n'existe qu'en `:focus-within`
(MK-flux) ; presser un outil déplaçait le focus hors du champ, `:focus-within` devenait faux, les
outils passaient en `display:none` — et le `mouseup` retombait dans le vide, donc **aucun `click`
n'était émis**. On voyait « le menu se replier » parce que c'est littéralement ce qui se passait.
`preventDefault()` sur `pointerdown` annule la mise au point sans annuler le clic.

Corollaire de méthode pour le témoin : il fallait de **vrais clics** Playwright. Un `.focus()`
programmatique ne déclenche pas `:focus-within` de façon fiable en headless — même leçon que l'anneau
de focus d'`audit-a11y`, qui a dû passer par de vraies touches Tab.

#### Le guide rouge/ambre est replié par défaut
La v4.31.0 l'ouvrait d'office pour qu'un nouveau venu voie la leçon ; l'usage dit l'inverse : il se
répète sur **chaque** bloc d'étapes, si bien qu'une fiche à quatre blocs affichait quatre fois le
même paragraphe. La pédagogie est ailleurs depuis la v4.65.0 — c'est la porte « ＋ » qui présente les
registres au moment où on **choisit**. Clé renommée (`ac-cg-open`) : réutiliser l'ancienne aurait
rouvert le guide chez tous ceux qui l'avaient replié, c'est-à-dire puni ceux qui avaient fait le geste.

#### La bascule guidé ↔ statique ne remonte plus en haut
La v4.74.2 ancrait sur le bloc **courant**, ce qui ne vaut que si une session est démarrée : sans
elle, aucun `.cur` n'existe et l'on retombait sur `scrollTo(0,0)` — donc le saut décrit, aggravé par
l'en-tête qui se redéploie au passage. L'ancre juste n'est pas « le bloc courant » mais **ce qu'on
regarde** : le premier bloc dont le bas passe sous les couches collantes. Les deux vues portent l'id
de bloc dans un attribut (`data-ovb` / `data-svgo`), donc l'ancre se **traduit** d'une vue à l'autre —
d'où un second sélecteur d'arrivée dans `keepAnchor`.

#### « Rien ne se passe » quand la porte crée un minuteur
Rien n'était masqué : la section réapparaît bien, mais elle est en bas d'un formulaire de plusieurs
milliers de pixels, et seules les **listes** avaient droit à l'ancrage. Un minuteur, un compteur, une
complication ou un bloc naissaient hors de l'écran. La règle « on amène l'auteur sur ce qu'il vient
de créer » valait depuis la v4.65.0 ; elle n'était appliquée qu'au quart.

#### Deux règles de saillance remises d'aplomb
**« Noter l'heure » n'est pas l'action primaire de l'écran.** Il l'était : en session, l'écran porte
déjà « Continuer — … → », et c'est lui qui fait avancer le soin ; un second aplat bleu mettait un
horodatage au même niveau de saillance qu'un geste de checklist. Il passe tonal, cible et place
inchangées.

**La porte « ＋ » devient l'unique bouton rempli de l'éditeur, et « ▶ Essayer » passe en tonal.**
C'est un arbitrage, pas un détail : l'action primaire d'un **éditeur** est d'écrire, la porte est
l'entrée de l'écriture, dérouler son brouillon vient après. La règle « un seul bouton rempli par
écran » (v4.0.3) est donc tenue, dans l'autre sens. **Refusé** : un second `＋` dans l'en-tête — ce
serait la dispersion que la v4.65.0 a supprimée.

#### La synchro d'historique devient une ligne
Un bouton pleine largeur empruntait la forme d'une **action** pour porter un **état**. C'est
désormais une ligne « libellé à gauche, contrôle à droite » au gabarit des autres réglages depuis M5,
avec sa pastille — verte `--ok` quand c'est « Oui », et le **mot** l'accompagne toujours (règle 8).

#### Le prompt IA : les libellés se relisent après le soin
Remarque exacte, et plus forte que sa formulation : les `label` de `timers` et de `counters` nomment
les repères du **journal des actions** et les compteurs du **compte-rendu**, où ils sont lus hors
contexte, parfois par quelqu'un qui n'était pas là. Consigne ajoutée — 2 à 4 mots, l'unité entre
parenthèses (« Adrénaline (mg) »), jamais « Compteur 1 », jamais une phrase — avec son témoin.

#### Ce qui n'a pas changé, et pourquoi
**L'anneau d'annulation reste pas-à-pas**, sans liste des cinq derniers gestes : nommer chaque point
de reprise exigerait un libellé par site de mutation, exactement la liste à maintenir que `edCommit`
et `persistLive` ont permis de ne pas écrire, et qui divergerait au premier geste ajouté. Presser
trois fois « ↶ » donne le même résultat qu'un menu à trois entrées, sans ce coût. Le plafond reste
20 — au-delà ce n'est plus une annulation mais une restauration, et elle a son outil (« Versions »).

#### Vérifications
809 tests × 2 moteurs, `npm run check` vert, **seize harnais verts** (`npm run audit` en sortie 0),
a11y 301/301, doctrine 159/159, `audit-k5` **93/93**, prompt 13/13, partage 298/298. **Dix-sept
nouveaux témoins**, tous vérifiés capables d'échouer. Un témoin antérieur corrigé au passage : il
laissait un objet « en main », ce qui — depuis que le déplacement est modal — éteignait silencieusement
tous les contrôles mesurés ensuite. Un témoin qui laisse un état derrière lui fait échouer les autres
pour la mauvaise raison.

## [4.76.0] — 2026-07-30
### Lot 3 : la porte devient celle de l'aide entière

#### La porte « ＋ » quitte « Prise en charge »
Signalé à l'usage : *« le bouton s'arrête avant les blocs minuteurs & compteurs, repères
posologiques, schémas et captures, documents PDF… ce qui n'est pas logique »*. Le constat était plus
juste encore que sa formulation : la porte créait **déjà** des minuteurs, des compteurs, des
complications et des repères posologiques, tout en vivant **à l'intérieur** du fieldset « Prise en
charge ». Ce n'était donc pas une porte de bloc, c'était la porte de l'aide, mal rangée.

Elle sort du fieldset, se pose à la fin du formulaire, colle sur toute sa hauteur, et se répartit en
quatre groupes dans l'ordre de **lecture** de la fiche : Structure · Pendant la session · Contenu
clinique · Annexes. Nouvelles entrées : « À vérifier », « Diagnostic différentiel », « Référence »,
« Schéma ou capture ».

**Elle redescend dans le flux pendant un déplacement** (`.ed-door.flat`) : collée, elle masque le
dernier « Poser ici », et « créer » n'a rien à faire sous le doigt de quelqu'un qui cherche où
**poser**.

**Le dessin répond à « peu identifiable »** : le pointillé reste (grammaire de « créer », inchangée
depuis la v4.3.0) mais sur un fond **tonal** au lieu du blanc — le blanc était la couleur de toutes
les cartes autour d'elle, donc son seul trait la distinguait ; le « ＋ » entre dans une pastille
ronde ; un filet haut la détache du flux, ce qui rend son comportement collant lisible sans qu'on
ait à le deviner. **Elle reste tonale, jamais remplie** : l'unique bouton rempli de l'écran demeure
« ▶ Essayer ».

#### Une règle nouvelle, et ses deux exceptions nommées
**« Présent dans la porte ⇔ masqué quand vide ».** « À vérifier », « Diagnostics différentiels »,
« Références », « Repères posologiques », « Schémas & captures » et « Documents » disparaissent quand
ils sont vides et se recréent par la porte, avec le focus dans le champ neuf.

**Deux exceptions** : le chapeau « Ne pas oublier » et la « Confirmation diagnostique » restent
affichés même vides, et n'ont donc **pas** d'entrée dans la porte. Ce ne sont pas des extras : en
QRH, la condition d'entrée et les memory items sont ce qui rend une checklist **sûre**. Un champ vide
y est une **invitation** — la règle « un panneau vide est du bruit » vise ce qui *affirme* quelque
chose (« 0 remarque »), pas un champ qui attend du texte. Un auteur qui ne **voit** pas « Ne pas
oublier » ne l'inventera pas.

« Étape » n'entre pas dans la porte : un « ＋ » = une **portée**, et l'étape a la sienne, entre les
blocs, plus le ⏎ (MK-flux). Piège résolu au passage : `_edImgMode` a dû monter au module, la porte
devant ouvrir le sélecteur de fichier alors que la section « Schémas » est masquée — donc son bouton
absent.

#### Une image s'associe à un bloc depuis la galerie
On ne pouvait joindre une image que **depuis** un bloc : partir de l'image était impossible, alors
que c'est l'ordre naturel quand on vient d'en importer trois. Un sélecteur par vignette liste les
blocs, montre celui qui la porte, et « Aucun bloc » la détache. **Une image ne peut être que sur un
seul bloc** : on détache partout avant de rattacher, sinon deux sélecteurs afficheraient deux
porteurs pour un même état.

**Ce que cela copie, et il faut le savoir** : `b.image` porte la **donnée**, pas une référence —
c'est le format existant, et le changer serait un champ modèle de plus (règle 12) que les clients
antérieurs ne sauraient pas lire. Associer duplique donc l'image, et retoucher la vignette de la
galerie **après** coup ne suivra pas dans le bloc.

#### Le placard de l'essai est une hachure, et rien d'autre
Signalé à l'usage : *« le mode essayer ne se distingue pas beaucoup d'un mode fiche normal »*. Et le
« rien d'autre » est le vrai contenu de la décision. La v4.72.0 avait retiré l'étiquette de bandeau
parce qu'elle répétait mot pour mot la pilule de la barre ; **vérifié à l'écran, la barre porte déjà
les deux énoncés** — la pilule « ■ Aperçu » *et* le badge « Essai — rien n'est enregistré ». Les mots
sont donc couverts deux fois ; ce qui manquait était le canal **périphérique**, celui qui se
reconnaît sans lire. On n'ajoute donc que la **texture**. La règle 8 (« la couleur n'est jamais
seule ») est tenue par la barre, permanente et immobile — pas par une troisième copie de la phrase.
Bénéfice mesuré : **coût nul en hauteur et en largeur**, alors qu'une étiquette de trente caractères
repoussait le titre sur deux lignes à 400 px.

Hachure **neutre** (`--surface-3`), registre MEMO : le bleu est pris par l'invité et par l'exercice,
et un essai d'auteur n'est ni un rôle ni une répétition clinique. La justification a changé de poids
depuis K5 : « ▶ Essayer » déroule une **vraie** session (les minuteurs tournent, on coche, le chrono
avance), donc l'écran ressemble trait pour trait à un soin — le risque n'est plus esthétique, c'est
croire qu'une session est en cours ou qu'elle est enregistrée. L'exercice garde la priorité.

#### Douzième piège de cascade : une couleur aussi se vérifie
Trouvé en posant le placard d'essai à côté de celui de l'invité. `#crisisBand .cb-tag` vaut
**(1,1,0)** et écrasait le bleu du placard invité, écrit `.cb-tag.inv` = (0,2,0) : **« ▪ Vous
suivez » s'affichait en rouge depuis la v4.55.4**, sur un cadre bleu, dans le seul registre qu'elle
ne devait pas emprunter. La règle d'exercice, elle, était déjà préfixée par `#crisisBand` et gagnait
— d'où deux placards jumeaux dont un seul avait la bonne couleur.

Corollaire : la doctrine « pour une **géométrie**, ne jamais dépendre de l'ordre de déclaration »
vaut aussi pour les **couleurs**. Un témoin d'`audit-partage` compare désormais l'encre **résolue**
à `--primary-dk` au lieu de l'affirmer.

#### Le compte de relecture monte dans la barre
Le volet-bilan vit en pied de formulaire — c'est sa place, on le lit en fermant — mais rien ne
disait, pendant qu'on écrit, qu'il y avait quelque chose à relire. Le **compte** (« △ n ») rejoint
donc la barre, le seul endroit qui ne défile jamais, et ancre vers le volet **en le dépliant** ; le
détail reste en bas et sous la ligne qu'il vise. Registre ATTENTION, jamais rouge — rien n'est
bloqué, et le volet le dit en toutes lettres. Masqué à zéro remarque.

#### Vérifications
809 tests × 2 moteurs, `npm run check` vert, **seize harnais verts** (`npm run audit` en sortie 0),
a11y **301/301** dans les deux thèmes, doctrine 159/159, `audit-k5` **76/76**, partage **298/298**.
**Vingt-deux nouveaux témoins**, tous vérifiés **capables d'échouer** : masquage-si-vide neutralisé,
porte laissée collante pendant un déplacement, placard désarmé, compte bridé, préfixe `#crisisBand`
retiré → six rouges dans `audit-k5` et un dans `audit-partage` ; fichiers restaurés à l'octet.
La porte vérifiée sans débordement à **320 px** (contenu à 205 px sur 284 disponibles).

## [4.75.0] — 2026-07-30
### Lot 2 : « prendre / poser » s'étend aux listes — et l'aperçu d'algorithme s'entrebâille

#### L'aperçu d'algorithme est entrebâillé, jamais fermé
Demande utilisateur, et l'argument est doctrinal : *« un néophyte de l'application ne verra pas
qu'il existe »*. Un titre replié dit qu'une chose **existe**, il ne dit pas **ce qu'elle est** — et
un schéma est précisément ce qui ne se raconte pas. On en montre donc la tête : 168 px, avec un
fondu vers `--paper`, le fond du **canevas** (c'est le dessin qu'on estompe, pas la page). Assez
pour reconnaître un organigramme, pas assez pour repousser la première étape à écrire.

**Ce n'est plus un `<details>`**, et c'est une contrainte technique, pas un choix : un `details`
fermé ne rend **rien** de son contenu, et révéler un enfant d'un `details` fermé n'est pas fiable
d'un moteur à l'autre (le contenu vit dans un slot du shadow tree). Conteneur ordinaire + vrai
bouton ≥ 44 px, entrebâillement par `max-height`, **aucune transition** (c'est une propriété de
mise en page — `check-anim` l'interdit, et rien ici n'animerait une hauteur), **aucun re-rendu** au
dépliage : le SVG est déjà dans le DOM, donc pas une ligne ne bouge et le zoom garde ses écouteurs.
Mesuré 168 → 618 px, chevron et `aria-expanded` suivis, choix mémorisé, `scrollY` inchangé.

#### « Prendre / poser » s'étend aux huit listes
Les ↑ ↓ étaient un reste d'avant MK5-b — plus lents **et** moins sûrs : dix taps pour remonter une
rangée de dix rangs, un re-rendu à chaque tap. Et surtout, **cinq listes n'avaient aucun moyen de
réordonner** (« À vérifier », « Diagnostics différentiels », « Références », « Ne pas oublier »,
repères posologiques) : elles s'écrivaient dans l'ordre où l'on y pensait, définitivement.

**Une seule sorte `'l'`, adressée par la clé du modèle.** Les listes de chaînes et les listes
d'objets (`timers`, `counters`) se réordonnent par le même `splice` : elles n'ont pas besoin de deux
mécaniques, et un `kind` par type aurait produit huit chemins à tenir. Points d'entrée uniques —
`edGrabRows` enrobe les rangées de leurs interstices, la liste passe son gabarit de rangée et n'a
rien à savoir du déplacement.

**Confiné à sa propre boîte, et cela simplifie au lieu de compliquer** : les interstices ne sont
émis que pour la clé prise, donc un objet ne peut pas changer de contexte — le garde-fou QRH
d'`edGrabIsCrit` (« une étape ⚠ tirée hors de son bloc change de sens ») n'a ici rien à annoncer,
par construction. Il reste réservé aux étapes, qui franchissent des blocs.

Pas de poignée à une seule rangée (aucun bouton mort). Ancrage `keepAnchor` aux deux bouts :
**0 px de dérive à la prise**, mesuré, comme pour les blocs et les étapes.

#### Le glisser amorce le mode — il n'est pas le mécanisme
MK5-b a écarté le glisser comme **mécanisme** pour de bonnes raisons (gants, une seule main,
appareil qui bouge : c'est le point de défaillance du drag au doigt). Mais l'écarter comme
**amorce** était une décision par défaut, jamais raisonnée — or quelqu'un qui essaie de glisser une
poignée fait le geste que tout le reste du monde logiciel lui a appris, et le refuser **en silence**
lui laisse croire que rien n'est déplaçable.

On intercepte donc `dragstart` sur la poignée, on **annule** le glisser natif (pas question d'avoir
deux mécaniques de dépôt) et l'on entre dans « prendre / poser » en réutilisant le **clic** de la
poignée : l'utilisateur apprend le bon geste en faisant le mauvais. `dragstart` n'existe qu'au
pointeur — sur tactile rien ne change, et **aucun `touch-action` n'est posé** sur la poignée : en
poser un empêcherait de faire défiler la page depuis elle, ce qui coûterait plus que ça ne rapporte.

#### Micro-animations du passage en mode déplacement
Les deux idées proposées sont retenues, la seconde avec une borne. Les interstices « Poser ici »
entrent en **fondu cascadé** (22 ms par rang, borné à six — au-delà, un décalage n'informe plus, il
fait attendre) ; l'objet pris fait **une oscillation amortie** ; et le bandeau collant entre par le
haut, dans le sens où il arrive.

**L'oscillation ne boucle pas.** Le mouvement continu est réservé à l'alarme dans cette app (ECAM),
et un objet qui se balance indéfiniment finirait par se lire comme une alerte — or prendre un objet
n'est ni une erreur ni un danger. `transform` et `opacity` seulement, tout sous
`prefers-reduced-motion: no-preference`.

#### `--soft` n'est pas une encre, et la sonde l'a enfin vu
Les trois poignées ⠿ étaient en `--soft` — **2,62:1 mesuré**, sous le seuil AA de 4,5:1 — alors que
la règle est écrite depuis la v4.5 : « `--soft` est décoratif seulement, jamais une couleur de
texte ; texte secondaire = `--ink-soft` ». Le glyphe ⠿ **est** le contenu du bouton.

Le défaut datait de MK5-b et personne ne **pouvait** le voir : les poignées ne vivaient que dans
`.blk`, qui n'est pas dans le SCOPE d'`audit-a11y`. En les posant dans `.list-edit` (lot 2), elles y
sont entrées et la sonde a parlé aussitôt. Leçon de méthode : **un défaut hors scope n'est pas un
défaut absent** — quand un composant déménage, la sonde peut se mettre à voir ce qu'elle ne voyait
pas, et c'est un bon jour, pas une régression.

#### Vérifications
809 tests × 2 moteurs, `npm run check` vert, **seize harnais verts** (`npm run audit` en sortie 0),
a11y **301/301**, doctrine 159/159, `audit-k5` **55/55**. **Seize nouveaux témoins** pour le lot 2
(confinement, ancrage à 0 px, dépôt réellement publié, Échap qui repose sans déplacer, liste
d'objets par le même chemin, glisser-amorce, cascade, oscillation unique), vérifiés **capables
d'échouer** : confinement neutralisé, amorce neutralisée et cascade aplatie → 7 rouges ; fichier
restauré à l'octet.

## [4.74.2] — 2026-07-30
### Lot 1 des améliorations d'éditeur — et un garde-fou qui a trouvé un mort-né

#### Le contrôle qui manquait : une erreur de parse CSS ne disait rien
`npm run check` ne regardait que du JavaScript. Or dans une app monofichier, une erreur de parse
**CSS** est aussi grave et beaucoup plus silencieuse : un fermeur de commentaire en trop laisse du
texte à nu dans la feuille, et le parseur, pour se resynchroniser, **avale la règle suivante**.
C'est arrivé deux fois de suite, sur des commentaires coupés en deux — et la seconde fois, **la
v4.74.0 avait livré un correctif mort** : la règle `.hs-wrap>.hs-row:hover`, celle du survol des
bibliothèques, était mangée par le parseur depuis sa publication, avec `npm run check` vert de bout
en bout. Seule une mesure dans le navigateur l'a montré.

`check-syntax.mjs` vérifie donc maintenant la feuille : commentaires jamais imbriqués et tous
fermés, accolades équilibrées, les chaînes retirées d'abord (une accolade dans un `content:"…"` ne
compte pas). On ne réécrit pas un parseur CSS — on attrape la classe d'erreur qui fait disparaître
des règles sans rien dire. Vérifié capable d'échouer dans les deux sens.

#### Le trou entre deux paliers : 430 → 441 px
Signalé à l'usage (« à 435-440 px, Se repérer et Cons. passent sous Guidé/Statique, puis ça revient
à une ligne si on élargit ou rétrécit un peu »). Le diagnostic est arithmétique : le palier de
compression suivant est à **430**, donc entre 430 et ~441 la rangée n'a plus la place de la recette
large et n'a pas encore **droit** à la recette compressée — et l'enroulement, qui est le dernier
recours de la v4.73.1, y devenait le premier.

**On ne déplace pas le seuil** : les seuils en dur pour cette rangée se sont déjà révélés faux deux
fois, et un seuil juste ici dépendrait de la fonte du système et de la longueur des libellés.
`fitCtrlRow` **mesure** déjà : il descend donc d'un palier, re-mesure, descend encore, et n'enroule
qu'après avoir épuisé la compression. Les classes posées sont **celles de `syncZoomWidth`** — aucune
recette dupliquée, donc rien qui puisse diverger — et elles ne stylent que cette rangée. Témoin :
six largeurs de 429 à 460 px, hauteur de rangée **et** libellés intacts ; défaut réintroduit → rouge
à 431 et 435, exactement la bande signalée.

#### La carte du parcours est une surface
« Pourquoi les étapes de blocs sont de la même couleur que le fond de page et pas en fond blanc
comme les autres blocs ? » — ce n'était pas une décision : `.ov-block` n'avait **aucun
`background`**, quand `.conf-block`, `.local`, `.forget-strip` et les cartes de l'éditeur sont tous
en `--surface`. Rien ne justifiait l'exception, et le précédent existe en sens inverse : la v4.59.0
a mis l'Échelle sur une surface parce qu'elle était « la seule zone de la vue lecture à ne pas être
une surface, ses filets se lisant comme des restes de trait ». C'est la colonne d'**action** : elle
mérite le niveau 2. Les registres ne bougent pas (`.dec` garde son ambre, une étape signalée sa
boîte).

#### Le relief des étapes revient au registre
Chaque étape était en graisse **800** — le poids d'un titre appliqué à un paragraphe : plus rien ne
ressortait, ce qui est mot pour mot le reproche fait à l'inflation du rouge. **600** pour une étape
ordinaire, **800 conservé** pour les seules étapes `⚠`/`△`. Même geste que la v4.73.0 sur les
chronos (700 → 500) et pour la même raison : l'état ne crie pas plus fort que l'action. Le corps ne
bouge pas (16,5 px, palier de l'échelle fermée).

#### L'algorithme de l'éditeur étroit se replie
Mesuré à 820 px : le schéma commence haut (812 px) mais `.flow-scroll` monte à `75vh`, donc on
traversait ~1400 px de préambule avant la première étape à écrire. Il devient un dépliant **replié
par défaut**, avec son compte en sous-titre (« · 4 blocs » — un plafond qu'on voit sans l'ouvrir), et
le choix de l'auteur **persiste** : gabarit exact de `.crit-guide` (v4.31.0), rien à inventer. À
≥ 1000 px le schéma vit dans la colonne collante et n'a pas de dépliant.

#### La bascule guidé ↔ statique garde le bloc courant
Avant : `scrollTo(0,0)`, systématique — et conserver `scrollY` n'aurait rien voulu dire non plus,
les deux vues n'ayant pas la même hauteur. La seule ancre qui **existe des deux côtés** est le bloc
courant, et les deux vues le marquent avec la même classe `.cur`. C'est donc `keepAnchor`, la
mécanique ECAM du projet, appliquée au bon élément : dérive mesurée à **0 px** dans les deux sens.
Deux replis vers le haut, tous deux voulus : pas de session démarrée (rien à retrouver) et bloc
courant hors de l'écran avant la bascule (même test de visibilité qu'`ovAdvanceRender`).

#### « Essayer » est rond
`.hdr-act2` garde `border-radius:18px` pour 36 px de haut — un cercle parfait à 36 px de large, une
pilule à toute autre largeur. Le rembourrage de 10 px laissait ~32 px : plus haut que large, donc un
ovale couché. Largeur fixée à la hauteur, glyphe centré. Passé par un `#id`, les paliers plus
étroits redéclarant `padding` plus bas dans la feuille.

#### Les repères posologiques disent leur classement
C'est exact, et plus fort que demandé : `posoRank`/`posoSplit` **réordonnent selon le bloc en cours
et ne filtrent jamais** — c'est cette garantie qui autorise un rapprochement volontairement
permissif. Un auteur qui l'ignore ordonne ses repères à la main et s'étonne de les voir bouger.

#### L'anneau d'annulation
Le « Annuler » de l'éditeur est parti avec le bouton « Enregistrer » (K5, v4.72.0) : rien ne
défaisait plus une fausse manœuvre, et l'écriture étant continue, une suppression était publiée
avant qu'on ait le temps de la regretter. Bouton « ↶ » contre l'état d'enregistrement (son pendant :
l'un dit ce qui est écrit, l'autre le défait) et **Cmd/Ctrl-Z hors champ de saisie** — dans un champ,
le raccourci reste au navigateur, qui fait l'annulation fine mieux que nous.

**Il empile des points de reprise, pas des commandes**, et il a fallu **mesurer** pour comprendre
qu'il en fallait deux sortes. La première version ne couvrait que les gestes **structurels**, au
motif que les champs texte ont déjà le Cmd-Z natif. C'était vrai, mais la conséquence ne l'était
pas : annuler une suppression après avoir tapé trois mots **rendait aussi ces trois mots**, puisqu'un
instantané pris avant le geste ne peut pas contenir ce qui a été écrit après. La frappe pose donc
son propre point, **à la pause** (une rafale = un point, pas un point par caractère).

**Second défaut trouvé à la mesure** : annuler jusqu'à l'état d'ouverture ne republiait **rien**. La
garde anti-réécriture d'`edTouch` (celle qui évite qu'ouvrir une fiche la marque modifiée) sortait la
première, si bien que la bibliothèque gardait la version modifiée pendant que l'écran affichait
l'originale. L'annulation passe donc par `edCommit` : c'est un geste explicite, il écrit toujours.

**Aucun geste à recenser** : les gestes structurels se terminent tous par un re-rendu de l'éditeur,
la frappe passe toute par `edTouch` — les deux points d'étranglement existaient déjà. **Jamais
persisté, jamais synchro** : c'est un geste, pas un état du brouillon (même statut que
`state.edGrab`). Plafond 20 ; au-delà, ce n'est plus une annulation mais une restauration, et elle a
déjà son outil (« Versions », plus le point de version posé à chaque ouverture).

#### Vérifications
809 tests × 2 moteurs, `npm run check` vert (avec le nouveau contrôle CSS), **seize harnais verts**
(`npm run audit` en sortie 0), a11y 301/301, doctrine 159/159, `audit-k5` 39/39. **Quinze nouveaux
témoins** (huit pour l'anneau, trois pour l'ancrage de la bascule, douze mesures pour la bande
430-441), tous vérifiés **capables d'échouer** : défauts réintroduits un par un, fichiers restaurés à
l'octet.

## [4.74.0] — 2026-07-30
### L'éditeur dit la vérité, et il rend l'écran à ce qu'on écrit

Onze points signalés à l'usage, tous dans l'éditeur ou à sa lisière. Deux sont des indicateurs
qui **mentaient**, les autres de la place et de la lisibilité rendues.

#### L'état d'enregistrement annonçait l'inverse de ce qui se passait
`edCommit` refuse depuis la v4.72.0 d'écrire une fiche **sans titre** — une fiche anonyme n'a pas
de nom sous lequel apparaître, et une rangée « Sans titre » se rangerait sous « # » dans un
répertoire A→Z. Mais il sortait **en silence** : la barre restait sur « ⟳ Enregistrement… » et la
pastille sur « auto-enregistré », c'est-à-dire exactement l'inverse de la réalité. C'est le pire
mode de défaillance d'un indicateur d'état, et celui que ce dossier combat partout ailleurs (la
donnée périmée présentée comme vivante, danger n° 2 du palmarès ECRI 2015).

Deux moitiés, et la seconde était la moins évidente : **il fallait le dire AVANT le test « rien
n'a bougé »**. Quand on ajoute puis supprime, le brouillon revient *exactement* à son instantané
d'ouverture — la garde anti-écriture sortait la première et le badge restait figé sur le
« ✓ Enregistré » de la frappe précédente. L'ordre des deux tests suffisait à produire le défaut.

L'état est donc « ○ Sans titre — rien n'est enregistré » (abrégé « ○ sans titre » sous 560 px,
même troncature du même énoncé que le reste de la barre) et la pastille dit « brouillon gardé —
titre manquant » : registre **neutre**, comme le brouillon — il ne manque rien, il reste un geste
à faire, et le parc protège bel et bien la saisie en attendant.

#### Le dépliant « Identité » se refermait tout seul
Il s'ouvre d'office sur une fiche neuve et reste replié sur une fiche existante — la distinction
se fait sur le **titre vide**. Mais elle était **recalculée à chaque rendu** : `vide` devenant
faux dès la première lettre, le premier geste structurel (ajouter un bloc, changer d'état)
refermait le panneau sous les yeux de l'auteur qui y remplissait encore la catégorie et la date.
L'ouverture se DÉCIDE désormais à l'entrée dans l'éditeur (clé = l'id du brouillon : changer de
fiche redécide, un re-rendu jamais) et le repli n'appartient plus qu'au geste de l'auteur.
Au passage, le premier champ ne se colle plus au filet du sommaire : un en-tête de carte n'est pas
la première ligne du formulaire.

#### La colonne de droite porte l'algorithme, plus une maquette
Demande utilisateur, et le constat découle de K1 : depuis la v4.64.0 la colonne du **milieu** EST
le rendu — le chapeau est le cadre rouge, un bloc est sa carte, une étape est sa rangée. Une
carte-maquette de trois étapes à côté n'ajoutait plus qu'une seconde version, forcément moins
fidèle, de ce qu'on avait déjà sous les yeux. Ce qui, lui, ne se voit nulle part en écrivant,
c'est la **structure** que les blocs dessinent : le schéma monte donc dans la colonne collante,
où il reste sous les yeux pendant qu'on descend les blocs, et libère la hauteur qu'il prenait en
tête de « Prise en charge ». Sous 1000 px, il reprend sa place dans le flux, inchangé.
Il ne se redessine pas à la frappe — c'est le comportement d'avant, pas une régression :
`buildFlowSVG` reconstruit toute la géométrie, et le faire à chaque pause de frappe ferait sauter
le schéma. Toute la **maquette miniature** est purgée avec ses treize classes (règle 14).

#### La porte « + » reste à portée — et elle ne devient pas une zone fixe
La question posée était la bonne. SPEC §5 dit « une seule zone fixe, et en HAUT », et pour les
éditeurs elle dit en propre « **aucun pied d'éditeur** » : un bouton `fixed` en bas de l'écran est
exactement ce que cette ligne interdit, clavier mobile compris. La réponse est donc `sticky` : la
porte reste le dernier enfant de son fieldset, se colle au bas de l'écran **tant qu'on est dans
« Prise en charge »** et se décroche d'elle-même à la fin de la section — bornage natif, comme les
bandes-questions du mode statique. Elle ne prend aucune hauteur de plus, rien ne se décale, et
aucune couche fixe ne s'ajoute au chrome. Fond plein + élévation, sans quoi un bouton transparent
se lirait par-dessus le texte d'un bloc. **Pendant un déplacement, elle redescend dans le flux** :
collée, elle masquait le dernier « Poser ici », et « créer » n'a rien à faire sous le doigt de
quelqu'un qui cherche où poser.

#### K1, le membre qui manquait : quatre listes sans coquille
« Confirmation diagnostique », « Repères posologiques », « À vérifier », « Diagnostics
différentiels » (et « Références », de même nature) étaient à nu sur le fond de page, entre un
chapeau à cadre rouge et des blocs en cartes. En lecture, chacune est une `<section class="block">`
— surface, filet, rayon. La grammaire de la v4.64.0 n'était donc appliquée qu'à moitié, et une
moitié de grammaire n'en est pas une. Coquille **neutre** : la couleur reste aux registres.

#### Une section vide n'enseigne plus rien
Depuis la porte unique « ＋ » de la v4.65.0, c'est elle qui présente les types disponibles avec
leur glyphe et leur phrase : « Minuteurs & compteurs » et « ⚡ Complications » ne portaient plus
qu'un titre au-dessus du néant. Même règle que le volet de relecture (« un panneau vide qui
affirme 0 remarque est du bruit permanent ») et que le pied de l'accueil. La capacité vit dans la
porte ; la section réapparaît au premier objet créé.

#### La poignée ⠿ d'un bloc vit en tête, à droite du titre
Elle était en pied, **au contact de « Supprimer le bloc »** — précisément ce que la v4.68.0 avait
corrigé pour les étapes (« un geste destructeur ne se met jamais au contact d'un autre bouton,
sinon le pouce corrige et supprime du même geste »). La règle n'avait pas été appliquée à
l'échelon du bloc ; elle rejoint l'anatomie déjà retenue pour l'étape.

#### Le bandeau « déplacement » tenait sur un mot par ligne
Signalé avec capture, sur iPhone. Troisième occurrence du même défaut de rangée flex :
« TOUCHEZ UNE DESTINATION » (majuscules + interlettrage) et le ✕ de 44 px sont **incompressibles**,
et le seul objet qui pouvait céder — le libellé, seul `min-width:0` de la rangée — cédait jusqu'à
la largeur d'un mot (**12 px sur 284**, mesuré). Remède déjà écrit deux fois dans ce fichier (croix
du panneau minuteurs v4.55.3, ligne d'état v4.56.3) : on **empile**, et le ✕ est **ancré** en haut
à droite avec sa place réservée par un rembourrage.

#### Une rangée de bibliothèque, un seul survol
Depuis que l'aplat de sélection vit sur le **conteneur** (v4.73.0), la micro-réponse E5 du
bouton-titre (lévitation d'1 px + ombre au survol) le décollait de son propre fond : le titre
montait, le crayon restait, et l'ombre se peignait par-dessus le bleu — deux objets là où il n'y a
qu'une bibliothèque. C'est le conteneur qui répond au geste, comme c'est lui qui porte l'état.

#### Points examinés sans changement de code
- **Le discriminant est déjà borné** à 60 caractères, dans le champ (`maxlength`) comme dans
  `migrate` (`sstr(x.discriminant,60)`) — le libellé le dit maintenant, il ne le disait pas.
- **« Essayer » qui entassait tout dans la colonne de gauche** : non reproductible, vérifié à
  1250, 1400 et 1600 px, en dynamique comme en statique, sur fiche et sur protocole — la grille se
  pose bien en `860 | 360`. C'était le défaut de piste corrigé en v4.73.0 (`cockpit` conditionné à
  l'existence de la colonne).
- **Le plafond des rappels** reste non bloquant : déjà en place, et c'est la doctrine (on suggère,
  on n'empêche rien).

#### Une exemption au harnais a11y, nommée et motivée
Le schéma `buildFlowSVG` (`.flow-scroll`) est entré dans une surface mesurée le jour où la colonne
droite a cessé d'être une maquette. Il n'a jamais été conforme au plancher de 11 px, **nulle part**
— ni dans le flux de l'éditeur, ni dans le panneau « Algorithme » de lecture, ni en plein écran :
simplement, aucun de ces logements n'était dans le SCOPE. Il en est exempté parce que ce n'est pas
du **texte** mais un **dessin à échelle variable** (zoom 25–400 %, plein écran, pincement natif) et
que chacun de ses mots existe en taille pleine dans le contenu qu'il résume — même frontière que
`check-type`, qui borne l'échelle fermée au texte. Tout le reste de `#editSide` reste mesuré.

#### Vérifications
809 tests × 2 moteurs, `npm run check` vert, **seize harnais verts** (`npm run audit` en sortie 0),
a11y 301/301, doctrine 144/144. **Douze nouveaux témoins** dans `scripts/audit-k5.mjs` (28 contrôles),
vérifiés **capables d'échouer** : défauts réintroduits un par un → 5 rouges, dont le libellé du
bandeau retombé à 12 px ; fichier restauré à l'octet. Rien à rejouer côté serveur.

## [4.73.3] — 2026-07-30
### Le prompt IA rattrape la structure — et il devient un contrat vérifié

> Cette version a d'abord été préparée sous le numéro **4.73.0**, en parallèle des 4.73.0 à
> 4.73.2 faites ailleurs. Deux versions ne peuvent pas porter le même numéro : `APP_VERSION` et
> `CACHE` sont un couple, et un décalage casse la mise à jour du service worker (règle 1). Elle a
> donc été renumérotée au merge, et republiée par `./release.sh` pour que les cinq fichiers
> d'artefacts restent cohérents. Le contenu est inchangé.

#### Le gabarit qu'il montrait n'était pas du JSON valide
Trouvé en écrivant le contrôle, pas en relisant : le `\n` de `localInfo` vivait dans un littéral
gabarit, donc JavaScript le transformait en **vrai saut de ligne**. Le JSON d'exemple affiché à
l'IA contenait une chaîne coupée par une fin de ligne — invalide. Une IA qui recopie fidèlement ce
qu'on lui montre produisait un fichier que l'import refuse, et la faute paraissait venir d'elle.
Il faut `\\n` dans la source pour afficher `\n`.

#### Deux champs manquaient depuis trois versions
`discriminant` (v4.70.0) et `onDue` (v4.70.0) n'étaient pas dans le prompt : une IA ne pouvait donc
pas les produire, et le champ créé pour éviter deux titres identiques sur un écran de crise restait
vide sur toute fiche générée.

- **`discriminant`** — la population ou le contexte (« adulte », « pédiatrique », « femme
  enceinte ») sort du titre pour rejoindre son champ. Le titre devient la **situation seule**, aussi
  court que possible : c'est lui qui est tronqué partout où la place manque. Et la consigne est
  explicite — **ne le devine jamais** : aucune migration ne découpe le titre d'un auteur pour en
  extraire un discriminant supposé, le prompt ne doit pas le faire non plus.
- **`onDue`** — ce qu'il faut faire quand le minuteur sonne, annoncé à la place du seul nom. Une
  alarme qui se contente de nommer dit **quoi** a sonné, jamais **quoi faire**.

#### Peu de texte — avec les seuils réels de l'éditeur
La contrainte est désormais énoncée d'abord, avant l'exhaustivité : un écran de téléphone tenu à
bout de bras pendant une réanimation ne rend pas un paragraphe, et une étape qui déborde sur trois
lignes repousse d'autant les suivantes sous le bas de l'écran. Les budgets ne sont pas des vœux :
ce sont **les seuils que l'éditeur signale lui-même** — challenge ≤ 110 caractères, bloc ≤ 7 étapes,
au plus deux séparateurs « · »/« + » par étape, rappel ≤ 110 caractères et 4 maximum, titres de
bloc de 2 à 4 mots. Les seuils du prompt et ceux de l'application ne doivent jamais diverger, sinon
l'IA produit exactement ce que l'éditeur va signaler.

#### Ce que « :: » fait à l'écran
Le prompt disait à quoi le séparateur **sert** (challenge-réponse, confirmation à deux voix) mais
pas ce qu'il **fait** : tout ce qui suit « :: », jusqu'à la fin de la ligne, sort du texte principal
et s'affiche en **gris, dans une bulle, à chasse fixe**. C'est donc un outil de mise en page autant
que de méthode — les chiffres passés après « :: » raccourcissent la ligne de moitié à l'œil. Une
étape de quatre-vingts caractères dont soixante sont des valeurs se lit très bien ; la même sans
« :: » est un pavé.

#### Un seizième harnais
`scripts/audit-prompt.mjs` extrait le schéma **du prompt lui-même**, le parse, le passe par
`migrate()` et vérifie qu'aucun champ ne tombe — puis que le prompt dit bien les trois choses que
cette version y ajoute. Il est **pur** : aucun rendu, aucun clic. Il mesure un contrat, pas un
écran. Règle qui en découle : tout champ modèle ajouté entre dans le prompt **et** dans ce harnais.

809 tests × 2 moteurs, a11y 301/301, doctrine 112/112, les seize harnais verts, `npm run audit` en
sortie 0. Rien à rejouer côté serveur.
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
