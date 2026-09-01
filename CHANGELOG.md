# Journal des modifications

## [5.20.9] — 2026-09-01
### La vue guidée est purgée : le journal sert tout, l'aperçu vide compris (A296)

- **Le vestige mis au jour en A295 tombe** : `navSection`, `bindNavEvents`, `renderNavOnly`, la
  mécanique `scrollNavNext`/`scrollNavIntoView`, le fil d'Ariane, `.nav-wrap`, `.flow-nav` et
  les commandes `#navNext`/`#navFwd`/`#navResume`/`#navBack`/`data-goto`/`data-crumb` ne
  servaient plus que l'aperçu d'un brouillon SANS bloc — où la vue ne rendait RIEN. Mesuré avant
  de trancher : le journal rend cette même fiche sans planter (« Parcours » vide, même chrome).
  `readModeOf` n'a plus que deux réponses, `'guided'` sort de `READ_MODES` (une ancienne
  préférence retombe sur `'overview'`), et `jumpToBlock` se décide sur `readModeOf` — au
  passage, un saut sur fiche mono-bloc rejoint le comportement du journal, la doctrine v5.6
  enfin vraie partout.
- **Purge disciplinée (règle 14)** : suppressions par pré-image vérifiée UNIQUE, épitaphe CSS au
  format exigé par `check-classes`, membres retirés des unions partagées sans toucher leurs
  frères vivants (`.opt`, `.options`, `.question`, `.arr`, `.pass-n`, `.btn.cont`, `.flow-end`,
  `.tmr-hint` — le journal et les minuteurs les émettent), harnais doctrine mis au propre. Ce
  sont les garde-fous d'A289 qui ont énuméré le CSS orphelin : une purge à moitié faite façon
  `.pl-stp` (v4.25.0) ne peut plus passer. Bilan : ~265 lignes et ~16 Ko de vue morte en moins.
  Vérifié : check complet, 1 176 tests × 2 moteurs, audit complet 26/26. Détail : A296
  (`docs/decisions/lot-v5-20.md`).

## [5.20.8] — 2026-09-01
### Le signalement d'A294, re-mesuré : un vestige, pas un trou — et le témoin qui manquait (A295)

- **Mesurer avant de corriger, et le signalement s'est dégonflé** : `#navNext` et `data-goto`
  — les deux sites sans `persistLive` d'A294 — ne vivent que dans la vue guidée, que
  `readModeOf` ne sert qu'aux fiches SANS AUCUN BLOC (l'aperçu d'un brouillon vide, fusion
  v4.16). Sondé sur fiche à blocs (journal et statique, session vive) : zéro occurrence des
  deux contrôles ; sur fiche sans bloc : aucun non plus (rien à continuer). L'implication
  décrite en A294 — l'invité qui resterait en arrière — ne pouvait pas se produire : le
  « Continuer » réel est celui du journal (`data-ovnext`), qui persiste et émet. Les deux
  `,false` tombent quand même (uniformisation, neutre par construction) ; `persist:false` ne
  reste que sur `cxGo`, qui persiste autrement.
- **La propriété qui compte gagne son témoin** : `audit-partage` § « l'avancée chez l'hôte
  ÉMET » — session réelle, bloc coché par ses vrais gestes (le cran « Continuer » est fermé
  tant que le bloc ne l'est pas, A234), base de diff remise à zéro, tap sur `data-ovnext`,
  exigence d'un évènement `nav` au fil portant le COUPLE nav/navSeq complet. Vérifié CAPABLE
  D'ÉCHOUER (méthode v4.31.1) : défaut réintroduit sur le site → rouge exactement sur
  l'assertion d'émission, l'avancée locale restant verte ; restauré à l'octet, re-vert.
  Détail : A295 (`docs/decisions/lot-v5-20.md`).

## [5.20.7] — 2026-09-01
### La quadruple mutation de navigation n'existe plus qu'une fois (A294)

- **`nav.push · navSeq.push(++seq) · navPos=bout · persistLive` survivait en clair sur huit
  sites** malgré la factorisation partielle de v5.19.4 (`ovNavPush`/`ovNavDone`, bornée au
  journal). C'est l'invariant le plus critique du mode crise : les clés de cochage valent
  `seq:idBloc:index` — un décalage nav/navSeq orpheline les coches (48 disparues en un rendu,
  le précédent documenté) — et le partage transporte le couple indissociablement (`shareFold`
  refuse des longueurs divergentes). `navAdvance(id,persist)` porte désormais la mutation
  entière ; le re-rendu, seule chose qui différait légitimement, reste chez l'appelant.
- **Ralliés à sortie identique** : `cxGo`, `cxResume`, les deux branches de `jumpToBlock`, le
  « Continuer » guidé, `data-goto`, `data-ovnext`, `svJump`. Hors motif à dessein :
  `ovNavPush`/`ovNavDone` (le journal pousse parfois deux ids avant de conclure) et la remise à
  zéro de `restartCourse` (un reset n'est pas une avancée).
- **Signalement mis au jour, comportement conservé tel quel** : le « Continuer » guidé et
  `data-goto` n'appelaient historiquement aucun `persistLive` — les deux sites portent désormais
  `persist:false` en toutes lettres, et corriger ce trou est un choix d'un caractère qui attend
  un arbitrage (il change ce qui s'écrit sur le disque à chaque « Continuer »). Détail : A294
  (`docs/decisions/lot-v5-20.md`).

## [5.20.6] — 2026-09-01
### Les commentaires longs du script suivent ceux de la feuille (A293) — le chantier d'assainissement est clos

- **Le pendant JS de la v5.20.5, plus gros gisement** : les 239 blocs de commentaires JS de PLUS
  de dix lignes (384 Ko — le JS portait 54 % de commentaires) sont repris **à l'octet** dans
  `docs/decisions/doctrine-js.md` sous les ids stables **J1…J239**, puis resserrés sur place :
  les invariants en toutes lettres (« la SEULE barrière anti-XSS », « migrate est le point
  d'ASSAINISSEMENT », « ICI, ET NULLE PART AILLEURS »…), les ⚠, les marqueurs Q/K/R/P, les
  renvois A-xxx, et « Détail : doctrine-js.md J‹n› ». Le grand commentaire d'architecture de
  tête et les 261 blocs de 7-10 lignes déjà denses ne bougent pas.
- **La différence technique avec le CSS** : un run de `//` ne se reconnaît pas à l'œil — une
  ligne commençant par `//` DANS un template literal est du code. Les blocs ont été cartographiés
  au tokeniseur d'états et le masque PROUVÉ juste avant toute édition (le script blanchi de tous
  les commentaires détectés doit compiler, `vm.Script`) ; les blocs enjambant une ligne de code
  gardent leurs délimiteurs de bord. Hashs CSP rejoués à chaque tranche (règle 3) ; les contrôles
  sensibles aux commentaires (`check-fns`, `check-actions`, `check-actest`, `check-upload`,
  `check-stores`) verts de bout en bout — aucun nom ne vivait par le seul commentaire supprimé.
- **Bilan des deux déménagements (A292 + A293)** : `index.html` passe de **2 891 à 2 440 Ko
  (−451 Ko, −15,6 %)** et de 33 874 à 29 059 lignes. Mesuré au même protocole que la phase 0 :
  boot à CPU ×6 **714 → 691 ms** (vierge) et **354 → 334 ms** (avec données) ; pleine vitesse
  103 → 99 / 57 → 51 ms (Chromium), 110 → 105 / 74 → 68 ms (WebKit) — la fraction attendue de la
  borne parse d'A289. Le chantier ouvert au rapport de phase 0 est clos ; restent en attente
  d'arbitrage les blocs de 7-10 lignes, les écrasements CSS PROBABLES, les treize factorisations
  PROBABLES et le repli `Math.random` de `uid`. Détail : A293 (`docs/decisions/lot-v5-20.md`).

## [5.20.5] — 2026-09-01
### Les commentaires longs de la feuille de style déménagent, comme AGENTS.md avant eux (A292)

- **La méthode du déménagement v5.10.3, pas celle du résumé destructeur** : les 135 blocs de
  commentaires CSS de PLUS de dix lignes (252 Ko sur les 66,6 % de commentaires que pèse la
  feuille) sont d'abord repris **à l'octet** dans `docs/decisions/doctrine-css.md`, chacun sous
  un id stable **C1…C135** — puis le commentaire en place est resserré à l'essentiel : la
  contrainte que le code ne peut pas dire, les ⚠, les renvois A-xxx, et « Détail :
  doctrine-css.md C‹n› ». Rien n'est perdu par construction ; les 19 bannières de section et les
  137 blocs de 7-10 lignes déjà denses ne bougent pas.
- **Discipline d'exécution** : aucune ligne de code CSS touchée, les épitaphes de purge (que
  `check-classes` exige) survivent dans chaque résumé, aucun résumé ne cite une couleur littérale
  ni ne contient une fermeture de commentaire en son milieu (le piège v4.74.0). Vérifié :
  135/135 renvois posés, check complet, 1 176 tests × 2 moteurs, audit complet 26/26.
- **Bilan** : `index.html` perd **~196 Ko** (2 891 → 2 695 Ko) ; l'effet au démarrage est la
  fraction correspondante de la borne parse mesurée en A289. Détail : A292
  (`docs/decisions/lot-v5-20.md`). Les commentaires JS suivent au lot suivant.

## [5.20.4] — 2026-09-01
### Soixante-quatre gardes `typeof` d'un monde révolu (A291)

- **`if(typeof Sync!=='undefined')Sync.schedule();` et ses soixante-trois cousines** — des gardes
  sur des symboles top-niveau du seul script applicatif, héritées des chantiers où `Sync`,
  `Share` ou `zoomF` n'existaient pas encore — sont purgées. L'argument est structurel, pas un
  inventaire : pour un `const` en zone morte temporelle, `typeof` LÈVE au lieu de répondre
  `'undefined'` (la garde ne pouvait pas rendre le service qu'elle affichait), et le
  run-to-completion garantit que tout gestionnaire ou timer court après l'évaluation complète du
  script. Zéro comportement changé — 1 176 tests × 2 moteurs et l'audit complet le confirment.
- **Gardés en connaissance de cause** : les vrais tests d'API sur des objets
  (`navigator.wakeLock`, `document.elementsFromPoint`, `AbortController`) et les tests de type
  sur des données ou des paramètres — eux disent quelque chose de vrai. Le repli `Math.random`
  de `uid` reste en attente d'arbitrage. Détail : A291 (`docs/decisions/lot-v5-20.md`).

## [5.20.3] — 2026-09-01
### La suppression de compte oubliait une clé que la déconnexion retirait (A290)

- **Un reliquat d'« éditions retenues » survivait à l'effacement TOTAL de l'appareil** :
  `wipeLocal()` (suppression de compte) et `wipeCurrentSpace()` (déconnexion en effaçant
  l'appareil) recopiaient chacun leur liste de clés locales — la seconde retirait
  `ac-held-edits`, la première non, et sa boucle générique de rattrapage exige un `@` que la
  forme nue de la clé n'a pas. Prouvé à la sonde par le vrai appel, deux moteurs : la clé nue
  SURVIT quand tout le reste part.
- **Correctif structurel, pas une ligne dans une liste** : `WIPE_SPACE_KEYS`, liste UNIQUE des
  clés d'espace, consommée par les deux effacements (`wipeLocal` y concatène ses extras
  d'appareil). Une liste recopiée diverge, une liste unique non — même remède que `MUTE_SEL`
  (v4.4.2) et `SHARE_KINDS` (A216). Rouge→vert rejoué à la sonde après correctif. Détail : A290
  (`docs/decisions/lot-v5-20.md`).

## [5.20.2] — 2026-09-01
### Assainissement mesuré : trois garde-fous nés rouges, purges prouvées, vingt factorisations (A289)

- **Trois trous de garde-fous fermés, chacun PROUVÉ né ROUGE** sur l'état d'avant correctif :
  `check-fns` détecte les `let` top-niveau écrits mais jamais LUS (deux vivaient ainsi, dont un
  au commentaire décrivant une comparaison jamais écrite) ; `check-ids` gagne le sens « id émis →
  lu » — **20 croix de fermeture de modales** portaient un id que rien ne lisait (le câblage
  passe par `.ai-x`), dont une née en v5.20.0 PENDANT l'inventaire même ; `check-icons` gagne la
  passe « entrée de table jamais citée » — trois en-têtes (`h-main`, `h-img`, `h-forget`)
  vivaient en fantômes (dictionnaire + CSS + un commentaire, zéro émission).
- **Code mort purgé au grep** (règle 14, zéro citation restante) : douze purges CSS (`.tag.draft`,
  `.pl-lnk.loop`, cinq états de `.pc-card`, `.blk-type.steps/.decision`, `.hs-row.hs-cmd`, la
  famille `h-*`, quatre écrasements dont un `gap:10px` écrasé par la ligne ADJACENTE, trois
  copies de palier strictement incluses — la copie du « dix-neuvième piège de cascade » est
  GARDÉE, son ordre est sa raison d'être) ; côté JS `flowCtx.curId` (7 écritures, 0 lecture),
  les 20 ids, quatre commentaires menteurs. Faux positifs écartés avec preuve (FLOWK destructuré,
  POSO_SYN indexé dynamiquement).
- **Vingt factorisations à sortie identique** — les invariants que la doctrine énonçait sans les
  tenir n'existent plus qu'une fois : récepteur de fontaine optique (la plus grosse zone
  dupliquée du fichier, sa divergence de ré-armement neutralisée), fermetures mémoire de la
  synchro (« ne jamais ré-insérer un supprimé » vivait en six copies), cœur de cochage
  local/distant, tri unique de l'accueil, gestes communs de « Consulter », empreinte SHA-256 de
  protocole, « pli neuf » de l'invité identique sur ses deux portes, marquage des préférences
  (six copies qui se citaient l'une l'autre en commentaire) ; deux fetch bornés artisanaux
  passent par `acFetch`.
- **Le ✓ de « Quand l'utiliser » retrouve son vert** : la règle `:not(.cur):not(.done)` pesait
  (0,4,0) avec deux états MORTS et écrasait `.pc-n.ok` — badge sur fond neutre, encre grise,
  prouvé à la sonde par le vrai chemin (session → Tout voir → Parcours) sur deux moteurs, avant
  et après correctif (fond `--ok`, encre `--on-primary` désormais).
- **Verdict performance, chiffré pour ne plus y revenir** : le boot est dominé par le PARSE
  (510 ms sur 673 à CPU ×6 ; le JS applicatif pèse ~40 ms), les interactions tiennent en
  10-16 ms même bridées, +0 écouteur par coche, timers déjà gatés — rien à optimiser ; le seul
  levier mesurable est la masse de commentaires (55,6 % du fichier), chantier documentaire à
  arbitrer séparément. Détail complet : A289 (`docs/decisions/lot-v5-20.md`).

## [5.20.1] — 2026-09-01
### En voie large, l'accueil repartait de zéro à chaque re-rendu (A288)

- **« On ne revient pas au scroll initial, on revient en haut de la page »** (A288, signalé à
  l'usage après le ✎ *modifier bibliothèque* pris dans la LISTE de cartes). Le ✎ n'y est pour
  rien : c'est la fermeture qui, après un enregistrement de nom, re-rend l'accueil. Or à partir de
  780 px la page ne défile plus — ce sont `.home-main` (la liste) et `.hs-scroll` (les catégories
  de la colonne gauche) qui portent le défilement, et tous deux sont **reconstruits** par
  `main.innerHTML`. Mesuré : **600 → 0** pour la liste, **80 → 0** pour la colonne, à CHAQUE
  re-rendu — donc aussi en épinglant, en filtrant, en cochant. En voie étroite le défileur est la
  page, que le navigateur ne bouge pas : le même geste n'avait donc pas le même effet à 390 et à
  1280, et c'est cette asymétrie qui tranchait la question.
- **Correctif au patron de `.read-side`** (v4.23.5, même défaut sur le rail de lecture) : capture
  avant, restauration après, **bornée au nouveau contenu** — une liste raccourcie par un filtre ne
  doit pas poser hors borne. La mémoire par section de `setSection` l'emporte toujours : deux
  crans ne partagent pas une position.
- **Un piège de mesure évité en route** (famille A267) : la première sonde interrogeait le nœud
  capturé AVANT le re-rendu — donc un nœud DÉTACHÉ, qui répond 0 quoi qu'il arrive, et qui aurait
  affiché « rouge » même une fois le défaut corrigé. Le défaut a été re-mesuré avec une sonde qui
  re-interroge le document ; le témoin (`audit-doctrine`, « le défilement survit au re-rendu »)
  couvre les deux défileurs ET le geste signalé par son vrai chemin, et il est né ROUGE.

## [5.20.0] — 2026-09-01
### Le rail A→Z posait sa lettre sous ce qui coiffe l'écran ; la gestion descend au pouce (A286-A287)

- **Le premier résultat de la lettre était masqué** (A286, signalé à l'usage : « depuis la refonte
  de l'en-tête, le scroll s'affiche mal — le premier résultat de la lettre est masqué »). C'est un
  reste de la v5.18 : l'en-tête d'accueil y est devenu STATIQUE, la cible du saut a donc cessé de
  soustraire quoi que ce soit — mais DEUX objets coiffent encore le haut du défileur. La **barre
  de sélection** (collante à 0) avalait l'intertitre entier et **17 px de la première rangée** ;
  la **bande de zone sûre** de l'iPhone installé — posée dans ce même lot v5.18 pour que rien ne
  défile sous l'heure — faisait s'épingler l'intertitre à 47 px, où il recouvrait la rangée qu'il
  annonce (**39 px de 60 mesurés**). La cible ôte désormais cette coiffe, LUE au moment du saut et
  jamais écrite en constante ; équivalence prouvée au pixel là où rien ne coiffe, en voie étroite
  comme en voie large, sur les deux moteurs.
- **Pourquoi vingt et un harnais ne voyaient rien, et ce qui change** : `env(safe-area-inset-top)`
  vaut 0 dans un navigateur — la moitié du défaut n'existait que sur un appareil INSTALLÉ, l'autre
  demandait le mode sélection, qu'aucune sonde du rail n'activait. Le témoin (`audit-doctrine`,
  « le rail A→Z pose sous ce qui coiffe ») joue trois cas — nominal, sélection, **encoche
  simulée** par un littéral de 47 px — et il est né ROUGE sur les trois assertions qu'il fallait.
- **Gérer les catégories et les bibliothèques, sans colonne gauche** (A287, signalé à l'usage :
  « sur smartphone il n'y a pas de sidebar : je ne peux plus gérer les catégories, et les
  bibliothèques je ne peux les gérer qu'en vue *Rangé par bibliothèque* »). Sous 780 px, « Gérer
  les catégories » n'était atteignable QUE par la feuille de filtres, dont le déclencheur n'existe
  que pendant une recherche ; et le ✎ d'une bibliothèque administrée ne paraît que sur
  l'intertitre de section, donc dans un rangement sur trois. Une **rangée au socle**, masquée
  ≥ 780 px où la colonne gauche reprend la main — même patron et même cause que « Rejoindre une
  session » (v5.14.3). Elle **n'invente aucune fenêtre** : mêmes rangées, mêmes attributs, mêmes
  lecteurs que la colonne (`#catModal`, `#membersModal`, `#newLibModal`). Le socle n'ouvre jamais
  une feuille d'UNE rangée — sans bibliothèque à administrer, elle dit « Gérer les catégories » et
  va droit au gestionnaire ; et l'on ne liste que ce qui se gère (une bibliothèque en lecture
  seule serait une commande morte, règle 14). La feuille entre dans les surfaces d'`audit-a11y`
  par son vrai point d'entrée.

## [5.19.6] — 2026-08-31
### L'anneau de focus repris par un `#id` : une propriété corrigée, deux trous fermés (A285)

- **Un `#id` reprenait EN SILENCE la respiration d'A268** (A285, signalé sur capture : « la
  bordure du bouton *Tout* est toujours coupée par la fenêtre »). La feuille de filtres portait
  depuis la v5.6 `#filtSheetBody{padding:0 0 4px}` : un `#id` l'emporte sur `.ai-card>.ai-body`,
  et le RACCOURCI `padding` remettait l'axe inline à zéro — en laissant vivre la marge négative,
  qui dès lors ne compensait plus rien. Résultat PIRE que l'état d'avant A268 : chips 4 px à
  gauche du titre, pile sur la découpe, anneau de focus rasé. Mesuré : garde gauche 0 px pour
  « Tout », « Toutes » et « Gérer », contre 3,9 px dans les seize autres corps de fenêtre.
  Correctif d'une propriété : `padding-block:0 4px` — on n'écrit que l'axe qu'on règle, l'axe
  inline reste à la règle commune ; effet second voulu, les chips s'alignent enfin sur le titre.
- **Le trou de cascade se ferme en garde-fou** : `check-ring.mjs` (dans `npm run check`, donc en
  CI) lit les corps de fenêtre dans la coque — jamais une liste tenue à la main — et refuse toute
  règle qui les CIBLE par leur `#id` en posant une respiration inline < 4 px (les règles visant
  un DESCENDANT ne sont pas concernées). Né ROUGE sur l'état d'avant correctif.
- **Le trou de couverture aussi** : la feuille de filtres n'était ouverte par AUCUNE des
  vingt-cinq surfaces d'`audit-a11y` — c'est ce qui a laissé sept mois au défaut. Elle entre au
  balayage par son VRAI point d'entrée (`#filtTog`, qui n'existe que pendant une recherche) :
  conforme aux deux thèmes du premier coup. Leçon v4.75.0 redite au prix fort : un défaut hors
  périmètre n'est pas un défaut absent.

## [5.19.5] — 2026-08-31
### Les mineurs de l'audit : la rangée d'éditeur suit la largeur effective, la doctrine se navigue (A284)

- **La chaîne de compression de la rangée d'éditeur (640→430→360) passe aux paliers `zw`**
  (A284). Mesuré sous zoom texte 130 % : la recette anti-chevauchement des halos ne
  s'appliquait pas à largeur EFFECTIVE < 430 (le tap partait au dernier élément du DOM) et
  « Aperçu » restait en toutes lettres là où l'icône s'imposait. Équivalence exacte à zoom 1
  prouvée aux quatre témoins (620/420/350/700 px), deux moteurs — et le piège de mesure A267
  évité en route (un « débordement de 161 px » qui n'était qu'un artefact de repère visuel).
  Les quatre paliers de composition restants ne se convertissent pas d'office : arbitrage
  écrit dans A284.
- **`Share` et `Sync` se naviguent** : quatorze sous-bannières `/* ===== … ===== */` aux
  frontières logiques des deux modules (cadence, PULL, PUSH, annexes ; horloge, émission,
  cycle, application, gestes hôte/invité, passation, fins) — la commande d'index du
  monofichier les liste désormais. Aucun code déplacé.
- **`GUIDELINES.md` relu** (il l'exigeait lui-même) : les principes tiennent, une note datée
  renvoie les quatre surfaces refondues (accueil v5.18, colonne/pied v5.19, barres v5.15,
  sélection v5.17) vers leurs lots ; `design/README` corrige ses fiches « ~275 Ko » (réel :
  ~815) et consigne les deux `git gc`.

## [5.19.4] — 2026-08-31
### Phase 3 de l'audit : trois garde-fous nouveaux, le pli QR assaini, cinq duplications factorisées (A283)

- **Trois trous de l'audit fermés en garde-fous**, chacun né ROUGE sur défaut fabriqué puis
  restauré à l'octet : `check-tokens` (token CSS déclaré ↔ lu, le trou du survol `--hover`),
  `check-ids` sens inverse (sélecteur `#id` stylé → émis, le trou de `#f-validation`),
  `check-fns` (déclaration top-niveau → citée ailleurs, le trou de `catsUtiles`). Les
  commentaires sont dépouillés d'abord (`strip-comments.mjs`, source unique) — un nom cité
  dans la doctrine n'est pas un usage. **`check-fns` a attrapé un 4ᵉ mort dès sa naissance**
  (`enLigneOk`, locale jamais lue), supprimé.
- **Le pli reçu par QR passe par `slFoldSan`** — c'était le seul intrant distant pris brut :
  grammaires du chemin en ligne (shareNavNorm, vfMapNorm, tkRefNorm), bornes de
  sanitizeSession, liste fermée (un miroir ne réécrit rien), témoin dans tests.html (+7
  assertions, aucun label d'évènement ne traverse — règle 15). `ltSnapUnpack` décompresse
  borné à 4 Mo (le flux s'annule, comme `inflateBounded`).
- **Durcissements** : la purge des caches du SW se limite au préfixe `aides-cognitives-`
  (l'origine n'est pas le scope — un déploiement intranet en sous-répertoire n'effacera pas
  les PWA voisines) ; `esc()` rejoint les six sites d'id qui y avaient échappé (couverts par
  safeId en amont, mais la règle v5.10.2 « échapper au site » y était cassée).
- **Cinq duplications factorisées, comportement identique** : renommage inline
  minuteur/compteur (jumeaux), `selBounds` (×3), `slBusySheet` (refus « partage déjà actif »
  ×2), `attInfoFor` (×2), `ovNavPush`/`ovNavDone` (queue de navigation ×2).
- **Piège découvert et fermé en route** : deux commentaires JS citent `<style>` sans
  fermeture — sur le fichier brut, ils s'appariaient de travers avec tout bloc ajouté plus
  bas ; l'appariement des blocs se fait désormais commentaires retirés.
- Les cinq fonctions de test embarquées et les deux surfaces de harnais portent leur marqueur
  « délibéré » (décision Q3) — un futur audit ne les re-signalera pas.

## [5.19.3] — 2026-08-31
### Audit interne complet : le survol qui ne peignait rien, le code mort purgé, la doctrine qui dit vrai (A280-A282)

Audit transverse en quatre passes (code mort, PWA/performance, sécurité, outillage), chaque
constat contre-vérifié, cinq arbitrages posés à l'auteur avant le premier geste. Verdict
d'ensemble : aucune XSS atteignable, aucun secret exposé, RLS et `search_path` corrects sur les
24 fonctions `SECURITY DEFINER`, une seule vraie duplication de bloc dans 1,97 Mo de JS. Les
correctifs, sans changer un seul comportement voulu :

- **Deux survols inertes réparés (A280)** : `.rt-lnk` (sommaire d'une référence) et `.at-b`
  (onglets) lisaient `var(--hover)` — un token JAMAIS déclaré, déclaration invalide au calcul,
  survol qui ne peignait rien dans les deux thèmes. Peints avec la famille vivante (`--amb-2`
  le jour ; `--hover-dk` la nuit, `-hi` sur surface élevée), prouvé à la sonde : fond calculé
  non transparent au survol réel, 2 thèmes × 2 moteurs, 8/8.
- **Code mort purgé (règle 14, zéro émission vérifiée au grep)** : `catsUtiles` +
  `catNbSousFiltre` (remplacées par l'union v5.18, jamais purgées), `filtersActive`,
  `_ROLE_LBL` ; six tokens déclarés-jamais-lus (`--w-max`, `--g-cmd`, `--hit-crisis`,
  `--dur-1`, `--primary-300` ×2, `--shadow-dock`) ; deux sélecteurs `#id` orphelins
  (`#f-validation.val-bad`, `#readTopSeg` dans `@media print` — purge v5.6 enfin achevée).
- **Le palier 1200 n'a plus qu'UNE copie** : le bloc d'origine (§ LARGEURS) avait été réaffirmé
  plus bas pour gagner la cascade, puis les deux copies ont divergé en silence (`.ed-cockpit`
  240 ici, 220 là — la cascade tranchait pour 220, la copie d'origine était morte avec un
  commentaire annonçant 220 au-dessus d'une ligne écrivant 240). Le bloc mort est purgé, 220
  confirmé par l'auteur, la doctrine « pour une géométrie, ne jamais dépendre de l'ordre »
  déménagée sur la copie vivante.
- **Quatre commentaires qui mentaient corrigés** : `fitCtrlRow()` décrite au présent
  (supprimée en v5.6, son épitaphe existait 21 000 lignes plus loin), `--primary-300`
  documentée en service, « structure 220 » sur la ligne à 240, et `_headers` qui justifiait
  `no-cache` par une stratégie « réseau d'abord » révolue depuis v4.4.6.
- **La règle des 20 du CHANGELOG devient exécutoire (A281)** : `scripts/check-changelog.mjs`
  (dans `npm run check`, donc CI) — compte ≤ 20 et aucune entrée en double avec une archive.
  Né ROUGE sur l'état réel à 21 entrées, vert après archivage de [5.14.21] puis [5.14.22]
  (en FIN d'archive, convention constatée et désormais écrite). L'alias `npm run ci`, jamais
  appelé et divergent du workflow, est retiré.
- **Le périmètre de déploiement est tranché (A282, décision utilisateur)** : le dépôt est servi
  EN ENTIER — et ce qui ne doit pas être public SORT du dépôt : `sonde/index.html` (313 Ko de
  sonde WebRTC d'un spike clos v5.14, jumelle à l'octet d'un fichier délibérément gitignoré,
  publiée à `/sonde/` faute d'index) est supprimée.
- **La doctrine devient navigable par toute IA** : `docs/README.md` créé (carte plage A-xxx →
  fichier, sans passer par AGENTS.md) ; l'index d'AGENTS.md corrigé — le lot v5.13 (A192-A197,
  second chapitre de `lot-v5-12.md`) n'était indexé NULLE PART, trois plages annoncées étaient
  fausses (v5.12 « A170-A179 » pour A170-A197, v5.17 « A227-A230 » pour A227-A237, v5.18
  « A238-A261 » pour A238-A268) ; README remis d'aplomb (« onze harnais » → 21, hébergement
  Workers Assets + adresse de production, contenu du dépôt complété).
- **Écarté en connaissance de cause** : pas de `Cache-Control: immutable` sur `vendor/` —
  les fichiers n'y sont pas nommés par hash, un an d'immutabilité HTTP ferait servir un vieux
  pdf.js après une mise à jour de sécurité (le piège v5.0.0 « la mise à jour qui n'atteint
  personne », au niveau HTTP) ; et pas de re-fusion des `.md`, qui recréerait la troncature
  silencieuse à 797 Ko documentée en v5.10.3.

## [5.19.2] — 2026-08-31
### Le halo de cible se vérifie en capture, la feuille qui dépasse le dit (A278-A279)

Second volet de l'audit design v5.19 — publié avec la 5.19.1 (fusionnée ici), les deux
corrigent les quatre défauts réels que l'audit a mesurés sur l'app servie.

- **« filtres : aides » était une cible de 72×18 px, sous les 24 de WCAG 2.5.8 (A278).** Sa
  conformité reposait sur un halo `::after` de −8 px — rogné par la chaîne d'ancêtres en
  `overflow:hidden` qui ellipse les longs résumés : mesuré à l'`elementFromPoint`, un tap à
  5 px du rectangle atteignait `.dir-wrap`, jamais le bouton. Le dessin porte désormais
  lui-même les 24 px (`.dir-hf` en inline-flex, `min-height:24px` — la rangée absorbe les
  ~6 px), le halo ne restant qu'en bonus là où le clip le laisse vivre.
- **Le trou du garde-fou, plus grave que le défaut : `audit-a11y` créditait les halos SANS
  vérifier la capture.** La sonde cibles lisait les insets du `::after` et comptait la
  surface — tout halo rogné par un clip passait vert (famille v4.31.1 : un contrôle aveugle
  au défaut qu'il couvre ne prouve rien). Elle teste désormais la CAPTURE : pour tout élément
  dont la conformité repose sur le halo, `elementFromPoint` au milieu de chaque côté à halo
  non nul doit rendre l'élément — sinon « halo rogné, capture perdue ». Deux garde-fous
  appris à la première passe : garde d'occlusion (le centre inatteignable — fenêtre ouverte
  par-dessus — n'est pas un halo rogné : la sonde rougissait sur le chrome DERRIÈRE la
  feuille Plan), et abstention hors fenêtre. Plus une surface d'état nouvelle, « filtres
  posés » : le déclencheur n'existe qu'avec un filtre actif et ne vivait dans AUCUNE surface
  mesurée (un défaut hors scope n'est pas un défaut absent, v4.75.0). Preuve rouge→vert :
  sonde ajoutée AVANT le correctif, passe rouge sur le seul témoin visé, puis verte.
- **La Page SFAR annonce son débordement horizontal (A279).** Mesuré : 904 px visibles pour
  1131 de feuille à 1280 — la colonne « NE PAS OUBLIER » coupée en plein mot, et les barres
  de défilement en incrustation ne laissent aucun indice tant qu'on ne défile pas.
  L'ajustement d'office reste REFUSÉ (k ≈ 0,28 à 390 px tuerait toute cible — cf. `svZoom`
  et l'épitaphe `.pg-wide`) : ce qui manquait, c'est que la coupe se DISE. Un mot en encre
  seconde dans la barre d'échelle — « la feuille dépasse à droite — défiler, ou “⤢ Ajusté” » —
  posé/levé par `svApplyZoom` sur la mesure réelle du défileur, dans les deux logements de la
  feuille. Vérifié aux trois états : annoncé à l'ouverture, tu après « Ajusté » (80 %), de
  retour à 1:1.
- **Les trois autres signalements de l'audit, vérifiés puis classés** : la bascule de thème
  « lente » était un artefact de mesure (pane masqué au rendu étranglé — le thème s'applique
  en synchrone, aucune transition couleur > 0,3 s ; corriger au symptôme aurait été le piège
  A267) ; la troncature des titres du rail est un arbitrage écrit (« un titre ellipsé se
  devine, un renvoi tronqué ne se répare pas ») ; le bandeau auteur est déjà conditionnel
  (un seul créneau avec le bandeau système, fermeture définitive mémorisée).

## [5.19.1] — 2026-08-31
### La pile du quai se purge à toute fermeture, et une seule primaire verte (A277)

- **Le bug, mesuré à l'audit design v5.19** (desktop 1280, session vive) : Tout voir →
  Consulter → retour par « Un bloc » laissait le quai en « Revenir au bloc en cours » vert
  plein alors qu'on était déjà sur le bloc — il masquait la commande Consulter, et un tap le
  dissipait sans autre effet. La cause est une asymétrie de logement : à ≥ 1200 px la
  consultation vit en colonne DANS `main` (A15), que le rendu complet du retour d'excursion
  venait de détruire — mais son état (`body.ref-col-on`, le `dp-back` de `#refBtn`) vit HORS
  de `main` et survivait.
- **Réconciliation à chaque `render()`** : si l'état dit « colonne ouverte » mais qu'aucune
  `.ref-col` n'existe plus dans le DOM, la fermeture passe par `closeRefSheet()` — la porte
  unique, quelle que soit la porte de SORTIE. Sémantique de pile : dépiler un niveau du
  dessous emporte ce qui était posé dessus. Le même filet couvre le trou voisin jamais
  signalé : franchir le palier 1200 vers le bas avec la colonne ouverte la tuait de la même
  façon. (La feuille `#refModal` des voies étroites vit hors de `main` et survit à bon
  droit — rien à réconcilier.)
- **Une seule primaire verte — le sommet de pile.** SFAR + Consulter ouverts montraient DEUX
  vertes côte à côte (« Un bloc » + « Revenir ») : deux référents pour un même signe
  (AC 120-71B § 5.5). Quand Consulter est ouvert par-dessus, c'est lui le sommet : « Un
  bloc » garde libellé et geste mais rend le vert, et le reprend à la fermeture de la
  consultation. Écrit aux deux points qui peignent ces boutons (`applyViewChrome`,
  `syncRefBtn`).
- **Témoin de non-régression** : `audit-retour.mjs`, section « pile du QUAI » — cinq mesures
  (une seule verte à chaque étage, purge complète après la séquence croisée, re-tap qui
  rouvre une vraie consultation, vert qui redescend), vérifiées capables d'échouer contre
  l'`index.html` d'avant le correctif (3 rouges montrant les symptômes exacts), fichier
  restauré à l'octet.

## [5.19.0] — 2026-08-30
### La colonne gauche a trois étages, le pied ne dit plus deux fois la même chose (A269-A276)

- **Mesuré avant de décider** (iPad 11″ paysage, 1194 × 834 → 774 px utiles) : avec 3
  bibliothèques et 5 catégories, la colonne demandait **777 px**. Elle défilait d'un bloc, pied
  compris — le ✓ « contenu trouvable par la recherche » était donc **coupé en pleine phrase**
  (capture utilisateur), et avec lui le contrôle d'avant-départ « tout est sur l'appareil », qui
  est précisément ce qu'on vient vérifier avant de partir sans réseau. À 10 catégories il
  manquait 190 px.
- **Trois étages, un seul défile** : le PÉRIMÈTRE (bibliothèques) est fixe en haut, les
  CATÉGORIES sont le seul défileur — intertitre collant compris —, les COMMANDES et l'ÉTAT
  forment un socle fixe en bas. Ce qui ne grandit pas ne bouge plus. Le pied nomade atterrit
  désormais dans le socle (`.hs-foot`), ce qui est exactement ce qui le soustrait au défilement.
- **Densité** : catégories et commandes en rangées de 32 et 34 px (le corps reste à 13,5 px,
  seul le rembourrage tombe à 6) — **sept catégories tiennent sans défiler** là où cinq
  débordaient. ⚠ Les comptes restent collés à droite : la maquette leur réservait la colonne de
  34 px du crayon pour les aligner sur ceux des bibliothèques, écarté à la relecture
  (« ça fait bizarre sinon »).
- **La remise à zéro des catégories manquait** : « Toutes » existait pour les bibliothèques,
  rien en face — on ne revenait à l'union qu'en re-tapant la rangée active, un geste que rien
  n'annonce. Une rangée « Toutes les catégories » ferme la symétrie ; son compte est celui du
  PÉRIMÈTRE choisi, pas de l'application entière.
- **Une commande n'est plus dessinée comme un filtre** : icône, libellé en gras, chevron. Le
  nombre en queue voulait dire « ce que la liste montre » pour une catégorie et « ce qu'il y a
  derrière la porte » pour l'historique — deux sens pour un même signe.
- **Le pied ne dit plus deux fois la même chose** : au nominal, les deux phrases « Documents
  PDF : … » — qui commençaient par les mêmes mots et laissaient « (15) · Réindexer » partir
  seul à la ligne suivante — fusionnent en **une rangée** « ✓ 15 documents prêts hors ligne »,
  dépliable SUR PLACE (pas de fenêtre, règle 11). Dès qu'une des deux a quelque chose à
  demander, la synthèse s'efface et les deux lignes reprennent la parole telles quelles,
  registre ambre compris : **on ne masque jamais un état qui appelle un geste**.
- **Aucun aplat** : la maquette posait la synthèse sur un fond vert doux ; refusé à la relecture
  (« ça saute trop aux yeux ») — et le code disait déjà pourquoi, `refreshAttOffline` portant
  « P3-11 : nominal = neutre » et `.pers-warn` colorant le TEXTE, jamais un fond. Un aplat vert
  permanent aurait désensibilisé à l'ambre, seul registre qui doit se voir. L'accroche vient du
  CHIFFRE en encre pleine : c'est ce qu'on vérifie.
- **Le pied devient une colonne de rangées** (A271), sur les trois largeurs où il vit (250 px en
  socle de colonne, ~574 et ~300 en voie étroite). La coulée `flex-wrap` mettait la version en
  bout de la rangée des liens à 574 et la rejetait sous eux à 300 : l'ordre de lecture changeait
  avec la largeur, et **trois bords gauches cohabitaient** (18 px pour une marque, 28 pour le
  texte d'un lien, 36 pour celui d'un état), avec 2 px d'interligne entre des rangées de 32.
  Désormais : une colonne, un interligne de 4 px, et **une seule colonne de texte à 20 px** —
  marque de 14 px + gouttière de 6 — que les liens rejoignent en recevant leur icône (les mêmes
  que dans la colonne). La marque de l'état de stockage sort du texte (elle n'existait que dans
  l'état « Cloud », et décalait le premier mot d'une largeur variable selon l'état).
- **Les deux lignes d'état prennent le même dessin** — elles sont toutes deux des commandes
  (l'une ouvre la fenêtre Stockage, l'autre déplie) : marque, texte, chevron, et la hauteur de
  32 px que la règle 9 leur devait déjà. `#storageInfo` vivait à 15,4 px depuis toujours.
- **Une seule hauteur de rangée dans la colonne** : la première version densifiait les seules
  catégories (32 px) et laissait les bibliothèques à 38 — deux hauteurs, à un filet d'écart, pour
  deux listes qui font la même chose. 32 partout.
- **Un seul dessin de marque dans le pied** (A272) : la pastille de synchro était son seul OBJET
  — une pilule teintée de 22,7 px au milieu de lignes de 15,4 — et sa rangée n'avait rien dans la
  colonne de marque. La pilule tombe, l'état rejoint la colonne, et son point plein cède la place
  à un **glyphe par état** (✓ synchronisé, ↺ en cours, ⏸ hors-ligne, △ erreur, 🔒 en attente) au
  gabarit des trois autres. Les états qui appellent un geste gardent leur encre de registre sur
  le texte, jamais un fond.
- **Les deux commandes du pied deviennent des boutons discrets** en voie étroite : en lien, elles
  flottaient dans un bloc d'état, et leur cible se réduisait à la longueur du mot. Surface tonale
  sans contour, 36 px. Coût mesuré et assumé : à 390 px les deux libellés entiers ne tiennent pas
  sur une rangée (339 px pour 354 disponibles), elles s'empilent — 78 px au lieu de 32, compensé
  en partie par l'interligne du pied ramené de 4 à 2 px.
- **L'interligne du pied ne se réglait pas en pixels** : un `gap` unique se lisait 4, 12 puis
  19 px selon les rangées qu'il séparait, parce qu'elles n'avaient pas la même hauteur (20 px pour
  la version, 32 pour les deux commandes) et que le blanc interne d'une rangée s'ajoute au gap.
  Les trois rangées font désormais 32, le gap tombe à 0, et le seul écart qui reste (6 px) sépare
  les deux registres — commandes et état.
- **Les rangées d'état s'arrêtent à leur texte** : elles prenaient toute la largeur, donc le
  chevron se collait au bord droit en laissant des centaines de pixels de vide, et la marque
  restait seule à l'autre bout. Le groupe marque · texte · chevron redevient un objet, au même
  retrait (12 px) et au même rayon que les boutons du dessus ; la surface n'apparaît qu'au survol.
  Toutes les marques du pied tombent alors sur la même verticale, boutons compris.
- **Trois verticales dans la colonne, et trois seulement** (A273) : quatre libellés démarraient à
  quatre abscisses (24 · 41 · 45,5 · 46), chaque famille posant son texte où sa marque tombait.
  Une **colonne de marque de largeur fixe**, portée par toutes les rangées et laissée vide quand
  il n'y a rien à y mettre, remet tout d'aplomb — marque à 24, libellé à 44, nombre au bord droit.
  Le nombre passe **après** le crayon : c'est ce qui aligne les deux colonnes de comptes sans
  réserver la case du crayon partout. Une seule hauteur de rangée (32), un seul filet, et les deux
  pavés pleine largeur (« Nouvelle bibliothèque », « Gérer les catégories ») deviennent des
  rangées discrètes. Le socle suit le contenu au lieu de laisser un trou de 120 px au milieu.
- **Le socle se replie en une ligne** (A274) : il empilait cinq rangées de même forme sur 216 px
  pour dire deux commandes et un état. Au nominal, les quatre lignes d'état deviennent
  **« ✓ Tout est prêt · v5.19.0 »**, dépliable sur place ; dès qu'un fait appelle un geste
  (documents manquants, index en échec, synchro refusée, stockage presque plein), elles reprennent
  la parole telles quelles. Le dépliant est **subordonné** — ses rangées démarrent sous le texte
  de la synthèse, pas sous sa marque.
- **Intitulés réécrits, courts** : « Prêt hors ligne » puis « Utilisable sans réseau » ont été
  essayés et abandonnés — le premier se lisait comme un état de connexion, le second ne couvrait
  pas la recherche dans les documents. « 15 documents sur l'appareil », « Recherche dans les
  documents », « 3 documents à télécharger », « Indexation en cours (4) ». Les actions de ces
  rangées passent à 11 px : un lien de 13,5 px faisait un mot deux fois plus gros que sa phrase.
- **Trois blancs verticaux, pas sept** : la colonne séparait ses blocs par 10 · 2 · 14 · 4 · 8 ·
  12 · 31 px, chaque valeur héritée d'un réglage local. L'échelle est désormais 2 (entre rangées),
  10 (d'un intertitre à sa première rangée), 12 (au-dessus d'un intertitre et de part et d'autre
  d'un filet).
- **Le type à créer ne filtre plus la liste** (A275, signalé à l'usage : « Créer → aide cognitive
  mène à une vue filtrée qui n'est plus censée exister »). Le dialogue empruntait `state.section`
  depuis la v4.4.2 — juste quand l'accueil était une liste par type, faux depuis que la liste est
  l'union. Il a son propre cran. ⚠ **Deux harnais s'appuyaient sur ce défaut** : l'un gardait
  l'ancien contrat, l'autre cliquait le sélecteur du dialogue en croyant changer de section — et,
  la liste des protocoles étant vide dans le jeu d'exemple, ses deux témoins mesuraient l'accueil
  en croyant mesurer une lecture. Les deux sont réécrits, et la lacune du second est écrite dans
  le fichier.
- **Dire ce qu'est une aide cognitive, et un protocole** (A276) : le dialogue « Créer » l'explique
  en une phrase par nature, depuis la même source que les bandeaux. Et les deux bandeaux de
  bibliothèque vide fusionnent en **un seul** qui pose les deux natures côte à côte — écrits pour
  un accueil filtré par type, ils s'empilaient toujours ensemble depuis l'union, et la question
  qu'on se pose vraiment (« quelle est la différence ? ») n'avait de réponse nulle part.
- **Le rappel du raccourci suit le système** : `⌘K` sur Apple, `Ctrl K` ailleurs (le gestionnaire
  acceptait déjà les deux, plus « / »), et le champ réserve la largeur du plus long des deux.
- **En voie étroite, « Rangé par » et « Sélectionner » passent sous « Répertoire »** : ils
  gouvernent cette liste, ils ne la précèdent pas.
- **Les 18 px sous l'en-tête tombaient sur `#syncErrNotice`**, présent mais masqué — donc sur une
  boîte sans hauteur : le premier bandeau touchait l'en-tête.
- **Deux pièges payés en chemin**, tous deux notés sur place : (1) le bloc de style est déclaré
  AVANT `.hs-row`, donc `.hs-cat{min-height:32px}` perdait la cascade **en silence** (rangées
  mesurées à 38 px) — qualifié en `.hs-row.hs-cat` ; (2) la marge basse du filet de l'étage haut
  s'échappait de sa boîte et ouvrait une bande de 12 px entre les deux étages, assez pour laisser
  voir ce qui défile dessous : la marge tombe, et les deux étages fixes deviennent opaques et
  au-dessus. Écart mesuré à 0, intertitre collé au bord du défileur, socle immobile sous
  défilement (bas du pied identique avant et après).

## [5.18.5] — 2026-08-30
### L'anneau de focus n'est plus rogné par les fenêtres (A268)

- **Signalé sur captures** : « l'encadré de sélection des champs et des boutons est coupé par la
  fenêtre, dans plusieurs modales ». Cause : le corps des fenêtres (`.ai-body`) ferme son axe
  horizontal depuis la v5.10.5 — décision juste, gardée telle quelle — et un champ y occupe
  TOUTE la largeur : son anneau (2 px de trait + 2 px de décalage) tombait pile sur le bord de
  découpe et se voyait amputé à gauche et à droite. Un état de focus amputé est un défaut
  d'accessibilité, pas une coquetterie.
- **L'axe n'est pas rouvert** : le bord de découpe s'écarte de 4 px, rendus par une marge
  négative — le contenu ne bouge pas d'un pixel (mesuré 423..857 avant et après), la découpe
  respire. Vérifié au clavier à 1280 comme à 390 px : anneau entier, 4 px de marge de chaque
  côté. En HAUTEUR, `scroll-padding` évite qu'un champ atteint au clavier ne se colle au bord
  du scrollport.
- **`overflow-clip-margin` ne pouvait pas servir** — la propriété faite pour ça est ignorée dès
  que l'élément défile (`overflow-y:auto` en fait un conteneur de défilement) : c'est noté dans
  la doctrine pour la prochaine fois.
- **Trouvé en chemin** : le dépliant « Pourquoi créer un compte ? » n'avait AUCUNE règle de
  focus — il rendait l'anneau par défaut du navigateur (couleur hors palette, épaisseur non
  maîtrisée), seul de sa famille dans ce cas. Comblé.

## [5.18.4] — 2026-08-30
### Le clavier ne part plus tout seul (A267)

- **Signalé le jour même** : « si la page rétrécit pendant une recherche qui s'affine, le
  clavier disparaît ? ». Oui — et c'était une faille de conception, pas un réglage : la v5.18.3
  refermait le clavier sur l'ÉVÈNEMENT `scroll`, or une liste qui RACCOURCIT sous la frappe fait
  recaler le défilement par le navigateur, qui émet `scroll` sans qu'aucun doigt n'ait bougé. Le
  clavier se fermait donc en pleine saisie, au pire moment. La garde de 600 ms n'y pouvait rien :
  le cas arrive bien après l'ouverture.
- **Seul un GLISSEMENT réel referme désormais** : `touchmove` de plus de 10 px vertical, né HORS
  du dock (dans le champ, le geste est celui du curseur ; dans la rangée de crans, un défilement
  horizontal). Une remise en page n'émet jamais de touchmove. Vérifié dans les deux sens : le
  focus TIENT sur un recalage programmatique, il PART sur un glissement de 70 px.
- **La leçon, écrite dans la doctrine** : pour distinguer « l'utilisateur a fait X » de « il
  s'est passé X », écouter l'ENTRÉE, jamais la conséquence.

## [5.18.3] — 2026-08-30
### Suites du terrain iPhone (A266)

- **Défiler referme le clavier** (signalé : « en scrollant, la barre saute et la bande
  disparaît »). Suivre le viewport visuel pendant un défilement clavier-ouvert est
  structurellement saccadé (les variables sont sondées) — et l'utilisateur qui défile a fini de
  taper : au premier défilement (fenêtre ou viewport visuel, garde de 600 ms car l'ouverture du
  clavier émet ses propres évènements), le champ rend le focus, le clavier se referme, la
  liste se lit plein écran et la pilule revient en bas. Le patron d'iOS Mail/Safari.
- **La zone sûre du haut est couverte** (signalé en PWA installée : « le bandeau de sélection
  se retrouve sous l'heure », idem pour les intertitres collants). L'en-tête est statique
  depuis la v5.18 — une fois défilé, plus rien ne portait `env(safe-area-inset-top)` : un sol
  fixe couvre la bande de l'encoche (le contenu ne défile plus sous l'heure) et le bandeau de
  sélection comme les intertitres s'arrêtent dessous. Inerte en navigateur (env vaut 0).
- **Le rythme sous l'en-tête est UN** : le titre « Résultats — toutes les bibliothèques »
  naissait collé (marge haute nulle) — 18 px sous l'en-tête partout désormais (Accès direct,
  Résultats, et la voie large), mesuré aux deux largeurs.
