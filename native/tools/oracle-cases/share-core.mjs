// Partage — noyau pur : codes, projection, capacités, trace de vérification, grammaires du fil,
// instantané, différence, pli, assainissement optique, empreinte, horloge, dates ISO.
// Les clés d'objet des entrées sont écrites TRIÉES : le natif parcourt ses dictionnaires triés,
// le JS dans l'ordre d'insertion — ainsi l'ordre des évènements émis se compare tel quel.
const T0 = '2026-09-30T12:00:00.000Z';
const fiche = {
  id: 'f1', v: 4, kind: 'fiche', title: 'ACR', discriminant: 'adulte', code: 'ACR-01', status: 'validated', validatedAt: '2026-01',
  category: 'c1', library: 'L1', sources: ['x'], images: [{ id: 'i1' }], docs: [], links: [], order: 3, ownerId: 'u',
  complications: [{ label: 'x', target: 'f2' }], start: 'b1', excursions: [], updatedAt: 1, extraField: 5,
  blocks: [{ id: 'b1', title: 'Bloc 1', image: 'i1', items: ['s1'] }, { id: 'b2', title: 'Bloc 2' }, null],
  timers: [{ id: 't1', label: 'RCP', seconds: 120 }], counters: [{ id: 'c1', label: 'Chocs' }], items: [{ id: 's1', do: 'Masser' }],
};
const runtimeA = {
  checked: { '1:b1:0': true }, counters: { c1: 1, c2: '3', c3: 'x' }, cxBack: { '2': { id: 'b1', t: 5 }, '3': 'bad', '4': { t: 1 } },
  events: [{ id: 'e1', label: 'MOT LIBRE', ref: { id: 'c1', type: 'counter', v: 1 }, t: 1000 }, { id: 'e2', t: '2000', voidAt: 2500 }],
  exercise: 1, nav: ['b1', 'b2'], navSeq: [1, 2], startedAt: 500, stopClosed: true,
  timers: { t1: { elapsedMs: 1200, cycles: 1, lastStart: 900, running: true }, t2: null, t3: { elapsedMs: '50', running: 0, stoppedAt: 77 } },
  verified: { '1:b1:0': 1234, '1:b1:1': { a: 'p1', t: '5' }, '1:b1:2': 'x', '1:b1:3': [1] }, vgaps: { '2:b2:0': { t: 9 } },
};
export const inputs = [
  // Codes
  ...['k7m2-qx9p', 'K7M2QX9P', 'k7m2qx9', 'K0M1QX9P', ' ab cd ef gh ', 'ßSSSSSSS', 'IIIIOOOO', '', null, '23456789'].map(s => ({ fn: 'code', arg: s })),
  ...['#j=K7M2QX9P', 'https://x.org/a/index.html#j=k7m2-qx9p', '#x=1&j=K7M2QX9P', '#j=K7M2QX9', '#j=', '#j=!!&j=K7M2QX9P', 'j=K7M2QX9P', '#J=K7M2QX9P'].map(h => ({ fn: 'fromHash', arg: h })),
  { fn: 'payload', arg: fiche }, { fn: 'payload', arg: { id: 'x', title: null } }, { fn: 'payload', arg: null },
  { fn: 'can', arg: null }, { fn: 'applyMode', arg: ['check', 'nav', 'verify', 'sig', 'offline_mark', 'session_start', 'inconnu', 'end', 'cx'] },
  { fn: 'vf', arg: [{ a: 'p', t: 5 }, 12, { t: 'x' }, [1], 'str', null, { a: 0, t: 3 }, true] },
  { fn: 'navNorm', arg: [['b1', 'b2'], [1, '2']] }, { fn: 'navNorm', arg: [['b1', '__proto__', 'x y'], [0, 2.6, 'z']] },
  { fn: 'navNorm', arg: [['b1'], []] }, { fn: 'navNorm', arg: [[], []] }, { fn: 'navNorm', arg: ['b1', [1]] },
  { fn: 'cxbNorm', arg: [{ '1': { id: 'b2', t: 4 }, '2': { id: '__proto__' }, '3': { id: 'b1' }, '4.4': { id: 'b3', t: 'x' }, x: { id: 'b1' }, '9': 'str' }, [1, 2, 4]] },
  { fn: 'cxbNorm', arg: [[{ id: 'b1' }], [1]] },
  { fn: 'cxbForFiche', arg: [{ '1': { id: 'b1', t: 1 }, '2': { id: 'zz', t: 1 }, '3': null }, fiche] },
  { fn: 'snap', arg: runtimeA }, { fn: 'snap', arg: null }, { fn: 'snap', arg: { checked: { a: 1 } } },
  // Différences (a, b, sid)
  { fn: 'diff', arg: [null, runtimeA, 's-local'] },
  { fn: 'diff', arg: [runtimeA, {
    checked: { '1:b1:1': true }, counters: { c1: 2, c2: '3', c3: 'x' }, cxBack: {},
    events: [{ id: 'e1', ref: { id: 'c1', type: 'counter', v: 2 }, t: 1000 }, { id: 'e2', t: '2000' }, { id: 'e3', ref: { k: 'bilan', type: 'core' }, t: 3000, voidAt: 3100 }],
    exercise: 1, nav: ['b1', 'b2', 'b3'], navSeq: [1, 2, 3], startedAt: 600,
    timers: { t1: { elapsedMs: 1200, cycles: 1, lastStart: 900, running: false, stoppedAt: 1500 }, t3: { elapsedMs: '50', running: 0, stoppedAt: 77 } },
    verified: { '1:b1:0': { a: 'p2', t: 1234 }, '1:b1:1': { a: 'p1', t: '5' } }, vgaps: { '2:b2:0': { t: 9 }, '2:b2:1': 5 },
  }, null] },
  { fn: 'diff', arg: [runtimeA, runtimeA, null] },
  { fn: 'diff', arg: [{ checked: { a: false } }, { checked: { a: false, b: 0, c: true } }, null] },
  // Pli
  { fn: 'fold', arg: [[
    { seq: 1, id: 'u1', actor: 'p1', kind: 'check', payload: { k: '1:b1:0' }, ts: T0 },
    { seq: 2, id: 'u2', actor: 'p1', kind: 'check', payload: { k: 'bad key' }, ts: T0 },
    { seq: 3, id: 'u3', actor: 'p2', kind: 'verify', payload: { k: '1:b1:0', t: 111 }, ts: T0 },
    { seq: 4, id: 'u4', actor: 'p2', kind: 'gap', payload: { k: '1:b1:0', t: 222 }, ts: T0 },
    { seq: 5, id: 'u5', kind: 'verify', payload: { k: '1:b1:1', t: 3 }, ts: T0 },
    { seq: 6, id: 'u6', actor: 'p1', kind: 'counter', payload: { id: 'c1', v: '4' } },
    { seq: 7, id: 'u7', actor: 'p1', kind: 'counter', payload: { v: 4 } },
    { seq: 8, id: 'u8', actor: 'p1', kind: 'timer_arm', payload: { anchor: 5000, cycles: 1, elapsedMs: 100, id: 't1', running: true }, ts: T0 },
    { seq: 9, id: 'u9', actor: 'p1', kind: 'timer_stop', payload: { anchor: 5000, cycles: 'x', elapsedMs: 900, id: 't2', running: false }, ts: '2026-09-30T12:00:01.5+00:00' },
    { seq: 10, id: 'u10', actor: 'p1', kind: 'timer_reset', payload: { id: 't3', running: false }, ts: 1727697600000 },
    { seq: 11, id: 'u11', actor: 'p1', kind: 'nav', payload: { cxb: { '2': { id: 'b1', t: 3 } }, nav: ['b1', 'b2'], navSeq: [1, 2] } },
    { seq: 12, id: 'u12', actor: 'p1', kind: 'nav', payload: { nav: ['b1'], navSeq: [1, 2] } },
    { seq: 13, id: 'u13', actor: 'p1', kind: 'flow_end', payload: { on: 1 } },
    { seq: 14, id: 'u14', actor: 'p1', kind: 'session_start', payload: { exo: true, id: 's-host', t: 1234 } },
    { seq: 15, id: 'u15', actor: 'p1', kind: 'session_start', payload: { t: 0 } },
    { seq: 16, id: 'u16', actor: 'p1', kind: 'mark', payload: { id: 'e1', ref: { id: 'c1', type: 'counter', v: 2.4 }, t: 100 }, ts: T0 },
    { seq: 17, id: 'u17', actor: 'p2', kind: 'mark', payload: { id: 'e1', ref: { type: 'nope' }, t: 'x' }, ts: T0 },
    { seq: 18, id: 'u18', actor: 'p2', kind: 'mark', payload: { id: 'e2', label: 'MOT', ref: { k: 'bilan', type: 'core' }, t: 300 } },
    { seq: 19, id: 'u19', actor: 'p2', kind: 'mark_void', payload: { id: 'e2', on: true, t: 0 } },
    { seq: 20, id: 'u20', actor: 'p2', kind: 'mark_void', payload: { id: 'e1', on: true, t: 777 } },
    { seq: 21, id: 'u21', actor: 'p2', kind: 'mark_void', payload: { id: 'e1', on: false } },
    { seq: 22, id: 'u22', actor: 'p3', kind: 'offline_mark', payload: { ref: { i: 3, type: 'poso' }, t: 999, was: 'check' } },
    { seq: 23, id: 'u23', actor: 'p1', kind: 'sig', payload: { t: 'o' } },
    { seq: 24, id: 'u24', actor: 'p1', kind: 'uncheck', payload: { k: '1:b1:0' } },
    { seq: 25, id: 'u25', actor: 'p1', kind: 'mark', payload: { id: 'e9', t: 5 } },
    { seq: 26, id: 'u26', actor: 'p1', kind: 'presence', payload: {} },
    { seq: 27, id: 'u27', kind: 'check', payload: null },
  ], null] },
  { fn: 'fold', arg: [[{ actor: 'p', kind: 'check', payload: { k: '2:b2:0' } }], { annex: [{ t: 1 }], checked: { '1:b1:0': true }, sessId: 'old' }] },
  { fn: 'foldSan', arg: {
    checked: { '1:b1:0': 1, 'bad': true, '2:b:1': 0 }, counters: { c1: '2', 'x y': 1 }, cxb: { '1': { id: 'b1', t: 2 }, '5': { id: 'b2' } },
    events: [{ id: 'e1', label: 'MOT', ref: { type: 'timer', id: 't1' }, t: '5', voidAt: '6' }, { id: 12345, t: null, voidAt: null }, null, 'x', [1]],
    exercise: 1, flowEnded: 'yes', nav: ['b1', 'b2'], navSeq: [1, 2], sessId: 'ignored', startedAt: '77',
    timers: { t1: { anchor: 5, cycles: 1, elapsedMs: 2, running: 1, stoppedAt: 3 }, t2: 5 },
    verified: { '1:b1:0': { a: 'p', t: 1 }, '1:b1:1': 5, '1:b1:2': 'x' }, vgaps: 'nope' } },
  { fn: 'foldSan', arg: null }, { fn: 'foldSan', arg: { nav: ['b1'], navSeq: [1, 2] } },
  { fn: 'hash', arg: { checked: { '1:b1:0': true, '1:b1:1': false, 'z:b:1': true }, counters: { c1: 2.5, c2: 0 }, flowEnded: true, nav: ['b1', 'b2'], navSeq: [1, 2],
    timers: { t1: { cycles: 3 }, t2: {} }, verified: { '1:b1:0': {} }, vgaps: {} } },
  { fn: 'hash', arg: {} },
  { fn: 'offset', arg: [{ t0: 1000, t1: 1100, srv: 5000 }, { t0: 2000, t1: 2500, srv: 9000 }, { t0: 3000, t1: 3080, srv: 7100 }] },
  { fn: 'offset', arg: [{ t0: 1000, t1: 1100, srv: 5000 }, { t0: 3000, t1: 3080, srv: 7101 }] },
  { fn: 'offset', arg: [{ t0: 1000, t1: 900, srv: 5000 }] }, { fn: 'offset', arg: [] },
  { fn: 'iso', arg: ['2026-09-30T12:34:56.789+00:00', '2026-09-30T12:34:57.012345+00:00', '2026-09-30T12:34:56Z', '2026-09-30T12:34:56.7Z',
    '2026-09-30T14:34:56.789+02:00', '2026-09-30T08:04:56-04:30', '1999-12-31T23:59:59.999Z', '2026-02-29T00:00:00Z', 'garbage', ''] },
  { fn: 'isoOut', arg: [0, 1727697600000, 1727697600123.9, 951782400000, -1, 253402300799999] },
  { fn: 'stream', arg: [['1:3f2c1a9e-0000-4000-8000-000000000001', '2:3f2c1a9e-0000-4000-8000-000000000002'], [], ['é:€']] },
  { fn: 'whitelist', arg: { a: 1, anchor: 5, code: 'X', cxb: { '1': {} }, k: 'k', label: 'MOT', nav: [1], o: 'o', ref: { type: 'x', label: 'nested' }, state: 'quit', take: true } },
];
export async function run(inputs) {
  const c = x => JSON.parse(JSON.stringify(x === undefined ? null : x));
  const out = [];
  for (const { fn, arg } of inputs) {
    const a = c(arg);
    switch (fn) {
      case 'code': out.push({ norm: shareCodeNorm(a), valid: shareCodeValid(a), bad: shareCodeBadChars(a), fmt: shareCodeFmt(a) }); break;
      case 'fromHash': out.push(shareCodeFromHash(a)); break;
      case 'payload': out.push(c(sharePayload(a))); break;
      case 'can': { const o = {}; for (const r of ['lead', 'scribe', 'x', null]) for (const k of [...SHARE_KINDS_ANY, ...SHARE_KINDS_LEAD, 'zz']) o[r + '/' + k] = shareCan(r, k); out.push(o); break; }
      case 'applyMode': out.push(a.map(shareApplyMode)); break;
      case 'vf': out.push({ norm: a.map(v => vfNorm(v)), time: a.map(v => vfTime(v)), actor: a.map(v => vfActor(v)), map: c(vfMapNorm(Object.assign({}, a))) }); break;
      case 'navNorm': out.push(c(shareNavNorm(a[0], a[1]))); break;
      case 'cxbNorm': out.push(c(shareCxbNorm(a[0], a[1]))); break;
      case 'cxbForFiche': out.push(c(cxbForFiche(a[0], a[1]))); break;
      case 'snap': out.push(c(shareSnap(a, !!(a && a.stopClosed)))); break;
      case 'diff': {
        const sv = Runtime.sessionId; Runtime.sessionId = a[2];
        try { out.push(c(shareDiff(a[0] ? shareSnap(a[0], false) : null, shareSnap(a[1], false)))); } finally { Runtime.sessionId = sv; }
        break; }
      case 'fold': out.push(c(shareFold(a[0], a[1] || undefined))); break;
      case 'foldSan': out.push(c(slFoldSan(a))); break;
      case 'hash': out.push(shareStateHash(a)); break;
      case 'offset': out.push(shareOffset(a)); break;
      case 'iso': out.push(a.map(s => { const n = Date.parse(s); return Number.isFinite(n) ? n : null; })); break;
      case 'isoOut': out.push(a.map(n => new Date(n).toISOString())); break;
      case 'stream': { const r = []; for (const ids of a) r.push(await hexDigest(ids.join(','))); out.push(r); break; }
      case 'whitelist': { const pl = {}; for (const k of Object.keys(a)) if (SHARE_PAYLOAD_KEYS.indexOf(k) >= 0) pl[k] = a[k]; out.push({ pl, keys: SHARE_PAYLOAD_KEYS, keep: SHARE_KEEP, any: SHARE_KINDS_ANY, lead: SHARE_KINDS_LEAD, travels: SHARE_TRAVELS, local: SHARE_LOCAL, alpha: SHARE_ALPHA }); break; }
      default: out.push({ error: 'fn inconnue ' + fn });
    }
  }
  return out;
}
