#!/usr/bin/env node
/* ON ANIME LA COMPOSITION, JAMAIS LA MISE EN PAGE — garde-fou auto-exécutoire (v4.41.0).
 *
 * POURQUOI CE FICHIER EXISTE. `.tm-bar`, la barre de progression d'un minuteur, était en
 * `transition:width 1s linear`. `width` est une propriété de MISE EN PAGE : animée en continu,
 * elle force une passe de layout par image. Mesuré en session vive, un minuteur d'intervalle
 * armé, panneau ouvert, six secondes sans le moindre geste : 118 layouts/s et 123 recalculs de
 * style/s, pour 126,8 ms/s de fil principal à CPU nominal, 206,9 à ×4 et 377,3 à ×6 — jusqu'à
 * 38 % d'un cœur brûlés à ne rien faire, pendant toute la durée d'une réanimation. En
 * `transform:scaleX()` : 2 layouts/s, 13,3 / 14,3 / 27,7 ms/s, pour un rendu identique à une
 * colonne d'anticrénelage près.
 *
 * La règle était déjà respectée PARTOUT ailleurs (19 keyframes sur 19 n'animent que des
 * propriétés composées, et `.t-life` faisait déjà le bon geste depuis longtemps) : c'est
 * exactement le profil d'une règle qu'on connaît, qu'on applique presque toujours, et qu'un seul
 * oubli suffit à trahir sans que rien ne le signale. D'où ce contrôle.
 *
 * CE QUI EST REFUSÉ : une propriété de MISE EN PAGE dans un `transition` ou dans un `@keyframes`.
 * CE QUI EST ADMIS : `transform` et `opacity` (composées), et les propriétés de PEINTURE SEULE
 * (couleurs, ombres, contours) — elles provoquent un repaint, jamais un layout, et le projet s'en
 * sert massivement pour les survols. Ce contrôle ne les regarde pas.
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

/* Propriétés dont l'animation force un recalcul de mise en page. `all` en fait partie : il
   embarque tout, donc les propriétés de layout aussi — un `transition:all` est un chèque en
   blanc, refusé pour la même raison. */
const LAYOUT = new Set(['all',
  'width', 'height', 'min-width', 'min-height', 'max-width', 'max-height',
  'block-size', 'inline-size', 'min-block-size', 'min-inline-size', 'max-block-size', 'max-inline-size',
  'top', 'right', 'bottom', 'left', 'inset', 'inset-block', 'inset-inline',
  'margin', 'margin-top', 'margin-right', 'margin-bottom', 'margin-left', 'margin-block', 'margin-inline',
  'padding', 'padding-top', 'padding-right', 'padding-bottom', 'padding-left', 'padding-block', 'padding-inline',
  'border-width', 'border-top-width', 'border-right-width', 'border-bottom-width', 'border-left-width',
  'font-size', 'font-weight', 'line-height', 'letter-spacing', 'word-spacing', 'text-indent',
  'flex', 'flex-basis', 'flex-grow', 'flex-shrink', 'order', 'vertical-align',
  'gap', 'row-gap', 'column-gap', 'columns', 'column-width', 'column-count', 'grid-template-columns', 'grid-template-rows']);

/* EXEMPTIONS — chacune motivée, jamais « ça passait déjà ».
   `.skiplink` : le lien d'évitement glisse de -60 px à sa place au focus, sur 120 ms, UNE fois
   par focus. Ce n'est pas le phénomène que la règle vise (une animation CONTINUE pendant un
   soin) : le coût est de quelques images, jamais répété. Le convertir en `transform` obligerait
   à recomposer une position qui dépend d'`env(safe-area-inset-top)`, au risque de laisser le
   lien à moitié visible ou hors d'atteinte — une régression d'accessibilité (WCAG 2.4.1, saut
   de blocs) pour un gain nul. Décision : on n'y touche pas, et on le DIT. */
const EXEMPT = [{ sel: '.skiplink', prop: 'top' }];

const sansCommentaires = s => s.replace(/\/\*[\s\S]*?\*\//g, '');

/* Découpe une liste CSS sur les virgules DE PREMIER NIVEAU : `cubic-bezier(.2,0,0,1)` contient
   des virgules qui n'en sont pas. Un `split(',')` naïf produirait des « propriétés » fantômes. */
function partsTopLevel(s) {
  const out = []; let cur = '', prof = 0;
  for (const c of s) {
    if (c === '(') prof++; else if (c === ')') prof--;
    if (c === ',' && prof === 0) { out.push(cur); cur = ''; } else cur += c;
  }
  if (cur.trim()) out.push(cur);
  return out;
}

const html = readFileSync(join(ROOT, 'index.html'), 'utf8');
const styles = [...html.matchAll(/<style>([\s\S]*?)<\/style>/g)].map(m => m[1]);
if (!styles.length) { console.error('check-anim : aucune feuille <style> trouvée dans index.html.'); process.exit(1); }

const fautes = [];
let nTrans = 0, nKf = 0;

for (const brut of styles) {
  const css = sansCommentaires(brut);

  /* 1. Les transitions. On remonte au sélecteur du bloc pour que le message soit actionnable. */
  for (const m of css.matchAll(/transition(?:-property)?\s*:\s*([^;}]+)/g)) {
    nTrans++;
    const avant = css.slice(0, m.index);
    const ouvre = avant.lastIndexOf('{');
    const sel = ouvre < 0 ? '?' : avant.slice(Math.max(avant.lastIndexOf('}', ouvre), avant.lastIndexOf('{', ouvre - 1)) + 1, ouvre).trim().replace(/\s+/g, ' ');
    for (const part of partsTopLevel(m[1])) {
      const p = part.trim().split(/\s+/)[0].replace(/!important$/, '').toLowerCase();
      if (!LAYOUT.has(p)) continue;
      if (EXEMPT.some(e => sel.includes(e.sel) && e.prop === p)) continue;
      fautes.push({ ou: `transition « ${sel} »`, prop: p });
    }
  }

  /* 2. Les keyframes. On lit les propriétés DÉCLARÉES dans chaque bloc d'étapes. */
  for (const m of css.matchAll(/@keyframes\s+([\w-]+)\s*\{/g)) {
    nKf++;
    // Lecture du bloc en comptant les accolades : un @keyframes contient des sous-blocs.
    let i = m.index + m[0].length, prof = 1;
    while (i < css.length && prof > 0) { if (css[i] === '{') prof++; else if (css[i] === '}') prof--; i++; }
    const corps = css.slice(m.index + m[0].length, i - 1);
    for (const d of corps.matchAll(/([-a-z]+)\s*:/g)) {
      const p = d[1].toLowerCase();
      if (LAYOUT.has(p) && !EXEMPT.some(e => e.sel === '@' + m[1] && e.prop === p))
        fautes.push({ ou: `@keyframes ${m[1]}`, prop: p });
    }
  }
}

if (fautes.length) {
  console.error('✗ check-anim : ' + fautes.length + ' animation(s) de propriété de MISE EN PAGE.\n');
  for (const f of fautes) console.error(`    ${f.ou} → ${f.prop}`);
  console.error('\n  Animer une propriété de mise en page force un layout PAR IMAGE pendant toute');
  console.error('  la durée de l\'animation (mesuré sur .tm-bar : 118 layouts/s, jusqu\'à 38 % d\'un');
  console.error('  cœur en pleine réanimation). Passer par `transform` / `opacity`, qui sont');
  console.error('  composées — cf. `.tm-bar` (scaleX) et `.t-life`. Si l\'animation est ponctuelle');
  console.error('  et ne peut pas se convertir sans risque, l\'ajouter à EXEMPT avec sa RAISON.');
  process.exit(1);
}
console.log(`✓ check-anim : ${nTrans} transition(s) et ${nKf} keyframes — aucune animation de propriété de mise en page` +
  (EXEMPT.length ? ` (${EXEMPT.length} exemption documentée : ${EXEMPT.map(e => e.sel + '/' + e.prop).join(', ')}).` : '.'));
