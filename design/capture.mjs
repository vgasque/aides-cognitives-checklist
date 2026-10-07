#!/usr/bin/env node
/* Captures du DOM RÉEL pour les fiches du design system (design/captures/*.html).
 * Les démos écrites à la main ont divergé du code (rail ①②③, Échelle, glyphes ⚠/△ — tous purgés) ;
 * celles-ci sont relevées sur l'app, aide d'exemple « Arrêt cardiaque ». À rejouer quand une surface
 * de crise change : `node design/capture.mjs`, puis `npm run design:build`. Dev seulement (Playwright). */
import { writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { serveApp, moteur, amorce, ouvrirFiche, demarrerSession } from '../scripts/harness.mjs';

const OUT = join(dirname(fileURLToPath(import.meta.url)), 'captures');
mkdirSync(OUT, { recursive: true });
const { port, srv } = await serveApp();
const br = await moteur().launch();
const W = ms => new Promise(r => setTimeout(r, ms));
// Une capture = le outerHTML, sans les `id` (deux thèmes par fiche) — sauf `ids` : la coque stylée PAR son id (quai, capsule).
const grab = (page, sel, ids) => page.evaluate(([s, ids]) => {
  const el = document.querySelector(s); if (!el) return null;
  const c = el.cloneNode(true); c.removeAttribute('hidden');
  if (!ids) { c.removeAttribute('id'); c.querySelectorAll('[id]').forEach(x => x.removeAttribute('id')); }
  return c.outerHTML;
}, [sel, !!ids]);
const save = (nom, html) => {
  if (!html) { console.error('✗ capture vide : ' + nom); process.exitCode = 1; return; }
  writeFileSync(join(OUT, nom + '.html'), html + '\n'); console.log('  ✓', nom, `(${(html.length / 1024).toFixed(1)} ko)`);
};
const clic = (page, sel) => page.evaluate(s => { const e = document.querySelector(s); if (!e) throw new Error('absent : ' + s); e.click(); }, sel);

{ // Avant la session, au téléphone : l'écran de démarrage (A330) avec son parcours à plat.
  const page = await br.newPage({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });
  await page.goto(`http://localhost:${port}/index.html`); await amorce(page);
  await page.evaluate(() => { const b = [...document.querySelectorAll('.notice-x')]; b.forEach(x => x.click()); }); await W(300);
  save('entete-accueil', await grab(page, 'header.bar', true));
  await page.evaluate(() => { togglePin(fiches[1].id); collNew('Garde SMUR', fiches.map(f => f.id)); collNew('Bloc pédia', [fiches[0].id]); render(); }); await W(400);
  save('accueil', await grab(page, '.dir-wrap'));
  await ouvrirFiche(page, /Arrêt cardiaque/); await W(400);
  save('demarrage', await grab(page, '.care-flat'));
  await demarrerSession(page); await W(400);
  save('capsule', await grab(page, '#crisisDock', true));
  save('quai', await grab(page, '#sessionDock', true));
  await page.close();
}
{ // En session, au cockpit : étapes, Vérifier, journal, parcours de la colonne.
  const page = await br.newPage({ viewport: { width: 1280, height: 900 } });
  await page.goto(`http://localhost:${port}/index.html`); await amorce(page);
  await ouvrirFiche(page, /Arrêt cardiaque/); await W(300);
  await clic(page, '[data-prelink="page"]'); await W(800);
  save('page', await grab(page, '.sv-wrap'));
  await page.keyboard.press('Escape'); await W(400);
  await demarrerSession(page);
  await clic(page, '.ov-block.cur li[data-ck$=":0"]'); await W(300);
  save('etapes', await grab(page, '.ov-block.cur'));
  await clic(page, '.ov-block.cur [data-ovverify]'); await W(300);
  await clic(page, '.ov-block.cur .v-ok'); await W(200);
  await clic(page, '.ov-block.cur .v-gap'); await W(200);
  save('verification', await grab(page, '.ov-block.cur'));
  await clic(page, '.ov-block.cur .v-quit'); await W(300);
  await page.evaluate(() => { document.querySelectorAll('.ov-block.cur li[data-ck][aria-checked="false"]').forEach(x => x.click()); }); await W(300);
  await clic(page, '.ov-block.cur .btn.cont'); await W(400);
  save('journal', await grab(page, '.ov-wrap'));
  save('parcours', await grab(page, '.read-plan .pf-flat'));
  await clic(page, '#hdrMore'); await W(300);
  save('menu', await grab(page, '#moreMenu', true));
  await page.close();
}
await br.close(); srv.close();
