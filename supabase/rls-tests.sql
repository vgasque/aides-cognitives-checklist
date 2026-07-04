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
  carol uuid := '33333333-3333-3333-3333-333333333333';
  dave  uuid := '44444444-4444-4444-4444-444444444444';
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

  ------------------------------------------------------------------ 5bis. Liste d'attente : e-mail vérifié exigé
  -- Demander un code OTP crée la ligne auth.users AVANT toute vérification : elle ne doit PAS
  -- apparaître en attente tant que l'e-mail n'est pas confirmé (anti-spam de fausses adresses).
  reset role;
  insert into auth.users (id, email) values (carol,'carol@test.local') on conflict (id) do nothing;
  select count(*) into v_cnt from public.user_status where user_id=carol;
  if v_cnt <> 0 then raise exception 'ÉCHEC : une inscription non vérifiée apparaît dans user_status'; end if;
  -- L'utilisateur saisit son code (GoTrue pose email_confirmed_at) -> il apparaît alors en attente.
  update auth.users set email_confirmed_at=now() where id=carol;
  select count(*) into v_cnt from public.user_status where user_id=carol and status='pending';
  if v_cnt <> 1 then raise exception 'ÉCHEC : un e-mail vérifié n''apparaît pas en attente de validation'; end if;

  ------------------------------------------------------------------ 5ter. Compte SANS ligne user_status : approuvé (aligné sur my_status)
  -- Cas réel : compte antérieur à la fonctionnalité de validation (ou migration incomplète).
  -- my_status() rapporte 'approved' quand aucune ligne n'existe -> is_approved() doit faire de
  -- même, sinon l'app affiche « Connecté » pendant que toutes les écritures sont refusées en 403.
  -- (require_approval est TRUE depuis la section 5 : c'est bien l'absence de ligne qu'on teste.)
  reset role;
  insert into auth.users (id, email, email_confirmed_at) values (dave,'dave@test.local',now())
    on conflict (id) do nothing;
  delete from public.user_status where user_id=dave;   -- simule le compte d'avant la fonctionnalité
  perform set_config('request.jwt.claims', json_build_object('sub',dave,'role','authenticated')::text, true);
  set local role authenticated;
  if public.my_status() <> 'approved' then raise exception 'ÉCHEC : my_status sans ligne user_status devrait être approved'; end if;
  if public.is_approved() <> true then raise exception 'ÉCHEC : is_approved diverge de my_status (compte sans ligne user_status refusé)'; end if;
  insert into public.fiches(id,owner,library_id,data) values ('f-dave',dave,null,'{"t":1}');
  select count(*) into v_cnt from public.fiches where id='f-dave';
  if v_cnt <> 1 then raise exception 'ÉCHEC : un compte sans ligne user_status ne peut pas écrire son espace perso'; end if;

  ------------------------------------------------------------------ 6. Notes personnelles : privées et gatées
  -- La section 5bis est repassée en PROPRIÉTAIRE (reset role) : on REVIENT impérativement au
  -- rôle authenticated (sinon la RLS est contournée et ce test échouerait à tort).
  perform set_config('request.jwt.claims', json_build_object('sub',bob,'role','authenticated')::text, true);
  set local role authenticated;
  -- Bob est PENDING (section 5) : l'écriture d'une note est bloquée par le gate is_approved().
  begin
    insert into public.fiche_notes(user_id,fiche_id,note) values (bob,'f-alice','note de bob');
    raise exception 'ÉCHEC : un compte pending a pu écrire une note';
  exception when insufficient_privilege then null; end;

  -- Alice (approuvée) écrit sa note ; Bob (réapprouvé) écrit la SIENNE sur la MÊME fiche.
  reset role;
  update public.user_status set status='approved' where user_id=bob;
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  set local role authenticated;
  insert into public.fiche_notes(user_id,fiche_id,note) values (alice,'f-alice','note d''alice');
  perform set_config('request.jwt.claims', json_build_object('sub',bob,'role','authenticated')::text, true);
  insert into public.fiche_notes(user_id,fiche_id,note) values (bob,'f-alice','note de bob');

  -- Chacun ne voit QUE la sienne ; impossible d'écrire une note au nom d'un autre.
  select count(*) into v_cnt from public.fiche_notes where fiche_id='f-alice';
  if v_cnt <> 1 then raise exception 'ÉCHEC : Bob voit % note(s) sur f-alice (attendu : 1, la sienne)', v_cnt; end if;
  select count(*) into v_cnt from public.fiche_notes where user_id=alice;
  if v_cnt <> 0 then raise exception 'ÉCHEC : Bob voit la note personnelle d''Alice'; end if;
  begin
    insert into public.fiche_notes(user_id,fiche_id,note) values (alice,'f-2','usurpation');
    raise exception 'ÉCHEC : Bob a pu écrire une note au nom d''Alice';
  exception when insufficient_privilege then null; end;
  update public.fiche_notes set note='hack' where user_id=alice;  -- RLS -> 0 ligne, sans erreur
  reset role;
  select count(*) into v_cnt from public.fiche_notes where user_id=alice and note='hack';
  if v_cnt <> 0 then raise exception 'ÉCHEC : Bob a pu modifier la note d''Alice'; end if;

  -- (Remise en pending pour ne pas fausser la suite éventuelle.)
  update public.user_status set status='pending' where user_id=bob;

  ------------------------------------------------------------------ 7. delete_my_account : OTP récent exigé
  -- Sans entrée amr dans le JWT (jeton de session « nu », p. ex. volé) -> refus.
  perform set_config('request.jwt.claims', json_build_object('sub',bob,'role','authenticated')::text, true);
  set local role authenticated;
  begin
    perform public.delete_my_account();
    raise exception 'ÉCHEC : suppression de compte possible SANS vérification OTP récente';
  exception when raise_exception then
    if sqlerrm <> 'recent otp verification required' then raise; end if;
  end;

  -- Entrée amr otp PÉRIMÉE (il y a 1 h) -> refus aussi (un refresh conserve l'amr d'origine).
  perform set_config('request.jwt.claims', json_build_object('sub',bob,'role','authenticated',
    'amr',json_build_array(json_build_object('method','otp','timestamp',(extract(epoch from now())::bigint - 3600))))::text, true);
  begin
    perform public.delete_my_account();
    raise exception 'ÉCHEC : suppression de compte possible avec un OTP d''il y a 1 h';
  exception when raise_exception then
    if sqlerrm <> 'recent otp verification required' then raise; end if;
  end;

  -- Entrée amr otp FRAÎCHE (le parcours normal de l'app : code saisi juste avant) -> suppression OK.
  perform set_config('request.jwt.claims', json_build_object('sub',bob,'role','authenticated',
    'amr',json_build_array(json_build_object('method','otp','timestamp',extract(epoch from now())::bigint)))::text, true);
  perform public.delete_my_account();
  reset role;
  select count(*) into v_cnt from auth.users where id=bob;
  if v_cnt <> 0 then raise exception 'ÉCHEC : delete_my_account n''a pas supprimé le compte'; end if;
  -- La suppression du compte emporte aussi ses notes personnelles (FK on delete cascade).
  select count(*) into v_cnt from public.fiche_notes where user_id=bob;
  if v_cnt <> 0 then raise exception 'ÉCHEC : les notes de Bob ont survécu à la suppression du compte'; end if;

  ------------------------------------------------------------------ FIN
  reset role;
  raise notice '✅ TOUS LES TESTS RLS PASSENT';
end $$;

rollback;  -- IMPORTANT : aucune donnée de test conservée.

-- Confirmation VISIBLE dans le SQL Editor (qui n'affiche pas les RAISE NOTICE) : cette ligne ne
-- s'exécute que si tout ce qui précède a réussi — un échec de test aurait interrompu le script.
select '✅ TOUS LES TESTS RLS PASSENT' as resultat;
