-- ============================================================================
--  Tests des politiques RLS — Aides cognitives
--  À exécuter dans Supabase > SQL Editor APRÈS schema.sql.
--
--  Sûr à exécuter : tout se déroule dans une transaction terminée par ROLLBACK
--  -> AUCUNE donnée de test n'est conservée (même en cas d'échec).
--
--  Pourquoi un seul bloc DO ?
--   • La gestion d'exceptions (begin/exception/end), raise, if… n'existe qu'en
--     PL/pgSQL : elle DOIT être dans un DO $$ … $$ (pas au niveau SQL).
--   • Pour que la RLS s'applique vraiment, on bascule le rôle courant vers
--     « authenticated » (le SQL Editor tourne sinon en propriétaire, qui
--     CONTOURNE la RLS). On simule l'utilisateur via request.jwt.claims (lu par
--     auth.uid()). Le seeding (auth.users, statuts, interrupteur) se fait en
--     propriétaire (RESET ROLE) car ces écritures sont réservées côté serveur.
--
--  Résultat attendu : NOTICE « ✅ TOUS LES TESTS RLS PASSENT ». Toute violation
--  lève une exception -> le script s'arrête en rouge.
-- ============================================================================
begin;

do $$
declare
  alice uuid := '11111111-1111-1111-1111-111111111111';
  bob   uuid := '22222222-2222-2222-2222-222222222222';
  v_hack text;
  v_cnt  int;
begin
  ------------------------------------------------------------------ SEED (propriétaire)
  reset role;
  insert into auth.users (id, email) values (alice,'alice@test.local'),(bob,'bob@test.local')
    on conflict (id) do nothing;
  insert into public.user_status(user_id,email,status) values
    (alice,'alice@test.local','approved'),(bob,'bob@test.local','approved')
    on conflict (user_id) do update set status='approved';

  ------------------------------------------------------------------ 1. Espace PERSO isolé
  -- Alice crée une fiche perso.
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  set local role authenticated;
  insert into public.fiches(id,owner,library_id,data) values ('f-alice',alice,null,'{"t":1}');
  select count(*) into v_cnt from public.fiches where id='f-alice';
  if v_cnt <> 1 then raise exception 'ÉCHEC : Alice ne voit pas sa propre fiche perso'; end if;

  -- Bob ne doit ni la voir, ni la modifier.
  perform set_config('request.jwt.claims', json_build_object('sub',bob,'role','authenticated')::text, true);
  select count(*) into v_cnt from public.fiches where id='f-alice';
  if v_cnt <> 0 then raise exception 'ÉCHEC : Bob voit la fiche perso d''Alice'; end if;
  update public.fiches set data='{"hack":1}' where id='f-alice';  -- RLS -> 0 ligne, sans erreur

  reset role;
  select data->>'hack' into v_hack from public.fiches where id='f-alice';
  if v_hack is not null then raise exception 'ÉCHEC : Bob a pu modifier la fiche perso d''Alice'; end if;

  ------------------------------------------------------------------ 2. Tables invisibles de l'API
  perform set_config('request.jwt.claims', json_build_object('sub',bob,'role','authenticated')::text, true);
  set local role authenticated;
  begin
    perform 1 from public.app_admins limit 1;
    raise exception 'ÉCHEC : app_admins est lisible par un utilisateur authentifié';
  exception when insufficient_privilege then null; end;
  begin
    perform 1 from public.app_settings limit 1;
    raise exception 'ÉCHEC : app_settings est lisible par un utilisateur authentifié';
  exception when insufficient_privilege then null; end;

  ------------------------------------------------------------------ 3. Helpers : non-membre sans droit
  if public.is_member('lib-inexistante') <> false then raise exception 'ÉCHEC : is_member devrait être false'; end if;
  if public.member_role('lib-inexistante') is not null then raise exception 'ÉCHEC : member_role devrait être NULL'; end if;

  ------------------------------------------------------------------ 4. Création de bibliothèque réservée aux app-admins
  begin
    insert into public.libraries(id,name) values ('lib-x','Pirate');
    raise exception 'ÉCHEC : un non-admin a pu créer une bibliothèque';
  exception when insufficient_privilege then null; end;

  ------------------------------------------------------------------ 5. Compte NON approuvé : écriture perso bloquée
  reset role;
  update public.user_status set status='pending' where user_id=bob;
  update public.app_settings set require_approval=true where id=true;

  perform set_config('request.jwt.claims', json_build_object('sub',bob,'role','authenticated')::text, true);
  set local role authenticated;
  if public.is_approved() <> false then raise exception 'ÉCHEC : Bob (pending) est considéré approuvé'; end if;
  begin
    insert into public.fiches(id,owner,library_id,data) values ('f-bob',bob,null,'{"t":1}');
    raise exception 'ÉCHEC : un compte pending a pu écrire dans son espace perso';
  exception when insufficient_privilege then null; end;

  ------------------------------------------------------------------ FIN
  reset role;
  raise notice '✅ TOUS LES TESTS RLS PASSENT';
end $$;

rollback;  -- IMPORTANT : aucune donnée de test conservée.

-- Confirmation VISIBLE dans le SQL Editor (qui n'affiche pas les RAISE NOTICE) : cette ligne ne
-- s'exécute que si tout ce qui précède a réussi — un échec de test aurait interrompu le script.
select '✅ TOUS LES TESTS RLS PASSENT' as resultat;
