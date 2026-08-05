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
 * toujours lancer seul (`node scripts/audit-doctrine.mjs`). Les dix-sept sont indépendants par
 * construction (chacun son serveur sur port libre via `serveApp`, son navigateur ; seul audit-qr
 * écrit sur disque, dans un mkdtemp unique) : les jouer en concurrence ne change aucun verdict.
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
 * que AC_ENGINE dans harness.mjs).
 *
 * AC_ENGINE est transmis tel quel aux enfants (héritage d'environnement) :
 *     AC_ENGINE=webkit npm run audit            → les dix-sept sur WebKit
 *     npm run audit -- doctrine                 → un seul harnais, passe PARTIELLE
 *     AC_JOBS=2 npm run audit                   → pool réduit (machine chargée)
 */
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { availableParallelism } from 'node:os';

/* LISTE EXACTE des harnais — la source de vérité, ex-chaîne du script `audit` de package.json
   (AGENTS.md y renvoie). Le poids est la durée MESURÉE en secondes (2026-08, Chromium, M-series) :
   il ne sert qu'à ordonner lourd-d'abord, une dérive ne fausse aucun verdict. */
const HARNAIS = [
  { nom: 'audit-doctrine',      poids: 215 },
  { nom: 'audit-a11y',          poids: 135 },
  { nom: 'audit-partage',       poids: 89 },
  { nom: 'audit-k5',            poids: 67 },
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

/* Ciblage : `npm run audit -- partage qr` (le préfixe `audit-` est facultatif). Un nom qui ne
   correspond à RIEN échoue : une faute de frappe qui retomberait sur « rien à faire » produirait
   une passe vide et verte, c'est-à-dire un mensonge. */
const demandes = process.argv.slice(2).filter(a => !a.startsWith('-'));
let liste = HARNAIS;
if (demandes.length) {
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

/* Pool adaptatif : 4 au plus, et jamais tous les cœurs — sur un runner CI à 4 vCPU, quatre
   navigateurs affameraient les sondes à délais (un rouge de charge n'est pas un rouge). */
const defJobs = Math.max(1, Math.min(4, availableParallelism() - 1));
const JOBS = Math.max(1, parseInt(process.env.AC_JOBS || String(defJobs), 10) || defJobs);
const moteur = (process.env.AC_ENGINE || 'chromium').toLowerCase();

if (partiel) {
  console.log(`⚠ PASSE PARTIELLE — ${liste.length}/${HARNAIS.length} harnais (${liste.map(h => h.nom.replace(/^audit-/, '')).join(', ')}).`);
  console.log('  Un vert partiel ne vaut PAS la suite : « avant chaque commit », npm run audit sans argument.');
}
console.log(`Audit ${partiel ? 'partiel' : 'complet'} — ${liste.length} harnais, pool ${JOBS}, moteur ${moteur}.\n`);

/* Un harnais = un processus enfant, sortie CAPTURÉE (stdout+stderr mêlés dans l'ordre d'arrivée).
   En vert on n'affiche que sa dernière ligne (le « ✓ … » que chaque harnais imprime) ; en rouge,
   la sortie ENTIÈRE est rejouée dans le rapport final — c'est le rapport agrégé qui remplace le
   fail-fast : une passe montre TOUS les rouges, pas le premier. */
function lancer(h) {
  return new Promise(res => {
    const t0 = Date.now();
    const p = spawn(process.execPath, [SCRIPTS + h.nom + '.mjs'], { env: process.env });
    let sortie = '';
    p.stdout.on('data', d => { sortie += d; });
    p.stderr.on('data', d => { sortie += d; });
    p.on('close', code => {
      const s = ((Date.now() - t0) / 1000).toFixed(1);
      const lignes = sortie.trimEnd().split('\n');
      const derniere = lignes[lignes.length - 1] || '';
      console.log(`${code === 0 ? '✓' : '✗'} ${h.nom.padEnd(20)} ${String(s).padStart(6)}s  ${code === 0 ? derniere : `ÉCHEC (code ${code})`}`);
      res({ ...h, code, s, sortie });
    });
    p.on('error', e => {
      console.log(`✗ ${h.nom.padEnd(20)} — lancement impossible : ${e.message}`);
      res({ ...h, code: 127, s: '0', sortie: String(e.message) });
    });
  });
}

/* Pool : on pioche dans la file (déjà triée lourd-d'abord) dès qu'un slot se libère. */
const file = [...liste];
const resultats = [];
const t0 = Date.now();
await Promise.all(Array.from({ length: Math.min(JOBS, file.length) }, async () => {
  while (file.length) resultats.push(await lancer(file.shift()));
}));

const total = ((Date.now() - t0) / 1000).toFixed(1);
const rouges = resultats.filter(r => r.code !== 0);

if (rouges.length) {
  console.log(`\n════ ${rouges.length} harnais en échec — sorties complètes ════`);
  for (const r of rouges) {
    console.log(`\n──── ${r.nom} (code ${r.code}) ────`);
    console.log(r.sortie.trimEnd());
  }
}

console.log(`\n${rouges.length ? '✗' : '✓'} ${resultats.length - rouges.length}/${resultats.length} harnais verts en ${total}s${partiel ? ' — PASSE PARTIELLE (la passe complète reste due avant commit)' : ''}.`);
process.exit(rouges.length ? 1 : 0);
