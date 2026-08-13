#!/usr/bin/env node
/* check-actions — TOUT `data-*` ÉMIS A UN LECTEUR (v5.6).
   ────────────────────────────────────────────────────────────────────────────────────────────
   NÉ D'UN DÉFAUT SIGNALÉ À L'USAGE : « sur la page d'entrée, cliquer sur “Voir le compte-rendu”
   il ne se passe rien ». Le bouton portait `data-prelast` — un attribut ÉMIS UNE FOIS et câblé
   NULLE PART, inventé à côté du `data-report` que `bindReadEvents` relie déjà à
   `exportSessionReport`. Rien ne pouvait le voir : ce n'est ni une classe (check-classes), ni une
   icône (check-icons), ni une couleur ; le bouton s'affiche, se survole, se focalise, et ne fait
   RIEN. C'est le pire mode de défaillance d'une aide d'urgence — un contrôle qui a l'air vivant.
   CE QUE LE CONTRÔLE EXIGE : tout `data-x=` écrit dans un gabarit doit avoir au moins un LECTEUR
   dans le même fichier — un sélecteur `[data-x]` (y compris `[data-x="…"]`, donc les règles CSS
   comptent), un accès `dataset.x`, ou un `get/set/has/removeAttribute('data-x')`.
   ⚠ CE QU'IL NE PEUT PAS VOIR, ET IL FAUT LE DIRE : un attribut lu par une expression CALCULÉE
   (`el.dataset[nom]`, un sélecteur assemblé à la volée) sort de la portée d'un contrôle statique —
   comme les noms d'icône calculés de `check-icons`. Il attrape l'attribut ORPHELIN, pas l'usage
   indirect ; c'est exactement le cas qui l'a fait écrire.
   ⚠ ET LES EXEMPTIONS SE NOMMENT AVEC LEUR LECTEUR : un attribut peut n'exister que pour un
   HARNAIS (une poignée de mesure). C'est légitime — mais alors on écrit LEQUEL, sinon la liste
   devient l'endroit où l'on range ce qu'on n'a pas compris. */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

/* Exemptions : nom -> le lecteur qui le justifie. Vérifiées, pas déclarées. */
const EXEMPT = {
  'upkind': 'scripts/audit-upload.mjs — la sonde vise .up-drop[data-upkind="pdf"] pour déposer un fichier',
  'i':      'index de rangée des éditeurs de liste : poignée de mesure et repère de lecture du DOM',
};

let s = readFileSync(join(ROOT, 'index.html'), 'utf8');
/* Les commentaires CITENT des attributs à foison (ce dépôt documente ses règles dans le code) :
   on les neutralise en gardant les longueurs, comme check-space. */
s = s.replace(/\/\*[\s\S]*?\*\//g, m => ' '.repeat(m.length));

const emis = new Map(), lus = new Set();
for (const m of s.matchAll(/data-([a-z][a-z0-9-]*)\s*=/g)) emis.set(m[1], (emis.get(m[1]) || 0) + 1);
for (const m of s.matchAll(/\[data-([a-z][a-z0-9-]*)[\]=~^$*|]/g)) lus.add(m[1]);
for (const m of s.matchAll(/dataset\.([a-zA-Z][a-zA-Z0-9]*)/g))
  lus.add(m[1].replace(/[A-Z]/g, c => '-' + c.toLowerCase()));
for (const m of s.matchAll(/(?:get|set|has|remove)Attribute\(\s*['"`]data-([a-z][a-z0-9-]*)['"`]/g)) lus.add(m[1]);

const morts = [...emis.keys()].filter(a => !lus.has(a) && !(a in EXEMPT)).sort();
const exInutiles = Object.keys(EXEMPT).filter(a => !emis.has(a)).sort();

if (morts.length) {
  console.error(`✗ ${morts.length} attribut(s) data-* ÉMIS sans aucun lecteur :`);
  for (const a of morts) console.error(`    data-${a}   (${emis.get(a)} émission(s))`);
  console.error(`  -> soit le gestionnaire manque (le contrôle a l'air vivant et ne fait RIEN,`);
  console.error(`     cf. data-prelast, v5.6), soit l'attribut ne sert plus et doit disparaître.`);
  console.error(`     Avant d'inventer un nom, chercher celui qui nomme déjà l'action.`);
  process.exit(1);
}
if (exInutiles.length) {
  console.error(`✗ ${exInutiles.length} exemption(s) qui n'ont plus d'objet : ${exInutiles.join(', ')}`);
  console.error(`  -> l'attribut n'est plus émis : retirer l'exemption (une liste périmée ment).`);
  process.exit(1);
}
console.log(`✓ check-actions : ${emis.size} attribut(s) data-* émis, tous lus `
  + `(${Object.keys(EXEMPT).length} exemption(s) nommée(s) avec leur lecteur ; `
  + `les lectures par nom CALCULÉ sont hors portée d'un contrôle statique).`);
