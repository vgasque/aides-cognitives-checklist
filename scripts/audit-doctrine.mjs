/* LOT 7 — volet DOCTRINE : ECAM / QRH / FAA AC 120-71B, mesuré sur l'app réelle.
   Chaque contrôle traduit une règle de sûreté en invariant observable. */
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname } from 'node:path';
import { chromium } from 'playwright';
const ROOT=decodeURIComponent(new URL('../',import.meta.url).pathname);
const T={'.html':'text/html','.js':'text/javascript','.json':'application/json','.webmanifest':'application/manifest+json','.png':'image/png','.svg':'image/svg+xml','.ico':'image/x-icon'};
const srv=createServer(async(q,r)=>{try{let p=decodeURIComponent(q.url.split('?')[0]);if(p==='/')p='/index.html';
 const b=await readFile(ROOT+p.replace(/^\/+/,''));r.writeHead(200,{'content-type':T[extname(p)]||'application/octet-stream'});r.end(b);}catch{r.writeHead(404);r.end('nf');}});
const port=await new Promise(r=>srv.listen(0,()=>r(srv.address().port)));
const br=await chromium.launch();
let ok=0,ko=0;
const t=(nom,cond,det)=>{if(cond){ok++;console.log('  ✓ '+nom);}else{ko++;console.log('  ✗ '+nom+(det?'\n      '+det:''));}};

async function session(w){
  const page=await br.newPage({viewport:{width:w,height:820}});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(async()=>{
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();
    await new Promise(r=>setTimeout(r,120));
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();
    await new Promise(r=>setTimeout(r,350));
    const c=[...document.querySelectorAll('.card-open')].find(x=>/Arrêt cardiaque/.test(x.textContent));
    c.click();await new Promise(r=>setTimeout(r,150));
    document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,350));});
  return page;
}

// ══ ECAM — constance positionnelle de la zone d'état ════════════════════════
console.log('\n══ ECAM · constance positionnelle du quai ══');
{
  const page=await session(1280);
  const snap=()=>page.evaluate(()=>[...document.querySelectorAll('#crisisDock .dock-in>*')]
    .filter(e=>!e.hidden&&getComputedStyle(e).display!=='none')
    .map(e=>e.id||e.className));
  const geo=id=>page.evaluate(i=>{const e=document.getElementById(i);
    return e&&!e.hidden?Math.round(e.getBoundingClientRect().left):null;},id);
  const a=await snap(), pa=await geo('planBtn'), ra=await geo('refBtn');
  // faire varier l'état : ajouter des minuteurs (la partie VARIABLE du quai)
  await page.evaluate(async()=>{
    const add=[...document.querySelectorAll('.rt-add,.add-line')];
    for(const b of add.slice(0,3)){b.click();await new Promise(r=>setTimeout(r,120));}});
  await page.waitForTimeout(300);
  const b=await snap(), pb=await geo('planBtn'), rb=await geo('refBtn');
  t('ordre du quai identique quel que soit l\'état', JSON.stringify(a)===JSON.stringify(b), a+'\n      → '+b);
  t('bouton Plan immobile (px)', pa!==null&&pa===pb, `${pa} → ${pb}`);
  t('bouton Réf. immobile (px)', ra===rb, `${ra} → ${rb}`);
  // Débordement JAMAIS silencieux : on fait ÉCHOIR 3 minuteurs d'intervalle, le quai n'en
  // montre que 2 en large — le 3ᵉ doit être annoncé par un « +n », jamais escamoté.
  const ov=await page.evaluate(async()=>{
    const ids=Object.keys(Runtime.timers);
    while(ids.length<3){const b=document.querySelector('.rt-add,.add-line');if(!b)break;b.click();
      await new Promise(r=>setTimeout(r,200));ids.splice(0,ids.length,...Object.keys(Runtime.timers));}
    ids.slice(0,3).forEach(k=>{const t=Runtime.timers[k];
      t.type='interval';t.seconds=t.seconds||120;t.running=false;t.elapsedMs=t.seconds*1000+5000;});
    updateRtStrip(Date.now());await new Promise(r=>setTimeout(r,120));
    const s=document.getElementById('cbTimers');
    const due=Object.values(Runtime.timers).filter(t=>t.type==='interval'&&!t.running
      &&t.elapsedMs>=t.seconds*1000).length;
    const segs=s?s.querySelectorAll('.seg:not(.glb)').length:0;
    return {due,segs,plus:!!s&&/\+\s?\d/.test(s.textContent),txt:s?s.textContent:null};});
  t('débordement d\'alarmes annoncé (« +n »)', ov.due<=ov.segs||ov.plus, JSON.stringify(ov));
  await page.close();
}

// ══ AC 120-71B — les memory items ne sont JAMAIS derrière un clic ═══════════
console.log('\n══ AC 120-71B · memory items en accès direct ══');
{
  const page=await session(390);
  const r=await page.evaluate(()=>{
    const strip=document.querySelector('.forget-strip,#forgetStrip,.ov-forget');
    const inMain=!!strip&&!!strip.closest('#main');
    const inSheet=!!strip&&!!strip.closest('#refModal,#planModal');
    return {present:!!strip,inMain,inSheet,
      // rien de vital ne doit exister UNIQUEMENT dans une feuille repliable
      dupRef:!!document.querySelector('#refModal .forget-strip')};});
  t('« Ne pas oublier » présent dans le FLUX principal', r.present&&r.inMain&&!r.inSheet, JSON.stringify(r));
  t('non recopié dans la feuille Consulter (source unique)', !r.dupRef);
  // QRH : la procédure abrégée reste sous les yeux, la référence est appelée
  const refInert=await page.evaluate(async()=>{
    const rb=document.getElementById('refBtn');if(!rb)return 'pas de bouton';
    rb.click();await new Promise(r=>setTimeout(r,350));
    const boxes=document.querySelectorAll('#refModal input[type=checkbox],#refModal .stp');
    const starts=document.querySelectorAll('#refModal [data-navgo],#refModal #sessStart');
    return {boxes:boxes.length,starts:starts.length};});
  t('feuille Consulter INERTE (aucune coche, aucun démarrage)',
    typeof refInert==='object'&&refInert.boxes===0&&refInert.starts===0, JSON.stringify(refInert));
  await page.close();
}

// ══ ECAM — naviguer ≠ agir ; le plan ne coche pas, ne démarre pas ══════════
console.log('\n══ ECAM · naviguer ≠ agir ══');
{
  const page=await br.newPage({viewport:{width:1280,height:820}});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(async()=>{
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();
    await new Promise(r=>setTimeout(r,120));
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();
    await new Promise(r=>setTimeout(r,350));
    [...document.querySelectorAll('.card-open')].find(x=>/Arrêt cardiaque/.test(x.textContent)).click();
    await new Promise(r=>setTimeout(r,250));});
  const before=await page.evaluate(()=>({live:Object.keys(liveSessions||{}).length,
    checked:JSON.stringify(Runtime.checked||{})}));
  const after=await page.evaluate(async()=>{
    const nd=document.querySelector('.pl-nd');if(nd)nd.click();
    await new Promise(r=>setTimeout(r,300));
    return {live:Object.keys(liveSessions||{}).length,checked:JSON.stringify(Runtime.checked||{})};});
  t('taper un nœud du plan ne DÉMARRE pas de session', before.live===after.live, `${before.live} → ${after.live}`);
  t('taper un nœud du plan ne COCHE rien', before.checked===after.checked);
  await page.close();
}

// ══ ECAM — aucune notification flottante pendant un soin ═══════════════════
console.log('\n══ ECAM · pas d\'alerte flottante en session ══');
{
  const page=await session(390);
  const r=await page.evaluate(async()=>{
    const vis=()=>[...document.querySelectorAll('.toast')].filter(e=>getComputedStyle(e).display!=='none'
      &&getComputedStyle(e).visibility!=='hidden'&&e.getBoundingClientRect().height>0).length;
    const avant=vis();                       // un toast antérieur au démarrage peut encore vivre
    toast('essai');await new Promise(r=>setTimeout(r,250));
    const sb=document.getElementById('sysBanner');
    return {crise:document.body.classList.contains('crisis-live'),nouveaux:vis()-avant,
      banner:sb?(!sb.hidden&&sb.getBoundingClientRect().height>0):false};});
  t('snackbar mis en attente en session', r.crise&&r.nouveaux===0, JSON.stringify(r));
  t('bandeau système absent hors accueil', r.banner===false);
  await page.close();
}

// ══ WCAG 2.3.3 / projet — mouvement inhibé sous prefers-reduced-motion ═════
console.log('\n══ WCAG · prefers-reduced-motion ══');
{
  const page=await br.newPage({viewport:{width:1280,height:820},reducedMotion:'reduce'});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(async()=>{
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();
    await new Promise(r=>setTimeout(r,120));
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();
    await new Promise(r=>setTimeout(r,350));
    [...document.querySelectorAll('.card-open')].find(x=>/Arrêt cardiaque/.test(x.textContent)).click();
    await new Promise(r=>setTimeout(r,250));
    document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,300));});
  const anim=await page.evaluate(()=>{
    const bad=[];
    document.querySelectorAll('#crisisDock *,.ov-wrap *,.read-side *,.pl-chip,.seg .seg-pill').forEach(e=>{
      const c=getComputedStyle(e);
      const d=parseFloat(c.animationDuration)||0, td=parseFloat(c.transitionDuration)||0;
      if(c.animationName!=='none'&&d>0.05)bad.push('anim '+(e.className||e.tagName)+' '+c.animationName);
      if(td>0.05&&/transform|opacity|all/.test(c.transitionProperty))bad.push('trans '+(e.className||e.tagName));});
    return [...new Set(bad)];});
  t('aucun mouvement autonome sous reduced-motion', anim.length===0, anim.slice(0,4).join('\n      '));
  await page.close();
}
await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} contrôles doctrine OK${ko?` — ${ko} ÉCHEC(S)`:''}`);
process.exit(ko?1:0);
