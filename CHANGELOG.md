# Journal des modifications

## [4.44.0] — 2026-07-27
### Durcissement, sécurité serveur, purge — et le filet qui manquait sur le service worker
Quatre lots techniques du reliquat d'audit, sans effet visible à l'écran.

### Durcissement
**`esc()` échappe désormais l'apostrophe.** La doctrine en fait « la SEULE barrière anti-XSS » : la
laisser suspendue à l'invariant non vérifié « aucun attribut n'est délimité par une apostrophe »
faisait reposer la sûreté de tout le fichier sur une convention que rien n'impose. Innocuité
établie avant écriture : 278 sites d'appel, dont **0 `textContent`, 0 `setAttribute`, 0 comparaison
de chaîne** — la sortie ne va que dans du HTML, où l'entité est re-décodée.

**Le backtick, lui, reste intact — et c'est une décision, pas un oubli.** Il a été échappé, puis
rétabli : trois tests du mini-Markdown tombent aussitôt, parce que `mdInline` échappe d'abord et
reconnaît la syntaxe ensuite — un backtick devenu `&#96;` n'est plus un délimiteur de code. Et ce
n'est pas un métacaractère HTML. L'échapper coûtait une fonctionnalité documentée pour zéro sûreté.
Les deux tests encodent maintenant la règle **et son exception**.

Le risque réel n'était pas la sûreté mais l'affichage : les textes français sont pleins
d'apostrophes. Balayage de **7 surfaces × 2 moteurs** (accueil, session vive, feuilles Consulter et
Se repérer, statique, éditeur, protocole) — **aucune entité littérale**, la sonde prouvant par
contre-épreuve qu'elle sait en voir une.

**`check-colors` : exemption resserrée à la règle, plus à la ligne.** Elle était `^.*\.acc-sw\..*$`
— ligne entière. Or ce CSS écrit plusieurs règles par ligne : trois lignes exemptées, dont **deux
portant six règles chacune**, et une troisième sans le moindre hex. Un hex collé en fin d'une de
ces lignes passait inaperçu ; il est désormais attrapé (démontré, puis fichier restauré à l'octet).

### Sécurité serveur
`pg_temp` ajouté en fin des **20** `search_path` épinglés, et les **2 fonctions trigger** —
`clamp_updated_at`, `stamp_updated_by` — qui n'en avaient aucune en reçoivent une. Nuance honnête :
`pg_temp` n'est jamais consulté pour résoudre une fonction ou un opérateur, seulement pour les
tables, et toutes les relations sont déjà qualifiées `public.…` — on ferme une porte déjà fermée
par ailleurs. On le fait parce que c'est gratuit et que l'absence est ce qu'un auditeur tiers
relève en premier. Vérifié : **0 `search_path` nu, 0 sans `pg_temp`**.

**`FORCE ROW LEVEL SECURITY` n'est PAS activé, et le piège est désormais écrit dans le schéma.**
L'ajouter par réflexe supprimerait **tous les app-admins** : `app_admins` et `app_settings` n'ont
volontairement ni politique ni grant, et ne sont lues que par `is_app_admin()`/`is_approved()`, qui
sont `security definer` précisément pour traverser cette invisibilité. Sous `force`, le
propriétaire redevient soumis aux politiques — il n'y en a aucune — donc plus aucune création de
bibliothèque ni validation de compte sur toute l'instance.

> ⚠ **`supabase/schema.sql` est à rejouer** sur l'instance Supabase, puis `rls-tests.sql`.

### Purge (règle 14) — zéro pixel changé
- **`state.showSess`** : déclaré, remis à false deux fois, **jamais lu**.
- **`_rtShowDirty`** : quatre écritures, **zéro lecture** — deux écouteurs globaux (`scroll`,
  `resize`) entretenaient une valeur que personne ne consultait, et le commentaire décrivait une
  optimisation qui n'existait plus.
- **Modificateur `compact`** : émis deux fois, **aucune règle CSS** dans tout le fichier.
- **Délégation du plan dans `bindOverviewEvents`** : trois branches inatteignables. Ce gestionnaire
  écoute `.ov-wrap`, le journal ; le plan l'a quitté en v4.23.0. Mesuré avant retrait dans
  **21 configurations** (3 largeurs × 7 états) : `.ov-wrap [data-pl*]` = **0 partout**, pendant que
  le rail en portait 9 dès 800 px et la feuille 9 une fois ouverte.
- **Trois règles CSS strictement dupliquées** (`.dock-plan:hover`, `.catchip{position:relative}`,
  `#crtIA .crt-ic`). Un **quatrième** doublon strict existe — `body.view-read .read-grid` @1200 —
  et il est **délibéré**, réaffirmé exprès après le bloc 1000 pour gagner par l'ordre de cascade.
  Il apparaît dans la même liste que les autres : ne jamais passer d'outil « supprimer les règles
  dupliquées » sur ce fichier.
- **`--pulse`** était la copie décimale **exacte** de `--ok` dans les deux thèmes (29,122,56 et
  55,214,122). Invisible au garde-fou couleurs, puisque c'était une déclaration de token : changer
  `--ok` aurait laissé le halo derrière. Source unique désormais — `--ok-rgb` porte le triplet,
  `--ok` en dérive. Vérifié au calculé : `rgb(29, 122, 56)` / `rgba(29, 122, 56, 0.45)` en clair,
  `rgb(55, 214, 122)` / `rgba(55, 214, 122, 0.45)` en sombre, identique sur les deux moteurs.
- **`#brandSub .sess-dot`** : CSS mort. `.sess-dot` n'est émis que dans les cartes « sessions en
  cours » de l'accueil ; `#brandSub` est un `<span>` de texte. 0 nœud sur 3 états × 2 moteurs.

### Commentaires qui mentaient
- `posoCardsHtml` s'annonçait « source unique **partagée par le flux et la feuille Consulter** — les
  deux rendus ne peuvent pas diverger ». Faux depuis v4.25.3, qui a retiré la posologie de la
  feuille : il ne reste qu'**un** site d'appel. Le commentaire promettait une garantie de
  non-divergence entre deux rendus dont l'un n'existe plus. **AGENTS.md portait la même
  affirmation**, en contradiction avec sa propre section « FEUILLE CONSULTER » deux paragraphes
  plus haut — corrigé aux deux endroits.
- `_vvhSync` annonçait « ~1 s » : il tourne à **3,3 fois par seconde** (`setInterval(…,300)`, appel
  placé avant le garde d'activité). Coût mesuré : **nul** — `vv.height` est déjà calculé, et
  l'écriture n'a lieu qu'au-delà de 0,5 px de variation. Le chiffre est corrigé parce qu'un
  commentaire faux sur une fréquence est ce qui fait ensuite « optimiser » au jugé une boucle qui
  ne coûte rien.

### Le filet manquant : `scripts/check-sw.mjs`
**La fonction dont tout dépend en intervention — exister hors ligne — était la seule que rien ne
mesurait** : aucun des onze harnais ne regardait `sw.js` ni le manifeste, et trois des défauts les
plus graves de cet audit vivaient là, trouvés à la lecture seule. Quatre contrôles **statiques**,
donc instantanés, donc dans `npm run check` à chaque commit : toute entrée d'`ASSETS` /
`CORE_ASSETS` / `PDFJS_ASSETS` existe sur le disque (une entrée fantôme dans `CORE_ASSETS` fait
échouer `addAll`, qui est tout-ou-rien, et supprime le hors-ligne entier) ; `CORE_ASSETS` ⊆
`ASSETS` ; tout fichier servable de la racine est dans `ASSETS` — la règle 13 ne s'auto-exécutait
pas ; `CACHE` aligné sur `APP_VERSION`, c'est-à-dire la règle 1. Vérifié capable d'échouer sur les
deux scénarios, fichier restauré à l'octet.

513 tests × 2 moteurs, 11 harnais verts (34/34 en doctrine), 289 contrôles d'accessibilité.

## [4.43.0] — 2026-07-27
### Deux arbitrages tranchés : 320 px est servi, et la production est GitHub Pages
Décisions utilisateur. Elles débloquent quatre constats du reliquat d'audit.

### 320 px — WCAG 1.4.10, et deux rognages silencieux
C'est le plancher de « Reflow », et deux surfaces y perdaient du contenu sans le dire :

- **rangée de commandes de crise** : 348 px requis pour 320, soit **28 px inatteignables** — le
  bouton restait opérable (44 px visibles, `aria-label` intact) mais se lisait « ⤢ Con », coupé en
  plein mot ;
- **`⋯` de l'éditeur** : **6,2 px hors écran**, bouton pourtant `display:grid` donc bien peint.

Identique sur Chromium et WebKit. Les pixels viennent de la recette v4.23.4 — écarts et
rembourrages — jamais d'un renommage (règle « troncature du même mot ») ni d'une 2ᵉ ligne (la
hauteur de crise est un coût permanent) : **34 px rendus pour 28 nécessaires** dans la crise,
~12 pour 6,2 dans l'éditeur.

Une analyse antérieure concluait que la recette était épuisée et qu'il faudrait sacrifier
`.ctrl-sp`. C'est faux, et pour une raison précise : elle visait les postes déjà compressés en
v4.30.0, jamais le rembourrage des deux segments de mode (12 px à lui seul) ni celui des deux
ouvertures. **`.ctrl-sp` n'est pas touché** — ces 4 px sont l'écart de Gestalt qui sépare le MODE
des OUVERTURES, raison d'être de la séparation ECP/ECAM de v4.25.0.

Le harnais gagne un contrôle qu'il n'avait pas : le **rognage par le conteneur**. Un bouton peut
tenir dans la fenêtre tout en étant coupé par sa boîte de contenu — c'est exactement ce qui se
produisait, et le contrôle « hors écran » seul passait au vert. `audit-doctrine` mesure désormais
320/360/375/390 pour la crise et 320/360 pour l'éditeur (34/34).

### Hébergement : GitHub Pages en production, déployable ailleurs
Décision datée dans `docs/deploiement-et-conformite.md` et en tête de `_headers`. Conséquence
assumée : **`_headers` est maintenu à jour bien que GitHub Pages l'ignore totalement** — il n'est
pas décoratif, c'est la posture servie sur tout autre hébergeur, et le supprimer ferait disparaître
le seul endroit où elle est écrite.

Ajoutés : `Cross-Origin-Opener-Policy` et `Cross-Origin-Resource-Policy` en `same-origin`
(`window.open` est absent du code — vérifié, 0 occurrence — donc aucun échange de fenêtre à
casser), et une `Permissions-Policy` portée de 3 à **21 capacités**.

**COEP `require-corp` est délibérément absent** : aucun `SharedArrayBuffer`, aucune ressource
cross-origin embarquée, donc il ne protège rien — et il casserait au premier ajout. Un en-tête qui
ne protège rien et casse plus tard est une dette.

Trois capacités restent **volontairement ouvertes**, et la liste a été établie par mesure, pas
recopiée d'un modèle :
- **`autoplay`** — le bip d'alarme passe par WebAudio, soumis à la politique d'autoplay. Le fermer
  rendrait l'alarme de minuteur **muette** : la sortie la plus critique de l'application.
- **`screen-wake-lock`** — inutilisé aujourd'hui, mais garder l'écran allumé pendant une
  réanimation est un besoin plausible.
- **`web-share`** — `navigator.share` est le chemin **obligatoire** du téléchargement PDF en PWA
  installée (v4.19.1 : WebKit ignore `download` en standalone).

`launch_handler: {client_mode: "focus-existing"}` ajouté au manifeste — la seule des quatre clés
manquantes qui porte un argument clinique (ne pas ouvrir une seconde fenêtre pendant une session
vive). iOS ne l'implémente pas ; Android et bureau si.

**`"id": "./"` n'est PAS modifié**, et la raison est écrite pour la prochaine fois : `id` se résout
par rapport à l'**origine**, pas au chemin du manifeste. Le changer ferait apparaître l'app comme
une **nouvelle application** chez tout utilisateur l'ayant installée — doublon sur l'écran
d'accueil, ancienne installation figée sur son cache. C'est une porte à sens unique. Contrainte qui
en découle : ne pas héberger une seconde PWA sur la même origine.

510 tests × 2 moteurs, 11 harnais verts (34/34 en doctrine), 289 contrôles d'accessibilité.

## [4.42.0] — 2026-07-27
### Le reliquat d'audit trié : 36 % était périmé
Les 70 constats jamais traités de la Phase 1 ont été reconfrontés au code actuel, chacun sous
contre-expertise. **25 sont tombés** : 2 déjà corrigés, 5 mal fondés, 18 dont la preuve se
reproduit mais dont le verdict s'inverse (victime inexistante ou remède pire que le mal). Restent
45, dont **22 sont des questions à trancher** et 23 des corrections — dont **4 seulement changent
quelque chose pour un soignant**. Ce sont ces quatre-là.

Deux familles se sont effondrées en bloc. Les constats de **performance** mesuraient des *comptes
d'appels* sans chronomètre : le tick de 300 ms coûte 0,5 ms/s de mise en page, le resize PDF
0,26 ms, `syncHdrScroll` 0,10 ms/s de gain potentiel — à comparer aux 126,8 ms/s du seul vrai
levier de v4.41.0. Les constats **« le dépôt ne documente pas X »** reposaient sur des greps qui
excluaient `CHANGELOG-archive.md`, qui est pourtant le canal de décision du projet.

### Décocher ne défaisait pas la fin de l'algorithme, en mode guidé
Le cœur du cochage existe en deux copies, guidé et journal, et elles avaient divergé. Le journal
remet `state.flowEnded` à false puis re-rend si la bannière traîne. Le guidé faisait le reset dans
la branche `else` d'un `if(nn)` — or quand la fin est actée, `#navNext` **n'existe plus** :
`navSection` le remplace par la bannière `.flow-end`. `nn` étant null, le bloc entier était sauté
et le reset ne s'exécutait **jamais dans le seul cas où il sert**. Mesuré sur une fiche mono-bloc
(ce que rend `blankFiche()`, donc toute fiche neuve) : « Algorithme terminé — surveillance en
cours » restait affiché après décochage et « Terminer l'algorithme » ne revenait pas.

**Ce chemin n'était couvert par aucun test** : `grep -rn 'nav-wrap\|navNext\|bindNavEvents'
tests.html scripts/` rendait 0. Cinq contrôles ajoutés à `audit-doctrine.mjs` (27/27), vérifiés
capables d'échouer — défaut réintroduit, 3 échecs, fichier restauré à l'octet.

### L'alarme routée était muette pour les lecteurs d'écran
Session hors de vue (autre fiche, autre vue), un minuteur sonne : banderole visuelle, flash écran,
et notification système **seulement si l'app est en arrière-plan**. Restait le bip — qui dit qu'un
minuteur a sonné, jamais **lequel** ni **sur quelle fiche**. C'est précisément le cas où
l'information manque : une session vive sur une autre fiche pendant qu'on lit un différentiel.
`announce()` écrit désormais dans `#srLive` (`role=alert`, `aria-live=assertive`) : audible côté
lecteur d'écran, **invisible à l'écran** — la règle 11 tient, rien ne bouge et rien ne se pose
par-dessus la checklist. Vérifié : une seule banderole ajoutée, pas deux (WCAG 4.1.3).

### Trois minuteurs de même id n'en armaient qu'un
`migrate()` déduplique les ids de blocs (`while(used[nid])`) mais pas ceux des minuteurs ni des
compteurs. Or `Runtime.timers` est indexé par id : trois entrées de même id, **une seule armée, la
dernière**, sans le moindre signal — et les ids DOM (`tmval-`, `cnval-`) se télescopent. Une fiche
importée, dupliquée ou reçue d'une bibliothèque partagée passe par là, et la règle 5 veut que
`migrate()` soit le point où une donnée entrante devient sûre. Le premier garde son id (les
références `counters[].timerId` continuent de résoudre sur lui) ; les suivants en reçoivent un
neuf. Mesuré : 3/3 ids distincts, 3/3 minuteurs armés, 3/3 cartes, 2/2 compteurs.

### Un pull de synchro avalait un tap en pleine réanimation
`if(applied)render()` reconstruisait tout le DOM dès qu'une seule ligne distante était écrite —
y compris en session vive. La règle 11 l'interdit déjà en toutes lettres (« aucune synchro
intrusive ») : ce n'était donc pas un arbitrage. Il suffisait qu'un coéquipier modifie une ligne
d'une bibliothèque partagée.

Le premier contrôle que j'avais écrit était faux, et il faut le dire : un `.click()` programmatique
sur un nœud détaché déclenche quand même son handler (la fermeture survit), et je comptais des
*clés* de `state.checked` alors que décocher écrit `false` et conserve la clé. Un tap réel est
`pointerdown → pointerup → click`, et le click n'est émis que si les deux atterrissent sur le même
élément : le défaut est donc « DOM remplacé entre les deux ». Reproduit à la vraie souris,
Chromium **et** WebKit — **témoin : 0 → 0 coche** (tap avalé) ; **après correctif : 0 → 1**, sans
re-rendu ; et hors session le rendu se déclenche toujours.

Rien n'est perdu pendant ce temps : la mémoire est déjà à jour, et toute sortie de crise passe par
`render()`. Ce qui reste vrai, et c'est voulu : **la fiche ouverte ne change pas sous les yeux du
soignant** — une aide partagée réécrite à distance en pleine réanimation ne se substitue pas à
celle qu'on déroule ; la nouvelle version arrive à la réouverture.

510 tests × 2 moteurs, 11 harnais verts (dont 27/27 en doctrine), 289 contrôles d'accessibilité.

## [4.41.0] — 2026-07-27
### Phase 3 (optimisation) — premier lot : le seul vrai levier de performance, et deux invariants
La campagne de mesure a couvert six dimensions (démarrage, re-rendus, calcul répété, service
worker, CSS, Web Vitals) sous vérification adversariale. **Le résultat principal est que
l'application est déjà rapide** : 26 « rien à faire » démontrés, 16 constats réfutés, et **un seul**
levier de performance réel. Les chiffres du budget, re-mesurés machine au repos : démarrage 66 ms
(CPU nominal) / 262 ms (×4) ; un parcours clinique complet ne déclenche que 5 `render()` complets ;
`esc()`, appelée 817 fois par rendu, coûte 0,06 ms.

### `transition:width` sur la barre de minuteur → `transform:scaleX()`
`width` est une propriété de **mise en page** : animée en continu, elle force un layout par image.
En session vive avec un minuteur d'intervalle armé et le panneau ouvert, six secondes sans le
moindre geste : **118 layouts/s, 123 recalculs de style/s**, soit 126,8 ms/s de fil principal à CPU
nominal, 206,9 à ×4 et 377,3 à ×6 — **jusqu'à 38 % d'un cœur brûlés pendant toute une réanimation**,
sans qu'aucun JS ne s'exécute.

Mesuré après application, sur le fichier réel contre un témoin `width` réinjecté :
115,0 → **11,4** ms/s (×1), 193,5 → **18,2** (×4), 248,0 → **25,9** (×6) ; 115 → **2** layouts/s.
WebKit, hors CDP : **+9,7 %** de débit utile du fil principal.

Un arbitrage annoncé n'a finalement pas eu lieu d'être. Deux vérificateurs divergeaient sur ce que
rend `scaleX` — l'un mesurait ~120 recalculs de style/s résiduels, ce qui aurait obligé à choisir
entre performance et rendu. L'A/B rejoué à trois variantes (actuel / `scaleX` / sans transition),
servies en mémoire, tranche : **17 recalculs/s**, l'animation est bien composée, et `scaleX` rend
autant que supprimer l'animation *sans changer le rendu*. Le gain est de la **marge CPU et de
l'autonomie**, pas de la fluidité (120 fps et latence de cochage identiques) — ne pas le vendre
autrement.

Rendu vérifié au pixel, et la première sonde était fausse : elle mesurait un minuteur **en marche**,
donc une cible mouvante (le « 0 % » relevait `scaleX(0.9912)` — le minuteur avait rebouclé). Refaite
à minuteur figé : géométrie identique à 0,01 px près, et la comparaison des captures ne diffère que
sur **une colonne de 4 px** — l'anticrénelage du bord mobile, écart max 73/255 — plus les deux
extrémités arrondies à 100 % (≤ 9/255). Identique dans les deux thèmes. Une source unique `barTf()`
sert le gabarit ET le tick : deux formats seulement équivalents (`scaleX(0.76)` vs `scaleX(0.7600)`)
feraient échouer la comparaison anti-churn et réécriraient le style 3,3 fois par seconde. Vérifié :
17 écritures en 5 s pour ~16,7 passages du tick, soit une par tick.

### Garde-fou `scripts/check-anim.mjs`, dans `npm run check`
Aucune propriété de mise en page dans un `transition` ni dans un `@keyframes`. La règle était déjà
respectée partout ailleurs (19 keyframes sur 19) — c'est le profil exact d'une règle qu'un seul oubli
trahit sans que rien ne le signale. Une exemption, motivée : `.skiplink` (glissement de 120 ms une
fois par focus ; le convertir mettrait en jeu une position dépendant d'`env(safe-area-inset-top)`,
soit un risque d'accessibilité pour un gain nul). Le contrôle a été **vérifié capable d'échouer**
(défaut réintroduit, message juste, fichier restauré à l'octet) — leçon v4.31.1 : un garde-fou qui
ne peut pas échouer ne prouve rien.

### `touch-action:manipulation` sur les étapes cochables
AGENTS.md § Interactif énonce que « tous les contrôles » le portent. Mesuré en session vive à
390×844 : **5 cibles en `touch-action:auto`** sur « Anaphylaxie », 3 sur « Arrêt cardiaque » — les
`li[role="checkbox"]` du parcours, que la règle de base ne couvrait pas alors que
`li.md-task[role="checkbox"]` (protocoles) le posait déjà. Après : **0**, sur Chromium et WebKit.
Le gain n'est pas un délai de tap — le délai de ~350 ms n'existe plus pour un viewport
`width=device-width`, et le commentaire qui l'affirmait encore avait servi à justifier de ne pas
étendre la règle : il est corrigé. Ce que le réglage évite est le **zoom parasite** quand deux taps
tombent à moins de ~40 px l'un de l'autre — 12 px mesurés entre deux étapes voisines, et en
réanimation on coche des étapes voisines à la chaîne.

### Un minuteur échu ne peignait pas son état sur les rangées compactes
Trouvé par la sonde du point précédent. `.tm-mini` (rangée compacte d'un minuteur ad hoc, le
« ＋ Minuteur PA ») partage l'id `tmcard-<id>` avec la carte pleine, et `syncTimerBtns` bornait son
basculement d'état à `.tmcard`. Mesuré sur **Chromium ET WebKit** : le modèle disait « échu », la
rangée restait NEUTRE tant qu'aucun re-rendu complet ne passait — alors que `.tm-mini.due` est bien
stylée (cadre et encre ambre). L'alarme n'était pas perdue (le quai porte l'ambre, canal
d'acquittement documenté), mais elle manquait là où l'œil se trouve quand le panneau est ouvert.
`paused` reste réservé à la carte pleine : `.tm-mini.paused` n'a pas de règle.

510 tests × 2 moteurs, 11 harnais verts, 289 contrôles d'accessibilité.

## [4.40.0] — 2026-07-26
### Les 4 dernières fenêtres : le harnais d'accessibilité couvre les 20 sur 20
`attPickModal`, `relPickModal`, `reportModal` et `newLibModal` étaient signalées « résistantes » en
v4.39.0. Elles ne résistaient pas : **mes appels étaient faux**. Les vraies signatures sont
`openAttPicker(entity, rerender)`, `openRelPicker(entity, rerender)` et surtout
`exportSessionReport(sessionId)` — un **ID**, pas l'objet session. `openNewLib()` est par ailleurs
gardée par `myIsAppAdmin` : garde métier légitime, dont la vraie barrière est la RLS serveur ; la
sonde la lève pour auditer le RENDU, ce qui est l'objet du harnais.

Le compte-rendu n'est atteignable que par le parcours COMPLET (ouvrir, démarrer, terminer) puisqu'il
lit `sessions`, les sessions **archivées**. C'est en le déroulant qu'un défaut de sonde plus gênant
est apparu.

### Défaut de sonde corrigé : trois fenêtres mesuraient un contexte FACTICE
Les surfaces « historique sessions », « terminer la session » et « complications » posaient
`state.view='read'; state.fiche=f; render()` à la main. Or ce n'est pas le point d'entrée :
`openRead(id)` appelle `buildRuntime` puis `bindStateToRuntime`, sans quoi **le Runtime n'est pas
installé** — le clic sur « démarrer la session » ne démarrait donc rien. Mesuré :
`Runtime.started=false`, `liveSessions=0`, `sessions=0`. Les trois fenêtres s'ouvraient bien, mais
dans un contexte SANS session vive, pas celui que le harnais annonçait ; une régression propre à la
session vive n'aurait pas été vue. Les trois passent par `openRead(f.id)`.

C'est le même travers que le `classList.add('on')` refusé en v4.39.0, en plus discret : reconstruire
un état à la main au lieu d'emprunter le chemin de l'utilisateur. Défaut du harnais, jamais de l'app.

### Résultat
**289 contrôles, 20 fenêtres × 2 thèmes, aucun défaut.** Les 4 dernières fenêtres n'ont rien révélé —
résultat en soi : les corrections de v4.37→v4.39 (associations `for=`, noms de champs, `[hidden]`
impératif, cibles) tenaient déjà sur les surfaces non encore auditées. Les 11 harnais restent verts,
510 tests sur Chromium et WebKit.

## [4.39.0] — 2026-07-26
### Harnais d'accessibilité : de 6 fenêtres auditées à 16 sur 20
Chaque fenêtre est ouverte par son **vrai point d'entrée**, après CONSTRUCTION de son contexte —
session vive pour « Terminer la session » et l'historique, sauvegarde de version pour « Versions
précédentes », complication déclarée pour l'index ⚡, document joint pour la visionneuse PDF. Jamais
un `classList.add('on')` : une fenêtre forcée vide n'a pas le contenu qu'on veut mesurer et
produirait des verdicts faux. Le mécanisme `prep` accepte donc désormais une **fonction**,
sérialisée par Playwright — la mise au point a d'ailleurs confirmé que la CSP du projet **interdit
bien `eval()`** : la première version de la sonde, qui passait du code en chaîne, a été bloquée.

Les 4 dernières (`attPickModal`, `relPickModal`, `reportModal`, `newLibModal`) résistent encore :
leurs points d'entrée attendent des arguments ou un état non reconstitué. Signalé plutôt que
contourné.

### Ce que ces dix fenêtres ont révélé
- **Un faux positif du harnais — corrigé dans le harnais, pas dans l'app.** `#pendToggle` était
  signalé à 13×13 px, sous le seuil de 24. Mais son `<label>` parent fait **358×65 px** et coche la
  case au clic : la CIBLE au sens de WCAG 2.5.8 (« la zone qui accepte l'action du pointeur ») était
  donc largement conforme. Le harnais mesure désormais le label quand il en existe un — même esprit
  que la recherche de l'anneau de focus sur les ancêtres, déjà en place. Agrandir les cases pour
  faire taire ce contrôle aurait été un changement visible pour un défaut inexistant.
- **Mais les cases se LISAIENT mal** (décision utilisateur) : aucune règle du projet ne les
  dimensionnait, elles gardaient les ~13 px du navigateur — dont l'interrupteur de sécurité
  « Exiger une validation pour les nouveaux comptes ». Passées à **20 px** avec
  `accent-color:var(--primary)` : la case cochée prend le bleu de l'app au lieu du bleu système.
  Appliqué aux **quatre** cases de l'app (confirmation, suppression locale, validation des comptes,
  boucle d'un minuteur) — les styler une par une aurait recréé l'incohérence.
- **Le bruit réseau est filtré nommément** : les fenêtres liées au compte interrogent Supabase et
  crient `ERR_INTERNET_DISCONNECTED` hors réseau. C'est le contexte de la sonde, pas un défaut de la
  page ; seul ce motif est filtré, pour ne pas masquer une vraie erreur.

**241/241** contrôles d'accessibilité — contre 121 avant, sur un périmètre deux fois plus étroit.

510 tests × 2 moteurs, 22/22 doctrine, 241/241 accessibilité, 163 contrôles d'audit, 10 sondes.

## [4.38.0] — 2026-07-26
### Tous les champs de l'éditeur ont enfin un nom
**39 champs sur 53 n'étaient nommés que par leur `placeholder`** — qui disparaît dès qu'on tape.
Concrètement : on revient sur un champ déjà rempli, et plus rien ne dit ce qu'il contient ; un
lecteur d'écran annonce « champ, texte » sur ce qui est peut-être la dose d'un protocole de
réanimation. C'est WCAG 3.3.2 et 4.1.2, et c'est l'antipattern le plus répandu des formulaires.

Le diagnostic a montré que ces 39 champs n'étaient **pas de même nature**, et qu'un `aria-label`
uniforme aurait été la mauvaise réponse :
- **4 gabarits avaient déjà un `<label>` visible ET un `id`** : il suffisait de les associer
  (`for=`). Aucune duplication, et le libellé devient cliquable pour focaliser le champ.
- **Les autres sont des LIGNES DE LISTE** — « Ne pas oublier », étapes d'un bloc, options d'une
  décision — coiffées par un `<label>` de section qui ne peut être associé à aucune en particulier.
  Elles reçoivent un nom qui dit leur liste ET leur rang : « Ne pas oublier — ligne 1 »,
  « Étape 3 », « Libellé de la réponse 2 ».
- **Les rangées de minuteur et de compteur** reçoivent le nom de ce qu'elles règlent (« Nom du
  cycle », « Nom du chronomètre », « Nom du compteur »), et le sélecteur de relance — jusqu'ici
  nommé par un simple `title`, pis-aller que tous les lecteurs ne lisent pas et qui n'existe pas
  sur mobile — reçoit un vrai `aria-label`.

Vérifié : **0 champ anonyme et 0 champ nommé par son placeholder** sur les 53 de l'éditeur, et
**aucun nom n'est une simple copie du placeholder** (contrôlé explicitement — recopier « ex. Oui »
n'aurait rien nommé du tout).

Aucun changement de rendu : le diff est de 11 lignes modifiées pour 11, uniquement des attributs,
et aucune règle CSS du fichier ne cible `label[for]` ni `[aria-label]` (vérifié).

510 tests × 2 moteurs, 22/22 doctrine, 121/121 accessibilité, 143 contrôles d'audit, 10 sondes.

## [4.37.0] — 2026-07-26
Deux garde-fous élargis, et **un bouton fantôme trouvé grâce à l'un d'eux**. Aucun changement de
rendu voulu — et aucun constaté, vérifié par comparaison des couleurs calculées avant/après dans
les deux thèmes.

### Garde-fou couleurs — il ne voyait que la moitié de la règle
`check-colors.mjs` n'inspectait que les **hex**. Un token recopié en DÉCIMAL passait donc au
travers, et c'est exactement la dérive que la règle proscrit : cinq occurrences de `rgba(16,27,40,…)`
— la valeur de `--ink` — vivaient dans les voiles et les élévations. Si `--ink` changeait, elles
seraient restées derrière.

Sur les 34 valeurs littérales du CSS, le tri est net et toutes ne sont pas des dérives :
- **5 étaient de vraies copies de token** → tokenisées, à valeur **strictement identique** :
  `--scrim-soft` (voile du menu de catégories), `--scrim` (fenêtres), `--scrim-full` (visionneuse
  d'image), `--shadow-dock` et `--shadow-bar`. Aucun override sombre ajouté : ces valeurs n'en
  avaient pas, en créer un serait un changement visible.
- **Le reste n'est PAS de la palette** et est exempté avec sa raison dans le script : noir et blanc
  PURS (profondeur, voiles neutres — ils ne portent aucune sémantique de registre) et les deux
  teintes de l'alerte de minuteur, dérivées d'aucun token. Un garde-fou qui crie sur ce qui va bien
  finit ignoré.

Le contrôle accepte désormais `rgb()`, `rgba()`, `hsl()`, `hsla()`. Contre-épreuve faite : remettre
`rgba(16,27,40,.55)` à la place de `var(--scrim)` le fait échouer.

### Harnais d'accessibilité — de 2 fenêtres auditées à 6
Il ne mesurait que `#planModal` et `#refModal` sur les **20** `.ai-modal` de l'application. Quatre
de plus y entrent (dialogue Créer, gérer les catégories, fenêtre Compte, « où sont mes fiches »),
ouvertes par leur **vrai point d'entrée** — jamais par un `classList.add('on')`, qui donnerait une
fenêtre vide et des verdicts faux. Les 16 autres exigent un contexte construit (session vive,
document joint, sélection, erreur de synchro) : mesuré, aucune ne s'ouvre par un simple appel —
c'est un chantier à part, avec une fixture par fenêtre.

**Ces quatre fenêtres ont immédiatement révélé deux défauts réels :**
- **`[hidden]` était une suggestion, pas une instruction.** La feuille du navigateur pose
  `display:none` pour cet attribut, mais avec une spécificité si faible que toute règle de classe
  portant un `display` l'écrase. Le projet compensait par une règle ponctuelle par composant —
  **vingt** au total — qu'il fallait penser à écrire, et `.tlink` avait été oublié : `#authAnon`,
  pourtant marqué `hidden`, s'affichait en **bouton VIDE de 20×32 px** dans la fenêtre Compte.
  Une règle globale `[hidden]{display:none!important}` ferme la classe entière de bugs ; vérifié
  qu'aucune règle du fichier n'affiche volontairement un élément `[hidden]`.
- **`.crt-chev`** (le chevron des cartes du dialogue Créer) était en `--line-strong` : 4,32:1, sous
  le seuil AA. C'est la règle déjà écrite dans `AGENTS.md` — `--line-strong` vise 3:1 pour les
  BORDURES et échoue en couleur de TEXTE — simplement jamais appliquée ici, faute que cette fenêtre
  soit mesurée. Passée à `--ink-soft`.

**121/121** contrôles d'accessibilité (117 avant l'élargissement, sur un périmètre plus étroit).

510 tests × 2 moteurs, 22/22 doctrine, 121/121 accessibilité, 143 contrôles d'audit, 10 sondes.

## [4.36.0] — 2026-07-26
### Corrigé — 1,77 Mo chargés pour ne rien dessiner
Ouvrir une fiche portant un PDF déclenchait le chargement de **pdf.js en entier** — `pdf.min.js`
389 Ko à +106 ms, `pdf.worker.min.js` 1 384 Ko à +181 ms — alors qu'aucun document n'avait été tapé.
Cela contredisait la règle du projet (« pdf.js chargé paresseusement, `import()` au premier document
OUVERT, jamais au démarrage »), sur l'écran de soin lui-même.

**Et c'était pire que ça.** Depuis la v4.23.0, la liste « Documents » d'une FICHE a quitté la colonne
d'action pour la feuille « Consulter », qui ne s'ouvre qu'à la demande. Mesuré à l'ouverture d'une
fiche : **0 rangée `[data-att]`, 0 emplacement `[data-thumb]` dans toute la page** — les 1,77 Mo
n'avaient littéralement rien à peindre. La chaîne `bindReadEvents` → `bindAttList` →
`hydrateAttThumbs` appelait la génération de vignettes **inconditionnellement**, alors que
`bindAttList` cherche ses rangées dans `main`, où il n'y en a plus. Travail intégralement perdu, et
redondant de surcroît : `renderRefSheet` rappelle `hydrateAttThumbs` à l'ouverture de la feuille,
là où les rangées existent.

Correctif d'une ligne — ne générer les vignettes que si une rangée est réellement dans le flux :
`if(main.querySelector('[data-thumb]')) hydrateAttThumbs(entity);`. Vérifié sur les trois cas qui
comptent : fiche seule → **0 Ko au lieu de 1 773** ; feuille « Consulter » ouverte → pdf.js chargé
et vignette peinte (96×128 px) ; **protocole → comportement inchangé** (ses documents sont dans le
flux, la condition est vraie pour lui).

> Nuance conservée pour la suite : ce n'est pas du réseau en usage normal (`sw.js` précache pdf.js à
> l'installation), mais le PARSING de 1,8 Mo de JS minifié et le démarrage d'un worker, en CPU, sur
> la vue utilisée pendant un soin. Le travail était différé par `_idle()` — donc il ne bloquait pas
> le premier rendu — mais une tâche d'idle n'est pas préemptible une fois commencée.

### Sécurité serveur — réserve de v4.34.0 LEVÉE
Les modifications SQL n'avaient pas pu être exécutées ici (ni Postgres ni Docker sur le poste) et
étaient livrées relues à la main. **Elles ont été rejouées sur l'instance réelle** : `schema.sql`
appliqué sans erreur, et `rls-tests.sql` répond « ✅ TOUS LES TESTS RLS PASSENT » — donc la
**section 13** (élévation de privilège, rôle anonyme, invitation à e-mail non vérifié) passe, et le
durcissement (`revoke all … from anon`, `alter default privileges`, `email_confirmed_at` exigé)
n'a rien cassé du flux existant.

510 tests × 2 moteurs, 22/22 doctrine, 73/73 accessibilité, 135 contrôles d'audit, 10 sondes.

## [4.35.0] — 2026-07-26
**Phase 4 de l'audit externe : simplification de la structure**, validée sur plan. Aucune ligne de
code applicatif touchée — documentation, arborescence et maintenance du dépôt. Les mesures ont
contredit l'énoncé de départ sur trois points, et le plus gros gain n'était pas dans la doc.

### Le plus gros gain : 144 Mo dans `.git`
- **151 Mo → 6,2 Mo en 2,8 secondes**, par un simple `git gc`. Mesuré avant : `count: 2922` objets
  **lâches** occupant 152 232 Ko, contre 219 objets packés tenant dans 1,1 Mo. `design/ds/`
  représentait **190 Mo sur 365 Mo** de blobs de l'historique, ses 20 fiches de ~275 Ko étant
  réécrites en bloc à chaque `design:build` (46 commits). Elles sont quasi identiques entre elles et
  d'une version à l'autre : elles se delta-compressent presque parfaitement.
- **Conclusion importante : `design/ds/` n'a AUCUN problème de structure.** L'hypothèse d'une
  dé-duplication de son CSS est ÉCARTÉE — l'autonomie de chaque fiche est intentionnelle (l'outil
  distant les lit isolément), la duplication en est le prix assumé. Ce n'était que de la maintenance
  jamais faite. Vérifié après coup : HEAD identique, 299 commits, 125 tags, `git fsck` sans erreur.

### Documentation — 9 → 8 fichiers, et un point d'entrée
- **`AGENTS.md` reçoit un socle « Si vous ne lisez qu'une chose »** : 14 règles qui ne se négocient
  pas (publication, `npm run check`, hashs CSP, `esc()`, `migrate()`, `safeId()`, tokens de couleur,
  registres, plancher 11 px, hauteurs sous zoom, mode crise jamais interrompu, compatibilité
  ascendante, zéro dépendance, vérification d'une suppression au grep) — suivies d'une **carte
  thématique** qui renvoie aux intitulés existants. Le problème n'était pas la longueur du fichier
  mais sa PLATITUDE : 1 297 lignes en une seule liste, sans point d'entrée, où l'on ne pouvait pas
  savoir ce qui est impératif sans tout lire. **Le diff est un AJOUT PUR** (+64/−0 lignes) : aucune
  règle déplacée ni réécrite, vérifié ligne à ligne contre la version précédente.
- **`CHANGELOG.md` : 221 Ko → 51 Ko** (112 → 20 entrées). Les 92 plus anciennes rejoignent
  `CHANGELOG-archive.md` **telles quelles** — 153 entrées avant, 153 après, zéro ligne de contenu
  absente (vérifié par comparaison exhaustive). La règle d'archivage existait déjà et n'avait servi
  qu'une fois ; elle est maintenant inscrite dans la règle de publication, avec son seuil.
- **`design/icons/README.md` fusionné dans `design/README.md`** — deux fichiers pour un seul sujet.
  Au passage, deux erreurs corrigées : le tableau des icônes listait `icon-512.png` **deux fois**
  avec des origines contradictoires, et `design/README.md` annonçait 15 fiches pour 20.
  `scripts/build-favicons.mjs` pointait vers le fichier supprimé : référence mise à jour.
- **`design/ds/GUIDELINES.md` remis à jour** (daté v4.22) : il décrivait encore au présent les trois
  affichages du Plan et le fil d'ancêtres sticky, supprimés en v4.25.0. Or ce fichier est **poussé
  tel quel** vers le projet Design distant : il documentait un composant inexistant auprès d'un
  outil externe. Son idée survit d'ailleurs ailleurs — l'épinglage des bandes-questions du mode
  statique (v4.32.0) — et c'est dit.

### Ce que je n'ai PAS fait, et pourquoi
- **`GUIDELINES.md` n'est PAS déplacé hors de `ds/`**, contrairement à ce que proposait le plan : la
  configuration de synchro dit « la synchro pousse `design/ds/` tel quel », le sortir d'un niveau
  l'aurait retiré du périmètre envoyé. Le plan annonçait donc −2 fichiers ; le résultat réel est −1.
- **Aucun `GEMINI.md`, `.cursorrules` ni `.github/copilot-instructions.md` ajouté.** `AGENTS.md` est
  le standard convergent (Codex, Cursor, Aider, Copilot le lisent), et `CLAUDE.md` l'importe en six
  lignes au lieu de le dupliquer. Ajouter des copies multiplierait les fichiers — contre la demande —
  pour créer la pire configuration : des sources qui divergent.
- **L'arborescence est inchangée.** Six dossiers thématiques, profondeur 3, aucun fichier égaré :
  « regrouper par fonctionnalité plutôt que par type » ne s'applique pas à un projet dont la seule
  fonctionnalité livrée est `index.html`. Et « réduire les niveaux d'abstraction » présupposait des
  couches qui n'existent pas : les deux seules indirections (`Data` sur trois backends, `Sync`)
  gagnent leur place.
- **Aucune règle supprimée d'`AGENTS.md`.** Le constat de phase 1 « AGENTS.md est un changelog
  déguisé » était EXAGÉRÉ : mesuré, 13 % des lignes citent une version, et ces citations sont de la
  traçabilité (« décision utilisateur v4.25.0 ») — elles disent pourquoi une règle existe et qui l'a
  tranchée, ce qui est précisément ce qui empêche de la « corriger » par ignorance.

### Une honnêteté sur les chiffres
Le plan annonçait « 433 Ko → ~230 Ko » de documentation. **C'est faux, et le total AUGMENTE
légèrement** (464 Ko) : les 92 entrées archivées sont DÉPLACÉES, pas supprimées, et le socle ajoute
6 Ko. Le gain réel porte sur le fichier qu'on LIT et que les outils chargent — `CHANGELOG.md`, −76 %
— et sur la navigabilité, pas sur le volume du dépôt.

510 tests × 2 moteurs, 22/22 doctrine, 73/73 accessibilité, 135 contrôles d'audit, 9 sondes dédiées.

## [4.34.0] — 2026-07-26
Troisième lot de l'audit externe : **sécurité serveur, couverture de test et documentation**. Aucun
changement de rendu. Un point à connaître : les modifications SQL n'ont PAS pu être exécutées ici
(ni Postgres ni Docker sur ce poste) — elles sont relues à la main, et doivent être rejouées sur une
instance de test avant d'atteindre la production.

### Sécurité serveur — trois trous de la suite RLS
- **Un membre invité perdait silencieusement son accès à sa première connexion.** Chaîne complète :
  `invite_member` cherchait le compte par e-mail SANS exiger `email_confirmed_at`, or la simple
  DEMANDE d'un code crée déjà la ligne `auth.users` (le client passe `create_user:true`) ; un tel
  compte n'a pas encore de ligne `user_status`, la garde d'approbation lisait donc NULL →
  `coalesce(…,'approved')` → invitation ACCEPTÉE ; puis sa première vraie connexion créait
  `user_status='pending'`, ce qui déclenchait `revoke_memberships` et EFFAÇAIT l'adhésion. L'admin
  voyait « ok », la personne apparaissait dans la liste des membres, et l'accès disparaissait sans
  trace ni message — le scénario le plus banal (« je t'ajoute, connecte-toi »). L'e-mail vérifié est
  désormais exigé : l'invitation prématurée retourne `not_found`, ce que le message client annonçait
  DÉJÀ (« la personne doit d'abord se connecter une fois ») — c'était le SQL qui ne tenait pas le
  contrat, pas l'interface. Le trigger de purge reste sur `insert or update` à dessein (le
  restreindre à UPDATE ouvrirait un trou) : la cause est fermée à la source, et c'est documenté sur
  place pour que la question ne se rouvre pas.
- **« Rien pour le rôle anonyme » était une ABSENCE de grant, pas une interdiction.** Le schéma
  n'ôtait jamais un privilège (0 `revoke` dans tout le fichier) : ne rien accorder à `anon` ne
  garantit rien si le projet porte des privilèges par défaut hérités de sa création, invisibles
  depuis le dépôt. Or la clé publishable est publiée en clair dans `index.html` : `anon` est
  utilisable par quiconque contre l'API REST. La posture affichée — « grants restrictifs PUIS
  RLS » — n'avait donc qu'un seul rempart démontrable. Ajout de `revoke all … from anon` sur les
  tables et les fonctions, **et sur les privilèges FUTURS** (`alter default privileges`), pour
  qu'une table ajoutée plus tard ne soit pas exposée par oubli.
- **Les politiques d'ÉLÉVATION DE PRIVILÈGE n'étaient jamais exercées.** Les onze écritures de la
  suite sur `memberships` et `user_status` étaient TOUTES faites en tant que propriétaire de table,
  qui CONTOURNE la RLS : `mem_write`, `lib_update`, `lib_delete` et `user_status_write` n'avaient
  jamais été testées, alors que `memberships` est la table dont dépendent toutes les autres
  politiques partagées (`member_role()` est consultée par cinq d'entre elles — une faille d'écriture
  y compromettrait tout d'un coup). **Section 13** ajoutée, chaque test en `set local role
  authenticated` : un viewer ne s'élève pas admin, un non-membre ne s'ajoute pas, un editor ne
  renomme ni ne supprime la bibliothèque, personne ne s'approuve soi-même, `anon` ne lit AUCUNE des
  sept tables publiques, et une invitation à un e-mail non vérifié est refusée.

### Tests — la cible principale n'était pas testée
- **`npm test` joue désormais Chromium ET WebKit.** iOS Safari est la cible principale (PWA
  installée sur iPhone, usage SMUR) et toute la suite tournait sur Blink seul — alors que le dossier
  « bande basse iOS » (v4.29.x) a précisément montré qu'un comportement WebKit peut couper l'écran
  sans qu'aucune mesure web ne le voie. Les fonctions pures ne sont pas à l'abri non plus
  (`DecompressionStream` de l'import .zip, regex, normalisation Unicode). WebKit absent produit un
  AVERTISSEMENT et non un échec, même dégradation douce que pour Playwright lui-même ; la CI
  l'installe. Résultat : **510 tests verts sur les deux moteurs**.
- `run-tests.mjs` ne JETTE plus les erreurs console quand la page ne boote pas : c'est le mode
  d'échec le plus probable (hashs CSP périmés, erreur de syntaxe) et il produisait jusqu'ici la
  sortie la moins lisible — l'exception emportait la seule information utile.

### Sécurité côté document
- **`<meta name="referrer" content="no-referrer">`** : c'est le SEUL des cinq en-têtes de `_headers`
  qui ait un équivalent balise, donc le seul récupérable là où `_headers` est ignoré — GitHub Pages,
  intranet nu. HSTS, `nosniff`, `X-Frame-Options` et `frame-ancestors` n'existent qu'en en-tête HTTP :
  rien à faire côté document, et c'est dit.
- La doc de déploiement sous-estimait la perte sur GitHub Pages : son tableau citait le `no-cache`
  sur `sw.js` mais omettait celui sur `/` et `/index.html`. Or la stratégie « cache d'abord »
  suppose que le rafraîchissement de fond atteigne le SERVEUR : servi depuis un cache
  intermédiaire, il peut réécrire une copie périmée dans le cache hors-ligne. Deux lignes ajoutées
  au tableau, et la conséquence expliquée.

### Documentation — trois affirmations fausses
- « **éditeurs alignés sur leur vue de lecture (fiche ≤ 860 px)** » : mesuré faux — l'éditeur rend
  1fr+320 au-delà de 1200 px. La règle du palier listait bien `body.view-edit`, mais le bloc 1000 la
  reprend **2 293 lignes plus bas** à spécificité ÉGALE (`:is()` prend le max de ses arguments) et
  gagne par l'ORDRE : la règle était MORTE tout en donnant l'illusion d'être appliquée. **4ᵉ incident
  de ce type** après `.read-grid`, `.cbt-n` et `.mode-seg`. Le membre inopérant est RETIRÉ de la
  règle du palier — zéro changement visuel, prouvé à 1400 px — plutôt que réaffirmé plus bas :
  aligner réellement l'éditeur sur 860+360 serait un changement VISIBLE, à décider séparément.
- Le **plan du monofichier** annonçait « ~5 600 lignes » pour 12 250 et décrivait 16 sections sur
  **54**. Il est présenté pour ce qu'il est — un RÉSUMÉ, pas un index — avec la commande `grep` qui
  donne l'index exact et à jour, et le découpage global en lignes. Des numéros de ligne figés dans
  la doc seraient périmés au commit suivant : mieux vaut la commande.
- `AGENTS.md` disait `npm test` sur un seul moteur.

510 tests × 2 moteurs, 22/22 doctrine, 73/73 accessibilité, 135 contrôles d'audit, 9 sondes dédiées.

## [4.33.0] — 2026-07-26
Second lot de l'audit externe : les correctifs dont le RENDU change, volontairement séparés du lot
invisible de v4.32.0. Chacun restaure une doctrine que le code violait, ou rend audible une surface
qui ne l'était pas. Deux découvertes faites en cours de route, hors du relevé initial.

### Corrigé — registres perdus
- **`.pl-stp` : la régression jumelle de v4.25.0.** La purge du Plan « Détails » avait emporté les
  cinq règles de cette classe alors que `ovPlanLadderHtml` l'émet TOUJOURS : pendant six versions,
  une étape **⚠ (memory item)** s'affichait en encre ordinaire dans le détail de « Se repérer »,
  avec les puces disque du navigateur, indiscernable d'une étape banale — dans une surface visible
  en permanence dans le rail dès 780 px et ouvrable d'un tap du quai de crise. Le pendant statique
  (`.sv-stp li.crit`), lui, n'avait jamais cessé d'être peint : deux surfaces de la même app
  donnaient une lecture différente du même contenu vital. Règles restaurées à l'identique de
  v4.24.0 ; vérifié dans les deux thèmes (⚠ = `--critical`, △ = `--verify`, graisse renforcée en
  second canal non chromatique, corps 11,5 px, puces « · »).
- **`.sv-x`** (compteur de passages « ×n » du statique) était émis sans aucune règle. Stylé en encre
  DOUCE et non bleue, contrairement à son jumeau `.pl-x` : dans le statique, « aucun texte bleu dans
  les cellules » — le bleu n'y marque que la position et la reprise. Copier `.pl-x` aurait réparé la
  taille en cassant la doctrine.

### Corrigé — contenu qui sortait de l'écran
- **Cinq `vh` NUS** subsistaient malgré la règle « toute hauteur relative à la fenêtre s'écrit
  `calc(…/var(--zf))` » : le réglage de taille du texte est un `zoom` sur `<html>`, qui agrandit la
  valeur APRÈS sa résolution. Conséquence mesurée à 130 % : dans la visionneuse d'image, 8 px
  d'image et **51 px de légende hors écran**, sans aucun défilement possible — et c'est précisément
  l'utilisateur qui a AGRANDI le texte qui voit mal. Corrigés (visionneuse, schéma, compte-rendu,
  feuille de catégories, sélecteur de documents) ; vérifié à 100 / 115 / 130 %.
- Le harnais qui prétendait couvrir cette règle ne regardait que deux surfaces nommées : il reçoit
  une **sonde générique** qui balaie le CSS résolu de tout élément visible et échoue sur toute
  hauteur bornante dépassant la fenêtre, quel que soit son nom.

### Accessibilité
- **La vue de lecture n'avait AUCUN titre.** Son unique `<h2>` était éteint par `display:none` à
  l'écran (il ne servait qu'à l'impression) — donc absent de l'arbre d'accessibilité — et les sept
  intertitres de section sont des `<div>`/`<span>`. Sur la surface CLINIQUE, il n'y avait donc rien
  à parcourir : il fallait traverser toute la fiche linéairement pour atteindre « Repères
  posologiques ». Le titre passe HORS ÉCRAN (propriétés de `.sr-only`, rien ne change à l'œil) et
  les intertitres reçoivent `role="heading" aria-level="2"` — sémantique sans changer la balise ni
  le CSS. Mesuré : **0 → 25 titres** parcourables, en portrait comme en paysage.
- **`#flowFull` et `.lightbox` : calques OPAQUES plein écran sans sémantique de dialogue.** Ni rôle,
  ni nom, ni déplacement du focus : mesuré, **14 tabulations sur 14 sortaient derrière le calque**,
  atterrissant sur « ⤢ Se repérer » ou des étapes cochables invisibles, en pleine session. C'est
  WCAG 2.4.11, le défaut corrigé en v4.30.0 pour les couches collantes et resté entier pour les
  overlays. Rôle + `aria-modal` + nom, focus déplacé à l'ouverture et RENDU à la fermeture, verrou
  de fond, piège Tab. Ils ne deviennent pas des `.ai-modal` (CSS distinct, et Échap leur est câblé
  nommément — les inscrire dans `_topModal()` aurait cassé leur fermeture, qui cherche un `.ai-x`
  qu'ils n'ont pas) : de nouvelles primitives `_layerEnter`/`_layerLeave` réutilisent les mêmes
  briques. L'image agrandie reçoit enfin un `alt` — sa LÉGENDE : `alt=""` la rendait décorative
  alors qu'elle est le contenu même de la couche. Vérifié : 0 sortie sur 14.
- **`--primary` en couleur de TEXTE** sur trois contrôles (lien d'évitement, pilule du mode lecteur,
  « Pourquoi créer un compte ? ») : 3,44:1 en thème sombre, sous le seuil AA. La règle du projet
  l'énonce déjà — en sombre `--primary` est un REMPLISSAGE, l'accent TEXTE est `--link` (8,24:1).
  Les trois y échappaient parce qu'ils vivent hors du périmètre du harnais.
- **Plancher typographique 11 px** : `.status-tag` (présent sur les cartes d'accueil, les vues de
  lecture et les éditeurs) et `.cx-tag` étaient à 10,5 px. Plus rien sous 11 px dans tout le fichier.
- **Six gabarits sans nom accessible** → 0 contrôle anonyme sur 53 (13 avant) : sélecteur de bloc
  suivant, durée d'un cycle (minutes/secondes), pas et valeur de départ d'un compteur, case
  « boucle », boutons de suppression. Les libellés « min », « s », « pas », « départ » étaient des
  `<span>` VOISINS, jamais associés — un lecteur d'écran annonçait « champ numérique, vide » sur la
  durée d'un cycle de réanimation. Reste 39 champs nommés par leur seul `placeholder` (antipattern
  connu : il disparaît à la saisie) — chantier distinct, consigné.
- **Orientation libérée** (`"any"`, décision utilisateur) : le manifeste verrouillait le portrait, si
  bien que l'app INSTALLÉE refusait le paysage — WCAG 1.3.4, et une tablette fixée au chariot
  d'urgence était inutilisable. Mesuré à 844×390 : aucun débordement, et le rail d'orientation
  APPARAÎT, donnant « action + structure de front » — l'idéal ECAM que le portrait n'atteint pas
  à 390 px.

### Découvert en cours de route (hors relevé initial)
- **Une cible tactile sous le seuil DANS la zone de crise** : `.dock-plan` (« Se repérer » /
  « Consulter ») mesurait **38 px** là où la crise exige 44. Le défaut avait échappé au harnais
  parce que son périmètre listait `#crisisDock` — le quai d'ÉTAT — mais pas `#crisisCtrl`, la rangée
  de COMMANDES qui en a été séparée en v4.25.0 : le trou de couverture cachait un défaut réel sur la
  surface la moins permissive de l'app. Corrigé par **halo** (`inset:-3px 0`) et non par
  grossissement : la hauteur de la zone haute est un coût PERMANENT en crise (177 px sur 640 déjà)
  et passer à 44 px l'aurait épaissie de 6 px ; c'est le patron déjà employé pour les contrôles de
  36 px de la barre. Vérifié à 360/390/1280 : cible 44 px, visuel inchangé, rangée toujours à
  59 px, aucun empiètement sur le quai. `#crisisCtrl` entre dans le périmètre du harnais.
- **GARDE-FOU « une classe émise a une règle »** (`scripts/check-classes.mjs`, dans `npm run check`).
  C'est le contrôle qui manquait pour attraper une purge ASYMÉTRIQUE — celle qui retire du CSS mort
  et, dans le même geste, du CSS vivant. Contre-épreuve faite : retirer les cinq règles `.pl-stp` le
  fait échouer. Il a d'ailleurs trouvé seul le défaut `.sv-x`. Trois exemptions documentées, toutes
  des CROCHETS de délégation JS (`.ov-wrap`, `.ov-journal`, `.seg-ic`). Son premier jet portait le
  faux négatif exact qu'il combat — il extrayait les sélecteurs commentaires COMPRIS, or les
  commentaires citent les classes qu'ils expliquent : noté dans le fichier.

510 tests, 22/22 doctrine, 73/73 accessibilité, 135 contrôles d'audit, 9 sondes dédiées.

## [4.32.0] — 2026-07-26
Premier lot d'un audit externe complet (phase 1 : relevé de 138 constats mesurés, 3 réfutés par
contre-audit ; phase 2 : correctifs à comportement INCHANGÉ). Trois défauts critiques éliminés,
chacun reproduit AVANT correction puis vérifié APRÈS par sonde Playwright — plus une demande
utilisateur : l'intitulé d'une décision reste sous les yeux en mode statique sur téléphone.

### Corrigé — trois chemins vers une page blanche
- **« Réparer l'application » pouvait rendre l'app INDISPONIBLE hors ligne.** Sa sonde réseau
  (`fetch('./sw.js')`) était interceptée par le service worker qu'elle s'apprêtait à détruire :
  `cache:'no-store'` pilote le cache HTTP, PAS le Cache API. Dès qu'un appel avait réussi une fois
  en ligne, `sw.js` était dans le cache stale-while-revalidate ; hors ligne la sonde répondait 200,
  la purge s'exécutait, et le rechargement donnait un écran blanc — en intervention, sans réseau.
  Le commentaire du code énonçait exactement ce risque et croyait s'en prémunir. Deux verrous :
  jeton unique par appel (`?_probe=`+Date.now(), clé de cache inédite) et **le worker refuse
  désormais de se mettre lui-même en cache**. Reproduit hors ligne, serveur arrêté : la sonde
  rejette maintenant avec ET sans jeton.
- **Un échec sur pdf.js supprimait TOUT le hors-ligne, silencieusement.** Le précache de 1,73 Mio
  vivait dans le même `waitUntil` que le noyau ; un 503 ou une coupure faisait rejeter
  l'installation entière (mesuré : `{active:false, controller:false}`, app non servie hors ligne),
  et le `.catch(()=>{})` de l'enregistrement rendait la panne invisible. Précache pdf.js
  best-effort ; `addAll` (tout-ou-rien) réservé à `CORE_ASSETS` = index.html + manifest, les
  10 icônes passant en best-effort — un favicon en 404 ne peut plus emporter l'app avec lui.
- **Le bouton « Recharger » de l'écran d'échec de démarrage était MORT.** Seul attribut `onclick=`
  du fichier, il était inerte : dès qu'un hash figure dans `script-src`, les navigateurs ignorent
  `'unsafe-inline'` et un gestionnaire inline exigerait `'unsafe-hashes'` (absent). C'était le
  dernier recours quand IndexedDB ne répond pas — et en PWA installée, il n'y a ni barre d'adresse
  ni bouton de rechargement. Câblé en DOM (jamais en assouplissant la CSP), avec témoin de
  non-régression : un `onclick` inline reste bloqué, violation CSP journalisée.

### Sécurité
- **`zipParse` : les bornes anti-« zip bomb » annoncées n'existaient qu'à moitié.** Rien ne bornait
  la SOMME des tailles, et N entrées de noms distincts pouvaient pointer sur le MÊME en-tête local
  (PoC exécuté : **18 Ko → 256 Mio**). Un `.zip` est le format de partage d'une bibliothèque : il
  circule par mail ou clé USB, sans contrôle. Trois bornes ajoutées — 256 Mo cumulés, offsets
  locaux dédoublonnés, et `inflateBounded` qui **arrête net la décompression** au-delà de la taille
  déclarée (`usize` est lu DANS le fichier : il peut mentir, et la vérification d'après ne servait
  à rien puisque la mémoire était déjà consommée). **Sept tests** ajoutés : la fonction, qui lit
  des octets étrangers, n'était couverte par aucun.

### Ajouté
- **INTITULÉ DE DÉCISION COLLANT en mode statique sous 640 px** (demande utilisateur, `svStickBands`).
  En pile, la bande-question sortait de l'écran pendant qu'on lisait encore ses étapes : **844 px
  de contenu lus sans elle** sur une décision imbriquée à 360×640, contre **0 px côte à côte** —
  le bornage à ce palier est donc celui du problème, pas un réglage esthétique. La bande s'épingle
  sous `--stick-top`, chaque niveau imbriqué se rangeant SOUS son ancêtre.
  **La hauteur n'est PAS forcée** : compacter à une ligne aurait rendu les décalages arithmétiques
  (donc CSS pur) mais TRONQUÉ toute question de plus de deux lignes — or la question EST
  l'information. D'où une mesure, réduite à UNE passe par rendu en fin de `svPaintArrows`
  (lectures groupées puis écritures, ÷ `zoomF()`), là où l'ex-fil d'ancêtres de la vue « Détails »
  recalculait à chaque événement de défilement. Décrochage NATIF (bornage par `.sv-decwrap`),
  z-ordre décroissant (modèle ECL : un niveau se replie DERRIÈRE son ancêtre), plafond 3 niveaux,
  `scroll-margin-top` pour le focus clavier (WCAG 2.4.11). Six contrôles au harnais de doctrine.
- **Garde-fou de fraîcheur des hashs CSP** (`csp-hashes.mjs --check`, dans `npm run check`) : le
  piège « on édite le script inline, on oublie de rejouer csp-hashes, la CSP bloque le seul script
  de l'app » s'était produit trois fois, dont une pendant cette session. Le même contrôle refuse
  tout attribut `on*=`, ce qui rend le correctif ci-dessus non-régressable. Contre-épreuve faite.
- CI : `npm run check` EN ENTIER (elle n'appelait que son premier maillon — `check-colors.mjs`,
  présenté comme « auto-exécutoire », ne tournait dans AUCUNE barrière automatique), `npm ci` au
  lieu de `npm install` (CI reproductible), cache des navigateurs Playwright, et les **11 harnais
  d'audit** en mode non bloquant — la doctrine était jusqu'ici vérifiée seulement si quelqu'un y
  pensait, mais un échec y demande un arbitrage humain, pas un blocage de merge.

### Supprimé — la purge v4.25.0, achevée
`AGENTS.md` affirmait la suppression du Plan « Détails » faite alors qu'elle l'était à moitié : la
pire configuration, puisque celui qui lit la doctrine croit le terrain propre. Étaient restés
**20 classes CSS mortes** (38 lignes, avec 45 lignes de commentaires décrivant en détail un
composant inexistant) : `.pl-cols`, `.pl-decwrap`, `.pl-nd*`, `.pm-views`, `.ovs-tgl`, `.pinchip`,
`.stuck`, `@keyframes pinIn`, `.pd0…pd3`, `.pl-end`, `.pl-offtag`, `.svgv`, `.diff-anchor`,
`.rail-sep`, `.ov-offtag`, `.ov-block.off` — chacune vérifiée à ZÉRO émission dans tout le dépôt
avant retrait. Plus quatre branches de délégation `data-plfold` inatteignables, deux
`querySelector('.pl-nd[data-plgo]')` qui ne pouvaient que renvoyer `null` (leur repli `||` faisait
croire à deux structures possibles), `ovPlanStick()` vide appelée depuis quatre sites, et la démo
`planDemo` de `design/build.mjs` qui PUBLIAIT le composant disparu — sept de ses classes n'ayant
plus aucune règle, le design system le documentait cassé (réécrite sur l'Échelle, à partir du
balisage réellement émis).
- **Un faux positif du harnais, plus grave que le CSS mort** : `audit-doctrine.mjs` cliquait sur
  `.pl-nd`, classe plus jamais émise — le contrôle passait SANS avoir rien cliqué, si bien que
  l'invariant « taper un nœud du plan ne DÉMARRE ni ne COCHE » n'était plus vérifié depuis v4.25.0.
  Corrigé sur `.pl-line[data-plln]`, avec une assertion qui vérifie que le clic a bien eu lieu :
  un contrôle qui ne peut pas échouer ne prouve rien.
- `.condensed` : le repli d'en-tête au défilement était décrit au présent par trois commentaires,
  renvoi « cf. CSS » compris, et la classe était posée par le JS — mais **la règle n'a jamais
  existé dans tout l'historique du dépôt** (vérifié). Ce n'était donc pas une régression mais une
  intention jamais implémentée : le toggle est retiré (aucun changement visuel possible) et la
  hauteur d'en-tête constante est désormais énoncée pour ce qu'elle est.

### Performance
- **`index.html` était téléchargé DEUX FOIS par publication** : `ASSETS` listait `'./'` ET
  `'./index.html'`, soit le même document sous deux URL que le cache HTTP ne peut pas dédupliquer —
  290 Ko en double, pour une entrée JAMAIS servie (le repli de navigation cherche
  `'./index.html'` d'abord). Entrée retirée : une seule copie en cache au lieu de deux.
- **La synchro reconstruisait tout le DOM après VOS PROPRES modifications.** `_pullTable` comptait
  les lignes REÇUES et non APPLIQUÉES : or `_pushTable` pousse l'horodatage LOCAL et, dans `full()`,
  le pull précède le push — la ligne qu'on vient de pousser revient au pull suivant, n'est pas
  appliquée (horodatages égaux) et déclenchait quand même un `render()` complet, focus perdu et
  journal de plusieurs milliers de nœuds réécrit, en pleine session. Le compteur porte désormais
  sur les écritures effectives (`puts`+`dels`).
- Une réponse que le cache REFUSE d'enregistrer (quota, réponse partielle) devenait un ÉCHEC RÉSEAU
  pour la page : `respondWith` recevait la promesse qui contenait le `put`. Découplé, comme le fait
  déjà la branche de navigation — reproduit avec une réponse 206, qui atteint maintenant la page.

### Documentation
- `AGENTS.md` et `README.md` disaient que la CI rejouait `check` (faux pour sa moitié) et
  annonçaient « deux harnais Playwright » là où il y en a onze. Corrigé, avec la leçon de la purge
  incomplète consignée à l'endroit fautif.
- Six blocs de commentaires décrivaient au présent des symboles inexistants (`ovPlanTreeHtml`,
  `ovPlanPin`, `state.ovPlanView`, `#ovPlanD`, `data-plview`, `--pl-stick`) : un commentaire qui
  décrit un mécanisme absent est pire qu'absent — il envoie le lecteur suivant, humain ou IA,
  chercher ce qui n'existe pas.
- `release.sh` synchronise désormais `package-lock.json` (resté figé à 4.3.0 pendant 28 versions,
  alors que `npm ci` installe d'après ce fichier) — édité comme du JSON, jamais par regex.

510 tests (503 + 7), 22/22 contrôles de doctrine (16 avant), 133 contrôles d'audit, 3 sondes
dédiées (critiques 9/9, service worker 6/6, intitulé collant 8/8).

## [4.31.0] — 2026-07-26
Second lot de l'audit design externe (axes couleurs / hiérarchie / priorisation), décisions
utilisateur.

### Ajouté
- **Garde-fou couleurs auto-exécutoire** (`scripts/check-colors.mjs`, dans `npm run check`) :
  un hex n'est admis dans le CSS que dans une déclaration de token (`--…`), où qu'elle vive
  (`:root`, bloc sombre, blocs d'accent) ; seuls les nuanciers littéraux `.acc-sw` sont
  exemptés. La règle d'AGENTS.md n'est plus déclarative. Le garde-fou a d'ailleurs trouvé PLUS
  que les 4 hex de l'audit : des `#fff` de canevas et deux `stroke:#1f5fa6` — copie hex du
  token primaire, la dérive exacte que la règle proscrit.
- **Raccourci clavier vers la recherche** : « / » et Cmd/Ctrl+K focalisent la recherche de
  l'accueil (inerte dans un champ, sous une fenêtre, ou hors accueil).
- **`prefers-contrast: more`** : texte secondaire à l'encre pleine, filets au gris de composant.

### Modifié
- **Tokenisation complète** : `--shadow-primary(-sm)` (les cinq `rgba(23,71,127,…)` éparses),
  `--hover-dk(-hi)` et `--flow-hl-dk` (ex-hex des overrides sombres), `--lb-cap`/`--lb-ink`
  (lightbox), `--paper` (canevas SVG, pages PDF, impression), `--flow-cur` (nœud courant du
  SVG), `--on-primary` sur les remplissages verts/rouges. Zéro changement visuel (valeurs
  identiques), zéro hex hors token.
- **En session vive, la rangée méta de lecture s'efface** (statut, catégorie, validation —
  vus à l'ouverture, ils ne conduisent rien pendant le soin ; même doctrine que l'état de
  stockage retiré des pieds en crise). Sélecteur `:has(#cbTimers)`, écran seulement, saut
  absorbé par `renderKeepAnchor`.
- **« Non protégé » du pied d'accueil : registre NEUTRE** — un état permanent en ambre s'use
  (banner blindness) et émousse l'ambre des états actionnables (« presque plein », PDF
  manquants), qui le gardent. Le test unitaire encode la nouvelle règle.
- **Guide rouge/ambre de l'éditeur de blocs : `<details>` repliable** — ouvert tant qu'on ne
  l'a pas replié, puis le choix persiste (`ac-cg-folded`).
- **Bouton du mode lecteur : « ⤢ Lecteur »** — le glyphe des ouvertures plein écran (même
  grammaire que Se repérer/Consulter) le fait lire comme une surface. Décision d'audit : pas
  d'entrée dans le chrome de crise (12 px libres à 360 px, et une commande qui apparaît selon
  la largeur romprait la constance positionnelle) — les entrées restent la carte du bout et
  le menu ⋯.

503 tests (dont le test du registre de stockage mis à jour), 11 harnais verts.

## [4.30.0] — 2026-07-26
Correctifs P0/P1/P2 de l'audit design externe (axe « conformité aux normes »).

### Corrigé (P0 — mesurés avant/après)
- **WCAG 2.2 § 2.4.11 « Focus Not Obscured » (AA) : NON-CONFORMITÉ levée.** Un Shift+Tab
  remontant déposait l'élément focalisé ENTIÈREMENT sous les couches collantes (en-tête +
  commandes + quai : 238 px mesurés à 360 px en session — dont la case « Alerter, appeler du
  renfort » et l'étape critique « ⚠ RCP immédiate », masquées à 100 %). Le défilement déclenché
  par le focus clavier est celui du navigateur, que `stickBase()` ne voit pas : seul
  `scroll-padding` le pilote — `html{scroll-padding-top:calc(var(--stick-top,64px)+8px)}`
  (la variable existait déjà, mesurée et divisée par le zoom). Corollaire : le
  `scroll-margin-top:130px` forfaitaire de `.rt-panel` (qui s'ADDITIONNE désormais) est ramené
  à 6 px. Vérifié : 0 masquage après correctif ; sonde 2.4.11 ajoutée à `audit-a11y.mjs`
  (73/73).
- **Rangée de commandes `#crisisCtrl` rognée sur les deux largeurs mobiles les plus répandues.**
  Elle exigeait 386 px : « Cons. » perdait 11 px à 375 (iPhone SE/mini) et 26 px à 360 (Android
  standard), sans défilement horizontal — pixels INACCESSIBLES, débordement silencieux dans la
  zone de crise. Compression mesurée sous 400 px (gaps/paddings, recette v4.23.4) : ~346 px à
  360 après, positions constantes conservées. Sondes « sans rognage » à 360/375/390 ajoutées à
  `audit-doctrine.mjs` (15/15).

### Ajouté (P1)
- **Le retour SYSTÈME (Android, geste/bouton) ne sort plus de l'app en pleine session.**
  History API branchée (0 pushState/popstate jusqu'ici) : une entrée sentinelle ré-armée, le
  popstate empruntant le MÊME chemin que l'affordance visible — fenêtre du dessus (✕ ou clic de
  voile : « Terminer la session ? » ferme sur Poursuivre, jamais Terminer), sinon lecteur,
  schéma plein écran, visionneuse, sinon le « ‹ » d'en-tête (pile readStack + garde double-tap
  700 ms héritées). À l'accueil nu, le retour sort réellement (aucun appui mort) ; une
  sentinelle survivant à un rechargement est neutralisée au boot. Vérifié en scénario réel :
  dialogue fermé sans terminer la session, puis retour à la bibliothèque, puis sortie.

### Ajouté (P2)
- **Filet `forced-colors` (Windows High Contrast)** : `.acct-dot`, `.cat-dot` et `.seg-pill`
  gardent leur couleur (`forced-color-adjust:none`) — le reste s'appuie sur « la couleur jamais
  seule ». Filet minimal, à valider sur machine Windows réelle.
- **Dialogue de bienvenue : « Commencer » ancré en bas de la feuille sur mobile** (zone du
  pouce). Sous 780 px la fenêtre est plein écran : le bouton flottait à mi-écran dans ~700 px
  de vide. Carte en colonne flex, action au bord bas ; ordinateur inchangé.

503 tests, 11 harnais verts (a11y 73/73 avec la sonde 2.4.11, doctrine 15/15 avec les sondes
anti-rognage).

## [4.29.10] — 2026-07-26
### Retiré
- **Dossier « bande basse iOS » clos — correctif v4.29.9 confirmé sur appareil.**
  L'instrumentation temporaire est retirée : ligne de diagnostic de la fenêtre Compte
  (`ih/vv/dvh/sab/sat/scr/vvV/sc/ot`) et règle visuelle (`_vvRuler`, calque rouge + trait bleu
  au toucher). Pour ré-instrumenter un jour : tags v4.29.5 à v4.29.9. Restent en place, acquis
  durables du dossier : le verrou de fond par `overflow:hidden` (jamais de `position:fixed` sur
  `body`), les overlays dimensionnés par `--vvh` (visualViewport, resynchronisée en continu),
  et le fond peint sur `html` (ceinture rebond).

503 tests, 11 harnais verts.

## [4.29.9] — 2026-07-26
### Corrigé (bande basse iOS — LE COUPABLE)
- La règle visuelle (v4.29.8) a produit la preuve : sur l'ACCUEIL, `bottom:0` touche le bord
  physique de l'écran — la WebView est saine ; **fenêtre ouverte, il flotte ~60 px au-dessus**.
  Ce qui change entre les deux états : le verrou de fond passait `body` en
  `position:fixed; top:-scrollY` (v4.21.0). Sur iPhone, un body fixé RÉTRÉCIT le rendu des
  éléments fixés qui en descendent (~60 px coupés en bas) sans qu'aucune mesure web ne le voie
  (`ih/vv/dvh/vvV` disaient tous 874) — et cette bande était MASQUÉE depuis v4.23.3 par le fond
  peint sur `html` (le commentaire de l'époque décrivait déjà « une bande vide en bas à
  l'ouverture de n'importe quelle fenêtre » : il masquait le symptôme, le rétrécissement
  restait). **Le verrou change de technique** : `overflow:hidden` sur `html` et `body` (fiable
  depuis iOS 16), qui bloque le défilement de fond sans toucher au repère des fixés ; position
  restaurée au pixel en ceinture ; même périmètre qu'avant (toucher pour les dialogues, tous
  pointeurs pour les feuilles opaques). Vérifié par sonde : couverture 0→874, fond immobile au
  geste, position restaurée, déverrouillage propre (Chromium et WebKit).
- La bascule de la barre d'état vers `default` (entamée en cours d'investigation) est ANNULÉE :
  l'accueil est parfait en `black-translucent`, la meta n'était pas en cause.
- Diag + règle visuelle CONSERVÉS jusqu'à confirmation sur l'appareil ; retrait prévu ensuite.

503 tests, 11 harnais verts.

## [4.29.8] — 2026-07-26
### Diagnostic (bande basse iOS — instrumentation visuelle)
- Le diag v4.29.7 sur appareil est PARFAIT (`vvV 874px · sc 1.00 · ot 0` — la variable effective
  n'était même pas périmée) et la bande persiste, indépendante du défilement (confirmé
  utilisateur ET par sonde : fond verrouillé après défilement, fenêtre au pixel sur les
  3 moteurs). Toutes les hypothèses mesurables par des NOMBRES sont épuisées : les métriques
  disent « parfait », l'écran dit « coupé ». **Règle visuelle** : toucher la ligne diag dessine
  un calque ROUGE = la boîte que le CSS croit poser de `top:0` à `--vvh` (géométrie des
  overlays, graduée tous les 100 px, bords pleins) et un trait BLEU = là où le CSS croit que
  `bottom:0` se trouve. Une capture d'écran comparera la croyance CSS à la réalité physique :
  bord rouge bas au-dessus du bord d'écran = boîte déplacée/raccourcie au RENDU ; trait bleu
  au-dessus du bord = c'est `bottom:0` lui-même qui ment. Re-toucher retire la règle.

## [4.29.7] — 2026-07-26
### Corrigé (bande basse iOS, suite du dossier)
- Les captures en thème clair montrent DEUX anomalies : la bande basse (~60 px, les trois
  fenêtres) et les feuilles Se repérer/Consulter décalées vers le bas. Or le diag lit 874
  partout… au moment où il se calcule. Suspect principal : **`--vvh` posée au lancement (quand
  iOS annonçait encore 812) et jamais rafraîchie** — iOS corrige la géométrie de la WebView
  SANS émettre `resize` sur `visualViewport`. La variable est désormais resynchronisée sur tous
  les canaux (resize/scroll du visualViewport, resize fenêtre, orientation, retour au premier
  plan) ET à chaque tic d'horloge (~1 s, écriture seulement si la valeur change) : une hauteur
  périmée ne peut plus survivre plus d'une seconde.
- Diag enrichi : `vvV` (valeur EFFECTIVE de `--vvh`, celle que les fenêtres utilisent — si elle
  diverge de `vv`, l'obsolescence est prouvée), `sc` (échelle du viewport visuel — un zoom
  automatique résiduel se verrait ici) et `ot` (décalage vertical du viewport visuel — piste du
  décalage des feuilles). Champ e-mail vérifié à 16 px (pas d'auto-zoom iOS).

503 tests, 11 harnais verts.

## [4.29.6] — 2026-07-26
### Diagnostic (bande basse iOS, suite du dossier)
- Après réinstallation de la PWA, le diag sur appareil est redevenu SAIN : `ih 874 · vv 874 ·
  dvh 874 · sat 62 · scr 874` — la WebView couvre à nouveau l'écran entier (la géométrie était
  bien figée à l'installation, bug iOS `black-translucent`). **Mais une bande résiduelle est
  encore rapportée malgré ces mesures saines** : la cause est donc ailleurs (piste : padding
  bas de sécurité des cartes ? autre fenêtre ? viewport rétréci après clavier non restauré ?).
  La ligne de diag est CONSERVÉE dans la fenêtre Compte tant que le dossier n'est pas clos ;
  une capture de la bande actuelle (fenêtre concernée, thème clair de préférence) est attendue
  pour trancher.

## [4.29.5] — 2026-07-26
### Diagnostic (bande basse iOS, suite)
- Le diag v4.29.4 sur l'appareil tranche : `ih 812 · vv 812 · dvh 812 · scr 874` — les trois
  mesures CONCORDENT. La WebView de la PWA fait réellement 812 px sur un écran de 874 : il
  manque exactement la hauteur de la barre d'état (62 px), **hors de la zone accordée par iOS**
  — aucun contenu web ne peut s'y peindre (la tab bar s'arrête à la même ligne, invisible en
  sombre). Les fenêtres remplissent depuis v4.29.4 100 % de ce qu'iOS accorde ; le reste est un
  problème de coquille PWA (géométrie figée à l'installation ou style de barre d'état), pas de
  CSS. Ajout de `sat` (safe-area haut) au diag pour départager : `sat ≈ 59` = WebView ancrée en
  haut de l'écran et AMPUTÉE en bas (bug iOS `black-translucent`, se corrige souvent en
  réinstallant la PWA) ; `sat = 0` = WebView déjà sous la barre d'état (le style
  `black-translucent` est alors à abandonner).

## [4.29.4] — 2026-07-26
### Corrigé
- **Fenêtres coupées en bas (iOS, suite)** : la capture sur appareil montre que le défaut existe
  aussi en **PWA installée** — sans barre d'outils dynamique, donc `100dvh` (v4.29.3) ne suffit
  pas : cette unité ment sur cet appareil. Les overlays sont désormais dimensionnés par la seule
  source de vérité, **`window.visualViewport.height`** (variable `--vvh`, tenue à jour à chaque
  changement du viewport visuel — barre Safari, clavier, PWA), `100dvh` ne servant plus que de
  repli avant la première mesure. Effet secondaire bienvenu : clavier ouvert, les fenêtres se
  redimensionnent au lieu de passer dessous. Vérifié au pixel sur Chromium et WebKit à
  90/100/130 %.
- **Ligne de diagnostic temporaire** dans la fenêtre Compte (sous « Sur cet appareil ») :
  `ih / vv / dvh / sab / scr` — les quatre mesures de hauteur de l'appareil ; celle qui diverge
  désignera le coupable si la coupure persiste. À retirer une fois le bug clos.

503 tests, 11 harnais verts.

## [4.29.3] — 2026-07-25
### Corrigé
- **iOS Safari/PWA : les fenêtres plein écran n'étaient pas seulement recouvertes d'une bande —
  elles étaient COUPÉES en bas** (retour utilisateur : « le contenu ne scrolle pas sur cette
  bande »). Cause : un overlay `position:fixed; inset:0` se dimensionne sur le *grand* viewport
  iOS (barre d'outils repliée) ; barre visible, le bas de l'overlay passe derrière elle — et
  comme l'overlay est aussi le défileur, la fin du contenu est inatteignable : on peut scroller
  jusqu'au bout, mais le bout vit sous la barre. Correctif : tous les overlays défilables
  (dialogues, feuilles Plan/Consulter, visionneuse PDF, lightbox, mode lecteur, schéma plein
  écran) passent en `height:100dvh` (viewport *dynamique* : la fenêtre s'arrête au bord
  réellement visible et suit la barre), divisé par `--zf` (règle zoom v4.24.0), sous
  `@supports` — les navigateurs sans `dvh` gardent le comportement antérieur. Vérifié au pixel
  sur Chromium et WebKit à 90/100/130 % ; à confirmer sur l'appareil.

503 tests, 11 harnais verts.

## [4.29.2] — 2026-07-25
### Corrigé
- **Le ✕ de la carte-bilan de fin de session est ancré en haut à droite** (retour utilisateur) :
  sur petit écran, la carte passe en plusieurs lignes et le ✕ « dans le flux » (contournement
  v4.23.2) atterrissait au milieu, collé au bouton « Compte-rendu ». Rétabli proprement : carte
  `position:relative`, ✕ ancré `top/right`, place réservée par le padding — vérifié à 320/360/390
  et couvert par le harnais (contrôle « coin haut-droit » à 360 px).
- **Piste bande vide en bas (iOS Safari/PWA)** : les dialogues plein écran (< 780 px) avaient un
  conteneur au fond `--bg` sous une carte `--surface` — le rebond de défilement iOS révélait ce
  fond au-delà de la carte (bande étrangère en bas, invisible sur Chromium où le rebond n'existe
  pas). Le conteneur prend le fond de la carte. **À confirmer sur appareil** : si la bande
  persiste, une capture d'écran (quelle vue, quelle fenêtre ouverte) permettra de viser juste.

### Modifié
- **« Répéter en exercice » est grisé pendant une session réelle** (sous-titre « session en
  cours » — même patron que « Modifier ») : modèle *inhibit* ECAM, on ne propose pas
  l'entraînement pendant un soin. La rangée reste active pendant un exercice (la recommencer
  est justement son usage) ; la confirmation danger « Terminer et exercer » reste dans le code
  en garde-fou, mais n'a plus de chemin d'accès accidentel.

503 tests, 11 harnais verts.

## [4.29.1] — 2026-07-25
### Corrigé
- **L'entrée et la sortie du mode exercice ne sautent plus** (retour utilisateur) : la hachure
  vit désormais sur un `::before` en **fondu d'opacité** (~300 ms) — l'apparition, le retrait,
  **et le passage bandeau → en-tête au défilement** sont fondus au lieu d'un aplat instantané ;
  le fondu est neutralisé sous `prefers-reduced-motion`. Et le **saut de hauteur** est éliminé :
  à ≥ 780 px le bouton « Quitter l'exercice… » épaississait le bandeau de 12 px (bouton 36 px
  dans un bandeau de 44) — compacté à ce palier, halo conservant la cible de 44 px. Δ mesuré à
  **0 px** sur 360/390/430/780.

503 tests, 11 harnais verts (les sondes lisent la hachure sur le `::before`).

## [4.29.0] — 2026-07-25
Cinq retours utilisateur : le placard exercice suit le titre, le sélecteur ne bouge plus d'un
pixel, la pastille se glisse au doigt, trois micro-animations, et la méta de lecture se désencombre.

### Modifié
- **Le placard exercice SUIT LE TITRE** (retour utilisateur : hachurer le quai était illisible —
  annulé) : tant que le bandeau-titre est visible, lui seul porte la hachure ; au pixel où il
  passe sous la barre, c'est **l'en-tête** qui la prend — même mécanique de relais que la pilule
  « ▲ Exercice ». Le quai redevient une zone d'état propre : des chiffres n'ont pas à vivre sur
  une texture. Vérifié en capture dans les deux thèmes.
- **Guidé/Statique : les libellés ne bougent plus d'un pixel** à la bascule — la graisse passait
  de 700 à 800 sur le segment actif, ce qui élargissait le mot et décalait les deux libellés.
  Graisse constante partout (tab bar comprise, qui passait de 600 à 800) : l'état est porté par
  la pastille et la couleur. Mesuré à 0 px par le harnais.
- **La méta de lecture perd la pastille « ▲ Exercice : date »** (retour utilisateur : elle
  captait l'œil à côté de la date de validation pour une information non clinique) — la date du
  dernier exercice vit désormais en sous-titre de « Répéter en exercice » au menu ⋯
  (« dernier : ‹date› », sinon « aucune trace clinique ») et dans l'historique scindé.

### Ajouté
- **Glisser la pastille au doigt** (HIG iOS) sur les trois sélecteurs segmentés — Guidé/Statique,
  la tab bar Aides/Protocoles de l'accueil et le dialogue Créer (aucun n'est une vraie tab bar
  iOS : le geste y fait sens partout). Engagement au relâchement seulement (≥ moitié du trajet —
  rien de lourd ne se re-rend pendant le geste), un tap reste un tap (seuil 6 px), un drag
  n'émet jamais le clic du bouton sous le doigt.
- **Micro-animations non bloquantes** (transform/opacité/fond seulement, l'app reste utilisable
  pendant l'effet, inertes sous `prefers-reduced-motion`) : entrée/sortie du mode exercice
  (glissement de la hachure + pop de la pilule), retour par la pile d'origine (la vue entre dans
  le sens du geste), reprise après complication (la carte de reprise glisse en place).

`audit-modeseg` mesure désormais l'immobilité des libellés et rejoue un drag réel ;
`audit-exercice` vérifie le placard suiveur (en-tête hachuré au défilement, quai propre).
503 tests, 11 harnais verts.

## [4.28.0] — 2026-07-25
Quatre retours utilisateur d'un coup : pile de retour, mode lecteur enrichi, placard exercice
visible partout + bouton Quitter, menu ⋯ réordonné.

### Ajouté
- **Pile de retour fiche → fiche** : ouvrir une autre aide depuis une fiche (« Voir aussi »,
  complication externe, feuille Consulter) mémorise l'origine — le « ‹ » d'en-tête porte le
  **titre de la fiche d'origine** et y ramène ; il ne dit « Bibliothèque » que quand la pile est
  vide (AC 120-71B : le retour d'une interruption est prévu par le dispositif, pas laissé à la
  mémoire — les bandeaux de l'accueil restent la redondance, mais ils n'existent que si une
  session a démarré). **Garde anti double-tap 700 ms** (même mécanique que le retour d'aperçu) :
  deux taps nerveux ne traversent jamais deux niveaux.
- **Mode lecteur enrichi** (audit : le « un item à la fois » n'est pas le modèle aviation — l'ECL
  Boeing montre la liste entière avec un curseur, et le binôme soignant anticipe) :
  **bande minuteurs propre** — l'overlay couvrait le quai, or l'état ne disparaît jamais : tous
  les minuteurs, échus d'abord en ambre avec le mot « échu », sans « +n » (la bande passe à la
  ligne) ; **carte des blocs** (pastilles ✓/●/○ du rail, même `minimapData`) + **contexte local**
  (item précédent avec ✓, « suivant : … ») autour du challenge courant qui reste seul en 26 px ;
  **⚡ Complication(s)** accessible sans quitter le lecteur — l'index passe au-dessus de
  l'overlay, le lecteur reste ouvert pendant l'excursion (doctrine QRH : on change de checklist,
  pas de support) et la fin d'un bloc d'excursion propose « ↩ Reprendre », jamais « Terminer ».
- **« Quitter l'exercice… »** directement sur le placard hachuré ; le dialogue de fin est titré
  « Terminer l'exercice ? » (une action dit sa portée).

### Modifié
- **Placard exercice visible partout et dans les deux thèmes** (retour utilisateur) : les
  hachures alternent désormais surface/`--primary-soft` (le couple surface/surface-2 était quasi
  invisible en sombre — delta mesuré par le harnais dans les deux thèmes), et le **quai collant
  est hachuré aussi** : l'annonciation TRAINING ne quitte plus l'écran au défilement ; le relais
  d'en-tête devient la même pilule bleu pointillé.
- **Menu ⋯ réordonné** (retour utilisateur) : conduite en cours d'abord (⚡, Lecteur, Se repérer,
  Schéma, Consulter), puis cycle de vie de session (Exercice, Recommencer, Historique), puis
  gestion (Modifier, Versions, Dupliquer), puis exports ; Terminer… ferme toujours la liste.
  Avant, Modifier/Versions — désactivées en session — trônaient en tête : deux rangées mortes au
  moment où le menu sert le plus. `setMoreMenu` normalise les séparateurs (un groupe vide
  disparaît). **Icônes désambiguïsées** : « Historique des sessions » reçoit une boîte d'archives
  (elle partageait l'horloge-flèche de « Versions » — deux entrées, même dessin) et
  « Se repérer » reçoit un rail à lignes indentées, l'Échelle elle-même (l'ex-icône « plan »,
  quasi identique au « flow » du Schéma juste en dessous, est supprimée).

Nouveau harnais `scripts/audit-lecteur.mjs` (13 contrôles) ; `audit-exercice.mjs` passe à
20 contrôles (placard collant, delta des hachures par thème, bouton Quitter). 503 tests,
11 harnais verts.

## [4.27.1] — 2026-07-25
### Modifié
- **L'« Aperçu en direct » des éditeurs (colonne droite ≥ 1000 px) rattrape trois versions de
  retard** : la miniature rendait encore la grammaire d'avant v4.23.0 — numéros `01/02` devant les
  étapes (supprimés du rendu réel), chaque étape en boîte bordée (le réel est « normal = ligne,
  signalé = boîte »), case à cocher à droite (elle est à gauche), bandeau teinté rouge (le bandeau
  réel est blanc depuis v4.23.0 : jamais d'aplat rouge permanent). Une miniature qui montre
  l'ancienne grammaire apprend le mauvais rendu à l'auteur pendant qu'il rédige. Elle suit
  désormais le rendu réel : lignes à filet, boîtes teintées avec glyphe ⚠/△ en tête, pilule de
  réponse « challenge :: réponse », et la rangée « ⚡ Complication(s) » apparaît dès qu'une
  complication est déclarée. (L'aperçu PLEIN ÉCRAN, lui, passe par le vrai moteur de rendu et
  n'a jamais dérivé — seule la miniature était figée.)

Vérifié par sonde : glyphes, pilule, ligne plate, case à gauche, bandeau blanc, rangée ⚡.
503 tests, 10 harnais verts.

## [4.27.0] — 2026-07-25
Mode exercice — le second manque identifié par l'audit doctrinal (piliers EMIC : après « utiliser »
et « débriefer », voici « s'entraîner ») — et compte-rendu enrichi pour TOUTES les sessions.

### Ajouté
- **« Répéter en exercice » (menu ⋯)** : rejoue la fiche dans l'écran RÉEL, à l'identique — même
  journal, mêmes minuteurs, mêmes gestes. C'est un choix doctrinal, pas une facilité : Greig 2023
  montre que le transfert de l'entraînement exige la **fidélité de format** — un mode « simplifié »
  entraînerait au mauvais outil. Seule l'**annonciation** change, sur le modèle du placard TRAINING
  aviation : bandeau de titre **hachuré** + pilule « ▲ Exercice » en bleu pointillé (ni rouge ni
  ambre : un exercice n'est pas une alerte), et le chrono d'état dit « ▲ Exercice » — le
  « ● Session » **vert reste réservé au réel**. Démarrer un exercice par-dessus une session réelle
  vive exige une confirmation au registre danger (« Terminer et exercer »).
- **Zéro contamination clinique** : la session d'exercice est marquée `exercise` (les sessions
  vivent en local seulement — jamais dans l'export v3, jamais synchronisées : le drapeau est sûr) ;
  l'historique **sépare** « Sessions cliniques (n) » et « Exercices (n) », badge « ▲ EXERCICE » sur
  chaque rangée ; carte-bilan « **Exercice terminé** » au registre exercice ; compte-rendu
  **filigrané « EXERCICE »** avec la mention « répétition sans patient ». « Terminer » dit sa
  portée : « Terminer l'exercice… » vs « Terminer la session… » (AC 120-71B : une action dit
  exactement ce qu'elle fait).
- **Méta de fiche : « ▲ Exercice : ‹date› »** — seulement quand un exercice existe. **Aucun rappel
  « jamais répétée », aucune relance** (décision utilisateur : pas de nudge) ; le harnais vérifie
  l'ABSENCE de ce texte dans le DOM rendu.
- **Compte-rendu enrichi pour toutes les sessions, réelles comprises** (support du débrief) :
  section « ⚡ Complications » — chaque excursion horodatée (l'heure d'entrée est désormais
  mémorisée : `cxBack[seq]={id,t}`, les sessions v4.26.x en format chaîne sont normalisées à la
  lecture) — et section « Vérification (do-verify) » : n étapes constatées ✓✓ + chaque
  « △ écart » horodaté avec le texte de l'étape.
- Harnais `scripts/audit-exercice.mjs` (16 contrôles, dans `npm run audit`) — dont « la session
  réelle est INCHANGÉE » et un contrôle d'absence de nudge. Piège consigné : le `<script>` inline
  est un enfant de `body`, donc `document.body.textContent` remonte les commentaires du code —
  borner ce genre de sonde à `main`.

503 tests, 10 harnais verts.

## [4.26.1] — 2026-07-25
Deux retours d'usage sur les complications, tous deux retenus.

### Modifié
- **Un seul déclencheur constant, « ⚡ Complication(s) (n) », qui ouvre un index par événement** —
  au lieu d'un bouton par complication. C'est le retour utilisateur, et il est plus doctrinal que
  la version initiale : le QRH est **un** objet à index par onglets, le manuel de Stanford **un**
  manuel à onglets d'événements — on ne met pas un bouton de cockpit par urgence. L'appel
  automatique de l'ECAM ne vaut que pour les pannes *captées*, ce que l'application ne fait pas ;
  l'analogue honnête est donc l'index. Bonus : mot et position constants quelle que soit la fiche
  (plusieurs boutons rouges qui se ressemblent obligeraient à lire chacun sous stress), et l'écran
  d'action se désencombre. Coût assumé : un tap de plus, payé en grandes rangées dans l'index
  (événement + « interrompt le parcours — retour prévu » ou « ouvre : ‹aide› ↗ »).
  - Le menu ⋯ porte la même entrée unique « Complications (n) ».
  - **Le déclencheur vit désormais aussi sur un bloc de décision courant** (limite de la 4.26.0,
    levée).
- **Éditeur : la cible s'ouvre dans le sélecteur filtrable partagé** (même patron que « Voir
  aussi » et « Joindre un document ») au lieu d'un menu déroulant — la liste des aides peut être
  très longue. Deux groupes : **blocs de cette fiche** d'abord, puis **aides & protocoles** ;
  contrairement à « Voir aussi », une aide déjà liée reste sélectionnable.

### Interne
- Harnais `audit-complications.mjs` réécrit pour le nouveau flux : 20 contrôles, dont l'index
  (ouverture, contenu, Échap), le bloc de décision courant et le sélecteur d'éditeur.

---

Les versions **antérieures à 4.26.1** (jusqu'à 4.26.0 incluse) sont dans
[`CHANGELOG-archive.md`](CHANGELOG-archive.md), déplacées **telles quelles** — aucune ligne
réécrite ni perdue.

> **Règle d'archivage** : ce fichier garde les **20 dernières versions**. Au-delà, déplacer les plus
> anciennes dans l'archive au moment de la publication. Elle n'avait été appliquée qu'une fois en
> 112 entrées, et ce fichier pesait alors 221 Ko — la moitié de toute la documentation du projet.
