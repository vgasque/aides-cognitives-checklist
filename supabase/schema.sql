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

-- NB : Postgres n'a pas de « create policy if not exists » -> chaque politique est précédée
-- d'un drop if exists pour que schema.sql soit REJOUABLE en entier sur une instance existante.

-- fiches : perso (owner) OU partagé (lecture = membre, écriture = editor/admin)
drop policy if exists fiches_perso on public.fiches;
create policy fiches_perso on public.fiches for all
  using      (library_id is null and owner = auth.uid())
  with check (library_id is null and owner = auth.uid());
drop policy if exists fiches_shared_read on public.fiches;
create policy fiches_shared_read on public.fiches for select
  using (library_id is not null and public.is_member(library_id));
drop policy if exists fiches_shared_write on public.fiches;
create policy fiches_shared_write on public.fiches for all
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
-- GARDE D'APPROBATION (3.3.2) : la validation des comptes (user_status/is_approved) n'était
-- jusqu'ici câblée que sur l'espace PERSO -> un compte en attente ou refusé, une fois invité
-- par un admin de bibliothèque, obtenait quand même un accès lecture/écriture immédiat à une
-- bibliothèque partagée (fiches_shared_write ne teste pas l'approbation). On applique donc ici
-- la MÊME règle que is_approved(), évaluée pour l'INVITÉ (et non l'appelant) : logique dupliquée
-- en ligne plutôt qu'un is_approved(uid) paramétré, pour ne PAS créer de fonction qui permettrait
-- à n'importe quel compte de sonder le statut d'approbation d'un autre (cf. commentaire des
-- helpers SECURITY DEFINER ci-dessus : « aucun paramètre ne permet de lire les droits d'autrui »).
create or replace function public.invite_member(p_library text, p_email text, p_role text default 'viewer')
returns text language plpgsql security definer set search_path = public as $$
declare v_uid uuid; v_status text;
begin
  if not (public.member_role(p_library) = 'admin' or public.is_app_admin()) then
    raise exception 'not allowed';
  end if;
  if p_role not in ('viewer','editor','admin') then p_role := 'viewer'; end if;
  select id into v_uid from auth.users where lower(email) = lower(trim(p_email));
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
-- DÉFENSE EN PROFONDEUR : exige une CONFIRMATION D'IDENTITÉ RÉCENTE — une entrée « amr »
-- (authentication method reference, posée par GoTrue dans le JWT) de type otp/magiclink datant
-- de moins de 10 minutes. Un jeton de session volé ne suffit donc pas, même rafraîchi (le
-- refresh conserve l'amr et son horodatage d'origine) : il faut avoir saisi un code reçu sur
-- la boîte mail du compte juste avant. C'est le pendant serveur du parcours de l'app
-- (SUPPRIMER -> code OTP -> suppression) ; toute anomalie de claim bloque (fail-closed).
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth as $$
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
  delete from public.fiches        where owner = uid and library_id is null;
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
returns trigger language plpgsql security definer set search_path = public as $$
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
create or replace function public.is_approved()
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_app_admin()
    or not coalesce((select require_approval from public.app_settings limit 1), true)
    or coalesce((select status from public.user_status where user_id = auth.uid()), 'approved') = 'approved';
$$;
grant execute on function public.is_approved() to authenticated;

-- Gate : l'espace PERSO (fiches + catégories) requiert l'approbation. Les bibliothèques
-- partagées sont inchangées (déjà protégées par memberships, qu'un compte pending n'a pas).
drop policy if exists fiches_perso on public.fiches;
create policy fiches_perso on public.fiches for all
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
create table if not exists public.fiche_notes (
  user_id    uuid not null references auth.users on delete cascade,
  fiche_id   text not null,
  note       text not null default '',
  updated_at timestamptz not null default now(),
  primary key (user_id, fiche_id)
);
alter table public.fiche_notes enable row level security;
drop policy if exists notes_own on public.fiche_notes;
create policy notes_own on public.fiche_notes for all
  using      (user_id = auth.uid() and public.is_approved())
  with check (user_id = auth.uid() and public.is_approved());
grant select, insert, update, delete on public.fiche_notes to authenticated;
-- Même anti-postdatage que fiches/category_sets (last-write-wins non trichable).
drop trigger if exists notes_clamp_updated on public.fiche_notes;
create trigger notes_clamp_updated before insert or update on public.fiche_notes
  for each row execute function public.clamp_updated_at();

-- Statut du compte courant (le client l'appelle juste après la vérification OTP, puis à chaque
-- synchro) : reflète EXACTEMENT is_approved() (si la validation est désactivée globalement, ou si
-- aucune ligne n'existe -> 'approved', pour ne jamais afficher "en attente" à quelqu'un dont la
-- synchro fonctionne déjà réellement).
create or replace function public.my_status()
returns text language sql stable security definer set search_path = public as $$
  select case
    when public.is_app_admin() then 'approved'
    when not coalesce((select require_approval from public.app_settings limit 1), true) then 'approved'
    else coalesce((select status from public.user_status where user_id = auth.uid()), 'approved')
  end;
$$;
grant execute on function public.my_status() to authenticated;

-- Lecture/écriture de l'interrupteur (écran « Comptes en attente »). Lecture ouverte à tout
-- utilisateur connecté (ne révèle rien de sensible) ; écriture réservée à l'app-admin.
create or replace function public.get_approval_required()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select require_approval from public.app_settings limit 1), true);
$$;
grant execute on function public.get_approval_required() to authenticated;

create or replace function public.set_approval_required(p_value boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_app_admin() then raise exception 'not allowed'; end if;
  update public.app_settings set require_approval = p_value where id = true;
end;$$;
grant execute on function public.set_approval_required(boolean) to authenticated;

-- Comptes pending/rejected (app-admin uniquement ; vide sinon) -> écran « Comptes en attente ».
create or replace function public.list_unapproved_users()
returns table(user_id uuid, email text, status text, created_at timestamptz)
language sql security definer set search_path = public as $$
  select s.user_id, s.email, s.status, s.created_at from public.user_status s
  where s.status in ('pending','rejected') and public.is_app_admin()
  order by s.created_at;
$$;
grant execute on function public.list_unapproved_users() to authenticated;

-- Approuver / refuser (app-admin uniquement). Un app-admin ne peut pas être rétrogradé
-- par erreur (protège contre un clic malheureux sur son propre compte).
create or replace function public.set_user_status(p_user uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
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

-- Supprime DÉFINITIVEMENT un compte REFUSÉ (app-admin uniquement) : donne une "2e chance" à la
-- personne, qui pourra recréer un compte avec la même adresse e-mail (nouvelle demande, repartant
-- de "pending" via le trigger on_auth_user_created). Restreint volontairement aux comptes rejected
-- (pas pending/approved) -> pas d'usage détourné pour supprimer n'importe quel compte via cette RPC.
create or replace function public.delete_rejected_user(p_user uuid)
returns void language plpgsql security definer set search_path = public, auth as $$
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
  alter table public.fiches add constraint fiches_data_size_chk
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
returns jsonb language sql stable security definer set search_path = public, auth as $$
  select case when not public.is_app_admin() then null else jsonb_build_object(
    'users',        (select count(*) from auth.users),
    'pending',      (select count(*) from public.user_status where status = 'pending'),
    'rejected',     (select count(*) from public.user_status where status = 'rejected'),
    'libraries',    (select count(*) from public.libraries),
    'fiches_perso', (select count(*) from public.fiches where library_id is null and deleted_at is null),
    'fiches_shared',(select count(*) from public.fiches where library_id is not null and deleted_at is null),
    'storage_bytes',(select coalesce(sum(octet_length(data::text)),0) from public.fiches where deleted_at is null)
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

-- La suppression de compte (RGPD) emporte aussi les protocoles perso.
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth as $$
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
  delete from public.fiches        where owner = uid and library_id is null;
  delete from public.protocols     where owner = uid and library_id is null;
  delete from public.category_sets where owner = uid and library_id is null;
  -- Documents PDF perso du bucket : rendus inaccessibles par la RLS dès la suppression du compte ;
  -- leurs objets orphelins remontent dans list_orphan_attachments() (purge manuelle app-admin).
  delete from auth.users where id = uid;   -- cascade -> memberships, app_admins, sessions…
end; $$;

-- État de l'instance : RE-CRÉÉE ici (après la table protocols, qu'une fonction SQL ne peut
-- référencer avant sa création) avec les compteurs de protocoles et le poids du bucket.
create or replace function public.get_instance_stats()
returns jsonb language sql stable security definer set search_path = public, auth as $$
  select case when not public.is_app_admin() then null else jsonb_build_object(
    'users',        (select count(*) from auth.users),
    'pending',      (select count(*) from public.user_status where status = 'pending'),
    'rejected',     (select count(*) from public.user_status where status = 'rejected'),
    'libraries',    (select count(*) from public.libraries),
    'fiches_perso', (select count(*) from public.fiches where library_id is null and deleted_at is null),
    'fiches_shared',(select count(*) from public.fiches where library_id is not null and deleted_at is null),
    'protocols',    (select count(*) from public.protocols where deleted_at is null),
    'storage_bytes',(select coalesce(sum(octet_length(data::text)),0) from public.fiches where deleted_at is null)
                    + (select coalesce(sum(octet_length(data::text)),0) from public.category_sets)
                    + (select coalesce(sum(octet_length(data::text)),0) from public.protocols where deleted_at is null),
    'attachments_bytes',(select coalesce(sum((o.metadata->>'size')::bigint),0)
                         from storage.objects o where o.bucket_id = 'attachments')
  ) end;
$$;

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
-- logique que fiches : un compte non approuvé n'obtient pas de membership, cf. invite_member).
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
language sql stable security definer set search_path = public, storage as $$
  select o.name, coalesce((o.metadata->>'size')::bigint, 0), o.created_at
  from storage.objects o
  where o.bucket_id = 'attachments'
    and public.is_app_admin()
    and substring(o.name from '([A-Za-z0-9_-]{1,64})\.pdf$') not in (
      select a->>'id'
      from public.fiches f, jsonb_array_elements(coalesce(f.data->'attachments','[]'::jsonb)) a
      where f.deleted_at is null
      union
      select a->>'id'
      from public.protocols p, jsonb_array_elements(coalesce(p.data->'attachments','[]'::jsonb)) a
      where p.deleted_at is null)
  order by o.created_at;
$$;
grant execute on function public.list_orphan_attachments() to authenticated;

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
