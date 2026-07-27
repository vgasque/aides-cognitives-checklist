#!/usr/bin/env node
/* SQL — garde-fou de syntaxe minimal (v4.44.1).
 *
 * POURQUOI CE FICHIER EXISTE. `supabase/schema.sql` et `supabase/rls-tests.sql` n'étaient
 * couverts par RIEN : ils ne sont ni servis, ni chargés par les tests, et l'erreur ne se voit
 * qu'au moment où on les colle dans l'éditeur SQL de Supabase — c'est-à-dire chez l'utilisateur,
 * sur une instance de production. C'est exactement ce qui vient d'arriver : une édition
 * automatisée a transformé `as $$` en `as $` sur DEUX fonctions trigger, et rien ne l'a vu.
 *
 * LA CAUSE MÉRITE D'ÊTRE ÉCRITE, parce qu'elle se reproduira : `String.prototype.replace()`
 * interprète `$$` DANS LA CHAÎNE DE REMPLACEMENT comme un dollar littéral unique (au même titre
 * que `$&`, `` $` ``, `$'` et `$1`). Un script de patch qui réinjecte du SQL contenant `$$` le
 * mutile donc en silence. Le remède, côté script : passer une FONCTION de remplacement (elle ne
 * subit aucune substitution), ou `split().join()`.
 *
 * ET LE CONTRÔLE QUI AVAIT ÉTÉ FAIT NE POUVAIT PAS L'ATTRAPER : il comptait les occurrences de
 * `$$` et vérifiait la parité. Or un `$$` amputé en `$` ne matche plus le motif — il disparaît du
 * compte des deux côtés, et la parité reste vraie. Un contrôle qui ne peut pas voir le défaut
 * qu'il est censé couvrir vaut zéro (leçon v4.31.1). D'où le contrôle par RUNS de dollars.
 */
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const FICHIERS = ['supabase/schema.sql', 'supabase/rls-tests.sql'];
const fautes = [];
let nFonctions = 0, nDelims = 0;

for (const rel of FICHIERS) {
  const p = join(ROOT, rel);
  if (!existsSync(p)) { fautes.push(`${rel} : introuvable`); continue; }
  const sql = readFileSync(p, 'utf8');
  const lignes = sql.split('\n');

  /* 1. RUNS DE DOLLARS. Un délimiteur de corps est `$$` ou `$nom$`. Un dollar ISOLÉ, entouré de
        non-dollars, n'a aucune raison d'exister hors d'une chaîne — et c'est la signature exacte
        du `$$` mutilé. On ignore les commentaires de ligne. */
  lignes.forEach((l, i) => {
    const code = l.replace(/--.*$/, '');
    for (const m of code.matchAll(/\$+/g)) {
      const av = code[m.index - 1], ap = code[m.index + m[0].length];
      // `$nom$` : un dollar suivi d'un identifiant puis d'un dollar — forme légitime.
      if (m[0].length === 1 && /[A-Za-z_]/.test(ap || '')) continue;
      if (m[0].length === 1 && /[A-Za-z_]/.test(av || '')) continue;
      if (m[0].length !== 2)
        fautes.push(`${rel}:${i + 1} — suite de ${m[0].length} dollar(s) « ${m[0]} » : un délimiteur de corps s'écrit « $$ »\n        ${l.trim().slice(-72)}`);
    }
  });

  /* 2. APPARIEMENT. Chaque `$$` ouvre ou ferme un corps : leur nombre doit être PAIR, et chaque
        `create … function` doit être suivi d'exactement une paire avant le `;` terminal. */
  const delims = (sql.match(/\$\$/g) || []).length;
  nDelims += delims;
  if (delims % 2) fautes.push(`${rel} : ${delims} délimiteurs « $$ » — nombre IMPAIR, un corps n'est pas refermé`);

  const fns = [...sql.matchAll(/create\s+(?:or\s+replace\s+)?function\s+([a-z0-9_.]+)/gi)];
  nFonctions += fns.length;
  for (const f of fns) {
    // Du nom de la fonction jusqu'au prochain `$$`, il ne doit y avoir NI `;` NI autre `create`.
    const apres = sql.slice(f.index + f[0].length);
    const iDelim = apres.indexOf('$$');
    if (iDelim < 0) { fautes.push(`${rel} : « ${f[1]} » n'a pas de corps délimité par « $$ »`); continue; }
    const entete = apres.slice(0, iDelim);
    if (/;/.test(entete.replace(/--.*$/gm, '')))
      fautes.push(`${rel} : l'en-tête de « ${f[1]} » contient un « ; » avant son corps — délimiteur probablement mutilé`);
  }
}

if (fautes.length) {
  console.error('✗ check-sql : ' + fautes.length + ' problème(s).\n');
  for (const f of fautes) console.error('    ' + f);
  console.error('\n  Rappel : dans un script de patch, `String.replace()` transforme « $$ » du');
  console.error('  REMPLACEMENT en un seul « $ ». Utiliser une fonction de remplacement, ou split/join.');
  process.exit(1);
}
console.log(`✓ check-sql : ${nFonctions} fonction(s), ${nDelims} délimiteur(s) « $$ » appariés, aucun dollar isolé.`);
