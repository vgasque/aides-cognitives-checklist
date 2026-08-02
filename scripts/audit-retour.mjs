/* AUDIT — PILE DE RETOUR + MENU ⋯ (ex-« mode lecteur », v4.28.0 → v5.0.0).
   LE MODE LECTEUR A ÉTÉ RETIRÉ AU LOT T14 ; ce harnais NE DISPARAÎT PAS AVEC LUI, et c'est la
   règle 14 appliquée dans le bon sens : sur ses quatorze contrôles, SIX ne mesuraient pas le
   lecteur. Ils restent, et ils sont tout ce qui les vérifie —
     · MENU ⋯ : l'ordre ECAM (conduite → session → gestion → export → danger), la normalisation
       des séparateurs (jamais en tête, jamais doublés), et le fait que deux entrées voisines ne
       portent JAMAIS le même dessin (ladder ≠ flow, archive ≠ history) ;
     · PILE DE RETOUR fiche → fiche : le « ‹ » porte le TITRE de l'origine et y ramène, la garde
       anti double-tap de 700 ms empêche deux taps nerveux de traverser deux niveaux, et passé la
       fenêtre de garde on ressort vers la bibliothèque.
   Supprimer ce fichier avec le lecteur aurait donc emporté six invariants sans rapport — c'est
   exactement la « purge à moitié faite » que la doctrine nomme, à l'envers. */
import { serveApp, moteur, NOM_MOTEUR, ROOT , items, amorce} from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();const p=await br.newPage({viewport:{width:1000,height:950},deviceScaleFactor:2});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
p.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
await p.goto(`http://localhost:${port}/index.html`);
await amorce(p);
await p.evaluate(async()=>{const f=fiches.find(x=>/Arr.t cardiaque/.test(x.title));window.__fid=f.id;
 window.__oid=fiches.find(x=>x.id!==f.id).id;
 f.blocks.push({id:'cxL',kind:'do',title:'Laryngospasme — gestes',items:['Arrêter la stimulation','O2 pur'].map(x=>v4MakeItem(uid('i'),'do',x)),next:null});
 f.excursions=[{label:'Laryngospasme',target:'cxL'}];
 openRead(f.id);await new Promise(r=>setTimeout(r,400));});
console.log('=== menu ⋯ : ordre + icônes ===');
const m=await p.evaluate(async()=>{
 document.getElementById('hdrMore').click();await new Promise(r=>setTimeout(r,250));
 const kids=[...document.getElementById('moreMenu').children];
 const rows=kids.map(x=>x.classList.contains('mm-sep')?'—':x.textContent.replace(/\s+/g,' ').trim());
 document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',bubbles:true}));await new Promise(r=>setTimeout(r,150));
 const ix=re=>rows.findIndex(x=>re.test(x));
 return {rows,noLeadSep:rows[0]!=='—',noDblSep:!rows.some((x,i)=>x==='—'&&rows[i-1]==='—'),
  ordre:ix(/^Complication/)<ix(/Se repérer/)&&ix(/Se repérer/)<ix(/Répéter en exercice/)&&ix(/Répéter en exercice/)<ix(/^Modifier/)&&ix(/^Modifier/)<ix(/^Exporter /),
  icons:uiIcon('ladder')!==uiIcon('flow')&&uiIcon('archive')!==uiIcon('history')&&uiIcon('ladder').includes('svg')&&uiIcon('archive').includes('svg')};});
t('conduite → session → gestion → export (⚡ < repérer < exercice < Modifier < export)', m.ordre, JSON.stringify(m.rows));
t('séparateurs normalisés (jamais en tête, jamais doublés)', m.noLeadSep&&m.noDblSep);
t('icônes distinctes : ladder ≠ flow, archive ≠ history', m.icons);
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
