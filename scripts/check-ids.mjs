#!/usr/bin/env node
/* ============================================================================
   check-ids — tout `getElementById('X')` littéral doit avoir une ÉMISSION.
   (v5.10.2, audit externe.)

   POURQUOI CE CONTRÔLE EXISTE : quatre lecteurs visaient des ids que plus rien
   n'émettait (#crisisCtrl, #planBtn ×2, #endSess) — l'un recalculait `--ctrl-h`
   à « 0px » À CHAQUE ÉVÈNEMENT DE DÉFILEMENT pour un élément inexistant, les
   autres étaient des câblages morts. `check-classes` couvre les classes,
   `check-icons` les icônes, `check-actions` les data-* : PERSONNE ne couvrait
   les ids, et c'est par ce trou que les quatre sont entrés (et que `pb.hidden`
   sur null avait déjà coûté un démarrage entier, cf. AGENTS.md lot T8).

   CE QU'EST UNE ÉMISSION : un `id="X"` / `id='X'` littéral n'importe où dans le
   fichier (coque statique OU gabarit JS), OU un id passé en argument littéral à
   une FABRIQUE déclarée ci-dessous (upDropHtml émet `id="${esc(id)}"`, crtCard
   ses cartes du dialogue Créer). Une fabrique nouvelle s'ajoute ICI, avec son
   motif d'extraction — jamais en liste d'ids en clair, qui se périmerait.

   LIMITE DITE (même famille que check-icons/check-actions) : un
   `getElementById(variable)` ou un id construit (`'tmcard-'+t.id`) sort de la
   portée d'un contrôle statique — leur compte est affiché, pas vérifié.
   ============================================================================ */
import { readFileSync, readdirSync } from 'node:fs';
import { stripComments } from './strip-comments.mjs';

const src = readFileSync(new URL('../index.html', import.meta.url), 'utf8');

// Émissions : attributs id littéraux (statiques et dans les gabarits).
const emitted = new Set();
for (const m of src.matchAll(/\bid\s*=\s*"([A-Za-z][\w-]*)"/g)) emitted.add(m[1]);
for (const m of src.matchAll(/\bid\s*=\s*'([A-Za-z][\w-]*)'/g)) emitted.add(m[1]);
// Fabriques : l'id est un ARGUMENT littéral, l'attribut est émis par la fonction.
const FACTORIES = [
  { rx: /upDropHtml\(\s*'[^']*'\s*,\s*'([A-Za-z][\w-]*)'/g, why: "upDropHtml(kind, id, …) émet id=\"${esc(id)}\"" },
  { rx: /crtCard\(\s*'([A-Za-z][\w-]*)'/g,                  why: "crtCard(id, …) émet la carte du dialogue Créer" },
  { rx: /stgAct\(\s*'([A-Za-z][\w-]*)'/g,                   why: "stgAct(id, libellé) émet l'action d'une rangée d'état du pied" },
];
for (const f of FACTORIES) for (const m of src.matchAll(f.rx)) emitted.add(m[1]);

// Lecteurs : getElementById à argument littéral (les variables sont hors portée, comptées).
const readers = new Map(); let dynamic = 0;
for (const m of src.matchAll(/getElementById\(\s*(?:'([^']+)'|"([^"]+)"|([^'")][^)]*))\)/g)) {
  const lit = m[1] || m[2];
  if (lit === undefined) { dynamic++; continue; }
  if (!readers.has(lit)) readers.set(lit, 0);
  readers.set(lit, readers.get(lit) + 1);
}

const orphans = [...readers.keys()].filter(id => !emitted.has(id)).sort();
if (orphans.length) {
  console.error('✗ check-ids : ' + orphans.length + ' id(s) lus par getElementById mais émis NULLE PART :');
  orphans.forEach(id => console.error('    #' + id + ' (' + readers.get(id) + ' lecteur(s)) — un contrôle qui a l\'air vivant et ne fait rien'));
  process.exit(1);
}

/* SENS INVERSE (audit v5.19.4) : un sélecteur `#id` de la FEUILLE doit viser un id émis —
   c'est par ce trou que #f-validation (règle morte) et #readTopSeg (purge v5.6 à moitié faite,
   masqué à l'impression six versions durant) sont passés. Les sélecteurs sont pris entre `}` et
   `{` (jamais dans les valeurs : un hex #fff n'est pas un sélecteur). Les commentaires tombent
   AVANT l'appariement des blocs : deux commentaires JS citent `<style>` sans fermeture — sur le
   fichier brut, ils s'apparieraient de travers avec tout bloc ajouté plus bas (mesuré). */
const cssOrphans = new Set();
for (const st of stripComments(src).matchAll(/<style>([\s\S]*?)<\/style>/g)) {
  const css = st[1];
  for (const chunk of css.split('}')) {
    const sel = chunk.split('{')[0];
    for (const m of sel.matchAll(/#([A-Za-z][\w-]*)/g))
      if (!emitted.has(m[1])) cssOrphans.add(m[1]);
  }
}
if (cssOrphans.size) {
  console.error('✗ check-ids : ' + cssOrphans.size + ' sélecteur(s) #id stylés mais émis NULLE PART :');
  [...cssOrphans].sort().forEach(id => console.error('    #' + id + ' — règle morte (ou purge à moitié faite, règle 14)'));
  process.exit(1);
}
/* SENS 3 (assainissement v5.20.x) : un id ÉMIS en attribut littéral doit être LU quelque part —
   20 croix de fermeture de modales ont vécu avec un id que rien ne lisait (app, feuille, aria,
   tests, harnais), le câblage passant par la classe `.ai-x` — la 20ᵉ (mgrSheetX) née en v5.20.0
   pendant l'inventaire même : le trou fabriquait encore. Émission d'ATTRIBUT seulement : le
   lookbehind exclut `x.id='p'+i` (propriété, préfixe dynamique — consommé autrement). Est « lu » :
   toute occurrence du nom HORS attribut id= dans index.html, tests.html, sw.js ou scripts/ — une
   citation en chaîne compte (jamais de faux rouge). Les ids passés aux FABRIQUES ci-dessus sont
   hors portée de ce sens : l'argument du point d'appel cite le nom par construction. Le lookbehind
   écarte aussi `const id='lib-'+…` : une VARIABLE nommée id n'émet pas d'attribut. */
const EXEMPT_EMIS = new Map([
  // id -> raison (aucun à ce jour — un id lu par un chemin invisible au grep s'exempte ICI)
]);
const emittedAttr = new Set();
for (const m of src.matchAll(/(?<![.\w$])(?<!const )(?<!let )(?<!var )id\s*=\s*(?:"([A-Za-z][\w-]*)"|'([A-Za-z][\w-]*)')/g))
  emittedAttr.add(m[1] || m[2]);
let horsEmission = src.replace(/(?<![.\w$])(?<!const )(?<!let )(?<!var )id\s*=\s*(?:"[A-Za-z][\w-]*"|'[A-Za-z][\w-]*')/g, 'id=%%');
horsEmission += readFileSync(new URL('../tests.html', import.meta.url), 'utf8')
  + readFileSync(new URL('../sw.js', import.meta.url), 'utf8');
for (const f of readdirSync(new URL('../scripts/', import.meta.url)))
  if (f.endsWith('.mjs')) horsEmission += readFileSync(new URL('../scripts/' + f, import.meta.url), 'utf8');
const emisJamaisLus = [...emittedAttr].filter(id => !EXEMPT_EMIS.has(id)
  && !new RegExp('(?<![\\w$-])' + id.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '(?![\\w$-])').test(horsEmission)).sort();
if (emisJamaisLus.length) {
  console.error('✗ check-ids : ' + emisJamaisLus.length + ' id(s) émis que RIEN ne lit (app, feuille, aria, tests, harnais) :');
  emisJamaisLus.forEach(id => console.error('    id="' + id + '" — attribut mort (le câblage passe ailleurs, ou purge à faire)'));
  process.exit(1);
}
console.log('✓ check-ids : ' + readers.size + ' id(s) littéraux lus, tous émis ; sélecteurs #id de la feuille tous émis ; ' +
  emittedAttr.size + ' id(s) émis tous lus quelque part (' +
  dynamic + ' appel(s) à id calculé, hors portée d\'un contrôle statique).');
