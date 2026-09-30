#!/usr/bin/env node
// GARDE-FOU — le design system de l'app native, jumeau des garde-fous CSS de la PWA.
//
// Les vues SwiftUI suivent LES MÊMES échelles fermées que la feuille de style d'index.html, et
// ces échelles ne sont PAS recopiées ici : elles sont lues dans les garde-fous de la PWA
// eux-mêmes (`scripts/check-type.mjs`, `check-space.mjs`, `check-radius.mjs`). Changer une
// échelle côté PWA la change des deux côtés.
//
//   · COULEURS  (≈ check-colors) : aucune couleur littérale dans une vue — `T.*` (généré depuis
//     les tokens CSS), `Shadows.*`, `Accent.*`, ou une couleur venue des DONNÉES (`Color(cssHex:)`).
//   · TYPOGRAPHIE (≈ check-type) : `.font(.system(size: <nombre>))` est refusé (on passe par
//     `.aFont`, qui suit le réglage de taille du texte) ; un corps chiffré doit être un palier.
//   · ESPACEMENT (≈ check-space) : `.padding(n)` et `spacing: n` sur l'échelle fermée.
//   · RAYONS    (≈ check-radius) : `cornerRadius: n` sur l'échelle fermée (ou `Radius.*`).
//
// EXEMPTIONS NOMMÉES ET MOTIVÉES, comme dans la PWA : un commentaire `// design: <motif>` sur
// la ligne. Une exemption sans motif (moins de deux mots) ne compte pas — « une exemption
// anonyme rouvre la porte qu'on vient de fermer ». Les fichiers `Design/Tokens*.swift` sont hors
// périmètre (c'est là que vivent les valeurs).
//
//   node native/tools/check-swift-design.mjs        → échoue (code 1) à la première faute listée
//   node native/tools/check-swift-design.mjs --list → liste tout, n'échoue pas (migration)

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const SRC = join(ROOT, 'native', 'App', 'Sources');
const listOnly = process.argv.includes('--list');

// ---- Les échelles, lues dans les garde-fous de la PWA (source unique) ------------------------
function arrayConst(file, name) {
  const s = readFileSync(join(ROOT, 'scripts', file), 'utf8');
  const m = s.match(new RegExp(`const ${name} = \\[([^\\]]+)\\]`));
  if (!m) throw new Error(`${name} introuvable dans scripts/${file} — le garde-fou Swift ne peut pas suivre la PWA`);
  return m[1].split(',').map((x) => +x.trim());
}
const TYPE = arrayConst('check-type.mjs', 'PALIERS');
// Valeurs d'exemption de check-type (16 : champs tactiles ; 38 : titre de bienvenue) — permises
// SEULEMENT avec un motif sur la ligne, comme dans la PWA où elles sont liées à un sélecteur.
const TYPE_EXEMPT = [...readFileSync(join(ROOT, 'scripts', 'check-type.mjs'), 'utf8')
  .matchAll(/val:\s*([\d.]+)/g)].map((m) => +m[1]);
const SPACE = arrayConst('check-space.mjs', 'ECHELLE');
const RADIUS = arrayConst('check-radius.mjs', 'ECHELLE');

// ---- Lecture des sources ---------------------------------------------------------------------
function walk(d) {
  return readdirSync(d).flatMap((n) => {
    const p = join(d, n);
    return statSync(p).isDirectory() ? walk(p) : (p.endsWith('.swift') ? [p] : []);
  });
}
const files = walk(SRC).filter((f) => !/Design\/Tokens(\.generated)?\.swift$/.test(f));

const faults = [];
let checked = 0, exempted = 0;
const motif = (line) => {
  const m = line.match(/\/\/\s*design:\s*(.+)$/);
  return m && m[1].trim().split(/\s+/).length >= 2 ? m[1].trim() : null;
};

for (const f of files) {
  const lines = readFileSync(f, 'utf8').split('\n');
  lines.forEach((raw, i) => {
    const code = raw.replace(/\/\/.*$/, '').replace(/"(?:\\.|[^"\\])*"/g, '""');
    const ex = motif(raw);
    const fault = (kind, msg) => {
      checked++;
      if (ex) { exempted++; return; }
      faults.push({ f: relative(ROOT, f), l: i + 1, kind, msg, src: raw.trim().slice(0, 110) });
    };
    const ok = () => { checked++; };

    // COULEURS
    for (const m of code.matchAll(/Color\((red|white|hex|light|\.sRGB|hue)\b|UIColor\(|NSColor\(|CGColor\(/g)) fault('couleur', `couleur littérale « ${m[0]} » — un token T.*`);
    for (const m of code.matchAll(/Color\.(red|blue|green|orange|yellow|gray|grey|black|white|pink|purple|brown|cyan|mint|teal|indigo)\b/g)) fault('couleur', `couleur système « ${m[0]} » — un token T.*`);
    for (const m of code.matchAll(/(?:foregroundStyle|foregroundColor|background|fill|tint|stroke|strokeBorder)\(\s*\.(red|blue|green|orange|yellow|gray|black|white|pink|purple|brown|cyan|mint|teal|indigo)\b/g)) fault('couleur', `couleur système « .${m[1]} » — un token T.*`);

    // TYPOGRAPHIE
    for (const m of code.matchAll(/\.font\(\.system\(size:\s*([\d.]+)/g)) fault('type', `.font(.system(size: ${m[1]})) — passer par .aFont (suit la taille du texte)`);
    for (const m of code.matchAll(/\.aFont\(\s*([\d.]+)/g)) {
      const v = +m[1];
      if (TYPE.includes(v)) ok();
      else if (TYPE_EXEMPT.includes(v)) fault('type', `corps ${v} : valeur d'EXEMPTION de check-type — motif requis`);
      else fault('type', `corps ${v} hors échelle (${TYPE.join(' · ')})`);
    }

    // ESPACEMENT
    for (const m of code.matchAll(/\.padding\((?:\.[a-zA-Z]+,\s*|\[[^\]]*\],\s*)?(-?[\d.]+)\)|\bspacing:\s*(-?[\d.]+)/g)) {
      const v = Math.abs(+(m[1] ?? m[2]));
      if (SPACE.includes(v)) ok(); else fault('espace', `espacement ${v} hors échelle (${SPACE.join(' · ')})`);
    }

    // RAYONS
    for (const m of code.matchAll(/cornerRadius:\s*([\d.]+)/g)) {
      const v = +m[1];
      if (RADIUS.includes(v)) ok(); else fault('rayon', `rayon ${v} hors échelle (${RADIUS.join(' · ')})`);
    }
  });
}

const byKind = faults.reduce((a, x) => ((a[x.kind] = (a[x.kind] || 0) + 1), a), {});
if (faults.length) {
  console.log(`\n✗ check-swift-design : ${faults.length} écart(s) au design system (${Object.entries(byKind).map(([k, n]) => `${k} ${n}`).join(', ')}) :`);
  for (const x of faults.slice(0, listOnly ? faults.length : 60)) console.log(`   ${x.f}:${x.l}  [${x.kind}] ${x.msg}\n      ${x.src}`);
  if (!listOnly && faults.length > 60) console.log(`   … et ${faults.length - 60} autre(s) (--list pour tout voir)`);
  console.log('\n   Exemption : `// design: <motif>` sur la ligne (motif obligatoire, comme dans la PWA).');
  process.exit(listOnly ? 0 : 1);
}
console.log(`✓ check-swift-design : ${checked} valeur(s) de design contrôlée(s) sur les échelles de la PWA `
  + `(texte ${TYPE.join(' · ')} · espace ${SPACE.length} crans · rayons ${RADIUS.join(' · ')}), ${exempted} exemption(s) motivée(s).`);
