/* Icône de l'app native (1024 px, iOS + macOS) tirée de la MÊME géométrie que la PWA :
 * `logo-glyph.svg` (généré par scripts/build-icons.mjs) est recadré à l'échelle de l'icône
 * d'application (1,12 au lieu de 1,45), blanc sur le bleu de marque — aucun second dessin.
 *   node native/tools/build-app-icon.mjs */
import { chromium } from 'playwright';
import { readFileSync, existsSync } from 'node:fs';
import { ROOT } from '../../scripts/harness.mjs';

const glyph = readFileSync(ROOT + 'logo-glyph.svg', 'utf8');
const inner = glyph.replace(/^[\s\S]*?<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '').replaceAll('#000000', '#FFFFFF');
const k = 1.12 / 1.45;
const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
<rect width="1024" height="1024" fill="#1F5FA6"/>
<g transform="translate(512 512) scale(${k}) translate(-512 -512)">${inner}</g></svg>`;
const PRE = '/opt/pw-browsers/chromium';
const b = await chromium.launch(existsSync(PRE) ? { executablePath: PRE } : {});
const p = await b.newPage({ viewport: { width: 1024, height: 1024 } });
await p.setContent(`<html><body style="margin:0">${svg}</body></html>`);
await p.screenshot({ path: ROOT + 'native/App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png', omitBackground: false });
await b.close();
console.log('icône 1024 écrite');
