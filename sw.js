// =============================================================================
//  Service worker — fonctionnement hors ligne + MISE À JOUR AUTOMATIQUE du code.
//
//  Stratégie :
//   - Navigation (la page index.html) : "réseau d'abord". Quand l'iPhone a du
//     réseau, on récupère TOUJOURS la dernière version en ligne, puis on la met
//     en cache pour l'usage hors ligne. Hors ligne -> on sert la copie en cache.
//     => une modif d'index.html en ligne s'applique automatiquement à la
//        réouverture, sans bump de version manuel.
//   - Autres fichiers (icônes, manifest) : "stale-while-revalidate" = on sert
//     vite le cache et on rafraîchit en arrière-plan.
//   - skipWaiting + clients.claim : le nouveau worker prend la main tout de suite.
//   - À l'activation : on supprime les anciens caches.
//
//  IMPORTANT : ce worker ne touche JAMAIS à IndexedDB ('ac-db') ni au
//  localStorage. Vos fiches/catégories/sessions sont indépendantes du cache de
//  code et restent intactes à chaque mise à jour, tant que l'URL reste la même.
// =============================================================================
// IMPORTANT : garder cette version synchronisée avec APP_VERSION dans index.html.
const CACHE = 'aides-cognitives-v3.2.1';
const ASSETS = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icon-192.png',
  './icon-512.png',
  './icon-512-maskable.png',
  './apple-touch-icon.png'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  // Requêtes CROSS-ORIGIN (ex. API Supabase : auth, REST de synchro) : on ne les intercepte
  // JAMAIS et on ne met JAMAIS leurs réponses en cache -> réseau direct, données fraîches.
  if (new URL(req.url).origin !== self.location.origin) return;
  if (req.method !== 'GET') return;

  // Page / navigation : réseau d'abord, cache en secours (hors ligne).
  const isNav = req.mode === 'navigate' ||
                (req.headers.get('accept') || '').includes('text/html');
  if (isNav) {
    e.respondWith(
      fetch(req)
        .then(resp => {
          // Ne mettre en cache QUE les vraies réponses de l'app (statut 2xx, même origine) :
          // une page d'erreur (404/500) ou un portail captif Wi-Fi (hôtel/hôpital) qui répond
          // à la place du serveur écraserait sinon la copie hors-ligne -> app critique cassée.
          if (resp.ok && resp.type === 'basic') {
            const copy = resp.clone();
            caches.open(CACHE).then(c => c.put('./index.html', copy));
          }
          return resp;
        })
        .catch(() => caches.match(req).then(r => r || caches.match('./index.html')))
    );
    return;
  }

  // Autres ressources : stale-while-revalidate.
  e.respondWith(
    caches.match(req).then(cached => {
      const network = fetch(req).then(resp => {
        // Même garde-fou que pour la navigation : jamais d'erreur mise en cache.
        if (resp.ok && resp.type === 'basic') {
          const copy = resp.clone();
          caches.open(CACHE).then(c => c.put(req, copy));
        }
        return resp;
      }).catch(() => cached);
      return cached || network;
    })
  );
});
