#!/usr/bin/env node
// Régénère TOUTES les icônes servies à partir d'UNE seule géométrie (ci-dessous).
//
// POURQUOI UN SCRIPT ET NON DIX FICHIERS BINAIRES : dix rasters dessinés à la main divergent —
// c'est la leçon des listes tenues en double de ce dépôt. Ici la marque n'existe qu'à un seul
// endroit (`GLYPHE`), et chaque sortie n'est qu'un cadrage : couleur de fond, coins, échelle.
//
// ÉCHELLES — la contrainte la plus serrée n'est pas Apple mais Material 3 : l'icône adaptative
// ne garantit qu'un disque de 66 dp sur 108, soit 61 % du canevas (rayon 312 sur 1024). Le
// cadrage `maskable` s'y tient ; les autres, que personne ne masque, respirent davantage.
//
// ⚠ CHANGER CES OCTETS NE CHANGE PAS CE QUI EST INSTALLÉ : sw.js range les icônes dans un cache
// versionné par APP_VERSION. Sans `./release.sh X.Y.Z`, un appareil déjà installé garde les
// ANCIENNES icônes, indéfiniment et sans un mot (même piège que pdf.js, cf. AGENTS.md).
//
//   node scripts/build-icons.mjs

import { chromium } from 'playwright';
import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

/* ---- LA MARQUE, UNE FOIS -------------------------------------------------------------------
   Chronomètre coché à onglet. Canevas 1024, centre (512,512).
   - anneau r=200, trait 56 (5,5 % du canevas : sous ~4 % la coche s'efface à 29 px, et Apple
     déconseille explicitement les traits fins) ; coupure bornée à 300°-360°, juste ce qu'il faut
     pour laisser sortir la coche — plus large, l'onglet se retrouvait en porte-à-faux ;
   - coche : bras court 136 u, bras long 393 u (rapport 2,9), sortie à 326° ;
   - onglet : décalé de 62 u à gauche (140/24 de part et d'autre de l'axe). Le décalage est FRANC
     à dessein — à 36 u il se lisait comme un défaut de centrage. Il descend jusqu'au bord
     INTÉRIEUR du trait : une barre droite ne peut pas rester tangente à un cercle, elle doit le
     traverser, sinon ses extrémités décrochent.
     TRAPÈZE, ET LA PENTE N'EST PAS DÉCORATIVE : en rectangle, le bord droit coupait l'arc de
     l'anneau à angle vif et laissait un DÉCROCHEMENT — l'ensemble se lisait comme un col de fiole
     plutôt que comme un intercalaire. Le bord incliné (490,236) -> (532,340) rencontre le cercle
     extérieur à (509,284), c'est-à-dire à 0,01 u près SUR l'arc : la jonction devient tangente,
     le décrochement disparaît, et la suite du bord se noie dans la bande de trait. La pente
     (22° du vertical) est celle d'un onglet de classeur.
   - bouts COUPÉS, jamais arrondis (identité de marque v1) : SF Symbols et Material 3 arrondissent,
     mais l'arrondi date sa décennie et la coupe à plat est le trait constitutif de cette marque. */
const GLYPHE = `
  <circle cx="512" cy="512" r="200" stroke-dasharray="1047.2 209.44"/>
  <path d="M372 528 L482 608 L752 322"/>
  <path d="M368 236 L490 236 L532 340 L368 340 Z" fill="COLOR" stroke="none"/>`;

const marque = (color, scale) => `<g transform="translate(512 512) scale(${scale}) translate(-512 -512)"
  fill="none" stroke="${color}" stroke-width="56" stroke-linecap="butt" stroke-linejoin="bevel">
  ${GLYPHE.replaceAll('COLOR', color)}
</g>`;

const svg = ({ bg = null, rx = 0, color, scale }) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">`
  + (bg ? `<rect width="1024" height="1024"${rx ? ` rx="${rx}"` : ''} fill="${bg}"/>` : '')
  + marque(color, scale) + `</svg>`;

const BLEU = '#1F5FA6', BLANC = '#FFFFFF';

// Échelles : .95 = zone sûre Material (masquable) · 1.12 = icône d'app (rien ne la masque)
// · 1.25 = favicon (il doit tenir à 16 px) · 1.45 = glyphe nu (il remplit sa boîte de masque).
const SVGS = {
  'logo-glyph.svg': svg({ color: '#000000', scale: 1.45 }),           // masque CSS : seul l'alpha sert
  'favicon.svg':    svg({ bg: BLEU, rx: 230, color: BLANC, scale: 1.25 })
};

const PNGS = [
  ['icon-512-maskable.png',  512, svg({ bg: BLEU, color: BLANC, scale: 0.95 })],
  ['icon-192-maskable.png',  192, svg({ bg: BLEU, color: BLANC, scale: 0.95 })],
  // MONOCHROME (Android 13+) : glyphe NOIR sur fond TRANSPARENT — Android n'en lit que l'alpha et
  // le teinte lui-même selon le fond d'écran. Sans cette entrée, il dérive l'icône thématisée à
  // partir de la maskable, avec un résultat qu'on ne maîtrise pas. Même zone sûre que la maskable.
  ['icon-monochrome-512.png', 512, svg({ color: '#000000', scale: 0.95 })],
  ['icon-512.png',           512, svg({ bg: BLEU, color: BLANC, scale: 1.12 })],
  ['icon-192.png',           192, svg({ bg: BLEU, color: BLANC, scale: 1.12 })],
  ['apple-touch-icon.png',   180, svg({ bg: BLEU, color: BLANC, scale: 1.12 })], // opaque, coins vifs : iOS masque
  ['favicon-32.png',          32, SVGS['favicon.svg']],
  ['favicon-16.png',          16, SVGS['favicon.svg']]
];
const ICO_SIZES = [16, 32, 48];

/* ---- ICO : conteneur d'images PNG (Vista+ et tous les navigateurs modernes) ---------------- */
function buildIco(images) {
  const head = Buffer.alloc(6);
  head.writeUInt16LE(0, 0); head.writeUInt16LE(1, 2); head.writeUInt16LE(images.length, 4);
  const dir = Buffer.alloc(16 * images.length);
  let offset = 6 + dir.length;
  images.forEach(({ size, buf }, i) => {
    const o = i * 16;
    dir.writeUInt8(size >= 256 ? 0 : size, o);
    dir.writeUInt8(size >= 256 ? 0 : size, o + 1);
    dir.writeUInt8(0, o + 2); dir.writeUInt8(0, o + 3);
    dir.writeUInt16LE(1, o + 4); dir.writeUInt16LE(32, o + 6);
    dir.writeUInt32LE(buf.length, o + 8); dir.writeUInt32LE(offset, o + 12);
    offset += buf.length;
  });
  return Buffer.concat([head, dir, ...images.map(i => i.buf)]);
}

const browser = await chromium.launch();
const page = await browser.newPage();

// Rastériser à la taille FINALE, jamais réduire depuis un grand rendu : une réduction ×12
// échantillonne hors de l'image et produit une arête semi-transparente, lue comme un liseré
// blanc dans un onglet (leçon v4.22.2 -> v4.22.4, consignée dans l'en-tête d'index.html).
async function raster(markup, size) {
  await page.setViewportSize({ width: size, height: size });
  await page.setContent(`<style>html,body{margin:0;padding:0;background:transparent}
    svg{display:block;width:${size}px;height:${size}px}</style>${markup}`);
  return await page.screenshot({ omitBackground: true });
}

for (const [name, markup] of Object.entries(SVGS)) {
  writeFileSync(join(ROOT, name), markup + '\n');
  console.log(`  ${name}`);
}
for (const [name, size, markup] of PNGS) {
  writeFileSync(join(ROOT, name), await raster(markup, size));
  console.log(`  ${name}  (${size}px)`);
}
const icoImgs = [];
for (const size of ICO_SIZES) icoImgs.push({ size, buf: await raster(SVGS['favicon.svg'], size) });
writeFileSync(join(ROOT, 'favicon.ico'), buildIco(icoImgs));
console.log(`  favicon.ico  (${ICO_SIZES.join('+')})`);

await browser.close();
console.log('\n⚠ Les appareils DÉJÀ INSTALLÉS garderont les anciennes icônes tant que la version');
console.log('  n\'est pas montée : ./release.sh X.Y.Z (le cache du service worker est versionné).');
