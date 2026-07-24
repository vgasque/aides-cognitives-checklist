/* AUDIT — HAUTEURS DE FENÊTRE SOUS ZOOM. `zoom` sur <html> agrandit une hauteur en vh/dvh APRÈS
   sa résolution : à 130 %, `100dvh` occupe 1,3 écran (bas inatteignable) et `min-height:100vh`
   crée du défilement dans le vide. Prouve que --zf corrige les deux. */
import { createServer } from 'node:http';import { readFile } from 'node:fs/promises';import { extname } from 'node:path';import { chromium } from 'playwright';
const ROOT=decodeURIComponent(new URL('../',import.meta.url).pathname);
const T={'.html':'text/html','.js':'text/javascript','.json':'application/json','.webmanifest':'application/manifest+json','.png':'image/png','.svg':'image/svg+xml','.ico':'image/x-icon'};
const srv=createServer(async(q,r)=>{try{let p=decodeURIComponent(q.url.split('?')[0]);if(p==='/')p='/index.html';const b=await readFile(ROOT+p.replace(/^\/+/,''));r.writeHead(200,{'content-type':T[extname(p)]||'application/octet-stream'});r.end(b);}catch{r.writeHead(404);r.end('nf');}});
const port=await new Promise(r=>srv.listen(0,()=>r(srv.address().port)));
const br=await chromium.launch();let ok=0,ko=0;
const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
for(const z of [100,130]){
 const p=await br.newPage({viewport:{width:1200,height:800}});
 await p.goto(`http://localhost:${port}/index.html`);await p.waitForFunction(()=>!document.querySelector('.boot-load'));
 await p.evaluate(async(z)=>{const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await new Promise(r=>setTimeout(r,150));
  const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await new Promise(r=>setTimeout(r,400));
  applyZoom(z);await new Promise(r=>setTimeout(r,350));},z);
 console.log(`\n=== zoom ${z}% ===`);
 // A. sidebar de l'ACCUEIL : peut-on atteindre le bas ?
 const a=await p.evaluate(()=>{const s=document.querySelector('.home-side');if(!s)return null;
  s.scrollTop=999999;
  const r=s.getBoundingClientRect();   // px VISUELS déjà (règle v4.13.1) : aucune multiplication
  return {atteint:Math.round(s.scrollTop)>=Math.round(s.scrollHeight-s.clientHeight)-2,
    basVisuel:Math.round(r.bottom), fenetre:window.innerHeight, deborde:Math.round(r.bottom)-window.innerHeight};});
 t(`accueil : le bas de la sidebar est DANS la fenêtre`, a&&a.deborde<=4, JSON.stringify(a));
 // B. page COURTE : pas de défilement dans le vide
 const b2=await p.evaluate(async()=>{
  // ouvrir un protocole court
  const seg=[...document.querySelectorAll('.seg-btn,[data-section]')].find(x=>/Protocole/i.test(x.textContent));
  if(seg){seg.click();await new Promise(r=>setTimeout(r,350));}
  const c=document.querySelector('.card-open');if(c){c.click();await new Promise(r=>setTimeout(r,400));}
  const doc=document.documentElement;
  // scrollHeight/clientHeight sont dans le MÊME repère (px CSS) : leur différence est l'excédent réel.
  return {scrollable:Math.round(doc.scrollHeight-doc.clientHeight)};});
 t(`page courte : pas de défilement dans le vide (excédent ≤ 40px)`, b2.scrollable<=40, 'excédent='+b2.scrollable+'px');
 await p.close();
}
await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
