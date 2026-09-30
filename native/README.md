# Aides cognitives — application native (iPhone, iPad, Mac)

Réécriture native de la PWA (`../index.html`), en **Swift / SwiftUI**, une seule base de code
pour **iOS 26+, iPadOS 26+ et macOS 26+** (app Mac native, pas Catalyst), compilée avec
**Xcode 27** (SDK iOS 27 / macOS 27).

## Design : iOS 27 (Liquid Glass)

L'interface suit les recommandations d'Apple de 2026 (HIG : Materials, Toolbars, Tab bars,
Sidebars, Buttons, Sheets) :

- **coque système** : onglets *Aides · Sessions · Moi · Rechercher* (`TabView` adaptable —
  barre d'onglets flottante qui se réduit au défilement sur iPhone, barre latérale sur iPad et
  Mac), une pile de navigation par onglet, recherche dans son propre onglet avec ses portées
  (*Tout · Aides · Protocoles*) ;
- **verre réservé à la couche fonctionnelle** (barres, quai de session, capsule, bandeaux
  flottants) — le contenu (cartes, étapes, listes) reste opaque et garde les registres de la PWA
  (rouge / ambre / vert / bleu, toujours avec un mot) ;
- **barres d'outils** en symboles SF, une seule action proéminente (`.glassProminent`) au bord
  droit ; boutons de contenu en **capsules** ; feuilles avec ✕ à gauche, ✓ à droite, détentes ;
- le **mode crise masque la barre d'onglets** : le quai de session est la seule barre du bas, et
  rien ne l'interrompt (règle 11).

## Pourquoi Swift (et pas TypeScript)

- **Natif réel sur les trois plateformes** : SwiftUI, PDFKit, AVFoundation, UserNotifications,
  Keychain — sans pont JavaScript ni WebView. React Native / Capacitor n'auraient pas donné une
  app Mac native et auraient réintroduit une couche web.
- **Ce que la PWA ne pouvait pas faire** devient possible : alarme de minuteur audible **même
  bouton silencieux activé**, notifications locales quand l'app est en arrière-plan, écran
  maintenu allumé en session, visionneuse PDF système (pdf.js disparaît), jetons de connexion
  dans le **trousseau**.
- **Interopérabilité conservée** : même format de données (modèle v4, export `version: 3`,
  `.zip` avec documents), même projet Supabase (mêmes lignes, mêmes chemins de stockage, mêmes
  règles de conflit), même format de session. Web et natif lisent et écrivent la même
  bibliothèque.

## Organisation

```
native/
├── project.yml            projet Xcode (XcodeGen) — une cible multiplateforme
├── AidesCore/             LE CŒUR, sans interface (Foundation seule) — compilé et testé
│   ├── Sources/AidesCore/
│   │   ├── JSON.swift, JSCompat.swift   valeur JSON dynamique ; primitives à la sémantique JS
│   │   ├── Model / Migrate / Serialize  modèle v4 + port ligne à ligne de migrate()
│   │   ├── SessionSanitize, Store, Library, ImportExport, Zip
│   │   ├── Engine/        moteur de session (coches, liens, moments, parcours, minuteurs…)
│   │   ├── Cloud/         compte (OTP e-mail), synchronisation Supabase
│   │   ├── Share/         partage de session (formats, transport)
│   │   └── Pure/          fonctions pures (Markdown, parcours, recherche, posologie…)
│   └── Tests/AidesCoreTests/  tests + fixtures d'ORACLE (sorties de la PWA)
├── App/                   l'application SwiftUI (vues, alarmes, trousseau, PDFKit)
└── tools/
    ├── oracle.mjs         exécute la PWA dans Chromium et produit les fixtures de parité
    ├── oracle-cases/      les cas joués
    ├── build-app-icon.mjs icône tirée de la même géométrie que la PWA
    └── build-seeds.mjs    fiches d'exemple extraites de la PWA
```

## Parité avec la PWA : l'oracle

La PWA reste la **source de vérité**. `tools/oracle.mjs` charge `index.html?__actest` dans
Chromium (le crochet de test expose les fonctions pures), rejoue des cas — y compris des données
**hostiles** (`__proto__`, XSS dans les couleurs et les images, cibles pendantes) — et écrit
leurs sorties dans `AidesCore/Tests/AidesCoreTests/Fixtures/oracle/`. Les tests Swift exigent la
**même** sortie : une divergence entre le web et le natif devient un test rouge.

```bash
npm ci                                  # à la racine du dépôt (Playwright)
node native/tools/oracle.mjs            # régénère toutes les fixtures
cd native/AidesCore && swift test       # macOS ou Linux (Swift 5.10+) — le cœur vise encore iOS 17 / macOS 14
```

## Compiler et lancer l'app

```bash
brew install xcodegen
cd native && xcodegen generate && open AidesCognitives.xcodeproj
```

Choisir la cible (simulateur iPhone/iPad, ou « My Mac »), renseigner l'équipe de signature
(`DEVELOPMENT_TEAM` dans `project.yml` ou dans Xcode), puis ⌘R.

L'instance Supabase se change dans l'Info.plist (`SupabaseURL`, `SupabaseKey`) ; par défaut,
celle de la PWA.

## Intégration continue

`.github/workflows/native.yml` : tests du cœur sur macOS, puis compilation de l'app pour le
simulateur iOS et pour macOS (sans signature), sur l'image `macos-26` avec Xcode 27 quand elle
le fournit.

## Écarts assumés vis-à-vis de la PWA

Documentés à l'endroit du code concerné (commentaires « Q… » renvoyant aux questions des
spécifications) ; principaux :

- L'alarme d'un minuteur annonce l'**action** (`onDue`) — la PWA ne recopiait pas ce champ.
- « Faire maintenant » enregistre et partage immédiatement.
- Une reprise de session ne laisse jamais deux sessions vives pour une même aide.
- L'alarme sonne malgré le bouton silencieux (session audio « lecture ») ; notification locale
  en arrière-plan.
- Images encodées en JPEG (iOS ne sait pas écrire le WebP) — lisibles par la PWA.
