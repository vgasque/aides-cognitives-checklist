/* SOCLE COMMUN DES HARNAIS (v4.45.0) — serveur statique + choix du moteur.
 *
 * POURQUOI. Les onze harnais recopiaient le même serveur statique et la même table MIME : 90
 * occurrences redondantes sur 1 442 lignes. Ce n'est pas la duplication qui coûte, c'est ce
 * qu'elle produit — la DIVERGENCE avait déjà commencé, `audit-lecteur.mjs` étant le seul dont la
 * table MIME omettait `.ico`. Une copie qui dérive dans un harnais fait mesurer autre chose que
 * ce que mesurent les dix autres, sans que rien ne le signale.
 *
 * ET SURTOUT. Les onze lançaient `chromium.launch()` EN DUR. Or `npm test` tourne sur deux
 * moteurs depuis v4.34.0, précisément parce qu'iOS Safari est la cible principale déclarée et
 * qu'un comportement WebKit peut couper l'écran sans qu'aucune mesure ne le voie (dossier « bande
 * basse iOS »). Les harnais, eux, n'auditaient QUE Blink : la cible principale n'était couverte
 * par aucun d'eux. Le moteur se choisit désormais par `AC_ENGINE` :
 *
 *     npm run audit                    → chromium (défaut, inchangé)
 *     AC_ENGINE=webkit npm run audit   → WebKit, la cible iOS
 *
 * Le défaut reste chromium pour que rien ne change sans décision : passer WebKit en défaut, ou
 * jouer les deux systématiquement, se décide en connaissant le coût (le temps d'audit double) et
 * les écarts réels — qu'on peut enfin mesurer.
 */
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname } from 'node:path';
import * as pw from 'playwright';

export const ROOT = decodeURIComponent(new URL('../', import.meta.url).pathname);

/* Table MIME — SOURCE UNIQUE. `.ico` en fait partie : son absence dans une copie faisait servir
   le favicon en `application/octet-stream`, ce qui ne casse rien de visible mais suffit à faire
   diverger un harnais des autres. */
const MIME = {
  '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json',
  '.webmanifest': 'application/manifest+json', '.png': 'image/png',
  '.svg': 'image/svg+xml', '.ico': 'image/x-icon',
};

/* Serveur statique du dépôt, sur un port libre. Rend { port, srv } — les harnais gardent la main
   sur la fermeture, qu'ils font déjà tous (`srv.close()`), pour ne rien changer à leur structure. */
export async function serveApp() {
  const srv = createServer(async (q, r) => {
    try {
      let p = decodeURIComponent(q.url.split('?')[0]);
      if (p === '/') p = '/index.html';
      const b = await readFile(ROOT + p.replace(/^\/+/, ''));
      r.writeHead(200, { 'content-type': MIME[extname(p)] || 'application/octet-stream' });
      r.end(b);
    } catch { r.writeHead(404); r.end('nf'); }
  });
  const port = await new Promise(r => srv.listen(0, () => r(srv.address().port)));
  return { port, srv };
}

/* Moteur choisi par AC_ENGINE (chromium par défaut). Un nom inconnu ÉCHOUE bruyamment : une faute
   de frappe qui retomberait silencieusement sur chromium ferait croire à un audit WebKit vert. */
export function moteur() {
  const nom = (process.env.AC_ENGINE || 'chromium').toLowerCase();
  if (!['chromium', 'webkit', 'firefox'].includes(nom)) {
    console.error(`harness : AC_ENGINE="${process.env.AC_ENGINE}" inconnu (chromium | webkit | firefox).`);
    process.exit(1);
  }
  return pw[nom];
}

/* Nom du moteur, pour que les harnais puissent l'afficher dans leur en-tête — un résultat qui ne
   dit pas sur quel moteur il a été obtenu n'est pas interprétable. */
export const NOM_MOTEUR = (process.env.AC_ENGINE || 'chromium').toLowerCase();

/* CONSTRUIRE DES ITEMS v4 DANS UNE FIXTURE DE HARNAIS (v5.0.0, étape D).
   Les fixtures sont bâties côté Node, où les fonctions de l'application n'existent pas ; et depuis
   que le modèle est v4, un bloc ne peut plus être décrit par un tableau de chaînes. Ce helper fait
   la même lecture que `v4MakeItem` : le préfixe de registre devient `level`, « :: » sépare le
   challenge de la réponse attendue. `migrate` posera les identités. */
export const items = arr => (arr || []).map(s => {
  const t = String(s || '');
  const level = /^\s*(⚠|!)/.test(t) ? 3 : (/^\s*△/.test(t) ? 2 : 1);
  const nu = t.replace(/^\s*(⚠️?|!|△)\s*/, '');
  const i = nu.indexOf('::');
  return i < 0 ? { do: nu.trim(), expect: '', level }
               : { do: nu.slice(0, i).trim(), expect: nu.slice(i + 2).trim(), level };
});
