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

/* ⚠ LE QUOTA DU PLANCHER (v5.0.0, audit design A5-1) — LE PREMIER CONTRÔLE DE CE DÉPÔT QUI
   MESURE UNE PROPORTION, PAS UNE PROPRIÉTÉ.
   Les six garde-fous d'échelle répondent tous à la même question : « cette valeur est-elle
   ADMISE ? ». Aucun ne répond à « est-elle TROP UTILISÉE ? » — et c'est exactement par là que le
   plancher typographique a glissé. Mesuré à l'audit : 173 déclarations à 11 px sur ~520, soit LA
   TAILLE LA PLUS UTILISÉE DE TOUTE LA FEUILLE, devant 13,5 px (138) et 12 px (107) ; 81 % des
   corps étaient à 13,5 px ou moins. Chaque déclaration prise isolément était parfaitement légale,
   donc rien ne pouvait le voir. Or un plancher est une EXCEPTION MOTIVÉE : employé 173 fois, ce
   n'est plus un plancher, c'est le corps de texte du produit — et la règle qui le nomme
   « plancher » masque ce fait au lieu de le révéler.
   C'EST UN CLIQUET, PAS UN SEUIL D'OPINION : le plafond est posé au niveau ATTEINT après le lot,
   de sorte que la valeur ne peut que descendre. Le baisser est un geste explicite, l'augmenter est
   un échec bruyant. Même dispositif qu'`audit-budget` pour la répartition d'écran (v5.0.0, lot T4).
   ⚠ CE QU'IL NE MESURE PAS, et il faut le savoir : une DÉCLARATION n'est pas un ÉLÉMENT À
   L'ÉCRAN. Le vrai constat de l'audit était « 14 des 26 éléments visibles à l'accueil sont à
   11 px », ce qu'un contrôle statique ne peut pas voir. Ce cliquet est un proxy — il empêche la
   dérive de s'aggraver, il ne prouve pas qu'elle a cessé. La mesure d'écran, elle, vit dans
   `audit-doctrine`.
   BAISSER LE PLAFOND est la façon normale de faire descendre la dette : traiter un gisement de
   11 px (une méta, une rangée), constater le nouveau compte, et reposer PLANCHER_MAX dessus. */
const PLANCHER = 11;
const PLANCHER_MAX = 169;
const auPlancher = (css.match(/font-size:\s*11px/g) || []).length;

if (!fautes.length && auPlancher > PLANCHER_MAX) {
  console.log(`\n✗ check-type : ${auPlancher} déclarations à ${PLANCHER}px — le plafond est ${PLANCHER_MAX}.`);
  console.log('  Le plancher typographique est une EXCEPTION MOTIVÉE, pas un corps de texte.');
  console.log('  Choisissez un palier au-dessus (12 px), ou — si ce nouvel usage est vraiment une');
  console.log('  étiquette de zone — rendez sa place en remontant un autre gisement, puis baissez');
  console.log('  PLANCHER_MAX dans scripts/check-type.mjs. Le cliquet ne remonte pas.\n');
  process.exit(1);
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
  + `${exemptees} exemption(s) documentée(s) ; `
  + `plancher ${PLANCHER}px : ${auPlancher}/${PLANCHER_MAX} déclarations.`);
