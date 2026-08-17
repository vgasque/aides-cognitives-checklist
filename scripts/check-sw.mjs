#!/usr/bin/env node
/* SERVICE WORKER — garde-fou statique (v4.44.0).
 *
 * POURQUOI CE FICHIER EXISTE. La fonction dont TOUT dépend en intervention — l'application
 * existe hors ligne, en mode avion, sans réseau SMUR — était la seule que rien ne mesurait :
 * aucun des onze harnais ne regardait `sw.js` ni le manifeste. Trois des défauts les plus graves
 * de cet audit vivaient précisément là (page blanche hors ligne, installation tout-ou-rien,
 * 290 Ko re-téléchargés à chaque publication), et ils n'ont été trouvés qu'à la lecture.
 *
 * CE CONTRÔLE EST STATIQUE ET INSTANTANÉ : il n'ouvre pas de navigateur, il lit des fichiers.
 * C'est ce qui lui permet de vivre dans `npm run check`, donc de tourner à CHAQUE commit — un
 * garde-fou qu'on ne joue qu'en audit ne protège rien entre deux audits. Le comportement DYNAMIQUE
 * (install, fetch, hors-ligne réel) reste hors de portée d'ici : il demande un navigateur, et
 * deux pièges documentés — désinscrire le worker et purger les caches entre exécutions (v4.30.0),
 * sans quoi on teste la version précachée et l'on conclut à tort.
 *
 * CE QU'IL VÉRIFIE, et pourquoi chaque point est une panne déjà vue ou évitée de justesse :
 *   1. Toute entrée d'`ASSETS`, de `CORE_ASSETS` et de `PDFJS_ASSETS` existe sur le disque.
 *      Une entrée fantôme fait échouer `c.add()` — silencieusement pour ASSETS (best-effort,
 *      v4.32.0), mais `CORE_ASSETS` passe par `addAll`, qui est TOUT-OU-RIEN : une seule entrée
 *      morte et il n'y a plus d'application hors ligne du tout.
 *   2. `CORE_ASSETS` est un sous-ensemble d'`ASSETS`. Sinon la boucle best-effort ne le voit pas
 *      et l'intention « noyau + reste » se disloque.
 *   3. Tout fichier SERVABLE à la racine est dans `ASSETS` — c'est la règle 13 d'AGENTS.md
 *      (« tout fichier servi doit entrer dans ASSETS »), qui ne s'auto-exécutait pas.
 *   4. `CACHE` porte la version d'`APP_VERSION`. Un décalage entre les deux casse la mise à jour
 *      du service worker : c'est la raison d'être de `release.sh` et la règle 1 du projet.
 */
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const sw = readFileSync(join(ROOT, 'sw.js'), 'utf8');
const html = readFileSync(join(ROOT, 'index.html'), 'utf8');

const liste = nom => {
  const m = sw.match(new RegExp('const ' + nom + '\\s*=\\s*\\[([\\s\\S]*?)\\]'));
  if (!m) { console.error(`check-sw : ${nom} introuvable dans sw.js.`); process.exit(1); }
  return [...m[1].matchAll(/['"]([^'"]+)['"]/g)].map(x => x[1]);
};

/* Depuis v5.10.2, ASSETS est l'UNION `[core…, ...STATIC_ASSETS]` (cache statique pérenne — le
   motif pdf.js généralisé) : la liste des statiques n'est écrite qu'une fois, et ce contrôle la
   REJOINT au lieu d'exiger sa recopie — une liste tenue en double diverge (leçon MUTE_SEL). */
const STATIC = liste('STATIC_ASSETS');
const ASSETS = [...new Set([...liste('ASSETS'), ...(sw.includes('...STATIC_ASSETS') ? STATIC : [])])];
const CORE = liste('CORE_ASSETS');
const PDFJS = liste('PDFJS_ASSETS');
const JSQR = liste('JSQR_ASSETS');
const fautes = [];
if (!sw.includes('...STATIC_ASSETS'))
  fautes.push('ASSETS ne reprend plus ...STATIC_ASSETS : la règle 13 (« tout fichier servi entre dans ASSETS ») perd les statiques');
if (STATIC.some(a => CORE.includes(a)))
  fautes.push('un actif est à la fois CORE_ASSETS et STATIC_ASSETS : deux caches se disputeraient la même clé');

/* 1. Existence sur le disque. */
for (const [nom, arr] of [['ASSETS', ASSETS], ['CORE_ASSETS', CORE], ['PDFJS_ASSETS', PDFJS], ['JSQR_ASSETS', JSQR], ['STATIC_ASSETS', STATIC]])
  for (const p of arr) {
    const f = join(ROOT, p.replace(/^\.\//, ''));
    if (!existsSync(f)) fautes.push(`${nom} référence « ${p} », absent du dépôt`);
  }

/* 2. Le noyau est bien un sous-ensemble. */
for (const c of CORE)
  if (!ASSETS.includes(c)) fautes.push(`CORE_ASSETS contient « ${c} », absent d'ASSETS`);

/* 3. Rien de servable à la racine n'est oublié. Le périmètre est la RACINE seule : le dépôt est
      déployé tel quel, mais `docs/`, `design/`, `scripts/`, `supabase/` et `exemples/` ne sont pas
      des ressources de l'application — les précacher gonflerait l'installation pour rien. */
const SERVABLE = /\.(png|svg|ico|webmanifest)$/i;
const HORS = new Set([
  'sw.js',        // le worker ne se met JAMAIS en cache (il se resservirait périmé, cf. sw.js)
  'tests.html',   // page de test, pas une ressource de l'app
]);
for (const f of readdirSync(ROOT))
  // Les fichiers en point sont les sondes jetables (gitignorées, cf. .gitignore) : jamais déployés.
  if (!f.startsWith('.') && SERVABLE.test(f) && !HORS.has(f) && !ASSETS.includes('./' + f))
    fautes.push(`« ${f} » est servi à la racine mais absent d'ASSETS (règle 13)`);

/* 4. Version du cache alignée sur celle de l'app. */
const vCache = (sw.match(/const CACHE\s*=\s*['"]aides-cognitives-v([^'"]+)['"]/) || [])[1];
const vApp = (html.match(/APP_VERSION\s*=\s*['"]([^'"]+)['"]/) || [])[1];
if (!vCache || !vApp) fautes.push('impossible de lire CACHE (sw.js) ou APP_VERSION (index.html)');
else if (vCache !== vApp)
  fautes.push(`CACHE dit v${vCache}, APP_VERSION dit v${vApp} — la mise à jour du service worker casse (règle 1 : passer par release.sh)`);

if (fautes.length) {
  console.error('✗ check-sw : ' + fautes.length + ' problème(s) de service worker.\n');
  for (const f of fautes) console.error('    ' + f);
  process.exit(1);
}
console.log(`✓ check-sw : ${ASSETS.length} asset(s) + ${PDFJS.length} pdf.js + ${JSQR.length} jsQR présents, noyau cohérent, ` +
  `racine sans oubli, CACHE aligné sur APP_VERSION (v${vApp}).`);
