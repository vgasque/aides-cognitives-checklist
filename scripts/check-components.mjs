#!/usr/bin/env node
// GARDE-FOU — les COMPOSANTS JUMEAUX PWA ↔ app native (design/components.json).
//
// Les tokens et les échelles passent d'un côté à l'autre SANS intervention (build-tokens,
// check-swift-design). Le DESSIN d'un composant, lui, ne se génère pas : du SwiftUI ne se déduit
// pas proprement d'une règle CSS. Ce contrôle garantit donc la chose qui compte — qu'AUCUNE
// modification de composant ne soit OUBLIÉE de l'autre côté :
//
//   1. EMPREINTE : pour chaque composant, le CSS de sa famille de classes (toutes les règles
//      dont le sélecteur nomme l'un de ses préfixes, @media compris) est haché. L'empreinte
//      relue est rangée dans design/components.lock.json. CSS changé → échec, avec le nom du
//      composant, sa fiche du design system et ses types Swift à revoir ;
//   2. JUMEAUX : chaque type Swift nommé existe dans native/App/Sources (un renommage ou une
//      suppression sans mise à jour du catalogue est une dérive) ;
//   3. COUVERTURE : toute famille de classes CSS (≥ 3 règles) appartient à un composant ou est
//      écartée NOMMÉMENT (`horsCatalogue`) — une nouvelle surface de la PWA force la décision
//      « quel est son jumeau ? » au lieu de passer inaperçue ;
//   4. UNICITÉ : un préfixe n'appartient qu'à un composant.
//
//   node scripts/check-components.mjs              contrôle (code 1 en cas d'écart)
//   node scripts/check-components.mjs --ack <id>   le jumeau a été relu : enregistre l'empreinte
//   node scripts/check-components.mjs --ack all    (première pose, ou relecture d'ensemble)
//   node scripts/check-components.mjs --doc        régénère native/DESIGN-COMPOSANTS.md

import { readFileSync, writeFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const CAT = join(ROOT, 'design', 'components.json');
const LOCK = join(ROOT, 'design', 'components.lock.json');
const DOC = join(ROOT, 'native', 'DESIGN-COMPOSANTS.md');
const args = process.argv.slice(2);

const catalogue = JSON.parse(readFileSync(CAT, 'utf8'));
const lock = existsSync(LOCK) ? JSON.parse(readFileSync(LOCK, 'utf8')) : {};

// ---- CSS : règles de premier niveau et dans les @media, avec leur condition -------------------
const html = readFileSync(join(ROOT, 'index.html'), 'utf8');
const css = html.slice(html.indexOf('<style>') + 7, html.indexOf('</style>')).replace(/\/\*[\s\S]*?\*\//g, '');
function rules(src) {
  const out = [];
  const stack = [];
  let i = 0, start = 0;
  while (i < src.length) {
    const c = src[i];
    if (c === '{') {
      const head = src.slice(start, i).trim();
      if (head.startsWith('@')) { stack.push(head); start = i + 1; i++; continue; }
      const end = src.indexOf('}', i);
      out.push({ sel: head, body: src.slice(i + 1, end).trim(), at: stack.join(' ') });
      i = end + 1; start = i; continue;
    }
    if (c === '}') { stack.pop(); start = i + 1; }
    i++;
  }
  return out;
}
const norm = (s) => s.replace(/\s+/g, ' ').trim();
const prefixesOf = (sel) => new Set([...sel.matchAll(/\.([a-zA-Z][\w-]*)/g)].map((m) => m[1].split('-')[0]));
const R = rules(css).filter((r) => !r.at.startsWith('@keyframes') && !r.at.startsWith('@font-face'))
  .map((r) => ({ ...r, pre: prefixesOf(r.sel) }));

// ---- Unicité des préfixes ----------------------------------------------------------------------
const owner = new Map();
const faults = [];
for (const c of catalogue.composants) for (const p of c.css) {
  if (owner.has(p)) faults.push(`préfixe « ${p} » revendiqué par « ${owner.get(p)} » ET « ${c.id} »`);
  owner.set(p, c.id);
}

// ---- Empreintes --------------------------------------------------------------------------------
const hashes = {}, counts = {};
for (const c of catalogue.composants) {
  const set = new Set(c.css);
  const mine = R.filter((r) => [...r.pre].some((p) => set.has(p)));
  counts[c.id] = mine.length;
  hashes[c.id] = createHash('sha256').update(mine.map((r) => `${norm(r.at)}|${norm(r.sel)}{${norm(r.body)}}`).join('\n')).digest('hex').slice(0, 16);
}

// ---- Couverture --------------------------------------------------------------------------------
const uncovered = {};
for (const r of R) {
  if (!r.pre.size || [...r.pre].some((p) => owner.has(p))) continue;
  for (const p of r.pre) uncovered[p] = (uncovered[p] || 0) + 1;
}
const ignored = new Set(catalogue.horsCatalogue.map((x) => (typeof x === 'string' ? x : x.prefixe)));
const newFamilies = Object.entries(uncovered).filter(([p, n]) => n >= 3 && !ignored.has(p)).sort((a, b) => b[1] - a[1]);

// ---- Jumeaux Swift -----------------------------------------------------------------------------
function walk(d) {
  return readdirSync(d).flatMap((n) => { const p = join(d, n); return statSync(p).isDirectory() ? walk(p) : (p.endsWith('.swift') ? [p] : []); });
}
const swiftSrc = walk(join(ROOT, 'native', 'App', 'Sources')).map((f) => readFileSync(f, 'utf8')).join('\n');
const missingTypes = [];
for (const c of catalogue.composants) for (const t of c.swift) {
  if (!new RegExp(`\\b(struct|class|enum)\\s+${t}\\b`).test(swiftSrc)) missingTypes.push(`${c.id} → ${t}`);
}

// ---- Actions -----------------------------------------------------------------------------------
const ackIx = args.indexOf('--ack');
if (ackIx >= 0) {
  const id = args[ackIx + 1];
  const ids = id === 'all' ? catalogue.composants.map((c) => c.id) : [id];
  for (const x of ids) {
    if (!(x in hashes)) { console.error(`✗ composant inconnu : ${x}`); process.exit(1); }
    lock[x] = hashes[x];
  }
  const sorted = Object.fromEntries(Object.keys(lock).sort().map((k) => [k, lock[k]]));
  writeFileSync(LOCK, JSON.stringify(sorted, null, 2) + '\n');
  console.log(`✓ empreinte(s) enregistrée(s) : ${ids.join(', ')}`);
  process.exit(0);
}

if (args.includes('--doc')) {
  const fiches = (c) => (c.fiche ? `\`design/ds/${c.fiche}\`` : '—');
  const L = [];
  L.push('# Composants jumeaux PWA ↔ app native');
  L.push('');
  L.push('> ⚠ Fichier GÉNÉRÉ depuis `design/components.json` (`node scripts/check-components.mjs --doc`) — ne pas éditer.');
  L.push('');
  L.push('Chaque composant relie une famille de classes CSS d\'`index.html` à ses types SwiftUI. Si le CSS');
  L.push('d\'un composant change, `scripts/check-components.mjs` (CI) échoue et désigne le jumeau à revoir ;');
  L.push('une fois relu : `node scripts/check-components.mjs --ack <id>`.');
  L.push('');
  L.push('| Composant | Statut | Classes CSS (préfixes) | Règles | Fiche du design system | Types SwiftUI |');
  L.push('|---|---|---|---:|---|---|');
  for (const c of catalogue.composants) {
    L.push(`| **${c.nom}** (\`${c.id}\`) | ${c.statut} | ${c.css.map((p) => '`.' + p + '`').join(' ')} | ${counts[c.id]} | ${fiches(c)} | ${c.swift.map((t) => '`' + t + '`').join(', ')} |`);
  }
  L.push('');
  L.push('## Traduction PWA → iOS 27');
  L.push('');
  L.push('Ce qui n\'est PAS recopié mais TRADUIT vers un composant ou un réglage du système. Les registres');
  L.push('(rouge / ambre / vert / bleu, toujours avec un mot), les échelles et les tokens restent identiques.');
  L.push('');
  L.push('| PWA | App native | Règle |');
  L.push('|---|---|---|');
  for (const t of catalogue.traductions) L.push(`| ${t.pwa} | ${t.ios} | ${t.regle} |`);
  L.push('');
  if (catalogue.horsCatalogue.length) {
    L.push('## Familles CSS hors catalogue (écartées nommément)');
    L.push('');
    for (const x of catalogue.horsCatalogue) L.push(`- \`.${x.prefixe}\` — ${x.motif}`);
    L.push('');
  }
  writeFileSync(DOC, L.join('\n'));
  console.log('✓ native/DESIGN-COMPOSANTS.md');
  process.exit(0);
}

// ---- Contrôle ----------------------------------------------------------------------------------
const stale = catalogue.composants.filter((c) => lock[c.id] && lock[c.id] !== hashes[c.id]);
const unstamped = catalogue.composants.filter((c) => !lock[c.id]);
for (const c of stale) {
  faults.push(`« ${c.nom} » (${c.id}) : son CSS a changé depuis la dernière relecture du jumeau Swift.\n`
    + `      revoir : ${c.swift.join(', ')}${c.fiche ? `  ·  fiche design/ds/${c.fiche}` : ''}\n`
    + `      puis   : node scripts/check-components.mjs --ack ${c.id}`);
}
for (const c of unstamped) faults.push(`« ${c.nom} » (${c.id}) : aucune empreinte relue — node scripts/check-components.mjs --ack ${c.id}`);
for (const m of missingTypes) faults.push(`jumeau Swift introuvable : ${m} (renommé ou supprimé ? mettre design/components.json à jour)`);
for (const [p, n] of newFamilies) faults.push(`famille CSS « .${p}-… » (${n} règles) sans composant : l'ajouter à un composant de design/components.json, ou l'écarter nommément dans « horsCatalogue »`);

const covered = R.filter((r) => [...r.pre].some((p) => owner.has(p))).length;
const withClass = R.filter((r) => r.pre.size).length;
if (faults.length) {
  console.log(`\n✗ check-components : ${faults.length} écart(s) :`);
  for (const f of faults) console.log('   • ' + f);
  process.exit(1);
}
console.log(`✓ check-components : ${catalogue.composants.length} composants jumeaux, empreintes à jour ; `
  + `${covered}/${withClass} règles CSS à classes couvertes (${Math.round((100 * covered) / withClass)} %), `
  + `${catalogue.horsCatalogue.length} famille(s) écartée(s) nommément.`);
