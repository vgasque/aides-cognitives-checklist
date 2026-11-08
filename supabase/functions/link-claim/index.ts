// link-claim — CONNEXION PAR LE TÉLÉPHONE (v5.111, A643)
//
// LA SEULE PIÈCE DU PROJET QUI TIENT LA CLÉ DE SERVICE. Elle existe parce que GoTrue ne crée pas de
// session depuis SQL : une fois la demande approuvée sur le téléphone, il faut une session NEUVE
// pour le poste — jamais celle du téléphone (son jeton de rafraîchissement tourne à chaque usage :
// deux appareils sur le même se déconnecteraient l'un l'autre, et le poste ne serait plus
// révocable seul).
//
// CE QU'ELLE FAIT, ET RIEN D'AUTRE :
//   1. `link_claim_srv(id, secret)` (SQL, exécutable par la clé de service seule) vérifie le secret
//      et l'approbation, marque la demande réclamée, et rend l'e-mail du compte ;
//   2. `auth.admin.generateLink({type:'magiclink'})` fabrique un lien de connexion À USAGE UNIQUE
//      pour ce compte — sans envoyer d'e-mail ;
//   3. elle rend au poste l'empreinte de ce lien (`token_hash`), que le poste échange aussitôt
//      contre sa session par `/auth/v1/verify`. L'e-mail ne sort jamais de cette fonction.
//
// DÉPLOIEMENT (une fois, puis à chaque modification de ce fichier) :
//     supabase functions deploy link-claim --no-verify-jwt
// `--no-verify-jwt` est NÉCESSAIRE et sans risque : le poste n'a pas encore de compte, et la clé
// publishable n'est pas un JWT. La capacité, c'est le SECRET du QR, vérifié par le SQL.
// Les variables SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont fournies par la plateforme.
import { createClient } from 'npm:@supabase/supabase-js@2.45.4';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { ...CORS, 'content-type': 'application/json' } });

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ ok: false, err: 'method' }, 405);
  let body: { id?: unknown; secret?: unknown };
  try { body = await req.json(); } catch { return json({ ok: false, err: 'bad_request' }, 400); }
  const id = String(body?.id ?? ''), secret = String(body?.secret ?? '');
  if (!/^[0-9a-f-]{36}$/.test(id) || secret.length < 16 || secret.length > 128)
    return json({ ok: false, err: 'bad_request' }, 400);

  const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false, autoRefreshToken: false } });

  // Les refus restent INDIFFÉRENCIÉS vers le poste : pas d'oracle sur l'existence d'une demande.
  const { data, error } = await admin.rpc('link_claim_srv', { p_id: id, p_secret: secret });
  if (error || !data || data.ok !== true || !data.email) return json({ ok: false, err: 'refused' }, 403);

  const gl = await admin.auth.admin.generateLink({ type: 'magiclink', email: data.email });
  const tokenHash = gl.data?.properties?.hashed_token;
  if (gl.error || !tokenHash) return json({ ok: false, err: 'link' }, 502);
  return json({ ok: true, token_hash: tokenHash, ends_at: data.ends_at });
});
