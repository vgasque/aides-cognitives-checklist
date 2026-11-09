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
      return J(null);
    }
    if (p === '/functions/v1/link-claim') { (vu.claim = vu.claim || []).push(body);
      return J({ ok: true, ends_at: srvst.ends, session: { access_token: 'at', refresh_token: 'rt', expires_at: Math.floor(Date.now() / 1000) + 3600, user: { id: UID, email: 'kim@test.local' } } }); }
    if (p === '/auth/v1/verify') { (vu.verify = vu.verify || []).push(body); return J({}); }
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
  await page.waitForSelector('#authLink');
  await page.click('#authLink');
  await page.waitForSelector('#linkModal.on .pp-qr svg');
  const r1 = await page.evaluate(() => ({ num: (document.querySelector('.pp-num') || {}).textContent,
    exp: (document.getElementById('lkExp') || {}).textContent, titre: document.getElementById('linkModalTitle').textContent }));
  t('le poste montre un QR et un nombre de contrôle', /^\d{2}$/.test(r1.num || ''), JSON.stringify(r1));
  t('… avec son compte à rebours', /Expire dans \d:\d\d/.test(r1.exp || ''), r1.exp);
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
  t('la bande de l’accueil dit « Poste partagé », le compte et l’heure de fin', /Poste partagé/.test(band) && /kim@test\.local/.test(band) && /jusqu’à/.test(band), band);
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
  t('poste partagé : l’Administration est refusée, et dit pourquoi', adm.on && /Pas sur un poste partagé/.test(adm.titre) && !adm.adm, JSON.stringify(adm));
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
  t('poste partagé : supprimer demande le TÉLÉPHONE, même déverrouillé', del.on && /Confirmer avec le téléphone/.test(del.titre) && !del.conf, JSON.stringify(del));
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
    ends: [...document.querySelectorAll('[data-lkend]')].map(b => b.textContent), on: !!document.querySelector('[data-lkend].on'),
    dis: document.querySelector('[data-lkok]').disabled, label: document.querySelector('.pp-dev').textContent }), S);
  t('feuille : le poste nommé, trois nombres dont le vrai', r.nums.length === 3 && r.nums.includes(r.vrai) && /Chrome · Windows/.test(r.label), JSON.stringify(r));
  t('… des heures de fin, une présélectionnée', r.ends.length >= 2 && r.on, JSON.stringify(r.ends));
  t('… « Connecter » fermé tant que le nombre n’est pas choisi', r.dis === true);
  const faux = r.nums.find(n => n !== r.vrai);
  await ph.click(`[data-lkn="${faux}"]`);
  const w = await ph.evaluate(() => ({ txt: document.getElementById('lkWarn').textContent, dis: document.querySelector('[data-lkok]').disabled }));
  t('mauvais nombre : refusé, dit, et rien ne part', /pas le nombre/.test(w.txt) && w.dis && !(vu2.link_approve || []).length, JSON.stringify(w));
  await ph.click(`[data-lkn="${r.vrai}"]`);
  await ph.click('[data-lkok]');
  await ph.waitForFunction(() => /Ordinateur connecté/.test(document.getElementById('linkBody').textContent));
  const ap = (vu2.link_approve || [])[0] || {};
  const dt = Date.parse(ap.p_ends_at) - Date.now();
  t('approbation envoyée avec le secret et une heure de fin entre 1 h et 28 h', ap.p_id === LID && ap.p_secret === S && dt > 3600e3 - 60e3 && dt <= 28 * 3600e3, JSON.stringify(ap));
  await ph.click('[data-lkrevnow]');
  await ph.waitForFunction(() => /déconnecté/.test(document.getElementById('linkBody').textContent));
  t('« Rien ne s’ouvre devant vous ? Déconnecter » : un geste, et le poste est déconnecté', (vu2.link_revoke || []).some(x => x && x.p_id === LID));
  t('le fragment du lien est effacé de l’adresse', await ph.evaluate(() => !/lier=/.test(location.href)));
  await c2.close();
}

await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles connexion par le téléphone OK` + (ko ? ` — ${ko} ÉCHEC(S)` : ''));
process.exit(ko ? 1 : 0);
