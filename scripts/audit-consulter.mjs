/* AUDIT — LES CARTES DE CONSULTATION (A367 : la feuille « Consulter » a vécu). AVANT la session, la
   page porte les quatre cartes de la session (À vérifier, différentiels, repères, Références),
   FERMÉES d'office sous « Parcours » ; « Le tableau ne colle pas ? » ouvre la carte des
   différentiels SEULE (les autres repliées) et l'amène à l'écran ; « Documents · n » ouvre la carte
   Références. EN session la carte « Références » vit sous le bloc, sans les différentiels. Invariant
   du BOUTON MORT : pas de carte sans contenu, et plus AUCUN « Consulter » — ni quai, ni menu ⋯. */
import { serveApp, moteur, NOM_MOTEUR, ROOT, amorce, ouvrirFiche, demarrerSession } from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();const p=await br.newPage({viewport:{width:420,height:900},deviceScaleFactor:2});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
p.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
await p.goto(`http://localhost:${port}/index.html`);
await amorce(p);
await p.evaluate(()=>{const f=fiches.find(x=>/Arr.t cardiaque/.test(x.title));
 setList(f,'posology',['△ **ADRÉNALINE — IV** : 1 mg / 3–5 min','**AMIODARONE** : 300 mg']);
 f.docs=[{id:'zdoc1',name:'Protocole 2024',size:1024}];});
await ouvrirFiche(p,/Arr.t cardiaque/);
// AVANT LA SESSION : les cartes, fermées d'office, et les deux liens qui y mènent
const r=await p.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
 const etat=()=>Object.fromEntries([...document.querySelectorAll('.care-flat [data-prefold]')].map(b=>[b.dataset.prefold,b.closest('.fold-card,.cf-stage').classList.contains('closed')?'fermée':'ouverte']));
 const avant=etat();
 const al=document.getElementById('atypLink');if(al)al.click();await w(500);
 const apresDiff=etat();
 const diff=document.querySelector('[data-sf="diff"]');const rd=diff?diff.getBoundingClientRect():null;
 // A371 : sans pied de lecture, la page peut être trop courte pour amener la carte sous le chrome —
 // « en haut » vaut alors « au plancher du défilement » (la page ne peut pas aller plus loin).
 const se=document.scrollingElement;const auPlancher=se.scrollTop>=se.scrollHeight-innerHeight-1;
 // « Documents · n » vit dans « Parcours » : on l'ouvre pour l'atteindre
 const fb=document.querySelector('[data-prefold="flow"]');if(fb&&fb.getAttribute('aria-expanded')!=='true'){fb.click();await w(400);}
 const dl=document.querySelector('[data-prelink="docs"]');if(dl)dl.click();await w(500);
 const apresDocs=etat();
 const refs=document.querySelector('[data-sf="refs"]');
 document.getElementById('hdrMore').click();await w(300);
 const tuiles=[...document.querySelectorAll('#moreMenu .mm-tile')].map(x=>x.textContent.trim());closeMoreMenu();
 return {avant,apresDiff,diffEnHaut:rd?(rd.top>=0&&(rd.top<200||auPlancher)):null,apresDocs,refsDocs:!!(refs&&refs.querySelector('[data-att]')),tuiles,feuille:!!document.getElementById('refModal')};});
t('avant la session, Parcours et les quatre cartes sont FERMÉES d’office', ['flow','verify','diff','pos','refs'].every(k=>r.avant[k]==='fermée'), JSON.stringify(r.avant));
t('« Quand l’utiliser » et « Ne pas oublier » restent ouvertes d’office', r.avant.when==='ouverte'&&r.avant.forget==='ouverte', JSON.stringify(r.avant));
t('« Le tableau ne colle pas ? » ouvre la carte des différentiels SEULE', r.apresDiff.diff==='ouverte'&&Object.entries(r.apresDiff).every(([k,v])=>k==='diff'||v==='fermée'), JSON.stringify(r.apresDiff));
t('… et l’amène en haut de l’écran (ou au plancher du défilement, page courte)', r.diffEnHaut===true, JSON.stringify(r.diffEnHaut));
t('« Documents · n » ouvre la carte Références, qui porte les documents', r.apresDocs.refs==='ouverte'&&r.refsDocs===true, JSON.stringify(r.apresDocs));
t('plus aucune tuile « Consulter » au menu ⋯, plus de feuille dans le document', !r.tuiles.some(x=>/Consulter/.test(x))&&r.feuille===false, JSON.stringify(r.tuiles));
// EN SESSION : la carte « Références », et plus aucun « Consulter »
await demarrerSession(p);
const s=await p.evaluate(async()=>{const c=document.querySelector('[data-sf="refs"]');
 const head=c&&c.querySelector('[data-sessfold]');if(head&&c.classList.contains('closed'))head.click();await new Promise(r=>setTimeout(r,300));
 return {carte:!!c,ouverte:!!c&&!c.classList.contains('closed'),
  secs:c?[...c.querySelectorAll('.rs-sec summary')].map(x=>x.textContent.trim()):[],
  quai:[...document.querySelectorAll('#sessionDock .sd-in button')].filter(b=>!b.hidden).map(b=>b.textContent.trim())};});
t('en session, une carte « Références » vit sous le bloc', s.carte===true);
t('… qui s’ouvre d’un tap et porte le contenu SANS les différentiels', s.ouverte===true&&s.secs.length>=1&&!s.secs.some(x=>/Diagnostics/.test(x)), JSON.stringify(s.secs));
t('… et « Consulter » n’est pas au quai', !s.quai.some(x=>/Consulter/.test(x)), JSON.stringify(s.quai));
t('la posologie reste dans le flux (téléphone)', await p.evaluate(()=>document.querySelector('#main').textContent.indexOf('ADRÉNALINE')>=0));
// INVARIANT : pas de carte sans contenu
const vide=await p.evaluate(async()=>{const f=state.fiche;
 setList(f,'differentials',[]);f.images=[];f.docs=[];f.sources=[];f.links=[];
 render();await new Promise(r=>setTimeout(r,400));
 return {carte:!!document.querySelector('[data-sf="refs"]'),poso:clean(listOf(f,'posology')).length};});
t('fiche SANS contenu à consulter : aucune carte Références morte', vide.carte===false, JSON.stringify(vide));
await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
