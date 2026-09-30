// sanitizeSession, migrateProtocol, sanitizeCats, sanitizeNotes, tkRefNorm, parseValidation.
export const inputs = [
  { fn: 'sanitizeSession', arg: { id: 's1', ficheId: 'f1', ficheTitle: 'T', name: 'n', startedAt: '12', savedAt: 5, live: 1, exercise: 0,
      checked: { '1:b1:0': true, 'bad key': true, '1:b1:12345': true, '2:b2:3': 1 }, nav: ['b1', 'b2', '__proto__'], navSeq: [1, '2', -4],
      counters: { n1: '3', 'x y': 1, n2: 'abc' }, timers: { t1: { elapsedMs: 1500, cycles: 2, running: 1 }, t2: null },
      cxBack: { '2': 'b1', '3': { id: 'b2', t: 99 }, x: 'b' }, extraTimers: [{ id: 'e1', label: 'PA', seconds: 300, autoloop: true }, null],
      extraCounters: [{ label: 'Chocs' }], linkArm: { t1: { b: 'b1', x: '7' }, '__proto__': { b: 'x' } },
      events: [{ id: 'e1', t: '100', label: 'Renommé', ref: { type: 'counter', id: 'n1', v: 2.6 } }, { id: 'e2', t: 5, ref: { type: 'core', k: 'renfort' }, voidAt: null },
        { id: 'e3', t: 6, ref: { type: 'core', k: 'nope' } }, { id: 'e4', ref: { type: 'step', b: 'b1', i: '2' } }, { id: 'e5', ref: { type: 'poso', i: -1 } },
        { id: 'e6', ref: { type: 'tag', k: 'x' }, a: 'acteur', annex: true }, null, 'str'], futureField: [1, 2] } },
  { fn: 'sanitizeSession', arg: { nav: ['a'], navSeq: [] } },
  { fn: 'migrateProtocol', arg: { id: 'p1', title: 'Référence', body: '# Titre\n\nTexte', sources: ['a'], status: 'draft', order: 1700000000000, attachments: [{ id: 'd' }], libraryId: 'L', extraX: 1, dirty: true } },
  { fn: 'migrateProtocol', arg: { id: 'bad id', order: 1700000000001, body: 12, docs: [{ id: 'd1', name: 'doc' }] } },
  { fn: 'sanitizeCats', arg: [{ id: 'c1', name: 'Urgences', color: '#1f5fa6', library: 'L1' }, { id: '__proto__', name: 5, color: 'red' }, null] },
  { fn: 'sanitizeNotes', arg: { f1: { t: 'note', at: 5, dirty: true }, 'bad id': { t: 'x' }, f2: 'str', f3: { t: 7 } } },
  ...['2026-01', '2026-13', '202602', '022026', 'janvier 2026', 'fév 26', '01/2026', '2026/01', '1-2026', '12/25', 'rien', '', 'Déc. 2024', '7 2031'].map(s => ({ fn: 'parseValidation', arg: s })),
];
export function run(inputs) {
  const T = __ac_test__;
  return inputs.map(({ fn, arg }) => JSON.parse(JSON.stringify(T[fn](JSON.parse(JSON.stringify(arg))))));
}
