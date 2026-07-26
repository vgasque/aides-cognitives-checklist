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

/* ÉLARGI EN v4.37.0 aux fonctions de couleur. Le contrôle ne voyait que les hex : `--ink` recopié
   en DÉCIMAL (`rgba(16,27,40,.45)`) passait au travers, et c'est exactement la dérive que la règle
   proscrit — cinq occurrences vivaient ainsi dans les voiles et les élévations (tokenisées depuis).

   CE QUI N'EST PAS DE LA PALETTE est exempté, avec sa raison — un garde-fou qui crie sur ce qui va
   bien finit ignoré :
   · noir et blanc PURS (`rgba(0,0,0,…)`, `rgba(255,255,255,…)`) = profondeur et voiles neutres,
     ils ne portent aucune sémantique de registre et ne suivent aucun token ;
   · les teintes de l'ALERTE de minuteur (ombre brune et halo pulsé), qui ne sont dérivées d'aucun
     token existant — les tokeniser reviendrait à inventer un token pour un seul usage. */
const EXEMPT_RGB = new Set([
  '0,0,0',            // ombres
  '255,255,255',      // voiles clairs, surbrillances
  '50,35,0',          // .alert-toast : ombre portée brune
  '242,176,28',       // .alert-toast : halo de la pulsation (toastPulse)
]);

const bad = [];
// Déclarations `prop: valeur` — une couleur littérale n'est admise que si prop commence par `--`.
const rx = /([{;]\s*)(--?[a-zA-Z][\w-]*|[a-zA-Z-]+)\s*:\s*([^;{}]*)/g;
let d;
while ((d = rx.exec(css))) {
  const prop = d[2], val = d[3];
  if (prop.startsWith('--')) continue;
  const hex = val.match(/#[0-9a-fA-F]{3,8}\b/g);
  if (hex) { bad.push(`${prop}: ${val.trim().slice(0, 70)}`); continue; }
  for (const f of val.matchAll(/(rgba?|hsla?)\(\s*([\d.]+)\s*[, ]\s*([\d.%]+)\s*[, ]\s*([\d.%]+)/g)) {
    const triplet = [f[2], f[3], f[4]].join(',');
    if (EXEMPT_RGB.has(triplet)) continue;
    bad.push(`${prop}: ${val.trim().slice(0, 70)}`);
  }
}

if (bad.length) {
  console.error(`✗ ${bad.length} couleur(s) littérale(s) hors déclaration de token (règle AGENTS.md) :`);
  [...new Set(bad)].slice(0, 12).forEach(x => console.error('    ' + x));
  console.error('  -> tokeniser (déclaration `--…` dans :root / bloc sombre / bloc accent),');
  console.error('     ou, si la valeur ne relève PAS de la palette (ombre, voile neutre),');
  console.error('     l\'ajouter à EXEMPT_RGB avec sa raison.');
  process.exit(1);
}
console.log('✓ check-colors : aucune couleur littérale hors déclaration de token (hex, rgb, hsl).');
