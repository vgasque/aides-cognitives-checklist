/* LOT 7 — volet DOCTRINE : ECAM / QRH / FAA AC 120-71B, mesuré sur l'app réelle.
   Chaque contrôle traduit une règle de sûreté en invariant observable. */
import { serveApp, moteur, NOM_MOTEUR, ROOT , items, amorce, ouvrirFiche, demarrerSession, secRunner } from './harness.mjs';
import { readFile } from 'node:fs/promises';

const { port, srv } = await serveApp();
const br=await moteur().launch();
/* Sections ciblables (v5.4.4) : `--grep <motif>` rejoue les seules sections dont le nom matche,
   `--shard k/n` une tranche (le lanceur découpe la passe complète ainsi). Sans argument, rien ne
   change — mêmes sections, même ordre, mêmes en-têtes. cf. secRunner (harness.mjs). */
const sec=secRunner();
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
await sec('ECAM · constance positionnelle du quai', async () => {
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
  const nAv=await page.evaluate(()=>Object.keys(Runtime.timers).length);
  await page.evaluate(async()=>{
    /* Deux taps par minuteur depuis la v5.6 : la porte déplie, la durée crée. Sans le second, le
       nombre de minuteurs ne bougeait pas — et ce témoin, qui vérifie que le quai ne se déplace
       pas QUAND L'ÉTAT VARIE, ne rencontrait plus son cas. */
    for(let i=0;i<3;i++){
      const b=document.querySelector('[data-rtadd]');if(!b)break;
      b.click();await new Promise(r=>setTimeout(r,120));
      const d=document.querySelector('[data-rtnew]');if(!d)break;
      d.click();await new Promise(r=>setTimeout(r,150));}});
  await page.waitForTimeout(300);
  const nAp=await page.evaluate(()=>Object.keys(Runtime.timers).length);
  t('témoin : l\'état a bien varié (minuteurs ajoutés)', nAp>nAv, `${nAv} → ${nAp}`);
  const b=await snap(), pb=await geo('allBtn'), rb=await geo('refBtn');
  t('ordre du quai identique quel que soit l\'état', JSON.stringify(a)===JSON.stringify(b), a+'\n      → '+b);
  t('axe de densité immobile (px)', pa!==null&&pa===pb, `${pa} → ${pb}`);
  t('bouton Réf. immobile (px)', ra===rb, `${ra} → ${rb}`);
  // Débordement JAMAIS silencieux : on fait ÉCHOIR 3 minuteurs d'intervalle, le quai n'en
  // montre que 2 en large — le 3ᵉ doit être annoncé par un « +n », jamais escamoté.
  const ov=await page.evaluate(async()=>{
    const ids=Object.keys(Runtime.timers);
    /* ⚠ LA PORTE DÉPLIE, PUIS CRÉE (v5.6, planche 11h) : un tap ne pose plus un minuteur, il ouvre
       le choix de durée. Ce témoin comptait sur « un tap = un minuteur » et sa boucle tournait
       DÉFINITIVEMENT — un `while` sans borne dans un `page.evaluate` est un blocage en attente.
       Deux corrections : on suit le VRAI geste (deux taps), et la boucle est BORNÉE — un témoin
       ne doit jamais pouvoir pendre, sinon c'est la passe entière qu'il emporte. */
    for(let n=0;ids.length<3&&n<6;n++){
      const b=document.querySelector('[data-rtadd]');if(!b)break;
      b.click();await new Promise(r=>setTimeout(r,150));
      const d=document.querySelector('[data-rtnew]');if(!d)break;
      d.click();await new Promise(r=>setTimeout(r,200));
      ids.splice(0,ids.length,...Object.keys(Runtime.timers));}
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
});

// ══ AC 120-71B — les memory items ne sont JAMAIS derrière un clic ═══════════
await sec('AC 120-71B · memory items en accès direct', async () => {
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
});

// ══ ECAM — naviguer ≠ agir ; le plan ne coche pas, ne démarre pas ══════════
await sec('ECAM · naviguer ≠ agir', async () => {
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
});

// ══ ECAM — aucune notification flottante pendant un soin ═══════════════════
await sec('ECAM · pas d\'alerte flottante en session', async () => {
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
});

/* ══ LE MENU ⋯ TIENT DANS L'ÉCRAN, MARGE DU MATÉRIEL COMPRISE (v4.73.2) ═════════════════════════
   Signalé deux fois à l'usage : d'abord en fenêtre basse, puis « pareil, menu ⋯ tronqué » en grande
   police. Il porte jusqu'à seize rangées, et à 130 % chacune passe sur deux ou trois lignes — les
   dernières, dont « Terminer la session… », tombaient hors de l'écran SANS défilement, donc
   INATTEIGNABLES en silence. On mesure les deux moitiés de l'invariant : la boîte tient dans la
   zone visible ET la dernière rangée est réellement atteignable une fois défilé au bout.
   `--sab` est FORCÉE à 34 px sur un tour : c'est la bande de l'indicateur d'accueil d'un iPhone,
   que `visualViewport.height` INCLUT — le terme qui manquait, et qu'un moteur de bureau ne
   présente jamais. Sans ce tour, le contrôle serait aveugle au défaut effectivement observé. */
await sec('Chrome · le menu ⋯ tient dans l\'écran (390/430 × 4 tailles de texte)', async () => {
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
});

// ══ ECAM — LE DOCK DE SESSION SANS ROGNAGE (320/360/375/390 × 4 tailles de texte) ═══════════
// L'ancêtre de cette section mesurait `#crisisCtrl`, la rangée de commandes HAUTE. Le lot 2 de la
// refonte v5.6 l'a remplacée par le DOCK BAS : l'invariant, lui, ne change pas d'un mot — aucun
// contrôle de la zone de crise n'est rogné, à aucune largeur servie ni à aucune taille de texte,
// ET aucun libellé n'est sacrifié pour y parvenir. C'est la seconde moitié qui compte : sans elle
// un « correctif » passerait le premier contrôle en masquant les mots, ce que la doctrine
// interdit (« deux pictogrammes voisins sans mot se confondent sous stress »).
// CE QUI A CHANGÉ DANS LA MESURE, et pourquoi : (1) la cible est `#sessionDock .sd-in` ;
// (2) l'enroulement n'existe plus — les quatre touches sont de largeur ÉGALE, il n'y a rien à
// ajuster, donc plus de bande 430→441 à surveiller ; on mesure à la place que les quatre touches
// tiennent bien sur UNE rangée ; (3) A2 : sous 360 px les deux OUVERTURES passent au glyphe seul
// (leur `aria-label` reste), les deux GESTES gardent leurs mots — le contrôle des libellés est
// donc borné aux largeurs ≥ 360, et le nom accessible est vérifié partout.
await sec('ECAM · dock de session sans rognage (320/360/375/390)', async () => {
{
  const page=await session(360);
  const lire=()=>page.evaluate(()=>{
    const din=document.querySelector('#sessionDock .sd-in');
    const btns=[...din.querySelectorAll('button')].filter(b=>b.offsetParent);
    const db=din.getBoundingClientRect(),ds=getComputedStyle(din);
    const zf=(parseFloat(document.documentElement.style.zoom)||100)/100;
    const tops=new Set(btns.map(b=>Math.round(b.getBoundingClientRect().top)));
    return {right:+Math.max(...btns.map(b=>b.getBoundingClientRect().right)).toFixed(1),
      vw:innerWidth,doc:document.documentElement.scrollWidth,
      bordInterne:+(db.right-parseFloat(ds.paddingRight)*zf).toFixed(1),
      deborde:+(din.scrollWidth-din.clientWidth).toFixed(1),
      rangs:tops.size,n:btns.length,
      eff:Math.round(innerWidth/zf),
      libelles:btns.map(b=>b.textContent.trim()).join('|'),
      aria:btns.map(b=>b.getAttribute('aria-label')||b.textContent.trim()).join('|')};});
  for(const w of [320,360,375,390]){
    await page.setViewportSize({width:w,height:820});
    await page.waitForTimeout(220);
    const r=await lire();
    t(`aucune touche du dock hors écran à ${w} px`, r.right<=r.vw&&r.doc<=r.vw,
      `bord droit ${r.right} px / viewport ${r.vw} px`);
    t(`aucun rognage par le conteneur à ${w} px`, r.right<=r.bordInterne+0.5&&r.deborde<=0.5,
      `dernière touche à ${r.right} px, bord interne ${r.bordInterne} px, débordement ${r.deborde} px`);
    t(`les quatre touches tiennent sur UNE rangée à ${w} px`, r.rangs===1&&r.n===4,
      `${r.n} touche(s) sur ${r.rangs} rangée(s)`);
    /* A2 — à 320 px les OUVERTURES perdent leur étiquette, jamais leur nom accessible ; les
       GESTES gardent leurs mots à toutes les largeurs, parce qu'ils ÉCRIVENT. */
    t(`le nom accessible de chaque touche est intact à ${w} px`,
      /Tout voir|Revenir|bloc/i.test(r.aria)&&/Consulter/i.test(r.aria)
      &&/Noter/i.test(r.aria)&&/omplication/i.test(r.aria), r.aria);
    if(w>=360) t(`les libellés visibles sont intacts à ${w} px`,
      /Tout voir|Un bloc/i.test(r.libelles)&&/Consulter/i.test(r.libelles), r.libelles);
  }
  /* SOUS LA PLUS GRANDE TAILLE DE TEXTE — le trou de couverture qui avait produit le défaut de la
     v4.73.1 : le réglage de taille du texte est un `zoom` sur `<html>`, la place réellement
     disponible vaut `largeur ÷ zoom` (331 px sur un écran de 430 à 130 %), et AUCUN palier
     `max-width` ne s'y déclenche puisqu'une media query mesure la fenêtre du PÉRIPHÉRIQUE. */
  for(const w of [390,430]){
    await page.setViewportSize({width:w,height:820});
    for(const z of [90,100,115,130]){
      await page.evaluate(async(z)=>{applyZoom(z);render();await new Promise(x=>setTimeout(x,260));},z);
      const r=await lire();
      t(`${w} px à ${z} % : aucune touche du dock rognée`,
        r.right<=r.vw+0.5&&r.right<=r.bordInterne+0.5,
        `bord droit ${r.right} px, bord interne ${r.bordInterne} px, viewport ${r.vw} px (${r.eff} px effectifs)`);
      t(`${w} px à ${z} % : le dock tient sur UNE rangée`, r.rangs===1,
        `${r.n} touche(s) sur ${r.rangs} rangée(s)`);
      t(`${w} px à ${z} % : les noms accessibles sont intacts`,
        /Tout voir|Revenir|bloc/i.test(r.aria)&&/Consulter/i.test(r.aria), r.aria);
    }
  }
  await page.evaluate(()=>applyZoom(100));
  await page.close();
}
});

/* LA BASCULE GUIDÉ ↔ STATIQUE GARDE LE BLOC COURANT (v4.74.2, signalé à l'usage : « comment
   améliorer le passage guidé/statique lorsqu'on a déjà scrollé ? »). Avant : `scrollTo(0,0)`
   systématique — et conserver `scrollY` n'aurait rien voulu dire non plus, les deux vues n'ayant
   pas la même hauteur. La seule ancre qui EXISTE des deux côtés est le bloc courant, marqué `.cur`
   dans les deux vues. On mesure la DÉRIVE en pixels, comme pour toutes les mécaniques d'ancrage du
   projet, et l'on vérifie le repli : sans bloc courant à l'écran, on repart du haut. */
await sec('ECAM · bascule guidé ↔ statique ancrée sur le bloc courant', async () => {
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
});

// La MÊME règle vaut hors crise : un débordement silencieux reste un débordement. L'ÉDITEUR
// sortait « ⋯ » de 6,2 px à 320 px (bouton VISIBLE, donc pixels inatteignables) — le commentaire
// du CSS visait 360 et le tenait, personne n'avait mesuré en dessous.
await sec('ECAM · barre d\'éditeur sans rognage (320/360)', async () => {
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
});

// ══ WCAG 2.3.3 / projet — mouvement inhibé sous prefers-reduced-motion ═════
await sec('WCAG · prefers-reduced-motion', async () => {
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
});

// ══ LOT « PAGE » — LA FEUILLE NE SE REFLUE PAS, ELLE SE MET À L'ÉCHELLE ═══════════════════════
// ⚠ CETTE SECTION A CHANGÉ DE PROPRIÉTÉ, PAS DE SUJET (v5.10.0). Elle mesurait les BANDES-QUESTIONS
// COLLANTES et leurs décalages cumulés : un mécanisme qui existait pour un cas — la branche EMPILÉE
// sous 640 px, où la question sortait de l'écran pendant qu'on lisait ses étapes (844 px de contenu
// mesurés sans elle en v4.13.1). Le lot Page supprime l'empilement : la feuille a une largeur
// d'AUTEUR, elle garde sa géométrie aux trois formats et c'est l'échelle qui s'adapte. Il n'y a
// donc plus de branche empilée, plus de question qui s'échappe, et plus de pile de décalages.
// Ce qu'on mesure désormais est ce que le lot PROMET, et c'est la définition du fini du brief :
// une seule grille (jamais imbriquée), la même géométrie et le même texte aux trois largeurs.
await sec('Lot Page · une seule grille, la même image aux trois formats', async () => {
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
  const mesure=async page=>page.evaluate(()=>{
    const sheet=document.querySelector('.sv-sheet'),algo=document.querySelector('.sv-algo');
    const cs=algo?getComputedStyle(algo):null;
    return {
      largeur:sheet?sheet.offsetWidth:0,
      pistes:cs?cs.gridTemplateColumns.split(/\s+/).filter(Boolean).length:0,
      imbriquees:document.querySelectorAll('.sv-algo [style*="display:grid"]').length,
      // La PLACE de chaque nœud : c'est elle qui doit être identique d'un format à l'autre.
      places:[...(algo?algo.children:[])].map(e=>e.style.gridColumn+'@'+e.style.gridRow).join(' '),
      // L'ordre du DOM et le texte : le test que le brief demande explicitement.
      texte:sheet?sheet.textContent.replace(/\s+/g,' ').trim():'',
      // Les branches restent CÔTE À CÔTE : deux options d'une même décision partagent leur ligne.
      opts:[...(algo?algo.querySelectorAll('.sv-opt'):[])].map(e=>Math.round(e.getBoundingClientRect().top)).length};});
  const p360=await openStatic(360,640), r360=await mesure(p360);
  const p768=await openStatic(768,1024), r768=await mesure(p768);
  const p1280=await openStatic(1280,900), r1280=await mesure(p1280);
  /* INVARIANT 1 DU BRIEF — le test le plus simple et le plus décisif : une seconde grille dans
     `.sv-algo` reconstruirait la division par la profondeur que le lot existe pour supprimer. */
  t('aucune grille imbriquée dans .sv-algo, aux trois formats',
    r360.imbriquees===0&&r768.imbriquees===0&&r1280.imbriquees===0,
    JSON.stringify([r360.imbriquees,r768.imbriquees,r1280.imbriquees]));
  t('témoin : la feuille est rendue et porte des nœuds placés',
    r1280.places.length>0&&r1280.largeur>0, JSON.stringify({l:r1280.largeur,n:r1280.places.length}));
  t('la feuille garde sa largeur d\'AUTEUR aux trois formats (aucun reflux)',
    r360.largeur===r768.largeur&&r768.largeur===r1280.largeur,
    JSON.stringify([r360.largeur,r768.largeur,r1280.largeur]));
  t('six pistes partout — la grille est un fait de la fiche, pas de l\'écran',
    r360.pistes===6&&r768.pistes===6&&r1280.pistes===6,
    JSON.stringify([r360.pistes,r768.pistes,r1280.pistes]));
  t('la MÊME image : chaque nœud à la même place aux trois largeurs',
    r360.places===r768.places&&r768.places===r1280.places);
  /* INVARIANT 5 — l'ordre du DOM est identique aux trois paliers : les paliers sont des GRILLES,
     jamais un réordonnancement (un lecteur d'écran lit la même suite partout). */
  t('le même texte, dans le même ordre, aux trois largeurs',
    r360.texte===r768.texte&&r768.texte===r1280.texte,
    'longueurs '+JSON.stringify([r360.texte.length,r768.texte.length,r1280.texte.length]));
  /* ⚠ LA COLONNE D'ÉTAT NE DÉMÉNAGE PAS POUR FAIRE PLACE À LA PAGE — CONTRÔLE DE NON-RÉGRESSION
     (audit externe v5.10.1). `.pg-wide` a fait céder cette colonne le temps d'une itération, pour
     rendre à la feuille sa largeur d'auteur ; refusé à l'usage (« le volet noter l'heure reste
     petit, et les minuteurs apparaissent en bas de la page »). Déplacer une surface d'ÉTAT VIVE
     pendant un soin coûte plus cher qu'un défilement horizontal sur une surface de consultation.
     Ce qu'on mesure ici est donc la propriété qui a été choisie : en voie large, l'état reste dans
     SA colonne, à droite du document — quel que soit l'onglet. */
  const col=await p1280.evaluate(()=>{const side=document.querySelector('.read-side');
    const rm=document.querySelector('.read-main');
    if(!side||!rm)return {absent:true};
    const s=side.getBoundingClientRect(),m=rm.getBoundingClientRect();
    return {aDroite:s.left>=m.right-1,memeRangee:Math.abs(s.top-m.top)<200,
      sx:Math.round(s.left),mr:Math.round(m.right)};});
  t('1280 · la colonne d\'état reste À DROITE du document, jamais dessous',
    col.absent!==true&&col.aDroite===true&&col.memeRangee===true, JSON.stringify(col));
  await p360.close();await p768.close();await p1280.close();
}
});
/* ⚠ v5.6 — CETTE SECTION A CHANGÉ DE PORTEUR, PAS D'OBJET. Elle mesurait la vue GUIDÉE
   (`navSection`), qui n'était plus atteinte que par les fiches mono-bloc — et celles-ci rendent
   désormais la CARTE de travail comme toutes les autres (la justification « les deux vues y
   seraient identiques » datait de v4.16.0 et était fausse depuis la refonte : cf. la section
   « une fiche d'un seul bloc »). L'INVARIANT qu'elle protège, lui, n'a pas bougé d'un mot, et
   c'est le défaut v4.42.0 : décocher après « Terminer » doit retirer la bannière ET rendre le
   bouton d'avancement. On le mesure donc sur le porteur d'aujourd'hui. */
// ══ Le RENDU GUIDÉ, jusqu'ici couvert par RIEN ═══════════════════════════════
// `grep -rn 'nav-wrap\|navNext\|bindNavEvents' tests.html scripts/` rendait 0 : la vue guidée
// (celle d'une fiche SANS algorithme — c'est-à-dire ce que produit `blankFiche()`, donc toute
// fiche neuve) n'était mesurée nulle part. C'est ce trou qui a laissé vivre le défaut v4.42.0 :
// décocher après « Terminer l'algorithme » laissait la bannière de fin à l'écran, parce que le
// reset de `state.flowEnded` était enfermé dans un `if(nn)` alors que `#navNext` n'existe
// justement plus à cet instant. Le journal, lui, faisait les deux — la divergence entre les deux
// copies du cochage était invisible faute de sonde.
await sec('Rendu guidé · décocher annule la fin de l\'algorithme', async () => {
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
    /* Une fiche SANS branchement n'a pas de bascule de format — c'est la part juste de la
       doctrine d'origine — mais elle rend bien la carte de travail. */
    const guide=!document.querySelector('#readTopSeg')&&!!document.querySelector('.ov-block');
    const av=()=>document.querySelector('[data-ovnext],[data-ovend],#navNext');
    /* ⚠ ON RE-INTERROGE LE DOM À CHAQUE COCHE : la carte du journal se repeint, donc une liste
       collectée d'avance ne contient plus que des nœuds détachés — on n'en cochait qu'un seul, et
       le bouton restait « Cochez les étapes restantes ». */
    /* ⚠ ON RE-INTERROGE LE DOM À CHAQUE COCHE : la carte du journal se repeint, donc une liste
       collectée d'avance ne contient plus que des nœuds détachés. */
    for(let g=0;g<12;g++){
      const li=[...document.querySelectorAll('[data-ck]')].find(x=>!x.classList.contains('done'));if(!li)break;
      li.dispatchEvent(new MouseEvent('click',{bubbles:true}));
      await new Promise(r=>setTimeout(r,300));}
    const nn=av();if(nn)nn.click();
    await new Promise(r=>setTimeout(r,350));
    const finActee=!!document.querySelector('.flow-end')&&state.flowEnded===true;
    document.querySelector('[data-ck]').click();await new Promise(r=>setTimeout(r,400));
    return {guide,finActee,flowEnded:state.flowEnded,
      banniere:!!document.querySelector('.flow-end'),bouton:!!av()};});
  t('une fiche sans branchement rend la CARTE, et sans bascule de format',r.guide);
  t('« Terminer l\'algorithme » acte la fin (bannière + drapeau)',r.finActee);
  t('décocher remet state.flowEnded à false',r.flowEnded===false);
  t('décocher retire la bannière « Algorithme terminé »',r.banniere===false,'bannière encore présente');
  t('décocher fait revenir le bouton d\'avancement',r.bouton===true,'bouton d\'avancement absent');
  await page.close();
}
});

// ══ ECAM — « rien ne bouge sous le doigt » : le RÉSIDU d'ancrage ═══════════
// Le motif « mesurer, re-rendre, compenser » vivait en QUATRE copies dont UNE SEULE renvoyait son
// résidu (v4.45.0 : `keepAnchor`, source unique). L'invariant le plus cité du projet devient donc
// mesurable — encore faut-il le mesurer. Le résidu est BORNÉ par le haut de page : on défile
// exprès avant le geste, sinon `scrollBy` ne peut pas descendre sous 0 et le contrôle mesurerait
// la limite structurelle au lieu de l'ancrage (cf. la doctrine de `state.confOpen`).
await sec('ECAM · ancrage — résidu nul au geste de première action', async () => {
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
  /* ⚠ v5.6 — LE PREMIER GESTE N'EST PLUS UN COCHAGE. Avant la session, la colonne montre le
     PARCOURS INERTE (maquettes 1b/1c) : il n'y a plus de case à cocher tant qu'on n'a pas
     confirmé le tableau, et le geste d'entrée est la touche du dock. Ce que ce contrôle mesure
     — « un re-rendu de session ne déplace pas d'un pixel l'élément touché » (ECAM, v4.4.0) —
     n'a pas changé d'un mot : c'est son DÉCLENCHEUR qui a changé. On démarre donc par le vrai
     geste, puis on coche : le cochage reste le cas le plus exposé, puisqu'il re-rend le journal
     sous le doigt. */
  const a=await page.evaluate(async()=>{
    const f=fiches.find(x=>/Arrêt cardiaque/.test(x.title))||fiches[0];
    openRead(f.id);await new Promise(r=>setTimeout(r,350));
    document.getElementById('sessStart').click();await new Promise(r=>setTimeout(r,500));
    /* ⚠ LE DÉCLENCHEUR A CHANGÉ, PAS L'INVARIANT (v5.6). Le geste d'entrée n'est plus un COCHAGE
       — avant la session, la colonne montre le parcours inerte, il n'y a pas de case — et il ne
       passe pas par `keepAnchor` mais par un ATTERRISSAGE mesuré (`startSessionGesture`, couvert
       par la section « DÉMARRAGE · le haut du premier bloc est visible »). Ce que ce bloc mesure
       reste ce qu'il a toujours mesuré : « un re-rendu de session ne déplace pas d'un pixel
       l'élément touché » (ECAM, v4.4.0). Son cas le plus exposé est désormais l'AVANCEMENT — on
       coche tout, on presse « Continuer », et le journal se recompose SOUS le doigt. */
    document.querySelectorAll('ol.steps li[data-ck]').forEach(li=>li.click());
    await new Promise(r=>setTimeout(r,300));
    window.scrollTo(0,600);await new Promise(r=>setTimeout(r,250));
    window.__anc=[];
    const nx=document.querySelector('[data-ovnext]');if(nx)nx.click();
    await new Promise(r=>setTimeout(r,600));return window.__anc;});
  t('avancement : l\'ancrage est bien invoqué',a.length>0,'aucun appel de keepAnchor');
  /* ⚠ ET ON N'EN DEMANDE PAS PLUS SUR CE DÉCLENCHEUR (v5.6). « PAS MESURÉ » N'EST PAS « N'A PAS
     BOUGÉ » : si l'ancre DISPARAÎT pendant le re-rendu, `keepAnchor` ne peut rien compenser et la
     sonde ne peut calculer aucune dérive — or `Math.abs(null)` vaut 0, donc un contrôle de dérive
     passerait au VERT sans avoir rien mesuré (leçon v4.31.1). Sur un AVANCEMENT, c'est le cas
     NORMAL et non un défaut : R6 transforme le passage qu'on vient d'achever en rangée
     d'historique, donc l'ancre visée n'existe plus par construction. La compensation, elle, est
     faite par `ovAdvanceRender` sur l'instance du geste (dérive mesurée 0 px, v4.16.3).
     Ce qui reste STRICTEMENT mesurable ici est donc « l'ancrage est invoqué » ; la dérive, elle,
     est mesurée juste en dessous sur le rendu GUIDÉ, où l'ancre survit au re-rendu. */
  /* LE RE-RENDU CIBLÉ OÙ L'ANCRE SURVIT — c'est ici que la DÉRIVE est réellement mesurable.
     ⚠ v5.6 : ce contrôle passait par `renderNavOnly` sur une fiche mono-bloc, seul reste de la
     vue guidée ; celle-ci rend désormais la carte de travail comme les autres. Le geste qui
     re-rend le journal SANS avancer — donc en gardant l'ancre — est DÉCOCHER après que la fin a
     été actée (`ovAfterCheck` : « seul chemin qui RE-REND »). L'invariant ne bouge pas, son
     déclencheur est simplement celui d'aujourd'hui. */
  const g=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    /* ⚠ LA FICHE DOIT POUVOIR DÉFILER LARGEMENT, ET C'EST UNE CONDITION DE MESURE (v5.6). Avec six
       étapes, le document faisait 982 px pour une fenêtre de 900 : `scrollTo(0,300)` retombait à
       82, c'est-à-dire au MAXIMUM. Or décocher après la fin retire la bannière de fin — la page
       raccourcit, le navigateur RABAT le défilement, et tout glisse de la hauteur perdue. Aucune
       compensation ne peut rien contre un rabat de fin de page : le témoin mesurait alors le
       navigateur, pas l'application (constaté en restaurant « Vérifier », qui déplaçait cette
       limite de 22 px). Vingt-quatre étapes donnent de la marge des deux côtés. */
    const etp=[];for(let i=0;i<24;i++)etp.push('étape '+(i+1));
    const f=migrate({id:'ancd',title:'Ancre mono-bloc',blocks:[
      {id:'b1',kind:'do',title:'Bloc unique',items:etp.map(x=>v4MakeItem(uid('i'),'do',x))}],start:'b1'});
    await Data.put(f);fiches.push(f);
    openRead(f.id);await w(350);
    document.getElementById('sessStart').click();await w(400);
    for(let i=0;i<30;i++){const li=[...document.querySelectorAll('[data-ck]')].find(x=>!x.classList.contains('done'));
      if(!li)break;li.dispatchEvent(new MouseEvent('click',{bubbles:true}));await w(120);}
    const fin=document.querySelector('[data-ovend]');if(fin)fin.click();await w(400);
    window.scrollTo(0,300);await w(250);
    /* Témoin de la condition ci-dessus : on n'est PAS collé au bas de la page. */
    const auBout=Math.round(scrollY)>=Math.round(document.documentElement.scrollHeight-innerHeight)-2;
    window.__anc=[];
    const li=document.querySelector('[data-ck].done');
    if(li)li.dispatchEvent(new MouseEvent('click',{bubbles:true}));
    await w(450);return {anc:window.__anc,auBout};});
  t('témoin : la page n\'est pas collée au bas (sinon on mesure le rabat du navigateur)',
    g.auBout===false, `auBout ${g.auBout}`);
  const gg=g.anc;
  t('re-rendu ciblé : le remplacement du bloc est ancré',gg.length>0&&gg[0].sel.indexOf('data-ck')>=0,
    JSON.stringify(gg));
  if(gg.length)t('… le résidu est réellement MESURÉ (ancre retrouvée)',
    gg[0].residu!==null&&gg[0].derive!==null,
    `résidu ${gg[0].residu}, dérive ${gg[0].derive} — ancre perdue pendant le re-rendu ?`);
  /* ⚠ CE DERNIER CONTRÔLE EST UN GARDE, ET IL FAUT LE DIRE : sur ce chemin, aujourd'hui, RIEN ne
     change au-dessus de l'ancre — neutraliser la compensation de `keepAnchor` le laisse VERT
     (vérifié). Il ne DÉMONTRE donc rien ; il protège contre une modification future qui ferait
     bouger le contenu au-dessus de l'ancre sans que la compensation l'absorbe. Ce qui, lui, est
     capable d'échouer, c'est le contrôle précédent : remplacer l'appel ancré par un re-rendu nu
     le fait rougir (vérifié aussi).
     ⚠ ET IL A MESURÉ LE NAVIGATEUR PENDANT UNE VERSION : avec six étapes, la page faisait 982 px
     pour une fenêtre de 900 — le défilement était collé au maximum, décocher retirait la bannière
     de fin, le navigateur RABATTAIT la page, et les 22 px de rabat étaient imputés à l'ancrage.
     D'où le témoin « pas collée au bas » ci-dessus : sans lui, la mesure ne dit rien. */
  if(gg.length)t('… et le bloc ne bouge pas (≤ 1 px)',
    gg[0].derive!==null&&Math.abs(gg[0].derive)<=1,
    `dérive ${gg[0].derive} px`);
  await page.close();
}
});

/* ══ LA RANGÉE D'ÉTAT NE ROGNE PAS, MÊME AVEC UN LIBELLÉ LONG (v4.47.0) ══
   `audit-doctrine` contrôlait déjà le débordement de la rangée de COMMANDES à 320/360/375/390.
   La rangée d'ÉTAT n'avait AUCUN contrôle symétrique — alors que `#cbTimers` est en
   `overflow:hidden` : un débordement n'y produit ni barre de défilement, ni glissement possible,
   RIEN. Et la clé de la boucle d'ajustement était aveugle aux INTITULÉS (elle ne décrivait que le
   nombre de chiffres) : renommer un minuteur faisait déborder le quai en silence — mesuré à
   119 px à 320 px avant correctif. Ce contrôle mesure les deux : intitulé long ET libellé de
   session étendu, ce dernier étant l'emplacement où le partage écrira (Lot 4). */
await sec('ECAM · la rangée d\'ÉTAT ne rogne jamais', async () => {
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
});

/* ══ L'ALARME NE TOMBE JAMAIS AVANT LE DÉCORATIF (v4.47.0) ══
   Le segment ambre d'un minuteur ÉCHU est le canal d'ACQUITTEMENT de l'alarme : c'est la seule
   trace qui persiste dans une zone qui ne quitte jamais l'écran une fois le bip passé. Or la
   boucle d'ajustement retirait les segments un à un et n'essayait « sans chevron » qu'arrivée à
   ZÉRO segment : elle sacrifiait donc l'alarme pour garder un glyphe `aria-hidden` que son propre
   commentaire dit « purement décoratif ». Et si même cette version ne tenait pas, elle REMETTAIT
   le chevron par-dessus — réécrivant un état qu'elle venait de mesurer comme débordant.
   Le contrôle mesure les deux : à toutes les largeurs de téléphone, avec un intitulé long sur le
   minuteur échu, `.seg.due` est PRÉSENT et le quai ne rogne pas. */
await sec('ECAM · l\'alarme survit au décoratif', async () => {
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
});

/* ══ LE QUAI DE L'INVITÉ EXISTE, ET IL DIT LA MAIN (v4.47.0) ══
   AC 120-71B §6.4 pt 1 : à tout instant, qui tient la checklist ne souffre AUCUNE ambiguïté. Or le
   quai n'apparaissait que si une session avait démarré LOCALEMENT — un invité qui suit n'a rien
   démarré, c'est le principe du miroir : tant qu'aucun minuteur ne tournait, il n'avait ni le
   détenteur de la main ni l'indicateur de péremption. Les deux informations que la doctrine veut
   permanentes n'avaient pas de conteneur.
   On vérifie AUSSI qu'elles sont LISIBLES : l'ellipse du quai fonctionne désormais (cf. plancher de
   112 px), donc un jeton trop long ne déborderait plus — il serait TRONQUÉ, c'est-à-dire muet. */
await sec('AC 120-71B · le quai de l\'invité dit qui tient la main', async () => {
for(const w of [320,360,390]){
  const page=await session(w,false);
  const r=await page.evaluate(async()=>{
    const el=document.getElementById('cbTimers');
    const avant=el.hidden;                                  // aucune session locale : quai absent
    Share.mode='guest';Share.status='active';Share.role='scribe';
    Share.lastOk=Date.now();Share._act=Date.now();
    /* LE CONTRAT RÉEL (v5.14.19) : chez l'invité, `openSharedFiche` pose TOUJOURS
       `started=true` et `sessionId` nul — c'est CE fait qui porte le chrome de crise, plus
       une branche sur le mode global (elle suivait l'invité jusque sur SES aides, signalé). */
    Runtime.started=true;Runtime.sessionId=null;
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
});

/* ══ INCRÉMENTER UN COMPTEUR HORODATE — et ne fait pas remonter le rail (v4.47.0) ══
   « Choc n° 3 à 14:32 » est exactement ce qu'on oublie de noter sous stress, et l'heure est ce
   qui compte cliniquement. Le repère porte une RÉFÉRENCE, pas un mot : son libellé se dérive de
   la fiche, il traverse donc le partage sans texte libre et suit le compteur si on le renomme.
   Le contrôle mesure les deux moitiés : le repère EXISTE, et le rail NE BOUGE PAS — le journal
   vit en fin de rail, qui a son propre défilement, et un rendu complet le remettrait à zéro
   (retour d'usage v4.23.5, « la barre latérale remontait à chaque Noter l'heure »). */
await sec('Journal · incrémenter un compteur pose un repère horodaté', async () => {
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
      libelle:(()=>{const b=document.querySelector('.tk-panel [data-tkdel="'+CSS.escape(id)+'"]');
        /* ⚠ ON MESURE LA PROPRIÉTÉ, PAS LE CARACTÈRE (v5.7) : le témoin exigeait le glyphe « ↺ »
           écrit en clair, donc il rougissait le jour où ce glyphe est devenu un TRACÉ (A106 —
           un dessin qui varie selon la police du système n'a rien à faire dans un bouton). Ce
           que la règle promet est qu'après une annulation le bouton propose de RÉTABLIR, et ne
           propose plus de supprimer : c'est le nom accessible qui le dit. */
        return b?{titre:b.title||b.getAttribute('aria-label')||'',
          trace:!!b.querySelector('svg'), croix:/^\s*×\s*$/.test(b.textContent||'')}:null;})()};
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
    t('le × est devenu un RETOUR : le bouton propose de rétablir',
      !!v.apresAnnul.libelle&&/rétablir/i.test(v.apresAnnul.libelle.titre)
      &&v.apresAnnul.libelle.trace===true&&v.apresAnnul.libelle.croix===false,
      JSON.stringify(v.apresAnnul.libelle));
    t('on peut se raviser : le repère est rétabli',
      !v.apresRetour.voidAt&&!v.apresRetour.barre&&v.apresRetour.n===v.n0);
  }
  await page.close();
}
});

/* ── TROIS ROGNAGES SIGNALÉS À L'USAGE (v4.55.3) ─────────────────────────────────────────────
   Le contrôle de rognage existait pour la rangée de commandes de crise (v4.43.0) ; ces trois
   surfaces n'étaient mesurées nulle part, et elles débordaient toutes les trois.
   DEUX PRÉCAUTIONS SANS LESQUELLES CES CONTRÔLES NE PROUVERAIENT RIEN — la première version les a
   omises et restait verte avec les défauts réintroduits :
    · le PLAN ne déborde qu'à partir de QUATRE options : la fiche d'exemple n'en a que deux, on
      construit donc une décision à huit branches ;
    · le PANNEAU ne déborde que sur écran TACTILE, où « silencieux ? » et le bouton son montent à
      44 px de cible — d'où un contexte `hasTouch`. */
await sec(`DOCTRINE · aucun rognage dans les feuilles ni le panneau — moteur ${NOM_MOTEUR}`, async () => {
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

    /* (b) LA CROIX DU PANNEAU MINUTEURS RESTE DANS LE CADRE. On mesure contre le bord INTÉRIEUR,
       comme le fait l'œil : un bouton qui touche la bordure est déjà coupé.
       ⚠ LE BORD INTÉRIEUR SE CALCULE, IL NE S'ÉCRIT PAS (v5.6). Il était en dur — « bordure 1 px
       + rembourrage 14 » —, donc le témoin encodait la géométrie d'UN logement. Le jour où le
       volet du quai a pris la largeur de la capsule, son panneau a perdu sa bordure et changé de
       rembourrage : le contrôle est passé au rouge sur une croix parfaitement dans le cadre.
       Un littéral qui décrit un mécanisme rougit sur un changement JUSTE (leçon v5.0.0). */
    // v5.4.2 : le panneau s'ouvre par le QUAI (la rangée repliée n'existe plus).
    const o2 = document.getElementById('cbTimers'); if (o2) { o2.click(); await new Promise(x => setTimeout(x, 350)); }
    {const pan = document.querySelector('.rt-panel'), head = document.querySelector('.rt-head'),
      k = document.querySelector('.rt-x');
     if (pan && k) { const p = pan.getBoundingClientRect(), kr = k.getBoundingClientRect();
       const cs = getComputedStyle(pan);
       const interieur = p.right - (parseFloat(cs.paddingRight)||0) - (parseFloat(cs.borderRightWidth)||0);
       o.croixDebord = Math.round(kr.right - interieur);
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
});

/* LE QUAI NOMME CE QU'IL CACHE — ET SEULEMENT ALORS (v5.0.0).
   Trois propriétés, et la deuxième est la seule qui rende la première admissible : le rappel
   n'existe QUE lorsque le quai ne montre aucun minuteur. Un témoin qui ne mesurerait que la
   présence du libellé laisserait passer la régression qui compte — celle où il concurrencerait
   l'alarme. On mesure donc aussi l'ÉTAT ARMÉ, où il doit avoir DISPARU. */
await sec('ECAM · le quai nomme ce qu\'il cache, sans jamais coûter un pixel', async () => {
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
  /* v5.6 (A9) : la capsule a un gabarit CONSTANT de 50 px, quel que soit son état — le rappel
     « n minuteurs · n compteurs » habille un chevron qui existe déjà, il ne coûte rien. Le
     nombre change (52 → 50, la capsule ayant remplacé la rangée) ; la propriété, non. */
  t(`${w} · … et sans coûter de hauteur (50 px)`, r.repos.h===50, `${r.repos.h} px`);
  /* ⚠ CE TÉMOIN MESURAIT UN MÉCANISME, PAS UNE PROPRIÉTÉ (corrigé en v5.6). Il exigeait que le
     rappel S'EFFACE dès qu'un minuteur est armé — c'était la règle d'alors (`!want.length`), et
     elle avait un trou : quand la boucle d'ajustement RETIRE le segment faute de place, le rappel
     se taisait aussi et le minuteur armé n'était annoncé par RIEN (mesuré à 390 px). La propriété
     recherchée n'a jamais été « le rappel s'efface » mais « il n'y a pas DEUX annonces du même
     minuteur, et il y en a au moins UNE ». C'est cela qu'on mesure désormais, et le témoin couvre
     donc aussi le cas où le segment ne tient pas. */
  const seg=/\d\d:\d\d[^]*\d\d:\d\d/.test(r.arme.txt);   // deux valeurs = chrono + segment
  t(`${w} · minuteur ARMÉ : il est montré OU annoncé, jamais tu`,
    seg || /\d+ minuteur/.test(r.arme.txt), r.arme.txt);
  t(`${w} · … et jamais les deux à la fois`,
    !(seg && /\d+ minuteur/.test(r.arme.txt)), r.arme.txt);
  t(`${w} · … et là non plus rien ne déborde`, r.arme.deb<=1, `${r.arme.deb} px`);
  await page.close();
}
});

/* LOT T8 — L'AXE DE DENSITÉ, ET LES TROIS FAÇONS DE REGARDER L'AIDE ENTIÈRE (v5.0.0).
   Le contrôle qui compte n'est pas « les onglets s'affichent » : c'est que le SCHÉMA GARDE SES
   COMPORTEMENTS. Le plan interdit de réécrire `buildFlowSVG` — mais poser le SVG dans un onglet
   sans rebrancher ses écouteurs le réduit à une IMAGE, et c'est ce qui s'est produit à la première
   passe (mesuré : zoom figé à 100 %, état de session non peint). On mesure donc le zoom, la
   peinture d'état et la navigabilité, pas la présence. */
await sec('T8 · axe de densité — « toute la fiche » se regarde de trois façons', async () => {
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
    /* v5.6 : l'excursion se commande depuis le DOCK. Ce qu'on mesure ne change pas — le
       contrôle est à la MÊME place et la barre garde la MÊME hauteur avant et après. */
    const hAv=Math.round(document.querySelector('#sessionDock .sd-in').getBoundingClientRect().height);
    const prefAv=currentReadMode();
    document.getElementById('allBtn').click(); await wt(600);
    const segRetour=document.querySelector('#allBtn .dp-lbl').textContent.trim();
    const xAp=Math.round(document.getElementById('allBtn').getBoundingClientRect().left);
    const hAp=Math.round(document.querySelector('#sessionDock .sd-in').getBoundingClientRect().height);
    const prefAp=currentReadMode();
    const ong=[...document.querySelectorAll('.at-b')].map(e=>e.textContent.trim());
    const defaut=(document.querySelector('.at-b.on')||{}).textContent||'';
    const pageOk=!!document.querySelector('.sv-sheet');
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
    const parc=!!document.querySelector('.pc-wrap')&&!document.querySelector('.sv-sheet')
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
    const avantHtml=document.querySelector('.sv-sheet').innerHTML;
    {const q=document.getElementById('pfQ');q.value='adrénaline';q.dispatchEvent(new Event('input',{bubbles:true}));}
    await wt(400);
    const hits=document.querySelectorAll('.sv-sheet mark.pf-h').length;
    const cpt=(document.getElementById('pfCount')||{}).textContent||'';
    const cache=[...document.querySelectorAll('.sv-sheet .sv-cell')].filter(e=>getComputedStyle(e).display==='none').length;
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
    const identique=document.querySelector('.sv-sheet').innerHTML===avantHtml;
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
});

/* LOT T9 / R4 — LA BIBLIOTHÈQUE EST UNIQUE, LE TYPE EST UN FILTRE.
   LE CAS DOIT EXISTER AVANT D'ÊTRE MESURÉ : le jeu d'exemple ne contient AUCUN protocole, si bien
   que « Tout » et « Aides » y donnent le même compte — un contrôle écrit sans cette précaution
   passerait au vert sans avoir rien vérifié (leçon v4.55.3, redite au lot T4). On en crée un. */
await sec('T9 · une seule bibliothèque, le type en filtre', async () => {
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
});

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
await sec('Audit design · titres longs, boîtes bornées', async () => {
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
    /* ⚠ LES ÉPINGLÉES SONT DES RANGÉES DEPUIS LA v5.6 (maquette 1a : le répertoire est UNE
       carte, les épinglées une carte de rangées au-dessus). `.qa-tile` n'existe plus — le
       mesurer rendait un ensemble VIDE, donc un témoin « cas adverse constitué » faux, et trois
       contrôles verts sur rien. On mesure la rangée épinglée, qui est ce qui a remplacé la
       tuile : même contrainte de boîte, même titre long. */
    const rows=scan('.dir-book:not(.pinned) .dir-row','.dir-t'), tiles=scan('.dir-book.pinned .dir-row','.dir-t');
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
  t(`${w}/z${zm} · la rangée épinglée ne déborde pas`, r.pireTile<=0, `${r.pireTile} px`);
  t(`${w}/z${zm} · … et ne rogne rien`, r.clipTile<=1, `${r.clipTile} px rognés`);
  /* PLAFOND DE CROISSANCE : la rangée épinglée est le premier objet de l'écran ; un titre long
     ne doit pas la faire enfler au point de repousser le répertoire. */
  t(`${w}/z${zm} · … et sa croissance reste bornée`, r.hTile<=105, `${r.hTile} px`);
  await page.close();
}
});

await sec('Audit design · la feuille de filtres', async () => {
{
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const rangees=()=>document.querySelectorAll('.typebar,.scopebar,.catbar').length;
    const tog=()=>{const b=document.getElementById('filtTog');return b&&!b.hidden?b:null;};
    /* On mesure le BORD DROIT : le déclencheur grossit du chiffre qu'il porte, mais il est le
       dernier objet de sa rangée — sa position apprise est celle de son bord droit. */
    const bordD=()=>{const b=tog();return b?Math.round(b.getBoundingClientRect().right):null;};
    const etat=()=>{const b=tog();if(!b)return null;
      const n=document.getElementById('filtN');
      return {act:b.classList.contains('act'),n:n&&!n.hidden?n.textContent:'',lbl:b.getAttribute('aria-label')||''};};
    /* Le premier contenu CLINIQUE, c'est-à-dire le point que tout ce lot cherche à remonter. */
    const yPremier=()=>{const e=document.querySelector('.dir-row .card-open');
      return e?Math.round(e.getBoundingClientRect().top):null;};
    await w(400);
    /* v5.6 (planche 8c) — LES FILTRES SONT UNE FEUILLE. On mesure donc EN PLUS la hauteur du
       chrome collant et la position du premier contenu AVANT et PENDANT l'ouverture : la
       propriété du lot n'est plus « le repli remonte le contenu » (il n'y a plus de repli) mais
       « ouvrir ne déplace RIEN », ce qui est strictement plus fort. */
    const hdrH=()=>Math.round(document.querySelector('header.bar').getBoundingClientRect().height);
    const feuille=()=>document.getElementById('filtSheet').classList.contains('on');
    const familles=()=>[...document.querySelectorAll('#filtSheetBody .scope-lbl')]
      .filter(e=>e.offsetParent!==null).length;
    const repliRangees=rangees(), repliTog=!!tog(), yRepli=yPremier(), xRepli=bordD(), hRepli=hdrH();
    if(!repliTog)return {repliRangees,repliTog,yRepli,xRepli,geo:null,ouvRangees:0,ouvTog:false,yOuvert:null,
      actifRangees:0,actifTog:false,actifEtat:null,chipOn:false,apresRender:0,apresTog:false,apresEtat:null,
      repliActifRangees:0,repliActifEtat:null,xRepliActif:null,avaitCat:false,deuxEtat:null,zeroEtat:null};
    /* v5.6 (maquette) — LE DÉCLENCHEUR VIT SUR LA RANGÉE DES CONTRÔLES DE LISTE, à son bord
       DROIT, en face du sélecteur de groupement. Il ne coûte toujours aucune ligne (cette rangée
       existe de toute façon) et il gagne son MOT, que l'en-tête ne pouvait pas lui offrir : à
       320 px la rangée d'identité n'avait la place que d'un glyphe.
       ⚠ SA RANGÉE EST ÉMISE MÊME SANS LISTE : sinon il déménagerait dans l'en-tête dès qu'un
       filtre ne rend rien — c'est-à-dire exactement au moment où on le cherche. */
    /* ⚠ IL NE DÉMÉNAGE PLUS (v5.6, demande de l'auteur) — le témoin change donc de VOISIN. Il
       mesurait le déclencheur contre le sélecteur de groupement, c'est-à-dire son adresse quand on
       est en haut de page ; or il en changeait au défilement. La propriété est désormais « il est
       contre le CHAMP DE RECHERCHE, et il y reste » : même rangée, à sa droite, dans l'écran. */
    const geo=(()=>{const b=tog(),q=document.querySelector('.hdr-search .srch-box');
      if(!b||!q)return null;const rb=b.getBoundingClientRect(),rq=q.getBoundingClientRect();
      return {memeRangee:Math.abs((rb.top+rb.height/2)-(rq.top+rq.height/2))<=6,
              aDroite:Math.round(rb.left-rq.right), h:Math.round(rb.height), w:Math.round(rb.width),
              dansChamp:!!b.closest('.hdr-search'),
              /* Il fait la HAUTEUR du champ d'en face, à quelques pixels près : deux objets voisins
                 d'une même rangée qui ne s'alignent pas se lisent comme deux niveaux. */
              hChamp:Math.round(rq.height),
              dyHaut:Math.round(rb.top-rq.top), dyBas:Math.round(rq.bottom-rb.bottom),
              dansEcran:Math.round(rb.right)<=innerWidth};})();
    /* Après défilement l'en-tête se resserre (`home-slim`) : le déclencheur doit être resté dans
       le champ. On attend une image pour que la classe soit posée. */
    window.scrollTo(0,600);
    await new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)));
    const apresScroll=!!(tog()&&tog().closest('.hdr-search'));
    window.scrollTo(0,0);
    tog().click(); await w(500);
    const ouvRangees=rangees(), ouvTog=!!tog(), yOuvert=yPremier();
    const ouvFeuille=feuille(), ouvFam=familles(), hOuvert=hdrH();
    const piedAvant=(document.getElementById('filtSheetGo')||{}).textContent||'';
    const nRangees=document.querySelectorAll('.dir-row').length;
    /* On pose un filtre : à partir de là, le déclencheur doit le DIRE, et ne jamais s'en aller. */
    document.querySelector('.typebar [data-section="fiches"]').click(); await w(500);
    const actifRangees=rangees(), actifTog=!!tog(), actifEtat=etat();
    const chipOn=!!document.querySelector('.typebar [data-section="fiches"].on');
    /* Et il doit le rester après un re-rendu complet, pas seulement juste après le clic. */
    render(); await w(500);
    const apresRender=rangees(), apresTog=!!tog(), apresEtat=etat();
    /* PUIS ON REPLIE ALORS QU'UN FILTRE AGIT : les rangées s'en vont, l'ÉTAT reste annoncé.
       ⚠ Chaque geste est GARDÉ : un déclencheur absent est précisément le défaut que ce bloc
       mesure — le laisser lever ferait planter le harnais, et « un harnais qui plante en emporte
       cinq » (v4.70.1). On veut un ROUGE lisible, pas une exception. */
    tog()?.click(); await w(500);
    /* ⚠ ON MESURE LA FEUILLE, PLUS LE NOMBRE DE RANGÉES (v5.6). Les chips vivent désormais dans
       `#filtSheetBody`, qui GARDE son contenu une fois la feuille fermée — compter les rangées
       du document reviendrait à compter l'intérieur d'un pli, la leçon déjà payée sur le rail
       (v5.4.3). Ce qui compte est que la SURFACE soit refermée et que l'annonce demeure. */
    const repliActifRangees=feuille()?1:0, repliActifEtat=etat(), xRepliActif=bordD();
    /* Deux filtres : le chiffre COMPTE, il ne se contente pas d'exister.
       ⚠ Les chips sont re-rendues à chaque geste : on RE-INTERROGE le DOM, une référence gardée
       d'avant le clic désignerait un nœud détaché et le geste ne ferait rien. */
    tog()?.click(); await w(400);
    const cat2=[...document.querySelectorAll('.catbar [data-cat]')].find(b=>b.dataset.cat);
    const avaitCat=!!cat2; if(cat2)cat2.click(); await w(500);
    const deuxEtat=etat();
    document.querySelector('.typebar [data-section="all"]').click(); await w(400);
    document.querySelector('.catbar [data-cat=""]')?.click(); await w(500);
    const zeroEtat=etat();
    /* Le pied ANNONCE puis ferme : on mesure les deux, et que l'annonce du déclencheur reprenne
       la main derrière (l'état ne peut pas se perdre entre deux surfaces). */
    tog()?.click(); await w(400);
    const cat3=[...document.querySelectorAll('#filtSheetBody [data-cat]')].find(b=>b.dataset.cat);
    if(cat3)cat3.click(); await w(400);
    const piedApres=(document.getElementById('filtSheetGo')||{}).textContent||'';
    const nApres=document.querySelectorAll('.dir-row').length;
    document.getElementById('filtSheetGo').click(); await w(400);
    const fermee=!feuille(), etatApresPied=etat();
    document.querySelector('#filtSheetClear')&&0;
    tog()?.click(); await w(300);
    document.getElementById('filtSheetClear').click(); await w(400);
    const apresClear=etat(); document.getElementById('filtSheetGo').click(); await w(300);
    return {hRepli,hOuvert,ouvFeuille,ouvFam,piedAvant,nRangees,piedApres,nApres,fermee,etatApresPied,apresClear,
            repliRangees,repliTog,yRepli,xRepli,geo,apresScroll,ouvRangees,ouvTog,yOuvert,
            actifRangees,actifTog,actifEtat,chipOn,apresRender,apresTog,apresEtat,
            repliActifRangees,repliActifEtat,xRepliActif,avaitCat,deuxEtat,zeroEtat};});

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
  /* ══ v5.6, PLANCHE 8c — LA PROPRIÉTÉ A CHANGÉ, ET ELLE EST PLUS FORTE ══
     Le témoin d'avant mesurait un GAIN (« le repli remonte le contenu de ≥ 40 px ») : c'était
     la bonne mesure d'un DÉPLIANT, qui poussait le contenu quand on l'ouvrait. Une feuille ne
     pousse rien — le gain serait donc de 0 px et le témoin rougirait sur un correctif JUSTE.
     Ce qu'on mesure désormais est ce que le dépliant ne pouvait pas offrir : demander à voir les
     filtres ne coûte AUCUN pixel de liste, et le chrome collant ne grandit pas d'un pixel. */
  t('ouvrir les filtres ne déplace pas le contenu d\'un pixel',
    r.yRepli!==null&&r.yOuvert!==null&&Math.abs(r.yOuvert-r.yRepli)<=1,
    `${r.yRepli} px puis ${r.yOuvert} px`);
  t('… ni ne fait grandir le chrome collant', Math.abs(r.hOuvert-r.hRepli)<=1,
    `${r.hRepli} px puis ${r.hOuvert} px`);
  t('… et c\'est bien une FEUILLE qui s\'ouvre', r.ouvFeuille===true);
  /* Les trois familles d'un coup : c'est le reproche exact fait au dépliant, où l'on déroulait
     une rangée après l'autre dans un espace qui poussait le reste vers le bas. */
  t('… où les familles de filtres sont visibles ENSEMBLE', r.ouvFam>=2, `${r.ouvFam} famille(s)`);
  /* LE PIED ANNONCE LE RÉSULTAT AVANT DE FERMER — et le nombre annoncé est celui de la liste
     RÉELLEMENT rendue dessous, jamais un second comptage qui pourrait diverger. */
  t('le pied annonce le nombre de résultats, et il est JUSTE',
    new RegExp('(^|\\D)'+r.nRangees+'(\\D|$)').test(r.piedAvant)||(r.nRangees===1&&/le résultat/.test(r.piedAvant)),
    `« ${r.piedAvant} » pour ${r.nRangees} rangée(s)`);
  t('… et il suit le filtre qu\'on vient de poser, sans fermer',
    r.piedApres!==r.piedAvant||r.nApres===r.nRangees,
    `« ${r.piedApres} » pour ${r.nApres} rangée(s)`);
  t('… le valider ferme la feuille et rend l\'annonce au déclencheur',
    r.fermee===true&&!!r.etatApresPied&&r.etatApresPied.act===true,
    `fermée ${r.fermee}, ${JSON.stringify(r.etatApresPied)}`);
  /* « Tout effacer » remet les trois familles à leur cran neutre d'un geste. */
  t('« Tout effacer » remet tout à zéro d\'un geste',
    !!r.apresClear&&r.apresClear.act===false&&r.apresClear.n==='',
    JSON.stringify(r.apresClear));
  /* v5.0.3 — LE DÉCLENCHEUR VIT CONTRE LA RECHERCHE. La v5.0.0 le posait dans le flux, au-dessus
     du contenu : une ligne permanente pour un geste rare. */
  t('il vit contre le champ de recherche, à sa droite',
    !!r.geo&&r.geo.memeRangee&&r.geo.aDroite>=0&&r.geo.dansEcran&&r.geo.dansChamp===true,
    JSON.stringify(r.geo));
  /* ⚠ ET IL Y RESTE APRÈS DÉFILEMENT — c'est le défaut signalé : il changeait d'adresse selon
     l'endroit où l'on se trouvait dans la page. Le témoin mesure donc les DEUX états. */
  t('… et il y reste une fois l\'en-tête resserré', r.apresScroll===true, `${r.apresScroll}`);
  /* Cible ≥ 32 px hors mode crise (règle 9) — le halo ::after l'étend encore de 4 px. */
  t('… et sa cible reste réglementaire', !!r.geo&&r.geo.h>=32&&r.geo.w>=32,
    r.geo?`${r.geo.w}×${r.geo.h} px`:'—');
  /* SIGNALÉ À L'USAGE (v5.0.3) : une hauteur FIXE de 36 px laissait 4 px de jeu en haut et en bas,
     le champ montant à 43 px sur écran tactile. Deux objets voisins d'une même rangée qui ne
     s'alignent ni en haut ni en bas se lisent comme deux objets sans rapport. */
  t('… et il s’aligne exactement sur le sélecteur d’en face',
    !!r.geo&&Math.abs(r.geo.h-r.geo.hChamp)<=1&&Math.abs(r.geo.dyHaut)<=1&&Math.abs(r.geo.dyBas)<=1,
    r.geo?`${r.geo.h} px contre ${r.geo.hChamp} px (jeu ${r.geo.dyHaut}/${r.geo.dyBas})`:'—');
  /* LA CONTREPARTIE, ET C'EST LA GARANTIE QUI COMPTE (v5.0.3 : elle a CHANGÉ DE PORTEUR).
     La v5.0.0 forçait les rangées ouvertes dès qu'un filtre agissait, et retirait le
     déclencheur — donc un contrôle qui apparaît et disparaît selon l'état. L'état actif est
     désormais porté par le déclencheur LUI-MÊME : couleur + CHIFFRE + nom accessible, à position
     constante dans l'en-tête. Il ne peut donc plus se cacher, et le bouton ne peut plus mourir. */
  t('⚠ un filtre ACTIF est annoncé par le déclencheur, qui RESTE',
    r.actifTog===true&&!!r.actifEtat&&r.actifEtat.act===true&&r.actifEtat.n==='1'&&r.chipOn===true,
    `${JSON.stringify(r.actifEtat)}, chip active ${r.chipOn}`);
  /* RÈGLE 8 : la couleur n'est jamais seule — le chiffre et le nom accessible portent l'info. */
  t('… et pas par la seule couleur (chiffre + nom accessible)',
    !!r.actifEtat&&/1 actif/.test(r.actifEtat.lbl), r.actifEtat?r.actifEtat.lbl:'—');
  t('… et cela survit à un re-rendu complet',
    r.apresRender===r.ouvRangees&&r.apresTog===true&&!!r.apresEtat&&r.apresEtat.act===true,
    `${r.apresRender} rangée(s), déclencheur ${r.apresTog} ${JSON.stringify(r.apresEtat)}`);
  /* CE QUI REMPLACE LE FORÇAGE : replier avec un filtre actif est permis, mais l'annonce demeure —
     on ne peut pas se retrouver dans un corpus restreint sans savoir pourquoi. */
  t('refermer la feuille avec un filtre actif garde l\'annonce',
    r.repliActifRangees===0&&!!r.repliActifEtat&&r.repliActifEtat.act===true&&r.repliActifEtat.n==='1',
    `feuille ouverte ${r.repliActifRangees}, ${JSON.stringify(r.repliActifEtat)}`);
  /* CONSTANCE POSITIONNELLE : il grossit du chiffre, son bord droit ne bouge d'aucun état. */
  t('… et sa position ne bouge pas d\'un état à l\'autre',
    r.xRepli!==null&&r.xRepliActif!==null&&Math.abs(r.xRepli-r.xRepliActif)<=1,
    `${r.xRepli} px puis ${r.xRepliActif} px`);
  /* TÉMOIN : sans seconde dimension filtrable, on mesurerait « 1 » en croyant mesurer « 2 ». */
  t('témoin : une seconde dimension de filtre existe', r.avaitCat===true);
  t('le chiffre COMPTE les filtres posés',
    !!r.deuxEtat&&r.deuxEtat.n==='2'&&!!r.zeroEtat&&r.zeroEtat.act===false&&r.zeroEtat.n==='',
    `deux → ${JSON.stringify(r.deuxEtat)} ; aucun → ${JSON.stringify(r.zeroEtat)}`);
  await page.close();
}
});

/* CROIX D'EFFACEMENT DE LA RECHERCHE (v5.0.3, demande utilisateur). Trois propriétés, et la
   troisième est celle qu'on oublie : effacer sans rendre le focus oblige à re-viser le champ. */
/* L'EN-TÊTE D'ACCUEIL TIENT SUR UNE LIGNE JUSQU'AU PLANCHER SERVI (v5.0.3, signalé à l'usage).
   `.id-row` est en `flex-wrap` : le flex CASSE LA LIGNE avant de rétrécir, donc un déficit de
   quelques pixels ne se voit pas comme un débordement — il se paie en HAUTEUR d'en-tête, sur le
   seul écran où elle est la plus rare. C'est exactement ce qui se produisait à 320 px, et ce que
   la v4.43.0 avait mesuré partout SAUF ici. On mesure donc l'alignement des deux blocs, pas un
   débordement qui n'arrivera jamais. */
await sec('En-tête d\'accueil · une seule ligne jusqu\'à 320 px', async () => {
{
  for(const w of [320,360,375,390,430]){
    const page = await br.newPage({viewport:{width:w,height:700},hasTouch:true});
    page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'));
    await amorce(page);
    await page.waitForTimeout(300);
    const r = await page.evaluate(()=>{
      const io=s=>{const v=parseFloat(s);return isNaN(v)?0:v;};
      const brand=document.querySelector('.brand').getBoundingClientRect();
      const acts=document.querySelector('.hdr-acts').getBoundingClientRect();
      /* Les cibles sont mesurées HALO COMPRIS : c'est le patron admis en zone haute pour ne pas
         épaissir la rangée (doctrine « halo sur les contrôles 36 px de la barre »). */
      /* ⚠ ON NE MESURE QUE CE QUI EST RENDU (v5.6) : le raccourci de thème existe dans la coque
         mais n'est visible qu'en LECTURE — un élément masqué rend une boîte de 0×0, et la cible
         minimale tombait donc à 0 sur l'accueil. Le contrôle mesurait l'absence, pas une cible. */
      /* ⚠ HAUTEUR ET LARGEUR NE SE MESURENT PLUS AU MÊME SEUIL, ET C'EST UN ARBITRAGE (v5.6,
         balayage de COLLISIONS). Les halos qui portaient ces boutons à 44 px de LARGE mordaient
         sur la cible du voisin — 10 px de recouvrement à 320 px, 4 à 390 : dans cette bande, c'est
         le dernier élément du DOM qui reçoit le tap, donc on visait « Créer » et l'on ouvrait le
         Compte. Une largeur de cible qui appartient pour moitié au bouton d'à côté n'est pas une
         cible : elle est fictive. On garde donc les 44 px en HAUTEUR (rien ne les dispute) et l'on
         borne la LARGEUR à la place réellement disponible — au-dessus du plancher de 32 px, qui
         est la règle hors crise —, en exigeant EN PLUS que deux cibles voisines ne se recouvrent
         jamais. Mieux vaut une cible plus étroite et sans ambiguïté qu'une cible large et
         partagée. */
      const cib=[...document.querySelectorAll('.hdr-new,.hdr-theme,.bar-acct')].filter(e=>e.offsetParent).map(e=>{
        const b=e.getBoundingClientRect(),a=getComputedStyle(e,'::after');
        return {w:Math.round(b.width-io(a.left)-io(a.right)),h:Math.round(b.height-io(a.top)-io(a.bottom)),
          l:b.left-io(a.left),r:b.right+io(a.right)};});
      let rec=0;for(let i=0;i<cib.length;i++)for(let j=i+1;j<cib.length;j++)
        rec=Math.max(rec,Math.round(Math.min(cib[i].r,cib[j].r)-Math.max(cib[i].l,cib[j].l)));
      const deb=Math.max(0,...[...document.querySelector('.id-row').children].filter(e=>e.offsetParent)
        .map(e=>Math.round(e.getBoundingClientRect().right)-innerWidth));
      /* ⚠ ON MESURE AUSSI LA MARGE, ET C'EST ELLE QUI PRÉVIENT. « Une seule ligne » est un
         booléen : il reste vert jusqu'au dernier pixel, puis casse d'un coup en +38 px de hauteur.
         La largeur du mot-marque dépend en plus du RENDU de la police — mesurée à 126 px sur
         Chromium complet et 136 sur le headless shell, soit 10 px d'écart pour le même code, et
         la marge d'origine était de 4. On exige donc une réserve, pas seulement un tenu-de-peu. */
      const row=document.querySelector('.id-row').getBoundingClientRect();
      const logo=document.querySelector('.brand-logo').getBoundingClientRect();
      const g=parseFloat(getComputedStyle(document.querySelector('.id-row')).columnGap)||0;
      return {uneLigne:Math.abs((brand.top+brand.height/2)-(acts.top+acts.height/2))<=8,
        cible:Math.min(...cib.map(c=>c.h)), cibleW:Math.min(...cib.map(c=>c.w)), recouvre:rec, debord:deb,
        marge:Math.round(row.width-(logo.width+brand.width+acts.width+2*g)),
        hdr:Math.round(document.querySelector('header.bar').getBoundingClientRect().height)};});
    t(`${w} px · marque et actions sur la MÊME ligne`, r.uneLigne===true, `en-tête ${r.hdr} px`);
    t(`${w} px · … avec une réserve, pas au pixel près`, r.marge>=8, `${r.marge} px de marge`);
    t(`${w} px · … sans rien pousser hors de l'écran`, r.debord===0, `${r.debord} px`);
    t(`${w} px · … et les cibles gardent 44 px de HAUTEUR (halo compris)`, r.cible>=44, `${r.cible} px`);
    t(`${w} px · … au moins 32 px de large (plancher hors crise)`, r.cibleW>=32, `${r.cibleW} px`);
    t(`${w} px · … et AUCUNE cible ne mord sur celle de sa voisine`, r.recouvre<=0, `${r.recouvre} px`);
    await page.close();
  }
}
});

/* LE VERROU DE MARQUE SE MESURE SUR L'ENCRE, PAS SUR LA BOÎTE (v5.0.5, signalé à l'usage).
   `logo-glyph.svg` porte son propre blanc — un cinquième de la boîte à gauche : caler le
   rectangle sur la marge de page laissait le DESSIN 6 px plus loin, et l'écart au mot-marque
   valait 14,5 px quand celui au bord n'en valait que 2, d'où une marque qui flotte au lieu de
   faire lockup. Le témoin relit donc les insets d'encre AU CANVAS (si le glyphe est redessiné,
   la mesure suit — un inset écrit en dur périmerait au premier retracé) et vérifie les deux
   propriétés : l'encre commence à la marge de page, et la respiration du verrou reste
   proportionnée au dessin. ⚠ Il rencontre son cas d'abord : hors accueil, le logo n'existe pas. */
await sec('Accueil · le verrou logo + mot-marque', async () => {
{
  for(const w of [320,390,430,1280]){
    const page = await br.newPage({viewport:{width:w,height:760},hasTouch:true});
    page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'));
    await amorce(page);
    await page.waitForTimeout(250);
    const r = await page.evaluate(async ()=>{
      const l=document.querySelector('.brand-logo');
      if(!l||!l.offsetParent) return {pose:false};
      const img=new Image();img.src='logo-glyph.svg';await img.decode();
      const N=256,c=document.createElement('canvas');c.width=c.height=N;
      const x=c.getContext('2d');x.drawImage(img,0,0,N,N);
      const d=x.getImageData(0,0,N,N).data;
      let x0=N,x1=-1;
      for(let j=0;j<N;j++)for(let i=0;i<N;i++)
        if(d[(j*N+i)*4+3]>12){if(i<x0)x0=i;if(i>x1)x1=i;}
      const rl=l.getBoundingClientRect(),rb=document.querySelector('.brand').getBoundingClientRect();
      const pad=parseFloat(getComputedStyle(document.querySelector('header.bar')).paddingLeft);
      const encre={g:rl.left+rl.width*(x0/N), d:rl.right-rl.width*((N-1-x1)/N)};
      return {pose:true, blanc:+((x0/N)*100).toFixed(1), marge:pad,
        deltaG:+(encre.g-pad).toFixed(2), ecart:+(rb.left-encre.d).toFixed(2),
        haut:+(rl.height*((x1-x0+1)/N)).toFixed(1)};});
    t(`${w} px · le contrôle rencontre son cas (logo affiché, masque à blanc réel)`,
      r.pose===true&&r.blanc>5, JSON.stringify(r));
    t(`${w} px · l'ENCRE du logo commence à la marge de page`,
      Math.abs(r.deltaG)<=1, `${r.deltaG} px d'écart à la marge de ${r.marge}`);
    t(`${w} px · … et le verrou respire sans se disloquer (0,25–0,6 × la largeur d'encre)`,
      r.ecart>=r.haut*0.25&&r.ecart<=r.haut*0.6, `${r.ecart} px pour ${r.haut} px d'encre`);
    await page.close();
  }
}
});

/* LE RAIL A→Z NE COUVRE JAMAIS UNE CARTE (v5.0.3, question utilisateur sur l'écart). En voie
   étroite il est `position:fixed` : la gouttière réservée n'est pas un tampon anti-fausse-manœuvre,
   c'est ce qui l'empêche de recouvrir le bord droit des rangées — donc l'épingle. La resserrer se
   mesure des DEUX côtés : assez pour ne rien couvrir, assez pour que les deux cibles ne se
   touchent pas. */
await sec('Accueil · la gouttière du rail A→Z', async () => {
{
  for(const w of [320,390,430,640,779]){
    const page = await br.newPage({viewport:{width:w,height:760},hasTouch:true});
    page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'));
    await amorce(page);
    /* Le rail exige au moins deux lettres distinctes : les fiches d'exemple n'en donnent pas
       assez, on construit donc le cas au lieu de mesurer un écran sans rail. */
    await page.evaluate(async()=>{const f=JSON.parse(JSON.stringify(fiches[0]));
      for(const ti of ['Bradycardie','Choc septique','Dyspnée','Hémorragie','Intubation']){
        const n=JSON.parse(JSON.stringify(f));n.id='x'+ti.slice(0,3);n.title=ti;fiches.push(migrate(n));}
      render();await new Promise(r=>setTimeout(r,400));});
    await page.waitForTimeout(300);
    const r = await page.evaluate(()=>{
      const rail=document.querySelector('.azrail');
      if(!rail)return {rail:false};
      const io=s=>{const v=parseFloat(s);return isNaN(v)?0:v;};
      const rl=rail.getBoundingClientRect().left;
      const rows=[...document.querySelectorAll('.dir-row')];
      const cartes=rows.map(e=>Math.round(rl-e.getBoundingClientRect().right));
      const cibles=[...document.querySelectorAll('.dir-row button')].map(e=>{
        const b=e.getBoundingClientRect(),h=getComputedStyle(e,'::before');
        return Math.round(rl-(b.right-io(h.right)));});
      return {rail:true,nRangs:rows.length,pireCarte:Math.min(...cartes),pireCible:Math.min(...cibles)};});
    t(`${w} px · témoin : le rail est bien rendu`, r.rail===true&&r.nRangs>=3,
      r.rail?`${r.nRangs} rangée(s)`:'aucun rail');
    t(`${w} px · il ne recouvre AUCUNE rangée`, r.pireCarte>0, `${r.pireCarte} px au plus près`);
    /* Borne basse : deux zones tactiles voisines qui se touchent produisent la fausse manœuvre
       que la question redoutait — c'est CETTE distance qu'il faut tenir, pas une marge d'aspect. */
    t(`${w} px · … et laisse la zone tactile de l'épingle libre`, r.pireCible>=4,
      `${r.pireCible} px`);
    /* ⚠ LA GOUTTIÈRE APPARTIENT À LA PAGE, PAS AU RAIL (v5.6, signalé à l'usage : « l'absence de
       rail redistribue la largeur des cartes »). La règle était accrochée à `.azr-on` : sans rail
       — bibliothèque vide, une seule lettre — la colonne récupérait ses 16 px et tout s'élargissait
       avant de rétrécir au retour. On compare donc la colonne UTILE avec rail et sans, et l'on
       vérifie au passage que la rangée de contrôles respire sous elle, quel que soit ce qui suit :
       avec des cartes l'écart venait du titre de section, donc d'un VOISIN, et le bloc « aucune
       aide » n'en apportait aucun (0 px mesuré). */
    const g = await page.evaluate(async()=>{
      const util=()=>{const h=document.querySelector('.home-main'),c=getComputedStyle(h);
        return Math.round(h.clientWidth-parseFloat(c.paddingLeft)-parseFloat(c.paddingRight));};
      const ecart=()=>{const gr=document.querySelector('.grp-row'),nx=gr&&gr.nextElementSibling;
        return (gr&&nx)?Math.round(nx.getBoundingClientRect().top-gr.getBoundingClientRect().bottom):null;};
      const avec={util:util(),ecart:ecart()};
      fiches.length=0;protocols.length=0;render();
      await new Promise(r=>setTimeout(r,350));
      return {avec,sans:{util:util(),ecart:ecart(),rail:!!document.querySelector('.azrail:not([hidden])')}};});
    t(`${w} px · la colonne ne s'élargit pas quand le rail disparaît`,
      g.avec.util===g.sans.util, `${g.avec.util} px avec rail, ${g.sans.util} sans`);
    t(`${w} px · témoin : le rail a bien disparu`, g.sans.rail===false, JSON.stringify(g.sans));
    t(`${w} px · la rangée de contrôles respire sous elle, avec ou sans cartes`,
      g.avec.ecart>=12&&g.sans.ecart>=12, `${g.avec.ecart} px avec, ${g.sans.ecart} sans`);
    await page.close();
  }
}
});

await sec('Recherche · la croix d\'effacement', async () => {
{
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const vis=()=>page.evaluate(()=>{const x=document.getElementById('qClear');return !!x&&!x.hidden;});
  const nRows=()=>page.evaluate(()=>document.querySelectorAll('.dir-row').length);
  const repos=await vis(), toutes=await nRows();
  /* ⚠ ON MESURE AVANT LE DÉBOUNCE (150 ms) : le re-rendu repeint tout, donc attendre le laisserait
     vert même si la croix ne se peignait qu'au rendu — c'est-à-dire une croix qui paraît un sixième
     de seconde après la lettre qu'on vient de taper. C'est la frappe qui doit la poser. */
  await page.fill('#q','anaphyl');
  const surLeChamp=await vis();
  await page.waitForTimeout(350);
  const saisie=await vis(), filtre=await nRows();
  /* Elle ne doit pas RECOUVRIR le texte saisi : sa place est réservée par le rembourrage. */
  const geo=await page.evaluate(()=>{const x=document.getElementById('qClear'),q=document.getElementById('q');
    const rx=x.getBoundingClientRect(),rq=q.getBoundingClientRect();
    const pr=parseFloat(getComputedStyle(q).paddingRight);
    /* La cible se mesure HALO COMPRIS (::after), comme le fait audit-a11y : c'est le patron du
       dossier pour ne pas épaissir une rangée dense. */
    const a=getComputedStyle(x,'::after');
    const io=s=>{const v=parseFloat(s);return isNaN(v)?0:v;};
    return {dansChamp:rx.right<=rq.right+1&&rx.left>=rq.left,
            reserve:Math.round(pr)>=Math.round(rx.width),
            w:Math.round(rx.width-io(a.left)-io(a.right)),h:Math.round(rx.height-io(a.top)-io(a.bottom)),
            pr:Math.round(pr)};});
  await page.click('#qClear'); await page.waitForTimeout(350);
  const apres=await vis(), rendu=await nRows();
  const foc=await page.evaluate(()=>document.activeElement&&document.activeElement.id);
  const val=await page.inputValue('#q');
  t('témoin : la recherche restreint bien la liste', toutes>filtre&&filtre>=0,
    `${toutes} rangée(s) puis ${filtre}`);
  t('aucune croix tant qu\'il n\'y a rien à effacer', repos===false);
  t('elle paraît dès la frappe, sans attendre le re-rendu', surLeChamp===true);
  t('… et elle y reste après le re-rendu', saisie===true);
  t('… dans le champ, sans recouvrir le texte', geo.dansChamp&&geo.reserve, JSON.stringify(geo));
  t('… avec une cible ≥ 24 px (halo compris)', geo.w>=24&&geo.h>=24, `${geo.w}×${geo.h} px`);
  t('elle efface la saisie ET la recherche', val===''&&apres===false&&rendu===toutes,
    `valeur ${JSON.stringify(val)}, ${rendu} rangée(s) pour ${toutes}`);
  t('… et rend le focus au champ', foc==='q', `focus : ${foc}`);
  await page.close();
}
});

/* LOT T7 — ★ MÉMOIRE, DE BOUT EN BOUT. Le contrôle unitaire mesure le CALCUL ; celui-ci mesure
   le CHEMIN RÉEL — poser l'étoile dans l'éditeur, revenir en lecture, la voir dans le chapeau.
   C'est ce chemin qui a révélé un défaut ANTÉRIEUR : `openRead` conservait un Runtime déjà
   construit SANS re-pointer sa fiche, si bien qu'après une édition la lecture affichait l'objet
   d'avant (`edCommit` REMPLACE l'entrée de `fiches` par sa copie normalisée). Un contrôle qui se
   serait arrêté au calcul ne l'aurait jamais vu. */
await sec('T7 · ★ mémoire — de l\'éditeur au chapeau', async () => {
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
    /* v5.6 : les étapes ne se voient qu'une fois la session démarrée (la page d'avant montre le
       parcours inerte). Ce qui est mesuré — « le memory item RESTE dans son bloc, le chapeau
       AGRÈGE » — vaut au moment où on l'exécute, donc en session. */
    {const b=document.getElementById('sessStart');if(b)b.click();}await w(600);
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
});

/* LOT T13 — LES DEUX FICHES D'EXEMPLE SONT LE SEUL MATÉRIEL PÉDAGOGIQUE, donc ce qu'elles
   n'exercent pas n'existe pas pour un nouveau venu. Le constat 3 de l'audit J0 les mesurait à un
   TIERS des mécanismes du produit : zéro posologie, zéro complication, aucun `discriminant`,
   aucun `onDue`, et le registre AMBRE présent UNE seule fois dans tout le produit.
   ON MESURE LES MÉCANISMES, PAS LE TEXTE : un contrôle sur les libellés casserait à la première
   relecture clinique, alors que ce qui compte est qu'un J0 RENCONTRE chaque dispositif. */
await sec('T13 · les fiches d\'exemple exercent la doctrine qu\'elles enseignent', async () => {
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
});

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
await sec('RÉFÉRENCE · plan à gauche, recherche dedans', async () => {
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
      if(!d||!bar)return {pos:'—',visibleLoin:null,loin:0,borne:0,defile:'',liens:0,corpsLien:'',
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
      /* ⚠ ON VÉRIFIE QU'ON A VRAIMENT DÉFILÉ (v5.6, balayage A46) : `scrollTo(0,1200)` est ÉCRÊTÉ
         si le document est plus court, et « la barre reste visible loin dans la page » se
         vérifierait alors sans qu'on soit jamais parti — un témoin qui ne rencontre pas son cas ne
         prouve rien. La borne n'est pas ici un piège de MESURE (la barre est FIXE, aucune hauteur
         n'est comparée de part et d'autre d'un re-rendu) : c'est seulement le cas qu'il faut. */
      window.scrollTo(0,1200);
      const loin=Math.round(window.scrollY);
      const vis=d.getBoundingClientRect().top>=0&&d.getBoundingClientRect().top<300;
      const survit=d.open&&d.scrollTop>0&&nt===1;
      window.scrollTo(0,0);d.open=false;
      return {pos:cb.position,visibleLoin:vis,loin,borne:Math.round(b),defile:ov,liens:nb,corpsLien:cl,survit,
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
       qu'il rétrécissait au moment PRÉCIS où l'on gagne de la place. Largeur passée à 240 en
       v5.6 (7b : une seule colonne d'orientation pour tout le produit) — c'est l'INVARIANCE qui
       est mesurée, pas le chiffre, et le chiffre suit la grille canonique. */
    t(`${W} · … et le sommaire garde ses 240 px`, r.largeurToc>=238, `${r.largeurToc} px`);
    if(W>=1200)t(`${W} · … le corps reprend ses 780 px pleins`, r.largeurCorps>=770, `${r.largeurCorps} px`);
    /* ⚠ LE CORPS N'EST PLUS CENTRÉ DANS LA FENÊTRE À PARTIR DE 1400 (7b) : la grille canonique
       pose `240 · 780 · 1fr`, donc la piste de droite absorbe tout l'excédent et le corps reste
       calé à gauche derrière son sommaire. C'est l'arbitrage de la planche — une seule grille
       pour tout le produit prime sur le centrage optique d'une seule vue —, et l'écart mesuré
       (32 px à 1400) est la moitié d'une gouttière. On mesure donc ce qui EST garanti : le
       sommaire ne recouvre jamais le corps, et le corps garde sa largeur de lecture. */
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
  t('témoin : la page a bien défilé loin (le cas est rencontré)',
    r.dock.loin>=600, `${r.dock.loin} px défilés`);
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
});

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
await sec('COMPLICATIONS · entrer d’un tap, revenir sans chercher', async () => {
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
    /* UN SEUL ÉVÉNEMENT : l'événement EST la touche (elle porte son NOM), et taper n'ouvre
       AUCUN index — on entre d'un tap. v5.6 : la touche vit au dock, à position constante. */
    const un=document.getElementById('cxKey');
    const unLbl=un?un.textContent.replace(/\s+/g,' ').trim():null;
    /* ⚠ ON PART DE LOIN, EXPRÈS : le défaut signalé est que l'entrée ne ramenait pas EN HAUT du
       bloc d'excursion — un contrôle qui n'a pas défilé avant ne peut pas le voir. */
    /* ⚠ ON RELÈVE LES TROIS GESTES AVANT D'ENTRER : une fois DANS la complication, son bouton
       disparaît (on y est), et le témoin ne verrait plus que deux boîtes. */
    const _actesAvant=[...document.querySelectorAll('.cx-row .blk-act,.flow-ctrl.has-ver .blk-ver')].map(e=>{
      const c=getComputedStyle(e);
      return {fs:c.fontSize,pad:c.padding,h:Math.round(e.getBoundingClientRect().height),col:c.color};});
    window.scrollTo(0,700);await wt(200);
    if(un){un.click();}await wt(900);
    /* L'index ne doit pas s'être ouvert : on est entré directement. */
    const indexAUn=!document.getElementById('dockSheet').hidden;
    const cur2=document.querySelector('.ov-block.cur');
    const entreeY=cur2?Math.round(cur2.getBoundingClientRect().top-stickBase()):null;
    /* Entré sur l'unique événement : la touche ne doit plus le proposer — on y EST. */
    const _k=document.getElementById('cxKey');
    const btnApres=!!_k&&!_k.hidden;
    const _c=document.querySelector('.ov-block.cur');
    const _vp=document.querySelector('.cx-row [data-ovverify],.flow-ctrl.has-ver [data-ovverify]');
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
    const tg=document.getElementById('cxKey');
    const tgLbl=tg?tg.textContent.replace(/\s+/g,' ').trim():null;
    if(tg){tg.click();}await wt(600);
    const items=[...document.querySelectorAll('#dockSheet .ds-row')];
    const modale2=[...document.querySelectorAll('.ai-modal.on')].length;
    const cible=items.length?Math.round(Math.min(...items.map(e=>e.getBoundingClientRect().height))):0;
    const ext=items.some(e=>/↗/.test(e.textContent));
    {const b=document.getElementById('cxKey');if(b)b.click();}await wt(400);
    const referme=document.getElementById('dockSheet').hidden;
    /* ⚠ ON MESURE L'ÉTAT « on y est » LÀ OÙ IL EXISTE DÉJÀ : la première moitié du contrôle nous
       a fait ENTRER sur l'unique complication, et la session vive garde cette position. Il suffit
       donc de déclarer le second événement et de rouvrir l'index. Ma première version rouvrait
       puis cliquait la rangée courante — laquelle est justement DÉSACTIVÉE : le clic ne faisait
       rien et le dernier tap REFERMAIT l'index, d'où zéro rangée mesurée. */
    {const b=document.getElementById('cxKey');if(b)b.click();}await wt(500);
    const ap=[...document.querySelectorAll('#dockSheet .ds-row')];
    const iciEl=ap.find(e=>e.classList.contains('ici'));
    const iciTxt=iciEl?iciEl.textContent.replace(/\s+/g,' ').trim():null;
    const iciDis=ap.filter(e=>e.disabled).length,autreTapable=ap.filter(e=>!e.disabled).length;
    return {unLbl,indexAUn,modale,items:items.length,tgLbl,modale2,cible,ext,referme,
      btnApres,entreeY,verPied,verTete,verCible,actes,iciTxt,iciDis,autreTapable,
      retourY:rr?Math.round(rr.top):null,
      retourVisible:!!(rr&&rr.top>=0&&rr.bottom<=innerHeight),
      contDernier:(()=>{const cc=document.querySelector('.ov-block.cur .ov-body');if(!cc)return null;
        const fc=[...cc.querySelectorAll('.flow-ctrl')].pop();if(!fc)return null;
        const last=fc.lastElementChild;return !!last&&last.classList.contains('cont');})(),
      premier};});
  t(`${W} · B — à UN événement, il n'y a pas d'index (on entre d'un tap)`,
    r.indexAUn===false&&!!r.unLbl&&!/Complications/.test(r.unLbl), `${r.unLbl}`);
  t(`${W} · C — à DEUX, l'index reparaît, et il ne COUVRE rien`,
    r.items===2&&r.modale2===0&&/Complications\s*·\s*2/.test(r.tgLbl||''), `${r.tgLbl} · ${r.items} rangée(s), ${r.modale2} fenêtre(s)`);
  t(`${W} · … rangées ≥ 56 px, et la porte EXTERNE se dit (↗)`, r.cible>=56&&r.ext===true,
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
  /* ⚠ R9 + A7 (v5.6) — LE PIED DE CARTE N'A PLUS QU'UN GESTE. Il en portait trois (⚡︎, ⏱,
     Vérifier) et la pile dépassait le plafond de 25 % de la hauteur de carte sur un bloc court.
     Deux d'entre eux ne sont pas des gestes de BLOC par NATURE — une complication survient quand
     elle survient, un horodatage se pose à n'importe quel moment : ils sont partis au dock, à
     position constante. « Vérifier :: » reste, parce qu'il rejoue les challenges DE CE BLOC.
     L'ancien contrôle mesurait l'UNIFORMITÉ des trois boîtes ; il mesure désormais ce qui la
     remplace — il n'y a plus qu'une boîte, donc plus rien à uniformiser, et c'est vérifiable. */
  /* A7 rend « Vérifier :: » CONDITIONNEL : il n'existe que si le bloc porte des challenges « :: ».
     Le contrôle mesure donc la borne HAUTE — le pied ne porte JAMAIS plus d'un geste — et le fait
     que « Continuer » reste le DERNIER élément de la carte, qui est l'autre moitié de la règle. */
  t(`${W} · le pied de carte ne porte jamais plus d'UN geste`,
    r.actes.n<=1, `${r.actes.n} bouton(s) · corps ${JSON.stringify(r.actes.fs)}`);
  t(`${W} · … et « Continuer » reste le dernier élément`, r.contDernier===true, String(r.contDernier));
  t(`${W} · entrer amène EN HAUT du bloc d'excursion`,
    r.entreeY!==null&&Math.abs(r.entreeY-8)<=4, `${r.entreeY} px sous le chrome collant`);
  t(`${W} · à UN événement, le bouton disparaît quand on y est`,
    r.btnApres===false, `présent=${r.btnApres}`);
  t(`${W} · à DEUX, la rangée où l'on est se dit et n'est plus tapable`,
    r.iciTxt&&/vous y êtes/.test(r.iciTxt)&&r.iciDis===1&&r.autreTapable===1,
    `« ${r.iciTxt} » · ${r.iciDis} désactivée, ${r.autreTapable} tapable`);
  await page.close();
}
});

await sec('CONTRASTE DES ÉTATS · ce qui n’existe qu’après un geste', async () => {
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
});

await sec('BANDEAU · il ne porte plus que l’exception', async () => {
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
    /* ⚠ LE TÉMOIN MESURE LA PROPRIÉTÉ, PAS LE PORTEUR (audit externe v5.10.0). Il lisait
       `bt.querySelector('.bt-d')`, c'est-à-dire le discriminant DANS le titre — donc il validait
       exactement le défaut : la pilule était le dernier enfant d'un nœud ellipsé et n'était jamais
       peinte. La propriété que K6 promet est « le discriminant est LISIBLE quand le titre est
       tronqué » ; on mesure donc qu'il est rendu, qu'il porte le bon texte, et qu'il n'est PAS
       dans la chaîne qui s'ellipse. */
    const bd=document.querySelector('#brandSur .bs-d');
    const discVu=!!bd&&!bd.hidden&&bd.getBoundingClientRect().width>0&&/adulte/.test(bd.textContent);
    const crise=Object.assign(lire(),{titreBarre:bt.textContent.trim(),
      disc:discVu&&!bt.contains(bd)&&bt.scrollWidth>bt.clientWidth,
      /* v5.6 (A14) : la pilule de mode a cédé la place au SUR-TITRE, dans la zone d'identité. */
      pilule:!document.getElementById('brandSur').hidden});
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
  t('… et le discriminant SURVIT à la troncature du titre (K6), hors de la chaîne ellipsée',
    R.crise.disc===true, String(R.crise.disc));
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
});

/* ⚠ LA COLONNE D'ORIENTATION EST DÉSATURÉE — Y COMPRIS SES CHIPS DE BRANCHE (signalé à l'usage).
   En ambre plein, la chip empruntait le registre ATTENTION à ce qui n'est ni une alerte ni un
   point de vigilance : le NOM de la branche. Et le groupe « à tout moment » porte UN rail, du
   titre à la dernière rangée, au lieu d'une bordure par rangée qui semblait surgir. */
await sec('PARCOURS INERTE · registres et cohérence du groupe', async () => {
{
  const page = await br.newPage({viewport:{width:1280,height:900}});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    openRead(fiches[0].id);await w(700);
    /* v5.6 — LA COLONNE D'ORIENTATION N'EXISTE QU'EN SESSION : avant le premier geste, la page
       porte elle-même le parcours inerte (maquettes 1b/1c) et la colonne l'afficherait une
       seconde fois. Le témoin démarre donc la session — c'est l'état où la colonne vit. */
    document.getElementById('sessStart').click();await w(700);});
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
});

await sec('RÉFÉRENCE · le palier se franchit RÉELLEMENT', async () => {
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
});

/* ⚠ CE CONTRÔLE A CHANGÉ D'OBJET PARCE QUE LE COMPOSANT A CHANGÉ DE NATURE (v5.6). Il vérifiait
   qu'une BOÎTE ambre ne perde pas son bord haut — le défaut de v5.0.9, quand un repère signalé
   était une boîte à quatre côtés. Depuis 7d/A16 un repère est une RANGÉE : `border:0`, le
   registre porté par le glyphe et l'encre. Le `border-top` qu'il mesurait n'était plus le bord
   d'une boîte mais le SÉPARATEUR d'item — il passait par coïncidence, et il est passé au rouge le
   jour où ce séparateur est devenu un pseudo-élément pour pouvoir rentrer sans voler de place au
   texte. On mesure donc ce qui reste vrai, et qui est la préoccupation d'origine : deux repères
   qui se suivent restent SÉPARÉS, y compris quand les deux sont signalés. */
await sec('REPÈRES POSOLOGIQUES · deux repères qui se suivent restent séparés', async () => {
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
    const sep=e=>{const b=getComputedStyle(e,'::before');
      return (parseFloat(b.height)||0)>=0.5&&b.content!=='none'&&b.display!=='none';};
    return {n:cs.length,
      boites:cs.filter(c=>c.classList.contains('vig')).length,
      /* Le PREMIER n'a pas de séparateur, et c'est voulu : il n'y a rien au-dessus de lui. */
      sansBordHaut:cs.slice(1).filter(c=>!sep(c)).length};});
  /* Le contrôle doit RENCONTRER SON CAS : il faut DEUX boîtes consécutives, sinon la règle
     fautive ne se déclenche pas et le témoin reste vert sur le défaut. */
  t('témoin : au moins deux repères SIGNALÉS se suivent', r.boites>=2, `${r.boites} sur ${r.n}`);
  t('aucun repère ne perd son séparateur', r.sansBordHaut===0, `${r.sansBordHaut} sans séparateur`);
  await page.close();
}
});

await sec('ACCUEIL · la rangée a un rythme régulier', async () => {
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
      /* ⚠ CE TÉMOIN A CHANGÉ DE PROPRIÉTÉ, PAS DE SUJET (v5.0.0, demande utilisateur : centrer
         le rail). Il exigeait `justify-content:flex-start` — un LITTÉRAL CSS, donc un témoin qui
         rougit sur un changement JUSTE et pousse à le contourner (leçon déjà payée sur le corps
         du titre de rangée). Son intention n'a jamais été « la valeur vaut flex-start » : c'est
         « le rail ne bouge pas ». Le centrage rend la position dépendante du NOMBRE de lettres —
         arbitrage assumé de l'auteur, donc plus mesurable — mais l'autre moitié reste vraie et
         c'est elle qu'on mesure désormais : la boîte est STABLE et le rail COLLÉ À DROITE. */
      railBox:(()=>{const r=document.getElementById('azRail');if(!r)return null;
        const b=r.getBoundingClientRect();
        return {droite:Math.round(window.innerWidth-b.right),h:Math.round(b.height),
          bas:Math.round(window.innerHeight-b.bottom)};})(),
      /* ⚠ ET LA BOÎTE NE SUIT PAS LA BARRE D'OUTILS DU NAVIGATEUR (signalé à l'usage : « il bouge
         sous mon doigt alors qu'il est censé rester fixe »). La hauteur du rail étroit passait par
         `--vvh` = `visualViewport.height`, qui grandit quand la barre se replie AU DÉFILEMENT —
         donc pendant qu'on se sert du rail. Les lettres centrées descendaient de la moitié de
         l'écart et la lettre visée changeait sous le doigt. On simule le repli en posant `--vvh`
         (le sondage de `_vvhSync` ne la réécrit pas : il sort tant que `vv.height` n'a pas bougé)
         et l'on mesure le déplacement de la PREMIÈRE lettre — c'est elle que le doigt vise.
         Vérifié capable d'échouer : avec l'ancienne règle en `--vvh`, 60 px de déplacement. */
      railStable:(()=>{const r=document.getElementById('azRail');if(!r)return null;
        const b0=r.querySelector('[data-azl]');if(!b0)return null;
        const av=b0.getBoundingClientRect().top;
        const rs=document.documentElement.style.getPropertyValue('--vvh');
        document.documentElement.style.setProperty('--vvh',(window.innerHeight-120)+'px');
        const ap=b0.getBoundingClientRect().top;
        if(rs)document.documentElement.style.setProperty('--vvh',rs);
        else document.documentElement.style.removeProperty('--vvh');
        return Math.round(Math.abs(ap-av));})(),
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
  /* v5.6 : l'échelle s'est refermée sur SEPT AUTRES crans (A6) — le titre de rangée descend au
     palier 15 avec l'ensemble du texte courant, et le plancher suit le système au lieu de figer
     un chiffre. C'est exactement la leçon que ce commentaire porte : on mesure l'APPARTENANCE à
     l'échelle et la COHÉRENCE entre rangées, jamais une valeur. */
  {const PALIERS_TXT=[11,12,13.5,15,17.5,21,24];
   const v=parseFloat(String(r.corps[0]||''));
   t(`${W} · le titre reste sur l'échelle typographique`,
     r.corps.length===1&&PALIERS_TXT.indexOf(v)>=0&&v>=15, JSON.stringify(r.corps));}
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
  if(r.railBox){
    t(`${W} · le rail alphabétique reste COLLÉ à droite`, r.railBox.droite===0, JSON.stringify(r.railBox));
    /* Et il ne réserve pas de place pour un objet disparu : la tab bar a été supprimée au lot M4,
       ses 68 px de gouttière étaient restés — invisibles tant que les lettres étaient ancrées en
       haut, décalant tout le rail dès qu'on les a centrées. */
    t(`${W} · … sans gouttière fantôme sous lui`, r.railBox.bas<=24, `${r.railBox.bas} px sous le rail`);
    if(r.railStable!=null)
      t(`${W} · … et ses lettres ne suivent pas la barre d'outils du navigateur`,
        r.railStable<=1, `${r.railStable} px de déplacement`);}
  t(`${W} · « à compléter » n'a plus de fond de chip`,
    /rgba\(0, 0, 0, 0\)|transparent/.test(r.fondTodo||'transparent'), r.fondTodo);
  await page.close();
}
});

/* LA HAUTEUR DU RAIL ÉTROIT NE CITE AUCUNE MESURE QUI BOUGE AU DÉFILEMENT (v5.0.1).
   ⚠ CE TÉMOIN EST STATIQUE, ET C'EST DÉLIBÉRÉ : les deux termes fautifs sont invisibles en
   headless — `--vvh` y vaut la hauteur de la fenêtre, qui ne varie jamais faute de barre
   d'outils, et `env(safe-area-inset-bottom)` y vaut 0, qu'aucune API ne permet de simuler. Un
   contrôle dynamique resterait donc VERT sur le défaut signalé (« il remonte quand on scroll »),
   c'est-à-dire exactement le pire cas du dossier. On mesure donc la SOURCE : dans une hauteur qui
   doit être constante, `--vvh`, `dvh`/`lvh` et l'inset bas sont proscrits — le second parce qu'il
   n'est pas constant dans Safari iOS (la barre d'outils du bas couvre la bande de l'indicateur
   d'accueil : 0 barre déployée, ~34 px barre repliée).
   L'exception est NOMMÉE et bornée : en `display-mode:standalone`, il n'y a pas de barre
   d'outils, l'inset y est constant et il DOIT être retranché. */
await sec('ACCUEIL · le rail A→Z ne suit aucune mesure mouvante', async () => {
{
  const src = await readFile(ROOT + 'index.html', 'utf8');
  const bloc = (src.match(/@supports \(height:100svh\)\{[\s\S]*?\n    \}/) || [''])[0];
  t('témoin : la règle de hauteur du rail étroit est bien trouvée',
    /\.azrail\{bottom:auto;height:/.test(bloc), `${bloc.length} caractères`);
  const horsStandalone = bloc.split('@media (display-mode:standalone)')[0];
  t('… sa hauteur ne cite ni --vvh ni dvh/lvh', !/--vvh|dvh|lvh/.test(horsStandalone),
    horsStandalone.replace(/\s+/g,' ').slice(0,160));
  t('… ni la marge basse du matériel, qui saute au repli de la barre d\'outils',
    !/safe-area-inset-bottom|--sab/.test(horsStandalone),
    horsStandalone.replace(/\s+/g,' ').slice(0,160));
  t('… et l\'app INSTALLÉE, elle, la retranche (aucune barre d\'outils, inset constant)',
    /display-mode:standalone/.test(bloc) && /--sab/.test(bloc.split('@media (display-mode:standalone)')[1]||''),
    bloc.includes('display-mode:standalone') ? 'branche présente' : 'branche absente');
  /* UN SAUT SE CALCULE EN ABSOLU, JAMAIS EN RELATIF. Un pas relatif déduit d'un rect DÉJÀ RENDU
     puis ajouté à la position COURANTE suppose que les deux sont de la même frame — vrai sur
     Blink (défilement synchrone), faux sur iOS, où l'écart devient une oscillation à 60 Hz :
     on descend, ça remonte. Statique là encore, parce qu'aucun moteur headless ne reproduit un
     défilement asynchrone : un contrôle dynamique resterait vert sur le défaut. */
  /* ⚠ ON NEUTRALISE LES COMMENTAIRES AVANT DE MESURER : le code CITE la règle (« jamais
     `scrollBy` »), et un contrôle qui lit sa propre justification échoue sur du texte. Patron
     `check-upload` ; l'approximation tombe du bon côté — sur-neutraliser fait échouer, jamais
     passer sous silence. */
  const fn = ((src.match(/function bindAzRail\(\)[\s\S]*?\n\}/) || [''])[0])
    .replace(/\/\*[\s\S]*?\*\//g,' ').replace(/(^|\n)\s*\/\/[^\n]*/g,'$1');
  t('témoin : le corps de bindAzRail est bien trouvé', /const jump=/.test(fn), `${fn.length} caractères`);
  t('… le saut du rail ne se calcule jamais en relatif',
    !/scrollBy|scrollTop\s*\+=/.test(fn), (fn.match(/scrollBy|scrollTop\s*\+=/g) || []).join(' '));
  /* Et la BOÎTE ne consomme plus `--hdr-h` autrement qu'en repli de première peinture : c'est une
     propriété que `syncHdrScroll` réécrit à CHAQUE défilement, depuis un rect d'élément collant. */
  t('… et sa boîte est gelée dans --azr-top, posée au rendu',
    /top:var\(--azr-top,/.test(src) && /--azr-top/.test(horsStandalone)
      && /rail\.style\.setProperty\('--azr-top'/.test(src),
    `haut=${/top:var\(--azr-top,/.test(src)} hauteur=${/--azr-top/.test(horsStandalone)}`);
}
/* ET LE SAUT RESTE JUSTE — un calcul absolu qui viserait mal serait pire que le pas relatif
   qu'il remplace. On mesure les deux propriétés qui comptent : la lettre atterrit JUSTE SOUS les
   couches collantes (c'est la promesse du geste), et deux appels de suite ne déplacent RIEN
   (l'idempotence est ce qui casse l'oscillation). Les deux voies de défilement sont couvertes :
   la fenêtre en étroit, la colonne `.home-main` en large. */
for (const W of [390, 1100]) {
  const page = await br.newPage({viewport:{width:W,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    /* Le rail n'existe qu'à partir de deux lettres distinctes : sans ce répertoire construit, le
       contrôle ne rencontrerait pas son cas. */
    for(let i=0;i<12;i++)fiches.push(migrate({id:'zaz'+i,
      title:String.fromCharCode(67+i)+' fiche de répertoire '+i,blocks:[]}));
    state.view='library';render();await w(400);
    const rail=document.getElementById('azRail');if(!rail)return null;
    const sc=matchMedia('(min-width:780px)').matches?document.querySelector('main .home-main'):null;
    const pos=()=>sc?Math.round(sc.scrollTop):Math.round(window.scrollY);
    const go=async L=>{[...rail.querySelectorAll('[data-azl]')].find(x=>x.dataset.azl===L).click();
      await w(120);return pos();};
    const out={n:0,ecarts:[],derives:0};
    for(const L of [...rail.querySelectorAll('[data-azl]')].map(x=>x.dataset.azl).slice(0,5)){
      const a1=await go(L);
      const g=document.querySelector(`[data-azg="${L}"]`);
      const haut=sc?g.getBoundingClientRect().top-sc.getBoundingClientRect().top
        :g.getBoundingClientRect().top-document.querySelector('header.bar').getBoundingClientRect().bottom;
      const a2=await go(L),a3=await go(L);
      out.n++;out.ecarts.push(Math.round(haut));if(a1!==a2||a2!==a3)out.derives++;}
    return out;});
  if(r){
    t(`${W} · témoin : des lettres sont réellement parcourues`, r.n>=3, `${r.n}`);
    t(`${W} · la lettre visée atterrit sous les couches collantes`,
      r.ecarts.every(v=>v>=0&&v<=24), JSON.stringify(r.ecarts));
    t(`${W} · … et deux sauts de suite ne déplacent plus rien`, r.derives===0, `${r.derives} dérive(s)`);}
  /* LE REBOND N'EST SUPPRIMÉ QUE PENDANT LA VISÉE, ET C'EST LA PORTÉE QU'ON MESURE. Pendant le
     rubber-band, WebKit translate les éléments `position:fixed` — le rail part avec, sous le
     doigt. Mais `overscroll-behavior` n'ampute pas que le rebond sur WebKit : il ampute aussi
     l'INERTIE, donc le posé en permanence faisait payer le geste le plus fréquent de l'écran (le
     défilement des cartes) pour un geste rare. Trois états à vérifier — AU REPOS le défilement du
     document est celui du système, PENDANT la visée le rebond est supprimé, APRÈS il revient. */
  const o = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const lire=()=>getComputedStyle(document.documentElement).overscrollBehaviorY;
    state.view='library';render();await w(250);
    const rail=document.getElementById('azRail');
    const repos=lire();
    let vise=null,apres=null;
    if(rail){const b=rail.querySelector('[data-azl]').getBoundingClientRect();
      rail.dispatchEvent(new PointerEvent('pointerdown',
        {bubbles:true,clientX:b.left+2,clientY:b.top+2,pointerId:1,buttons:1}));
      vise=lire();
      rail.dispatchEvent(new PointerEvent('pointerup',{bubbles:true,pointerId:1}));
      await w(60);apres=lire();}
    openRead(fiches[0].id);await w(350);
    return {repos,vise,apres,lecture:lire(),
      modale:(()=>{const m=document.querySelector('.ai-modal');
        return m?getComputedStyle(m).overscrollBehaviorY:null;})()};});
  t(`${W} · au repos, le défilement du document est celui du système`, o.repos==='auto', o.repos);
  if(o.vise!=null){
    /* ⚠ EN VOIE LARGE, RIEN NE DOIT CHANGER MÊME PENDANT LA VISÉE : le document n'y défile pas
       (l'accueil est une coque fixe, seule `.home-main` défile) et le rail y est `absolute` dans
       le flux, donc le rebond ne l'a jamais déplacé. La règle est bornée au palier étroit, et
       c'est cette BORNE que le contrôle mesure — sans elle on supprimerait un rebond natif là où
       il ne gêne personne. */
    t(`${W} · … le rebond ${W<780?"n'est supprimé que PENDANT la visée du rail":'reste intact même pendant la visée (rail dans le flux)'}`,
      o.vise===(W<780?'none':'auto'), String(o.vise));
    t(`${W} · … et il revient dès le relâchement`, o.apres==='auto', String(o.apres));}
  t(`${W} · … il reste partout ailleurs`, o.lecture==='auto', o.lecture);
  t(`${W} · … les fenêtres gardant leur « contain »`, o.modale==='contain', String(o.modale));
  await page.close();
}
});

/* UN GESTE DE CHROME NE CHANGE PAS DE VUE (v5.0.0, signalé à l'usage : « fermer la croix d'un
   bandeau efface une des deux invites »). Les binders de l'accueil re-rendaient par
   `renderFiches()` EN DUR, et la vue « Tout » réutilise celui des fiches : fermer un bandeau,
   épingler, ou terminer une session BASCULAIT l'affichage sur les aides seules pendant que
   `state.section` valait toujours 'all' — l'écran et l'état divergeaient.
   ⚠ LE CONTRÔLE DOIT RENCONTRER SON CAS : il faut un PROTOCOLE dans la bibliothèque, sinon
   « Tout » et « Aides » affichent la même chose et le témoin reste vert sur le défaut. Les deux
   fiches d'exemple sont toutes deux des aides. */
await sec('ACCUEIL · un geste de chrome ne change pas de vue', async () => {
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
  /* ⚠ ON COMPTE LE RÉPERTOIRE, PAS LES ÉPINGLÉES (v5.6) : depuis que les épinglées sont des
     RANGÉES et non des tuiles, épingler une fiche en ajoute une seconde à l'écran — le total
     bougerait sans que le CORPUS ait changé, et le témoin rougirait sur un non-défaut. Ce qu'il
     mesure est « la vue n'a pas basculé sur les aides seules », donc le contenu du répertoire. */
  const etat=()=>page.evaluate(()=>({section:state.section,
    rangees:document.querySelectorAll('.dir-book:not(.pinned) .dir-row').length,
    natures:[...new Set([...document.querySelectorAll('.dir-book:not(.pinned) .dir-kind')].map(e=>e.textContent.trim()))]}));
  const av=await etat();
  t('témoin : la vue « Tout » montre les DEUX natures',
    av.section==='all'&&av.natures.length===2, JSON.stringify(av));
  /* v5.6 (demande de l'auteur) — CHANGER DE CRAN N'ANIME PAS LA LISTE. Ce n'est pas une
     navigation : la liste reste la même, seule sa clé change, et l'y faire glisser lui donnait
     l'allure d'un changement d'écran. On mesure l'ABSENCE d'animation sur le conteneur au moment
     du geste — la pastille du sélecteur, elle, continue de glisser (manipulation directe).
     ⚠ IL REPOSE LE CRAN AVANT DE RENDRE LA MAIN : un témoin qui laisse un état derrière lui fait
     échouer les suivants pour la mauvaise raison (leçon du mode déplacement, v4.77.0) — celui-ci
     bascule sur « Aides » et le contrôle d'épinglage, juste après, mesurait ce cran-là. */
  const anim=await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const b=[...document.querySelectorAll('#tabSeg .seg-btn, .grp-seg .seg-btn, [data-sec]')]
      .find(x=>/Aides/i.test(x.textContent||''));
    if(b)b.click();else if(typeof setSection==='function')setSection('fiches');
    await w(60);
    const hm=document.querySelector('.home-main'), m=document.querySelector('main');
    const out={classes:m?[...m.classList].filter(c=>/sec-anim/.test(c)):[],
      nom:hm?getComputedStyle(hm).animationName:'—'};
    state.section='all';render();await w(250);
    return out;});
  t('changer de cran n\'anime pas la liste',
    anim.classes.length===0&&(anim.nom==='none'||anim.nom==='—'), JSON.stringify(anim));
  await page.click('[data-pin]');await page.waitForTimeout(600);
  const ap=await etat();
  t('épingler ne bascule pas sur les aides seules',
    ap.section==='all'&&ap.rangees===av.rangees&&ap.natures.length===2, JSON.stringify(ap));
  /* Et la croix d'un bandeau, le geste EXACT qui a été signalé.
     VOIX SYSTÈME UNIQUE (direction A) : l'amorçage a laissé le bandeau « 2 fiches d'exemple »
     visible, et tant qu'il l'est la notice auteur ATTEND son créneau. Le témoin passe par le
     VRAI geste — on acquitte le bandeau, la notice paraît — plutôt que d'exiger un état que
     l'application ne produit plus (leçon T9 : « un contrôle qui mesure ce que font les crans
     doit passer par le vrai geste »). */
  await page.evaluate(()=>{fiches.length=0;protocols.length=0;
    try{localStorage.removeItem('ac-notice-hidden');}catch(e){}
    const sb=document.getElementById('sysBanner');
    if(sb&&!sb.hidden)document.getElementById('sbX').click();
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
});

/* L'ÉTAT VIDE N'OFFRE QUE CE QU'ON PEUT CRÉER LÀ (v5.0.0, signalé à l'usage : en vue « Tout »,
   le titre était neutre mais le texte et le bouton étaient ceux des AIDES seules). Le nombre de
   cartes doit être exactement le nombre de types créables dans la vue courante, et le bouton
   d'une carte doit ouvrir la création DE SON type — `state.section` étant la source unique du
   type dans le dialogue « Créer », c'est lui qu'on mesure, pas l'apparence du dialogue.
   ⚠ ET LA LEÇON NE S'AFFICHE PAS SOUS UN FILTRE : qui cherche sait déjà ce qu'est une aide ; on
   lui doit un résultat, pas un cours. Le témoin construit donc les DEUX cas. */
await sec('ACCUEIL · l\'état vide n\'offre que ce qu\'on peut créer ici', async () => {
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
});

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
await sec('ACCUEIL · l\'extrait de recherche tient dans sa rangée', async () => {
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
});

await sec('RÉGRESSIONS · déplacement, flèches, losange', async () => {
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
});

await sec('DÉPLIANTS · un tap ne déplace pas l’écran', async () => {
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
    /* v5.6 : « ⏱ Noter l'heure » est une touche du DOCK, et sa réponse est le VOLET qui monte
       de la même touche — « la réponse vit là où le geste a eu lieu » (M11), l'adresse a suivi
       le geste. Le volet est FIXE : il ne peut, par construction, déplacer aucune géométrie de
       flux — c'est ce que le contrôle vérifie, exactement comme pour le volet du quai. */
    const y1=Math.round(scrollY);
    document.getElementById('tkKey').click();await w(600);
    const sh=document.getElementById('dockSheet');
    return {sautQuai,dockBouge,sousLeQuai,panneau:!!pn,
      sautJournal:Math.round(scrollY)-y1,
      lignes:(sh&&!sh.hidden)?sh.querySelectorAll('.ds-in,.ds-card').length:0};});
  t(`${W} · le panneau s’ouvre bien au tap sur le quai`, r.panneau===true);
  t(`${W} · … SANS déplacer l’écran`, r.sautQuai===0, `${r.sautQuai} px`);
  t(`${W} · … ni le quai lui-même`, r.dockBouge<=1, `${r.dockBouge} px`);
  t(`${W} · … et il se pose SOUS le quai`, r.sousLeQuai!==null&&r.sousLeQuai>=0&&r.sousLeQuai<=60, `${r.sousLeQuai} px`);
  t(`${W} · le repère s'accuse dans son volet, sans défiler`, r.sautJournal===0&&r.lignes>=1,
    `saut ${r.sautJournal} px, ${r.lignes} volet(s)`);
  await page.close();
}
});

await sec('PARCOURS INERTE · les marqueurs sont lisibles', async () => {
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
});

await sec('QUAI · le geste d’entrée se détache de sa barre (planches 17-18)', async () => {
/* v5.15.0 — les témoins exigés par les planches 17/1a et 18/2a, sur l'écran HORS session (le
   seul où le geste d'entrée existe), dans les DEUX thèmes :
   (1) l'APLAT du bouton « Démarrer la session » tient 3:1 contre la matière système — 1.4.11
       vise la LIMITE d'un composant, pas son texte : c'était le défaut, --act tenait 1,68:1 et
       la forme du bouton se confondait avec sa propre barre (le défaut de « Reprendre »
       [v5.10.0], jamais rejoué sur le geste d'entrée) ;
   (2) la nuit, le quai se détache de l'ambiance par son PÉRIMÈTRE (--sys-edge, ombre interne,
       3:1 contre le fond) — l'ombre montante y est none, assombrir du noir ne dit rien ; le
       jour, c'est l'ombre montante élargie qui le détache (témoin : elle est bien posée) ;
   (3) sous 430 px effectifs, « Exercice » passe au GLYPHE SEUL sans perdre ni sa cible (44 px,
       A8) ni son nom accessible (aria-label posé par render()). */
{
  for (const theme of ['light','dark']) {
    const page = await br.newPage({viewport:{width:390,height:844},colorScheme:theme});
    page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'));
    await amorce(page);
    await ouvrirFiche(page,/Arrêt cardiaque/);
    const r = await page.evaluate(()=>{
      const lum=c=>{const m=String(c).match(/[\d.]+/g)||[0,0,0];
        const v=m.slice(0,3).map(x=>{const u=(+x)/255;return u<=0.03928?u/12.92:Math.pow((u+0.055)/1.055,2.4);});
        return 0.2126*v[0]+0.7152*v[1]+0.0722*v[2];};
      const ratio=(a,b)=>{const l1=lum(a),l2=lum(b);return +(((Math.max(l1,l2)+0.05)/(Math.min(l1,l2)+0.05))).toFixed(2);};
      const sd=document.querySelector('.sd-in'),sb=document.getElementById('sessStart'),
            ek=document.getElementById('exoKey');
      const csd=getComputedStyle(sd),csb=getComputedStyle(sb);
      /* La couleur du périmètre se lit dans l'ombre INTERNE calculée du quai. */
      const shadow=csd.boxShadow||'';
      const edge=(shadow.match(/rgba?\([^)]+\)/)||[null])[0];
      return {
        aplat:ratio(csb.backgroundColor,csd.backgroundColor),
        inset:/inset/.test(shadow), montante:/-12px/.test(shadow),
        edgeR:edge?ratio(edge,getComputedStyle(document.body).backgroundColor):0,
        ekW:ek.getBoundingClientRect().width,
        ekLblCache:getComputedStyle(ek.querySelector('.dp-lbl')).display==='none',
        ekNom:(ek.getAttribute('aria-label')||'').length>3};});
    const T=theme==='dark'?'sombre':'clair';
    t(`${T} · l'aplat du geste d'entrée tient 3:1 sur sa barre (limite de composant, 1.4.11)`,
      r.aplat>=3, `${r.aplat}:1`);
    if(theme==='dark'){
      t('sombre · le quai est bordé (périmètre en ombre INTERNE, pas d\'ombre portée)',
        r.inset===true&&r.montante===false);
      t('sombre · le périmètre tient 3:1 contre l\'ambiance', r.edgeR>=3, `${r.edgeR}:1`);
    }else{
      t('clair · l\'ombre montante élargie est posée sur le quai (le jour projette)',
        r.montante===true&&r.inset===false);
    }
    t(`${T} · « Exercice » au glyphe seul garde sa cible (≥ 44 px) et son nom accessible`,
      r.ekLblCache===true&&r.ekW>=44&&r.ekNom===true,
      `largeur ${r.ekW} px, libellé caché ${r.ekLblCache}, aria-label ${r.ekNom}`);
    await page.close();
  }
}
});

await sec('QUAI · la structure survit aux ticks', async () => {
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
});

await sec('aidRev · la révision lue pendant le soin', async () => {
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
});

/* ── RÉENTRÉE · on revient sur le soin, pas sur le préambule ─────────────────────────────────
   Mesuré avant correctif : rouvrir une aide dont la session TOURNE déposait à 456 px du bout à
   320 × 640 (356 à 390 × 844), zéro étape cochable à l'écran. Le témoin mesure les DEUX moitiés,
   et la seconde n'est pas décorative : ouvrir une aide SANS session doit continuer d'arriver en
   HAUT DE FICHE (on s'oriente avant d'agir — condition d'entrée QRH). Un atterrissage qui
   s'appliquerait partout remplacerait un défaut par son symétrique.
   ⚠ ET IL VÉRIFIE QU'IL RENCONTRE SON CAS : sur une aide courte, le bout serait visible depuis le
   haut de page et le contrôle resterait vert sans rien prouver. */
await sec('RÉENTRÉE · rouvrir une session vive atterrit sur le bout', async () => {
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
    /* ⚠ LE PRÉDICAT DE RÉGIME EST CELUI DE L'APPLICATION, PAS UN SEUIL À NOUS (A109/4, rejouée ici
       en v5.10.1). Il valait « plus de 100 px à défiler » : un proxy, et un resserrement de 10 px
       du préambule a suffi à faire basculer la page de 106 à 96 px — le témoin a alors exigé
       l'immobilité d'un atterrissage parfaitement juste (mesuré : 88 px défilés, bout déposé à
       8 px sous les couches collantes). `landOnBout` ne décide pas sur une distance mais sur la
       VISIBILITÉ ENTIÈRE du bout depuis le haut de page — « si le bout est déjà entièrement à
       l'écran, rien ne bouge ». On mesure donc cela. */
    vive.boutEntierDepuisLeHaut=(()=>{const c=bout();if(!c)return null;
      const g=c.getBoundingClientRect();
      return g.top>=stickBase()-1&&g.bottom<=innerHeight+1;})();
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
  /* ⚠ LE CAS PEUT NE PLUS SE PRÉSENTER, ET C'EST UNE BONNE NOUVELLE — pas une raison de mentir.
     Depuis R6 (v5.6) l'historique se replie en une ligne-bilan : le journal ne grandit plus, et à
     390 px le contrôle d'avancement est DÉJÀ visible depuis le haut de page. Il n'y a alors rien
     à rattraper, et `landOnBout` a raison de ne pas défiler (« si le bout est déjà entièrement à
     l'écran, rien ne bouge » — un saut qui n'apporte rien escamoterait le chapeau pour rien).
     Le témoin mesure donc la PROPRIÉTÉ dans les deux régimes : quand le cas existe, on atterrit
     sur le bout ; quand il n'existe pas, on ne bouge pas. Écrire l'un sans l'autre rendrait rouge
     un comportement juste — la faute que ce fichier a déjà commise deux fois sur ce témoin. */
  const casExiste=v.boutEntierDepuisLeHaut===false;
  t(`${fmt.w}× régime mesuré : ${casExiste?'le bout est loin, il faut y atterrir':'le bout est déjà là, rien à rattraper'}`,
    true, `${v.aDefilerDepuisLeHaut} px depuis le haut, bout entier=${v.boutEntierDepuisLeHaut}, Continuer visible=${v.continuerDepuisLeHaut}`);
  t(`${fmt.w}× ${casExiste?'la réouverture atterrit sur le bout':'… et la réouverture ne défile pas pour rien'}`,
    casExiste ? (v.aDefiler!=null && v.aDefiler<=12) : (v.scrollY===0),
    `${v.aDefiler} px à défiler, scrollY=${v.scrollY}`);
  t(`${fmt.w}× … avec au moins une étape cochable à l’écran`, v.etapes>=1, `${v.etapes} étape(s)`);
  t(`${fmt.w}× une aide SANS session s’ouvre toujours en haut`, r.inerte===0, `scrollY=${r.inerte}`);
  await page.close();
}
});

/* ── DÉMARRAGE · on atterrit sur le HAUT du premier bloc (v5.0.7) ────────────────────────────
   Presser « Confirmé — démarrer la session » retire ou rétrécit tout ce qui est au-dessus du
   doigt (chapeau replié, condition d'entrée refermée, « Prise en charge » remontée en tête) sans
   que le défilement bouge : on atterrissait au MILIEU de la carte du bloc, titre et premières
   étapes au-dessus du pli.
   ⚠ LE CAS SE CONSTRUIT, IL NE SE RENCONTRE PAS SUR LES FICHES D'EXEMPLE : il faut une condition
   d'entrée assez longue pour qu'on ait DÉFILÉ en la lisant (c'est le cas pour lequel
   `.sess-start.afloat` existe). Le témoin le vérifie par un CONTREFACTUEL — on repose la page où
   elle était au clic et l'on remesure : sans l'atterrissage, le haut de la carte est bien
   au-dessus des couches collantes.
   ET LA NON-RÉGRESSION EST L'AUTRE MOITIÉ : sur une fiche courte, où le haut de la carte est déjà
   à sa place, rien ne doit bouger — un atterrissage inconditionnel déplacerait la page pour tout
   le monde et laisserait les gestes suivants décalés. */
await sec('DÉMARRAGE · le haut du premier bloc est visible', async () => {
for (const fmt of [{w:320,h:640},{w:390,h:844}]) {
  const page = await br.newPage({viewport:{width:fmt.w,height:fmt.h},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  const r = await page.evaluate(async(ITEMS)=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const f=migrate({id:'zstart',title:'Sonde critères longs',start:'b1',
      notForget:['Appeler à l’aide','Adrénaline prête','Vérifier voie et site','Prévenir la régulation'],
      confirmation:['Début brutal après exposition à un allergène connu ou probable',
        'Atteinte cutanéo-muqueuse : urticaire généralisée, angio-œdème, prurit',
        'Atteinte respiratoire : dyspnée, sibilants, stridor, désaturation < 92 %',
        'Atteinte cardiovasculaire : hypotension, tachycardie, marbrures, malaise',
        'Atteinte digestive : douleurs abdominales, vomissements répétés, diarrhée',
        'Deux organes atteints ou plus après exposition suffisent au diagnostic',
        'Hypotension isolée après exposition à un allergène connu du patient',
        'En cas de doute, traiter comme une anaphylaxie — le retard est le facteur de gravité',
        'Bronchospasme résistant aux bêta-2 inhalés chez un patient jusque-là stable',
        'Œdème laryngé : dysphonie, sensation de gorge serrée, tirage inspiratoire',
        'Collapsus sans étiologie évidente dans les minutes suivant une injection',
        /* v5.6 — LE CAS SE CONSTRUIT, IL NE SE SUPPOSE PAS. Le dock a quitté l'écran hors
           session et la condition d'entrée s'est densifiée (rangées serrées au lieu de boîtes) :
           à 390 × 844, onze critères ne descendaient plus sous le pli — le défilement de lecture
           valait donc 0 et le contrefactuel mesurait la MÊME position que le geste (64 px des
           deux côtés, donc deux rouges sur un non-défaut). On rallonge la CONDITION D'ENTRÉE,
           qui est le sujet même de cette sonde (« critères longs ») ; on ne relâche pas le seuil. */
        'Prurit palmo-plantaire ou du cuir chevelu précédant l’éruption',
        'Sensation de mort imminente rapportée par le patient conscient',
        'Récidive dans les heures suivant une première réaction traitée',
        'Exposition professionnelle connue (latex, produits anesthésiques)',
        'Injection intraveineuse de produit de contraste dans l’heure précédente',
        'Piqûre d’hyménoptère avec réaction générale antérieure documentée',
        'Ingestion d’un aliment déjà responsable d’une réaction systémique',
        'Aggravation malgré un traitement symptomatique bien conduit',
        'Terrain asthmatique connu — facteur de gravité indépendant'],
      /* v5.4.2 : le panneau journal a quitté le flux (~70 px) — sans la section « À vérifier »,
         la page devenait trop COURTE sous le pli, le défilement s'écrêtait et le contrefactuel
         ne rencontrait plus son cas (mesuré : -14 px pour un seuil à -20). Le témoin construit
         son cas, il ne le suppose pas. */
      /* v5.6, MÊME RAISON QU'EN v5.4.2 : le dock a quitté l'écran hors session et la condition
         d'entrée s'est densifiée — la page redevenait trop COURTE, le défilement s'écrêtait, et
         le contrefactuel mesurait la même position que le geste (64 px des deux côtés à 390).
         On rallonge le CAS, on ne relâche pas le seuil. */
      verify:['TA toutes les 5 minutes','SpO2 en continu','Conscience et coloration',
        'Récidive possible jusqu’à 72 h — surveillance prolongée',
        'Tryptase sérique : prélèvement à H0, H1 et H24',
        'Voie veineuse maintenue jusqu’à stabilisation complète',
        'Orientation hospitalière systématique, même en cas d’amélioration',
        'Bilan allergologique à distance — consultation spécialisée'],
      blocks:[{id:'b1',kind:'do',title:'Mesures immédiates',next:'b2',items:ITEMS.a},
              {id:'b2',kind:'do',title:'Réévaluation à 5 min',items:ITEMS.b}]});
    await Data.put(f);fiches.push(f);
    openRead(f.id);await w(450);
    // On LIT les critères : défilement jusqu'au bas de la condition d'entrée, puis on démarre.
    const cb=document.querySelector('.conf-block').getBoundingClientRect();
    scrollTo(0,Math.max(0,Math.round(scrollY+cb.bottom-innerHeight+60)));await w(150);
    const yClic=Math.round(scrollY);
    document.getElementById('sessStart').click();await w(600);
    const carte=()=>{const c=[...document.querySelectorAll('.ov-block')];return c[c.length-1]||null;};
    const haut=()=>{const c=carte();return c?Math.round(c.getBoundingClientRect().top-stickBase()):null;};
    const apres=haut();
    const etapes=(()=>{const b=stickBase();
      return [...document.querySelectorAll('ol.steps li[data-ck]')]
        .filter(e=>{const g=e.getBoundingClientRect();return g.top>=b-1&&g.bottom<=innerHeight+1;}).length;})();
    // CONTREFACTUEL : la page reposée où elle était au clic — ce qu'on avait avant le correctif.
    scrollTo(0,yClic);await w(150);
    const sans=haut();
    return {apres,sans,etapes};},
    {a:items(['⚠ Adrénaline IM :: 0,5 mg','Arrêter l’exposition','O2 haut débit au masque',
      'Voie veineuse de gros calibre','Décubitus, jambes surélevées']),
     b:items(['Réévaluer TA, SpO2, conscience','△ Seconde dose si non-amélioration'])});
  t(`${fmt.w}× le contrôle rencontre son cas (sans atterrissage, le haut est masqué)`,
    r.sans!=null && r.sans<-20, `${r.sans} px sous les couches collantes`);
  t(`${fmt.w}× le haut de la carte du bloc est visible après démarrage`,
    r.apres!=null && r.apres>=-1 && r.apres<=12, `${r.apres} px`);
  t(`${fmt.w}× … avec au moins une étape cochable à l’écran`, r.etapes>=1, `${r.etapes} étape(s)`);
  await page.close();
}
{ /* ⚠ LE PORTEUR A CHANGÉ (v5.6) : une fiche mono-bloc rendait la vue guidée (`.nav-wrap`) ; elle
     rend désormais la CARTE de travail comme les autres (cf. « une fiche d'un seul bloc »).
     L'INVARIANT mesuré ici ne bouge pas — le démarrage dépose sur le HAUT du bloc, et la fiche
     mono-bloc est le cas où l'oublier ne se verrait nulle part ailleurs. Seul le sélecteur suit. */
  const page = await br.newPage({viewport:{width:320,height:640},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  const r = await page.evaluate(async(ITEMS)=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const f=migrate({id:'zmono',title:'Sonde mono-bloc',start:'b1',
      notForget:['Appeler à l’aide','Adrénaline prête','Vérifier voie et site','Prévenir la régulation'],
      confirmation:['Début brutal après exposition à un allergène connu ou probable',
        'Atteinte cutanéo-muqueuse : urticaire généralisée, angio-œdème, prurit',
        'Atteinte respiratoire : dyspnée, sibilants, stridor, désaturation < 92 %',
        'Atteinte cardiovasculaire : hypotension, tachycardie, marbrures, malaise',
        'Atteinte digestive : douleurs abdominales, vomissements répétés, diarrhée',
        'Deux organes atteints ou plus après exposition suffisent au diagnostic',
        'Hypotension isolée après exposition à un allergène connu du patient',
        'En cas de doute, traiter comme une anaphylaxie — le retard est le facteur de gravité',
        'Bronchospasme résistant aux bêta-2 inhalés chez un patient jusque-là stable',
        'Œdème laryngé : dysphonie, sensation de gorge serrée, tirage inspiratoire',
        'Collapsus sans étiologie évidente dans les minutes suivant une injection'],
      verify:['TA toutes les 5 minutes','SpO2 en continu','Conscience et coloration',
        'Récidive possible jusqu’à 72 h — surveillance prolongée'],   // v5.4.2 : cf. fixture du flux
      blocks:[{id:'b1',kind:'do',title:'Mesures immédiates',items:ITEMS}]});
    await Data.put(f);fiches.push(f);
    openRead(f.id);await w(450);
    const cb=document.querySelector('.conf-block').getBoundingClientRect();
    scrollTo(0,Math.max(0,Math.round(scrollY+cb.bottom-innerHeight+60)));await w(150);
    const yClic=Math.round(scrollY);
    document.getElementById('sessStart').click();await w(600);
    const h=()=>{const c=[...document.querySelectorAll('.ov-block')].pop();
      return c?Math.round(c.getBoundingClientRect().top-stickBase()):null;};
    const apres=h(); scrollTo(0,yClic); await w(150);
    return {apres,sans:h(),guide:!!document.querySelector('.ov-block')&&!document.querySelector('#readTopSeg')};},
    items(['⚠ Adrénaline IM :: 0,5 mg','Arrêter l’exposition','O2 haut débit au masque']));
  t(`320× témoin : la fiche mono-bloc rend la carte, sans bascule de format`, r.guide===true);
  t(`320× mono-bloc : le contrôle rencontre son cas (sans atterrissage, le haut est masqué)`,
    r.sans!=null&&r.sans<-20, `${r.sans} px`);
  t(`320× mono-bloc : le haut du bloc est visible après démarrage`,
    r.apres!=null&&r.apres>=-1&&r.apres<=12, `${r.apres} px`);
  await page.close();
}
{ // NON-RÉGRESSION — fiche courte : le haut est déjà à sa place, rien ne bouge.
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  await ouvrirFiche(page,/Anaphylaxie/);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const y0=Math.round(scrollY);
    document.getElementById('sessStart').click();await w(600);
    const c=[...document.querySelectorAll('.ov-block')].pop();
    return {saut:Math.round(scrollY)-y0,
      haut:c?Math.round(c.getBoundingClientRect().top-stickBase()):null};});
  t(`390× fiche courte : le démarrage ne déplace pas la page`, r.saut===0, `${r.saut} px`);
  t(`390× … et le haut de la carte y était déjà`, r.haut!=null&&r.haut>=0, `${r.haut} px`);
  await page.close();
}
});

/* ── LE CHAPEAU ENTRE LES CRITÈRES ET LE BOUTON (v5.0.8) ────────────────────────────────────
   Séquence QRH : condition d'entrée → memory items → geste d'entrée. Trois propriétés, et la
   deuxième est celle qui distingue cette variante de « descendre le chapeau » tout court : il ne
   passe JAMAIS sous le bouton, sinon on l'aurait rangé derrière le geste qu'il doit précéder.
   La troisième est la non-régression : une fois la session démarrée, le chapeau replié revient en
   tête (T3 + T5) — rien de ce qui existait ne change. */
await sec('CHAPEAU · condition d’entrée → memory items → bouton', async () => {
{
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  await ouvrirFiche(page,/Anaphylaxie/);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    await w(300);
    const Y=s=>{const e=document.querySelector(s);return e?Math.round(e.getBoundingClientRect().top+scrollY):null;};
    const avant={conf:Y('.conf-block'),fs:Y('.forget-strip'),btn:Y('#sessStart'),
      n:document.querySelectorAll('.forget-strip').length};
    document.getElementById('sessStart').click();await w(600);
    const apres={fs:Y('.forget-strip'),carte:Y('.ov-block'),
      n:document.querySelectorAll('.forget-strip').length,
      replie:!!document.querySelector('.forget-strip.fs-foldable')};
    return {avant,apres};});
  const a=r.avant,b=r.apres;
  t('hors session : les critères viennent EN PREMIER',
    a.conf!=null&&a.fs!=null&&a.conf<a.fs, `conf ${a.conf}, chapeau ${a.fs}`);
  t('hors session : le chapeau reste AU-DESSUS du bouton',
    a.fs!=null&&a.btn!=null&&a.fs<a.btn, `chapeau ${a.fs}, bouton ${a.btn}`);
  t('le chapeau n’est rendu QU’UNE fois', a.n===1&&b.n===1, `${a.n} avant, ${b.n} après`);
  t('en session : le chapeau replié revient en tête, au-dessus de la carte',
    b.fs!=null&&b.carte!=null&&b.fs<b.carte&&b.replie===true,
    `chapeau ${b.fs}, carte ${b.carte}, repliable=${b.replie}`);
  await page.close();
}
{ /* ══ v5.6 — L'ÉCRAN D'ENTRÉE NE PORTE QUE CE QUI SERT À DÉCIDER D'ENTRER ═══════════════════
     Signalé à l'usage. Trois retraits et un déplacement : « Surveiller ensuite » est par
     définition ce qui vient APRÈS les gestes (il revient au premier geste, et la colonne
     d'orientation le porte en permanence en voie large) ; la rangée « Consulter » appartient au
     soin (elle reste à un tap par le renvoi des différentiels et par le menu ⋯) ; et les deux
     façons de REGARDER la fiche entière passent au-dessus de « Prise en charge », en boutons.
     ⚠ ET CE SONT DES EXCURSIONS, PAS DES RÉGLAGES : « Tableau » écrivait `state.readMode` et
     re-rendait, or le retour d'excursion vit dans le DOCK, qui n'existe pas avant le premier
     geste — on était enfermé dans le tableau, et le cockpit y perdait ses deux colonnes. Le
     témoin mesure donc l'ALLER **et** le RETOUR, colonnes comprises. */
  for(const [nom,W] of [['390',390],['1280',1280]]){
    const page = await br.newPage({viewport:{width:W,height:900},hasTouch:W<780});
    page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
    await page.goto(`http://localhost:${port}/index.html`);
    await amorce(page);
    await ouvrirFiche(page,/Anaphylaxie/);
    const r = await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
      const Y=s=>{const e=document.querySelector(s);return e?Math.round(e.getBoundingClientRect().top):null;};
      const titres=[...document.querySelectorAll('main .cp-h')].map(e=>e.textContent.trim());
      const av={titres, consulter:document.querySelectorAll('main .annex-row').length,
        liens:Y('.pre-links'), pec:(()=>{const h=[...document.querySelectorAll('main .cp-h')]
          .find(x=>/Prise en charge/.test(x.textContent));return h?Math.round(h.getBoundingClientRect().top):null;})(),
        hLien:(()=>{const b=document.querySelector('.pre-link');return b?Math.round(b.getBoundingClientRect().height):null;})(),
        rangee:(()=>{const l=document.querySelector('.rail-lad .pl-line');return l?Math.round(l.getBoundingClientRect().height):null;})()};
      /* SCHÉMA : il n'ouvrait RIEN — `openFlowFull(f)` prend la fiche et l'appel l'omettait. */
      const bs=[...document.querySelectorAll('.pre-link')].find(x=>/Schéma/.test(x.textContent));
      if(bs)bs.click();await w(450);
      const ff=document.getElementById('flowFull');
      const svg={ouvert:!!(ff&&ff.classList.contains('on')),
        noeuds:ff?ff.querySelectorAll('svg .fn, svg g').length:0};
      document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',bubbles:true}));await w(350);
      /* TABLEAU : une feuille, donc la page reste dessous — et l'on en SORT. */
      const bt=[...document.querySelectorAll('.pre-link')].find(x=>/Tableau/.test(x.textContent));
      if(bt)bt.click();await w(600);
      const pm=document.getElementById('planModal');
      const tab={ouvert:!!(pm&&pm.classList.contains('on')),
        cellules:pm?pm.querySelectorAll('.sv-cell').length:0,
        sortie:!!(pm&&pm.querySelector('.ai-x')),
        modeIntact:state.readMode!=='static'};
      document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',bubbles:true}));await w(450);
      const apres={modale:!!document.querySelector('#planModal.on'),
        demarrer:!!document.getElementById('sessStart'),
        plan:!!document.querySelector('.read-plan'), rail:!!document.querySelector('.read-side')};
      return {av,svg,tab,apres};});
    t(`${nom} · « Surveillances & pièges » n'est pas sur l'écran d'entrée`,
      !r.av.titres.some(x=>/Surveillance/i.test(x)), JSON.stringify(r.av.titres));
    t(`${nom} · ni la rangée « Consulter »`, r.av.consulter===0, `${r.av.consulter}`);
    t(`${nom} · Tableau/Schéma passent AU-DESSUS de « Prise en charge »`,
      r.av.liens!=null&&r.av.pec!=null&&r.av.liens<r.av.pec, `liens ${r.av.liens}, PEC ${r.av.pec}`);
    t(`${nom} · … et ce sont des boutons de 44 px`, r.av.hLien>=44, `${r.av.hLien} px`);
    /* Le parcours se resserre AVANT le soin — et pas d'un cheveu : la rangée passe sous les 44 px
       de la crise, qui ne s'appliquent pas ici, en restant au-dessus du plancher hors crise. */
    t(`${nom} · le parcours d'entrée est compact (32 ≤ h < 44)`,
      r.av.rangee>=32&&r.av.rangee<44, `${r.av.rangee} px`);
    t(`${nom} · « Schéma » ouvre RÉELLEMENT le schéma`,
      r.svg.ouvert===true&&r.svg.noeuds>0, JSON.stringify(r.svg));
    t(`${nom} · « Tableau » ouvre une FEUILLE, avec sa sortie`,
      r.tab.ouvert===true&&r.tab.cellules>0&&r.tab.sortie===true, JSON.stringify(r.tab));
    t(`${nom} · … sans toucher au format de lecture (regarder ≠ régler)`, r.tab.modeIntact===true);
    t(`${nom} · on REVIENT sur l'écran d'entrée`,
      r.apres.modale===false&&r.apres.demarrer===true, JSON.stringify(r.apres));
    if(W>=1200) t(`${nom} · … et les deux colonnes sont toujours là`,
      r.apres.plan===true&&r.apres.rail===true, JSON.stringify(r.apres));
    /* ══ v5.6 (planche 11a) — « PRÊT » SE DIT SUR LA FICHE, PAS SUR L'ACCUEIL ═══════════════
       La jauge d'accueil disait le manque au mauvais endroit : on l'apprenait en perdant le
       réseau. La ligne vit sous les excursions, et surtout elle NE CONDITIONNE RIEN — c'est la
       propriété qui compte, et c'est celle qu'on mesure : le bouton de démarrage reste actif
       avec des pièces manquantes. Un soin ne s'arrête pas parce qu'un PDF n'est pas là. */
    const pr = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
      const f=state.fiche;
      f.docs=[{id:'zd1',name:'Protocole SFAR 2024',size:1024},{id:'zd2',name:'Fiche produit',size:512}];
      await persist();render();await w(600);
      const L=()=>{const e=document.getElementById('preReady');
        return e&&!e.hidden?{cls:e.className,txt:e.textContent.replace(/\s+/g,' ').trim()}:null;};
      const manque=L(), dem1=!!document.getElementById('sessStart');
      const pdf=new Uint8Array([37,80,68,70,45,49,46,52,10]).buffer;
      await IDB.putAtt({id:'zd1',blob:pdf,size:9});await IDB.putAtt({id:'zd2',blob:pdf,size:9});
      await refreshPreReady(state.fiche);await w(250);
      const pret=L();
      /* Une fiche SANS document n'a rien à dire : pas de ligne. */
      f.docs=[];await persist();render();await w(500);
      return {manque,dem1,pret,sansDoc:L()};});
    t(`${nom} · une pièce manquante se dit SUR la fiche`,
      !!pr.manque&&/warn/.test(pr.manque.cls)&&/non disponible/.test(pr.manque.txt),
      JSON.stringify(pr.manque));
    t(`${nom} · … et ne conditionne RIEN : « démarrer » reste actif`, pr.dem1===true);
    t(`${nom} · tout présent : la ligne le confirme, sans ambre`,
      !!pr.pret&&!/warn/.test(pr.pret.cls)&&/tous disponibles/.test(pr.pret.txt),
      JSON.stringify(pr.pret));
    t(`${nom} · aucun document : aucune ligne`, pr.sansDoc===null, JSON.stringify(pr.sansDoc));
    await page.close();
  }
}
{ /* SANS CRITÈRES, il n'y a pas de séquence à ordonner : le chapeau reprend sa place en tête —
     c'est la même condition qui protège l'invité et l'aperçu d'essai, où le bouton n'existe pas. */
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  const r = await page.evaluate(async(ITEMS)=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const f=migrate({id:'zsanscrit',title:'Sonde sans critères',start:'b1',
      notForget:['Appeler à l’aide','Adrénaline prête'],confirmation:[],
      verify:['TA toutes les 5 minutes','SpO2 en continu','Conscience et coloration',
        'Récidive possible jusqu’à 72 h — surveillance prolongée'],   // v5.4.2 : cf. fixture du flux
      blocks:[{id:'b1',kind:'do',title:'Mesures immédiates',items:ITEMS}]});
    await Data.put(f);fiches.push(f);openRead(f.id);await w(450);
    const Y=s=>{const e=document.querySelector(s);return e?Math.round(e.getBoundingClientRect().top+scrollY):null;};
    return {conf:!!document.querySelector('.conf-block'),fs:Y('.forget-strip'),btn:Y('#sessStart')};},
    items(['⚠ Adrénaline IM :: 0,5 mg','Arrêter l’exposition']));
  t('témoin : la fiche sans critères n’a pas de condition d’entrée', r.conf===false);
  t('sans critères : le chapeau reste en tête, au-dessus du bouton',
    r.fs!=null&&r.btn!=null&&r.fs<r.btn, `chapeau ${r.fs}, bouton ${r.btn}`);
  await page.close();
}
});

/* ── LE PARCOURS MONTRE TOUT CE QU'IL PROMET (v5.0.9) ───────────────────────────────────────
   Trois défauts signalés à l'usage, tous dans l'onglet « Parcours » de « Toute la fiche ».
   (1) La réponse attendue était `flex:none` dans une rangée qui n'enroulait pas : le seul objet
   compressible était le GESTE, qui tombait à quelques pixels pendant que la pilule sortait de la
   carte. Le témoin CONSTRUIT SON CAS — une réponse volontairement longue, sur l'écran le plus
   étroit servi : sur les fiches d'exemple, aucune réponse ne déborde et le contrôle serait resté
   vert sur le défaut. (2) L'étiquette d'une branche n'était posée que devant sa première CARTE,
   or une branche qui ne fait que boucler n'en a pas : elle disparaissait. (3) Cette branche-là
   n'affichait alors RIEN, dans une vue qui promet la fiche entière.
   L'INERTIE reste mesurée avec eux : rien de tout cela n'introduit un geste. */
await sec('PARCOURS · la réponse enroule, la branche se nomme', async () => {
{
  const page = await br.newPage({viewport:{width:320,height:640},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  const r = await page.evaluate(async(ITEMS)=>{const w=m=>new Promise(x=>setTimeout(x,m));
    /* Fiche ADVERSE : une décision dont UNE branche boucle (donc sans carte), et une réponse
       attendue plus longue que la carte n'est large. */
    const f=migrate({id:'zparcours',title:'Sonde parcours',start:'b1',
      blocks:[{id:'b1',kind:'do',title:'Mesures',items:ITEMS,next:'b2'},
        {id:'b2',kind:'decision',title:'Réévaluation',question:'Amélioration ?',
          options:[{label:'Oui — stabilisé',target:'b3'},{label:'Non — réfractaire',target:'b1'}]},
        {id:'b3',kind:'do',title:'Suite',items:[],next:null}]});
    await Data.put(f);fiches.push(f);openRead(f.id);await w(450);
    document.getElementById('sessStart').click();await w(500);
    document.getElementById('allBtn').click();await w(600);
    document.querySelector('[data-alltab="parcours"]').click();await w(600);
    const wrap=document.querySelector('.pc-wrap');if(!wrap)return {err:'pas de .pc-wrap'};
    const deb=[],ecr=[];let avecR=0;
    /* ⚠ v5.6 : la SÉQUENCE est une pile de RANGÉES, et seul le bloc COURANT développe ses items
       (les autres n'affichent que leur compte — le contenu complet, c'est l'onglet « Page »).
       Le porteur d'un `.pc-it` est donc `.pc-row.cur` OU une des trois cartes encadrantes ; ne
       scanner que `.pc-card` rendait un ensemble vide, donc un témoin faux. */
    wrap.querySelectorAll('.pc-card,.pc-row').forEach(c=>{const cb=c.getBoundingClientRect();
      c.querySelectorAll('.pc-it').forEach(it=>{
        const tx=it.querySelector('.pc-t'),rp=it.querySelector('.pc-r');
        if(tx&&tx.getBoundingClientRect().width<60)ecr.push(tx.textContent.slice(0,24));
        if(!rp)return;avecR++;const rb=rp.getBoundingClientRect();
        if(rb.right>cb.right+.5||rb.left<cb.left-.5)deb.push({t:(tx||{}).textContent,d:Math.round(rb.right-cb.right)});});});
    const avant=state.checked&&JSON.stringify(state.checked);
    const it0=wrap.querySelector('.pc-it');if(it0)it0.click();await w(150);
    return {deb,ecr,avecR,
      brc:[...wrap.querySelectorAll('.pl-brc')].map(x=>x.textContent.trim()),
      jmp:[...wrap.querySelectorAll('.pc-jmp')].map(x=>x.textContent.trim()),
      ck:wrap.querySelectorAll('[data-ck]').length,
      inerte:JSON.stringify(state.checked)===avant};},
    items(['⚠ Curariser :: succinylcholine, après vérification de la kaliémie et du délai de jeûne',
      'Ventilation :: PaCO2 35–45 mmHg']));
  t('témoin : le cas est RENCONTRÉ (des réponses attendues sont rendues)', r.avecR>=2, JSON.stringify({avecR:r.avecR,err:r.err}));
  t('la réponse attendue ne sort jamais de sa carte', (r.deb||[]).length===0, JSON.stringify(r.deb));
  t('… et elle n’écrase pas le geste', (r.ecr||[]).length===0, JSON.stringify(r.ecr));
  t('CHAQUE branche de la décision porte son étiquette',
    (r.brc||[]).length===2&&/OUI/.test(r.brc[0])&&/NON/.test(r.brc[1]), JSON.stringify(r.brc));
  /* Les DEUX branches de cette fiche sont sans carte — l'une rejoint le point de convergence
     (« → »), l'autre reboucle sur un bloc déjà décrit (« ↺ ») : les deux formes de renvoi que
     `flowPlan` sait émettre, donc les deux qui disparaissaient. */
  t('une branche sans carte affiche son renvoi au lieu de rien',
    (r.jmp||[]).length===2&&r.jmp.some(x=>/^→/.test(x))&&r.jmp.some(x=>/^↺/.test(x)), JSON.stringify(r.jmp));
  t('la vue reste INERTE (aucun data-ck, rien ne se coche)', r.ck===0&&r.inerte===true, JSON.stringify({ck:r.ck,inerte:r.inerte}));
  await page.close();
}
});

/* ── LE CHROME COLLANT NE SUIT PAS LE DÉFILEMENT (v5.0.9) ───────────────────────────────────
   `--hdr-h` est le `top` collant de la rangée de commandes, donc du quai empilé dessus ; il était
   dérivé du `bottom` de l'en-tête, c'est-à-dire d'une POSITION. Au rebond de fin de course, iOS
   TRANSLATE tout le document, en-tête collant compris : les deux rangées descendaient puis
   revenaient, à la cadence du doigt (signalé à l'usage, vidéo à l'appui).
   ⚠ CE QUE LE COMPOSITEUR FAIT DU RENDU N'EST VISIBLE DANS AUCUNE MESURE DE LA PAGE, et Blink ne
   rebondit pas : un contrôle qui se contenterait de défiler resterait vert sur le défaut. On
   DÉPLACE donc l'en-tête sans changer sa hauteur — le stand-in fidèle de ce que fait le
   compositeur — et l'on vérifie que la géométrie du chrome ne bouge pas d'un pixel. */
await sec('CHROME · une géométrie ne se dérive pas d’une position', async () => {
{
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  await ouvrirFiche(page,/Anaphylaxie/);
  await demarrerSession(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const V=n=>getComputedStyle(document.documentElement).getPropertyValue(n).trim();
    const T=id=>{const e=document.getElementById(id);return e?getComputedStyle(e).top:null;};
    syncHdrScroll();await w(60);
    const avant={h:V('--hdr-h'),s:V('--stick-top'),ctrl:T('crisisCtrl'),dock:T('crisisDock')};
    const hb=document.querySelector('header.bar'),old=hb.style.transform;
    hb.style.transform='translateY(64px)';syncHdrScroll();await w(60);
    const pendant={h:V('--hdr-h'),s:V('--stick-top'),ctrl:T('crisisCtrl'),dock:T('crisisDock')};
    hb.style.transform=old;syncHdrScroll();await w(60);
    const apres={h:V('--hdr-h'),s:V('--stick-top')};
    /* Le témoin doit rencontrer son cas : sans déplacement mesurable, il ne prouverait rien. */
    return {avant,pendant,apres,decale:64};});
  const a=r.avant,b=r.pendant;
  /* v5.6 : il n'y a plus qu'UNE couche collante sous l'en-tête — la capsule d'état. La rangée de
     commandes est devenue le dock BAS, qui est `fixed` et n'entre donc dans aucun empilement de
     `top`. Le témoin mesure ce qui reste : une hauteur d'en-tête et un `--stick-top` non nuls,
     plus la capsule réellement posée. */
  t('témoin : le chrome a une géométrie non nulle à mesurer',
    !!a.h&&a.h!=='0px'&&!!a.s&&a.s!=='0px'&&!!a.dock&&a.dock!=='auto', JSON.stringify(a));
  t('--hdr-h ne bouge pas quand l’en-tête est déplacé', a.h===b.h, `${a.h} → ${b.h}`);
  t('--stick-top ne bouge pas non plus', a.s===b.s, `${a.s} → ${b.s}`);
  t('… donc la capsule collante ne se décale pas',
    a.dock===b.dock, JSON.stringify({avant:a.dock,pendant:b.dock}));
  t('l’état revient à l’identique', r.apres.h===a.h&&r.apres.s===a.s, JSON.stringify(r.apres));
  await page.close();
}
});

/* ── UN BLOC COMPLET L'EST SUR TOUTE SA BORDURE (v5.0.9, signalé à l'usage) ─────────────────
   `.done` n'écrivait que le liseré gauche : un bloc courant ET complet portait un cadre bleu avec
   une seule arête verte. La carte REPLIÉE le faisait déjà — le même bloc changeait donc de
   registre selon qu'il était plié. Une DÉCISION reste exclue : son ambre prime sur l'état. */
await sec('BLOC COMPLET · le registre tient sur les quatre côtés', async () => {
{
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  await ouvrirFiche(page,/Anaphylaxie/);
  await demarrerSession(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const cs=()=>{const s=document.querySelector('.ov-block.cur');if(!s)return null;const c=getComputedStyle(s);
      return {cls:s.className,top:c.borderTopColor,right:c.borderRightColor,bottom:c.borderBottomColor,left:c.borderLeftColor};};
    const avant=cs();
    let sec=document.querySelector('.ov-block.cur');
    const n=sec.querySelectorAll('[data-ck]').length;
    for(let i=0;i<n;i++){const li=[...document.querySelectorAll('.ov-block.cur [data-ck]')].find(x=>!x.classList.contains('done'));
      if(!li)break;li.click();await w(80);}
    return {avant,apres:cs(),n};});
  const a=r.avant,b=r.apres;
  t('témoin : le bloc n’était PAS complet au départ', !/\bdone\b/.test(a.cls)&&r.n>0, JSON.stringify({cls:a.cls,n:r.n}));
  t('… et il l’est après avoir tout coché', /\bdone\b/.test(b.cls), b.cls);
  t('les quatre côtés passent au même registre',
    b.top===b.right&&b.right===b.bottom&&b.bottom===b.left, JSON.stringify(b));
  t('… et ce registre est bien celui du liseré « fait »', b.top!==a.top&&b.top===b.left, `${a.top} → ${b.top}`);
  await page.close();
}
});

/* ═══ JALONS DE BOUCLE (v5.5.0, P1+P2+P3+P4) — le seuil ne repose plus sur la mémoire ═══
   Le cas est celui de la fiche d'exemple ACR (lot T13 : les exemples EXERCENT la doctrine) :
   jalon « Chocs délivrés ≥ 3 » sur la décision d'analyse, renvoi ⚡ vers l'excursion
   « FV réfractaire ». Le contrôle vérifie d'abord qu'il RENCONTRE SON CAS — si la fiche
   d'exemple perdait son jalon, ce serait un rouge bruyant, pas une passe vide. */
await sec('QRH · jalons de boucle — le compte, jamais la mémoire', async () => {
{
  const page=await br.newPage({viewport:{width:1280,height:900}});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  await ouvrirFiche(page,/Arrêt cardiaque/);
  await demarrerSession(page);
  // Avancer jusqu'au bloc porteur : cocher le bloc 1, puis « Continuer » vers l'analyse.
  await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    for(let i=0;i<12;i++){const li=[...document.querySelectorAll('.ov-block.cur [data-ck]')].find(x=>!x.classList.contains('done'));
      if(!li)break;li.click();await w(60);}
    const nx=document.querySelector('.ov-block.cur [data-ovnext]');if(nx)nx.click();await w(250);});
  const c0=await page.evaluate(()=>{
    const cur=document.querySelector('.ov-block.cur');
    const row=cur&&cur.querySelector('.jl-row');
    const prog=row&&row.querySelector('.jl-prog');
    return {dec:!!(cur&&cur.classList.contains('dec')),row:!!row,on:!!(row&&row.classList.contains('on')),
      cond:row?row.textContent:'',prog:prog?prog.textContent.trim():'',
      btn:!!(cur&&cur.querySelector('.jl-go')),y:window.scrollY};});
  t('le contrôle rencontre son cas : la décision d\'analyse porte un jalon compteur', c0.dec&&c0.row, JSON.stringify({dec:c0.dec,row:c0.row}));
  t('AVANT le seuil : ligne présente mais PAS mise en avant, condition en toutes lettres + progression 0/3',
    !c0.on&&/Chocs délivrés\s*≥\s*3/.test(c0.cond)&&c0.prog==='0/3', JSON.stringify({on:c0.on,prog:c0.prog,cond:c0.cond.slice(0,60)}));
  t('… et aucun bouton de renvoi avant le seuil (l\'index ⚡ constant du pied suffit)', c0.btn===false);
  // 3 incréments du compteur « Chocs délivrés » (rail droit, 1280) : le franchissement se peint
  // par setCounterVal (chirurgie), jamais par un re-rendu ni un défilement.
  const c1=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const btn=[...document.querySelectorAll('[data-cninc]')].find(b=>/Chocs/.test(b.getAttribute('aria-label')||''));
    if(!btn)return {err:'compteur Chocs introuvable dans le rail'};
    const y0=window.scrollY;
    for(let i=0;i<3;i++){btn.click();await w(120);}
    const cur=document.querySelector('.ov-block.cur');
    const row=cur&&cur.querySelector('.jl-row');
    const go=cur&&cur.querySelector('.jl-go');
    const prog=row&&row.querySelector('.jl-prog');
    return {on:!!(row&&row.classList.contains('on')),prog:prog?prog.textContent.trim():'',
      go:go?go.textContent:'',dy:Math.abs(window.scrollY-y0)};});
  t('AU seuil (3 incréments) : la ligne passe au registre ATTENTION, progression vivante 3/3',
    c1.on===true&&c1.prog==='3/3', JSON.stringify(c1));
  t('… le renvoi ⚡ vers l\'excursion apparaît', /FV réfractaire/.test(c1.go||''), JSON.stringify(c1.go||c1.err));
  t('… et RIEN ne bouge à l\'écran au franchissement (règle 11)', c1.dy<=1, 'Δ='+c1.dy+'px');
  // P2 : le renvoi EST une entrée d'excursion — nouveau passage ⚡, retour prévu, jamais laissé
  // à la mémoire (AC 120-71B).
  const c2=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const go=document.querySelector('.ov-block.cur .jl-go');if(!go)return {err:'pas de renvoi'};
    go.click();await w(300);
    const cur=document.querySelector('.ov-block.cur');
    return {titre:cur?cur.textContent.slice(0,300):'',cx:!!(cur&&cur.querySelector('.cx-tag')),
      back:!!(cur&&cur.querySelector('[data-cxback]'))};});
  t('P2 : le renvoi entre dans l\'excursion (nouveau passage marqué ⚡ complication)',
    c2.cx===true&&/FV réfractaire/.test(c2.titre), JSON.stringify({cx:c2.cx,err:c2.err}));
  t('… avec le retour prévu « ↩ Reprendre » en tête de carte', c2.back===true);
  // Retour à l'analyse, puis les vues de STRUCTURE annoncent le jalon (inertes, condition en
  // toutes lettres) et P4 annote les renvois de boucle de la période du cycle.
  const c3=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const bk=document.querySelector('.ov-block.cur [data-cxback]');if(bk)bk.click();await w(250);
    const lad=[...document.querySelectorAll('.read-plan .pl-line')].find(l=>/Analyse du rythme/.test(l.textContent));
    const srj=lad?/jalon de boucle/.test(lad.textContent):false;
    if(lad)lad.click();await w(200);
    const jll=document.querySelector('.read-plan .pl-jll');
    const ab=document.getElementById('allBtn');if(ab)ab.click();await w(400);
    const svjl=[...document.querySelectorAll('.sv-jl')].map(e=>e.textContent).join('|');
    const svloop=[...document.querySelectorAll('.sv-jump.loop')].map(e=>e.textContent).join('|');
    const pt=document.querySelector('[data-alltab="parcours"]');if(pt)pt.click();await w(300);
    const pcjl=[...document.querySelectorAll('.pc-jl')].map(e=>e.textContent).join('|');
    /* v5.6 : le renvoi de boucle a quitté le pied de carte pour la COLONNE DE DROITE de la
       rangée — c'est la même information (où va-t-on après) au même endroit que les renvois
       d'une décision. Le témoin suit le composant, il ne disparaît pas avec son ancien porteur. */
    const pcloop=[...document.querySelectorAll('.pc-row .pc-go')].filter(e=>/↺/.test(e.textContent)).map(e=>e.textContent).join('|');
    return {srj,jll:jll?jll.textContent:'',svjl,svloop,pcjl,pcloop};});
  t('Échelle : la ligne ANNONCE le jalon et le détail déplié dit la condition',
    c3.srj===true&&/Chocs délivrés ≥ 3/.test(c3.jll), JSON.stringify({srj:c3.srj,jll:c3.jll.slice(0,60)}));
  t('Statique : la cellule porte le jalon, condition en toutes lettres', /Chocs délivrés ≥ 3/.test(c3.svjl), c3.svjl.slice(0,80));
  t('Parcours : idem, inerte', /Chocs délivrés ≥ 3/.test(c3.pcjl), c3.pcjl.slice(0,80));
  t('P4 : les renvois de boucle portent la période du cycle (statique ET parcours)',
    /toutes les 2 min/.test(c3.svloop)&&/toutes les 2 min/.test(c3.pcloop),
    JSON.stringify({sv:c3.svloop.slice(0,60),pc:c3.pcloop.slice(0,60)}));
  await page.close();
}
});

/* ══ v5.6, PLANCHES 7e/8d — TROIS GABARITS DE FENÊTRE, EN-TÊTE FIXE, CORPS QUI DÉFILE ══════
   Trois propriétés, et la première est celle qu'aucun garde-fou statique ne pouvait voir : une
   largeur écrite EN LIGNE (`style="max-width:560px"`) échappe à check-type comme à check-space,
   qui lisent le bloc `<style>` (leçon A23). On mesure donc les largeurs RENDUES.
   La deuxième est la propriété d'usage : sur une fenêtre longue, le titre ne doit pas s'en aller
   par le haut et l'action ne doit pas se chercher au bout d'un défilement.
   La troisième est le PLACEMENT : un DOCUMENT devient une feuille pleine hauteur sous 780 px,
   un CHOIX reste une fenêtre centrée à la hauteur de son contenu. */
await sec('v5.6 · trois gabarits de fenêtre', async () => {
{
  const GABARITS=[420,480,720];
  const OUV={filtSheet:"document.getElementById('filtTog').click()", authModal:'openAuth()',
             catModal:'openCatMgr()', sessModal:'openSessHist()', storageModal:'openStorageInfo()',
             reportModal:null};
  for(const W of [390,1100]){
    const page=await br.newPage({viewport:{width:W,height:844},hasTouch:W<780});
    page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'));
    await amorce(page);
    const r=await page.evaluate(async(W)=>{const w=m=>new Promise(r=>setTimeout(r,m));
      /* AUCUNE LARGEUR ÉCRITE EN LIGNE sur une carte de fenêtre : c'est le trou que les
         garde-fous statiques ne voient pas, et par lequel 560 et 760 étaient entrés. */
      const enLigne=[...document.querySelectorAll('.ai-card[style]')]
        .filter(c=>/max-width|width/.test(c.getAttribute('style')||'')).map(c=>c.id||c.className);
      /* ⚠ BALAYAGE, PAS LISTE BLANCHE (v5.6, audit externe 9b — même leçon que 8f) : la boucle
         ci-dessous n'ouvre que cinq fenêtres NOMMÉES À LA MAIN, et c'est exactement par là que
         sept largeurs hors gabarit étaient entrées. On mesure donc d'abord TOUTES les cartes de
         fenêtre du document, sans en ouvrir aucune : `getComputedStyle` résout `max-width` même
         sur un élément `display:none`, donc la substitution de `var(--dlg-*)` est déjà faite.
         Les exceptions se NOMMENT ici, avec ce qu'elles mesurent — un texte, un champ, une
         colonne — jamais une fenêtre. */
      const horsGabarit=[...document.querySelectorAll('.ai-card')].map(c=>{
        const mw=getComputedStyle(c).maxWidth;
        const px=/^(\d+(?:\.\d+)?)px$/.exec(mw);
        return {id:c.id||c.className.split(' ').slice(0,2).join('.'),mw,px:px?+px[1]:null};
      }).filter(x=>x.px!==null&&![420,480,720].includes(x.px));
      const out={enLigne,horsGabarit,fen:{}};
      const cmds={filtSheet:()=>document.getElementById('filtTog').click(), authModal:()=>openAuth(),
                  catModal:()=>openCatMgr(), sessModal:()=>openSessHist(), storageModal:()=>openStorageInfo()};
      for(const [id,go] of Object.entries(cmds)){
        try{go();}catch(e){out.fen[id]={err:e.message};continue;}
        await w(450);
        const m=document.getElementById(id);
        if(!m||!m.classList.contains('on')){out.fen[id]={err:'pas ouverte'};continue;}
        const c=m.querySelector('.ai-card'),t=c.querySelector('.ai-top'),b=c.querySelector('.ai-body');
        const rc=c.getBoundingClientRect();
        /* Le corps DÉFILE-T-IL VRAIMENT ? On le pousse au bout : s'il bouge, c'est lui le
           défileur ; s'il ne bouge pas, c'est soit qu'il tient (légitime) soit que la carte
           n'a pas de squelette (ce que le contrôle suivant attrape). */
        let deb=0;if(b){b.scrollTop=99999;deb=Math.round(b.scrollTop);b.scrollTop=0;}
        const rt=t.getBoundingClientRect();
        out.fen[id]={w:Math.round(rc.width),h:Math.round(rc.height),corps:!!b,defile:deb>0,
          /* Le titre reste dans la carte ET à l'écran, quoi qu'il arrive au corps. */
          titreDansCarte:rt.top>=rc.top-1, titreVisible:rt.top>=-1&&rt.bottom<=innerHeight+1,
          police:(()=>{const cs=getComputedStyle(t.querySelector('h3'));
            return Math.round(parseFloat(cs.fontSize)*10)/10+'/'+cs.fontWeight;})(),
          pleineHauteur:Math.round(rc.height)>=innerHeight-2};
        const x=m.querySelector('.ai-x');if(x)x.click();await w(250);
      }
      out.tokens=['--dlg-confirm','--dlg-std','--dlg-atelier']
        .map(k=>getComputedStyle(document.documentElement).getPropertyValue(k).trim());
      return out;},W);

    t(`${W} · aucune largeur de fenêtre écrite en ligne`, r.enLigne.length===0, JSON.stringify(r.enLigne));
    t(`${W} · aucune carte de fenêtre hors des trois gabarits`, r.horsGabarit.length===0,
      JSON.stringify(r.horsGabarit));
    t(`${W} · les trois gabarits valent 420 / 480 / 720`,
      r.tokens && r.tokens.join('/')==='420px/480px/720px', JSON.stringify(r.tokens));
    for(const [id,f] of Object.entries(r.fen)){
      if(f.err){t(`${W} · ${id} : ouverture`,false,f.err);continue;}
      /* En voie étroite une feuille prend la largeur de l'écran : le gabarit ne se mesure que
         là où il a le choix. */
      if(W>=780) t(`${W} · ${id} tient l'un des trois gabarits`, GABARITS.includes(f.w), `${f.w} px`);
      t(`${W} · ${id} : le titre ne s'en va jamais`, f.titreDansCarte&&f.titreVisible, JSON.stringify(f));
      t(`${W} · ${id} : un seul titre de fenêtre (17.5/800)`, f.police==='17.5/800', f.police);
    }
    /* LE PLACEMENT DIT LA NATURE (décision utilisateur) : « Filtrer » est un CHOIX — il ne prend
       jamais toute la hauteur, même sous 780 ; « Compte » est un DOCUMENT — il devient une
       feuille pleine hauteur. Deux régimes, lisibles sur le contenu, jamais sur la largeur. */
    if(W<780){
      t(`${W} · un CHOIX reste une fenêtre centrée (Filtrer)`,
        r.fen.filtSheet&&r.fen.filtSheet.pleineHauteur===false, JSON.stringify(r.fen.filtSheet));
      t(`${W} · un DOCUMENT devient une feuille pleine hauteur (Compte)`,
        r.fen.authModal&&r.fen.authModal.pleineHauteur===true, JSON.stringify(r.fen.authModal));
    }
    await page.close();
  }
}
});

/* ══ v5.6 — L'ACCUEIL EST LE MÊME, QUEL QUE SOIT LE CHEMIN PAR LEQUEL ON Y ARRIVE ══════════
   Signalé à l'usage : « après avoir lancé une session, en revenant à l'accueil, pas le même
   design (le bouton Créer n'est pas du même style) ». Deux causes, et la première était une
   DESTRUCTION silencieuse : `render()` parque `#filtTog` hors de `main` avant le wipe, puis
   `syncHomeNew(false)` le remettait aussitôt dans `.grp-row` — donc dans le `main` qu'on
   remplaçait à la ligne suivante. Un rescue annulé par la ligne d'après est pire que pas de
   rescue : il donne l'illusion d'être couvert.
   Le témoin compare le CHROME de l'accueil avant et après un aller-retour en session : mêmes
   éléments, mêmes parents, mêmes classes. La position VERTICALE est exclue à dessein — la carte
   « Reprendre » s'ajoute légitimement au contenu. */
await sec('v5.6 · l\'accueil ne dépend pas du chemin d\'arrivée', async () => {
{
  const page=await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const chrome=()=>page.evaluate(()=>{const o={};
    for(const id of ['hdrNew','filtTog','q','hdrSearch']){
      const e=document.getElementById(id);
      o[id]=e?{cls:e.className,par:e.parentElement.id||e.parentElement.className,hidden:!!e.hidden,
        x:Math.round(e.getBoundingClientRect().x),h:Math.round(e.getBoundingClientRect().height)}:'ABSENT';}
    return o;});
  const avant=await chrome();
  await ouvrirFiche(page,'Anaphylaxie');
  /* ⚠ ON MESURE AUSSI PENDANT LE SÉJOUR : c'est là que le bouton disparaissait. Un contrôle qui
     ne regarderait que le retour verrait l'accueil réparé par son propre re-rendu complet, et
     resterait vert sur une destruction bien réelle. */
  const pendant=await page.evaluate(()=>!!document.getElementById('filtTog'));
  await demarrerSession(page);
  await page.evaluate(()=>{const b=document.getElementById('hdrBack');if(b)b.click();});
  await page.waitForFunction(()=>document.body.classList.contains('view-home'));
  await page.waitForTimeout(500);
  const apres=await chrome();
  t('le déclencheur de filtre survit au départ de l\'accueil', pendant===true);
  for(const k of Object.keys(avant)){
    t(`${k} : même logement et même habit au retour`,
      JSON.stringify(avant[k])===JSON.stringify(apres[k]),
      `${JSON.stringify(avant[k])} → ${JSON.stringify(apres[k])}`);
  }
  await page.close();
}
});

/* ══ v5.6 — LA RANGÉE D'ACTIONS DE L'EN-TÊTE : UN SEUL GABARIT, UNE SEULE CIBLE ═══════════
   Signalé à l'usage : « la taille des boutons Créer / thème / initiales du compte n'est pas la
   même ». Mesuré, le menu ⋯ était le seul à 44 px de DESSIN (les autres à 36) et l'avatar
   portait un halo de -7 px calibré du temps où il faisait 30 px — sa cible montait donc à 50
   quand celle de ses voisins s'arrête à 44, et deux halos se chevauchaient. Sur une rangée de
   glyphes, le plus gros se lit comme le plus important ; et un halo qui déborde sur le voisin,
   c'est un tap au bord qui n'atteint pas le bouton visé.
   ⚠ ET LE THÈME EST DE RETOUR, EN LECTURE SEULEMENT (décision utilisateur) : le réglage
   canonique reste à froid dans Compte › Affichage, ceci en est le raccourci, posé dans la seule
   situation où il est urgent. Sa condition est la VUE, jamais la largeur. */
await sec('v5.6 · la rangée d\'actions de l\'en-tête', async () => {
{
  for(const W of [320,390,1280]){
    const page=await br.newPage({viewport:{width:W,height:844},hasTouch:W<780});
    page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'));
    await amorce(page);
    const mesure=()=>page.evaluate(()=>{const o={};
      for(const sel of ['#hdrNew','#hdrTheme','#hdrMore','#acctTop']){
        const e=document.querySelector(sel);if(!e||e.hidden||!e.offsetParent)continue;
        const r=e.getBoundingClientRect(),a=getComputedStyle(e,'::after');
        /* La cible EFFECTIVE = dessin + halo, jamais `min-height` : c'est le halo qui la rend en
           zone haute, et un contrôle mesuré sur son seul dessin passerait pour trop petit. */
        const h=a.content!=='none'?Math.abs(parseFloat(a.insetBlockStart||a.inset)||0):0;
        o[sel]={w:Math.round(r.width),h:Math.round(r.height),y:Math.round(r.y),
                cible:Math.round(r.height+2*h),cibleW:Math.round(r.width+2*h)};}
      return o;});
    const hdrH=()=>page.evaluate(()=>Math.round(document.querySelector('header.bar').getBoundingClientRect().height));
    const acc=await mesure();const hAcc=await hdrH();
    await ouvrirFiche(page,'Anaphylaxie');
    const lec=await mesure();const hLec=await hdrH();
    for(const [nom,m] of [['accueil',acc],['lecture',lec]]){
      const v=Object.entries(m);
      t(`${W} · ${nom} : témoin — la rangée porte au moins deux contrôles`, v.length>=2, JSON.stringify(Object.keys(m)));
      /* Les GLYPHES ont tous le même carré ; « Créer » en large porte son mot et s'allonge, mais
         sa HAUTEUR reste celle de la rangée — c'est l'alignement qui se lit, pas la largeur. */
      const hs=[...new Set(v.map(([,x])=>x.h))], ys=[...new Set(v.map(([,x])=>x.y))];
      t(`${W} · ${nom} : même hauteur de dessin`, hs.length===1, JSON.stringify(m));
      t(`${W} · ${nom} : alignés sur la même ligne`, ys.length===1, JSON.stringify(ys));
      t(`${W} · ${nom} : cible ≥ 44 px, et jamais au-delà de son voisin`,
        v.every(([,x])=>x.cible>=44&&x.cible<=46&&x.cibleW>=44), JSON.stringify(m));
    }
    /* ⚠ LA HAUTEUR DE L'EN-TÊTE NE DÉPEND PAS DE LA VUE (v5.6, signalé à l'usage). Mesuré à
       ≥ 780 px : 68 px sur l'accueil contre 61 en lecture, pour la seule raison que le champ de
       recherche était plus haut que les contrôles de sa rangée. C'est l'objet le plus permanent
       du produit, et tout ce qui s'y accroche en dépend (couches collantes, rail A→Z, décalage
       d'ancre) — un plancher commun sur la rangée le garantit par construction.
       ⚠ SOUS 780 px L'ÉCART EST STRUCTUREL et n'est pas mesuré ici : l'accueil y porte une RANGÉE
       DE PLUS (la recherche, que la planche 7b veut dans l'en-tête). Les égaliser supposerait de
       la retirer. Et une fois défilé, le resserrement de 7a les ramène à 62 contre 61. */
    if(W>=780) t(`${W} · l'en-tête a la MÊME hauteur sur l'accueil et en lecture`,
      Math.abs(hAcc-hLec)<=1, `${hAcc} px contre ${hLec} px`);
    /* ⚠ LE RETOUR EST DANS LA MÊME RANGÉE ET SOUS LA MÊME RÈGLE, mais il n'a pas le gabarit des
       quatre glyphes (il porte un mot) : il a donc son contrôle à lui, sur la CIBLE seule.
       Mesuré à 43 × 52 avant correction — un pixel sous le seuil, invisible à l'œil et hors du
       champ d'`audit-a11y`, qui mesure les surfaces au repos et non la barre en session. */
    const back=await page.evaluate(()=>{const e=document.getElementById('hdrBack');
      if(!e||e.hidden||!e.offsetParent)return null;
      const r=e.getBoundingClientRect(),a=getComputedStyle(e,'::after');
      const h=a.content!=='none'?Math.abs(parseFloat(a.insetBlockStart||a.inset)||0):0;
      return {w:Math.round(r.width+2*h),h:Math.round(r.height+2*h)};});
    t(`${W} · le retour d'en-tête a 44 px de cible dans les DEUX sens`,
      !!back&&back.w>=44&&back.h>=44, back?`${back.w}×${back.h}`:'absent');

    /* Le raccourci de thème : présent en LECTURE, absent de l'accueil — c'est le moment qui le
       justifie, pas la place. */
    t(`${W} · le thème est un raccourci de LECTURE, pas de l'accueil`,
      !acc['#hdrTheme']&&!!lec['#hdrTheme'], `accueil ${!!acc['#hdrTheme']}, lecture ${!!lec['#hdrTheme']}`);
    /* Trois crans, comme le réglage canonique — sinon « Auto » deviendrait inatteignable depuis
       la fiche, et l'on ne saurait plus si l'on est en clair CHOISI ou en clair SUIVI. */
    const cy=await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));const v=[];
      for(let i=0;i<4;i++){v.push(localStorage.getItem(spaceKey('ac-theme'))||'auto');
        document.getElementById('hdrTheme').click();await w(150);}
      return v;});
    t(`${W} · … et il parcourt les TROIS crans, dans l'ordre du réglage`,
      cy.slice(0,3).join(',')==='auto,light,dark'&&cy[3]==='auto', cy.join(' → '));
    /* ⚠ EN SOMBRE, LA PASTILLE DU COMPTE SE DISSOUT DANS L'EN-TÊTE (v5.6, signalé à l'usage).
       C'est le seul contrôle de la rangée à porter un APLAT, et en sombre cet aplat vaut
       exactement le fond de la barre : 1,00:1 mesuré. Les initiales restent lisibles — ce n'est
       donc pas un défaut de TEXTE, et `audit-a11y`, qui mesure le texte, ne pouvait pas le voir :
       c'est la LIMITE DU COMPOSANT que WCAG 2.2 § 1.4.11 protège, et elle vaut 3:1. */
    const past=await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
      const lum=c=>{const m=(String(c).match(/[\d.]+/g)||[0,0,0]).slice(0,3).map(Number);
        const [r,g,b]=m.map(v=>{v/=255;return v<=0.03928?v/12.92:Math.pow((v+0.055)/1.055,2.4);});
        return .2126*r+.7152*g+.0722*b;};
      const ratio=(x,y)=>{const [l1,l2]=[lum(x),lum(y)].sort((a,b)=>b-a);return Math.round(((l1+.05)/(l2+.05))*100)/100;};
      const out={};
      for(const th of ['light','dark']){document.documentElement.dataset.theme=th;await w(200);
        const e=document.getElementById('acctTop');if(!e){out[th]=null;continue;}
        const cs=getComputedStyle(e),bar=getComputedStyle(document.querySelector('header.bar')).backgroundColor;
        /* La limite peut être portée par le FOND ou par le filet — ici une ombre interne, qui ne
           déplace pas la boîte (36 px de dessin, 44 de cible : A30). On prend le meilleur des deux. */
        const sh=(cs.boxShadow||'').match(/rgba?\([^)]*\)/);
        out[th]={fond:ratio(cs.backgroundColor,bar),filet:sh?ratio(sh[0],bar):0};}
      document.documentElement.dataset.theme='light';await w(150);
      return out;});
    for(const th of ['light','dark']){
      const m=past[th];
      t(`${W} · ${th} : la pastille du compte se DÉTACHE de l'en-tête (≥ 3:1)`,
        !!m&&Math.max(m.fond,m.filet)>=3, m?`fond ${m.fond}:1 · filet ${m.filet}:1`:'absente');
    }
    await page.close();
  }
}
});

/* ══ v5.6 — LE RAIL A→Z NE BOUGE NI AU DÉFILEMENT NI AU RE-RENDU ═══════════════════════════
   Signalé à l'usage : « il se déplace légèrement quand on a scrollé, et se recentre quand on
   clique sur n'importe quel bouton ». Depuis 7a l'en-tête de l'accueil se COMPACTE au défilement
   (114 → 62 px) et `azrPoseBox` mesurait son bas À L'INSTANT DU RENDU : tout re-rendu reposait
   `--azr-top` avec la hauteur du moment, la boîte grandissait de 52 px, et les lettres — qui
   sont CENTRÉES — se déplaçaient de 26 px sous le doigt. C'est la règle de v5.0.9, appliquée à
   un second objet : une géométrie de chrome ne se dérive jamais d'un état qui dépend du
   défilement.
   ⚠ LE TÉMOIN CONSTRUIT SON CAS : deux fiches d'exemple ne donnent pas assez de lettres pour que
   le rail existe, ni assez de hauteur pour que la page défile — il pose son propre répertoire. */
await sec('v5.6 · le rail A→Z ne se déplace jamais', async () => {
{
  const page=await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r=await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    for(const l of 'ABCDEFGHIJKLMNOPQRSTUVWX'.split('')){
      const f=blankFiche();f.title=l+' — démo';fiches.push(migrate(f));}
    await persist();render();await w(400);
    const g=()=>{const el=document.getElementById('azRail');
      if(!el||el.hidden)return null;
      const b=el.getBoundingClientRect(),l=el.querySelector('[data-azl]');
      return {top:Math.round(b.top),h:Math.round(b.height),
              l1:l?Math.round(l.getBoundingClientRect().top):null,
              n:el.querySelectorAll('[data-azl]').length,
              slim:document.body.classList.contains('home-slim')};};
    const repos=g();
    window.scrollTo(0,400);await w(350);
    const defile=g();
    /* Un tap qui NE CHANGE PAS le contenu du rail : c'est le cas signalé. Changer le groupement
       changerait le nombre de crans, donc leur position — ce serait mesurer autre chose. */
    const pin=main.querySelector('[data-pin]');if(pin)pin.click();await w(500);
    const apres=g();
    window.scrollTo(0,0);await w(350);
    const remonte=g();
    return {repos,defile,apres,remonte,avaitPin:!!pin};});

  t('témoin : le rail existe et porte plusieurs lettres',
    !!r.repos&&r.repos.n>=5, JSON.stringify(r.repos));
  t('témoin : le défilement resserre bien l\'en-tête',
    !!r.defile&&r.defile.slim===true, JSON.stringify(r.defile));
  t('témoin : un tap sans effet sur le rail a bien eu lieu', r.avaitPin===true);
  const memes=(a,b)=>a&&b&&Math.abs(a.top-b.top)<=1&&Math.abs(a.h-b.h)<=1&&Math.abs(a.l1-b.l1)<=1;
  t('le rail ne bouge pas au défilement', memes(r.repos,r.defile),
    `${JSON.stringify(r.repos)} → ${JSON.stringify(r.defile)}`);
  t('… ni à un re-rendu déclenché par un tap', memes(r.defile,r.apres),
    `${JSON.stringify(r.defile)} → ${JSON.stringify(r.apres)}`);
  /* ⚠ LE RAIL EST CENTRÉ SUR L'ÉCRAN, PAS DANS SA PROPRE BOÎTE (v5.6, signalé à l'usage : « le
     rail A→Z n'est pas centré au milieu de la page »). Sa boîte commence sous l'en-tête, si bien
     que des lettres centrées DEDANS tombaient 58 px sous l'axe médian à 390 px. On mesure donc
     l'axe des LETTRES contre celui de l'écran — et la tolérance est large (6 px) parce que le
     décalage est CLAMPÉ à la place disponible : sur un alphabet complet il n'y a pas de quoi
     remonter jusqu'au centre, et rogner une lettre serait pire (une lettre coupée est une lettre
     injoignable en silence). */
  const cen=await page.evaluate(()=>{const el=document.getElementById('azRail');
    if(!el||el.hidden)return null;
    const ls=[...el.querySelectorAll('[data-azl]')];if(!ls.length)return null;
    const a=ls[0].getBoundingClientRect(),z=ls[ls.length-1].getBoundingClientRect();
    const b=el.getBoundingClientRect();
    return {axe:Math.round((a.top+z.bottom)/2),ecran:Math.round(document.documentElement.clientHeight/2),
      hautLettre:Math.round(a.top),hautBoite:Math.round(b.top),
      hdr:Math.round(document.querySelector('header.bar').getBoundingClientRect().bottom)};});
  t('témoin : les lettres tiennent dans la boîte (décalage non clampé)',
    !!cen&&cen.hautLettre>=cen.hautBoite-1, JSON.stringify(cen));
  t('le rail est centré sur l\'axe médian de l\'écran',
    !!cen&&Math.abs(cen.axe-cen.ecran)<=6, cen?`lettres ${cen.axe} · écran ${cen.ecran}`:'absent');
  t('… sans qu\'aucune lettre ne passe derrière l\'en-tête',
    !!cen&&cen.hautLettre>=cen.hdr, cen?`première lettre ${cen.hautLettre} · en-tête ${cen.hdr}`:'absent');
  t('… ni au retour en haut de page', memes(r.apres,r.remonte),
    `${JSON.stringify(r.apres)} → ${JSON.stringify(r.remonte)}`);
  await page.close();
}
});

/* ══ v5.6 — DEUX NIVEAUX DE SÉPARATION DANS LE RAIL, ET ILS NE SE RESSEMBLENT PLUS ══════════
   Signalé à l'usage : « les séparations entre repères posologiques sont les mêmes qu'entre les
   grands blocs, ce qui pose un problème de hiérarchie » et « en mode consulter, diagnostics
   différentiels et références sont collés entre eux ». Les deux étaient exacts et mesurés : un
   ITEM et une FAMILLE portaient le MÊME filet de 1 px, et les deux cartes de « Consulter »
   n'avaient aucun écart. Une famille se sépare désormais par l'ESPACE et par son titre ; le
   filet reste à l'item, qui n'a que lui. */
await sec('v5.6 · la hiérarchie des séparations du rail', async () => {
{
  const page=await br.newPage({viewport:{width:1280,height:1000}});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await ouvrirFiche(page,'Anaphylaxie');
  await demarrerSession(page);
  const r=await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const b=[...document.querySelectorAll('button')].find(x=>/Consulter/.test(x.textContent));
    if(b)b.click();await w(600);
    const side=document.querySelector('.read-side');if(!side)return {err:'pas de rail'};
    const px=v=>Math.round(parseFloat(v)||0);
    const fam=[...side.querySelectorAll('.rail-sec')].map(e=>{const cs=getComputedStyle(e);
      return {t:(e.querySelector('.rail-title')||{}).textContent||'',mt:px(cs.marginTop),bt:px(cs.borderTopWidth)};});
    const cartes=[...side.querySelectorAll('.rs-sec')].map(e=>{const cs=getComputedStyle(e);
      return {t:(e.querySelector('summary')||{}).textContent||'',mt:px(cs.marginTop)};});
    /* Le RETRAIT est ce qui distingue les deux filets, et on le mesure sur le TRAIT — pas sur la
       boîte : le filet d'item est un pseudo-élément précisément pour que la colonne de texte ne
       bouge pas (un retrait écrit en `padding` volait 10 px au texte et faisait passer une
       posologie longue sur une ligne de plus). */
    const items=[...side.querySelectorAll('.pos-card')].map(e=>{
      const b=getComputedStyle(e,'::before');
      return {bt:px(b.height)||px(getComputedStyle(e).borderTopWidth),
              dx:px(b.left), pseudo:b.content!=='none'};});
    const col=side.querySelector('.ref-col');
    return {fam,cartes,items,colBb:col?px(getComputedStyle(col).borderBottomWidth):null,
            colMb:col?px(getComputedStyle(col).marginBottom):null};});

  t('témoin : le cas est constitué (plusieurs familles, deux cartes, des items)',
    !r.err&&r.fam.length>=2&&r.cartes.length>=2&&r.items.length>=2,
    JSON.stringify({fam:r.fam.length,cartes:r.cartes.length,items:r.items.length}));
  /* ⚠ LA PROPRIÉTÉ A ÉTÉ CORRIGÉE PAR L'AUTEUR : le filet de FAMILLE devait rester (il donne au
     rail sa structure) ; c'est l'item qui devait changer de nature. On mesure donc les DEUX
     niveaux et surtout ce qui les DISTINGUE, plutôt que l'absence de l'un des deux. */
  t('une famille garde son filet, franc et pleine largeur',
    r.fam.slice(1).every(f=>f.mt>=16&&f.bt>=1), JSON.stringify(r.fam));
  t('… et l\'item garde le sien, mais EN RETRAIT — les deux ne se confondent plus',
    r.items.filter(x=>x.bt>0&&x.dx>=6).length>=1&&r.items.every(x=>x.bt===0||x.dx>=6),
    JSON.stringify(r.items));
  /* « CONSULTER » : deux cartes ne se touchent pas. */
  t('les deux cartes de « Consulter » ne sont plus collées',
    r.cartes.slice(1).every(c=>c.mt>=8), JSON.stringify(r.cartes));
  /* Et la frontière de l'excursion suit la même règle que les familles. */
  t('… et la frontière de l\'excursion est du niveau FAMILLE',
    r.colBb>=1&&r.colMb>=16, `bordure ${r.colBb}, marge ${r.colMb}`);
  await page.close();
}
});

/* ══ v5.6 — LE VOLET DU QUAI EST UN SECOND ÉTAGE DE LA CAPSULE ═════════════════════════════
   Signalé à l'usage : « le menu qui se déroule du chronomètre de session devrait être designé
   comme s'il était intégré au bandeau session — la largeur doit être la même, et il devrait être
   collé ». La v5.4.1 en avait fait un ÉTAGE du chrome plutôt qu'une carte flottante : bonne
   structure, géométrie d'avant — il restait posé sous TOUT le bandeau et de bord à bord, donc il
   se lisait comme une seconde barre, pas comme le dépliant DE LA CAPSULE.
   ⚠ ET LES INVARIANTS DE V1 NE BOUGENT PAS : rien ne se déplace derrière lui (il est `fixed`),
   et l'alarme reste en vue (V2) — la capsule est AU-DESSUS de lui, jamais recouverte. */
await sec('v5.6 · le volet du quai prolonge la capsule', async () => {
{
  const page=await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await ouvrirFiche(page,'Anaphylaxie');
  await demarrerSession(page);
  const r=await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const g=e=>e?(x=>({x:Math.round(x.x),r:Math.round(x.right),t:Math.round(x.top),b:Math.round(x.bottom)}))(e.getBoundingClientRect()):null;
    const cap=()=>document.getElementById('cbTimers');
    /* On relève la géométrie du CONTENU avant/après : un volet FIXE ne doit rien déplacer.
       ⚠ ON RE-INTERROGE LE DOM APRÈS LE GESTE : ouvrir le volet passe par `renderKeepAnchor`,
       donc une référence gardée d'avant désigne un nœud DÉTACHÉ, dont le rectangle vaut 0 — le
       contrôle mesurerait alors sa propre erreur (leçon déjà payée sur le rail, v5.4.3). */
    const SEL='.ov-block,.nav-wrap,.sv-cell';
    const av=g(document.querySelector(SEL)), capAv=g(cap());
    cap().click(); await w(500);
    const d=document.querySelector('.rt-dock');
    const o={volet:g(d),capsule:g(cap()),contenuAv:av,contenuAp:g(document.querySelector(SEL)),capAv,
      /* La capsule doit rester DEVANT le volet : l'alarme ne se laisse jamais recouvrir (V2). */
      zVolet:d?+getComputedStyle(d).zIndex:null,
      zQuai:+getComputedStyle(document.getElementById('crisisDock')).zIndex};
    return o;});

  t('témoin : le volet s\'ouvre bien au tap de la capsule', !!r.volet, JSON.stringify(r.volet));
  t('il a EXACTEMENT la largeur de la capsule',
    !!r.volet&&Math.abs(r.volet.x-r.capsule.x)<=1&&Math.abs(r.volet.r-r.capsule.r)<=1,
    `volet ${r.volet&&r.volet.x}..${r.volet&&r.volet.r} · capsule ${r.capsule.x}..${r.capsule.r}`);
  t('… et il lui est COLLÉ, sans interstice',
    !!r.volet&&Math.abs(r.volet.t-r.capsule.b)<=1,
    `volet à ${r.volet&&r.volet.t}, capsule finit à ${r.capsule.b}`);
  /* V1 : rien ne bouge derrière — c'est ce qui rend l'occultation admissible. */
  t('rien ne se déplace derrière lui (V1)',
    !!r.contenuAv&&!!r.contenuAp&&Math.abs(r.contenuAv.t-r.contenuAp.t)<=1,
    `${r.contenuAv&&r.contenuAv.t} → ${r.contenuAp&&r.contenuAp.t}`);
  /* V2 : la capsule ne bouge pas et reste AU-DESSUS — l'alarme n'est jamais masquée. */
  /* ⚠ ON MESURE LA PROPRIÉTÉ, PAS LE MÉCANISME (leçon du dossier, re-payée ici) : ce contrôle
     exigeait `z(quai) > z(volet)`, un ORDRE D'EMPILEMENT — il est devenu rouge le jour où le volet
     a dû monter d'un cran pour que les deux noirs se touchent, alors que ce que V2 protège est
     intact. Ce que la doctrine promet est que l'alarme reste EN VUE : la capsule ne bouge pas, et
     rien ne la recouvre. C'est cela qu'on mesure — `elementFromPoint` en son centre. */
  const capVis=await page.evaluate(()=>{const c=document.querySelector('#cbTimers');
    const b=c.getBoundingClientRect();
    const e=document.elementFromPoint(Math.round(b.left+b.width/2),Math.round(b.top+b.height/2));
    return !!e&&(e===c||c.contains(e));});
  t('… et la capsule reste en place, EN VUE, rien ne la recouvre (V2)',
    Math.abs(r.capAv.t-r.capsule.t)<=1&&capVis===true,
    `capsule ${r.capAv.t} → ${r.capsule.t}, visible ${capVis}`);
  /* ⚠ DEUX BOÎTES QUI SE TOUCHENT NE FONT PAS DEUX NOIRS QUI SE TOUCHENT (v5.6, signalé à
     l'usage : « le noir du bandeau ne touche pas le noir du début du menu »). Le bas de la capsule
     et le haut du volet étaient DÉJÀ au même pixel — c'est la PEINTURE qui différait : le quai
     porte 8 px de rembourrage sous la capsule, il est de la matière d'ambiance, et il peignait
     par-dessus le haut du volet. On mesure donc la couleur EFFECTIVE de la bande, en remontant
     jusqu'au premier fond opaque — mesurer les rectangles serait rester aveugle au défaut. */
  const bande=await page.evaluate(()=>{
    const cap=document.querySelector('#cbTimers'),vol=document.querySelector('.rt-dock');
    if(!cap||!vol)return null;
    const opaque=e=>{for(let n=e;n;n=n.parentElement){const c=getComputedStyle(n).backgroundColor;
      const m=(c.match(/[\d.]+/g)||[]).map(Number);
      if(m.length<4||m[3]>0.99)return c;}return '';};
    const y0=cap.getBoundingClientRect().bottom,x=Math.round(innerWidth/2);
    const fondCap=opaque(cap);
    const pts=[1,3,5,7].map(d=>opaque(document.elementFromPoint(x,Math.round(y0+d))));
    return {fondCap,pts,tous:pts.every(c=>c===fondCap)};});
  t('témoin : la capsule et le volet ont bien un fond opaque', !!bande&&!!bande.fondCap, JSON.stringify(bande));
  t('les deux noirs se TOUCHENT — aucune bande d\'ambiance entre eux',
    !!bande&&bande.tous===true, JSON.stringify(bande));
  /* LE DÉROULÉ (v5.6, proposition de l'auteur) : il répond à un GESTE, il ne survient pas tout
     seul — et il est en `transform` PUR, la seule façon de « dérouler » sans animer une hauteur
     (`check-anim`). Le contenu porte le contre-scale exact, donc il ne s'étire pas. On mesure
     qu'il a bien joué ET qu'il ne laisse AUCUN résidu : une boîte restée à 0,99 serait un défaut
     permanent pour une animation de 180 ms. Son inertie sous `prefers-reduced-motion` est déjà
     couverte par la section WCAG dédiée — la règle vit dans le bloc `no-preference`. */
  const roul=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const q=document.querySelector('#cbTimers');
    q.click();await w(350);q.click();await w(60);          // on referme, on rouvre : l'animation rejoue
    const v=document.querySelector('.rt-dock');if(!v)return null;
    const noms=v.getAnimations().map(a=>a.animationName||'');
    const inn=v.firstElementChild;
    const mid={ext:getComputedStyle(v).transform,int:inn?getComputedStyle(inn).transform:''};
    await w(500);
    return {noms,mid,fin:getComputedStyle(v).transform,
      lab:(()=>{const l=v.querySelector('.tm-label');return l?Math.round(l.getBoundingClientRect().height):null;})()};});
  t('témoin : l\'ouverture joue bien une animation', !!roul&&roul.noms.length>0, JSON.stringify(roul&&roul.noms));
  t('le volet se DÉROULE (transform seul, contenu contre-scalé)',
    !!roul&&/matrix/.test(roul.mid.ext)&&roul.mid.ext!==roul.fin&&/matrix/.test(roul.mid.int),
    JSON.stringify(roul&&roul.mid));
  t('… et il ne laisse aucun résidu à la fin',
    !!roul&&(roul.fin==='none'||roul.fin==='matrix(1, 0, 0, 1, 0, 0)'), roul?roul.fin:'—');
  /* ⚠ UNE SECTION RESPIRE AUTANT DES DEUX CÔTÉS DE SON FILET (v5.6, signalé à l'usage : « le
     journal replié s'affiche avec plus d'espace en bas qu'en haut — et même déplié vide »). Le
     panneau posait sa respiration d'un seul côté (12 px sous son filet, rien après son contenu) :
     replié il n'a qu'un TITRE, et ce qu'on lisait était donc 12 px au-dessus contre la fin du
     volet en dessous. On mesure les deux marges INTERNES du panneau, replié — le cas où
     l'asymétrie se voit le plus, puisqu'il n'y a rien d'autre pour la masquer. */
  const jr=await page.evaluate(()=>{const p2=document.querySelector('.rt-dock .tk-panel');
    if(!p2)return null;const r=p2.getBoundingClientRect();
    const k=[...p2.children].filter(e=>getComputedStyle(e).display!=='none');
    if(!k.length)return null;
    const a2=k[0].getBoundingClientRect(),z=k[k.length-1].getBoundingClientRect();
    return {haut:Math.round(a2.top-r.top),bas:Math.round(r.bottom-z.bottom),n:k.length};});
  t('journal · témoin : le panneau replié est bien rendu', !!jr&&jr.n>=1, JSON.stringify(jr));
  t('journal · il respire autant au-dessus qu\'au-dessous',
    !!jr&&Math.abs(jr.haut-jr.bas)<=2, jr?`${jr.haut} px / ${jr.bas} px`:'—');
  await page.close();
}
});

/* ══ v5.6 — ⏱ UN GESTE, DEUX FAITS, UNE SEULE LIGNE ════════════════════════════════════════
   Demande utilisateur : « dans Noter l'heure, ajouter les items des compteurs — permet
   d'incrémenter le compteur ET de noter l'heure en même temps ; rester transparent, l'utilisateur
   doit savoir que ça a incrémenté ».
   ⚠ LE PIÈGE EST LE DOUBLON, ET C'EST LUI QUE LE TÉMOIN GARDE. Incrémenter un compteur pose DÉJÀ
   son propre repère horodaté (v4.52.0) : passer par le chemin ordinaire du « + » aurait produit
   DEUX lignes à la même seconde pour un seul acte — exactement ce que la ligne « ✓ Consigné à … »
   existe pour supprimer. La chip ATTACHE le compteur au repère déjà posé. */
await sec('v5.6 · ⏱ un compteur s\'incrémente depuis le volet, sans doubler la ligne', async () => {
{
  const page=await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await ouvrirFiche(page,'Anaphylaxie');
  await demarrerSession(page);
  const r=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const key=[...document.querySelectorAll('#crisisDockBar button,.sd-key')]
      .find(b=>/NOTER/i.test(b.textContent));
    if(!key)return {err:'touche ⏱ introuvable'};
    key.click(); await w(500);
    const chip=document.querySelector('.ds-chip.ds-cnt');
    if(!chip)return {err:'aucune chip de compteur'};
    const cid=chip.dataset.tkcnt;
    const avant={ev:(Runtime.events||[]).length, val:+(Runtime.counters||{})[cid]||0,
      /* Elle DIT où elle mène AVANT le tap : un bouton qui incrémente sans l'annoncer serait un
         effet de bord, et sous stress on ne relit pas. */
      annonce:(chip.querySelector('.ds-cn')||{}).textContent||'',
      /* Le compteur est GARANTI dans la liste, il n'y est pas par chance de classement. */
      premier:document.querySelector('.ds-chip')===chip};
    chip.click(); await w(500);
    const ev=(Runtime.events||[]);
    return {...avant, apres:{ev:ev.length, val:+(Runtime.counters||{})[cid]||0,
      refs:ev.map(e=>e.ref&&e.ref.type==='counter'?e.ref.v:null).filter(v=>v!=null),
      live:(document.getElementById('srLive')||{}).textContent||'',
      ferme:!!(document.getElementById('dockSheet')||{}).hidden}};});

  if(r.err){t('témoin : le volet ⏱ offre un compteur',false,r.err);}
  else{
    t('témoin : le compteur est proposé, et en PREMIER (garanti, pas par chance de rang)',
      r.premier===true);
    t('la chip annonce sa destination AVANT le tap',
      /\d+\s*→\s*\d+/.test(r.annonce), `« ${r.annonce} »`);
    t('un tap incrémente réellement le compteur',
      r.apres.val===r.val+1, `${r.val} → ${r.apres.val}`);
    /* LE CŒUR DU LOT : le journal ne gagne PAS une ligne — le repère déjà posé reçoit la
       référence, avec la valeur atteinte. */
    t('… sans ajouter une seconde ligne au journal',
      r.apres.ev===r.ev, `${r.ev} → ${r.apres.ev} repère(s)`);
    t('… et c\'est le repère horodaté qui porte la valeur atteinte',
      r.apres.refs.length===1&&r.apres.refs[0]===r.val+1, JSON.stringify(r.apres.refs));
    /* TRANSPARENCE : on ne se contente pas d'étiqueter en silence. */
    t('l\'incrément est ANNONCÉ, pas silencieux',
      /incrément/i.test(r.apres.live), `« ${r.apres.live} »`);
    t('… et le volet se referme sur le geste', r.apres.ferme===true);
  }
  await page.close();
}
});

/* ══ A9 · A6 · A11 — TROIS INVARIANTS DE LA REFONTE, MESURÉS AU RENDU (v5.6, planche 8f) ═════
   Les trois sont écrits dans AGENTS.md depuis le lot 1 et n'étaient vérifiés PAR RIEN :
   · A9 — un changement d'état NON COMMANDÉ ne modifie jamais une hauteur (un minuteur qui échoit,
     une alarme qui s'éveille). Le piège n'est pas la structure, identique d'un état à l'autre,
     c'est le LIBELLÉ : « Adrénaline » devient « Adrénaline — échu », un mot de plus passe le nom
     sur deux lignes, et la carte grandit sous le doigt.
   · A6 — l'échelle typographique fermée, VÉRIFIÉE AU RENDU : `check-type` lit la feuille de
     style, donc il ne voit ni un `style=` en ligne ni une règle qui ne s'applique pas dans un
     logement donné (leçon A23, quatre dérives trouvées ainsi).
   · A11 — une seule masse colorée à l'écran : l'aplat est réservé à ce qui exige une action
     MAINTENANT. À cinq étapes, l'aplat happe l'œil et détruit la lecture de la séquence. */
/* ══ A7 — « VÉRIFIER » EST UN GESTE DE BLOC, ET IL EXISTE SUR TOUT BLOC D'ÉTAPES ═══════════
   Signalé à l'usage : « où est passé le bouton vérifier ?? ». Il avait disparu de toutes les
   fiches qui n'écrivent pas de challenges « :: » — c'est-à-dire presque toutes — parce que j'avais
   ajouté à A7 une condition que la maquette ne demande pas. La passe Do-Verify redéroule TOUTES
   les étapes (doctrine v4.11.0) : le « :: » l'enrichit, il ne la conditionne pas.
   ⚠ LE TÉMOIN CONSTRUIT SON CAS : les fiches d'exemple n'ont AUCUNE réponse attendue, donc c'est
   exactement sur elles que le défaut vivait — et un contrôle qui se contenterait de chercher le
   bouton sur une fiche à challenges serait resté vert. */
await sec('A7 · « Vérifier » sur un bloc sans challenge', async () => {
{
  const page=await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await ouvrirFiche(page,'Anaphylaxie');
  await demarrerSession(page);
  const r=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    /* ⚠ LE TÉMOIN CONSTRUIT SON CAS : le premier bloc de la fiche d'exemple porte DEUX réponses
       attendues, donc le bouton y était visible même avec la condition fautive — on RETIRE les
       « :: » du bloc courant, ce qui est exactement l'état de presque toutes les fiches réelles. */
    const bid=document.querySelector('.ov-block[data-ovb]').dataset.ovb;
    const bloc=Runtime.fiche.blocks.find(x=>x.id===bid);
    bItems(bloc).forEach(it=>{const src=(Runtime.fiche.items||[]).find(p=>p.id===it.id)||it;src.expect='';});
    renderOvOnly();await w(350);
    const reste=bItems(bloc).filter(it=>(it.expect||'').trim()).length;
    const v=document.querySelector('[data-ovverify]');
    const c=document.querySelector('[data-ovnext]');
    const vr=v&&v.getBoundingClientRect(),cr=c&&c.getBoundingClientRect();
    const geo=v&&c?{gauche:vr.left<cr.left,rangee:Math.abs(vr.top-cr.top)<=6,h:Math.round(vr.height)}:null;
    if(!v)return {reste,present:false,geo:null};
    v.click();await w(400);
    const passe=!!document.querySelector('[data-ovvok]');
    /* ⚠ LA SORTIE SE MET AU BOUT DE LA LIGNE QU'ELLE FERME (signalé à l'usage : « texte et croix
       ne sont pas sur la même ligne, même en desktop »). La rangée de la carte porte le titre sur
       toute la largeur et les gestes DESSOUS — juste pour « ↺ Refaire », faux pour la sortie d'un
       mode. On compare les CENTRES : les deux objets n'ont pas la même hauteur, comparer leurs
       hauts ferait échouer un alignement pourtant correct. */
    /* ⚠ LA SORTIE A CHANGÉ DE LIGNE, PAS DE RÔLE (v5.6, signalé à l'usage : « la croix et le
       texte ne sont pas alignés, et ce n'est pas évident qu'elle ferme le mode »). Elle était un
       ✕ nu dans l'en-tête du bloc ; elle vit désormais sur la ligne qui NOMME le mode, avec son
       verbe. Le témoin suit le contrôle : même propriété — sur la ligne, à son bout, 44 px. */
    const hd=document.querySelector('.v-hint');
    const tg=hd&&hd.querySelector('.v-hint-t'),cx=hd&&hd.querySelector('[data-ovvx]');
    const mil=e=>{const r=e.getBoundingClientRect();return r.top+r.height/2;};
    const tete=(tg&&cx)?{ligne:Math.abs(mil(tg)-mil(cx))<=4,
      droite:cx.getBoundingClientRect().right>tg.getBoundingClientRect().right,
      w:Math.round(cx.getBoundingClientRect().width),h:Math.round(cx.getBoundingClientRect().height),
      txt:(cx.textContent||'').trim(),
      hh:Math.round(hd.getBoundingClientRect().height)}:null;
    /* On va jusqu'au BOUT de la passe : la pilule de trace est DURABLE, elle vit sur la liste
       d'étapes — laquelle ne revient qu'une fois la passe terminée (pendant, la carte affiche un
       item à la fois). Mesurer avant, c'est mesurer l'écran qui n'a pas encore la trace. */
    for(let i=0;i<12;i++){const ok=document.querySelector('[data-ovvok]');if(!ok)break;ok.click();await w(220);}
    /* … puis on SORT de la passe : elle finit sur son bilan (« n/n vérifiées »), et la liste
       d'étapes — qui porte la trace — ne revient qu'après « Terminer la vérification ». */
    const fin=document.querySelector('[data-ovvx]');if(fin)fin.click();await w(400);
    /* ⚠ LA TRACE SE RELÈVE AVANT D'AVANCER : le journal CONDENSE un passage terminé en ligne-bilan
       (ovPresList), donc les pilules quittent le DOM dès le geste suivant. Mesurée après, elle
       vaudrait zéro — et l'on croirait à une régression de la trace au lieu d'un défaut de sonde. */
    const trace=document.querySelectorAll('.stp-vf.ok').length;
    /* ⚠ ON AVANCE JUSQU'À UNE DÉCISION, SINON DEUX CONTRÔLES SONT VIDES. « un bloc de décision
       n'a pas de Vérifier » cherchait `.ov-block.dec [data-ovverify]` alors qu'aucune décision
       n'était encore POSTÉE au journal : absent parce qu'absent, vert sans rien mesurer. */
    for(let i=0;i<8;i++){
      if(document.querySelector('.ov-block.dec .question'))break;
      document.querySelectorAll('.ov-block.cur [data-ck]').forEach(e=>e.click());
      const c=document.querySelector('[data-ovnext]');if(!c)break;c.click();await w(220);}
    const dec=document.querySelector('.ov-block.dec');
    /* HIÉRARCHIE DU BLOC DE DÉCISION (v5.6, signalé à l'usage : « titre du bloc et question
       s'affichent en même grandeur -> perturbant »). Les deux étaient à 21 px : `check-type` ne
       pouvait rien voir — 21 est SUR l'échelle — parce que ce n'est pas la valeur qui était
       fausse, c'est le rapport. Une hiérarchie ne se mesure qu'au rendu, et par comparaison. */
    const px=e=>e?Math.round(parseFloat(getComputedStyle(e).fontSize)*10)/10:null;
    const hier=dec?{titre:px(dec.querySelector('.ov-t')),question:px(dec.querySelector('.question')),
                    option:px(dec.querySelector('.opt'))}:null;
    return {reste,present:true,txt:v.textContent.trim(),geo,passe,tete,hier,
      trace,
      coches:Object.values(state.checked).filter(Boolean).length,
      decAtteinte:!!dec,
      surDecision:!!(document.querySelector('.ov-block.dec [data-ovverify]'))};});

  t('témoin : le bloc courant ne porte plus AUCUNE réponse attendue', r.reste===0, `${r.reste}`);
  t('« Vérifier » existe quand même', r.present===true);
  /* Le libellé est celui de la MAQUETTE (décision de l'auteur) : « :: » nomme la passe
     challenge-réponse, il n'annonce pas un pré-requis du bloc — c'est la CONDITION qui était
     fautive, pas le mot. */
  t('… et il porte le libellé de la maquette', r.txt==='Vérifier ::', r.txt);
  t('… à gauche de « Continuer », dans la même rangée de pied (A7)',
    !!r.geo&&r.geo.gauche===true&&r.geo.rangee===true, JSON.stringify(r.geo));
  t('… cible ≥ 44 px', !!r.geo&&r.geo.h>=44, r.geo?r.geo.h+' px':'—');
  t('… la sortie de la passe est SUR la ligne qui nomme le mode, à son bout',
    !!r.tete&&r.tete.ligne===true&&r.tete.droite===true, JSON.stringify(r.tete));
  t('… elle porte son VERBE, pas un glyphe seul', !!r.tete&&/quitter/i.test(r.tete.txt||''),
    r.tete?String(r.tete.txt):'—');
  t('… et sa cible fait 44 px dans les DEUX sens',
    !!r.tete&&r.tete.w>=44&&r.tete.h>=44, r.tete?`${r.tete.w}×${r.tete.h}`:'—');
  t('la passe s\'ouvre et « Constaté ✓ » coche les étapes', r.passe===true&&r.coches>=2,
    `passe ${r.passe} · ${r.coches} coche(s)`);
  t('… en laissant une trace DURABLE sur les lignes', r.trace>=2, `${r.trace} pilule(s)`);
  /* Un bloc de DÉCISION n'a pas d'étapes à re-constater : il en reste exclu. */
  t('témoin : une décision est bien atteinte', r.decAtteinte===true);
  t('un bloc de décision n\'a pas de « Vérifier »', r.surDecision===false);
  t('… son titre passe DEVANT sa question (hiérarchie)',
    !!r.hier&&r.hier.titre>r.hier.question, JSON.stringify(r.hier));
  t('… et la question partage le corps de ses options',
    !!r.hier&&r.hier.question===r.hier.option, JSON.stringify(r.hier));
  await page.close();
}
});

await sec('v5.6 · A9/A6/A11 — hauteurs d\'état, échelle au rendu, une seule masse', async () => {
{
  const ECHELLE=[11,12,13.5,15,17.5,21,24];
  const page=await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await ouvrirFiche(page,'Anaphylaxie');
  await demarrerSession(page);
  const r=await page.evaluate(async(ECH)=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const H=s=>{const e=document.querySelector(s);return e?Math.round(e.getBoundingClientRect().height):null;};
    /* ── A9 ── On ouvre le volet pour avoir les cartes de minuteur sous la main, puis on fait
       ÉCHOIR le minuteur sans toucher à rien d'autre : c'est le changement d'état non commandé
       que la règle vise. */
    document.getElementById('cbTimers').click();await w(450);
    const sel='.rt-dock .tmcard';
    const avant={capsule:H('#cbTimers'),carte:H(sel)};
    /* ⚠ ON FAIT ÉCHOIR PAR LE MODÈLE RÉEL : un minuteur d'intervalle porte `seconds`, `elapsedMs`
       et `lastStart` — pas de `durMs`. Deviner le nom d'un champ produit un témoin qui ne
       rencontre jamais son cas, et le contrôle d'état qui suit mesurerait deux fois le nominal. */
    /* ⚠ UN MINUTEUR À CYCLES N'EST JAMAIS ÉCHU — il se relance (`autoloop`) et incrémente son
       compte : le forcer au-delà de son intervalle produit un tour de plus, pas l'état ambre.
       Le témoin coupe donc la boucle avant de forcer l'échéance, sinon il ne rencontrerait
       jamais son cas et A9 mesurerait deux fois le nominal. */
    const t0=Object.keys(Runtime.timers||{})[0];
    if(t0){const tm=Runtime.timers[t0];tm.autoloop=false;
      tm.running=true;tm.elapsedMs=((tm.seconds||60)*1000)+5000;tm.lastStart=Date.now();}
    tickAll();await w(400);
    const apres={capsule:H('#cbTimers'),carte:H(sel)};
    const echu=!!document.querySelector('.rt-dock .tmcard.due,.tmcard.due,#cbTimers .seg.due');
    /* ── A6 ── Toutes les tailles de texte RÉELLEMENT peintes dans la vue de crise. On ignore ce
       que la doctrine exempte NOMMÉMENT : le schéma (dessin à échelle variable, cf. audit-a11y)
       et les champs à 16 px du plancher tactile (valeur de SERVICE, contrainte du moteur, pas un
       palier — A6 le dit en toutes lettres). */
    const tailles={};
    document.querySelectorAll('body *').forEach(el=>{
      if(el.closest('.flow-scroll'))return;
      /* `<option>` est peint par le SYSTÈME dans sa liste déroulante, pas par la feuille : sa
         taille n'appartient à aucune échelle de la page, et son parent `<select>` est déjà
         exempté au titre du plancher tactile de 16 px. */
      if(/^(INPUT|TEXTAREA|SELECT|OPTION|OPTGROUP)$/.test(el.tagName))return;
      /* `.sr-only` n'est PAS peint : sa taille ne dit rien de l'écran, et l'imposer sur l'échelle
         serait mesurer une chose qui n'existe pas visuellement. */
      if(el.closest('.sr-only'))return;
      const cs=getComputedStyle(el);
      if(cs.display==='none'||cs.visibility==='hidden')return;
      const own=[...el.childNodes].some(n=>n.nodeType===3&&n.textContent.trim().length);
      if(!own)return;
      const fs=Math.round(parseFloat(cs.fontSize)*10)/10;
      if(ECH.indexOf(fs)<0)(tailles[fs]=tailles[fs]||[]).push((el.className||el.tagName)+'');
    });
    /* ── A11 ── Une masse colorée = un APLAT de registre (rouge ou ambre PLEIN) sur une surface
       de plus de 2 000 px². Les CONTOURS, les liserés et les teintes à 15 % n'en sont pas : la
       doctrine dit « une étape critique se MARQUE, elle ne se remplit pas ». */
    const cv=n=>getComputedStyle(document.documentElement).getPropertyValue(n).trim();
    const norm=c=>{const m=String(c).match(/\d+/g);return m?m.slice(0,3).join(','):'';};
    const pleins=[norm(cv('--crit')),norm(cv('--warn'))].filter(Boolean);
    const masses=[];
    document.querySelectorAll('body *').forEach(el=>{
      const cs=getComputedStyle(el);const bg=norm(cs.backgroundColor);
      if(!bg||pleins.indexOf(bg)<0)return;
      const rr=el.getBoundingClientRect();
      if(rr.width*rr.height>2000)masses.push((el.className||el.tagName)+'');
    });
    return {avant,apres,echu,tailles,masses};},ECHELLE);

  t('témoin : le minuteur est réellement passé à l\'état ÉCHU', r.echu===true);
  t('A9 · la capsule ne change pas de hauteur quand un minuteur échoit',
    r.avant.capsule!==null&&r.avant.capsule===r.apres.capsule,
    `${r.avant.capsule} → ${r.apres.capsule} px`);
  t('A9 · … ni la carte du minuteur',
    r.avant.carte!==null&&Math.abs(r.avant.carte-r.apres.carte)<=1,
    `${r.avant.carte} → ${r.apres.carte} px`);
  t('A6 · aucune taille de texte hors échelle fermée dans la vue de crise',
    Object.keys(r.tailles).length===0,
    Object.entries(r.tailles).map(([k,v])=>k+'px → '+v.slice(0,3).join(', ')).join(' | '));
  t('A11 · au plus UNE masse colorée à l\'écran',
    r.masses.length<=1, `${r.masses.length} : ${r.masses.slice(0,4).join(' · ')}`);

  /* ── ACQUITTER UNE ALARME (v5.6) — MÊME PAGE, MÊME MANŒUVRE D'ÉCHÉANCE. Signalé à l'usage :
     « un minuteur sans relance, une fois échu, s'affiche dans le bandeau session et tout, c'est
     super ; mais aucun moyen de le faire disparaître que de le relancer ». La doctrine v4.2.0
     disait « acquittement par l'ACTION » et elle a raison sur le fond — mais elle ne prévoyait
     qu'UNE façon d'agir. « ✓ Vu » est le master caution de l'ECAM : on l'acquitte à SA station,
     la panne reste écrite. C'est mesuré ICI et non dans une section à part : le contexte est le
     même au geste près (volet ouvert, minuteur échu), et le recharger coûterait une page pour
     rien. */
  const ack=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const st=()=>{const c=document.querySelector('.rt-dock .tmcard');
      const ct=c&&c.querySelector('.tm-ctrl');
      return {quai:document.querySelectorAll('#cbTimers .seg.due').length,
        carte:document.querySelectorAll('.rt-dock .tmcard.due').length,
        bouton:document.querySelectorAll('[data-tmack]').length,
        ctrl:ct?Math.round(ct.getBoundingClientRect().height):0};};
    const echu=st();
    const b=document.querySelector('[data-tmack]');if(b)b.click();await w(400);
    const acq=st(),flag=!!Object.values(Runtime.timers)[0].ack;
    const tg=document.querySelector('[data-tmtoggle]');if(tg)tg.click();await w(400);
    return {echu,acq,flag,relance:{...st(),ack:!!Object.values(Runtime.timers)[0].ack}};});

  t('acquitter · « ✓ Vu » paraît AU TICK, sans re-rendu', ack.echu.bouton===1);
  t('acquitter · le quai se tait', ack.acq.quai===0, JSON.stringify(ack.acq));
  /* CE QUI NE DOIT PAS CHANGER : l'état. La carte dit toujours « échu ». */
  t('acquitter · … mais le minuteur RESTE échu sur sa carte',
    ack.acq.carte===1&&ack.flag===true, `carte ${ack.acq.carte} · drapeau ${ack.flag}`);
  t('acquitter · … et le bouton s\'efface, il n\'y a plus rien à acquitter', ack.acq.bouton===0);
  /* A9 · « ✓ Vu » se sert dans la part de la remise à zéro, il ne prend pas une ligne de plus.
     ⚠ ON COMPARE LES DEUX ÉTATS ÉCHUS — avec et sans le bouton —, jamais l'échu au nominal :
     dans le RAIL, une carte nominale replie ses commandes et les rouvre en échéant, ce qui est
     une décision antérieure et une autre question. Avant correction : 94 → 144 px.
     ⚠ ET LE CAS N'EST RENCONTRÉ QU'EN COLONNE ÉTROITE : dans le rail large la rangée ne
     s'enroule pas, trois boutons s'y resserrent sur une ligne et le contrôle resterait VERT sur
     le défaut (vérifié). */
  t('acquitter · … sans avoir ajouté de ligne à la rangée (A9)', ack.echu.ctrl===ack.acq.ctrl,
    `${ack.acq.ctrl} sans le bouton → ${ack.echu.ctrl} avec`);
  t('acquitter · relancer efface l\'acquittement', ack.relance.ack===false);

  /* ── A9 · LE LIBELLÉ (v5.6, #53) — mesuré à 320 px, LE SEUL FORMAT OÙ LE CAS EXISTE : à 390 le
     libellé occupe déjà deux lignes dans les deux états (colonne de 136 px), donc le contrôle y
     resterait vert sur le défaut. On redimensionne au lieu de recharger — l'état de session et
     le volet survivent, et c'est une page de moins. */
  await page.setViewportSize({width:320,height:844});
  const lab=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const t=Object.values(Runtime.timers)[0];
    const H=()=>{const c=document.querySelector('.rt-dock .tmcard');
      const l=c&&c.querySelector('.tm-label');
      /* ⚠ ON COMPTE LES LIGNES DU TEXTE, PAS LA HAUTEUR DE LA BOÎTE : depuis que le libellé
         RÉSERVE ses deux lignes, sa boîte en fait deux dans les deux états — mesurer la boîte
         reviendrait à mesurer le correctif au lieu du cas qu'il traite. Un `Range` rend un
         rectangle par ligne de texte, insensible au `min-height`. */
      let lignes=null;
      if(l){const rg=document.createRange();rg.selectNodeContents(l);lignes=rg.getClientRects().length;}
      return {carte:c?Math.round(c.getBoundingClientRect().height):null,lignes};};
    t.ack=false;t.autoloop=false;t.running=false;t.elapsedMs=0;t.lastStart=0;tickAll();await w(400);
    const nominal={...H(),txt:(document.querySelector('.rt-dock .tm-label')||{}).textContent||''};
    t.elapsedMs=(t.seconds||60)*1000;tickAll();await w(400);
    const echu={...H(),txt:(document.querySelector('.rt-dock .tm-label')||{}).textContent||''};
    return {nominal,echu};});
  t('témoin : le libellé s\'allonge bien en échéant', /réévaluer/.test(lab.echu.txt)&&!/réévaluer/.test(lab.nominal.txt));
  t('témoin : et il tenait sur UNE ligne au nominal', lab.nominal.lignes===1, `${lab.nominal.lignes} ligne(s)`);
  t('A9 · 320 px · le libellé réserve ses deux lignes, la carte ne grandit pas',
    lab.nominal.carte===lab.echu.carte, `${lab.nominal.carte} → ${lab.echu.carte} px`);
  /* ── REPLIÉE, LA CARTE EST UN STATUT D'UNE LIGNE, ET SA LIGNE EST CENTRÉE (v5.6, signalé à
     l'usage : « quand le bloc est enroulé, le numéro et le titre se déplacent mais ne sont pas
     centrés verticalement »). L'en-tête OUVERT est fait pour deux rangées et aligné sur les
     BASELINES ; replié, la même mise en page donnait 73 px de haut avec le numéro 23 px au-dessus
     du milieu et le titre 7 en dessous. On mesure les quatre parts contre le MILIEU de la rangée —
     un alignement se mesure sur les centres, pas sur les hauts (deux objets de tailles
     différentes n'ont pas le même haut). */
  const repli=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const tg=document.querySelector('.ov-block .ov-tgl');if(!tg)return null;
    tg.click();await w(400);
    const b=document.querySelector('.ov-block'),g=b.querySelector('.ov-tgl');
    const mid=e=>{if(!e)return null;const r=e.getBoundingClientRect();return r.top+r.height/2;};
    const m0=mid(g);
    const part=s2=>{const e=g.querySelector(s2);return e?Math.round(mid(e)-m0):null;};
    const gauche=s2=>{const e=g.querySelector(s2);return e?Math.round(e.getBoundingClientRect().left):null;};
    const out={repliee:b.classList.contains('closed'),
      h:Math.round(g.getBoundingClientRect().height),
      ecarts:{n:part('.ov-n'),t:part('.ov-t'),c:part('.ov-c'),chev:part('.ov-chev')},
      ordre:[gauche('.ov-n'),gauche('.ov-t'),gauche('.ov-c')]};
    tg.click();await w(300);
    return out;});
  t('replié · témoin : la carte est bien repliée', !!repli&&repli.repliee===true, JSON.stringify(repli));
  t('replié · les quatre parts sont centrées sur la rangée',
    !!repli&&Object.values(repli.ecarts).every(v=>v!==null&&Math.abs(v)<=1), JSON.stringify(repli&&repli.ecarts));
  /* Une ligne, pas deux : la hauteur de la rangée repliée est celle d'un contrôle. */
  t('replié · … et la rangée ne fait qu'+'\u2019'+'UNE ligne', !!repli&&repli.h<=52, repli?`${repli.h} px`:'—');
  /* On lit d'abord CE QUE C'EST, ensuite où ça en est : numéro, titre, puis compte. */
  t('replié · … dans l'+'\u2019'+'ordre de lecture (numéro · titre · compte)',
    !!repli&&repli.ordre[0]<repli.ordre[1]&&repli.ordre[1]<repli.ordre[2], JSON.stringify(repli&&repli.ordre));

  /* ── LA NUIT, LES TROIS MATIÈRES SE DISTINGUENT — ET LA CARTE A UNE LIMITE (v5.6, variante C
     choisie sur maquettes). Mesuré avant : travail contre ambiance 1,10:1 et filet contre travail
     1,21:1 — une carte n'avait ni ombre (« la nuit ne projette pas, elle borde ») ni bord
     perceptible, et c'est le COMPTAGE qui échouait, pas la lecture. `audit-a11y` ne pouvait pas le
     voir : il mesure le TEXTE, et le texte, lui, était à 14:1.
     On mesure ici parce que le décor est déjà dressé — même page, même session (règle « une
     manœuvre, une section ») ; seul le thème change, et il est rendu à sa valeur ensuite. */
  const nuit=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const avant=document.documentElement.dataset.theme||'';
    document.documentElement.dataset.theme='dark';await w(300);
    const f=v=>{v/=255;return v<=0.03928?v/12.92:Math.pow((v+0.055)/1.055,2.4);};
    const L=c=>{const m=(String(c).match(/[\d.]+/g)||[0,0,0]).slice(0,3).map(Number);
      return .2126*f(m[0])+.7152*f(m[1])+.0722*f(m[2]);};
    const R=(x,y)=>{const l=[L(x),L(y)].sort((a,b)=>b-a);return Math.round((l[0]+.05)/(l[1]+.05)*100)/100;};
    const al=c=>{const m=(String(c).match(/[\d.]+/g)||[]);return m.length>3?+m[3]:1;};
    const opq=e=>{for(let n=e;n;n=n.parentElement){const c=getComputedStyle(n).backgroundColor;
      if(al(c)>0.99&&!/rgba\(0, 0, 0, 0\)/.test(c))return c;}return 'rgb(0,0,0)';};
    const card=document.querySelector('.ov-block'),cap=document.querySelector('#cbTimers');
    if(!card||!cap){document.documentElement.dataset.theme=avant;return null;}
    const cs=getComputedStyle(card),t=card.querySelector('.ov-t');
    const out={matiere:R(cs.backgroundColor,opq(card.parentElement)),
      filet:R(cs.borderTopColor,cs.backgroundColor),
      encre:t?R(getComputedStyle(t).color,cs.backgroundColor):null,
      systemeVsTravail:R(getComputedStyle(cap).backgroundColor,cs.backgroundColor)};
    document.documentElement.dataset.theme=avant;await w(150);
    return out;});
  t('nuit · témoin : la carte et la capsule sont bien mesurées', !!nuit&&nuit.encre!==null, JSON.stringify(nuit));
  /* Le SEUIL est celui de la limite d'un composant (WCAG 2.2 § 1.4.11). */
  t('nuit · la carte de travail a une LIMITE perceptible (≥ 3:1)',
    !!nuit&&nuit.filet>=3, nuit?`${nuit.filet}:1`:'—');
  /* La matière n'a pas de seuil réglementaire — c'est elle qui décide de la charge du filet ; on
     vérifie seulement qu'elle ne retombe pas au ras de l'ambiance (1,10 avant la variante C). */
  t('nuit · … et elle se détache de l\'ambiance', !!nuit&&nuit.matiere>=1.18,
    nuit?`${nuit.matiere}:1`:'—');
  t('nuit · SYSTÈME et TRAVAIL ne sont plus la même matière',
    !!nuit&&nuit.systemeVsTravail>1.03, nuit?`${nuit.systemeVsTravail}:1`:'—');
  t('nuit · … sans rien coûter à l\'encre (≥ 4,5:1)', !!nuit&&nuit.encre>=4.5,
    nuit?`${nuit.encre}:1`:'—');
  await page.close();
}
});

/* ══ v5.6 — « ＋ AJOUTER » DEPUIS UN CHAMP FOCALISÉ AJOUTE VRAIMENT UNE LIGNE ════════════════
   Signalé à l'usage : « si j'ai tapé du texte dans le champ et que j'appuie directement sur
   ＋ Rappel, la ligne n'est pas ajoutée — il referme le bloc mais n'ajoute rien ; pareil pour la
   condition d'entrée, les blocs d'étapes, les références, les diagnostics à éliminer et les
   surveillances ». C'est le VOL DE CLIC de la v4.77.0, un cran plus loin : entre `mousedown` et
   `mouseup`, le champ perd le focus, la rangée referme ses outils (`.li-tools`, affichés en
   `:focus-within`), la page se resserre d'autant — et le bouton n'est plus sous le pointeur
   quand `mouseup` arrive, donc AUCUN `click` n'est émis.
   ⚠ LE TÉMOIN DOIT CLIQUER POUR DE VRAI : un `.click()` programmatique ne déplace aucun focus et
   ajoute la ligne même sur le code fautif — il serait resté vert sur les sept familles. */
await sec('v5.6 · « ＋ Ajouter » depuis un champ focalisé', async () => {
{
  const page=await br.newPage({viewport:{width:1100,height:900}});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const f=fiches.find(x=>/Anaphylaxie/.test(x.title));await openEdit(f.id);await w(800);});

  const essai=async(nom,selChamp,selBtn,compte)=>{
    const av=await page.evaluate(compte);
    const ch=page.locator(selChamp).last();
    await ch.scrollIntoViewIfNeeded();await ch.click();
    await page.keyboard.type('ZZ');await page.waitForTimeout(150);
    const b=page.locator(selBtn).first();
    await b.scrollIntoViewIfNeeded();await b.click();await page.waitForTimeout(400);
    const ap=await page.evaluate(compte);
    t(`${nom} : la ligne est AJOUTÉE malgré le focus dans un champ`, ap===av+1, `${av} → ${ap}`);
    const garde=await page.evaluate(compte.toString().includes('forgetAll')
      ? '(()=>forgetAll(state.draft).some(x=>/ZZ/.test(String(x))))()'
      : '(()=>JSON.stringify(state.draft).indexOf("ZZ")>=0)()');
    t(`… et le texte en cours de frappe n'est pas perdu`, garde===true);
  };

  for(const [nom,k] of [['surveillances','verify'],['condition d\'entrée','confirmation'],
                        ['références','sources'],['diagnostics à éliminer','differentials'],
                        ['repères posologiques','posology']]){
    await essai(nom,`input[data-key="${k}"]`,`[data-add="${k}"]`,
      new Function('return edList(state.draft,"'+k+'").length'));
  }
  await essai('« Ne pas oublier »','.ed-forget input:not([disabled])','[data-fgadd]',
    ()=>forgetAll(state.draft).length);
  await essai('étapes d\'un bloc','.blk[data-bid] input[data-sf]','[data-addstep]',
    ()=>bItems(state.draft.blocks[0]).length);
  /* ⚠ UN RE-RENDU PENDANT QU'UN CHAMP VIDE EST FOCALISÉ NE DOIT PAS AVORTER (v5.6, trouvé au
     balayage). Le champ d'étape vide se supprime AU BLUR — mais ce blur peut être celui du rendu
     lui-même (remplacer le contenu de `main` retire le champ focalisé) : re-rendre depuis là
     revient à écrire dans `main` pendant qu'on y écrit, Chrome lève, et le rendu extérieur
     s'arrête au milieu — écouteurs non câblés, focus non rendu, ancrage sauté. On provoque donc
     exactement ce cas : champ vide sous le focus, puis re-rendu. */
  /* ⚠ L'EN-TÊTE DE BLOC N'EXPULSE RIEN DE LA CARTE (v5.6, trouvé au balayage — 22ᵉ défaut de
     rangée flex). La rangée était en `nowrap` avec DEUX objets incompressibles (pastille et
     sélecteur de phase, 191 px) : le champ TITRE, seul à pouvoir céder, tombait à 26 px pendant
     que la poignée ⠿ sortait de 35 px du cadre. On mesure ici, à la largeur où le défaut vit —
     un redimensionnement, pas une page de plus (règle « une manœuvre, une section »). */
  await page.setViewportSize({width:320,height:844});
  await page.waitForTimeout(400);
  const bt=await page.evaluate(()=>{const top=document.querySelector('.blk-top');if(!top)return null;
    const carte=top.closest('.blk').getBoundingClientRect();
    const k=[...top.children].filter(e=>getComputedStyle(e).display!=='none');
    const inp=top.querySelector('input[type=text]');
    return {hors:Math.round(Math.max(...k.map(e=>e.getBoundingClientRect().right))-carte.right),
      titre:inp?Math.round(inp.getBoundingClientRect().width):null,
      lignes:new Set(k.map(e=>Math.round(e.getBoundingClientRect().top))).size};});
  t('320 · témoin : l\'en-tête de bloc est bien rendu', !!bt&&bt.titre!==null, JSON.stringify(bt));
  t('320 · rien ne sort de la carte du bloc', !!bt&&bt.hors<=0, bt?`${bt.hors} px`:'—');
  t('320 · … et le champ titre garde une largeur utile (≥ 120 px)',
    !!bt&&bt.titre>=120, bt?`${bt.titre} px`:'—');
  /* La rangée a donc le DROIT d'enrouler : c'est le remède du dossier — « on enroule, on ne
     tronque jamais » —, et à 1280 elle tient sur une ligne (mesuré). */
  t('320 · … en enroulant plutôt qu'+'\u2019'+'en écrasant', !!bt&&bt.lignes>=2, bt?`${bt.lignes} ligne(s)`:'—');
  await page.close();
}
});

/* ══ v5.6 — UNE FICHE D'UN SEUL BLOC EST UNE FICHE COMME LES AUTRES ═════════════════════════
   Signalé à l'usage : « s'il n'y a qu'un seul bloc avec une seule étape, le bloc ne s'affiche pas
   correctement et le parcours inerte ne s'affiche pas ». Deux causes, et la même racine — un
   critère écrit pour une autre question :
   · `hasFlow` (« y a-t-il un BRANCHEMENT ? ») décidait aussi du RENDU. À un bloc, la fiche
     retombait sur `navSection`, le rendu d'AVANT la refonte : une étiquette de texte, l'étape à
     nu sur le fond de page, un panneau « Algorithme » sans objet. La justification d'origine
     (« les deux vues y seraient identiques », v4.16.0) était vraie alors et fausse depuis le
     lot 3. Un bloc est une séquence d'UN : le journal le sert sans rien de nouveau.
   · Le même `hasFlow` masquait la colonne d'orientation, qui porte pourtant AUSSI « Quand
     l'utiliser » et « Surveiller ensuite ».
   ⚠ LA BASCULE DE FORMAT, ELLE, RESTE MASQUÉE sans branchement : « Toute la fiche » n'y montrerait
   rien de plus, et c'était la part JUSTE de la doctrine d'origine.
   ⚠ AUCUNE FIXTURE NE COUVRAIT CE CAS (les deux fiches d'exemple ont quatre blocs) : le témoin
   construit la sienne. */
/* ══ v5.6 — UN RE-RENDU NE DOIT PAS S'INTERROMPRE LUI-MÊME ════════════════════════════════
   Trouvé au balayage. Un champ d'étape VIDE se supprime au départ du focus (MK-flux) — mais ce
   `blur` peut être celui du RENDU : remplacer le contenu de `main` retire le champ focalisé, donc
   l'émet. Re-rendre depuis là revient à écrire dans `main` pendant qu'on y écrit ; Chrome lève
   « The node to be removed is no longer a child of this node », le rendu extérieur AVORTE en
   plein milieu, et ce qui le suivait — câblage des écouteurs, restitution du focus, ancrage — ne
   s'exécute jamais. Reproduit à la sonde : champ vide sous le focus, puis un redimensionnement.
   ⚠ SECTION À PART, ET C'EST MOTIVÉ : la section « ＋ Ajouter » édite sept familles de listes
   avant de finir, et le focus n'y survit pas à ses propres gestes — mesuré. Le décor partagé
   serait ici HOSTILE, pas économe (cf. la limite de la règle « une manœuvre, une section »). */
await sec('v5.6 · un re-rendu ne s\'interrompt pas lui-même', async () => {
{
  const page=await br.newPage({viewport:{width:1100,height:900}});
  const errs=[];
  page.on('pageerror',e=>{errs.push(e.message.slice(0,90));ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await page.evaluate(()=>openEdit(fiches[0].id));
  await page.waitForTimeout(700);
  /* On vide au CLAVIER, après un vrai clic : un `.focus()` programmatique ne prouverait rien. */
  /* `fill('')` de Playwright focalise puis vide, et émet `input` — le geste de l'auteur qui
     efface sa ligne, sans dépendre d'un raccourci clavier qui n'a pas le même sens d'un système
     à l'autre (`Control+A` n'est PAS « tout sélectionner » sur macOS : le témoin effaçait un
     caractère et mesurait autre chose). */
  await page.fill('.blk .li input[data-sf]','');
  await page.waitForTimeout(250);
  const av=await page.evaluate(()=>{const e=document.activeElement;
    return {focus:!!e&&!!e.matches&&e.matches('.blk .li input[data-sf]')&&e.value==='',
      champs:document.querySelectorAll('.blk .li input[data-sf]').length};});
  t('témoin : un champ d\'étape VIDE est bien sous le focus', av.focus===true, JSON.stringify(av));
  errs.length=0;ko-=0;
  /* LE RE-RENDU EXTÉRIEUR : un redimensionnement, c'est-à-dire le geste le plus banal. */
  await page.setViewportSize({width:900,height:900});
  await page.waitForTimeout(600);
  const ap=await page.evaluate(()=>({
    bind:!!document.querySelector('[data-addstep]')&&!!document.querySelector('.blk-top'),
    champs:document.querySelectorAll('.blk .li input[data-sf]').length}));
  t('le rendu ne s\'interrompt pas', errs.length===0, errs.join(' | '));
  t('… et l\'éditeur reste rendu ET câblé', ap.bind===true, JSON.stringify(ap));
  /* Le champ vide n'a PAS été supprimé : ce n'est pas l'auteur qui l'a quitté, c'est le rendu qui
     l'a retiré — la nuance est exactement ce que la garde mesure. */
  t('… et la ligne vide n\'a pas été supprimée par le rendu', ap.champs===av.champs,
    `${av.champs} → ${ap.champs}`);
  await page.close();
}
});

await sec('v5.6 · une fiche d\'un seul bloc', async () => {
{
  for(const W of [390,1280]){
    const page=await br.newPage({viewport:{width:W,height:900},hasTouch:W<780});
    page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'));
    await amorce(page);
    const r=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
      const f0=blankFiche();f0.title='Mono';
      const A=v4MakeItem(uid('i'),'do','Geste unique',false),B=v4MakeItem(uid('i'),'do','Second geste',false);
      f0.items=[A,B];f0.blocks=[{id:'b1',kind:'do',title:'Le bloc',items:[A.id,B.id]}];f0.start='b1';
      const f=migrate(f0);fiches.push(f);await persist();
      openRead(f.id);await w(600);
      const sb=document.getElementById('sessStart');if(sb)sb.click();await w(800);
      /* Deux étapes : une seule ne peut pas révéler un compte qui ne se met plus à jour. */
      for(let g=0;g<6;g++){
        const li=[...document.querySelectorAll('[data-ck]')].find(x=>!x.classList.contains('done'));
        if(!li)break;li.dispatchEvent(new MouseEvent('click',{bubbles:true}));await w(300);}
      const apresCoches={compte:(document.querySelector('.ov-block .ov-c')||{}).textContent||'',
        btn:((document.querySelector('[data-ovnext],[data-ovend]')||{}).textContent||'').trim()};
      const side=document.querySelector('.read-side');
      return {apresCoches,carte:main.querySelectorAll('.ov-block').length,
        etapes:main.querySelectorAll('ol.steps li[data-ck]').length,
        vieuxRendu:!!main.querySelector('.nav-wrap'),
        parcours:document.querySelectorAll('.read-plan .pl-line,.rail-lad .pl-line').length,
        bascule:!!document.querySelector('#dispBack,[data-dispback]'),
        /* Aucun filet suspendu au-dessus du vide : une section vide ne compte pas comme voisine. */
        filetOrphelin:side?[...side.querySelectorAll('.rail-sec')].some(e=>{
          const p=e.previousElementSibling;
          return p&&p.classList.contains('rail-sec')&&p.getBoundingClientRect().height===0
                 &&parseFloat(getComputedStyle(e).borderTopWidth)>0;}):false};});

    t(`${W} · le bloc est rendu par la CARTE de travail, pas par l'ancien rendu`,
      r.carte===1&&r.vieuxRendu===false, JSON.stringify(r));
    t(`${W} · … et ses étapes sont cochables`, r.etapes===2, `${r.etapes} étape(s)`);
    /* ⚠ ET LE CÂBLAGE SUIT LE RENDU (v5.6) : la résolution du mode était RECOPIÉE dans le
       binder, si bien qu'on rendait la carte de travail en branchant les gestes de l'ancienne
       vue guidée — cocher la DEUXIÈME étape ne mettait plus à jour ni le compte ni le bouton
       d'avancement. Le contrôle coche TOUT et vérifie que les deux ont suivi. */
    t(`${W} · le compte et le bouton suivent CHAQUE coche`,
      r.apresCoches&&r.apresCoches.compte==='2/2'&&/Terminer/.test(r.apresCoches.btn||''),
      JSON.stringify(r.apresCoches));
    t(`${W} · aucun filet de famille suspendu au-dessus du vide`, r.filetOrphelin===false);
    if(W>=1200) t(`${W} · le parcours inerte existe, même à un bloc`, r.parcours>=1,
      `${r.parcours} rangée(s)`);
    await page.close();
  }
}
});

/* ══ v5.6 — UN FILTRE POSÉ AGIT AUSSI EN RECHERCHE ══════════════════════════════════════════
   Signalé à l'usage : « en mode recherche, quand on change de catégorie, rien ne se passe ». La
   branche de recherche ignorait `state.scope` ET `state.cat` : le déclencheur annonçait « 1 filtre »
   pendant que la liste n'en tenait aucun compte — un contrôle MORT au moment précis où l'on s'en
   sert, et pire, un contrôle qui MENT. Ce n'est pas la règle « on réordonne, on ne filtre jamais » :
   celle-là vaut pour un rapprochement que la machine devine (posologie, étiquettes), pas pour un
   cran posé du doigt. La règle de v5.0.3 tient dans les deux sens : on ne peut pas se retrouver
   dans un corpus restreint sans savoir pourquoi — ni croire l'avoir restreint sans que rien ne
   bouge. */
await sec('v5.6 · un filtre posé agit aussi en recherche', async () => {
{
  const page=await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const n=()=>document.querySelectorAll('.dir-row').length;
    /* ⚠ ON COMPARE LES RÉSULTATS, PAS LEUR NOMBRE : avec deux fiches d'une catégorie chacune, les
       deux crans donnent « 1 » — un contrôle sur le compte serait rouge sur un correctif juste. */
    const titres=()=>[...document.querySelectorAll('.dir-row .dir-t')].map(e=>e.textContent.trim()).join('|');
    const q=document.getElementById('q');
    q.value='a';q.dispatchEvent(new Event('input',{bubbles:true}));await w(450);
    const sansFiltre=n();
    /* On prend la catégorie d'UNE fiche réellement présente : un identifiant inventé ne
       filtrerait rien et le contrôle mesurerait le vide. */
    const vues=[...document.querySelectorAll('.dir-row')];
    const cats=[...new Set(fiches.map(f=>f.category).filter(Boolean))];
    if(cats.length<2)return {err:'moins de deux catégories — cas non constitué'};
    state.cat=cats[0];render();await w(450);
    const avecA=n(),titA=titres();
    state.cat=cats[1];render();await w(450);
    const avecB=n(),titB=titres();
    state.cat='';render();await w(450);
    return {sansFiltre,avecA,avecB,titA,titB,rendu:n(),vues:vues.length};});

  if(r.err){t('témoin : le cas est constitué',false,r.err);}
  else{
    t('témoin : la recherche rend bien des résultats', r.sansFiltre>=2, `${r.sansFiltre} rangée(s)`);
    t('poser une catégorie RESTREINT les résultats de recherche',
      r.avecA<r.sansFiltre, `${r.sansFiltre} → ${r.avecA}`);
    t('… et changer de catégorie change le RÉSULTAT',
      r.titA!==r.titB&&!!r.titA, `« ${r.titA} » puis « ${r.titB} »`);
    t('… et le retirer les rend tous', r.rendu===r.sansFiltre, `${r.rendu} / ${r.sansFiltre}`);
  }
  await page.close();
}
});

/* ══ v5.6 — LE VOLET DU DOCK SUIT LA BARRE, ET LA MAQUETTE LES SÉPARE LÉGÈREMENT ═══════════
   Signalé à l'usage : « la mini-fenêtre qui apparaît sur Noter l'heure ou Complication n'est plus
   adaptée à la nouvelle taille de la barre flottante, elle est décalée par moments, et dans le
   mockup elle en est un tout petit peu séparée ». Deux défauts mesurés : elle se posait à
   `bottom:64px` EN DUR — valeur juste le jour où elle a été écrite, fausse dès que la barre change
   de contenu, et qui la faisait CHEVAUCHER la barre de 8 px — et elle se centrait sur la FENÊTRE
   (`max-width:660; margin:auto`) quand la barre s'aligne sur la COLONNE D'ACTION : 310..970 contre
   280..920 à 1280 px, 120..780 contre 20..540 à 900. */
/* ══ v5.6 — LES TROIS GESTES D'APPAREIL ET DE VOLET (planches 11h, 11i, 11k) ═══════════════════
   Le verrou de veille est le seul dont le défaut se mesure en CONSOMMATION : « un verrou redemandé
   en boucle est un bogue de consommation », dit la planche — c'est donc le NOMBRE DE DEMANDES qu'on
   compte, pas la présence d'un interrupteur. L'API est instrumentée AVANT le chargement : on ne
   dépend ni du navigateur d'essai ni d'une permission. */
await sec('v5.6 · veille, minuteur et compteur ad hoc', async () => {
{
  const page=await br.newPage({viewport:{width:390,height:900},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.addInitScript(()=>{window.__wl={req:0,rel:0};
    const s={addEventListener(){},release(){window.__wl.rel++;return Promise.resolve();}};
    Object.defineProperty(navigator,'wakeLock',{value:{request:()=>{window.__wl.req++;return Promise.resolve(s);}},configurable:true});});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  await ouvrirFiche(page,/Anaphylaxie/);
  const avant=await page.evaluate(()=>({...window.__wl,tenu:wakeActive()}));
  t('hors session, aucun verrou n\'est demandé', avant.req===0&&avant.tenu===false, JSON.stringify(avant));
  await demarrerSession(page);
  await page.waitForTimeout(400);
  const r=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const enSession={...window.__wl,tenu:wakeActive()};
    for(let i=0;i<5;i++){render();await w(60);}
    const apresRendus={...window.__wl,tenu:wakeActive()};
    document.getElementById('cbTimers').click();await w(400);
    document.getElementById('wakeToggle').click();await w(300);
    const coupe={...window.__wl,tenu:wakeActive(),lbl:document.getElementById('wakeToggle').textContent.trim()};
    document.getElementById('wakeToggle').click();await w(300);
    const repris={...window.__wl,tenu:wakeActive()};
    /* ══ MINUTEUR AD HOC : le ＋ DÉPLIE, la durée se choisit, le nom vient du dernier repère ══ */
    const lbl=()=>document.querySelector('[data-rtadd]').textContent.trim();
    const nu=lbl();
    Runtime.events.push({id:'ez1',t:Date.now(),label:'Amiodarone'});render();await w(300);
    const nomme=lbl();
    document.querySelector('[data-rtadd]').click();await w(300);
    const durees=[...document.querySelectorAll('[data-rtnew]')].map(b=>b.textContent.trim());
    const champs=document.querySelectorAll('.rt-dock input[type=text],.rt-dock input[type=number]').length;
    document.querySelector('[data-rtnew="180"]').click();await w(400);
    const tm=Object.values(Runtime.timers).filter(x=>x.adhoc).pop();
    /* ══ COMPTEUR AD HOC : créé À 1, un repère horodaté, et AUCUN timerId ══ */
    const evAvant=(Runtime.events||[]).filter(e=>e.ref&&e.ref.type==='counter').length;
    document.querySelector('[data-cnadd]').click();await w(450);
    const c=(Runtime.adhocCounters||[]).pop();
    const cn={val:c?Runtime.counters[c.id]:null,lien:c?(c.timerId===undefined):null,
      reperes:(Runtime.events||[]).filter(e=>e.ref&&e.ref.type==='counter').length-evAvant};
    /* Le nom pressenti ne reprend JAMAIS un libellé de repli (« Compteur », « Action 3 »). */
    const apresCompteur=lbl();
    const nommable=!!document.querySelector('.rt-dock .tm-mini [data-tmname]');
    return {enSession,apresRendus,coupe,repris,nu,nomme,durees,champs,nommable,
      tm:tm?{label:tm.label,sec:tm.seconds,running:tm.running}:null,cn,apresCompteur};});
  t('en session, le verrou est demandé UNE fois',
    r.enSession.req===1&&r.enSession.tenu===true, JSON.stringify(r.enSession));
  t('… et cinq rendus ne le redemandent pas (pas de boucle de consommation)',
    r.apresRendus.req===1, JSON.stringify(r.apresRendus));
  t('… l\'interrupteur le relâche, et le dit', r.coupe.req===1&&r.coupe.rel===1
    &&r.coupe.tenu===false&&/veille/i.test(r.coupe.lbl), JSON.stringify(r.coupe));
  t('… et le redemande quand on le rallume', r.repris.req===2&&r.repris.tenu===true, JSON.stringify(r.repris));
  /* ⚠ CES DEUX TÉMOINS MESURAIENT UNE DEVINETTE, ET ELLE EST SUPPRIMÉE (v5.6, signalé à l'usage :
     « comment as-tu trouvé l'intitulé automatique, c'est très mauvais et ça ne se met pas à jour à
     chaque bloc »). Le bouton reprenait le nom du DERNIER REPÈRE — une source sans rapport avec le
     bloc courant, donc incapable de le suivre. Ils mesurent désormais la propriété qui remplace la
     devinette : la porte ne dit QUE sa nature, quel que soit ce qu'on a horodaté avant, et le nom
     se pose APRÈS, à la main, sur l'objet. */
  t('＋ Minuteur : il ne dit que sa nature',
    /＋\s*Minuteur$/.test(r.nu)&&!/PA/.test(r.nu), r.nu);
  t('… et un repère étiqueté ne le change pas', /＋\s*Minuteur$/.test(r.nomme), r.nomme);
  t('… son tap déplie QUATRE durées, sans aucun champ',
    r.durees.length===4&&r.champs===0, JSON.stringify(r.durees)+' · '+r.champs+' champ(s)');
  t('… la durée choisie est celle du minuteur créé, qui naît SANS nom',
    !!r.tm&&r.tm.sec===180&&r.tm.label===''&&r.tm.running===true, JSON.stringify(r.tm));
  t('… et sa rangée porte de quoi le nommer', r.nommable===true, `${r.nommable}`);
  t('＋ Compteur : créé À 1, avec son repère horodaté',
    r.cn.val===1&&r.cn.reperes===1, JSON.stringify(r.cn));
  t('… et SANS timerId : le lien vers une alarme est une décision d\'auteur', r.cn.lien===true);
  /* ══ v5.6, signalés à l'usage — DEUX DÉFAUTS DU COMPTEUR AD HOC ═══════════════════════════════
     (a) « renommer fait disparaître la barre flottante » : `kb-open` (A1, le clavier efface le
         dock) était posée au focus et retirée au blur — or le commit RE-REND, donc le champ meurt
         avant son `focusout` et la classe restait, dock compris.
     (b) « un nouveau compteur n'apparaît pas dans Noter l'heure » : le vivier lisait `f.counters`,
         et un objet créé EN SESSION vit dans le Runtime. Et il doit en SORTIR à la suppression —
         ce qui est acquis puisque le vivier est calculé, jamais mémorisé. */
  const cnb=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const vis=()=>getComputedStyle(document.getElementById('sessionDock')).display;
    const noms=()=>tagAll(Runtime.fiche,myTags(),rtExtra()).map(x=>x.label);
    /* ⚠ IL CONSTRUIT SON CAS : s'appuyer sur un compteur créé par un bloc précédent, c'est mesurer
       l'état que ce bloc a laissé — et il n'en laisse pas forcément (mesuré : 0). */
    if(!(Runtime.adhocCounters||[]).length){
      const b=document.querySelector('[data-cnadd]');if(!b)return {erreur:'aucune porte de compteur'};
      b.click();await w(500);}
    if(!(Runtime.adhocCounters||[]).length)return {erreur:'la porte ne crée pas de compteur'};
    const cree=noms().filter(l=>/^Compteur \d/.test(l)).length;
    const bn=document.querySelector('[data-cnname]');
    if(!bn)return {erreur:'aucun bouton « nommer » — le compteur ad hoc n’est pas rendu'};
    bn.click();await w(300);
    const inp=document.querySelector('.cn-input');
    if(!inp)return {erreur:'le champ de nommage ne s’ouvre pas',cnadd:!!document.querySelector('[data-cnadd]'),
      cartes:document.querySelectorAll('.cncard').length,adhoc:(Runtime.adhocCounters||[]).length};
    inp.value='Chocs';
    inp.dispatchEvent(new Event('input',{bubbles:true}));
    inp.dispatchEvent(new KeyboardEvent('keydown',{key:'Enter',bubbles:true}));
    await w(500);
    const apresNom={dock:vis(),nomme:noms().includes('Chocs')};
    document.querySelector('[data-cnrm]').click();await w(400);
    const y=document.getElementById('confirmYes');if(y)y.click();await w(500);
    return {cree,apresNom,apresSuppr:noms().includes('Chocs'),dockFin:vis()};});
  if(cnb.erreur){t('témoin : le compteur ad hoc est manipulable',false,JSON.stringify(cnb));}
  else{
  t('un compteur créé en session entre dans « Noter l\'heure »', cnb.cree>=1, `${cnb.cree}`);
  t('… le renommer ne fait pas disparaître la barre flottante',
    cnb.apresNom.dock!=='none', cnb.apresNom.dock);
  t('… et son nouveau nom y est', cnb.apresNom.nomme===true);
  t('… le supprimer l\'en retire', cnb.apresSuppr===false&&cnb.dockFin!=='none',
    JSON.stringify({vivier:cnb.apresSuppr,dock:cnb.dockFin}));}
  t('… un libellé de repli ne devient jamais le nom pressenti d\'un minuteur',
    !/Compteur|Action/.test(r.apresCompteur), r.apresCompteur);
  /* ⚠ LE DÉROULÉ APPARTIENT AU TAP QUI OUVRE (A68/1, signalé à l'usage : « ajouter un minuteur
     réinitialise le contenu, on perd le fil et ça fait un fondu blanc moche »). Le volet vit dans
     `main` : tout rendu complet le remonte, et l'animation, portée par le MONTAGE, rejouait à
     chaque geste. On mesure les deux moitiés — elle joue à l'ouverture, elle ne rejoue pas après —
     et le défilement PROPRE du volet, qui repartait en haut. */
  const roul=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const an=()=>{const d=document.querySelector('.rt-dock');return d?getComputedStyle(d).animationName:'—';};
    document.getElementById('cbTimers').click();await w(300);          // referme
    document.getElementById('cbTimers').click();await w(300);          // rouvre : le déroulé joue
    const ouverture=an();
    const d=document.querySelector('.rt-dock');d.scrollTop=40;const y0=d.scrollTop;
    document.querySelector('[data-cnadd]').click();await w(450);
    const d2=document.querySelector('.rt-dock');
    return {ouverture,apres:an(),y0,y1:d2?d2.scrollTop:-1};});
  /* ══ A68 / planche 11g/1 — LA RANGÉE DE REPÈRE QUI VIENT D'ÊTRE ÉCRITE SE DÉSIGNE ═══════════
     Le panneau est remplacé EN PLACE à chaque ajout : rien ne disait LAQUELLE est nouvelle.
     ⚠ ET LE DRAPEAU DOIT ÊTRE CONSOMMÉ : le panneau se repeint aussi au tick et sur un évènement
     distant ; une rangée qui re-clignoterait à chaque passage serait le mouvement NON commandé
     qu'A68/1 interdit. Le témoin mesure donc les deux moitiés. */
  const fresh=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    const an=()=>[...document.querySelectorAll('.tk-item')].map(e=>getComputedStyle(e).animationName);
    /* Le journal vit dans le VOLET en étroit : sans l'ouvrir, `.tk-item` n'est nulle part et l'on
       mesurerait un DOM vide en croyant mesurer une animation. */
    const tk=document.getElementById('tkKey');
    tk.click();await w(300);document.getElementById('tkKey').click();await w(250);
    tk.click();await w(300);document.getElementById('tkKey').click();await w(250);
    if(!document.querySelector('.rt-dock'))document.getElementById('cbTimers').click();
    await w(450);
    const apres=an();
    renderTkOnly();await w(200);
    return {apres,repeinture:an()};});
  t('la rangée qui vient d\'être écrite se désigne, et elle SEULE',
    fresh.apres.filter(x=>x==='cbIn').length===1&&fresh.apres.length>=2, JSON.stringify(fresh.apres));
  t('… et une repeinture ne la rejoue pas (mouvement non commandé)',
    fresh.repeinture.every(x=>x==='none'), JSON.stringify(fresh.repeinture));
  t('le volet se déroule au tap qui l\'ouvre', roul.ouverture==='dockRoll', roul.ouverture);
  t('… et NE se déroule plus à chaque geste dans le volet', roul.apres==='none', roul.apres);
  t('… qui garde aussi son défilement propre', roul.y0>0&&roul.y1===roul.y0, `${roul.y0} → ${roul.y1}`);
  await page.close();
}
{ /* SANS AUCUN MINUTEUR NI COMPTEUR PRÉDÉFINI, les deux portes existent quand même — c'est sur ces
     fiches-là qu'on en a le plus besoin, puisque l'auteur n'en a prévu aucun. Le rail sortait à
     vide et les emportait avec lui. */
  for(const [nom,W] of [['390',390],['1280',1280]]){
    const page=await br.newPage({viewport:{width:W,height:900},hasTouch:W<780});
    page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'));
    await amorce(page);
    await page.evaluate(async()=>{const f=fiches.find(x=>/Anaphylaxie/.test(x.title));
      f.timers=[];f.counters=[];await persist();});
    await ouvrirFiche(page,/Anaphylaxie/);await demarrerSession(page);
    const r=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
      if(innerWidth<780){document.getElementById('cbTimers').click();await w(400);}
      return {min:!!document.querySelector('[data-rtadd]'),cn:!!document.querySelector('[data-cnadd]')};});
    t(`${nom} · fiche sans minuteur : les deux portes existent`, r.min&&r.cn, JSON.stringify(r));
    await page.close();
  }
}
{ /* SANS L'API : la ligne n'existe pas. Dégradation silencieuse — jamais un message qui explique
     une absence, et surtout pas un interrupteur qui ne commande rien. */
  const page=await br.newPage({viewport:{width:390,height:900},hasTouch:true});
  await page.addInitScript(()=>{Object.defineProperty(navigator,'wakeLock',{value:undefined,configurable:true});});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);await ouvrirFiche(page,/Anaphylaxie/);await demarrerSession(page);
  const r=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
    document.getElementById('cbTimers').click();await w(400);
    return {veille:!!document.getElementById('wakeToggle'),son:!!document.getElementById('soundToggle')};});
  t('sans l\'API, aucune ligne de veille — et le son reste', r.veille===false&&r.son===true,
    JSON.stringify(r));
  await page.close();
}
});

await sec('v5.6 · le volet du dock suit la barre flottante', async () => {
{
  for(const W of [390,900,1280]){
    const page=await br.newPage({viewport:{width:W,height:900},hasTouch:W<780});
    page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'));
    await amorce(page);
    await ouvrirFiche(page,'Anaphylaxie');
    await demarrerSession(page);
    const r=await page.evaluate(async()=>{const w=m=>new Promise(x=>setTimeout(x,m));
      const k=[...document.querySelectorAll('.sd-key')].find(x=>/NOTER/i.test(x.textContent));
      if(!k)return {err:'touche ⏱ introuvable'};
      k.click();await w(500);
      const c=document.querySelector('.ds-card'),d=document.querySelector('#sessionDock .sd-in');
      if(!c||!d)return {err:'volet ou barre absents'};
      const C=c.getBoundingClientRect(),D=d.getBoundingClientRect();
      return {vx:Math.round(C.left),vr:Math.round(C.right),
              dx:Math.round(D.left),dr:Math.round(D.right),
              ecart:Math.round(D.top-C.bottom)};});
    if(r.err){t(`${W} · témoin`,false,r.err);}
    else{
      t(`${W} · le volet a EXACTEMENT la boîte de la barre`,
        Math.abs(r.vx-r.dx)<=1&&Math.abs(r.vr-r.dr)<=1,
        `volet ${r.vx}..${r.vr} · barre ${r.dx}..${r.dr}`);
      /* La maquette les SÉPARE : ni collés (ce serait un étage de la barre), ni recouvrants. */
      t(`${W} · … et il en est légèrement séparé, jamais par-dessus`,
        r.ecart>=4&&r.ecart<=16, `${r.ecart} px`);
    }
    await page.close();
  }
}
});

await sec('v5.6 · tolérance orthographique du répertoire', async () => {
  const page=await br.newPage({viewport:{width:390,height:900},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  /* Signalé comme besoin d'usage : sous stress et avec des gants, une faute de frappe rendait
     « aucun résultat » — et un répertoire qui répond cela fait renoncer à chercher là où le
     contenu est. Les QUATRE bornes de la doctrine se mesurent au RENDU, pas sur la fonction pure
     (tests.html la couvre déjà) : c'est le CÂBLAGE qui peut se tromper de cas. */
  await amorce(page);
  const cherche = async q => { await page.fill('#q', q); await page.waitForTimeout(400);
    return page.evaluate(() => ({
      n: document.querySelectorAll('.dir-row').length,
      fix: (document.querySelector('.fix-line') || {}).textContent || '',
      champ: document.getElementById('q').value })); };

  /* 1 · ELLE NE SE DÉCLENCHE QUE SUR ZÉRO RÉSULTAT. Le témoin doit d'abord RENCONTRER SON CAS :
     sans résultat pour la requête juste, il mesurerait le vide et resterait vert sur le défaut. */
  const juste = await cherche('anaphylaxie');
  t('témoin : la requête juste trouve bien quelque chose', juste.n >= 1, `${juste.n}`);
  t('une liste NON VIDE n\'est jamais corrigée', juste.fix === '', juste.fix);

  /* 2 · UN PRÉFIXE EN COURS DE FRAPPE N'EST PAS CORRIGÉ — sinon la liste sauterait sous le doigt. */
  const pref = await cherche('anaph');
  t('… ni un préfixe tapé en cours de route', pref.fix === '' && pref.n >= 1, `${pref.n}|${pref.fix}`);

  /* 3 · LA FAUTE EST RATTRAPÉE, ET LA CORRECTION SE DÉCLARE EN TOUTES LETTRES. */
  const faute = await cherche('anafilaxie');
  t('une faute de frappe rend malgré tout des résultats', faute.n >= 1, `${faute.n}`);
  t('… et la correction est DÉCLARÉE, avec les deux mots',
    /Aucun résultat pour/.test(faute.fix) && /anafilaxie/.test(faute.fix)
      && /anaphylaxie/.test(faute.fix), faute.fix);

  /* 4 · ELLE NE RÉÉCRIT PAS LE CHAMP : le texte tapé reste celui de l'utilisateur. */
  t('… le champ garde le texte tapé', faute.champ === 'anafilaxie', faute.champ);

  /* 5 · UN MOT QUI NE RESSEMBLE À RIEN RESTE SANS RÉPONSE — on ne fabrique pas un résultat. */
  const rien = await cherche('zzqwxyv');
  t('un mot qui ne ressemble à rien ne rapproche rien',
    rien.n === 0 && rien.fix === '', `${rien.n}|${rien.fix}`);

  await page.close();
});


await sec('v5.6 · le minuteur armé rejoint la capsule, et le quai annonce ce qu\'il cache', async () => {
  /* Planche 10d/3. Deux propriétés, et la seconde est un défaut PRÉEXISTANT trouvé en mesurant la
     première : à 390 px la boucle d'ajustement retire le segment d'un minuteur NOMINAL armé, et
     rien ne l'annonçait — « +n » ne compte que les échus depuis la v5.6, et le rappel du chevron
     se taisait dès qu'un minuteur était « voulu ». L'animation n'avait donc rien à désigner
     exactement sur le format le plus courant. */
  /* 320 est le format où la place manque VRAIMENT : le segment y est retiré, et seule l'annonce
     reste due. 700 est celui où il tient, donc le seul où l'entrée a un cas. Mesuré : 360, 390 et
     430 montrent désormais le segment — c'est pourquoi la borne du bas est 320 et pas 390. */
  for(const W of [320,700]){
    const page=await br.newPage({viewport:{width:W,height:900},hasTouch:true});
    page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
    await page.goto(`http://localhost:${port}/index.html`);
    await amorce(page);await ouvrirFiche(page,'Anaphylaxie');await demarrerSession(page);
    /* ⚠ ON ATTEND LES POLICES AVANT DE MESURER : la boucle d'ajustement du quai MÉMORISE sa
       décision sur une clé qui ne connaît pas l'état de chargement des fontes — mesurée avec la
       police de repli, elle peut retenir un segment de moins et ne jamais se redire. Sans cette
       attente, le témoin mesure le hasard du chargement, pas l'application. */
    await page.evaluate(()=>document.fonts&&document.fonts.ready);
    await page.click('#cbTimers');await page.waitForTimeout(400);
    await page.evaluate(()=>{const b=[...document.querySelectorAll('.rt-dock button')]
      .find(x=>/^Démarrer/.test((x.textContent||'').trim()));
      if(!b)throw new Error('bouton Démarrer introuvable');b.click();});
    /* ⚠ ON MESURE PENDANT L'ANIMATION, PAS APRÈS. La classe est posée sur le NŒUD et retirée par
       `animationend` : à 150 ms elle a déjà disparu, et un témoin qui la cherche là mesure sa
       propre lenteur. 50 ms — le quai répondant au geste, il n'y a plus rien à attendre. */
    await page.waitForTimeout(50);
    const g=await page.evaluate(()=>{const el=document.getElementById('cbTimers');
      const s=el.querySelector('.seg.seg-in');
      return {marques:el.querySelectorAll('.seg.seg-in').length,
        anim:s?getComputedStyle(s).animationName:'—',
        segs:el.querySelectorAll('.seg').length,
        rappel:(el.querySelector('.cbt-dl')||{}).textContent||'',
        arme:Object.values(Runtime.timers).some(t=>t.running)};});
    t(`${W} · témoin : le minuteur est bien armé`, g.arme===true);
    /* L'ANNONCE EST DUE DANS LES DEUX CAS, et c'est elle qui compte cliniquement : ou le segment
       est là, ou le rappel le nomme — jamais ni l'un ni l'autre. */
    t(`${W} · le minuteur armé est montré OU annoncé, jamais tu`,
      g.segs>=2||/minuteur/.test(g.rappel), JSON.stringify({segs:g.segs,rappel:g.rappel}));
    /* ⚠ LE CAS S'EXIGE, IL NE SE CONTOURNE PAS. Une première version rendait l'assertion
       d'animation CONDITIONNELLE à « le segment est montré » : neutraliser l'animation la faisait
       simplement SAUTER, donc le témoin restait vert sur le défaut qu'il couvre. À 390 px le
       segment est légitimement retiré (la place manque) et seule l'annonce est due ; au-dessus, il
       DOIT être là — et son absence est désormais un rouge, pas un silence. */
    if(W>=500){
      t(`${W} · témoin : le segment est bien montré`, g.segs>=2, `${g.segs} segment(s)`);
      t(`${W} · … et il entre en fondu`, g.marques===1&&g.anim==='capIn', JSON.stringify(g));
      t(`${W} · … sans se recompter dans le rappel`, !/minuteur/.test(g.rappel), g.rappel);
      /* L'ENTRÉE SE NETTOIE ET NE REJOUE PAS — la chaîne écrite ne porte pas la classe, donc les
         ticks ne réécrivent rien et le segment garde son nœud. */
      await page.waitForTimeout(1600);
      const fin=await page.evaluate(()=>({res:document.querySelectorAll('#cbTimers .seg.seg-in').length,
        seg:document.querySelectorAll('#cbTimers .seg').length}));
      t(`${W} · … puis se nettoie, sans rejouer à aucun tick`, fin.res===0, `${fin.res}`);
      t(`${W} · … et le segment, lui, reste`, fin.seg>=2, `${fin.seg}`);
    }
    /* UN SEGMENT ÉCHU N'ENTRE PAS EN DOUCEUR : l'alarme a sa grammaire, elle PULSE. */
    const du=await page.evaluate(()=>{const t0=Object.values(Runtime.timers)[0];
      t0.elapsedMs=t0.seconds*1000;t0.running=false;t0.ack=false;updateRtStrip(Date.now());
      const d=document.querySelector('#cbTimers .seg.due');
      return {due:!!d,in:d?d.classList.contains('seg-in'):null};});
    t(`${W} · témoin : le minuteur échoit bien`, du.due===true);
    t(`${W} · … et un segment échu n'emprunte pas l'entrée du nominal`, du.in===false);
    await page.close();
  }
});


await sec('v5.6 · l\'index A→Z s\'éclaircit pour rester centré', async () => {
  /* Décision de l'auteur, après mesure : avec un alphabet presque complet sur téléphone, un
     centrage exact est GÉOMÉTRIQUEMENT impossible (la boîte commence sous l'en-tête). L'index
     montre alors moins d'entrées, un « · » remplaçant deux lettres — solution de l'index de
     Contacts d'iOS. Le témoin mesure les trois promesses : centré, cibles intactes, rien de perdu. */
  for(const [W,H,n] of [[390,844,26],[390,844,16],[1280,900,26]]){
    const page=await br.newPage({viewport:{width:W,height:H},hasTouch:W<780});
    page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
    await page.goto(`http://localhost:${port}/index.html`);
    await amorce(page);
    await page.evaluate(async(k)=>{const w=m=>new Promise(r=>setTimeout(r,m));
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').slice(0,k)
        .forEach(x=>fiches.push(migrate({id:uid('f'),title:x+'zz test',blocks:[]})));
      await persist();render();await w(500);},n);
    const r=await page.evaluate(()=>{
      const rail=document.querySelector('.azrail');
      if(!rail||rail.hidden)return {replie:true};
      const tous=[...rail.querySelectorAll('[data-azl]')];
      const vis=tous.filter(b=>!b.hidden);
      const f=vis[0].getBoundingClientRect(),l=vis[vis.length-1].getBoundingClientRect();
      const pts=vis.filter(b=>b.textContent.trim()==='·');
      return {total:tous.length,vis:vis.length,pts:pts.length,
        ecart:Math.round((f.top+l.bottom)/2-document.documentElement.clientHeight/2),
        petits:vis.filter(b=>{const q=b.getBoundingClientRect();return q.height<23.5||q.width<23.5;}).length,
        couvre:pts.every(b=>!!b.dataset.azlDot&&/ ou /.test(b.getAttribute('aria-label')||''))};});
    const tag=`${W}×${H} · ${n} lettres`;
    t(`${tag} · l'index est centré sur l'écran`, Math.abs(r.ecart)<=2, `${r.ecart} px`);
    t(`${tag} · … sans jamais rétrécir une cible sous 24 px`, r.petits===0, `${r.petits} trop petite(s)`);
    /* ⚠ LE TÉMOIN RENCONTRE SON CAS : à 26 lettres sur téléphone il DOIT y avoir des points, et à
       16 (ou en voie large) il ne doit y en avoir AUCUN — sans quoi on mesurerait un rail qui
       s'éclaircit tout le temps, ou jamais. */
    if(W<780&&n===26){
      t(`${tag} · … en éclaircissant l'index`, r.pts>0&&r.vis<r.total, JSON.stringify(r));
      t(`${tag} · … et chaque point dit les deux lettres qu'il porte`, r.couvre===true);
    } else {
      t(`${tag} · … sans éclaircir quand tout tient`, r.pts===0&&r.vis===r.total, JSON.stringify(r));
    }
    await page.close();
  }
});

/* ── « DIAGNOSTIC CONFIRMÉ » PASSE DANS LE JOURNAL, ET N'Y DÉMÉNAGE PAS ────────────────────────
   Le déplacement avait été ANNULÉ une première fois (A107) sur un rouge de 457 px qui s'est révélé
   être un défaut d'INSTRUMENT (A109). Il revient avec ce qui lui manquait : la garantie qu'il ne
   change jamais de place. Trois propriétés, et la deuxième est celle qui l'a fait refuser :
    · avant la session, la condition d'entrée est une CARTE, en tête du flux (A19) ;
    · une fois démarré, elle quitte le flux pour la tête du JOURNAL, et sa position ne bouge pas
      d'un pixel quand la ligne-bilan des blocs faits l'absorbe ;
    · dans le dépliant, c'est UNE RANGÉE comme les blocs, qui déroule ses critères d'un tap. */
await sec('v5.6 · « Diagnostic confirmé » vit dans le journal, en tête', async () => {
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page); await ouvrirFiche(page, /Anaphylaxie/);
  const lire = () => page.evaluate(() => {
    const rl = main.querySelector('.ov-runline'), j = main.querySelector('.ov-journal');
    return { carte: !!main.querySelector('.conf-block.entry'),
      flux: !!main.querySelector('.conf-block:not(.entry)'),
      lbl: rl ? rl.textContent.replace(/\s+/g, ' ').trim() : null,
      enTete: !!(rl && j && j.firstElementChild && j.firstElementChild.contains(rl)),
      y: rl ? Math.round(rl.getBoundingClientRect().top + window.scrollY) : null,
      rangees: [...main.querySelectorAll('.ov-hist .ovh-row:not(.ovh-crit)')].length,
      rangeeConf: [...main.querySelectorAll('.ovh-row')]
        .filter(x => /Diagnostic confirmé/.test(x.textContent)).length,
      crits: main.querySelectorAll('.ovh-crit').length }; });

  const av = await lire();
  t('avant la session : la condition d\'entrée est une carte du flux', av.carte === true && av.lbl === null);

  await demarrerSession(page);
  const d0 = await lire();
  t('démarrée : elle a quitté le flux', d0.flux === false && d0.carte === false);
  t('… et ouvre le journal', d0.enTete === true && /diagnostic confirmé/i.test(d0.lbl || ''), d0.lbl);

  /* Un bloc achevé : la ligne-bilan apparaît et l'ABSORBE — c'est là qu'un déménagement se
     produirait. On mesure la position, pas le libellé. */
  await page.evaluate(async () => { const w = m => new Promise(r => setTimeout(r, m));
    main.querySelectorAll('.ov-block.cur [data-ck]').forEach(e => e.click()); await w(250);
    const n = main.querySelector('[data-ovnext]'); if (n) n.click(); await w(500); });
  const d1 = await lire();
  t('témoin : la ligne-bilan des blocs faits l\'a bien absorbée',
    /blocs? faits?/.test(d1.lbl || '') && /diagnostic confirmé/i.test(d1.lbl || ''), d1.lbl);
  t('… et la ligne n\'a pas déménagé (A107)',
    d1.enTete === true && d1.y != null && Math.abs(d1.y - d0.y) <= 2, `${d0.y} → ${d1.y} px`);

  await page.evaluate(() => main.querySelector('.ov-runline').click());
  await page.waitForTimeout(300);
  const ouv = await lire();
  t('dépliée : une RANGÉE, comme les blocs — pas les critères en vrac',
    ouv.rangeeConf === 1 && ouv.rangees >= 2 && ouv.crits === 0,
    `${ouv.rangeeConf} rangée · ${ouv.crits} critère(s)`);

  await page.evaluate(() => { const r = [...main.querySelectorAll('.ovh-row')]
    .find(x => /Diagnostic confirmé/.test(x.textContent)); if (r) r.click(); });
  await page.waitForTimeout(300);
  const det = await lire();
  t('… et cette rangée déroule ses critères d\'un tap', det.crits >= 2, `${det.crits} critère(s)`);
  await page.close();
});

// ══ P1 (v5.7) — LA BARRE DE RETOUR AU BLOC COURANT ═══════════════════════════
/* Ce que le témoin mesure est la PROPRIÉTÉ, pas le mécanisme : au repos elle n'existe pas ;
   dès que la carte du bloc courant est ENTIÈREMENT hors de la zone utile elle paraît, elle
   nomme sa destination et elle y ramène ; et son apparition ne déplace RIEN (elle est fixe,
   elle ne prend aucune hauteur au flux — c'est ce qui la rend admissible malgré SPEC §5). */
await sec('P1 · le retour au bloc courant', async () => {
  const page=await session(390);
  const vu=()=>page.evaluate(()=>{const b=document.getElementById('blkReturn');
    return !!b&&!b.hidden&&!!b.querySelector('.bkr');});
  const hautCarte=()=>page.evaluate(()=>{const c=document.querySelector('.ov-block.cur,.sv-cell.cur,.nav-wrap');
    return c?Math.round(c.getBoundingClientRect().top):null;});
  await page.waitForTimeout(500);
  t('au repos, la barre n\'existe pas', !(await vu()));
  const yAvant=await page.evaluate(()=>window.scrollY);
  // On descend jusqu'au bout : la carte du bloc courant doit sortir ENTIÈREMENT de la zone utile.
  await page.evaluate(()=>window.scrollTo(0,document.body.scrollHeight));
  await page.waitForTimeout(600);
  /* ⚠ LE PRÉDICAT DU TÉMOIN EST CELUI DE L'APPLICATION, PAS UN AUTRE (leçon A109/4, rejouée
     ici) : la barre se règle sur la zone UTILE — sous les couches collantes, au-dessus du dock —,
     pas sur le rectangle brut de la fenêtre. Mesuré avec `r.bottom<0||r.top>innerHeight`, le
     témoin rougissait sur un comportement juste : la carte était bien hors de la zone utile,
     mais elle dépassait encore derrière le chrome. */
  const dehors=await page.evaluate(()=>{const c=document.querySelector('.ov-block.cur,.sv-cell.cur,.nav-wrap');
    if(!c)return false;const r=c.getBoundingClientRect();
    const cs=getComputedStyle(document.documentElement);
    const haut=parseFloat(cs.getPropertyValue('--stick-top'))||64;
    const bas=innerHeight-((parseFloat(cs.getPropertyValue('--dock-h'))||64)+16);
    return r.bottom<=haut||r.top>=bas;});
  /* ⚠ LE TÉMOIN DOIT RENCONTRER SON CAS : sur une fiche trop courte la carte ne sort jamais de
     l'écran, et « la barre ne paraît pas » serait vrai sans rien prouver. On l'exige d'abord. */
  t('… et le cas est bien rencontré (la carte est hors de vue)', dehors);
  t('défilé loin, la barre paraît', await vu());
  const txt=await page.evaluate(()=>{const b=document.querySelector('.bkr');return b?b.textContent:'';});
  t('… et elle NOMME sa destination', /\S/.test(txt)&&!/^↩\s*$/.test(txt), JSON.stringify(txt));
  /* Elle ne prend aucune hauteur au flux : le contenu ne bouge pas quand elle paraît. */
  const dec=await page.evaluate(()=>{const y=window.scrollY;
    const b=document.getElementById('blkReturn');const av=b.hidden;b.hidden=!av;
    const d=Math.abs(window.scrollY-y);b.hidden=av;return d;});
  t('… et son apparition ne déplace pas le contenu', dec===0, dec+' px');
  /* ⚠ UN TÉMOIN NE DOIT JAMAIS POUVOIR PENDRE (A89) : `page.click('.bkr')` attend 30 s quand la
     barre n'est pas là — c'est-à-dire précisément quand le défaut qu'on couvre est présent — et
     ce blocage emporte la tranche entière, sans un mot. On prend la poignée, on la teste, et
     l'absence devient un ROUGE lisible au lieu d'un timeout. */
  const bkr=await page.$('.bkr');
  if(!bkr){t('un tap ramène la carte sous les couches collantes', false, 'barre absente');
    t('… et la barre s\'efface d\'elle-même une fois revenu', false, 'barre absente');}
  else{
    await bkr.click();
    await page.waitForTimeout(400);
    const h=await hautCarte();
    t('un tap ramène la carte sous les couches collantes', h!==null&&h>0&&h<260, h+' px');
    await page.waitForTimeout(500);
    t('… et la barre s\'efface d\'elle-même une fois revenu', !(await vu()));}
  t('le défilement de départ était bien en haut', yAvant<40, yAvant+' px');
  /* ⚠ ELLE NE CLIGNOTE PAS À CHAQUE RE-RENDU (v5.7, signalé à l'usage). L'observateur restait
     pointé sur l'ANCIENNE carte entre le rendu du journal et le prochain tick — un nœud détaché
     ne coupe aucune zone, donc « hors zone », donc la barre paraissait (mesuré : visible de
     146 à 214 ms) avant d'être reprise. On mesure la PROPRIÉTÉ : la carte étant sous les yeux,
     aucun rendu ne doit rendre la barre visible, fût-ce une image. */
  await page.evaluate(async()=>{const c=document.querySelector('.ov-block.cur');
    if(c){const y=window.scrollY+c.getBoundingClientRect().top-140;window.scrollTo(0,Math.max(0,y));}
    await new Promise(r=>setTimeout(r,500));});
  const clign=await page.evaluate(async()=>{
    const h=document.getElementById('blkReturn');let vues=0;
    const mo=new MutationObserver(()=>{if(!h.hidden)vues++;});
    mo.observe(h,{attributes:true,attributeFilter:['hidden']});
    for(let k=0;k<3;k++){renderOvOnly();await new Promise(r=>setTimeout(r,300));}
    mo.disconnect();
    const c=document.querySelector('.ov-block.cur');const r=c.getBoundingClientRect();
    const d=parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--dock-h'))||64;
    return {vues, dansZone:r.bottom>stickBase()&&r.top<innerHeight-(d+16), fin:!h.hidden};});
  t('témoin : la carte courante est bien SOUS LES YEUX', clign.dansZone===true);
  t('… trois re-rendus ne font pas clignoter la barre', clign.vues===0 && clign.fin===false,
    `${clign.vues} apparition(s)`);
  await page.close();
});

// ══ Q2 (v5.7) — LE RETOUR D'INTERRUPTION ═════════════════════════════════════
/* Le retour au premier plan est un GESTE de l'utilisateur : la ligne a le droit de paraître.
   Ce qu'on mesure : elle ne paraît QUE si l'absence dépasse le seuil d'affichage, elle ne
   déplace pas la page, et elle s'efface au geste suivant — jamais après un délai. */
await sec('Q2 · la reprise après interruption', async () => {
  const page=await session(390);
  const ligne=()=>page.evaluate(()=>{const e=document.getElementById('ovResume');return e?e.textContent:null;});
  const revenir=()=>page.evaluate(()=>document.dispatchEvent(new Event('visibilitychange')));
  await page.waitForTimeout(400);
  // (a) une absence COURTE n'annonce rien : on n'annonce pas quinze secondes.
  await revenir();await page.waitForTimeout(150);
  t('absence courte → aucune ligne', (await ligne())===null);
  // (b) une absence longue : on recule l'horodatage du dernier geste, qui vit dans persistLive.
  const posee=await page.evaluate(()=>{if(typeof Runtime==='undefined')return false;
    Runtime.lastActAt=Date.now()-6*60*1000;return true;});
  t('… le cas est constructible (l\'horodatage du dernier geste est lisible)', posee);
  const yAv=await page.evaluate(()=>window.scrollY);
  await revenir();await page.waitForTimeout(200);
  const txt=await ligne();
  t('absence longue → la ligne paraît', !!txt, String(txt));
  t('… et elle dit DEPUIS COMBIEN DE TEMPS', !!txt&&/il y a\s+\d+:\d\d/.test(txt), String(txt));
  t('… sans déplacer la page', Math.abs((await page.evaluate(()=>window.scrollY))-yAv)<2);
  /* ⚠ ELLE S'EFFACE AU GESTE, JAMAIS APRÈS UN DÉLAI : c'est le geste qui la périme. */
  await page.waitForTimeout(1200);
  t('… et elle ne s\'efface PAS toute seule avec le temps', (await ligne())!==null);
  /* ⚠ QUATRE REPROCHES DE FORME, MESURÉS (v5.7) : la ligne vivait HORS du rembourrage de la
     carte (collée au bord), son nombre était FIGÉ donc faux dès la minute suivante, elle ne
     disait pas d'où elle venait, et son glyphe était le caractère « ⏱ » au lieu d'un tracé. */
  const forme=await page.evaluate(async()=>{
    const e=document.getElementById('ovResume');if(!e)return null;
    const v0=(e.querySelector('.rsm-v')||{}).textContent||'';
    await new Promise(r=>setTimeout(r,2200));
    const x=e.querySelector('.rsm-x'),rx=x?x.getBoundingClientRect():null;
    return {pad:Math.round(parseFloat(getComputedStyle(e).paddingLeft)),
      svg:!!e.querySelector('svg'), litteral:/⏱/.test(e.textContent),
      dit:/interruption/i.test(e.textContent),
      cible:rx?Math.round(Math.min(rx.width+16,rx.height+16)):0,
      v0, v1:(e.querySelector('.rsm-v')||{}).textContent||''};});
  t('… elle vit DANS le rembourrage de la carte, pas contre son bord',
    !!forme&&forme.pad>=14, forme?forme.pad+' px':'absente');
  t('… son glyphe est un TRACÉ (uiIcon), pas le caractère ⏱ (A106)',
    !!forme&&forme.svg===true&&forme.litteral===false);
  t('… elle dit d\'où elle vient', !!forme&&forme.dit===true);
  t('… et son nombre VIT (il ne ment pas à la minute suivante)',
    !!forme&&forme.v0!==''&&forme.v1!==''&&forme.v0!==forme.v1, forme?`${forme.v0} → ${forme.v1}`:'—');
  t('… sa sortie explicite tient la cible de 44 px',
    !!forme&&forme.cible>=44, forme?forme.cible+' px':'—');
  const box=await page.$('.ov-block.cur [data-ck], .nav-wrap [data-ck]');
  if(box){await box.click();await page.waitForTimeout(300);}
  t('… mais elle s\'efface au geste suivant', (await ligne())===null);
  await page.close();
});

// ══ P4b (v5.7) — LE TRI VIVANT DES MINUTEURS, ET SON GARDE ═══════════════════
/* Ce que le témoin mesure : l'ordre suit le temps RESTANT, l'alarme passe devant, et surtout
   RIEN NE BOUGE tant qu'un doigt est posé — puis pendant le délai de grâce. Ce dernier point
   est la moitié qui compte : c'est lui qui empêche la carte qu'on vient de toucher de tomber
   au bas de la liste sous le doigt.
   ⚠ LE DÉCOR A DÛ ÊTRE CONSTRUIT AVANT LE TÉMOIN : le réordonnancement ne s'observe qu'à
   partir de DEUX minuteurs déclarés, et la fiche ACR en porte deux depuis la v5.7. */
await sec('P4b · le tri vivant des minuteurs', async () => {
  const page=await session(1280);
  await page.waitForTimeout(500);
  const ordre=()=>page.evaluate(()=>[...document.querySelectorAll('.tmcard[id^="tmcard-"]')].map(e=>e.id.slice(7)));
  const ids=await ordre();
  t('le cas est rencontré : deux cartes de minuteur', ids.length>=2, ids.length+' carte(s)');
  if(ids.length<2){await page.close();return;}
  /* On fait tourner les deux, le SECOND plus près de son échéance que le premier. */
  const poser=(a,b)=>page.evaluate(([ia,ib])=>{const T=Runtime.timers,n=Date.now();
    T[ia].running=true;T[ia].lastStart=n;T[ia].elapsedMs=0;
    T[ib].running=true;T[ib].lastStart=n;T[ib].elapsedMs=(T[ib].seconds*1000)-8000;
    return true;},[a,b]);
  await poser(ids[0],ids[1]);
  await page.waitForTimeout(900);
  const apres=await ordre();
  t('le plus proche de son échéance remonte en tête', apres[0]===ids[1], apres.join(' , '));
  /* L'IMMINENCE SE VOIT SUR LA CARTE, et pas seulement dans la capsule (marquage, pas aplat). */
  const marque=await page.evaluate(i=>{const c=document.getElementById('tmcard-'+i);
    return c?{soon:c.classList.contains('soon'),al:c.getAttribute('aria-label')||''}:null;},ids[1]);
  t('… et la carte imminente est MARQUÉE', !!marque&&marque.soon);
  t('… avec le mot, jamais la couleur seule', !!marque&&/bient[ôo]t/i.test(marque.al), marque&&marque.al);
  /* ⚠ LE GARDE : doigt posé → rien ne bouge, même si l'ordre devrait changer. */
  const carte=await page.$('#tmcard-'+apres[0]);
  if(!carte){t('le garde : un doigt posé fige la liste', false, 'carte introuvable');}
  else{
    const bb=await carte.boundingBox();
    await page.mouse.move(bb.x+bb.width/2,bb.y+10);
    await page.mouse.down();
    await poser(ids[1],ids[0]);            // on inverse l'urgence pendant que le doigt est posé
    await page.waitForTimeout(900);
    t('le garde : un doigt posé fige la liste', (await ordre())[0]===apres[0], (await ordre()).join(' , '));
    await page.mouse.up();
    /* … puis le DÉLAI DE GRÂCE : la liste attend encore, le temps de lire la réponse de la carte. */
    await page.waitForTimeout(500);
    t('… et le délai de grâce la fige encore juste après le relâchement', (await ordre())[0]===apres[0]);
    await page.waitForTimeout(1500);
    t('… puis l\'ordre se fait, une fois le geste compris', (await ordre())[0]===ids[0], (await ordre()).join(' , '));}
  await page.close();
});

// ══ Q1 (v5.7) — LA RELECTURE PROPOSE, ET LE TAP CRÉE L'OBJET ═════════════════
/* `reviewOffers` a ses 13 témoins purs ; ce qui n'était mesuré par rien, c'est le CÂBLAGE —
   la rangée paraît, son tap passe par `edAdd` avec le `pre` lu dans la phrase de l'auteur, et
   l'objet créé porte la période. Plus la garantie inverse : un refus ne revient pas. */
await sec('Q1 · les propositions de relecture', async () => {
  const page=await br.newPage({viewport:{width:1280,height:900}});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  /* Patron d'audit-k5 : on ouvre l'éditeur sur un brouillon dont le TEXTE porte la cadence —
     c'est le texte de l'auteur qui déclenche, jamais un barème. */
  const ouvrir=(txt,timers)=>page.evaluate(([t0,tm])=>{
    const f=migrate({id:'q1f',v:4,kind:'procedure',title:'Essai',
      items:[{id:'qa',do:t0}],blocks:[{id:'qb',title:'B',kind:'do',items:['qa']}],timers:tm||[]});
    state.view='edit';state.draft=f;render();return true;},[txt,timers]);
  await ouvrir('Analyse du rythme toutes les 3 min');
  await page.waitForTimeout(500);
  const offres=()=>page.evaluate(()=>[...document.querySelectorAll('[data-revoff]')].map(b=>b.dataset.revoff));
  const o=await offres();
  t('le cas est rencontré : le volet porte une proposition', o.indexOf('tm')>=0, o.join(','));
  const btn=await page.$('[data-revoff="tm"]');
  t('… et son bouton dit ce qu\'il crée', !!btn&&/Minuteur/.test((await btn.textContent())||''));
  if(btn){
    await btn.click();await page.waitForTimeout(500);
    const tm=await page.evaluate(()=>((state.draft&&state.draft.timers)||[]).map(x=>({t:x.type,s:x.seconds})));
    t('le tap crée le minuteur', tm.length===1, JSON.stringify(tm));
    /* ⚠ LA PÉRIODE VIENT DE LA PHRASE, PAS D'UN DÉFAUT : 3 min lues dans le texte, pas 120 s. */
    t('… avec la période LUE dans la phrase', tm.length===1&&tm[0].t==='interval'&&tm[0].s===180, JSON.stringify(tm));
    t('… et la proposition se tait ensuite', (await offres()).indexOf('tm')<0);}
  /* Le refus : la proposition s'écarte pour la séance, et rien n'est créé. */
  await ouvrir('Analyse du rythme toutes les 3 min');
  await page.waitForTimeout(400);
  const no=await page.$('[data-revoffno="tm"]');
  t('une proposition écartée est possible', !!no);
  if(no){await no.click();await page.waitForTimeout(400);
    t('… elle ne revient pas de la séance', (await offres()).indexOf('tm')<0);
    t('… et rien n\'a été créé', (await page.evaluate(()=>((state.draft&&state.draft.timers)||[]).length))===0);}
  await page.close();
});

/* ── LES ÉPINGLÉES SUIVENT LE RYTHME DU RÉPERTOIRE ────────────────────────────────────────────
   Signalé à l'usage : « les cartes épinglées prennent toute la largeur de la page — autant en
   mettre plusieurs colonnes quand la largeur le permet ». Leurs rangées vivaient hors du
   `.dir-grid` que porte chaque groupe de lettre : mesuré à 1280 px, 320 px pour une rangée du
   répertoire contre 976 pour une épinglée. On mesure la PROPRIÉTÉ — même largeur de rangée dans
   les deux sections, à toutes les largeurs — et non le nombre de colonnes, qui dépend de la
   grille fluide et n'a pas à être encodé ici. */
await sec('v5.7 · les épinglées ont le rythme du répertoire', async () => {
  const page = await br.newPage({ viewport: { width: 1280, height: 900 } });
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  await page.evaluate(async () => { (fiches || []).slice(0, 2).forEach(f => togglePin(f.id));
    render(); await new Promise(r => setTimeout(r, 400)); });
  for (const w of [390, 1100, 1280, 1600]) {
    await page.setViewportSize({ width: w, height: 900 });
    await page.waitForTimeout(320);
    const r = await page.evaluate(() => {
      const pb = document.querySelector('.dir-book.pinned');
      const nb = [...document.querySelectorAll('.dir-book:not(.pinned)')][0];
      const lg = e => e ? Math.round(e.getBoundingClientRect().width) : 0;
      return { ep: lg(pb && pb.querySelector('.dir-row')), rep: lg(nb && nb.querySelector('.dir-row')),
        livre: lg(pb), n: pb ? pb.querySelectorAll('.dir-row').length : 0 }; });
    t(`${w} px · témoin : les deux sections existent`, r.n >= 2 && r.rep > 0, JSON.stringify(r));
    t(`${w} px · une rangée épinglée a la largeur d'une rangée du répertoire`,
      r.ep > 0 && Math.abs(r.ep - r.rep) <= 2, `${r.ep} px vs ${r.rep} px`);
    if (w >= 1100)
      t(`${w} px · … donc elle ne prend PAS toute la largeur du livre`,
        r.ep < r.livre - 40, `${r.ep} px dans ${r.livre} px`);
  }
  await page.close();
});

// ══ REPRISE APRÈS COMPLICATION — QUEL BLOC EST AU BOUT ? (v5.7) ══════════════
/* Signalé à l'usage : « on tape une complication, on appuie sur reprendre, et on AVANCE d'un
   bloc ; le précédent s'affiche en haut comme un doublon ».
   DEUX LECTURES OPPOSÉES, et le témoin existe pour trancher AVANT qu'on touche au code :
   (a) le second passage du bloc interrompu est VOULU — c'est la doctrine d'interruption
       (AC 120-71B, v4.26.0 : « on re-vérifie après une interruption, l'ancienne carte reste
       lisible juste au-dessus »), et l'ancienne reste ouverte parce qu'un passage INCOMPLET
       n'est jamais une chip. Rien à corriger, seulement à présenter ;
   (b) ou bien `cxResume` redépose sur le bloc SUIVANT, et c'est un défaut net.
   Corriger sans avoir tranché, ce serait risquer d'effacer une trace de soin pour un symptôme
   mal lu — la faute qu'A100, A107 et A113b ont déjà documentée. */
await sec('⚡ la reprise après complication redépose sur le bloc interrompu', async () => {
  const page=await session(390);
  await page.waitForTimeout(400);
  const bout=()=>page.evaluate(()=>{const c=[...document.querySelectorAll('.ov-block[data-ovb]')].pop();
    return c?{id:c.dataset.ovb,ttl:(c.querySelector('.ov-t')||{}).textContent||''}:null;});
  const av=await bout();
  t('le cas est rencontré : un bloc courant existe', !!av, JSON.stringify(av));
  const cx=await page.$('#cxKey');
  t('… et la fiche déclare au moins une complication', !!cx);
  if(!av||!cx){await page.close();return;}
  await cx.click();await page.waitForTimeout(350);
  /* À UNE seule complication, la touche entre directement (v5.0.0/B) ; à plusieurs elle déplie
     l'index. On couvre les deux sans supposer laquelle. */
  const go=await page.$('[data-cxgo]');
  if(go){await go.click();await page.waitForTimeout(400);}
  const pend=await bout();
  t('entrer sur la complication pose un NOUVEAU passage', !!pend&&pend.id!==av.id, JSON.stringify(pend));
  const back=await page.$('[data-cxback]');
  t('… et le retour est proposé (jamais laissé à la mémoire)', !!back);
  if(!back){await page.close();return;}
  await back.click();await page.waitForTimeout(500);
  const ap=await bout();
  /* LE CONTRÔLE QUI TRANCHE : le bout du journal doit être le bloc QU'ON A QUITTÉ, pas le suivant. */
  t('reprendre redépose sur le bloc INTERROMPU, pas sur le suivant',
    !!ap&&ap.id===av.id, 'quitté='+JSON.stringify(av)+' · repris='+JSON.stringify(ap));
  /* Et le second passage est voulu : le bloc interrompu apparaît DEUX fois dans le journal. */
  const n=await page.evaluate(i=>[...document.querySelectorAll('.ov-block[data-ovb]')]
    .filter(c=>c.dataset.ovb===i).length, av.id);
  t('… en postant un second passage, l’ancien restant lisible (doctrine d’interruption)', n>=2, n+' carte(s)');
  /* ⚠ ET LE PASSAGE INTERROMPU EST REPLIÉ : deux cartes OUVERTES du même bloc, l'une au-dessus de
     l'autre avec les mêmes étapes, se lisent comme un doublon. Le repli manuel (autorisé : « repli
     manuel = ligne d'état au maximum ») laisse UNE seule carte ouverte, la neuve. */
  const ouv=await page.evaluate(i=>[...document.querySelectorAll('.ov-block[data-ovb]')]
    .filter(c=>c.dataset.ovb===i&&!c.classList.contains('closed')).length, av.id);
  t('… mais UNE SEULE reste ouverte : l’interrompue se replie', ouv===1, ouv+' ouverte(s)');
  await page.close();
});

// ══ LE VOLET PROLONGE LA CAPSULE — Y COMPRIS EN EXERCICE (v5.7) ══════════════
/* Signalé à l'usage, captures à l'appui. MESURÉ avant correction : en exercice le volet
   recouvrait le quai de 63 px — la capsule disparaissait entièrement sous lui (z 16 contre 15).
   `--stick-top` est une SOMME DE HAUTEURS : elle suppose le quai collé sous l'en-tête, ce qui est
   vrai en crise ordinaire mais FAUX en exercice, où le bandeau survit dans le FLUX et pousse le
   quai vers le bas. Le témoin compare les DEUX modes : le recouvrement doit être le même. */
await sec('⚡ le volet prolonge la capsule, en crise comme en exercice', async () => {
  const geo=async(exo)=>{
    const page=await br.newPage({viewport:{width:390,height:820}});
    await page.goto(`http://localhost:${port}/index.html`);
    await amorce(page);await ouvrirFiche(page,/Arrêt cardiaque/);
    if(exo)await page.evaluate(()=>{const f=state.fiche||(typeof Runtime!=='undefined'&&Runtime.fiche);
      if(typeof startExercise==='function'&&f)startExercise(f);});
    await page.waitForTimeout(250);
    await demarrerSession(page);
    await page.evaluate(()=>{const q=document.getElementById('cbTimers');if(q)q.click();});
    await page.waitForTimeout(450);
    const m=await page.evaluate(()=>{const q=document.getElementById('crisisDock'),v=document.querySelector('.rt-dock');
      if(!q||!v)return null;
      return {rec:Math.round(q.getBoundingClientRect().bottom-v.getBoundingClientRect().top),
        band:!!document.querySelector('#crisisBand:not([hidden])')};});
    await page.close();return m;};
  const a=await geo(false), b=await geo(true);
  t('le cas est rencontré : quai et volet mesurables dans les deux modes', !!a&&!!b, JSON.stringify([a,b]));
  if(!a||!b)return;
  t('… et l\'exercice montre bien son bandeau (sinon le cas n\'existe pas)', b.band===true);
  t('le volet se colle à la capsule en crise', a.rec>=0&&a.rec<=12, a.rec+' px');
  t('… et EXACTEMENT de la même façon en exercice', Math.abs(a.rec-b.rec)<=2, 'crise '+a.rec+' px · exercice '+b.rec+' px');
});

/* ══ A129 — L'ATELIER D'IMPORT : LE GRAIN EST L'ENTITÉ, ET RIEN NE S'ÉCRIT AVANT LE CHOIX ══════
   Ce que la section mesure, et pourquoi chaque contrôle est là :
     · l'atelier PARAÎT et le stockage n'a PAS bougé — c'est la propriété centrale (« avant
       écriture ») et c'est elle qui rend l'import inspectable ;
     · une rangée par entité, aides ET références, avec l'ÉTAT QUE LE FICHIER DÉCLARE — le
       forçage en brouillon est parti, donc l'état affiché est celui qui sera écrit ;
     · la pastille « △ n » n'apparaît QUE là où il reste à relire (même compte que le volet de
       l'éditeur) — une pastille sur toutes les rangées ne dirait plus rien ;
     · une entité décochée n'est écrite NULLE PART, et — c'est le point dur — son binaire PDF
       n'entre pas non plus : `importAtts` ne tourne que sur la liste filtrée.
   POINT D'ENTRÉE RÉEL : `readImportFile` est le seul entonnoir des trois portes (dialogue
   « Créer », dépôt sur la bibliothèque, méthode IA) — elles ne diffèrent que par
   `pendingOpenImport`. On lui donne un VRAI .zip, fabriqué par `zipBuild` (la fonction de
   l'app) : sans binaires dans l'archive, `importAtts` n'aurait rien à écrire et le témoin du
   filtrage ne rencontrerait pas son cas. */
await sec('A129 · l\'atelier d\'import', async () => {
  const page=await br.newPage({viewport:{width:390,height:900}});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  const avant=await page.evaluate(()=>({f:fiches.length,p:protocols.length}));
  await page.evaluate(()=>{
    const pdf=new TextEncoder().encode('%PDF-1.4\ntrailer<</Root 1 0 R>>');
    const doc={version:3,categories:[],fiches:[
      // A — VALIDÉE, deux étapes : aucune remarque de relecture, donc aucune pastille attendue.
      {id:'impa',title:'ATELIER — aide validée',status:'validated',start:'ba',
       docs:[{id:'attimpa',name:'A.pdf',size:pdf.length}],
       blocks:[{id:'ba',kind:'do',title:'Gestes',items:['Un geste','Un autre geste']}]},
      // B — BROUILLON, neuf étapes : `stepGuardTxt` en fait une remarque, donc UNE pastille.
      {id:'impb',title:'ATELIER — aide brouillon',status:'draft',start:'bb',
       docs:[{id:'attimpb',name:'B.pdf',size:pdf.length}],
       blocks:[{id:'bb',kind:'do',title:'Bloc trop long',items:['1','2','3','4','5','6','7','8','9']}]}],
      protocols:[{id:'impc',title:'ATELIER — référence',status:'review',body:'Un texte',sources:['SFAR 2024']}]};
    const zip=zipBuild([{name:'donnees.json',data:new TextEncoder().encode(JSON.stringify(doc))},
      {name:'documents/attimpa.pdf',data:pdf},{name:'documents/attimpb.pdf',data:pdf}]);
    readImportFile(new File([zip],'atelier.zip'));});
  await page.waitForFunction(()=>document.getElementById('impModal').classList.contains('on'),null,{timeout:5000}).catch(()=>{});
  const vu=await page.evaluate(()=>{
    const on=document.getElementById('impModal').classList.contains('on');
    const rows=[...document.querySelectorAll('#impModal .imp-row')].map(r=>({
      t:(r.querySelector('.imp-t')||{}).textContent||'',
      kind:(r.querySelector('.imp-kind')||{}).textContent||'',
      st:(r.querySelector('.status-tag')||{}).textContent||'',
      todo:!!r.querySelector('.tag.todo'),
      key:(r.querySelector('[data-impsel]')||{}).getAttribute?r.querySelector('[data-impsel]').getAttribute('data-impsel'):''}));
    return {on,rows,f:fiches.length,p:protocols.length};});
  t('le cas est rencontré : l\'atelier s\'ouvre sur le .zip',vu.on&&vu.rows.length===3,JSON.stringify(vu.rows));
  if(!vu.on||vu.rows.length!==3){await page.close();return;}
  t('RIEN n\'est écrit tant qu\'on n\'a pas validé',vu.f===avant.f&&vu.p===avant.p,
    `avant ${avant.f}/${avant.p} · pendant ${vu.f}/${vu.p}`);
  t('une rangée par entité — les DEUX natures, nommées',
    vu.rows.filter(r=>/Aide/.test(r.kind)).length===2&&vu.rows.filter(r=>/Référence/.test(r.kind)).length===1,
    JSON.stringify(vu.rows.map(r=>r.kind)));
  t('la rangée dit l\'ÉTAT DÉCLARÉ PAR LE FICHIER, jamais un état forcé',
    /Validée/.test(vu.rows[0].st)&&/Brouillon/.test(vu.rows[1].st),
    JSON.stringify(vu.rows.map(r=>r.st)));
  t('la pastille de relecture ne paraît que là où il reste à relire',
    vu.rows[0].todo===false&&vu.rows[1].todo===true&&vu.rows[2].todo===false,
    JSON.stringify(vu.rows.map(r=>r.todo)));
  // On DÉCOCHE l'aide brouillon — par un vrai clic sur sa case, pas en écrivant dans l'état.
  await page.click(`#impModal [data-impsel="${vu.rows[1].key}"]`);
  const cpt=await page.evaluate(()=>document.getElementById('impN').textContent);
  t('le pied annonce ce qu\'on obtient avant de fermer',/2\s*\/\s*3/.test(cpt),cpt);
  await page.click('#impGo');
  // Une seule question suit (Perso par défaut, donc pas de destination ; 2 éléments -> fusion).
  await page.waitForFunction(()=>document.getElementById('confirmModal').classList.contains('on'),null,{timeout:5000}).catch(()=>{});
  await page.click('#confirmYes');
  await page.waitForFunction(()=>fiches.some(f=>/ATELIER — aide validée/.test(f.title)),null,{timeout:8000}).catch(()=>{});
  const apres=await page.evaluate(async()=>{
    const A=fiches.find(f=>/ATELIER — aide validée/.test(f.title));
    return {a:!!A,statutA:A?A.status:null,
      b:fiches.some(f=>/ATELIER — aide brouillon/.test(f.title)),
      c:protocols.some(p=>/ATELIER — référence/.test(p.title)),
      binA:!!(await IDB.getAtt('attimpa')),binB:!!(await IDB.getAtt('attimpb'))};});
  t('la sélection seule est écrite — l\'entité décochée n\'entre nulle part',
    apres.a&&apres.c&&!apres.b,JSON.stringify(apres));
  t('le FILTRAGE PRÉCÈDE `importAtts` : aucun binaire pour l\'entité décochée',
    apres.binA===true&&apres.binB===false,`coché ${apres.binA} · décoché ${apres.binB}`);
  t('l\'état entrant est PRÉSERVÉ (plus de forçage en brouillon)',apres.statutA==='validated',
    String(apres.statutA));
  await page.close();
});

/* ══ A130 — L'ATELIER, SECOND TOUR : CE QUE LA RANGÉE DIT DE PLUS, ET CE QUE LE FILTRE ATTEINT ══
   Décor DIFFÉRENT de la section A129, et c'est pourquoi il a la sienne : un fichier de MÊME
   ESPACE (empreinte `origin`), portant un identifiant DÉJÀ dans la bibliothèque et deux
   catégories dont une n'appartient qu'à l'entité qu'on va décocher.
     · « ⟳ déjà présent » — la rangée annonce la collision AVANT la question « Doublons », et
       seulement là où elle peut avoir lieu (ids conservés = même espace) ;
     · « n blocs · n minuteurs » — la MÊME phrase que l'écran d'entrée (A118), seule chose qui
       distingue un algorithme complet d'une ébauche sans ouvrir le fichier ;
     · les CATÉGORIES suivent la sélection — le filtrage doit atteindre tout ce qui s'écrit, pas
       seulement les entités ;
     · la question destructive annonce la SÉLECTION, pas « le contenu du fichier » : depuis
       l'atelier, les deux ne sont plus la même chose. */
await sec('A130 · doublons annoncés, catégories filtrées', async () => {
  const page=await br.newPage({viewport:{width:390,height:900}});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  const dejaId=await page.evaluate(()=>fiches[0].id);
  await page.evaluate(id=>{
    const doc={version:3,origin:spaceTag(currentSpace()),
      categories:[{id:'catgardee',name:'Catégorie gardée',color:'#1f5fa6'},
                  {id:'catecartee',name:'Catégorie écartée',color:'#1f5fa6'}],
      fiches:[
        // A — MÊME identifiant qu'une aide déjà présente : la rangée doit l'annoncer. Son
        // horodatage est VOLONTAIREMENT très ancien (A131) : c'est le cas où « remplacer »
        // écraserait une révision locale par une copie périmée — le seul qui prenne l'ambre.
        {id:id,title:'A130 — déjà chez moi',status:'validated',category:'catgardee',start:'ba',
         updatedAt:1,
         timers:[{id:'t1',label:'Adrénaline',type:'interval',seconds:120}],
         blocks:[{id:'ba',kind:'do',title:'Gestes',items:['Un geste','Un autre']},
                 {id:'ba2',kind:'do',title:'Suite',items:['Encore']}]},
        // B — identifiant NEUF, et seule porteuse de la catégorie qu'on va écarter.
        {id:'a130neuve',title:'A130 — jamais vue',status:'draft',category:'catecartee',start:'bb',
         blocks:[{id:'bb',kind:'do',title:'Bloc',items:['Un geste']}]}]};
    readImportFile(new File([JSON.stringify(doc)],'a130.json'));},dejaId);
  await page.waitForFunction(()=>document.getElementById('impModal').classList.contains('on'),null,{timeout:5000}).catch(()=>{});
  const vu=await page.evaluate(()=>({
    on:document.getElementById('impModal').classList.contains('on'),
    rows:[...document.querySelectorAll('#impModal .imp-row')].map(r=>({
      t:(r.querySelector('.imp-t')||{}).textContent||'',
      dup:!!r.querySelector('.imp-dup'),
      rel:(r.querySelector('.imp-rel')||{}).textContent||'',
      relW:!!(r.querySelector('.imp-rel')||{classList:{contains:()=>false}}).classList.contains('warn'),
      relC:r.querySelector('.imp-rel')?getComputedStyle(r.querySelector('.imp-rel')).color:'',
      verify:getComputedStyle(document.documentElement).getPropertyValue('--verify').trim(),
      sub:(r.querySelector('.imp-sub')||{}).textContent||'',
      key:(r.querySelector('[data-impsel]')||{}).getAttribute('data-impsel')}))}));
  t('le cas est rencontré : deux rangées, et la collision est possible (même espace)',
    vu.on&&vu.rows.length===2&&vu.rows.some(r=>r.dup),JSON.stringify(vu.rows.map(r=>[r.t,r.dup])));
  if(!vu.on||vu.rows.length!==2){await page.close();return;}
  t('« déjà présent » sur la rangée qui entre en collision, et sur elle SEULE',
    vu.rows[0].dup===true&&vu.rows[1].dup===false,JSON.stringify(vu.rows.map(r=>r.dup)));
  t('la rangée dit ce que l\'entité EMBARQUE, dans les mots de l\'écran d\'entrée',
    /2 blocs · 1 minuteur/.test(vu.rows[0].sub),vu.rows[0].sub);
  /* A131 — la rangée dit LEQUEL des deux est le plus récent, c'est-à-dire ce que la question
     suivante demande de trancher. Ici le fichier est le plus ANCIEN : « remplacer » perdrait une
     révision locale, donc registre ATTENTION — le glyphe ET le mot, jamais la couleur seule. */
  t('A131 · la rangée dit que MA version est la plus récente',
    /votre version est plus récente/.test(vu.rows[0].rel),JSON.stringify(vu.rows[0].rel));
  t('A131 · … au registre ATTENTION, glyphe compris, et jamais la couleur seule',
    vu.rows[0].relW===true&&/△/.test(vu.rows[0].rel),JSON.stringify([vu.rows[0].relW,vu.rows[0].rel]));
  t('A131 · sans collision possible, aucune relation n\'est annoncée',
    vu.rows[1].rel==='',JSON.stringify(vu.rows[1].rel));
  /* A132 — « Comparer » déplie ce que remplacer changerait.
     ⚠ LA SECONDE ASSERTION EST UN GARDE, ET IL FAUT LE DIRE : « ouvrir ne change pas la
     sélection » est acquis par CONSTRUCTION (un descendant interactif n'active pas son label —
     vérifié sur les deux moteurs en retirant le `preventDefault` que j'avais cru nécessaire :
     témoin resté vert). Elle ne peut donc pas rougir aujourd'hui. On la garde parce qu'elle mesure
     la PROPRIÉTÉ et non le mécanisme : le jour où ce bouton deviendrait un élément non interactif,
     elle serait le seul contrôle à le voir. Celles qui DISCRIMINENT sont les deux autres. */
  const cmpAvant=await page.evaluate(()=>{const b=document.querySelector('#impList [data-impcmp]');
    return b?{existe:true,coche:b.closest('.imp-item').querySelector('[data-impsel]').checked,
      ouvert:!b.closest('.imp-item').querySelector('.imp-diff').hidden}:{existe:false};});
  t('A132 · le cas est rencontré : « Comparer » n\'existe que sur la rangée déjà présente, et replié',
    cmpAvant.existe===true&&cmpAvant.ouvert===false
      &&(await page.evaluate(()=>document.querySelectorAll('#impList [data-impcmp]').length))===1,
    JSON.stringify(cmpAvant));
  if(cmpAvant.existe){
    await page.click('#impList [data-impcmp]');
    await page.waitForTimeout(120);
    const cmp=await page.evaluate(()=>{const it=document.querySelector('#impList .imp-item');
      const d=it.querySelector('.imp-diff');
      return {ouvert:!d.hidden,txt:d.textContent||'',
        // ⚠ ON LIT LES DEUX COLONNES SÉPARÉMENT, jamais le texte du panneau : une première
        // version cherchait le titre entrant « quelque part » — elle restait VERTE quand on
        // INVERSAIT l'orientation, le mot se trouvant alors dans l'autre colonne (mesuré).
        add:[...d.querySelectorAll('.diff-line.add')].map(x=>x.textContent).join(' | '),
        del:[...d.querySelectorAll('.diff-line.del')].map(x=>x.textContent).join(' | '),
        coche:it.querySelector('[data-impsel]').checked,
        lbl:it.querySelector('[data-impcmp]').textContent,
        aria:it.querySelector('[data-impcmp]').getAttribute('aria-expanded')};});
    t('A132 · le dépliant s\'ouvre et dit ce que REMPLACER changerait',
      cmp.ouvert===true&&/Remplacer ajouterait/.test(cmp.txt),
      JSON.stringify({ouvert:cmp.ouvert,tete:cmp.txt.slice(0,60)}));
    /* L'ORIENTATION est la propriété qui compte : ce que le FICHIER apporte est un ajout, ce que
       MA version perdrait est une suppression. Inversées, les deux colonnes existent encore et
       le panneau se lit très bien — c'est le sens qui serait faux. */
    t('A132 · … et dans le bon sens : le titre du FICHIER est un ajout, le mien une suppression',
      /A130 — déjà chez moi/.test(cmp.add)&&!/A130 — déjà chez moi/.test(cmp.del),
      JSON.stringify({add:cmp.add.slice(0,70),del:cmp.del.slice(0,70)}));
    t('A132 · … SANS toucher à la sélection (le bouton vit dans un <label>)',
      cmp.coche===true,String(cmp.coche));
    t('A132 · … et le bouton dit désormais ce qu\'il fera',
      cmp.lbl==='Masquer'&&cmp.aria==='true',JSON.stringify([cmp.lbl,cmp.aria]));}
  // On décoche la neuve — donc la seule qui porte « catecartee ».
  await page.click(`#impModal [data-impsel="${vu.rows[1].key}"]`);
  await page.click('#impGo');
  await page.waitForFunction(()=>document.getElementById('confirmModal').classList.contains('on'),null,{timeout:5000}).catch(()=>{});
  /* La question de fusion n'est posée qu'au-delà d'un élément : à UNE sélection, on tombe
     directement sur « Doublons ». On lit donc le titre pour savoir où l'on est. */
  const q1=await page.evaluate(()=>({titre:document.getElementById('confirmModalTitle').textContent,
    msg:document.getElementById('confirmMsg').textContent}));
  t('la question suivante est bien « Doublons », et elle NOMME la collision',
    /Doublon/i.test(q1.titre)&&/déjà présent/i.test(q1.msg),JSON.stringify(q1));
  await page.click('#confirmYes');   // remplacer l'existante
  await page.waitForFunction(()=>fiches.some(f=>/A130 — déjà chez moi/.test(f.title)),null,{timeout:8000}).catch(()=>{});
  const apres=await page.evaluate(()=>({
    a:fiches.some(f=>/A130 — déjà chez moi/.test(f.title)),
    b:fiches.some(f=>/A130 — jamais vue/.test(f.title)),
    gardee:categories.some(c=>c.id==='catgardee'),
    ecartee:categories.some(c=>c.id==='catecartee')}));
  t('la sélection seule est écrite',apres.a&&!apres.b,JSON.stringify(apres));
  t('LES CATÉGORIES SUIVENT LA SÉLECTION — aucune catégorie orpheline créée par une entité décochée',
    apres.gardee===true&&apres.ecartee===false,JSON.stringify(apres));
  await page.close();
});
/* La question destructive annonce ce qu'on a COCHÉ. Mesurée à part, sur un décor neuf : elle
   n'apparaît qu'à deux éléments ou plus, et l'on en sort par « Annuler » — on lit le texte,
   on ne vide pas la bibliothèque pour vérifier une phrase. */
await sec('A130 · « remplacer » annonce la sélection, pas le fichier', async () => {
  const page=await br.newPage({viewport:{width:390,height:900}});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  await page.evaluate(()=>{
    const f=n=>({id:'a130w'+n,title:'A130 — lot '+n,status:'draft',start:'b'+n,
      blocks:[{id:'b'+n,kind:'do',title:'Bloc',items:['Un geste']}]});
    readImportFile(new File([JSON.stringify({version:3,categories:[],fiches:[f(1),f(2),f(3)]})],'a130w.json'));});
  await page.waitForFunction(()=>document.getElementById('impModal').classList.contains('on'),null,{timeout:5000}).catch(()=>{});
  const k=await page.evaluate(()=>{const r=document.querySelectorAll('#impModal .imp-row');
    return r.length===3?r[2].querySelector('[data-impsel]').getAttribute('data-impsel'):null;});
  t('le cas est rencontré : trois rangées à l\'atelier',!!k);
  if(!k){await page.close();return;}
  await page.click(`#impModal [data-impsel="${k}"]`);   // 2 cochées sur 3
  await page.click('#impGo');
  await page.waitForFunction(()=>document.getElementById('confirmModal').classList.contains('on'),null,{timeout:5000}).catch(()=>{});
  const q=await page.evaluate(()=>document.getElementById('confirmMsg').textContent);
  t('la question de fusion compte la SÉLECTION',/2 éléments/.test(q),q);
  await page.click('#confirmNo');    // « REMPLACER » -> la confirmation destructive
  await page.waitForTimeout(300);
  const d=await page.evaluate(()=>({titre:document.getElementById('confirmModalTitle').textContent,
    msg:document.getElementById('confirmMsg').textContent}));
  t('la confirmation destructive annonce « les 2 éléments cochés », jamais « le contenu du fichier »',
    /Remplacer la biblioth/i.test(d.titre)&&/2 éléments cochés/.test(d.msg)&&!/contenu du fichier/.test(d.msg),
    JSON.stringify(d));
  await page.click('#confirmNo');    // on n'écrase rien : l'import est abandonné
  await page.waitForTimeout(400);
  const rien=await page.evaluate(()=>fiches.filter(f=>/A130 — lot/.test(f.title)).length);
  t('… et refuser la remplace n\'écrit rien du tout',rien===0,String(rien));
  await page.close();
});
/* ══ A131 — SANS HORODATAGE, LA RANGÉE SE TAIT ═════════════════════════════════════════════════
   Le piège que ce lot pouvait manquer, et il est INVISIBLE au témoin de la section A130 : c'est
   `migrate` lui-même qui POSE un `updatedAt` quand le fichier n'en porte pas, et son dernier
   recours est `Date.now()`. Un fichier ancien serait donc daté de l'INSTANT DE L'IMPORT, donc
   annoncé « plus récent » que tout ce qu'on possède — un mensonge, sur la seule question
   destructive du parcours. La sonde exige donc le silence là où l'on ne sait pas.
   SECTION À PART, et sa manœuvre le justifie : elle se termine par ANNULER, alors que la section
   A130 va jusqu'à l'écriture. On ne fusionne pas deux verdicts qui ne finissent pas au même
   endroit (« une section est une UNITÉ DE VERDICT »). */
await sec('A131 · sans horodatage, la rangée se tait', async () => {
  const page=await br.newPage({viewport:{width:390,height:900}});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  const dejaId=await page.evaluate(()=>fiches[0].id);
  await page.evaluate(id=>{
    // Même espace (donc collision possible) et AUCUN `updatedAt` : le cas exact du fichier ancien.
    const doc={version:3,origin:spaceTag(currentSpace()),categories:[],
      fiches:[{id:id,title:'A131 — sans horodatage',status:'draft',start:'bz',
        blocks:[{id:'bz',kind:'do',title:'Bloc',items:['Un geste']}]}]};
    readImportFile(new File([JSON.stringify(doc)],'a131.json'));},dejaId);
  await page.waitForFunction(()=>document.getElementById('impModal').classList.contains('on'),null,{timeout:5000}).catch(()=>{});
  const vu=await page.evaluate(()=>{const r=document.querySelector('#impModal .imp-row');
    return r?{dup:!!r.querySelector('.imp-dup'),rel:(r.querySelector('.imp-rel')||{}).textContent||''}:null;});
  // ON RENCONTRE SON CAS D'ABORD : sans collision annoncée, l'absence de relation ne prouverait
  // rien — elle serait absente parce qu'il n'y a rien à comparer.
  t('le cas est rencontré : la collision EST annoncée',!!vu&&vu.dup===true,JSON.stringify(vu));
  if(vu&&vu.dup)t('A131 · … et AUCUNE relation n\'est inventée à partir d\'un horodatage absent',
    vu.rel==='',JSON.stringify(vu.rel));
  await page.click('#impCancel');
  await page.waitForTimeout(300);
  const rien=await page.evaluate(()=>fiches.some(f=>/A131 — sans horodatage/.test(f.title)));
  t('annuler l\'atelier n\'écrit rien',rien===false,String(rien));
  await page.close();
});

/* ═══ « TOUT VOIR » EST UNE EXCURSION : ELLE REVIENT OÙ L'ON ÉTAIT ═══════════════════════════
   Signalé à l'usage (audit externe v5.10.0) : « quand je sors du mode tout voir mon scroll est
   tout en bas — il devrait être sauvegardé à la dernière position où j'étais », puis « si quelqu'un
   dans une session partagée a continué à cocher pendant que j'y étais, la longueur de page change,
   que je ne me retrouve pas tout en bas ».
   Deux propriétés, et la seconde est celle qui discrimine : (1) le retour repose où l'on est parti,
   pas où l'excursion s'est terminée ; (2) il le fait par une ANCRE — le bloc qu'on regardait, à son
   décalage d'écran — donc il survit à un document qui a changé de longueur pendant l'excursion.
   Un `scrollY` brut satisferait (1) et échouerait (2), et c'est exactement le régime où le
   navigateur RABAT au maximum (A46, A109), c'est-à-dire le défaut par une autre porte. */
await sec('EXCURSION · « Tout voir » revient où l’on était', async () => {
  const page = await br.newPage({viewport:{width:390,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r=await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const f=fiches.find(x=>/Arrêt cardiaque/i.test(x.title))||fiches[0];
    openRead(f.id);await w(500);
    document.getElementById('sessStart').click();await w(800);
    const vu=()=>{const b=[...document.querySelectorAll('[data-ovb]')]
      .find(e=>e.getBoundingClientRect().bottom>stickBase()+2);
      return b?{id:b.dataset.ovb,top:Math.round(b.getBoundingClientRect().top)}:null;};
    window.scrollTo(0,300);await w(300);
    const avant={y:Math.round(scrollY),vu:vu(),h:document.documentElement.scrollHeight};
    document.getElementById('allBtn').click();await w(700);
    /* On va AU BOUT de l'excursion : c'est la position qui produisait le défaut, et sans elle le
       contrôle resterait vert (partir et revenir sans bouger ne discrimine rien). */
    window.scrollTo(0,document.documentElement.scrollHeight);await w(400);
    const bout=Math.round(scrollY);
    /* LE COLLÈGUE AVANCE PENDANT L'EXCURSION — c'est le cas qui distingue une ANCRE d'un nombre.
       On passe par l'ÉTAT et non par le DOM : la vue « Tout voir » est inerte, et un lot distant
       n'y touche pas davantage. */
    const b0=Runtime.nav[state.navPos];
    const bloc=Runtime.fiche.blocks.find(x=>x.id===b0)||{};
    (stepsOf(bloc)||[]).forEach((_,i)=>{state.checked[state.navPos+':'+b0+':'+i]=true;});
    if(bloc.next){Runtime.nav.push(bloc.next);state.navPos=Runtime.nav.length-1;}
    await w(200);
    document.getElementById('allBtn').click();await w(900);
    const apres={y:Math.round(scrollY),vu:vu(),h:document.documentElement.scrollHeight,
      max:Math.round(document.documentElement.scrollHeight-innerHeight)};
    return {avant,bout,apres};});
  // LE CAS EST RENCONTRÉ : on était bien parti d'ailleurs que du bout, on a bien atteint le bout,
  // et le document a bien changé de longueur pendant l'excursion.
  t('le cas est rencontré : l’excursion s’est terminée AU BOUT, loin du point de départ',
    r.bout>r.avant.y+100, `${r.avant.y} → ${r.bout}`);
  t('… et la page a bien changé de longueur pendant l’excursion',
    r.apres.h!==r.avant.h, `${r.avant.h} → ${r.apres.h} px`);
  t('le retour ne dépose PAS à la borne du défilement',
    r.apres.y<r.apres.max-40, `y=${r.apres.y} pour un max de ${r.apres.max}`);
  // LA PROPRIÉTÉ, ET NON LE MÉCANISME : c'est le bloc REGARDÉ qui revient à sa place, à quelques
  // pixels près — un `scrollY` brut le raterait dès que la page change de longueur au-dessus.
  t('… et il repose le bloc qu’on regardait à son décalage d’écran',
    !!r.avant.vu&&!!r.apres.vu&&r.apres.vu.id===r.avant.vu.id&&Math.abs(r.apres.vu.top-r.avant.vu.top)<=8,
    JSON.stringify({avant:r.avant.vu,apres:r.apres.vu}));
  await page.close();
});

/* ═══ UN FILTRE QUI NE FILTRE RIEN N'EST PAS UN FILTRE ═══════════════════════════════════════
   Sur une installation neuve, le rail de l'accueil affichait NEUF catégories dont SIX à zéro. Deux
   propriétés, et la seconde est un GARDE au sens d'A132 — il ne peut pas rougir aujourd'hui par un
   chemin d'interface (basculer le type remet `state.cat` à null), mais il mesure la PROPRIÉTÉ qui
   compte : un filtre posé ne devient jamais invisible, quelle que soit la façon dont son compte
   tombe à zéro (suppression de la dernière fiche, pull de synchro). */
await sec('ACCUEIL · les catégories vides ne mènent nulle part', async () => {
  const page = await br.newPage({viewport:{width:1280,height:900}});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r=await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const lire=()=>[...document.querySelectorAll('.home-side .hs-row[data-cat]')].map(b=>({
      id:b.dataset.cat,n:b.querySelector('.hs-name').textContent,
      c:b.querySelector('.hs-n').textContent,on:b.classList.contains('on')}));
    state.view='library';state.cat=null;render();await w(400);
    const nominal=lire();
    const tous=categories.length;
    const vides=categories.filter(c=>!fiches.concat(protocols).some(x=>x.category===c.id));
    /* LE CAS DU GARDE : une catégorie SÉLECTIONNÉE dont le compte est à zéro. */
    state.cat=vides.length?vides[0].id:null;render();await w(400);
    const selVide=lire();
    state.cat=null;render();await w(200);
    return {tous,nVides:vides.length,nominal,selVide,videId:vides.length?vides[0].id:null};});
  // ON RENCONTRE SON CAS : sans catégorie vide au départ, l'absence de rangée ne prouverait rien.
  t('le cas est rencontré : des catégories sont vides sur une installation neuve',
    r.nVides>=1, `${r.nVides} vide(s) sur ${r.tous}`);
  t('aucune catégorie à zéro dans le rail',
    r.nominal.filter(x=>x.id&&x.c==='0').length===0, JSON.stringify(r.nominal.map(x=>x.n+':'+x.c)));
  t('… et les non vides sont TOUTES là',
    r.nominal.filter(x=>x.id).length===r.tous-r.nVides, `${r.nominal.filter(x=>x.id).length} sur ${r.tous-r.nVides}`);
  // GARDE (A132) : il ne discrimine pas aujourd'hui, il tient la propriété.
  t('GARDE · une catégorie SÉLECTIONNÉE reste visible même à zéro',
    !!r.videId&&r.selVide.some(x=>x.id===r.videId&&x.on&&x.c==='0'),
    JSON.stringify(r.selVide.filter(x=>x.on)));
  await page.close();
});

/* ══ LA PORTE « ＋ » DE L'ÉDITEUR AMÈNE SUR CE QU'ELLE CRÉE (v5.10.8) ═══════════════════════════
   CETTE SECTION EXISTE PARCE QUE RIEN NE REGARDAIT CE CHEMIN. Signalé à l'usage : « en mode
   édition, quand on clique sur ajouter (étape, chronomètre, minuteur, compteur…) le scroll ne
   descend pas jusqu'à la case qui vient d'être créée ». Le geste défilait correctement, puis
   `_bgUnlock` — appelé une MICRO-TÂCHE plus tard par l'observateur de fenêtres — restaurait la
   position d'avant l'ouverture de la palette et l'annulait. Aucune porte ne l'a vu : `check-*` est
   statique, `tests.html` n'exerce que des fonctions PURES, et aucun des vingt harnais n'ouvrait
   cette palette. Pire, pendant le correctif une `ReferenceError` a vécu dans `edAdd` en laissant
   toute la passe VERTE — d'où le `pageerror` ci-dessous, qui l'aurait attrapée seul.
   ⚠ ELLE MESURE EN POINTEUR GROSSIER, ET C'EST TOUT LE SUJET. La restauration fautive était gardée
   par `matchMedia('(pointer:coarse)')` : sur ordinateur le défilement tenait, le défaut n'existait
   QUE sur téléphone et tablette — invisible partout où l'on développe, systématique partout où
   l'on soigne. Un témoin vérifie donc d'abord que le régime tactile est bien émulé : sans lui, la
   sonde mesurerait un contexte où le défaut ne peut pas se produire, et son vert ne vaudrait rien.
   ⚠ ET ELLE MESURE `haut ≈ --stick-top`, PAS « visible ». Le second défaut, trouvé à la question
   « le scroll peut-il afficher le début du bloc en haut ? », était un `block:'center'` qui centre
   la boîte sans rien savoir des couches collantes : à 844 le titre d'un bloc neuf tombait à 181
   (visible, mais 120 px de vide au-dessus), à 667 il tombait à 40, DERRIÈRE un en-tête de 61. Un
   témoin « l'objet est visible » aurait été vert dans les deux cas. On mesure donc l'ancrage.
   ⚠ ENFIN, LES LISTES GARDENT LEUR CENTRAGE, et le témoin le TIENT plutôt qu'il ne le constate :
   une dose est une ligne de 44 px dont le sens vient du titre de section au-dessus d'elle.
   L'ancrer en haut la collerait sous l'en-tête et pousserait sa section hors de l'écran. */
await sec('ÉDITEUR · la porte « ＋ » amène sur ce qu\'elle crée', async () => {
for (const H of [844, 667]) {
  const page = await br.newPage({viewport:{width:390,height:H},hasTouch:true,isMobile:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(()=>!document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async()=>{const w=m=>new Promise(r=>setTimeout(r,m));
    const f=fiches.find(x=>/cardiaque/i.test(x.title))||fiches[0];
    /* LE VRAI POINT D'ENTRÉE (doctrine v4.40.0) : `openEdit` pose le brouillon, la sauvegarde de
       version et l'état de restauration — un `state.view='edit'` à la main sauterait tout cela. */
    await openEdit(f.id);await w(500);
    const stick=Math.round(parseFloat(getComputedStyle(document.documentElement)
      .getPropertyValue('--stick-top'))||0);
    const out={coarse:matchMedia('(pointer:coarse)').matches,stick,vh:innerHeight,cas:{}};
    const ouvrir=async kind=>{
      window.scrollTo(0,1200);await w(150);
      const porte=document.getElementById('edAddOpen');if(!porte)return null;
      porte.click();await w(300);
      const row=[...document.querySelectorAll('[data-edadd]')].find(b=>b.dataset.edadd===kind);
      if(!row)return null;
      row.click();await w(400);return true;};
    /* OBJETS À TÊTE PROPRE : on exige l'ANCRAGE (haut ≈ --stick-top), pas la visibilité. */
    for(const [kind,sel] of [['steps','.blk'],['decision','.blk.blk-dec'],
        ['interval','.tmedit[data-ti]'],['counter','.tmedit[data-ci]'],['cx','.cx-edit-row']]){
      const n0=document.querySelectorAll(sel).length;
      if(!await ouvrir(kind)){out.cas[kind]={absent:true};continue;}
      const l=[...document.querySelectorAll(sel)];const c=l[l.length-1];
      const bb=c.getBoundingClientRect();
      out.cas[kind]={cree:l.length>n0,haut:Math.round(bb.top),
        focusDedans:c.contains(document.activeElement)};}
    /* LIGNE DE LISTE : on exige le CENTRAGE — la ligne visible ET son titre de section avec elle. */
    for(const [kind,key] of [['poso','posology']]){
      const n0=document.querySelectorAll('[data-key="'+key+'"]').length;
      if(!await ouvrir(kind)){out.cas[kind]={absent:true};continue;}
      const l=[...document.querySelectorAll('[data-key="'+key+'"]')];const c=l[l.length-1];
      const bb=c.getBoundingClientRect();
      const fs=c.closest('.list-edit');const lab=fs?fs.querySelector('label'):null;
      const lb=lab?lab.getBoundingClientRect():null;
      out.cas[kind]={cree:l.length>n0,haut:Math.round(bb.top),
        focus:c===document.activeElement,
        ligneVisible:bb.top>=0&&bb.bottom<=innerHeight,
        titreSection:!!lb&&lb.top>=0&&lb.bottom<=innerHeight};}
    return out;});
  const P=`${H}`;
  // TÉMOIN : sans pointeur grossier, le défaut d'origine ne peut PAS se produire — un vert
  // obtenu ici ne prouverait rien. Il échoue bruyamment plutôt que de rassurer à tort.
  t(`${P} · témoin : le régime TACTILE est bien émulé (pointer:coarse)`, r.coarse===true);
  t(`${P} · témoin : les couches collantes sont mesurées`, r.stick>0, `--stick-top = ${r.stick}`);
  for(const k of ['steps','decision','interval','counter','cx']){
    const c=r.cas[k]||{};
    t(`${P} · « ${k} » : l'objet est bien créé`, c.cree===true, JSON.stringify(c));
    // ANCRÉ EN HAUT : sous les couches collantes, et pas 120 px plus bas non plus.
    t(`${P} · « ${k} » : son DÉBUT se pose sous les couches collantes`,
      typeof c.haut==='number'&&c.haut>=r.stick&&c.haut<=r.stick+24,
      `haut = ${c.haut} px (attendu entre ${r.stick} et ${r.stick+24})`);
    t(`${P} · « ${k} » : le focus est DANS l'objet créé`, c.focusDedans===true);}
  {const c=r.cas.poso||{};
   t(`${P} · « poso » : la ligne est bien créée`, c.cree===true, JSON.stringify(c));
   t(`${P} · « poso » : la ligne est visible ET focalisée`,
     c.ligneVisible===true&&c.focus===true, JSON.stringify(c));
   t(`${P} · « poso » : son TITRE DE SECTION reste à l'écran (centrage tenu)`,
     c.titreSection===true, `haut de ligne = ${c.haut} px`);}
  await page.close();
}
});

/* ══ PLANCHE 20 — LA BARRE DE SÉLECTION : UNE LIGNE, 56 px, TOUJOURS ════════════════════════
   Le témoin de la consigne 9, et il mesure la contrainte ELLE-MÊME plutôt qu'une mise en page :
   `offsetHeight === 56` à 320, 390, 560 et 1280 px, à zéro comme à plusieurs cochés. Trois
   mesures l'accompagnent, parce qu'une hauteur juste ne prouve pas une ligne juste — une barre
   peut tenir 56 px en ROGNANT son contenu, et c'est précisément le défaut silencieux que ce
   dépôt s'interdit (ECAM) :
     · aucun débordement horizontal (`scrollWidth <= clientWidth`) ;
     · un SEUL rang (tous les objets visibles centrés sur la même bande) ;
     · le COMPTE jamais tronqué — c'est l'état de la sélection, et il est le seul élément
       élastique : tout ce qui manque à la ligne se prend sur lui.
   ⚠ LE PALIER SE FRANCHIT RÉELLEMENT : sans la vérification « déplié à 1280, replié en dessous »,
   un vert ne dirait que « la barre tient », y compris si elle tenait en n'affichant jamais ses
   actes. On mesure donc AUSSI ce qui est sur la ligne de part et d'autre de 1200 px. */
await sec('SÉLECTION · une ligne, 56 px, à tout écran et dans tout état (planche 20)', async () => {
for (const W of [320, 390, 560, 744, 1200, 1280]) {
  const page = await br.newPage({viewport:{width:W,height:844},hasTouch:true});
  page.on('pageerror',e=>{ko++;console.log('  ✗ ERREUR PAGE : '+e.message);});
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  const r = await page.evaluate(async () => {
    const w=ms=>new Promise(r=>setTimeout(r,ms));
    const mes=()=>{const b=document.querySelector('.sel-bar');if(!b)return null;
      /* `display:contents` n'a pas de boîte : ses ENFANTS sont les objets de la ligne. */
      const kids=[...b.children]
        .flatMap(k=>getComputedStyle(k).display==='contents'?[...k.children]:[k])
        .filter(k=>getComputedStyle(k).display!=='none');
      const n=document.getElementById('selN');
      const centres=kids.map(k=>{const q=k.getBoundingClientRect();return q.top+q.height/2;});
      return {h:b.offsetHeight, over:b.scrollWidth-b.clientWidth,
        rangs:Math.round(Math.max(...centres)-Math.min(...centres)),
        cptTronq:n.scrollWidth>n.clientWidth+1, cpt:n.textContent,
        cible:Math.min(...kids.filter(k=>k.tagName==='BUTTON').map(k=>k.offsetHeight)),
        ids:kids.map(k=>k.id||k.className).join(' ')};};
    const out={};
    document.getElementById('selTog').click(); await w(300);
    out.zero=mes();
    let c; while((c=[...document.querySelectorAll('[data-selid]')].filter(x=>x.getAttribute('aria-checked')!=='true')[0])){c.click();await w(150);}
    out.n=selEnt().length;
    out.plein=mes();
    return out;});
  const P=`${W}px`;
  for (const [etat,m] of [['0 coché',r.zero],[r.n+' cochés',r.plein]]) {
    t(`${P} · ${etat} : la barre mesure exactement 56 px`, m.h===56, `offsetHeight = ${m.h}`);
    t(`${P} · ${etat} : aucun débordement horizontal`, m.over<=0, `scrollWidth - clientWidth = ${m.over}`);
    // Les objets n'ont pas la même hauteur (le compte est un span) : on compare leurs CENTRES.
    t(`${P} · ${etat} : un seul rang`, m.rangs<=1, `écart des centres = ${m.rangs} px — ${m.ids}`);
    t(`${P} · ${etat} : le compte n'est pas tronqué`, m.cptTronq===false, `« ${m.cpt} »`);
    t(`${P} · ${etat} : cibles ≥ 40 px (règle 9, plancher hors crise relevé par la planche)`,
      m.cible>=40, `plus petite = ${m.cible} px`);
  }
  // À zéro coché, RIEN DE MORT : la touche d'actes n'existe pas, elle n'est pas grisée.
  t(`${P} · 0 coché : la touche d'actes n'est pas rendue`, !/selDo/.test(r.zero.ids), r.zero.ids);
  // Le palier de dépliage (1200 px EFFECTIFS, cf. .sel-bar) se franchit réellement.
  const deplie=/selLib/.test(r.plein.ids)&&/selCat/.test(r.plein.ids)&&/selDel/.test(r.plein.ids);
  const tiroir=/selDo/.test(r.plein.ids);
  if (W>=1200) t(`${P} · déplié : les trois actes sont SUR la ligne, pas de touche d'actes`,
    deplie&&!tiroir, r.plein.ids);
  else t(`${P} · replié : une touche d'actes, aucun acte sur la ligne`,
    tiroir&&!deplie, r.plein.ids);
  await page.close();
}
});

const bilanSec=sec.bilan();
await br.close();srv.close();


console.log(`\n${ok}/${ok+ko} contrôles doctrine OK${ko?` — ${ko} ÉCHEC(S)`:''}${bilanSec.partiel?` — PARTIEL (${bilanSec.joues}/${bilanSec.total} sections)`:''}`);
process.exit(ko?1:0);
