// Recherche, accueil, textes : txNorm, qTerms, hayMatch, ficheHaystack, markQTerms, searchSnippet,
// ficheSnipParts, protoSnipParts, frecencyScore, sanitizeUsage, mergeUsage, azLetter, azGroups, qaPick,
// byTitle, catSlug, detCatId, staleDate, relCandidatesFor, libVocab, spellFix, dlev, sinceTxt,
// revisedSinceTxt, fmtBytes, fmtMs, tkParseTime, sessStamp, tmLabelParts, et la posologie
// (posoTokens, posoName, posoScore, posoRank, posoSplit, posoParts).
import { FICHES } from './_fiches.mjs';

const TXT = ['', 'Adrénaline', 'ADRÉNALINE IM', 'Œdème de Quincke', 'İstanbul', 'ΟΔΟΣ Σ', 'straße', 'ﬁn', 'école', 'a⃝b',
  'Anaphylaxie — choc', '  choc   anaph  ', 'Crise convulsive ≥ 5 min', '😀 émoji', 'Ǆemal', 'ÀÉÎÕÜ àéîõü ç Ç', 'ÅNGSTRÖM', 'x̧'];
const TERMS = [['adre'], ['choc', 'anaph'], ['e'], ['ist'], ['οδος'], ['strasse', 'ss'], ['fin'], ['ecole'], ['ab'], ['5', 'min'], [], ['xx', 'x'], ['a', 'an', 'ana']];
const SNIP = [
  [['Adrénaline IM 0,5 mg, face antéro-latérale de la cuisse, à renouveler toutes les 5 min si besoin, jusqu’à amélioration clinique franche et durable'], 'renouveler'],
  [['', null, 'rien', '**Adrénaline** IM'], 'adre'],
  [['un deux trois quatre cinq six sept huit neuf dix onze douze treize quatorze quinze seize dix-sept dix-huit dix-neuf vingt adrénaline fin de phrase qui continue encore longtemps après le mot cherché pour tester la coupe'], 'adrenaline'],
  [['Œdème', 'İİİİ adrénaline'], 'adrenaline'],
  [['ééé cible'], 'cible'],
  [['x'], ''], [['abc'], 'zzz'], [['aaa aaa'], 'aa'],
  [['y'.repeat(50) + 'adrénaline suite du texte'], 'adrenaline'], [['debut ' + 'y'.repeat(50) + 'adrénaline'], 'adrenaline'],
];
const TITLES = ['Bloc 10', 'Bloc 2', 'bloc 1', 'Éclampsie', 'eclampsie', 'Anaphylaxie', 'anaphylaxie adulte', 'Arrêt cardiaque', 'ACR',
  'Zona', 'zèbre', 'Œdème', 'Oedeme', '12 heures', '9 heures', 'État de mal', 'Etat de choc', '', 'Choc septique', 'choc',
  'Hypoglycémie', 'Hyperkaliémie', 'Âge', 'Aide', 'Côte', 'Cote', 'Coté', 'Côté', 'Intox. CO', 'Intoxication', 'Bloc 2b', 'Bloc 2a', 'Bloc 02'];
const USAGE = [
  { a: { f1: { n: 3, t: 100 }, f2: { n: 1, t: 50 }, 'bad id': { n: 5, t: 1 }, __proto__x: { n: 1 }, f3: { n: 0, t: 1 }, f4: { n: '7', t: '12.9' }, f5: [], f6: 'x', f7: { n: 99999, t: -5 } },
    b: { f1: { n: 3, t: 200 }, f2: { n: 4, t: 10 }, f8: { n: 1.9, t: 3 } } },
  { a: null, b: { x: { n: 1, t: 1 } } },
  { a: [{ n: 2, t: 3 }], b: {} },
  { a: { f1: { n: '10', t: 1 } }, b: { f1: { n: '9', t: 5 } } },
  { a: Object.fromEntries(Array.from({ length: 230 }, (_, i) => ['u' + i, { n: 1 + (i % 3), t: 1000 + i }])), b: {} },
];
const FREC = [[{ n: 3, t: 0 }, 86400000 * 10], [{ n: 3, t: 0 }, 86400000 * 15], [{ n: 3, t: 0 }, 86400000 * 16], [{ n: 3, t: 0 }, 86400000 * 61], [{ n: 0, t: 0 }, 1], [null, 1], [{ n: 2 }, 5], [{ n: 2, t: 10 }, 0]];
const AZ = ['', 'abc', 'Éclair', ' zèbre', '1er', 'ßeta', 'ﬁn', '#x', 'ŉx', '😀', 'Ω', 'Ǆ', 'Å'];
const VOC = { items: [{ title: 'Anaphylaxie de l’adulte', code: 'ANA-1', discriminant: 'grade III' }, { title: 'Arrêt cardio-respiratoire', code: 'ACR', discriminant: '' },
  { title: 'Hyperkaliémie sévère', code: '', discriminant: 'insuffisance rénale' }, { title: 'État de mal épileptique', code: 'EME', discriminant: null }], extra: ['Urgences', 'Réanimation'] };
const SPELL = ['anafilaxie', 'anaphylaxie', 'anaph', 'arret cardio', 'hyperkalemie', 'epileptik', 'xyz', 'etat mal epileptque', 'reanimaton', 'urgnces', 'abc', '', 'cardio-respiratoir'];
const DLEV = [['', '', 1], ['abc', 'abc', 1], ['abc', 'acb', 1], ['anafilaxie', 'anaphylaxie', 3], ['anafilaxie', 'anaphylaxie', 2], ['kitten', 'sitting', 3], ['ab', 'ba', 0], ['a', '', 2], ['😀a', 'a😀', 2], ['abcdef', 'badcfe', 3]];
const POSO = [
  { items: ['Adrénaline IM : 0,5 mg', '△ Amiodarone : 300 mg IVD', 'Remplissage : NaCl 20 mL/kg', '⚠ Salbutamol : aérosol', 'Glucagon', '**Hydrocortisone** : 200 mg IV', '  '],
    hays: ['Adrénaline intramusculaire', 'choc réfractaire, amio IV', 'bronchospasme nébulisation', 'per os', '', 'sous-cutané voie orale', 'hydro'] },
  { items: ['A : 1', 'B : 2'], hays: ['A'] },
  { items: ['Nor : 1', 'Dobu : 2', 'Adré : 3', 'Vaso : 4'], hays: ['xyz', 'adrenaline dobutamine'] },
];
export const inputs = [
  { k: 'text', txt: TXT, terms: TERMS },
  { k: 'snip', snip: SNIP },
  { k: 'titles', titles: TITLES },
  { k: 'usage', usage: USAGE, frec: FREC },
  { k: 'az', az: AZ },
  { k: 'vocab', voc: VOC, spell: SPELL, dlev: DLEV, v2: ['carto', 'carta', 'cartz', 'bbbb', 'aaaa'], q2: ['carte', 'cbbb', 'abab', 'cartee'] },
  { k: 'poso', poso: POSO },
  { k: 'misc', bytes: [0, 1, 1023, 1024, 1536, 1048575, 1048576, 1572864, 1073741823, 1073741824, 5e9, -5, 2.5, '12', null],
    ms: [0, 999, 1000, 59999, 60000, 3599999, 3600000, 7325000, -5, 1e10],
    times: ['', '1', '12', '123', '1234', '12345', '123456', '1234567', '12:34', '12h34', '9 5', '24', '23:59:59', '23:60', '1:2:3:4', '123:4', 'abc', ' 7 ', '٣'],
    stamps: [0, 1727700000000, 1735689599999, 1719792000000],
    stale: [['', 0], ['2020-01', 1727700000000], ['2025-01', 1727700000000], ['2024-09', 1727700000000], ['2022-09-29', 1727700000000], ['xx', 1], ['2022-10', 1727700000000]],
    slugs: ['', 'Anesthésie', '  Soins  critiques  ', 'Œdème & co', 'x'.repeat(60), '---', 'ÉÉÉ', 'Réa/SMUR (nuit)'],
    labels: ['', 'Cycle (2 min)', 'Adrénaline (IM)', 'A (b)', 'Nom (x)', 'Nom ( )', 'Nom (précision) suite', '(seul)'],
    since: [[0, 1000], [5000, 1000], [1000, 3700000]] },
  ...FICHES.slice(0, 12).map(fiche => ({ k: 'fiche', fiche })),
  { k: 'rel', fiches: FICHES.slice(0, 12).map((f, i) => ({ ...f, library: i % 3 === 0 ? 'L1' : null, deletedAt: i === 5 ? 1 : null, links: i === 2 ? ['f-acr'] : [] })) },
];
export function run(inputs) {
  const J = x => JSON.parse(JSON.stringify(x === undefined ? null : x));
  const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  return inputs.map(x => {
    if (x.k === 'text') return { norm: x.txt.map(txNorm), q: x.txt.map(qTerms),
      mark: x.txt.map(s => x.terms.map(t => markQTerms(s, t))), match: x.txt.map(s => x.terms.map(t => hayMatch(txNorm(s), t))) };
    if (x.k === 'snip') return x.snip.map(([p, q]) => searchSnippet(p, q));
    if (x.k === 'titles') return { sorted: x.titles.slice().map((t, i) => ({ title: t, i })).sort(byTitle).map(o => o.i),
      pairs: x.titles.map(a => x.titles.map(b => Math.sign(byTitle({ title: a }, { title: b })))) };
    if (x.k === 'usage') return { san: x.usage.map(u => sanitizeUsage(u.a)), merge: x.usage.map(u => mergeUsage(u.a, u.b)), frec: x.frec.map(([u, now]) => frecencyScore(u, now)) };
    if (x.k === 'az') return { letters: x.az.map(azLetter), groups: azGroups(x.az, t => t).map(g => ({ L: g.L, items: g.items })),
      qa: qaPick(x.az.map((t, i) => ({ id: 'i' + i, t })), ['i3', 'i0', 'zz', 'i7']).map(o => o.id) };
    if (x.k === 'vocab') { const v = libVocab(x.voc.items, x.voc.extra);
      return { vocab: v, spell: x.spell.map(q => spellFix(q, v)), dlev: x.dlev.map(([a, b, m]) => dlev(a, b, m)), empty: spellFix('abcd', []), s2: x.q2.map(q => spellFix(q, x.v2)) }; }
    if (x.k === 'poso') return x.poso.map(p => ({ tokens: p.items.concat(p.hays).map(posoTokens), names: p.items.map(posoName),
      scores: p.items.map(i => p.hays.map(h => posoScore(posoName(i), h))), rank: p.hays.map(h => posoRank(p.items, h)),
      split: p.hays.map(h => [posoSplit(p.items, h), posoSplit(p.items, h, 2), posoSplit(p.items, h, 10)]), parts: p.items.map(posoParts) }));
    if (x.k === 'misc') return { bytes: x.bytes.map(fmtBytes), ms: x.ms.map(fmtMs), times: x.times.map(tkParseTime), stamps: x.stamps.map(sessStamp), tz,
      stale: x.stale.map(([v, now]) => { const r = Date.now; Date.now = () => now; try { return staleDate(v); } finally { Date.now = r; } }),
      slugs: x.slugs.map(catSlug), det: x.slugs.map(s => (catSlug(s) ? detCatId(s) : null)), labels: x.labels.map(tmLabelParts),
      since: x.since.map(([t, now]) => sinceTxt(t, now)) };
    if (x.k === 'fiche') {
      const f = migrate(J(x.fiche));
      const sess = [{ ficheId: f.id, aidRev: f.updatedAt - 1, startedAt: 1727700000000 }, { ficheId: f.id, aidRev: f.updatedAt, startedAt: 1727600000000 }, { ficheId: 'autre', aidRev: 1, startedAt: 9e12 }];
      const catName0 = 'Réanimation';
      return { f: J(f), hay: (() => { categories.length = 0; return ficheHaystack(f); })(), parts: ficheSnipParts(f).map(p => (p == null ? null : String(p))),
        snips: ['adre', 'choc', 'masser', 'e', 'b1', 'à compléter', 'zzz'].map(q => searchSnippet(ficheSnipParts(f), q)),
        rev: [revisedSinceTxt(f, sess), revisedSinceTxt(f, sess.slice(1)), revisedSinceTxt(f, [])], tz, catName0 };
    }
    if (x.k === 'rel') {
      const fs = x.fiches.map(f => Object.assign(migrate(J(f)), { library: f.library, deletedAt: f.deletedAt }));
      const ps = fs.slice(0, 4).map((f, i) => ({ id: 'p' + i, title: ['Réf B', 'réf a', '', 'Réf 10'][i], code: i ? 'C' + i : '', library: i === 1 ? 'L1' : null, deletedAt: null }));
      return { fs: fs.map(J), ps, out: fs.map(e => relCandidatesFor(e, fs, ps)) };
    }
    return null;
  });
}

// Fixture compacte ; la fiche brute n'y est pas recopiée (la sortie `f` porte sa forme migrée).
export const compact = true;
export const slim = ({ fiche, fiches, ...rest }) => rest;
