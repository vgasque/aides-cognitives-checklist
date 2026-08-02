/* AUDIT — CARTE-BILAN DE FIN DE SESSION. Deux régressions constatées à l'usage : le ✕ existait
   mais était invisible (position:absolute sans ancêtre positionné), et la carte survivait à la
   SUPPRESSION de sa session dans l'historique (son bouton « Compte-rendu » menait alors à un
   rapport introuvable). */
import { serveApp, moteur, NOM_MOTEUR, ROOT, amorce, ouvrirFiche, demarrerSession } from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();const p=await br.newPage({viewport:{width:1000,height:820},deviceScaleFactor:2});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?'\n      '+d:''));}};
await p.goto(`http://localhost:${port}/index.html`);
await amorce(p);
// démarrer puis terminer une session -> carte-bilan
await ouvrirFiche(p,/Arr.t cardiaque/);
await demarrerSession(p);
await p.evaluate(async()=>{endSession(Runtime);resetRuntime();state.fiche=null;state.view='library';render();await new Promise(r=>setTimeout(r,500));});
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
/* v4.29.2 (retour utilisateur) : sur PETIT écran la carte passe en plusieurs lignes et le ✕
   « dans le flux » (contournement v4.23.2) atterrissait AU MILIEU, collé à « Compte-rendu ».
   Le ✕ est désormais ANCRÉ en haut à droite (carte position:relative) — vérifié en étroit. */
const rN=await p.evaluate(async()=>{
 const old=[window.innerWidth,window.innerHeight];return old;});
await p.setViewportSize({width:360,height:740});await p.waitForTimeout(300);
const rEtroit=await p.evaluate(()=>{const c=document.querySelector('.last-sess');if(!c)return null;
 const x=c.querySelector('.notice-x');const cr=c.getBoundingClientRect(),xr=x.getBoundingClientRect();
 return {hautDroit:(xr.top-cr.top)<=14&&(cr.right-xr.right)<=14,
   dansLaCarte:xr.right<=cr.right+1&&xr.top>=cr.top-1&&xr.bottom<=cr.bottom+1};});
t('360 px : le ✕ est ancré au COIN HAUT-DROIT de la carte', rEtroit&&rEtroit.hautDroit&&rEtroit.dansLaCarte, JSON.stringify(rEtroit));
await p.setViewportSize({width:1000,height:820});await p.waitForTimeout(300);
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
