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
      repere: (Runtime.events || []).some(x => x.label === 'Adrénaline'),
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

await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles partage OK` + (ko ? ` — ${ko} ÉCHEC(S)` : ''));
process.exit(ko ? 1 : 0);
