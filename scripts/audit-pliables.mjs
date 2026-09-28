/* AUDIT — ÉCRANS PLIABLES (audit UX 27/09/2026, N7). Exigence de l'auteur : l'application sert aussi
   sur les pliables à deux segments (Surface Duo en double portrait, Pixel Fold ouvert en paysage…).
   La règle `@media (horizontal-viewport-segments:2)` existait depuis v5.30, mais RIEN ne la
   vérifiait : en session, la capsule des minuteurs traversait la charnière et la gouttière de 24 px
   était plus étroite qu'une charnière de 34. Ce harnais émule la charnière (CDP, `displayFeature`)
   et exige qu'aucun objet de conduite ne la chevauche.
   ⚠ PIÈGE MESURÉ : `page.screenshot` de Playwright réapplique l'émulation du viewport et EFFACE la
   charnière — ce harnais ne capture donc rien, et revérifie la media query avant chaque mesure.
   WebKit n'expose pas les segments : le harnais s'y annonce SAUTÉ, il ne se déclare pas vert. */
import { serveApp, moteur, NOM_MOTEUR, amorce, ouvrirFiche, demarrerSession } from './harness.mjs';

if (NOM_MOTEUR !== 'chromium') { console.log(`audit-pliables : SAUTÉ sur ${NOM_MOTEUR} (émulation de charnière = CDP Chromium seulement).`); process.exit(0); }
const { port, srv } = await serveApp();
const br = await moteur().launch();
let ok = 0, ko = 0; const t = (n, c, d) => { if (c) { ok++; console.log('  ✓ ' + n); } else { ko++; console.log('  ✗ ' + n + (d ? ' — ' + d : '')); } };
const w = m => new Promise(r => setTimeout(r, m));
const APPAREILS = [
  { nom: 'double portrait, charnière 34 px (type Surface Duo)', W: 1114, H: 705, off: 540, mask: 34 },
  { nom: 'ouvert en paysage, pli sans épaisseur (type Pixel Fold)', W: 841, H: 701, off: 420, mask: 0 },
];
const OBJETS = { 'colonne d’action': '.read-main', 'colonne d’état': '.read-side', 'capsule des minuteurs': '#cbTimers', 'quai': '#sessionDock .sd-in' };
for (const a of APPAREILS) {
  console.log(`=== ${a.nom} — ${a.W}×${a.H} ===`);
  const ctx = await br.newContext({ viewport: { width: a.W, height: a.H }, hasTouch: true });
  const p = await ctx.newPage(); p.on('pageerror', e => { ko++; console.log('  ✗ ERREUR PAGE : ' + e.message); });
  const cdp = await ctx.newCDPSession(p);
  await cdp.send('Emulation.setDeviceMetricsOverride', { width: a.W, height: a.H, deviceScaleFactor: 1, mobile: true, displayFeature: { orientation: 'vertical', offset: a.off, maskLength: a.mask } });
  await p.goto(`http://localhost:${port}/index.html`);
  await amorce(p); await ouvrirFiche(p, /Anaphylaxie/); await demarrerSession(p);
  await p.evaluate(() => { const t = Object.values(Runtime.timers)[0]; if (t && !t.running) toggleTimer(t); window.scrollTo(0, 0); }); await w(600);
  const seg = () => p.evaluate(() => matchMedia('(horizontal-viewport-segments:2)').matches);
  t('la charnière est bien émulée (deux segments)', await seg());
  // Chevauche si l'objet déborde dans [off, off+mask] ; à pli nul, s'il enjambe la ligne du pli.
  const croise = (r) => a.mask > 0 ? (r[0] < a.off + a.mask && r[1] > a.off) : (r[0] < a.off && r[1] > a.off);
  const rects = await p.evaluate(o => Object.fromEntries(Object.entries(o).map(([k, s]) => { const e = document.querySelector(s); const r = e && e.getBoundingClientRect(); return [k, r && r.width ? [Math.round(r.left), Math.round(r.right)] : null]; })), OBJETS);
  for (const [k, r] of Object.entries(rects)) t(`${k} hors de la charnière`, r && !croise(r), r ? `${r[0]}→${r[1]}, charnière ${a.off}→${a.off + a.mask}` : 'absent');
  t('les deux colonnes sont de part et d’autre de la charnière', rects['colonne d’action'] && rects['colonne d’état'] && rects['colonne d’action'][1] <= a.off && rects['colonne d’état'][0] >= a.off + a.mask, JSON.stringify(rects));
  // La fenêtre « Terminer la session ? » : une confirmation ne se lit pas à cheval sur une charnière.
  await p.evaluate(() => document.getElementById('endKey').click()); await w(500);
  t('la charnière tient encore après ouverture de la fenêtre', await seg());
  const dlg = await p.evaluate(() => { const c = document.querySelector('#endSessModal .ai-card'); const r = c && c.getBoundingClientRect(); return r && r.width ? [Math.round(r.left), Math.round(r.right)] : null; });
  t('la fenêtre « Terminer la session ? » hors de la charnière', dlg && !croise(dlg), dlg ? `${dlg[0]}→${dlg[1]}` : 'absente');
  await ctx.close();
}
await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} OK${ko ? ` — ${ko} ÉCHEC(S)` : ''}`); process.exit(ko ? 1 : 0);
