// =============================================================================
//  Service worker — fonctionnement hors ligne + MISE À JOUR AUTOMATIQUE du code.
//
//  Stratégie :
//   - Navigation (la page index.html) : "réseau d'abord", BORNÉ à 3,5 s. Quand l'iPhone a du
//     réseau, on récupère la dernière version en ligne, puis on la met en cache pour l'usage
//     hors ligne. Hors ligne -> copie en cache, immédiatement. Réseau qui ne répond PAS
//     (Wi-Fi hospitalier saturé, « lie-fi ») -> au-delà de 3,5 s on sert la copie en cache
//     (app ouverte en urgence : attendre le timeout navigateur, parfois > 30 s, est exclu) ;
//     le fetch continue en arrière-plan et rafraîchit le cache pour la prochaine ouverture.
//     => une modif d'index.html en ligne s'applique automatiquement à la
//        réouverture, sans bump de version manuel.
//   - Autres fichiers (icônes, manifest) : "stale-while-revalidate" = on sert
//     vite le cache et on rafraîchit en arrière-plan.
//   - pdf.js (vendorisé, FIGÉ) : cache SÉPARÉ versionné par la version de pdf.js, PAS par celle
//     de l'app — l'ancien cache unique re-téléchargeait ~1,8 Mo inchangés à CHAQUE release.
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
const CACHE = 'aides-cognitives-v4.2.1';
// Versionné par pdf.js (vendor/pdfjs/README.txt) : à changer UNIQUEMENT quand pdf.js est mis à jour.
const PDFJS_CACHE = 'aides-cognitives-pdfjs-4.10.38';
const PDFJS_ASSETS = [
  './vendor/pdfjs/pdf.min.js',
  './vendor/pdfjs/pdf.worker.min.js'
];
const ASSETS = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icon-192.png',
  './icon-192-maskable.png',
  './icon-512.png',
  './icon-512-maskable.png',
  './apple-touch-icon.png'
];
// Délai au-delà duquel une navigation bascule sur la copie en cache (le réseau continue derrière).
const NAV_TIMEOUT_MS = 3500;

self.addEventListener('install', e => {
  e.waitUntil(Promise.all([
    caches.open(CACHE).then(c => c.addAll(ASSETS)),
    // pdf.js : ne télécharger QUE ce qui manque (le cache survit aux versions de l'app).
    caches.open(PDFJS_CACHE).then(async c => {
      for (const a of PDFJS_ASSETS) if (!(await c.match(a))) await c.add(a);
    })
  ]).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE && k !== PDFJS_CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
      // Annonce la version du worker aux pages ouvertes : index.html la compare à son APP_VERSION
      // et affiche le message JUSTE — « déjà à jour » (cas normal : la navigation réseau-d'abord a
      // déjà servi le nouvel index.html) ou « rechargez » (page encore servie par l'ancien cache).
      .then(() => self.clients.matchAll({ type: 'window' }))
      .then(cs => cs.forEach(c => c.postMessage({ type: 'sw-activated', version: CACHE })))
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  // Requêtes CROSS-ORIGIN (ex. API Supabase : auth, REST de synchro) : on ne les intercepte
  // JAMAIS et on ne met JAMAIS leurs réponses en cache -> réseau direct, données fraîches.
  if (new URL(req.url).origin !== self.location.origin) return;
  if (req.method !== 'GET') return;

  // Page / navigation : réseau d'abord (borné), cache en secours (hors ligne ou réseau muet).
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
        return caches.open(CACHE).then(c => c.put('./index.html', copy));
      }
    }).catch(() => {}));
    // Repli : './index.html' D'ABORD — c'est la SEULE clé rafraîchie par le put ci-dessus ;
    // l'entrée './' d'ASSETS, elle, date de l'installation du worker (matcher la requête brute
    // d'abord servait cette copie figée hors ligne : version périmée).
    const cached = () => caches.match('./index.html').then(r => r || caches.match(req));
    e.respondWith((async () => {
      const first = await Promise.race([
        net.catch(() => null),
        new Promise(r => setTimeout(() => r('slow'), NAV_TIMEOUT_MS))
      ]);
      if (first && first !== 'slow') return first;          // réseau OK dans les temps
      const c = await cached();
      if (c) return c;                                      // hors ligne, ou réseau trop lent
      return net.catch(() => Response.error());             // toute première visite : on attend le réseau
    })());
    return;
  }

  // Autres ressources : stale-while-revalidate. Le rafraîchissement (fetch + put) est couvert
  // par waitUntil ; pdf.js est rangé dans SON cache (pérenne entre versions de l'app).
  const refresh = fetch(req).then(resp => {
    // Même garde-fou que pour la navigation : jamais d'erreur mise en cache.
    if (resp.ok && resp.type === 'basic') {
      const isPdfjs = new URL(req.url).pathname.indexOf('/vendor/pdfjs/') >= 0;
      const copy = resp.clone();
      return caches.open(isPdfjs ? PDFJS_CACHE : CACHE).then(c => c.put(req, copy)).then(() => resp);
    }
    return resp;
  });
  e.waitUntil(refresh.catch(() => {}));
  e.respondWith(
    caches.match(req).then(cached => cached || refresh.catch(() => cached))
  );
});
