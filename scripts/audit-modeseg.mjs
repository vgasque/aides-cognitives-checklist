/* AUDIT — PASTILLE DU SÉLECTEUR DE MODE. Trois pièges cumulés, tous mesurés : `gap:8px` hérité de
   `.seg` (même spécificité, déclarée plus bas -> elle gagnait par l'ORDRE), `min-width:auto` des
   items flex qui empêche `flex:1 1 0` d'égaliser deux libellés de longueurs différentes (d'où la
   grille `1fr 1fr`), et un fond de pastille qui s'INVERSE entre thèmes. */
import { createServer } from 'node:http';import { readFile } from 'node:fs/promises';import { extname } from 'node:path';import { chromium } from 'playwright';
const ROOT=decodeURIComponent(new URL('../',import.meta.url).pathname);
const T={'.html':'text/html','.js':'text/javascript','.json':'application/json','.webmanifest':'application/manifest+json','.png':'image/png','.svg':'image/svg+xml','.ico':'image/x-icon'};
const srv=createServer(async(q,r)=>{try{let p=decodeURIComponent(q.url.split('?')[0]);if(p==='/')p='/index.html';const b=await readFile(ROOT+p.replace(/^\/+/,''));r.writeHead(200,{'content-type':T[extname(p)]||'application/octet-stream'});r.end(b);}catch{r.writeHead(404);r.end('nf');}});
const port=await new Promise(r=>srv.listen(0,()=>r(srv.address().port)));
const br=await chromium.launch();let KO=0;
for(const TH of ['light','dark']){
const p=await br.newPage({viewport:{width:900,height:800},colorScheme:TH,deviceScaleFactor:2});
await p.goto(`http://localhost:${port}/index.html`);await p.waitForFunction(()=>!document.querySelector('.boot-load'));
await p.evaluate(async()=>{const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await new Promise(r=>setTimeout(r,150));
 const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await new Promise(r=>setTimeout(r,400));
 [...document.querySelectorAll('.card-open')].find(x=>/Arr.t cardiaque/.test(x.textContent)).click();await new Promise(r=>setTimeout(r,450));});
const m=async()=>p.evaluate(()=>{const sg=document.getElementById('modeSeg');
 const pill=sg.querySelector('.seg-pill'),btns=[...sg.querySelectorAll('.seg-btn')];
 const S=sg.getBoundingClientRect(),P=pill.getBoundingClientRect();
 const B=btns.map(b=>b.getBoundingClientRect());
 const on=btns.findIndex(b=>b.classList.contains('on'));
 const cb=getComputedStyle(btns[0]);return {gap:getComputedStyle(sg).gap,flexBtn:cb.flex,dispSeg:getComputedStyle(sg).display,pillW:getComputedStyle(pill).width,
   pastille:{x:Math.round(P.left-S.left),l:Math.round(P.width)},
   boutons:B.map(b=>({x:Math.round(b.left-S.left),l:Math.round(b.width)})),
   actif:on,
   ecartX:Math.round(P.left-B[on].left),ecartL:Math.round(P.width-B[on].width)};});
const a=await m();
console.log(`\n=== thème ${TH} ===`);console.log('  GUIDÉ actif  :',JSON.stringify(a));
await p.evaluate(async()=>{[...document.querySelectorAll('#modeSeg [data-readmode]')].find(x=>x.dataset.readmode==='static').click();await new Promise(r=>setTimeout(r,600));});
const b=await m();
console.log('  STATIQUE actif:',JSON.stringify(b));
const ok=Math.abs(a.ecartX)<=2&&Math.abs(a.ecartL)<=2&&Math.abs(b.ecartX)<=2&&Math.abs(b.ecartL)<=2;
console.log(ok?'  ✓ la pastille épouse le segment actif':`  ✗ DÉCALAGE : x ${a.ecartX}/${b.ecartX} px · largeur ${a.ecartL}/${b.ecartL} px`);
if(!ok)KO++;
await p.close();}
await br.close();srv.close();
console.log(KO?`\n${KO} thème(s) en échec`:'\n2/2 thèmes OK — pastille alignée');
process.exit(KO?1:0);
