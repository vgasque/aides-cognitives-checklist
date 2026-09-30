// Partage « par l'écran » : PRNG mulberry32, CDF du soliton robuste, indices de réparation,
// trames d'un émetteur à graine fixée, DEFLATE brut dans LES DEUX SENS (le web compresse →
// le natif décompresse ; le natif compresse → le web décompresse), fontaine complète dans les
// deux sens. Les vecteurs natifs viennent de `share-optical.native.json` (ShareNativeVectors).
import { readFileSync } from 'node:fs';
const native = JSON.parse(readFileSync(new URL('./share-optical.native.json', import.meta.url)));
const bytes = n => Array.from({ length: n }, (_, i) => (i * 37 + 11) % 251);
export const inputs = [
  { fn: 'mulberry', arg: [0, 1, 0x12345678, 0xDEADBEEF, 0xFFFFFFFF, 0x80000000] },
  { fn: 'cdf', arg: [...Array.from({ length: 40 }, (_, i) => i + 1), 50, 64, 100, 127, 200, 500, 1000, 4096] },
  // Les deux seuls calculs NON exacts de ltCdf : Math.log(k/δ) et Math.log(R/δ) (fdlibm côté V8).
  { fn: 'logs', arg: 3000 },
  { fn: 'indices', arg: [[0xDEADBEEF, 20], [0xDEADBEEF, 3], [1, 100], [0xFFFFFFFF, 1], [12345, 700]] },
  { fn: 'frames', arg: { data: bytes(1000), seed: 0x9ABCDEF0, type: 0 } },
  { fn: 'frames', arg: { data: bytes(10), seed: 7, type: 1 } },
  { fn: 'webDeflate', arg: ['', 'a', 'abcabcabc'.repeat(300), JSON.stringify({ sess: 's', at: 1, fiche: { id: 'f', title: 'Été €𝄞' }, snap: { nav: ['b1'] } }),
    Array.from({ length: 2000 }, (_, i) => String.fromCharCode(32 + (i * 7919) % 90)).join('')] },
  { fn: 'webFountain', arg: { json: { sess: 's-web', at: 1727697600000, fiche: { id: 'f1', title: 'Hémorragie', blocks: [] },
    snap: { checked: Object.fromEntries(Array.from({ length: 250 }, (_, i) => [`${i % 9 + 1}:b${i % 5}:${i % 17}`, true])), nav: ['b1'], navSeq: [1] } }, seed: 0x13572468 } },
  { fn: 'nativeDeflate', arg: native.deflate },
  { fn: 'nativeFountain', arg: native.frames },
];
export async function run(inputs) {
  const hex = u => [...u].map(b => b.toString(16).padStart(2, '0')).join('');
  const unhex = h => Uint8Array.from(h.match(/../g) || [], x => parseInt(x, 16));
  const deflate = async u => new Uint8Array(await new Response(new Blob([u]).stream().pipeThrough(new CompressionStream('deflate-raw'))).arrayBuffer());
  const inflate = async u => new Uint8Array(await new Response(new Blob([u]).stream().pipeThrough(new DecompressionStream('deflate-raw'))).arrayBuffer());
  const sha4 = async u => new Uint8Array(await crypto.subtle.digest('SHA-256', u)).slice(0, 4);
  const withSeed = (seed, f) => { const R = Math.random; Math.random = () => seed / 0xffffffff + 1e-12; try { return f(); } finally { Math.random = R; } };
  const out = [];
  for (const { fn, arg } of inputs) {
    switch (fn) {
      case 'mulberry': out.push(arg.map(s => { const r = ltMulberry(s); return Array.from({ length: 12 }, () => r()); })); break;
      case 'cdf': out.push(arg.map(k => ltCdf(k))); break;
      case 'logs': out.push(Array.from({ length: arg }, (_, i) => { const k = i + 1, R = Math.max(1, 0.1 * Math.log(k / 0.5) * Math.sqrt(k)); return [Math.log(k / 0.5), R, Math.log(R / 0.5)]; })); break;
      case 'indices': out.push(arg.map(([seed, k]) => { const cdf = ltCdf(k); return Array.from({ length: 40 }, (_, j) => [...ltIndices(seed, k + j, k, cdf)]); })); break;
      case 'frames': {
        const u = Uint8Array.from(arg.data);
        const tx = withSeed(arg.seed, () => ltTx(u, arg.type));
        tx.setH4(await sha4(u));
        const fr = Array.from({ length: tx.cycle * 2 + 1 }, (_, p) => hex(tx.frameAt(p)));
        out.push({ k: tx.k, cycle: tx.cycle, seed: ltParse(unhex(fr[0])).seed, frames: fr, parsed: (({ type, seed, i, k, z, h }) => ({ type, seed, i, k, z, h }))(ltParse(unhex(fr[fr.length - 1]))) });
        break; }
      case 'webDeflate': { const r = []; for (const t of arg) r.push({ text: t, hex: hex(await deflate(new TextEncoder().encode(t))) }); out.push(r); break; }
      case 'webFountain': {
        const z = await deflate(new TextEncoder().encode(JSON.stringify(arg.json)));
        const tx = withSeed(arg.seed, () => ltTx(z, 0));
        tx.setH4(await sha4(z));
        // un cycle et demi, en perdant une trame sur trois : la réparation doit suffire
        const fr = Array.from({ length: Math.ceil(tx.cycle * 2) }, (_, p) => tx.frameAt(p)).filter((_, p) => p % 3 !== 1).map(hex);
        const rx = ltRx(); let st = null; for (const f of fr) { st = ltRxFeed(rx, unhex(f)); if (st === 'done') break; }
        out.push({ frames: fr, webDone: st, webBack: st === 'done' ? await ltSnapUnpack(ltRxBytes(rx)) : null }); break; }
      case 'nativeDeflate': { const r = []; for (const v of arg) { let t = null; try { t = new TextDecoder().decode(await inflate(unhex(v.hex))); } catch (e) { t = 'ERREUR ' + e; } r.push(t); } out.push(r); break; }
      case 'nativeFountain': {
        const rx = ltRx(); const res = [];
        for (const f of arg) { res.push(ltRxFeed(rx, unhex(f))); if (res[res.length - 1] === 'done') break; }
        let o = null; try { o = await ltSnapUnpack(ltRxBytes(rx)); } catch (e) { o = 'ERREUR ' + e; }
        out.push({ res, o, h: rx.st && rx.st.h, sha: hex(await sha4(ltRxBytes(rx))) }); break; }
      default: out.push({ error: fn });
    }
  }
  return out;
}
