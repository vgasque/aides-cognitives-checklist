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

console.log('Vérification de syntaxe :');
checkInlineScripts('index.html');
checkInlineScripts('tests.html');
checkCode('sw.js', readFileSync(new URL('../sw.js', import.meta.url), 'utf8'));

if (failed) { console.error(`\n${failed} fichier(s) en erreur de syntaxe.`); process.exit(1); }
console.log('\nSyntaxe OK.');
