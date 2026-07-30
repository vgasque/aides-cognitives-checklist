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


/* ═══ AJOUTS v4.74.0 — CE QUE L'ÉCRAN DIT, ET CE QU'IL NE REFERME PAS TOUT SEUL ═══════════════
   Trois défauts signalés à l'usage, tous dans l'éditeur, tous mesurables ici. Le premier est le
   plus grave des trois parce qu'il portait sur un INDICATEUR D'ÉTAT : la barre annonçait un
   enregistrement automatique là où `edCommit` sortait les bras vides, faute de titre. */
console.log('=== l’état ne promet pas ce qui n’a pas lieu ===');
const f1=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  newFiche(); render(); await w(300);
  const ti=document.getElementById('f-title');
  ti.value='Provisoire'; ti.dispatchEvent(new Event('input',{bubbles:true})); await w(900);
  const avecTitre=(document.getElementById('hdrSaved')||{}).textContent||'';
  ti.value=''; ti.dispatchEvent(new Event('input',{bubbles:true})); await w(900);
  const sansTitre=(document.getElementById('hdrSaved')||{}).textContent||'';
  await w(2700);   // le parc écrit toutes les 2,5 s : c'est lui qui posait « auto-enregistré »
  const pastille=(document.getElementById('hdrStatus')||{}).textContent||'';
  return {avecTitre,sansTitre,pastille};});
t('avec titre, la barre dit « enregistré »', /✓/.test(f1.avecTitre), f1.avecTitre);
t('sans titre, elle dit « sans titre » — jamais « enregistrement… »',
  /sans titre/i.test(f1.sansTitre)&&!/⟳/.test(f1.sansTitre), f1.sansTitre);
t('… et la pastille ne dit pas « auto-enregistré »',
  !/auto-enregistr/.test(f1.pastille), f1.pastille);

console.log('=== le dépliant « Identité » ne se referme pas tout seul ===');
const f2=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const d=()=>document.querySelector('details.ed-ident');
  const neuf=d().open;                                   // fiche vierge -> ouvert d'office
  const ti=document.getElementById('f-title');
  ti.value='Fiche à identité'; ti.dispatchEvent(new Event('input',{bubbles:true}));
  renderEditor(); await w(400);                           // geste STRUCTUREL : le piège d'avant
  const apresRendu=d().open;
  d().open=false; d().dispatchEvent(new Event('toggle')); renderEditor(); await w(400);
  const repliTenu=!d().open;
  return {neuf,apresRendu,repliTenu};});
t('fiche vierge : ouvert d’office', f2.neuf);
t('titre saisi puis re-rendu : il RESTE ouvert', f2.apresRendu);
t('replié par l’auteur : il RESTE replié', f2.repliTenu);

console.log('=== une section vide ne s’affiche pas ===');
const f3=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const lbl=()=>[...document.querySelectorAll('fieldset.field>label')].map(x=>x.textContent);
  const vide=lbl();
  edAdd(state.draft,'stopwatch'); await w(500);
  const avec=lbl();
  return {videMinuteurs:vide.some(x=>/Minuteurs/.test(x)),
    videCx:vide.some(x=>/Complications/.test(x)),
    avecMinuteurs:avec.some(x=>/Minuteurs/.test(x))};});
t('aucun minuteur : la section n’est pas là', !f3.videMinuteurs);
t('aucune complication : la section n’est pas là', !f3.videCx);
t('un minuteur ajouté : elle revient', f3.avecMinuteurs);

console.log('=== le bandeau « déplacement » tient sur un écran étroit ===');
await p.setViewportSize({width:320,height:760});
const f4=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const g=document.querySelector('.blk .li .li-grab'); if(!g)return {absent:true};
  g.click(); await w(400);
  const b=document.querySelector('.ed-grab'); if(!b)return {absent:true};
  const l=b.querySelector('.eg-l'), x=b.querySelector('.eg-x');
  const rb=b.getBoundingClientRect(), rl=l.getBoundingClientRect(), rx=x.getBoundingClientRect();
  return {larg:Math.round(rl.width), boite:Math.round(rb.width),
    hors:Math.round(rb.right)>320||Math.round(rx.right)>320,
    croix:Math.round(Math.min(rx.width,rx.height))};});
t('le libellé garde au moins la moitié de la largeur du bandeau',
  !f4.absent&&f4.larg>=f4.boite*0.5, JSON.stringify(f4));
t('rien ne sort de l’écran à 320 px', !f4.absent&&!f4.hors, JSON.stringify(f4));
t('la croix reste une cible de 44 px', !f4.absent&&f4.croix>=44, String(f4.croix));

console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);
await br.close();srv.close();process.exit(ko?1:0);
