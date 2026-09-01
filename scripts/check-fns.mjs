#!/usr/bin/env node
/* ============================================================================
   check-fns — une fonction (ou const) top-niveau déclarée doit être CITÉE
   ailleurs que dans sa déclaration (audit v5.19.4, A280).

   POURQUOI : catsUtiles, filtersActive et _ROLE_LBL vivaient à zéro appelant —
   et la doctrine décrivait filtersActive AU PRÉSENT. Aucun garde-fou ne couvrait
   ce sens (check-actest ne voit que la surface __ac_test__).

   MÉTHODE : noms déclarés dans index.html (function X / const X =), puis compte
   des occurrences du nom (mot entier) dans index.html SANS commentaires + les
   témoins et harnais (tests.html, scripts/, sw.js). 1 occurrence = la
   déclaration seule = mort. Une citation en chaîne compte comme usage (les
   gabarits appellent par nom) : le contrôle ne peut donc pas fabriquer de faux
   rouge, seulement manquer un mort — mesuré à l'audit : 3 morts, 0 faux positif
   sur ~1 300 déclarations. Un appel UNIQUEMENT dynamique (window[x]) ferait un
   rouge à exempter ci-dessous, avec sa raison.
   ============================================================================ */
import { readFileSync, readdirSync } from 'node:fs';
import { stripComments } from './strip-comments.mjs';

const ROOT = new URL('../', import.meta.url);
const idx = stripComments(readFileSync(new URL('index.html', ROOT), 'utf8'));
let corpus = idx + readFileSync(new URL('tests.html', ROOT), 'utf8')
  + readFileSync(new URL('sw.js', ROOT), 'utf8');
for (const f of readdirSync(new URL('scripts/', ROOT)))
  if (f.endsWith('.mjs')) corpus += readFileSync(new URL('scripts/' + f, ROOT), 'utf8');

const EXEMPT = new Set([
  // (aucune à ce jour — un appel purement dynamique s'exempte ICI, avec sa raison)
]);

const declared = new Set();
for (const m of idx.matchAll(/(?:^|[\s;{}()])(?:async\s+)?function\s+([A-Za-z_$][\w$]*)/g)) declared.add(m[1]);
for (const m of idx.matchAll(/(?:^|[\s;{}(])const\s+([A-Za-z_$][\w$]*)\s*=/g)) declared.add(m[1]);

const count = new Map();
for (const m of corpus.matchAll(/[A-Za-z_$][\w$]*/g))
  count.set(m[0], (count.get(m[0]) || 0) + 1);

const morts = [...declared].filter(n => (count.get(n) || 0) <= 1 && !EXEMPT.has(n)).sort();
if (morts.length) {
  console.error('✗ check-fns : ' + morts.length + ' déclaration(s) citées NULLE PART ailleurs :');
  morts.forEach(n => console.error('    ' + n + ' — zéro appelant (code mort, ou appel dynamique à exempter)'));
  process.exit(1);
}

/* SENS 2 (assainissement v5.20.x) : un `let` top-niveau ÉCRIT mais jamais LU est mort — et le
   compte de citations ci-dessus ne peut pas le voir, une ÉCRITURE cite le nom (deux let de
   l'accueil ont vécu ainsi, cf. rapport phase 0 ; on ne les nomme pas ICI : ce fichier est dans
   le corpus, les nommer les ferait vivre). Top-niveau = ligne à la colonne 0 (le code des
   fonctions est indenté). Est une LECTURE toute occurrence hors `nom =` (les `==`, `=>`, `+=`
   lisent) ; une citation en chaîne compte comme lecture — jamais de faux rouge. */
const lets = new Set();
for (const m of idx.matchAll(/^let\s+([^\n;]*)/gm)) {
  const seg = m[1];
  const first = seg.match(/^([A-Za-z_$][\w$]*)/);
  if (first) lets.add(first[1]);
  for (const d of seg.matchAll(/,\s*([A-Za-z_$][\w$]*)\s*=/g)) lets.add(d[1]);
}
const jamaisLus = [];
for (const n of lets) {
  if (EXEMPT.has(n)) continue;
  let reads = 0;
  const rx = new RegExp('(^|[^.\\w$])' + n + '(?![\\w$])', 'g');
  let m;
  while ((m = rx.exec(corpus))) {
    let i = m.index + m[0].length;
    while (corpus[i] === ' ' || corpus[i] === '\t') i++;
    if (corpus[i] === '=' && corpus[i + 1] !== '=' && corpus[i + 1] !== '>') continue; // écriture
    reads++;
  }
  if (!reads) jamaisLus.push(n);
}
if (jamaisLus.length) {
  console.error('✗ check-fns : ' + jamaisLus.length + ' let top-niveau écrit(s) mais jamais LU(S) :');
  jamaisLus.sort().forEach(n => console.error('    ' + n + ' — toutes ses occurrences sont des écritures (code mort)'));
  process.exit(1);
}
console.log('✓ check-fns : ' + declared.size + ' déclaration(s) top-niveau toutes citées hors de leur ligne ; '
  + lets.size + ' let top-niveau tous lus au moins une fois.');
