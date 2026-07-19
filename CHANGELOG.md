# Journal des modifications

## [4.14.5] — 2026-07-19
### Corrigé
- **Mode Statique — la flèche de convergence ne traverse plus les blocs élargis**
  (ex. anaphylaxie : la flèche du bloc 11 « symptômes gastro-intestinaux » vers le bloc 12
  passait sur les blocs élargis de la branche voisine). Cause : la pilule « → 12 »
  remplacée par le brin libérait sa place, l'élargissement s'y étendait, puis le brin
  redessiné traversait les cellules. Désormais : un brin n'est dessiné que si son **couloir
  vertical est libre** — sinon la branche **garde sa pilule** (l'information reste locale au
  bloc) ; et une pilule remplacée reste invisible **sans libérer son espace** (plus
  d'oscillations de recalcul). Vérifié sur les 6 fiches tachycardies + ACR + anaphylaxie :
  zéro superposition, élargissements et brins légitimes conservés.

## [4.14.4] — 2026-07-19
Corrections issues des essais sur les fiches tachycardies/SVT (6 algorithmes très
ramifiés, imbrications à 4 niveaux).

### Corrigé
- **Mode Statique — l'élargissement fonctionne dans les deux sens** : sur ces fiches, la
  branche courte (« instable → choc ») est à **gauche** et la longue à droite — l'extension
  ne s'appliquait jamais (elle ne regardait qu'à droite) et l'algorithme restait coincé
  dans une demi-colonne avec tout le côté gauche vide. Le critère devient un **test de
  collision global** (l'espace convoité ne doit contenir aucun contenu extérieur, à toute
  profondeur d'imbrication) et l'extension se fait à gauche comme à droite. Vérifié sur les
  6 fiches : « Régularité du rythme » s'étend à pleine largeur, zéro collision, zéro
  débordement, y compris sur l'orage rythmique à 4 niveaux.
- **Fil d'ancêtres — hauteur stable** : l'apparition du « › Oui / › Non » dans une bulle ne
  décale plus le texte vers le haut/bas (hauteur de ligne réservée).
- **Vue guidée — plus de saut au « Continuer »** : valider une étape faisait défiler la vue
  (~200 px d'alignement systématique + ~70 px de dérive du navigateur) même quand tout
  était visible. Le remplacement du bloc est désormais **ancré** (le nouveau bloc apparaît
  exactement là où était l'ancien) et le rattrapage ne se produit plus que si le fil
  d'Ariane ou le bloc ne sont pas entièrement à l'écran. Mesuré sur 4 validations
  successives : mouvement visuel nul.

## [4.14.3] — 2026-07-19
### Corrigé
- **Fil d'ancêtres — plus de battements** : en fin de branche, les bulles pouvaient
  apparaître et disparaître en rafale (la hauteur de la pile modifiait la ligne qui
  décidait du contenu de la pile — boucle de rétroaction). L'entrée/sortie est désormais un
  **cumul déterministe** (le seuil de chaque bulle est le bas de la pile au-dessus d'elle,
  hauteurs réelles mémorisées) avec **hystérésis** (~16 px entre seuils d'entrée et de
  sortie) : les transitions sont uniques et monotones, le décrochage est propre.

### Modifié
- **Mode Statique — les arbres imbriqués s'étendent** : quand toutes les branches sœurs à
  droite d'une décision imbriquée sont terminées au-dessus d'elle (colonne devenue vide),
  la décision **s'élargit** dans l'espace libéré — ses sous-branches gagnent en largeur,
  comme sur un algorithme papier ; si la bande-question fait encore face à une sœur, seules
  la fourche et les colonnes s'élargissent (jamais de collision). Recalculé au rendu et au
  redimensionnement, flèches repeintes sur la géométrie finale.
- **Mode Statique — bouton « démarrer la session » intégré au carrelage** : coins de 3 px,
  pleine largeur de rangée, espacement du joint de la grille — il s'aligne avec les
  cellules tout en restant l'unique bouton rempli de la page (≥ 44 px).

## [4.14.2] — 2026-07-19
### Corrigé
- **Fil d'ancêtres — rangée partagée** : quand deux branches sont côte à côte et que l'une
  est plus longue, la bulle réaffichait son option dès que la ligne de lecture dépassait le
  bas de la plus courte — trompeur, la rangée parallèle étant encore à l'écran. L'option ne
  s'affiche désormais que si la branche est **seule sur sa rangée** (aucun chevauchement
  vertical avec une sœur).
- **Fil d'ancêtres — entrée dans la pile** : une bande de décision pouvait disparaître
  **derrière** la pile de bulles avant d'y être représentée (la détection se faisait à
  hauteur fixe, sous une pile devenue plus haute) — on perdait la question et ses options.
  La ligne de lecture vit maintenant au **bas réel de la pile** : tout ce que la pile
  recouvre y est représenté, une bande y entre à l'instant où elle glisse dessous.

### Modifié
- **Mode Statique — bouton « Confirmé — démarrer la session »** déplacé dans le tableau,
  **sous « Confirmer le diagnostic » et « Éliminer »** et avant « ⚠ Ne pas oublier »
  (condition d'entrée : on confirme le tableau avant d'agir). Consulter reste inerte ;
  démarrer est l'unique action de la page.

## [4.14.1] — 2026-07-19
### Corrigé
- **Fil d'ancêtres du plan** : quand les branches d'une décision sont affichées **côte à
  côte**, la ligne de lecture traverse plusieurs branches à la fois — la bulle épinglée
  affichait pourtant « › Oui » ou « › Non » arbitrairement, ce qui induisait en erreur.
  Désormais l'option ne s'affiche que si la ligne de lecture ne traverse **qu'une seule**
  branche (pile ou branche pleine largeur) ; sur une rangée de branches parallèles, la
  bulle ne montre que la question.

## [4.14.0] — 2026-07-19
Trois évolutions demandées à l'usage : le fil d'ancêtres du plan retrouve ses niveaux, le
mode Statique devient un document complet choisi dès l'entrée de la fiche, et les branches
profondes s'affichent en colonnes.

### Modifié
- **Plan de l'aide — fil d'ancêtres à plusieurs niveaux (sans superposition)** : en
  défilant dans les branches, une **pile de bulles flottantes** montre chaque décision
  ancêtre, **indentée selon sa position dans l'arbre** comme avant — mais les bulles
  s'empilent désormais selon leurs hauteurs réelles (le chevauchement est impossible), et
  chaque bulle porte son « › Oui / › Non » **dans la même bulle** : deux niveaux avec des
  options homonymes ne peuvent plus se confondre. Un tap sur une bulle va à sa décision.
- **Mode Statique = document complet** : le tableau inclut désormais « Confirmer le
  diagnostic » et « Éliminer — tableau atypique ? » côte à côte, le chapeau « ⚠ Ne pas
  oublier », et « △ À vérifier — surveillances » en pied — comme la maquette validée ; le
  bouton « démarrer la session » reste au-dessus. Le choix se fait dès l'entrée de la
  fiche : **« Dynamique ↔ Statique »** en tête, et en Dynamique la bascule
  **« Journal ↔ Guidé »** reste à sa place dans la prise en charge. Revenir en Dynamique
  restaure le dernier sous-mode utilisé.
- **Branches profondes en colonnes** : dans le tableau statique (dès 640 px), une branche
  contenant plusieurs blocs ou une décision imbriquée reste **côte à côte** avec ses sœurs
  — l'arbre dans l'arbre garde ses fourches gauche/droite au premier niveau (une colonne
  courte à côté d'une longue, esprit SFAR papier) ; une décision imbriquée dans une colonne
  étroite s'empile d'elle-même. Sur téléphone, tout reste en pile pleine largeur.

## [4.13.3] — 2026-07-19
### Corrigé
- **Plan de l'aide (vue journal) — le fil d'ancêtres retrouve la bonne bulle** : la
  simplification 4.13.2 épinglait la question de premier niveau — donc la mauvaise dès
  qu'on lisait une branche imbriquée, et sans le Oui/Non. Désormais **une bulle flottante
  unique** suit le défilement : toujours la question la plus **proche** de ce qu'on lit,
  avec « › Oui / › Non » de la branche où l'on se trouve. Elle se remplace en traversant
  les décisions (jamais d'empilement), disparaît aux convergences, et un tap y va
  directement. Alignée quelle que soit la taille du texte ; absente du mode Échelle et de
  l'impression.

## [4.13.2] — 2026-07-19
### Corrigé
- **Plan de l'aide — fil collant simplifié** : la pile de questions et d'options épinglées
  en haut de l'écran (v4.12) se superposait — les décalages étaient figés à 48 px alors
  qu'une question sur deux lignes est plus haute — et, même correcte, une pile de 3-4
  boîtes gênait la lecture sur téléphone. Désormais **une seule épingle** : la question de
  premier niveau reste visible pendant qu'on défile dans ses branches et se décroche à la
  convergence ; le contexte de branche reste porté par les rails et les étiquettes
  d'option, qui défilent normalement.
- **Textes qui débordaient de leur cadre** : dans les bulles « À vérifier —
  surveillances », les diagnostics différentiels, les options d'une décision, les rappels
  « Ne pas oublier » et les questions, un mot long pouvait sortir du cadre ou pousser la
  case/le chevron hors de la carte (journal ET vue guidée). Les textes peuvent maintenant
  rétrécir et se couper proprement (césure française), comme les étapes en v4.13.1.

## [4.13.1] — 2026-07-19
Audit design complet après retours d'usage sur v4.13.0 : taille du texte, petits écrans,
flèches du mode statique et en-têtes du journal.

### Corrigé
- **Réglage « Taille du texte » (cause racine de deux bugs)** : ce réglage est un zoom CSS,
  et les positions mesurées à l'écran sont en pixels « visuels » (× zoom) alors que les
  styles écrits sont en pixels CSS. Dès que la taille n'était pas à 100 %, le fil d'ancêtres
  collant du plan dérivait (pastilles flottant sous l'en-tête ou glissant dessous) et les
  flèches du mode statique se désalignaient. Toutes les mesures sont désormais ramenées en
  pixels CSS (`zoomF()`), et la base du fil collant est recalée à chaque variation de
  hauteur de l'en-tête (repli au défilement, bandeau de crise, changement de taille).
- **Mode statique sur petit écran** : sous 640 px, les branches ne s'affichent plus côte à
  côte (colonnes de ~145 px illisibles — retour d'usage) : tout s'empile en pleine largeur,
  les pilules « → n » / « ↺ n » portent la structure. La pilule de réponse « :: » peut se
  replier sur plusieurs lignes (elle débordait du cadre en nowrap), comme les titres et
  étapes des cellules.
- **Flèches de convergence** : les brins partent maintenant du bas réel de chaque branche
  (chip comprise pour une branche vide) et traversent l'espace libre jusqu'au coude — plus
  de segments flottants sous une colonne courte. Redessin automatique à tout changement de
  géométrie du tableau (taille du texte, rotation, resize).
- **Journal — en-tête d'instance** : sur petit écran, les boutons « Lecteur » et
  « Vérifier » passent sous le titre (deux rangées) au lieu de l'écraser ; le chip « Vous
  êtes ici » ne recouvre plus la ligne du dessus ; la réponse d'une décision repliée peut
  se replier sur plusieurs lignes.
- **Étapes de la checklist** : un mot long (« compressions ») ne pousse plus la case à
  cocher hors du cadre en étroit / grande taille de texte (césure française automatique).

## [4.13.0] — 2026-07-19
Un **troisième mode de lecture « Statique »** rejoint le Journal et la vue guidée : tout
l'algorithme d'un coup d'œil, en tableau compact façon aide cognitive SFAR/CAMR — généré
automatiquement depuis les blocs de la fiche, consultable sur téléphone, tablette et
ordinateur. Direction visuelle et arbitrages (tableau à joints fins, petites flèches sur les
décisions, aucun texte bleu dans les cellules) validés en séances de maquettes.

### Ajouté
- **Mode Statique** : bascule à trois segments « Journal · Guidé · Statique » en tête de la
  prise en charge (préférence mémorisée et synchronisée, comme avant). Le tableau carrelle
  des cellules télégraphiques — titre en petites capitales, étapes ❑, valeurs « :: » en
  pilule mono **neutre** (le bleu ne marque plus que la position « ● ici » et les reprises
  ↺) ; les décisions sont des bandes ambre pleine largeur (titre + question) dont les
  branches s'affichent côte à côte quand l'écran le permet et s'empilent sinon (mêmes règles
  de profondeur que le plan v4.12).
- **Petites flèches dessinées** : fourche ambre de chaque décision vers ses options,
  convergence grise qui fusionne les branches retombant sur le tronc, retours ↺ en trait
  bleu dans la gouttière gauche (2 voies maximum). Dessinées sur les positions réelles après
  le rendu et au redimensionnement ; quand les branches s'empilent, elles s'effacent et les
  pilules « → n » / « ↺ n » — toujours présentes — reprennent seules le relais : la flèche
  n'est jamais la seule information (accessibilité, impression).
- **Navigation seule, aucune case** : le tableau est inerte côté cochage (la trace vit dans
  le journal) mais montre l'état de session en lecture seule — ✓ du dernier passage, bloc
  courant cerclé de bleu, réponse prise « ✓ » sur son option, hors chemin estompé avec la
  mention en toutes lettres. Taper une cellule = y aller (un bloc jamais visité entre au
  bout du journal, sans défilement ni démarrage de session) ; taper un renvoi = défiler
  vers sa cible dans le tableau. Clavier : Entrée/Espace sur toute cellule.
- Minuteurs, chrono, alarmes et sessions inchangés : mêmes emplacements dans les trois
  modes, mêmes règles d'alarme (rien ne bouge sous les yeux) ; en Statique, le panneau
  « Algorithme » et la minimap disparaissent — le tableau est la vue d'ensemble.

### Détails techniques
- `svTableHtml` (walker de `flowPlan`), `svPaintArrows` (mesures réelles + resize rAF),
  `svBranchIssue`/`svLoopTargets` (pures, testées), `svJump`, `renderSvOnly` ;
  `READ_MODES` accepte `static` ; préfixe CSS `sv-` (collision `st-` évitée) ; aucun
  changement de modèle, de session ni d'export ; 456 tests ; vérifié de bout en bout sur
  les deux fiches réelles (375/810/1280 px, thème sombre, synchro journal ↔ tableau).

## [4.12.0] — 2026-07-18
Le « Plan de l'aide » devient un **organigramme hybride** : la forme de l'arbre se voit
enfin (branches côte à côte quand l'écran le permet), chaque branche est lisible et
repliable, et un mode compact « Échelle » montre tout l'algorithme en une ligne par bloc,
façon ECAM. Décisions figées en séances de maquettes sur fiches réelles (ACR adulte,
anaphylaxie enfant) : le plan reste **inerte** (pas de cases — le cochage vit dans le
parcours) ; la structure `flowPlan` (post-dominateurs, numérotation commune) est inchangée.

### Ajouté
- **Branches côte à côte (organigramme hybride)** : les branches d'une décision s'affichent
  en colonnes quand au moins deux colonnes de 148 px tiennent, et s'empilent sinon — règle
  CSS pure, locale et récursive (une décision imbriquée dans une colonne étroite retombe
  d'elle-même en pile). Une branche **profonde** (plus de 2 blocs ou décision imbriquée)
  s'étale toujours sur toute la largeur ; une branche **volumineuse** (plus de 3 étapes)
  ne s'étale que sur téléphone, où une colonne de 150 px émietterait son texte. Le nombre
  de pistes est plafonné au nombre réel de branches en colonne (sans quoi une branche
  pleine largeur coinçait ses sœurs dans des colonnes étroites même sur grand écran).
- **Rails de branche étiquetés** : chaque branche porte un rail continu de 3 px né sous son
  option et raccordé à un coude de convergence (`→ n` / `↺ n`) — bleu = chemin pris,
  pointillé estompé + mention « hors chemin » = branche écartée (la couleur n'est jamais
  seule).
- **Repli par branche** : le chip d'option est un bouton (≥ 44 px) ; replié, la branche
  devient une ligne-bilan « n blocs · k ✓ · → n ». Les branches hors chemin se replient
  d'elles-mêmes après une réponse ; un tap les rouvre — jamais verrouillées, jamais
  bloquantes.
- **Fil d'ancêtres collant** : en défilant dans une longue branche, la question et l'option
  en cours restent épinglées sous l'en-tête (pile façon éditeur de code, 4 niveaux max) et
  se décrochent d'elles-mêmes à la convergence — on sait toujours « dans quelle branche
  on est », même au fond d'un ACR sur téléphone.
- **Échelle ECAM (mode compact, remplace « Titres seuls »)** : une ligne par bloc — retrait
  de profondeur avec chip d'étiquette (`OUI ›`), n°, titre, renvois abrégés en mono
  (`OUI→5`, `↺1`, `▪fin`) — l'algorithme entier tient sur un écran de téléphone (14 lignes
  pour l'ACR). Taper une ligne la déplie sur place (étapes en lecture seule + « → aller à
  ce bloc ») ; taper un renvoi défile vers la ligne cible et la fait clignoter. Bascule
  « Échelle » ↔ « Détails » ; l'impression sort toujours le plan détaillé.

### Détails techniques
- `ovPlanTreeHtml` (walker imbriqué), `ovPlanLadderHtml` (marche plate), `optAbbr` (pure,
  abréviation des étiquettes de renvoi avec désambiguïsation, testée) ; état de repli dans
  `state.ovFold` (`'b:…'` branches, `'l:…'` lignes de l'échelle), `state.ovPlanTitles` →
  `state.ovPlanCompact` ; `--pl-stick` mesuré sur l'en-tête réel (`ovPlanStick`). Aucun
  changement de modèle, de session ni d'export ; 448 tests.

## [4.11.1] — 2026-07-17
### Corrigé
- **Menu ⋯ déformé** : les entrées du menu s'affichaient comme des cartes à bord gauche marqué
  — la minimap du rail (v4.8.0) avait réutilisé par accident le nom de classe des items du
  menu (`.mm-row`). Les classes de la minimap sont renommées (`.ovm-*`), le menu retrouve son
  apparence.

### Modifié
- **Fiches d'exemple mises à niveau** : les deux exemples (Anaphylaxie, Arrêt cardiaque)
  illustrent désormais les registres ⚠/△ et le format « challenge :: réponse » (« ⚠ Choc
  immédiat :: puis reprise RCP 2 min », « Adrénaline :: 1 mg après le 3ᵉ choc… ») — les
  valeurs restent des placeholders à relire et adapter avant tout usage clinique.

## [4.11.0] — 2026-07-17
Le mode crise devient un vrai support **challenge-response** au sens des checklists
aviation (FAA AC 120-71B, philosophie Do-Verify) : la réponse attendue est séparée du
challenge, une passe de vérification redéroule un bloc, et un mode lecteur plein écran
outille le travail en binôme.

### Ajouté
- **Réponse attendue « challenge :: réponse »** : dans une étape, tapez `::` entre l'action et
  sa valeur (`Adrénaline IM :: 0,01 mg/kg — max 0,5 mg`). En lecture, la réponse devient une
  pilule distincte ; **cocher = confirmer la réponse constatée** (elle passe en readback vert
  « ✓ … »), pas un simple « fait ». Visible aussi dans le plan et le schéma ; une étape sans
  `::` est inchangée, un ancien client affiche le texte tel quel. Rien ne change au format.
- **Mode Vérification (Do-Verify)** : sur tout bloc du parcours, « Vérifier » redéroule les
  challenges **un à un** — « Constaté ✓ » coche l'étape, « △ Écart » passe **sans cocher**
  (jamais de coche inventée, jamais de coche effacée) ; résumé final avec les écarts, qui
  restent visibles dans le parcours. Quitter à tout moment : l'état est celui des cases.
- **Mode lecteur (binôme)** : plein écran, un challenge à la fois en très grand, réponse
  attendue en dessous, zone de validation géante (mains gantées) — le lecteur désigné lit à
  voix haute, l'exécutant répond, le lecteur valide. Fin de bloc et décisions suivent les
  mêmes règles que la checklist (pas d'avance tant que tout n'est pas confirmé, « Revoir »
  ramène au premier écart) ; le chrono de session reste affiché, le flash d'alarme des
  minuteurs reste visible par-dessus ; Échap/✕ quitte sans rien perdre. Entrées : bouton
  « Lecteur » sur le bloc en cours et menu ⋯.
- **Garde-fou télégraphique** dans l'éditeur (non bloquant) : signale un bloc de plus de
  7 étapes ou un challenge de plus de 110 caractères, avec la marche à suivre (« une action
  courte, la valeur en réponse :: »). 8 tests ajoutés (444).

## [4.10.0] — 2026-07-16
La **structure globale** de l'aide devient enfin visible : sous le parcours, le nouveau
**Plan de l'aide** affiche tout l'algorithme en arbre indenté, comme sur un algorithme papier —
retour d'usage sur les fiches à décisions enchaînées (anaphylaxie enfant, ACR), où la liste
plate « Suite de l'algorithme » ne montrait pas qui mène où.

### Ajouté
- **Plan de l'aide** (remplace la « Suite de l'algorithme ») : l'algorithme complet en arbre —
  les branches d'une décision s'indentent sous leur option (« Oui », « Non — digestifs
  isolés »), le tronc reprend au **point de convergence** (calculé automatiquement : sur une
  anaphylaxie, toutes les branches retombent sur « Suivi post-critique », qui s'affiche donc
  au niveau racine), et une boucle est une flèche explicite « ↺ reprendre à n » — la boucle
  des cycles de 2 minutes d'un ACR devient une structure lisible. Chaque bloc n'apparaît
  qu'une fois ; étapes visibles par défaut, bascule « Titres seuls » pour la structure pure.
- Le plan est **immuable et sans cases à cocher** (la trace vit dans le parcours) ; il porte
  un état léger — ✓ bloc fait, ● position, ×n passages, branche écartée « hors chemin »
  estompée — et sert à naviguer : taper un bloc = y aller (un bloc jamais visité entre au
  bout du parcours) ; les liens → / ↺ défilent dans le plan.
- La **numérotation des blocs est désormais commune** au plan, au parcours, aux pastilles
  mobiles et à la minimap du rail : l'ordre de lecture du plan.

### Modifié
- L'impression inclut le plan complet avec ses étapes (structure + contenu sur papier).
- 6 tests ajoutés (436) sur `flowPlan` (convergence, boucles, orphelins, unicité).

## [4.9.0] — 2026-07-16
La vue d'ensemble devient un **journal de parcours** : sur les algorithmes à boucles et à
décisions, l'ancienne présentation (chaque bloc affiché une fois, remis à neuf à chaque passage)
perdait l'utilisateur — retour d'usage immédiat. Le journal suit le modèle ECAM : les étapes
faites restent à l'écran, ce qui vient se poste à la suite.

### Modifié
- **La « Vue d'ensemble » est désormais chronologique** : chaque passage d'un bloc est une carte
  postée à la suite — on lit toujours vers le bas, rien ne se réécrit au-dessus, rien ne
  disparaît. Un bloc terminé se replie en **ligne d'état verte** relisible d'un tap (le repli
  n'arrive jamais sous le doigt : il attend le geste suivant) ; un bloc quitté incomplet reste
  déplié. Une décision repliée garde **sa réponse en toutes lettres** (« → Non — réfractaire »),
  passage par passage — plus de décision amnésique. Reboucler = une nouvelle carte en bas avec
  des cases neuves (tag « passage 2/2 »), l'ancien passage reste intact au-dessus.
- **« Suite de l'algorithme »** : sous le journal, tous les blocs pas encore visités restent
  lisibles en entier (dépliés par défaut — tout l'algorithme d'un coup dès l'ouverture) et
  actifs : cocher une étape ou « Commencer ici → » fait entrer le bloc dans le journal, sans
  que rien ne bouge sous le doigt. La branche écartée par une décision est marquée « hors
  chemin », grisée mais jamais verrouillée.
- Le schéma navigable (v4.7.0) et la minimap (v4.8.0) sont inchangés et suivent le journal ;
  y taper un bloc déjà visité défile vers sa dernière carte, un bloc jamais visité y entre.
- Format de session et export inchangés ; la vue guidée reste identique. 5 tests ajoutés (430).

## [4.8.0] — 2026-07-16
La vue d'ensemble gagne sa **minimap** : où que l'on soit dans la page, la position dans
l'algorithme reste visible et chaque bloc est à un tap.

### Ajouté
- **Bande de pastilles-blocs sur téléphone et tablette** (< 1000 px) : sous le bandeau de crise,
  une ligne collante de pastilles d'état — vert ✓ = bloc fait, bleu = position actuelle,
  cerclé ambre = décision, pointillé estompé = hors chemin — avec la pastille courante
  auto-centrée. Taper une pastille = aller au bloc ; « Dg ✓ » et « ③ Surv. » sautent vers la
  confirmation diagnostique et les surveillances. C'est la table des matières de crise.
- **Minimap dans le rail droit sur ordinateur** (≥ 1000 px) : liste verticale des blocs
  (n°, titre, avancement) sous les minuteurs, synchronisée en direct avec chaque coche et
  chaque navigation — mêmes états, mêmes sauts.

## [4.7.0] — 2026-07-16
L'organigramme devient **navigable** : taper un bloc dans le schéma y emmène directement, et le
schéma se peint selon l'avancement de la session.

### Ajouté
- **Nœuds cliquables dans le schéma de l'algorithme** (panneau « Algorithme » et plein écran) :
  taper un bloc = s'y rendre dans la checklist (bloc déjà visité → on y retourne sans rien
  perdre ; bloc jamais visité → le parcours s'y étend). Jamais de cochage dans le schéma — la
  coche reste un geste de la checklist, sur ses grandes cibles ; naviguer ne démarre pas de
  session. Accessible au clavier (Tab + Entrée/Espace) ; l'aperçu de l'éditeur reste inerte.
- **Le schéma montre l'avancement** : halo bleu = bloc où l'on est, badge ✓ vert = bloc
  entièrement coché, blocs « hors chemin » atténués — mis à jour en direct à chaque coche et
  chaque navigation, en thème clair comme sombre.

### Modifié
- **Performances** : la mise en page du schéma n'est plus jamais reconstruite pendant la crise
  (elle l'était à chaque changement de bloc) — l'état est désormais peint par-dessus une
  géométrie en cache.

## [4.6.0] — 2026-07-16
Réfection du mode crise des aides cognitives : une **vue d'ensemble** montre désormais TOUT
l'algorithme d'un coup — tous les blocs cochables à la suite, démarrage possible n'importe où,
retour en arrière jamais bloquant (doctrine QRH/ECAM).

### Ajouté
- **Vue d'ensemble de la prise en charge** (nouveau défaut des fiches à algorithme) : tous les
  blocs affichés dans l'ordre du parcours (BFS depuis le départ), chacun avec sa ligne d'état
  repliable (n°, titre, compteur x/y, ✓ vert quand complet) et ses étapes cochables. La position
  « Vous êtes ici » suit la dernière action ; cocher dans un bloc jamais visité y déplace le
  parcours (le chemin s'étend, rien n'est présumé). Boutons « Tout replier / Tout déplier » et
  « ↺ Recommencer » (maintenir).
- **Bascule « Vue d'ensemble ↔ Vue guidée »** en tête de l'étape ② : le mode bloc à bloc
  historique reste disponible tel quel ; les deux vues partagent la même session (coches,
  chemin, minuteurs — basculer ne perd rien). Préférence mémorisée par utilisateur et
  synchronisée (elle s'applique à la prochaine ouverture, jamais à l'écran en cours).
- **Décisions jamais bloquantes** : les options restent actives en permanence — changer d'avis
  = un tap ; l'option prise est marquée ✓, la branche écartée est **grisée « hors chemin » mais
  toujours cochable** (un bloc où l'on a agi n'est jamais grisé : les coches sont la trace du
  soin).
- **Boucles maîtrisées** : reboucler par l'algorithme (option de décision, arête « ↺ … —
  nouveau passage ») redonne des cases neuves ; un simple coup d'œil en arrière ne modifie
  JAMAIS les coches ; « ↺ Refaire ce bloc » permet de re-dérouler volontairement un bloc
  (tag « passage n/N », l'ancien passage reste au compte-rendu).
- 19 tests ajoutés (422) sur les nouvelles fonctions pures (`flowOrder`, `latestPass`,
  `offPathSet`, `minimapData`).

### Modifié
- **Exporter en PDF / imprimer** : la fiche s'imprime désormais en vue d'ensemble (tous les
  blocs, dans l'ordre, blocs repliés rouverts le temps de l'impression).
- **Aperçu de l'éditeur** : l'aperçu d'un brouillon utilise un bac à sable de navigation —
  cocher dans un aperçu ne touche plus jamais la session vive d'une autre fiche.

### Corrigé
- **Algorithme tronqué à l'impression** : le schéma SVG était coupé à 300 px de haut dans le
  PDF ; il s'imprime désormais en entier.

## [4.5.4] — 2026-07-16
Les protocoles gagnent des listes cochables `- [ ]` pour les vérifications rapides en lecture.

### Ajouté
- **Listes cochables dans le contenu rédigé des protocoles** : syntaxe GitHub `- [ ] tâche`
  (`- [x]` déjà cochée), aussi en liste numérotée — pour cocher du matériel ou des critères en
  lisant (bouton dédié dans la barre d'outils de l'éditeur, case au registre CONFIRMATION,
  texte jamais barré : on doit pouvoir relire). Les coches sont **éphémères** : elles survivent
  aux re-rendus tant qu'on reste sur le protocole et repartent de l'état écrit à chaque
  ouverture — pas de session, pas de trace (pour une checklist tracée avec minuteurs et
  compte-rendu, créer une aide cognitive et la lier par « Voir aussi »). **Rien ne change dans
  le format** : le corps reste une chaîne, export JSON identique ; une version antérieure de
  l'app (ou tout lecteur Markdown qui ignore la syntaxe) affiche « [ ] tâche » en liste
  normale, GitHub la rend en case native. Les aperçus de l'éditeur dessinent les cases sans les
  rendre cliquables. 14 tests ajoutés (403), vérifié en conditions réelles (cochage
  clic/clavier, lien dans une tâche, re-rendu de synchro, remise à zéro à la ré-ouverture).

### Corrigé
- **Curseur perdu après les boutons de mise en forme** (éditeur de protocole) : poser un titre,
  une liste, une citation ou une liste cochable sur une ligne du milieu du texte modifiait bien
  la ligne, mais la frappe suivante partait tout en bas du document (réécrire le contenu du
  champ remet le curseur à la fin). Le curseur est désormais reposé en fin de ligne modifiée —
  comme le faisaient déjà les boutons gras/encadrés/tableau.

### Décision d'architecture
- **Pas de section « Checklists » à part** : les aides cognitives SONT les checklists de l'app
  (sessions, minuteurs, reprise, compte-rendu). Une troisième section aurait dupliqué ce
  concept pour un coût élevé (stockage, synchronisation, navigation, import/export).

## [4.5.3] — 2026-07-16
L'app dit quand elle travaille : « Chargement… » au démarrage, anneau tournant sur le bouton
Compte pendant la synchronisation.

### Ajouté
- **Indicateur d'activité de la synchronisation** : pendant qu'une synchro tourne, la pastille
  d'état du bouton Compte (en-tête) devient un **anneau tournant** discret — un seul endroit,
  constant, visible dans toutes les vues. C'est un signal d'**activité**, pas une alerte :
  registre INFORMATION (mouvement calme, bleu `--link`), les autres états gardent leur pastille
  statique (vert en phase, rouge erreur, gris hors-ligne). Aucune nouvelle logique : l'anneau
  est piloté par la source d'état existante (`setSyncChip`), en CSS seul ; il ralentit sous
  `prefers-reduced-motion` et disparaît en session de crise (le bouton Compte y est déjà
  masqué — jamais de signal non actionnable pendant un soin, doctrine ECAM). Le bandeau
  système reste réservé à l'information actionnable (« Nouvelle version — Recharger ») : pas de
  bandeau furtif à chaque ouverture.
- **« Chargement… » au démarrage** : pendant la lecture initiale des données (IndexedDB), la
  page affiche une petite roue et « Chargement… » au lieu d'une zone vide — placé dans le HTML
  statique, remplacé par le tout premier rendu, zéro JavaScript ajouté.

## [4.5.2] — 2026-07-16
L'accueil ne se reconstruit plus inutilement juste après l'ouverture : les premiers taps ne
sont plus « avalés ».

### Corrigé
- **App qui semble ne pas répondre à l'ouverture** : la synchronisation se lance à chaque
  ouverture (et à chaque retour au premier plan), et son chargement de profil se terminait par
  une reconstruction **inconditionnelle** de l'accueil — environ une seconde après
  l'affichage, pile quand on commence à s'en servir. Comme le profil (bibliothèques, rôle) est
  déjà restauré depuis le cache au démarrage, cette reconstruction ne changeait rien à l'écran…
  mais remplaçait l'élément sous le doigt entre le toucher et le clic : le tap était perdu,
  d'où l'impression d'une app « bloquée pendant le chargement ». Désormais le re-rendu n'a lieu
  que si le profil a **réellement changé** (bibliothèque ajoutée/retirée, rôle modifié, comptes
  en attente). Les autres re-rendus de synchro étaient déjà conditionnés à un vrai changement ;
  à l'ouverture sans nouveauté distante, plus **aucune** reconstruction ne suit l'affichage
  initial. Vérifié en conditions réelles (profil inchangé = zéro re-rendu).

## [4.5.1] — 2026-07-16
L'animation de bascule Aides ↔ Protocoles ne se rejoue plus quand un re-rendu tombe pendant
qu'elle joue.

### Corrigé
- **Animation d'apparition rejouée plusieurs fois** à la bascule de section : un re-rendu
  survenant pendant les 300 ms de l'animation (typiquement une synchronisation qui se termine —
  jusqu'à trois re-rendus d'affilée : catégories, contenu, documents téléchargés) remplaçait la
  liste en plein vol, ce qui relançait l'animation depuis zéro à chaque fois — et laissait la
  classe d'animation posée (la fin de l'animation de l'élément détruit n'arrivait jamais), donc
  chaque re-rendu suivant la rejouait encore. Désormais tout rendu neutralise la classe de
  bascule : l'animation voulue joue toujours sa fois unique (elle est posée après le rendu de
  `setSection`), et un re-rendu en plein vol pose simplement le contenu, sans rejouer
  l'apparition. Vérifié en conditions réelles : 1 seul départ d'animation, même avec deux
  re-rendus parasites dans la fenêtre.

## [4.5.0] — 2026-07-16
Les documents PDF voyagent enfin avec les exports : nouveau format `.zip` « avec documents »,
au choix à l'export, accepté à l'import — et visionneuse plus robuste face aux PDF endommagés.

### Ajouté
- **Export « avec documents » (.zip)** : quand le contenu exporté référence des PDF joints,
  l'app demande — **« Avec les documents (.zip) »** ou **« Sans les documents (.json) »**
  (✕/Échap = export abandonné). Le `.zip` contient `donnees.json` (strictement le JSON
  historique, format `version: 3` inchangé — un client antérieur peut l'extraire à la main et
  l'importer) et `documents/<id>.pdf` (les binaires, dédoublonnés : un document partagé entre
  plusieurs fiches n'est embarqué qu'une fois). Proposé partout où l'on exporte : fiche seule,
  protocole seul, brouillons des éditeurs et « Exporter mes données » (fenêtre Compte). Un
  document pas encore téléchargé sur l'appareil est exporté en référence seule, avec un
  avertissement chiffré.
- **Import du `.zip`** aux deux points d'entrée existants (sélecteur de fichier du dialogue
  Créer et glisser-déposer), détecté à la **signature** du fichier, jamais à l'extension.
  Règles de restauration : un import **n'écrase jamais** un document déjà présent (même
  identifiant → le document local fait foi — importer ne peut pas modifier les PDF des autres
  fiches) ; un binaire du zip n'est posé que s'il manque, signé `%PDF-` et sous le plafond de
  15 Mo ; il repart ensuite vers le cloud à la synchronisation suivante. Venu d'un autre
  espace, un export `.zip` transporte désormais ses documents (avant : références vidées).
- **ZIP maison, zéro dépendance** : écriture sans compression (les PDF le sont déjà), lecture
  STORE + DEFLATE via l'API native du navigateur (un export dézippé puis re-zippé par
  macOS/Windows reste importable), CRC de chaque entrée vérifié (une archive endommagée est
  rejetée d'un bloc — jamais d'import à moitié), bornes anti-« zip bomb ». 12 tests ajoutés
  (389), vérifié de bout en bout (import, non-écrasement, export des deux formats).

### Corrigé
- **Visionneuse : PDF endommagé après un en-tête valide** — la lecture de la première page est
  désormais sous le même garde-fou que l'ouverture du document : le message « fichier
  endommagé » s'affiche au lieu d'un « Ouverture du document… » sans fin.
- La taille affichée d'un document importé reflète le fichier réellement présent sur
  l'appareil, pas celle déclarée par le fichier d'import.

## [4.4.7] — 2026-07-16
Frecency synchronisée entre appareils, arrivée sur les éditeurs bien en haut de page, et
recherche débarrassée des cartes « Session en cours ».

### Modifié
- **Frecency synchronisée** (connecté) : le classement par usage des résultats de recherche
  (v4.4.6) voyage désormais entre vos appareils, dans le document personnel — comme les
  épingles et les préférences, mais **fusionné** au lieu d'être remplacé : chaque appareil
  compte ses propres ouvertures, et à la synchronisation c'est l'entrée au compte le plus
  grand qui gagne, par fiche (fusion idempotente : jamais de double-compte, assainie à
  l'import — ids sûrs, bornes, plafond 200 entrées). L'envoi est **espacé d'au moins
  10 minutes** : ouvrir une fiche ne coûte jamais une écriture réseau. 10 tests ajoutés (377).
- **En mode recherche, les cartes « Session en cours » s'effacent** : quand on tape une
  requête, on cherche autre chose. La session reste signalée par le tag « ● En cours » sur sa
  carte-résultat et par la barre de minuteurs de l'en-tête ; les cartes reviennent dès que la
  requête se vide.

### Corrigé
- **Arrivée sur un éditeur légèrement « descendue » (iOS)** : le haut de page était bien posé
  au rendu, mais Safari pouvait re-décaler la page juste après (fermeture asynchrone du
  clavier de la recherche, restauration de focus à la fermeture du dialogue Créer). Double
  correctif : le champ actif est défocalisé dès l'ouverture du dialogue Créer, et le haut de
  page est ré-affirmé dans les instants qui suivent l'arrivée — uniquement à l'arrivée (jamais
  pendant l'édition) et seulement pour un petit décalage (< 160 px : on corrige un artefact,
  jamais un défilement volontaire).

## [4.4.6] — 2026-07-16
Ouverture instantanée (cache d'abord), visibilité des documents pas encore téléchargés, et
résultats de recherche classés par usage réel (frecency).

### Modifié
- **Ouverture instantanée — « cache d'abord »** : dès qu'une copie locale existe, l'app
  s'affiche **immédiatement**, quel que soit l'état du réseau (la v4.4.4 avait réduit
  l'attente réseau-d'abord de 3,5 s à 1,5 s ; cette version la supprime). Le réseau est
  toujours consulté **en arrière-plan** : la copie hors-ligne est rafraîchie pour l'ouverture
  suivante, et quand une nouvelle version s'installe, le bandeau persistant « Nouvelle version
  disponible — **Recharger** » propose de l'appliquer tout de suite — invite **non bloquante**
  (✕ pour ignorer, jamais de rechargement forcé, masquée pendant une session de crise) ; sans
  action, la nouvelle version arrive de toute façon à l'ouverture suivante.

### Ajouté
- **Badge « △ à télécharger » sur les documents PDF** : un document ajouté sur un autre
  appareil, dont le fichier n'est pas encore arrivé ici, l'annonce désormais **à froid** dans
  la liste « Documents » (fiches et protocoles) — on ne découvre plus en pleine crise qu'un
  PDF n'est pas consultable hors ligne. L'état est décidé sur la vraie lecture du stockage
  local (un PDF endommagé mais présent garde l'icône générique **sans** badge — message
  juste), et le badge disparaît **sous les yeux** (vignette posée dans la foulée) dès que le
  téléchargement de fond de la synchronisation fait arriver le fichier — téléchargement déjà
  retenté à chaque synchronisation avec du réseau.
- **Frecency dans la recherche** : les résultats sont classés par usage réel — les fiches et
  protocoles qu'on **ouvre le plus, récemment**, remontent en premier (compte d'ouvertures
  amorti par l'ancienneté : pleine valeur ≤ 15 j, demi-valeur ≤ 60 j, quart au-delà). Préférence
  **locale à l'appareil** (même famille que les épingles), plafonnée aux 200 usages les plus
  récents. Les épingles restent toujours premières ; la **liste par défaut reste alphabétique**
  (décision v4.3.2) ; le classement ne dépend pas de la requête, donc **les cartes ne se
  réordonnent pas pendant la frappe** (calme sous stress). 7 tests ajoutés (367).

## [4.4.5] — 2026-07-16
Navigation entre blocs instantanée : la mise à jour ciblée du cochage (v4.2) est étendue au
geste de navigation lui-même.

### Modifié
- **Naviguer dans l'algorithme ne reconstruit plus toute la vue** : « Continuer → », le choix
  d'une option de décision, « Bloc précédent », le fil d'Ariane, « Repartir d'ici » et
  « Recommencer » ne re-rendent plus que le nécessaire — fil d'Ariane, bloc courant, rangée de
  navigation, compteur du panneau algorithme et halo du SVG (`renderNavOnly`). La galerie
  d'images base64, le parcours de soin, les documents et la note ne sont plus reconstruits à
  chaque pas (des dizaines de ms par tap sur mobile — or c'est le geste répété d'un arbre
  décisionnel). La section navigation et ses écouteurs sont extraits de `renderRead` en
  briques partagées (`navSection`/`bindNavEvents`) : rendu complet et rendu ciblé produisent
  le MÊME HTML par construction.
- **Les cas qui changent l'état global restent des rendus complets** (doctrine inchangée) :
  fin d'algorithme (« Terminer l'algorithme ✓ » — les étapes ②/③ du rail changent d'état),
  premier « Continuer » d'une session quand l'étape ① était ouverte (repli différé, v4.4.2),
  démarrage de session par première action (`renderKeepAnchor`). Structure inattendue
  (aperçu, fiche sans bloc) : repli automatique sur le rendu complet.

## [4.4.4] — 2026-07-16
Documents PDF plus lisibles (miniatures, zoom d'ouverture « page entière »), recherche
multi-mots avec extraits contextuels, démarrage plus rapide en réseau dégradé, et une salve
de corrections (onglet Protocoles, bottom sheet des catégories, ombre fantôme, tactile).

### Ajouté
- **Miniatures des documents PDF** : dans les listes « Documents » des vues lecture (fiches ET
  protocoles), chaque rangée montre la **première page en vignette** — on reconnaît un document
  d'un coup d'œil avant de l'ouvrir, d'autant plus utile quand il y en a plusieurs. Génération
  **paresseuse** (pdf.js n'est chargé qu'à la première vignette manquante, différée à
  l'inactivité — jamais au démarrage), une seule à la fois (plafond mémoire canvas d'iOS),
  cache mémoire de session. Document pas encore téléchargé ou repli KV : icône générique.
- **Zoom d'ouverture « page entière »** : la visionneuse s'ouvre au zoom qui montre la première
  page **en entier**, calculé d'après le ratio réel du document (portrait comme paysage) et la
  fenêtre — borné à 100 % (sur téléphone, rien ne change : le calcul y retombe sur la pleine
  largeur). Nouveau bouton **« Page »** à côté de « Largeur » pour retrouver ce cadrage, et
  **plancher de dézoom abaissé de 50 % à 25 %** (survoler un long document).
- **Recherche multi-mots** : chaque mot de la requête doit être présent, où qu'il soit —
  « choc anaph » trouve la fiche dont le titre porte « anaphylactique » et une étape « choc » ;
  l'ancien comportement exigeait les mots contigus.
- **Extraits contextuels dans les résultats** : sous le titre de chaque carte-résultat, la
  première ligne de contenu où la requête matche, termes en **graisse** — on comprend pourquoi
  le résultat est là sans ouvrir la fiche. Relief par la graisse SEULE (doctrine du projet : la
  couleur est un registre — rouge = vital, ambre = vigilance — jamais un simple relief) ; le
  titre est exclu des sources d'extrait (déjà affiché sur la carte). 17 tests ajoutés (360).

### Modifié
- **Démarrage en réseau dégradé** : le service worker basculait sur la copie hors-ligne après
  **3,5 s** de réseau muet (« lie-fi » : Wi-Fi hospitalier qui accepte la connexion mais ne
  répond pas) — jusqu'à 3,5 s d'écran blanc à chaque ouverture. Délai abaissé à **1,5 s** ; la
  fraîcheur n'est pas sacrifiée (le fetch continue en arrière-plan pour l'ouverture suivante).
- **Réactivité de la vue fiche** : le SVG de l'algorithme n'est plus reconstruit (mesure + BFS +
  routage) à chaque re-rendu de session quand le panneau est ouvert — mémo par objet fiche +
  bloc courant, réservé à la lecture (l'éditeur, qui mute son brouillon en place, recalcule
  toujours) ; l'image d'un bloc passe en `loading="lazy" decoding="async"` (plus de re-décodage
  synchrone à chaque navigation).
- **Bottom sheet des catégories** (éditeurs, « Autre… ») : poignée et champ « Filtrer… » sont
  désormais **épinglés en haut** (ils partaient hors écran avec la liste), le défilement est
  **confiné à la feuille** (`overscroll-behavior:contain` — arrivé en butée, le glissement ne
  faisait défiler toute la page derrière) et un glissement sur le voile ne défile plus rien.
- **Tactile** : le « soulèvement » des cartes au survol est neutralisé sur écran tactile
  (`@media (hover:none)`) — sur iOS, le premier tap pose l'état hover, et un hover qui bouge
  l'élément favorise le double-tap. Seule règle `:hover` du fichier qui changeait la géométrie.

### Corrigé
- **Onglet Protocoles qui « retombait » sur les aides** : créer/modifier une catégorie puis
  fermer la fenêtre (ou ouvrir/fermer « Gérer les catégories », fermer la fenêtre Compte,
  modifier/créer/supprimer une bibliothèque) re-rendait toujours la liste des AIDES sous
  l'onglet Protocoles. Tout re-rendu de l'accueil passe désormais par un répartiteur unique
  (`renderLibrary`) qui respecte l'onglet courant.
- **Ombre fantôme en haut à gauche** : le lien d'évitement clavier (« Aller au contenu »), garé
  hors écran, laissait « suinter » son ombre portée sous le bord supérieur (très visible en
  thème sombre). L'ombre ne vit plus que sur l'état focalisé.

## [4.4.3] — 2026-07-15
De la couleur dans les protocoles — mais seulement celle des registres : encadrés typés à la
syntaxe GitHub, surligneur achromatique, et taille d'affichage réglable image par image.

### Ajouté
- **ENCADRÉS TYPÉS dans le contenu rédigé** : une citation peut porter un registre, exactement
  comme une étape de fiche porte « ⚠ » ou « △ ». Quatre registres, aucun nouveau code couleur :
  `> [!CAUTION]` **alerte** (rouge), `> [!WARNING]` **attention** (ambre), `> [!NOTE]`
  **information** (bleu), `> [!TIP]` **confirmation** (vert) ; une citation sans marqueur reste
  neutre. La couleur n'est **jamais seule** : bord gauche 4 px + icône + libellé du registre en
  toutes lettres (WCAG 1.4.1).
  **Syntaxe = celle des « alerts » de GitHub**, entièrement tapable au clavier — donc rendue
  nativement par GitHub, GitLab, pandoc et Typora, et dégradée en simple citation lisible partout
  ailleurs. Les quatre boutons de la barre d'outils produisent la **forme canonique** (marqueur
  seul sur sa ligne, mot-clé en MAJUSCULES : seul dénominateur commun des implémentations tierces).
  En lecture, l'app accepte aussi les alias `[!alerte]` / `[!attention]` / `[!info]` / `[!ok]`,
  les glyphes ⚠ △ ℹ ✓ (copier-coller depuis une fiche), la forme d'une seule ligne, et les cinq
  mots-clés GitHub (`IMPORTANT` est rendu au registre INFORMATION). Sécurité : le registre vient
  d'un **jeu fermé** posé en classe — un mot-clé inconnu redonne une citation neutre, aucune
  valeur utilisateur n'atteint jamais une classe ni un attribut.
- **`==surligné==`** : surligneur **achromatique** (registre MEMO) — faire ressortir un mot sans
  emprunter une couleur qui, dans cette app, veut dire « ça tue si on l'oublie » (rouge) ou « c'est
  là qu'on se trompe » (ambre). Syntaxe répandue (Obsidian, Typora, pandoc) ; ailleurs, elle
  s'affiche telle quelle. Bouton « S » dans la barre d'outils.
- **Taille d'affichage des images, réglable IMAGE PAR IMAGE** : chaque image insérée apparaît dans
  une galerie sous l'éditeur, avec son propre sélecteur (25 / 33 / 50 / 66 / 75 / 100 %) et une
  vignette qui insère une nouvelle référence à la même image (une image peut illustrer deux
  passages). La taille vit dans le **modèle** (`p.images[i].scale`), jamais dans la syntaxe : un
  `=50%` glissé dans `![](img:ID)` casserait la regex des clients antérieurs et **ferait
  disparaître les images** en bibliothèque partagée. Rendu par une classe issue d'un jeu fermé
  (jamais un nombre interpolé dans un style) ; la réduction ne s'applique qu'au-dessus de 560 px
  (sur téléphone, une image à 25 % serait illisible sous stress). Export v3 inchangé : un ancien
  client ignore le champ et affiche l'image à 100 %.

### Modifié
- **Barre d'outils du protocole** : ajout des 4 boutons d'encadré (chacun coloré à son registre)
  et du surligneur. Poser un encadré sur un encadré **remplace** son registre au lieu d'empiler
  les marqueurs — comme un titre posé sur un titre remplace son niveau (v4.4.2).
- Légende de syntaxe complétée (encadrés, surlignage, taille d'image) avec une note de
  **portabilité** : ce qui est rendu ailleurs, ce qui dégrade — et en quoi rien n'est jamais perdu.

### Sécurité / tests
- 27 tests ajoutés (343 au total) : reconnaissance des 4 registres + 5 mots-clés GitHub + alias FR
  + glyphes, marqueur inconnu → citation neutre, registre lu sur la seule 1ʳᵉ ligne, forme
  canonique, absence de classe issue du texte utilisateur, surlignage échappé et neutralisé dans
  du code, jeu fermé des échelles d'image, valeur par défaut posée par `migrate`, et deux images
  aux tailles indépendantes.

## [4.4.2] — 2026-07-14
Tableaux dans les protocoles, sélecteur de type dans le dialogue « Créer », pieds de page
harmonisés, icônes agrandies, et deux correctifs iOS (zoom au focus, colonnes du bandeau).

### Ajouté
- **TABLEAUX dans le contenu rédigé des protocoles** (mini-Markdown) : syntaxe pipe
  `| a | b |` avec ligne de séparation obligatoire `|---|` en 2ᵉ ligne, qui porte l'**alignement**
  (`|:-:|` centré, `|---:|` à droite) ; gras, italique, `code` et liens fonctionnent dans les
  cellules ; pipe littéral en `\|`. Bouton dédié dans la barre d'outils, légende de syntaxe
  complétée (y compris `att:` et `img:`, jusqu'ici non documentés). Rendu dans un **conteneur
  défilant focusable** (`role="region"`, tabindex, `:focus-visible`) : sur iPhone le tableau
  défile au lieu d'écraser ses colonnes ; il se déploie à l'impression. Sécurité : le contenu
  des cellules passe par `mdInline` (donc `esc()` d'abord) et l'alignement vient d'une **table
  blanche fermée** posée en classe — aucune valeur utilisateur n'atteint jamais un attribut.
  Pipes ouvrant ET fermant exigés (plus strict que GFM) : une phrase clinique contenant un « | »
  ne peut pas devenir un tableau par accident. Export v3 inchangé (un ancien client affiche des
  lignes de texte à pipes — dégradation lisible). 14 tests ajoutés.
- **Bouton H1 dans la barre d'outils du protocole** (le niveau existait dans le parseur mais
  n'était pas atteignable) ; poser un titre sur un titre **remplace** son niveau au lieu
  d'empiler les `#`.
- **Sélecteur de type dans le dialogue « Créer »** : « Aide cognitive » / « Protocole » via le
  **même composant segmenté à pastille glissante** que la tab bar basse (`.seg`, généralisé —
  aucun CSS dupliqué, `prefers-reduced-motion` couvert). Choisir un type bascule aussi l'onglet
  de l'accueil : au retour de l'éditeur, on retrouve la bonne liste. Clavier : flèches ← →,
  `aria-selected`, tabindex itinérant.

### Modifié
- **Pieds de page harmonisés** (fiche ET protocole — le protocole n'en avait aucun) : la chaîne
  morte « ● Local — hors ligne OK », qui affirmait « Local » même synchronisé au cloud, est
  remplacée par l'**état réel de stockage**, désormais produit par une source unique
  (`storageState`, pure et testée) partagée avec le pied de la barre latérale : « ☁ Cloud ·
  3 Mo sur l'appareil » ou « Cet appareil seulement · 3 Mo ». Le « maj MM/AAAA » et le code
  court disparaissent du pied (tous deux déjà en tête de page) : il ne reste que l'état et la
  version. En session de crise, l'état de stockage s'efface — comme il s'efface du pied de la
  sidebar (aucun signal non actionnable pendant un soin).
- **Rail « parcours de soin » agrandi sur grand écran** (≥ 1000 px) : pastilles 28 → 34 px,
  chiffres 12,5 → 15 px, ✓ des étapes faites à l'échelle, ligne de liaison et titres recalés
  (géométrie liée, documentée dans le CSS). Lisible à distance sur un poste de déchocage.
- **Hiérarchie des titres du contenu rédigé corrigée** : elle était **inversée** (H3 14 px >
  H1 13 px > H2 12,5 px — un `###` paraissait plus important qu'un `#`). La saillance passe
  désormais par le poids, l'encre et un filet, jamais par la seule taille : H1 = capitales
  encre pleine + filet, H2 = capitales encre douce, H3 = casse normale. Les titres restent
  volontairement plus petits que le corps (15 px) — le texte prime, le titre jalonne.
- **Logotype de l'accueil** 18 → 20 px (sans élargir la barre : la hauteur est fixée par le
  bouton Compte) et **glyphe des icônes de l'app agrandi** : 53 % → 63 % du canevas pour les
  icônes iOS/PWA, 44 % → 49 % pour les icônes maskable Android (zone sûre respectée : le
  bouclier n'est jamais rogné par un masque circulaire). Coins arrondis et opacité préservés.
- **Repli de l'étape ① « Confirmation diagnostique » : doctrine figée** (audit QRH/ECAM). Un
  démarrage **implicite** (cocher une étape, lancer un minuteur…) ne replie **jamais** le bloc —
  `renderKeepAnchor` ne peut compenser le scroll que si la page est assez défilée ; en haut de
  fiche ou sur une page courte, replier ferait sauter le contenu sous le doigt (c'est le bug
  v4.3.2, en pire). Le repli est désormais **différé à la première navigation « Continuer → »**,
  qui l'acquitte et déplace déjà le contexte à la demande de l'utilisateur : l'écran de crise
  s'épure sans qu'aucun contenu ne bouge sous le doigt. `renderKeepAnchor` renvoie le résidu de
  compensation (garde-fou testable).

### Corrigé
- **iPhone — zoom automatique au focus de la barre de recherche** : Safari iOS zoome dès qu'un
  champ fait moins de 16 px. Le correctif v4.3.1 existait mais était **inopérant** — placé trop
  haut dans la feuille, il était écrasé par les règles suivantes (une media query n'ajoute
  aucune spécificité, seul l'ordre source tranche). Bloc unique reposé en fin de feuille et
  **étendu à tous les champs concernés** après audit : recherche, corps du protocole, notes,
  filtre de catégories, journal de session, renommage de catégorie, légende d'image, invitations
  et rôles. Aucun `maximum-scale` au viewport (WCAG 2.2 §1.4.4).
- **Bandeau « Ne pas oublier » en 2 colonnes — décalage vertical** : la grille faisait **partager
  les rangées** aux deux colonnes (hauteur = plus grand item), si bien qu'un rappel sur deux
  lignes creusait un trou en face. Passage en **multi-colonnes CSS** : deux colonnes de flux
  indépendantes, remplissage compact, ordre de lecture (et d'annonce aux lecteurs d'écran)
  inchangé, et un rappel n'est jamais coupé entre deux colonnes.

### Vérifié (aucun changement)
- **Contraste du texte des boutons rouges pleins en thème sombre** : déjà conforme. Le blanc sur
  `--critical-bd` sombre (#ff5a52) donnerait 3,07:1 (échec AA) — mais les deux seuls boutons
  concernés (« Terminer la session », confirmation destructrice) passent déjà à l'encre du fond
  en sombre, soit 6,02:1. Aucun autre bouton à fond rouge plein n'existe dans l'app.

## [4.4.1] — 2026-07-14
Finitions du parcours de soin : fil d'Ariane à hauteur fixe, encadrés de session unifiés,
bouton de démarrage au gabarit « Continuer », mémoire de défilement de l'accueil, éditeur
réordonné, prompt IA durci et fiches d'exemple allégées.

### Modifié
- **Encadrés de session unifiés** : « Minuteurs & compteurs » (rangée repliée et panneau) et
  « Journal des actions » suivent le gabarit commun des blocs de la fiche (surface, bordure
  fine, rayon 8, sans ombre — comme « Confirmation » et « Algorithme ») : un seul langage
  d'encadré dans le parcours de soin.
- **« Confirmé — démarrer la session » au gabarit de « Continuer »** : pleine largeur du bloc,
  50 px, typographie 15/800 — la rangée d'action d'une étape a partout la même forme. Il reste
  bleu `--primary` (démarrer = action primaire ; le vert reste la CONFIRMATION d'un bloc
  entièrement coché) ; l'aide passe dessous, centrée.
- **Éditeur de fiche réordonné dans l'ordre de LECTURE** du parcours de soin : identité →
  Ne pas oublier (avec la mention « 4 rappels maximum ») → Confirmation diagnostique →
  Prise en charge → Minuteurs & compteurs → Contexte local → Repères posologiques →
  À vérifier → Diagnostics différentiels → annexes. On rédige dans l'ordre où l'équipe lira.
- **Prompt IA** : « notForget » est désormais borné à **4 rappels maximum** (limite stricte,
  alignée sur le garde-fou de l'éditeur) avec consigne de reclassement (étape ⚠ du bloc
  concerné, ou « verify ») — l'ancienne consigne commune « ≤ 7 items » laissait passer des
  bandeaux-fleuves.
- **Fiches d'exemple** : le chronomètre « Temps écoulé » est retiré d'Anaphylaxie et d'ACR —
  le chrono global de session (en-tête) le rend redondant. Micro-libellé : « Schéma = vue
  d'ensemble · étapes à cocher en-dessous ↓ » (raccourci).

### Corrigé
- **Fil d'Ariane à HAUTEUR FIXE sur mobile** (règle ECAM : un long parcours ne doit jamais
  allonger la page ni repousser les étapes hors de l'écran) : les jalons ne passent plus à la
  ligne — une seule rangée à défilement horizontal (même geste que la barre de minuteurs de
  l'en-tête), position COURANTE auto-centrée à chaque rendu, historique consultable d'un
  glissement. Testé sur 6 tours de boucle ACR : 32 px de haut, constants.
- **Défilement de l'accueil par section** : basculer Aides ↔ Protocoles n'hérite plus du
  défilement de l'autre liste (la nouvelle section arrive EN HAUT) — mais revenir à une
  section retrouve l'endroit exact où on l'avait laissée (mémoire par section, fenêtre en
  étroit / colonne centrale en large).

## [4.4.0] — 2026-07-14
Parcours de soin numéroté dans la vue fiche : la séquence « ① confirmer le diagnostic →
② dérouler l'algorithme → ③ surveiller » devient la structure visible de l'écran de crise
(option B des maquettes, prérequis QRH / ECAM / WCAG 2.2 AA).

### Ajouté
- **Rail « parcours de soin »** (`<ol class="care-path">`) dans la vue lecture d'une aide
  cognitive : ① **Confirmer le diagnostic** → ② **Prise en charge** → ③ **Surveillances &
  pièges**. Pastilles : bleu = étape active (`aria-current="step"`), vert ✓ = faite, neutre
  cerclé = à venir — jamais d'ambre ni de rouge dans le rail (registres réservés à l'alerte,
  ECAM « un signal = un sens ») ; en thème sombre l'encre des pastilles passe à l'encre du
  fond (contrastes AA vérifiés dans les deux thèmes, ≥ 4.9:1). L'état est aussi porté par le
  texte (« Diagnostic confirmé ») et le glyphe ✓ — jamais la couleur seule (WCAG 1.4.1).
  Étapes vides omises (numérotation recalculée) ; une seule étape non vide → pas de rail.
  La séquence est **suggérée, jamais bloquante** (QRH) : la première action clinique démarre
  toujours la session.
- **Lien « Tableau atypique ? → Diagnostics différentiels »** dans l'étape ① (affiché si la
  fiche a des différentiels) : saut direct à l'étape ③, cible tactile 44 px, défilement
  instantané (pas d'animation de déplacement — `prefers-reduced-motion` de fait respecté).
- **Garde-fou « Ne pas oublier » dans l'éditeur** (non bloquant, registre ATTENTION) : au-delà
  de 4 rappels, une note suggère de reclasser (étape ⚠ du bloc concerné, ou « À vérifier ») —
  les memory items sont rares par construction. Recompté à la frappe.
- **`renderKeepAnchor`** : tout re-rendu de démarrage de session (cocher, minuteur, compteur,
  horodatage) compense le scroll pour que l'élément touché **ne bouge pas d'un pixel** à
  l'écran (le bouton « Confirmé — démarrer » disparaît du flux au démarrage — sans ancrage,
  le contenu remontait sous le doigt ; ECAM : le contexte de travail ne bouge jamais).

### Modifié
- **Étape ① = l'ex-bloc « Confirmation diagnostique »** : son en-tête repliable devient le
  titre d'étape — « Confirmer le diagnostic » avant la session, « Diagnostic confirmé »
  ensuite ; critères ré-ouvrables d'un tap à tout moment (doute en cours d'algorithme), la
  session et les minuteurs continuent. Le bouton de démarrage devient « **Confirmé — démarrer
  la session** » quand la fiche a des critères (le geste porte la confirmation) et REPLIE
  délibérément l'étape ① (acquittement par l'action) ; sans critères, il reste « Démarrer la
  session » en tête de l'étape ②.
- **« À vérifier » et « Diagnostics différentiels » remontent ensemble** dans l'étape ③, juste
  sous la prise en charge (ils étaient dispersés sous la galerie et les documents) ; la carte
  des blocs (SVG) reste repliée en tête de l'étape ② — vue d'ensemble de la phase d'action,
  pas une étape. Galerie, documents, références, voir aussi et note personnelle deviennent
  les annexes de fin de page. En large (≥ 1000 px), minuteurs / posologie / journal restent
  dans la colonne droite collante ; en étroit ils vivent dans l'étape ②.
- **Bandeau « Ne pas oublier » long** : au-delà de 4 rappels, passage en **2 colonnes**
  ≥ 780 px pour contenir la hauteur du chapeau — jamais de repli ni de troncature (un rappel
  caché n'existe plus) ; une colonne en étroit et au zoom 400 % (reflow WCAG 1.4.10). Le
  bandeau reste le chapeau de la fiche, hors numérotation (memory items transversaux),
  visible avant et pendant la session.

## [4.3.2] — 2026-07-14
Micro-animations harmonisées, bouton « Démarrer la session », tri alphabétique par défaut,
et correctifs d'affichage (bandeau de bibliothèque partagée, contraste de la barre latérale,
scroll perdu au premier cochage).

### Ajouté
- **Bouton « ▶ Démarrer la session »** dans la vue lecture d'une aide cognitive, sous la
  confirmation diagnostique (doctrine QRH : on confirme le tableau, puis on agit). Il lance
  chrono, minuteurs et journal par le même chemin que la première action (`ensureStarted`) —
  laquelle continue de démarrer la session implicitement. Seul bouton `--primary` plein de
  l'écran avant session ; il disparaît dès la session démarrée.
- **Micro-animations cohérentes** (registre unique, aligné Apple HIG / Material 3) : voile en
  fondu + légère levée des fenêtres (`veilIn`/`riseIn`), dépliage ancré du menu ⋯ (`menuIn`),
  entrée du bandeau système (réutilise `cbIn`), fondu court des survols (rangées de la barre
  latérale, menu ⋯, documents), levée adoucie des cartes. Règles de sûreté (aviation/QRH) :
  transform/opacity seulement (compositeur — l'app reste utilisable pendant l'animation),
  **aucune animation de sortie** (fermer = immédiat), aucune boucle hors alarmes, pas
  d'animation d'entrée sur les surfaces re-rendues en session (elles rejoueraient à chaque
  action), visionneuse PDF exclue ; tout est neutralisé sous `prefers-reduced-motion`.

### Modifié
- **La date de validation quitte les CARTES** (elle doublait le badge « ✓ Validée ») : sur
  l'accueil, une carte ne porte plus que le badge de statut ; seul un **dépassement** (validation
  de plus de 2 ans) est signalé par une pastille « △ à revoir » au registre ATTENTION (la date
  exacte reste dans son info-bulle). La vue lecture conserve « Validation : 01/2025 » inchangée.
- **Bandeau « Bibliothèque partagée » supprimé** à l'ouverture d'une bibliothèque partagée :
  l'information vit désormais dans le titre de liste — « Nom de la bibliothèque — partagée
  (· lecture seule le cas échéant) — n aides cognitives / documents » — affiché aussi sur
  l'accueil étroit quand une bibliothèque partagée est ouverte. Le titre de la section
  Protocoles porte lui aussi le nom de la bibliothèque ouverte.
- **Tri alphabétique par défaut** des aides cognitives, des protocoles et du sélecteur
  « Voir aussi » (collation française : accents ignorés, numérique naturel — « Bloc 2 » avant
  « Bloc 10 ») ; les épinglés restent en tête. Remplace le tri par récence (`order`, conservé
  dans le modèle pour la compatibilité). Fonction `byTitle` exposée au mode test et couverte
  par tests.html.
- **Pied de page synthétisé** (bas de la barre latérale) : la ligne de stockage devient
  compacte — « ☁ Cloud · 3 Mo sur l'appareil », « Cet appareil seulement · 3 Mo · copie
  unique / non protégé » — le message de sécurité complet reste dans l'info-bulle et la
  fenêtre « Où sont enregistrées vos fiches ? » (inchangées).

### Corrigé
- **Scroll perdu au premier cochage** : cocher la première étape (= démarrage de session)
  re-rendait la vue avec « Confirmation diagnostique » repliée — le contenu remontait et le
  point de tap était perdu. L'état d'ouverture du bloc est désormais figé au démarrage de la
  session (`ensureStarted`) ; le repli par défaut ne vaut plus que pour une session reprise.
- **Contraste de la barre latérale (WCAG 2.2 AA)** : sur une rangée de bibliothèque
  sélectionnée (fond bleu système), le sous-texte « La vôtre · lecture-écriture » /
  « Partagée · rôle » gardait son encre douce (contraste insuffisant) — il hérite désormais
  de l'encre inversée (opacité .92, ≥ 4.5:1 sur tous les accents), comme le compte d'éléments.

## [4.3.1] — 2026-07-13
Correctifs mobile (fiabilité des taps, taille du texte sur iPhone) et harmonisation des
confirmations destructrices sur le registre du dialogue « Terminer la session ».

### Modifié
- **États vides → dialogue Créer** : sur un accueil vide, « Créer un protocole » et le bouton
  de création de fiche ouvrent désormais le dialogue « Créer » (mêmes méthodes — Manuellement,
  Avec l'IA, Importer un fichier .json — que le bouton « ＋ Créer » de l'en-tête), au lieu de
  sauter directement dans l'éditeur.
- **« Créer une fiche » renommé « Créer une aide cognitive »** (bouton d'appel à l'action de
  l'accueil vide), aligné sur le vocabulaire du reste de l'app.
- **Confirmations destructrices au registre « Terminer la session »** : dans la fenêtre de
  confirmation (`confirmDlg`), le bouton principal d'une action destructrice (supprimer une
  fiche, un protocole, la bibliothèque, une session, retirer un membre…) est désormais **rouge
  plein `--critical-bd` + texte blanc**, comme « Terminer » du dialogue de fin de session. Les
  boutons « Supprimer » de fin de formulaire et des zones sensibles restent en contour (le
  rouge plein est réservé à la confirmation finale).

### Corrigé
- **iPhone — taille du texte sans effet sur le texte** : dans « Compte & synchronisation »,
  changer la taille (S/M/L/XL) agrandissait les cadres mais pas la police. Cause : le `zoom`
  CSS posé sur `<html>` n'agrandit pas le texte sur iOS/iPadOS quand
  `-webkit-text-size-adjust:100%` (anti font-boosting) est actif — ce réglage recale chaque
  texte à sa taille spécifiée. Correctif : sur iOS uniquement, `-webkit-text-size-adjust` est
  aligné sur le pourcentage de zoom choisi.
- **iPhone — taps « ignorés » dans « Modifier la bibliothèque »** : le sélecteur de rôle
  (Lecteur/Éditeur/Admin) et les boutons voisins ne répondaient pas toujours. Deux causes
  traitées : (1) champs et menus de cette fenêtre en 12.5–13.5 px — sous 16 px, Safari iOS
  **zoome automatiquement la page au focus** et le tap semble perdu (16 px sur écrans
  tactiles) ; (2) délai du double-tap zoom — `touch-action:manipulation` posé sur tous les
  contrôles (boutons, champs, menus) de l'app. Le bouton « retirer le membre » (×) reçoit un
  halo portant sa cible tactile à 44 px.
- **Fenêtre Compte — boutons jumeaux inégaux sur mobile** : « Exporter mes données » et
  « Se déconnecter » n'avaient pas la même taille en étroit (le libellé le plus long élargissait
  son bouton, et pouvait le rehausser en passant sur deux lignes). Les jumeaux demi-largeur
  (`.dlg-actions`) partagent désormais la largeur à parts égales et s'étirent à la même hauteur.

## [4.3.0] — 2026-07-13
Code couleur des catégories unifié (SPEC crise §1), sélecteur de catégorie « une sélectionnée
+ Autre… » (§2), dialogue « Terminer la session ? » (§3), marqueurs d'étapes sortis du champ
texte, indicateur de mode dans les éditeurs.

### Ajouté
- **Sélecteur de catégorie « une sélectionnée + Autre… »** dans les deux éditeurs : le
  formulaire n'affiche plus que la décision prise (chip teinté qui prévisualise liseré et
  pastille) et la porte de sortie « Autre… » — menu ancré au patron du menu ⋯ (rangées 44 px
  pastille + nom + ✓ sur la courante, champ de filtre au-delà de 8 catégories, « ＋ Nouvelle
  catégorie » en pointillé qui ouvre le gestionnaire sans perdre le brouillon), **bottom
  sheet** avec poignée et voile sous 780 px. Listbox ARIA (flèches, Entrée, Échap). Remplace
  la rangée de toutes les catégories (largeur non bornée, faux air de choix multiple).
  Correction au passage : fermer le gestionnaire de catégories re-rend désormais aussi
  l'éditeur de protocole.
- **Dialogue « Terminer la session ? »** : seule porte de sortie d'une session (menu ⋯, fin
  d'algorithme, ✕ du bandeau SESSIONS EN COURS — jamais d'arrêt direct). Il annonce le
  **contexte** (titre de la fiche + durée) puis les **conséquences avant le choix** (chrono et
  minuteurs stoppés, session retirée de l'accueil, déroulé conservé dans l'historique) ;
  « Poursuivre » = action sûre (contour, focus initial, Échap) ; « Terminer » = rouge système
  plein — l'un des seuls de l'app. Terminer depuis l'écran de crise ramène à l'accueil.
- **Indicateur de mode des éditeurs** : « ÉDITION/CRÉATION — AIDE COGNITIVE/PROTOCOLE » en
  micro-titre permanent dans la barre (11 px/800, encre douce — informe, n'alerte pas),
  tronqué au mode seul en étroit ; le **badge de statut ne disparaît plus jamais** (il
  s'ellipse, plancher 40 px ; thème et compte s'effacent à sa place sous 640 px, « Aperçu »
  passe en icône ⛶ sous 430 px). Pas de barre d'actions flottante en bas (une seule zone
  fixe — en haut ; clavier mobile ; Supprimer reste isolé en fin de formulaire).
- **Bascule ⚠ sur les repères posologiques** : le signe étant intapable au clavier, chaque
  ligne porte le même bouton que les étapes (carte rouge en lecture).

### Modifié
- **Code couleur des catégories (règle unique, partout)** : la couleur choisie par
  l'utilisateur n'apparaît qu'en **pastille** (`.cat-dot` ronde à anneau), **liseré** de carte
  (ramené de 8 à 4 px) ou **teinte ≤ 15 %** avec texte de la couleur — jamais en aplat saturé
  (réservé aux états système), jamais seule (toujours le nom en toutes lettres). La
  **sélection** (rangées de la sidebar, chips mobiles) passe au **bleu système** — plus de
  chips remplis de la couleur de catégorie ni de pilule noire « Toutes » ; la pastille reste
  lisible sur le bleu grâce à son anneau. Le bandeau MODE CRISE ne porte pas la couleur de
  catégorie (rouge système).
- **Marqueur d'étape sorti du champ texte** (éditeur) : le préfixe ⚠/△ ajouté par la bascule
  apparaissait DANS le champ — l'effacer à la main changeait le type par accident. Le champ
  affiche désormais le texte nu, la rangée est **encadrée à la couleur du registre** (bordure,
  fond doux, numéro coloré) et le préfixe est re-posé par le code à chaque frappe (la chaîne
  stockée le garde : exports v3 et anciens clients inchangés).

## [4.2.2] — 2026-07-13
Étapes : doctrine rouge/ambre affichée, gras retiré, chiffres plus lisibles ; références sur
les protocoles ; prompt IA actualisé.

### Corrigé
- **Étape vigilance (ambre) invisible dans l'« Aperçu en direct »** de l'éditeur : la colonne
  d'aperçu ne traitait que les étapes critiques (rouges) — une étape `△` s'y affichait comme
  une étape normale. Elle apparaît désormais au registre ATTENTION (fond et texte ambre),
  comme en lecture.

### Ajouté
- **Consigne d'usage rouge/ambre dans l'éditeur de blocs** (affichée au-dessus des étapes, là
  où se prend la décision) : **rouge** = ce qui tue si on l'oublie (memory item, geste vital) ;
  **ambre** = là où l'on risque de se tromper (dose/dilution à vérifier avant injection,
  contre-indication à écarter, confusion voie/site/produit, seuil à contrôler avant de
  poursuivre) ; une étape des deux registres → rouge. Les infobulles du bouton ⚠/△ reprennent
  la doctrine, ainsi que le prompt IA et AGENTS.md.
- **Références sur les protocoles** : même section « Références » que les aides cognitives —
  liste dans l'éditeur (sous le contenu rédigé), affichée en bas de la lecture, indexée par la
  recherche. Champ facultatif, export v3 inchangé (un ancien client l'ignore).

### Modifié
- **Gras retiré des étapes** (bouton « B » et raccourci Ctrl/Cmd-B) : le texte des étapes est
  déjà affiché en gras — un **fragment** y était invisible ; le relief d'une étape passe par
  son TYPE (rouge/ambre). Le gras reste disponible dans les listes (À vérifier, Ne pas
  oublier, Repères posologiques…) ; l'ancien contenu contenant `**` reste rendu (compat).
- **Chiffres des étapes** (mode crise) : 14 → 16 px et **centrés verticalement** sur l'axe de
  la case à cocher — le numéro est l'ancre de suivi de position de la lecture à voix haute
  (challenge-response, logique QRH) ; il reste en encre douce pour ne pas concurrencer le
  texte, et suit les registres rouge/ambre/coché.
- **Prompt IA actualisé** : le gras y est désormais exclu des étapes (réservé aux listes) ;
  la doctrine rouge/ambre ci-dessus remplace l'ancienne définition du `△` ; nouvelle règle —
  **ne jamais générer de chronomètre « Temps écoulé »** (l'app affiche déjà un chrono global
  de session qui démarre à la première action), un `stopwatch` ne servant qu'à une durée
  spécifique explicitement demandée par la source (garrot, no-flow…) ; l'exemple du schéma
  est corrigé en conséquence. Déjà à jour et vérifiés : `code`, types d'étapes ⚠/△, repères
  posologiques.

## [4.2.1] — 2026-07-13
### Corrigé
- **App tronquée à droite sur certains navigateurs** : sur les navigateurs à barres de
  défilement classiques (Windows/Linux — pas macOS/iOS, d'où le « certains »),
  `scrollbar-gutter: stable` posé sur `html` réservait ~15 px à droite **en permanence**, même
  quand rien ne défile (accueil = coque fixe, fiche courte) : l'en-tête, le bandeau MODE CRISE
  et tout le contenu s'arrêtaient avant le bord de la fenêtre — alors que les éléments fixes
  (tab bar, notifications) allaient, eux, jusqu'au bord. La réservation est retirée de `html` ;
  l'anti-décalage qu'elle assurait (bascule Aides ↔ Protocoles) est déplacé **dans les panneaux
  défilants de l'accueil large** (`.home-side`/`.home-main`), seul endroit où il agit encore
  depuis la coque fixe V5. Vérifié : l'app atteint désormais exactement le bord droit à toutes
  les largeurs, sans débordement horizontal.

## [4.2.0] — 2026-07-13
Liens croisés « Voir aussi », alarmes de minuteur au standard aviation (QRH/ECAM), thème
accessible en mode crise.

### Ajouté
- **Liens croisés « Voir aussi »** : une aide cognitive OU un protocole peut désormais être lié
  aux deux (et plus seulement des fiches). Le choix se fait dans un **sélecteur filtrable au
  même design que « Joindre un document existant »** (icône par nature — feuille = aide,
  livre = protocole —, nature en 2ᵉ ligne, code en colonne droite), commun aux deux éditeurs ;
  il remplace l'ancien menu déroulant. En lecture, la section s'appelle « Voir aussi » partout
  (fiches ET protocoles), chaque raccourci porte l'icône de sa nature et ouvre la bonne vue.
  Compatibilité : `related` reste un tableau d'ids (export v3 inchangé) — un ancien client
  ignore simplement les ids de protocole qu'il ne résout pas. Même périmètre uniquement
  (Perso ou même bibliothèque), comme les documents partagés.

### Modifié
- **Alarme de minuteur en mode crise — règle QRH/ECAM** : un minuteur qui arrive à échéance ne
  **déplace plus jamais le contexte de travail** quand la session est sous les yeux — plus
  d'ouverture automatique du panneau minuteurs (qui décalait la checklist en cours de lecture),
  plus de banderole jaune par-dessus l'écran de travail. À la place : bip/vibration + flash
  bref (l'attention, façon *master caution*), puis un **segment ambre persistant** dans la
  barre de minuteurs de l'en-tête — le minuteur échu y reste affiché « 00:00 » tant qu'il n'est
  ni relancé ni réarmé (l'acquittement passe par l'action, pas par un « OK » de plus). La
  banderole cliquable, le flash écran et la notification système sont **réservés à la session
  hors de vue** (autre vue, autre fiche, app en arrière-plan) : là, l'alerte doit être routée.
- **Bouton thème en mode crise (mobile)** : il reste visible pendant une session (retour sur la
  v4.1.2 — décision : la luminosité ambiante change pendant une intervention, extérieur/
  intérieur) ; seule la pastille de compte s'efface. Les intitulés de minuteurs s'ellipsent un
  peu plus tôt (< 430 px) pour que barre + thème + menu ⋯ tiennent ensemble sur 375 px.

## [4.1.2] — 2026-07-13
Correctifs d'affichage et retouches de design, surtout sur mobile.

### Corrigé
- **Fenêtre « Modifier la bibliothèque »** : Annuler / Enregistrer remontent **sous le champ
  Nom** (ils ne portent que sur lui) au lieu de suivre la liste des membres — placés en bas,
  ils laissaient croire qu'un ajout ou un retrait de membre devait être « enregistré », alors
  que ces changements s'appliquent immédiatement (précisé aussi dans la légende des rôles).
  Les messages du renommage s'affichent désormais sous le champ Nom, ceux des membres restent
  sous la rangée d'invitation.
- **Minuteurs de l'en-tête sur mobile** : un intitulé de minuteur long poussait le temps hors
  du cadre (coupé net) sur les écrans < 430 px — l'intitulé s'ellipse à nouveau (« ● Session »
  reste toujours entier) et les segments se resserrent. En complément, pendant une session de
  crise sur écran étroit, les boutons **thème** et **compte** s'effacent de la barre (inutiles
  en pleine prise en charge, accessibles partout ailleurs) : toute la place revient aux
  minuteurs. Le menu ⋯ reste.
- **Badge d'état fantôme dans l'en-tête** : après « Enregistrer » dans l'éditeur, le badge
  « ✓ Validée · auto-enregistré » survivait au retour en lecture de la fiche — redondant avec
  la pastille de statut du haut de page et envahissant sur mobile. L'en-tête masque désormais
  son badge à chaque rendu ; seules les vues qui en déclarent un (éditeurs, lecture de
  protocole, aperçus) le réaffichent.

### Modifié
- **Tab bar basse de l'accueil (mobile)** : hauteur réduite (~72 → ~55 px hors encoche) —
  boutons 44 px (cible tactile minimale conservée), paddings resserrés.
- **« Supprimer mon compte et mes données »** (et « Supprimer cette demande de compte ») :
  même grammaire destructrice que « Supprimer la bibliothèque… » — zone sensible avec bouton
  **contour rouge**, à la place de l'ancien lien discret (`.auth-danger` retiré).
- **Bouton thème de l'en-tête** : rond (40 px) en format compact sans libellé, comme le bouton
  Créer — il était ovale ; la forme pilule revient avec le libellé (≥ 780 px).
- **Dialogue « Créer » (aide ET protocole)** : icônes des cartes remplacées par des **icônes
  SVG uniformes 26 px** (crayon, étincelles, import, reprise de brouillon) — les anciens
  glyphes texte ✎ ✦ ⤓ ↺ rendaient à des tailles inégales selon la police du système.
- **Fenêtre « Où sont mes fiches ? »** mise à jour des évolutions V5 : le conseil d'export
  pointe vers « Compte → Exporter mes données » (l'ancien bouton « Exporter tout » du pied de
  page n'existe plus) et mentionne le chemin d'import (dialogue Créer). Mêmes corrections dans
  la fenêtre de bienvenue et deux messages d'erreur qui citaient encore « Exporter tout ».
- Lanceur de tests : variable `AC_CHROMIUM` pour pointer un Chromium déjà installé
  (environnements distants/CI sans téléchargement Playwright).

## [4.1.1] — 2026-07-12
Correctifs et nettoyage issus d'un audit complet (code mort, duplication, sécurité, PWA/perf).
Aucun changement de comportement visible : mêmes écrans, mêmes données.

### Corrigé
- **Droits perdus en cours d'utilisation** (rétrogradé lecteur ou retiré d'une bibliothèque
  pendant que l'app est ouverte) : une modification locale non poussée d'une bibliothèque où
  l'on ne peut plus écrire divergeait en silence pour toujours (jamais poussée, jamais
  réconciliée, pastille verte). Désormais : la modification est **copiée dans « Perso »**
  (rien ne se perd), la copie partagée **revient à la version de l'équipe** (ou disparaît si
  l'on n'est plus membre), et l'utilisateur est **prévenu**. Une suppression bloquée est
  annulée (version de l'équipe restaurée). En complément, l'ouverture de l'éditeur d'une
  fiche/protocole **partagé** revérifie le rôle auprès du serveur quand on est en ligne.
  Rappel : il n'y a pas de synchro périodique — droits et contenus se rafraîchissent au
  démarrage, après chaque écriture locale, au retour au premier plan et au retour en ligne.
- **Fuite d'écouteurs de l'aperçu d'édition** : un écouteur `input` s'empilait sur `#main` à
  chaque ouverture d'éditeur — un seul est désormais posé (les frappes ne déclenchaient plus,
  après plusieurs éditions, qu'un seul aperçu au lieu de N).
- **Service worker** : le handler de navigation ne met plus en cache que la page de l'app —
  visiter `tests.html` ou une fiche de `design/` ne peut plus remplacer la copie hors-ligne.
- **Défense en profondeur du mini-Markdown** : liens et images nettoyés au point d'insertion
  (`href`, `safeImg`) — la sûreté ne dépend plus d'un invariant d'ordre.

### Ajouté
- **Réservation d'espace des images** (anti-décalage de mise en page) : chaque image mémorise ses
  dimensions ; `width`/`height` émis en lecture réservent le bon ratio avant décodage, sans
  jamais déformer un schéma. Import ancien sans dimensions : inchangé.
- **Manifest** : `orientation` portrait, `categories`, `dir` — fiche d'installation plus complète.

### Modifié
- **Recherche transverse à toutes les bibliothèques** : dès qu'on tape une recherche, elle porte
  sur la bibliothèque perso ET toutes les bibliothèques partagées accessibles (plus seulement
  celle affichée) ; chaque résultat porte une pastille indiquant sa bibliothèque (si l'on a des
  bibliothèques partagées). Les brouillons restent masqués là où l'on n'a pas le droit d'éditer.
  Sans recherche, la navigation par bibliothèque/catégorie est inchangée.
- **Correctifs mobile** : la loupe de la recherche ne chevauche plus le placeholder ; le crayon ✎
  d'édition de bibliothèque ne déborde plus de la chip et réagit au tap.
- **Facteur commun fiche/protocole** : sanitisation des entités (`sanitizeEntityCommon`), en-tête
  et sortie des éditeurs mutualisés — une évolution ne peut plus diverger d'un seul côté.
- `render()` allégé (chrome d'en-tête extrait dans `applyViewChrome`) ; `renderLibrary` renommée
  `renderFiches` (elle rend les fiches, pas les bibliothèques).

### Supprimé
- Code mort : `timeAgo()`, variable `_rtShow`, 17 règles CSS orphelines (vestiges des
  remplacements V5). Chaîne de build `dist/` retirée (dossier, `build-dist.mjs`, `terser`) : le
  dépôt est la seule forme servie.

### Sécurité
- **CSP durcie** : `release.sh` calcule les hashs SHA-256 des scripts inline
  (`scripts/csp-hashes.mjs`) et les injecte dans la CSP (`<meta>` + `_headers`). Sur navigateur
  récent (CSP 2+), `'unsafe-inline'` est ignoré et seuls ces scripts s'exécutent : un `<script>`
  ou un handler `on*=` injecté est bloqué (repli `'unsafe-inline'` conservé pour les très vieux
  navigateurs). `style-src 'unsafe-inline'` demeure (attributs `style=` non hachables). Risque
  résiduel restant documenté (`docs/deploiement-et-conformite.md` § 1.1 : jetons Supabase en
  `localStorage`, discipline `esc()`).

### Documentation
- `CHANGELOG.md` allégé : les versions 3.x déplacées dans `CHANGELOG-archive.md` (rien de
  fusionné ni perdu — le journal courant ne garde que le 4.x). Références mortes purgées
  (`dist/`, `renderLibrary`) dans AGENTS.md, README, kit de déploiement et `design/`.

## [4.1.0] — 2026-07-12
Version consolidée : intégration complète du design Claude Design « V5 Explorations » et des
spécifications écrites qui l'ont suivi (largeurs, écrans de gestion, mode crise, dialogue
bibliothèque), plus l'audit UX/ECAM/WCAG appliqué. Remplace les versions locales 4.0.4 → 4.4.1,
jamais publiées, écrasées en une seule entrée.

### Ajouté
- **Écrans de gestion** : dialogue « Créer » (3 méthodes — rédiger, avec l'IA, importer un
  fichier ; tout import par ce dialogue arrive en Brouillon ; carte « Reprendre le brouillon ») ;
  **menu ⋯** en lecture (Modifier, Versions, Dupliquer, Exports, Historique des sessions en
  modale, « Terminer la session… » — remplace les barres d'autorat et le bandeau session) ;
  **auto-enregistrement des brouillons** (store meta `draftpark`, fantôme restaurable,
  « ‹ Retour » remplace « Annuler ») ; dialogue bibliothèque unifié (membres + zone sensible).
- **Mode crise V5** : bandeau TITRE au registre ALERTE (« ■ MODE CRISE »), minuteurs segmentés
  dans la barre à toutes les largeurs + chrono GLOBAL « ● Session », rail droit ≥ 1000 px,
  cartes minuteur refondues (état TEXTUEL, barre 4 px du temps restant, échu = ambre,
  « ↺ durée »), **minuteurs ad hoc** (`extraTimers`), compteur lié (`counters[].timerId`),
  bouton Continuer à 2 états (destination annoncée, champ `nextLbl`), confirmation diagnostique
  = condition d'entrée visible hors session, colonne de contenu au canvas (SPEC-crise).
- **Statuts 3 états** (validé / à relire / brouillon, pilule achromatique unique), champ `code`
  court indexé, étapes critiques « ⚠ » et vigilance « △ », section « Repères posologiques »,
  aperçu d'édition en direct (colonne ≥ 1000 px).
- **Couleur d'accent par utilisateur** (5 nuances AA + bleu clinique, connecté seulement :
  accueil entier + en-têtes ; le contenu clinique reste bleu) ; préférences par utilisateur
  (thème + taille du texte + accent) synchronisées via `data.prefs`.
- Fenêtre Compte restructurée (gabarit dlg-480, « synchronisé à HH:MM », zones Cet appareil /
  Administration / Zone sensible, avatar en initiales de l'e-mail).

### Modifié
- **Palette V5 « bleu clinique »** et tokens (trois rouges distincts, `--ok` confirmation,
  `--soft` décoratif seulement, `--done-*`/`--tag-*`/`--link`/`--verify-bd`) ; taxonomie des
  notices à 5 registres ; nouveau logo (bouclier + tracé ECG) ; icônes SVG harmonisées.
- **Largeurs fermées par vue** (breakpoints 430→1200) : accueil = sidebar 255 px sur coque FIXE
  + grille ≤ 1320 px ; fiche ≤ 860 px + rail 320→360 px ; protocole ≤ 780 px ; éditeurs alignés
  sur leur lecture + aperçu sticky 360 px. Pied de page nomade en bas de la sidebar de
  l'accueil ; export via la fenêtre Compte, import via le dialogue Créer.
- **Audit ECAM/WCAG appliqué** : contrastes (texte secondaire `--ink-soft`, champs/cases
  `--line-strong`), plancher typographique 11 px, garde 700 ms anti double-tap sur les retours
  empilés, halos tactiles 44 px, cartes d'accueil sobres (pilule de catégorie neutre, couleur
  au liseré seul), impression qui déplie les sections repliées.
- Docs consolidées : la spécification des largeurs vit dans AGENTS.md (le fichier
  `docs/SPEC-largeurs.md` est supprimé) ; export Design System (`design/`) régénéré.

### Supprimé
- **Chaîne de build `dist/`** (dossier, `scripts/build-dist.mjs`, dépendance `terser`, étape 6
  de `release.sh`) : le dépôt est la seule forme servie — l'entre-deux « build optionnel
  jamais déployé » était le pire des deux mondes.


## [4.0.3] — 2026-07-11
Lot de cohérence issu de l'audit design v4 (registres visuels, saillance, accessibilité).

### Modifié
- **Les protocoles parlent la même langue visuelle que les fiches.** Les titres de section du
  contenu rédigé (`#`, `##`) reprennent le registre des en-têtes de section des fiches (petites
  capitales grasses espacées) au lieu d'un simple gras : une seule grammaire de titres dans
  toute l'app, en lecture comme dans l'aperçu de l'éditeur.
- **Le titre n'apparaît dans la barre d'en-tête qu'au défilement** (fiches et protocoles,
  lecture et édition). En haut de page, le corps affiche déjà le titre : la barre garde la
  marque, puis bascule sur « titre + nature du contenu » une fois le titre du corps sorti de
  l'écran — le motif « grand titre » d'iOS, déjà utilisé par l'accueil, appliqué entièrement.
  Hauteur de barre inchangée entre les deux états ; plus jamais deux titres affichés à la fois.
- **Un seul bouton rempli par écran.** Quand l'accueil affiche « Reprendre » (session en cours,
  teal plein), « Créer » — action d'autorat, rare en situation d'urgence — passe en ton doux ;
  il reste plein quand aucune session n'est affichée. Règle notée dans AGENTS.md.
- **« Validation : MM/AAAA »** remplace « Validée MM/AAAA » : le même libellé sert aux fiches
  (féminin) et aux protocoles (masculin), l'accord unique était fautif pour l'un des deux.
- **Doc — sémantique du vermillon régularisée** (`:root` + AGENTS.md) : `--critical` couvre la
  destruction **et l'arrêt d'un processus vivant** (« Terminer » une session stoppe les
  minuteurs — registre du rouge « raccrocher ») ; le bouton, volontairement vermillon, n'est
  plus une exception à la règle.

### Corrigé
- **Cartes de liste accessibles au lecteur d'écran.** La carte entière était un « bouton »
  contenant d'autres boutons (épingle, badge « À compléter ») — structure proscrite (ARIA).
  Le titre est désormais le vrai bouton, sa zone de tap étendue à toute la carte ; épingle et
  badge restent des commandes indépendantes, au clavier comme au doigt. Aucun changement visuel.
- **Pastilles de catégories : zone de tap portée à ~44 px** (halo invisible autour de chaque
  pastille, filtres de l'accueil et choix de catégorie des éditeurs) — taille visuelle inchangée.

## [4.0.2] — 2026-07-11
### Corrigé
- **Synchronisation : certains contenus n'arrivaient jamais sur un appareil déjà synchronisé**
  (constaté sur des protocoles, mais valable pour les fiches). Le rattrapage incrémental ne
  demandait au serveur que les lignes **plus récentes que la dernière synchro** ; or deux cas
  réels produisent des lignes « dans le passé » : du contenu créé **avant votre adhésion** à une
  bibliothèque partagée (l'accès le révèle d'un coup, avec ses dates d'origine), et un appareil
  à l'**horloge en retard** (l'horodatage vient de l'appareil qui enregistre). Ces contenus
  n'apparaissaient qu'en repartant de zéro (nouveau navigateur) — même la synchro manuelle ne
  les ramenait pas. Chaque synchro effectue désormais un **repêchage de complétude** : un
  inventaire léger (identifiants + dates) de tout ce qui est visible, puis récupération ciblée
  des seules lignes manquées, appliquées avec les mêmes règles qu'avant (la version la plus
  récente gagne, une saisie locale plus fraîche n'est jamais écrasée).

### Modifié
- **Barre d'en-tête harmonisée entre fiches et protocoles en lecture.** Un protocole ouvert
  affichait « Protocole » sous son titre, mais une fiche ouverte n'affichait rien sous le sien.
  La lecture d'une fiche porte désormais le libellé « Aide cognitive » au même endroit — les
  deux barres ont la même structure (titre + nature du contenu). Le bandeau teal reste dédié à
  l'état (mode crise, session en cours) et ne change pas.

## [4.0.1] — 2026-07-11
### Corrigé
- **Titre dans la barre d'en-tête : comportement unifié entre fiches et protocoles, lecture et
  édition.** En lecture de protocole, le titre s'affichait en petite troisième ligne sous
  « Aides cognitives / Protocole » et se retrouvait **coupé par le bas de la barre** (rangée
  d'identité plafonnée à 44 px) ; en édition (fiche comme protocole), aucun titre n'apparaissait.
  Désormais, dans toute vue fiche/protocole, le titre **remplace la marque** sur une seule ligne
  ellipsée à l'échelle du titre d'accueil (17 px), avec le libellé « Protocole » ou « Édition »
  dessous — même géométrie qu'avant, la hauteur de barre ne change pas. En édition, le titre de
  la barre **suit la saisie en direct** dans le champ « Titre » ; champ vidé, la marque revient
  (création d'une nouvelle fiche). Le mode crise est inchangé (même motif, désormais partagé).

## [4.0.0] — 2026-07-09
### Ajouté
- **Documents PDF joints aux fiches.** Chaque fiche peut porter jusqu'à 10 PDF (15 Mo max
  chacun : protocoles de service, recommandations…), ajoutés depuis l'éditeur (le contenu du
  fichier est vérifié, pas seulement son extension) et lisibles hors ligne. Un document peut
  être **partagé entre plusieurs fiches/protocoles du même périmètre** (« Joindre un document
  existant ») : le remplacer le met à jour partout, il n'est supprimé que quand plus rien ne le
  référence. Les PDF sont stockés en Blob natif dans IndexedDB (jamais en base64 dans la fiche)
  et n'alourdissent pas l'export JSON (seules leurs métadonnées y figurent). Le binaire est
  stocké en ArrayBuffer (fiable sur tous les navigateurs, y compris Safari/iOS où le stockage
  de Blob dans IndexedDB a des bugs connus) ; en cas de problème, la visionneuse distingue
  clairement « composant non téléchargé » (hors-ligne avant première utilisation) de
  « fichier endommagé ».
- **Visionneuse PDF intégrée, toutes pages, tous appareils.** Lecture dans l'app (iPhone, iPad,
  Android, ordinateur) : défilement de toutes les pages, zoom −/+/Largeur, plein écran, Échap
  pour fermer. Rendu par pdf.js **vendorisé** (`vendor/pdfjs`, version figée 4.10.38, précaché
  par le service worker → fonctionne hors ligne dès l'installation, chargé paresseusement →
  aucun coût au démarrage) : **exception unique et documentée à la règle zéro-dépendance**
  (AGENTS.md). Rendu virtualisé (les pages éloignées de l'écran sont libérées : un long PDF ne
  sature pas la mémoire d'un iPhone).
- **Synchronisation cloud des documents.** Bucket privé Supabase Storage avec politiques RLS
  strictes : le chemin encode le périmètre (`u/<compte>/…` personnel — propriétaire approuvé
  seul ; `l/<bibliothèque>/…` partagé — lecture pour tout membre, écriture éditeur/admin),
  plafonds de taille et de type appliqués par le serveur, aucun accès sans session. Les
  documents manquants sont **téléchargés systématiquement** en arrière-plan à la synchro
  (disponibles hors ligne en urgence), déplacements entre bibliothèques et suppressions
  propagés, orphelins listés pour l'app-admin (`list_orphan_attachments`, purge manuelle).
  Nouveaux tests RLS (section 9) : lecture croisée refusée, usurpation de chemin refusée,
  rôles respectés, anonyme sans accès.
- **Nouvelle section « Protocoles ».** Le **titre de la page d'accueil devient le sélecteur**
  dans la barre fixe : « Aides cognitives | Protocoles » en titres à onglets — une ligne de
  base court sous les deux titres et un indicateur ajusté au titre actif glisse de l'un à
  l'autre avec un léger ressort — transition de contenu fluide et jamais bloquante, bascule à
  tout moment, mémorisée par compte. Sépare les aides cognitives de crise des protocoles de
  référence.
  Un protocole = titre, catégorie (jeu partagé avec les fiches), bibliothèque (perso ou
  partagée), date de validation, état brouillon/validé, **un ou plusieurs PDF** et/ou un
  **contenu rédigé dans l'app**. Recherche plein texte, export/import JSON (champ
  rétrocompatible), synchronisation cloud complète (table `protocols`, mêmes politiques RLS
  que les fiches — tests section 10).
- **Contenu rédigé en mise en forme simple (mini-Markdown maison, sans dépendance).** Titres
  (`#`/`##`/`###`), listes à puces et numérotées avec **sous-listes** (2 espaces d'indentation),
  **citations** (`>`), **code** en ligne et en bloc (```` ``` ````), séparateur (`---`),
  **gras**, *italique*, liens web, liens vers un PDF joint, images intégrées (réduites et
  stockées hors ligne). Éditeur avec barre d'outils (B, I, H2, H3, listes, citation, code,
  lien, image) et aperçu en direct. Rendu sûr par construction (échappement d'abord,
  `javascript:` et identifiants hostiles refusés, aucun balisage interprété dans le code —
  testés) ; balisage non reconnu laissé visible, le rendu ne casse jamais.
- **Recherche transversale.** La recherche de l'accueil évalue aussi la requête sur l'autre
  section : un bloc discret « N protocoles correspondent aussi à cette recherche » (et
  inversement) bascule de section en conservant la recherche — en urgence, pas besoin de se
  souvenir d'où vit un contenu.

### Modifié
- **En-tête clair (inversion) + identité d'accueil.** La barre fixe prend la couleur du fond de
  page (hairline de séparation), le teal se retire dans les **accents**. L'accueil retrouve la
  **ligne d'identité** « Aides cognitives » + compte, avec en dessous la rangée d'onglets
  « **Aides | Protocoles** » (la section est renommée pour lever le doublon avec le nom de
  l'app). Le **mode crise** ne recolore plus la barre : il s'annonce par un **bandeau d'état
  étiqueté** sous la barre (« Mode crise · session en cours… », pattern des systèmes
  critiques — texte + couleur + position), le titre de la fiche gardant l'emplacement et le
  corps du titre d'accueil ; le **rappel minuteurs y est fusionné** (chrono compact cliquable à
  droite du bandeau — un seul bloc d'état, apparition en fondu discret jamais bloquant). Sur
  l'accueil, la **ligne d'identité se replie au défilement** (pattern grand titre : espaces
  confortables en haut de page, barre minimale en navigation). Propagé partout : bouton Compte
  et pastille d'état, thème sombre, couleur de la barre d'état système.
- **Base locale IndexedDB v4 → v5** (stores `attachments` et `protocols`). Migration
  automatique et silencieuse ; si un vieil onglet de l'app bloque la mise à jour du stockage,
  un message invite à le fermer (au lieu d'un repli silencieux vers une bibliothèque vide).
- La jauge de stockage indique le poids des documents PDF ; le tableau de bord app-admin
  affiche protocoles et poids du bucket ; le message d'erreur « contenu trop volumineux »
  couvre les documents.
- Chrome de l'accueil (sélecteur de section, barre de bibliothèques, catégories, recherche)
  et composants Documents **factorisés** entre fiches et protocoles (aucune logique dupliquée).
- **Correctifs de l'audit design 4.0.0** (conformité WCAG 2.2 AA + cohérence des palettes) :
  - **Pastilles d'état du compte et de la synchro** : couleurs sémantiques qui suivent le thème
    (ok = teal, attente = ambre, erreur = vermillon, inactif = gris) — les anciennes valeurs
    vives, calibrées pour l'en-tête sombre d'avant l'inversion, tombaient à 1,3–2,4:1 sur la
    barre claire (3:1 requis) ; désormais ≥ 3:1 dans les deux thèmes.
  - **Manifest et barre système alignés sur le chrome clair** : `theme_color`/`background_color`
    du manifest et balise `theme-color` initiale = fond de page (plus de barre teal au-dessus
    d'une app claire à l'installation) ; la couleur suit le thème sombre dès avant le premier
    rendu. Le **verrou portrait est retiré** (usage tablette en paysage possible).
  - **Plancher typographique 11 px** (étiquettes du bandeau de crise, indice « maintenir »,
    numéros du fil d'Ariane, badges) et **zones de tap** : chrono du bandeau de crise ≥ 44 px,
    jauge de stockage ≥ 24 px (WCAG 2.5.8).
  - **Palettes dé-dupliquées** : les overrides du thème sombre qui recopiaient des valeurs de
    tokens en hex sont supprimés (les tokens suivent seuls le thème) ; nouveau token
    `--input-bg` pour tous les fonds de champs ; plus aucun style inline sur les pastilles de
    catégorie (classes `.on`/`.mgr` tokenisées) ; le panneau de navigation garde son liseré
    teal en thème sombre (perdu jusqu'ici par un override trop large).
  - **Sémantique** : la marque devient le `h1` du document, les titres de cartes des `h2`
    (plan de titres propre pour lecteurs d'écran) ; le sélecteur de section est un vrai
    `tablist` (flèches ←/→, focus itinérant, `aria-selected`) ; badge « À compléter » souligné
    en pointillés (affordance d'action) ; **bouton « Créer » dans les états vides** ;
    breakpoints consolidés sur une échelle fermée (430/560/640/780/900 px, notée AGENTS.md).

### Sécurité
- Nouveaux garde-fous : `safeAttachment` (id jamais régénéré, entrée invalide rejetée,
  extension `.pdf` garantie même après renommage), `safeFileName`, validateurs du
  mini-Markdown — tous testés (246 tests). Un PDF endommagé affiche un message clair et ne
  bloque jamais la navigation (rendu isolé dans un worker, jamais de code exécuté depuis un
  document). La suppression de compte (RGPD) emporte aussi les protocoles personnels.

### À savoir
- Le schéma serveur doit être re-exécuté (`supabase/schema.sql`) puis validé avec
  `supabase/rls-tests.sql` pour activer bucket et table `protocols`.
- Multi-onglets : si la bibliothèque semble vide après la mise à jour, fermez les autres
  onglets de l'app puis rechargez (migration de la base locale en attente).
