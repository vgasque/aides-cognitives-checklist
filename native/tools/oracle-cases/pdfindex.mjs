// Index inversé des documents PDF : ixTokens, ixBuild (octets du dictionnaire et des postings,
// comparés À L'OCTET), ixOpen + ixPagesOf (chaque terme), ixSearch — sur des documents tirés au sort
// (petits et grands : postings en varint ET en bitmap) et des enregistrements corrompus.
const TEXTS = ['', 'Adrénaline IM 0,5 mg', 'L’œdème de Quincke — ANAPHYLAXIE (grade III)', 'a b cd e2 x'.repeat(3), 'ÉÉÉ çà où', 'x'.repeat(30) + ' yy',
  'Crise convulsive ≥ 5 min : benzodiazépine', '😀 émoji et naïveté'];
let seed = 777;
const rnd = n => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed % n; };
const WORDS = ['adrenaline', 'adre', 'dose', 'mg', 'kg', 'choc', 'chocs', 'anaphylaxie', 'ab', 'abc', 'abcd', 'zz', 'z9', '10', '100', 'ivse', 'iv', 'intraveineuse', 'x'.repeat(24), 'bolus'];
const DOCS = [[], [[]], [['aa']], [['aa', 'aa', 'bb'], ['bb'], [], ['aa']]];
for (let d = 0; d < 30; d++) {
  const nP = 1 + rnd(d < 20 ? 12 : 90), pages = [];
  for (let p = 0; p < nP; p++) { const n = rnd(8), w = []; for (let i = 0; i < n; i++) w.push(WORDS[rnd(WORDS.length)]); pages.push(w); }
  DOCS.push(pages);
}
export const inputs = [{ k: 'tokens', texts: TEXTS }, ...DOCS.map(pages => ({ k: 'doc', pages })), { k: 'corrupt' }];
export function run(inputs) {
  const A = b => Array.from(new Uint8Array(b));
  const Q = [['adre'], ['dose', 'mg'], ['drenalin'], ['a'], ['ab'], ['zz', 'choc'], ['xxxxxxxx'], [], ['inconnu'], ['10'], ['0'], ['c', 'ch'], ['s\na']];
  return inputs.map(x => {
    if (x.k === 'tokens') return { tokens: x.texts.map(ixTokens), v: IX_V };
    if (x.k === 'doc') {
      const rec = ixBuild(x.pages), h = ixOpen(rec);
      return { rec: { v: rec.v, pages: rec.pages, terms: rec.terms, dict: A(rec.dict), post: A(rec.post) },
        pagesOf: h ? Array.from({ length: h.n }, (_, i) => ixPagesOf(h, i)) : null, search: Q.map(q => ixSearch(h, q)) };
    }
    // Enregistrements corrompus : version, termes, dictionnaire tronqué, postings incohérents.
    const base = ixBuild([['aa', 'bb'], ['bb', 'cc'], ['cc']]);
    const mk = (o) => Object.assign({ v: base.v, pages: base.pages, terms: base.terms, dict: base.dict, post: base.post }, o);
    const cut = (b, n) => new Uint8Array(b).slice(0, n).buffer;
    const recs = [mk({}), mk({ v: 2 }), mk({ terms: 0 }), mk({ terms: 9 }), mk({ dict: cut(base.dict, 4) }), mk({ post: cut(base.post, 1) }), mk({ post: new Uint8Array([0, 200, 200, 200, 200, 1]).buffer }),
      mk({ pages: 1 }), mk({ post: new Uint8Array([1, 255, 0, 5, 1, 2, 3, 4, 5, 6, 7]).buffer }), mk({ dict: new Uint8Array([0, 97, 97, 10, 5, 98, 10, 1, 99, 10]).buffer })];
    return recs.map(r => { const h = ixOpen(r); return { rec: { v: r.v, pages: r.pages, terms: r.terms, dict: A(r.dict), post: A(r.post) }, ok: !!h,
      pagesOf: h ? Array.from({ length: h.n }, (_, i) => ixPagesOf(h, i)) : null, search: Q.map(q => ixSearch(h, q)) }; });
  });
}
