/* LOT 7 — volet DOCTRINE : ECAM / QRH / FAA AC 120-71B, mesuré sur l'app réelle.
   Chaque contrôle traduit une règle de sûreté en invariant observable. */
import { serveApp, moteur, NOM_MOTEUR, ROOT } from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();
let ok=0,ko=0;
const t=(nom,cond,det)=>{if(cond){ok++;console.log('  ✓ '+nom);}else{ko++;console.log('  ✗ '+nom+(det?'\n      '+det:''));}};

async function session(w){
  const page=await br.newPage({viewport:{width:w,height:820}});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(async()=>{
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();
    await new Promise(r=>setTimeout(r,120));
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();
    await new Promise(r=>setTimeout(r,350));
    const c=[...document.querySelectorAll('.card-open')].find(x=>/Arrêt cardiaque/.test(x.textContent));
    c.click();await new Promise(r=>setTimeout(r,150));
    document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,350));});
  return page;
}

// ══ ECAM — constance positionnelle de la zone d'état ════════════════════════
console.log('\n══ ECAM · constance positionnelle du quai ══');
{
  const page=await session(1280);
  const snap=()=>page.evaluate(()=>[...document.querySelectorAll('#crisisDock .dock-in>*')]
    .filter(e=>!e.hidden&&getComputedStyle(e).display!=='none')
    .map(e=>e.id||e.className));
  const geo=id=>page.evaluate(i=>{const e=document.getElementById(i);
    return e&&!e.hidden?Math.round(e.getBoundingClientRect().left):null;},id);
  const a=await snap(), pa=await geo('planBtn'), ra=await geo('refBtn');
  // faire varier l'état : ajouter des minuteurs (la partie VARIABLE du quai)
  await page.evaluate(async()=>{
    const add=[...document.querySelectorAll('.rt-add,.add-line')];
    for(const b of add.slice(0,3)){b.click();await new Promise(r=>setTimeout(r,120));}});
  await page.waitForTimeout(300);
  const b=await snap(), pb=await geo('planBtn'), rb=await geo('refBtn');
  t('ordre du quai identique quel que soit l\'état', JSON.stringify(a)===JSON.stringify(b), a+'\n      → '+b);
  t('bouton Plan immobile (px)', pa!==null&&pa===pb, `${pa} → ${pb}`);
  t('bouton Réf. immobile (px)', ra===rb, `${ra} → ${rb}`);
  // Débordement JAMAIS silencieux : on fait ÉCHOIR 3 minuteurs d'intervalle, le quai n'en
  // montre que 2 en large — le 3ᵉ doit être annoncé par un « +n », jamais escamoté.
  const ov=await page.evaluate(async()=>{
    const ids=Object.keys(Runtime.timers);
    while(ids.length<3){const b=document.querySelector('.rt-add,.add-line');if(!b)break;b.click();
      await new Promise(r=>setTimeout(r,200));ids.splice(0,ids.length,...Object.keys(Runtime.timers));}
    ids.slice(0,3).forEach(k=>{const t=Runtime.timers[k];
      t.type='interval';t.seconds=t.seconds||120;t.running=false;t.elapsedMs=t.seconds*1000+5000;});
    updateRtStrip(Date.now());await new Promise(r=>setTimeout(r,120));
    const s=document.getElementById('cbTimers');
    const due=Object.values(Runtime.timers).filter(t=>t.type==='interval'&&!t.running
      &&t.elapsedMs>=t.seconds*1000).length;
    const segs=s?s.querySelectorAll('.seg:not(.glb)').length:0;
    return {due,segs,plus:!!s&&/\+\s?\d/.test(s.textContent),txt:s?s.textContent:null};});
  t('débordement d\'alarmes annoncé (« +n »)', ov.due<=ov.segs||ov.plus, JSON.stringify(ov));
  await page.close();
}

// ══ AC 120-71B — les memory items ne sont JAMAIS derrière un clic ═══════════
console.log('\n══ AC 120-71B · memory items en accès direct ══');
{
  const page=await session(390);
  const r=await page.evaluate(()=>{
    const strip=document.querySelector('.forget-strip,#forgetStrip,.ov-forget');
    const inMain=!!strip&&!!strip.closest('#main');
    const inSheet=!!strip&&!!strip.closest('#refModal,#planModal');
    return {present:!!strip,inMain,inSheet,
      // rien de vital ne doit exister UNIQUEMENT dans une feuille repliable
      dupRef:!!document.querySelector('#refModal .forget-strip')};});
  t('« Ne pas oublier » présent dans le FLUX principal', r.present&&r.inMain&&!r.inSheet, JSON.stringify(r));
  t('non recopié dans la feuille Consulter (source unique)', !r.dupRef);
  // QRH : la procédure abrégée reste sous les yeux, la référence est appelée
  const refInert=await page.evaluate(async()=>{
    const rb=document.getElementById('refBtn');if(!rb)return 'pas de bouton';
    rb.click();await new Promise(r=>setTimeout(r,350));
    const boxes=document.querySelectorAll('#refModal input[type=checkbox],#refModal .stp');
    const starts=document.querySelectorAll('#refModal [data-navgo],#refModal #sessStart');
    return {boxes:boxes.length,starts:starts.length};});
  t('feuille Consulter INERTE (aucune coche, aucun démarrage)',
    typeof refInert==='object'&&refInert.boxes===0&&refInert.starts===0, JSON.stringify(refInert));
  await page.close();
}

// ══ ECAM — naviguer ≠ agir ; le plan ne coche pas, ne démarre pas ══════════
console.log('\n══ ECAM · naviguer ≠ agir ══');
{
  const page=await br.newPage({viewport:{width:1280,height:820}});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(async()=>{
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();
    await new Promise(r=>setTimeout(r,120));
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();
    await new Promise(r=>setTimeout(r,350));
    [...document.querySelectorAll('.card-open')].find(x=>/Arrêt cardiaque/.test(x.textContent)).click();
    await new Promise(r=>setTimeout(r,250));});
  const before=await page.evaluate(()=>({live:Object.keys(liveSessions||{}).length,
    checked:JSON.stringify(Runtime.checked||{})}));
  // Le nœud du plan est une LIGNE de l'Échelle (.pl-line[data-plln]) — l'ancien sélecteur .pl-nd
  // visait l'organigramme « Détails » supprimé en v4.25.0 : il ne matchait plus rien, si bien que
  // ces deux contrôles passaient SANS avoir rien cliqué (faux positif permanent). D'où le
  // `clique` remonté et vérifié : un contrôle qui ne peut pas échouer ne prouve rien.
  const after=await page.evaluate(async()=>{
    const nd=document.querySelector('.pl-line[data-plln]');
    if(nd)nd.click();
    await new Promise(r=>setTimeout(r,300));
    return {clique:!!nd,live:Object.keys(liveSessions||{}).length,checked:JSON.stringify(Runtime.checked||{})};});
  t('un nœud du plan est bien présent et cliqué (le contrôle n\'est pas vide)', after.clique===true);
  t('taper un nœud du plan ne DÉMARRE pas de session', before.live===after.live, `${before.live} → ${after.live}`);
  t('taper un nœud du plan ne COCHE rien', before.checked===after.checked);
  await page.close();
}

// ══ ECAM — aucune notification flottante pendant un soin ═══════════════════
console.log('\n══ ECAM · pas d\'alerte flottante en session ══');
{
  const page=await session(390);
  const r=await page.evaluate(async()=>{
    const vis=()=>[...document.querySelectorAll('.toast')].filter(e=>getComputedStyle(e).display!=='none'
      &&getComputedStyle(e).visibility!=='hidden'&&e.getBoundingClientRect().height>0).length;
    const avant=vis();                       // un toast antérieur au démarrage peut encore vivre
    toast('essai');await new Promise(r=>setTimeout(r,250));
    const sb=document.getElementById('sysBanner');
    return {crise:document.body.classList.contains('crisis-live'),nouveaux:vis()-avant,
      banner:sb?(!sb.hidden&&sb.getBoundingClientRect().height>0):false};});
  t('snackbar mis en attente en session', r.crise&&r.nouveaux===0, JSON.stringify(r));
  t('bandeau système absent hors accueil', r.banner===false);
  await page.close();
}

// ══ ECAM — rangée de COMMANDES sans rognage (v4.30.0, audit externe) ════════
// Mesuré AVANT correctif : #crisisCtrl exigeait 386 px — « Cons. » rogné de 11 px à 375
// (iPhone SE/mini) et 26 px à 360 (Android standard), sans défilement horizontal : pixels
// INACCESSIBLES. Un débordement silencieux dans la zone de crise — l'écart que ce harnais
// existe pour attraper (il mesurait le quai, pas la rangée de commandes juste au-dessus).
// 320 px AJOUTÉ en v4.43.0 (décision utilisateur « oui pour 320 px ») : c'est le plancher de
// WCAG 1.4.10 « Reflow », et la rangée y exigeait 348 px pour 320 — 28 px rognés en silence.
// On mesure aussi le ROGNAGE INTERNE (bord droit du dernier bouton contre la boîte cliente de
// `.dock-in`) : un bouton peut tenir dans le viewport tout en étant coupé par son conteneur,
// et c'est exactement le cas qui se produisait.
console.log('\n══ ECAM · rangée de commandes sans rognage (320/360/375/390) ══');
{
  const page=await session(360);
  for(const w of [320,360,375,390]){
    await page.setViewportSize({width:w,height:820});
    await page.waitForTimeout(220);
    const r=await page.evaluate(()=>{
      const btns=[...document.querySelectorAll('#crisisCtrl button')].filter(b=>b.offsetParent);
      const right=Math.max(...btns.map(b=>b.getBoundingClientRect().right));
      const din=document.querySelector('#crisisCtrl .dock-in');
      const db=din.getBoundingClientRect(),ds=getComputedStyle(din);
      const bordInterne=db.right-parseFloat(ds.paddingRight);
      return {right:+right.toFixed(1),vw:innerWidth,doc:document.documentElement.scrollWidth,
        bordInterne:+bordInterne.toFixed(1),deborde:+(din.scrollWidth-din.clientWidth).toFixed(1)};});
    t(`aucun bouton de commande hors écran à ${w} px`, r.right<=r.vw&&r.doc<=r.vw,
      `bord droit ${r.right} px / viewport ${r.vw} px`);
    t(`aucun rognage par le conteneur à ${w} px`, r.right<=r.bordInterne+0.5&&r.deborde<=0.5,
      `dernier bouton à ${r.right} px, bord interne ${r.bordInterne} px, débordement ${r.deborde} px`);
  }
  await page.close();
}

// La MÊME règle vaut hors crise : un débordement silencieux reste un débordement. L'ÉDITEUR
// sortait « ⋯ » de 6,2 px à 320 px (bouton VISIBLE, donc pixels inatteignables) — le commentaire
// du CSS visait 360 et le tenait, personne n'avait mesuré en dessous.
console.log('\n══ ECAM · barre d\'éditeur sans rognage (320/360) ══');
{
  const page=await br.newPage({viewport:{width:320,height:844}});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(async()=>{
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();
    await new Promise(r=>setTimeout(r,120));
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();
    await new Promise(r=>setTimeout(r,400));
    const f=fiches.find(x=>/Arrêt cardiaque/.test(x.title))||fiches[0];
    await openEdit(f.id);await new Promise(r=>setTimeout(r,600));});
  for(const w of [320,360]){
    await page.setViewportSize({width:w,height:844});
    await page.waitForTimeout(250);
    const r=await page.evaluate(()=>{
      // Seulement ce qui est RÉELLEMENT peint : `hidden` et `display:none` ne débordent de rien.
      const vis=[...document.querySelectorAll('header.bar button')]
        .filter(e=>!e.hidden&&getComputedStyle(e).display!=='none'&&e.getBoundingClientRect().width>0);
      const pire=vis.reduce((a,e)=>{const b=e.getBoundingClientRect();return b.right>a.r?{r:b.right,id:e.id||e.className}:a;},{r:0,id:'—'});
      return {r:+pire.r.toFixed(1),id:pire.id,vw:innerWidth,n:vis.length};});
    t(`aucun bouton d'éditeur hors écran à ${w} px`, r.r<=r.vw+0.5,
      `${r.id} finit à ${r.r} px pour un écran de ${r.vw} px (${r.n} boutons visibles)`);
  }
  await page.close();
}

// ══ WCAG 2.3.3 / projet — mouvement inhibé sous prefers-reduced-motion ═════
console.log('\n══ WCAG · prefers-reduced-motion ══');
{
  const page=await br.newPage({viewport:{width:1280,height:820},reducedMotion:'reduce'});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(async()=>{
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();
    await new Promise(r=>setTimeout(r,120));
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();
    await new Promise(r=>setTimeout(r,350));
    [...document.querySelectorAll('.card-open')].find(x=>/Arrêt cardiaque/.test(x.textContent)).click();
    await new Promise(r=>setTimeout(r,250));
    document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,300));});
  const anim=await page.evaluate(()=>{
    const bad=[];
    document.querySelectorAll('#crisisDock *,.ov-wrap *,.read-side *,.pl-chip,.seg .seg-pill').forEach(e=>{
      const c=getComputedStyle(e);
      const d=parseFloat(c.animationDuration)||0, td=parseFloat(c.transitionDuration)||0;
      if(c.animationName!=='none'&&d>0.05)bad.push('anim '+(e.className||e.tagName)+' '+c.animationName);
      if(td>0.05&&/transform|opacity|all/.test(c.transitionProperty))bad.push('trans '+(e.className||e.tagName));});
    return [...new Set(bad)];});
  t('aucun mouvement autonome sous reduced-motion', anim.length===0, anim.slice(0,4).join('\n      '));
  await page.close();
}

// ══ QRH / Degani & Wiener — l'intitulé d'une décision ne quitte pas l'écran ═
// En mode STATIQUE sur petit écran les branches sont EMPILÉES : sans épinglage, la bande-question
// sortait de l'écran pendant qu'on lisait encore ses étapes (mesuré : 844 px de contenu lus sans
// elle sur une décision imbriquée à 360×640). Perdre sa place est un mode de défaillance premier ;
// au-delà de 640 px les branches sont côte à côte et le défaut n'existe pas — d'où les deux volets.
console.log('\n══ QRH · intitulé de décision toujours visible (statique empilé) ══');
{
  const st=n=>Array.from({length:n},(_,i)=>`Étape ${i+1} du protocole, libellé réaliste`);
  const FICHE={id:'aud-sb',title:'Audit — décision imbriquée',start:'a',blocks:[
    {id:'a',type:'steps',title:'Début',steps:st(3),next:'d1'},
    {id:'d1',type:'decision',title:'Analyse du rythme',question:'Le rythme est-il choquable (FV / TV sans pouls) ?',
      options:[{label:'Choquable',target:'b1'},{label:'Non choquable',target:'b9'}]},
    {id:'b1',type:'steps',title:'Choc',steps:st(4),next:'d2'},
    {id:'d2',type:'decision',title:'Réévaluation',question:'Reprise d\'activité circulatoire spontanée ?',
      options:[{label:'Non',target:'b6'},{label:'Oui',target:'b8'}]},
    {id:'b6',type:'steps',title:'Poursuite',steps:st(6),next:'fin'},
    {id:'b8',type:'steps',title:'Post-arrêt',steps:st(3),next:'fin'},
    {id:'b9',type:'steps',title:'Sans choc',steps:st(4),next:'fin'},
    {id:'fin',type:'steps',title:'Surveillance',steps:st(2),next:null}],
    timers:[],counters:[],confirmation:[],verify:[],notForget:[],differentials:[],references:[],images:[]};
  const openStatic=async(w,h)=>{
    const page=await br.newPage({viewport:{width:w,height:h}});
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'));
    await page.evaluate(async f=>{
      const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();
      await new Promise(r=>setTimeout(r,120));
      const nf=migrate(JSON.parse(JSON.stringify(f)));await Data.put(nf);fiches.push(nf);
      state.view='read';state.fiche=nf;state.readMode='static';render();
      await new Promise(r=>setTimeout(r,650));},FICHE);
    return page;};
  {
    const page=await openStatic(360,640);
    const r=await page.evaluate(async()=>{
      const bands=[...document.querySelectorAll('.sv-decwrap>.sv-band')];
      const inner=[...document.querySelectorAll('.sv-decwrap .sv-cell')];
      const H=innerHeight;const out={sans:0,positions:0,overlap:0,sticky:bands.map(b=>getComputedStyle(b).position)};
      for(let y=0;y<document.documentElement.scrollHeight-H;y+=60){
        scrollTo(0,y);await new Promise(r=>requestAnimationFrame(r));
        const sTop=parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--stick-top'))||64;
        const lues=inner.filter(c=>{const q=c.getBoundingClientRect();return q.top>sTop&&q.bottom<H;});
        if(!lues.length)continue;
        out.positions++;
        for(const c of lues){
          let p=c.parentElement,band=null;
          while(p){if(p.classList&&p.classList.contains('sv-decwrap')){band=p.querySelector(':scope>.sv-band');break;}p=p.parentElement;}
          if(!band)continue;
          const q=band.getBoundingClientRect();
          if(!(q.bottom>0&&q.top<H-4&&q.height>4))out.sans++;}
        // Deux bandes COLLÉES (chacune à son top résolu) ne doivent pas se chevaucher ; pendant
        // l'approche, l'enfant glisse DERRIÈRE son ancêtre — comportement ECL voulu, pas un défaut.
        const colle=[];
        for(const b of bands){const q=b.getBoundingClientRect();if(q.height<4)continue;
          const cible=parseFloat(getComputedStyle(b).top);
          if(Number.isFinite(cible)&&Math.abs(q.top-cible)<=2)colle.push(q);}
        for(let i=0;i<colle.length;i++)for(let j=i+1;j<colle.length;j++)
          if(colle[i].top<colle[j].bottom-1&&colle[j].top<colle[i].bottom-1)out.overlap++;}
      scrollTo(0,0);
      const o=document.querySelector('.sv-decwrap>.sv-band'),n=document.querySelector('.sv-decwrap .sv-decwrap>.sv-band');
      out.zOk=+getComputedStyle(n).zIndex<+getComputedStyle(o).zIndex;
      return out;});
    t('360 px : les bandes de décision sont collantes', r.sticky.every(p=>p==='sticky'), JSON.stringify(r.sticky));
    t('360 px : aucune étape lue sans sa question visible', r.sans===0, `${r.sans} cas sur ${r.positions} positions balayées`);
    t('360 px : deux bandes collées ne se chevauchent pas', r.overlap===0, r.overlap+' chevauchement(s)');
    t('360 px : z-ordre décroissant (l\'enfant se replie derrière son ancêtre)', r.zOk===true);
    // DÉCROCHAGE : une bande épinglée alors que sa décision a quitté l'écran serait un bandeau
    // permanent — exactement ce que le décrochage natif (bornage par .sv-decwrap) doit empêcher.
    const dec=await page.evaluate(async()=>{
      const bands=[...document.querySelectorAll('.sv-decwrap>.sv-band')];
      const fautes=[];
      for(let y=0;y<document.documentElement.scrollHeight-innerHeight;y+=80){
        scrollTo(0,y);await new Promise(r=>requestAnimationFrame(r));
        for(const b of bands){
          const dw=b.closest('.sv-decwrap');
          const bq=b.getBoundingClientRect(),dq=dw.getBoundingClientRect();
          if(bq.bottom>0&&bq.top<innerHeight&&!(dq.bottom>0&&dq.top<innerHeight))
            fautes.push(y);}}
      scrollTo(0,0);return fautes;});
    t('360 px : la bande se décroche dès que sa décision quitte l\'écran', dec.length===0,
      dec.length+' position(s) fautive(s)');
    await page.close();
  }
  {
    const page=await openStatic(1280,900);
    const r=await page.evaluate(()=>[...document.querySelectorAll('.sv-decwrap>.sv-band')]
      .map(b=>getComputedStyle(b).position+'|'+(b.style.top||'-')));
    t('1280 px : aucun épinglage, les bandes restent dans le flux',
      r.every(x=>x==='static|-'), JSON.stringify(r));
    await page.close();
  }
}
// ══ Le RENDU GUIDÉ, jusqu'ici couvert par RIEN ═══════════════════════════════
// `grep -rn 'nav-wrap\|navNext\|bindNavEvents' tests.html scripts/` rendait 0 : la vue guidée
// (celle d'une fiche SANS algorithme — c'est-à-dire ce que produit `blankFiche()`, donc toute
// fiche neuve) n'était mesurée nulle part. C'est ce trou qui a laissé vivre le défaut v4.42.0 :
// décocher après « Terminer l'algorithme » laissait la bannière de fin à l'écran, parce que le
// reset de `state.flowEnded` était enfermé dans un `if(nn)` alors que `#navNext` n'existe
// justement plus à cet instant. Le journal, lui, faisait les deux — la divergence entre les deux
// copies du cochage était invisible faute de sonde.
console.log('\n══ Rendu guidé · décocher annule la fin de l\'algorithme ══');
{
  const page=await br.newPage({viewport:{width:390,height:844}});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(async()=>{
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();
    await new Promise(r=>setTimeout(r,120));
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();
    await new Promise(r=>setTimeout(r,400));});
  const r=await page.evaluate(async()=>{
    // Fiche MONO-BLOC : pas d'algorithme -> rendu guidé (`navSection`), pas le journal.
    const f=migrate({id:'dgui',title:'Sonde guidée',blocks:[
      {id:'b1',type:'steps',title:'Bloc unique',steps:['Étape A','Étape B']}],start:'b1'});
    await Data.put(f);fiches.push(f);
    openRead(f.id);await new Promise(r=>setTimeout(r,350));
    const guide=!document.querySelector('#readTopSeg')&&!!document.querySelector('.nav-wrap');
    for(const li of document.querySelectorAll('[data-ck]')){li.click();await new Promise(r=>setTimeout(r,250));}
    const nn=document.getElementById('navNext');if(nn)nn.click();
    await new Promise(r=>setTimeout(r,350));
    const finActee=!!document.querySelector('.flow-end')&&state.flowEnded===true;
    document.querySelector('[data-ck]').click();await new Promise(r=>setTimeout(r,400));
    return {guide,finActee,flowEnded:state.flowEnded,
      banniere:!!document.querySelector('.flow-end'),bouton:!!document.getElementById('navNext')};});
  t('la fiche mono-bloc rend bien la vue GUIDÉE (.nav-wrap, pas de bascule de mode)',r.guide);
  t('« Terminer l\'algorithme » acte la fin (bannière + drapeau)',r.finActee);
  t('décocher remet state.flowEnded à false',r.flowEnded===false);
  t('décocher retire la bannière « Algorithme terminé »',r.banniere===false,'bannière encore présente');
  t('décocher fait revenir le bouton d\'avancement',r.bouton===true,'#navNext absent');
  await page.close();
}

// ══ ECAM — « rien ne bouge sous le doigt » : le RÉSIDU d'ancrage ═══════════
// Le motif « mesurer, re-rendre, compenser » vivait en QUATRE copies dont UNE SEULE renvoyait son
// résidu (v4.45.0 : `keepAnchor`, source unique). L'invariant le plus cité du projet devient donc
// mesurable — encore faut-il le mesurer. Le résidu est BORNÉ par le haut de page : on défile
// exprès avant le geste, sinon `scrollBy` ne peut pas descendre sous 0 et le contrôle mesurerait
// la limite structurelle au lieu de l'ancrage (cf. la doctrine de `state.confOpen`).
console.log('\n══ ECAM · ancrage — résidu nul au geste de première action ══');
{
  const page=await br.newPage({viewport:{width:390,height:844}});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(async()=>{
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();
    await new Promise(r=>setTimeout(r,120));
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();
    await new Promise(r=>setTimeout(r,400));
    window.__anc=[];const o=window.keepAnchor;
    window.keepAnchor=function(sel,rr){const el=sel?main.querySelector(sel):null;
      const av=el?el.getBoundingClientRect().top:null;
      const r=o.call(this,sel,rr);const ap=sel?main.querySelector(sel):null;
      window.__anc.push({sel:String(sel).slice(0,24),residu:r,
        derive:(av!=null&&ap)?Math.round(ap.getBoundingClientRect().top-av):null});return r;};});
  // 1ʳᵉ action de session : cocher SANS avoir cliqué « démarrer » -> renderKeepAnchor.
  const a=await page.evaluate(async()=>{
    const f=fiches.find(x=>/Arrêt cardiaque/.test(x.title))||fiches[0];
    openRead(f.id);await new Promise(r=>setTimeout(r,350));
    window.scrollTo(0,600);await new Promise(r=>setTimeout(r,250));
    window.__anc=[];
    const li=document.querySelector('[data-ck]');if(li)li.click();
    await new Promise(r=>setTimeout(r,500));return window.__anc;});
  t('1ʳᵉ action : l\'ancrage est bien invoqué',a.length>0,'aucun appel de keepAnchor');
  // « PAS MESURÉ » N'EST PAS « N'A PAS BOUGÉ ». Si l'ancre DISPARAÎT pendant le re-rendu (une
  // condensation du journal transforme la carte visée en chip, par exemple), `keepAnchor` ne peut
  // rien compenser et la sonde ne peut calculer aucune dérive. Or `Math.abs(null)` vaut 0 : le
  // contrôle ci-dessous passait donc au VERT sans avoir rien mesuré, exactement sur le cas qu'il
  // prétend couvrir. On exige d'abord que la mesure ait EU LIEU (leçon v4.31.1, 3ᵉ occurrence).
  if(a.length)t('1ʳᵉ action : le résidu est réellement MESURÉ (ancre retrouvée)',
    a[0].residu!==null&&a[0].derive!==null,
    `résidu ${a[0].residu}, dérive ${a[0].derive} — ancre perdue pendant le re-rendu ?`);
  // Tolérance 1 px : c'est du SOUS-PIXEL de compositeur (WebKit rend 1 px là où Blink rend 0,
  // arithmétique identique) — pas un défaut d'ancrage. Au-delà, la vue a réellement sauté.
  if(a.length)t('1ʳᵉ action : l\'étape tapée ne bouge pas (≤ 1 px)',
    a[0].derive!==null&&Math.abs(a[0].derive)<=1,
    `dérive ${a[0].derive} px, résidu ${a[0].residu} px`);
  // Rendu GUIDÉ (fiche à un bloc) : le remplacement chirurgical est ancré lui aussi.
  const g=await page.evaluate(async()=>{
    const f=migrate({id:'ancd',title:'Ancre guidée',blocks:[
      {id:'b1',type:'steps',title:'Bloc unique',steps:['a','b','c','d','e','f']}],start:'b1'});
    await Data.put(f);fiches.push(f);
    openRead(f.id);await new Promise(r=>setTimeout(r,350));
    document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,350));
    window.scrollTo(0,300);await new Promise(r=>setTimeout(r,250));
    window.__anc=[];renderNavOnly();
    await new Promise(r=>setTimeout(r,400));return window.__anc;});
  t('guidé : le remplacement du bloc est ancré',g.length>0&&g[0].sel.indexOf('nav-wrap')>=0,
    JSON.stringify(g));
  if(g.length)t('guidé : le résidu est réellement MESURÉ (ancre retrouvée)',
    g[0].residu!==null&&g[0].derive!==null,
    `résidu ${g[0].residu}, dérive ${g[0].derive} — ancre perdue pendant le re-rendu ?`);
  if(g.length)t('guidé : le bloc ne bouge pas (≤ 1 px)',
    g[0].derive!==null&&Math.abs(g[0].derive)<=1,
    `dérive ${g[0].derive} px`);
  await page.close();
}

await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} contrôles doctrine OK${ko?` — ${ko} ÉCHEC(S)`:''}`);
process.exit(ko?1:0);
