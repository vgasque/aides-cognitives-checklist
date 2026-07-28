#!/usr/bin/env node
/* AUDIT — HISTORIQUE DE SESSIONS SYNCHRONISÉ (v4.54.2)
 *
 * Il a été livré en v4.54.0 et ne synchronisait RIEN. La table existait, les politiques RLS
 * étaient vertes, la bascule s'allumait — et pas une ligne ne partait, parce que `_pushTable` ne
 * pousse que les objets portant `dirty` et qu'aucun site n'en posait jamais sur une session.
 * Trois symptômes, une cause et demie : le réglage lui-même n'entrait pas non plus dans les
 * préférences synchronisées, donc la bascule restait éteinte sur le second appareil.
 *
 * Les tests unitaires prouvent la FORME de ce qui monte (`sessionToRow`). Ils ne peuvent pas
 * prouver qu'une ligne PART : cela demande le stockage réel, la vraie chaîne d'écriture et le vrai
 * `_pushTable`. D'où ce harnais, qui bouchonne le transport et regarde ce qui SERAIT envoyé.
 */
import { serveApp, moteur, NOM_MOTEUR } from './harness.mjs';

const { port, srv } = await serveApp();
const br = await moteur().launch();
let ok = 0, ko = 0;
const t = (nom, cond, det) => { if (cond) { ok++; console.log('  ✓ ' + nom); }
  else { ko++; console.log('  ✗ ' + nom + (det ? '\n      ' + det : '')); } };

console.log(`\n══ HISTORIQUE · ce qui monte, et ce qui reste — moteur ${NOM_MOTEUR} ══`);
{
  const page = await br.newPage({ viewport: { width: 1100, height: 900 } });
  await page.goto(`http://localhost:${port}/index.html`);
  await page.waitForFunction(() => !document.querySelector('.boot-load'));
  await page.evaluate(async () => {
    const b = [...document.querySelectorAll('button')].find(x => /Commencer/.test(x.textContent));
    if (b) b.click();
    await new Promise(r => setTimeout(r, 120));
    const s = [...document.querySelectorAll('button')].find(x => x.textContent.includes("fiches d'exemple"));
    if (s) s.click();
    await new Promise(r => setTimeout(r, 400));
  });

  const r = await page.evaluate(async () => {
    const out = {};
    const f = fiches[0];
    const neuve = (id, extra) => Object.assign({ id, ficheId: f.id, ficheTitle: f.title,
      savedAt: Date.now(), startedAt: Date.now() - 60e3, live: false, checked: {},
      verified: {}, vgaps: {}, counters: {}, timers: {}, nav: [], navSeq: [], events: [] }, extra || {});

    // Un historique qui existait AVANT que l'option ne soit connue.
    for (const n of [1, 2]) await Data.putSession(neuve('s-av-' + n, { savedAt: Date.now() - n * 3600e3 }));
    out.avantMarquees = (await Data.getSessions()).filter(x => x.dirty).length;

    // Transport bouchonné : on veut savoir ce qui PARTIRAIT, pas joindre un serveur.
    const envoi = [];
    window.rest = async (m, u, b) => {
      if (m === 'POST' && /\/sessions/.test(u)) envoi.push(...(b || []));
      return {}; };
    Auth.user = () => ({ id: 'uid-1' });
    Auth.signedIn = () => true;

    // 1 — SANS l'option, rien ne part. Le garde est en tête de la fonction, pas chez l'appelant.
    await Sync._pushSessions();
    out.sansOption = envoi.length;

    // 2 — L'ACTIVATION RATTRAPE L'EXISTANT. Sans cela, « synchroniser » ne synchronise que
    // l'avenir : ce que l'utilisateur demande en activant, c'est de retrouver ce qu'il A DÉJÀ.
    setSessSync(true);
    await new Promise(x => setTimeout(x, 400));
    out.rattrapees = (await Data.getSessions()).filter(x => x.dirty).length;
    await Sync._pushSessions();
    out.anterieures = envoi.map(x => x.id).sort();
    // `savedAt` est l'heure du SOIN : elle ne se réécrit pas parce qu'on a changé un réglage.
    const av = (await Data.getSessions()).find(x => x.id === 's-av-1');
    out.savedAtIntact = av && Math.abs(av.savedAt - (Date.now() - 3600e3)) < 60e3;

    // 3 — Une session terminée APRÈS l'activation. Toute écriture réelle passe par
    // `_putSessionSafe` : c'est LE point d'étranglement, et c'est là que le marquage vit.
    envoi.length = 0;
    _putSessionSafe(neuve('s-ap-1', { verified: { '1:b:0': { a: null, t: 3 } } }));
    await new Promise(x => setTimeout(x, 250));
    await Sync._pushSessions();
    out.posterieures = envoi.map(x => x.id);

    // 4 — CE QUI NE MONTE PAS, ET QUI LE DIT. La trace do-verify reste sur l'appareil qui l'a
    // produite ; une absence qui ne s'annonce pas se lirait « aucune vérification n'a été faite ».
    out.traceRestee = !envoi.some(x => x.data && (x.data.verified || x.data.vgaps));
    out.absenceDite = envoi.some(x => x.data && x.data.vElsewhere === true);

    // 5 — Une session VIVE ne part jamais : ce serait un second canal de partage, sans code, sans
    // rôle et sans péremption.
    envoi.length = 0;
    _putSessionSafe(neuve('s-live', { live: true }));
    await new Promise(x => setTimeout(x, 200));
    await Sync._pushSessions();
    out.viveEnvoyee = envoi.some(x => x.id === 's-live');

    // 6 — LE RÉGLAGE LUI-MÊME VOYAGE, sinon la bascule reste éteinte sur le second appareil.
    let prefs = null;
    window.rest = async (m, u, b) => {
      if (m === 'POST' && /category_sets/.test(u) && b && b[0] && b[0].data) prefs = b[0].data.prefs;
      return {}; };
    try { localStorage.setItem(spaceKey('ac-cats-dirty:'), '1'); } catch (e) {}
    await Sync._syncCats();
    out.reglageDansPrefs = !!(prefs && typeof prefs.syncSessions === 'boolean');
    out.reglageValeur = prefs && prefs.syncSessions;

    // 7 — … et il est RELU. On simule l'arrivée d'une préférence distante qui l'éteint.
    _sessSyncWrite(false);
    out.eteintParPull = sessSyncOn() === false;

    /* 8 — LE CAS QUI A ÉCHAPPÉ À LA PREMIÈRE CORRECTION : un utilisateur qui avait activé
       l'option quand elle ne poussait rien (v4.54.0). Sa clé vaut déjà « 1 » : il ne reverra
       JAMAIS la transition éteint -> allumé, et un rattrapage gardé par cette transition ne
       s'exécuterait jamais chez lui — c'est-à-dire chez les personnes qui ont signalé le défaut.
       On reproduit exactement cet état : option déjà active, rattrapage jamais fait. */
    envoi.length = 0;
    // L'étape 6 avait remplacé le bouchon par celui des préférences : sans ce rétablissement, la
    // sonde ne voyait plus AUCUNE session partir et accusait l'application de son propre oubli.
    window.rest = async (m, u, b) => {
      if (m === 'POST' && /\/sessions/.test(u)) envoi.push(...(b || []));
      return {}; };
    try { localStorage.setItem(spaceKey('ac-sync-sessions'), '1');
          localStorage.removeItem(spaceKey('ac-sess-backfilled')); } catch (e) {}
    for (const x of await Data.getSessions()) { if (x.dirty) { delete x.dirty; await Data.putSession(x); } }
    out.dejaActifMarquees0 = (await Data.getSessions()).filter(x => x.dirty).length;
    _sessSyncWrite(true);                      // aucune transition : la clé valait déjà « 1 »
    await new Promise(x => setTimeout(x, 500));
    out.dejaActifRattrapees = (await Data.getSessions()).filter(x => x.dirty).length;
    await Sync._pushSessions();
    out.dejaActifPoussees = envoi.length;
    // … et le rattrapage ne se rejoue pas à chaque appel : la clé durable le dit.
    for (const x of await Data.getSessions()) { if (x.dirty) { delete x.dirty; await Data.putSession(x); } }
    _sessSyncWrite(true);
    await new Promise(x => setTimeout(x, 350));
    out.pasDeRejeu = (await Data.getSessions()).filter(x => x.dirty).length === 0;
    return out;
  });

  t('témoin : l’historique existant n’est pas marqué au départ', r.avantMarquees === 0, String(r.avantMarquees));
  t('sans l’option, RIEN ne part', r.sansOption === 0, `${r.sansOption} ligne(s)`);
  t('activer RATTRAPE l’existant', r.rattrapees >= 2, `${r.rattrapees} marquée(s)`);
  t('… et les sessions ANTÉRIEURES partent',
    r.anterieures.join(',') === 's-av-1,s-av-2', JSON.stringify(r.anterieures));
  t('… sans réécrire l’heure du soin', r.savedAtIntact === true);
  t('une session terminée APRÈS part aussi',
    r.posterieures.indexOf('s-ap-1') >= 0, JSON.stringify(r.posterieures));
  t('la trace do-verify RESTE sur l’appareil', r.traceRestee === true);
  t('… et son absence est DITE', r.absenceDite === true);
  t('une session VIVE ne part jamais', r.viveEnvoyee === false);
  t('le réglage voyage dans les préférences', r.reglageDansPrefs === true, JSON.stringify(r.reglageValeur));
  t('… avec sa vraie valeur', r.reglageValeur === true);
  t('… et une préférence distante l’éteint', r.eteintParPull === true);
  /* Le cas des utilisateurs DÉJÀ activés en v4.54.0 : leur clé vaut « 1 », ils ne reverront jamais
     la transition. Un rattrapage gardé par elle ne les couvrirait pas — donc ne couvrirait pas
     ceux qui ont signalé le défaut. */
  t('témoin : rien n’est marqué au départ', r.dejaActifMarquees0 === 0, String(r.dejaActifMarquees0));
  t('déjà activé en v4.54.0 : l’historique est RATTRAPÉ quand même',
    r.dejaActifRattrapees >= 2, `${r.dejaActifRattrapees} marquée(s)`);
  t('… et il part', r.dejaActifPoussees >= 2, `${r.dejaActifPoussees} ligne(s)`);
  t('… mais le balayage ne se rejoue pas à chaque appel', r.pasDeRejeu === true);
  await page.close();
}

await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles historique OK` + (ko ? ` — ${ko} ÉCHEC(S)` : ''));
process.exit(ko ? 1 : 0);
