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
import { readFileSync } from 'node:fs';

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
console.log('✓ check-ids : ' + readers.size + ' id(s) littéraux lus, tous émis (' +
  dynamic + ' appel(s) à id calculé, hors portée d\'un contrôle statique).');
