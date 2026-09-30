// EXTRACTION DES TOKENS — source de vérité : le CSS d'`index.html`.
//
// Lit les déclarations de propriétés personnalisées là où la PWA les pose, et les RÉSOUT
// (`var()`, `rgb(var(--ok-rgb))`, `transparent`) pour chaque contexte :
//   • `light`    — `:root` (hors @media) ;
//   • `dark`     — `html[data-theme="dark"]` (hérite de light pour ce qu'il ne redéclare pas) ;
//   • `contrast` — `@media (prefers-contrast:more)` : surcharges appliquées aux DEUX thèmes ;
//   • `accents`  — `body[data-accent="x"]` et sa variante sombre (couleur du disque de compte) ;
//   • `palette`  — `const PALETTE=[…]` (nuancier des catégories, A408).
// Les déclarations propres à un composant (`html[data-theme="dark"] .rt-dock{…}`) et les
// paliers de largeur (`@media (min-width…) :root{--col-state…}`) ne sont PAS des tokens globaux :
// ils restent dans leur composant, de chaque côté.
//
// Sortie : un objet sérialisable (cf. `toJSON`) consommé par `design/build.mjs`
// (tokens.json) et par `native/tools/build-tokens.mjs` (Swift). Déterministe : ni date ni aléa.

const stripComments = (s) => s.replace(/\/\*[\s\S]*?\*\//g, '');

/** Blocs `sélecteur{corps}` de premier niveau, avec la condition @media englobante éventuelle. */
function blocks(css) {
  const out = [];
  let i = 0, media = null, depth = 0, mediaDepth = -1;
  let start = 0;
  while (i < css.length) {
    const c = css[i];
    if (c === '{') {
      const head = css.slice(start, i).trim();
      if (head.startsWith('@')) {
        if (depth === 0) { media = head; mediaDepth = depth; }
        depth++;
        start = i + 1; i++; continue;
      }
      const end = css.indexOf('}', i);
      out.push({ sel: head, body: css.slice(i + 1, end), media: depth > 0 ? media : null });
      i = end + 1; start = i; continue;
    }
    if (c === '}') {
      depth--;
      if (depth <= mediaDepth) { media = null; mediaDepth = -1; }
      start = i + 1;
    }
    i++;
  }
  return out;
}

const decls = (body) => Object.fromEntries(
  [...body.matchAll(/(--[\w-]+)\s*:\s*([^;]+)/g)].map((m) => [m[1].slice(2), m[2].trim()]));

/** Résout les `var(--x)` (récursivement) dans un contexte donné. */
function resolve(ctx) {
  const out = {};
  const get = (k, seen = new Set()) => {
    if (!(k in ctx)) return undefined;
    if (seen.has(k)) throw new Error('Cycle de tokens : ' + [...seen, k].join(' → '));
    seen.add(k);
    return ctx[k].replace(/var\(--([\w-]+)(?:,([^)]*))?\)/g, (_, n, fb) => {
      const v = get(n, new Set(seen));
      return v !== undefined ? v : (fb ?? '').trim();
    });
  };
  for (const k of Object.keys(ctx)) out[k] = get(k);
  return out;
}

// ---- Valeurs typées -------------------------------------------------------------------------

/** Couleur CSS → { hex: 'rrggbb', a: 0…1 } ; null si ce n'est pas une couleur simple. */
export function parseColor(v) {
  if (typeof v !== 'string') return null;
  v = v.trim().toLowerCase();
  if (v === 'transparent') return { hex: '000000', a: 0 };
  let m = v.match(/^#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/);
  if (m) {
    let h = m[1];
    if (h.length === 3) h = [...h].map((c) => c + c).join('');
    const a = h.length === 8 ? parseInt(h.slice(6), 16) / 255 : 1;
    return { hex: h.slice(0, 6), a: +a.toFixed(3) };
  }
  m = v.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)$/);
  if (m) {
    const hex = [m[1], m[2], m[3]].map((x) => (+x).toString(16).padStart(2, '0')).join('');
    return { hex, a: m[4] !== undefined ? +(+m[4]).toFixed(3) : 1 };
  }
  return null;
}
const parsePx = (v) => { const m = v.trim().match(/^(-?[\d.]+)px$/); return m ? +m[1] : null; };
const parseMs = (v) => { const m = v.trim().match(/^([\d.]+)ms$/); return m ? +m[1] : null; };
/** Ombre CSS → couches { x, y, blur, color } (la première couche suffit à SwiftUI ; toutes gardées). */
function parseShadow(v) {
  if (v.trim() === 'none') return [];
  return v.split(/,(?![^(]*\))/).map((layer) => {
    const color = layer.match(/rgba?\([^)]*\)|#[0-9a-f]{3,8}/i);
    const nums = layer.replace(color ? color[0] : '', '').trim().split(/\s+/).map(parsePx);
    return { x: nums[0] ?? 0, y: nums[1] ?? 0, blur: nums[2] ?? 0, color: color ? parseColor(color[0]) : null };
  });
}

// ---- Extraction -----------------------------------------------------------------------------

export function extractTokens(html) {
  const s0 = html.indexOf('<style>'), s1 = html.indexOf('</style>');
  if (s0 < 0 || s1 < 0) throw new Error('Bloc <style> introuvable');
  const css = stripComments(html.slice(s0 + 7, s1));
  const bs = blocks(css);

  const light = {}, darkOnly = {}, contrast = {}, accents = {};
  for (const b of bs) {
    const d = decls(b.body);
    if (!Object.keys(d).length) continue;
    const sels = b.sel.split(',').map((x) => x.trim());
    if (b.media && /prefers-contrast\s*:\s*more/.test(b.media)) {
      if (sels.some((x) => x === ':root' || x === 'html[data-theme="dark"]')) Object.assign(contrast, d);
      continue;
    }
    if (b.media) continue;                                 // paliers de largeur : pas globaux
    let am;
    if ((am = b.sel.match(/^(html\[data-theme="dark"\]\s+)?body\[data-accent="([\w-]+)"\]$/))) {
      (accents[am[2]] ??= {})[am[1] ? 'dark' : 'light'] = d.accent;
      continue;
    }
    if (sels.includes(':root')) Object.assign(light, d);
    else if (b.sel === 'html[data-theme="dark"]') Object.assign(darkOnly, d);
  }
  if (!Object.keys(light).length || !Object.keys(darkOnly).length) throw new Error('Tokens :root ou sombres introuvables');

  const L = resolve(light), D = resolve({ ...light, ...darkOnly });
  const LC = resolve({ ...light, ...contrast }), DC = resolve({ ...light, ...darkOnly, ...contrast });

  const colors = {}, sizes = {}, durations = {}, shadows = {}, fonts = {}, other = {};
  for (const k of Object.keys(light).concat(Object.keys(darkOnly).filter((k) => !(k in light)))) {
    const lv = L[k] ?? D[k], dv = D[k];
    const lc = parseColor(lv), dc = parseColor(dv);
    if (lc && dc) {
      const c = { light: lc, dark: dc };
      const hl = parseColor(LC[k] ?? DC[k]), hd = parseColor(DC[k]);
      if (k in contrast || JSON.stringify(hl) !== JSON.stringify(lc) || JSON.stringify(hd) !== JSON.stringify(dc)) {
        c.lightContrast = hl; c.darkContrast = hd;
      }
      colors[k] = c;
    } else if (/^\d+,\s*\d+,\s*\d+$/.test(lv)) {
      // canal RVB brut (--ok-rgb) : consommé par `rgb(var(--…))`, résolu ci-dessus.
    } else if (parsePx(lv) !== null && lv === dv) sizes[k] = parsePx(lv);
    else if (parseMs(lv) !== null) durations[k] = parseMs(lv);
    else if (/^f-/.test(k)) fonts[k] = lv.split(',').map((x) => x.trim().replace(/^'|'$/g, ''));
    else if (/shadow/.test(k)) shadows[k] = { light: parseShadow(lv), dark: parseShadow(dv) };
    else other[k] = lv === dv ? lv : { light: lv, dark: dv };
  }

  const accentOut = {};
  for (const [n, v] of Object.entries(accents)) {
    const lc = parseColor(v.light), dc = parseColor(v.dark ?? v.light);
    if (lc && dc) accentOut[n] = { light: lc, dark: dc };
  }
  const pm = html.match(/const PALETTE=\[([^\]]+)\]/);
  if (!pm) throw new Error('PALETTE introuvable');
  const palette = pm[1].split(',').map((s) => s.replace(/['"\s]/g, ''));

  return { colors, sizes, durations, shadows, fonts, accents: accentOut, palette, other };
}

/** Sérialisation au format « Design Tokens » (W3C, $type/$value), stable (clés triées). */
export function toJSON(t) {
  const col = (c) => `#${c.hex}${c.a < 1 ? Math.round(c.a * 255).toString(16).padStart(2, '0') : ''}`;
  const sortObj = (o) => Object.fromEntries(Object.keys(o).sort().map((k) => [k, o[k]]));
  const doc = {
    $description: 'Tokens extraits de index.html (source de vérité) par design/tokens.mjs — ne pas éditer.',
    color: sortObj(Object.fromEntries(Object.entries(t.colors).map(([k, c]) => [k, {
      $type: 'color', $value: col(c.light),
      $extensions: { 'fr.aidescognitives': Object.fromEntries(Object.entries({
        dark: col(c.dark), lightContrast: c.lightContrast && col(c.lightContrast), darkContrast: c.darkContrast && col(c.darkContrast),
      }).filter(([, v]) => v)) },
    }]))),
    dimension: sortObj(Object.fromEntries(Object.entries(t.sizes).map(([k, v]) => [k, { $type: 'dimension', $value: `${v}px` }]))),
    duration: sortObj(Object.fromEntries(Object.entries(t.durations).map(([k, v]) => [k, { $type: 'duration', $value: `${v}ms` }]))),
    shadow: sortObj(Object.fromEntries(Object.entries(t.shadows).map(([k, v]) => [k, { $type: 'shadow', $value: v.light,
      $extensions: { 'fr.aidescognitives': { dark: v.dark } } }]))),
    fontFamily: sortObj(Object.fromEntries(Object.entries(t.fonts).map(([k, v]) => [k, { $type: 'fontFamily', $value: v }]))),
    accent: sortObj(Object.fromEntries(Object.entries(t.accents).map(([k, c]) => [k, { $type: 'color', $value: col(c.light),
      $extensions: { 'fr.aidescognitives': { dark: col(c.dark) } } }]))),
    palette: t.palette.map((c) => ({ $type: 'color', $value: c })),
  };
  return JSON.stringify(doc, null, 2) + '\n';
}
