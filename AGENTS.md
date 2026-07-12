# Instructions projet — Aides cognitives

> Fichier d'instructions **canonique**, destiné à tout contributeur, humain ou IA
> (Claude, Codex, Cursor, Gemini…). `CLAUDE.md` ne fait que l'importer.

PWA médicale **monofichier** (`index.html`), JavaScript vanille, **aucune dépendance runtime**.
Stockage local-first (IndexedDB) ; synchro cloud Supabase optionnelle (RLS). Utilisée en urgence
vitale, sous stress : clarté et robustesse priment.

> **Exception UNIQUE à la règle zéro-dépendance : pdf.js** (visionneuse des documents PDF).
> Vendorisé dans `vendor/pdfjs/` (version figée, notée dans `vendor/pdfjs/README.txt`), chargé
> **paresseusement** (`import()` au premier document ouvert — jamais au démarrage), **précaché
> par `sw.js`** (hors ligne dès l'installation). Mettre à jour pdf.js = décision explicite +
> test hors-ligne complet (mode avion, PDF 50+ pages, iPhone). **Aucune autre dépendance runtime
> n'est autorisée** ; tout nouveau fichier servi doit être ajouté à `ASSETS` (`sw.js`).

## Règle de publication (IMPÉRATIF)
Publier une version = trois étapes, dans cet ordre :

1. `./release.sh X.Y.Z` — synchronise `APP_VERSION` (`index.html`) et `CACHE` (`sw.js`), ébauche
   l'entrée `CHANGELOG.md`, vérifie syntaxe et tests. **Ne jamais éditer ces numéros à la main**
   (un décalage casse la mise à jour du service worker). Le script **ne committe pas**.
2. Rédiger l'entrée `CHANGELOG.md` (contenu réel, pas de « à compléter » laissé en place).
3. Committer avec de **vraies notes de version** — format des messages du dépôt :
   `vX.Y.Z : <résumé en français des changements>` — puis taguer `vX.Y.Z`.

Les étapes 2 et 3 sont le travail de l'IA (ou de l'humain), jamais du script.
Versionnage sémantique : correctif → patch (Z), nouvelle fonctionnalité → mineure (Y).
Ne jamais pousser (`git push`) sans demande explicite de l'utilisateur.

## Avant chaque commit
- `npm run check` — vérifie la syntaxe des scripts inline (attrape les templates mal fermés).
- `npm test` — exécute `tests.html` en headless (Playwright). À défaut de npm, ouvrir `tests.html`
  **servi en http** (pas en `file://` : les iframes cross-origin y sont bloquées).
- L'intégration continue (`.github/workflows/ci.yml`) rejoue check + tests sur chaque push/PR.

## Conventions de code
- **Design tokens** : aucune nouvelle couleur hex hors `:root` (tokens CSS) et `PALETTE`
  (catégories) — **y compris dans les overrides `html[data-theme="dark"]`** (pas de copie hex
  d'un token : la duplication désaccorde les palettes ; fond de champ de saisie = `--input-bg`).
  Palette **V5 « bleu clinique »** (canvas « V5 Explorations », v4.0.4) : `--primary` bleu =
  identité/action ; **`--ok` vert = confirmation/issue positive** (pastilles d'état, fin
  d'algorithme) ; erreur/danger = `--critical`, attente/avertissement/décision = `--verify`,
  jamais l'inverse. `--critical` couvre la destruction **et l'arrêt d'un processus vivant**
  (ex. « Terminer » une session : archivante et réversible, mais stoppe les minuteurs — registre
  du rouge « raccrocher » ; ne pas le « corriger » en ambre). TROIS ROUGES distincts, ne pas
  les fusionner : `--critical` #a32e1f = TEXTE/icônes vital-destructif ; `--critical-bd`
  #c43d34 = BORDURES des cartes/bandeaux rouges ; PALETTE « Urgences » #b6382f = couleur de
  CATÉGORIE (liseré/pastille, jamais un signal d'alerte) ; états (pastilles compte/synchro) :
  ok = `--ok`, attente = `--verify`, erreur = `--critical`, inactif = `--line-strong` ; survol
  des boutons remplis = `--primary-hi` (en sombre, `--primary-dk` est l'accent **texte** clair).
  Contraste texte ≥ 4.5:1, composants ≥ 3:1 (WCAG AA). Depuis l'audit v4.5 : `--soft` est
  **décoratif seulement** (jamais une couleur de TEXTE — texte secondaire = `--ink-soft`) ;
  cases à cocher et bordures de champs = `--line-strong` (3:1, WCAG 1.4.11). Tokens ajoutés
  v4.5 : `--verify-bd`/`--verify-hi` (bordure/emphase du registre ATTENTION, ex. minuteur
  échu), `--critical-bd`, `--done-bg/-line/-ink` (étape cochée), `--tag-bg/-ink` (pilules
  neutres), `--link` (liens ET temps d'un minuteur en cours — ancien `--timer-run` fusionné).
- **Taxonomie des notices (V5)** : 5 registres, du plus au moins impérieux — ALERTE
  (`--critical`), ATTENTION (`--verify`), INFORMATION (`--primary` : `.notice`, `#sysBanner`),
  CONFIRMATION (`--ok` : `.endcap`), MEMO (neutre). Grammaire : bord gauche 4 px + bordure de la
  couleur sémantique ; la couleur n'est jamais seule. **Statuts achromatiques** : pilule `.status-tag` unique
  pour les 3 états (✓ Validé(e) — affiché lui aussi depuis v4.5 —, △ À compléter, ○ Brouillon ;
  tokens `--tag-bg`/`--tag-ink`) — la couleur reste réservée au danger et aux catégories
  (liserés de cartes ; sur les cartes d'accueil la pilule de catégorie est NEUTRE, la couleur
  ne vit que dans le liseré). Surfaces : bandeau système persistant (`#sysBanner`, INFO), snackbar
  transitoire (`.toast`, ardoise `--rt-*` fixe dans les deux thèmes) ; **en session de crise,
  aucune notification flottante** — snackbars mis en attente (cf. `toast()`), bandeau système
  masqué (`body.crisis-live`). Le panneau minuteurs suit le THÈME depuis V5 (plus de panneau
  sombre forcé en clair).
- **Statuts, code, étapes critiques (V5)** : fiches ET protocoles portent un statut à 3 états
  (`''` = validé(e) — défaut historique, `'review'` = à relire, `'draft'` = brouillon ;
  sélecteur segmenté dans les éditeurs, badges achromatiques, un ancien client traite `review`
  comme validé) et un `code` court facultatif (mono, indexé par la recherche). **Étape
  critique** = préfixe `⚠ ` (ou `!`) DANS la chaîne d'étape (`stepIsCrit`/`stepText` — le format
  reste une chaîne : exports v3 et anciens clients inchangés) ; rendue rouge en lecture et dans
  le SVG, bascule ⚠ dans l'éditeur de blocs ; le cochage passe au **vert `--ok`** et
  « Continuer » au registre CONFIRMATION quand tout le bloc est coché. Les éditeurs offrent un
  **aperçu du brouillon** (bouton « Aperçu » + colonne « Aperçu en direct » à ≥ 1000 px) via
  `state.previewFrom` : AUCUNE session ne démarre en aperçu (garde dans `ensureStarted`).
  **Auto-enregistrement des brouillons (v4.5)** : les éditeurs se sauvent en continu dans le
  store meta `draftpark` (`getDraftPark`/`setDraftPark`) — « ‹ Retour » remplace « Annuler »,
  un brouillon interrompu est proposé en « fantôme » (carte « Reprendre le brouillon » du
  dialogue Créer, lien « Repartir de la version enregistrée ») ; badge d'état
  « auto-enregistré » (+ « · synchro en attente » si le push a échoué).
- **En-têtes V5** : rangée principale unique (`.id-row` : retour ‹, marque, recherche FIXE de
  l'accueil, minuteurs de crise segmentés `#cbTimers` avec chrono **GLOBAL** — temps écoulé
  depuis la 1ʳᵉ action de session, décision produit —, badge de statut, Créer, thème, compte) ;
  en crise, bandeau TITRE teinté au registre ALERTE (`#crisisBand`, titre permanent +
  « ■ MODE CRISE »). Le sélecteur de section vit dans la tab bar basse (< 780) ou la colonne
  gauche (≥ 780), jamais dans la barre. **Menu ⋯ (v4.5)** : en lecture, toutes les actions
  secondaires (Modifier, Versions, Dupliquer, Export .json, Exporter en PDF, Historique des
  sessions, Terminer la session… — rangée `danger` en dernier, séparateurs entre groupes)
  vivent dans le menu ⋯ de la barre — il remplace les anciennes barres « Autorat » de bas de
  page. **Pied de page nomade** : `#appFooter` (Installer l'app, version, pastille synchro,
  jauge de stockage) ne vit plus qu'en bas de la sidebar de l'accueil — il est DÉPLACÉ
  (`placeFooter`/`rescueFooter`), jamais recréé (écouteurs vivants) ; « Exporter mes données »
  est dans la fenêtre Compte, l'import dans le dialogue Créer.
- **Largeurs & échelles fermées** (consignes Claude Design, v5/6 — la présente section est la
  référence) : cadre `.app` FLUIDE (en-tête/pied pleine largeur partout), contenus
  plafonnés ET centrés par vue — accueil = sidebar 240 px + grille ≤ 1320 px (auto-fill
  minmax(300px,1fr), gap 12 px, 1 colonne < 640) ; fiche = checklist ≤ 860 px (≥ 1200) + rail
  320 → 360 px (chiffres 34 px) ; protocole ≤ 780 px partout ; éditeurs alignés sur leur vue
  de lecture (fiche ≤ 860 px, protocole ≤ 780 px) + aperçu sticky 360 px
  (≥ 1000). L'accueil ≥ 780 est une COQUE FIXE (`body.view-home` : 100dvh, overflow hidden ;
  seuls `.home-side` et `.home-main` défilent — la sidebar ne bouge jamais à la bascule de
  section). Breakpoints : 430 / 560 / 640 / 780 / 900 / 1000 / 1200 px — pas de
  nouveau palier sans décision explicite. En-têtes (SPEC §5) : marque uniquement sur l'accueil ;
  éditeurs = actions dans la barre (Enregistrer à droite), AUCUN pied d'éditeur ; crise = une
  seule zone fixe en haut, jamais en bas. Plancher typographique **11 px** (app consultée sous
  stress : rien en dessous, nulle part) ; cibles tactiles ≥ 44 px (halo sur les contrôles 36 px
  de la barre).
- **Saillance & registres (audit v4.0.3)** : **un seul bouton rempli** (`--primary` plein) par
  écran — si deux actions coexistent, la moins critique passe en tonal (`--primary-soft`,
  cf. `.btn-new.tonal` : « Créer » s'efface quand « Reprendre » est affiché). **Un seul registre
  de titres de section** (petites capitales grasses, cf. `.block-h`), repris par les titres du
  contenu rédigé des protocoles (`.md-h1`/`.md-h2`) — pas de nouveau style de titre.
- **Couleur d'accent par utilisateur (v4.5)** : 5 accents prédéfinis AA (sarcelle, violet,
  indigo, framboise, ardoise) + bleu clinique par défaut ; **connecté seulement** (l'accent
  tombe à la déconnexion). Portée : l'accueil ENTIER (`body.view-home`) + l'EN-TÊTE de toutes
  les vues (`header.bar`) ; le CONTENU clinique (fiches en crise, protocoles, éditeurs) reste
  bleu clinique. Jamais de vert/ambre/rouge en accent (registres réservés). Persistance :
  `spaceKey('ac-accent')` local + `data.prefs.accent` cloud (avec thème et taille du texte).
- **Interactif** : cible tactile ≥ 32 px (44 px pour les contrôles du mode crise) ; tout nouvel
  élément interactif reçoit un état `:focus-visible` et un équivalent clavier (Entrée/Espace).
  Action destructrice en situation de crise = geste « maintenir » (`holdToReset`), pas un simple
  tap. Deux boutons « retour » empilés (aperçu → éditeur → bibliothèque) reçoivent une
  **inhibition temporelle** de 700 ms contre le double-tap (`.guarded`, opacité réduite —
  logique ECAM). Grammaire des boutons de gestion : **pointillé** = créer, **contour** = gérer/
  secondaire, **plein** = action primaire (un seul par écran).
- Toute donnée affichée passe par `esc()` (contenu potentiellement importé/partagé).
- Toute donnée importée/chargée passe par `migrate()` / `sanitizeCats()` (point d'entrée unique de
  compatibilité et de sécurité) ; nouveaux champs = facultatifs, avec défaut posé dans `migrate()`.
- **Documents PDF** : le PDF vit en ArrayBuffer dans le store IndexedDB `attachments` (base v5 ; Blob historique accepté en lecture), JAMAIS en
  base64 dans la fiche ni dans l'export JSON ; la fiche ne porte que `attachments:[{id,name,size}]`
  (validé par `safeAttachment` — id jamais régénéré, entrée invalide rejetée ; plafonds
  `MAX_PDF_BYTES`/`MAX_ATT_PER_ENTITY`). En repli KV l'ajout est refusé (`supportsAttachments`).
  Un document peut être **partagé** entre plusieurs fiches du même périmètre (même id référencé) :
  les documents ne sont supprimés que par `gcAttachments` (comptage de références au démarrage).
- Fonctions pures testables : les exposer via le hook `?__actest` (fin de `index.html`) et ajouter
  un test dans `tests.html`.
- Ne jamais supprimer un champ du modèle fiche/catégorie (compatibilité ascendante).
- **Nommage SQL** : ne JAMAIS renommer un identifiant existant (`fiches`, `category_sets`,
  `fiche_notes`… sont historiquement en français : un renommage casserait les instances déployées
  et le client, sans gain fonctionnel) ; tout **nouvel** objet (table, fonction, politique,
  colonne) est nommé **en anglais** (`protocols`, `list_orphan_attachments`…). Le français reste
  la langue des commentaires et des textes visibles.
- La sécurité réelle est **côté serveur** (politiques RLS de `supabase/schema.sql`, y compris
  celles du bucket Storage `attachments` — le **chemin encode le périmètre** : `u/<uid>/…` perso,
  `l/<libId>/…` partagé) ; les contrôles client ne sont que de l'ergonomie. Toute évolution du
  schéma OU des politiques du bucket doit être revalidée avec `supabase/rls-tests.sql`.

## Périmètre réglementaire
L'app est un **support de contenu** rédigé et validé par l'utilisateur, sans calcul ni
recommandation individualisée : voir `docs/deploiement-et-conformite.md` (§ 2, statut
non-dispositif-médical). Toute fonctionnalité qui produirait une sortie individualisée
(ex. calcul de doses) doit être évaluée au regard de ce statut **avant** développement.

## Se repérer dans `index.html` (monofichier, ~5 600 lignes)
Le fichier s'ouvre sur un **grand commentaire d'architecture** (objectif, règles de conception,
modèle de données, règles de sécurité) : le lire en premier. Ensuite, dans l'ordre :

| Section (bannières `/* ===== … ===== */`) | Contenu |
|---|---|
| `<style>` | Tout le CSS (variables dans `:root`, thème sombre via `html[data-theme="dark"]`) |
| Backends | `KV` / `IDB` / `MEM` : trois stockages locaux interchangeables derrière `Data` ; **un espace local par compte** (`currentSpace`/`dbNameFor`/`spaceKey`, bascule par reload à la connexion d'un autre compte, jamais de mélange entre comptes) ; stores IndexedDB v5 : `fiches`, `meta`, `sessions`, `backups`, `attachments` (ArrayBuffer PDF), `protocols` |
| State & Runtime | `state` (quoi afficher) ; `Runtime` (état vivant du mode crise) ; garde-fous `safeId`/`safeColor`/`safeImg`/`safeAttachment`/`sstr`/`sarr` |
| Modèle | `blankFiche`, `migrate` (point d'entrée sécurité/compat), `seed`/`seed2`, catégories |
| Load | `chooseBackend`, `load()` (démarrage), `persist`, `softDelete` |
| Runtime | minuteurs/compteurs/audio (`tickAll`, `beep`), sessions vives (`liveSessions`) |
| Sessions | auto-enregistrement (`persistLive`), reprise, compte-rendu |
| Render | `render()` → `renderLibrary` / `renderRead` / `renderEditor` (template strings + écouteurs) |
| Flow SVG | `buildFlowSVG` : organigramme auto de la prise en charge |
| Visionneuse PDF | `pdfLib` (chargement paresseux de `vendor/pdfjs`), `openPdfViewer` (rendu virtualisé par IntersectionObserver, zoom), fenêtre `#pdfModal` |
| Mini-Markdown | `mdBlocks`/`mdInline`/`mdRender`/`mdStrip` : parseur maison XSS-safe (esc() d'abord) du contenu rédigé des protocoles |
| Protocoles | `blankProtocol`/`migrateProtocol` (point d'entrée sécurité/compat), `renderProtocols`/`renderProtocolRead`/`renderProtocolEdit`, sélecteur de section dans l'en-tête (`#hdrSec` statique, `state.section`) |
| Export / Import | JSON `version: 3` ; règles de rétrocompatibilité documentées sur place |
| Compte & synchro | `Auth` (OTP e-mail), `Sync` (pull/push local-first), fenêtres associées |
| Accessibilité | gestion centralisée des modales (focus, Échap, Tab) |
| Mode test | hook `?__actest` : expose les fonctions pures pour `tests.html` |
