/* AUDIT — PASTILLE DU SÉLECTEUR DE MODE. Trois pièges cumulés, tous mesurés : `gap:8px` hérité de
   `.seg` (même spécificité, déclarée plus bas -> elle gagnait par l'ORDRE), `min-width:auto` des
   items flex qui empêche `flex:1 1 0` d'égaliser deux libellés de longueurs différentes (d'où la
   grille `1fr 1fr`), et un fond de pastille qui s'INVERSE entre thèmes. */
import { serveApp, moteur, NOM_MOTEUR, ROOT } from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();let KO=0;
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
/* v4.29.0 — les LIBELLÉS ne bougent pas d'un pixel à la bascule (la graisse 700→800 les
   élargissait : « le texte se décale », retour utilisateur). Mesure : mêmes boîtes avant/après. */
const shift=Math.max(...a.boutons.flatMap((x,i)=>[Math.abs(x.x-b.boutons[i].x),Math.abs(x.l-b.boutons[i].l)]));
console.log(shift<=0.5?'  ✓ libellés immobiles à la bascule (0 px)':`  ✗ LIBELLÉS DÉCALÉS : ${shift} px`);
if(shift>0.5)KO++;
/* v4.29.0 — GLISSER la pastille (HIG iOS) : drag de gauche à droite -> mode statique. */
await p.evaluate(async()=>{[...document.querySelectorAll('#modeSeg [data-readmode]')].find(x=>x.dataset.readmode==='dynamic').click();await new Promise(r=>setTimeout(r,500));});
const sb=await p.locator('#modeSeg').boundingBox();
await p.mouse.move(sb.x+25,sb.y+sb.height/2);await p.mouse.down();
await p.mouse.move(sb.x+sb.width-15,sb.y+sb.height/2,{steps:8});await p.mouse.up();
await p.waitForTimeout(600);
const drag=await p.evaluate(()=>state.readMode);
console.log(drag==='static'?'  ✓ drag de la pastille -> Statique (commit au relâchement)':`  ✗ drag sans effet (readMode=${drag})`);
if(drag!=='static')KO++;
await p.close();}
await br.close();srv.close();
console.log(KO?`\n${KO} thème(s) en échec`:'\n2/2 thèmes OK — pastille alignée');
process.exit(KO?1:0);
