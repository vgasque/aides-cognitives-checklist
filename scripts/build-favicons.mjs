#!/usr/bin/env node
// Génère les FAVICONS depuis les masters vectoriels de `design/icons/`.
//
//   node scripts/build-favicons.mjs
//
// Produit à la racine : favicon.svg, favicon.ico (16+32+48), favicon-16.png, favicon-32.png.
// Ces quatre fichiers sont servis et listés dans `ASSETS` (sw.js) — cf. `design/icons/README.md`.
//
// POURQUOI un script plutôt qu'un export à la main (leçon v4.22.2 → v4.22.4) :
//   1. Un favicon doit être servi à la TAILLE NATIVE de son emplacement. Servir un PNG de 192 px
//      dans un onglet de 16 px force une réduction ×12 : le filtre du rasteriseur échantillonne
//      hors de l'image et laisse une arête d'un pixel semi-transparente, lue comme un LISERÉ
//      BLANC sur une barre d'onglets claire.
//   2. Le favicon est le SEUL jeu d'icônes à porter des COINS ARRONDIS. Les icônes d'application
//      (icon-*.png, apple-touch-icon.png, maskables) restent des CARRÉS PLEINS : iOS et Android
//      appliquent leur propre masque, les pré-arrondir donnerait un double arrondi. Le favicon,
//      lui, n'est masqué par personne et se pose dans un conteneur déjà arrondi.
//
// Le rendu passe par Chromium (Playwright, dev-dépendance existante) : aucune dépendance runtime
// n'est ajoutée, et le script ne tourne JAMAIS en production ni en intégration continue.
import { chromium } from 'playwright';
import { readFileSync, writeFileSync, copyFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const MASTER = join(root, 'design/icons/icon-rounded-preview.svg'); // tuile arrondie, rx 22,5 %
const SIZES = [16, 32, 48];                                        // 48 : entrée .ico seulement

// --- Écriture d'un .ico à entrées PNG -----------------------------------------------------
// Format : en-tête 6 o + n × entrée de 16 o + charges utiles. Les entrées PNG (au lieu du DIB
// historique) sont décodées par tous les moteurs visés, WebKit compris.
function buildIco(pngs) {
  const head = Buffer.alloc(6);
  head.writeUInt16LE(0, 0);            // réservé
  head.writeUInt16LE(1, 2);            // type 1 = icône
  head.writeUInt16LE(pngs.length, 4);
  const dir = Buffer.alloc(16 * pngs.length);
  let offset = head.length + dir.length;
  pngs.forEach(({ size, data }, i) => {
    const e = i * 16;
    dir.writeUInt8(size >= 256 ? 0 : size, e + 0);   // largeur (0 = 256)
    dir.writeUInt8(size >= 256 ? 0 : size, e + 1);   // hauteur
    dir.writeUInt8(0, e + 2);                        // palette
    dir.writeUInt8(0, e + 3);                        // réservé
    dir.writeUInt16LE(1, e + 4);                     // plans
    dir.writeUInt16LE(32, e + 6);                    // bits/pixel
    dir.writeUInt32LE(data.length, e + 8);
    dir.writeUInt32LE(offset, e + 12);
    offset += data.length;
  });
  return Buffer.concat([head, dir, ...pngs.map(p => p.data)]);
}

const svg = readFileSync(MASTER);
const dataUrl = 'data:image/svg+xml;base64,' + svg.toString('base64');

const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto('about:blank');

const pngs = [];
for (const size of SIZES) {
  const url = await page.evaluate(async ({ dataUrl, size }) => {
    const img = new Image();
    img.src = dataUrl;
    await img.decode();
    const c = document.createElement('canvas');
    c.width = c.height = size;
    const x = c.getContext('2d');
    x.imageSmoothingQuality = 'high';
    x.drawImage(img, 0, 0, size, size);   // rendu à la taille FINALE, jamais un downscale de PNG
    return c.toDataURL('image/png');
  }, { dataUrl, size });
  pngs.push({ size, data: Buffer.from(url.split(',')[1], 'base64') });
}
await browser.close();

for (const { size, data } of pngs) {
  if (size === 48) continue;                          // 48 ne vit que dans le .ico
  writeFileSync(join(root, `favicon-${size}.png`), data);
  console.log(`favicon-${size}.png    ${data.length} o`);
}
const ico = buildIco(pngs);
writeFileSync(join(root, 'favicon.ico'), ico);
console.log(`favicon.ico        ${ico.length} o (${SIZES.join('+')})`);
copyFileSync(MASTER, join(root, 'favicon.svg'));
console.log(`favicon.svg        ${svg.length} o (master vectoriel)`);
