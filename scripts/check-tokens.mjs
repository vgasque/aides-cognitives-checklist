#!/usr/bin/env node
/* ============================================================================
   check-tokens — un token CSS se vérifie déclaré ET lu (audit v5.19.4, A280).

   POURQUOI : `var(--hover)` était lu par deux règles et déclaré NULLE PART —
   déclaration invalide au calcul, deux survols INERTES en production, invisibles
   de check-colors (qui vérifie les valeurs, pas l'usage) ; et six tokens
   déclarés n'étaient lus par personne, dont --hit-crisis. Même famille que
   check-classes, transposée aux tokens.

   DEUX SENS : (1) tout token DÉCLARÉ (`--x:` — CSS, setProperty, style inline
   des gabarits) doit être LU (`var(--x`, getPropertyValue) quelque part —
   index.html, tests.html ou un harnais ; (2) tout token LU par `var(--x)` SANS
   repli doit être déclaré quelque part (un `var(--x, repli)` se suffit).
   Commentaires retirés d'abord : la doctrine cite des tokens, elle ne les
   déclare pas. Exemptions NOMMÉES ci-dessous, avec leur raison.

   TROISIÈME SENS (v5.38.1, A416) : aucun ALIAS PUR — un token dont TOUTES les déclarations valent
   le même `var(--x)` n'est qu'un second nom de --x. Trente-huit avaient survécu à la refonte v5.6
   (« les anciens noms pointent vers les nouveaux ») : deux noms par valeur, une doctrine qui citait
   --critical/--verify quand le code lisait --crit/--warn. On lit --x directement. Un alias
   CONTEXTUEL (redéfini ailleurs : --ink-soft en contraste renforcé, --on-primary la nuit) reste un
   vrai token sémantique.
   ============================================================================ */
import { readFileSync, readdirSync } from 'node:fs';
import { stripComments } from './strip-comments.mjs';

const ROOT = new URL('../', import.meta.url);
const idx = stripComments(readFileSync(new URL('index.html', ROOT), 'utf8'));
let readersExt = readFileSync(new URL('tests.html', ROOT), 'utf8');
for (const f of readdirSync(new URL('scripts/', ROOT)))
  if (f.endsWith('.mjs') && f !== 'check-tokens.mjs') readersExt += readFileSync(new URL('scripts/' + f, ROOT), 'utf8');

const EXEMPT = new Set([
  // (aucune à ce jour — une exemption s'ajoute ICI, avec sa raison en commentaire)
]);

const declared = new Set();
for (const m of idx.matchAll(/--([A-Za-z][\w-]*)\s*:/g)) declared.add(m[1]);
for (const m of idx.matchAll(/setProperty\(\s*['"`]--([\w-]+)/g)) declared.add(m[1]);

const read = new Set(), noFallback = new Set();
for (const m of idx.matchAll(/var\(\s*--([A-Za-z][\w-]*)\s*(,)?/g)) {
  read.add(m[1]); if (!m[2]) noFallback.add(m[1]);
}
for (const m of (idx + readersExt).matchAll(/(?:getPropertyValue|removeProperty)\(\s*['"`]--([\w-]+)/g)) read.add(m[1]);
for (const m of readersExt.matchAll(/var\(\s*--([A-Za-z][\w-]*)/g)) read.add(m[1]);

const morts = [...declared].filter(t => !read.has(t) && !EXEMPT.has(t)).sort();
const valeurs = new Map();
for (const m of idx.matchAll(/--([A-Za-z][\w-]*)\s*:\s*([^;}"'`]+)/g)) {
  if (!valeurs.has(m[1])) valeurs.set(m[1], []); valeurs.get(m[1]).push(m[2].trim()); }
const purs = [...valeurs].filter(([, vs]) => vs.every(v => /^var\(--[\w-]+\)$/.test(v)) && new Set(vs).size === 1)
  .map(([t, vs]) => [t, vs[0].slice(4, -1)]).sort();
const fantomes = [...noFallback].filter(t => !declared.has(t) && !EXEMPT.has(t)).sort();
let ko = 0;
if (morts.length) {
  ko++;
  console.error('✗ check-tokens : ' + morts.length + ' token(s) déclarés et lus NULLE PART :');
  morts.forEach(t => console.error('    --' + t + ' — déclaration morte (ou lecteur oublié)'));
}
if (fantomes.length) {
  ko++;
  console.error('✗ check-tokens : ' + fantomes.length + ' token(s) lus par var() SANS repli et déclarés NULLE PART :');
  fantomes.forEach(t => console.error('    --' + t + ' — déclaration invalide au calcul : la propriété ne peint RIEN (le cas --hover)'));
}
if (purs.length) {
  ko++;
  console.error('✗ check-tokens : ' + purs.length + ' alias PUR(S) — un second nom pour une même valeur (A416) :');
  purs.forEach(([t, x]) => console.error('    --' + t + ' ← var(' + x + ') — lire ' + x + ' directement'));
}
if (ko) process.exit(1);
console.log('✓ check-tokens : ' + declared.size + ' token(s) déclarés, tous lus ; ' +
  noFallback.size + ' lu(s) sans repli, tous déclarés ; aucun alias pur.');
