/* AUDIT — TRACE DE VÉRIFICATION (Do-Verify, AC 120-71B). Prouve qu'une passe laisse un résultat
   CONSULTABLE : « ✓✓ constaté » (constaté) et « △ écart » distincts de la simple coche, invalidés
   par un geste manuel, et enregistrés dans la session. */
import { serveApp, moteur, NOM_MOTEUR, ROOT, amorce, ouvrirFiche, demarrerSession } from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();const p=await br.newPage({viewport:{width:900,height:1000}});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?'\n      '+d:''));}};
await p.goto(`http://localhost:${port}/index.html`);
await amorce(p);
await p.evaluate(()=>{const f=fiches.find(x=>/Arr.t cardiaque/.test(x.title));
 f.blocks[0].steps=['Étape A','Étape B','Étape C'];});
await ouvrirFiche(p,/Arr.t cardiaque/);
await demarrerSession(p);
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
t('l’étape pré-cochée puis CONSTATÉE porte « ✓✓ constaté »', /constaté/.test(r.marks[0].tag));
t('l’étape en ÉCART garde une trace « △ écart » après la passe', /écart/.test(r.marks[1].tag));
t('l’écart ne DÉCOCHE pas et reste non coché ici', r.marks[1].done===false);
t('la 3e constatée porte aussi « ✓✓ constaté »', /constaté/.test(r.marks[2].tag));
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
