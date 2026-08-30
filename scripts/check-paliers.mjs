/* PALIERS DE LARGEUR — LA FERMETURE DEVIENT AUTO-EXÉCUTOIRE (v5.0.0, lot T0).
 *
 * POURQUOI. `AGENTS.md` déclare une échelle responsive « FERMÉE » et ajoute « pas de nouveau palier
 * sans décision explicite ». C'était une règle DÉCLARATIVE, et elle avait fui : l'audit structurel a
 * mesuré DOUZE paliers réels pour NEUF déclarés — deux non déclarés (479,98 et 924) et un déclaré
 * qui n'existe nulle part (900). Une échelle fermée qui a fui est une échelle ouverte qu'on croit
 * fermée, et personne ne pouvait le voir : rien ne la mesurait.
 *
 * Même famille que `check-colors` (aucune couleur hors token) et `check-type` (échelle
 * typographique fermée) : la règle cesse d'être une intention et devient un contrôle.
 *
 * CE QUI EST MESURÉ : les valeurs `min-width` / `max-width` apparaissant dans une CONDITION de
 * `@media`. Pas les `min-width:44px` des cibles tactiles, ni les `max-width` de plafonnement de
 * colonne — ce ne sont pas des paliers, ce sont des dimensions.
 *
 * LES DEMI-PIXELS. Le dépôt écrit ses bornes hautes en `.98` (`779.98px`) pour ne pas chevaucher la
 * borne basse suivante. `779.98` et `780` sont donc UN palier, pas deux : on arrondit au supérieur
 * avant de comparer, sinon le contrôle réclamerait de déclarer les deux moitiés de chaque seuil.
 *
 * VÉRIFIÉ CAPABLE D'ÉCHOUER (leçon v4.31.1) : palier fantôme ajouté puis retiré, rouge constaté
 * dans les deux sens (non déclaré ET déclaré-absent).
 */
import { readFileSync } from 'node:fs';

/* L'ÉCHELLE. Toute addition ici est une DÉCISION, et c'est tout l'objet du fichier : la liste ne
   s'édite pas pour faire passer le contrôle, elle s'édite pour acter un palier de plus. */
// 390 : palier v5.18 (maquette « Zero », 390 px) — sous lui, l'en-tête d'accueil rend son mot
// « Créer » et la marque redescend à 21 px (la ligne n'a pas la place des deux).
const PALIERS = [360, 390, 400, 430, 480, 560, 640, 780, 924, 1000, 1200];

/* Exemptions NOMMÉES et MOTIVÉES — comme dans check-type. Une exemption anonyme rouvrirait la porte
   qu'on vient de fermer. (Aucune à ce jour : les douze paliers mesurés se rangent tous dans
   l'échelle ci-dessus, une fois 479,98 et 924 déclarés et 900 retiré.) */
const EXEMPTIONS = [];

const src = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const css = src.slice(src.indexOf('<style>'), src.lastIndexOf('</style>'))
               .replace(/\/\*[\s\S]*?\*\//g, '');

/* Une condition de @media court jusqu'à l'accolade ouvrante. On ne lit QUE là. */
const trouves = new Map();          // palier arrondi -> Set des écritures réelles
for (const m of css.matchAll(/@media([^{]*)\{/g)) {
  for (const w of m[1].matchAll(/(?:min|max)-width\s*:\s*([\d.]+)px/g)) {
    const brut = parseFloat(w[1]);
    const p = Math.ceil(brut);      // 779.98 et 780 sont UN palier
    if (!trouves.has(p)) trouves.set(p, new Set());
    trouves.get(p).add(w[1] + 'px');
  }
}

const decl = new Set(PALIERS);
const exempt = new Set(EXEMPTIONS);
const nonDeclares = [...trouves.keys()].filter(p => !decl.has(p) && !exempt.has(p)).sort((a, b) => a - b);
const declaresAbsents = PALIERS.filter(p => !trouves.has(p));

console.log('Paliers de largeur :');
console.log(`  déclarés : ${PALIERS.length} — ${PALIERS.join(' · ')}`);
console.log(`  mesurés  : ${trouves.size} — ${[...trouves.keys()].sort((a, b) => a - b).join(' · ')}`);

let ko = 0;
if (nonDeclares.length) {
  ko = 1;
  console.error('\n✗ Palier(s) NON DÉCLARÉ(S) dans l’échelle :');
  for (const p of nonDeclares) console.error(`    ${p}px  (écrit : ${[...trouves.get(p)].join(', ')})`);
  console.error('  Un palier de plus est une DÉCISION : ajoutez-le à PALIERS ici ET à AGENTS.md,');
  console.error('  ou retirez la media query.');
}
if (declaresAbsents.length) {
  ko = 1;
  console.error('\n✗ Palier(s) DÉCLARÉ(S) mais absent(s) du CSS :');
  for (const p of declaresAbsents) console.error(`    ${p}px`);
  console.error('  Une échelle qui annonce un palier inexistant est une échelle fausse.');
}
if (ko) process.exit(1);
console.log('\nÉchelle des paliers : fermée et exacte.');
