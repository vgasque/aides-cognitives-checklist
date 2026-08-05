#!/usr/bin/env node
/* MANIFESTE OTA SIGNÉ — la mise à jour du contenu sans passer par l'App Store.
 *
 * POURQUOI. Sur le web, un correctif clinique arrive en MINUTES : on publie, le service worker
 * prend la nouvelle version. En natif, chaque correctif attendrait une revue Apple (1 à 3 jours).
 * Pour une aide utilisée en urgence vitale, c'est une régression de sécurité, pas un désagrément
 * de confort. Apple l'autorise explicitement (App Review 3.3.2 : du code interprété exécuté par
 * WebKit peut être téléchargé tant qu'il ne change pas la finalité de l'application).
 *
 * CE QUE CE SCRIPT PRODUIT, et rien d'autre :
 *   ota/manifest.json — version, `minShell`, et pour chaque fichier servi son SHA-256 ;
 *   ota/manifest.sig  — signature Ed25519 des OCTETS EXACTS du manifeste ;
 *   ota/pubkey.b64    — la clé PUBLIQUE, que la coquille embarque (publique par conception).
 *
 * ⚠ LA LISTE DES FICHIERS N'EST PAS ÉCRITE ICI. Elle est DÉRIVÉE d'`ASSETS` et `PDFJS_ASSETS`
 * de `sw.js`, qui sont déjà la liste de ce que l'application sert — et que `check-sw` garantit
 * complète (« tout fichier servable de la racine est dans ASSETS », règle 13). Une seconde liste
 * finirait par diverger, et le trou serait SILENCIEUX : un fichier oublié du manifeste ne serait
 * jamais mis à jour sur les appareils, indéfiniment et sans un mot. C'est exactement le piège que
 * `PDFJS_CACHE` a déjà tendu une fois à ce dépôt.
 *
 * ⚠ LA CLÉ PRIVÉE NE VIT PAS DANS LE DÉPÔT. Chemin par `AC_OTA_KEY`, sinon
 * ~/.config/aides-cognitives/ota-ed25519.pem. Elle est créée au premier lancement si elle manque.
 * Node 18 signe en Ed25519 nativement : AUCUNE dépendance ajoutée (règle 13).
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { createHash, generateKeyPairSync, sign, createPrivateKey, createPublicKey } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { homedir } from 'node:os';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const OTA = join(ROOT, 'ota');

/* Le `minShell` du manifeste : version de COQUILLE minimale exigée par ce contenu. Une coquille
   plus ancienne refuse le payload et RESTE sur le précédent, plutôt que de démarrer dégradée sans
   le dire. À monter le jour où le contenu se met à dépendre d'un verbe de pont neuf. */
const MIN_SHELL = 1;

// ── La liste des fichiers vient de sw.js, jamais d'ici ────────────────────────────────────────
const sw = readFileSync(join(ROOT, 'sw.js'), 'utf8');
const liste = nom => {
  const m = sw.match(new RegExp('const ' + nom + '\\s*=\\s*\\[([\\s\\S]*?)\\]'));
  if (!m) { console.error(`ota-manifest : ${nom} introuvable dans sw.js.`); process.exit(1); }
  return [...m[1].matchAll(/['"]([^'"]+)['"]/g)].map(x => x[1]);
};
const fichiers = [...new Set([...liste('ASSETS'), ...liste('PDFJS_ASSETS')])].sort();

const html = readFileSync(join(ROOT, 'index.html'), 'utf8');
const version = (html.match(/APP_VERSION\s*=\s*['"]([^'"]+)['"]/) || [])[1];
if (!version) { console.error('ota-manifest : APP_VERSION illisible dans index.html.'); process.exit(1); }

const entrees = fichiers.map(p => {
  const f = join(ROOT, p.replace(/^\.\//, ''));
  if (!existsSync(f)) { console.error(`ota-manifest : « ${p} » est listé mais absent du disque.`); process.exit(1); }
  const b = readFileSync(f);
  return { p, sha256: createHash('sha256').update(b).digest('hex'), taille: b.length };
});

/* Clés stables entre deux exécutions et tableau TRIÉ : le manifeste doit être reproductible à
   l'octet, sinon sa signature changerait sans que le contenu ait bougé. */
const manifeste = JSON.stringify({ version, minShell: MIN_SHELL, fichiers: entrees }, null, 2) + '\n';

// ── Signature ─────────────────────────────────────────────────────────────────────────────────
const cheminCle = process.env.AC_OTA_KEY || join(homedir(), '.config', 'aides-cognitives', 'ota-ed25519.pem');
if (!existsSync(cheminCle)) {
  mkdirSync(dirname(cheminCle), { recursive: true });
  const { privateKey, publicKey } = generateKeyPairSync('ed25519');
  writeFileSync(cheminCle, privateKey.export({ type: 'pkcs8', format: 'pem' }), { mode: 0o600 });
  console.log(`ota-manifest : clé de signature CRÉÉE — ${cheminCle}`);
  console.log('  ⚠ Sauvegardez-la. La perdre signifie qu\'aucun appareil déjà installé n\'acceptera');
  console.log('    plus de mise à jour : il faudrait republier la coquille par l\'App Store.');
  void publicKey;
}
const priv = createPrivateKey(readFileSync(cheminCle));
const pub = createPublicKey(priv);
// Format RAW (32 octets) : c'est ce que CryptoKit attend côté Swift, et le DER lui déplairait.
const pubRaw = pub.export({ type: 'spki', format: 'der' }).subarray(-32);
const signature = sign(null, Buffer.from(manifeste, 'utf8'), priv);

mkdirSync(OTA, { recursive: true });
writeFileSync(join(OTA, 'manifest.json'), manifeste);
writeFileSync(join(OTA, 'manifest.sig'), signature.toString('base64') + '\n');
writeFileSync(join(OTA, 'pubkey.b64'), pubRaw.toString('base64') + '\n');

console.log(`✓ ota-manifest : v${version}, ${entrees.length} fichier(s), minShell ${MIN_SHELL}, signé Ed25519.`);
