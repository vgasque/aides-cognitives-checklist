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
import { serveApp, moteur, NOM_MOTEUR, ROOT , items, amorce, ouvrirFiche, demarrerSession } from './harness.mjs';

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
/* ═══ PILE DU QUAI (v5.19.1, audit design v5.19) — deux invariants nés d'un bug mesuré :
   Tout voir → Consulter (colonne du cockpit, DANS `main`) → « Un bloc » ; le rendu complet du
   retour détruisait la colonne mais `body.ref-col-on` et le `dp-back` de #refBtn survivaient —
   « Revenir » vert plein masquait la commande Consulter, un tap le dissipait sans autre effet.
   Et pendant que les deux feuilles étaient ouvertes, DEUX primaires vertes voisines.
   Invariants : (1) après toute séquence ouvrir/fermer croisée, AUCUN bouton de retour dont le
   niveau de pile est résolu ; (2) jamais plus d'UNE primaire verte — le sommet de pile. */
console.log('=== pile du QUAI : dp-back purgé quelle que soit la porte de sortie, une seule primaire verte ===');
{
 const p2=await br.newPage({viewport:{width:1280,height:800}});
 p2.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
 await p2.goto(`http://localhost:${port}/index.html`);
 await amorce(p2);await ouvrirFiche(p2,'Arr.t cardiaque');await demarrerSession(p2);
 const lit=()=>p2.evaluate(()=>({
   verts:[...document.querySelectorAll('#sessionDock .sd-key.dp-back')].filter(b=>!b.hidden).length,
   allBack:document.getElementById('allBtn').classList.contains('dp-back'),
   refBack:document.getElementById('refBtn').classList.contains('dp-back'),
   refLbl:document.querySelector('#refBtn .dp-lbl').textContent.trim(),
   colOn:document.body.classList.contains('ref-col-on'),
   colDom:!!document.querySelector('.read-side .ref-col'),
   modalOn:document.getElementById('refModal').classList.contains('on')}));
 const tap=async id=>{await p2.evaluate(i=>document.getElementById(i).click(),id);
   await p2.waitForTimeout(500);};
 await tap('allBtn');const e1=await lit();
 await tap('refBtn');const e2=await lit();
 await tap('allBtn');const e3=await lit();
 await tap('refBtn');const e4=await lit();
 t('Tout voir : « Un bloc » seul porte le vert', e1.verts===1&&e1.allBack&&!e1.refBack, JSON.stringify(e1));
 t('Consulter PAR-DESSUS : le sommet de pile prend le vert, « Un bloc » le rend (jamais deux)',
   e2.verts===1&&e2.refBack&&!e2.allBack&&e2.colOn&&e2.colDom, JSON.stringify(e2));
 t('« Un bloc » dépile TOUT : aucun retour résolu encore affiché, état Consulter purgé',
   e3.verts===0&&e3.refLbl==='Consulter'&&!e3.colOn&&!e3.colDom&&!e3.modalOn, JSON.stringify(e3));
 t('… et le re-tap Consulter rouvre une VRAIE consultation (pas un fantôme à dissiper)',
   e4.refBack&&e4.colOn&&e4.colDom, JSON.stringify(e4));
 /* La fermeture par la porte NORMALE rend le vert au niveau du dessous. */
 await tap('allBtn');await tap('refBtn');await tap('refBtn');const e5=await lit();
 t('fermer Consulter pendant l’excursion : le vert REDESCEND sur « Un bloc »',
   e5.verts===1&&e5.allBack&&!e5.refBack&&e5.refLbl==='Consulter', JSON.stringify(e5));
 await p2.close();
}
await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
