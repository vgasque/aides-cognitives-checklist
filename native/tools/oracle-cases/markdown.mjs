// Mini-Markdown : mdBlocks, mdInline, mdRender (+ images), mdStrip, mdCells, mdCallout, mdTask et
// les clés de repli posées par mdFoldApply. Documents réalistes, cas limites, et un lot FUZZ
// déterministe (fragments de lignes tirés par un générateur à graine).
const DOCS = [
  '# Anaphylaxie\n\n## Reconnaître\n- Urticaire **généralisée**\n- Hypotension < 90\n  - sous-point\n  1. sous ordonné\n\n## Traiter\n1. Adrénaline IM :: 0,5 mg\n2) Remplissage\n\n> [!WARNING] Vérifier la dilution\n> ligne 2\n\n| Produit | Dose | Voie |\n|:--|:-:|--:|\n| Adré | 0,01 mg/kg | IM |\n| NaCl | 20 mL/kg |\n\n![Schéma](img:i1)\n![](img:i2)\n![x](img:absent)\n![bad](img:i3)\n\n---\nFin',
  '```\n| a | b |\n|---|---|\n# pas un titre\n```\ntexte',
  '```js\nnon refermé\n> rien',
  '- [ ] à faire\n- [x] fait\n- [X] fait aussi\n- [] pas tâche\n- [y] pas tâche\n* [ ]\n1. [x] ordonnée\n  - [ ] sous-item reste texte',
  '> [!caution] danger\n> [!info] seconde ligne garde le marqueur\n\n> ⚠️ glyphe\n\n> △\n\n> [!constructor] quirk\n\n> [!inconnu] reste\n\n>sans espace\n> [!OK]\n> [!Astuce]   espaces',
  '#### quatre\n#sans espace\n# \n##  deux espaces\n### Titre ~ spécial & <b>\n# Titre\n# Titre\npara',
  'ligne 1\nligne 2\n- item\npara après liste\n  - orphelin sous-liste',
  '| a | b\n|---|---|\n\n| x |\n| y |\n\n|a|b|c|\n|-|:-|\n|1|2|3|4|\n|1|\n| esc \\| pipe | ok |\n|---|',
  'a **gras** et *ital* et ==surligné== et `code **pas gras**`\n[lien](https://exemple.org/a?b=1&c=2) [doc](att:doc_1) [js](javascript:alert(1)) [proto](att:__proto__)\n***a** *a**b* x *y* *z* **a*b** ==a=b==',
  '[t](https://x.org/a*b*c) [t2](https://x.org/q==v==w) **[lien](https://x.org)** [**gras**](http://x.org)',
  '<script>alert("x")</script> & \' " `a` ``b`` `c\n`d`',
  '# H1\n### H3\ntexte\n## H2\n# H1\n## vide\n## Suite\ncontenu\n### Fin',
  '\r\n# crlf\r\n- item\r\n> q\r\n| a |\r\n|---|\r\n',
  '1. un\n2. deux\n- puce\n3. trois\n  1) sous\n  - autre sous\n\n***\n- - -\n--*',
  '![' + 'x'.repeat(301) + '](img:i1)\n[' + 'y'.repeat(201) + '](https://x.org)\n[' + 'z'.repeat(200) + '](https://x.org)',
  '😀 **émoji** [😀](https://x.org) `😀`\n> ℹ️ info emoji\n| 😀 | é |\n|---|---|',
  '',
  '    \n\t\n',
  '# Même titre\ncorps\n# Même titre\ncorps\n# même  titre !\ncorps\n# ???\ncorps\n# \ncorps',
];
// FUZZ : lignes tirées d'un vivier de fragments.
const FRAG = ['# T', '## Sous-titre', '### x', 'texte **g**', '- a', '- [ ] t', '- [x] u', '1. o', '  - s', '  2) s', '> q', '> [!WARNING] w',
  '> [!tip]', '| a | b |', '|---|:-:|', '| 1 | 2 |', '```', '---', '![c](img:i1)', '![c](img:zz)', '', ' ', '*i* ==m==', '`c`', 'x | y',
  '[l](https://a.b)', '[a](att:d1)', '> ⚠ alerte', '* item', '12. douze', '1234. non'];
let seed = 12345;
const rnd = n => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed % n; };
for (let d = 0; d < 60; d++) {
  const n = 3 + rnd(18), L = [];
  for (let i = 0; i < n; i++) L.push(FRAG[rnd(FRAG.length)]);
  DOCS.push(L.join('\n'));
}
const INL = ['', 'a', '**a**', '**a** **b**', '*', '**', '***', '****a****', '*a*b*', 'a*b', '*a *b*', '_a_', '==', '====', '==a==b==',
  '`', '``', '```', '`a``b`', 'a `b` c `d', '[a](b)', '[a](https://x)', '[a](HTTP://X.ORG/"q\'<>`)', '[a](att:x y)', '[](https://x)',
  '[a]( https://x)', '[a](https://x) [b](https://y)', '[[a](https://x)](https://y)', '& < > " \'', '&amp;', 'é *é* **é**',
  'x'.repeat(4001) + ' fin', 'a\nb *c\nd*', '`a\nb`'];
const CELLS = ['', '|', '||', '| a |', 'a|b', '|a|b|', ' | a \\| b | c | ', '|' + 'c|'.repeat(14), '\\|', '| a \\\\| b |'];
const CALL = ['', '[!WARNING]', '[!warning] txt', '  [! note ]  txt', '[!x]', '[!abcdefghijklm]', '[!Élan]', '⚠️ a', '⚠ a', '✔', '✓x', 'ℹ️', 'rien', '[!OK] x', '[!constructor] c'];
const TASK = ['', '[ ]', '[x]', '[X] t', '[ ]t', '[x]  t', '[y] t', '[] t', ' [ ] t', '[ ]\tt'];
export const inputs = [
  ...DOCS.map(src => ({ k: 'doc', src })),
  ...INL.map(s => ({ k: 'inline', s })),
  ...CELLS.map(s => ({ k: 'cells', s })),
  ...CALL.map(s => ({ k: 'callout', s })),
  ...TASK.map(s => ({ k: 'task', s })),
];
export function run(inputs) {
  const T = __ac_test__;
  const imgs = [
    { id: 'i1', data: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUg==', w: 120, h: 80, caption: 'Schéma', scale: 50 },
    { id: 'i2', data: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUg==', w: 0, h: 0, caption: '', scale: 100 },
    { id: 'i3', data: 'javascript:alert(1)', w: 1, h: 1, caption: 'mauvaise', scale: 33 },
    { id: 'i1', data: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUg==', w: 10, h: 10, caption: 'doublon (le dernier gagne)', scale: 75 },
  ];
  return inputs.map(x => {
    if (x.k === 'doc') {
      const html = T.mdRender(x.src, { images: imgs });
      const div = document.createElement('div');
      div.innerHTML = html;
      mdFoldApply(div, 'oracle-md');
      const folds = [...div.querySelectorAll('.md-h1,.md-h2,.md-h3')].map(h => ({ k: h._fkey || null, id: (h._sec && h._sec.id) || null }));
      return { blocks: JSON.parse(JSON.stringify(T.mdBlocks(x.src))), html, strip: T.mdStrip(x.src), folds };
    }
    if (x.k === 'inline') return T.mdInline(x.s);
    if (x.k === 'cells') return T.mdCells(x.s);
    if (x.k === 'callout') { const c = T.mdCallout(x.s); return { kind: typeof c.kind === 'string' ? c.kind : null, text: c.text, fn: typeof c.kind === 'function' }; }
    if (x.k === 'task') return T.mdTask(x.s);
    return null;
  });
}
