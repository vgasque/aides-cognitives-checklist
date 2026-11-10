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
//   4. elle rend la session au poste, avec de l'utilisateur son identifiant et son adresse — ce que
//      l'app lit, et rien d'autre (A691). Cet en-tête disait « l'e-mail ne sort jamais d'ici » : c'était
//      faux, la réponse portait l'objet utilisateur ENTIER de GoTrue (adresse, identités, métadonnées,
//      dates). L'adresse sort, vers le poste que son titulaire vient d'approuver : il l'affiche (« connecté
//      temporairement — ‹adresse› »), et tout rafraîchissement de jeton la lui rendrait de toute façon.
//
// BORNES (A691) — la fonction est appelable sans compte et tient la clé de service :
//   · une requête à clé FAUSSE ne coûte au serveur qu'une lecture par clé primaire et une empreinte, et
//     n'écrit rien (`link_claim_srv` vérifie la clé avant tout, A679) ;
//   · une clé JUSTE ne réclame que CINQ fois par lien (`device_links.claims`, compté en SQL — la fonction
//     n'a pas d'état, le compteur tient d'une instance à l'autre). Chaque réclamation fait fabriquer une
//     session par GoTrue : c'est ce travail-là qui est borné. Seul le porteur de la clé fait avancer le
//     compteur — personne ne peut bloquer le poste d'un autre ;
//   · le corps est borné à 1 Kio (un identifiant et une clé en tiennent 200 octets).
// CE QUE LA FONCTION NE PEUT PAS BORNER : le nombre d'INVOCATIONS. Une limite par adresse devrait vivre
// à la passerelle de l'hébergeur (réglage du projet), pas ici.
//
// DÉPLOIEMENT (une fois, puis à chaque modification de ce fichier) :
//     supabase functions deploy link-claim --no-verify-jwt
//     supabase secrets set APP_ORIGIN=https://<adresse de l'app>     (OBLIGATOIRE depuis A663)
// SANS `APP_ORIGIN`, LA FONCTION REFUSE (A663, amende A650) : elle répondait alors `*`, c'est-à-dire
// que n'importe quelle page pouvait lire la session rendue — la forme qu'A650 écarte « en production »,
// servie par défaut à qui oubliait le secret. Le refus précède la réclamation : rien n'est consommé.
// PLUSIEURS ADRESSES (A650) : l'app peut être servie sur plus d'une origine (le domaine, et un miroir
// GitHub Pages). `APP_ORIGIN` accepte une LISTE séparée par des virgules — une ORIGINE par entrée,
// schéma + hôte, sans chemin (`https://<compte>.github.io`, pas `…/<dépôt>/`) :
//     supabase secrets set APP_ORIGIN="https://aides.example.fr,https://compte.github.io"
// (`*` n'est plus une entrée : une liste qui n'en contient pas d'autre vaut « absente ».)
// La réponse renvoie l'origine de la requête SI elle figure dans la liste, sinon la première : un
// navigateur sur une autre adresse voit sa réponse bloquée. Ce n'est pas l'autorisation (la clé du
// poste l'est) mais une ceinture : une page tierce ne peut pas lire la session rendue.
// `--no-verify-jwt` est NÉCESSAIRE et sans risque : le poste n'a pas encore de compte, et la clé
// publishable n'est pas un JWT. La capacité, c'est la CLÉ DU POSTE, vérifiée en SQL.
// SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY et SUPABASE_ANON_KEY sont fournies par la plateforme.
import { createClient } from 'npm:@supabase/supabase-js@2.45.4';

const ORIGINS = (Deno.env.get('APP_ORIGIN') ?? '').split(',')
  .map((o) => o.trim().replace(/\/+$/, '')).filter((o) => o && o !== '*');
const corsFor = (req: Request) => {
  const o = req.headers.get('origin') ?? '';
  // A663 : jamais `*`. Sans origine configurée, AUCUN en-tête d'autorisation — le navigateur bloque.
  const allow = ORIGINS.includes(o) ? o : ORIGINS[0];
  return {
    ...(allow ? { 'Access-Control-Allow-Origin': allow } : {}), 'Vary': 'Origin',
    'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
};
const OPTS = { auth: { persistSession: false, autoRefreshToken: false } };
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

Deno.serve(async (req: Request) => {
  const CORS = corsFor(req);
  const json = (o: unknown, status = 200) =>
    new Response(JSON.stringify(o), { status, headers: { ...CORS, 'content-type': 'application/json' } });
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ ok: false, err: 'method' }, 405);
  // A663 — CONFIGURATION INCOMPLÈTE : refus EXPLICITE, avant toute réclamation (elle ne prend qu'une
  // fois : la consommer pour une réponse que le poste ne lira pas le laisserait en impasse).
  //   · `APP_ORIGIN` absent : plus de repli sur `*` (cf. en-tête) ;
  //   · `SUPABASE_ANON_KEY` absente : plus de repli sur la CLÉ DE SERVICE pour l'échange — un client
  //     censé être PUBLIC aurait porté tous les droits, à un `verifyOtp` près.
  const anon = Deno.env.get('SUPABASE_ANON_KEY');
  if (!ORIGINS.length || !anon) {
    console.error('link-claim : configuration incomplète —', !ORIGINS.length ? 'APP_ORIGIN manquant' : 'SUPABASE_ANON_KEY manquante');
    return json({ ok: false, err: 'config' }, 503);
  }
  // A691 : corps borné AVANT lecture complète quand la taille est annoncée, et après dans tous les cas.
  if (Number(req.headers.get('content-length') ?? '0') > 1024) return json({ ok: false, err: 'bad_request' }, 400);
  let body: { id?: unknown; key?: unknown };
  try {
    const raw = await req.text();
    if (raw.length > 1024) return json({ ok: false, err: 'bad_request' }, 400);
    body = JSON.parse(raw);
  } catch { return json({ ok: false, err: 'bad_request' }, 400); }
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
  const pub = createClient(url, anon, OPTS);
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
  // A691 : de l'utilisateur, ce que l'app lit — `id` (l'espace local du compte) et `email` (affichée sur le
  // poste, et signature de ses modifications). Jamais l'objet GoTrue entier.
  return json({ ok: true, ends_at: data.ends_at, session: {
    access_token: s.access_token, refresh_token: s.refresh_token, expires_at: s.expires_at,
    user: { id: s.user?.id ?? null, email: s.user?.email ?? null } } });
});
