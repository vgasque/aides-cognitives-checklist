#!/usr/bin/env node
/* ÉCHELLE TYPOGRAPHIQUE FERMÉE (v4.71.1, audit design E2) — garde-fou auto-exécutoire.
 *
 * POURQUOI. Avant ce contrôle, la feuille portait SEIZE corps différents entre 10 et 19 px :
 * 11 / 11,5 / 12 / 12,5 / 13 / 13,5 / 14 / 14,5 / 15 / 15,5 / 16 / 16,5 / 17 / 18 / 19 (+ un 10).
 * Le problème n'est pas la pureté : deux textes à 13 et 13,5 px ne se lisent pas comme deux
 * NIVEAUX, ils se lisent comme une inattention. Une échelle fermée rend la hiérarchie lisible —
 * un écart de corps y signifie toujours quelque chose — et, comme les couleurs depuis la v4.31.0,
 * elle cesse d'être une intention pour devenir une propriété vérifiée.
 *
 * CE QUI EST CONTRÔLÉ : deux bandes, chacune avec SON échelle.
 *   · le TEXTE, sous 20 px — sept paliers ;
 *   · les AFFICHAGES, à partir de 20 px — cinq paliers (v5.0.0, audit design, action 8).
 * L'exemption d'origine (« ils ne se croisent jamais du regard ») était juste pour 34 et 40 px —
 * chronos, moniteur, tête de bilan, qui occupent chacun leur surface. Elle était FAUSSE pour
 * 20/21/22/23/24, qui sont des titres et se croisent en permanence : cinq valeurs à moins de 5 %
 * d'écart ne se lisent pas comme cinq niveaux. La bande d'affichage a donc sa propre échelle,
 * plus lâche que celle du texte parce que ses objets sont plus rares et plus gros.
 *
 * DEUX VALEURS DE SERVICE, qui ne sont pas des paliers :
 *   · 16 px — plancher des champs de saisie sur écran tactile (règle 9 : sous 16, Safari iOS
 *     zoome la page au focus et les taps voisins se perdent). C'est une contrainte du moteur,
 *     pas un niveau de hiérarchie.
 *   · 14 px — l'un des quatre « A » du sélecteur de taille du texte. Ces quatre corps SONT
 *     l'échantillon de l'échelle que l'utilisateur règle : leur écart est l'information.
 */
import { readFile } from 'node:fs/promises';

const ROOT = decodeURIComponent(new URL('../', import.meta.url).pathname);

/* Les sept paliers. Toute autre valeur sous 20 px doit être justifiée ci-dessous, jamais
   ajoutée en silence : c'est la discussion qu'on veut forcer, pas la conformité. */
const PALIERS = [19, 18, 16.5, 15.5, 13.5, 12, 11];
/* Les cinq paliers d'AFFICHAGE (≥ 20 px). Même règle : toute autre valeur se discute ici. */
const AFFICHAGES = [20, 24, 26, 34, 40];
/* Exemptions NOMMÉES par leur sélecteur, avec leur motif. Une exemption anonyme ne vaut rien —
   elle rouvre la porte qu'on vient de fermer. */
const EXEMPTIONS = [
  { rx: /#zoomSeg\s+\.ts-(90|100|115|130)\b/, val: null,
    motif: 'les quatre « A » sont l’échantillon de l’échelle réglée par l’utilisateur' },
  { rx: /input|textarea|select|\.auth-field|\.tg-row|\.join-sel|coarse/i, val: 16,
    motif: 'plancher de 16 px des champs sur écran tactile (règle 9)' },
];

const src = await readFile(ROOT + 'index.html', 'utf8');
const css = src.slice(src.indexOf('<style>'), src.indexOf('</style>'));

const fautes = [];
let exemptees = 0, controlees = 0;
const rx = /font-size:\s*([0-9.]+)px/g;
let m;
while ((m = rx.exec(css))) {
  const val = parseFloat(m.group ? m.group(1) : m[1]);
  const bande = val >= 20 ? AFFICHAGES : PALIERS;
  controlees++;
  if (bande.includes(val)) continue;

  // Sélecteur : on remonte à l'accolade ouvrante puis au séparateur précédent.
  const st = css.lastIndexOf('{', m.index);
  const cut = Math.max(css.lastIndexOf('}', st), css.lastIndexOf('*/', st), css.lastIndexOf('\n', st));
  const sel = css.slice(cut + 1, st).trim().replace(/\s+/g, ' ');

  const ex = EXEMPTIONS.find(e => e.rx.test(sel) && (e.val === null || e.val === val));
  if (ex) { exemptees++; continue; }

  const ligne = css.slice(0, m.index).split('\n').length;
  fautes.push({ ligne, val, sel: sel.slice(-70) });
}

if (fautes.length) {
  console.log('\n✗ check-type : corps hors des échelles fermées (texte '
    + PALIERS.join(' · ') + ' px · affichage ' + AFFICHAGES.join(' · ') + ' px) :');
  for (const f of fautes) console.log(`   index.html:${f.ligne}  ${f.val}px  —  ${f.sel}`);
  console.log('\n  Choisissez le palier le plus proche, ou ajoutez une exemption NOMMÉE et motivée');
  console.log('  dans scripts/check-type.mjs. Une valeur de plus posée en silence est exactement');
  console.log('  ce que ce contrôle existe pour empêcher.\n');
  process.exit(1);
}
console.log(`✓ check-type : ${controlees} corps, tous sur les échelles fermées `
  + `(texte ${PALIERS.join(' · ')} · affichage ${AFFICHAGES.join(' · ')} px) — `
  + `${exemptees} exemption(s) documentée(s).`);
