#!/usr/bin/env node
/* check-guide (A467) — « Prendre en main » et l'exercice guidé citent l'app : ils doivent la suivre quand
   elle change (demande de l'auteur). Statique, donc à chaque commit :
   1. chaque libellé cité « … » dans GUIDE_GESTES, GLOSSAIRE et GUIDE_ETAPES existe ailleurs dans l'app
      (un bouton renommé sans le guide laisserait un geste qui renvoie à un mot disparu) ;
   2. chaque sélecteur visé par GUIDE_ETAPES (`tgt:`) est émis : #id, .classe, [data-…] ;
   3. chaque icône de GUIDE_GESTES existe dans `uiIcon` ;
   4. chaque étape a son geste dans `audit-guide.mjs`, qui déroule le guide en entier.
   Un exemple (« Chocs ≥ 3 : … ») porte des points de suspension : il n'est pas un libellé et n'est pas lu. */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const src = readFileSync(join(ROOT, 'index.html'), 'utf8');
const audit = readFileSync(join(ROOT, 'scripts/audit-guide.mjs'), 'utf8');
const blank = m => m.replace(/[^\n]/g, ' ');
const fautes = [];

const bloc = (debut, fin) => {
  const i = src.indexOf(debut), j = src.indexOf(fin, i);
  if (i < 0 || j < 0) { console.error(`✗ check-guide : « ${debut} » introuvable — le contrôle est périmé.`); process.exit(1); }
  return [i, j];
};
const B = {
  GUIDE_GESTES: bloc('const GUIDE_GESTES=[', '];\nconst GLOSSAIRE'),
  GLOSSAIRE: bloc('const GLOSSAIRE=[', '];\nconst guideModal'),
  GUIDE_ETAPES: bloc('const GUIDE_ETAPES=[', '\nlet _gd=null;'),
};
// Le reste de l'app, tables du guide et commentaires effacés : un mot n'y compte que s'il y est EMPLOYÉ.
let reste = src;
for (const [i, j] of Object.values(B)) reste = reste.slice(0, i) + blank(reste.slice(i, j)) + reste.slice(j);
reste = reste.replace(/<!--[\s\S]*?-->/g, blank).replace(/\/\*[\s\S]*?\*\//g, blank);
const sansCss = reste.replace(/<style[\s\S]*?<\/style>/g, blank);
const texte = s => s.replace(/\\u00a0|\u00a0|\u202f/g, ' ').replace(/\\?[’']/g, "'");   // insécables, apostrophes typographiques ou échappées
const resteTxt = texte(reste);

// 1. Libellés cités
let nLib = 0;
for (const [nom, [i, j]] of Object.entries(B)) {
  for (const m of src.slice(i, j).matchAll(/«\s*([^»]+?)\s*»/g)) {
    const lib = m[1];
    if (/…|\$\{|'\+|\+'/.test(lib)) continue;
    nLib++;
    if (!resteTxt.includes(texte(lib))) fautes.push(`${nom} cite « ${lib} », absent du reste de l'app`);
  }
}
// 2. Sélecteurs visés
let nSel = 0;
const [ei, ej] = B.GUIDE_ETAPES, etapes = src.slice(ei, ej);
for (const m of etapes.matchAll(/(?:tgt|voir|avec):'([^']+)'/g)) {   // cible, ce qu'on amène en vue, ce que le voile découvre aussi
  const sel = m[1].replace(/\[aria-[^\]]+\]/g, '');
  for (const x of sel.matchAll(/#([\w-]+)/g)) { nSel++;
    if (!new RegExp(`id=["'\\\\]*${x[1]}["'\\\\]`).test(sansCss)) fautes.push(`GUIDE_ETAPES vise #${x[1]}, qui n'est émis nulle part`); }
  for (const x of sel.replace(/#[\w-]+/g, '').matchAll(/\.([a-z][\w-]*)/g)) { nSel++;
    if (!new RegExp(`(?<![\\w.#-])${x[1]}(?![\\w-])`).test(sansCss)) fautes.push(`GUIDE_ETAPES vise .${x[1]}, classe qu'aucun code n'émet`); }
  for (const x of sel.matchAll(/\[(data-[\w-]+)/g)) { nSel++;
    if (!sansCss.includes(x[1])) fautes.push(`GUIDE_ETAPES vise [${x[1]}], attribut qu'aucun code n'émet`); }
}
// 3. Icônes des gestes
const ui = src.slice(src.indexOf('function uiIcon('), src.indexOf('function uiIcon(') + 20000);
const [gi, gj] = B.GUIDE_GESTES;
for (const m of src.slice(gi, gj).matchAll(/\['([\w-]+)','/g))
  if (!new RegExp(`[{,\\s]${m[1]}:`).test(ui)) fautes.push(`GUIDE_GESTES : icône « ${m[1]} » absente de uiIcon`);
// 4. Chaque étape a son geste dans le harnais
const ids = [...etapes.matchAll(/\{id:'([\w-]+)'/g)].map(m => m[1]);
for (const id of ids) if (!audit.includes(`id === '${id}'`)) fautes.push(`étape « ${id} » sans geste dans scripts/audit-guide.mjs`);

if (fautes.length) {
  console.error(`✗ check-guide : ${fautes.length} écart(s) entre le guide et l'app :`);
  fautes.forEach(f => console.error('    ' + f));
  console.error('  -> un geste de session a changé : mettre à jour GUIDE_ETAPES / GUIDE_GESTES / GLOSSAIRE (A467).');
  process.exit(1);
}
console.log(`✓ check-guide : ${nLib} libellé(s) cité(s), ${nSel} sélecteur(s), ${ids.length} étape(s) — le guide suit l'app.`);
