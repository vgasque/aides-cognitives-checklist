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
import { serveApp, moteur, amorce } from './harness.mjs';
const {port,srv}=await serveApp(); const br=await moteur().launch();
const p=await br.newPage({viewport:{width:390,height:900}});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
p.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
await p.goto(`http://localhost:${port}/index.html`);
await amorce(p);

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
/* ⚠ LE REDIMENSIONNEMENT RE-REND L'ÉDITEUR (`_onReadBp`, v4.77.0), et un re-rendu passe par
   `edTouch` qui repose « ⟳ Enregistrement… ». Poser l'état AVANT que le re-rendu soit retombé
   mesurait donc une course, pas un libellé : on laisse le rendu s'achever, PUIS on pose l'état. */
await p.waitForTimeout(500);
await p.evaluate(()=>{if(typeof edSaySave==='function')edSaySave('saved');});
await p.waitForTimeout(120);
const bLarge=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  return {etat:(document.getElementById('hdrSaved')||{}).textContent||''};});
t('… et en toutes lettres au large', /^✓ Enregistré · \d{2}:\d{2}$/.test(bLarge.etat.trim()), bLarge.etat);
t('« Enregistrer » n’existe plus', b.plusDeSave);
/* v4.77.0 — L'UNIQUE BOUTON REMPLI A CHANGÉ DE MAINS, et c'est un arbitrage assumé : l'action
   primaire d'un ÉDITEUR est d'écrire, donc c'est la porte « ＋ » qui porte le remplissage ; dérouler
   son brouillon vient après. La règle « un seul bouton rempli par écran » (v4.0.3) est tenue dans
   l'autre sens — le témoin la mesure donc dans l'autre sens aussi. */
t('« ▶ Essayer » n’est plus le bouton rempli de la barre', b.boutonRempli.length===0, JSON.stringify(b.boutonRempli));

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
  const out={larg:Math.round(rl.width), boite:Math.round(rb.width),
    hors:Math.round(rb.right)>320||Math.round(rx.right)>320,
    croix:Math.round(Math.min(rx.width,rx.height))};
  /* ON REPOSE L'OBJET AVANT DE SORTIR (v4.77.0) : un déplacement en cours désactive désormais tout
     le reste du formulaire (geste MODAL). Le laisser ouvert éteignait silencieusement chaque
     contrôle des blocs suivants — et un témoin qui laisse un état derrière lui fait échouer les
     autres pour la mauvaise raison. */
  state.edGrab=null;renderEditor();await w(400);
  return out;});
t('le libellé garde au moins la moitié de la largeur du bandeau',
  !f4.absent&&f4.larg>=f4.boite*0.5, JSON.stringify(f4));
t('rien ne sort de l’écran à 320 px', !f4.absent&&!f4.hors, JSON.stringify(f4));
t('la croix reste une cible de 44 px', !f4.absent&&f4.croix>=44, String(f4.croix));


/* ═══ ANNEAU D'ANNULATION (v4.74.2) — les deux sortes de points de reprise ════════════════════
   Le geste qui remplace le « Annuler » disparu avec le bouton « Enregistrer ». Deux propriétés
   ont été trouvées À LA MESURE et ne s'inventent pas en relisant : la frappe postérieure à un
   geste destructeur était perdue en silence (d'où un point de reprise à la PAUSE de frappe), et
   annuler jusqu'à l'état d'ouverture ne republiait RIEN (la garde anti-réécriture d'`edTouch`
   sortait la première, si bien que la bibliothèque gardait la version modifiée pendant que
   l'écran affichait l'originale). */
console.log('=== l’anneau d’annulation ===');
await p.setViewportSize({width:900,height:900});
/* ON REPART D'UN ÉDITEUR NEUF : les contrôles précédents ont déjà fait des gestes structurels sur
   ce brouillon, donc l'anneau n'y est pas vide et le bloc n'a plus qu'une étape. Un témoin qui
   mesure des valeurs ABSOLUES dans un fixture partagé mesure le fixture, pas la propriété. */
const g=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const id=state.draft.id;
  document.getElementById('hdrBack').click(); await w(800);
  await openEdit(id); await w(600);
  const nb=()=>document.querySelectorAll('.blk .li').length;
  const pub=()=>((fiches.find(f=>f.id===id)||{blocks:[]}).blocks||[]).reduce((a,b)=>a+bItems(b).length,0);
  const bouton=()=>document.getElementById('hdrUndo');
  const etat=[];
  etat.push({e:'ouverture',n:nb(),pile:_edUndo.length,visible:!bouton().hidden,pub:pub()});
  // deux étapes NOMMÉES, pour pouvoir en supprimer une sans vider le bloc
  for(const v of ['Sonde une','Sonde deux']){
    document.querySelector('.blk [data-addstep]').click(); await w(250);
    const ins=[...document.querySelectorAll('.blk .li input[data-sf]')];
    const cible=ins[ins.length-1]; cible.value=v; cible.dispatchEvent(new Event('input',{bubbles:true}));
    await w(700);}
  const base=_edUndo.length, nBase=nb(), pubBase=pub();
  [...document.querySelectorAll('.blk [data-rmstep]')].pop().click(); await w(300);
  etat.push({e:'suppression',n:nb(),pile:_edUndo.length,visible:!bouton().hidden,pub:pub()});
  const inp=document.querySelectorAll('.blk .li input[data-sf]')[0];
  const txt0=inp.value;
  inp.value='SONDE FRAPPE'; inp.dispatchEvent(new Event('input',{bubbles:true})); await w(900);
  etat.push({e:'frappe',n:nb(),pile:_edUndo.length,txt:inp.value,pub:pub()});
  bouton().click(); await w(800);
  etat.push({e:'undo frappe',n:nb(),pile:_edUndo.length,txt:document.querySelectorAll('.blk .li input[data-sf]')[0].value,txt0,pub:pub()});
  bouton().click(); await w(800);
  etat.push({e:'undo suppression',n:nb(),pile:_edUndo.length,visible:!bouton().hidden,pub:pub()});
  return {etat,base,nBase,pubBase};});
const E=g.etat;
t('éditeur fraîchement ouvert : aucun bouton d’annulation',
  !E[0].visible&&E[0].pile===0, JSON.stringify(E[0]));
t('un geste STRUCTUREL pose UN point et montre le bouton',
  E[1].pile===g.base+1&&E[1].visible&&E[1].n===g.nBase-1, JSON.stringify(E[1])+' base='+g.base);
t('une rafale de frappe pose UN point, pas un par caractère',
  E[2].pile===g.base+2, JSON.stringify(E[2])+' base='+g.base);
t('annuler rend le TEXTE d’avant la frappe', E[3].txt===E[3].txt0, `« ${E[3].txt} » ≠ « ${E[3].txt0} »`);
t('… sans toucher à la structure', E[3].n===E[2].n, `${E[2].n} → ${E[3].n}`);
t('annuler encore rend l’étape supprimée', E[4].n===g.nBase, `${E[4].n} vs ${g.nBase}`);
t('… ET LA BIBLIOTHÈQUE SUIT (garde anti-réécriture contournée)', E[4].pub===g.pubBase,
  `publié ${E[4].pub}, attendu ${g.pubBase}`);
t('on redescend jusqu’au point de départ', E[4].pile===g.base, `${E[4].pile} vs ${g.base}`);

/* Cmd/Ctrl-Z NE VOLE JAMAIS LE UNDO NATIF D'UN CHAMP : dans un `input`, le raccourci appartient
   au navigateur. Le témoin mesure la PROPRIÉTÉ (l'anneau n'a pas bougé), pas l'intention. */
const g2=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  document.querySelector('.blk [data-rmstep]').click(); await w(250);
  const av=_edUndo.length;
  const inp=document.querySelector('.blk .li input[data-sf]'); inp.focus();
  inp.dispatchEvent(new KeyboardEvent('keydown',{key:'z',metaKey:true,bubbles:true,cancelable:true}));
  await w(300);
  const dansChamp=_edUndo.length;
  document.body.focus();
  document.body.dispatchEvent(new KeyboardEvent('keydown',{key:'z',ctrlKey:true,bubbles:true,cancelable:true}));
  await w(700);
  return {av,dansChamp,horsChamp:_edUndo.length};});
t('Cmd-Z DANS un champ ne touche pas à l’anneau', g2.dansChamp===g2.av, JSON.stringify(g2));
t('Ctrl-Z hors champ annule bien', g2.horsChamp===g2.av-1, JSON.stringify(g2));

/* Sortir de l'éditeur vide l'anneau : c'est un GESTE, pas un état du brouillon (même statut que
   `state.edGrab`). Le filet de plus longue portée reste le point de version de v4.72.0. */
const g3=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  document.querySelector('.blk [data-rmstep]').click(); await w(250);
  const av=_edUndo.length;
  document.getElementById('hdrBack').click(); await w(800);
  return {av,apres:_edUndo.length,cache:document.getElementById('hdrUndo').hidden};});
t('quitter l’éditeur vide l’anneau', g3.av>0&&g3.apres===0&&g3.cache, JSON.stringify(g3));


/* ═══ LOT 2 (v4.75.0) — « PRENDRE / POSER » DANS LES LISTES ════════════════════════════════════
   Cinq listes n'avaient AUCUN moyen de réordonner (À vérifier, Différentiels, Références, Ne pas
   oublier, repères posologiques) et deux avaient des ↑ ↓ (minuteurs, compteurs) — plus lents et
   moins sûrs. Une seule sorte `'l'`, adressée par la CLÉ du modèle, couvre les huit. Ce qui se
   mesure ici : le CONFINEMENT (une liste ne reçoit que ses propres interstices), l'ANCRAGE à la
   prise (0 px, invariant ECAM du projet), le déplacement réellement écrit dans la bibliothèque, et
   le fait que le GLISSER amorce le mode au lieu d'être refusé en silence. */
console.log('=== lot 2 : prendre / poser dans les listes ===');
await p.setViewportSize({width:900,height:900});
const L=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  // Le contrôle précédent a QUITTÉ l'éditeur pour vérifier que l'anneau se vide : on y rentre.
  if(!state.draft){const f=fiches.find(x=>!x.deletedAt);await openEdit(f.id);await w(600);}
  const id=state.draft.id,d=state.draft;
  if(state.edGrab){state.edGrab=null;renderEditor();await w(300);}
  // un jeu de listes garni : deux objets par liste d'objets, quatre lignes en texte
  /* v5.0.0, étape B — ces listes ne sont plus des CHAMPS mais des RÔLES du pool `items` :
     `setList` est l'écriture réelle. Les écraser directement ne faisait plus rien, et la sonde
     mesurait alors une fiche qu'elle croyait avoir remplie. */
  setList(d,'differentials',['Un','Deux','Trois','Quatre']);
  setList(d,'posology',['Adrénaline : 0,5 mg','△ Noradré : dilution']);
  while((d.timers||[]).length<2)edAdd(d,'stopwatch');
  while((d.counters||[]).length<2)edAdd(d,'counter');
  d.timers[0].label='Minuteur A';d.timers[1].label='Minuteur B';
  d.counters[0].label='Compteur A';d.counters[1].label='Compteur B';
  renderEditor();await w(500);
  const cles=[...new Set([...document.querySelectorAll('[data-lgrab]')].map(b=>b.dataset.lgrab.split(':')[0]))];
  const H=k=>document.querySelector('[data-lgrab="'+k+'"]');
  // une liste à UNE seule rangée n'a pas de poignée (aucun bouton mort)
  d.sources=['Seule'];renderEditor();await w(400);
  const refSeule=!H('sources:0');
  // PRISE : ancrage à 0 px + confinement
  H('differentials:3').scrollIntoView({block:'center'});await w(150);
  const y0=Math.round(H('differentials:3').getBoundingClientRect().top);
  H('differentials:3').click();await w(350);
  const y1=Math.round(H('differentials:3').getBoundingClientRect().top);
  const drops=[...document.querySelectorAll('[data-ldrop]')].map(b=>b.dataset.ldrop);
  const marque=!!document.querySelector('.li.grabbed');
  const bandeau=(document.querySelector('.ed-grab .eg-l')||{}).textContent||'';
  // DÉPÔT
  document.querySelector('[data-ldrop="differentials:0"]').click();await w(500);
  const apres=listOf(d,'differentials').slice();
  const publie=listOf(fiches.find(f=>f.id===id)||{},'differentials').slice();
  // ÉCHAP repose l'objet sans rien déplacer
  H('differentials:2').click();await w(350);
  const avantEchap=(d.differentials||[]).slice();
  document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',bubbles:true}));await w(400);
  const apresEchap=(d.differentials||[]).slice();
  // une liste d'OBJETS se réordonne par le même chemin
  H('timers:1').click();await w(350);
  const dropsT=[...document.querySelectorAll('[data-ldrop]')].map(b=>b.dataset.ldrop);
  document.querySelector('[data-ldrop="timers:0"]').click();await w(500);
  const tApres=(d.timers||[]).map(t=>t.label);
  // LE GLISSER AMORCE LE MODE (et le glisser natif est annulé)
  const h=H('differentials:1');
  const ev=new DragEvent('dragstart',{bubbles:true,cancelable:true});
  h.dispatchEvent(ev);await w(350);
  const amorce=!!state.edGrab&&state.edGrab.kind==='l'&&state.edGrab.i===1;
  const annule=ev.defaultPrevented;
  // les micro-animations existent et cascadent
  const dl=[...document.querySelectorAll('.ed-drop')].map(x=>getComputedStyle(x).animationDelay);
  const animObjet=(()=>{const e=document.querySelector('.li.grabbed');return e?getComputedStyle(e).animationName:'';})();
  const animBan=(()=>{const e=document.querySelector('.ed-grab');return e?getComputedStyle(e).animationName:'';})();
  state.edGrab=null;renderEditor();await w(300);
  return {cles,refSeule,derivePrise:y1-y0,drops,marque,bandeau,apres,publie,
    avantEchap,apresEchap,dropsT,tApres,amorce,annule,dl,animObjet,animBan,
    flechesRestantes:document.querySelectorAll('[data-cmv],[data-tmv]').length};});

t('les huit listes ont leur poignée', ['notForget','confirmation','posology','verify','differentials','timers','counters'].every(k=>L.cles.includes(k)), L.cles.join(','));
t('les ↑ ↓ ont disparu', L.flechesRestantes===0, String(L.flechesRestantes));
t('une liste à UNE rangée n’a pas de poignée (aucun bouton mort)', L.refSeule);
// Tolérance 1 px : sous-pixel de compositeur, même convention que les autres mesures d'ancrage.
t('à la prise, l’objet ne bouge pas', Math.abs(L.derivePrise)<=1, `${L.derivePrise} px`);
t('le bandeau NOMME l’objet pris', /Quatre/.test(L.bandeau), L.bandeau);
t('l’objet pris est marqué', L.marque);
t('CONFINÉ : la liste ne reçoit que ses propres interstices',
  L.drops.length===5&&L.drops.every(x=>x.startsWith('differentials:')), L.drops.join(','));
t('le dépôt réordonne', L.apres[0]==='Quatre'&&L.apres.length===4, JSON.stringify(L.apres));
t('… et la bibliothèque suit', L.publie[0]==='Quatre', JSON.stringify(L.publie));
t('Échap repose l’objet sans rien déplacer',
  JSON.stringify(L.avantEchap)===JSON.stringify(L.apresEchap), JSON.stringify(L.apresEchap));
t('une liste d’OBJETS passe par le même chemin',
  L.dropsT.every(x=>x.startsWith('timers:'))&&L.tApres[0]==='Minuteur B', JSON.stringify(L.tApres));
t('le GLISSER amorce le mode déplacement', L.amorce);
t('… et le glisser natif est annulé', L.annule);
t('les interstices cascadent (un délai par rang)', new Set(L.dl).size>1, L.dl.join(' '));
t('l’objet pris s’anime UNE fois (pas une boucle)', L.animObjet==='grabWake', L.animObjet);
t('le bandeau entre dans le sens du geste', L.animBan==='grabBanIn', L.animBan);


/* ═══ LOT 3 (v4.76.0) — LA PORTE DE L'AIDE, L'IMAGE, LE COMPTE, LE PLACARD ═══════════════════
   La règle centrale à tenir : « PRÉSENT DANS LA PORTE ⇔ MASQUÉ QUAND VIDE ». Deux exceptions
   NOMMÉES, et elles doivent rester vraies : le chapeau « Ne pas oublier » et la confirmation
   diagnostique restent affichés même vides (ce ne sont pas des extras — condition d'entrée et
   memory items), donc ils n'ont pas d'entrée dans la porte. Un témoin des deux sens. */
console.log('=== lot 3 : la porte de l’aide entière ===');
await p.setViewportSize({width:900,height:900});
const P=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  if(!state.draft){const f=fiches.find(x=>!x.deletedAt);await openEdit(f.id);await w(600);}
  const d=state.draft,id=d.id;
  const labels=()=>[...document.querySelectorAll('fieldset>label')].map(e=>e.textContent);
  const a=(rx)=>labels().some(x=>rx.test(x));
  const porte=()=>document.getElementById('edAddOpen');
  // (1) la porte a quitté « Prise en charge » et colle
  const dedansFieldset=!!porte().closest('fieldset');
  const collante=getComputedStyle(porte()).position;
  // (2) la palette : groupes + entrées
  porte().click();await w(300);
  const body=document.getElementById('edAddBody');
  const groupes=[...body.querySelectorAll('.ep-g')].map(e=>e.textContent);
  const cles=[...body.querySelectorAll('.ep-row')].map(e=>e.dataset.edadd);
  document.querySelector('#edAddModal .ai-x, #edAddModal [data-x]')?.click();
  if(document.querySelector('#edAddModal.on'))edAddClose();
  await w(250);
  // (3) « présent dans la porte ⇔ masqué quand vide »
  setList(d,'verify',[]);setList(d,'differentials',[]);d.sources=[];setList(d,'posology',[]);d.images=[];d.docs=[];
  setList(d,'notForget',[]);setList(d,'confirmation',[]);
  renderEditor();await w(500);
  /* v5.0.0, lot M3 : « Confirmation diagnostique » et « Diagnostics différentiels » sont réunis
     sous « Condition d'entrée » (critères + diagnostics à éliminer). Les LIBELLÉS changent, la
     RÈGLE ne change pas : les critères restent une invitation visible même vide, les diagnostics
     à éliminer restent masqués quand la liste est vide et recréés par la porte. */
  const vides={verify:a(/À vérifier/),diff:a(/Diagnostics à éliminer/),ref:a(/Références/),
    poso:a(/Repères posologiques/),img:a(/Schémas/),att:a(/Documents \(PDF\)/),
    nf:a(/Ne pas oublier/),conf:a(/Condition d’entrée/)};
  // (4) chaque entrée de liste recrée sa section
  const recree={};
  for(const [k,rx] of [['verify',/À vérifier/],['diff',/Diagnostics à éliminer/],['ref',/Références/],['poso',/Repères posologiques/]]){
    porte().click();await w(250);
    document.querySelector('[data-edadd="'+k+'"]').click();await w(450);
    recree[k]=a(rx);}
  // (5) la porte redescend dans le flux pendant un déplacement
  setList(d,'differentials',['Un','Deux']);renderEditor();await w(400);
  document.querySelector('[data-lgrab="differentials:1"]').click();await w(350);
  const platPendantDeplacement=getComputedStyle(porte()).position;
  state.edGrab=null;renderEditor();await w(350);
  // (6) l'image s'associe à un bloc, et à UN SEUL
  const px='data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
  d.images=[{id:'i1',data:px,w:1,h:1,caption:'Sonde'}];renderEditor();await w(450);
  const sel=document.querySelector('[data-imgblk="0"]');
  const nOptions=sel?sel.options.length:0;
  const cible=(d.blocks||[])[0].id;
  sel.value=cible;sel.dispatchEvent(new Event('change'));await w(450);
  const porteurs=(d.blocks||[]).filter(b=>b.image===px).length;
  const sel2=document.querySelector('[data-imgblk="0"]');
  const memorise=sel2.value===cible;
  sel2.value='';sel2.dispatchEvent(new Event('change'));await w(450);
  const detache=(d.blocks||[]).filter(b=>b.image===px).length;
  // (7) le compte de relecture
  const rb=document.getElementById('hdrRev');
  setList(d,'notForget',['a']);renderEditor();await w(400);
  const revZero=rb.hidden;
  setList(d,'notForget',['a','b','c','d','e']);renderEditor();await w(400);
  const revUn={cache:rb.hidden,txt:rb.textContent};
  rb.click();await w(400);
  const voletOuvert=!!document.querySelector('#revPanel details.rev-panel[open]');
  return {dedansFieldset,collante,groupes,cles,vides,recree,platPendantDeplacement,
    nOptions,porteurs,memorise,detache,revZero,revUn,voletOuvert,nBlocs:(d.blocks||[]).length};});

t('la porte a QUITTÉ le fieldset « Prise en charge »', !P.dedansFieldset);
t('… et elle colle sur toute la hauteur du formulaire', P.collante==='sticky', P.collante);
t('… et redescend dans le flux pendant un déplacement', P.platPendantDeplacement==='static', P.platPendantDeplacement);
t('la palette est GROUPÉE', P.groupes.length===4, P.groupes.join(' | '));
t('elle porte les nouvelles entrées', ['verify','diff','ref','img'].every(k=>P.cles.includes(k)), P.cles.join(','));
t('elle NE porte PAS le chapeau ni la confirmation (hors règle, assumé)',
  !P.cles.includes('nf')&&!P.cles.includes('conf'), P.cles.join(','));
t('vide = masqué : à vérifier, différentiels, références, doses, schémas, documents',
  !P.vides.verify&&!P.vides.diff&&!P.vides.ref&&!P.vides.poso&&!P.vides.img&&!P.vides.att, JSON.stringify(P.vides));
t('… MAIS le chapeau et la CONDITION D’ENTRÉE restent VISIBLES même vides',
  P.vides.nf&&P.vides.conf, JSON.stringify(P.vides));
t('chaque entrée de liste recrée sa section',
  Object.values(P.recree).every(Boolean), JSON.stringify(P.recree));
t('le sélecteur de la vignette liste tous les blocs + « aucun »',
  P.nOptions===P.nBlocs+1, `${P.nOptions} options pour ${P.nBlocs} blocs`);
t('associer une image la met sur UN SEUL bloc', P.porteurs===1, String(P.porteurs));
t('… et le sélecteur montre le porteur', P.memorise);
t('« aucun bloc » détache', P.detache===0, String(P.detache));
t('compte de relecture : masqué à zéro remarque', P.revZero);
t('… affiché avec son compte au-delà', !P.revUn.cache&&/△ 1/.test(P.revUn.txt), JSON.stringify(P.revUn));
t('… et il ancre en DÉPLIANT le volet', P.voletOuvert);

console.log('=== lot 3 : le placard de l’essai ===');
const E2=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const cb=document.getElementById('crisisBand');
  const hach=()=>getComputedStyle(cb,'::before').opacity;
  const tag=()=>cb.querySelector('.cb-tag');
  state.draft.notForget=['Adrénaline IM'];renderEditor();await w(350);
  document.getElementById('hdrPreview').click();await w(700);window.scrollTo(0,0);await w(250);
  /* COÛT NUL : on isole UNE variable, le placard lui-même. Dans l'éditeur `#crisisBand` est masqué
     (hauteur 0), donc le comparer à l'essai ne mesurerait rien ; on retire la seule classe du
     placard, on mesure, on la remet. C'est une mesure de CSS, pas une reconstruction d'état. */
  const hAvecPlacard=Math.round(cb.getBoundingClientRect().height);
  const opac=hach();                       // LU AVANT le retrait : la hachure est en fondu 300 ms
  cb.classList.remove('ess');await w(120);
  const hAvant=Math.round(cb.getBoundingClientRect().height);
  cb.classList.add('ess');await w(120);
  return {classe:cb.classList.contains('ess'),hachure:opac,hAvecPlacard,
    etiquetteCachee:tag().hidden,
    hauteur:hAvecPlacard,hAvant,
    /* v5.6 (A14) : l'énoncé du mode vit sur le SUR-TITRE `.brand-sur`. */
    pilule:(document.getElementById('brandSur')||{}).textContent||'',
    badge:(document.querySelector('.hdr-badge')||{}).textContent||'',
    barre:document.querySelector('header.bar').classList.contains('ess')};});
t('essai : la hachure est posée sur le bandeau', E2.classe&&E2.hachure==='1', JSON.stringify(E2.hachure));
t('… et sur la barre, pour le relais au défilement', E2.barre);
t('AUCUNE étiquette de bandeau (la barre porte déjà les mots)', E2.etiquetteCachee);
t('… les mots sont bien dans la barre', /Aperçu/.test(E2.pilule)&&/rien n’est enregistré/.test(E2.badge),
  E2.pilule+' | '+E2.badge);
t('COÛT NUL en hauteur de bandeau', E2.hauteur===E2.hAvant, `${E2.hAvant} → ${E2.hauteur}`);


/* ═══ v4.77.0 — LES DÉFAUTS SIGNALÉS À L'USAGE APRÈS LES TROIS LOTS ══════════════════════════════
   NOTE DE MÉTHODE, elle vaut pour le premier contrôle : le pane du navigateur intégré ne déclenche
   NI `resize` NI `matchMedia change` quand on redimensionne par CDP — il ne peut donc pas éprouver
   un franchissement de palier. Playwright, lui, les émet. C'est exactement le genre de trou où un
   défaut survit à une vérification manuelle, d'où le témoin. */
console.log('=== v4.77.0 : l’éditeur suit les paliers ===');
/* On REVIENT dans l'éditeur : le bloc précédent finit dans l'aperçu d'essai (`state.previewFrom`),
   et rendre l'éditeur par-dessus une vue de lecture ne mesurerait rien de réel. */
await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  if(state.previewFrom){document.getElementById('hdrBack').click();await w(800);}
  if(state.view!=='edit'){const f=fiches.find(x=>!x.deletedAt);await openEdit(f.id);await w(700);}});
await p.waitForTimeout(400);
{
  await p.setViewportSize({width:1250,height:820}); await p.waitForTimeout(500);
  const large=await p.evaluate(()=>({side:!!document.querySelector('#editSide .flow-scroll'),
    flux:!!document.querySelector('.flow-prev')}));
  await p.setViewportSize({width:820,height:820}); await p.waitForTimeout(500);
  const etroit=await p.evaluate(()=>({side:!!document.querySelector('#editSide .flow-scroll'),
    flux:!!document.querySelector('.flow-prev'),
    dansLeFlux:!!document.querySelector('fieldset .flow-prev')}));
  await p.setViewportSize({width:1250,height:820}); await p.waitForTimeout(500);
  const retour=await p.evaluate(()=>({side:!!document.querySelector('#editSide .flow-scroll'),
    flux:!!document.querySelector('.flow-prev')}));
  t('≥ 1000 px : le schéma vit dans la colonne collante', large.side&&!large.flux, JSON.stringify(large));
  t('< 1000 px : il redescend, entrebâillé, DANS le flux',
    !etroit.side&&etroit.flux&&etroit.dansLeFlux, JSON.stringify(etroit));
  t('et il remonte au retour (le palier est suivi dans les DEUX sens)',
    retour.side&&!retour.flux, JSON.stringify(retour));
}

console.log('=== v4.77.0 : le mode déplacement est modal, et réversible ===');
await p.setViewportSize({width:900,height:900});
const R2=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const d=state.draft;
  setList(d,'differentials',['Un','Deux','Trois']);renderEditor();await w(450);
  const H=k=>document.querySelector('[data-lgrab="'+k+'"]');
  H('differentials:2').scrollIntoView({block:'center'});await w(200);
  const y0=Math.round(H('differentials:2').getBoundingClientRect().top);
  H('differentials:2').click();await w(400);
  // (a) le reste du formulaire est INERTE
  const champ=document.querySelector('#f-title');
  const suppr=document.querySelector('[data-bdel]');
  const inerte={titre:!!champ.disabled,suppr:!!(suppr&&suppr.disabled),
    interstice:!document.querySelector('[data-ldrop]').disabled,
    poignee:!H('differentials:2').disabled,
    croix:!document.getElementById('edGrabX').disabled};
  // (b) le bandeau vit HORS du fieldset « Prise en charge »
  const ban=document.querySelector('.ed-grab');
  const banHorsFieldset=!ban.closest('fieldset');
  // (c) re-presser la MÊME poignée repose l'objet, sans dérive
  H('differentials:2').click();await w(450);
  const y1=Math.round(H('differentials:2').getBoundingClientRect().top);
  const repose=state.edGrab===null;
  const rendu={titre:!document.querySelector('#f-title').disabled};
  // (d) Échap repose aussi, sans dérive
  H('differentials:2').click();await w(400);
  document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',bubbles:true}));await w(450);
  const y2=Math.round(H('differentials:2').getBoundingClientRect().top);
  return {inerte,banHorsFieldset,repose,rendu,deriveRepose:y1-y0,deriveEchap:y2-y0,
    edGrab:state.edGrab};});
t('pendant un déplacement, les champs et les suppressions sont INERTES',
  R2.inerte.titre&&R2.inerte.suppr, JSON.stringify(R2.inerte));
t('… mais les interstices, la poignée et le ✕ restent actifs',
  R2.inerte.interstice&&R2.inerte.poignee&&R2.inerte.croix, JSON.stringify(R2.inerte));
t('le bandeau vit HORS du fieldset (il couvre tout le formulaire)', R2.banHorsFieldset);
t('re-presser la même poignée REPOSE l’objet', R2.repose&&R2.edGrab===null);
t('… et rend la main au formulaire', R2.rendu.titre);
t('abandonner ne DÉCALE rien (poignée)', Math.abs(R2.deriveRepose)<=2, `${R2.deriveRepose} px`);
t('abandonner ne DÉCALE rien (Échap)', Math.abs(R2.deriveEchap)<=2, `${R2.deriveEchap} px`);

console.log('=== v4.77.0 : les outils d’une étape agissent vraiment ===');
/* DE VRAIS CLICS, PAS UN `.focus()` : `.li-tools` n'existe qu'en `:focus-within`, et un focus
   PROGRAMMATIQUE ne le déclenche pas de façon fiable en headless (même leçon que l'anneau de focus
   dans `audit-a11y`, qui a dû passer par de vraies touches Tab). Surtout, le défaut EST une
   séquence de pointeur — pointerdown qui vole le focus, `display:none`, plus de `click`. Il faut
   donc la rejouer telle quelle : Playwright émet pointerdown/mousedown/mouseup/click. */
{
  const CH='.blk:not(.blk-dec) .li input[data-sf]';
  const cle=await p.evaluate(()=>{const b=document.querySelector('.blk:not(.blk-dec)');return b?b.dataset.bid:null;});
  const etapes=async()=>p.evaluate(id=>bItems(state.draft.blocks.find(b=>b.id===id)||{}).map(v4ItemToStr),cle);
  await p.click(CH); await p.waitForTimeout(250);
  const vus=await p.evaluate(()=>{const e=document.querySelector('.blk:not(.blk-dec) .li-tools');
    return e?getComputedStyle(e).display:'absent';});
  t('les outils apparaissent quand l’étape est en édition', vus!=='none'&&vus!=='absent', vus);
  const av=await etapes();
  await p.click('.blk:not(.blk-dec) .li[data-si="0"] .li-tools .crit-tgl');
  await p.waitForTimeout(400);
  const ap=await etapes();
  t('le bouton ⚠ change bien le registre', av[0]!==ap[0], `« ${av[0]} » → « ${ap[0]} »`);
  await p.click(CH); await p.waitForTimeout(250);
  const n0=(await etapes()).length;
  await p.click('.blk:not(.blk-dec) .li[data-si="0"] .li-tools .del');
  await p.waitForTimeout(450);
  const n1=(await etapes()).length;
  t('le bouton ✕ supprime bien l’étape', n1===n0-1, `${n0} → ${n1}`);
}

console.log('=== v4.77.0 : guide replié, porte remplie, ajouts amenés à l’écran ===');
const R4=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  try{localStorage.removeItem('ac-cg-open');}catch(e){}
  renderEditor();await w(450);
  const guides=[...document.querySelectorAll('details.crit-guide')].map(x=>x.open);
  const porte=document.getElementById('edAddOpen');
  const prim=getComputedStyle(document.documentElement).getPropertyValue('--primary').trim();
  const bidon=document.createElement('span');bidon.style.background=prim;document.body.appendChild(bidon);
  const attendu=getComputedStyle(bidon).backgroundColor;bidon.remove();
  const res={guides,porteFond:getComputedStyle(porte).backgroundColor,attendu,
    essayerPrimaire:document.getElementById('hdrPreview').classList.contains('primary'),vus:{}};
  // chaque type créé par la porte doit arriver DANS l'écran
  for(const k of ['interval','counter','cx']){
    porte.click();await w(250);
    document.querySelector('[data-edadd="'+k+'"]').click();await w(600);
    const sel={interval:'.tmedit',counter:'.tmedit',cx:'.cx-edit-row'}[k];
    const l=[...document.querySelectorAll(sel)];const c=l[l.length-1];
    const r=c.getBoundingClientRect();
    res.vus[k]=r.top<window.innerHeight&&r.bottom>0;}
  return res;});
t('le guide rouge/ambre est REPLIÉ par défaut sur tous les blocs',
  R4.guides.length>0&&R4.guides.every(x=>!x), JSON.stringify(R4.guides));
t('la porte est le bouton REMPLI de l’écran', R4.porteFond===R4.attendu, `${R4.porteFond} vs ${R4.attendu}`);
t('… et « ▶ Essayer » n’est plus primaire', !R4.essayerPrimaire);
t('minuteur, compteur, complication : chacun arrive DANS l’écran',
  Object.values(R4.vus).every(Boolean), JSON.stringify(R4.vus));


console.log('=== v4.78.0 : la galerie agrège, les cartes se ressemblent ===');
await p.setViewportSize({width:900,height:900});
const V=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  if(state.previewFrom){document.getElementById('hdrBack').click();await w(800);}
  if(state.view!=='edit'){const f=fiches.find(x=>!x.deletedAt);await openEdit(f.id);await w(700);}
  const d=state.draft;
  const px='data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
  /* (1) UNE IMAGE POSÉE SUR UN BLOC DOIT APPARAÎTRE DANS LA GALERIE. On simule le cas EXISTANT —
     `b.image` renseigné sans entrée de galerie — parce que c'est celui des fiches déjà écrites, et
     que le corriger seulement au point d'ajout n'aurait rien rattrapé. */
  d.images=[];d.blocks[0].image=px;d.blocks[0].imageW=1;d.blocks[0].imageH=1;
  renderEditor();await w(500);
  const agrege={n:(d.images||[]).length,
    memeDonnee:((d.images||[])[0]||{}).data===px,
    vignette:!!document.querySelector('[data-imgblk]'),
    porteurMontre:(()=>{const sel=document.querySelector('[data-imgblk="0"]');
      return sel?sel.value===d.blocks[0].id:false;})()};
  // idempotence : un second rendu ne doit rien empiler
  renderEditor();await w(400);
  const idem=(d.images||[]).length;
  /* DÉTACHER (« Aucun bloc ») : la vignette RESTE dans la galerie, prête pour un autre bloc. */
  {const sel=document.querySelector('[data-imgblk="0"]');sel.value='';
   sel.dispatchEvent(new Event('change'));await w(450);}
  const detache={images:(d.images||[]).length,blocs:(d.blocks||[]).filter(b=>b.image===px).length};
  /* RETIRER : l'image quitte l'aide entière — sinon la réconciliation la ramène. */
  {const sel=document.querySelector('[data-imgblk="0"]');sel.value=d.blocks[0].id;
   sel.dispatchEvent(new Event('change'));await w(450);}
  document.querySelector('[data-imgdel]').click();await w(500);
  const retrait={images:(d.images||[]).length,blocs:(d.blocks||[]).filter(b=>b.image===px).length};
  /* (2) LE COMPTEUR A L'ANATOMIE DE LA CARTE DE MINUTEUR : poignée ET croix en tête, même rangée. */
  while((d.counters||[]).length<2)edAdd(d,'counter');
  renderEditor();await w(500);
  const carte=document.querySelector('.tmedit[data-ci]');
  const top=carte?carte.querySelector('.tme-top'):null;
  const g=top?top.querySelector('[data-lgrab]'):null,x=top?top.querySelector('.mini.del'):null;
  const ctr=e=>{const q=e.getBoundingClientRect();return Math.round(q.y+q.height/2);};
  const compteur={carte:!!carte,poignee:!!g,croix:!!x,
    memeRangee:(g&&x)?Math.abs(ctr(g)-ctr(x))<=1:false,
    memeHauteur:(g&&x)?Math.abs(Math.round(g.getBoundingClientRect().height-x.getBoundingClientRect().height))<=1:false,
    trowDisparu:document.querySelectorAll('.trow').length===0};
  /* (3) UN BLOC SANS TITRE SE NOMME. */
  d.blocks[1].title='';renderEditor();await w(450);   // sans re-rendu, le <select> garde l'ancien titre
  const nomme=(()=>{const o=[...document.querySelectorAll('select[data-target] option')]
    .map(x=>x.textContent);return o.some(t=>/Bloc sans titre \(\d\)/.test(t))&&!o.some(t=>/^b[_0-9a-z]{4,}$/.test(t));})();
  /* (4) LA MARQUE « EN DÉPLACEMENT » NE MANGE PLUS LE CHAMP D'UNE LIGNE DE LISTE. */
  setList(d,'differentials',['Un','Deux','Trois']);renderEditor();await w(450);
  const champ=()=>document.querySelector('.list-edit .li input[data-key="differentials"]');
  const lRepos=Math.round(champ().getBoundingClientRect().width);
  document.querySelector('[data-lgrab="differentials:0"]').click();await w(450);
  const lPris=Math.round(document.querySelector('.li.grabbed input[data-key="differentials"]').getBoundingClientRect().width);
  state.edGrab=null;renderEditor();await w(400);
  /* (5) LA PORTE A DE LA PROFONDEUR : élévation de niveau 3 + voile au-dessus. */
  const porte=document.getElementById('edAddOpen');
  const voile=getComputedStyle(porte,'::before');
  const up=getComputedStyle(document.documentElement).getPropertyValue('--shadow-up').trim();
  const bidon=document.createElement('span');bidon.style.boxShadow=up;document.body.appendChild(bidon);
  const attendu=getComputedStyle(bidon).boxShadow;bidon.remove();
  return {agrege,idem,detache,retrait,compteur,nomme,lRepos,lPris,
    porteOmbre:getComputedStyle(porte).boxShadow,porteAttendue:attendu,
    voile:voile.backgroundImage,voileHaut:voile.height};});

t('une image de BLOC apparaît dans la galerie', V.agrege.n===1&&V.agrege.memeDonnee, JSON.stringify(V.agrege));
t('… avec sa vignette et son porteur montré', V.agrege.vignette&&V.agrege.porteurMontre, JSON.stringify(V.agrege));
t('… et la réconciliation est IDEMPOTENTE', V.idem===1, String(V.idem));
/* LE RETRAIT DOIT TENIR (v4.78.0) : c'est le défaut que l'agrégateur a créé — on sortait l'image de
   `f.images`, un bloc la portait encore, et la réconciliation la remettait au rendu suivant. Le
   témoin mesure les DEUX moitiés : elle disparaît de la galerie ET du bloc, sinon elle revient. */
t('« Retirer » sort l’image de la galerie ET du bloc', V.retrait.images===0&&V.retrait.blocs===0,
  JSON.stringify(V.retrait));
t('… et le sélecteur « Aucun bloc » ne fait que DÉTACHER', V.detache.images===1&&V.detache.blocs===0,
  JSON.stringify(V.detache));
t('le compteur est une CARTE, poignée et croix en tête',
  V.compteur.carte&&V.compteur.poignee&&V.compteur.croix&&V.compteur.memeRangee, JSON.stringify(V.compteur));
t('… la poignée a la hauteur de la croix', V.compteur.memeHauteur, JSON.stringify(V.compteur));
t('… et `.trow` a bien disparu (règle 14)', V.compteur.trowDisparu);
t('un bloc sans titre se NOMME, il ne s’identifie pas', V.nomme);
t('la marque « en déplacement » ne rétrécit plus le champ',
  V.lPris>=V.lRepos-2, `${V.lRepos} px au repos → ${V.lPris} px pris`);
/* L'OMBRE SUIT LA FORME, ET ELLE MONTE (v4.78.0) : un dégradé en `::before` est un RECTANGLE dont
   les angles ne suivent pas le rayon, et il éclaircissait vers `--bg` au lieu d'assombrir — « à
   l'envers », littéralement. On mesure donc les DEUX propriétés : l'ombre vaut `--shadow-up`
   (décalage NÉGATIF, du côté d'où vient le contenu) et il n'y a plus AUCUN voile. */
t('la porte porte l’ombre montante', V.porteOmbre===V.porteAttendue,
  `${V.porteOmbre} vs ${V.porteAttendue}`);
t('… avec un décalage vertical NÉGATIF', /-\d+px/.test(V.porteOmbre), V.porteOmbre);
t('… et plus aucun voile rectangulaire', V.voile==='none', V.voile);

console.log('=== v4.78.0 : le placard d’essai ne survit pas au retour en édition ===');
const V2=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  document.getElementById('hdrPreview').click();await w(800);
  const enEssai=document.querySelector('header.bar').classList.contains('ess');
  document.getElementById('hdrBack').click();await w(900);
  const bar=document.querySelector('header.bar');
  return {enEssai,apres:bar.classList.contains('ess'),
    bandeau:document.getElementById('crisisBand').classList.contains('ess'),vue:state.view};});
t('l’essai pose bien la hachure sur la barre', V2.enEssai);
t('… et le retour en édition la RETIRE', !V2.apres&&!V2.bandeau, JSON.stringify(V2));

console.log('=== v4.78.0 : la bascule ⚠ garde la rangée en édition ===');
{
  const CH='.blk:not(.blk-dec) .li input[data-sf]';
  await p.click(CH); await p.waitForTimeout(250);
  await p.click('.blk:not(.blk-dec) .li[data-si="0"] .li-tools .crit-tgl');
  await p.waitForTimeout(450);
  const r=await p.evaluate(()=>{const li=document.querySelector('.blk:not(.blk-dec) .li[data-si="0"]');
    const inp=li?li.querySelector('input[data-sf]'):null;
    return {focus:document.activeElement===inp,
      outils:li?getComputedStyle(li.querySelector('.li-tools')).display:'absent'};});
  t('après la bascule ⚠, le champ garde le focus', r.focus, JSON.stringify(r));
  t('… donc les outils restent affichés', r.outils!=='none'&&r.outils!=='absent', r.outils);
}


console.log('=== v4.78.0 : chronomètre, champs numériques, cible de défilement ===');
const W=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  if(state.previewFrom){document.getElementById('hdrBack').click();await w(800);}
  if(state.view!=='edit'){const f=fiches.find(x=>!x.deletedAt);await openEdit(f.id);await w(700);}
  const d=state.draft;
  d.timers=[];d.counters=[];renderEditor();await w(400);
  const porte=()=>document.getElementById('edAddOpen');
  const cree=async k=>{porte().click();await w(250);
    document.querySelector('[data-edadd="'+k+'"]').click();await w(650);};
  /* (1) UN CHRONOMÈTRE NE SONNE PAS : pas de champ « à l'échéance », et il le DIT. */
  await cree('stopwatch');
  const chr=[...document.querySelectorAll('.tmedit[data-ti]')].pop();
  const rc=chr.getBoundingClientRect();
  const chrono={due:!!chr.querySelector('[data-tdue]'),
    dit:/ne sonne pas/.test((chr.querySelector('.tme-h')||{}).textContent||''),
    vu:rc.top<window.innerHeight&&rc.bottom>0,
    estUnChrono:chr.querySelector('.tm-kind').textContent==='Chrono'};
  /* (2) UN CYCLE, LUI, GARDE LE CHAMP. */
  await cree('interval');
  const cyc=[...document.querySelectorAll('.tmedit[data-ti]')].pop();
  const cycle={due:!!cyc.querySelector('[data-tdue]'),
    vu:(()=>{const r=cyc.getBoundingClientRect();return r.top<window.innerHeight&&r.bottom>0;})()};
  /* (3) LA CIBLE DE DÉFILEMENT DISTINGUE minuteur et compteur — ils partagent `.tmedit`.
     L'ORDRE DU CONTRÔLE EST LE CONTRÔLE : les compteurs sont rendus APRÈS les minuteurs, donc le
     dernier `.tmedit` du formulaire est un COMPTEUR. Créer un compteur en dernier ne prouverait
     rien (la cible ambiguë tomberait juste par hasard) ; il faut créer un MINUTEUR alors qu'un
     compteur existe déjà — c'est là, et là seulement, que « viser la classe » se trompe de cible. */
  await cree('counter');
  const cpt=[...document.querySelectorAll('.tmedit[data-ci]')].pop();
  const rn=cpt.getBoundingClientRect();
  const compteur={vu:rn.top<window.innerHeight&&rn.bottom>0,
    dernierEstUnCompteur:[...document.querySelectorAll('.tmedit')].pop().dataset.ci!==undefined};
  window.scrollTo(0,0);await w(200);
  await cree('stopwatch');
  const dernierMin=[...document.querySelectorAll('.tmedit[data-ti]')].pop();
  const rm=dernierMin.getBoundingClientRect();
  const minApresCompteur={vu:rm.top<window.innerHeight&&rm.bottom>0,
    piegeArme:[...document.querySelectorAll('.tmedit')].pop().dataset.ci!==undefined};
  /* (4) LES CHAMPS NUMÉRIQUES ONT LE GABARIT DES AUTRES CHAMPS. */
  /* On RE-INTERROGE le DOM : `cpt` a été capturé avant le dernier re-rendu, son nœud est détaché,
     et `getComputedStyle` d'un détaché rend des valeurs vides — un témoin qui mesurerait ça
     échouerait sans rien dire du sujet. */
  const num=document.querySelector('.tmedit[data-ci] input[type=number]');
  const cs=getComputedStyle(num);
  const ref=getComputedStyle(document.getElementById('f-title'));
  const champ={rembourrage:parseFloat(cs.paddingTop)>=8,
    rayon:parseFloat(cs.borderTopLeftRadius)>=8,
    largeurFilet:Math.round(parseFloat(cs.borderTopWidth)),
    fond:cs.backgroundColor===ref.backgroundColor};
  return {chrono,cycle,compteur,minApresCompteur,champ};});

t('un chronomètre n’a PAS de champ « à l’échéance »', !W.chrono.due&&W.chrono.estUnChrono, JSON.stringify(W.chrono));
t('… et il dit pourquoi il ne sonne pas', W.chrono.dit);
t('un cycle, lui, garde le champ', W.cycle.due);
t('chaque minuteur créé arrive DANS l’écran', W.chrono.vu&&W.cycle.vu, JSON.stringify([W.chrono.vu,W.cycle.vu]));
t('un compteur créé arrive DANS l’écran', W.compteur.vu&&W.compteur.dernierEstUnCompteur, JSON.stringify(W.compteur));
t('un MINUTEUR créé alors qu’un compteur existe amène au MINUTEUR',
  W.minApresCompteur.piegeArme&&W.minApresCompteur.vu, JSON.stringify(W.minApresCompteur));
t('les champs numériques ont le gabarit des champs du projet',
  W.champ.rembourrage&&W.champ.rayon&&W.champ.largeurFilet===1&&W.champ.fond, JSON.stringify(W.champ));


console.log('=== v4.79.0 : ce qui est inerte pendant un déplacement en a l’air ===');
const G=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  if(state.previewFrom){document.getElementById('hdrBack').click();await w(800);}
  if(state.view!=='edit'){const f=fiches.find(x=>!x.deletedAt);await openEdit(f.id);await w(700);}
  const d=state.draft;
  setList(d,'confirmation',['Un critère','Deux']);renderEditor();await w(450);
  /* On mesure la RÈGLE, pas l'intention : encre, fond et curseur des deux boutons que l'utilisateur
     nomme (le ✕ d'une étape — le seul qui soit ROUGE au repos, donc celui où la spécificité pouvait
     échouer — et le B d'une ligne de liste). Et l'on vérifie le RETOUR à l'identique : le dégrisage
     est structurel (`:disabled` disparaît avec l'attribut), il ne doit rien laisser derrière. */
  const cs=e=>e?{c:getComputedStyle(e).color,bg:getComputedStyle(e).backgroundColor,
    cur:getComputedStyle(e).cursor,dis:!!e.disabled}:null;
  const lire=()=>{const b=document.querySelector('.blk:not(.blk-dec)');
    return {stepDel:cs(b.querySelector('.li-tools .del')),
      bold:cs(document.querySelector('.list-edit .bld')),
      poignee:cs(document.querySelector('.blk-top [data-grab]'))};};
  const inp=document.querySelector('.blk:not(.blk-dec) .li input[data-sf]');inp.focus();await w(200);
  const avant=lire();
  document.querySelector('.blk-top [data-grab]').click();await w(500);
  const pendant=lire();
  const surface2=getComputedStyle(document.documentElement).getPropertyValue('--surface-2').trim();
  const bidon=document.createElement('span');bidon.style.background=surface2;document.body.appendChild(bidon);
  const attenduBg=getComputedStyle(bidon).backgroundColor;bidon.remove();
  document.getElementById('edGrabX').click();await w(600);
  const apres=lire();
  return {avant,pendant,apres,attenduBg};});

t('le ✕ d’une étape est ROUGE au repos (le contrôle rencontre son cas)',
  G.avant.stepDel.c!==G.pendant.stepDel.c, `${G.avant.stepDel.c} → ${G.pendant.stepDel.c}`);
t('pendant un déplacement, le ✕ et le B sont grisés',
  G.pendant.stepDel.bg===G.attenduBg&&G.pendant.bold.bg===G.attenduBg, JSON.stringify(G.pendant));
t('… avec le curseur « interdit »',
  G.pendant.stepDel.cur==='not-allowed'&&G.pendant.bold.cur==='not-allowed', JSON.stringify(G.pendant));
t('… et ils sont réellement inertes, pas seulement grisés',
  G.pendant.stepDel.dis&&G.pendant.bold.dis, JSON.stringify(G.pendant));
t('la POIGNÉE, elle, reste active', !G.pendant.poignee.dis&&G.pendant.poignee.cur!=='not-allowed',
  JSON.stringify(G.pendant.poignee));
t('en sortant du mode, tout est DÉGRISÉ à l’identique',
  JSON.stringify(G.apres)===JSON.stringify(G.avant), JSON.stringify(G.apres));

/* ── M1 — LA RANGÉE D'ITEM DE L'ÉDITEUR (v5.0.0, maquettes proto-large) ──────────────────────
   Trois écarts de maquette corrigés d'un coup, et le troisième est le plus fort : une case à
   cocher INERTE dans un éditeur invite au geste qu'elle refuse. La marque de registre la
   remplace — elle DIT le registre au lieu de mimer l'action.
   Le contrôle mesure aussi le 320 px, parce que la rangée porte désormais DEUX champs et TROIS
   mots : c'est exactement là qu'un ajout se paie. */
await p.setViewportSize({width:320,height:640});
const M1=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const f=fiches[0];state.view='edit';state.draft=JSON.parse(JSON.stringify(f));render();await w(400);
  const li=document.querySelector('.blk .li');
  const inp=li?[...li.querySelectorAll('input[type=text]')]:[];
  if(inp[0]){inp[0].value='Geste témoin';inp[0].dispatchEvent(new Event('input',{bubbles:true}));}
  if(inp[1]){inp[1].value='30 mg';inp[1].dispatchEvent(new Event('input',{bubbles:true}));}
  await w(80);
  const it0=bItems(state.draft.blocks[0])[0],do1=it0.do,exp1=it0.expect;
  /* Retaper le `do` SANS « :: » ne doit pas effacer la réponse attendue : ce sont deux champs. */
  if(inp[0]){inp[0].value='Geste témoin bis';inp[0].dispatchEvent(new Event('input',{bubbles:true}));}
  await w(80);
  const it2=bItems(state.draft.blocks[0])[0];
  const r=li.getBoundingClientRect();let mx=0;
  [...li.children].forEach(c=>{const q=c.getBoundingClientRect();if(q.right>mx)mx=q.right;});
  return {nInp:inp.length,do1,exp1,exp2:it2.expect,
    premier:li.firstElementChild?li.firstElementChild.className:'',
    cases:document.querySelectorAll('.li-box').length,
    marques:document.querySelectorAll('.li-mk').length,
    mots:[...document.querySelectorAll('.mini-w')].slice(0,3).map(x=>x.textContent.trim()),
    deb:Math.round(mx-r.right)};});

t('B1 — la rangée d’item porte DEUX champs (`do` et `expect`)', M1.nInp===2, `${M1.nInp} champ(s)`);
t('… et ils écrivent chacun le leur, sans « :: » à composer',
  M1.do1==='Geste témoin'&&M1.exp1==='30 mg', `do=${M1.do1} / expect=${M1.exp1}`);
t('… retaper le geste n’EFFACE PAS la réponse attendue', M1.exp2==='30 mg', `expect=${M1.exp2}`);
t('A4 — plus AUCUNE case à cocher dans l’éditeur', M1.cases===0&&M1.marques>0,
  `${M1.cases} case(s), ${M1.marques} marque(s)`);
t('B7 — la poignée ⠿ est le PREMIER objet de la rangée', /li-grab/.test(M1.premier), M1.premier);
t('B2 — les outils portent leur MOT', /^(registre|vital|vérifier)$/.test(M1.mots[0])&&M1.mots[1]==='mémoire'&&M1.mots[2]==='double', M1.mots.join('·'));
t('… et la rangée ne déborde pas à 320 px', M1.deb<=0, `${M1.deb} px hors de la boîte`);
await p.setViewportSize({width:390,height:900});


/* ─────────────────────────────────────────────────────────────────────────────
   L'ÉDITEUR, PASSE D'UNIFORMISATION (v5.0.0) — sept défauts signalés à l'usage.
   Tous se mesurent sur la MÊME page : on la construit une fois.
   ───────────────────────────────────────────────────────────────────────────── */
await p.setViewportSize({width:390,height:900});
const U=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  await openEdit(fiches[0].id);await w(700);
  /* (1) LA MARQUE DE REGISTRE NE PASSE PAS SOUS LE TEXTE. Le défaut n'existait qu'au FOCUS —
     un `padding` raccourci de la règle `:focus`, déclarée 1 350 lignes plus bas, écrasait le
     `padding-left` longhand qui réserve la place de l'icône. Le témoin doit donc FOCALISER. */
  const li=document.querySelector('.blk .li.li-crit')||document.querySelector('.blk .li');
  const inp=li.querySelector('input[data-sf]'),mk=li.querySelector('.li-mk');
  inp.focus();await w(200);
  const ci=getComputedStyle(inp),ri=inp.getBoundingClientRect();
  const svg=mk&&mk.querySelector('svg'),rs=(svg||mk||inp).getBoundingClientRect();
  const marque=li.classList.contains('li-crit')||li.classList.contains('li-vigil');
  const chevauche=marque&&(ri.left+parseFloat(ci.paddingLeft)+parseFloat(ci.borderLeftWidth))<rs.right;
  /* (7) UNE SEULE VOIX : les deux champs de la rangée, même corps ET même police. */
  const ex=li.querySelector('.li-exp');const ce=getComputedStyle(ex);
  /* (2) LA RÉPONSE ATTENDUE SUIT LA FRAPPE, SANS RE-RENDU : la classe `has-exp` décide de son
     affichage hors focus — posée au rendu seulement, elle restait périmée dans les deux sens. */
  const li2=[...document.querySelectorAll('.blk .li')].find(x=>!x.classList.contains('has-exp'))||li;
  const ex2=li2.querySelector('.li-exp');
  ex2.value='témoin';ex2.dispatchEvent(new Event('input',{bubbles:true}));await w(120);
  const apresAjout=li2.classList.contains('has-exp');
  ex2.value='';ex2.dispatchEvent(new Event('input',{bubbles:true}));await w(120);
  const apresEffacement=li2.classList.contains('has-exp');
  /* (3) LE SÉLECTEUR DE PHASE A LA BOÎTE DE SON VOISIN. */
  const ph=document.querySelector('.blk-phase select'),ti=document.querySelector('.blk-top input[data-bf="title"]');
  /* (5) LE CHAPEAU EST UNE SEULE LISTE, ORDONNÉE PAR LE POOL : une ligne portée par une étape y
     est une rangée COMME LES AUTRES, au champ fermé, et elle se déplace. */
  const fg=[...document.querySelectorAll('.ed-forget .li')];
  const heritee=fg.find(r=>r.querySelector('.fg-st'));
  const propre=fg.find(r=>!r.querySelector('.fg-st'));
  const memeBoite=heritee&&propre
    ?Math.abs(heritee.querySelector('input').getBoundingClientRect().height
      -propre.querySelector('input').getBoundingClientRect().height)<=1:false;
  /* On identifie la ligne par SON texte, pas par sa position : la mesure précédente a pu
     réécrire une étape, donc l'ordre d'avant n'est pas une hypothèse sûre. */
  const herTxt=heritee?heritee.querySelector('input').value:null;
  let deplace=null,apresTxt=null;
  if(heritee&&heritee.querySelector('[data-lgrab]')){
    heritee.querySelector('[data-lgrab]').click();await w(320);
    const d0=document.querySelector('.ed-forget [data-ldrop]');if(d0){d0.click();await w(420);}
    apresTxt=forgetAll(state.draft)[0]||'';
    deplace=!!herTxt&&apresTxt.indexOf(herTxt.slice(0,18))>=0;}
  return {marque,chevauche,fsDo:ci.fontSize,fsEx:ce.fontSize,
    famDo:ci.fontFamily.split(',')[0].trim(),famEx:ce.fontFamily.split(',')[0].trim(),
    apresAjout,apresEffacement,
    phH:ph?Math.round(ph.getBoundingClientRect().height):0,
    tiH:ti?Math.round(ti.getBoundingClientRect().height):0,
    phTag:ph?ph.tagName:'—',
    fgN:fg.length,heritee:!!heritee,ferme:heritee?heritee.querySelector('input').disabled:null,
    memeBoite,deplace,herTxt,apresTxt};});

t('témoin : la rangée mesurée porte bien une marque de registre', U.marque===true, String(U.marque));
t('la marque ⚠ ne passe pas SOUS le texte, même au focus', U.chevauche===false, `chevauche=${U.chevauche}`);
t('les deux champs de la rangée ont la même voix (corps ET police)',
  U.fsDo===U.fsEx&&U.famDo===U.famEx, `${U.fsDo}/${U.famDo} vs ${U.fsEx}/${U.famEx}`);
t('une réponse attendue AJOUTÉE s’affiche hors focus', U.apresAjout===true, String(U.apresAjout));
t('… et EFFACÉE, elle disparaît', U.apresEffacement===false, String(U.apresEffacement));
/* ⚠ MESURÉ À 1280 px, ET C'EST LÀ QUE LE DÉFAUT VIT : à 390 le sélecteur retombait par hasard
   sur la hauteur du champ voisin, si bien qu'un témoin étroit restait vert sur l'écart (39 px
   contre 43, mesurés en large). Un contrôle qui ne rencontre pas son cas ne le couvre pas. */
await p.setViewportSize({width:1280,height:900});
const PH=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  await openEdit(fiches[0].id);await w(700);
  const ph=document.querySelector('.blk-phase select'),ti=document.querySelector('.blk-top input[data-bf="title"]');
  return {tag:ph?ph.tagName:'—',ph:ph?Math.round(ph.getBoundingClientRect().height):0,
    ti:ti?Math.round(ti.getBoundingClientRect().height):0};});
await p.setViewportSize({width:390,height:900});
t('la phase est un SÉLECTEUR, à la boîte de son voisin',
  PH.tag==='SELECT'&&Math.abs(PH.ph-PH.ti)<=1, `${PH.tag} ${PH.ph} px vs ${PH.ti} px`);
t('le chapeau est UNE liste : la ligne héritée y est une rangée fermée',
  U.heritee===true&&U.ferme===true&&U.memeBoite===true,
  `héritée=${U.heritee} fermée=${U.ferme} même boîte=${U.memeBoite}`);
t('… et elle se déplace parmi les autres (ordre du pool)', U.deplace===true,
  `« ${String(U.herTxt).slice(0,28)} » → tête « ${String(U.apresTxt).slice(0,28)} »`);

/* (9) LES DEUX PORTES ONT LE MÊME GABARIT DE RANGÉE. */
const PORTE=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
  const mes=()=>{const r=document.querySelector('.ed-palette .ep-row')||document.querySelector('.ep-row');
    if(!r)return null;const c=getComputedStyle(r);
    return {h:Math.round(r.getBoundingClientRect().height),fs:getComputedStyle(r.querySelector('.ep-n')||r).fontSize,
      ic:!!r.querySelector('.ep-ic'),n:!!r.querySelector('.ep-n')};};
  document.getElementById('edAddOpen').click();await w(350);const A=mes();
  document.querySelector('#edAddModal .ai-x').click();await w(250);
  /* ⚠ UNE SONDE OUVRE PAR LE VRAI POINT D'ENTRÉE (doctrine v4.40.0) : reconstruire l'état à la
     main donnait un éditeur sans sa porte, et le témoin mesurait alors le vide. */
  protocols.push(migrateProtocol({id:'pT',title:'T',kind:'reference',body:''}));
  await openProtocolEdit('pT');await w(700);
  const b=document.getElementById('edAddOpenP');if(!b)return {A,B:null};
  b.click();await w(350);const B=mes();
  return {A,B};});
t('témoin : les deux portes ont été ouvertes', !!PORTE.A&&!!PORTE.B, JSON.stringify(PORTE));
t('… et leurs rangées ont le même gabarit',
  !!PORTE.A&&!!PORTE.B&&PORTE.A.h===PORTE.B.h&&PORTE.A.fs===PORTE.B.fs&&PORTE.B.ic&&PORTE.B.n,
  JSON.stringify(PORTE));

console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);
await br.close();srv.close();process.exit(ko?1:0);
