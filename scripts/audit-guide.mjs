/* AUDIT — L'EXERCICE GUIDÉ ET « PRENDRE EN MAIN » SUIVENT L'APP (A467). Demande de l'auteur : que le guide
   reste juste quand le dessin, le style des sessions ou leur contenu changent. Le guide ne dessine rien —
   il pointe des commandes vivantes — donc ce harnais le DÉROULE en entier, geste par geste, sur les deux
   aides d'exemple, au téléphone, au bureau, en texte agrandi et sur un pliable à deux écrans : chaque phase
   doit trouver sa cible, la carte ne jamais la couvrir, se poser au-dessus du quai dans sa largeur, ne pas
   bouger quand la page défile, réserver sa hauteur au bas de la page ; et le geste réel doit la faire
   avancer. Une commande renommée, déplacée ou retirée sans mise à jour de GUIDE_ETAPES rougit ici. Le pendant
   statique (libellés cités, sélecteurs émis) est `check-guide.mjs`. */
import { serveApp, moteur, NOM_MOTEUR, amorce, ouvrirFiche } from './harness.mjs';

const { port, srv } = await serveApp();
const br = await moteur().launch();
let ok = 0, ko = 0; const t = (n, c, d) => { if (c) { ok++; console.log('  ✓ ' + n); } else { ko++; console.log('  ✗ ' + n + (d ? ' — ' + d : '')); } };
const w = m => new Promise(r => setTimeout(r, m));
/* `tout` : l'aide doit exercer TOUTES les étapes du guide — l'ACR d'exemple en est le banc. Si son contenu
   change au point d'en perdre une, c'est rouge : le guide et l'exemple doivent être revus ensemble. Le
   nombre attendu se lit dans l'app (GUIDE_ETAPES applicables), jamais en dur. `duo` : pliable émulé (CDP,
   charnière verticale à `off`, Chromium seulement — comme audit-pliables) ; la carte reste d'un côté. */
const CAS = [
  { aide: /ACR/, W: 390, H: 844, z: 100, tout: true },
  { aide: /ACR/, W: 1280, H: 800, z: 100, tout: true },
  { aide: /ACR/, W: 360, H: 740, z: 130, tout: true },
  { aide: /Anaphylaxie/, W: 390, H: 844, z: 100 },   // pas de revue : l'étape se retire d'elle-même
  { aide: /ACR/, W: 1114, H: 705, z: 100, duo: { off: 540, mask: 34 } },
];
// Attendre que la page soit posée : le voile se retire pendant un défilement et revient après.
// Et que le guide ait fini d'amener la cible (ses essais sont espacés de 500 ms).
const pose = async p => { await w(150); await p.waitForFunction(() => !_gd || (Date.now() - (_gd.scrollT || 0) > 300 && Date.now() - (_gd.roomT || 0) > 900), null, { timeout: 6000 }).catch(() => {}); await w(80); };
const etat = p => p.evaluate(() => {
  const tip = document.getElementById('gdTip'), g = document.querySelector('.gd-tgt');
  const E = _gd ? GUIDE_ETAPES[_gd.i] : null, P = E ? E.ph(_gd, state.fiche) : null;
  const tr = tip && !tip.hidden ? tip.getBoundingClientRect() : null, gr = g ? g.getBoundingClientRect() : null;
  const couvre = !!(tr && gr && !(tr.right <= gr.left || tr.left >= gr.right || tr.bottom <= gr.top || tr.top >= gr.bottom));
  const dedans = !!tr && tr.left >= 0 && tr.top >= 0 && tr.right <= innerWidth + 1 && tr.bottom <= innerHeight + 1;
  // Ancrage : au-dessus du quai (ou de ce qu'il a ouvert), dans la largeur du quai ; en haut seulement si une
  // fenêtre de dialogue mettait la cible sous la carte.
  const q = document.querySelector('#sessionDock .sd-in'), qr = q && q.getClientRects().length ? q.getBoundingClientRect() : null;
  const bas = _gdBas(innerHeight), enHaut = !!tr && tr.top <= 9 * zoomF();
  const ancre = !!tr && (enHaut || tr.bottom <= bas - 4) && (!qr || qr.width <= 200 || (Math.abs(tr.left - qr.left) <= 1 && Math.abs(tr.right - qr.right) <= 1));
  // Le voile : UN calque sur toute la fenêtre, percé autour de la cible (et de ce qu'elle a ouvert), inerte.
  const v = document.getElementById('gdVeil'), vr = v && v.classList.contains('on') ? v.getBoundingClientRect() : null;
  const trou = v && v.dataset.hole ? v.dataset.hole.split(',').map(Number) : null;
  const voile = !!vr && vr.left <= 0 && vr.top <= 0 && vr.right >= innerWidth - 1 && vr.bottom >= innerHeight - 1
    && getComputedStyle(v).pointerEvents === 'none' && !!trou && !!gr
    && trou[0] <= gr.left + 2 && trou[1] <= gr.top + 2 && trou[2] >= gr.right - 2 && trou[3] >= gr.bottom - 2;
  // Sans cible mais avec un `trou` (le bloc à cocher) : le voile estompe le reste et découvre ce bloc entier.
  const zt = P && !P.tgt && P.trou ? document.querySelector(P.trou) : null, zr = zt ? zt.getBoundingClientRect() : null;
  const voileTrou = !(P && !P.tgt && P.trou) || (!!zt && !!vr && !!trou && trou[0] <= zr.left + 2 && trou[1] <= zr.top + 2 && trou[2] >= zr.right - 2 && trou[3] >= zr.bottom - 2 && !document.querySelector('.gd-tgt'));
  return { voile, voileTrou, ancre, id: E ? E.id : null, aCible: !!(P && P.tgt), k: tip && !tip.hidden ? (tip.querySelector('.gd-k') || {}).textContent : '',
    cible: !!g, couvre, dedans, tr: tr && [tr.left | 0, tr.top | 0, tr.right | 0, tr.bottom | 0], dbg: [tr && [tr.top | 0, tr.bottom | 0], gr && [gr.top | 0, gr.bottom | 0], g && g.className, bas | 0, _gd && [_gd.room, (_gd.userT || 0) > (_gd.phaseT || 0), scrollY | 0]],
    fin: !!(tip && tip.classList.contains('end')) };
});
for (const c of CAS) {
  if (c.duo && NOM_MOTEUR !== 'chromium') { console.log(`=== pliable : SAUTÉ sur ${NOM_MOTEUR} (charnière émulée par CDP Chromium) ===`); continue; }
  console.log(`=== ${c.aide.source} — ${c.W}×${c.H} à ${c.z} %${c.duo ? ' · pliable, charnière à ' + c.duo.off : ''} ===`);
  const ctx = await br.newContext({ viewport: { width: c.W, height: c.H }, hasTouch: !!c.duo });
  const p = await ctx.newPage();
  p.on('pageerror', e => { ko++; console.log('  ✗ ERREUR PAGE : ' + e.message); });
  if (c.duo) { const cdp = await ctx.newCDPSession(p);
    await cdp.send('Emulation.setDeviceMetricsOverride', { width: c.W, height: c.H, deviceScaleFactor: 1, mobile: true, displayFeature: { orientation: 'vertical', offset: c.duo.off, maskLength: c.duo.mask } }); }
  await p.goto(`http://localhost:${port}/index.html`);
  await amorce(p);
  if (c.z !== 100) await p.evaluate(async z => { applyZoom(z); await new Promise(r => setTimeout(r, 350)); }, c.z);
  await ouvrirFiche(p, c.aide);
  const att = await p.evaluate(() => ({ n: GUIDE_ETAPES.filter(E => E.ok(state.fiche)).length, total: GUIDE_ETAPES.length }));
  c.n = att.n;
  if (c.tout) t(`l’aide d’exemple exerce toutes les étapes du guide (${att.n}/${att.total})`, att.n === att.total);
  t('la carte « Apprendre avec cette aide » est proposée sur l’aide d’exemple', await p.evaluate(() => !!document.querySelector('[data-gdgo]')));
  await p.click('[data-gdgo]'); await w(400);
  const vus = [];
  let mobilite = false;
  for (let pas = 0; pas < 50; pas++) {
    await pose(p);
    const e = await etat(p);
    if (e.fin || !e.id) break;
    if (!vus.includes(e.id)) {
      vus.push(e.id);
      t(`${e.id} : carte « ${e.k} »`, new RegExp(`· ${vus.length}/${c.n}$`).test(e.k || ''), e.k);
    }
    if (e.aCible) {
      t(`${e.id} : la cible est trouvée et entourée`, e.cible);
      t(`${e.id} : tout l’écran est estompé sauf la cible (voile unique, percé, inerte)`, e.voile);
    }
    t(`${e.id} : sans cible, le bloc à cocher reste net et le reste s’estompe (sans anneau)`, e.voileTrou);
    t(`${e.id} : la carte ne couvre pas la cible`, !e.couvre, JSON.stringify(e.dbg));
    t(`${e.id} : la carte tient dans la fenêtre`, e.dedans);
    t(`${e.id} : la carte est ancrée au-dessus du quai, dans sa largeur`, e.ancre, JSON.stringify(e.tr));
    if (c.duo) t(`${e.id} : la carte reste d’un côté de la charnière`, e.tr && (e.tr[2] <= c.duo.off || e.tr[0] >= c.duo.off + c.duo.mask), JSON.stringify(e.tr));
    // Une fois par cas, en cours de session : la carte ne bouge pas quand la page défile, et la page réserve sa
    // hauteur — on défile jusqu'au bout sans qu'une ligne reste dessous (le défaut signalé sur iPhone).
    if (!mobilite && e.id === 'check') {
      mobilite = true;
      // Défilement À LA MAIN (molette) : c'est lui que le guide doit respecter, pas un scrollTo de sonde.
      const avant = await p.evaluate(() => document.getElementById('gdTip').getBoundingClientRect().top | 0);
      await p.mouse.move(c.W / 2, c.H / 3); await p.mouse.wheel(0, 90); await w(120);
      const pendant = await p.evaluate(() => ({ apres: document.getElementById('gdTip').getBoundingClientRect().top | 0, voilePendant: !!document.querySelector('#gdVeil.on') }));
      // Deux fois : au bas de page la barre « ↩ Bloc » paraît et réserve sa propre hauteur, la page s'allonge.
      await p.mouse.wheel(0, 20000); await w(700); await p.mouse.wheel(0, 20000); await w(700);
      const bout = await p.evaluate(() => { const tip = document.getElementById('gdTip'), main = document.getElementById('main');
        const der = [...main.querySelectorAll('.ov-block, section, .pre-tail, .fold-card')].filter(x => x.getClientRects().length).pop();
        return { fin: der ? der.getBoundingClientRect().bottom | 0 : 0, haut: tip.getBoundingClientRect().top | 0, y: scrollY | 0 }; });
      await p.mouse.wheel(0, -20000); await w(600);
      const m = { avant, ...pendant, ...bout };
      t('la carte ne bouge pas quand la page défile', Math.abs(m.avant - m.apres) <= 1, JSON.stringify(m));
      t('… et le voile se retire pendant le défilement', !m.voilePendant, JSON.stringify(m));
      t('au bout de la page, rien ne reste sous la carte (hauteur réservée)', m.fin <= m.haut + 1, JSON.stringify(m));
    }
    // Le geste RÉEL de l'étape, par la commande de l'app — jamais par l'état du guide.
    await p.evaluate(async id => {
      const q = s => document.querySelector(s), clic = s => { const x = q(s); if (x) x.click(); return !!x; };
      const cur = '#main .ov-block.cur';
      if (id === 'start') clic('#sessStart');
      else if (id === 'check') clic(cur + ' ol.steps>li[data-ck][aria-checked="false"]:not(.rv-step)');
      else if (id === 'capsule') { if (!clic('#gdNext.gd-b')) clic('#cbTimers'); }   // regarder (large) ; ouvrir puis refermer (étroit)
      else if (id === 'decision') {
        if (!clic(cur + ' [data-ovopt]')) {
          for (const li of document.querySelectorAll(cur + ' ol.steps>li[data-ck][aria-checked="false"]:not(.rv-step)')) li.click();
          await new Promise(r => setTimeout(r, 150)); clic(cur + ' [data-ovnext]');
        }
      } else if (id === 'revue') {
        if (!q(cur + ' li.rv-step.open')) clic(cur + ' li.rv-step .rv-head');
        await new Promise(r => setTimeout(r, 150)); clic(cur + ' li.rv-step.open [data-ck]');
      } else if (id === 'cx') { if (!clic('#main [data-cxback]')) clic('#cxKey'); }
      else if (id === 'tk') { if (!clic('#dockSheet .ds-x')) clic('#tkKey'); }
      else if (id === 'fin') {
        if (!q('#endSessModal.on')) clic('#endKey');
        else { const b = q('#endSessYes'); b.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
          await new Promise(r => setTimeout(r, 1400)); b.dispatchEvent(new PointerEvent('pointerup', { bubbles: true })); }
      }
    }, e.id);
    await w(450);
  }
  const fin = await p.evaluate(() => { const tip = document.getElementById('gdTip');
    return tip && tip.classList.contains('end') ? { faits: tip.querySelectorAll('.gd-sum li.ok').length, tous: tip.querySelectorAll('.gd-sum li').length, accueil: state.view } : null; });
  t('l’exercice terminé, la carte de fin résume les gestes', !!fin, JSON.stringify(fin));
  t(`tous les gestes sont faits (${c.n})`, fin && fin.faits === c.n && fin.tous === c.n, JSON.stringify(fin));
  t('le voile est retiré à la fin, la hauteur réservée aussi', await p.evaluate(() => !document.querySelector('#gdVeil.on') && !document.body.classList.contains('gd-on')));
  t('aucune session réelle n’a été créée', await p.evaluate(() => !sessions.some(s => !s.exercise)));
  await ctx.close();
}
console.log('=== carte réduite · jamais en session réelle · « Prendre en main » ===');
{
  const p = await br.newPage({ viewport: { width: 390, height: 844 } });
  p.on('pageerror', e => { ko++; console.log('  ✗ ERREUR PAGE : ' + e.message); });
  await p.goto(`http://localhost:${port}/index.html`);
  await amorce(p); await ouvrirFiche(p, /ACR/);
  await p.click('[data-gdgo]'); await w(300); await p.click('#sessStart'); await w(500);
  await p.click('#gdMin'); await w(300);
  const r = await p.evaluate(() => { const b = document.getElementById('gdOpen'), x = b && b.getBoundingClientRect();
    return { pastille: !!b, h: x ? Math.round(x.height) : 0, voile: !!document.querySelector('#gdVeil.on'), focus: document.activeElement === b }; });
  t('▾ réduit la carte en pastille (44 px), sans voile, focus sur la pastille', r.pastille && r.h >= 44 && !r.voile && r.focus, JSON.stringify(r));
  await p.click('#gdOpen'); await w(300);
  t('… et la pastille la rouvre', await p.evaluate(() => !!document.getElementById('gdMin') && document.activeElement === document.getElementById('gdMin')));
  await p.click('#gdQuit'); await w(200);
  await p.evaluate(() => { endSession(Runtime); freshRuntime(state.fiche, null); render(); }); await w(200);
  await p.evaluate(() => document.getElementById('sessStart').click()); await w(400);
  t('session réelle : ni carte d’entrée ni carte du guide', await p.evaluate(() => !document.querySelector('[data-gdgo]') && !document.getElementById('gdTip')));
  await p.evaluate(() => { endSession(Runtime); freshRuntime(state.fiche, null); state.view = 'library'; state.fiche = null; render(); openGuide(); }); await w(300);
  const pm = await p.evaluate(() => ({ gestes: document.querySelectorAll('#guideBody .gd-row').length, mots: document.querySelectorAll('#guideBody .gd-gl dt').length,
    attendus: [GUIDE_GESTES.length, GLOSSAIRE.length], lancer: !!document.getElementById('guideRun') }));
  t('« Prendre en main » montre tous ses gestes et tout son glossaire', pm.gestes === pm.attendus[0] && pm.mots === pm.attendus[1] && pm.gestes > 0, JSON.stringify(pm));
  t('« Prendre en main » lance l’exercice guidé', pm.lancer);
  await p.click('#guideRun'); await w(600);
  t('… qui ouvre l’aide d’exemple sur la première carte', await p.evaluate(() => /· 1\/\d$/.test((document.querySelector('#gdTip .gd-k') || {}).textContent || '') && state.view === 'read'));
  await p.close();
}
await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} OK${ko ? ` — ${ko} ÉCHEC(S)` : ''}`); process.exit(ko ? 1 : 0);
