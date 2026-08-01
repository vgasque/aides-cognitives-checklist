/* GARDE-FOU — ÉCHELLE DE RAYONS FERMÉE (v5.0.0, audit design, action 5).
   Le dossier verrouille les couleurs (`check-colors`), le texte (`check-type`) et les paliers
   responsive (`check-paliers`) — mais le rayon avait DIX-NEUF valeurs distinctes pour trois
   tokens : 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 18, 20, 22, 99, 999. Ce n'est pas une
   question de pureté : deux rayons à 1 px d'écart ne se lisent pas comme deux niveaux, ils se
   lisent comme une inattention — l'argument exact qui a fermé l'échelle typographique en v4.71.1.
   Et l'expérience du dossier est constante : partout où une règle est restée DÉCLARATIVE, elle a
   fui (les paliers responsive avaient douze valeurs pour neuf déclarées).
   L'ÉCHELLE A ÉTÉ CHOISIE SUR LA DISTRIBUTION RÉELLE, pas dans l'abstrait : elle garde les trois
   valeurs des tokens existants et n'a demandé qu'un déplacement de ≤ 2 px sur les autres. */
import { readFileSync } from 'node:fs';
const SRC = new URL('../index.html', import.meta.url);
const html = readFileSync(SRC, 'utf8');
const css = html.slice(html.indexOf('<style>'), html.indexOf('</style>'));

const ECHELLE = [3, 6, 8, 11, 14, 18, 999];
/* EXEMPTIONS — nommées par leur sélecteur et MOTIVÉES, comme dans `check-type` : une exemption
   anonyme rouvrirait la porte qu'on vient de fermer. (Aucune à ce jour.) */
const EXEMPT = [];

const lignes = css.split('\n');
const mauvais = [];
lignes.forEach((l, i) => {
  const m = l.match(/border-radius:[^;}]+/g);
  if (!m) return;
  if (EXEMPT.some(x => l.includes(x))) return;
  m.forEach(d => {
    (d.match(/(\d+)px/g) || []).forEach(v => {
      const n = +v.replace('px', '');
      if (!ECHELLE.includes(n)) mauvais.push({ n, ligne: i + 1, txt: l.trim().slice(0, 90) });
    });
  });
});

if (mauvais.length) {
  console.error(`✗ check-radius : ${mauvais.length} rayon(s) hors échelle (${ECHELLE.join(' · ')} px).`);
  mauvais.slice(0, 12).forEach(x => console.error(`   ligne ${x.ligne} — ${x.n}px — ${x.txt}`));
  if (mauvais.length > 12) console.error(`   … +${mauvais.length - 12} autres`);
  console.error('   Ajouter une valeur à l’échelle est une DÉCISION : la porter ici ET dans AGENTS.md.');
  process.exit(1);
}
const total = (css.match(/border-radius:/g) || []).length;
console.log(`✓ check-radius : ${total} rayon(s), tous sur l’échelle fermée (${ECHELLE.join(' · ')} px)`
  + `${EXEMPT.length ? ` — ${EXEMPT.length} exemption(s) documentée(s).` : '.'}`);
