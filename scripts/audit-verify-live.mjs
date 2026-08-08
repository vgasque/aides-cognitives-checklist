/* AUDIT — RETOUR IMMÉDIAT DU MODE VÉRIFIER + registre des blocs de décision + taille des options. */
import { serveApp, moteur, NOM_MOTEUR, ROOT, amorce, ouvrirFiche, demarrerSession } from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();const p=await br.newPage({viewport:{width:1000,height:900},deviceScaleFactor:2});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
await p.goto(`http://localhost:${port}/index.html`);
await amorce(p);
await ouvrirFiche(p,/Arr.t cardiaque/);
await demarrerSession(p);
// B. taille des options : avancer jusqu'au bloc décision
await p.evaluate(async()=>{document.querySelectorAll('.ov-block.cur ol.steps li:not(.done)').forEach(li=>li.click());await new Promise(r=>setTimeout(r,200));
 const nb=document.querySelector('.ov-block.cur [data-ovnext]');if(nb)nb.click();await new Promise(r=>setTimeout(r,400));});
/* v5.6 — L'INVARIANT SE PRÉCISE AU LIEU DE DISPARAÎTRE. Il disait « une option de branche a la
   MÊME taille qu'une étape » (16,5 px des deux côtés), et son motif était : « choisir une branche
   engage AU MOINS AUTANT que cocher une étape ». La refonte hiérarchise les étapes par le corps
   (ordinaire --t-item, critique --t-step) : l'égalité stricte n'a donc plus de sens, mais le
   motif, lui, en a toujours — et davantage, puisque sur un bloc de décision il n'y a PAS de
   « Continuer » : la décision EST l'avancement. On mesure donc ce que la règle voulait dire. */
const b=await p.evaluate(()=>{const o=document.querySelector('.opt'),st=document.querySelector('ol.steps li .txt');
 /* Le bloc courant peut être une DÉCISION : il n'y a alors aucune étape à l'écran. On retombe
    sur le cran de l'échelle qu'une étape ordinaire emploie (--t-item) — la référence est le
    SYSTÈME, pas la présence fortuite d'un élément. */
 const item=getComputedStyle(document.documentElement).getPropertyValue('--t-item').trim();
 return {opt:o?getComputedStyle(o).fontSize:null,step:st?getComputedStyle(st).fontSize:(item||null)};});
t('option de branche AU MOINS aussi grande qu\'une étape',
  !!b.opt&&!!b.step&&parseFloat(b.opt)>=parseFloat(b.step), JSON.stringify(b));
// A. bordure du bloc décision COURANT = ambre
const a=await p.evaluate(()=>{const d=document.querySelector('.ov-block.dec.cur');if(!d)return null;
 const cs=getComputedStyle(d);
 return {bord:cs.borderLeftColor,cur:d.getAttribute('aria-current'),
   seulOuvert:document.querySelectorAll('.ov-block:not(.closed)').length};});
/* Le REGISTRE prime sur l'état : un bloc de décision courant garde sa bordure ambre — la position,
   elle, passe par un AUTRE canal (un canal par signification, v4.24.0). --verify-bd pointe
   désormais sur --warn-line, la fusion des deux ambres (lot 1). */
t('bloc décision COURANT : bordure ambre (--warn-line), pas bleue', a&&a.bord==='rgb(180, 83, 9)', JSON.stringify(a));
/* A12 (v5.6) — « ICI » N'EXISTE PLUS QUE DANS UNE LISTE. Sur la carte il était redondant avec
   trois signaux déjà présents ; ce qui doit rester VÉRIFIABLE, c'est qu'un de ces canaux porte
   effectivement la position, et le plus fort des trois est aussi le seul lisible par un lecteur
   d'écran : `aria-current="step"`. On mesure la propriété, plus la pilule qui la portait. */
t('la position reste marquée — aria-current sur le bloc courant', a&&a.cur==='step', JSON.stringify(a));
// C. mode Vérifier : retour immédiat
await p.evaluate(async()=>{const opt=document.querySelector('.opt');if(opt)opt.click();await new Promise(r=>setTimeout(r,400));
 // cocher UNE étape AVANT la vérification (cas décrit : ne doit pas afficher ✓ trompeur)
 const li=document.querySelector('.ov-block.cur ol.steps li');if(li)li.click();await new Promise(r=>setTimeout(r,250));
 const vb=document.querySelector('.ov-block.cur [data-ovverify]');if(vb)vb.click();await new Promise(r=>setTimeout(r,400));});
const c0=await p.evaluate(()=>{const r=[...document.querySelectorAll('.vstp')];
 return {tally:(document.querySelector('.v-tally')||{}).textContent||null,
   marqueurs:r.map(x=>x.querySelector('.vst').textContent.trim()),tags:r.map(x=>(x.querySelector('.v-tag')||{}).textContent||'')};});
t('bilan VIVANT affiché dès l’ouverture de la passe', !!c0.tally&&/constat/.test(c0.tally), ''+c0.tally);
t('une étape cochée AVANT la passe n’affiche pas de ✓ trompeur', !c0.tags.some(x=>x==='constaté'), JSON.stringify(c0.tags));
// « Constaté ✓ » puis « △ Écart »
await p.evaluate(async()=>{document.querySelector('[data-ovvok]').click();await new Promise(r=>setTimeout(r,300));});
const c1=await p.evaluate(()=>({tally:document.querySelector('.v-tally').textContent,tags:[...document.querySelectorAll('.v-tag')].map(x=>x.textContent)}));
t('« Constaté » s’affiche IMMÉDIATEMENT sur l’étape', c1.tags.some(x=>/constaté/.test(x)), JSON.stringify(c1.tags));
t('le bilan vivant se met à jour', /1 constaté/.test(c1.tally), c1.tally);
await p.evaluate(async()=>{document.querySelector('[data-ovvgap]').click();await new Promise(r=>setTimeout(r,300));});
const c2=await p.evaluate(()=>({tally:document.querySelector('.v-tally').textContent,tags:[...document.querySelectorAll('.v-tag')].map(x=>x.textContent)}));
t('« Écart » s’affiche IMMÉDIATEMENT', c2.tags.some(x=>/écart/.test(x)), JSON.stringify(c2.tags));
// v4.25.2 — MÊME vocabulaire pendant et après la passe, et AUCUN bandeau ambre sur l'étape :
// le liseré inset appartient au REGISTRE (⚠/△), pas à l'état de la passe.
{const sortie=await p.evaluate(async()=>{const x=document.querySelector('[data-ovvx]');if(x)x.click();
   await new Promise(r=>setTimeout(r,450));
   const li=document.querySelector('ol.steps li.vgap');
   return {apres:[...document.querySelectorAll('.stp-vf')].map(e=>e.textContent),
     bandeau:li?getComputedStyle(li).boxShadow:'aucune ligne en écart'};});
 t('le libellé est IDENTIQUE pendant et après la passe',
   sortie.apres.some(x=>/constaté/.test(x))&&!sortie.apres.some(x=>/vérifié/.test(x)), JSON.stringify(sortie.apres));
 t('aucun bandeau ambre sur l’étape en écart (canal du registre préservé)',
   sortie.bandeau==='none'||/aucune/.test(sortie.bandeau), ''+sortie.bandeau);}
t('le bilan annonce l’écart sans attendre la fin', /1 écart/.test(c2.tally), c2.tally);

await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
