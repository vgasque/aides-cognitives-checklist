/* AUDIT — MODE LECTEUR ENRICHI + PILE DE RETOUR + MENU ⋯ (v4.28.0).
   v4.62.0 (I4) : le lecteur n'a plus de vocabulaire parallèle — il ÉMET les verbes du journal
   (`data-ovnext`, `data-ovopt`, `data-cxback`). Les sondes suivent ce vocabulaire unique ;
   `data-rmok`/`data-rmgap` restent propres à la passe challenge-réponse, sans jumeau ailleurs.
   Lecteur : l'état ne disparaît jamais (bande minuteurs propre, échu ambre + mot), carte des
   blocs (modèle ECL), contexte précédent/suivant, ⚡ au-dessus de l'overlay, excursion =
   « Reprendre » jamais « Terminer ». Pile : le « ‹ » ramène à l'ORIGINE (fiche → fiche), garde
   anti double-tap 700 ms. Menu ⋯ : conduite → session → gestion → export → danger ; icônes
   distinctes (ladder ≠ flow, archive ≠ history). */
import { serveApp, moteur, NOM_MOTEUR, ROOT } from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();const p=await br.newPage({viewport:{width:1000,height:950},deviceScaleFactor:2});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
p.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
await p.goto(`http://localhost:${port}/index.html`);await p.waitForFunction(()=>!document.querySelector('.boot-load'));
await p.evaluate(async()=>{const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await new Promise(r=>setTimeout(r,150));
 const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await new Promise(r=>setTimeout(r,400));
 const f=fiches.find(x=>/Arr.t cardiaque/.test(x.title));window.__fid=f.id;
 window.__oid=fiches.find(x=>x.id!==f.id).id;
 f.blocks.push({id:'cxL',type:'steps',title:'Laryngospasme — gestes',steps:['Arrêter la stimulation','O2 pur'],next:null});
 f.complications=[{label:'Laryngospasme',target:'cxL'}];
 openRead(f.id);await new Promise(r=>setTimeout(r,400));});
console.log('=== menu ⋯ : ordre + icônes ===');
const m=await p.evaluate(async()=>{
 document.getElementById('hdrMore').click();await new Promise(r=>setTimeout(r,250));
 const kids=[...document.getElementById('moreMenu').children];
 const rows=kids.map(x=>x.classList.contains('mm-sep')?'—':x.textContent.replace(/\s+/g,' ').trim());
 document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',bubbles:true}));await new Promise(r=>setTimeout(r,150));
 const ix=re=>rows.findIndex(x=>re.test(x));
 return {rows,noLeadSep:rows[0]!=='—',noDblSep:!rows.some((x,i)=>x==='—'&&rows[i-1]==='—'),
  ordre:ix(/^Complication/)<ix(/Mode lecteur/)&&ix(/Mode lecteur/)<ix(/Se repérer/)&&ix(/Se repérer/)<ix(/Répéter en exercice/)&&ix(/Répéter en exercice/)<ix(/^Modifier/)&&ix(/^Modifier/)<ix(/^Exporter /),
  icons:uiIcon('ladder')!==uiIcon('flow')&&uiIcon('archive')!==uiIcon('history')&&uiIcon('ladder').includes('svg')&&uiIcon('archive').includes('svg')};});
t('conduite → session → gestion → export (⚡ < lecteur < repérer < exercice < Modifier < export)', m.ordre, JSON.stringify(m.rows));
t('séparateurs normalisés (jamais en tête, jamais doublés)', m.noLeadSep&&m.noDblSep);
t('icônes distinctes : ladder ≠ flow, archive ≠ history', m.icons);
console.log('=== lecteur : état toujours visible ===');
const r1=await p.evaluate(async()=>{
 document.querySelector('.ov-block.cur ol.steps li').click();await new Promise(r=>setTimeout(r,400));
 const ts=Object.values(Runtime.timers);
 if(ts[0]){ts[0].running=true;ts[0].lastStart=Date.now();}
 Runtime.timers['audx']={id:'audx',label:'Cycle RCP',type:'interval',seconds:120,elapsedMs:120000,running:false,lastStart:0};
 readerOpen();updateRtStrip(Date.now());await new Promise(r=>setTimeout(r,250));
 const segs=[...document.querySelectorAll('#rmTimers .rm-seg')];
 return {n:segs.length,strip:!document.getElementById('rmTimers').hidden,
  dueFirst:segs.length>1?segs[0].classList.contains('due')&&/échu/.test(segs[0].textContent):null,
  time:document.getElementById('rmTime').textContent,
  map:!document.getElementById('rmMap').hidden,
  nd:document.querySelectorAll('#rmMap .rm-nd').length,
  cur:document.querySelectorAll('#rmMap .rm-nd.cur').length};});
t('bande minuteurs du lecteur : visible, échu EN TÊTE ambre + mot « échu »', r1.strip&&r1.n>=2&&r1.dueFirst===true, JSON.stringify(r1));
t('carte des blocs (ECL) : pastilles = blocs du plan, une seule position ●', r1.map&&r1.nd>0&&r1.cur===1, JSON.stringify({nd:r1.nd,cur:r1.cur}));
const r2=await p.evaluate(async()=>{
 /* I4 (v4.62.0) : LE CONTEXTE N'EST PLUS RECONSTRUIT, IL EST STRUCTUREL. Ce contrôle cherchait
    `.rm-ctx` — deux lignes que le lecteur recopiait à côté d'un paragraphe isolé. Le lecteur rend
    désormais la MÊME liste que la page (`ol.steps > li[data-ck]`), curseur sur `.cur-step` : le
    précédent et le suivant sont là par construction, avec leur état et leur registre réels.
    On mesure donc la PROPRIÉTÉ (le contexte est visible, l'étape faite est marquée) et non plus
    le mécanisme — et ce contrôle échouerait si la liste redevenait un item isolé. */
 const lire=()=>{const li=[...document.querySelectorAll('#rmBody .rm-steps li')];
   const iCur=li.findIndex(x=>x.classList.contains('cur-step'));
   return {n:li.length,iCur,aSuivant:iCur>=0&&iCur<li.length-1,
     aPrecedent:iCur>0,precedentFait:iCur>0&&li[iCur-1].classList.contains('done'),
     memeVerbe:li.every(x=>x.hasAttribute('data-ck'))};};
 const avant=lire();
 document.querySelector('[data-rmok]').click();await new Promise(r=>setTimeout(r,250));
 const apres=lire();
 return {avant,apres};});
t('contexte STRUCTUREL : le suivant est visible au 1ᵉʳ challenge, le précédent COCHÉ au 2ᵉ',
  r2.avant.aSuivant&&r2.apres.aPrecedent&&r2.apres.precedentFait, JSON.stringify(r2));
t('I4 : la liste du lecteur est celle de la page — mêmes lignes, même verbe data-ck',
  r2.avant.n>1&&r2.avant.memeVerbe&&r2.apres.memeVerbe, JSON.stringify(r2));
console.log('=== lecteur : ⚡ et excursion ===');
const r3=await p.evaluate(async()=>{
 const cb=document.getElementById('rmCx');
 const vis=!cb.hidden;cb.click();await new Promise(r=>setTimeout(r,300));
 const zCx=+getComputedStyle(document.getElementById('cxModal')).zIndex;
 const zRm=+getComputedStyle(document.getElementById('readerMode')).zIndex;
 document.querySelector('#cxList .cx-item').click();await new Promise(r=>setTimeout(r,400));
 const blk=document.getElementById('rmBlock').textContent;
 document.querySelector('[data-rmok]').click();await new Promise(r=>setTimeout(r,200));
 document.querySelector('[data-rmok]').click();await new Promise(r=>setTimeout(r,300));
 const h=document.getElementById('rmBody').innerHTML;
 return {vis,zCx,zRm,blk,repr:/data-cxback/.test(h)&&/Reprendre/.test(h),pasTerminer:!/Terminer l’algorithme/.test(h)};});
t('⚡ visible dans le lecteur, index AU-DESSUS de l’overlay', r3.vis&&r3.zCx>r3.zRm, `z ${r3.zCx} vs ${r3.zRm}`);
t('excursion pilotée dans le lecteur (bloc Laryngospasme)', /Laryngospasme/.test(r3.blk), r3.blk);
t('fin d’excursion : « ↩ Reprendre », JAMAIS « Terminer » (parcours interrompu)', r3.repr&&r3.pasTerminer);
const r4=await p.evaluate(async()=>{
 document.querySelector('[data-cxback]').click();await new Promise(r=>setTimeout(r,350));
 const blk=document.getElementById('rmBlock').textContent;
 document.getElementById('rmClose').click();await new Promise(r=>setTimeout(r,300));
 return {blk};});
t('« Reprendre » ramène au bloc interrompu (nouveau passage)', !/Laryngospasme/.test(r4.blk), r4.blk);
console.log('=== pile de retour + garde double-tap ===');
const r5=await p.evaluate(async()=>{
 const A=fiches.find(x=>x.id===window.__fid);
 openRel(window.__oid);await new Promise(r=>setTimeout(r,400));
 const lbl=document.getElementById('hdrBackLbl').textContent;
 const hb=document.getElementById('hdrBack');
 hb.click();await new Promise(r=>setTimeout(r,150));hb.click();hb.click();await new Promise(r=>setTimeout(r,400));
 const apres={vue:state.view,surOrigine:!!(state.fiche&&state.fiche.id===window.__fid),guard:hb.classList.contains('guarded')};
 await new Promise(r=>setTimeout(r,800));
 document.getElementById('hdrBack').click();await new Promise(r=>setTimeout(r,400));
 return {lblA:A.title,lbl,apres,fin:state.view};});
t('« ‹ » porte le TITRE de la fiche d’origine', r5.lbl===r5.lblA, r5.lbl);
t('triple tap nerveux : on est sur l’ORIGINE, jamais à la bibliothèque (garde 700 ms + .guarded)',
  r5.apres.vue==='read'&&r5.apres.surOrigine&&r5.apres.guard, JSON.stringify(r5.apres));
t('après la fenêtre de garde, « ‹ » sort vers la bibliothèque (pile vidée)', r5.fin==='library');
await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
