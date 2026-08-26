#!/usr/bin/env node
/* AUDIT — SERVICE WORKER : le cache du DOCUMENT survit-il à un hébergeur qui normalise les URL ?
 * (v5.17.3)
 *
 * POURQUOI CE HARNAIS EXISTE. Le hors-ligne est la fonction dont tout dépend en intervention, et
 * `check-sw.mjs` ne mesure que du STATIQUE (entrées présentes sur le disque, noyau ⊆ ASSETS,
 * CACHE aligné). Le comportement DYNAMIQUE — installer, mettre en cache, servir une navigation —
 * n'était mesuré par rien. Un défaut y a vécu et a cassé l'application ENTIÈREMENT sur iPhone,
 * signalé à l'usage : « Safari ne peut pas ouvrir la page — Response served by service worker
 * has redirections ».
 *
 * LE DÉFAUT, ET POURQUOI IL ÉTAIT INVISIBLE. Une requête de navigation a le mode de redirection
 * "manual" : lui servir depuis le cache une réponse dont le drapeau `redirected` est vrai est une
 * ERREUR RÉSEAU. L'hébergeur normalise les URL et redirige `/index.html` vers `/` (Cloudflare
 * Workers Assets ; GitHub Pages ne le faisait pas, d'où l'apparition à la bascule d'août 2026) ;
 * `fetch` suit la redirection, la réponse porte `redirected: true`, et `addAll` la rangeait telle
 * quelle. WebKit refuse net, **Chromium tolère** — le défaut ne se voyait donc pas sur la machine
 * de développement, et il était fatal sur la cible principale. C'est la raison d'être de ce
 * harnais : mesurer le cas SUR LES DEUX MOTEURS (`AC_ENGINE=webkit npm run audit -- sw`).
 *
 * CE QU'IL MESURE, ET COMMENT. Le SUJET est ici le comportement du SERVEUR : il ne peut donc pas
 * utiliser `serveApp()` de `harness.mjs`, qui sert les fichiers à plat sans jamais rediriger.
 * Deux serveurs sont montés — l'un qui redirige `/index.html` vers `/` en 307 (Cloudflare),
 * l'autre qui sert à plat (GitHub Pages, intranet) — et les MÊMES contrôles sont joués sur les
 * deux : le second existe pour prouver que le correctif n'a pas cassé le chemin normal.
 *
 * ⚠ PAS `amorce()` ici, et ce n'est pas une copie oubliée : ce harnais ne veut pas ENTRER dans
 * l'application. Il mesure ce qui se passe AVANT tout usage — l'installation du worker et le
 * contenu de son cache. Amorcer masquerait le sujet derrière un parcours d'accueil.
 */
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname } from 'node:path';
import { ROOT, moteur, NOM_MOTEUR } from './harness.mjs';

const MIME = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.webmanifest': 'application/manifest+json',
  '.css': 'text/css', '.png': 'image/png', '.svg': 'image/svg+xml', '.ico': 'image/x-icon',
  '.woff2': 'font/woff2', '.txt': 'text/plain; charset=utf-8'
};

/* `redirigeIndex` reproduit la normalisation d'URL de l'hébergeur : /index.html -> / en 307.
   C'est LE paramètre de ce harnais ; tout le reste est un serveur de fichiers ordinaire. */
async function serveur(redirigeIndex) {
  const srv = createServer(async (q, r) => {
    let p = decodeURIComponent(q.url.split('?')[0]);
    if (redirigeIndex && p === '/index.html') {
      r.writeHead(307, { location: '/' }); r.end(); return;
    }
    if (p === '/') p = '/index.html';
    try {
      const b = await readFile(ROOT + p.replace(/^\/+/, ''));
      r.writeHead(200, { 'content-type': MIME[extname(p)] || 'application/octet-stream' });
      r.end(b);
    } catch { r.writeHead(404); r.end('nf'); }
  });
  const port = await new Promise(res => srv.listen(0, () => res(srv.address().port)));
  return { port, srv };
}

/* ⚠ NE PAS UTILISER `page.waitForFunction` AVEC UN PRÉDICAT `async` (piège payé en écrivant ce
   harnais). Le prédicat renvoie alors une PROMESSE, qui est toujours vraie : l'attente réussit au
   premier sondage sans rien avoir vérifié, et la sonde mesure ensuite un état pas encore écrit.
   Le symptôme était trompeur au possible — un cache rapporté VIDE alors qu'un dump de
   `cache.keys()` montrait les entrées bien présentes. Tout ce qui doit s'attendre ici demande une
   lecture ASYNCHRONE (`caches`), donc l'attente est pilotée depuis Node, où le `await` est réel. */
async function attendre(page, fn, ms = 20000) {
  const t0 = Date.now();
  for (;;) {
    try { if (await page.evaluate(fn)) return true; } catch { /* page en navigation */ }
    if (Date.now() - t0 > ms) return false;
    await page.waitForTimeout(200);
  }
}

const br = await moteur().launch();
let ok = 0, ko = 0;
const t = (nom, cond, det) => { if (cond) { ok++; console.log('  ✓ ' + nom); }
  else { ko++; console.log('  ✗ ' + nom + (det ? '\n      ' + det : '')); } };

console.log(`\n══ SERVICE WORKER · cache du document — moteur ${NOM_MOTEUR} ══`);

for (const [nom, redirige] of [['hébergeur qui NORMALISE (/index.html -> 307 /)', true],
                               ['hébergeur qui sert à PLAT', false]]) {
  const { port, srv } = await serveur(redirige);
  // Contexte NEUF à chaque cas : registre de workers et caches vierges (piège v4.30.0 — sans
  // cela on mesurerait la version précachée par le cas précédent).
  const ctx = await br.newContext();
  const page = await ctx.newPage();
  console.log(`\n── ${nom}`);

  await page.goto(`http://localhost:${port}/`);
  /* On attend la CONDITION RÉELLE, pas l'activation : un worker `active` n'a pas forcément fini
     d'écrire son cache, et l'écart est systématique sur WebKit. La condition qui compte est : le
     document est DANS le cache. URL ABSOLUE pour le `match` — sur WebKit, `match('./index.html')`
     ne retrouve pas une entrée pourtant présente (vérifié en dumpant `cache.keys()`). */
  const installe = await attendre(page, async () => {
    const rs = await navigator.serviceWorker.getRegistrations();
    if (!rs.some(r => r.active)) return false;
    const app = (await caches.keys()).find(n => /^aides-cognitives-v/.test(n));
    if (!app) return false;
    return !!(await (await caches.open(app)).match(new URL('./index.html', location.href).href));
  });
  t('le worker s’installe, s’active et remplit son cache', installe);

  const etat = await page.evaluate(async () => {
    const noms = await caches.keys();
    const app = noms.find(n => /^aides-cognitives-v/.test(n));
    if (!app) return { app: null };
    const c = await caches.open(app);
    const abs = r => new URL(r, location.href).href;   // cf. le commentaire ci-dessus (WebKit)
    const doc = await c.match(abs('./index.html'));
    const man = await c.match(abs('./manifest.webmanifest'));
    return {
      app,
      docPresent: !!doc,
      docRedirige: doc ? doc.redirected : null,
      docStatut: doc ? doc.status : null,
      docType: doc ? (doc.headers.get('content-type') || '') : '',
      docOctets: doc ? (await doc.clone().text()).length : 0,
      docEstApp: doc ? (await doc.clone().text()).includes('APP_VERSION') : false,
      manPresent: !!man,
      nbCaches: noms.length
    };
  });

  t('le NOYAU est en cache (document + manifeste)', etat.docPresent && etat.manPresent,
    JSON.stringify({ doc: etat.docPresent, manifeste: etat.manPresent }));
  // LE contrôle de ce harnais. Une entrée redirigée = « Response served by service worker has
  // redirections » à la navigation suivante, donc application morte sur WebKit.
  t('le document en cache n’est PAS une réponse redirigée', etat.docRedirige === false,
    `redirected=${etat.docRedirige} statut=${etat.docStatut}`);
  t('… et c’est bien l’application, pas une page d’erreur', etat.docEstApp === true,
    `${etat.docOctets} octets, type « ${etat.docType} »`);

  // Le symptôme lui-même : une seconde navigation est servie PAR le worker depuis ce cache.
  const rechargee = await page.reload({ timeout: 15000 })
    .then(async () => {
      // Même précaution : `controller` est posé de façon asynchrone après `clients.claim()`.
      await attendre(page, () => !!navigator.serviceWorker.controller, 10000);
      return page.evaluate(() => ({
        titre: document.title,
        controlee: !!navigator.serviceWorker.controller,
        app: !!document.querySelector('#app, main, body > *')
      }));
    })
    .catch(e => ({ erreur: String(e).slice(0, 120) }));
  t('une navigation servie par le worker aboutit', !rechargee.erreur && rechargee.titre === 'Aides cognitives',
    rechargee.erreur || `titre=« ${rechargee.titre} »`);
  t('… et la page est bien contrôlée par le worker', rechargee.controlee === true);

  await ctx.close(); srv.close();
}

await br.close();
console.log(`\n${ok}/${ok + ko} contrôles service worker OK`);
process.exit(ko ? 1 : 0);
