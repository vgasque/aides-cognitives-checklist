/* UN `#id` NE REPREND PAS EN SILENCE LA RESPIRATION DU CORPS DE FENÊTRE (v5.19.6).
 *
 * HISTOIRE. A268 (v5.18.5) a réparé l'anneau de focus rogné par le défileur des fenêtres : le
 * corps `.ai-card>.ai-body` écarte son bord de découpe de 4 px (`padding-inline:4px`) et rend ces
 * 4 px par une marge négative (`margin-inline:-4px`) — la découpe respire, le contenu ne bouge
 * pas. Sept mois plus tard, la même capture revenait : « la bordure du bouton Tout est toujours
 * coupée par la fenêtre ». La feuille de filtres portait `#filtSheetBody{…;padding:0 0 4px}` — un
 * `#id` l'emporte sur `.ai-card>.ai-body`, et le RACCOURCI `padding` remet les quatre côtés, donc
 * l'axe inline à ZÉRO. Pire que le statu quo d'avant A268 : la marge négative, elle, survivait et
 * ne compensait plus rien, si bien que les chips partaient 4 px PLUS à gauche que le titre de la
 * fenêtre — pile sur la découpe. Mesuré : 0 px de garde pour « Tout », « Toutes » et « Gérer »,
 * contre 3,9 px dans les seize autres corps de fenêtre.
 *
 * CE QUI EST MESURÉ : aucune règle CIBLANT un corps de fenêtre par son `#id` ne pose une
 * respiration inline inférieure à 4 px — ni par `padding`/`padding-inline` en raccourci, ni par
 * `padding-left`/`padding-right`. Les règles qui visent un DESCENDANT (`#xBody .chiprow`) ne sont
 * pas concernées : elles ne touchent pas le bord de découpe. Une valeur SUPÉRIEURE à 4 px passe
 * (elle écarte davantage, elle ne rogne rien) ; une valeur non littérale (`var()`, `calc()`) est
 * signalée, faute de pouvoir en juger ici.
 *
 * POURQUOI STATIQUE ET NON À LA SONDE : le défaut est une question de CASCADE, pas de rendu — il
 * se lit dans la feuille, il coûte une milliseconde, et il tient donc dans la porte de commit.
 * Un harnais ne l'aurait vu que sur une surface ouverte, et la feuille de filtres n'est ouverte
 * par AUCUN des dix-huit (c'est aussi pour cela qu'il a vécu).
 *
 * VÉRIFIÉ CAPABLE D'ÉCHOUER : rejoué sur l'état d'avant correctif (`padding:0 0 4px`) -> ROUGE,
 * fichier restauré à l'octet.
 */
import { readFileSync } from 'node:fs';
import { stripComments } from './strip-comments.mjs';

const src = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const css = stripComments(src.slice(src.indexOf('<style>'), src.lastIndexOf('</style>')));

/* Les corps de fenêtre se déclarent dans la coque HTML : `class="… ai-body …"` + un `id`.
   On lit la SOURCE, jamais une liste tenue à la main — un corps ajouté demain entre tout seul. */
const CORPS = new Set();
for (const t of src.matchAll(/<[a-z]+\b[^>]*\bclass="[^"]*\bai-body\b[^"]*"[^>]*>/gi)) {
  const id = /\bid="([^"]+)"/.exec(t[0]);
  if (id) CORPS.add(id[1]);
}
if (!CORPS.size) {
  console.error('✗ check-ring : aucun `.ai-body` trouvé dans la coque — le motif a dérivé.');
  process.exit(1);
}

const GARDE = 4;                                   // 2 px d'anneau + 2 px de décalage (A268)
const px = v => { const t = v.trim(); if (/^-?0(\.0+)?$/.test(t)) return 0;
  const m = /^(-?[\d.]+)px$/.exec(t); return m ? parseFloat(m[1]) : null; };

/* Respiration inline posée par un corps de déclarations, ou null si la règle n'y touche pas.
   L'ordre compte : la dernière déclaration gagne, comme dans la cascade. */
function inlineDe(corps) {
  let g = null, d = null, brut = null;
  for (const m of corps.matchAll(/(?:^|;)\s*(padding(?:-inline(?:-start|-end)?|-left|-right)?)\s*:\s*([^;]+)/g)) {
    const prop = m[1], val = m[2].trim(), parts = val.split(/\s+/);
    if (prop === 'padding') { g = parts[3] !== undefined ? parts[3] : parts[1] !== undefined ? parts[1] : parts[0]; d = parts[1] !== undefined ? parts[1] : parts[0]; }
    else if (prop === 'padding-inline') { g = parts[0]; d = parts[1] !== undefined ? parts[1] : parts[0]; }
    else if (prop === 'padding-inline-start' || prop === 'padding-left') g = val;
    else if (prop === 'padding-inline-end' || prop === 'padding-right') d = val;
    else continue;
    brut = prop + ':' + val;
  }
  return brut === null ? null : { g, d, brut };
}

const fautes = [];
for (const m of css.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
  const sels = m[1].trim().split('\n').pop().trim();
  const decl = m[2];
  for (const sel of sels.split(',')) {
    /* Le DERNIER compound du sélecteur est la cible : `#filtSheetBody` vise le corps,
       `#filtSheetBody .chiprow` vise un descendant et ne touche pas le bord de découpe. */
    const cible = sel.trim().split(/[\s>+~]+/).pop() || '';
    const id = /#([\w-]+)/.exec(cible);
    if (!id || !CORPS.has(id[1])) continue;
    const p = inlineDe(decl);
    if (!p) continue;
    for (const [cote, v] of [['gauche', p.g], ['droite', p.d]]) {
      if (v == null) continue;
      const n = px(v);
      if (n === null) {
        fautes.push({ sel: sel.trim(), quoi: `respiration ${cote} non littérale (« ${v} ») — illisible ici`, brut: p.brut });
      } else if (n < GARDE) {
        fautes.push({ sel: sel.trim(), quoi: `respiration ${cote} de ${n} px (< ${GARDE}) : l'anneau de focus sera rogné`, brut: p.brut });
      }
    }
  }
}

if (fautes.length) {
  console.error('✗ check-ring : ' + fautes.length + ' corps de fenêtre reprennent la respiration d’A268 :');
  fautes.forEach(f => console.error('   · ' + f.sel + '  {' + f.brut + '}\n       ' + f.quoi
    + '\n       remède : ne régler que l’axe voulu (`padding-block`), laisser l’inline à `.ai-card>.ai-body`'));
  process.exit(1);
}

console.log('✓ check-ring : ' + CORPS.size + ' corps de fenêtre gardent les ' + GARDE
  + ' px d’écart qui laissent l’anneau de focus entier.');
