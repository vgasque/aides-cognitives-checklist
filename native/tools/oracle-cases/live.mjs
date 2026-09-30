// Session vivante : tmIsDue, tmLiveOrder, TM_SOON_MS, monPick, monBandData, timerDisplay, wtTimerModel,
// wtCountModel, evDeltas, liveWhereText, endSessOpenTxt ; vocabulaire des repères : sanitizeTags, tkLabels,
// tagAll, tagSuggest, tagLabel, tagRank — sur le corpus de fiches et des états de minuteurs variés.
import { FICHES } from './_fiches.mjs';

const NOW = 1727700000000;
const T = (id, o) => ({ id, label: '', type: 'interval', seconds: 120, autoloop: false, onDue: '', elapsedMs: 0, running: false, lastStart: 0, cycles: 0, ack: false, ...o });
const TIMERS = [
  T('a', { label: 'Cycle RCP (2 min)', running: true, lastStart: NOW - 30000, autoloop: true }),
  T('b', { label: 'Adrénaline', running: true, lastStart: NOW - 100000, seconds: 240, elapsedMs: 20000 }),
  T('c', { label: 'Échu', elapsedMs: 120000, onDue: '  Réévaluer  ' }),
  T('d', { label: 'Échu acquitté', elapsedMs: 130000, ack: true }),
  T('e', { label: 'Pause', elapsedMs: 50000, cycles: 1 }),
  T('f', { label: '', type: 'stopwatch', running: true, lastStart: NOW - 5000 }),
  T('g', { label: 'Chrono arrêté', type: 'stopwatch', elapsedMs: 65000 }),
  T('h', { label: 'Jamais lancé', seconds: 300 }),
  T('i', { label: 'Relancé', running: true, lastStart: NOW - 100, elapsedMs: 0, seconds: 60 }),
  T('j', { label: 'Loin', running: true, lastStart: NOW, seconds: 900, autoloop: true }),
  T('k', { label: 'Échu cyclique', elapsedMs: 200000, autoloop: true }),
  T('l', { label: 'Zéro', seconds: 0, running: true, lastStart: NOW - 10 }),
  T('m', { label: 'Futur', running: true, lastStart: NOW + 5000, seconds: 30, autoloop: true }),
];
const EVENTS = [
  { id: 'e1', t: NOW - 200000, ref: { type: 'counter', id: 'n1', v: 1 } },
  { id: 'e2', t: NOW - 110000, ref: { type: 'counter', id: 'n1', v: 2 } },
  { id: 'e3', t: NOW - 100000, ref: { type: 'timer', id: 't1' } },
  { id: 'e4', t: NOW - 99000, ref: { type: 'counter', id: 'n1', v: 3 }, voidAt: 5 },
  { id: 'e5', t: NOW - 60000, ref: { type: 'counter', id: 'n1', v: 3 } },
  { id: 'e6', t: NOW - 59000, ref: { type: 'core', k: 'renfort' } },
  { id: 'e7', t: NOW - 58000 },
  { id: 'e8', t: NOW - 20000, ref: { type: 'counter', id: 'bad id' } },
  { id: 'e9', t: NOW - 1000, ref: { type: 'timer', id: 't1' }, label: 'Manuel' },
  { id: 'e10', t: NOW - 500, ref: { type: 'counter', id: 'n1', v: 4 } },
  { id: 'e11', t: NOW - 400, ref: { type: 'counter', id: 'bad id' } },
  { id: 'e12', t: NOW - 300, ref: { type: 'bad type', id: 'n1' } },
  { id: 'e13', t: NOW - 200, ref: { type: 'bad type', id: 'n1' } },
];
const TAGS = [{ k: 'mru', l: 'Médecin régulateur', a: ['mru', 'regul', '  ', 'x'.repeat(30)] }, { l: 'Famille prévenue' }, { label: 'Anesthésiste', alias: ['MAR'] },
  { k: 'bad key', l: 'Clé invalide' }, { k: 'mru', l: 'Doublon' }, { l: '' }, null, 'str', { l: 'x'.repeat(50) }, { k: 5, l: 'Clé nombre' }];
export const inputs = [
  { k: 'timers', timers: TIMERS, now: NOW, events: EVENTS, labels: EVENTS.map((e, i) => (i % 2 ? 'L' + i : '')) },
  { k: 'tags', tags: TAGS },
  ...FICHES.slice(0, 40).map((fiche, i) => ({ k: 'fiche', fiche, i, now: NOW, events: EVENTS })),
];
export function run(inputs) {
  const J = x => JSON.parse(JSON.stringify(x === undefined ? null : x));
  const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  return inputs.map(x => {
    if (x.k === 'timers') {
      const ts = x.timers, obj = {};
      ts.forEach(t => { obj[t.id] = t; });
      const subsets = [ts, ts.filter(t => t.type === 'interval' && !t.running), ts.filter(t => t.running), [], ts.slice(0, 2), ts.slice(4)];
      const nows = [x.now, x.now + 60000, x.now - 200000];
      return {
        due: ts.map(tmIsDue), soon: TM_SOON_MS, monNow: MON_NOW,
        order: nows.map(n => subsets.map(s => tmLiveOrder(s, n).map(t => t.id))),
        pick: nows.map(n => subsets.map(s => { const o = {}; s.forEach(t => { o[t.id] = t; }); const p = monPick(o, n); return p ? p.id : null; })),
        band: nows.map(n => J(monBandData(obj, x.events, n, x.labels))), bandNoLab: J(monBandData(obj, x.events, x.now)),
        disp: nows.map(n => ts.map(t => J(timerDisplay(t, n)))),
        wt: nows.map(n => ts.map(t => [J(wtTimerModel(t, n)), J(wtTimerModel(t, n, { hint: 'Indice', gr: 120, exited: true, lat: 'au bloc' }))])),
        deltas: J(evDeltas(x.events)),
      };
    }
    if (x.k === 'tags') return J(sanitizeTags(x.tags));
    const f = migrate(J(x.fiche));
    const ids = (f.blocks || []).map(b => b.id);
    const nav = ids.length ? [ids[0], ids[ids.length - 1], ids[x.i % ids.length]] : [];
    const navSeq = [1, 0, 3];
    const checked = {};
    if (ids.length) { checked['1:' + ids[0] + ':0'] = true; checked['2:' + ids[ids.length - 1] + ':1'] = true; }
    const R = { fiche: f, nav, navSeq, checked, events: x.events, timers: { a: { running: true }, b: { running: false }, c: { running: true } } };
    const RT = Runtime;
    RT.timers = { z1: { id: 'z1', label: '', type: 'interval', adhoc: true }, z2: { id: 'z2', label: 'Ad hoc nommé', type: 'stopwatch', adhoc: true }, z3: { id: 'z3', label: 'pas adhoc' } };
    RT.adhocCounters = [{ id: 'y1', label: '', adhoc: true }, { id: 'y2', label: 'Compteur ad hoc', adhoc: true }];
    const ex = { timers: Object.values(RT.timers).filter(t => t && t.adhoc), counters: RT.adhocCounters };
    const tags = [{ k: 'mru', l: 'Médecin régulateur', a: ['mru', 'regul'] }, { l: 'Famille prévenue' }];
    const all = tagAll(f, tags, ex);
    const refs = [...all.map(o => o.ref), { type: 'counter', id: 'n1', v: '3' }, { type: 'counter', id: 'zz', v: null }, { type: 'counter', id: 'n1', v: 2.6 },
      { type: 'step', b: ids[0] || 'x', i: '1' }, { type: 'step', b: ids[0] || 'x', i: 1.5 }, { type: 'step', b: ids[0] || 'x', i: -1 }, { type: 'step', b: ids[0] || 'x', i: null },
      { type: 'poso', i: 0 }, { type: 'poso', i: 99 }, { type: 'core', k: 'nope' }, { type: 'tag', k: 'mru' }, { type: 'x' }, null, 'str', { type: 'timer', id: 'z1' }];
    const counters = f.counters || [];
    const ev = { t: x.now - 5000, ref: { type: 'counter', id: 'n1', v: 3 } }, last = { t: x.now - 20000 };
    return {
      f: J(f), tz, nav, navSeq, checked,
      where: liveWhereText(R), whereNoEv: liveWhereText({ fiche: f, nav, events: [] }), whereEmpty: liveWhereText({ fiche: f, nav: [], events: [{ t: 0 }] }),
      open: J(endSessOpenTxt(R)),
      all: J(all), allNoEx: J(tagAll(f, tags)),
      sug: [J(tagSuggest(f, tags, ids[0], 5)), J(tagSuggest(f, tags, ids[1], 8, ['counter', 'timer'])), J(tagSuggest(f, tags, null, 0, ['poso'])), J(tagSuggest(f, null, ids[0], -3))],
      tk: tkLabels(x.events.concat([{ t: 1, label: 'Renommé', ref: { type: 'core', k: 'renfort' } }, { t: 2 }, null, { t: 3, ref: { type: 'step', b: ids[0] || 'x', i: 0 } }]), f, tags, ex),
      labels: refs.map(r => tagLabel(r, f, tags, ex)), labelsNoEx: refs.map(r => tagLabel(r, f, tags)),
      rank: ['', 'mru', 'adrenaline', 'regul', 'famille', 'choc électrique'].map(q => J(tagRank(q, all))),
      count: counters.map(c => [J(wtCountModel(c, 2, true, ev, last, x.now)), J(wtCountModel(c, 2, true, null, last, x.now)), J(wtCountModel(c, 2, false, null, last, x.now)),
        J(wtCountModel(c, 0, false, null, null, x.now)), J(wtCountModel(c, 5, true, { t: x.now - 100, ref: { type: 'counter', id: c.id } }, null, x.now)),
        J(wtCountModel(c, 1, true, { t: x.now - 100000, ref: { type: 'counter', id: c.id, v: 0 } }, null, x.now))]),
    };
  });
}

// Fixture compacte ; la fiche brute n'y est pas recopiée (la sortie `f` porte sa forme migrée).
export const compact = true;
export const slim = ({ fiche, fiches, ...rest }) => rest;
