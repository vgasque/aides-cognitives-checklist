/* LANCEUR DES HARNAIS D'AUDIT (v5.0.0) — parallèle, rapport agrégé, ciblage explicite.
 *
 * POURQUOI. `npm run audit` était une chaîne `&&` de dix-sept processus : séquentielle (on paie
 * la SOMME des durées — mesuré 9 min 42 s, dont 87 % dans quatre harnais : doctrine 215 s,
 * a11y 135 s, partage 89 s, k5 67 s) et fail-fast (un rouge dans le harnais n°3 CACHE tout ce qui
 * suit — l'incident « un harnais qui plante en emporte cinq » de la v4.70.1, revécu à chaque
 * itération : on corrige un défaut, on relance tout, on découvre le suivant).
 *
 * CE QUE CE LANCEUR CHANGE — ET RIEN D'AUTRE : l'ordonnancement. Les sondes, leurs seuils et leur
 * contenu sont strictement inchangés ; chaque harnais reste un processus autonome qu'on peut
 * toujours lancer seul (`node scripts/audit-doctrine.mjs`). Les harnais sont indépendants par
 * construction (chacun son serveur sur port libre via `serveApp`, son navigateur ; seul audit-qr
 * écrit sur disque, dans un mkdtemp unique) : les jouer en concurrence ne change aucun verdict.
 *
 * TRANCHES (v5.4.4). Mesuré sur la passe complète : doctrine (216,7 s) était À LUI SEUL le temps
 * mural — le pool absorbait les 19 autres pendant qu'il tournait. Ses 51 sections étant
 * indépendantes (seul état partagé : les compteurs ok/ko), un harnais peut déclarer `tranches: n`
 * et le lanceur le lance en n processus `--shard k/n` (découpe au modulo dans secRunner /
 * trancheArg de harness.mjs — les sondes ne changent pas d'une ligne). GARDE-FOU : chaque tranche
 * imprime `##SEC joues=j total=N` et le lanceur VÉRIFIE que la somme des tranches couvre le
 * total — une tranche qui perdrait des sections serait une troncature SILENCIEUSE, et un vert
 * tronqué est pire qu'un rouge. Mesuré après découpe : 216,7 s → ~120 s de temps mural, aucun
 * verdict changé.
 *
 * ORDONNANCEMENT : les plus lourds partent en PREMIER (poids mesurés ci-dessous), sinon un
 * mastodonte lancé en dernier fixe seul le temps mural. Pool borné à AC_JOBS (défaut 4) : les
 * sondes portent des attentes en temps réel, et un pool trop large les affamerait en CPU — un
 * rouge obtenu sous forte charge se confirme en rejouant le harnais SEUL avant d'y croire.
 *
 * CIBLAGE (`npm run audit -- partage qr`) : pendant l'itération on ne rejoue que les harnais du
 * domaine touché. DEUX GARDE-FOUS, non négociables : une passe partielle s'annonce « PARTIELLE »
 * en toutes lettres (un vert partiel pris pour un vert complet serait pire que le statu quo — la
 * règle « avant chaque commit, npm run audit » entier reste, et la CI rejoue tout) ; et un nom
 * inconnu ÉCHOUE bruyamment au lieu de lancer une passe vide qui aurait l'air verte (même doctrine
 * que AC_ENGINE dans harness.mjs). Pour UNE section d'un gros harnais, viser plus fin encore :
 * `node scripts/audit-doctrine.mjs --grep <motif>` (secRunner, harness.mjs) — c'est la boucle
 * d'itération à quelques secondes, la passe complète restant la porte de commit.
 *
 * REJOUER LES ROUGES (`npm run audit -- --rouges`, v5.4.4) : chaque passe écrit dans
 * `.audit-etat.json` (racine, gitignoré) la liste des harnais en échec ; `--rouges` ne rejoue
 * qu'eux, annoncé PARTIELLE. Aucun rouge enregistré → il le dit et sort vert (ce n'est pas un
 * mensonge : rien n'était dû).
 *
 * CACHE DE PASSE VERTE (v5.4.4) : une passe COMPLÈTE verte enregistre le SHA-256 de tout ce qui
 * peut influencer un verdict (fichiers servables de la racine, vendor/, scripts/*.mjs, moteur).
 * Si rien n'a changé depuis, `npm run audit` le DIT au lieu de rejouer — des entrées identiques
 * octet à octet donnent le même verdict, c'est le cas réel « je n'ai touché que le CHANGELOG
 * depuis le dernier vert ». `--force` rejoue quand même. Une passe PARTIELLE n'écrit ni ne
 * consomme jamais ce cache.
 *
 * AC_ENGINE est transmis tel quel aux enfants (héritage d'environnement) :
 *     AC_ENGINE=webkit npm run audit            → tous les harnais sur WebKit
 *     npm run audit -- doctrine                 → un seul harnais (ses 4 tranches), PARTIELLE
 *     npm run audit -- --rouges                 → les seuls harnais rouges de la dernière passe
 *     AC_JOBS=2 npm run audit                   → pool réduit (machine chargée)
 */
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { availableParallelism } from 'node:os';
import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, writeFileSync } from 'node:fs';

/* LISTE EXACTE des harnais — la source de vérité, ex-chaîne du script `audit` de package.json
   (AGENTS.md y renvoie). Le poids est la durée MESURÉE en secondes (2026-08, Chromium, M-series) :
   il ne sert qu'à ordonner lourd-d'abord, une dérive ne fausse aucun verdict. `tranches` : le
   harnais sait se découper (`--shard k/n`, cf. secRunner/trancheArg dans harness.mjs) et le
   lanceur le joue en n processus parallèles — réservé à ceux qui dominent le temps mural. */
const HARNAIS = [
  { nom: 'audit-doctrine',      poids: 217, tranches: 4 },
  { nom: 'audit-a11y',          poids: 128, tranches: 2 },
  { nom: 'audit-partage',       poids: 76,  tranches: 2 },
  { nom: 'audit-k5',            poids: 67 },
  { nom: 'audit-pdfsearch',     poids: 66 },
  { nom: 'audit-complications', poids: 13 },
  { nom: 'audit-upload',        poids: 12 },
  { nom: 'audit-qr',            poids: 12 },
  { nom: 'audit-exercice',      poids: 12 },
  { nom: 'audit-modeseg',       poids: 6 },
  { nom: 'audit-session-card',  poids: 5 },
  { nom: 'audit-budget',        poids: 5 },
  { nom: 'audit-verify-live',   poids: 5 },
  { nom: 'audit-retour',        poids: 4 },
  { nom: 'audit-verify',        poids: 4 },
  { nom: 'audit-stockage',      poids: 4 },
  { nom: 'audit-zoom-scroll',   poids: 3 },
  { nom: 'audit-consulter',     poids: 3 },
  { nom: 'audit-historique',    poids: 3 },
  { nom: 'audit-prompt',        poids: 1 },
];

const SCRIPTS = fileURLToPath(new URL('.', import.meta.url));
const RACINE = fileURLToPath(new URL('../', import.meta.url));
const ETAT_F = RACINE + '.audit-etat.json';
const moteur = (process.env.AC_ENGINE || 'chromium').toLowerCase();

/* ÉTAT ENTRE PASSES (.audit-etat.json, gitignoré) : { quand, moteur, rouges: [noms],
   vertComplet: bool, hash } — `hash` n'existe que posé par une passe COMPLÈTE verte. */
function lireEtat() { try { return JSON.parse(readFileSync(ETAT_F, 'utf8')); } catch { return null; } }
function ecrireEtat(e) { try { writeFileSync(ETAT_F, JSON.stringify(e, null, 1) + '\n'); } catch { /* un cache qui ne s'écrit pas ne casse rien */ } }

/* EMPREINTE DE L'ÉTAT AUDITÉ : tout ce qu'un harnais peut lire — les fichiers servables de la
   racine (l'app entière est un monofichier, mais sw.js, le manifeste et les icônes sont servis
   aussi), vendor/ (pdf.js, la police), et TOUS les scripts/*.mjs (harnais, socle, garde-fous :
   modifier un témoin invalide le vert qu'il avait produit). Trier avant de hacher — l'ordre de
   readdir n'est pas contractuel. */
function empreinte() {
  const h = createHash('sha256');
  const fichiers = [];
  for (const f of readdirSync(RACINE))
    if (/\.(html|js|webmanifest|svg|png|ico)$/.test(f)) fichiers.push(f);
  const walk = d => {
    for (const e of readdirSync(RACINE + d, { withFileTypes: true }))
      if (e.isDirectory()) walk(d + e.name + '/'); else fichiers.push(d + e.name);
  };
  walk('vendor/');
  for (const f of readdirSync(RACINE + 'scripts')) if (f.endsWith('.mjs')) fichiers.push('scripts/' + f);
  fichiers.sort();
  for (const f of fichiers) { h.update(f + '\0'); h.update(readFileSync(RACINE + f)); h.update('\0'); }
  h.update('moteur=' + moteur);
  return h.digest('hex');
}

/* Ciblage : `npm run audit -- partage qr` (préfixe `audit-` facultatif), `--rouges`, `--force`.
   Un nom qui ne correspond à RIEN échoue : une faute de frappe qui retomberait sur « rien à
   faire » produirait une passe vide et verte, c'est-à-dire un mensonge. */
const brut = process.argv.slice(2);
const drapeaux = new Set(brut.filter(a => a.startsWith('--')));
const demandes = brut.filter(a => !a.startsWith('-'));
for (const d of drapeaux) if (!['--rouges', '--force'].includes(d)) {
  console.error(`✗ drapeau inconnu : ${d} (connus : --rouges, --force)`); process.exit(1);
}
if (drapeaux.has('--rouges') && demandes.length) {
  console.error('✗ --rouges ne se combine pas avec des noms de harnais.'); process.exit(1);
}

let liste = HARNAIS;
if (drapeaux.has('--rouges')) {
  const etat = lireEtat();
  const rouges = etat?.rouges || [];
  if (!rouges.length) {
    console.log('✓ --rouges : aucun harnais rouge enregistré par la dernière passe — rien à rejouer.');
    process.exit(0);
  }
  liste = HARNAIS.filter(h => rouges.includes(h.nom));
} else if (demandes.length) {
  const inconnus = [];
  const retenus = new Set();
  for (const d of demandes) {
    const nom = d.startsWith('audit-') ? d : `audit-${d}`;
    const h = HARNAIS.find(x => x.nom === nom);
    if (h) retenus.add(h); else inconnus.push(d);
  }
  if (inconnus.length) {
    console.error(`✗ harnais inconnu(s) : ${inconnus.join(', ')}`);
    console.error(`  Noms valides : ${HARNAIS.map(h => h.nom.replace(/^audit-/, '')).join(' · ')}`);
    process.exit(1);
  }
  liste = HARNAIS.filter(h => retenus.has(h)); // ordre lourd-d'abord conservé
}
const partiel = liste.length < HARNAIS.length;

/* CACHE DE PASSE VERTE — passe complète seulement, et jamais sous --force. */
let hachage = null;
if (!partiel) {
  hachage = empreinte();
  const etat = lireEtat();
  if (!drapeaux.has('--force') && etat?.vertComplet && etat.hash === hachage && etat.moteur === moteur) {
    console.log(`✓ Passe complète DÉJÀ VERTE sur cet état exact (${etat.quand}, moteur ${moteur}) —`);
    console.log('  aucun fichier servable, vendorisé ni script d\'audit n\'a changé depuis.');
    console.log('  `npm run audit -- --force` pour rejouer malgré tout.');
    process.exit(0);
  }
}

/* EXPANSION EN TÂCHES : un harnais à `tranches` devient n processus `--shard k/n`, chacun ~1/n du
   poids — le tri lourd-d'abord se fait sur les TÂCHES, pour que le pool les empile au mieux. */
const taches = [];
for (const h of liste) {
  if (h.tranches) for (let k = 1; k <= h.tranches; k++)
    taches.push({ nom: h.nom, label: `${h.nom} ${k}/${h.tranches}`, args: ['--shard', `${k}/${h.tranches}`], poids: h.poids / h.tranches });
  else taches.push({ nom: h.nom, label: h.nom, args: [], poids: h.poids });
}
taches.sort((a, b) => b.poids - a.poids);

/* Pool adaptatif : 4 au plus, et jamais tous les cœurs — sur un runner CI à 4 vCPU, quatre
   navigateurs affameraient les sondes à délais (un rouge de charge n'est pas un rouge). */
const defJobs = Math.max(1, Math.min(4, availableParallelism() - 1));
const JOBS = Math.max(1, parseInt(process.env.AC_JOBS || String(defJobs), 10) || defJobs);

if (partiel) {
  console.log(`⚠ PASSE PARTIELLE — ${liste.length}/${HARNAIS.length} harnais (${liste.map(h => h.nom.replace(/^audit-/, '')).join(', ')}).`);
  console.log('  Un vert partiel ne vaut PAS la suite : « avant chaque commit », npm run audit sans argument.');
}
console.log(`Audit ${partiel ? 'partiel' : 'complet'} — ${liste.length} harnais (${taches.length} tâches), pool ${JOBS}, moteur ${moteur}.\n`);

/* Une tâche = un processus enfant, sortie CAPTURÉE (stdout+stderr mêlés dans l'ordre d'arrivée).
   En vert on n'affiche que sa dernière ligne (le « ✓ … » que chaque harnais imprime) ; en rouge,
   la sortie ENTIÈRE est rejouée dans le rapport final — c'est le rapport agrégé qui remplace le
   fail-fast : une passe montre TOUS les rouges, pas le premier. */
function lancer(t) {
  return new Promise(res => {
    const t0 = Date.now();
    const p = spawn(process.execPath, [SCRIPTS + t.nom + '.mjs', ...t.args], { env: process.env });
    let sortie = '';
    p.stdout.on('data', d => { sortie += d; });
    p.stderr.on('data', d => { sortie += d; });
    p.on('close', code => {
      const s = ((Date.now() - t0) / 1000).toFixed(1);
      const lignes = sortie.trimEnd().split('\n');
      const derniere = lignes[lignes.length - 1] || '';
      console.log(`${code === 0 ? '✓' : '✗'} ${t.label.padEnd(24)} ${String(s).padStart(6)}s  ${code === 0 ? derniere : `ÉCHEC (code ${code})`}`);
      res({ ...t, code, s, sortie });
    });
    p.on('error', e => {
      console.log(`✗ ${t.label.padEnd(24)} — lancement impossible : ${e.message}`);
      res({ ...t, code: 127, s: '0', sortie: String(e.message) });
    });
  });
}

/* Pool : on pioche dans la file (déjà triée lourd-d'abord) dès qu'un slot se libère. */
const file = [...taches];
const resultats = [];
const t0 = Date.now();
await Promise.all(Array.from({ length: Math.min(JOBS, file.length) }, async () => {
  while (file.length) resultats.push(await lancer(file.shift()));
}));

const total = ((Date.now() - t0) / 1000).toFixed(1);

/* VÉRIFICATION DES TRANCHES : la somme des `##SEC joues=` d'un harnais découpé doit couvrir son
   `total=` (identique d'une tranche à l'autre — c'est le même fichier). Un écart = tâche ROUGE
   fabriquée : une passe qui perd des sections en silence est exactement ce que ce lanceur
   existe pour empêcher. */
const parHarnais = new Map();
for (const r of resultats) {
  if (!parHarnais.has(r.nom)) parHarnais.set(r.nom, []);
  parHarnais.get(r.nom).push(r);
}
for (const [nom, runs] of parHarnais) {
  const h = HARNAIS.find(x => x.nom === nom);
  if (!h?.tranches || runs.some(r => r.code !== 0)) continue; // un rouge se voit déjà
  let joues = 0, totalSec = null, sans = false;
  for (const r of runs) {
    const m = /##SEC joues=(\d+) total=(\d+)/.exec(r.sortie);
    if (!m) { sans = true; break; }
    joues += +m[1];
    if (totalSec === null) totalSec = +m[2];
    else if (totalSec !== +m[2]) { sans = true; break; }
  }
  if (sans || joues !== totalSec) {
    console.log(`✗ ${nom} : tranches incohérentes (${sans ? 'ligne ##SEC absente ou totaux divergents' : `${joues} sections jouées pour ${totalSec} attendues`}) — troncature possible.`);
    runs.forEach(r => { r.code = r.code || 1; });
  }
}

const rouges = resultats.filter(r => r.code !== 0);
const nomsRouges = [...new Set(rouges.map(r => r.nom))];

if (rouges.length) {
  console.log(`\n════ ${rouges.length} tâche(s) en échec — sorties complètes ════`);
  for (const r of rouges) {
    console.log(`\n──── ${r.label} (code ${r.code}) ────`);
    console.log(r.sortie.trimEnd());
  }
}

/* Mise à jour de l'état : une passe COMPLÈTE fait autorité sur `rouges` ; une passe partielle ne
   corrige que ce qu'elle a rejoué (un harnais redevenu vert en sort, un rouge y entre). */
{
  const etat = lireEtat() || {};
  const avant = new Set(etat.rouges || []);
  for (const h of liste) avant.delete(h.nom);
  for (const n of nomsRouges) avant.add(n);
  const e = { quand: new Date().toISOString(), moteur, rouges: [...avant] };
  if (!partiel && !rouges.length) { e.vertComplet = true; e.hash = hachage; }
  ecrireEtat(e);
}

console.log(`\n${rouges.length ? '✗' : '✓'} ${resultats.length - rouges.length}/${resultats.length} tâches vertes (${liste.length} harnais) en ${total}s${partiel ? ' — PASSE PARTIELLE (la passe complète reste due avant commit)' : ''}.`);
process.exit(rouges.length ? 1 : 0);
