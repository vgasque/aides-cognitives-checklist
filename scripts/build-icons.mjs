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
   - anneau : le RAYON EXTÉRIEUR (228) est l'invariant, pas le rayon médian. C'est lui qui fixe
     l'emprise d'encre, donc les marges négatives de `.brand-logo` dans index.html — amincir le
     trait se fait TOUJOURS vers l'intérieur, `R = R_OUT - SW/2`, sinon l'alignement du logo sur
     la marge de page devient faux sans que rien ne le dise ;
     coupure bornée à 300°-360°, juste ce qu'il faut pour laisser sortir la coche — plus large,
     l'onglet se retrouvait en porte-à-faux ;
   - coche : bras court 136 u, bras long 393 u (rapport 2,9), sortie à 326°, trait à 90 % de
     l'anneau — c'est le rapport fût/délié d'une romane, et c'est ce qui accorde le glyphe au
     mot-marque, qui est une Source Serif ;
   - onglet : décalé de 62 u à gauche (140/24 de part et d'autre de l'axe). Le décalage est FRANC
     à dessein — à 36 u il se lisait comme un défaut de centrage.
     TRAPÈZE, ET LA PENTE N'EST PAS DÉCORATIVE : en rectangle, le bord droit coupait l'arc de
     l'anneau à angle vif et laissait un DÉCROCHEMENT — l'ensemble se lisait comme un col de fiole
     plutôt que comme un intercalaire. La pente (22° du vertical) est celle d'un onglet de classeur.
     ⚠ SON PIED SUIT L'ARC, IL N'EST PLUS UNE BARRE DROITE (v5.6) : il descendait jusqu'au bord
     INTÉRIEUR du trait, ce qui n'était tenable QUE pour un trait de 56 — une corde horizontale
     n'est contenue dans la bande que si `dy >= R_in` au milieu ET `hypot(144,dy) <= R_OUT` au
     bord, deux conditions dont la fenêtre se referme quand la bande maigrit (à 40 : il faudrait
     dy >= 188 et dy <= 176,8). Le pied POINTAIT donc dans le vide de l'anneau — signalé à
     l'œil : « le bouton sur le dessus dépasse ». Il suit désormais le cercle MÉDIAN de
     l'anneau : par construction il est enfoui de SW/2 de chaque côté, quel que soit le trait.
     ⚠ ET C'EST LE MÉDIAN, PAS L'EXTÉRIEUR : posé sur l'arc extérieur, l'onglet et la bande
     partagent une frontière EXACTE, chacun n'y couvre que la moitié du pixel, et l'anticrénelage
     rend un LISERÉ CLAIR le long de la jonction — deux encres qui se touchent doivent se
     RECOUVRIR. La silhouette reste celle du trapèze d'origine : tout ce que l'onglet a sous
     l'arc extérieur est noyé dans l'encre du trait. Les extrémités sont CALCULÉES, jamais
     recopiées : le dessin survit à un changement de trait, ce que la version en dur ne faisait
     pas.
   - bouts COUPÉS, jamais arrondis (identité de marque v1) : SF Symbols et Material 3 arrondissent,
     mais l'arrondi date sa décennie et la coupe à plat est le trait constitutif de cette marque. */
const R_OUT = 228;                      // rayon EXTÉRIEUR — l'invariant du dessin
const SW    = 40;                       // trait de l'anneau (voir « ÉPAISSEUR » ci-dessous)
const SW_16 = 56;                       // ... sauf sur le raster de 16 px (voir « HINTING »)
const r3    = n => +n.toFixed(2);

/* ÉPAISSEUR — calibrée sur le MOT, pas à l'œil (v5.6, signalé à l'usage : « le logo contraste
   avec l'épaisseur du texte »). Le mot-marque est Source Serif 4 à 17,5 px / 600 ; son fût
   vertical mesure 2,20 px au canevas (« A » perpendiculaire au jambage, « d » : 2,20 ; « I » :
   2,35). Un monolinéaire paraît plus lourd qu'une romane à épaisseur égale, d'où une cible à
   85-90 % : SW=40 rend 1,93 px dans la boîte de 34 px du masque (facteur 1024/(34*1.45)=20,77),
   soit 88 %. Le trait d'origine (56) rendait 2,70 px, soit 123 % du fût — c'est ce que l'œil
   voyait.

   HINTING DU 16 px — UNE COMPENSATION DE RENDU N'EST PAS UNE DIVERGENCE DE DESSIN. Sur la tuile,
   un pixel vaut 51,2 unités (1024/(1.25*16)) : à 40 l'anneau ne rend que 0,78 px, c'est-à-dire
   AUCUNE ligne pleine — le trait se délave en gris et la coche disparaît. Le 16 px garde donc le
   trait de 56, qui rend 1,09 px. C'est la même logique que le hinting d'une fonte : sous ~1 px, ce
   n'est plus une épaisseur qu'on choisit mais une grille qu'on subit, et le dessin doit s'y poser.
   La borne est étroite et elle le reste : la compensation ne vaut QUE pour ce raster (32 px rend
   déjà 1,56 px à 40, net et plus juste), et personne ne compare un onglet de 16 px à l'en-tête.
   Toutes les autres sorties — masque, SVG, PNG d'application, ICO 32 et 48 — partagent SW.
   NE PAS descendre SW sous ~36 : en dessous la coche s'efface aussi à 32 px. */

/* La géométrie DÉCOULE du trait : rayon médian, coupure, et pied de l'onglet. Tout écrire en
   fonction de `sw` est ce qui rend le hinting possible sans recopier un second dessin — une
   variante recopiée finirait par diverger (leçon des listes tenues en double de ce dépôt). */
const glyphe = (sw) => {
  const R = R_OUT - sw / 2;                  // rayon médian du cercle tracé
  const C = 2 * Math.PI * R;                 // circonférence, pour la coupure à 300°/60°
  // Pied de l'onglet : intersections du bord incliné et du bord gauche avec le cercle MÉDIAN.
  const inter = (x0, y0, dx, dy) => {        // point de (x0,y0)+t(dx,dy) sur le cercle R
    const ax = x0 - 512, ay = y0 - 512;
    const a = dx * dx + dy * dy, b = 2 * (ax * dx + ay * dy), c = ax * ax + ay * ay - R * R;
    const t = (-b - Math.sqrt(b * b - 4 * a * c)) / (2 * a);
    return [x0 + t * dx, y0 + t * dy];
  };
  const [PX, PY] = inter(490, 236, 42, 104);               // bord incliné  -> arc
  const QY = 512 - Math.sqrt(R * R - 144 * 144);           // bord gauche x=368 -> arc
  return `
  <circle cx="512" cy="512" r="${r3(R)}" stroke-dasharray="${r3(C * 5 / 6)} ${r3(C / 6)}"/>
  <path d="M372 528 L482 608 L752 322" stroke-width="${Math.round(sw * 0.9)}"/>
  <path d="M368 236 L490 236 L${r3(PX)} ${r3(PY)} A${r3(R)} ${r3(R)} 0 0 0 368 ${r3(QY)} Z" fill="COLOR" stroke="none"/>`;
};

const marque = (color, scale, sw = SW) => `<g transform="translate(512 512) scale(${scale}) translate(-512 -512)"
  fill="none" stroke="${color}" stroke-width="${sw}" stroke-linecap="butt" stroke-linejoin="bevel">
  ${glyphe(sw).replaceAll('COLOR', color)}
</g>`;

const svg = ({ bg = null, rx = 0, color, scale, sw }) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">`
  + (bg ? `<rect width="1024" height="1024"${rx ? ` rx="${rx}"` : ''} fill="${bg}"/>` : '')
  + marque(color, scale, sw) + `</svg>`;

const BLEU = '#1F5FA6', BLANC = '#FFFFFF';

// Échelles : .95 = zone sûre Material (masquable) · 1.12 = icône d'app (rien ne la masque)
// · 1.25 = favicon (il doit tenir à 16 px) · 1.45 = glyphe nu (il remplit sa boîte de masque).
const SVGS = {
  'logo-glyph.svg': svg({ color: '#000000', scale: 1.45 }),           // masque CSS : seul l'alpha sert
  'favicon.svg':    svg({ bg: BLEU, rx: 230, color: BLANC, scale: 1.25 })
};
// Le SEUL raster qui n'est pas tiré de `favicon.svg` : sous 1 px de trait, on hinte (cf. plus haut).
const FAVICON_16 = svg({ bg: BLEU, rx: 230, color: BLANC, scale: 1.25, sw: SW_16 });

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
  ['favicon-16.png',          16, FAVICON_16]                   // trait hinté, cf. « HINTING DU 16 px »
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
for (const size of ICO_SIZES) icoImgs.push({ size, buf: await raster(size === 16 ? FAVICON_16 : SVGS['favicon.svg'], size) });
writeFileSync(join(ROOT, 'favicon.ico'), buildIco(icoImgs));
console.log(`  favicon.ico  (${ICO_SIZES.join('+')})`);

await browser.close();
console.log('\n⚠ Les appareils DÉJÀ INSTALLÉS garderont les anciennes icônes tant que la version');
console.log('  n\'est pas montée : ./release.sh X.Y.Z (le cache du service worker est versionné).');
