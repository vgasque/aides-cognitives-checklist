// Vérification de syntaxe SANS dépendance : extrait chaque <script> inline de index.html/tests.html
// et le contenu de sw.js, puis tente de les compiler (vm.Script) — sans exécuter. Attrape exactement
// la classe de bug qui casse une app monofichier (parenthèse/backtick mal fermé dans un template).
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

let failed = 0;
function checkCode(label, code) {
  try { new vm.Script(code, { filename: label }); console.log('  ✓', label); }
  catch (e) { failed++; console.error('  ✗', label, '→', e.message); }
}
function checkInlineScripts(file) {
  const html = readFileSync(new URL('../' + file, import.meta.url), 'utf8');
  const re = /<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g;
  let m, i = 0;
  while ((m = re.exec(html))) checkCode(`${file} <script #${i++}>`, m[1]);
  if (i === 0) console.warn('  (aucun script inline trouvé dans ' + file + ')');
}

/* ═══ ET LA FEUILLE DE STYLE (v4.74.2) — LE TROU QUI A LAISSÉ PASSER UN BLOC ENTIER ═══════════
   Ce contrôle ne regardait que du JavaScript. Or dans une app monofichier, une erreur de PARSE
   CSS est aussi grave et beaucoup plus silencieuse : un fermeur de commentaire en trop laisse du texte à nu dans la
   feuille, et le parseur, pour se resynchroniser, AVALE la règle suivante. C'est arrivé sur un
   commentaire coupé en deux au-dessus de `@media (max-width:429.98px)` — tout le palier étroit de
   l'en-tête d'éditeur a disparu, `npm run check` est resté vert de bout en bout, et seule une
   mesure dans le navigateur l'a montré.
   Deux invariants, tous deux locaux et sûrs : les commentaires ne s'imbriquent pas et se ferment
   tous, et les accolades s'équilibrent. On ne réécrit PAS un parseur CSS — on attrape la classe
   d'erreur qui fait disparaître des règles sans rien dire. Les chaînes sont retirées d'abord :
   une accolade ou un `/*` dans un `content:"…"` ou une `url()` ne compte pas. */
function checkCss(file) {
  const html = readFileSync(new URL('../' + file, import.meta.url), 'utf8');
  const re = /<style[^>]*>([\s\S]*?)<\/style>/g;
  let m, i = 0;
  while ((m = re.exec(html))) {
    const label = `${file} <style #${i++}>`;
    // Les chaînes d'abord (elles peuvent contenir /*, */ ou des accolades), puis les commentaires.
    const sansChaines = m[1].replace(/"(?:[^"\\\n]|\\.)*"|'(?:[^'\\\n]|\\.)*'/g, '""');
    const ligne = idx => sansChaines.slice(0, idx).split('\n').length;
    let ouv = -1, prob = null;
    for (let k = 0; k < sansChaines.length - 1 && !prob; k++) {
      const deux = sansChaines.slice(k, k + 2);
      if (deux === '/*') {
        if (ouv >= 0) prob = `commentaire imbriqué ligne ${ligne(k)} (ouvert ligne ${ligne(ouv)})`;
        else { ouv = k; k++; }
      } else if (deux === '*/') {
        if (ouv < 0) prob = `fermeur de commentaire sans ouvreur, ligne ${ligne(k)} — le texte qui précède reste à nu dans la feuille, et le parseur avalera la règle suivante`;
        else { ouv = -1; k++; }
      }
    }
    if (!prob && ouv >= 0) prob = `commentaire jamais fermé, ouvert ligne ${ligne(ouv)}`;
    if (!prob) {
      const nu = sansChaines.replace(/\/\*[\s\S]*?\*\//g, '');
      const o = (nu.match(/\{/g) || []).length, f = (nu.match(/\}/g) || []).length;
      if (o !== f) prob = `accolades déséquilibrées : ${o} « { » pour ${f} « } »`;
    }
    if (prob) { failed++; console.error('  ✗', label, '→', prob); }
    else console.log('  ✓', label);
  }
}

console.log('Vérification de syntaxe :');
checkInlineScripts('index.html');
checkCss('index.html');
checkInlineScripts('tests.html');
checkCode('sw.js', readFileSync(new URL('../sw.js', import.meta.url), 'utf8'));

if (failed) { console.error(`\n${failed} fichier(s) en erreur de syntaxe.`); process.exit(1); }
console.log('\nSyntaxe OK.');
