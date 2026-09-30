// Partage « en direct » : signalisation compacte, charges SO:/SA:, trames RPC, adresse locale,
// et le HUB de l'hôte rejoué sur un scénario déterministe (horloge, ids et secrets injectés).
const SDP_OFFER = [
  'v=0', 'o=- 8810094451223 2 IN IP4 127.0.0.1', 's=-', 't=0 0', 'a=group:BUNDLE 0', 'a=extmap-allow-mixed', 'a=msid-semantic: WMS',
  'm=application 9 UDP/DTLS/SCTP webrtc-datachannel', 'c=IN IP4 0.0.0.0',
  'a=candidate:1467250027 1 udp 2122260223 9b0e1adb-ef3c-4d91-9293-30c565438ab7.local 61735 typ host generation 0 network-id 1',
  'a=candidate:1467250028 1 UDP 2122194687 192.168.1.10 54321 typ host generation 0',
  'a=candidate:1467250028 1 udp 2122194687 192.168.1.10 54321 typ host generation 0',
  'a=candidate:1467250029 2 udp 2122194686 192.168.1.10 54322 typ host generation 0',
  'a=candidate:842163049 1 udp 1686052607 88.1.2.3 61735 typ srflx raddr 0.0.0.0 rport 0 generation 0',
  'a=candidate:1 1 tcp 1518280447 192.168.1.10 9 typ host tcptype active',
  'a=candidate:7 1 udp 2122129151 fe80::1 50000 typ host generation 0',
  'a=ice-ufrag:wXyZ', 'a=ice-pwd:nLp3qTncIC1wOTaHc2jB39Q8', 'a=ice-options:trickle',
  'a=fingerprint:sha-256 84:b1:86:E0:18:2F:11:7F:2F:5B:36:1C:D0:D7:4C:DD:8F:DB:5D:66:A9:12:EE:69:3E:29:81:6F:0D:89:87:F9',
  'a=setup:actpass', 'a=mid:0', 'a=sctp-port:5000', 'a=max-message-size:262144', ''].join('\r\n');
const SDP_ANSWER = SDP_OFFER.replace('a=setup:actpass', 'a=setup:active').replace('wXyZ', 'AbCd');
export const inputs = [
  { fn: 'sdp', arg: SDP_OFFER }, { fn: 'sdp', arg: SDP_ANSWER }, { fn: 'sdp', arg: 'garbage' },
  { fn: 'rebuild', arg: { u: 'wXyZ', p: 'pw', f: '84B186E0182F117F2F5B361CD0D74CDD8FDB5D66A912EE693E29816F0D8987F9', s: 'active', c: ['192.168.1.10~54321', 'x.local~1', 'noport'] } },
  { fn: 'rebuild', arg: { u: 'a', p: 'b', f: 'ABC', s: 'actpass', c: [] } }, { fn: 'rebuild', arg: { u: 'a', p: '', f: 'AB', s: 'x', c: [] } },
  { fn: 'rebuild', arg: { u: 'a', p: 'b', f: 'AB', s: 'x', c: 'nope' } },
  { fn: 'pack', arg: { k: 'j4x2', u: 'wXyZ8aBc', p: 'nLp3qTncIC1wOTaHc2jB39Q8', f: '84B186E0182F117F2F5B361CD0D74CDD8FDB5D66A912EE693E29816F0D8987F9', s: 'actpass',
    c: ['9b0e1adb-ef3c-4d91-9293-30c565438ab7.local~61735', '192.168.1.10~54321'] } },
  { fn: 'pack', arg: { k: 'zz', u: 'u', p: 'p', f: '84b186e0182f117f2f5b361cd0d74cdd8fdb5d66a912ee693e29816f0d8987f9', s: 'active',
    c: ['fe80::1~50000', '10.0.0.300~70000', '9B0E1ADB-EF3C-4D91-9293-30C565438AB7.LOCAL~1', 'host.lan~-1', 'a~b', '1.2.3.4~5', '6.7.8.9~10'] } },
  { fn: 'pack', arg: { k: 'é', u: 'ü', p: 'p', f: 'GG', s: 'actpass', c: [] } },
  ...['AQEEajR4Mgh3WHlaOGFCYxhuTHAzcVRuY0lDMXdPVGFIYzJqQjM5UTiEsYbgGC8Rfy9bNhzQ10zdj9tdZqkS7mk-KYFvDYmH-QIBmw4a2-88TZGSkzDFZUOKt_EnAMCoAQrUMQ',
    'AgEEajR4', '', '!!!', 'AQE', 'AQEEajR4Mgh3WHlaOGFCYxhuTHAzcVRuY0lDMXdPVGFIYzJqQjM5UTiEsYbgGC8Rfy9bNhzQ10zdj9tdZqkS7mk-KYFvDYmH-Q'].map(s => ({ fn: 'unpack', arg: s })),
  { fn: 'rpc', arg: ['{"i":1,"n":"pull","p":{"secret":"s","since":0}}', '{"i":2,"r":null}', '{"i":3,"e":"timeout"}', '{"i":4}', '{"n":"x"}', '[1]', 'AC:GO', '{"i":null,"r":1}', '{"i":5,"n":""}'] },
  { fn: 'rpcOut', arg: null },
  { fn: 'localCand', arg: [['10.1.2.3~1'], ['172.16.0.1~1'], ['172.32.0.1~1'], ['172.31.9.9~2'], ['169.254.1.1~3'], ['x.local~4'], ['88.1.2.3~5', 'fe80::1~6'], [], ['172.16~1'], ['192.168.0.1']] },
  { fn: 'hub', arg: [
    ['join', 'Médecin avec un libellé beaucoup trop long pour tenir'], ['join', ''], ['pull', 'S2', 0], ['pull', 'S1', 0], ['pull', 'nope', 0],
    ['push', 'S1', [{ event_id: 'e1', kind: 'check', payload: { k: '1:b:0', label: 'MOT' }, ts: '2026-09-30T12:00:00.000Z' },
      { event_id: 'e1', kind: 'check', payload: { k: '1:b:1' } }, { event_id: 'e2', kind: 'uncheck', payload: { k: '1:b:0' } },
      { kind: 'check' }, null, { event_id: 'e3', kind: 'mark', payload: { cxb: 1, id: 'm1', ref: { type: 'core', k: 'bilan', extra: 'x' }, t: 5 } }]],
    ['push', 'S2', [{ event_id: 'h1', kind: 'session_start', payload: { exo: false, id: 's', t: 9 } }, { event_id: 'h2', kind: 'sig', payload: 'str' }]],
    ['pull', 'S3', 0], ['pull', 'S3', 2], ['setRole', 'p3', 'lead'], ['push', 'S3', [{ event_id: 'e4', kind: 'uncheck', payload: { k: '1:b:0' } }]],
    ['revoke', 'p1'], ['revoke', 'p4'], ['pull', 'S4', 0], ['push', 'S4', [{ event_id: 'e5', kind: 'check', payload: {} }]],
    ['setRole', 'zz', 'lead'], ['join', 'a'], ['join', 'b'], ['join', 'c'], ['join', 'd'], ['join', 'e'], ['join', 'f'],
    ['end'], ['pull', 'S3', 0], ['push', 'S3', []], ['join', 'z']] },
];
export async function run(inputs) {
  const c = x => JSON.parse(JSON.stringify(x === undefined ? null : x));
  const out = [];
  for (const { fn, arg } of inputs) {
    const a = c(arg);
    switch (fn) {
      case 'sdp': out.push(slSdpExtract(a)); break;
      case 'rebuild': out.push(slSdpRebuild(a)); break;
      case 'pack': { let r = null; try { r = slPairPack(a); } catch (e) { r = null; } out.push({ b64: r, back: r ? slPairUnpack(r) : null }); break; }
      case 'unpack': out.push(slPairUnpack(a)); break;
      case 'rpc': out.push(a.map(t => slRpcUnpack(t))); break;
      case 'rpcOut': out.push([JSON.parse(slRpcPack(3, 'push', { secret: 's', events: [] })), JSON.parse(slRpcReply(3, { ok: true })), JSON.parse(slRpcReply(4, null, 'hub')), JSON.parse(slRpcPack(1, 'end'))]); break;
      case 'localCand': out.push(a.map(x => slLocalCand(x))); break;
      case 'hub': {
        let t = 1727697600000, nu = 0, ns = 0;
        const h = slHub({ now: () => t, uid: () => 'p' + (++nu), secret: () => 'S' + (++ns), shareId: 'shl1', fiche: { id: 'f1', title: 'T' }, guestRole: 'scribe', hostLabel: 'Hôte' });
        const r = [];
        for (const [op, x, y] of a) {
          t += 1000;
          if (op === 'join') r.push(h.join(x));
          else if (op === 'pull') r.push(await h.pull(x, y));
          else if (op === 'push') r.push(h.push(x, y));
          else if (op === 'revoke') r.push(h.revoke(x));
          else if (op === 'setRole') r.push(h.setRole(x, y));
          else if (op === 'end') r.push(h.end());
        }
        out.push(c(r)); break; }
      default: out.push({ error: fn });
    }
  }
  return out;
}
