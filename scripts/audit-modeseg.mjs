/* AUDIT — PASTILLE DES SÉLECTEURS SEGMENTÉS. Trois pièges cumulés, tous mesurés à l'origine sur
   la bascule de mode : `gap:8px` hérité de `.seg` (même spécificité, déclarée plus bas → elle
   gagnait par l'ORDRE), `min-width:auto` des items flex qui empêche `flex:1 1 0` d'égaliser deux
   libellés de longueurs différentes (d'où la grille `1fr 1fr`), et un fond de pastille qui
   S'INVERSE entre thèmes.
   ⚠ LE SUJET A CHANGÉ DE PORTEUR, PAS DE NATURE (v5.0.0, lot A). `#modeSeg` est SUPPRIMÉ : prendre
   du recul pendant un soin est une EXCURSION (« ⤢ Tout voir » / « ↩ Un bloc »), pas un sélecteur
   de format. Supprimer ce harnais avec lui aurait emporté trois invariants qui n'ont rien à voir
   avec la crise et qui valent pour TOUS les segmentés du fichier — c'est la leçon
   `audit-lecteur` → `audit-retour` (v5.0.0, lot T14) : on TAILLE, on ne jette pas.
   Il mesure donc désormais `#dispSeg` (Compte › Affichage — le réglage à froid qui a remplacé la
   bascule de crise), qui est le même composant à deux crans, et il garde les trois contrôles. */
import { serveApp, moteur, amorce } from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();let KO=0;
for(const TH of ['light','dark']){
const p=await br.newPage({viewport:{width:900,height:800},colorScheme:TH,deviceScaleFactor:2});
await p.goto(`http://localhost:${port}/index.html`);
await amorce(p);
/* ⚠ ON OUVRE PAR LE VRAI POINT D'ENTRÉE (doctrine v4.40.0) : la fenêtre Compte se construit à
   l'ouverture, et un état reconstruit à la main donnerait un sélecteur sans son câblage. */
await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
 setReadModePref('overview');openAuth();await w(700);});
const m=async()=>p.evaluate(()=>{const sg=document.getElementById('dispSeg');
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
console.log(`\n=== thème ${TH} ===`);console.log('  1er cran actif :',JSON.stringify(a));
await p.evaluate(async()=>{document.querySelector('#dispSeg [data-disp="static"]').click();await new Promise(r=>setTimeout(r,500));});
const b=await m();
console.log('  2e cran actif  :',JSON.stringify(b));
const ok=Math.abs(a.ecartX)<=2&&Math.abs(a.ecartL)<=2&&Math.abs(b.ecartX)<=2&&Math.abs(b.ecartL)<=2;
console.log(ok?'  ✓ la pastille épouse le segment actif':`  ✗ DÉCALAGE : x ${a.ecartX}/${b.ecartX} px · largeur ${a.ecartL}/${b.ecartL} px`);
if(!ok)KO++;
/* v4.29.0 — les LIBELLÉS ne bougent pas d'un pixel à la bascule (la graisse 700→800 les
   élargissait : « le texte se décale », retour utilisateur). Mesure : mêmes boîtes avant/après. */
const shift=Math.max(...a.boutons.flatMap((x,i)=>[Math.abs(x.x-b.boutons[i].x),Math.abs(x.l-b.boutons[i].l)]));
console.log(shift<=0.5?'  ✓ libellés immobiles à la bascule (0 px)':`  ✗ LIBELLÉS DÉCALÉS : ${shift} px`);
if(shift>0.5)KO++;
/* v4.29.0 — GLISSER la pastille (HIG iOS) : drag de gauche à droite -> second cran. */
await p.evaluate(async()=>{document.querySelector('#dispSeg [data-disp="overview"]').click();await new Promise(r=>setTimeout(r,400));});
/* ⚠ ON AMÈNE LE SÉLECTEUR À L'ÉCRAN AVANT DE LE SAISIR (v5.6). La fenêtre Compte s'est allongée
   — « Affichage » y porte désormais le thème EN PLUS du format et de la taille du texte — et
   `#dispSeg` naissait à y=778 sur une fenêtre de 800 : le point de prise tombait HORS du
   viewport, la souris n'atteignait rien, et le contrôle rougissait sur un geste qui n'avait pas
   eu lieu. Un utilisateur fait défiler ; le témoin aussi, sinon il mesure sa propre géométrie et
   non l'application. */
await p.locator('#dispSeg').scrollIntoViewIfNeeded();await p.waitForTimeout(120);
const sb=await p.locator('#dispSeg').boundingBox();
await p.mouse.move(sb.x+15,sb.y+sb.height/2);await p.mouse.down();
await p.mouse.move(sb.x+sb.width-8,sb.y+sb.height/2,{steps:8});await p.mouse.up();
await p.waitForTimeout(600);
const drag=await p.evaluate(()=>currentReadMode());
console.log(drag==='static'?'  ✓ drag de la pastille -> 2e cran (commit au relâchement)':`  ✗ drag sans effet (préférence=${drag})`);
if(drag!=='static')KO++;
await p.close();}
await br.close();srv.close();
console.log(KO?`\n${KO} thème(s) en échec`:'\n2/2 thèmes OK — pastille alignée');
process.exit(KO?1:0);
