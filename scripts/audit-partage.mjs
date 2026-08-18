#!/usr/bin/env node
/* AUDIT — PARTAGE DE SESSION : « rien ne bouge sous le doigt » quand ça vient de l'autre (v4.46.0)
 *
 * Les tests unitaires prouvent le pli, l'empreinte, les capacités et la cadence. Ils ne prouvent
 * PAS la seule chose qui compte en réanimation : qu'un évènement arrivé de l'autre appareil ne
 * déplace pas l'écran de celui qui est en train de cocher.
 *
 * Le précédent est mesuré et daté : en v4.42.0, un simple pull de synchro reconstruisait `main`
 * entre le pointerdown et le click, et AVALAIT le tap — témoin 0 coche avec re-rendu, 1 sans, sur
 * les deux moteurs. Le partage rejoue exactement ce risque, mais piloté par quelqu'un d'autre.
 *
 * On mesure donc, sur une session RÉELLE ouverte par le vrai point d'entrée (`openRead`, qui
 * construit le Runtime — le reconstruire à la main donnerait un contexte sans session vive et des
 * verdicts faux, leçon v4.40.0) : la dérive en pixels d'une étape visible pendant qu'un lot
 * d'évènements distants s'applique.
 */
import { serveApp, moteur, NOM_MOTEUR, amorce, secRunner } from './harness.mjs';

const { port, srv } = await serveApp();
const br = await moteur().launch();
/* Sections ciblables (v5.4.4) : `--grep <motif>` / `--shard k/n` — cf. secRunner (harness.mjs). */
const sec = secRunner();
let ok = 0, ko = 0;
const t = (nom, cond, det) => { if (cond) { ok++; console.log('  ✓ ' + nom); }
  else { ko++; console.log('  ✗ ' + nom + (det ? '\n      ' + det : '')); } };

// Bootstrap identique à celui d'audit-doctrine : on passe par les VRAIS points d'entrée.
async function session(page) {
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  await page.evaluate(async () => {
    const f = fiches.find(x => /Arrêt cardiaque/.test(x.title)) || fiches[0];
    openRead(f.id);
    await new Promise(r => setTimeout(r, 350));
    document.getElementById('sessStart').click();
    await new Promise(r => setTimeout(r, 350));
  });
}

await sec(`PARTAGE · un évènement distant ne déplace rien — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);

  // On se place comme un HÔTE qui partage : le rôle et l'identité viennent du transport, mais
  // aucun réseau n'est sollicité — c'est la couture `_io` qui rend la mesure possible.
  const r = await page.evaluate(async () => {
    Share.mode = 'host'; Share.role = 'lead'; Share.me = 'moi'; Share.status = 'active';
    Share.lastOk = Date.now(); Share.offset = 0;
    /* v5.6 : les étapes n'existent qu'en session (avant, la colonne montre le parcours inerte).
       Un hôte qui partage a forcément démarré — on se place donc dans cet état. */
    { const b = document.getElementById('sessStart'); if (b && !b.hidden) b.click(); }
    await new Promise(x => setTimeout(x, 500));
    // On défile pour que la compensation d'ancrage ait de la marge : bornée par le haut de page,
    // elle mesurerait sinon la limite structurelle et non l'ancrage (cf. doctrine de confOpen).
    window.scrollTo(0, 500);
    await new Promise(x => setTimeout(x, 250));

    const cibles = [...document.querySelectorAll('[data-ck]')];
    if (cibles.length < 3) return { err: 'pas assez d’étapes à l’écran' };
    const temoin = cibles[2];                       // une étape VISIBLE, pas celle qu'on modifie
    const avant = temoin.getBoundingClientRect().top;
    const scrollAvant = window.scrollY;
    // Toasts AVANT : l'amorçage en produit un légitime (« 2 fiches d'exemple ajoutées »), émis
    // hors session. Mesurer un total absolu ferait échouer la sonde sur du bruit de démarrage —
    // ce qu'on veut savoir, c'est si l'ARRIVÉE DISTANTE en produit un.
    const toastsAvant = document.querySelectorAll('.toast').length;

    // Lot distant : un participant coche deux étapes, incrémente un compteur, horodate.
    const cle0 = cibles[0].dataset.ck, cle1 = cibles[1].dataset.ck;
    const cid = Object.keys(Runtime.counters)[0];
    const tid = Object.keys(Runtime.timers)[0];
    Share.onEvents([
      { seq: 1, id: 'e1', actor: 'autre', kind: 'check', payload: { k: cle0 } },
      { seq: 2, id: 'e2', actor: 'autre', kind: 'check', payload: { k: cle1 } },
      cid ? { seq: 3, id: 'e3', actor: 'autre', kind: 'counter', payload: { id: cid, v: 4 } } : null,
      tid ? { seq: 4, id: 'e4', actor: 'autre', kind: 'timer_arm',
              payload: { id: tid, running: true, elapsedMs: 0, cycles: 0, anchor: Date.now() } } : null,
      /* CE PAYLOAD PORTE UN `label`, ET C'EST VOLONTAIRE : aucun émetteur de l'application n'en
         met, mais un client MODIFIÉ le pourrait. On vérifie donc que la réception l'IGNORE — la
         règle 15 (« aucun texte libre ne traverse le réseau ») vaut aussi à l'arrivée, sinon elle
         ne vaut rien. Le repère doit entrer au journal ; le mot, non. */
      { seq: 5, id: 'e5', actor: 'autre', kind: 'mark', payload: { id: 'em1', t: Date.now(), label: 'Adrénaline' } },
      // Différé : il ne doit RIEN peindre maintenant.
      { seq: 6, id: 'e6', actor: 'autre', kind: 'gap', payload: { k: cle0 } },
      // De soi : jamais ré-appliqué.
      { seq: 7, id: 'e7', actor: 'moi', kind: 'check', payload: { k: cibles[2].dataset.ck } },
    ].filter(Boolean));
    await new Promise(x => setTimeout(x, 300));

    const apres = temoin.getBoundingClientRect().top;
    return {
      derive: Math.round(apres - avant),
      scrollBouge: window.scrollY !== scrollAvant,
      coche0: !!state.checked[cle0], coche1: !!state.checked[cle1],
      compteur: cid ? Runtime.counters[cid] : null,
      // Le panneau compteurs est REPLIÉ sous 1000 px (stratégie V5 : le contenu clinique d'abord).
      // Il n'y a donc rien à peindre ici, et `setCounterVal` se garde déjà — c'est le même cas
      // qu'une étape hors écran. Le peinturage DOM se mesure au scénario large, plus bas.
      compteurDom: cid ? !!document.getElementById('cnval-' + cid) : null,
      minuteurArme: tid ? !!Runtime.timers[tid].running : null,
      repere: (Runtime.events || []).some(x => x.id === 'em1'),
      motDuReseau: (Runtime.events || []).some(x => x.label === 'Adrénaline') ||
        (main.textContent || '').indexOf('Adrénaline') >= 0,
      differes: Share._defer.length,
      soiIgnore: !state.checked[cibles[2].dataset.ck],
      toastsNouveaux: document.querySelectorAll('.toast').length - toastsAvant,
      modales: document.querySelectorAll('.ai-modal.on').length,
    };
  });

  t('le lot distant est appliqué', !r.err && r.coche0 && r.coche1, JSON.stringify(r));
  // Tolérance 1 px : sous-pixel de compositeur (WebKit rend 1 là où Blink rend 0), pas un défaut
  // d'ancrage. Au-delà, l'écran a réellement bougé sous le doigt.
  t('l’étape témoin ne bouge pas (≤ 1 px)', Math.abs(r.derive) <= 1, `dérive ${r.derive} px`);
  t('la page ne défile pas d’elle-même', r.scrollBouge === false);
  t('le compteur distant est à jour dans l’état', r.compteur === 4, `état ${r.compteur}`);
  t('le minuteur distant est armé', r.minuteurArme === true);
  t('le repère horodaté distant entre au journal', r.repere === true);
  t('… mais un LIBELLÉ venu du réseau n’est jamais lu (règle 15)', r.motDuReseau === false);
  t('un genre DIFFÉRÉ est mis en file, pas peint', r.differes === 1, `file : ${r.differes}`);
  t('ses PROPRES évènements ne sont jamais ré-appliqués', r.soiIgnore === true);
  // Règle 11 : l'arrivée distante ne produit ni banderole flottante, ni fenêtre.
  t('l’arrivée distante ne produit AUCUNE banderole', r.toastsNouveaux === 0,
    `${r.toastsNouveaux} toast(s) de plus`);
  t('aucune fenêtre ouverte', r.modales === 0, `${r.modales} modale(s)`);
  await page.close();
}
});

/* Le panneau compteurs/minuteurs n'existe dans le DOM qu'à partir de 1000 px (sous ce seuil il
   reste replié : le contenu clinique d'abord). C'est là qu'on mesure la PEINTURE, pas seulement
   l'état — sinon on croirait tester le rendu alors qu'on ne teste que la mémoire. */
await sec(`PARTAGE · peinture réelle du compteur et du minuteur (rail visible)`, async () => {
{
  const page = await br.newPage({ viewport: { width: 1280, height: 900 } });
  await session(page);
  const r = await page.evaluate(async () => {
    Share.mode = 'host'; Share.role = 'lead'; Share.me = 'moi'; Share.status = 'active'; Share.offset = 0;
    const cid = Object.keys(Runtime.counters)[0], tid = Object.keys(Runtime.timers)[0];
    const noeudAvant = !!document.getElementById('cnval-' + cid);
    Share.onEvents([
      { seq: 1, id: 'c1', actor: 'autre', kind: 'counter', payload: { id: cid, v: 7 } },
      { seq: 2, id: 'c2', actor: 'autre', kind: 'timer_arm',
        payload: { id: tid, running: true, elapsedMs: 0, cycles: 2, anchor: Date.now() } }]);
    await new Promise(x => setTimeout(x, 300));
    const el = document.getElementById('cnval-' + cid);
    return { noeudAvant, dom: el ? el.textContent.trim() : null,
      aria: el ? el.getAttribute('aria-label') : null,
      cycles: Runtime.timers[tid].cycles, running: Runtime.timers[tid].running };
  });
  t('le panneau est bien présent à 1280 px (sinon la mesure ne prouverait rien)', r.noeudAvant === true);
  t('le compteur distant est PEINT dans le DOM', r.dom === '7', `DOM « ${r.dom} »`);
  t('et son étiquette accessible suit', /: 7$/.test(r.aria || ''), String(r.aria));
  t('les cycles du minuteur distant sont repris', r.cycles === 2 && r.running === true);
  await page.close();
}
});

/* Le cas que `ovAfterCheck` traite à part : décocher une étape alors que la bannière de fin
   d'algorithme est affichée. En LOCAL cela re-rend le journal (légitime, l'utilisateur l'a
   demandé) ; à DISTANCE, ce re-rendu rejouerait la condensation et retirerait du contenu
   au-dessus de la carte courante. On mesure que ça n'arrive pas. */
await sec(`PARTAGE · un décochage distant ne recompose pas le journal`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    Share.mode = 'host'; Share.role = 'lead'; Share.me = 'moi'; Share.status = 'active';
    /* Fiche synthétique à DEUX blocs enchaînés : il en faut au moins deux pour que la vue soit le
       JOURNAL (une fiche mono-bloc rend le mode guidé, où la bannière n'existe pas), et il faut
       atteindre le DERNIER bloc pour que « Terminer l'algorithme » apparaisse. La fiche d'exemple
       « Arrêt cardiaque » ne convient pas : elle porte des décisions, on resterait au bloc 1.
       On la pose par `migrate` + `Data.put` puis on l'ouvre par `openRead` — le vrai point
       d'entrée, seul à construire le Runtime (leçon v4.40.0). */
    const f = migrate({ id: 'shend', title: 'Fin distante', start: 'b1', blocks: [
      /* ⚠ FIXTURE REMISE À LA FORME RÉELLE (v5.0.0) : elle portait `steps`, la clé v3, qui ne
         produit plus RIEN depuis l'étape D — les deux blocs étaient VIDES, la sonde ne trouvait
         aucune étape à cocher et levait une exception, emportant la fin de la chaîne d'audit.
         Le format v4 écrit les étapes sous `items` (forme abrégée : chaîne, ou objet). */
      { id: 'b1', kind: 'do', title: 'Premier', items: ['a', 'b'], next: 'b2' },
      { id: 'b2', kind: 'do', title: 'Second', items: ['c', 'd'], next: null }] });
    await Data.put(f); fiches.push(f);
    openRead(f.id); await new Promise(x => setTimeout(x, 350));
    /* v5.6 : les étapes n'existent qu'en session — avant, la colonne porte le parcours inerte. */
    { const b = document.getElementById('sessStart'); if (b && !b.hidden) b.click(); }
    await new Promise(x => setTimeout(x, 500));
    /* On RE-INTERROGE le DOM entre chaque clic. La PREMIÈRE action d'une session déclenche
       `ensureStarted` donc un rendu complet : une liste de nœuds capturée d'avance est détachée
       dès le premier clic, et les suivants tombent dans le vide. C'est le phénomène mesuré en
       v4.42.0 — ici dans la sonde elle-même, qui croyait avoir tout coché. */
    const cocherTout = async sel => {
      for (let i = 0; i < 12; i++) {
        const li = [...document.querySelectorAll(sel)].find(x => !state.checked[x.dataset.ck]);
        if (!li) return true;
        li.click(); await new Promise(x => setTimeout(x, 140));
      }
      return false;
    };
    await cocherTout('.ov-block [data-ck]');
    const suite = document.querySelector('[data-ovnext]');
    if (suite) suite.click();
    await new Promise(x => setTimeout(x, 400));
    await cocherTout('.ov-block:last-of-type [data-ck]');
    const cibles = [...document.querySelectorAll('.ov-block:last-of-type [data-ck]')];
    /* Pour atteindre la branche qui re-rend, il faut la CONDITION EXACTE : la bannière de fin
       présente dans le DOM alors que `state.flowEnded` vient de repasser à false. On coche donc
       tout le bloc, PUIS on termine l'algorithme (c'est « Terminer », pas le cochage, qui pose le
       drapeau et affiche la bannière) — le décochage distant qui suit remet flowEnded à false et
       tombe pile dans la branche. Sans cette mise en scène, la sonde ne traversait tout
       simplement pas le code qu'elle prétend contrôler. */
    const fin = document.querySelector('[data-ovend]');
    if (fin) fin.click();
    await new Promise(x => setTimeout(x, 350));
    const banniere = !!document.querySelector('.ov-journal .flow-end');
    const k = cibles[cibles.length - 1].dataset.ck;
    /* ON MESURE L'IDENTITÉ DES NŒUDS, PAS LEUR NOMBRE. Un re-rendu du journal reconstruit le même
       nombre d'étapes et `keepAnchor` en compense le défilement : compter les `[data-ck]` ou
       mesurer la dérive laisserait donc passer le re-rendu sans rien voir — vérifié en retirant la
       garde, les deux contrôles restaient verts. Le signal sans ambiguïté est le DÉTACHEMENT : si
       le nœud d'avant n'est plus dans le document, le DOM a été refait. C'est exactement le mode
       de défaillance mesuré en v4.42.0 — le nœud sous le doigt détaché, et le tap avalé. */
    const temoin = document.querySelector('[data-ck="' + CSS.escape(cibles[0].dataset.ck) + '"]');
    const avant = temoin ? temoin.getBoundingClientRect().top : null;
    Share.onEvents([{ seq: 9, id: 'e9', actor: 'autre', kind: 'uncheck', payload: { k } }]);
    await new Promise(x => setTimeout(x, 300));
    return { banniere, attache: !!(temoin && document.contains(temoin)),
      decoche: !state.checked[k], flowEnded: state.flowEnded,
      derive: (avant != null && temoin && document.contains(temoin))
        ? Math.round(temoin.getBoundingClientRect().top - avant) : null };
  });
  // Sans cette garde, la sonde ne traverserait pas la branche et passerait au vert pour rien.
  t('la bannière de fin est bien présente (la branche est atteinte)', r.banniere === true);
  t('le décochage distant est bien pris en compte', r.decoche === true);
  t('l’état de fin d’algorithme est remis à false', r.flowEnded === false);
  t('le journal n’est PAS reconstruit (le nœud d’avant est TOUJOURS attaché)', r.attache === true,
    'nœud détaché : le DOM a été refait sous le doigt');
  t('et rien ne bouge (≤ 1 px)', r.derive !== null && Math.abs(r.derive) <= 1, `dérive ${r.derive}`);
  await page.close();
}
});

/* ══ L'INVITÉ NE PAIE RIEN AVANT D'AVOIR LU (v4.47.0) ══════════════════════════════════════════
   Mesuré avant correctif, sur profil vierge, en chargeant `index.html#j=CODE` : deux caches
   (1 302 Ko + 1 773 Ko de pdf.js), une base IndexedDB, quatre clés localStorage, un service worker
   — et `navigator.storage.persist()` appelé INCONDITIONNELLEMENT, c'est-à-dire une demande de
   dépôt non évinçable — le tout AVANT que le premier mot de la notice ait pu s'afficher.
   Le contrôle est SYMÉTRIQUE, et c'est ce qui le rend probant : la même mesure sans le fragment
   doit montrer l'inverse (l'application s'installe bel et bien). Un contrôle qui ne verrait que le
   cas nu ne prouverait pas que la sonde sait voir une empreinte. */
await sec(`PARTAGE · empreinte sur le téléphone d'un tiers — moteur ${NOM_MOTEUR}`, async () => {
{
  const mesure = async (frag) => {
    const ctx = await br.newContext();                      // profil VIERGE à chaque fois
    const page = await ctx.newPage();
    await page.goto(`http://localhost:${port}/index.html${frag}`);
    await page.waitForFunction(() => !document.querySelector('.boot-load'), null, { timeout: 15000 })
      .catch(() => {});
    await page.waitForTimeout(900);                          // laisser le worker s'enregistrer
    const r = await page.evaluate(async () => {
      let caches_ = [], sws = 0, dbs = 0, usage = 0;
      try { caches_ = await caches.keys(); } catch (e) {}
      try { sws = (await navigator.serviceWorker.getRegistrations()).length; } catch (e) {}
      try { dbs = (await indexedDB.databases()).length; } catch (e) { dbs = -1; }
      try { usage = (await navigator.storage.estimate()).usage || 0; } catch (e) {}
      const ls = []; try { for (let i = 0; i < localStorage.length; i++) ls.push(localStorage.key(i)); } catch (e) {}
      const js = document.getElementById('joinScreen');
      return { caches: caches_.length, sws, dbs, usage, ls,
        ecran: !!js && !js.hidden,
        notice: !!js && /responsable/i.test(js.textContent) && /texte libre/i.test(js.textContent),
        hash: location.hash, champ: (document.getElementById('joinCode') || {}).value || '' };
    });
    await ctx.close();
    return r;
  };
  const invite = await mesure('#j=K7M2P4Q9');
  const normal = await mesure('');
  t('invité : AUCUN cache déposé', invite.caches === 0, `${invite.caches} cache(s)`);
  t('invité : AUCUN service worker enregistré', invite.sws === 0, `${invite.sws}`);
  t('invité : AUCUNE base IndexedDB créée', invite.dbs <= 0, `${invite.dbs}`);
  t('invité : aucune clé de stockage propre à l’espace', !invite.ls.some(k => /^ac-(db-owner|space|spaces)$/.test(k)),
    invite.ls.join(', '));
  t('invité : empreinte de stockage négligeable', invite.usage < 100000, `${invite.usage} octets`);
  t('invité : l’écran d’entrée est affiché', invite.ecran, 'écran absent');
  t('invité : la notice dit le responsable ET l’absence de texte libre', invite.notice);
  t('invité : le code est retiré de l’URL', invite.hash === '', invite.hash);
  t('invité : mais reporté dans le champ', /K7M2-P4Q9/.test(invite.champ), invite.champ);
  // Le témoin : sans fragment, l'application s'installe — la sonde SAIT voir une empreinte.
  t('témoin : sans code, l’app dépose bien son cache', normal.caches > 0, `${normal.caches}`);
  t('témoin : sans code, le worker est bien enregistré', normal.sws > 0, `${normal.sws}`);
  t('témoin : sans code, aucun écran d’entrée', !normal.ecran);
}
});

/* ══ LE REFUS N'ESCAMOTE PAS LE BOUTON QU'IL DEMANDE DE PRESSER (v4.47.0) ═════════════════════
   Un message d'erreur pousse le bouton vers le bas. Mesuré avec la rédaction précédente (34 mots,
   2 phrases, un deux-points portant deux justifications) : 7 lignes, 145 px de boîte, et à
   320×568 le bouton « Rejoindre » n'était plus visible que sur 23 px de ses 48 — sous le plancher
   de 32 px de la règle 9, et 0 px sur un écran de 480. Le défaut n'apparaît QU'À la largeur la
   plus contrainte servie, et aucun harnais ne regardait cet écran.
   On mesure aussi que la différenciation vient du CLIENT et de lui seul : le serveur bouchonné
   rend rigoureusement la même réponse dans les trois cas, seule la provenance locale du code
   change le texte. Un message qui varierait avec la réponse du serveur serait un oracle. */
await sec(`PARTAGE · le refus de jointure reste lisible et actionnable — moteur ${NOM_MOTEUR}`, async () => {
for (const [w, h] of [[320, 568], [360, 640], [390, 844]]) {
  const ctx = await br.newContext({ viewport: { width: w, height: h } });
  const page = await ctx.newPage();
  await page.goto(`http://localhost:${port}/index.html#j=K7M2P4Q9`);
  await page.waitForTimeout(700);
  const r = await page.evaluate(async () => {
    // Serveur bouchonné : la MÊME réponse pour tout le monde. Ce qui varie ne peut donc venir
    // que du client — c'est l'invariant qu'on mesure.
    Share._io.join = async () => ({ ok: false, err: 'refused' });
    const inp = document.getElementById('joinCode'), btn = document.getElementById('joinGo');
    const err = document.getElementById('joinErr');
    const lu = () => {
      const be = btn.getBoundingClientRect(), we = window.innerHeight;
      const visible = Math.max(0, Math.min(be.bottom, we) - Math.max(be.top, 0));
      return { txt: err.hidden ? '' : err.textContent, errH: Math.round(err.getBoundingClientRect().height),
        btnBas: Math.round(be.bottom), fenetre: we, visible: Math.round(visible) };
    };
    // 1) code venu du fragment (scanné) — le champ est déjà rempli par openJoinScreen
    await joinGo(); await new Promise(x => setTimeout(x, 120));
    const scan = lu();
    // 2) même code re-soumis : la boucle doit être coupée
    await joinGo(); await new Promise(x => setTimeout(x, 120));
    const redit = lu();
    // 3) code TAPÉ à la main : SHARE_JOIN ne correspond plus
    openJoinScreen('');                     // remet l'écran à zéro (et _joinRefuse)
    inp.value = 'ABCD-EFGH';
    await joinGo(); await new Promise(x => setTimeout(x, 120));
    const tape = lu();
    return { scan, redit, tape };
  });
  await ctx.close();
  const plancher = (m) => m.visible >= 44 && m.btnBas <= m.fenetre;
  t(`${w}×${h} · code scanné : le bouton reste entier sous le message`, plancher(r.scan),
    `${r.scan.visible} px visibles sur 48, bas ${r.scan.btnBas} / ${r.scan.fenetre} — boîte ${r.scan.errH} px`);
  t(`${w}×${h} · code tapé : le bouton reste entier`, plancher(r.tape),
    `${r.tape.visible} px visibles, bas ${r.tape.btnBas} / ${r.tape.fenetre}`);
  t(`${w}×${h} · re-soumission : le bouton reste entier`, plancher(r.redit),
    `${r.redit.visible} px visibles, bas ${r.redit.btnBas} / ${r.redit.fenetre}`);
  t(`${w}×${h} · un code scanné ne demande pas de le relire`, !/Relisez/.test(r.scan.txt), r.scan.txt);
  t(`${w}×${h} · un code tapé demande de le relire`, /Relisez/.test(r.tape.txt), r.tape.txt);
  t(`${w}×${h} · la 2ᵉ soumission coupe la boucle`, /déjà été refusé/.test(r.redit.txt), r.redit.txt);
  // Le serveur a répondu la MÊME chose trois fois : trois textes différents prouvent que la
  // variation est locale. Et aucun chiffre autre que ceux que le client détient.
  t(`${w}×${h} · trois textes distincts pour une réponse serveur identique`,
    new Set([r.scan.txt, r.tape.txt, r.redit.txt]).size === 3);
  t(`${w}×${h} · aucun paramètre de partage chiffré dans le refus`,
    ![r.scan.txt, r.tape.txt, r.redit.txt].some(s => /\b(minute|participant|\d+\s*(min|s)\b)/i.test(s)));
}
});

/* ══ LE MIROIR DE L'INVITÉ : PAS DE BOUTON MORT, PAS DE CUL-DE-SAC (v4.47.0) ══════════════════
   Trois défauts mesurés sur la première version de l'écran invité. (1) Le bouton « Confirmé —
   démarrer la session » — contrôle PLEIN, registre d'action primaire, le plus visible de l'écran —
   était rendu chez lui alors qu'il ne démarre RIEN (`ensureStarted` refuse une session locale à
   qui suit celle d'un autre). (2) La première étape cochable tombait à y=827 pour une fenêtre de
   844 : hors écran, derrière un bloc de confirmation diagnostique qu'il n'a pas à confirmer.
   (3) Il n'avait AUCUNE porte de sortie : `Share.stop()` n'avait aucun appelant, et le « ‹ »
   d'en-tête changeait la vue en laissant le mode et le sondage armés.
   On mesure sur un miroir RÉEL, ouvert par le vrai chemin (`joinGo` → `openSharedFiche`), avec un
   instantané produit par `sharePayload` d'une vraie fiche — jamais un état reconstruit à la main. */
await sec(`PARTAGE · le miroir de l'invité — moteur ${NOM_MOTEUR}`, async () => {
for (const [w, h] of [[320, 568], [390, 844]]) {
  const ctx = await br.newContext({ viewport: { width: w, height: h } });
  const page = await ctx.newPage();
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  const r = await page.evaluate(async () => {
    const f = fiches.find(x => /Arrêt cardiaque/.test(x.title)) || fiches[0];
    // Serveur bouchonné : une jointure RÉUSSIE, avec la projection réelle de la fiche.
    Share._io.join = async () => ({ ok: true, share: 's1', secret: 'x'.repeat(24), me: 'p1',
      role: 'scribe', fiche: sharePayload(f), since: new Date().toISOString(),
      expires_at: new Date(Date.now() + 3600e3).toISOString(), server_time: new Date().toISOString() });
    Share._io.pull = async () => ({ ok: true, status: 'active', events: [], seq: 0, n_events: 0,
      participants: [], server_time: new Date().toISOString() });
    openJoinScreen('K7M2P4Q9');
    await joinGo(); await new Promise(x => setTimeout(x, 500));
    const etape = document.querySelector('[data-ck]');
    const ecran = window.innerHeight;
    const out = {
      miroir: state.view === 'read' && Share.mode === 'guest',
      /* LE TITRE RESTE LISIBLE, PAR LE CANAL PRÉVU. `#crisisBand` porte l'information CONSTANTE et
         s'en va au défilement — c'est sa nature, documentée : `#hdrCrisis` et `#brandTitle` en
         prennent le relais dans la barre au pixel où il passe dessous. L'entrée de l'invité défile
         jusqu'au point d'action, donc le titre vit dans le relais : on mesure LÀ, pas dans le
         bandeau. Mesurer le bandeau seul reviendrait à exiger que l'invité soit le seul
         utilisateur à ne jamais défiler. */
      titreVu: (() => { const t = document.querySelector('#crisisBand .cb-ttl');
        const b = document.getElementById('brandTitle');
        const vu = x => { if (!x) return false; const r = x.getBoundingClientRect();
          return r.top >= 0 && r.bottom <= ecran && r.width > 2; };
        return (vu(t) || vu(b)) && /Arrêt cardiaque/.test((b || {}).textContent || '');
      })(),
      /* v5.6 : le geste d'entrée est une TOUCHE DU DOCK, présente dans la coque statique et
         masquée par `hidden` — on mesure donc qu'il n'est pas OFFERT, plus qu'il n'existe pas.
         C'est d'ailleurs la propriété qui compte : chez l'invité, `ensureStarted` refuse, et un
         bouton au registre primaire pour un geste sans effet est ce que la v4.47.0 a supprimé. */
      boutonMort: (()=>{const b=document.getElementById('sessStart');
        return !!b && !b.hidden && b.getBoundingClientRect().height>0;})(),
      etapeY: etape ? Math.round(etape.getBoundingClientRect().top) : null,
      etapeVue: !!etape && etape.getBoundingClientRect().top < ecran && etape.getBoundingClientRect().bottom > 0,
      ecran,
      /* CE QU'ON MESURE : qu'AUCUN DOSSIER n'est créé — pas que le drapeau `started` vaut faux.
         Le contrôle mesurait le mécanisme, et le mécanisme était le défaut : `started` à faux
         faisait sauter une trentaine de sites de mutation gardés par `if(Runtime.started)`, si
         bien que le miroir de l'invité était EN LECTURE SEULE et que ses coches ne quittaient
         jamais son téléphone. L'invariant vrai est l'étanchéité : rien dans son stockage, rien
         dans son historique, aucune session vive à son nom. */
      sessions: sessions.length, vives: Object.keys(liveSessions).length,
      dossier: !!Runtime.sessionId,
      annonce: (document.getElementById('srLive') || {}).textContent || '',
      emis: 0,
    };
    /* IL ÉMET. C'est la contrepartie de l'invariant précédent, et le défaut qu'il masquait :
       l'invité doit pouvoir CONTRIBUER, sinon tout le dispositif se réduit à un écran de
       consultation et il coche dans le vide en croyant aider. */
    { const av = Share.pending();
      const ck = document.querySelector('[data-ck]'); if (ck) ck.click();
      await new Promise(x => setTimeout(x, 400));
      out.emis = Share.pending() - av; }
    // Le menu ⋯ : ce qu'il propose, et ce qu'il ne propose plus.
    document.getElementById('hdrMore').click();
    await new Promise(x => setTimeout(x, 150));
    out.menu = [...document.querySelectorAll('#moreMenu [data-mmi]')]
      .map(e => e.textContent.trim()).join(' | ');
    document.body.click(); await new Promise(x => setTimeout(x, 100));
    return out;
  });
  t(`${w}×${h} · le miroir s'ouvre par le vrai chemin`, r.miroir, JSON.stringify(r).slice(0, 160));
  t(`${w}×${h} · aucun dossier de session n'est créé chez l'invité`,
    r.sessions === 0 && r.vives === 0 && r.dossier === false,
    `${r.sessions} archivée(s), ${r.vives} vive(s), dossier ${r.dossier}`);
  // Et pourtant il ÉMET : c'est tout l'enjeu du correctif. Une coche doit partir sur le fil.
  t(`${w}×${h} · mais ses gestes partent bien sur le fil`, r.emis >= 1, `${r.emis} évènement(s)`);
  t(`${w}×${h} · le bouton de démarrage MORT a disparu`, !r.boutonMort);
  t(`${w}×${h} · le titre de l'aide est visible sans défiler`, r.titreVu);
  t(`${w}×${h} · la première étape cochable est visible sans défiler`, r.etapeVue,
    `étape à y=${r.etapeY} pour une fenêtre de ${r.ecran}`);
  t(`${w}×${h} · l'arrivée est annoncée au lecteur d'écran`, /Vous suivez/.test(r.annonce), r.annonce);
  t(`${w}×${h} · le menu offre une PORTE DE SORTIE`, /Quitter le partage/.test(r.menu), r.menu.slice(0, 200));
  t(`${w}×${h} · et plus aucune rangée d'écriture ou d'export`,
    !/(Modifier|Versions|Dupliquer|Exporter|Répéter en exercice|Recommencer)/.test(r.menu), r.menu.slice(0, 200));
  await ctx.close();
}
/* La sortie doit RÉELLEMENT sortir : mode éteint, sondage désarmé, et aucun évènement `detach`
   émis — dater un « je poursuis seul » dans le compte-rendu de l'hôte serait affirmer à sa place. */
{
  const ctx = await br.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  const r = await page.evaluate(async () => {
    const f = fiches.find(x => /Arrêt cardiaque/.test(x.title)) || fiches[0];
    const pousses = [];
    Share._io.join = async () => ({ ok: true, share: 's1', secret: 'x'.repeat(24), me: 'p1', role: 'scribe',
      fiche: sharePayload(f), server_time: new Date().toISOString() });
    Share._io.pull = async () => ({ ok: true, status: 'active', events: [], seq: 0, n_events: 0,
      participants: [], server_time: new Date().toISOString() });
    Share._io.push = async (s, sh, ev) => { pousses.push(...ev); return { ok: true, server_time: new Date().toISOString() }; };
    openJoinScreen('K7M2P4Q9'); await joinGo(); await new Promise(x => setTimeout(x, 400));
    const avant = { mode: Share.mode, fiche: !!Runtime.fiche };
    const p = quitShare();                                  // le dialogue s'ouvre…
    await new Promise(x => setTimeout(x, 250));
    const dlg = document.querySelector('#confirmModal.on');
    const oui = dlg && [...dlg.querySelectorAll('button')].find(b => /Quitter/.test(b.textContent));
    if (oui) oui.click();
    await p; await new Promise(x => setTimeout(x, 400));
    return { avant, mode: Share.mode, timer: !!Share._timer, vue: state.view,
      fiche: !!Runtime.fiche, detach: pousses.some(e => e.kind === 'detach'),
      dialogue: !!dlg };
  });
  t('quitter passe par une confirmation (jamais un simple tap)', r.dialogue);
  t('quitter éteint le mode partagé', r.avant.mode === 'guest' && r.mode === 'off');
  t('quitter désarme le sondage', !r.timer);
  t('quitter libère le miroir et revient à la bibliothèque', r.vue === 'library' && !r.fiche);
  t('quitter n’émet AUCUN « detach » (on n’affirme pas à sa place)', !r.detach);
  await ctx.close();
}
});

/* ══ LA FENÊTRE D'APPARIEMENT DE L'HÔTE (v4.47.0) ═════════════════════════════════════════════
   Trois exigences mesurables. (1) L'ORDRE : une maquette « QR d'abord » faisait 572 px de carte
   pour une fenêtre de 568 à 320×568 — « Arrêter le partage » sous la ligne de flottaison. On place
   donc en haut ce qui se DICTE (titre de l'aide et code), le QR ensuite et plafonné. (2) LE FOND
   N'EST PAS VERROUILLÉ : toute `.ai-modal` fige le défilement derrière elle au pointeur grossier,
   et celle-ci reste ouverte pendant toute la fenêtre d'admission — la checklist de crise de l'hôte
   deviendrait indéfilable. (3) L'ÉMISSION EXISTE : sans elle, on ouvrirait un partage, quelqu'un
   rejoindrait, et rien ne bougerait jamais — une façade. */
await sec(`PARTAGE · la fenêtre d'appariement de l'hôte — moteur ${NOM_MOTEUR}`, async () => {
for (const [w, h] of [[320, 568], [390, 844]]) {
  const page = await br.newPage({ viewport: { width: w, height: h } });
  await session(page);
  const r = await page.evaluate(async () => {
    // Serveur bouchonné : ouverture réussie, puis un participant qui rejoint.
    let admis = 0;
    Share._io.open = async () => ({ ok: true, share: 's1', code: 'K7M2P4Q9',
      join_open_until: new Date(Date.now() + 120e3).toISOString(),
      expires_at: new Date(Date.now() + 3600e3).toISOString(), server_time: new Date().toISOString() });
    Share._io.admit = async () => { admis++; return { ok: true, code: 'RSTU5678',
      join_open_until: new Date(Date.now() + 120e3).toISOString(), server_time: new Date().toISOString() }; };
    /* PERSONNE N'A ENCORE REJOINT — et c'est la première moitié du contrat. Le harnais renvoyait
       d'emblée un participant, donc il mesurait la fenêtre APRÈS jointure tout en exigeant le code
       affiché : il encodait le défaut. Un code est consommé par la première jointure ; tant qu'elle
       n'a pas eu lieu, il doit être lisible, grand, avec son QR et son lien. */
    let rejoint = false;
    Share._io.pull = async () => ({ ok: true, status: 'active', events: [], seq: 0, n_events: 0,
      participants: [{ id: 'p0', label: 'Hôte', role: 'lead', owner: true }].concat(
        rejoint ? [{ id: 'p1', label: 'IADE', role: 'scribe', owner: false }] : []),
      server_time: new Date().toISOString() });
    window.__rejoindre = () => { rejoint = true; };
    const pousses = [];
    Share._io.push = async (s, sh, ev) => { pousses.push(...ev); return { ok: true, server_time: new Date().toISOString() }; };
    Auth.signedIn = () => true;                       // l'hébergement exige un compte

    await startShare(state.fiche);
    await new Promise(x => setTimeout(x, 1600));
    const card = document.querySelector('#shareModal .ai-card');
    const stop = document.getElementById('shEnd');
    const qr = document.querySelector('#shareModal .qr');
    const cr = card ? card.getBoundingClientRect() : null;
    const sr = stop ? stop.getBoundingClientRect() : null;
    const out = {
      ouverte: !!document.querySelector('#shareModal.on'),
      code: (document.getElementById('shCode') || {}).textContent || '',
      codePx: (() => { const e = document.getElementById('shCode');
        return e ? Math.round(parseFloat(getComputedStyle(e).fontSize)) : 0; })(),
      lien: (document.getElementById('shLink') || {}).textContent || '',
      qrTexte: (() => { try { return shareJoinUrl('K7M2P4Q9'); } catch (e) { return null; } })(),
      titre: (document.querySelector('#shareModal .sh-fiche') || {}).textContent || '',
      qrLarge: qr ? Math.round(qr.getBoundingClientRect().width) : 0,
      carte: cr ? Math.round(cr.height) : 0, fenetre: window.innerHeight,
      stopBas: sr ? Math.round(sr.bottom) : null,
      stopVisible: sr ? Math.round(Math.max(0, Math.min(sr.bottom, window.innerHeight) - Math.max(sr.top, 0))) : 0,
      // Dernier élément de la carte : rien ne peut le repousser, aucune liste ne peut l'engloutir.
      stopDernier: !!stop && !!stop.closest('.sh-acts') &&
        !stop.closest('.sh-acts').parentElement.querySelector('.sh-acts ~ .sh-p'),
      apresStop: stop ? [...stop.closest('.sh-acts').parentElement.children]
        .indexOf(stop.closest('.sh-acts')) >= 0
        ? [...stop.closest('.sh-acts').parentElement.children].length -
          [...stop.closest('.sh-acts').parentElement.children].indexOf(stop.closest('.sh-acts')) - 1 : -1 : -1,
      defilable: (() => { const m = document.getElementById('shareModal');
        return !!m && m.scrollHeight > m.clientHeight - 1 && /auto|scroll/.test(getComputedStyle(m).overflowY); })(),
      fondVerrouille: document.documentElement.classList.contains('modal-open'),
      // Capturées PORTE OUVERTE : une fois le code consommé, ni l'adresse ni le QR n'ont de sens.
      adresse: (document.querySelector('#shareModal .sh-adr') || {}).textContent || '',
      participants: [...document.querySelectorAll('#shareModal .sh-p .n')].map(e => e.textContent),
      // L'ÉMISSION : l'ouverture doit avoir versé l'état COURANT dans la file (la session est
      // démarrée depuis le bootstrap), sinon un invité arriverait devant une fiche vierge.
      fileOuverture: Share.pending() + pousses.length,
    };
    /* SECONDE MOITIÉ DU CONTRAT — LE CODE MEURT DÈS QUE QUELQU'UN ENTRE.
       `share_join` met `code_hash` et `join_open_until` à NULL : la porte se referme derrière celui
       qui entre, AVANT l'échéance des 120 s. L'hôte, lui, gardait sa copie et continuait d'afficher
       le code avec un décompte — il dictait un code déjà consommé et lisait « ouvert encore 97 s »
       sur une porte fermée. Donnée périmée présentée comme vivante (danger n°2 ECRI 2015). */
    window.__rejoindre();
    await new Promise(x => setTimeout(x, 2600));
    out.codeApres = (document.getElementById('shCode') || {}).textContent || '';
    out.qrApres = !!document.querySelector('#shareModal .qr');
    out.diApres = (document.querySelector('#shareModal .sh-lead') || {}).textContent || '';
    out.admetApres = !!document.getElementById('shAdmit');
    out.participants = [...document.querySelectorAll('#shareModal .sh-p .n')].map(e => e.textContent);

    // Un geste local doit produire un évènement — c'est tout l'objet du raccrochage à persistLive.
    const av = Share.pending() + pousses.length;
    const ck = document.querySelector('[data-ck]'); if (ck) ck.click();
    await new Promise(x => setTimeout(x, 500));
    out.apresCoche = (Share.pending() + pousses.length) - av;
    out.genres = pousses.map(e => e.kind).concat(Share._q.map(e => e.kind));
    // Le vocabulaire est LU DEPUIS L'APP, jamais recopié ici : une liste en dur dans le harnais
    // divergerait du jour où l'on ajoute un genre — et le contrôle passerait au vert sans rien
    // couvrir. C'est la même règle que pour les verbes réservés au lead.
    out.vocab = SHARE_KINDS_ANY.concat(SHARE_KINDS_LEAD);
    /* COUPER : « en attente » tant que le serveur n'a pas confirmé — aucun affichage optimiste.
       Ici le réseau n'existe pas, donc la requête ÉCHOUE : on mesure les deux moments, l'attente
       immédiate puis le RETOUR EN ARRIÈRE. Un bouton qui laisserait « coupé » affiché après un
       échec dirait à l'hôte qu'il a retiré un accès qu'il n'a pas retiré. */
    const cut = document.querySelector('[data-shcut]');
    if (cut) { cut.click(); await Promise.resolve(); await Promise.resolve(); }
    out.attente = (document.querySelector('#shareModal .sh-p.wait .r') || {}).textContent || '';
    await new Promise(x => setTimeout(x, 600));
    out.repli = !document.querySelector('#shareModal .sh-p.wait')
      && !!document.querySelector('#shareModal [data-shcut]');
    // La confirmation d'arrêt doit DOMINER la fenêtre qui l'ouvre : elle héritait du z-index 55
    // des fenêtres ordinaires et s'affichait DERRIÈRE la fenêtre d'appariement (94), invisible
    // alors même que le focus y était piégé.
    document.getElementById('shEnd').click();
    await new Promise(x => setTimeout(x, 250));
    out.zPartage = +getComputedStyle(document.getElementById('shareModal')).zIndex || 0;
    out.zConf = +getComputedStyle(document.getElementById('confirmModal')).zIndex || 0;
    out.confAuDessus = !!document.querySelector('#confirmModal.on') && out.zConf > out.zPartage;
    { const no = [...document.querySelectorAll('#confirmModal button')].find(b => /Poursuivre|Annuler/i.test(b.textContent));
      if (no) no.click(); else document.getElementById('confirmModal').classList.remove('on'); }
    await new Promise(x => setTimeout(x, 150));
    Share.stop();
    return out;
  });
  t(`${w}×${h} · la fenêtre s'ouvre`, r.ouverte, JSON.stringify(r).slice(0, 200));
  t(`${w}×${h} · le code DISPARAÎT dès qu'un participant entre`, !r.codeApres, r.codeApres);
  t(`${w}×${h} · … et le QR avec lui`, r.qrApres === false, 'QR encore peint');
  t(`${w}×${h} · … la fenêtre dit QUI l'a consommé`, /IADE/.test(r.diApres) && /servi/i.test(r.diApres), r.diApres);
  t(`${w}×${h} · … et « Nouveau code » reste offert`, r.admetApres, 'bouton absent');
  t(`${w}×${h} · le code est affiché en clair`, /K7M2-P4Q9/.test(r.code), r.code);
  /* LA TAILLE RENDUE, PAS LA VALEUR ÉCRITE. Le code a été agrandi trois fois sans le moindre
     effet à l'écran : `.ai-card p` (spécificité 0,1,1 — une classe ET un type) l'emportait sur
     `.sh-code` (0,1,0) et le ramenait à 13 px, quel que soit l'ordre de déclaration. C'est le 7ᵉ
     incident de cascade du projet et le PREMIER par spécificité — les six précédents tenaient à
     l'ordre. Une valeur écrite dans la feuille ne prouve rien : on mesure ce que le navigateur
     calcule. */
  /* SEUIL 30 -> 21 px (v5.6). L'échelle typographique s'est FERMÉE (A6) : la bande d'affichage
     20/24/26/34/40 n'existe plus, et le code d'appariement — qui était à 34/40 px — descend au
     cran haut des valeurs mono. Ce qu'il faut vérifier reste le MOTIF de la règle (« il se lit
     à bout de bras, à travers une pièce ») : 24 px en mono 700 avec un interlettrage de 3 px le
     tient, et le QR juste au-dessus reste le chemin nominal. On abaisse le seuil au CRAN, pas à
     la valeur mesurée : un code qui redescendrait à 21 px échouerait encore. */
  t(`${w}×${h} · et il est RÉELLEMENT grand à l'écran`, r.codePx >= 22,
    `${r.codePx} px calculés`);
  /* LE QR PORTE LE LIEN, PAS SEULEMENT LE CODE : scanné, il ouvre l'application AVEC le code
     déjà rempli — c'est tout l'intérêt. Et le lien est écrit en clair pour qu'on puisse le dicter
     ou l'envoyer quand la caméra ne sert pas. */
  t(`${w}×${h} · le QR encode l'URL AVEC le code`, /^https?:\/\/.*#j=K7M2P4Q9$/.test(r.qrTexte||''),
    r.qrTexte);
  t(`${w}×${h} · et le lien complet est donné en clair`, /#j=K7M2P4Q9$/.test(r.lien||''), r.lien);
  t(`${w}×${h} · le TITRE DE L'AIDE est à côté du code`, /Arrêt cardiaque/.test(r.titre), r.titre);
  t(`${w}×${h} · le QR est présent et plafonné à 200 px`, r.qrLarge > 60 && r.qrLarge <= 200, `${r.qrLarge} px`);
  /* CE QU'ON EXIGE VRAIMENT DE « ARRÊTER LE PARTAGE ». La première version de ce contrôle
     demandait qu'il soit visible SANS DÉFILER à toutes les largeurs. C'était trop, et cela se
     payait sur ce qui compte davantage : à 320×568, avec un code réellement lisible, un QR
     scannable et l'adresse écrite en clair, la carte fait 734 px — aucune mise en page honnête ne
     tient dans 568. L'objection d'origine n'était d'ailleurs pas celle-là : elle disait que le
     bouton ne devait jamais se retrouver À L'INTÉRIEUR d'une liste qui grandit, et qu'il devait
     rester atteignable. C'est donc cela qu'on mesure — plus la visibilité sans défilement sur le
     téléphone courant (390×844), où elle est atteignable sans rien sacrifier. */
  t(`${w}×${h} · « Arrêter le partage » ferme la carte (jamais dans la liste)`, r.stopDernier === true,
    `${r.apresStop} élément(s) après lui`);
  t(`${w}×${h} · il est atteignable (visible, ou la fenêtre défile jusqu'à lui)`,
    (r.stopBas <= r.fenetre && r.stopVisible >= 44) || r.defilable === true,
    `${r.stopVisible} px visibles, bas ${r.stopBas} / ${r.fenetre} — carte ${r.carte} px, défilable ${r.defilable}`);
  if (h >= 844) t(`${w}×${h} · et sur un téléphone courant, sans défiler`,
    r.stopVisible >= 44 && r.stopBas <= r.fenetre,
    `${r.stopVisible} px visibles, bas ${r.stopBas} / ${r.fenetre}`);
  t(`${w}×${h} · le fond N'EST PAS verrouillé (la checklist reste défilable)`, !r.fondVerrouille);
  t(`${w}×${h} · l'hôte n'apparaît pas dans sa propre liste`, r.participants.join() === 'IADE', r.participants.join());
  t(`${w}×${h} · l'ouverture verse l'état COURANT dans le fil`, r.fileOuverture > 0, `${r.fileOuverture} évènement(s)`);
  t(`${w}×${h} · un geste local produit un évènement`, r.apresCoche >= 1, `${r.apresCoche}`);
  t(`${w}×${h} · et il appartient au vocabulaire fermé`,
    r.genres.every(k => r.vocab.indexOf(k) >= 0),
    r.genres.filter(k => r.vocab.indexOf(k) < 0).join(',') || r.genres.join(','));
  t(`${w}×${h} · une coupure s'affiche EN ATTENTE, jamais acquise d'office`, /coupure/.test(r.attente), r.attente);
  /* L'ADRESSE EN CLAIR : c'est elle qu'on dicte quand le QR ne peut pas servir, et c'est aussi ce
     qui rend l'écran d'entrée trouvable. Le QR ne vaut que si l'appareil qui le scanne peut
     ATTEINDRE ce qu'il contient — servi depuis un fichier local ou `localhost`, il décode une URL
     que le téléphone d'un collègue ne joindra jamais. */
  t(`${w}×${h} · l'adresse de jointure est écrite en clair`, /localhost|adresse/.test(r.adresse),
    r.adresse);
  t(`${w}×${h} · la confirmation d'arrêt passe AU-DESSUS de la fenêtre`, r.confAuDessus === true,
    `partage z=${r.zPartage}, confirmation z=${r.zConf}`);
  t(`${w}×${h} · une coupure non transmise revient en arrière`, r.repli === true);
  await page.close();
}
});

/* ══ LES DEUX FENÊTRES DU PARTAGE SONT DES FENÊTRES DE L'APP (v4.47.0) ════════════════════════
   Retour utilisateur : « pourquoi le design n'est pas calqué sur les autres fenêtres ? — là ça
   s'affiche mal sur écrans de moyenne largeur ». Mesuré : l'écran d'entrée n'utilisait pas
   `.ai-card`, donc ni son `margin:auto` (centrage vertical) ni son échelle typographique — la
   carte restait collée en haut d'une page opaque, au-dessus de 450 px de vide à 760 px de large.
   Et une fois `.ai-card` adoptée, le 6ᵉ piège de cascade du projet : `.join-card` et `.ai-card`
   ont la même spécificité, la `max-width:720px` déclarée PLUS BAS l'emportait et la carte
   s'étalait sur 700 px. D'où des sélecteurs par `#id`, comme la règle l'impose pour toute
   géométrie. On verrouille les deux ici. */
await sec(`PARTAGE · les fenêtres suivent la grammaire de l'app — moteur ${NOM_MOTEUR}`, async () => {
for (const [w, h] of [[390, 844], [744, 1133], [760, 900], [1280, 900]]) {
  const page = await br.newPage({ viewport: { width: w, height: h } });
  await session(page);
  const r = await page.evaluate(async () => {
    Share._io.open = async () => ({ ok: true, share: 's1', code: 'K7M2P4Q9',
      join_open_until: new Date(Date.now() + 120e3).toISOString(),
      expires_at: new Date(Date.now() + 3600e3).toISOString(), server_time: new Date().toISOString() });
    Share._io.pull = async () => ({ ok: true, status: 'active', events: [], seq: 0, n_events: 0,
      participants: [], server_time: new Date().toISOString() });
    Share._io.push = async () => ({ ok: true, server_time: new Date().toISOString() });
    Auth.signedIn = () => true;
    const mes = (el) => { if (!el) return null; const b = el.getBoundingClientRect();
      return { w: Math.round(b.width), top: Math.round(b.top), bas: Math.round(b.bottom),
        g: Math.round(b.left), d: Math.round(b.right) }; };
    // 1. La fenêtre d'appariement, ouverte par son vrai chemin.
    await startShare(state.fiche); await new Promise(x => setTimeout(x, 900));
    const part = mes(document.querySelector('#shareModal .ai-card'));
    // SOUS 780 px l'app transforme toute fenêtre en feuille PLEINE LARGEUR : c'est sa convention.
    // Ce qui doit rester borné, c'est le CONTENU — sinon le code et le QR se perdent au milieu
    // d'une surface de 744 px sur tablette (mesuré : carte 744x1133 pour 643 px de contenu).
    const corps = mes(document.getElementById('shareBody'));
    /* COHÉRENCE AVEC LES AUTRES FENÊTRES (retour utilisateur) : le titre et le ✕ doivent occuper
       la largeur de la FEUILLE et vivre à son coin, comme partout ailleurs — fermer une fenêtre est
       le geste le plus appris de l'application. On compare donc au pixel à une fenêtre EXISTANTE,
       dans les mêmes conditions, plutôt qu'à une valeur écrite à la main. */
    const monTop = mes(document.querySelector('#shareModal .ai-top'));
    const monX = mes(document.querySelector('#shareModal .ai-x'));
    closeShareSheet(); openCatMgr(); await new Promise(x => setTimeout(x, 250));
    const refTop = mes(document.querySelector('#catModal .ai-top'));
    const refX = mes(document.querySelector('#catModal .ai-x'));
    closeCatMgr(); openShareSheet(); await new Promise(x => setTimeout(x, 250));
    const partCard = !!document.querySelector('#shareModal .ai-card');
    closeShareSheet(); Share.stop();
    // 2. L'écran d'entrée de l'invité.
    openJoinScreen('K7M2P4Q9'); await new Promise(x => setTimeout(x, 200));
    const join = mes(document.querySelector('.join-card'));
    const joinCard = !!document.querySelector('.join-card.ai-card');
    const titre = !!document.querySelector('#joinScreen .ai-top h3');
    document.getElementById('joinScreen').hidden = true;
    return { part, partCard, corps, monTop, monX, refTop, refX, join, joinCard, titre, ecran: window.innerHeight };
  });
  t(`${w}×${h} · l'appariement utilise la carte standard`, r.partCard);
  t(`${w}×${h} · l'entrée invité aussi, avec un titre h3`, r.joinCard && r.titre);
  t(`${w}×${h} · le CONTENU de l'appariement reste borné`, r.corps && r.corps.w <= 480,
    `${r.corps && r.corps.w} px`);
  t(`${w}×${h} · son en-tête a la MÊME largeur qu'une fenêtre existante`,
    r.monTop && r.refTop && r.monTop.w === r.refTop.w, `${r.monTop&&r.monTop.w} vs ${r.refTop&&r.refTop.w}`);
  t(`${w}×${h} · et son ✕ est au MÊME endroit`,
    r.monX && r.refX && Math.abs(r.monX.d - r.refX.d) <= 1, `${r.monX&&r.monX.d} vs ${r.refX&&r.refX.d}`);
  t(`${w}×${h} · l'entrée invité garde une largeur de fenêtre`, r.join && r.join.w <= 480,
    `${r.join && r.join.w} px`);
  // Centrage vertical : quand l'écran a de la place, la carte n'est pas collée en haut. On mesure
  // la symétrie des marges plutôt qu'une valeur absolue — c'est ce que `margin:auto` produit.
  if (h - (r.join ? r.join.bas - r.join.top : 0) > 120) {
    const haut = r.join.top, bas = r.ecran - r.join.bas;
    t(`${w}×${h} · l'entrée invité est centrée verticalement`, Math.abs(haut - bas) <= 24,
      `${haut} px au-dessus, ${bas} px en dessous`);
  }
  await page.close();
}
});

/* ══ CONTINUER SEUL : LA TRACE REMONTE, L'ÉTAT NON (v4.48.0) ══════════════════════════════════
   Le repli hors dispositif (AC 120-64 §9.a). Trois propriétés, et chacune répare un mur trouvé en
   contre-expertise : (1) au détachement, la file n'est pas JETÉE mais CONVERTIE en annexes — elle
   l'était, au moment précis où son contenu devenait la seule chose qui doive encore remonter ;
   (2) un détaché continue de sondier lentement, sinon ses annexes n'atteignent jamais l'hôte ;
   (3) chez l'hôte, l'annexe entre au JOURNAL et NULLE PART ailleurs — fusionner l'état d'un
   appareil qui a bifurqué produirait un résultat plausible et faux. */
await sec(`PARTAGE · continuer seul — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    const f = fiches.find(x => /Arrêt/.test(x.title)) || fiches[0];
    const pousses = [];
    Share._io.join = async () => ({ ok: true, share: 's1', secret: 'x'.repeat(24), me: 'p1',
      role: 'scribe', fiche: sharePayload(f), server_time: new Date().toISOString() });
    Share._io.pull = async () => ({ ok: true, status: 'active', events: [], seq: 0, n_events: 0,
      participants: [], server_time: new Date().toISOString() });
    // Le réseau tombe à la POUSSÉE : la file grossit, exactement le cas où le repli sert.
    Share._io.push = async (s, sh, ev) => { pousses.push(...ev); throw new Error('réseau'); };
    openJoinScreen('K7M2P4Q9'); await joinGo(); await new Promise(x => setTimeout(x, 400));
    const ck = [...document.querySelectorAll('[data-ck]')].slice(0, 2);
    for (const c of ck) { c.click(); await new Promise(x => setTimeout(x, 120)); }
    const avant = Share.pending();
    const genresAvant = Share._q.map(e => e.kind).join(',');
    await Share.detach();
    await new Promise(x => setTimeout(x, 200));
    return { avant, genresAvant, statut: Share.status,
      apres: Share.pending(), genresApres: Share._q.map(e => e.kind).join(','),
      // Le lot de détachement ne porte QUE lui (règle serveur).
      lotDetach: pousses.filter(e => e.kind === 'detach').length === 1 &&
                 pousses.length >= 1 && pousses[pousses.length - 1].kind === 'detach',
      cycle: !!Share._timer, mode: Share.mode };
  });
  t('la file contenait bien des évènements d’état', r.avant >= 1, `${r.avant} : ${r.genresAvant}`);
  t('au détachement, la file est CONVERTIE, jamais jetée', r.apres === r.avant,
    `${r.avant} → ${r.apres}`);
  t('et convertie en ANNEXES (aucun état ne remonte)',
    r.genresApres.split(',').every(k => k === 'offline_mark'), r.genresApres);
  t('le statut passe à « détaché »', r.statut === 'detached');
  t('le mode reste « invité » (l’écran survit au lien)', r.mode === 'guest');
  t('un cycle de retransmission reste armé', r.cycle === true);
  t('le lot qui porte le détachement ne porte que lui', r.lotDetach === true);
  await page.close();
}
{
  // Côté HÔTE : l'annexe entre au journal, et nulle part ailleurs.
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    Share.mode = 'host'; Share.role = 'lead'; Share.me = 'moi'; Share.status = 'active';
    Share.lastOk = Date.now(); Share.offset = 0;
    const avant = { coches: Object.keys(state.checked).length, ev: (Runtime.events || []).length,
      nav: state.nav.length };
    Share.onEvents([
      { seq: 9, id: 'ax1', actor: 'renfort', kind: 'offline_mark',
        payload: { t: Date.now() - 60000, ref: null } },
      { seq: 10, id: 'ax2', actor: 'renfort', kind: 'offline_mark',
        payload: { t: Date.now() - 30000, ref: null } },
      // Rejoué : le fil peut resservir un lot après une reprise — jamais de doublon.
      { seq: 9, id: 'ax1', actor: 'renfort', kind: 'offline_mark',
        payload: { t: Date.now() - 60000, ref: null } },
    ]);
    await new Promise(x => setTimeout(x, 300));
    // v5.4.0 : en étroit le journal vit DANS le dépliant minuteurs — on l'ouvre par le VRAI
    // geste avant de compter ses rangées (l'entrée au journal, elle, se mesure sur Runtime).
    // v5.4.2 : la rangée repliée n'existe plus — le volet s'ouvre par le QUAI (accès unique).
    { const dk = document.getElementById('cbTimers'); if (dk) { dk.click(); await new Promise(x => setTimeout(x, 400)); } }
    const rows = [...document.querySelectorAll('.tk-annex')];
    return { avant, coches: Object.keys(state.checked).length, nav: state.nav.length,
      ev: (Runtime.events || []).length, rangees: rows.length,
      inerte: rows.every(x => !x.querySelector('input') && !x.querySelector('button')),
      mention: rows.length ? /poursuit seul/.test(rows[0].textContent) : false,
      chrono: (Runtime.events || []).every((e, i, a) => i === 0 || a[i - 1].t <= e.t) };
  });
  t('l’annexe entre au journal de l’hôte', r.ev === r.avant.ev + 2, `${r.avant.ev} → ${r.ev}`);
  t('sans doublon quand le fil rejoue un lot', r.rangees === 2, `${r.rangees} rangée(s)`);
  t('et sans toucher l’état (ni coche, ni navigation)',
    r.coches === r.avant.coches && r.nav === r.avant.nav);
  t('elle est INERTE : ni champ, ni bouton', r.inerte === true);
  t('et se dit rapportée', r.mention === true);
  t('le journal reste chronologique', r.chrono === true);
  await page.close();
}
});

/* ══ BRIDAGE : LE SCRIBE AJOUTE, IL NE DÉFAIT PAS (v4.48.0) ═══════════════════════════════════
   Forme canonique du travail à deux (AC 120-71B §5.2.2.1), pas un compromis. Trois exigences :
   (1) il PEUT cocher — sinon le dispositif n'a plus d'objet ; (2) il ne peut PAS décocher, parce
   que décocher détruit une information que personne d'autre ne peut restituer ; (3) le refus ne
   DÉPLACE RIEN — même géométrie, même DOM, aucune banderole (règle 11) : c'est une annonce au
   lecteur d'écran et une ligne qui ne change pas d'état. Un masquage aurait fait sauter le
   contenu clinique de 46 px, mesuré, et sur ÉVÈNEMENT DISTANT si le rôle change.
   Et le cœur du cochage existe en DEUX COPIES : on mesure les deux, sinon on retombe sur la
   divergence de la v4.42.0. */
await sec(`PARTAGE · le scribe ajoute, il ne défait pas — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    const f = fiches.find(x => /Arrêt/.test(x.title)) || fiches[0];
    Share._io.join = async () => ({ ok: true, share: 's1', secret: 'x'.repeat(24), me: 'p1',
      role: 'scribe', fiche: sharePayload(f), server_time: new Date().toISOString() });
    Share._io.pull = async () => ({ ok: true, status: 'active', events: [], seq: 0, n_events: 0,
      participants: [], server_time: new Date().toISOString() });
    // On COMPTE ce qui est réellement poussé : mesurer la file seule donnerait 0 dès qu'un envoi
    // réussit — elle se vide. Le témoin doit être l'émission, pas son résidu.
    const pousses = [];
    Share._io.push = async (s, sh, ev) => { pousses.push(...ev); return { ok: true, server_time: new Date().toISOString() }; };
    const emis = () => Share.pending() + pousses.length;
    openJoinScreen('K7M2P4Q9'); await joinGo(); await new Promise(x => setTimeout(x, 500));
    // Les banderoles d'AMORÇAGE (« 2 fiches d'exemple ajoutées ») sont un bruit de démarrage, émis
    // hors session : on mesure le DELTA, pas un total absolu.
    const toastsAvant = document.querySelectorAll('.toast').length;
    const li = document.querySelector('[data-ck]'); if (!li) return { err: 'aucune étape' };
    const k = li.dataset.ck;
    const geo = () => { const b = li.getBoundingClientRect(); return Math.round(b.top); };
    // 1. COCHER : autorisé, et transmis.
    const y0 = geo(), q0 = emis();
    li.click(); await new Promise(x => setTimeout(x, 250));
    const coche = !!state.checked[k], q1 = emis(), y1 = geo();
    // 2. DÉCOCHER : refusé — l'état ne bouge pas, rien n'est émis, rien ne se déplace.
    li.click(); await new Promise(x => setTimeout(x, 250));
    const toujours = !!state.checked[k], q2 = emis(), y2 = geo();
    const noeud = document.contains(li);
    // 3. Le prédicat, aux deux copies du cœur de cochage.
    const predicat = { cocheOK: canToggleStep(true), decocheKO: !canToggleStep(false) };
    // 4. Lien figé : plus rien n'est transmis, même une coche.
    Share.lastOk = Date.now() - 600000;
    const q3 = emis();
    const li2 = document.querySelectorAll('[data-ck]')[1];
    if (li2) li2.click(); await new Promise(x => setTimeout(x, 250));
    const q4 = emis(), fige = !canToggleStep(true);
    return { coche, emisCoche: q1 - q0, toujours, emisDecoche: q2 - q1,
      derive: [y1 - y0, y2 - y1], noeud, predicat, fige, emisFige: q4 - q3,
      toasts: document.querySelectorAll('.toast').length - toastsAvant,
      modales: document.querySelectorAll('.ai-modal.on').length };
  });
  t('le scribe PEUT cocher', r.coche === true, JSON.stringify(r).slice(0, 160));
  t('et sa coche part sur le fil', r.emisCoche >= 1, `${r.emisCoche}`);
  t('il ne peut PAS décocher', r.toujours === true);
  t('et rien n’est émis quand c’est refusé', r.emisDecoche === 0, `${r.emisDecoche}`);
  t('le refus ne déplace RIEN (≤ 1 px)', r.derive.every(d => Math.abs(d) <= 1), r.derive.join(' / '));
  t('la ligne n’est pas reconstruite', r.noeud === true);
  t('le prédicat est le même aux deux copies du cochage',
    r.predicat.cocheOK === true && r.predicat.decocheKO === true, JSON.stringify(r.predicat));
  t('lien figé : plus rien n’est transmis', r.fige === true && r.emisFige === 0, `${r.emisFige}`);
  t('aucune banderole, aucune fenêtre (règle 11)', r.toasts === 0 && r.modales === 0);
  await page.close();
}
});

/* ══ REJOINDRE SE TAPE DANS LA RECHERCHE (v4.48.0, décision utilisateur) ══════════════════════
   Rejoindre est une action APPELÉE, pas permanente : une ligne en tête d'accueil ferait payer
   44 px d'attention à CHAQUE ouverture pour un geste rare. Le champ de recherche est déjà
   l'endroit où l'on tape ce qu'on cherche, et un code est reconnaissable sans ambiguïté (8
   caractères d'un alphabet fermé de 32 symboles, sans 0/1/I/O). Ce qu'on mesure : la ligne
   apparaît sur un code, JAMAIS sur un mot, et l'accueil au repos est identique au pixel — c'est
   la propriété qui justifie ce choix plutôt qu'une ligne permanente. */
await sec(`PARTAGE · rejoindre se tape dans la recherche — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto(`http://localhost:${port}/index.html`);
  await amorce(page);
  const r = await page.evaluate(async () => {
    const haut = () => document.getElementById('main').scrollHeight;
    const repos = haut(), sansCode = !document.getElementById('homeJoin');
    state.q = 'K7M2P4Q9'; renderFiches(); await new Promise(x => setTimeout(x, 200));
    const b = document.getElementById('homeJoin');
    const j = document.querySelector('.home-join');
    const cs = j ? getComputedStyle(j) : null, gs = b ? getComputedStyle(b) : null;
    const avec = { present: !!b, code: b ? b.dataset.code : null,
      cible: b ? Math.round(b.getBoundingClientRect().height) : 0,
      // ELLE DOIT SAUTER AUX YEUX (retour utilisateur) : bouton REMPLI et bord gauche de registre.
      rempli: gs ? gs.backgroundColor !== 'rgba(0, 0, 0, 0)' && gs.backgroundColor !== 'transparent' : false,
      bord: cs ? Math.round(parseFloat(cs.borderLeftWidth)) : 0,
      titrePx: j && j.querySelector('b') ? Math.round(parseFloat(getComputedStyle(j.querySelector('b')).fontSize)) : 0 };
    // Formaté à la main, avec le tiret : le même code doit être reconnu.
    state.q = 'k7m2-p4q9'; renderFiches(); await new Promise(x => setTimeout(x, 200));
    const minusc = !!document.getElementById('homeJoin');
    state.q = 'adrénaline'; renderFiches(); await new Promise(x => setTimeout(x, 200));
    const mot = !document.getElementById('homeJoin');
    state.q = 'ABC'; renderFiches(); await new Promise(x => setTimeout(x, 200));
    const court = !document.getElementById('homeJoin');
    state.q = ''; renderFiches(); await new Promise(x => setTimeout(x, 200));
    return { sansCode, avec, minusc, mot, court, reposIdentique: haut() === repos };
  });
  t('au repos, l’accueil ne porte AUCUNE ligne de jointure', r.sansCode === true);
  t('un code tapé fait apparaître la ligne', r.avec.present === true && r.avec.code === 'K7M2P4Q9',
    JSON.stringify(r.avec));
  t('minuscules et tiret sont reconnus', r.minusc === true);
  t('un mot ordinaire ne la déclenche jamais', r.mot === true);
  t('un fragment trop court non plus', r.court === true);
  t('la cible fait au moins 44 px', r.avec.cible >= 44, `${r.avec.cible} px`);
  t('le bouton est REMPLI (c'+String.fromCharCode(39)+'est la seule action de cet écran)', r.avec.rempli === true);
  t('la ligne porte le bord gauche de registre', r.avec.bord >= 3, `${r.avec.bord} px`);
  t('et son titre est réellement grand', r.avec.titrePx >= 15, `${r.avec.titrePx} px`);
  t('et l’accueil au repos est identique au pixel', r.reposIdentique === true);
  await page.close();
}
});

/* ══ BRIDAGE VISIBLE DES GESTES DU LEAD (v4.48.0) ═════════════════════════════════════════════
   Deux exigences, et la seconde est celle qui a coûté cher au projet par le passé.
   (1) VISIBLE, JAMAIS MASQUÉ : masquer ferait sauter le contenu clinique de 46 px, et sur
       évènement DISTANT si le rôle change — sous le doigt de quelqu'un qui n'a rien demandé.
   (2) UNE SEULE LISTE : le CSS (apparence désactivée) et le script (garde déléguée) énumèrent les
       mêmes verbes. Deux listes divergeraient en silence, exactement comme les deux copies du
       cœur de cochage en v4.42.0. On lit donc la liste DEPUIS LE SCRIPT et on vérifie que chaque
       élément réellement rendu porte l'apparence désactivée : une divergence devient mesurable. */
await sec(`PARTAGE · le bridage se VOIT, et les deux listes ne divergent pas — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    const f = fiches.find(x => /Arrêt/.test(x.title)) || fiches[0];
    Share._io.join = async () => ({ ok: true, share: 's1', secret: 'x'.repeat(24), me: 'p1',
      role: 'scribe', fiche: sharePayload(f), server_time: new Date().toISOString() });
    Share._io.pull = async () => ({ ok: true, status: 'active', events: [], seq: 0, n_events: 0,
      participants: [], server_time: new Date().toISOString() });
    const pousses = [];
    Share._io.push = async (s, sh, ev) => { pousses.push(...ev); return { ok: true, server_time: new Date().toISOString() }; };
    openJoinScreen('K7M2P4Q9'); await joinGo(); await new Promise(x => setTimeout(x, 500));

    /* LE PANNEAU DES MINUTEURS S'OUVRE AVANT LE RELEVÉ, et l'ordre n'est pas un détail : la
       version précédente l'ouvrait APRÈS avoir photographié les contrôles bridés — elle relevait
       donc un écran qui n'en portait aucun et accusait la liste. Sous le seuil du rail, ces
       boutons vivent dans un panneau replié. */
    { state.rtOpen = true; render(); await new Promise(x => setTimeout(x, 400)); }

    const tA = document.querySelectorAll('.toast').length;   // bruit d'amorçage : on mesure le DELTA
    const scribe = document.body.classList.contains('share-scribe');
    // La liste vient du SCRIPT, pas d'une copie dans ce fichier.
    const sel = LEAD_ONLY_SEL;
    const els = [...document.querySelectorAll(sel)];
    const muet = getComputedStyle(document.documentElement).getPropertyValue('--ink-soft').trim();
    const vus = els.map(e => ({ tag: (e.tagName || '').toLowerCase(),
      attrs: [...e.attributes].map(a => a.name).filter(n => n.startsWith('data-')).join('+'),
      curseur: getComputedStyle(e).cursor,
      ariaOff: e.getAttribute('aria-disabled')==='true',
      encre: getComputedStyle(e).color }));
    /* UN GESTE RÉSERVÉ EST UN GESTE QUI DÉTRUIT (v4.55.0). Remettre un minuteur à zéro efface un
       décompte que personne ne restitue — c'est le critère, et il remplace « conduire ou suivre ».
       Le panneau des minuteurs doit être ouvert pour que le contrôle existe. */
    const q0 = Share.pending() + pousses.length;
    const rz = document.querySelector('[data-tmreset],[data-cnreset]');
    let geo0 = null, geo1 = null, resetBloque = true;
    if (rz) {
      const id = rz.dataset.tmreset || rz.dataset.cnreset;
      const av = rz.dataset.cnreset ? Runtime.counters[id] : (Runtime.timers[id] || {}).elapsedMs;
      geo0 = Math.round(rz.getBoundingClientRect().top); rz.click();
      await new Promise(x => setTimeout(x, 300));
      geo1 = Math.round(rz.getBoundingClientRect().top);
      const ap = rz.dataset.cnreset ? Runtime.counters[id] : (Runtime.timers[id] || {}).elapsedMs;
      resetBloque = (av === ap);
    }
    /* … MAIS AVANCER EST OUVERT. C'est le renversement de la v4.55.0 : celui qui lit fait avancer
       la liste (McEvoy 2014 — le lecteur tient l'unique appareil ; SFAR — « lire et GUIDER »). */
    /* « Continuer » n'existe qu'une fois le bloc complet — le lecteur a le même comportement, et
       mesurer avant, c'est mesurer un écran qui n'a rien à offrir. On coche donc d'abord, ce qui
       est de toute façon le verbe du scribe. */
    /* Le panneau des minuteurs, ouvert plus haut, occupe la vue : on le referme pour retrouver le
       journal, puis on complète le bloc — « Continuer » n'apparaît qu'ensuite, exactement comme
       dans le lecteur. */
    { state.rtOpen = false; render(); await new Promise(x => setTimeout(x, 350)); }
    /* ON COCHE TOUT, TOUJOURS — et pas « tant que Continuer n'existe pas ». Le bouton est RENDU
       dès l'ouverture du bloc, mais son handler refuse d'avancer tant que le passage n'est pas
       complet (« jamais d'avance tant que tout n'est pas confirmé »). La boucle précédente,
       gardée sur l'existence du bouton, ne cochait donc RIEN et concluait que l'avance était
       refusée — alors qu'elle mesurait la règle d'avancement, pas le bridage. */
    const nav0 = state.nav.length;
    for (let i = 0; i < 14; i++) {
      const c = [...document.querySelectorAll('[data-ck]')].find(x => !x.classList.contains('done'));
      if (!c) break; c.click(); await new Promise(x => setTimeout(x, 140));
    }
    const suiv = document.querySelector('[data-ovnext],[data-ovopt]');
    if (suiv) { suiv.click(); await new Promise(x => setTimeout(x, 400)); }
    const nav1 = state.nav.length, q1 = Share.pending() + pousses.length;
    // Un geste ADDITIF reste ouvert : incrémenter un compteur.
    const inc = document.querySelector('[data-cninc]');
    let cptAvant = null, cptApres = null;
    if (inc) { const id = inc.dataset.cninc; cptAvant = Runtime.counters[id];
      inc.click(); await new Promise(x => setTimeout(x, 300)); cptApres = Runtime.counters[id]; }
    // Promotion en lead : tout redevient possible, SANS re-rendu ni déplacement.
    Share.role = 'lead'; render(); await new Promise(x => setTimeout(x, 200));
    const promu = !document.body.classList.contains('share-scribe');
    return { scribe, nb: els.length, vus, muet, resetBloque,
      avanceOuverte: nav1 > nav0, aEmis: q1 > q0,
      derive: (geo0 !== null && geo1 !== null) ? geo1 - geo0 : 0,
      cptAvant, cptApres, promu,
      toasts: document.querySelectorAll('.toast').length - tA,
      modales: document.querySelectorAll('.ai-modal.on').length };
  });
  t('le corps porte la classe de bridage', r.scribe === true);
  t('des contrôles DESTRUCTEURS sont bien à l’écran', r.nb >= 1, `${r.nb} élément(s)`);
  t('ils portent TOUS l’apparence désactivée (les deux listes coïncident)',
    r.vus.length > 0 && r.vus.every(v => v.curseur === 'not-allowed' || v.ariaOff),
    r.vus.filter(v => v.curseur !== 'not-allowed' && !v.ariaOff).map(v => v.tag + '[' + v.attrs + ']:' + v.curseur).join(', '));
  t('remettre à zéro ne fait RIEN', r.resetBloque === true);
  t('le refus ne déplace rien (≤ 1 px)', Math.abs(r.derive) <= 1, `${r.derive} px`);
  /* LE RENVERSEMENT DE LA v4.55.0 : la ligne passe sur la destruction, pas sur la hiérarchie. Un
     scribe qui ne pourrait pas avancer obligerait le médecin à reprendre son téléphone pour valider
     puis à repasser la main — l'inverse de ce pour quoi il partage. */
  t('mais AVANCER est ouvert au scribe', r.avanceOuverte === true);
  t('… et son geste PART', r.aEmis === true);
  t('mais incrémenter un compteur reste ouvert au scribe',
    r.cptApres === null || r.cptApres > r.cptAvant, `${r.cptAvant} → ${r.cptApres}`);
  t('promu lead, le bridage tombe', r.promu === true);
  t('aucune banderole, aucune fenêtre (règle 11)', r.toasts === 0 && r.modales === 0);
  await page.close();
}
});

/* ── LE MIROIR SUIT L'HÔTE QUAND IL CHANGE DE BLOC ────────────────────────────────────────────
   Le défaut mesuré : `SHARE_APPLY` distingue 'live', 'anchored' et 'deferred', mais une seule
   ligne rangeait 'anchored' ET 'deferred' dans la même file — laquelle n'était vidée NULLE PART
   (grep : aucun site de drainage). Conséquence : l'invité voyait les coches du bloc courant, et
   plus rien ensuite. Le miroir se figeait au premier « Continuer » de l'hôte.
   Deux régimes à vérifier, et ils sont OPPOSÉS À DESSEIN :
    · lecteur FERMÉ  -> la navigation s'applique, ancrée ;
    · lecteur OUVERT -> elle est REFUSÉE et ANNONCÉE. La clé de l'étape y est calculée AU CLIC
      depuis `state.nav` : une navigation qui arrive entre le pointerdown et le click ferait
      cocher la mauvaise étape, et le compte-rendu l'imprimerait comme réalisée.

   CE TÉMOIN A CHANGÉ DE PROPRIÉTÉ, PAS DE SUJET (correctif « le miroir laisse l'invité derrière »).
   Il mesurait « dérive ≤ 1 px du haut du journal », c'est-à-dire l'invariant « on ne défile JAMAIS
   sur un geste qui n'est pas le sien ». Cet invariant protégeait un cas et en cassait un autre,
   signalé à l'usage : quelqu'un qui SUIT la progression se faisait laisser derrière, carte après
   carte, jusqu'à perdre de vue le bloc en cours. Le critère n'est donc plus « qui a appuyé » mais
   OÙ REGARDAIT-IL, et il se mesure des DEUX côtés :
    · le bout du journal était à l'écran  -> il suivait le bord vif, on l'y GARDE (la nouvelle
      carte doit être visible après le lot) ;
    · il avait défilé ailleurs           -> RIEN NE BOUGE (dérive ≤ 1 px), comme avant.
   Un témoin qui ne mesurerait que le second régime laisserait revenir le défaut sans rien dire. */
await sec(`PARTAGE · le miroir suit quand l'hôte avance — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  /* Le redimensionnement vit CÔTÉ HARNAIS (une page ne change pas sa propre fenêtre) : on
     l'expose au contexte de page, qui l'appelle au moment où il en a besoin. */
  await page.exposeFunction('__vh', async (h) => {
    await page.setViewportSize({ width: 390, height: Math.round(h) });
    await new Promise(x => setTimeout(x, 200)); return true; });
  const r = await page.evaluate(async () => {
    Share.mode = 'guest'; Share.role = 'scribe'; Share.me = 'inv'; Share.status = 'active';
    Share.lastOk = Date.now(); Share.offset = 0; Share._defer = [];
    window.scrollTo(0, 300);
    await new Promise(x => setTimeout(x, 250));

    const blocs = (state.fiche.blocks || []).map(b => b.id);
    const cible = blocs.find(id => Runtime.nav.indexOf(id) < 0);
    const navApres = Runtime.nav.concat([cible]);
    const seqApres = Runtime.navSeq.concat([(Runtime.seq || 1) + 1]);

    /* RÉGIME 1 — IL SUIT LE BORD VIF. On amène le bout du journal à l'écran, puis on mesure si la
       nouvelle carte y est APRÈS le lot : c'est la propriété qui manquait, et c'est celle qui
       empêche de perdre le bloc en cours. */
    /* Le bout est amené EN BAS de l'écran, pas au centre : c'est ce qui rend le témoin CAPABLE
       D'ÉCHOUER. `keepAnchor` fige le bout là où il est, donc si on le centrait, la carte suivante
       resterait visible même SANS suivi — le contrôle passerait au vert sur le défaut qu'il
       prétend couvrir (leçon v4.31.1). Placé en bas, la nouvelle carte tombe sous le pli, et seule
       la règle de visibilité peut la ramener. Vérifié : suivi neutralisé -> ce témoin rougit. */
    const bout0 = [...main.querySelectorAll('.ov-block[data-ovi]')].pop();
    if (bout0) window.scrollBy(0, bout0.getBoundingClientRect().top - (window.innerHeight - 90));
    await new Promise(x => setTimeout(x, 200));
    // Témoin de dérive : une carte visible du journal, AVANT l'arrivée du lot.
    const temoin = main.querySelector('.ov-block');
    const avant = temoin ? temoin.getBoundingClientRect().top : null;
    // Comptage RELATIF : l'amorçage produit une banderole légitime (« fiches d'exemple ajoutées »),
    // émise hors session. Un total absolu ferait échouer la sonde sur du bruit de démarrage — ce
    // qu'on veut savoir, c'est si L'ARRIVÉE DISTANTE en produit une.
    const toastsAvant = document.querySelectorAll('.toast').length;

    Share.onEvents([{ seq: 11, id: 'n1', actor: 'hote', kind: 'nav',
      payload: { nav: navApres, navSeq: seqApres } }]);
    await new Promise(x => setTimeout(x, 500));
    const t2 = main.querySelector('.ov-block');
    const apres = t2 ? t2.getBoundingClientRect().top : null;

    const out = {
      applique: Runtime.nav.indexOf(cible) >= 0,
      // L'alias `state.nav` <-> `Runtime.nav` doit TENIR : lui affecter un tableau neuf le casse
      // en silence, et l'application lit alors deux navigations différentes selon l'endroit.
      aliasIntact: state.nav === Runtime.nav && state.navSeq === Runtime.navSeq,
      seqMonte: (Runtime.seq || 0) >= seqApres[seqApres.length - 1],
      cartes: main.querySelectorAll('.ov-block').length,
      derive: (avant != null && apres != null) ? Math.round(apres - avant) : null,
      toasts: document.querySelectorAll('.toast').length - toastsAvant,
      modales: document.querySelectorAll('.ai-modal.on').length,
    };
    // Le bout du journal — la carte que l'hôte vient de poster — est-il sous les yeux ?
    {
      const nb = [...main.querySelectorAll('.ov-block[data-ovi]')].pop();
      const r2 = nb ? nb.getBoundingClientRect() : null;
      out.boutVisible = !!r2 && r2.top >= 0 && r2.top < window.innerHeight - 4;
    }

    /* ⚠ LE REPÈRE SE DÉSIGNE PAR SÉLECTEUR, JAMAIS PAR NŒUD (v5.6). Le témoin gardait une
       RÉFÉRENCE à l'élément sous le centre de l'écran — or un re-rendu le DÉTRUIT (mesuré :
       `SPAN.pos-body`, `isConnected:false`, et pas un seul ancêtre survivant dans sa chaîne
       `parentNode`). Il rendait alors `null`, c'est-à-dire un rouge qui ne dit rien du produit.
       On vise un repère STABLE et re-interrogé à chaque échantillon : la rangée « Consulter »,
       qui vit SOUS le journal (donc s'y garer met le bout hors de vue, ce que le régime exige),
       qui est un nœud UNIQUE, et qu'un lot de navigation ne touche pas.
       ⚠ LES REPÈRES POSOLOGIQUES ONT ÉTÉ ESSAYÉS PUIS ÉCARTÉS À LA MESURE : `renderOvOnly` les
       RECLASSE pour le bloc courant (v5.4.2), donc `.pos-card` ne désigne plus la même carte
       après le lot — on mesurait un écart entre deux objets, pas un déplacement. Même leçon qu'en
       A65 : à travers un re-rendu, on re-interroge le DOM — et l'on vérifie que le sélecteur
       désigne encore la même chose. */
    const REPERE = '.annex-row';

    /* ⚠ ET ON LUI DONNE DE QUOI DÉFILER (v5.6, A46). Une fois garé sous le bas du bout, il ne
       restait que 46 px avant la borne de défilement — donc un document qui rétrécit de plus de
       46 px au re-rendu (la condensation R6 en retire plusieurs centaines) ferait RABATTRE le
       navigateur, et le rabat serait imputé à l'application. On raccourcit la FENÊTRE le temps de
       ce régime : `maxScroll` grandit d'autant, la bande apparaît, et rien d'autre ne change —
       même page, même session, mêmes volets (précédent : redimensionner plutôt que recharger).
       La hauteur est rendue juste après, pour ne pas contaminer ce qui suit. */
    const _vh0 = window.innerHeight;
    if (typeof window.__vh === 'function') await window.__vh(440);

    /* RÉGIME 2 — IL REGARDE AILLEURS. Même lot, mais l'écran est cette fois loin du bout : rien ne
       doit bouger d'un pixel. C'est l'ancienne garantie, conservée telle quelle — la nouveauté ne
       vaut que si elle ne coûte pas celle-là. */
    {
      /* ⚠ LE MONTAGE A DÛ ÊTRE REFAIT AU LOT T5 (v5.0.0), et la leçon vaut au-delà de ce
         contrôle. Il faisait `scrollTo(0,0)` pour signifier « il regarde ailleurs » — ce qui
         était vrai tant que le journal naissait à ~700 px du haut. Depuis que L'ACTION PASSE
         DEVANT L'ORIENTATION, le haut de page est précisément le bout du journal : le montage
         produisait donc l'AUTRE régime, l'application suivait le bord vif comme elle le doit, et
         le témoin est passé au rouge en accusant un comportement juste (mesuré : 508 px).
         On ne vise donc plus une POSITION, on vise la PROPRIÉTÉ — le bout doit être hors de vue —
         et l'on vérifie d'abord que le cas est bien rencontré : un contrôle qui ne rencontre pas
         son cas ne le couvre pas (leçon v4.31.1, redite ici au prix d'un faux rouge). */
      /* ⚠ ET IL NE SE GARE PLUS AU BOUT DE LA PAGE (v5.6, A46 appliqué ici — trouvé en cherchant
         la cause des 457 px d'A107). `scrollTo(0, scrollHeight)` colle le défilement à sa borne
         MAXIMALE : ce que le témoin mesure ensuite n'est plus l'ancrage de l'application mais la
         façon dont le NAVIGATEUR réconcilie une position saturée avec un document qui change de
         hauteur — il rabat, et le rabat est imputé à l'app. A46 l'avait déjà payé à 22 px sur le
         témoin d'ancrage ; ici il vaut plusieurs centaines.
         On vise donc la PROPRIÉTÉ (« le bout est hors de vue ») au plus PRÈS, pas au plus loin :
         juste sous le bas du bout, avec un coussin — et l'on EXIGE de rester à distance de la
         borne. Si la fiche n'a pas de quoi défiler entre les deux, le témoin le DIT au lieu de
         se garer au bout en silence : une mesure prise sur une borne saturée est une mesure du
         moteur, pas de l'application. */
      /* ⚠ ET LE RÉGIME SE DÉCIDE AVEC LE PRÉDICAT DE L'APPLICATION, PAS AVEC UN JUMEAU (v5.6).
         Le témoin se garait « bout hors de vue » au sens `top >= 0 && top < vh-4` — le test de
         `boutVisible`. Mais `shareApplyAnchored` décide, lui, sur `bottom > stickBase() && top <
         innerHeight` : une carte HAUTE dont le bas dépasse encore sous le chrome est « sous les
         yeux » pour l'app et « hors de vue » pour le témoin. Résultat mesuré : le témoin exigeait
         l'immobilité pendant que l'app suivait le bord vif — 273 px imputés à un comportement
         JUSTE. Deux définitions concurrentes d'un même régime, la divergence que ce dépôt a déjà
         payée quatre fois. On se gare donc SOUS le bas du bout au sens de l'app. */
      {const rep = main.querySelector(REPERE);
       if(rep){const r0 = rep.getBoundingClientRect();
         /* Garé dans le TIERS HAUT, pas au centre : la rangée « Consulter » est le dernier
            contenu de la page, et la centrer revient à se coller à la borne (mesuré : 0 px de
            marge). Elle reste pleinement visible, ce que le témoin vérifie. */
         window.scrollTo(0, Math.max(0, window.scrollY + r0.top - window.innerHeight*0.3));}}
      await new Promise(x => setTimeout(x, 250));
      {const rp=main.querySelector(REPERE);const rr=rp?rp.getBoundingClientRect():null;
       out.repereLa = !!rr && rr.top>=0 && rr.bottom<=window.innerHeight;}
      out.scAvant = Math.round(window.scrollY);
      {const nb = [...main.querySelectorAll('.ov-block[data-ovi]')].pop();
       const q = nb ? nb.getBoundingClientRect() : null;
       /* LE PRÉDICAT EST CELUI DE L'APPLICATION, pas un « entièrement hors écran » de notre
          invention : le régime se décide sur « le BOUT était-il sous les yeux », c'est-à-dire son
          HAUT dans la fenêtre (même test que `boutVisible` ci-dessus et qu'`ovAdvanceRender`).
          Mesurer autre chose reviendrait à écrire une seconde définition du régime — celle-là
          même que le dépôt a payé deux fois quand deux critères concurrents ont divergé. */
       const base = (typeof stickBase==='function'?stickBase():0);
       out.ailleursMonte = !!q && !(q.bottom > base && q.top < window.innerHeight);
       out.dbg = q ? {top:Math.round(q.top),bottom:Math.round(q.bottom),base:Math.round(base),
         vh:window.innerHeight,sy:Math.round(window.scrollY)} : null;}
      /* ⚠ ET LE LOT DOIT CHANGER LA HAUTEUR AU-DESSUS DU REGARD, SINON LE TÉMOIN NE PROUVE RIEN
         (v5.6). Avec la première cible venue, la carte qui se condense et celle qui s'ouvre
         avaient la MÊME hauteur : le journal ne bougeait pas d'un pixel, et le contrôle restait
         VERT même en neutralisant complètement l'ancrage (vérifié). On choisit donc le bloc dont
         la carte différera le plus de la courante — et l'on MESURE ce que le journal a gagné ou
         perdu, pour refuser de conclure quand l'écart est nul. */
      /* L'HÔTE A AVANCÉ DE PLUSIEURS BLOCS pendant qu'il regardait ailleurs — c'est le cas réel du
         retard rattrapé à la jointure, et le seul qui change franchement la hauteur : chaque
         passage achevé se condense en rangée (R6) tandis qu'une seule carte s'ouvre. Avec UN seul
         bloc, la carte qui se ferme et celle qui s'ouvre ont la même taille : le journal ne
         bougeait que de 30 px et le contrôle restait vert même sans aucun ancrage (vérifié). */
      /* ⚠ ON EN LAISSE UN : le contrôle du drain, plus bas, a besoin d'un « Continuer » local à
         faire. Tout consommer le privait de son geste (mesuré : « ABSENT »). */
      const _lib = blocs.filter(id => Runtime.nav.indexOf(id) < 0);
      const suite = _lib.slice(0, Math.min(3, Math.max(1, _lib.length - 1)));
      const cibles = suite.length ? suite : [blocs[0]];
      const hJ = () => {const w = main.querySelector('.ov-wrap');
        return w ? Math.round(w.getBoundingClientRect().height) : 0;};
      const hAvant = hJ();
      /* ⚠ « RIEN NE BOUGE » SE MESURE SUR CE QU'ON REGARDE, PAS SUR UN ÉLÉMENT ARBITRAIRE
         (v5.6). Le témoin visait `main .ov-block`, la PREMIÈRE carte du journal : R6 la condense
         en rangée d'historique dès qu'un passage s'achève, donc après le lot le sélecteur
         désigne une AUTRE carte — on mesurait un écart de hauteur entre deux objets. Et le viser
         sur le chapeau n'est pas meilleur : `keepAnchor` compense les changements de hauteur
         SITUÉS AU-DESSUS du regard, ce qui déplace légitimement tout le haut de page pendant que
         la vue, elle, ne bouge pas d'un pixel — c'est exactement son office.
         On mesure donc CE QUE L'ŒIL A SOUS LUI : l'élément au centre du viewport avant le lot,
         et sa position après. C'est la propriété que la règle 11 protège. */
      const rA = main.querySelector(REPERE);
      const yA = rA ? rA.getBoundingClientRect().top : null;
      const scA = window.scrollY;
      Share.onEvents([{ seq: 13, id: 'n3', actor: 'hote', kind: 'nav',
        payload: { nav: Runtime.nav.concat(cibles),
                   navSeq: Runtime.navSeq.concat(cibles.map((_, i) => (Runtime.seq || 1) + 1 + i)) } }]);
      await new Promise(x => setTimeout(x, 500));
      const rB = main.querySelector(REPERE);
      const yB = rB ? rB.getBoundingClientRect().top : null;
      out.deriveAilleurs = (yA != null && yB != null) ? Math.round(yB - yA) : null;
      /* Le DÉFILEMENT peut légitimement changer — c'est la compensation d'ancrage. Ce qui ne doit
         pas changer, c'est la position de ce qu'on regarde. On garde la valeur pour le rapport. */
      out.scrollAilleurs = Math.round(window.scrollY - scA);
      /* ⚠ A46 SE MESURE PAR LE RABAT, PAS PAR UNE MARGE (v5.6). Ce qui fausse une mesure de
         dérive, c'est que le NAVIGATEUR ait dû rabattre le défilement parce que le document a
         rétréci sous lui — pas la distance à la borne en soi. Exiger une bande de 80 px était
         d'ailleurs GÉOMÉTRIQUEMENT impossible ici : il n'y a qu'une centaine de pixels sous la
         rangée « Consulter ». On teste donc la chose même : la borne d'APRÈS atteint-elle encore
         la position d'AVANT ? Si non, le témoin le DIT au lieu d'imputer le rabat à l'app. */
      out.dJournal = hJ() - hAvant;
      out.rabat = Math.round(Math.min(0, (document.documentElement.scrollHeight
        - window.innerHeight) - out.scAvant));
    }
    if (typeof window.__vh === 'function') await window.__vh(_vh0);

    /* ── LE RÉGIME « deferred » SE DRAINE SUR UN GESTE LOCAL DE NAVIGATION, ET SANS LE LECTEUR.
       C'est le cas que le défaut laissait passer : `SHARE_APPLY` classe `verify` et `gap` en
       'deferred', et le SEUL drain était le bouton « reprendre » du mode lecteur. Un invité qui
       n'ouvre jamais le lecteur ne recevait donc jamais la trace do-verify de l'hôte.
       LE CONTRÔLE VÉRIFIE D'ABORD QUE LE CAS EST RENCONTRÉ — la file doit être NON VIDE avant le
       geste local, sinon on mesurerait un drain qui n'a rien à drainer. */
    {
      const cle = Object.keys(state.checked || {})[0]
        || (state.navSeq[state.navPos] + ':' + state.nav[state.navPos] + ':0');
      Share.onEvents([{ seq: 20, id: 'v1', actor: 'hote', kind: 'verify', payload: { k: cle } }]);
      await new Promise(x => setTimeout(x, 300));
      out.filePleine = (Share._defer || []).length;
      out.avantDrain = !!(Runtime.verified || {})[cle];
      /* Le geste LOCAL : un « Continuer » ordinaire du journal — pas un bouton du lecteur. */
      /* On prend un geste de navigation RÉELLEMENT disponible à ce rôle et à cet instant :
         « Continuer » est `aria-disabled` tant que le bloc n'est pas coché (le libellé le dit),
         et le cocher entièrement changerait l'état qu'on mesure. « ↺ Refaire » est une
         navigation locale ouverte à tous les rôles depuis la v4.55.0, et il poste une carte au
         bout du journal sans rien effacer. */
      /* IL FAUT CONSTITUER L'ÉTAT OÙ LE GESTE EXISTE. « Continuer » est `aria-disabled` tant que
         le bloc n'est pas coché — et c'est une information en soi : un scribe au milieu d'un bloc
         n'a AUCUN geste de navigation disponible, donc la file attend, ce qui est exactement ce
         que « acquittement par l'action » veut dire. On coche donc les étapes restantes (le
         cochage est ouvert à tous les rôles) avant de mesurer le drain. */
      const cartes=[...main.querySelectorAll('.ov-block')];
      const derniere=cartes[cartes.length-1];
      if(derniere)[...derniere.querySelectorAll('li[data-ck]')]
        .filter(li=>li.getAttribute('aria-checked')!=='true')
        .forEach(li=>li.click());
      await new Promise(x => setTimeout(x, 400));
      const nx = [...main.querySelectorAll('.ov-block [data-ovnext]')]
        .find(b=>b.getAttribute('aria-disabled')!=='true');
      out.btn = nx ? (nx.textContent||'').trim().slice(0,40) : 'ABSENT';
      out.role = Share.role;
      if (nx) nx.click();
      await new Promise(x => setTimeout(x, 500));
      out.fileApres = (Share._defer || []).length;
      out.apresDrain = !!(Runtime.verified || {})[cle];
      out.cleDrain = cle;
    }

    return out;
  });
  t('l’hôte avance : la navigation ATTEINT l’écran', r.applique === true, JSON.stringify(r).slice(0, 220));
  t('… l’alias state/Runtime tient', r.aliasIntact === true);
  t('… le compteur de visites ne redescend pas', r.seqMonte === true);
  t('… une carte de plus au journal', r.cartes >= 2, `${r.cartes} carte(s)`);
  t('… il suivait le bord vif : la nouvelle carte est sous les yeux',
    r.boutVisible === true, JSON.stringify({ boutVisible: r.boutVisible, derive: r.derive }));
  t('… témoin : le bout n’était PAS sous les yeux avant le lot',
    r.ailleursMonte === true, JSON.stringify(r.dbg));
  /* ⚠ ON EXIGE QUE LA MESURE AIT EU LIEU : `Math.abs(null)` vaut 0, donc un témoin perdu
     passerait au vert sans rien mesurer (leçon v4.31.1). */
  t('témoin : un repère stable est bien sous les yeux', r.repereLa === true);
  t('témoin : le lot change bien la hauteur au-dessus du regard',
    Math.abs(r.dJournal) >= 50, `${r.dJournal} px de journal`);
  t('témoin : aucun rabat de fin de page ne fausse la mesure (A46)',
    r.rabat === 0, `${r.rabat} px rabattus par le navigateur`);
  t('… il regardait ailleurs : ce qu\'il regarde ne bouge pas (≤ 1 px)',
    r.deriveAilleurs !== null && Math.abs(r.deriveAilleurs) <= 1,
    `${r.deriveAilleurs} px de dérive (défilement compensé : ${r.scrollAilleurs} px)`);
  t('… sans banderole ni fenêtre (règle 11)', r.toasts === 0 && r.modales === 0);
  /* Le drain du régime « deferred » — SANS jamais ouvrir le lecteur. */
  t('témoin : la file « deferred » est bien pleine avant le geste',
    r.filePleine >= 1, `${r.filePleine} en file`);
  t('… et rien n’est appliqué tant qu’aucun geste local n’a eu lieu', r.avantDrain === false);
  t('un « Continuer » ORDINAIRE draine la file (sans le mode lecteur)',
    r.fileApres === 0 && r.apresDrain === true,
    `file ${r.filePleine} → ${r.fileApres}, trace ${r.avantDrain} → ${r.apresDrain} · geste « ${r.btn} », rôle ${r.role}`);
  await page.close();
}
});

/* ── COUPER CELUI QUI TIENT LA MAIN LA REND À L'HÔTE ─────────────────────────────────────────
   « Un seul lead à tout instant, jamais deux, JAMAIS ZÉRO » (invariant 1). Sans cela, couper le
   participant à qui l'on vient de passer la main laisse le partage sans conducteur : un lead
   révoqué d'un côté, un hôte resté scribe de l'autre, et le prochain invité admis arrive scribe
   lui aussi. Ce n'est pas bloquant pour l'hôte — ses gardes sortent sur `mode!=='guest'` — mais
   faire reposer un invariant AFFICHÉ sur la porte de sortie d'une garde, c'est le laisser dépendre
   d'un détail d'implémentation. */
await sec(`PARTAGE · couper celui qui conduit rend la main — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    const patchs = [];
    const vrai = window.rest;
    window.rest = async (m, u, b) => {
      if (m === 'PATCH' && /session_participants/.test(u)) { patchs.push({ u, b }); return {}; }
      return vrai(m, u, b); };
    Share.mode = 'host'; Share.role = 'scribe'; Share.status = 'active'; Share.share = 's1';
    // L'état d'après une passation : l'invité conduit, l'hôte a relâché.
    Share.participants = [{ id: 'p0', label: 'Hôte', role: 'scribe', owner: true },
                          { id: 'p1', label: 'IADE', role: 'lead', owner: false }];
    const ok = await Share.revoke('p1');
    return { ok, patchs: patchs.map(x => ({ pid: /participant=eq\.([^&]+)/.exec(x.u)[1], b: x.b })),
             roleApres: Share.role };
  });
  t('la coupure part', r.ok === true);
  t('… et la main revient à l’hôte', r.patchs.some(x => x.pid === 'p0' && x.b.role === 'lead'),
    JSON.stringify(r.patchs));
  t('… dans cet ordre : couper, PUIS rendre', r.patchs.length === 2 && r.patchs[0].pid === 'p1');
  t('… et le client le sait immédiatement', r.roleApres === 'lead', r.roleApres);
  await page.close();
}
});

/* ── UN RECHARGEMENT NE DOIT PLUS TOUT PERDRE ────────────────────────────────────────────────
   Le cas est banal et il était terminal : un onglet mobile meurt tout seul (iOS recycle les
   onglets en arrière-plan), et l'invité perdait sa participation SANS RETOUR — rien n'était
   persisté, et son code d'appariement est consommé, donc il ne pouvait pas rejoindre.
   Le billet vit en `sessionStorage` : CET onglet, CETTE navigation. On vérifie les deux moitiés
   de l'arbitrage — il survit au rechargement (sinon il ne sert à rien) ET il ne contient aucune
   donnée clinique (sinon l'étanchéité écrite au registre serait fausse). */
await sec(`PARTAGE · un rechargement ne perd plus la session — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    const snapFiche = JSON.parse(JSON.stringify(state.fiche));
    Share._io.join = async () => ({ ok: true, share: 's9', secret: 'SECRET-0123456789abcd',
      me: 'p9', role: 'scribe', fiche: snapFiche, since: 0,
      expires_at: new Date(Date.now() + 3600e3).toISOString(), server_time: new Date().toISOString() });
    Share._io.pull = async (k, sh, since) => ({ ok: true, status: 'active', role: 'scribe', me: 'p9',
      events: [], seq: 0, n_events: 0, participants: [],
      fiche: since === 0 ? snapFiche : undefined,
      expires_at: new Date(Date.now() + 3600e3).toISOString(), server_time: new Date().toISOString() });

    await Share.joinByCode('K7M2P4Q9', 'IADE');
    const brut = sessionStorage.getItem('ac-share-tk') || '';
    const out = {
      billet: !!brut,
      // AUCUNE DONNÉE CLINIQUE dans le billet : il ne porte que de quoi rouvrir le tuyau. Le titre
      // de la fiche est le témoin le plus simple — s'il y est, tout le reste peut y être.
      sansClinique: brut.indexOf(state.fiche.title) < 0 && brut.indexOf('blocks') < 0,
      porteLeSecret: brut.indexOf('SECRET-0123456789abcd') >= 0,
      // Le LIEN peut mourir sans que l'écran soit quitté : le billet doit survivre à `freeze`,
      // sinon un invité coupé puis réadmis ne pourrait plus reprendre après un rechargement.
      apresFreeze: (() => { Share.freeze('ended'); return !!sessionStorage.getItem('ac-share-tk'); })(),
    };
    // `stop` = l'écran est quitté : là seulement, plus rien ne subsiste.
    Share.mode = 'guest'; Share.secret = 'SECRET-0123456789abcd';
    Share.stop();
    out.apresStop = !sessionStorage.getItem('ac-share-tk');

    // REPRISE : on repose un billet et on rejoue le chemin du rechargement.
    sessionStorage.setItem('ac-share-tk', JSON.stringify({ s: 's9', k: 'SECRET-0123456789abcd', m: 'p9', r: 'scribe' }));
    out.lu = !!Share._ticketRead();
    out.repris = await Share.resume();
    out.ficheRevenue = !!(Share.fiche && Share.fiche.title);
    out.modeInvite = Share.mode === 'guest';

    // Un serveur qui REFUSE (partage purgé, participant coupé) ne doit pas laisser traîner le jeton.
    Share.stop();
    sessionStorage.setItem('ac-share-tk', JSON.stringify({ s: 'sX', k: 'SECRET-0123456789abcd', m: 'p9', r: 'scribe' }));
    Share._io.pull = async () => ({ ok: false, err: 'refused' });
    out.reprisRefus = await Share.resume();
    out.billetNettoye = !sessionStorage.getItem('ac-share-tk');
    return out;
  });
  t('la jointure écrit un billet', r.billet === true);
  t('… qui porte le secret', r.porteLeSecret === true);
  t('… et AUCUNE donnée clinique', r.sansClinique === true);
  t('le billet survit à la mort du lien', r.apresFreeze === true);
  t('… mais pas au départ de l’écran', r.apresStop === true);
  t('après rechargement, le billet est relu', r.lu === true);
  t('… la reprise rouvre le fil', r.repris === true && r.modeInvite === true);
  t('… et la fiche revient du serveur', r.ficheRevenue === true);
  t('un refus du serveur ne laisse pas traîner le jeton', r.reprisRefus === false && r.billetNettoye === true);

  /* LE RECHARGEMENT RÉEL — `sessionStorage` survit, l'écran d'entrée ne doit PAS reparaître :
     l'invité n'a rien à saisir, son code est brûlé depuis longtemps. */
  await page.evaluate(() => sessionStorage.setItem('ac-share-tk',
    JSON.stringify({ s: 's9', k: 'SECRET-0123456789abcd', m: 'p9', r: 'scribe' })));
  await page.reload();
  await page.waitForFunction(() => !document.querySelector('.boot-load'));
  await page.waitForTimeout(800);
  const ap = await page.evaluate(() => ({
    billet: !!sessionStorage.getItem('ac-share-tk'),
    entree: !document.getElementById('joinScreen').hidden,
    demarree: !!document.querySelector('main')  &&
              (document.querySelector('main').textContent || '').trim().length > 0,
  }));
  /* ICI IL N'Y A PAS DE SERVEUR : la reprise échoue, donc le billet est NETTOYÉ et l'application
     démarre normalement. C'est exactement le comportement voulu — un invité dont le partage a été
     purgé se retrouve CHEZ LUI, pas devant une erreur qu'il ne peut pas résoudre. Ce que la sonde
     prouve, c'est que le chemin de reprise ne casse pas le démarrage et ne fait pas reparaître un
     écran de saisie que l'invité ne peut pas remplir (son code est brûlé). */
  t('un rechargement ne fait PAS reparaître l’écran d’entrée', ap.entree === false);
  t('… et un serveur injoignable ne bloque pas le démarrage', ap.demarree === true);
  t('… le billet mort ne traîne pas', ap.billet === false);
  await page.close();
}
});

/* ── LE JOURNAL RÉFÉRENTIEL : LE MOT ARRIVE, LE TEXTE LIBRE NON ─────────────────────────────
   Un repère partagé ne portait AUCUN mot : `ref` n'existait que pour les compteurs, si bien qu'un
   repère posé par l'hôte s'affichait « Action 3 » chez l'invité — l'heure juste, le mot manquant.
   On vérifie les deux moitiés de la promesse, et elles se contredisent si l'on se trompe :
   le MOT doit arriver (sinon la fonctionnalité ne sert à rien), et le TEXTE LIBRE ne doit JAMAIS
   partir (sinon la règle 15 et le registre RGPD deviennent faux). */
await sec(`PARTAGE · le journal référentiel — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    Share.mode = 'host'; Share.role = 'lead'; Share.me = 'moi'; Share.status = 'active';
    setMyTags([{ k: 'mru', l: 'Médecin régulateur', a: ['mru', 'regul'] }]);
    // v5.6 : « Noter l'heure » a quitté le panneau — c'est une TOUCHE DU DOCK. On pose le repère
    // par le vrai geste, puis on ouvre le volet du quai pour atteindre le champ d'étiquette.
    document.getElementById('tkKey').click();
    await new Promise(x => setTimeout(x, 300));
    const dk = document.getElementById('cbTimers');
    if (dk) { dk.click(); await new Promise(x => setTimeout(x, 400)); }
    const inp = document.querySelector('.tk-panel [data-tklab]');
    inp.value = 'regul';
    inp.dispatchEvent(new Event('input', { bubbles: true }));
    await new Promise(x => setTimeout(x, 250));
    const chips = [...document.querySelectorAll('.tk-sug:not([hidden]) [data-tkpick]')];
    const out = {
      propositions: chips.map(c => c.textContent),
      cible44: chips.length > 0 && chips.every(c => c.getBoundingClientRect().height >= 43.5),
      // Une étiquette PERSONNELLE ne se résout que sur les appareils du même compte : pendant un
      // partage, le taire laisserait croire à un mot partagé.
      persoSignalee: chips.some(c => /vous seul/i.test(c.textContent)),
    };
    // AVANT de choisir : le texte tapé est LOCAL, et rien de lui ne doit entrer dans l'émission.
    const ev0 = Runtime.events[Runtime.events.length - 1];
    out.tapeLocal = ev0.label === 'regul';
    out.emisAvant = JSON.stringify(shareSnap(Runtime, false).events.slice(-1));
    out.texteNEmisPas = out.emisAvant.indexOf('regul') < 0;

    if (chips[0]) chips[0].click();
    await new Promise(x => setTimeout(x, 350));
    const ev1 = Runtime.events[Runtime.events.length - 1];
    out.refPosee = JSON.stringify(ev1.ref || null);
    out.labelEfface = ev1.label === '';
    out.affiche = (document.querySelector('.tk-panel [data-tklab]') || {}).value;

    // LE CHEMIN COMPLET : on émet, on plie, on résout — c'est ce que fait l'appareil d'en face.
    const evs = shareDiff(shareSnap(null, false), shareSnap(Runtime, false))
      .map((e, i) => ({ seq: i + 1, id: 'z' + i, actor: 'hote', ...e }));
    const plie = shareFold(evs);
    const recu = plie.events[plie.events.length - 1];
    out.motRecu = tkLabels([recu], Runtime.fiche, myTags())[0];
    out.sansVocab = tkLabels([recu], Runtime.fiche, [])[0];
    out.rienDeTape = JSON.stringify(evs).indexOf('regul') < 0;
    return out;
  });
  t('taper propose des entrées RAPPROCHÉES', r.propositions.length > 0, JSON.stringify(r).slice(0, 200));
  t('… dont l’étiquette trouvée par son ALIAS', r.propositions.some(x => /Médecin régulateur/.test(x)), r.propositions.join(' | '));
  t('… cibles ≥ 44 px', r.cible44 === true);
  t('… et le « vous seul » est dit pendant un partage', r.persoSignalee === true, r.propositions.join(' | '));
  t('avant de choisir, le texte tapé reste LOCAL', r.tapeLocal === true);
  t('… et n’entre pas dans ce qui est émis (règle 15)', r.texteNEmisPas === true, r.emisAvant);
  t('choisir pose la référence', /"type":"tag"/.test(r.refPosee), r.refPosee);
  t('… et efface le libellé manuel', r.labelEfface === true);
  t('… l’écran affiche le mot résolu', r.affiche === 'Médecin régulateur', r.affiche);
  t('LE MOT ARRIVE CHEZ L’AUTRE', r.motRecu === 'Médecin régulateur', r.motRecu);
  t('… sans jamais faire voyager le texte tapé', r.rienDeTape === true);
  /* La résolution ÉCHOUE PROPREMENT chez qui n'a pas ce vocabulaire : « Action n », jamais un mot
     inventé. C'est la garantie qui autorise à faire voyager des références plutôt que des mots. */
  t('… et retombe sur « Action n » sans le vocabulaire', /^Action /.test(r.sansVocab), r.sansVocab);
  await page.close();
}
});

/* ── LA FIN DE LA SESSION EST LA FIN DU PARTAGE ──────────────────────────────────────────────
   Signalé à l'usage : l'hôte terminait sa session et la fenêtre continuait d'annoncer « Partage
   en cours ». Le partage survivait à la session qu'il reflétait — l'invité sondait un miroir que
   plus rien n'alimentait, et le code d'appariement restait vivant jusqu'à son terme. Un partage
   sans session n'a pas d'objet. */
await sec(`PARTAGE · terminer la session coupe le partage — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    let patchs = 0;
    Share._io.open = async () => ({ ok: true, share: 's1', code: 'K7M2P4Q9',
      join_open_until: new Date(Date.now() + 120e3).toISOString(),
      expires_at: new Date(Date.now() + 3600e3).toISOString(), server_time: new Date().toISOString() });
    Share._io.pull = async () => ({ ok: true, status: 'active', events: [], seq: 0, n_events: 0,
      participants: [{ id: 'p0', label: 'Hôte', role: 'lead', owner: true }],
      server_time: new Date().toISOString() });
    Share._io.push = async () => ({ ok: true, server_time: new Date().toISOString() });
    const vrai = window.rest;
    window.rest = async (m, u, b, h) => {
      if (/shared_sessions/.test(u) && m === 'PATCH') { patchs++; return {}; }
      return vrai(m, u, b, h); };
    Auth.signedIn = () => true;

    await startShare(state.fiche);
    await new Promise(x => setTimeout(x, 1200));
    const avant = { mode: Share.mode, sonde: !!Share._timer };
    endSession(Runtime);
    await new Promise(x => setTimeout(x, 600));
    return { avant, mode: Share.mode, share: Share.share, sonde: !!Share._timer, patchs };
  });
  t('témoin : le partage tournait bien', r.avant.mode === 'host' && r.avant.sonde === true, JSON.stringify(r.avant));
  t('terminer la session ferme le partage', r.mode === 'off', r.mode);
  t('… n’en garde pas l’identifiant', r.share === null, String(r.share));
  t('… arrête le sondage', r.sonde === false);
  /* L'arrêt est ANNONCÉ au serveur, mais jamais ATTENDU (règle 12) : fermer sa session ne dépend
     pas du réseau. Si le PATCH échoue, la ligne expirera et sera purgée — c'est à cela que sert un
     relais transitoire. */
  t('… et l’annonce au serveur est partie', r.patchs >= 1, `${r.patchs} PATCH`);
  await page.close();
}
});

/* ── UN PARTICIPANT NE PEUT PAS INJECTER DE BALISAGE CHEZ LES AUTRES ─────────────────────────
   Deux injections d'attribut ont été REPRODUITES avant correction, et elles empruntaient les deux
   routes distinctes par lesquelles un évènement distant atteint l'écran :
    · la PEINTURE (`sharePaintLive`, en direct) — elle normalisait déjà ;
    · le PLI (`shareFold` → `buildRuntime` → rendu) — il recopiait BRUT. C'est la route de tout
      invité qui REJOINT (il reçoit l'historique depuis le début) et de tout invité qui RECHARGE.
   Une barrière sur une branche et pas sur l'autre ne protège rien. La CSP à hashs empêche
   l'exécution d'un script injecté sur un navigateur à jour, mais `style-src 'unsafe-inline'` est
   accordé : du balisage et du CSS arbitraires dans la colonne d'action d'une réanimation — masquer
   une étape, en superposer une fausse — suffisent à qualifier le défaut. On mesure donc la SORTIE
   DE BALISE, pas l'exécution : c'est la propriété, l'exécution n'est qu'une de ses conséquences. */
await sec(`PARTAGE · aucun participant n'injecte de balisage — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    const out = {};
    const POISON = 'x"><span id="POISON_A">!</span><b z="';
    // ── Route 1 : LE PLI (invité qui rejoint ou recharge)
    const fold = shareFold([{ seq: 1, id: 'm1', actor: 'autre', kind: 'mark',
      payload: { id: POISON, t: Date.now(), ref: null } }]);
    out.pliIdBrut = fold.events[0].id === POISON;
    const f = state.fiche, sauve = Runtime;
    Runtime = buildRuntime(f, Object.assign({ shared: true }, fold));
    Runtime.started = true; Runtime.fiche = f;
    const html = timekeeperPanel();
    Runtime = sauve;
    const box = document.createElement('div'); box.innerHTML = html;
    out.pliBalise = !!box.querySelector('#POISON_A');

    // ── Route 2 : LA NAVIGATION, en direct, sans rechargement (régime « anchored »)
    const POISON_B = '1"><span id="POISON_B">!</span><i y="';
    const navAvant = Runtime.nav.slice();
    Share.mode = 'guest'; Share.role = 'scribe'; Share.me = 'inv'; Share.status = 'active';
    Share.lastOk = Date.now(); Share.offset = 0; Share._defer = [];
    Share.onEvents([{ seq: 2, id: 'n1', actor: 'hote', kind: 'nav',
      payload: { nav: navAvant.slice(), navSeq: navAvant.map(() => POISON_B) } }]);
    await new Promise(x => setTimeout(x, 450));
    out.navBalise = !!document.getElementById('POISON_B');
    out.navSeq = JSON.stringify(Runtime.navSeq);
    out.cle = (main.querySelector('[data-ck]') || {}).dataset ? main.querySelector('[data-ck]').dataset.ck : '';

    // ── Route 3 : les clés de cochage servent d'INDEX d'objet autant que d'attribut (règle 6).
    const f2 = shareFold([{ seq: 3, id: 'c1', actor: 'x', kind: 'check', payload: { k: '__proto__' } },
                          { seq: 4, id: 'c2', actor: 'x', kind: 'check', payload: { k: 'a"><b>:x:0' } },
                          { seq: 5, id: 'c3', actor: 'x', kind: 'check', payload: { k: '9:b1:0' } }]);
    out.clesRetenues = Object.keys(f2.checked);

    // ── Route 4 : identifiants de compteur et de minuteur, eux aussi index d'objet.
    const f3 = shareFold([{ seq: 6, id: 'k1', actor: 'x', kind: 'counter', payload: { id: '__proto__', v: 2 } },
      { seq: 7, id: 'k2', actor: 'x', kind: 'timer_arm', payload: { id: 'a"><b>', running: true } }]);
    out.compteurs = Object.keys(f3.counters);
    out.minuteurs = Object.keys(f3.timers);
    return out;
  });
  t('témoin : la sonde sait voir une balise étrangère', typeof r.pliBalise === 'boolean');
  t('le PLI n’accepte pas un identifiant brut', r.pliIdBrut === false);
  t('… et n’injecte aucune balise dans le journal', r.pliBalise === false, 'balise sortie du DOM');
  t('la NAVIGATION borne ses numéros de visite', r.navSeq === JSON.stringify([1]), r.navSeq);
  t('… et n’injecte aucune balise dans la checklist', r.navBalise === false, 'balise sortie du DOM');
  t('… la clé de cochage reste bien formée', /^\d+:[A-Za-z0-9_-]+:\d+$/.test(r.cle), r.cle);
  t('une clé de cochage difforme est écartée',
    r.clesRetenues.length === 1 && r.clesRetenues[0] === '9:b1:0', JSON.stringify(r.clesRetenues));
  t('… __proto__ compris (règle 6)', r.clesRetenues.indexOf('__proto__') < 0);
  t('un identifiant de compteur passe par safeId', r.compteurs.indexOf('__proto__') < 0, JSON.stringify(r.compteurs));
  t('… de minuteur aussi', /^[A-Za-z0-9_-]+$/.test(r.minuteurs[0] || ''), JSON.stringify(r.minuteurs));
  await page.close();
}
});

/* ── LA PASSATION DE LA MAIN — EN TROIS TEMPS, ET AUCUN ÉCRAN NE CHANGE SEUL ─────────────────
   Le scribe ne conduit pas : il ne navigue pas, n'arrête pas un minuteur, ne termine pas. C'est la
   forme canonique du travail à deux (AC 120-71B §5.2.2.1) — mais sans passation, quelqu'un qui a
   BESOIN de conduire n'a aucun recours, et l'asymétrie devient une impasse.
   Trois temps (AC 61-115 « Positive Exchange of Flight Controls ») : l'un PROPOSE, l'autre PREND,
   et le changement de rôle vaut confirmation. Invariant 2 : aucun écran ne change de capacité sans
   un geste effectué SUR CET écran — un `handoff` reçu n'accorde donc rien, il AFFICHE. */
await sec(`PARTAGE · la passation de la main — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    Share.mode = 'guest'; Share.role = 'scribe'; Share.me = 'inv'; Share.status = 'active';
    Share.lastOk = Date.now(); Share.offset = 0; Share._q = []; Share._defer = [];
    const out = {};
    const tok = () => (document.querySelector('.seg.glb') || {}).textContent || '';
    const menu = () => { try { return moreItemsForTest ? [] : []; } catch (e) { return []; } };
    out.avantJeton = tok();
    out.avantPeutDetruire = Share.canWrite('timer_reset');
    // Comptage RELATIF : l'amorçage produit une banderole légitime (« fiches d'exemple ajoutées »),
    // émise hors session. Un total absolu ferait échouer la sonde sur du bruit de démarrage.
    const toastsAvant = document.querySelectorAll('.toast').length;

    // TEMPS 1 — l'hôte propose. Rien ne doit changer de capacité, seulement d'affichage.
    Share.onEvents([{ seq: 1, id: 'h1', actor: 'hote', kind: 'handoff', payload: { to: 'inv' } }]);
    await new Promise(x => setTimeout(x, 350));
    out.apresOffreJeton = tok();
    out.apresOffreRole = Share.role;
    out.apresOffrePeutDetruire = Share.canWrite('timer_reset');
    out.toasts = document.querySelectorAll('.toast').length - toastsAvant;
    out.modales = document.querySelectorAll('.ai-modal.on').length;

    // TEMPS 2 — le geste est SUR SON écran, et il n'accorde rien : il annonce.
    const avantQ = Share.pending();
    const pris = Share.takeLead();
    out.pris = pris;
    out.emisPrise = Share.pending() > avantQ;
    out.roleApresPrise = Share.role;   // TOUJOURS scribe : le rôle vient du serveur

    // TEMPS 3 — le serveur inscrit, et c'est la lecture suivante qui l'apprend.
    Share.role = 'lead';
    out.apresServeurJeton = tok.call ? (Share.mode !== 'off' ? shareGlobTag() : '') : '';
    out.peutDetruireEnfin = Share.canWrite('timer_reset');
    return out;
  });
  t('témoin : un scribe ne peut pas remettre à zéro', r.avantPeutDetruire === false);
  t('l’offre se dit dans le QUAI, à position constante', r.apresOffreJeton.indexOf('offert') >= 0, r.apresOffreJeton);
  t('… sans rien accorder (invariant 2)', r.apresOffreRole === 'scribe' && r.apresOffrePeutDetruire === false);
  t('… sans banderole ni fenêtre (règle 11)', r.toasts === 0 && r.modales === 0);
  t('prendre la main est un geste LOCAL', r.pris === true);
  t('… qui ANNONCE au lieu de s’accorder', r.emisPrise === true && r.roleApresPrise === 'scribe');
  t('le rôle ne vient que du serveur', r.apresServeurJeton === 'main', r.apresServeurJeton);
  t('… et alors seulement le geste destructeur s’ouvre', r.peutDetruireEnfin === true);
  await page.close();
}
});

await sec(`PARTAGE · le menu suit, le lien mort refuse — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    const f = fiches.find(x => /Arrêt/.test(x.title)) || fiches[0];
    Share._io.join = async () => ({ ok: true, share: 's1', secret: 'x'.repeat(24), me: 'p1',
      role: 'scribe', fiche: sharePayload(f), server_time: new Date().toISOString() });
    Share._io.pull = async () => ({ ok: true, status: 'active', events: [], seq: 0, n_events: 0,
      participants: [], server_time: new Date().toISOString() });
    Share._io.push = async () => ({ ok: true, server_time: new Date().toISOString() });
    openJoinScreen('K7M2P4Q9'); await joinGo(); await new Promise(x => setTimeout(x, 500));
    const lire = () => { openMoreMenu();
      const t = [...document.querySelectorAll('#moreMenu .mm-row')].map(b => b.textContent.trim());
      closeMoreMenu(); return t; };
    const out = { avant: lire(), toastsAvant: document.querySelectorAll('.toast').length };

    /* 1 — UNE OFFRE ARRIVE. Le menu doit gagner sa rangée SANS que la checklist soit re-rendue :
       on relève un témoin visible avant/après pour le prouver. */
    const tem = main.querySelector('[data-ck]');
    const y0 = tem ? Math.round(tem.getBoundingClientRect().top) : null;
    Share.onEvents([{ seq: 1, id: 'h1', actor: 'hote', kind: 'handoff', payload: { to: 'p1' } }]);
    await new Promise(x => setTimeout(x, 350));
    out.apres = lire();
    const tem2 = main.querySelector('[data-ck]');
    out.derive = (y0 !== null && tem2) ? Math.round(tem2.getBoundingClientRect().top) - y0 : 0;
    out.memeNoeud = tem === tem2;      // la checklist n'a PAS été reconstruite

    /* 2 — LE LIEN MORT REFUSE TOUT, ET LE DIT. Le compteur est un geste ADDITIF, donc ouvert au
       scribe tant que le lien vit : c'est exactement le cas qui passait à travers. */
    /* LE COMPTEUR VIT DANS UN PANNEAU REPLIÉ sous le seuil du rail : sans cette ouverture, la
       sonde ne trouve aucun bouton et conclut que le geste est bloqué — alors qu'elle n'a rien
       mesuré du tout. Même oubli que dans le bloc de bridage, et même remède. */
    { state.rtOpen = true; render(); await new Promise(x => setTimeout(x, 400)); }
    Share.status = 'revoked';
    // On vide la zone d'annonce : elle porte encore le message de l'offre reçue plus haut, et
    // `announce` écrit avec 30 ms de retard — lire trop tôt, c'est lire le message précédent.
    { const z = document.getElementById('srLive'); if (z) z.textContent = ''; }
    const inc = document.querySelector('[data-cninc]');
    let cA = null, cB = null;
    if (inc) { const id = inc.dataset.cninc; cA = Runtime.counters[id];
      inc.click(); await new Promise(x => setTimeout(x, 400)); cB = Runtime.counters[id]; }
    out.compteurFige = (cA === cB);
    out.annonce = (document.getElementById('srLive') || {}).textContent || '';
    out.toasts = document.querySelectorAll('.toast').length - out.toastsAvant;
    out.modales = document.querySelectorAll('.ai-modal.on').length;

    /* … mais un DÉTACHÉ garde ses gestes : il travaille sur SA session, et lui les refuser serait
       lui retirer le repli hors dispositif qu'on vient de lui donner (AC 120-64 §9.a). */
    Share.status = 'detached';
    let dA = null, dB = null;
    const inc2 = document.querySelector('[data-cninc]');
    if (inc2) { const id = inc2.dataset.cninc; dA = Runtime.counters[id];
      inc2.click(); await new Promise(x => setTimeout(x, 400)); dB = Runtime.counters[id]; }
    out.detacheTravaille = (dB > dA);
    return out;
  });
  t('témoin : « Prendre la main » n’est pas là au départ',
    !r.avant.some(x => /Prendre la main/i.test(x)), r.avant.join(' | '));
  t('une offre distante FAIT APPARAÎTRE la rangée',
    r.apres.some(x => /Prendre la main/i.test(x)), r.apres.join(' | '));
  t('… sans reconstruire la checklist', r.memeNoeud === true);
  t('… et sans rien déplacer (≤ 1 px)', Math.abs(r.derive) <= 1, `${r.derive} px`);
  t('coupé : un compteur ne bouge plus', r.compteurFige === true);
  t('… et le refus est ANNONCÉ', /retiré|transmis/i.test(r.annonce), r.annonce);
  t('… sans banderole ni fenêtre (règle 11)', r.toasts === 0 && r.modales === 0);
  t('mais un DÉTACHÉ continue de travailler', r.detacheTravaille === true);
  await page.close();
}
});

/* ── LE PLACARD DE L'INVITÉ, ET LES RÉPONSES QUI NE SE PERDENT PLUS ──────────────────────────
   Deux derniers signalements. (1) L'invité lisait « ■ Mode crise » — exactement ce que lit l'hôte —
   alors que sa situation est autre : il SUIT une session qu'il ne conduit pas et qui peut s'arrêter
   sans lui. (2) La règle 11 (« aucune notification flottante en session ») vise ce qui ARRIVE ;
   elle retenait aussi la RÉPONSE à un bouton qu'on venait de presser, si bien que le message
   surgissait à l'accueil, détaché de son geste. */
await sec(`PARTAGE · le placard de l'invité et les réponses directes — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    const o = {};
    const band = document.getElementById('crisisBand');
    const tag = () => (band.querySelector('.cb-tag') || {}).textContent || '';
    const hach = el => getComputedStyle(el, '::before').opacity;
    o.hoteTag = tag(); o.hoteHachure = hach(band);
    /* v5.6 (A14) : l'énoncé du mode a quitté la pilule de droite pour le SUR-TITRE, dans la
       zone d'identité — un seul énoncé, du côté où l'œil arrive. */
    o.hoteEnTete = (document.getElementById('brandSur') || {}).textContent || '';

    // On passe en INVITÉ par le vrai chemin d'affichage : le placard suit un rendu.
    Share.mode = 'guest'; Share.role = 'scribe'; Share.me = 'inv'; Share.status = 'active';
    Share.lastOk = Date.now(); Share.offset = 0;
    render(); await new Promise(x => setTimeout(x, 450));
    o.inviteTag = tag();
    o.inviteHachure = hach(band);
    /* LA COULEUR DE L'ÉTIQUETTE, mesurée et non supposée (v4.76.0) : `#crisisBand .cb-tag` vaut
       (1,1,0) et écrasait le bleu du placard invité, écrit en (0,2,0) — « ▪ Vous suivez » sortait
       donc en ROUGE, dans le seul registre qu'elle ne devait pas emprunter, depuis la v4.55.4.
       On compare à `--primary-dk` résolu, jamais à une chaîne en dur. */
    {const el = band.querySelector('.cb-tag');
     const attendu = getComputedStyle(document.documentElement).getPropertyValue('--primary-dk').trim();
     const bidon = document.createElement('span'); bidon.style.color = attendu;
     document.body.appendChild(bidon);
     o.inviteCouleur = getComputedStyle(el).color;
     o.inviteCouleurAttendue = getComputedStyle(bidon).color;
     bidon.remove();}
    o.inviteEnTete = (document.getElementById('brandSur') || {}).textContent || '';
    o.hauteurBandeau = Math.round(band.getBoundingClientRect().height);

    /* L'EXERCICE GARDE LA PRIORITÉ : « ceci est une répétition » prime sur « vous suivez ». Le
       premier protège d'une méprise clinique ; le second est une information de rôle, que le quai
       porte en permanence de toute façon. */
    Runtime.exercise = true; Runtime.ficheId = state.fiche.id;
    render(); await new Promise(x => setTimeout(x, 400));
    o.exoGagne = tag();
    Runtime.exercise = false; render(); await new Promise(x => setTimeout(x, 350));
    o.hauteurInvite = Math.round(band.getBoundingClientRect().height);

    // (2) Une réponse DIRECTE s'affiche pendant un soin ; une nouvelle de fond reste retenue.
    document.querySelectorAll('.toast').forEach(t => t.remove());
    o.enCrise = document.body.classList.contains('crisis-live');
    toast('nouvelle de fond', 3000);
    await new Promise(x => setTimeout(x, 200));
    o.fondAffiche = document.querySelectorAll('.toast').length;
    toast('réponse à votre geste', 3000, true);
    await new Promise(x => setTimeout(x, 200));
    o.directAffiche = document.querySelectorAll('.toast').length;
    return o;
  });
  /* v4.70.1 — LE TÉMOIN A CHANGÉ DE PROPRIÉTÉ, PAS DE SUJET. Il lisait « l'hôte affiche
     "Mode crise" » ; la barre et le bandeau disaient alors la même chose deux fois. Ce qu'il
     vérifie maintenant est l'invariant réel : en crise ORDINAIRE le bandeau n'annonce AUCUNE
     exception (étiquette vide, pas de hachure) et le mode est dit UNE fois, par la barre. */
  t('témoin : l’hôte n’annonce aucune exception (bandeau nu, sans hachure)',
    r.hoteTag === '' && r.hoteHachure === '0', `«${r.hoteTag}» / ${r.hoteHachure}`);
  t('… et le mode est dit UNE fois, par le sur-titre', /Mode crise/.test(r.hoteEnTete)
    && !/Mode crise/i.test(r.hoteTag), `${r.hoteEnTete} / «${r.hoteTag}»`);
  t('l’invité lit « Vous suivez »', /Vous suivez/.test(r.inviteTag), r.inviteTag);
  t('… et son étiquette est BLEUE, pas rouge', r.inviteCouleur===r.inviteCouleurAttendue,
    `${r.inviteCouleur} au lieu de ${r.inviteCouleurAttendue}`);
  t('… le bandeau est hachuré', r.inviteHachure === '1', r.inviteHachure);
  t('… et le sur-titre le dit aussi', /Vous suivez/.test(r.inviteEnTete), r.inviteEnTete);
  t('… à COÛT NUL en hauteur', r.hauteurInvite === r.hauteurBandeau,
    `${r.hauteurBandeau} → ${r.hauteurInvite} px`);
  t('l’exercice garde la priorité sur le placard d’invité', /Exercice/.test(r.exoGagne), r.exoGagne);
  t('témoin : une session de crise est bien à l’écran', r.enCrise === true);
  t('une nouvelle de fond reste RETENUE (règle 11)', r.fondAffiche === 0, `${r.fondAffiche} banderole(s)`);
  t('… mais une réponse à un geste S’AFFICHE', r.directAffiche === 1, `${r.directAffiche} banderole(s)`);

  /* LE COÛT DU PLACARD SE MESURE À 320 px, PAS AILLEURS (v4.70.1). Depuis que la crise ORDINAIRE
     n'affiche plus d'étiquette, le placard de l'invité est le seul objet de sa rangée — il peut
     donc, sur un titre long, pousser le titre à la ligne. La largeur où cela compterait est celle
     où `#crisisCtrl` n'a que 2,1 px de marge : à 320 px le titre occupe DÉJÀ deux lignes dans les
     deux cas, le coût y est donc nul. Au-dessus, la place existe verticalement — et l'entrée en
     mode invité n'est jamais une transition SUR PLACE (on arrive par l'écran d'entrée ; un lien
     coupé passe par `freeze`, qui garde `mode === 'guest'`). */
  await page.setViewportSize({ width: 320, height: 844 });
  /* ⚠ TÉMOIN REMIS SUR SON SUJET (v5.0.0). Il comparait la hauteur du bandeau chez l'HÔTE et
     chez l'INVITÉ — or depuis que le bandeau ne subsiste QUE pour les modes d'exception, l'hôte
     n'en a plus du tout : le contrôle mesurait alors l'EXISTENCE du bandeau, pas le coût du
     PLACARD, et il aurait rougi pour la mauvaise raison. Ce que la doctrine affirme est que
     l'étiquette « ▪ Vous suivez » et sa hachure n'ajoutent AUCUNE hauteur au bandeau qui les
     porte : on compare donc le bandeau de l'invité AVEC et SANS son étiquette, à 320 px, où le
     titre occupe déjà deux lignes. C'est la même affirmation, mesurée sur le bon objet. */
  const cout = await page.evaluate(async () => {
    const band = document.getElementById('crisisBand');
    const H = () => Math.round(band.getBoundingClientRect().height * 10) / 10;
    Share.mode = 'guest'; Share.role = 'scribe'; Share.me = 'i'; Share.status = 'active';
    Share.lastOk = Date.now(); Share.offset = 0;
    render(); await new Promise(x => setTimeout(x, 350));
    const avec = H();
    const tg = band.querySelector('.cb-tag');
    const vu = tg && !tg.hidden;                       // le contrôle rencontre-t-il son cas ?
    if (tg) tg.hidden = true;
    band.classList.remove('inv');
    await new Promise(x => setTimeout(x, 250));
    const sans = H();
    if (tg) tg.hidden = false; band.classList.add('inv');
    return { avec, sans, vu, present: H() > 0 };
  });
  t('témoin : l’invité a bien un bandeau ET son étiquette', cout.present && cout.vu === true,
    JSON.stringify(cout));
  t('le placard ne coûte RIEN à 320 px, la largeur qui compte',
    cout.avec === cout.sans, `${cout.sans} → ${cout.avec} px`);
  await page.close();
}
});

/* LE MENU ⋯ SOUS UN PLACARD (v4.55.5, signalé à l'usage). Le placard levait TOUS les enfants
   directs de l'en-tête en `position:relative` pour les faire passer au-dessus de sa hachure — or
   `.more-menu` est un enfant direct, et il se positionne LUI-MÊME. La règle valait (0,2,1) contre
   (0,1,0) : le menu retombait dans le flux de la barre et s'y ouvrait au lieu de flotter dessous.
   ON MESURE LA POSITION CALCULÉE ET LA GÉOMÉTRIE, PAS LA PRÉSENCE D'UNE CLASSE : c'est le fait de
   flotter qui est en cause, pas l'intention de le faire flotter. Et on mesure la hachure par son
   IMAGE DE FOND, jamais par l'opacité seule — sur un en-tête SANS placard le pseudo-élément n'a
   pas de `content`, et `getComputedStyle` rend alors l'opacité par défaut 1 : un témoin fondé sur
   l'opacité serait vert des deux côtés et ne prouverait rien. */
await sec(`PARTAGE · le menu ⋯ reste flottant sous un placard — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const mesure = await page.evaluate(async () => {
    const out = {};
    const h = document.querySelector('header.bar');
    const lire = async (placard) => {
      h.classList.remove('exo', 'inv', 'ttl-on');
      if (placard) h.classList.add(placard, 'ttl-on');
      await new Promise(x => setTimeout(x, 400));
      openMoreMenu(); await new Promise(x => setTimeout(x, 250));
      const m = document.getElementById('moreMenu');
      const mr = m.getBoundingClientRect(), hr = h.getBoundingClientRect();
      const av = getComputedStyle(h, '::before');
      const r = { pos: getComputedStyle(m).position,
        sousEnTete: +(mr.top - hr.bottom).toFixed(1),
        // hachure RÉELLE : un dégradé peint, pas une opacité par défaut
        hachure: /gradient/.test(av.backgroundImage) && av.opacity === '1',
        // le menu ne doit pas gonfler la barre : dans le flux, il l'aurait rallongée
        hauteurEnTete: +hr.height.toFixed(1) };
      closeMoreMenu(); await new Promise(x => setTimeout(x, 150));
      return r; };
    out.nu = await lire(null);
    out.exo = await lire('exo');
    out.inv = await lire('inv');
    return out;
  });
  const { nu, exo, inv } = mesure;
  t('témoin : sans placard, le menu flotte sous l’en-tête',
    nu.pos === 'absolute' && nu.sousEnTete > 0, `${nu.pos} / +${nu.sousEnTete} px`);
  t('témoin : sans placard, aucune hachure n’est peinte', nu.hachure === false);
  for (const [nom, m] of [['exercice', exo], ['invité', inv]]) {
    t(`placard ${nom} : la hachure est bien peinte`, m.hachure === true);
    t(`placard ${nom} : le menu ⋯ reste hors du flux`, m.pos === 'absolute', m.pos);
    t(`placard ${nom} : … et s’ouvre SOUS l’en-tête`, m.sousEnTete > 0, `${m.sousEnTete} px`);
    t(`placard ${nom} : … sans rallonger la barre`,
      Math.abs(m.hauteurEnTete - nu.hauteurEnTete) <= 1,
      `${nu.hauteurEnTete} → ${m.hauteurEnTete} px`);
  }
  await page.close();
}
});

/* « AVANCÉ PAR … » NE SUIT PLUS CELUI QUI AVANCE (v4.55.5, signalé à l'usage). La mention était un
   drapeau global qu'un SEUL site effaçait (`cxEnter`) : posée une fois — typiquement par le
   backlog rattrapé à la jointure, où toutes les navigations de l'hôte défilent d'un coup — elle
   suivait ensuite l'invité de carte en carte et attribuait à « Hôte » les blocs qu'il venait
   lui-même d'avancer. Elle est désormais AMARRÉE au numéro de visite créé par l'avance distante.
   LE CONTRÔLE CONSTRUIT LE CAS : une avance distante, PUIS une avance locale — le défaut ne se
   voit qu'à la seconde, et un contrôle qui s'arrêterait à la première serait vert avec le défaut
   en place. */
await sec(`PARTAGE · l'attribution ne survit pas à un geste local — moteur ${NOM_MOTEUR}`, async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    const o = {};
    Share._io.push = async () => ({ ok: true, server_time: new Date().toISOString() });
    Share.mode = 'guest'; Share.role = 'lead'; Share.me = 'pInv'; Share.status = 'active';
    Share.lastOk = Date.now(); Share.offset = 0;
    // La liste telle que le serveur la renvoie : l'hôte y porte « Hôte » (schema.sql).
    Share.participants = [{ id: 'pHote', label: 'Hôte', role: 'lead', owner: true },
                          { id: 'pInv', label: 'Infirmier', role: 'scribe', owner: false }];
    const f = Runtime.fiche;
    const suite = id => { const b = f.blocks.find(x => x.id === id); return (b && b.next) || null; };
    const mention = () => (document.querySelector('.ov-by') || {}).textContent || '';

    const b1 = suite(state.nav[state.nav.length - 1]) || f.blocks[1].id;
    Share.onEvents([{ seq: 1, id: 'n1', actor: 'pHote', kind: 'nav',
      payload: { nav: [...state.nav, b1], navSeq: [...state.navSeq, (Math.max(...state.navSeq) || 0) + 1] } }]);
    await new Promise(x => setTimeout(x, 600));
    o.distante = mention();

    /* … puis L'INVITÉ avance LUI-MÊME. C'est ici que le défaut vivait, et il faut donc que
       l'avance ait VRAIMENT lieu : `next` est nul sur le dernier bloc de la fiche d'exemple, et
       s'y fier laissait les deux contrôles suivants mesurer du vide en restant verts. On prend
       n'importe quel bloc DIFFÉRENT du bloc courant — c'est un passage valide dans un journal
       append-only, et c'est le cas qu'on veut construire. */
    const b2 = suite(b1) || (f.blocks.find(x => x && x.id !== b1) || {}).id;
    o.cible = !!b2 && b2 !== b1;
    if (o.cible) {
      state.nav.push(b2); state.navSeq.push(++Runtime.seq); state.navPos = state.nav.length - 1;
      renderOvOnly(); await new Promise(x => setTimeout(x, 350));
      o.locale = mention(); }

    // Puis l'hôte avance ENCORE : la mention doit revenir — sinon on aurait « corrigé » en la
    // tuant définitivement, ce qui vaudrait aussi peu que de la laisser traîner.
    const b3 = (f.blocks.find(x => x && x.id !== b2) || {}).id;
    Share.onEvents([{ seq: 2, id: 'n2', actor: 'pHote', kind: 'nav',
      payload: { nav: [...state.nav, b3], navSeq: [...state.navSeq, ++Runtime.seq] } }]);
    await new Promise(x => setTimeout(x, 600));
    o.retour = mention();
    return o;
  });
  t('une avance DISTANTE nomme son auteur', /avancé par Hôte/.test(r.distante), r.distante || '(aucune)');
  t('témoin : la fiche a bien un bloc suivant', r.cible === true);
  t('… et la mention DISPARAÎT dès que j’avance moi-même',
    r.locale === '', r.locale || '(aucune)');
  t('… mais elle REVIENT si l’autre avance de nouveau',
    /avancé par Hôte/.test(r.retour), r.retour || '(aucune)');
  await page.close();
}
});

/* ══ v5.6 — UN LOT N'EST JAMAIS PERDU, MÊME QUAND L'HÔTE REGARDE AILLEURS ═══════════════════
   Signalé à l'usage : « en session partagée, les blocs des étapes disparaissent par moments chez
   l'hôte et ne réapparaissent pas ». La cause était un ABANDON, et la perte était DÉFINITIVE :
   `onEvents` sortait sans rien appliquer dès que la vue n'était pas `read`, alors que le curseur
   est avancé par l'appelant AVANT cet appel — le lot ne serait donc jamais relu. Il suffisait que
   l'hôte revienne à la bibliothèque, ouvre un éditeur ou consulte une autre aide pendant que le
   collègue avance pour que ces gestes soient perdus pour toujours, et l'écran, à son retour,
   montrait un parcours amputé que plus rien ne réparait.
   L'ÉTAT S'APPLIQUE TOUJOURS ; SEULE LA PEINTURE DÉPEND DE LA VUE. Le commentaire d'origine disait
   « le pli suffit » : c'est vrai chez l'INVITÉ, dont l'état EST le pli ; chez l'hôte la session
   locale fait autorité et rien ne la rattrape. */
await sec('v5.6 · un lot distant n\'est jamais perdu', async () => {
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 }, hasTouch: true });
  page.on('pageerror', e => { ko++; console.log('  ✗ ERREUR PAGE : ' + e.message); });
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(() => !document.querySelector('.boot-load'));
  await amorce(page);
  const r = await page.evaluate(async () => {
    const w = m => new Promise(x => setTimeout(x, m));
    const f = fiches.find(x => /Arrêt cardiaque/.test(x.title));
    openRead(f.id); await w(450);
    document.getElementById('sessStart').click(); await w(500);
    const dep = { nav: state.nav.length, cartes: main.querySelectorAll('.ov-block').length };
    /* L'hôte quitte la fiche — c'est le cas signalé, et le seul où le défaut se produisait. */
    document.getElementById('hdrBack').click(); await w(650);
    const horsEcran = state.view;
    /* Le collègue avance DEUX fois pendant ce temps. */
    let s = 900;
    Share.onEvents([{ seq: s++, id: 'z1', actor: 'autre', kind: 'nav',
      payload: { nav: [Runtime.nav[0], f.blocks[1].id],
                 navSeq: [Runtime.navSeq[0], (Runtime.seq || 1) + 1] } }]);
    await w(200);
    Share.onEvents([{ seq: s++, id: 'z2', actor: 'autre', kind: 'nav',
      payload: { nav: [Runtime.nav[0], f.blocks[1].id, f.blocks[2].id],
                 navSeq: [...Runtime.navSeq, (Runtime.seq || 1) + 1] } }]);
    await w(300);
    const applique = Runtime.nav.length;
    const resteAilleurs = state.view;      // aucun rendu ne doit nous ramener sur la fiche
    openRead(f.id); await w(800);
    return { dep, horsEcran, applique, resteAilleurs,
             retour: { nav: state.nav.length, cartes: main.querySelectorAll('.ov-block').length } };
  });

  t('témoin : la session est démarrée et l\'hôte quitte bien la fiche',
    r.dep.nav === 1 && r.horsEcran !== 'read', JSON.stringify(r));
  t('les avances distantes sont APPLIQUÉES même hors écran',
    r.applique === 3, `${r.applique} bloc(s) dans Runtime.nav`);
  /* La contrepartie, et c'est elle qui rend l'application hors écran admissible : on n'arrache
     personne à la page qu'il regarde. */
  t('… sans ramener l\'hôte sur la fiche', r.resteAilleurs !== 'read', r.resteAilleurs);
  t('… et le parcours est COMPLET au retour', r.retour.nav === 3 && r.retour.cartes >= 1,
    JSON.stringify(r.retour));
  await page.close();
}
});


/* ═══ v5.14.9 — BASCULE EN LIGNE ⇄ EN DIRECT SANS RE-SCAN (E2E, signalé : « tous les
   participants sont déconnectés » ; « inversement non plus »').
   Deux PAGES réelles (hôte, invité) dans le même contexte, un relais en mémoire (slHub +
   BroadcastChannel) qui joue Supabase, et de VRAIS RTCPeerConnection entre les deux pages :
   le secours chaud s'apparie en silence, puis le tap « En direct » emporte l'invité SANS QR,
   puis « En ligne » le ramène SANS re-saisie (billet « gc » par le canal). Le flux COMPLET —
   aucune brique applicative simulée ; seul le transport serveur est remplacé, comme partout
   dans ce harnais. */
await sec('v5.14.9 · bascule en ligne⇄direct : les canaux dormants portent les deux sens', async () => {
  /* Chromium HEADLESS masque les IP locales derrière des noms mDNS mais ne fait tourner AUCUN
     répondeur mDNS : les candidats sont irrésolubles entre deux pages et ICE échoue à coup sûr —
     un artefact du banc, pas de l'application (Safari/Chrome de production embarquent Bonjour).
     On lève l'obfuscation ICI SEULEMENT ; WebKit ne la pratique pas. */
  const brE = NOM_MOTEUR === 'chromium'
    ? await moteur().launch({ args: ['--disable-features=WebRtcHideLocalIpsWithMdns'] })
    : br;
  const ctx = await brE.newContext({ viewport: { width: 390, height: 844 } });
  const H = await ctx.newPage();
  await session(H);
  const G = await ctx.newPage();
  await G.goto(`http://localhost:${port}/index.html`);
  /* PAS `amorce()` ici : les deux pages PARTAGENT le contexte (BroadcastChannel l'exige), donc
     le stockage amorcé par l'hôte — l'écran de bienvenue n'existe plus pour la seconde page.
     L'invité n'a besoin que d'une app démarrée. */
  await G.waitForFunction(() => typeof Share === 'object' && typeof openSharedFiche === 'function',
    null, { timeout: 15000 });

  // Le relais : un hub en mémoire dans la page HÔTE + un guichet BroadcastChannel pour l'invité.
  await H.evaluate(() => {
    window.__cloudEnded = 0;
    const hub = slHub({ now: () => Date.now(), uid: (() => { let n = 0; return () => 'r' + (++n); })(),
      secret: (() => { let n = 0; return () => 'sec' + (++n); })(),
      shareId: 'bus1', fiche: null, guestRole: 'scribe', hostLabel: 'Hôte' });
    const io = {
      open: async () => ({ ok: true, share: 'bus1', code: 'AAAA2222',
        join_open_until: new Date(Date.now() + 120e3).toISOString(),
        expires_at: new Date(Date.now() + 3600e3).toISOString(), server_time: new Date().toISOString() }),
      admit: async () => ({ ok: true, code: 'BBBB3333',
        join_open_until: new Date(Date.now() + 120e3).toISOString(), server_time: new Date().toISOString() }),
      join: async (code, label) => hub.join(label),
      pull: async (s, sh, since) => hub.pull(hub.hostSecret(), since),
      push: async (s, sh, ev) => hub.push(hub.hostSecret(), ev),
      revoke: async (sh, pid) => hub.revoke(pid),
      setRole: async (sh, pid, role) => hub.setRole(pid, role),
      /* `end` compte au lieu d'agir : en production il vise l'ANCIEN identifiant de partage,
         sans effet sur le nouveau — un hub unique ne sait pas jouer cette distinction. */
      end: async () => { window.__cloudEnded++; return { ok: true }; } };
    Share._io = io; Share._ioRest = io; Auth.signedIn = () => true;
    const bc = new BroadcastChannel('acbus');
    bc.onmessage = async ev => { const m = ev.data || {}; if (!m.q) return; let r = null;
      try {
        if (m.v === 'join') r = hub.join(m.p.label);
        else if (m.v === 'pull') r = await hub.pull(m.p.secret, m.p.since);
        else if (m.v === 'push') r = hub.push(m.p.secret, m.p.events);
      } catch (e) {}
      bc.postMessage({ i: m.i, r }); };
    window.__bc = bc;
    confirmDlg = async () => true;
  });
  await G.evaluate(() => {
    const bc = new BroadcastChannel('acbus'); let n = 0; const pend = {};
    bc.onmessage = ev => { const m = ev.data || {}; if (m.q || !pend[m.i]) return;
      const w = pend[m.i]; delete pend[m.i]; w(m.r); };
    const call = (v, p) => new Promise(res => { const i = ++n; pend[i] = res;
      bc.postMessage({ q: 1, i, v, p });
      setTimeout(() => { if (pend[i]) { delete pend[i]; res(null); } }, 4000); });
    const io = { open: async () => null, admit: async () => null,
      join: (code, label) => call('join', { label }),
      pull: (s, sh, since) => call('pull', { secret: s, since }),
      push: (s, sh, ev) => call('push', { secret: s, events: ev }),
      revoke: async () => null, setRole: async () => null, end: async () => null };
    Share._io = io; Share._ioRest = io; Auth.signedIn = () => true;
    confirmDlg = async () => true;
  });

  await H.evaluate(async () => { await startShare(Runtime.fiche); });
  const j = await G.evaluate(async () => {
    const r = await Share.joinByCode('AAAA2222', 'IADE').catch(e => ({ ok: false, err: String(e) }));
    if (r && r.ok) openSharedFiche();
    return r; });
  t('l\'invité rejoint le relais', !!(j && j.ok), JSON.stringify(j));

  /* Le secours chaud doit s'apparier TOUT SEUL — offre `sig` de l'invité, réponse de l'hôte,
     ICE réel entre les deux pages. */
  const pretH = await H.waitForFunction(() =>
    slSb.dcs.some(d => d.dc && d.dc.readyState === 'open'), null, { timeout: 30000 })
    .then(() => true).catch(() => false);
  const pretG = pretH && await G.waitForFunction(() => !!slSb.dc, null, { timeout: 10000 })
    .then(() => true).catch(() => false);
  t('le canal dormant s\'apparie en silence (vrais RTCPeerConnection)', pretH && pretG,
    'hôte:' + pretH + ' invité:' + pretG);
  const dot = await H.evaluate(() => {
    const b = document.querySelector('#shareBody .seg-btn[data-shmode="direct"] .sdot');
    return b ? b.classList.contains('ok') : null; });
  t('la pastille « En direct » dit que le canal est prêt', dot === true, String(dot));

  /* Le TAP « En direct » : l'hôte bascule, l'invité SUIT — personne ne scanne. */
  await H.click('#shareBody .seg-btn[data-shmode="direct"]');
  const basH = await H.waitForFunction(() => Share.share === 'local' && SL && SL.live === true,
    null, { timeout: 20000 }).then(() => true).catch(() => false);
  const basG = basH && await G.waitForFunction(() =>
    Share._io !== Share._ioRest && Share.status === 'active' && Share.share && Share.share !== 'bus1',
    null, { timeout: 20000 }).then(() => true).catch(() => false);
  const endTot = await H.evaluate(() => window.__cloudEnded);
  t('« En direct » : l\'hôte bascule sur le hub local', basH, '');
  t('… et l\'invité SUIT par son canal dormant, sans QR', basG, '');
  t('le partage cloud n\'est terminé qu\'en DIFFÉRÉ (le « go » a le temps de partir)',
    endTot === 0, 'end=' + endTot);
  const titreG = await G.evaluate(() => (Runtime && Runtime.fiche && Runtime.fiche.title) || null);
  const titreH = await H.evaluate(() => (Runtime && Runtime.fiche && Runtime.fiche.title) || null);
  t('l\'état complet a voyagé par le canal (même fiche des deux côtés)',
    !!titreG && titreG === titreH, titreG + ' vs ' + titreH);

  /* Le TAP « En ligne » : billet « gc » par le canal, personne ne ressaisit de code. */
  await H.click('#shareBody .seg-btn[data-shmode="cloud"]');
  const revH = await H.waitForFunction(() => Share.share === 'bus1' && Share.mode === 'host' && !SL,
    null, { timeout: 40000 }).then(() => true).catch(() => false);
  const revG = revH && await G.waitForFunction(() =>
    Share._io === Share._ioRest && Share.share === 'bus1' && Share.status === 'active',
    null, { timeout: 20000 }).then(() => true).catch(() => false);
  t('« En ligne » : l\'hôte repasse par le serveur', revH, '');
  t('… et l\'invité le rejoint avec le billet « gc », sans re-saisie', revG, '');

  /* PHASE 3 — LA PANNE BRUTALE (la question de terrain : « si perte de réseau brutale, le
     canal direct sera-t-il réellement transmis ? »). Le secours chaud doit s'être RE-FORMÉ
     après le retour en ligne (ardoise propre + re-proposition automatique), puis le relais
     MEURT d'un coup : les deux côtés doivent se retrouver en direct SANS AUCUN geste. */
  const rearmH = revG && await H.waitForFunction(() =>
    slSb.dcs.some(d => d.dc && d.dc.readyState === 'open'), null, { timeout: 30000 })
    .then(() => true).catch(() => false);
  const rearmG = rearmH && await G.waitForFunction(() => !!slSb.dc, null, { timeout: 10000 })
    .then(() => true).catch(() => false);
  t('le secours chaud se RE-FORME après le retour en ligne', rearmH && rearmG,
    'hôte:' + rearmH + ' invité:' + rearmG);


  await H.evaluate(() => { window.__panne = true;
    const io = Share._io;
    Share._io = Object.assign({}, io, {
      pull: async () => { throw new Error('panne'); },
      push: async () => { throw new Error('panne'); } });
    Share._ioRest = Share._io;
    window.__bc.onmessage = () => {};   // le relais ne répond plus à l'invité non plus
  });
  const autoH = await H.waitForFunction(() => Share.share === 'local' && SL && SL.live === true,
    null, { timeout: 40000 }).then(() => true).catch(() => false);
  const autoG = autoH && await G.waitForFunction(() =>
    Share._io !== Share._ioRest && Share.status === 'active' && Share.share !== 'bus1',
    null, { timeout: 40000 }).then(() => true).catch(() => false);
  t('PANNE BRUTALE du relais : l\'hôte bascule TOUT SEUL en direct', autoH, '');
  t('… et l\'invité le suit TOUT SEUL par le canal dormant — zéro geste', autoG, '');
  await ctx.close();
  if (brE !== br) await brE.close();
});

const bilanSec = sec.bilan();
await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles partage OK` + (ko ? ` — ${ko} ÉCHEC(S)` : '')
  + (bilanSec.partiel ? ` — PARTIEL (${bilanSec.joues}/${bilanSec.total} sections)` : ''));
process.exit(ko ? 1 : 0);
