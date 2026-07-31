# Audit « jour 0 » — prise en main sans tutoriel

> **Question directrice.** Comment améliorer l'application pour qu'à J0 quelqu'un sache déjà **où
> tout se trouve** et sache déjà **ce qui est important / pas important dans une fiche** ?
>
> **Deux contraintes non négociables, rappelées ici parce qu'elles ont écarté des propositions.**
> **(1) Aucun tutoriel** — pas de visite guidée, pas d'onboarding en étapes, pas de coach marks, pas
> de bulle « astuce », pas d'écran de bienvenue à cliquer. La compréhension doit venir de la
> STRUCTURE, des MOTS, de la HIÉRARCHIE VISUELLE et des ÉTATS VIDES.
> **(2) Aucune aide cognitive livrée en plus** — les deux fiches d'exemple restent les deux seules.
>
> Audit **sans aucune modification de code**. Version auditée : **v4.79.0**, moteurs **Chromium et
> WebKit**, base **vierge** à chaque parcours, largeurs 320 / 390 / 780 / 1280 px, thèmes clair et
> sombre, passage à 130 % de taille de texte via `applyZoom(130)` (le vrai chemin de l'application,
> pas un `style.zoom` injecté).
>
> Maquettes : **[`audit-j0-maquettes.html`](audit-j0-maquettes.html)** — huit propositions, état
> mesuré à gauche, proposition à droite, tokens et corps repris d'`index.html`.

---

## 1 · Verdict en dix lignes

1. **Ce qui se comprend seul est la GÉOMÉTRIE, et elle est excellente.** Rien ne déborde, rien ne
   saute : rangée de commandes à 0 px de rognage de 320 à 1280 px, y compris à 130 % de taille de
   texte (elle s'enroule proprement, hauteur 59 → 135,5 px), CTA de démarrage visible sans défiler
   dans les huit configurations mesurées, identique sur les deux moteurs.
2. **Ce qui se comprend seul est aussi le PARCOURS PHYSIQUE** : créer sa première aide coûte
   **3 gestes**, démarrer une session **4**, retrouver une fiche par son nom **2**. Personne ne se
   perd dans l'app ; on se perd dans son vocabulaire.
3. **Ce qui ne se comprend pas, c'est le SENS DES COULEURS — le cœur même de la demande.** En vue
   lecture, le mot « vigilance » apparaît **0 fois** et le mot « critique » uniquement dans un
   `.sr-only` invisible. Le seul texte de toute l'application qui définisse ⚠ et △ vit **dans
   l'éditeur**, dans un dépliant **replié par défaut** depuis la v4.77.0.
4. **Sept symboles cohabitent à l'écran en lecture** (⚠ △ ■ ↺ ▪ → ▸) et l'application ne contient
   **aucun glossaire**, nulle part, pour aucun d'eux.
5. **Le produit explique mieux sa doctrine à une machine qu'à un soignant** : `AI_PROMPT` définit les
   deux registres, le plafond de deux étapes colorées par bloc, le format des repères posologiques,
   les complications et `onDue`. Rien de tout cela n'est jamais montré à un humain.
6. **Les deux fiches d'exemple n'exercent pas la doctrine qu'elles sont censées enseigner** :
   `posology`, `complications`, `discriminant`, `onDue`, `code` sont **vides sur les deux** ; le
   registre △ n'apparaît **qu'une fois dans tout le produit**, au **sixième geste**.
7. **Sur téléphone, un minuteur déclaré par la fiche est invisible** : session démarrée à 390 px,
   `.tm-label` visibles = **0**, quai réduit à « ● SESSION · 00:00 · ▾ ».
8. **La pilule de mode annonce « ■ CRISE » avant qu'aucune session n'ait démarré** — ouvrir une fiche
   pour la découvrir s'annonce comme un soin en cours.
9. **Le message d'ajout des exemples masque 60,7 % du seul bouton rempli de l'écran**, pendant 8 s,
   sur le trajet exact d'un J0.
10. **L'écran « Bienvenue » est précisément le dispositif que la contrainte 1 interdit** — 114 mots,
    trois paragraphes numérotés, un bouton « Commencer », plein écran sous 780 px — et il ne dit
    **rien** de où se trouvent les choses. Il est le seul endroit où le produit a essayé
    d'enseigner, et il a choisi le seul format qui ne peut pas.

---

## 2 · Parcours chronométrés

Base vierge à chaque ligne, 390 × 844, Chromium **et** WebKit (écarts < 40 ms, aucune divergence de
comportement). « Gestes » = taps réels comptés par la sonde `.j0-f.mjs`.

| # | Objectif | Gestes | ms | Où ça bloque |
|---|---|---|---|---|
| a | Créer sa première aide | **3** | 1 444 | Rien. `Commencer` → `Créer une aide cognitive` (état vide) → `Manuellement`. Le dialogue « Créer » est exemplaire : chaque voie porte une glose. |
| b | **Comprendre ⚠ vs △** | **∞** | — | **Aucune définition n'existe en lecture.** Il faut 6 gestes pour seulement *voir* un △ (Commencer → exemples → ouvrir → démarrer → Continuer → option « Non — réfractaire »), et une fois vu, rien ne le définit. Le seul texte existant est dans l'éditeur, replié. |
| c | Démarrer une session | **4** | 1 880 | Rien. Le CTA est le seul bouton rempli, visible sans défiler (y = 746 sur 844)… mais masqué à 60,7 % par la snackbar pendant 8 s (constat 7). |
| d | Partager une session | **5** | 2 323 | Entrée **unique** : menu ⋯, rangée 5 sur 12. Aucune trace ailleurs. La modale n'a pas pu s'ouvrir sans serveur (voir § 6). |
| e | Retrouver une fiche par son nom | **2** | 1 565 | Rien. Recherche fixe dans l'en-tête, `/` en raccourci, 1 résultat sur « anaph ». |
| f | Découvrir qu'un minuteur existe | **5** | 2 366 | **Le libellé du minuteur n'existe nulle part à l'écran** avant d'avoir tapé une bande de 390 × 52 px dont la seule affordance visible est « ▾ ». |

---

## 3 · Constats

Classés **du plus au moins rentable en gain-de-compréhension par ligne modifiée**.
Priorité **P1** = empêche de comprendre ou de trouver · **P2** = ralentit · **P3** = finition.

---

### 1 — L'état vide des protocoles décrit un format, jamais la différence · **P1**

- **Surface** — Accueil, onglet Protocoles, base vierge (`cfg.empty.anon`, `index.html:8422`).
- **Symptôme mesuré** — L'état vide affiche : « Aucun protocole · Ajoutez un protocole : un ou
  plusieurs PDF, et/ou un contenu rédigé dans l'app. · Créer un protocole ». Il énonce un **format
  de fichier**. Côté aides : « Aucune fiche · Créez votre première aide cognitive. » Ni l'un ni
  l'autre ne dit **en quoi les deux diffèrent**.
- **Pourquoi c'est un problème à J0** — La bascule Aides / Protocoles est le **premier objet de
  l'écran** (tab bar basse sous 780 px, sidebar au-dessus) : c'est la toute première décision que
  l'application impose, et elle l'impose sans donner le critère. Le néophyte range au hasard, puis
  cherche au hasard.
- **Correctif proposé** — Une ligne dans chaque état vide, sur le **verbe** : « Un protocole se
  **lit** (référence, procédure, PDF) — rien ne s'y coche, aucune session ne s'y déroule. » /
  « Une aide cognitive se **déroule** pendant le soin (étapes cochables, décisions, minuteurs). »
- **Coût estimé** — **2 chaînes.** Le meilleur rapport de tout l'audit.
- **Risque de régression** — Nul (deux littéraux dans `cfg`).
- **Règle AGENTS.md** — Aucune. Conforme à « un panneau vide est du bruit vise ce qui AFFIRME, pas
  ce qui INVITE » (v4.76.0).

---

### 2 — Aucune légende des registres nulle part en lecture · **P1**

- **Surface** — Vue lecture d'une aide, toutes largeurs, tous thèmes.
- **Symptôme mesuré** — À 390 px sur la fiche « Anaphylaxie » : `/vigilance/i` dans le texte de
  `#main` → **faux** ; `/critique/i` → vrai **uniquement** dans un `<span class="sr-only">`, donc
  invisible ; `document.querySelectorAll('.crit-guide').length` → **0** (le dépliant n'est émis que
  par l'éditeur de blocs, `index.html:13506`, et il est **replié par défaut** depuis la v4.77.0).
  À l'écran on lit donc, sans un mot d'explication : une boîte **rouge** à liseré et glyphe ⚠, une
  boîte **ambre** à glyphe △, une **bulle grise à chasse fixe** (la réponse attendue), un chapeau
  **rouge** « ■ NE PAS OUBLIER ».
- **Pourquoi c'est un problème à J0** — C'est la question posée. La doctrine du produit tient en
  deux phrases (⚠ = ce qui tue si on l'oublie · △ = là où l'on se trompe) et ces deux phrases sont
  écrites **trois fois** dans le dépôt — `AGENTS.md`, `AI_PROMPT`, le `title` du bouton bascule de
  l'éditeur — dont **zéro fois** là où un soignant les rencontre. La couleur n'est pas seule (le
  glyphe est là, règle 8 tenue), mais un glyphe sans clé n'est qu'une seconde couleur.
- **Correctif proposé — révisé après mesure, voir l'encadré ci-dessous.** La légende **chevauche le
  titre de section « PARCOURS »**, qui existe déjà et dont la ligne est presque vide :
  `PARCOURS  ⚠ vital · △ à vérifier`, au corps du titre lui-même (11 px / 800, l'un des sept
  paliers de l'échelle fermée). **Coût de hauteur : 0 px.** Une fois par fiche, pas une fois par
  bloc. Maquette **C1**.
- **Coût estimé** — ~4 lignes (concaténation dans le titre de section), plus l'extraction en table
  partagée (constat 15).
- **Risque de régression** — Faible : rien n'est inséré dans le flux, une chaîne est ajoutée à une
  ligne existante. À re-mesurer si un jour le titre de section s'allonge.

> #### Pourquoi la première version de ce correctif a été abandonnée — mesure
>
> La proposition initiale était un `<details>` replié en tête de **chaque** bloc portant une étape
> signalée. Mesuré en injectant le DOM proposé dans l'application vivante, sur la fiche d'exemple,
> session démarrée :
>
> | Variante | 320 px | 390 px | 390 px @ 130 % |
> |---|---|---|---|
> | **V1** — dépliant complet (cadre, cible 44 px, 3 entrées) | **+65,6 px** | **+65,6 px** | **+85,6 px** |
> | **V2** — même dépliant, 2 entrées | +56 px | +56 px | +72,8 px |
> | **V3** — ligne **nue** (ni cadre, ni fond, ni cible 44 px) | +41,6 px (2 lignes) | **+24,8 px** (1 ligne) | +54 px |
> | **V4** — la légende **sur la ligne « PARCOURS »** | **0 px** | **0 px** | **0 px** |
>
> **⚠ MISE À JOUR — décision A4 de [`transition-v4.md`](transition-v4.md).** V4 n'a finalement pas
> été retenue : la légende vit **dans la carte du bloc, inconditionnellement**, et coûte ses 23 px.
> Deux raisons. **(1)** Le modèle v4 n'a plus de titre de section « PARCOURS » à chevaucher.
> **(2)** Une variante conditionnelle a été essayée puis abandonnée : le test « le bloc porte-t-il
> un ⚠ ou un △ ? » était faux, car la **bulle** (réponse attendue) apparaît aussi sur des items de
> niveau 1. Une légende qui ne paraît que là où l'on sait déjà lire n'enseigne plus rien.
>
> Sur un bloc de 722 px à 320 px, V1 coûtait **9 % de la carte**, et le coût se **répétait par
> bloc**. L'erreur de conception est nommable : j'avais fait de la légende un `<details>`, donc un
> **contrôle** — d'où le plancher de 44 px, le cadre et les marges. **Une légende n'est pas un
> contrôle** : si elle ne s'ouvre pas, elle n'a pas à être tapable, et l'essentiel tient de toute
> façon dans son résumé.
>
> Largeurs mesurées au corps du titre (11 px / 800) : « ⚠ vital · △ à vérifier » = **132 px**
> (171 px à 130 %) ; « ⚠ vital · △ à vérifier · bulle = réponse attendue » = 311 px (404 à 130 %).
> Le titre « PARCOURS » occupe ~70 px, les conteneurs font 251 / 321 / 300 / 382 px
> (320 / 390 / 390 @130 % / 780). **La version à deux entrées passe partout ; la version à trois
> entrées ne passe nulle part** — d'où le renoncement à énoncer là la bulle « réponse attendue ».
> Elle est reportée sur le mode lecteur, qui la nomme déjà (« Répondu — conforme ✓ »), et sur la
> légende du plan (constat 4).
>
> Variante écartée mais mesurée, à garder en réserve : le **mot dans l'étape** (`⚠ VITAL ·
> Adrénaline IM…`). Coût **0 px à 320 et 390 px** — le mot se loge dans l'enroulement existant —
> mais **+31,1 px à 130 %**, et il se répète sur chaque étape signalée en concurrençant le texte
> clinique. Moins bon que V4 pour un gain identique.
- **Règle AGENTS.md** — 8 (renforcée, pas contredite) · 9 (12 px ≥ plancher) · 11 (dans le flux,
  aucune modale, aucun mouvement).

---

### 3 — Les deux fiches d'exemple n'exercent pas la doctrine qu'elles enseignent · **P1**

- **Surface** — `seed()` et `seed2()` (`index.html:6390` et `:6412`), les deux seuls objets
  cliniques qu'un J0 rencontre.
- **Symptôme mesuré** (lecture statique du code, confirmée à l'exécution) :

  | Mécanisme | Anaphylaxie | ACR |
  |---|---|---|
  | étapes ⚠ | 2 | 3 |
  | étapes △ | **1** (bloc « Réfractaire », 6ᵉ geste) | **0** |
  | « :: » | 4 | 7 |
  | décision | 1 | 1 (rebouclée) |
  | `posology` | **0** | **0** |
  | `complications` | **0** | **0** |
  | `discriminant` | **vide** | **vide** |
  | `onDue` | **vide** | **vide** |
  | `code` | **vide** | **vide** |
  | `images`, `related`, `stopwatch` | 0 | 0 |

  Autrement dit : le registre ambre existe **une fois dans tout le produit**, la feuille
  « Consulter » n'y contient que deux sections sur cinq, le bouton ⚡ Complications n'apparaît
  jamais, et l'alarme d'un minuteur ne peut jamais dire quoi faire.
- **Pourquoi c'est un problème à J0** — Ces deux fiches **sont** le matériel pédagogique, puisque
  aucun autre n'est autorisé. Elles montrent aujourd'hui le tiers des mécanismes de l'application,
  et pas ceux qui la distinguent. Pire, mesuré : elles ne respectent pas les règles que
  `AI_PROMPT` **impose à une IA** (posologie obligatoire dès qu'il y a un médicament dosé, `onDue`
  dès que le délai commande un geste, `discriminant` jamais dans le titre).
- **Correctif proposé** (contenu seul — c'est explicitement autorisé, ce n'est pas ajouter une
  fiche) : `discriminant: 'adulte'` sur les deux ; un repère `posology` sur l'Anaphylaxie —
  l'exemple est **déjà rédigé** dans `AI_PROMPT` : `△ **ADRÉNALINE — IM** : adulte 0,5 mg · enfant
  0,01 mg/kg (max 0,5 mg)` ; un `onDue` par minuteur (« Réévaluation : PA, respiration,
  urticaire » / « Analyse du rythme + relais adrénaline ») ; **une** complication sur l'Anaphylaxie
  (« Bronchospasme réfractaire » → bloc hors séquence) ; **une** étape △ dans le **premier** bloc
  de l'ACR, pour que l'ambre existe au premier écran. Maquette **C6**.
- **Coût estimé** — ~15 lignes de données, zéro ligne de logique.
- **Risque de régression** — **Réel et à vérifier** : plusieurs harnais ouvrent la fiche d'exemple
  et comptent ses blocs/étapes (`audit-doctrine`, `audit-consulter`, `audit-complications`,
  `audit-lecteur`, `audit-k5`). Ajouter une complication fait **apparaître** le bouton ⚡ et la
  section « ⚡ À tout moment » ; ajouter une posologie fait apparaître une section dans le rail et
  la feuille Consulter. À rejouer intégralement (`npm run audit`, deux moteurs) avant livraison.
- **Règle AGENTS.md** — 12 (aucun champ retiré, seulement remplis) · doctrine posologie ambre
  (v4.23.0 : `△`, **jamais** `⚠`) · plafond de 2 étapes colorées par bloc (`AI_PROMPT`).

---

### 4 — Les abréviations de « Se repérer » n'ont aucune clé · **P1**

- **Surface** — Feuille « Se repérer » (`planModal`), colonne `.read-plan` du cockpit ≥ 1200 px,
  rail droit ≥ 780 px — c'est-à-dire la vue qui répond littéralement à « où tout se trouve ».
- **Symptôme mesuré** — Texte réel de `.read-plan` à 1280 px sur la fiche d'exemple :
  `PLAN — ÉCHELLE | 4 | complet | 1 | Mesures immédiates ICI | 0/5 →2 | 2 | Réévaluation |
  OUI→4 NON→3 | NON › | 3 | Réfractaire | 0/4 ↺2 | 4 | Stabilisé | 0/3 ▪fin`.
  Recherche « légende / glossaire / signification » dans `index.html` : **aucune occurrence
  destinée à l'utilisateur** (les seules concernent les légendes d'images).
- **Pourquoi c'est un problème à J0** — `↺2` et `▪fin` ne sont devinables par personne. Et il
  manque, en plus des symboles, **la propriété la plus contre-intuitive de l'écran** : ce plan est
  **inerte**, rien ne s'y coche (décision doctrinale re-confirmée deux fois). Un néophyte qui tape
  une case et ne voit rien se passer conclut à une panne, pas à une carte.
- **Correctif proposé** — On garde les abréviations (elles existent parce que la colonne fait
  240 px) et on ajoute (a) un `title` en toutes lettres par abréviation, produit par la fonction
  `optAbbr` qui les fabrique déjà, et (b) **une ligne en pied de panneau** :
  « `→` mène à · `↺` revient à · `▪fin` fin du parcours · `0/5` étapes cochées. Ce plan est une
  **carte** : rien ne s'y coche. » Maquette **C2**.
- **Coût estimé** — ~4 lignes.
- **Risque de régression** — Faible ; la ligne est en pied, hors de la zone d'ancrage. À vérifier à
  240 px de large (colonne cockpit), où elle passera sur trois lignes — c'est acceptable, c'est un
  pied.
- **Règle AGENTS.md** — Aucune. Cohérent avec « une zone d'état annonce ce qu'elle cache » (quai).

---

### 5 — L'état vide des aides est le meilleur emplacement pédagogique du produit, et il est muet · **P1**

- **Surface** — Accueil, bibliothèque vide (`emptyHtml`, `index.html:8247`).
- **Symptôme mesuré** — À 390 × 844, base vierge, après « Commencer » : le bloc `.empty` occupe
  (18, 427) 354 × 222,8 px — soit **26 % de la hauteur d'écran** — et porte 8 mots :
  « Aucune fiche · Créez votre première aide cognitive. » plus le bouton. Au-dessus, la notice de
  responsabilité et le bandeau « Besoin d'exemples ? » (bouton visible, 212,8 × 38 px).
- **Pourquoi c'est un problème à J0** — Sous la contrainte « aucun tutoriel », les états vides sont
  **les seuls professeurs autorisés**. Celui-ci est vu par 100 % des utilisateurs, au moment exact
  où ils se demandent ce que l'application fabrique, il dispose de 222 px et il n'enseigne rien.
- **Correctif proposé** — Cinq lignes glyphe + mot + conséquence, **reprises telles quelles de la
  porte « ＋ »** de l'éditeur (voir constat 15) : ❑ des étapes qu'on coche · ◆ des décisions qui
  aiguillent · ⚠ rouge : ce qui tue si on l'oublie · △ ambre : là où l'on se trompe · ⏱ minuteurs
  et compteurs pendant la session. Maquette **C3**.
- **Coût estimé** — ~6 lignes si la table partagée existe (constat 15), ~14 sinon.
- **Risque de régression** — Faible. À re-mesurer à 320 × 640, où l'état vide passerait sous le pli
  — acceptable : le bouton reste au-dessus.
- **Règle AGENTS.md** — Aucune. C'est l'application de la doctrine de la porte « ＋ » (v4.65.0 :
  « c'est là que les registres s'apprennent, avant la crise ») à la surface d'avant l'éditeur.

---

### 6 — ~~Sur téléphone, le minuteur et le compteur d'une fiche sont invisibles~~ · **CONSTAT RETIRÉ**

> **Ce constat était FAUX, et la faute vient de mon instrument.** Retiré le 30/07/2026, à
> l'implémentation du lot T2, en même temps que la règle N7 qu'il avait engendrée.

- **Ce que j'avais mesuré** — `.tm-label` visibles = 0, session démarrée, 390 px. Exact, et sans
  portée : `.tm-label` est le libellé d'une **carte** de minuteur, qui n'existe que **panneau
  ouvert**. Compter à zéro un objet qui ne peut pas exister dans l'état mesuré ne prouve rien.
- **Ce que l'application fait RÉELLEMENT** — la rangée `.rt-collapsed` porte, dans le flux,
  « **Minuteurs & compteurs · 1 minuteur · 1 compteur ▾ Afficher** ». Mesuré sur « Anaphylaxie »,
  session démarrée : **y = 494 px pour un pli à 844** (390 px de large) — donc **visible sans
  défiler** ; à 320 × 640, y = 553, soit juste sous le pli. Le correctif que je proposais existait
  déjà, dans le flux plutôt que dans le quai.
- **Conséquence sur la suite** — la règle **N7** (« le quai nomme ce que la fiche déclare ») est
  **retirée**. L'appliquer aurait **dupliqué une constante sur deux canaux** — ce que la v4.70.1
  proscrit explicitement (« la barre dit le mode, le bandeau dit l'exception ») — pour rendre
  permanente une information déjà donnée à sa place.
- **Leçon de méthode, et c'est le vrai contenu de ce constat** — un compte à zéro n'est une preuve
  d'absence que si l'objet compté **pouvait exister** dans l'état mesuré. Même famille que le
  garde-fou qui ne rencontre pas son défaut (v4.31.1) et que le contrôle mesurant un nœud détaché
  (v4.78.0) : ici, c'est la SONDE qui ne rencontrait pas son sujet.
---

### 7 — Le message d'ajout des exemples masque 60,7 % de l'action primaire · **P2**

- **Surface** — Snackbar d'`addSeedFiches` (8 000 ms), vue lecture, 390 × 844.
- **Symptôme mesuré** — Sur le trajet exact d'un J0 (taper « Ajouter les fiches d'exemple », puis
  ouvrir une fiche dans les 8 s) : snackbar (98, 717) 195 × 107 px, bouton « Confirmé — démarrer la
  session » (51, 746) 321 × 50 px. **Recouvrement 9 750 px², soit 60,7 % du bouton**, libellé
  compris. Vérifié aussi sur le bouton « Continuer — … (5) » après démarrage.
- **Pourquoi c'est un problème à J0** — C'est le seul bouton rempli de l'écran, sur le seul écran
  qui compte, au seul moment où l'utilisateur ne sait pas encore ce qu'il cherche.
- **Correctif proposé** — Le message n'est pas urgent : c'est une **information à acquitter**, donc
  le registre `#sysBanner` (INFORMATION, bord gauche 4 px, dans le flux de l'accueil) plutôt qu'une
  notification flottante. Variante minimale à **une ligne** : durée 8 000 → 3 500 ms — réduit la
  gêne sans la supprimer. Maquette **C7**.
- **Coût estimé** — 1 ligne (durée) ou ~6 (bandeau).
- **Risque de régression** — Nul pour la durée. Le bandeau n'apparaît que sur l'accueil
  (`body.view-home`), ce qui est déjà sa règle.
- **Règle AGENTS.md** — 11 (« en session, aucune notification flottante ») : ici on est **hors**
  session, la règle n'est pas enfreinte — mais son motif (ne rien imposer sur l'écran d'action) est
  exactement ce qui est en jeu.

---

### 8 — « Lecteur » et « Vérifier » nomment des outils, pas des gestes · **P3** — ⚠ **sans objet en v4**

> **Mise à jour.** Dans le modèle v4, ces deux boutons **n'existent plus** : le lecteur devient le
> cran « Une étape » de l'axe de densité, et la passe de vérification y est intégrée (« Répondu —
> conforme ✓ » / « △ Écart »). Le constat est conservé pour sa mesure — la ligne d'état s'enroule
> déjà à 320 px — mais son correctif est caduc.

- **Surface** — Ligne d'état du bloc courant (`.ov-here` + deux boutons), session démarrée.
- **Symptôme mesuré** — Libellés à l'écran : « ⤢ Lecteur » et « Vérifier ». Le menu ⋯ porte
  pourtant, à trois centimètres de là, la grammaire correcte : « Mode lecteur (binôme) »,
  « Consulter — surveillances, documents… », « Répéter en exercice — aucune trace clinique ».
- **Pourquoi c'est un problème à J0** — « Vérifier » lance une **seconde passe complète sur le
  bloc, à deux voix**, avec ses propres verdicts (« Constaté ✓ » / « △ Écart ») — c'est la fonction
  la plus doctrinale du produit (Do-Verify) et la moins nommée. Personne ne l'essaie par curiosité
  en pleine session : le mot ne promet rien.
- **Correctif proposé — révisé après mesure. Renommer sur place, JAMAIS sous-titrer.** Le sous-mot
  de 11 px est abandonné (encadré ci-dessous). Il reste deux options, toutes deux sur **une seule
  ligne**, plus le repli :
  - **(a) recommandée, minimale** — « Vérifier » → « **Revérifier** » (+14 px seulement), et
    l'explication complète en `title` + `aria-label` (« 2ᵉ passe du bloc, à deux voix »). « Lecteur »
    est laissé tel quel : il est déjà glosé dans le menu ⋯ (« Mode lecteur (binôme) »).
  - **(b) plus explicite, plus chère** — « ⤢ Lecteur » → « **Lire à deux** » (+10 px) et
    « Vérifier » → « **Revérifier** » (+14 px). Les deux tiennent sur une ligne à 390 px
    (173 px pour 191 disponibles) ; à 320 px la rangée s'enroule — **comme elle le fait déjà**.
  - **(c)** statu quo assumé, `title` seul. **Le gain de (a) et (b) est modeste** : c'est un
    constat P3, il est parfaitement défendable de le laisser tomber.
- **Coût estimé** — 1 à 2 chaînes.
- **Risque de régression** — Faible pour (a) : +14 px sur une rangée dont l'enroulement est déjà
  géré depuis la v4.73.1. À re-mesurer à 320 px et à 130 % dans les deux cas.
- **Règle AGENTS.md** — La ligne d'état de la v4.56.3 (−52 px par bloc) : **ne pas la regonfler**,
  c'est exactement ce que le sous-titre faisait.

> #### Pourquoi le sous-titre sur deux lignes est abandonné — mesure
>
> Injecté dans l'application vivante, ligne d'état du bloc courant, session démarrée :
>
> | | 320 px | 390 px | 390 px @ 130 % |
> |---|---|---|---|
> | Largeur de la rangée | 246 px | 316 px | 294 px |
> | Pilule « VOUS ÊTES ICI » | 109 px | 109 px | 142 px |
> | **Place restante pour les deux boutons** | **121 px** | 191 px | **136 px** |
> | Largeur réclamée par les deux boutons actuels | **155 px** | 155 px | **200 px** |
> | Hauteur de la rangée, aujourd'hui | **106 px (enroulée)** | 54 px | **104,6 px (enroulée)** |
> | Hauteur avec les sous-titres | **132,5 px** | — | — |
>
> Deux enseignements. **(1) La rangée déborde déjà** à 320 px et à 130 % — 155 px réclamés pour
> 121 disponibles : le sous-titre n'a pas créé le problème, il l'a aggravé de **26,5 px** et, à la
> capture, chaque bouton se retrouve **seul sur sa ligne, ferré à gauche** : c'est bien laid, votre
> objection est exacte. **(2) Le budget interdit d'ajouter du texte, mais pas d'en changer.**
> Largeurs mesurées, padding compris : `Vérifier` 69 · `2ᵉ passe` 75 · `Revérifier` 83 ·
> `Contre-vérifier` 114 · `⤢ Lecteur` 80 · `Lire à deux` 90 · `Lecteur à deux` 113.
> Un mot plus juste coûte 10 à 14 px ; une seconde ligne en coûte 26,5 et casse l'alignement.

---

### 9 — Le badge « △ À compléter » accuse sans dire où · **P2**

- **Surface** — Rangées du répertoire et méta de lecture, sur les **deux** fiches d'exemple.
- **Symptôme mesuré** — À J0, les deux rangées lisent : « Anaphylaxie (choc anaphylactique) · △ À
  compléter · Urgences · 01/2025 ». La cause est correcte (`references` et `localInfo` contiennent
  la chaîne « à compléter »), l'infobulle `completionSpots` existe — **mais elle est inatteignable
  au doigt**, et c'est un téléphone.
- **Pourquoi c'est un problème à J0** — Le premier et le seul matériel pédagogique se présente
  comme défectueux, sans dire en quoi. Le message de fond est juste et doit rester (ces fiches
  **doivent** être adaptées) ; c'est son actionnabilité qui manque.
- **Correctif proposé** — Le badge porte son compte (« △ À compléter · 2 ») et la rangée de méta de
  la vue lecture liste les emplacements — **hors session seulement**, où elle est déjà masquée
  (v4.31.0), donc à coût nul en crise.
- **Coût estimé** — ~4 lignes ( `completionSpots` est déjà écrite et testée).
- **Risque de régression** — Faible.
- **Règle AGENTS.md** — Taxonomie des notices (ambre = « on risque de se tromper » : juste ici).

---

### 10 — La pilule de mode annonce « ■ CRISE » avant toute session · **P2**

- **Surface** — `#hdrCrisis`, en-tête, dès l'ouverture d'une aide.
- **Symptôme mesuré** — Fiche ouverte, **rien démarré** : `#hdrCrisis` = « ■ CRISE », visible,
  pendant que `#sessStart` (« Confirmé — démarrer la session ») est encore à l'écran et que
  `#cbTimers` est masqué. Le libellé est **strictement identique** avant et après démarrage.
- **Pourquoi c'est un problème à J0** — Le premier réflexe d'un néophyte est d'ouvrir une fiche
  pour **regarder**. L'application lui répond « crise », en rouge, en capitales. Deux effets : elle
  décourage l'exploration, et elle **use le rouge** — exactement ce que la doctrine du bandeau blanc
  refuse par ailleurs (« un bandeau d'état permanent teinté en rouge désensibilise au rouge »).
- **Correctif proposé** — Un mot par état, **même place, même corps, même permanence** :
  « ▫ Lecture » (registre neutre) avant démarrage, « ■ Crise » après. Maquette **C5**.
- **Coût estimé** — ~3 lignes.
- **Risque de régression** — Le changement de mot change la largeur de la pilule ; à re-mesurer à
  320 px, où `#crisisCtrl` n'a que 2,1 px de marge, et sur `audit-partage`, qui mesure le coût en
  hauteur des placards.
- **Règle AGENTS.md** — **Rouvre explicitement les v4.58.0 / v4.70.1** (« `#hdrCrisis` est le seul
  énoncé du mode, permanent et immobile »). La proposition respecte la **place** et la
  **permanence**, et amende la **constance du mot** — ce que ces versions n'avaient jamais examiné,
  puisqu'elles arbitraient une redondance entre deux surfaces, pas une justesse d'état. **Décision
  à trancher (§ 4).**

---

### 11 — Le menu ⋯ porte douze rangées avant qu'une session existe · **P3**

- **Surface** — `#moreMenu`, vue lecture.
- **Symptôme mesuré** — **Avant** toute session : 12 rangées, hauteur 583 px (plafond calculé
  768 px), aucune désactivée, « Mode lecteur (binôme) » en tête et « Recommencer le parcours —
  repart du début » alors que rien n'a commencé. **Pendant** une session : 14 rangées, 686 px,
  3 désactivées.
- **Pourquoi c'est un problème à J0** — Un menu de douze rangées est l'endroit où les
  fonctionnalités se cachent les unes des autres, et « Partager la session » (parcours d) n'a que
  celui-là. Les gloses sont excellentes ; c'est leur **nombre simultané** qui coûte.
- **Correctif proposé** — Appliquer la règle « aucun bouton mort » déjà en vigueur ailleurs (le
  lien Historique du pied est masqué à zéro session) : masquer avant démarrage ce qui n'a pas
  d'objet (« Recommencer le parcours »). **Ne rien masquer d'autre sans mesure** — « Mode lecteur »
  démarre légitimement la session.
- **Coût estimé** — ~2 lignes.
- **Risque de régression** — `setMoreMenu` normalise déjà les séparateurs d'un groupe vide.
- **Règle AGENTS.md** — Ordre ECAM du menu (conservé) · « aucun bouton mort ».

---

### 12 — « Cons. » sur toute la gamme téléphone · **P3**

- **Surface** — `#crisisCtrl`, bouton d'ouverture de la feuille Consulter.
- **Symptôme mesuré** — Libellés relevés : « Cons. » à **320, 390 et 430 px** ; « Consulter » à
  partir de **560 px**. Sur la totalité des largeurs de téléphone, donc, le bouton qui contient les
  diagnostics différentiels s'appelle « Cons. ».
- **Pourquoi c'est un problème à J0** — La doctrine défend cette troncature (« troncature du même
  mot, jamais un autre mot ») et elle a raison contre « Réf. » ; mais « Cons. » n'est pas un mot
  tronqué reconnaissable, c'est un mot absent. Or `AGENTS.md` écrit lui-même que **ce sont les
  différentiels qui justifient ce bouton** et que « le pire mode de défaillance serait un nom qui
  décourage l'usage qui compte ».
- **Correctif proposé** — Trois options, à trancher : (a) retirer le glyphe ⤢ sous 560 px (~17 px
  récupérés d'après la recette de la v4.57.0) pour faire tenir « Consulter » ; (b) garder « Cons. »
  et vérifier que l'`aria-label` porte le mot entier ; (c) statu quo assumé.
- **Coût estimé** — ~2 lignes (a) · 1 (b).
- **Risque de régression** — (a) touche la rangée la plus mesurée du dépôt : re-jouer
  `audit-doctrine` à 320/360/375/390/430/460 **et** aux quatre tailles de texte.
- **Règle AGENTS.md** — Troncature du même mot (v4.25.0) · rangée de commandes (v4.43.0, v4.73.1).
  **Décision à trancher (§ 4).**

---

### 13 — L'écran « Bienvenue » est le seul dispositif interdit par la contrainte, et il n'enseigne rien · **P3** (mais structurant)

- **Surface** — `#welcomeModal`, premier démarrage, une seule fois (`ac-onboarded`).
- **Symptôme mesuré** — Ouvert d'office à toutes les largeurs. **114 mots**, trois paragraphes
  numérotés, un bouton « Commencer ». À 320 et 390 px la carte occupe **100 % de la hauteur de
  fenêtre** (0 → 640 / 0 → 844), sans défilement ; à 780 et 1280 px, 355,5 px centrés. Contenu :
  responsabilité éditoriale, non-interruption du mode crise, localité des données. **Aucune
  mention** de où se trouve quoi que ce soit.
- **Pourquoi c'est un problème à J0** — C'est le seul endroit où le produit a tenté d'enseigner, et
  il a choisi le format que la contrainte 1 interdit — celui qu'on clique une fois et qu'on ne
  revoit jamais, au moment précis où l'on n'a encore rien vu à quoi rattacher les phrases.
- **Correctif proposé** — **Garder** le paragraphe 1 (responsabilité éditoriale : c'est une mention
  réglementaire, cf. `docs/deploiement-et-conformite.md` § 2, ce n'est pas de la pédagogie) et
  **déplacer** les paragraphes 2 et 3 vers les surfaces qui les portent naturellement : la
  non-interruption s'apprend en session, la localité des données est **déjà** écrite en pied
  d'accueil (« Cet appareil seulement · 3,5 Mo · non protégé », mesuré). Le reste de l'enseignement
  passe par les constats 1 à 5.
- **Coût estimé** — ~10 lignes retirées.
- **Risque de régression** — Vérifier avec le registre RGPD que rien de ce qui est retiré n'y est
  engagé.
- **Règle AGENTS.md** — Aucune. **Décision à trancher (§ 4)** : la mention réglementaire est du
  ressort de l'auteur, pas de l'audit.

---

### 14 — Sept symboles à l'écran, zéro glossaire dans le produit · **P3** (constat transverse)

- **Surface** — Toutes.
- **Symptôme mesuré** — En vue lecture à 1280 px, présents **simultanément** dans le texte rendu :
  `⚠ △ ■ ↺ ▪ → ▸`. En comptant les surfaces adjacentes : `● ✓ ⚡ ⤢ ⠿ ◆ ❑ № ⇄ ▲ ::`. Recherche d'un
  glossaire utilisateur : **aucune**.
- **Pourquoi c'est un problème à J0** — Pris un par un, chaque symbole a une bonne raison d'être et
  presque tous sont accompagnés d'un mot quelque part. Pris ensemble, ils forment une **langue**
  que le produit n'enseigne nulle part, et dont la maîtrise est justement ce qui sépare le J0 du
  J30.
- **Correctif proposé** — **Ne pas** créer de page « glossaire » (elle ne serait jamais ouverte).
  Les constats 2, 4 et 5 couvrent les six symboles qui portent du sens clinique, là où ils
  apparaissent. Le reste peut rester non légendé.
- **Coût estimé** — Nul en propre (couvert par 2, 4, 5).
- **Règle AGENTS.md** — 8.

---

### 15 — La porte « ＋ » est le meilleur professeur du produit, et elle est enfermée dans l'éditeur · **P3** (habilitant)

- **Surface** — `edAddModal` (v4.65.0).
- **Symptôme mesuré** — Texte intégral relevé : quatre groupes, **treize types**, chacun avec un
  glyphe, un nom et une conséquence de deux à quatre mots — « Bloc d'étapes / titre, puis ⏎ » ·
  « Décision oui / non / 2 branches » · « Compteur / chocs, doses… » · « Complication / à tout
  moment » · « Doses & seuils / consulté, pas coché » · « À vérifier / surveillances, pièges » ·
  « Diagnostic différentiel / si le tableau ne colle pas » · « Document PDF / rangé dans
  “Consulter” ». C'est **exactement** le vocabulaire qu'un lecteur J0 a besoin d'acquérir, et il
  n'est atteignable que depuis l'éditeur.
- **Correctif proposé** — Extraire ces chaînes dans **une table unique** (`AC_LEX`), consommée par
  la porte (inchangée à l'écran), par la légende des registres (constat 2) et par les états vides
  (constats 1 et 5). **Source unique** : aucune copie à tenir accordée — c'est précisément le motif
  qui a coûté deux bugs au dépôt (`MUTE_SEL`/`LEAD_ONLY_SEL`, liste des placards v4.78.0).
- **Coût estimé** — ~20 lignes de réorganisation, zéro changement visible sur la porte.
- **Risque de régression** — Faible si la porte est rendue depuis la table sans changer une
  chaîne ; `audit-a11y` couvre déjà `edAddModal`.
- **Règle AGENTS.md** — 14 (hygiène) · doctrine « une seule grammaire » (I4, v4.62.0).

---

## 4 · Décisions à trancher par l'utilisateur

Une par ligne : ce qui touche un token, un palier, un champ modèle, un libellé opposable, ou ce qui
ouvre un chantier. **Recommandation d'abord, option inverse ensuite.**

| # | Décision | Recommandé | Option inverse |
|---|---|---|---|
| D1 | **Enrichir les deux fiches d'exemple** (constat 3) — posologie, complication, `onDue`, `discriminant`, une étape △ au premier écran | **Oui.** C'est le seul levier autorisé qui rende visibles six mécanismes d'un coup, sans une ligne de logique | Laisser les fiches minimales et n'enseigner que par les légendes (constats 2, 4, 5) : moins de risque sur les harnais, mais l'ambre et le ⚡ restent invisibles à J0 |
| D2 | **La pilule de mode change de mot** (constat 10) — rouvre v4.58.0/v4.70.1 | **Oui**, en gardant place et permanence : le rouge retrouve sa valeur | Statu quo : un seul mot, jamais de doute sur *où* regarder, au prix d'un rouge qui ne dit plus rien |
| D3 | **Le chevron du quai porte « n minuteur · n compteur »** (constat 6) — le jeu de jetons du quai est déclaré FERMÉ | **Oui** : ce n'est pas un jeton de plus, c'est l'habillage d'un chevron existant | Statu quo, et régler le problème par le rail seul — mais le rail n'existe pas sous 780 px, donc pas sur le téléphone |
| D4 | ✅ **RÉSOLU AUTREMENT** — l'axe de densité libère la rangée : « Consulter » s'affiche entier dès 320 px (vérifié dans proto-r4). ~~« Consulter » entier sous 560 px, au prix du glyphe ⤢~~ | **Oui**, option (a) — le nom est le seul canal qui décide de l'ouverture | Garder « Cons. » : la doctrine de troncature est tenue, la rangée n'est pas retouchée |
| D5 | **Réduire l'écran de bienvenue au seul paragraphe réglementaire** (constat 13) | **Oui** — c'est la contrainte 1 appliquée au produit lui-même | Le garder tel quel : trois paragraphes valent mieux que zéro, même mal placés |
| D6 | **Snackbar des exemples → bandeau système** (constat 7) | **Bandeau.** Le message n'est pas urgent et concerne la sécurité clinique du contenu | Simple réduction de durée à 3 500 ms : une ligne, aucun risque, gêne réduite mais non supprimée |
| D7 | **Extraire `AC_LEX`** (constat 15) — refactor sans effet visible | **Oui**, en préalable aux constats 2 et 5 | Écrire les chaînes deux fois : plus rapide aujourd'hui, divergence garantie plus tard |
| D8 | **Corriger `AGENTS.md`** — deux affirmations relevées comme périmées, non corrigées ici (voir § 6) | À faire à part | — |

---

## 5 · Écarté par contrainte

Cinq propositions écartées d'office, dites ici parce qu'elles ont été formées avant d'être rejetées :

- **Une visite guidée en quatre bulles** sur la première ouverture d'une fiche (« ceci est le
  chapeau », « ceci est le rail ») — c'est la définition même de ce que la contrainte 1 interdit,
  et elle enseignerait des noms plutôt que des sens.
- **Une troisième fiche d'exemple « Fiche de démonstration »** qui exercerait tous les mécanismes en
  une fois — interdit par la contrainte 2, et de toute façon inférieur à l'enrichissement des deux
  existantes, qui sont cliniquement crédibles.
- **Un protocole d'exemple** (la moitié « Protocoles » n'a aujourd'hui aucun matériel) — même
  interdiction. Remplacé par le constat 1 : l'état vide dit la **différence** au lieu de la montrer.
- **Un coach mark sur le quai** pour révéler les minuteurs au premier démarrage — remplacé par le
  constat 6, qui rend l'information **permanente** au lieu de la donner une fois.
- **Une page « Aide / Glossaire »** dans le menu ⋯ — écartée sur le fond autant que par la
  contrainte : une page d'aide est le lieu où l'on range ce qu'on n'a pas su rendre évident, et
  personne ne l'ouvre. Remplacée par les légendes locales des constats 2 et 4.

---

## 6 · Ce que je n'ai pas pu mesurer

Angles morts déclarés, plutôt qu'un vert de complaisance.

1. **La fenêtre de partage côté hôte** (`shareModal`) — elle exige un backend Supabase joignable ;
   la sonde a bien ouvert la rangée du menu mais aucune modale n'est apparue. **Le code du partage
   n'a donc pas été audité à l'écran** : seuls le parcours d'accès (5 gestes, menu ⋯) et l'écran
   invité l'ont été.
2. **L'écran invité au-delà de sa première image** — `#joinScreen` s'affiche bien sur base vierge
   avec `#j=CODE` (texte relevé : notice, champ code, `<select>` de neuf rôles, dépliant « Ce qui
   est enregistré, et par qui »). **Il est, à ma lecture, la meilleure surface pédagogique du
   produit.** La jointure réelle, les rôles lead/scribe, le lien coupé et « continuer seul » n'ont
   pas pu être joués.
3. **La visionneuse PDF, les vignettes et le badge « △ à télécharger »** — aucun document n'est
   livré et je n'en ai pas importé (l'audit devait rester sans effet de bord).
4. **Le QR** — `audit-qr` le décode via CoreImage ; je ne l'ai pas rejoué.
5. **Le compte, la synchronisation, les bibliothèques partagées, l'historique synchronisé, les
   versions, l'import/export ZIP** — hors de portée sans compte ni serveur.
6. **`forced-colors` (Windows High Contrast) et `prefers-contrast: more`** — non mesurés ; la
   doctrine note d'ailleurs que le premier n'a jamais été validé sur machine Windows réelle.
7. **Un vrai lecteur d'écran (VoiceOver / NVDA)** — je n'ai lu que le DOM. Le constat 2 s'appuie sur
   la présence d'un `.sr-only`, pas sur ce qu'un utilisateur de VoiceOver entend réellement.
8. **Un appareil iOS réel en PWA installée** — le dossier « bande basse iOS » montre que certains
   défauts n'y sont visibles nulle part ailleurs.
9. **Le mode moniteur, le mode exercice et le compte-rendu** n'ont été vus qu'à 390 px, en un seul
   passage (textes relevés, pas d'analyse fine) : moniteur = « 00:03 · TAP = REVENIR ·
   Réévaluation après adrénaline · 05:00 · Aucun repère horodaté » ; exercice = bandeau hachuré
   « ▲ EXERCICE » + « Quitter l'exercice… », correct et lisible ; carte-bilan = « Session terminée —
   … · 00:01 · 0/1 bloc ✓ · Compte-rendu ».
10. **Un vrai néophyte.** Tout ce rapport est une mesure de l'interface, pas une observation
    d'usage. Les six parcours du § 2 comptent des gestes, pas des hésitations — le seul chiffre
    qu'aucune sonde ne produit.

### Deux contradictions relevées dans `AGENTS.md` (signalées, **non corrigées**, conformément à la consigne)

- La section « Se repérer dans `index.html` » annonce « ~14 400 lignes » ; le fichier en compte
  **18 540**.
- La même section annonce « **57** bannières `/* ===== … ===== */` » ; le `grep` qu'elle propose
  elle-même en renvoie **61**. (Le compte de fenêtres modales, lui, est exact : **22**.)

---

## 7 · Maquettes

**[`audit-j0-maquettes.html`](audit-j0-maquettes.html)** — page autonome, sans dépendance, thèmes
clair et sombre (bouton en bas à droite). Huit maquettes, « aujourd'hui mesuré » à gauche,
« proposition » à droite :

| | Maquette | Constat |
|---|---|---|
| C1 | La légende des registres, **à coût de hauteur nul** (+ le tableau des 4 variantes mesurées) | 2 |
| C2 | Les abréviations de « Se repérer » reçoivent leur clé | 4 |
| C3 | Les états vides enseignent au lieu de s'excuser | 1 et 5 |
| C4 | Le quai nomme ce qu'il cache | 6 |
| C5 | La pilule de mode dit le mode réellement engagé | 10 |
| C6 | Les deux fiches d'exemple exercent la doctrine (tableau de couverture + écran résultant) | 3 et 9 |
| C7 | Le message d'ajout des exemples cesse de masquer l'action primaire | 7 |
| C8 | **Renommer sur place — jamais sous-titrer** (+ le budget de largeur de la ligne d'état) | 8 |

> **Note de révision.** Les maquettes C1 et C8 ont été **refaites après objection de l'auteur**, et
> l'objection était juste dans les deux cas : les propositions initiales coûtaient respectivement
> **65,6 px par bloc** et **26,5 px de rangée avec ferrage à gauche**. Les deux encadrés « Pourquoi
> cette version a été abandonnée — mesure » (constats 2 et 8) gardent la trace du raisonnement et
> des chiffres, plutôt que d'effacer l'erreur.

Les maquettes reprennent les tokens d'`index.html` sans une seule couleur littérale hors du bloc de
tokens, respectent le plancher de 11 px (vérifié à la sonde : **0 texte sous 11 px** dans les deux
thèmes) et les cibles de 44 px.

---

## 8 · Ce qui marche déjà, et qu'il ne faut pas casser

Un audit qui ne dit que ce qui manque laisse croire que le reste est indifférent.

- **Le dialogue « Créer »** : trois voies, chacune avec une glose d'une ligne, plus la phrase
  « Tout import arrive en état ○ Brouillon — jamais “Validée” d'office. » C'est un modèle.
- **La porte « ＋ » de l'éditeur** : treize types, chacun avec sa conséquence en deux mots. La
  meilleure pédagogie du produit (constat 15 propose de la réemployer, pas de la refaire).
- **L'écran invité** : il explique en quatre phrases ce qu'on va voir, ce qui est enregistré, par
  qui, et qu'on peut partir — sans un tutoriel.
- **Le dialogue « Terminer la session ? »** : contexte, durée, conséquences annoncées **avant** le
  choix, action sûre par défaut.
- **La géométrie sous contrainte** : 320 px, 130 % de texte, deux moteurs — 0 px de débordement
  partout où j'ai mesuré. C'est rare, et c'est cher payé (la doctrine en porte la trace).
- **`AI_PROMPT`** : le document le plus abouti du dépôt. Son seul défaut est de n'avoir jamais été
  lu par un humain — c'est l'objet du constat 3.
