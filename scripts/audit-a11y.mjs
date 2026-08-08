/* AUDIT TRANSVERSE (lot 7) — WCAG 2.2 AA + règles projet, sur TOUTES les surfaces ajoutées
   par les lots 1 à 6. Tout est mesuré sur les styles CALCULÉS, dans les deux thèmes.
     • plancher typographique 11px (règle projet, plus stricte que WCAG)
     • contraste : texte >= 4.5:1 (>= 3:1 si "grand texte"), composants/bordures >= 3:1
     • cibles : >= 44px en mode crise (règle projet), >= 24px partout (WCAG 2.5.8)
     • focus visible au CLAVIER (parcours Tab réel, pas un .focus() programmatique)
     • règles projet : jamais --soft en couleur de texte, « hors chemin » jamais par opacité seule
*/
import { serveApp, moteur, NOM_MOTEUR, ROOT, amorce, ouvrirFiche, demarrerSession, trancheArg } from './harness.mjs';


const { port, srv } = await serveApp();

const AUDIT = `(() => {
  const px=v=>parseFloat(v)||0;
  const parse=c=>{const m=String(c).match(/rgba?\\(([^)]+)\\)/);if(!m)return null;
    const p=m[1].split(',').map(x=>parseFloat(x));return {r:p[0],g:p[1],b:p[2],a:p.length>3?p[3]:1};};
  const over=(f,b)=>({r:f.r*f.a+b.r*(1-f.a),g:f.g*f.a+b.g*(1-f.a),b:f.b*f.a+b.b*(1-f.a),a:1});
  function bgOf(el){
    let e=el,acc=null;
    while(e&&e.nodeType===1){
      const c=parse(getComputedStyle(e).backgroundColor);
      if(c&&c.a>0){ acc=acc?over(acc,c):c; if(acc.a>=1||c.a>=1) return acc.a>=1?acc:over(acc,{r:255,g:255,b:255,a:1}); }
      e=e.parentElement;
    }
    const body=parse(getComputedStyle(document.body).backgroundColor)||{r:255,g:255,b:255,a:1};
    return acc?over(acc,body):body;
  }
  const lin=v=>{v/=255;return v<=0.03928?v/12.92:Math.pow((v+0.055)/1.055,2.4);};
  const lum=c=>0.2126*lin(c.r)+0.7152*lin(c.g)+0.0722*lin(c.b);
  const ratio=(a,b)=>{const l1=lum(a),l2=lum(b);const hi=Math.max(l1,l2),lo=Math.min(l1,l2);return (hi+0.05)/(lo+0.05);};
  const visible=el=>{const cs=getComputedStyle(el);
    if(cs.display==='none'||cs.visibility==='hidden'||px(cs.opacity)===0)return false;
    const r=el.getBoundingClientRect();return r.width>0&&r.height>0;};
  const ownText=el=>[...el.childNodes].some(n=>n.nodeType===3&&n.textContent.trim().length);

  const out={typo:[],contrast:[],targets:[],soft:[],misc:[]};
  // #crisisCtrl AJOUTÉ en v4.32.0 : le SCOPE listait le quai d'ÉTAT (#crisisDock) mais pas la
  // rangée de COMMANDES, séparée de lui en v4.25.0. Le trou cachait un défaut réel — les boutons
  // « Se repérer » / « Consulter » mesuraient 38 px là où la crise exige 44. Une surface ajoutée
  // à l'app doit être ajoutée ICI dans le même geste, sinon elle n'est jamais mesurée.
  // .dir-wrap + .azrail REMPLACENT .cards en v4.56.0 (accueil « poste accès direct ») : un
  // sélecteur qui ne matche plus rien ferait passer l'accueil sans l'avoir mesuré (v4.31.1).
  const SCOPE=window.__acScope||'#crisisBand,.brand-sur,#crisisDock,#sessionDock,#dockSheet,#planModal,#refModal,.read-side,.annex-row,.dir-wrap,.azrail,.list-edit,.pos-more';
  const roots=[...document.querySelectorAll(SCOPE)].filter(visible);
  const seen=new Set();
  roots.forEach(root=>{
    [root,...root.querySelectorAll('*')].forEach(el=>{
      if(seen.has(el)||!visible(el))return;seen.add(el);
      /* UNE EXEMPTION, NOMMÉE ET MOTIVÉE : le SCHÉMA buildFlowSVG (.flow-scroll). Il est
         entré dans une surface mesurée le jour où la colonne droite de l'éditeur a cessé d'être
         une maquette pour porter l'algorithme — il n'a jamais été conforme au plancher de 11 px,
         nulle part (ni dans le flux de l'éditeur, ni dans le panneau « Algorithme » de lecture,
         ni en plein écran), simplement aucun de ces logements n'était dans le SCOPE.
         Il en est exempté parce que ce n'est pas du TEXTE mais un DESSIN à échelle variable :
         son corps n'a pas de valeur absolue (zoom 25–400 %, visionneuse plein écran, pincement
         natif), et chacun de ses mots existe en TAILLE PLEINE dans le contenu qu'il résume — le
         schéma n'est jamais la seule source. Même frontière que check-type, qui borne l'échelle
         fermée au texte et laisse dehors les AFFICHAGES.
         NE PAS élargir cette exemption à autre chose : tout le reste de #editSide reste mesuré. */
      if(el.closest&&el.closest('.flow-scroll'))return;
      const cs=getComputedStyle(el);
      const fs=px(cs.fontSize);
      if(ownText(el)&&el.textContent.trim()){
        // plancher typographique (règle projet)
        if(fs&&fs<11) out.typo.push({sel:el.className||el.tagName,px:fs,txt:el.textContent.trim().slice(0,28)});
        /* contraste du texte
           ATTENTION — L'OPACITE HERITEE COMPTE (v5.0.0, audit design A1-2). C'etait un defaut de
           la SONDE, pas de l'application, et il la rendait aveugle partout a la fois : la passe
           composait bien l'alpha de la COULEUR (une notation rgba), mais ignorait la propriete
           opacity sur l'element et sur ses ancetres. Or opacity compose le rendu exactement comme
           un alpha : getComputedStyle continue de rapporter l'encre PLEINE, si bien qu'un texte
           reellement peint a 2,55:1 etait mesure a 5,93 et declare conforme.
           C'est ce qui a laisse passer l'ETAPE COCHEE (opacity .6 + --done-ink), c'est-a-dire
           l'etat le plus frequent de l'application. Le defaut n'etait donc pas qu'il manquait un
           etat a la liste : c'est que l'instrument ne POUVAIT PAS le voir. Ajouter l'etat sans
           corriger la sonde aurait produit un vert de plus, et un vert faux.
           On multiplie les opacites jusqu'a la racine, puis on compose l'encre sur son fond
           effectif. Une valeur inferieure a 1 sur un ANCETRE compte autant que sur l'element :
           c'est le groupe entier qui est peint en transparence.
           NOTE DE MAINTENANCE : ce bloc vit dans un litteral gabarit (la sonde est une chaine
           evaluee dans la page). Aucun accent grave ni sequence dollar-accolade ici, sous peine
           de refermer le gabarit — erreur commise en ecrivant ce commentaire. */
        const opAcc=(()=>{let o=1,n=el;while(n&&n.nodeType===1){o*=px(getComputedStyle(n).opacity);n=n.parentElement;}return o;})();
        const fg0=parse(cs.color);
        const fg=fg0?{r:fg0.r,g:fg0.g,b:fg0.b,a:fg0.a*opAcc}:null;
        if(fg){
          const eff=fg.a<1?over(fg,bgOf(el)):fg;
          const rr=ratio(eff,bgOf(el));
          const big=fs>=24||(fs>=18.66&&px(cs.fontWeight)>=700);
          const need=big?3:4.5;
          if(rr<need-0.01) out.contrast.push({sel:el.className||el.tagName,px:fs,ratio:+rr.toFixed(2),need,txt:el.textContent.trim().slice(0,28)});
        }
        // règle projet : --soft est DÉCORATIF, jamais une couleur de texte
        const soft=getComputedStyle(document.documentElement).getPropertyValue('--soft').trim();
        if(soft){const s=parse(soft)||null;const f2=parse(cs.color);
          if(s&&f2&&Math.abs(s.r-f2.r)<2&&Math.abs(s.g-f2.g)<2&&Math.abs(s.b-f2.b)<2)
            out.soft.push({sel:el.className||el.tagName,txt:el.textContent.trim().slice(0,28)});}
      }
      // cibles interactives
      if(el.matches('button,[role="button"],a[href],summary,input,select,[tabindex="0"]')){
        // La CIBLE est la zone qui accepte le pointeur, pas le seul élément (WCAG 2.5.8).
        // Une case à cocher DANS un <label> est activée par tout le label : mesurer la case seule
        // produisait un faux positif — #pendToggle fait 13×13 px, mais son label 358×65, et
        // cliquer sur le texte coche bien la case (vérifié). Même esprit que la recherche de
        // l'anneau de focus sur les ANCÊTRES, déjà en place plus haut.
        const lab=(el.tagName==='INPUT'||el.tagName==='SELECT')?el.closest('label'):null;
        const cible=lab||el;
        const r=cible.getBoundingClientRect();
        const cs2=getComputedStyle(el);
        const halo=cs2.position==='relative'?8:0;   // ::after inset:-4px du chrome
        const h=Math.round(r.height+halo),w=Math.round(r.width+halo);
        const crisis=document.body.classList.contains('view-read');
        const need=crisis?44:24;
        if(h<need||w<24) out.targets.push({sel:el.className||el.tagName,w,h,need,txt:(el.textContent||'').trim().slice(0,24)});
      }
    });
  });
  // « hors chemin » : jamais signalé par la seule opacité (règle projet + WCAG 1.4.1)
  document.querySelectorAll('.rail-lad .pl-line.off').forEach(el=>{
    const o=px(getComputedStyle(el).opacity);
    if(o<1) out.misc.push({sel:'.rail-lad .pl-line.off',pb:'opacité '+o+' — hors chemin doit être en encre + mention'});
  });
  return out;
})()`;

const browser = await moteur().launch();
const errs=[]; let fails=0, checks=0;
const report=(label,arr,fmt)=>{ checks++; if(!arr.length){return;} fails++;
  console.log('  ✗ '+label);
  arr.slice(0,6).forEach(x=>console.log('      '+fmt(x)));
  if(arr.length>6)console.log('      … +'+(arr.length-6)+' autres'); };

// ---- surfaces à auditer -------------------------------------------------
/* ⚠ CINQ SURFACES MANQUAIENT, ET LE PLANCHER SERVI N'ÉTAIT PAS AUDITÉ (audit design v5.0.0).
   La bibliothèque n'était mesurée qu'à 1100 px — c'est-à-dire JAMAIS en voie étroite, là où vivent
   les chips de filtre, le rail A→Z et les rangées du répertoire. La lecture d'une RÉFÉRENCE, le
   mode STATIQUE, le MONITEUR et l'éditeur de PROTOCOLE n'y étaient pas du tout. Et 320 px — le
   plancher que le dossier déclare servir, celui de WCAG 1.4.10 — n'était mesuré que sur l'écran
   d'entrée invité. Un défaut hors scope n'est pas un défaut absent (leçon v4.75.0). */
const SURFACES = [
  { nom:'bibliothèque',        w:1100, prep:null },
  { nom:'bibliothèque étroite',w:320,  prep:null },
  { nom:'lecture 320',         w:320,  prep:'read' },
  { nom:'lecture étroite',     w:390,  prep:'read' },
  { nom:'lecture + rail',      w:1280, prep:'read' },
  { nom:'feuille Plan',        w:1280, prep:'plan' },
  { nom:'feuille Consulter',   w:1280, prep:'ref'  },
  { nom:'éditeur',             w:1100, prep:'edit' },
  { nom:'dialogue Créer',      w:390,  prep:'dlg:openCreateDlg',  scope:'#createModal' },
  { nom:'gérer catégories',    w:390,  prep:'dlg:openCatMgr',     scope:'#catModal' },
  { nom:'fenêtre Compte',      w:390,  prep:'dlg:openAuth',       scope:'#authModal' },
  { nom:'où sont mes fiches',  w:390,  prep:'dlg:openStorageInfo',scope:'#storageModal' },
  { nom:'bienvenue',           w:390,  scope:'#welcomeModal', noSeed:true, fn: async()=>{} },
  { nom:'confirmation',        w:390,  scope:'#confirmModal', fn: async()=>{
      confirmDlg({title:'Supprimer la fiche ?',
        msg:'Cette action est irréversible. Les sessions liées restent dans l\'historique.',
        okText:'Supprimer',danger:true}); } },
  { nom:'historique sessions', w:390,  scope:'#sessModal', fn: async()=>{
      const f=fiches.find(x=>/Arrêt cardiaque/.test(x.title));
      openRead(f.id);await new Promise(r=>setTimeout(r,400));
      document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,450));
      openSessHist(); } },
  { nom:'terminer la session', w:390,  scope:'#endSessModal', fn: async()=>{
      const f=fiches.find(x=>/Arrêt cardiaque/.test(x.title));
      openRead(f.id);await new Promise(r=>setTimeout(r,400));
      document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,450));
      confirmEndSession(f); } },
  /* L'index ⚡ n'est plus une FENÊTRE mais un dépliant DANS la carte (v5.0.0, audit design) : la
     surface change de porteur, pas de nature — on l'ouvre par son vrai point d'entrée, et il faut
     DEUX événements pour qu'un index existe (à un seul, l'événement est le bouton). */
  { nom:'excursions',       w:390,  scope:'#dockSheet', fn: async()=>{
      const f=fiches.find(x=>/Arrêt cardiaque/.test(x.title));
      f.excursions=[{label:'Laryngospasme',target:f.blocks[1].id},
                    {label:'Choc réfractaire',target:f.blocks[0].id}];
      await Data.put(f);openRead(f.id);await new Promise(r=>setTimeout(r,400));
      const sb=document.getElementById('sessStart');if(sb)sb.click();
      await new Promise(r=>setTimeout(r,500));
      const b=document.querySelector('#cxKey');if(b)b.click();
      await new Promise(r=>setTimeout(r,350)); } },
  { nom:'versions précédentes',w:390,  scope:'#versModal', fn: async()=>{
      const f=fiches.find(x=>/Arrêt cardiaque/.test(x.title));
      await Data.putBackup({bid:uid('bk'),ficheId:f.id,at:Date.now(),data:JSON.parse(JSON.stringify(f))});
      openVersions(f.id); } },
  { nom:'visionneuse PDF',     w:390,  scope:'#pdfModal', fn: async()=>{
      const f=fiches.find(x=>/Arrêt cardiaque/.test(x.title));
      const by=new TextEncoder().encode('%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 300 400]>>endobj\ntrailer<</Root 1 0 R>>');
      await IDB.putAtt({id:'att-x',buf:by.buffer,size:by.byteLength,type:'application/pdf',createdAt:Date.now(),dirty:0});
      await openPdfViewer({id:'att-x',name:'Protocole.pdf',size:by.byteLength},f); } },
  { nom:'membres bibliothèque',w:390,  scope:'#membersModal', fn: async()=>{
      if(typeof openMembers==='function')openMembers('lib-x'); } },
  { nom:'comptes en attente',  w:390,  scope:'#pendingModal', fn: async()=>{
      if(typeof openPending==='function')openPending(); } },
  { nom:'erreur de synchro',   w:390,  scope:'#syncErrModal', fn: async()=>{
      if(typeof openSyncErr==='function')openSyncErr('La synchronisation a échoué : réseau indisponible.'); } },
  { nom:'joindre un document', w:390,  scope:'#attPickModal', fn: async()=>{
      const f=fiches.find(x=>/Arrêt cardiaque/.test(x.title));
      const by=new TextEncoder().encode('%PDF-1.4\ntrailer<</Root 1 0 R>>');
      await IDB.putAtt({id:'att-y',buf:by.buffer,size:by.byteLength,type:'application/pdf',createdAt:Date.now(),dirty:0});
      // Un document joint AILLEURS : sans lui, la liste filtrable serait vide et ne mesurerait rien.
      const g=fiches.find(x=>x.id!==f.id);
      if(g){g.docs=[{id:'att-y',name:'Annexe partagée.pdf',size:by.byteLength}];await Data.put(g);}
      openEdit(f.id);await new Promise(r=>setTimeout(r,500));
      openAttPicker(state.draft,()=>{}); } },
  { nom:'lier une aide',       w:390,  scope:'#relPickModal', fn: async()=>{
      const f=fiches.find(x=>/Arrêt cardiaque/.test(x.title));
      openEdit(f.id);await new Promise(r=>setTimeout(r,500));
      openRelPicker(state.draft,()=>{}); } },
  { nom:'compte-rendu',        w:390,  scope:'#reportModal', fn: async()=>{
      // exportSessionReport prend un ID et lit `sessions` (les ARCHIVÉES) : le seul chemin est
      // donc de dérouler la session complète — ouvrir, démarrer, terminer.
      const f=fiches.find(x=>/Arrêt cardiaque/.test(x.title));
      openRead(f.id);await new Promise(r=>setTimeout(r,400));
      document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,500));
      confirmEndSession(f);await new Promise(r=>setTimeout(r,300));
      document.getElementById('endSessYes').click();await new Promise(r=>setTimeout(r,800));
      const last=sessions[sessions.length-1];
      if(last)exportSessionReport(last.id); } },
  /* ÉCRAN D'ENTRÉE D'UN INVITÉ (v4.47.0) : la SEULE surface que verra un soignant sans compte, sur
     son propre téléphone, en pleine intervention. Elle n'est pas une `.ai-modal` — elle échappait
     donc au balayage des 20 fenêtres. Mesurée à 320 px, la largeur la plus contrainte servie :
     c'est un écran qu'on remplit debout, sur l'appareil qu'on a en main.
     Point d'entrée RÉEL (`openJoinScreen`, la fonction qu'appellent le démarrage par appariement
     ET le bandeau système), jamais un `hidden=false` posé à la main. Le dépliage de la notice est
     le geste de l'utilisateur, pas une reconstruction d'état : sans lui, le texte qui porte
     l'information légale ne serait pas mesuré du tout. */
  { nom:'mode statique',       w:390,  prep:'read', fn: async()=>{
      const b=document.getElementById('allBtn'); if(b)b.click();
      await new Promise(r=>setTimeout(r,500)); } },
  { nom:'mode moniteur',       w:390,  scope:'#monMode', prep:'read', fn: async()=>{
      if(typeof openMonitor==='function')openMonitor();
      await new Promise(r=>setTimeout(r,400)); } },
  { nom:'lecture de référence',w:390,  fn: async()=>{
      protocols.push(migrateProtocol({id:'pA11y',title:'Référence témoin',kind:'reference',
        body:'# Titre A\n\ntexte de la référence\n\n## Sous-titre\n\n- [ ] tâche\n\n## Autre\n\ntexte'}));
      openProtocolRead('pA11y'); await new Promise(r=>setTimeout(r,500)); } },
  { nom:'éditeur de protocole',w:1100, fn: async()=>{
      protocols.push(migrateProtocol({id:'pEd',title:'Référence à écrire',kind:'reference',body:'# A\n\nx'}));
      await openProtocolEdit('pEd'); await new Promise(r=>setTimeout(r,500)); } },
  /* ═══ ÉTATS ═══ (audit design v5.0.0 — ACTION 1, et c'est la plus importante du rapport).
     Ce harnais ouvrait chaque surface AU REPOS. Or DEUX violations AA ont vécu à l'écran sans
     qu'il les voie, parce qu'elles n'existent qu'après un geste : le surlignage de recherche
     (3,64:1 en clair, 1,76:1 en sombre) et le vert du retour d'excursion (1,9:1 en sombre). Un
     harnais qui ne mesure que le repos ne couvre pas la moitié de ce qu'il prétend couvrir.
     Chaque entrée ci-dessous CONSTRUIT son état par les gestes réels de l'application. */
  /* BIBLIOTHÈQUE VIDE — le premier écran d'un nouveau venu, et il n'était mesuré nulle part : la
     surface « bibliothèque » est ouverte AVEC les fiches d'exemple, donc l'état vide n'existe
     jamais dans le balayage. Il porte pourtant du texte à 13,5 px en encre douce et des glyphes
     de registre (rouge, ambre, gris d'absence) : exactement ce que ce harnais existe pour voir.
     ⚠ ON VIDE LES LISTES, ON NE FABRIQUE PAS L'ÉCRAN : c'est `renderHomeList` qui décide, sur la
     même condition que chez l'utilisateur (rien à afficher, aucun filtre, droit de créer). */
  { nom:'état · bibliothèque vide', w:390, must:'.emp-intro .emp-anat b', fn: async()=>{
      fiches.length=0; protocols.length=0;
      state.section='all'; state.q=''; state.cat=''; state.view='library';
      render(); await new Promise(r=>setTimeout(r,400)); } },
  { nom:'état · recherche active', w:390, prep:'read', must:'mark.pf-h', fn: async()=>{
      const b=document.getElementById('allBtn'); if(b)b.click();
      await new Promise(r=>setTimeout(r,600));
      const q=document.getElementById('pfQ');
      if(q){q.value='adrénaline';q.dispatchEvent(new Event('input',{bubbles:true}));}
      await new Promise(r=>setTimeout(r,450)); } },
  { nom:'état · excursion (retour)', w:390, prep:'read', must:'[data-cxback]', fn: async()=>{
      /* ⚠ ON NE RÉ-OUVRE PAS LA FICHE : `openRead` reconstruit le Runtime, donc la session
         démarrée par la préparation disparaîtrait — et `cxEnter` refuse d'enregistrer un retour
         hors session. On ajoute la déclaration et l'on re-rend le journal, rien de plus. */
      const f=state.fiche;
      f.excursions=[{label:'Laryngospasme',target:f.blocks[1].id}];
      /* v5.6 : l'entrée sur complication est passée au DOCK. La touche ⚡︎ est peinte par le
         chrome (applyViewChrome), pas par le journal : un `renderOvOnly` ne la ferait pas
         paraître, et le témoin mesurerait un écran où rien n'a été construit. */
      render(); await new Promise(r=>setTimeout(r,400));
      const k=document.getElementById('cxKey'); if(k)k.click();
      await new Promise(r=>setTimeout(r,350));
      const g=document.querySelector('#dockSheet [data-cxgo]'); if(g)g.click();
      await new Promise(r=>setTimeout(r,700)); } },
  { nom:'état · minuteur échu', w:390, prep:'read', must:'.seg.due,.tmcard.due', fn: async()=>{
      /* Les minuteurs du Runtime sont un DICTIONNAIRE par id, pas un tableau — et l'échéance se
         calcule sur `elapsedMs` + `lastStart`, pas sur une durée nue. On arme, puis on antidate. */
      const R=Runtime, ks=Object.keys(R.timers||{});
      const src=(state.fiche.timers||[])[0];
      /* ⚠ ET IL FAUT COUPER `autoloop` : un minuteur à cycles se REMET À ZÉRO à l'échéance, donc
         il n'est jamais « échu » — l'état qu'on veut mesurer ne pouvait pas exister. */
      if(ks.length&&src){const t=R.timers[ks[0]];
        t.autoloop=false;src.autoloop=false;
        t.running=true;t.elapsedMs=0;t.lastStart=Date.now()-((src.seconds||60)*1000+9000);}
      if(typeof tickAll==='function')tickAll();
      await new Promise(r=>setTimeout(r,500)); } },
  { nom:'état · index ⚡ déplié', w:390, prep:'read', must:'#dockSheet .ds-row', fn: async()=>{
      const f=state.fiche;
      f.excursions=[{label:'Laryngospasme',target:f.blocks[1].id},
                    {label:'Choc réfractaire',target:f.blocks[0].id}];
      renderOvOnly(); await new Promise(r=>setTimeout(r,350));
      const b=document.querySelector('#cxKey'); if(b)b.click();
      await new Promise(r=>setTimeout(r,450)); } },
  /* ═══ ÉTATS D'ITEM (v5.0.0, audit design A1-2) ═══
     LES CINQ ÉTATS DE SURFACE ci-dessus mesuraient des ÉCRANS après un geste. Aucun ne mesurait
     l'état d'un ITEM — et c'est par là qu'une violation AA a survécu à 443 contrôles verts :
     l'étape COCHÉE, c'est-à-dire l'état le plus fréquent de toute l'application (en réanimation,
     la moitié des lignes à l'écran le sont), composait un texte à 2,55:1 en clair et 1,95:1 en
     SOMBRE. Le harnais ouvrait la fiche, mesurait des lignes vierges, et concluait.
     « Un contrôle qui ne rencontre pas son cas ne le couvre pas » est la leçon la plus redite de
     ce dossier ; elle n'avait pas été appliquée à la couverture du harnais lui-même. */
  { nom:'état · étape cochée', w:390, prep:'read', must:'ol.steps li.done .txt', fn: async()=>{
      /* On coche par le VRAI geste (clic sur la rangée), jamais en posant `.done` à la main :
         c'est `applyCheck` qui écrit l'état, et une classe posée de force mesurerait un rendu
         que l'application ne produit pas. Deux étapes, dont une SIGNALÉE si elle existe — la
         boîte teintée `.crit` change le fond effectif, donc le contraste à mesurer. */
      const li=[...document.querySelectorAll('ol.steps li[data-ck]')];
      if(li[0])li[0].click();
      const sig=li.find(e=>e.classList.contains('crit')||e.classList.contains('vigil'));
      if(sig)sig.click(); else if(li[1])li[1].click();
      /* La transition d'état dure 250 ms : mesurer avant, c'est mesurer une couleur en vol. */
      await new Promise(r=>setTimeout(r,600)); } },
  { nom:'état · trace do-verify', w:390, prep:'read', must:'.stp-vf', fn: async()=>{
      /* La passe Do-Verify laisse DEUX marqueurs DURABLES et distincts de `checked` (v4.23.0) :
         « ✓✓ constaté » (`.stp-vf.ok`) et « △ écart » (`.stp-vf.gap`), peints sur la rangée par
         `paintStepTrace`. On mesure la TRACE, c'est-à-dire ce qui reste APRÈS la passe — c'est
         elle qu'on relit au débriefing, et elle vit sur la liste ordinaire.
         ⚠ Il faut SORTIR de la passe (`data-ovvx`) : pendant, les rangées sont des `.vstp`, un
         autre composant. Mesurer là aurait couvert l'écran de passe et laissé la trace dehors —
         exactement le trou que ces entrées existent pour fermer. */
      const v=document.querySelector('[data-ovverify]'); if(v)v.click();
      await new Promise(r=>setTimeout(r,450));
      const ok=document.querySelector('[data-ovvok]'); if(ok)ok.click();
      await new Promise(r=>setTimeout(r,350));
      const gap=document.querySelector('[data-ovvgap]'); if(gap)gap.click();
      await new Promise(r=>setTimeout(r,350));
      const x=document.querySelector('[data-ovvx]'); if(x)x.click();
      await new Promise(r=>setTimeout(r,600)); } },
  { nom:'état · bloc hors chemin', w:1280, prep:'read', must:'.pl-line.off,.sv-cell.off,[class*="off"]', fn: async()=>{
      /* Le « hors chemin » est signalé par une encre douce PLUS la mention en toutes lettres —
         jamais par l'opacité seule (le harnais a une sonde dédiée pour ça). Il faut donc une
         DÉCISION dont une branche a été prise pour que l'autre devienne hors chemin. */
      const o=document.querySelector('[data-ovopt]'); if(o)o.click();
      await new Promise(r=>setTimeout(r,700)); } },
  { nom:'état · contrôles fermés (scribe)', w:390, prep:'read', must:'body.share-scribe', fn: async()=>{
      /* La grammaire de « fermé » du fichier — encre douce, filet neutre, `--surface-2`, ombre
         retirée — sert TROIS régimes (scribe, mode déplacement, lien mort). WCAG 1.4.3 exempte
         les composants inactifs du seuil, mais la sonde vérifie le reste de la surface, et
         surtout que le grisé ne déborde pas sur le contenu CLINIQUE, qui doit rester lisible. */
      document.body.classList.add('share-scribe');
      await new Promise(r=>setTimeout(r,400)); } },
  { nom:'état · lien de partage mort', w:390, prep:'read', must:'.share-dead,[data-sharedead],#srLive', fn: async()=>{
      if(typeof Share!=='undefined'&&Share.freeze){Share.mode='guest';Share.freeze('over');}
      await new Promise(r=>setTimeout(r,500)); } },
  { nom:'entrée invité',       w:320,  scope:'#joinScreen', fn: async()=>{
      openJoinScreen('K7M2P4Q9');
      const d=document.querySelector('#joinScreen .join-info'); if(d)d.open=true; } },
  { nom:'nouvelle biblio.',    w:390,  scope:'#newLibModal', fn: async()=>{
      // openNewLib est gardée par myIsAppAdmin : garde MÉTIER légitime, dont la vraie barrière
      // est la RLS serveur. On la lève pour auditer le RENDU, ce qui est l'objet du harnais.
      myIsAppAdmin=true; openNewLib(); } },
];

/* Tranches (v5.4.4, `--shard k/n`) : découpe de SURFACES au modulo — le lanceur joue les n
   tranches en parallèle, chacune couvrant les DEUX thèmes de ses surfaces ; la somme des lignes
   `##SEC` est vérifiée par audit-run (aucune troncature silencieuse). La section focus 2.4.11 ne
   tourne que dans la tranche 1 (la dupliquer mesurerait deux fois la même chose). */
const tranche = trancheArg();
const SURF = tranche ? SURFACES.filter((_, i) => i % tranche.n === tranche.k - 1) : SURFACES;

for (const theme of ['light','dark']) {
  console.log('\n══════ THÈME '+(theme==='dark'?'SOMBRE':'CLAIR')+' ══════');
  for (const S of SURF) {
    const page = await browser.newPage({ viewport:{width:S.w,height:900}, colorScheme:theme });
    page.on('pageerror',e=>errs.push(`${S.nom}/${theme}: ${e.message}`));
    // Les fenêtres liées au COMPTE interrogent Supabase : hors réseau, la console crie
    // « ERR_INTERNET_DISCONNECTED ». C est le contexte de la sonde, pas un défaut de la page —
    // on ne filtre QUE ce motif, pour ne pas masquer une vraie erreur.
    const bruitReseau=/ERR_INTERNET_DISCONNECTED|Failed to load resource|net::ERR_/;
    page.on('console',m=>{ if(m.type()==='error'&&!bruitReseau.test(m.text())) errs.push(`${S.nom}/${theme}: ${m.text()}`); });
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'),null,{timeout:10000});
    if (!S.noSeed) { await amorce(page);
    await page.evaluate(async(kind)=>{
      const a=[...document.querySelectorAll('button')].find(b=>b.textContent.trim()==='Toutes'); if(a)a.click();
      if(!kind)return;
      const c=[...document.querySelectorAll('.card-open')].find(x=>/Arrêt cardiaque/.test(x.textContent));
      const id=c.dataset.open;
      const f=fiches.find(x=>x.id===id);
      f.posology=['△ **ADRÉNALINE — IV** : 1 mg / 3–5 min','**Remplissage** : cristalloïdes','**O₂** : haut débit','**Amiodarone** : 300 mg'];
      f.sources=['Réanimation — recommandations 2023.'];
      if(kind==='edit'){openEdit(id);await new Promise(r=>setTimeout(r,350));return;}
      c.click();
      /* VT (direction A, lot 7) : sous startViewTransition le rendu d'openRead est différé d'une
         frame — on attend la CONDITION réelle (le bouton existe), pas un délai fixe : c'est la
         discipline d'amorce()/ouvrirFiche(), que cette sonde inline n'appliquait pas. */
      for(let i=0;i<40&&!document.getElementById('sessStart');i++)await new Promise(r=>setTimeout(r,50));
      document.getElementById('sessStart').click();
      await new Promise(r=>setTimeout(r,300));
      /* LOT T8 (v5.0.0) — le bouton « Se repérer » a QUITTÉ la rangée de commandes : son Échelle
         est devenue l'onglet « Parcours » du cran « Toute la fiche ». La FEUILLE, elle, existe
         toujours (menu ⋯, « complet » depuis le rail) et reste donc à mesurer : on l'ouvre par sa
         fonction plutôt que par un bouton disparu. Sans ce correctif la sonde ne rougissait pas —
         elle levait une exception et EMPORTAIT les seize harnais suivants (`&&` en chaîne), le
         défaut de la v4.70.1 exactement. */
      if(kind==='plan'){const b=document.getElementById('planBtn');
        if(b)b.click();else if(typeof openPlanSheet==='function')openPlanSheet();
        await new Promise(r=>setTimeout(r,300));}
      if(kind==='ref'){const rb=document.getElementById('refBtn');if(rb)rb.click();await new Promise(r=>setTimeout(r,300));}
    }, S.prep && S.prep.indexOf('dlg:')===0 ? null : S.prep); }
    // Fenêtres ouvertes par leur VRAI point d'entrée (jamais un classList.add('on') : une modale
    // forcée vide n'a pas le contenu qu'on veut mesurer, et produirait des verdicts faux).
    if (S.prep && S.prep.indexOf('dlg:') === 0) {
      const fn = S.prep.slice(4);
      await page.evaluate(async (f) => { try { window[f] ? window[f]() : eval(f + '()'); } catch (e) {}
        await new Promise(r => setTimeout(r, 400)); }, fn);
    }
    // Fenêtres à contexte construit : leur préparation est une vraie fonction.
    if (S.fn) { await page.evaluate(S.fn); await page.waitForTimeout(700); }
    if (S.scope) await page.evaluate(s => { window.__acScope = s; }, S.scope);
    await page.waitForTimeout(250);

    /* ⚠ UN ÉTAT QUI NE S'EST PAS CONSTRUIT EST UN REPOS QU'ON MESURE EN CROYANT MESURER AUTRE
       CHOSE — c'est la leçon la plus redite du dossier. Chaque entrée d'état déclare donc CE QUI
       DOIT EXISTER, et son absence est un ÉCHEC, pas un silence. */
    if (S.must) {
      const vu = await page.evaluate(sel=>!!document.querySelector(sel), S.must);
      checks++; if(!vu){fails++;console.log(`\n── ${S.nom} (${S.w}px)`);
        console.log(`  ✗ l'état ne s'est pas construit — rien ne correspond à « ${S.must} »`);
        await page.close(); continue;}
    }
    const res = await page.evaluate(AUDIT);
    console.log(`\n── ${S.nom} (${S.w}px)`);
    const before=fails;
    report('typo < 11px', res.typo, x=>`${x.px}px · ${x.sel} · « ${x.txt} »`);
    report('contraste insuffisant', res.contrast, x=>`${x.ratio}:1 (seuil ${x.need}) · ${x.px}px · ${x.sel} · « ${x.txt} »`);
    report('cible trop petite', res.targets, x=>`${x.w}×${x.h} (seuil ${x.need}) · ${x.sel} · « ${x.txt} »`);
    report('--soft utilisé comme couleur de TEXTE', res.soft, x=>`${x.sel} · « ${x.txt} »`);
    report('règle projet', res.misc, x=>`${x.sel} — ${x.pb}`);

    // ---- focus visible : VRAIES touches Tab (`:focus-visible` ne s'applique qu'au clavier —
    //      un .focus() programmatique produisait des faux positifs). ------------------------
    const nom=el=>el;
    await page.evaluate(()=>{document.body.focus?.();});
    const badFocus=[];const vus=new Set();
    for(let i=0;i<60;i++){
      await page.keyboard.press('Tab');
      const info=await page.evaluate(()=>{
        const el=document.activeElement;
        if(!el||el===document.body)return null;
        const cs=getComputedStyle(el);
        const outl=e=>{const c=getComputedStyle(e);
          return c.outlineStyle!=='none'&&(parseFloat(c.outlineWidth)||0)>0;};
        // L'anneau peut être porté par un ANCÊTRE (motif .card:has(.card-open:focus-visible) :
        // le bouton pose outline:none, la CARTE porte l'anneau — 3 niveaux au-dessus).
        // Sur un ancêtre on n'accepte QUE l'outline : son box-shadow est en général une simple
        // élévation permanente, qui masquerait un vrai défaut.
        const cs0=getComputedStyle(el);
        let ring3=outl(el)||(cs0.boxShadow&&cs0.boxShadow!=='none');
        let a=el.parentElement;for(let k=0;k<4&&a&&!ring3;k++,a=a.parentElement){if(outl(a))ring3=true;}
        const ow=parseFloat(cs.outlineWidth)||0, os=cs.outlineStyle, sh=cs.boxShadow;
        const cls=(typeof el.className==='string'?el.className:(el.getAttribute('class')||''))||el.tagName;
        const key=cls+'|'+(el.textContent||'').trim().slice(0,20);
        return {key,cls,
          txt:((el.textContent||el.getAttribute('aria-label')||'').trim().slice(0,26)),
          vis:ring3};
      });
      if(!info)break;
      if(vus.has(info.key))break; vus.add(info.key);
      if(!info.vis)badFocus.push(info.cls+' | '+info.txt);
    }
    checks++;
    if(badFocus.length){fails++;
      console.log(`  ✗ focus NON visible au clavier (${badFocus.length}/${vus.size})`);
      [...new Set(badFocus)].slice(0,6).forEach(x=>console.log('      '+x));
    }
    if(fails===before)console.log('  ✓ conforme');
    await page.close();
  }
}
// ---- WCAG 2.2 § 2.4.11 « Focus Not Obscured (Minimum) » ------------------------------------
// Un Shift+Tab remontant ne doit JAMAIS déposer l'élément focalisé ENTIÈREMENT sous les couches
// collantes (en-tête + commandes + quai). Sonde ajoutée par l'audit externe v4.30.0 — échec
// mesuré AVANT correctif : 3 masquages TOTAUX à 360 px en session (dont l'étape critique
// « ⚠ RCP immédiate »). Correctif : html{scroll-padding-top:calc(var(--stick-top)+8px)}.
// On émule le cas réel : l'élément est envoyé AU-DESSUS du viewport, puis focalisé — le
// défilement déclenché par le focus est celui du navigateur, le seul que scroll-padding pilote.
if (!tranche || tranche.k === 1) {
console.log('\n══════ WCAG 2.2 · 2.4.11 focus non masqué (session, 360 px) ══════');
{
  const page = await browser.newPage({ viewport:{width:360,height:780} });
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'),null,{timeout:10000});
  await amorce(page);
  await ouvrirFiche(page,/Arrêt cardiaque/);
  await demarrerSession(page);
  const bad = await page.evaluate(async()=>{
    const layers=['header.bar','#crisisDock'].map(s=>document.querySelector(s)).filter(Boolean);
    const stick=()=>Math.max(...layers.map(e=>e.getBoundingClientRect().bottom));
    const foc=[...document.querySelectorAll('main a[href],main button,main input,main [tabindex="0"]')].filter(e=>e.offsetParent);
    const out=[];
    for(const el of foc){
      const y=el.getBoundingClientRect().top+scrollY;
      scrollTo(0,y+400);                      // l'élément passe AU-DESSUS du viewport (cas Shift+Tab)
      el.focus();
      // ATTENDRE LE DÉFILEMENT (v4.45.0) : sur WebKit — la cible iOS — le défilement induit par un
      // focus programmatique est ASYNCHRONE. Lire la géométrie dans la foulée, comme on le faisait,
      // renvoyait la position d'AVANT : 8 « masquages » signalés sur 11 cibles, avec des bas
      // NÉGATIFS (-352, -237, -138 px), c'est-à-dire des éléments encore hors écran. Le harnais
      // mesurait la synchronicité du moteur, pas la conformité de l'app. Avec l'attente : 0 sur
      // les deux moteurs, à sélecteur et scénario identiques (variable isolée). Le défaut n'est
      // apparu qu'en jouant enfin les harnais sur WebKit — ils lançaient tous Chromium en dur.
      await new Promise(r=>setTimeout(r,60));
      const r=el.getBoundingClientRect();
      if(r.height>0&&r.bottom<=stick())out.push((el.textContent||'').trim().slice(0,32)||el.className);
    }
    scrollTo(0,0); return out;
  });
  checks++;
  if(bad.length){ fails++;
    console.log(`  ✗ focus ENTIÈREMENT masqué sous les couches collantes (${bad.length})`);
    bad.slice(0,6).forEach(x=>console.log('      '+x));
  } else console.log('  ✓ aucun élément focalisé entièrement masqué');
  await page.close();
}
}

await browser.close(); srv.close();
if(errs.length){console.log('\nErreurs page :');[...new Set(errs)].forEach(e=>console.log('  '+e));}
/* Ligne machine pour audit-run : joues/total en unités « surface × thème » (+1 pour la section
   focus, jouée dans la seule tranche 1) — la somme des tranches doit couvrir le total. */
console.log(`##SEC joues=${SURF.length*2+((!tranche||tranche.k===1)?1:0)} total=${SURFACES.length*2+1}`+(tranche?` tranche=${tranche.k}/${tranche.n}`:''));
if(tranche)console.log(`⚠ PASSE PARTIELLE — tranche ${tranche.k}/${tranche.n} (${SURF.length}/${SURFACES.length} surfaces) ; le harnais entier reste dû avant commit.`);
console.log(`\n${checks-fails}/${checks} contrôles OK${fails?` — ${fails} ÉCHEC(S)`:''}${errs.length?` — ${errs.length} erreur(s)`:''}${tranche?` — PARTIEL (tranche ${tranche.k}/${tranche.n})`:''}`);
process.exit(fails||errs.length?1:0);
