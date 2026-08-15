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
 * REJOUER LES ROUGES (`npm run audit -- --rouges`, v5.4.4 ; PAR SECTION depuis v5.10.5) : chaque
 * passe écrit dans `.audit-etat.json` (racine, gitignoré) la liste des harnais en échec — et,
 * pour les harnais à sections (doctrine, partage), les NOMS des sections rouges, lus dans la
 * sortie capturée (en-têtes `══ nom ══` de secRunner + lignes `✗`). `--rouges` rejoue alors ces
 * seules sections par `--grep` (motif ancré sur les noms exacts, échappés) : la confirmation d'un
 * correctif tombe de ~2 min (harnais entier, 4 tranches) à quelques secondes. Toujours annoncé
 * PARTIELLE. TROIS GARDE-FOUS : (1) l'attribution n'est tentée que si le harnais a TERMINÉ
 * normalement (ligne `##SEC` présente) — un crash mid-course rend l'attribution non fiable, et on
 * retombe sur le harnais ENTIER plutôt que de rejouer trop peu ; (2) un `--grep` qui rejoue MOINS
 * de sections qu'attendu (section renommée depuis l'échec ?) est FORCÉ ROUGE — un vert obtenu en
 * rejouant 1 section sur 2 serait un mensonge ; (3) un rejeu par sections ne prouve JAMAIS le
 * harnais entier : il sort le harnais de la liste des rouges, mais n'écrit pas de vert dans le
 * cache — la passe complète le rejouera. Aucun rouge enregistré → il le dit et sort vert (ce
 * n'est pas un mensonge : rien n'était dû).
 *
 * CACHE VERT PAR HARNAIS (v5.4.4, affiné v5.10.5). Le cache de passe verte était TOUT-OU-RIEN :
 * un octet changé dans `audit-qr.mjs` invalidait le vert entier, et la passe finale rejouait
 * doctrine (217 s) qui n'avait pas bougé — la boucle « je corrige un témoin dans UN harnais → je
 * repaie les 20 » était exactement la douleur que le lanceur devait guérir. Le verdict d'un
 * harnais ne dépend que de : les fichiers servables de la racine, vendor/, le socle
 * (`harness.mjs`), le lanceur (`audit-run.mjs`), SON script (+ dépendances déclarées : audit-qr
 * compile `qr-decode.swift`), et le moteur. L'empreinte est donc PAR HARNAIS : socle commun
 * haché une fois, + le script propre. Une passe qui joue un harnais EN ENTIER (toutes tranches,
 * jamais un `--grep`) et le trouve vert enregistre son empreinte ; la passe COMPLÈTE suivante ne
 * rejoue que les harnais dont un intrant a changé, et LISTE les autres comme réutilisés — même
 * argument de sécurité que le cache d'origine (entrées identiques octet à octet → même verdict),
 * appliqué plus finement. Les `check-*.mjs` sont sciemment HORS empreinte : ils tournent dans
 * `npm run check`, ne sont lus par aucun harnais, et ne peuvent influencer aucun verdict d'audit
 * — les inclure fabriquait des repasses complètes fantômes. `--force` rejoue tout malgré tout.
 * Un rejeu par sections (`--rouges`) n'écrit jamais dans ce cache ; un ciblage par NOMS y écrit
 * (le harnais a tourné en entier) mais ne le CONSOMME pas — demander un harnais, c'est demander
 * de l'observer tourner.
 *
 * AC_ENGINE est transmis tel quel aux enfants (héritage d'environnement) :
 *     AC_ENGINE=webkit npm run audit            → tous les harnais sur WebKit
 *     npm run audit -- doctrine                 → un seul harnais (ses 4 tranches), PARTIELLE
 *     npm run audit -- --rouges                 → rouges de la dernière passe (sections si connues)
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
   lanceur le joue en n processus parallèles — réservé à ceux qui dominent le temps mural.
   `sections` : le harnais passe par secRunner (donc accepte `--grep` et imprime `══ nom ══`) —
   condition du rejeu par sections de `--rouges`. `deps` : fichiers HORS scripts/<nom>.mjs que le
   harnais lit ou exécute, à entrer dans son empreinte. */
const HARNAIS = [
  { nom: 'audit-doctrine',      poids: 217, tranches: 4, sections: true },
  { nom: 'audit-a11y',          poids: 128, tranches: 2 },
  { nom: 'audit-partage',       poids: 76,  tranches: 2, sections: true },
  { nom: 'audit-k5',            poids: 67 },
  { nom: 'audit-pdfsearch',     poids: 66 },
  { nom: 'audit-complications', poids: 13 },
  { nom: 'audit-upload',        poids: 12 },
  { nom: 'audit-qr',            poids: 12, deps: ['scripts/qr-decode.swift'] },
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

/* ÉTAT ENTRE PASSES (.audit-etat.json, gitignoré) :
     { quand, moteur, rouges: [noms],
       sections: { nom: [noms de sections rouges] },      ← harnais à secRunner seulement
       verts:    { nom: { hash, quand } } }               ← empreinte du dernier vert ENTIER
   Un fichier d'ancien format (vertComplet/hash globaux) est lu sans erreur : `verts` absent =
   aucun vert réutilisable, tout se rejoue une fois — migration silencieuse et sûre. */
function lireEtat() { try { return JSON.parse(readFileSync(ETAT_F, 'utf8')); } catch { return null; } }
function ecrireEtat(e) { try { writeFileSync(ETAT_F, JSON.stringify(e, null, 1) + '\n'); } catch { /* un cache qui ne s'écrit pas ne casse rien */ } }

/* EMPREINTES PAR HARNAIS. Socle commun : les fichiers servables de la racine (l'app entière est
   un monofichier, mais sw.js, le manifeste et les icônes sont servis aussi), vendor/ (pdf.js, la
   police), `harness.mjs` (le socle que tous importent), CE lanceur, et le moteur. Puis, par
   harnais : son script + ses `deps`. Trier avant de hacher — l'ordre de readdir n'est pas
   contractuel. Les autres scripts/*.mjs (check-*, csp-hashes…) sont HORS empreinte À DESSEIN :
   aucun harnais ne les lit, ils ne peuvent changer aucun verdict d'audit. */
function empreintes() {
  const socle = createHash('sha256');
  const fichiers = [];
  for (const f of readdirSync(RACINE))
    if (/\.(html|js|webmanifest|svg|png|ico)$/.test(f)) fichiers.push(f);
  const walk = d => {
    for (const e of readdirSync(RACINE + d, { withFileTypes: true }))
      if (e.isDirectory()) walk(d + e.name + '/'); else fichiers.push(d + e.name);
  };
  walk('vendor/');
  fichiers.push('scripts/harness.mjs', 'scripts/audit-run.mjs');
  fichiers.sort();
  for (const f of fichiers) { socle.update(f + '\0'); socle.update(readFileSync(RACINE + f)); socle.update('\0'); }
  socle.update('moteur=' + moteur);
  const base = socle.digest('hex');
  const map = {};
  for (const h of HARNAIS) {
    const hh = createHash('sha256');
    hh.update(base);
    for (const f of [`scripts/${h.nom}.mjs`, ...(h.deps || [])]) {
      hh.update(f + '\0'); hh.update(readFileSync(RACINE + f)); hh.update('\0');
    }
    map[h.nom] = hh.digest('hex');
  }
  return map;
}

/* ATTRIBUER LES ÉCHECS À LEURS SECTIONS, depuis la sortie capturée d'un harnais à secRunner :
   en-tête `══ nom ══`, échec = ligne `✗` (préfixe d'indentation variable). Rend null — c'est-à-
   dire « rejouer le harnais ENTIER » — dès que l'attribution n'est pas fiable : un `✗` AVANT la
   première section, aucune section identifiée, ou sortie SANS ligne `##SEC` (le harnais n'a pas
   atteint son bilan : crash mid-course, sections suivantes jamais jouées — en rejouer une seule
   serait rejouer trop peu). */
function sectionsRouges(sortie) {
  if (!/##SEC joues=/.test(sortie)) return null;
  let cur = null, horsSection = false;
  const rouges = new Set();
  for (const l of sortie.split('\n')) {
    const m = /^══ (.+) ══$/.exec(l);
    if (m) { cur = m[1]; continue; }
    if (/^\s*✗/.test(l)) { if (cur) rouges.add(cur); else horsSection = true; }
  }
  if (horsSection || !rouges.size) return null;
  return [...rouges];
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

const etatPrec = lireEtat() || {};
let liste = HARNAIS;
let modeRouges = false;
if (drapeaux.has('--rouges')) {
  const rouges = etatPrec.rouges || [];
  if (!rouges.length) {
    console.log('✓ --rouges : aucun harnais rouge enregistré par la dernière passe — rien à rejouer.');
    process.exit(0);
  }
  liste = HARNAIS.filter(h => rouges.includes(h.nom));
  modeRouges = true;
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
/* `--rouges` est TOUJOURS une passe partielle, même si tous les harnais étaient rouges : un rejeu
   par sections ne couvre pas les harnais entiers, et un vert `--rouges` ne vaut jamais la porte
   de commit. */
const partiel = modeRouges || liste.length < HARNAIS.length;

const EMP = empreintes();

/* CACHE VERT PAR HARNAIS — consommé par la passe COMPLÈTE seulement, et jamais sous --force :
   un harnais dont l'empreinte n'a pas changé depuis son dernier vert ENTIER est prouvé vert sur
   les octets courants, il est listé « réutilisé » au lieu d'être rejoué. */
let reutilises = [];
let aJouer = liste;
if (!partiel && !drapeaux.has('--force')) {
  const verts = etatPrec.verts || {};
  reutilises = liste.filter(h => verts[h.nom]?.hash === EMP[h.nom]);
  aJouer = liste.filter(h => !reutilises.includes(h));
  if (!aJouer.length) {
    console.log(`✓ Passe complète DÉJÀ VERTE sur cet état exact (moteur ${moteur}) — les ${HARNAIS.length} harnais`);
    console.log('  ont un vert enregistré sur les octets courants (servables, vendor, socle, leur script).');
    console.log('  `npm run audit -- --force` pour rejouer malgré tout.');
    process.exit(0);
  }
}

/* EXPANSION EN TÂCHES : un harnais à `tranches` devient n processus `--shard k/n`, chacun ~1/n du
   poids — le tri lourd-d'abord se fait sur les TÂCHES, pour que le pool les empile au mieux.
   Sous --rouges, un harnais à sections dont les sections rouges sont CONNUES devient UN processus
   `--grep` sur leurs noms exacts (ancrés, échappés) ; `grep` porte le nombre de sections
   attendues, vérifié au retour. */
const taches = [];
for (const h of aJouer) {
  const secs = modeRouges && h.sections ? (etatPrec.sections || {})[h.nom] : null;
  if (secs?.length) {
    const motif = '^(?:' + secs.map(s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|') + ')$';
    taches.push({ nom: h.nom, label: `${h.nom} --grep ×${secs.length}`, args: ['--grep', motif], poids: 6 * secs.length, grep: secs.length });
  } else if (h.tranches) {
    for (let k = 1; k <= h.tranches; k++)
      taches.push({ nom: h.nom, label: `${h.nom} ${k}/${h.tranches}`, args: ['--shard', `${k}/${h.tranches}`], poids: h.poids / h.tranches });
  } else taches.push({ nom: h.nom, label: h.nom, args: [], poids: h.poids });
}
taches.sort((a, b) => b.poids - a.poids);

/* Pool adaptatif : 4 au plus, et jamais tous les cœurs — sur un runner CI à 4 vCPU, quatre
   navigateurs affameraient les sondes à délais (un rouge de charge n'est pas un rouge). */
const defJobs = Math.max(1, Math.min(4, availableParallelism() - 1));
const JOBS = Math.max(1, parseInt(process.env.AC_JOBS || String(defJobs), 10) || defJobs);

if (partiel) {
  console.log(`⚠ PASSE PARTIELLE — ${liste.length}/${HARNAIS.length} harnais (${liste.map(h => h.nom.replace(/^audit-/, '')).join(', ')})${modeRouges ? ', mode --rouges' : ''}.`);
  console.log('  Un vert partiel ne vaut PAS la suite : « avant chaque commit », npm run audit sans argument.');
}
if (reutilises.length) {
  console.log(`≡ ${reutilises.length} harnais réutilisés — vert déjà prouvé sur ces octets exacts :`);
  console.log('  ' + reutilises.map(h => h.nom.replace(/^audit-/, '')).join(' · '));
}
console.log(`Audit ${partiel ? 'partiel' : 'complet'} — ${aJouer.length} harnais à jouer (${taches.length} tâches), pool ${JOBS}, moteur ${moteur}.\n`);

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

/* GARDE-FOU DU REJEU PAR SECTIONS : un `--grep` vert doit avoir joué EXACTEMENT le nombre de
   sections attendues. Moins (section renommée depuis l'échec ? zéro est déjà un échec bruyant de
   secRunner) = vert FABRIQUÉ sur une couverture amputée → forcé rouge. */
for (const r of resultats) {
  if (!r.grep || r.code !== 0) continue;
  const m = /##SEC joues=(\d+)/.exec(r.sortie);
  if (!m || +m[1] !== r.grep) {
    console.log(`✗ ${r.label} : ${m ? m[1] : 0} section(s) rejouée(s) pour ${r.grep} attendue(s) — section renommée depuis l'échec ?` +
      ` Rejouer le harnais entier : npm run audit -- ${r.nom.replace(/^audit-/, '')}`);
    r.code = 1;
  }
}

/* VÉRIFICATION DES TRANCHES : la somme des `##SEC joues=` d'un harnais découpé doit couvrir son
   `total=` (identique d'une tranche à l'autre — c'est le même fichier). Un écart = tâche ROUGE
   fabriquée : une passe qui perd des sections en silence est exactement ce que ce lanceur
   existe pour empêcher. Sans objet pour un rejeu `--grep` (partiel par définition, gardé
   ci-dessus par le compte de sections attendues). */
const parHarnais = new Map();
for (const r of resultats) {
  if (!parHarnais.has(r.nom)) parHarnais.set(r.nom, []);
  parHarnais.get(r.nom).push(r);
}
for (const [nom, runs] of parHarnais) {
  const h = HARNAIS.find(x => x.nom === nom);
  if (!h?.tranches || runs.some(r => r.grep) || runs.some(r => r.code !== 0)) continue; // un rouge se voit déjà
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

if (rouges.length) {
  console.log(`\n════ ${rouges.length} tâche(s) en échec — sorties complètes ════`);
  for (const r of rouges) {
    console.log(`\n──── ${r.label} (code ${r.code}) ────`);
    console.log(r.sortie.trimEnd());
  }
}

/* Mise à jour de l'état. Par harnais ADRESSÉ par cette passe (joué ou réutilisé) :
   vert entier → sort des rouges, empreinte enregistrée dans `verts` ; vert par `--grep` → sort
   des rouges mais N'ENTRE PAS dans `verts` (seules ses sections rouges ont été rejouées) ;
   rouge → entre dans les rouges, sort de `verts`, et ses sections rouges sont enregistrées si
   l'attribution est fiable (sinon on efface : le prochain --rouges rejouera le harnais entier).
   Un harnais non adressé garde son état. */
{
  const etat = lireEtat() || {};
  const rougesEtat = new Set(etat.rouges || []);
  const sectionsEtat = { ...(etat.sections || {}) };
  const vertsEtat = { ...(etat.verts || {}) };
  const quand = new Date().toISOString();
  for (const h of liste) {
    const runs = parHarnais.get(h.nom);
    if (!runs) { // réutilisé : vert prouvé par empreinte, rien d'autre à changer
      rougesEtat.delete(h.nom); delete sectionsEtat[h.nom];
      continue;
    }
    const rouge = runs.some(r => r.code !== 0);
    const parGrep = runs.some(r => r.grep);
    if (!rouge) {
      rougesEtat.delete(h.nom); delete sectionsEtat[h.nom];
      if (!parGrep) vertsEtat[h.nom] = { hash: EMP[h.nom], quand };
    } else {
      rougesEtat.add(h.nom); delete vertsEtat[h.nom];
      if (h.sections) {
        const secs = new Set();
        let fiable = true;
        for (const r of runs) {
          if (r.code === 0) continue;
          const s = sectionsRouges(r.sortie);
          if (!s) { fiable = false; break; }
          s.forEach(x => secs.add(x));
        }
        if (fiable && secs.size) sectionsEtat[h.nom] = [...secs];
        else delete sectionsEtat[h.nom];
      }
    }
  }
  ecrireEtat({ quand, moteur, rouges: [...rougesEtat], sections: sectionsEtat, verts: vertsEtat });
}

console.log(`\n${rouges.length ? '✗' : '✓'} ${resultats.length - rouges.length}/${resultats.length} tâches vertes (${aJouer.length} harnais joués${reutilises.length ? `, ${reutilises.length} réutilisés` : ''}) en ${total}s${partiel ? ' — PASSE PARTIELLE (la passe complète reste due avant commit)' : ''}.`);
process.exit(rouges.length ? 1 : 0);
