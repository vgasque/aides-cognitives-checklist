/* AUDIT — L'EXERCICE GUIDÉ ET « PRENDRE EN MAIN » SUIVENT L'APP (A467). Demande de l'auteur : que le guide
   reste juste quand le dessin, le style des sessions ou leur contenu changent. Le guide ne dessine rien —
   il pointe des commandes vivantes — donc ce harnais le DÉROULE en entier, geste par geste, sur les deux
   aides d'exemple et à trois largeurs : chaque bulle doit trouver sa cible, ne jamais la couvrir, tenir
   dans la fenêtre, et le geste réel doit la faire avancer. Une commande renommée, déplacée ou retirée sans
   mise à jour de GUIDE_ETAPES rougit ici. Le pendant statique (libellés cités, sélecteurs émis) est
   `check-guide.mjs`. */
import { serveApp, moteur, amorce, ouvrirFiche } from './harness.mjs';

const { port, srv } = await serveApp();
const br = await moteur().launch();
let ok = 0, ko = 0; const t = (n, c, d) => { if (c) { ok++; console.log('  ✓ ' + n); } else { ko++; console.log('  ✗ ' + n + (d ? ' — ' + d : '')); } };
const w = m => new Promise(r => setTimeout(r, m));
/* `tout` : l'aide doit exercer TOUTES les étapes du guide — l'ACR d'exemple en est le banc. Si son contenu
   change au point d'en perdre une, c'est rouge : le guide et l'exemple doivent être revus ensemble. Le
   nombre attendu se lit dans l'app (GUIDE_ETAPES applicables), jamais en dur. */
const CAS = [
  { aide: /ACR/, W: 390, H: 844, z: 100, tout: true },
  { aide: /ACR/, W: 1280, H: 800, z: 100, tout: true },
  { aide: /ACR/, W: 360, H: 740, z: 130, tout: true },
  { aide: /Anaphylaxie/, W: 390, H: 844, z: 100 },   // pas de revue : l'étape se retire d'elle-même
];
const etat = p => p.evaluate(() => {
  const tip = document.getElementById('gdTip'), g = document.querySelector('.gd-tgt');
  const tr = tip && !tip.hidden ? tip.getBoundingClientRect() : null, gr = g ? g.getBoundingClientRect() : null;
  const couvre = !!(tr && gr && !(tr.right <= gr.left || tr.left >= gr.right || tr.bottom <= gr.top || tr.top >= gr.bottom));
  const dedans = !!tr && tr.left >= 0 && tr.top >= 0 && tr.right <= innerWidth + 1 && tr.bottom <= innerHeight + 1;
  // Le voile (A467) : UN calque sur toute la fenêtre, percé exactement autour de la cible, inerte au toucher.
  const v = document.getElementById('gdVeil'), vr = v && v.classList.contains('on') ? v.getBoundingClientRect() : null;
  const trou = v && v.dataset.hole ? v.dataset.hole.split(',').map(Number) : null;
  const voile = !!vr && vr.left <= 0 && vr.top <= 0 && vr.right >= innerWidth - 1 && vr.bottom >= innerHeight - 1
    && getComputedStyle(v).pointerEvents === 'none' && !!trou && !!gr
    && Math.abs(trou[0] - gr.left) <= 2 && Math.abs(trou[1] - gr.top) <= 2 && Math.abs(trou[2] - gr.right) <= 2 && Math.abs(trou[3] - gr.bottom) <= 2;
  return { voile, id: _gd ? (GUIDE_ETAPES[_gd.i] || {}).id : null, k: tip && !tip.hidden ? (tip.querySelector('.gd-k') || {}).textContent : '',
    cible: !!g, couvre, dedans, dbg: [tr && [tr.top|0, tr.bottom|0], gr && [gr.top|0, gr.bottom|0], g && g.className, document.getElementById('crisisDock').getBoundingClientRect().bottom|0], fin: !!(tip && tip.classList.contains('end')) };
});
for (const c of CAS) {
  console.log(`=== ${c.aide.source} — ${c.W}×${c.H} à ${c.z} % ===`);
  const p = await br.newPage({ viewport: { width: c.W, height: c.H } });
  p.on('pageerror', e => { ko++; console.log('  ✗ ERREUR PAGE : ' + e.message); });
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
  for (let pas = 0; pas < 40; pas++) {
    const e = await etat(p);
    if (e.fin || !e.id) break;
    if (!vus.includes(e.id)) {
      vus.push(e.id);
      t(`${e.id} : bulle « ${e.k} »`, new RegExp(`· ${vus.length}/${c.n}$`).test(e.k || ''), e.k);
    }
    t(`${e.id} : la cible est trouvée et entourée`, e.cible);
    t(`${e.id} : la bulle ne couvre pas la cible`, !e.couvre, JSON.stringify(e.dbg));
    t(`${e.id} : la bulle tient dans la fenêtre`, e.dedans);
    t(`${e.id} : tout l’écran est estompé sauf la cible (voile unique, percé, inerte)`, e.voile);
    // Le geste RÉEL de l'étape, par la commande de l'app — jamais par l'état du guide.
    await p.evaluate(async id => {
      const q = s => document.querySelector(s), clic = s => { const x = q(s); if (x) x.click(); return !!x; };
      const cur = '#main .ov-block.cur';
      if (id === 'start') clic('#sessStart');
      else if (id === 'check') clic(cur + ' ol.steps>li[data-ck][aria-checked="false"]:not(.rv-step)');
      else if (id === 'capsule') clic('#gdNext');
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
  t('le voile est retiré à la fin', await p.evaluate(() => !document.querySelector('#gdVeil.on')));
  t('aucune session réelle n’a été créée', await p.evaluate(() => !sessions.some(s => !s.exercise)));
  await p.close();
}
console.log('=== jamais en session réelle · « Prendre en main » ===');
{
  const p = await br.newPage({ viewport: { width: 390, height: 844 } });
  p.on('pageerror', e => { ko++; console.log('  ✗ ERREUR PAGE : ' + e.message); });
  await p.goto(`http://localhost:${port}/index.html`);
  await amorce(p); await ouvrirFiche(p, /ACR/);
  await p.evaluate(() => document.getElementById('sessStart').click()); await w(400);
  t('session réelle : ni carte ni bulle', await p.evaluate(() => !document.querySelector('[data-gdgo]') && !document.getElementById('gdTip')));
  await p.evaluate(() => { endSession(Runtime); freshRuntime(state.fiche, null); state.view = 'library'; state.fiche = null; render(); openGuide(); }); await w(300);
  const pm = await p.evaluate(() => ({ gestes: document.querySelectorAll('#guideBody .gd-row').length, mots: document.querySelectorAll('#guideBody .gd-gl dt').length,
    attendus: [GUIDE_GESTES.length, GLOSSAIRE.length], lancer: !!document.getElementById('guideRun') }));
  t('« Prendre en main » montre tous ses gestes et tout son glossaire', pm.gestes === pm.attendus[0] && pm.mots === pm.attendus[1] && pm.gestes > 0, JSON.stringify(pm));
  t('« Prendre en main » lance l’exercice guidé', pm.lancer);
  await p.click('#guideRun'); await w(600);
  t('… qui ouvre l’aide d’exemple sur la première bulle', await p.evaluate(() => /· 1\/\d$/.test((document.querySelector('#gdTip .gd-k') || {}).textContent || '') && state.view === 'read'));
  await p.close();
}
await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} OK${ko ? ` — ${ko} ÉCHEC(S)` : ''}`); process.exit(ko ? 1 : 0);
