#!/usr/bin/env node
// GÉNÈRE `native/App/Sources/Design/Tokens.generated.swift` depuis les tokens de la PWA.
//
// Source de vérité : le CSS d'`index.html`, lu par `design/tokens.mjs` (le même extracteur qui
// écrit `design/ds/tokens/tokens.json`). Rien n'est recopié à la main : un token changé dans la
// PWA arrive dans l'app à la prochaine régénération (`npm run design:build`), et
// `npm run design:check` échoue si le fichier Swift versionné n'est plus à jour.
//
// Correspondance des noms, MÉCANIQUE : `--crit-soft` → `T.critSoft`, `--t-step-l` →
// `TypeScale.stepL`, `--r-3` → `Radius.r3`. Les couleurs portent leurs quatre variantes (jour,
// nuit, et « Augmenter le contraste » pour chacun) : le système choisit, aucune vue ne teste
// `colorScheme`.

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { extractTokens } from '../../design/tokens.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const OUT = join(ROOT, 'native', 'App', 'Sources', 'Design', 'Tokens.generated.swift');
const t = extractTokens(readFileSync(join(ROOT, 'index.html'), 'utf8'));

const camel = (k) => k.replace(/-([a-z0-9])/g, (_, c) => c.toUpperCase());
const hex = (c) => `0x${c.hex}`;
const num = (v) => (Number.isInteger(v) ? `${v}` : `${v}`);
const alpha = (a) => (a === 1 ? '1' : `${+a.toFixed(3)}`);

function colorExpr(c) {
  const lc = c.lightContrast ?? c.light, dc = c.darkContrast ?? c.dark;
  const same = (a, b) => a.hex === b.hex && a.a === b.a;
  if (same(c.light, c.dark) && same(lc, c.light) && same(dc, c.dark)) return `Color(hex: ${hex(c.light)}, alpha: ${alpha(c.light.a)})`;
  const args = [`light: ${hex(c.light)}`, `dark: ${hex(c.dark)}`];
  if (c.light.a !== 1) args.push(`lightAlpha: ${alpha(c.light.a)}`);
  if (c.dark.a !== 1) args.push(`darkAlpha: ${alpha(c.dark.a)}`);
  if (!same(lc, c.light) || !same(dc, c.dark)) {
    args.push(`lightContrast: ${hex(lc)}`, `darkContrast: ${hex(dc)}`);
    if (lc.a !== 1) args.push(`lightContrastAlpha: ${alpha(lc.a)}`);
    if (dc.a !== 1) args.push(`darkContrastAlpha: ${alpha(dc.a)}`);
  }
  return `Color(${args.join(', ')})`;
}

const lines = [];
const w = (s = '') => lines.push(s);
w('// ⚠ FICHIER GÉNÉRÉ — ne pas éditer. Source : les tokens CSS d\'index.html (PWA).');
w('// Régénérer : `npm run design:build` (→ design/tokens.mjs → native/tools/build-tokens.mjs).');
w('// `npm run design:check` échoue si ce fichier n\'est plus à jour avec index.html.');
w('import SwiftUI');
w();
w('/// Couleurs (`--nom` → `T.nom`, en camelCase). Quatre variantes quand la PWA en déclare :');
w('/// jour, nuit, et « Augmenter le contraste » (`@media (prefers-contrast:more)`).');
w('enum T {');
for (const [k, c] of Object.entries(t.colors)) w(`    static let ${camel(k)} = ${colorExpr(c)}`);
w();
w('    /// Nuancier des catégories (`PALETTE`, A408 : hors des registres).');
w(`    static let palette: [String] = [${t.palette.map((c) => `"${c}"`).join(', ')}]`);
w('}');
w();
w('/// Échelle typographique FERMÉE (`--t-*`, A6) — aucune valeur entre les crans.');
w('enum TypeScale {');
for (const [k, v] of Object.entries(t.sizes)) if (/^t-/.test(k)) w(`    static let ${camel(k.slice(2))}: CGFloat = ${num(v)}`);
if ('g-cmd' in t.sizes) w(`    /// Corps des commandes de session (\`--g-cmd\`).\n    static let cmd: CGFloat = ${num(t.sizes['g-cmd'])}`);
w('}');
w();
w('/// Rayons (`--r-*`).');
w('enum Radius {');
for (const [k, v] of Object.entries(t.sizes)) if (/^r-\d$/.test(k)) w(`    static let r${k.slice(2)}: CGFloat = ${num(v)}`);
w('}');
w();
w('/// Mesures de mise en page (colonnes, fenêtres, cible tactile).');
w('enum Metrics {');
for (const [k, v] of Object.entries(t.sizes)) if (!/^(t-|r-\d$|g-cmd$)/.test(k)) w(`    static let ${camel(k)}: CGFloat = ${num(v)}`);
w('}');
w();
w('/// Mouvement (`--dur-*`, `--ease-out`).');
w('enum Motion {');
for (const [k, v] of Object.entries(t.durations)) w(`    static let ${camel(k)}: Double = ${v / 1000}`);
const ease = typeof t.other['ease-out'] === 'string' && t.other['ease-out'].match(/cubic-bezier\(([^)]+)\)/);
if (ease) {
  const [a, b, c, d] = ease[1].split(',').map((x) => +x);
  w(`    /// \`--ease-out\` : cubic-bezier(${a}, ${b}, ${c}, ${d}).`);
  w(`    static func easeOut(_ duration: Double = ${t.durations['dur-2'] ? t.durations['dur-2'] / 1000 : 0.2}) -> Animation { .timingCurve(${a}, ${b}, ${c}, ${d}, duration: duration) }`);
}
w('}');
w();
w('/// Graisses (`--w-*`).');
w('enum Weights {');
const weightName = { 400: '.regular', 500: '.medium', 600: '.semibold', 700: '.bold', 800: '.heavy', 900: '.black' };
for (const [k, v] of Object.entries(t.other)) if (/^w-/.test(k) && weightName[v]) w(`    static let ${camel(k.slice(2))}: Font.Weight = ${weightName[v]}`);
w('}');
w();
w('/// Ombres (`--shadow-*`) : première couche, rayon SwiftUI = flou CSS ÷ 2. `none` → nil.');
w('enum Shadows {');
for (const [k, v] of Object.entries(t.shadows)) {
  const n = camel(k.replace(/^shadow-/, ''));
  const lay = (arr) => arr[0];
  const l = lay(v.light), d = lay(v.dark);
  if (!l || !l.color) { w(`    static let ${n}: ShadowToken? = nil`); continue; }
  const dd = d && d.color ? d : { x: 0, y: 0, blur: 0, color: { hex: '000000', a: 0 } };
  w(`    static let ${n}: ShadowToken? = ShadowToken(color: ${colorExpr({ light: l.color, dark: dd.color })}, radius: ${num(l.blur / 2)}, x: ${num(l.x)}, y: ${num(l.y)})`);
}
w('}');
w();
w('/// Couleurs d\'accent (`body[data-accent]`) : elles ne teintent que le disque du compte.');
w('enum Accent {');
w('    static let all: [(name: String, color: Color)] = [');
for (const [k, c] of Object.entries(t.accents)) w(`        ("${k}", ${colorExpr(c)}),`);
w('    ]');
w('    static func color(_ name: String) -> Color? { all.first { $0.name == name }?.color }');
w('}');
w();

writeFileSync(OUT, lines.join('\n'));
console.log(`  ✓ ${OUT.replace(ROOT + '/', '')} — ${Object.keys(t.colors).length} couleurs, ${Object.keys(t.sizes).length} mesures`);
