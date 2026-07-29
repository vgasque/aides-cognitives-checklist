/* AUDIT — K5 : L'ENREGISTREMENT SE DIT, IL NE SE DEMANDE PAS (v4.72.0).
   Ce harnais tient le CYCLE DE VIE, qui est la seule chose que K5 change vraiment :
     · sans titre, RIEN n'entre dans la bibliothèque (une rangée « Sans titre » dans un
       répertoire A→Z se rangerait sous « # » : un piège, pas une aide) ;
     · dès qu'il y a un titre, la fiche y est — et la barre le DIT au lieu de le demander ;
     · ce qui sort du brouillon est un ACTE éditorial (le statut), rien d'autre — et tant qu'il
       est brouillon, il ne prend pas la place d'accès de crise (épinglage refusé) ;
     · « ▶ Essayer » démarre une VRAIE session (on coche, les minuteurs tournent) qui ne laisse
       RIEN : ni archive, ni session vive, ni ligne d'historique ;
     · ouvrir l'éditeur pose UN point de version — le filet qui remplace le « Annuler » disparu.
   Les trois derniers contrôles sont les plus importants : ce sont eux qui garantissent qu'un
   essai d'auteur ne contamine pas l'historique clinique de quelqu'un. */
import { serveApp, moteur } from './harness.mjs';
const {port,srv}=await serveApp(); const br=await moteur().launch();
const p=await br.newPage({viewport:{width:390,height:900}});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
p.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
await p.goto(`http://localhost:${port}/index.html`);
await p.waitForFunction(()=>!document.querySelector('.boot-load'));
await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await w(200);
  const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await w(700);});

console.log('=== une fiche NEUVE sans titre n’entre pas ===');
const a=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const n0=fiches.length; newFiche(); render(); await w(300);
  const bloc=document.querySelector('.blk .li input[type=text]');
  bloc.value='Poser une voie'; bloc.dispatchEvent(new Event('input',{bubbles:true}));
  await w(900);
  return {n0,nApres:fiches.length,etat:(document.getElementById('hdrSaved')||{}).textContent||'',
    cache:(document.getElementById('hdrSaved')||{}).hidden};});
t('sans titre : rien n’entre dans la bibliothèque', a.nApres===a.n0, `${a.n0} → ${a.nApres}`);

console.log('=== dès qu’elle a un titre, elle y est ===');
const b=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const ti=document.getElementById('f-title'); ti.value='Test K5 — publication continue';
  ti.dispatchEvent(new Event('input',{bubbles:true})); state.draft.title=ti.value;
  await w(900);
  const f=fiches.find(x=>x.id===state.draft.id);
  return {dedans:!!f, titre:f?f.title:null, etat:(document.getElementById('hdrSaved')||{}).textContent||'',
    boutonRempli:[...document.querySelectorAll('header .hdr-act2.primary')].map(x=>x.textContent.trim()),
    plusDeSave:!document.getElementById('hdrSave')};});
t('titre saisi : la fiche entre dans la bibliothèque', b.dedans, JSON.stringify(b.titre));
/* L'état s'ABRÈGE sous 560 px (« ✓ 17:28 ») — troncature du même énoncé, l'HEURE ne tombant
   jamais puisque c'est la seule chose qui change. Le témoin mesure donc les DEUX largeurs :
   accepter « l'une ou l'autre » ne prouverait rien sur celle qu'on n'a pas regardée. */
t('la barre DIT l’enregistrement, avec l’heure (étroit)', /^✓ \d{2}:\d{2}$/.test(b.etat.trim()), b.etat);
await p.setViewportSize({width:900,height:900});
await p.evaluate(()=>{if(typeof edSaySave==='function')edSaySave('saved');});
const bLarge=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  return {etat:(document.getElementById('hdrSaved')||{}).textContent||''};});
t('… et en toutes lettres au large', /^✓ Enregistré · \d{2}:\d{2}$/.test(bLarge.etat.trim()), bLarge.etat);
t('« Enregistrer » n’existe plus', b.plusDeSave);
t('l’unique bouton rempli est « ▶ Essayer »', b.boutonRempli.length===1&&/Essayer/.test(b.boutonRempli[0]), JSON.stringify(b.boutonRempli));

await p.setViewportSize({width:390,height:900});
console.log('=== le statut, et lui seul, sort du brouillon ===');
const c=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const id=state.draft.id;
  state.draft.status='draft'; renderEditor(); await w(800);
  const brouillon=(fiches.find(x=>x.id===id)||{}).status;
  const avantPins=pins.length; togglePin(id); const refuse=pins.length===avantPins;
  state.draft.status=''; renderEditor(); await w(800);
  const valide=(fiches.find(x=>x.id===id)||{}).status;
  togglePin(id); const accepte=pins.indexOf(id)>=0;
  return {brouillon,valide,refuse,accepte};});
t('brouillon : le statut suit dans la bibliothèque', c.brouillon==='draft', c.brouillon);
t('un brouillon ne s’épingle PAS en accès direct', c.refuse);
t('validée : le statut suit', c.valide==='', JSON.stringify(c.valide));
t('… et elle s’épingle', c.accepte);

console.log('=== « ▶ Essayer » : une session qui ne laisse RIEN ===');
const d=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const nS=sessions.length, nL=Object.keys(liveSessions).length;
  document.getElementById('hdrPreview').click(); await w(500);
  const ck=document.querySelector('[data-ck]'); if(ck)ck.click(); await w(500);
  const demarre=Runtime.started&&!!Runtime.essai;
  const coche=Object.keys(state.checked||{}).length>0;
  // on quitte l'essai par le retour
  const bk=document.getElementById('hdrBack'); bk.click(); await w(600);
  return {nS,nL,demarre,coche,sApres:sessions.length,lApres:Object.keys(liveSessions).length,
    retourEditeur:state.view==='edit'};});
t('l’essai DÉMARRE vraiment (marqué essai)', d.demarre);
t('… et l’on peut y cocher', d.coche);
t('AUCUNE session archivée', d.sApres===d.nS, `${d.nS} → ${d.sApres}`);
t('AUCUNE session vive', d.lApres===d.nL, `${d.nL} → ${d.lApres}`);
t('le retour ramène à l’éditeur', d.retourEditeur);

console.log('=== un point de version est posé à l’ouverture ===');
const e=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const id=state.draft.id; const bk=document.getElementById('hdrBack'); bk.click(); await w(700);
  const av=(await Data.getBackups(id)).length;
  await openEdit(id); await w(500);
  const ap=(await Data.getBackups(id)).length;
  return {av,ap};});
t('ouvrir l’éditeur pose UN point de version', e.ap===e.av+1, `${e.av} → ${e.ap}`);

console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);
await br.close();srv.close();process.exit(ko?1:0);
