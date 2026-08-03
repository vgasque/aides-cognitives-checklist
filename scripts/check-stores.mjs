/* GARDE-FOU — AUCUN STORE LOCAL FANTÔME (v5.0.4).

   POURQUOI. `_pullTable(cfg)` faisait servir `cfg.table` à DEUX choses : le nom de la table REST
   (`/rest/v1/<table>`) et le nom du store LOCAL où la page est écrite (`Data.applyRows`). C'était
   vrai tant que les deux noms coïncidaient. Le lot T9 (v5.0.0) a renommé la table Supabase
   `fiches` -> `cognitive_aids` — décision motivée, et qui ne pouvait PAS renommer le store
   IndexedDB (cela exige une montée de version de base, cf. AGENTS.md « distinguer le CHAMP du
   STORE »). Le pull des aides a donc demandé une transaction sur un store `cognitive_aids` qui
   n'existe nulle part, et la synchro ENTIÈRE échouait — « Failed to execute 'transaction' on
   'IDBDatabase': One of the specified object stores was not found » — à la première page portant
   une ligne. Signalé par l'utilisateur, invisible à tous les garde-fous : aucun harnais n'exerce
   un pull réel, et `npm run check` ne lisait pas ce couplage.

   CE QU'IL VÉRIFIE, dans les deux sens :
   (1) tout store visé par une écriture de synchro (`_pullTable`, via `store:` sinon `table:`)
       existe RÉELLEMENT dans le schéma créé par `openSpaceDb` — c'est le défaut vécu ;
   (2) tout nom de store écrit en toutes lettres ailleurs dans le fichier (`_s('x')`,
       `objectStore('x')`, `transaction('x')`) existe aussi — même famille, coût nul ;
   (3) `SYNC_KV_KEY` (repli localStorage) couvre EXACTEMENT les stores que la synchro écrit. Sans
       cela, le repli KV retombe sur une clé par défaut et corrompt en SILENCE : c'est ce que
       faisait `store==='protocols'?'protocols_v1':'fiches_v1'`, qui rangeait les sessions
       rapatriées dans `fiches_v1`.

   CE QU'IL NE VOIT PAS. Les noms de store passés par variable — il n'y en a aucun aujourd'hui
   hors des deux fonctions génériques `applyRows`/`_s`, dont les appelants sont tous littéraux.
   Le dire vaut mieux que de laisser croire à une couverture totale. */
import { readFileSync } from 'node:fs';
const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const err = [];

/* LE SCHÉMA FAIT AUTORITÉ : les stores sont ceux que `openSpaceDb` crée, pas une liste recopiée
   ici — une liste recopiée diverge (leçon `MUTE_SEL`, la liste des placards…). */
const iOpen = html.indexOf('function openSpaceDb(');
const fin = html.indexOf('\nconst req2p=', iOpen);
const schema = iOpen < 0 ? '' : html.slice(iOpen, fin < 0 ? iOpen + 4000 : fin);
const STORES = new Set([...schema.matchAll(/createObjectStore\('([a-z]+)'/g)].map(m => m[1]));
if (STORES.size < 4) err.push("schéma introuvable : aucun createObjectStore lu dans openSpaceDb — le contrôle ne mesurerait rien");

/* Corps du littéral objet qui suit `_pullTable(` — compteur d'accolades : les cfg contiennent des
   fonctions fléchées avec leurs propres accolades. */
function cfgAt(i) {
  const a = html.indexOf('{', i);
  if (a < 0) return '';
  let d = 0;
  for (let j = a; j < html.length; j++) {
    if (html[j] === '{') d++;
    else if (html[j] === '}' && --d === 0) return html.slice(a, j + 1);
  }
  return '';
}

// (1) les cibles d'écriture du pull
const vises = new Set();
// `_pullTable({` : les APPELS (le littéral cfg suit), jamais la déclaration `_pullTable(cfg)`.
for (const m of html.matchAll(/_pullTable\(\{/g)) {
  const cfg = cfgAt(m.index);
  const t = /[{,]\s*table:'([a-z_]+)'/.exec(cfg);
  const s = /[{,]\s*store:'([a-z_]+)'/.exec(cfg);
  if (!t && !s) { err.push('_pullTable sans table: ni store: littéral — cible d\'écriture non vérifiable'); continue; }
  const store = s ? s[1] : t[1];
  vises.add(store);
  if (!STORES.has(store)) err.push(`_pullTable écrit dans le store « ${store} » (table REST « ${t ? t[1] : '?'} »), qui n'existe pas dans openSpaceDb`);
}
if (!vises.size) err.push('aucun appel à _pullTable trouvé — le contrôle ne rencontre pas son cas');

// (2) les autres noms de store écrits en toutes lettres
for (const m of html.matchAll(/(?:_s|objectStore|transaction)\('([a-z]+)'/g)) {
  if (!STORES.has(m[1])) err.push(`store inconnu « ${m[1]} » à l'index ${m.index} (absent d'openSpaceDb)`);
}

// (3) la table du repli KV couvre exactement ce que la synchro écrit
const kv = /const SYNC_KV_KEY=\{([^}]*)\}/.exec(html);
if (!kv) err.push('SYNC_KV_KEY introuvable — le repli KV n\'a plus de table explicite');
else {
  const cles = new Set([...kv[1].matchAll(/([a-z]+)\s*:/g)].map(m => m[1]));
  for (const s of vises) if (!cles.has(s)) err.push(`SYNC_KV_KEY n'a pas d'entrée pour « ${s} » : en repli localStorage, le pull échouerait`);
  for (const c of cles) if (!STORES.has(c)) err.push(`SYNC_KV_KEY nomme « ${c} », qui n'est pas un store d'openSpaceDb`);
}

if (err.length) { console.error('check-stores : ' + err.length + ' problème(s)\n' + err.map(e => '  · ' + e).join('\n')); process.exit(1); }
console.log(`check-stores OK — ${STORES.size} stores, ${vises.size} cible(s) de synchro, repli KV aligné.`);
