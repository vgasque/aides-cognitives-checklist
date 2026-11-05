/* AUDIT — L'ATTENTE DE CALME DES HARNAIS (A564).
 *
 * POURQUOI CE HARNAIS. `__acCalme(max)` (installeCalme, harness.mjs) remplace ~830 pauses fixes dans doctrine,
 * a11y et k5 : elle rend la main dès que l'écran est posé. Si elle la rendait TROP TÔT, ces harnais liraient un
 * écran à moitié construit — rouges de charge au mieux, verts faciles sur un témoin négatif au pire. C'est donc
 * l'outil, et non une sonde, qu'il faut garder : chaque source de changement qu'elle suit est éprouvée ici, avec
 * un effet qui tombe APRÈS 80 ms de silence du DOM (sans suivi, l'attente rendrait la main avant lui).
 * Vérifié capable d'échouer : suivi des minuteurs et des rAF retiré → « minuteur » et « rAF » rouges.
 */
import { serveApp, moteur, NOM_MOTEUR, amorce, calme } from './harness.mjs';

const { port, srv } = await serveApp();
const br = await moteur().launch();
let ok = 0, ko = 0;
const t = (n, c, d) => { if (c) { ok++; console.log('  ✓ ' + n); } else { ko++; console.log('  ✗ ' + n + (d ? ' — ' + d : '')); } };
console.log(`══ L'attente de calme ne rend pas la main trop tôt — moteur ${NOM_MOTEUR} ══`);
const page = await br.newPage({ viewport: { width: 390, height: 844 } });
page.on('pageerror', e => { ko++; console.log('  ✗ ERREUR PAGE : ' + e.message); });
await page.goto(`http://localhost:${port}/index.html`);
await amorce(page);
t('posée dès la création de la page, avant le code de l’app', await page.evaluate(() => typeof window.__acCalme === 'function'));
const r = await page.evaluate(async () => {
  const o = {}, el = document.createElement('div'); document.body.appendChild(el);
  const ms = t0 => Math.round(performance.now() - t0);
  let t0 = performance.now();
  setTimeout(() => { el.textContent = 'minuteur'; }, 300); await __acCalme(600);
  o.minuteur = { vu: el.textContent === 'minuteur', ms: ms(t0) };
  t0 = performance.now(); let n = 0;
  const boucle = () => { if (++n < 20) requestAnimationFrame(boucle); else el.textContent = 'raf'; };
  requestAnimationFrame(boucle); await __acCalme(900);
  o.raf = { vu: el.textContent === 'raf', ms: ms(t0) };
  t0 = performance.now(); el.style.cssText = 'width:10px;height:10px';
  const a = el.animate([{ transform: 'none' }, { transform: 'translateX(50px)' }], { duration: 400 }); await __acCalme(900);
  o.anim = { vu: a.playState === 'finished', ms: ms(t0) };
  const db = await new Promise(res => { const q = indexedDB.open('audit-calme', 1);
    q.onupgradeneeded = () => q.result.createObjectStore('s'); q.onsuccess = () => res(q.result); });
  t0 = performance.now(); let fini = false;
  const tx = db.transaction('s', 'readwrite');
  for (let i = 0; i < 3000; i++) tx.objectStore('s').put('x'.repeat(200), i);
  tx.oncomplete = () => { fini = true; }; await __acCalme(5000);
  o.idb = { vu: fini, ms: ms(t0) };
  t0 = performance.now(); await __acCalme(600); o.repos = ms(t0);
  /* Le plafond tient : une source qui ne se tait jamais (boucle rAF perpétuelle) ne bloque pas au-delà. */
  let stop = false; const sans = () => { if (!stop) requestAnimationFrame(sans); }; requestAnimationFrame(sans);
  t0 = performance.now(); await __acCalme(300); o.plafond = ms(t0); stop = true;
  return o;
});
t('un minuteur de l’app qui échoit avant le plafond est attendu', r.minuteur.vu, JSON.stringify(r.minuteur));
t('une boucle requestAnimationFrame est attendue', r.raf.vu, JSON.stringify(r.raf));
t('une animation finie d’un élément est attendue', r.anim.vu, JSON.stringify(r.anim));
t('une transaction IndexedDB ouverte est attendue', r.idb.vu, JSON.stringify(r.idb));
t('au repos, la main revient vite (c’est tout le gain)', r.repos < 300, `${r.repos} ms`);
t('le plafond borne l’attente (jamais plus long que la pause d’avant)', r.plafond >= 290 && r.plafond < 450, `${r.plafond} ms`);
/* Côté Node, `calme(page, N)` : même attente, appelée depuis la sonde. */
const t1 = Date.now();
await page.evaluate(() => setTimeout(() => { document.body.dataset.calme = 'node'; }, 250));
await calme(page, 600);
t('côté Node, calme(page, N) attend aussi l’effet', await page.evaluate(() => document.body.dataset.calme === 'node'), `${Date.now() - t1} ms`);
await page.close();
await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} OK${ko ? ` — ${ko} ÉCHEC(S)` : ''}`); process.exit(ko ? 1 : 0);
