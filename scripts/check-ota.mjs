#!/usr/bin/env node
/* MANIFESTE OTA — garde-fou statique (lot 3 du portage natif).
 *
 * POURQUOI CE FICHIER EXISTE. Le manifeste est ce qui décide de ce que les appareils NATIFS
 * téléchargent. S'il ment — un fichier oublié, un hash périmé, une version décalée — la
 * conséquence n'est pas une erreur visible mais une MISE À JOUR QUI N'ARRIVE PAS : l'appareil
 * garde l'ancien contenu, indéfiniment et sans un mot. C'est exactement le mode de défaillance
 * de `PDFJS_CACHE` (v5.0.0), qui laissait chaque appareil déjà installé avec l'ANCIENNE
 * bibliothèque pdf.js — « la mise à jour de sécurité qui n'atteint personne ».
 *
 * CE QU'IL VÉRIFIE :
 *   1. Le manifeste couvre EXACTEMENT `ASSETS` ∪ `PDFJS_ASSETS` de sw.js — ni plus, ni moins.
 *      Ni plus : un fichier fantôme ferait échouer la mise à jour entière côté coquille.
 *      Ni moins : un fichier absent du manifeste ne serait JAMAIS rafraîchi.
 *   2. Chaque hash correspond au fichier RÉELLEMENT sur le disque. Un manifeste non régénéré
 *      après une édition est le cas nominal de l'oubli — il est donc traité comme une faute.
 *   3. La version du manifeste est alignée sur `APP_VERSION` (règle 1, étendue à l'OTA).
 *   4. La signature est présente et vérifie CONTRE la clé publique publiée. Un manifeste juste
 *      mais mal signé serait refusé par tous les appareils, donc silencieusement inopérant.
 *
 * ⚠ ABSENT ≠ FAUTE. Tant que `ota/` n'existe pas, le contrôle passe en ANNONÇANT qu'il n'a rien
 * mesuré : le dépôt reste publiable en PWA seule, et le portage natif est un chantier en cours.
 * Un garde-fou qui exigerait un artefact non encore adopté bloquerait le web pour rien.
 */
import { readFileSync, existsSync } from 'node:fs';
import { createHash, verify, createPublicKey } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const OTA = join(ROOT, 'ota');
const M = join(OTA, 'manifest.json'), S = join(OTA, 'manifest.sig'), P = join(OTA, 'pubkey.b64');

if (!existsSync(M)) {
  console.log('• check-ota : aucun manifeste OTA (ota/manifest.json) — rien à vérifier.');
  console.log('  (normal tant que la coquille native n\'est pas publiée ; `node scripts/ota-manifest.mjs` le crée.)');
  process.exit(0);
}

const fautes = [];
const brut = readFileSync(M, 'utf8');
let man;
try { man = JSON.parse(brut); } catch (e) { console.error('✗ check-ota : manifeste illisible — ' + e.message); process.exit(1); }

// 1. Périmètre : exactement ce que sw.js déclare servir.
const sw = readFileSync(join(ROOT, 'sw.js'), 'utf8');
const liste = nom => {
  const m = sw.match(new RegExp('const ' + nom + '\\s*=\\s*\\[([\\s\\S]*?)\\]'));
  return m ? [...m[1].matchAll(/['"]([^'"]+)['"]/g)].map(x => x[1]) : [];
};
const attendus = new Set([...liste('ASSETS'), ...liste('PDFJS_ASSETS')]);
const presents = new Set((man.fichiers || []).map(f => f.p));
for (const p of attendus) if (!presents.has(p))
  fautes.push(`« ${p} » est servi (sw.js) mais ABSENT du manifeste — il ne serait jamais mis à jour`);
for (const p of presents) if (!attendus.has(p))
  fautes.push(`« ${p} » est dans le manifeste mais n'est plus servi — la mise à jour échouerait sur un fichier fantôme`);

// 2. Hashs contre le disque.
for (const f of man.fichiers || []) {
  const chemin = join(ROOT, f.p.replace(/^\.\//, ''));
  if (!existsSync(chemin)) { fautes.push(`« ${f.p} » : absent du disque`); continue; }
  const b = readFileSync(chemin);
  const h = createHash('sha256').update(b).digest('hex');
  if (h !== f.sha256)
    fautes.push(`« ${f.p} » : hash périmé — manifeste non régénéré depuis la dernière édition`);
}

// 3. Version alignée (règle 1).
const html = readFileSync(join(ROOT, 'index.html'), 'utf8');
const vApp = (html.match(/APP_VERSION\s*=\s*['"]([^'"]+)['"]/) || [])[1];
if (man.version !== vApp)
  fautes.push(`le manifeste dit v${man.version}, APP_VERSION dit v${vApp} (règle 1 : passer par release.sh)`);

// 4. Signature.
if (!existsSync(S) || !existsSync(P)) {
  fautes.push('signature ou clé publique manquante (ota/manifest.sig, ota/pubkey.b64)');
} else {
  const raw = Buffer.from(readFileSync(P, 'utf8').trim(), 'base64');
  // Reconstitution du SPKI DER à partir des 32 octets bruts — préfixe fixe pour Ed25519.
  const spki = Buffer.concat([Buffer.from('302a300506032b6570032100', 'hex'), raw]);
  try {
    const ok = verify(null, Buffer.from(brut, 'utf8'),
                      createPublicKey({ key: spki, format: 'der', type: 'spki' }),
                      Buffer.from(readFileSync(S, 'utf8').trim(), 'base64'));
    if (!ok) fautes.push('la signature ne vérifie PAS contre ota/pubkey.b64 — aucun appareil n\'accepterait cette mise à jour');
  } catch (e) { fautes.push('signature invérifiable : ' + e.message); }
}

if (fautes.length) {
  console.error('✗ check-ota : ' + fautes.length + ' problème(s).\n');
  for (const f of fautes) console.error('  · ' + f);
  console.error('\n  -> régénérer : node scripts/ota-manifest.mjs');
  process.exit(1);
}
console.log(`✓ check-ota : ${(man.fichiers || []).length} fichier(s), hashs à jour, v${man.version}, signature vérifiée.`);
