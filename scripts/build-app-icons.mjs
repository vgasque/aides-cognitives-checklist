#!/usr/bin/env node
// Génère les icônes « any » du manifest (icon-192/512) depuis le master vectoriel.
//
//   node scripts/build-app-icons.mjs
//
// POURQUOI un glyphe plus grand ici que sur apple-touch-icon (leçon v4.22.5) :
//   iOS pose l'icône PLEIN BORD (apple-touch-icon, glyphe ~72 % du fichier = ~72 % de la case).
//   macOS (Safari « Ajouter au Dock », Chrome installé) place l'icône du MANIFEST dans une tuile
//   qui n'occupe que ~80 % du canevas du Dock, avec marge + ombre autour. Un glyphe à 72 % du
//   fichier n'y ferait plus que ~58 % de la case — nettement plus petit qu'sur iPhone.
//   On COMPENSE en agrandissant le glyphe à 88 % du fichier : après la marge macOS il retrouve
//   ~70 % de la case, très proche du rendu iOS. apple-touch-icon N'EST PAS régénéré ici : il
//   reste à 72 %, l'iPhone étant déjà parfait.
//
// Le glyphe couvre ~72,2 % de son propre viewBox ; scale = 0.88 / 0.722 pour l'amener à 88 %.
// Rendu par Chromium (Playwright, dev-dépendance) ; ni CI, ni dépendance runtime.
import { chromium } from 'playwright';
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const BG = '#1F5FA6';
const TARGET = 0.88, GLYPH_IN_VIEWBOX = 0.722;
const S = TARGET / GLYPH_IN_VIEWBOX;
const glyph = 'data:image/svg+xml;base64,' +
  readFileSync(join(root, 'design/icons/icon-master-white-glyph.svg')).toString('base64');

const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto('about:blank');
for (const n of [192, 512]) {
  const url = await page.evaluate(async ({ glyph, n, BG, S }) => {
    const img = new Image(); img.src = glyph; await img.decode();
    const c = document.createElement('canvas'); c.width = c.height = n;
    const x = c.getContext('2d');
    x.fillStyle = BG; x.fillRect(0, 0, n, n);       // carré plein — iOS/Android masquent eux-mêmes
    x.imageSmoothingQuality = 'high';
    const d = n * S, off = (n - d) / 2;             // centré, le débord est de la marge transparente
    x.drawImage(img, off, off, d, d);
    return c.toDataURL('image/png');
  }, { glyph, n, BG, S });
  const buf = Buffer.from(url.split(',')[1], 'base64');
  writeFileSync(join(root, `icon-${n}.png`), buf);
  console.log(`icon-${n}.png    ${buf.length} o (glyphe ~88 %)`);
}
await browser.close();
