/* AUDIT — COMPLICATIONS « À TOUT MOMENT » (v4.26.x). Entrée PAR L'ÉVÉNEMENT, modèle QRH : UN
   déclencheur constant (« ⚡ Complication(s) ») ouvre un INDEX par événement — pas un bouton par
   urgence. Excursion tracée, « Terminer » supprimé pendant, RETOUR nommé toujours actif (cases
   neuves — doctrine d'interruption AC 120-71B), sections « À tout moment » hors numérotation,
   cible externe = autre aide, zéro chrome sans déclaration, sélecteur filtrable de l'éditeur. */
import { serveApp, moteur, NOM_MOTEUR, ROOT , items, amorce, ouvrirFiche, demarrerSession } from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();const p=await br.newPage({viewport:{width:1000,height:950},deviceScaleFactor:2});
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
p.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
await p.goto(`http://localhost:${port}/index.html`);
await amorce(p);
await p.evaluate(()=>{const f=fiches.find(x=>/Arr.t cardiaque/.test(x.title));
 f.blocks.push({id:'cxL',kind:'do',title:'Laryngospasme — gestes',items:['Arrêter la stimulation','⚠ PPC + subluxation mandibulaire','Approfondir la sédation'].map(x=>v4MakeItem(uid('i'),'do',x)),next:null});
 const autre=fiches.find(x=>x.id!==f.id);
 f.excursions=[{label:'Laryngospasme',target:'cxL'},{label:'Anaphylaxie',target:autre.id}];
 window.__autre=autre.id;window.__acr=f.id;});
await ouvrirFiche(p,/Arr.t cardiaque/);
await demarrerSession(p);
console.log('=== déclencheur constant + index ===');
const d1=await p.evaluate(async()=>{
 /* v5.6 : le déclencheur ⚡︎ est une TOUCHE DU DOCK, à position constante, et l'index est le
    VOLET qu'elle ouvre. La doctrine mesurée est inchangée — UN objet à index plutôt qu'un bouton
    par urgence, des rangées qui annoncent la destination, aucune fenêtre qui couvre. */
 const btns=[...document.querySelectorAll('#sessionDock #cxKey')].filter(b=>!b.hidden);
 const lbl=btns.map(b=>b.textContent.replace(/\s+/g,' ').trim());
 btns[0].click();await new Promise(r=>setTimeout(r,350));
 const rows=[...document.querySelectorAll('#dockSheet .ds-row')].map(x=>x.textContent.replace(/\s+/g,' ').trim());
 const on=!document.getElementById('dockSheet').hidden;
 const couvre=[...document.querySelectorAll('.ai-modal.on')].length;
 /* ⚠ ON RE-INTERROGE LE DOM : le volet peut avoir re-rendu le journal — le bouton d'avant serait
    un nœud DÉTACHÉ, le cliquer ne ferait rien et le témoin mesurerait l'état inchangé. */
 document.querySelector('#cxKey').click();await new Promise(r=>setTimeout(r,300));
 return {nb:btns.length,lbl,rows,on,couvre,ferme:document.getElementById('dockSheet').hidden};});
t('UN SEUL bouton, mot constant + compte',
  d1.nb===1&&/Complications\s*·\s*2/.test(d1.lbl[0]), JSON.stringify(d1.lbl));
t('l’index liste les 2 événements en grandes rangées',
  d1.rows.length===2&&/Laryngospasme/.test(d1.rows[0])&&/Anaphylaxie/.test(d1.rows[1]), JSON.stringify(d1.rows));
/* ⚠ L'INDEX EST UN VOLET, PAS UNE FENÊTRE (v5.0.0, audit design ; v5.6 : il monte du dock) :
   mesurée, la fenêtre couvrait 38 % de l'écran à 320 px pendant un soin. Un volet est aussi un
   index unique — la doctrine QRH porte sur l'objet, pas sur la modalité. */
t('… et il ne COUVRE rien (volet, pas fenêtre)', d1.couvre===0, `${d1.couvre} fenêtre(s) ouverte(s)`);
t('… re-taper la touche le referme (V1)', d1.ferme===true, JSON.stringify({ferme:d1.ferme}));
/* BIFURCATION ANNONCÉE : chaque rangée dit sa DESTINATION avant le tap — « → bloc n · retour ↩ »
   pour une cible interne, « ↗ » pour une aide externe. On sait où l'on va, et qu'on reviendra. */
t('la cible externe annonce ce qu’elle ouvre (↗)',
  /↗/.test(d1.rows[1])&&/ouvre une autre aide/.test(d1.rows[1]), JSON.stringify(d1.rows[1]));
t('la cible interne annonce sa destination ET son retour',
  /→/.test(d1.rows[0])&&/retour/.test(d1.rows[0]), JSON.stringify(d1.rows[0]));
t('re-presser le déclencheur referme l’index', d1.ferme);
const dm=await p.evaluate(()=>{document.getElementById('hdrMore').click();
 const rows=[...document.querySelectorAll('#moreMenu .mm-row')].map(x=>x.textContent.replace(/\s+/g,' ').trim());
 document.getElementById('hdrMore').click();return rows.filter(x=>/Complication/.test(x));});
t('menu ⋯ : UNE entrée constante « Complications (2) »', dm.length===1&&/\(2\)/.test(dm[0]), JSON.stringify(dm));
console.log('=== entrée / excursion / retour ===');
const d2=await p.evaluate(async()=>{
 {const b=document.querySelector('#cxKey');if(b)b.click();}await new Promise(r=>setTimeout(r,300));
 [...document.querySelectorAll('#dockSheet .ds-row')].find(x=>/Laryngo/.test(x.textContent)).click();
 await new Promise(r=>setTimeout(r,450));
 const cur=document.querySelector('.ov-block.cur');
 return {bout:state.nav[state.nav.length-1],tag:!!cur.querySelector('.cx-tag'),
  pastille:cur.querySelector('.ov-n').textContent.trim(),terminer:!!cur.querySelector('[data-ovend]'),
  reprendre:(cur.querySelector('[data-cxback]')||{}).textContent||null};});
t('l’événement entre au bout du journal', d2.bout==='cxL');
t('passage marqué « ⚡ complication », pastille ⚡', d2.tag&&d2.pastille==='⚡', JSON.stringify(d2));
t('« Terminer l’algorithme » supprimé pendant l’excursion', d2.terminer===false);
t('« ↩ Reprendre » nomme le bloc interrompu', !!d2.reprendre&&/Reprendre/.test(d2.reprendre), ''+d2.reprendre);
const d3=await p.evaluate(async()=>{const avant=state.nav.length;
 document.querySelector('[data-cxback]').click();await new Promise(r=>setTimeout(r,450));
 const cur=document.querySelector('.ov-block.cur');
 return {plus:state.nav.length>avant,neuves:cur.querySelectorAll('ol.steps li:not(.done)').length>0,
  cartes:document.querySelectorAll('.ov-block').length>=3};});
t('Reprendre = NOUVEAU passage, cases neuves (doctrine interruption)', d3.plus&&d3.neuves, JSON.stringify(d3));
t('l’excursion reste tracée (cartes conservées)', d3.cartes);
const d4=await p.evaluate(async()=>{const n0=state.nav.filter(x=>x==='cxL').length;
 document.querySelector('#cxKey').click();await new Promise(r=>setTimeout(r,300));
 [...document.querySelectorAll('#dockSheet .ds-row')].find(x=>/Laryngo/.test(x.textContent)).click();
 await new Promise(r=>setTimeout(r,400));
 return state.nav.filter(x=>x==='cxL').length>n0;});
t('un événement qui SE REPRODUIT = nouveau passage', d4);
console.log('=== bloc de DÉCISION courant (limite v4.26.0 levée) ===');
const d5=await p.evaluate(async()=>{
 document.querySelector('[data-cxback]').click();await new Promise(r=>setTimeout(r,400));
 document.querySelectorAll('.ov-block.cur ol.steps li:not(.done)').forEach(li=>li.click());await new Promise(r=>setTimeout(r,250));
 const nb=document.querySelector('.ov-block.cur [data-ovnext]');if(nb)nb.click();await new Promise(r=>setTimeout(r,450));
 const cur=document.querySelector('.ov-block.cur');
 /* v5.6 : le déclencheur ⚡︎ a quitté la carte pour le DOCK — la propriété mesurée reste la
    même (« il existe aussi quand le bloc courant est une décision »), seule son adresse change :
    il est désormais à position CONSTANTE, ce qui la renforce plutôt qu'il ne l'affaiblit. */
 const k=document.getElementById('cxKey');
 return {dec:cur.classList.contains('dec'),btn:!!k&&!k.hidden};});
t('le déclencheur vit AUSSI sur un bloc de décision courant', d5.dec&&d5.btn, JSON.stringify(d5));
console.log('=== échelle / statique / externe / sans ===');
/* ⚠ « À TOUT MOMENT » A QUITTÉ LA COLONNE D'ORIENTATION (v5.0.0, demande utilisateur : « c'est
   inutile ») — elle oriente dans la SÉQUENCE, or une complication n'y est pas. Le contrôle suit le
   composant plutôt que de disparaître avec lui (règle 14) : la section vit toujours dans la vue
   « Toute la fiche », onglet Parcours, et c'est là qu'on vérifie les deux invariants — elle EXISTE,
   et le tronc n'est pas pollué par son bloc. */
const d6=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
 const lad=document.querySelector('.read-side .rail-lad');
 const colonne={cx:lad?lad.querySelectorAll('.pl-line.cxl').length:0,
   pollue:[...(lad?lad.querySelectorAll('.pl-line .t'):[])].some(x=>/Laryngo/.test(x.textContent))};
 document.getElementById('allBtn').click();await w(700);
 document.querySelector('[data-alltab="parcours"]').click();await w(600);
 const sec=[...document.querySelectorAll('.pc-wrap .pl-sech')].some(x=>/tout moment/i.test(x.textContent));
 const cartes=document.querySelectorAll('.pc-wrap .pc-card.exc').length;
 document.getElementById('allBtn').click();await w(600);
 return {colonne,sec,cartes};});
t('la colonne d’orientation ne porte plus la section', d6.colonne.cx===0&&!d6.colonne.pollue, JSON.stringify(d6.colonne));
t('« Toute la fiche » : section « À tout moment », une carte', d6.sec&&d6.cartes===1, JSON.stringify(d6));
const d7=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
 document.getElementById('allBtn').click();await w(600);
 /* ⚠ ON REVIENT À L'ONGLET « PAGE » : le contrôle précédent a laissé « Parcours » sélectionné, et
    l'onglet n'est pas persisté mais il survit à la fermeture de la feuille. Sans cela on mesure la
    vue en cartes en croyant mesurer le tableau. */
 {const pg=document.querySelector('[data-alltab="page"]');if(pg)pg.click();}await w(600);
 /* ⚠ CE TÉMOIN A CHANGÉ DE PORTEUR, PAS D'OBJET (lot Page, v5.10.0). La section « ⚡ À tout
    moment » vivait en PIED du tableau, sous une bande-intertitre ; depuis la feuille, une
    complication n'est plus la suite de l'algorithme — c'est ce qui peut survenir pendant qu'on
    le déroule, donc elle vit dans la COLONNE DE RÉFÉRENCE, à côté des surveillances. Ce qui est
    mesuré reste la PROPRIÉTÉ : elle est là, elle porte ⚡ et non un numéro de séquence (le
    numéroter la ferait lire comme « l'étape d'après », défaut mesuré en v4.26.0), et elle est
    HORS de la grille de l'algorithme. */
 const cell=document.querySelector('.sv-ref .sv-cell.sv-cx');
 return {ref:!!cell,horsGrille:!document.querySelector('.sv-algo .sv-cx'),
   num:cell?cell.querySelector('.sv-n').textContent.trim():null};});
t('Statique : la complication vit dans la colonne de référence, sans numéro (⚡)',
  d7.ref&&d7.horsGrille&&d7.num==='⚡', JSON.stringify(d7));
/* LE SCHÉMA DIT AUSSI « À TOUT MOMENT » (v5.0.9). Il était la SEULE des quatre vues de structure
   où une cible de complication se dessinait comme un bloc d'étapes ordinaire — donc comme l'étape
   d'après, le défaut mesuré en v4.26.0. On mesure la PROPRIÉTÉ (le nœud se distingue par un mot
   ET par le registre, et les autres nœuds ne l'empruntent pas), jamais la valeur d'un hex isolé —
   un témoin qui figerait la teinte rougirait sur un changement de token qui serait juste. */
const dsvg=await p.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
 {const sc=document.querySelector('[data-alltab="schema"]');if(sc)sc.click();}await w(700);
 const svg=document.querySelector('#allSheet .flow-scroll svg')||document.querySelector('.flow-scroll svg');
 if(!svg)return {err:'pas de svg'};
 const lire=g=>({lab:g.getAttribute('aria-label')||'',
   mots:[...g.querySelectorAll('text')].map(t=>t.textContent).join(' | '),
   bd:(g.querySelector('.fn-bd')||{getAttribute:()=>null}).getAttribute('stroke')});
 const tous=[...svg.querySelectorAll('.fnode')].map(lire);
 const cx=tous.find(n=>/Laryngospasme/.test(n.lab)),autres=tous.filter(n=>!/Laryngospasme/.test(n.lab));
 return {n:tous.length,cx,autresCadres:[...new Set(autres.map(a=>a.bd))],
   autresMots:autres.filter(a=>/TOUT MOMENT/.test(a.mots)).length};});
t('… et le contrôle RENCONTRE SON CAS (le nœud existe dans le schéma)', !!(dsvg.cx), JSON.stringify(dsvg&&dsvg.err));
t('Schéma : la cible ⚡ porte « À TOUT MOMENT » en toutes lettres', !!(dsvg.cx&&/TOUT MOMENT/.test(dsvg.cx.mots)), JSON.stringify(dsvg.cx&&dsvg.cx.mots));
t('… et l’annonce au lecteur d’écran le dit aussi', !!(dsvg.cx&&/tout moment/i.test(dsvg.cx.lab)), JSON.stringify(dsvg.cx&&dsvg.cx.lab));
t('… son cadre passe au registre ALERTE, les autres NON', !!(dsvg.cx&&dsvg.cx.bd&&!dsvg.autresCadres.includes(dsvg.cx.bd)), JSON.stringify({cx:dsvg.cx&&dsvg.cx.bd,autres:dsvg.autresCadres}));
t('… et aucun autre nœud n’emprunte le mot', dsvg.autresMots===0, ''+dsvg.autresMots);
const d8=await p.evaluate(async()=>{
 document.getElementById('allBtn').click();await new Promise(r=>setTimeout(r,500));
 document.querySelector('#cxKey').click();await new Promise(r=>setTimeout(r,300));
 [...document.querySelectorAll('#dockSheet .ds-row')].find(x=>/Anaphyl/.test(x.textContent)).click();
 await new Promise(r=>setTimeout(r,500));
 return {ouvert:state.fiche&&state.fiche.id===window.__autre};});
t('cible EXTERNE : ouvre l’autre aide', d8.ouvert, JSON.stringify(d8));
const d9=await p.evaluate(async()=>{const f2=fiches.find(x=>x.id===window.__autre);f2.excursions=[];
 render();await new Promise(r=>setTimeout(r,400));
 const k=document.getElementById('cxKey');
 return {btn:(k&&!k.hidden)?1:0,sec:document.querySelectorAll('.pl-sech.cx').length};});
t('fiche SANS complications : zéro chrome ⚡', d9.btn===0&&d9.sec===0, JSON.stringify(d9));
console.log('=== éditeur : sélecteur filtrable à deux groupes ===');
const d10=await p.evaluate(async()=>{
 openEdit(window.__autre);await new Promise(r=>setTimeout(r,450));
 /* v4.70.1 : la sonde cliquait `#addCx`, l'un des SIX boutons d'ajout que la v4.65.0 a
    remplacés par UNE porte « ＋ Bloc · décision · minuteur… ». Elle plantait donc depuis, et
    comme `npm run audit` chaîne les harnais par `&&`, elle emportait les CINQ suivants avec
    elle. On passe désormais par la porte réelle — c'est le chemin de l'auteur. */
 document.getElementById('edAddOpen').click();await new Promise(r=>setTimeout(r,350));
 document.querySelector('#edAddBody [data-edadd="cx"]').click();await new Promise(r=>setTimeout(r,400));
 const row=document.querySelector('.cx-edit-row');if(!row)return {row:false};
 row.querySelector('[data-cxpicker]').click();await new Promise(r=>setTimeout(r,350));
 const heads=[...document.querySelectorAll('#relPickList .pick-h')].map(x=>x.textContent);
 const titre=document.getElementById('relPickTitle').textContent;
 // filtrer puis choisir le premier bloc
 const inp=document.getElementById('relPickQ');inp.value='';inp.dispatchEvent(new Event('input'));
 await new Promise(r=>setTimeout(r,200));
 const first=document.querySelector('#relPickList [data-pick]');const pickId=first.dataset.pick;first.click();
 await new Promise(r=>setTimeout(r,350));
 const btn=document.querySelector('.cx-edit-row .cx-tgt');
 return {row:true,heads,titre,cible:state.draft.excursions[0].target===pickId,
  nom:btn?btn.textContent.trim():null,modalFermee:!document.getElementById('relPickModal').classList.contains('on')};});
t('le sélecteur filtrable s’ouvre, titré pour la complication', d10.row&&/Cible de la complication/.test(d10.titre), JSON.stringify({titre:d10.titre}));
t('deux groupes : blocs de la fiche PUIS aides & protocoles', d10.heads&&d10.heads.length===2&&/Blocs/.test(d10.heads[0]), JSON.stringify(d10.heads));
t('choisir pose la cible et referme ; le bouton affiche le nom', d10.cible&&d10.modalFermee&&!!d10.nom&&!/Choisir/.test(d10.nom), JSON.stringify({nom:d10.nom}));
await p.close();await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);process.exit(ko?1:0);
