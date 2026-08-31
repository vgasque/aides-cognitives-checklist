#!/usr/bin/env node
/* check-changelog.mjs — la règle « le CHANGELOG garde les 20 dernières versions » devient
   EXÉCUTOIRE (audit v5.19.3). Elle était écrite deux fois (README, AGENTS.md § publication)
   et appliquée par personne : `release.sh` INSÈRE une entrée en tête et n'élague jamais la
   queue, aucun check-*.mjs ne lisait CHANGELOG.md — le profil exact de règle fuyante que la
   v5.0.0 avait déjà documenté (« la règle existait et n'avait servi qu'une fois en 112
   entrées ») ; re-mesuré à 21 entrées le 31/08/2026. Au-delà de 20, les plus anciennes se
   DÉPLACENT (jamais réécrites) en FIN de docs/changelog/vN.md, une archive par version
   majeure — la fin, car c'est la convention constatée des lots déjà archivés.
   Second volet : aucune entrée ne doit exister À LA FOIS dans CHANGELOG.md et dans une
   archive — un déplacement à moitié fait serait une entrée en double, et le lecteur ne
   saurait plus laquelle fait foi.
   Vérifié CAPABLE D'ÉCHOUER à sa naissance : joué ROUGE sur l'état à 21 entrées AVANT
   l'archivage de [5.14.21], vert après — un garde-fou qui ne peut pas échouer ne prouve
   rien (leçon v4.31.1). */
import { readFileSync, readdirSync } from 'node:fs';

const MAX = 20;
const entetes = t => [...t.matchAll(/^## \[([^\]]+)\]/gm)].map(m => m[1]);

const log = entetes(readFileSync('CHANGELOG.md', 'utf8'));
let ko = 0;

if (log.length > MAX) {
  ko++;
  console.error(`✗ check-changelog : ${log.length} entrées dans CHANGELOG.md pour ${MAX} admises.`);
  console.error(`  Déplacer les plus anciennes (${log.slice(MAX).map(v => `[${v}]`).join(', ')}) en FIN de`);
  console.error(`  docs/changelog/v<majeure>.md — telles quelles, sans réécriture (règle de publication).`);
}

const vives = new Set(log);
for (const f of readdirSync('docs/changelog')) {
  if (!f.endsWith('.md')) continue;
  const doublons = entetes(readFileSync(`docs/changelog/${f}`, 'utf8')).filter(v => vives.has(v));
  if (doublons.length) {
    ko++;
    console.error(`✗ check-changelog : ${doublons.map(v => `[${v}]`).join(', ')} présente(s) à la fois`);
    console.error(`  dans CHANGELOG.md et docs/changelog/${f} — un déplacement se finit, il ne se copie pas.`);
  }
}

if (ko) process.exit(1);
console.log(`✓ check-changelog : ${log.length}/${MAX} entrées, aucune en double avec les archives.`);
