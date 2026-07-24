/* AUDIT — TRACE DE VÉRIFICATION (Do-Verify, AC 120-71B). Prouve qu'une passe laisse un résultat
   CONSULTABLE : « ✓✓ vérifié » (constaté) et « △ écart » distincts de la simple coche, invalidés
   par un geste manuel, et enregistrés dans la session. */
import { createServer } from 'node:http';import { readFile } from 'node:fs/promises';import { extname } from 'node:path';import { chromium } from 'playwright';
const ROOT=decodeURIComponent(new URL('../',import.meta.url).pathname);
const T={'.html':'text/html','.js':'text/javascript','.json':'application/json','.webmanifest':'application/manifest+json','.png':'image/png','.svg':'image/svg+xml','.ico':'image/x-icon'};
const srv=createServer(async(q,r)=>{try{let p=decodeURIComponent(q.url.split('?')[0]);if(p==='/')p='/index.html';const b=await readFile(ROOT+p.replace(/^\/+/,''));r.writeHead(200,{'content-type':T[extname(p)]||'application/octet-stream'});r.end(b);}catch{r.writeHead(404);r.end('nf');}});
const port=await new Promise(r=>srv.listen(0,()=>r(srv.address().port)));
const br=await chromium.launch();const p=await br.newPage({viewport:{width:900,height:1000}});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?'\n      '+d:''));}};
await p.goto(`http://localhost:${port}/index.html`);await p.waitForFunction(()=>!document.querySelector('.boot-load'));
await p.evaluate(async()=>{const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await new Promise(r=>setTimeout(r,120));
 const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await new Promise(r=>setTimeout(r,350));
 const c=[...document.querySelectorAll('.card-open')].find(x=>/Arr.t cardiaque/.test(x.textContent));
 const f=fiches.find(x=>x.id===c.dataset.open);
 f.blocks[0].steps=['Étape A','Étape B','Étape C'];
 c.click();await new Promise(r=>setTimeout(r,250));
 document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,300));});
// Pré-cocher l'étape A AVANT la vérification (c'est le cas décrit par l'utilisateur)
await p.evaluate(async()=>{document.querySelectorAll('ol.steps li')[0].click();await new Promise(r=>setTimeout(r,250));});
console.log('\n=== Passe de vérification : A déjà cochée avant ===');
// lancer Vérifier
await p.evaluate(async()=>{document.querySelector('[data-ovverify]').click();await new Promise(r=>setTimeout(r,300));});
// A -> Constaté ; B -> Écart ; C -> Constaté
await p.evaluate(async()=>{
 for(const act of ['ok','gap','ok']){
   const b=document.querySelector(act==='ok'?'[data-ovvok]':'[data-ovvgap]');b.click();await new Promise(r=>setTimeout(r,220));}});
// terminer la passe
await p.evaluate(async()=>{const x=document.querySelector('[data-ovvx]');if(x)x.click();await new Promise(r=>setTimeout(r,320));});
const r=await p.evaluate(()=>{
 const lis=[...document.querySelectorAll('ol.steps li')];
 return {marks:lis.map(li=>({txt:li.querySelector('.txt').textContent.trim().slice(0,9),
   done:li.classList.contains('done'),
   tag:(li.querySelector('.stp-vf')||{}).textContent||''})),
  verifiedN:Object.keys(Runtime.verified||{}).length,gapsN:Object.keys(Runtime.vgaps||{}).length};});
r.marks.forEach(m=>console.log(`   ${m.txt} : coché=${m.done} trace="${m.tag}"`));
t('l’étape pré-cochée puis CONSTATÉE porte « ✓✓ vérifié »', /vérifié/.test(r.marks[0].tag));
t('l’étape en ÉCART garde une trace « △ écart » après la passe', /écart/.test(r.marks[1].tag));
t('l’écart ne DÉCOCHE pas et reste non coché ici', r.marks[1].done===false);
t('la 3e constatée porte aussi « ✓✓ vérifié »', /vérifié/.test(r.marks[2].tag));
t('verified et vgaps sont distincts de checked', r.verifiedN===2&&r.gapsN===1, JSON.stringify(r));
// invalidation : cocher l'étape en écart doit lever l'écart
const r2=await p.evaluate(async()=>{document.querySelectorAll('ol.steps li')[1].click();await new Promise(r=>setTimeout(r,260));
 const li=document.querySelectorAll('ol.steps li')[1];
 return {tag:(li.querySelector('.stp-vf')||{}).textContent||'',gaps:Object.keys(Runtime.vgaps||{}).length};});
t('cocher une étape en écart LÈVE l’écart', r2.tag===''&&r2.gaps===0, JSON.stringify(r2));
// invalidation : décocher une étape vérifiée retire la constatation
const r3=await p.evaluate(async()=>{document.querySelectorAll('ol.steps li')[0].click();await new Promise(r=>setTimeout(r,260));
 const li=document.querySelectorAll('ol.steps li')[0];
 return {tag:(li.querySelector('.stp-vf')||{}).textContent||'',ver:Object.keys(Runtime.verified||{}).length};});
t('décocher une étape vérifiée RETIRE la constatation', r3.tag===''&&r3.ver===1, JSON.stringify(r3));
// persistance : la trace survit à un enregistrement/relecture de session
const r4=await p.evaluate(async()=>{persistLive(Runtime,true);await new Promise(r=>setTimeout(r,300));
 const s=sessions.find(x=>x.id===Runtime.sessionId);
 return {v:s&&s.verified?Object.keys(s.verified).length:-1,g:s&&s.vgaps?Object.keys(s.vgaps).length:-1};});
t('la trace est ENREGISTRÉE dans la session', r4.v>=1&&r4.g>=0, JSON.stringify(r4));
await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} contrôles vérification OK${ko?` — ${ko} ÉCHEC(S)`:''}`);
process.exit(ko?1:0);
