// =============================================================================
//  Service worker — fonctionnement hors ligne + MISE À JOUR AUTOMATIQUE du code.
//
//  Stratégie :
//   - Navigation (la page index.html) : "CACHE D'ABORD" (v4.4.6). Dès qu'une copie locale
//     existe, elle est servie IMMÉDIATEMENT — zéro attente réseau à l'ouverture, quel que soit
//     l'état du Wi-Fi (l'app est ouverte en urgence : la v4.4.4 avait réduit l'attente
//     réseau-d'abord de 3,5 à 1,5 s ; le cache d'abord la supprime). Le fetch réseau part
//     quand même en arrière-plan et rafraîchit la copie pour l'ouverture suivante.
//     => une modif d'index.html en ligne s'applique à la RÉOUVERTURE ; quand la version
//        change (sw.js modifié), le nouveau worker s'active et la page affiche le bandeau
//        « Nouvelle version disponible — Recharger » (invite NON bloquante, masquée en
//        session de crise) : l'utilisateur applique quand IL le décide.
//     Toute première visite (aucun cache) : on attend le réseau, comme avant.
//   - Autres fichiers (icônes, manifest) : "stale-while-revalidate" = on sert
//     vite le cache et on rafraîchit en arrière-plan.
//   - pdf.js (vendorisé, FIGÉ) : cache SÉPARÉ versionné par la version de pdf.js, PAS par celle
//     de l'app — l'ancien cache unique re-téléchargeait ~1,8 Mo inchangés à CHAQUE release.
//   - polices + icônes (IMMUABLES) : même motif, cache STATIC_CACHE pérenne (v5.10.2) —
//     ils étaient re-téléchargés (~120 Ko) à chaque publication pour rien.
//     Précaché à l'installation (chargé paresseusement par la page, un premier usage hors ligne
//     échouerait sinon) ; les fichiers déjà présents ne sont pas re-téléchargés.
//   - skipWaiting + clients.claim : le nouveau worker prend la main tout de suite.
//     La page, elle, affiche un toast « application mise à jour » quand un nouveau worker
//     s'active (voir l'enregistrement du SW en fin d'index.html) — jamais de reload forcé.
//   - À l'activation : on supprime les anciens caches (sauf le cache pdf.js courant).
//
//  IMPORTANT : ce worker ne touche JAMAIS à IndexedDB ('ac-db') ni au
//  localStorage. Vos fiches/catégories/sessions sont indépendantes du cache de
//  code et restent intactes à chaque mise à jour, tant que l'URL reste la même.
// =============================================================================
// IMPORTANT : garder cette version synchronisée avec APP_VERSION dans index.html.
const CACHE = 'aides-cognitives-v5.21.2';
// Versionné par pdf.js (vendor/pdfjs/README.txt) : à changer UNIQUEMENT quand pdf.js est mis à jour.
const PDFJS_CACHE = 'aides-cognitives-pdfjs-4.10.38';
const PDFJS_ASSETS = [
  './vendor/pdfjs/pdf.min.js',
  './vendor/pdfjs/pdf.worker.min.js'
];
// Versionné par jsQR (vendor/jsqr/README.txt) : même motif que pdf.js, mêmes raisons, même
// garde-fou (check-vendor relie la note et cette clé). Décodeur du partage sans serveur (v5.14).
const JSQR_CACHE = 'aides-cognitives-jsqr-1.4.0';
const JSQR_ASSETS = [
  './vendor/jsqr/jsQR.js'
];
/* Actifs IMMUABLES entre publications (polices, icônes, logo) : cache SÉPARÉ, versionné À PART —
   le motif pdf.js GÉNÉRALISÉ (v5.10.2). Avant, le renommage de CACHE à chaque release purgeait
   puis re-téléchargeait ces ~120 Ko parfaitement inchangés — exactement le défaut déjà corrigé
   pour pdf.js (l. 17-20), jamais étendu au reste. `-v1` ne bouge QUE si l'un de ces fichiers
   change de CONTENU sous le MÊME nom (piège des actifs vendorisés, AGENTS.md : changer les octets
   ne change pas ce qui tourne tant que la clé de cache ne bouge pas).
   F5 (v4.61.0) : les polices sont EMBARQUÉES — l'app doit s'afficher hors ligne, et la CSP
   n'autorise aucune origine externe (`font-src 'self'`). Licences : vendor/fonts/README.txt.
   NB : ne jamais mettre de commentaire À L'INTÉRIEUR de ces tableaux — check-sw les lit
   littéralement et prendrait chaque ligne pour une entrée de cache. */
const STATIC_CACHE = 'aides-cognitives-static-v1';
const STATIC_ASSETS = [
  './vendor/fonts/source-serif-4-latin-600.woff2',
  './vendor/fonts/manrope-latin-var.woff2',
  './vendor/fonts/ibm-plex-mono-latin-600.woff2',
  './vendor/fonts/ibm-plex-mono-latin-700.woff2',
  './icon-192.png',
  './icon-192-maskable.png',
  './icon-512.png',
  './icon-512-maskable.png',
  './icon-monochrome-512.png',
  './apple-touch-icon.png',
  './favicon-16.png',
  './favicon-32.png',
  './favicon.ico',
  './favicon.svg',
  './logo-glyph.svg'
];
// TOUT fichier servi par l'app reste dans ASSETS (règle 13 d'AGENTS.md) — l'UNION, par spread :
// la liste n'est écrite qu'une fois, seule sa CLÉ de cache diffère selon la nature de l'actif.
// `'./'` N'Y EST PLUS : c'était le MÊME document que './index.html' sous une seconde URL, soit
// 290 Ko téléchargés et stockés en double à chaque publication, pour une entrée JAMAIS servie
// (le repli de navigation cherche './index.html' d'abord — seule clé que le fetch de navigation
// rafraîchit ; cf. le commentaire de ce repli, plus bas).
const ASSETS = [
  './index.html',
  './manifest.webmanifest',
  ...STATIC_ASSETS
];
// Sous-ensemble OBLIGATOIRE d'ASSETS : sans ces deux fichiers il n'y a pas d'application, donc
// eux SEULS peuvent faire échouer l'installation. Tout le reste (icônes, favicons) dégrade
// l'apparence sans empêcher l'usage : un ajout futur à ASSETS est best-effort par défaut, ce qui
// est le bon défaut pour une app dont la fonction première est d'exister hors ligne.
const CORE_ASSETS = ['./index.html', './manifest.webmanifest'];

/* UNE RÉPONSE REDIRIGÉE NE PEUT PAS SERVIR UNE NAVIGATION (v5.17.3 ; signalé sur iPhone :
   « Safari ne peut pas ouvrir la page — Response served by service worker has redirections »).
   Une requête de navigation a le mode de redirection "manual" : servir depuis le cache une
   réponse dont le drapeau `redirected` est vrai est une ERREUR RÉSEAU. WebKit la refuse net,
   Chromium la tolère — d'où un défaut INVISIBLE sur la machine de développement et fatal sur
   la cible principale du projet. L'app ne s'ouvrait plus du tout : le pire mode de défaillance
   pour un logiciel d'urgence.
   Comment le drapeau arrivait là : l'hébergeur normalise les URL et redirige `/index.html`
   vers `/` (Cloudflare Workers Assets, `html_handling: auto-trailing-slash` — GitHub Pages ne
   le faisait pas, d'où l'apparition à la bascule). `fetch` suit la redirection, la réponse
   obtenue porte `redirected: true`, et `addAll` la range telle quelle.
   ⚠ LE CORRECTIF EST ICI, PAS DANS UN RÉGLAGE D'HÉBERGEUR. Neutraliser la redirection côté
   Cloudflare (`html_handling: "none"`) supprimerait aussi le service de `/` — on échangerait un
   défaut contre une racine morte —, et surtout l'application doit rester déployable ailleurs
   (règle 13) : un hébergeur qui normalise autrement réintroduirait le défaut.
   La reconstruction ne recopie QUE le type de contenu : réinjecter les en-têtes d'origine
   ferait suivre un éventuel `content-encoding` alors que le corps lu par `.blob()` est DÉJÀ
   décodé — la réponse serait alors illisible. */
async function putDoc(cache, key, resp) {
  if (!resp.redirected) return cache.put(key, resp);
  const body = await resp.blob();
  const h = new Headers();
  const ct = resp.headers.get('content-type');
  if (ct) h.set('content-type', ct);
  return cache.put(key, new Response(body, { status: 200, statusText: 'OK', headers: h }));
}

self.addEventListener('install', e => {
  e.waitUntil(Promise.all([
    // NOYAU, TOUT-OU-RIEN — mais SANS `addAll`, qui rangerait la réponse redirigée telle quelle
    // (cf. `putDoc`). La propriété qu'on veut est conservée par le `throw` : ou les deux entrent,
    // ou l'installation échoue. Elle n'a jamais été étendue aux 10 icônes, qui feraient échouer
    // l'installation ENTIÈRE — donc supprimer tout le hors-ligne — pour un favicon en 404.
    // On DEMANDE `./` et non `./index.html` : c'est la forme qu'aucun hébergeur ne redirige,
    // donc la redirection n'a même plus lieu. La clé ÉCRITE reste `./index.html`, seule clé lue
    // par le repli de navigation. Ceinture (la requête) et bretelles (`putDoc`).
    caches.open(CACHE).then(async c => {
      const reqs = CORE_ASSETS.map(a => (a === './index.html' ? './' : a));
      const resps = await Promise.all(reqs.map(r => fetch(r)));
      if (resps.some(r => !r.ok)) throw new Error('noyau indisponible');
      await Promise.all(CORE_ASSETS.map((key, i) => putDoc(c, key, resps[i])));
    }),
    // Statiques : ne télécharger QUE ce qui manque (le cache survit aux versions de l'app) —
    // même boucle best-effort que pdf.js, même raison : rien d'ornemental ne doit pouvoir
    // empêcher le noyau hors-ligne d'exister.
    caches.open(STATIC_CACHE).then(async c => {
      for (const a of STATIC_ASSETS) {
        if (await c.match(a)) continue;
        try { await c.add(a); } catch (err) {}
      }
    }),
    // pdf.js : ne télécharger QUE ce qui manque (le cache survit aux versions de l'app).
    // BEST-EFFORT, JAMAIS BLOQUANT : ces 1,73 Mio sont une dépendance de CONFORT (la visionneuse
    // PDF). Sans le try/catch, un 503 ou une coupure pendant leur téléchargement faisait rejeter
    // l'install ENTIÈRE -> aucun worker actif -> l'app d'urgence n'existait plus hors ligne, et
    // le `.catch(()=>{})` de son enregistrement rendait la panne silencieuse. Mesuré : worker en
    // 503 => {active:false, controller:false} avant, {active:true, controller:true} après.
    // Un PDF non précaché reste ouvrable en ligne et sera précaché à la prochaine installation.
    caches.open(PDFJS_CACHE).then(async c => {
      for (const a of PDFJS_ASSETS) {
        if (await c.match(a)) continue;
        try { await c.add(a); } catch (e) {}
      }
    }),
    // jsQR : même régime best-effort — un scan reste possible en ligne si le précache a raté.
    caches.open(JSQR_CACHE).then(async c => {
      for (const a of JSQR_ASSETS) {
        if (await c.match(a)) continue;
        try { await c.add(a); } catch (e) {}
      }
    })
  ]).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      // `caches.keys()` est indexé par ORIGINE, pas par scope : sans le préfixe, un déploiement
      // en sous-répertoire (intranet, cf. conformité § 1.1) effacerait les caches des PWA voisines.
      .then(keys => Promise.all(keys.filter(k => k.startsWith('aides-cognitives-') && k !== CACHE && k !== PDFJS_CACHE && k !== JSQR_CACHE && k !== STATIC_CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
      // Annonce la version du worker aux pages ouvertes : index.html la compare à son APP_VERSION
      // et affiche le message JUSTE — « déjà à jour » (la page servie est déjà la nouvelle) ou,
      // cas NORMAL depuis le cache-d'abord, le bandeau « Nouvelle version — Recharger » (la page
      // en main vient du cache, donc de l'ancienne version ; le bouton applique sans forcer).
      .then(() => self.clients.matchAll({ type: 'window' }))
      .then(cs => cs.forEach(c => c.postMessage({ type: 'sw-activated', version: CACHE })))
  );
});

/* LA VERSION SE DEMANDE, elle ne fait plus que s'annoncer (v5.14.10, signalé : « il ne me
   prévient plus tout le temps »). L'annonce à l'activation ne touche que les pages OUVERTES à
   cet instant : une activation app fermée (cas fréquent en PWA iOS — la vérification de sw.js
   court en parallèle du lancement) était perdue À JAMAIS, et personne ne redemandait. La page
   interroge donc AUSSI le worker (au chargement et à chaque retour au premier plan) ; la
   réponse porte un type distinct pour rester SILENCIEUSE quand les versions concordent —
   l'égalité est l'état normal, pas une nouvelle. */
self.addEventListener('message', e => {
  if (e.data && e.data.type === 'sw-version' && e.source)
    e.source.postMessage({ type: 'sw-version', version: CACHE });
});

self.addEventListener('fetch', e => {
  const req = e.request;
  // Requêtes CROSS-ORIGIN (ex. API Supabase : auth, REST de synchro) : on ne les intercepte
  // JAMAIS et on ne met JAMAIS leurs réponses en cache -> réseau direct, données fraîches.
  if (new URL(req.url).origin !== self.location.origin) return;
  if (req.method !== 'GET') return;

  // Le WORKER LUI-MÊME n'entre JAMAIS dans un cache : réseau direct, toujours. Sans ce garde, le
  // stale-while-revalidate ci-dessous mettait sw.js en cache au premier `fetch('./sw.js')` de la
  // page, puis répondait 200 hors ligne — c'est-à-dire qu'il MENTAIT à la sonde réseau de
  // « Réparer l'application » (index.html, repairApp), qui purgeait alors tout et laissait une
  // page blanche sans réseau. Un worker n'a par ailleurs aucune raison de se servir de sa propre
  // copie périmée : _headers le sert déjà en `no-cache` pour la même raison.
  if (new URL(req.url).pathname === new URL('./sw.js', self.location).pathname) return;

  // Page / navigation : cache d'abord (ouverture instantanée), réseau en rafraîchissement de fond.
  const isNav = req.mode === 'navigate' ||
                (req.headers.get('accept') || '').includes('text/html');
  if (isNav) {
    // SEULE la page de l'APP est traitée ici. Avant ce garde, TOUTE navigation HTML du même
    // domaine (tests.html, design/…) passait par ce chemin et son contenu était mis en cache
    // sous la clé './index.html' — la copie HORS-LIGNE de l'app d'urgence était alors REMPLACÉE
    // par la dernière page visitée (empoisonnement constaté à l'audit v4.1.0). Hors app :
    // réseau direct, jamais de mise en cache.
    const navPath = new URL(req.url).pathname;
    const appDir = new URL('./', self.location).pathname;
    if (navPath !== appDir && navPath !== appDir + 'index.html') return;
    const net = fetch(req);
    // Mise en cache garantie par waitUntil (enregistré TOUT DE SUITE : le navigateur ne tue pas
    // le worker avant la fin du put), même quand la réponse servie vient finalement du cache.
    // Ne mettre en cache QUE les vraies réponses de l'app (statut 2xx, même origine) :
    // une page d'erreur (404/500) ou un portail captif Wi-Fi (hôtel/hôpital) qui répond
    // à la place du serveur écraserait sinon la copie hors-ligne -> app critique cassée.
    e.waitUntil(net.then(resp => {
      if (resp.ok && resp.type === 'basic') {
        const copy = resp.clone();
        return caches.open(CACHE).then(c => putDoc(c, './index.html', copy));
      }
    }).catch(() => {}));
    // Repli : './index.html' D'ABORD — c'est la SEULE clé écrite, par l'installation comme par le
    // put ci-dessus. Matcher la requête brute ('/') d'abord servait une copie figée à l'install,
    // donc une version périmée hors ligne ; cette seconde clé n'est plus alimentée du tout (voir
    // CORE_ASSETS), le `caches.match(req)` final ne reste que par ceinture.
    // ⚠ ON REFUSE UNE ENTRÉE REDIRIGÉE PLUTÔT QUE DE LA SERVIR (v5.17.3). `putDoc` empêche d'en
    // écrire une, mais un cache écrit par un worker ANTÉRIEUR peut en contenir : la servir
    // provoquerait « Response served by service worker has redirections » et l'app ne s'ouvrirait
    // pas du tout. On retombe alors sur le réseau — dégradé, jamais mort — et le `put` ci-dessus
    // répare l'entrée au passage.
    const cached = () => caches.match('./index.html').then(r => r || caches.match(req));
    e.respondWith((async () => {
      const c = await cached();
      if (c && !c.redirected) return c;         // cache d'abord : ouverture instantanée, toujours
      return net.catch(() => Response.error()); // toute première visite : on attend le réseau
    })());
    return;
  }

  // Autres ressources : stale-while-revalidate. Le rafraîchissement (fetch + put) est couvert
  // par waitUntil ; pdf.js est rangé dans SON cache (pérenne entre versions de l'app).
  //
  // LA RÉPONSE SERVIE EST DÉCOUPLÉE DE L'ÉCRITURE EN CACHE — même patron que la branche de
  // navigation ci-dessus. Avant, la promesse rendue à la page ÉTAIT celle qui contenait le `put` :
  // un `put` qui rejette (quota dépassé, réponse que l'API Cache refuse) transformait une réponse
  // réseau parfaitement valide en ÉCHEC de chargement pour la page, dès lors que la ressource
  // n'était pas déjà en cache. Victime désignée : pdf.worker.min.js (1,4 Mio, chargé
  // paresseusement) — la visionneuse cassait sous pression de quota, exactement quand le
  // hors-ligne est déjà fragile, et le symptôme était indiscernable d'une coupure réseau.
  const net = fetch(req);
  e.waitUntil(net.then(resp => {
    // Même garde-fou que pour la navigation : jamais d'erreur mise en cache.
    if (resp.ok && resp.type === 'basic') {
      const path = new URL(req.url).pathname;
      const isPdfjs = path.indexOf('/vendor/pdfjs/') >= 0;
      const isJsqr = path.indexOf('/vendor/jsqr/') >= 0;
      // Un actif statique se rafraîchit dans SON cache pérenne — l'y ranger sous CACHE le ferait
      // re-télécharger à la release suivante, le défaut que STATIC_CACHE vient de fermer.
      const isStatic = STATIC_ASSETS.some(a => path === new URL(a, self.location).pathname);
      const copy = resp.clone();
      return caches.open(isPdfjs ? PDFJS_CACHE : (isJsqr ? JSQR_CACHE : (isStatic ? STATIC_CACHE : CACHE))).then(c => c.put(req, copy));
    }
  }).catch(() => {}));
  e.respondWith(
    caches.match(req).then(cached => cached || net)
  );
});
