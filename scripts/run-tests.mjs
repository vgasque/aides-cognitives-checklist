// Lance tests.html dans un Chromium headless (Playwright) et échoue si un test échoue.
// Sert les fichiers via un petit serveur statique intégré (pas de dépendance serveur).
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

let chromium;
try { ({ chromium } = await import('playwright')); }
catch { console.error('Playwright absent : `npm install` puis `npx playwright install chromium`.'); process.exit(2); }

const browser = await chromium.launch();
const page = await browser.newPage();
const errors = [];
page.on('pageerror', e => errors.push('pageerror: ' + e.message));
page.on('console', m => { if (m.type() === 'error') errors.push('console: ' + m.text()); });

await page.goto(`http://localhost:${port}/tests.html`);
await page.waitForFunction(() => {
  const s = document.getElementById('summary');
  return s && /réussis/.test(s.textContent);
}, { timeout: 15000 });

const summary = await page.textContent('#summary');
const failCount = await page.$$eval('.t.fail', els => els.length);
const failMsgs = await page.$$eval('.t.fail .msg', els => els.map(e => e.textContent));

console.log(summary.trim());
if (errors.length) console.error('Erreurs page :\n' + errors.join('\n'));
if (failMsgs.length) console.error('Échecs :\n- ' + failMsgs.join('\n- '));

await browser.close();
server.close();
process.exit(failCount === 0 && summary.includes('0 échoué') && !errors.length ? 0 : 1);
