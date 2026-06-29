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

-- ---------- 6. Recharge du cache PostgREST ----------------------------------
notify pgrst, 'reload schema';

-- ============================================================================
--  APRÈS EXÉCUTION — pour vous nommer app-admin (créateur de bibliothèques) :
--    1) Connectez-vous une première fois dans l'app (pour créer votre compte),
--    2) puis exécutez, en remplaçant l'e-mail :
--       insert into public.app_admins(user_id)
--       select id from auth.users where email = 'vous@exemple.fr';
-- ============================================================================
