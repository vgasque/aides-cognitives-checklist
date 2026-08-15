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
  /* EXEMPTION À LA RÈGLE, PLUS À LA LIGNE (v4.44.0). Elle était `^.*\.acc-sw\..*$` — donc
     LIGNE ENTIÈRE. Le CSS de ce projet écrit plusieurs règles par ligne : trois lignes étaient
     exemptées, dont DEUX portant SIX règles chacune (les nuanciers clair et sombre), et une
     troisième — `.acc-sw.on` — qui ne contient aucun hex et bénéficiait du blanc-seing pour
     rien. Un hex collé en fin de l'une de ces lignes passait donc inaperçu (démontré : `exit 0`
     avec la fuite en place, `exit 1` la même déclaration écrite une ligne plus haut).
     Ne sont désormais exemptées que les règles dont le SÉLECTEUR nomme un nuancier, c'est-à-dire
     `.acc-sw.a-…` : ce sont les seules qui doivent porter une couleur littérale, puisqu'elles
     montrent chaque accent quel que soit l'accent actif — un `var()` y serait faux par
     construction. Tout le reste de ces mêmes lignes redevient inspecté. */
  .replace(/[^{}]*\.acc-sw\.a-[^{}]*\{[^}]*\}/g, '');

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

/* Blocs de tokens, gardés BRUTS pour le contrôle de la barre système plus bas : c'est la seule
   partie du fichier dont une valeur doive être RELUE, et non seulement autorisée. */
const rootTokensRaw = (css.match(/:root\{[^}]*\}/) || [])[0];
const darkTokensRaw = (css.match(/html\[data-theme="dark"\]\{\s*--[^}]*\}/) || [])[0];

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

/* ═══ LA BARRE SYSTÈME (v5.0.0, audit) ═══════════════════════════════════════════════════════
   CE CONTRÔLE EXISTE PARCE QUE LE PRÉCÉDENT S'ARRÊTAIT AU <style>, ET QUE LA FUITE ÉTAIT DEHORS.
   `themeColorCurrent()` et le script de boot peignent la barre d'état du téléphone avec deux hex
   ÉCRITS EN CLAIR DANS LE JS. Ils valaient `--bg` à l'écriture ; `--bg` sombre est passé de
   `#121d2b` à `#0a0a0c` en v4.71.0 et personne n'a suivi — pendant six versions, la barre d'état
   d'un iPhone en thème sombre était peinte d'un bleu marine qui n'existait plus dans la palette,
   sur 44 px, juste au-dessus de l'annonciateur de mode. Le fichier était vert de bout en bout.

   TROIS PROPRIÉTÉS VÉRIFIÉES, et la troisième est celle qui mord :
     1. les deux sites (table `THEME_COLOR` et script de boot) portent les MÊMES valeurs — leur
        désaccord se verrait par un flash de couleur au premier rendu ;
     2. chaque valeur est un token RÉEL de son thème, pas une couleur inventée ;
     3. c'est bien `--amb` (la barre système prolonge l'EN-TÊTE ; depuis la refonte v5.6, celui-ci
        est en AMBIANCE — les matières ont remplacé les bandes). Sans ce troisième point, remettre
        `--bg` demain repasserait au vert tout en refaisant exactement le défaut d'origine.

   LE RESTE DES LITTÉRAUX DU JS N'EST PAS INSPECTÉ, ET C'EST MOTIVÉ : ce sont des copies FIGÉES,
   pas des suiveurs de token. `PALETTE`/`defaultCats` (couleurs de CATÉGORIE — hors palette de
   registres, déjà hors champ par la règle d'origine) ; le CSS de `_reportDoc` (document autonome
   TÉLÉCHARGEABLE : il doit s'afficher sans l'app, et ne doit surtout pas suivre le thème sombre —
   un compte rendu s'imprime) ; `buildFlowSVG` (primaire baké clair + contre-inversion sombre,
   décision v4.7.0). Les exempter en bloc serait laxiste ; les tokeniser casserait leur raison
   d'être. On nomme donc ce qui DOIT suivre, et on inspecte cela seul. */
const themeBad = [];
/* `#fff` et `#ffffff` sont la MÊME couleur : comparer les chaînes ferait échouer le contrôle sur
   une notation, pas sur une dérive — et un garde-fou qui crie sur ce qui va bien finit ignoré. */
const hex6 = h => {
  const s = String(h || '').toLowerCase();
  return s.length === 4 ? '#' + s[1] + s[1] + s[2] + s[2] + s[3] + s[3] : s;
};
/* v5.6 : le token visé peut être un ALIAS (--surface:var(--work)). On suit UNE indirection —
   au-delà, c'est une chaîne d'alias, et une chaîne d'alias sur une couleur de chrome est
   exactement ce qu'on ne veut pas avoir à démêler pour savoir de quelle couleur est la barre. */
const tokenOf = (block, name, depth = 0) => {
  const b = block || '';
  const m = b.match(new RegExp('--' + name + ':\\s*(#[0-9a-fA-F]{3,8})\\b'));
  if (m) return hex6(m[1]);
  const a = b.match(new RegExp('--' + name + ':\\s*var\\(--([\\w-]+)\\)'));
  return (a && depth < 1) ? tokenOf(block, a[1], depth + 1) : null;
};
const surfLight = tokenOf(rootTokensRaw, 'amb');
const surfDark  = tokenOf(darkTokensRaw, 'amb');
const tableM = html.match(/const THEME_COLOR=\{light:'(#[0-9a-fA-F]{3,8})',dark:'(#[0-9a-fA-F]{3,8})'\}/);
const bootM  = html.match(/_tc\.setAttribute\('content',\s*_d==='dark'\?'(#[0-9a-fA-F]{3,8})':'(#[0-9a-fA-F]{3,8})'\)/);

if (!surfLight || !surfDark) themeBad.push('token --amb introuvable dans :root ou le bloc sombre');
if (!tableM) themeBad.push('table THEME_COLOR introuvable (forme attendue : const THEME_COLOR={light:\'#…\',dark:\'#…\'})');
if (!bootM)  themeBad.push('script de boot : pose de meta[theme-color] introuvable');
if (tableM && bootM && surfLight && surfDark) {
  const t = { light: hex6(tableM[1]), dark: hex6(tableM[2]) };
  const b = { light: hex6(bootM[2]),  dark: hex6(bootM[1])  };
  for (const th of ['light', 'dark']) {
    const want = th === 'light' ? surfLight : surfDark;
    if (t[th] !== b[th]) themeBad.push(`${th} : THEME_COLOR (${t[th]}) ≠ script de boot (${b[th]}) — flash au premier rendu`);
    else if (t[th] !== want) themeBad.push(`${th} : barre système ${t[th]} ≠ --amb ${want} (la barre prolonge l'en-tête)`);
  }
}
/* LE MANIFESTE AUSSI (v5.10.2, audit externe M-1) : `theme_color`/`background_color` peignent le
   SPLASH et la barre système AU LANCEMENT — avant tout CSS. Ils portaient des hex qui n'existaient
   dans AUCUN token (#ffffff, #e9edf2) : flash de couleurs hors palette à chaque démarrage, et ce
   contrôle, borné au bloc <style>, ne pouvait pas le voir. Le manifeste ne sait pas être sombre :
   il s'aligne sur le CLAIR de THEME_COLOR, la même vérité que la barre. */
try {
  const mf = JSON.parse(await readFile(ROOT + 'manifest.webmanifest', 'utf8'));
  if (tableM) {
    const want = hex6(tableM[1]);
    for (const k of ['theme_color', 'background_color'])
      if (hex6(String(mf[k] || '')) !== want)
        themeBad.push(`manifest.webmanifest : ${k} (${mf[k]}) ≠ THEME_COLOR.light (${want}) — splash hors palette`);
  }
} catch (e) { themeBad.push('manifest.webmanifest illisible : ' + e.message); }
if (themeBad.length) {
  console.error('✗ check-colors : la barre système a dérivé de ses tokens.');
  themeBad.forEach(x => console.error('    ' + x));
  console.error('  -> aligner THEME_COLOR (index.html) ET le script de boot sur --amb des deux thèmes.');
  process.exit(1);
}

console.log('✓ check-colors : aucune couleur littérale hors déclaration de token (hex, rgb, hsl) ;'
  + ` barre système alignée sur --amb (${surfLight} / ${surfDark}).`);
