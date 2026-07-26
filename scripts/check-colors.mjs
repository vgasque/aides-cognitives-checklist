/* GARDE-FOU COULEURS (v4.31.0, audit externe) — rend AUTO-EXÉCUTOIRE la règle d'AGENTS.md :
   « aucune nouvelle couleur hex hors tokens ». Un hex n'est admis dans le CSS d'index.html que
   dans une DÉCLARATION DE TOKEN (propriété `--…`), où qu'elle vive (:root, overrides sombres,
   blocs data-accent — la définition de token délocalisée EST de la définition de token).
   Exception listée : les pastilles `.acc-sw` du sélecteur d'accent (nuanciers LITTÉRAUX — elles
   montrent chaque accent quel que soit l'accent actif, un var() serait faux par construction).
   Périmètre : le <style> du monofichier. Les sélecteurs (#id) ne peuvent pas déclencher : seule
   la VALEUR d'une déclaration est inspectée. Le JS (PALETTE des catégories) reste hors champ. */
import { readFile } from 'node:fs/promises';

const ROOT = decodeURIComponent(new URL('../', import.meta.url).pathname);
const html = await readFile(ROOT + 'index.html', 'utf8');
const m = html.match(/<style>([\s\S]*?)<\/style>/);
if (!m) { console.error('check-colors : <style> introuvable'); process.exit(1); }

let css = m[1]
  .replace(/\/\*[\s\S]*?\*\//g, '')          // commentaires
  .replace(/^.*\.acc-sw\..*$/gm, '');        // nuanciers littéraux du sélecteur d'accent (les
                                             // deux lignes : claire ET html[data-theme="dark"])

const bad = [];
// Déclarations `prop: valeur` — un hex dans la valeur n'est admis que si prop commence par `--`.
const rx = /([{;]\s*)(--?[a-zA-Z][\w-]*|[a-zA-Z-]+)\s*:\s*([^;{}]*)/g;
let d;
while ((d = rx.exec(css))) {
  const prop = d[2], val = d[3];
  if (prop.startsWith('--')) continue;
  const hex = val.match(/#[0-9a-fA-F]{3,8}\b/g);
  if (hex) bad.push(`${prop}: ${val.trim().slice(0, 70)}`);
}

if (bad.length) {
  console.error(`✗ ${bad.length} couleur(s) hex hors déclaration de token (règle AGENTS.md) :`);
  [...new Set(bad)].slice(0, 12).forEach(x => console.error('    ' + x));
  console.error('  -> tokeniser (déclaration `--…` dans :root / bloc sombre / bloc accent).');
  process.exit(1);
}
console.log('✓ check-colors : aucun hex hors déclaration de token dans le CSS.');
