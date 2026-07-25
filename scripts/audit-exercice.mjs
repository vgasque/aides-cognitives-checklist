/* AUDIT — MODE EXERCICE (v4.27.0, pilier EMIC « se familiariser ») + COMPTE-RENDU ENRICHI (toutes
   sessions). Fidélité : écran identique, seule l'ANNONCIATION change (bandeau hachuré « ▲ Exercice »,
   chrono bleu au lieu du « ● Session » vert). Zéro trace clinique : groupes séparés dans
   l'historique, carte-bilan et compte-rendu filigranés. Le compte-rendu restitue ⚡ complications
   (horodatées) et la trace do-verify (constats + écarts) — pour les sessions RÉELLES aussi. */
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
 const f=fiches.find(x=>x.id===c.dataset.open);window.__fid=f.id;
 f.blocks.push({id:'cxL',type:'steps',title:'Laryngospasme — gestes',steps:['Arrêter la stimulation'],next:null});
 f.complications=[{label:'Laryngospasme',target:'cxL'}];
 c.click();await new Promise(r=>setTimeout(r,400));});
console.log('=== entrée en exercice ===');
const e1=await p.evaluate(async()=>{
 document.getElementById('hdrMore').click();await new Promise(r=>setTimeout(r,250));
 const row=[...document.querySelectorAll('#moreMenu .mm-row')].find(x=>/Répéter en exercice/.test(x.textContent));
 if(!row)return {row:false};
 row.click();await new Promise(r=>setTimeout(r,450));
 const cb=document.getElementById('crisisBand');
 return {row:true,exo:cb.classList.contains('exo'),tag:cb.querySelector('.cb-tag').textContent,
  flag:Runtime.exercise,started:Runtime.started,
  hatch:getComputedStyle(cb).backgroundImage.includes('repeating')};});
t('« Répéter en exercice » au menu ⋯', e1.row);
t('bandeau HACHURÉ + « ▲ Exercice » (jamais confondable)', e1.exo&&/Exercice/.test(e1.tag)&&e1.hatch, JSON.stringify(e1));
t('le drapeau est posé AVANT le démarrage (session pas encore démarrée)', e1.flag&&!e1.started);
// v4.29.0 : le placard SUIT LE TITRE (retour utilisateur — hachurer le quai était illisible) :
// au défilement, l'EN-TÊTE prend la hachure (.ttl-on), le quai reste PROPRE.
const e1c=await p.evaluate(async()=>{
 window.scrollTo(0,700);await new Promise(r=>setTimeout(r,400));
 const h=document.querySelector('header.bar');
 const res={ttl:h.classList.contains('ttl-on'),exo:h.classList.contains('exo'),
  bg:getComputedStyle(h).backgroundImage.includes('repeating'),
  dockNet:getComputedStyle(document.getElementById('crisisDock')).backgroundImage==='none'};
 window.scrollTo(0,0);await new Promise(r=>setTimeout(r,300));
 return res;});
t('le placard SUIT LE TITRE : en-tête hachuré au défilement, quai PROPRE', e1c.ttl&&e1c.exo&&e1c.bg&&e1c.dockNet, JSON.stringify(e1c));
// Lisibilité des hachures DANS LES DEUX THÈMES (v4.28.0, retour utilisateur : surface/surface-2
// était quasi invisible en sombre) : delta mesuré entre les deux bandes (surface vs primary-soft).
const e1b=await p.evaluate(async()=>{
 const probe=c=>{const d=document.createElement('div');d.style.color=`var(${c})`;document.body.appendChild(d);
   const v=getComputedStyle(d).color;d.remove();return (v.match(/\d+/g)||[0,0,0]).slice(0,3).map(Number);};
 const delta=()=>{const a=probe('--surface'),b=probe('--primary-soft');return a.reduce((t2,x,i)=>t2+Math.abs(x-b[i]),0);};
 const dl=delta();
 document.documentElement.dataset.theme='dark';await new Promise(r=>setTimeout(r,120));
 const dd=delta();
 document.documentElement.dataset.theme='light';await new Promise(r=>setTimeout(r,120));
 return {dl,dd};});
t('hachures LISIBLES dans les deux thèmes (delta bande/bande ≥ 30, clair ET sombre)', e1b.dl>=30&&e1b.dd>=30, JSON.stringify(e1b));
const e2=await p.evaluate(async()=>{
 document.querySelector('.ov-block.cur ol.steps li').click();await new Promise(r=>setTimeout(r,400));
 return {started:Runtime.started,strip:document.getElementById('cbTimers').textContent,
  exoChip:!!document.querySelector('#cbTimers .seg.glb.exo'),
  snapExo:(sessions.find(x=>x.id===Runtime.sessionId)||{}).exercise};});
t('la 1ʳᵉ action démarre une session MARQUÉE exercise', e2.started&&e2.snapExo===true);
t('le chrono d’état dit « ▲ Exercice », pas « ● Session »', e2.exoChip&&/Exercice/.test(e2.strip)&&!/● Session/.test(e2.strip), e2.strip);
// BOUTON « Quitter l'exercice… » sur le placard (v4.28.0, demande utilisateur) : même dialogue
// que le menu ⋯, titre à la PORTÉE de l'action ; « Poursuivre » n'interrompt rien.
const e2b=await p.evaluate(async()=>{
 const qb=document.getElementById('cbExoQuit');
 const vis=!qb.hidden,txt=qb.textContent;
 qb.click();await new Promise(r=>setTimeout(r,350));
 const ttl=document.getElementById('endSessTitle').textContent;
 document.getElementById('endSessNo').click();await new Promise(r=>setTimeout(r,250));
 return {vis,txt,ttl,encore:Runtime.exercise&&Runtime.started};});
t('bouton « Quitter l’exercice… » sur le placard → dialogue « Terminer l’exercice ? »',
  e2b.vis&&/Quitter l’exercice/.test(e2b.txt)&&/Terminer l’exercice \?/.test(e2b.ttl), JSON.stringify(e2b));
t('« Poursuivre » n’interrompt rien (l’exercice continue)', e2b.encore);
// matière pour le compte-rendu : une complication + une passe de vérification avec écart
await p.evaluate(async()=>{
 document.querySelector('[data-cxopen]').click();await new Promise(r=>setTimeout(r,300));
 document.querySelector('#cxList .cx-item').click();await new Promise(r=>setTimeout(r,400));
 document.querySelector('[data-cxback]').click();await new Promise(r=>setTimeout(r,400));
 const vb=document.querySelector('.ov-block.cur [data-ovverify]');vb.click();await new Promise(r=>setTimeout(r,350));
 document.querySelector('[data-ovvok]').click();await new Promise(r=>setTimeout(r,250));
 document.querySelector('[data-ovvgap]').click();await new Promise(r=>setTimeout(r,250));
 const x=document.querySelector('[data-ovvx]');if(x)x.click();await new Promise(r=>setTimeout(r,350));});
console.log('=== terminer + débrief ===');
const e3=await p.evaluate(async()=>{
 document.getElementById('hdrMore').click();await new Promise(r=>setTimeout(r,250));
 const row=[...document.querySelectorAll('#moreMenu .mm-row')].find(x=>/Terminer l’exercice|Terminer l'exercice/.test(x.textContent));
 const lbl=row?row.textContent.replace(/\s+/g,' ').trim():null;
 if(row){row.click();await new Promise(r=>setTimeout(r,400));}
 const btn=[...document.querySelectorAll('.ai-modal.on button,.dlg-confirm.on button')].find(x=>/^Terminer/.test(x.textContent.trim()));
 if(btn){btn.click();await new Promise(r=>setTimeout(r,500));}
 const card=document.querySelector('.last-sess');
 return {lbl,carte:card?card.textContent.replace(/\s+/g,' ').trim().slice(0,60):null,exo:card&&card.classList.contains('exo')};});
t('le menu dit « Terminer l’exercice… »', !!e3.lbl&&/exercice/.test(e3.lbl), ''+e3.lbl);
t('carte-bilan « Exercice terminé », registre exercice', e3.exo&&/Exercice terminé/.test(e3.carte), ''+e3.carte);
const e4=await p.evaluate(async()=>{
 document.getElementById('lsrReport').click();await new Promise(r=>setTimeout(r,450));
 const h=document.getElementById('reportBody').innerHTML;
 const on=document.querySelector('#reportModal.on,.ai-modal.on #reportBody');
 document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',bubbles:true}));await new Promise(r=>setTimeout(r,250));
 return {wm:/class="wm">EXERCICE/.test(h),meta:/répétition sans patient/.test(h),
  cx:/⚡/.test(h)&&/Laryngospasme/.test(h),gap:/△ écart/.test(h),ver:/constatée/.test(h)};});
t('compte-rendu FILIGRANÉ « EXERCICE »', e4.wm&&e4.meta, JSON.stringify(e4));
t('compte-rendu : la complication ⚡ y figure (horodatée)', e4.cx);
t('compte-rendu : la trace do-verify y figure (constat + écart)', e4.gap&&e4.ver);
console.log('=== historique scindé + méta ===');
const e5=await p.evaluate(async()=>{
 openSessHist(window.__fid);await new Promise(r=>setTimeout(r,350));
 const gh=[...document.querySelectorAll('#sessBody .sess-gh')].map(x=>x.textContent);
 const badge=document.querySelectorAll('#sessBody .sess-exotag').length;
 closeSessHist();await new Promise(r=>setTimeout(r,200));
 return {gh,badge};});
t('historique : groupe « Exercices (1) », badge sur la rangée', e5.gh.some(x=>/Exercices \(1\)/.test(x))&&e5.badge===1, JSON.stringify(e5));
const e6=await p.evaluate(async()=>{
 openRead(window.__fid);await new Promise(r=>setTimeout(r,450));
 const pill=document.querySelector('.read-meta .tag.exo2');
 document.getElementById('hdrMore').click();await new Promise(r=>setTimeout(r,250));
 const row=[...document.querySelectorAll('#moreMenu .mm-row')].find(x=>/Répéter en exercice/.test(x.textContent));
 const sub=row?row.textContent.replace(/\s+/g,' '):'';
 document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',bubbles:true}));await new Promise(r=>setTimeout(r,200));
 return {pill:!!pill,sub,jamais:document.querySelector('main').textContent.indexOf('jamais répétée')>=0};});
t('méta SANS pastille exercice (v4.29.0 : elle captait l’œil pour rien) — la date vit au menu ⋯', e6.pill===false&&/dernier :/.test(e6.sub), JSON.stringify({pill:e6.pill,sub:e6.sub}));
t('AUCUN rappel « jamais répétée » nulle part (décision utilisateur)', e6.jamais===false);
console.log('=== session RÉELLE : rien ne change, compte-rendu enrichi aussi ===');
const e7=await p.evaluate(async()=>{
 document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,400));
 const cb=document.getElementById('crisisBand');
 const real={tag:cb.querySelector('.cb-tag').textContent,exo:cb.classList.contains('exo'),
   strip:document.getElementById('cbTimers').textContent};
 document.querySelector('[data-cxopen]').click();await new Promise(r=>setTimeout(r,300));
 document.querySelector('#cxList .cx-item').click();await new Promise(r=>setTimeout(r,400));
 endSession(Runtime);resetRuntime();state.fiche=null;state.view='library';render();await new Promise(r=>setTimeout(r,400));
 const card=document.querySelector('.last-sess');
 exportSessionReport(lastEndedSession.id);await new Promise(r=>setTimeout(r,400));
 const h=document.getElementById('reportBody').innerHTML;
 return {real,carte:card?card.textContent.slice(0,40):null,
  wm:/class="wm">EXERCICE/.test(h),cx:/⚡/.test(h)&&/Laryngospasme/.test(h)};});
t('session réelle : « ■ Mode crise » + « ● Session » inchangés', /Mode crise/.test(e7.real.tag)&&!e7.real.exo&&/● Session/.test(e7.real.strip), JSON.stringify(e7.real));
t('carte-bilan réelle : « Session terminée »', /Session terminée/.test(e7.carte||''), ''+e7.carte);
t('compte-rendu RÉEL : ⚡ complication restituée, SANS filigrane', e7.cx&&!e7.wm, JSON.stringify({cx:e7.cx,wm:e7.wm}));
await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
