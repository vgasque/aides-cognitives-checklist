// Synchro cloud : fonctions PURES du compte et de la synchro (spec D), rejouées dans la PWA.
// Les fonctions non exportées par `__ac_test__` (rowConverters, Date) sont atteintes par leur nom
// nu : ce sont des déclarations de premier niveau du script de la page.
const U = '5b7c1f0e-8a1d-4c0e-9f00-0123456789ab';
const T0 = 1790000000000;
export const inputs = [
  ...['REST 403 {"code":"42501"}', 'REST 500', 'REST 12', 'NET timeout 25000 ms', 'Failed to fetch', '', 'xREST 401', 'REST abc']
    .map(m => ({ fn: 'restErrStatus', arg: m })),
  { fn: 'isPersoRepairCandidate', arg: ['REST 403 x', true] },
  { fn: 'isPersoRepairCandidate', arg: ['REST 403 x', false] },
  { fn: 'isPersoRepairCandidate', arg: ['REST 401 x', true] },
  ...['REST 401 JWT expired', 'REST 403 new row violates row-level security policy', 'REST 413 Payload too large', 'REST 409 conflict',
      'REST 503 Service Unavailable', 'REST 500', 'NetworkError when attempting to fetch resource.', 'Load failed',
      'The database connection is closing.', 'InvalidStateError: idb-closed', 'NET timeout 25000 ms', 'quelque chose ' + 'x'.repeat(300),
      'REST 404 not found']
    .map(m => ({ fn: 'explainSyncError', arg: m })),
  { fn: 'explainSyncErrorTypeError', arg: 'Failed to fetch' },
  { fn: 'pullMissedIds', arg: [[
      { id: 'a', updated_at: '2026-09-01T10:00:00.000Z', deleted_at: null },
      { id: 'b', updated_at: '2026-09-01T10:00:00.000Z', deleted_at: '2026-09-01T10:00:00.000Z' },
      { id: 'c', updated_at: '2026-09-01T10:00:00.500Z', deleted_at: null },
      { id: 'd', updated_at: '2026-09-01T09:00:00.000Z', deleted_at: null },
      { id: 'bad id', updated_at: '2026-09-01T10:00:00.000Z' },
      { id: '__proto__', updated_at: '2026-09-01T10:00:00.000Z' },
      { id: 7, updated_at: '2026-09-01T10:00:00.000Z' },
      { updated_at: '2026-09-01T10:00:00.000Z' },
      { id: 'e', updated_at: 'garbage' },
    ], { c: { updatedAt: Date.UTC(2026, 8, 1, 10) }, d: { updatedAt: Date.UTC(2026, 8, 1, 10) }, e: { updatedAt: 0 }, b: { updatedAt: 1 } }] },
  ...[['pending', false, 3], ['rejected', false, 1], ['approved', false, 3], ['pending', true, 3], ['pending', false, 0], [null, false, 2]]
    .map(a => ({ fn: 'canReturnToAnon', arg: a })),
  ...[['', ''], [U, U], [U, ''], ['', U], [U, null]].map(a => ({ fn: 'dbNameFor', arg: a })),
  ...[['ac-pins', '', ''], ['ac-pins', U, U], ['ac-pins', U, 'other'], ['ac-pins', '', U]].map(a => ({ fn: 'spaceKeyFor', arg: a })),
  ...['', U, 'é€𝄞'].map(s => ({ fn: 'spaceTag', arg: s })),
  { fn: 'sanitizePins', arg: ['f1', 'bad id', 5, '__proto__', ...Array.from({ length: 60 }, (_, i) => 'p' + i)] },
  { fn: 'sanitizePins', arg: 'nope' },
  { fn: 'sanitizeUsage', arg: { f1: { n: 3.7, t: 12.9 }, 'bad id': { n: 1, t: 1 }, f2: { n: 0, t: 5 }, f3: { n: 20000, t: -5 }, f4: 'x', f5: { n: '4', t: '9' } } },
  { fn: 'sanitizeUsage', arg: Object.fromEntries(Array.from({ length: 205 }, (_, i) => ['u' + i, { n: 1, t: 1000 + i }])) },
  { fn: 'sanitizeUsage', arg: [1, 2] },
  { fn: 'mergeUsage', arg: [{ a: { n: 2, t: 10 }, b: { n: 5, t: 1 }, c: { n: 1, t: 1 } }, { a: { n: 2, t: 20 }, b: { n: 4, t: 99 }, d: { n: 1, t: 3 } }] },
  { fn: 'sanitizeTags', arg: [{ k: 'tk1', l: 'Médecin régulateur', a: ['mru', 'regul', '', 'x'.repeat(40), 'a', 'b', 'c', 'd', 'e', 'f'] },
      { l: 'Médecin régulateur' }, { label: 'Ancien format', alias: ['af'] }, { k: 'tk1', l: 'doublon' }, { l: '   ' }, null, 'str',
      { l: 'Été chaud !' }, { l: '!!!' }, { k: 'bad key', l: 'Clé invalide' }] },
  ...['Anesthésie', 'SMUR — Pédiatrie', '  Équipe déchocage  ', '!!!', 'a'.repeat(60), 'Œuf ÇA ß', ''].map(s => ({ fn: 'catSlug', arg: s })),
  ...[['L1', U, 'a1'], [null, U, 'a1'], ['', U, 'a2']].map(a => ({ fn: 'attStoragePath', arg: a })),
  ...['2026-09-30T08:56:13.046123+00:00', '2026-09-30T08:56:13.046Z', '2026-09-30T08:56:13+02:00', '2026-09-30T08:56:13.9+0530',
      '2026-09-30', '2026-09', '2026', '1970-01-01T00:00:00Z', '2026-02-30T00:00:00Z', 'garbage', '2026-09-30T24:00:00Z',
      '2026-09-30T08:56Z', '+002026-09-30T08:56:13.046Z', '2024-02-29T23:59:59.999Z', '1969-12-31T23:59:59.999Z']
    .map(s => ({ fn: 'dateParse', arg: s })),
  ...[0, T0, T0 + 0.9, -1, 253402300799999, 1e15, -62198755200000].map(n => ({ fn: 'toISOString', arg: n })),
  { fn: 'ficheToRow', arg: [{ id: 'f1', title: 'T', library: 'L1', updatedAt: T0, deletedAt: null, dirty: true, extraX: [1] }, U] },
  { fn: 'ficheToRow', arg: [{ id: 'f2', title: 'T', library: null, updatedAt: T0, deletedAt: T0 + 5, dirty: false }, U] },
  { fn: 'ficheFromRow', arg: { id: 'f9', owner: U, library_id: 'L2', updated_at: '2026-09-30T08:56:13.046123+00:00', deleted_at: null,
      data: { id: 'autre', title: 'Distante', library: 'X', ownerId: 'Y', updatedAt: 1, dirty: true, v: 4, kind: 'procedure', items: [], blocks: [], futur: { a: 1 } } } },
  { fn: 'ficheFromRow', arg: { id: 'f8', owner: null, library_id: null, updated_at: '2026-09-30T08:56:13Z', deleted_at: '2026-09-30T09:00:00Z', data: null } },
  { fn: 'protocolFromRow', arg: { id: 'p1', owner: U, library_id: 'L1', updated_at: '2026-09-30T08:56:13.5Z', deleted_at: null,
      data: { title: 'Réf', body: '# T', attachments: [{ id: 'd1', name: 'x.pdf', size: 10 }] } } },
  { fn: 'sessionToRow', arg: [{ id: 's1', ficheId: 'f1', live: false, exercise: 1, savedAt: T0, updatedAt: T0 + 10, deletedAt: null, dirty: true,
      linkArm: { t1: { b: 'b1', x: 0 } }, verified: { '1:b1:0': 1 }, vgaps: {}, stepTexts: {}, checked: { '1:b1:0': true }, futur: 'ok' }, U] },
  { fn: 'sessionToRow', arg: [{ id: 's2', ficheId: 'f1', savedAt: T0, verified: {}, vgaps: {}, stepTexts: 'ab', deletedAt: T0 + 1 }, U] },
  { fn: 'sessionToRow', arg: [{ id: 's3', ficheId: 'f1', updatedAt: 0, savedAt: T0 + 3 }, U] },
  { fn: 'sessionFromRow', arg: { id: 's1', exercise: true, updated_at: '2026-09-30T08:56:13.046Z', deleted_at: null,
      data: { ficheId: 'f1', ficheTitle: 'T', live: false, checked: { '1:b1:0': true, bad: 1 }, verified: { '1:b1:0': 1 }, vElsewhere: true,
        events: [{ id: 'e1', t: 5, ref: { type: 'core', k: 'renfort' } }], nav: ['b1'], navSeq: [1], futur: [1] } } },
  { fn: 'sessionFromRow', arg: { id: 's2', exercise: false, updated_at: '2026-09-30T08:56:13Z', deleted_at: '2026-09-30T09:00:00Z', data: { v: 2, enc: 'xyz' } } },
];
export function run(inputs) {
  const T = __ac_test__;
  const c = x => x === undefined ? null : JSON.parse(JSON.stringify(x));
  const ex = e => { const r = T.explainSyncError(e); return { title: r.title, detail: r.detail }; };
  const F = {
    explainSyncError: m => ex({ message: m }),
    explainSyncErrorTypeError: m => ex(new TypeError(m)),
    dateParse: s => { const v = Date.parse(s); return Number.isNaN(v) ? null : v; },
    toISOString: n => { try { return new Date(n).toISOString(); } catch (e) { return null; } },
    ficheToRow: a => ficheToRow(a[0], a[1]),
    ficheFromRow: r => ficheFromRow(r),
    protocolFromRow: r => protocolFromRow(r),
  };
  return inputs.map(({ fn, arg }) => {
    const a = c(arg);
    if (F[fn]) return c(F[fn](a));
    const f = T[fn];
    return c(Array.isArray(a) && f.length > 1 ? f(...a) : f(a));
  });
}
