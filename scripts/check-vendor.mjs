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
import { readFile, stat } from 'node:fs/promises';

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

/* ---- police : la taille annoncée est la taille réelle ---- */
const fontReadme = await readFile(ROOT + 'vendor/fonts/README.txt', 'utf8');
const mFont = fontReadme.match(/([\w.-]+\.woff2)\s*\(([\d\s  ]+)\s*octets\)/);
if (!mFont) fautes.push("vendor/fonts/README.txt : « <fichier>.woff2 (N octets) » introuvable");
else {
  const attendu = parseInt(mFont[2].replace(/[\s  ]/g, ''), 10);
  const reel = (await stat(ROOT + 'vendor/fonts/' + mFont[1])).size;
  if (reel !== attendu) fautes.push(`${mFont[1]} : ${reel} octets sur le disque, ${attendu} annoncés dans README.txt`);
}

if (fautes.length) {
  console.error('✗ check-vendor : un actif vendorisé et sa note ne disent pas la même chose.');
  fautes.forEach(f => console.error('    ' + f));
  process.exit(1);
}
console.log(`✓ check-vendor : pdf.js ${mDecl[1]} — clé de cache alignée ; police ${mFont[1]} conforme à sa note.`);
