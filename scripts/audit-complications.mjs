/* AUDIT — COMPLICATIONS « À TOUT MOMENT » (v4.26.0). Entrée PAR L'ÉVÉNEMENT (QRH non-normal /
   mode failure-related ECAM) : boutons ⚡ sur la carte du bout + menu ⋯, nouveau passage à chaque
   occurrence, excursion marquée en toutes lettres, « Terminer » supprimé pendant l'excursion,
   RETOUR nommé toujours actif (cases neuves — doctrine d'interruption AC 120-71B), sections
   « À tout moment » hors numérotation dans l'Échelle et le Statique, cible externe = autre aide,
   zéro chrome sans déclaration. */
import { createServer } from 'node:http';import { readFile } from 'node:fs/promises';import { extname } from 'node:path';import { chromium } from 'playwright';
const ROOT=decodeURIComponent(new URL('../',import.meta.url).pathname);
const T={'.html':'text/html','.js':'text/javascript','.json':'application/json','.webmanifest':'application/manifest+json','.png':'image/png','.svg':'image/svg+xml','.ico':'image/x-icon'};
const srv=createServer(async(q,r)=>{try{let p=decodeURIComponent(q.url.split('?')[0]);if(p==='/')p='/index.html';const b=await readFile(ROOT+p.replace(/^\/+/,''));r.writeHead(200,{'content-type':T[extname(p)]||'application/octet-stream'});r.end(b);}catch{r.writeHead(404);r.end('nf');}});
const port=await new Promise(r=>srv.listen(0,()=>r(srv.address().port)));
const br=await chromium.launch();const p=await br.newPage({viewport:{width:1000,height:950},deviceScaleFactor:2});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
p.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
await p.goto(`http://localhost:${port}/index.html`);await p.waitForFunction(()=>!document.querySelector('.boot-load'));
await p.evaluate(async()=>{const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await new Promise(r=>setTimeout(r,150));
 const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await new Promise(r=>setTimeout(r,400));
 const c=[...document.querySelectorAll('.card-open')].find(x=>/Arr.t cardiaque/.test(x.textContent));
 const f=fiches.find(x=>x.id===c.dataset.open);
 // bloc de complication dédié + déclaration : 1 locale + 1 externe (l'autre fiche d'exemple)
 f.blocks.push({id:'cxL',type:'steps',title:'Laryngospasme — gestes',steps:['Arrêter la stimulation','⚠ PPC + subluxation mandibulaire','Approfondir la sédation'],next:null});
 const autre=fiches.find(x=>x.id!==f.id);
 f.complications=[{label:'Laryngospasme',target:'cxL'},{label:'Anaphylaxie',target:autre.id}];
 window.__autre=autre.id;
 c.click();await new Promise(r=>setTimeout(r,400));
 document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,450));});
console.log('=== déclencheur ===');
const d1=await p.evaluate(()=>({btns:[...document.querySelectorAll('.ov-block.cur .cx-btn')].map(b=>b.textContent.trim()),
 menu:(()=>{document.getElementById('hdrMore').click();const rows=[...document.querySelectorAll('#moreMenu .mm-row')].map(x=>x.textContent.replace(/\s+/g,' ').trim());document.getElementById('hdrMore').click();return rows.filter(x=>/Laryngo|Anaphyl/.test(x));})()}));
t('les boutons ⚡ vivent sur la carte du bout', d1.btns.length===2&&/Laryngospasme/.test(d1.btns[0]), JSON.stringify(d1.btns));
t('la cible EXTERNE est marquée ↗', /↗/.test(d1.btns[1]), JSON.stringify(d1.btns));
t('le menu ⋯ liste les complications (accès constant)', d1.menu.length===2, JSON.stringify(d1.menu));
console.log('=== entrée locale + excursion ===');
const d2=await p.evaluate(async()=>{
 [...document.querySelectorAll('.cx-btn')].find(b=>/Laryngospasme/.test(b.textContent)).click();
 await new Promise(r=>setTimeout(r,450));
 const cur=document.querySelector('.ov-block.cur');
 return {nav:state.nav.slice(),titre:cur.querySelector('.ov-t').textContent.replace(/\s+/g,' ').trim(),
  tag:!!cur.querySelector('.cx-tag'),pastille:cur.querySelector('.ov-n').textContent.trim(),
  terminer:!!cur.querySelector('[data-ovend]'),
  reprendre:(cur.querySelector('[data-cxback]')||{}).textContent||null,
  cases:cur.querySelectorAll('ol.steps li:not(.done)').length};});
t('l’événement ENTRE au bout du journal', d2.nav[d2.nav.length-1]==='cxL', JSON.stringify(d2.nav));
t('le passage est marqué « ⚡ complication » en toutes lettres', d2.tag&&/complication/.test(d2.titre));
t('la pastille montre ⚡, pas un numéro de tronc', d2.pastille==='⚡', d2.pastille);
t('« Terminer l’algorithme » est SUPPRIMÉ pendant l’excursion', d2.terminer===false);
t('« ↩ Reprendre » est présent et nomme le bloc interrompu', !!d2.reprendre&&/Reprendre/.test(d2.reprendre), ''+d2.reprendre);
const d3=await p.evaluate(async()=>{
 const avant=state.nav.length;
 document.querySelector('[data-cxback]').click();await new Promise(r=>setTimeout(r,450));
 const cur=document.querySelector('.ov-block.cur');
 return {apres:state.nav.length>avant,retourAu:state.nav[state.nav.length-1],
  casesNeuves:cur.querySelectorAll('ol.steps li:not(.done)').length>0,
  cartesGardees:document.querySelectorAll('.ov-block').length>=3};});
t('« Reprendre » = NOUVEAU passage du bloc interrompu (cases neuves, doctrine interruption)', d3.apres&&d3.casesNeuves, JSON.stringify(d3));
t('l’excursion reste TRACÉE (les cartes précédentes demeurent)', d3.cartesGardees);
const d4=await p.evaluate(async()=>{const n0=state.nav.filter(x=>x==='cxL').length;
 [...document.querySelectorAll('.cx-btn')].find(b=>/Laryngospasme/.test(b.textContent)).click();await new Promise(r=>setTimeout(r,400));
 return state.nav.filter(x=>x==='cxL').length>n0;});
t('un événement qui SE REPRODUIT crée un nouveau passage (jamais un simple défilement)', d4);
console.log('=== échelle / statique / externe / sans ===');
const d5=await p.evaluate(()=>{const lad=document.querySelector('.read-side .rail-lad');
 return {section:!!document.querySelector('.pl-cxh'),
  ligne:[...(lad?lad.querySelectorAll('.pl-line.cxl'):[])].map(x=>x.textContent.trim().slice(0,20)),
  troncPollue:[...(lad?lad.querySelectorAll('.pl-line:not(.cxl) .t'):[])].some(x=>/Laryngo/.test(x.textContent))};});
t('Échelle : section « ⚡ À tout moment », tronc non pollué', d5.section&&d5.ligne.length===1&&!d5.troncPollue, JSON.stringify(d5));
const d6=await p.evaluate(async()=>{
 [...document.querySelectorAll('#modeSeg [data-readmode]')].find(x=>x.dataset.readmode==='static').click();await new Promise(r=>setTimeout(r,600));
 const band=document.querySelector('.sv-cxband');const cell=document.querySelector('.sv-cell.sv-cx');
 return {band:!!band,cell:cell?cell.textContent.replace(/\s+/g,' ').slice(0,40):null,
   num:cell?cell.querySelector('.sv-n').textContent.trim():null};});
t('Statique : bande « ⚡ À tout moment » + cellule sans numéro', d6.band&&d6.num==='⚡', JSON.stringify(d6));
const d7=await p.evaluate(async()=>{
 [...document.querySelectorAll('#modeSeg [data-readmode]')].find(x=>x.dataset.readmode==='dynamic').click();await new Promise(r=>setTimeout(r,500));
 const before=state.fiche.id;
 [...document.querySelectorAll('.cx-btn')].find(b=>/Anaphylaxie/.test(b.textContent)).click();await new Promise(r=>setTimeout(r,500));
 return {avant:before,apres:state.fiche&&state.fiche.id,ouvert:state.fiche&&state.fiche.id===window.__autre};});
t('cible EXTERNE : ouvre l’autre aide (session courante préservée)', d7.ouvert, JSON.stringify(d7));
const d8=await p.evaluate(async()=>{
 // revenir, puis retirer les complications -> AUCUN chrome ⚡ ne doit rester
 const f2=fiches.find(x=>x.id===window.__autre);f2.complications=[];
 render();await new Promise(r=>setTimeout(r,400));
 return {btn:document.querySelectorAll('.cx-btn').length,tag:document.querySelectorAll('.cx-tag').length,sec:document.querySelectorAll('.pl-cxh').length};});
t('fiche SANS complications : zéro chrome ⚡ (pas de bouton mort)', d8.btn===0&&d8.sec===0, JSON.stringify(d8));
await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
