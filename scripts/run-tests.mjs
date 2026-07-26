// Lance tests.html dans des navigateurs headless (Playwright) et échoue si un test échoue.
// Sert les fichiers via un petit serveur statique intégré (pas de dépendance serveur).
//
// DEUX MOTEURS depuis v4.34.0 — Chromium ET WebKit. iOS Safari est la cible PRINCIPALE de cette
// app (PWA installée sur iPhone, usage SMUR) et n'était jamais testé : toute la suite tournait sur
// Blink seul, alors que le dossier « bande basse iOS » (v4.29.x) a montré qu'un comportement
// WebKit peut différer au point de couper l'écran sans qu'aucune mesure ne le voie. Les fonctions
// pures elles-mêmes ne sont pas à l'abri : `DecompressionStream` (import .zip), les regex, la
// normalisation Unicode et `structuredClone` ont des implémentations distinctes.
// WebKit est OPTIONNEL : absent (CI minimale, poste sans `npx playwright install webkit`), il
// produit un AVERTISSEMENT, pas un échec — même dégradation douce que pour Playwright lui-même.
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json',
  '.webmanifest': 'application/manifest+json', '.png': 'image/png', '.svg': 'image/svg+xml' };

const server = createServer(async (req, res) => {
  try {
    let p = decodeURIComponent(req.url.split('?')[0]);
    if (p === '/') p = '/index.html';
    const buf = await readFile(ROOT + p.replace(/^\/+/, ''));
    res.writeHead(200, { 'content-type': TYPES[extname(p)] || 'application/octet-stream' });
    res.end(buf);
  } catch { res.writeHead(404); res.end('not found'); }
});

const port = await new Promise(r => server.listen(0, () => r(server.address().port)));

let pw;
try { pw = await import('playwright'); }
catch { console.error('Playwright absent : `npm install` puis `npx playwright install chromium webkit`.'); process.exit(2); }

// Une passe = un moteur. Renvoie { ok, resume } ou null si le moteur n'est pas installé.
async function run(nom, launcher, launchOpts) {
  let browser;
  try { browser = await launcher.launch(launchOpts); }
  catch (e) { return null; }                 // révision absente : traité en avertissement
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push('pageerror: ' + e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push('console: ' + m.text()); });

  let summary = '', failMsgs = [], failCount = 0;
  try {
    await page.goto(`http://localhost:${port}/tests.html`);
    await page.waitForFunction(() => {
      const s = document.getElementById('summary');
      return s && /réussis/.test(s.textContent);
    }, { timeout: 20000 });
    summary = (await page.textContent('#summary')).trim();
    failCount = await page.$$eval('.t.fail', els => els.length);
    failMsgs = await page.$$eval('.t.fail .msg', els => els.map(e => e.textContent));
  } catch (e) {
    // Le résumé n'est jamais arrivé : le mode d'échec le PLUS PROBABLE est que la page n'a pas
    // booté (hashs CSP périmés, erreur de syntaxe). Les erreurs console captées sont alors la
    // seule information utile — elles étaient jusqu'ici JETÉES avec l'exception.
    summary = `(aucun résumé — ${e.name}: ${String(e.message).split('\n')[0]})`;
    failCount = 1;
  }

  console.log(`\n── ${nom}`);
  console.log('  ' + summary);
  if (errors.length) console.error('  Erreurs page :\n    ' + errors.slice(0, 8).join('\n    '));
  if (failMsgs.length) console.error('  Échecs :\n    - ' + failMsgs.join('\n    - '));

  await browser.close();
  return { ok: failCount === 0 && summary.includes('0 échoué') && !errors.length, resume: summary };
}

// AC_CHROMIUM : chemin d'un Chromium déjà présent (environnements distants/CI où la révision
// attendue par Playwright n'est pas téléchargée) — ex. AC_CHROMIUM=/opt/pw-browsers/chromium.
const results = [];
const chr = await run('Chromium (Blink)', pw.chromium,
  process.env.AC_CHROMIUM ? { executablePath: process.env.AC_CHROMIUM } : {});
if (!chr) { console.error('Chromium introuvable : `npx playwright install chromium`.'); server.close(); process.exit(2); }
results.push(chr);

const wk = await run('WebKit (cible iOS)', pw.webkit, {});
if (wk) results.push(wk);
else console.warn('\n⚠ WebKit non installé — la cible iOS n\'a PAS été testée.' +
  '\n  `npx playwright install webkit` (le reste de la suite a bien tourné sur Chromium).');

server.close();
const allOk = results.every(r => r.ok);
console.log(`\n${allOk ? '✓' : '✗'} ${results.length} moteur(s) : ${results.map(r => r.resume).join(' | ')}`);
process.exit(allOk ? 0 : 1);
