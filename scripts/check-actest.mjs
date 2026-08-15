#!/usr/bin/env node
/* ============================================================================
   check-actest — toute clé exportée vers `__ac_test__` a un LECTEUR.
   (v5.10.2, audit externe.)

   POURQUOI : l'export « pour test » faisait passer le comptage d'occurrences de
   1 à 2, et rien ne vérifiait que le test correspondant existe. C'est par ce
   trou que `flattenFiche` — exportée, jamais citée par un témoin — a pu rester
   verte pendant que le diff de versions devenait aveugle sur cinq listes sur
   six (défaut corrigé en v5.10.2). Le littéral portait en outre trois DOUBLONS
   (`Share`, `tkLabels`, `tkRefNorm` ×2) : une liste que plus personne ne relit.

   RÈGLE : chaque clé du littéral `window.__ac_test__ = {…}` doit apparaître
   (en mot entier) dans `tests.html` OU dans un harnais `scripts/*.mjs` — les
   harnais consomment aussi cet objet. Un doublon dans le littéral échoue.
   ⚠ `tests.html` se lit comme des OCTETS (il contient des séquences que grep
   croit binaires — le piège qui a fait dire « 0 test » à un audit entier).

   LIMITE DITE : « cité » n'est pas « couvert » — le contrôle attrape la clé
   ORPHELINE, pas le témoin creux. C'est le même contrat que check-actions
   (l'attribut émis doit avoir un lecteur), appliqué à la surface de test.
   ============================================================================ */
import { readFileSync, readdirSync } from 'node:fs';

const root = new URL('../', import.meta.url);
const idx = readFileSync(new URL('index.html', root), 'utf8');

// Le littéral d'export : de `window.__ac_test__={` à la `}` qui le ferme (suivie de `;`).
const start = idx.indexOf('window.__ac_test__={');
if (start < 0) { console.error('✗ check-actest : littéral __ac_test__ introuvable.'); process.exit(1); }
const end = idx.indexOf('};', start);
const lit = idx.slice(start + 'window.__ac_test__={'.length, end);

// Clés : identifiants séparés par des virgules (raccourcis ES2015 — le littéral n'a pas de `k:v`).
const keys = [...lit.matchAll(/[A-Za-z_$][\w$]*/g)].map(m => m[0]);
const seen = new Set(), dups = new Set();
for (const k of keys) { if (seen.has(k)) dups.add(k); seen.add(k); }

// Lecteurs : tests.html + tous les scripts (harnais ET garde-fous, qui pilotent la page).
let hay = readFileSync(new URL('tests.html', root), 'utf8');
for (const f of readdirSync(new URL('scripts/', root))) {
  if (f.endsWith('.mjs') && f !== 'check-actest.mjs') hay += readFileSync(new URL('scripts/' + f, root), 'utf8');
}
const cited = k => new RegExp('\\b' + k.replace(/\$/g, '\\$') + '\\b').test(hay);

const orphans = [...seen].filter(k => !cited(k)).sort();
const fails = [];
if (dups.size) fails.push(dups.size + ' doublon(s) dans le littéral : ' + [...dups].sort().join(', '));
if (orphans.length) fails.push(orphans.length + ' clé(s) exportée(s) que ni tests.html ni aucun harnais ne cite : ' + orphans.join(', '));
if (fails.length) {
  console.error('✗ check-actest :');
  fails.forEach(f => console.error('    ' + f));
  console.error('    -> écrire le témoin, ou retirer la clé du littéral (un export « pour test » sans test est un faux vert).');
  process.exit(1);
}
console.log('✓ check-actest : ' + seen.size + ' clé(s) exportée(s), toutes citées par un témoin ou un harnais, aucun doublon.');
