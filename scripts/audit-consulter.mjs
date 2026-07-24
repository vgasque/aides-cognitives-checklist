/* AUDIT — FEUILLE « CONSULTER ». Elle ne porte QUE ce qui n'existe nulle part ailleurs : 57 % de
   sa hauteur était de la redite (surveillances, posologie), qui repoussait le contenu unique.
   Verrouille aussi l'invariant du BOUTON MORT : la rangée d'accès et le bouton du quai ne
   doivent exister que si la feuille a réellement du contenu. */
import { createServer } from 'node:http';import { readFile } from 'node:fs/promises';import { extname } from 'node:path';import { chromium } from 'playwright';
const ROOT=decodeURIComponent(new URL('../',import.meta.url).pathname);
const T={'.html':'text/html','.js':'text/javascript','.json':'application/json','.webmanifest':'application/manifest+json','.png':'image/png','.svg':'image/svg+xml','.ico':'image/x-icon'};
const srv=createServer(async(q,r)=>{try{let p=decodeURIComponent(q.url.split('?')[0]);if(p==='/')p='/index.html';const b=await readFile(ROOT+p.replace(/^\/+/,''));r.writeHead(200,{'content-type':T[extname(p)]||'application/octet-stream'});r.end(b);}catch{r.writeHead(404);r.end('nf');}});
const port=await new Promise(r=>srv.listen(0,()=>r(srv.address().port)));
const br=await chromium.launch();const p=await br.newPage({viewport:{width:420,height:900},deviceScaleFactor:2});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
p.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
await p.goto(`http://localhost:${port}/index.html`);await p.waitForFunction(()=>!document.querySelector('.boot-load'));
await p.evaluate(async()=>{const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await new Promise(r=>setTimeout(r,150));
 const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await new Promise(r=>setTimeout(r,400));
 const c=[...document.querySelectorAll('.card-open')].find(x=>/Arr.t cardiaque/.test(x.textContent));
 const f=fiches.find(x=>x.id===c.dataset.open);
 f.posology=['△ **ADRÉNALINE — IV** : 1 mg / 3–5 min','**AMIODARONE** : 300 mg'];
 c.click();await new Promise(r=>setTimeout(r,400));
 document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,450));});
// composition + hauteur
await p.evaluate(async()=>{document.getElementById('refBtn').click();await new Promise(r=>setTimeout(r,500));});
const r=await p.evaluate(()=>{const secs=[...document.querySelectorAll('#refModal .rs-sec')];
 let h=0;secs.forEach(s=>h+=s.getBoundingClientRect().height);
 return {ordre:secs.map(s=>s.dataset.rs),hauteur:Math.round(h),
  sousTitre:(document.querySelector('.annex-row .ax-sub')||{}).textContent||''};});
console.log('  composition :',JSON.stringify(r.ordre),'· hauteur',r.hauteur+'px');
t('plus de section « Surveillances »', !r.ordre.includes('verify'), JSON.stringify(r.ordre));
t('plus de section « Posologie »', !r.ordre.includes('poso'), JSON.stringify(r.ordre));
t('les différentiels restent EN TÊTE', r.ordre[0]==='diff', JSON.stringify(r.ordre));
t('la feuille est nettement plus courte (< 500 px ici)', r.hauteur<500, r.hauteur+'px');
t('le sous-titre n’annonce plus les copies', !/Surveillances|Posologie/.test(r.sousTitre), '«'+r.sousTitre+'»');
// la posologie reste joignable ailleurs
await p.evaluate(async()=>{closeRefSheet();await new Promise(r=>setTimeout(r,300));});
t('la posologie reste dans le flux (téléphone)', await p.evaluate(()=>document.querySelector('#main').textContent.indexOf('ADRÉNALINE')>=0));
t('les surveillances restent dans le flux', await p.evaluate(()=>document.querySelector('#main').textContent.indexOf('Chariot')>=0));
// INVARIANT : pas de bouton sans contenu
const vide=await p.evaluate(async()=>{const f=state.fiche;
 f.differentials=[];f.images=[];f.attachments=[];f.references=[];f.related=[];
 render();await new Promise(r=>setTimeout(r,400));
 return {btn:!document.getElementById('refBtn').hidden,rangee:!!document.getElementById('annexRow'),
   verify:clean(f.verify).length,poso:clean(f.posology).length};});
t('fiche SANS contenu de feuille (mais avec surveillances+posologie) : aucun bouton mort',
  vide.btn===false&&vide.rangee===false, JSON.stringify(vide));
await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
