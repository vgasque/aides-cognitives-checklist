/* GARDE-FOU DES PAUSES FIXES DES HARNAIS (A567) — un cliquet : le nombre de pauses fixes COURTES d'un harnais peut
 * baisser, jamais monter.
 *
 * POURQUOI. A564 a remplacé ~830 pauses fixes par l'attente de calme (`__acCalme(N)` dans la page, `calme(page, N)`
 * côté Node) : elle rend la main dès que l'écran est posé, au lieu de payer N ms à chaque fois. Rien n'empêchait
 * pourtant la prochaine sonde d'écrire `await w(500)` : la règle n'était qu'une ligne d'AGENTS.md, et une règle
 * déclarative fuit (précédents : l'échelle des paliers, l'amorçage recopié — d'où check-paliers, check-harnais).
 *
 * CE QUI EST COMPTÉ, par harnais `scripts/audit-*.mjs` : une pause FIXE de moins de 700 ms — `x.waitForTimeout(N)`,
 * `setTimeout(r, N)` (littéral), ou l'appel `w(N)` d'un utilitaire de pause défini dans le fichier
 * (`const w = m => new Promise(r => setTimeout(r, m))`). 700 ms et plus = pause d'HORLOGE présumée (garde, tick,
 * échéance), non comptée — la frontière d'A564.
 * EXEMPTÉE : une ligne qui porte `// horloge` — une pause courte dont la DURÉE est le témoin (« le voile revient
 * après 220 ms », « un tick passe »), nommée À L'ENDROIT où elle s'applique, avec sa raison.
 *
 * LE CLIQUET. `scripts/pauses-plafond.json` garde, par harnais, le compte admis (relevé à l'introduction : les
 * harnais non convertis gardent leurs pauses, partage n'avait rien à gagner, A564). Compte > plafond → ROUGE : écrire
 * `__acCalme(N)` / `calme(page, N)`, ou marquer `// horloge : <raison>`. Compte < plafond → ROUGE aussi, avec la
 * commande qui abaisse le plafond (`node scripts/check-pauses.mjs --maj`) : un plafond resté haut laisserait
 * REVENIR, sans bruit, autant de pauses qu'on vient d'en retirer. Un harnais absent du plafond a un plafond de 0.
 * Vérifié capable d'échouer (une pause ajoutée → rouge ; une retirée → rouge qui demande --maj).
 */
import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const SCRIPTS = fileURLToPath(new URL('.', import.meta.url));
const PLAFOND_F = SCRIPTS + 'pauses-plafond.json';
const SEUIL = 700;

export function compterPauses(src) {
  const lignes = src.split('\n');
  // Utilitaires de pause du fichier : `const X = (m) => new Promise((r) => setTimeout(r, m))`.
  const utils = [...src.matchAll(/const\s+(\w+)\s*=\s*\(?(\w+)\)?\s*=>\s*new Promise\(\s*\(?(\w+)\)?\s*=>\s*setTimeout\(\s*\3\s*,\s*\2\s*\)\s*\)/g)].map(m => m[1])
    /* `__acCalme` a la même forme côté Node (son REPLI, A564) : c'est l'attente de calme, pas une pause fixe. */
    .filter(u => u !== '__acCalme');
  const motifs = [/\.waitForTimeout\(\s*(\d+)\s*\)/g, /setTimeout\(\s*\w+\s*,\s*(\d+)\s*\)/g,
    ...[...new Set(utils)].map(u => new RegExp(`(?<![\\w.$])${u}\\(\\s*(\\d+)\\s*\\)`, 'g'))];
  let n = 0; const ou = [];
  lignes.forEach((l, i) => {
    if (/\/\/\s*horloge\b/.test(l)) return;
    for (const re of motifs) for (const m of l.matchAll(re)) if (+m[1] < SEUIL) { n++; ou.push(i + 1); }
  });
  return { n, ou };
}

const fichiers = readdirSync(SCRIPTS).filter(f => /^audit-.*\.mjs$/.test(f) && f !== 'audit-run.mjs').sort();
const comptes = {};
for (const f of fichiers) comptes[f.replace(/\.mjs$/, '')] = compterPauses(readFileSync(SCRIPTS + f, 'utf8'));

if (process.argv.includes('--maj')) {
  const p = {};
  for (const [h, c] of Object.entries(comptes)) if (c.n) p[h] = c.n;
  writeFileSync(PLAFOND_F, JSON.stringify(p, null, 1) + '\n');
  console.log(`✓ check-pauses : plafond réécrit (${Object.values(p).reduce((a, b) => a + b, 0)} pauses fixes courtes admises).`);
  process.exit(0);
}

let plafond = {};
try { plafond = JSON.parse(readFileSync(PLAFOND_F, 'utf8')); }
catch (e) { console.error(`✗ check-pauses : ${PLAFOND_F} illisible (${e.message}).`); process.exit(1); }

let ko = 0;
for (const [h, c] of Object.entries(comptes)) {
  const max = plafond[h] || 0;
  if (c.n > max) { ko++;
    console.error(`  ✗ ${h} : ${c.n} pauses fixes de moins de ${SEUIL} ms pour ${max} admises (lignes ${c.ou.slice(-Math.min(c.n - max, 8)).join(', ')}…).\n` +
      `      Une pause de RENDU s'écrit __acCalme(N) dans la page, calme(page, N) côté Node (A564) ;\n` +
      `      une pause dont la durée EST le témoin se marque « // horloge : <raison> » sur sa ligne.`); }
  else if (c.n < max) { ko++;
    console.error(`  ✗ ${h} : ${c.n} pauses fixes courtes pour un plafond de ${max} — bravo ; abaissez le plafond pour qu'elles ne reviennent pas :\n` +
      `      node scripts/check-pauses.mjs --maj`); }
}
for (const h of Object.keys(plafond)) if (!comptes[h]) { ko++;
  console.error(`  ✗ « ${h} » a un plafond mais plus de fichier : node scripts/check-pauses.mjs --maj`); }

if (ko) { console.error(`✗ check-pauses : ${ko} écart(s) au cliquet des pauses fixes (A567).`); process.exit(1); }
const tot = Object.values(comptes).reduce((a, c) => a + c.n, 0);
console.log(`✓ check-pauses : ${fichiers.length} harnais, ${tot} pauses fixes courtes, aucune au-delà du plafond (cliquet A567).`);
