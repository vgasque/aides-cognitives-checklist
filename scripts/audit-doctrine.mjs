/* LOT 7 — volet DOCTRINE : ECAM / QRH / FAA AC 120-71B, mesuré sur l'app réelle.
   Chaque contrôle traduit une règle de sûreté en invariant observable. */
import { serveApp, moteur, NOM_MOTEUR, ROOT , items, amorce, ouvrirFiche, demarrerSession} from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();
let ok=0,ko=0;
const t=(nom,cond,det)=>{if(cond){ok++;console.log('  ✓ '+nom);}else{ko++;console.log('  ✗ '+nom+(det?'\n      '+det:''));}};

async function session(w,demarrer){
  const page=await br.newPage({viewport:{width:w,height:820}});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  await ouvrirFiche(page,/Arrêt cardiaque/);
  // `demarrer===false` = l'écran d'un INVITÉ : la fiche est ouverte, mais rien n'a démarré
  // localement — c'est le principe même du miroir, et c'est ce qui faisait disparaître le quai.
  if(demarrer!==false)await demarrerSession(page);
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
  /* LOT T8 (v5.0.0) — « Se repérer » a quitté la rangée : l'immobilité se mesure désormais sur
     ce qui l'occupe, c'est-à-dire l'AXE DE DENSITÉ et « Consulter ». L'invariant ECAM est
     inchangé (un contrôle est toujours au même endroit quel que soit l'état du quai) ; c'est la
     liste des contrôles qui a changé, pas la règle. */
  const a=await snap(), pa=await geo('allBtn'), ra=await geo('refBtn');
  // faire varier l'état : ajouter des minuteurs (la partie VARIABLE du quai)
  await page.evaluate(async()=>{
    const add=[...document.querySelectorAll('.rt-add,.add-line')];
    for(const b of add.slice(0,3)){b.click();await new Promise(r=>setTimeout(r,120));}});
  await page.waitForTimeout(300);
  const b=await snap(), pb=await geo('allBtn'), rb=await geo('refBtn');
  t('ordre du quai identique quel que soit l\'état', JSON.stringify(a)===JSON.stringify(b), a+'\n      → '+b);
  t('axe de densité immobile (px)', pa!==null&&pa===pb, `${pa} → ${pb}`);
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
  await amorce(page);
  await ouvrirFiche(page,/Arrêt cardiaque/);
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

/* ══ LE MENU ⋯ TIENT DANS L'ÉCRAN, MARGE DU MATÉRIEL COMPRISE (v4.73.2) ═════════════════════════
   Signalé deux fois à l'usage : d'abord en fenêtre basse, puis « pareil, menu ⋯ tronqué » en grande
   police. Il porte jusqu'à seize rangées, et à 130 % chacune passe sur deux ou trois lignes — les
   dernières, dont « Terminer la session… », tombaient hors de l'écran SANS défilement, donc
   INATTEIGNABLES en silence. On mesure les deux moitiés de l'invariant : la boîte tient dans la
   zone visible ET la dernière rangée est réellement atteignable une fois défilé au bout.
   `--sab` est FORCÉE à 34 px sur un tour : c'est la bande de l'indicateur d'accueil d'un iPhone,
   que `visualViewport.height` INCLUT — le terme qui manquait, et qu'un moteur de bureau ne
   présente jamais. Sans ce tour, le contrôle serait aveugle au défaut effectivement observé. */
console.log('\n══ Chrome · le menu ⋯ tient dans l\'écran (390/430 × 4 tailles de texte) ══');
{
  const page=await session(390);
  for(const w of [390,430]){
    await page.setViewportSize({width:w,height:844});
    for(const z of [100,130]) for(const sab of [0,34]){
      const r=await page.evaluate(async([z,sab])=>{
        document.documentElement.style.setProperty('--sab',sab+'px');
        applyZoom(z);render();await new Promise(x=>setTimeout(x,260));
        document.getElementById('hdrMore').click();
        await new Promise(x=>setTimeout(x,220));
        const m=document.getElementById('moreMenu');
        const zf=(parseFloat(document.documentElement.style.zoom)||100)/100;
        const vv=window.visualViewport;
        const visible=((vv&&vv.height)?vv.height:window.innerHeight)-sab*zf;
        const b=m.getBoundingClientRect();
        // Dernière rangée atteignable : on défile le menu au bout et on la mesure là.
        m.scrollTop=m.scrollHeight;
        await new Promise(x=>setTimeout(x,60));
        const rows=[...m.querySelectorAll('.mm-row')];
        const der=rows.length?rows[rows.length-1].getBoundingClientRect():null;
        const out={bas:+b.bottom.toFixed(1),visible:+visible.toFixed(1),n:rows.length,
          derBas:der?+der.bottom.toFixed(1):null,derHaut:der?+der.top.toFixed(1):null};
        closeMoreMenu();
        document.documentElement.style.removeProperty('--sab');
        return out;},[z,sab]);
      const nom=`${w} px à ${z} %${sab?' + marge matérielle':''}`;
      t(`${nom} : le menu tient dans la zone visible`, r.bas<=r.visible+0.5,
        `bas ${r.bas} px / visible ${r.visible} px (${r.n} rangées)`);
      t(`${nom} : la dernière rangée est atteignable`,
        r.derBas!=null&&r.derBas<=r.visible+0.5&&r.derHaut>=0,
        `dernière rangée ${r.derHaut}–${r.derBas} px / visible ${r.visible} px`);
    }
  }
  await page.evaluate(()=>applyZoom(100));
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
  /* ET SOUS LA PLUS GRANDE TAILLE DE TEXTE — le trou de couverture qui a produit le défaut
     (v4.73.1, signalé à l'usage : « ⤢ Se repérer » coupé, « ⤢ Consulter » hors écran). Ce témoin
     ne mesurait qu'à zoom 1, alors que le réglage de taille du texte est un `zoom` sur `<html>` :
     la place réellement disponible vaut `largeur ÷ zoom` (331 px sur un écran de 430 à 130 %) et
     AUCUN palier `max-width` ne s'y déclenche, puisqu'une media query mesure la fenêtre du
     périphérique. On mesure donc les mêmes deux propriétés aux quatre paliers de taille du texte,
     sur les deux largeurs de téléphone les plus courantes. La géométrie est lue en px VISUELS des
     deux côtés (rects contre rects), donc comparable sans division. */
  for(const w of [390,430]){
    await page.setViewportSize({width:w,height:820});
    for(const z of [90,100,115,130]){
      const r=await page.evaluate(async(z)=>{applyZoom(z);render();
        await new Promise(x=>setTimeout(x,260));
        const btns=[...document.querySelectorAll('#crisisCtrl button')].filter(b=>b.offsetParent);
        const right=Math.max(...btns.map(b=>b.getBoundingClientRect().right));
        const din=document.querySelector('#crisisCtrl .dock-in');
        const db=din.getBoundingClientRect(),ds=getComputedStyle(din);
        const zf=(parseFloat(document.documentElement.style.zoom)||100)/100;
        const _ab=document.getElementById('allBtn'),_sg=document.querySelector('#crisisDock .seg');
        return {right:+right.toFixed(1),vw:innerWidth,
          xCtrl:_ab?Math.round(_ab.getBoundingClientRect().left):null,
          xDock:_sg?Math.round(_sg.getBoundingClientRect().left):null,
          bordInterne:+(db.right-parseFloat(ds.paddingRight)*zf).toFixed(1),
          eff:Math.round(innerWidth/zf),
          libelles:btns.map(b=>b.textContent.trim()).join('|')};},z);
      t(`${w} px à ${z} % : aucun bouton de commande rogné`,
        r.right<=r.vw+0.5&&r.right<=r.bordInterne+0.5,
        `bord droit ${r.right} px, bord interne ${r.bordInterne} px, viewport ${r.vw} px (${r.eff} px effectifs)`);
      /* AUCUN LIBELLÉ N'EST SACRIFIÉ POUR TENIR : c'est la seconde moitié de l'invariant, et sans
         elle un futur « correctif » pourrait faire passer le premier en masquant les mots — ce que
         la doctrine interdit explicitement (« deux pictogrammes voisins sans mot se confondent sous
         stress »). On exige que chaque bouton porte encore du texte.
         Le premier libellé est celui de la DESTINATION du bouton d'excursion : « Tout voir » à
         l'aller, « Un bloc » au retour (lot A, v5.0.0) — l'un OU l'autre, jamais les deux. */
      /* ⚠ LES DEUX RANGÉES COLLANTES PARTENT DU MÊME x (signalé à l'usage : « aligne le compteur
         de session sur Tout voir »). Mesuré avant : commandes à 10, session à 18 au-dessus de
         780 px, et session à 0 en dessous — deux verticales, jamais la même. */
      t(`${w} px à ${z} % : commandes et quai partent du même x`,
        r.xCtrl!==null&&r.xDock!==null&&Math.abs(r.xCtrl-r.xDock)<=1,
        `commandes ${r.xCtrl} px · quai ${r.xDock} px`);
      t(`${w} px à ${z} % : les libellés sont intacts`,
        /Tout voir|Un bloc/.test(r.libelles)&&/Consulter/.test(r.libelles),
        r.libelles);
    }
  }
  /* LE TROU ENTRE DEUX PALIERS (v4.74.2, signalé à l'usage : « à 435-440 px, Se repérer et Cons.
     passent sous Guidé/Statique, puis ça revient à une ligne si on élargit ou rétrécit un peu »).
     Le témoin ne mesurait QUE des largeurs où un palier de compression est actif (320/360/375/390,
     donc toutes < 430) : la bande 430→441 — trop étroite pour la recette large, pas assez pour
     avoir droit à la compressée — n'était vue par personne, et l'enroulement, qui est le dernier
     recours, y devenait le premier. On mesure donc la HAUTEUR de la rangée : une seule ligne, ou
     l'enroulement s'est produit. Les deux bornes ET l'intérieur, parce que c'est un intervalle. */
  await page.evaluate(()=>applyZoom(100));
  {
    let h1=null;
    for(const w of [429,431,435,440,444,460]){
      await page.setViewportSize({width:w,height:820});
      await page.waitForTimeout(240);
      const r=await page.evaluate(()=>{
        const din=document.querySelector('#crisisCtrl .dock-in');
        const kids=[...din.children].filter(k=>k.getBoundingClientRect().height>0);
        const tops=new Set(kids.map(k=>Math.round(k.getBoundingClientRect().top)));
        return {h:Math.round(din.getBoundingClientRect().height),
          wrapped:din.classList.contains('wrapped'),
          rangs:Math.max(...kids.map(k=>k.getBoundingClientRect().bottom))-Math.min(...kids.map(k=>k.getBoundingClientRect().top)),
          libelles:[...din.querySelectorAll('button')].filter(b=>b.offsetParent).map(b=>b.textContent.trim()).join('|')};});
      if(h1===null)h1=r.h;
      t(`${w} px : la rangée de commandes tient sur UNE ligne`,
        !r.wrapped&&r.h<=h1+2, `hauteur ${r.h} px (référence ${h1}), wrapped=${r.wrapped}`);
      t(`${w} px : les libellés sont intacts`,
        /Tout voir|Un bloc/.test(r.libelles)&&/Consulter/.test(r.libelles),
        r.libelles);
    }
  }
  await page.close();
}

/* LA BASCULE GUIDÉ ↔ STATIQUE GARDE LE BLOC COURANT (v4.74.2, signalé à l'usage : « comment
   améliorer le passage guidé/statique lorsqu'on a déjà scrollé ? »). Avant : `scrollTo(0,0)`
   systématique — et conserver `scrollY` n'aurait rien voulu dire non plus, les deux vues n'ayant
   pas la même hauteur. La seule ancre qui EXISTE des deux côtés est le bloc courant, marqué `.cur`
   dans les deux vues. On mesure la DÉRIVE en pixels, comme pour toutes les mécaniques d'ancrage du
   projet, et l'on vérifie le repli : sans bloc courant à l'écran, on repart du haut. */
console.log('\n══ ECAM · bascule guidé ↔ statique ancrée sur le bloc courant ══');
{
  const page=await session(390);
  await page.waitForTimeout(250);
  const r=await page.evaluate(async()=>{
    const w=m=>new Promise(x=>setTimeout(x,m));
    const CUR='.ov-block.cur,.sv-cell.cur,.sv-band.cur';
    const top=()=>{const e=main.querySelector(CUR);return e?e.getBoundingClientRect().top:null;};
    // on défile pour que le bloc courant ne soit PAS en haut de l'écran
    const el=main.querySelector(CUR);
    window.scrollTo(0,window.scrollY+el.getBoundingClientRect().top-260);
    await w(200);
    const av=top();
    document.getElementById('allBtn').click(); await w(400);
    const apStat=top(), yStat=window.scrollY;
    document.getElementById('allBtn').click(); await w(400);
    const apDyn=top();
    return {av:Math.round(av),apStat:Math.round(apStat),apDyn:Math.round(apDyn),yStat:Math.round(yStat)};});
  t('guidé → statique : le bloc courant ne dérive pas', Math.abs(r.apStat-r.av)<=2,
    `${r.av} px → ${r.apStat} px`);
  t('… et l’on n’est PAS remonté en haut', r.yStat>40, `scrollY ${r.yStat} px`);
  t('statique → guidé : idem dans l’autre sens', Math.abs(r.apDyn-r.av)<=2,
    `${r.av} px → ${r.apDyn} px`);
  await page.close();
}

// La MÊME règle vaut hors crise : un débordement silencieux reste un débordement. L'ÉDITEUR
// sortait « ⋯ » de 6,2 px à 320 px (bouton VISIBLE, donc pixels inatteignables) — le commentaire
// du CSS visait 360 et le tenait, personne n'avait mesuré en dessous.
console.log('\n══ ECAM · barre d\'éditeur sans rognage (320/360) ══');
{
  const page=await br.newPage({viewport:{width:320,height:844}});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  await page.evaluate(async()=>{
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
  await amorce(page);
  await ouvrirFiche(page,/Arrêt cardiaque/);
  await demarrerSession(page);
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
    {id:'a',kind:'do',title:'Début',items:items(st(3)),next:'d1'},
    {id:'d1',kind:'decision',title:'Analyse du rythme',question:'Le rythme est-il choquable (FV / TV sans pouls) ?',
      options:[{label:'Choquable',target:'b1'},{label:'Non choquable',target:'b9'}]},
    {id:'b1',kind:'do',title:'Choc',items:items(st(4)),next:'d2'},
    {id:'d2',kind:'decision',title:'Réévaluation',question:'Reprise d\'activité circulatoire spontanée ?',
      options:[{label:'Non',target:'b6'},{label:'Oui',target:'b8'}]},
    {id:'b6',kind:'do',title:'Poursuite',items:items(st(6)),next:'fin'},
    {id:'b8',kind:'do',title:'Post-arrêt',items:items(st(3)),next:'fin'},
    {id:'b9',kind:'do',title:'Sans choc',items:items(st(4)),next:'fin'},
    {id:'fin',kind:'do',title:'Surveillance',items:items(st(2)),next:null}],
    timers:[],counters:[],confirmation:[],verify:[],notForget:[],differentials:[],sources:[],images:[]};
  const openStatic=async(w,h)=>{
    const page=await br.newPage({viewport:{width:w,height:h}});
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'));
    /* PAS `amorce()` ici, à dessein : cette sonde injecte SA fiche et ne pose pas les exemples —
       le clic « Commencer » seul n'est pas une copie du geste partagé, c'est un autre trajet. */
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
  await amorce(page);
  const r=await page.evaluate(async()=>{
    // Fiche MONO-BLOC : pas d'algorithme -> rendu guidé (`navSection`), pas le journal.
    const f=migrate({id:'dgui',title:'Sonde guidée',blocks:[
      {id:'b1',kind:'do',title:'Bloc unique',items:['Étape A','Étape B'].map(x=>v4MakeItem(uid('i'),'do',x))}],start:'b1'});
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
  await amorce(page);
  await page.evaluate(async()=>{
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
      {id:'b1',kind:'do',title:'Bloc unique',items:['a','b','c','d','e','f'].map(x=>v4MakeItem(uid('i'),'do',x))}],start:'b1'});
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

/* ══ LA RANGÉE D'ÉTAT NE ROGNE PAS, MÊME AVEC UN LIBELLÉ LONG (v4.47.0) ══
   `audit-doctrine` contrôlait déjà le débordement de la rangée de COMMANDES à 320/360/375/390.
   La rangée d'ÉTAT n'avait AUCUN contrôle symétrique — alors que `#cbTimers` est en
   `overflow:hidden` : un débordement n'y produit ni barre de défilement, ni glissement possible,
   RIEN. Et la clé de la boucle d'ajustement était aveugle aux INTITULÉS (elle ne décrivait que le
   nombre de chiffres) : renommer un minuteur faisait déborder le quai en silence — mesuré à
   119 px à 320 px avant correctif. Ce contrôle mesure les deux : intitulé long ET libellé de
   session étendu, ce dernier étant l'emplacement où le partage écrira (Lot 4). */
console.log('\n══ ECAM · la rangée d\'ÉTAT ne rogne jamais ══');
for(const w of [320,360,390]){
  const page=await session(w);
  const r=await page.evaluate(async()=>{
    /* DEUX TEMPS, et c'est tout le contrôle. Changer plusieurs choses d'un coup ferait bouger la
       clé d'ajustement par un AUTRE terme (nombre de minuteurs, chiffres du chrono) et la boucle
       se re-mesurerait — le contrôle passerait au vert sans rien prouver.
       Temps 1 : on installe le pire cas réaliste et on laisse la boucle se stabiliser.
       Temps 2 : on RENOMME un minuteur, et RIEN d'autre. C'est le scénario exact du défaut. */
    const ids=Object.keys(Runtime.timers).slice(0,3);
    ids.forEach(id=>{const t=Runtime.timers[id];t.running=true;t.lastStart=Date.now();});
    Runtime.startedAt=Date.now()-3*3600*1000;      // chrono à h:mm:ss, le cas le plus large
    updateRtStrip();await new Promise(x=>setTimeout(x,400));
    const el=document.getElementById('cbTimers');
    const depAvant=el.scrollWidth-el.clientWidth;
    if(ids[0])Runtime.timers[ids[0]].label='Cycle de compressions thoraciques profondes';
    updateRtStrip();await new Promise(x=>setTimeout(x,400));
    const dep=el.scrollWidth-el.clientWidth;
    const nb=el.querySelectorAll('.seg').length;
    const plus=!!el.querySelector('.cbt-n');
    return {depAvant,dep,nb,plus,arme:ids.length};
  });
  t(`${w} px · état stable avant renommage : aucun débordement`,r.depAvant<=1,
    `déborde déjà de ${r.depAvant} px`);
  // Tolérance 1 px : sous-pixel de compositeur, comme pour la rangée de commandes.
  t(`${w} px · 3 minuteurs + intitulé long : la rangée d'état ne rogne pas`,r.dep<=1,
    `déborde de ${r.dep} px`);
  // Et si elle a dû retirer un segment, le « +n » DOIT l'annoncer — une zone d'état ne cache
  // jamais une alarme en silence.
  t(`${w} px · ce qui est retiré est annoncé par « +n »`,r.nb>=1&&(r.arme<=r.nb-1||r.plus),
    `${r.nb} segment(s), +n ${r.plus?'présent':'absent'}`);
  await page.close();
}

/* ══ L'ALARME NE TOMBE JAMAIS AVANT LE DÉCORATIF (v4.47.0) ══
   Le segment ambre d'un minuteur ÉCHU est le canal d'ACQUITTEMENT de l'alarme : c'est la seule
   trace qui persiste dans une zone qui ne quitte jamais l'écran une fois le bip passé. Or la
   boucle d'ajustement retirait les segments un à un et n'essayait « sans chevron » qu'arrivée à
   ZÉRO segment : elle sacrifiait donc l'alarme pour garder un glyphe `aria-hidden` que son propre
   commentaire dit « purement décoratif ». Et si même cette version ne tenait pas, elle REMETTAIT
   le chevron par-dessus — réécrivant un état qu'elle venait de mesurer comme débordant.
   Le contrôle mesure les deux : à toutes les largeurs de téléphone, avec un intitulé long sur le
   minuteur échu, `.seg.due` est PRÉSENT et le quai ne rogne pas. */
console.log('\n══ ECAM · l\'alarme survit au décoratif ══');
for(const w of [320,360,390]){
  const page=await session(w);
  const r=await page.evaluate(async()=>{
    const ids=Object.keys(Runtime.timers).slice(0,3);
    ids.forEach((id,i)=>{const t=Runtime.timers[id];
      t.type='interval';t.seconds=120;t.running=i>0;t.lastStart=Date.now();
      t.elapsedMs=i===0?125000:0;});                       // le 1ᵉʳ est ÉCHU
    if(ids[0])Runtime.timers[ids[0]].label='Cycle de compressions thoraciques profondes';
    Runtime.startedAt=Date.now()-3*3600*1000;              // chrono h:mm:ss, le cas le plus large
    updateRtStrip();await new Promise(x=>setTimeout(x,400));
    const el=document.getElementById('cbTimers');
    const due=el.querySelector('.seg.due');
    const lu=()=>({dep:el.scrollWidth-el.clientWidth, alarme:!!el.querySelector('.seg.due'),
      txt:el.textContent.trim().slice(0,90)});
    const nu=lu();
    /* PIRE CAS DU LOT 4 : le libellé du chrono porte EN PLUS le jeton de partage. C'est la
       combinaison que la contre-expertise annonçait fatale à l'alarme — elle ne l'est plus, mais
       elle doit être mesurée ici, pas supposée. */
    Share.mode='guest';Share.status='active';Share.role='scribe';
    Share.lastOk=Date.now();Share._act=Date.now();
    updateRtStrip();await new Promise(x=>setTimeout(x,250));
    const avecJeton=lu(), jeton=/suit/.test(el.textContent);
    Share.mode='off';Share.status='off';
    return {dep:nu.dep, alarme:nu.alarme,
      glyphe:!!due&&/△/.test(due.textContent),
      mot:!!due&&/échu/.test(due.textContent),
      avecJeton, jeton, txt:nu.txt};
  });
  t(`${w} px · le segment ÉCHU reste affiché`,r.alarme,`quai : « ${r.txt} »`);
  t(`${w} px · l'échu porte le glyphe △ ET le mot (lecteur d'écran)`,r.glyphe&&r.mot,
    `glyphe ${r.glyphe?'oui':'NON'}, mot ${r.mot?'oui':'NON'}`);
  t(`${w} px · la rangée d'état ne rogne pas pour autant`,r.dep<=1,`déborde de ${r.dep} px`);
  t(`${w} px · jeton de partage EN PLUS : l'alarme survit et rien ne rogne`,
    r.jeton&&r.avecJeton.alarme&&r.avecJeton.dep<=1,
    `jeton ${r.jeton?'écrit':'ABSENT'}, alarme ${r.avecJeton.alarme?'là':'PERDUE'}, déborde de ${r.avecJeton.dep} px\n      « ${r.avecJeton.txt} »`);
  await page.close();
}

/* ══ LE QUAI DE L'INVITÉ EXISTE, ET IL DIT LA MAIN (v4.47.0) ══
   AC 120-71B §6.4 pt 1 : à tout instant, qui tient la checklist ne souffre AUCUNE ambiguïté. Or le
   quai n'apparaissait que si une session avait démarré LOCALEMENT — un invité qui suit n'a rien
   démarré, c'est le principe du miroir : tant qu'aucun minuteur ne tournait, il n'avait ni le
   détenteur de la main ni l'indicateur de péremption. Les deux informations que la doctrine veut
   permanentes n'avaient pas de conteneur.
   On vérifie AUSSI qu'elles sont LISIBLES : l'ellipse du quai fonctionne désormais (cf. plancher de
   112 px), donc un jeton trop long ne déborderait plus — il serait TRONQUÉ, c'est-à-dire muet. */
console.log('\n══ AC 120-71B · le quai de l\'invité dit qui tient la main ══');
for(const w of [320,360,390]){
  const page=await session(w,false);
  const r=await page.evaluate(async()=>{
    const el=document.getElementById('cbTimers');
    const avant=el.hidden;                                  // aucune session locale : quai absent
    Share.mode='guest';Share.status='active';Share.role='scribe';
    Share.lastOk=Date.now();Share._act=Date.now();
    Runtime.startedAt=Date.now()-65000;                     // le chrono REÇU de l'hôte
    updateRtStrip();await new Promise(x=>setTimeout(x,250));
    const lu=()=>{const l=el.querySelector('.seg-l.seg-sess');
      return {txt:l?l.textContent:'',coupe:!!l&&l.scrollWidth>Math.round(l.getBoundingClientRect().width)+1};};
    const suit=lu(), dep1=el.scrollWidth-el.clientWidth, cache=el.hidden;
    Share.role='lead';updateRtStrip();await new Promise(x=>setTimeout(x,120));
    const main=lu();
    Share.lastOk=Date.now()-120000;updateRtStrip();await new Promise(x=>setTimeout(x,120));
    const fige=lu(), off=!!el.querySelector('.seg-l.seg-sess.off');
    Share.lastOk=Date.now();Share.status='revoked';updateRtStrip();await new Promise(x=>setTimeout(x,120));
    const coupe=lu(), toujours=!el.hidden;
    Share.mode='off';Share.status='off';
    return {avant,cache,dep1,suit,main,fige,off,coupe,toujours};
  });
  t(`${w} px · sans partage, aucune session locale : pas de quai`,r.avant,'le quai était déjà là');
  t(`${w} px · invité : le quai EXISTE sans session locale`,!r.cache);
  t(`${w} px · il dit « suit », entièrement lisible`,/suit/.test(r.suit.txt)&&!r.suit.coupe,
    `« ${r.suit.txt} »${r.suit.coupe?' — TRONQUÉ':''}`);
  t(`${w} px · la main prise : « main », lisible`,/main/.test(r.main.txt)&&!r.main.coupe,
    `« ${r.main.txt} »${r.main.coupe?' — TRONQUÉ':''}`);
  t(`${w} px · lien figé : le mot le dit et le vert cesse d'affirmer`,
    /figé/.test(r.fige.txt)&&!r.fige.coupe&&r.off,`« ${r.fige.txt} », neutre ${r.off}`);
  t(`${w} px · coupé : le quai reste, le mot change`,
    /coupé/.test(r.coupe.txt)&&!r.coupe.coupe&&r.toujours,`« ${r.coupe.txt} »`);
  t(`${w} px · et la rangée ne rogne pas`,r.dep1<=1,`déborde de ${r.dep1} px`);
  await page.close();
}

/* ══ INCRÉMENTER UN COMPTEUR HORODATE — et ne fait pas remonter le rail (v4.47.0) ══
   « Choc n° 3 à 14:32 » est exactement ce qu'on oublie de noter sous stress, et l'heure est ce
   qui compte cliniquement. Le repère porte une RÉFÉRENCE, pas un mot : son libellé se dérive de
   la fiche, il traverse donc le partage sans texte libre et suit le compteur si on le renomme.
   Le contrôle mesure les deux moitiés : le repère EXISTE, et le rail NE BOUGE PAS — le journal
   vit en fin de rail, qui a son propre défilement, et un rendu complet le remettrait à zéro
   (retour d'usage v4.23.5, « la barre latérale remontait à chaque Noter l'heure »). */
console.log('\n══ Journal · incrémenter un compteur pose un repère horodaté ══');
{
  const page=await session(1280);   // >= 1000 px : le panneau compteurs est dans le DOM
  const r=await page.evaluate(async()=>{
    const inc=document.querySelector('[data-cninc]');
    if(!inc)return {err:'aucun compteur à l\'écran'};
    const cid=inc.dataset.cninc;
    const cLab=((Runtime.fiche.counters||[]).find(x=>x.id===cid)||{}).label||'';
    const rail=document.querySelector('.read-side');
    if(rail)rail.scrollTop=60;
    await new Promise(x=>setTimeout(x,200));
    const railAvant=rail?rail.scrollTop:null;
    const avant=(Runtime.events||[]).length;
    // Deux incréments : le second doit porter le rang 2, pas répéter le premier.
    inc.click();await new Promise(x=>setTimeout(x,250));
    const inc2=document.querySelector('[data-cninc="'+CSS.escape(cid)+'"]');
    if(inc2)inc2.click();
    await new Promise(x=>setTimeout(x,300));
    const ev=Runtime.events||[];
    const labs=window.__acTkLabels?window.__acTkLabels(ev,Runtime.fiche):null;
    const lignes=[...document.querySelectorAll('.tk-panel .tk-lab')].map(i=>i.value);
    return {err:null,cLab,avant,apres:ev.length,
      refs:ev.filter(e=>e.ref&&e.ref.type==='counter').map(e=>e.ref.v),
      lignes,railApres:rail?rail.scrollTop:null,railAvant,
      compteur:Runtime.counters[cid],
      incAttache:!!(inc2&&document.contains(inc2))};
  });
  t('un compteur est bien à l\'écran à 1280 px',!r.err,r.err||'');
  if(!r.err){
    t('deux incréments posent deux repères',r.apres===r.avant+2,`${r.avant} -> ${r.apres}`);
    t('les repères portent le rang du compteur (1 puis 2)',
      JSON.stringify(r.refs.slice(-2))==='[1,2]',JSON.stringify(r.refs));
    t('le libellé affiché dérive du compteur',
      r.lignes.some(l=>l===r.cLab+' n° 2'),JSON.stringify(r.lignes));
    t('le compteur lui-même est à 2',r.compteur===2,String(r.compteur));
    // Le cœur du contrôle : la mise à jour est CHIRURGICALE, donc le rail garde sa position et le
    // bouton reste le même nœud. Un render() complet casserait les deux.
    t('le rail ne remonte pas',r.railAvant===r.railApres,`${r.railAvant} -> ${r.railApres}`);
    t('le bouton reste le MÊME nœud (aucun rendu complet)',r.incAttache===true);
  }
  /* ANNULER N'EST PAS SUPPRIMER. Le × effaçait le repère d'un simple tap : contraire à la règle
     du projet sur les gestes destructeurs en crise, et surtout intenable pour une TRACE qui
     alimente le compte-rendu. On vérifie l'aller-retour complet — et surtout qu'à AUCUN moment le
     repère ne quitte le journal. */
  const v=await page.evaluate(async()=>{
    const n0=(Runtime.events||[]).length;
    const b=document.querySelector('.tk-panel [data-tkdel]');
    if(!b)return {err:'aucun repère à annuler'};
    const id=b.dataset.tkdel;
    b.click();await new Promise(x=>setTimeout(x,250));
    const apresAnnul={n:(Runtime.events||[]).length,
      voidAt:!!(Runtime.events.find(e=>e.id===id)||{}).voidAt,
      barre:!!document.querySelector('.tk-panel .tk-item.tk-void'),
      libelle:(document.querySelector('.tk-panel [data-tkdel="'+CSS.escape(id)+'"]')||{}).textContent};
    const b2=document.querySelector('.tk-panel [data-tkdel="'+CSS.escape(id)+'"]');
    if(b2)b2.click();await new Promise(x=>setTimeout(x,250));
    return {err:null,n0,apresAnnul,
      apresRetour:{n:(Runtime.events||[]).length,
        voidAt:!!(Runtime.events.find(e=>e.id===id)||{}).voidAt,
        barre:!!document.querySelector('.tk-panel .tk-item.tk-void')}};
  }).catch(e=>({err:String(e).slice(0,80)}));
  t('un repère est annulable',!v.err,v.err||'');
  if(!v.err){
    t('annuler NE SUPPRIME PAS la ligne',v.apresAnnul.n===v.n0,`${v.n0} -> ${v.apresAnnul.n}`);
    t('la ligne est marquée annulée et barrée',v.apresAnnul.voidAt&&v.apresAnnul.barre);
    t('le × est devenu un retour (↺)',v.apresAnnul.libelle==='↺',String(v.apresAnnul.libelle));
    t('on peut se raviser : le repère est rétabli',
      !v.apresRetour.voidAt&&!v.apresRetour.barre&&v.apresRetour.n===v.n0);
  }
  await page.close();
}

/* ── TROIS ROGNAGES SIGNALÉS À L'USAGE (v4.55.3) ─────────────────────────────────────────────
   Le contrôle de rognage existait pour la rangée de commandes de crise (v4.43.0) ; ces trois
   surfaces n'étaient mesurées nulle part, et elles débordaient toutes les trois.
   DEUX PRÉCAUTIONS SANS LESQUELLES CES CONTRÔLES NE PROUVERAIENT RIEN — la première version les a
   omises et restait verte avec les défauts réintroduits :
    · le PLAN ne déborde qu'à partir de QUATRE options : la fiche d'exemple n'en a que deux, on
      construit donc une décision à huit branches ;
    · le PANNEAU ne déborde que sur écran TACTILE, où « silencieux ? » et le bouton son montent à
      44 px de cible — d'où un contexte `hasTouch`. */
console.log(`\n══ DOCTRINE · aucun rognage dans les feuilles ni le panneau — moteur ${NOM_MOTEUR} ══`);
for (const w of [320, 360, 390]) {
  const page = await br.newPage({ viewport: { width: w, height: 820 }, hasTouch: true, isMobile: true });
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(() => !document.querySelector('.boot-load'));
  await amorce(page);
  await ouvrirFiche(page, /Arrêt cardiaque/);
  await demarrerSession(page);
  const r = await page.evaluate(async () => {
    const o = {};
    /* (a) LA BARRE DE TITRE D'UNE FEUILLE AFFLEURE LE HAUT. Une règle de largeur étroite reposait
       18 px de rembourrage sur la carte, alors que ces feuilles se donnent `padding:0` — leur
       barre est `sticky top:0` et doit toucher le bord. `:not()` COMPTE LA SPÉCIFICITÉ DE SON
       ARGUMENT : (0,3,0) contre (0,2,0), la règle générique gagnait. */
    openPlanSheet(); await new Promise(x => setTimeout(x, 450));
    {const c = document.querySelector('#planModal .ai-card'), b = document.querySelector('#planModal .pm-bar');
     o.planBarTop = (c && b) ? Math.round(b.getBoundingClientRect().top - c.getBoundingClientRect().top) : null;}
    document.getElementById('planX').click(); await new Promise(x => setTimeout(x, 300));

    /* (c) UNE DÉCISION À HUIT OPTIONS. `flowPlan` met en cache par OBJET (WeakMap) : muter la
       fiche en place ne suffirait pas, il faut un objet neuf. */
    {const src = JSON.parse(JSON.stringify(state.fiche));
     const LB = ['Fibrillation ventriculaire','Asystolie','Rythme sans pouls','Tachycardie ventriculaire',
                 'Bradycardie extrême','Bloc auriculo-ventriculaire','Rythme sinusal','Indéterminé'];
     const cibles = LB.map((l, i) => ({ id: 'zz' + i, kind: 'do', title: 'Conduite ' + (i + 1), items: ['faire ceci'], next: null }));
     src.blocks = [{ id: 'zzdec', type: 'decision', title: 'Rythme au moniteur ?', question: 'Quel rythme ?',
       options: cibles.map((c, i) => ({ label: LB[i], target: c.id })) }, ...cibles];
     src.start = 'zzdec';
     const f = migrate(src);
     state.fiche = f; Runtime.fiche = f;
     state.nav = ['zzdec']; state.navSeq = [0]; state.navPos = 0; state.checked = {};
     render(); await new Promise(x => setTimeout(x, 300));}
    openPlanSheet(); await new Promise(x => setTimeout(x, 450));
    {const body = document.getElementById('planBody');
     let pire = 0, qui = '';
     if (body) { const br2 = body.getBoundingClientRect();
       body.querySelectorAll('*').forEach(el => { const r2 = el.getBoundingClientRect();
         if (!r2.width) return;
         const d = Math.round(r2.right - br2.right);
         if (d > pire) { pire = d; qui = (el.className || el.tagName) + ''; } }); }
     o.planDebord = pire; o.planQui = qui;
     o.planNbLignes = document.querySelectorAll('#planModal .pl-line').length;}
    document.getElementById('planX').click(); await new Promise(x => setTimeout(x, 300));

    /* (b) LA CROIX DU PANNEAU MINUTEURS RESTE DANS LE CADRE. On mesure contre le bord INTÉRIEUR
       (bordure 1 px + rembourrage 14 px), comme le fait l'œil : un bouton qui touche la bordure
       est déjà coupé. */
    const o2 = document.getElementById('rtOpen'); if (o2) { o2.click(); await new Promise(x => setTimeout(x, 350)); }
    {const pan = document.querySelector('.rt-panel'), head = document.querySelector('.rt-head'),
      k = document.querySelector('.rt-x');
     if (pan && k) { const p = pan.getBoundingClientRect(), kr = k.getBoundingClientRect();
       o.croixDebord = Math.round(kr.right - (p.right - 15));
       o.croixVisible = kr.width >= 32 && kr.height >= 32; }
     else { o.croixDebord = null; o.croixVisible = false; }
     o.headDebord = head ? head.scrollWidth - head.clientWidth : null;}
    return o;
  });
  t(`${w} · la barre de « Se repérer » affleure le haut`, r.planBarTop === 0, `${r.planBarTop} px`);
  t(`${w} · témoin : le plan à 8 options est bien rendu`, r.planNbLignes >= 8, `${r.planNbLignes} ligne(s)`);
  t(`${w} · … et aucune ligne ne sort du cadre`, r.planDebord <= 1, `${r.planDebord} px — ${r.planQui}`);
  t(`${w} · la croix des minuteurs reste dans le cadre`, r.croixDebord !== null && r.croixDebord <= 0, `${r.croixDebord} px`);
  t(`${w} · … le bandeau ne déborde pas non plus`, r.headDebord !== null && r.headDebord <= 1, `${r.headDebord} px`);
  t(`${w} · … et la croix reste une cible de 32 px`, r.croixVisible === true);
  await page.close();
}

/* LE QUAI NOMME CE QU'IL CACHE — ET SEULEMENT ALORS (v5.0.0).
   Trois propriétés, et la deuxième est la seule qui rende la première admissible : le rappel
   n'existe QUE lorsque le quai ne montre aucun minuteur. Un témoin qui ne mesurerait que la
   présence du libellé laisserait passer la régression qui compte — celle où il concurrencerait
   l'alarme. On mesure donc aussi l'ÉTAT ARMÉ, où il doit avoir DISPARU. */
console.log('\n══ ECAM · le quai nomme ce qu\'il cache, sans jamais coûter un pixel ══');
for (const w of [320, 360, 390, 430]) {
  const page = await br.newPage({viewport:{width:w,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const wt=m=>new Promise(r=>setTimeout(r,m));
    const f=fiches.find(x=>/Anaphylaxie/i.test(x.title))||fiches[0]; openRead(f.id); await wt(400);
    const b=document.getElementById('sessStart'); if(b)b.click(); await wt(600);
    const e=document.getElementById('cbTimers');
    const lis=()=>({txt:(e.innerText||'').replace(/\s+/g,' ').trim(),
                    deb:e.scrollWidth-e.clientWidth,h:Math.round(e.getBoundingClientRect().height)});
    const repos=lis();
    const t=Object.values(Runtime.timers)[0]; if(t){toggleTimer(t);updateRtStrip();} await wt(400);
    const arme=lis();
    return {repos,arme,declare:Object.keys(Runtime.timers).length};});
  t(`${w} · au repos, le quai NOMME les minuteurs déclarés`, /minuteur/.test(r.repos.txt), r.repos.txt);
  t(`${w} · … sans déborder d'un pixel`, r.repos.deb<=1, `${r.repos.deb} px`);
  t(`${w} · … et sans coûter de hauteur (52 px)`, r.repos.h===52, `${r.repos.h} px`);
  t(`${w} · minuteur ARMÉ : le rappel s'efface, le segment reprend la place`,
    !/\d+ minuteur/.test(r.arme.txt) && /\d\d:\d\d/.test(r.arme.txt), r.arme.txt);
  t(`${w} · … et là non plus rien ne déborde`, r.arme.deb<=1, `${r.arme.deb} px`);
  await page.close();
}

/* LOT T8 — L'AXE DE DENSITÉ, ET LES TROIS FAÇONS DE REGARDER L'AIDE ENTIÈRE (v5.0.0).
   Le contrôle qui compte n'est pas « les onglets s'affichent » : c'est que le SCHÉMA GARDE SES
   COMPORTEMENTS. Le plan interdit de réécrire `buildFlowSVG` — mais poser le SVG dans un onglet
   sans rebrancher ses écouteurs le réduit à une IMAGE, et c'est ce qui s'est produit à la première
   passe (mesuré : zoom figé à 100 %, état de session non peint). On mesure donc le zoom, la
   peinture d'état et la navigabilité, pas la présence. */
console.log('\n══ T8 · axe de densité — « toute la fiche » se regarde de trois façons ══');
for (const w of [320, 390]) {
  const page = await br.newPage({viewport:{width:w,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const wt=m=>new Promise(r=>setTimeout(r,m));
    const f=fiches.find(x=>/Anaphylaxie/i.test(x.title))||fiches[0]; openRead(f.id); await wt(400);
    const b=document.getElementById('sessStart'); if(b)b.click(); await wt(600);
    const seg=[document.querySelector('#allBtn .dp-lbl').textContent.trim()];
    /* Le RETOUR est-il garanti ? On relève le libellé APRÈS l'excursion : le même bouton, à la
       même place, doit nommer le chemin inverse. C'est ce qui distingue une excursion d'un
       changement de format — sans lui, on termine le soin dans une vue qu'on n'a pas choisie. */
    const planBtn=!!document.getElementById('planBtn');
    const xAv=Math.round(document.getElementById('allBtn').getBoundingClientRect().left);
    const hAv=Math.round(document.getElementById('crisisCtrl').getBoundingClientRect().height);
    const prefAv=currentReadMode();
    document.getElementById('allBtn').click(); await wt(600);
    const segRetour=document.querySelector('#allBtn .dp-lbl').textContent.trim();
    const xAp=Math.round(document.getElementById('allBtn').getBoundingClientRect().left);
    const hAp=Math.round(document.getElementById('crisisCtrl').getBoundingClientRect().height);
    const prefAp=currentReadMode();
    const ong=[...document.querySelectorAll('.at-b')].map(e=>e.textContent.trim());
    const defaut=(document.querySelector('.at-b.on')||{}).textContent||'';
    const pageOk=!!document.querySelector('.sv-tb');
    const tabs=document.querySelector('.all-tabs');
    const debord=tabs?Math.round(tabs.scrollWidth-tabs.clientWidth):null;
    const cible=Math.min(...[...document.querySelectorAll('.at-b')].map(e=>e.getBoundingClientRect().height));
    document.querySelector('[data-alltab="parcours"]').click(); await wt(400);
    /* v5.0.0 (M9) : « Parcours » N'EST PLUS l'Échelle — c'est la fiche entière en CARTES de
       blocs, avec leurs items, et INERTE. Le contrôle mesure les trois : la présence des cartes,
       la présence des items, et l'impossibilité de cocher (aucun `data-ck` émis, `state.checked`
       inchangé après un clic sur une case). Sans la troisième, on validerait une vue qui
       RESSEMBLE à la fiche et qui la MODIFIERAIT. */
    const avCk=JSON.stringify(state.checked);
    {const b0=document.querySelector('.pc-box');if(b0)b0.click();}
    await wt(250);
    const parc=!!document.querySelector('.pc-wrap')&&!document.querySelector('.sv-tb')
      &&document.querySelectorAll('.pc-card').length>=2
      &&document.querySelectorAll('.pc-it').length>=2
      &&document.querySelectorAll('.pc-wrap [data-ck]').length===0
      &&JSON.stringify(state.checked)===avCk;
    document.querySelector('[data-alltab="schema"]').click(); await wt(600);
    const zAv=(document.querySelector('.all-svg .fzv')||{}).textContent||'';
    const zb=document.querySelector('.all-svg [data-zoom="in"]'); if(zb)zb.click(); await wt(300);
    const zAp=(document.querySelector('.all-svg .fzv')||{}).textContent||'';
    const peint=!!document.querySelector('.all-svg svg .fn-cur, .all-svg svg .fn-ok');
    const navAv=(state.nav||[]).length;
    const coche=Object.keys(state.checked||{}).filter(k=>state.checked[k]).length;
    const nd=document.querySelector('.all-svg svg [data-fgo]'); if(nd)nd.dispatchEvent(new MouseEvent('click',{bubbles:true})); await wt(300);
    /* ── LOT B : la recherche, mesurée sur l'onglet Page puis rejouée sur Parcours ── */
    document.querySelector('[data-alltab="page"]').click(); await wt(500);
    const avantHtml=document.querySelector('.sv-tb').innerHTML;
    {const q=document.getElementById('pfQ');q.value='adrénaline';q.dispatchEvent(new Event('input',{bubbles:true}));}
    await wt(400);
    const hits=document.querySelectorAll('.sv-tb mark.pf-h').length;
    const cpt=(document.getElementById('pfCount')||{}).textContent||'';
    const cache=[...document.querySelectorAll('.sv-tb .sv-cell')].filter(e=>getComputedStyle(e).display==='none').length;
    const qEl=document.getElementById('pfQ');
    const champH=Math.round(qEl.getBoundingClientRect().height),champFs=getComputedStyle(qEl).fontSize;
    const fleches=[...document.querySelectorAll('.rt-find-all .rt-fnav .mini')]
      .map(b=>Math.round(Math.min(b.getBoundingClientRect().width,b.getBoundingClientRect().height)));
    document.querySelector('[data-alltab="parcours"]').click(); await wt(600);
    const hitsParcours=document.querySelectorAll('.pc-wrap mark.pf-h').length;
    document.querySelector('[data-alltab="schema"]').click(); await wt(600);
    const champSchema=!!document.getElementById('pfQ'),marksSchema=document.querySelectorAll('mark.pf-h').length;
    document.querySelector('[data-alltab="page"]').click(); await wt(600);
    {const q=document.getElementById('pfQ');q.value='';q.dispatchEvent(new Event('input',{bubbles:true}));}
    await wt(350);
    const identique=document.querySelector('.sv-tb').innerHTML===avantHtml;
    /* ── Le registre du bouton, dans les DEUX préférences ── */
    const vert=()=>document.getElementById('allBtn').classList.contains('dp-back');
    document.getElementById('allBtn').click(); await wt(500);      // retour « chez soi »
    const vertRepos=vert();
    document.getElementById('allBtn').click(); await wt(500);
    const vertLoin=vert();
    document.getElementById('allBtn').click(); await wt(500);
    setReadModePref('static'); openRead(f.id); await wt(500);
    {const b2=document.getElementById('sessStart'); if(b2)b2.click(); await wt(500);}
    const vertReposStatic=vert();
    document.getElementById('allBtn').click(); await wt(500);
    const vertLoinStatic=vert();
    setReadModePref('overview');
    return {seg,segRetour,xAv,xAp,hAv,hAp,prefAv,prefAp,planBtn,ong,defaut,pageOk,debord,cible,parc,zAv,zAp,peint,
            hits,cpt,cache,hitsParcours,champSchema,marksSchema,identique,champH,champFs,fleches,
            vertRepos,vertLoin,vertReposStatic,vertLoinStatic,
            navBouge:(state.nav||[]).length!==navAv,
            cocheApres:Object.keys(state.checked||{}).filter(k=>state.checked[k]).length,cocheAvant:coche};});
  /* ⚠ PRENDRE DU RECUL EST UNE EXCURSION, PAS UN CHANGEMENT DE FORMAT (lot A, v5.0.0 — retour
     d'usage : on bascule EN COURS de session pour trouver une information, et l'ancien sélecteur
     segmenté ne ramenait personne). Trois propriétés, et il faut les trois : le contrôle nomme sa
     DESTINATION, il ne BOUGE PAS d'un pixel (ni lui ni la rangée), et l'excursion n'écrit PAS la
     préférence — regarder n'est pas régler. */
  t(`${w} · le contrôle nomme sa DESTINATION, à l'aller comme au retour`,
    r.seg[0]==='Tout voir'&&r.segRetour==='Un bloc', `${r.seg[0]} → ${r.segRetour}`);
  t(`${w} · … et il ne bouge pas d'un pixel (ni lui, ni la rangée)`,
    r.xAv===r.xAp&&r.hAv===r.hAp, `x ${r.xAv}→${r.xAp}, rangée ${r.hAv}→${r.hAp}`);
  t(`${w} · … et l'excursion n'écrit pas la préférence`,
    r.prefAv===r.prefAp, `${r.prefAv} → ${r.prefAp}`);
  /* ⚠ LE VERT NE DIT QU'UNE CHOSE : « vous êtes loin de chez vous » (signalé à l'usage). Au REPOS,
     dans SON format d'ouverture, l'utilisateur ne doit voir aucun registre CONFIRMATION — sinon
     c'est l'inflation qui vide le vert de son sens. Symétrique : on le vérifie dans les deux
     préférences, sans quoi le témoin ne rencontrerait que la moitié de son cas. */
  t(`${w} · au repos, aucun registre CONFIRMATION`,
    r.vertRepos===false&&r.vertLoin===true, `repos=${r.vertRepos} loin=${r.vertLoin}`);
  t(`${w} · … y compris quand « toute la fiche » EST le format d'ouverture`,
    r.vertReposStatic===false&&r.vertLoinStatic===true,
    `repos=${r.vertReposStatic} loin=${r.vertLoinStatic}`);
  /* LOT B — CHERCHER DANS L'AIDE : elle SURLIGNE et SAUTE, elle ne filtre pas ; elle ne touche
     jamais au balisage (le document revient à l'identique) ; et elle n'existe pas sur le SCHÉMA,
     où un `<mark>` n'est pas un nœud valide. */
  t(`${w} · on peut CHERCHER dans l'aide entière`,
    r.hits>0&&/\d+ \/ \d+/.test(r.cpt||''), `${r.hits} occurrence(s), compteur « ${r.cpt} »`);
  t(`${w} · … elle surligne et saute, elle ne FILTRE pas`, r.cache===0, `${r.cache} cellule(s) masquée(s)`);
  t(`${w} · … la requête suit l'onglet`, r.hitsParcours>0, `${r.hitsParcours} occurrence(s) en Parcours`);
  t(`${w} · … pas de champ sur le SCHÉMA (le SVG n'accepte pas de mark)`,
    r.champSchema===false&&r.marksSchema===0, `champ=${r.champSchema} marques=${r.marksSchema}`);
  t(`${w} · … et effacer rend le document IDENTIQUE`, r.identique===true, String(r.identique));
  t(`${w} · … avec des cibles de 44 px et un champ à 16 px`,
    r.champH>=44&&r.champFs==='16px'&&r.fleches.every(v=>v>=44),
    `champ ${r.champH} px / ${r.champFs}, flèches ${JSON.stringify(r.fleches)}`);
  t(`${w} · « Se repérer » a quitté la rangée de commandes`, r.planBtn===false);
  t(`${w} · trois façons de regarder l'aide entière`,
    r.ong.join('|')==='Parcours|Page SFAR|Schéma', r.ong.join('|'));
  /* LA PAGE RESTE LE DÉFAUT : un lot qui AJOUTE deux vues n'a pas à changer par surprise ce que
     voit celui qui n'a rien demandé. */
  t(`${w} · … et la Page reste ce qu'on voit d'abord`, r.defaut==='Page SFAR'&&r.pageOk, r.defaut);
  t(`${w} · les onglets ne débordent pas`, r.debord!==null&&r.debord<=1, `${r.debord} px`);
  t(`${w} · … et restent des cibles de 44 px`, r.cible>=44, `${r.cible} px`);
  t(`${w} · « Parcours » montre la fiche en CARTES de blocs, et reste inerte`, r.parc===true);
  t(`${w} · le SCHÉMA garde son zoom (il n'est pas une image)`, r.zAv!==r.zAp, `${r.zAv} → ${r.zAp}`);
  t(`${w} · … et son état de session PEINT`, r.peint===true);
  /* NAVIGUER ≠ AGIR : taper un nœud y va, il ne coche RIEN. Invariant v4.7.0, qu'un changement de
     logement ne doit pas altérer. */
  t(`${w} · taper un nœud NAVIGUE et ne coche rien`,
    r.cocheApres===r.cocheAvant, `${r.cocheAvant} → ${r.cocheApres}`);
  await page.close();
}

/* LOT T9 / R4 — LA BIBLIOTHÈQUE EST UNIQUE, LE TYPE EST UN FILTRE.
   LE CAS DOIT EXISTER AVANT D'ÊTRE MESURÉ : le jeu d'exemple ne contient AUCUN protocole, si bien
   que « Tout » et « Aides » y donnent le même compte — un contrôle écrit sans cette précaution
   passerait au vert sans avoir rien vérifié (leçon v4.55.3, redite au lot T4). On en crée un. */
console.log('\n══ T9 · une seule bibliothèque, le type en filtre ══');
{
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const pr=blankProtocol();pr.title='Procédure de décontamination';
    protocols.push(migrateProtocol(pr));await persist();render();await w(600);
    const n=()=>document.querySelectorAll('.dir-row').length;
    /* v5.0.0, lot M4 : le type n'est plus une TAB BAR à pastille glissante mais une rangée de
       CHIPS, comme la bibliothèque et la catégorie — il est devenu un filtre parmi les filtres.
       Ce qui se mesure change donc de FORME mais pas de FOND : trois crans, « Tout » par défaut,
       chaque cran filtre ce qu'il annonce. La position de pastille est remplacée par l'état `on`,
       qui est le canal réel de la sélection sur une chip. */
    /* ⚠ LES FILTRES SE REPLIENT AU REPOS depuis la v5.0.0 (audit design A3-1/A5-3) : tant
       qu'aucun n'est posé, les trois rangées vivent derrière un déclencheur unique « Filtrer ».
       Ce témoin mesure ce que font les CRANS, pas leur présence au repos — il déplie donc par le
       VRAI geste, comme l'utilisateur. Sans cela il cliquait sur `null` et emportait la passe.
       Le repli lui-même a ses propres témoins, juste en dessous. */
    const deplier=async()=>{const b=document.querySelector('[data-filttog]');if(b){b.click();await w(450);}};
    await deplier();
    const px=()=>{const e=document.querySelector('.typebar [data-section].on');return e?(e.dataset.section||null):null;};
    const crans=[...document.querySelectorAll('.typebar [data-section]')].map(e=>e.textContent.trim());
    const actif=(document.querySelector('.typebar [data-section].on')||{}).textContent||'';
    const tout=n(),pTout=px();
    document.querySelector('.typebar [data-section="fiches"]').click(); await w(500);
    const aides=n(),pAides=px();
    document.querySelector('.typebar [data-section="protocols"]').click(); await w(500);
    const prot=n(),pProt=px();
    document.querySelector('.typebar [data-section="all"]').click(); await w(500);
    await deplier();   // « Tout » = aucun filtre actif : la rangée s'est repliée, on la rouvre
    state.q='décontamination';render();await w(500);
    const q=n();state.q='';render();await w(400);
    return {crans,actif,tout,aides,prot,q,pTout,pAides,pProt,nF:fiches.length,nP:protocols.length,
      tabbar:document.querySelectorAll('#tabBar,#tabSeg').length};});
  t('le type est un FILTRE à trois crans', r.crans.join('|')==='Tout|Aides|Protocoles', r.crans.join('|'));
  /* « Tout » est le DÉFAUT : chercher un SUJET ne doit pas exiger de savoir d'abord de quel TYPE
     il est — c'est toute la thèse de R4. */
  t('… et « Tout » est ce qu\'on voit en arrivant', /Tout/.test(r.actif), r.actif);
  t('témoin : le cas est bien constitué (aides ET protocoles)', r.nF>=1&&r.nP>=1, `${r.nF} + ${r.nP}`);
  t('« Tout » réunit les deux types', r.tout===r.nF+r.nP, `${r.tout} pour ${r.nF}+${r.nP}`);
  t('« Aides » ne montre que les aides', r.aides===r.nF, `${r.aides}`);
  t('« Protocoles » ne montre que les protocoles', r.prot===r.nP, `${r.prot}`);
  t('la recherche traverse les deux types depuis « Tout »', r.q===1, `${r.q} résultat(s)`);
  /* L'état sélectionné doit SUIVRE le cran choisi : une chip qui filtre sans se marquer laisse
     croire que le filtre n'a pas pris — et sur trois crans on ne peut plus le déduire du reste. */
  t('la chip active suit bien les trois crans',
    r.pTout==='all'&&r.pAides==='fiches'&&r.pProt==='protocols', `${r.pTout} · ${r.pAides} · ${r.pProt}`);
  /* M4 : la barre fixe du bas a disparu — 62 px rendus à l'accueil. Un reste d'émission ferait
     coexister deux commandes pour un même filtre (règle 14). */
  t('la tab bar basse est PURGÉE (aucune émission)', r.tabbar===0, `${r.tabbar} nœud(s)`);
  await page.close();
}

/* AUDIT DESIGN A3-1 / A5-3 — LE REPLI DES FILTRES, ET SURTOUT SA CONTREPARTIE.
   Le gain est réel (~90 px au premier écran, mesuré ci-dessous), mais le RISQUE l'est aussi, et
   c'est lui qu'il faut garder : un filtre POSÉ qui se cacherait serait bien pire que trois
   rangées permanentes — on chercherait une aide dans un corpus restreint sans savoir pourquoi
   elle n'apparaît pas, ce qui est le pire mode de défaillance d'une bibliothèque de crise.
   D'où la règle constante du dossier, mesurée ici : UN ÉTAT ACTIF NE SE CACHE JAMAIS. */
/* AUDIT DESIGN A3-1 — UN TITRE LONG NE DÉBORDE JAMAIS DE SA BOÎTE.
   Le lot a monté le titre de la rangée de répertoire de 15,5 à 16,5 px dans une boîte de hauteur
   FIXE (71 px). Un palier de plus sur un contenu à hauteur bornée est exactement le genre de
   changement qui rogne en silence : `.dir-sub` est en `overflow:hidden`, donc la rangée resterait
   PROPRE pendant que la date disparaît. C'est le défaut déjà vécu sur la méta (v5.0.0) et sur les
   deux rognages « que personne ne mesurait » (v4.55.3).
   ⚠ ON CONSTRUIT UN CAS ADVERSE : mesurer les fiches d'exemple ne prouverait rien, leurs titres
   tenant sur une ligne. C'est la leçon la plus redite de ce dossier — un contrôle qui ne rencontre
   pas son cas ne le couvre pas. On mesure aussi la TUILE, dont la hauteur est FLUIDE et qui
   entraîne toute sa rangée de grille : c'est par elle que le coût s'était réintroduit. */
console.log('\n══ Audit design · titres longs, boîtes bornées ══');
for (const [w,zm] of [[320,100],[390,100],[430,100],[1100,100],[1600,100],[390,130],[1246,130],[1600,130]]) {
  const page = await br.newPage({viewport:{width:w,height:900},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async(zm)=>{const wt=m=>new Promise(r=>setTimeout(r,m));
    const LONG='Anaphylaxie (choc anaphylactique avec un titre vraiment très long)';
    applyZoom(zm);
    fiches[0].title=LONG; if(fiches[1])fiches[1].title='ACR';
    togglePin(fiches[0].id); if(fiches[1])togglePin(fiches[1].id);
    await persist(); render(); await wt(700);
    /* ⚠ RÈGLE 10 : sous zoom, getBoundingClientRect rend des px VISUELS (× zoom) alors que les
       styles sont en px CSS. Toute mesure réinjectée se divise par --zf, sans quoi on lit 92 px
       là où la boîte en fait 71 et l'on conclut à un débordement qui n'existe pas — piège tombé
       en écrivant ce contrôle. */
    const Z=parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--zf'))||1;
    const scan=(selBox,selT)=>[...document.querySelectorAll(selBox)].map(b=>{
      const t=b.querySelector(selT); if(!t)return null;
      const bb=b.getBoundingClientRect(), tr=t.getBoundingClientRect();
      const bas=[...b.children].map(c=>c.getBoundingClientRect().bottom)
        .reduce((a,c)=>Math.max(a,c),tr.bottom);
      const pb=parseFloat(getComputedStyle(b).paddingBottom)||0;
      const lh=parseFloat(getComputedStyle(t).lineHeight)||1;
      return {debord:Math.round((bas-(bb.bottom-pb))/Z), clip:b.scrollHeight-b.clientHeight,
              h:Math.round(bb.height/Z), lignes:+((tr.height/Z)/lh).toFixed(2),
              long:t.textContent.trim().length>40};}).filter(Boolean);
    /* ⚠ ON MESURE LE <span> DU TITRE, PAS LE <button> : celui-ci porte un rembourrage compensé
       et une line-height 'normal' — y compter des lignes rend un chiffre qui ne veut rien dire
       (piège tombé en écrivant ce contrôle : 46 px / 1 = « 46 lignes »). */
    const rows=scan('.dir-row','.dir-t'), tiles=scan('.qa-tile','.qa-t');
    return {rows,tiles,
      casRow:rows.some(x=>x.long), casTile:tiles.some(x=>x.long),
      pireRow:Math.max(0,...rows.map(x=>x.debord)), clipRow:Math.max(0,...rows.map(x=>x.clip)),
      pireTile:Math.max(0,...tiles.map(x=>x.debord)), clipTile:Math.max(0,...tiles.map(x=>x.clip)),
      hTile:Math.max(0,...tiles.map(x=>x.h)),
      lignesRow:Math.max(0,...rows.map(x=>x.lignes))};},zm);
  t(`${w}/z${zm} · témoin : le cas adverse est constitué (titre long rendu)`,
    r.casRow===true&&r.casTile===true, `rangée ${r.casRow}, tuile ${r.casTile}`);
  t(`${w}/z${zm} · la rangée de répertoire ne déborde pas`, r.pireRow<=0, `${r.pireRow} px`);
  /* Le débordement ne suffit pas : `.dir-sub` est en overflow:hidden, donc la boîte reste propre
     pendant que la donnée disparaît. On mesure AUSSI le rognage réel. */
  /* TOLÉRANCE D'UN PIXEL, ET ELLE EST MOTIVÉE : `scrollHeight`/`clientHeight` sont des ENTIERS,
     alors que la rangée mesure 70,9976 px CSS sous zoom 130 %. WebKit rapporte alors 1 px d'écart
     là où rien n'est perdu — vérifié par la mesure qui compte vraiment : la méta finit 6,5 px À
     L'INTÉRIEUR de la boîte, et le titre tient en deux lignes. Chromium rapporte 0.
     ⚠ La tolérance ne vaut QUE pour ce contrôle d'arrondi : `debord` et « deux lignes » restent
     STRICTS, et ce sont eux qui portent le sens. Un vrai rognage se compte en dizaines de px
     (le défaut d'origine en produisait un de 19). */
  t(`${w}/z${zm} · … et ne rogne rien`, r.clipRow<=1, `${r.clipRow} px rognés`);
  /* LE VRAI INVARIANT, et celui qui manquait : le titre tient en DEUX lignes. Le clamp hérité
     est inerte dès que le display calculé n'est pas `-webkit-box` — c'est ce qui, à 130 %, faisait
     passer un titre réel à trois lignes et poussait la méta hors du cadre (signalé à l'usage). */
  t(`${w}/z${zm} · le titre tient en deux lignes`, r.lignesRow<=2.05, `${r.lignesRow} ligne(s)`);
  t(`${w}/z${zm} · la tuile ne déborde pas`, r.pireTile<=0, `${r.pireTile} px`);
  t(`${w}/z${zm} · … et ne rogne rien`, r.clipTile<=0, `${r.clipTile} px rognés`);
  /* PLAFOND DE CROISSANCE : la tuile est fluide et tire sa rangée de grille avec elle. À 15,5 px
     un titre de trois lignes la porte à ~103 px ; au-delà de 115 on aurait remplacé le gain de
     l'audit par une dépense au même endroit. */
  t(`${w}/z${zm} · … et sa croissance reste bornée`, r.hTile<=105, `${r.hTile} px`);
  await page.close();
}

console.log('\n══ Audit design · le repli des filtres ══');
{
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const rangees=()=>document.querySelectorAll('.typebar,.scopebar,.catbar').length;
    const tog=()=>document.querySelector('[data-filttog]');
    /* Le premier contenu CLINIQUE, c'est-à-dire le point que tout ce lot cherche à remonter. */
    const yPremier=()=>{const e=document.querySelector('.dir-row .card-open');
      return e?Math.round(e.getBoundingClientRect().top):null;};
    await w(400);
    const repliRangees=rangees(), repliTog=!!tog(), yRepli=yPremier();
    tog().click(); await w(500);
    const ouvRangees=rangees(), ouvTog=!!tog(), yOuvert=yPremier();
    /* On pose un filtre : à partir de là, le repli doit devenir IMPOSSIBLE. */
    document.querySelector('.typebar [data-section="fiches"]').click(); await w(500);
    const actifRangees=rangees(), actifTog=!!tog();
    const chipOn=!!document.querySelector('.typebar [data-section="fiches"].on');
    /* Et il doit le rester après un re-rendu complet, pas seulement juste après le clic. */
    render(); await w(500);
    const apresRender=rangees(), apresTog=!!tog();
    document.querySelector('.typebar [data-section="all"]').click(); await w(500);
    return {repliRangees,repliTog,yRepli,ouvRangees,ouvTog,yOuvert,
            actifRangees,actifTog,chipOn,apresRender,apresTog};});

  /* TÉMOIN D'ABORD : sans rangées à déplier, tout ce qui suit mesurerait le vide.
     ⚠ LE COMPTE DÉPEND DE L'ÉTAT DU COMPTE, et l'attendre à 3 était une erreur de la SONDE :
     `.scopebar` n'est émise que CONNECTÉ (`Auth.signedIn()`), donc une session déconnectée —
     celle de ce harnais — en porte DEUX (type, catégorie). On mesure donc l'INVARIANCE du
     nombre entre « déplié » et « filtre actif », qui est la propriété qui compte, plutôt qu'un
     chiffre en dur qui ne vaudrait que pour un état de connexion. */
  t('témoin : le cas est constitué (des rangées existent une fois dépliées)',
    r.ouvRangees>=2, `${r.ouvRangees} rangée(s)`);
  t('au repos, les filtres sont repliés derrière UN déclencheur',
    r.repliRangees===0&&r.repliTog===true, `${r.repliRangees} rangée(s), déclencheur ${r.repliTog}`);
  t('le déclencheur les ouvre', r.ouvRangees>=2&&r.ouvTog===true, `${r.ouvRangees} rangée(s)`);
  /* LE GAIN, MESURÉ — et on ne l'affirme pas, on le compare. */
  t('… et le repli remonte bien le premier contenu clinique',
    r.yRepli!==null&&r.yOuvert!==null&&(r.yOuvert-r.yRepli)>=40,
    `${r.yRepli} px replié contre ${r.yOuvert} px déplié (${r.yOuvert-r.yRepli} px rendus)`);
  /* LA CONTREPARTIE, ET C'EST LA GARANTIE QUI COMPTE. */
  t('⚠ un filtre ACTIF n\'est jamais masqué', r.actifRangees===r.ouvRangees&&r.chipOn===true,
    `${r.actifRangees} rangée(s) pour ${r.ouvRangees} dépliées, chip active ${r.chipOn}`);
  t('… et le déclencheur DISPARAÎT alors (aucun bouton mort)', r.actifTog===false);
  t('… et cela survit à un re-rendu complet', r.apresRender===r.ouvRangees&&r.apresTog===false,
    `${r.apresRender} rangée(s), déclencheur ${r.apresTog}`);
  await page.close();
}

/* LOT T7 — ★ MÉMOIRE, DE BOUT EN BOUT. Le contrôle unitaire mesure le CALCUL ; celui-ci mesure
   le CHEMIN RÉEL — poser l'étoile dans l'éditeur, revenir en lecture, la voir dans le chapeau.
   C'est ce chemin qui a révélé un défaut ANTÉRIEUR : `openRead` conservait un Runtime déjà
   construit SANS re-pointer sa fiche, si bien qu'après une édition la lecture affichait l'objet
   d'avant (`edCommit` REMPLACE l'entrée de `fiches` par sa copie normalisée). Un contrôle qui se
   serait arrêté au calcul ne l'aurait jamais vu. */
console.log('\n══ T7 · ★ mémoire — de l\'éditeur au chapeau ══');
{
  const page = await br.newPage({viewport:{width:390,height:900},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const f=fiches.find(x=>/Anaphylaxie/i.test(x.title))||fiches[0];
    openRead(f.id); await w(500);
    const avant=document.querySelectorAll('.forget-strip .fs-i').length;
    openEdit(f.id); await w(700);
    const btn=document.querySelector('.blk .li[data-si="1"] [data-mem]');
    /* v5.0.0, étape B : le bloc ne porte que des IDENTIFIANTS — on passe par le résolveur, qui
       est aussi ce que fait l'éditeur. */
    const txt=bItems(state.draft.blocks[0])[1].do;
    if(btn)btn.click(); await w(700);
    const pose=bItems(state.draft.blocks[0])[1].memory===true;
    render(); await w(400);
    openRead(f.id); await w(700);
    const chap=[...document.querySelectorAll('.forget-strip .fs-i')].map(e=>e.textContent);
    const bloc=[...document.querySelectorAll('ol.steps li')].map(e=>e.textContent);
    return {avant,pose,apres:chap.length,dansChapeau:chap.some(x=>x.includes(txt)),
            resteDansBloc:bloc.some(x=>x.includes(txt)),
            frais:state.fiche===fiches.find(x=>x.id===f.id)};});
  t('l\'étoile se pose dans l\'éditeur', r.pose===true);
  t('témoin : le chapeau avait bien un contenu avant', r.avant>=1, `${r.avant}`);
  t('… et le chapeau en compte UNE de plus au retour', r.apres===r.avant+1, `${r.avant} → ${r.apres}`);
  t('… c\'est bien le texte de l\'étape étoilée', r.dansChapeau===true);
  /* LA DOCTRINE QRH : il se récite AVANT, puis se re-vérifie À SA PLACE. */
  t('… et l\'étape RESTE dans son bloc', r.resteDansBloc===true);
  /* Le défaut antérieur, verrouillé : rouvrir une fiche éditée doit rendre l'objet À JOUR. */
  t('rouvrir une fiche éditée donne l\'objet À JOUR (pas celui d\'avant)', r.frais===true);
  await page.close();
}

/* LOT T13 — LES DEUX FICHES D'EXEMPLE SONT LE SEUL MATÉRIEL PÉDAGOGIQUE, donc ce qu'elles
   n'exercent pas n'existe pas pour un nouveau venu. Le constat 3 de l'audit J0 les mesurait à un
   TIERS des mécanismes du produit : zéro posologie, zéro complication, aucun `discriminant`,
   aucun `onDue`, et le registre AMBRE présent UNE seule fois dans tout le produit.
   ON MESURE LES MÉCANISMES, PAS LE TEXTE : un contrôle sur les libellés casserait à la première
   relecture clinique, alors que ce qui compte est qu'un J0 RENCONTRE chaque dispositif. */
console.log('\n══ T13 · les fiches d\'exemple exercent la doctrine qu\'elles enseignent ══');
{
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html?__actest`);
  await page.waitForFunction(()=>!!window.__ac_test__);
  const r = await page.evaluate(()=>{
    const A=window.__ac_test__;
    const bilan=f=>{const its=(f.blocks||[]).flatMap(b=>A.bItems(b));
      return {disc:f.discriminant,code:f.code,
        vigil:its.filter(i=>i.level===2).length, crit:its.filter(i=>i.level===3).length,
        mem:its.filter(i=>i.memory).length, dual:its.filter(i=>i.dual).length,
        poso:A.listOf(f,'posology').length, cx:(f.excursions||[]).length,
        onDue:(f.timers||[]).filter(t=>t.onDue).length,
        vigilTot:its.filter(i=>i.level===2).length,
        cxCible:(f.excursions||[]).every(c=>(f.blocks||[]).some(b=>b.id===c.target)),
        cxHorsChaine:(f.excursions||[]).every(c=>!(f.blocks||[]).some(b=>b.next===c.target
          ||(b.options||[]).some(o=>o.target===c.target))),
        chapeau:A.forgetAll(f).length};};
    return {a:bilan(seed('')),b:bilan(seed2(''))};});
  for (const [nom,x] of [['Anaphylaxie',r.a],['ACR',r.b]]) {
    t(`${nom} · porte un discriminant et un code`, !!x.disc && !!x.code, `${x.disc} / ${x.code}`);
    t(`${nom} · exerce le registre AMBRE`, x.vigil>=1, `${x.vigil} étape(s) △`);
    t(`${nom} · … et le registre ROUGE, sans le noyer`, x.crit>=1 && x.crit<=3, `${x.crit} étape(s) ⚠`);
    t(`${nom} · porte des repères posologiques`, x.poso>=1, `${x.poso}`);
    t(`${nom} · son minuteur DIT quoi faire à l'échéance (onDue)`, x.onDue>=1, `${x.onDue}`);
    t(`${nom} · exerce ★ mémoire`, x.mem===1, `${x.mem} (une seule : s'il y en avait partout, elle ne dirait rien)`);
    /* Le chapeau agrège notForget ET les étoiles : il doit rester sous le plafond doctrinal de 4. */
    t(`${nom} · … sans faire déborder le chapeau (≤ 4 rappels)`, x.chapeau<=4, `${x.chapeau}`);
  }
  t(`Anaphylaxie · exerce ×2 (double confirmation)`, r.a.dual===1, `${r.a.dual}`);
  t(`Anaphylaxie · exerce une complication « à tout moment »`, r.a.cx===1, `${r.a.cx}`);
  t(`… dont la cible existe`, r.a.cxCible===true);
  /* L'invariant de la doctrine : un bloc d'excursion est HORS chaîne — aucun `next`, aucune
     option n'y mène — sinon il prendrait un numéro de tronc et se lirait « l'étape d'après ». */
  t(`… et vit HORS de la chaîne (aucun next n'y mène)`, r.a.cxHorsChaine===true);
  await page.close();
}

/* LOT T13 — J0-D6 : LE MESSAGE DES EXEMPLES N'EST PAS UNE SNACKBAR. Mesuré à l'audit J0, elle
   recouvrait 60,7 % du bouton d'action primaire à l'instant où un nouveau venu venait de le
   presser. Une snackbar accuse un geste ; ceci AVERTIT, et doit tenir. */
{
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  const r = await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    /* PAS `amorce()` ici, à dessein : cette sonde MESURE le trajet d'accueil lui-même (nombre de
       paragraphes, position du CTA, bandeau) — l'amorçage est son SUJET, pas sa mise en condition. */
    const m=document.getElementById('welcomeModal');
    const paras=m.querySelectorAll('p').length;
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));
    if(b)b.click(); await w(300);
    const cta=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));
    const av=cta?cta.getBoundingClientRect():null;
    if(cta)cta.click(); await w(900);
    const ban=document.getElementById('sysBanner');
    const rec=(()=>{if(!ban||ban.hidden||!av)return 0;const r2=ban.getBoundingClientRect();
      return Math.round(Math.max(0,Math.min(r2.bottom,av.bottom)-Math.max(r2.top,av.top))/av.height*100);})();
    return {paras,bandeau:!!ban&&!ban.hidden,toasts:document.querySelectorAll('.toast').length,rec};});
  t(`l'écran de bienvenue ne fait plus le tour du produit (≤ 2 paragraphes)`, r.paras<=2, `${r.paras}`);
  t(`les exemples s'annoncent par le BANDEAU, pas par une snackbar`, r.bandeau===true && r.toasts===0,
    `bandeau=${r.bandeau}, snackbars=${r.toasts}`);
  t(`… et il ne recouvre plus le bouton d'action (0 %)`, r.rec===0, `${r.rec} %`);
  await page.close();
}

/* `aidRev` — LA RÉVISION LUE PENDANT LE SOIN (v5.0.0). La spécification v4 écrit « aidRev + texts
   réparent le défaut mesuré » ; le lot T1 n'avait livré que `texts`. Le témoin mesure les deux
   propriétés qui comptent : la révision est celle qui était SOUS LES YEUX au démarrage, et une
   édition ULTÉRIEURE ne la réécrit pas — sinon le compte rendu nommerait la version d'après. */
/* LE QUAI NE DÉTRUIT PLUS SON DOM À CHAQUE TICK (v5.0.0, question puis mesure).
   POURQUOI C'EST UN INVARIANT ET PAS UNE OPTIMISATION : la doctrine interdit de loger un contrôle
   dans le quai parce qu'un tap y était avalé — et la cause était ici, pas ailleurs. La chaîne
   comparée à `_rtsHtml` contenait les TEMPS, donc changeait à chaque seconde, donc `innerHTML`
   était réécrit et TOUT le sous-arbre remplacé : entre le `pointerdown` et le `click`, le nœud
   sous le doigt n'existait plus. Mesuré avant : 36 éléments détruits en 6 s, 0 survivant sur 8.
   Si un futur correctif remet une valeur dans la chaîne de structure, ce témoin doit crier. */
/* LA PASTILLE DU PARCOURS INERTE DOIT ÊTRE LISIBLE (v5.0.0, défaut mesuré puis corrigé).
   Elle est `aria-hidden` — donc HORS du champ d'`audit-a11y`, qui mesure le texte accessible — et
   c'est exactement pour cela qu'un numéro BLEU SUR BLEU a pu vivre sans que rien ne crie : un
   reste du dessin PLAT (`.rail-lad .pl-line.cur .n{color:var(--link)}`) peignait l'encre de la
   couleur du fond que la nouvelle pastille pleine venait de poser. Un défaut hors scope n'est pas
   un défaut absent (leçon v4.75.0) : on lui donne un scope.
   On ne mesure PAS un seuil WCAG ici (le glyphe n'est pas du texte au sens de la norme) — on
   mesure qu'il est DISTINCT de son propre fond, ce qui est la seule chose qui ait un sens pour
   un marqueur, et la seule que le défaut violait. */
/* LES DÉPLIANTS APPARTIENNENT À LEUR GESTE (v5.0.0, lot M11 — mesuré, puis corrigé).
   La règle 11 interdit le DÉFILEMENT AUTOMATIQUE en session : l'écran ne bouge que sous le doigt
   de celui qui le fait bouger. Deux gestes l'enfreignaient, et les deux étaient invisibles à la
   relecture parce que le code disait simplement « scrollIntoView » :
     · taper le QUAI ouvrait le panneau minuteurs, qui vit en bas de colonne depuis le lot T5, et
       s'y rendait — mesuré 1120 px de saut à 320 px, soit plus d'un écran et demi, en pleine
       réanimation, en perdant de vue le bloc qu'on exécutait ;
     · « Journal des actions (n) ▾ » de l'accusé de réception y allait aussi — 484 px.
   Le « ▾ » de la maquette dit un DÉPLIANT, pas une navigation. Le panneau ouvert PAR LE QUAI se
   rend donc juste SOUS le quai, et le journal se déplie DANS la carte. On mesure le SAUT, pas la
   présence du panneau : un panneau présent 1120 px plus bas est un panneau qu'on a perdu. */
/* TROIS RÉGRESSIONS SILENCIEUSES, ET ELLES SE RESSEMBLENT (v5.0.0, signalées à l'usage).
   Deux d'entre elles sont la MÊME faute : après une migration de modèle ou un déplacement de
   balisage, un test qui ne correspond plus ne lève AUCUNE erreur — il rend faux, et se tait.
     · `buildFlowSVG` comparait `kind` à `'steps'`, valeur disparue à l'étape C (`kind:'do'`) :
       tout bloc non-décision retombait dans la branche « décision », `options` valait [], et
       AUCUNE flèche n'était tracée pour les liens `next`. Les branches d'une décision, elles,
       continuaient de s'afficher — d'où un symptôme partiel, donc déroutant.
     · le binder des interstices tournait PAR CARTE (`.blk`), alors que les interstices de niveau
       BLOC sont émis ENTRE les cartes : le dépôt d'un bloc tombait dans le vide, tandis que le
       dépôt d'une ÉTAPE (interstice interne à la carte) fonctionnait.
   La troisième est géométrique : un élément TOURNÉ déborde sa boîte (26 px de côté font 36,8 px
   de diagonale), et la colonne le rognait. */
/* LA RANGÉE DE RÉPERTOIRE A UNE HAUTEUR IDENTIQUE D'UNE FICHE À L'AUTRE (v5.0.0, V2).
   C'ÉTAIT LE DÉFAUT RÉEL, et il n'était pas de style : la sous-ligne était une rangée
   `flex-wrap` de six à sept pilules de largeurs quelconques, donc chaque fiche se repliait
   différemment (52 à 86 px mesurés) et l'annuaire n'avait aucun rythme. Un contrôle qui
   mesurerait « la rangée fait 71 px » resterait vert sur une liste d'une seule fiche : on mesure
   donc que TOUTES les rangées ont la MÊME hauteur, et l'on vérifie d'abord qu'il y en a plusieurs.
   ⚠ ET LE CORPS RESTE SUR L'ÉCHELLE FERMÉE : c'est la contrainte qui a fait échouer deux
   maquettes (15 px et 14,5 px, aucun n'étant un palier). Ce qui se resserre pour tenir en 71 px
   est l'interligne, jamais la police. */
/* ⚠ LES LARGEURS MESURÉES SONT CELLES DES PISTES, PAS DES ÉCRANS (signalé à l'usage : « la rangée
   à 4 colonnes et à 3 colonnes peut très mal s'afficher »). La grille de l'accueil est fluide
   (`auto-fill minmax(290px,1fr)`) : un écran de 1600 px donne QUATRE pistes de 319 px, plus
   étroites qu'un téléphone de 390. Mesurer 330 et 390 ne prouvait donc rien sur ordinateur — on
   balaye les six largeurs qui produisent 1, 2, 3 et 4 colonnes. */
/* UNE BOÎTE GARDE SES QUATRE CÔTÉS (v5.0.0, signalé à l'usage). La règle
   `.pos-card.vig + .pos-card{border-top:0}` avait été écrite quand le repère ORDINAIRE était une
   LIGNE à filet : après une boîte ambre, ce filet aurait fait double trait. Mais deux BOÎTES qui
   se suivent — le cas dès que deux repères sont signalés △, donc sur les deux fiches d'exemple
   depuis T13 — n'ont pas ce problème : la seconde perdait son bord haut et se lisait comme rognée.
   C'est « normal = ligne, signalé = boîte » : une règle écrite pour une LIGNE ne doit pas
   s'appliquer à une BOÎTE. */
/* LA RÉFÉRENCE — PLAN À GAUCHE, RECHERCHE DEDANS (v5.0.0, refonte des protocoles).
   Un protocole peut faire plusieurs milliers de mots : la recherche de l'accueil trouve la FICHE,
   jamais l'endroit. ⚠ LE SURLIGNAGE NE PASSE JAMAIS PAR `innerHTML` — il parcourt les NŒUDS DE
   TEXTE et n'insère que des nœuds créés : réinjecter du balisage produit par `mdRender` ouvrirait
   une seconde occasion de se tromper là où `esc()` est la seule barrière (règle 4). Le témoin
   vérifie donc AUSSI que le HTML rendu est intact. */
console.log('\n══ RÉFÉRENCE · plan à gauche, recherche dedans ══');
/* ⚠ ON BALAYE LE SEUIL, PAS DEUX POINTS CONFORTABLES. La grille demande 260 + 24 + 780 = 1064 px
   de contenu : entre 1000 et 1064, la piste du corps débordait et la colonne COLLANTE se
   superposait au texte (signalé à l'usage). Le seuil est donc 1200 — palier déjà déclaré, aucune
   addition à l'échelle — et le témoin mesure DE PART ET D'AUTRE, plus le point exact. */
for (const W of [390, 999, 1000, 1199, 1200, 1400]) {
  const page = await br.newPage({viewport:{width:W,height:900},hasTouch:W<780});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const pr=migrateProtocol({id:'pz',title:'Référence témoin',kind:'reference',
      body:['# Préparation',Array(30).fill('Vérifier le matériel de perfusion.').join('\n\n'),
        '## Matériel',Array(20).fill('cristalloïdes et tubulure').join('\n\n'),
        '# Déroulé',Array(20).fill('Poser la voie veineuse.').join('\n\n'),
        '## Surveillance','fin'].join('\n\n')});
    protocols.push(pr);openProtocolRead('pz');await w(600);
    const toc=document.querySelector('.ref-toc'),grid=document.querySelector('.ref-grid');
    const bodyL=Math.round(document.querySelector('.md-body').getBoundingClientRect().left);
    const avant=document.querySelector('.md-body').innerHTML;
    const q=document.getElementById('pfQ');
    if(q){q.value='perfusion';q.dispatchEvent(new Event('input',{bubbles:true}));}
    await w(500);
    const marks=document.querySelectorAll('mark.pf-h').length;
    const cnt=(document.getElementById('pfCount')||{}).textContent||'';
    /* On efface la recherche : le document doit revenir À L'IDENTIQUE, sinon le surlignage
       laisserait des nœuds derrière lui à chaque frappe. */
    if(q){q.value='';q.dispatchEvent(new Event('input',{bubbles:true}));}
    await w(300);
    /* ⚠ LA COLONNE NE DÉPEND PLUS DU NOMBRE DE TITRES (v5.0.0, demande utilisateur) : elle porte
       aussi la RECHERCHE et les annexes. Ce qui reste conditionnel est le SOMMAIRE lui-même — une
       liste de titres n'a de sens que s'il y en a. Le cas à mesurer est donc une référence SANS
       AUCUN titre : la colonne doit exister (on cherche encore dans le texte), la liste non. */
    const court=migrateProtocol({id:'pzc',title:'Court',kind:'reference',
      body:'Un paragraphe sans le moindre titre.\n\nUn autre paragraphe.'});
    protocols.push(court);openProtocolRead('pzc');await w(600);
    const gC=document.querySelector('.ref-grid');
    const sansToc={toc:!!document.querySelector('.ref-toc'),
      recherche:!!document.getElementById('pfQ'),
      liens:document.querySelectorAll('.ref-toc [data-rtgo]').length,
      cls:gC?gC.className:'',largeur:Math.round(document.querySelector('.md-body').getBoundingClientRect().width)};
    openProtocolRead('pz');await w(500);
    /* ⚠ ON RE-INTERROGE LE DOM. `toc` a été capturé AVANT que la sonde ouvre le protocole court
       puis rouvre le long : la référence pointe un nœud DÉTACHÉ, dont toutes les mesures valent
       zéro — et un témoin qui mesure un nœud détaché mesure le vide (leçon v4.78.0). */
    /* Une référence à TRENTE titres : sans elle, le bornage ne rencontrerait pas son cas. */
    const secs=[];for(let i=1;i<=30;i++)secs.push('## Section '+i,'texte '+i);
    const lg=migrateProtocol({id:'pzL',title:'Longue',kind:'reference',body:'# Grand\n\n'+secs.join('\n\n')});
    protocols.push(lg);openProtocolRead('pzL');await w(600);
    const dk=await (async()=>{const d=document.querySelector('details.ref-toc'),bar=document.getElementById('refBar');
      if(!d||!bar)return {pos:'—',visibleLoin:null,borne:0,defile:'',liens:0,corpsLien:'',
        ecart:999,fond:'—',hdrLine:'—',sousLaBarre:null,dansLaBarre:false};
      const hd=document.querySelector('header.bar');
      const cb=getComputedStyle(bar),ch=getComputedStyle(hd);const l=d.querySelector('.rt-lnk');
      const ec=Math.round(bar.getBoundingClientRect().top-hd.getBoundingClientRect().bottom);
      const sous=document.querySelector('.md-body').getBoundingClientRect().top>=bar.getBoundingClientRect().bottom;
      /* ⚠ ON COMPTE LES `toggle`, ON NE REGARDE PAS SEULEMENT L'ÉTAT FINAL — première version
         de ce témoin, qui restait VERTE sur le défaut : la mesure de hauteur refermait puis
         rouvrait le panneau, donc l'état final était bien « ouvert » et le défilement, acquis
         APRÈS le battement, survivait. Ce qui se voit à l'usage est le battement lui-même :
         un seul geste d'ouverture doit produire un seul `toggle`. */
      let nt=0;d.addEventListener('toggle',()=>{nt++;});
      d.open=true;await w(260);const c2=getComputedStyle(d);
      /* ⚠ LE DÉPLIAGE NE DOIT PAS SE DÉFAIRE TOUT SEUL : la mesure de hauteur refermait le
         panneau pour lire sa taille repliée, et `toggle` étant asynchrone, le handler se
         rappelait — le panneau battait et perdait son défilement. On mesure donc qu'il est
         ENCORE ouvert et qu'un défilement acquis SURVIT. */
      d.scrollTop=200;await w(160);
      const b=parseFloat(c2.maxHeight)||0,ov=c2.overflowY,nb=d.querySelectorAll('.rt-lnk').length;
      const cl=l?getComputedStyle(l).fontSize:'';
      window.scrollTo(0,1200);
      const vis=d.getBoundingClientRect().top>=0&&d.getBoundingClientRect().top<300;
      const survit=d.open&&d.scrollTop>0&&nt===1;
      window.scrollTo(0,0);d.open=false;
      return {pos:cb.position,visibleLoin:vis,borne:Math.round(b),defile:ov,liens:nb,corpsLien:cl,survit,
        ecart:ec,fond:cb.backgroundColor===ch.backgroundColor?'identique':cb.backgroundColor,
        hdrLine:ch.borderBottomWidth,barLine:cb.borderBottomWidth,sousLaBarre:sous,
        dansLaBarre:bar.contains(d)};})();
    openProtocolRead('pz');await w(500);
    const toc2=document.querySelector('.ref-toc');
    const rb=document.querySelector('.md-body').getBoundingClientRect();
    const rt=toc2?toc2.getBoundingClientRect():null;
    return {sansToc, dock:dk, tag:toc2?toc2.tagName:null,
      chevauche:!!(toc2&&toc2.tagName==='ASIDE'&&rt.right>rb.left+1),
      centre:Math.abs((rb.left+rb.width/2)-innerWidth/2)<=2,
      ecart:Math.round(Math.abs((rb.left+rb.width/2)-innerWidth/2)),
      largeurCorps:Math.round(rb.width),
      largeurToc:rt?Math.round(rt.width):0,
      dansCorps:!!document.querySelector('.ref-main .links')||!document.querySelector('.links'),
      gauche:toc2?Math.round(rb.left)>Math.round(rt.left):null,
      ordre:[...(grid?grid.children:[])].map(x=>String(x.className).split(' ')[0]),
      marks,cnt,restaure:document.querySelector('.md-body').innerHTML===avant,
      resteMarks:document.querySelectorAll('mark.pf-h').length};});
  /* DEUX RÉGIMES, ET LE TÉMOIN LES DISTINGUE (v5.0.0, après deux signalements) :
       · < 1000 : dépliant — il n'y a pas de place pour une colonne ;
       · ≥ 1000 : colonne de 260 px, la paire centrée, donc le corps un peu à droite du milieu —
         mieux vaut un léger décalage qu'un sommaire qui s'efface « alors qu'il y a la place » ;
       · ≥ 1200 : le corps reprend ses 780 px et se RECENTRE PROGRESSIVEMENT (le rail a un
         plancher de 260, c'est la piste de droite qui absorbe) — nul à partir de ~1370.
     On mesure donc la DÉCROISSANCE du décalage, pas une égalité à zéro qui serait fausse à 1200. */
  if(W>=1000){
    t(`${W} · le plan d'une référence vit à GAUCHE`, r.tag==='ASIDE'&&r.gauche===true, `${r.tag} gauche=${r.gauche}`);
    /* L'ordre du DOM reste celui de la LECTURE : le corps AVANT le sommaire. */
    t(`${W} · … mais le corps vient AVANT lui dans le DOM`, r.ordre[0]==='ref-main', JSON.stringify(r.ordre));
    /* LE SOMMAIRE NE RÉTRÉCIT JAMAIS : il passait de 260 à 168 puis revenait à 260, c'est-à-dire
       qu'il rétrécissait au moment PRÉCIS où l'on gagne de la place. */
    t(`${W} · … et le sommaire garde ses 260 px`, r.largeurToc>=258, `${r.largeurToc} px`);
    if(W>=1200)t(`${W} · … le corps reprend ses 780 px pleins`, r.largeurCorps>=770, `${r.largeurCorps} px`);
    if(W>=1400)t(`${W} · … et il est alors centré dans la FENÊTRE`, r.ecart<=2, `écart ${r.ecart} px`);
  } else {
    t(`${W} · sans colonne, le plan est un DÉPLIANT replié`, r.tag==='DETAILS', String(r.tag));
    /* ⚠ IL EST COLLANT ET BORNÉ. Un dépliant posé dans le flux disparaît dès qu'on descend de deux
       écrans — or on cherche dans une référence précisément quand on est loin dans le texte. Et
       déplié, une référence à trente titres remplirait l'écran : la hauteur est bornée et défile.
       ⚠ ON MESURE AUSSI LE STYLE DES RANGÉES : elles vivaient dans la media query ≥ 1000, donc
       sous ce seuil elles n'avaient AUCUN style — des boutons bruts à la police du système. Un
       témoin qui ne regarde que la structure ne voit pas ça. */
    /* ⚠ IL EST DU CHROME, PAS DU FLUX (signalé à l'usage : « lorsque ça colle ça ne fusionne pas
       à l'en-tête et ça fait moche »). Un `sticky` vit d'abord dans le flux PUIS se colle : à cet
       instant il touche la barre sans en faire partie. En `fixed`, sœur de `.app`, il ne
       transitionne jamais — il EST la seconde rangée de l'en-tête dès le premier pixel. On mesure
       la CONTINUITÉ (écart nul, même fond, un SEUL filet — celui du bas), pas seulement la
       position : « collé » et « fusionné » ne sont pas la même chose, et c'est le second qui
       était demandé. */
    t(`${W} · … il est en en-tête (fixed), pas un dépliant du flux`,
      r.dock.pos==='fixed'&&r.dock.dansLaBarre===true&&r.dock.visibleLoin===true, JSON.stringify(r.dock));
    /* Le fond commun fait le BLOC, le filet dit qu'il a deux ÉTAGES (demande utilisateur) : les
       deux rangées sont bordées, comme #crisisCtrl au-dessus de #crisisDock. */
    t(`${W} · … et il PROLONGE le bandeau : écart nul, même fond, un filet par étage`,
      r.dock.ecart===0&&r.dock.fond==='identique'&&parseFloat(r.dock.hdrLine)>0&&parseFloat(r.dock.barLine)>0,
      `écart ${r.dock.ecart} px · fond ${r.dock.fond} · filets hdr ${r.dock.hdrLine} / barre ${r.dock.barLine}`);
    t(`${W} · … et le dépliage ne se défait pas tout seul (défilement conservé)`,
      r.dock.survit===true, `ouvert+défilé+un seul toggle=${r.dock.survit}`);
    /* Une barre FIXE ne prend aucune place au flux : sans réservation mesurée, le texte naîtrait
       DERRIÈRE elle — le défaut qu'un `sticky` n'a pas et qu'on hérite en changeant de mécanique. */
    t(`${W} · … et le corps naît SOUS elle, jamais derrière`, r.dock.sousLaBarre===true, String(r.dock.sousLaBarre));
    t(`${W} · … borné en hauteur et défilant quand il est long`,
      r.dock.borne>0&&r.dock.defile!=='visible'&&r.dock.liens>=10,
      `${r.dock.borne} px, ${r.dock.liens} liens, overflow ${r.dock.defile}`);
    t(`${W} · … et ses rangées sont RÉELLEMENT stylées`, r.dock.corpsLien==='12px', r.dock.corpsLien);
  }
  /* LE DÉFAUT SIGNALÉ : une colonne collante qui passe PAR-DESSUS le texte. Il ne se voit pas
     dans un débordement de conteneur — il faut comparer les deux boîtes. */
  t(`${W} · le sommaire ne chevauche jamais le corps`, r.chevauche===false, `chevauche=${r.chevauche}`);
  /* Les annexes sont RECOPIÉES, pas déplacées : la copie est un accès rapide, l'original reste
     à sa place dans le document. Mesurer la seule copie laisserait passer un déplacement. */
  t(`${W} · les annexes restent DANS le corps`, r.dansCorps===true, `${r.dansCorps}`);
  t(`${W} · la recherche trouve dans le corps`, r.marks>=10&&/\/\s*\d+/.test(r.cnt), `${r.marks} — « ${r.cnt} »`);
  /* Sans AUCUN titre : la colonne existe (la recherche y vit), mais elle ne liste rien. */
  t(`${W} · une référence sans titre garde sa RECHERCHE`, r.sansToc.toc===true&&r.sansToc.recherche===true,
    JSON.stringify(r.sansToc));
  t(`${W} · … et n'affiche alors AUCUN sommaire`, r.sansToc.liens===0, `${r.sansToc.liens} lien(s)`);
  t(`${W} · … sans réécrire le HTML rendu (effacée, le document est identique)`,
    r.restaure===true&&r.resteMarks===0, `restauré=${r.restaure} restes=${r.resteMarks}`);
  await page.close();
}

/* ⚠ LE FRANCHISSEMENT DE PALIER, MESURÉ SUR UN VRAI REDIMENSIONNEMENT (signalé à l'usage : « non
   responsive, pas d'adaptation »). Le sommaire d'une référence est un `<aside>` au-dessus de
   1000 px et un `<details>` en dessous : c'est une STRUCTURE, décidée au rendu — et `_onReadBp`
   ne connaissait pas la vue `protocolRead`, donc redimensionner laissait la page telle qu'elle
   avait été RENDUE. Même trou que celui réparé pour les éditeurs en v4.77.0.
   ⚠ ET IL FAUT PLAYWRIGHT : le pane du navigateur intégré n'émet NI `resize` NI
   `matchMedia change` sur un redimensionnement CDP — un palier n'y est pas éprouvable. */
/* ⚠ LE BANDEAU-TITRE NE SE DIT PLUS DEUX FOIS (signalé à l'usage : « le bandeau inférieur avec le
   titre apparaît encore en mode Essayer et en exercice, alors que le titre est déjà à côté du ‹ »).
   Il ne porte plus QUE la phrase d'une exception ; le titre et son discriminant vivent dans la
   barre, en permanence. Trois modes à vérifier — et le témoin doit RENCONTRER SON CAS : sans
   session démarrée il n'y a pas de crise du tout, et tout serait vert pour la mauvaise raison. */
/* ⚠ LE HARNAIS D'ACCESSIBILITÉ MESURE DES SURFACES, PAS DES ÉTATS — et c'est ce qui a laissé
   passer DEUX violations AA que j'ai moi-même introduites (audit de design, v5.0.0) : le
   surlignage de recherche n'existe qu'une fois une requête tapée, et le vert du bouton
   d'excursion qu'une fois parti. `audit-a11y` ouvre chaque surface AU REPOS : ni l'un ni l'autre
   n'était dans son champ, et les 301 contrôles restaient verts.
   Mesuré avant correction : surlignage 3,64:1 en clair et 1,76:1 en sombre (texte de 11 px),
   bouton vert 1,9:1 en sombre. On mesure donc ici les ÉTATS, dans les deux thèmes. */
/* ⚠ COMPLICATIONS — B, C, D (v5.0.0, audit design). Trois défauts mesurés : l'index existait même
   à UN seul événement (une liste d'un élément, deux taps) ; il ouvrait une FENÊTRE qui couvrait
   38 % de l'écran pendant un soin ; et le RETOUR d'excursion naissait à y=738 sur un écran de 640,
   c'est-à-dire hors écran, alors que la doctrine le décrit comme « LE contrôle rempli de l'écran ».
   ⚠ L'ENTRÉE, ELLE, N'A PAS BOUGÉ, et c'est une décision de l'auteur : la mettre en tête de carte
   donnerait la position de plus forte saillance à l'événement le MOINS probable et repousserait
   les cases à cocher. La dissymétrie entrée/retour est le raisonnement, pas un oubli. */
console.log('\n══ COMPLICATIONS · entrer d’un tap, revenir sans chercher ══');
for (const W of [320, 390]) {
  const page = await br.newPage({viewport:{width:W,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const wt=m=>new Promise(r=>setTimeout(r,m));
    const f=fiches.find(x=>(x.excursions||[]).length);
    openRead(f.id);await wt(400);
    {const b=document.getElementById('sessStart');if(b)b.click();}await wt(700);
    /* UN SEUL ÉVÉNEMENT : l'événement EST le bouton, il n'y a pas d'index à traverser. */
    const un=document.querySelector('[data-cxgo]');
    const unLbl=un?un.textContent.replace(/\s+/g,' ').trim():null;
    const indexAUn=!!document.querySelector('[data-cxopen]');
    /* ⚠ ON PART DE LOIN, EXPRÈS : le défaut signalé est que l'entrée ne ramenait pas EN HAUT du
       bloc d'excursion — un contrôle qui n'a pas défilé avant ne peut pas le voir. */
    /* ⚠ ON RELÈVE LES TROIS GESTES AVANT D'ENTRER : une fois DANS la complication, son bouton
       disparaît (on y est), et le témoin ne verrait plus que deux boîtes. */
    const _actesAvant=[...document.querySelectorAll('.cx-row .blk-act')].map(e=>{
      const c=getComputedStyle(e);
      return {fs:c.fontSize,pad:c.padding,h:Math.round(e.getBoundingClientRect().height),col:c.color};});
    window.scrollTo(0,700);await wt(200);
    if(un){un.click();}await wt(900);
    const cur2=document.querySelector('.ov-block.cur');
    const entreeY=cur2?Math.round(cur2.getBoundingClientRect().top-stickBase()):null;
    /* Entré sur l'unique événement : son bouton ne doit plus être proposé — on y EST. */
    const btnApres=!!document.querySelector('[data-cxgo]');
    const _c=document.querySelector('.ov-block.cur');
    const _vp=document.querySelector('.cx-row [data-ovverify]');
    const verPied=!!_vp,verTete=!!(_c&&_c.querySelector('.ov-head [data-ovverify]'));
    const verCible=_vp?Math.round(_vp.getBoundingClientRect().height):0;
    const _ac=_actesAvant;
    const actes={n:_ac.length,
      fs:[...new Set(_ac.map(e=>e.fs))],
      pad:[...new Set(_ac.map(e=>e.pad))],
      h:[...new Set(_ac.map(e=>e.h))],
      encres:new Set(_ac.map(e=>e.col)).size};
    const modale=[...document.querySelectorAll('.ai-modal.on')].length;
    const ret=document.querySelector('[data-cxback]'),carte=document.querySelector('.ov-block.cur');
    const rr=ret?ret.getBoundingClientRect():null,rc=carte?carte.getBoundingClientRect():null;
    const corps=carte?carte.querySelector('.ov-body'):null;
    /* Le retour ouvre le CORPS de la carte : il est le premier enfant, donc au-dessus des étapes. */
    const premier=corps?(corps.firstElementChild&&corps.firstElementChild.className||''):'';
    /* DEUX ÉVÉNEMENTS : l'index reparaît, en dépliant — et la porte EXTERNE le dit par « ↗ ». */
    f.excursions.push({label:'Arrêt cardiaque',target:fiches.find(x=>x.id!==f.id).id});
    openRead(f.id);await wt(400);
    {const b=document.getElementById('sessStart');if(b)b.click();}await wt(700);
    const tg=document.querySelector('[data-cxopen]');
    const tgLbl=tg?tg.textContent.replace(/\s+/g,' ').trim():null;
    if(tg){tg.scrollIntoView({block:'center'});await wt(200);tg.click();}await wt(600);
    const items=[...document.querySelectorAll('.cx-list .cx-item')];
    const modale2=[...document.querySelectorAll('.ai-modal.on')].length;
    const cible=items.length?Math.round(Math.min(...items.map(e=>e.getBoundingClientRect().height))):0;
    const ext=items.some(e=>/↗/.test(e.textContent));
    {const b=document.querySelector('[data-cxopen]');if(b)b.click();}await wt(400);
    const referme=!document.querySelector('.cx-list');
    /* ⚠ ON MESURE L'ÉTAT « on y est » LÀ OÙ IL EXISTE DÉJÀ : la première moitié du contrôle nous
       a fait ENTRER sur l'unique complication, et la session vive garde cette position. Il suffit
       donc de déclarer le second événement et de rouvrir l'index. Ma première version rouvrait
       puis cliquait la rangée courante — laquelle est justement DÉSACTIVÉE : le clic ne faisait
       rien et le dernier tap REFERMAIT l'index, d'où zéro rangée mesurée. */
    {const b=document.querySelector('[data-cxopen]');if(b)b.click();}await wt(500);
    const ap=[...document.querySelectorAll('.cx-list .cx-item')];
    const iciEl=ap.find(e=>e.classList.contains('ici'));
    const iciTxt=iciEl?iciEl.textContent.replace(/\s+/g,' ').trim():null;
    const iciDis=ap.filter(e=>e.disabled).length,autreTapable=ap.filter(e=>!e.disabled).length;
    return {unLbl,indexAUn,modale,items:items.length,tgLbl,modale2,cible,ext,referme,
      btnApres,entreeY,verPied,verTete,verCible,actes,iciTxt,iciDis,autreTapable,
      retourY:rr?Math.round(rr.top):null,
      retourVisible:!!(rr&&rr.top>=0&&rr.bottom<=innerHeight),
      premier};});
  t(`${W} · B — à UN événement, il n'y a pas d'index`,
    r.indexAUn===false&&/⚡/.test(r.unLbl||''), `${r.unLbl}`);
  t(`${W} · C — à DEUX, l'index reparaît, et il ne COUVRE rien`,
    r.items===2&&r.modale2===0&&/Complications 2/.test(r.tgLbl||''), `${r.tgLbl} · ${r.items} rangée(s), ${r.modale2} fenêtre(s)`);
  t(`${W} · … rangées ≥ 44 px, et la porte EXTERNE se dit (↗)`, r.cible>=44&&r.ext===true,
    `${r.cible} px, externe=${r.ext}`);
  t(`${W} · … et re-presser referme`, r.referme===true, String(r.referme));
  t(`${W} · entrer ne passe par AUCUNE fenêtre`, r.modale===0, `${r.modale}`);
  /* ⚠ ON MESURE QUE LE RETOUR SE VOIT, pas seulement qu'il existe : un contrôle présent 400 px
     plus bas est un contrôle qu'on cherche, et la doctrine le veut « rempli, sous les yeux ». */
  t(`${W} · D — le retour d'excursion est VISIBLE sans défiler`,
    r.retourVisible===true, `y = ${r.retourY} px`);
  t(`${W} · … et il ouvre le corps de la carte`, /cx-back-top/.test(r.premier), r.premier);
  /* ⚠ ON NE PROPOSE PAS D'ENTRER LÀ OÙ L'ON EST DÉJÀ (signalé à l'usage). À UN SEUL événement le
     bouton PORTE son nom : le voir pendant qu'on exécute ce bloc laisse croire qu'on n'y est pas
     encore. À DEUX ou plus l'index reste — on peut vouloir passer d'un événement à l'autre —, mais
     celui où l'on se trouve s'y ANNONCE et n'est plus tapable : une liste dont les rangées bougent
     selon l'endroit où l'on est ne s'apprend pas. */
  /* ⚠ ENTRER AMÈNE EN HAUT DU BLOC (signalé à l'usage) : le défilement n'existait que dans UNE
     des trois branches de `cxEnter` — ni au premier geste de la session, ni en « Toute la fiche ».
     8 px sous les couches collantes, c'est la marge que `ovScrollEl` pose partout. */
  /* ⚠ « VÉRIFIER » EST AU PIED, PAS EN TÊTE (demande utilisateur) : l'en-tête ne garde que ce qui
     dit OÙ l'on est ; le pied porte ce qui fait avancer, ce qui ramène et ce qui re-vérifie. La
     seconde passe commence quand la première est finie, elle ne la précède pas. Mesuré : en-tête
     106 → 81 px, première étape 387 → 361. */
  t(`${W} · « Vérifier » est au PIED de la carte, plus en tête`,
    r.verPied===true&&r.verTete===false, `pied=${r.verPied} tête=${r.verTete}`);
  t(`${W} · … avec une cible de 44 px`, r.verCible>=44, `${r.verCible} px`);
  /* ⚠ LES TROIS GESTES DE BLOC PARTAGENT UNE SEULE BOÎTE (signalé à l'usage). Ils différaient sur
     trois axes — corps 13,5 / 13,5 / 12 px, rembourrage 8-14 / 8-12 / 6-10, trois traitements de
     fond —, et le troisième perdait en plus contre `.ov-redo` : le gabarit qu'on lui avait écrit ne
     s'appliquait qu'à moitié. Seul le REGISTRE distingue désormais, et il porte du sens. */
  t(`${W} · les trois gestes de bloc ont la MÊME boîte`,
    r.actes.n===3&&r.actes.fs.length===1&&r.actes.pad.length===1&&r.actes.h.length===1,
    `${r.actes.n} boutons · corps ${JSON.stringify(r.actes.fs)} · rembourrage ${JSON.stringify(r.actes.pad)} · hauteur ${JSON.stringify(r.actes.h)}`);
  t(`${W} · … et trois registres distincts`, r.actes.encres===3, `${r.actes.encres} encres`);
  t(`${W} · entrer amène EN HAUT du bloc d'excursion`,
    r.entreeY!==null&&Math.abs(r.entreeY-8)<=4, `${r.entreeY} px sous le chrome collant`);
  t(`${W} · à UN événement, le bouton disparaît quand on y est`,
    r.btnApres===false, `présent=${r.btnApres}`);
  t(`${W} · à DEUX, la rangée où l'on est se dit et n'est plus tapable`,
    r.iciTxt&&/vous y êtes/.test(r.iciTxt)&&r.iciDis===1&&r.autreTapable===1,
    `« ${r.iciTxt} » · ${r.iciDis} désactivée, ${r.autreTapable} tapable`);
  await page.close();
}

console.log('\n══ CONTRASTE DES ÉTATS · ce qui n’existe qu’après un geste ══');
for (const th of ['light','dark']) {
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true,colorScheme:th});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(th=>{document.documentElement.dataset.theme=th;},th);
  await amorce(page);
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    openRead(fiches[0].id);await w(400);
    const sb=document.getElementById('sessStart');if(sb)sb.click();await w(600);
    document.getElementById('allBtn').click();await w(700);
    const q=document.getElementById('pfQ');q.value='adrénaline';q.dispatchEvent(new Event('input',{bubbles:true}));await w(400);},th);
  const R=await page.evaluate(()=>{
    const lum=c=>{const m=c.match(/[\d.]+/g).map(Number);const f=v=>{v/=255;return v<=.03928?v/12.92:Math.pow((v+.055)/1.055,2.4);};
      return .2126*f(m[0])+.7152*f(m[1])+.0722*f(m[2]);};
    const fond=e=>{let n=e;while(n&&n!==document.documentElement){const b=getComputedStyle(n).backgroundColor;
      if(b&&!/rgba?\(0, 0, 0, 0\)|transparent/.test(b))return b;n=n.parentElement;}
      return getComputedStyle(document.body).backgroundColor;};
    const rap=e=>{const A=lum(getComputedStyle(e).color),B=lum(fond(e));
      return Math.round(((Math.max(A,B)+.05)/(Math.min(A,B)+.05))*100)/100;};
    const marks=[...document.querySelectorAll('mark.pf-h')];
    const cur=document.querySelector('mark.pf-h.cur');
    const vert=document.querySelector('#allBtn .dp-lbl');
    return {nMarks:marks.length,
      pireMark:marks.length?marks.reduce((a,e)=>Math.min(a,rap(e)),99):null,
      vert:vert?rap(vert):null,vertPose:document.getElementById('allBtn').classList.contains('dp-back'),
      curForme:cur?(parseFloat(getComputedStyle(cur).outlineWidth)>0||+getComputedStyle(cur).fontWeight>=700):null};});
  t(`${th} · témoin : les états mesurés EXISTENT`, R.nMarks>0&&R.vertPose===true,
    `${R.nMarks} surlignage(s), vert posé=${R.vertPose}`);
  t(`${th} · le surlignage de recherche tient AA (4,5:1)`, R.pireMark>=4.5, `${R.pireMark}:1`);
  t(`${th} · … et l'occurrence courante se distingue par la FORME`, R.curForme===true, String(R.curForme));
  t(`${th} · le vert du retour d'excursion tient AA`, R.vert>=4.5, `${R.vert}:1`);
  await page.close();
}

console.log('\n══ BANDEAU · il ne porte plus que l’exception ══');
{
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    fiches[0].discriminant='adulte';openRead(fiches[0].id);await w(500);
    const sb=document.getElementById('sessStart');if(sb)sb.click();await w(700);});
  const R=await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const cb=document.getElementById('crisisBand'),bt=document.getElementById('brandTitle');
    const lire=()=>({vu:!cb.hidden,tag:cb.querySelector('.cb-tag').textContent.trim(),
      titreDansBandeau:!!cb.querySelector('.cb-ttl')});
    const crise=Object.assign(lire(),{titreBarre:bt.textContent.trim(),disc:!!bt.querySelector('.bt-d'),
      pilule:!document.getElementById('hdrCrisis').hidden});
    state.previewFrom='edit';render();await w(400);
    const ess=Object.assign(lire(),{hach:getComputedStyle(document.querySelector('header.bar'),'::before').opacity,
      cls:document.querySelector('header.bar').classList.contains('ess')});
    state.previewFrom=null;Runtime.exercise=true;render();await w(400);
    const exo=lire();
    Runtime.exercise=false;render();await w(300);
    return {crise,ess,exo};});
  t('témoin : la crise est bien à l’écran (pilule de mode posée)', R.crise.pilule===true, String(R.crise.pilule));
  t('crise ordinaire : aucun bandeau, le titre est dans la barre',
    R.crise.vu===false&&R.crise.titreBarre.length>0, JSON.stringify(R.crise));
  t('… et le discriminant l’y suit (K6 survit à la troncature)', R.crise.disc===true, String(R.crise.disc));
  t('le bandeau ne porte plus AUCUN titre (purgé)', R.crise.titreDansBandeau===false, String(R.crise.titreDansBandeau));
  /* L'ESSAI N'EST PAS UNE EXCEPTION AU SENS DU BANDEAU : la barre y dit déjà tout, il ne manquait
     que la TEXTURE — et elle vit sur l'en-tête. Un bandeau sans titre ni phrase y serait une
     bande hachurée vide. */
  t('essai : pas de bandeau, la hachure vit sur l’en-tête',
    R.ess.vu===false&&R.ess.cls===true&&parseFloat(R.ess.hach)>0.9, JSON.stringify(R.ess));
  t('exercice : le bandeau reste, et il ne porte QUE la phrase',
    R.exo.vu===true&&/Exercice/.test(R.exo.tag), JSON.stringify(R.exo));
  await page.close();
}

/* ⚠ LA COLONNE D'ORIENTATION EST DÉSATURÉE — Y COMPRIS SES CHIPS DE BRANCHE (signalé à l'usage).
   En ambre plein, la chip empruntait le registre ATTENTION à ce qui n'est ni une alerte ni un
   point de vigilance : le NOM de la branche. Et le groupe « à tout moment » porte UN rail, du
   titre à la dernière rangée, au lieu d'une bordure par rangée qui semblait surgir. */
console.log('\n══ PARCOURS INERTE · registres et cohérence du groupe ══');
{
  const page = await br.newPage({viewport:{width:1280,height:900}});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    openRead(fiches[0].id);await w(700);});
  const R=await page.evaluate(()=>{
    /* ⚠ UNE SEULE COLONNE À LA FOIS : à 1280 px le plan existe À GAUCHE *et* dans le rail de
       droite. Comparer un intertitre de l'une à une rangée de l'autre mesure l'écart entre deux
       colonnes, pas l'alignement — première version du témoin, rouge pour cette raison. */
    const root=document.querySelector('.read-plan')||document.querySelector('.rail-lad')||document;
    const ch=root.querySelector('.pl-brc span');
    const sec=root.querySelector('.pl-sec.cx');
    const sh=root.querySelector('.pl-sech'),ln=root.querySelector('.pl-line');
    /* ⚠ ON RÉSOUT LE TOKEN, ON NE LE COMPARE PAS PAR SON NOM (douzième piège, v4.76.0) : lu dans
       `--verify` il vaut « #… » alors que la couleur calculée d'un élément vaut « rgb(…) » —
       comparer les deux ne peut JAMAIS être vrai, et le contrôle passait quoi qu'il arrive. On
       peint une sonde et l'on lit ce que le moteur en fait. */
    const sonde=document.createElement('span');
    sonde.style.cssText='color:var(--verify);background:var(--verify-soft);position:absolute;left:-9999px';
    document.body.appendChild(sonde);
    const amb=getComputedStyle(sonde).color,ambBg=getComputedStyle(sonde).backgroundColor;
    sonde.remove();
    return {chip:!!ch,chipBg:ch?getComputedStyle(ch).backgroundColor:'',chipInk:ch?getComputedStyle(ch).color:'',
      ambre:amb,ambreBg:ambBg,sec:!!sec,railSec:sec?getComputedStyle(sec).borderLeftWidth:'0px',
      railLigne:root.querySelector('.pl-line.cxl')?getComputedStyle(root.querySelector('.pl-line.cxl')).borderLeftWidth:'0px',
      cxCol:root.querySelectorAll('.pl-line.cxl').length,
      chipEcart:(()=>{const c=root.querySelector('.pl-brc');if(!c)return null;
        const sp=c.querySelector('span'),nx=c.nextElementSibling;
        const mk=nx&&nx.querySelector?nx.querySelector('.n'):null;
        return (sp&&mk)?Math.round(sp.getBoundingClientRect().left-mk.getBoundingClientRect().left):null;})(),
      ecarts:(()=>{const ns=[...root.querySelectorAll('.rail-head,.pl-line')];
        const o=[];ns.forEach((e,i)=>{if(!e.classList.contains('rail-head'))return;
          const nx=ns[i+1];if(nx)o.push(Math.round(nx.getBoundingClientRect().top-e.getBoundingClientRect().bottom));});
        return o;})(),
      marqueurs:(()=>{const ls=[...root.querySelectorAll('.pl-line')];
        const sansMk=ls.filter(e=>!e.querySelector('.n')).length;
        /* On ignore les rangées à fond plein (courante, faite) : leur encre est celle du fond. */
        const enc=[...new Set(ls.filter(e=>!e.classList.contains('cur')&&!e.classList.contains('done'))
          .map(e=>e.querySelector('.n')).filter(Boolean).map(e=>getComputedStyle(e).color))];
        return {manquants:sansMk,encres:enc};})(),
      /* ⚠ LA RÉFÉRENCE EST UNE PASTILLE AU REPOS : la rangée COURANTE est un aplat plein, son
         filet vaut le primaire — la comparer au losange mesurait deux états, pas deux styles. */
      pastilleFilet:(()=>{const p0=root.querySelector('.pl-line:not(.dec):not(.cxl):not(.wl):not(.cur):not(.done) .n');
        return p0?getComputedStyle(p0).borderTopColor:'';})(),
      losange:(()=>{const d=root.querySelector('.pl-line.dec .n');if(!d)return null;
        const b4=getComputedStyle(d,'::before');
        return {chiffre:d.textContent.trim(),filet:b4.borderTopColor,fond:b4.backgroundColor};})(),
      /* ⚠ TOUS LES INTERTITRES DE LA COLONNE PARTENT DU MÊME x (demande utilisateur) : « À tout
         moment » et « Surveiller » s'alignent sur « Parcours inerte » — et, en rail unique, sur
         « Minuteurs & compteurs » et « Repères posologiques », qui sont des `.rail-title` sans
         retrait. On compare le début du TEXTE, pas le bord de la boîte. */
      /* ⚠ PAR COLONNE, PAS EN BLOC : en cockpit il y a DEUX colonnes (le plan à gauche, le rail à
         droite) — les mélanger mesurerait l'écart entre deux colonnes, pas un alignement. */
      xTitres:(()=>{const x=e=>{const c=getComputedStyle(e);
          return Math.round(e.getBoundingClientRect().left+parseFloat(c.paddingLeft)+parseFloat(c.borderLeftWidth));};
        const cols=[[...root.querySelectorAll('.rail-title,.pl-sech')]];
        const side=document.querySelector('.read-side');
        if(side&&side!==root)cols.push([...side.querySelectorAll('.rail-title,.pl-sech')]);
        return cols.filter(c=>c.length).map(c=>[...new Set(c.map(x))]);})()};});
  t('témoin : une chip de branche est mesurée', R.chip===true, String(R.chip));
  /* On compare l'ENCRE RÉSOLUE, on ne se fie pas au nom du token (douzième piège, v4.76.0). */
  t('… et elle n’emprunte plus le registre ATTENTION',
    R.chip&&R.chipInk!==R.ambre&&R.chipBg!==R.ambreBg,
    `fond ${R.chipBg} · encre ${R.chipInk} (ambre ${R.ambre} / ${R.ambreBg})`);
  /* ⚠ « À TOUT MOMENT » A QUITTÉ LA COLONNE (v5.0.0, demande utilisateur : « c'est inutile »).
     Elle ORIENTE dans la séquence — or une complication n'y est justement pas, et l'endroit où on
     l'attend est la carte du bloc ou la vue « Toute la fiche », qui la gardent toutes deux. */
  t('la colonne ne porte plus de section « à tout moment »',
    R.cxCol===0&&parseFloat(R.railLigne)===0, `${R.cxCol} rangée(s), liseré ${R.railLigne}`);
  /* ⚠ LA CHIP DE BRANCHE S'ALIGNE SUR LE MARQUEUR DU BLOC QU'ELLE OUVRE (signalé à l'usage) :
     elle portait les retraits du PLAN (20/32/48) quand la colonne resserre les siens (16/28/40). */
  if(R.chipEcart!==null)t('la chip de branche s’aligne sur le marqueur du bloc enfant',
    Math.abs(R.chipEcart)<=1, `${R.chipEcart} px`);
  /* ⚠ UN SEUL ÉCART ENTRE UN TITRE ET SES RANGÉES (demande utilisateur). */
  t('chaque titre a le même écart avec ses rangées',
    R.ecarts.length>=2&&[...new Set(R.ecarts)].length===1, JSON.stringify(R.ecarts));
  /* ⚠ UNE SEULE ANATOMIE DE RANGÉE : chaque ligne porte un marqueur dans la MÊME colonne, et
     l'encre reste celle de la colonne — la FORME dit le registre, pas la couleur. */
  t('chaque rangée porte un marqueur, tous à la même encre',
    R.marqueurs.manquants===0&&R.marqueurs.encres.length===1,
    `${R.marqueurs.manquants} sans marqueur · encres ${JSON.stringify(R.marqueurs.encres)}`);
  /* Le LOSANGE a le style de la pastille — même filet, même fond — et il PORTE son numéro. */
  t('le losange d’une décision est chiffré et au style des pastilles',
    !!(R.losange&&R.losange.chiffre&&R.losange.filet===R.pastilleFilet),
    JSON.stringify(R.losange)+' vs filet pastille '+R.pastilleFilet);
  t('dans CHAQUE colonne, les intertitres partent du même x',
    R.xTitres.every(c=>c.length<=1), JSON.stringify(R.xTitres));
  await page.close();
}

console.log('\n══ RÉFÉRENCE · le palier se franchit RÉELLEMENT ══');
{
  const page = await br.newPage({viewport:{width:390,height:900},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const a=migrateProtocol({id:'pR',title:'Réf',kind:'reference',body:'# Un\n\nt\n\n## Deux\n\nt\n\n# Trois\n\nt'});
    protocols.push(a);openProtocolRead('pR');await w(600);});
  const tag=async()=>page.evaluate(()=>(document.querySelector('.ref-toc')||{}).tagName||null);
  const a1=await tag();
  await page.setViewportSize({width:1400,height:900}); await page.waitForTimeout(700);
  const a2=await tag();
  await page.setViewportSize({width:390,height:900}); await page.waitForTimeout(700);
  const a3=await tag();
  t('étroit → le dépliant', a1==='DETAILS', String(a1));
  t('… puis large SANS re-rendu manuel → la colonne', a2==='ASIDE', String(a2));
  t('… et retour à l’étroit → le dépliant', a3==='DETAILS', String(a3));
  await page.close();
}

console.log('\n══ REPÈRES POSOLOGIQUES · une boîte garde ses quatre côtés ══');
{
  const page = await br.newPage({viewport:{width:1280,height:1000}});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const f=fiches.find(x=>/Anaphylaxie/i.test(x.title))||fiches[0];
    openRead(f.id);await w(500);
    const sb=document.getElementById('sessStart');if(sb)sb.click();await w(800);
    const cs=[...document.querySelectorAll('.read-side .pos-card,.read-plan .pos-card')];
    return {n:cs.length,
      boites:cs.filter(c=>c.classList.contains('vig')).length,
      sansBordHaut:cs.filter(c=>c.classList.contains('vig')&&parseFloat(getComputedStyle(c).borderTopWidth)<0.5).length};});
  /* Le contrôle doit RENCONTRER SON CAS : il faut DEUX boîtes consécutives, sinon la règle
     fautive ne se déclenche pas et le témoin reste vert sur le défaut. */
  t('témoin : au moins deux repères en BOÎTE se suivent', r.boites>=2, `${r.boites} sur ${r.n}`);
  t('aucune boîte ne perd son bord haut', r.sansBordHaut===0, `${r.sansBordHaut} sans bord`);
  await page.close();
}

console.log('\n══ ACCUEIL · la rangée a un rythme régulier ══');
for (const W of [330, 390, 700, 1000, 1400, 1600]) {
  const page = await br.newPage({viewport:{width:W,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    /* Une session EN COURS sur la première fiche : sans elle, le contrôle du chrono vivant ne
       rencontrerait pas son cas et resterait vert sur son absence. */
    const f=fiches[0];openRead(f.id);await w(400);
    const sb=document.getElementById('sessStart');if(sb)sb.click();await w(600);
    /* ⚠ LE CONTRÔLE DOIT RENCONTRER SON CAS. Mesurer les fiches d'EXEMPLE ne prouvait rien : leur
       code fait trois caractères et leur catégorie un mot — la rangée ne pouvait pas déborder, et
       le témoin restait vert pendant qu'un code de trente caractères effaçait la date chez
       l'utilisateur. On rend donc TOUT ce qui peut être long, long. */
    /* ⚠ ET LE RAIL ALPHABÉTIQUE DOIT EXISTER POUR ÊTRE MESURÉ : il ne paraît qu'à partir de deux
       lettres distinctes, or les deux fiches d'exemple n'en donnent pas assez. Sans ce cas
       construit, le témoin d'ancrage ne rencontrait rien et restait vert sur le défaut. */
    for(let i=0;i<6;i++)fiches.push(migrate({id:'zaz'+i,
      title:String.fromCharCode(67+i)+' fiche de répertoire '+i,blocks:[]}));
    const g=fiches[1]||fiches[0];
    g.code='ACR-CODE-TRES-LONG-2025';
    g.discriminant='adulte et adolescent > 12 ans';
    {const c=categories.find(x=>x.id===g.category);if(c)c.name='Urgences vitales préhospitalières';}
    state.view='library';render();await w(600);
    const rows=[...document.querySelectorAll('.dir-row')];
    const H=[...new Set(rows.map(x=>Math.round(x.getBoundingClientRect().height)))];
    const titres=rows.map(x=>x.querySelector('.card-open'));
    const live=document.querySelector('.dir-live');
    const av=live?live.textContent.trim():null;
    await w(1300);
    return {n:rows.length,hauteurs:H,
      corps:[...new Set(titres.map(b=>getComputedStyle(b).fontSize))],
      tronques:titres.filter(b=>b.scrollHeight>b.clientHeight+1).length,
      deborde:rows.filter(x=>x.scrollWidth>x.clientWidth+1).length,
      debordeH:rows.filter(x=>x.scrollHeight>x.clientHeight+1).length,
      ellipsees:rows.filter(x=>{const e=x.querySelector('.dir-sub');return e&&e.scrollWidth>e.clientWidth+1;}).length,
      reste:rows.map(x=>{const e=x.querySelector('.dir-sub');return e?Math.round(e.scrollWidth-e.clientWidth):0;}),
      fondTodo:(()=>{const e=document.querySelector('.dir-sub .tag.todo');return e?getComputedStyle(e).backgroundColor:null;})(),
      /* Chaque item doit rester DANS la boîte de la méta : un item hors boîte a disparu, alors
         qu'un item qui s'abrège LUI-MÊME reste présent et lisible en partie. La différence est la
         règle : ce qui déborde ne doit pas AFFAMER le reste. */
      itemsHors:(()=>{let h=0;rows.forEach(x=>{const sb2=x.querySelector('.dir-sub');if(!sb2)return;
        const rr=sb2.getBoundingClientRect();
        [...sb2.children].forEach(e=>{if(e.getBoundingClientRect().right>rr.right+0.5)h++;});});return h;})(),
      /* Et la DATE, qui est un item DUR, ne doit jamais être amputée — un chiffre tronqué est
         pire qu'absent (règle du quai). */
      dateCoupee:(()=>{let c2=0;rows.forEach(x=>{const e=x.querySelector('.card-date');
        if(e&&e.scrollWidth>e.clientWidth+1)c2++;});return c2;})(),
      pistes:getComputedStyle(rows[0].parentElement).gridTemplateColumns.split(' ').filter(Boolean).length,
      piste:Math.round(rows[0].getBoundingClientRect().width),
      ...(()=>{const b=rows[0].querySelector('.pinbtn');if(!b)return {pinOk:false,pinBox:'aucune épingle'};
        const cs=getComputedStyle(b,'::before'),rr=rows[0].getBoundingClientRect();
        const q=b.getBoundingClientRect();
        const ins=Math.abs(parseFloat(cs.top)||0);
        const L=q.left-ins,R=q.right+ins,T=q.top-ins,B=q.bottom+ins;
        return {pinOk:(R-L)>=43.5&&(B-T)>=43.5&&R<=rr.right+0.5&&L>=rr.left-0.5,
          pinBox:`${Math.round(R-L)}×${Math.round(B-T)} px, hors rangée : ${R>rr.right+0.5}`};})(),
      /* La NATURE de l'objet : présente sur chaque rangée, item DUR (jamais rétréci). */
      kinds:[...document.querySelectorAll('.dir-row .dir-kind')].map(e=>e.textContent.trim()),
      kindsTronq:[...document.querySelectorAll('.dir-row .dir-kind')]
        .filter(e=>e.scrollWidth>e.clientWidth+1).length,
      /* Les rangées de filtres partent-elles du même x ? (les intitulés ont des longueurs
         différentes : sans largeur minimale commune, chaque rangée commençait ailleurs). */
      chipsX:(()=>{const rs=[...document.querySelectorAll('#homeChrome .chiprow')]
        .map(r=>r.firstElementChild&&Math.round(r.firstElementChild.getBoundingClientRect().left))
        .filter(v=>v!=null);return [...new Set(rs)];})(),
      /* Le rail alphabétique est ancré en HAUT : sa position ne doit pas dépendre du NOMBRE de
         lettres — sinon un filtre déplace toute la colonne. */
      railJc:(()=>{const r=document.getElementById('azRail');return r?getComputedStyle(r).justifyContent:'—';})(),
      liseCat:!!document.querySelector('.dir-row[style*="--catcol"]'),
      pastille:document.querySelectorAll('.dir-row .cat-dot').length,
      live:!!document.querySelector('.dir-row.live'),
      chronoAvance:live?live.textContent.trim()!==av:false};});
  t(`${W} · témoin : plusieurs rangées sont mesurées`, r.n>=2, `${r.n}`);
  t(`${W} · toutes les rangées ont la MÊME hauteur`, r.hauteurs.length===1, JSON.stringify(r.hauteurs));
  t(`${W} · … et rien n'en déborde`, r.deborde===0, `${r.deborde} rangée(s)`);
  /* ⚠ 16,5 px DEPUIS L'AUDIT DESIGN v5.0.0 (A3-1) — et le contrôle EXPRIME DÉSORMAIS SON
     INTENTION plutôt qu'un chiffre. Il figeait « 15,5 px » en dur, ce qui était la bonne
     réaction à ce qui l'avait motivé (deux maquettes posant 15 puis 14,5 px, dont aucun n'est un
     palier). Mais l'intention n'a jamais été « ce titre fait 15,5 » : c'est « ce titre est SUR
     L'ÉCHELLE FERMÉE, et il ne redescend pas ». Un littéral rend le contrôle rouge sur un
     changement JUSTE, ce qui pousse à le contourner — la pire chose qu'on puisse faire à un
     garde-fou.
     Le plancher est posé à 15,5 : le titre peut monter d'un palier, jamais redescendre sous
     celui qui avait été mesuré et validé. La cohérence de VALEUR entre toutes les rangées reste
     exigée (`r.corps.length===1`), c'est elle qui donne son rythme à l'annuaire. */
  {const PALIERS_TXT=[11,12,13.5,15.5,16.5,18,19];
   const v=parseFloat(String(r.corps[0]||''));
   t(`${W} · le titre reste sur l'échelle typographique`,
     r.corps.length===1&&PALIERS_TXT.indexOf(v)>=0&&v>=15.5, JSON.stringify(r.corps));}
  t(`${W} · le titre n'est pas tronqué sur les exemples`, r.tronques===0, `${r.tronques}`);
  t(`${W} · la catégorie vit dans le liseré, la pastille est purgée`,
    r.liseCat===true&&r.pastille===0, `liseré=${r.liseCat} pastilles=${r.pastille}`);
  t(`${W} · une session en cours se voit, et son chrono AVANCE`, r.live===true&&r.chronoAvance===true,
    `live=${r.live} avance=${r.chronoAvance}`);
  /* LA RANGÉE NE DÉBORDE PAS D'UN PIXEL, quelle que soit la largeur de PISTE. C'est ce qui
     manquait : une chip a une largeur incompressible et se coupait net dès que la piste
     rétrécissait ; et le halo de l'épingle sortait de 5 px, donc était rogné — la cible se
     retrouvait amputée du côté du pouce, sans que rien ne le dise. */
  t(`${W} · la rangée ne déborde pas (${r.pistes} colonne(s), piste ${r.piste} px)`,
    r.deborde===0&&r.debordeH===0, `${r.deborde} en largeur, ${r.debordeH} en hauteur`);
  t(`${W} · … et l'épingle garde sa cible de 44 px DANS la rangée`, r.pinOk===true, r.pinBox);
  /* LA MÉTA TIENT ENTIÈRE, à toutes les largeurs de PISTE. Le débordement de la RANGÉE ne suffit
     pas à le prouver : `.dir-sub` est en `overflow:hidden`, donc la rangée reste propre pendant
     que l'information disparaît. On mesure l'ellipse elle-même. */
  t(`${W} · la méta ne déborde sur aucune rangée, même avec des libellés longs`, r.ellipsees===0,
    `${r.ellipsees} sur ${r.n} — reste ${JSON.stringify(r.reste)} px`);
  t(`${W} · … aucun item n'est POUSSÉ hors de la méta`, r.itemsHors===0, `${r.itemsHors} item(s)`);
  t(`${W} · … et la date n'est jamais amputée`, r.dateCoupee===0, `${r.dateCoupee}`);
  /* Et le registre est porté par l'ENCRE, pas par une chip : une chip a une largeur
     incompressible, c'est elle qui poussait la catégorie hors du cadre. */
  /* LA NATURE SE LIT SUR LA RANGÉE (demande utilisateur, d'après la maquette) : en vue « Tout »
     les deux types se mêlent et rien ne disait lequel on allait ouvrir. C'est un item DUR : il ne
     s'abrège jamais — un mot de nature amputé en dirait moins que rien. */
  t(`${W} · chaque rangée dit sa NATURE`,
    r.kinds.length===r.n&&r.kinds.every(k=>k==='Aide'||k==='Protocole'), JSON.stringify(r.kinds.slice(0,3)));
  t(`${W} · … et ce mot n'est jamais abrégé`, r.kindsTronq===0, `${r.kindsTronq}`);
  /* LES RANGÉES DE FILTRES PARTENT DU MÊME x (signalé à l'usage : « Tout » pas aligné). */
  if(W<780)t(`${W} · les rangées de filtres sont alignées`, r.chipsX.length<=1, JSON.stringify(r.chipsX));
  /* LE RAIL A-T-IL UNE POSITION QUI NE DÉPEND PAS DE SON CONTENU ? `center` la fait dépendre du
     nombre de lettres — c'est le défaut signalé (« sa position bouge sans cesse »). */
  if(r.railJc!=='—')t(`${W} · le rail alphabétique est ancré en haut`, r.railJc==='flex-start', r.railJc);
  t(`${W} · « à compléter » n'a plus de fond de chip`,
    /rgba\(0, 0, 0, 0\)|transparent/.test(r.fondTodo||'transparent'), r.fondTodo);
  await page.close();
}

/* UN GESTE DE CHROME NE CHANGE PAS DE VUE (v5.0.0, signalé à l'usage : « fermer la croix d'un
   bandeau efface une des deux invites »). Les binders de l'accueil re-rendaient par
   `renderFiches()` EN DUR, et la vue « Tout » réutilise celui des fiches : fermer un bandeau,
   épingler, ou terminer une session BASCULAIT l'affichage sur les aides seules pendant que
   `state.section` valait toujours 'all' — l'écran et l'état divergeaient.
   ⚠ LE CONTRÔLE DOIT RENCONTRER SON CAS : il faut un PROTOCOLE dans la bibliothèque, sinon
   « Tout » et « Aides » affichent la même chose et le témoin reste vert sur le défaut. Les deux
   fiches d'exemple sont toutes deux des aides. */
console.log('\n══ ACCUEIL · un geste de chrome ne change pas de vue ══');
{
  const page = await br.newPage({viewport:{width:1100,height:950}});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await page.evaluate(async()=>{
    protocols.push(migrateProtocol({id:'pT',title:'Référence témoin',kind:'reference',body:'# x'}));
    await Data.putProtocol(protocols[protocols.length-1]);
    state.section='all';render();});
  await page.waitForTimeout(500);
  const etat=()=>page.evaluate(()=>({section:state.section,
    rangees:document.querySelectorAll('.dir-row').length,
    natures:[...new Set([...document.querySelectorAll('.dir-kind')].map(e=>e.textContent.trim()))]}));
  const av=await etat();
  t('témoin : la vue « Tout » montre les DEUX natures',
    av.section==='all'&&av.natures.length===2, JSON.stringify(av));
  await page.click('[data-pin]');await page.waitForTimeout(600);
  const ap=await etat();
  t('épingler ne bascule pas sur les aides seules',
    ap.section==='all'&&ap.rangees===av.rangees&&ap.natures.length===2, JSON.stringify(ap));
  /* Et la croix d'un bandeau, le geste EXACT qui a été signalé. */
  await page.evaluate(()=>{fiches.length=0;protocols.length=0;
    try{localStorage.removeItem('ac-notice-hidden');}catch(e){}
    state.section='all';render();});
  await page.waitForTimeout(450);
  const c0=await page.evaluate(()=>document.querySelectorAll('.emp-intro').length);
  const x=await page.$('#noticeX');
  if(!x)t('témoin : un bandeau fermable est présent', false, 'aucune croix');
  else{
    t('témoin : un bandeau fermable est présent, et les 2 cartes sont là', c0===2, `${c0} carte(s)`);
    await x.click();await page.waitForTimeout(500);
    const c1=await page.evaluate(()=>({n:document.querySelectorAll('.emp-intro').length,s:state.section}));
    t('fermer un bandeau n\'efface pas une des deux invites',
      c1.n===2&&c1.s==='all', JSON.stringify(c1));}
  await page.close();
}

/* L'ÉTAT VIDE N'OFFRE QUE CE QU'ON PEUT CRÉER LÀ (v5.0.0, signalé à l'usage : en vue « Tout »,
   le titre était neutre mais le texte et le bouton étaient ceux des AIDES seules). Le nombre de
   cartes doit être exactement le nombre de types créables dans la vue courante, et le bouton
   d'une carte doit ouvrir la création DE SON type — `state.section` étant la source unique du
   type dans le dialogue « Créer », c'est lui qu'on mesure, pas l'apparence du dialogue.
   ⚠ ET LA LEÇON NE S'AFFICHE PAS SOUS UN FILTRE : qui cherche sait déjà ce qu'est une aide ; on
   lui doit un résultat, pas un cours. Le témoin construit donc les DEUX cas. */
console.log('\n══ ACCUEIL · l\'état vide n\'offre que ce qu\'on peut créer ici ══');
{
  const page = await br.newPage({viewport:{width:390,height:900}});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  // ⚠ PAS `amorce()` ici : elle POSE les fiches d'exemple, or le sujet mesuré est la bibliothèque
  // VIDE. On traverse l'écran de bienvenue et l'on s'arrête là — c'est le vrai point d'entrée.
  await page.evaluate(()=>{const b=[...document.querySelectorAll('button')]
    .find(x=>/Commencer/.test(x.textContent));if(b)b.click();});
  await page.waitForFunction(()=>document.body.classList.contains('view-home'));
  const lire=()=>page.evaluate(()=>({
    cartes:document.querySelectorAll('.emp-intro').length,
    kinds:[...document.querySelectorAll('[data-emptynew]')].map(b=>b.dataset.emptynew),
    /* Chaque ligne d'anatomie se lit d'un TRAIT : `.empty b{display:block}` la coupait en deux
       (nom sur une ligne, glose sur la suivante) — mesuré par la hauteur de la ligne. */
    coupees:[...document.querySelectorAll('.emp-anat li')]
      .filter(li=>li.getBoundingClientRect().height
        >parseFloat(getComputedStyle(li).lineHeight)*1.9
        &&li.querySelector('b').getBoundingClientRect().width<li.getBoundingClientRect().width*0.9
        &&getComputedStyle(li.querySelector('b')).display!=='inline').length,
    /* Aucun glyphe VIDE : `uiIcon` rend un <svg> sans tracé pour un nom inconnu — un dessin
       absent ne se voit pas à la relecture, seulement à l'écran. */
    icVides:[...document.querySelectorAll('.emp-ic svg')].filter(s=>!s.innerHTML.trim()).length}));
  for(const [sec,att] of [['all',['fiches','protocols']],['fiches',['fiches']],['protocols',['protocols']]]){
    await page.evaluate(s=>{state.section=s;state.q='';state.cat='';render();},sec);
    await page.waitForTimeout(300);
    const r=await lire();
    t(`vue « ${sec} » · ${att.length} carte(s), du ou des types créables ici`,
      r.cartes===att.length&&JSON.stringify(r.kinds)===JSON.stringify(att), JSON.stringify(r.kinds));
    t(`vue « ${sec} » · chaque ligne se lit d'un trait, glyphes présents`,
      r.coupees===0&&r.icVides===0, `${r.coupees} coupée(s), ${r.icVides} glyphe(s) vide(s)`);
  }
  /* LE BOUTON OUVRE LA CRÉATION DE SON TYPE — depuis la vue « Tout », où les deux coexistent.
     ⚠ ON VÉRIFIE QUE LE BOUTON EXISTE AVANT DE LE CLIQUER : un `page.click` sur un sélecteur
     absent lève, et un harnais qui PLANTE en emporte cinq (leçon v4.70.1). Ici l'absence est
     déjà signalée par le témoin de comptage ci-dessus ; celui-ci doit échouer, pas exploser. */
  for(const k of ['protocols','fiches']){
    await page.evaluate(()=>{state.section='all';render();});
    await page.waitForTimeout(250);
    if(!await page.$(`[data-emptynew="${k}"]`)){
      t(`« ${k} » ouvre le dialogue Créer sur SON type`, false, 'bouton absent');
      continue;}
    await page.click(`[data-emptynew="${k}"]`);
    await page.waitForTimeout(350);
    const r=await page.evaluate(()=>({ouvert:document.getElementById('createModal').classList.contains('on'),
      section:state.section}));
    t(`« ${k} » ouvre le dialogue Créer sur SON type`, r.ouvert===true&&r.section===k,
      `ouvert=${r.ouvert} section=${r.section}`);
    await page.keyboard.press('Escape');await page.waitForTimeout(250);
  }
  /* SOUS UN FILTRE : aucune carte, aucun bouton — on doit un résultat, pas un cours. */
  await page.evaluate(()=>{state.section='all';state.q='zzzintrouvable';render();});
  await page.waitForTimeout(350);
  const r=await lire();
  t('sous un filtre, la leçon disparaît (0 carte, 0 bouton)', r.cartes===0&&r.kinds.length===0,
    `${r.cartes} carte(s), ${r.kinds.length} bouton(s)`);
  await page.close();
}

/* L'EXTRAIT DE RECHERCHE TIENT DANS SA RANGÉE (v5.0.0, signalé à l'usage : « en mode recherche
   le texte dépasse des cartes d'accueil »). La boucle ci-dessus mesure le RÉPERTOIRE, où la
   rangée porte un contenu borné (titre + méta) et tient ses 71 px fixes ; en RECHERCHE elle porte
   EN PLUS l'extrait contextuel, et la hauteur fixe le clippait en plein milieu d'une ligne —
   défaut invisible au témoin du répertoire, qui n'entre jamais dans ce mode.
   ⚠ LE CONTRÔLE DOIT RENCONTRER SON CAS, deux fois : il faut qu'un extrait soit RENDU (une
   recherche par titre n'en produit aucun — `searchSnippet` rend alors une chaîne vide, et l'on
   mesurerait une rangée ordinaire), et il faut qu'il soit assez long pour DÉBORDER (un extrait
   d'une ligne tiendrait dans les 71 px et le témoin resterait vert sur le défaut). D'où le terme
   « adrénaline », qui matche dans le CORPS des deux fiches d'exemple. */
console.log('\n══ ACCUEIL · l\'extrait de recherche tient dans sa rangée ══');
for (const W of [320, 360, 390, 700, 1400]) {
  const page = await br.newPage({viewport:{width:W,height:844}});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  // Le VRAI geste : on tape dans le champ de l'en-tête (poser `state.q` à la main court-circuite
  // l'écouteur et le re-rendu, donc mesurerait un écran que personne n'obtient).
  await page.click('#hdrSearch');
  await page.type('#hdrSearch','adrénaline',{delay:15});
  await page.waitForFunction(()=>document.querySelectorAll('.card-snip').length>0,null,{timeout:4000})
    .catch(()=>{});
  const r = await page.evaluate(()=>{
    const rows=[...document.querySelectorAll('.dir-grid.flat .dir-row')];
    return {n:rows.length, snips:document.querySelectorAll('.card-snip').length,
      /* Le contenu tient-il dans la boîte ? `.dir-row` est en `overflow:hidden` : la rangée reste
         PROPRE à l'écran pendant que le texte disparaît — on mesure donc le débordement, jamais
         l'aspect. */
      debordeH:rows.filter(x=>x.scrollHeight>x.clientHeight+1).length,
      /* Et l'extrait lui-même ne doit pas passer sous le bord bas de sa rangée. */
      snipHors:rows.filter(x=>{const s=x.querySelector('.card-snip');
        return s&&s.getBoundingClientRect().bottom>x.getBoundingClientRect().bottom+0.5;}).length,
      /* Rencontre-t-on le cas ? Un extrait sur DEUX lignes est ce qui débordait. */
      deuxLignes:[...document.querySelectorAll('.card-snip')]
        .filter(s=>s.getBoundingClientRect().height>=parseFloat(getComputedStyle(s).lineHeight)*1.8).length,
      /* Le pas de 71 px reste le PLANCHER : la recherche ne rétrécit pas la rangée. */
      minH:Math.min(...rows.map(x=>Math.round(x.getBoundingClientRect().height))),
      /* Deux hauteurs au plus (avec extrait / sans) — jamais N : le rythme n'est pas abandonné. */
      hauteurs:[...new Set(rows.map(x=>Math.round(x.getBoundingClientRect().height)))]};});
  t(`${W} · témoin : des extraits sont rendus`, r.snips>=1, `${r.snips} sur ${r.n} rangée(s)`);
  t(`${W} · témoin : au moins un extrait fait deux lignes`, r.deuxLignes>=1, `${r.deuxLignes}`);
  t(`${W} · l'extrait ne déborde pas de sa rangée`, r.debordeH===0&&r.snipHors===0,
    `${r.debordeH} rangée(s) débordent, ${r.snipHors} extrait(s) hors cadre`);
  t(`${W} · … et la rangée garde son pas de 71 px au minimum`, r.minH>=71,
    `${r.minH} px — hauteurs ${JSON.stringify(r.hauteurs)}`);
  await page.close();
}

console.log('\n══ RÉGRESSIONS · déplacement, flèches, losange ══');
{
  const page = await br.newPage({viewport:{width:1280,height:1000}});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const f=fiches.find(x=>/cardiaque/i.test(x.title))||fiches[0];
    /* 1 — DÉPLACER UN BLOC, par le vrai geste : poignée puis interstice. */
    state.view='edit';state.draft=JSON.parse(JSON.stringify(f));render();await w(500);
    const av=state.draft.blocks.map(b=>b.id).join('|');
    const g=document.querySelector('[data-grab^="b:"]');if(g)g.click();await w(400);
    const nInt=document.querySelectorAll('[data-drop]').length;
    const d=[...document.querySelectorAll('[data-drop]')].pop();if(d)d.click();await w(400);
    const ap=state.draft.blocks.map(b=>b.id).join('|');
    state.edGrab=null;
    /* 2 — LES FLÈCHES DU SCHÉMA : une par lien `next` ET une par option. On compte les chemins
       PORTANT UNE POINTE (`marker-end`) : les autres `path` sont les glyphes et la pointe elle-même. */
    openRead(f.id);await w(400);
    state.readMode='static';state.allTab='schema';render();await w(700);
    const svg=document.querySelector('.flow-scroll svg');
    const fleches=svg?[...svg.querySelectorAll('path')].filter(x=>x.getAttribute('marker-end')).length:0;
    const attendu=f.blocks.filter(b=>b.next).length+f.blocks.reduce((n,b)=>n+((b.options||[]).length),0);
    /* 3 — LE LOSANGE NE DÉBORDE PAS SA RANGÉE. */
    state.readMode='overview';render();await w(400);
    const sb=document.getElementById('sessStart');if(sb)sb.click();await w(700);
    const dec=document.querySelector('.pl-line.dec .n');
    const los=dec?(()=>{const q=dec.getBoundingClientRect(),pr=dec.parentElement.getBoundingClientRect();
      return {gauche:Math.round(q.left-pr.left),haut:Math.round(q.top-pr.top)};})():null;
    return {bouge:av!==ap,nInt,fleches,attendu,los};});
  t('témoin : les interstices de bloc sont bien émis', r.nInt>=2, `${r.nInt}`);
  t('déplacer un BLOC change réellement l’ordre', r.bouge===true);
  t('une flèche par lien `next` ET par option', r.fleches===r.attendu, `${r.fleches} pour ${r.attendu} attendue(s)`);
  t('le losange d’une décision ne déborde pas sa rangée',
    r.los&&r.los.gauche>=0&&r.los.haut>=0, JSON.stringify(r.los));
  await page.close();
}

console.log('\n══ DÉPLIANTS · un tap ne déplace pas l’écran ══');
for (const W of [320, 390]) {
  const page = await br.newPage({viewport:{width:W,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const f=fiches.find(x=>/Anaphylaxie/i.test(x.title))||fiches[0];
    openRead(f.id);await w(400);
    const sb=document.getElementById('sessStart');if(sb)sb.click();await w(700);
    const dockY=()=>{const e=document.getElementById('cbTimers');return e?Math.round(e.getBoundingClientRect().top):null;};
    const y0=Math.round(scrollY),d0=dockY();
    document.getElementById('cbTimers').click();await w(600);
    const sautQuai=Math.round(scrollY)-y0, dockBouge=Math.abs(dockY()-d0);
    const pn=document.querySelector('.rt-panel');
    const sousLeQuai=(()=>{const d=document.getElementById('cbTimers');
      return (d&&pn)?Math.round(pn.getBoundingClientRect().top-d.getBoundingClientRect().bottom):null;})();
    document.getElementById('cbTimers').click();await w(400);        // refermer
    document.querySelector('[data-tknote]').click();await w(600);
    const y1=Math.round(scrollY);
    const j=document.querySelector('.tk-ack-j'); if(j)j.click(); await w(600);
    return {sautQuai,dockBouge,sousLeQuai,panneau:!!pn,
      sautJournal:Math.round(scrollY)-y1,
      lignes:document.querySelectorAll('.tk-ack-r').length};});
  t(`${W} · le panneau s’ouvre bien au tap sur le quai`, r.panneau===true);
  t(`${W} · … SANS déplacer l’écran`, r.sautQuai===0, `${r.sautQuai} px`);
  t(`${W} · … ni le quai lui-même`, r.dockBouge<=1, `${r.dockBouge} px`);
  t(`${W} · … et il se pose SOUS le quai`, r.sousLeQuai!==null&&r.sousLeQuai>=0&&r.sousLeQuai<=60, `${r.sousLeQuai} px`);
  t(`${W} · le journal se DÉPLIE dans la carte, sans défiler`, r.sautJournal===0&&r.lignes>=1,
    `saut ${r.sautJournal} px, ${r.lignes} ligne(s)`);
  await page.close();
}

console.log('\n══ PARCOURS INERTE · les marqueurs sont lisibles ══');
{
  const page = await br.newPage({viewport:{width:1280,height:1000}});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const f=fiches.find(x=>/Anaphylaxie/i.test(x.title))||fiches[0];
    openRead(f.id);await w(400);
    const sb=document.getElementById('sessStart');if(sb)sb.click();await w(700);
    const lum=c=>{const m=String(c).match(/[\d.]+/g)||[0,0,0];
      const v=m.slice(0,3).map(x=>{const u=(+x)/255;return u<=0.03928?u/12.92:Math.pow((u+0.055)/1.055,2.4);});
      return 0.2126*v[0]+0.7152*v[1]+0.0722*v[2];};
    const ratio=(a,b)=>{const l1=lum(a),l2=lum(b);return +(((Math.max(l1,l2)+0.05)/(Math.min(l1,l2)+0.05))).toFixed(2);};
    const badges=[...document.querySelectorAll('.rail-lad .pl-line .n,.read-plan .pl-line .n')]
      .filter(n=>n.textContent.trim()||n.querySelector('svg'))
      .map(n=>{const cs=getComputedStyle(n);
        return {txt:n.textContent.trim()||'✓',r:ratio(cs.color,cs.backgroundColor)};});
    /* Le contrôle doit RENCONTRER SON CAS : sans pastille pleine (bloc courant ou bloc fait) il
       mesurerait des contours gris et resterait vert sur le défaut. */
    const pleines=[...document.querySelectorAll('.rail-lad .pl-line.cur .n,.read-plan .pl-line.cur .n')].length;
    return {badges,pleines,carte:getComputedStyle(document.querySelector('.rail-lad')||document.body).backgroundColor};});
  t('témoin : au moins une pastille PLEINE est mesurée', r.pleines>=1, `${r.pleines}`);
  t('aucun marqueur n’est de la couleur de son propre fond',
    r.badges.length>0&&r.badges.every(b=>b.r>=3), JSON.stringify(r.badges));
  /* La colonne n'est PAS une carte (maquette) : deux niveaux de surface pour un seul objet. */
  t('le parcours n’est pas posé dans une carte blanche',
    /rgba\(0, 0, 0, 0\)|transparent/.test(r.carte), r.carte);
  await page.close();
}

console.log('\n══ QUAI · la structure survit aux ticks ══');
{
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const q = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    openRead(fiches[0].id);await w(400);
    const sb=document.getElementById('sessStart');if(sb)sb.click();await w(600);
    const t=Object.values(Runtime.timers)[0];if(t){t.running=true;t.lastStart=Date.now();t.elapsedMs=0;}
    await w(300);
    const el=document.getElementById('cbTimers');
    let elems=0;
    const mo=new MutationObserver(ms=>{ms.forEach(m=>{if(m.type==='childList')
      m.removedNodes.forEach(nd=>{if(nd.nodeType===1)elems++;});});});
    mo.observe(el,{childList:true,subtree:true});
    /* Le geste : on garde la référence du nœud sous le doigt et l'on regarde s'il survit à des
       ticks. Un `click` n'est émis que si le nœud du `pointerdown` est toujours là. */
    let vivants=0;const n=5;
    for(let i=0;i<n;i++){const cible=el.querySelector('.seg.glb')||el.firstElementChild;
      await w(1100);if(cible&&document.contains(cible))vivants++;}
    mo.disconnect();
    const vals=[...el.querySelectorAll('.seg-t')].map(x=>x.textContent.trim());
    return {elems,vivants,n,vals,txt:el.textContent.replace(/\s+/g,' ').trim()};});
  t('aucun ÉLÉMENT du quai n’est détruit pendant les ticks', q.elems===0, `${q.elems} élément(s) retiré(s)`);
  t('… donc un nœud sous le doigt survit à chaque seconde', q.vivants===q.n, `${q.vivants}/${q.n}`);
  /* Et le quai continue de DIRE l'heure : une structure stable qui n'afficherait plus rien serait
     un progrès parfaitement inutile. Le contrôle rencontre donc son cas. */
  t('… et les valeurs sont bien peintes', q.vals.length>=1&&q.vals.every(v=>/\d/.test(v)), JSON.stringify(q.vals));
  await page.close();
}

console.log('\n══ aidRev · la révision lue pendant le soin ══');
{
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const f=fiches[0]; const revLue=f.updatedAt||0;
    openRead(f.id); await w(400);
    const b=document.getElementById('sessStart'); if(b)b.click(); await w(500);
    const li=document.querySelector('ol.steps li[data-ck]'); if(li)li.click(); await w(400);
    const snap1=snapshotSession(Runtime);
    /* On RÉVISE la fiche après coup : la session archivée doit garder l'ANCIENNE révision. */
    f.updatedAt=revLue+60000;
    const snap2=snapshotSession(Runtime);
    return {revLue,rev1:snap1.aidRev,rev2:snap2.aidRev,
            html:exportSessionReport?'':''};});
  t('la session enregistre la révision de l’aide', r.rev1===r.revLue && r.rev1>0, `${r.rev1} vs ${r.revLue}`);
  t('… et une révision POSTÉRIEURE ne la réécrit pas', r.rev2===r.rev1, `${r.rev1} → ${r.rev2}`);
  await page.close();
}

/* ── RÉENTRÉE · on revient sur le soin, pas sur le préambule ─────────────────────────────────
   Mesuré avant correctif : rouvrir une aide dont la session TOURNE déposait à 456 px du bout à
   320 × 640 (356 à 390 × 844), zéro étape cochable à l'écran. Le témoin mesure les DEUX moitiés,
   et la seconde n'est pas décorative : ouvrir une aide SANS session doit continuer d'arriver en
   HAUT DE FICHE (on s'oriente avant d'agir — condition d'entrée QRH). Un atterrissage qui
   s'appliquerait partout remplacerait un défaut par son symétrique.
   ⚠ ET IL VÉRIFIE QU'IL RENCONTRE SON CAS : sur une aide courte, le bout serait visible depuis le
   haut de page et le contrôle resterait vert sans rien prouver. */
console.log('\n══ RÉENTRÉE · rouvrir une session vive atterrit sur le bout ══');
for (const fmt of [{w:320,h:640},{w:390,h:844}]) {
  const page = await br.newPage({viewport:{width:fmt.w,height:fmt.h},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  await ouvrirFiche(page,/Anaphylaxie/);
  await demarrerSession(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const f=Runtime.fiche;
    const bout=()=>{const c=[...document.querySelectorAll('.ov-block')];return c[c.length-1]||null;};
    /* On avance pour CONSTITUER le cas : un journal d'un seul passage tiendrait à l'écran. */
    for(let i=0;i<6;i++){
      const nb=bout(); if(!nb)break;
      nb.querySelectorAll('li[data-ck]:not(.done)').forEach(e=>e.click()); await w(120);
      const opt=[...nb.querySelectorAll('[data-ovopt]')].find(o=>/Non/.test(o.textContent));
      if(opt){opt.click(); await w(400); continue;}
      const nx=nb.querySelector('[data-ovnext]');
      if(nx&&!nx.hasAttribute('aria-disabled')){nx.click(); await w(400);} else break;}
    // Réouverture depuis l'accueil, session vive.
    state.view='library'; render(); await w(400);
    openRead(f.id); await w(500);
    const etapesVis=()=>{const b=stickBase();
      return [...document.querySelectorAll('ol.steps li[data-ck]')]
        .filter(e=>{const g=e.getBoundingClientRect();return g.top>=b-1&&g.bottom<=innerHeight+1;}).length;};
    const b=stickBase();
    const nb=bout(); const q=nb?nb.getBoundingClientRect():null;
    const vive={aDefiler:q?Math.max(0,Math.round(q.top-b)):null,
                etapes:etapesVis(), scrollY:Math.round(scrollY)};
    /* CONTREFACTUEL — ce qu'on aurait SANS l'atterrissage : on remet en haut de page et l'on
       recompte. C'est cela que l'utilisateur perdait, et c'est non circulaire : le contrôle ne
       vaut que si l'arrivée en haut ne montrait effectivement aucune étape à cocher. */
    scrollTo(0,0); await w(150);
    vive.etapesDepuisLeHaut=etapesVis();
    vive.aDefilerDepuisLeHaut=(()=>{const c=bout();
      return c?Math.max(0,Math.round(c.getBoundingClientRect().top-stickBase())):null;})();
    vive.continuerDepuisLeHaut=(()=>{const n=document.querySelector('[data-ovnext]');
      if(!n)return null; const g=n.getBoundingClientRect();
      return g.top>=stickBase()&&g.bottom<=innerHeight;})();
    // NON-RÉGRESSION : une aide SANS session vive s'ouvre en haut.
    const g=fiches.find(x=>x.id!==f.id);
    let inerte=null;
    if(g){state.view='library'; render(); await w(300); openRead(g.id); await w(500);
          inerte=Math.round(scrollY);}
    return {vive,inerte};});
  const v=r.vive;
  /* Le cas EXISTE si, arrivé en haut de page, on est loin du bout ET que le contrôle
     d'avancement n'est pas atteignable. « 0 étape visible » serait trop fort : à 390 px le haut
     de la carte du bout dépasse déjà sous le pli, deux de ses étapes se voient — mais « Continuer »
     non, et c'est cela qu'on venait chercher. */
  t(`${fmt.w}× le contrôle rencontre son cas (depuis le haut, avancement hors écran)`,
    v.aDefilerDepuisLeHaut>100 && v.continuerDepuisLeHaut===false,
    `${v.aDefilerDepuisLeHaut} px à défiler, Continuer visible=${v.continuerDepuisLeHaut}`);
  t(`${fmt.w}× la réouverture atterrit sur le bout`, v.aDefiler!=null && v.aDefiler<=12,
    `${v.aDefiler} px à défiler`);
  t(`${fmt.w}× … avec au moins une étape cochable à l’écran`, v.etapes>=1, `${v.etapes} étape(s)`);
  t(`${fmt.w}× une aide SANS session s’ouvre toujours en haut`, r.inerte===0, `scrollY=${r.inerte}`);
  await page.close();
}

await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} contrôles doctrine OK${ko?` — ${ko} ÉCHEC(S)`:''}`);
process.exit(ko?1:0);
