/* WAKE LOCK — l'écran ne s'éteint pas pendant un soin (lot 1 du portage natif).
 *
 * POURQUOI CE HARNAIS EXISTE. L'application n'a eu aucun wake lock jusqu'à la v5.1.2 : en pleine
 * réanimation guidée, l'écran s'éteignait au bout du délai système et il fallait le rallumer d'une
 * main déjà prise. Le comportement est désormais là, et il n'a AUCUN autre témoin : ni `npm test`
 * (qui ne rend rien) ni les autres harnais ne regardent `_wake`. Sans ce fichier, un
 * réordonnancement de `tickAll` ou un déplacement du site d'obtention le casserait en silence.
 *
 * CE QU'IL MESURE : la LOGIQUE des deux sites d'appel — obtention sur `click` (après les
 * gestionnaires de l'application, donc la crise est déjà à l'écran), libération et reprise par le
 * réconciliateur de `tickAll`. L'OBTENTION RÉELLE sur WKWebView iOS est mesurée ailleurs et une
 * fois pour toutes (`native/probe/README.md`) : accordée après un geste, refusée sans.
 *
 * ⚠ IL PEUT NE RIEN MESURER, ET IL LE DIT : un moteur sans `navigator.wakeLock` fait sortir le
 * harnais en vert avec un avertissement plutôt qu'en faux positif silencieux.
 */
import { serveApp, moteur, NOM_MOTEUR, amorce, ouvrirFiche, demarrerSession } from './harness.mjs';

const { port, srv } = await serveApp();
const nav = await moteur().launch();
const ctx = await nav.newContext();
try { await ctx.grantPermissions(['screen-wake-lock']); } catch (e) { /* WebKit ne connaît pas ce nom */ }
const page = await ctx.newPage();
await page.goto(`http://127.0.0.1:${port}/index.html`);
await page.waitForFunction(() => !document.querySelector('.boot-load'), null, { timeout: 15000 });

const dispo = await page.evaluate(() => !!navigator.wakeLock);
if (!dispo) { console.log(`[${NOM_MOTEUR}] ⚠ API wakeLock absente de ce moteur — sonde sans objet.`); await nav.close(); srv.close(); process.exit(0); }

const fautes = [];
const veut = (nom, cond, vu) => { if (!cond) fautes.push(`${nom} — vu : ${JSON.stringify(vu)}`); };
const tenu = () => page.evaluate(() => ({ wake: !!_wake, crise: crisisOnScreen() }));

await amorce(page);
await ouvrirFiche(page, /anaphylaxie/);
let s = await tenu();
veut('1. fiche ouverte, session NON démarrée : aucun verrou', !s.wake && !s.crise, s);

await demarrerSession(page);
await page.waitForTimeout(600);
s = await tenu();
veut('2. session démarrée : crise à l’écran ET verrou tenu', s.crise && s.wake, s);

// Retour à la bibliothèque : la crise quitte l'écran, le verrou doit être RENDU par tickAll.
await page.evaluate(() => document.getElementById('hdrBack').click());
await page.waitForTimeout(1200);
s = await tenu();
veut('3. retour bibliothèque : verrou rendu', !s.wake && !s.crise, s);

/* 4. On y revient : le verrou se reprend, la session étant toujours vive.
      ⚠ `ouvrirFiche` clique par `.click()`, qui n'émet PAS de `pointerup` — le filet de reprise
      ne joue donc pas ici et l'on dépend de la bride de 3 s du réconciliateur. En usage réel un
      vrai tap le reprend immédiatement ; on attend donc 4,5 s pour mesurer le pire cas. */
await ouvrirFiche(page, /anaphylaxie/);
await page.waitForTimeout(4500);
s = await tenu();
veut('4. réouverture : verrou repris (pire cas, sans pointerup)', s.crise && s.wake, s);

/* 5. LE VERROU SE PERD AU PASSAGE EN ARRIÈRE-PLAN — c'est la spécification, pas un défaut. On
      CONTRÔLE la course au lieu de la subir : la bride est poussée au loin pour observer la perte
      (sinon le réconciliateur la répare avant qu'on ait pu la voir — affirmer un état transitoire
      que le système est fait pour effacer donnerait un contrôle instable), puis on la lève. */
await page.evaluate(async () => { _wakeNext = Date.now() + 60000; if (_wake) await _wake.release(); });
await page.waitForTimeout(400);
s = await tenu();
veut('5a. verrou perdu, reprise bridée', !s.wake && s.crise, s);
await page.evaluate(() => { _wakeNext = 0; });
await page.waitForTimeout(1200);
s = await tenu();
veut('5b. repris seul dès que la bride tombe, sans aucun geste', s.wake, s);

await nav.close(); srv.close();
if (fautes.length) { console.error('✗ ' + fautes.length + ' faute(s) :\n  ' + fautes.join('\n  ')); process.exit(1); }
console.log(`[${NOM_MOTEUR}] ✓ wake lock : 6/6 — pris en crise, rendu sinon, repris seul.`);
