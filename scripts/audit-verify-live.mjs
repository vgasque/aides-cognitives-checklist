/* AUDIT — RETOUR IMMÉDIAT DU MODE VÉRIFIER + registre des blocs de décision + taille des options. */
import { createServer } from 'node:http';import { readFile } from 'node:fs/promises';import { extname } from 'node:path';import { chromium } from 'playwright';
const ROOT=decodeURIComponent(new URL('../',import.meta.url).pathname);
const T={'.html':'text/html','.js':'text/javascript','.json':'application/json','.webmanifest':'application/manifest+json','.png':'image/png','.svg':'image/svg+xml','.ico':'image/x-icon'};
const srv=createServer(async(q,r)=>{try{let p=decodeURIComponent(q.url.split('?')[0]);if(p==='/')p='/index.html';const b=await readFile(ROOT+p.replace(/^\/+/,''));r.writeHead(200,{'content-type':T[extname(p)]||'application/octet-stream'});r.end(b);}catch{r.writeHead(404);r.end('nf');}});
const port=await new Promise(r=>srv.listen(0,()=>r(srv.address().port)));
const br=await chromium.launch();const p=await br.newPage({viewport:{width:1000,height:900},deviceScaleFactor:2});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
await p.goto(`http://localhost:${port}/index.html`);await p.waitForFunction(()=>!document.querySelector('.boot-load'));
await p.evaluate(async()=>{const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await new Promise(r=>setTimeout(r,150));
 const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await new Promise(r=>setTimeout(r,400));
 [...document.querySelectorAll('.card-open')].find(x=>/Arr.t cardiaque/.test(x.textContent)).click();await new Promise(r=>setTimeout(r,300));
 document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,400));});
// B. taille des options : avancer jusqu'au bloc décision
await p.evaluate(async()=>{document.querySelectorAll('.ov-block.cur ol.steps li:not(.done)').forEach(li=>li.click());await new Promise(r=>setTimeout(r,200));
 const nb=document.querySelector('.ov-block.cur [data-ovnext]');if(nb)nb.click();await new Promise(r=>setTimeout(r,400));});
const b=await p.evaluate(()=>{const o=document.querySelector('.opt'),st=document.querySelector('ol.steps li .txt');
 return {opt:o?getComputedStyle(o).fontSize:null,step:st?getComputedStyle(st).fontSize:'16.5px'};});
t('option de branche à la même taille qu\'une étape', b.opt==='16.5px', JSON.stringify(b));
// A. bordure du bloc décision COURANT = ambre
const a=await p.evaluate(()=>{const d=document.querySelector('.ov-block.dec.cur');if(!d)return null;
 const cs=getComputedStyle(d);const badge=d.querySelector('.ov-here');
 return {bord:cs.borderLeftColor,badgeVisible:!!badge&&getComputedStyle(badge).display!=='none',
   badgeFond:badge?getComputedStyle(badge).backgroundColor:null};});
t('bloc décision COURANT : bordure ambre (--verify-bd), pas bleue', a&&a.bord==='rgb(183, 121, 31)', JSON.stringify(a));
t('la position reste marquée par « VOUS ÊTES ICI » en bleu', a&&a.badgeVisible&&a.badgeFond==='rgb(31, 95, 166)', JSON.stringify(a));
// C. mode Vérifier : retour immédiat
await p.evaluate(async()=>{const opt=document.querySelector('.opt');if(opt)opt.click();await new Promise(r=>setTimeout(r,400));
 // cocher UNE étape AVANT la vérification (cas décrit : ne doit pas afficher ✓ trompeur)
 const li=document.querySelector('.ov-block.cur ol.steps li');if(li)li.click();await new Promise(r=>setTimeout(r,250));
 const vb=document.querySelector('.ov-block.cur [data-ovverify]');if(vb)vb.click();await new Promise(r=>setTimeout(r,400));});
const c0=await p.evaluate(()=>{const r=[...document.querySelectorAll('.vstp')];
 return {tally:(document.querySelector('.v-tally')||{}).textContent||null,
   marqueurs:r.map(x=>x.querySelector('.vst').textContent.trim()),tags:r.map(x=>(x.querySelector('.v-tag')||{}).textContent||'')};});
t('bilan VIVANT affiché dès l’ouverture de la passe', !!c0.tally&&/constat/.test(c0.tally), ''+c0.tally);
t('une étape cochée AVANT la passe n’affiche pas de ✓ trompeur', !c0.tags.some(x=>x==='constaté'), JSON.stringify(c0.tags));
// « Constaté ✓ » puis « △ Écart »
await p.evaluate(async()=>{document.querySelector('[data-ovvok]').click();await new Promise(r=>setTimeout(r,300));});
const c1=await p.evaluate(()=>({tally:document.querySelector('.v-tally').textContent,tags:[...document.querySelectorAll('.v-tag')].map(x=>x.textContent)}));
t('« Constaté » s’affiche IMMÉDIATEMENT sur l’étape', c1.tags.some(x=>/constaté/.test(x)), JSON.stringify(c1.tags));
t('le bilan vivant se met à jour', /1 constaté/.test(c1.tally), c1.tally);
await p.evaluate(async()=>{document.querySelector('[data-ovvgap]').click();await new Promise(r=>setTimeout(r,300));});
const c2=await p.evaluate(()=>({tally:document.querySelector('.v-tally').textContent,tags:[...document.querySelectorAll('.v-tag')].map(x=>x.textContent)}));
t('« Écart » s’affiche IMMÉDIATEMENT', c2.tags.some(x=>/écart/.test(x)), JSON.stringify(c2.tags));
// v4.25.2 — MÊME vocabulaire pendant et après la passe, et AUCUN bandeau ambre sur l'étape :
// le liseré inset appartient au REGISTRE (⚠/△), pas à l'état de la passe.
{const sortie=await p.evaluate(async()=>{const x=document.querySelector('[data-ovvx]');if(x)x.click();
   await new Promise(r=>setTimeout(r,450));
   const li=document.querySelector('ol.steps li.vgap');
   return {apres:[...document.querySelectorAll('.stp-vf')].map(e=>e.textContent),
     bandeau:li?getComputedStyle(li).boxShadow:'aucune ligne en écart'};});
 t('le libellé est IDENTIQUE pendant et après la passe',
   sortie.apres.some(x=>/constaté/.test(x))&&!sortie.apres.some(x=>/vérifié/.test(x)), JSON.stringify(sortie.apres));
 t('aucun bandeau ambre sur l’étape en écart (canal du registre préservé)',
   sortie.bandeau==='none'||/aucune/.test(sortie.bandeau), ''+sortie.bandeau);}
t('le bilan annonce l’écart sans attendre la fin', /1 écart/.test(c2.tally), c2.tally);

await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
