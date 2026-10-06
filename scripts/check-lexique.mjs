#!/usr/bin/env node
/* check-lexique (A461) — le texte affiché dit « aide » et « protocole », jamais « fiche ».
   Le mot reste libre dans le code : on ne lit que la prose (déterminant, nombre, interpolation
   ou majuscule en tête de chaîne). Exempté : le prompt IA, qui décrit le JSON. */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

const orig = readFileSync(join(ROOT, 'index.html'), 'utf8');
const blank = m => m.replace(/[^\n]/g, ' ');
let s = orig.replace(/<style[\s\S]*?<\/style>/g, blank)
  .replace(/<!--[\s\S]*?-->/g, blank)
  .replace(/\/\*[\s\S]*?\*\//g, blank)
  .replace(/(^|[^:'"`\\])\/\/[^\n]*/gm, (m, a) => a + blank(m.slice(a.length)));
{ const i = s.indexOf('const AI_PROMPT=`'), j = s.indexOf('`;', i);
  if (i < 0 || j < 0) { console.error('✗ check-lexique : AI_PROMPT introuvable — exemption périmée.'); process.exit(1); }
  s = s.slice(0, i) + blank(s.slice(i, j)) + s.slice(j); }

const DET = "la|une|cette|chaque|aucune|toute|toutes les|les|des|ces|vos|nos|mes|ses|leurs|de|en|sa|ma|ta|votre|notre"
  + "|nouvelle|nouvelles|même|autre|autres|par|sur|plusieurs|quelle|seule|d[’']|l[’']";
const RE = new RegExp(`(?:(?<=(?:^|[^\\p{L}])(?:${DET})\\s)|(?<=d[’']|\\}\\s|\\d\\s|[>'"\`]))(f|F)iches?(?![\\p{L}\\d_\\-])`, 'gu');

const lignes = s.split('\n'), src = orig.split('\n'), hits = [];
lignes.forEach((l, i) => {
  for (const m of l.matchAll(RE)) {
    const avant = l[m.index - 1] || '', apres = l.slice(m.index + m[0].length);
    // Après un guillemet, seule une PROSE compte : majuscule, ou un mot qui suit (« 'fiches' » est une clé).
    if (/['"`>]/.test(avant) && m[1] === 'f' && !/^\s\p{L}/u.test(apres)) continue;
    hits.push(`    index.html:${i + 1}  …${src[i].slice(Math.max(0, m.index - 40), m.index + 40).trim()}…`);
  }
});
if (hits.length) {
  console.error(`✗ check-lexique : ${hits.length} « fiche » dans du texte affiché :`);
  hits.forEach(h => console.error(h));
  console.error('  -> écrire « aide » (parcours à cocher), « protocole » (texte à lire), ou « données »');
  console.error('     quand le texte vise les deux (compte, synchro, stockage). Cf. A461.');
  process.exit(1);
}
console.log('✓ check-lexique : aucun « fiche » dans le texte affiché (aide · protocole ; prompt IA exempté).');
