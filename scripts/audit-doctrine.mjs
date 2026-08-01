/* LOT 7 — volet DOCTRINE : ECAM / QRH / FAA AC 120-71B, mesuré sur l'app réelle.
   Chaque contrôle traduit une règle de sûreté en invariant observable. */
import { serveApp, moteur, NOM_MOTEUR, ROOT , items} from './harness.mjs';

const { port, srv } = await serveApp();
const br=await moteur().launch();
let ok=0,ko=0;
const t=(nom,cond,det)=>{if(cond){ok++;console.log('  ✓ '+nom);}else{ko++;console.log('  ✗ '+nom+(det?'\n      '+det:''));}};

async function session(w,demarrer){
  const page=await br.newPage({viewport:{width:w,height:820}});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(async(demarrer)=>{
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();
    await new Promise(r=>setTimeout(r,120));
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();
    await new Promise(r=>setTimeout(r,350));
    const c=[...document.querySelectorAll('.card-open')].find(x=>/Arrêt cardiaque/.test(x.textContent));
    c.click();await new Promise(r=>setTimeout(r,150));
    // `demarrer===false` = l'écran d'un INVITÉ : la fiche est ouverte, mais rien n'a démarré
    // localement — c'est le principe même du miroir, et c'est ce qui faisait disparaître le quai.
    if(demarrer!==false){document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,350));}},demarrer);
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
  const a=await snap(), pa=await geo('modeSeg'), ra=await geo('refBtn');
  // faire varier l'état : ajouter des minuteurs (la partie VARIABLE du quai)
  await page.evaluate(async()=>{
    const add=[...document.querySelectorAll('.rt-add,.add-line')];
    for(const b of add.slice(0,3)){b.click();await new Promise(r=>setTimeout(r,120));}});
  await page.waitForTimeout(300);
  const b=await snap(), pb=await geo('modeSeg'), rb=await geo('refBtn');
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
        return {right:+right.toFixed(1),vw:innerWidth,
          bordInterne:+(db.right-parseFloat(ds.paddingRight)*zf).toFixed(1),
          eff:Math.round(innerWidth/zf),
          libelles:btns.map(b=>b.textContent.trim()).join('|')};},z);
      t(`${w} px à ${z} % : aucun bouton de commande rogné`,
        r.right<=r.vw+0.5&&r.right<=r.bordInterne+0.5,
        `bord droit ${r.right} px, bord interne ${r.bordInterne} px, viewport ${r.vw} px (${r.eff} px effectifs)`);
      /* AUCUN LIBELLÉ N'EST SACRIFIÉ POUR TENIR : c'est la seconde moitié de l'invariant, et sans
         elle un futur « correctif » pourrait faire passer le premier en masquant les mots — ce que
         la doctrine interdit explicitement (« deux pictogrammes voisins sans mot se confondent sous
         stress »). On exige que chaque bouton porte encore du texte. */
      t(`${w} px à ${z} % : les libellés sont intacts`,
        /Un bloc/.test(r.libelles)&&/Toute la fiche/.test(r.libelles)&&/Cons/.test(r.libelles),
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
        /Un bloc/.test(r.libelles)&&/Toute la fiche/.test(r.libelles)&&/Cons/.test(r.libelles),
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
    document.querySelector('#modeSeg [data-readmode="static"]').click(); await w(400);
    const apStat=top(), yStat=window.scrollY;
    document.querySelector('#modeSeg [data-readmode="dynamic"]').click(); await w(400);
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
  await page.evaluate(async () => {
    const b = [...document.querySelectorAll('button')].find(x => /Commencer/.test(x.textContent)); if (b) b.click();
    await new Promise(r => setTimeout(r, 120));
    const s = [...document.querySelectorAll('button')].find(x => x.textContent.includes("fiches d'exemple")); if (s) s.click();
    await new Promise(r => setTimeout(r, 400));
    const c = [...document.querySelectorAll('.card-open')].find(x => /Arrêt cardiaque/.test(x.textContent));
    c.click(); await new Promise(r => setTimeout(r, 200));
    document.getElementById('sessStart').click(); await new Promise(r => setTimeout(r, 350));
  });
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
  await page.evaluate(async()=>{const wt=m=>new Promise(r=>setTimeout(r,m));
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await wt(200);
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await wt(700);});
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
  await page.evaluate(async()=>{const wt=m=>new Promise(r=>setTimeout(r,m));
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await wt(200);
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await wt(700);});
  const r = await page.evaluate(async()=>{const wt=m=>new Promise(r=>setTimeout(r,m));
    const f=fiches.find(x=>/Anaphylaxie/i.test(x.title))||fiches[0]; openRead(f.id); await wt(400);
    const b=document.getElementById('sessStart'); if(b)b.click(); await wt(600);
    const seg=[...document.querySelectorAll('#modeSeg .seg-btn')].map(e=>e.textContent.trim());
    const planBtn=!!document.getElementById('planBtn');
    document.querySelector('#modeSeg [data-readmode="static"]').click(); await wt(600);
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
    return {seg,planBtn,ong,defaut,pageOk,debord,cible,parc,zAv,zAp,peint,
            navBouge:(state.nav||[]).length!==navAv,
            cocheApres:Object.keys(state.checked||{}).filter(k=>state.checked[k]).length,cocheAvant:coche};});
  t(`${w} · l'axe nomme des DENSITÉS, plus des présentations`,
    r.seg.join('|')==='Un bloc|Toute la fiche', r.seg.join('|'));
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
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await w(200);
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await w(800);});
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const pr=blankProtocol();pr.title='Procédure de décontamination';
    protocols.push(migrateProtocol(pr));await persist();render();await w(600);
    const n=()=>document.querySelectorAll('.dir-row').length;
    /* v5.0.0, lot M4 : le type n'est plus une TAB BAR à pastille glissante mais une rangée de
       CHIPS, comme la bibliothèque et la catégorie — il est devenu un filtre parmi les filtres.
       Ce qui se mesure change donc de FORME mais pas de FOND : trois crans, « Tout » par défaut,
       chaque cran filtre ce qu'il annonce. La position de pastille est remplacée par l'état `on`,
       qui est le canal réel de la sélection sur une chip. */
    const px=()=>{const e=document.querySelector('.typebar [data-section].on');return e?(e.dataset.section||null):null;};
    const crans=[...document.querySelectorAll('.typebar [data-section]')].map(e=>e.textContent.trim());
    const actif=(document.querySelector('.typebar [data-section].on')||{}).textContent||'';
    const tout=n(),pTout=px();
    document.querySelector('.typebar [data-section="fiches"]').click(); await w(500);
    const aides=n(),pAides=px();
    document.querySelector('.typebar [data-section="protocols"]').click(); await w(500);
    const prot=n(),pProt=px();
    document.querySelector('.typebar [data-section="all"]').click(); await w(500);
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
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await w(200);
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await w(800);});
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
console.log('\n══ ACCUEIL · la rangée a un rythme régulier ══');
for (const W of [330, 390, 700, 1000, 1400, 1600]) {
  const page = await br.newPage({viewport:{width:W,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await w(200);
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await w(900);});
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    /* Une session EN COURS sur la première fiche : sans elle, le contrôle du chrono vivant ne
       rencontrerait pas son cas et resterait vert sur son absence. */
    const f=fiches[0];openRead(f.id);await w(400);
    const sb=document.getElementById('sessStart');if(sb)sb.click();await w(600);
    /* ⚠ LE CONTRÔLE DOIT RENCONTRER SON CAS. Mesurer les fiches d'EXEMPLE ne prouvait rien : leur
       code fait trois caractères et leur catégorie un mot — la rangée ne pouvait pas déborder, et
       le témoin restait vert pendant qu'un code de trente caractères effaçait la date chez
       l'utilisateur. On rend donc TOUT ce qui peut être long, long. */
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
      liseCat:!!document.querySelector('.dir-row[style*="--catcol"]'),
      pastille:document.querySelectorAll('.dir-row .cat-dot').length,
      live:!!document.querySelector('.dir-row.live'),
      chronoAvance:live?live.textContent.trim()!==av:false};});
  t(`${W} · témoin : plusieurs rangées sont mesurées`, r.n>=2, `${r.n}`);
  t(`${W} · toutes les rangées ont la MÊME hauteur`, r.hauteurs.length===1, JSON.stringify(r.hauteurs));
  t(`${W} · … et rien n'en déborde`, r.deborde===0, `${r.deborde} rangée(s)`);
  t(`${W} · le titre reste sur l'échelle typographique`,
    r.corps.length===1&&['15.5px','15.5'].indexOf(r.corps[0])>=0, JSON.stringify(r.corps));
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
  t(`${W} · « à compléter » n'a plus de fond de chip`,
    /rgba\(0, 0, 0, 0\)|transparent/.test(r.fondTodo||'transparent'), r.fondTodo);
  await page.close();
}

console.log('\n══ RÉGRESSIONS · déplacement, flèches, losange ══');
{
  const page = await br.newPage({viewport:{width:1280,height:1000}});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await w(200);
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await w(800);});
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
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await w(200);
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await w(800);});
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
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await w(200);
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await w(800);});
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
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await w(200);
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await w(800);});
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
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const b=[...document.querySelectorAll('button')].find(x=>/Commencer/.test(x.textContent));if(b)b.click();await w(200);
    const s=[...document.querySelectorAll('button')].find(x=>x.textContent.includes("fiches d'exemple"));if(s)s.click();await w(800);});
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

await br.close();srv.close();
console.log(`\n${ok}/${ok+ko} contrôles doctrine OK${ko?` — ${ko} ÉCHEC(S)`:''}`);
process.exit(ko?1:0);
