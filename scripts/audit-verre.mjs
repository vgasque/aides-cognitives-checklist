/* AUDIT — CONTRASTE SOUS LES BARRES (lot 2 de la refonte « Natif », A510 §1).
   `audit-a11y` compose le fond d'un texte par ses ANCÊTRES du DOM : juste pour une surface opaque,
   faux sous une barre translucide, où le fond réel est ce qui DÉFILE dessous. Ce harnais mesure au
   PIXEL : pour chaque texte de la capsule et du quai, la barre est masquée, on capture ce qui passe
   dessous, on y compose la pile de fonds de la barre (couleurs et opacités réelles), et l'on garde le
   PIRE contraste. Le contenu le plus chargé est amené sous chaque barre : l'étape CRITIQUE, puis une
   étape cochée (aplat « fait »). Barres opaques aujourd'hui : la sonde le dit et mesure quand même.
   Seuil : 4,5:1, 3:1 pour un texte ≥ 24 px ou ≥ 18,66 px gras (WCAG 1.4.3). */
import { serveApp, moteur, amorce, ouvrirFiche, demarrerSession } from './harness.mjs';

const { port, srv } = await serveApp();
const br = await moteur().launch();
let ok = 0, ko = 0;
const t = (n, c, d) => { if (c) { ok++; console.log('  ✓ ' + n); } else { ko++; console.log('  ✗ ' + n + (d ? '\n      ' + d : '')); } };
const W = ms => new Promise(r => setTimeout(r, ms));
/* `AC_VERRE_ESSAI=1` : la capsule et le quai reçoivent un verre clair à 60 % sur lequel l'encre
   système (claire) ne tient pas — la sonde DOIT rougir. C'est sa preuve d'échec, rejouable. */
const ESSAI = process.env.AC_VERRE_ESSAI === '1';

const BARRES = [['capsule', '#cbTimers'], ['quai', '#sessionDock .sd-in']];

async function mesurer(page, sel, vise) {
  // 1. amener `vise` (une étape) sous la barre : la barre fixe/collante ne bouge pas, le contenu oui
  await page.evaluate(([sel, vise]) => {
    const b = document.querySelector(sel), e = document.querySelector(vise);
    if (!b || !e) return;
    const rb = b.getBoundingClientRect(), re = e.getBoundingClientRect();
    window.scrollBy(0, (re.top + re.height / 2) - (rb.top + rb.height / 2));
  }, [sel, vise]);
  await W(250);
  // 2. inventaire des textes de la barre, avec la pile de fonds DANS la barre (jusqu'à sa racine)
  const inv = await page.evaluate((sel) => {
    const root = document.querySelector(sel); if (!root) return null;
    const parse = c => { const m = c.match(/rgba?\(([^)]+)\)/); if (!m) return null; const a = m[1].split(/[ ,/]+/).filter(Boolean).map(Number); return [a[0], a[1], a[2], a.length > 3 ? a[3] : 1]; };
    const z = (parseFloat(document.documentElement.style.zoom) || 100) / 100;
    const out = [];
    root.querySelectorAll('*').forEach(e => {
      if (![...e.childNodes].some(n => n.nodeType === 3 && n.textContent.trim())) return;
      const r = e.getBoundingClientRect(); if (r.width < 2 || r.height < 2) return;
      const cs = getComputedStyle(e); if (cs.visibility === 'hidden' || +cs.opacity === 0) return;
      const pile = [];   // du plus proche au plus lointain, jusqu'à la barre et ses ancêtres fixés
      for (let a = e; a; a = a.parentElement) {
        const s = getComputedStyle(a), c = parse(s.backgroundColor);
        if (c && c[3] > 0) pile.push(c);
        if (c && c[3] >= 1) break;
        if (a === root) { for (let p = root.parentElement; p && p !== document.body; p = p.parentElement) { const q = parse(getComputedStyle(p).backgroundColor); if (q && q[3] > 0) { pile.push(q); if (q[3] >= 1) break; } const pos = getComputedStyle(p).position; if (pos !== 'fixed' && pos !== 'sticky') break; } break; }
      }
      out.push({ txt: e.textContent.trim().slice(0, 24), fg: parse(cs.color), px: parseFloat(cs.fontSize) * z, w: +cs.fontWeight,
        r: [Math.round(r.left), Math.round(r.top), Math.round(r.width), Math.round(r.height)], pile, opaque: pile.some(c => c[3] >= 1) });
    });
    return out;
  }, sel);
  if (!inv) return null;
  // 3. ce qui passe DESSOUS : la barre masquée le temps d'une capture
  await page.evaluate(s => { const b = document.querySelector(s); b.dataset.vv = b.style.visibility; b.style.visibility = 'hidden'; }, sel);
  await W(60);
  const png = (await page.screenshot()).toString('base64');
  await page.evaluate(s => { const b = document.querySelector(s); b.style.visibility = b.dataset.vv || ''; }, sel);
  // 4. composition et pire contraste, au pixel, dans la page (canvas : aucune dépendance)
  return page.evaluate(async ([png, inv]) => {
    const img = new Image(); img.src = 'data:image/png;base64,' + png; await img.decode();   // pas de fetch : la CSP de l'app l'interdit sur data:
    const cv = document.createElement('canvas'); cv.width = img.width; cv.height = img.height;
    const cx = cv.getContext('2d'); cx.drawImage(img, 0, 0);
    const k = img.width / innerWidth;
    const lum = ([r, g, b]) => { const f = v => { v /= 255; return v <= .03928 ? v / 12.92 : Math.pow((v + .055) / 1.055, 2.4); }; return .2126 * f(r) + .7152 * f(g) + .0722 * f(b); };
    const over = (t, b) => [0, 1, 2].map(i => t[i] * t[3] + b[i] * (1 - t[3]));
    return inv.map(x => {
      const [l, tp, w, h] = x.r;
      const d = cx.getImageData(Math.max(0, Math.round(l * k)), Math.max(0, Math.round(tp * k)), Math.max(1, Math.round(w * k)), Math.max(1, Math.round(h * k))).data;
      let pire = 99, n = 0;
      for (let i = 0; i < d.length; i += 4 * 3) {   // un pixel sur trois suffit
        let bg = [d[i], d[i + 1], d[i + 2]];
        for (let j = x.pile.length - 1; j >= 0; j--) bg = over(x.pile[j], bg);
        const fg = over(x.fg, bg), L1 = lum(fg), L2 = lum(bg);
        const cr = (Math.max(L1, L2) + .05) / (Math.min(L1, L2) + .05);
        if (cr < pire) pire = cr; n++;
      }
      const seuil = (x.px >= 24 || (x.px >= 18.66 && x.w >= 700)) ? 3 : 4.5;
      return { txt: x.txt, pire: +pire.toFixed(2), seuil, opaque: x.opaque, n };
    });
  }, [png, inv]);
}

for (const [Wd, H, th] of [[390, 844, 'light'], [390, 844, 'dark'], [844, 390, 'light'], [1280, 800, 'light']]) {
  const ctx = await br.newContext({ viewport: { width: Wd, height: H }, hasTouch: Wd < 1280, colorScheme: th });
  await ctx.addInitScript(th => { try { localStorage.setItem('ac-theme', th); } catch (e) {} }, th);
  const page = await ctx.newPage();
  page.on('pageerror', e => { ko++; console.log('  ✗ ERREUR PAGE : ' + e.message); });
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  if (ESSAI) await page.addStyleTag({ content: '#cbTimers,#sessionDock .sd-in,#crisisDock{background:rgba(255,255,255,.6)!important;backdrop-filter:blur(8px)}' });
  await ouvrirFiche(page, /Arrêt cardiaque/);
  await demarrerSession(page);
  await page.evaluate(() => { Object.values(Runtime.timers).slice(0, 2).forEach(t => tmRestart(t)); render(); });
  await W(600);
  // une étape cochée existe pour l'aplat « fait »
  await page.evaluate(() => { const l = document.querySelector('.ov-block.cur li[data-ck]'); if (l) l.click(); });
  await W(400);
  console.log(`\n══ ${Wd} × ${H} · ${th === 'dark' ? 'nuit' : 'jour'} ══`);
  for (const [nom, sel] of BARRES) {
    for (const [lib, vise] of [['étape CRITIQUE', '.ov-block.cur li.crit'], ['étape cochée', '.ov-block.cur li[aria-checked="true"]']]) {
      const r = await mesurer(page, sel, vise);
      if (!r) { t(`${nom} · sous ${lib} : barre absente`, false); continue; }
      if (!r.length) { t(`${nom} · sous ${lib} : aucun texte mesuré`, false); continue; }
      const fautes = r.filter(x => x.pire < x.seuil);
      const pire = r.reduce((a, x) => x.pire / x.seuil < a.pire / a.seuil ? x : a, r[0]);
      t(`${nom} · sous ${lib} · ${r.length} textes · pire ${pire.pire}:1 (« ${pire.txt} », seuil ${pire.seuil})${r.every(x => x.opaque) ? ' · barre opaque' : ' · barre translucide'}`,
        !fautes.length, JSON.stringify(fautes.slice(0, 4)));
    }
  }
  await ctx.close();
}
await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles de contraste sous barre OK${ko ? ' — ' + ko + ' ÉCHEC(S)' : ''}`);
process.exit(ko ? 1 : 0);
