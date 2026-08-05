/* VIEW TRANSITIONS — aucune transition annulée ne rejette dans le vide.
 *
 * POURQUOI CE HARNAIS EXISTE, ALORS QU'`audit-retour` FAIT DÉJÀ UN TRIPLE TAP : parce qu'il ne
 * l'attrapait que PAR INTERMITTENCE — 18/19 puis 19/19 sur un code identique, selon la charge de
 * la passe parallèle. C'est la pire forme de rouge : celle qu'on finit par mettre sur le compte
 * du hasard. Ici les trois clics sont SYNCHRONES, donc les transitions se chevauchent à tous les
 * coups et le contrôle est déterministe.
 *
 * CE QU'IL MESURE : les rejets NON GÉRÉS, pas un symptôme. Un rouge dit qu'il s'est passé quelque
 * chose ; un rejet capté dit QUOI.
 *
 * (Historique — mécanisme, et antériorité.
   `vtWrap` appelle `document.startViewTransition(...)` sans jamais tenir la promesse renvoyée.
   Quand une seconde transition démarre avant la fin de la première, le moteur ANNULE la première
   et rejette ses promesses — un rejet NON GÉRÉ, que le `try/catch` de `vtWrap` ne peut pas
   rattraper (il est synchrone). Le harnais `audit-retour` fait un « triple tap nerveux » sur le
   retour : c'est exactement le scénario.
   Défaut PRÉEXISTANT, mesuré sur v5.1.2 pur : 3 clics = 2 rejets sur les deux moteurs.) */
import { serveApp, moteur, NOM_MOTEUR, amorce, ouvrirFiche } from './harness.mjs';

const { port, srv } = await serveApp();
const nav = await moteur().launch();
const page = await (await nav.newContext()).newPage();

const rejets = [];
page.on('pageerror', e => rejets.push(String(e.message || e)));

await page.goto(`http://127.0.0.1:${port}/index.html`);
await page.waitForFunction(() => !document.querySelector('.boot-load'), null, { timeout: 15000 });
await amorce(page);
await ouvrirFiche(page, /anaphylaxie/);

// Le triple tap nerveux, sans attendre entre les taps : trois transitions en rafale.
await page.evaluate(() => {
  const b = document.getElementById('hdrBack');
  if (b) { b.click(); b.click(); b.click(); }
});
await page.waitForTimeout(1200);

const vt = await page.evaluate(() => !!document.startViewTransition);
await nav.close(); srv.close();

if (!vt) { console.log(`[${NOM_MOTEUR}] ⚠ startViewTransition absent de ce moteur — sonde sans objet.`); process.exit(0); }
if (rejets.length) {
  console.error(`✗ ${rejets.length} rejet(s) non géré(s) :`);
  for (const r of rejets) console.error('   • ' + r);
  process.exit(1);
}
console.log(`[${NOM_MOTEUR}] ✓ view transitions : 1/1 — trois transitions en rafale, aucun rejet non géré.`);
