#!/usr/bin/env node
/* AUDIT — STOCKAGE LOCAL : une connexion IndexedDB FERMÉE se reprend-elle ? (v5.0.10)
 *
 * POURQUOI CE HARNAIS EXISTE. Le stockage local est la fonction dont tout dépend en intervention,
 * et c'était le seul point du dossier où une fonction critique n'était mesurée que par ses parties
 * PURES : `npm run check` lit du texte, `npm test` charge `index.html?__actest` — qui n'amorce pas
 * l'application, donc n'ouvre AUCUNE base réelle. Le défaut signalé à l'usage (« The database
 * connection is closing », remonté jusqu'à la fenêtre de synchro en « Erreur inattendue ») vivait
 * exactement dans cet angle mort : les deux garde-fous étaient verts pendant que la synchro
 * échouait sur un appareil.
 *
 * CE QU'IL MESURE, et qu'aucun autre ne peut voir : une connexion se ferme SANS que l'application
 * le demande (un autre onglet qui migre ou efface la base — `onversionchange` la libère alors —,
 * une page qui commence à se recharger, un moteur mobile qui la reprend en arrière-plan). On coupe
 * donc la connexion SOUS l'application, exactement comme le moteur le ferait, et l'on vérifie que
 * l'appel suivant RÉUSSIT — lecture comme écriture groupée (le pull de synchro passe par
 * `applyRows`) — au lieu de lever.
 *
 * ⚠ PIÈGE DE SPEC, appris en écrivant la sonde : l'événement `close` ne se déclenche PAS sur un
 * `close()` explicite (il est réservé aux fermetures ANORMALES). Un harnais qui attendrait cette
 * notification mesurerait le moteur, pas l'application — c'est `_try` qui lâche le handle au
 * premier appel qui échoue, et l'écouteur `versionchange` qui couvre le chemin « autre onglet ».
 */
import { serveApp, moteur, amorce } from './harness.mjs';

const { port, srv } = await serveApp();
const br = await moteur().launch();
const page = await (await br.newContext()).newPage();
let ok = 0, ko = 0;
const t = (nom, cond, det) => { if (cond) { ok++; console.log('  ✓ ' + nom); }
  else { ko++; console.log('  ✗ ' + nom + (det ? '\n      ' + det : '')); } };

await page.goto(`http://localhost:${port}/index.html`);
await amorce(page);

const r = await page.evaluate(async () => {
  const out = { backend: window.Data === window.IDB };
  out.n0 = (await Data.getAll()).length;
  // 1. Fermeture SUBIE, sans notification (moteur mobile, page qui s'en va).
  IDB.db.close();
  try { out.n1 = (await Data.getAll()).length; out.err = null; }
  catch (e) { out.n1 = -1; out.err = String(e && e.message); }
  out.rouverte = !!IDB.db && IDB.db !== null;
  try { await Data.applyRows('fiches', [], []); out.wErr = null; } catch (e) { out.wErr = String(e && e.message); }
  // 2. Chemin « un autre onglet migre ou efface la base » : openSpaceDb ferme la connexion sur
  //    `versionchange` — le handle doit être lâché DANS LA FOULÉE, sans attendre un appel raté.
  IDB.db.dispatchEvent(new Event('versionchange'));
  out.vcLache = IDB.db === null;
  try { out.n2 = (await Data.getAll()).length; out.vErr = null; } catch (e) { out.n2 = -1; out.vErr = String(e && e.message); }
  // 3. SCELLÉ (effacement en cours) : là, on ne rouvre PAS — rouvrir recréerait la base qu'on
  //    efface. L'erreur doit remonter, pas être avalée.
  IDB.sealed = true; IDB.db = null;
  let sErr = null; try { await Data.getAll(); } catch (e) { sErr = String(e && e.message); }
  out.scelle = sErr !== null;
  IDB.sealed = false;
  return out;
});

// Un contrôle qui ne rencontre pas son cas ne couvre rien : sans IndexedDB ni fiches, tout le reste
// mesurerait le vide.
t('le backend retenu est bien IndexedDB', r.backend, 'repli KV : rien de ce qui suit ne mesure quoi que ce soit');
t('des fiches sont présentes avant la coupure', r.n0 > 0, 'n0=' + r.n0);
t('après une fermeture subie, la lecture RÉUSSIT au lieu de lever', r.err === null, r.err);
t('… et rend exactement les mêmes fiches', r.n1 === r.n0, r.n1 + ' au lieu de ' + r.n0);
t('… la connexion a bien été rouverte', r.rouverte, 'IDB.db resté null');
t('une écriture groupée (pull de synchro) passe aussi', r.wErr === null, r.wErr);
t('versionchange (autre onglet) lâche le handle DANS LA FOULÉE', r.vcLache, 'IDB.db toujours posé');
t('… et la lecture suivante réussit encore', r.vErr === null && r.n2 === r.n0, r.vErr || ('n2=' + r.n2));
t('une base SCELLÉE (effacement en cours) n’est jamais rouverte', r.scelle, 'la base a été recréée sous un effacement');

await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles stockage OK`);
process.exit(ko ? 1 : 0);
