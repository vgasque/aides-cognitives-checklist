#!/usr/bin/env node
// Garde-fou anti-dérive de `design/ds/`.
//
// `design/ds/` est GÉNÉRÉ depuis `index.html` par `design/build.mjs` (source de vérité = le CSS
// du monofichier). Rien n'obligeait à rejouer le build : les 15 fiches ont dérivé de v4.4.6 à
// v4.22.1 (18 versions) avant qu'on s'en aperçoive. Ce script régénère puis compare :
//
//   node scripts/design-check.mjs            → régénère + rapporte la dérive (n'échoue jamais).
//   node scripts/design-check.mjs --strict   → échoue (code 1) si `design/ds/` a bougé, SANS
//                                              laisser la régénération dans l'arbre de travail
//                                              (mode CI : signale au dev de rejouer le build).
//
// Déterministe (aucune date/aléa dans build.mjs), donc utilisable en intégration continue.

import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const strict = process.argv.includes('--strict');
const git = (...args) => execFileSync('git', args, { cwd: root, encoding: 'utf8' });

// Seuls ces chemins sont PRODUITS par build.mjs. GUIDELINES.md, lui, est RÉDIGÉ À LA MAIN :
// il ne doit ni compter comme une dérive, ni — surtout — être restauré par --strict (une
// première version de ce script faisait `git checkout -- design/ds` et a effacé une
// réécriture non committée de GUIDELINES.md).
const GEN = ['design/ds/components', 'design/ds/foundations', 'design/ds/tokens'];

// 1. Régénérer design/ds/ depuis index.html.
execFileSync('node', ['design/build.mjs'], { cwd: root, stdio: 'inherit' });

// 2. La sortie GÉNÉRÉE diffère-t-elle de ce qui est versionné ?
const changed = git('status', '--porcelain', '--', ...GEN).trim();

if (!changed) {
  console.log('\n✓ design/ds/ est à jour avec index.html.');
  process.exit(0);
}

console.log('\n⚠ design/ds/ a dérivé de index.html. Fiches concernées :');
console.log(changed.split('\n').map(l => '   ' + l.trim()).join('\n'));

if (strict) {
  // Ne pas polluer l'espace de travail CI : restaurer les seuls fichiers GÉNÉRÉS.
  git('checkout', '--', ...GEN);
  console.error('\n✗ Régénère et committe avant de pousser :  npm run design:build && git add design/ds');
  process.exit(1);
}

console.log('\nLa régénération est dans ton arbre de travail — relis puis committe avec la version.');
process.exit(0);
