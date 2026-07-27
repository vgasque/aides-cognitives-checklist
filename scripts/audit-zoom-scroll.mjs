/* AUDIT — HAUTEURS DE FENÊTRE SOUS ZOOM. `zoom` sur <html> agrandit une hauteur en vh/dvh APRÈS
   sa résolution : à 130 %, `100dvh` occupe 1,3 écran (bas inatteignable) et `min-height:100vh`
   crée du défilement dans le vide. Prouve que --zf corrige les deux. */
import { serveApp, moteur, NOM_MOTEUR, ROOT } from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();let ok=0,ko=0;
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
 // C. SONDE GÉNÉRIQUE (v4.32.0) — le harnais ne regardait que deux surfaces nommées, et cinq
 // `vh` NUS avaient traversé le balayage : `.lightbox img` (82vh) faisait sortir la légende de
 // 51 px à 130 %, sans défilement possible. On lit ici le CSS RÉSOLU de tout élément visible et
 // on échoue sur toute hauteur relative à la fenêtre qui la dépasse — indépendamment du nom.
 const c=await p.evaluate(()=>{
  const zf=parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--zf'))||1;
  const H=window.innerHeight;   // px VISUELS
  const bad=[];
  for(const e of document.querySelectorAll('*')){
   const cs=getComputedStyle(e);
   if(cs.display==='none'||cs.visibility==='hidden')continue;
   for(const prop of ['maxHeight','height','minHeight']){
    const v=cs[prop];
    if(!v||v==='none'||v.indexOf('px')<0)continue;
    // La valeur résolue est en px CSS ; à l'écran elle occupe v × zf px visuels.
    const px=parseFloat(v);
    if(!Number.isFinite(px)||px<=0)continue;
    if(px*zf>H+2){
     // Seules comptent les hauteurs BORNANTES (une height de contenu long est légitime si
     // l'élément défile) : on ne retient que ce qui n'a pas de défilement propre.
     const scrolls=/(auto|scroll)/.test(cs.overflowY);
     if(!scrolls)bad.push((e.id?'#'+e.id:'.'+String(e.className).split(' ')[0])+' '+prop+'='+v);
    }
   }
  }
  return {zf,H,bad:[...new Set(bad)].slice(0,6)};});
 t(`aucune hauteur bornante ne dépasse la fenêtre (balayage global)`, c.bad.length===0,
   `zf=${c.zf} fenêtre=${c.H} → ${c.bad.join(' | ')}`);
 await p.close();
}
await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
