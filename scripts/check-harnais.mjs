/* GARDE-FOU DES HARNAIS (v5.0.0) — la discipline du lanceur et des gestes partagés,
 * auto-exécutoire.
 *
 * POURQUOI. Deux règles sont nées avec `audit-run.mjs` et `harness.mjs` (gestes partagés), et
 * toutes deux sont exactement du genre qui FUIT si rien ne les vérifie (précédent : l'échelle des
 * paliers, déclarative pendant des années, avait fui — d'où `check-paliers.mjs`) :
 *
 * 1. LA LISTE DU LANCEUR EST EXHAUSTIVE. Un harnais créé sur disque mais absent de `HARNAIS`
 *    (audit-run.mjs) ne tournerait JAMAIS dans `npm run audit` — et le trou serait SILENCIEUX :
 *    la passe resterait verte, en croyant tout couvrir. Inversement, un nom listé sans fichier
 *    échouerait au lancement, mais autant l'attraper ici, en quelques millisecondes.
 *
 * 2. L'AMORÇAGE NE SE RECOPIE PAS. Dix-sept copies de « Commencer → fiches d'exemple » avaient
 *    déjà divergé sur leurs délais avant la mutualisation ; une copie réintroduite recommencerait
 *    la dérive. Le motif est détecté par le clic « Commencer » dans un audit-*.mjs ; DEUX sites
 *    sont bénis, marqués sur place par « PAS `amorce()` ici » (la sonde de l'écran de bienvenue,
 *    dont l'amorçage est le SUJET de mesure, et la sonde qui injecte sa propre fiche sans poser
 *    les exemples) — une exemption est NOMMÉE à l'endroit exact où elle s'applique, jamais dans
 *    une liste ici (elle se périmerait, leçon des listes tenues en double).
 */
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const SCRIPTS = fileURLToPath(new URL('.', import.meta.url));
let ko = 0;
const fail = m => { ko++; console.error('  ✗ ' + m); };

/* ── 1. Liste du lanceur ⇔ fichiers sur disque ─────────────────────────────────────────────── */
const runner = readFileSync(SCRIPTS + 'audit-run.mjs', 'utf8');
const listes = [...runner.matchAll(/nom:\s*'([a-z0-9-]+)'/g)].map(m => m[1]);
const disque = readdirSync(SCRIPTS).filter(f => /^audit-.*\.mjs$/.test(f) && f !== 'audit-run.mjs')
  .map(f => f.replace(/\.mjs$/, ''));

for (const d of disque) if (!listes.includes(d))
  fail(`${d}.mjs existe sur disque mais n'est PAS dans HARNAIS (audit-run.mjs) : il ne tournera jamais dans « npm run audit ».`);
for (const l of listes) if (!disque.includes(l))
  fail(`« ${l} » est listé dans HARNAIS (audit-run.mjs) mais ${l}.mjs n'existe pas sur disque.`);

/* ── 2. Aucun amorçage recopié hors des sites bénis ────────────────────────────────────────── */
const MARQUE = 'PAS `amorce()` ici';
for (const f of disque) {
  const lignes = readFileSync(SCRIPTS + f + '.mjs', 'utf8').split('\n');
  lignes.forEach((l, i) => {
    if (!/\/Commencer\//.test(l)) return;
    // Béni si la marque d'exemption figure dans les 6 lignes AU-DESSUS de l'occurrence.
    const avant = lignes.slice(Math.max(0, i - 6), i).join('\n');
    if (avant.includes(MARQUE)) return;
    fail(`${f}.mjs:${i + 1} recopie l'amorçage (« Commencer ») : utiliser amorce() de harness.mjs, ` +
      `ou marquer le site « ${MARQUE} » avec sa justification.`);
  });
}

if (ko) { console.error(`✗ check-harnais : ${ko} problème(s).`); process.exit(1); }
console.log(`✓ check-harnais : ${listes.length} harnais listés = ${disque.length} sur disque, aucun amorçage recopié.`);
