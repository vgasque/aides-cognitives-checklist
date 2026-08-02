/* GARDE-FOU — TOUTE ENTRÉE DE FICHIER PASSE PAR LA PORTE (v5.0.0, chantier des uploads).
 *
 * POURQUOI. Avant ce chantier, quatre chemins d'upload cohabitaient avec quatre niveaux de
 * rigueur, et ils avaient DÉJÀ divergé — 60 images maximum côté référence, aucun plafond côté
 * aide, aucun plafond du tout à l'import, et deux `accept` écrits à la main que rien ne reliait
 * aux vérifications faites. C'est la leçon la plus redite du dossier : partout où une règle est
 * restée DÉCLARATIVE, elle a fui (`MUTE_SEL`, les verbes de partage, la liste des placards, les
 * paliers responsive qui avaient douze valeurs pour neuf déclarées), et l'écart est SILENCIEUX.
 *
 * CE QUE CE CONTRÔLE REND AUTO-EXÉCUTOIRE :
 *   1. un seul `<input type="file">` dans tout le fichier, et c'est `#upInput` ;
 *   2. aucun `accept=` écrit à la main dans le balisage — il vient de `UP_KINDS`, où il est
 *      posé sur la même ligne que la signature qui sera vérifiée ;
 *   3. aucun `accept` fourre-tout du genre « image/étoile » : c'est par là que le SVG entrait ;
 *   4. chaque nature de la table porte ses cinq champs (accept · sniff · max · un · ind) ;
 *   5. aucun NOUVEAU site ne lit `.files` sans passer par la porte — c'est la règle qui compte,
 *      parce qu'un cinquième chemin d'upload ajouté demain serait exactement le défaut d'hier.
 *
 * Vérifié CAPABLE D'ÉCHOUER sur les cinq points (défauts réintroduits un à un, fichier restauré
 * à l'octet) : un garde-fou qui ne peut pas échouer ne prouve rien — leçon v4.31.1.
 */
import { readFileSync } from 'node:fs';
const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const lignes = html.split('\n');
const noLigne = (i) => html.slice(0, i).split('\n').length;

const fautes = [];
const dire = (l, m) => fautes.push(`index.html:${l}  ${m}`);
/* Un COMMENTAIRE qui cite `<input type="file">` ou `.files` n'est pas un site d'upload — et ce
   fichier en cite plusieurs, précisément pour énoncer la règle. On NEUTRALISE donc les
   commentaires (blocs, commentaires HTML, lignes commençant par `//`) en préservant les offsets,
   de sorte que les numéros de ligne restent justes.
   ⚠ Sur-neutraliser fait ÉCHOUER (un site attendu manquerait à l'appel), jamais passer sous
   silence : la marge d'erreur de cette approximation tombe donc du bon côté. */
const blanc = (s) => s.replace(/[^\n]/g, ' ');
const code = html
  .replace(/\/\*[\s\S]*?\*\//g, blanc)
  .replace(/<!--[\s\S]*?-->/g, blanc)
  .split('\n').map(l => (/^\s*\/\//.test(l) ? blanc(l) : l)).join('\n');
const lignesCode = code.split('\n');
const dansCode = (l) => !!(lignesCode[l - 1] || '').trim();

/* ── 1 · UN SEUL SÉLECTEUR DE FICHIER ────────────────────────────────────────────────────── */
const inputs = [];
{ const rx = /<input\b[^>]*\btype\s*=\s*["']file["'][^>]*>/gi; let m;
  while ((m = rx.exec(code))) { const l = noLigne(m.index);
    if (dansCode(l)) inputs.push({ l, tag: m[0] }); } }
if (inputs.length !== 1) {
  inputs.forEach(i => dire(i.l, `<input type="file"> supplémentaire — il n’en existe qu’UN (#upInput) : ${i.tag.slice(0, 90)}`));
  if (!inputs.length) fautes.push('index.html  aucun <input type="file"> : #upInput a disparu.');
} else if (!/id\s*=\s*["']upInput["']/.test(inputs[0].tag)) {
  dire(inputs[0].l, `l’unique <input type="file"> doit porter id="upInput" : ${inputs[0].tag.slice(0, 90)}`);
}

/* ── 2 · AUCUN `accept` ÉCRIT À LA MAIN ──────────────────────────────────────────────────────
   L'attribut est posé par `pickFile` depuis la table ; l'écrire dans le balisage rouvrirait la
   possibilité qu'il dise autre chose que ce que la porte vérifie. */
inputs.forEach(i => { if (/\baccept\s*=/i.test(i.tag)) dire(i.l, 'accept= écrit dans le balisage — il vient de UP_KINDS, jamais de la main.'); });
{ const rx = /\.accept\s*=/g; let m, n = 0;
  while ((m = rx.exec(code))) { const l = noLigne(m.index);
    if (!dansCode(l)) continue;
    n++;
    if (!/UP_KINDS|K\.accept/.test(lignes[l - 1])) dire(l, '`.accept =` posé ailleurs que depuis UP_KINDS.'); }
  if (!n) fautes.push('index.html  plus aucun `.accept =` : pickFile ne pose plus l’accept de la table.'); }

/* ── 3 · LA TABLE : cinq champs par nature, aucun fourre-tout ────────────────────────────── */
{ const i = code.indexOf('const UP_KINDS=');
  if (i < 0) fautes.push('index.html  UP_KINDS introuvable — la table est LA source unique.');
  else {
    // Corps de la déclaration : de l'accolade ouvrante à la première fermante en colonne 0 du littéral.
    const debut = code.indexOf('{', i);
    let prof = 0, fin = debut;
    for (let k = debut; k < code.length; k++) {
      if (code[k] === '{') prof++;
      else if (code[k] === '}') { prof--; if (!prof) { fin = k; break; } } }
    const corps = code.slice(debut, fin + 1);
    const l = noLigne(i);
    const natures = [...corps.matchAll(/(\w+)\s*:\s*\{/g)].map(m => m[1]);
    const attendues = ['pdf', 'image', 'data'];
    const manquantes = attendues.filter(n => !natures.includes(n));
    if (manquantes.length) dire(l, `nature(s) absente(s) de UP_KINDS : ${manquantes.join(', ')}`);
    const enTrop = natures.filter(n => !attendues.includes(n));
    if (enTrop.length) dire(l, `nature(s) inattendue(s) dans UP_KINDS : ${enTrop.join(', ')} — une quatrième nature se décide, elle ne s’ajoute pas en passant.`);
    // Chaque nature porte ses cinq champs : sans l'un d'eux, la porte ou la zone mentirait.
    attendues.forEach(nom => {
      const d = corps.indexOf(nom + ':');
      if (d < 0) return;
      const suite = corps.slice(d, corps.indexOf('}', d) + 1);
      ['accept', 'sniff', 'max', 'un', 'ind'].forEach(champ => {
        if (!new RegExp('\\b' + champ + '\\s*:').test(suite)) dire(l, `UP_KINDS.${nom} : champ « ${champ} » manquant.`); });
    });
    // Le fourre-tout est la porte par laquelle le SVG entrait : `accept="image/*"`.
    [...corps.matchAll(/accept\s*:\s*'([^']*)'/g)].forEach(m => {
      if (/image\/\*|\*\/\*|application\/\*/.test(m[1]))
        dire(l, `accept fourre-tout « ${m[1]} » — il admettrait des formats que la signature refusera ensuite.`); });
  } }

/* ── 4 · AUCUN SITE NE LIT `.files` HORS DE LA PORTE ─────────────────────────────────────────
   On COMPTE au lieu de deviner la portée : les trois sites légitimes sont `bindUpDrop` (dépôt sur
   une zone), `upInput.onchange` (sélecteur) et le garde global `window.drop`. Un quatrième est,
   par construction, un chemin d'upload qui ne passe pas par `acceptFile` — c'est-à-dire le défaut
   que ce chantier a supprimé, en train de revenir. */
const SITES_ATTENDUS = 3;
const sites = [];
{ const rx = /\b(?:dataTransfer|target|e)\s*(?:&&\s*\w+\.)?\.?\w*\.files\b|\.files\b/g; let m;
  while ((m = rx.exec(code))) {
    const l = noLigne(m.index);
    if (!dansCode(l)) continue;
    sites.push({ l, txt: (lignes[l - 1] || '').trim().slice(0, 100) }); } }
if (sites.length !== SITES_ATTENDUS) {
  fautes.push(`index.html  ${sites.length} site(s) lisent « .files » au lieu de ${SITES_ATTENDUS} :`);
  sites.forEach(s => fautes.push(`    index.html:${s.l}  ${s.txt}`));
  fautes.push('    Tout nouveau chemin d’upload doit passer par upTake()/acceptFile() —');
  fautes.push('    sinon il retrouve exactement les quatre rigueurs divergentes d’avant la v5.0.0.');
}

/* ── 5 · LA PORTE EXISTE ET N'EST PAS CONTOURNÉE ─────────────────────────────────────────── */
['function acceptFile(', 'async function upTake(', 'function pickFile(', 'function upDetect(']
  .forEach(sig => { if (code.indexOf(sig) < 0) fautes.push(`index.html  ${sig}…) introuvable — la porte a été démontée.`); });

if (fautes.length) {
  console.log('\n✗ check-upload : la porte des entrées de fichier est contournée ou incomplète :');
  fautes.forEach(f => console.log('   ' + f));
  console.log('\n  Un champ de PDF qui accepterait un JSON, ou un upload qui ne vérifie que son');
  console.log('  `accept`, est précisément ce que ce contrôle existe pour empêcher.\n');
  process.exit(1);
}
console.log(`✓ check-upload : 1 sélecteur, 3 natures complètes, ${SITES_ATTENDUS} sites de lecture, accept issu de la table.`);
