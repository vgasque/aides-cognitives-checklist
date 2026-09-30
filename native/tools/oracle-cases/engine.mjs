// Moteur de session : graphe, moments, jalons, et l'aller-retour buildRuntime → snapshotSession
// (horloge FIGÉE : Date.now est remplacé dans la page le temps du cas).
import { readFileSync } from 'node:fs';
const cases = JSON.parse(readFileSync(new URL('./migrate.inputs.json', import.meta.url)));
const acr = cases[2]; // l'aide v4 complète du cas migrate (boucles, revue, jalons, liens)
export const inputs = [
  { fn: 'graph', fiche: acr },
  { fn: 'moments' },
  { fn: 'jalons', fiche: acr },
  { fn: 'snapshot', fiche: acr, session: null, now: 1700000100000 },
  { fn: 'snapshot', fiche: acr, now: 1700000200000, session: {
      id: 's1', name: 'Test', startedAt: 1700000000000, savedAt: 1700000050000, aidRev: 17, live: true, exercise: true,
      checked: { '1:b1:0': true, '1:b1:1': false, '2:rv:0': true, 'r:rv:1': true }, verified: { '1:b1:0': { a: 'p1', t: 5 } }, vgaps: { '1:b1:1': 9 },
      cxBack: { '3': 'b1', '4': { id: 'bd', t: 44 } }, nav: ['b1', 'bd', 'bx', 'b2'], navSeq: [1, 2, 3, 4],
      counters: { n1: 3, n2: 7, c9: 2 }, timers: { t1: { elapsedMs: 120000, cycles: 1, running: true, stoppedAt: 0 } },
      extraTimers: [{ id: 'tx1', label: 'PA', seconds: 120, autoloop: false }], extraCounters: [{ id: 'c9', label: 'Chocs' }],
      linkArm: { t1: { b: 'b1', x: 0 } }, events: [{ id: 'e1', t: 1700000010000, label: '', ref: { type: 'counter', id: 'n1', v: 1 } }],
      futureKey: 'garde-moi' } },
];
export function run(inputs) {
  const T = __ac_test__, c = x => JSON.parse(JSON.stringify(x));
  const realNow = Date.now;
  return inputs.map(inp => {
    try {
      if (inp.fn === 'graph') {
        const f = T.migrate(c(inp.fiche)), ids = f.blocks.map(b => b.id);
        const nav = ['b1', 'bd', 'b1', 'bx', 'b2', 'b1'], navSeq = [1, 2, 3, 4, 5, 6];
        return {
          reach: Object.fromEntries(ids.map(id => [id, [...T.blkReach(f, id)].sort()])),
          inLoop: Object.fromEntries(ids.map(id => [id, T.blkInLoop(f, id)])),
          exits: ids.map(to => T.loopExitStops(f, { t1: { b: 'b1', x: 0 }, t9: { b: 'b2', x: 0 }, tz: { b: 'b1', x: 5 }, ty: { b: '', x: 0 } }, to)),
          latest: ids.map(id => T.latestPass(nav, navSeq, id)),
          pass: nav.map((_, i) => T.passInfo(nav, i)).concat([T.passInfo(nav, 99)]),
        };
      }
      if (inp.fn === 'moments') {
        const its = [null, {}, { from: { counter: 'n', n: 2 } }, { from: { counter: 'n', n: 1 } }, { repeat: 'once' }, { repeat: 'due' },
          { repeat: 'need' }, { from: { counter: 'n', n: 1 }, repeat: 'due' }, { from: { counter: 'n', n: 1 }, repeat: 'need' }];
        const out = [];
        for (const it of its) for (const cn of [0, 1, 3]) for (const tm of ['', 'run', 'due']) for (const before of [false, true]) for (const tid of ['', 't'])
          out.push(T.momentOf(it, () => cn, () => tm, before, tid));
        return out;
      }
      if (inp.fn === 'jalons') {
        const f = T.migrate(c(inp.fiche)); const js = f.blocks.flatMap(b => b.milestones || []);
        return { prog: js.flatMap(j => [[0, 0], [1, 2], [5, 3], [99, 99]].map(([p, n]) => T.jalonProg(j, p, n))), lbl: js.map(j => T.jalonCondLbl(f, j)) };
      }
      if (inp.fn === 'snapshot') {
        Date.now = () => inp.now;
        const f = T.migrate(c(inp.fiche));
        const R = T.buildRuntime(f, inp.session ? c(inp.session) : null);
        if (!inp.session) { R.started = true; R.startedAt = inp.now - 1000; R.sessionId = 's0'; R.name = 'N'; }
        return c(snapshotSession(R, true));
      }
    } finally { Date.now = realNow; }
  });
}
