# Doctrine JS — les commentaires longs du monofichier, repris à l'octet (v5.20.6, A293)

> Le pendant JS de [doctrine-css.md](doctrine-css.md) (A292), même méthode que le déménagement
> v5.10.3 : les blocs de commentaires de PLUS de dix lignes du grand script d'index.html sont
> repris ici À L'OCTET, chacun sous un id stable **J`n`** — le commentaire en place est resserré
> à la contrainte que le code ne peut pas dire, avec le renvoi « doctrine-js.md J`n` ». RIEN
> n'est réécrit ; l'ordre suit le script ; le grand commentaire d'architecture en tête du fichier
> et les blocs de dix lignes ou moins restent en place, tels quels.

## J1 — Palette de catégories (index réutilisé cycliquement) : chaque teinte respecte WCAG AA

```
// Palette de catégories (index réutilisé cycliquement) : chaque teinte respecte WCAG AA
// (contraste >= 4.5:1) en pastille (texte coloré sur fond teinté à 15 %) comme en chip
// sélectionnée (texte blanc). Le vermillon #b23240 (ex-#b6382f, re-résolution OKLCH v5.1.1 :
// écarté du rouge d'alerte --critical-bd, dont il n'était qu'à dE_OK 3,1) est assumé pour les
// catégories d'urgence — les STATUTS, eux, sont achromatiques depuis V5.
// Pas de bleu --primary (#1f5fa6) : une catégorie sélectionnée ressemblerait à un bouton
// d'action primaire ; l'ex-teal de la marque (#0d5b56) reprend cette place, désormais libre.
// RE-RÉSOLUTION PERCEPTUELLE (action 7 rouverte en OKLCH, v5.1.1) : SIX teintes déplacées, à
// problème NOMMÉ chacune — 0 (collision --critical-bd, dE_OK 3,1), 2 (collision --verify, 3,0 :
// l'olive se lisait comme le registre ambre), 4 (collision --ok, 3,3), 5 et 6 (paire confusable,
// 5,1 entre elles), 9 (contraste sombre 2,37 -> 3,10). Déplacements MINUSCULES (dE_OK 1,3 à 2,8,
// sauf l'indigo 9 à 6,2 pour son contraste) : une catégorie déjà choisie reste reconnaissable, et
// le caractère sourd de la palette est conservé (chroma quasi inchangée). CONTRAINTES = CELLES DU
// TEST DE RÉGRESSION #3 (tests.html), pas « sur blanc » : texte couleur sur teinte 15 % >= 4.5 ET
// blanc sur couleur pleine >= 4.5 — un premier jet contraint « sur blanc » a produit trois teintes
// que la suite refusait (3,74-3,95) ; le solveur applique donc tint15/chip à l'identique.
// Plancher des distances (paires + registres) : 3,0 -> 4,0. Les couleurs DÉJÀ STOCKÉES ne
// changent pas (la couleur vit dans la catégorie) : seuls les nouveaux choix voient la palette.
// TROIS teintes restent < 3:1 sur surface sombre (#45556b, #0d5b56, #7a2f6b) : aucun candidat
// conforme n'existe dans le budget de reconnaissabilité (vérifié au solveur, pas supposé) —
// atténué par la règle « la couleur n'est jamais seule » (le nom est toujours en toutes lettres).
```

## J2 — Backends (stockage LOCAL)

```
/* ===== Backends (stockage LOCAL) =====
   Trois implémentations interchangeables exposant la MÊME interface.
   `Data` (plus bas) pointera vers celle retenue par chooseBackend().
   - MEM : repli mémoire (perdu au rechargement).
   - KV  : clé-valeur sérialisé en JSON (window.storage de l'hôte, sinon
           localStorage, sinon MEM). Clés : fiches_v1 / cats_v1 / sessions_v1 / backups_v1.
   - IDB : IndexedDB 'ac-db' v5, stores 'fiches'(keyPath id), 'meta'
           (catégories sous la clé 'categories'), 'sessions'(keyPath id),
           'backups'(keyPath bid, index byFiche), 'attachments'(keyPath id,
           ArrayBuffer des PDF) et 'protocols'(keyPath id).
   Méthodes communes : getAll/put/del, getCats/setCats,
   getSessions/putSession/delSession, getBackups/putBackup/delBackup. */
```

## J3 — ESPACES LOCAUX PAR COMPTE (multi-profils)

```
/* ===== ESPACES LOCAUX PAR COMPTE (multi-profils) =====
   Chaque compte a SES données locales (fiches, notes, sessions, épingles, catégories, curseur
   de synchro) : changer de compte ne mélange JAMAIS deux bibliothèques, et revenir à un compte
   retrouve instantanément son cache local. Principes :
   - L'espace SUIT LE DERNIER COMPTE CONNECTÉ ('ac-space', collant) : une déconnexion — même
     forcée par un jeton révoqué en pleine session — ne change RIEN à l'affichage (promesse
     hors-ligne intacte). L'espace ne bascule que par un location.reload() (bascule atomique
     de tout l'état en mémoire) : à la CONNEXION d'un AUTRE compte, ou par le retour EXPLICITE
     vers l'espace sans compte depuis l'écran de connexion (switchToAnonSpace). MULTI-ONGLETS :
     ce reload ne se produit QUE dans l'onglet qui se connecte ; un autre onglet resté ouvert
     est averti via l'évènement 'storage' sur 'ac-space' et se recharge à son tour (cf. plus bas).
   - UNE base IndexedDB PAR espace : la base historique 'ac-db' est ATTRIBUÉE (sans copie) au
     premier espace qui la réclame ('ac-db-owner') ; les autres espaces utilisent 'ac-db-<uid>'.
     Même logique pour les clés localStorage par espace (spaceKey) et le repli KV (kvName).
   - Transition « sans compte -> compte » : les fiches locales sont PROPOSÉES au déménagement
     (déplacement, pas copie : un id ne peut être adopté que par un seul compte, la clé primaire
     cloud est globale). Entre deux comptes : jamais de transfert (export/import si besoin).
   - RETOUR « compte -> sans compte » (returnLocalDataToAnon) : uniquement pour un compte NON
     APPROUVÉ (pending/rejected) jamais synchronisé depuis cet appareil (canReturnToAnon) — ses
     ids n'ont jamais été réclamés dans le cloud, le retour puis une adoption ultérieure par un
     autre compte sont donc sans risque de collision de clé primaire. Évite qu'un refus de
     compte (ou une erreur d'e-mail) n'échoue les fiches dans un espace devenu inaccessible. */
```

## J4 — State & Runtime

```
/* ===== State & Runtime =====
   `fiches` `categories` `sessions` : copies en mémoire des données persistées.
   `state` : ce qui doit être AFFICHÉ.
     view      = 'library' | 'edit' | 'read'
     q, cat    = recherche texte et filtre catégorie (bibliothèque)
     draft     = brouillon en cours d'édition (copie profonde de la fiche)
     fiche     = fiche affichée en lecture
     nav       = pile des blocs visités (fil d'Ariane / parcours guidé)
     checked   = { 'seqVisite:idBloc:index': true } étapes cochées (partagé avec Runtime)
     showFlow  = panneau « aperçu de l'algorithme » déplié
     (showSess a été SUPPRIMÉ en v4.44.0 : écrit deux fois, jamais lu — l'historique des
      sessions vit dans sa propre fenêtre #sessModal depuis longtemps)
   `Runtime` : état VIVANT d'une fiche utilisée en mode crise. Persiste tant
     qu'on reste sur la même fiche (ficheId), pour ne pas perdre des minuteurs
     en cours en revenant à la bibliothèque. Contient les minuteurs (avec leur
     horodatage de démarrage) et les compteurs. state.checked/state.nav pointent
     vers Runtime.checked/Runtime.nav (même référence) -> cocher = modifier la session vive.
   `AC` : AudioContext (créé paresseusement, voir ensureAudio/beep).
   Helpers : uid (id unique), esc (échappe le HTML), clean (vide les lignes vides),
     catTag (pastille couleur d'une catégorie), fmtMs (millisecondes -> mm:ss). */
```

## J5 — Cycle de vie du Runtime — quatre verbes, quatre rôles :

```
/* Cycle de vie du Runtime — quatre verbes, quatre rôles :
   makeRuntime()  = objet VIERGE (aucune fiche liée) ;
   buildRuntime() = objet CONSTRUIT depuis une fiche (+ session reprise éventuelle), sans le poser ;
   freshRuntime() = build + POSE comme Runtime courant + relie state.checked/state.nav dessus ;
   resetRuntime() = repose un objet vierge (invalidation après édition de la fiche). */
/* VÉRIFICATION (Do-Verify, v4.23.0) — `verified` et `vgaps` sont VOLONTAIREMENT distincts de
   `checked`. Avant, « Constaté ✓ » écrivait la MÊME clé que le cochage courant et les écarts
   étaient jetés à la sortie : une étape cochée pendant l'exécution devenait indiscernable d'une
   étape CONSTATÉE par observation, et un « △ Écart » d'une étape jamais atteinte. Or c'est
   exactement la distinction que la seconde passe existe pour produire (AC 120-71B : en do-verify,
   la réponse doit venir de l'état CONSTATÉ, pas du souvenir d'avoir fait le geste) — la conflater
   en un seul bit détruit le résultat de la vérification.
   Portée : STOCKÉ DANS LA SESSION uniquement (stores `sessions`) — l'export v3 des FICHES et le
   format des clés (`seq:blocId:index`) restent strictement inchangés ; un client antérieur ignore
   simplement ces deux champs. */
/* `counters`/`timers` sont indexés par des IDS DE FICHE (donnée importable) : sans prototype,
   un id `toString` ne peut plus matcher un héritage d'Object.prototype dans les gardes `in`
   (v5.10.2, audit sécurité — cosmétique, les ids passent déjà par safeId, mais l'invariant
   devient local au lieu de dépendre du reste de la chaîne). */
```

## J6 — ══ L'ÉCRAN NE S'ÉTEINT PAS PENDANT UNE SESSION (v5.6, planche 11k)

```
/* ══ L'ÉCRAN NE S'ÉTEINT PAS PENDANT UNE SESSION (v5.6, planche 11k) ═══════════════════════════
   Aucune occurrence de `wakeLock` dans le fichier : pendant une réanimation de vingt minutes,
   l'écran s'éteint seul et le geste suivant commence par réveiller un téléphone — l'outil se
   retire pendant qu'on s'en sert. C'est un défaut d'intuitif au sens le plus littéral.
   QUATRE RÈGLES LE RENDENT NON INVASIF, et ce sont elles qui décident du code :
   1. DEMANDÉ SEULEMENT PENDANT UNE SESSION VIVE — relâché à la fin et au masquage, REDEMANDÉ au
      retour au premier plan (le verrou est perdu à chaque masquage, notamment sur iOS).
      ⚠ Et redemandé UNE FOIS, sur l'évènement : un verrou redemandé en boucle est un bogue de
      consommation, ce que la planche demande justement de ne pas écrire.
   2. AUCUNE FENÊTRE, AUCUNE PERMISSION. L'API n'en demande pas ; là où elle manque, il ne se passe
      rien et la ligne ne s'affiche pas — DÉGRADATION SILENCIEUSE, jamais un message qui explique
      une absence. Une demande refusée (batterie faible : le navigateur peut refuser) ne dit rien
      non plus : elle laisse l'interrupteur sur « laissé au système ».
   3. UNE LIGNE, DANS LE VOLET, SUR GESTE : elle n'apparaît pas d'elle-même sur la surface de soin.
   4. ELLE SE COUPE COMME LE SON SE COUPE — batterie faible, transport long, tablette partagée :
      c'est un réglage, donc il a un interrupteur, et l'état est VISIBLE plutôt que deviné.
   Le choix est PERSISTÉ par utilisateur (comme le thème et le son) : le rallumer à chaque session
   serait un réglage qu'on ne peut pas régler. */
/* ⚠ ON TESTE LA CAPACITÉ, PAS LA PRÉSENCE DE LA CLÉ : `'wakeLock' in navigator` est VRAI même
   quand la propriété vaut `undefined` (un navigateur peut la déclarer sans l'implémenter, et un
   harnais qui la neutralise la laisse en place). Sans cela la ligne s'afficherait là où rien ne
   peut se produire — l'inverse de la dégradation silencieuse. */
```

## J7 — esc/clean COERCENT toujours en chaîne -> jamais d'exception si une donnée importée n'est pas une

```
// esc/clean COERCENT toujours en chaîne -> jamais d'exception si une donnée importée n'est pas une
// chaîne (sinon `(obj).replace` lèverait et casserait tout le rendu = écran blanc).
/* L'APOSTROPHE ET LE BACKTICK SONT ÉCHAPPÉS AUSSI (v4.44.0). La doctrine fait de `esc()` « la
   SEULE barrière anti-XSS » (la CSP monofichier impose `style-src 'unsafe-inline'`) : une barrière
   qui laisse passer `'` n'est pas une barrière, c'est une barrière conditionnée à un invariant
   que personne ne vérifie — « aucun attribut n'est jamais délimité par une apostrophe ». Cet
   invariant est vrai aujourd'hui (mesuré : 0 occurrence de `='${`) et le restera jusqu'au jour où
   quelqu'un écrira un attribut à l'apostrophe sans savoir que la sûreté de tout le fichier en
   dépendait.
   LE BACKTICK, LUI, N'EST PAS ÉCHAPPÉ — et c'est une décision, pas un oubli. Il a été ajouté puis
   RETIRÉ : trois tests du mini-Markdown tombent aussitôt (« code en ligne », « balisage non
   interprété dans le code en ligne », « pas de surlignage dans du code »). La raison est
   structurelle : `mdInline` échappe D'ABORD puis reconnaît la syntaxe, donc un backtick devenu
   `&#96;` n'est plus reconnu comme délimiteur de code. Et le backtick n'est pas un métacaractère
   HTML : dans le contexte où va la sortie d'`esc()` — du texte et des attributs à guillemets — il
   n'ouvre aucune brèche. L'échapper coûtait une fonctionnalité documentée pour zéro sûreté.
   INNOCUITÉ VÉRIFIÉE avant d'écrire : 278 sites d'appel, dont 0 `textContent`, 0 `setAttribute`
   et 0 comparaison de chaîne — la sortie de `esc()` ne va QUE dans du HTML, où `&#39;` est
   re-décodé en `'` par l'analyseur. Un titre français en contient presque toujours un
   (« fiches d'exemple ») : le contrôle qui compte est qu'AUCUN `&#39;` ne remonte à l'écran, et
   il est joué sur les deux moteurs. Entité numérique et non `&apos;` : universellement comprise,
   y compris par un analyseur HTML4. */
```

## J8 — Mini-Markdown (protocoles rédigés)

```
/* ===== Mini-Markdown (protocoles rédigés) =====
   Parseur MAISON volontairement minimal (zéro dépendance), XSS-safe par construction :
   mdInline fait TOUJOURS esc() d'abord, puis pose le balisage sur le texte déjà échappé.
   Syntaxe : # / ## / ### titres, - liste, 1. liste numérotée (sous-liste : 2 espaces
   d'indentation, UN niveau), > citation, `code` en ligne, ``` bloc de code, --- séparateur,
   **gras**, *italique*, [texte](https://…) lien externe, [texte](att:ID) ouvre un document PDF
   joint, ![légende](img:ID) image (référence à l'entrée p.images correspondante — data URL déjà
   validée par safeImg dans migrateProtocol), TABLEAUX (v4.4.2) : lignes « | a | b | » avec
   une 2e ligne de séparation « |---|:-:|---:| » qui porte l'alignement (défaut / centré / droite),
   et LISTES COCHABLES (v4.5.4) : « - [ ] tâche » / « - [x] cochée » (syntaxe GFM, aussi en liste
   numérotée « 1. [ ] ») — coches ÉPHÉMÈRES par ouverture (state.protoTasks, cf. bindProtoTasks),
   jamais écrites dans le body : export v3 strictement inchangé.
   Balisage non reconnu laissé VISIBLE tel quel (même philosophie que fmt : la coquille se voit
   en relecture, le rendu ne casse jamais) — un ancien client affiche donc un tableau comme des
   lignes de texte à pipes : dégradation lisible, export v3 inchangé (body reste une chaîne).
   Fonctions PURES (testées via ?__actest). Plafonds anti-DoS : 20 000 caractères / 2 000 lignes. */
```

## J9 — A171 — LES TITRES D'UNE RÉFÉRENCE SE REPLIENT

```
/* ═══ A171 — LES TITRES D'UNE RÉFÉRENCE SE REPLIENT ═══════════════════════════════════════════
   Demande de l'auteur : « vue protocoles : titres H1 H2 H3 repliables en mode lecture ». Une
   référence se CONSULTE — on y vient chercher UNE section (c'est déjà la raison d'être du
   sommaire M5) — et sur un document de plusieurs milliers de pixels, replier ce qu'on a lu ou ce
   qui ne concerne pas le patient devant soi remplace dix défilements par un tap.
   ⚠ CONSTRUIT APRÈS LE RENDU, JAMAIS DANS `mdRender` : le parseur reste PUR et NON interactif —
   c'est la règle du dépôt (les aperçus sont inertes) et celle que le sommaire M5 suit déjà. Un
   dépliant posé au parsing voyagerait dans TOUT rendu markdown, y compris le compte rendu PDF.
   ⚠ ET LE TITRE RESTE UN TITRE : on n'écrit pas `role="button"` sur un `<h2>` (cela lui retirerait
   sa sémantique de titre, donc la navigation par titres des lecteurs d'écran, au moment précis où
   l'on ajoute une raison de s'en servir). Le bouton vit DANS le titre et n'enveloppe que son
   texte ; l'ancre du sommaire (`h.id`) reste sur le titre lui-même.
   ⚠ REPLIS MÉMORISÉS PAR PROTOCOLE (décision de l'auteur) — mais dans une préférence LOCALE, pas
   dans la donnée : un repli est une commodité de lecture, il n'a rien à faire dans un document
   qu'on partage, qu'on exporte et qu'on synchronise (les coches d'un protocole, elles, restent
   ÉPHÉMÈRES : ce sont deux choses différentes, et la seconde vaut décision clinique).
   ⚠ ET LA CLÉ EST LE TITRE, PAS SON RANG : les index de document se décalent dès qu'on insère une
   section, et l'on retrouverait « replié » sur une autre. Le slug du texte survit à l'édition
   d'ailleurs dans le document. */
```

## J10 — v5.4.1 — OPTION A DU CHROME COCKPIT (décision utilisateur sur maquette : « tout voir, consulter

```
/* v5.4.1 — OPTION A DU CHROME COCKPIT (décision utilisateur sur maquette : « tout voir, consulter
   et chrono se mettent tout à gauche, mais la bande reste : du contenu du centre perdu »). À
   ≥ 1200 px en lecture de fiche, les DEUX rangées de crise quittent la bande pleine largeur et
   rejoignent le créneau statique de l'en-tête (#hdrCrisisSlot) : le contenu commence tout en haut
   (~110 px rendus sur toute la largeur, aucune colonne n'en paie le prix), et l'« effet de
   tronquage » de la bande disparaît avec elle. MÊME PATRON QUE LE PIED DE PAGE NOMADE : les
   éléments sont DÉPLACÉS, jamais recréés — leurs ids, écouteurs et mises à jour chirurgicales
   (updateRtStrip, syncDock) restent vivants. `body.chrome-hdr` porte l'état : le CSS y neutralise
   le sticky de bande, et stickBase()/stickHeight() cessent de compter des rangées qui ne sont
   plus empilées en haut. Le rescue court avec ceux d'applyViewChrome, à chaque changement de
   vue. */
```

## J11 — v5.4.1 (2e passe — A′) : la destination n'est plus la colonne du plan (retours utilisateur :

```
/* v5.4.1 (2e passe — A′) : la destination n'est plus la colonne du plan (retours utilisateur :
   « trois boutons empilés », « on perd de la hauteur ») mais le CRÉNEAU STATIQUE de l'en-tête,
   qui a l'espace à ≥ 1200 px. Conséquence heureuse : plus besoin d'une colonne pour loger le
   chrome — la bande disparaît pour TOUTE lecture de fiche à ce palier, statique et mono-bloc
   comprises, et le cas résiduel « la bande reste » n'existe plus. */
/* v5.6 (lot 2) — IL N'Y A PLUS QU'UN OBJET À DÉPLACER, ET LE PALIER DESCEND À 1000. Les
   commandes ont quitté le haut de l'écran pour le dock : seule la CAPSULE peut encore monter
   dans l'en-tête. A14 la veut au CENTRE, en position absolue, à partir de 1000 px — un titre
   long ne déplace alors plus l'alarme. Le palier descend de 1200 à 1000 parce que la capsule
   est un objet unique et compact, là où les deux rangées d'avant demandaient la largeur du
   cockpit. `mqReadWide` porte déjà ce seuil, mesuré et déclaré. */
```

## J12 — ENTRÉES DE FICHIER : UNE TABLE FERMÉE, UNE PORTE (v5.0.0)

```
/* ═══════ ENTRÉES DE FICHIER : UNE TABLE FERMÉE, UNE PORTE (v5.0.0) ══════════════════════════
   Quatre chemins d'upload cohabitaient avec quatre niveaux de rigueur — le PDF vérifiait sa
   signature, l'import vérifiait la sienne, les DEUX chemins d'image ne vérifiaient qu'un
   `accept`, c'est-à-dire une INDICATION donnée au sélecteur de fichier et jamais une garantie
   (un fichier renommé, ou tout dépôt par glisser, la traverse). Et ils avaient déjà DIVERGÉ :
   60 images maximum côté référence, aucun plafond côté aide, aucun plafond du tout à l'import.
   C'est le motif que ce dossier a payé quatre fois (MUTE_SEL, les verbes de partage, la liste
   des placards, les deux listes de capacités) : deux endroits qui doivent s'accorder finissent
   par ne plus s'accorder, et l'écart est SILENCIEUX.
   CE QUI REND LA RÈGLE EXÉCUTOIRE : l'`accept` AFFICHÉ et la signature VÉRIFIÉE sortent de la
   MÊME ligne de la table. « Un champ de PDF n'accepte ni JSON ni image » cesse d'être une
   intention pour devenir une propriété du code — on ne peut plus changer l'un sans l'autre.
   TROIS NATURES, ET PAS UNE DE PLUS : un document (pdf), une illustration (image), un fichier de
   données (data). Une quatrième s'ajoute ICI, ou nulle part. */
```

## J13 — COMPLICATIONS « À TOUT MOMENT » (v4.26.0) — entrée PAR L'ÉVÉNEMENT

```
/* ═══ COMPLICATIONS « À TOUT MOMENT » (v4.26.0) — entrée PAR L'ÉVÉNEMENT ═══
   Modèle : QRH non-normal / mode failure-related ECAM — une complication ne s'entre pas par la
   séquence mais quand l'événement survient, et le RETOUR fait partie du dispositif (ECAM : on
   traite, puis on REVIENT — jamais laissé à la mémoire).
   cxEnter, cible LOCALE : TOUJOURS un nouveau passage au bout du journal — même bloc déjà visité,
   un événement qui se REproduit est un nouvel événement (≠ jumpToBlock, où revoir = défiler).
   Le bloc interrompu est mémorisé (Runtime.cxBack[seq]) pour le retour. Cible EXTERNE : ouvre
   l'autre aide — la session courante reste vive (multi-sessions).
   cxResume : NOUVEAU passage du bloc interrompu, cases neuves — doctrine d'interruption
   AC 120-71B : après une interruption on RE-VÉRIFIE depuis une ancre sûre, on ne fait pas
   confiance aux coches d'avant l'événement (l'ancienne carte reste lisible juste au-dessus). */
/* UN SEUL DÉCLENCHEUR, mot CONSTANT (v4.26.1, décision utilisateur — et plus doctrinal que la
   rangée de boutons par événement de v4.26.0) : le QRH est UN objet à index par onglets, le manuel
   de Stanford UN manuel à onglets d'événements — on ne met pas un bouton de cockpit par urgence.
   L'appel automatique ECAM ne vaut que pour les pannes CAPTÉES ; l'app ne capte rien, l'analogue
   honnête est donc l'index. Bonus : position ET libellé constants quelle que soit la fiche (N
   boutons rouges qui se ressemblent obligeraient à LIRE chacun sous stress), et l'écran d'action
   se désencombre. Coût assumé : un tap de plus, payé en rangées LARGES dans l'index. */
/* ⚠ B (v5.0.0, audit design) — À UN SEUL ÉVÉNEMENT, IL N'Y A PAS D'INDEX. Ouvrir une liste d'UN
   élément pour y choisir cet élément est le bouton mort de la doctrine, en plus lent : c'est la
   règle « la poignée n'existe qu'à partir de deux rangées », « aucun bouton mort », « un panneau
   qui affirme 0 est du bruit ». L'événement DEVIENT le bouton, et l'on entre d'un tap.
   L'ARBITRAGE EST NOMMÉ, ET IL A ÉTÉ TRANCHÉ PAR L'AUTEUR : le libellé devient alors variable
   d'une fiche à l'autre, alors que la doctrine dit « un mot constant à position constante
   s'apprend ». À UN SEUL événement, lire un mot n'est pas scanner cinq boutons — c'est exactement
   ce que la doctrine reproche aux N boutons rouges ; le glyphe ⚡ et la POSITION, eux, restent
   constants. Au-delà d'un, on retombe sur le mot constant et l'index.
   ⚠ ET UNE COMPLICATION PEUT ÊTRE UNE PORTE VERS UNE AUTRE AIDE (rappel de l'auteur) : le libellé
   le DIT alors par « ↗ », le glyphe des ouvertures externes du dossier — sinon on croirait rester
   dans la fiche, et l'on se retrouverait ailleurs sans l'avoir voulu. */
/* ⚠ ON NE PROPOSE PAS D'ENTRER LÀ OÙ L'ON EST DÉJÀ (signalé à l'usage : « j'ai cliqué sur
   complication bronchospasme réfractaire, et sur la fiche j'ai encore le bouton bronchospasme
   réfractaire »). À UN SEUL événement, le bouton PORTE son nom : le voir pendant qu'on exécute ce
   bloc laisse croire qu'on n'y est pas encore. Il disparaît donc — c'est « aucun bouton mort »,
   et la carte n'est pas pour autant sans contrôle : `↩ Reprendre` est en tête, juste au-dessus.
   À DEUX OU PLUS, l'index RESTE (décision de l'auteur : on peut vouloir passer d'un événement à
   l'autre) — mais celui où l'on se trouve s'y annonce et n'est plus tapable, plutôt que d'être
   retiré : une liste dont les rangées bougent selon l'endroit où l'on est ne s'apprend pas. */
// (`cxOne` — l'accesseur « à un seul événement » — est PURGÉE v5.10.2 : plus aucun appelant,
//  la règle ci-dessus vit dans les rendus eux-mêmes.)
/* ══ A7 + R9 (v5.6) — LE PIED DE CARTE NE PORTE PLUS QUE « VÉRIFIER :: » ═══════════════════════
   Il portait TROIS gestes : ⚡︎ Complications, ⏱ Noter l'heure, Vérifier. Mesuré, la pile
   dépassait le plafond de 25 % de la hauteur de carte sur un bloc court — et deux des trois n'y
   avaient pas leur place par NATURE : une complication survient quand elle survient, un
   horodatage se pose à n'importe quel moment. Ce sont des gestes de SESSION, ils sont partis au
   dock, à position constante et sous le pouce.
   « Vérifier :: » RESTE, et A7 le dit : il rejoue les challenges « :: » DE CE BLOC (Do-Verify,
   FAA Order 8900.1) — c'est un geste de bloc au sens strict, il n'a de sens nulle part ailleurs.
   Il n'apparaît QUE si le bloc porte des challenges, à GAUCHE de « Continuer », qui reste le
   dernier élément de la carte. Le dock, lui, reste pur session.
   ⚠ La fabrique garde son nom et sa signature : trois sites l'appellent, et `curId`/`list` restent
   lus par la garde « on ne propose pas d'entrer là où l'on est déjà » côté dock. */
```

## J14 — (`cxListHtml` est purgée avec l'index de carte — cf. la note CSS des `.cx-*`.)

```
/* (`cxListHtml` est purgée avec l'index de carte — cf. la note CSS des `.cx-*`.) */
/* ═══ JALONS DE BOUCLE (v5.5.0, P1+P2+P3) — l'ÉVOLUTION DANS la boucle ═══
   Le déroulé en boucle était couvert (↺, passages ×n, convergence) ; ce qui n'existait pas, c'est
   un contenu qui CHANGE au k-ième passage ou au n-ième choc — FV réfractaire après 3 CEE, 4H/4T à
   re-balayer. L'auteur n'avait que du texte statique (bruit avant le seuil) ou une excursion dont
   l'ENTRÉE reposait sur la mémoire du compte — l'inverse de la doctrine QRH (« jamais laissé à la
   mémoire »), alors que le runtime CONNAÎT les deux nombres (passInfo, Runtime.counters).
   RENDU : sur la carte du BOUT seulement (le journal est une chronologie ; le jalon est une aide
   à la décision de MAINTENANT — les vues de structure, elles, l'annoncent d'emblée). Modèle ECL :
   le contenu est CONSTANT — la ligne existe dès le premier passage, estompée, condition en toutes
   lettres et progression vivante (« Chocs délivrés 2/3 ») — seul son ÉTAT change au seuil (boîte
   au registre ATTENTION). Ambre, jamais rouge : « c'est là qu'on se trompe », pas une alerte.
   RIEN NE SE DÉCLENCHE (règle 11) : pas de son, pas de défilement, pas de fenêtre — un texte déjà
   affiché change d'état, l'annonce SR passe par #srLive. Le franchissement est un ≥ : un fait ne
   s'acquitte pas (doctrine « Consigné »).
   P2 : le renvoi `go` désigne la CIBLE d'une excursion DÉCLARÉE — le bouton réutilise `data-cxgo`
   donc `cxEnter`, ses gardes de partage et son retour prévu (↩ Reprendre). AUCUNE navigation
   nouvelle. Le bouton n'est TAPABLE qu'au seuil (avant, l'excursion reste joignable par sa rangée
   ⚡ constante au pied — deux moments, pas une duplication : l'index constant s'apprend, l'action
   au pied de l'alerte est la règle ECAM d'`onDue`).
   Qualification réglementaire écrite AVANT développement : docs/deploiement-et-conformite.md § 2. */
```

## J15 — ⚠ LE PASSAGE QU'ON INTERROMPT SE REPLIE (v5.7, signalé à l'usage : « on reprend et le bloc

```
  /* ⚠ LE PASSAGE QU'ON INTERROMPT SE REPLIE (v5.7, signalé à l'usage : « on reprend et le bloc
     précédent s'affiche en haut comme un doublon »). Un témoin a tranché AVANT qu'on touche au
     code : `cxResume` redépose bien sur le bloc INTERROMPU — la navigation est juste. Ce qui se
     lit comme un doublon est la PRÉSENTATION : le passage quitté est INCOMPLET, donc `ovPresList`
     le garde en CARTE OUVERTE (« un passage incomplet n'est jamais une chip » — l'invariant qui
     fait la conformité du journal), et l'on se retrouve avec deux cartes ouvertes du même bloc,
     l'une au-dessus de l'autre, portant les mêmes étapes.
     L'INVARIANT N'EST PAS TOUCHÉ : on ne le transforme pas en chip, on pose le REPLI MANUEL, que
     la doctrine autorise déjà (« repli manuel = ligne d'état au maximum ») et qui PERSISTE. Rien
     n'est perdu — les mêmes étapes sont dans la carte neuve juste en dessous, et un tap rouvre
     l'ancienne. C'est exactement ce que la condensation R6 fait d'un passage achevé, appliqué au
     seul cas où deux cartes du même bloc coexistent par construction. */
```

## J16 — ══ TOLÉRANCE ORTHOGRAPHIQUE — ON CORRIGE LA REQUÊTE, JAMAIS LA LISTE (v5.6)

```
/* ══ TOLÉRANCE ORTHOGRAPHIQUE — ON CORRIGE LA REQUÊTE, JAMAIS LA LISTE (v5.6) ═══════════════════
   Sous stress et avec des gants, « anafilaxie » ne trouvait RIEN — et un répertoire qui répond
   « aucun résultat » sur une faute de frappe fait renoncer à chercher là où le contenu est.
   QUATRE BORNES, et ce sont elles qui rendent la chose admissible dans un logiciel d'urgence :
   1. ELLE NE SE DÉCLENCHE QUE SUR ZÉRO RÉSULTAT — la liste littérale, quand elle existe, n'est ni
      réordonnée ni complétée. Le rapprochement flou est un DERNIER recours, pas un classement.
   2. LES CANDIDATS VIENNENT DE VOTRE PROPRE BIBLIOTHÈQUE, jamais d'un dictionnaire livré : corriger
      vers un mot qui n'est nulle part rendrait zéro résultat, et un lexique médical embarqué serait
      une seconde source de vérité à tenir (sans compter le poids, règle 13).
   3. ELLE SE DÉCLARE EN TOUTES LETTRES (« aucun résultat pour X · affiché : Y ») : une recherche
      qui corrige en silence ment sur ce qu'elle montre, et l'on croirait avoir tapé juste.
   4. ELLE NE RÉÉCRIT PAS LE CHAMP — le texte tapé reste celui de l'utilisateur ; c'est le RÉSULTAT
      qui est élargi, pas la saisie qui est corrigée sous les doigts.
   ⚠ Un terme qui est le PRÉFIXE ou un fragment d'un mot du vocabulaire n'est jamais corrigé : on
   tape « anaph » en cours de frappe, et le corriger ferait sauter la liste sous le doigt. */
/* Distance de Damerau-Levenshtein BORNÉE : on sort dès que la meilleure valeur d'une ligne dépasse
   le budget — sans cette borne, un vocabulaire de plusieurs milliers de mots coûterait une passe
   complète par candidat, à chaque frappe. La transposition compte pour UN : « anaphylaxie » tapé
   « anaphyalxie » est la faute la plus fréquente au clavier, et deux substitutions la surestiment. */
```

## J17 — CHERCHER DANS LES DOCUMENTS PDF — UN INDEX INVERSÉ (v5.2.0)

```
/* ═══ CHERCHER DANS LES DOCUMENTS PDF — UN INDEX INVERSÉ (v5.2.0) ═════════════════════════════
 *
 * LE PROBLÈME. La recherche trouvait la FICHE, jamais l'endroit : un protocole de service joint
 * en PDF pouvait porter la seule mention d'une dilution, et rien ne la trouvait. La première
 * proposition — conserver le texte extrait et le balayer — a été REFUSÉE par l'auteur, à raison :
 * ce n'est pas un index, c'est une photocopie sur laquelle on fait un `grep`. Elle pesait ~100 %
 * du texte extrait (mesuré 546 Ko pour un document de 200 pages), et il fallait inventer un
 * PLAFOND pour la contenir — donc des documents indexés à moitié, sans que rien ne le rattrape.
 *
 * CE QUE FONT SPOTLIGHT, FINDER ET LUCENE — et que l'on fait ici. On ne garde pas le texte. On
 * garde le DICTIONNAIRE des mots distincts du document (trié, front-codé : chaque mot ne stocke
 * que ce qui le distingue du précédent) et, pour chacun, la LISTE DES PAGES où il apparaît,
 * codée en écarts successifs sur un octet — ou en BITMAP quand le mot est trop fréquent pour que
 * les écarts soient rentables (c'est le choix de Roaring/Lucene). Trois conséquences :
 *   · le poids suit le VOCABULAIRE, qui sature, et non la longueur : mesuré sur du français
 *     technique réel, 49 Ko de texte donnent un index à 34 % ; 626 Ko, un index à 13,4 % — le
 *     texte est multiplié par 13, les mots distincts par 3,7 seulement ;
 *   · AUCUN plafond n'est donc nécessaire : l'indexation est INTÉGRALE, toujours ;
 *   · l'extrait n'est pas stocké non plus — Finder montre le FICHIER, pas la phrase, et le
 *     contexte se régénère depuis le document quand on l'ouvre. C'est ce qui garantit que pdf.js
 *     (1 773 Ko) n'est JAMAIS chargé pendant qu'on tape (règle 13).
 *
 * ⚠ POURQUOI PAS L'INDEX DU NAVIGATEUR, QUI EXISTE — la question a été posée, et elle est bonne.
 * IndexedDB sait faire un index inversé tout seul (`createIndex(..., {multiEntry:true})` +
 * `IDBKeyRange` pour les préfixes), sans une ligne de notre part. MESURÉ sur le même corpus, même
 * découpage : **3 521 Ko** contre **74 Ko** ici, soit ×47 — et ×39 encore pour la variante mixte
 * (notre dictionnaire, ses postings sur des entiers). Le coût est le sur-poids par entrée du
 * moteur (~55 octets par couple mot-page, 54 024 couples), qu'aucun encodage de notre côté ne
 * peut retirer. C'est donc exactement le poids qui avait été refusé, en quatorze fois pire.
 * ⚠ ET PAS SQLITE FTS5 : il n'existe aucun SQLite dans un navigateur (Web SQL est retiré depuis
 * Chrome 119). L'y amener, c'est embarquer SQLite compilé en WASM — une SECONDE dépendance
 * runtime, que la règle 13 interdit, avec tout l'appareillage de pdf.js (vendorisation, entrée
 * dans `ASSETS`, clé de cache versionnée, veille d'avis de sécurité) — pour obtenir « mot →
 * pages ». FTS5, c'est aussi le classement BM25, les requêtes de phrase, `snippet()`, les
 * tokeniseurs et la fusion incrémentale : rien de ce dont il s'agit ici.
 *
 * L'index est DÉRIVÉ, donc strictement LOCAL : jamais poussé dans Storage, jamais dans l'export
 * ni le ZIP. Le perdre ne perd rien — il se reconstruit depuis le PDF. */
```

## J18 — ----- FRECENCY (v4.4.6) : fréquence + récence d'OUVERTURE par fiche/protocole (même famille

```
// ----- FRECENCY (v4.4.6) : fréquence + récence d'OUVERTURE par fiche/protocole (même famille
// que ac-pins / ac-lib-usage, un espace par compte). N'ordonne QUE les résultats de RECHERCHE :
// « ana » remonte la fiche qu'on ouvre le plus en tapant ça (Spotlight).
// La liste par défaut reste ALPHABÉTIQUE (décision v4.3.2) et les épingles restent premières.
// Le score est STABLE pendant la frappe (il ne dépend pas de la requête) : les cartes ne se
// réordonnent pas sous le doigt — exigence de calme sous stress.
// SYNCHRONISÉE entre appareils depuis v4.4.7 (connecté) : voyage dans le document de catégories
// PERSO (data.usage, comme les épingles), mais FUSIONNÉE à l'arrivée au lieu d'être remplacée —
// deux appareils comptent indépendamment, un remplacement en bloc perdrait les comptes de l'un
// (mergeUsage : par fiche, l'entrée au n le plus grand ; max idempotent, jamais de double-compte).
// Le push est THROTTLÉ (au plus toutes les 10 min) : ouvrir une fiche ne doit pas coûter une
// écriture réseau à chaque tap — la fraîcheur inter-appareils n'a pas besoin du temps réel.
```

## J19 — RÉPERTOIRE A→Z de l'accueil (v4.56.0, maquette 2c « poste accès direct »)

```
/* ===== RÉPERTOIRE A→Z de l'accueil (v4.56.0, maquette 2c « poste accès direct ») =====
   Fonctions PURES (testées via ?__actest).
   azLetter : lettre de classement d'un titre — majuscule désaccentuée ; hors A-Z (chiffre,
   symbole, vide) -> '#', groupe rangé en FIN d'alphabet.
   azGroups : groupes ordonnés {L,items} — table en Object.create(null) (la clé vient d'un titre
   saisi, règle 6) ; l'ordre INTERNE d'un groupe est celui de la liste reçue.
   qaPick : tuiles « Accès direct » — les ÉPINGLÉES SEULES (décision utilisateur : « juste les
   favoris » — la frecency reste un critère de TRI DE RECHERCHE, jamais de mise en avant), dans
   l'ordre du tableau pins (la plus récente en tête, comme le tri de liste historique). PAS de
   plafond : un favori escamoté par une borne silencieuse serait pire que la place qu'il coûte
   (pins est déjà borné à 50) ; sans épingle, AUCUNE tuile — la section disparaît. */
```

## J20 — ══ NAVIGATION UNIFORMISÉE — UNE SEULE LISTE, DEUX CLÉS DE GROUPEMENT (v5.6, lot 5)

```
/* ══ NAVIGATION UNIFORMISÉE — UNE SEULE LISTE, DEUX CLÉS DE GROUPEMENT (v5.6, lot 5) ═════════
   L'accueil avait DEUX dispositifs pour la même question « où est ma fiche ? » : un répertoire
   A→Z avec son rail d'index à droite, et un filtre de catégorie en chips qui RESTREIGNAIT le
   corpus. Ce ne sont pas deux vues d'une même chose, ce sont deux gestes différents — l'un
   oriente, l'autre ampute — et il fallait savoir lequel on voulait avant de chercher.
   Le sélecteur « A–Z | Catégories » choisit désormais la CLÉ DE GROUPEMENT de la MÊME liste, et
   le rail droit est le MÊME index dans les deux modes (lettres ↔ pastilles de catégorie). On ne
   perd jamais de fiche en changeant de clé : c'est un changement d'ordre, pas de contenu — et
   c'est ce qui distingue un groupement d'un filtre.
   `catGroups` est le JUMEAU d'`azGroups` : même forme de sortie `{L, items}`, pour que le rendu
   et le rail n'aient pas à savoir laquelle des deux les a produits. Les fiches SANS catégorie
   forment un groupe « Sans catégorie » rangé en fin, comme le « # » du A→Z. */
```

## J21 — UN FILTRE QUI NE FILTRE RIEN N'EST PAS UN FILTRE (audit externe v5.10.1). Sur une installation

```
/* UN FILTRE QUI NE FILTRE RIEN N'EST PAS UN FILTRE (audit externe v5.10.1). Sur une installation
   neuve, le rail de l'accueil affichait NEUF catégories dont SIX à zéro : six rangées qui mènent à
   une liste vide, en tête de l'écran qu'on ouvre en premier. C'est la règle « un panneau vide est
   du bruit », qu'A88 précise — elle vise ce qui AFFIRME, pas ce qui INVITE : une rangée « Pédiatrie
   0 » AFFIRME l'existence d'un rangement vide, elle n'ouvre aucune capacité. La taxinomie, elle, a
   son lieu — « Gérer les catégories », qui reste à sa place.
   ⚠ LA CATÉGORIE SÉLECTIONNÉE RESTE, MÊME À ZÉRO, et c'est la moitié qui compte : supprimer sa
   rangée rendrait le filtre INVISIBLE au moment précis où il explique une liste vide — « un filtre
   posé ne doit jamais être invisible » (v5.0.0), et l'on chercherait pourquoi une aide n'apparaît
   pas. Le compte se lit alors « 0 », ce qui est exactement l'information utile.
   ⚠ ET LE COMPTE EST CELUI DU CRAN COURANT, pas du corpus : une catégorie non vide en « Tout »
   peut être vide en « Protocoles ». C'est juste — sous ce cran, elle ne mènerait à rien. */
/* `catsUtiles`/`catNbSousFiltre` SUPPRIMÉES à l'audit v5.19.3 (règle 14) : le prédicat par
   bibliothèque était resté après que la v5.18 l'a remplacé par l'UNION ci-dessous — successeur
   arrivé, prédécesseur jamais purgé, zéro appelant. Le principe « UN SEUL COMPTE, DEUX
   LOGEMENTS » (rail large et chips étroites cachent EXACTEMENT les mêmes catégories, un seul
   prédicat) vaut toujours et vit dans `catsUtilesAll`. */
/* v5.18 — l'accueil est l'UNION des bibliothèques : le filtre de catégorie se compare PAR NOM
   (chaque bibliothèque a ses propres ids ; « Anesthésie » du bloc et « Anesthésie » du SMUR
   sont le même cran pour qui filtre). La feuille liste une entrée par nom, tous corpus. */
```

## J22 — Modèle

```
/* ===== Modèle =====
   blankFiche()  : fiche vierge (1 bloc d'étapes) pour une création.
   migrate(f)    : rend compatible une fiche d'origine quelconque (ajoute les
                   champs manquants ; convertit l'ancien format "étapes plates"
                   en un bloc 'steps'). Appelée à chaque lecture/import.
   seed(catId)   : fiche d'exemple "Anaphylaxie" (branchement + chronomètre +
                   minuteur à cycle + compteur) chargée au 1er lancement.
   defaultCats() : 8 catégories par défaut (espace Perso).
   migrateCategories() : convertit d'anciennes catégories "texte" en objets
                   {id,name,color,libraryId} et réécrit fiche.category avec l'id.
                   Renvoie les fiches modifiées (à repersister).
   Aides : hasFlow (la fiche a-t-elle un branchement ?), staleDate (validation
   de plus de 2 ans), fmtDate (libellé de date de validation). */
```

## J23 — CE QUI N'A AUCUNE SOURCE EN v3 REÇOIT UN DÉFAUT NEUTRE, ET SURTOUT PAS UNE DEVINETTE : `dual`

```
   CE QUI N'A AUCUNE SOURCE EN v3 REÇOIT UN DÉFAUT NEUTRE, ET SURTOUT PAS UNE DEVINETTE : `dual`
   (AC 120-71B §5.2.2.5 — inexprimable en v3), `phase`, `concl`, `note` naissent vides. Deviner
   qu'un premier bloc est « immediate » ou qu'un item est `dual` reviendrait à écrire du contenu
   clinique à la place de l'auteur — exactement ce que la doctrine refuse pour le `discriminant`
   (« aucune migration ne DEVINE »). */
/* ===== L'ITEM DEVIENT LA SOURCE (lot T6 — côté RENDU, v5.0.0) =================================
   Jusqu'ici une étape était une CHAÎNE À UNE POSITION : `b.steps[3]`. Trois conséquences qu'on a
   payées séparément — un compte rendu qui nomme le mauvais geste après une insertion (lot T1), et
   l'impossibilité d'accrocher quoi que ce soit À UNE ÉTAPE (`dual` d'AC 120-71B §5.2.2.5, une
   note d'auteur, un niveau d'alerte ordonné) autrement que par son rang, c'est-à-dire par la
   chose même qui bouge.
   DÉSORMAIS `b.items[]` EST LA SOURCE. (Le miroir `b.steps[]`, qui a existé de T6 à l'étape C, a
   écriture. Ce n'est PAS une seconde source de vérité, et la distinction est le cœur du dispositif :
   le miroir est écrit, jamais lu par ce client (`stepsOf` lit les items). Il existe pour UNE seule
   raison — un client antérieur qui reçoit la fiche par la synchro doit continuer d'afficher la
   checklist. Le jour où plus personne ne tourne en 4.x, il s'enlève en une ligne.
   ÉCART ASSUMÉ AVEC LA SPÉCIFICATION v4, ET IL EST RÉVERSIBLE : la spec range les items dans un
   POOL `f.items[]` que les blocs référencent par id. Ce niveau d'indirection sert un cas qu'aucune
   fonctionnalité n'a aujourd'hui (un item partagé par deux blocs, ou porté par aucun) et le
   coûterait à CHACUN des quarante-huit sites de lecture. Les items d'un bloc vivent donc DANS leur
   bloc. (La conversion `v3ToV4`/`v4ToV3` a été RETIRÉE à l'étape D : v4 est le seul format
   que l'application connaisse — la reprise d'un fichier v3 passe par `docs/conversion-v3-vers-v4.md`.) */
```

## J24 — LE MIROIR EST RÉGÉNÉRÉ, JAMAIS RÉCONCILIÉ : on n'essaie pas de deviner laquelle des deux formes

```
/* LE MIROIR EST RÉGÉNÉRÉ, JAMAIS RÉCONCILIÉ : on n'essaie pas de deviner laquelle des deux formes
   est « la plus fraîche » — les items gagnent toujours. Une réconciliation aurait exactement le
   défaut de `edSyncGallery` (v4.78.0), où un geste qui retirait se défaisait tout seul au rendu. */
/* ═══ LE POOL (étape B du passage à v4 complet, v5.0.0) ════════════════════════════════════
   `f.items[]` est désormais LA liste des items de l'aide — toutes portées confondues — et un bloc
   ne porte plus que des IDENTIFIANTS. Les six listes v3 (`confirmation`, `notForget`, `verify`,
   `posology`, `differentials`) n'existent plus comme champs : leurs lignes sont des items à `role`.
   POURQUOI UN POOL PLUTÔT QUE DES OBJETS DANS LES BLOCS — la question mérite d'être tranchée ici,
   parce que j'avais fait l'inverse au lot T6 et que c'était défendable : sans pool, les items d'un
   bloc vivent dans leur bloc, et il n'y a aucune indirection à payer. Mais alors les items de
   `role` entry/watch/dose/ddx n'ont NULLE PART où vivre — ils restaient dans leurs six champs v3,
   c'est-à-dire que le modèle n'était pas v4. Le pool est ce qui donne un logement à TOUS les items,
   et c'est pour cela qu'il est la forme de la spécification.
   RÉSOUDRE UN ID DEMANDE DE CONNAÎTRE LA FICHE, et vingt-deux sites appellent `bItems(b)` sans
   l'avoir sous la main. Plutôt que de threader `f` à travers vingt-deux signatures — donc d'ouvrir
   vingt-deux occasions de se tromper —, chaque bloc connaît son aide par une WeakMap posée là où
   les blocs sont normalisés (`migrate`). La WeakMap ne touche pas la donnée : rien de nouveau ne
   se sérialise, rien ne part en synchro, et un bloc oublié se retrouve par un balayage de repli. */
```

## J25 — PERTINENCE DES REPÈRES POSOLOGIQUES (v4.23.0)

```
/* ===== PERTINENCE DES REPÈRES POSOLOGIQUES (v4.23.0) =====
   Une liste de repères peut être longue ; on veut voir en tête ceux qui concernent le bloc en
   cours. RÈGLE DE SÛRETÉ ABSOLUE : ce classement RÉORDONNE, il ne FILTRE JAMAIS. C'est ce qui
   autorise un rapprochement volontairement permissif — un faux positif coûte un rang, un faux
   négatif coûte un défilement, jamais une dose manquante. Un filtre silencieux, lui, ferait
   disparaître un repère à l'instant précis où on le cherche : c'est le seul mode de défaillance
   inacceptable ici (le décluttering ECAM n'est sûr que parce que sa sélection est exhaustive).
   Corollaire tenu par le rendu : un repère « ⚠ » (registre ALERTE) n'est JAMAIS replié.
   Résilience demandée (retour utilisateur) : « Adré » doit trouver « Adrénaline » (préfixe) et
   « IM » doit trouver « intramusculaire » (table de voies, dans les deux sens). */
// Voies et formes : chaque variante -> un jeton CANONIQUE ; « im » et « intramusculaire »
// donnent tous deux 'im', donc l'un trouve l'autre sans règle supplémentaire.
```

## J26 — Cartes de repères posologiques, classées pour le bloc courant : les rapprochés et TOUS LES

```
/* Cartes de repères posologiques, classées pour le bloc courant : les rapprochés et TOUS LES
   SIGNALÉS — `⚠` comme `△`, via `posoRank().crit` — en tête, le reste replié derrière un
   dépliant qui ANNONCE SON NOMBRE (un pli muet serait un filtre déguisé).
   CORRIGÉ v4.44.0 : cette entête affirmait « source unique, partagée par le flux et la feuille
   Consulter — les deux rendus ne peuvent pas diverger ». C'est FAUX depuis v4.25.3, qui a retiré
   la posologie de la feuille Consulter (elle y pesait, avec les surveillances, 57 % de la hauteur
   pour un contenu déjà présent quatre fois ailleurs). Il ne reste qu'UN site d'appel, dans
   `renderRead`. Le commentaire promettait donc une garantie de non-divergence entre deux rendus
   dont l'un n'existe plus — le genre d'affirmation qui survit à ce qu'elle décrit et qu'un
   contributeur applique par imitation. */
/* LIRE UN REPÈRE — UN SEUL POINT DE LECTURE, DEUX BALISAGES (v5.10.0, lot Page).
   Le lot « Page » a besoin des repères en TABLE À TROIS COLONNES, où une carte ne tient pas ; le
   brief le dit en toutes lettres : « ne duplique pas la logique de lecture des items ». On extrait
   donc la lecture (nom · corps · registre) et l'on n'écrit deux fois que le BALISAGE — recopiée,
   la coupure sur « : » aurait fini par découper autrement ici et là, sur la seule donnée du
   fichier qui porte une dose. PURE. */
```

## J27 — migrate = compatibilité ascendante ET point d'ASSAINISSEMENT (toute fiche chargée/importée/dupliquée

```
// migrate = compatibilité ascendante ET point d'ASSAINISSEMENT (toute fiche chargée/importée/dupliquée
// y passe). Coerce les types, restreint les identifiants à un jeu sûr (remappés si dangereux, en
// conservant les liens internes), valide images/couleurs, plafonne les tailles.
// Queue COMMUNE de sanitisation fiche/protocole (audit v4.1.0 : ces règles vivaient en double
// dans migrate() et migrateProtocol() — une évolution faite d'un seul côté divergeait en silence).
// Couvre l'identité, les métadonnées éditoriales (status/code/related/updatedBy), les images
// (plafond par image 6 M car. + plafond CUMULÉ 24 M : sans lui un JSON importé pouvait porter
// imgMax × 6 M de base64 et figer le téléphone au rendu — images en excès IGNORÉES), les
// documents PDF (métadonnées seules, entrées invalides rejetées) et la synchro (updatedAt
// last-write-wins, tombstone deletedAt, ownerId/libraryId ; `dirty` purement local, jamais
// conservé d'un import).
// Dimension d'image bornée (0 = inconnue, ex. import ancien -> pas de réservation d'espace).
```

## J28 — L'ITEM EST LA SOURCE (lot T6). Si la fiche en porte déjà, ils gagnent — et le miroir

```
      /* L'ITEM EST LA SOURCE (lot T6). Si la fiche en porte déjà, ils gagnent — et le miroir
         `steps` est RÉGÉNÉRÉ depuis eux ; sinon on les dérive des chaînes, une fois. */
      /* Le bloc ne porte plus que des IDENTIFIANTS ; les objets sont rassemblés dans `_pool`,
         monté sur la fiche juste après (le pool doit exister AVANT que `bItems` soit appelée). */
      /* ÉTAPE D : plus de miroir, donc plus de repli sur des chaînes. Une fiche entrante SANS
         items est une fiche VIDE — conséquence assumée de la rupture, et annoncée : un fichier v3
         se convertit par `docs/conversion-v3-vers-v4.md`, jamais ici. */
      /* ⚠ DÉFAUT DE CONTRAT TROUVÉ À LA MESURE (v5.0.0) : une CHAÎNE dans `b.items` était
         recopiée telle quelle comme IDENTIFIANT. Si elle ne désigne aucun item du pool — cas
         d'un fichier produit par une IA, qui écrit naturellement le texte de l'étape —, le bloc
         se retrouvait plein de RÉFÉRENCES PENDANTES : il s'affichait VIDE, sans un mot, et le
         contenu était perdu à l'import. `migrate` est le point d'ASSAINISSEMENT (règle 5) : une
         référence qui ne résout pas ne doit jamais en sortir vivante.
         RÈGLE : une chaîne qui correspond à un id du pool est une RÉFÉRENCE ; toute autre chaîne
         est le TEXTE d'une étape, et devient un item. Ce n'est pas une tolérance v3 — le format
         v4 est inchangé — c'est la forme abrégée que le prompt IA documente désormais, et le
         refus d'avaler une donnée en silence. */
```

## J29 — JALONS DE BOUCLE (v5.5.0, P1) — b.milestones : [{at:'pass'|'count', n, counter, text, go}].

```
  /* JALONS DE BOUCLE (v5.5.0, P1) — b.milestones : [{at:'pass'|'count', n, counter, text, go}].
     Un contenu de boucle qui ÉVOLUE (« après 3 CEE : envisager FV réfractaire ») n'avait aucune
     écriture possible : soit du texte statique (bruit avant le seuil), soit une excursion dont
     l'ENTRÉE reposait sur la mémoire du compte — l'inverse de la doctrine QRH. Le jalon est une
     règle ÉCRITE PAR L'AUTEUR que l'app met en avant au moment que l'auteur a défini — même
     famille qu'`onDue` (K7) ; qualification écrite AVANT développement dans
     docs/deploiement-et-conformite.md § 2 (« Le cas des jalons de boucle »).
     ASSAINISSEMENT ICI, ET PAS AILLEURS (règle 5) — ce bloc court APRÈS les compteurs et les
     excursions, seul point où leurs ids finaux existent : un jalon 'count' dont le compteur ne
     résout pas est REJETÉ (un jalon qui ne peut pas mesurer est mort — même règle que les cibles
     d'excursion invalides) ; un renvoi `go` qui ne désigne pas la cible d'une excursion DÉCLARÉE
     est retiré (le renvoi réutilise cxEnter : hors excursion il n'aurait pas de retour prévu). */
```

## J30 — ⚠ DEUX MINUTEURS DÉCLARÉS, ET C'EST UNE DÉCISION DE DÉCOR (v5.7). Le lot T13 pose que « les

```
    /* ⚠ DEUX MINUTEURS DÉCLARÉS, ET C'EST UNE DÉCISION DE DÉCOR (v5.7). Le lot T13 pose que « les
       deux fiches d'exemple exercent la doctrine qu'elles enseignent » ; il en manquait un cas —
       le RÉORDONNANCEMENT VIVANT (A116) ne s'observe qu'à partir de DEUX minuteurs déclarés dans
       la même liste, et aucun exemple n'en portait deux. Son témoin d'audit n'avait donc aucun cas
       à rencontrer, et l'écrire quand même aurait produit un vert qui ne mesure rien.
       Le second est clinique et non décoratif : en ACR, l'adrénaline se renouvelle, et les deux
       cadences (2 min / 4 min) sont précisément le cas où l'ordre par temps restant change sous
       l'œil.
       ⚠ IL N'EST PAS `autoloop`, ET CE N'EST PAS UN DÉTAIL — un témoin l'a dit aussitôt.
       `cycleHint` (v5.5.0, P4) n'annote les renvois de boucle QUE si la fiche déclare UN SEUL
       minuteur à cycles : « à deux, annoter serait une devinette ». Un second minuteur CYCLIQUE
       aurait donc fait disparaître le cas de ce témoin-là — on aurait réparé un décor en cassant
       un autre. Une relance MANUELLE est d'ailleurs le geste juste ici : on relance après avoir
       injecté, pas avant. */
```

## J31 — PRÉSENTATION du fil FUSIONNÉ (v4.16.0 — le mode guidé est absorbé par le journal) : pour

```
/* PRÉSENTATION du fil FUSIONNÉ (v4.16.0 — le mode guidé est absorbé par le journal) : pour
   chaque passage, 'open' (carte), 'line' (ligne d'état verte) ou 'chip' (pastille condensée).
   RÈGLES (validées ECAM/QRH/AC 120-71B avec l'utilisateur) :
   - le BOUT est toujours une carte (surface d'action) ;
   - un passage INCOMPLET n'est JAMAIS condensé en chip (le non-fait reste sous les yeux —
     l'invariant qui fait la conformité) ; repli manuel -> ligne d'état au maximum ;
   - un passage COMPLET non-courant : les 2 plus récents -> ligne d'état, les autres -> chip ;
   - la SURCHARGE MANUELLE prime (manual=false -> carte dépliée, manual=true -> condensé).
   La condensation ne s'applique qu'AU RENDU d'un geste (jamais sous le doigt). PURE. */
/* ══ R6 (v5.6) — LE PASSÉ S'ANNONCE ET SE TIRE ════════════════════════════════════════════════
   Le fil condensé gardait les DEUX passages complets les plus récents en LIGNE D'ÉTAT, les plus
   anciens en chips, et ne repliait la rangée qu'au-delà de quatre. Résultat mesuré : ~25 objets à
   l'écran en nominal, dont l'essentiel était de l'HISTORIQUE — c'est-à-dire ce qui ne conduit
   plus rien. La refonte pose « le bloc SEUL au centre » : tout passage complet et non courant
   devient une chip, et la rangée de chips se replie DÈS QU'ELLE EXISTE en ligne-bilan (« ✓ n
   passages · a→b ▸ »), qu'un tap déplie sur place.
   ⚠ LES DEUX INVARIANTS DU JOURNAL SONT INTACTS, et ce sont eux qui rendent le repli admissible :
     · un passage INCOMPLET n'est JAMAIS une chip — il appelle l'action, il reste déplié ;
     · le BOUT est toujours une carte — on écrit là, et nulle part ailleurs.
   Le repli MANUEL reste souverain dans les deux sens (`manual===false` rouvre, `manual===true`
   replie), et la condensation automatique ne reprend qu'au prochain geste de navigation
   (`ovDropOpens`) — jamais sous le doigt pendant le cochage. */
```

## J32 — F5 (v5.7) — ROUVRIR L'APP PENDANT UN SOIN, C'EST VOULOIR LE SOIN

```
  /* ═══ F5 (v5.7) — ROUVRIR L'APP PENDANT UN SOIN, C'EST VOULOIR LE SOIN ═══════════════════
     Rouvrir l'application pendant une session vive déposait sur l'accueil, où une carte propose
     de reprendre : un tap de plus dans le seul moment où l'on n'en a aucun à donner. On atterrit
     désormais DANS le soin — avec le « ‹ » d'en-tête qui ramène à la bibliothèque, à sa place
     constante, donc sans piéger personne.
     ⚠ CE QUE ÇA ROMPT, ET LA BORNE QUI LE REND ACCEPTABLE : « on s'oriente avant d'agir » (la
     condition d'entrée QRH) ne vaut que pour une session qu'on COMMENCE ; ici elle est déjà en
     cours, et l'orientation a eu lieu. Le risque est celui de quelqu'un qui rouvre l'app pour une
     AUTRE aide : il est borné par la fraîcheur — au-delà de dix minutes sans le moindre geste, on
     redépose sur l'accueil, où la carte de session reprend son office.
     ⚠ ET JAMAIS SUR UN LIEN DE PARTAGE : l'invité a son propre écran d'entrée, décidé avant le
     chargement (shareBootDecide) — le lui remplacer serait le sortir de son parcours. */
```

## J33 — Runtime (minuteurs, compteurs, audio)

```
/* ===== Runtime (minuteurs, compteurs, audio) =====
   freshRuntime(f, session) : (re)construit l'état vivant pour la fiche f. Si une
     `session` est fournie, reprend ses cochages/position/compteurs/minuteurs
     (minuteurs en pause). Relie state.checked/state.nav à Runtime.
   resetRuntime()           : invalide le Runtime (forcera une reconstruction).
   ensureAudio()/beep()     : AudioContext paresseux ; beep = bip + vibration,
     déclenché à la fin d'un cycle de minuteur. flash(id) : clignotement visuel.
   toggleTimer(t)           : démarre/met en pause (plie le temps écoulé dans
     elapsedMs ; mémorise lastStart au démarrage). resetTimer(t) : remet à zéro.
   tickAll()                : appelée par un setInterval global toutes les 300 ms.
     - Pour les minuteurs 'interval' en marche : détecte le franchissement d'un
       cycle (rebascule, incrémente cycles, beep+flash ; boucle si autoloop).
     - Si on est en vue 'read', met à jour le DOM par id (valeur, cycles, barre)
       SANS re-rendu complet (évite les sauts de défilement et pertes de focus).
   Note : l'intervalle tourne en permanence mais ne fait rien hors mode crise
   sauf gérer les alertes des minuteurs encore actifs. */
```

## J34 — navSeq : identifiant de VISITE unique par entrée de nav (parallèle à nav). Permet, lors

```
  // navSeq : identifiant de VISITE unique par entrée de nav (parallèle à nav). Permet, lors
  // d'une boucle qui revient sur un bloc, d'avoir des cases à cocher NEUVES pour cette visite
  // tout en conservant (sans les effacer) les cases cochées des visites précédentes. La clé de
  // cochage = 'seqDeLaVisite:idBloc:index'. On restaure navSeq d'une session, sinon on régénère.
  /* RÉGÉNÉRATION INTERDITE SUR UNE SESSION PARTAGÉE. Sur une session locale, régénérer `1..n`
     quand les longueurs divergent est un repli raisonnable (enregistrement ancien, sans navSeq).
     Sur une session PARTAGÉE, c'est une catastrophe silencieuse : les clés de cochage valent
     `seqDeLaVisite:idBloc:index`, donc renuméroter les visites ORPHELINE TOUTES LES COCHES — sur
     une fiche de 8 blocs à 6 étapes, 48 coches disparaissent en un rendu, sans message. Le fil
     transporte d'ailleurs `nav` et `navSeq` comme un COUPLE indissociable (shareFold refuse un
     évènement de navigation dont les longueurs ne correspondent pas) : une divergence ici signifie
     que l'état reçu est faux, pas qu'il est vieux. On garde donc ce qu'on a reçu et on LÈVE UN
     DRAPEAU — l'appelant redemande un instantané complet plutôt que d'afficher une session
     renumérotée. Échouer bruyamment, jamais deviner. */
```

## J35 — ⚠ UN MINUTEUR RESTAURÉ EST EN PAUSE, ET IL DOIT DIRE DEPUIS QUAND (v5.6, planche 11j).

```
/* ⚠ UN MINUTEUR RESTAURÉ EST EN PAUSE, ET IL DOIT DIRE DEPUIS QUAND (v5.6, planche 11j).
   Le temps passé application fermée n'est PAS rattrapé, et c'est juste : le rattraper fabriquerait
   un temps que personne n'a mesuré. Mais rien ne disait COMBIEN — or un minuteur figé à 4:22 se
   lit d'un coup d'œil comme un minuteur qui tourne à 4:22, et la décision qui suit (« ça fait
   quatre minutes, je redonne ») est alors prise sur un chiffre qui a cessé d'avancer. C'est le
   seul endroit du produit où un chiffre commande un geste médicamenteux.
   DEUX CAUSES, UNE SEULE PHRASE : s'il TOURNAIT à l'enregistrement, l'arrêt date de `savedAt` et
   l'on nomme le motif (« application fermée ») ; s'il était déjà en pause, on reprend l'heure de
   cette pause. Un instantané ANTÉRIEUR à ces deux champs retombe sur `savedAt` : au pire la durée
   annoncée est trop COURTE, jamais inventée. */
/* ═══ P8 — L'ÉCART ENTRE DEUX GESTES DU MÊME OBJET (v5.7, décision de l'auteur : « juste
   l'écart sans analyse ») ══════════════════════════════════════════════════════════════════
   Au débriefing, la question posée est presque toujours « combien de temps entre les deux ? »,
   et on la soustrait à la main sur le papier. La colonne la donne.
   ⚠ LA LIGNE À NE PAS FRANCHIR EST PROCHE, ET C'EST POUR ÇA QUE CELLE-CI EST NUE : un écart
   BRUT est un fait. Une MOYENNE, un « intervalle cible », une couleur qui vire au rouge au-delà
   d'une valeur, ou le mot « conformité » feraient basculer le document du côté de l'ÉVALUATION
   PAR LE LOGICIEL — ce que le § 2 de docs/deploiement-et-conformite.md nomme comme le vocabulaire
   à ne jamais employer. Aucune de ces choses n'est calculée ici, et aucune ne doit l'être.
   · L'ÉCART EST PAR OBJET, jamais entre deux repères quelconques : « 3:56 » n'a de sens qu'entre
     deux doses du MÊME produit. Un repère sans référence (une note libre) n'ouvre pas de série.
   · UN REPÈRE ANNULÉ NE COMPTE PAS et ne coupe pas la série : il est resté dans la chronologie
     (c'est une décision qui a eu lieu), mais l'écart se mesure entre les gestes qui TIENNENT.
   PURE, et elle suppose les évènements déjà triés — c'est le cas à son seul site d'appel. */
```

## J36 — Photographie de l'état vivant -> objet session persistable. live=true tant que la session est « en c

```
// Photographie de l'état vivant -> objet session persistable. live=true tant que la session est « en cours ».
/* TEXTE DES ÉTAPES TOUCHÉES — archivé AVEC la session (v5.0.0, lot T1).
   POURQUOI. Une clé de cochage vaut `visite:bloc:INDEX`, et le compte rendu la résolvait contre la
   fiche ACTUELLE. Mesuré : après une simple insertion d'étape en tête de bloc, la clé `1:b1:2` ne
   désigne plus « ⚠ Adrénaline IM » mais « Appeler à l'aide » — et un enregistrement de soin archivé
   nomme donc LE MAUVAIS GESTE, en silence. Le défaut est ancien ; MK5-b (v4.64.0) l'a rendu
   atteignable en deux taps, puisque réordonner une étape est désormais un geste ordinaire.
   CE QU'ON ARCHIVE, ET RIEN DE PLUS : le texte des étapes RÉELLEMENT touchées — cochées, constatées
   ou en écart — plus le titre de leur bloc. Pas la fiche entière : une session doit rester légère,
   et ce qu'on n'a pas touché n'a pas à être figé.
   OÙ ÇA NE VA PAS : `SESS_LOCAL`. Ce texte est du contenu CLINIQUE ; il ne monte donc jamais vers le
   serveur, exactement comme la trace do-verify depuis la v4.54.0, et le drapeau posé à sa place dit
   au compte rendu distant que les libellés sont restés sur l'appareil qui les a produits. */
```

## J37 — MARQUER À POUSSER — ICI, ET NULLE PART AILLEURS (v4.54.2).

```
/* MARQUER À POUSSER — ICI, ET NULLE PART AILLEURS (v4.54.2).
   `_pushTable` ne pousse QUE les objets portant `dirty`. Aucun site n'en posait sur une session :
   l'historique synchronisé de la v4.54.0 ne montait donc RIEN, ni les sessions antérieures à
   l'activation, ni celles terminées après. La fonctionnalité était livrée, la table était créée,
   les politiques étaient vertes — et pas une ligne ne partait.
   Le marquage vit au point d'étranglement de l'ÉCRITURE, exactement comme l'émission du partage
   vit dans `persistLive` : toute modification de session y passe déjà, donc toute mutation ajoutée
   demain sera couverte sans qu'on ait à y penser. Marquer une session VIVE est sans effet —
   `_pushSessions` ne retient que les archivées — mais c'est l'écriture finale, celle qui la rend
   archivée, qui compte, et elle passe par ici.
   `updatedAt` est posé au même endroit : `_pushTable` s'en sert comme horloge de résolution, et
   une session n'en portait pas (elle n'avait que `savedAt`, qui ne bouge plus après l'archivage —
   un renommage n'aurait donc jamais gagné contre la copie distante). */
```

## J38 — Démarre la session de la fiche active DÈS la 1ʳᵉ action (cocher / minuteur / compteur / horodatage).

```
// Démarre la session de la fiche active DÈS la 1ʳᵉ action (cocher / minuteur / compteur / horodatage).
// Renvoie true si elle vient de démarrer (le caller fait alors un render pour afficher le bandeau).
/* `aidRev` — LA RÉVISION DE L'AIDE RÉELLEMENT LUE PENDANT LE SOIN (v5.0.0).
   La spécification v4 écrit « aidRev + texts réparent le défaut mesuré » ; le lot T1 n'avait
   livré que `texts` — un compte rendu ne nommait plus le mauvais geste, mais il ne disait
   toujours pas SUR QUELLE VERSION de la fiche le soin avait été conduit. Deux relectures d'un
   même dossier, à six mois d'écart et sur une fiche révisée entre-temps, n'avaient aucun moyen
   de le savoir.
   ON N'INVENTE PAS UN NUMÉRO : `updatedAt` EST la révision — il change à chaque écriture, il est
   déjà stocké, il est déjà synchronisé, et les points de version (`backups`) portent le même
   horodatage, donc on retrouve la version exacte. Un compteur maison serait un second mécanisme
   pour la même chose.
   CAPTURÉE AU DÉMARRAGE, ET NON AU SNAPSHOT : c'est la révision qu'on a EUE SOUS LES YEUX. La
   question ne se pose d'ailleurs qu'une fois — ouvrir l'éditeur TERMINE la session (K5), donc la
   fiche ne peut pas changer sous une session vive. */
```

## J39 — K5 — « ▶ ESSAYER » : UNE SESSION QUI NE LAISSE RIEN (v4.72.0)

```
  /* ═══ K5 — « ▶ ESSAYER » : UNE SESSION QUI NE LAISSE RIEN (v4.72.0) ═══════════════════════
     L'aperçu refusait TOUTE session : on regardait un rendu inerte, donc on ne pouvait pas voir
     ce qu'on venait d'écrire se COMPORTER — or c'est précisément ce que l'auteur doit vérifier
     (une décision mène-t-elle où je crois ? le minuteur sonne-t-il au bon moment ?).
     La session démarre donc, marquée `essai`, et l'étanchéité tient en TROIS points et trois
     seulement, tous en tête des fonctions qui écrivent :
       · ici — elle n'entre PAS dans `liveSessions` (aucune reprise, aucun bandeau d'accueil) ;
       · `persistLive` — sort AVANT `shareEmitDiff` : rien sur le disque, rien sur le fil ;
       · `endSession` — arrête les minuteurs et s'en va, sans rien archiver.
     CE N'EST PAS LE MODE EXERCICE, et il ne faut pas les confondre : l'exercice est une
     répétition RÉELLE, enregistrée, ségrégée dans l'historique et restituée au débriefing — il
     porte sur une fiche publiée. L'essai porte sur un BROUILLON qu'on est en train d'écrire ;
     il n'a rien à restituer à personne. */
```

## J40 — DOCTRINE DU REPLI DE L'ÉTAPE ① (QRH/ECAM — audit v4.4.2, ne pas « simplifier ») :

```
  /* DOCTRINE DU REPLI DE L'ÉTAPE ① (QRH/ECAM — audit v4.4.2, ne pas « simplifier ») :
     un démarrage IMPLICITE (cocher une étape, lancer un minuteur, incrémenter un compteur,
     horodater) ne replie JAMAIS « Confirmation diagnostique » — on FIGE l'état ouvert.
     Deux raisons, chacune suffisante :
      1. SCROLL — le repli retirerait 240 à 500 px AU-DESSUS du doigt. renderKeepAnchor ne peut
         compenser que si window.scrollY >= hauteur retirée : en haut de fiche, sur une page
         courte ou non défilable (desktop, tablette), la compensation est impossible et le
         contenu saute — c'est le bug v4.3.2, en pire (le tap suivant pourrait cocher une AUTRE
         étape en pleine réanimation).
      2. DOCTRINE — cocher une étape de PRISE EN CHARGE n'acquitte rien sur le DIAGNOSTIC :
         replier ① serait une action non commandée du système, retirant sous les yeux une
         information qu'on est peut-être en train de lire à voix haute.
     Le repli est réservé aux gestes qui l'ACQUITTENT explicitement : le bouton « Confirmé —
     démarrer la session », et la première navigation « Continuer → » (qui déplace déjà le
     contexte à la demande de l'utilisateur, cf. bindReadEvents). Session REPRISE : replié
     d'emblée (openRead remet state.confOpen à undefined). */
```

## J41 — Reprise d'un minuteur d'intervalle DÉJÀ TERMINÉ (non bouclé) = nouveau cycle (repart du plein) —

```
// Reprise d'un minuteur d'intervalle DÉJÀ TERMINÉ (non bouclé) = nouveau cycle (repart du plein) —
// sinon « Relancer » semble ne rien faire (le temps est déjà à 0).
/* ⚠ L'ACQUITTEMENT NE SURVIT PAS À UN NOUVEAU DÉPART (v5.6). Un minuteur relancé puis échu à
   nouveau est une NOUVELLE alarme : la garder silencée parce qu'on avait acquitté la précédente
   serait le pire mode de défaillance d'un annonciateur. Le drapeau tombe donc aux DEUX points
   qui remettent le minuteur en marche — armer et remettre à zéro —, et nulle part ailleurs. */
/* ══ LE MINUTEUR ARMÉ REJOINT LA CAPSULE — ET IL DIT D'OÙ IL VIENT (v5.6, planche 10d/3) ═══════
   Le segment apparaît en HAUT alors que le geste a lieu en BAS, dans le volet : rien ne relie les
   deux, et l'on découvre le minuteur au tour d'œil suivant. 140 ms d'opacité + `scaleY`, une fois.
   ⚠ LE DRAPEAU EST À USAGE UNIQUE, et c'est la condition qui rend l'animation admissible : la
   capsule est RECONSTRUITE à chaque seconde par `updateRtStrip` — une classe posée à demeure
   rejouerait l'entrée toutes les secondes, c'est-à-dire exactement le mouvement non commandé
   qu'A68/1 interdit, et sur la zone qui ne quitte jamais l'écran (précédent `_tkFresh`, A90).
   ⚠ ET UN SEGMENT ÉCHU N'Y A PAS DROIT : l'alarme a sa propre grammaire (elle PULSE). Lui prêter
   l'entrée douce du nominal mêlerait deux registres dans la seule zone où l'ECAM réserve le
   mouvement à l'alerte. */
```

## J42 — R6 (v5.10.3) — LE TICK EST GATÉ, PAS RALENTI. Mesuré avant de toucher (l'exigence de la

```
  /* R6 (v5.10.3) — LE TICK EST GATÉ, PAS RALENTI. Mesuré avant de toucher (l'exigence de la
     Phase 3 sur cette boucle) : une fiche simplement OUVERTE, sans session, payait le tick
     complet 3,3 fois par seconde — 40 appels inutiles en 3 s (refreshTimersDOM, paintCnAgo,
     updateRtStrip, monRender) alors qu'AUCUNE valeur de temps n'y vit : un minuteur ne peut pas
     tourner sans session. La condition devient « une session AFFICHE du temps » : sessions vives
     (hôte, exercice), essai K5 (Runtime.started sans liveSessions), invité (miroir Share).
     ⚠ LA CADENCE, ELLE, NE BOUGE PAS : 300 ms borne le retard d'affichage d'un passage de
     seconde à 300 ms (mesuré : 79-288 ms) QUEL QUE SOIT le déphasage des minuteurs. Un réveil
     « aligné sur la seconde », envisagé, a été REJETÉ AU CALCUL : chaque minuteur franchit SA
     seconde à sa propre phase (démarré à t+0,7 s → bascule à x,7 s), un réveil calé sur
     l'horloge murale afficherait ce changement jusqu'à UNE seconde en retard — la granularité
     que la cadence achète ne se négocie pas. */
```

## J43 — Rappel MINUTEURS dans l'en-tête sticky (chrono #cbTimers du bandeau de crise) : en mode crise, dès q

```
/* Rappel MINUTEURS dans l'en-tête sticky (chrono #cbTimers du bandeau de crise) : en mode crise, dès qu'un minuteur tourne et
   que le panneau minuteurs est sorti de l'écran (on a déroulé les étapes), l'en-tête affiche le
   temps restant/écoulé en permanence — le cas d'usage cardinal (« adrénaline / 5 min ») ne doit
   jamais exiger de remonter la page pour LIRE le temps. Tap -> re-scrolle au panneau. */
// `_rtShowDirty` SUPPRIMÉ en v4.44.0 (règle 14). C'était un cache d'invalidation pour ne relire la
// géométrie du panneau minuteurs qu'après un défilement, un redimensionnement ou un re-rendu — le
// commentaire d'origine décrivait fidèlement cette intention. Mais le drapeau était ÉCRIT quatre
// fois et LU zéro fois : deux écouteurs globaux (`scroll`, `resize`) tournaient pour maintenir une
// valeur que personne ne consultait. Le mécanisme a dû perdre son lecteur lors d'une refonte du
// quai, et le commentaire a survécu à la logique qu'il expliquait — il affirmait donc une
// optimisation qui n'existait plus. Ne pas « réparer » en réintroduisant un lecteur sans mesure :
// la Phase 3 a chronométré ce que coûte réellement la relecture de géométrie du quai (0,5 ms/s de
// mise en page pour le tick complet, gain d'un cache : 0,10 ms/s). Il n'y a rien à gagner ici.
// FUSIONNÉ dans le bandeau de crise : le chrono compact #cbTimers (à droite du bandeau) reprend
// le rôle de l'ancien rappel #rtStrip — visible quand un minuteur tourne ET que le panneau
// minuteurs est sorti de l'écran ; tap -> remonte au panneau. Un seul bloc d'état dans la barre.
/* P3 — la trace d'un compteur avance avec le tick. Chirurgical : on ne réécrit que si la
   chaîne a changé (anti-churn, patron de `barTf`), et jamais la carte entière. */
/* ═══ Q2 — « Reprise — dernier geste il y a … » ════════════════════════════════════════
   Vérifié avant d'écrire : ZÉRO occurrence d'un « temps depuis le dernier geste » dans le
   fichier. Les cinq écouteurs de `visibilitychange` persistaient, reprenaient l'audio,
   redemandaient la veille — aucun ne disait à quelqu'un qui revient depuis combien de temps
   il n'était plus là. Or c'est le cas nominal : on pose le téléphone, on intube, on transporte.
   · PAS DE MODALE, PAS DE SON, PAS DE DÉFILEMENT (règle 11) — une ligne, dans la carte du bloc
     courant, c'est-à-dire à l'endroit où le regard revient.
   · A9 : le retour au premier plan EST un geste de l'utilisateur, la ligne a donc le droit de
     paraître. Et elle ne pousse rien d'autre qu'elle-même : elle s'insère en TÊTE de la carte,
     au-dessus de l'en-tête, jamais entre deux étapes.
   · AUCUN SEUIL CLINIQUE : deux minutes est un seuil d'AFFICHAGE, qui évite d'annoncer une
     absence de quinze secondes. Rien ne change de couleur avec la durée, rien ne se déclenche.
   · Le texte est FIGÉ à l'instant du retour : c'est la durée de l'interruption qu'on annonce,
     pas un second chronomètre — il y en a déjà assez à l'écran. */
```

## J44 — ⚠ QUATRE REPROCHES, UN SEUL OBJET (v5.7, signalé à l'usage : « très mauvaisement implanté

```
/* ⚠ QUATRE REPROCHES, UN SEUL OBJET (v5.7, signalé à l'usage : « très mauvaisement implanté
   niveau design, s'affiche collé à la bordure en haut à gauche ; le temps ne bouge pas ; très
   difficile de comprendre ce que c'est, d'où ça vient et comment faire pour que ça parte ; et
   pourquoi l'icône ne passe pas par uiIcon ? »). Tous justes, et le premier explique le reste :
   c'était un `<div>` de texte NU inséré avant `.ov-head`, donc HORS du rembourrage de la carte —
   un objet sans boîte n'a l'air de rien, donc n'explique rien.
   · UNE RANGÉE, DANS LE REMBOURRAGE DE LA CARTE, séparée du titre par un filet : la même
     grammaire que tout ce qui vit dans une carte de bloc.
   · LE NOMBRE VIT. A117 le figeait « pour ne pas ajouter un second chronomètre » — mais un
     nombre figé qui dit « il y a 6:12 » MENT dès la minute suivante, et c'est la donnée périmée
     présentée comme vivante que ce dossier combat partout. Ce qu'on annonce est « depuis combien
     de temps rien n'a été fait », et cela CROÎT tant que rien n'est fait. Aucune hauteur ne
     change (A9), et le tick le peint déjà pour les compteurs.
   · ELLE DIT D'OÙ ELLE VIENT : « après une interruption », en toutes lettres.
   · ET ELLE A UNE SORTIE : un ✕. Elle s'effaçait au geste suivant — vrai, mais invisible : rien
     ne le disait, et quelqu'un qui veut juste s'en débarrasser n'a pas à deviner qu'il faut
     cocher une étape. Le geste reste la sortie NATURELLE ; le ✕ est la sortie EXPLICITE.
   · GLYPHE TRACÉ (`uiIcon`), jamais le caractère « ⏱ » — règle A106. */
```

## J45 — P1 — LA BARRE DE RETOUR AU BLOC COURANT (v5.7)

```
/* ═══ P1 — LA BARRE DE RETOUR AU BLOC COURANT (v5.7) ═══════════════════════════════════
   Elle n'existe que tant que la carte du bloc courant est ENTIÈREMENT hors de la zone utile
   (sous les couches collantes, au-dessus du dock) — pas quand elle dépasse à moitié : on ne
   l'a pas perdue, on la regarde de biais.
   · UN OBSERVATEUR, PAS UN ÉCOUTEUR DE DÉFILEMENT : rien à calculer par image, et le navigateur
     fait le travail. Les marges de racine reprennent `stickBase()` et la hauteur MESURÉE du dock
     (--dock-h), donc la zone utile est celle qu'on voit vraiment.
   · IDEMPOTENT : on ne réinstalle l'observateur que si la carte a changé — la fonction est
     appelée à chaque tick, elle doit donc être gratuite quand rien ne bouge.
   · ELLE NE DÉFILE JAMAIS TOUTE SEULE (règle 11) : c'est une PORTE, pas un rappel à l'ordre. */
/* ⚠ ELLE NE CLIGNOTE PAS À CHAQUE RE-RENDU (v5.7, signalé à l'usage : « à chaque fois que la vue
   se met à jour, le bandeau vert s'affiche quelques ms, c'est moche et très perturbant »).
   La clé d'idempotence était le NŒUD de la carte — or tout rendu du journal le remplace. On
   reconstruisait donc la barre à chaque fois : l'HTML était écrit alors que `hidden` valait encore
   sa valeur d'AVANT, l'observateur ne rendant son verdict qu'à l'image suivante. Mesuré :
   `hidden=false` → HTML → `hidden=true`, soit une image ou deux de barre peinte pour rien, avec
   son animation d'entrée rejouée par-dessus.
   LA CLÉ PORTE DONC LE CONTENU (identité du bloc + libellé), pas le nœud :
    · contenu inchangé -> on se contente de RÉ-OBSERVER le nouveau nœud. Aucune écriture, donc
      aucun clignotement et aucun rejeu d'animation — la barre reste exactement dans l'état où
      l'observateur l'avait laissée ;
    · contenu changé   -> on MASQUE D'ABORD, on peint ensuite. Une barre neuve ne peut plus
      apparaître avant que l'observateur ait dit qu'elle doit exister. C'est le même principe que
      « l'état est appliqué d'abord, l'animation le décore » (A68/2), pris par l'autre bout.
   ⚠ LE COMPTE EST HORS DE LA CLÉ, et se peint sur place : il change à chaque coche, et l'inclure
   aurait rendu la barre à son clignotement au premier geste — le défaut signalé, par une autre
   porte. Même anti-churn que `paintCnAgo`. */
```

## J46 — ⚠ UN NŒUD DÉTACHÉ N'EST PAS « HORS ZONE », IL N'EST PLUS LÀ — ET C'ÉTAIT TOUTE LA CAUSE

```
/* ⚠ UN NŒUD DÉTACHÉ N'EST PAS « HORS ZONE », IL N'EST PLUS LÀ — ET C'ÉTAIT TOUTE LA CAUSE
   (v5.7). Entre un re-rendu du journal et le prochain passage de `syncBlkReturn`, l'observateur
   surveille encore l'ANCIENNE carte, désormais détachée : un élément détaché ne coupe aucune
   zone, donc `isIntersecting` vaut FAUX, donc la barre s'affichait — puis disparaissait dès que
   l'observateur était repointé sur la carte neuve. Mesuré : apparition à 146 ms, retrait à 214.
   ⚠ ET DEUX EXPLICATIONS PLAUSIBLES ONT ÉTÉ ÉCARTÉES PAR LA MESURE, dans cet ordre : « la
   première notification porte une géométrie transitoire » (j'ai tranché moi-même en synchrone —
   toujours faux), puis « la page se pose encore » (échantillonnée à 0-300 ms : rTop 243, rBot 802,
   `stickBase` 127, `--dock-h` 72, INVARIANTS). C'est en constatant que rien ne bougeait qu'il est
   devenu clair que le verdict portait sur un autre nœud que celui qu'on regarde.
   On ignore donc les notifications d'un nœud détaché, et `render`/`renderOvOnly` repointent
   l'observateur AU LIEU d'attendre le prochain tick. Aucun délai, aucun seuil : la barre ne peut
   plus se tromper de sujet. */
```

## J47 — Enrichissement d'un minuteur pour les DEUX zones d'état — le quai `#cbTimers` et la bande du

```
  /* Enrichissement d'un minuteur pour les DEUX zones d'état — le quai `#cbTimers` et la bande du
     mode lecteur `#rmTimers`. Source unique depuis v4.45.0 : le calcul du temps restant (qui sert
     au TRI : échus d'abord, puis les plus urgents) était écrit DEUX FOIS, à l'identique, et le
     prédicat « échu » y était rédigé de DEUX FAÇONS DIFFÉRENTES — `dueDone(t)||(interval &&
     val==='00:00')` d'un côté, `interval && val==='00:00'` de l'autre. Les deux sont équivalents,
     et la démonstration mérite d'être écrite parce qu'elle n'est pas évidente : `dueDone` impose
     déjà `type==='interval'`, et un minuteur échu et arrêté donne `within >= per`, donc
     `fmtMs(max(0, per-within))` vaut « 00:00 » — le premier disjoint est absorbé par le second.
     L'extraction est donc ISO-SORTIE, pas une harmonisation qui trancherait entre deux règles.
     Une FONCTION appliquée deux fois, jamais un tableau partagé : chaque zone garde son propre
     tri et sa propre troncature, et rien n'est mutable en commun. */
```

## J48 — CE QUE PORTE LE QUAI (v4.23.0, décision utilisateur) :

```
  // CE QUE PORTE LE QUAI (v4.23.0, décision utilisateur) :
  //   < 1000px : le chrono de session, UN minuteur étiqueté (l'échu / le plus urgent) et « +n ».
  //   ≥ 1000px : le rail droit porte DÉJÀ tous les minuteurs, avec leurs grands chiffres et leurs
  //     boutons — les répéter ici ferait deux sources pour la même valeur. Le quai ne garde que ce
  //     qui doit vivre dans une zone de statut FIXE : l'état de session et l'ALARME (un minuteur
  //     échu). La redondance de l'alarme à deux endroits est VOULUE ; celle du nominal, non.
  /* ⚠ UN MINUTEUR ACQUITTÉ RESTE ÉCHU, IL CESSE SEULEMENT D'ANNONCER (v5.6, signalé à l'usage :
     « un minuteur sans relance, une fois échu, s'affiche dans le bandeau session et tout, c'est
     super ; mais aucun moyen de le faire disparaître que de le relancer »).
     La doctrine v4.2.0 dit « acquittement par l'ACTION » — relance ou réarmement —, et elle a
     raison sur le fond : une alarme ne se referme pas d'un revers de main. Mais elle ne prévoyait
     qu'UNE façon d'agir, or l'action juste est parfois « c'est noté, je n'ai pas besoin de ce
     minuteur ». C'est exactement le master caution de l'ECAM : on l'acquitte à SA station, la
     panne reste écrite sur l'écran. L'ÉTAT ne change donc pas — la carte continue de dire
     « échu », le compte rendu aussi ; seule l'ANNONCIATION du quai se tait.
     ⚠ ET C'EST LOCAL, DÉLIBÉRÉMENT : acquitter est un geste de STATION. Rien ne diverge, puisque
     l'état du minuteur est inchangé — c'est la même panne, silencée ici et pas là-bas, ce que
     fait tout acquittement d'alarme. */
```

## J49 — PLACE DISPONIBLE EN ÉTROIT (v4.23.0) : passé l'heure, le chrono de session s'écrit h:mm:ss et

```
  /* PLACE DISPONIBLE EN ÉTROIT (v4.23.0) : passé l'heure, le chrono de session s'écrit h:mm:ss et
     occupe presque la largeur d'un segment entier. Deux segments étiquetés ne tiennent alors plus
     sous ~430px : le quai débordait et ROGNAIT (or une zone d'état n'ampute jamais un nombre —
     et le « +n » existe précisément pour annoncer ce qu'elle ne montre pas). Dans ce cas on ne
     garde un segment de minuteur QUE s'il est ÉCHU : l'ALARME prime sur le nominal, qui reste
     compté dans « +n » et accessible d'un tap sur le quai. */
  /* ⚠ P4 (v5.7) — L'IMMINENT ENTRE DANS LA CAPSULE EN VOIE LARGE, ET C'EST UN AJOUT À LA
     DOCTRINE DE LA v4.23.0, PAS UN OUBLI QU'ON RATTRAPE. Cette doctrine dit : au-delà de 780 px
     le rail porte DÉJÀ tous les minuteurs, les répéter au quai ferait deux sources pour une même
     valeur — et elle réserve l'exception à l'ALARME, dont la redondance est VOULUE.
     L'imminence appartient à cette exception : c'est l'annonce d'une alarme qui va survenir, et
     l'argument qui fonde l'exception vaut mot pour mot ici — le rail DÉFILE, donc le minuteur qui
     va sonner peut être sous la ligne de flottaison. Sans cela le marquage était INERTE au-delà
     de 780 px, ce qui est pire qu'absent : un signal qu'on croit avoir et qu'on n'a pas.
     ⚠ ET « +n » NE CHANGE PAS : il ne compte que les ÉCHUS non montrés (`pool=dueList`). Un
     imminent n'est pas une alarme ; s'il ne tient pas, c'est le rappel du chevron qui l'annonce. */
```

## J50 — LA COULEUR ÉTAIT SEULE DANS LA ZONE LA PLUS CRITIQUE DE L'APP (correctif). AGENTS.md décrit le

```
  /* LA COULEUR ÉTAIT SEULE DANS LA ZONE LA PLUS CRITIQUE DE L'APP (correctif). AGENTS.md décrit le
     quai comme portant « le segment échu en ambre + le mot “échu” » : c'était FAUX ici — seuls le
     LIBELLÉ et la VALEUR étaient écrits, le mot n'existant que dans la bande du mode lecteur
     (`.rm-seg`, ci-dessus). L'échu du quai se distinguait donc d'un minuteur nominal par la seule
     teinte, ce que la règle 8 interdit (et le « 00:00 » ne dit rien : un chrono à peine armé
     l'affiche aussi).
     LE MOT NE PEUT PAS ÊTRE ÉCRIT EN CLAIR ICI, et le mesurer l'a montré : `.seg-l` est en
     `overflow:hidden;text-overflow:ellipsis` — un « — échu » SUFFIXÉ serait le premier à être
     rogné, donc absent précisément sur les écrans où la place manque ; et à 320 px le quai n'a
     qu'un pixel de marge, si bien qu'allonger le segment le ferait EXPULSER par la boucle
     d'ajustement : on perdrait l'alarme entière pour avoir voulu la nommer.
     D'où le patron DÉJÀ retenu par le projet pour les étapes signalées (`stepTxtHtml` : glyphe
     visible + étiquette `.sr-only`) : le `△` en PRÉFIXE — il survit à l'ellipse — porte le second
     canal visuel pour ~14 px, et le mot part au lecteur d'écran. */
  /* ⚠ LU ICI, CONSOMMÉ QUAND LE SEGMENT EST PEINT — pas avant (trouvé à la mesure). Le brûler à
     la lecture le perdait dans deux cas : la sortie anticipée quand la capsule n'a rien à montrer,
     et surtout la passe d'ajustement qui CACHE le segment faute de place — le rattrapage de la
     passe suivante le faisait alors apparaître sans son entrée. Un drapeau d'animation se
     consomme au moment où l'animation a lieu, jamais au moment où on le regarde. */
```

## J51 — DÉBORDEMENT JAMAIS SILENCIEUX (ECAM, v4.23.0) : une zone d'état ne peut pas cacher une

```
  // DÉBORDEMENT JAMAIS SILENCIEUX (ECAM, v4.23.0) : une zone d'état ne peut pas cacher une
  // alarme sans le dire. En étroit le quai porte tous les minuteurs (« +n » sur le reste) ; en
  // large il ne porte que les ÉCHUS, plafonnés à deux — au-delà, « +n » compte les échus NON
  // MONTRÉS (le rail droit les affiche en grand, mais il DÉFILE : le 3ᵉ peut être sous la ligne
  // de flottaison, donc le quai doit l'annoncer). Le décompte suit toujours la liste affichée.
  /* ⚠ « +n » NE COMPTE QUE LES ÉCHUS NON MONTRÉS (v5.6, signalé à l'usage : « le +n ne s'affiche
     que quand un minuteur arrive à 0 »). Il comptait, en étroit, TOUS les minuteurs armés : deux
     chronomètres nominaux affichaient « +1 » en permanence, c'est-à-dire un chiffre qui ne
     désigne aucune alarme dans la zone où le chiffre EST l'alarme.
     LA PROMESSE ECAM RESTE TENUE, elle a seulement changé de porteur : le débordement NOMINAL est
     annoncé par le rappel du chevron (« 1 minuteur · 1 compteur »), qui dit ce qui est caché en
     toutes lettres, et « +n » redevient ce qu'il doit être — l'annonce d'une ALARME qu'on ne peut
     pas montrer. Les deux ne coexistent jamais : le rappel ne paraît que s'il n'y a pas de « +n ». */
```

## J52 — LA VALEUR SORT DE LA CHAÎNE DE STRUCTURE (v5.0.0, question utilisateur : « n'y a-t-il pas

```
  /* LA VALEUR SORT DE LA CHAÎNE DE STRUCTURE (v5.0.0, question utilisateur : « n'y a-t-il pas
     moyen de ne réécrire que les parties qui comptent ? » — si, et c'était mesurable).
     MESURÉ AVANT : le quai remplaçait TOUT son sous-arbre 2 fois par seconde (36 nœuds détruits
     en 6 s), parce que la chaîne comparée à `_rtsHtml` contenait les TEMPS, qui changent à chaque
     tick. La garde `h!==_rtsHtml` était donc vraie en permanence dès qu'un chrono tournait.
     C'est ce qui interdisait d'y loger un contrôle : entre le `pointerdown` et le `click`, le
     nœud sous le doigt pouvait avoir été détruit et recréé — le clic tombait dans le vide.
     DÉSORMAIS : la structure (segments présents, libellés, « +n », chevron) est comparée SANS les
     valeurs ; les valeurs sont peintes séparément, par `textContent`, et seulement si elles ont
     changé. La structure ne bouge donc que lorsqu'elle change VRAIMENT — un minuteur armé ou
     arrêté, un franchissement de palier, une alarme qui paraît. */
```

## J53 — LE QUAI NOMME CE QU'IL CACHE — MAIS SEULEMENT QUAND IL NE MONTRE RIEN D'AUTRE (v5.0.0).

```
  /* LE QUAI NOMME CE QU'IL CACHE — MAIS SEULEMENT QUAND IL NE MONTRE RIEN D'AUTRE (v5.0.0).
     [v5.4.2 : la rangée `.rt-collapsed` évoquée ci-dessous N'EXISTE PLUS — le quai est devenu
     l'accès unique au panneau en étroit, ce qui renforce d'autant ce rappel : il est désormais
     le SEUL canal qui annonce minuteurs et compteurs cachés. Le raisonnement historique reste.]
     La rangée `.rt-collapsed` disait déjà, dans le FLUX, « Minuteurs & compteurs · 1 minuteur ·
     1 compteur ▾ Afficher » — visible sans défiler à l'ouverture (mesuré y=408 pour un pli à 844).
     Ce n'est donc PAS l'information qui manquait, et le constat J0 qui l'affirmait était faux.
     Ce qui manque est ailleurs, et c'est une mesure DIFFÉRENTE : cette rangée VIT DANS LE FLUX, donc
     elle s'en va (mesurée à y=−292 après 700 px de défilement) — alors que le quai, lui, ne quitte
     jamais l'écran et ne disait rien. Le seul canal PERMANENT était muet.
     CE N'EST PAS LA DUPLICATION QUE LA v4.70.1 PROSCRIT : elle vise deux canaux qui énoncent la
     même CONSTANTE en même temps, à demeure (« ■ CRISE » en barre et « ■ MODE CRISE » en bandeau).
     Ici c'est un RELAIS, exactement comme le titre passe du bandeau à la barre au défilement — et
     le recouvrement ne dure que le temps où la rangée est encore à l'écran.
     TROIS BORNES, et ce sont elles qui rendent la chose admissible :
       · JAMAIS UN SEGMENT — le libellé habille le chevron EXISTANT, donc zéro pixel de hauteur et
         aucun déplacement de l'alarme (la constance positionnelle ECAM est intacte) ;
       · SEULEMENT QUAND LE QUAI NE PORTE AUCUN MINUTEUR (`!want.length`) — dès qu'un minuteur est
         armé, son segment reprend la place et le comportement d'avant est rendu au pixel. Les deux
         sont mutuellement exclusifs par construction : le libellé ne peut pas concurrencer l'alarme ;
       · IL TOMBE LE PREMIER — c'est un rappel, pas une annonce ECAM ; la boucle d'ajustement le
         sacrifie avant tout le reste, « +n » et segment échu compris. */
```

## J54 — ⚠ LE RAPPEL NE PARAÎT QUE SI LE QUAI NE MONTRE AUCUN MINUTEUR, et cette borne tient toujours

```
  /* ⚠ LE RAPPEL NE PARAÎT QUE SI LE QUAI NE MONTRE AUCUN MINUTEUR, et cette borne tient toujours
     (v5.6 : je l'avais élargie en même temps que « +n », et le témoin a eu raison de rougir — un
     minuteur ARMÉ doit reprendre la place du rappel, sinon deux annonces se disputent la même
     largeur et c'est le SEGMENT qui tombe). Ce qui a changé n'est que le contenu de « +n » : il
     ne compte plus que les ÉCHUS non montrés. Un minuteur nominal caché n'est donc plus annoncé
     par un chiffre — il l'est par le chevron, qui ouvre le volet où ils sont tous. */
  /* ⚠ LE RAPPEL COMPTE CE QUI N'EST PAS MONTRÉ, PAS CE QUI N'EST PAS VOULU (v5.6, trouvé à la
     mesure en posant l'entrée du segment). Sa condition était `!want.length` — « aucun minuteur
     ne prend la place ». Or `want` est ce que le quai VEUT montrer, pas ce qu'il montre : la
     boucle d'ajustement retire des segments quand la place manque, et à 390 px un minuteur
     NOMINAL armé était retiré sans un mot — « +n » ne compte que les ÉCHUS depuis la v5.6, et le
     rappel se taisait parce que le minuteur était « voulu ». Mesuré : capsule à 362 px, segment
     absent, zéro annonce. C'est la promesse ECAM prise en défaut dans la seule zone qui ne quitte
     jamais l'écran — « une zone d'état annonce toujours ce qu'elle cache ».
     Le compte dépend donc du nombre RÉELLEMENT peint, que seule la boucle connaît : le libellé
     devient une fonction de `n`. À `n=0` il rend exactement ce qu'il rendait (`decl.t-0`), donc le
     cas nominal est inchangé au caractère près ; à `n=1` le minuteur montré ne se compte plus —
     il ne peut toujours pas concurrencer son propre segment. */
  /* ⚠ CORRECTIF À ZÉRO PIXEL (v5.7, volet 3) — UN MINUTEUR ARMÉ PUIS MIS EN PAUSE EST MUET.
     Le rappel comptait les minuteurs DÉCLARÉS ; il ne distinguait pas celui qu'on a lancé puis
     arrêté de celui qu'on n'a jamais démarré. Or le premier est le cas dangereux : il ne figure
     dans AUCUN segment de la capsule (`run` filtre sur `running || (échu && !ack)`), il n'a pas
     d'alarme à venir, et il n'existe donc nulle part sans ouvrir le volet — alors qu'il porte un
     temps qui a cessé d'avancer, ce que le produit combat partout ailleurs (A81).
     Le mot ET le glyphe (règle 8), dans un libellé qui est de toute façon le PREMIER sacrifié par
     la boucle d'ajustement : aucune alarme ne peut lui être disputée. */
```

## J55 — ORDRE (v4.23.0, décision utilisateur) : « ● Session » ANCRÉ EN TÊTE, puis l'alarme / le

```
  // ORDRE (v4.23.0, décision utilisateur) : « ● Session » ANCRÉ EN TÊTE, puis l'alarme / le
  // minuteur, puis « +n », puis le chevron. Le chrono de session était placé APRÈS les minuteurs :
  // sa position glissait donc à droite dès qu'un minuteur apparaissait, à gauche quand il
  // disparaissait. Or la règle cardinale d'une zone de statut ECAM est la CONSTANCE POSITIONNELLE
  // (on apprend où regarder, l'œil y va sans lire) ; une valeur qui bouge doit être re-cherchée.
  // Le chrono est le seul élément TOUJOURS présent : c'est lui l'ancre. L'alarme n'a pas besoin
  // de la 1ʳᵉ place pour être saillante — elle a déjà la teinte ambre, le mot « échu », le flash
  // et le son.
  /* AJUSTEMENT MESURÉ (v4.23.0) — « une zone d'état n'ampute jamais un nombre ». Passé l'heure le
     chrono s'écrit h:mm:ss et, avec un segment de minuteur, le quai débordait donc ROGNAIT ses
     chiffres. Des seuils de largeur en dur se sont montrés faux (320 et 430 débordaient encore) :
     on MESURE. On écrit la version voulue, et tant qu'elle déborde on RETIRE un segment — il n'est
     pas perdu, il repasse dans « +n » (annonce ECAM) et reste accessible d'un tap.
     La décision ne dépend QUE de la largeur, du nombre de minuteurs et du NOMBRE DE CARACTÈRES
     des valeurs (chiffres tabulaires : même compte = même largeur) — elle est donc mémorisée et
     re-mesurée seulement quand cette clé change, jamais à chaque tic de seconde. */
  /* LA CLÉ ÉTAIT AVEUGLE AUX INTITULÉS (correctif). Elle ne décrivait que la largeur, le nombre de
     minuteurs et le NOMBRE DE CHIFFRES des valeurs — jamais la longueur d'un LIBELLÉ. Renommer un
     minuteur « Cycle de compressions thoraciques » ne changeait donc aucun terme de la clé : la
     boucle ne se re-mesurait pas, le quai débordait, et comme `#cbTimers` est en `overflow:hidden`
     RIEN ne le signalait — ni barre de défilement, ni possibilité de faire glisser. Mesuré à
     320 px : le quai exigeait 119 px de plus que sa largeur, en silence.
     Les intitulés entrent donc dans la clé. Cela ne suffit pas à lui seul : `glob` n'est JAMAIS
     expulsé par la boucle (cf. `write`), donc un libellé de session trop long déborderait même
     re-mesuré — c'est pourquoi il est BORNÉ en code, ci-dessus, plutôt que laissé à la boucle. */
```

## J56 — ══ LA MESURE SE FAIT SUR UN FANTÔME DÉTACHÉ, JAMAIS DANS LE QUAI VIVANT (v5.6)

```
  /* ══ LA MESURE SE FAIT SUR UN FANTÔME DÉTACHÉ, JAMAIS DANS LE QUAI VIVANT (v5.6) ══════════════
     La boucle d'ajustement ÉCRIVAIT ses candidats dans `#cbTimers` pour les mesurer : chaque
     mesure détruisait et recréait les nœuds du quai. C'est ce qui obligeait à MÉMORISER la
     décision — et donc ce qui rendait une mauvaise mesure DÉFINITIVE (mesuré : à géométrie
     identique, un minuteur armé n'apparaissait que 2 fois sur 5, la clé ne capturant pas l'état
     de chargement des polices). Le rattrapage naïf, lui, rouvrait le défaut que la mémoïsation
     empêchait : `audit-doctrine` l'a rougi sur « aucun ÉLÉMENT du quai n'est détruit pendant les
     ticks » — un tap tombe alors dans le vide.
     LE FANTÔME EST UN ENFANT DE `#cbTimers`, et c'est ce qui le rend fidèle sans dupliquer une
     ligne de CSS : les règles du quai sont toutes DESCENDANTES (`#cbTimers .seg` — vérifié, zéro
     combinateur enfant), donc elles s'appliquent à son contenu ; police et couleurs s'héritent par
     l'arbre. Il est en `position:fixed` HORS ÉCRAN : pris hors flux, il n'est pas un item de la
     rangée, n'ajoute aucune zone défilable à quiconque, et ne peut rien recouvrir.
     ⚠ On reproduit les propriétés de CONTENEUR (display, gap, align-items) : elles vivent sur
     `#cbTimers` lui-même, pas sur ses descendants, donc elles ne s'héritent pas. Et la largeur
     mesurée est la boîte de CONTENU (`clientWidth` moins les rembourrages), celle dont disposent
     réellement les segments. */
```

## J57 — ORDRE DE SACRIFICE — DEUX DÉFAUTS CORRIGÉS ICI, tous deux mesurés à 320 px.

```
  /* ORDRE DE SACRIFICE — DEUX DÉFAUTS CORRIGÉS ICI, tous deux mesurés à 320 px.
     1. LE CHEVRON TOMBAIT APRÈS LE DERNIER SEGMENT, jamais avant. La boucle retirait les segments
        un à un et n'essayait « sans chevron » qu'une fois arrivée à ZÉRO segment — c'est-à-dire
        qu'elle sacrifiait le SEGMENT ÉCHU (la seule persistance de l'alarme dans une zone qui ne
        quitte jamais l'écran) pour garder un glyphe `aria-hidden` que le commentaire d'origine
        qualifiait lui-même de « purement décoratif ». On essaie désormais, à CHAQUE palier,
        d'abord avec le chevron puis sans : le décoratif tombe toujours avant l'informatif.
     2. À COURT DE SOLUTIONS, ELLE RÉÉCRIVAIT UN ÉTAT QU'ELLE VENAIT DE MESURER COMME DÉBORDANT.
        Si `write(0,true)` ne tenait pas non plus, `_rtsNoChev` retombait à `false` et l'écriture
        finale REMETTAIT le chevron — strictement pire que ce qui venait d'être testé, et le
        débordement redevenait silencieux (`#cbTimers` est en `overflow:hidden`). Le plancher est
        maintenant explicite : on garde la version la plus étroite connue, on n'en réécrit jamais
        une plus large. Le « +n » n'est JAMAIS sacrifié — c'est l'ANNONCE ECAM. */
  /* ⚠ UNE MESURE SANS MISE EN PAGE NE SE RETIENT PAS — C'ÉTAIT LA CAUSE (v5.6, mesuré).
     `updateRtStrip` peut courir alors que la capsule n'a pas encore de géométrie (largeur nulle :
     premier rendu, ancêtre masqué). Le test « ça tient » répond alors OUI à tout — 0 ≤ 0 — et la
     décision, prise sur du vide, était MÉMORISÉE pour de bon : c'est ainsi qu'un minuteur armé
     restait invisible 3 fois sur 5 à géométrie pourtant identique. On ne mesure donc que si la
     capsule a une largeur, et l'on ne touche PAS à la clé sinon : la passe suivante re-mesurera
     pour de vrai. */
```

## J58 — ⚠ MESURÉ AVANT CORRECTION (v5.0.0) : taper le quai faisait passer `scrollY` de 0 à 1120 px

```
   /* ⚠ MESURÉ AVANT CORRECTION (v5.0.0) : taper le quai faisait passer `scrollY` de 0 à 1120 px
      à 320 px (988 à 390) — le panneau vivait en BAS de la colonne (lot T5), et l'on s'y rendait
      par un `scrollIntoView`. Un tap sur une ZONE D'ÉTAT catapultait donc l'écran d'un écran et
      demi, en pleine session : c'est le défilement automatique que la règle 11 interdit, et
      l'utilisateur perdait de vue le bloc qu'il exécutait.
      LE DÉPLIANT APPARTIENT AU QUAI (maquette) : ouvert PAR LE QUAI, le panneau se rend
      immédiatement SOUS lui, en tête de la colonne d'action — la réponse au geste vit à l'endroit
      du geste (même règle que l'accusé « ✓ noté » du lot M7). Aucun défilement, donc rien ne
      bouge sous le doigt. Ouvert par la rangée du BAS, il s'ouvre en bas, là où on l'a demandé :
      `state.rtOpen` porte l'ENDROIT ('dock' | 'flow'), pas seulement l'état.
      v5.4.1 : le dépliant du quai est devenu un VOLET FIXE (cf. `.rt-dock`) — même mécanique de
      bascule, mais il SUIT le défilement ; `_histArm()` à l'ouverture, comme toute surface qui
      recouvre (doctrine v4.30.0), pour que le retour système le referme au lieu de sortir. */
```

## J59 — Terminer : archive la session (historique, reprenable plus tard), arrête les minuteurs, puis

```
// Terminer : archive la session (historique, reprenable plus tard), arrête les minuteurs, puis
// repart d'une fiche vierge (cochages, compteurs, minuteurs remis à zéro).
/* Dialogue « Terminer la session ? » (SPEC crise §3, v4.3.0) — SEULE porte de sortie d'une
   session (menu ⋯, note de fin d'algorithme, ✕ du bandeau SESSIONS EN COURS) : contexte
   (titre + durée) et conséquences annoncés AVANT le choix ; focus initial sur Poursuivre ;
   Échap / tap hors carte = Poursuivre, jamais Terminer. */
/* ═══ P2 — CE QUI RESTE OUVERT (v5.7) ══════════════════════════════════════════════════
   PURE : elle ne lit que le runtime qu'on lui passe, et ne rend que des FAITS COMPTÉS — des
   cases et des minuteurs, jamais un jugement. Pas de score, pas de pourcentage, pas de
   « conformité » : ce vocabulaire est nommé par le § 2 du dossier de conformité comme celui
   à ne jamais employer. Deux lignes au plus : au-delà, on ne lit plus rien avant de taper.
   ⚠ ON NE COMPTE QUE LES BLOCS VISITÉS : une étape vitale d'un bloc où l'on n'est jamais
   passé n'est pas « oubliée », elle est HORS CHEMIN — la compter ferait paraître incomplète
   toute session qui a pris une branche. */
```

## J60 — ⚠ LE BANDEAU SURVIT AUX MODES D'EXCEPTION, ET SEULEMENT À EUX (v5.0.0). En crise ORDINAIRE

```
   /* ⚠ LE BANDEAU SURVIT AUX MODES D'EXCEPTION, ET SEULEMENT À EUX (v5.0.0). En crise ORDINAIRE
      il ne portait que le titre, que la barre porte déjà par son relais — il s'en va, 63,7 px
      rendus. Mais il porte AUSSI la PHRASE et la HACHURE des exceptions (« ▪ Vous suivez »,
      « ▲ Exercice », l'essai), et c'est précisément ce que la pilule de la barre ne sait pas
      dire : elle n'a que le MOT (« Suivi », « Exercice »). La v4.70.1 a réparti les deux offices
      ainsi, et supprimer le bandeau partout supprimerait la moitié du dispositif — sans qu'aucun
      harnais ne crie, `getComputedStyle` répondant encore sur un élément masqué.
      AUCUN SAUT NON PLUS : être en exercice ou invité ne CHANGE PAS au premier geste — la
      condition est stable pendant toute la session, donc la hauteur aussi. */
   /* ⚠ ET IL NE SURVIT QU'À DEUX EXCEPTIONS, PAS TROIS. L'ESSAI N'EN EST PAS UNE : la v4.76.0 a
      établi que la barre y porte DÉJÀ les deux énoncés (pilule « ■ Aperçu » ET badge « rien n'est
      enregistré »), et qu'il ne manquait que la TEXTURE — laquelle vit sur l'en-tête. Un bandeau
      sans titre et sans phrase n'y serait plus qu'une bande hachurée vide. Restent l'exercice et
      l'invité, qui ont une PHRASE que la pilule ne dit pas. */
```

## J61 — ⚠ ESSAYÉ, MESURÉ, REFUSÉ (v5.0.0) — EFFACER LE BANDEAU-TITRE AU DÉMARRAGE.

```
   /* ⚠ ESSAYÉ, MESURÉ, REFUSÉ (v5.0.0) — EFFACER LE BANDEAU-TITRE AU DÉMARRAGE.
      L'idée : il pèse 64 px à 320 et 390 px (44 à 430) en haut du premier écran de session, et le
      RELAIS de la barre (`#brandTitle`, v4.23.0) sait déjà porter le titre — on ne le supprimerait
      donc pas, on le ferait porter en permanence par l'objet qui le porte déjà la moitié du temps.
      Gain mesuré : première étape 511 → 448 px, et 3 → 4 étapes visibles à 390.
      CE QUI L'INTERDIT : `audit-doctrine` mesure que L'ÉTAPE TAPÉE NE BOUGE PAS À LA PREMIÈRE
      ACTION (ECAM) — et l'ancrage NE PEUT PAS compenser ici. Au premier geste on est en haut de
      page ; retirer 64 px AU-DESSUS demanderait de faire défiler vers le HAUT au-delà de zéro.
      La compensation est donc écrêtée par le butoir du document, et l'étape saute de 64 px sous
      le doigt — exactement l'invariant que le dossier tient depuis la v4.4.0.
      Le gain de 63 px se paierait donc au pire endroit : le geste qui démarre le soin. Statu quo.
      La voie qui resterait ouverte n'est PAS l'effacement mais la RÉDUCTION du bandeau (une seule
      ligne de titre, le discriminant en pilule à côté) : elle ne change pas la hauteur AU-DESSUS
      d'un coup, elle la change progressivement — à re-mesurer si le sujet revient. */
   /* LE BANDEAU-TITRE N'EXISTE PLUS EN LECTURE (v5.0.0, demande utilisateur — et la remarque qui
      a corrigé ma première tentative). Il pesait 64 px à 320 et 390 px (44 à 430) en haut de la
      colonne, et le RELAIS de la barre (`#brandTitle`, v4.23.0) sait déjà porter le titre : on ne
      le supprime donc pas, on le fait porter EN PERMANENCE par l'objet qui le portait déjà la
      moitié du temps. Bénéfice second : la barre a la MÊME hauteur repliée et dépliée, donc le
      chrome de lecture ne change plus jamais de taille.
      ⚠ ET C'EST INCONDITIONNEL, POUR UNE RAISON MESURÉE. Ma première version l'effaçait AU
      DÉMARRAGE : `audit-doctrine` a rougi sur « l'étape tapée ne bouge pas à la première action »
      (invariant ECAM depuis la v4.4.0), et à juste titre — c'était la TRANSITION qui retirait
      64 px AU-DESSUS de l'étape touchée, au moment précis du tap, et l'ancrage ne peut pas
      compenser vers le haut quand on est déjà en haut de page. Sans transition, pas de saut :
      le bandeau n'existe à aucun moment, donc rien ne change de hauteur sous le doigt. */
```

## J62 — « ■ CRISE » NE S'ANNONCE QU'UNE FOIS LA SESSION DÉMARRÉE (v5.0.0, maquette). Ouvrir une

```
   /* « ■ CRISE » NE S'ANNONCE QU'UNE FOIS LA SESSION DÉMARRÉE (v5.0.0, maquette). Ouvrir une
      fiche pour la RELIRE n'est pas être en crise : l'annoncer alors, c'est user le mot — la même
      inflation que celle du rouge, et sur le seul annonciateur de mode de l'écran. Le bandeau-
      titre, lui, reste (il porte le TITRE, qui est vrai dans les deux cas) ; c'est la PILULE DE
      MODE qui attend le premier geste. `crisisOnScreen()` est le prédicat unique du dossier —
      le même qui gouverne le quai, la mise en attente des banderoles et le masquage de la méta. */
   /* A14 — LE STATUT CESSE DE SE LIRE COMME UN FRAGMENT DU NOM DE LA FICHE. Il vivait à la suite
      du titre (pilule `#hdrCrisis`, coin haut-droit) ; le sur-titre le pose AU-DESSUS, dans la
      zone d'identité, où il se lit comme ce qu'il est : l'énoncé du mode. La pilule reste — c'est
      elle qui tient la position constante à droite —, le sur-titre est son pendant à gauche, là
      où l'œil arrive. Il n'apparaît qu'en crise VÉCUE (même prédicat unique) : ouvrir une fiche
      pour la relire n'est pas être en crise, et l'annoncer alors use le mot. */
   /* ⚠ LE SUR-TITRE A DEUX ÉCRIVAINS DEPUIS QU'IL PORTE AUSSI LE DISCRIMINANT — donc il a des
      ENFANTS, et A55 s'applique mot pour mot : « dès qu'un nœud gagne un enfant, tout textContent
      posé sur lui devient une suppression ». Le mot du mode s'écrit dans `.bs-m`, le discriminant
      dans `.bs-d` (par `setBarTitle`, plus bas dans le même rendu), et NI L'UN NI L'AUTRE ne
      décide seul de la visibilité : `syncBrandSur()` la dérive des deux contenus, ce qui la rend
      insensible à l'ordre des appels — `setBarTitle` est aussi appelée depuis le champ titre de
      l'éditeur, hors de tout rendu de chrome. */
```

## J63 — Le mot suit le MODE : une répétition et un suivi ne sont pas une crise, et le sur-titre

```
      /* Le mot suit le MODE : une répétition et un suivi ne sont pas une crise, et le sur-titre
         est le seul énoncé — il doit donc dire lequel des trois. Registre ACTION (bleu) pour les
         deux exceptions : ni l'une ni l'autre n'est une alerte. */
      /* ⚠ L'APERÇU EST DÉCIDÉ ICI, PLUS EN AVAL — ET C'EST UNE RÉPARATION, PAS UN DÉPLACEMENT.
         Le mot de l'essai s'écrivait ~60 lignes plus bas, sous la condition `!bs.hidden`. Or
         `hidden` est désormais DÉRIVÉ des deux contenus (mode + discriminant), donc il dépend de
         ce que le rendu PRÉCÉDENT avait laissé dans `.bs-d` : l'écrivain d'aval lisait un état
         transitoire et pouvait sauter son tour, laissant un sur-titre qui n'affichait que le
         discriminant. Un écrivain qui se conditionne à une valeur qu'un autre écrivain va
         recalculer est un écrivain à l'ordre. Les quatre mots du mode se décident donc d'un seul
         tenant, ici, à partir de l'ÉTAT et de rien d'autre. */
```

## J64 — DEUX ANNONCIATEURS, DEUX OFFICES (v4.70.1, demande utilisateur)

```
     /* ═══ DEUX ANNONCIATEURS, DEUX OFFICES (v4.70.1, demande utilisateur) ═══════════════════
        La v4.58.0 avait ancré la pilule de mode au coin haut-droit SANS retirer celle du
        bandeau : on lisait donc « ■ CRISE » en barre et « ■ MODE CRISE » en bandeau, en même
        temps, sur le même écran. La doctrine du projet l'admettait comme une troncature du même
        mot (« Cons. » pour « Consulter »), mais la troncature sert à faire tenir UN libellé dans
        une place étroite — elle n'a jamais servi à écrire deux fois la même chose côte à côte.
        RÈGLE, désormais explicite et vérifiable : LA BARRE DIT LE MODE, LE BANDEAU DIT
        L'EXCEPTION. La pilule `#hdrCrisis` est permanente, immobile, et le seul énoncé du mode.
        `.cb-tag` ne paraît QUE lorsqu'il y a une exception à annoncer, c'est-à-dire quelque
        chose que la pilule ne dit pas déjà à elle seule :
          · « ▪ Vous suivez » — l'invité SUIT une session qu'il ne conduit pas et qui peut
            s'arrêter sans lui (v4.55.4, décision utilisateur : en toutes lettres, à l'endroit le
            plus lu). La pilule dit « Suivi » ; le bandeau dit la PHRASE, et porte la hachure.
          · « ▲ Exercice » — « ceci est une répétition », la seule annonce qui protège d'une
            méprise CLINIQUE ; elle garde sa hachure et sa priorité sur le placard d'invité.
          · « ■ Aperçu » — on regarde un brouillon, rien n'est enregistré.
        En crise ORDINAIRE il n'y a aucune exception : le bandeau ne porte plus que le titre et
        son discriminant, qui y gagnent ~85 px à 390 px. Ce n'est donc pas la redondance de
        l'alarme (quai + rail), qui répète une valeur VIVE en deux endroits pour qu'elle ne
        puisse pas être manquée : ici les deux canaux disaient la même constante. */
```

## J65 — v4.72.0 — L'APERÇU CESSE DE SE DIRE DEUX FOIS. La v4.70.1 avait rangé « Aperçu »

```
      /* v4.72.0 — L'APERÇU CESSE DE SE DIRE DEUX FOIS. La v4.70.1 avait rangé « Aperçu »
         parmi les EXCEPTIONS du bandeau ; c'était une erreur de classement. Une exception,
         au sens de cette règle, est ce que la pilule de la barre ne dit pas à elle seule —
         « ▪ Vous suivez » porte une PHRASE et une hachure, « ▲ Exercice » protège d'une
         méprise clinique. « Aperçu » n'a ni l'une ni l'autre : c'est le même mot, écrit
         deux fois. La barre suffit, exactement comme pour la crise ordinaire. */
      /* L'ESSAI NE PORTE QUE LA HACHURE, PAS D'ÉTIQUETTE — et c'est la v4.72.0 qui l'impose,
         vérifié à l'écran : la barre affiche DÉJÀ « ■ Aperçu » (la pilule) ET « Essai — rien n'est
         enregistré » (le badge d'état). Les MOTS sont donc couverts deux fois ; ce qui manquait
         était le canal PÉRIPHÉRIQUE, celui qui se reconnaît sans lire. On ajoute donc la texture
         et rien d'autre. La règle 8 (« la couleur n'est jamais seule ») est tenue par la barre, qui
         est permanente et immobile — pas par une troisième copie de la même phrase.
         Bénéfice mesuré au passage : coût NUL en largeur comme en hauteur, alors qu'une étiquette
         de trente caractères repoussait le titre sur deux lignes à 400 px. */
```

## J66 — « Réf. » : accès permanent à la couche de consultation. Pas de condition d'algorithme (une

```
   // « Réf. » : accès permanent à la couche de consultation. Pas de condition d'algorithme (une
   // fiche mono-bloc a aussi des annexes) ; masqué en aperçu de brouillon et hors lecture.
   /* Le bouton d'excursion : même condition qu'avant (sans algorithme, les deux vues seraient
      identiques — règle inchangée depuis v4.16.0), mais un seul contrôle, qui dit où il MÈNE.
      Au retour il prend le registre CONFIRMATION et le glyphe ↩ : c'est le contrôle rempli de
      l'écran pendant l'excursion, exactement comme `↩ Reprendre` pendant une complication. */
   /* ══ LE DOCK EST LA BARRE DE COMMANDE DE LA SESSION (v5.6, maquette 1c — « le dock hors
      session n'a que Démarrer et Exercice ») ═══════════════════════════════════════════════
      Ses quatre touches attendent désormais que la session ait DÉMARRÉ, et le motif n'est pas
      esthétique : avant le premier geste, deux d'entre elles n'ont rien à faire (⏱ Noter l'heure
      et ⚡ Complication DÉMARRERAIENT la session implicitement, par un contrôle qui ne dit pas
      qu'il le fait) et les deux autres doublonnent ce que la page montre déjà — hors session la
      fiche est ENTIÈRE sous les yeux, « Tout voir » n'ouvre rien de neuf, et « Consulter » reste
      à un tap par la rangée d'annexes en fin de colonne et par le renvoi de la condition
      d'entrée. Ce qui reste hors session est donc ce que la maquette montre : la condition
      d'entrée, et le geste qui la valide.
      ⚠ CE QUE JE N'AI PAS REPRIS DE LA MAQUETTE, ET POURQUOI : elle loge « Démarrer la session »
      DANS le dock. Le bouton vit ici dans le flux, sous les critères — c'est le geste qui PORTE
      la confirmation (« Confirmé — démarrer la session », doctrine QRH v4.3.2), et le déplacer
      en ferait un second énoncé du même verbe (AC 120-71B §5.5) ou obligerait à supprimer celui
      du flux, donc à rouvrir l'ordre « critères → memory items → geste » (v5.0.8) et la zone
      flottante qui garantit qu'on l'atteint (v4.73.0). Trois décisions mesurées pour un gain de
      position : à décider séparément, pas par effet de bord. */
```

## J67 — ⚠ « CONSULTER » NE PORTE PLUS LE MÊME GLYPHE QUE « TOUT VOIR » (audit externe v5.10.0).

```
    /* ⚠ « CONSULTER » NE PORTE PLUS LE MÊME GLYPHE QUE « TOUT VOIR » (audit externe v5.10.0).
       Les deux portaient ⤢, et la v4.25.0 avait raison de le choisir : « elles font exactement la
       même chose — ouvrir une feuille plein écran ». Ce qui a changé depuis, c'est A2 : sous
       360 px effectifs les deux perdent leur ÉTIQUETTE. Restaient donc deux boutons voisins, même
       symbole, aucun mot, deux destinations — en mode crise, à la largeur plancher déclarée
       servie. Chaque règle était bonne isolément ; leur composition ne l'était pas, et c'est
       AC 120-71B § 5.5 pris en défaut (un signe, deux référents).
       On différencie le SIGNE plutôt que de rendre l'étiquette : « Consulter » ouvre de la
       RÉFÉRENCE — surveillances, différentiels, documents, sources —, et `book` est déjà le signe
       de la référence dans ce fichier (pastille de bibliothèque partagée, renvois de protocole).
       Peint UNE FOIS et non à chaque passage : `syncDock` court à chaque rendu. */
```

## J68 — ══ HORS SESSION : EXERCICE + DÉMARRER, ET RIEN D'AUTRE (v5.6, maquettes 1b/1c)

```
   /* ══ HORS SESSION : EXERCICE + DÉMARRER, ET RIEN D'AUTRE (v5.6, maquettes 1b/1c) ═════════
      Le geste d'entrée rejoint le dock — décision de l'auteur, après la divergence assumée de la
      passe précédente : « uniformise le design ; préférentiellement opte pour le nouveau ». Ce
      qu'on y gagne, et qui vaut le déplacement : une position CONSTANTE, atteignable au pouce à
      toutes les largeurs, sur une fiche à critères longs comme sur une fiche courte — c'est-à-
      dire exactement ce que la zone flottante `.sess-start.afloat` (v4.73.0) cherchait à obtenir
      par un objet qui se détachait et se rattachait selon le défilement. Elle est purgée avec le
      bouton du flux (règle 14).
      LE LIBELLÉ PORTE TOUJOURS LA CONFIRMATION : « Confirmé — démarrer la session » dès qu'il y
      a des critères (doctrine QRH v4.3.2) — c'est le MOT qui porte le geste, pas son logement.
      CHEZ L'INVITÉ ET EN APERÇU D'ESSAI, RIEN : `ensureStarted` refuse de créer une session
      locale sur l'appareil de quelqu'un qui suit celle d'un autre, et offrir le contrôle le plus
      visible de l'écran à un geste sans effet est ce que la v4.47.0 a supprimé. */
```

## J69 — ARRIVÉE sur un éditeur (création OU modification) : le haut de page est RÉ-AFFIRMÉ dans les

```
  // ARRIVÉE sur un éditeur (création OU modification) : le haut de page est RÉ-AFFIRMÉ dans les
  // instants qui suivent (v4.4.7). Le scrollTo(0,0) ci-dessus est posé au bon moment, mais
  // Safari iOS peut re-décaler la page juste APRÈS (fermeture asynchrone du clavier de la
  // recherche, restauration de focus à la fermeture du dialogue Créer) — constat : « j'arrive
  // un peu descendu ». Garde-fous : seulement à l'ARRIVÉE (un re-rendu en cours d'édition ne
  // repasse pas ici) et, pour l'échéance tardive, seulement si le décalage est PETIT (< 160 px :
  // on corrige un artefact, jamais un défilement volontaire de l'utilisateur).
  /* v5.10.5 : la LECTURE d'un protocole reçoit le même garde-fou (signalé à l'usage : « lorsqu'on
     ouvre un protocole on ne commence pas en haut de la page ») — même artefact Safari, même
     remède. PAS la lecture de fiche : sa réentrée atterrit sur le bout (`landOnBout`, plus bas),
     que la ré-affirmation du haut viendrait combattre. */
```

## J70 — RÉENTRÉE — ON REVIENT SUR LE SOIN, PAS SUR LE PRÉAMBULE (v5.0.0)

```
/* ═══ RÉENTRÉE — ON REVIENT SUR LE SOIN, PAS SUR LE PRÉAMBULE (v5.0.0) ════════════════════════
   Arriver en lecture posait `scrollTo(0,0)`, sans distinguer les deux arrivées qui n'ont rien à
   voir : OUVRIR une aide (on s'oriente avant d'agir — condition d'entrée QRH, le haut de fiche
   est la bonne arrivée) et Y REVENIR alors qu'une session TOURNE (on reprend un geste interrompu).
   Mesuré sur la fiche d'exemple en boucle, après six avancées : la réouverture depuis l'accueil
   déposait à 456 px du bout à 320 × 640, 356 px à 390 × 844 — le contrôle « Continuer » et les
   cases à cocher hors écran, en pleine réanimation, à retrouver au défilement.
   CE N'EST PAS UN DÉFILEMENT AUTOMATIQUE (règle 11). La règle vise l'écran qui BOUGE tout seul
   sous quelqu'un qui n'a rien demandé ; ici la page vient d'être rendue de neuf, il n'y a aucune
   position à préserver — on CHOISIT le point d'arrivée d'une navigation que l'utilisateur vient
   de demander d'un tap. C'est la distinction déjà tranchée pour `cxEnter` (« entrer sur une
   complication est une navigation DEMANDÉE ») et le point d'arrivée de `ovAdvanceRender`.
   MÊME RÈGLE DE VISIBILITÉ QU'`ovAdvanceRender` : si le bout est déjà entièrement à l'écran depuis
   le haut de page (aide courte, session à peine démarrée), on ne bouge pas — un saut qui n'apporte
   rien est un saut de trop, et il escamoterait le chapeau et les critères pour rien.
   L'atterrissage vaut aussi pour un INVITÉ (`crisisOnScreen` couvre les deux) : il suit un soin
   qu'il n'a pas démarré, et rien ne justifie qu'il le retrouve moins vite que l'hôte. */
```

## J71 — LES ÉDITEURS AUSSI FRANCHISSENT LES PALIERS (v4.77.0, signalé à l'usage : « les modifications à

```
/* LES ÉDITEURS AUSSI FRANCHISSENT LES PALIERS (v4.77.0, signalé à l'usage : « les modifications à
   l'algorithme ne fonctionnent plus en responsive — ne s'adapte pas à la largeur, repart en bas, ne
   s'affiche plus en sidebar »). Ce garde ne couvrait que `read`, alors que l'éditeur change de
   STRUCTURE au même seuil que la lecture : à ≥ 1000 px le schéma vit dans la colonne collante, en
   dessous il est entrebâillé dans le flux. Redimensionner laissait donc la page telle qu'elle avait
   été RENDUE — schéma en bas d'un formulaire large, ou colonne absente sur un écran large. Le
   défaut préexistait (les trois colonnes de K11 avaient le même trou) ; le lot 1 l'a rendu visible
   en donnant au schéma deux logements très différents. Règle : toute vue dont la STRUCTURE dépend
   d'un palier doit être listée ici — c'est le pendant exact de `_onHomeBp` pour l'accueil. */
/* ⚠ TOUTE VUE DONT LA STRUCTURE DÉPEND D'UN PALIER DOIT ÊTRE ICI — et la LECTURE D'UNE RÉFÉRENCE
   y manquait (signalé à l'usage : « non responsive, pas d'adaptation »). Son sommaire est un
   `<aside>` au-dessus de 1000 px et un `<details>` en dessous : c'est une STRUCTURE, décidée au
   rendu, donc un redimensionnement laissait la page telle qu'elle avait été RENDUE. Exactement le
   trou réparé pour les éditeurs en v4.77.0 — il en restait un. */
```

## J72 — Vues fiche/protocole (.titled) : le titre n'entre dans la barre (.ttl-on) qu'une fois le

```
  // Vues fiche/protocole (.titled) : le titre n'entre dans la barre (.ttl-on) qu'une fois le
  // titre du CORPS sorti de l'écran (~110px : bouton retour + ligne de titre) — jamais deux
  // titres visibles à la fois (pattern « grand titre » iOS, symétrique du repli de l'accueil).
  // FICHE EN CRISE (v4.23.0) : le seuil n'est PAS un nombre — c'est le passage RÉEL du bas du
  // BANDEAU sous le bas de l'en-tête, MESURÉ. Le relais (titre + ■ Crise) se prend donc « ni
  // avant ni après » : à l'instant exact où le bandeau disparaît, jamais dans un intervalle où
  // l'état ne serait annoncé nulle part. Les MINUTEURS n'ont pas de seuil : leur rangée est
  // collante, elle ne disparaît pas.
  // --hdr-h est posée ici parce que la hauteur de l'en-tête est déjà mesurée : c'est le `top`
  // de cette rangée collante. Division par zoomF() — getBoundingClientRect rend des px VISUELS
  // (× zoom du réglage de taille du texte) alors que `top` se consomme en px CSS (règle v4.13.1).
```

## J73 — ⚠ ON MESURE LA HAUTEUR DE L'EN-TÊTE, JAMAIS SA POSITION (v5.0.9, signalé à l'usage en PWA :

```
  /* ⚠ ON MESURE LA HAUTEUR DE L'EN-TÊTE, JAMAIS SA POSITION (v5.0.9, signalé à l'usage en PWA :
     « barre d'en-tête inférieure, scroll pas très réactif, beaucoup d'à-coups » — vidéo à
     l'appui, où les deux rangées collantes se désolidarisent de l'en-tête et laissent une bande
     vide à leur place). `--hdr-h` est le `top` collant du quai `#crisisDock` (et l'était de la
     rangée `#crisisCtrl`, purgée en v5.6) : le dériver du `bottom` de l'en-tête revenait à asservir la GÉOMÉTRIE du chrome à la
     POSITION DE DÉFILEMENT. Or, au rebond de fin de course (rubber-band iOS), le compositeur
     TRANSLATE tout le document, en-tête collant compris : `bottom` grandit, `--hdr-h` grandit avec
     lui, les deux rangées descendent — puis reviennent. À la cadence du doigt, c'est le
     tremblement filmé. Même famille que le rail A→Z (v5.0.2) et que la hachure des placards
     (v5.0.6) : **on n'ancre jamais à un repère qu'on ne contrôle pas**, et ce que le compositeur
     fait du rendu n'est visible dans AUCUNE mesure de la page — un harnais Blink reste vert.
     La HAUTEUR, elle, ne dépend d'aucun défilement : c'est la seule des deux qui exprime ce que
     la valeur veut dire. Bénéfice second, et il compte autant : la valeur devenant CONSTANTE, la
     garde d'écriture ci-dessous devient un vrai no-op — on cesse d'invalider le style de tout le
     document (une propriété personnalisée posée sur `<html>`) à chaque évènement de défilement.
     `bottom` reste calculé, mais pour le SEUL usage qui parle de position : le relais du titre. */
```

## J74 — ⚠ LE VOLET PROLONGE LA CAPSULE — ENCORE FAUT-IL SAVOIR OÙ ELLE EST (v5.7, signalé à l'usage,

```
  /* ⚠ LE VOLET PROLONGE LA CAPSULE — ENCORE FAUT-IL SAVOIR OÙ ELLE EST (v5.7, signalé à l'usage,
     captures à l'appui : « en mode exercice le volet s'affiche mal »).
     MESURÉ : en exercice, la capsule DISPARAISSAIT sous le volet. `--stick-top` est une SOMME DE
     HAUTEURS (en-tête + quai) — elle suppose donc le quai collé DIRECTEMENT sous l'en-tête. C'est
     vrai en crise ordinaire, où le bandeau-titre n'existe plus depuis la v5.0.0 ; c'est FAUX en
     exercice et chez l'invité, où le bandeau SURVIT pour porter le placard (A/v5.0.0) et vit dans
     le FLUX : il pousse le quai vers le bas, et le volet — posé sur la somme, donc plus haut que
     le quai réel — venait le recouvrir (z 16 contre 15).
     On mesure donc le bas RÉEL du quai, et l'on ne s'en sert QUE pour le volet : `--stick-top`
     reste une somme de hauteurs pour tout le reste (le rail, l'ancrage, le scroll-padding), donc
     la leçon v5.0.9 — une géométrie de chrome ne se dérive jamais d'une position de défilement —
     tient toujours là où elle protège. Ici, le volet est une surface TRANSITOIRE qu'on ouvre d'un
     tap : elle doit suivre la capsule où qu'elle soit, et c'est précisément ce qu'on lui demande. */
```

## J75 — Barre BIBLIOTHÈQUE en chips (accueil ÉTROIT, visible seulement connecté) : Perso + bibliothèques

```
// Barre BIBLIOTHÈQUE en chips (accueil ÉTROIT, visible seulement connecté) : Perso + bibliothèques
// partagées + création (app-admin). En large, la colonne gauche (homeSideHtml) prend le relais.
/* M4 (v5.0.0, décision utilisateur « type en chips, sous la recherche ») — LE TYPE REJOINT LES
   AUTRES FILTRES. Il vivait dans une TAB BAR BASSE, c'est-à-dire dans la grammaire d'une
   NAVIGATION entre sections — un reste du temps où « Aides » et « Protocoles » étaient deux
   bibliothèques. Depuis qu'elles n'en font qu'une (lot T9), le type est un FILTRE comme la
   bibliothèque et la catégorie : il prend leur forme, se pose au-dessus d'elles, et l'on lit du
   plus large au plus étroit — Type, Biblio, Catég. Ce que cela rend : 62 px de hauteur permanents
   en bas de l'accueil (la place que la barre fixe réservait), et une grammaire de moins.
   La colonne gauche de l'accueil LARGE portait déjà les sections : rien n'y change. */
/* ⚠ LES FILTRES SE REPLIENT TANT QU'AUCUN N'EST POSÉ (v5.0.0, audit design A3-1/A5-3).
   MESURÉ à l'accueil sur 390×844 : 12 éléments de texte et 439 px — 52 % de l'écran — précédaient
   le premier contenu clinique, dont ~90 px pour les trois rangées de filtres. Or filtrer est un
   geste qu'on ne fait JAMAIS sous stress : en urgence on cherche un SUJET, on n'affine pas un
   corpus. C'est le même diagnostic que celui qui a déclenché les lots T2–T5 sur la vue lecture
   (« 68 % de l'écran avant la première case à cocher »), appliqué à l'écran qu'on ouvre EN PREMIER
   et qui ne l'avait jamais reçu.
   UN ÉTAT ACTIF NE SE CACHE JAMAIS — règle constante du dossier. Dès qu'un filtre est posé
   (`filtersCount()>0`), les rangées sont RENDUES EN PERMANENCE et le déclencheur DISPARAÎT : il n'y
   a plus rien à replier, et les chips actives sont elles-mêmes le moyen de revenir en arrière. Un
   bouton qui ne peut plus rien basculer serait un bouton mort.
   `state.filtersOpen` VIT LE TEMPS DE LA PAGE : ni persisté, ni synchronisé — c'est une
   consultation, pas un réglage (même statut que `state.allTab` et `state.cxOpen`). Il n'est
   PAS remis à zéro au retour de fiche, et c'est délibéré : replier sous le doigt de quelqu'un
   qui vient d'ouvrir les filtres puis de consulter une aide serait le punir de son geste.
   L'ORDRE ET LES LIBELLÉS des trois rangées sont INCHANGÉS (biblio → type → catég., lot M4b) :
   ce lot ne touche qu'à leur PRÉSENCE au repos. */
/* COMBIEN de filtres agissent — c'est ce chiffre que porte le déclencheur (v5.0.3). Le type
   compte pour un dès qu'il quitte « Tout », la bibliothèque dès qu'elle quitte « Perso ». */
```

## J76 — LE DÉCLENCHEUR NE DISPARAÎT PLUS, ET L'ÉTAT ACTIF N'EST PLUS CACHÉ POUR AUTANT (v5.0.3,

```
/* LE DÉCLENCHEUR NE DISPARAÎT PLUS, ET L'ÉTAT ACTIF N'EST PLUS CACHÉ POUR AUTANT (v5.0.3,
   signalé à l'usage : « le bouton filtrer ne s'affiche pas toujours quand on a sélectionné »).
   La v5.0.0 le RETIRAIT dès qu'un filtre agissait, et forçait les rangées ouvertes en permanence,
   pour tenir la règle « un état actif ne se cache jamais » — au prix d'un contrôle qui apparaît
   et disparaît selon l'état, c'est-à-dire de la constance positionnelle, et de ~90 px rendus au
   premier écran seulement tant qu'on n'avait rien filtré.
   CE QUI REMPLACE LE FORÇAGE : le déclencheur PORTE l'état. Posé dans l'en-tête, il est visible
   sans défiler, à position CONSTANTE, et il dit combien de filtres agissent — registre de
   sélection PLEIN plus le CHIFFRE (règle 8 : la couleur n'est jamais seule ; un chiffre n'est pas
   une couleur). L'état actif n'est donc pas caché, il est porté par un objet permanent au lieu de
   trois rangées permanentes — et l'on ne peut plus se retrouver dans un corpus restreint sans
   savoir pourquoi, ce que la règle protège réellement.
   Les rangées, elles, ne s'affichent QUE si l'on a demandé à les voir — et depuis la v5.6 elles
   s'affichent AILLEURS : dans une FEUILLE (planche 8c). Cf. `openFiltSheet`. */
/* LA FEUILLE DE FILTRES (v5.6, planche 8c). Trois raisons, toutes mesurées ou doctrinales :
   (1) le dépliant faisait grandir le chrome COLLANT de l'accueil — on demandait à voir les
   filtres, et l'écran rendait MOINS de liste ; (2) les trois familles ne se voyaient jamais
   ensemble, on déroulait l'une après l'autre ; (3) une feuille peut porter un PIED qui annonce
   le résultat AVANT de fermer (« Voir les 11 résultats »), ce qu'un dépliant ne peut pas — et
   c'est la seule façon de savoir ce qu'on obtient sans avoir à refermer pour regarder.
   ⚠ `state.filtersOpen` GARDE SON NOM ET SON STATUT : c'est l'état d'ouverture de la feuille, il
   vit le temps de la page, n'est ni persisté ni synchronisé (même statut que `state.allTab`) —
   seule sa FORME change. Fermeture par le mécanisme centralisé (✕, voile, Échap, retour
   système) : aucune accessibilité réécrite. */
```

## J77 — ══ GÉRER SANS COLONNE GAUCHE (v5.20.0, signalé à l'usage : « sur smartphone il n'y a pas de

```
/* ══ GÉRER SANS COLONNE GAUCHE (v5.20.0, signalé à l'usage : « sur smartphone il n'y a pas de
   sidebar : je ne peux plus gérer les catégories, et les bibliothèques seulement en vue Rangé par
   bibliothèque ») ════════════════════════════════════════════════════════════════════════════
   Même patron et même cause que « Rejoindre une session » (v5.14.3) : une rangée au socle, masquée
   ≥ 780. Elle N'INVENTE AUCUNE FENÊTRE — #catModal, #membersModal et #newLibModal existent, ce
   sont les mêmes rangées (`hsRow`), les mêmes attributs (`data-catmgr`/`data-libedit`/`data-newlib`)
   et les mêmes lecteurs que la colonne gauche. Deux règles de politesse :
   · LE SOCLE N'OUVRE JAMAIS UNE FEUILLE D'UNE SEULE RANGÉE — sans bibliothèque à administrer, la
     rangée dit « Gérer les catégories » et va DROIT au gestionnaire ; libellé et destination
     disent alors la même chose, et l'on n'ajoute pas un tap pour rien.
   · ON NE LISTE QUE CE QUI SE GÈRE : une bibliothèque en lecture seule n'a rien à modifier, une
     rangée pour elle serait une commande morte (règle 14). Elle reste lisible partout ailleurs. */
```

## J78 — ── RÉSULTATS TROUVÉS DANS UN DOCUMENT PDF ──────────────────────────────────────────────────

```
/* ── RÉSULTATS TROUVÉS DANS UN DOCUMENT PDF ──────────────────────────────────────────────────
   UN GROUPE À PART, jamais fondu dans les rangées d'aides (décision) : sinon on ne saurait plus
   si le mot est dans l'aide ou dans une annexe — et un document porté par deux fiches
   apparaîtrait deux fois. C'est aussi la forme de Finder : une ligne par FICHIER.
   AUCUN EXTRAIT ici, et c'est la clé du dispositif : afficher la phrase exigerait de rouvrir le
   PDF, donc de charger pdf.js (1 773 Ko) à chaque frappe. On donne ce qui situe — le nombre de
   passages et les PAGES — et le contexte se lit dans le document, qu'un tap ouvre à la bonne
   page. Le document est nommé par la première entité VISIBLE qui le porte : un brouillon caché
   ne doit pas révéler l'existence de son annexe. */
/* LE DOCUMENT QUI CORRESPOND FAIT CORRESPONDRE SON PORTEUR (v5.3.0, demande utilisateur : « il
   faut aussi afficher les protocoles/aides qui contiennent ce document »). Une aide et ses
   annexes forment UN objet de soin : chercher un mot qui ne vit que dans le PDF joint doit
   sortir l'aide, pas seulement le fichier. `entityDocHit` rend le PREMIER document de l'entité
   où TOUS les termes apparaissent (même conjonction que `hayMatch`) — utilisé par les trois
   listes de l'accueil, par le renvoi croisé et par l'extrait de rangée. */
```

## J79 — Rail alphabétique : tap = saut vers la lettre, GLISSER le long des lettres = parcourir (index

```
/* Rail alphabétique : tap = saut vers la lettre, GLISSER le long des lettres = parcourir (index
   iOS — pointer capture, un jump par lettre traversée). Le défileur dépend de la largeur : la
   colonne .home-main (accueil large, coque fixe) ou la fenêtre (étroit). Toute mesure rect est
   en px VISUELS (× zoom du réglage de taille du texte) : réinjectée en scroll, elle se divise
   par zoomF() (règle v4.13.1). */
/* LA BOÎTE DU RAIL EST POSÉE UNE FOIS PAR RENDU, JAMAIS À CHAQUE ÉVÉNEMENT DE DÉFILEMENT
   (v5.0.2). C'était la DERNIÈRE entrée dynamique de sa géométrie : le haut valait `--hdr-h`, une
   propriété que `syncHdrScroll` RÉÉCRIT à chaque scroll depuis un `getBoundingClientRect()` de
   l'en-tête COLLANT. Sur Blink, un sticky est repositionné avant l'évènement, donc la mesure est
   toujours juste (vérifié à la sonde : `--hdr-h` constante sur toute la course). Sur iOS, où le
   défilement et le repositionnement des collants sont composités, rien ne garantit que cette
   lecture soit celle de la frame en cours — et le rail, lui, est FIXE : la moindre valeur
   transitoire lui déplace le haut ET la hauteur, donc son centre.
   Le haut est donc MESURÉ au rendu et gelé dans `--azr-top` ; le CSS n'y consomme plus rien qui
   s'écrive au défilement. Repose au redimensionnement et à la rotation — les deux seuls moments
   où la hauteur d'en-tête peut réellement changer sans re-rendu. Le repli CSS garde
   `--hdr-h` : il ne sert qu'à la toute première peinture, avant que le JS ait mesuré. */
/* ⚠ LE HAUT DU RAIL EST CELUI DE L'EN-TÊTE AU REPOS, JAMAIS CELUI DU MOMENT (v5.6, signalé à
   l'usage : « le rail A→Z se déplace légèrement quand on a scrollé, et se recentre quand on
   clique sur n'importe quel bouton »). Depuis 7a, l'en-tête de l'accueil étroit se COMPACTE au
   défilement (114 → 62 px) ; `azrPoseBox` mesurait son bas À L'INSTANT DU RENDU, et tout
   re-rendu — un tap de chip, une épingle, un changement de groupement — reposait donc la
   variable avec la hauteur du moment. La boîte du rail grandissait alors de 52 px et, les
   lettres étant CENTRÉES, elles se déplaçaient de 26 px sous le doigt.
   C'est la règle déjà écrite en v5.0.9 : une géométrie de chrome ne se dérive jamais d'un état
   qui dépend du défilement. Le rail s'ancre à la hauteur de l'en-tête DÉPLOYÉ — il ne descend
   pas dans la place que la compaction libère, et sa position s'apprend une fois pour toutes.
   ⚠ QUAND L'EN-TÊTE EST DÉJÀ RESSERRÉ, ON NE PEUT PAS LE MESURER TEL QUEL : on retire la classe
   le temps d'UNE lecture, puis on la remet dans la même tâche — aucun rendu intermédiaire n'a
   lieu, et c'est plus sûr qu'une valeur mise en cache qui se périmerait au redimensionnement. */
```

## J80 — LECTURES GROUPÉES PUIS ÉCRITURES (discipline `svPaintArrows`), et une seule inconnue : le

```
  /* LECTURES GROUPÉES PUIS ÉCRITURES (discipline `svPaintArrows`), et une seule inconnue : le
     DÉCALAGE du premier caractère depuis le haut de la boîte. On passe donc la colonne en
     `flex-start` et on le POSE — un centrage qu'on corrigerait ensuite par des rembourrages
     symétriques se paie en arithmétique inverse et en arrondis (essayé, 2,5 px d'écart résiduel).
     ⚠ LA CIBLE SE MESURE, ELLE NE SE DÉDUIT PAS D'UNE FORMULE : le haut de la boîte vaut le bas de
     l'en-tête en voie étroite, mais PAS en voie large (mesuré 110 px pour un en-tête de 61) — une
     formule « rends la hauteur de l'en-tête » y laissait 24 px d'écart.
     ⚠ ET LA HAUTEUR DE RÉFÉRENCE SE DÉRIVE DE LA BOÎTE DU RAIL, PLUS JAMAIS DE
     `documentElement.clientHeight` (v5.10.5, signalé à l'usage : « jamais centrée », vidéo à
     l'appui — bloc de lettres à ~23 % de l'écran). `clientHeight` était choisi comme « la seule
     hauteur qui ne suive ni la barre d'outils ni le clavier » (leçon v5.0.2) — mais son
     COMPORTEMENT SOUS `zoom` DIVERGE ENTRE MOTEURS : les moteurs de bureau le rendent NON zoomé
     (la division par z est alors juste, sondé vert sur Chromium ET WebKit aux deux zooms), iOS
     le rend dans l'espace zoomé ou au small viewport selon le chrome — la même formule y centre
     trop haut. Or la boîte du rail EST déjà la géométrie stable qu'on cherche : sa hauteur est
     `100svh` par le CSS (constante, barre déployée), son bas est donc le bord bas du small
     viewport moins la réserve déclarée (96 px — le dock —, + `--sab` en app installée). On reconstruit le
     bord d'écran depuis `b.bottom` — même source, mêmes unités visuelles que tout le reste de
     la formule, zéro mesure au comportement divergent. */
```

## J81 — ══ QUAND L'ALPHABET NE TIENT PAS CENTRÉ, ON L'ÉCLAIRCIT (v5.6, décision de l'auteur)

```
/* ══ QUAND L'ALPHABET NE TIENT PAS CENTRÉ, ON L'ÉCLAIRCIT (v5.6, décision de l'auteur) ══════════
   Le clamp d'`azrCentrer` pousse les lettres aussi haut que la boîte l'autorise, et c'est déjà
   l'optimum — mais l'optimum n'est pas le centre. MESURÉ à 390 × 844 : la boîte commence à 121 px
   (sous l'en-tête, pour qu'aucune lettre ne passe derrière lui) et l'écran a son axe à 422 ; un
   alphabet complet mesure 650 px et devrait donc commencer à 97. Il reste 24 px trop bas, et
   descendre les cibles au plancher WCAG de 24 px n'en rendrait que 13 : c'est GÉOMÉTRIQUEMENT
   impossible sans cacher des lettres.
   C'est le problème que l'index de Contacts d'iOS résout depuis toujours : quand l'alphabet ne
   tient pas, il en montre MOINS et met un « · » à la place des lettres omises. L'index raccourci
   se centre alors exactement, les cibles gardent leurs 24 px, et rien n'est injoignable — un point
   mène à la première lettre qu'il remplace, et son nom accessible les cite toutes les deux.
   ⚠ ON NE FUSIONNE QUE DES PAIRES, ET SEULEMENT CE QU'IL FAUT : un point qui avalerait cinq
   lettres ne serait plus un index. S'il en faudrait plus que la moitié de l'alphabet, on renonce —
   le rail se replie déjà tout seul quand il ne tient pas (`bindAzRail`), ce qui reste préférable à
   un index illisible.
   ⚠ ET C'EST RÉSERVÉ AUX LETTRES : le rail des CATÉGORIES porte des pastilles de couleur, qui ne
   se remplacent pas par un point sans perdre ce qu'elles disent. */
```

## J82 — UN SAUT SE CALCULE EN ABSOLU, JAMAIS EN RELATIF (v5.0.2, signalé à l'usage : « ça continue de

```
  /* UN SAUT SE CALCULE EN ABSOLU, JAMAIS EN RELATIF (v5.0.2, signalé à l'usage : « ça continue de
     bugger en descendant vers le bas sur le rail — il remonte », EN PWA, donc sans barre d'outils
     ni marge basse qui bougent : ni `--vvh` ni l'inset n'expliquent plus rien).
     Le saut était un DÉPLACEMENT RELATIF (`scrollBy`, `scrollTop +=`) dont le pas se déduisait
     d'un `getBoundingClientRect()` — c'est-à-dire de la position DÉJÀ RENDUE — puis s'ajoutait à
     la position COURANTE. Sur Blink les deux sont la même chose : le défilement est synchrone,
     et la sonde le confirme (course monotone, 0 oscillation). **Sur iOS le défilement est
     ASYNCHRONE** : pendant un glisser, le rect peut refléter une position que le compositeur n'a
     pas encore appliquée alors que `scrollY` est déjà à jour. On ajoute alors un pas déjà
     parcouru — on dépasse —, le mouvement suivant calcule un pas NÉGATIF pour corriger, et à
     60 évènements par seconde cela devient une oscillation : on descend, ça remonte.
     La cible est donc calculée dans les OFFSETS DE MISE EN PAGE, qui ne dépendent d'aucune
     position de défilement, et posée en ABSOLU (`scrollTo` / `scrollTop =`). Deux appels pour la
     même lettre visent alors exactement le même point : idempotent par construction, donc rien à
     accumuler et rien à corriger. Les offsets sont en px CSS non zoomés — ce que `scrollTo`
     attend —, seule la hauteur de la pile collante est une mesure VISUELLE et se divise par
     `zoomF()` (règle v4.13.1).
     ⚠ ET CETTE MESURE EST `stickHeight()`, JAMAIS `stickBase()` (v5.10.5, signalé à l'usage :
     « en arrivant tout en haut l'en-tête saute pendant moins d'une seconde », inchangé après le
     gel des bascules d'état — donc le mouvement ne venait PAS d'un changement d'état).
     `stickBase()` lit le `bottom` OBSERVÉ de l'en-tête collant : une position, donc une valeur
     que le compositeur iOS peut rendre TRANSITOIREMENT fausse pendant le rattrapage d'un grand
     saut (le rect reflète une frame que l'écran n'a pas encore — même dossier que le calcul en
     absolu ci-dessus, v5.0.2, qui avait purgé tous les lecteurs de position SAUF celui-là).
     Chaque relevé transitoire recalculait une cible différente pour la MÊME lettre : l'idempotence
     tombait, les poses se corrigeaient en rafale ~1 s — le « saut » du haut. `stickHeight()` est
     la SOMME DES HAUTEURS de la pile (leçon v5.0.9, celle de `--stick-top`) : indépendante de
     tout défilement, et ÉGALE à `stickBase()` au repos sur l'accueil (en-tête collé en haut de
     fenêtre, quai absent — vérifié à la sonde sur les deux moteurs). En bas, l'écrêtage à `max`
     masquait déjà ce défaut ; en haut, rien ne le bornait. */
```

## J83 — ----- ACCUEIL GÉNÉRIQUE fiches/protocoles — même patron que _pullTable/_pushTable : le

```
/* ----- ACCUEIL GÉNÉRIQUE fiches/protocoles — même patron que _pullTable/_pushTable : le
   squelette (barre bibliothèques, recherche + Créer, catégories, résultats croisés, pagination
   des résultats de recherche, état vide, câblage commun, restauration du défilement des
   catégories) est UNIQUE ; cfg injecte les différences. Corriger le chrome d'accueil =
   corriger ICI, une seule fois.
     cfg = { rerender (la vue elle-même), crossKind ('protocols'|'fiches'),
             list(q,canEdit) -> éléments filtrés/triés, row(x) -> rangée du répertoire,
             tile(x) -> tuile « Accès direct », open(id), create(),
             remainLbl(n) (accord du « Afficher plus »),
             kinds (types créables ICI : ['fiches'] | ['protocols'] | les deux),
             empty:{title,libRead},
             topHtml()? / notices()? (sections propres à la vue), bind()? (écouteurs en plus) } */
/* LE CHRONO D'UNE SESSION EN COURS, DANS LA RANGÉE (v5.0.0, V2). Il remplace la DATE de
   validation, qui n'apprend rien pendant qu'une session tourne — donc coût de largeur NUL. Un
   temps qui s'incrémente est un signal non ambigu : la couleur n'est jamais seule (règle 8), et
   l'on apprend en plus depuis combien de temps. PEINT SUR PLACE par `tickAll` (l'accueil n'est
   pas re-rendu chaque seconde : ce serait détruire le DOM sous le doigt, leçon du quai). */
/* « Session en cours » se dit d'une session DÉMARRÉE, jamais d'une fiche simplement ouverte.
   Le prédicat est écrit UNE fois : la carte de l'accueil filtrait déjà sur `R.started`, la
   rangée et la tuile testaient la seule présence dans `liveSessions` — d'où le chrono figé à
   0:00 d'un exercice à peine ouvert (v5.2.0). Le registre ne contient plus que des sessions
   démarrées ; ce garde le dit en toutes lettres plutôt que de reposer sur cet invariant. */
```

## J84 — CE QUE L'ON VA CRÉER, DIT AU SEUL MOMENT OÙ ON PEUT L'ENTENDRE (v5.0.0, maquette d'audit).

```
/* CE QUE L'ON VA CRÉER, DIT AU SEUL MOMENT OÙ ON PEUT L'ENTENDRE (v5.0.0, maquette d'audit).
   Une aide cognitive et un protocole ne se distinguent nulle part ailleurs dans le produit :
   l'accueil les mêle depuis le lot T9, et la NATURE écrite sur la rangée nomme la différence
   sans l'expliquer. Le seul écran qui a la place ET l'attention pour le faire est la
   bibliothèque VIDE — il n'y a alors rien d'autre à regarder, et personne à interrompre.
   MÊME COMPOSANT `.empty` pour les deux, MÊME anatomie (une phrase qui donne le VERBE, puis
   les objets qu'on y trouvera) : deux cartes de formes différentes se liraient comme deux
   objets sans rapport, alors qu'on les met côte à côte précisément pour être COMPARÉES.
   ⚠ LE PROTOCOLE N'EST PAS « CE QUI NE SE COCHE PAS » (correction de l'utilisateur sur la
   maquette, et la maquette avait tort) : une référence A des cases cochables — syntaxe GFM
   `- [ ]`, v4.5.4 — elles servent à ne pas perdre sa place pendant qu'on la parcourt, et c'est
   leur NON-ENREGISTREMENT qui est la propriété (`state.protoTasks`, remis à zéro à chaque
   ouverture, aucun champ du modèle touché). Écrire « rien ne s'y coche » aurait enseigné
   l'inverse de ce que l'écran fait, à l'endroit même où l'on prétend l'expliquer.
   LES GLYPHES SONT CEUX DU PRODUIT (`uiIcon`), et la couleur n'est jamais seule (règle 8) : le
   registre est nommé en toutes lettres (« Rouge », « Ambre »), le glyphe ne fait que le montrer.
   Le TON passe par un attribut, jamais par une classe `.crit`/`.vig` — ce sont des classes
   AUTONOMES du produit, et un modificateur ne prend jamais le nom d'une classe existante
   (leçon v4.23.2, collision `.tk-panel.empty`). */
```

## J85 — A170 — SÉLECTION MULTIPLE DANS LA BIBLIOTHÈQUE

```
/* ═══ A170 — SÉLECTION MULTIPLE DANS LA BIBLIOTHÈQUE ══════════════════════════════════════════
   Demande de l'auteur : « déplacer plusieurs fiches (entre bibliothèques, entre catégories),
   supprimer plusieurs fiches à la fois (avec pour la suppression une confirmation forte) ».
   Jusqu'ici chacun de ces gestes coûtait un ALLER-RETOUR PAR FICHE — ouvrir, éditer, changer,
   enregistrer, revenir — et le seul recours après un import raté était de supprimer une par une
   (c'est d'ailleurs ce que disait déjà la doctrine de l'atelier d'import, A129).
   TROIS PROPRIÉTÉS QUI NE SE NÉGOCIENT PAS :
    · **Le mode ne survit pas à l'accueil** (`render`) : l'accueil est aussi l'écran qu'on ouvre
      en urgence, et le retrouver en gestion après avoir consulté une fiche serait un piège.
    · **On ne coche que ce qu'on peut MODIFIER** (`canEditFiche`) : dans une bibliothèque partagée
      dont on est LECTEUR, la case n'existe pas — proposer un geste que le serveur refusera
      (la RLS est l'autorité) serait un bouton mort doublé d'un mensonge.
    · **La catégorie ne se pose que sur une destination COMMUNE** : un id de catégorie n'a de sens
      que dans SA bibliothèque (v5.10.9). Sur une sélection éparpillée, la commande se FERME et
      dit pourquoi, au lieu d'écrire une référence qui ne résoudrait nulle part. */
```

## J86 — Le compte est un `status` : il change sans que le focus bouge, un lecteur d'écran doit

```
  /* Le compte est un `status` : il change sans que le focus bouge, un lecteur d'écran doit
     l'entendre. Il est aussi le SEUL élément élastique de la ligne (cf. CSS) et le seul qui
     bouge d'un état à l'autre — il bouge donc dans son propre espace, sans jamais pousser une
     commande ailleurs.
     ⚠ ET C'EST LE COMPTE QUI DIT POURQUOI « Catégorie… » EST FERMÉE (planche 20, consigne 7) :
     un `title` n'existe pas au doigt, et en étroit le bouton vit dans la feuille, où aucune
     infobulle ne se survole. Le motif rejoint donc la seule ligne que l'on regarde de toute
     façon — « 3 cochés · deux bibliothèques ». Les `title` longs des autres commandes partent
     avec : un intitulé qui se suffit ne se double pas d'une infobulle (consigne 4).
     RIEN DE COCHÉ, RIEN DE MORT : la touche d'actes n'est pas grisée, elle N'EXISTE PAS — la
     barre est alors trois objets sur une ligne courte, au lieu des quatre commandes désactivées
     sur deux étages qu'on ouvrait hier. */
```

## J87 — ACCUEIL v5.18 (maquettes de l'artefact « Accueil — la barre d'en-tête »). Deux régimes :

```
  /* ACCUEIL v5.18 (maquettes de l'artefact « Accueil — la barre d'en-tête »). Deux régimes :
     — RECHERCHE : liste plate triée par pertinence (épinglées > frecency > titre), extraits,
       pagination LIB_PAGE ; chaque rangée dit sa bibliothèque (liste plate = provenance partout).
     — SANS recherche : UNE liste (union des bibliothèques), sections à intertitres COLLANTS
       selon le rangement (bibliothèque | catégories | A–Z). Le rail A→Z n'existe qu'en
       rangement A–Z et en voie étroite ; « Accès direct » (tuiles épinglées) qu'à ≥ 1200 px ;
       à ≥ 1200 le répertoire se lit en TABLEAU (rowT). Pas de pagination hors recherche.
     .dir-wrap enveloppe la zone de contenu des DEUX régimes : c'est le périmètre que
     audit-a11y.mjs balaye sur l'accueil (ex-.cards — garder ce sélecteur vivant, v4.31.1). */
  /* ÉTAT VIDE — LE VIDE EST LE SEUL MOMENT OÙ L'ON PEUT ENSEIGNER LA DIFFÉRENCE (v5.0.0,
     maquette d'audit, demande utilisateur). Deux cas, et un seul portait l'information :
     — BIBLIOTHÈQUE VIDE et l'on peut créer : c'est le premier écran d'un nouveau venu, et
       c'est le seul instant où l'on a sa place ET son attention pour dire ce qu'il va créer.
       `cfg.kinds` décide combien de cartes : les DEUX en vue « Tout », une seule dans une vue
       filtrée — le nombre de cartes est donc exactement le nombre de choses créables ICI.
       ⚠ C'est ce qui corrige le défaut signalé : en vue « Tout », le titre était bien neutre
       (« Bibliothèque vide ») mais le texte et le bouton étaient ceux des AIDES seules — on
       proposait un type là où l'on venait de dire qu'il n'y en avait pas.
     — FILTRE SANS RÉSULTAT, ou bibliothèque partagée en LECTURE SEULE : rien à enseigner (on
       sait déjà ce qu'est une aide, on cherchait autre chose), et rien à créer. Le `.empty`
       ordinaire suffit, sans bouton.
     `empty.anon`, `empty.libEdit` et `empty.cta` sont PURGÉS avec `#emptyNew` (règle 14) : les
     cartes couvrent exactement leur condition d'affichage (`!q && !cat && canEdit`), et
     `canEditScope(null)` valant toujours vrai, aucun de ces trois textes n'était plus
     atteignable. Le titre du cas filtré devient « Aucun résultat » : « Bibliothèque vide »
     au-dessus de « aucun résultat pour ce filtre » disait deux choses différentes du même écran. */
```

## J88 — Tri : épinglées d'abord (préférence locale), puis ordre alphabétique (byTitle, v4.3.2).

```
    // Tri : épinglées d'abord (préférence locale), puis ordre alphabétique (byTitle, v4.3.2).
    // Recherche : plein texte normalisé.
    // Recherche (q non vide) : porte sur TOUTES les bibliothèques accessibles (le tableau `fiches`
    // ne contient déjà que du contenu autorisé) ; brouillon visible si on peut éditer SA biblio
    // (canEditFiche, par item). Sans recherche : périmètre + catégorie courants, comme avant.
    // Tri des RÉSULTATS de recherche (v4.4.6) : épinglées, puis frecency (les fiches qu'on ouvre
    // le plus, récemment, en premier), puis alphabétique. Sans recherche : alphabétique inchangé.
    /* ⚠ UN FILTRE POSÉ AGIT AUSSI EN RECHERCHE (v5.6, signalé à l'usage : « en mode recherche,
       quand on change de catégorie, rien ne se passe »). La branche `q` ignorait `state.scope` et
       `state.cat` — le déclencheur annonçait « 2 filtres », la liste n'en tenait aucun compte, et
       le contrôle était donc MORT au moment précis où l'on s'en sert. Ce n'est pas la règle
       « on réordonne, on ne filtre jamais » : celle-là vaut pour un RAPPROCHEMENT que la machine
       devine (posologie, étiquettes), pas pour un cran que l'utilisateur a posé du doigt.
       La règle de v5.0.3 tient dans les deux sens : on ne peut pas se retrouver dans un corpus
       restreint sans savoir pourquoi — ni croire l'avoir restreint sans que rien ne bouge. */
    /* v5.18 : UNION des bibliothèques (le rangement fait les sections) ; brouillon visible si
       l'on peut éditer SA bibliothèque (par fiche) ; le cran catégorie agit partout, par nom. */
```

## J89 — SESSIONS EN COURS (SPEC §5) : une CARTE par session (surface, liseré primaire 3px), point

```
    // SESSIONS EN COURS (SPEC §5) : une CARTE par session (surface, liseré primaire 3px), point
    // vert + kicker + titre, CHRONO mono vivant (mis à jour par tickAll), « Reprendre » plein,
    // « Terminer » en texte rouge (destructif : jamais plein, jamais premier).
    // En mode RECHERCHE, les cartes « Session en cours » s'effacent (v4.4.7) : on cherche AUTRE
    // chose — la session reste signalée par le tag « ● En cours » de sa carte-résultat, par la
    // barre de minuteurs de l'en-tête, et les cartes reviennent dès que la requête se vide.
    /* REJOINDRE SE TAPE DANS LA RECHERCHE (décision utilisateur, v4.48.0). Rejoindre est une action
       APPELÉE, pas permanente : la doctrine ECAM réserve l'affichage permanent à ce qui sert la
       conduite en cours, et une ligne en tête d'accueil ferait payer 44 px d'attention à CHAQUE
       ouverture pour un geste rare. Le champ de recherche est déjà l'endroit où l'on tape ce qu'on
       cherche, il est visible à toutes les largeurs, et un code est reconnaissable SANS AMBIGUÏTÉ :
       exactement 8 caractères d'un alphabet fermé de 32 symboles, sans 0/1/I/O. Le risque de
       collision avec une vraie recherche est donc nul en pratique — et s'il s'en produisait une, la
       ligne s'AJOUTE aux résultats, elle ne les remplace pas.
       Coût quand on ne s'en sert pas : ZÉRO pixel, zéro attention. */
```

## J90 — R4 — LA BIBLIOTHÈQUE DEVIENT UNIQUE, LE TYPE DEVIENT UN FILTRE (lot T9, v5.0.0)

```
/* ===== R4 — LA BIBLIOTHÈQUE DEVIENT UNIQUE, LE TYPE DEVIENT UN FILTRE (lot T9, v5.0.0) =======
   Avant, choisir « Aides » ou « Protocoles » était une DÉCISION PRÉALABLE : il fallait savoir de
   quel TYPE était ce qu'on cherchait avant de pouvoir le chercher. Or le type est une propriété de
   l'AUTEUR (« ai-je écrit une checklist ou un document ? »), pas du lecteur, qui cherche un SUJET.
   Le répertoire A→Z réunit donc les deux, et le type devient un filtre — c'est-à-dire quelque chose
   qu'on applique APRÈS avoir vu, jamais avant.
   CE N'EST PAS UNE FUSION DES DEUX RENDUS, ET C'EST DÉLIBÉRÉ : `renderFiches` et `renderProtocols`
   restent intacts et servent les deux crans filtrés. On ajoute une TROISIÈME configuration qui
   délègue rangée, tuile et ouverture au type de chaque objet. Fusionner les deux aurait produit un
   rendu unique truffé de conditions — et surtout un seul endroit à casser pour les trois vues.
   LA PROVENANCE RESTE ÉCRITE SUR LA RANGÉE (décision D4) : elle ne dépend d'aucun filtre, parce
   qu'une bibliothèque partagée et une fiche perso ne s'engagent pas de la même façon. */
```

## J91 — EXTRACTION — une passe par page, on ne garde que les MOTS. Le texte complet n'est jamais

```
/* EXTRACTION — une passe par page, on ne garde que les MOTS. Le texte complet n'est jamais
   assemblé : `ixTokens` est appliqué page par page, donc le pic mémoire vaut une page.
   ⚠ `getDocument` DÉTACHE le tampon qu'on lui passe (piège documenté du ⤓ Télécharger, v4.19.0) :
   inoffensif ici parce que la lecture IndexedDB nous en rend une copie fraîche à chaque fois —
   ne PAS réutiliser ce tampon après cet appel. */
/* DEUX FAMILLES D'ÉCHEC, ET ELLES NE SE TRAITENT PAS PAREIL — c'est tout l'enjeu de résilience :
   · TRANSITOIRE (binaire pas encore téléchargé, pdf.js hors du cache et hors réseau, stockage
     saturé) : on ne RETIENT rien. Le document reste « à indexer », donc visible dans la ligne
     d'état, avec son geste — il repassera.
   · DURABLE (pdf.js a bien ouvert le document et n'en tire aucun texte, ou le refuse) : on
     ENREGISTRE l'état (`none:'scan'` ou `none:'illisible'`). Sans cela, un PDF que rien ne peut
     lire serait « pas encore indexé » à chaque démarrage, pour toujours — un compte qui ne
     descend jamais et un bouton qui ne fait rien, c'est-à-dire le pire des deux mondes.
   Le distinguo se joue sur `pdfLib()` : s'il échoue, c'est NOTRE bibliothèque qui manque, jamais
   le document. On relance donc, on ne condamne pas.
   ⚠ `getDocument` DÉTACHE le tampon qu'on lui passe (piège documenté du ⤓ Télécharger, v4.19.0) :
   inoffensif ici parce que la lecture IndexedDB nous en rend une copie fraîche à chaque fois —
   ne PAS réutiliser ce tampon après cet appel. */
```

## J92 — M5 (v5.0.0, maquettes proto-r4) — LE SOMMAIRE D'UNE RÉFÉRENCE. Une aide cognitive se DÉROULE,

```
  /* M5 (v5.0.0, maquettes proto-r4) — LE SOMMAIRE D'UNE RÉFÉRENCE. Une aide cognitive se DÉROULE,
     une référence se CONSULTE : on y vient chercher UNE section, et sans sommaire il faut faire
     défiler un document qui peut faire plusieurs milliers de pixels pour savoir ce qu'il contient.
     C'est l'exacte contrepartie de la colonne « structure » de l'éditeur et du plan de la lecture :
     un document long a besoin d'une carte.
     CONSTRUIT APRÈS LE RENDU, jamais dans `mdRender` — le parseur reste PUR et NON interactif
     (règle du dépôt : les aperçus sont inertes, et un id posé au parsing voyagerait dans tout
     rendu markdown, aperçus d'éditeur compris). Les ancres sont posées ici, sur les nœuds réels.
     TROIS TITRES AU MINIMUM : un sommaire de deux lignes ne fait pas gagner un défilement, il
     ajoute une colonne. Et JAMAIS sous 1000 px, où il prendrait la place du texte qu'il indexe. */
  /* LE PLAN D'UNE RÉFÉRENCE VIT À GAUCHE (v5.0.0, refonte des protocoles, maquettes) — comme le
     plan d'une aide en cockpit, et pour la même raison : on s'oriente à gauche, on lit au milieu.
     SOUS 1000 px il n'y a pas de colonne : il devient un DÉPLIANT en tête du corps, replié, qui
     dit son nombre de sections — un sommaire qu'on ouvre, jamais une liste qui pousse le texte.
     ⚠ L'ORDRE DU DOM RESTE CELUI DE LA LECTURE : le sommaire est ajouté APRÈS le corps et ramené
     à gauche par `order` — ni un lecteur d'écran ni une tabulation ne doivent traverser un
     sommaire pour atteindre le texte (même règle que `.read-plan`, v4.59.0). */
```

## J93 — ----- Tronc COMMUN des éditeurs fiche/protocole (audit v4.1.0 : le gabarit d'en-tête de

```
/* ----- Tronc COMMUN des éditeurs fiche/protocole (audit v4.1.0 : le gabarit d'en-tête de
   formulaire, le câblage des champs partagés et la sortie « ‹ Retour » vivaient en double —
   corriger ICI corrige les deux ; les ids de champs restent préfixés 'f-'/'p-'). ----- */
// Rangées partagées du formulaire : notice de brouillon restauré, titre, catégorie,
// bibliothèque, code + date de validation, état segmenté. L = libellés propres à l'entité.
/* K4 (v4.63.0, audit design — phase K) : LA PAGE APPARTIENT AU CONTENU CLINIQUE. Titre, code,
   catégorie, bibliothèque, date de validation et état occupaient tout le haut de l'éditeur —
   l'auteur traversait six champs administratifs avant d'atteindre ce qu'il vient écrire. Ils
   vivent maintenant dans un dépliant « Identité » dont l'EN-TÊTE montre déjà l'essentiel (titre +
   code), et qui s'ouvre d'un tap.
   OUVERT D'OFFICE EN CRÉATION, REPLIÉ EN MODIFICATION : sur une fiche neuve le titre est le
   premier geste — le replier obligerait à un tap pour commencer ; sur une fiche existante il est
   déjà écrit, et ce qu'on vient corriger est le contenu. La distinction est faite sur le TITRE
   (vide = on commence), pas sur l'existence de la fiche : dupliquer une fiche donne un titre,
   repartir de zéro n'en donne pas.
   Le statut éditorial reste en PLUS dans la barre (badge d'en-tête, doctrine v4.3.0) : c'est un
   état, il ne se replie pas. */
```

## J94 — MENU ANCRÉ GÉNÉRIQUE (v5.11.0) — le CORPS EXACT de l'ancien `openCatMenu`, extrait

```
/* ═══ MENU ANCRÉ GÉNÉRIQUE (v5.11.0) — le CORPS EXACT de l'ancien `openCatMenu`, extrait ═══════
   POURQUOI L'EXTRAIRE PLUTÔT QUE D'EN ÉCRIRE UN SECOND : l'atelier d'import a besoin du même menu
   pour la CATÉGORIE et pour la BIBLIOTHÈQUE d'une rangée — soit trois usages du même objet. Trois
   copies de trente lignes de machinerie (voile, piège clavier, filtre, fermeture, retour de
   focus, `aria-expanded` sur les déclencheurs) auraient divergé : c'est la leçon du serveur
   statique recopié dans onze harnais (v4.45.0) et des listes tenues à la main (MUTE_SEL). Le DOM
   et les classes sont INCHANGÉS — le menu de l'éditeur rend le même HTML qu'avant, à l'octet près
   du nom de l'attribut d'option (`data-catopt` -> `data-pickopt`, qu'aucun harnais ne cite).
   `opts` : {aria, options:[{val,name,col,dot,tt,danger}], value, onPick(val), action:{label,fn},
   trigger, seuilFiltre, head}. `col` vide -> pastille neutre ; `dot:false` -> aucune pastille ;
   `danger:true` -> la rangée passe au registre critique (encre seule — cf. `.catmenu-row.danger`).
   `head` (v5.17) est un rappel de CONTEXTE posé au-dessus des rangées : le tiroir d'actes de la
   sélection y redit le compte et sa portée avant tout acte, la largeur d'une feuille ne coûtant
   rien là où celle de la barre coûte une rangée.
   ⚠ `head` EST DU HTML BRUT, ET C'EST L'APPELANT QUI ÉCHAPPE (règle 4) : il compose des balises,
   donc `esc()` ne peut pas s'appliquer ici sans les détruire. Aucun appelant n'y passe autre
   chose que des chaînes déjà passées à `esc()`.
   ⚠ LES VALEURS SONT DES CHAÎNES : elles transitent par un attribut. Les appelants qui ont besoin
   d'un troisième état (l'atelier : « garder celle du fichier ») emploient une SENTINELLE que
   `SAFE_ID` ne peut pas produire — cf. IMP_KEEP. */
/* UN SEUL MENU OUVERT À LA FOIS, et le suivant REMPLACE le précédent — au lieu du garde d'avant,
   `if(host.querySelector('.catmenu'))return;`, qui ne faisait RIEN de visible.
   ⚠ CE QUE LA MESURE DIT, ET QUI CORRIGE CE QUE J'ALLAIS ÉCRIRE : j'ai posé ce remplacement en
   croyant fermer un défaut atteignable — l'atelier aligne deux déclencheurs par rangée, et le
   voile ne ferme pas sur un clic portant `[data-catmenu]`, donc taper la pastille d'une autre
   rangée aurait laissé le menu de la précédente ouvert avec ses options. La sonde a refusé le
   scénario : sous forme de FEUILLE, le menu et son voile COUVRENT les pastilles (Playwright :
   « .catmenu-row intercepts pointer events »), et aucun doigt ne peut atteindre un second
   déclencheur sans avoir refermé le premier. Le remplacement reste — il coûte rien et rend le
   composant juste hors de ce logement (un appelant futur en menu ANCRÉ y serait exposé) — mais
   il est une CEINTURE, pas la réparation d'un symptôme observé, et il se dit comme telle (A72 :
   un commentaire qui affirme un mécanisme inexistant finit par le faire « réparer »).
   L'`aria-expanded`, lui, était bel et bien faux, et de façon atteignable — voir plus bas. */
```

## J95 — Flow SVG

```
/* ===== Flow SVG =====
   buildFlowSVG(f) : génère l'organigramme de la fiche, en SVG, par mise en page
   en COUCHES. Algorithme :
     1) BFS depuis le bloc de départ -> niveau (profondeur) de chaque bloc atteint ;
        les blocs orphelins (non reliés) sont empilés après le dernier niveau.
     2) Les blocs d'un même niveau forment une rangée centrée horizontalement.
        L'ORDRE dans la rangée est calculé par BARYCENTRE des positions des
        parents (haut->bas) pour limiter les croisements d'arêtes inutiles.
        Le TEXTE des titres/étapes/options est ENROULÉ (wrapText), jamais tronqué,
        et TOUTES les étapes sont affichées (plus de limite à 7) ; la hauteur du
        bloc s'adapte (LAY[id]).
     3) Arêtes : steps->next (sans label) ; decision->options (label = intitulé
        de la réponse, affiché dans une pastille). Connecteurs ORTHOGONAUX
        (angles droits), convention des algorithmes médicaux. Flèche via <marker>.
        - Arête AVANT (cible plus bas) : trait PLEIN gris. Les points de SORTIE
          (bas du bloc) sont triés par x de la cible (pas de croisement en X sous
          une décision) ; les points d'ENTRÉE (haut du bloc cible) sont répartis et
          triés par x de la source (convergence de plusieurs blocs lisible).
          Coude horizontal dans l'inter-rangée, flèche vers le bas (marqueur 'ah').
        - Arête RETOUR / BOUCLE (cible au même niveau ou plus haut) routée sur la
          marge DROITE (sortie côté droit de la source -> entrée côté droit de la
          cible). Boucle issue d'une DÉCISION (conditionnelle) = AMBRÉ POINTILLÉ
          (flèche 'ahb') ; boucle issue d'un bloc d'étapes (next inconditionnel =
          flux déterministe) = GRIS PLEIN, identique aux flèches descendantes
          (flèche 'ah'). Plusieurs boucles sont décalées horizontalement pour ne pas
          se superposer. Côté libre à droite -> tracé direct ; côté obstrué ->
          contournement par l'inter-rangée.
     4) Nœuds : 'steps' clairs / 'decision' ambrés ; le bloc de départ porte une pastille
        « DÉPART » ; le bloc COURANT (où l'on en est dans le parcours) est entouré d'un halo bleu.
   Retourne une chaîne <svg> dimensionnée (scroll horizontal si large).
   Utilisé en aperçu live dans l'éditeur et à la demande en lecture. */
// Enroulement de texte (retour à la ligne sur les mots) pour le SVG : aucune troncature,
// coupe les mots trop longs. Renvoie un tableau de lignes.
```

## J96 — ⚡ LES CIBLES DE COMPLICATION SE RECONNAISSENT DANS LE SCHÉMA (v5.0.9, proposition de

```
  /* ⚡ LES CIBLES DE COMPLICATION SE RECONNAISSENT DANS LE SCHÉMA (v5.0.9, proposition de
     l'auteur : « mettre un éclair et en rouge ? »). Elles y étaient dessinées comme un bloc
     d'étapes ORDINAIRE, posé dans une rangée de plus : le schéma était donc la SEULE des quatre
     vues de structure à ne pas dire qu'on n'y entre pas par la séquence — l'Échelle, le tableau
     Statique et la vue Parcours ont toutes leur section « À tout moment ». Un bloc hors séquence
     qui ressemble à l'étape d'après est précisément le défaut mesuré en v4.26.0 (« 5
     Laryngospasme » se lisait comme le cinquième temps du soin).
     REGISTRE ALERTE EN CONTOUR, JAMAIS EN APLAT (v4.26.1) : bandeau d'en-tête teinté, liseré et
     cadre rouges, corps du bloc INCHANGÉ — un aplat rouge permanent désensibilise au rouge, qui
     appartient ici aux étapes vitales dessinées à l'intérieur. Et la couleur n'est jamais seule
     (règle 8) : l'éclair est accompagné de « À TOUT MOMENT » en toutes lettres.
     La réachabilité est calculée ICI, sans passer par `cxDetached` : celui-ci appelle `flowPlan`,
     dont le cache est indexé par OBJET fiche et que l'éditeur — qui mute son brouillon en place —
     ne doit jamais peupler. Même critère, aucun cache. */
```

## J97 — ⚠ SIGNALÉ À L'USAGE : « on a perdu les flèches du schéma SVG, en dehors des blocs

```
  /* ⚠ SIGNALÉ À L'USAGE : « on a perdu les flèches du schéma SVG, en dehors des blocs
     conditionnels ». Diagnostic : ce test comparait `kind` à `'steps'` — une valeur qui
     N'EXISTE PLUS depuis les renommages de l'étape C (`type:'steps'` → `kind:'do'`). Tout bloc
     non-décision retombait donc dans la branche « décision » et rendait `options` = [] : AUCUNE
     arête n'était tracée pour les liens `next`, en silence, alors que les branches d'une décision
     — qui, elles, passent par `options` — continuaient de s'afficher. D'où le symptôme exact.
     ON TESTE DÉSORMAIS `!== 'decision'` : le jeu de valeurs de `kind` peut s'étendre (une fiche
     v4 déclare `do`), la décision reste le seul cas particulier — et un renommage futur du cas
     GÉNÉRAL ne pourra plus faire disparaître les flèches sans que rien ne crie.
     Même famille que `completionSpots` : après une migration de modèle, une comparaison à une
     ANCIENNE valeur ne lève aucune erreur — elle rend simplement toujours faux, et se tait. */
```

## J98 — 1. PROJECTION DE LA FICHE (`sharePayload`) — ce n'est PAS la fiche. Envoyer l'objet entier

```
   1. PROJECTION DE LA FICHE (`sharePayload`) — ce n'est PAS la fiche. Envoyer l'objet entier
      expédierait `localInfo` (pré-rempli « Tél renfort / Tél régulation »), jusqu'à 24 Mo
      d'images en base64, et des références de documents que l'invité ne pourra jamais ouvrir
      (aucun droit sur le bucket). Deux listes EXPLICITES, et un test qui échoue si un champ du
      modèle n'est classé ni dans l'une ni dans l'autre : ajouter demain un champ à `blankFiche`
      sans décider s'il se partage devient impossible.
   2. CAPACITÉS (`shareCan`) — MIROIR de `share_kind_allowed` côté serveur. Le client n'est
      qu'ergonomie : la vraie barrière est en SQL. Cette copie sert à masquer les commandes
      interdites, jamais à autoriser quoi que ce soit.
   3. PLI (`shareFold`) — l'état est un PLI du journal d'évènements, jamais une ligne mutée.
      `offline_mark` en est EXCLU par construction : le relevé d'un participant détaché est un
      rapport, pas une commande — il rejoint le journal, il ne touche pas l'état.
   4. EMPREINTE (`shareStateHash`) — détecte la DIVERGENCE SILENCIEUSE, celle qu'un indicateur
      de péremption ne verra jamais : les mises à jour arrivent à l'heure et sont fausses. Deux
      miroirs qui ne calculent pas la même empreinte ne s'accordent pas, et celui qui diverge se
      déclare périmé plutôt que d'afficher un état plausible.
   5. HORLOGE (`shareOffset`) — algorithme de Cristian. L'en-tête HTTP `Date` n'est PAS lisible
      en fetch cross-origin (hors liste CORS-safelisted) : l'heure serveur voyage donc dans le
      CORPS. Une mesure dont l'aller-retour dépasse le seuil est REJETÉE — en 4G dégradée on
      garde le dernier bon décalage plutôt qu'un mauvais frais. */
/* K6 (v4.70.0) : `discriminant` VOYAGE, et c'est un choix explicite. Il fait partie du NOM de la
   fiche — l'invité qui lirait « Arrêt cardiaque » là où l'hôte lit « adulte » serait exposé au
   piège même que ce champ supprime (deux fiches homonymes en crise). La règle 15 (« aucun texte
   libre ne traverse le réseau ») vise ce que l'on SAISIT PENDANT un soin — repères, notes,
   contexte local — pas l'identité de l'aide, dont le titre et le code voyagent déjà.
   CE CHAMP EXIGE DE REJOUER `supabase/schema.sql` : la liste blanche du serveur est l'autorité,
   et sans lui le discriminant serait filtré à l'arrivée (le client afficherait un vide). */
/* ÉTAPE B (v5.0.0) — LES SIX CHAMPS ONT DISPARU, DONC C'EST `items` QUI VOYAGE. Sans cette
   ligne, un invité recevrait des blocs pleins d'identifiants ne résolvant vers RIEN : une
   checklist vide, en pleine réanimation, sans le moindre signal.
   ⚠ LA LISTE BLANCHE DU SERVEUR DOIT SUIVRE (`share_fiche`, supabase/schema.sql) : c'est ELLE
   l'autorité, et un champ absent y est filtré à l'arrivée quoi qu'en dise le client. */
```

## J99 — Vocabulaire FERMÉ des évènements. Toute valeur hors de cette liste est refusée par le serveur ;

```
/* Vocabulaire FERMÉ des évènements. Toute valeur hors de cette liste est refusée par le serveur ;
   la liste est ici pour que le client sache quoi émettre, pas pour arbitrer. */
/* `mark_void` est ouvert au SCRIBE, contrairement à `uncheck` qui est réservé au lead — et la
   différence n'est pas une inconséquence. Décocher DÉTRUIT une information (l'étape redevient non
   faite, sans trace). Annuler un repère la CONSERVE : la ligne reste, barrée, attribuée, datée, et
   le geste est réversible. Ce n'est donc plus une action destructrice, et la doctrine qui réserve
   celles-ci au lead ne s'y applique pas. */
/* LA LIGNE PASSE SUR LA DESTRUCTION, PAS SUR LA HIÉRARCHIE (v4.55.0, décision utilisateur).
   Elle passait sur « conduire ou suivre », et c'était une MAUVAISE LECTURE de la source. AC 120-71B
   §5.2.2.1 décrit une répartition de la PAROLE — « one crewmember reading the checklist and the
   second confirming and responding » — et dans ce modèle c'est CELUI QUI LIT QUI FAIT AVANCER LA
   LISTE ; le lead est celui dont les mains sont prises. Toutes les autres sources disent la même
   chose : la SFAR (« le lecteur : sa seule tâche est de lire et de GUIDER »), l'ECAM (le pilot
   monitoring actionne l'ECP, le pilot flying pilote), et surtout McEvoy 2014 — l'essai qui donne
   99,5 % contre 70 %, la meilleure donnée du dossier — où LE LECTEUR TENAIT L'UNIQUE APPAREIL.
   La conception précédente empêchait donc exactement la configuration la mieux documentée.
   LE CRITÈRE ÉTAIT D'AILLEURS DÉJÀ ÉCRIT DANS CE FICHIER, pour `mark_void` : « annuler CONSERVE,
   décocher DÉTRUIT — ce n'est donc pas une action destructrice, et la règle qui réserve celles-ci
   au lead ne s'y applique pas. » Naviguer est append-only ; arrêter un minuteur conserve son
   `elapsedMs`. Ni l'un ni l'autre ne détruit quoi que ce soit : rien ne les justifiait au lead.
   RESTE RÉSERVÉ CE QUI DÉTRUIT OU CLÔT : décocher (efface une information), remettre à zéro un
   minuteur ou un compteur (efface un décompte que personne ne restitue), terminer le partage, et
   `session_start` — un fait sur LA session de l'hôte, pas un geste de participant.
   L'OBJECTION D'AMBIGUÏTÉ (§5.5, « qui fait quoi », qu'Airbus supprime par un ECP unique) est
   réelle et reçoit ici la réponse constante du projet : on n'INTERDIT pas, on ANNONCE — chaque
   geste est attribué, et une avance venue d'un autre écran se dit. */
```

## J100 — COMMENT UN ÉVÈNEMENT DISTANT ATTEINT L'ÉCRAN — quatre régimes, et le classement n'est PAS

```
/* COMMENT UN ÉVÈNEMENT DISTANT ATTEINT L'ÉCRAN — quatre régimes, et le classement n'est PAS
   « chirurgical vs re-rendant » comme on l'écrirait spontanément. Le vrai critère est : est-ce que
   ça déplace le sol sous le doigt, et est-ce que c'est LÉGITIME que ça le déplace ?
     'live'     — chirurgie DOM pure, applicable en direct : le <li> change, rien d'autre bouge.
     'anchored' — reconstruit le journal, DONC anCRÉ (keepAnchor) et ANNONCÉ (announce). Ce n'est
                  pas une entorse à la règle 11 : quand le pilote avance, le scribe DOIT suivre —
                  ECAM montre le même E/WD aux deux postes. Ce qui reste interdit, c'est qu'une
                  arrivée distante fasse disparaître du contenu AU-DESSUS de la position courante
                  (cf. `ovDropOpens` / condensation : jamais recalculée sur un geste distant).
     'deferred' — mis en file, appliqué au prochain geste LOCAL de navigation. La passe do-verify
                  d'un autre participant réorganiserait l'écran au milieu d'un geste, sans que rien
                  ne l'ait demandé : c'est la doctrine « acquittement par l'action ».
     'none'     — ne touche jamais le DOM de la checklist (annexe d'un détaché, changements de
                  statut, présence) : ils vivent dans le journal, le quai ou la feuille de partage.
   Un genre non classé est traité comme 'deferred' — le défaut prudent : différer n'a jamais
   avalé un tap, appliquer si. */
```

## J101 — Acteur du geste courant : `null` hors partage (« moi », il n'y a personne d'autre) ; l'identifiant

```
// Acteur du geste courant : `null` hors partage (« moi », il n'y a personne d'autre) ; l'identifiant
// public du participant sinon. C'est ce qui permettra au compte-rendu de dire QUI a constaté quoi.
/* « UNE SESSION DE CRISE EST À L'ÉCRAN » — critère de `body.crisis-live`, qui met les snackbars en
   attente (règle 11) et masque la méta de lecture pendant un soin. Il ne reflétait que
   `Runtime.started`, c'est-à-dire « MA session a démarré ». Or un invité qui SUIT une session
   partagée n'a rien démarré localement : toutes les banderoles flottantes — erreurs de synchro,
   conflits, échec d'enregistrement — lui passeraient par-dessus la checklist, exactement ce que la
   règle interdit. Le critère juste est la PRÉSENCE d'une session à l'écran, d'où qu'elle vienne. */
/* LA FIN DU PARTAGE N'EST PAS LA FIN DU SOIN (correctif). Le critère invité s'écrivait
   `status==='active'` : à l'instant EXACT où l'hôte coupait — ou à l'expiration, ou au
   détachement — `crisis-live` tombait, et deux mécanismes se rallumaient sur la checklist que le
   collègue tient encore en main : le déversement des snackbars mises en attente pendant tout le
   soin (jusqu'à 8, plafond de la file) et la ré-apparition de la méta de lecture, qui décale le
   contenu sous le doigt. L'invité est le seul à qui l'app ferait cela, et au pire moment.
   Le critère juste est la PRÉSENCE d'une fiche de crise à l'écran, quel que soit l'état du lien —
   la coupure se déclare SUR PLACE, dans le quai, elle ne déverrouille pas le chrome. */
```

## J102 — JETON D'ÉTAT DU PARTAGE DANS LE QUAI

```
/* ═══ JETON D'ÉTAT DU PARTAGE DANS LE QUAI ═══════════════════════════════════════════════════
   Le partage doit dire DEUX choses en permanence, à position constante, sur les deux écrans : QUI
   TIENT LA MAIN (AC 120-71B §6.4 pt 1 : aucune ambiguïté possible, jamais) et SI CE QU'ON VOIT EST
   ENCORE VRAI (donnée périmée affichée comme vivante = danger n° 2 du palmarès ECRI 2015).
   OÙ : dans le LIBELLÉ du chrono, et nulle part ailleurs. Trois emplacements ont été mesurés et
   écartés — un SEGMENT `⇄` propre déplace le segment d'alarme de 45 à 57 px selon la largeur, à
   son apparition ET à sa disparition, donc sur ÉVÈNEMENT DISTANT (les segments sont en `flex:1 1 0`,
   une insertion redistribue toute la rangée) ; la rangée de COMMANDES n'a que 2,1 px de marge à
   320 px ; et une 2ᵉ pilule sur le BANDEAU fait tomber le titre de fiche de 172 à 58 px. Le libellé
   du chrono, lui, coûte ZÉRO pixel de mise en page : le segment est déjà étiré par le flex.
   JEU FERMÉ ET COURT, jamais de prose : mesuré à 320 px avec un minuteur échu conservé, « · main »
   (42 px) et « · figé » passent sans déborder, « · vous conduisez » (116 px) déborde de 15 px.
   Et AUCUN COMPTEUR QUI BAT : un « figé 12 s » se réécrirait chaque seconde dans une zone qu'on
   apprend à lire d'un coup d'œil ; la péremption est un état, pas un chronomètre.
   LE LIEN REMPLACE LA MAIN, il ne s'y ajoute pas — decluttering ECAM, et surtout : quand le lien
   n'est plus nominal, le détenteur de la main N'EST PLUS CONNU. Afficher un compte de participants
   ou un rôle appris il y a une minute serait précisément la donnée périmée présentée comme vivante.
   Longueur maximale par construction : 8 caractères (« · coupé »), très en deçà de la borne. */
```

## J103 — ENTRÉE PAR APPARIEMENT — UNE DÉCISION DE DÉMARRAGE, PAS UNE CLASSE CSS

```
/* ═══ ENTRÉE PAR APPARIEMENT — UNE DÉCISION DE DÉMARRAGE, PAS UNE CLASSE CSS ═════════════════
   Mesuré sur un profil vierge, en chargeant `index.html#j=CODE` : l'application déposait
   3,17 Mo (le cache applicatif ET les 1 773 Ko de pdf.js), créait sa base IndexedDB, écrivait
   quatre clés `localStorage`, enregistrait un service worker — et appelait
   `navigator.storage.persist()`, c'est-à-dire demandait au navigateur de rendre ce dépôt NON
   ÉVINÇABLE — le tout AVANT que le premier mot de la notice d'information ait pu s'afficher.
   Une information préalable posée sur une collecte déjà faite n'informe rien.
   Le téléphone d'un collègue n'est pas un appareil de l'utilisateur : l'invariant d'étanchéité
   dit « l'invité ne garde rien », et cela se décide AU DÉMARRAGE, avant `load()` et avant
   l'enregistrement du worker — pas après coup par des classes CSS.
   TROIS CAS, et le troisième est le piège (règle 11) :
     · pas de code               -> démarrage normal ;
     · code sur appareil VIERGE  -> aucune empreinte : stockage en mémoire, aucun worker, aucune
                                    persistance demandée, aucun ensemencement, et l'écran d'entrée
                                    À LA PLACE de l'application ;
     · code sur un appareil qui utilise DÉJÀ l'app -> démarrage normal (lui refuser son worker ne
                                    protégerait rien et casserait son hors-ligne), écran d'entrée
                                    par-dessus — SAUF si une fiche de crise est à l'écran : on ne
                                    couvre pas une réanimation en cours par un écran non demandé.
                                    Le code est alors GARÉ et annoncé par le bandeau système, qui
                                    est déjà le canal « information persistante, accueil seulement ».
   Le fragment est retiré de l'historique IMMÉDIATEMENT : un code d'appariement n'a rien à faire
   dans l'URL d'un onglet qu'on rouvre, ni dans la barre d'adresse d'un téléphone prêté — et
   `_histArm()` recopie l'URL courante, fragment compris. */
```

## J104 — BRIDAGE — CE QU'UN SCRIBE PEUT, ET CE QU'IL VOIT

```
/* ═══ BRIDAGE — CE QU'UN SCRIBE PEUT, ET CE QU'IL VOIT ═══════════════════════════════════════
   La forme canonique du travail à deux n'est pas deux écrans jumeaux : « one crewmember reading
   the checklist and the second crewmember confirming and responding » (AC 120-71B §5.2.2.1). Le
   scribe ajoute et constate ; il ne DÉFAIT pas, il ne CONDUIT pas.
   `data-ck` PORTE DEUX GESTES OPPOSÉS — le handler fait `on = !state.checked[k]`, donc cocher ET
   décocher. Un masquage est donc impossible (il doit voir la ligne, et pouvoir cocher) : la garde
   vit dans le handler, sur la DIRECTION du geste. Et le cœur du cochage existe en DEUX COPIES —
   celles-là mêmes qui ont divergé en v4.42.0, où le reset de fin d'algorithme n'était fait que
   dans l'une. D'où un prédicat UNIQUE, appelé aux deux endroits : la divergence devient
   impossible par construction, pas par vigilance.
   REFUSER SANS BANDEROLE : la règle 11 interdit toute notification flottante pendant un soin, et
   `toast()` est de toute façon mis en attente. Le refus s'annonce donc sur `#srLive` (invisible à
   l'écran, audible au lecteur d'écran) et se VOIT sur la ligne elle-même, qui ne change pas
   d'état. Rien ne bouge, rien ne saute : la géométrie est identique refus ou non. */
/* ═══ I4 (v4.62.0) — UNE SEULE GRAMMAIRE DE PROGRESSION : LE CŒUR ═══════════════════════════
   POURQUOI, ET C'EST DOCTRINAL (décision utilisateur, argumentaire retenu tel quel) :
     · ECAM — l'affichage d'Airbus repose sur UN format unique pour tous les états : le pilote
       n'apprend pas trois écrans, il apprend UNE grammaire (position fixe, registres, priorités)
       qui se décline. Trois surfaces de progression, c'est l'anti-ECAM — trois cartographies
       mentales pour la même information. Harmonisées, celui qui a appris l'écran hôte SAIT déjà
       lire l'écran invité.
     · QRH — un manuel n'a qu'UNE mise en page de checklist, quel que soit le lecteur : celui qui
       LIT et celui qui EXÉCUTE regardent le MÊME document, et c'est ce qui rend possible le
       cross-check à voix haute (« bloc 2, ligne 2 »). Si le lecteur voit une autre structure que
       l'hôte, la vérification croisée se désynchronise.
     · FAA (facteurs humains) — la MODE CONFUSION naît d'un même écran qui se comporte
       différemment selon le mode SANS signal univoque. La réponse canonique est : structure
       CONSTANTE + annonciateur de mode saillant — pas des écrans différents. Ici l'interactivité
       et le placard changent ; la structure, jamais.
   ET L'ARGUMENT D'INGÉNIERIE QUI EN DÉCOULE : trois surfaces = trois endroits où un correctif
   peut diverger. Ce n'est pas théorique — ce fichier a payé DEUX FOIS : les copies du cœur de
   cochage avaient divergé en v4.42.0, et en v4.55.0 un invité scribe CONDUISAIT la checklist
   depuis le lecteur parce que ses verbes portaient d'autres noms (`data-rmnext` au lieu de
   `data-ovnext`) et échappaient donc à la liste des gestes réservés.
   `applyCheck` est LE point d'écriture de `state.checked`. Il porte la garde de rôle, la trace
   do-verify, l'acquittement haptique, le démarrage de session et l'enregistrement. Les trois
   appelants (guidé, journal, lecteur) ne font plus que PEINDRE ce qu'il a décidé. */
```

## J105 — CE QUI REVIENT À CELUI QUI CONDUIT. Liste des verbes réservés au lead, EXPRIMÉE UNE FOIS et

```
/* CE QUI REVIENT À CELUI QUI CONDUIT. Liste des verbes réservés au lead, EXPRIMÉE UNE FOIS et
   consommée aux deux bouts : le CSS s'en sert pour montrer que c'est désactivé, la garde déléguée
   pour le faire respecter. Deux listes divergeraient — c'est la leçon de la v4.42.0.
     · avancer, terminer, refaire, choisir une branche, sauter à un bloc  -> `nav` / `flow_end`
     · arrêter ou remettre à zéro un minuteur, remettre à zéro un compteur -> `timer_stop` / `timer_reset`
   Ce qui reste OUVERT au scribe, et c'est tout l'objet du rôle : cocher, constater, signaler un
   écart, INCRÉMENTER un compteur, ARMER un minuteur, poser et annuler un repère horodaté.
   INCRÉMENTER MAIS PAS REMETTRE À ZÉRO n'est pas une subtilité : ajouter est additif et
   réversible par le journal, remettre à zéro DÉTRUIT un décompte que personne ne peut restituer. */
/* LE VOCABULAIRE PARALLÈLE DU LECTEUR N'EXISTE PLUS (I4, v4.62.0). Il avait coûté un incident :
   `data-rmnext` (avancer, terminer) et `data-rmopt` (choisir une branche) étaient les MÊMES
   verbes que `data-ovnext` et `data-ovopt` sous d'autres noms, et un invité scribe conduisait
   donc la checklist depuis le lecteur alors que la page la lui refusait (v4.55.0). Ce n'était pas
   un défaut de PORTÉE — la garde en capture atteint bien `#readerMode` — mais de PRÉDICAT : la
   liste ne les nommait pas. On a d'abord ajouté les noms manquants ; on SUPPRIME maintenant le
   besoin de s'en souvenir — le lecteur ÉMET les verbes du journal. Un verbe ajouté demain sera
   couvert des deux côtés d'office, parce qu'il n'y a plus de « deux côtés ».
   `data-rmok` et `data-rmgap` RESTENT propres au lecteur, et c'est délibéré : ce sont les gestes
   de la passe challenge-réponse (« Répondu », « Écart »), OUVERTS au scribe — c'est même toute
   sa raison d'être. Ils ne sont pas des synonymes d'un verbe du journal, donc rien à fusionner. */
/* NE RESTENT QUE LES GESTES DESTRUCTEURS. `[data-ovnext]`, `[data-ovopt]`, `[data-plgo]`,
   `[data-svgo]`, `[data-svref]`, `[data-cxback]`
   et `[data-ovredo]` en SORTENT (v4.55.0) : naviguer, choisir une branche, refaire un passage et
   reprendre après une complication sont tous append-only. Le scribe relaie une consigne — « pause
   le minuteur, il reprend un rythme » — sans que le médecin ait à reprendre son téléphone.
   `[data-ovend]` sort aussi : terminer l'algorithme pose un drapeau réversible, ce n'est pas
   terminer la session. */
```

## J106 — LIEN MORT — CE QUE L'INVITÉ VOIT (proposition utilisateur : « améliorer le mode invité

```
/* ═══ LIEN MORT — CE QUE L'INVITÉ VOIT (proposition utilisateur : « améliorer le mode invité
   lorsque la session est coupée / se termine → tout griser avec un message ») ═════════════════
   AVANT, l'écran de l'invité ne changeait RIEN quand le partage mourait : le quai remplaçait un
   jeton de sept caractères (« suit » → « fini »), et un geste tenté produisait une annonce
   INVISIBLE sur `#srLive`. Autrement dit, la seule façon d'apprendre qu'on ne recevait plus rien
   était d'essayer quelque chose — et de ne rien voir se passer. C'est le pire mode de défaillance
   nommé par le plan de partage (« cocher dans le vide en croyant contribuer »), et la donnée
   périmée présentée comme vivante (danger n°2 du palmarès ECRI 2015).
   TROIS DÉCISIONS, ET DEUX REFUS.
   1. UN BANDEAU DANS LE FLUX, en tête du contenu, PAS une modale ni une banderole : la règle 11
      interdit d'interrompre un écran de crise, et l'invité tient encore une fiche en main — il
      doit pouvoir continuer à la LIRE. L'annonce se fait sur place, comme une alarme de minuteur.
   2. LES CONTRÔLES PRENNENT L'APPARENCE DÉSACTIVÉE (cf. CSS `body.share-dead`), au patron exact
      de `share-scribe` : c'est CELA que « griser » veut dire ici, et c'est le seul greying que
      WCAG exempte de son seuil de contraste — celui d'un contrôle indisponible.
   3. LE TEXTE CLINIQUE N'EST PAS GRISÉ, ET C'EST UN REFUS ASSUMÉ. Estomper les étapes serait
      passer sous AA (le projet a déjà tranché ce point pour le « hors chemin » du rail, et deux
      fois pour le bridage du scribe), et surtout : ce qui est écrit là reste VRAI et reste utile —
      c'est le dernier état connu du soin, pas une information caduque. On ne rend pas illisible ce
      qu'on demande à quelqu'un de continuer à lire.
   4. AUCUNE DÉSATURATION D'ENSEMBLE non plus : un filtre sur la colonne éteindrait le rouge des
      étapes vitales et l'ambre des vigilances — la règle 8 interdit de toucher aux registres pour
      un motif d'état de liaison.
   Le bandeau porte la SORTIE (« Quitter le partage… », le geste qui existe déjà) : un écran figé
   sans porte est ce que la v4.47.0 s'était donné pour tâche de supprimer. */
```

## J107 — ÉMISSION PAR DIFFÉRENCE — UN SEUL POINT D'ACCROCHE, ET C'EST DÉLIBÉRÉ.

```
/* ÉMISSION PAR DIFFÉRENCE — UN SEUL POINT D'ACCROCHE, ET C'EST DÉLIBÉRÉ.
   L'alternative était d'appeler `Share.emit` depuis chaque verbe de mutation. Le recensement en a
   trouvé SOIXANTE (41 attributs `data-*` en vue lecture, plus 19 contrôles à `id` sans aucun
   `data-*`) : autant d'endroits où un oubli serait silencieux, et où toute mutation ajoutée demain
   échapperait au partage sans que rien ne le signale. On DIFFE donc l'état, en un seul endroit —
   `persistLive`, par où passe déjà toute modification de session. Ce qui est couvert par
   l'enregistrement local l'est mécaniquement par le partage.
   `shareSnap` est PURE et normalise ce qui doit voyager : les minuteurs perdent `lastStart` (une
   heure LOCALE) au profit d'une ancre absolue, la trace do-verify passe par `vfMapNorm`. Ce qui
   ne voyage pas n'entre pas dans l'instantané — c'est la liste SHARE_TRAVELS, testée.
   `shareDiff` est PURE aussi : deux instantanés donnent une suite d'évènements du vocabulaire
   fermé. C'est ce qui rend l'émission testable sans navigateur, sans réseau et sans horloge. */
```

## J108 — 1. SIGNALISATION COMPACTE. On ne transmet JAMAIS le SDP brut (~1 500 o) : on extrait le

```
   1. SIGNALISATION COMPACTE. On ne transmet JAMAIS le SDP brut (~1 500 o) : on extrait le
      quintuple {ufrag, pwd, empreinte DTLS, rôle, candidats hôte} (~130 o compressés = un QR)
      et on RECONSTRUIT un SDP minimal de l'autre côté. Validé à parité brut/reconstruit sur
      Chromium ET WebKit par la sonde.
   2. TRAME RPC. Le canal transporte les verbes `_io` tels quels : {i,n,p} → {i,r}|{i,e}.
      Une trame illisible rend null — l'appelant ignore, jamais d'exception depuis le fil.
   3. LE HUB. Quand il n'y a pas de serveur, l'HÔTE tient la sémantique serveur — les mêmes
      règles que `supabase/schema.sql` § 8, réduites à un partage : allocation de séquence sous
      compteur unique (l'ordre des numéros EST l'ordre de visibilité), dédup par `event_id`,
      `actor` DÉDUIT du secret (jamais un paramètre — l'attribution EST le contrôle),
      capacités par rôle via `shareCan` (déjà le miroir exact du serveur), empreinte de flux
      au MÊME format que `_streamHash` (sha-256 des couples « seq:id » joints par des
      virgules). Le pli, l'application, la file hors-ligne ne changent pas : un journal
      append-only se moque de qui le numérote. */
```

## J109 — Runtime panel (rendu des minuteurs/compteurs en lecture)

```
/* ===== Runtime panel (rendu des minuteurs/compteurs en lecture) =====
   timerCard(t)   : carte d'un minuteur. 'stopwatch' -> temps qui monte ;
     'interval' -> temps restant qui descend + barre de progression + "Cycles : n".
     Les valeurs initiales sont calculées ici ; ensuite refreshTimersDOM() rafraîchit
     les éléments par id (tmval-/tmcyc-/tmbar-). Boutons Démarrer/Pause et Réinit.
   counterCard(c) : carte d'un compteur (valeur + boutons - / +).
   runtimePanel(f): assemble le bandeau (rien si la fiche n'a ni minuteur ni
     compteur) avec un bouton son 🔔/🔕. */
/* LA LIGNE « ARRÊTÉ DEPUIS » (v5.6, planche 11j) — texte AMBRE, jamais un aplat : A11 réserve la
   masse colorée à ce qui exige une action maintenant, et ceci est une LECTURE.
   ⚠ ELLE NE PARAÎT QUE SUR UN MINUTEUR EN PAUSE, ET C'EST A9 QUI L'IMPOSE. Un état non commandé
   ne doit modifier aucune hauteur : la pause arrive par un TAP (ou au chargement, où la ligne est
   déjà là), donc la carte a le droit d'y gagner une ligne. Un minuteur ÉCHU, lui, le devient tout
   seul — il n'en reçoit aucune, et de toute façon l'alarme dit déjà ce qu'il faut savoir.
   ⚠ ET AUCUN SEUIL : « n'afficher qu'au-delà de 30 s » ferait apparaître une ligne — donc grandir
   la carte — SANS geste, ce qu'A9 interdit. Elle paraît au tap et son nombre avance ensuite. */
```

## J110 — ⚠ UN CHRONOMÈTRE DIT QU'IL EN EST UN (v5.10.8, signalé à l'usage : « les chronomètres s'affichent

```
/* ⚠ UN CHRONOMÈTRE DIT QU'IL EN EST UN (v5.10.8, signalé à l'usage : « les chronomètres s'affichent
   pareils que les minuteurs, impossible à distinguer visuellement »). Il n'y avait AUCUNE marque
   positive : la seule différence était une ABSENCE — pas de barre, pas de « Cycles : n » —, et une
   absence ne se lit pas, surtout sur un minuteur qu'on vient de poser (barre pleine, « Cycles : 0 »
   ressemble déjà à « rien »). Le nom par défaut disait bien « Chronomètre », mais il disparaît dès
   que l'auteur nomme l'objet, c'est-à-dire toujours. Un temps qui MONTE et un temps qui DESCEND
   commandent des gestes opposés : les confondre en réanimation, c'est lire « 05:00 » comme « il
   reste cinq minutes » quand il s'est écoulé cinq minutes.
   LA MARQUE OCCUPE LA PLACE DE LA BARRE ET DU COMPTE DE CYCLES — le même emplacement, jamais un
   emplacement nouveau : les deux natures ont alors la même silhouette, et c'est la LIGNE qui les
   sépare, pas la hauteur de la carte. Glyphe ET mot (règle 8), aucune couleur : ce n'est pas un
   état, c'est une nature. Rien ne bouge sur les minuteurs d'intervalle. */
```

## J111 — v5.4.0 — LE JOURNAL REJOINT LE PANNEAU DES MINUTEURS (décision utilisateur, vécu en situation

```
/* v5.4.0 — LE JOURNAL REJOINT LE PANNEAU DES MINUTEURS (décision utilisateur, vécu en situation
   réelle : « pour changer l'un puis l'autre on doit passer au-dessus des étapes ») : minuteurs,
   compteurs et journal des actions vivent ENSEMBLE — le geste FRÉQUENT (« ⏱ Noter », accusé,
   suggestions) reste dans la CARTE du bloc (lot M7), le panneau est la vue de DÉTAIL. En LARGE le
   rail garde son ordre (minuteurs → posologie → Échelle → journal).
   v5.4.2 : la rangée repliée du flux qui portait cet accès en étroit est SUPPRIMÉE (cf. la
   doctrine dans runtimePanel) — le quai est l'accès unique, `rtRowLabel` est parti avec elle. */
/* ══ LE MINUTEUR AD HOC DIT CE QU'IL CRÉE, ET SA DURÉE SE CHOISIT (v5.6, planche 11h) ═════════
   Le geste existait et il était juste — un tap, objet déjà réglé, démarré, supprimable : le risque
   n'est pas la CRÉATION, c'est la SAISIE. Deux limites mesurées : la durée valait 300 s en dur, et
   le nom DÉGÉNÉRAIT (`'PA'+(n+1)` → « PA, PA 2, PA 3 »), c'est-à-dire trois minuteurs qui ne
   disaient plus ce qu'ils surveillaient.
   · LE NOM VIENT DU DERNIER REPÈRE (`tkLabels`, vocabulaire déjà normalisé) et le bouton l'annonce
     AVANT le tap. Aucun repère encore noté → le libellé d'avant : la proposition n'invente pas un
     mot quand elle n'en a pas.
   · LA DURÉE SE CHOISIT EN UN SECOND TAP, parmi QUATRE valeurs. Jamais de champ, jamais de
     clavier ; et un SEUL ＋ qui déplie, jamais quatre ＋ dans une rangée que la largeur du volet ne
     supporte pas.
   ⚠ RÈGLE 15 — ET ELLE SE VÉRIFIE, ELLE NE SE SUPPOSE PAS : `label` est strictement local. Mesuré :
   `shareSnap` n'envoie d'un minuteur que `{running, elapsedMs, cycles, anchor}` sous sa CLÉ, et un
   minuteur ad hoc n'existe pas chez l'invité (il vit dans la session, qui ne voyage pas). Le nom
   tiré d'un repère ne peut donc pas traverser le réseau : la contrainte est tenue par construction,
   pas par une garde qu'il faudrait maintenir. */
```

## J112 — ⚠ PLUS DE « PA » PAR DÉFAUT (v5.6, demande de l'auteur). C'était le reste du geste d'origine —

```
  /* ⚠ PLUS DE « PA » PAR DÉFAUT (v5.6, demande de l'auteur). C'était le reste du geste d'origine —
     « ＋ Minuteur PA 5:00 », un minuteur de surveillance tensionnelle câblé en dur. Le bouton pose
     maintenant n'importe quel minuteur : lui laisser le nom d'un usage particulier, c'est nommer
     autre chose que ce qu'il fait. Sans nom pressenti, il ne dit que sa NATURE. */
  /* ⚠ ET IL NE DEVINE PLUS DU TOUT (v5.6, signalé à l'usage : « comment as-tu trouvé l'intitulé
     automatique après ＋ Minuteur, c'est très mauvais et ça ne se met pas à jour à chaque bloc »).
     Le nom pressenti venait du DERNIER REPÈRE horodaté (`tmAddName` → `tkLabels`), pas du bloc
     courant : il ne pouvait donc pas suivre les blocs — et sa qualité dépendait entièrement de ce
     que l'on avait étiqueté avant, c'est-à-dire souvent de rien. Deviner à partir d'une source qui
     n'a aucun rapport avec le geste, c'est fabriquer un mot ; la planche 11h le disait déjà pour
     les libellés de repli (A85), la règle vaut pour la source elle-même.
     LE NOM SE POSE APRÈS, comme pour le compteur ad hoc : « — nommer » sur la carte (A86). Le
     geste reste deux taps sans clavier, et le clavier n'entre que si l'on VEUT nommer. */
```

## J113 — ⚠ P4 (v5.7) — L'ÉCHU EN TÊTE, ET SEULEMENT AU RENDU. C'est la règle ECAM de « l'action au

```
/* ⚠ P4 (v5.7) — L'ÉCHU EN TÊTE, ET SEULEMENT AU RENDU. C'est la règle ECAM de « l'action au
   pied de l'alerte » : on tape le quai PARCE QU'un minuteur sonne, et le volet s'ouvrait sur sa
   première carte — avec quatre minuteurs et deux compteurs, il fallait chercher, dans un volet
   plafonné à 45 % de la hauteur, celui que le geste désignait sans ambiguïté.
   ⚠ LE TRI NE VIT QUE DANS LE RENDU, ET C'EST LA MOITIÉ QUI COMPTE : le volet ouvert ne se
   re-rend pas au tick (repeinture chirurgicale), donc AUCUNE carte ne se déplace sous le doigt
   quand une échéance survient. Les cartes portent « Relancer », « ✓ Vu » et « Remettre à zéro » :
   déplacer une cible à l'instant où l'alarme approche est exactement le risque que la constance
   positionnelle existe pour supprimer. L'imminence, elle, n'est annoncée QUE dans la capsule, où
   le seul geste est « ouvrir le volet » — un tri n'y peut pas provoquer d'erreur de visée.
   L'ordre de l'AUTEUR est conservé entre minuteurs de même état (tri stable). */
/* L'ORDRE VIVANT — une seule fonction pour le rendu ET pour le tick. Deux tris écrits
   séparément auraient divergé le jour où l'un des deux aurait appris un cas ; ce fichier a
   déjà payé cette leçon quatre fois. Rang : l'ALARME d'abord (échu non acquitté), puis ce qui
   TOURNE par temps restant croissant, puis le reste — en pause, chronomètre, échu acquitté —
   dans l'ordre de l'AUTEUR, qui est conservé entre pairs (tri stable par index). */
```

## J114 — ⚠ LE GARDE — RIEN NE BOUGE SOUS UN DOIGT POSÉ. Les cartes portent « Relancer », « ✓ Vu » et

```
/* ⚠ LE GARDE — RIEN NE BOUGE SOUS UN DOIGT POSÉ. Les cartes portent « Relancer », « ✓ Vu » et
   « Remettre à zéro » (dont un appui PROLONGÉ) : réordonner entre le pointerdown et le clic
   ferait taper le bouton du voisin. Le tri est donc suspendu tant qu'un pointeur est posé dans
   un panneau, et repris au relâchement — le retard vaut au plus la durée d'un appui. */
/* ⚠ ET LE GARDE DEVIENT UN DÉLAI DE GRÂCE (v5.7, demande de l'auteur : « un tout petit temps
   de latence pour que l'utilisateur comprenne qu'il a bien touché le bon minuteur »). C'est
   meilleur que ma version, et pour une raison que je n'avais pas vue : le geste le plus fréquent
   sur une carte est « Relancer », qui remet le temps restant au MAXIMUM — la carte tomberait donc
   au bas de la liste À L'INSTANT où l'on vient de la toucher, et l'on ne verrait pas son accusé.
   Le tri attend la fin du geste PLUS 1,2 s : assez pour lire la réponse de la carte (la valeur
   repart, les boutons changent), sous la seconde et demie où un mouvement différé se met à
   ressembler à un raté.
   ⚠ NON BLOQUANT PAR CONSTRUCTION, et c'est ce qui le rend admissible : ce délai ne suspend QUE
   la réorganisation. Les minuteurs continuent de courir, les valeurs de se peindre à chaque tick,
   les boutons de répondre, la capsule d'annoncer. Rien n'est mis en file, rien n'attend — au pire
   l'ordre de la liste est en retard de 1,2 s sur celui de la capsule, qui, elle, ne bouge pas.
   Le clavier compte comme un doigt : tant que le focus est DANS une carte, on ne la déplace pas. */
```

## J115 — ⚠ LES DEUX INTERRUPTEURS FORMENT UN GROUPE INSÉCABLE (v5.6, signalé à l'usage : « le bouton

```
  /* ⚠ LES DEUX INTERRUPTEURS FORMENT UN GROUPE INSÉCABLE (v5.6, signalé à l'usage : « le bouton
     veille apparaît toujours en dessous du bouton son »). Ils tenaient sur la même ligne à partir
     de 390 px, et pas en dessous — mesuré : à 375 il manquait DEUX pixels, à 360 dix-sept, à 320
     trente-trois. Espérer qu'ils tiennent est une erreur de méthode : ce qu'on veut n'est pas
     « qu'ils rentrent », c'est qu'ils ne se séparent JAMAIS — deux réglages jumeaux, de même
     grammaire, dont l'un tombe seul sous l'autre se lisent comme deux objets sans rapport.
     Enveloppés, ils enroulent ENSEMBLE : soit sur la ligne du titre, soit sur la suivante, côte à
     côte. C'est l'AVERTISSEMENT qui part en premier s'il faut couper quelque part, et c'est le bon
     ordre — il n'est pas un réglage.
     ⚠ `.rt-wl` EST PURGÉE AVEC SA CAUSE (règle 14) : elle n'existait que pour masquer le mot
     « silencieux ? » sous 560 px, quand la rangée d'en-tête n'avait plus la place (A103). La
     rangée n'existe plus — l'avertissement a retrouvé ses mots, et un glyphe de caution muet
     n'aurait de toute façon rien averti.
     ⚠ ET LE GROUPE A QUITTÉ L'EN-TÊTE DE FAMILLE (v5.6, signalé à l'usage : « deux boutons
     utilisés périodiquement prennent autant de place avant les minuteurs-compteurs-journal »).
     Enveloppés, ils enroulaient ensemble — mais ENSEMBLE SUR UNE SECONDE LIGNE, y compris dans le
     rail de 301 px où le groupe en demande 311 : une rangée entière au-dessus du contenu vivant,
     pour deux réglages qu'on touche une ou deux fois par soin. Ce sont des RÉGLAGES, pas de
     l'état : ils descendent au PIED du panneau, après ce qu'ils règlent — l'ordre ECAM (l'état
     vivant d'abord) et celui que le rail applique déjà (« l'illimité en dernier »). Ils y gardent
     leurs mots, donc l'état se lit toujours sans réfléchir (A103), et ne coûtent plus un pixel
     au-dessus des minuteurs. */
```

## J116 — ⚠ CORRECTIF À ZÉRO PIXEL (v5.7, volet 3) — LA PROGRESSION D'UN JALON SORT DE SON BLOC.

```
  /* ⚠ CORRECTIF À ZÉRO PIXEL (v5.7, volet 3) — LA PROGRESSION D'UN JALON SORT DE SON BLOC.
     Un jalon ne s'affiche que sur la carte du bloc qui le déclare (`jalonsHtml`) : dès qu'on est
     ailleurs — une complication, un bloc plus loin, la feuille « Tout voir » — « Chocs 2/3 »
     disparaît, alors que le COMPTE, lui, continue d'avancer. C'est le second manque que le refus
     de F2 a révélé, et il se répare là où l'état vit déjà : le volet.
     · UNE LIGNE PAR JALON, jamais une carte : ce n'est pas un objet qu'on manipule, c'est un
       compte qu'on lit (A16 — ce qui se LIT prend une ligne).
     · LE MÊME CALCUL QUE LA CARTE (`jalonProg`, `jalonCondLbl`) : deux progressions écrites
       séparément finiraient par diverger, et ce fichier a déjà payé cette leçon cinq fois.
     · RIEN À DIRE → AUCUNE SECTION : une fiche sans jalon n'en voit pas la trace.
     · LE SEUIL FRANCHI SE MARQUE en ambre, comme sur la carte — jamais un aplat (A11), et le
       glyphe △ accompagne la couleur (règle 8). */
```

## J117 — ⚠ L'EN-TÊTE DU VOLET **EST** LE SOUS-TITRE « MINUTEURS » (v5.10.8, signalé à l'usage : « la

```
  /* ⚠ L'EN-TÊTE DU VOLET **EST** LE SOUS-TITRE « MINUTEURS » (v5.10.8, signalé à l'usage : « la
     ligne “Minuteurs · compteurs · journal” avec croix prend beaucoup de hauteur »). Mesuré à
     390 px : 48 px de rangée de titre + 8 d'écart + 17 de sous-titre « MINUTEURS » + 8 = 81 px
     avant la première carte, pour DEUX rangées qui nomment la même chose à un mot près — c'est
     exactement le doublon de vocabulaire qu'AC 120-71B §5.5 proscrit, payé ici en hauteur d'écran
     pendant un soin. Les deux rangées portaient déjà la MÊME grammaire (`.tk-head b` et
     `.rt-head b` sont la même déclaration : 11 px, petites capitales, `--sys-ink-2`) : les fondre
     ne crée aucune forme nouvelle, elle en supprime une redondante.
     Le titre du volet devient donc le premier sous-titre de famille, et le ✕ vit dans SA rangée —
     « Compteurs » et « Jalons » gardent la leur, inchangées. La fermeture reste TRIPLE (V1) : le
     ✕ est là, à 36 px de dessin pour 48 de cible (halo, cf. `.rt-x`), et le re-tap du quai, Échap
     et le tap hors volet n'ont pas bougé. Mesuré après : 44 px au lieu de 81. */
```

## J118 — timekeeperPanel : journal d'horodatage. Bouton « Horodater » -> ajoute un repère à l'heure

```
/* timekeeperPanel : journal d'horodatage. Bouton « Horodater » -> ajoute un repère à l'heure
   courante avec un libellé automatique ("Action N"), renommable à tout moment (même a
   posteriori en reprenant une session). Chaque ligne montre l'heure (HH:MM:SS) et le délai
   écoulé depuis le 1er repère. Persisté dans la session (Runtime.events / session.events).
   L'heure est CORRIGEABLE (clic dessus) pour rattraper un clic tardif : correction NON
   DESTRUCTIVE -> la toute première heure enregistrée (e.origT) reste affichée et un bouton
   permet d'y revenir, plutôt que de la faire disparaître silencieusement. */
/* REPÈRE RÉFÉRENTIEL (v4.47.0). Un repère du journal peut désormais porter une RÉFÉRENCE plutôt
   qu'un mot : `{type:'counter', id, v}`. Le libellé se DÉRIVE à l'affichage, depuis la fiche.
   Trois raisons, et la troisième est celle qui a décidé :
     1. C'est ce qui permet d'incrémenter un compteur et d'obtenir « Choc n° 3 — 14:32 » sans que
        personne n'ait à taper quoi que ce soit sous stress.
     2. Sur le fil de partage, AUCUN texte libre ne circule : une référence traverse le réseau,
        chaque appareil rend le libellé depuis SA copie de la fiche. L'invariant « aucun texte
        libre transmis » tient sans exception.
     3. Le libellé automatique « Action N » était calculé À L'ÉCRITURE, sur la LONGUEUR LOCALE du
        tableau (`'Action '+(events.length+1)`). À deux appareils, chacun produisait son « Action 4 »
        et le compte-rendu — la seule sortie qu'on relit à froid — affichait deux fois le même
        numéro puis sautait. Il se calcule maintenant au RENDU, par rang chronologique.
   Un libellé SAISI À LA MAIN gagne toujours : le renommage existant reste souverain, et un
   enregistrement antérieur (qui porte « Action 3 » en dur) s'affiche exactement comme avant. */
/* ═══ VOCABULAIRE DU JOURNAL — DES RÉFÉRENCES, JAMAIS DES MOTS (v4.52.0) ═══════════════════════
   Un repère partagé ne porte AUCUN mot : il porte une RÉFÉRENCE, et chaque appareil rend le
   libellé depuis SA copie de la fiche. C'est ce qui tient la promesse « aucun texte libre ne
   traverse le réseau » (règle 15) sans condamner le journal au mutisme — jusqu'ici `ref` n'existait
   QUE pour les compteurs, si bien qu'un repère posé par l'hôte s'affichait « Action 3 » chez
   l'invité : l'heure était juste, le mot manquait.
   QUATRE SOURCES, cumulatives, et rien n'est jamais perdu :
    1. LA FICHE elle-même — minuteurs, compteurs, étapes, repères posologiques. Toute aide apporte
       donc son vocabulaire sans qu'on ait rien à déclarer, et il suit ses mises à jour.
    2. UN NOYAU UNIVERSEL livré (ci-dessous) : ce qui se note dans toute intervention, quelle que
       soit la fiche.
    3. LE VOCABULAIRE PERSONNEL avec alias (`data.prefs.tags`, déjà synchronisé), édité À FROID.
       C'est là que vivent les abréviations qu'on se découvre à l'usage.
    4. RIEN DU TOUT — et c'est le cas nominal. « Noter l'heure » reste UN TAP qui capture l'heure,
       c'est-à-dire ce qui compte cliniquement, sans dépendre d'aucun vocabulaire. L'étiquetage est
       facultatif et différable au débrief. Pire cas d'un vocabulaire incomplet : un repère non
       étiqueté côté partagé, et le mot exact EN LOCAL chez celui qui l'a tapé.
   « AUTRE » N'EST PAS DANS LE NOYAU, et ce n'est pas un oubli : l'absence de référence EST
   « autre ». Une étiquette qui ne distingue rien n'apprend rien à qui relit le compte-rendu.
   RÉSOLUTION FAILLIBLE PAR CONSTRUCTION : `tagLabel` rend `null` quand la référence ne se résout
   pas — fiche d'une autre version, étape supprimée, étiquette effacée. Le repère retombe alors sur
   « Action n », jamais sur un mot inventé. */
```

## J119 — Le vocabulaire disponible ICI, MAINTENANT. Pur : la fiche et les étiquettes entrent, une liste

```
/* Le vocabulaire disponible ICI, MAINTENANT. Pur : la fiche et les étiquettes entrent, une liste
   annotée sort. Aucun filtrage — c'est `tagRank` qui ordonne, et le rendu qui décide combien il
   en montre. */
/* ══ LES OBJETS AD HOC SONT DES OBJETS DE LA SESSION, PAS DE LA FICHE (v5.6, signalé à l'usage :
   « un nouveau compteur n'apparaît pas dans Noter l'heure ») ═══════════════════════════════════
   `tagAll` et `tagLabel` lisaient `f.timers` / `f.counters` — or un minuteur ou un compteur créé
   EN SESSION vit dans le Runtime (`adhoc`, `adhocCounters`), donc il était visible à l'écran et
   introuvable au moment de l'horodater : exactement le défaut qu'A58 avait corrigé pour les objets
   SANS NOM, revenu par une autre porte.
   ⚠ LES DEUX FONCTIONS RESTENT PURES : la session passe ses objets en PARAMÈTRE (`ex`), elle n'est
   pas lue depuis leur corps. C'est ce qui permet au compte rendu d'une session ARCHIVÉE de
   résoudre les mêmes noms, en lisant `extraTimers`/`extraCounters` de l'instantané.
   ⚠ ET LA SUPPRESSION SUIT SANS RIEN ÉCRIRE : le vivier est CALCULÉ à chaque appel, donc un
   compteur supprimé disparaît de « Noter l'heure » par construction. */
```

## J120 — PROPOSER SANS QU'ON AIT TAPÉ (v5.0.0, signalé à l'usage : « ne propose pas toujours des

```
/* PROPOSER SANS QU'ON AIT TAPÉ (v5.0.0, signalé à l'usage : « ne propose pas toujours des
   libellés, et ils sont peu nombreux »). `tagPaintSug` n'ouvrait la bouche qu'à partir de deux
   caractères — donc jamais dans le geste le plus fréquent, qui est UN TAP et rien d'autre. Or le
   contexte suffit à proposer : au moment où l'on horodate, ce qu'on vient de faire est presque
   toujours une étape DU BLOC OÙ L'ON EST, ou un objet de la fiche.
   ORDRE DE PERTINENCE, du plus contextuel au plus général : les étapes du bloc COURANT, puis ses
   minuteurs et compteurs, puis les autres étapes de la fiche, puis les repères posologiques, puis
   le noyau universel. AUCUN FILTRE — on RÉORDONNE (même garantie que `posoRank` et `tagRank`) :
   un faux positif coûte un rang, un faux négatif coûte le mot au moment où on le cherche.
   PURE (testée) : elle ne lit que ce qu'on lui passe. */
/* UNE CHIP N'EST PAS UN LIBELLÉ, C'EST UNE CIBLE DE POUCE (v5.0.0) : « Adrénaline IM, face
   antéro-latérale de cuisse :: dose du protocole local » ne tient sur aucune rangée et ne se lit
   pas d'un coup d'œil. On abrège À L'AFFICHAGE seulement — la RÉFÉRENCE, elle, voyage entière :
   abréger la donnée serait perdre de l'information ; abréger l'affichage ne perd rien. Depuis la
   v5.0.0 (signalé à l'usage), le libellé RÉSOLU d'une ÉTAPE passe lui aussi par ce raccourci
   (`tagLabel`) : recopier la ligne de geste entière dans le journal et le compte rendu ne se
   relisait pas — le raccourci intelligent suffit en texte. PURE, testée. */
```

## J121 — MENTION « AVANCÉ PAR … » — sur la carte du BOUT seulement, et seulement si l'avance vient d'un

```
/* MENTION « AVANCÉ PAR … » — sur la carte du BOUT seulement, et seulement si l'avance vient d'un
   autre écran. Registre NEUTRE : ce n'est ni une alerte ni une confirmation, c'est une attribution.
   Elle vit à côté de « Vous êtes ici » parce que c'est la même information — où en est-on — vue
   sous l'autre angle : par qui. Deux canaux distincts, jamais une couleur seule. */
/* ELLE S'INVALIDE TOUTE SEULE, ET C'EST LE CORRECTIF (v4.55.5, signalé à l'usage). La mention
   était un drapeau GLOBAL qu'un seul site du fichier remettait à zéro — `cxEnter`, l'entrée sur
   complication. Aucun avancement ordinaire ne l'effaçait : posée une fois (typiquement par le
   rattrapage du backlog à la jointure, où toutes les navigations de l'hôte défilent d'un coup),
   elle SUIVAIT ensuite l'invité de carte en carte et attribuait à « Hôte » les blocs qu'il venait
   lui-même d'avancer. Encore un demi-chemin : un effacement écrit d'un seul côté.
   On ne rajoute donc pas les N sites manquants — on supprime le besoin de s'en souvenir. La
   mention est AMARRÉE au numéro de VISITE que l'avance distante a créé, et ne s'affiche que sur
   celui-là. Le premier passage minté localement porte un autre numéro : la mention disparaît par
   construction, sans qu'aucun geste ait à y penser. */
```

## J122 — ⚠ « T+ » SE COMPTE DEPUIS LE DÉBUT DE LA SESSION, PAS DEPUIS LE PREMIER REPÈRE (v5.6, signalé

```
/* ⚠ « T+ » SE COMPTE DEPUIS LE DÉBUT DE LA SESSION, PAS DEPUIS LE PREMIER REPÈRE (v5.6, signalé
   à l'usage : « session commencée à 23h30, encore en cours à 00h30 — le journal montre +0:30:00 »).
   Ce n'était pas un défaut de minuit : toutes les durées du fichier sont des différences
   d'horodatages, insensibles au changement de date (vérifié — un repère à 00:30 d'une session de
   23:30 affiche bien « +1:00:00 » dès lors que la référence est la bonne). C'était une référence
   DIVERGENTE : le journal partait du premier repère, quand le compte rendu (`+` de sa colonne),
   l'accusé du volet ⏱ et la trace d'un compteur partent tous de `startedAt`. Deux origines pour
   un même « T+ », c'est-à-dire deux vocabulaires pour une idée (AC 120-71B § 5.5) — et celle du
   journal était trompeuse dès qu'on notait le premier repère longtemps après le début.
   Repli sur le premier repère quand la session n'a pas d'heure de départ (elle en a toujours une
   dès qu'un geste a eu lieu, mais un journal peut être rendu avant). */
```

## J123 — Outil SECONDAIRE : compact tant qu'on n'a rien noté (juste le bouton). « Journal des actions » =

```
  // Outil SECONDAIRE : compact tant qu'on n'a rien noté (juste le bouton). « Journal des actions » =
  // suite horodatée des gestes clés (pour la traçabilité / le compte-rendu après coup).
  /* ⚠ « NOTER L'HEURE » A QUITTÉ LE PANNEAU (v5.6, signalé à l'usage). Le geste est une TOUCHE
     DU DOCK depuis le lot 2 : le laisser AUSSI ici, c'était deux adresses pour un même verbe
     (AC 120-71B §5.5) — et la seconde vit derrière un dépliant, donc invisible à l'instant où
     l'on en a besoin. Le panneau redevient ce qu'il est : la LECTURE du journal. La maquette ne
     l'y met pas non plus. `#tkAdd` reste dans MUTE_SEL : le sélecteur ne matche plus rien, et le
     retirer serait parier qu'aucun chemin ne le réintroduira. */
  /* ⚠ UN JOURNAL VIDE DISAIT SON NOM ET RIEN D'AUTRE (v5.10.8, signalé à l'usage). Le panneau
     replié montrait « JOURNAL DES ACTIONS » au-dessus du vide — dans le rail, le titre lui-même est
     masqué par le dépliant qui le porte déjà (`.rail-fold .tk-panel .tk-head b`), et il ne restait
     donc STRICTEMENT RIEN. Or c'est exactement l'endroit où l'on découvre la capacité : le geste
     qui remplit ce journal est ailleurs, dans le dock, depuis que « Noter l'heure » a quitté le
     panneau (v5.6) — la lecture ne dit plus par quel geste on écrit.
     · C'EST UNE INVITATION, PAS UN ÉTAT : même distinction que le chapeau « Ne pas oublier »
       affiché vide (v4.76.0), et que les deux portes du panneau minuteurs (v5.6). Rien n'AFFIRME
       « 0 repère » — la phrase dit ce qu'on peut faire.
     · ELLE NE PARAÎT QU'EN SESSION : hors session la touche qu'elle nomme n'existe pas, et une
       consigne qui désigne un bouton absent est pire qu'un silence.
     · ELLE DISPARAÎT AU PREMIER REPÈRE, et elle ne clignotera pas : un repère ANNULÉ reste dans la
       chronologie (`voidAt` conserve, il ne retire pas), donc le journal ne redevient jamais vide
       une fois écrit — aucune mémoire à tenir, aucune remise à zéro à câbler.
     · AUCUNE COULEUR, AUCUN CADRE, 11 px en encre douce : c'est le registre de la légende, pas
       celui d'une notice — le mode crise ne se fait pas interpeller (règle 11). */
```

## J124 — Câblage du JOURNAL DES ACTIONS, isolé pour être REJOUÉ après une mise à jour chirurgicale du seul

```
/* Câblage du JOURNAL DES ACTIONS, isolé pour être REJOUÉ après une mise à jour chirurgicale du seul
   panneau (`renderTkOnly`). Un `render()` complet reconstruit tout le DOM et remet à 0 le `scrollTop`
   du RAIL (`overflow-y:auto`) : la barre latérale « remontait » à chaque « Noter l'heure » (retour
   d'usage). Un ajout/suppression/correction d'horodatage n'affecte QUE ce panneau — jamais les
   minuteurs, le plan ou la posologie —, donc on le remplace en place. */
/* ANALYSEUR D'HEURE RÉSILIENT (v5.4.0, signalé à l'usage : « entrer 1547 pour 15h47 ne fonctionne
   pas — trop strict, en contexte d'urgence on n'a pas le temps »). L'ancien format exigeait
   H:MM[:SS] — or le champ est `inputmode=numeric`, et le clavier numérique d'iOS N'A PAS de
   deux-points : le format canonique était littéralement intapable sur la cible principale
   déclarée. On accepte donc tout ce qui a un sens UNIVOQUE :
   — avec séparateurs (`:`, `h`, `.`, `,`, espace…) : 2-3 groupes → « 15h47 », « 15:47:23 », « 15 47 » ;
   — chiffres nus, lus par longueur : « 947 » → 9:47:00, « 1547 » → 15:47:00, « 154723 » → 15:47:23.
   Une valeur IMPOSSIBLE (minutes ou secondes > 59, heure > 23) rend null — REFUSÉE, jamais
   écrêtée : l'ancien code écrêtait « 15:87 » en 15:59, c'est-à-dire qu'il FABRIQUAIT une heure
   fausse dans une trace de soin qui alimente le compte-rendu. PURE (testée via ?__actest). */
```

## J125 — ANNULER, PAS SUPPRIMER (v4.47.0). Le × effaçait le repère d'un simple tap — ce qui enfreignait

```
  /* ANNULER, PAS SUPPRIMER (v4.47.0). Le × effaçait le repère d'un simple tap — ce qui enfreignait
     la règle du projet (« action destructrice en situation de crise = geste MAINTENIR ») et,
     surtout, ce qui n'est pas soutenable pour une TRACE : le journal alimente le compte-rendu,
     support du débrief. Un enregistrement qu'un tap involontaire efface sans laisser de marque
     n'est pas un enregistrement.
     Le « maintenir » a été envisagé et ÉCARTÉ : il protège du geste accidentel mais laisse la
     perte définitive, et il ne dit rien à celui qui relit. La réponse retenue est celle que le
     fichier applique DÉJÀ à la correction d'heure deux lignes plus bas — non destructive,
     visible, réversible (`origT` + « ↺ revenir »). On aligne, au lieu d'inventer.
     `voidAt` porte l'HEURE de l'annulation, comme `origT` porte celle d'origine : le compte-rendu
     peut donc dire quand on s'est ravisé. En session partagée, l'annulation est un ÉVÈNEMENT
     attribué et réversible — donc plus une action destructrice, et c'est pourquoi elle reste
     ouverte au scribe (cf. `SHARE_KINDS_ANY`) là où décocher est réservé au lead. */
```

## J126 — UN SEUL POINT D'ÉCRITURE D'UN REPÈRE (v5.0.0, lot M2) : le bouton du PANNEAU et celui de la

```
/* UN SEUL POINT D'ÉCRITURE D'UN REPÈRE (v5.0.0, lot M2) : le bouton du PANNEAU et celui de la
   CARTE DU BLOC appellent la même fonction. Deux copies auraient divergé — c'est déjà arrivé au
   cœur de cochage (v4.42.0) et aux verbes du lecteur (v4.55.0).
   Libellé LAISSÉ VIDE : « Action N » se calcule au rendu, par rang chronologique (cf. tkLabels). */
/* LE PANNEAU D'ACQUITTEMENT DU BLOC (v5.0.0, lot M7, maquette `proto-r4`) — « ✓ 03:33 noté ·
   sans étiquette », puis les étiquettes proposées, puis le renvoi vers le journal. Il répond AU
   GESTE, à l'endroit du geste : sans lui, taper « Noter » dans la carte ne produisait qu'une
   ligne de plus dans un panneau situé plus bas, donc hors du regard.
   CE N'EST PAS UNE NOTIFICATION FLOTTANTE (règle 11) : rien ne surgit, rien ne recouvre, rien ne
   s'impose à qui n'a rien demandé — c'est la RÉPONSE à un bouton qu'on vient de presser, et elle
   vit dans le flux, sous ce bouton (même distinction que `toast(msg,ms,direct)`, v4.55.4).
   ÉTAT TRANSITOIRE, jamais persisté : `state.tkAck` porte l'id du dernier repère posé DEPUIS la
   carte. Il tombe au prochain geste de navigation — on ne traîne pas un accusé de réception. */
/* ⚠ L'ACCUSÉ DE RÉCEPTION A CHANGÉ D'ADRESSE, PAS DE NATURE (v5.6, lot 2 — `tkAckHtml`,
   `tkAckPaint`, `state.tkAck`/`tkAckOpen`, `data-tkack`/`data-tkmore`/`data-tknote` et les règles
   `.tk-ack*` sont PURGÉS, règle 14). Le lot M7 l'avait posé DANS la carte du bloc, parce que le
   geste « ⏱ Noter » y vivait : « la réponse vit là où le geste a eu lieu ». Le geste a déménagé au
   DOCK — c'est un geste de session, pas de bloc —, et sa réponse l'a suivi : le volet ⏱ dit
   « ⏱ Repère posé · T+02:16 · ✓ au journal » et offre la nomination, au même endroit, sous le
   doigt qui vient de taper. La règle n'a pas bougé d'un mot ; c'est le geste qui s'est déplacé,
   et laisser l'accusé derrière lui aurait produit DEUX réponses à un seul geste — exactement ce
   que la doctrine proscrit. */
/* Le chevron du chapeau « Ne pas oublier » — SOURCE UNIQUE (v5.6). Convention du dépliant, la
   même que tous les `<details>` du fichier : fermé « › », ouvert « ▾ ». */
```

## J127 — 1ʳᵉ action de la session : le bandeau apparaît -> re-rendu complet obligatoire, une seule fois.

```
  // 1ʳᵉ action de la session : le bandeau apparaît -> re-rendu complet obligatoire, une seule fois.
  // Ensuite : le seul panneau — rien ne doit bouger sous le doigt dans la colonne d'action.
  /* DEPUIS LA CARTE, c'est la CARTE qui doit répondre : `renderTkOnly` ne remplace que le panneau
     du journal, plus bas — l'accusé n'y serait jamais apparu. `renderOvOnly` refait le journal de
     parcours, donc la carte du bout, donc l'accusé ; rien au-dessus ne bouge (doctrine du journal :
     on n'écrit qu'au bout). Depuis le PANNEAU, on garde la mise à jour chirurgicale d'origine. */
  /* ⚠ SIGNALÉ À L'USAGE : « bug de scroll quand on clique sur Noter l'heure ». Mesuré : 53 px à
     390, 60 à 1280 — mais SEULEMENT au PREMIER repère, celui qui DÉMARRE la session. Le rendu y
     est forcément complet (le bandeau de crise et le quai apparaissent, le chapeau se replie), et
     il n'était pas ANCRÉ : toute la colonne remontait de la hauteur nette du chrome ajouté.
     C'est la mécanique ECAM du dossier — un geste ne déplace pas ce qu'on regarde — appliquée là
     où elle manquait. On ancre sur la carte du bloc courant, qui est ce que l'utilisateur a sous
     les yeux au moment où il note l'heure ; à défaut (aucune carte : fiche mono-bloc), sur le
     bouton lui-même. */
  /* ON ANCRE SUR LE BOUTON, PAS SUR LA CARTE : c'est lui qui est sous le doigt. Ancré sur la
     carte, le bouton dérivait encore de 65 px à 390 px — le contenu de la carte change de hauteur
     au démarrage (le fil d'Ariane paraît), et garder le HAUT de la carte immobile ne garde pas
     immobile ce qui est à son PIED. */
```

## J128 — Read (mode crise / lecture)

```
/* ===== Read (mode crise / lecture) =====
   renderRead() : affiche la fiche active. De haut en bas : titre + méta, bandeau
   « Ne pas oublier » (CHAPEAU, hors parcours), puis le PARCOURS DE SOIN numéroté
   (v4.4.0) — ① Confirmer le diagnostic (repliable, bouton « Confirmé — démarrer »),
   ② Prise en charge (minuteurs/compteurs en étroit, carte des blocs SVG repliable,
   fil d'Ariane, bloc courant : étapes cochables ou décision, contexte local,
   repères posologiques en étroit), ③ Surveillances & pièges (À vérifier +
   différentiels) — puis les ANNEXES : journal des actions (étroit), galerie,
   documents PDF, références, voir aussi, note personnelle. En large (>= 1000px),
   minuteurs / posologie / journal vivent dans la colonne droite collante.
   Actions de gestion (modifier / dupliquer / exporter / versions) : menu ⋯.
   La 2e moitié de la fonction RATTACHE tous les écouteurs : navigation entre blocs
   (push/pop sur state.nav), cochage des étapes, contrôles minuteurs/compteurs
   (mise à jour DOM directe, sans render), et gestion des sessions. */
/* Section NAVIGATION de la vue lecture (v4.4.5) : fil d'Ariane + bloc courant (étapes/décision)
   + rangée « Bloc précédent / Recommencer », EXTRAITS de renderRead pour pouvoir être re-rendus
   SEULS par renderNavOnly() — naviguer dans l'arbre décisionnel reconstruisait toute la vue
   (galerie base64, parcours de soin, documents, note…) : le geste répété de la crise mérite la
   même chirurgie que le cochage d'étape. Renvoie tout ce que renderRead ET renderNavOnly
   consomment (le HTML des trois zones + le bloc courant pour le câblage et le halo du SVG). */
```

## J129 — v4.6.0 : DEUX modes de lecture de la prise en charge. 'overview' (défaut) = TOUS les blocs

```
  // v4.6.0 : DEUX modes de lecture de la prise en charge. 'overview' (défaut) = TOUS les blocs
  // affichés à la suite (overviewSection) ; 'guided' = bloc à bloc historique (navSection).
  // Une fiche SANS algorithme (un seul bloc, pas de décision) garde le rendu guidé : les deux
  // vues y seraient identiques — la bascule n'est pas affichée non plus.
  // v4.16.0 : le mode guidé n'existe plus pour les fiches À ALGORITHME (fusionné dans le
  // journal — fil condensé) ; il ne subsistait que pour les fiches mono-bloc.
  /* ⚠⚠ ET IL N'Y SUBSISTE PLUS (v5.6, signalé à l'usage : « s'il n'y a qu'un seul bloc avec une
     seule étape, le bloc ne s'affiche pas correctement et le parcours inerte ne s'affiche pas »).
     La justification d'origine — « les deux vues y seraient identiques » — était VRAIE en v4.16.0
     et FAUSSE depuis la refonte : `navSection` est le rendu d'avant v5.6 (une étiquette de texte
     « BLOC · LE BLOC — 0/1 COCHÉ », l'étape à nu sur le fond de page, un panneau « Algorithme »
     qui n'a aucun sens à un seul bloc), quand `overviewSection` rend la CARTE de travail avec sa
     pastille, sa légende de registres, son pied de gestes et son parcours. Une fiche à un bloc
     n'avait donc aucun des acquis du lot 3, et le rail n'affichait rien du tout.
     UN BLOC EST UNE SÉQUENCE D'UN : `flowPlan` en rend une entrée, `ovPresList` un passage — et
     le BOUT est toujours une carte. Le journal sert donc les deux cas sans qu'on lui demande rien
     de nouveau. La BASCULE reste masquée quand il n'y a pas d'algorithme (`hasFlow`) : « Toute la
     fiche » n'y montrerait rien de plus, et c'est cela qui était juste dans la doctrine d'origine.
     `navSection` n'est plus atteint que par l'APERÇU d'un brouillon sans bloc. */
```

## J130 — ══ AVANT LA SESSION, C'EST UNE CONDITION D'ENTRÉE ; APRÈS, C'EST UN FAIT ACQUIS

```
    /* ══ AVANT LA SESSION, C'EST UNE CONDITION D'ENTRÉE ; APRÈS, C'EST UN FAIT ACQUIS
       (v5.6, maquettes 1b/1c) ═════════════════════════════════════════════════════════════
       Le même objet répondait aux deux moments avec le MÊME dessin — un dépliant gris coiffé
       d'un chevron bleu. Or les deux questions n'ont rien à voir : avant, « suis-je au bon
       endroit ? » est LA question, et le QRH l'imprime en tête, en entier, dans l'encadré du
       registre qui la rend impérieuse ; après, c'est une ligne de traçabilité qu'on rouvre en
       cas de doute.
       AVANT : carte au CONTOUR d'alerte (jamais un aplat — un rouge permanent désensibilise),
       titre « ■ Quand l'utiliser », un ■ rouge par critère, et le renvoi vers les différentiels
       en pied discret. Le chevron disparaît : il n'y a rien à replier quand on n'a pas encore
       répondu à la question — et un dépliant ouvert d'office avec un chevron invite au seul
       geste qu'on ne veut pas voir faire ici.
       APRÈS : le dépliant d'avant, inchangé, qui redevient ce qu'il est. */
```

## J131 — (gallery / docs / refs vivaient ici avant le lot 4 : ils sont désormais rendus par la feuille

```
  // (gallery / docs / refs vivaient ici avant le lot 4 : ils sont désormais rendus par la feuille
  // Consulter — refSheetHtml — et n'ont plus de place dans le flux d'action ; retirés v4.23.0.)
  // « Ne pas oublier » : bandeau compact SOUS le titre (un rappel critique doit être vu AVANT
  // d'être violé, pas après avoir tout déroulé).
  // « Ne pas oublier » : kicker ■ + UNE LIGNE PAR ÉLÉMENT (les rappels critiques se lisent
  // ligne à ligne, jamais en coulée — décision utilisateur).
  /* ★ MÉMOIRE (lot T7, v5.0.0) — UN MEMORY ITEM EST UN ITEM DE LA LISTE, PAS UN CHAMP À PART.
     C'est la doctrine QRH, et le modèle v4 l'écrit ainsi : `memory:true` sur l'item, qui RESTE
     dans son bloc. Le chapeau agrège donc `notForget` (la liste historique, conservée — règle 12)
     et les étoiles posées sur les étapes.
     IL APPARAÎT DEUX FOIS, ET CE N'EST PAS LA DUPLICATION QUE LA v4.70.1 PROSCRIT : celle-là vise
     deux canaux qui énoncent la même CONSTANTE en même temps et à demeure. Ici les deux moments
     sont distincts et c'est exactement le geste QRH — on lit le chapeau AVANT d'agir (condition
     d'entrée ; il se replie dès le démarrage, lot T3), puis on RE-VÉRIFIE l'item à sa place dans
     la liste. Un memory item se récite de mémoire, puis se confirme sur la checklist.
     LE CONTEXTE EST DONNÉ : l'étoile dit d'où vient la ligne (« Bloc 2 »), sans quoi un rappel
     surgi de nulle part serait moins utile que la ligne qu'il rappelle. */
```

## J132 — ftxt englobant : .fs-i est un flex (puce ::before + texte) — sans lui, chaque segment

```
    // ftxt englobant : .fs-i est un flex (puce ::before + texte) — sans lui, chaque segment
    // autour d'un **gras** deviendrait un item flex séparé (texte éclaté, gaps parasites).
    /* REPLI EN SESSION (v5.0.0, lot T3) — RÈGLE ROUVERTE, et il faut dire laquelle : la v4.4.0
       posait que « Ne pas oublier » reste le CHAPEAU, entier, jamais replié. L'argument d'origine est
       juste — un memory item qu'on replie est un memory item qu'on oublie — mais il vise LE MOMENT
       DE LA DÉCISION D'ENTRÉE, pas les quarante minutes qui suivent, pendant lesquelles le chapeau
       ne conduit plus rien et repousse ce qui conduit. Mesuré : 172 px à 320 px, 223 px à 130 %,
       en permanence, AU-DESSUS de la première étape à exécuter.
       DONC : entier tant que la session n'a pas démarré (on le lit AVANT d'agir, c'est la condition
       d'entrée QRH) ; replié en UNE LIGNE ensuite, et dépliable d'un tap.
       CE QUI RESTE, ET C'EST LA RÈGLE 8 : le registre (rouge), le glyphe ■ et le mot en toutes
       lettres. Seule la SURFACE part. Le compte est ANNONCÉ — même vocabulaire que le « +n » du quai
       et les totaux du rail : une zone qui replie dit ce qu'elle replie.
       ÉTAT TRANSITOIRE, jamais persisté : c'est un état d'affichage de session, pas une préférence.
       Le dépliage ne re-rend RIEN (bascule de classe en place) — un re-rendu ferait sauter la page
       sous le doigt, et le chapeau est au-dessus de tout le reste. */
    /* `Runtime.started` et non la constante `started` : elle est déclarée PLUS BAS dans
       `renderRead`, donc en zone morte temporelle ici — la lire faisait échouer TOUT le rendu
       (« sessStart » introuvable, écran blanc). Ni `npm test` ni `npm run check` ne l'ont vu : ils
       n'exercent aucun rendu. C'est la sonde de mesure qui a parlé. */
```

## J133 — F4 (audit design v4.59.0) — COCKPIT TROIS ZONES. À grande largeur l'espace existe pour

```
  /* F4 (audit design v4.59.0) — COCKPIT TROIS ZONES. À grande largeur l'espace existe pour
     tenir de front l'ORIENTATION (le plan), l'ACTION (le parcours) et l'ÉTAT (les minuteurs) :
     c'est l'idéal ECAM, E/WD et SD sous les yeux en même temps, et pour un binôme hospitalier
     un poste fixe où l'aide-lecteur voit tout sans un tap.
     PALIER 1200, PAS 1000 (l'audit proposait 1000 « puisque le palier existe ») : mesuré, à
     1000 px les trois colonnes laissent ~390 px à la checklist — MOINS que la largeur d'une
     tablette en portrait, pour du contenu clinique qu'on lit sous stress. À 1200, la colonne
     d'action garde ~560 px et le plan 220. Aucun palier nouveau : 1200 est déjà celui des
     largeurs de lecture.
     Le plan QUITTE le rail droit à cette largeur — l'afficher aux deux endroits ferait deux
     sources pour la même structure (la règle qui vaut déjà pour les minuteurs nominaux). */
  /* ÉCHELLE DU RAIL (v4.23.0) : la structure de l'aide, une ligne par bloc, à côté de l'action.
     Même `flowPlan`, même numérotation commune, même `minimapData` que le Plan — aucune seconde
     source de vérité. DÉSATURÉE (cf. CSS .rail-lad) : le rail ORIENTE, la colonne AGIT ; s'il
     reprenait les aplats de l'action, deux surfaces se disputeraient le regard au même niveau de
     saillance. L'état n'y est plus porté que par le MARQUEUR. « ⤢ complet » ouvre la feuille.
     Absent en mode statique (le tableau EST déjà la vue d'ensemble) et en aperçu de brouillon. */
  /* ⚠ PAS DE COLONNE DE PLAN AVANT LE SOIN (v5.6) : la page d'avant la session PORTE déjà le
     parcours inerte, au centre — la colonne l'afficherait une seconde fois, côte à côte avec
     lui. Deux fois la même liste sur le même écran est la duplication que la v4.70.1 proscrit ;
     ici elle serait littérale, au pixel près. La colonne revient au démarrage, avec la vue de
     travail qu'elle oriente. */
  /* ⚠ DÉCLARÉE ICI, ET PAS PLUS BAS : `ladRail` la lit. Une constante `const` lue avant sa
     déclaration lève — c'est la zone morte temporelle, la faute exacte payée au lot T3 (tout le
     rendu échouait, et ni `npm test` ni `npm run check` ne l'auraient vu : aucun des deux
     n'exerce un rendu). */
  /* PLUS DE CONDITION SUR LE MODE GLOBAL (v5.14.18, signalé : « une autre aide de l'invité est
     cochable comme si une session était démarrée, et le bandeau diffère ») : la garde « pas de
     bouton Démarrer chez l'invité » visait la fiche PARTAGÉE — où `Runtime.started` est de
     toute façon vrai. Sur SES aides, l'invité retrouve le parcours inerte et l'entrée normale. */
```

## J134 — RAIL EN TROIS ZONES (v4.23.0) — retour d'usage : empilées dans un seul défileur, une Échelle

```
  /* RAIL EN TROIS ZONES (v4.23.0) — retour d'usage : empilées dans un seul défileur, une Échelle
     longue ou des minuteurs nombreux repoussaient les repères posologiques tout en bas.
     Ordre par URGENCE DÉCROISSANTE, et surtout : la seule zone de longueur NON BORNÉE (l'Échelle)
     passe en DERNIER, où elle ne peut plus rien repousser.
       1. minuteurs — état vivant, plafonné et défilant sur lui-même s'il y en a beaucoup ;
       2. posologie — lue PENDANT le geste, donc toujours visible sans défiler ;
       3. Échelle + horodatage — orientation et journal, prennent le reste et défilent seuls.
     Chaque zone borne son propre débordement : aucune ne peut chasser les autres. */
  /* RAIL — colonne CONTINUE (v4.23.0). Seule règle : la ou les sections de longueur ILLIMITÉE
     (Échelle, horodatage) passent en DERNIER, où elles ne peuvent rien repousser. La posologie,
     placée avant, reste donc lisible sans défiler quelle que soit la taille du plan. */
  /* ⚠ DÉCLARÉES ICI, ET PAS PLUS BAS : `gridClose` les lit pour composer la colonne de droite.
     C'est la TROISIÈME fois que la zone morte temporelle se paie dans ce fichier (lot T3, puis
     `gesteEntree` en v5.6) — et elle ne se voit ni à `npm test` ni à `npm run check`, dont aucun
     n'exerce un rendu. Une constante lue par le gabarit se déclare avant le gabarit. */
```

## J135 — ----- LES ÉTAGES DE LA FICHE (v4.4.0 → v5.0.0) : condition d'entrée → prise en charge →

```
  /* ----- LES ÉTAGES DE LA FICHE (v4.4.0 → v5.0.0) : condition d'entrée → prise en charge →
     surveillances. Le RAIL NUMÉROTÉ ①②③ qui les ossaturait est SUPPRIMÉ (M2a) : deux
     numérotations concurrentes dans la même colonne — la sienne et celle des BLOCS — sont deux
     vocabulaires pour situer un même geste, ce qu'AC 120-71B proscrit ; celle des blocs reste,
     étant commune au journal, au plan, au statique et au SVG. Les étages demeurent des SECTIONS
     titrées (`.care-flat` / `.cf-stage`), l'état porté par le titre et le texte, jamais par une
     couleur seule (WCAG 1.4.1). La séquence est SUGGÉRÉE, jamais bloquante (QRH) ; « Ne pas
     oublier » reste le CHAPEAU, hors séquence. Une fois la session démarrée, « Prise en charge »
     passe en TÊTE (lot T5) : avant d'agir on s'oriente, pendant on agit. */
  // Bouton de démarrage EXPLICITE : dans l'étape ① s'il y a des critères (« Confirmé — … » :
  // le geste PORTE la confirmation), sinon en tête de « Prise en charge ». Un seul bouton
  // rempli par écran ; la 1ʳᵉ action clinique démarre toujours aussi (jamais bloquant).
  // v4.13.0 : en mode STATIQUE, pas de panneau « Algorithme » (le tableau EST la vue d'ensemble).
  // v4.18.0 : en mode DYNAMIQUE, plus de panneau « Algorithme » AVANT le journal (ordre ECAM
  // E/WD → SD : jamais un synoptique au-dessus de la surface d'action) — le SVG est devenu
  // l'affichage « Schéma » de la section Plan, SOUS le journal. Le panneau ne subsiste que
  // pour les fiches SANS algorithme (rendu guidé, pas de Plan).
```

## J136 — DÉCLARÉ ICI, ET PAS PLUS BAS : le lot T3 a payé une zone morte temporelle (`started` lu

```
  /* DÉCLARÉ ICI, ET PAS PLUS BAS : le lot T3 a payé une zone morte temporelle (`started` lu
     24 lignes avant sa déclaration → ReferenceError → tout le rendu échouait, sans qu'aucun
     test ni aucun garde-fou ne le voie, puisque ni l'un ni l'autre n'exerce un rendu). */
  /* M2a (v5.0.0, décision utilisateur « le retirer partout ») — LE RAIL ①②③ N'EXISTE PLUS.
     Le lot T5 l'avait retiré EN SESSION ; les maquettes ne le montrent nulle part, hors session
     comprise, et les numéros y vivent sur les BLOCS. Deux numérotations concurrentes dans la
     même colonne (le rail ①②③ et les pastilles de bloc) sont exactement ce qu'AC 120-71B
     proscrit : deux vocabulaires pour situer un même geste. C'est celle des BLOCS qui reste —
     elle est commune au journal, au plan, au statique et au SVG (`flowPlan().order`), quand le
     rail ne parlait qu'à lui-même. La PERMUTATION, elle, reste conditionnée au démarrage :
     avant d'agir on s'oriente, et la condition d'entrée QRH se lit d'abord. */
```

## J137 — LE CHAPEAU SE GLISSE ENTRE LES CRITÈRES ET LE BOUTON (v5.0.7, décision utilisateur)

```
  /* ═══ LE CHAPEAU SE GLISSE ENTRE LES CRITÈRES ET LE BOUTON (v5.0.7, décision utilisateur) ═════
     Question posée : « remonter confirmer le diagnostic au-dessus de ne pas oublier — est-ce
     incompatible ECAM/QRH ? ». Non : c'est l'ordre CANONIQUE, et c'est l'ordre d'avant qui s'en
     écartait. Un QRH imprime le titre et la CONDITION D'ENTRÉE au-dessus des recall items ; sur
     ECAM le titre de l'alerte — qui EST la condition — précède les lignes d'action. La séquence
     est condition → memory items → read-and-do ; on avait memory items → condition.
     ⚠ LE CHAPEAU NE PASSE PAS SOUS LE BOUTON, ET C'EST TOUT L'ARBITRAGE. Le descendre simplement
     sous l'étage de la condition d'entrée le mettrait APRÈS « Confirmé — démarrer la session »,
     puisque le bouton vit dans cet étage : on l'aurait rangé derrière le geste qu'il doit
     précéder. Il se glisse donc ENTRE les deux — la lecture devient exactement celle du QRH, et le
     bouton porte l'acquittement des deux.
     CE QUE CELA COÛTE, MESURÉ, ET IL FAUT LE SAVOIR : le chapeau quitte le premier écran dès que
     les critères sont longs (fiche à 8 critères, 390 × 844 : il naissait à y = 130, il naît à
     y = 813). Sur une fiche ordinaire il y reste entier (571 → 786 à 390 × 844). Et comme le
     bouton FLOTTE quand il est sous le pli (v4.73.0), on peut démarrer sans avoir défilé jusqu'aux
     memory items. Ce qui rend le coût acceptable est le lot T7 : un memory item ★ RESTE dans son
     bloc — le chapeau AGRÈGE, il ne possède pas. Rien n'est perdu, l'item se re-vérifie à sa place
     dans la checklist, ce qui est précisément le geste QRH (réciter de mémoire, puis confirmer).
     LA CONDITION EST LA PRÉSENCE DU BOUTON, pas l'état de la session : chez l'invité et en aperçu
     d'essai le geste d'entrée n'existe pas, et une séquence qui mène à un
     bouton absent n'a rien à ordonner — le chapeau reprend alors sa place en tête. Une fois la
     session DÉMARRÉE, rien ne change de ce qui existait : le chapeau replié revient en tête et la
     condition d'entrée descend avec son étage (T5). */
  /* ⚠ « DIAGNOSTIC CONFIRMÉ » RESTE UN ÉTAGE — TENTATIVE ANNULÉE, ET LA MESURE EST LA RAISON
     (v5.6, demande de l'auteur : « déplace diagnostic confirmé dans le dépliant “x blocs faits —
     diagnostic confirmé” »). Le déplacement a été écrit et il FONCTIONNAIT : condition d'entrée
     avant le démarrage (A19), trace dans l'historique après, repliée dans « ✓ n blocs faits ·
     diagnostic confirmé ». `audit-partage` l'a rougi sur un invariant de crise — « il regardait
     ailleurs : ce qu'il regarde ne bouge pas » — avec **457 px de dérive**.
     LA CAUSE EST STRUCTURELLE, pas un détail d'implémentation : la place de la confirmation
     dépendait alors de l'EXISTENCE d'une ligne-bilan, laquelle peut naître d'un lot DISTANT. Un
     élément de plusieurs centaines de pixels qui change de logement sous les yeux de quelqu'un qui
     n'a rien fait, c'est exactement ce que la règle 11 interdit — et le pire des cas, puisqu'il est
     au-dessus de ce qu'on regarde.
     CE QU'IL FAUDRAIT POUR LE FAIRE PROPREMENT : que la confirmation soit une ligne-bilan DÈS le
     démarrage (« ✓ diagnostic confirmé »), qui gagne ensuite le compte des blocs dans son libellé —
     alors elle ne déménage jamais, seul son texte s'allonge. C'est une refonte de l'assemblage du
     journal, à décider séparément et à mesurer contre ce même témoin. */
  /* EN SESSION, LA CONFIRMATION A CHANGÉ DE LOGEMENT (v5.6) : elle vit dans le journal, en tête,
     dans la ligne-bilan « ✓ n blocs faits · diagnostic confirmé ». La laisser AUSSI dans le flux
     serait la duplication que § 5.5 proscrit ; l'étage n'a donc plus de corps une fois démarré. */
```

## J138 — T2 (v5.0.0) — LE JOURNAL DES ACTIONS REMONTE. Il vivait en FIN de colonne : mesuré, le bouton

```
  /* T2 (v5.0.0) — LE JOURNAL DES ACTIONS REMONTE. Il vivait en FIN de colonne : mesuré, le bouton
     « Noter l'heure » était à y = 1588 px sur un écran de 844 (744 px sous le pli) et à 1829 px sur
     640. C'est le geste de traçabilité le plus fréquent d'une réanimation, et c'était le plus loin
     de la main. Il se pose désormais JUSTE SOUS la carte du bloc courant : c'est là que le geste se
     produit, donc là qu'on l'horodate. PAS AU-DESSUS : le mettre avant repousserait l'action, ce
     que le lot T5 existe précisément pour corriger. Le panneau est déjà compact au repos
     (`.tk-slim` : l'en-tête et le bouton, rien d'autre). */
  /* CH1 / LOT T5 — EN SESSION, L'ACTION PASSE DEVANT L'ORIENTATION. Même contenu, même vue,
     rien de supprimé : c'est la SUITE VERTICALE qui est réécrite, et seulement une fois la
     session démarrée. Hors session, pas un pixel ne bouge — avant d'agir on s'oriente, et le
     chapeau entier, les critères et le rail ①②③ restent en tête (condition d'entrée QRH).
     LE FIL D'ARIANE RESTE COLLÉ À SA CARTE : il ne s'oriente pas dans la fiche, il dit où l'on
     est DANS le bloc qu'on exécute — le séparer de lui n'aurait aucun sens. */
  /* v5.4.0 : en session le dépliant fusionné (minuteurs · compteurs · journal) prend la place que
     le lot T2 avait donnée au journal — JUSTE SOUS la carte du bloc, là où le geste se produit.
     tkH ne subsiste à cette place que pour une fiche sans minuteur ni compteur. */
  /* ══ AVANT LA SESSION, LA PRISE EN CHARGE S'ANNONCE — ELLE NE SE DÉROULE PAS (v5.6, maquettes
     1b/1c — demande de l'auteur : « le mockup proposait une première page de démarrage de
     session, avec possibilité de voir les critères, tout voir, tableau, schéma ») ═════════════
     La colonne montrait les CARTES DE TRAVAIL, cases comprises, avant même qu'on ait confirmé le
     tableau. C'est la checklist déroulée sur un patient qu'on n'a pas encore reconnu, et cela
     contredit la condition d'entrée QRH que la carte juste au-dessus vient d'énoncer.
     ELLE MONTRE DONC LE PARCOURS INERTE — la séquence, ses branches, ses boucles, ses renvois,
     et rien à cocher — puis les AUTRES VUES en liens de texte (tableau, schéma, documents), que
     la maquette met là plutôt qu'en tuiles. On voit ce qu'on va faire avant de le faire.
     ⚠ CE QUE CELA COÛTE, ET IL FAUT LE SAVOIR : le DÉMARRAGE IMPLICITE par cochage (« la 1ʳᵉ
     action clinique démarre toujours aussi », v4.4.0) n'existe plus AVANT le premier geste — il
     n'y a plus de case à cocher à ce moment-là. Ce qui le remplace est plus sûr, pas moins : le
     geste d'entrée est une touche PERMANENTE du dock, à position constante, atteignable au pouce
     sans défiler, quelle que soit la longueur des critères. `ensureStarted` reste le point
     d'entrée unique et démarre toujours sur n'importe quel geste ultérieur.
     ⚠ ET SEULEMENT QUAND LE GESTE D'ENTRÉE EXISTE : chez l'INVITÉ (qui suit une session
     distante et n'en démarre aucune) et en APERÇU D'ESSAI, la vue de travail reste — sinon on
     leur montrerait une fiche qu'ils ne peuvent plus dérouler. */
  /* v5.6 — LES DEUX FAÇONS DE REGARDER LA FICHE PASSENT AU-DESSUS DE « PRISE EN CHARGE » (demande
     de l'auteur). Elles ne sont pas un détail de cet étage : elles ouvrent la fiche ENTIÈRE, donc
     elles se lisent avant lui, et elles ont leur propre rangée. */
```

## J139 — v4.23.0 : ③ ne garde que « △ À vérifier » — ce qui tue si on l'oublie reste dans le FLUX

```
  // v4.23.0 : ③ ne garde que « △ À vérifier » — ce qui tue si on l'oublie reste dans le FLUX
  // (AC 120-71B). Les DIFFÉRENTIELS, eux, sont de la consultation (on les ouvre quand le
  // tableau est atypique, pour re-décider) : ils partent dans la feuille, où le lien
  // « Tableau atypique ? » de l'étape ① atterrit directement.
  /* ⚠ PAS AVANT LA SESSION (v5.6, demande de l'auteur). « Surveiller ensuite » est, par
     définition, ce qui vient APRÈS les gestes : sur l'écran où l'on décide d'entrer, il n'est ni
     actionnable ni décisif, et il pousse le geste d'entrée d'autant. Il revient dès le premier
     geste — donc rien n'est perdu, seulement différé au moment où cela commence à servir. En voie
     LARGE il n'a même pas disparu : la colonne d'orientation porte « Surveiller ensuite » en
     permanence. AC 120-71B demande que les surveillances restent dans le FLUX ; cette règle vise
     le déroulé du soin, pas la page de garde. */
```

## J140 — Re-rendu de DÉMARRAGE de session (1ʳᵉ action) avec ANCRAGE : le bouton « Confirmé — démarrer »

```
/* Re-rendu de DÉMARRAGE de session (1ʳᵉ action) avec ANCRAGE : le bouton « Confirmé — démarrer »
   disparaît du flux au re-rendu -> tout remonterait sous le doigt (ECAM : le contexte de travail
   ne bouge pas). On mémorise la position ÉCRAN de l'élément déclencheur et on compense le scroll
   pour qu'il ne bouge pas d'un pixel. `sel` = sélecteur re-trouvable après render().
   LIMITE STRUCTURELLE (à connaître avant d'en dépendre) : la compensation est BORNÉE par le haut
   de page. Si le re-rendu retire S pixels AU-DESSUS de l'ancre alors que window.scrollY < S,
   scrollBy ne peut pas descendre sous 0 : il reste un résidu de (S - scrollY) px. C'est sans
   conséquence pour S ≈ une centaine de px (le bouton), mais cela interdit d'y adosser le repli
   d'un BLOC entier (cf. la doctrine de state.confOpen dans ensureStarted).
   Renvoie le RÉSIDU en px (0 = l'ancre n'a pas bougé), ou `null` si AUCUNE mesure n'a pu être
   faite -> testable, et garde-fou pour l'avenir. */
/* ANCRAGE — SOURCE UNIQUE (v4.45.0). Le motif « mesurer la position écran d'une ancre, re-rendre,
   compenser le défilement » existait en QUATRE copies : `renderKeepAnchor` (render complet),
   `renderOvOnlyKeepAnchor` et `ovAdvanceRender` (journal), et le remplacement chirurgical de
   `renderNavOnly`. Or c'est l'invariant le plus cité du projet — « rien ne bouge sous le doigt »,
   doctrine ECAM — et UNE SEULE des quatre mesurait son résidu : les trois autres l'appliquaient
   sans jamais pouvoir dire si elles y arrivaient. Il est désormais vérifiable partout.
   LE RÉSIDU EST RENVOYÉ, JAMAIS CORRIGÉ, et ce n'est pas un détail : la compensation est BORNÉE
   par le haut de page. Si le re-rendu retire S pixels AU-DESSUS de l'ancre alors que
   `window.scrollY < S`, `scrollBy` ne peut pas descendre sous 0 et il reste (S - scrollY) px.
   C'est sans conséquence pour S ≈ une centaine de px (un bouton qui disparaît), mais cela
   INTERDIT d'y adosser le repli d'un BLOC entier — c'est exactement ce qui fonde la doctrine de
   `state.confOpen` dans `ensureStarted`. « Corriger » ce résidu masquerait la limite au lieu de
   la respecter, et rouvrirait le bug v4.3.2.
   Ce qui reste PROPRE À CHAQUE APPELANT et ne doit pas être unifié : le focus clavier (seul le
   journal le déplace) et la règle de visibilité (seul `ovAdvanceRender` défile vers la nouvelle
   carte, et seulement si elle n'est pas déjà entièrement à l'écran).
   « PAS MESURÉ » N'EST PAS « N'A PAS BOUGÉ » (correctif) : les trois sorties sans mesure
   renvoyaient `0`, c'est-à-dire la valeur qui signifie « ancrage parfait ». La plus grave est la
   troisième — l'ancre A DISPARU pendant le re-rendu. Elle n'est pas théorique : une condensation
   du journal (`ovPresList` : carte -> chip, puis rangée -> `.ov-runline`) fait disparaître le
   `[data-ck="…"]` que l'on visait, et la page peut alors sauter de plusieurs centaines de px
   pendant que la fonction annonce `0`. Le contrôle « dérive 0 px » d'`audit-doctrine` serait donc
   VERT exactement sur le cas qu'il prétend couvrir — troisième occurrence de la leçon v4.31.1 :
   un contrôle aveugle au défaut qu'il couvre ne vaut rien. D'où `null`, que le harnais refuse.
   Aucun appelant ne se branche sur la valeur de retour (vérifié : 8 sites l'ignorent,
   `renderOvOnlyKeepAnchor` se contente de la relayer) — le changement est donc sans effet visible. */
/* `selAfter` (v4.77.0) : l'ancre d'ARRIVÉE peut porter un autre sélecteur que celle de DÉPART —
   c'est le cas de la bascule guidé ↔ statique, où le même bloc s'appelle `.ov-block` d'un côté et
   `.sv-cell`/`.sv-band` de l'autre. Sans ce paramètre, il fallait un sélecteur commun aux deux
   vues, donc ne conserver que ce que les deux savent nommer. */
/* ══ QUAND L'ANCRE DISPARAÎT, ON SE RABAT SUR CE QUE L'ŒIL A SOUS LUI (v5.6) ═══════════════════
   `keepAnchor` renonçait EN SILENCE si son ancre n'existait plus après le re-rendu (`if(!nl)
   return null`) — et ce cas n'est pas rare, c'est même le plus coûteux : un lot distant qui fait
   avancer le parcours CONDENSE la dernière carte de bloc (R6), or c'est précisément elle que
   `shareApplyAnchored` prend pour ancre. Mesuré : `ancreSurvit:false`, donc AUCUNE compensation,
   et les quelque 500 px que la condensation retire au-dessus du regard partent directement dans
   l'œil de quelqu'un qui n'a rien demandé.
   LE REPLI EST CELUI QUE LA RÈGLE PROTÈGE : ce n'est pas « un autre sélecteur » mais L'ÉLÉMENT SOUS
   LE CENTRE DE L'ÉCRAN, capturé avant le re-rendu. C'est la définition même de « rien ne bouge
   sous les yeux », et c'est ce que le témoin de partage mesure.
   ⚠ ON LE CHERCHE DANS `main`, PAS AU SOMMET DE LA PILE : au centre de l'écran on peut tomber sur
   une couche FIXE (capsule, volet, barre) — qui ne bouge jamais, donc compenserait zéro et
   masquerait le défaut. `elementsFromPoint` rend la pile ; on prend le premier qui appartient au
   flux de la page.
   ⚠ ET SI CET ÉLÉMENT MEURT AUSSI, on remonte ses ANCÊTRES : un sous-arbre détaché garde sa chaîne
   `parentNode`, donc le premier ancêtre encore `isConnected` est un nœud réel du nouveau document.
   Au pire on tombe sur `main`, dont le haut ne bouge pas — la compensation vaut alors zéro, c'est
   -à-dire exactement le comportement d'avant : ce repli ne peut rien dégrader. */
```

## J141 — ORDRE DU MENU ⋯ (v4.28.0, retour utilisateur — logique ECAM E/WD → SD) : ce qui sert la

```
  /* ORDRE DU MENU ⋯ (v4.28.0, retour utilisateur — logique ECAM E/WD → SD) : ce qui sert la
     CONDUITE EN COURS d'abord (⚡ complications, lecteur, orientation, consultation), puis le
     CYCLE DE VIE de la session (exercice, recommencer, historique), puis la GESTION de la fiche
     (modifier, versions, dupliquer), puis les EXPORTS ; l'action dangereuse ferme la liste
     (doctrine v4.5, inchangée). Avant, « Modifier »/« Versions » — DÉSACTIVÉES pendant une
     session — trônaient en tête : deux rangées mortes au moment où le menu sert le plus. */
  /* MENU DE L'INVITÉ — CE QU'IL PEUT, ET UNE PORTE DE SORTIE (v4.47.0).
     Le menu ordinaire lui offrait des rangées qui, chez lui, sont fausses ou muettes : « Répéter en
     exercice » créerait une session locale sur un téléphone emprunté, « Recommencer le parcours »
     est un geste de portée globale réservé à celui qui conduit, « Modifier »/« Versions »/
     « Dupliquer » et les exports rouvriraient la porte dérobée que l'étanchéité ferme (un
     compte-rendu complet contient le texte des étapes, donc l'aide elle-même).
     ET IL N'AVAIT AUCUNE SORTIE : `Share.stop()` n'avait aucun appelant, le seul geste disponible
     — le « ‹ » d'en-tête — changeait la vue en laissant le mode et le sondage armés, sans chemin
     de retour vers le miroir. Un dispositif dont on ne peut pas sortir n'est pas un dispositif de
     confiance, et le collègue à qui l'on tend un QR mérite de savoir qu'il peut partir. */
  /* I8 (v5.10.2) — les quatre rangées de CONDUITE communes aux deux menus (invité / hôte)
     sortent en fabrique : recopiées, elles ne pouvaient que diverger (§ 5.5). Le SOUS-TITRE de
     « Consulter » reste un PARAMÈTRE, et ce n'est pas une divergence accidentelle : l'invité
     reçoit la fiche DÉPOUILLÉE (liste blanche SHARE_KEEP — ni documents ni images), et lui
     promettre « surveillances, documents… » serait un bouton menteur. Deux libellés, une raison,
     UNE fabrique. */
```

## J142 — Lancer un minuteur DÉMARRE la session. Si elle vient de démarrer, on re-rend (le bandeau « en

```
  // Lancer un minuteur DÉMARRE la session. Si elle vient de démarrer, on re-rend (le bandeau « en
  // cours » apparaît) ; sinon mise à jour DOM directe.
  /* ⚠ ACQUITTER N'EST NI RELANCER NI REMETTRE À ZÉRO — c'est une TROISIÈME sortie, et elle se
     nomme pour qu'on ne croie pas avoir relancé (« ✓ Vu », et le nom accessible dit en toutes
     lettres que le minuteur reste échu). L'état ne bouge pas : seule l'annonciation du quai se
     tait, la carte continue de dire « échu » et le compte rendu n'y perd rien.
     GESTE OUVERT À TOUS LES RÔLES : acquitter une alarme sur SON écran n'efface rien et ne
     conduit rien — c'est le master caution de l'ECAM, pressé à sa station. */
  /* ⚠ DÉLÉGUÉ, PAS CÂBLÉ AU RENDU : ce bouton PARAÎT au tick (une échéance survient sans qu'on
     touche à rien, cf. `syncTimerBtns`), donc un `onclick` posé au rendu ne l'aurait jamais
     atteint — il n'existait pas encore. Même raison que la délégation des chips de l'accueil. */
```

## J143 — Vue d'ensemble = JOURNAL DE PARCOURS (v4.9.0 — remplace la vue spatiale v4.6.0)

```
/* ===== Vue d'ensemble = JOURNAL DE PARCOURS (v4.9.0 — remplace la vue spatiale v4.6.0) =====
   La vue spatiale (chaque bloc UNE fois, état peint dessus) perdait l'utilisateur dès qu'un
   bloc vivait PLUSIEURS passages : coches remplacées sous les yeux, décision amnésique,
   position qui remonte. Le journal aligne l'écran sur ce que le moteur fait déjà — nav[] EST
   une chronologie : CHAQUE passage est une carte POSTÉE à la suite (modèle ECAM : les
   procédures se postent, rien ne mute au-dessus, on lit toujours vers le bas). Une instance
   COMPLÈTE et non-courante se replie en LIGNE D'ÉTAT verte relisible (le repli n'arrive qu'au
   RENDU suivant un geste de navigation — jamais sous le doigt pendant le cochage) ; une
   instance incomplète reste dépliée (elle appelle l'action) ; une décision repliée garde sa
   réponse en toutes lettres (→ option). Le journal n'a PAS de curseur : la position est le
   BOUT (state.navPos = fin, la vue guidée garde son curseur). Sous le journal, le « PLAN DE
   L'AIDE » (v4.10.0, ovPlanHtml) : la STRUCTURE complète en arbre indenté — IMMUABLE et
   INERTE côté cochage (leçon v4.6 : jamais d'état de passage sur une vue spatiale) ; taper un
   bloc = y ALLER (jumpToBlock : visité → défilement vers sa dernière carte, jamais visité →
   il entre au bout du journal) ; état LÉGER peint dessus (✓ dernier passage complet, ● ici,
   ×n passages, branche hors chemin estompée). Cases neuves à CHAQUE passage (sémantique
   inchangée) ; « ↺ Refaire » poste volontairement une nouvelle carte. DÉLÉGATION sur .ov-wrap. */
/* ══ « DIAGNOSTIC CONFIRMÉ » EST UNE LIGNE DU JOURNAL, PAS UN ÉTAGE (v5.6, demande de l'auteur :
   « déplace diagnostic confirmé dans le dépliant “x blocs faits — diagnostic confirmé” ») ═══════
   Avant le démarrage, la condition d'entrée EST la question (A19) : carte « ■ Quand l'utiliser »,
   en tête, entière. Une fois le soin commencé, elle ne conduit plus rien — c'est une TRACE, et sa
   place est celle des traces : le journal. Elle y rejoint la ligne-bilan des passages achevés,
   dont elle est chronologiquement la première.
   ⚠ ELLE NE DÉMÉNAGE PAS QUAND LE PREMIER BLOC S'ACHÈVE, et c'est la condition qui rend le
   déplacement admissible (A107) : la ligne est TOUJOURS en tête du journal — seule sa légende
   s'allonge (« ✓ diagnostic confirmé » puis « ✓ n blocs faits · diagnostic confirmé »). On fusionne
   donc dans la ligne-bilan SEULEMENT quand celle-ci commence au premier passage ; sinon la
   confirmation garde sa propre ligne, à la même place.
   ⚠ ET ELLE SE CALCULE DANS LE JOURNAL, jamais par un drapeau posé dans `renderRead` : le journal
   est bâti ~200 lignes plus haut, et surtout `renderOvOnly` le re-rend SEUL, bien plus souvent —
   un drapeau à usage unique y serait brûlé au premier passage (les trois pièges d'ordonnancement
   d'A107, payés une fois). */
```

## J144 — Une INSTANCE du journal (un passage d'un bloc) — en-tête ligne d'état (n° topologique, titre,

```
// Une INSTANCE du journal (un passage d'un bloc) — en-tête ligne d'état (n° topologique, titre,
// « passage k/N », réponse d'une décision, compteur, chevron, « ↺ Refaire ») et corps (étapes
// cochables / question + options — même grammaire ol.steps que la vue guidée). Le bouton
// d'avancement (« Continuer — … → » / « Terminer l'algorithme ✓ ») n'existe QUE sur l'instance
// du bout : le journal avance par le bout, une boucle est un simple « Continuer ».
// CHIP d'un passage condensé (v4.16.0 ; v4.16.2 : + TITRE ABRÉGÉ, décision utilisateur —
// « le numéro seul ne parle pas à un humain ») : n° topo + titre tronqué + ✓ (étapes), ou
// n° + « › réponse » en toutes lettres tronquée (décision — la réponse EST la trace) ;
// tap = DÉPLIER la carte sur place (consultation transitoire, cf. ovDropOpens).
/* LA RANGÉE D'HISTORIQUE (v5.6, maquette) : ✓ vert, « n · Titre », et à droite le compte en mono
   pour un bloc d'étapes, la réponse PRISE pour une décision (« le numéro seul ne parle pas à un
   humain », v4.16.2 — la règle vaut ici aussi, en toutes lettres puisqu'on a la largeur).
   Elle reste TAPABLE et mène au même endroit que la chip qu'elle remplace : `data-ovix` déplie la
   carte du passage sur place. Un seul verbe, une seule délégation. */
```

## J145 — A1 (v5.0.0, lot M2, maquettes proto-r4) — LA LÉGENDE DES REGISTRES VIT SUR LA CARTE. Elle

```
    /* A1 (v5.0.0, lot M2, maquettes proto-r4) — LA LÉGENDE DES REGISTRES VIT SUR LA CARTE. Elle
       n'existait QUE dans l'éditeur (`.crit-guide`) : ⚠, △ et la bulle mono ne s'apprenaient donc
       nulle part pour qui LIT la fiche sans jamais l'écrire — c'est-à-dire pour la majorité de ceux
       qui l'utilisent en soin. C'est le seul endroit du produit où ces trois signes se rencontrent.
       ELLE NE LISTE QUE CE QUE LE BLOC PORTE, et c'est ce qui la rend admissible : annoncer « △ à
       vérifier » sur un bloc sans aucune vigilance n'enseigne rien et coûte une ligne à chaque
       carte — c'est la règle « un panneau vide est du bruit », appliquée signe par signe. Un bloc
       sans aucun des trois n'a pas de légende du tout. */
    /* ⚠ CHAQUE ENTRÉE EST UN ÉLÉMENT, PAS UN FRAGMENT (v5.6, correctif). Elles étaient jointes
       par un « · » ; en le supprimant (il mesurait 1,3:1, cf. A33) je les ai jointes par RIEN, et
       comme ce sont des fragments inline elles se sont collées : « vital△ à vérifier ». Une liste
       dont les items ne sont pas des boîtes ne peut pas être espacée par `gap` — c'est la boîte
       qui reçoit l'écart, pas le texte. */
```

## J146 — les étapes : mesuré à 320 × 640, il naissait à y = 738, c'est-à-dire HORS ÉCRAN — alors

```
          les étapes : mesuré à 320 × 640, il naissait à y = 738, c'est-à-dire HORS ÉCRAN — alors
          que la doctrine le décrit comme « LE contrôle rempli de l'écran pendant l'excursion ».
          Il ne l'est que s'il se voit.
          ET CE N'EST PAS L'INVERSION DE HIÉRARCHIE QUE L'AUTEUR A REFUSÉE POUR L'ENTRÉE : mettre
          l'ENTRÉE en tête donnerait la position de plus forte saillance à l'événement le moins
          probable, et repousserait ce qu'on est en train de faire. Une fois DANS l'excursion, le
          retour EST l'action principale — la doctrine l'écrit —, et ce qu'il repousse, ce sont les
          étapes de la complication où l'on vient d'entrer. La dissymétrie est le raisonnement,
          pas une inconséquence. */
       /* A2 (v5.0.0, lot M2) — « ⏱ NOTER » REJOINT LA CARTE DU BLOC. Le lot T2 avait rapproché
          le JOURNAL (il se pose juste sous la carte) ; il n'avait pas rapproché le GESTE, qui
          restait un bouton du panneau, donc à lire et à viser ailleurs que là où l'on agit.
          Horodater EST un geste de bloc : on note l'heure de ce qu'on vient de faire ICI.
          Le bouton est le MÊME chemin que `#tkAdd` (aucune seconde écriture de l'évènement), et
          les propositions d'intitulés apparaissent où elles apparaissaient déjà — dans le panneau
          immédiatement dessous, donc sous le doigt. Il ne paraît QU'AU BOUT du journal : noter
          l'heure depuis une carte passée daterait le présent au nom du passé. */
       /* Do-Verify au pied : dans la rangée des gestes de bloc, avec « ⏱ Noter » et l'entrée sur
          complication — trois actions qui se prennent APRÈS avoir déroulé les étapes. */
       /* A7 — « VÉRIFIER » VIT À GAUCHE DE « CONTINUER », DANS LA RANGÉE DE PIED, SUR TOUT BLOC
          D'ÉTAPES.
          ⚠ CORRECTION D'UNE ERREUR À MOI (v5.6, signalé à l'usage : « où est passé le bouton
          vérifier ?? »). En écrivant A7 j'avais ajouté une condition que la maquette ne demande
          pas — « seulement si le bloc porte des challenges “::” » — au motif que « sans ::, il n'y
          a rien à rejouer ». C'EST FAUX, et la doctrine v4.11.0 le dit depuis toujours : la passe
          Do-Verify « redéroule TOUTES les étapes, déjà cochées comprises », et ses deux réponses
          — « Constaté ✓ » qui coche, « △ Écart » qui avance sans cocher — ne dépendent d'aucune
          réponse attendue. Le « :: » ENRICHIT la passe (il affiche la réponse à confirmer), il ne
          la conditionne pas. La condition rendait donc le bouton invisible sur toute fiche qui
          n'écrit pas de challenges — c'est-à-dire, en pratique, presque toutes.
          ⚠ LE LIBELLÉ, LUI, GARDE SON « :: » — décision de l'auteur, la maquette l'écrit ainsi.
          J'avais proposé de le retirer avec la condition ; c'est la CONDITION qui était fautive,
          pas le mot : « :: » nomme la PASSE (challenge-réponse), il n'annonce pas un pré-requis du
          bloc. Un bloc de DÉCISION reste exclu : il n'a pas d'étapes à re-constater. */
```

## J147 — PLAN DE L'AIDE — « Se repérer » (v4.12.0, réduit à UNE vue en v4.25.0) : rendu de flowPlan.

```
/* PLAN DE L'AIDE — « Se repérer » (v4.12.0, réduit à UNE vue en v4.25.0) : rendu de flowPlan.
   Le plan reste INERTE côté cochage (la trace vit dans le journal) et sert à NAVIGUER.
   UNE SEULE VUE, l'ÉCHELLE (ovPlanLadderHtml, mode compact ECAM) : une LIGNE par bloc, retraits
   de profondeur AVEC étiquette de la réponse qui ouvre la branche (« OUI › »), renvois mono
   abrégés (optAbbr : OUI→5 · ↺1 · ▪fin), tap ligne = détails in-place + « aller à ce bloc ».
   L'ex-vue « DÉTAILS » (organigramme hybride ovPlanTreeHtml, ses colonnes .pl-cols, ses rails
   de branche et son FIL D'ANCÊTRES STICKY ovPlanPin) est SUPPRIMÉE : seule des trois à recopier
   les étapes, elle rejouait la vue d'action au lieu de montrer autre chose — un SD ECAM ne redit
   jamais l'E/WD. Son CSS et ses commentaires ont été retirés avec elle (v4.31.1) ; l'épinglage de
   question survit ailleurs, en CSS quasi pur, sur les bandes du mode STATIQUE (svStickBands). */
// Abréviation des libellés d'options (échelle) : premier mot en capitales (6 car. max) ; deux
// options d'une même décision au même premier mot → initiale du 2ᵉ mot, sinon rang. PURE.
```

## J148 — FEUILLE « PLAN » plein écran (v4.23.0)

```
/* ===== FEUILLE « PLAN » plein écran (v4.23.0) =====
   Le Plan sert la VUE D'ENSEMBLE ; le fil LOCAL, lui, est déjà dans le journal. Il quitte donc
   le flux et s'ouvre en pleine largeur, où les intitulés cliniques tiennent entiers et où les
   branches d'une décision peuvent se ranger côte à côte.
   C'est une FEUILLE, jamais un onglet : un onglet est un état persistant qu'on peut oublier
   ouvert pendant qu'une alarme tombe — modèle ECAM E/WD (l'action, permanente) + SD (le
   synoptique, appelé puis relâché). Rien n'est dupliqué : même flowPlan, même numérotation
   commune, même état peint, mêmes gestes (data-plgo / data-plref / data-plln).
   UNE SEULE VUE depuis v4.25.0, l'ÉCHELLE : « Détails » (l'organigramme hybride) était la seule
   des trois à RECOPIER les étapes — elle rejouait la vue d'action au lieu de montrer autre chose,
   ce qu'un SD ECAM ne fait jamais. Le Schéma a rejoint le menu ⋯ (openFlowFull).
   ⚠ CE PARAGRAPHE DISAIT « pas de Tableau ici : ce serait une seconde porte vers le mode statique,
   dont #readTopSeg est le seul maître ». Les deux moitiés sont caduques (v5.6) : `#readTopSeg` a
   été PURGÉ au lot A avec le sélecteur de mode, et surtout la feuille ne BASCULE rien — elle
   MONTRE la page sans écrire `state.readMode`. L'objection visait une porte vers un ÉTAT ; il
   s'agit d'une excursion, qui se referme là où elle s'est ouverte. */
```

## J149 — DEUX VUES, UNE COQUE (v5.6). Ce n'est pas une seconde porte vers le MODE statique — rien ici

```
  /* DEUX VUES, UNE COQUE (v5.6). Ce n'est pas une seconde porte vers le MODE statique — rien ici
     n'écrit `state.readMode` : on MONTRE la page, on ne bascule pas le format de lecture. La
     distinction est celle du lot A : regarder n'est pas régler. C'est aussi ce qui répare
     l'excursion d'avant le soin, qui remplaçait la vue de travail sans laisser de retour (le dock,
     qui porte « ↩ Un bloc », n'existe pas encore à ce moment-là) et faisait tomber les deux
     colonnes du cockpit au passage. */
  /* LA FENÊTRE « TABLEAU » MONTRE LA FEUILLE ENTIÈRE (v5.10.0, demande de l'auteur : « ça ouvre
     une fenêtre déjà toute prête »). Elle rendait l'ancien tableau NU — donc, depuis le lot Page,
     une fonction qui n'existe plus : c'est le même générateur des deux côtés (`svSheetHtml`), avec
     son cartouche, sa colonne de référence et ses doses. Deux rendus de la même page auraient fini
     par diverger, et c'est justement AVANT le soin qu'on vient la lire en entier. */
```

## J150 — ON GARDE LE BLOC COURANT LÀ OÙ IL ÉTAIT (v4.74.2, signalé à l'usage : « comment améliorer le

```
   /* ON GARDE LE BLOC COURANT LÀ OÙ IL ÉTAIT (v4.74.2, signalé à l'usage : « comment améliorer le
      passage guidé/statique lorsqu'on a déjà scrollé ? »). Avant : `scrollTo(0,0)`, systématique.
      Or les deux vues n'ont pas la même hauteur, donc conserver `scrollY` n'aurait rien voulu dire
      non plus — la seule ancre qui EXISTE des deux côtés est le bloc courant, et les deux vues le
      marquent avec la MÊME classe `.cur` (`.ov-block.cur` en dynamique, `.sv-cell`/`.sv-band` en
      statique). C'est donc `keepAnchor`, la mécanique ECAM du projet, appliquée au bon élément.
      DEUX REPLIS VERS LE HAUT, tous deux voulus : pas de session démarrée (aucun `.cur` — il n'y a
      rien à retrouver), et bloc courant HORS de l'écran avant la bascule (le ramener au même
      décalage négatif déposerait la vue à un endroit qu'on ne regardait pas ; même test de
      visibilité qu'`ovAdvanceRender`). */
   /* ON GARDE LE PREMIER BLOC VISIBLE — SESSION OU PAS (v4.77.0, signalé à l'usage : « je n'ai
      pas démarré de session, je suis en train de scroller, l'en-tête est rétrécie, je passe en
      statique, je retourne en haut de la page avec l'en-tête dépliée et ça fait moche /
      perturbant »). La v4.74.2 ancrait sur le bloc COURANT, ce qui ne vaut que si une session est
      démarrée : sans elle, aucun `.cur` n'existe et l'on retombait sur `scrollTo(0,0)` — donc
      exactement le saut décrit, aggravé par l'en-tête qui se redéplie au passage.
      L'ancre juste n'est pas « le bloc courant » mais « CE QU'ON REGARDE » : le premier bloc
      dont le bas passe sous les couches collantes. Les deux vues portent l'ID de bloc dans un
      attribut (`data-ovb` en dynamique, `data-svgo` en statique), donc l'ancre se TRADUIT d'une
      vue à l'autre — c'est ce que le second sélecteur de `keepAnchor` permet.
      On ne repart du haut que si l'on y était déjà, ou si aucun bloc n'est identifiable. */
   /* ⚠ UNE EXCURSION REVIENT OÙ L'ON ÉTAIT — LES DEUX JAMBES NE SE RESSEMBLENT PAS (audit externe
      v5.10.0, signalé à l'usage : « quand je sors du mode tout voir mon scroll est tout en bas,
      il devrait être sauvegardé à la dernière position où j'étais »).
      La traduction d'ancre ci-dessous est JUSTE à l'ALLER : on prend du recul, et l'on veut voir
      le bloc qu'on regardait. Elle était appliquée AUSSI au RETOUR, et c'est là qu'elle se
      retourne contre son intention : la position d'arrivée devient celle où l'EXCURSION s'est
      terminée, pas celle d'où l'on est parti. Mesuré : parti de 300, arrivé dans « Tout voir »,
      défilé jusqu'au bout, retour → scrollY 575, c'est-à-dire le MAXIMUM du document.
      Ce n'est pas un défaut d'ancrage : c'est un défaut de DOCTRINE. Depuis le lot A, « Tout voir »
      n'est plus une bascule de mode mais une EXCURSION à retour nommé (« ↩ Un bloc »), et le
      dossier a déjà tranché ce que vaut un retour d'excursion — `_bgUnlock` restitue la position
      AU PIXEL quand on referme une feuille. La règle v4.77.0 (« l'ancre est ce qu'on REGARDE »)
      reste vraie de la jambe ALLER, qui est bien un changement de vue.
      ⚠ ET LE SECOND SYMPTÔME TOMBE AVEC LE PREMIER : atterrir au MAXIMUM du défilement est la
      condition exacte du rabat de fin de page (A46, A109) et du rebond iOS qui déplace les
      couches fixes (v5.0.2) — « la barre flottante et les clics sont décalés jusqu'à ce qu'on
      remonte ». On ne borne pas le symptôme, on cesse de déposer les gens à la borne. */
   /* ⚠ ON MÉMORISE UNE ANCRE, PAS UN NOMBRE (signalé à l'usage : « si quelqu'un dans une session
      partagée a continué à cocher et/ou passé de bloc pendant que j'étais dans Tout voir, la
      longueur de la page change — que je ne me retrouve pas tout en bas »). La remarque est juste
      et elle est structurelle : un `scrollY` brut ne décrit une position que dans le document qui
      l'a produit. Pendant l'excursion, un lot distant peut condenser un passage achevé (R6 : une
      carte de 559 px devient une rangée de 44) — la position d'avant désigne alors autre chose,
      et si le document a raccourci, le navigateur la RABAT au maximum, c'est-à-dire au défaut
      qu'on vient de corriger, par une autre porte. C'est la leçon A108, exactement.
      On retient donc CE QU'ON REGARDAIT : le bloc sous le haut de la zone utile, et son décalage
      à l'écran. Au retour, on repose ce bloc au même décalage — le document peut avoir changé de
      longueur, l'ancre reste vraie. Le `y` brut n'est plus qu'un REPLI, pour le cas où le bloc
      n'existe plus (branche abandonnée, fiche révisée) ; il est alors borné. */
```

## J151 — FEUILLE « CONSULTER » (v4.23.0)

```
/* ===== FEUILLE « CONSULTER » (v4.23.0) =====
   Deux natures de contenu, à ne pas confondre :
     • des COPIES de ce qui doit rester joignable à tout instant — rappels, surveillances,
       posologie. L'original ne bouge pas du flux ; la feuille évite seulement d'avoir à
       remonter/descendre un journal qui grandit. Une même source, deux rendus : jamais de
       divergence possible.
     • les ORIGINAUX de ce qui se consulte — différentiels, schémas, documents, références,
       voir aussi. Ceux-là quittent réellement la colonne d'action.
   La NOTE personnelle reste dans le flux : seul bloc à état éditable (son bouton re-rend la vue
   et restaure le défilement — logique de flux, pas de feuille).
   Ouverture en PULL seulement ; `sect` déplie et met en évidence une section précise, ce qui
   permet au lien « Tableau atypique ? » de l'étape ① d'atterrir DIRECTEMENT sur les
   différentiels (sans ce ciblage, on remplacerait un accès direct par une chasse au trésor). */
```

## J152 — (surveillances et posologie ne sont plus recopiées ici — cf. le commentaire de `body`)

```
  // (surveillances et posologie ne sont plus recopiées ici — cf. le commentaire de `body`)
  /* LE DESSIN DE LA MAQUETTE (v5.0.0, lot M10) : une RANGÉE par entrée — case inerte, intitulé
     en gras, et la valeur attendue en PILULE MONO à droite. C'est la forme que prend une
     référence qu'on CONSULTE (par opposition à une étape qu'on exécute) : le nom sert à trouver,
     la pilule sert à lire. Les cases sont `aria-hidden` et sans `data-ck` — la feuille Consulter
     est INERTE depuis la v4.23.0 (0 coche, 0 démarrage), un harnais le vérifie.
     ⚠ CE QUE JE N'AI PAS REPRIS DE LA MAQUETTE, ET POURQUOI : elle y remet « DOSES » et
     « SURVEILLANCES ». La v4.25.3 les en avait RETIRÉES sur mesure — elles pesaient 57 % de la
     hauteur de la feuille (451 px sur 790) alors qu'elles existent déjà dans le flux, dans le
     rail et en Statique, soit QUATRE exemplaires : elles repoussaient de ~450 px le contenu
     réellement unique (les différentiels), c'est-à-dire le motif même pour lequel on ouvre. Le
     dessin est repris, la duplication non — à rouvrir ensemble si l'arbitrage a changé. */
```

## J153 — v4.23.0 : PAS de copie du chapeau « Ne pas oublier » ici (décision utilisateur). Il est déjà

```
  // v4.23.0 : PAS de copie du chapeau « Ne pas oublier » ici (décision utilisateur). Il est déjà
  // en tête de fiche, entier et jamais replié ; un pavé rouge rouvert à chaque consultation
  // repoussait ce qu'on vient réellement chercher (une dose, un différentiel) sans rien apporter.
  /* ORDRE PAR UTILITÉ (v4.25.0) : l'UNIQUE avant les COPIES, l'urgent avant la traçabilité.
     Les différentiels passent en tête — c'est le motif principal d'ouverture en cours de soin
     (« ça ne colle pas »), et le seul contenu clinique qu'on ne trouve nulle part ailleurs.
     Surveillances et posologie SUIVENT : ce sont des copies (elles restent dans le flux, cf. la
     règle AC 120-71B « ce qui se consulte pendant un geste reste près du geste ») — on les garde
     ici pour ne pas avoir à fermer la feuille afin de vérifier une dose, mais elles ne méritent
     pas la première place. Documentation et traçabilité ferment la marche. */
  /* LA FEUILLE NE PORTE QUE CE QUI N'EST NULLE PART AILLEURS (v4.25.3, audit d'utilité).
     Mesuré : 57 % de sa hauteur (451 px sur 790) était de la REDITE — les surveillances existent
     déjà dans le flux (③) et en Statique, la posologie dans le flux, le rail (≥ 780) ET en
     Statique, soit QUATRE exemplaires. Ces copies repoussaient de ~450 px le contenu réellement
     unique (documents, références) : on faisait défiler ce qu'on avait déjà sous les yeux pour
     atteindre ce qu'on venait chercher — l'inverse du decluttering ECAM, qui montre ce qui manque
     et tait ce qu'on a déjà.
     Ce qui reste est donc exactement « ce que je n'ai pas sous les yeux ». Et ce sont les
     DIFFÉRENTIELS qui justifient le bouton permanent du quai : de la documentation seule irait au
     menu ⋯ ; le « ça ne colle pas » mérite un tap. Le nom « Consulter » est CONSERVÉ pour cette
     raison — « Documents » ou « Annexes » sous-vendrait les différentiels, et personne dont le
     tableau ne colle pas n'ouvrirait un bouton nommé « Documents ». */
```

## J154 — Le quai n'existe que s'il porte quelque chose (minuteurs vivants et/ou accès au Plan).

```
// Le quai n'existe que s'il porte quelque chose (minuteurs vivants et/ou accès au Plan).
/* ═══ LES DEUX GESTES DU DOCK — ⚡︎ COMPLICATIONS ET ⏱ NOTER L'HEURE (v5.6, lot 2) ═══════════
   Ils vivaient dans la carte de bloc (rangée `.cx-row`), là où le lot M2 les avait mis « à
   l'endroit du geste ». La refonte les remonte au DOCK pour une raison mesurée et une seule :
   la pile d'actions de la carte dépassait le plafond de 25 % de sa hauteur sur un bloc court
   (R9), et ces deux-là ne sont pas des gestes de BLOC — une complication survient quand elle
   survient, un horodatage se pose à n'importe quel moment. « Vérifier :: », lui, RESTE dans la
   carte : c'est un geste de bloc au sens strict (il rejoue les challenges DE CE BLOC), et A7 le
   dit. Le dock reste pur session.
   ⚠ CE QUI NE CHANGE PAS : `cxEnter` et son retour prévu, `tkNoteNow` et son accusé de
   réception, l'attribution de rôle (`MUTE_SEL`), l'horodatage IMMÉDIAT au tap. On change
   l'ADRESSE du geste, jamais le geste — un verbe réécrit est un verbe qui diverge (leçon du
   cœur de cochage, v4.42.0, et des verbes du lecteur, v4.55.0). */
```

## J155 — ⚠ LA TOUCHE ⚡︎ SE RÉÉVALUE À CHAQUE NAVIGATION, PAS SEULEMENT AU RENDU COMPLET (v5.6).

```
/* ⚠ LA TOUCHE ⚡︎ SE RÉÉVALUE À CHAQUE NAVIGATION, PAS SEULEMENT AU RENDU COMPLET (v5.6).
   `cxEnter` ne re-rend que le JOURNAL (`renderOvOnly`) — c'est la doctrine du dossier : rien ne
   bouge au-dessus du bout. Mais la touche du dock dépend de la POSITION (« on ne propose pas
   d'entrer là où l'on est déjà »), et un rendu ciblé ne repassait pas par le chrome : la touche
   restait proposée alors qu'on venait d'entrer dedans. Elle a donc son point d'écriture propre,
   appelé par le chrome ET par le journal — un seul endroit qui décide, deux qui le déclenchent. */
/* A54 APPLIQUÉE À LA TOUCHE ⚡︎ DU DOCK — ON DÉCIDE CE QUI TOMBE (audit externe v5.10.0).
   Le libellé était clampé à deux lignes ET encore tronqué : « FV réfractaire.. » à 390 px,
   « FV réfractaire (CEE… » à 320. Or savoir LAQUELLE des complications s'ouvre est tout l'objet
   du bouton — c'est la règle « un mot COUPÉ est moins lisible qu'un mot absent », prise à
   l'endroit où elle coûte le plus. On ne raccourcit donc pas au hasard : le prompt IA et les
   fiches d'exemple écrivent « nom (précision) », et la PARENTHÈSE est faite pour tomber — elle
   qualifie, elle n'identifie pas. La phrase entière reste dans le `aria-label` et dans l'index
   ⚡ du flux, qui ont tous deux la place.
   ⚠ SEULEMENT EN QUEUE, ET SEULEMENT SI LA TÊTE SURVIT : « (Choc) » sans tête reste entier —
   une abréviation qui rendrait une chaîne vide serait pire que la troncature qu'elle remplace. */
```

## J156 — Rangée de COMMANDES : visible si au moins une commande l'est. ⚠ Correctif (retombée de purge,

```
  // Rangée de COMMANDES : visible si au moins une commande l'est. ⚠ Correctif (retombée de purge,
  // règle 14) : depuis les lots T8/A (v5.0.0) la rangée porte #allBtn et #refBtn, mais le test
  // lisait encore #modeSeg et #planBtn (toujours null) en ignorant #allBtn — une fiche À
  // ALGORITHME mais SANS annexe (Consulter masqué) perdait donc la rangée entière, « ⤢ Tout
  // voir » compris, en silence.
  /* LE DOCK — visible dès qu'une de ses quatre touches l'est. Il n'a plus rien à ajuster : les
     touches sont de largeur ÉGALE, et A2 fait tomber les deux étiquettes d'ouverture par media
     query. Ce qui reste à décider, c'est la RÉSERVE DE PLACE en bas de page : un dock FIXE ne
     prend aucune hauteur de flux, donc sans elle le dernier contenu de la colonne d'action
     naîtrait DERRIÈRE lui — et la dernière étape d'un bloc est exactement ce qu'on ne peut pas
     se permettre de cacher. La classe le dit au CSS, qui pose le rembourrage. */
```

## J157 — v5.4.2-r — LE RAIL SE RÉÉQUILIBRE À 780-1199 px (R1+R2, décision utilisateur sur maquette

```
/* ═══ v5.4.2-r — LE RAIL SE RÉÉQUILIBRE À 780-1199 px (R1+R2, décision utilisateur sur maquette
   chiffrée). MESURÉ (session réelle, fenêtre du rail 642 px) : 1 625 px de contenu, 60 % ENTERRÉ
   sous un pli invisible, le journal à 583 px dessous — séparé des compteurs par la posologie et
   toute l'Échelle, c'est-à-dire exactement la séparation que la v5.4.0 a corrigée en étroit.
   R1 : le JOURNAL remonte CONTRE les compteurs, en dépliant d'une ligne (les trois familles de
   traçabilité redeviennent voisines à toutes les largeurs) — replié par défaut sous 1200, déplié
   par défaut en cockpit (rail à 4 zones, la place existe). R2 : sous 1200, l'ÉCHELLE devient un
   dépliant d'une ligne qui annonce son compte ET la position courante (« ici : ① … ») — elle
   était de toute façon déjà sous le pli, et une zone repliée qui S'ANNONCE est plus fidèle à
   l'ECAM qu'un contenu enterré muet (modèle ECL, v4.16.4). À ≥ 1200 l'Échelle vit dépliée dans
   la colonne du plan, comme avant. `<details>` NATIFS (clavier, toggle, aria-expanded implicite),
   état TRANSITOIRE par fiche (state.railTkOpen/railLadOpen, classés SHARE_LOCAL, remis à zéro
   par openRead) — regarder n'est pas régler. DIVERGENCE ASSUMÉE avec la maquette : « Surveiller
   ensuite » vit DANS le corps de l'Échelle et se replie avec elle — sa source reste le flux (③),
   le rail n'en portait qu'une copie. */
```

## J158 — ÉCHELLE DU RAIL (v4.23.0) : mêmes gestes que dans le Plan — déplier une ligne, aller à un bloc,

```
/* ÉCHELLE DU RAIL (v4.23.0) : mêmes gestes que dans le Plan — déplier une ligne, aller à un bloc,
   suivre un renvoi. Délégation propre au rail : il n'est pas dans `.ov-wrap`, donc les écouteurs du
   journal ne l'atteignent pas. Re-rendu ANCRÉ sur la ligne touchée (le rail ne doit pas sauter sous
   le doigt). Le défilement d'un renvoi vise le conteneur RÉEL — `.read-plan` en cockpit,
   `.read-side` sinon : viser le rail droit en dur ne déplaçait rien quand le plan vit à gauche. */
/* ══ LES COMMANDES D'UN MINUTEUR DU RAIL SE DÉPLIENT AU TAP (v5.6, maquette) ═══════════════════
   La colonne AFFICHE ; on la touche pour COMMANDER. Trois précautions :
   · l'état est TRANSITOIRE par minuteur (`state.railTmOpen`, classé SHARE_LOCAL) — regarder n'est
     pas régler, et déplier chez soi ne doit rien déplier chez l'autre ;
   · un minuteur ÉCHU n'est jamais concerné : ses commandes sont visibles d'office (CSS), parce
     qu'acquitter une alarme ne se cherche pas ;
   · la classe est posée SUR PLACE, sans re-rendu — le rail ne doit pas sauter sous le doigt, et
     `renderTkOnly`/`repaintRailLad` la reposent à partir de l'état au prochain rendu complet.
   ⚠ On ignore les taps qui viennent d'un CONTRÔLE : sans cela, presser « Pause » replierait la
   carte sous le doigt qui vient de l'ouvrir. */
```

## J159 — ⚠ UNE BRANCHE PEUT N'AVOIR AUCUNE RANGÉE À ELLE — ET ELLE DISPARAISSAIT EN ENTIER

```
      /* ⚠ UNE BRANCHE PEUT N'AVOIR AUCUNE RANGÉE À ELLE — ET ELLE DISPARAISSAIT EN ENTIER
         (v5.17.4, signalé à l'usage : « le parcours s'affiche mal pour les blocs conditionnels,
         uniquement certains s'affichent »). Ce n'est pas un cas tordu, c'est le cas ORDINAIRE
         d'une option qui rejoint directement le point de convergence : `flowPlan` la rend en un
         seul `link`, aucune rangée de bloc ne consomme donc son étiquette, et `brclose`
         l'effaçait. Mesuré sur « Accouchement inopiné » : la branche « OUI — SUR PLACE » de
         l'imminence était MUETTE quand « NON — TRANSPORT » s'affichait — une décision à deux
         issues qui n'en montre qu'une se lit comme un rendu à moitié fait, et c'est exactement
         ce qui a été signalé. La vue « Parcours » de « Tout voir », elle, le faisait déjà
         (`ovParcoursHtml`, jmp) : on reprend sa règle, pas une seconde grammaire — l'étiquette,
         puis où mène la branche. Les liens qui SUIVENT une rangée restent tus : la colonne de
         renvois de cette rangée les porte déjà. */
```

## J160 — Section « À TOUT MOMENT » (v4.26.0) : les blocs de complication HORS tronc, SANS numéro de

```
  /* Section « À TOUT MOMENT » (v4.26.0) : les blocs de complication HORS tronc, SANS numéro de
     séquence (ils s'entrent par l'événement, pas par la position — les numéroter les ferait lire
     comme « l'étape d'après »). Tap = y aller (navigation, sémantique jumpToBlock du plan). */
  /* ⚠ « À TOUT MOMENT » A QUITTÉ CETTE COLONNE (v5.0.0, demande utilisateur : « c'est inutile »).
     Elle ORIENTE dans la séquence — or une complication n'y est justement pas, et l'endroit où on
     l'attend est la carte du bloc (bouton constant) ou la vue « Toute la fiche », qui la gardent
     toutes deux. Une section de deux lignes qui n'aide pas à se repérer coûtait un en-tête, un
     marqueur et une exception de mise en page. `.pl-sec.cx` et `.pl-line.cxl` sont PURGÉS. */
  /* « △ SURVEILLER — APRÈS LES GESTES » : les items de rôle `watch`. Ils vivent déjà dans le flux
     (étage « Surveillances & pièges ») ; ici c'est une COPIE d'orientation, inerte, à sa place
     chronologique — ce qui vient après. Registre ATTENTION, jamais rouge : on ne surveille pas ce
     qui tue, on surveille ce qui dérive. */
  /* « SURVEILLER APRÈS LES GESTES » : mêmes RANGÉES que les blocs — nom à gauche, valeur en mono
     à droite. Une liste à puces aurait été une seconde grammaire dans la même colonne, pour des
     objets qui se lisent exactement pareil : un nom, un repère chiffré. */
```

## J161 — PALIERS DE LARGEUR EFFECTIVE (v4.73.1) — le pendant de `--zf` pour les SEUILS, là où la règle 10

```
/* PALIERS DE LARGEUR EFFECTIVE (v4.73.1) — le pendant de `--zf` pour les SEUILS, là où la règle 10
   ne parlait que des hauteurs. Une media query mesure la fenêtre du périphérique ; sous `zoom`, la
   mise en page dispose de `largeur ÷ zoom`. Ces classes portent donc la largeur RÉELLEMENT
   disponible, et elles sont l'équivalent exact des `max-width` qu'elles remplacent : à zoom 1,
   `innerWidth ÷ 1` est la valeur que la media query aurait lue.
   Seuils identiques aux anciens blocs, bornes comprises (`max-width:399.98px` ≡ `< 400`).
   Posée à CHAQUE rendu (via `applyViewChrome`) plutôt que sur le seul évènement de
   redimensionnement : un rendu peut suivre un changement de zoom, une rotation ou une reprise
   d'onglet sans qu'aucun `resize` ne soit arrivé, et un palier manquant est un débordement
   silencieux — exactement ce que ce dispositif existe pour empêcher. Le coût est une division et
   quatre `classList.toggle` idempotents. */
/* ⚠ UN CINQUIÈME PALIER, ET IL NE PEUT NAÎTRE QUE DU ZOOM (audit externe v5.10.0). Aucun appareil
   servi ne fait 300 px : `zw300` ne se pose donc JAMAIS par la largeur seule — il ne se pose que
   lorsqu'un appareil étroit rencontre le plus grand réglage de texte (320 ÷ 1,3 = 246 px CSS),
   c'est-à-dire exactement la configuration où le budget d'écran cédait. C'est aussi la
   démonstration de la règle 10 par l'exemple : ce palier serait INEXPRIMABLE en `@media`, qui ne
   voit que la fenêtre du périphérique et répondrait 320. */
/* ⚠ 1200 N'EST PAS UN PALIER DE COMPRESSION, C'EST UN PALIER DE DÉPLIAGE (v5.17, planche 20) —
   le premier de cette table à marquer une largeur CONFORTABLE plutôt qu'une largeur contrainte,
   et il est donc posé la plupart du temps. Il vaut pour la barre de sélection, dont la forme
   dépliée réclame 757 px de largeur utile : cf. le long commentaire de `.sel-bar` dans le CSS,
   qui donne les mesures et dit pourquoi ni une media query ni le palier 560 de la planche ne
   pouvaient convenir. */
// 640 (v5.19.5) : la chaîne de compression de la rangée d'ÉDITEUR (640→430→360) passe aux zw —
// mesuré sous zoom 130 % : la recette anti-chevauchement des halos ne s'appliquait pas à largeur
// effective < 430 (le tap partait au dernier élément du DOM), et « Aperçu » restait en toutes
// lettres là où l'icône s'imposait. Équivalence exacte à zoom 1, prouvée aux 4 témoins.
```

## J162 — ⚠ `fitCtrlRow` A ÉTÉ SUPPRIMÉE AVEC LA RANGÉE QU'ELLE AJUSTAIT (v5.6, lot 2 — règle 14).

```
/* ⚠ `fitCtrlRow` A ÉTÉ SUPPRIMÉE AVEC LA RANGÉE QU'ELLE AJUSTAIT (v5.6, lot 2 — règle 14).
   Elle remettait `#crisisCtrl .dock-in` à plat, lisait son débordement RÉEL et n'enroulait
   qu'après avoir épuisé les paliers de compression : un dispositif entièrement mesuré, né du
   trou de 430 à 441 px (v4.74.2) et de la grande police (v4.73.1). Le dock à quatre touches de
   largeur ÉGALE n'a plus rien à ajuster — sa largeur ne dépend pas de la longueur des libellés,
   et A2 fait tomber les deux étiquettes d'ouverture par media query, pas par mesure.
   ⚠ SON APPELANT ENCHAÎNAIT `fitCtrlRow()` PUIS `syncHdrScroll()` : le second appel RESTE, et
   c'est le point à ne pas rater — `--hdr-h` et `--stick-top` sont consommés par le quai, le rail
   A→Z, le rail de lecture, `stickBase()` et le `scroll-margin` qui empêche le masquage total
   d'une cible d'ancre (exigence AA, sonde 2.4.11 d'audit-a11y). */
/* SUPPRIMÉS EN v4.25.0 (audit Plan/Statique), nettoyage achevé en v4.31.1 : `ovPlanTreeHtml`
   (l'organigramme « Détails ») et tout le FIL D'ANCÊTRES COLLANT qui n'existait que pour lui
   (`ovPlanStick`, `ovPlanPin`, tops cumulés mesurés, chips d'option injectés, z-ordre pdN, la
   variable --pl-stick). Détails était la seule vue du Plan à RECOPIER LES ÉTAPES : elle rejouait
   la vue d'action au lieu d'être un synoptique, ce qu'un SD ECAM ne fait pas. Le Plan n'a plus
   qu'une vue — l'Échelle — qui n'a pas d'ancêtres à épingler.
   v4.25.0 avait laissé derrière elle ~20 règles CSS, deux `querySelector` qui ne pouvaient que
   renvoyer null, quatre branches de délégation `data-plfold` inatteignables, une fonction vide
   appelée depuis quatre sites, et une démo du design system qui publiait le composant disparu —
   tout cela est parti en v4.31.1. L'épinglage de question, lui, SURVIT ailleurs et en mieux :
   sur les bandes du mode STATIQUE (`svStickBands`), où une seule mesure par rendu suffit.
   Historique complet dans git (tag v4.24.0) si la question devait être rouverte. */
```

## J163 — Rendu d'un geste d'AVANCEMENT (v4.16.3, doctrine ECAM du guidé v4.14.4 appliquée au

```
/* Rendu d'un geste d'AVANCEMENT (v4.16.3, doctrine ECAM du guidé v4.14.4 appliquée au
   journal) : le re-rendu condense l'historique au-dessus (cartes -> chips), ce qui décale
   tout — on ANCRE donc la vue sur l'instance d'où part le geste (compensation scrollBy),
   puis on ne défile QUE si la nouvelle carte du bout n'est pas déjà entièrement visible.
   Résultat : avancer bloc à bloc ne fait plus « sauter » l'écran ni disparaître les chips. */
/* LE DRAIN DU RÉGIME « deferred » (v5.0.0) — LÀ OÙ LA DOCTRINE LE PROMETTAIT DÉJÀ.
   `SHARE_APPLY` classe `verify` et `gap` en 'deferred' et le commentaire dit : « mis en file,
   appliqué au prochain geste LOCAL DE NAVIGATION ». C'était faux dans les faits : le SEUL site
   qui vidait `Share._defer` était `rmResume`, c'est-à-dire le bouton « reprendre » DU MODE
   LECTEUR. Un invité qui n'ouvrait jamais le lecteur ne recevait donc JAMAIS la trace do-verify
   de l'hôte — elle s'empilait indéfiniment, en silence. Le défaut est de la même famille que
   celui consigné en v4.55 (« aucun site du fichier ne drainait _defer »), réparé à moitié : on
   avait donné un drain, pas le bon.
   `ovAdvanceRender` EST le geste local de navigation, et il l'est exclusivement : ses trois
   appelants sont `ovAnswer` (choisir une branche), `ovNewPass` (↺ Refaire) et le handler de
   « Continuer ». L'application distante, elle, passe par `keepAnchor` directement — elle ne
   repasse donc pas ici, et le drain ne peut pas se déclencher sur un évènement distant.
   ON DRAINE AVANT DE RENDRE : l'application ancrée pose la trace dans l'état, puis le rendu du
   geste local peint les deux d'un coup — l'utilisateur voit sa navigation ET ce qui l'attendait,
   dans le même mouvement. C'est exactement « l'acquittement par l'action ». */
```

## J164 — APPLICATION ANCRÉE — l'hôte a avancé, et l'écran de l'autre doit suivre SANS bouger sous son

```
/* APPLICATION ANCRÉE — l'hôte a avancé, et l'écran de l'autre doit suivre SANS bouger sous son
   doigt. Le journal est reconstruit (une navigation poste une carte au bout, la condensation peut
   replier des passages plus haut), donc on passe par `keepAnchor` : on mesure la position d'un
   repère avant, on re-rend, on compense le résidu. Le repère choisi est la DERNIÈRE carte du
   journal — celle que l'utilisateur a sous les yeux ; si elle n'existe pas encore, `keepAnchor`
   rend `null` et l'on n'invente rien.
   ON NE DÉFILE PAS vers la nouvelle carte : le geste n'est pas le sien. Il apprend qu'elle est là
   par `#srLive` et par la carte elle-même, à l'endroit où le journal l'a posée. C'est la
   différence exacte avec `ovAdvanceRender`, qui défile parce que c'est l'utilisateur qui vient
   d'appuyer sur « Continuer ». */
/* `muet` : appliquer SANS peindre. L'écran affiche autre chose (bibliothèque, éditeur, une autre
   aide) — l'état doit quand même entrer, sinon il est perdu définitivement (cf. `onEvents`), mais
   reconstruire le journal ferait un rendu complet et arracherait l'utilisateur à sa page. */
```

## J165 — SUIVRE LE BORD VIF, ET SEULEMENT SI ON Y ÉTAIT (correctif — « quand la session se synchronise

```
  /* SUIVRE LE BORD VIF, ET SEULEMENT SI ON Y ÉTAIT (correctif — « quand la session se synchronise
     et que des blocs sont passés, pas de défilement, on finit par perdre le bloc actuel »).
     La doctrine d'origine — ne JAMAIS défiler sur un geste qui n'est pas le sien — protégeait le
     bon cas et en cassait un autre : celui de quelqu'un qui SUIT la progression et que l'hôte
     laisse derrière, carte après carte, jusqu'à ne plus voir du tout où en est le soin.
     Le critère n'est donc pas « qui a appuyé » mais OÙ REGARDAIT-IL : si le bout du journal était
     à l'écran avant l'application, il suivait le bord vif et on l'y garde ; s'il avait défilé
     ailleurs (il consulte un passage antérieur, une décision plus haut), rien ne bouge — l'annonce
     `#srLive` et la carte elle-même l'informent, exactement comme avant.
     C'est la même règle de VISIBILITÉ qu'`ovAdvanceRender`, appliquée à l'intention constatée au
     lieu de l'être au geste. */
```

## J166 — I4 (v4.62.0) — LA LISTE D'ÉTAPES N'EST ÉCRITE QU'UNE FOIS. Elle l'était TROIS : dans la vue

```
/* I4 (v4.62.0) — LA LISTE D'ÉTAPES N'EST ÉCRITE QU'UNE FOIS. Elle l'était TROIS : dans la vue
   guidée, dans le journal, et le lecteur en produisait une variante encore différente (un
   paragraphe, pas une liste). Trois écritures, donc trois occasions de diverger — et elles
   avaient déjà divergé : le journal peignait la trace do-verify (« ✓✓ constaté », « △ écart »),
   la vue guidée non, pour la même donnée. Ce générateur est le SURENSEMBLE : la trace apparaît
   partout où l'étape apparaît.
   `opts.cur` (index de la ligne courante) sert la densité LECTEUR : même DOM, même verbe
   `data-ck`, même registre — seule la mise en avant change, par une classe. */
/* LOT T7 — « ×2 » : L'ITEM CONFIRMÉ PAR LES DEUX (AC 120-71B §5.2.2.5, « items critiques vérifiés
   par les DEUX membres d'équipage »). C'était la seule exigence explicite de la source que le
   modèle ne savait pas EXPRIMER : une chaîne d'étape n'a pas de place où accrocher une propriété.
   Elle en a une depuis que l'item porte une identité (lot T6).
   REGISTRE : NEUTRE, jamais rouge ni ambre. Ce n'est ni un danger (⚠) ni un piège (△) — c'est une
   consigne de PROCÉDURE sur la façon de confirmer. Lui donner une couleur de registre l'aurait
   mise en concurrence avec le contenu clinique, ce que la règle 8 proscrit ; et le glyphe seul ne
   suffirait pas (WCAG 1.4.1), d'où le mot au lecteur d'écran.
   `opts.items` est FACULTATIF : sans lui le rendu est celui d'avant, au caractère près — les trois
   appelants (vue guidée, journal, lecteur) le passent, mais un appelant futur qui l'oublierait
   dégraderait proprement au lieu de casser. */
```

## J167 — MODE LECTEUR (v4.11.0) : plein écran, piloté sur le bout du journal.

```
    // MODE LECTEUR (v4.11.0) : plein écran, piloté sur le bout du journal.
    // (Les trois branches du PLAN — data-plref / data-plln / data-plgo — ont été SUPPRIMÉES ici
    //  en v4.44.0 : elles étaient INATTEIGNABLES. Ce gestionnaire délègue sur `.ov-wrap`, le
    //  JOURNAL ; or le plan a quitté le journal en v4.23.0 pour vivre dans le RAIL (`.rail-lad`,
    //  câblé par `bindReadEvents`) et dans la FEUILLE plein écran (`#planModal`, câblée à part).
    //  Mesuré avant retrait, dans 21 configurations — 3 largeurs (390/800/1280) × 7 états
    //  (journal, session vive, passages, feuille ouverte, feuille refermée, statique, retour) :
    //  `.ov-wrap [data-plln],[data-plgo],[data-plref]` = 0 partout, pendant que le rail en portait
    //  9 dès 800 px et la feuille 9 une fois ouverte. Les deux copies VIVANTES restent, et elles
    //  divergent — ne pas les factoriser sans décision : la version du rail ancre sur
    //  `.rail-lad`, celle de la feuille sur son propre corps.)
```

## J168 — MODE STATIQUE (v4.13.0) : TABLEAU compact façon aide SFAR/CAMR

```
/* ===== MODE STATIQUE (v4.13.0) : TABLEAU compact façon aide SFAR/CAMR =====
   3e mode de lecture — l'algorithme ENTIER carrelé en cellules télégraphiques, GÉNÉRÉ depuis
   flowPlan (post-dominateurs, numérotation commune) : tronc = cellules pleine largeur,
   décision = bande ATTENTION + branches en colonnes (auto-fit plafonné cN, pile en étroit).
   INERTE côté cochage (doctrine du plan) : l'état de session est PEINT en lecture seule
   (✓ dernier passage, ● ici = bout du journal, hors chemin estompé + mention, coches du
   dernier passage relisibles) ; taper une cellule = svJump (bloc jamais visité → il ENTRE au
   bout du journal, comme jumpToBlock — JAMAIS de démarrage de session, JAMAIS de défilement :
   rien ne bouge sous le doigt). Les FLÈCHES (fourche ambre, convergence grise, retour bleu en
   gouttière) sont dessinées APRÈS le rendu par svPaintArrows sur les positions réelles, et ne
   sont jamais la seule information : les pilules « → n » / « ↺ n » restent le texte de vérité
   (branches empilées, impression, lecteurs d'écran — flèches aria-hidden). */
// (`svBranchIssue` et `svLoopTargets` sont PURGÉES v5.10.2 : leurs appelants — le peintre de
//  fourches/convergences et les brins de gouttière d'avant la grille unique — sont partis au lot
//  v5.10.0 (A137) sans qu'elles suivent. Règle 14, témoins partis avec elles.)
```

## J169 — L'ONGLET « PARCOURS » N'EST PAS L'ÉCHELLE (v5.0.0, maquette — signalé à l'usage : « c'est pas

```
/* L'ONGLET « PARCOURS » N'EST PAS L'ÉCHELLE (v5.0.0, maquette — signalé à l'usage : « c'est pas
   ça du tout »). L'Échelle est une colonne d'ORIENTATION : une ligne par bloc, des comptes, des
   renvois — elle tient dans 240 px parce qu'elle ne montre rien du contenu. Ici on dispose de
   toute la largeur et l'on vient voir LA FICHE ENTIÈRE : les blocs sont donc des CARTES empilées,
   avec leurs items, dans l'ordre du parcours, imbrication comprise.
   LES CASES SONT DESSINÉES ET INERTES, et c'est un écart assumé à la doctrine « jamais de cases
   dans le plan » : ici la vue N'EST PAS un plan mais la fiche elle-même, montrée d'un bloc. Une
   étape sans sa case ne ressemblerait pas à ce qu'on lira en soin, et c'est précisément ce que la
   vue existe pour montrer. L'inertie est portée par l'ABSENCE de `data-ck` — aucun geste n'est
   possible, ni au doigt ni au clavier (les cases sont `aria-hidden`), et le sous-titre le DIT en
   toutes lettres : « rien ne s'y coche ».
   ELLE NE DÉMARRE RIEN et ne coche rien : mêmes invariants que le plan, vérifiés par harnais. */
/* LA PAGE D'AVANT LE SOIN (v5.6, maquettes 1b/1c) : le parcours INERTE, puis les autres vues en
   liens de TEXTE. Ni tuiles ni cartes : la maquette les met en liens parce que ce sont des
   ouvertures secondaires — l'action de l'écran est dans le dock, et rien ne doit lui disputer sa
   saillance. Chaque lien passe par le VRAI chemin (le même que le menu ⋯ et le dock), il n'y a
   pas de second point d'entrée. */
/* « CE QUI DÉMARRERA · n » (7c) — information de DÉCISION, jamais d'action : on lit ce que le
   tap va mettre en route avant de le taper. Le chrono de session en tête (il démarre toujours),
   puis chaque minuteur avec sa nature — un cycle dit sa période, un chronomètre dit qu'il compte.
   AUCUN CONTRÔLE ICI : rien ne s'arme avant le démarrage. */
/* ═══ Q4 — CE QUE LA FICHE EMBARQUE, AVANT QU'ON ENTRE (v5.7) ══════════════════════════
   MESURÉ : `preStartHtml` (« Ce qui démarrera ») ne se rend que dans le RAIL, donc à partir de
   780 px ; en voie ÉTROITE le panneau n'existe que dans le volet du quai, qui exige une session
   vive (v5.4.2), et la capsule n'existe pas non plus avant le premier geste. Sur la cible
   PRINCIPALE déclarée, un minuteur à cycles de 2 min écrit par l'auteur était donc totalement
   invisible tant qu'on n'avait pas démarré — et le néophyte chronométrait de tête, ce que
   l'aide existait pour éviter.
   Une LIGNE dérivée, pas une seconde copie du détail : le rail garde sa liste, l'étroit reçoit
   le compte. Rien à dire (ni minuteur, ni compteur, ni complication) → aucune ligne : un
   panneau qui affirmerait « 0 minuteur » serait le bruit que ce dossier refuse partout.
   PURE : aucun champ nouveau, aucune migration — c'est du comptage de ce que la fiche déclare. */
/* ═══ P7 — « RÉVISÉE DEPUIS VOTRE DERNIER PASSAGE » (v5.7) ═════════════════════════════
   `aidRev` existe depuis le lot T1 : chaque session archive la révision de l'aide sur laquelle
   le soin a été CONDUIT (et `aidRev` EST `updatedAt`, donc les points de version portent le
   même horodatage — la version exacte se retrouve). Elle ne servait qu'au compte rendu.
   Or dans une bibliothèque PARTAGÉE, un collègue révise une aide qu'on croit connaître par
   cœur, et l'on déroule de mémoire. La ligne le dit — AVANT le geste d'entrée, jamais pendant
   le soin (la rangée de méta est déjà masquée en session depuis la v4.31.0).
   · ELLE NE CONDITIONNE RIEN : « Confirmé — démarrer la session » ne bouge pas d'un pixel.
   · ELLE NE DIT PAS CE QUI A CHANGÉ — le dire exigerait de rendre un diff clinique à l'écran,
     donc de résumer une modification de dose. « Versions » est dans le menu ⋯ pour cela.
   · ET RIEN SUR UNE AIDE JAMAIS DÉROULÉE : il n'y a alors pas de « dernier passage », et
     « révisée » serait du bruit. PURE : elle ne lit que ce qu'on lui passe. */
```

## J170 — LES DEUX (OU TROIS) FAÇONS DE REGARDER LA FICHE AVANT DE LA DÉROULER — v5.6, demande de

```
/* LES DEUX (OU TROIS) FAÇONS DE REGARDER LA FICHE AVANT DE LA DÉROULER — v5.6, demande de
   l'auteur : « remonte les boutons tableau et schéma au-dessus de prise en charge et rends-les
   plus visibles ». Ils vivaient DANS le corps de l'étage, sous son titre, en liens de texte : on
   les lisait comme une note de bas de section alors qu'ils ouvrent la fiche entière.
   Ce sont des EXCURSIONS, pas des réglages — chacune s'ouvre en feuille plein écran et se referme
   par son ✕, Échap ou le retour système : la page d'entrée reste dessous, intacte. C'est ce qui
   les distingue de l'axe de densité du dock, qui remplace la vue de travail et porte son retour
   dans le chrome (lot A). */
/* ══ « PRÊT » SE DIT SUR LA FICHE, PAS SUR L'ACCUEIL (v5.6, planche 11a) ═══════════════════════
   La jauge `#attOffline` dit sur l'ACCUEIL que des documents manquent, alors que la question se
   pose sur la FICHE qu'on est en train d'ouvrir : c'est le test du LIEU, pris en défaut par une
   information juste mais au mauvais endroit — on l'apprend en perdant le réseau.
   ⚠ ELLE NE CONDITIONNE RIEN : « Confirmé — démarrer » reste actif avec des pièces manquantes. Un
   soin ne s'arrête pas parce qu'un PDF n'est pas là ; le manque est une INFORMATION, jamais une
   condition. Pas de bandeau, pas de fenêtre, pas de pastille : une phrase.
   ⚠ ET LA MOITIÉ « RÉVISION » DE LA PLANCHE N'EST PAS REPRISE : elle la croyait absente de la page
   d'entrée, or la rangée de méta y porte déjà « Validation : 01/2025 » (elle n'est masquée qu'EN
   SESSION, v4.31.0). L'y écrire une seconde fois serait la duplication que § 5.5 proscrit.
   Le compte est ASYNCHRONE (lecture IndexedDB) : la ligne naît `hidden` et se remplit après —
   même mécanique que `#attOffline`, et rien ne dépend d'elle. */
```

## J171 — ══ « PARCOURS » EST LA SÉQUENCE, « PAGE » EST LE CONTENU (v5.6, maquette — demande

```
  /* ══ « PARCOURS » EST LA SÉQUENCE, « PAGE » EST LE CONTENU (v5.6, maquette — demande
     utilisateur : « mets à jour parcours dans tout voir pour que ça corresponde au nouveau
     design ») ═══════════════════════════════════════════════════════════════════════════════
     La v5.0.0/M10 en faisait une pile de CARTES portant tous les items, au motif qu'on y dispose
     de la largeur. Le résultat mesuré est que les deux onglets du même cran disaient la même
     chose : « Parcours » et « Page » montraient l'un et l'autre chaque étape de chaque bloc, dans
     deux mises en page. Deux vocabulaires pour une même idée, ce qu'AC 120-71B §5.5 proscrit.
     La maquette tranche, et la division devient nette : PARCOURS = où l'on en est dans la
     séquence (une rangée par bloc, l'état dans la marque, les renvois à droite) ; PAGE = tout le
     contenu (le tableau statique, qui ne bouge pas).
     UNE SEULE EXCEPTION, ET C'EST CELLE DE LA MAQUETTE : le bloc COURANT montre ses items. On
     vient précisément vérifier « où j'en suis » — la rangée qui répond à la question a le droit
     de la développer, les autres n'ont rien à dire de plus que leur compte.
     « QUAND L'UTILISER » RESTE (lot M6) : c'est la condition d'entrée QRH, et c'est le seul
     endroit du cran qui la porte. La maquette ne la montre pas ; l'y garder ne coûte qu'une carte
     et retirer une condition d'entrée d'une vue « toute la fiche » serait une perte sèche.
     TOUT Y EST INERTE (doctrine du plan, re-confirmée cinq fois) : aucun `data-ck`. */
```

## J172 — LOT T8 — « TOUTE LA FICHE » EST UN CRAN DE DENSITÉ, ET IL SE REGARDE DE TROIS FAÇONS.

```
  /* LOT T8 — « TOUTE LA FICHE » EST UN CRAN DE DENSITÉ, ET IL SE REGARDE DE TROIS FAÇONS.
     Ce ne sont PAS trois vues nouvelles : ce sont les trois rendus que le dépôt possède déjà,
     rassemblés sous le cran qui les concerne tous les trois — la PAGE (le tableau statique), le
     PARCOURS (l'Échelle, qui vivait derrière le bouton « Se repérer » de la rangée de commandes)
     et le SCHÉMA (`buildFlowSVG`, qui vivait dans le menu ⋯). Aucun n'est réécrit : c'est une
     contrainte du plan, pas une préférence — réécrire le générateur SVG reperdrait les flèches
     mesurées, la contre-inversion sombre, le cache de géométrie et la navigation par nœud.
     LA PAGE RESTE LE DÉFAUT, DÉLIBÉRÉMENT : c'est ce que ce cran affiche aujourd'hui, et un lot
     qui AJOUTE deux façons de regarder n'a pas à changer par surprise ce que voit celui qui n'a
     rien demandé. L'onglet n'est pas persisté (même règle que l'ancien sélecteur de vue du plan) :
     c'est une consultation, pas un réglage. */
```

## J173 — ⚠ LOT B — CHERCHER DANS L'AIDE, PENDANT LE SOIN (retour d'usage : « difficile de trouver la

```
    /* ⚠ LOT B — CHERCHER DANS L'AIDE, PENDANT LE SOIN (retour d'usage : « difficile de trouver la
       bonne information en mode guidé parfois » — c'est CE besoin qui faisait basculer de format,
       et le format n'y répondait qu'en montrant tout d'un coup). C'est le composant de la lecture
       de référence, à racine variable : aucun second parseur, aucun second surlignage.
       TROIS GARDE-FOUS, tous repris de la version référence et tous nécessaires ici :
       · ELLE NE FILTRE PAS — elle surligne et saute. Masquer laisserait croire que le reste
         n'existe pas, et dans une aide de crise c'est le pire mode de défaillance possible ;
       · ELLE NE PASSE JAMAIS PAR `innerHTML` — le surlignage parcourt les NŒUDS DE TEXTE et
         n'insère que des nœuds créés (règle 4 : `esc()` est la seule barrière anti-XSS, on ne
         rouvre pas une seconde occasion de se tromper) ;
       · ELLE N'EST PAS LE CHEMIN OBLIGÉ — taper avec des gants sous adrénaline n'est pas fiable.
         C'est un accélérateur pour qui SAIT ce qu'il cherche ; la vue d'ensemble reste entière
         au-dessous, et ne pas s'en servir ne coûte rien.
       PAS SUR LE SCHÉMA : ses textes vivent dans un SVG, où un `<mark>` n'est pas un nœud valide —
       on abîmerait le dessin pour surligner un mot. L'onglet le dit en n'offrant pas le champ,
       plutôt qu'en offrant un champ qui ne trouve rien. */
```

## J174 — Sections de la fiche EN CELLULES du tableau statique (v4.14.0, maquette validée) :

```
// Sections de la fiche EN CELLULES du tableau statique (v4.14.0, maquette validée) :
// confirmation + différentiels côte à côte, chapeau « Ne pas oublier » pleine largeur en
// tête ; surveillances (À vérifier) en pied. Cellules INERTES (pas de data-svgo — ce sont
// des repères de lecture, pas des blocs de l'algorithme).
// Bouton de démarrage de session — partagé entre le parcours (dynamique) et le tableau
// statique, où il vit SOUS Confirmation/Éliminer (v4.14.2, condition d'entrée QRH).
/* ═══ LE DÉMARRAGE DÉPOSE SUR LE HAUT DU PREMIER BLOC (v5.0.7, signalé à l'usage) ═════════════
   Presser « Confirmé — démarrer la session » fait DISPARAÎTRE ou RÉTRÉCIR tout ce qui est au-dessus
   du doigt — le chapeau se replie en une ligne (T3), la condition d'entrée se referme (acquittement
   par l'action), et l'étage « Prise en charge » remonte en tête (T5). Le défilement, lui, ne bougeait
   pas : on atterrissait donc AU MILIEU de la carte du bloc, titre et premières étapes AU-DESSUS du
   pli, au moment précis où l'on commence le soin.
   MESURÉ sur une fiche à condition d'entrée longue (8 critères — le cas pour lequel `.sess-start.afloat`
   existe : on défile pour les lire, le bouton suit) : après le clic, le haut de la carte tombait à
   −206 px à 320 × 640 (324 px au-dessus des couches collantes) et à +20 px à 390 × 844, soit 98 px
   SOUS l'en-tête collant — dans les deux cas le numéro du bloc, son titre et « Vous êtes ici »
   étaient invisibles.
   CE N'EST PAS UN DÉFILEMENT AUTOMATIQUE (règle 11) : la règle vise l'écran qui bouge sous quelqu'un
   qui n'a rien demandé. Ici la page vient d'être rendue de neuf et le geste est une navigation
   DEMANDÉE d'un tap — même arbitrage que `landOnBout` à la réentrée et que `cxEnter`. Et c'est
   littéralement `landOnBout` qu'on rappelle : à cet instant le « bout » du journal EST la carte du
   bloc de départ (un seul passage), donc aucune seconde mécanique d'atterrissage à faire diverger,
   et sa règle de visibilité s'applique telle quelle — carte déjà entièrement à l'écran, rien ne bouge.
   ⚠ CE CHEMIN EST CELUI DU BOUTON, JAMAIS CELUI DU COCHAGE : un démarrage IMPLICITE (cocher une
   étape, armer un minuteur) passe par `renderKeepAnchor` et doit continuer de ne pas déplacer d'un
   pixel l'élément touché (invariant ECAM v4.4.0, mesuré par `audit-doctrine`).
   ⚠ ET CE N'EST PAS LA RÈGLE DE VISIBILITÉ DE `landOnBout`, QUI A ÉTÉ ESSAYÉE ET MESURÉE FAUSSE
   ICI : elle exige la carte ENTIÈRE à l'écran, or une carte de bloc dépasse presque toujours le
   pli (615 px mesurés sur 640) — elle aurait donc défilé même quand le haut était DÉJÀ à sa
   place, y compris sur les fiches courtes où rien ne le demandait, et laissé la page décalée pour
   les gestes suivants (deux témoins de dépliant l'ont dit, à −51 px). Ce qu'on garantit est ce
   que l'usage demande, et rien de plus : LE HAUT de la carte sous les couches collantes. */
```

## J175 — ── LOT 3 · ÉCHELLE DE LA FEUILLE ────────────────────────────────────────────────────────────

```
/* ── LOT 3 · ÉCHELLE DE LA FEUILLE ────────────────────────────────────────────────────────────
   La feuille a une largeur d'AUTEUR fixe (`--sheet-w`), jamais un pourcentage : c'est ce qui en
   fait une PAGE — la géométrie ne dépend plus de l'écran, donc l'image est la même au chariot,
   sur le téléphone et sur le papier, et c'est cette image qui se mémorise. L'agrandissement est
   une TRANSFORMATION (`scale`), jamais un `zoom` CSS : celui-ci refait la mise en page au lieu de
   la transformer, et à petite échelle les tailles minimales de police des navigateurs mobiles
   reprennent la main — c'est-à-dire exactement ce qu'on cherchait à figer.
   ⚠ PAS DE PINCH ÉCRIT À LA MAIN : il exigerait `touch-action:none` sur le défileur, ce qui tue
   le défilement — et `touch-action` se résout à la contrainte la plus stricte de la chaîne
   d'ancêtres, un enfant ne peut pas la rendre (le fichier a déjà payé cette leçon). Le pinch du
   NAVIGATEUR marche par-dessus, gratuitement : le viewport de l'app ne l'interdit pas.
   ⚠ PAS D'ÉCHELLE CONTINUE : des pas discrets laissent le moteur re-tramer le texte proprement à
   chaque palier ; une échelle qui glisse fait travailler une image mise en cache, et c'est là que
   le texte « bave ».
   ⚠ L'AJUSTEMENT NE SE FAIT PAS TOUT SEUL À L'OUVERTURE, et c'est un arbitrage MESURÉ contre le
   brief : à 390 px, ajuster une feuille de 1130 px donne k ≈ 0,28 — donc TOUTE cible tapable de
   la vue tombe à moins de 13 px réels, dans un écran qu'on ouvre PENDANT un soin, et le harnais
   d'accessibilité que la recette exige de garder vert le dit aussitôt. La feuille s'ouvre donc à
   l'échelle 1 (géométrie d'auteur, défilement horizontal) et « ⤢ ajusté » est UN TAP. L'échelle
   n'est JAMAIS mémorisée : c'est une consultation, pas un réglage (même statut que `state.allTab`). */
```

## J176 — ══ LOT 2 · svGridPlan — PURE, SANS DOM, TESTABLE ISOLÉMENT

```
/* ══ LOT 2 · svGridPlan — PURE, SANS DOM, TESTABLE ISOLÉMENT ══════════════════════════════════
   Entrée : la fiche. Sortie : la liste des nœuds à placer sur UNE grille de 6 pistes. Ne lit
   AUCUN état de session (l'état est PEINT ensuite, comme dans le schéma SVG) et ne touche pas à
   `flowPlan` — elle le LIT.
   6 PISTES parce que c'est le plus petit nombre divisible par 2 ET par 3 : deux branches se
   partagent 3+3, trois branches 2+2+2, sans piste orpheline. TRONC SUR 4, centré : la piste libre
   de chaque côté n'est pas décorative — c'est elle que les branches viennent occuper, et c'est ce
   qui permet à une branche d'être plus large que le tronc dont elle descend.
   RÉPARTITION AU PRORATA DE LA HAUTEUR TOTALE de chaque branche, minimum 1 piste, reste à la plus
   haute (départage par l'index : deux appels donnent la même sortie).
   ⚠ UN ARBITRAGE ASSUMÉ CONTRE LE PSEUDO-CODE DU BRIEF, ET IL EST TRANCHÉ PAR LA MAQUETTE. Le
   brief décrit une répartition RECALCULÉE LIGNE PAR LIGNE, avec « si une seule branche est encore
   vivante, elle reprend la position de TRONC (4 pistes) ». Or sur la fiche de référence, la
   branche « réfractaire » reçoit 5 pistes et les GARDE sur toute sa hauteur alors que sa voisine
   est close dès la première ligne : la règle par ligne l'aurait RÉTRÉCIE de 5 à 4 en descendant,
   c'est-à-dire l'inverse de l'effet cherché. La répartition est donc faite UNE FOIS par décision
   — les colonnes d'une branche ne bougent pas d'une ligne à l'autre, ce qui est aussi la seule
   géométrie stable à lire — et la « reprise de largeur » vient d'où elle vient réellement : les
   branches d'une décision se partagent l'étendue ENTIÈRE de leur contexte, pas la part de leur
   parente. Vérifié sur la maquette : décision 8 → 5 + 1 pistes, bloc 9 sur 5 pistes contre 4 au
   tronc. Le reste de la maquette est reproduit au placement près.
   REPLI (brief : « en cas de doute, le rendu simple, jamais le rendu embrouillé ») : au-delà
   d'une branche par piste disponible, on n'émiette pas — les branches s'EMPILENT à pleine
   étendue, chacune sous son étiquette. Une colonne lisible vaut mieux qu'un dessin illisible. */
```

## J177 — ══ CE QUE DEVIENT svPaintArrows (v5.10.0, lot Page)

```
/* ══ CE QUE DEVIENT svPaintArrows (v5.10.0, lot Page) ════════════════════════════════════════
   Il n'a plus ni fourche ni convergence à peindre : la FOURCHE est en divs, dans la grille (ses
   bras se posent en pourcentage de l'étendue, donc justes sans qu'on mesure quoi que ce soit), et
   la CONVERGENCE est redevenue ce qu'elle n'aurait jamais dû cesser d'être — une pilule « → n »,
   c'est-à-dire du texte, qui survit à l'impression et au lecteur d'écran. Ne lui restent que les
   RETOURS ↺ en gouttière, son cas le mieux tenu, et il y gagne : une boucle enjambe désormais une
   grille RÉGULIÈRE au lieu d'un empilement de conteneurs.
   Il porte en plus le CALANT de l'échelle (lot 3), parce que c'est la même passe : une mesure
   après rendu, groupée, jamais pendant un geste.
   ⚠ LES MESURES SE DIVISENT PAR `zoomF()` ET PAR L'ÉCHELLE DE LA FEUILLE : `getBoundingClientRect`
   rend des px VISUELS (× le zoom de l'app × le `scale` de la feuille) alors que le tracé se pose
   en px CSS dans le repère du DOCUMENT. Oublier le second terme donnerait une gouttière juste à
   l'échelle 1 et fausse partout ailleurs — le pire des deux mondes, puisqu'elle aurait l'air de
   marcher.
   ⚠ ET LA SUPERPOSITION VIT DANS LA FEUILLE, pas dans `.sv-wrap` : la feuille défile et se met à
   l'échelle, un calque resté dehors se décalerait au premier geste de zoom.
   ÉPITAPHES — PURGÉS avec la mécanique qu'ils servaient (règle 14, émissions vérifiées au grep) :
   `.sv-decwrap`, `.sv-cols`, `.sv-br`, `.sv-fork`, `.sv-merge`, `.sv-tb` (les conteneurs
   imbriqués), et `svStickBands` avec les bandes-questions COLLANTES. Ces dernières étaient
   protégées par les interdits du brief, et il faut dire pourquoi elles partent : elles existaient
   pour un cas — la branche EMPILÉE sous 640 px, où la question sortait de l'écran pendant qu'on
   lisait ses étapes (844 px de contenu mesurés sans elle en v4.13.1). Le lot 3 supprime
   l'empilement : sous 640 px la feuille ne se reflue plus, elle garde sa géométrie et c'est
   l'échelle qui s'adapte. Il n'y a donc plus de branche empilée, plus de question qui s'échappe,
   et plus de pile de décalages à mesurer — la cause est partie, le mécanisme la suit. */
```

## J178 — F2 (v5.7, volet 3) — LE PLAN DE VOL, DANS LE MONITEUR ET NULLE PART AILLEURS

```
/* ═══ F2 (v5.7, volet 3) — LE PLAN DE VOL, DANS LE MONITEUR ET NULLE PART AILLEURS ═══════
   La bande a été REFUSÉE sur le chrome de crise après mesure : ses quatre bénéfices y tombaient
   un par un (la collision est théorique sur des cadences 2/4 min que l'équipe enchaîne ; l'angle
   mort du minuteur en pause est un défaut de la CAPSULE, réparable pour zéro pixel ; le passé est
   déjà porté par le journal et par « il y a »). Ne restait que la simultanéité — cas rare — pour
   52 px permanents dans une colonne dont le budget de chrome est tenu à 30 % par un harnais.
   ICI, elle gagne tout : l'écran ENTIER est un afficheur, les pixels sont gratuits, on regarde à
   deux mètres, et une bande de temps est exactement la bonne forme. C'est un objet de MONITEUR,
   pas un objet de chrome.
   ⚠ TROIS REGISTRES DE TRAIT, ET ILS PORTENT TOUT LE SENS : un point derrière la ligne de vie =
   C'EST ARRIVÉ (horodatage) ; un trait plein devant = C'EST DATÉ (un minuteur qui TOURNE, dont
   l'échéance se calcule au milliseconde près) ; un tiret = C'EST PROJETÉ, si rien n'est touché
   (les tours suivants d'un cyclique). On ne peut pas confondre un fait avec une promesse, et
   c'est la seule chose que cette bande doit garantir.
   ⚠ CE QUI N'A PAS D'HEURE N'A PAS DE POSITION : un minuteur en PAUSE (il a un reste, pas une
   date), un échu non acquitté (il est passé), un chronomètre (il ne finit jamais). Ils vivent
   dans une rangée « sans heure », sous l'axe — et c'est justement l'information.
   ⚠ ET UN JALON COMPTÉ N'Y ENTRE JAMAIS, même quand un minuteur cadence les passages : dater le
   3ᵉ choc reviendrait à prédire le rythme auquel L'ÉQUIPE va agir. Sa progression reste sur la
   carte du bloc. (Le porter dans la rangée « sans heure » reste possible — il n'est pas fait.) */
```

## J179 — COMBIEN DE RANGÉES LA HAUTEUR PERMET (v5.17.1). Une rangée par échéance règle la collision

```
/* COMBIEN DE RANGÉES LA HAUTEUR PERMET (v5.17.1). Une rangée par échéance règle la collision
   HORIZONTALE, mais elle en ouvrait une VERTICALE : la bande est `flex:none` au-dessus d'un
   `.mon-main` qui, lui, cède — à quatre rangées sur un téléphone COUCHÉ, le grand chiffre,
   objet primaire de l'afficheur, se faisait recouvrir de 44 px (mesuré à 844×390 ; 54 px à
   667×375). Le correctif d'un défaut ne doit pas en poser un autre, et surtout pas sur ce qui
   compte le plus à deux mètres.
   ON NE DEVINE DONC PAS UN PALIER DE HAUTEUR, ON MESURE LA PLACE QUI RESTE : hauteur de la
   surface, moins l'en-tête, moins le pied, moins ce que le contenu de `.mon-main` VEUT.
   ⚠ ON ADDITIONNE LES ENFANTS DE `.mon-main`, ON NE LIT PAS SON `scrollHeight` — c'était ma
   première écriture, et elle était FAUSSE : `.mon-main` est `flex:1`, donc ÉTIRÉ, et le
   `scrollHeight` d'un conteneur étiré vaut sa BOÎTE, pas son contenu. La place libre s'effondrait
   et la bande tombait à deux rangées là où il y avait de quoi en tenir quatre (mesuré : 390×844,
   2 rangées pour six minuteurs alors que 534 px restaient). La hauteur VOULUE par le contenu,
   c'est la somme de ses enfants plus les écarts — elle, ne dépend pas de la bande, donc aucune
   boucle (la bande décide de la place de main, main déciderait de celle de la bande).
   ⚠ TOUT EN `offset/clientHeight`, JAMAIS EN `getBoundingClientRect` : sous le réglage de taille
   du texte (`zoom` sur `<html>`), le premier rend des pixels de MISE EN PAGE et le second des
   pixels PEINTS. Mélanger les deux comparerait deux unités (règle 10).
   LE CHROME SE CALCULE SUR LES DONNÉES, pas sur une constante : la rangée « sans heure » et les
   deux lignes de pied (légende des tours projetés, « + n plus tard ») coûtent des pixels bien
   réels — les oublier laissait 10 à 26 px de recouvrement résiduel sur trois cas mesurés. Les
   deux lignes de pied sont réservées dès qu'elles PEUVENT paraître : leur présence dépend du
   nombre de rangées retenues, donc d'une valeur qu'on est en train de calculer. Majorer est la
   seule sortie non circulaire, et elle tombe du bon côté — au pire une rangée de moins, jamais un
   recouvrement. Le cap qui en découle n'est jamais silencieux : `.mb-plus` le dit. */
```

## J180 — ⚠ UNE ÉCHÉANCE PAR RANGÉE (v5.17.1, signalé à l'usage : « lorsque plusieurs minuteurs,

```
   /* ⚠ UNE ÉCHÉANCE PAR RANGÉE (v5.17.1, signalé à l'usage : « lorsque plusieurs minuteurs,
      timeline ne s'affichent plus »). Les étiquettes vivaient TOUTES au même `top:8px` sur une
      ligne unique : à quatre minuteurs, mesuré à 390 px, quatre chevauchements deux à deux et
      DEUX étiquettes entièrement hors de l'écran (bords droits à 408 et 438 px pour 390
      disponibles). Sur un afficheur qu'on lit à deux mètres, c'était une bouillie — les minuteurs
      « ne s'affichaient plus » au sens propre.
      Une rangée par échéance, sur le MÊME axe : deux marques alignées verticalement se lisent
      alors comme une simultanéité, ce que la bande existe précisément pour montrer. La ligne de
      « maintenant » traverse toutes les rangées, c'est elle qui les tient ensemble.
      ⚠ ET L'ÉTIQUETTE BASCULE À GAUCHE DE SA MARQUE PASSÉ LA MOITIÉ DE L'AXE : elle grandit
      toujours VERS LE CENTRE, donc elle ne peut plus sortir de la bande. Un libellé est borné à
      18 signes (~115 px à 12 px gras) contre 142 px de demi-bande à 320 px, le plus étroit servi :
      la garantie est arithmétique, pas espérée. */
```

## J181 — Editor

```
/* ===== Editor =====
   Briques de formulaire qui produisent du HTML :
     listEditor()      : éditeur d'une liste simple (confirmation, vérifier, etc.),
       avec ajout/suppression et réordonnancement optionnel.
     targetSelect()    : menu déroulant "bloc cible" (pour next / options).
     imageEditor()     : ajout/retrait d'une image attachée à un bloc.
     blockEditor()     : éditeur d'un bloc 'steps' ou 'decision'.
     timerEditorRow()  : ligne d'édition d'un minuteur (libellé ; pour 'interval'
       : minutes/secondes + case "boucle").
     counterEditorRow(): ligne d'édition d'un compteur (libellé, pas, départ).
   renderEditor() : assemble le formulaire complet à partir de state.draft, INCLUT
     l'aperçu d'algorithme (re-dessiné à chaque rendu), puis rattache tous les
     écouteurs. Les modifications mutent directement state.draft ; un re-rendu n'a
     lieu que pour les changements structurels (ajout/suppression/réordre/typage).
   bindListEditors() : écouteurs communs aux listes simples.
   downscale()       : réduit une image (canvas) avant stockage base64.
   edCommit()        : normalise une COPIE du brouillon et la publie (K5, v4.72.0 — il n'y a
                       plus de bouton « Enregistrer » : cf. le bloc K5 plus bas).
   deleteDraft()     : supprime la fiche ET ses sessions associées. */
// opts.crit (v4.3.0, repères posologiques) : bascule par BOUTON (le signe est intapable au
// clavier) — le champ affiche le texte NU, la rangée encadrée porte le registre, le préfixe reste
// dans la CHAÎNE stockée (format v3 inchangé).
// v4.23.0 : ce registre est la VIGILANCE (« △ », ambre), plus l'ALERTE — un dosage est une
// RÉFÉRENCE où l'on risque de se tromper, pas un geste dont l'oubli tue (doctrine v4.2.2). La
// rangée, le bouton et la carte de lecture portent donc tous les trois l'ambre. Un « ⚠ » hérité
// d'une fiche antérieure est encore RECONNU (stepIsCrit||stepIsVigil) et affiché en ambre :
// aucune migration de données, aucun contenu perdu.
/* K1 : `opts.shell` habille la liste de la coquille de LECTURE correspondante (le chapeau prend
   le cadre rouge de `.forget-strip`) ; `opts.guard` y loge le garde-fou, qui vivait jusqu'ici en
   paragraphe SOUS le champ — donc hors du cadre qu'il commente. */
/* ⚠ UNE SEULE LISTE, DEUX NATURES DE RANGÉE (v5.0.0, signalé à l'usage : « uniformise avec les
   blocs ne pas oublier du dessus — ex. input grisé du même style »). Le chapeau montrait deux
   objets qui n'avaient rien en commun : des champs, puis des lignes de texte d'un autre dessin,
   reléguées en bas. Ce sont pourtant les mêmes rappels, et ils s'affichent côte à côte en lecture.
   La rangée est donc la MÊME — poignée, champ, ×2 rien —, et ce qui change est ce que le champ
   AUTORISE : une ligne portée par une étape est un champ DÉSACTIVÉ, dans la grammaire de « fermé »
   du dossier (`:disabled`, cf. v4.79.0), suivi du renvoi vers le bloc où elle se modifie. On ne
   duplique pas le lieu d'écriture : le chapeau AGRÈGE, il ne possède pas.
   L'ORDRE EST CELUI DU POOL, donc les deux familles s'entrelacent — et la poignée déplace l'un
   comme l'autre, puisque déplacer, ici, c'est déplacer une entrée du pool. */
```

## J182 — K2 (v4.63.0, audit design — phase K) : LA RELECTURE DOCTRINALE, EN MARGE ET NON BLOQUANTE

```
/* ═══ K2 (v4.63.0, audit design — phase K) : LA RELECTURE DOCTRINALE, EN MARGE ET NON BLOQUANTE
   L'éditeur est l'envers de la crise : on y travaille AU CALME, et chaque minute investie ici
   achète des secondes là-bas. Les garde-fous existaient déjà — mais dispersés, chacun sous son
   champ, sans vue d'ensemble : l'auteur ne savait pas, en fermant, ce qu'il laissait derrière lui.
   `reviewNotes` les rassemble en UNE grammaire « △ Relecture » : chaque remarque nomme sa CIBLE
   (le chapeau, un bloc) et dit l'action proposée. PURE, testée.
   JAMAIS BLOQUANT, JAMAIS ROUGE : l'ambre est le registre du « c'est là qu'on se trompe » ; le
   rouge reste à ce qui tue. Un auteur qui veut publier une fiche imparfaite le peut — c'est lui
   l'expert de son service, pas l'application. */
/* Le volet-bilan : ce que la doctrine a relevé, en pied de page, avec l'ANCRAGE vers la ligne
   concernée. Il DISPARAÎT quand il n'y a rien à dire — un panneau vide qui affirme « 0 remarque »
   est du bruit permanent pour une information qu'on lit une fois. */
```

## J183 — ANCRAGE : taper une remarque amène à la ligne concernée et la FAIT CLIGNOTER une fois. On ne

```
/* ANCRAGE : taper une remarque amène à la ligne concernée et la FAIT CLIGNOTER une fois. On ne
   met PAS le focus dans le champ — l'auteur vient de LIRE le bilan, il choisit ce qu'il corrige ;
   voler le curseur déciderait à sa place. */
/* ═══ Q1 — LA RELECTURE DEVIENT FORCE DE PROPOSITION (v5.7) ═══════════════════════════════
   VÉRIFIÉ AVANT D'ÉCRIRE : les six détections de `reviewNotes`/`reviewNotesProto` sont TOUTES
   des manques — titre absent, « à compléter » résiduel, aucune source, chapeau trop long, bloc de
   plus de sept étapes, challenge trop long. Aucune ne disait jamais « votre texte décrit un
   cycle : voulez-vous le minuteur qui va avec ? »
   Or c'est là que tout se joue pour un néophyte-auteur : il écrit « renouveler toutes les 3 min »
   EN TEXTE et n'apprendra jamais que l'application sait armer un minuteur à cycles, poser un
   compteur ou marquer un memory item. La fiche qu'il publie n'emploie alors qu'une part du
   produit — et c'est EN CRISE que la différence se paie.
   · **LE NOMBRE VIENT DE SA PHRASE, JAMAIS D'UN BARÈME.** C'est de la lecture de texte, à froid,
     dans l'éditeur — hors de toute session, hors de tout patient. Aucun seuil clinique n'est
     inventé : c'est l'interdit que le prompt IA porte déjà (et qu'`audit-prompt` vérifie).
   · **RIEN N'EST CRÉÉ AUTOMATIQUEMENT.** Jamais. Une proposition est une rangée avec un bouton ;
     l'auteur reste l'expert de sa fiche, et son texte n'est PAS réécrit — l'objet s'ajoute, la
     phrase reste.
   · **LA PROPOSITION N'INVENTE PAS DE NOM** (A85, A99) : le compteur naît SANS libellé, et c'est
     le ✎ de sa carte qui le nomme. Deviner un mot à partir d'une phrase serait la dégénérescence
     de « PA 2 » sous un autre visage.
   · **UNE PROPOSITION REFUSÉE NE REVIENT PAS** de la séance : le refus vit dans `state.edOffNo`,
     transitoire comme `state.edGrab` — c'est un geste, pas un état du brouillon, et le graver
     dans le modèle ajouterait un champ pour mémoriser un NON.
   · **ET ELLE DISPARAÎT D'ELLE-MÊME QUAND ELLE EST SUIVIE** : les trois détecteurs se taisent dès
     que l'objet existe. Aucun drapeau à tenir. */
```

## J184 — K2, deuxième moitié (v4.68.0, maquette MK) : LA REMARQUE SOUS LA LIGNE QU'ELLE VISE. Le volet

```
/* K2, deuxième moitié (v4.68.0, maquette MK) : LA REMARQUE SOUS LA LIGNE QU'ELLE VISE. Le volet
   en pied dit COMBIEN il reste à relire ; il ne dit pas OÙ pendant qu'on écrit. `stepNote` rend
   la remarque qui concerne UNE étape — affichée sous elle, et seulement quand elle est en
   ÉDITION : au repos, la page reste du texte (état 1 de MK-flux). PURE, testée. */
/* ═══ K10 (v4.69.0) — LES RACCOURCIS À LA FRAPPE, PAS UN ÉDITEUR MARKDOWN ═══════════════════
   Un éditeur markdown LIBRE casserait la grammaire (registres, télégraphique, une action par
   ligne) : refusé. En revanche, la VITESSE du texte n'a aucune raison d'être perdue — on tape
   « ! » en tête de ligne et l'étape devient critique, « ? » et elle passe en vigilance. Le
   préfixe est CONSOMMÉ (il ne reste pas dans le texte) et le registre se pose sur le MODÈLE,
   là où il vit déjà : la chaîne stockée garde « ⚠ »/« △ », l'export v3 est inchangé.
   `stepShortcut` est PURE (testée) : elle rend le nouvel état d'une étape après frappe, ou null
   si rien ne s'applique. Deux caractères seulement, et seulement EN TÊTE : un « ? » au milieu
   d'une question (« Choquable ? ») n'est pas un raccourci, et l'oublier transformerait le texte
   d'un auteur sans qu'il comprenne pourquoi. */
```

## J185 — GARDE-FOU QRH : une étape ⚠ tirée hors de son bloc CHANGE de contexte — un memory item n'a de

```
/* GARDE-FOU QRH : une étape ⚠ tirée hors de son bloc CHANGE de contexte — un memory item n'a de
   sens que dans la séquence qui le porte. On l'ANNONCE avant le dépôt (△ sur la cible), on ne
   l'interdit pas : l'auteur reste l'expert de sa fiche. */
/* ═══ K3 / K8 / K9 (v4.65.0, maquette MK4) — LA PORTE « + » : UNE SEULE, TOUT PASSE PAR ELLE ══
   Six boutons d'ajout vivaient dispersés dans trois fieldsets (« + Bloc d'étapes », « + Décision
   (si… alors…) », « + Chronomètre », « + Minuteur (cycle) », « + Ajouter un compteur »,
   « ＋ Complication ») : pour savoir ce qu'on POUVAIT ajouter, il fallait faire défiler la page
   entière, et rien ne disait à quoi chaque type sert. Une seule porte les rassemble, et CHAQUE
   TYPE SE PRÉSENTE — le glyphe, le nom, et UNE ligne dans les mots du soignant.
   C'EST LÀ QUE LES REGISTRES S'APPRENNENT, AVANT LA CRISE : « ⚠ ce qui TUE si on l'oublie » et
   « △ là où l'on se TROMPE » sont écrits noir sur blanc au moment où l'auteur choisit — pas dans
   un guide qu'on replie. La palette est un dialogue ordinaire (`confirmDlg` n'irait pas : ce
   n'est pas une confirmation), fermée par Échap et le voile comme toutes les fenêtres. */
/* UN « + » = UNE PORTÉE (MK-flux, état 4). La palette ne vit qu'ENTRE les blocs et ne liste que
   les objets de NIVEAU BLOC : « Étape » n'y figure PAS — dans un bloc, « + Étape » (et ⏎) s'en
   charge. C'est la position du bouton qui choisit la portée, à la place de l'auteur : il n'a
   jamais à se demander « où va atterrir ce que j'ajoute ». Chaque type dit sa CONSÉQUENCE en
   deux mots, à droite — pas ce qu'il est, ce qu'il produit. */
/* v4.71.0 — LA PORTE ÉTAIT INCOMPLÈTE, DONC ELLE MENTAIT. Elle promet « voici tout ce que vous
   pouvez ajouter » ; il en manquait DEUX que la fiche accepte pourtant — le TABLEAU DE DOSES et
   le DOCUMENT (maquette MK4, qui les liste tous les deux). Une porte unique qui ne montre pas
   tout est pire que six portes dispersées : on cherchait avant, on renonce maintenant.
   CE QUI RESTE HORS DE LA PORTE, ET POURQUOI : « Étape », « Étape critique » et « Étape
   vigilance », que MK4 y range. Un « + » = une PORTÉE (MK-flux, état 4, décision retenue) — la
   palette ne vit qu'ENTRE les blocs, où une étape n'a pas de bloc d'accueil ; dans un bloc,
   « ＋ Étape » et ⏎ s'en chargent. L'INTENTION PÉDAGOGIQUE de MK4 (« les registres s'apprennent
   ici, avant la crise ») n'est pas perdue pour autant : elle vit dans le dépliant `.crit-guide`
   en tête de chaque bloc, c'est-à-dire à l'endroit exact où l'on choisit le registre. */
/* `_edImgMode` est PURGÉ (v5.0.0, règle 14). Ce drapeau de module existait parce qu'un seul
   `<input type="file">` servait plusieurs destinations et qu'il fallait, au retour de son
   `onchange`, se rappeler laquelle : galerie, bloc, ou protocole. La porte prend désormais un
   CALLBACK (`pickFile(kind, onFiles)`) — la destination voyage avec le geste au lieu d'être
   mémorisée à côté, et il n'y a plus d'état à remettre à zéro ni à oublier de remettre à zéro. */
/* ═══ LOT 3 (v4.76.0) — LA PORTE « ＋ » DEVIENT CELLE DE L'AIDE ENTIÈRE ════════════════════════
   Signalé à l'usage : « le bouton s'arrête avant les blocs minuteurs & compteurs, repères
   posologiques, schémas et captures, documents PDF… ce qui n'est pas logique ». Le constat était
   plus juste encore que sa formulation : la porte créait DÉJÀ des minuteurs, des compteurs, des
   complications et des repères posologiques, tout en vivant à l'INTÉRIEUR du fieldset « Prise en
   charge ». Ce n'était donc pas une porte de bloc, c'était la porte de l'aide, mal rangée. Elle
   sort du fieldset, passe à la fin du formulaire, et reste collante sur toute sa hauteur.
```

## J186 — On amène l'auteur SUR ce qu'il vient de créer : une porte qui demande un geste pour ouvrir

```
  /* On amène l'auteur SUR ce qu'il vient de créer : une porte qui demande un geste pour ouvrir
     et un autre pour retrouver son résultat n'a rien simplifié. Ancrage direct, jamais animé
     (`behavior:'smooth'` ne défilait pas du tout sur de grands écarts — mesuré en v4.63.0). */
  /* ON AMÈNE TOUJOURS SUR CE QU'ON VIENT DE CRÉER (v4.77.0, signalé à l'usage : « quand je clique
     sur ajouter une complication, rien ne se passe si le bloc est masqué »). Rien n'était masqué :
     la section réapparaît bien, mais elle est en bas d'un formulaire de plusieurs milliers de
     pixels, et seules les LISTES avaient droit à l'ancrage — un minuteur, un compteur, une
     complication ou un bloc naissaient hors de l'écran, donc « rien ne se passe ». Une porte qui
     demande un geste pour ouvrir et un autre pour retrouver son résultat n'a rien simplifié
     (v4.65.0) : la règle valait déjà, elle n'était appliquée qu'au quart. */
  /* MINUTEURS ET COMPTEURS PARTAGENT `.tmedit` DEPUIS LA v4.78.0 : viser la classe seule amenait au
     DERNIER `.tmedit` du formulaire, c'est-à-dire au dernier COMPTEUR (ils sont rendus après les
     minuteurs) — d'où « le scroll nous ramène en bas du bloc mais pas au bloc ajouté ». On
     distingue par l'attribut qui porte l'index : `data-ti` pour un minuteur, `data-ci` pour un
     compteur. Leçon : quand deux objets se mettent à partager une classe, tout sélecteur qui les
     visait « par la classe » devient ambigu — et l'ambiguïté ne se voit pas, elle se subit. */
  /* ⚠ ON ANCRE EN HAUT CE QUI A UNE TÊTE À SOI, ON CENTRE CE QUI N'EST QU'UNE LIGNE (v5.10.8,
     question de l'auteur : « le scroll peut-il afficher le début du bloc en haut de la page ?
     sinon peu visible »). `block:'center'` centre la BOÎTE dans la fenêtre, sans rien savoir des
     couches collantes : mesuré, un bloc d'étapes neuf fait 552 px et une décision 587 — sur une
     fenêtre de 844 le titre tombait à 181 px, donc 120 px de vide sous l'en-tête ; sur une fenêtre
     de 667 (iPhone SE, ou n'importe quel téléphone en paysage) le même calcul le pose à 40, c'est-
     à-dire DERRIÈRE l'en-tête collant, qui en fait 61. On ne voyait plus le titre de ce qu'on
     venait de créer — exactement ce qui est signalé, et le cas s'aggrave avec la hauteur de l'objet.
     `block:'start'` pose le HAUT de l'objet en haut de la zone utile, et rien à calculer : le
     `scroll-padding-top` global (`--stick-top + 8`, déjà divisé par le zoom) est honoré par le
     défilement natif — c'est la ligne posée pour WCAG 2.4.11, qui sert ici une seconde fois.
     ⚠ ET LES LISTES GARDENT LEUR CENTRAGE, ce n'est pas un oubli. Une dose, une vérification, un
     différentiel, une source : l'objet créé est UNE ligne de 44 px, et son sens vient du titre de
     section AU-DESSUS d'elle. L'ancrer en haut collerait la ligne sous l'en-tête et pousserait sa
     section hors de l'écran — on saurait où écrire sans savoir dans quoi. Un bloc, une carte de
     minuteur, une complication portent leur propre titre : eux n'ont besoin de rien au-dessus. */
```

## J187 — LA PORTE D'UNE RÉFÉRENCE (v5.0.0, refonte des protocoles). Même composant, même fenêtre, même

```
/* LA PORTE D'UNE RÉFÉRENCE (v5.0.0, refonte des protocoles). Même composant, même fenêtre, même
   grammaire que celle des aides — mais une AUTRE liste, parce qu'une référence n'a ni bloc, ni
   étape, ni minuteur : elle a un CORPS, des DOCUMENTS, des RENVOIS et des SOURCES. Proposer les
   types d'une checklist ici serait promettre ce qui n'existe pas.
   ET LA MÊME RÈGLE : « présent dans la porte ⇔ masqué quand vide ». Une section vide n'enseigne
   plus rien depuis que la porte présente les types disponibles ; elle se recrée par la porte, le
   focus dans le champ neuf. */
/* ⚠ MÊME REGISTRE D'ÉCRITURE QUE LA PORTE DES AIDES, ET C'EST CE QUI UNIFORMISE LA RANGÉE
   (signalé à l'usage). Le gabarit était déjà partagé, mais les gloses étaient des PHRASES là où
   celles des aides disent la CONSÉQUENCE en deux mots — elles enroulaient, et la rangée passait de
   52 à 56 px. Deux portes qui n'écrivent pas dans le même registre ne se ressemblent pas, quel que
   soit leur CSS. */
```

## J188 — LA PHASE VIT DANS L'EN-TÊTE DU BLOC, À DROITE (v5.0.0, maquette — et correction : ma première

```
/* LA PHASE VIT DANS L'EN-TÊTE DU BLOC, À DROITE (v5.0.0, maquette — et correction : ma première
   pose n'était que dans la branche DÉCISION, `replace(…,1)` ayant pris la première occurrence).
   Elle est FACULTATIVE et HÉRITÉE : le champ vide affiche en filigrane la phase héritée du bloc
   précédent, de sorte que l'auteur voit ce qui s'appliquera sans avoir à la retaper. Un `datalist`
   propose le noyau, sans jamais l'imposer. */
/* ⚠ UNE LISTE QU'ON CHOISIT, PAS UN MOT QU'ON RETAPE (demande utilisateur : « propose plutôt une
   liste par défaut éditable avec sélectionneur, avec rappel des blocs dans chaque phase »). Le
   champ libre demandait de RÉÉCRIRE le mot à l'identique d'un bloc à l'autre : une faute de frappe
   créait une phase jumelle, et rien ne le disait. Le sélecteur supprime la classe d'erreur entière.
   IL RESTE OUVERT — la décision de la v5.0.0 tient : rien n'établit que les cliniciens pensent en
   cinq phases fixes. « ＋ Nouvelle phase… » ouvre le champ de saisie, la valeur entre dans la
   liste, et une phase déjà écrite y figure même si elle n'est pas du noyau.
   LE RAPPEL VIT DANS LES INTITULÉS : chaque option dit combien de blocs la portent. C'est
   l'information qu'on cherche au moment où l'on choisit — « est-ce que cette phase existe déjà, et
   qu'y ai-je mis ? » — et elle ne coûte pas une surface de plus. */
/* ⚠ CE QUI EST HÉRITÉ EST LA PHASE DU BLOC PRÉCÉDENT, PAS L'EFFECTIVE. `phaseOf` rend la phase
   qui S'APPLIQUE, celle du bloc comprise — s'en servir ici faisait dire « hérite : Immédiate » au
   bloc qui DÉCLARE lui-même « Immédiate ». Ce que l'option vide doit annoncer, c'est ce qui
   arriverait si l'on ne déclarait rien. */
```

## J189 — LA COLONNE DE DROITE PORTE L'ALGORITHME, PLUS UNE MAQUETTE (demande utilisateur : « enlève

```
/* LA COLONNE DE DROITE PORTE L'ALGORITHME, PLUS UNE MAQUETTE (demande utilisateur : « enlève
   aperçu en direct — c'est déjà un aperçu en direct ; remplace par l'algorithme, aperçu
   automatique »). Le constat est exact et il découle de K1 : depuis la v4.64.0 la colonne du
   MILIEU est le rendu — le chapeau EST le cadre rouge, un bloc EST sa carte, une étape EST sa
   rangée. Une carte-maquette de trois étapes à côté n'ajoutait donc plus rien qu'une seconde
   version, forcément moins fidèle, de ce qu'on avait déjà sous les yeux.
   Ce qui, lui, ne se voit NULLE PART en écrivant, c'est la STRUCTURE que les blocs dessinent :
   le schéma. Il vivait au milieu, en tête de « Prise en charge », où il repoussait vers le bas
   le premier bloc à écrire ; il monte dans la colonne COLLANTE, où il reste sous les yeux
   pendant qu'on descend les blocs. Sous 1000 px, il reprend sa place dans le flux — inchangé.
   IL NE SE REDESSINE PAS À LA FRAPPE, et c'est le comportement d'AVANT, pas une régression :
   `buildFlowSVG` reconstruit toute la géométrie, et le faire à chaque pause de frappe ferait
   sauter le schéma sous les yeux. Il suit les gestes STRUCTURELS, qui re-rendent l'éditeur. */
```

## J190 — « SCHÉMAS & CAPTURES » EST UN AGRÉGATEUR (v4.78.0, signalé à l'usage)

```
/* ═══ « SCHÉMAS & CAPTURES » EST UN AGRÉGATEUR (v4.78.0, signalé à l'usage) ═══════════════════
   « Une image ajoutée depuis un bloc via + Image/Capture ne s'affiche pas dans le bloc schémas &
   captures, alors que l'inverse est vrai. » Exact, et c'était une asymétrie de MODÈLE : la galerie
   est `f.images[]`, l'image d'un bloc est `b.image` (la donnée elle-même), et « + Image » n'écrivait
   que la seconde. La galerie ne pouvait donc pas montrer ce qu'elle prétendait rassembler, et le
   sélecteur de bloc de la v4.76.0 n'avait rien à sélectionner.
   RÉCONCILIATION AU RENDU, pas au point d'ajout : elle rattrape aussi les fiches EXISTANTES, dont
   les images de bloc n'ont jamais eu d'entrée de galerie — sinon le correctif n'aurait valu que
   pour les images ajoutées après lui. Idempotente (on ne pousse que ce qui manque), purement
   ADDITIVE, et sans champ nouveau : l'export v3 garde exactement sa forme.
   Elle n'est PAS dans `migrate()` à dessein : `migrate` court sur toute donnée entrante, y compris
   un pull de synchro, et grossirait `images` sur des fiches qu'on ne fait que LIRE. Ici le geste est
   une ÉDITION — l'auteur a ouvert l'éditeur, l'écriture est déjà sa décision. */
```

## J191 — Export / Import

```
/* ===== Export / Import =====
   Export : télécharge un JSON { version, categories, fiches } (sessions exclues).
     exportData() est partagée : export GLOBAL (toutes fiches + toutes catégories,
     bouton du pied de page) et export d'UNE seule fiche (bouton dans la lecture,
     n'embarque que les catégories utilisées). Même enveloppe -> réimportable.
   Import : accepte le format objet (nouveau) ou un simple tableau de fiches
     (ancien) ; fonctionne pour une librairie entière comme pour une fiche seule.
     DESTINATION : Perso par défaut ; si une bibliothèque partagée éditable est
     sélectionnée à l'accueil, demande où importer (publier à l'équipe = jamais
     silencieux). Propose de FUSIONNER ou de REMPLACER (la destination seulement,
     et UNIQUEMENT si l'import contient plusieurs fiches) ; un import d'une seule
     fiche fusionne toujours. Ajoute les catégories manquantes au jeu de la
     bibliothèque de destination.
     DOUBLONS (même id, mode fusion) : demande une fois s'il faut remplacer la
     version existante ou importer en double ; sinon régénère l'id (copie).
     IDENTIFIANTS INTER-COMPTES : la clé primaire du cloud est GLOBALE (tous comptes) ->
     conserver l'id d'une fiche exportée par un AUTRE compte rendait son push impossible
     (refus RLS 403 permanent). L'export embarque donc une empreinte de l'espace d'origine
     (`origin`, non réversible — spaceTag) ; l'import ne conserve les ids que si le fichier
     vient du MÊME espace (vraie restauration/fusion multi-appareils). Fichier d'un autre
     espace, ou ancien fichier sans `origin` : ids régénérés (le push répare de toute façon
     une collision résiduelle, cf. Sync._push/reassignFicheId — ceinture et bretelles).
```

## J192 — Règles pour conserver la compatibilité au fil des mises à jour :

```
   Règles pour conserver la compatibilité au fil des mises à jour :
   1. Ne JAMAIS supprimer un champ existant du modèle fiche ou catégorie.
      Si un champ est abandonné, le laisser accepté en import (il sera ignoré).
   2. Tout nouveau champ OBLIGATOIRE doit être ajouté dans migrate() avec une
      valeur par défaut, de façon à ce que les fiches sans ce champ restent valides.
   3. Si la structure change de façon incompatible (ex. type ou sémantique d'un
      champ modifiée), incrémenter `version` dans exportData() ET adapter
      l'import pour détecter l'ancienne version et la convertir.
   4. migrate() est le point d'entrée unique de migration : elle est appelée à
      chaque lecture (getAll) et à chaque import. C'est là qu'on assure la
      compatibilité ascendante.
   5. Ne pas oublier de mettre à jour le commentaire MODÈLE DE DONNÉES en tête
      de fichier quand le schéma évolue, pour que les prochains lecteurs/IAs
      aient une vue exacte de la structure attendue. */
/* ----- ZIP maison (v4.5.0) : conteneur d'export « avec documents » -----
   Écriture au format ZIP standard en méthode STORE uniquement (les PDF sont déjà compressés :
   déflater ferait perdre du temps pour rien) ; lecture STORE + DEFLATE via DecompressionStream
   NATIF (un export dézippé puis re-zippé par macOS/Windows reste importable). Zéro dépendance,
   fonctions PURES (testées dans tests.html). Le CRC de chaque entrée est vérifié en lecture :
   une archive endommagée est rejetée d'un bloc (« Fichier illisible »), jamais importée à moitié. */
```

## J193 — Uint8Array -> Promise<[{name, data:Uint8Array}]>. Lit depuis le répertoire central (fin de

```
// Uint8Array -> Promise<[{name, data:Uint8Array}]>. Lit depuis le répertoire central (fin de
// fichier). BORNES ANTI-« ZIP BOMB », toutes nécessaires — un .zip est le format de partage d'une
// bibliothèque entre collègues : il circule par mail ou clé USB, sans aucun contrôle.
//   1. 1000 entrées max (n, plus bas) ;
//   2. 64 Mo par entrée, déclaré ET réel ;
//   3. 256 Mo CUMULÉS sur toute l'archive — la borne qui manquait : chaque entrée passait
//      individuellement, et rien ne bornait la somme ;
//   4. un même en-tête local ne peut être consommé qu'UNE fois — sans quoi N entrées de noms
//      distincts pointaient sur le MÊME flux compressé, ce qui multipliait le volume produit
//      sans grossir l'archive (PoC exécuté : 18 Ko -> 256 Mio en 16 entrées) ; `zipBuild`
//      n'en produit jamais, la contrainte est donc gratuite pour les exports de l'app ;
//   5. la décompression elle-même est BORNÉE (inflateBounded) : `usize` est lu DANS le fichier,
//      il peut mentir. La vérification `data.length!==usize` d'avant n'arrivait qu'APRÈS avoir
//      matérialisé les octets — la mémoire était déjà consommée quand on rejetait l'entrée.
```

## J194 — Les rangées SONT les objets qui seront écrits, pas une estimation faite à côté : on migre ICI,

```
/* Les rangées SONT les objets qui seront écrits, pas une estimation faite à côté : on migre ICI,
   une fois, et l'on repose l'objet migré dans `imp`. `migrate` est idempotent (il tourne à chaque
   chargement) — la boucle d'import le rejoue donc sans conséquence, et la règle 5 tient : le
   point d'assainissement reste unique, il est seulement atteint plus tôt. */
/* `dup` = cette entité EXISTE DÉJÀ chez moi, sous le même identifiant. La question n'a de sens
   que si les ids sont CONSERVÉS, c'est-à-dire en même espace : sinon ils sont régénérés à
   l'écriture et il ne peut pas y avoir de collision (cf. `sameSpace`). Le calcul est donc le
   MÊME prédicat que la boucle d'import — un second, écrit à côté, annoncerait des doublons que
   l'écriture ne verrait pas. */
/* ═══ A131 — « DÉJÀ PRÉSENT » NE SUFFIT PAS À DÉCIDER : LEQUEL DES DEUX EST LE PLUS RÉCENT ? ═══
   A130 fait annoncer la COLLISION par la rangée, sans dire ce que la question SUIVANTE demande
   pourtant de trancher — « remplacer » ou « garder les deux ». Or remplacer, quand le fichier est
   PLUS ANCIEN que ma version, écrase une révision locale par une copie périmée : en silence, et
   c'est exactement le genre de geste que l'atelier existe pour rendre visible.
   · ON N'INVENTE PAS DE NUMÉRO DE RÉVISION : `updatedAt` EST la révision — c'est déjà ce dont
     `aidRev` se sert pour dire sur quelle version un soin a été conduit (v5.0.0). Aucun champ
     nouveau, aucune migration, rien de plus à synchroniser.
   · ⚠ ET ON LIT L'HORODATAGE **AVANT** `migrate` : `migrate` en POSE un quand il manque, et son
     dernier recours est `Date.now()` — un fichier ancien qui n'en portait pas se retrouverait
     donc daté de L'INSTANT DE L'IMPORT, c'est-à-dire annoncé « plus récent » que tout ce qu'on
     possède. Le prédicat travaille sur l'objet BRUT ; sans horodatage des DEUX côtés, la rangée
     se tait plutôt que de deviner (A83 : elle ne dit que ce qu'elle sait).
   · AUCUNE TOLÉRANCE, AUCUN SEUIL : un objet exporté puis réimporté sans avoir été touché porte
     le MÊME horodatage à la milliseconde près. « À une minute près » serait un seuil inventé.
   · ELLE NE CONDITIONNE RIEN, et le sort reste GLOBAL : la stratégie est décidée par la question
     « Doublons » (A130, où le contrôle par rangée a été écarté et motivé). La rangée informe. */
```

## J195 — A159 — L'ATELIER DIT AUSSI **OÙ** ÇA VA, ET RANGÉE PAR RANGÉE

```
/* ═══ A159 — L'ATELIER DIT AUSSI **OÙ** ÇA VA, ET RANGÉE PAR RANGÉE ═══════════════════════════
   A129 avait renversé l'ordre : d'abord CE QUE l'on importe, ensuite OÙ. Le « OÙ » était pourtant
   resté ce qu'il était avant l'atelier — une question oui/non posée APRÈS, et seulement si une
   bibliothèque partagée éditable se trouvait sélectionnée à l'accueil. Trois manques, tous
   signalés à l'usage (« comment définir les catégories et bibliothèques de une ou multiples
   fiches à l'import ? ») :
    · on ne pouvait viser QUE la bibliothèque déjà sélectionnée — depuis l'accueil « Perso », la
      question ne se posait même pas et tout tombait au Perso ;
    · la CATÉGORIE n'était pas réglable du tout : elle venait du fichier, un point c'est tout ;
    · et le grain était le FICHIER, alors que le grain de l'atelier est l'ENTITÉ depuis A129 — un
      export de bibliothèque entière ne pouvait pas se répartir entre deux rayons.
   Chaque rangée porte donc sa destination : une bibliothèque et une catégorie. Le bandeau de tête
   est la MÊME commande appliquée aux rangées COCHÉES (cf. CSS) — pas un réglage global à côté.
   ⚠ LE DÉFAUT NE DÉCIDE RIEN À LA PLACE DE L'AUTEUR : la catégorie vaut `IMP_KEEP`, « garder
   celle du fichier », qui est le comportement d'AVANT ce lot, réconcilié par nom dans la
   destination (v5.10.9). L'atelier ne se met à ranger que si on le lui demande.
   ⚠ ET LA SENTINELLE NE PEUT PAS ÊTRE UN IDENTIFIANT : les valeurs de menu transitent par un
   attribut, donc par une chaîne, et `SAFE_ID` (`[A-Za-z0-9_-]`) ne produit jamais de « ~ ». Sans
   quoi une catégorie nommée de la bonne façon vaudrait « garder », en silence. */
```

## J196 — A132 — SAVOIR LEQUEL EST LE PLUS RÉCENT NE DIT PAS CE QU'ON PERDRAIT

```
/* ═══ A132 — SAVOIR LEQUEL EST LE PLUS RÉCENT NE DIT PAS CE QU'ON PERDRAIT ════════════════════
   Dernier étage de l'atelier, et il ferme la promesse « voir avant d'écrire » : sur une entité
   DÉJÀ présente, « Comparer » déplie ce que « remplacer » ajouterait et ce qu'il supprimerait.
   · **AUCUN COMPARATEUR NEUF** : c'est celui de « Versions » (`flattenFiche` + différence
     d'ensembles), inchangé — un second, écrit à côté, finirait par répondre autre chose ici que
     là sur la même paire d'objets. Seule l'ORIENTATION change et elle est nommée : on part de MA
     version, l'entrant est la cible, donc « + » = ce que le fichier apporte.
   · **UNE RÉFÉRENCE A SON APLATISSEMENT**, parce qu'elle n'a ni bloc ni minuteur : son corps est
     du texte, et ses lignes SONT ses unités de comparaison. La taire aurait laissé sans réponse
     exactement la même question destructive, sur l'autre moitié de la bibliothèque.
   · **CE N'EST PAS LE DIFF CLINIQUE REFUSÉ EN A119** : celui-là aurait résumé une modification de
     dose à quelqu'un qui s'apprête à SOIGNER. Ici on est dans un geste d'AUTEUR, à froid, et la
     surface est celle que « Versions » lui montre déjà — même public, même dessin, mêmes mots.
   · **REPLIÉ PAR DÉFAUT** : la rangée reste une rangée. On ne déplie que ce qu'on a demandé. */
```

## J197 — A132 — le dépliant de comparaison. DÉLÉGUÉ (la liste est reconstruite à chaque atelier), et le

```
/* A132 — le dépliant de comparaison. DÉLÉGUÉ (la liste est reconstruite à chaque atelier), et le
   diff est calculé À L'OUVERTURE, jamais au rendu de la liste : sur dix-huit entités, ce serait
   dix-huit aplatissements pour un dépliant qu'on n'ouvrira peut-être pas.
   ⚠ CE QUI A ÉTÉ ÉCRIT PUIS RETIRÉ, ET POURQUOI C'EST À DIRE : j'avais posé un `preventDefault`
   au motif que « le bouton vit dans un <label>, donc l'ouvrir cocherait la rangée ». C'est FAUX —
   un descendant de contenu INTERACTIF n'active pas son label, et la mesure le confirme sur les
   DEUX moteurs (défaut réintroduit, témoin resté vert). La ligne est donc partie avec la croyance
   qu'elle servait : un commentaire qui affirme un mécanisme inexistant finit par le faire
   « réparer » (A72). Le témoin, lui, RESTE — il mesure la PROPRIÉTÉ (ouvrir la comparaison ne
   change pas la sélection), pas le mécanisme du jour, et couvrirait donc le cas où ce bouton
   deviendrait un jour un élément non interactif. C'est un GARDE, pas un discriminant, et il le
   dit. */
```

## J198 — Fonctionne pour une librairie entière comme pour une fiche seule (fiches = tableau de 1).

```
    // Fonctionne pour une librairie entière comme pour une fiche seule (fiches = tableau de 1).
    // SÉCURITÉ : l'option destructive "remplacer entièrement" n'est proposée que pour un
    // import de PLUSIEURS fiches, et ne touche QUE la bibliothèque de destination.
    // Tri-état : Fusionner (true) / Remplacer tout (false) / ✕-Échap (null) = import ABANDONNÉ
    // (une étape destructive doit pouvoir être annulée proprement).
    // Le compte est celui de la SÉLECTION, jamais celui du fichier : une question qui annoncerait
    // dix-huit fiches pour deux cochées mesurerait le fichier, pas ce qu'on est en train de faire.
    /* ⚠ ET « REMPLACER » N'EST PLUS PROPOSÉ QUAND L'IMPORT VISE PLUSIEURS BIBLIOTHÈQUES (A159).
       Une suppression totale doit NOMMER ce qu'elle vide : « remplacer les bibliothèques
       choisies » viderait deux bibliothèques entières sur une phrase au pluriel, dont l'une
       peut-être pour une seule fiche qu'on y a glissée. Le geste reste possible — on importe vers
       une destination à la fois — mais il ne se propose pas par inadvertance. La fusion, elle,
       n'a jamais eu besoin de destination unique. */
```

## J199 — Catégories importées : rattachées à la bibliothèque de DESTINATION (chaque bibliothèque a

```
    /* Catégories importées : rattachées à la bibliothèque de DESTINATION (chaque bibliothèque a
       son propre jeu de catégories).
       ⚠ LA CLÉ DE RÉCONCILIATION EST LE NOM, PAS L'ID (v5.10.9, signalé à l'usage : « à l'import de
       fiches qui ont des catégories qui ne sont pas dans la bibliothèque d'import, elles s'affichent
       quand même — encore plus s'il y a une catégorie qui porte le même nom »). Ces deux lignes ne
       regardaient que l'id, et un id de catégorie n'a de sens QUE dans sa bibliothèque : ils sont
       déterministes au Perso (« c-reanimation », dérivé du nom) et aléatoires en bibliothèque
       partagée (`newCatId`). D'où deux défauts symétriques, tous deux visibles au rail :
        · vers une bibliothèque PARTAGÉE : l'id Perso entrant n'y existait pas -> on posait une
          SECONDE catégorie du MÊME id dans `categories`. Or `catOf()` résout un id sans regarder la
          bibliothèque et renvoie la première trouvée : la carte portait la couleur de l'AUTRE.
        · vers le PERSO : l'id partagé entrant est aléatoire, donc jamais reconnu -> une catégorie
          « Réanimation » de plus à côté de celle qui existait, même nom, deux rangées, les fiches
          réparties entre les deux.
       On réutilise donc la catégorie de destination dès que le NOM s'y trouve (comparé par
       `catSlug` : sans casse ni accents, comme partout ailleurs), on n'en crée une qu'à défaut, et
       un id déjà pris — fût-ce dans une AUTRE bibliothèque — est régénéré. `catMap` repointe
       ensuite les entités importées : c'est ce qui rend l'opération sûre, l'id d'origine n'étant
       qu'une adresse locale au fichier. Table nue (`Object.create(null)`, règle 6) : ses clés
       viennent du fichier importé. */
    /* A159 — LA TABLE EST INDEXÉE PAR (BIBLIOTHÈQUE, ID SOURCE), et ce n'est pas un détail : deux
       rangées peuvent GARDER la même catégorie du fichier vers DEUX destinations différentes, où
       elle ne porte pas le même identifiant. Une table indexée par le seul id source aurait
       renvoyé la première résolution à toutes les autres — c'est-à-dire l'id d'une catégorie
       d'une AUTRE bibliothèque, le défaut même que la v5.10.9 vient de fermer.
       Et la résolution est PARESSEUSE : une catégorie n'est créée que lorsqu'une entité la
       réclame réellement, dans la bibliothèque où elle la réclame. */
```

## J200 — DÉLAI DE GARDE SUR TOUT APPEL RÉSEAU (correctif) — AUCUN `fetch` du fichier n'en avait.

```
/* DÉLAI DE GARDE SUR TOUT APPEL RÉSEAU (correctif) — AUCUN `fetch` du fichier n'en avait.
   Sur iOS, un fetch qui ne trouve pas de route ne rejette qu'au bout de 60 à 75 s. Trois
   conséquences, toutes vécues comme « la synchro est bloquée » :
     • `Sync.running` reste vrai pendant tout ce temps, donc aucune autre tentative ne part ;
     • le repli exponentiel (5/10/20…120 s) ne s'arme qu'APRÈS la première erreur — il ne peut
       donc pas raccourcir cette première minute, il ne fait que la suivre ;
     • `Auth.refresh()` est attendu par `ensureFresh()` avant CHAQUE appel REST : un
       rafraîchissement suspendu bloque tout ce qui vient derrière, y compris ce qui n'aurait
       pas eu besoin du réseau.
   `navigator.onLine` ne rattrape rien et ne peut pas servir de garde : en ascenseur, en
   sous-sol ou derrière un portail captif, l'interface radio reste « up » et il répond `true`
   (c'est pourquoi `Sync.online()` n'est utilisé QUE comme échec rapide, jamais comme preuve
   qu'on est joignable).
   Deux délais, parce que deux natures : les appels JSON sont courts par construction (au pire
   une page de 1 000 lignes), un binaire PDF ne l'est pas — lui donner 25 s casserait un
   téléversement légitime sur réseau lent, ce qui serait un défaut de plus, pas un correctif.
   Sans AbortController on garde le `fetch` nu : non borné, mais jamais refusé faute d'API. */
```

## J201 — UN SEUL bouton « Se déconnecter » : l'ancien « Changer de compte » faisait EXACTEMENT la

```
    // UN SEUL bouton « Se déconnecter » : l'ancien « Changer de compte » faisait EXACTEMENT la
    // même chose (doSignOut -> écran de connexion, où l'on peut saisir n'importe quel e-mail) ;
    // deux boutons voisins pour une seule action ajoutaient du bruit et un choix inutile. Le
    // message de confirmation couvre le cas « autre compte ». L'OPTION facultative — effacer les
    // fiches de ce compte sur cet appareil — est portée par la fenêtre de confirmation (case
    // décochée par défaut), au lieu d'une case permanente dupliquée dans chaque variante de
    // l'écran Compte -> un seul point de code.
    // L'option n'est PROPOSÉE que si les fiches sont réellement sauvegardées en ligne : un compte
    // EN ATTENTE ou REFUSÉ a ses écritures bloquées côté serveur (RLS) -> ses fiches locales ne
    // sont pas dans le cloud, les effacer les perdrait définitivement. On masque donc la case pour
    // ces comptes (confirmDlg redevient un oui/non simple), la promesse « restent en ligne » ne
    // valant que pour un compte approuvé.
```

## J202 — Structure (audit v4.5) : identité + état -> ACTION PRIMAIRE au contact de l'état qu'elle

```
    // Structure (audit v4.5) : identité + état -> ACTION PRIMAIRE au contact de l'état qu'elle
    // rafraîchit -> contours jumeaux demi-largeur -> zone « Cet appareil » -> zone
    // « Administration » (admin) -> zone sensible, toujours dernière.
    /* M5 (audit design, v4.71.0) — L'IDENTITÉ EST UNE CARTE, ET IL N'Y A PLUS D'ACTION PRIMAIRE.
       Trois boutons pleine largeur empilés donnaient à un écran de RÉGLAGES l'allure d'un écran
       d'action, et « Synchroniser maintenant » y était le seul bouton REMPLI de la fenêtre — or
       on n'ouvre pas ses réglages pour agir, on les ouvre pour regarder. Les trois passent en
       contour et rejoignent la carte d'identité, dont ils dépendent tous les trois.
       CE QUI N'EST PAS REPRIS DE LA MAQUETTE : elle range les trois sur UNE rangée, ce qui
       remettrait « Se déconnecter » au contact du bouton le plus tapé de la fenêtre. La v4.5
       avait posé un espacement là exprès — « un tap légèrement trop bas ne doit pas déclencher
       une déconnexion », défaut vécu comme un bug. La déconnexion garde donc sa ligne et son
       tampon (et sa confirmation). */
```

## J203 — HAUTEUR DU MENU ⋯ — MESURÉE, JAMAIS CALCULÉE EN CSS (v4.73.2 ; cf. le commentaire de

```
/* HAUTEUR DU MENU ⋯ — MESURÉE, JAMAIS CALCULÉE EN CSS (v4.73.2 ; cf. le commentaire de
   `.more-menu`). Deux lectures, une écriture :
     · `bas` = la hauteur RÉELLEMENT visible. `visualViewport.height` quand il existe, parce que
       c'est la seule mesure qu'iOS ne fausse pas (dossier « bande basse iOS », v4.29.4) et qu'elle
       exclut d'elle-même les barres d'outils du navigateur ; `innerHeight` en repli.
     · `r.top` = la position réelle du menu, qui absorbe SANS AUCUN CALCUL la hauteur de l'en-tête,
       `env(safe-area-inset-top)` et le décalage de 6 px — les trois termes que le `calc()`
       précédent devait deviner un par un.
   Les deux sont en px VISUELS ; la hauteur écrite, elle, est en px CSS — d'où la division par
   `zoomF()` (règle v4.13.1). PLANCHER de 180 px : une mesure pathologique (menu ouvert pendant une
   transition, clavier virtuel déployé) ne doit jamais réduire le menu à une bande inutilisable —
   mieux vaut un menu qui dépasse un peu et qu'on peut faire défiler qu'un menu qui a disparu.
   `10 px` de garde au bas : de quoi voir que la liste continue, plutôt que de la couper au ras.
   ET LA MARGE BASSE DU MATÉRIEL EST RETIRÉE (`--sab`) — c'est le terme qui manquait, et c'est
   probablement lui qu'on voyait à l'usage : la hauteur visible d'iOS INCLUT la bande de
   l'indicateur d'accueil, si bien qu'un menu calé dessus y fait passer sa dernière rangée. Elle est
   soustraite en px CSS, comme le CSS le fait déjà partout ailleurs (`.azrail`, `.sess-start`) : sous
   zoom on en réserve donc un peu trop, ce qui raccourcit le menu de quelques pixels — l'erreur va
   dans le sens sûr. */
```

## J204 — --vvh (v4.29.4) : hauteur RÉELLEMENT visible, depuis visualViewport — la seule mesure fiable

```
/* --vvh (v4.29.4) : hauteur RÉELLEMENT visible, depuis visualViewport — la seule mesure fiable
   sur iOS (barre d'outils, clavier, PWA installée). En px CSS non zoomés, comme innerHeight :
   les consommateurs divisent par --zf. Mise à jour à chaque changement du viewport visuel. */
/* --vvt (v5.10.9) : DÉCALAGE du viewport visuel dans le viewport de mise en page. Posée par le
   même observateur et sur les mêmes évènements que --vvh, parce que c'est la même mesure en deux
   composantes — une couche plein écran a besoin des DEUX pour décrire le rectangle visible (cf.
   « une hauteur ne suffit pas », feuille de style). Bornée à 0 : `offsetTop` peut être légèrement
   négatif pendant l'élastique iOS, et un `top` négatif décollerait la couche vers le haut, soit le
   défaut qu'on corrige. Même unité que --vvh (px non zoomés) -> les consommateurs divisent par --zf. */
/* ⚠ `--vvt` NE VAUT QUE SOUS CLAVIER, ET C'EST UNE CORRECTION DE LA v5.12.0 (signalé à l'usage :
   « en scroll sur smartphone, tablette ou desktop, l'en-tête SAUTE au scroll, et tout en bas du
   scroll continue à descendre alors que pas besoin »). En rendant le chrome collant tributaire de
   `--vvt`, la v5.12.0 l'a rendu tributaire d'une valeur qui n'est PAS STABLE PENDANT LE
   DÉFILEMENT : `offsetTop` devient non nul pendant le rebond élastique de fin de course et pendant
   un pincement, sans qu'aucun clavier ne soit ouvert. L'en-tête suivait donc ces micro-décalages —
   il sautait, et il descendait avec le rebond.
   LA GARDE EST LA DÉFINITION MÊME DU CAS À COUVRIR : un clavier OCCUPE DE LA HAUTEUR. Le
   panoramique n'est retenu que si le viewport visuel est réellement plus COURT que celui de mise
   en page ; un panoramique sans rétrécissement n'est pas un clavier, c'est un artefact de geste.
   Le seuil est en dessous de toute barre d'accessoires de clavier (~44 px de dessin plus la marge
   du système) et très au-dessus de l'amplitude d'un rebond, qui ne rétrécit RIEN. C'est le pendant
   exact de la garde d'`unpan()` (v5.10.4), qui refuse d'agir tant qu'un champ est focalisé : les
   deux décrivent la même frontière, chacune de son côté. */
```

## J205 — ⚠ `--vvt` NE SUIT QUE LES CHANGEMENTS DE **HAUTEUR**, JAMAIS LE DÉFILEMENT (signalé à

```
  /* ⚠ `--vvt` NE SUIT QUE LES CHANGEMENTS DE **HAUTEUR**, JAMAIS LE DÉFILEMENT (signalé à
     l'usage : « lorsque je clique sur les flèches ‹ et › pour parcourir la recherche, l'en-tête et
     la sidebar sautent »). Le clavier ouvert, chaque défilement programmatique fait RE-PANORAMIQUER
     le viewport visuel pour garder le champ focalisé sous les yeux : `offsetTop` change alors à
     chaque saut d'occurrence, et le chrome — qui le suit depuis la v5.12.0 — sautait avec lui.
     C'est la règle déjà écrite du dossier, appliquée une famille plus loin : **une géométrie de
     chrome ne se dérive jamais d'un état qui dépend du défilement** (v5.0.9, puis `azrPoseBox` en
     v5.6, dont le haut est mesuré puis GELÉ pour la même raison — sinon ses lettres bougent sous
     le doigt). Le décalage se relit donc quand la HAUTEUR change, c'est-à-dire quand le clavier
     s'ouvre, se ferme ou change de taille ; entre deux, il est gelé et le chrome reste immobile
     pendant qu'on parcourt les occurrences.
     CE QUE ÇA COÛTE, ET C'EST DIT : si le système re-panoramique SANS changer la hauteur (passer
     le focus à un champ plus bas, clavier déjà ouvert), le chrome garde le décalage du dernier
     évènement de hauteur. C'est le bon compromis — ce cas laisse le chrome à quelques dizaines de
     pixels près, quand l'ancien comportement le faisait sauter à CHAQUE geste de lecture. */
  /* ⚠ AUCUN DÉLAI : LE DÉCALAGE S'APPLIQUE À L'INSTANT OÙ IL CHANGE (correction de la v5.12.7,
     tranchée par une VIDÉO de l'auteur — la première preuve directe de cette série).
     Trois réglages ont été essayés, et l'enregistrement montre pourquoi les deux derniers
     échouaient, à 0,6 seconde d'intervalle :
      · t = 4,4 s — l'en-tête a COMPLÈTEMENT disparu, le contenu monte sous la barre du navigateur :
        le décalage n'était PAS ENCORE appliqué ;
      · t = 5,0 s — l'en-tête est POUSSÉ VERS LE BAS, avec du contenu visible AU-DESSUS de lui :
        le décalage était appliqué alors qu'il n'était DÉJÀ PLUS bon.
     Ce n'était donc ni « trop suivre » ni « trop geler » : c'était DÉPHASÉ. Une couche calée sur le
     viewport visuel doit se recaler à l'instant exact où il bouge — un retard de 180 ms produit les
     DEUX symptômes tour à tour, et c'est ce que l'auteur décrivait depuis trois versions sans que
     le harnais puisse le montrer (il ne pilote pas `visualViewport`).
     CE QUI RESTE DE LA v5.12.5, et qui n'est pas en cause : la garde `VVT_MIN_CLAVIER` — sans
     clavier, aucun décalage n'est retenu, donc le rebond élastique de fin de course ne déplace
     toujours rien. */
```

## J206 — `html.kbd` — clavier logiciel ouvert : le chrome de PAGE se retire (cf. la feuille de style).

```
    /* `html.kbd` — clavier logiciel ouvert : le chrome de PAGE se retire (cf. la feuille de style).
       Posée ici parce que c'est le même prédicat que `--vvt` et qu'un second poseur, ailleurs,
       finirait par répondre autre chose sur le même état.
       ⚠ SAUF SI LE CHAMP QUI A OUVERT LE CLAVIER VIT DANS L'EN-TÊTE (v5.14.1, signalé à
       l'usage : « le clavier de l'accueil ne s'affiche plus »). La règle `html.kbd
       header.bar{display:none}` a été conçue pour la recherche des RÉFÉRENCES, dont le champ
       vit dans la colonne — mais le champ de recherche de l'ACCUEIL vit DANS l'en-tête :
       clavier s'ouvre → en-tête masqué → le champ touché est détruit AVEC lui → focus perdu →
       le clavier se referme aussitôt. Le champ se tuait lui-même, et aucune mesure du harnais
       ne le voyait (il ne pilote pas le clavier). Quand le champ actif est dans l'en-tête,
       l'en-tête reste — c'est LUI le chrome de frappe, exactement le principe de la 5.13.4
       (« un seul chrome à la fois ») appliqué dans l'autre sens. */
    /* v5.18.1 : le champ de l'accueil vit dans #homeDock, qui vit dans l'en-tête (A249) — mais
       le dock est FIXÉ au viewport visuel et gère sa propre géométrie clavier (translateY) :
       pour lui, la classe DOIT se poser (et l'en-tête d'accueil est exempté du retrait, cf.
       feuille de style). La garde ne vaut plus que pour un champ d'en-tête HORS dock. */
```

## J207 — v4.29.7 : iOS peut CORRIGER la géométrie de la WebView (ex. après le bug de la PWA amputée)

```
  /* v4.29.7 : iOS peut CORRIGER la géométrie de la WebView (ex. après le bug de la PWA amputée)
     SANS émettre resize sur visualViewport — une valeur posée au lancement restait alors fausse
     pour toute la session. On écoute large (fenêtre, orientation, retour au premier plan) ET on
     resynchronise à chaque tic d'horloge — c'est-à-dire toutes les 300 ms, soit ~3,3 fois par
     seconde, et non « ~1 s » comme l'annonçait ce commentaire jusqu'en v4.44.0 : `tickAll` est
     branché sur `setInterval(…,300)`, et l'appel est placé AVANT le garde d'activité, donc il
     tourne aussi au repos. Ce que ça coûte, mesuré : RIEN — `vv.height` est une propriété déjà
     calculée (aucune lecture de géométrie forcée, 0 layout), et l'écriture de `--vvh` n'a lieu
     que si la valeur a bougé d'au moins 0,5 px. Le chiffre est corrigé parce qu'un commentaire
     faux sur une fréquence est ce qui fait ensuite « optimiser » au jugé une boucle qui ne coûte
     rien — la Phase 3 a chronométré exactement cette famille de faux problèmes. */
```

## J208 — ⚠ DÉCALAGE RÉSIDUEL DU VIEWPORT VISUEL (v5.10.4, signalé à l'usage avec capture : toast

```
  /* ⚠ DÉCALAGE RÉSIDUEL DU VIEWPORT VISUEL (v5.10.4, signalé à l'usage avec capture : toast
     « fichier ignoré » au MILIEU de l'écran, en-tête invisible sous la barre d'état, bande vide
     sous le pied de page — « quelques fois »). Sur iOS, l'ouverture du clavier PANORAMIQUE le
     viewport visuel DANS le viewport de mise en page (`offsetTop` > 0) pour montrer le champ
     focalisé ; à la fermeture, WebKit ne recolle pas toujours les deux — surtout quand le fond
     était verrouillé par une fenêtre (`overflow:hidden`, donc aucun évènement de défilement pour
     resynchroniser). L'état restant est EXACTEMENT la capture : l'en-tête collant (accroché au
     haut du viewport de mise en page) est au-dessus de l'écran, tout `position:fixed` ancré en
     bas paraît remonté d'autant, et l'on voit PASSÉ la fin du document. Un défilement de
     l'utilisateur répare (c'est pourquoi le défaut est fugace) ; on répare d'office.
     LA GARDE EST LA DÉFINITION MÊME DE L'ANOMALIE : hors pincement (scale ≈ 1) et hors clavier
     (aucun champ focalisé), un `offsetTop` non nul est TOUJOURS un état incohérent — les deux
     viewports ont la même hauteur, il ne peut rien y avoir à « montrer » plus bas. Le recollage
     déplace le défilement de mise en page DE l'offset (`scrollBy`) : le contenu visible ne bouge
     pas d'un pixel (il était déjà là), seuls l'en-tête et les couches fixes retrouvent l'écran.
     Jamais appelé en continu : sur les seuls évènements où l'état peut naître ou se voir
     (fermeture du clavier = resize du viewport visuel, perte de focus, retour de bfcache). */
```

## J209 — HISTORIQUE DE SESSIONS SYNCHRONISÉ (v4.54.0) — ET L'INVARIANT QU'IL LÈVE

```
/* ═══ HISTORIQUE DE SESSIONS SYNCHRONISÉ (v4.54.0) — ET L'INVARIANT QU'IL LÈVE ════════════════
   « Les sessions vivent en IndexedDB local, jamais synchro » était une propriété ÉCRITE du projet,
   et le mode EXERCICE en DÉRIVAIT sa garantie de non-contamination clinique. On la lève — sur
   OPT-IN, défaut fermé — et il faut donc redire ce qui la remplace :
    · SEULES LES SESSIONS ARCHIVÉES montent (`live:false`). Une session VIVE resynchronisée serait
      un second mécanisme de partage, avec tous les risques du premier et aucun de ses garde-fous.
    · L'EXERCICE EST SÉGRÉGÉ PAR UNE COLONNE, pas par une convention de contenu : la propriété
      « zéro contamination clinique » cesse de dépendre de la localité et devient une donnée qu'on
      peut filtrer, et que le serveur voit.
    · `verified`/`vgaps` NE MONTENT PAS — décision d'étape, pas de principe. Le compte rendu
      distant porte alors la mention explicite « trace de vérification disponible sur l'appareil
      d'origine », jamais un silence : une trace absente qui ne se dit pas est pire qu'une trace
      absente.
    · `data` accueille SOIT un objet en clair, SOIT `{v:2, enc:<blob>}`. C'est la seule décision de
      forme qu'il fallait prendre MAINTENANT, parce qu'elle devient irréversible dès qu'il y a des
      données en place : passer au chiffrement de bout en bout ne demandera aucune migration.
   Une session n'est PAS un contenu d'équipe : ni `libraryId`, ni partage, une seule politique. */
/* `stepTexts` rejoint la liste : c'est du contenu CLINIQUE, il reste sur l'appareil qui l'a
   produit. Le drapeau `vElsewhere` couvre déjà le cas — un compte rendu distant DIT que le détail
   est resté ailleurs plutôt que de le taire. */
```

## J210 — UNE SESSION DISTANTE PASSE PAR ICI, ET NULLE PART AILLEURS (v5.10.2 — la règle 5 appliquée aux

```
/* UNE SESSION DISTANTE PASSE PAR ICI, ET NULLE PART AILLEURS (v5.10.2 — la règle 5 appliquée aux
   sessions). C'était le SEUL point d'entrée de données distantes sans assainisseur : fiches et
   protocoles passent par migrate()/migrateProtocol() trois lignes plus haut, les sessions étaient
   écrites TELLES QUELLES en IndexedDB. La RLS borne la table à son propriétaire et tout est esc()
   à l'affichage — ce qui se jouait n'est pas une XSS mais la règle elle-même, l'absence de tout
   PLAFOND (une ligne gonflée grossit IndexedDB sans borne), et le motif __proto__ : JSON.parse
   pose `__proto__` en propriété PROPRE, qu'`Object.assign` recopie par [[Set]] — c'est-à-dire
   écrit le PROTOTYPE de la cible.
   LISTE GRISE, PAS BLANCHE : les champs CONNUS sont bornés et normalisés, les inconnus TRAVERSENT
   (moins BAD_KEYS) — une liste blanche perdrait en silence les champs d'un client plus récent au
   premier aller-retour LWW, le défaut que la synchro existe pour éviter. Les grammaires sont
   celles qui existent déjà : SHARE_KEY_RX pour les clés d'état, shareNavNorm pour nav/navSeq,
   tkRefNorm pour les références du journal — une seconde grammaire divergerait (§ 5.5). */
```

## J211 — Cocher l'option rend l'action destructrice -> le bouton principal passe en rouge (convention

```
    // Cocher l'option rend l'action destructrice -> le bouton principal passe en rouge (convention
    // « destructeur = danger »), même si l'appel de base n'était pas `danger`. Exception
    // `checkSafe:true` : la case est PROTECTRICE (ex. « ramener les fiches hors compte »),
    // la cocher ne doit pas peindre l'action en danger.
    /* ⚠ `checkRequired` (v5.12.0) — LA CASE OUVRE LE BOUTON, elle ne fait plus que le peindre.
       Jusqu'ici une case ne CONDITIONNAIT rien : on pouvait valider sans la cocher, et son rôle
       se réduisait à une couleur. C'est assez pour une option ; ce n'est pas assez pour une
       suppression EN LOT, où la fenêtre énumère ce qui va disparaître et où la case est
       l'accusé de lecture de cette liste. Avec ce drapeau, le bouton principal reste FERMÉ
       (`:disabled`, apparence de fermé du dossier) tant que la case n'est pas cochée — le geste
       ne peut pas être franchi machinalement. Les appels existants ne le passent pas et ne
       changent donc pas d'un pixel. */
```

## J212 — Lignes distantes que le pull INCRÉMENTAL (curseur temporel) ne ramènera JAMAIS, à repêcher :

```
// Lignes distantes que le pull INCRÉMENTAL (curseur temporel) ne ramènera JAMAIS, à repêcher :
//  - id absent en local et non supprimé : ligne devenue visible APRÈS coup — adhésion à une
//    bibliothèque dont le contenu existait déjà (la RLS révèle d'un coup des lignes plus VIEILLES
//    que le curseur), ou ligne poussée avec un updated_at « passé » (horloge en retard sur un
//    autre appareil : updated_at vient du client, le serveur ne borne que le futur,
//    cf. clamp_updated_at dans supabase/schema.sql) ;
//  - id présent mais version distante plus récente que la locale (mêmes causes, sur une mise à
//    jour ou une suppression passée SOUS le curseur). La sélection reste LWW : une saisie locale
//    plus fraîche n'est jamais redemandée (donc jamais écrasée).
// PURE (testée) : reçoit le listing léger {id,updated_at,deleted_at} et l'index local {id:entité}.
// Les ids viennent du serveur et repartent dans un filtre `id=in.(...)` : format SAFE_ID exigé.
```

## J213 — PULL GÉNÉRIQUE d'une table {id, data jsonb, updated_at, deleted_at} — comportement

```
  // PULL GÉNÉRIQUE d'une table {id, data jsonb, updated_at, deleted_at} — comportement
  // STRICTEMENT identique à l'historique des fiches ; les spécificités (archivage de version,
  // nettoyage de la note personnelle) sont injectées par `cfg`.
  //   cfg = { table (table REST), store? (store LOCAL, défaut = table), cursorKey,
  //           getAllLocal, fromRow, addMem/replaceMem/dropMem (tableau en mémoire),
  //           backup?, onRemoteDelete? }
  /* ⚠ LA TABLE DISTANTE ET LE STORE LOCAL SONT DEUX NOMS, PAS UN (v5.0.4, signalé à l'usage :
     « Erreur synchronisation — One of the specified object stores was not found »). `cfg.table`
     servait aux DEUX, ce qui était vrai tant que les noms coïncidaient. Le lot T9 (v5.0.0) a
     renommé la table Supabase `fiches` -> `cognitive_aids` — pour de bonnes raisons, et en ne
     touchant PAS au store IndexedDB (renommer un store exige une montée de version de base) —
     et le pull des aides a dès lors écrit dans un store nommé `cognitive_aids`, qui n'existe
     nulle part : la synchro ENTIÈRE échouait à la première page portant une ligne. Le défaut est
     resté invisible aux garde-fous parce qu'aucun harnais n'exerce un pull réel. */
```

## J214 — JAMAIS DE RE-RENDU PENDANT UN SOIN (v4.42.0) — règle 11 : « le mode crise n'est jamais

```
    // JAMAIS DE RE-RENDU PENDANT UN SOIN (v4.42.0) — règle 11 : « le mode crise n'est jamais
    // interrompu : aucune modale, AUCUNE SYNCHRO INTRUSIVE ». Un `render()` reconstruit `main` :
    // le nœud sous le doigt est détaché et **un tap en vol est avalé** (mesuré avec témoin sur
    // Chromium ET WebKit : l'étape reste décochée avec re-rendu, se coche sans). Il suffisait
    // qu'un coéquipier modifie UNE ligne d'une bibliothèque partagée pour que ça tombe en pleine
    // réanimation. Le compte `applied` (v4.32.0) avait déjà supprimé les re-rendus qui ne
    // peignaient rien ; celui-ci peint quelque chose, mais au pire moment.
    // Rien n'est perdu : `addMem`/`replaceMem`/`dropMem` ont déjà mis À JOUR LA MÉMOIRE, et toute
    // sortie de crise passe par `render()` (fermer la session, revenir à l'accueil, ouvrir une
    // autre fiche) — l'écran se met donc à jour au premier instant où c'est sans danger. Pas de
    // drapeau à tenir : ce serait un second état à synchroniser pour rien.
    // CE QUI RESTE VRAI PENDANT CE TEMPS, et c'est voulu : la fiche OUVERTE ne change pas sous
    // les yeux du soignant. `state.fiche` et `Runtime.fiche` pointent l'objet d'AVANT ; le
    // contenu clinique en cours d'exécution est figé jusqu'à la fin du soin. Une aide partagée
    // réécrite à distance en pleine réanimation ne doit pas se substituer à celle qu'on déroule.
    // Le mécanisme de reprise (`openRead` re-pointe `Runtime.fiche` sur la version fraîche) reste
    // inchangé : la nouvelle version arrive à la RÉOUVERTURE, jamais en cours de geste.
```

## J215 — Sync · PUSH — le local-first vers le cloud (_reclaimBlocked/_pushTable/_push…)

```
  /* ===== Sync · PUSH — le local-first vers le cloud (_reclaimBlocked/_pushTable/_push…) ===== */
  // PUSH GÉNÉRIQUE d'une table {id, data jsonb, ...} — même patron que _pullTable : mécanique
  // UNIQUE (un correctif de la boucle de retry ne s'écrit plus qu'une fois), spécificités par cfg.
  //   cfg = { table, getAllLocal, dataPut, dataDel, toRow,
  //           skip? (retenue d'éléments, ex. heldEdits), repair (403 perso : régénère l'id) }
  // Déroulé :
  //   1. Cas nominal : tout part en UNE requête (une requête PostgREST est atomique : tout le
  //      sous-ensemble passe, ou rien), acquittement local (dirty=false / purge des tombstones).
  //   2. Lot refusé : on réessaie élément PAR élément pour ISOLER le ou les fautifs — sinon un
  //      seul refus (droits retirés, id déjà pris par un autre compte...) bloquerait TOUTE la
  //      bibliothèque indéfiniment (le backoff rejouerait le même lot voué à l'échec).
  //   3. PERSO refusé en 403 = son id appartient déjà à un AUTRE compte (transfert par
  //      export/import — la clé primaire cloud est globale) : RÉPARATION en régénérant l'id
  //      (cfg.repair) puis renvoi immédiat. GARDE-FOU : uniquement si nos droits d'écriture perso
  //      sont avérés (un autre élément perso vient de passer, ou is_approved() confirme) — sinon
  //      une panne de droits GLOBALE (compte plus approuvé, politique serveur) renommerait tout
  //      en boucle à chaque nouvelle tentative.
  // DROITS PERDUS en cours de route (audit v4.1.1) : une modification locale `dirty` d'une
  // bibliothèque où l'on ne peut PLUS écrire (rétrogradé lecteur, retiré de la bibliothèque)
  // ne partirait JAMAIS — filtrée du push, épargnée par la réconciliation (qui protège les
  // dirty), jamais écrasée par le pull (LWW : la copie locale est plus récente) -> divergence
  // permanente et SILENCIEUSE (pastille verte). Ici : la modification est DUPLIQUÉE en Perso
  // (rien ne se perd), la copie partagée revient à la version du serveur (ou disparaît si l'on
  // n'est plus membre, comme _reconcileShared), et l'utilisateur est PRÉVENU. Ordre copie
  // d'abord, retour serveur ensuite : un échec à mi-chemin laisse au pire un doublon Perso au
  // passage suivant, jamais une modification effacée. Une SUPPRESSION bloquée, elle, n'a rien
  // à préserver : la version de l'équipe est simplement restaurée.
```

## J216 — ⚠ PRÉSENCE OBSERVÉE, JAMAIS DÉCLARÉE (v5.10.5, signalé à l'usage : « si l'invité se

```
/* ⚠ PRÉSENCE OBSERVÉE, JAMAIS DÉCLARÉE (v5.10.5, signalé à l'usage : « si l'invité se
   déconnecte, pas de mise à jour côté hôte — il apparaît toujours, et ⇄ 1 reste »). Fermer
   l'application n'émet RIEN : la seule trace d'un départ silencieux est `last_seen_at`, que le
   serveur date à chaque pull/push du participant et renvoie (`seen`). Comparaison en heure
   SERVEUR (`Share.now()`), `seen` étant côté serveur. Rien n'est déduit ni jugé (§ 2 : on
   recopie une heure) et rien n'est révoqué : un sondage suivant refait le participant présent,
   sans autre geste. */
/* ⚠ LE SEUIL EST CLINIQUE, PAS RÉSEAU (v5.10.5, retour utilisateur sur les 30 s initiales :
   « en situation d'urgence ça peut arriver de lâcher son téléphone 1, 2 min, des fois plus ») :
   un téléphone posé pendant un geste NE quitte PAS la session. Trois régimes, donc :
   - silence ≤ 45 s : rien à dire (le sondage le plus lent fait 10 s ± 20 %) ;
   - 45 s à 3 min : le participant reste PRÉSENT et compté — la fenêtre de session porte juste
     « sans nouvelles · N min », une information, pas un verdict ;
   - au-delà de 3 min : « absent », hors compte ⇄ et menu.
   Et le départ EXPLICITE n'attend pas ce seuil : « Quitter le partage » émet un évènement
   `presence` (genre réservé depuis l'origine, jamais branché — accepté tel quel par la liste
   blanche du serveur), et l'hôte l'affiche « parti » à la seconde. */
```

## J217 — PÉREMPTION = CONTRAT AFFICHÉ, pas propriété émergente : le seuil ne dépend PAS du repli

```
  /* PÉREMPTION = CONTRAT AFFICHÉ, pas propriété émergente : le seuil ne dépend PAS du repli
     exponentiel (`_fails`), qui est une réaction à la panne et non une promesse. Au retour
     d'arrière-plan l'écran est périmé AVANT la première réponse, et c'est automatique — iOS
     SUSPEND le JS, donc `lastOk` est déjà vieux au réveil.
     LE SEUIL EST SOLIDAIRE DE LA CADENCE COURANTE, et une constante ne pouvait pas l'être : à
     4 000 ms fixes, il était INFÉRIEUR à la période nominale dès 30 s sans action (5 s ± 20 %,
     puis 10 s après deux minutes). Un réseau PARFAIT aurait donc affiché « figé » environ une
     seconde sur cinq au repos, et six secondes sur dix pendant un cycle de RCP de deux minutes —
     c'est-à-dire précisément dans le cas d'usage phare. Un indicateur qui crie au loup pendant
     60 % du temps n'est plus lu quand la panne est réelle.
     Le facteur 2,5 n'est pas un arrondi : la gigue étant de ±20 %, deux périodes consécutives
     peuvent légitimement atteindre 2,4 × la base. 2,5 signifie donc « DEUX cycles manqués », pas
     « un cycle un peu lent ». La levée, elle, est immédiate : un seul succès rafraîchit `lastOk`. */
```

## J218 — LE CODE EST MORT DÈS QUE QUELQU'UN ENTRE — et l'hôte doit le voir.

```
        /* LE CODE EST MORT DÈS QUE QUELQU'UN ENTRE — et l'hôte doit le voir.
           `share_join` met `code_hash` et `join_open_until` à NULL : la porte se referme derrière
           celui qui entre, avant l'échéance des 120 s. Or l'hôte gardait `code` et `joinUntil` de
           son côté et continuait d'afficher le code AVEC un décompte : il dictait un code déjà
           consommé, et voyait « ouvert encore 97 s » sur une porte fermée. C'est la donnée périmée
           présentée comme vivante — danger n°2 du palmarès ECRI 2015, que la doctrine du quai
           nomme déjà pour les minuteurs. Aucune modification du schéma n'est nécessaire : une
           jointure est la SEULE chose qui consomme un code, donc l'apparition d'un participant
           EST l'observation. On en profite pour l'annoncer — l'hôte obtient enfin l'accusé de
           réception d'appariement que l'échange en trois temps (AC 61-115) suppose. */
        /* UN DÉTACHÉ QUI TENAIT LA MAIN LA REND AUSSI. Poursuivre seul est un départ : le laisser
           inscrit comme lead laisserait le partage sans conducteur, et l'hôte n'aurait aucun geste
           pour le dire (le bouton « Donner la main » ne se propose que sur un participant vivant). */
```

## J219 — AVANCER JUSQU'À LA BORNE HAUTE DU SERVEUR — sinon le curseur se bloque sur un TROU.

```
        /* AVANCER JUSQU'À LA BORNE HAUTE DU SERVEUR — sinon le curseur se bloque sur un TROU.
           Les numéros sont alloués à TOUT le lot poussé, mais seuls les évènements autorisés sont
           insérés : un scribe qui pousse [cocher, naviguer] consomme deux numéros et n'écrit
           qu'une ligne. Le trou ne se comblera JAMAIS. En calant le curseur sur le dernier
           évènement REÇU, `cursor` resterait éternellement sous `seq` — et la détection ci-dessous,
           qui exige d'être à jour, ne se déclencherait plus jamais : un contrôle mort, sans que
           rien ne le signale.
           Avancer est SÛR ici, et c'est la contrepartie du verrou de ligne : deux écritures
           concurrentes sont entièrement sérialisées (le verrou est tenu jusqu'au commit), donc
           lorsqu'un lecteur voit `last_seq = N`, toutes les lignes de numéro ≤ N sont committées
           et visibles. C'est exactement ce qu'un `bigserial` NE garantirait pas.
           SAUF si le lot est TRONQUÉ (le serveur en renvoie 500 au plus) : il reste alors des
           évènements réels sous `seq`, et sauter jusqu'à la borne les perdrait pour de bon. */
```

## J220 — DÉTECTION DE DIVERGENCE, EN DEUX ÉTAGES. L'indicateur de péremption ne voit que le

```
        /* DÉTECTION DE DIVERGENCE, EN DEUX ÉTAGES. L'indicateur de péremption ne voit que le
           SILENCE ; or le mode de défaillance dangereux de ce transport produit des mises à jour
           qui arrivent À L'HEURE et sont FAUSSES. Un écran vert et faux vaut moins qu'un écran qui
           se déclare périmé — c'est le danger n°2 du palmarès ECRI (intégrité des données), et il
           ne se traite pas par la confiance dans un verrou de ligne.
             1. LE COMPTE, symétrique : il manque des évènements OU il y en a en trop (un lot
                réappliqué après une reprise compte double).
             2. L'EMPREINTE DU FLUX : SHA-256 des couples (numéro, identifiant) reçus, comparé à
                celle que le serveur calcule sur les lignes ÉCRITES. Elle attrape ce que le compte
                ne voit pas — doublon, ordre faux, identifiant corrompu.
           On vérifie AU MOMENT OÙ L'ON PRÉTEND ÊTRE À JOUR : c'est là que l'affirmation « mon
           écran reflète la session » est faite, donc là qu'elle doit être prouvée. */
```

## J221 — APPLICATION D'UN LOT DISTANT. Trois interdits, et ils ne sont pas négociables :

```
  /* APPLICATION D'UN LOT DISTANT. Trois interdits, et ils ne sont pas négociables :
       1. AUCUN `render()`. Il reconstruit `main` : le nœud sous le doigt est détaché et un tap en
          vol est AVALÉ — mesuré en v4.42.0 avec témoin, sur les deux moteurs, à l'époque où un
          simple pull de synchro suffisait à le déclencher en pleine réanimation.
       2. AUCUNE CONDENSATION. `ovPresList` replie les passages complets en chips ; déclenchée par
          une arrivée distante, elle ferait DISPARAÎTRE des centaines de pixels AU-DESSUS de la
          carte courante. La doctrine du journal est explicite : chaque passage est une carte
          postée à la suite, rien ne mute au-dessus. La condensation n'appartient qu'aux gestes
          LOCAUX de navigation (`ovDropOpens`) — c'est pourquoi on ne passe jamais par eux ici.
       3. AUCUN ÉVÈNEMENT DE SOI. Le fil renvoie aussi ce qu'on vient d'émettre ; le ré-appliquer
          ferait clignoter l'écran et, sur un repère horodaté, produirait un doublon au
          compte-rendu.
     Ce qui n'est pas applicable en direct est MIS EN FILE (`_defer`) et attendra un geste local :
     doctrine « acquittement par l'action », déjà employée pour le repli des cartes. */
  /* ===== Share · application des lots reçus (onEvents → SHARE_APPLY) et crochets d'état ===== */
```

## J222 — ⚠ L'ÉTAT S'APPLIQUE TOUJOURS ; SEULE LA PEINTURE DÉPEND DE LA VUE (v5.6, signalé à l'usage :

```
    /* ⚠ L'ÉTAT S'APPLIQUE TOUJOURS ; SEULE LA PEINTURE DÉPEND DE LA VUE (v5.6, signalé à l'usage :
       « en session partagée, les blocs des étapes disparaissent par moments chez l'hôte et ne
       réapparaissent pas »). Cette ligne était `if(state.view!=='read')return` — un ABANDON, et
       la perte était DÉFINITIVE : le curseur est avancé par l'appelant AVANT cet appel, donc le
       lot ne sera jamais relu. Il suffisait que l'hôte revienne à la bibliothèque, ouvre un
       éditeur ou consulte une autre aide pendant que le collègue avance pour que ces gestes
       soient perdus pour toujours — et l'écran, à son retour, montrait un parcours amputé qui ne
       se réparait plus. Le commentaire disait « le pli suffit » : c'est vrai chez l'INVITÉ, dont
       l'état EST le pli ; chez l'hôte la session locale fait autorité, et rien ne la rattrape.
       On applique donc toujours, et l'on se tait quand l'écran n'est pas celui de cette fiche.
       `sharePaintLive` tolère déjà l'absence d'un élément (« ce n'est pas un échec ») ; c'est la
       QUEUE de `shareApplyAnchored` qu'il faut museler, elle seule pouvant déclencher un rendu
       complet — donc arracher quelqu'un à l'écran qu'il regarde. */
```

## J223 — LA FILE ÉTAIT REMPLIE ET JAMAIS VIDÉE — le miroir se figeait dès que l'hôte changeait de

```
      /* LA FILE ÉTAIT REMPLIE ET JAMAIS VIDÉE — le miroir se figeait dès que l'hôte changeait de
         bloc. `SHARE_APPLY` décrit pourtant deux régimes DISTINCTS et cette ligne les confondait :
         'anchored' veut dire « reconstruit le journal, DONC ancré et annoncé » — appliqué tout de
         suite, sans que rien ne bouge sous le doigt —, quand seul 'deferred' attend un geste
         local. Mesuré avant correctif : après une navigation distante, `Runtime.nav` ne contenait
         pas le bloc cible, et aucun site du fichier ne drainait `_defer`. L'invité voyait les
         coches du bloc courant et plus rien ensuite : le contraire d'un miroir. */
      /* LE LECTEUR EST LE CAS LE PLUS DANGEREUX, et il l'était déjà avant le partage : la clé de
         l'étape est calculée AU CLIC depuis `state.nav`, jamais depuis le DOM peint. Une
         navigation distante arrivant entre le pointerdown et le click ferait donc cocher LA
         MAUVAISE ÉTAPE, et le compte-rendu l'imprimerait comme réalisée. Tant que le lecteur est
         ouvert, une navigation distante est donc REFUSÉE et mise en attente ; elle s'applique au
         prochain geste local (doctrine « acquittement par l'action »), et la bannière le dit —
         car ne pas suivre en silence serait le pire des deux mondes : l'autre a avancé, et celui
         qui lit à voix haute l'ignore. */
```

## J224 — LE BILLET DE L'INVITÉ — `sessionStorage`, et ce choix EST l'arbitrage.

```
  /* LE BILLET DE L'INVITÉ — `sessionStorage`, et ce choix EST l'arbitrage.
     Un rechargement involontaire mettait fin à la participation SANS RETOUR : rien n'était
     persisté (décision v4.46.0, « l'invité ne garde rien ») et le code est consommé, donc il ne
     pouvait pas revenir sans que l'hôte réarme une porte. Or un onglet mobile meurt tout seul —
     iOS recycle les onglets en arrière-plan —, et c'est le seul écran de la personne qui relève.
     `sessionStorage` a exactement la portée qu'il faut : CET onglet, CETTE navigation. Il survit
     au rechargement, il est effacé à la fermeture, il n'est partagé avec aucun autre onglet, et
     il ne touche ni IndexedDB, ni `localStorage`, ni les espaces de l'application. L'invariant
     d'étanchéité n'est donc pas abandonné — il est tenu là où il compte : rien de DURABLE ne
     reste sur le téléphone d'un tiers.
     Le billet ne porte que ce qui rouvre le tuyau. Aucune donnée clinique : la fiche et l'état
     sont redemandés au serveur, qui reste la source. */
```

## J225 — ÉCRAN D'ENTRÉE DE L'INVITÉ

```
/* ═══ ÉCRAN D'ENTRÉE DE L'INVITÉ ═══════════════════════════════════════════════════════════════
   OUVERTURE DE LA FICHE MIROIR. `openRead` est INUTILISABLE ici, et pas seulement par commodité :
   il cherche la fiche dans `fiches` — où elle n'est pas, et où elle ne doit JAMAIS entrer (la
   portée est la session, pas l'aide : partager une aide, ce sont les bibliothèques partagées, et
   c'est un autre dispositif) — puis appelle `bumpUsage`, qui écrit dans le stockage local de
   l'invité. Chemin distinct, donc, et volontairement court.
   `started` est remis à FAUX après `buildRuntime` (qui le déduit de la présence d'une session) :
   l'invité n'a pas de session locale, il regarde celle d'un autre. C'est ce qui garantit qu'aucun
   enregistrement ne se crée chez lui — le quai, lui, n'en dépend plus (cf. `crisisOnScreen`). */
/* SESSION PARTAGÉE SUR CET APPAREIL (v5.14.17, signalé : « consulter d'autres aides reste en
   mode partage, puis impossible de revenir »). Deux faits structuraux : (1) le menu invité
   était conditionné au MODE GLOBAL, pas à la fiche AFFICHÉE — il suivait l'invité sur ses
   propres aides ; (2) `openRead` REMPLACE `Runtime` — naviguer détruisait la session partagée
   elle-même, et la fiche reçue n'ayant pas de carte, aucun chemin n'y ramenait.
   Le retour a DEUX régimes : l'invité en ligne/direct se RECONSTRUIT du pli (`openSharedFiche`
   — le pli est son état, il n'a rien perdu) ; le MIROIR optique, sans transport, se GARE
   (`_shParked` : l'objet Runtime survit tel quel, ses ancres de minuteurs sont des heures). */
```

## J226 — ACCUSÉ DE RÉCEPTION À COÛT NUL. Un écran de confirmation « vous rejoignez <titre> » a été

```
  /* ACCUSÉ DE RÉCEPTION À COÛT NUL. Un écran de confirmation « vous rejoignez <titre> » a été
     envisagé et ÉCARTÉ, mesures à l'appui : le titre est déjà peint dans CETTE image par
     `#crisisBand` (visible sans défiler à 320×568 comme à 390×844), la jointure est irréversible
     à cet instant (ligne participant écrite, code brûlé, place tenue sur le quota), et l'écran
     intermédiaire aurait coûté un tap plus une lecture pour zéro information — au moment le plus
     contraint. Ce qui manquait n'est donc pas une surface : c'est l'annonce à qui ne voit pas
     l'écran. `#srLive` est le seul canal admis pendant un soin (règle 11) : invisible, sans pixel.
     ENTRÉE AU BOUT DU JOURNAL, PAS EN TÊTE DE FICHE. Mesuré avant correctif : la première étape
     cochable tombait à y=827 pour une fenêtre de 844, et à y=910 pour 568 — hors écran dans les
     deux cas, derrière un bloc de confirmation diagnostique que l'invité n'a pas à confirmer et un
     bouton de démarrage qui ne démarre rien chez lui. Le défilement est ici la conséquence directe
     de SON geste (il vient de taper « Rejoindre »), jamais un mouvement autonome : la règle 11
     proscrit le défilement déclenché par un évènement DISTANT, pas l'arrivée sur le point d'action
     de sa propre entrée. Même arithmétique d'ancrage que partout ailleurs (`stickBase`). */
```

## J227 — FENÊTRE D'APPARIEMENT DE L'HÔTE

```
/* ═══ FENÊTRE D'APPARIEMENT DE L'HÔTE ═════════════════════════════════════════════════════════
   Le QR n'est PAS un raccourci esthétique : un code affiché à l'écran ne peut être scanné que par
   quelqu'un qui est LÀ, dans la pièce. Il ne transite par aucun message, aucun serveur de courrier,
   aucun journal d'accès — c'est ce qui rend l'appariement défendable sans authentifier l'invité.
   RIEN N'EST PEINT DE FAÇON OPTIMISTE. La liste des participants vient du SONDAGE, donc du
   serveur ; une coupure demandée s'affiche « en attente » jusqu'à ce qu'il la confirme. Et la
   liste est APPEND-ONLY, jamais réordonnée : une rangée qui change de place sous le doigt pendant
   qu'on vise « Couper » est un mode de défaillance, pas un détail d'affichage.
   MISE À JOUR CHIRURGICALE : le compte à rebours vit dans un nœud texte isolé, la liste n'est
   reconstruite que si sa signature change. Une fenêtre qui se réécrit en bloc chaque seconde
   avale les taps — 13 % mesurés sur le quai, qui fait exactement cela. */
```

## J228 — DÉMARRER UN PARTAGE. Deux refus honnêtes AVANT tout appel réseau : sans compte, la session ne

```
/* DÉMARRER UN PARTAGE. Deux refus honnêtes AVANT tout appel réseau : sans compte, la session ne
   peut pas transiter par le serveur (l'hébergement d'un partage exige un compte — l'invité, lui,
   n'en a pas besoin) ; et sans session démarrée, il n'y a rien à partager. Le motif est dit sur
   place, jamais un « refusé » indifférencié : celui-ci n'a de raison d'être que face à un appelant
   anonyme, pour ne pas devenir un oracle. */
/* ═══ PARTAGE EN DIRECT (local, v5.14 étape 3c) — l'assemblage des briques témoignées ═══
   Un seul geste (« Partager ») : sans compte OU sans internet, la MÊME feuille montre
   l'appariement direct (maquettes figées). L'hôte : QR d'offre (jeton dedans) → scan de la
   réponse → canal → `slServe(hub)` + `Share.host()` INCHANGÉ sur `slHostIo`. Multi-invités :
   « Inviter un autre » régénère offre+jeton sur le MÊME hub. Vocabulaire à l'écran : jamais
   WebRTC/P2P — « en direct ». */
```

## J229 — LE SÉLECTEUR DE MODE, UN SEUL CONSTRUCTEUR (v5.14.7, signalé à l'usage : « parfois pas de

```
/* LE SÉLECTEUR DE MODE, UN SEUL CONSTRUCTEUR (v5.14.7, signalé à l'usage : « parfois pas de
   sélecteur, et si je clique il disparaît ») : il vit sur TOUS les états de la feuille —
   en ligne, appariement, en direct, émission optique — avec le composant .seg canonique et
   les pastilles de la maquette 08 (vert = cran actif, gris sinon, ⧗ pour le ponctuel).
   Cliquer le cran ACTIF ne fait rien ; cliquer un autre cran mène à un état qui PORTE AUSSI
   le sélecteur — il ne disparaît plus jamais. */
/* JOIGNABILITÉ MESURÉE (v5.14.19, signalé : « retrouver internet ne rend pas la pastille
   verte — pareil en Wi-Fi sans connexion ») : `navigator.onLine` dit « une interface réseau
   est levée », pas « le serveur répond » — sur un Wi-Fi SANS internet il répond vrai, et
   inversement rien ne repeignait la pastille quand la connexion revenait. Tant qu'un sélecteur
   est à l'écran, une sonde légère (HEAD auth/health, 3,5 s de garde) interroge le serveur
   toutes les 8 s + à chaque évènement online/offline, et repeint le sélecteur EN PLACE. */
```

## J230 — POURQUOI « EN LIGNE » EST FERMÉ — ON LE DIT, ET LE TAP RÉPOND

```
/* ═══ POURQUOI « EN LIGNE » EST FERMÉ — ON LE DIT, ET LE TAP RÉPOND ═══════════════════════════
   (v5.17.4, signalé à l'usage : « avec le mode direct on peut partager sans compte ; mais quand
   on clique sur “En ligne”, grisé, on ne sait pas pourquoi ça ne fonctionne pas — il faudrait
   une phrase du genre “compte nécessaire”, et expliquer comment marche le direct/hors ligne,
   valable aussi si connecté ».)
   DEUX DÉFAUTS, ET LE SECOND EXPLIQUE LE PREMIER :
   · la légende ne connaissait qu'UNE cause (« reviendra avec internet ») alors que le cran est
     fermé pour DEUX raisons distinctes — pas d'internet, ou pas de compte. Sans compte, attendre
     le réseau n'apportera jamais rien : la phrase était fausse au moment où elle comptait ;
   · le cran portait `disabled`, l'attribut natif, qui n'émet AUCUN évènement — le seul geste que
     l'on fait pour comprendre ne produisait rien du tout. Il passe donc en `aria-disabled` : même
     apparence, toujours annoncé fermé aux lecteurs d'écran, focalisable au clavier — et le tap
     DIT la cause et ce qui marche à la place. C'est la doctrine du dépôt (« un bouton grisé n'est
     acceptable que si une ligne voisine dit pourquoi », cf. `syncBtnRefresh`), poussée d'un cran :
     ici la ligne voisine ne suffisait pas, puisqu'elle se trompait de cause. */
```

## J231 — QUITTER LE PARTAGE — `Share.stop()`, JAMAIS `emit('detach')`. La distinction n'est pas

```
/* QUITTER LE PARTAGE — `Share.stop()`, JAMAIS `emit('detach')`. La distinction n'est pas
   technique : un évènement `detach` DATE un « je poursuis seul » dans le compte-rendu de l'hôte,
   c'est-à-dire qu'il affirme que l'invité a continué le soin de son côté. Quelqu'un qui ferme
   simplement l'écran n'a rien affirmé de tel, et un compte-rendu qui le prétendrait serait faux là
   où il compte — au débriefing. Le départ est donc SILENCIEUX côté serveur ; la ligne participant
   reste inscrite jusqu'à la purge, ce que l'hôte lira comme une présence qui ne rafraîchit plus.
   CE QUI RESTE, ET QU'ON DIT : ce qui a déjà été relevé appartient au compte-rendu du soignant.
   C'est un enregistrement de soin, il ne s'efface pas rétroactivement — la notice d'entrée
   l'annonce déjà, le dialogue le redit au moment où la question se pose vraiment.
   Le dialogue de confirmation est ici LÉGITIME malgré la règle 11 : c'est exactement le patron du
   « Terminer la session ? », que la doctrine désigne comme la SEULE porte de sortie d'une session
   et qui est un dialogue confirmé, précisément parce qu'un arrêt ne doit pas tenir à un tap. */
/* CE QUI N'EST PAS ENCORE PARTI (v5.14.20, demandé : « affiche s'il y a des actions non
   transmises — uniquement dans ce cas ») : chez l'invité en ligne/direct, la vérité est la
   FILE (`Share._q`) — ce qui y reste n'a pas atteint l'hôte et partira à la poubelle au
   départ explicite (doctrine du gel : seule la bifurcation « Continuer seul » convertit).
   Chez le MIROIR, la vérité est l'écart entre ses repères et ceux du dernier « Renvoyer ». */
```

## J232 — CE QUI A ÉTÉ RETIRÉ, ET POURQUOI — les trois formulations précédentes étaient fautives :

```
   CE QUI A ÉTÉ RETIRÉ, ET POURQUOI — les trois formulations précédentes étaient fautives :
   · « Vérifiez les 8 caractères » : TEXTE MORT. `shareCodeValid` a déjà exigé exactement huit
     caractères tous pris dans l'alphabet, deux lignes plus haut. On demandait un contrôle déjà
     fait, à la place du seul que l'application ne peut PAS faire : relire le code sur l'écran d'en
     face, où un caractère a pu être lu pour un autre.
   · « demandez de rouvrir l'accès » : FAUX OU NUISIBLE DANS CINQ CAUSES SUR SEPT, dont deux
     boucles infinies — `share_admit` ne vérifie NI l'expiration NI le quota : il rend un code neuf
     que `share_join` refusera encore, sans que personne ne comprenne pourquoi. Et sur une simple
     faute de frappe, il TUE un code peut-être encore vivant. On nomme donc le RÉSULTAT (« un
     nouveau code »), jamais le geste : l'hôte seul voit sa porte, et c'est lui qui décide — la
     coupure ne mord que parce que rejoindre exige un geste de l'hôte, sur SON écran.
   · « quelques minutes » et « nombre limité » : CHIFFRER AURAIT ÉTÉ FAUX, et l'argument n'est pas
     l'oracle (une chaîne statique ne porte aucun état). `max_guests` est une COLONNE PAR PARTAGE
     (1-8, défaut 3) et la fenêtre vaut 120 s à l'ouverture mais 15 à 600 s à chaque réadmission :
     aucune des deux valeurs n'est une constante de déploiement, et le client ne les reçoit jamais.
     RÈGLE DE TRI : un chiffre n'entre dans un message que s'il est (i) détenu par le client,
     (ii) identique pour tout partage de ce déploiement, (iii) capable de changer ce que le lecteur
     fait ensuite. « 8 caractères » passe les trois ; « 2 minutes » et « 3 » échouent aux trois.
     Ils sont remplacés par le seul INVARIANT DE PROTOCOLE utile — « un code ne sert qu'une fois » —
     qui est aussi le fait qui casse la boucle du re-tap, le champ conservant sa valeur après échec.
   Budget : ≤ 4 lignes à 320 px, sans quoi la boîte d'erreur escamote le bouton qu'elle demande de
   presser (mesuré : 7 lignes, 145 px, bouton coupé à 23 px sur 48). Couvert par audit-partage. */
```

## J233 — Accessibilité des fenêtres modales

```
/* ===== Accessibilité des fenêtres modales =====
   Les attributs role="dialog"/aria-modal/aria-labelledby sont posés dans le HTML. Ici, de façon
   CENTRALISÉE pour toutes les .ai-modal (aucune modif des 9 fonctions d'ouverture) :
     • à l'ouverture : mémorise l'élément actif et déplace le focus DANS la fenêtre ;
     • Échap : ferme la fenêtre du dessus (réutilise son bouton ✕, donc ses effets de bord),
       sinon l'aperçu plein écran ou la visionneuse d'image ;
     • Tab : piège le focus dans la fenêtre ouverte (recalculé à chaque frappe car le contenu
       de certaines fenêtres se remplit après l'ouverture) ;
     • à la fermeture : rend le focus à l'élément déclencheur ;
     • v4.21.0 : verrouille le défilement de la page de FOND (_bgLock/_bgUnlock, cf. la règle
       body.modal-open) tant qu'au moins une fenêtre est ouverte. */
```

## J234 — CALQUES OPAQUES plein écran (#flowFull, #lightbox) — traités comme des fenêtres pour le FOCUS,

```
/* CALQUES OPAQUES plein écran (#flowFull, #lightbox) — traités comme des fenêtres pour le FOCUS,
   le verrou de fond et le piège Tab, sans être des `.ai-modal` (CSS distinct, et Échap leur est
   déjà câblé nommément). `_layerTop()` sert au piège Tab ; il ne touche pas à `_topModal()`, dont
   dépendent Échap et le retour système. */
/* ═══ LE FOCUS D'OUVERTURE N'EST PAS LA CROIX (v5.17.4, demande utilisateur : « rendre les
   boutons des fenêtres de dialogue navigables au clavier — tab pour passer d'annuler au bouton
   d'action, entrée pour valider ; implémentation système native, reste simple ».) ═════════════
   Le piège Tab et l'activation par Entrée existaient DÉJÀ — ce sont les comportements natifs d'un
   `<button>`. Ce qui manquait est le POINT D'ENTRÉE : le gestionnaire posait le focus sur le
   premier élément focalisable, c'est-à-dire presque toujours le ✕. La première frappe d'Entrée
   FERMAIT donc la fenêtre au lieu de valider, et l'on n'atteignait « Confirmer » qu'après deux
   Tab — ce qui se vit comme « le clavier ne marche pas dans les dialogues ».
   Deux règles, natives toutes les deux, aucun composant nouveau :
   · une fenêtre peut DÉSIGNER son point d'entrée (`data-dlgfocus`) ;
   · à défaut, on prend le premier focalisable qui n'est PAS la croix — et la croix seulement s'il
     n'y a rien d'autre (fenêtre purement informative). */
```

## J235 — ⚠ ET IL DOIT SE VOIR — SINON LE CLAVIER N'EXISTE PAS (v5.17.5, signalé à l'usage : « je ne sais

```
/* ⚠ ET IL DOIT SE VOIR — SINON LE CLAVIER N'EXISTE PAS (v5.17.5, signalé à l'usage : « je ne sais
   pas quel bouton est sélectionné, et surtout ça paraît inconstant »).
   MESURÉ sur LES DEUX MOTEURS, cinq fenêtres : après un geste SOURIS — c'est-à-dire le geste qui
   ouvre un dialogue neuf fois sur dix —, `:focus-visible` ne s'allume PAS sur un focus
   PROGRAMMATIQUE ; après une frappe clavier, si. Le même dialogue avait donc DEUX apparences,
   et dans la plus fréquente rien à l'écran ne disait ce qu'Entrée allait faire : c'est
   exactement l'inconstance signalée, et elle vient de l'heuristique du navigateur, pas du code.
   Le dépôt connaissait déjà le piège dans l'AUTRE sens (audit-a11y v4.40.0 : « un `.focus()`
   programmatique ne déclenche pas `:focus-visible` » — il y produisait des faux positifs ; ici il
   produit un écran muet).
   ⚠ MESURE AVANT REMÈDE, ET LA PREMIÈRE MESURE MENTAIT : `.btn.primary` porte une ÉLÉVATION
   permanente en `box-shadow`, qu'une sonde « y a-t-il un anneau ? » compte pour un anneau. Le seul
   bouton qui semblait marqué ne l'était pas. Ne jamais lire « box-shadow ≠ none » comme un focus.
   ON POSE DONC L'ANNEAU NOUS-MÊMES, sur le SEUL élément qu'on focalise à l'ouverture, et il part
   au premier `blur` : au geste suivant `:focus-visible` reprend la main, avec le MÊME dessin —
   l'utilisateur ne voit aucune bascule. Pas de `:focus` nu en cascade sur toute la fenêtre : il
   écraserait les anneaux accordés à leur fond (`.chip-edit`, `.ds-x`, matière sombre), où un
   anneau primaire disparaîtrait — c'est la famille des pièges de cascade du dossier. */
```

## J236 — ⚠ LA CEINTURE PEUT DÉFAIRE UNE NAVIGATION VOULUE — D'OÙ `restaure` (v5.10.8, signalé à l'usage :

```
/* ⚠ LA CEINTURE PEUT DÉFAIRE UNE NAVIGATION VOULUE — D'OÙ `restaure` (v5.10.8, signalé à l'usage :
   « en mode édition, quand on clique sur ajouter (étape, chronomètre, minuteur, compteur…) le scroll
   ne descend pas jusqu'à la case qui vient d'être créée »).
   MESURÉ AVANT DE TOUCHER, et le défaut n'était pas où on le cherchait : `edAdd` défilait
   PARFAITEMENT (trace : y 1200 → 4996 dans la même tâche que le clic). C'est la micro-tâche
   suivante qui le rembobinait — l'observateur de fenêtres appelle `_bgUnlock`, qui restaurait
   `_bgScrollY` et ramenait à 1200, l'objet neuf restant 3 000 px sous le pli. Le symptôme
   « rien ne se passe » est donc un geste JUSTE, annulé 1 ms plus tard.
   ⚠ ET SEULEMENT SUR TACTILE, ce qui explique le signalement : la restauration est gardée par
   `pointer:coarse`. Sur ordinateur le défilement tenait — un défaut invisible partout où l'on
   développe, visible partout où l'on soigne. Même famille que le dossier « bande basse iOS ».
   La ceinture RESTE (elle protège d'un moteur qui bouge pendant le verrou, cf. ci-dessous) : ce
   qu'on ajoute, c'est la possibilité pour l'appelant de dire qu'il PREND LA MAIN — cf.
   `modalHandoffClose`. Une ceinture ne doit pas décider à la place de qui conduit. */
```

## J237 — FERMER EN PASSANT LA MAIN. Pour une fenêtre dont la fermeture est le DÉBUT d'un geste et non sa

```
/* FERMER EN PASSANT LA MAIN. Pour une fenêtre dont la fermeture est le DÉBUT d'un geste et non sa
   fin — la porte « ＋ » crée un objet et amène l'auteur dessus —, les deux réflexes du gestionnaire
   sont à contretemps : rendre le focus au bouton qui a ouvert (il n'existe plus, le formulaire
   vient d'être re-rendu) et rendre la position de défilement (elle annule le geste). On les coupe
   ICI, à la source, plutôt que de faire courir l'appelant après eux :
   · `_modalReturnFocus` est mis à néant AVANT que l'observateur ne le lise ;
   · le verrou de fond est levé TOUT DE SUITE, sans restauration — l'observateur trouvera le fond
     déjà déverrouillé et sortira sans rien faire.
   ⚠ SYNCHRONE, ET C'EST LE POINT : l'observateur de mutations est une MICRO-TÂCHE, il passe donc
   APRÈS tout ce que l'appelant fait dans la même tâche. Attendre de lui qu'il ne dérange rien est
   un pari sur un ordre d'exécution ; le couper d'avance est une propriété.
   ⚠ NE PAS L'UTILISER POUR UNE FERMETURE ORDINAIRE (✕, Échap, tap hors fenêtre) : là, rendre le
   focus au bouton d'ouverture et la position d'avant est exactement ce qu'il faut faire. */
```

## J238 — Bouton retour SYSTÈME (History API — v4.30.0, P1 de l'audit externe)

```
/* ===== Bouton retour SYSTÈME (History API — v4.30.0, P1 de l'audit externe) =====
   Aucun pushState/popstate jusqu'ici : sur Android (PWA ou navigateur), le geste retour SORTAIT
   de l'app depuis une fiche en pleine session, le lecteur, un PDF ou une feuille plein écran —
   l'écran disparaissait en pleine réanimation (les données, elles, survivaient : persistAllLive
   sur beforeunload/visibilitychange + reprise de session). Contrat Material (predictive back),
   implémenté SANS routing (cohérent monofichier) : UNE entrée SENTINELLE, ré-armée à chaque
   consommation. Le retour système emprunte le MÊME chemin que l'affordance visible — doctrine du
   gestionnaire de modales ci-dessus (« réutilise son bouton ✕, donc ses effets de bord ») :
   fenêtre du dessus, sinon lecteur, sinon schéma plein écran, sinon visionneuse d'image, sinon
   le « ‹ » d'en-tête — qui porte déjà la pile readStack ET la garde anti double-tap 700 ms : le
   retour système en hérite. À l'accueil nu : le retour SORT de l'app (on re-recule d'un cran
   par-dessus l'entrée d'origine — aucun « appui mort »). Un popstate vers l'AVANT (retour sur la
   sentinelle) ne fait que re-noter l'armement : jamais de fermeture sur un geste avant.
   scrollRestoration='manual' : les deux entrées partagent le même document, laisser le moteur
   « restaurer » un défilement entre elles ferait sauter la page (doctrine : le seul mouvement
   est le geste). */
/* ===== Guide rouge/ambre de l'éditeur : repli PERSISTANT (v4.31.0, audit externe) =====
   'toggle' ne bulle pas -> écoute en CAPTURE. Le choix de l'utilisateur survit aux re-rendus de
   l'éditeur (le markup relit la clé) et aux sessions. */
```

## J239 — MISE À JOUR VISIBLE : sw.js fait skipWaiting+claim (la nouvelle version s'installe seule),

```
    // MISE À JOUR VISIBLE : sw.js fait skipWaiting+claim (la nouvelle version s'installe seule),
    // mais jusqu'ici en silence — une version cassée pouvait remplacer la copie hors-ligne sans
    // que personne ne le sache. À son activation, le worker ENVOIE sa version (postMessage,
    // cf. sw.js) ; on la compare à APP_VERSION pour afficher le message JUSTE :
    //  - versions différentes (cas NORMAL depuis le cache-d'abord, v4.4.6 : la page en main
    //    vient du cache, donc de l'ANCIENNE version) -> bandeau persistant « Nouvelle version
    //    disponible — Recharger » : invite NON bloquante (bouton #sbReload, ✕ pour ignorer),
    //    visible SEULEMENT sur l'accueil (body.view-home, v4.20.0 — en lecture il entrait en
    //    collision avec le bandeau rouge du titre, et recharger pendant un soin n'est jamais
    //    souhaitable) ; la nouvelle version arrive de toute façon à l'ouverture suivante ;
    //  - versions égales (la page servie est déjà la nouvelle — ex. après le Recharger)
    //    -> simple snackbar « vous utilisez déjà la nouvelle version ».
    // JAMAIS de rechargement forcé : en pleine crise, on ne recharge pas l'écran sous les doigts
    // de l'utilisateur. Silencieux à la toute 1ʳᵉ installation (hadController faux).
```

