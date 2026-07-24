/* AUDIT — COMPLICATIONS « À TOUT MOMENT » (v4.26.x). Entrée PAR L'ÉVÉNEMENT, modèle QRH : UN
   déclencheur constant (« ⚡ Complication(s) ») ouvre un INDEX par événement — pas un bouton par
   urgence. Excursion tracée, « Terminer » supprimé pendant, RETOUR nommé toujours actif (cases
   neuves — doctrine d'interruption AC 120-71B), sections « À tout moment » hors numérotation,
   cible externe = autre aide, zéro chrome sans déclaration, sélecteur filtrable de l'éditeur. */
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
 f.blocks.push({id:'cxL',type:'steps',title:'Laryngospasme — gestes',steps:['Arrêter la stimulation','⚠ PPC + subluxation mandibulaire','Approfondir la sédation'],next:null});
 const autre=fiches.find(x=>x.id!==f.id);
 f.complications=[{label:'Laryngospasme',target:'cxL'},{label:'Anaphylaxie',target:autre.id}];
 window.__autre=autre.id;window.__acr=f.id;
 c.click();await new Promise(r=>setTimeout(r,400));
 document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,450));});
console.log('=== déclencheur constant + index ===');
const d1=await p.evaluate(async()=>{
 const btns=[...document.querySelectorAll('.ov-block.cur .cx-btn')];
 const lbl=btns.map(b=>b.textContent.replace(/\s+/g,' ').trim());
 btns[0].click();await new Promise(r=>setTimeout(r,350));
 const rows=[...document.querySelectorAll('#cxList .cx-item')].map(x=>x.textContent.replace(/\s+/g,' ').trim());
 const on=document.getElementById('cxModal').classList.contains('on');
 document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',bubbles:true}));await new Promise(r=>setTimeout(r,250));
 return {nb:btns.length,lbl,rows,on,ferme:!document.getElementById('cxModal').classList.contains('on')};});
t('UN SEUL bouton, mot constant + compte', d1.nb===1&&/⚡ Complications 2/.test(d1.lbl[0]), JSON.stringify(d1.lbl));
t('l’index liste les 2 événements en grandes rangées', d1.on&&d1.rows.length===2, JSON.stringify(d1.rows));
t('la cible externe annonce ce qu’elle ouvre (↗)', /ouvre :/.test(d1.rows[1])&&/↗/.test(d1.rows[1]), d1.rows[1]);
t('Échap ferme l’index', d1.ferme);
const dm=await p.evaluate(()=>{document.getElementById('hdrMore').click();
 const rows=[...document.querySelectorAll('#moreMenu .mm-row')].map(x=>x.textContent.replace(/\s+/g,' ').trim());
 document.getElementById('hdrMore').click();return rows.filter(x=>/Complication/.test(x));});
t('menu ⋯ : UNE entrée constante « Complications (2) »', dm.length===1&&/\(2\)/.test(dm[0]), JSON.stringify(dm));
console.log('=== entrée / excursion / retour ===');
const d2=await p.evaluate(async()=>{
 document.querySelector('[data-cxopen]').click();await new Promise(r=>setTimeout(r,300));
 [...document.querySelectorAll('#cxList .cx-item')].find(x=>/Laryngo/.test(x.textContent)).click();
 await new Promise(r=>setTimeout(r,450));
 const cur=document.querySelector('.ov-block.cur');
 return {bout:state.nav[state.nav.length-1],tag:!!cur.querySelector('.cx-tag'),
  pastille:cur.querySelector('.ov-n').textContent.trim(),terminer:!!cur.querySelector('[data-ovend]'),
  reprendre:(cur.querySelector('[data-cxback]')||{}).textContent||null};});
t('l’événement entre au bout du journal', d2.bout==='cxL');
t('passage marqué « ⚡ complication », pastille ⚡', d2.tag&&d2.pastille==='⚡', JSON.stringify(d2));
t('« Terminer l’algorithme » supprimé pendant l’excursion', d2.terminer===false);
t('« ↩ Reprendre » nomme le bloc interrompu', !!d2.reprendre&&/Reprendre/.test(d2.reprendre), ''+d2.reprendre);
const d3=await p.evaluate(async()=>{const avant=state.nav.length;
 document.querySelector('[data-cxback]').click();await new Promise(r=>setTimeout(r,450));
 const cur=document.querySelector('.ov-block.cur');
 return {plus:state.nav.length>avant,neuves:cur.querySelectorAll('ol.steps li:not(.done)').length>0,
  cartes:document.querySelectorAll('.ov-block').length>=3};});
t('Reprendre = NOUVEAU passage, cases neuves (doctrine interruption)', d3.plus&&d3.neuves, JSON.stringify(d3));
t('l’excursion reste tracée (cartes conservées)', d3.cartes);
const d4=await p.evaluate(async()=>{const n0=state.nav.filter(x=>x==='cxL').length;
 document.querySelector('[data-cxopen]').click();await new Promise(r=>setTimeout(r,300));
 [...document.querySelectorAll('#cxList .cx-item')].find(x=>/Laryngo/.test(x.textContent)).click();
 await new Promise(r=>setTimeout(r,400));
 return state.nav.filter(x=>x==='cxL').length>n0;});
t('un événement qui SE REPRODUIT = nouveau passage', d4);
console.log('=== bloc de DÉCISION courant (limite v4.26.0 levée) ===');
const d5=await p.evaluate(async()=>{
 document.querySelector('[data-cxback]').click();await new Promise(r=>setTimeout(r,400));
 document.querySelectorAll('.ov-block.cur ol.steps li:not(.done)').forEach(li=>li.click());await new Promise(r=>setTimeout(r,250));
 const nb=document.querySelector('.ov-block.cur [data-ovnext]');if(nb)nb.click();await new Promise(r=>setTimeout(r,450));
 const cur=document.querySelector('.ov-block.cur');
 return {dec:cur.classList.contains('dec'),btn:!!cur.querySelector('[data-cxopen]')};});
t('le déclencheur vit AUSSI sur un bloc de décision courant', d5.dec&&d5.btn, JSON.stringify(d5));
console.log('=== échelle / statique / externe / sans ===');
const d6=await p.evaluate(()=>{const lad=document.querySelector('.read-side .rail-lad');
 return {sec:!!document.querySelector('.pl-cxh'),
  lignes:[...(lad?lad.querySelectorAll('.pl-line.cxl'):[])].length,
  pollue:[...(lad?lad.querySelectorAll('.pl-line:not(.cxl) .t'):[])].some(x=>/Laryngo/.test(x.textContent))};});
t('Échelle : section « À tout moment », tronc non pollué', d6.sec&&d6.lignes===1&&!d6.pollue, JSON.stringify(d6));
const d7=await p.evaluate(async()=>{
 [...document.querySelectorAll('#modeSeg [data-readmode]')].find(x=>x.dataset.readmode==='static').click();await new Promise(r=>setTimeout(r,600));
 const cell=document.querySelector('.sv-cell.sv-cx');
 return {band:!!document.querySelector('.sv-cxband'),num:cell?cell.querySelector('.sv-n').textContent.trim():null};});
t('Statique : bande + cellule sans numéro (⚡)', d7.band&&d7.num==='⚡', JSON.stringify(d7));
const d8=await p.evaluate(async()=>{
 [...document.querySelectorAll('#modeSeg [data-readmode]')].find(x=>x.dataset.readmode==='dynamic').click();await new Promise(r=>setTimeout(r,500));
 document.querySelector('[data-cxopen]').click();await new Promise(r=>setTimeout(r,300));
 [...document.querySelectorAll('#cxList .cx-item')].find(x=>/Anaphyl/.test(x.textContent)).click();
 await new Promise(r=>setTimeout(r,500));
 return {ouvert:state.fiche&&state.fiche.id===window.__autre};});
t('cible EXTERNE : ouvre l’autre aide', d8.ouvert, JSON.stringify(d8));
const d9=await p.evaluate(async()=>{const f2=fiches.find(x=>x.id===window.__autre);f2.complications=[];
 render();await new Promise(r=>setTimeout(r,400));
 return {btn:document.querySelectorAll('.cx-btn').length,sec:document.querySelectorAll('.pl-cxh').length};});
t('fiche SANS complications : zéro chrome ⚡', d9.btn===0&&d9.sec===0, JSON.stringify(d9));
console.log('=== éditeur : sélecteur filtrable à deux groupes ===');
const d10=await p.evaluate(async()=>{
 openEdit(window.__autre);await new Promise(r=>setTimeout(r,450));
 document.getElementById('addCx').click();await new Promise(r=>setTimeout(r,350));
 const row=document.querySelector('.cx-edit-row');if(!row)return {row:false};
 row.querySelector('[data-cxpicker]').click();await new Promise(r=>setTimeout(r,350));
 const heads=[...document.querySelectorAll('#relPickList .pick-h')].map(x=>x.textContent);
 const titre=document.getElementById('relPickTitle').textContent;
 // filtrer puis choisir le premier bloc
 const inp=document.getElementById('relPickQ');inp.value='';inp.dispatchEvent(new Event('input'));
 await new Promise(r=>setTimeout(r,200));
 const first=document.querySelector('#relPickList [data-pick]');const pickId=first.dataset.pick;first.click();
 await new Promise(r=>setTimeout(r,350));
 const btn=document.querySelector('.cx-edit-row .cx-tgt');
 return {row:true,heads,titre,cible:state.draft.complications[0].target===pickId,
  nom:btn?btn.textContent.trim():null,modalFermee:!document.getElementById('relPickModal').classList.contains('on')};});
t('le sélecteur filtrable s’ouvre, titré pour la complication', d10.row&&/Cible de la complication/.test(d10.titre), JSON.stringify({titre:d10.titre}));
t('deux groupes : blocs de la fiche PUIS aides & protocoles', d10.heads&&d10.heads.length===2&&/Blocs/.test(d10.heads[0]), JSON.stringify(d10.heads));
t('choisir pose la cible et referme ; le bouton affiche le nom', d10.cible&&d10.modalFermee&&!!d10.nom&&!/Choisir/.test(d10.nom), JSON.stringify({nom:d10.nom}));
await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
