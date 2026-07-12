# design/ — export Design System (claude.ai/design)

Dossier **hors app** : rien ici n'est servi par la PWA (pas dans `ASSETS` de `sw.js`,
hors app servie). Il alimente le projet « Design System » de claude.ai/design
(projectId `ded5aff6-1b5c-4813-919d-c9774c5163d1`).

## Contenu

- `build.mjs` — génère `ds/` en **extrayant** tokens, PALETTE et CSS réels de
  `index.html` (source de vérité unique ; ne jamais éditer les fichiers générés).
- `ds/` — sortie générée : 15 fiches HTML (Fondations + Composants, chaque fiche
  montre les deux thèmes), `tokens/tokens.css`, `GUIDELINES.md` (rédigé à la main :
  règles de design du projet, seul fichier de `ds/` à éditer).

## Resynchroniser après une évolution du design

1. `node design/build.mjs`
2. Demander à Claude Code : « resynchronise le design system » (outil DesignSync,
   composant par composant — jamais de remplacement en bloc).
