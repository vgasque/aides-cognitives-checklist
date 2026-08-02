#!/usr/bin/env node
/*
 * GARDE-FOU « UNE CLASSE ÉMISE A UNE RÈGLE » (v4.32.0) — attrape la PURGE ASYMÉTRIQUE.
 *
 * Pourquoi : la suppression du Plan « Détails » (v4.25.0) a retiré ~20 règles CSS mortes… et,
 * dans le même geste, les cinq règles de `.pl-stp`, une classe TOUJOURS ÉMISE. Résultat, pendant
 * six versions, une étape ⚠ (memory item) s'affichait en encre ordinaire dans le détail de « Se
 * repérer », indiscernable d'une étape banale — alors que son pendant statique restait, lui,
 * correctement peint. Le défaut était invisible : aucun test ne cassait, rien ne le signalait.
 *
 * Le contrôle SYMÉTRIQUE (« une règle CSS a un porteur ») n'est PAS automatisable de façon fiable
 * ici : trop de classes sont posées par concaténation (`pd`+n, `c`+n, `w`+scale) ou par classList.
 * Celui-ci l'est, parce qu'il part des classes LITTÉRALES écrites dans les attributs `class="…"`
 * des gabarits, et ne regarde que les familles préfixées des composants de crise — celles dont
 * la perte d'un registre a des conséquences cliniques.
 *
 *   node scripts/check-classes.mjs
 */
import { readFile } from 'node:fs/promises';

const ROOT = decodeURIComponent(new URL('../', import.meta.url).pathname);
const html = await readFile(ROOT + 'index.html', 'utf8');

const m = html.match(/<style>([\s\S]*?)<\/style>/);
if (!m) { console.error('check-classes : <style> introuvable'); process.exit(1); }
const css = m[1];
const cssStart = html.indexOf(css);
// Le corps HORS feuille de style (coque HTML + gabarits JS), commentaires retirés : un nom de
// classe cité dans un commentaire n'est pas une émission.
const body = (html.slice(0, cssStart) + html.slice(cssStart + css.length))
  .replace(/\/\*[\s\S]*?\*\//g, '')
  .replace(/<!--[\s\S]*?-->/g, '')
  .replace(/^\s*\/\/.*$/gm, '');

// Familles surveillées : composants du mode crise et de ses synoptiques, où perdre un registre
// (⚠ rouge, △ ambre, ✓ vert) change la lecture d'un contenu vital.
const FAMILIES = /^(pl|sv|ov|rm|cb|cx|rt|tk|care|flow|seg|stp)-/;
// Exemptions explicites, avec leur raison — jamais de liste muette. Toutes sont des CROCHETS :
// des classes qui existent pour être sélectionnées en JS, pas pour peindre.
const EXEMPT = new Map([
  ['flow-scroll', 'conteneur de défilement du SVG : géométrie posée en style inline'],
  ['ov-wrap', 'crochet de DÉLÉGATION du journal (cf. bindOverviewEvents) — aucun style propre'],
  ['ov-journal', 'crochet de sélection JS (`.ov-journal .flow-end`) — aucun style propre'],
  ['seg-ic', 'conteneur d\'icône rempli par uiIcon() : le SVG porte ses propres dimensions'],
]);

// Classes littérales des attributs class="…" (gabarits et coque). On ignore tout fragment
// contenant une interpolation ou une concaténation : `class="ov-block${…}"` ou
// `class="rm-seg'+(x.due?'…` donneraient de faux noms.
const emitted = new Map();   // nom -> nombre d'émissions
for (const mm of body.matchAll(/class="([^"]*)"/g)) {
  const frag = mm[1];
  if (/[$`'+{}]/.test(frag)) {
    // Fragment interpolé : on ne garde que les noms situés AVANT la première interpolation,
    // qui sont écrits littéralement et donc sûrs.
    const head = frag.split(/[$`'+{}]/)[0];
    for (const c of head.trim().split(/\s+/)) {
      if (c && FAMILIES.test(c)) emitted.set(c, (emitted.get(c) || 0) + 1);
    }
    continue;
  }
  for (const c of frag.trim().split(/\s+/)) {
    if (!c || !FAMILIES.test(c)) continue;
    emitted.set(c, (emitted.get(c) || 0) + 1);
  }
}

// Une classe est « stylée » si son nom apparaît comme sélecteur de classe dans la feuille.
// LES COMMENTAIRES SONT RETIRÉS D'ABORD : sans cela, un commentaire qui CITE `.pl-stp` — par
// exemple pour expliquer sa restauration — suffirait à faire croire que la classe est stylée.
// Premier jet de ce script : le faux négatif exact qu'il est censé prévenir.
const cssCode = css.replace(/\/\*[\s\S]*?\*\//g, '');
const styled = new Set();
for (const mm of cssCode.matchAll(/\.([A-Za-z][\w-]*)/g)) styled.add(mm[1]);

/* ═══ LA PASSE INVERSE : « UNE RÈGLE CSS A UN PORTEUR » (v5.0.0, audit) ══════════════════════
   L'EN-TÊTE DE CE FICHIER LA DÉCLARAIT « PAS AUTOMATISABLE DE FAÇON FIABLE », et c'était vrai du
   raisonnement, pas du terrain : la mesure dit qu'exactement TREIZE classes sont posées par
   concaténation, et qu'elles tiennent en trois familles qu'on peut nommer. Tout le reste s'écrit
   littéralement quelque part — attribut, `classList`, chaîne de sélecteur — et se cherche donc.

   CE QUE SON ABSENCE A COÛTÉ : dix classes mortes vivaient dans la feuille, dont `.pl-cxh`, que
   `AGENTS.md` déclare PURGÉE en toutes lettres (« un seul demeure »). Autrement dit la doctrine
   affirmait un nettoyage qui n'avait pas eu lieu — exactement le défaut que la règle 14 nomme
   (« une purge à moitié faite est pire qu'aucune purge ») et que la moitié FORWARD de ce script
   avait été écrite pour attraper, dans l'autre sens seulement.

   PORTÉE : toutes les classes de la feuille, pas seulement les familles de crise. La moitié
   forward se restreint aux familles parce qu'y perdre un registre a des conséquences cliniques ;
   ici le risque est inverse et uniforme — du CSS mort qu'on relit, qu'on croit vivant, et sur
   lequel on raisonne. Les dix trouvées étaient à 70 % HORS des familles surveillées. */
const CONCAT = new Map([
  [/^a-/,   'accent utilisateur : classe posée par `\'a-\'+accent` (applyAccent)'],
  [/^ts-/,  'taille du texte : classe posée par `\'ts-\'+z` (applyZoom)'],
  [/^zw/,   'palier de largeur sous zoom : classe posée par `\'zw\'+w` (syncZoomWidth)'],
  [/^c\d$/, 'nombre de branches en colonne : classe posée par `\'c\'+n` (plan et statique)'],
  [/^d\d$/, 'profondeur d\'imbrication : classe posée par `\'d\'+depth` (retraits du plan)'],
]);
const usedSomewhere = new Set();
for (const mm of body.matchAll(/[A-Za-z][\w-]*/g)) usedSomewhere.add(mm[0]);
const deadCss = [...styled]
  .filter(c => !usedSomewhere.has(c) && ![...CONCAT.keys()].some(rx => rx.test(c)))
  .sort();

const orphans = [...emitted.keys()].filter(c => !styled.has(c) && !EXEMPT.has(c)).sort();

if (deadCss.length) {
  console.error(`✗ ${deadCss.length} règle(s) CSS dont la classe n'est émise NULLE PART :`);
  for (const c of deadCss) console.error(`    .${c}`);
  console.error('  -> le composant a disparu sans son CSS (règle 14) : supprimer la ou les règles,');
  console.error('     leurs commentaires, et la doc qui les cite.');
  console.error('     Si la classe est posée par CONCATÉNATION, ajouter sa famille à CONCAT avec sa raison.');
  process.exit(1);
}

if (orphans.length) {
  console.error(`✗ ${orphans.length} classe(s) ÉMISE(S) sans aucune règle CSS :`);
  for (const c of orphans) console.error(`    .${c}   (${emitted.get(c)} émission(s) dans les gabarits)`);
  console.error('  -> soit la règle a été supprimée par erreur (cf. .pl-stp, purge v4.25.0),');
  console.error('     soit la classe ne sert plus et doit disparaître du gabarit.');
  console.error('     Si elle est volontairement sans style, l\'ajouter à EXEMPT avec sa raison.');
  process.exit(1);
}
console.log(`✓ check-classes : ${emitted.size} classe(s) émise(s) surveillée(s), toutes stylées ;`
  + ` ${styled.size} classe(s) stylée(s), toutes émises (${CONCAT.size} familles concaténées exemptées).`);
