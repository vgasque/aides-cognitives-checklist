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

create table if not exists public.fiches (
  id         text primary key,
  owner      uuid not null default auth.uid(),
  library_id text references public.libraries on delete cascade,   -- NULL = perso
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists fiches_updated_idx on public.fiches (updated_at);
create index if not exists fiches_library_idx on public.fiches (library_id);

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
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.app_admins where user_id = auth.uid());
$$;

create or replace function public.is_member(lib text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.memberships
                 where user_id = auth.uid() and library_id = lib);
$$;

create or replace function public.member_role(lib text)
returns text language sql stable security definer set search_path = public as $$
  select role from public.memberships
  where user_id = auth.uid() and library_id = lib;
$$;

-- ---------- 3. RLS (explicite, même si auto-RLS est ON) ---------------------
alter table public.app_admins    enable row level security;
alter table public.libraries     enable row level security;
alter table public.memberships   enable row level security;
alter table public.fiches        enable row level security;
alter table public.category_sets enable row level security;

-- app_admins : AUCUNE politique + AUCUN grant -> totalement invisible de l'API.

-- fiches : perso (owner) OU partagé (lecture = membre, écriture = editor/admin)
create policy fiches_perso on public.fiches for all
  using      (library_id is null and owner = auth.uid())
  with check (library_id is null and owner = auth.uid());
create policy fiches_shared_read on public.fiches for select
  using (library_id is not null and public.is_member(library_id));
create policy fiches_shared_write on public.fiches for all
  using      (library_id is not null and public.member_role(library_id) in ('editor','admin'))
  with check (library_id is not null and public.member_role(library_id) in ('editor','admin'));

-- category_sets : même logique
create policy cats_perso on public.category_sets for all
  using      (library_id is null and owner = auth.uid())
  with check (library_id is null and owner = auth.uid());
create policy cats_shared_read on public.category_sets for select
  using (library_id is not null and public.is_member(library_id));
create policy cats_shared_write on public.category_sets for all
  using      (library_id is not null and public.member_role(library_id) in ('editor','admin'))
  with check (library_id is not null and public.member_role(library_id) in ('editor','admin'));

-- libraries : lecture = membre ou app-admin ; création = app-admin uniquement ;
--             renommage = app-admin ou library-admin ; suppression = app-admin
create policy lib_select on public.libraries for select
  using (public.is_member(id) or public.is_app_admin());
create policy lib_insert on public.libraries for insert
  with check (public.is_app_admin());
create policy lib_update on public.libraries for update
  using      (public.is_app_admin() or public.member_role(id) = 'admin')
  with check (public.is_app_admin() or public.member_role(id) = 'admin');
create policy lib_delete on public.libraries for delete
  using (public.is_app_admin());

-- memberships : on voit ses propres lignes (et l'admin voit celles de sa biblio) ;
--               seul un library-admin (ou app-admin) ajoute/retire des membres
create policy mem_select on public.memberships for select
  using (user_id = auth.uid() or public.member_role(library_id) = 'admin' or public.is_app_admin());
create policy mem_write on public.memberships for all
  using      (public.member_role(library_id) = 'admin' or public.is_app_admin())
  with check (public.member_role(library_id) = 'admin' or public.is_app_admin());

-- ---------- 4. Trigger : le créateur d'une biblio en devient admin ----------
create or replace function public.lib_add_creator()
returns trigger language plpgsql security definer set search_path = public as $$
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
grant select, insert, update, delete on public.fiches        to authenticated;
grant select, insert, update, delete on public.category_sets to authenticated;
grant select, insert, update, delete on public.libraries     to authenticated;
grant select, insert, update, delete on public.memberships   to authenticated;
grant execute on function public.is_app_admin()   to authenticated;
grant execute on function public.is_member(text)  to authenticated;
grant execute on function public.member_role(text) to authenticated;
-- public.app_admins : volontairement AUCUN grant.

-- ---------- 5bis. Invitation d'un membre par e-mail (Lot 3) -----------------
-- Recherche un compte par e-mail (table auth.users protégée) et lui attribue un rôle.
-- Réservé à un admin de la bibliothèque (ou app-admin). L'invité doit s'être connecté
-- au moins une fois (compte existant) ; sinon retourne 'not_found'.
create or replace function public.invite_member(p_library text, p_email text, p_role text default 'viewer')
returns text language plpgsql security definer set search_path = public as $$
declare v_uid uuid;
begin
  if not (public.member_role(p_library) = 'admin' or public.is_app_admin()) then
    raise exception 'not allowed';
  end if;
  if p_role not in ('viewer','editor','admin') then p_role := 'viewer'; end if;
  select id into v_uid from auth.users where lower(email) = lower(trim(p_email));
  if v_uid is null then return 'not_found'; end if;
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
language sql security definer set search_path = public as $$
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
returns trigger language plpgsql as $$
begin if new.updated_at is null or new.updated_at > now() then new.updated_at = now(); end if; return new; end;
$$;
drop trigger if exists fiches_clamp_updated   on public.fiches;
drop trigger if exists catsets_clamp_updated  on public.category_sets;
create trigger fiches_clamp_updated  before insert or update on public.fiches        for each row execute function public.clamp_updated_at();
create trigger catsets_clamp_updated before insert or update on public.category_sets for each row execute function public.clamp_updated_at();

-- ---------- 5quinquies. Suppression de son propre compte (RGPD) --------------
-- Efface les DONNÉES PERSONNELLES (fiches + catégories perso) puis le compte lui-même.
-- Les memberships et app_admins partent en cascade avec auth.users. Les fiches que l'utilisateur
-- a ajoutées à des bibliothèques PARTAGÉES y restent (contenu collectif de l'équipe).
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth as $$
declare uid uuid := auth.uid();
begin
  if uid is null then raise exception 'not authenticated'; end if;
  delete from public.fiches        where owner = uid and library_id is null;
  delete from public.category_sets where owner = uid and library_id is null;
  delete from auth.users where id = uid;   -- cascade -> memberships, app_admins, sessions…
end; $$;
grant execute on function public.delete_my_account() to authenticated;

-- ---------- 6. Recharge du cache PostgREST ----------------------------------
notify pgrst, 'reload schema';

-- ============================================================================
--  APRÈS EXÉCUTION — pour vous nommer app-admin (créateur de bibliothèques) :
--    1) Connectez-vous une première fois dans l'app (pour créer votre compte),
--    2) puis exécutez, en remplaçant l'e-mail :
--       insert into public.app_admins(user_id)
--       select id from auth.users where email = 'vous@exemple.fr';
-- ============================================================================
