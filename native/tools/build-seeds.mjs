/* Les deux fiches d'exemple de l'app native sont celles de la PWA (seed / seed2), extraites en
 * exécutant la PWA : aucun second texte clinique à tenir. Les catégories sont des jetons
 * (__URG__, __SMUR__) remplacés à l'ajout par les catégories « Urgences » et « SMUR » de
 * l'appareil, comme `addSeedFiches`.   node native/tools/build-seeds.mjs */
import { writeFileSync, existsSync } from 'node:fs';
import { chromium } from 'playwright';
import { serveApp, ROOT } from '../../scripts/harness.mjs';
const { port, srv } = await serveApp();
const PRE = '/opt/pw-browsers/chromium';
const b = await chromium.launch(existsSync(PRE) ? { executablePath: PRE } : {});
const p = await b.newPage();
await p.goto(`http://localhost:${port}/index.html?__actest`);
await p.waitForFunction(() => !!window.__ac_test__);
const seeds = await p.evaluate(() => JSON.parse(JSON.stringify([seed('__URG__'), seed2('__SMUR__')])));
writeFileSync(ROOT + 'native/App/Resources/exemples.json', JSON.stringify(seeds, null, 1) + '\n');
await b.close(); srv.close();
console.log('exemples.json : ' + seeds.map(s => s.title).join(' · '));
