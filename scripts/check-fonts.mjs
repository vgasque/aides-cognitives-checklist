#!/usr/bin/env node
/*
 * GARDE-FOU DES POLICES (v5.6) — trois familles, trois tokens, et rien d'autre.
 *
 * POURQUOI CE CONTRÔLE EXISTE. La refonte « verre clinique » vendorise TROIS familles au lieu
 * d'une : Manrope (interface), IBM Plex Mono (valeurs), Source Serif 4 (titres). Elles sont
 * déclarées une fois, dans `--f-ui` / `--f-mono` / `--f-title`, et tout le fichier est censé
 * passer par elles. Rien ne l'imposait : une `font-family` écrite en clair est SILENCIEUSE — le
 * texte s'affiche, simplement pas dans la bonne police, et sur un système où `system-ui` ressemble
 * à Manrope on ne le voit même pas en regardant.
 *
 * Et ce n'est pas théorique : au moment d'écrire ce script, DEUX sites l'enfreignaient depuis la
 * refonte — la pilule de discriminant du titre (`.bt-d`, posée en `system-ui` du temps où
 * l'interface ELLE-MÊME l'était) et les sept textes du schéma SVG. Deux endroits où l'application
 * parlait encore l'ancienne voix, sans que rien ne puisse le dire.
 *
 * CE QU'IL VÉRIFIE
 *   1. Les trois tokens existent et commencent par la famille EMBARQUÉE (pas par un repli) ;
 *      chaque famille embarquée a son `@font-face` et son fichier sur le disque.
 *   2. Toute déclaration CSS `font-family:` passe par un token (ou `inherit`).
 *   3. Tout attribut SVG `font-family="…"` commence par une famille embarquée — un attribut
 *      n'hérite pas d'une propriété personnalisée, il porte donc la pile en clair.
 *
 * CE QU'IL N'EXAMINE PAS, ET POURQUOI C'EST NOMMÉ : le compte rendu TÉLÉCHARGÉ (`.html` autonome)
 * est un document qui vit HORS de l'application — aucun serveur, aucune police à charger. Ses
 * `font-family` système sont une DÉCISION (v5.2.0), pas un oubli, et le script les exempte par la
 * région où elles vivent, pas par une liste de valeurs qui se périmerait.
 *
 *   node scripts/check-fonts.mjs
 */
import { readFile, stat } from 'node:fs/promises';

const ROOT = decodeURIComponent(new URL('../', import.meta.url).pathname);
const src = await readFile(ROOT + 'index.html', 'utf8');
const fautes = [];

/* Les trois familles embarquées, et le token qui doit les porter. */
const FAMILLES = [
  { nom: 'Manrope',        token: '--f-ui' },
  { nom: 'IBM Plex Mono',  token: '--f-mono' },
  { nom: 'Source Serif 4', token: '--f-title' },
];

/* ---- 1. Chaque famille : un token qui la nomme EN TÊTE, un @font-face, un fichier ---- */
for (const f of FAMILLES) {
  const m = src.match(new RegExp('\\' + f.token + ':\\s*([^;]+);'));
  if (!m) { fautes.push(`${f.token} : token introuvable dans :root`); continue; }
  const tete = m[1].split(',')[0].replace(/["']/g, '').trim();
  if (tete !== f.nom) fautes.push(`${f.token} commence par « ${tete} » et non « ${f.nom} » — le repli passerait devant la police embarquée`);
  const ff = [...src.matchAll(/@font-face\{font-family:'([^']+)';src:url\('([^']+)'\)/g)]
    .filter(x => x[1] === f.nom);
  if (!ff.length) { fautes.push(`${f.nom} : aucun @font-face`); continue; }
  for (const x of ff) {
    try { await stat(ROOT + x[2]); }
    catch { fautes.push(`${f.nom} : @font-face pointe « ${x[2]} », absent du disque`); }
  }
}

/* ---- 2. Les déclarations CSS passent par un token ----
   ⚠ ON NEUTRALISE D'ABORD LES COMMENTAIRES ET LA RÉGION DU COMPTE RENDU AUTONOME. Ce fichier CITE
   ses propres règles à longueur de commentaires doctrinaux (« il était resté en `system-ui` ») :
   les lire ferait signaler la doctrine au lieu du code — la leçon de `check-space` (v5.0.3) et de
   `check-upload`. La neutralisation remplace par des espaces de MÊME LONGUEUR : indices et numéros
   de ligne restent justes. */
const blanc = (t, a, b) => t.slice(0, a) + t.slice(a, b).replace(/[^\n]/g, ' ') + t.slice(b);
let net = src.replace(/\/\*[\s\S]*?\*\//g, m => m.replace(/[^\n]/g, ' '))
             .replace(/<!--[\s\S]*?-->/g, m => m.replace(/[^\n]/g, ' '));

/* La région du compte rendu autonome : de son `const css=` jusqu'au backtick fermant. Bornée par
   un repère du CODE, jamais par un numéro de ligne. */
{
  const a = net.indexOf("const css=`@font-face");
  if (a < 0) fautes.push("région du compte rendu autonome introuvable (repère « const css=`@font-face ») — le contrôle ne sait plus ce qu'il exempte");
  else { const b = net.indexOf('`;', a); net = blanc(net, a, b > 0 ? b : a); }
}

const ligne = i => net.slice(0, i).split('\n').length;
const OK_CSS = /^(var\(--(sans|mono|serif|f-ui|f-mono|f-title)\)|inherit)$/;
for (const m of net.matchAll(/font-family\s*:\s*([^;}"']+)/g)) {
  const v = m[1].trim();
  if (OK_CSS.test(v)) continue;
  fautes.push(`index.html:${ligne(m.index)}  font-family:${v}  — passer par --sans / --mono / --serif`);
}

/* ---- 3. Les attributs SVG portent la pile en clair, et commencent par une famille embarquée ---- */
for (const m of net.matchAll(/font-family\s*=\s*"([^"]*)"/g)) {
  const tete = m[1].split(',')[0].replace(/["']/g, '').trim();
  if (FAMILLES.some(f => f.nom === tete)) continue;
  fautes.push(`index.html:${ligne(m.index)}  font-family="${m[1]}"  — un attribut SVG n'hérite pas de --f-ui : écrire la pile, famille embarquée en tête`);
}

if (fautes.length) {
  console.error(`✗ check-fonts : ${fautes.length} déclaration(s) de police hors des trois tokens.`);
  fautes.forEach(f => console.error('   ' + f));
  console.error('\n  Une police écrite en clair est SILENCIEUSE : le texte s’affiche, dans la');
  console.error('  mauvaise voix, et rien ne le signale. Trois familles, trois tokens.');
  process.exit(1);
}
console.log('✓ check-fonts : 3 familles embarquées, 3 tokens ; aucune police écrite en clair (compte rendu autonome exempté, cf. en-tête).');
