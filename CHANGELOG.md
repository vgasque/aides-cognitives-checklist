# Journal des modifications

## [5.3.0] — 2026-08-07
### La recherche dans les PDF va au bout du geste — auto-indexation, porteurs en résultats, surlignage dans la visionneuse

Quatre retours d'usage sur la v5.2.0, vécus sur la PWA de l'auteur le jour même, tous les quatre
livrés.

- **Le rattrapage d'indexation est AUTOMATIQUE — revirement assumé** (« l'indexation ne s'est pas
  lancée automatiquement, j'ai dû cliquer ») : la v5.2.0 exigeait un geste explicite pour ne
  jamais lancer de tâche de fond spontanée ; à l'usage, l'état nominal attendu est « mes
  documents sont trouvables », pas un bouton pour un travail que la machine sait faire seule.
  `ixLoadAll` met en file les documents en attente au démarrage — ~4 ms/page, un à la fois, à
  l'inactivité, et pdf.js ne se charge QUE s'il existe des documents à indexer (un démarrage
  ordinaire n'y touche pas). La ligne du pied devient un indicateur d'avancement ; son bouton
  « Indexer » reste, filet des cas où la file s'est arrêtée.
- **Le porteur du document est lui aussi un résultat** : chercher un mot qui ne vit que dans le
  PDF joint sort l'AIDE dans la liste (les trois vues, `entityDocHit` dans les filtres, renvoi
  croisé compris), avec l'extrait « dans ‹nom› · p. n » — le OÙ, jamais le contenu, qui n'est
  pas stocké. Le groupe « Dans les documents » reste : deux objets, deux gestes.
- **La recherche d'une entité couvre ses annexes** : le champ d'une référence et celui de la
  feuille « Toute la fiche » listent sous le champ (`#pfDocs`) les documents joints où tous les
  termes apparaissent ; un tap ouvre la visionneuse à la page, occurrences surlignées. Un mot
  absent replie la zone.
- **Les occurrences se surlignent dans la visionneuse et se naviguent** (« comme le texte des
  fiches ») : les PAGES viennent de l'index déjà en mémoire (coût nul), les POSITIONS sont
  retrouvées au rendu de chaque page visible (`pdfPaintHl` — `getTextContent` ~3 ms, en cache) et
  posées en rectangles `--verify-soft` en `mix-blend-mode:multiply`, même registre que le
  surlignage du texte. Pilule flottante ‹ n/N · p. x › : navigation par page d'occurrence. La
  position dans une ligne est approchée au prorata des caractères — le compromis qui évite
  d'embarquer la couche texte entière de pdf.js. Ouvert depuis sa RANGÉE : ni surlignage ni
  pilule — on vient lire, pas chercher.
- Vérification : `audit-pdfsearch` passe de 26 à **37 contrôles**, verts sur les deux moteurs —
  dont l'auto-rattrapage au démarrage sans clic, le repli sur mot absent, la boîte de chaque
  rectangle dans sa page, et l'ouverture neutre depuis la rangée. Deux témoins corrigés en les
  écrivant (un mot qui ne vivait que sur une page ne pouvait pas faire naviguer ; la rangée de
  documents d'une fiche vit dans « Consulter », pas dans le flux). Passes complètes 17/17 check ·
  920 × 2 tests · 20/20 harnais.

## [5.2.0] — 2026-08-07
### La recherche trouve dans les documents PDF — un index inversé, jamais une copie du texte

La recherche trouvait la FICHE, jamais l'endroit : un protocole de service joint en PDF pouvait
porter la seule mention d'une dilution, et rien ne la trouvait. Et deux correctifs de moindre
taille livrés dans la même version : le compte-rendu s'enregistre en PDF, et « Répéter en
exercice » n'allume plus l'accueil avant le premier geste.

- **Chercher dans les documents PDF** (`ixBuild`/`ixOpen`/`ixSearch`, purs et testés ; store
  IndexedDB `attidx`, base v6). La première approche — conserver le texte extrait et le balayer —
  a été REFUSÉE par l'auteur, à raison : ~100 % du poids du texte (546 Ko mesurés pour 200 pages)
  et un plafond obligatoire, donc des documents indexés à moitié. On fait ce que font Spotlight,
  Finder et Lucene : un **index inversé** — dictionnaire des mots distincts (front-codé) + pages
  de chaque mot (varint-delta, ou bitmap pour les mots trop fréquents). Le poids suit le
  VOCABULAIRE, qui sature : mesuré sur du français technique réel, 13,4 % du texte à 626 Ko
  (34 % à 49 Ko) — **aucun plafond, indexation intégrale, toujours**. L'index natif d'IndexedDB
  (`multiEntry`) a été mesuré et écarté : ×47 en occupation réelle ; SQLite FTS5 n'existe pas
  dans un navigateur et l'amener en WASM serait une seconde dépendance runtime (règle 13).
- **Aucun extrait dans les résultats, et c'est la clé** : la rangée « Dans les documents » donne
  le nom, le nombre de passages, les PAGES et la fiche qui porte le document — le contexte se lit
  dans le document, qu'un tap ouvre À LA PAGE (`openPdfViewer` accepte une page). pdf.js
  (1 773 Ko) n'est donc JAMAIS chargé pendant qu'on tape. Correspondance par sous-chaîne, comme
  le reste de la recherche (« drenalin » trouve « adrénaline »).
- **Indexation à l'arrivée du binaire — les CINQ arrivées** : `attPut(rec)` est le point
  d'étranglement unique (patron `persistLive`) ; trouvé en le posant, l'indexation n'était
  accrochée qu'à deux des cinq chemins (manquaient le « Télécharger » manuel, le téléchargement
  immédiat de la visionneuse et l'import .zip). `check-stores` compte désormais les sites
  d'écriture. File à l'inactivité, un document à la fois ; rattrapage des documents déjà là par
  un geste explicite (ligne du pied de la sidebar), jamais en tâche de fond spontanée.
- **Résilience** : deux familles d'échec distinguées — transitoire (binaire absent, pdf.js hors
  cache : rien n'est retenu, trois essais par session puis « Réessayer ») et durable (`scan` /
  `illisible` : état enregistré, sinon le compte « à indexer » ne descendrait jamais).
  `ixAdopt` est l'unique point d'adoption : un enregistrement illisible est JETÉ et le document
  redevient « à indexer » — le défaut inverse (un `null` rangé dans la table) aurait rendu tous
  les documents non ré-indexables au premier changement de version d'index. **Réindexer** existe
  pour tout (ligne du pied, avec confirmation) et pour un document (sa rangée d'éditeur). Le
  décodeur est TOTAL : enregistrement tronqué refusé en bloc, aucune boucle infinie possible,
  aucune page rendue hors du document.
- **Confidentialité** : l'index est DÉRIVÉ et strictement LOCAL — jamais synchronisé, jamais
  exporté (un dictionnaire EST la liste des mots d'un document clinique ; le faire voyager serait
  une catégorie nouvelle de donnée sortante, pour zéro gain — il se reconstruit en ~4 ms/page).
  Il vit dans la base de l'ESPACE : un compte par index sur un poste partagé, déménagé avec le
  reste, effacé avec le reste. Le contenu des PDF n'atteint jamais le DOM (aucun texte stocké,
  aucun extrait affiché) ; le seul texte non maîtrisé est le NOM du document, couvert par `esc()`
  et éprouvé par un témoin au nom hostile.
- **Le compte-rendu s'enregistre en PDF** (demande utilisateur) : « Télécharger » (.html) et
  « Imprimer » deviennent « Fichier .html » et « **Enregistrer en PDF** » (rempli) — le second
  EST le chemin d'impression (iframe A4), seul producteur de PDF du projet ; un seul bouton pour
  ce chemin (AC 120-71B §5.5), le .html restant le repli qui ne dépend d'aucun dialogue système,
  et le message d'échec le nomme.
- **« Répéter en exercice » n'allume plus l'accueil avant le premier geste** (signalé à l'usage :
  chrono figé à 0:00 et « Session en cours » dès l'entrée en exercice) : `startExercise`
  n'inscrit plus le runtime dans `liveSessions` — `ensureStarted` le fait au premier geste, comme
  pour une session réelle ; le prédicat `sessionLive()` (présence ET `started`) remplace les deux
  tests de présence de la rangée et de la tuile.
- Vérification : 26 contrôles `audit-pdfsearch` (nouveau harnais, PDF fabriqué xref calculé, vert
  sur les DEUX moteurs — dont « pdf.js n'est pas chargé par la frappe », mesuré sur page
  rechargée), 25 témoins unitaires de l'index (bitmap, front-codage, résilience), sonde dédiée du
  correctif exercice ; passes complètes 17/17 check · 920 × 2 tests · 20/20 harnais.

## [5.1.2] — 2026-08-05
### Purge des commentaires orphelins (règle 14) — et la rangée de commandes ne disparaît plus d'une fiche sans annexe

Passe d'hygiène demandée sur les ~839 Ko de commentaires du monofichier : le croisement de tous
les identifiants cités en commentaire avec le code réel n'a trouvé que 34 absents, presque tous
des mentions historiques volontaires (tombstones, renvois aux pièges de cascade) — conservées.
Le reste, les vrais vestiges, est purgé ; et la purge a mis au jour un défaut réel.

- **⚠ Correctif `syncDock` (retombée de purge, règle 14)** : depuis les lots T8/A (v5.0.0) la
  rangée de commandes porte `#allBtn` et `#refBtn`, mais son test de visibilité lisait encore
  `#modeSeg` et `#planBtn` (toujours null) en ignorant `#allBtn` — une fiche À ALGORITHME mais
  SANS annexe (Consulter masqué) perdait donc la rangée entière, « ⤢ Tout voir » compris, en
  silence. Les fiches d'exemple ayant toutes des annexes, aucun harnais ne rencontrait le cas.
  Prouvé par une sonde qui le CONSTRUIT : rouge sur l'ancienne logique (rangée masquée, bouton à
  0 px), verte sur la corrigée, fichier restauré à l'octet entre les deux (leçon v4.31.1).
- **Six blocs de commentaires orphelins du sélecteur de mode** (`#modeSeg`, `.ctrl-sp` — purgés au
  lot A) flottaient dans le CSS sans plus aucune règle en dessous : remplacés par un tombstone de
  trois lignes. La seule doctrine encore vivante — le fond de pastille n'est jamais `--surface`,
  qui s'inverse entre thèmes — déménage sur le composant `.seg` générique, où elle s'applique.
- **Le « HUITIÈME PIÈGE DE CASCADE » vivait en DEUX versions successives** (l'originale et sa
  réécriture v4.55.0, conservées côte à côte par erreur) : dédoublonné, et mis à jour — la
  surface qu'il cite (mode lecteur) est partie au lot T14 ; la leçon de spécificité reste.
- **Trois commentaires remis au vrai** : la recette 320 px citait `.ctrl-sp` au présent ; le bloc
  d'enroulement portait une phrase MUTILÉE par une ancienne édition (deux moitiés de phrases
  recollées) ; la délégation de la feuille Plan justifiait son choix par `#pmViews`, disparu en
  v4.25.0. Et la bannière « ORGANIGRAMME HYBRIDE (mode Détails) » — vue supprimée en v4.25.0 —
  renommée « ÉCHELLE DU PLAN », ce qu'elle contient réellement.
- **Code mort purgé** : `modeTopSegH` (constante vide et son interpolation, vestige de la bascule
  d'en-tête) et le mécanisme `kb-open` entier — deux écouteurs posaient une classe que plus
  aucune règle CSS ne lit depuis que les actions d'éditeur vivent dans l'en-tête sticky.
- **Le CHANGELOG revient à 20 entrées** (il en comptait 28) : les neuf plus anciennes (4.70.1 →
  4.74.0) rejoignent `docs/changelog/v4.md` telles quelles, sans réécriture.

Bilan : 88 lignes supprimées, 36 ajoutées. Vérifié : `npm run check` complet, 894 tests × deux
moteurs, passe d'audit COMPLÈTE (19 harnais). Le gisement « commentaires périmés » était petit à
dessein — le reste des 839 Ko est de la doctrine volontaire, et il reste en place.

## [5.1.1] — 2026-08-05
### La palette de catégories re-résolue en espace perceptuel — six teintes corrigées, à problème nommé chacune

L'action 7 de l'audit v5.0.0 (« désaturer les catégories ») avait été refusée sur mesure — à
raison pour une désaturation d'ensemble. Rejouée en OKLCH (point 1 de l'audit direction A), la
bonne métrique montre que le problème était PONCTUEL, pas global : trois catégories étaient
perceptuellement COLLÉES à un registre d'alerte, deux l'étaient entre elles, et quatre passaient
sous 3:1 sur surface sombre.

- **Ce qui était mesuré (dE_OK, distance OKLab ×100)** : l'olive #806311 à **3,0** du registre
  ambre `--verify` — au premier regard, une catégorie pouvait se lire comme un signal de
  vigilance ; le vermillon à 3,1 de `--critical-bd` ; le vert #1d7449 à 3,3 de `--ok` ; les deux
  sarcelle/bleu à 5,1 l'une de l'autre ; et #45556b, #0d5b56, #4b3fa6, #7a2f6b entre 2,26 et
  2,56:1 sur le sombre (la couleur stockée est rendue brute dans les deux thèmes).
- **La correction est chirurgicale** : six teintes bougent (0, 2, 4, 5, 6, 9), sept sont
  intactes. Déplacements minuscules — dE_OK 1,3 à 2,8, sauf l'indigo (6,2) qui devait remonter
  pour son contraste sombre (2,37 → 3,10). Plancher des distances : **3,0 → 4,0**. Le caractère
  sourd de la palette est conservé (chroma quasi inchangée) : un premier solveur qui maximisait
  librement les distances proposait des néons, et a été corrigé en objectif lexicographique sur
  les plus petites distances.
- **⚠ Les contraintes de clair sont celles du test de régression #3**, pas « sur blanc » : texte
  couleur sur sa teinte à 15 % ≥ 4,5:1 ET blanc sur couleur pleine ≥ 4,5:1. Un premier jet
  contraint « sur blanc » a produit trois teintes que `npm test` a refusées (3,74-3,95) — le
  garde-fou a fait son travail, et le solveur reprend désormais `tint15`/`ratio` à l'identique.
- **Sans rupture par construction** : la couleur vit dans la catégorie stockée — les choix
  existants ne changent pas d'un pixel ; seuls le nuancier proposé et `defaultCats` (nouvelles
  installations) sont corrigés. Trois teintes restent < 3:1 en sombre (#45556b, #0d5b56,
  #7a2f6b) : aucun candidat conforme n'existe dans le budget de reconnaissabilité (vérifié au
  solveur) — dit, pas caché, et atténué par la règle « la couleur n'est jamais seule ».
- **Et « Urgences » par défaut porte enfin le vermillon.** `defaultCats()` lui donnait `#1f5fa6` —
  le bleu `--primary` — depuis sa création en v3.0.0 ; la règle « pas de bleu primaire pour une
  catégorie » posée en v4.1.0 avait corrigé le nuancier **sans toucher le jeu par défaut**
  (vérifié à l'historique : le commit de la règle ne modifie pas `defaultCats`). Aligné sur
  `#b23240`, la couleur que la doctrine destine nommément aux catégories d'urgence — nouvelles
  installations seulement, aucune migration des catégories existantes.

## [5.1.0] — 2026-08-05
### Direction « Instrument clinique » — six lots de matière issus d'un audit UX externe, aucun contrôle déplacé

Un audit UX/direction artistique complet (7 axes, mesures sur l'application réelle à 320/390/1280,
deux thèmes) a conclu que l'interface était conforme et confortable, et a proposé une direction de
modernisation « Instrument clinique », validée sur prototype comparatif A/B. Tout ce qui suit est
de la MATIÈRE : aucune position de contrôle ne change, aucune règle de sûreté n'est touchée.

- **Une seule voix système à la fois.** Mesuré à 390×844 : au premier lancement, le bandeau
  « 2 fiches d'exemple ajoutées » et la notice « Vous êtes l'auteur… » s'empilaient — premier
  contenu clinique à 39 % de l'écran, et les deux textes énonçaient la même responsabilité
  éditoriale. Le bandeau absorbe désormais le texte de la notice ; tant qu'il est visible, la
  notice attend son tour et paraît à l'acquittement (« J'ai compris » ou ✕). ⚠ La garde teste la
  classe `body.view-home` — le même prédicat que la visibilité CSS du bandeau — et non
  `state.view`, qui vaut `'library'` sur l'accueil (payé à la première livraison).
- **La recherche est un creux.** Le champ passe sur `--surface-2` avec un filet d'1 px (les 2 px
  de bordure rendus au rembourrage) : une zone de saisie se distingue d'une carte de contenu par
  le renfoncement — et en sombre `--surface-2` est plus foncé que la surface, le creux tient dans
  les deux thèmes. Le placeholder garde sa phrase entière et s'**ellipse** quand la place manque,
  au lieu de se couper en plein mot (défaut mesuré à 390 px).
- **Les lettres du répertoire parlent serif.** La lettre de classement (`.dir-l`) passe en Source
  Serif 4 13,5 px/600 — la police et la graisse déjà embarquées : un index d'ouvrage, pas du
  chrome. Le rail A→Z reste en mono (cibles minuscules, la lisibilité prime).
- **Une seule famille d'ombres en clair.** Les élévations du thème clair (`--shadow`, `-lg`,
  `-up`, `-dock`, `-bar`) sont teintées primaire (23,71,127), comme l'étaient déjà les boutons
  remplis ; les voiles restent à l'encre (un voile assombrit, il n'élève pas) et le sombre garde
  ses ombres noires.
- **Neuf variantes tonales suivent leur base.** `--primary-soft/-100/-200`, `--ok-soft`,
  `--done-bg`, `--tag-bg` (clair) et leurs pendantes sombres se **dérivent** par `color-mix`
  (`@supports`, repli hex intact), aux pourcentages mesurés qui reproduisent le hex actuel à
  ≤ 4/255 par canal — aucun changement visible, mais changer une base met à jour sa famille.
  `--primary-300`, `--critical-soft` et `--verify-soft` restent en hex : leur écart au mélange
  pur (Δ 5 à 16) est un accord de teinte voulu.
- **Au palier cockpit (≥ 1200 px), le chrome s'efface derrière ses contrôles.** Mesuré à
  1280 px : la rangée de commandes était une bande blanche de bord à bord au contenu arrêté à
  x = 256 (1024 px de vide). Les deux rangées collantes prennent le fond de page ; boutons et
  cartes, qui portent déjà leurs bordures, se lisent comme des contrôles posés sur la page.
- **Pilote View Transitions.** Les traversées accueil → fiche (sans session vive) et
  fiche → bibliothèque se font en fondu de 180 ms piloté par le moteur (`vtWrap`) — trois
  gardes : API présente (sinon comportement d'avant au caractère près), aucune crise à l'écran
  (le mouvement reste réservé à l'alarme), et `prefers-reduced-motion` coupe tout. ⚠ Sous VT le
  rendu est asynchrone d'une frame : deux sondes qui lisaient le DOM juste après un clic de
  carte ont été mises au standard du dépôt (attente de condition réelle, discipline `amorce()`).
- **L'écran de bienvenue étroit est composé.** Le glyphe de marque (masque `logo-glyph.svg`,
  couleur de filet, décoratif) habite les ~430 px de vide mesurés entre le texte et
  « Commencer » ; `text-wrap:balance` équilibre les titres non clampés.
- **Étudiés et écartés, avec la raison** (consignée dans AGENTS.md) : entrées `@starting-style`
  (les keyframes `veilIn`/`riseIn`/`menuIn` couvrent déjà le besoin), duplication des neutres en
  oklch (une copie par token est la liste tenue en double de v4.37.0), scrims dérivés de
  `--ink` (en sombre l'encre est claire : le voile deviendrait blanchâtre).

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
