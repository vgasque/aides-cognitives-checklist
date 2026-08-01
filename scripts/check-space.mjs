/* GARDE-FOU — ÉCHELLE D'ESPACEMENT FERMÉE (v5.0.0, audit design, action 4).
   C'était la MOITIÉ OUVERTE du design system : zéro token, et des valeurs prises au cas par cas
   de 1 à 26 px — 55 usages de 2, 26 de 3, 42 de 4, 42 de 5, 112 de 6, 55 de 7, 138 de 8, 65 de 9,
   89 de 10, 30 de 11, 49 de 12, 10 de 13… Deux rembourrages à 1 px d'écart ne sont pas deux
   niveaux, ce sont deux inattentions : c'est l'argument qui a fermé l'échelle typographique en
   v4.71.1, et il vaut ici mot pour mot.
   ET C'EST LA LEÇON CONSTANTE DU DOSSIER : partout où une règle est restée DÉCLARATIVE, elle a
   fui — les paliers responsive avaient douze valeurs pour neuf déclarées, et personne ne pouvait
   le voir. Un garde-fou ne rend pas le système pur, il l'empêche de dériver.
   L'ÉCHELLE A ÉTÉ CHOISIE SUR LA DISTRIBUTION RÉELLE : la migration n'a déplacé aucune valeur de
   plus d'1 px, ce qui la rend vérifiable par les harnais existants (cibles de 44, rangées de 71,
   budgets d'écran) plutôt que par relecture. */
import { readFileSync } from 'node:fs';
const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const css = html.slice(html.indexOf('<style>'), html.indexOf('</style>'));

const ECHELLE = [0, 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 40, 48, 56, 64, 72, 96];
const PROPS = /\b(padding|margin|gap|row-gap|column-gap|padding-top|padding-right|padding-bottom|padding-left|margin-top|margin-right|margin-bottom|margin-left)\s*:\s*([^;}]+)/g;
/* EXEMPTIONS — nommées par leur sélecteur et MOTIVÉES (patron `check-type`). */
const EXEMPT = [
  { rx: /--sab|env\(safe-area/, motif: 'marges matérielles : la valeur vient du système, pas de nous' },
];

const fautes = [];
let controlees = 0, exemptees = 0;
let m;
while ((m = PROPS.exec(css))) {
  const val = m[2];
  if (/var\(|calc\(|env\(/.test(val)) { continue; }   // valeur calculée : hors périmètre
  const st = css.lastIndexOf('{', m.index);
  const cut = Math.max(css.lastIndexOf('}', st), css.lastIndexOf('*/', st), css.lastIndexOf('\n', st));
  const sel = css.slice(cut + 1, st).trim().replace(/\s+/g, ' ');
  const px = val.match(/-?\d+px/g) || [];
  px.forEach(v => {
    controlees++;
    const n = Math.abs(parseInt(v, 10));
    if (ECHELLE.includes(n)) return;
    if (EXEMPT.some(e => e.rx.test(sel) || e.rx.test(val))) { exemptees++; return; }
    fautes.push({ ligne: css.slice(0, m.index).split('\n').length, v, sel: sel.slice(-70) });
  });
}

if (fautes.length) {
  console.log(`\n✗ check-space : ${fautes.length} espacement(s) hors de l’échelle fermée (${ECHELLE.join(' · ')} px) :`);
  fautes.slice(0, 15).forEach(f => console.log(`   index.html:${f.ligne}  ${f.v}  —  ${f.sel}`));
  if (fautes.length > 15) console.log(`   … +${fautes.length - 15} autres`);
  console.log('\n  Choisissez le palier le plus proche, ou ajoutez une exemption NOMMÉE et motivée.');
  console.log('  Une valeur de plus posée en silence est exactement ce que ce contrôle empêche.\n');
  process.exit(1);
}
console.log(`✓ check-space : ${controlees} espacement(s), tous sur l’échelle fermée (${ECHELLE.join(' · ')} px)`
  + `${exemptees ? ` — ${exemptees} exemption(s) documentée(s).` : '.'}`);
