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
import { serveApp, moteur, NOM_MOTEUR, ROOT, amorce } from './harness.mjs';
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

/* Les témoins couvrent une ÉCHELLE DE LONGUEURS (8 · 30 · 35 · 64 · 94 caractères), parce que
   c'est la longueur qui décide de la VERSION du QR — donc de la densité des modules, donc de ce
   qu'un appareil photo arrive encore à décoder. Mesuré : v1 · v3 · v3 · v5 · v6.
   Deux d'entre eux sont des liens RÉELS, et ils le restent : la production a déménagé sur son
   propre domaine le 2026-08-26 (35 caractères, v3), mais le sous-répertoire (64, v5) n'est pas
   devenu fictif pour autant — c'est la forme que prend tout déploiement en
   `<compte>.github.io/<dépôt>/` ou dans un sous-chemin d'intranet, et remplacer l'un par l'autre
   aurait laissé DEUX versions de QR sans aucun témoin (v5, et la marche v3→v5). */
const CAS = [
  ['code seul (v1)',            'K7M2P4Q9'],
  ['lien court',                'https://exemple.fr/#j=K7M2P4Q9'],
  ['lien de production réel',   'https://aide.exemple.fr/#j=ABCDEFGH'],
  ['lien en sous-répertoire',   'https://vgasque.github.io/aides-cognitives-checklist/#j=ABCDEFGH'],
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

/* ══ LE QR RÉELLEMENT PEINT, PAS LA MATRICE (v4.47.0) ═════════════════════════════════════════
   Tout ce qui précède prouve que l'ENCODEUR est juste. Un utilisateur a pourtant rapporté
   « aucune donnée utilisable trouvée » en scannant la fenêtre d'appariement avec un iPhone : ces
   contrôles étaient donc aveugles au défaut qu'ils prétendent couvrir. Entre la matrice et
   l'appareil photo il y a la génération du SVG, deux variables CSS de couleur, un
   `shape-rendering`, une largeur en `vw` et un rendu sous-pixel — aucun de ces maillons n'était
   mesuré. On capture donc l'ÉLÉMENT PEINT dans la page, à chaque largeur servie, et on le donne
   au décodeur d'Apple. */
console.log(`\n══ QR · l'image PEINTE dans la fenêtre d'appariement — moteur ${NOM_MOTEUR} ══`);
for (const [w, h, theme] of [[320, 568, 'light'], [390, 844, 'light'], [390, 844, 'dark'], [760, 900, 'light']]) {
  const p = await br.newPage({ viewport: { width: w, height: h }, colorScheme: theme,
    deviceScaleFactor: 2 });
  await p.goto(`http://localhost:${port}/index.html`);
  await amorce(p);
  await p.evaluate(async () => {
    const f = fiches.find(x => /Arrêt/.test(x.title)) || fiches[0]; openRead(f.id);
    await new Promise(r => setTimeout(r, 300)); document.getElementById('sessStart').click();
    await new Promise(r => setTimeout(r, 300));
  });
  const url = await p.evaluate(async () => {
    Share._io.open = async () => ({ ok: true, share: 's1', code: 'K7M2P4Q9',
      join_open_until: new Date(Date.now() + 120e3).toISOString(),
      expires_at: new Date(Date.now() + 3600e3).toISOString(), server_time: new Date().toISOString() });
    Share._io.pull = async () => ({ ok: true, status: 'active', events: [], seq: 0, n_events: 0,
      participants: [], server_time: new Date().toISOString() });
    Share._io.push = async () => ({ ok: true, server_time: new Date().toISOString() });
    Auth.signedIn = () => true;
    await startShare(state.fiche); await new Promise(x => setTimeout(x, 900));
    /* CE QU'ON ATTEND EST CE QUE L'APP A DÉCIDÉ D'ENCODER, et cette décision dépend de l'origine :
       une URL n'a de valeur dans un QR que si le téléphone qui le scanne peut l'ATTEINDRE. Servi
       depuis `localhost` — comme ici, et comme sur un poste de développement — c'est le CODE SEUL
       qui est encodé, que l'appareil photo affiche comme du texte. C'est précisément le défaut
       rapporté : l'ancienne version encodait une adresse locale, décodée puis inutilisable, d'où
       « aucune donnée utilisable trouvée ». La règle elle-même est vérifiée à part, en test
       unitaire (`shareJoinUrl`) ; ici on vérifie que l'IMAGE PEINTE rend bien cette décision. */
    return shareJoinUrl('K7M2P4Q9') || 'K7M2P4Q9';
  });
  const el = await p.$('#shareModal .qr');
  if (!el) { t(`${w}×${h} ${theme} · le QR est peint`, false, 'aucun élément .qr'); await p.close(); continue; }
  const png = join(tmp, `qr-${w}-${theme}.png`);
  await el.screenshot({ path: png });
  let out = '';
  try { out = execFileSync(bin, [png], { encoding: 'utf8' }).trim(); } catch (e) { out = 'ERR:exécution'; }
  t(`${w}×${h} ${theme} · l'image peinte est relue par le décodeur d'Apple`, out === 'OK:' + url,
    `attendu « ${url} », obtenu « ${out} »`);
  await p.close();
}

await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles QR OK`);
process.exit(ko ? 1 : 0);
