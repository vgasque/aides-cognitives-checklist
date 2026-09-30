/* ORACLE DE PARITÉ — la PWA est la source de vérité, le port natif se vérifie CONTRE ELLE.
 *
 * Charge `index.html?__actest` dans Chromium headless (le crochet de test expose les fonctions
 * pures : migrate, sanitizeCats, flowPlan, shareDiff…), joue chaque cas de `oracle-cases/*.mjs`
 * et écrit { input, output } dans `AidesCore/Tests/AidesCoreTests/Fixtures/oracle/<nom>.json`.
 * Les tests Swift relisent ces fichiers et exigent la MÊME sortie : une divergence entre les deux
 * clients (web et natif) devient un test rouge, pas une surprise en intervention.
 *
 * Un cas = module qui exporte `inputs` (tableau JSON) et `run(inputs)` — une fonction exécutée
 * DANS LA PAGE (sérialisée par Playwright), où `__ac_test__` est disponible. Elle rend un tableau
 * de sorties JSON-sérialisables, une par entrée.
 *
 *   node native/tools/oracle.mjs            # tous les cas
 *   node native/tools/oracle.mjs migrate    # un cas
 */
import { readdir, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { serveApp, moteur, ROOT } from '../../scripts/harness.mjs';

const CASES = new URL('./oracle-cases/', import.meta.url).pathname;
const OUT = ROOT + 'native/AidesCore/Tests/AidesCoreTests/Fixtures/oracle/';
const only = process.argv.slice(2);

const { port, srv } = await serveApp();
// Environnement cloud : le Chromium préinstallé peut précéder la version de Playwright du lock.
const PRE = '/opt/pw-browsers/chromium';
const browser = await moteur().launch(existsSync(PRE) && !process.env.AC_ENGINE ? { executablePath: PRE } : {});
const page = await browser.newPage();
await page.goto(`http://localhost:${port}/index.html?__actest`);
await page.waitForFunction(() => !!window.__ac_test__);
let n = 0;
for (const f of (await readdir(CASES)).filter(x => x.endsWith('.mjs')).sort()) {
  const name = f.replace(/\.mjs$/, '');
  if (only.length && !only.includes(name)) continue;
  const mod = await import(CASES + f);
  const outputs = await page.evaluate(mod.run, mod.inputs);
  const cases = mod.inputs.map((input, i) => ({ input, output: outputs[i] === undefined ? null : outputs[i] }));
  await writeFile(OUT + name + '.json', JSON.stringify(cases, null, 1) + '\n');
  console.log(`oracle : ${name} — ${cases.length} cas`);
  n++;
}
await browser.close();
srv.close();
if (!n) { console.error('oracle : aucun cas joué'); process.exit(1); }
