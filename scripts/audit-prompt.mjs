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
  const cx=(f.excursions||[]);
  return {parse:true, disc:f.discriminant, onDue:(f.timers[0]||{}).onDue,
    titre:f.title, statut:f.status, valid:f.validatedAt,
    blocs:f.blocks.length, start:f.start,
    cxOk:cx.length===1&&cx[0].target==='cx1',
    cibles:f.blocks.filter(b=>b.kind==='decision').flatMap(b=>b.options.map(o=>o.target))
      .every(id=>f.blocks.some(b=>b.id===id)),
    nexts:f.blocks.filter(b=>b.kind==='do').every(b=>b.next===null||f.blocks.some(x=>x.id===b.next)),
    poso:A.listOf(f,'posology').length, promptLen:P.length,
    ditBulle:/en GRIS, dans une BULLE/.test(P), ditBudget:/BUDGETS/.test(P),
    ditPeuTexte:/PEU DE TEXTE/.test(P), ditDisc:/"discriminant"/.test(P), ditOnDue:/"onDue"/.test(P),
    /* v4.77.0 — les libellés de minuteurs et de compteurs ne servent pas qu'À L'INSTANT : ils
       nomment les repères du JOURNAL DES ACTIONS et les compteurs du COMPTE-RENDU, relus hors
       contexte et parfois par quelqu'un qui n'était pas là. Une IA qui l'ignore produit
       « Compteur 1 » ou une phrase, et le débriefing hérite du bruit. */
    ditJournal:/JOURNAL DES ACTIONS/.test(P)&&/COMPTE-RENDU/.test(P),
    /* LOT T12 — LA FORME ENRICHIE EST UN CONTRAT, DONC ELLE PASSE PAR `migrate()`. Le prompt la
       MONTRE dans son schéma ; si l'import la refusait, une IA fidèle produirait un fichier
       irrecevable et la faute paraîtrait venir d'elle — c'est exactement ce qui s'est produit en
       v4.73.0 avec le `\n` mal échappé. On mesure donc le bloc RÉELLEMENT extrait du prompt. */
    /* v5.0.0 : les DEUX formes vivent désormais sous la clé `items` (la clé `steps` a disparu du
       prompt). Le bloc ENRICHI est donc celui dont les entrées sont des OBJETS — sans ce
       raffinement, le contrôle attrapait le premier bloc, qui est abrégé, et mesurait la forme
       qu'il ne couvre pas. Un témoin qui ne rencontre pas son cas ne prouve rien. */
    ...(()=>{const be=(obj.fiches[0].blocks||[]).find(b=>Array.isArray(b.items)&&b.items.some(x=>x&&typeof x==='object'));
      if(!be)return {enr:false};
      /* v5.0.0, étape B : le bloc ne porte que des identifiants — on résout, comme le rendu. */
      const b2=(f.blocks||[]).find(x=>x.id===be.id)||{};const its=A.bItems(b2);
      return {enr:true,enrN:be.items.length,enrApres:its.length,
        enrLvl:its[0]&&its[0].level,enrMem:!!(its[0]&&its[0].memory),enrDual:!!(its[0]&&its[0].dual),
        enrMiroir:(b2.steps||[])[0]||''};})(),
    ditItems:/"items"/.test(P)&&/"dual"/.test(P)&&/"memory"/.test(P),
    pasSteps:!/"steps"\s*:/.test(P),
    /* v5.5.0 — JALONS DE BOUCLE : le prompt les documente ET son schéma en montre un que
       `migrate()` doit accepter tel quel (compteur résolu, renvoi vers l'excursion déclarée).
       S'il tombait à l'import, une IA fidèle produirait un fichier mutilé en silence — le
       défaut de contrat exact de la v5.0.0, rejoué sur un champ neuf. */
    ditJalon:/"milestones"/.test(P)&&/n'invente jamais un/.test(P),
    jl:(()=>{const bj=(f.blocks||[]).find(b=>Array.isArray(b.milestones)&&b.milestones.length);
      if(!bj)return null;const j=bj.milestones[0];
      return {at:j.at,counter:j.counter,n:j.n,go:j.go,textOk:!!j.text};})(),
    ...(()=>{const g=A.migrate({title:'T',start:'b1',blocks:[{id:'b1',kind:'do',items:['⚠ Adrénaline IM :: 0,5 mg','Oxygène']}]});
      const it=(g.items||[])[0]||{};
      const h=A.migrate({title:'T',start:'b1',items:[{id:'i9',role:'do',do:'Déjà là'}],
        blocks:[{id:'b1',kind:'do',items:['i9']}]});
      return {abrN:(g.items||[]).length,abrDo:it.do,abrLvl:it.level,abrExp:it.expect,
        refOk:(h.items||[]).length===1&&h.blocks[0].items[0]==='i9'};})()};});
t('le schéma du prompt est un JSON valide', r.parse===true, r.err||r.extrait);
if(r.parse){
  t('le prompt DOCUMENTE la forme enrichie (items · level · memory · dual)', r.ditItems===true);
  t('… et son schéma en montre un exemple', r.enr===true);
  t('… que `migrate` accepte sans rien perdre', r.enrApres===r.enrN, `${r.enrN} → ${r.enrApres}`);
  t('… le registre y devient un niveau ordonné', r.enrLvl===3, JSON.stringify(r.enrLvl));
  t('… ★ mémoire et ×2 traversent l’import', r.enrMem&&r.enrDual, `memory=${r.enrMem} dual=${r.enrDual}`);
  /* TÉMOIN REMPLACÉ (v5.0.0) : il vérifiait la reconstruction du miroir `steps`, supprimé à
     l'étape D — il mesurait donc un composant qui n'existe plus, et restait rouge pour la bonne
     raison. Ce qu'il faut vérifier désormais est l'inverse : qu'aucun `steps` ne SURVIT dans un
     bloc, et que la clé enseignée par le prompt est bien `items`. */
  t('… et plus aucun miroir `steps` ne survit dans un bloc', r.enrMiroir==='', JSON.stringify(r.enrMiroir));
  t('le prompt n’enseigne plus la clé "steps"', r.pasSteps===true, 'la clé "steps" figure encore dans le prompt');
  /* LE DÉFAUT DE CONTRAT DE LA v5.0.0, ET IL ÉTAIT SILENCIEUX : une CHAÎNE dans `b.items` était
     recopiée telle quelle comme IDENTIFIANT. Ne désignant aucun item du pool, elle produisait une
     RÉFÉRENCE PENDANTE — le bloc s'affichait VIDE et le contenu était perdu à l'import, sans un
     mot. C'est exactement la forme qu'une IA écrit spontanément. On mesure donc les DEUX formes. */
  t('la forme ABRÉGÉE (chaîne) devient un item, jamais une référence pendante',
    r.abrN===2&&r.abrDo==='Adrénaline IM', `${r.abrN} item(s), do=${JSON.stringify(r.abrDo)}`);
  t('… avec son registre et sa réponse attendue', r.abrLvl===3&&r.abrExp==='0,5 mg',
    `level=${r.abrLvl} expect=${JSON.stringify(r.abrExp)}`);
  t('… et une VRAIE référence au pool reste une référence',
    r.refOk===true, JSON.stringify(r.refOk));
}
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
  t('le prompt DOCUMENTE les jalons de boucle ("milestones") et interdit d’inventer un seuil', r.ditJalon===true);
  t('le jalon du schéma traverse migrate() — compteur résolu, renvoi vers l’excursion',
    !!(r.jl&&r.jl.at==='count'&&r.jl.counter==='n1'&&r.jl.n===3&&r.jl.go==='cx1'&&r.jl.textOk), JSON.stringify(r.jl));
  console.log('  · longueur du prompt : '+r.promptLen+' caractères');
}
console.log(`\n${ok}/${ok+ko} OK${ko?` — ${ko} ÉCHEC(S)`:''}`);
await br.close();srv.close();process.exit(ko?1:0);
