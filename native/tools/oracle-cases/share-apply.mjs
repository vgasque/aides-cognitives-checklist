// Partage — application d'un lot distant à une session (état seul, sans peinture) :
// shareStateLive, shareNavState, shareVfState, shareApplyAway. `Share.offset` est posé par cas ;
// toutes les charges portent leurs heures (le repli sur Share.now() dépendrait de l'horloge).
const R0 = {
  checked: { '1:b1:0': true }, counters: { c1: 1 }, cxBack: {},
  events: [{ id: 'e1', label: 'MOT LOCAL', ref: { type: 'core', k: 'bilan' }, t: 1000 }, { id: 'e2', t: 3000 }],
  fiche: { id: 'f1', blocks: [{ id: 'b1' }, { id: 'b2' }] }, nav: ['b1'], navSeq: [1], seq: 1, startedAt: 500,
  timers: { t1: { cycles: 0, elapsedMs: 0, id: 't1', label: 'RCP', lastStart: 0, running: false, stoppedAt: 0 } },
  verified: { '1:b1:0': { a: 'x', t: 1 } }, vgaps: { '1:b1:1': { a: 'y', t: 2 } },
};
const E = (kind, payload, extra) => Object.assign({ actor: 'p2', kind, payload, seq: 7, ts: '2026-09-30T12:00:00.000Z' }, extra || {});
export const inputs = [
  { R: R0, offset: 0, evs: [E('check', { k: '1:b1:1' })] },
  { R: R0, offset: 0, evs: [E('uncheck', { k: '1:b1:0' })] },
  { R: R0, offset: 0, evs: [E('counter', { id: 'c1', v: '5' }), E('counter', { id: 'zz', v: 2 })] },
  { R: R0, offset: 250, evs: [E('timer_arm', { anchor: 1727697500000, cycles: 2, elapsedMs: 100, id: 't1', running: true })] },
  { R: R0, offset: -40, evs: [E('timer_stop', { anchor: 0, cycles: 1, elapsedMs: 9000, id: 't1', running: false })] },
  { R: R0, offset: 0, evs: [E('timer_arm', { id: 'inconnu', running: true, anchor: 5 })] },
  { R: R0, offset: 0, evs: [E('mark', { id: 'e1', ref: { type: 'counter', id: 'c1', v: 3 }, t: 2000 }), E('mark', { id: 'e9', label: 'X', ref: { type: 'bad' }, t: 1500 })] },
  { R: R0, offset: 0, evs: [E('mark_void', { id: 'e2', on: true, t: 3500 }), E('mark_void', { id: 'e1', on: false, t: 0 }), E('mark_void', { id: 'zz', on: true, t: 1 })] },
  { R: R0, offset: 0, evs: [E('offline_mark', { ref: { type: 'poso', i: 2 }, t: 2500, was: 'check' }), E('offline_mark', { ref: null, t: 2500 })] },
  { R: R0, offset: 0, evs: [E('session_start', { t: 777, exo: true }), E('session_start', { t: 0 })] },
  { R: R0, offset: 0, evs: [E('nav', { cxb: { '2': { id: 'b2', t: 4 }, '3': { id: 'bX', t: 1 } }, nav: ['b1', 'b2', 'b1'], navSeq: [1, 5, 3] })], nav: true },
  { R: R0, offset: 0, evs: [E('nav', { nav: ['b1'], navSeq: [] })], nav: true },
  { R: R0, offset: 0, evs: [E('verify', { k: '1:b1:1', t: 42 }), E('gap', { k: '1:b1:0', t: 43 }), E('verify', { k: 'bad', t: 1 })], vf: true },
  { R: R0, offset: 0, away: true, me: 'p1', evs: [E('check', { k: '2:b2:0' }), E('check', { k: '2:b2:1' }, { actor: 'p1' }), E('presence', { state: 'quit' }),
    E('nav', { nav: ['b1', 'b2'], navSeq: [1, 2] }), E('verify', { k: '2:b2:0', t: 9 }), E('flow_end', { on: true }), E('handoff', { take: true })] },
];
export function run(inputs) {
  const c = x => JSON.parse(JSON.stringify(x));
  const sv = Share.offset;
  try {
    return inputs.map(({ R, offset, evs, nav, vf, away, me }) => {
      Share.offset = offset;
      const r = c(R), res = [];
      if (away) { const svMe = Share.me; Share.me = me; try { res.push(shareApplyAway(r, c(evs).filter(e => !(e.actor && e.actor === me) && shareApplyMode(e.kind) !== 'none'))); } finally { Share.me = svMe; } }
      else for (const e of c(evs)) {
        if (nav) { const x = shareNavState(r, e.payload); res.push(x ? x.avant : null); }
        else if (vf) res.push(shareVfState(r, e));
        else res.push(!!shareStateLive(r, e));
      }
      return { R: c(r), res };
    });
  } finally { Share.offset = sv; }
}
