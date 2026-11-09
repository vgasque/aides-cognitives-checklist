#!/usr/bin/env node
/* AUDIT — CE QUI FLOTTE SE POSE AU BON ENDROIT (v5.111.2, A649)
 *
 * Deux défauts signalés, tous deux nés avec l'architecture « lanceur + catalogue » (v5.100) et que rien ne mesurait :
 *  1. la notification (« Application mise à jour… ») se posait SUR la barre d'onglets du téléphone, et n'avait pour
 *     largeur que la moitié de l'écran (`left:50%` + `translate(-50%)`) — trois lignes à 195 px ;
 *  2. au bureau, les filtres de « Tout » (Type, Bibliothèque, Catégorie, A → Z) ouvraient leur menu EN FIN DE PAGE,
 *     en bas à gauche, au lieu de le faire flotter sous leur bouton.
 * Les deux se mesurent à la géométrie, par les vrais gestes.
 */
import { serveApp, moteur, NOM_MOTEUR, amorce } from './harness.mjs';

const { port, srv } = await serveApp();
const br = await moteur().launch();
let ok = 0, ko = 0;
const t = (nom, cond, det) => { if (cond) { ok++; console.log('  ✓ ' + nom); }
  else { ko++; console.log('  ✗ ' + nom + (det ? '\n      ' + det : '')); } };

console.log(`\n══ FLOTTANTS · notification et menus de filtres — moteur ${NOM_MOTEUR} ══`);
{
  console.log('\n── 1. La notification, au téléphone, au-dessus de la barre d’onglets');
  const ctx = await br.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
  await ctx.route('**/*.supabase.co/**', r => r.abort());
  const page = await ctx.newPage();
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  const r = await page.evaluate(async () => {
    document.querySelectorAll('.toast').forEach(x => x.remove());
    toast('Application mise à jour (v' + APP_VERSION + ') — vous utilisez déjà la nouvelle version.', 9000);
    await window.__acCalme(600);
    const el = [...document.querySelectorAll('.toast')].pop(), tr = el.getBoundingClientRect();
    const d = document.querySelector('.tab-bar .tb-tabs'), dr = d ? d.getBoundingClientRect() : null;
    return { t: [tr.left, tr.top, tr.width, tr.bottom], dock: dr && [dr.top, dr.height], vw: innerWidth };
  });
  t('témoin : la barre d’onglets est là', r.dock && r.dock[1] > 0, JSON.stringify(r.dock));
  t('la notification s’arrête AU-DESSUS de la barre d’onglets', r.dock && r.t[3] <= r.dock[0] - 4, JSON.stringify(r));
  t('… et prend sa largeur (plus la moitié de l’écran)', r.t[2] > r.vw * 0.6, `${Math.round(r.t[2])} px sur ${r.vw}`);
  t('… centrée', Math.abs((r.t[0] + r.t[2] / 2) - r.vw / 2) <= 2, JSON.stringify(r.t));
  await ctx.close();
}
{
  console.log('\n── 2. Au bureau, le menu d’un filtre de « Tout » flotte sous son bouton');
  const page = await br.newPage({ viewport: { width: 1280, height: 800 } });
  await page.route('**/*.supabase.co/**', r => r.abort());
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  await page.click('[data-navbiblio]');
  await page.waitForSelector('[data-ctgtout]');
  await page.click('[data-ctgtout]');
  for (const k of ['type', 'lib', 'cat', 'sort']) {
    await page.waitForSelector(`[data-ctgf="${k}"]`);
    await page.click(`[data-ctgf="${k}"]`);
    await page.waitForSelector('.popmenu [data-pickopt]');
    const g = await page.evaluate(k => {
      const b = document.querySelector(`[data-ctgf="${k}"]`).getBoundingClientRect();
      const m = [...document.querySelectorAll('.popmenu')].find(x => x.querySelector('[data-pickopt]')).getBoundingClientRect();
      return { b: [b.left, b.bottom], m: [m.left, m.top, m.width, m.height] };
    }, k);
    t(`« ${k} » : le menu s’ouvre SOUS son bouton, pas en fin de page`,
      Math.abs(g.m[0] - g.b[0]) <= 24 && g.m[1] >= g.b[1] - 2 && g.m[1] - g.b[1] <= 24 && g.m[3] > 40, JSON.stringify(g));
    await page.keyboard.press('Escape');
    await page.waitForFunction(() => !document.querySelector('.popmenu [data-pickopt]'));
  }
  await page.close();
}

await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles flottants OK` + (ko ? ` — ${ko} ÉCHEC(S)` : ''));
process.exit(ko ? 1 : 0);
