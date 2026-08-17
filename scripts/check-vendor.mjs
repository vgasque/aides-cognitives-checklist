#!/usr/bin/env node
/*
 * GARDE-FOU DES ACTIFS VENDORISÉS (v5.0.0, audit) — « mettre à jour pdf.js » doit VRAIMENT le
 * mettre à jour.
 *
 * POURQUOI CE CONTRÔLE EXISTE. Le service worker range pdf.js dans un cache SÉPARÉ, versionné par
 * la version de pdf.js et non par celle de l'app (`PDFJS_CACHE`) — c'est une bonne décision : elle
 * évite de re-télécharger 1,73 Mio inchangés à chaque publication. Mais l'installation n'y écrit
 * QUE ce qui manque :
 *
 *     for (const a of PDFJS_ASSETS) { if (await c.match(a)) continue; try { await c.add(a); } … }
 *
 * Donc si l'on remplace les fichiers de `vendor/pdfjs/` SANS changer `PDFJS_CACHE`, la clé de
 * cache est inchangée, les entrées sont déjà là, et **rien n'est re-téléchargé** : chaque appareil
 * déjà installé continue de faire tourner l'ANCIENNE bibliothèque, indéfiniment et en silence.
 * On croit avoir mis à jour ; on n'a rien mis à jour. Pour une bibliothèque qui PARSE DU CONTENU
 * NON MAÎTRISÉ (les PDF joints par l'utilisateur), c'est le pire mode de défaillance possible :
 * la mise à jour de sécurité qui n'atteint personne, et rien pour le dire.
 *
 * Ce script relie donc les DEUX sources qui doivent bouger ensemble : la version déclarée dans
 * `vendor/pdfjs/README.txt` (la seule qui dise ce qui est réellement posé sur le disque) et
 * `PDFJS_CACHE` (la seule que le navigateur regarde).
 *
 * IL VÉRIFIE AUSSI LA POLICE. `vendor/fonts/README.txt` annonce une taille en octets ; c'est la
 * seule trace de ce qui a été sous-ensemblé. Un fichier remplacé sans mise à jour de la note fait
 * mentir la note — et la note est tout ce qu'on aura pour savoir quoi re-télécharger le jour où il
 * faudra reconstituer le sous-ensemble.
 *
 * CE QU'IL NE FAIT PAS, ET C'EST VOLONTAIRE : il n'interroge aucun réseau. Un garde-fou de commit
 * doit être instantané et fonctionner hors ligne, comme les douze autres. Comparer à la version
 * amont et aux avis de sécurité est un geste d'AUDIT, périodique et humain — la marche à suivre
 * est dans AGENTS.md (§ « Mettre à jour un actif vendorisé »).
 *
 *   node scripts/check-vendor.mjs
 */
import { readFile, stat, readdir } from 'node:fs/promises';

const ROOT = decodeURIComponent(new URL('../', import.meta.url).pathname);
const fautes = [];

/* ---- pdf.js : version déclarée == version de la clé de cache ---- */
const pdfReadme = await readFile(ROOT + 'vendor/pdfjs/README.txt', 'utf8');
const sw = await readFile(ROOT + 'sw.js', 'utf8');

const mDecl = pdfReadme.match(/pdfjs-dist\s+([0-9]+(?:\.[0-9]+)*)/);
const mCache = sw.match(/const PDFJS_CACHE\s*=\s*'([^']*)'/);

if (!mDecl) fautes.push("vendor/pdfjs/README.txt : version introuvable (attendu « pdfjs-dist X.Y.Z »)");
if (!mCache) fautes.push("sw.js : PDFJS_CACHE introuvable");
if (mDecl && mCache) {
  const decl = mDecl[1];
  if (!mCache[1].endsWith('-' + decl)) {
    fautes.push(`pdf.js ${decl} (README) mais PDFJS_CACHE = '${mCache[1]}'`);
    fautes.push("  -> la clé de cache est INCHANGÉE : les appareils déjà installés garderont");
    fautes.push("     l'ancienne bibliothèque pour toujours (l'install n'écrit que ce qui manque).");
  }
}

/* ---- jsQR : même motif que pdf.js (v5.14) — la note, la clé de cache et l'octet ---- */
const jsqrReadme = await readFile(ROOT + 'vendor/jsqr/README.txt', 'utf8');
const jDecl = jsqrReadme.match(/jsqr\s+([0-9]+(?:\.[0-9]+)*)/);
const jCache = sw.match(/const JSQR_CACHE\s*=\s*'([^']*)'/);
if (!jDecl) fautes.push("vendor/jsqr/README.txt : version introuvable (attendu « jsqr X.Y.Z »)");
if (!jCache) fautes.push("sw.js : JSQR_CACHE introuvable");
if (jDecl && jCache && !jCache[1].endsWith('-' + jDecl[1]))
  fautes.push(`jsQR ${jDecl[1]} (README) mais JSQR_CACHE = '${jCache[1]}' — clé inchangée : les appareils installés garderaient l'ancien décodeur`);
const jTaille = jsqrReadme.match(/jsQR\.js\s*\(([\d\s\u00a0\u202f]+)\s*octets\)/);
if (!jTaille) fautes.push("vendor/jsqr/README.txt : « jsQR.js (N octets) » introuvable");
else {
  const attendu = parseInt(jTaille[1].replace(/[\s\u00a0\u202f]/g, ''), 10);
  let reel = null;
  try { reel = (await stat(ROOT + 'vendor/jsqr/jsQR.js')).size; }
  catch { fautes.push('vendor/jsqr/jsQR.js : annoncé dans README.txt, absent du disque'); }
  if (reel !== null && reel !== attendu)
    fautes.push(`jsQR.js : ${reel} octets sur le disque, ${attendu} annoncés dans README.txt`);
}

/* ---- polices : la taille annoncée est la taille réelle, POUR CHACUNE ----
   v5.6 : la refonte « verre clinique » vendorise trois familles (Source Serif 4, Manrope, IBM
   Plex Mono) au lieu d'une. Le contrôle lisait la PREMIÈRE ligne « <fichier>.woff2 (N octets) »
   et s'arrêtait là : il aurait donc validé une note où les trois autres poids étaient faux, en
   silence. On lit désormais TOUTES les lignes, et l'on vérifie EN PLUS qu'aucun .woff2 du disque
   n'échappe à la note — le trou inverse, celui d'une fonte ajoutée sans être documentée. */
const fontReadme = await readFile(ROOT + 'vendor/fonts/README.txt', 'utf8');
const annonces = [...fontReadme.matchAll(/([\w.-]+\.woff2)\s*\(([\d\s\u00a0\u202f]+)\s*octets\)/g)];
if (!annonces.length) fautes.push("vendor/fonts/README.txt : « <fichier>.woff2 (N octets) » introuvable");
for (const m of annonces) {
  const attendu = parseInt(m[2].replace(/[\s\u00a0\u202f]/g, ''), 10);
  let reel = null;
  try { reel = (await stat(ROOT + 'vendor/fonts/' + m[1])).size; }
  catch { fautes.push(`${m[1]} : annoncée dans README.txt, absente de vendor/fonts/`); continue; }
  if (reel !== attendu) fautes.push(`${m[1]} : ${reel} octets sur le disque, ${attendu} annoncés dans README.txt`);
}
const surDisque = (await readdir(ROOT + 'vendor/fonts')).filter(f => f.endsWith('.woff2'));
for (const f of surDisque) {
  if (!annonces.some(m => m[1] === f)) fautes.push(`${f} : sur le disque, absente de vendor/fonts/README.txt`);
}

if (fautes.length) {
  console.error('✗ check-vendor : un actif vendorisé et sa note ne disent pas la même chose.');
  fautes.forEach(f => console.error('    ' + f));
  process.exit(1);
}
console.log(`✓ check-vendor : pdf.js ${mDecl[1]} et jsQR ${jDecl ? jDecl[1] : '?'} — clés de cache alignées ; ${annonces.length} police(s) conformes à leur note.`);
