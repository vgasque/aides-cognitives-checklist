/* GARDE-FOU — AUCUN NOM D'ICÔNE FANTÔME (v5.0.0).

   POURQUOI. `uiIcon(nom)` retombe sur `${P[name]||''}` : un nom absent de la table ne lève RIEN,
   il rend un <svg> de la bonne taille et SANS AUCUN TRACÉ. Le résultat est un blanc parfaitement
   dimensionné à côté du libellé — invisible à la relecture, invisible à `check-classes` (la classe
   `.tic` est bien émise), invisible aux harnais (l'élément existe et se mesure). C'est ainsi que
   `user` a vécu dans la pastille de provenance : « 🕮 Partagée » portait son dessin, « Perso »
   portait 11 px de vide, et personne ne pouvait le voir autrement qu'à l'œil, sur l'écran de
   recherche d'un compte possédant au moins une bibliothèque partagée.

   ET C'EST LA LEÇON CONSTANTE DU DOSSIER : partout où une règle est restée DÉCLARATIVE, elle a
   fui — les paliers responsive avaient douze valeurs pour neuf déclarées, l'échelle d'espacement
   n'avait aucun garde-fou. Un contrôle ne rend pas le système pur, il l'empêche de dériver.

   DEUX SENS, comme `check-harnais` :
   (1) tout nom PASSÉ à `uiIcon`/`headerIcon` existe dans sa table — c'est le défaut vécu ;
   (2) toute entrée de table a un tracé NON VIDE — une clé qui vaudrait '' serait le même blanc,
       en pire, puisqu'elle aurait l'air d'exister.

   PORTÉE, ET CE QU'IL NE VOIT PAS. Seuls les noms écrits en TOUTES LETTRES sont vérifiables ;
   dix appels passent une variable (`uiIcon(l.ic)`, `uiIcon(x.ic)`…) et sortent par construction du
   champ d'un contrôle statique. Ce n'est pas une faiblesse à corriger par de l'astuce : les
   valeurs de ces variables sont, elles, des littéraux de tables voisines (`EMPTY_INTRO`, les
   entrées de menu), et un nom fautif y produirait le même blanc. Le contrôle couvre le chemin par
   lequel le défaut est arrivé, il ne prétend pas couvrir l'autre — le dire vaut mieux que de
   laisser croire à une couverture totale. */
import { readFileSync } from 'node:fs';
const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8');

/* La table d'une fabrique d'icônes : de `const P={` qui suit sa déclaration jusqu'au `};` qui la
   ferme. On lit les CLÉS et leur valeur brute — une valeur vide est un défaut à part entière. */
function table(fn) {
  const i = html.indexOf(`function ${fn}(`);
  if (i < 0) return null;
  const a = html.indexOf('const P={', i);
  const b = html.indexOf('};', a);
  if (a < 0 || b < 0) return null;
  const corps = html.slice(a + 'const P={'.length, b);
  const cles = new Map();
  // `nom:` en début d'entrée, suivi soit d'un littéral, soit d'une CONSTANTE partagée.
  for (const m of corps.matchAll(/(?:^|,)\s*(?:\/\*[^]*?\*\/\s*|\/\/[^\n]*\n\s*)*'?([a-zA-Z0-9_-]+)'?\s*:\s*('(?:[^'\\]|\\.)*'|[A-Z_][A-Z0-9_]*)/g))
    cles.set(m[1], m[2]);
  return cles;
}

/* Le PREMIER argument d'un appel, quel qu'il soit (ternaire compris) : on avance en comptant les
   parenthèses jusqu'à la virgule de premier niveau, puis on en extrait les littéraux. Prendre
   naïvement toutes les chaînes de l'appel ferait entrer la taille et les options dans le compte. */
function nomsPasses(fn) {
  const out = [];
  const rx = new RegExp(`\\b${fn}\\(`, 'g');
  let m;
  while ((m = rx.exec(html))) {
    let i = m.index + m[0].length, p = 0, arg = '';
    for (; i < html.length; i++) {
      const c = html[i];
      if (c === '(') p++;
      else if (c === ')') { if (!p) break; p--; }
      else if (c === ',' && !p) break;
      arg += c;
    }
    /* ⚠ NE GARDER QUE LES LITTÉRAUX EN POSITION DE VALEUR. Le premier argument est souvent un
       ternaire dont la CONDITION compare à une chaîne — `relKindOf(id)==='p'?'book':'doc'` : le
       `'p'` n'est pas un nom d'icône, et le prendre pour tel produisait quatre faux positifs.
       On retire donc les opérandes de comparaison avant d'extraire. */
    const val = arg.replace(/[=!]==?\s*'(?:[^'\\]|\\.)*'/g, '');
    for (const s of val.matchAll(/'([a-zA-Z0-9_-]+)'/g)) out.push({ nom: s[1], ligne: html.slice(0, m.index).split('\n').length });
  }
  return out;
}

const fautes = [];
let verifies = 0, dynamiques = 0;
for (const fn of ['uiIcon', 'headerIcon']) {
  const t = table(fn);
  if (!t) { fautes.push({ ligne: 0, msg: `table de ${fn}() introuvable — le contrôle ne mesure plus rien` }); continue; }
  for (const [k, v] of t)
    if (v === "''" || v === '""') fautes.push({ ligne: 0, msg: `${fn}() : l'entrée « ${k} » a un tracé VIDE` });
  const passes = nomsPasses(fn);
  const appels = (html.match(new RegExp(`\\b${fn}\\(`, 'g')) || []).length;
  dynamiques += appels - new Set(passes.map(p => p.ligne)).size;
  for (const { nom, ligne } of passes) {
    verifies++;
    if (!t.has(nom)) fautes.push({ ligne, msg: `${fn}('${nom}') — ce nom n'est PAS dans la table : rendu = un <svg> vide, silencieusement` });
  }
}

if (fautes.length) {
  console.log(`\n✗ check-icons : ${fautes.length} nom(s) d'icône fantôme ou vide :`);
  fautes.forEach(f => console.log(`   ${f.ligne ? 'index.html:' + f.ligne + '  ' : ''}${f.msg}`));
  console.log('\n  Ajoutez le tracé à la table, ou corrigez le nom au point d’appel.');
  console.log('  Un nom absent ne lève aucune erreur : il rend un blanc à la bonne taille.\n');
  process.exit(1);
}
console.log(`✓ check-icons : ${verifies} nom(s) d’icône littéral(aux) vérifié(s), tous présents et tracés`
  + ` (appels à nom calculé : hors portée d’un contrôle statique).`);
