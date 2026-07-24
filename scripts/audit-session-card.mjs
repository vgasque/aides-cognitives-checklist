/* AUDIT — CARTE-BILAN DE FIN DE SESSION. Deux régressions constatées à l'usage : le ✕ existait
   mais était invisible (position:absolute sans ancêtre positionné), et la carte survivait à la
   SUPPRESSION de sa session dans l'historique (son bouton « Compte-rendu » menait alors à un
   rapport introuvable). */
import { createServer } from 'node:http';import { readFile } from 'node:fs/promises';import { extname } from 'node:path';import { chromium } from 'playwright';
const ROOT=decodeURIComponent(new URL('../',import.meta.url).pathname);
const T={'.html':'text/html','.js':'text/javascript','.json':'application/json','.webmanifest':'application/manifest+json','.png':'image/png','.svg':'image/svg+xml','.ico':'image/x-icon'};
const srv=createServer(async(q,r)=>{try{let p=decodeURIComponent(q.url.split('?')[0]);if(p==='/')p='/index.html';const b=await readFile(ROOT+p.replace(/^\/+/,''));r.writeHead(200,{'content-type':T[extname(p)]||'application/octet-stream'});r.end(b);}catch{r.writeHead(404);r.end('nf');}});
const port=await new Promise(r=>srv.listen(0,()=>r(srv.address().port)));
const br=await chromium.launch();const p=await br.newPage({viewport:{width:1000,height:820},deviceScaleFactor:2});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?'\n      '+d:''));}};
await p.goto(`http://localhost:${port}/index.html`);await p.waitForFunction(()=>!document.querySelector('.boot-load'));
await p.evaluate(async()=>{const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await new Promise(r=>setTimeout(r,150));
 const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await new Promise(r=>setTimeout(r,450));
 // démarrer puis terminer une session -> carte-bilan
 [...document.querySelectorAll('.card-open')].find(x=>/Arr.t cardiaque/.test(x.textContent)).click();await new Promise(r=>setTimeout(r,350));
 document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,350));
 endSession(Runtime);resetRuntime();state.fiche=null;state.view='library';render();await new Promise(r=>setTimeout(r,500));});
const r=await p.evaluate(()=>{const c=document.querySelector('.last-sess');if(!c)return null;
 const x=c.querySelector('.notice-x');const cr=c.getBoundingClientRect(),xr=x.getBoundingClientRect();
 const cs=getComputedStyle(x);
 return {carte:true,pos:cs.position,
   dansLaCarte:xr.left>=cr.left-1&&xr.right<=cr.right+1&&xr.top>=cr.top-1&&xr.bottom<=cr.bottom+1,
   visible:xr.width>0&&xr.height>0&&cs.display!=='none',
   auPointDuClic:(()=>{const e=document.elementFromPoint(xr.left+xr.width/2,xr.top+xr.height/2);
     return e===x||x.contains(e);})(),
   taille:Math.round(xr.width)+'×'+Math.round(xr.height)};});
console.log('\n=== ✕ de la carte-bilan ===');
t('la carte-bilan s’affiche', !!r, JSON.stringify(r));
t('le ✕ est DANS la carte', r&&r.dansLaCarte, JSON.stringify(r));
t('le ✕ est visible et cliquable', r&&r.visible&&r.auPointDuClic, JSON.stringify(r));
// le ✕ ferme
const r2=await p.evaluate(async()=>{document.querySelector('.last-sess .notice-x').click();await new Promise(r=>setTimeout(r,300));
 return !!document.querySelector('.last-sess');});
t('le ✕ ferme la carte', r2===false);
console.log('\n=== suppression de la session dans l’historique ===');
const r3=await p.evaluate(async()=>{
 // refaire une session terminée
 [...document.querySelectorAll('.card-open')].find(x=>/Arr.t cardiaque/.test(x.textContent)).click();await new Promise(r=>setTimeout(r,300));
 document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,300));
 endSession(Runtime);resetRuntime();state.fiche=null;state.view='library';render();await new Promise(r=>setTimeout(r,450));
 const avant=!!document.querySelector('.last-sess');
 const id=lastEndedSession&&lastEndedSession.id;
 // supprimer la session de l'historique (chemin réel : Data.delSession + filtre + render)
 try{await Data.delSession(id);}catch(e){}
 sessions=sessions.filter(x=>x.id!==id);
 render();await new Promise(r=>setTimeout(r,300));
 return {avant,apres:!!document.querySelector('.last-sess'),refRestante:!!lastEndedSession};});
t('la carte était bien là avant suppression', r3.avant);
t('la carte DISPARAÎT quand sa session est supprimée', r3.apres===false, JSON.stringify(r3));
t('la référence en mémoire est effacée', r3.refRestante===false, JSON.stringify(r3));
await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
