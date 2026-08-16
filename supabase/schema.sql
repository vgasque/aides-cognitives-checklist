-- ============================================================================
--  Aides cognitives — schéma cloud (branche 3.0.0)
--  À EXÉCUTER UNE FOIS dans Supabase  >  SQL Editor  >  New query  >  Run.
--
--  Réglages projet attendus (page Security à la création) :
--    • Enable Data API ............. ON
--    • Auto-expose new tables ...... OFF   (on accorde les droits à la main, ci-dessous)
--    • Enable automatic RLS ........ ON    (RLS activée d'office sur chaque table)
--
--  Modèle : espace PERSONNEL (library_id NULL, isolé par owner) + BIBLIOTHÈQUES
--  PARTAGÉES multiples (library_id renseigné). Rôles : viewer / editor / admin.
--  Création de bibliothèque réservée aux app-admins (table app_admins, gérée au
--  dashboard). La sécurité réelle = ces politiques RLS, jamais le client.
-- ============================================================================

-- ---------- 0. RENOMMAGE v5 (lot T9) — À LIRE AVANT DE REJOUER CE FICHIER --------
--
--  `fiches` devient `cognitive_aids`, `fiche_notes` devient `aid_notes`.
--
--  POURQUOI MAINTENANT, ET PAS AVANT. La règle du dépôt interdit de renommer un identifiant
--  existant « sans gain fonctionnel » — et jusqu'ici il n'y en avait aucun : le nom décrivait
--  exactement ce que la table contenait. Le lot T9 réunit aides et protocoles dans UNE
--  bibliothèque où le type n'est plus qu'un filtre ; « fiches » cesse alors de nommer son
--  contenu, et un nom qui ment coûte plus cher qu'un renommage.
--
--  CE BLOC EST IDEMPOTENT ET SANS PERTE : il ne fait quelque chose que si l'ancienne table
--  existe ET que la nouvelle n'existe pas. Sur une instance NEUVE il ne fait rien (les `create
--  table` plus bas créent directement les bons noms) ; sur une instance EN PLACE il RENOMME —
--  donc les données, les index, les contraintes et les politiques suivent, ce qu'un
--  `create table if not exists` sous un nouveau nom N'AURAIT PAS FAIT (il aurait créé une table
--  VIDE à côté, et les données auraient paru disparaître).
--
--  ⚠ ORDRE DE DÉPLOIEMENT — NON NÉGOCIABLE : rejouer CE FICHIER **avant** de publier le client
--  v5. Le client v5 appelle `cognitive_aids` ; contre une instance non migrée, la synchro
--  échoue. Les clients 4.x, eux, continuent de fonctionner grâce à la vue de compatibilité
--  créée en fin de fichier — ils n'ont donc rien à faire, et rien ne casse chez eux.
--
--  LES COLONNES NE SONT PAS RENOMMÉES (`fiche_id` reste `fiche_id`). C'est un arbitrage de
--  rayon d'explosion, pas un oubli : renommer une colonne oblige à reprendre chaque politique,
--  chaque index et chaque appel REST qui la nomme, pour un gain de lisibilité interne nul —
--  personne ne lit ces colonnes hors du SQL et des cinq appels du client.
do $$
begin
  if exists (select 1 from pg_tables where schemaname='public' and tablename='fiches')
     and not exists (select 1 from pg_tables where schemaname='public' and tablename='cognitive_aids')
  then execute 'alter table public.fiches rename to cognitive_aids'; end if;
  if exists (select 1 from pg_tables where schemaname='public' and tablename='fiche_notes')
     and not exists (select 1 from pg_tables where schemaname='public' and tablename='aid_notes')
  then execute 'alter table public.fiche_notes rename to aid_notes'; end if;
end $$;

-- ---------- 1. Tables -------------------------------------------------------

create table if not exists public.app_admins (
  user_id uuid primary key references auth.users on delete cascade
);

create table if not exists public.libraries (
  id         text primary key,
  name       text not null,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.memberships (
  user_id    uuid not null references auth.users on delete cascade,
  library_id text not null references public.libraries on delete cascade,
  role       text not null default 'viewer' check (role in ('viewer','editor','admin')),
  primary key (user_id, library_id)
);

create table if not exists public.cognitive_aids (
  id         text primary key,
  owner      uuid not null default auth.uid(),
  library_id text references public.libraries on delete cascade,   -- NULL = perso
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists fiches_updated_idx on public.cognitive_aids (updated_at);
create index if not exists fiches_library_idx on public.cognitive_aids (library_id);

create table if not exists public.category_sets (
  scope_key  text primary key,                 -- 'personal:<uuid>' | 'lib:<id>'
  owner      uuid,
  library_id text references public.libraries on delete cascade,    -- NULL = perso
  data       jsonb not null,
  updated_at timestamptz not null default now()
);
-- SÉCURITÉ : la clé scope_key DOIT correspondre à l'identité réelle de la ligne (owner pour le perso,
-- library_id pour une bibliothèque). Empêche un éditeur d'une biblio de « squatter » la clé d'une
-- autre biblio (déni de service) en posant un scope_key qui ne lui appartient pas.
do $$ begin
  alter table public.category_sets add constraint category_sets_scope_chk
    check (scope_key = case when library_id is null then 'personal:'||coalesce(owner::text,'')
                            else 'lib:'||library_id end);
exception when duplicate_object then null; end $$;

-- ---------- 2. Helpers SECURITY DEFINER (évitent la récursion RLS) ----------
-- Ces fonctions consultent app_admins / memberships pour l'utilisateur COURANT
-- uniquement (auth.uid()). En SECURITY DEFINER elles contournent la RLS de ces
-- tables sans rien divulguer (aucun paramètre ne permet de lire les droits d'autrui).

create or replace function public.is_app_admin()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from public.app_admins where user_id = auth.uid());
$$;

create or replace function public.is_member(lib text)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from public.memberships
                 where user_id = auth.uid() and library_id = lib);
$$;

create or replace function public.member_role(lib text)
returns text language sql stable security definer set search_path = public, pg_temp as $$
  select role from public.memberships
  where user_id = auth.uid() and library_id = lib;
$$;

-- ---------- 3. RLS (explicite, même si auto-RLS est ON) ---------------------
alter table public.app_admins    enable row level security;
alter table public.libraries     enable row level security;
alter table public.memberships   enable row level security;
alter table public.cognitive_aids        enable row level security;
alter table public.category_sets enable row level security;

-- app_admins : AUCUNE politique + AUCUN grant -> totalement invisible de l'API.

-- « FORCE ROW LEVEL SECURITY » N'EST PAS ACTIVÉ, ET C'EST DÉLIBÉRÉ (v4.44.0).
-- `enable row level security` ci-dessus soumet déjà tous les clients de l'API (rôles
-- `anon` et `authenticated`) aux politiques : c'est ce qui protège les données. `force`
-- ajoute UNE chose de plus : soumettre aussi le PROPRIÉTAIRE des tables aux politiques.
--
-- L'activer par réflexe casserait toute l'administration, et le mécanisme mérite d'être écrit
-- une fois pour toutes : `app_admins` et `app_settings` n'ont VOLONTAIREMENT ni politique ni
-- grant (voir juste au-dessus). Elles ne sont lisibles que par `is_app_admin()` et
-- `is_approved()`, qui sont `security definer` — donc exécutées avec les droits du
-- propriétaire, précisément pour traverser cette invisibilité. Sous `force`, le propriétaire
-- redevient soumis aux politiques ; comme il n'y en a AUCUNE sur ces deux tables, les deux
-- fonctions renverraient systématiquement faux : plus aucun app-admin, donc plus aucune
-- création de bibliothèque ni validation de compte, sur toute l'instance.
--
-- Si `force` devait être adopté un jour, il faudrait D'ABORD donner à ces deux tables des
-- politiques explicites pour le rôle propriétaire — et rejouer `supabase/rls-tests.sql` en
-- entier, la section 13 comprise. Ne pas l'ajouter table par table « pour faire propre ».

-- NB : Postgres n'a pas de « create policy if not exists » -> chaque politique est précédée
-- d'un drop if exists pour que schema.sql soit REJOUABLE en entier sur une instance existante.

-- fiches : perso (owner) OU partagé (lecture = membre, écriture = editor/admin)
drop policy if exists fiches_perso on public.cognitive_aids;
create policy fiches_perso on public.cognitive_aids for all
  using      (library_id is null and owner = auth.uid())
  with check (library_id is null and owner = auth.uid());
drop policy if exists fiches_shared_read on public.cognitive_aids;
create policy fiches_shared_read on public.cognitive_aids for select
  using (library_id is not null and public.is_member(library_id));
drop policy if exists fiches_shared_write on public.cognitive_aids;
create policy fiches_shared_write on public.cognitive_aids for all
  using      (library_id is not null and public.member_role(library_id) in ('editor','admin'))
  with check (library_id is not null and public.member_role(library_id) in ('editor','admin'));

-- category_sets : même logique
drop policy if exists cats_perso on public.category_sets;
create policy cats_perso on public.category_sets for all
  using      (library_id is null and owner = auth.uid())
  with check (library_id is null and owner = auth.uid());
drop policy if exists cats_shared_read on public.category_sets;
create policy cats_shared_read on public.category_sets for select
  using (library_id is not null and public.is_member(library_id));
drop policy if exists cats_shared_write on public.category_sets;
create policy cats_shared_write on public.category_sets for all
  using      (library_id is not null and public.member_role(library_id) in ('editor','admin'))
  with check (library_id is not null and public.member_role(library_id) in ('editor','admin'));

-- libraries : lecture = membre ou app-admin ; création = app-admin uniquement ;
--             renommage = app-admin ou library-admin ; suppression = app-admin
drop policy if exists lib_select on public.libraries;
create policy lib_select on public.libraries for select
  using (public.is_member(id) or public.is_app_admin());
drop policy if exists lib_insert on public.libraries;
create policy lib_insert on public.libraries for insert
  with check (public.is_app_admin());
drop policy if exists lib_update on public.libraries;
create policy lib_update on public.libraries for update
  using      (public.is_app_admin() or public.member_role(id) = 'admin')
  with check (public.is_app_admin() or public.member_role(id) = 'admin');
drop policy if exists lib_delete on public.libraries;
create policy lib_delete on public.libraries for delete
  using (public.is_app_admin());

-- memberships : on voit ses propres lignes (et l'admin voit celles de sa biblio) ;
--               seul un library-admin (ou app-admin) ajoute/retire des membres
drop policy if exists mem_select on public.memberships;
create policy mem_select on public.memberships for select
  using (user_id = auth.uid() or public.member_role(library_id) = 'admin' or public.is_app_admin());
drop policy if exists mem_write on public.memberships;
create policy mem_write on public.memberships for all
  using      (public.member_role(library_id) = 'admin' or public.is_app_admin())
  with check (public.member_role(library_id) = 'admin' or public.is_app_admin());

-- ---------- 4. Trigger : le créateur d'une biblio en devient admin ----------
create or replace function public.lib_add_creator()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  insert into public.memberships(user_id, library_id, role)
  values (new.created_by, new.id, 'admin')
  on conflict do nothing;
  return new;
end;$$;

drop trigger if exists lib_creator_admin on public.libraries;
create trigger lib_creator_admin after insert on public.libraries
  for each row execute function public.lib_add_creator();

-- ---------- 5. GRANTS (auto-expose OFF -> on expose explicitement) ----------
-- Rien pour le rôle anonyme : tout requiert une session.
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.cognitive_aids        to authenticated;
grant select, insert, update, delete on public.category_sets to authenticated;
grant select, insert, update, delete on public.libraries     to authenticated;
grant select, insert, update, delete on public.memberships   to authenticated;
grant execute on function public.is_app_admin()   to authenticated;
grant execute on function public.is_member(text)  to authenticated;
grant execute on function public.member_role(text) to authenticated;
-- public.app_admins : volontairement AUCUN grant.
-- INTERDICTION EXPLICITE POUR anon (et non simple absence de grant). La clé publishable est
-- publiée en clair dans index.html : anon est donc utilisable par n'importe qui contre l'API
-- REST. Ne rien lui ACCORDER ici ne garantit rien si le projet porte des privilèges par défaut
-- hérités de sa création — invisibles depuis ce dépôt. On révoque donc, et on révoque aussi les
-- privilèges FUTURS, pour qu'une table ajoutée plus tard ne soit pas exposée par oubli.
-- (L'app n'a AUCUN flux non authentifié : rien à casser. Vérifié par la section 13 de
--  rls-tests.sql, qui interroge chaque table publique en tant qu'anon.)
revoke all on all tables in schema public from anon;
revoke all on all functions in schema public from anon;
revoke all on schema public from anon;
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on functions from anon;
-- ATTENTION : ces quatre lignes ne suffisent PAS côté FONCTIONS — elles ne retirent rien à
-- PUBLIC, dont anon hérite, et à qui PostgreSQL accorde EXECUTE par défaut. Le correctif est en
-- section 5quater, en FIN de fichier (il doit courir après la dernière définition de fonction).

-- ---------- 5bis. Invitation d'un membre par e-mail (Lot 3) -----------------
-- Recherche un compte par e-mail (table auth.users protégée) et lui attribue un rôle.
-- Réservé à un admin de la bibliothèque (ou app-admin). L'invité doit s'être connecté
-- au moins une fois (compte existant) ; sinon retourne 'not_found'.
-- GARDE D'APPROBATION (3.3.2) : la validation des comptes (user_status/is_approved) n'était
-- jusqu'ici câblée que sur l'espace PERSO -> un compte en attente ou refusé, une fois invité
-- par un admin de bibliothèque, obtenait quand même un accès lecture/écriture immédiat à une
-- bibliothèque partagée (fiches_shared_write ne teste pas l'approbation). On applique donc ici
-- la MÊME règle que is_approved(), évaluée pour l'INVITÉ (et non l'appelant) : logique dupliquée
-- en ligne plutôt qu'un is_approved(uid) paramétré, pour ne PAS créer de fonction qui permettrait
-- à n'importe quel compte de sonder le statut d'approbation d'un autre (cf. commentaire des
-- helpers SECURITY DEFINER ci-dessus : « aucun paramètre ne permet de lire les droits d'autrui »).
create or replace function public.invite_member(p_library text, p_email text, p_role text default 'viewer')
returns text language plpgsql security definer set search_path = public, pg_temp as $$
declare v_uid uuid; v_status text;
begin
  if not (public.member_role(p_library) = 'admin' or public.is_app_admin()) then
    raise exception 'not allowed';
  end if;
  if p_role not in ('viewer','editor','admin') then p_role := 'viewer'; end if;
  -- E-MAIL VÉRIFIÉ EXIGÉ : sans cette condition, on pouvait inviter un compte créé par la simple
  -- DEMANDE d'un code (create_user:true) mais jamais confirmé. Il n'a pas encore de ligne
  -- user_status, la garde d'approbation ci-dessous lit donc NULL et laisse passer ; puis sa
  -- première connexion crée user_status='pending', ce qui déclenche revoke_memberships et EFFACE
  -- l'adhésion tout juste accordée. Le contrat documenté plus haut (« l'invité doit s'être
  -- connecté au moins une fois ») n'était donc pas tenu par le code : il l'est maintenant, et
  -- l'appelant reçoit 'not_found' — le message client doit dire « cette personne doit d'abord se
  -- connecter une fois ».
  select id into v_uid from auth.users
   where lower(email) = lower(trim(p_email)) and email_confirmed_at is not null;
  if v_uid is null then return 'not_found'; end if;
  if not exists(select 1 from public.app_admins where user_id = v_uid) then
    select status into v_status from public.user_status where user_id = v_uid;
    if coalesce(v_status,'approved') <> 'approved'
       and coalesce((select require_approval from public.app_settings limit 1), true) then
      return 'not_approved';
    end if;
  end if;
  insert into public.memberships(user_id, library_id, role) values (v_uid, p_library, p_role)
    on conflict (user_id, library_id) do update set role = excluded.role;
  return 'ok';
end;$$;
grant execute on function public.invite_member(text,text,text) to authenticated;

-- ---------- 5ter. Liste des membres d'une bibliothèque (Lot 3, étape 4) ------
-- Renvoie e-mail + rôle des membres. Réservé aux admins de la bibliothèque (sinon vide) :
-- nécessaire car auth.users n'est pas accessible via l'API publique.
create or replace function public.list_members(p_library text)
returns table(user_id uuid, email text, role text)
language sql security definer set search_path = public, pg_temp as $$
  select m.user_id, u.email::text, m.role
  from public.memberships m join auth.users u on u.id = m.user_id
  where m.library_id = p_library
    and (public.member_role(p_library) = 'admin' or public.is_app_admin())
  order by m.role, u.email;
$$;
grant execute on function public.list_members(text) to authenticated;

-- ---------- 5quater. Durcissement : updated_at non postdatable ---------------
-- Empêche un client de postdater updated_at pour « gagner » indûment un conflit (last-write-wins).
-- On clampe seulement les valeurs dans le futur -> aucune nuisance pour les écritures normales.
create or replace function public.clamp_updated_at()
-- search_path épinglé (v4.44.0) : cette fonction tourne à chaque écriture de fiches et de
-- category_sets. Elle n'est PAS security definer — elle s'exécute avec les droits de l'appelant,
-- donc l'enjeu n'est pas une élévation mais l'indépendance vis-à-vis du search_path du client.
returns trigger language plpgsql set search_path = public, pg_temp as $$
begin if new.updated_at is null or new.updated_at > now() then new.updated_at = now(); end if; return new; end;
$$;
drop trigger if exists fiches_clamp_updated   on public.cognitive_aids;
drop trigger if exists catsets_clamp_updated  on public.category_sets;
create trigger fiches_clamp_updated  before insert or update on public.cognitive_aids        for each row execute function public.clamp_updated_at();
create trigger catsets_clamp_updated before insert or update on public.category_sets for each row execute function public.clamp_updated_at();

-- ---------- 5quinquies. Suppression de son propre compte (RGPD) --------------
-- Efface les DONNÉES PERSONNELLES (fiches + catégories perso) puis le compte lui-même.
-- Les memberships et app_admins partent en cascade avec auth.users. Les fiches que l'utilisateur
-- a ajoutées à des bibliothèques PARTAGÉES y restent (contenu collectif de l'équipe).
-- DÉFENSE EN PROFONDEUR : exige une CONFIRMATION D'IDENTITÉ RÉCENTE — une entrée « amr »
-- (authentication method reference, posée par GoTrue dans le JWT) de type otp/magiclink datant
-- de moins de 10 minutes. Un jeton de session volé ne suffit donc pas, même rafraîchi (le
-- refresh conserve l'amr et son horodatage d'origine) : il faut avoir saisi un code reçu sur
-- la boîte mail du compte juste avant. C'est le pendant serveur du parcours de l'app
-- (SUPPRIMER -> code OTP -> suppression) ; toute anomalie de claim bloque (fail-closed).
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth, pg_temp as $$
declare
  uid    uuid  := auth.uid();
  claims jsonb := coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb;
begin
  if uid is null then raise exception 'not authenticated'; end if;
  if not exists (
    select 1
    from jsonb_array_elements(coalesce(claims->'amr', '[]'::jsonb)) e
    where e->>'method' in ('otp','magiclink')
      and to_timestamp((e->>'timestamp')::numeric) > now() - interval '10 minutes'
  ) then
    raise exception 'recent otp verification required';
  end if;
  -- GARDE-FOU : un super-admin (app_admin) ne peut PAS s'auto-supprimer (gestion via dashboard).
  if exists (select 1 from public.app_admins where user_id = uid) then
    raise exception 'super-admin account cannot be self-deleted';
  end if;
  delete from public.cognitive_aids        where owner = uid and library_id is null;
  delete from public.category_sets where owner = uid and library_id is null;
  delete from auth.users where id = uid;   -- cascade -> memberships, app_admins, sessions…
end; $$;
grant execute on function public.delete_my_account() to authenticated;

-- ---------- 6bis. Validation des comptes par un super-admin (Lot 4) ---------
-- Un compte reste "pending" (créé, e-mail vérifié par code OTP, mais pas encore
-- utilisable dans le cloud) tant qu'un app-admin ne l'a pas approuvé. Tant que
-- pending/rejected, l'espace PERSO n'est PAS synchronisable (RLS ci-dessous) :
-- l'app continue de fonctionner en local (hors-ligne), exactement comme sans compte.
create table if not exists public.user_status (
  user_id    uuid primary key references auth.users on delete cascade,
  email      text not null,
  status     text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references auth.users
);

-- Peuplé automatiquement à chaque création de compte (1ère vérification OTP réussie
-- -> insertion dans auth.users, capturée ici). SECURITY DEFINER : nécessaire pour
-- qu'un trigger sur auth.users (schéma protégé) puisse écrire dans public.
-- Si la validation est DÉSACTIVÉE au moment de l'inscription, la ligne est directement créée
-- "approved" (pas "pending" par défaut) : sinon le compte fonctionne normalement (is_approved()
-- l'autorise déjà via l'interrupteur global) MAIS apparaît quand même, à tort, dans la liste
-- « Comptes en attente » -> confusion pour l'app-admin, et rattrapage rétroactif surprenant si la
-- validation est réactivée plus tard (des comptes déjà pleinement actifs se retrouveraient à valider).
-- GARDE ANTI-SPAM : un compte n'entre dans user_status (donc dans « Comptes en attente »)
-- qu'une fois son e-mail VÉRIFIÉ (code OTP saisi -> email_confirmed_at posé par GoTrue).
-- Demander un code (create_user) crée déjà la ligne auth.users AVANT toute vérification :
-- sans ce garde, n'importe qui pouvait remplir la liste d'attente d'adresses jamais
-- confirmées (pollution + risque qu'un admin approuve une adresse non vérifiée).
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare v_status text := 'pending';
begin
  if new.email_confirmed_at is null then return new; end if;  -- e-mail pas encore vérifié -> rien
  if not coalesce((select require_approval from public.app_settings limit 1), true) then
    v_status := 'approved';
  end if;
  insert into public.user_status(user_id, email, status) values (new.id, new.email, v_status)
    on conflict (user_id) do nothing;
  return new;
end;$$;
drop trigger if exists on_auth_user_created on auth.users;
-- INSERT (comptes créés déjà confirmés, ex. via dashboard) ET UPDATE de email_confirmed_at
-- (parcours normal : création à la demande du code, confirmation à la saisie du code).
create trigger on_auth_user_created after insert or update of email_confirmed_at on auth.users
  for each row execute function public.handle_new_user();

-- Migration : les comptes déjà existants (vous y compris, en tant qu'app-admin actuel) sont
-- approuvés d'office -> aucun risque de vous retrouver bloqué en ré-exécutant ce script.
-- UNIQUEMENT les e-mails vérifiés (sinon le rejeu ressusciterait les inscriptions fantômes).
insert into public.user_status(user_id, email, status, decided_at)
  select id, email, 'approved', now() from auth.users
  where email_confirmed_at is not null
  on conflict (user_id) do nothing;

-- Nettoyage : retire de la liste d'attente les inscriptions jamais vérifiées déjà enregistrées.
delete from public.user_status s
  using auth.users u
  where s.user_id = u.id and u.email_confirmed_at is null and s.status = 'pending';

alter table public.user_status enable row level security;
-- Chacun voit sa PROPRE ligne (pour connaître son statut) ; un app-admin voit tout.
drop policy if exists user_status_select on public.user_status;
create policy user_status_select on public.user_status for select
  using (user_id = auth.uid() or public.is_app_admin());
-- Seul un app-admin peut changer le statut de quelqu'un (approuver/refuser).
drop policy if exists user_status_write on public.user_status;
create policy user_status_write on public.user_status for update
  using (public.is_app_admin())
  with check (public.is_app_admin());
grant select, update on public.user_status to authenticated;

-- Interrupteur global (app-admin) : permet d'activer l'exigence de validation des nouveaux comptes.
-- DÉSACTIVÉ PAR DÉFAUT : sur une instance fraîche, app_admins est encore vide (on ne peut s'y
-- nommer admin qu'APRÈS s'être connecté une 1ère fois, cf. instructions finales) -> si la validation
-- était active d'office, ce tout premier compte se retrouverait bloqué "en attente" dès sa première
-- connexion. Une fois devenu app-admin, activez la validation quand vous le souhaitez (fenêtre
-- Compte -> « Comptes en attente ») pour les comptes suivants.
-- Ligne UNIQUE (id toujours = true) ; accès UNIQUEMENT via les fonctions ci-dessous (comme
-- app_admins : aucune politique ni grant sur la table elle-même -> invisible de l'API directe).
create table if not exists public.app_settings (
  id               boolean primary key default true check (id),
  require_approval boolean not null default false
);
insert into public.app_settings(id, require_approval) values (true, false) on conflict (id) do nothing;
alter table public.app_settings enable row level security;

-- is_approved() : un app-admin est TOUJOURS considéré approuvé (garde-fou anti-blocage,
-- même s'il a été promu admin après coup sans que sa ligne user_status ait été mise à jour).
-- Si la validation est désactivée globalement (require_approval = false), tout le monde passe.
-- ALIGNÉ SUR my_status() : un compte SANS ligne user_status (antérieur à la fonctionnalité,
-- migration incomplète...) est réputé APPROUVÉ, comme le rapporte my_status(). L'ancien
-- `exists(... status='approved')` le refusait : l'app affichait alors « Connecté » (my_status)
-- pendant que TOUTES les écritures étaient rejetées en 403 — panne de synchro inexplicable.
-- ELLE RENVOYAIT **TRUE POUR anon** (correctif) — et c'était le plus insidieux des deux défauts
-- de cette famille, parce qu'il a l'air solide. Sous le rôle anon, `auth.uid()` vaut NULL : la
-- sous-requête sur user_status ne ramène rien, le `coalesce` retombe sur 'approved', et la
-- troisième branche est VRAIE. Sur une instance neuve, `require_approval` valant false par
-- défaut, la DEUXIÈME branche suffisait déjà à elle seule. Le laxisme délibéré « pas de ligne
-- user_status = approuvé » (documenté ci-dessus, et qui reste INTACT) s'appliquait donc à
-- l'absence de compte tout court.
-- Aujourd'hui c'est sans conséquence : les politiques qui l'appellent exigent TOUTES en plus
-- `owner = auth.uid()` ou `user_id = auth.uid()`, qui est faux pour anon. C'est donc un correctif
-- de PRINCIPE : le jour où quelqu'un écrit un garde-fou en s'appuyant sur `is_approved()` seule,
-- il doit tenir. RÈGLE ÉCRITE : un gate anon s'écrit `auth.uid() is not null`, jamais
-- `is_approved()`. Aucun changement pour un compte connecté — `auth.uid()` y est toujours non nul.
-- UN JWT ANONYME N'EST PAS UN COMPTE APPROUVÉ (v4.49.0). Supabase peut émettre des jetons pour des
-- utilisateurs ANONYMES (`is_anonymous` dans le JWT) si l'option est activée au tableau de bord.
-- Un tel jeton porte un `auth.uid()` non nul et n'a AUCUNE ligne dans `user_status` : le `coalesce`
-- ci-dessous retombait donc sur 'approved' et le traitait comme un compte en règle — y compris pour
-- ouvrir un partage, c'est-à-dire faire sortir du contenu clinique de l'instance. La porte était
-- fermée uniquement parce que personne n'avait coché la case ; elle est maintenant fermée par le
-- schéma. Décision volontaire et documentée : le projet n'utilise PAS les connexions anonymes
-- (lignes dans auth.users, pollution de la liste d'attente, comptage MAU) — cf. le choix du
-- transport par sondage, motivé au §8.
create or replace function public.is_approved()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select auth.uid() is not null
    and not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
    and (public.is_app_admin()
      or not coalesce((select require_approval from public.app_settings limit 1), true)
      or coalesce((select status from public.user_status where user_id = auth.uid()), 'approved') = 'approved');
$$;
grant execute on function public.is_approved() to authenticated;

-- Gate : l'espace PERSO (fiches + catégories) requiert l'approbation. Les bibliothèques
-- partagées sont inchangées (déjà protégées par memberships, qu'un compte pending n'obtient
-- pas — cf. invite_member — et qu'un compte rejeté PERD — cf. user_status_revoke_memberships).
drop policy if exists fiches_perso on public.cognitive_aids;
create policy fiches_perso on public.cognitive_aids for all
  using      (library_id is null and owner = auth.uid() and public.is_approved())
  with check (library_id is null and owner = auth.uid() and public.is_approved());
drop policy if exists cats_perso on public.category_sets;
create policy cats_perso on public.category_sets for all
  using      (library_id is null and owner = auth.uid() and public.is_approved())
  with check (library_id is null and owner = auth.uid() and public.is_approved());

-- ---------- 6ter. Notes personnelles par fiche --------------------------------
-- (Après is_approved(), que la politique référence.)
-- Une note PRIVÉE par (utilisateur, fiche) : annotation perso sur une fiche (perso OU partagée),
-- synchronisée entre les appareils du même compte, JAMAIS visible des autres membres. Modifier la
-- fiche ne touche pas aux notes (stockage séparé). Pas de FK vers fiches : la fiche peut être un
-- tombstone ou une fiche locale jamais synchronisée ; les orphelines sont minuscules et ignorées.
create table if not exists public.aid_notes (
  user_id    uuid not null references auth.users on delete cascade,
  fiche_id   text not null,
  note       text not null default '',
  updated_at timestamptz not null default now(),
  primary key (user_id, fiche_id)
);
alter table public.aid_notes enable row level security;
drop policy if exists notes_own on public.aid_notes;
create policy notes_own on public.aid_notes for all
  using      (user_id = auth.uid() and public.is_approved())
  with check (user_id = auth.uid() and public.is_approved());
grant select, insert, update, delete on public.aid_notes to authenticated;
-- Même anti-postdatage que fiches/category_sets (last-write-wins non trichable).
drop trigger if exists notes_clamp_updated on public.aid_notes;
create trigger notes_clamp_updated before insert or update on public.aid_notes
  for each row execute function public.clamp_updated_at();

-- Statut du compte courant (le client l'appelle juste après la vérification OTP, puis à chaque
-- synchro) : reflète EXACTEMENT is_approved() (si la validation est désactivée globalement, ou si
-- aucune ligne n'existe -> 'approved', pour ne jamais afficher "en attente" à quelqu'un dont la
-- synchro fonctionne déjà réellement).
-- Même correctif que is_approved() (dont elle doit rester le REFLET EXACT) : sans compte, elle
-- répondait 'approved'. Elle renvoie désormais NULL — exactement ce que le client stocke déjà
-- lui-même quand il n'est pas connecté (`refreshAccountStatus` : `myAccountStatus=null`), donc
-- aucun changement de comportement côté app.
create or replace function public.my_status()
returns text language sql stable security definer set search_path = public, pg_temp as $$
  select case
    when auth.uid() is null then null
    -- Même raison qu'`is_approved` : un jeton anonyme n'est pas un compte, et l'interface ne doit
    -- pas lui annoncer « approuvé » — ce serait la seule chose que l'utilisateur verrait.
    when coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) then 'rejected'
    when public.is_app_admin() then 'approved'
    when not coalesce((select require_approval from public.app_settings limit 1), true) then 'approved'
    else coalesce((select status from public.user_status where user_id = auth.uid()), 'approved')
  end;
$$;
grant execute on function public.my_status() to authenticated;

-- Lecture/écriture de l'interrupteur (écran « Comptes en attente »). Lecture ouverte à tout
-- utilisateur connecté (ne révèle rien de sensible) ; écriture réservée à l'app-admin.
create or replace function public.get_approval_required()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select coalesce((select require_approval from public.app_settings limit 1), true);
$$;
grant execute on function public.get_approval_required() to authenticated;

create or replace function public.set_approval_required(p_value boolean)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not public.is_app_admin() then raise exception 'not allowed'; end if;
  update public.app_settings set require_approval = p_value where id = true;
end;$$;
grant execute on function public.set_approval_required(boolean) to authenticated;

-- Comptes pending/rejected (app-admin uniquement ; vide sinon) -> écran « Comptes en attente ».
create or replace function public.list_unapproved_users()
returns table(user_id uuid, email text, status text, created_at timestamptz)
language sql security definer set search_path = public, pg_temp as $$
  select s.user_id, s.email, s.status, s.created_at from public.user_status s
  where s.status in ('pending','rejected') and public.is_app_admin()
  order by s.created_at;
$$;
grant execute on function public.list_unapproved_users() to authenticated;

-- Approuver / refuser (app-admin uniquement). Un app-admin ne peut pas être rétrogradé
-- par erreur (protège contre un clic malheureux sur son propre compte).
-- NB : la révocation des accès PARTAGÉS d'un compte qui quitte 'approved' n'est pas faite
-- ici mais par le trigger user_status_revoke_memberships (ci-dessous) : il se déclenche sur
-- l'UPDATE exécuté par cette fonction, mais AUSSI sur un UPDATE direct de user_status
-- (app-admin via l'API REST, politique user_status_write) ou une édition au dashboard.
create or replace function public.set_user_status(p_user uuid, p_status text)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not public.is_app_admin() then raise exception 'not allowed'; end if;
  if p_status not in ('pending','approved','rejected') then raise exception 'invalid status'; end if;
  if p_status <> 'approved' and exists(select 1 from public.app_admins where user_id = p_user) then
    raise exception 'cannot demote an app-admin';
  end if;
  update public.user_status set status = p_status, decided_at = now(), decided_by = auth.uid()
    where user_id = p_user;
end;$$;
grant execute on function public.set_user_status(uuid, text) to authenticated;

-- RÉVOCATION DES ACCÈS PARTAGÉS (audit de sécurité). La garde d'approbation n'est appliquée
-- qu'à l'ENTRÉE d'une bibliothèque (invite_member, § 5bis) : les politiques *_shared_* des
-- fiches, protocoles, category_sets et du bucket attachments ne re-testent PAS is_approved()
-- à chaque requête — elles ne testent que le membership. Sans purge, un compte APPROUVÉ PUIS
-- REJETÉ conservait donc, via l'API REST, la lecture ET l'écriture de toutes ses bibliothèques
-- partagées. On supprime ici toutes ses lignes de memberships dès que son statut quitte
-- 'approved', quel que soit le chemin d'écriture (RPC set_user_status ci-dessus, UPDATE direct
-- de user_status par un app-admin, édition au dashboard). Le trigger couvre aussi l'INSERT
-- (ligne recréée directement en pending/rejected : purge par cohérence, normalement sans effet).
-- EFFET DE BORD ASSUMÉ : si le compte est RÉ-approuvé plus tard, ses memberships ne sont PAS
-- restaurés — il devra être ré-invité (invite_member) dans chacune de ses bibliothèques. C'est
-- voulu : la ré-approbation repasse par le circuit nominal, qui re-vérifie l'approbation.
-- SECURITY DEFINER : la purge doit aboutir quel que soit le rôle qui a modifié le statut
-- (défense en profondeur, indépendante des politiques RLS de memberships).
create or replace function public.revoke_memberships()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  delete from public.memberships where user_id = new.user_id;
  return new;
end;$$;
drop trigger if exists user_status_revoke_memberships on public.user_status;
-- MAINTENU SUR « insert or update » À DESSEIN : le restreindre à UPDATE ouvrirait un trou (une
-- ligne 'rejected' insérée directement ne révoquerait plus rien). Le scénario fautif qu'il
-- provoquait — purger l'adhésion d'un invité à sa première connexion — est fermé À LA SOURCE par
-- la condition email_confirmed_at d'invite_member : un compte non confirmé ne peut plus être
-- invité, il n'y a donc plus d'adhésion à effacer quand handle_new_user crée sa ligne 'pending'.
create trigger user_status_revoke_memberships
  after insert or update of status on public.user_status
  for each row when (new.status <> 'approved')
  execute function public.revoke_memberships();

-- Supprime DÉFINITIVEMENT un compte REFUSÉ (app-admin uniquement) : donne une "2e chance" à la
-- personne, qui pourra recréer un compte avec la même adresse e-mail (nouvelle demande, repartant
-- de "pending" via le trigger on_auth_user_created). Restreint volontairement aux comptes rejected
-- (pas pending/approved) -> pas d'usage détourné pour supprimer n'importe quel compte via cette RPC.
create or replace function public.delete_rejected_user(p_user uuid)
returns void language plpgsql security definer set search_path = public, auth, pg_temp as $$
begin
  if not public.is_app_admin() then raise exception 'not allowed'; end if;
  if not exists(select 1 from public.user_status where user_id = p_user and status = 'rejected') then
    raise exception 'user is not in rejected status';
  end if;
  delete from auth.users where id = p_user;   -- cascade -> user_status, memberships
end;$$;
grant execute on function public.delete_rejected_user(uuid) to authenticated;

-- ---------- 6ter. Garde-fou : taille maximale d'une ligne (anti-abus stockage) --------------
-- Les plafonds de taille CÔTÉ CLIENT (images redimensionnées par downscale(), nombre de blocs/
-- images limité...) ne sont que des garde-fous d'ergonomie : un appel REST direct (contournant
-- l'app, cf. revue de sécurité) pourrait les ignorer et pousser une ligne démesurée. Impact
-- PARTAGÉ pour une bibliothèque (quota de stockage du projet, donc de toute l'équipe). On mesure
-- la taille OCTET de la représentation JSON (simple et prévisible, indépendant des détails de
-- compression TOAST de Postgres).
--   fiches.data (20 Mo) : une fiche réelle contient au plus quelques dizaines d'images, chacune
--     réduite par downscale() à ~100-300 Ko en base64 -> large marge même pour une fiche très
--     riche en schémas/captures.
--   category_sets.data (1 Mo) : aucune image, seulement des tuples {id,name,color,libraryId}
--     plafonnés à 400 entrées -> quelques Ko en usage réel, marge x10 largement suffisante.
do $$ begin
  alter table public.cognitive_aids add constraint fiches_data_size_chk
    check (octet_length(data::text) <= 20*1024*1024);
exception when duplicate_object then null; end $$;
do $$ begin
  alter table public.category_sets add constraint catsets_data_size_chk
    check (octet_length(data::text) <= 1024*1024);
exception when duplicate_object then null; end $$;

-- ---------- 6quater. État de l'instance (app-admin) : tableau de bord léger ------------------
-- Compteurs agrégés pour l'écran « Comptes en attente » : nombre de comptes, en attente, refusés,
-- bibliothèques, fiches perso/partagées vivantes, et octets de stockage consommés (data des fiches
-- + des jeux de catégories). Réservé aux app-admins (renvoie NULL sinon). SECURITY DEFINER car il
-- agrège des tables/comptes que l'appelant ne peut pas lire ligne à ligne.
create or replace function public.get_instance_stats()
returns jsonb language sql stable security definer set search_path = public, auth, pg_temp as $$
  select case when not public.is_app_admin() then null else jsonb_build_object(
    'users',        (select count(*) from auth.users),
    'pending',      (select count(*) from public.user_status where status = 'pending'),
    'rejected',     (select count(*) from public.user_status where status = 'rejected'),
    'libraries',    (select count(*) from public.libraries),
    'fiches_perso', (select count(*) from public.cognitive_aids where library_id is null and deleted_at is null),
    'fiches_shared',(select count(*) from public.cognitive_aids where library_id is not null and deleted_at is null),
    'storage_bytes',(select coalesce(sum(octet_length(data::text)),0) from public.cognitive_aids where deleted_at is null)
                    + (select coalesce(sum(octet_length(data::text)),0) from public.category_sets),
    -- Octets du bucket de documents PDF (métadonnées storage ; 0 si le bucket n'existe pas encore).
    'attachments_bytes',(select coalesce(sum((o.metadata->>'size')::bigint),0)
                         from storage.objects o where o.bucket_id = 'attachments')
  ) end;
$$;
grant execute on function public.get_instance_stats() to authenticated;

-- ---------- 6quinquies. Protocoles (4.0.0) : clone de `fiches` -------------------------------
-- Section « Protocoles » de l'app : documents de service (PDF joints) et/ou contenu rédigé
-- (mini-Markdown), rangés comme les fiches (perso par owner, ou bibliothèque partagée).
-- MÊME modèle de sécurité que `fiches` : politiques identiques, trigger anti-postdatage,
-- plafond de taille de ligne. Le contenu voyage entier en jsonb (colonne data).
create table if not exists public.protocols (
  id         text primary key,
  owner      uuid not null default auth.uid(),
  library_id text references public.libraries on delete cascade,   -- NULL = perso
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists protocols_updated_idx on public.protocols (updated_at);
create index if not exists protocols_library_idx on public.protocols (library_id);
alter table public.protocols enable row level security;

drop policy if exists prot_perso on public.protocols;
create policy prot_perso on public.protocols for all
  using      (library_id is null and owner = auth.uid() and public.is_approved())
  with check (library_id is null and owner = auth.uid() and public.is_approved());
drop policy if exists prot_shared_read on public.protocols;
create policy prot_shared_read on public.protocols for select
  using (library_id is not null and public.is_member(library_id));
drop policy if exists prot_shared_write on public.protocols;
create policy prot_shared_write on public.protocols for all
  using      (library_id is not null and public.member_role(library_id) in ('editor','admin'))
  with check (library_id is not null and public.member_role(library_id) in ('editor','admin'));

drop trigger if exists protocols_clamp_updated on public.protocols;
create trigger protocols_clamp_updated before insert or update on public.protocols
  for each row execute function public.clamp_updated_at();

do $$ begin
  alter table public.protocols add constraint protocols_data_size_chk
    check (octet_length(data::text) <= 20*1024*1024);
exception when duplicate_object then null; end $$;

grant select, insert, update, delete on public.protocols to authenticated;

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- HISTORIQUE DE SESSIONS SYNCHRONISÉ (v4.54.0) — ET L'INVARIANT QU'IL LÈVE
--
-- Jusqu'ici, « les sessions vivent en IndexedDB local, jamais synchro » était une propriété écrite
-- de l'application, et le mode EXERCICE en DÉRIVAIT sa garantie de non-contamination clinique.
-- Cette table lève l'invariant — sur OPT-IN, défaut fermé — et il faut donc redire ce qui le
-- remplace :
--   · SEULES LES SESSIONS ARCHIVÉES montent (`live:false`). Une session VIVE resynchronisée serait
--     un second mécanisme de partage, avec tous les risques du premier et aucun de ses garde-fous.
--   · LES EXERCICES SONT SÉGRÉGÉS PAR UNE COLONNE, pas par une convention de contenu. La propriété
--     « zéro contamination clinique » ne doit plus dépendre de la localité : elle devient une
--     colonne qu'on peut filtrer, et que le serveur voit.
--   · `verified`/`vgaps` (la trace do-verify) NE MONTENT PAS pour l'instant — décision d'étape, pas
--     de principe : le compte rendu distant porte alors la mention explicite « trace de
--     vérification disponible sur l'appareil d'origine », jamais un silence.
--   · `data` accueille SOIT un objet en clair, SOIT `{v:2, enc:<blob>}`. Passer au chiffrement de
--     bout en bout plus tard ne demandera donc AUCUNE migration : c'est la seule décision de forme
--     qu'il fallait prendre maintenant, parce qu'elle est irréversible une fois des données en
--     place.
-- Une session n'est PAS un contenu d'équipe : pas de `library_id`, pas de partage, une seule
-- politique. C'est le dossier de ce que CETTE personne a fait, et il ne se prête pas.
create table if not exists public.sessions (
  id         text primary key,
  owner      uuid not null default auth.uid(),
  data       jsonb not null,
  exercise   boolean not null default false,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists sessions_updated_idx on public.sessions (updated_at);
create index if not exists sessions_owner_idx   on public.sessions (owner, updated_at);
alter table public.sessions enable row level security;

drop policy if exists sessions_own on public.sessions;
create policy sessions_own on public.sessions for all
  using      (owner = auth.uid() and public.is_approved())
  with check (owner = auth.uid() and public.is_approved());

drop trigger if exists sessions_clamp_updated on public.sessions;
create trigger sessions_clamp_updated before insert or update on public.sessions
  for each row execute function public.clamp_updated_at();

do $$ begin
  -- 1 Mio : un compte rendu est du texte et des horodatages. Le plafond vaut CONTRE LE CLIENT (un
  -- appel REST direct ignore toute borne écrite en JavaScript) et contre le remplissage d'un quota
  -- PARTAGÉ avec les fiches, dont dépend le fonctionnement clinique.
  alter table public.sessions add constraint sessions_data_size_chk
    check (octet_length(data::text) <= 1024*1024);
exception when duplicate_object then null; end $$;

grant select, insert, update, delete on public.sessions to authenticated;

-- La suppression de compte (RGPD) emporte aussi les protocoles perso.
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth, pg_temp as $$
declare
  uid    uuid  := auth.uid();
  claims jsonb := coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb;
begin
  if uid is null then raise exception 'not authenticated'; end if;
  if not exists (
    select 1
    from jsonb_array_elements(coalesce(claims->'amr', '[]'::jsonb)) e
    where e->>'method' in ('otp','magiclink')
      and to_timestamp((e->>'timestamp')::numeric) > now() - interval '10 minutes'
  ) then
    raise exception 'recent otp verification required';
  end if;
  if exists (select 1 from public.app_admins where user_id = uid) then
    raise exception 'super-admin account cannot be self-deleted';
  end if;
  delete from public.cognitive_aids        where owner = uid and library_id is null;
  delete from public.protocols     where owner = uid and library_id is null;
  delete from public.category_sets where owner = uid and library_id is null;
  -- PARTAGES DE SESSION — suppression EXPLICITE, et non « par cascade ». Deux raisons, chacune
  -- suffisante : (1) `session_participants.user_id` référence `auth.users`, donc sans cette ligne
  -- la cascade partirait de l'utilisateur et pourrait laisser des partages orphelins dont
  -- l'`owner` n'existe plus ; (2) surtout, une contrainte non satisfaite lèverait ici une
  -- `foreign_key_violation` — et comme tout ce corps plpgsql est UNE SEULE transaction, la
  -- fonction entière serait annulée : le droit à l'effacement disparaîtrait purement et
  -- simplement pour quiconque a partagé une session ne serait-ce qu'une fois. Le commentaire de
  -- la ligne `delete from auth.users` affirme déjà une cascade ; c'est exactement ce genre
  -- d'affirmation non vérifiée que le projet a payé cher en v4.44.1.
  delete from public.shared_sessions where owner = uid;   -- cascade -> participants, events
  -- L'historique synchronisé s'efface avec le compte. Explicitement, et AVANT la suppression de la
  -- ligne `auth.users` : sans cela, soit les lignes survivent au compte, soit la violation de clé
  -- étrangère annule TOUTE la fonction plpgsql — et le droit à l'effacement disparaît pour
  -- quiconque a synchronisé une seule session.
  delete from public.sessions where owner = uid;
  -- Documents PDF perso du bucket : rendus inaccessibles par la RLS dès la suppression du compte ;
  -- leurs objets orphelins remontent dans list_orphan_attachments() (purge manuelle app-admin).
  delete from auth.users where id = uid;   -- cascade -> memberships, app_admins, sessions…
end; $$;

-- État de l'instance : RE-CRÉÉE ici (après la table protocols, qu'une fonction SQL ne peut
-- référencer avant sa création) avec les compteurs de protocoles et le poids du bucket.
create or replace function public.get_instance_stats()
returns jsonb language sql stable security definer set search_path = public, auth, pg_temp as $$
  select case when not public.is_app_admin() then null else jsonb_build_object(
    'users',        (select count(*) from auth.users),
    'pending',      (select count(*) from public.user_status where status = 'pending'),
    'rejected',     (select count(*) from public.user_status where status = 'rejected'),
    'libraries',    (select count(*) from public.libraries),
    'fiches_perso', (select count(*) from public.cognitive_aids where library_id is null and deleted_at is null),
    'fiches_shared',(select count(*) from public.cognitive_aids where library_id is not null and deleted_at is null),
    'protocols',    (select count(*) from public.protocols where deleted_at is null),
    'sessions',     (select count(*) from public.sessions where deleted_at is null),
    'storage_bytes',(select coalesce(sum(octet_length(data::text)),0) from public.cognitive_aids where deleted_at is null)
                    + (select coalesce(sum(octet_length(data::text)),0) from public.category_sets)
                    + (select coalesce(sum(octet_length(data::text)),0) from public.protocols where deleted_at is null)
                    -- Historique synchronisé : un poste qui croît avec l'usage, et qu'un exploitant
                    -- aveugle ne pourrait pas anticiper (leçon v4.49.0, où le serveur comptait les
                    -- octets du partage sans que l'écran ne les montre).
                    + (select coalesce(sum(octet_length(data::text)),0) from public.sessions where deleted_at is null),
    'attachments_bytes',(select coalesce(sum((o.metadata->>'size')::bigint),0)
                         from storage.objects o where o.bucket_id = 'attachments')
  ) end;
$$;

-- ---------- 6sexies. Durcissement : updatedBy signé par le serveur (audit de sécurité) ------
-- Le client pose data->>'updatedBy' (e-mail du dernier modificateur, affiché « dernière
-- modification par… » dans les bibliothèques partagées) mais c'était une valeur DÉCLARATIVE :
-- une requête REST directe pouvait y mettre n'importe quoi — un editor pouvait signer une
-- modification du nom d'un collègue. Ce trigger écrase la valeur déclarée par l'e-mail RÉEL
-- du JWT, sur fiches ET protocols (les deux seules tables dont le jsonb `data` porte ce champ ;
-- category_sets et fiche_notes ne le portent pas).
--   • Sans JWT ou sans claim email (service_role, SQL Editor, opérations d'administration) :
--     on ne touche à RIEN — ces écritures ne sont pas des usurpations, et les écraser
--     casserait les interventions de maintenance.
--   • Champ ABSENT du payload : il le RESTE (on n'ajoute rien). Côté client, migrate() /
--     migrateProtocol() tolèrent l'absence mais attendent une chaîne : le champ reste donc
--     toujours une chaîne e-mail ou absent, jamais un null JSON.
create or replace function public.stamp_updated_by()
-- search_path épinglé (v4.44.0), même raison que clamp_updated_at ci-dessus.
returns trigger language plpgsql set search_path = public, pg_temp as $$
declare
  claims  jsonb := coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb;
  v_email text  := claims->>'email';
begin
  if v_email is null or v_email = '' then return new; end if;   -- pas de JWT -> ne rien écraser
  if new.data ? 'updatedBy' then
    new.data = jsonb_set(new.data, '{updatedBy}', to_jsonb(v_email));
  end if;
  return new;
end;$$;
drop trigger if exists fiches_stamp_updated_by    on public.cognitive_aids;
drop trigger if exists protocols_stamp_updated_by on public.protocols;
create trigger fiches_stamp_updated_by    before insert or update on public.cognitive_aids    for each row execute function public.stamp_updated_by();
create trigger protocols_stamp_updated_by before insert or update on public.protocols for each row execute function public.stamp_updated_by();

-- ---------- 7. Documents PDF joints : bucket Storage 'attachments' (4.0.0) ------------------
-- Les fiches ne transportent que des MÉTADONNÉES ({id,name,size} dans data.attachments) ; le
-- fichier PDF lui-même vit dans ce bucket PRIVÉ. LE CHEMIN ENCODE LE PÉRIMÈTRE DE SÉCURITÉ :
--   u/<owner_uid>/<attId>.pdf   -> document personnel (accès : propriétaire seul)
--   l/<library_id>/<attId>.pdf  -> document d'une bibliothèque partagée (accès : membres)
-- Les politiques RLS sur storage.objects réutilisent les helpers existants (is_approved,
-- is_member, member_role). On ne s'appuie JAMAIS sur storage.objects.owner : comme pour
-- fiches_shared_write, un éditeur doit pouvoir remplacer/supprimer le document d'un collègue
-- dans SA bibliothèque. Aucune politique pour anon -> aucun accès sans session.
-- Plafonds APPLIQUÉS PAR LE SERVEUR (indépendamment du client) : 15 Mo/fichier, PDF uniquement.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('attachments', 'attachments', false, 15728640, array['application/pdf'])
  on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Perso : propriétaire approuvé uniquement, chemin strictement conforme (uuid = auth.uid()).
-- USING = WITH CHECK -> lecture, upload (INSERT), remplacement (UPDATE, x-upsert) et suppression.
drop policy if exists att_perso on storage.objects;
create policy att_perso on storage.objects for all
  using      (bucket_id = 'attachments' and public.is_approved()
              and (storage.foldername(name))[1] = 'u'
              and (storage.foldername(name))[2] = auth.uid()::text
              and name ~ '^u/[0-9a-f-]{36}/[A-Za-z0-9_-]{1,64}\.pdf$')
  with check (bucket_id = 'attachments' and public.is_approved()
              and (storage.foldername(name))[1] = 'u'
              and (storage.foldername(name))[2] = auth.uid()::text
              and name ~ '^u/[0-9a-f-]{36}/[A-Za-z0-9_-]{1,64}\.pdf$');

-- Bibliothèque partagée : lecture = tout membre (comme fiches_shared_read).
drop policy if exists att_lib_read on storage.objects;
create policy att_lib_read on storage.objects for select
  using (bucket_id = 'attachments'
         and (storage.foldername(name))[1] = 'l'
         and public.is_member((storage.foldername(name))[2]));

-- Bibliothèque partagée : écriture (upload/remplacement/suppression) = editor/admin, chemin
-- strictement conforme (comme fiches_shared_write ; l'approbation n'est pas re-testée ici, même
-- logique que fiches : un compte non approuvé n'obtient pas de membership, cf. invite_member,
-- et un compte qui cesse d'être approuvé les perd tous, cf. user_status_revoke_memberships).
drop policy if exists att_lib_write on storage.objects;
create policy att_lib_write on storage.objects for all
  using      (bucket_id = 'attachments'
              and (storage.foldername(name))[1] = 'l'
              and public.member_role((storage.foldername(name))[2]) in ('editor','admin')
              and name ~ '^l/[A-Za-z0-9_-]{1,64}/[A-Za-z0-9_-]{1,64}\.pdf$')
  with check (bucket_id = 'attachments'
              and (storage.foldername(name))[1] = 'l'
              and public.member_role((storage.foldername(name))[2]) in ('editor','admin')
              and name ~ '^l/[A-Za-z0-9_-]{1,64}/[A-Za-z0-9_-]{1,64}\.pdf$');

-- Orphelins du bucket (app-admin) : objets dont l'id de fichier n'apparaît plus dans les
-- métadonnées d'AUCUNE fiche vivante. Cas rare (interruption entre un upload et l'enregistrement
-- de la fiche ; la file de suppression côté client couvre les flux normaux). La fonction LISTE
-- seulement (SECURITY DEFINER, app-admin) : la suppression effective reste MANUELLE, via le
-- dashboard Storage ou l'API — jamais de destruction automatique côté serveur.
create or replace function public.list_orphan_attachments()
returns table(name text, size_bytes bigint, created_at timestamptz)
language sql stable security definer set search_path = public, storage, pg_temp as $$
  select o.name, coalesce((o.metadata->>'size')::bigint, 0), o.created_at
  from storage.objects o
  where o.bucket_id = 'attachments'
    and public.is_app_admin()
    and substring(o.name from '([A-Za-z0-9_-]{1,64})\.pdf$') not in (
      select a->>'id'
      from public.cognitive_aids f, jsonb_array_elements(coalesce(f.data->'attachments','[]'::jsonb)) a
      where f.deleted_at is null
      union
      select a->>'id'
      from public.protocols p, jsonb_array_elements(coalesce(p.data->'attachments','[]'::jsonb)) a
      where p.deleted_at is null)
  order by o.created_at;
$$;
grant execute on function public.list_orphan_attachments() to authenticated;

-- ============================================================================================
-- ---------- 8. PARTAGE DE SESSION EN DIRECT --------------------------------------------------
-- ============================================================================================
-- Une session de crise (checklist en cours : cases cochées, minuteurs, compteurs, repères
-- horodatés) devient consultable et remplissable par un SECOND appareil, dont le porteur peut
-- n'avoir AUCUN compte. L'asymétrie est délibérée et il faut la lire dans ce sens : REJOINDRE ne
-- demande rien, OUVRIR un partage exige un compte approuvé (cf. share_open). La formule
-- symétrique qui figurait ici — « avec ou sans compte » — ne nommait aucun rôle et se lisait dans
-- les deux sens ; elle a effectivement conduit à poser la question.
--
-- CE QUE CETTE SECTION N'EST PAS. Ce n'est pas un partage d'AIDE COGNITIVE — les bibliothèques
-- partagées font déjà cela, avec memberships et RLS. Ici la portée est UNE session, elle meurt
-- avec elle, et l'invité ne conserve rien. `auth.uid()` ne sert donc QU'À L'ATTRIBUTION (nommer
-- un participant qui a un compte), JAMAIS à l'accès : l'accès vient toujours du secret de
-- participant. Il n'existe qu'un seul chemin d'accès à auditer.
--
-- RELAIS, PAS ENTREPÔT. Le serveur relaie et purge ; la trace durable reste locale, sur chaque
-- appareil, comme elle l'a toujours été. C'est ce qui permet d'écrire au registre RGPD « relais
-- transitoire, sans conservation » — et ce qui rend sans objet la question de l'hébergement
-- certifié HDS, qui ne s'était jamais posée tant que rien ne sortait de l'appareil.
--
-- QUATRE RÈGLES DE CONCEPTION, chacune réparant une faille identifiée AVANT écriture :
--  1. AUCUNE IDENTITÉ EN PARAMÈTRE. L'acteur d'un évènement est DÉDUIT du secret présenté.
--     Passer un `participant` en argument rendrait l'attribution forgeable par tout porteur du
--     code — or l'attribution EST le contrôle que l'hôte demande (« savoir ce que l'invité a
--     modifié »), et elle alimente le compte-rendu de débriefing.
--  2. UN SECRET PAR PARTICIPANT, généré ICI (gen_random_bytes), jamais par le client — dont le
--     seul générateur maison (`uid()`) rend ~41 bits et retombe sur Math.random. Seul le sha-256
--     est stocké. C'est ce qui rend la coupure d'un invité EFFECTIVE : sans lui, le coupé
--     rejoindrait avec le même code, et la seule coupure qui mordrait serait celle de tout le
--     monde — en pleine réanimation.
--  3. FENÊTRE D'ADMISSION. Le code n'ouvre la porte que pendant quelques dizaines de secondes,
--     armées par un geste de l'hôte. Un code re-diffusé plus tard n'ouvre plus rien.
--  4. APPEND-ONLY STRICT. Un invité n'écrit QUE des lignes dans `session_events` ; il ne met à
--     jour aucun état partagé. L'état est un PLI calculé par chaque client — exactement la
--     doctrine du journal de parcours (« nav[] EST la chronologie, rien ne mute au-dessus »).
--     Un état matérialisé imposerait un lire-modifier-écrire, donc un verrou tenu par la file
--     d'un invité, derrière lequel L'HÔTE ATTENDRAIT SES PROPRES ÉCRITURES.
--
-- Aucune exception ne doit traverser jusqu'à un appelant anonyme : PostgREST recopie mot pour mot
-- `message`, `detail` et `hint`. Les fonctions renvoient donc une valeur normalisée, et le motif
-- du refus n'est détaillé qu'au propriétaire authentifié.

-- pgcrypto : `gen_random_bytes` et `digest`. Déjà présent sur une instance Supabase (schéma
-- `extensions`) ; la ligne est idempotente et ne fait rien dans ce cas.
create extension if not exists pgcrypto;

create table if not exists public.shared_sessions (
  id              text primary key,                 -- 'sh…', minté par le client (safeId)
  owner           uuid not null default auth.uid(),
  session_id      text not null,                    -- id de la session LOCALE de l'hôte
  fiche_id        text not null,
  -- PROJECTION DÉCLARÉE de la fiche (`sharePayload` côté client), jamais la fiche entière :
  -- `localInfo` est pré-rempli « Tél renfort / Tél régulation », et une image y pèse jusqu'à
  -- 4,5 Mo. Le plafond ci-dessous est la deuxième barrière, celle qui ne dépend pas du client.
  fiche_snap      jsonb not null,
  code_hash       text,                             -- sha-256 du code d'appariement ; NULL = porte close
  join_open_until timestamptz,                      -- fenêtre d'admission ; NULL = close
  max_guests      smallint not null default 3 check (max_guests between 1 and 8),
  guest_role      text not null default 'scribe' check (guest_role in ('scribe','lead')),
  status          text not null default 'active' check (status in ('active','ended','revoked')),
  -- ALLOCATEUR DE SÉQUENCE, PAR PARTAGE. Surtout PAS un `bigserial` : un serial alloue son numéro
  -- à l'INSERT, pas au COMMIT. Deux écrivains concurrents peuvent donc valider dans le désordre,
  -- et un lecteur qui a déjà avancé son curseur ne verra JAMAIS la ligne restée dessous — une
  -- case cochée, un minuteur armé, perdus en silence. Ici le numéro est pris sous verrou de
  -- ligne dans la transaction d'écriture : l'ordre des numéros EST l'ordre de visibilité.
  last_seq        bigint not null default 0,
  expires_at      timestamptz not null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists shared_sessions_owner_idx   on public.shared_sessions (owner, updated_at);
create index if not exists shared_sessions_expires_idx on public.shared_sessions (expires_at);
create unique index if not exists shared_sessions_code_idx
  on public.shared_sessions (code_hash) where code_hash is not null;

create table if not exists public.session_participants (
  share_id     text not null references public.shared_sessions(id) on delete cascade,
  participant  uuid not null default gen_random_uuid(),   -- identifiant PUBLIC opaque
  user_id      uuid references auth.users on delete cascade,  -- NULL = invité sans compte
  secret_hash  text,                                      -- NULL pour l'hôte : son JWT suffit
  label        text not null default 'Invité' check (length(label) between 1 and 24),
  role         text not null default 'scribe' check (role in ('scribe','lead')),
  is_owner     boolean not null default false,
  joined_at    timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  revoked_at   timestamptz,
  -- L'invité a quitté le partage pour POURSUIVRE SEUL (perte de réseau durable). Ce n'est pas une
  -- panne : c'est le repli hors dispositif exigé par l'AC 120-64 §9.a, et il se TRACE — l'hôte
  -- doit pouvoir lire, dans son compte-rendu, à quelle minute il a cessé d'être suivi.
  detached_at  timestamptz,
  events_count integer not null default 0,
  window_start timestamptz not null default now(),
  window_count integer not null default 0,
  primary key (share_id, participant)
);
create index if not exists session_participants_secret_idx
  on public.session_participants (secret_hash) where secret_hash is not null;

create table if not exists public.session_events (
  share_id  text not null references public.shared_sessions(id) on delete cascade,
  seq       bigint not null,
  event_id  uuid   not null,          -- fourni par le client : déduplication d'un rejeu
  actor     uuid   not null,          -- session_participants.participant, DÉDUIT du secret
  kind      text   not null,
  payload   jsonb  not null default '{}'::jsonb,
  -- DEUX HORLOGES, ET C'EST LE POINT QUI REND LE HORS-LIGNE HONNÊTE. `at` = arrivée au serveur ;
  -- `client_ts` = instant du GESTE, corrigé du décalage d'horloge mesuré pendant que la liaison
  -- était bonne. Une action relevée hors réseau et rejouée dix minutes plus tard doit apparaître
  -- au compte-rendu à l'heure où le soignant l'a faite, pas à celle où le réseau est revenu :
  -- sans `client_ts`, « Choc n°2 » se rangerait après « Adrénaline » alors qu'il la précède.
  -- (Danger n°2 du palmarès ECRI 2015 : intégrité des données, dont la désynchronisation
  -- d'horloges entre appareils est un mécanisme nommé.)
  client_ts timestamptz,
  at        timestamptz not null default now(),
  primary key (share_id, seq)
);
create unique index if not exists session_events_dedup_idx on public.session_events (share_id, event_id);

do $$ begin
  alter table public.shared_sessions add constraint shared_snap_size_chk
    check (octet_length(fiche_snap::text) <= 2*1024*1024);
exception when duplicate_object then null; end $$;
do $$ begin
  -- Un évènement de checklist est une coche, un minuteur, un compteur : quelques dizaines
  -- d'octets. Le plafond vaut CONTRE LE CLIENT (un appel REST direct ignore toute borne écrite
  -- en JavaScript) et contre le remplissage de la base, dont le quota est PARTAGÉ avec les fiches.
  alter table public.session_events add constraint session_events_payload_size_chk
    check (octet_length(payload::text) <= 4096);
exception when duplicate_object then null; end $$;

alter table public.shared_sessions      enable row level security;
alter table public.session_participants enable row level security;
alter table public.session_events       enable row level security;

-- RLS : le PROPRIÉTAIRE seul touche ces tables en direct (lister ses partages, couper, terminer).
-- Les invités n'ont AUCUN accès de table — ils passent exclusivement par les trois fonctions.
drop policy if exists shared_own on public.shared_sessions;
create policy shared_own on public.shared_sessions for all
  using      (owner = auth.uid() and public.is_approved())
  with check (owner = auth.uid() and public.is_approved());
drop policy if exists sparts_own on public.session_participants;
create policy sparts_own on public.session_participants for all
  using      (exists (select 1 from public.shared_sessions s
                       where s.id = share_id and s.owner = auth.uid() and public.is_approved()))
  with check (exists (select 1 from public.shared_sessions s
                       where s.id = share_id and s.owner = auth.uid() and public.is_approved()));
drop policy if exists sevents_own on public.session_events;
create policy sevents_own on public.session_events for select
  using (exists (select 1 from public.shared_sessions s
                  where s.id = share_id and s.owner = auth.uid() and public.is_approved()));

grant select, insert, update, delete on public.shared_sessions      to authenticated;
grant select,               update, delete on public.session_participants to authenticated;
grant select                                on public.session_events       to authenticated;

-- ---------- 8bis. Vocabulaire fermé et capacités ---------------------------------------------
-- Le rôle borne ce qu'un participant a le DROIT d'écrire, et le contrôle est ICI, pas dans le
-- client (qui n'est qu'ergonomie). Deux principes, tous deux doctrinaux :
--  • le scribe ne reçoit que des droits ADDITIFS et IDEMPOTENTS. Il coche, constate, incrémente,
--    horodate, ARME un minuteur — il n'en arrête ni n'en remet aucun à zéro : AGENTS.md range
--    l'arrêt d'un processus vivant au registre `--critical`, et une commande d'arrêt émise à
--    1 à 3 s de retard sur un écran périmé est exactement la bêtise à rendre impossible ;
--  • la NAVIGATION appartient au seul `lead`. Un seul curseur, un seul détenteur à tout instant
--    (AC 120-71B §6.4 pt 1 et §6.6.2.1). C'est aussi ce qui garantit qu'un seul participant mine
--    des numéros de visite, donc qu'aucune clé de cochage `seq:blocId:index` ne peut se
--    télescoper — la propriété technique découle de la règle doctrinale, pas l'inverse.
-- `offline_mark` est à part et mérite son mot : c'est le RELEVÉ D'UN PARTICIPANT DÉTACHÉ, rapporté
-- après coup. Il ne se fond JAMAIS dans l'état (ni coche, ni navigation, ni minuteur) — il vient
-- s'ajouter au journal comme un brin distinct, attribué et horodaté à l'heure du geste. C'est ce
-- qui permet de tout rapporter sans jamais fusionner deux états. Le pli côté client DOIT l'ignorer
-- pour le calcul d'état : c'est un document, pas une commande.
create or replace function public.share_kind_allowed(p_role text, p_kind text)
returns boolean language sql immutable set search_path = public, pg_temp as $$
  select case
    -- `mark_void` est ouvert au scribe là où `uncheck` ne l'est pas, et ce n'est pas une
    -- inconséquence : décocher DÉTRUIT une information, annuler un repère la CONSERVE (la ligne
    -- reste, barrée, attribuée, datée) et le geste est réversible. Ce n'est donc pas une action
    -- destructrice, et la règle qui réserve celles-ci au lead ne s'y applique pas.
    -- `handoff` est ouvert aux DEUX rôles, et c'est un raisonnement, pas un relâchement : il ne
    -- change AUCUN état côté serveur. Il porte une OFFRE (« je vous propose de conduire ») ou une
    -- PRISE (« je prends la main ») ; le changement de rôle lui-même est un UPDATE de
    -- `session_participants`, que la politique `sparts_own` réserve déjà au propriétaire du
    -- partage. La frontière de sécurité est donc là où elle doit être — sur l'écriture du rôle,
    -- pas sur l'annonce. Réserver l'offre au lead ici aurait interdit à l'invité d'ACCEPTER,
    -- c'est-à-dire d'accomplir le geste que la doctrine exige de LUI (AC 61-115 : la passation se
    -- fait en trois temps, et le receveur en prononce un).
    /* LA LIGNE PASSE SUR LA DESTRUCTION, PAS SUR LA HIÉRARCHIE (v4.55.0). Naviguer, choisir une
       branche, terminer un bloc, entrer sur une complication et ARRÊTER un minuteur sont tous
       append-only ou réversibles : rien ne les réservait au lead, et les réserver empêchait
       exactement la configuration la mieux documentée du dossier (McEvoy 2014 : le LECTEUR tient
       l'appareil et guide). Le critère « détruit / ne détruit pas » était déjà celui écrit ici
       pour `mark_void` ; il vaut pour tous. */
    when p_kind in ('check','verify','gap','counter','timer_arm','timer_stop','mark','mark_void',
                    'nav','flow_end','cx','presence','detach','offline_mark','handoff')
      then p_role in ('scribe','lead')
    -- `session_start` porte l'heure à laquelle le SOIN a commencé, pas celle de la jointure. Sans
    -- lui, un renfort arrivé à 14 h 12 sur une réanimation débutée à 13 h 55 date le début du soin
    -- à son arrivée — et son compte rendu, comme celui de l'hôte, devient inexploitable au débrief.
    -- Réservé au lead : c'est un fait sur LA session, pas un geste de participant.
    -- Reste réservé ce qui DÉTRUIT ou CLÔT : décocher efface une information ; remettre à zéro
    -- efface un décompte que personne ne restitue ; `end` clôt le partage ; `session_start` est un
    -- fait sur LA session de l'hôte, pas un geste de participant.
    when p_kind in ('uncheck','timer_reset','end','session_start')
      then p_role = 'lead'
    else false
  end;
$$;

-- ---------- 8ter. Purge — auto-exécutoire, jamais planifiée -----------------------------------
-- L'hébergement est statique : il n'y a personne pour lancer une tâche de ménage. Une purge
-- annoncée et non câblée serait pire que pas de purge — elle ferait écrire au registre une durée
-- de conservation fausse. Elle tourne donc en tête de CHAQUE appel, bornée pour ne jamais
-- allonger une requête de soin. Même doctrine que `check-sw.mjs`, qui rend la règle 13 exécutoire.
create or replace function public.share_purge()
returns void language sql volatile security definer set search_path = public, pg_temp as $$
  delete from public.shared_sessions
   where id in (select id from public.shared_sessions
                 where expires_at < now() - interval '30 minutes' limit 50);
$$;

-- ---------- 8quater. Code d'appariement -------------------------------------------------------
-- 8 caractères d'un alphabet de 32 symboles, soit 40 bits, valables quelques dizaines de secondes
-- et à usage unique : hors de portée d'une recherche exhaustive dans cette fenêtre.
-- L'alphabet exclut `I` et `O`, seuls réellement confondables avec `1` et `0` — qui n'y sont pas ;
-- `L` et `U` peuvent donc rester, ce qui porte le compte à 32 EXACTEMENT. Ce n'est pas cosmétique :
-- 256 étant divisible par 32, le `% 32` ci-dessous n'introduit AUCUN biais modulo, là où un
-- alphabet de 30 symboles rendrait les 16 premiers plus probables.
-- LE CODE EST TIRÉ ICI, jamais par le client : le seul générateur maison (`uid()`) préfixe
-- `Date.now()`, tronque à 8 caractères et retombe sur `Math.random()` — ~41 bits réels, et une
-- suite reconstructible. Un secret de session clinique ne peut pas en dépendre.
create or replace function public.share_new_code()
returns text language sql volatile set search_path = public, extensions, pg_temp as $$
  select string_agg(substr('23456789ABCDEFGHJKLMNPQRSTUVWXYZ', 1 + (get_byte(t.b, i) % 32), 1), '')
    from (select gen_random_bytes(8) as b) t, generate_series(0, 7) as i;
$$;

-- Résolution de l'appelant. LE SECRET EST LA CAPACITÉ : il désigne à lui seul le partage ET le
-- participant, donc aucun identifiant n'a jamais besoin d'être passé en argument (c'est ce qui
-- rend l'attribution infalsifiable). L'hôte, lui, s'authentifie par son JWT.
-- Renvoie AUSSI `revoked_at` / `detached_at` : les appelants doivent pouvoir distinguer « coupé »
-- de « injoignable ». Un invité coupé qui ne recevrait qu'un refus muet croirait à une panne
-- réseau et continuerait de cocher — exactement la bêtise que ce dispositif doit rendre impossible.
-- Aucun grant : seules les fonctions SECURITY DEFINER de cette section l'appellent.
create or replace function public.share_resolve(p_secret text, p_share text)
returns table(share_id text, participant uuid, role text, is_owner boolean,
              revoked_at timestamptz, detached_at timestamptz,
              status text, expires_at timestamptz, owner uuid)
language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare v_h text;
begin
  if p_secret is not null and length(p_secret) >= 16 then
    v_h := encode(digest(p_secret, 'sha256'), 'hex');
    return query
      select p.share_id, p.participant, p.role, p.is_owner, p.revoked_at, p.detached_at,
             s.status, s.expires_at, s.owner
        from public.session_participants p
        join public.shared_sessions s on s.id = p.share_id
       where p.secret_hash = v_h;
  elsif auth.uid() is not null and p_share is not null then
    return query
      select p.share_id, p.participant, p.role, p.is_owner, p.revoked_at, p.detached_at,
             s.status, s.expires_at, s.owner
        from public.session_participants p
        join public.shared_sessions s on s.id = p.share_id
       where p.share_id = p_share and p.is_owner and s.owner = auth.uid();
  end if;
end; $$;

-- ---------- 8quinquies. OUVERTURE (hôte authentifié) ------------------------------------------
-- Crée le partage, la ligne du propriétaire, et ouvre une PREMIÈRE fenêtre d'admission.
-- Le partage ne s'ouvre que sur une session DÉJÀ démarrée (garanti côté client) : sinon la
-- première action de l'invité déclencherait `ensureStarted` chez l'hôte, donc un `render()`
-- complet et l'apparition de ~53 px de chrome collant AU-DESSUS de son doigt, en pleine crise.
create or replace function public.share_open(p_id text, p_session_id text, p_fiche_id text,
                                             p_fiche_snap jsonb, p_guest_role text, p_ttl_min int)
returns jsonb language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare v_code text; v_ttl int; v_win int := 120; v_snap jsonb; v_live int;
begin
  perform public.share_purge();
  if auth.uid() is null or not public.is_approved() then
    return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  -- Validation SANS ancre de regex (« longueur » + « aucun caractère interdit ») : plus lisible,
  -- et cela évite un « $ » isolé dans le fichier, que le garde-fou check-sql.mjs doit pouvoir
  -- lire comme la signature d'un délimiteur mutilé sans avoir à faire d'exception.
  -- `p_session_id` est borné de la même façon que `p_id` : c'était le SEUL champ texte de la table
  -- sans aucune contrainte, et il est destiné à devenir une clé de jointure vers l'historique.
  if p_id is null or length(p_id) not between 1 and 64 or p_id ~ '[^A-Za-z0-9_-]'
     or p_session_id is null or length(p_session_id) not between 1 and 64
     or p_session_id ~ '[^A-Za-z0-9_-]'
     or p_fiche_snap is null or jsonb_typeof(p_fiche_snap) <> 'object' then
    return jsonb_build_object('ok', false, 'err', 'bad_request'); end if;
  /* LISTE BLANCHE DES CHAMPS, CÔTÉ SERVEUR (v4.49.0). La projection de fiche était filtrée
     EXCLUSIVEMENT en JavaScript (`SHARE_KEEP` / `SHARE_DROP`) : un appel REST direct ne traverse
     pas ce filtre, si bien que `images` (jusqu'à 24 Mo de base64), `localInfo` (les téléphones de
     renfort et de régulation) et la liste des documents pouvaient encore partir. Le schéma avait
     déjà tiré cette leçon pour la TAILLE — « le plafond vaut CONTRE LE CLIENT » — sans l'appliquer
     au CONTENU. On ne retire donc pas les champs interdits, on ne GARDE que les autorisés : une
     liste noire oublie ce qu'on ajoutera demain, une liste blanche le refuse par défaut.
     Les images de BLOC sont retirées séparément : elles vivent dans chaque élément de `blocks`. */
  select coalesce(jsonb_object_agg(k, v), '{}'::jsonb) into v_snap
    from jsonb_each(p_fiche_snap) as e(k, v)
   where k in ('id','title','discriminant','code','status','validatedAt','blocks','start','timers','counters',
               'items');   -- v5.0.0 : les six listes v3 sont devenues des items à rôle (pool `items`),
                           -- et `validation` s'appelle `validatedAt` (renommage en place dans `migrate`) :
                           -- l'ancien nom, resté ici, filtrait la date de validation à l'arrivée.
  if v_snap ? 'blocks' and jsonb_typeof(v_snap->'blocks') = 'array' then
    select jsonb_set(v_snap, '{blocks}', coalesce(jsonb_agg(b - 'image' - 'images'), '[]'::jsonb))
      into v_snap from jsonb_array_elements(v_snap->'blocks') as b;
  end if;
  /* PLAFOND DE PARTAGES VIVANTS PAR PROPRIÉTAIRE. Il n'en existait AUCUN : un compte — qui coûte
     une adresse jetable, l'approbation étant désactivée par défaut — pouvait ouvrir des partages
     en boucle et remplir la base. Ce plafond ne gêne aucun usage réel (on ne conduit pas cinq
     réanimations à la fois) et il borne l'abus sans rien demander à personne. */
  select count(*) into v_live from public.shared_sessions
   where owner = auth.uid() and status = 'active' and expires_at > now();
  if v_live >= 5 then return jsonb_build_object('ok', false, 'err', 'too_many_shares'); end if;
  -- Une fiche NON VALIDÉE ne se diffuse pas hors du compte. Le statut « brouillon » n'était
  -- jusqu'ici masqué que côté client — borne acceptable tant que seuls des membres authentifiés
  -- accédaient au contenu, plus du tout dès qu'un appareil sans compte le reçoit.
  if coalesce(v_snap->>'status', '') = 'draft' then
    return jsonb_build_object('ok', false, 'err', 'draft'); end if;
  v_ttl  := least(greatest(coalesce(p_ttl_min, 180), 10), 720);
  v_code := public.share_new_code();
  insert into public.shared_sessions(id, owner, session_id, fiche_id, fiche_snap, code_hash,
                                     join_open_until, guest_role, expires_at)
    values (p_id, auth.uid(), p_session_id, p_fiche_id, v_snap,
            encode(digest(v_code, 'sha256'), 'hex'),
            now() + make_interval(secs => v_win),
            case when p_guest_role = 'lead' then 'lead' else 'scribe' end,
            now() + make_interval(mins => v_ttl));
  insert into public.session_participants(share_id, user_id, label, role, is_owner)
    values (p_id, auth.uid(), 'Hôte', 'lead', true);
  return jsonb_build_object('ok', true, 'share', p_id, 'code', v_code,
    'join_open_until', now() + make_interval(secs => v_win),
    'expires_at', now() + make_interval(mins => v_ttl), 'server_time', now());
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- Ré-ouvre la porte pour quelques dizaines de secondes, avec un code NEUF (l'ancien meurt).
-- C'est la contrepartie de la fenêtre : couper un invité a du sens parce que rejoindre exige un
-- geste de l'hôte, sur SON écran.
create or replace function public.share_admit(p_share text, p_seconds int)
returns jsonb language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare v_code text; v_sec int; v_s public.shared_sessions%rowtype; v_n int;
begin
  perform public.share_purge();
  if auth.uid() is null then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  /* DEUX BOUCLES INFINIES FERMÉES ICI (v4.49.0). `share_admit` ne vérifiait NI l'expiration NI le
     quota : sur un partage expiré ou déjà plein, il rendait un code NEUF — que l'hôte lisait à voix
     haute et que `share_join` refusait aussitôt, sans que personne, des deux côtés, ne puisse
     comprendre pourquoi. Pire, il ÉCRASAIT au passage un code peut-être encore vivant.
     Le motif est détaillé ici parce que l'appelant est le PROPRIÉTAIRE authentifié : l'argument
     d'indifférenciation ne vaut que face à un anonyme, pour ne pas faire du serveur un oracle.
     C'est aussi ce que le schéma promet plus haut — « le motif du refus n'est détaillé qu'au
     propriétaire authentifié » — et qui n'était appliqué nulle part. */
  select * into v_s from public.shared_sessions
   where id = p_share and owner = auth.uid() limit 1;
  if v_s.id is null then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  if v_s.status <> 'active' then
    return jsonb_build_object('ok', false, 'err', 'ended'); end if;
  if v_s.expires_at <= now() then
    return jsonb_build_object('ok', false, 'err', 'expired'); end if;
  select count(*) into v_n from public.session_participants
   where share_id = v_s.id and not is_owner and revoked_at is null and detached_at is null;
  if v_n >= v_s.max_guests then
    return jsonb_build_object('ok', false, 'err', 'full', 'guests', v_n, 'max', v_s.max_guests); end if;
  v_sec  := least(greatest(coalesce(p_seconds, 120), 15), 600);
  v_code := public.share_new_code();
  update public.shared_sessions
     set code_hash = encode(digest(v_code, 'sha256'), 'hex'),
         join_open_until = now() + make_interval(secs => v_sec), updated_at = now()
   where id = p_share and owner = auth.uid() and status = 'active';
  if not found then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  return jsonb_build_object('ok', true, 'code', v_code,
    'join_open_until', now() + make_interval(secs => v_sec), 'server_time', now());
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- ---------- 8sexies. JOINTURE (invité, avec ou sans compte) ----------------------------------
-- PAS DE LIMITE DE DÉBIT ICI, ET C'EST DÉLIBÉRÉ (v5.10.2, audit — l'asymétrie avec share_push,
-- qui a sa fenêtre glissante de 10 s, est une décision et non un oubli) : l'espace de codes fait
-- 32^8 ≈ 1,1 × 10^12, la porte n'est ouverte que ~120 s et le code est CONSOMMÉ à la première
-- jointure — un brute-force est hors de portée avant l'expiration. Une limite ajouterait un état
-- par appelant anonyme pour un risque déjà borné par la construction du code.
create or replace function public.share_join(p_code text, p_label text)
returns jsonb language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare v_s public.shared_sessions%rowtype; v_secret text; v_part uuid; v_n int;
begin
  perform public.share_purge();
  if p_code is null or length(p_code) <> 8 then
    return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  select * into v_s from public.shared_sessions
   where code_hash = encode(digest(upper(p_code), 'sha256'), 'hex')
     and status = 'active' and join_open_until is not null
     and now() <= join_open_until and now() < expires_at
   for update;
  if not found then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  select count(*) into v_n from public.session_participants
   where share_id = v_s.id and not is_owner and revoked_at is null and detached_at is null;
  if v_n >= v_s.max_guests then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  v_secret := encode(gen_random_bytes(18), 'base64');
  insert into public.session_participants(share_id, user_id, secret_hash, label, role)
    values (v_s.id, auth.uid(),
            encode(digest(v_secret, 'sha256'), 'hex'),
            /* AUCUN MÉTACARACTÈRE DE BALISAGE DANS UN LIBELLÉ DE PARTICIPANT. Il s'affiche chez
               TOUS les autres, et l'application ne propose qu'une liste fermée de neuf rôles —
               mais un client modifié n'est pas tenu par un `<select>`. On ne recopie pas la liste
               ici (elle dériverait) : on retire ce qui n'a rien à faire dans un nom de rôle. Le
               client échappe déjà à l'affichage ; ceci est la barrière qui ne dépend pas de lui. */
            coalesce(nullif(substr(regexp_replace(coalesce(p_label, ''),
                                                  '[^[:alnum:] ''()\-]', '', 'g'), 1, 24), ''), 'Invité'),
            v_s.guest_role)
    returning participant into v_part;
  -- Le code est CONSOMMÉ : la porte se referme derrière celui qui entre. Un lien ou une capture
  -- qui circulerait ensuite n'ouvre plus rien ; l'hôte ré-arme s'il veut un second participant.
  update public.shared_sessions set code_hash = null, join_open_until = null, updated_at = now()
   where id = v_s.id;
  return jsonb_build_object('ok', true, 'share', v_s.id, 'me', v_part, 'secret', v_secret,
    'role', v_s.guest_role, 'fiche', v_s.fiche_snap, 'since', 0,
    'expires_at', v_s.expires_at, 'server_time', now());
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- ---------- 8septies. LECTURE ----------------------------------------------------------------
-- Renvoie le delta depuis `p_since`, l'état du partage, la liste des participants (LIBELLÉS
-- seulement — jamais un user_id, jamais un secret), et DEUX quantités qui servent au client à
-- détecter une divergence silencieuse : `seq` (dernier numéro alloué) et `n_events` (total réel).
-- Un miroir qui n'obtient pas le même compte se déclare PÉRIMÉ et redemande tout, au lieu
-- d'afficher un état plausible mais faux — le mode de défaillance qu'un simple indicateur de
-- silence ne verrait jamais, puisque les mises à jour arrivent à l'heure et sont fausses.
create or replace function public.share_pull(p_secret text, p_share text, p_since bigint)
returns jsonb language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare a record; v_ev jsonb; v_parts jsonb; v_seq bigint; v_n int; v_state text; v_stream text;
begin
  perform public.share_purge();
  select * into a from public.share_resolve(p_secret, p_share) limit 1;
  if a.share_id is null then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  -- ÉTAT EXPLICITE, TOUJOURS. « coupé », « terminé » et « expiré » ne doivent jamais se présenter
  -- comme un silence : c'est ce qui permet à l'écran de l'invité de dire POURQUOI il s'arrête.
  v_state := case when a.revoked_at  is not null then 'revoked'
                  when a.detached_at is not null then 'detached'
                  when a.expires_at  <  now()    then 'expired'
                  else a.status end;
  update public.session_participants set last_seen_at = now()
   where share_id = a.share_id and participant = a.participant;
  select coalesce(jsonb_agg(jsonb_build_object('seq', e.seq, 'id', e.event_id, 'actor', e.actor,
                                               'kind', e.kind, 'payload', e.payload,
                                               'ts', e.client_ts, 'at', e.at)
                            order by e.seq), '[]'::jsonb)
    into v_ev
    from (select * from public.session_events
           where share_id = a.share_id and seq > coalesce(p_since, 0)
           order by seq limit 500) e;
  select s.last_seq into v_seq from public.shared_sessions s where s.id = a.share_id;
  select count(*)   into v_n   from public.session_events where share_id = a.share_id;
  /* EMPREINTE DU FLUX D'ENTRÉE — et surtout PAS de l'état.
     Un compte d'évènements ne détecte qu'une PERTE. Il ne voit ni un doublon appliqué, ni un
     ordre faux, ni un identifiant corrompu — trois façons d'obtenir un écran plausible et faux,
     avec des réponses qui arrivent parfaitement à l'heure. C'est le danger n°2 du palmarès ECRI
     (intégrité des données) et il ne se traite pas par la confiance.
     ON HACHE LES ENTRÉES, PAS L'ÉTAT, et ce n'est pas un raccourci : hacher l'état obligerait le
     serveur à REJOUER le pli, donc à savoir ce qu'un « cocher » signifie — une seconde
     implémentation de la sémantique, en PL/pgSQL, qui divergerait du client. C'est exactement la
     duplication qui a coûté le défaut de v4.42.0. Ici le serveur n'aligne que des couples
     (numéro, identifiant) : des données, aucune sémantique. Et comme le pli client est PUR et son
     déterminisme prouvé par un test unitaire, mêmes entrées ⇒ même état.
     SHA-256 des deux côtés : natif ici (`sha256`, PostgreSQL ≥ 11) comme dans le navigateur
     (`crypto.subtle`). Aucun code de hachage maison à tenir synchronisé entre deux langages.
     COÛT : un parcours des évènements du partage par lecture, borné par le plafond de 5 000 et
     servi par la clé primaire (share_id, seq) — quelques dizaines de microsecondes sur une
     session réelle d'environ 150 évènements. */
  select encode(sha256(convert_to(
           coalesce(string_agg(e.seq::text || ':' || e.event_id::text, ',' order by e.seq), ''),
           'UTF8')), 'hex')
    into v_stream
    from public.session_events e where e.share_id = a.share_id;
  select coalesce(jsonb_agg(jsonb_build_object('id', p.participant, 'label', p.label,
           'role', p.role, 'owner', p.is_owner, 'seen', p.last_seen_at,
           'revoked', p.revoked_at is not null, 'detached', p.detached_at is not null)
         order by p.joined_at), '[]'::jsonb)
    into v_parts from public.session_participants p where p.share_id = a.share_id;
  /* LA FICHE N'EST RENVOYÉE QUE SUR UNE REPRISE COMPLÈTE (`p_since = 0`), jamais aux sondages
     ordinaires — qui passent toutes les deux à dix secondes et n'ont aucun besoin d'un instantané
     de plusieurs dizaines de kilo-octets. Elle sert au cas où un invité RECHARGE sa page : son
     code est consommé, il ne peut donc pas rejoindre, mais il détient encore son secret ; il
     reprend le fil avec lui, et il lui faut de quoi repeindre. Aucune donnée nouvelle ne sort :
     c'est le même `fiche_snap` que `share_join` lui a déjà remis, filtré par la même liste
     blanche à l'ouverture. */
  /* UN PARTICIPANT COUPÉ NE REÇOIT PLUS RIEN — la coupure mord au SERVEUR, pas seulement chez
     lui. Jusqu'ici la fonction renvoyait `status: revoked` ET le flux complet : c'était son
     application qui gelait l'écran, donc un client modifié continuait de lire la session jusqu'à
     l'expiration. Le statut, lui, reste renvoyé : il faut qu'il SACHE, sinon la coupure passerait
     pour une panne de réseau. Même traitement pour un détaché, qui a bifurqué et dont l'état ne
     doit plus être alimenté. */
  if a.revoked_at is not null or a.detached_at is not null then
    return jsonb_build_object('ok', true, 'status', v_state, 'role', a.role, 'me', a.participant,
      'owner', a.is_owner, 'events', '[]'::jsonb, 'seq', 0, 'n_events', 0,
      'participants', '[]'::jsonb, 'expires_at', a.expires_at, 'server_time', now());
  end if;
  return jsonb_build_object('ok', true, 'status', v_state, 'role', a.role, 'me', a.participant,
    'owner', a.is_owner, 'events', v_ev, 'seq', v_seq, 'n_events', v_n, 'stream', v_stream,
    'participants', v_parts, 'expires_at', a.expires_at, 'server_time', now())
    || case when coalesce(p_since, 0) = 0 and not a.is_owner
         then jsonb_build_object('fiche',
                (select s.fiche_snap from public.shared_sessions s where s.id = a.share_id))
         else '{}'::jsonb end;
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- ---------- 8octies. ÉCRITURE ----------------------------------------------------------------
-- Un participant n'écrit QUE des lignes d'évènement, jamais un état. Le numéro de séquence est
-- pris sous verrou de la ligne du partage, dans la transaction : c'est ce qui sérialise les
-- écritures concurrentes et garantit que l'ordre des numéros est l'ordre de visibilité.
-- Le verrou est tenu le temps d'un `update` d'un entier suivi d'un `insert` — jamais le temps
-- d'une lecture-modification-écriture d'état, qui ferait attendre l'hôte derrière un invité.
create or replace function public.share_push(p_secret text, p_share text, p_events jsonb)
returns jsonb language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare a record; v_n int; v_base bigint; v_win int; v_ok int; v_state text; v_det boolean;
begin
  perform public.share_purge();
  select * into a from public.share_resolve(p_secret, p_share) limit 1;
  if a.share_id is null then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  v_state := case when a.revoked_at  is not null then 'revoked'
                  when a.expires_at  <  now()    then 'expired'
                  when a.detached_at is not null then 'detached'
                  else a.status end;
  -- UN DÉTACHÉ N'ÉCRIT PLUS L'ÉTAT, MAIS IL PEUT ENCORE RAPPORTER — et c'est tout l'écart entre
  -- « ne pas fusionner » et « perdre l'information ». Celui qui a poursuivi seul détient un relevé
  -- RÉEL d'une intervention réelle : le laisser mourir sur son appareil serait une perte, pas une
  -- précaution. Il peut donc pousser des `offline_mark`, et RIEN d'autre : son journal remonte,
  -- son état ne remonte pas. L'hôte voit apparaître un brin annexe, daté et attribué, à côté du
  -- sien — et c'est LUI qui décide quoi en faire. Le dispositif rend l'écart VISIBLE ; il ne
  -- tranche pas à la place du soignant (AC 120-71B §5.2.2.2 : constater qu'une action requise
  -- manque OBLIGE à le signaler — signaler, précisément, pas corriger d'autorité).
  -- Un participant COUPÉ par l'hôte, lui, ne rapporte rien : la coupure est une décision, pas
  -- une panne, et son relevé reste chez lui.
  if v_state <> 'active' and v_state <> 'detached' then
    return jsonb_build_object('ok', false, 'err', v_state, 'status', v_state, 'server_time', now());
  end if;
  if jsonb_typeof(p_events) <> 'array' then
    return jsonb_build_object('ok', false, 'err', 'bad_request'); end if;
  v_n := jsonb_array_length(p_events);
  if v_n = 0 then
    return jsonb_build_object('ok', true, 'accepted', 0, 'status', v_state, 'server_time', now()); end if;
  if v_n > 50 then return jsonb_build_object('ok', false, 'err', 'too_many'); end if;
  -- Limiteur de débit par participant : le quota de base est PARTAGÉ avec les fiches cliniques,
  -- et il n'existe aucun serveur applicatif où poser une limite. Fenêtre glissante de 10 s.
  update public.session_participants
     set window_count = case when window_start < now() - interval '10 seconds' then v_n
                             else window_count + v_n end,
         window_start = case when window_start < now() - interval '10 seconds' then now()
                             else window_start end,
         events_count = events_count + v_n, last_seen_at = now()
   where share_id = a.share_id and participant = a.participant
   returning window_count into v_win;
  if v_win > 120 or (select events_count from public.session_participants
                      where share_id = a.share_id and participant = a.participant) > 5000 then
    return jsonb_build_object('ok', false, 'err', 'rate'); end if;
  -- UN LOT QUI PORTE UN « detach » NE PORTE QUE LUI. L'invité qui a choisi de poursuivre seul a
  -- devant lui une file d'actions relevées PENDANT qu'il était déjà désynchronisé : les rejouer
  -- sur la session vive de l'hôte, qui a avancé entre-temps, écrirait des coches sur des passages
  -- qu'il a quittés — un enregistrement FAUX, et précisément ce que la réconciliation existe pour
  -- éviter. Ces actions restent la trace de SA session autonome, sur SON appareil.
  -- La règle est appliquée ICI plutôt que laissée à une convention de client : le serveur est la
  -- seule barrière réelle, le client n'est qu'ergonomie.
  v_det := exists (select 1 from jsonb_array_elements(p_events) e where e->>'kind' = 'detach');
  update public.shared_sessions set last_seq = last_seq + v_n, updated_at = now()
   where id = a.share_id returning last_seq - v_n into v_base;
  -- Les évènements sont RECONSTRUITS champ par champ sur une liste fermée de clés : insérer le
  -- jsonb reçu tel quel permettrait à un participant d'y glisser son propre `actor` et de signer
  -- une action du nom d'un autre. `actor` vient de la résolution du secret, point.
  with src as (
    select (e->>'event_id')::uuid                              as event_id,
           e->>'kind'                                          as kind,
           /* LISTE BLANCHE DES CLÉS DE PAYLOAD (v4.54.0). Le serveur ne validait que le TYPE
              et la TAILLE : un client modifié pouvait donc y glisser n'importe quoi, et deux
              injections d'attribut ont été reproduites côté client à partir de là (v4.53.1).
              Le client se défend désormais aux deux entrées — mais faire reposer la sûreté sur le
              seul client est précisément la faute que `share_open` a corrigée pour la fiche.
              On ne retire pas les clés interdites, on ne GARDE que les autorisées : une liste
              noire oublie ce qu'on ajoutera demain.
              `label` N'Y EST PAS, ET C'EST LE POINT : c'est ce qui rend vraie, au niveau du
              SERVEUR, la promesse « aucun texte libre ne traverse le réseau » (règle 15 du
              projet, § 3.1 du registre RGPD) — elle ne dépend plus d'une discipline de client. */
           case when jsonb_typeof(e->'payload') = 'object' then
                  coalesce((select jsonb_object_agg(k, v)
                              from jsonb_each(e->'payload') as kv(k, v)
                             where k in ('k','t','id','v','running','elapsedMs','cycles','anchor',
                                         'nav','navSeq','on','exo','ref','was','to','take')),
                           '{}'::jsonb)
                else '{}'::jsonb end                           as payload,
           nullif(e->>'ts','')::timestamptz                     as client_ts,
           ord
      from jsonb_array_elements(p_events) with ordinality t(e, ord)),
  ins as (
    insert into public.session_events(share_id, seq, event_id, actor, kind, payload, client_ts)
    select a.share_id, v_base + src.ord, src.event_id, a.participant, src.kind,
           src.payload, coalesce(src.client_ts, now())
      from src
     where src.event_id is not null
       and public.share_kind_allowed(a.role, src.kind)
       -- Trois régimes, dans l'ordre de spécificité :
       --   détaché  -> SEULES les annexes remontent (son état a divergé, il ne l'impose pas) ;
       --   lot avec `detach` -> seul le detach passe (le reste de la file appartient déjà à sa
       --                        session autonome et écrirait sur des passages quittés) ;
       --   sinon    -> les capacités du rôle font foi.
       and (case when v_state = 'detached' then src.kind = 'offline_mark'
                 when v_det                then src.kind = 'detach'
                 else true end)
    on conflict (share_id, event_id) do nothing
    returning 1)
  select count(*) into v_ok from ins;
  -- « Je continue seul » : l'invité quitte le miroir pour reprendre l'aide en session AUTONOME
  -- sur son appareil (repli hors dispositif, AC 120-64 §9.a). Ce n'est pas une panne, c'est une
  -- décision — elle se DATE, pour que le compte-rendu de l'hôte dise à quelle minute il a cessé
  -- d'être suivi. Si le réseau ne revient jamais, l'évènement ne part pas : le silence, lui,
  -- reste lisible dans `last_seen_at`.
  if exists (select 1 from jsonb_array_elements(p_events) e where e->>'kind' = 'detach') then
    update public.session_participants set detached_at = now()
     where share_id = a.share_id and participant = a.participant and not is_owner;
  end if;
  return jsonb_build_object('ok', true, 'accepted', v_ok, 'rejected', v_n - v_ok,
    'seq', v_base + v_n, 'status', v_state, 'server_time', now());
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- Ouverture et ré-admission : réservées à l'hôte CONNECTÉ, donc jamais accordées à anon — cela
-- garde la surface non authentifiée à trois fonctions exactement.
grant execute on function public.share_open(text,text,text,jsonb,text,int) to authenticated;
grant execute on function public.share_admit(text,int)                     to authenticated;
-- `share_purge`, `share_resolve`, `share_new_code` et `share_kind_allowed` ne reçoivent AUCUN
-- grant : elles ne sont appelées que depuis les fonctions SECURITY DEFINER ci-dessus, qui
-- s'exécutent avec les droits du définisseur. Les exposer n'apporterait rien et donnerait à
-- `share_resolve` — qui prend un secret — une surface d'appel directe.

-- État de l'instance : RE-CRÉÉE une TROISIÈME fois, ici, pour la même raison qu'après la table
-- `protocols` — une fonction `language sql` est intégralement résolue À SA CRÉATION, elle ne peut
-- donc pas référencer une table déclarée plus bas dans le fichier (`42P01: relation … does not
-- exist`). Les fonctions `language plpgsql` échappent à cette contrainte : leur corps n'est
-- analysé qu'à la première exécution — c'est pourquoi `delete_my_account`, qui supprime pourtant
-- la même table, n'a pas eu besoin d'être déplacée.
create or replace function public.get_instance_stats()
returns jsonb language sql stable security definer set search_path = public, auth, pg_temp as $$
  select case when not public.is_app_admin() then null else jsonb_build_object(
    'users',        (select count(*) from auth.users),
    'pending',      (select count(*) from public.user_status where status = 'pending'),
    'rejected',     (select count(*) from public.user_status where status = 'rejected'),
    'libraries',    (select count(*) from public.libraries),
    'fiches_perso', (select count(*) from public.cognitive_aids where library_id is null and deleted_at is null),
    'fiches_shared',(select count(*) from public.cognitive_aids where library_id is not null and deleted_at is null),
    'protocols',    (select count(*) from public.protocols where deleted_at is null),
    -- Partages VIVANTS d'abord, mais AUSSI le total de lignes : un total qui gonflerait pendant
    -- que le compte des vivants reste bas est la signature d'une purge qui ne tourne pas — le
    -- seul symptôme observable d'un dispositif dont la durée de conservation est écrite au
    -- registre RGPD. C'est ce qu'on veut pouvoir constater sans ouvrir la base.
    'shares_live',  (select count(*) from public.shared_sessions
                      where status = 'active' and expires_at > now()),
    'shares_rows',  (select count(*) from public.shared_sessions),
    'sessions',     (select count(*) from public.sessions where deleted_at is null),
    -- LES OCTETS DES PARTAGES ENTRENT DANS LE TOTAL (v4.49.0). Ils en étaient absents : la base
    -- pouvait grossir de plusieurs centaines de mégaoctets sans que le tableau de bord ne bouge
    -- d'un octet — l'exploitant était aveugle au seul poste que le partage fait croître, et c'est
    -- précisément celui dont la durée de conservation est écrite au registre RGPD.
    'storage_bytes',(select coalesce(sum(octet_length(data::text)),0) from public.cognitive_aids where deleted_at is null)
                    + (select coalesce(sum(octet_length(data::text)),0) from public.category_sets)
                    + (select coalesce(sum(octet_length(data::text)),0) from public.protocols where deleted_at is null)
                    + (select coalesce(sum(octet_length(fiche_snap::text)),0) from public.shared_sessions)
                    -- Historique synchronisé : un poste qui croît avec l'usage, et qu'un exploitant
                    -- aveugle ne pourrait pas anticiper (leçon v4.49.0, où le serveur comptait déjà
                    -- les octets du partage sans que l'écran ne les montre).
                    + (select coalesce(sum(octet_length(data::text)),0) from public.sessions where deleted_at is null)
                    + (select coalesce(sum(octet_length(payload::text)),0) from public.session_events),
    'attachments_bytes',(select coalesce(sum((o.metadata->>'size')::bigint),0)
                         from storage.objects o where o.bucket_id = 'attachments')
  ) end;
$$;
grant execute on function public.get_instance_stats() to authenticated;

-- ---------- 5quater. LA PROHIBITION anon NE PORTAIT PAS SUR PUBLIC (correctif) --------------
-- Le bloc « GRANTS » plus haut annonce une « INTERDICTION EXPLICITE POUR anon ». Elle ne faisait
-- pas ce qu'elle disait, et l'écart est structurel, pas un oubli :
--   • `revoke ... from anon` ne retire QUE les privilèges accordés NOMMÉMENT à anon ;
--   • or PostgreSQL accorde EXECUTE à **PUBLIC** par défaut sur TOUTE fonction (asymétrie avec
--     les tables, qui n'en reçoivent aucun — d'où un revoke efficace côté tables et INOPÉRANT
--     côté fonctions), et PUBLIC détient aussi USAGE sur le schéma `public` ;
--   • tout rôle, anon compris, hérite de PUBLIC.
-- Conséquence mesurable AVANT ce correctif : les fonctions de ce schéma étaient appelables SANS
-- COMPTE. Aucune escalade directe — chacune se protège par `auth.uid()` / `is_app_admin()` — mais
-- la garantie annoncée n'existait pas, et un futur helper écrit en s'y fiant serait sans défense.
-- (C'est le pendant exact du contrôle aveugle de la v4.44.1 : la phrase couvrait un cas, le code
--  en couvrait un autre.)
--
-- POURQUOI ICI, EN FIN DE FICHIER, et non dans le bloc 5 : `revoke ... on all functions` n'agit
-- que sur les fonctions EXISTANT à cet instant, et six d'entre elles sont définies plus bas.
-- Surtout, `create or replace function` CONSERVE l'ACL d'une fonction déjà présente : au rejeu du
-- schéma sur une instance existante, un revoke placé en amont laisserait intactes toutes celles
-- redéfinies ensuite. Placé en fin de fichier, il les couvre TOUTES, à chaque rejeu.
--
-- INNOCUITÉ VÉRIFIÉE avant écriture (inventaire fonction par fonction) : les 15 fonctions
-- appelables par l'app portent chacune leur `grant execute ... to authenticated` explicite ; les
-- 5 restantes (clamp_updated_at, stamp_updated_by, handle_new_user, lib_add_creator,
-- revoke_memberships) sont des fonctions de TRIGGER, invoquées par le moteur — le privilège
-- EXECUTE n'y est contrôlé qu'à la CRÉATION du trigger, jamais à son déclenchement.
-- USAGE sur le schéma n'est délibérément PAS retiré à PUBLIC : sans EXECUTE il n'ouvre rien
-- (les tables n'ont aucun grant PUBLIC), et le retirer toucherait des rôles internes de
-- l'instance pour un gain nul.
-- LIMITE ASSUMÉE, comme pour les deux lignes du bloc 5 : `alter default privileges` sans
-- `for role` ne lie que le rôle qui l'exécute (postgres, depuis l'éditeur SQL). Une migration
-- jouée par un autre rôle recréerait le grant PUBLIC — c'est le balayage anon de rls-tests.sql
-- (§13.5, refondu en assertions de CATALOGUE) qui le rattrape, pas ce fichier.
-- Les deux `revoke ... from anon` du bloc 5 sont REJOUÉS ici, et ce n'est pas une redondance
-- décorative : Supabase pose à la création du projet un `alter default privileges ... grant all
-- on functions to postgres, anon, authenticated, service_role`. Si cet ALTER a été exécuté par un
-- autre rôle que celui qui joue ce fichier, le nôtre ne l'annule pas — et chaque fonction créée
-- APRÈS le bloc 5 (il y en a six) repartirait avec un grant anon nominatif. Rejouer en fin de
-- fichier attrape tout, quel que soit l'ordre. Idempotent, et vérifié empiriquement par le
-- balayage 13.5b de rls-tests.sql (qui lit le CATALOGUE, pas nos intentions).
revoke execute on all functions in schema public from public;
revoke all on all functions in schema public from anon;
revoke all on all tables    in schema public from anon;
alter default privileges in schema public revoke execute on functions from public;

-- ---------- 5quinquies. LA SEULE SURFACE NON AUTHENTIFIÉE DU PROJET --------------------------
-- TROIS fonctions, nommées une par une, et rien d'autre — jamais une table, jamais un
-- `on all functions`. C'est la contrepartie assumée d'un besoin clinique précis : qu'un collègue
-- présent dans la pièce puisse suivre et remplir une session sur SON téléphone, sans compte,
-- sans installer l'app, pour cette session-là uniquement.
-- CES LIGNES DOIVENT RESTER APRÈS LE BLOC CI-DESSUS : la révocation à PUBLIC porte sur « toutes
-- les fonctions du schéma », donc sur celles-ci aussi. Placées avant, elles seraient effacées
-- quelques lignes plus bas — en silence, et le partage cesserait de fonctionner sans qu'aucun
-- message ne désigne la cause.
-- POURQUOI C'EST TENABLE : ces trois fonctions n'exposent que le partage désigné par le SECRET
-- présenté ; elles ne prennent aucune identité en paramètre ; elles ne laissent échapper aucune
-- exception PostgreSQL (PostgREST recopierait `message`, `detail` et `hint` mot pour mot) ; et
-- le balayage §13.5b de rls-tests.sql vérifie, PAR LE CATALOGUE, que la liste des fonctions
-- exécutables par anon est EXACTEMENT celle-ci — un quatrième grant, même accidentel, fait
-- échouer le test.
grant usage on schema public to anon;   -- sans USAGE, aucun `grant execute` n'est utilisable
grant execute on function public.share_join(text,text)         to anon, authenticated;
grant execute on function public.share_pull(text,text,bigint)  to anon, authenticated;
grant execute on function public.share_push(text,text,jsonb)   to anon, authenticated;

-- ---------- 6. Recharge du cache PostgREST ----------------------------------
notify pgrst, 'reload schema';

-- ============================================================================
--  APRÈS EXÉCUTION — pour vous nommer app-admin (créateur de bibliothèques) :
--    1) Connectez-vous une première fois dans l'app (pour créer votre compte).
--       La validation des comptes est DÉSACTIVÉE PAR DÉFAUT (voir app_settings
--       ci-dessus) : ce premier compte se synchronise donc normalement, sans
--       écran "en attente". Vous n'êtes pas encore app-admin pour autant (pas
--       de création de bibliothèque) tant que l'étape 2 n'est pas faite.
--    2) puis exécutez, en remplaçant l'e-mail :
--       insert into public.app_admins(user_id)
--       select id from auth.users where email = 'vous@exemple.fr';
--
--  Comptes suivants : ils se synchronisent librement tant que vous n'activez pas
--  la validation (fenêtre Compte -> « Comptes en attente », visible seulement
--  pour un app-admin -> case « Exiger une validation pour les nouveaux comptes »).
-- ============================================================================


-- ---------- COMPATIBILITÉ 4.x (lot T9) --------------------------------------
--  Un client antérieur appelle encore `/rest/v1/fiches` et `/rest/v1/fiche_notes`. Ces vues le
--  laissent travailler NORMALEMENT pendant la transition — et elles ne créent aucune faille :
--
--   • `security_invoker = true` (PostgreSQL 15+) fait évaluer les politiques RLS avec les droits
--     de l'APPELANT et non ceux du propriétaire de la vue. Sans cette option, une vue est un
--     contournement de RLS en règle — c'est l'erreur classique, et elle serait ici une fuite
--     de données entre comptes.
--   • Une vue SIMPLE sur une seule table est nativement MODIFIABLE (insert/update/delete) : le
--     client 4.x continue donc d'écrire, sans règle ni trigger à maintenir.
--
--  À SUPPRIMER quand plus aucun client 4.x ne tourne — deux `drop view`, rien d'autre.
create or replace view public.fiches with (security_invoker = true) as
  select * from public.cognitive_aids;
create or replace view public.fiche_notes with (security_invoker = true) as
  select * from public.aid_notes;
grant select, insert, update, delete on public.fiches     to authenticated;
grant select, insert, update, delete on public.fiche_notes to authenticated;
