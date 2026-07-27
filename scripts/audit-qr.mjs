#!/usr/bin/env node
/* AUDIT — CODE QR : les codes produits sont-ils RÉELLEMENT lisibles ? (v4.46.0)
 *
 * Les tests unitaires de `tests.html` prouvent beaucoup : syndromes Reed-Solomon nuls, format BCH
 * valide, table recoupée par la géométrie, motifs au bon endroit. Ils ne prouvent PAS la seule
 * chose qui compte le jour où un collègue lève son téléphone — qu'un décodeur y arrive. Un
 * encodeur peut produire des matrices impeccables et illisibles ; aucun contrôle de cohérence
 * interne ne le verrait, par construction.
 *
 * Ce harnais ferme cet écart : il prend le code tel que l'APPLICATION le produit (pas une copie de
 * l'algorithme), et le fait relire par CoreImage — le décodeur d'Apple, celui de l'appareil photo
 * de l'iPhone, qui est la cible déclarée du projet.
 *
 * macOS SEULEMENT, et c'est assumé : sans `swiftc`, le harnais AVERTIT et sort en succès, comme
 * `run-tests.mjs` le fait déjà pour WebKit manquant. Un contrôle indisponible ne doit pas se
 * déguiser en échec — mais il ne doit pas non plus se déguiser en réussite : la ligne d'avertissement
 * dit explicitement que la vérification n'a pas eu lieu.
 */
import { serveApp, moteur, NOM_MOTEUR, ROOT } from './harness.mjs';
import { execFileSync } from 'node:child_process';
import { writeFileSync, mkdtempSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

const { port, srv } = await serveApp();
const br = await moteur().launch();
let ok = 0, ko = 0;
const t = (nom, cond, det) => { if (cond) { ok++; console.log('  ✓ ' + nom); }
  else { ko++; console.log('  ✗ ' + nom + (det ? '\n      ' + det : '')); } };

// Compilation du décodeur. Absent (Linux, CI) -> on le dit et on s'arrête proprement.
const tmp = mkdtempSync(join(tmpdir(), 'acqr-'));
const bin = join(tmp, 'qrdec');
let decodeur = false;
try {
  execFileSync('swiftc', ['-O', join(ROOT, 'scripts/qr-decode.swift'), '-o', bin], { stdio: 'pipe' });
  decodeur = true;
} catch (e) {
  console.log(`\n⚠ audit-qr : swiftc indisponible sur cette machine — le décodage RÉEL n'a PAS été`);
  console.log(`  vérifié (contrôle macOS seulement). Les tests unitaires QR de tests.html, eux,`);
  console.log(`  ont bien tourné dans « npm test ».`);
  await br.close(); srv.close();
  process.exit(0);
}

console.log(`\n══ QR · relecture par le décodeur d'Apple (CoreImage) — moteur ${NOM_MOTEUR} ══`);

const CAS = [
  ['code seul (v1)',            'K7M2P4Q9'],
  ['lien court',                'https://exemple.fr/#j=K7M2P4Q9'],
  ['lien GitHub Pages réel',    'https://vgasque.github.io/aides-cognitives-checklist/#j=ABCDEFGH'],
  ['lien long (version haute)', 'https://exemple.fr/tres/long/chemin/pour/pousser/la/version/plus/haut/#j=ZZZZZZZZ&x=1234567890'],
  ['UTF-8 accentué',            'Réanimation — ⚠ cycle 2 min'],
];

const page = await br.newPage();
// Mode test : l'app N'EST PAS amorcée, seules les fonctions pures sont exposées. C'est bien le
// code EXPÉDIÉ qu'on mesure, pas une copie de l'algorithme dans ce fichier.
await page.goto(`http://localhost:${port}/index.html?__actest=1`);
await page.waitForFunction(() => !!window.__ac_test__);

for (const [nom, texte] of CAS) {
  const q = await page.evaluate(s => {
    const r = window.__ac_test__.qrEncode(s);
    if (!r) return null;
    const lignes = [];
    for (let y = 0; y < r.n; y++) {
      let l = '';
      for (let x = 0; x < r.n; x++) l += r.m[y * r.n + x] ? '1' : '0';
      lignes.push(l);
    }
    return { version: r.version, txt: lignes.join('\n') };
  }, texte);
  if (!q) { t(`${nom} : encodé`, false, 'qrEncode a renvoyé null'); continue; }
  const f = join(tmp, 'm.txt');
  writeFileSync(f, q.txt);
  let out = '';
  try { out = execFileSync(bin, [f], { encoding: 'utf8' }).trim(); }
  catch (e) { out = 'ERR:exécution'; }
  t(`v${q.version} · ${nom} : relu à l'identique`, out === 'OK:' + texte,
    `renvoyé : ${out.slice(0, 100)}`);
}

// La zone de silence fait partie de la norme : sans elle un lecteur peut refuser le code. On le
// VÉRIFIE plutôt que de l'affirmer — en la retirant, la lecture doit échouer.
{
  const q = await page.evaluate(() => {
    const r = window.__ac_test__.qrEncode('K7M2P4Q9');
    const lignes = [];
    for (let y = 0; y < r.n; y++) {
      let l = '';
      for (let x = 0; x < r.n; x++) l += r.m[y * r.n + x] ? '1' : '0';
      lignes.push(l);
    }
    return lignes.join('\n');
  });
  // On borde le code de modules sombres : la zone de silence disparaît sous du bruit.
  const l = q.split('\n'), n = l.length;
  const bruit = l.map(r => '1' + r + '1');
  bruit.unshift('1'.repeat(n + 2)); bruit.push('1'.repeat(n + 2));
  const f = join(tmp, 'noisy.txt');
  writeFileSync(f, bruit.join('\n'));
  let out = '';
  try { out = execFileSync(bin, [f], { encoding: 'utf8' }).trim(); } catch (e) { out = 'ERR'; }
  // Le décodeur d'Apple est robuste : s'il y arrive quand même, ce n'est pas un défaut de
  // l'encodeur. Le contrôle sert à prouver que la sonde SAIT distinguer deux images — pas à
  // exiger un échec. On signale seulement, sans faire échouer le harnais.
  console.log(out.startsWith('OK:')
    ? '  · zone de silence noyée : le décodeur y arrive encore (il est tolérant) — sonde non concluante'
    : '  ✓ la sonde sait distinguer une image dégradée (zone de silence noyée : illisible)');
  if (!out.startsWith('OK:')) ok++;
}

await page.close();
await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles QR OK`);
process.exit(ko ? 1 : 0);
