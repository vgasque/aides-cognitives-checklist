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
--  Création de bibliothèque : app-admins (table app_admins, gérée au dashboard), plus, depuis v5.51,
--  les personnes autorisées ou tout compte approuvé selon la règle d'instance (§ 9) ; les autres
--  demandent (§ 9bis). La sécurité réelle = ces politiques RLS, jamais le client.
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

-- libraries : lecture = membre ou app-admin ; création = app-admin (réécrite au § 9 : règle d'instance, v5.51) ;
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
-- A663 : la politique reste « for all », mais le GRANT (§ 5) ne laisse plus que DELETE et UPDATE(role) en
-- direct — l'ajout d'un membre passe par `invite_member`, qui vérifie l'e-mail et l'approbation.
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
-- A663 — memberships : plus d'INSERT ni d'UPDATE libre en direct. Un administrateur de bibliothèque
-- pouvait y inscrire N'IMPORTE QUEL compte (jamais confirmé, en attente, refusé) par un POST, ou en
-- réécrivant `user_id` d'une ligne par un PATCH : le contrôle `not_approved` d'`invite_member` (§ 5bis)
-- ne tenait que si l'on passait par elle. Le client ne fait que DELETE (retirer) et PATCH {role}.
-- `revoke` d'abord : un `grant` rejoué ne retire pas un droit déjà accordé.
revoke insert, update on public.memberships from authenticated;
grant select, delete, update (role) on public.memberships to authenticated;
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
  -- A663 : jamais depuis un poste partagé (A647, « membres et rôles : toujours interdit »). La politique
  -- restrictive `memberships_temp_ins` ne couvre pas cette fonction, qui écrit en SECURITY DEFINER.
  if public.link_is_poste() then raise exception 'not allowed'; end if;
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
-- A663 : la fonction est définie UNE fois, plus bas (après la table `sessions`). Elle l'était DEUX fois,
-- et la seconde — celle qui gagne — avait perdu l'effacement du suivi personnel (A613).

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
  decided_by uuid references auth.users on delete set null
);
-- A663 : `decided_by` n'avait aucun `on delete` — supprimer le compte d'un administrateur qui avait
-- approuvé ou refusé quelqu'un levait une violation de clé étrangère. Rejouable : la contrainte est
-- reposée à chaque passage (sur une instance en place, `create table if not exists` ne la changerait pas).
alter table public.user_status drop constraint if exists user_status_decided_by_fkey;
alter table public.user_status add constraint user_status_decided_by_fkey
  foreign key (decided_by) references auth.users on delete set null;

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
-- Seul un app-admin peut changer le statut de quelqu'un (approuver/refuser) — et SEULEMENT par
-- `set_user_status` (A663). La politique d'UPDATE et son grant sont retirés : un PATCH direct contournait
-- les gardes de la fonction (statut d'un autre administrateur, appel depuis un poste partagé, `decided_by`
-- au choix). Le client n'a jamais écrit cette table en direct.
drop policy if exists user_status_write on public.user_status;
revoke insert, update, delete on public.user_status from authenticated;
grant select on public.user_status to authenticated;

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
-- A663 : bornes de taille, comme `aid_followups` — la table n'en avait aucune (un POST direct y posait
-- une note de n'importe quelle taille, sous n'importe quelle clé). Ce sont celles du client : 10 000
-- caractères (`sstr(…,10000)`) et un identifiant d'aide (`SAFE_ID`). NOT VALID : la règle vaut pour toute
-- écriture à venir sans relire l'existant — un rejeu ne peut pas échouer sur une ligne ancienne.
alter table public.aid_notes drop constraint if exists aid_notes_note_len_chk;
alter table public.aid_notes add constraint aid_notes_note_len_chk
  check (char_length(note) <= 10000) not valid;
alter table public.aid_notes drop constraint if exists aid_notes_fiche_id_chk;
alter table public.aid_notes add constraint aid_notes_fiche_id_chk
  check (char_length(fiche_id) between 1 and 64 and fiche_id !~ '[^A-Za-z0-9_-]') not valid;
-- Même anti-postdatage que fiches/category_sets (last-write-wins non trichable).
drop trigger if exists notes_clamp_updated on public.aid_notes;
create trigger notes_clamp_updated before insert or update on public.aid_notes
  for each row execute function public.clamp_updated_at();

-- ---------- A613 : SUIVI — notes et tâches sur une aide ou une référence -------------------------
-- Une ligne = UNE note ou UNE tâche, attachée à une entité (`entity_id`). Deux portées :
--   • library_id NULL  = « pour moi » : seul son auteur la lit et l'écrit (comme aid_notes) ;
--   • library_id posé  = « pour l'équipe » : lue par les membres de la bibliothèque, écrite par ses
--     éditeurs et administrateurs — TOUS, pas seulement l'auteur (décision de l'auteur, A613).
-- Une ligne par objet (et non un document par bibliothèque, comme category_sets) : deux éditeurs qui
-- notent en même temps ne s'écrasent pas — le dernier-écrit-gagne vaut PAR NOTE, pas pour toutes.
-- L'HISTORIQUE est gardé : une tâche faite reste (done_at, done_by) ; une suppression est un drapeau
-- (`deleted`), pour que la synchro incrémentale la propage. Aucun texte libre ne sert de clé.
-- `owner` = l'auteur ; ON DELETE SET NULL : supprimer son compte n'efface pas une note d'ÉQUIPE
-- (elle appartient à l'équipe), ses notes PERSO sont effacées par delete_my_account.
create table if not exists public.aid_followups (
  id          text primary key check (char_length(id) between 1 and 64 and id !~ '[^A-Za-z0-9_-]'),
  owner       uuid default auth.uid() references auth.users on delete set null,
  library_id  text references public.libraries on delete cascade,      -- NULL = pour moi
  entity_id   text not null check (char_length(entity_id) between 1 and 64 and entity_id !~ '[^A-Za-z0-9_-]'),
  kind        text not null check (kind in ('note','task')),
  body        text not null default '' check (char_length(body) <= 2000),
  task        jsonb check (task is null or octet_length(task::text) <= 2000),
  author      text not null default '' check (char_length(author) <= 160),
  deleted     boolean not null default false,
  updated_at  timestamptz not null default now()
);
create index if not exists followups_updated_idx on public.aid_followups (updated_at);
create index if not exists followups_library_idx on public.aid_followups (library_id);
alter table public.aid_followups enable row level security;
drop policy if exists fu_perso on public.aid_followups;
create policy fu_perso on public.aid_followups for all
  using      (library_id is null and owner = auth.uid() and public.is_approved())
  with check (library_id is null and owner = auth.uid() and public.is_approved());
drop policy if exists fu_shared_read on public.aid_followups;
create policy fu_shared_read on public.aid_followups for select
  using (library_id is not null and public.is_member(library_id));
drop policy if exists fu_shared_write on public.aid_followups;
create policy fu_shared_write on public.aid_followups for all
  using      (library_id is not null and public.member_role(library_id) in ('editor','admin'))
  with check (library_id is not null and public.member_role(library_id) in ('editor','admin'));
grant select, insert, update, delete on public.aid_followups to authenticated;
drop trigger if exists followups_clamp_updated on public.aid_followups;
create trigger followups_clamp_updated before insert or update on public.aid_followups
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
  if not public.is_app_admin() or public.link_is_poste() then raise exception 'not allowed'; end if;
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
-- l'UPDATE exécuté par cette fonction, mais AUSSI sur une édition au dashboard (l'UPDATE direct
-- par l'API REST n'existe plus, A663).
create or replace function public.set_user_status(p_user uuid, p_status text)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not public.is_app_admin() or public.link_is_poste() then raise exception 'not allowed'; end if;
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
-- 'approved', quel que soit le chemin d'écriture (RPC set_user_status ci-dessus, édition au
-- dashboard). Le trigger couvre aussi l'INSERT
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
  if not public.is_app_admin() or public.link_is_poste() then raise exception 'not allowed'; end if;
  if not exists(select 1 from public.user_status where user_id = p_user and status = 'rejected') then
    raise exception 'user is not in rejected status';
  end if;
  -- A663 : ses données partent avec lui. Sans cela, aides, protocoles, catégories, suivi, sessions et
  -- partages de l'`owner` restaient en base, orphelins et illisibles par quiconque (`owner` n'est pas
  -- une clé étrangère) — un compte « supprimé définitivement » dont rien n'était effacé.
  perform public.purge_user_data(p_user);
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
-- A663 : définie UNE fois, au § 8 (après les tables du partage, qu'elle compte) — elle l'était trois fois,
-- les deux premières n'existant que pour être remplacées plus bas.

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

-- ---------- SUPPRESSION D'UN COMPTE : ce qui part avec lui (A663) ----------------------------------
-- UNE liste, tenue à UN endroit, appelée par les deux fonctions qui suppriment un compte
-- (`delete_my_account` ci-dessous, `delete_rejected_user` au § 6bis). Elles en avaient chacune une, et
-- elles divergeaient : la première avait perdu le suivi personnel (A613), la seconde n'effaçait rien.
-- Les contenus versés dans une bibliothèque PARTAGÉE restent (contenu collectif de l'équipe), comme
-- les notes de suivi d'équipe (`owner` y passe à NULL). AUCUN grant : appelée par les seules fonctions
-- SECURITY DEFINER — elle prend une identité en paramètre, aucun client ne doit l'atteindre.
create or replace function public.purge_user_data(p_uid uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if p_uid is null then return; end if;
  delete from public.cognitive_aids where owner = p_uid and library_id is null;
  delete from public.protocols      where owner = p_uid and library_id is null;
  delete from public.category_sets  where owner = p_uid and library_id is null;
  delete from public.aid_followups  where owner = p_uid and library_id is null;   -- A613 : le suivi perso
  delete from public.aid_notes      where user_id = p_uid;
  -- PARTAGES DE SESSION — suppression EXPLICITE, et non « par cascade ». Deux raisons, chacune
  -- suffisante : (1) `session_participants.user_id` référence `auth.users`, donc sans cette ligne
  -- la cascade partirait de l'utilisateur et pourrait laisser des partages orphelins dont
  -- l'`owner` n'existe plus ; (2) surtout, une contrainte non satisfaite lèverait ici une
  -- `foreign_key_violation` — et comme tout ce corps plpgsql est UNE SEULE transaction, la
  -- fonction entière serait annulée : le droit à l'effacement disparaîtrait purement et
  -- simplement pour quiconque a partagé une session ne serait-ce qu'une fois.
  delete from public.shared_sessions where owner = p_uid;   -- cascade -> participants, events
  -- L'historique synchronisé s'efface avec le compte, explicitement : `owner` n'est pas une clé
  -- étrangère, les lignes survivraient au compte.
  delete from public.sessions where owner = p_uid;
  -- Documents PDF perso du bucket : rendus inaccessibles par la RLS dès la suppression du compte ;
  -- leurs objets orphelins remontent dans list_orphan_attachments() (purge manuelle app-admin).
end; $$;
revoke execute on function public.purge_user_data(uuid) from public, anon, authenticated;

-- Suppression de son propre compte (RGPD) — la SEULE définition (en-tête et gardes : § 5quinquies).
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth, pg_temp as $$
declare
  uid    uuid  := auth.uid();
  claims jsonb := coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb;
begin
  if uid is null then raise exception 'not authenticated'; end if;
  -- A643 (revue de sécurité) : JAMAIS depuis un poste partagé. Sa session vient d'un lien de
  -- connexion (amr « magiclink » récent) : sans ce refus, elle passait la garde « code e-mail
  -- saisi il y a moins de 10 min » sans que personne n'ait reçu de code.
  if public.link_is_poste() then raise exception 'not from a shared device'; end if;
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
  perform public.purge_user_data(uid);     -- AVANT la ligne `auth.users` (A663 : une seule liste)
  delete from auth.users where id = uid;   -- cascade -> memberships, app_admins, user_status…
end; $$;
grant execute on function public.delete_my_account() to authenticated;

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
-- A663 — CE QUE L'HÔTE ÉCRIT EN DIRECT EST BORNÉ À SES TROIS GESTES. Les politiques étaient « for all »
-- et le grant complet : un hôte pouvait donc, par un appel REST, contourner tout ce que `share_open`
-- garantit — INSERT d'un partage sans liste blanche (`fiche_snap` entier), sans plafond ni durée
-- bornée, avec un `code_hash` de son choix ; UPDATE de `label` (texte libre affiché chez tous, règle 15)
-- ou de `secret_hash` d'un participant. Le client ne fait que trois PATCH : couper un invité
-- (`revoked_at`), poser un rôle (`role`), terminer (`status`, `expires_at`). Donc : lecture, et UPDATE
-- de ces QUATRE colonnes seulement (grant par colonne, plus bas) ; ni INSERT ni DELETE. Et terminer ne
-- peut que CLORE : jamais rouvrir (`status <> 'active'`), jamais repousser l'expiration au-delà des
-- 12 h de `share_open` — la purge, donc la durée écrite au registre RGPD, en dépend. La borne est
-- large à dessein : l'heure vient de l'horloge du CLIENT, un refus pour dix minutes d'avance
-- laisserait un partage ouvert.
drop policy if exists shared_own on public.shared_sessions;
create policy shared_own on public.shared_sessions for select
  using (owner = auth.uid() and public.is_approved());
drop policy if exists shared_own_upd on public.shared_sessions;
create policy shared_own_upd on public.shared_sessions for update
  using      (owner = auth.uid() and public.is_approved())
  with check (owner = auth.uid() and public.is_approved()
              and status <> 'active' and expires_at <= now() + interval '12 hours');
drop policy if exists sparts_own on public.session_participants;
create policy sparts_own on public.session_participants for select
  using (exists (select 1 from public.shared_sessions s
                  where s.id = share_id and s.owner = auth.uid() and public.is_approved()));
drop policy if exists sparts_own_upd on public.session_participants;
create policy sparts_own_upd on public.session_participants for update
  using      (exists (select 1 from public.shared_sessions s
                       where s.id = share_id and s.owner = auth.uid() and public.is_approved()))
  with check (exists (select 1 from public.shared_sessions s
                       where s.id = share_id and s.owner = auth.uid() and public.is_approved()));
drop policy if exists sevents_own on public.session_events;
create policy sevents_own on public.session_events for select
  using (exists (select 1 from public.shared_sessions s
                  where s.id = share_id and s.owner = auth.uid() and public.is_approved()));

-- `revoke` d'abord (A663) : un `grant` rejoué ne retire pas un droit déjà accordé — et un `revoke
-- update` de table emporte aussi les droits par colonne, d'où le `grant` qui suit.
revoke insert, update, delete on public.shared_sessions      from authenticated;
revoke insert, update, delete on public.session_participants from authenticated;
grant select, update (status, expires_at) on public.shared_sessions      to authenticated;
grant select, update (revoked_at, role)   on public.session_participants to authenticated;
grant select                              on public.session_events       to authenticated;

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
    -- `session_participants`, que la politique `sparts_own_upd` réserve déjà au propriétaire du
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
    -- `sig` (v5.14.5, M9 « secours chaud ») : descripteurs du canal de secours pair-à-pair
    -- (offre/réponse compactées), échangés PENDANT que le relais fonctionne pour que la perte
    -- d'internet ne coupe pas le partage. Ouvert aux deux rôles (l'invité PROPOSE, l'hôte
    -- RÉPOND) ; ignoré par les plis et les comptes-rendus ; purgé avec le reste.
    when p_kind in ('check','verify','gap','counter','timer_arm','timer_stop','mark','mark_void',
                    'nav','flow_end','cx','presence','detach','offline_mark','handoff','sig')
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
  -- A663 : `link_dead()` — un poste DÉCONNECTÉ (ou à l'heure de fin passée) n'ouvre plus de partage. Son
  -- jeton vit encore jusqu'à 900 s (A655) et les politiques `*_link_dead` ne couvrent que les tables.
  -- La garde est ICI et dans `share_admit`, pas dans `is_approved()` : les politiques `shared_own*`
  -- l'appellent, et ce même poste doit pouvoir TERMINER le partage de sa session en cours (règle 11).
  if auth.uid() is null or not public.is_approved() or public.link_dead() then
    return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  -- Validation SANS ancre de regex (« longueur » + « aucun caractère interdit ») : plus lisible,
  -- et cela évite un « $ » isolé dans le fichier, que le garde-fou check-sql.mjs doit pouvoir
  -- lire comme la signature d'un délimiteur mutilé sans avoir à faire d'exception.
  -- `p_session_id` est borné de la même façon que `p_id` : c'était le SEUL champ texte de la table
  -- sans aucune contrainte, et il est destiné à devenir une clé de jointure vers l'historique.
  if p_id is null or length(p_id) not between 1 and 64 or p_id ~ '[^A-Za-z0-9_-]'
     or p_session_id is null or length(p_session_id) not between 1 and 64
     or p_session_id ~ '[^A-Za-z0-9_-]'
     -- A663 : `p_fiche_id` aussi (l'identifiant d'une aide, `SAFE_ID` côté client) — il restait sans borne.
     or p_fiche_id is null or length(p_fiche_id) not between 1 and 64 or p_fiche_id ~ '[^A-Za-z0-9_-]'
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
  if auth.uid() is null or public.link_dead() then   -- A663 : ni un poste déconnecté (cf. share_open)
    return jsonb_build_object('ok', false, 'err', 'refused'); end if;
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
                                         'nav','navSeq','on','exo','ref','was','to','take',
                                         /* v5.14.14 — clés du secours chaud (A216) : la v5.14.5
                                            a ajouté le GENRE `sig` sans étendre CETTE liste —
                                            le serveur amputait `o` (offre) et `a` (réponse), et
                                            l'appariement silencieux mourait en silence. `code`
                                            ne voyage que sur le hub local (billet gc), listé ici
                                            pour la PARITÉ stricte avec SHARE_PAYLOAD_KEYS,
                                            gardée par check-sql. */
                                         'o','a','code')),
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

-- ---------- État de l'instance (app-admin) : tableau de bord léger ---------------------------
-- Définie ICI et nulle part ailleurs (A663 : elle l'était trois fois) : une fonction `language sql`
-- est intégralement résolue À SA CRÉATION, elle ne peut donc pas référencer une table déclarée plus
-- bas dans le fichier (`42P01: relation … does not exist`) — or elle compte les tables du partage.
-- Les fonctions `language plpgsql` échappent à cette contrainte : leur corps n'est analysé qu'à la
-- première exécution — c'est pourquoi `purge_user_data` peut citer ces tables depuis plus haut.
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

-- ---------- 9. CRÉER UNE BIBLIOTHÈQUE : QUI EN A LE DROIT (v5.51, A478) -------------------------
-- Une bibliothèque sert à PARTAGER : sa création reste gouvernée. Règle d'instance
-- `app_settings.library_creation` : 'admins' (administrateurs seulement), 'creators' (+ personnes
-- autorisées, `library_creators`), 'approved' (tout compte approuvé). Défaut 'creators' avec une liste
-- vide = le comportement d'avant. Les autres DEMANDENT (`library_requests`, § 9bis).
-- Placé ici (après app_settings, is_approved) : une fonction `language sql` résout ses tables à la création.
alter table public.app_settings add column if not exists library_creation text not null default 'creators';
do $$ begin
  alter table public.app_settings add constraint app_settings_library_creation_chk
    check (library_creation in ('admins','creators','approved'));
exception when duplicate_object then null; end $$;

create table if not exists public.library_creators (
  user_id    uuid primary key references auth.users on delete cascade,
  granted_at timestamptz not null default now(),
  granted_by uuid references auth.users on delete set null
);
-- Aucune politique, aucun grant (comme app_admins) : lue par les seules fonctions ci-dessous.
alter table public.library_creators enable row level security;

create or replace function public.can_create_library()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select public.is_app_admin() or (public.is_approved() and
    case coalesce((select library_creation from public.app_settings limit 1), 'creators')
      when 'approved' then true
      when 'creators' then exists (select 1 from public.library_creators where user_id = auth.uid())
      else false end);
$$;
grant execute on function public.can_create_library() to authenticated;

-- Remplace la politique du § 3 (`is_app_admin()` seul). Un non-administrateur ne crée QUE pour lui-même :
-- sans `created_by = auth.uid()`, le trigger lib_add_creator ferait administrateur quelqu'un d'autre.
drop policy if exists lib_insert on public.libraries;
create policy lib_insert on public.libraries for insert
  with check (public.is_app_admin() or (public.can_create_library() and created_by = auth.uid()));

-- Réglage (administrateur seulement).
create or replace function public.get_library_creation()
returns text language sql stable security definer set search_path = public, pg_temp as $$
  select case when public.is_app_admin()
    then coalesce((select library_creation from public.app_settings limit 1), 'creators') end;
$$;
grant execute on function public.get_library_creation() to authenticated;

create or replace function public.set_library_creation(p_mode text)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not public.is_app_admin() or public.link_is_poste() then raise exception 'not allowed'; end if;
  if p_mode not in ('admins','creators','approved') then raise exception 'invalid mode'; end if;
  update public.app_settings set library_creation = p_mode where id = true;
end;$$;
grant execute on function public.set_library_creation(text) to authenticated;

-- Comptes approuvés, pour choisir les personnes autorisées (administrateur seulement ; vide sinon).
create or replace function public.list_users()
returns table(user_id uuid, email text, is_admin boolean, can_create boolean)
language sql stable security definer set search_path = public, pg_temp as $$
  select s.user_id, s.email,
         exists (select 1 from public.app_admins a where a.user_id = s.user_id),
         exists (select 1 from public.library_creators c where c.user_id = s.user_id)
  from public.user_status s
  where s.status = 'approved' and public.is_app_admin()
  order by lower(s.email);
$$;
grant execute on function public.list_users() to authenticated;

create or replace function public.set_library_creator(p_user uuid, p_on boolean)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not public.is_app_admin() or public.link_is_poste() then raise exception 'not allowed'; end if;
  if p_on then
    insert into public.library_creators(user_id, granted_by) values (p_user, auth.uid())
      on conflict (user_id) do nothing;
  else
    delete from public.library_creators where user_id = p_user;
  end if;
end;$$;
grant execute on function public.set_library_creator(uuid, boolean) to authenticated;

-- ---------- 9bis. DEMANDER UNE BIBLIOTHÈQUE (v5.51, A479) -----------------------------------------
-- Qui n'a pas le droit DEMANDE : nom, personnes à inviter (e-mails) et leur rôle. L'administrateur
-- crée pour lui — le demandeur devient administrateur de la bibliothèque (trigger lib_add_creator) et
-- les invités sont ajoutés par `invite_member`. Données personnelles : les e-mails des invités, gardés
-- jusqu'à la décision seulement (acceptée : ligne supprimée ; refusée : liste vidée). Registre § 3.
create table if not exists public.library_requests (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users on delete cascade,
  name       text not null check (char_length(btrim(name)) between 1 and 60),
  invitees   jsonb not null default '[]'::jsonb
             check (jsonb_typeof(invitees) = 'array' and jsonb_array_length(invitees) <= 20),
  role       text not null default 'editor' check (role in ('viewer','editor','admin')),
  status     text not null default 'pending' check (status in ('pending','rejected')),
  created_at timestamptz not null default now(),
  decided_at timestamptz
);
-- Aucune politique, aucun grant : accès par les fonctions ci-dessous seulement.
alter table public.library_requests enable row level security;

create or replace function public.request_library(p_name text, p_invitees jsonb default '[]'::jsonb, p_role text default 'editor')
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_id uuid; v_inv jsonb;
begin
  if auth.uid() is null or not public.is_approved() then raise exception 'not allowed'; end if;
  if public.link_is_poste() then raise exception 'not allowed'; end if;   -- A663 : ni demander, depuis un poste (A647)
  if public.can_create_library() then raise exception 'can_create'; end if;
  if char_length(btrim(coalesce(p_name, ''))) not between 1 and 60 then raise exception 'invalid name'; end if;
  if (select count(*) from public.library_requests where user_id = auth.uid() and status = 'pending') >= 3 then
    raise exception 'too_many';
  end if;
  select coalesce(jsonb_agg(distinct lower(btrim(e))), '[]'::jsonb) into v_inv
    from jsonb_array_elements_text(case when jsonb_typeof(p_invitees) = 'array' then p_invitees else '[]'::jsonb end) e
    -- une adresse : un seul @, un point après, aucun blanc (sans ancre « $ », que check-sql lirait comme un délimiteur)
    where char_length(e) <= 254 and btrim(e) like '_%@_%._%' and btrim(e) !~ '[[:space:]]'
      and char_length(btrim(e)) - char_length(replace(btrim(e), '@', '')) = 1;
  if jsonb_array_length(v_inv) > 20 then raise exception 'too_many_invitees'; end if;
  insert into public.library_requests(user_id, name, invitees, role)
    values (auth.uid(), btrim(p_name), v_inv, case when p_role in ('viewer','editor','admin') then p_role else 'editor' end)
    returning id into v_id;
  return v_id;
end;$$;
grant execute on function public.request_library(text, jsonb, text) to authenticated;

create or replace function public.my_library_requests()
returns table(id uuid, name text, status text, invitees int, created_at timestamptz, decided_at timestamptz)
language sql stable security definer set search_path = public, pg_temp as $$
  select r.id, r.name, r.status, jsonb_array_length(r.invitees), r.created_at, r.decided_at
  from public.library_requests r where r.user_id = auth.uid()
  order by r.created_at desc;
$$;
grant execute on function public.my_library_requests() to authenticated;

-- Annuler une demande en attente, ou effacer une demande refusée : les siennes seulement.
create or replace function public.cancel_library_request(p_id uuid)
returns void language sql security definer set search_path = public, pg_temp as $$
  delete from public.library_requests where id = p_id and user_id = auth.uid();
$$;
grant execute on function public.cancel_library_request(uuid) to authenticated;

create or replace function public.list_library_requests()
returns table(id uuid, user_id uuid, email text, name text, invitees jsonb, role text, created_at timestamptz)
language sql stable security definer set search_path = public, pg_temp as $$
  select r.id, r.user_id, u.email::text, r.name, r.invitees, r.role, r.created_at
  from public.library_requests r join auth.users u on u.id = r.user_id
  where r.status = 'pending' and public.is_app_admin()
  order by r.created_at;
$$;
grant execute on function public.list_library_requests() to authenticated;

create or replace function public.decide_library_request(p_id uuid, p_ok boolean)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare r public.library_requests; v_lib text; v_em text; v_me text; v_ok int := 0; v_ko int := 0;
begin
  if not public.is_app_admin() or public.link_is_poste() then raise exception 'not allowed'; end if;
  select * into r from public.library_requests where id = p_id and status = 'pending' for update;
  if not found then return jsonb_build_object('status', 'gone'); end if;
  if not p_ok then
    update public.library_requests set status = 'rejected', decided_at = now(), invitees = '[]'::jsonb where id = p_id;
    return jsonb_build_object('status', 'rejected');
  end if;
  v_lib := 'lib-' || substr(md5(random()::text || clock_timestamp()::text), 1, 12);
  insert into public.libraries(id, name, created_by) values (v_lib, r.name, r.user_id);   -- le demandeur en devient admin
  select lower(email) into v_me from auth.users where id = r.user_id;
  for v_em in select jsonb_array_elements_text(r.invitees) loop
    continue when v_em = v_me;   -- jamais de rétrogradation du demandeur par sa propre adresse
    if public.invite_member(v_lib, v_em, r.role) = 'ok' then v_ok := v_ok + 1; else v_ko := v_ko + 1; end if;
  end loop;
  delete from public.library_requests where id = p_id;
  return jsonb_build_object('status', 'created', 'library', v_lib, 'invited', v_ok, 'not_invited', v_ko);
end;$$;
grant execute on function public.decide_library_request(uuid, boolean) to authenticated;

-- ---------- 9ter. ADMINISTRATION DE L'INSTANCE : comptes et bibliothèques (v5.52, A483) ----------
-- L'administrateur de l'instance VOIT tout (lib_select, mem_select le permettaient déjà) et gère les
-- membres de toute bibliothèque (mem_write) ; il lui manquait les VUES d'ensemble. Lecture seule ici :
-- les gestes passent par les politiques et RPC existantes (invite_member, memberships, set_user_status,
-- set_library_creator, delete_rejected_user). Toutes vides pour qui n'est pas administrateur.
create or replace function public.list_accounts()
returns table(user_id uuid, email text, status text, is_admin boolean, can_create boolean, libraries int, created_at timestamptz)
language sql stable security definer set search_path = public, pg_temp as $$
  select s.user_id, s.email, s.status,
         exists (select 1 from public.app_admins a where a.user_id = s.user_id),
         exists (select 1 from public.library_creators c where c.user_id = s.user_id),
         (select count(*)::int from public.memberships m where m.user_id = s.user_id),
         s.created_at
  from public.user_status s
  where public.is_app_admin()
  order by lower(s.email);
$$;
grant execute on function public.list_accounts() to authenticated;

create or replace function public.list_user_memberships(p_user uuid)
returns table(library_id text, name text, role text)
language sql stable security definer set search_path = public, pg_temp as $$
  select m.library_id, l.name, m.role
  from public.memberships m join public.libraries l on l.id = m.library_id
  where m.user_id = p_user and public.is_app_admin()
  order by lower(l.name);
$$;
grant execute on function public.list_user_memberships(uuid) to authenticated;

create or replace function public.list_all_libraries()
returns table(id text, name text, creator text, created_at timestamptz, members int, admins int, aids int, protocols int)
language sql stable security definer set search_path = public, pg_temp as $$
  select l.id, l.name, u.email::text, l.created_at,
         (select count(*)::int from public.memberships m where m.library_id = l.id),
         (select count(*)::int from public.memberships m where m.library_id = l.id and m.role = 'admin'),
         (select count(*)::int from public.cognitive_aids f where f.library_id = l.id and f.deleted_at is null),
         (select count(*)::int from public.protocols p where p.library_id = l.id and p.deleted_at is null)
  from public.libraries l left join auth.users u on u.id = l.created_by
  where public.is_app_admin()
  order by lower(l.name);
$$;
grant execute on function public.list_all_libraries() to authenticated;

-- ---------- 9quater. AU MOINS UN ADMINISTRATEUR PAR BIBLIOTHÈQUE, ET LA QUITTER (A663) -----------
-- Rien n'empêchait de rétrograder ou de retirer le DERNIER administrateur d'une bibliothèque (un PATCH
-- sur son propre rôle suffisait) : elle restait utilisable, mais plus personne — hors administrateur de
-- l'instance — ne pouvait en gérer les membres. Ce déclencheur refuse ce geste (`last_admin`), quel que
-- soit le chemin : PATCH ou DELETE direct, `invite_member` qui réécrit un rôle, `leave_library`.
-- CE QU'IL NE BLOQUE PAS, et chaque cas est voulu :
--   · la suppression de la BIBLIOTHÈQUE (cascade : la ligne `libraries` n'existe déjà plus) ;
--   · la suppression du COMPTE (cascade depuis `auth.users` : le compte n'existe déjà plus) — le droit à
--     l'effacement ne se négocie pas ; le client avertit avant (« Vous êtes le seul administrateur de… ») ;
--   · un compte qui cesse d'être approuvé (`user_status_revoke_memberships`) : la sécurité l'emporte ;
--   · la maintenance sans jeton (éditeur SQL, clé de service) : même régime que `stamp_updated_by`.
-- Dans ces cas la bibliothèque peut rester sans administrateur ; l'administrateur de l'instance en nomme
-- un (`invite_member`). La ligne `libraries` est verrouillée le temps du contrôle : deux administrateurs
-- qui se rétrogradent l'un l'autre au même instant ne passent pas tous les deux.
create or replace function public.memberships_keep_admin()
returns trigger language plpgsql security definer set search_path = public, auth, pg_temp as $$
begin
  if old.role = 'admin' and auth.uid() is not null
     and (tg_op = 'DELETE' or new.role <> 'admin'
          or new.library_id <> old.library_id or new.user_id <> old.user_id) then
    perform 1 from public.libraries where id = old.library_id for update;
    if found
       and exists (select 1 from auth.users where id = old.user_id)
       and coalesce((select status from public.user_status where user_id = old.user_id), 'approved') = 'approved'
       and not exists (select 1 from public.memberships
                        where library_id = old.library_id and role = 'admin' and user_id <> old.user_id) then
      raise exception 'last_admin';
    end if;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;$$;
drop trigger if exists memberships_keep_admin on public.memberships;
create trigger memberships_keep_admin before update or delete on public.memberships
  for each row execute function public.memberships_keep_admin();
revoke execute on function public.memberships_keep_admin() from public, anon, authenticated;   -- fonction de déclencheur

-- QUITTER une bibliothèque : SA propre adhésion, et elle seule (aucune identité en paramètre). Il n'y
-- avait aucun chemin : `mem_write` réserve le retrait aux administrateurs, un lecteur ou un éditeur ne
-- pouvait donc pas partir. Rend 'ok', 'not_member' ou 'last_admin' (nommer d'abord un autre
-- administrateur) ; refusée depuis un poste partagé (A647 : membres et rôles). Ce qu'il a versé dans la
-- bibliothèque y reste (contenu collectif de l'équipe).
create or replace function public.leave_library(p_library text)
returns text language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if auth.uid() is null or public.link_is_poste() then raise exception 'not allowed'; end if;
  perform 1 from public.libraries where id = p_library for update;
  if not exists (select 1 from public.memberships where user_id = auth.uid() and library_id = p_library) then
    return 'not_member';
  end if;
  if public.member_role(p_library) = 'admin'
     and not exists (select 1 from public.memberships
                      where library_id = p_library and role = 'admin' and user_id <> auth.uid()) then
    return 'last_admin';
  end if;
  delete from public.memberships where user_id = auth.uid() and library_id = p_library;
  return 'ok';
end;$$;
grant execute on function public.leave_library(text) to authenticated;

-- ---------- 9quinquies. INDEX (A663) -------------------------------------------------------------
-- `memberships` n'était indexée que par sa clé (user_id, library_id) : lister ou compter les membres
-- d'une bibliothèque (`list_members`, `list_all_libraries`, le contrôle ci-dessus) la parcourait en
-- entier. Et `owner` n'était indexé nulle part alors que TOUTE politique d'espace personnel filtre
-- dessus (`library_id is null and owner = auth.uid()`), comme la suppression d'un compte.
create index if not exists memberships_library_idx on public.memberships (library_id);
create index if not exists cognitive_aids_owner_idx on public.cognitive_aids (owner);
create index if not exists protocols_owner_idx      on public.protocols (owner);
create index if not exists followups_owner_idx      on public.aid_followups (owner);

-- ============================================================================================
-- ---------- 10. CONNEXION PAR LE TÉLÉPHONE (v5.111, A643) -----------------------------------
-- ============================================================================================
-- Un POSTE PARTAGÉ (l'ordinateur d'un service) se connecte au compte d'un soignant SANS e-mail :
-- il affiche un QR, le téléphone déjà connecté le vise, l'utilisateur touche le nombre de contrôle
-- affiché par le poste et choisit l'heure de fin de sa garde. Le poste reçoit alors SA PROPRE
-- session — jamais celle du téléphone : GoTrue fait tourner le jeton de rafraîchissement, deux
-- appareils sur le même se déconnecteraient l'un l'autre, et l'on ne pourrait plus révoquer le
-- poste seul. Cette session est créée par la fonction serveur `link-claim`
-- (supabase/functions/link-claim), SEULE pièce qui tient la clé de service : GoTrue ne crée pas
-- de session depuis SQL.
-- DEUX SECRETS, DEUX CAPACITÉS (revue de sécurité v5.111, avant publication). Tirés par le poste
-- (crypto.getRandomValues, 128 bits chacun), le serveur n'en garde que les empreintes SHA-256 :
--   · le SECRET DU QR — ce que voit l'écran, donc quiconque le photographie pendant 120 s. Il ne
--     sert qu'au TÉLÉPHONE : lire la demande et l'approuver (`link_peek`, `link_approve`) ;
--   · la CLÉ DU POSTE — jamais affichée, jamais dans le QR. Elle seule ouvre ce que fait le poste :
--     sonder, réclamer, déposer (`link_poll`, `link_claim_srv`, `link_deposit`).
-- La première version n'avait qu'un secret : un tiers qui photographiait le QR pouvait sonder,
-- RÉCLAMER à la place du poste (la réclamation n'était pas atomique) et LIER sa propre session,
-- qui échappait alors à la révocation et à l'heure de fin (démontré sur banc). Aucune fonction ne
-- prend d'identité en paramètre.
-- LA SESSION DU POSTE EST LIÉE PAR LE SERVEUR (`link_bind_srv`, appelée par `link-claim` juste après
-- l'avoir créée), une fois et une seule : c'est ce qui permet de la RECONNAÎTRE (`link_is_poste`)
-- et de lui refuser ce qu'un poste ne doit jamais faire, même par un appel REST direct — approuver
-- ou prolonger un poste (s'enchaîner sans téléphone), gérer les postes, supprimer le compte.
-- DURÉES : la DEMANDE vit 120 s ; la CONNEXION jusqu'à l'heure de fin choisie sur le téléphone
-- (28 h au plus : une garde de 24 h connectée un peu avant son début, et qui déborde) ; le DROIT
-- DE DÉPÔT 7 jours après l'heure de fin (une session terminée hors ligne, ou après l'heure de fin,
-- doit encore pouvoir rejoindre l'historique) ; purge 30 min après chacune de ces échéances.
-- Les deux types : `connect` (le poste devient connecté) et `unlock` (le poste, déjà connecté
-- mais rouvert, redemande le téléphone avant de laisser modifier quoi que ce soit — A643 § verrou).
create table if not exists public.device_links (
  id           uuid primary key default gen_random_uuid(),
  kind         text not null default 'connect' check (kind in ('connect','unlock')),
  secret_hash  text not null check (length(secret_hash) = 64),
  key_hash     text not null check (length(key_hash) = 64),
  ip_hash      text,
  label        text not null default '' check (length(label) <= 60),
  created_at   timestamptz not null default now(),
  open_until   timestamptz not null,
  user_id      uuid references auth.users on delete cascade,
  status       text not null default 'pending'
               check (status in ('pending','approved','claimed','revoked','ended')),
  ends_at      timestamptz,
  approved_at  timestamptz,
  claimed_at   timestamptz,
  auth_session uuid,
  deposits     int not null default 0
);
create index if not exists device_links_user_idx on public.device_links (user_id, status);
create index if not exists device_links_sess_idx on public.device_links (auth_session) where auth_session is not null;
create index if not exists device_links_ip_idx on public.device_links (ip_hash, created_at) where ip_hash is not null;
-- Fonctions dont la SIGNATURE a changé pendant la revue (même lot) : `create or replace` ne remplace
-- pas une signature différente, l'ancienne resterait appelable. Retirées par leur nom exact.
drop function if exists public.link_open(text,text,text);
drop function if exists public.link_bind(uuid,text);
alter table public.device_links enable row level security;
-- AUCUNE politique, AUCUN grant : la table ne se lit et ne s'écrit QUE par les fonctions
-- SECURITY DEFINER ci-dessous (même posture que les tables du partage de session).
revoke all on public.device_links from anon, authenticated;

-- Purge — AUTO-EXÉCUTOIRE, jamais planifiée (même doctrine que `share_purge` : l'hébergement est
-- statique, personne ne lancerait une tâche de ménage). Elle tourne en tête de chaque appel.
-- 1. HEURE DE FIN PASSÉE : la session de compte du poste est SUPPRIMÉE (ses jetons de
--    rafraîchissement partent avec elle). Le poste la ferme déjà lui-même à l'heure dite ; ceci
--    couvre le poste éteint, ou le navigateur jamais rouvert. LIMITE DITE : la suppression a lieu
--    au premier appel `link_*` qui suit l'heure de fin, de n'importe quel poste du serveur — pas
--    à la seconde près.
-- 2. MÉNAGE : demandes jamais abouties, et connexions dont le droit de dépôt a expiré.
-- Un échec sur `auth.sessions` (droits retirés par l'hébergeur) ne bloque JAMAIS l'appel en cours.
create or replace function public.link_purge()
returns void language plpgsql volatile security definer
set search_path = public, auth, pg_temp as $$
declare r record;
begin
  for r in select id, auth_session from public.device_links
            where kind = 'connect' and status = 'claimed' and ends_at < now() limit 50 loop
    if r.auth_session is not null then
      begin delete from auth.sessions where id = r.auth_session;
      exception when others then null; end;
    end if;
    update public.device_links set status = 'ended' where id = r.id;
  end loop;
  delete from public.device_links where id in (
    select id from public.device_links
     where (status in ('pending','approved') and open_until < now() - interval '30 minutes')
        or (kind = 'unlock' and created_at < now() - interval '30 minutes')
        or (kind = 'connect' and ends_at is not null
            and ends_at < now() - interval '7 days 30 minutes')
     limit 100);
end; $$;

-- Lecture d'une demande par son secret. Aucun grant : seules les fonctions de cette section
-- l'appellent. Rend la ligne si — et seulement si — le secret correspond.
create or replace function public.link_row(p_id uuid, p_secret text)
returns public.device_links language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare v public.device_links%rowtype;
begin
  if p_id is null or p_secret is null or length(p_secret) not between 16 and 128 then return null; end if;
  select * into v from public.device_links where id = p_id;
  if not found or encode(digest(p_secret, 'sha256'), 'hex') <> v.secret_hash then return null; end if;
  return v;
end; $$;

-- Même lecture, par la CLÉ DU POSTE (jamais dans le QR). Aucun grant.
create or replace function public.link_row_key(p_id uuid, p_key text)
returns public.device_links language plpgsql stable security definer
set search_path = public, extensions, pg_temp as $$
declare v public.device_links%rowtype;
begin
  if p_id is null or p_key is null or length(p_key) not between 16 and 128 then return null; end if;
  select * into v from public.device_links where id = p_id;
  if not found or encode(digest(p_key, 'sha256'), 'hex') <> v.key_hash then return null; end if;
  return v;
end; $$;

-- La session appelante est-elle celle d'un POSTE PARTAGÉ ? (liée par le serveur, cf. en-tête). Aucun grant.
create or replace function public.link_is_poste()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from public.device_links
                  where auth_session = nullif(auth.jwt() ->> 'session_id', '')::uuid);
$$;

-- OUVERTURE (le poste, sans compte pour `connect`, connecté pour `unlock`). Le poste tire le
-- secret du QR ET sa clé, et n'envoie que leurs empreintes. PLAFOND GLOBAL de demandes ouvertes : la fonction est
-- appelable sans compte (un poste ne l'est pas encore) ; sans borne, une boucle remplirait la
-- table. Une demande vit 120 s, donc le plafond borne le débit d'un abus sans gêner l'usage.
create or replace function public.link_open(p_hash text, p_key_hash text, p_label text, p_kind text)
returns jsonb language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare v_id uuid; v_kind text := coalesce(p_kind, 'connect');
        v_open timestamptz := now() + interval '120 seconds'; v_ip text; v_label text;
begin
  perform public.link_purge();
  if p_hash is null or length(p_hash) <> 64 or p_hash ~ '[^0-9a-f]'
     or p_key_hash is null or length(p_key_hash) <> 64 or p_key_hash ~ '[^0-9a-f]' or p_key_hash = p_hash
     or v_kind not in ('connect','unlock') then
    return jsonb_build_object('ok', false, 'err', 'bad_request'); end if;
  if v_kind = 'unlock' and (auth.uid() is null or not public.is_approved()) then
    return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  -- PLAFOND PAR ADRESSE (empreinte, jamais l'adresse) : un abus depuis une machine ne bloque plus
  -- l'instance entière. Le plafond GLOBAL reste en dernier recours.
  v_ip := split_part(coalesce(current_setting('request.headers', true)::json ->> 'x-forwarded-for', ''), ',', 1);
  v_ip := case when btrim(v_ip) = '' then null else encode(digest('ac-link:' || btrim(v_ip), 'sha256'), 'hex') end;
  if v_ip is not null and (select count(*) from public.device_links
        where ip_hash = v_ip and created_at > now() - interval '10 minutes') >= 20 then
    return jsonb_build_object('ok', false, 'err', 'busy'); end if;
  if (select count(*) from public.device_links where status = 'pending' and open_until > now()) >= 500 then
    return jsonb_build_object('ok', false, 'err', 'busy'); end if;
  -- LE LIBELLÉ EST UNE GRAMMAIRE FERMÉE (celle de `linkUaLabel`) : le téléphone l'affiche comme
  -- l'identité du poste, un texte libre fourni sans compte (« Poste IDE Urgences ») le tromperait.
  -- Deux listes fermées, sans ancre de regex (convention de check-sql : aucun « $ » isolé).
  v_label := coalesce(p_label, '');
  if cardinality(string_to_array(v_label, ' · ')) > 2
     or split_part(v_label, ' · ', 1) not in ('Edge','Firefox','Chrome','Safari','Navigateur')
     or split_part(v_label, ' · ', 2) not in ('','Windows','iPhone','iPad','Android','ChromeOS','macOS','Linux') then
    v_label := 'Navigateur'; end if;
  insert into public.device_links(kind, secret_hash, key_hash, ip_hash, label, open_until, user_id)
    values (v_kind, p_hash, p_key_hash, v_ip, v_label, v_open,
            case when v_kind = 'unlock' then auth.uid() end)
    returning id into v_id;
  return jsonb_build_object('ok', true, 'id', v_id, 'open_until', v_open, 'server_time', now());
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- LE TÉLÉPHONE LIT LA DEMANDE avant d'approuver (le navigateur du poste, l'âge du code). Un
-- `unlock` ne se lit que par SON compte : un téléphone d'un autre compte n'a rien à y faire.
create or replace function public.link_peek(p_id uuid, p_secret text)
returns jsonb language plpgsql volatile security definer
set search_path = public, pg_temp as $$
declare v public.device_links%rowtype;
begin
  perform public.link_purge();
  if auth.uid() is null or not public.is_approved() or public.link_is_poste() then
    return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  v := public.link_row(p_id, p_secret);
  if v.id is null then return jsonb_build_object('ok', false, 'err', 'not_found'); end if;
  if v.status <> 'pending' or v.open_until < now() then
    return jsonb_build_object('ok', false, 'err', 'expired'); end if;
  if v.kind = 'unlock' and v.user_id <> auth.uid() then
    return jsonb_build_object('ok', false, 'err', 'other_account'); end if;
  return jsonb_build_object('ok', true, 'kind', v.kind, 'label', v.label,
    'age_s', floor(extract(epoch from now() - v.created_at)), 'server_time', now());
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- APPROBATION (le téléphone, connecté et approuvé — JAMAIS un poste : il s'enchaînerait sans
-- téléphone). Heure de fin bornée : 30 min à 28 h. PLAFOND : cinq postes connectés à la fois par
-- compte, compté sous VERROU (deux approbations simultanées ne le franchissent pas). « ok » seulement
-- si CETTE approbation a pris (deux téléphones sur le même QR : le second l'apprend).
create or replace function public.link_approve(p_id uuid, p_secret text, p_ends_at timestamptz)
returns jsonb language plpgsql volatile security definer
set search_path = public, pg_temp as $$
declare v public.device_links%rowtype; v_n int;
begin
  perform public.link_purge();
  if auth.uid() is null or not public.is_approved() or public.link_is_poste() then
    return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  v := public.link_row(p_id, p_secret);
  if v.id is null then return jsonb_build_object('ok', false, 'err', 'not_found'); end if;
  if v.status <> 'pending' or v.open_until < now() then
    return jsonb_build_object('ok', false, 'err', 'expired'); end if;
  if v.kind = 'unlock' then
    if v.user_id <> auth.uid() then return jsonb_build_object('ok', false, 'err', 'other_account'); end if;
    update public.device_links set status = 'approved', approved_at = now() where id = v.id and status = 'pending';
    if not found then return jsonb_build_object('ok', false, 'err', 'expired'); end if;
    return jsonb_build_object('ok', true, 'kind', 'unlock');
  end if;
  if p_ends_at is null or p_ends_at < now() + interval '30 minutes' or p_ends_at > now() + public.temp_max_interval() then
    return jsonb_build_object('ok', false, 'err', 'bad_ends'); end if;
  perform pg_advisory_xact_lock(hashtext('link:' || auth.uid()::text));
  select count(*) into v_n from public.device_links
   where user_id = auth.uid() and kind = 'connect' and status in ('approved','claimed') and ends_at > now();
  if v_n >= 5 then return jsonb_build_object('ok', false, 'err', 'too_many'); end if;
  update public.device_links set status = 'approved', approved_at = now(), user_id = auth.uid(), ends_at = p_ends_at
   where id = v.id and status = 'pending';
  if not found then return jsonb_build_object('ok', false, 'err', 'expired'); end if;
  return jsonb_build_object('ok', true, 'kind', 'connect', 'ends_at', p_ends_at);
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- SONDAGE (le poste, par SA clé — le QR ne suffit pas). Rend l'état seul, jamais un jeton.
-- Sert aussi, une fois connecté, à apprendre une PROLONGATION ou une RÉVOCATION décidée sur le
-- téléphone.
drop function if exists public.link_poll(uuid,text);
create or replace function public.link_poll(p_id uuid, p_key text)
returns jsonb language plpgsql volatile security definer
set search_path = public, pg_temp as $$
declare v public.device_links%rowtype; v_st text;
begin
  perform public.link_purge();
  v := public.link_row_key(p_id, p_key);
  if v.id is null then return jsonb_build_object('ok', false, 'err', 'not_found'); end if;
  v_st := case when v.status = 'pending' and v.open_until < now() then 'expired'
               when v.status = 'claimed' and v.ends_at < now() then 'ended'
               else v.status end;
  return jsonb_build_object('ok', true, 'status', v_st, 'ends_at', v.ends_at, 'server_time', now());
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- RÉCLAMATION — par la fonction serveur `link-claim` SEULE (clé de service ; aucun grant client,
-- révoqué explicitement plus bas), avec la CLÉ DU POSTE. ATOMIQUE : `update … returning` — deux
-- réclamations simultanées ne réussissent pas toutes deux. Rejouable 2 min tant qu'aucune session
-- n'est liée (un réseau qui coupe entre la réclamation et la liaison ne laisse pas le poste en
-- impasse ; la liaison, elle, ne prend qu'une fois). Rend l'e-mail du compte — à la fonction
-- serveur seulement, qui le transforme en lien de connexion et ne le renvoie jamais.
drop function if exists public.link_claim_srv(uuid,text);
create or replace function public.link_claim_srv(p_id uuid, p_key text)
returns jsonb language plpgsql volatile security definer
set search_path = public, auth, pg_temp as $$
declare v public.device_links%rowtype; v_mail text; v_uid uuid; v_ends timestamptz;
begin
  perform public.link_purge();
  v := public.link_row_key(p_id, p_key);
  if v.id is null or v.kind <> 'connect' then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  update public.device_links set status = 'claimed', claimed_at = coalesce(claimed_at, now())
   where id = v.id and ((status = 'approved' and approved_at > now() - interval '5 minutes')
                     or (status = 'claimed' and claimed_at > now() - interval '2 minutes' and auth_session is null))
  returning user_id, ends_at into v_uid, v_ends;
  if v_uid is null then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  select email into v_mail from auth.users where id = v_uid;
  if v_mail is null then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  return jsonb_build_object('ok', true, 'email', v_mail, 'ends_at', v_ends);
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- LIAISON, PAR LE SERVEUR (`link-claim`, juste après avoir créé la session du poste) : retient
-- l'identifiant de CETTE session, une seule fois. Si la demande est déjà liée, la fonction serveur
-- détruit la session qu'elle vient de créer. Aucun grant client.
create or replace function public.link_bind_srv(p_id uuid, p_key text, p_session uuid)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare v public.device_links%rowtype;
begin
  v := public.link_row_key(p_id, p_key);
  if v.id is null or v.status <> 'claimed' or p_session is null then return jsonb_build_object('ok', false); end if;
  update public.device_links set auth_session = p_session where id = v.id and auth_session is null;
  return jsonb_build_object('ok', found);
exception when others then return jsonb_build_object('ok', false);
end; $$;

-- « APPAREILS CONNECTÉS » (le téléphone) : les postes partagés de CE compte, encore valides.
create or replace function public.link_list()
returns jsonb language plpgsql volatile security definer
set search_path = public, pg_temp as $$
begin
  perform public.link_purge();
  if auth.uid() is null or public.link_is_poste() then return '[]'::jsonb; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id', id, 'label', label,
            'since', coalesce(claimed_at, approved_at), 'ends_at', ends_at) order by ends_at)
     from public.device_links
    where user_id = auth.uid() and kind = 'connect' and status in ('approved','claimed')
      and ends_at > now()), '[]'::jsonb);
end; $$;

-- PROLONGER (le téléphone, JAMAIS un poste — vérifié ici, pas seulement à l'écran : un collègue
-- prolongerait la connexion d'un autre). Toujours 28 h au plus après l'approbation.
create or replace function public.link_extend(p_id uuid, p_ends_at timestamptz)
returns jsonb language plpgsql volatile security definer
set search_path = public, pg_temp as $$
declare v public.device_links%rowtype;
begin
  perform public.link_purge();
  if auth.uid() is null or not public.is_approved() or public.link_is_poste() then
    return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  select * into v from public.device_links
   where id = p_id and user_id = auth.uid() and kind = 'connect' and status in ('approved','claimed');
  if not found or v.ends_at < now() then return jsonb_build_object('ok', false, 'err', 'not_found'); end if;
  if p_ends_at is null or p_ends_at <= v.ends_at or p_ends_at > v.approved_at + public.temp_max_interval() then
    return jsonb_build_object('ok', false, 'err', 'bad_ends'); end if;
  update public.device_links set ends_at = p_ends_at where id = v.id;
  return jsonb_build_object('ok', true, 'ends_at', p_ends_at);
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- DÉCONNECTER À DISTANCE (le téléphone). La session de compte du poste est supprimée ; le poste
-- l'apprend à son sondage suivant et s'efface — sauf session de crise en cours (règle 11), dont
-- la fin est attendue. Un poste révoqué perd aussi son droit de dépôt.
create or replace function public.link_revoke(p_id uuid)
returns jsonb language plpgsql volatile security definer
set search_path = public, auth, pg_temp as $$
declare v public.device_links%rowtype;
begin
  if auth.uid() is null or public.link_is_poste() then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  select * into v from public.device_links where id = p_id and user_id = auth.uid() and kind = 'connect';
  if not found then return jsonb_build_object('ok', false, 'err', 'not_found'); end if;
  update public.device_links set status = 'revoked' where id = v.id;
  if v.auth_session is not null then
    begin delete from auth.sessions where id = v.auth_session and user_id = auth.uid();
    exception when others then null; end;
  end if;
  return jsonb_build_object('ok', true);
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- LE POSTE SE TERMINE LUI-MÊME (« Se déconnecter et effacer », v5.111.2, A649). Signalé : « Appareils
-- connectés ne se met pas à jour même si on clique sur se déconnecter » — la déconnexion du poste
-- (`logout`, scope=local) supprimait bien SA session de compte, mais rien ne disait au serveur que le
-- poste avait fini : il restait listé jusqu'à son heure de fin. Appelée par la SESSION DU POSTE
-- (reconnue par son `session_id`, liée par le serveur — cf. `link_is_poste`), elle ne vise que SON
-- lien ; aucun paramètre, donc rien à falsifier. Le droit de dépôt reste ouvert 7 jours (heure de fin
-- ramenée à maintenant) : une session non encore envoyée pourrait encore arriver.
create or replace function public.link_end()
returns jsonb language plpgsql volatile security definer
set search_path = public, pg_temp as $$
declare v_sid uuid := nullif(auth.jwt() ->> 'session_id', '')::uuid;
begin
  if auth.uid() is null or v_sid is null then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  update public.device_links set status = 'ended', ends_at = least(ends_at, now())
   where auth_session = v_sid and user_id = auth.uid() and kind = 'connect' and status in ('approved','claimed');
  if not found then return jsonb_build_object('ok', false, 'err', 'not_found'); end if;
  return jsonb_build_object('ok', true);
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- CONNEXION TEMPORAIRE PAR E-MAIL (v5.112, A651) : sans appareil connecté sous la main, on se
-- connecte par le code e-mail en choisissant « Temporaire ». La session TOUTE FRAÎCHE se déclare
-- alors poste partagé : elle reçoit les mêmes limites qu'un poste connecté par le code à viser
-- (`link_is_poste`), apparaît dans « Appareils connectés », se déconnecte à distance et s'arrête à
-- l'heure de fin (purge). Elle ne peut que SE RESTREINDRE : aucun droit n'est gagné ici.
--   · la session courante seulement (`session_id` du jeton), jamais une autre ; une seule fois ;
--   · compte validé, heure de fin entre 30 min et 28 h, 5 connexions actives au plus (comme l'approbation) ;
--   · la clé du poste (dépôts des sessions) n'arrive qu'en EMPREINTE, comme pour `link_open`.
create or replace function public.link_self(p_key_hash text, p_label text, p_ends_at timestamptz)
returns jsonb language plpgsql volatile security definer
set search_path = public, extensions, pg_temp as $$
declare v_sid uuid := nullif(auth.jwt() ->> 'session_id', '')::uuid; v_id uuid; v_n int; v_label text;
begin
  perform public.link_purge();
  if auth.uid() is null or v_sid is null or not public.is_approved() then
    return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  if public.link_is_poste() then return jsonb_build_object('ok', false, 'err', 'already'); end if;
  if p_key_hash is null or length(p_key_hash) <> 64 or p_key_hash ~ '[^0-9a-f]' then
    return jsonb_build_object('ok', false, 'err', 'bad_request'); end if;
  if p_ends_at is null or p_ends_at < now() + interval '30 minutes' or p_ends_at > now() + public.temp_max_interval() then
    return jsonb_build_object('ok', false, 'err', 'bad_ends'); end if;
  v_label := coalesce(p_label, '');
  if cardinality(string_to_array(v_label, ' · ')) > 2
     or split_part(v_label, ' · ', 1) not in ('Edge','Firefox','Chrome','Safari','Navigateur')
     or split_part(v_label, ' · ', 2) not in ('','Windows','iPhone','iPad','Android','ChromeOS','macOS','Linux') then
    v_label := 'Navigateur'; end if;
  perform pg_advisory_xact_lock(hashtext('link:' || auth.uid()::text));
  select count(*) into v_n from public.device_links
   where user_id = auth.uid() and kind = 'connect' and status in ('approved','claimed') and ends_at > now();
  if v_n >= 5 then return jsonb_build_object('ok', false, 'err', 'too_many'); end if;
  -- Aucun QR : le secret est une empreinte aléatoire que personne ne connaît (la colonne l'exige).
  insert into public.device_links(kind, secret_hash, key_hash, label, open_until, user_id, status,
                                  ends_at, approved_at, claimed_at, auth_session)
    values ('connect', encode(digest(gen_random_uuid()::text || clock_timestamp()::text, 'sha256'), 'hex'),
            p_key_hash, v_label, now(), auth.uid(), 'claimed', p_ends_at, now(), now(), v_sid)
    returning id into v_id;
  return jsonb_build_object('ok', true, 'id', v_id, 'ends_at', p_ends_at);
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

-- DÉPÔT (le poste, par SA clé, avec ou sans session de compte valide) : ajoute UNE session à
-- l'historique du compte qui a connecté le poste — sans rien lire. C'est ce qui permet à une
-- session terminée APRÈS l'heure de fin, ou hors ligne, de rejoindre l'historique (A643 § dépôt),
-- et aux SAUVEGARDES d'une session en cours d'y arriver (A645). Durci à la revue :
--   · jamais une session vive : `live` absent ou STRICTEMENT le booléen JSON false (« "false" »,
--     une chaîne, devenait une session VIVE chez le client) ;
--   · ne remplace qu'une SAUVEGARDE (`checkpoint`) non supprimée, ou la même donnée exacte (réessai) —
--     jamais une session terminée, jamais une session supprimée (pas de résurrection) ;
--   · 300 dépôts au plus par connexion (une session = une ligne d'au plus 1 Mio) ;
--   · « ok » seulement si une ligne a été écrite : le poste n'efface jamais une session non reçue.
drop function if exists public.link_deposit(uuid,text,jsonb);
create or replace function public.link_deposit(p_id uuid, p_key text, p_row jsonb)
returns jsonb language plpgsql volatile security definer
set search_path = public, pg_temp as $$
declare v public.device_links%rowtype; v_sid text; v_n int;
begin
  perform public.link_purge();
  v := public.link_row_key(p_id, p_key);
  if v.id is null or v.kind <> 'connect' or v.status not in ('claimed','ended')
     or v.ends_at is null or now() > v.ends_at + interval '7 days' then
    return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  if p_row is null or jsonb_typeof(p_row) <> 'object' or jsonb_typeof(p_row->'data') <> 'object' then
    return jsonb_build_object('ok', false, 'err', 'bad_request'); end if;
  v_sid := p_row->>'id';
  if v_sid is null or length(v_sid) not between 1 and 64 or v_sid ~ '[^A-Za-z0-9_-]'
     or (p_row->'data' ? 'live' and p_row->'data'->'live' <> 'false'::jsonb) then
    return jsonb_build_object('ok', false, 'err', 'bad_request'); end if;
  update public.device_links set deposits = deposits + 1 where id = v.id and deposits < 300;
  if not found then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  insert into public.sessions(id, owner, data, exercise, updated_at)
    values (v_sid, v.user_id, p_row->'data', coalesce(p_row->>'exercise', 'false') = 'true', now())
  on conflict (id) do update
    set data = excluded.data, exercise = excluded.exercise, updated_at = excluded.updated_at
    where public.sessions.owner = v.user_id and public.sessions.deleted_at is null
      and (public.sessions.data ? 'checkpoint' or public.sessions.data = excluded.data);
  get diagnostics v_n = row_count;
  if v_n = 0 then return jsonb_build_object('ok', false, 'err', 'refused'); end if;
  return jsonb_build_object('ok', true);
exception when others then return jsonb_build_object('ok', false, 'err', 'refused');
end; $$;

grant execute on function public.link_peek(uuid,text)                 to authenticated;
grant execute on function public.link_approve(uuid,text,timestamptz)  to authenticated;
grant execute on function public.link_list()                          to authenticated;
grant execute on function public.link_extend(uuid,timestamptz)        to authenticated;
grant execute on function public.link_revoke(uuid)                    to authenticated;
grant execute on function public.link_end()                           to authenticated;
grant execute on function public.link_self(text,text,timestamptz)     to authenticated;

-- ---------- 10ter. LES RÈGLES DE LA CONNEXION TEMPORAIRE (v5.113, A654) ---------------------------
-- Réglées dans Administration › Règles, POUR TOUTE L'APPLICATION (décision de l'auteur). Une grammaire
-- FERMÉE, valeurs par défaut = les paliers d'A647 :
--   edit : 'libre' | 'v5' | 'v15' | 'tel' | 'non'   (créer, modifier une aide ou un protocole)
--   del  : 'tel' | 'non'                            (supprimer)
--   repl : 'tel' | 'non'                            (remplacer une bibliothèque à l'import)
--   exp  : 'oui' | 'non'                            (exporter, télécharger)
--   dur  : 12 | 24 | 28                             (durée maximale d'une connexion, en heures)
-- CE QUE LE SERVEUR GARANTIT, et ce qu'il ne peut pas : les INTERDITS (`non`) et la DURÉE sont opposables —
-- une session de poste ne peut pas écrire ce que la règle interdit, même par la console du navigateur. Les
-- CONFIRMATIONS (« confirmer à chaque fois », verrou après N minutes) restent du ressort de l'app : la
-- synchro pousse les modifications plus tard (hors ligne, en lot), le serveur ne sait pas dater le geste.
alter table public.app_settings add column if not exists temp_rules jsonb not null
  default '{"edit":"v15","del":"tel","repl":"non","exp":"oui","dur":28}'::jsonb;

create or replace function public.temp_rules()
returns jsonb language sql stable security definer set search_path = public, pg_temp as $$
  select '{"edit":"v15","del":"tel","repl":"non","exp":"oui","dur":28}'::jsonb
         || coalesce((select temp_rules from public.app_settings limit 1), '{}'::jsonb);
$$;
create or replace function public.temp_max_interval()
returns interval language sql stable security definer set search_path = public, pg_temp as $$
  select make_interval(hours => least(28, greatest(1, coalesce((public.temp_rules() ->> 'dur')::int, 28))));
$$;

-- Lecture : tout compte connecté (l'app applique les règles sur un poste, et l'appareil qui approuve
-- borne les heures proposées). Rien de sensible.
create or replace function public.get_temp_rules()
returns jsonb language sql stable security definer set search_path = public, pg_temp as $$
  select case when auth.uid() is null then null else public.temp_rules() end;
$$;
grant execute on function public.get_temp_rules() to authenticated;

-- Écriture : l'administrateur, JAMAIS depuis une connexion temporaire (un poste resté ouvert pourrait
-- desserrer les règles puis s'en servir).
create or replace function public.set_temp_rules(p_rules jsonb)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v jsonb := '{}'::jsonb;
begin
  if not public.is_app_admin() or public.link_is_poste() then raise exception 'not allowed'; end if;
  if p_rules is null or jsonb_typeof(p_rules) <> 'object' then raise exception 'invalid rules'; end if;
  if p_rules ? 'edit' then
    if p_rules->>'edit' not in ('libre','v5','v15','tel','non') then raise exception 'invalid rules'; end if;
    v := v || jsonb_build_object('edit', p_rules->>'edit'); end if;
  if p_rules ? 'del' then
    if p_rules->>'del' not in ('tel','non') then raise exception 'invalid rules'; end if;
    v := v || jsonb_build_object('del', p_rules->>'del'); end if;
  if p_rules ? 'repl' then
    if p_rules->>'repl' not in ('tel','non') then raise exception 'invalid rules'; end if;
    v := v || jsonb_build_object('repl', p_rules->>'repl'); end if;
  if p_rules ? 'exp' then
    if p_rules->>'exp' not in ('oui','non') then raise exception 'invalid rules'; end if;
    v := v || jsonb_build_object('exp', p_rules->>'exp'); end if;
  if p_rules ? 'dur' then
    if p_rules->>'dur' not in ('12','24','28') then raise exception 'invalid rules'; end if;
    v := v || jsonb_build_object('dur', (p_rules->>'dur')::int); end if;
  update public.app_settings set temp_rules = temp_rules || v where id = true;
end;$$;
grant execute on function public.set_temp_rules(jsonb) to authenticated;

-- Le poste vu depuis une POLITIQUE : elle s'exécute avec les droits de l'appelant, à qui `link_is_poste`
-- est fermé ; ces relais en definer ne rendent qu'un booléen sur SA propre session.
create or replace function public.temp_is_poste()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select public.link_is_poste();
$$;
grant execute on function public.temp_is_poste() to authenticated;
-- Une écriture d'aide ou de protocole depuis un poste : permise sauf INTERDIT. `p_deleted` non nul = une
-- suppression (douce) : la règle `del` s'applique ; sinon la règle `edit`.
create or replace function public.temp_write_ok(p_deleted timestamptz)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select not public.link_is_poste()
      or (case when p_deleted is not null then public.temp_rules() ->> 'del' else public.temp_rules() ->> 'edit' end) <> 'non';
$$;
grant execute on function public.temp_write_ok(timestamptz) to authenticated;
create or replace function public.temp_del_ok()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select not public.link_is_poste() or public.temp_rules() ->> 'del' <> 'non';
$$;
grant execute on function public.temp_del_ok() to authenticated;

-- POLITIQUES RESTRICTIVES : elles s'AJOUTENT aux politiques existantes (ET logique) sans les réécrire.
drop policy if exists cognitive_aids_temp_ins on public.cognitive_aids;
create policy cognitive_aids_temp_ins on public.cognitive_aids as restrictive for insert to authenticated
  with check (public.temp_write_ok(deleted_at));
drop policy if exists cognitive_aids_temp_upd on public.cognitive_aids;
create policy cognitive_aids_temp_upd on public.cognitive_aids as restrictive for update to authenticated
  using (true) with check (public.temp_write_ok(deleted_at));
drop policy if exists cognitive_aids_temp_del on public.cognitive_aids;
create policy cognitive_aids_temp_del on public.cognitive_aids as restrictive for delete to authenticated
  using (public.temp_del_ok());
drop policy if exists protocols_temp_ins on public.protocols;
create policy protocols_temp_ins on public.protocols as restrictive for insert to authenticated
  with check (public.temp_write_ok(deleted_at));
drop policy if exists protocols_temp_upd on public.protocols;
create policy protocols_temp_upd on public.protocols as restrictive for update to authenticated
  using (true) with check (public.temp_write_ok(deleted_at));
drop policy if exists protocols_temp_del on public.protocols;
create policy protocols_temp_del on public.protocols as restrictive for delete to authenticated
  using (public.temp_del_ok());
-- A663 — LES DOCUMENTS D'UNE AIDE SUIVENT LA RÈGLE DE L'AIDE. Sous `edit = non`, un poste ne modifiait
-- plus une aide ni un protocole… mais pouvait encore REMPLACER leur PDF dans le bucket, par l'API Storage
-- (`att_perso`, `att_lib_write` ne connaissent que le rôle). Dépôt et remplacement suivent donc `edit`.
-- La SUPPRESSION d'un objet n'est refusée que si `edit` ET `del` sont interdits : le serveur ne sait pas
-- distinguer le document retiré d'une aide que l'on modifie de celui qui part avec une aide supprimée,
-- et chacun de ces deux gestes reste permis par sa propre règle. Bornées au bucket de l'application.
-- NON ÉTENDU, à dessein, à `category_sets` ni à `aid_followups` : la règle `edit` d'A654 nomme « une aide
-- ou un protocole » ; le document personnel de `category_sets` porte les préférences et les collections
-- du compte, qu'un poste réécrit légitimement (A647), et le suivi n'est pas verrouillé par l'app sur un
-- poste — le fermer ici ferait perdre en silence ce qu'elle laisse saisir. C'est une règle à DÉCIDER.
create or replace function public.temp_att_del_ok()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select not public.link_is_poste()
      or public.temp_rules() ->> 'edit' <> 'non' or public.temp_rules() ->> 'del' <> 'non';
$$;
grant execute on function public.temp_att_del_ok() to authenticated;
drop policy if exists att_temp_ins on storage.objects;
create policy att_temp_ins on storage.objects as restrictive for insert to authenticated
  with check (bucket_id <> 'attachments' or public.temp_write_ok(null));
drop policy if exists att_temp_upd on storage.objects;
create policy att_temp_upd on storage.objects as restrictive for update to authenticated
  using (true) with check (bucket_id <> 'attachments' or public.temp_write_ok(null));
drop policy if exists att_temp_del on storage.objects;
create policy att_temp_del on storage.objects as restrictive for delete to authenticated
  using (bucket_id <> 'attachments' or public.temp_att_del_ok());
-- Bibliothèques, membres et rôles : jamais depuis un poste (A647, « toujours interdit »).
drop policy if exists libraries_temp_ins on public.libraries;
create policy libraries_temp_ins on public.libraries as restrictive for insert to authenticated
  with check (not public.temp_is_poste());
drop policy if exists libraries_temp_upd on public.libraries;
create policy libraries_temp_upd on public.libraries as restrictive for update to authenticated
  using (not public.temp_is_poste());
drop policy if exists libraries_temp_del on public.libraries;
create policy libraries_temp_del on public.libraries as restrictive for delete to authenticated
  using (not public.temp_is_poste());
drop policy if exists memberships_temp_ins on public.memberships;
create policy memberships_temp_ins on public.memberships as restrictive for insert to authenticated
  with check (not public.temp_is_poste());
drop policy if exists memberships_temp_upd on public.memberships;
create policy memberships_temp_upd on public.memberships as restrictive for update to authenticated
  using (not public.temp_is_poste());
drop policy if exists memberships_temp_del on public.memberships;
create policy memberships_temp_del on public.memberships as restrictive for delete to authenticated
  using (not public.temp_is_poste());

-- ---------- 10quater. UN APPAREIL DÉCONNECTÉ NE LIT NI N'ÉCRIT PLUS, TOUT DE SUITE (v5.114, A655) --------
-- Signalé : « quand je déconnecte un appareil depuis mon téléphone, je peux continuer à modifier mes fiches et
-- lancer des sessions jusqu'à ce que je recharge la page ». `link_revoke` supprime la session de compte du poste,
-- mais son JETON D'ACCÈS reste valable jusqu'à son expiration (900 s, A648) : PostgREST vérifie la signature du
-- jeton, jamais l'existence de la session. Ces politiques RESTRICTIVES ferment les tables à une session de poste
-- DÉCONNECTÉE (révoquée, ou terminée par `link_end`) ou dont l'HEURE DE FIN est passée, dès la requête suivante.
-- Ce que le poste doit encore pouvoir faire passe par des fonctions SECURITY DEFINER qui ne lisent pas ces
-- politiques : `link_poll` (apprendre qu'il est déconnecté) et `link_deposit` (déposer ses sessions après l'heure de
-- fin — refusé, lui, à un poste révoqué). Index : `device_links_sess_idx`. `(select …)` : évaluée une fois par
-- requête, pas une fois par ligne.
create or replace function public.link_dead()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from public.device_links
                  where auth_session = nullif(auth.jwt() ->> 'session_id', '')::uuid
                    and (status <> 'claimed' or ends_at is null or ends_at < now()));
$$;
revoke execute on function public.link_dead() from public, anon;
grant execute on function public.link_dead() to authenticated;
do $$ declare t text; begin
  foreach t in array array['libraries','memberships','cognitive_aids','category_sets','aid_notes','aid_followups',
                           'protocols','sessions','library_requests','user_status'] loop
    execute format('drop policy if exists %I on public.%I', t || '_link_dead', t);
    execute format('create policy %I on public.%I as restrictive for all to authenticated '
                   'using (not (select public.link_dead())) with check (not (select public.link_dead()))', t || '_link_dead', t);
  end loop;
end $$;
drop policy if exists att_link_dead on storage.objects;
create policy att_link_dead on storage.objects as restrictive for all to authenticated
  using (not (select public.link_dead())) with check (not (select public.link_dead()));

-- ---------- 10bis. AUCUN MOT DE PASSE (v5.111.1, A648) ---------------------------------------
-- L'app ne se connecte QUE par code e-mail (et, depuis v5.111, par le téléphone). Or GoTrue laisse
-- toute session valide se DÉFINIR un mot de passe (`PUT /auth/v1/user`) : une session de poste
-- partagé — ou toute session volée — pourrait ainsi s'ouvrir un accès DURABLE, qui survivrait à la
-- déconnexion à distance et à l'heure de fin (revue de sécurité A643). Le « Password Verification
-- Attempt hook » qui refuserait ces connexions est réservé aux plans payants ; ce déclencheur fait
-- mieux, et partout : un compte ne peut tout simplement PAS porter de mot de passe. Les comptes
-- créés par code e-mail en ont un vide (GoTrue pose ''), que le déclencheur laisse passer.
-- Ne touche PAS la connexion au tableau de bord Supabase (compte supabase.com, séparé).
-- Le projet crée déjà un déclencheur sur `auth.users` (`on_auth_user_created`) : même régime.
create or replace function public.forbid_passwords()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if new.encrypted_password is not null and new.encrypted_password <> ''
     and (tg_op = 'INSERT' or new.encrypted_password is distinct from old.encrypted_password) then
    raise exception 'passwords are disabled for this application';
  end if;
  return new;
end; $$;
drop trigger if exists forbid_passwords on auth.users;
create trigger forbid_passwords before insert or update of encrypted_password on auth.users
  for each row execute function public.forbid_passwords();

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
-- INNOCUITÉ VÉRIFIÉE avant écriture (inventaire fonction par fonction) : chaque fonction appelable
-- par l'app porte son `grant execute ... to authenticated` explicite (elles étaient 15 à l'époque ;
-- le compte a grandi depuis, la règle non — A663) ; les fonctions de TRIGGER (clamp_updated_at,
-- stamp_updated_by, handle_new_user, lib_add_creator, revoke_memberships, memberships_keep_admin,
-- forbid_passwords) sont invoquées par le moteur — le privilège EXECUTE n'y est contrôlé qu'à la
-- CRÉATION du trigger, jamais à son déclenchement — et les aides internes (share_purge, share_resolve,
-- link_row…, purge_user_data) ne sont appelées que depuis des fonctions SECURITY DEFINER.
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
-- SIX fonctions, nommées une par une, et rien d'autre — jamais une table, jamais un
-- `on all functions`. Les trois premières sont la contrepartie assumée d'un besoin clinique
-- précis : qu'un collègue présent dans la pièce puisse suivre et remplir une session sur SON
-- téléphone, sans compte, sans installer l'app, pour cette session-là uniquement. Les trois
-- suivantes (v5.111, A643) servent le POSTE PARTAGÉ, qui n'a pas encore de compte quand il
-- demande à être connecté (`link_open`, `link_poll`), et peut ne plus en avoir quand il dépose
-- une session après l'heure de fin (`link_deposit`) — chacune ne désigne que la demande dont on
-- présente le SECRET.
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
grant execute on function public.link_open(text,text,text,text) to anon, authenticated;
grant execute on function public.link_poll(uuid,text)           to anon, authenticated;
grant execute on function public.link_deposit(uuid,text,jsonb)  to anon, authenticated;
-- A643 : les trois aides INTERNES de la connexion par le téléphone ne sont appelables par AUCUN
-- client. Révocation NOMINATIVE et pas seulement « from public » : Supabase pose à la création du
-- projet un `alter default privileges ... grant all on functions to ... authenticated` (cf.
-- 5quater) — sans ces lignes, tout compte connecté pourrait appeler `link_claim_srv` et obtenir
-- l'e-mail du compte d'un poste dont il aurait volé la clé.
revoke execute on function public.link_claim_srv(uuid,text)     from public, anon, authenticated;
revoke execute on function public.link_bind_srv(uuid,text,uuid) from public, anon, authenticated;
revoke execute on function public.link_row(uuid,text)           from public, anon, authenticated;
revoke execute on function public.link_row_key(uuid,text)       from public, anon, authenticated;
revoke execute on function public.link_is_poste()               from public, anon, authenticated;
revoke execute on function public.link_purge()                  from public, anon, authenticated;
revoke execute on function public.forbid_passwords()            from public, anon, authenticated;   -- A648 : fonction de déclencheur
grant  execute on function public.link_claim_srv(uuid,text)     to service_role;
grant  execute on function public.link_bind_srv(uuid,text,uuid) to service_role;

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
