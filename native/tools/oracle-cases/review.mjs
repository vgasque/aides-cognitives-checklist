// Relecture et comparaison : stepGuardTxt, nfGuardTxt, stepNote, stepShortcut, reviewNotes,
// reviewOffers, flattenFiche, diffFicheLines, flattenProto, impDiff, impDupRel, normalizeImport.
import { FICHES } from './_fiches.mjs';

const it = (id, d, o = {}) => ({ id, role: 'do', do: d, level: 1, ...o });
const OFFERS = [
  { id: 'o1', title: 'Cycle', order: 1, blocks: [{ id: 'b1', kind: 'do', items: [it('i1', 'RCP toutes les 2 min'), it('i2', '⚠ Choc', { level: 3 })] }] },
  { id: 'o2', title: 'Délai', order: 2, blocks: [{ id: 'b1', kind: 'do', items: [it('i1', 'Renouveler à 5 minutes si besoin')] }] },
  { id: 'o3', title: 'QH', order: 3, items: [{ id: 'p1', role: 'dose', do: 'Paracétamol : 1 g q6h' }], blocks: [{ id: 'b1', kind: 'do', items: [it('i1', 'Surveiller')] }] },
  { id: 'o4', title: 'Déjà', order: 4, timers: [{ id: 't1', label: 'x', type: 'interval', seconds: 60 }], counters: [{ id: 'n1', label: 'c' }],
    blocks: [{ id: 'b1', kind: 'do', items: [it('i1', 'toutes les 3 min, nouvelle dose', { memory: true }), it('i2', 'Choc', { level: 3 })] }] },
  { id: 'o5', title: 'Question', order: 5, blocks: [{ id: 'd1', kind: 'decision', question: 'Encore après 10 min ?', options: [] }, { id: 'b2', kind: 'do', items: [it('i1', '  ', { level: 3 }), it('i2', '! crit en chaîne')] }] },
  { id: 'o6', title: 'Grand', order: 6, blocks: [{ id: 'b1', kind: 'do', items: [it('i1', 'toutes les 999 min'), it('i2', 'q99h')] }] },
  { id: 'o7', title: 'Aprés', order: 7, blocks: [{ id: 'b1', kind: 'do', items: [it('i1', 'xà 5 min'), it('i2', 'Répéter la dose')] }] },
];
const STEPS = [[], ['a'], Array.from({ length: 8 }, (_, i) => 's' + i), ['x'.repeat(120)], ['court :: ' + 'y'.repeat(120)], ['a · b + c', 'a·b+c', 'a + b', ' · + '],
  ['⚠ ' + 'z'.repeat(111), '△ ok', '**' + 'w'.repeat(110) + '**'], ['', '  ']];
const NF = [[], ['a', 'b', 'c', 'd'], ['a', 'b', 'c', 'd', 'e'], ['**' + 'x'.repeat(109) + '**', 'y'.repeat(111), 'z'.repeat(111)], ['', ' ', 'a']];
const NOTES = ['', '  ', 'a · b + c', 'x'.repeat(111), '⚠ ' + 'x'.repeat(111), 'court :: a · b + c', '△ a + b · c'];
const SHORT = ['', '!', '! ', '! urgent', '? peut-être', '!sans', ' ! non', '?\tx', '! ligne\nsuite', '?  deux'];
const IMPORTS = [
  null, 5, 'x', [1, 2], {}, { fiches: [{ id: 'a' }, { id: 'r', kind: 'reference' }, null, 'str'], protocols: [{ id: 'p' }] },
  { aids: [{ id: 'a' }, { id: 'r', kind: 'reference' }], categories: [] }, { fiches: 'pas un tableau', aids: [{ id: 'a' }] }, { aids: 'x' },
  { fiches: [{ kind: 'reference' }], protocols: 'x' }, { version: 4, aids: [], extra: 1 },
];
const REL = [[1, 1], [2, 1], [1, 2], [null, 1], [1, null], [NaN, 1], [Infinity, 1], ['1', 1]];
export const inputs = [
  { k: 'text', stepStr: ['', ' ', '⚠ a', '⚠️b', '!c', ' ! d', '△ e', '⚠ △ f', '△ ⚠ g', 'h :: i', ':: j', 'k ::', 'l :: m :: n', '  o  ::  p  ', '!', '⚠', '△'], steps: STEPS, nf: NF, nfNum: [0, 4, 5, 5.5, '6', null], notes: NOTES, short: SHORT, imports: IMPORTS, rel: REL },
  ...[...OFFERS, ...FICHES].map((fiche, i) => ({ k: 'fiche', fiche, i })),
  { k: 'proto', protos: [
    { id: 'p1', title: 'Réf', validatedAt: '2025-01', status: 'draft', body: '# T\n\nligne\n  \nautre', sources: ['S1', ' '] },
    { id: 'p1', title: 'Réf 2', status: 'review', body: 'ligne\nnouvelle', sources: ['S1'] }, null,
    { id: 'p3', code: 'C3', title: 'Doc', body: '# T\n- [x] **fait** `c`\n\n| a | b |\n|---|---|\n> [!note] n', docs: [{ id: 'd1', name: 'Guide.pdf', size: 3 }, { id: 'd2', name: 'x' }], sources: ['S'] }] },
];
export function run(inputs) {
  const J = x => JSON.parse(JSON.stringify(x === undefined ? null : x));
  return inputs.map((x, xi) => {
    if (x.k === 'text') return {
      guard: x.steps.map(s => [stepGuardTxt(s), stepGuardTxt(s, 'bloc')]), nf: x.nf.map(nfGuardTxt), nfNum: x.nfNum.map(nfGuardTxt),
      notes: x.notes.map(stepNote), short: x.short.map(s => J(stepShortcut(s))), imports: x.imports.map(i => J(normalizeImport(J(i)))),
      rel: x.rel.map(([a, b]) => impDupRel(a, b)),
      steps: x.stepStr.map(s => ({ crit: stepIsCrit(s), vig: stepIsVigil(s), text: stepText(s), cr: stepCR(s), crt: stepCR(stepText(s)) })),
    };
    if (x.k === 'proto') {
      const ps = x.protos.map(p => (p ? migrateProtocol(J(p)) : null));
      return { ps: J(ps), flat: ps.map(flattenProto), diff: [J(impDiff(ps[0], ps[1], true)), J(impDiff(null, ps[1], true)), J(impDiff(ps[0], null, true))],
        snip: ps.filter(Boolean).map(p => protoSnipParts(p)) };
    }
    const f = migrate(J(x.fiche));
    const prev = inputs[xi - 1] && inputs[xi - 1].k === 'fiche' ? migrate(J(inputs[xi - 1].fiche)) : null;
    const saved = state.edOffNo;
    state.edOffNo = {};
    const offers = J(reviewOffers(f));
    state.edOffNo = { tm: 1, cn: 1 };
    const offersRef = J(reviewOffers(f));
    state.edOffNo = saved;
    return { f: J(f), prev: J(prev), notes: J(reviewNotes(f)), offers, offersRef, flat: flattenFiche(f), diff: J(diffFicheLines(f, prev)), diffNull: J(diffFicheLines(null, f)),
      imp: J(impDiff(prev, f, false)) };
  });
}
