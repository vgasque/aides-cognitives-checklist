/* AUDIT — PROMPT IA (v4.73.0). Le prompt embarqué PROMET un format ; rien ne vérifiait que
   l'application l'accepte, ni que le gabarit qu'il montre soit lui-même correct.
   IL NE L'ÉTAIT PAS : le `\n` de `localInfo` vivait dans un littéral gabarit (backticks), donc
   JavaScript le transformait en VRAI saut de ligne — le JSON d'exemple affiché à l'IA contenait
   une chaîne coupée par une fin de ligne, ce qui est invalide. Une IA qui recopie fidèlement ce
   qu'on lui montre produisait alors un fichier que l'import refuse, et la faute paraissait
   venir d'elle. Il faut `\\n` dans la source pour afficher `\n`.
   Ce harnais EXTRAIT le schéma du prompt lui-même, le parse, le passe par `migrate()` et vérifie
   qu'aucun champ ne tombe — puis que le prompt dit bien les trois choses que la v4.73.0 y ajoute
   (l'effet visuel de « :: », les budgets de longueur chiffrés, `discriminant` et `onDue`).
   Il est PUR : aucun rendu, aucun clic — il mesure un contrat, pas un écran. */
import { serveApp, moteur } from './harness.mjs';
const {port,srv}=await serveApp(); const br=await moteur().launch();
const p=await br.newPage();
let ok=0,ko=0;const t=(n,c,d)=>{if(c){ok++;console.log('  ✓ '+n);}else{ko++;console.log('  ✗ '+n+(d?' — '+d:''));}};
await p.goto(`http://localhost:${port}/index.html?__actest`);
await p.waitForFunction(()=>!!window.__ac_test__);
const r=await p.evaluate(()=>{
  const A=window.__ac_test__;
  const P=A.AI_PROMPT;
  // On EXTRAIT le schéma du prompt lui-même : c'est la promesse faite à l'IA.
  const i=P.indexOf('SCHÉMA EXACT'), j=P.indexOf('VALEURS AUTORISÉES');
  let bloc=P.slice(i,j); bloc=bloc.slice(bloc.indexOf('{'), bloc.lastIndexOf('}')+1);
  // les « ... » du gabarit deviennent du contenu plausible
  bloc=bloc.replace(/"\.\.\."/g,'"ligne"').replace(/"\.\.\.\?"/g,'"Question ?"');
  let obj=null,err=null; try{obj=JSON.parse(bloc);}catch(e){err=String(e);}
  if(!obj)return {parse:false,err,extrait:bloc.slice(0,200)};
  const f=A.migrate(JSON.parse(JSON.stringify(obj.fiches[0])));
  const cx=(f.complications||[]);
  return {parse:true, disc:f.discriminant, onDue:(f.timers[0]||{}).onDue,
    titre:f.title, statut:f.status, valid:f.validation,
    blocs:f.blocks.length, start:f.start,
    cxOk:cx.length===1&&cx[0].target==='cx1',
    cibles:f.blocks.filter(b=>b.type==='decision').flatMap(b=>b.options.map(o=>o.target))
      .every(id=>f.blocks.some(b=>b.id===id)),
    nexts:f.blocks.filter(b=>b.type==='steps').every(b=>b.next===null||f.blocks.some(x=>x.id===b.next)),
    poso:(f.posology||[]).length, promptLen:P.length,
    ditBulle:/en GRIS, dans une BULLE/.test(P), ditBudget:/BUDGETS/.test(P),
    ditPeuTexte:/PEU DE TEXTE/.test(P), ditDisc:/"discriminant"/.test(P), ditOnDue:/"onDue"/.test(P),
    /* v4.77.0 — les libellés de minuteurs et de compteurs ne servent pas qu'À L'INSTANT : ils
       nomment les repères du JOURNAL DES ACTIONS et les compteurs du COMPTE-RENDU, relus hors
       contexte et parfois par quelqu'un qui n'était pas là. Une IA qui l'ignore produit
       « Compteur 1 » ou une phrase, et le débriefing hérite du bruit. */
    ditJournal:/JOURNAL DES ACTIONS/.test(P)&&/COMPTE-RENDU/.test(P)};});
t('le schéma du prompt est un JSON valide', r.parse===true, r.err||r.extrait);
if(r.parse){
  t('migrate() conserve "discriminant"', r.disc==='adulte', JSON.stringify(r.disc));
  t('migrate() conserve "onDue"', /Analyse du rythme/.test(r.onDue||''), JSON.stringify(r.onDue));
  t('le titre ne porte plus la population', r.titre==='Situation', r.titre);
  t('arrive en BROUILLON non daté', r.statut==='draft'&&r.valid==='', r.statut+'/'+r.valid);
  t('tous les "target" de décision existent', r.cibles===true);
  t('tous les "next" existent ou sont null', r.nexts===true);
  t('la complication vise un bloc hors chaîne', r.cxOk===true);
  t('les repères posologiques passent', r.poso===2, ''+r.poso);
  t('le prompt EXPLIQUE l’effet visuel de « :: »', r.ditBulle===true);
  t('… énonce des budgets de longueur chiffrés', r.ditBudget&&r.ditPeuTexte);
  t('… documente "discriminant" et "onDue"', r.ditDisc&&r.ditOnDue);

  t('… dit que les libellés de minuteurs/compteurs se relisent APRÈS le soin', r.ditJournal===true);
  console.log('  · longueur du prompt : '+r.promptLen+' caractères');
}
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);
await br.close();srv.close();process.exit(ko?1:0);
