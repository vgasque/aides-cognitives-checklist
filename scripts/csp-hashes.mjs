#!/usr/bin/env node
/*
 * Durcissement CSP — calcule le hash SHA-256 de CHAQUE bloc <script> inline d'index.html
 * (anti-flash de thème + application) et l'injecte dans la directive `script-src`, à la fois
 * dans la balise <meta> d'index.html ET dans `_headers`.
 *
 * Pourquoi : l'architecture monofichier interdit les scripts externes ; sans hash, la seule
 * façon d'autoriser l'inline est `'unsafe-inline'`, qui laisse aussi passer un <script> injecté
 * (aucun rempart CSP contre le XSS). En listant les hashs des scripts LÉGITIMES, les navigateurs
 * modernes (CSP niveau 2+) IGNORENT `'unsafe-inline'` et n'exécutent QUE ces scripts — un inline
 * injecté est bloqué. On CONSERVE `'unsafe-inline'` comme repli pour les navigateurs pré-CSP2
 * (qui ignorent les hashs) : aucun affaiblissement, dégradation douce.
 *
 * `style-src 'unsafe-inline'` reste tel quel : les attributs `style=` des gabarits ne sont pas
 * hachables et le risque est de moindre portée (documenté dans docs/deploiement-et-conformite.md).
 *
 * Rejoué à CHAQUE release (le hash change avec le code) : appelé par release.sh. Idempotent.
 *
 *   node scripts/csp-hashes.mjs
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const idxPath = join(ROOT, 'index.html');
const hdrPath = join(ROOT, '_headers');
let html = readFileSync(idxPath, 'utf8');

// Extraction des blocs <script> SANS attribut src (les inline). Notre monofichier n'a pas de
// script externe ni d'attribut sur <script> ; on refuse tout src par sécurité.
const reScript = /<script\b([^>]*)>([\s\S]*?)<\/script>/g;
const hashes = [];
let m;
while ((m = reScript.exec(html)) !== null) {
  if (/\bsrc\s*=/.test(m[1])) continue;                 // script externe : jamais haché
  const digest = createHash('sha256').update(m[2], 'utf8').digest('base64');
  hashes.push(`'sha256-${digest}'`);
}
if (!hashes.length) { console.error('Aucun script inline trouvé — abandon.'); process.exit(1); }

// Nouvelle valeur de script-src : 'self' 'unsafe-inline' + hashs (remplace d'éventuels hashs déjà
// présents -> idempotent). On ne touche à AUCUNE autre directive.
const scriptSrc = `script-src 'self' 'unsafe-inline' ${hashes.join(' ')}`;
// Cible : `script-src 'self' 'unsafe-inline'` suivi d'éventuels hashs déjà injectés.
const reDirective = /script-src 'self' 'unsafe-inline'(?: 'sha256-[^']*')*/;

function inject(text, label) {
  if (!reDirective.test(text)) { console.error(`Directive script-src introuvable dans ${label}.`); process.exit(1); }
  return text.replace(reDirective, scriptSrc);
}

html = inject(html, 'index.html');
writeFileSync(idxPath, html);
let hdr = readFileSync(hdrPath, 'utf8');
hdr = inject(hdr, '_headers');
writeFileSync(hdrPath, hdr);

console.log(`CSP durcie : ${hashes.length} hash(s) de script inline injecté(s) (index.html + _headers).`);
