// link-claim — CONNEXION PAR LE TÉLÉPHONE (v5.111, A643)
//
// LA SEULE PIÈCE DU PROJET QUI TIENT LA CLÉ DE SERVICE. Elle existe parce que GoTrue ne crée pas de
// session depuis SQL : une fois la demande approuvée sur le téléphone, il faut une session NEUVE
// pour le poste — jamais celle du téléphone (son jeton de rafraîchissement tourne à chaque usage :
// deux appareils sur le même se déconnecteraient l'un l'autre, et le poste ne serait plus
// révocable seul).
//
// CE QU'ELLE FAIT, ET RIEN D'AUTRE (forme durcie par la revue de sécurité, avant publication) :
//   1. `link_claim_srv(id, clé du poste)` — exécutable par la clé de service seule — vérifie la CLÉ
//      DU POSTE (jamais dans le QR : photographier l'écran ne suffit pas), l'approbation, et marque
//      la demande réclamée de façon ATOMIQUE ; elle rend l'e-mail du compte ;
//   2. `generateLink({type:'magiclink'})` fabrique un lien de connexion à usage unique (aucun e-mail
//      n'est envoyé), que la fonction échange ELLE-MÊME contre la session (`verifyOtp`) ;
//   3. `link_bind_srv` lie l'identifiant de CETTE session à la demande — une seule fois. Si la
//      demande est déjà liée, la session tout juste créée est détruite et rien ne sort ;
//   4. elle rend la session au poste. L'e-mail ne sort jamais d'ici.
//
// DÉPLOIEMENT (une fois, puis à chaque modification de ce fichier) :
//     supabase functions deploy link-claim --no-verify-jwt
//     supabase secrets set APP_ORIGIN=https://<adresse de l'app>     (recommandé : CORS restreint)
// `--no-verify-jwt` est NÉCESSAIRE et sans risque : le poste n'a pas encore de compte, et la clé
// publishable n'est pas un JWT. La capacité, c'est la CLÉ DU POSTE, vérifiée en SQL.
// SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY et SUPABASE_ANON_KEY sont fournies par la plateforme.
import { createClient } from 'npm:@supabase/supabase-js@2.45.4';

const ORIGIN = Deno.env.get('APP_ORIGIN') ?? '*';
const CORS = {
  'Access-Control-Allow-Origin': ORIGIN, 'Vary': 'Origin',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { ...CORS, 'content-type': 'application/json' } });
const OPTS = { auth: { persistSession: false, autoRefreshToken: false } };
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ ok: false, err: 'method' }, 405);
  let body: { id?: unknown; key?: unknown };
  try { body = await req.json(); } catch { return json({ ok: false, err: 'bad_request' }, 400); }
  const id = String(body?.id ?? ''), key = String(body?.key ?? '');
  if (!UUID.test(id) || key.length < 16 || key.length > 128) return json({ ok: false, err: 'bad_request' }, 400);

  const url = Deno.env.get('SUPABASE_URL')!, svc = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const admin = createClient(url, svc, OPTS);

  // Les refus restent INDIFFÉRENCIÉS vers le poste : pas d'oracle sur l'existence d'une demande.
  const { data, error } = await admin.rpc('link_claim_srv', { p_id: id, p_key: key });
  if (error || !data || data.ok !== true || !data.email) return json({ ok: false, err: 'refused' }, 403);

  const gl = await admin.auth.admin.generateLink({ type: 'magiclink', email: data.email });
  const tokenHash = gl.data?.properties?.hashed_token;
  if (gl.error || !tokenHash) return json({ ok: false, err: 'link' }, 502);

  // Un client DISTINCT pour l'échange : après `verifyOtp`, un client porte la session de
  // l'utilisateur — le client d'administration doit garder la clé de service pour la liaison.
  const pub = createClient(url, Deno.env.get('SUPABASE_ANON_KEY') ?? svc, OPTS);
  const v = await pub.auth.verifyOtp({ type: 'magiclink', token_hash: tokenHash });
  const s = v.data?.session;
  if (v.error || !s) return json({ ok: false, err: 'link' }, 502);
  let sid: unknown = null;
  try {
    const p = s.access_token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    sid = JSON.parse(atob(p + '='.repeat((4 - p.length % 4) % 4))).session_id;
  } catch { sid = null; }
  const bd = sid ? await admin.rpc('link_bind_srv', { p_id: id, p_key: key, p_session: sid }) : null;
  if (!bd || bd.error || bd.data?.ok !== true) {
    await admin.auth.admin.signOut(s.access_token, 'local').catch(() => {});
    return json({ ok: false, err: 'refused' }, 403);
  }
  return json({ ok: true, ends_at: data.ends_at, session: {
    access_token: s.access_token, refresh_token: s.refresh_token, expires_at: s.expires_at, user: s.user } });
});
