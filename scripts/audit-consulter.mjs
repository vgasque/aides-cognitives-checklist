/* AUDIT — « CONSULTER » : AVANT la session, une feuille (menu ⋯) qui ne porte QUE ce qui n'existe
   nulle part ailleurs (57 % de sa hauteur était de la redite — surveillances, posologie —, qui
   repoussait le contenu unique) ; EN session (v5.30, A354), le même contenu vit dans la carte
   dépliable « Références » sous le bloc, sans les différentiels (qui ont leur carte), et ni le quai
   ni le bas de fiche ne portent plus de « Consulter ». Verrouille aussi l'invariant du BOUTON MORT :
   la porte du menu et la carte n'existent que si la fiche a réellement du contenu à consulter. */
import { serveApp, moteur, NOM_MOTEUR, ROOT, amorce, ouvrirFiche, demarrerSession } from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();const p=await br.newPage({viewport:{width:420,height:900},deviceScaleFactor:2});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
p.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
await p.goto(`http://localhost:${port}/index.html`);
await amorce(p);
await p.evaluate(()=>{const f=fiches.find(x=>/Arr.t cardiaque/.test(x.title));
 /* v5.0.0, étape B — `posology`, `verify` et `differentials` ne sont plus des CHAMPS mais des
    RÔLES du pool `items`. Les écraser ne faisait plus rien : la sonde croyait vider la fiche et
    mesurait une fiche pleine. On passe par `setList`, l'écriture réelle. */
 setList(f,'posology',['△ **ADRÉNALINE — IV** : 1 mg / 3–5 min','**AMIODARONE** : 300 mg']);});
await ouvrirFiche(p,/Arr.t cardiaque/);
// AVANT LA SESSION : la feuille, par sa porte réelle (la tuile « Consulter » du menu ⋯ appelle openRefSheet)
await p.evaluate(async()=>{openRefSheet();await new Promise(r=>setTimeout(r,500));});
const r=await p.evaluate(()=>{const secs=[...document.querySelectorAll('#refModal .rs-sec')];
 let h=0;secs.forEach(s=>h+=s.getBoundingClientRect().height);
 return {ordre:secs.map(s=>s.dataset.rs),hauteur:Math.round(h),ouverte:refSheetOpen()};});
console.log('  composition :',JSON.stringify(r.ordre),'· hauteur',r.hauteur+'px');
t('la feuille s’ouvre avant la session', r.ouverte===true);
t('plus de section « Surveillances »', !r.ordre.includes('verify'), JSON.stringify(r.ordre));
t('plus de section « Posologie »', !r.ordre.includes('poso'), JSON.stringify(r.ordre));
t('les différentiels restent EN TÊTE', r.ordre[0]==='diff', JSON.stringify(r.ordre));
t('la feuille est nettement plus courte (< 500 px ici)', r.hauteur<500, r.hauteur+'px');
await p.evaluate(async()=>{closeRefSheet();await new Promise(r=>setTimeout(r,300));});
// EN SESSION : la carte « Références », et plus aucun « Consulter »
await demarrerSession(p);
const s=await p.evaluate(async()=>{const c=document.querySelector('[data-sf="refs"]');
 const head=c&&c.querySelector('[data-sessfold]');if(head)head.click();await new Promise(r=>setTimeout(r,300));
 return {carte:!!c,ouverte:!!c&&!c.classList.contains('closed'),
  secs:c?[...c.querySelectorAll('.rs-sec')].map(x=>x.dataset.rs):[],
  refBtn:!!document.getElementById('refBtn'),annex:!!document.getElementById('annexRow'),
  quai:[...document.querySelectorAll('#sessionDock .sd-in button')].filter(b=>!b.hidden).map(b=>b.textContent.trim()),
  feuille:refSheetOpen()};});
t('en session, une carte « Références » vit sous le bloc', s.carte===true);
t('… qui s’ouvre d’un tap et porte le contenu de la feuille SANS les différentiels',
  s.ouverte===true&&s.secs.length>=1&&!s.secs.includes('diff'), JSON.stringify(s.secs));
t('… et « Consulter » n’est plus ni au quai ni sous la fiche', !s.refBtn&&!s.annex&&!s.quai.some(x=>/Consulter/.test(x)), JSON.stringify(s.quai));
t('la feuille s’est fermée à l’entrée en session', s.feuille===false);
// la posologie et les surveillances restent joignables ailleurs
t('la posologie reste dans le flux (téléphone)', await p.evaluate(()=>document.querySelector('#main').textContent.indexOf('ADRÉNALINE')>=0));
t('les surveillances restent dans le flux', await p.evaluate(()=>document.querySelector('#main').textContent.indexOf('Chariot')>=0));
// INVARIANT : pas de carte sans contenu
const vide=await p.evaluate(async()=>{const f=state.fiche;
 setList(f,'differentials',[]);f.images=[];f.docs=[];f.sources=[];f.links=[];
 render();await new Promise(r=>setTimeout(r,400));
 return {carte:!!document.querySelector('[data-sf="refs"]'),kinds:refContentKinds(f).length,
   verify:clean(listOf(f,'verify')).length,poso:clean(listOf(f,'posology')).length};});
t('fiche SANS contenu à consulter (mais avec surveillances+posologie) : aucune carte morte',
  vide.carte===false&&vide.kinds===0, JSON.stringify(vide));
await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
