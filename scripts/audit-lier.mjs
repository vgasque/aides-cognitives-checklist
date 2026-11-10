#!/usr/bin/env node
/* AUDIT — CONNEXION PAR LE TÉLÉPHONE ET POSTE PARTAGÉ (v5.111, A643)
 *
 * Les tests unitaires prouvent les fonctions PURES (nombre de contrôle, heures de fin, décision du
 * poste) et rls-tests.sql §16 prouve le SERVEUR. Ce harnais prouve ce qu'aucun des deux ne voit :
 * les vrais parcours de l'écran, de bout en bout, avec le serveur BOUCHONNÉ au niveau du réseau
 * (page.route) — donc les vrais `rpc`, `rest`, `Auth`, `Sync`, le vrai rechargement de bascule
 * d'espace, le vrai effacement.
 *
 * Trois manœuvres :
 *  1. LE POSTE se connecte : QR + nombre, sondage, réclamation, vérification, bascule d'espace SANS
 *     emporter le contenu hors compte ; il devient poste partagé (bande, état, historique qui monte
 *     sans que le RÉGLAGE du compte ne change).
 *  2. LE POSTE vit : verrou après réouverture (nouvel onglet), sauvegarde périodique d'une session en
 *     cours (par la synchro, puis par le DÉPÔT une fois la session de compte perdue), effacement
 *     refusé pendant une session, dépôt de la session terminée, effacement à l'heure de fin.
 *  3. LE TÉLÉPHONE approuve : lien `#lier=` ouvert par l'appareil photo, mauvais nombre refusé, heure
 *     de fin dans les bornes, et rien ne part avant le bon nombre.
 */
import { serveApp, moteur, NOM_MOTEUR, amorce, ouvrirFiche, demarrerSession } from './harness.mjs';

const { port, srv } = await serveApp();
const br = await moteur().launch();
let ok = 0, ko = 0;
const t = (nom, cond, det) => { if (cond) { ok++; console.log('  ✓ ' + nom); }
  else { ko++; console.log('  ✗ ' + nom + (det ? '\n      ' + det : '')); } };
const URL0 = `http://localhost:${port}/index.html`;
/* Attendre un état APRÈS un rechargement décidé par l'app (bascule d'espace, effacement) : une
   évaluation peut tomber pendant la navigation (« contexte détruit ») — on réessaie jusqu'au délai. */
async function apres(pg, fn, arg, ms) {
  const fin = Date.now() + (ms || 20000);
  while (Date.now() < fin) {
    try { if (await pg.evaluate(fn, arg)) return true; } catch (e) {}
    await pg.waitForTimeout(250);   // horloge : sondage d'un rechargement en cours
  }
  return false;
}
const LID = '0b6f3a2e-9c1d-4e5f-8a7b-1c2d3e4f5a6b', UID = 'abababab-abab-abab-abab-abababababab';

/* LE SERVEUR BOUCHONNÉ. `srvst` est l'état que les manœuvres pilotent ; `vu` ce qui est PARTI. */
function bouchon(srvst, vu) {
  return async route => {
    const rq = route.request(), u = new URL(rq.url()), m = rq.method();
    let body = null; try { body = rq.postDataJSON(); } catch (e) {}
    const J = (o, s) => route.fulfill({ status: s || 200, contentType: 'application/json', body: JSON.stringify(o) });
    const p = u.pathname;
    if (p.startsWith('/rest/v1/rpc/')) {
      const fn = p.slice(13); (vu[fn] = vu[fn] || []).push(body);
      if (fn === 'link_open') return J({ ok: true, id: LID, open_until: new Date(Date.now() + 120e3).toISOString(), server_time: new Date().toISOString() });
      if (fn === 'link_poll') return J(srvst.poll || { ok: true, status: 'pending' });
      if (fn === 'link_approve' || fn === 'link_deposit' || fn === 'link_revoke' || fn === 'link_end') return J({ ok: true });
      if (fn === 'link_peek') return J({ ok: true, kind: 'connect', label: 'Chrome · Windows', age_s: 4 });
      if (fn === 'my_status') return J('approved');
      if (fn === 'link_self') return J(srvst.self || { ok: true, id: LID, ends_at: body && body.p_ends_at });
      if (fn === 'get_temp_rules') return J(srvst.rules || { edit: 'v15', del: 'tel', repl: 'non', exp: 'oui', dur: 28 });
      if (fn === 'set_temp_rules') return J(null);
      if (fn === 'link_list') return J(srvst.devs || []);
      if (fn === 'link_extend') return J({ ok: true });
      return J(null);
    }
    if (p === '/functions/v1/link-claim') { (vu.claim = vu.claim || []).push(body);
      return J({ ok: true, ends_at: srvst.ends, session: { access_token: 'at', refresh_token: 'rt', expires_at: Math.floor(Date.now() / 1000) + 3600, user: { id: UID, email: 'kim@test.local' } } }); }
    if (p === '/auth/v1/otp') { (vu.otp = vu.otp || []).push(body); return J({}); }
    if (p === '/auth/v1/verify') { (vu.verify = vu.verify || []).push(body);
      return J(srvst.verifyOk ? { access_token: 'at', refresh_token: 'rt', expires_in: 3600, user: { id: UID, email: 'kim@test.local' } } : {}); }
    if (p === '/auth/v1/token') return J({ access_token: 'at', refresh_token: 'rt', expires_in: 3600, user: { id: UID, email: 'kim@test.local' } });
    if (p.startsWith('/auth/v1/logout')) { vu.logout = (vu.logout || 0) + 1; return route.fulfill({ status: 204, body: '' }); }
    if (p === '/rest/v1/sessions' && m === 'POST') { (vu.sessions = vu.sessions || []).push(...(body || [])); return route.fulfill({ status: 201, body: '' }); }
    if (m === 'GET') return J([]);
    return route.fulfill({ status: 201, body: '' });
  };
}

console.log(`\n══ CONNEXION PAR LE TÉLÉPHONE · poste partagé — moteur ${NOM_MOTEUR} ══`);
const ctx = await br.newContext({ viewport: { width: 1200, height: 900 } });
const srvst = { ends: new Date(Date.now() + 10 * 3600e3).toISOString() }, vu = {};
await ctx.route('**/*.supabase.co/**', bouchon(srvst, vu));
const page = await ctx.newPage();
const toasts = [];
await page.exposeFunction('__lkToast', s => toasts.push(s));
{
  console.log('\n── 1. Le poste se connecte');
  await page.goto(URL0);
  await amorce(page);   // l'espace SANS compte du poste a du contenu (deux exemples) : il ne doit pas suivre
  const avant = await page.evaluate(() => fiches.length);
  await page.evaluate(() => openAuth());
  // A651 : la carte « Se connecter » ne choisit RIEN d'office ; le code s'affiche DANS la page (Temporaire › appareil connecté).
  await page.waitForSelector('[data-authk="temp"]');
  const r0 = await page.evaluate(() => ({ on: document.querySelectorAll('.pp-tile.on').length, qr: !!document.querySelector('#lkInline') }));
  t('rien n’est choisi d’office : ni Temporaire ni Permanente, aucun code demandé', r0.on === 0 && !r0.qr && !(vu.link_open || []).length, JSON.stringify(r0));
  await page.click('[data-authk="temp"]');
  await page.waitForSelector('#lkInline .pp-qr svg');
  const r1 = await page.evaluate(() => ({ num: (document.querySelector('#lkInline .pp-num') || {}).textContent,
    exp: (document.getElementById('lkExp') || {}).textContent, modal: document.getElementById('linkModal').classList.contains('on') }));
  t('Temporaire : le code et son nombre de contrôle s’affichent dans la page, sans fenêtre', /^\d{2}$/.test(r1.num || '') && !r1.modal, JSON.stringify(r1));
  t('… avec son compte à rebours de renouvellement', /Nouveau code dans \d:\d\d/.test(r1.exp || ''), r1.exp);
  const op = (vu.link_open || [])[0] || {};
  t('le serveur ne reçoit que des EMPREINTES : secret du QR et clé du poste, distincts', /^[0-9a-f]{64}$/.test(op.p_hash || '') && /^[0-9a-f]{64}$/.test(op.p_key_hash || '') && op.p_hash !== op.p_key_hash && op.p_kind === 'connect' && /·/.test(op.p_label || ''), JSON.stringify(op));
  // Le téléphone approuve : le poste réclame, se connecte, et RECHARGE sur l'espace du compte.
  srvst.poll = { ok: true, status: 'approved', ends_at: srvst.ends };
  // La bascule d'espace RECHARGE la page : on attend l'espace du compte, application démarrée.
  await apres(page, u => localStorage.getItem('ac-space') === u && typeof linkShared === 'function'
    && !document.querySelector('.boot-load') && typeof fiches !== 'undefined' && fiches.length === 0, UID);
  const claim = (vu.claim || [])[0] || {}, polls = vu.link_poll || [];
  t('la réclamation porte la CLÉ DU POSTE, jamais le secret du QR', claim.id === LID && typeof claim.key === 'string' && claim.key.length >= 22 && !('secret' in claim), JSON.stringify(claim));
  t('… la même clé que le sondage (p_key)', polls.length && polls.every(x => x && x.p_key === claim.key && !('p_secret' in x)), JSON.stringify(polls[0]));
  t('la session arrive PRÊTE de la fonction serveur (le poste ne lie rien lui-même)', !(vu.verify || []).length && !(vu.link_bind || []).length);
  const r2 = await page.evaluate(() => ({ space: localStorage.getItem('ac-space'), sp: linkShared(), open: sessionStorage.getItem('ac-shared-open'),
    signed: Auth.signedIn(), fiches: fiches.length, confirm: document.getElementById('confirmModal').classList.contains('on') }));
  t('bascule sur l’espace du compte', r2.space === UID && r2.signed, JSON.stringify(r2));
  t('… sans emporter le contenu hors compte du poste', r2.fiches === 0 && !r2.confirm && avant >= 2, `avant ${avant}, après ${r2.fiches}`);
  t('l’heure de fin choisie sur le téléphone est retenue', r2.sp && Math.abs(r2.sp.endsAt - Date.parse(srvst.ends)) < 1000, JSON.stringify(r2.sp));
  t('cet onglet est ouvert par le téléphone (pas de verrou)', r2.open === '1');
  t('le poste garde la clé, jamais le secret du QR', await page.evaluate(() => { const o = JSON.parse(localStorage.getItem('ac-shared') || '{}'); return !!o.key && !('secret' in o); }));
  await page.waitForFunction(() => { const b = document.getElementById('linkBand'); return b && !b.hidden; });
  const band = await page.evaluate(() => document.getElementById('linkBand').textContent);
  t('la bande de l’accueil dit « Connexion temporaire », le compte et l’heure de fin', /Connexion temporaire/.test(band) && /kim@test\.local/.test(band) && /jusqu’à/.test(band), band);
  t('… sans couleur tant que rien ne presse (règle 8 : rien ne tourne mal)', await page.evaluate(() => { const b = document.getElementById('linkBand'); return b.className === 'pp-band'; }));
  // L'historique MONTE sur un poste partagé — sans que le réglage du compte ne bascule.
  const r3 = await page.evaluate(async () => {
    const f = { id: 's-poste-a', ficheId: 'x', ficheTitle: 'x', savedAt: Date.now(), startedAt: Date.now() - 6e4, live: false, checked: {}, verified: {}, vgaps: {}, counters: {}, timers: {}, nav: [], navSeq: [], events: [] };
    _putSessionSafe(f); await new Promise(r => setTimeout(r, 200));   // horloge : écriture IndexedDB
    const pull = await Sync._pullSessions();
    await Sync._pushSessions();
    return { reglage: sessSyncOn(), pull };
  });
  t('une session terminée sur le poste monte dans l’historique', (vu.sessions || []).some(x => x.id === 's-poste-a'));
  t('… sans activer le RÉGLAGE du compte (il voyagerait sur tous ses appareils)', r3.reglage === false);
  t('… et le poste ne TIRE pas l’historique du compte', r3.pull === false);
}
{
  console.log('\n── 2. Le poste vit : verrou, sauvegardes, effacement');
  // Un NOUVEL onglet = une réouverture : le verrou tient, la consultation reste libre.
  const p2 = await ctx.newPage();
  await p2.goto(URL0);
  await p2.waitForFunction(() => typeof linkShared === 'function' && !!linkShared() && !document.querySelector('.boot-load'));
  const v = await p2.evaluate(async () => { const was = linkLocked(); await newFiche();
    return { was, modal: document.getElementById('linkModal').classList.contains('on'), titre: document.getElementById('linkModalTitle').textContent, view: state.view }; });
  t('nouvel onglet : « Créer » est retenu par le verrou', v.was && v.modal && /Déverrouiller/.test(v.titre) && v.view !== 'edit', JSON.stringify(v));
  await p2.evaluate(() => { Link.close(); openAuth(); });
  const moi = await p2.evaluate(() => ({ unlock: !!document.querySelector('[data-lkunlock]'), wipe: !!document.querySelector('[data-lkwipe]'), suppr: !!document.getElementById('authDelete') }));
  t('Moi verrouillé : déverrouiller ou effacer, rien d’autre', moi.unlock && moi.wipe && !moi.suppr, JSON.stringify(moi));
  srvst.poll = { ok: true, status: 'approved', ends_at: srvst.ends };
  await p2.evaluate(() => newFiche());
  await p2.waitForFunction(() => state.view === 'edit', null, { timeout: 8000 });
  t('le téléphone d’accord, l’action retenue reprend (éditeur ouvert)', await p2.evaluate(() => state.view === 'edit' && !linkLocked()));
  t('… le verrou est passé par une demande de DÉVERROUILLAGE', (vu.link_open || []).some(x => x && x.p_kind === 'unlock'));
  await p2.close();
  srvst.poll = { ok: true, status: 'claimed', ends_at: srvst.ends };
  // Les PALIERS (décision de l'auteur) : l'administration est refusée, supprimer demande le téléphone à
  // chaque fois, et 15 min sans geste reverrouillent l'édition.
  await page.bringToFront();
  const adm = await page.evaluate(() => { openAdmin(); const r = { on: document.getElementById('linkModal').classList.contains('on'),
    titre: document.getElementById('linkModalTitle').textContent, adm: !!document.querySelector('#admModal.on') }; Link.close(); return r; });
  t('poste partagé : l’Administration est refusée, et dit pourquoi', adm.on && /Pas sur un appareil temporaire/.test(adm.titre) && !adm.adm, JSON.stringify(adm));
  await page.evaluate(() => { _linkGestAt = Date.now() - 16 * 60000; document.dispatchEvent(new PointerEvent('pointerdown')); });
  t('15 min sans geste : l’édition se reverrouille (consultation libre)', await page.evaluate(() => linkLocked()));
  // Le geste d'après reverrouille AVANT d'agir ; on déverrouille par le téléphone pour la suite.
  srvst.poll = { ok: true, status: 'approved', ends_at: srvst.ends };
  await page.evaluate(() => Link.start('unlock', null));
  await page.waitForFunction(() => !linkLocked(), null, { timeout: 8000 });
  // Supprimer : le téléphone à CHAQUE fois, même onglet déverrouillé ; confirmé, la suppression reprend.
  srvst.poll = { ok: true, status: 'pending', ends_at: srvst.ends };
  await page.evaluate(() => newFiche());
  await page.waitForFunction(() => state.view === 'edit');
  const del = await page.evaluate(() => { deleteDraft(); return { titre: document.getElementById('linkModalTitle').textContent,
    on: document.getElementById('linkModal').classList.contains('on'), conf: document.getElementById('confirmModal').classList.contains('on') }; });
  t('poste partagé : supprimer demande le TÉLÉPHONE, même déverrouillé', del.on && /Confirmer avec un appareil connecté/.test(del.titre) && !del.conf, JSON.stringify(del));
  srvst.poll = { ok: true, status: 'approved', ends_at: srvst.ends };
  await page.waitForFunction(() => document.getElementById('confirmModal').classList.contains('on'), null, { timeout: 8000 });
  t('… confirmé par le téléphone, la suppression reprend (sa propre confirmation)', true);
  await page.evaluate(() => document.getElementById('confirmNo').click());
  await page.evaluate(() => { state.view = 'library'; render(); });
  srvst.poll = { ok: true, status: 'claimed', ends_at: srvst.ends };
  // Une session en cours, sauvegardée en ligne : par la synchro tant que le compte est là…
  await page.bringToFront();
  await amorce(page);
  await ouvrirFiche(page, /arr[êe]t|anaphyl|./);
  await demarrerSession(page);
  vu.sessions = []; vu.link_deposit = [];
  await page.evaluate(async () => { Runtime.lastActAt = Date.now(); await Link.watch(); });
  const c1 = (vu.sessions || []).find(x => x.data && x.data.checkpoint);
  t('session en cours : une SAUVEGARDE part (compte rendu partiel)', !!c1 && c1.data.live === false && c1.id === await page.evaluate(() => Runtime.sessionId), JSON.stringify(c1 && { id: c1.id, live: c1.data.live }));
  await page.evaluate(async () => { await Link.watch(); });
  t('… pas une seconde sans nouveau geste', (vu.sessions || []).filter(x => x.data && x.data.checkpoint).length === 1);
  // … puis par le DÉPÔT quand la session de compte du poste est perdue (heure de fin, réseau).
  await page.evaluate(async () => { Auth.session = null; Runtime._lkCkpt = 0; Runtime.lastActAt = Date.now(); await Link.watch(); });
  const d1 = (vu.link_deposit || []).find(x => x && x.p_row && x.p_row.data && x.p_row.data.checkpoint);
  t('compte perdu : la sauvegarde passe par le DÉPÔT (secret du lien)', !!d1 && d1.p_id === LID && d1.p_row.data.live === false, JSON.stringify(d1 && d1.p_row && d1.p_row.id));
  await page.evaluate(() => { const ob = window.toast; window.toast = (m, ...a) => { window.__lkToast(String(m)); return ob(m, ...a); }; });
  await page.evaluate(() => Link.wipe(false));
  t('effacer est REFUSÉ pendant une session en cours (règle 11)', await page.evaluate(() => !!linkShared()) && toasts.some(s => /session est en cours/.test(s)), toasts.join(' | '));
  // La session terminée rejoint l'historique par le dépôt, puis l'heure de fin passée efface le poste.
  vu.link_deposit = [];
  await page.evaluate(async () => { const id = Runtime.sessionId; endSession(Runtime); window.__lkSid = id;
    await new Promise(r => setTimeout(r, 300));   // horloge : écriture IndexedDB de l'archive
    await Link.watch(); });
  const sid = await page.evaluate(() => window.__lkSid);
  t('session terminée, compte perdu : elle est DÉPOSÉE, sans marque de sauvegarde', (vu.link_deposit || []).some(x => x && x.p_row && x.p_row.id === sid && !x.p_row.data.checkpoint), JSON.stringify((vu.link_deposit || []).map(x => x && x.p_row && x.p_row.id)));
  srvst.poll = { ok: true, status: 'ended', ends_at: new Date(Date.now() - 60e3).toISOString() };
  await page.evaluate(() => { Link.watch().catch(() => {}); });
  await apres(page, () => localStorage.getItem('ac-space') === '' && typeof linkShared === 'function'
    && !document.querySelector('.boot-load') && !linkShared());
  const fin = await page.evaluate(() => ({ space: localStorage.getItem('ac-space'), spaces: localStorage.getItem('ac-spaces') || '', auth: localStorage.getItem('ac-auth'), open: sessionStorage.getItem('ac-shared-open') }));
  t('heure de fin passée, rien en attente : le poste s’EFFACE', fin.space === '' && !fin.auth && !fin.open, JSON.stringify(fin));
  t('… sans garder l’identifiant du compte dans le registre des espaces', fin.spaces.indexOf(UID) < 0, fin.spaces);
  t('… et en se déclarant TERMINÉ au serveur avant de se déconnecter (il quitte « Appareils connectés », A649)', (vu.link_end || []).length >= 1 && (vu.logout || 0) >= 1, JSON.stringify({ end: (vu.link_end || []).length, logout: vu.logout }));
}
await ctx.close();
{
  console.log('\n── 3. Le téléphone approuve');
  const c2 = await br.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });
  const st2 = { ends: new Date(Date.now() + 10 * 3600e3).toISOString() }, vu2 = {};
  await c2.route('**/*.supabase.co/**', bouchon(st2, vu2));
  const ph = await c2.newPage();
  await ph.goto(URL0);
  await amorce(ph);
  await ph.evaluate(() => { Auth._setSession({ access_token: 'at', refresh_token: 'rt', expires_in: 3600, user: { id: 'cdcdcdcd-cdcd-cdcd-cdcd-cdcdcdcdcdcd', email: 'ana@test.local' } });
    localStorage.setItem('ac-space', 'cdcdcdcd-cdcd-cdcd-cdcd-cdcdcdcdcdcd'); });
  await ph.reload();
  await ph.waitForFunction(() => typeof Auth !== 'undefined' && Auth.signedIn() && !document.querySelector('.boot-load'));
  const S = 'Q2xLk9_aZ0b-Xy7Pq3RsTu';
  // Le lien du QR ouvert par l'appareil photo du système (le vrai point d'entrée : le fragment).
  await ph.evaluate(([id, s]) => { location.hash = '#lier=' + id + '.' + s; }, [LID, S]);
  await ph.waitForSelector('#linkModal.on [data-lkscan]');
  const lien = await ph.evaluate(() => ({ feuille: !!document.querySelector('[data-lkn]'), txt: document.getElementById('linkBody').textContent }));
  t('un LIEN (appareil photo, SMS, e-mail) mène au viseur, jamais droit à l’approbation', !lien.feuille && /viseur/.test(lien.txt) && !(vu2.link_peek || []).length, JSON.stringify(lien));
  // Le viseur de l'app rend le code lu à `Link.approve(L, true)` : c'est son vrai point de sortie.
  await ph.evaluate(([id, s]) => Link.approve({ id, secret: s }, true), [LID, S]);
  await ph.waitForSelector('#linkModal.on [data-lkn]');
  const r = await ph.evaluate(s => ({ nums: [...document.querySelectorAll('[data-lkn]')].map(b => +b.dataset.lkn), vrai: linkCheckNum(s),
    ends: document.querySelectorAll('[data-lkend]').length, ok: !!document.querySelector('[data-lkok]'),
    titre: document.getElementById('linkModalTitle').textContent }), S);
  t('feuille : le poste nommé dans le titre, trois nombres dont le vrai', r.nums.length === 3 && r.nums.includes(r.vrai) && /Connecter Chrome · Windows/.test(r.titre), JSON.stringify(r));
  t('… une étape à la fois : ni heure ni « Connecter » avant le bon nombre (aucun bouton grisé, A656)', r.ends === 0 && !r.ok, JSON.stringify(r));
  const faux = r.nums.filter(n => n !== r.vrai);
  await ph.click(`[data-lkn="${faux[0]}"]`);
  const w = await ph.evaluate(() => ({ txt: document.getElementById('lkWarn').textContent, ok: !!document.querySelector('[data-lkok]'),
    fort: document.querySelector('[data-lkclose]').classList.contains('primary') }));
  t('mauvais nombre : refusé, dit, et rien ne part', /pas le nombre/.test(w.txt) && !w.ok && !w.fort && !(vu2.link_approve || []).length, JSON.stringify(w));
  await ph.click(`[data-lkn="${faux[1]}"]`);
  const w2 = await ph.evaluate(() => ({ txt: document.getElementById('lkWarn').textContent, fort: document.querySelector('[data-lkclose]').classList.contains('primary') }));
  t('… au 2ᵉ faux nombre : « Annulez », et « Annuler » devient le bouton fort', /Annulez/.test(w2.txt) && w2.fort, JSON.stringify(w2));
  await ph.click(`[data-lkn="${r.vrai}"]`);
  const r2 = await ph.evaluate(() => ({ ends: [...document.querySelectorAll('[data-lkend]')].map(b => b.textContent), on: !!document.querySelector('[data-lkend].on'),
    okl: (document.querySelector('.pp-okl') || {}).textContent || '', lbl: (document.querySelector('[data-lkok]') || {}).textContent || '' }));
  t('bon nombre : il est dit, puis l’heure de fin paraît (une présélectionnée) et « Connecter jusqu’à … »', /bien l’écran/.test(r2.okl) && r2.ends.length >= 1 && r2.on && /Connecter jusqu’à \S/.test(r2.lbl), JSON.stringify(r2));
  await ph.click('[data-lkok]');
  await ph.waitForFunction(() => /Appareil connecté/.test(document.getElementById('linkBody').textContent) && !!document.querySelector('[data-lkrevnow]'));
  const ap = (vu2.link_approve || [])[0] || {};
  const dt = Date.parse(ap.p_ends_at) - Date.now();
  t('approbation envoyée avec le secret et une heure de fin entre 1 h et 28 h', ap.p_id === LID && ap.p_secret === S && dt > 3600e3 - 60e3 && dt <= 28 * 3600e3, JSON.stringify(ap));
  await ph.click('[data-lkrevnow]');
  await ph.waitForFunction(() => /Appareil déconnecté/.test(document.getElementById('linkBody').textContent));
  t('« Rien ne s’ouvre devant vous ? Déconnecter » : un geste, et le poste est déconnecté', (vu2.link_revoke || []).some(x => x && x.p_id === LID));
  t('le fragment du lien est effacé de l’adresse', await ph.evaluate(() => !/lier=/.test(location.href)));
  // A656 : les connexions temporaires vivent DANS Moi — une rangée par appareil, l'échéance proche en ambre ; toucher
  // une rangée ouvre « gérer » (heure de fin, prolonger, déconnecter).
  const D1 = '1b6f3a2e-9c1d-4e5f-8a7b-1c2d3e4f5a6b';
  st2.devs = [{ id: LID, label: 'Chrome · Windows', since: new Date(Date.now() - 3600e3).toISOString(), ends_at: new Date(Date.now() + 9 * 3600e3).toISOString() },
    { id: D1, label: 'Safari · iPad', since: new Date(Date.now() - 7200e3).toISOString(), ends_at: new Date(Date.now() + 30 * 60e3).toISOString() }];
  await ph.evaluate(() => { Link.close(); Link._devAt = 0; openAuth(); });
  await ph.waitForSelector('#lkDevs [data-lkdev]');
  const m = await ph.evaluate(() => ({ rows: [...document.querySelectorAll('#lkDevs [data-lkdev]')].map(b => ({ t: b.textContent, soon: b.classList.contains('soon') })),
    scan: !!document.querySelector('#lkDevs [data-lkscan]'), fins: !!document.querySelector('#lkDevs [data-lkfins]'), menu2: !!document.querySelector('[data-lkdevs]') }));
  t('Moi : les appareils connectés sur place (plus de second menu), « Connecter un appareil » et « Mes fins de garde »', m.rows.length === 2 && m.scan && m.fins && !m.menu2, JSON.stringify(m));
  t('… l’échéance à moins d’une heure en ambre, dite par un glyphe et un mot', !m.rows[0].soon && m.rows[1].soon && /△ jusqu’à .* dans 30 min/.test(m.rows[1].t), JSON.stringify(m.rows));
  await ph.click(`[data-lkdev="${LID}"]`);
  await ph.waitForSelector('#linkModal.on [data-lkext]');
  const g = await ph.evaluate(() => ({ titre: document.getElementById('linkModalTitle').textContent, endt: document.querySelector('.pp-endt').textContent,
    ext: [...document.querySelectorAll('[data-lkext]')].map(b => +b.dataset.lkext) }));
  t('« gérer » : l’appareil nommé, son heure de fin en grand, ＋ 1 h', /Chrome · Windows/.test(g.titre) && /\d\d:\d\d/.test(g.endt) && g.ext.length >= 1, JSON.stringify(g));
  await ph.click('[data-lkext]');
  await ph.waitForFunction(() => (document.querySelector('.pp-endt') || {}).textContent);
  const ex = (vu2.link_extend || [])[0] || {};
  t('… ＋ 1 h part au serveur : une heure de plus que l’heure de fin', ex.p_id === LID && Math.abs(Date.parse(ex.p_ends_at) - Date.parse(st2.devs[0].ends_at) - 3600e3) < 2000, JSON.stringify(ex));
  await c2.close();
}

{
  console.log('\n── 4. Temporaire, par e-mail (sans appareil connecté sous la main, A651)');
  const c3 = await br.newContext({ viewport: { width: 1200, height: 900 } });
  const st3 = { verifyOk: true }, vu3 = {};
  await c3.route('**/*.supabase.co/**', bouchon(st3, vu3));
  const pg = await c3.newPage();
  await pg.goto(URL0);
  await amorce(pg);
  await pg.evaluate(() => openAuth());
  await pg.click('[data-authk="temp"]');
  await pg.click('[data-autht="email"]');
  await pg.waitForSelector('#authEmail');
  t('l’onglet « Par e-mail » arrête le code à viser (plus de demande ouverte en fond)', await pg.evaluate(() => !document.querySelector('#lkInline') && Link._cur !== 'inline'));
  await pg.fill('#authEmail', 'kim@test.local');
  await pg.click('#authSend');
  await pg.waitForSelector('#authCode');
  const r = await pg.evaluate(() => ({ ends: [...document.querySelectorAll('[data-authend]')].length, on: !!document.querySelector('[data-authend].on'), btn: document.getElementById('authVerify').textContent }));
  t('le code e-mail, puis l’heure de fin : le bouton dit jusqu’à quand', r.ends >= 2 && r.on && /Se connecter jusqu’à/.test(r.btn), JSON.stringify(r));
  await pg.fill('#authCode', '48207312');
  await pg.click('#authVerify');
  const okp = await apres(pg, u => localStorage.getItem('ac-space') === u && typeof linkShared === 'function' && !!linkShared() && !document.querySelector('.boot-load'), UID);
  const self = (vu3.link_self || [])[0] || {};
  t('la session se déclare appareil temporaire (link_self : empreinte de clé, libellé fermé, heure de fin)', okp && /^[0-9a-f]{64}$/.test(self.p_key_hash || '') && /·/.test(self.p_label || '') && Date.parse(self.p_ends_at) > Date.now(), JSON.stringify(self));
  const sp = await pg.evaluate(() => { const o = linkShared(); return o && { key: typeof o.key === 'string' && o.key.length >= 22, open: sessionStorage.getItem('ac-shared-open') }; });
  t('… et devient un poste partagé comme par le code à viser (clé gardée, onglet ouvert)', sp && sp.key && sp.open === '1', JSON.stringify(sp));
  await c3.close();
  // Refus du serveur (compte non validé) : la connexion NE RESTE PAS ouverte — on avait choisi « Temporaire ».
  const c4 = await br.newContext({ viewport: { width: 1200, height: 900 } });
  const st4 = { verifyOk: true, self: { ok: false, err: 'refused' } }, vu4 = {};
  await c4.route('**/*.supabase.co/**', bouchon(st4, vu4));
  const pg4 = await c4.newPage();
  await pg4.goto(URL0);
  await amorce(pg4);
  await pg4.evaluate(() => openAuth());
  await pg4.click('[data-authk="temp"]'); await pg4.click('[data-autht="email"]');
  await pg4.fill('#authEmail', 'kim@test.local'); await pg4.click('#authSend');
  await pg4.waitForSelector('#authCode'); await pg4.fill('#authCode', '48207312'); await pg4.click('#authVerify');
  // ⚠ Pas `document.body.textContent` : il inclut le texte du <script> inline, où ce message est écrit — témoin toujours vrai.
  await pg4.waitForFunction(() => /Connexion temporaire impossible/.test(_authStep.msg), null, { timeout: 8000 }).catch(() => {});
  const r4 = await pg4.evaluate(() => ({ signed: Auth.signedIn(), shared: !!linkShared(), msg: /Connexion temporaire impossible/.test((document.querySelector('#meView .auth-msg, #authBody .auth-msg') || {}).textContent || '') }));
  t('refusée, la connexion temporaire ne laisse PAS une connexion durable ouverte', !r4.signed && !r4.shared && r4.msg && (vu4.logout || 0) >= 1, JSON.stringify(r4));
  await c4.close();
}
{
  console.log('\n── 5. Les règles de la connexion temporaire (Administration, A654)');
  // Sur un appareil temporaire : les règles lues au serveur s'appliquent.
  const c5 = await br.newContext({ viewport: { width: 1200, height: 900 } });
  const st5 = { verifyOk: true, rules: { edit: 'non', del: 'non', repl: 'non', exp: 'non', dur: 12 } }, vu5 = {};
  await c5.route('**/*.supabase.co/**', bouchon(st5, vu5));
  const pg = await c5.newPage();
  await pg.goto(URL0);
  await amorce(pg);
  await pg.evaluate(() => openAuth());
  await pg.click('[data-authk="temp"]'); await pg.click('[data-autht="email"]');
  await pg.fill('#authEmail', 'kim@test.local'); await pg.click('#authSend');
  await pg.waitForSelector('#authCode'); await pg.fill('#authCode', '48207312'); await pg.click('#authVerify');
  await apres(pg, u => localStorage.getItem('ac-space') === u && typeof linkShared === 'function' && !!linkShared() && !document.querySelector('.boot-load'), UID);
  const self = (vu5.link_self || [])[0] || {};
  t('la durée maximale (12 h) borne l’heure de fin, même choisie avant la connexion', Date.parse(self.p_ends_at) - Date.now() <= 12 * 3600e3 + 60e3, JSON.stringify(self));
  await pg.evaluate(() => linkRulesFetch());
  const r = await pg.evaluate(async () => {
    const o = {}; const titre = () => { const m = document.getElementById('linkModal'); const x = m.classList.contains('on') ? document.getElementById('linkModalTitle').textContent : ''; Link.close(); return x; };
    await newFiche(); o.creer = titre(); o.vue = state.view;
    const dl = []; const ori = window.dlAnchor; window.dlAnchor = () => dl.push(1);
    await dlBlob(new Blob(['x']), 'x.txt'); o.exporter = titre(); o.dl = dl.length; window.dlAnchor = ori;
    return o; });
  t('« Créer » interdit par la règle : refusé, et dit pourquoi', /Pas sur un appareil temporaire/.test(r.creer) && r.vue !== 'edit', JSON.stringify(r));
  t('« Exporter » interdit par la règle : rien ne se télécharge', /Pas sur un appareil temporaire/.test(r.exporter) && r.dl === 0, JSON.stringify(r));
  await c5.close();
  // L'appareil qui approuve ne propose que des heures dans la durée maximale.
  const c6 = await br.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });
  const st6 = { rules: { dur: 12 } }, vu6 = {};
  await c6.route('**/*.supabase.co/**', bouchon(st6, vu6));
  const ph = await c6.newPage();
  await ph.goto(URL0); await amorce(ph);
  await ph.evaluate(() => { Auth._setSession({ access_token: 'at', refresh_token: 'rt', expires_in: 3600, user: { id: 'cdcdcdcd-cdcd-cdcd-cdcd-cdcdcdcdcdcd', email: 'ana@test.local' } });
    localStorage.setItem('ac-space', 'cdcdcdcd-cdcd-cdcd-cdcd-cdcdcdcdcdcd'); });
  await ph.reload();
  await ph.waitForFunction(() => typeof Auth !== 'undefined' && Auth.signedIn() && !document.querySelector('.boot-load'));
  await ph.evaluate(() => linkRulesFetch());
  await ph.evaluate(([id, sct]) => Link.approve({ id, secret: sct }, true), [LID, 'Q2xLk9_aZ0b-Xy7Pq3RsTu']);
  await ph.waitForSelector('#linkModal.on [data-lkn]');
  await ph.evaluate(sct => document.querySelector(`[data-lkn="${linkCheckNum(sct)}"]`).click(), 'Q2xLk9_aZ0b-Xy7Pq3RsTu');   // A656 : l'heure suit le bon nombre
  await ph.waitForSelector('#linkModal.on [data-lkend]');
  const ends = await ph.evaluate(() => [...document.querySelectorAll('[data-lkend]')].map(b => +b.dataset.lkend - Date.now()));
  t('l’appareil qui approuve ne propose aucune heure au-delà de la durée maximale', ends.length >= 1 && ends.every(x => x <= 12 * 3600e3), JSON.stringify(ends.map(x => Math.round(x / 36e5))));
  await c6.close();
  // Administration › Règles : la section se lit et chaque choix part au serveur.
  const c7 = await br.newContext({ viewport: { width: 1280, height: 900 } });
  const st7 = {}, vu7 = {};
  await c7.route('**/*.supabase.co/**', bouchon(st7, vu7));
  const pa = await c7.newPage();
  await pa.goto(URL0); await amorce(pa);
  const adm = await pa.evaluate(async () => {
    myIsAppAdmin = true; _admD = null;
    await openAdmin('regles'); await __acCalme(800);
    const rows = [...document.querySelectorAll('.adm-trow')].length;
    const b = document.querySelector('[data-trk="edit"][data-trv="non"]'); if (b) b.click();
    await __acCalme(800);
    return { rows, bouton: !!b };
  });
  const set = (vu7.set_temp_rules || [])[0] || {};
  t('Administration › Règles : la section « Connexion temporaire » (5 règles + 2 interdits fixes)', adm.rows === 7 && adm.bouton, JSON.stringify(adm));
  t('… un choix part au serveur (set_temp_rules)', set.p_rules && set.p_rules.edit === 'non', JSON.stringify(set));
  await c7.close();
}
{
  console.log('\n── 6. Déconnecté depuis un autre appareil : l’appareil s’arrête aussitôt (A655)');
  // Signalé : « je peux continuer à modifier mes fiches et lancer des sessions jusqu'à ce que je recharge la page ».
  // Une session terminée pas encore envoyée retient l'effacement (rien ne se perd en silence) : c'est le cas signalé.
  const c8 = await br.newContext({ viewport: { width: 1200, height: 900 } });
  const st8 = { verifyOk: true, rules: { edit: 'libre', del: 'tel', repl: 'non', exp: 'oui', dur: 28 } }, vu8 = {};
  await c8.route('**/*.supabase.co/**', bouchon(st8, vu8));
  const pg = await c8.newPage();
  await pg.goto(URL0);
  await amorce(pg);
  await pg.evaluate(() => openAuth());
  await pg.click('[data-authk="temp"]'); await pg.click('[data-autht="email"]');
  await pg.fill('#authEmail', 'kim@test.local'); await pg.click('#authSend');
  await pg.waitForSelector('#authCode'); await pg.fill('#authCode', '48207312'); await pg.click('#authVerify');
  await apres(pg, u => localStorage.getItem('ac-space') === u && typeof linkShared === 'function' && !!linkShared() && !document.querySelector('.boot-load'), UID);
  await pg.evaluate(async () => { await linkRulesFetch(); Link.close();
    const f = blankFiche(); f.title = 'Aide du poste'; fiches.push(f);
    await Data.putSession({ id: 's-poste-z', ficheId: f.id, ficheTitle: 'x', savedAt: Date.now(), startedAt: Date.now() - 6e4, live: false, dirty: true,
      checked: {}, verified: {}, vgaps: {}, counters: {}, timers: {}, nav: [], navSeq: [], events: [] }); });
  const avant = await pg.evaluate(() => ({ over: linkOver(), locked: linkLocked() }));
  t('connecté : l’appareil n’est pas « fini » (règle libre : rien de verrouillé)', !avant.over && !avant.locked, JSON.stringify(avant));
  st8.poll = { ok: true, status: 'revoked', ends_at: new Date(Date.now() + 9 * 3600e3).toISOString() };
  const lus = (vu8.link_poll || []).length;
  await pg.evaluate(() => Link.watch());
  await pg.waitForFunction(() => document.getElementById('linkModal').classList.contains('on'), null, { timeout: 8000 });
  const r = await pg.evaluate(() => ({ rev: linkShared() && linkShared().revoked, titre: document.getElementById('linkModalTitle').textContent,
    corps: document.getElementById('linkBody').textContent, fiches: fiches.length, ask: Link._ask }));
  t('la veille apprend la déconnexion : retenue sur le disque, et dit une fois', r.rev === true && /Appareil déconnecté/.test(r.titre) && (vu8.link_poll || []).length > lus, JSON.stringify(r));
  t('… la session pas encore envoyée est NOMMÉE (PDF depuis « Sessions »), l’appareil pas effacé en silence', /pas rejoint votre historique/.test(r.corps) && r.fiches === 1 && r.ask, JSON.stringify(r));
  await pg.evaluate(() => Link.close());
  const g = await pg.evaluate(async () => { const o = {}; const titre = () => { const m = document.getElementById('linkModal');
      const x = m.classList.contains('on') ? document.getElementById('linkModalTitle').textContent : ''; Link.close(); return x; };
    await newFiche(); o.creer = titre(); o.vueCreer = state.view;
    const f = fiches[0]; openRead(f.id); await __acCalme(300);
    o.demarre = startSessionGesture(); o.sess = titre(); o.started = !!(Runtime && Runtime.started);
    state.view = 'library'; render();
    o.band = (document.getElementById('linkBand') || {}).textContent || '';
    return o; });
  t('« Créer » refusé : « Appareil déconnecté », l’éditeur ne s’ouvre pas', /Appareil déconnecté/.test(g.creer) && g.vueCreer !== 'edit', JSON.stringify(g));
  t('… aucune NOUVELLE session ne démarre', g.demarre === false && !g.started && /Appareil déconnecté/.test(g.sess), JSON.stringify(g));
  t('… la bande de l’accueil le dit', /Déconnecté depuis un autre appareil/.test(g.band), g.band);
  const tables = [];
  pg.on('request', q => { if (/\/rest\/v1\/(?!rpc)/.test(q.url())) tables.push(q.url()); });
  await pg.evaluate(() => Sync.full());
  await pg.waitForTimeout(400);   // horloge : témoin négatif (aucune requête ne doit partir)
  t('… la synchro ne tourne plus (le serveur lui ferme les tables, A655)', tables.length === 0, JSON.stringify(tables.slice(0, 3)));
  // Un rechargement ne rouvre RIEN avant la veille : l'état est sur le disque.
  st8.poll = { ok: true, status: 'pending' };   // même si la veille ne répondait pas comme il faut
  await pg.reload();
  await pg.waitForFunction(() => typeof linkShared === 'function' && !!linkShared() && !document.querySelector('.boot-load'));
  const rl = await pg.evaluate(async () => { const over = linkOver(); await newFiche();
    const m = document.getElementById('linkModal').classList.contains('on'); return { over, m, vue: state.view }; });
  t('rechargé : toujours fini, « Créer » toujours refusé', rl.over && rl.m && rl.vue !== 'edit', JSON.stringify(rl));
  await c8.close();
}
{
  console.log('\n── 7. L’heure de fin passe EN PLEINE SESSION : la session continue jusqu’au bout (règle 11, A655)');
  // Question de l'auteur : « tout en permettant une session en cours dans le cas où la connexion expire ? ». Fin passée,
  // l'appareil est « fini » — mais la session en cours garde ses gestes, se sauvegarde par le DÉPÔT (le serveur ferme
  // les tables à la session du poste), puis rejoint l'historique ; l'effacement n'a lieu qu'après.
  const c9 = await br.newContext({ viewport: { width: 1200, height: 900 } });
  const st9 = { verifyOk: true }, vu9 = {};
  await c9.route('**/*.supabase.co/**', bouchon(st9, vu9));
  const pg = await c9.newPage();
  await pg.goto(URL0);
  await amorce(pg);
  await pg.evaluate(() => openAuth());
  await pg.click('[data-authk="temp"]'); await pg.click('[data-autht="email"]');
  await pg.fill('#authEmail', 'kim@test.local'); await pg.click('#authSend');
  await pg.waitForSelector('#authCode'); await pg.fill('#authCode', '48207312'); await pg.click('#authVerify');
  await apres(pg, u => localStorage.getItem('ac-space') === u && typeof linkShared === 'function' && !!linkShared() && !document.querySelector('.boot-load'), UID);
  await pg.evaluate(() => Link.close());
  await amorce(pg);
  await ouvrirFiche(pg, /arr[êe]t|anaphyl|./);
  await demarrerSession(pg);
  // L'heure de fin passe : le serveur dit « ended », l'appareil le sait.
  st9.poll = { ok: true, status: 'ended', ends_at: new Date(Date.now() - 60e3).toISOString() };
  await pg.evaluate(() => { const sp = linkShared(); linkSharedSet(Object.assign({}, sp, { endsAt: Date.now() - 60e3 })); });
  vu9.link_deposit = []; vu9.sessions = [];
  await pg.evaluate(async () => { Runtime._lkCkpt = 0; Runtime.lastActAt = Date.now(); await Link.watch(); });
  const a = await pg.evaluate(() => ({ over: linkOver(), sp: !!linkShared(), started: !!Runtime.started, modal: document.getElementById('linkModal').classList.contains('on') }));
  t('fin passée pendant la session : rien n’est effacé, la session reste ouverte, aucune fenêtre', a.over && a.sp && a.started && !a.modal, JSON.stringify(a));
  const g = await pg.evaluate(async () => { const n0 = Object.values(Runtime.checked || {}).filter(Boolean).length;
    const li = document.querySelector('ol.steps li[data-ck]'); if (li) li.click(); await __acCalme(300);
    return { li: !!li, n0, n1: Object.values(Runtime.checked || {}).filter(Boolean).length,
      modal: document.getElementById('linkModal').classList.contains('on') }; });
  t('… et ses gestes répondent (une étape se coche, sans « Appareil déconnecté »)', g.li && g.n1 > g.n0 && !g.modal, JSON.stringify(g));
  const d = (vu9.link_deposit || []).find(x => x && x.p_row && x.p_row.data && x.p_row.data.checkpoint);
  t('… sa sauvegarde part par le DÉPÔT, pas par les tables (fermées au poste après l’heure)', !!d && !(vu9.sessions || []).length, JSON.stringify({ dep: (vu9.link_deposit || []).length, rest: (vu9.sessions || []).length }));
  await pg.evaluate(() => { const ob = window.toast; window.__lkT = []; window.toast = (m, ...x) => { window.__lkT.push(String(m)); return ob(m, ...x); }; });
  await pg.evaluate(() => Link.wipe(false));
  t('… et l’effacement attend la fin de la session', await pg.evaluate(() => !!linkShared() && window.__lkT.some(s => /session est en cours/.test(s))));
  vu9.link_deposit = [];
  await pg.evaluate(async () => { const id = Runtime.sessionId; window.__lkSid = id; endSession(Runtime);
    await new Promise(r => setTimeout(r, 300));   // horloge : écriture IndexedDB de l'archive
    Link.watch().catch(() => {}); });
  const sid = await pg.evaluate(() => window.__lkSid);
  await apres(pg, () => localStorage.getItem('ac-space') === '' && typeof linkShared === 'function' && !document.querySelector('.boot-load') && !linkShared());
  t('session terminée : elle est DÉPOSÉE dans l’historique, puis l’appareil s’efface', (vu9.link_deposit || []).some(x => x && x.p_row && x.p_row.id === sid && !x.p_row.data.checkpoint)
    && await pg.evaluate(() => !linkShared()), JSON.stringify((vu9.link_deposit || []).map(x => x && x.p_row && x.p_row.id)));
  await c9.close();
}
await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles connexion par le téléphone OK` + (ko ? ` — ${ko} ÉCHEC(S)` : ''));
process.exit(ko ? 1 : 0);
