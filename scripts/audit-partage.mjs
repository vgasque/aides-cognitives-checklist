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
import { serveApp, moteur, NOM_MOTEUR } from './harness.mjs';

const { port, srv } = await serveApp();
const br = await moteur().launch();
let ok = 0, ko = 0;
const t = (nom, cond, det) => { if (cond) { ok++; console.log('  ✓ ' + nom); }
  else { ko++; console.log('  ✗ ' + nom + (det ? '\n      ' + det : '')); } };

// Bootstrap identique à celui d'audit-doctrine : on passe par les VRAIS points d'entrée.
async function session(page) {
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(() => !document.querySelector('.boot-load'));
  await page.evaluate(async () => {
    const b = [...document.querySelectorAll('button')].find(x => /Commencer/.test(x.textContent));
    if (b) b.click();
    await new Promise(r => setTimeout(r, 120));
    const s = [...document.querySelectorAll('button')].find(x => x.textContent.includes("fiches d'exemple"));
    if (s) s.click();
    await new Promise(r => setTimeout(r, 400));
    const f = fiches.find(x => /Arrêt cardiaque/.test(x.title)) || fiches[0];
    openRead(f.id);
    await new Promise(r => setTimeout(r, 350));
    document.getElementById('sessStart').click();
    await new Promise(r => setTimeout(r, 350));
  });
}

console.log(`\n══ PARTAGE · un évènement distant ne déplace rien — moteur ${NOM_MOTEUR} ══`);
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);

  // On se place comme un HÔTE qui partage : le rôle et l'identité viennent du transport, mais
  // aucun réseau n'est sollicité — c'est la couture `_io` qui rend la mesure possible.
  const r = await page.evaluate(async () => {
    Share.mode = 'host'; Share.role = 'lead'; Share.me = 'moi'; Share.status = 'active';
    Share.lastOk = Date.now(); Share.offset = 0;
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

/* Le panneau compteurs/minuteurs n'existe dans le DOM qu'à partir de 1000 px (sous ce seuil il
   reste replié : le contenu clinique d'abord). C'est là qu'on mesure la PEINTURE, pas seulement
   l'état — sinon on croirait tester le rendu alors qu'on ne teste que la mémoire. */
console.log(`\n══ PARTAGE · peinture réelle du compteur et du minuteur (rail visible) ══`);
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

/* Le cas que `ovAfterCheck` traite à part : décocher une étape alors que la bannière de fin
   d'algorithme est affichée. En LOCAL cela re-rend le journal (légitime, l'utilisateur l'a
   demandé) ; à DISTANCE, ce re-rendu rejouerait la condensation et retirerait du contenu
   au-dessus de la carte courante. On mesure que ça n'arrive pas. */
console.log(`\n══ PARTAGE · un décochage distant ne recompose pas le journal ══`);
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
      { id: 'b1', type: 'steps', title: 'Premier', steps: ['a', 'b'], next: 'b2' },
      { id: 'b2', type: 'steps', title: 'Second', steps: ['c', 'd'], next: null }] });
    await Data.put(f); fiches.push(f);
    openRead(f.id); await new Promise(x => setTimeout(x, 350));
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

/* ══ L'INVITÉ NE PAIE RIEN AVANT D'AVOIR LU (v4.47.0) ══════════════════════════════════════════
   Mesuré avant correctif, sur profil vierge, en chargeant `index.html#j=CODE` : deux caches
   (1 302 Ko + 1 773 Ko de pdf.js), une base IndexedDB, quatre clés localStorage, un service worker
   — et `navigator.storage.persist()` appelé INCONDITIONNELLEMENT, c'est-à-dire une demande de
   dépôt non évinçable — le tout AVANT que le premier mot de la notice ait pu s'afficher.
   Le contrôle est SYMÉTRIQUE, et c'est ce qui le rend probant : la même mesure sans le fragment
   doit montrer l'inverse (l'application s'installe bel et bien). Un contrôle qui ne verrait que le
   cas nu ne prouverait pas que la sonde sait voir une empreinte. */
console.log(`\n══ PARTAGE · empreinte sur le téléphone d'un tiers — moteur ${NOM_MOTEUR} ══`);
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

/* ══ LE REFUS N'ESCAMOTE PAS LE BOUTON QU'IL DEMANDE DE PRESSER (v4.47.0) ═════════════════════
   Un message d'erreur pousse le bouton vers le bas. Mesuré avec la rédaction précédente (34 mots,
   2 phrases, un deux-points portant deux justifications) : 7 lignes, 145 px de boîte, et à
   320×568 le bouton « Rejoindre » n'était plus visible que sur 23 px de ses 48 — sous le plancher
   de 32 px de la règle 9, et 0 px sur un écran de 480. Le défaut n'apparaît QU'À la largeur la
   plus contrainte servie, et aucun harnais ne regardait cet écran.
   On mesure aussi que la différenciation vient du CLIENT et de lui seul : le serveur bouchonné
   rend rigoureusement la même réponse dans les trois cas, seule la provenance locale du code
   change le texte. Un message qui varierait avec la réponse du serveur serait un oracle. */
console.log(`\n══ PARTAGE · le refus de jointure reste lisible et actionnable — moteur ${NOM_MOTEUR} ══`);
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
console.log(`\n══ PARTAGE · le miroir de l'invité — moteur ${NOM_MOTEUR} ══`);
for (const [w, h] of [[320, 568], [390, 844]]) {
  const ctx = await br.newContext({ viewport: { width: w, height: h } });
  const page = await ctx.newPage();
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(() => !document.querySelector('.boot-load'));
  await page.evaluate(async () => {
    const b = [...document.querySelectorAll('button')].find(x => /Commencer/.test(x.textContent)); if (b) b.click();
    await new Promise(r => setTimeout(r, 120));
    const s = [...document.querySelectorAll('button')].find(x => x.textContent.includes("fiches d'exemple")); if (s) s.click();
    await new Promise(r => setTimeout(r, 400));
  });
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
      boutonMort: !!document.getElementById('sessStart'),
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
  await page.waitForFunction(() => !document.querySelector('.boot-load'));
  await page.evaluate(async () => {
    const b = [...document.querySelectorAll('button')].find(x => /Commencer/.test(x.textContent)); if (b) b.click();
    await new Promise(r => setTimeout(r, 120));
    const s = [...document.querySelectorAll('button')].find(x => x.textContent.includes("fiches d'exemple")); if (s) s.click();
    await new Promise(r => setTimeout(r, 400));
  });
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

/* ══ LA FENÊTRE D'APPARIEMENT DE L'HÔTE (v4.47.0) ═════════════════════════════════════════════
   Trois exigences mesurables. (1) L'ORDRE : une maquette « QR d'abord » faisait 572 px de carte
   pour une fenêtre de 568 à 320×568 — « Arrêter le partage » sous la ligne de flottaison. On place
   donc en haut ce qui se DICTE (titre de l'aide et code), le QR ensuite et plafonné. (2) LE FOND
   N'EST PAS VERROUILLÉ : toute `.ai-modal` fige le défilement derrière elle au pointeur grossier,
   et celle-ci reste ouverte pendant toute la fenêtre d'admission — la checklist de crise de l'hôte
   deviendrait indéfilable. (3) L'ÉMISSION EXISTE : sans elle, on ouvrirait un partage, quelqu'un
   rejoindrait, et rien ne bougerait jamais — une façade. */
console.log(`\n══ PARTAGE · la fenêtre d'appariement de l'hôte — moteur ${NOM_MOTEUR} ══`);
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
  t(`${w}×${h} · et il est RÉELLEMENT grand à l'écran`, r.codePx >= 30,
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

/* ══ LES DEUX FENÊTRES DU PARTAGE SONT DES FENÊTRES DE L'APP (v4.47.0) ════════════════════════
   Retour utilisateur : « pourquoi le design n'est pas calqué sur les autres fenêtres ? — là ça
   s'affiche mal sur écrans de moyenne largeur ». Mesuré : l'écran d'entrée n'utilisait pas
   `.ai-card`, donc ni son `margin:auto` (centrage vertical) ni son échelle typographique — la
   carte restait collée en haut d'une page opaque, au-dessus de 450 px de vide à 760 px de large.
   Et une fois `.ai-card` adoptée, le 6ᵉ piège de cascade du projet : `.join-card` et `.ai-card`
   ont la même spécificité, la `max-width:720px` déclarée PLUS BAS l'emportait et la carte
   s'étalait sur 700 px. D'où des sélecteurs par `#id`, comme la règle l'impose pour toute
   géométrie. On verrouille les deux ici. */
console.log(`\n══ PARTAGE · les fenêtres suivent la grammaire de l'app — moteur ${NOM_MOTEUR} ══`);
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

/* ══ CONTINUER SEUL : LA TRACE REMONTE, L'ÉTAT NON (v4.48.0) ══════════════════════════════════
   Le repli hors dispositif (AC 120-64 §9.a). Trois propriétés, et chacune répare un mur trouvé en
   contre-expertise : (1) au détachement, la file n'est pas JETÉE mais CONVERTIE en annexes — elle
   l'était, au moment précis où son contenu devenait la seule chose qui doive encore remonter ;
   (2) un détaché continue de sondier lentement, sinon ses annexes n'atteignent jamais l'hôte ;
   (3) chez l'hôte, l'annexe entre au JOURNAL et NULLE PART ailleurs — fusionner l'état d'un
   appareil qui a bifurqué produirait un résultat plausible et faux. */
console.log(`\n══ PARTAGE · continuer seul — moteur ${NOM_MOTEUR} ══`);
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

/* ══ BRIDAGE : LE SCRIBE AJOUTE, IL NE DÉFAIT PAS (v4.48.0) ═══════════════════════════════════
   Forme canonique du travail à deux (AC 120-71B §5.2.2.1), pas un compromis. Trois exigences :
   (1) il PEUT cocher — sinon le dispositif n'a plus d'objet ; (2) il ne peut PAS décocher, parce
   que décocher détruit une information que personne d'autre ne peut restituer ; (3) le refus ne
   DÉPLACE RIEN — même géométrie, même DOM, aucune banderole (règle 11) : c'est une annonce au
   lecteur d'écran et une ligne qui ne change pas d'état. Un masquage aurait fait sauter le
   contenu clinique de 46 px, mesuré, et sur ÉVÈNEMENT DISTANT si le rôle change.
   Et le cœur du cochage existe en DEUX COPIES : on mesure les deux, sinon on retombe sur la
   divergence de la v4.42.0. */
console.log(`\n══ PARTAGE · le scribe ajoute, il ne défait pas — moteur ${NOM_MOTEUR} ══`);
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

/* ══ REJOINDRE SE TAPE DANS LA RECHERCHE (v4.48.0, décision utilisateur) ══════════════════════
   Rejoindre est une action APPELÉE, pas permanente : une ligne en tête d'accueil ferait payer
   44 px d'attention à CHAQUE ouverture pour un geste rare. Le champ de recherche est déjà
   l'endroit où l'on tape ce qu'on cherche, et un code est reconnaissable sans ambiguïté (8
   caractères d'un alphabet fermé de 32 symboles, sans 0/1/I/O). Ce qu'on mesure : la ligne
   apparaît sur un code, JAMAIS sur un mot, et l'accueil au repos est identique au pixel — c'est
   la propriété qui justifie ce choix plutôt qu'une ligne permanente. */
console.log(`\n══ PARTAGE · rejoindre se tape dans la recherche — moteur ${NOM_MOTEUR} ══`);
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(() => !document.querySelector('.boot-load'));
  await page.evaluate(async () => {
    const b = [...document.querySelectorAll('button')].find(x => /Commencer/.test(x.textContent)); if (b) b.click();
    await new Promise(r => setTimeout(r, 120));
    const s = [...document.querySelectorAll('button')].find(x => x.textContent.includes("fiches d'exemple")); if (s) s.click();
    await new Promise(r => setTimeout(r, 400));
  });
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

/* ══ BRIDAGE VISIBLE DES GESTES DU LEAD (v4.48.0) ═════════════════════════════════════════════
   Deux exigences, et la seconde est celle qui a coûté cher au projet par le passé.
   (1) VISIBLE, JAMAIS MASQUÉ : masquer ferait sauter le contenu clinique de 46 px, et sur
       évènement DISTANT si le rôle change — sous le doigt de quelqu'un qui n'a rien demandé.
   (2) UNE SEULE LISTE : le CSS (apparence désactivée) et le script (garde déléguée) énumèrent les
       mêmes verbes. Deux listes divergeraient en silence, exactement comme les deux copies du
       cœur de cochage en v4.42.0. On lit donc la liste DEPUIS LE SCRIPT et on vérifie que chaque
       élément réellement rendu porte l'apparence désactivée : une divergence devient mesurable. */
console.log(`\n══ PARTAGE · le bridage se VOIT, et les deux listes ne divergent pas — moteur ${NOM_MOTEUR} ══`);
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

/* ── LE MIROIR SUIT L'HÔTE QUAND IL CHANGE DE BLOC ────────────────────────────────────────────
   Le défaut mesuré : `SHARE_APPLY` distingue 'live', 'anchored' et 'deferred', mais une seule
   ligne rangeait 'anchored' ET 'deferred' dans la même file — laquelle n'était vidée NULLE PART
   (grep : aucun site de drainage). Conséquence : l'invité voyait les coches du bloc courant, et
   plus rien ensuite. Le miroir se figeait au premier « Continuer » de l'hôte.
   Deux régimes à vérifier, et ils sont OPPOSÉS À DESSEIN :
    · lecteur FERMÉ  -> la navigation s'applique, ancrée (rien ne bouge sous le doigt) ;
    · lecteur OUVERT -> elle est REFUSÉE et ANNONCÉE. La clé de l'étape y est calculée AU CLIC
      depuis `state.nav` : une navigation qui arrive entre le pointerdown et le click ferait
      cocher la mauvaise étape, et le compte-rendu l'imprimerait comme réalisée. */
console.log(`\n══ PARTAGE · le miroir suit quand l'hôte avance — moteur ${NOM_MOTEUR} ══`);
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    Share.mode = 'guest'; Share.role = 'scribe'; Share.me = 'inv'; Share.status = 'active';
    Share.lastOk = Date.now(); Share.offset = 0; Share._defer = [];
    window.scrollTo(0, 300);
    await new Promise(x => setTimeout(x, 250));

    const blocs = (state.fiche.blocks || []).map(b => b.id);
    const cible = blocs.find(id => Runtime.nav.indexOf(id) < 0);
    const navApres = Runtime.nav.concat([cible]);
    const seqApres = Runtime.navSeq.concat([(Runtime.seq || 1) + 1]);

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

    // ── Lecteur OUVERT : le régime s'inverse.
    readerOpen();
    await new Promise(x => setTimeout(x, 350));
    const navAvantLecteur = Runtime.nav.slice();
    const cible2 = blocs.find(id => navAvantLecteur.indexOf(id) < 0) || blocs[0];
    Share.onEvents([{ seq: 12, id: 'n2', actor: 'hote', kind: 'nav',
      payload: { nav: navAvantLecteur.concat([cible2]),
                 navSeq: Runtime.navSeq.concat([(Runtime.seq || 1) + 1]) } }]);
    await new Promise(x => setTimeout(x, 450));
    out.lecteurRefuse = Runtime.nav.join('|') === navAvantLecteur.join('|');
    out.banniere = !!document.querySelector('#readerMode [data-rmresume]');
    out.banniereTexte = (document.querySelector('#readerMode [data-rmresume]') || {}).textContent || '';

    // Le geste LOCAL qui lève l'attente — et lui seul.
    const b = document.querySelector('#readerMode [data-rmresume]');
    if (b) b.click();
    await new Promise(x => setTimeout(x, 400));
    out.apresReprise = Runtime.nav.indexOf(cible2) >= 0;
    out.banniereApres = !!document.querySelector('#readerMode [data-rmresume]');
    return out;
  });
  t('l’hôte avance : la navigation ATTEINT l’écran', r.applique === true, JSON.stringify(r).slice(0, 220));
  t('… l’alias state/Runtime tient', r.aliasIntact === true);
  t('… le compteur de visites ne redescend pas', r.seqMonte === true);
  t('… une carte de plus au journal', r.cartes >= 2, `${r.cartes} carte(s)`);
  t('… et rien ne bouge sous le doigt (≤ 1 px)', r.derive === null || Math.abs(r.derive) <= 1, `${r.derive} px`);
  t('… sans banderole ni fenêtre (règle 11)', r.toasts === 0 && r.modales === 0);
  t('lecteur ouvert : la navigation est REFUSÉE', r.lecteurRefuse === true);
  t('… mais elle est ANNONCÉE sur place', r.banniere === true && /avanc/i.test(r.banniereTexte), r.banniereTexte);
  t('… et un geste LOCAL la reprend', r.apresReprise === true);
  t('… la bannière disparaît une fois reprise', r.banniereApres === false);
  await page.close();
}

/* ── COUPER CELUI QUI TIENT LA MAIN LA REND À L'HÔTE ─────────────────────────────────────────
   « Un seul lead à tout instant, jamais deux, JAMAIS ZÉRO » (invariant 1). Sans cela, couper le
   participant à qui l'on vient de passer la main laisse le partage sans conducteur : un lead
   révoqué d'un côté, un hôte resté scribe de l'autre, et le prochain invité admis arrive scribe
   lui aussi. Ce n'est pas bloquant pour l'hôte — ses gardes sortent sur `mode!=='guest'` — mais
   faire reposer un invariant AFFICHÉ sur la porte de sortie d'une garde, c'est le laisser dépendre
   d'un détail d'implémentation. */
console.log(`\n══ PARTAGE · couper celui qui conduit rend la main — moteur ${NOM_MOTEUR} ══`);
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

/* ── UN RECHARGEMENT NE DOIT PLUS TOUT PERDRE ────────────────────────────────────────────────
   Le cas est banal et il était terminal : un onglet mobile meurt tout seul (iOS recycle les
   onglets en arrière-plan), et l'invité perdait sa participation SANS RETOUR — rien n'était
   persisté, et son code d'appariement est consommé, donc il ne pouvait pas rejoindre.
   Le billet vit en `sessionStorage` : CET onglet, CETTE navigation. On vérifie les deux moitiés
   de l'arbitrage — il survit au rechargement (sinon il ne sert à rien) ET il ne contient aucune
   donnée clinique (sinon l'étanchéité écrite au registre serait fausse). */
console.log(`\n══ PARTAGE · un rechargement ne perd plus la session — moteur ${NOM_MOTEUR} ══`);
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

/* ── LE JOURNAL RÉFÉRENTIEL : LE MOT ARRIVE, LE TEXTE LIBRE NON ─────────────────────────────
   Un repère partagé ne portait AUCUN mot : `ref` n'existait que pour les compteurs, si bien qu'un
   repère posé par l'hôte s'affichait « Action 3 » chez l'invité — l'heure juste, le mot manquant.
   On vérifie les deux moitiés de la promesse, et elles se contredisent si l'on se trompe :
   le MOT doit arriver (sinon la fonctionnalité ne sert à rien), et le TEXTE LIBRE ne doit JAMAIS
   partir (sinon la règle 15 et le registre RGPD deviennent faux). */
console.log(`\n══ PARTAGE · le journal référentiel — moteur ${NOM_MOTEUR} ══`);
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    Share.mode = 'host'; Share.role = 'lead'; Share.me = 'moi'; Share.status = 'active';
    setMyTags([{ k: 'mru', l: 'Médecin régulateur', a: ['mru', 'regul'] }]);
    document.getElementById('tkAdd').click();
    await new Promise(x => setTimeout(x, 400));
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

/* ── LA FIN DE LA SESSION EST LA FIN DU PARTAGE ──────────────────────────────────────────────
   Signalé à l'usage : l'hôte terminait sa session et la fenêtre continuait d'annoncer « Partage
   en cours ». Le partage survivait à la session qu'il reflétait — l'invité sondait un miroir que
   plus rien n'alimentait, et le code d'appariement restait vivant jusqu'à son terme. Un partage
   sans session n'a pas d'objet. */
console.log(`\n══ PARTAGE · terminer la session coupe le partage — moteur ${NOM_MOTEUR} ══`);
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
console.log(`\n══ PARTAGE · aucun participant n'injecte de balisage — moteur ${NOM_MOTEUR} ══`);
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

/* ── LA PASSATION DE LA MAIN — EN TROIS TEMPS, ET AUCUN ÉCRAN NE CHANGE SEUL ─────────────────
   Le scribe ne conduit pas : il ne navigue pas, n'arrête pas un minuteur, ne termine pas. C'est la
   forme canonique du travail à deux (AC 120-71B §5.2.2.1) — mais sans passation, quelqu'un qui a
   BESOIN de conduire n'a aucun recours, et l'asymétrie devient une impasse.
   Trois temps (AC 61-115 « Positive Exchange of Flight Controls ») : l'un PROPOSE, l'autre PREND,
   et le changement de rôle vaut confirmation. Invariant 2 : aucun écran ne change de capacité sans
   un geste effectué SUR CET écran — un `handoff` reçu n'accorde donc rien, il AFFICHE. */
console.log(`\n══ PARTAGE · la passation de la main — moteur ${NOM_MOTEUR} ══`);
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

/* ── LE MODE LECTEUR EST BRIDÉ COMME LA PAGE ─────────────────────────────────────────────────
   Signalé à l'usage : « pourquoi l'invité peut passer de bloc en bloc en mode lecteur mais pas sur
   la page de l'aide ? » — et c'était vrai. `data-rmnext` et `data-rmopt` sont les MÊMES verbes que
   `data-ovnext` et `data-ovopt` sous d'autres noms ; la liste ne les nommait pas.
   CE CONTRÔLE OUVRE LE LECTEUR, et ce n'est pas un détail : celui qui existait interrogeait
   `LEAD_ONLY_SEL` le lecteur FERMÉ — il ne pouvait donc pas voir les entrées du lecteur, et serait
   resté vert même en n'en corrigeant qu'une des deux listes. Un contrôle aveugle au défaut qu'il
   prétend couvrir ne prouve rien (leçon v4.31.1). */
console.log(`\n══ PARTAGE · le lecteur est bridé comme la page — moteur ${NOM_MOTEUR} ══`);
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    Share.mode = 'guest'; Share.role = 'scribe'; Share.me = 'inv'; Share.status = 'active';
    Share.lastOk = Date.now(); Share.offset = 0; Share._q = [];
    document.body.classList.add('share-scribe');
    readerOpen();
    await new Promise(x => setTimeout(x, 400));
    const rm = document.getElementById('readerMode');
    const out = { ouvert: rm.classList.contains('on') };

    /* LE CONTRÔLE DE CONDUITE N'EXISTE QU'EN FIN DE BLOC. Le lecteur montre un challenge à la
       fois : « Continuer » (`data-rmnext`) n'apparaît qu'une fois les étapes confirmées. Mesurer
       avant, c'est mesurer un écran qui n'a rien à brider — la sonde le voyait vide et accusait
       la liste. On CONFIRME donc d'abord, ce qui est précisément le verbe du scribe. */
    for (let i = 0; i < 12 && !rm.querySelector('[data-rmnext],[data-rmopt]'); i++) {
      const b2 = rm.querySelector('[data-rmok]'); if (!b2) break;
      b2.click(); await new Promise(x => setTimeout(x, 120));
    }
    out.conduiteVisible = !!rm.querySelector('[data-rmnext],[data-rmopt]');

    /* 1 — LE LECTEUR N'A PLUS AUCUN CONTRÔLE BRIDÉ (v4.55.0). Avancer et choisir une branche y
       sont ouverts comme sur la page : c'est le même verbe sous un autre nom, et la cohérence
       entre les deux surfaces est ce qui manquait — dans un sens comme dans l'autre. */
    out.recenses = rm.querySelectorAll(LEAD_ONLY_SEL).length;

    // 3 — AVANCER NE FAIT RIEN. Le vrai enjeu n'est pas « le geste est refusé » mais « le miroir
    // ne diverge pas » : `shareEmitDiff` avance la base de comparaison AVANT d'émettre, donc un
    // geste passé ici laisserait l'invité seul à avoir avancé, pour toujours.
    const navAvant = Runtime.nav.length;
    const qAvant = Share.pending();
    const nx = rm.querySelector('[data-rmnext]') || rm.querySelector('[data-rmopt]');
    if (nx) nx.click();
    await new Promise(x => setTimeout(x, 350));
    out.navApres = Runtime.nav.length;
    out.avance = Runtime.nav.length > navAvant;
    out.aEmis = Share.pending() > qAvant;

    // 4 — LA TROISIÈME COPIE DU CŒUR DE COCHAGE passe par le prédicat unique. Mesuré avec le lien
    // ARRÊTÉ : le même geste est refusé sur la page, il devait l'être ici aussi.
    Share.status = 'ended';
    const nCoches = Object.keys(state.checked).length;
    const ok2 = rm.querySelector('[data-rmok]');
    if (ok2) ok2.click();
    await new Promise(x => setTimeout(x, 250));
    out.cocheLienMort = Object.keys(state.checked).length > nCoches;
    Share.status = 'active';

    // 5 — Le focus initial n'atterrit pas sur un contrôle mort.
    readerClose(); await new Promise(x => setTimeout(x, 200));
    readerOpen(); await new Promise(x => setTimeout(x, 350));
    const af = document.activeElement;
    out.focusMort = !!(af && af.matches && af.matches(LEAD_ONLY_SEL));
    out.focusSur = af ? (af.id || af.className || af.tagName) : '(aucun)';

    // 6 — Un geste refusé déclare le miroir PÉRIMÉ plutôt que de le laisser diverger en silence.
    // (le verbe d'épreuve est désormais un DESTRUCTEUR — c'est là que passe la ligne)
    Share._resync = false;
    Share.emit('timer_reset', { id: 't1' });
    out.perimeApresRefus = Share._resync === true;
    document.body.classList.remove('share-scribe');
    return out;
  });
  t('le lecteur s’ouvre pour un scribe', r.ouvert === true);
  t('témoin : un scribe CONFIRME bien (c’est son verbe)', r.conduiteVisible === true);
  t('aucun contrôle du lecteur n’est bridé (v4.55.0)', r.recenses === 0, `${r.recenses} élément(s)`);
  t('AVANCER fonctionne comme sur la page', r.avance === true, `${r.navApres} bloc(s)`);
  t('… et le geste PART', r.aEmis === true);
  t('cocher au lien mort est refusé ici AUSSI', r.cocheLienMort === false);
  t('le focus n’atterrit pas sur un contrôle mort', r.focusMort === false, String(r.focusSur));
  t('un geste refusé déclare le miroir périmé', r.perimeApresRefus === true);
  await page.close();
}

/* ── LE MENU SUIT L'ÉTAT DU PARTAGE, ET LE LIEN MORT REFUSE TOUT ─────────────────────────────
   Trois signalements d'usage, une cause commune pour les deux premiers : les rangées du menu ⋯
   sont construites AU RENDU, et la règle 3 interdit de rendre sur évènement distant. Le compte de
   participants restait donc figé, et « Prendre la main » — qui n'existe que si une offre est
   arrivée — ne paraissait JAMAIS : la passation n'avait pas de porte.
   Le troisième : un invité COUPÉ pouvait encore incrémenter un compteur, sans que rien ne lui dise
   que son geste ne partait plus. « Cocher dans le vide en croyant contribuer » est nommé au plan
   comme le pire mode de défaillance du dispositif. */
console.log(`\n══ PARTAGE · le menu suit, le lien mort refuse — moteur ${NOM_MOTEUR} ══`);
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

/* ── LE PLACARD DE L'INVITÉ, ET LES RÉPONSES QUI NE SE PERDENT PLUS ──────────────────────────
   Deux derniers signalements. (1) L'invité lisait « ■ Mode crise » — exactement ce que lit l'hôte —
   alors que sa situation est autre : il SUIT une session qu'il ne conduit pas et qui peut s'arrêter
   sans lui. (2) La règle 11 (« aucune notification flottante en session ») vise ce qui ARRIVE ;
   elle retenait aussi la RÉPONSE à un bouton qu'on venait de presser, si bien que le message
   surgissait à l'accueil, détaché de son geste. */
console.log(`\n══ PARTAGE · le placard de l'invité et les réponses directes — moteur ${NOM_MOTEUR} ══`);
{
  const page = await br.newPage({ viewport: { width: 390, height: 844 } });
  await session(page);
  const r = await page.evaluate(async () => {
    const o = {};
    const band = document.getElementById('crisisBand');
    const tag = () => (band.querySelector('.cb-tag') || {}).textContent || '';
    const hach = el => getComputedStyle(el, '::before').opacity;
    o.hoteTag = tag(); o.hoteHachure = hach(band);

    // On passe en INVITÉ par le vrai chemin d'affichage : le placard suit un rendu.
    Share.mode = 'guest'; Share.role = 'scribe'; Share.me = 'inv'; Share.status = 'active';
    Share.lastOk = Date.now(); Share.offset = 0;
    render(); await new Promise(x => setTimeout(x, 450));
    o.inviteTag = tag();
    o.inviteHachure = hach(band);
    o.inviteEnTete = (document.getElementById('hdrCrisis') || {}).textContent || '';
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
  t('témoin : l’hôte lit « Mode crise », sans hachure',
    /Mode crise/.test(r.hoteTag) && r.hoteHachure === '0', `${r.hoteTag} / ${r.hoteHachure}`);
  t('l’invité lit « Vous suivez »', /Vous suivez/.test(r.inviteTag), r.inviteTag);
  t('… le bandeau est hachuré', r.inviteHachure === '1', r.inviteHachure);
  t('… et l’en-tête le relaie', /Suivi/.test(r.inviteEnTete), r.inviteEnTete);
  t('… à COÛT NUL en hauteur', r.hauteurInvite === r.hauteurBandeau,
    `${r.hauteurBandeau} → ${r.hauteurInvite} px`);
  t('l’exercice garde la priorité sur le placard d’invité', /Exercice/.test(r.exoGagne), r.exoGagne);
  t('témoin : une session de crise est bien à l’écran', r.enCrise === true);
  t('une nouvelle de fond reste RETENUE (règle 11)', r.fondAffiche === 0, `${r.fondAffiche} banderole(s)`);
  t('… mais une réponse à un geste S’AFFICHE', r.directAffiche === 1, `${r.directAffiche} banderole(s)`);
  await page.close();
}

/* LE MENU ⋯ SOUS UN PLACARD (v4.55.5, signalé à l'usage). Le placard levait TOUS les enfants
   directs de l'en-tête en `position:relative` pour les faire passer au-dessus de sa hachure — or
   `.more-menu` est un enfant direct, et il se positionne LUI-MÊME. La règle valait (0,2,1) contre
   (0,1,0) : le menu retombait dans le flux de la barre et s'y ouvrait au lieu de flotter dessous.
   ON MESURE LA POSITION CALCULÉE ET LA GÉOMÉTRIE, PAS LA PRÉSENCE D'UNE CLASSE : c'est le fait de
   flotter qui est en cause, pas l'intention de le faire flotter. Et on mesure la hachure par son
   IMAGE DE FOND, jamais par l'opacité seule — sur un en-tête SANS placard le pseudo-élément n'a
   pas de `content`, et `getComputedStyle` rend alors l'opacité par défaut 1 : un témoin fondé sur
   l'opacité serait vert des deux côtés et ne prouverait rien. */
console.log(`\n══ PARTAGE · le menu ⋯ reste flottant sous un placard — moteur ${NOM_MOTEUR} ══`);
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

/* « AVANCÉ PAR … » NE SUIT PLUS CELUI QUI AVANCE (v4.55.5, signalé à l'usage). La mention était un
   drapeau global qu'un SEUL site effaçait (`cxEnter`) : posée une fois — typiquement par le
   backlog rattrapé à la jointure, où toutes les navigations de l'hôte défilent d'un coup — elle
   suivait ensuite l'invité de carte en carte et attribuait à « Hôte » les blocs qu'il venait
   lui-même d'avancer. Elle est désormais AMARRÉE au numéro de visite créé par l'avance distante.
   LE CONTRÔLE CONSTRUIT LE CAS : une avance distante, PUIS une avance locale — le défaut ne se
   voit qu'à la seconde, et un contrôle qui s'arrêterait à la première serait vert avec le défaut
   en place. */
console.log(`\n══ PARTAGE · l'attribution ne survit pas à un geste local — moteur ${NOM_MOTEUR} ══`);
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

await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles partage OK` + (ko ? ` — ${ko} ÉCHEC(S)` : ''));
process.exit(ko ? 1 : 0);
