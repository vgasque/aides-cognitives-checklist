// Corpus de FICHES partagé par les cas d'oracle qui lisent une aide (parcours, Page, recherche,
// relecture…). Trois sources : les exemples livrés, des graphes écrits à la main (ceux des témoins
// de tests.html : convergence, sorties, récidive, complications, revues…) et un lot TIRÉ AU SORT par
// un générateur à graine (boucles, décisions imbriquées, cibles pendantes, doublons de cible).
// Chaque cas renvoie la fiche MIGRÉE par la PWA : le natif la relit (migrate est idempotent et
// conserve les ids), si bien que les identifiants générés ne gênent jamais la comparaison.
import { readFileSync } from 'node:fs';

const ex = n => JSON.parse(readFileSync(new URL(`../../../exemples/${n}.json`, import.meta.url))).fiches[0];
const it = (id, d, o = {}) => ({ id, role: 'do', do: d, expect: '', level: 1, ...o });

const MAIN = [
  ex('etat-de-mal-epileptique'),
  ex('accouchement-inopine-prehospitalier'),
  { id: 'f-conv', title: 'Convergence', order: 1, updatedAt: 1, start: 'A', blocks: [
    { id: 'A', kind: 'do', title: 'A', items: [it('a1', 'a')], next: 'D1' },
    { id: 'D1', kind: 'decision', title: 'D1', question: 'Stable ?', options: [{ label: 'Oui', target: 'B' }, { label: 'Non', target: 'C' }] },
    { id: 'B', kind: 'do', title: 'B', items: [it('b1', 'b')], next: 'E' },
    { id: 'C', kind: 'do', title: 'C', items: [it('c1', 'c')], next: 'E' },
    { id: 'E', kind: 'do', title: 'E', items: [it('e1', 'e')], next: null }] },
  { id: 'f-recid', title: 'Récidive', order: 2, updatedAt: 2, start: 'b1', blocks: [
    { id: 'b1', kind: 'do', next: 'b2' }, { id: 'b2', kind: 'do', next: 'd1' },
    { id: 'd1', kind: 'decision', options: [{ label: 'persiste', target: 'b3' }, { label: 'arrêté', target: 'r' }] },
    { id: 'b3', kind: 'do', next: 'd2' },
    { id: 'd2', kind: 'decision', options: [{ label: 'persiste', target: 'b4' }, { label: 'arrêté', target: 'r' }] },
    { id: 'b4', kind: 'do' }, { id: 'r', kind: 'do', next: 'd3' },
    { id: 'd3', kind: 'decision', options: [{ label: 'récidive', target: 'b2' }, { label: 'stable', target: 'r' }] }] },
  { id: 'f-acr', title: 'ACR', order: 3, updatedAt: 3, start: 'b1',
    timers: [{ id: 't1', label: 'Cycle RCP (2 min)', type: 'interval', seconds: 120, autoloop: true }, { id: 't2', label: 'Adrénaline', type: 'interval', seconds: 240 },
      { id: 't3', label: 'Chrono', type: 'stopwatch', short: 'Chr.' }],
    counters: [{ id: 'n1', label: 'Chocs délivrés', step: 1, timerId: 't1' }, { id: 'n2', label: 'Doses (adré)', step: 2, timerId: '' }],
    excursions: [{ label: 'Hyperkaliémie (suspicion)', target: 'cx1' }, { label: 'Pneumothorax', target: 'fiche_ext', short: 'PNO' }, { label: '**Tamponnade** sévère et prolongée', target: 'ca' }],
    blocks: [
      { id: 'b1', kind: 'do', title: 'Début', phase: 'Immédiate', timer: 't1', items: [it('i1', 'Masser', { level: 3, memory: true }), it('i2', 'Scope :: rythme', { level: 2 })], next: 'd1' },
      { id: 'd1', kind: 'decision', question: 'Choquable ?', options: [{ label: 'choquable', target: 'fv' }, { label: 'non choquable', target: 'as' }, { label: 'RACS', target: 'ro' }] },
      { id: 'fv', kind: 'do', title: 'Choc', items: [it('i3', 'Choc', { counts: 'n1' }), it('i4', 'Adrénaline', { starts: 't2', from: { counter: 'n1', n: 3 }, repeat: 'due', poso: 'p1' }),
        it('i5', 'Amiodarone', { from: { counter: 'n1', n: 3 }, repeat: 'once', poso: 'p2' }), it('i6', 'Amiodarone 2', { from: { counter: 'n1', n: 5 }, repeat: 'once', poso: 'p2' })],
        next: 'ca', milestones: [{ at: 'count', n: 3, counter: 'n1', text: 'Adré', go: 'cx1' }, { at: 'pass', n: 1, text: 'Premier' }, { at: 'pass', n: 2, text: 'Deuxième' }] },
      { id: 'as', kind: 'do', title: 'Asystolie', phase: '', items: [it('i7', 'Adré', { counts: 'n2', poso: 'p1' }), it('i8', 'Revue', { review: 'rv' }), it('i9', 'Au besoin', { repeat: 'need' })], next: 'ca' },
      { id: 'ca', kind: 'do', title: 'Cycle', phase: 'Surveillance', items: [it('i10', 'RCP 2 min', { starts: 't1' }), it('i11', 'à compléter')], next: 'd1' },
      { id: 'ro', kind: 'do', title: 'RACS', items: [it('i12', 'Transport')] },
      { id: 'cx1', kind: 'do', title: 'Hyperkaliémie', items: [it('i13', 'Calcium')] },
      { id: 'rv', kind: 'review', title: 'Causes réversibles', items: [it('h1', 'Hypoxie'), it('h2', 'Hypovolémie'), it('h3', '  ')] }],
    items: [{ id: 'p1', role: 'dose', do: '**Adrénaline** : 1 mg IV', level: 2, note: 'toutes les 4 min' }, { id: 'p2', role: 'dose', do: 'Amiodarone : 300 mg' },
      { id: 'p3', role: 'dose', do: 'NaCl 20 mL/kg' }, { id: 'c1', role: 'entry', do: 'Arrêt à compléter' }, { id: 'm1', role: 'do', do: 'Penser 4H4T', memory: true },
      { id: 'w1', role: 'watch', do: 'EtCO2' }, { id: 'x1', role: 'ddx', do: 'Syncope' },
      { id: 'i1', role: 'do', do: 'Masser', level: 3, memory: true }] },
  { id: 'f-cx', title: 'Sédation', order: 4, updatedAt: 4, start: 'b1', local: 'Tél : à compléter',
    sources: ['Fiche générée par IA le 1/1 — à relire et valider avant usage', 'SFAR 2020', 'À valider'],
    blocks: [{ id: 'b1', kind: 'do', title: 'Sédation titrée', items: [it('s1', 'Titration')], next: null },
      { id: 'cx1', kind: 'do', title: 'Laryngospasme', items: [it('s2', '⚠ PPC')], next: null }],
    excursions: [{ label: 'Laryngospasme', target: 'cx1' }, { label: 'ACR', target: 'fiche_acr_01' }] },
  { id: 'f-empty', title: 'Vide', order: 5, updatedAt: 5, blocks: [] },
  { id: 'f-one', title: 'Un', order: 6, updatedAt: 6, blocks: [{ id: 'b1', kind: 'do', title: '', items: [] }] },
  { id: 'f-quirk', title: 'Ids piégés', order: 7, updatedAt: 7, start: 'undefined', blocks: [
    { id: 'null', kind: 'do', title: 'null', next: 'undefined' }, { id: 'undefined', kind: 'decision', options: [{ label: '', target: 'null' }, { label: 'x', target: 'nope' }, { label: 'y', target: 'undefined' }] },
    { id: 'z', kind: 'decision', options: [] }] },
];

// Générateur à graine.
let seed = 424242;
// Générateur congruentiel sur 32 bits EXACTS (Math.imul) : en flottant, le produit dépassait 2^53 et
// la suite dégénérait vers zéro (constaté : des documents « tirés au sort » tous vides).
const rnd = n => { seed = (Math.imul(seed, 1103515245) + 12345) >>> 0; return (seed >>> 8) % n; };
const pick = a => a[rnd(a.length)];
const TXT = ['Adrénaline IM', '⚠ Masser fort', '△ Vérifier dose :: 0,01 mg/kg', 'Oxygène', 'à compléter', 'Bilan :: complet', 'Voie veineuse',
  '**Gras** geste', 'Appeler renfort', 'Scope · PA · SpO2 + ECG', 'x'.repeat(120), ''];
function randomFiche(k) {
  const n = 1 + rnd(9), ids = Array.from({ length: n }, (_, i) => 'b' + i);
  const tids = ['t0', 't1'], cids = ['n0', 'n1'];
  const blocks = ids.map((id, i) => {
    const kind = rnd(10) < 3 ? 'decision' : (rnd(12) === 0 ? 'review' : 'do');
    const tgt = () => { const r = rnd(10); return r < 6 ? pick(ids) : (r < 8 ? null : (r < 9 ? 'dangling' : ids[Math.min(n - 1, i + 1)])); };
    if (kind === 'decision') return { id, kind, question: pick(['Q ?', 'Répond ?', '']), options: Array.from({ length: rnd(5) }, (_, j) => ({ label: pick(['Oui', 'Non', 'Non répondeur', 'Non stabilisé', '', 'Choquable (FV)']), target: tgt() })) };
    const items = Array.from({ length: rnd(5) }, (_, j) => {
      const o = { id: `${id}i${j}`, role: 'do', do: pick(TXT), level: 1 + rnd(3), memory: rnd(4) === 0 };
      const r = rnd(8);
      if (r === 0) o.starts = pick(tids); else if (r === 1) o.counts = pick(cids);
      if (rnd(4) === 0) o.from = { counter: pick(cids), n: 1 + rnd(4) };
      if (rnd(4) === 0) o.repeat = pick(['due', 'once', 'need']);
      if (rnd(5) === 0) o.poso = pick(['pd0', 'pd1']);
      return o;
    });
    return { id, kind, title: pick(['Bloc', 'Étape à compléter', '', 'Surveillance']), phase: pick(['', '', 'Immédiate', 'Surveillance']), items,
      next: tgt(), timer: rnd(4) === 0 ? pick(tids) : undefined,
      milestones: rnd(4) === 0 ? [{ at: pick(['pass', 'count']), n: 1 + rnd(3), counter: pick(cids), text: 'Jalon', go: 'b0' }] : [] };
  });
  return {
    id: 'rf' + k, title: 'Aléa ' + k, order: 100 + k, updatedAt: 100 + k, start: rnd(6) === 0 ? 'dangling' : (rnd(3) ? 'b0' : pick(ids)),
    blocks, excursions: rnd(2) ? [{ label: 'Complication', target: pick(ids) }] : [],
    timers: [{ id: 't0', label: 'Cycle (2 min)', type: 'interval', seconds: 120, autoloop: rnd(2) === 0 }, { id: 't1', label: 'Délai adrénaline', type: rnd(2) ? 'interval' : 'stopwatch', seconds: 90 }],
    counters: [{ id: 'n0', label: 'Chocs', step: 1, timerId: 't0' }, { id: 'n1', label: '', step: 1 }],
    items: [{ id: 'pd0', role: 'dose', do: 'Adrénaline : 1 mg' }, { id: 'pd1', role: 'dose', do: '△ Amiodarone : 300 mg', note: 'bolus' }],
  };
}
// Graphes STRUCTURÉS : un tronc de segments, des décisions dont les branches se rejoignent plus loin
// (convergences en chaîne — le cas où le choix du post-dominateur le plus PROCHE compte), des
// sorties, des retours en arrière et des sauts en avant.
function structuredFiche(k) {
  const blocks = [];
  let nb = 0;
  const mk = (kind, extra = {}) => { const b = { id: 's' + (nb++), kind, title: 'S' + nb, items: kind === 'do' ? [it(`s${nb}x`, 'Geste ' + nb)] : [], ...extra }; blocks.push(b); return b; };
  const seq = (len, depth) => {
    const out = [];
    for (let i = 0; i < len; i++) {
      if (depth < 3 && rnd(3) === 0) {
        const d = mk('decision', { question: 'Q' + nb, options: [] });
        const nbr = 2 + rnd(2), brs = [];
        for (let j = 0; j < nbr; j++) brs.push(rnd(5) === 0 ? null : seq(1 + rnd(2), depth + 1));
        out.push({ d, brs });
      } else out.push({ b: mk('do') });
    }
    return out;
  };
  const first = x => (x.d ? x.d : x.b);
  const wire = (segs, after) => {
    segs.forEach((s, i) => {
      const next = i + 1 < segs.length ? first(segs[i + 1]).id : after;
      if (s.b) { s.b.next = next; return; }
      s.brs.forEach((br, j) => {
        const r = rnd(10);
        let tgt;
        if (!br) tgt = r < 3 ? null : (r < 6 ? next : blocks[rnd(blocks.length)].id);   // sortie, suite directe ou saut
        else { tgt = first(br[0]).id; wire(br, r === 0 ? null : (r === 1 ? blocks[rnd(blocks.length)].id : next)); }
        s.d.options.push({ label: ['Oui', 'Non', 'Peut-être', 'Autre'][j], target: tgt });
      });
    });
  };
  const top = seq(3 + rnd(5), 0);
  wire(top, null);
  return { id: 'sf' + k, title: 'Structuré ' + k, order: 300 + k, updatedAt: 300 + k, start: first(top[0]).id, blocks,
    excursions: rnd(3) === 0 ? [{ label: 'Cx', target: blocks[rnd(blocks.length)].id }] : [] };
}
export const FICHES = [...MAIN, ...Array.from({ length: 70 }, (_, k) => randomFiche(k)), ...Array.from({ length: 80 }, (_, k) => structuredFiche(k))];

/** Scénarios de journal déterministes pour une fiche (nav, navSeq, checked, navPos). */
export function scenarios(f, k) {
  const ids = (f.blocks || []).map(b => b.id);
  let s = 99 + k;
  const r = n => { s = (Math.imul(s, 1103515245) + 12345) >>> 0; return (s >>> 8) % n; };
  const out = [{ nav: [], navSeq: [], checked: {}, navPos: null }];
  if (!ids.length) return out;
  for (let v = 0; v < 3; v++) {
    const len = 1 + r(5), nav = [], navSeq = [], checked = {};
    for (let i = 0; i < len; i++) { nav.push(ids[r(ids.length)]); navSeq.push(r(5) === 0 ? 0 : i + 1); }
    nav.forEach((id, i) => { for (let j = 0; j < 4; j++) if (r(2)) checked[(navSeq[i] || 1) + ':' + id + ':' + j] = true; });
    if (r(2)) checked['r:' + ids[0] + ':0'] = true;
    out.push({ nav, navSeq, checked, navPos: v === 2 ? r(len + 2) - 1 : null });
  }
  return out;
}
