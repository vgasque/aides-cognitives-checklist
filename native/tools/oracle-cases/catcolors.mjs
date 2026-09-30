// Couleurs de catégorie : PALETTE, hexToOklch, catHueDeg, catHueHex (360 degrés), catHueSnap,
// dEok, catLisible, catRegNear, catSafeTwin — presets, registres, anciennes teintes, hex courts,
// couleurs quelconques tirées au sort.
let seed = 99;
// Générateur congruentiel sur 32 bits EXACTS (Math.imul) : en flottant, le produit dépassait 2^53 et
// la suite dégénérait vers zéro (constaté : des documents « tirés au sort » tous vides).
const rnd = n => { seed = (Math.imul(seed, 1103515245) + 12345) >>> 0; return (seed >>> 8) % n; };
const COLS = ['#905a39', '#7a2f6b', '#b23240', '#8d5c39', '#a32e1f', '#c43d34', '#7a5900', '#b45309', '#1d7a38', '#ffffff', '#000000', '#abc', '#ABCDEF',
  '#45556b', '#12345678', '#1f5fa6', '#e11d48', '#f59e0b', '#16a34a', '#2563eb'];
for (let i = 0; i < 60; i++) COLS.push('#' + [0, 0, 0].map(() => rnd(256).toString(16).padStart(2, '0')).join(''));
export const inputs = [{ k: 'cols', cols: COLS }, { k: 'hues' }];
export function run(inputs) {
  return inputs.map(x => {
    if (x.k === 'hues') return { hex: Array.from({ length: 360 }, (_, h) => catHueHex(h)), extra: [-30, 360, 725, 12.5].map(catHueHex),
      snap: Array.from({ length: 360 }, (_, h) => catHueSnap(h, h % 7 ? null : '#7a2f6b')), palette: PALETTE,
      // Couleur d'origine HORS palette, rendue à son propre degré (A312) — et pas à un autre.
      orig: ['#123456', '#abcdef', '#8d5c39', '#e11d48'].map(c => [catHueSnap(catHueDeg(c), c), catHueSnap((catHueDeg(c) + 1) % 360, c)]) };
    return x.cols.map(c => ({ c, oklch: hexToOklch(c), deg: catHueDeg(c), lis: catLisible(c), near: catRegNear(c), twin: catSafeTwin(c) || null,
      d: x.cols.slice(0, 12).map(o => dEok(c, o)) }));
  });
}

// Fixture compacte (JSON sans indentation).
export const compact = true;
