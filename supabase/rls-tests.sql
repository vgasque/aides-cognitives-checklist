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
  v_snap jsonb;
  alice uuid := '11111111-1111-1111-1111-111111111111';
  bob   uuid := '22222222-2222-2222-2222-222222222222';
  carol uuid := '33333333-3333-3333-3333-333333333333';
  dave  uuid := '44444444-4444-4444-4444-444444444444';
  erin  uuid := '55555555-5555-5555-5555-555555555555';
  frank uuid := '66666666-6666-6666-6666-666666666666';
  gina  uuid := '77777777-7777-7777-7777-777777777777';
  -- Compte dédié au §14.10 : la suppression RGPD refuse un app-admin, et Alice en est un
  -- depuis le §11. Réutiliser Alice faisait échouer le test sur « super-admin account cannot
  -- be self-deleted » — un refus légitime, mais qui ne testait plus ce qu'on voulait tester.
  ivan  uuid := '99999999-9999-9999-9999-999999999999';
  kim   uuid := 'abababab-abab-abab-abab-abababababab';   -- §16, compte dédié (A643)
  -- §17 (A663), comptes dédiés
  lea   uuid := 'a6630000-0000-0000-0000-000000000001';
  max   uuid := 'a6630000-0000-0000-0000-000000000002';
  noe   uuid := 'a6630000-0000-0000-0000-000000000003';
  oda   uuid := 'a6630000-0000-0000-0000-000000000004';
  pia   uuid := 'a6630000-0000-0000-0000-000000000005';
  -- §18 (A676-A680), comptes dédiés
  quin  uuid := 'a6760000-0000-0000-0000-000000000001';
  rui   uuid := 'a6760000-0000-0000-0000-000000000002';
  v_s18a uuid := 'a6760000-0000-0000-0000-0000000000a1';
  v_s18b uuid := 'a6760000-0000-0000-0000-0000000000a2';
  v_s18c uuid := 'a6760000-0000-0000-0000-0000000000a3';
  v_t0   timestamptz;
  v_t1   timestamptz;
  -- §19 (A687), comptes dédiés
  sam   uuid := 'a6870000-0000-0000-0000-000000000001';
  tom   uuid := 'a6870000-0000-0000-0000-000000000002';
  v_s19 uuid := 'a6870000-0000-0000-0000-0000000000a1';
  v_q0  jsonb;
  v_hack text;
  v_cnt  int;
  v_leak int;
  v_tbl  text;
  v_tbls text[];
  v_list text;
  -- Liste blanche des fonctions du schéma `public` que le rôle anon a le droit d'exécuter.
  -- VIDE aujourd'hui, et c'est la posture du projet. À n'étendre qu'avec une justification
  -- écrite dans schema.sql, jamais « pour faire passer le test ».
  -- v5.111 (A643) : les trois fonctions du POSTE PARTAGÉ, justifiées dans schema.sql § 5quinquies.
  v_anon_fns_ok text[] := array['share_join','share_pull','share_push','link_open','link_poll','link_deposit'];
  v_j    jsonb;
  v_j2   jsonb;
  v_code text;
  v_sec  text;
  v_lid  uuid;   -- §16 : une demande de connexion par le téléphone
  v_lid2 uuid;
  v_hash text;
  v_asid uuid;
  v_key  text;   -- §16 : la CLÉ DU POSTE (jamais dans le QR)
  v_asid2 uuid;
  v_asid3 uuid;
  v_lid3 uuid;   -- 16.18 : le lien du poste de 16.16
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
  insert into public.cognitive_aids(id,owner,library_id,data) values ('f-alice',alice,null,'{"t":1}');
  select count(*) into v_cnt from public.cognitive_aids where id='f-alice';
  if v_cnt <> 1 then raise exception 'ÉCHEC : Alice ne voit pas sa propre fiche perso'; end if;

  -- Bob ne doit ni la voir, ni la modifier.
  perform set_config('request.jwt.claims', json_build_object('sub',bob,'role','authenticated')::text, true);
  select count(*) into v_cnt from public.cognitive_aids where id='f-alice';
  if v_cnt <> 0 then raise exception 'ÉCHEC : Bob voit la fiche perso d''Alice'; end if;
  update public.cognitive_aids set data='{"hack":1}' where id='f-alice';  -- RLS -> 0 ligne, sans erreur

  reset role;
  select data->>'hack' into v_hack from public.cognitive_aids where id='f-alice';
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
    insert into public.cognitive_aids(id,owner,library_id,data) values ('f-bob',bob,null,'{"t":1}');
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
  insert into public.cognitive_aids(id,owner,library_id,data) values ('f-dave',dave,null,'{"t":1}');
  select count(*) into v_cnt from public.cognitive_aids where id='f-dave';
  if v_cnt <> 1 then raise exception 'ÉCHEC : un compte sans ligne user_status ne peut pas écrire son espace perso'; end if;

  ------------------------------------------------------------------ 6. Notes personnelles : privées et gatées
  -- La section 5bis est repassée en PROPRIÉTAIRE (reset role) : on REVIENT impérativement au
  -- rôle authenticated (sinon la RLS est contournée et ce test échouerait à tort).
  perform set_config('request.jwt.claims', json_build_object('sub',bob,'role','authenticated')::text, true);
  set local role authenticated;
  -- Bob est PENDING (section 5) : l'écriture d'une note est bloquée par le gate is_approved().
  begin
    insert into public.aid_notes(user_id,fiche_id,note) values (bob,'f-alice','note de bob');
    raise exception 'ÉCHEC : un compte pending a pu écrire une note';
  exception when insufficient_privilege then null; end;

  -- Alice (approuvée) écrit sa note ; Bob (réapprouvé) écrit la SIENNE sur la MÊME fiche.
  reset role;
  update public.user_status set status='approved' where user_id=bob;
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  set local role authenticated;
  insert into public.aid_notes(user_id,fiche_id,note) values (alice,'f-alice','note d''alice');
  perform set_config('request.jwt.claims', json_build_object('sub',bob,'role','authenticated')::text, true);
  insert into public.aid_notes(user_id,fiche_id,note) values (bob,'f-alice','note de bob');

  -- Chacun ne voit QUE la sienne ; impossible d'écrire une note au nom d'un autre.
  select count(*) into v_cnt from public.aid_notes where fiche_id='f-alice';
  if v_cnt <> 1 then raise exception 'ÉCHEC : Bob voit % note(s) sur f-alice (attendu : 1, la sienne)', v_cnt; end if;
  select count(*) into v_cnt from public.aid_notes where user_id=alice;
  if v_cnt <> 0 then raise exception 'ÉCHEC : Bob voit la note personnelle d''Alice'; end if;
  begin
    insert into public.aid_notes(user_id,fiche_id,note) values (alice,'f-2','usurpation');
    raise exception 'ÉCHEC : Bob a pu écrire une note au nom d''Alice';
  exception when insufficient_privilege then null; end;
  update public.aid_notes set note='hack' where user_id=alice;  -- RLS -> 0 ligne, sans erreur
  reset role;
  select count(*) into v_cnt from public.aid_notes where user_id=alice and note='hack';
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
  select count(*) into v_cnt from public.aid_notes where user_id=bob;
  if v_cnt <> 0 then raise exception 'ÉCHEC : les notes de Bob ont survécu à la suppression du compte'; end if;

  ------------------------------------------------------------------ 8. Bibliothèques partagées :
  -- cloisonnement des rôles (viewer/editor/admin) et étanchéité entre bibliothèques. Jusqu'ici,
  -- seuls les helpers is_member/member_role sur une bibliothèque INEXISTANTE étaient testés
  -- (section 3) : aucun test ne créait une VRAIE bibliothèque avec des membres — c'est
  -- précisément la lacune qui avait laissé passer, en 3.3.1, l'invitation d'un compte non
  -- approuvé dans une bibliothèque partagée (corrigé en 3.3.2, testé en 8.6 ci-dessous).
  reset role;
  insert into auth.users (id, email, email_confirmed_at) values
    (erin,'erin@test.local',now()),(frank,'frank@test.local',now()),(gina,'gina@test.local',now())
    on conflict (id) do nothing;
  insert into public.user_status(user_id,email,status) values
    (erin,'erin@test.local','approved'),(frank,'frank@test.local','approved')
    on conflict (user_id) do update set status='approved';
  insert into public.libraries(id,name,created_by) values ('lib-team','Équipe',alice),('lib-other','Autre',alice)
    on conflict (id) do nothing;
  insert into public.memberships(user_id,library_id,role) values (erin,'lib-team','editor'),(frank,'lib-team','viewer')
    on conflict (user_id,library_id) do update set role=excluded.role;
  insert into public.cognitive_aids(id,owner,library_id,data) values ('f-other',alice,'lib-other','{"t":1}')
    on conflict (id) do nothing;

  -- 8.1 Editor : peut créer/lire une fiche de SA bibliothèque.
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  set local role authenticated;
  insert into public.cognitive_aids(id,owner,library_id,data) values ('f-team',erin,'lib-team','{"t":1}');
  select count(*) into v_cnt from public.cognitive_aids where id='f-team';
  if v_cnt <> 1 then raise exception 'ÉCHEC : un editor ne peut pas créer une fiche dans sa bibliothèque'; end if;

  -- 8.2 Viewer : peut LIRE mais pas ÉCRIRE (RLS -> 0 ligne affectée, sans erreur, comme section 1).
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'role','authenticated')::text, true);
  select count(*) into v_cnt from public.cognitive_aids where id='f-team';
  if v_cnt <> 1 then raise exception 'ÉCHEC : un viewer ne voit pas une fiche de sa bibliothèque'; end if;
  update public.cognitive_aids set data='{"hack":1}' where id='f-team';
  reset role;
  select data->>'hack' into v_hack from public.cognitive_aids where id='f-team';
  if v_hack is not null then raise exception 'ÉCHEC : un viewer a pu modifier une fiche de sa bibliothèque'; end if;

  -- 8.2bis Déplacer une fiche partagée vers Perso (fonctionnalité VOULUE : sélecteur de
  -- bibliothèque de l'éditeur, cf. CHANGELOG 3.2.3 « déplacement de fiche entre bibliothèques »)
  -- reste réservé à un EDITOR/ADMIN de la bibliothèque d'origine — un simple viewer ne peut PAS
  -- s'en servir pour exfiltrer une fiche vers son propre espace perso. fiches_shared_write exige
  -- member_role in ('editor','admin') sur la ligne D'ORIGINE (USING) : un viewer échoue cette
  -- condition -> RLS -> 0 ligne affectée, sans erreur (même mécanique que le test précédent).
  reset role;
  insert into public.cognitive_aids(id,owner,library_id,data) values ('f-move',erin,'lib-team','{"t":1}')
    on conflict (id) do nothing;
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'role','authenticated')::text, true);
  set local role authenticated;
  update public.cognitive_aids set library_id=null, owner=frank where id='f-move';
  reset role;
  select library_id into v_hack from public.cognitive_aids where id='f-move';
  if v_hack is distinct from 'lib-team' then raise exception 'ÉCHEC : un viewer a pu exfiltrer une fiche partagée vers son espace perso'; end if;

  -- Un EDITOR de la bibliothèque, en revanche, peut légitimement déplacer CETTE MÊME fiche vers
  -- Perso (non-régression : USING valide sur l'ancienne ligne — editor de lib-team — ET WITH
  -- CHECK valide sur la nouvelle — owner = soi-même, cf. fiches_perso).
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  set local role authenticated;
  update public.cognitive_aids set library_id=null, owner=erin where id='f-move';
  select count(*) into v_cnt from public.cognitive_aids where id='f-move' and library_id is null and owner=erin;
  if v_cnt <> 1 then raise exception 'ÉCHEC : un editor ne peut pas déplacer une fiche de sa bibliothèque vers Perso'; end if;

  -- 8.3 Non-membre : ni lecture ni écriture.
  perform set_config('request.jwt.claims', json_build_object('sub',gina,'role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into v_cnt from public.cognitive_aids where id='f-team';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un non-membre voit une fiche de la bibliothèque'; end if;
  begin
    insert into public.cognitive_aids(id,owner,library_id,data) values ('f-intru',gina,'lib-team','{"t":1}');
    raise exception 'ÉCHEC : un non-membre a pu écrire dans la bibliothèque';
  exception when insufficient_privilege then null; end;

  -- 8.4 Étanchéité entre bibliothèques : un membre de lib-team ne voit pas les fiches de lib-other.
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into v_cnt from public.cognitive_aids where id='f-other';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un membre de lib-team voit une fiche de lib-other'; end if;

  -- 8.4bis A613 — SUIVI : une note d'ÉQUIPE se lit par les membres, s'écrit par TOUS les éditeurs (pas
  -- seulement son auteur), jamais par un lecteur ni un non-membre ; une note PERSO reste à son auteur.
  -- (Erin est éditrice de lib-team, Frank lecteur, Gina non-membre ; Alice n'est pas membre de lib-team.)
  insert into public.aid_followups(id,library_id,entity_id,kind,body,author) values ('fu-team','lib-team','f-team','note','Appel trauma leader','erin');
  insert into public.aid_followups(id,library_id,entity_id,kind,body,author) values ('fu-perso',null,'f-team','task','À revoir','erin');
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'role','authenticated')::text, true);
  select count(*) into v_cnt from public.aid_followups where id='fu-team';
  if v_cnt <> 1 then raise exception 'ÉCHEC : un lecteur ne voit pas une note d''équipe de sa bibliothèque'; end if;
  select count(*) into v_cnt from public.aid_followups where id='fu-perso';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un membre voit le suivi PERSO d''un autre'; end if;
  update public.aid_followups set body='hack' where id='fu-team';   -- lecteur : RLS -> 0 ligne
  begin
    insert into public.aid_followups(id,library_id,entity_id,kind,body) values ('fu-frank','lib-team','f-team','note','x');
    raise exception 'ÉCHEC : un lecteur a pu écrire une note d''équipe';
  exception when insufficient_privilege then null; end;
  perform set_config('request.jwt.claims', json_build_object('sub',gina,'role','authenticated')::text, true);
  select count(*) into v_cnt from public.aid_followups where id='fu-team';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un non-membre voit une note d''équipe'; end if;
  reset role;
  select body into v_hack from public.aid_followups where id='fu-team';
  if v_hack <> 'Appel trauma leader' then raise exception 'ÉCHEC : un lecteur a pu modifier une note d''équipe'; end if;
  -- Un AUTRE éditeur (Alice, ajoutée éditrice) modifie la note d'Erin : voulu (A613, « modifiable par tous les éditeurs »).
  -- A663 : Alice est la SEULE administratrice de lib-team (sa créatrice) — la rétrograder n'est permis
  -- qu'à la maintenance, c'est-à-dire SANS jeton (cf. memberships_keep_admin) : on l'efface donc ici,
  -- comme dans l'éditeur SQL. `reset role` seul laissait traîner le jeton du test précédent.
  perform set_config('request.jwt.claims', '', true);
  insert into public.memberships(user_id,library_id,role) values (alice,'lib-team','editor')
    on conflict (user_id,library_id) do update set role='editor';
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  set local role authenticated;
  update public.aid_followups set body='Appel trauma leader au 4 22 31' where id='fu-team';
  reset role;
  select body into v_hack from public.aid_followups where id='fu-team';
  if v_hack <> 'Appel trauma leader au 4 22 31' then raise exception 'ÉCHEC : un éditeur ne peut pas modifier la note d''équipe d''un autre'; end if;
  delete from public.memberships where user_id=alice and library_id='lib-team';
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  set local role authenticated;

  -- 8.5 invite_member : réservé à un admin de la bibliothèque (un editor est refusé).
  begin
    perform public.invite_member('lib-team','frank@test.local','editor');
    raise exception 'ÉCHEC : un editor (non admin) a pu inviter un membre';
  exception when raise_exception then
    if sqlerrm <> 'not allowed' then raise; end if;
  end;

  -- 8.6 invite_member : compte non approuvé refusé (correctif 3.3.2). Sans lui, Gina (pending)
  -- obtenait un accès lecture/écriture immédiat à lib-team via une simple invitation d'un admin
  -- de bibliothèque, alors que la validation des comptes n'était câblée que sur l'espace perso.
  reset role;
  update public.memberships set role='admin' where user_id=erin and library_id='lib-team';
  insert into public.user_status(user_id,email,status) values (gina,'gina@test.local','pending')
    on conflict (user_id) do update set status='pending';
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  set local role authenticated;
  select public.invite_member('lib-team','gina@test.local','viewer') into v_hack;
  -- A685 : une seule réponse pour « pas de compte » et « compte non validé » (plus d'oracle).
  if v_hack <> 'not_found' then raise exception 'ÉCHEC : invite_member a accepté un compte non approuvé (résultat : %)', v_hack; end if;
  reset role;
  select count(*) into v_cnt from public.memberships where user_id=gina and library_id='lib-team';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un compte non approuvé a quand même été ajouté comme membre'; end if;

  -- 8.7 invite_member : compte approuvé accepté normalement (non-régression du correctif 8.6).
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  set local role authenticated;
  select public.invite_member('lib-team','frank@test.local','viewer') into v_hack;
  if v_hack <> 'ok' then raise exception 'ÉCHEC : invite_member a refusé un compte approuvé (résultat : %)', v_hack; end if;

  ------------------------------------------------------------------ 9. Bucket Storage 'attachments' (documents PDF)
  -- Le CHEMIN encode le périmètre : u/<uid>/<attId>.pdf (perso) ; l/<libId>/<attId>.pdf (partagé).
  -- On teste directement les politiques RLS de storage.objects (l'API Storage n'est qu'un client
  -- de cette table). État hérité des sections précédentes : require_approval=TRUE ; erin = admin
  -- de lib-team ; frank = viewer de lib-team ; gina = pending, non-membre.

  -- 9.1 Alice (approuvée) dépose et lit un document dans SON dossier perso.
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  set local role authenticated;
  insert into storage.objects(bucket_id,name,metadata) values ('attachments','u/'||alice||'/att-a1.pdf','{"size":100}');
  select count(*) into v_cnt from storage.objects where bucket_id='attachments' and name='u/'||alice||'/att-a1.pdf';
  if v_cnt <> 1 then raise exception 'ÉCHEC : Alice ne voit pas son propre document perso'; end if;

  -- 9.2 Lecture croisée PERSO refusée : erin ne voit pas le document d'Alice, et ne peut pas
  -- écrire dans le dossier d'Alice (usurpation de chemin).
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  select count(*) into v_cnt from storage.objects where bucket_id='attachments' and name='u/'||alice||'/att-a1.pdf';
  if v_cnt <> 0 then raise exception 'ÉCHEC : erin voit un document perso d''Alice'; end if;
  begin
    insert into storage.objects(bucket_id,name) values ('attachments','u/'||alice||'/att-intrus.pdf');
    raise exception 'ÉCHEC : erin a pu déposer un document dans le dossier perso d''Alice';
  exception when insufficient_privilege then null; end;

  -- 9.3 Nom hors format refusé, même dans SON propre dossier (extension non-.pdf, id non conforme).
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  begin
    insert into storage.objects(bucket_id,name) values ('attachments','u/'||alice||'/evil.exe');
    raise exception 'ÉCHEC : un nom hors format (.exe) a été accepté';
  exception when insufficient_privilege then null; end;
  begin
    insert into storage.objects(bucket_id,name) values ('attachments','u/'||alice||'/a/b.pdf');
    raise exception 'ÉCHEC : un chemin à sous-dossier a été accepté';
  exception when insufficient_privilege then null; end;

  -- 9.4 Compte NON approuvé : dépôt refusé même dans son propre dossier (gate is_approved).
  perform set_config('request.jwt.claims', json_build_object('sub',gina,'role','authenticated')::text, true);
  begin
    insert into storage.objects(bucket_id,name) values ('attachments','u/'||gina||'/att-g1.pdf');
    raise exception 'ÉCHEC : un compte pending a pu déposer un document perso';
  exception when insufficient_privilege then null; end;

  -- 9.5 Bibliothèque partagée : erin (admin de lib-team) dépose un document de la bibliothèque.
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  insert into storage.objects(bucket_id,name,metadata) values ('attachments','l/lib-team/att-t1.pdf','{"size":200}');
  select count(*) into v_cnt from storage.objects where bucket_id='attachments' and name='l/lib-team/att-t1.pdf';
  if v_cnt <> 1 then raise exception 'ÉCHEC : un editor/admin ne peut pas déposer un document dans sa bibliothèque'; end if;

  -- NB SUPPRESSIONS : Supabase BLOQUE tout DELETE direct sur storage.objects, même en SQL Editor
  -- (trigger storage.protect_delete : « Use the Storage API instead »). La voie de suppression
  -- réelle de l'app est l'API Storage, qui applique LES MÊMES politiques (att_perso/att_lib_write
  -- sont FOR ALL : une seule expression pour SELECT/INSERT/UPDATE/DELETE). On valide donc leur
  -- clause USING via des UPDATE (autorisés en direct) — la sémantique DELETE en découle.

  -- 9.6 frank (viewer, membre) LIT le document de la bibliothèque mais ne peut ni le remplacer
  -- (RLS -> 0 ligne affectée, sans erreur) ni en déposer un nouveau.
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'role','authenticated')::text, true);
  select count(*) into v_cnt from storage.objects where bucket_id='attachments' and name='l/lib-team/att-t1.pdf';
  if v_cnt <> 1 then raise exception 'ÉCHEC : un viewer membre ne voit pas un document de sa bibliothèque'; end if;
  update storage.objects set metadata='{"hack":1}' where bucket_id='attachments' and name='l/lib-team/att-t1.pdf';
  begin
    insert into storage.objects(bucket_id,name) values ('attachments','l/lib-team/att-f1.pdf');
    raise exception 'ÉCHEC : un viewer a pu déposer un document dans la bibliothèque';
  exception when insufficient_privilege then null; end;
  reset role;
  select metadata->>'hack' into v_hack from storage.objects where bucket_id='attachments' and name='l/lib-team/att-t1.pdf';
  if v_hack is not null then raise exception 'ÉCHEC : un viewer a pu remplacer un document de sa bibliothèque'; end if;

  -- 9.7 Un EDITOR peut REMPLACER le document déposé par un AUTRE (jamais fondé sur
  -- storage.objects.owner — même modèle que fiches_shared_write, x-upsert = UPDATE ; la clause
  -- couvre aussi DELETE, cf. NB ci-dessus). frank passe editor pour le test.
  update public.memberships set role='editor' where user_id=frank and library_id='lib-team';
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'role','authenticated')::text, true);
  set local role authenticated;
  update storage.objects set metadata='{"size":999}' where bucket_id='attachments' and name='l/lib-team/att-t1.pdf';
  reset role;
  select metadata->>'size' into v_hack from storage.objects where bucket_id='attachments' and name='l/lib-team/att-t1.pdf';
  if v_hack is distinct from '999' then raise exception 'ÉCHEC : un editor ne peut pas remplacer le document d''un collègue de sa bibliothèque'; end if;
  update public.memberships set role='viewer' where user_id=frank and library_id='lib-team';  -- remise en état

  -- 9.8 Non-membre : aucun accès aux documents de la bibliothèque.
  reset role;
  insert into storage.objects(bucket_id,name) values ('attachments','l/lib-team/att-t2.pdf');
  perform set_config('request.jwt.claims', json_build_object('sub',gina,'role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into v_cnt from storage.objects where bucket_id='attachments' and name='l/lib-team/att-t2.pdf';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un non-membre voit un document de la bibliothèque'; end if;
  begin
    insert into storage.objects(bucket_id,name) values ('attachments','l/lib-team/att-g2.pdf');
    raise exception 'ÉCHEC : un non-membre a pu déposer un document dans la bibliothèque';
  exception when insufficient_privilege then null; end;

  -- 9.9 Rôle ANON (sans session) : rien — ni lecture ni dépôt (aucune politique ne le couvre,
  -- auth.uid() est NULL). Selon la configuration des grants storage, la lecture échoue en
  -- insufficient_privilege ou renvoie simplement 0 ligne : les deux sont un refus correct.
  perform set_config('request.jwt.claims', '{}', true);
  set local role anon;
  begin
    select count(*) into v_cnt from storage.objects where bucket_id='attachments';
    if v_cnt <> 0 then raise exception 'ÉCHEC : le rôle anon voit des documents du bucket'; end if;
  exception when insufficient_privilege then null; end;
  begin
    insert into storage.objects(bucket_id,name) values ('attachments','u/'||alice||'/att-anon.pdf');
    raise exception 'ÉCHEC : le rôle anon a pu déposer un document';
  exception when insufficient_privilege then null; end;

  ------------------------------------------------------------------ 10. Table protocols (clone de fiches)
  -- Mêmes scénarios que les fiches : isolement perso, gate d'approbation, rôles des bibliothèques
  -- partagées, anti-exfiltration. État hérité : require_approval=TRUE ; erin admin de lib-team ;
  -- frank viewer de lib-team ; gina pending non-membre.

  -- 10.1 Perso isolé : Alice crée, erin ne voit ni ne modifie.
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  set local role authenticated;
  insert into public.protocols(id,owner,library_id,data) values ('p-alice',alice,null,'{"t":1}');
  select count(*) into v_cnt from public.protocols where id='p-alice';
  if v_cnt <> 1 then raise exception 'ÉCHEC : Alice ne voit pas son propre protocole perso'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  select count(*) into v_cnt from public.protocols where id='p-alice';
  if v_cnt <> 0 then raise exception 'ÉCHEC : erin voit le protocole perso d''Alice'; end if;
  update public.protocols set data='{"hack":1}' where id='p-alice';
  reset role;
  select data->>'hack' into v_hack from public.protocols where id='p-alice';
  if v_hack is not null then raise exception 'ÉCHEC : erin a pu modifier le protocole perso d''Alice'; end if;

  -- 10.2 Compte NON approuvé : écriture perso bloquée (gate is_approved).
  perform set_config('request.jwt.claims', json_build_object('sub',gina,'role','authenticated')::text, true);
  set local role authenticated;
  begin
    insert into public.protocols(id,owner,library_id,data) values ('p-gina',gina,null,'{"t":1}');
    raise exception 'ÉCHEC : un compte pending a pu écrire un protocole perso';
  exception when insufficient_privilege then null; end;

  -- 10.3 Bibliothèque partagée : editor/admin écrit, viewer lit sans écrire, non-membre rien.
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  insert into public.protocols(id,owner,library_id,data) values ('p-team',erin,'lib-team','{"t":1}');
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'role','authenticated')::text, true);
  select count(*) into v_cnt from public.protocols where id='p-team';
  if v_cnt <> 1 then raise exception 'ÉCHEC : un viewer ne voit pas un protocole de sa bibliothèque'; end if;
  update public.protocols set data='{"hack":1}' where id='p-team';
  reset role;
  select data->>'hack' into v_hack from public.protocols where id='p-team';
  if v_hack is not null then raise exception 'ÉCHEC : un viewer a pu modifier un protocole de sa bibliothèque'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',gina,'role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into v_cnt from public.protocols where id='p-team';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un non-membre voit un protocole de la bibliothèque'; end if;
  begin
    insert into public.protocols(id,owner,library_id,data) values ('p-intru',gina,'lib-team','{"t":1}');
    raise exception 'ÉCHEC : un non-membre a pu écrire un protocole dans la bibliothèque';
  exception when insufficient_privilege then null; end;

  -- 10.4 Anti-exfiltration : un viewer ne peut pas déplacer un protocole partagé vers son perso.
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'role','authenticated')::text, true);
  set local role authenticated;
  update public.protocols set library_id=null, owner=frank where id='p-team';
  reset role;
  select library_id into v_hack from public.protocols where id='p-team';
  if v_hack is distinct from 'lib-team' then raise exception 'ÉCHEC : un viewer a pu exfiltrer un protocole partagé vers son espace perso'; end if;

  ------------------------------------------------------------------ 11. Compte rejeté : accès partagés révoqués IMMÉDIATEMENT
  -- (Audit de sécurité.) La garde d'approbation n'est testée qu'à l'ENTRÉE (invite_member,
  -- section 8.6) : les politiques *_shared_* ne re-testent pas is_approved() à chaque requête.
  -- Le trigger user_status_revoke_memberships purge donc les memberships dès qu'un statut
  -- quitte 'approved' : un membre approuvé PUIS rejeté doit perdre sur-le-champ lecture ET
  -- écriture sur les fiches, protocoles et documents partagés. État hérité : erin admin de
  -- lib-team (approuvée) ; frank viewer de lib-team ; f-team, p-team et att-t1.pdf existent.

  -- 11.1 Rejet via la RPC set_user_status (appelée par un app-admin) -> memberships purgés.
  reset role;
  insert into public.app_admins(user_id) values (alice) on conflict do nothing;
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  set local role authenticated;
  perform public.set_user_status(erin,'rejected');
  reset role;
  select count(*) into v_cnt from public.memberships where user_id=erin;
  if v_cnt <> 0 then raise exception 'ÉCHEC : le rejet du compte n''a pas purgé ses memberships (% restants)', v_cnt; end if;

  -- 11.2 erin (rejetée) ne LIT plus rien de partagé : fiches, protocoles, bucket.
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into v_cnt from public.cognitive_aids where id='f-team';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un compte rejeté lit encore une fiche partagée'; end if;
  select count(*) into v_cnt from public.protocols where id='p-team';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un compte rejeté lit encore un protocole partagé'; end if;
  select count(*) into v_cnt from storage.objects where bucket_id='attachments' and name='l/lib-team/att-t1.pdf';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un compte rejeté lit encore un document du bucket partagé'; end if;

  -- 11.3 erin (rejetée) n'ÉCRIT plus rien de partagé (UPDATE -> 0 ligne sans erreur ; INSERT -> refus).
  update public.cognitive_aids set data='{"revoked":1}' where id='f-team';
  update storage.objects set metadata='{"revoked":1}' where bucket_id='attachments' and name='l/lib-team/att-t1.pdf';
  begin
    insert into public.cognitive_aids(id,owner,library_id,data) values ('f-revoked',erin,'lib-team','{"t":1}');
    raise exception 'ÉCHEC : un compte rejeté a pu créer une fiche partagée';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.protocols(id,owner,library_id,data) values ('p-revoked',erin,'lib-team','{"t":1}');
    raise exception 'ÉCHEC : un compte rejeté a pu créer un protocole partagé';
  exception when insufficient_privilege then null; end;
  begin
    insert into storage.objects(bucket_id,name) values ('attachments','l/lib-team/att-revoked.pdf');
    raise exception 'ÉCHEC : un compte rejeté a pu déposer un document dans le bucket partagé';
  exception when insufficient_privilege then null; end;
  reset role;
  select data->>'revoked' into v_hack from public.cognitive_aids where id='f-team';
  if v_hack is not null then raise exception 'ÉCHEC : un compte rejeté a pu modifier une fiche partagée'; end if;
  select metadata->>'revoked' into v_hack from storage.objects where bucket_id='attachments' and name='l/lib-team/att-t1.pdf';
  if v_hack is not null then raise exception 'ÉCHEC : un compte rejeté a pu remplacer un document du bucket partagé'; end if;

  -- 11.4 AUTRE CHEMIN que la RPC : un UPDATE direct de user_status (app-admin via l'API REST,
  -- dashboard...) doit purger pareil — c'est le trigger qui porte la garantie, pas set_user_status.
  update public.user_status set status='rejected' where user_id=frank;
  select count(*) into v_cnt from public.memberships where user_id=frank;
  if v_cnt <> 0 then raise exception 'ÉCHEC : un UPDATE direct de user_status n''a pas purgé les memberships'; end if;

  ------------------------------------------------------------------ 12. updatedBy signé par le serveur (trigger stamp_updated_by)
  -- (Audit de sécurité.) data->>'updatedBy' est affiché « dernière modification par… » dans les
  -- bibliothèques partagées : sans le trigger, un editor pouvait signer du nom d'un collègue via
  -- l'API REST. frank est ré-approuvé et RÉ-INVITÉ editor (son rejet en 11.4 a purgé son
  -- membership : la ré-invitation est le parcours nominal documenté dans schema.sql).
  reset role;
  update public.user_status set status='approved' where user_id=frank;
  insert into public.memberships(user_id,library_id,role) values (frank,'lib-team','editor')
    on conflict (user_id,library_id) do update set role='editor';

  -- 12.1 UPDATE d'une fiche partagée avec un updatedBy FALSIFIÉ -> l'e-mail réel du JWT s'impose.
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'email','frank@test.local','role','authenticated')::text, true);
  set local role authenticated;
  update public.cognitive_aids set data='{"t":2,"updatedBy":"chef@example.org"}' where id='f-team';
  reset role;
  select data->>'updatedBy' into v_hack from public.cognitive_aids where id='f-team';
  if v_hack is distinct from 'frank@test.local' then
    raise exception 'ÉCHEC : updatedBy falsifié conservé sur une fiche (% au lieu de l''e-mail réel)', coalesce(v_hack,'NULL'); end if;

  -- 12.2 Idem à l'INSERT, et sur protocols (les deux tables portent le champ).
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'email','frank@test.local','role','authenticated')::text, true);
  set local role authenticated;
  insert into public.protocols(id,owner,library_id,data) values ('p-forge',frank,'lib-team','{"updatedBy":"chef@example.org"}');
  reset role;
  select data->>'updatedBy' into v_hack from public.protocols where id='p-forge';
  if v_hack is distinct from 'frank@test.local' then
    raise exception 'ÉCHEC : updatedBy falsifié conservé sur un protocole (% au lieu de l''e-mail réel)', coalesce(v_hack,'NULL'); end if;

  -- 12.3 Champ ABSENT du payload : il le RESTE (migrate() côté client tolère l'absence,
  -- jamais un null JSON — le trigger ne doit rien AJOUTER).
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'email','frank@test.local','role','authenticated')::text, true);
  set local role authenticated;
  update public.cognitive_aids set data='{"t":3}' where id='f-team';
  reset role;
  select count(*) into v_cnt from public.cognitive_aids where id='f-team' and data ? 'updatedBy';
  if v_cnt <> 0 then raise exception 'ÉCHEC : updatedBy a été ajouté à un payload qui ne le portait pas'; end if;

  -- 12.4 SANS claim email (service_role, SQL Editor, maintenance) : la valeur déclarée est
  -- CONSERVÉE (ne pas casser les opérations d'administration). NB : set_config(..., true)
  -- persiste jusqu'à la fin de la transaction, même après reset role -> on vide explicitement
  -- les claims pour simuler l'absence de JWT.
  perform set_config('request.jwt.claims', '{}', true);
  update public.cognitive_aids set data='{"t":4,"updatedBy":"admin@ops.local"}' where id='f-team';
  select data->>'updatedBy' into v_hack from public.cognitive_aids where id='f-team';
  if v_hack is distinct from 'admin@ops.local' then
    raise exception 'ÉCHEC : une écriture sans JWT a été écrasée (%) — la maintenance serait cassée', coalesce(v_hack,'NULL'); end if;

  ------------------------------------------------------------------ 13
  -- ÉLÉVATION DE PRIVILÈGE — le trou de forme le plus coûteux de cette suite (v4.34.0).
  -- Les onze écritures existantes sur memberships et user_status sont TOUTES faites en tant que
  -- propriétaire de table (rôle owner), qui CONTOURNE la RLS : les politiques mem_write,
  -- lib_update, lib_delete et user_status_write n'étaient donc JAMAIS exercées. Or memberships
  -- est la table dont dépendent toutes les autres politiques partagées (member_role() est
  -- consultée par fiches_shared_write, prot_shared_write, cats_shared_write, att_lib_read,
  -- att_lib_write) : une faille d'écriture y compromettrait tout d'un seul coup.
  -- Chaque test s'exécute donc en « set local role authenticated », le seul rôle que l'API expose.

  -- 13.1 Un VIEWER ne peut pas s'élever lui-même au rôle admin.
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'email','frank@test.local','role','authenticated')::text, true);
  set local role authenticated;
  begin
    update public.memberships set role='admin' where user_id=frank and library_id='lib-team';
  exception when insufficient_privilege then null;   -- refus par grant : aussi acceptable
  end;
  reset role;
  select count(*) into v_cnt from public.memberships
   where user_id=frank and library_id='lib-team' and role='admin';
  if v_cnt <> 0 then raise exception 'ÉCHEC 13.1 : un viewer s''est élevé au rôle admin'; end if;

  -- 13.2 Un NON-MEMBRE ne peut pas s'ajouter à une bibliothèque.
  perform set_config('request.jwt.claims', json_build_object('sub',gina,'email','gina@test.local','role','authenticated')::text, true);
  set local role authenticated;
  begin
    insert into public.memberships(user_id,library_id,role) values (gina,'lib-team','editor');
  exception when insufficient_privilege or check_violation then null;
  end;
  reset role;
  select count(*) into v_cnt from public.memberships where user_id=gina and library_id='lib-team';
  if v_cnt <> 0 then raise exception 'ÉCHEC 13.2 : un non-membre s''est ajouté à une bibliothèque'; end if;

  -- 13.3 Un membre (même editor) ne peut pas RENOMMER ni SUPPRIMER la bibliothèque.
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'email','erin@test.local','role','authenticated')::text, true);
  set local role authenticated;
  begin update public.libraries set name='détournée' where id='lib-team';
  exception when insufficient_privilege then null; end;
  begin delete from public.libraries where id='lib-team';
  exception when insufficient_privilege then null; end;
  reset role;
  select count(*) into v_cnt from public.libraries where id='lib-team' and name='détournée';
  if v_cnt <> 0 then raise exception 'ÉCHEC 13.3a : un editor a renommé la bibliothèque'; end if;
  select count(*) into v_cnt from public.libraries where id='lib-team';
  if v_cnt <> 1 then raise exception 'ÉCHEC 13.3b : un editor a supprimé la bibliothèque'; end if;

  -- 13.4 Personne ne s'approuve soi-même (user_status est la porte d'entrée de tout le reste).
  perform set_config('request.jwt.claims', json_build_object('sub',gina,'email','gina@test.local','role','authenticated')::text, true);
  set local role authenticated;
  begin
    insert into public.user_status(user_id,email,status) values (gina,'gina@test.local','approved');
  exception when insufficient_privilege or unique_violation then null; end;
  begin
    update public.user_status set status='approved' where user_id=gina;
  exception when insufficient_privilege then null; end;
  reset role;
  select count(*) into v_cnt from public.user_status where user_id=gina and status='approved';
  if v_cnt <> 0 then raise exception 'ÉCHEC 13.4 : un compte s''est approuvé lui-même'; end if;

  -- 13.5 LE RÔLE ANONYME N'A RIEN. La clé publishable est publiée en clair dans index.html :
  -- anon est utilisable par quiconque contre l'API REST. C'est donc LE contrôle sur lequel repose
  -- toute la confiance dans la posture du schéma.
  --
  -- REFONTE — ce contrôle était AVEUGLE À CE QU'IL PRÉTEND COUVRIR, deux fois :
  --   (a) il énumérait SEPT tables NOMMÉES EN DUR. Toute table ajoutée ensuite échappait au
  --       balayage, et le script continuait d'afficher « ✅ TOUS LES TESTS RLS PASSENT » — le vert
  --       était exactement le même qu'avant, personne n'aurait vu la différence ;
  --   (b) il ne testait AUCUNE FONCTION. Or la « prohibition » du schéma ne portait pas sur le
  --       pseudo-rôle PUBLIC, à qui PostgreSQL accorde EXECUTE par défaut sur toute fonction et
  --       dont anon hérite : les fonctions étaient appelables sans compte, et ce test ne pouvait
  --       pas le voir (correctif : schema.sql § 5quater).
  -- On passe donc d'assertions ÉNUMÉRATIVES à des assertions de CATALOGUE : elles ne peuvent plus
  -- prendre de retard sur le schéma, et une table ou une fonction ajoutée demain est couverte
  -- d'office. (Leçon v4.31.1 / v4.44.1 : un contrôle qui ne peut pas échouer ne prouve rien.)

  -- 13.5a AUCUN grant de table pour anon, quelle que soit la table.
  -- Casts EXPLICITES vers text : les colonnes d'information_schema sont des domaines
  -- (`sql_identifier` sur `name`) et `pg_proc.proname` est de type `name` ; s'en remettre à la
  -- coercition implicite pour résoudre `||` et `string_agg` marche, mais dépend de la version.
  select string_agg(distinct table_name::text || '(' || privilege_type::text || ')', ', ')
    into v_list
    from information_schema.role_table_grants
   where grantee = 'anon' and table_schema = 'public';
  if v_list is not null then
    raise exception 'ÉCHEC 13.5a : anon détient des privilèges de table -> %', v_list; end if;

  -- 13.5b Les fonctions exécutables par anon sont EXACTEMENT la liste blanche (vide par défaut).
  -- `has_function_privilege` tient compte de l'héritage depuis PUBLIC : c'est précisément ce que
  -- le `revoke ... from anon` seul ne voyait pas.
  select string_agg(p.proname::text, ', ' order by p.proname) into v_list
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and has_function_privilege('anon', p.oid, 'execute')
     and not (p.proname::text = any (v_anon_fns_ok));
  if v_list is not null then
    raise exception 'ÉCHEC 13.5b : anon peut exécuter des fonctions hors liste blanche -> %', v_list; end if;

  -- 13.5c BALAYAGE EXHAUSTIF ET DYNAMIQUE de toutes les tables du schéma : le refus peut venir du
  -- grant (insufficient_privilege) OU de la RLS (0 ligne) — les deux conviennent, une LECTURE non.
  -- LA LISTE SE CONSTRUIT AVANT LE CHANGEMENT DE RÔLE, et c'est le point à ne pas rater :
  -- `information_schema.tables` ne montre à un rôle que les tables sur lesquelles il a un
  -- privilège. Énumérée SOUS anon — qui n'en a aucun — elle serait VIDE, la boucle ne tournerait
  -- pas, et le test passerait au vert sans avoir rien balayé. Encore le même piège.
  select array_agg(table_name::text order by table_name) into v_tbls
    from information_schema.tables
   where table_schema = 'public' and table_type = 'BASE TABLE';
  if v_tbls is null or array_length(v_tbls,1) < 5 then
    raise exception 'ÉCHEC 13.5c : liste de tables invraisemblable (%) — balayage non probant',
      coalesce(array_length(v_tbls,1),0); end if;
  perform set_config('request.jwt.claims', json_build_object('role','anon')::text, true);
  set local role anon;
  foreach v_tbl in array v_tbls
  loop
    begin
      execute format('select count(*) from public.%I', v_tbl) into v_leak;
    exception when insufficient_privilege then v_leak := 0; end;
    if v_leak <> 0 then
      raise exception 'ÉCHEC 13.5c : anon lit public.% (% lignes)', v_tbl, v_leak; end if;
  end loop;

  -- 13.5d is_approved() ne doit JAMAIS être vraie sans compte : c'est le prédicat sur lequel
  -- s'appuient les politiques de l'espace perso, et un futur garde-fou écrit avec lui doit tenir.
  begin
    if public.is_approved() then
      raise exception 'ÉCHEC 13.5d : is_approved() est VRAIE pour anon'; end if;
    if public.my_status() is not null then
      raise exception 'ÉCHEC 13.5d : my_status() répond « % » à anon', public.my_status(); end if;
  exception when insufficient_privilege then null;   -- refus par le grant : parfait aussi
  end;
  reset role;

  -- 13.6 invite_member EXIGE un e-mail vérifié (correctif v4.34.0). Un compte créé par la simple
  -- DEMANDE d'un code (create_user:true) mais jamais confirmé était invité avec succès, puis
  -- perdait son adhésion à sa première vraie connexion — sans trace ni message.
  insert into auth.users(id,email,email_confirmed_at)
    values ('88888888-8888-8888-8888-888888888888','henri@test.local',null)
    on conflict (id) do nothing;
  reset role;
  -- La bibliothèque AVANT l'adhésion : memberships.library_id la référence (clé étrangère).
  -- Et la colonne est `created_by`, non `owner` (relu sur le schéma, pas supposé).
  insert into public.libraries(id,name,created_by) values ('lib-inv','Invitations',erin)
    on conflict (id) do nothing;
  insert into public.memberships(user_id,library_id,role) values (erin,'lib-inv','admin')
    on conflict do nothing;
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'email','erin@test.local','role','authenticated')::text, true);
  set local role authenticated;
  select public.invite_member('lib-inv','henri@test.local','viewer') into v_hack;
  reset role;
  if v_hack is distinct from 'not_found' then
    raise exception 'ÉCHEC 13.6 : un compte à l''e-mail NON vérifié a été invité (retour %)', coalesce(v_hack,'NULL'); end if;

  ------------------------------------------------------------------ 14. PARTAGE DE SESSION
  -- Première surface NON AUTHENTIFIÉE du projet : c'est la section qui compte le plus. Chaque
  -- test correspond à une faille identifiée AVANT l'écriture du schéma, et vérifie qu'elle est
  -- bien fermée — pas que la fonctionnalité « marche ».
  reset role;
  insert into auth.users(id,email) values (alice,'alice@test.local') on conflict (id) do nothing;

  -- 14.1 Un compte NON APPROUVÉ ne peut pas ouvrir un partage (le partage ne doit pas devenir un
  -- contournement du gate d'approbation).
  insert into public.user_status(user_id,email,status) values (gina,'gina@test.local','pending')
    on conflict (user_id) do update set status='pending';
  update public.app_settings set require_approval = true where id;
  perform set_config('request.jwt.claims', json_build_object('sub',gina,'role','authenticated')::text, true);
  set local role authenticated;
  v_j := public.share_open('sh-ko','s1','f1','{"title":"T"}'::jsonb,'scribe',60);
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 14.1 : un compte pending a ouvert un partage'; end if;
  reset role;
  update public.app_settings set require_approval = false where id;

  -- 14.2 Ouverture nominale par Alice (approuvée) : code renvoyé, ligne d'hôte créée.
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  set local role authenticated;
  v_j := public.share_open('sh-1','sess-1','fic-1','{"title":"ACR"}'::jsonb,'scribe',60);
  reset role;
  if not (v_j->>'ok')::boolean then raise exception 'ÉCHEC 14.2 : ouverture refusée (%)', v_j->>'err'; end if;
  v_code := v_j->>'code';
  if length(v_code) <> 8 then raise exception 'ÉCHEC 14.2 : code de longueur % au lieu de 8', length(v_code); end if;
  select count(*) into v_cnt from public.session_participants where share_id='sh-1' and is_owner;
  if v_cnt <> 1 then raise exception 'ÉCHEC 14.2 : ligne d''hôte absente'; end if;

  -- 14.3 Un INVITÉ SANS COMPTE rejoint avec le code, et reçoit un secret. C'est le cœur du besoin.
  perform set_config('request.jwt.claims', json_build_object('role','anon')::text, true);
  set local role anon;
  v_j := public.share_join(v_code, 'IDE');
  if not (v_j->>'ok')::boolean then raise exception 'ÉCHEC 14.3 : jointure anon refusée (%)', v_j->>'err'; end if;
  v_sec := v_j->>'secret';
  if v_sec is null or length(v_sec) < 16 then raise exception 'ÉCHEC 14.3 : secret absent ou trop court'; end if;
  if v_j->'fiche'->>'title' is distinct from 'ACR' then raise exception 'ÉCHEC 14.3 : instantané de fiche non transmis'; end if;

  -- 14.4 LE CODE EST CONSOMMÉ. Un lien ou une capture qui circulerait ensuite n'ouvre plus rien —
  -- c'est ce qui rend la coupure d'un invité effective plutôt que décorative.
  v_j2 := public.share_join(v_code, 'Curieux');
  if (v_j2->>'ok')::boolean then raise exception 'ÉCHEC 14.4 : le code a resservi après consommation'; end if;

  /* 14.5 CAPACITÉS — LA LIGNE PASSE SUR LA DESTRUCTION, PAS SUR LA HIÉRARCHIE (v4.55.0).
     Elle passait sur « conduire ou suivre », et c'était une mauvaise lecture d'AC 120-71B
     §5.2.2.1 : ce paragraphe décrit une répartition de la PAROLE, et dans ce modèle c'est CELUI
     QUI LIT qui fait avancer la liste. La SFAR (« le lecteur : lire et GUIDER »), l'ECAM (le pilot
     monitoring actionne l'ECP) et McEvoy 2014 (le lecteur tient l'UNIQUE appareil, 99,5 % contre
     70 %) disent tous la même chose. Le critère « détruit / ne détruit pas » était d'ailleurs déjà
     celui écrit dans `share_kind_allowed` pour `mark_void` ; il vaut désormais pour tous.
     OUVERT AU SCRIBE : cocher, naviguer, arrêter un minuteur (l'`elapsedMs` est conservé).
     RÉSERVÉ : terminer le partage — et, ci-dessous, décocher et remettre à zéro. */
  v_j := public.share_push(v_sec, null, jsonb_build_array(
           jsonb_build_object('event_id', gen_random_uuid(), 'kind','check',       'payload','{}'::jsonb),
           jsonb_build_object('event_id', gen_random_uuid(), 'kind','nav',         'payload','{}'::jsonb),
           jsonb_build_object('event_id', gen_random_uuid(), 'kind','timer_stop',  'payload','{}'::jsonb),
           jsonb_build_object('event_id', gen_random_uuid(), 'kind','end',         'payload','{}'::jsonb),
           jsonb_build_object('event_id', gen_random_uuid(), 'kind','uncheck',     'payload','{}'::jsonb),
           jsonb_build_object('event_id', gen_random_uuid(), 'kind','timer_reset', 'payload','{}'::jsonb)));
  if not (v_j->>'ok')::boolean then raise exception 'ÉCHEC 14.5 : push refusé en bloc (%)', v_j->>'err'; end if;
  if (v_j->>'accepted')::int <> 3 or (v_j->>'rejected')::int <> 3 then
    raise exception 'ÉCHEC 14.5 : capacités du scribe non appliquées (accepté %, rejeté %)',
      v_j->>'accepted', v_j->>'rejected'; end if;
  /* ON NOMME CE QUI DOIT PASSER, plutôt que de se fier à un COMPTE : trois acceptés pourraient
     être les trois mauvais. Ces lectures interrogent la TABLE en direct, et l'on est ici sous le
     rôle `anon` (posé au § 14.3) — qui n'a AUCUN privilège de table, ce qui est tout l'objet du
     § 13. On reprend donc les droits le temps de la vérification, puis on RESTITUE le rôle
     exactement comme on l'a trouvé : les sections suivantes s'appuient dessus. */
  reset role;
  if not exists (select 1 from public.session_events where share_id='sh-1' and kind='nav') then
    raise exception 'ÉCHEC 14.5 : le scribe ne peut pas faire avancer la checklist'; end if;
  if not exists (select 1 from public.session_events where share_id='sh-1' and kind='timer_stop') then
    raise exception 'ÉCHEC 14.5 : le scribe ne peut pas arrêter un minuteur'; end if;
  if exists (select 1 from public.session_events where share_id='sh-1'
              and kind in ('uncheck','timer_reset','end')) then
    raise exception 'ÉCHEC 14.5 : un geste DESTRUCTEUR du scribe a été écrit'; end if;
  set local role anon;

  -- 14.5bis CONTRAT DE LECTURE. Le client dépend de deux champs pour détecter une divergence
  -- silencieuse : l'IDENTIFIANT de chaque évènement (il en calcule l'empreinte du flux reçu) et
  -- l'EMPREINTE que le serveur calcule sur le flux écrit. Les oublier ne casserait rien de
  -- visible — le partage marcherait, et la détection serait morte sans que rien ne le dise.
  v_j := public.share_pull(v_sec, null, 0);
  if v_j->'events'->0->>'id' is null then
    raise exception 'ÉCHEC 14.5bis : les évènements ne portent pas leur identifiant'; end if;
  -- Validation sans ancre de regex (longueur + aucun caractère interdit) : évite un « $ » isolé,
  -- que check-sql.mjs doit pouvoir lire comme la signature d'un délimiteur mutilé.
  if coalesce(length(v_j->>'stream'), 0) <> 64 or v_j->>'stream' ~ '[^0-9a-f]' then
    raise exception 'ÉCHEC 14.5bis : empreinte de flux absente ou mal formée (%)',
      coalesce(v_j->>'stream','NULL'); end if;
  -- Et elle doit RÉELLEMENT dépendre du flux : deux partages de contenus différents ne peuvent
  -- pas produire la même. (Contre-épreuve : sans elle, une constante passerait le test ci-dessus.)
  v_hack := v_j->>'stream';

  -- 14.6 L'ACTEUR N'EST PAS FALSIFIABLE. Même en glissant un `actor` dans le payload, la ligne
  -- écrite porte le participant DÉDUIT du secret. L'attribution est tout l'objet du contrôle que
  -- l'hôte demande (« savoir ce qui a été modifié par l'invité ») : si elle se forge, il n'a rien.
  v_j := public.share_push(v_sec, null, jsonb_build_array(jsonb_build_object(
           'event_id', gen_random_uuid(), 'kind','mark',
           'payload', jsonb_build_object('actor','00000000-0000-0000-0000-000000000000'))));
  -- L'empreinte doit avoir CHANGÉ : un évènement de plus, un flux différent. Sans ce contrôle,
  -- une constante ou un hachage d'entrée vide passerait le test de forme ci-dessus.
  v_j := public.share_pull(v_sec, null, 0);
  if v_j->>'stream' = v_hack then
    raise exception 'ÉCHEC 14.5bis : l''empreinte ne dépend pas du flux (inchangée après écriture)'; end if;
  reset role;
  select count(*) into v_cnt from public.session_events e
    join public.session_participants p on p.share_id=e.share_id and p.participant=e.actor
   where e.share_id='sh-1' and p.is_owner;
  if v_cnt <> 0 then raise exception 'ÉCHEC 14.6 : un évènement d''invité est attribué à l''hôte'; end if;

  -- 14.7 COUPURE. L'hôte coupe l'invité : la lecture doit DIRE « revoked », jamais se taire —
  -- un invité qui prendrait la coupure pour une panne réseau continuerait de cocher dans le vide,
  -- ce qui est le pire mode de défaillance du dispositif.
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  set local role authenticated;
  update public.session_participants set revoked_at = now()
   where share_id='sh-1' and not is_owner;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('role','anon')::text, true);
  set local role anon;
  v_j := public.share_pull(v_sec, null, 0);
  if v_j->>'status' is distinct from 'revoked' then
    raise exception 'ÉCHEC 14.7 : un invité coupé lit « % » au lieu de « revoked »', v_j->>'status'; end if;
  v_j := public.share_push(v_sec, null, jsonb_build_array(jsonb_build_object(
           'event_id', gen_random_uuid(), 'kind','check', 'payload','{}'::jsonb)));
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 14.7 : un invité coupé écrit encore'; end if;
  if v_j->>'err' is distinct from 'revoked' then
    raise exception 'ÉCHEC 14.7 : refus non motivé (%)', v_j->>'err'; end if;

  -- 14.8 Un secret INCONNU n'ouvre rien, et un partage d'autrui reste invisible.
  v_j := public.share_pull('secret-totalement-invente-mais-assez-long', null, 0);
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 14.8 : un secret inventé a été accepté'; end if;
  v_j := public.share_pull(null, 'sh-1', 0);
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 14.8 : anon a lu un partage en le nommant'; end if;
  reset role;

  -- 14.8bis DÉTACHEMENT — « je continue seul », le repli hors dispositif quand le réseau ne
  -- revient pas. Deux propriétés à garantir, et elles se testent ensemble :
  --   (a) un lot qui porte un `detach` NE PORTE QUE LUI. Les actions relevées pendant la
  --       désynchronisation ne doivent pas s'écrire sur la session vive de l'hôte, qui a avancé
  --       entre-temps : ce serait un enregistrement faux. Elles restent la trace de la session
  --       autonome de l'invité, sur son appareil ;
  --   (b) le détachement est TERMINAL. Le même secret ne réécrit plus jamais — on ne se
  --       re-synchronise pas en douce après dix minutes de divergence. Revenir exige une
  --       NOUVELLE jointure, donc un geste de l'hôte : la porte se rouvre par devant.
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  set local role authenticated;
  v_j := public.share_admit('sh-1', 120);
  reset role;
  if not (v_j->>'ok')::boolean then raise exception 'ÉCHEC 14.8bis : share_admit refusé'; end if;
  v_code := v_j->>'code';
  select count(*) into v_cnt from public.session_events where share_id='sh-1';   -- TÉMOIN, figé ici
  perform set_config('request.jwt.claims', json_build_object('role','anon')::text, true);
  set local role anon;
  v_j  := public.share_join(v_code, 'Interne');
  v_sec := v_j->>'secret';
  if v_sec is null then raise exception 'ÉCHEC 14.8bis : seconde jointure refusée'; end if;

  -- (a) Un lot portant un `detach` ne porte QUE lui.
  v_j := public.share_push(v_sec, null, jsonb_build_array(
           jsonb_build_object('event_id', gen_random_uuid(), 'kind','check',  'payload','{}'::jsonb),
           jsonb_build_object('event_id', gen_random_uuid(), 'kind','mark',   'payload','{}'::jsonb),
           jsonb_build_object('event_id', gen_random_uuid(), 'kind','detach', 'payload','{}'::jsonb)));
  if (v_j->>'accepted')::int <> 1 then
    raise exception 'ÉCHEC 14.8bis(a) : % évènements acceptés avec un detach dans le lot (attendu 1)',
      v_j->>'accepted'; end if;
  reset role;
  select count(*) into v_leak from public.session_events where share_id='sh-1';
  if v_leak <> v_cnt + 1 then
    raise exception 'ÉCHEC 14.8bis(a) : % évènement(s) écrit(s) au lieu du seul detach', v_leak - v_cnt; end if;

  -- (b) Son ÉTAT ne repasse plus : une coche est rejetée, et la lecture le dit en toutes lettres.
  perform set_config('request.jwt.claims', json_build_object('role','anon')::text, true);
  set local role anon;
  v_j := public.share_push(v_sec, null, jsonb_build_array(jsonb_build_object(
           'event_id', gen_random_uuid(), 'kind','check', 'payload','{}'::jsonb)));
  if (v_j->>'accepted')::int <> 0 then
    raise exception 'ÉCHEC 14.8bis(b) : un détaché a réécrit l''état (accepté %)', v_j->>'accepted'; end if;
  v_j := public.share_pull(v_sec, null, 0);
  if v_j->>'status' is distinct from 'detached' then
    raise exception 'ÉCHEC 14.8bis(b) : la lecture d''un détaché dit « % »', v_j->>'status'; end if;

  -- (c) …MAIS SON RELEVÉ REMONTE. C'est tout l'écart entre « ne pas fusionner » et « perdre » :
  -- celui qui a poursuivi seul détient la trace d'une intervention réelle. Elle rejoint le
  -- compte-rendu de l'hôte en ANNEXE attribuée et datée — jamais en écrasant son état.
  v_j := public.share_push(v_sec, null, jsonb_build_array(jsonb_build_object(
           'event_id', gen_random_uuid(), 'kind','offline_mark',
           'ts', to_char(now() - interval '3 minutes', 'YYYY-MM-DD"T"HH24:MI:SSOF'),
           'payload', jsonb_build_object('ref', jsonb_build_object('type','core','k','adre')))));
  if (v_j->>'accepted')::int <> 1 then
    raise exception 'ÉCHEC 14.8bis(c) : l''annexe d''un détaché est refusée (accepté %)',
      v_j->>'accepted'; end if;
  reset role;
  select count(*) into v_leak from public.session_events where share_id='sh-1';
  if v_leak <> v_cnt + 2 then
    raise exception 'ÉCHEC 14.8bis(c) : total % au lieu de % (detach + annexe)', v_leak, v_cnt + 2; end if;
  -- L'heure retenue est celle du GESTE, pas celle du retour du réseau — sans quoi le compte-rendu
  -- rangerait une action de 14:32 après une action de 14:35.
  select count(*) into v_leak from public.session_events
   where share_id='sh-1' and kind='offline_mark' and client_ts < now() - interval '2 minutes';
  if v_leak <> 1 then raise exception 'ÉCHEC 14.8bis(c) : l''annexe a perdu l''heure du geste'; end if;
  select count(*) into v_leak from public.session_participants
   where share_id='sh-1' and detached_at is not null;
  if v_leak <> 1 then raise exception 'ÉCHEC 14.8bis : detached_at non posé (l''hôte ne saura pas)'; end if;

  -- 14.9 PURGE AUTO-EXÉCUTOIRE : un partage expiré depuis plus de 30 min disparaît au premier
  -- appel, sans ordonnanceur (l'hébergement est statique : personne ne lancerait une tâche).
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  set local role authenticated;
  v_j := public.share_open('sh-old','sess-old','fic-1','{"title":"Vieux"}'::jsonb,'scribe',60);
  reset role;
  update public.shared_sessions set expires_at = now() - interval '2 hours' where id='sh-old';
  perform public.share_purge();
  select count(*) into v_cnt from public.shared_sessions where id='sh-old';
  if v_cnt <> 0 then raise exception 'ÉCHEC 14.9 : un partage expiré depuis 2 h a survécu à la purge'; end if;

  -- 14.10 RGPD : la suppression de compte emporte les partages. Sans le `delete` explicite, soit
  -- ils survivent, soit la violation de clé étrangère annule TOUTE la fonction — et le droit à
  -- l'effacement disparaît pour quiconque a partagé une seule fois.
  -- Compte DÉDIÉ (Ivan) : la fonction refuse à juste titre de supprimer un app-admin, et Alice
  -- en est devenu un au §11. Au passage, ce bloc couvre le chemin HÔTE de `share_push` — un
  -- propriétaire authentifié écrit sans secret, son identité venant du JWT.
  reset role;
  insert into auth.users(id,email) values (ivan,'ivan@test.local') on conflict (id) do nothing;
  insert into public.user_status(user_id,email,status) values (ivan,'ivan@test.local','approved')
    on conflict (user_id) do update set status='approved';
  perform set_config('request.jwt.claims', json_build_object('sub',ivan,'role','authenticated')::text, true);
  set local role authenticated;
  v_j := public.share_open('sh-2','sess-2','fic-2','{"title":"Anaphylaxie"}'::jsonb,'scribe',60);
  if not (v_j->>'ok')::boolean then raise exception 'ÉCHEC 14.10 : ouverture par Ivan refusée (%)', v_j->>'err'; end if;
  -- L'hôte pousse SANS secret : `share_resolve` le reconnaît par son JWT. Et il a le rôle `lead`,
  -- donc `nav` — interdit au scribe en 14.5 — doit passer ici.
  v_j := public.share_push(null, 'sh-2', jsonb_build_array(
           jsonb_build_object('event_id', gen_random_uuid(), 'kind','nav', 'payload','{}'::jsonb)));
  if not (v_j->>'ok')::boolean or (v_j->>'accepted')::int <> 1 then
    raise exception 'ÉCHEC 14.10 : l''hôte authentifié ne peut pas écrire (%, accepté %)',
      v_j->>'err', v_j->>'accepted'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',ivan,'role','authenticated',
    'amr',json_build_array(json_build_object('method','otp','timestamp',extract(epoch from now())::bigint)))::text, true);
  perform public.delete_my_account();
  reset role;
  select count(*) into v_cnt from public.shared_sessions where owner=ivan;
  if v_cnt <> 0 then raise exception 'ÉCHEC 14.10 : des partages ont survécu à la suppression du compte'; end if;
  select count(*) into v_cnt from public.session_events where share_id='sh-2';
  if v_cnt <> 0 then raise exception 'ÉCHEC 14.10 : des évènements ont survécu (cascade absente)'; end if;

  ---------------------------------------------------------------- 14.11
  -- LA LISTE BLANCHE DES CHAMPS EST SERVEUR, PAS SEULEMENT CLIENT. Elle n'existait qu'en
  -- JavaScript : un appel REST direct la traversait, et `images` (jusqu'à 24 Mo de base64),
  -- `localInfo` (téléphones de renfort et de régulation) ou la liste des documents partaient
  -- avec la fiche. On pousse ici EXACTEMENT ce qu'un appelant hostile pousserait.
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated',
    'amr',json_build_array(json_build_object('method','otp','timestamp',extract(epoch from now())::bigint)))::text, true);
  set local role authenticated;
  v_j := public.share_open('sh-wl','sess-wl','f-wl', jsonb_build_object(
           'id','f-wl','title','Fiche','status','', 'blocks', jsonb_build_array(
              jsonb_build_object('id','b1','steps',jsonb_build_array('a'),'image','data:image/png;base64,AAAA')),
           'localInfo','Tél renfort 06…','images',jsonb_build_array('data:image/png;base64,BBBB'),
           'attachments',jsonb_build_array(jsonb_build_object('id','att','name','x.pdf')),
           'references',jsonb_build_array('ref'),'ownerId',alice::text,'libraryId','lib-1'),
         'scribe', 60);
  if not (v_j->>'ok')::boolean then
    raise exception 'ÉCHEC 14.11 : ouverture refusée (%)', v_j->>'err'; end if;
  reset role;
  select fiche_snap into v_snap from public.shared_sessions where id='sh-wl';
  if v_snap ? 'localInfo' or v_snap ? 'images' or v_snap ? 'attachments'
     or v_snap ? 'references' or v_snap ? 'ownerId' or v_snap ? 'libraryId' then
    raise exception 'ÉCHEC 14.11 : un champ interdit a été stocké (%)', v_snap; end if;
  if not (v_snap ? 'title') or not (v_snap ? 'blocks') then
    raise exception 'ÉCHEC 14.11 : un champ autorisé a été perdu'; end if;
  if (v_snap->'blocks'->0) ? 'image' then
    raise exception 'ÉCHEC 14.11 : l''image d''un BLOC a survécu'; end if;

  ---------------------------------------------------------------- 14.12
  -- PLAFOND DE PARTAGES VIVANTS PAR PROPRIÉTAIRE. Il n'en existait aucun : un compte — qui coûte
  -- une adresse jetable, l'approbation étant désactivée par défaut — pouvait en ouvrir sans fin.
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated',
    'amr',json_build_array(json_build_object('method','otp','timestamp',extract(epoch from now())::bigint)))::text, true);
  set local role authenticated;
  for v_cnt in 1..6 loop
    v_j := public.share_open('sh-cap-'||v_cnt, 'sess-cap', 'f-cap',
             jsonb_build_object('id','f-cap','title','T','status',''), 'scribe', 60);
  end loop;
  if (v_j->>'ok')::boolean then
    raise exception 'ÉCHEC 14.12 : aucun plafond de partages vivants'; end if;
  if v_j->>'err' <> 'too_many_shares' then
    raise exception 'ÉCHEC 14.12 : motif inattendu (%)', v_j->>'err'; end if;
  reset role;

  ---------------------------------------------------------------- 14.13
  -- `share_admit` VÉRIFIE L'EXPIRATION ET LE QUOTA. Il ne le faisait pas : sur un partage expiré
  -- ou plein, il rendait un code NEUF que `share_join` refusait aussitôt — deux boucles infinies,
  -- invisibles des deux côtés, et il écrasait au passage un code peut-être encore vivant.
  update public.shared_sessions set expires_at = now() - interval '1 minute' where id='sh-wl';
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated',
    'amr',json_build_array(json_build_object('method','otp','timestamp',extract(epoch from now())::bigint)))::text, true);
  set local role authenticated;
  v_j := public.share_admit('sh-wl', 120);
  if (v_j->>'ok')::boolean then
    raise exception 'ÉCHEC 14.13 : un partage EXPIRÉ a rendu un code neuf'; end if;
  if v_j->>'err' <> 'expired' then
    raise exception 'ÉCHEC 14.13 : motif inattendu (%)', v_j->>'err'; end if;
  reset role;

  ---------------------------------------------------------------- 14.14
  -- `session_start` — l'heure du SOIN — est réservée à celui qui conduit.
  if public.share_kind_allowed('scribe','session_start') then
    raise exception 'ÉCHEC 14.14 : un scribe peut redater le début du soin'; end if;
  if not public.share_kind_allowed('lead','session_start') then
    raise exception 'ÉCHEC 14.14 : le lead ne peut pas dater le début du soin'; end if;

  ---------------------------------------------------------------- 14.15 à 14.17
  /* TROIS DURCISSEMENTS, UN SEUL DÉCOR. Ces sections sont AUTONOMES : elles ouvrent leur propre
     partage et font rejoindre leur propre participant, au lieu de s'appuyer sur l'état laissé par
     les tests précédents. Une assertion qui dépend de ce qu'un test antérieur a bien voulu laisser
     derrière lui casse au premier réordonnancement — et c'est ce qui vient d'arriver.
     PRÉALABLE : 14.12 a rempli le quota de partages vivants d'Alice (le plafond est de cinq).
     On expire donc les siens avant d'en ouvrir un neuf, sinon l'ouverture échouerait pour une
     raison qui n'a rien à voir avec ce qu'on mesure ici. */
  update public.shared_sessions set expires_at = now() - interval '1 minute' where owner = alice;
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated',
    'amr',json_build_array(json_build_object('method','otp','timestamp',extract(epoch from now())::bigint)))::text, true);
  set local role authenticated;
  v_j := public.share_open('sh-hard','sess-hard','f-hard',
           jsonb_build_object('id','f-hard','title','Durcissement','status',''), 'scribe', 60);
  if not (v_j->>'ok')::boolean then
    raise exception 'ÉCHEC 14.15 : ouverture du décor refusée (%)', v_j->>'err'; end if;
  v_code := v_j->>'code';
  reset role;

  -- 14.16 — LE LIBELLÉ D'UN PARTICIPANT NE PORTE AUCUN MÉTACARACTÈRE DE BALISAGE. Il s'affiche
  -- chez TOUS les autres ; l'application ne propose qu'une liste fermée de neuf rôles, mais un
  -- client modifié n'est pas tenu par un `<select>`.
  v_j2 := public.share_join(v_code, '<img src=x onerror=alert(1)>');
  if not (v_j2->>'ok')::boolean then
    raise exception 'ÉCHEC 14.16 : jointure refusée à tort (%)', v_j2->>'err'; end if;
  v_sec := v_j2->>'secret';
  if exists (select 1 from public.session_participants
              where share_id = 'sh-hard'
                and (label like '%<%' or label like '%>%' or label like '%"%')) then
    raise exception 'ÉCHEC 14.16 : un libellé de participant porte du balisage'; end if;

  -- 14.15 — LISTE BLANCHE DES CLÉS DE PAYLOAD. Le serveur ne validait que le type et la taille :
  -- c'est de là que partaient les deux injections d'attribut reproduites côté client (v4.53.1).
  -- `label` est absent de la liste, ET C'EST LE POINT — c'est ce qui rend vraie AU NIVEAU DU
  -- SERVEUR la promesse « aucun texte libre ne traverse le réseau ».
  v_j := public.share_push(v_sec, 'sh-hard',
           jsonb_build_array(jsonb_build_object(
             'event_id', gen_random_uuid(), 'kind', 'mark',
             'payload', jsonb_build_object('id','e1','t',1,'label','<img src=x>','zz','autre'))));
  if not (v_j->>'ok')::boolean then
    raise exception 'ÉCHEC 14.15 : un mark légitime a été refusé (%)', v_j->>'err'; end if;
  if exists (select 1 from public.session_events
              where share_id = 'sh-hard' and kind = 'mark' and payload ? 'label') then
    raise exception 'ÉCHEC 14.15 : un LIBELLÉ a traversé le serveur'; end if;
  if exists (select 1 from public.session_events
              where share_id = 'sh-hard' and kind = 'mark' and payload ? 'zz') then
    raise exception 'ÉCHEC 14.15 : une clé hors liste blanche a traversé'; end if;
  if not exists (select 1 from public.session_events
                  where share_id = 'sh-hard' and kind = 'mark' and payload ? 'id') then
    raise exception 'ÉCHEC 14.15 : la liste blanche a mangé une clé légitime'; end if;

  -- 14.17 — LA COUPURE MORD AU SERVEUR, pas seulement chez le coupé. `share_pull` renvoyait
  -- `status: revoked` ET le flux complet : c'était son application qui gelait l'écran, donc un
  -- client modifié continuait de lire la session jusqu'à l'expiration. Le STATUT reste renvoyé —
  -- il faut qu'il SACHE, sinon la coupure passerait pour une panne de réseau.
  update public.session_participants set revoked_at = now()
   where share_id = 'sh-hard' and participant = (v_j2->>'me')::uuid;
  v_j := public.share_pull(v_sec, 'sh-hard', 0);
  if not (v_j->>'ok')::boolean then
    raise exception 'ÉCHEC 14.17 : la lecture d''un coupé devrait répondre, pas refuser'; end if;
  if (v_j->>'status') <> 'revoked' then
    raise exception 'ÉCHEC 14.17 : le coupé ignore qu''il est coupé (%)', v_j->>'status'; end if;
  if jsonb_array_length(v_j->'events') <> 0 then
    raise exception 'ÉCHEC 14.17 : un participant COUPÉ reçoit encore les évènements'; end if;
  if jsonb_array_length(v_j->'participants') <> 0 then
    raise exception 'ÉCHEC 14.17 : un participant COUPÉ voit encore la liste des participants'; end if;

  -- 14.18 — LA PASSATION S'ANNONCE DES DEUX CÔTÉS. `handoff` ne change AUCUN état serveur : il
  -- porte une offre ou une prise. Le rôle, lui, s'écrit sur `session_participants`, que la
  -- politique `sparts_own` réserve au propriétaire. Le réserver au lead aurait interdit à l'invité
  -- d'ACCEPTER — c'est-à-dire d'accomplir le temps que la doctrine exige de LUI (AC 61-115).
  if not public.share_kind_allowed('scribe','handoff') then
    raise exception 'ÉCHEC 14.18 : un invité ne peut pas PRENDRE la main'; end if;
  if not public.share_kind_allowed('lead','handoff') then
    raise exception 'ÉCHEC 14.18 : celui qui conduit ne peut pas PROPOSER la main'; end if;

  -- 14.19 — HISTORIQUE DE SESSIONS : une seule politique, et elle ne prête pas.
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated',
    'amr',json_build_array(json_build_object('method','otp','timestamp',extract(epoch from now())::bigint)))::text, true);
  set local role authenticated;
  insert into public.sessions(id,data,exercise) values ('sess-a','{"ficheTitle":"ACR"}'::jsonb,false);
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub',bob,'role','authenticated',
    'amr',json_build_array(json_build_object('method','otp','timestamp',extract(epoch from now())::bigint)))::text, true);
  set local role authenticated;
  select count(*) into v_cnt from public.sessions where id = 'sess-a';
  if v_cnt <> 0 then
    raise exception 'ÉCHEC 14.19 : Bob lit l''historique de sessions d''Alice'; end if;
  begin
    update public.sessions set data = '{"x":1}'::jsonb where id = 'sess-a';
    if found then raise exception 'ÉCHEC 14.19 : Bob écrit dans l''historique d''Alice'; end if;
  exception when insufficient_privilege then null; end;
  reset role;


  ------------------------------------------------------------------ 15. CRÉER OU DEMANDER UNE BIBLIOTHÈQUE (v5.51)
  -- État hérité : alice app-admin ; frank approuvé, viewer de lib-team ; require_approval=TRUE.
  -- 15.1 Règle par défaut ('creators', liste vide) : frank ne crée pas (comportement d'avant).
  reset role;
  update public.app_settings set library_creation = 'creators' where id;
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'email','frank@test.local','role','authenticated')::text, true);
  set local role authenticated;
  if public.can_create_library() then raise exception 'ÉCHEC 15.1 : frank peut créer sans être autorisé'; end if;
  begin
    insert into public.libraries(id,name) values ('lib-f1','Frank');
    raise exception 'ÉCHEC 15.1 : frank a créé une bibliothèque sans autorisation';
  exception when insufficient_privilege then null; end;
  -- 15.2 La table des personnes autorisées n'est pas lisible ni modifiable en direct, ni la RPC hors admin.
  begin
    perform 1 from public.library_creators limit 1;
    raise exception 'ÉCHEC 15.2 : library_creators est lisible';
  exception when insufficient_privilege then null; end;
  begin
    perform public.set_library_creator(frank, true);
    raise exception 'ÉCHEC 15.2 : frank s''est autorisé lui-même';
  exception when raise_exception then
    if sqlerrm like 'ÉCHEC%' then raise; end if; end;
  -- 15.3 Autorisé par l'administrateur : frank crée POUR LUI, jamais au nom d'un autre.
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'email','alice@test.local','role','authenticated')::text, true);
  perform public.set_library_creator(frank, true);
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'email','frank@test.local','role','authenticated')::text, true);
  set local role authenticated;
  insert into public.libraries(id,name) values ('lib-f2','Frank équipe');
  begin
    insert into public.libraries(id,name,created_by) values ('lib-f3','Au nom de Bob',bob);
    raise exception 'ÉCHEC 15.3 : frank a créé une bibliothèque au nom de bob';
  exception when insufficient_privilege then null; end;
  reset role;
  select count(*) into v_cnt from public.memberships where user_id=frank and library_id='lib-f2' and role='admin';
  if v_cnt <> 1 then raise exception 'ÉCHEC 15.3 : le créateur n''est pas admin de sa bibliothèque'; end if;
  -- 15.4 Règle 'admins' : même autorisé, frank ne crée plus.
  update public.app_settings set library_creation = 'admins' where id;
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'email','frank@test.local','role','authenticated')::text, true);
  set local role authenticated;
  if public.can_create_library() then raise exception 'ÉCHEC 15.4 : la règle « admins » laisse créer'; end if;
  reset role;
  -- 15.5 Demande : frank (sans droit) demande, ne voit que les siennes ; bob ne voit pas la file.
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'email','frank@test.local','role','authenticated')::text, true);
  set local role authenticated;
  v_sec := public.request_library('Pédia SMUR','["BOB@test.local","pas-un-mail","frank@test.local"]'::jsonb,'editor')::text;
  select count(*) into v_cnt from public.my_library_requests();
  if v_cnt <> 1 then raise exception 'ÉCHEC 15.5 : frank ne voit pas sa demande (%)', v_cnt; end if;
  begin
    perform 1 from public.library_requests limit 1;
    raise exception 'ÉCHEC 15.5 : library_requests est lisible en direct';
  exception when insufficient_privilege then null; end;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub',bob,'email','bob@test.local','role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into v_cnt from public.list_library_requests();
  if v_cnt <> 0 then raise exception 'ÉCHEC 15.5 : un non-admin lit la file des demandes'; end if;
  reset role;
  -- 15.6 L'administrateur accepte : bibliothèque créée, frank admin, l'adresse invalide écartée, frank jamais rétrogradé.
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'email','alice@test.local','role','authenticated')::text, true);
  v_j := public.decide_library_request(v_sec::uuid, true);
  if v_j->>'status' <> 'created' then raise exception 'ÉCHEC 15.6 : décision non appliquée (%)', v_j; end if;
  select count(*) into v_cnt from public.memberships where user_id=frank and library_id=v_j->>'library' and role='admin';
  if v_cnt <> 1 then raise exception 'ÉCHEC 15.6 : le demandeur n''est pas admin de la bibliothèque créée'; end if;
  select count(*) into v_cnt from public.library_requests where id = v_sec::uuid;
  if v_cnt <> 0 then raise exception 'ÉCHEC 15.6 : la demande acceptée (et ses e-mails) reste stockée'; end if;
  update public.app_settings set library_creation = 'creators' where id;   -- remise en état
  -- 15.7 Les vues d'ensemble de l'administrateur sont VIDES pour tout autre compte.
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'email','frank@test.local','role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into v_cnt from public.list_accounts();
  if v_cnt <> 0 then raise exception 'ÉCHEC 15.7 : un non-admin liste les comptes'; end if;
  select count(*) into v_cnt from public.list_all_libraries();
  if v_cnt <> 0 then raise exception 'ÉCHEC 15.7 : un non-admin liste toutes les bibliothèques'; end if;
  select count(*) into v_cnt from public.list_user_memberships(alice);
  if v_cnt <> 0 then raise exception 'ÉCHEC 15.7 : un non-admin lit les adhésions d''un autre'; end if;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'email','alice@test.local','role','authenticated')::text, true);
  select count(*) into v_cnt from public.list_all_libraries();
  if v_cnt = 0 then raise exception 'ÉCHEC 15.7 : l''administrateur ne voit aucune bibliothèque'; end if;
  select count(*) into v_cnt from public.list_user_memberships(frank);
  if v_cnt = 0 then raise exception 'ÉCHEC 15.7 : l''administrateur ne voit pas les adhésions de frank'; end if;


  ------------------------------------------------------------------ 16. CONNEXION PAR LE TÉLÉPHONE (v5.111, A643)
  -- DEUX SECRETS : celui du QR (le téléphone lit et approuve) et la CLÉ DU POSTE (jamais affichée :
  -- sonder, réclamer, déposer). Chaque attaque démontrée par la revue de sécurité a son contrôle.
  -- 16.1 Un poste SANS compte ouvre une demande. Le serveur ne reçoit que des EMPREINTES.
  -- Compte DÉDIÉ (Kim) : les sections précédentes suppriment ou rétrogradent des comptes, et ce
  -- bloc ne doit pas dépendre de leur ordre.
  reset role;
  insert into auth.users (id, email) values (kim,'kim@test.local') on conflict (id) do nothing;
  insert into public.user_status(user_id,email,status) values (kim,'kim@test.local','approved')
    on conflict (user_id) do update set status='approved';
  v_sec  := 'secret-du-qr-0123456789abcdef';
  v_key  := 'cle-du-poste-0123456789abcdef';
  v_hash := encode(extensions.digest(v_sec, 'sha256'), 'hex');
  v_code := encode(extensions.digest(v_key, 'sha256'), 'hex');
  perform set_config('request.jwt.claims', json_build_object('role','anon')::text, true);
  set local role anon;
  v_j := public.link_open(v_hash, v_hash, 'Chrome · Windows', 'connect');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.1 : clé du poste = secret du QR accepté'; end if;
  v_j := public.link_open(v_hash, v_code, 'Poste IDE Urgences', 'connect');
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 16.1 : un poste sans compte n''ouvre pas de demande (%)', v_j; end if;
  v_lid := (v_j->>'id')::uuid;
  v_j := public.link_open(v_hash, v_code, 'x', 'unlock');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.1 : un anonyme ouvre une demande de DÉVERROUILLAGE'; end if;
  -- 16.2 Le sondage n'ouvre qu'à la CLÉ DU POSTE (pas au secret du QR), et ne rend jamais de jeton.
  v_j := public.link_poll(v_lid, v_sec);
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.2 : le secret du QR suffit à sonder'; end if;
  v_j := public.link_poll(v_lid, v_key);
  if v_j->>'status' <> 'pending' or v_j ? 'token_hash' or v_j ? 'email' then
    raise exception 'ÉCHEC 16.2 : sondage inattendu (%)', v_j; end if;
  -- 16.3 Un anonyme n'approuve rien : la fonction ne lui est même pas exécutable.
  begin
    perform public.link_approve(v_lid, v_sec, now() + interval '12 hours');
    raise exception 'ÉCHEC 16.3 : un anonyme peut appeler link_approve';
  exception when insufficient_privilege then null; end;
  reset role;
  -- 16.4 Le téléphone de Kim lit la demande (libellé libre ramené à la grammaire fermée), l'approuve dans les bornes.
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated')::text, true);
  set local role authenticated;
  v_j := public.link_peek(v_lid, v_key);
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.4 : la clé du poste ouvre la lecture réservée au téléphone'; end if;
  v_j := public.link_peek(v_lid, v_sec);
  if v_j->>'label' <> 'Navigateur' then raise exception 'ÉCHEC 16.4 : libellé libre non ramené à la grammaire (%)', v_j; end if;
  v_j := public.link_approve(v_lid, v_sec, now() + interval '30 hours');
  if v_j->>'err' <> 'bad_ends' then raise exception 'ÉCHEC 16.4 : heure de fin à 30 h acceptée (%)', v_j; end if;
  v_j := public.link_approve(v_lid, v_sec, now() + interval '15 hours');
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 16.4 : approbation refusée (%)', v_j; end if;
  v_j := public.link_approve(v_lid, v_sec, now() + interval '20 hours');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.4 : une seconde approbation « réussit » sans avoir pris'; end if;
  -- 16.5 Aucun client n'appelle les fonctions internes.
  begin
    perform public.link_claim_srv(v_lid, v_key);
    raise exception 'ÉCHEC 16.5 : un compte connecté peut appeler link_claim_srv (e-mail du compte exposé)';
  exception when insufficient_privilege then null; end;
  begin
    perform public.link_bind_srv(v_lid, v_key, gen_random_uuid());
    raise exception 'ÉCHEC 16.5 : link_bind_srv est appelable par un client';
  exception when insufficient_privilege then null; end;
  begin
    perform public.link_row_key(v_lid, v_key);
    raise exception 'ÉCHEC 16.5 : link_row_key est appelable par un client';
  exception when insufficient_privilege then null; end;
  reset role;
  -- 16.6 La réclamation (clé de service) : le SECRET DU QR ne réclame pas ; la clé, UNE fois.
  v_j := public.link_claim_srv(v_lid, v_sec);
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.6 : le secret du QR suffit à réclamer la session'; end if;
  v_j := public.link_claim_srv(v_lid, v_key);
  if v_j->>'email' <> 'kim@test.local' then raise exception 'ÉCHEC 16.6 : réclamation inattendue (%)', v_j; end if;
  -- 16.7 La liaison (par le serveur) ne prend qu'UNE fois ; ensuite, plus de réclamation.
  -- `auth.sessions.id` n'a PAS de valeur par défaut chez Supabase (GoTrue la pose) : on la fournit.
  v_asid := gen_random_uuid(); v_asid2 := gen_random_uuid();
  insert into auth.sessions(id, user_id) values (v_asid, kim), (v_asid2, kim);
  v_j := public.link_bind_srv(v_lid, v_key, v_asid);
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 16.7 : liaison refusée (%)', v_j; end if;
  v_j := public.link_bind_srv(v_lid, v_key, v_asid2);
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.7 : une seconde session se lie au même poste'; end if;
  v_j := public.link_claim_srv(v_lid, v_key);
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.7 : réclamation après liaison'; end if;
  -- 16.8 La SESSION DU POSTE n'a pas les pouvoirs du téléphone : ni approuver un autre poste (s'enchaîner
  --      sans téléphone), ni prolonger, ni lister, ni déconnecter, ni supprimer le compte.
  insert into public.device_links(kind, secret_hash, key_hash, open_until, label)
    values ('connect', encode(extensions.digest('autre-qr-0123456789abcdef','sha256'),'hex'),
            encode(extensions.digest('autre-cle-0123456789abcdef','sha256'),'hex'), now() + interval '2 minutes', 'Chrome')
    returning id into v_lid2;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated','session_id',v_asid,
    'amr', json_build_array(json_build_object('method','magiclink','timestamp', extract(epoch from now()))))::text, true);
  set local role authenticated;
  v_j := public.link_approve(v_lid2, 'autre-qr-0123456789abcdef', now() + interval '27 hours');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.8 : un poste approuve un autre poste'; end if;
  v_j := public.link_extend(v_lid, now() + interval '16 hours');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.8 : un poste prolonge sa propre connexion'; end if;
  if jsonb_array_length(public.link_list()) <> 0 then raise exception 'ÉCHEC 16.8 : un poste liste les postes'; end if;
  v_j := public.link_revoke(v_lid);
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.8 : un poste déconnecte un poste'; end if;
  begin
    perform public.delete_my_account();
    raise exception 'ÉCHEC 16.8 : un poste supprime le compte';
  exception when others then
    if sqlerrm not like '%shared device%' then raise exception 'ÉCHEC 16.8 : refus inattendu (%)', sqlerrm; end if;
  end;
  reset role;
  -- 16.9 Le dépôt (sans compte, par la CLÉ) : jamais une session vive, ni « "false" » en chaîne ; jamais
  --      par-dessus une session terminée, supprimée, ou d'un autre compte ; une sauvegarde se remplace.
  insert into public.sessions(id, owner, data) values ('s-alice-dep', alice, '{"live":false,"name":"alice"}');
  insert into public.sessions(id, owner, data) values ('s-kim-fini', kim, '{"live":false,"name":"vrai"}');
  insert into public.sessions(id, owner, data, deleted_at) values ('s-kim-suppr', kim, '{"live":false}', now());
  perform set_config('request.jwt.claims', json_build_object('role','anon')::text, true);
  set local role anon;
  v_j := public.link_deposit(v_lid, v_sec, '{"id":"s-poste-1","data":{"live":false}}');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.9 : le secret du QR suffit à déposer'; end if;
  v_j := public.link_deposit(v_lid, v_key, '{"id":"s-poste-1","data":{"live":true}}');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.9 : une session VIVE est déposée'; end if;
  v_j := public.link_deposit(v_lid, v_key, '{"id":"s-poste-1","data":{"live":"false"}}');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.9 : « "false" » en chaîne accepté (vive chez le client)'; end if;
  v_j := public.link_deposit(v_lid, v_key, '{"id":"s-poste-1","data":{"live":false,"checkpoint":1}}');
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 16.9 : dépôt d''une sauvegarde refusé (%)', v_j; end if;
  v_j := public.link_deposit(v_lid, v_key, '{"id":"s-poste-1","data":{"live":false,"name":"terminee"}}');
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 16.9 : la session terminée ne remplace pas sa sauvegarde (%)', v_j; end if;
  v_j := public.link_deposit(v_lid, v_key, '{"id":"s-kim-fini","data":{"live":false,"name":"FALSIFIÉ"}}');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.9 : une session TERMINÉE de l''historique est écrasée'; end if;
  v_j := public.link_deposit(v_lid, v_key, '{"id":"s-kim-suppr","data":{"live":false}}');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.9 : une session SUPPRIMÉE est ressuscitée'; end if;
  v_j := public.link_deposit(v_lid, v_key, '{"id":"s-alice-dep","data":{"live":false,"name":"pirate"}}');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.9 : un dépôt sur la ligne d''un autre compte répond « ok »'; end if;
  reset role;
  select count(*) into v_cnt from public.sessions where id = 's-poste-1' and owner = kim and data->>'name' = 'terminee';
  if v_cnt <> 1 then raise exception 'ÉCHEC 16.9 : la session déposée n''est pas dans l''historique de Kim'; end if;
  select count(*) into v_cnt from public.sessions
   where (id = 's-alice-dep' and data->>'name' = 'alice') or (id = 's-kim-fini' and data->>'name' = 'vrai')
      or (id = 's-kim-suppr' and deleted_at is not null);
  if v_cnt <> 3 then raise exception 'ÉCHEC 16.9 : un dépôt a modifié une ligne protégée'; end if;
  -- 16.10 « Appareils connectés » (le téléphone, session ordinaire) : chacun ne voit, ne prolonge et ne
  --       déconnecte que SES postes.
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  set local role authenticated;
  if jsonb_array_length(public.link_list()) <> 0 then raise exception 'ÉCHEC 16.10 : Alice voit le poste de Kim'; end if;
  v_j := public.link_revoke(v_lid);
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.10 : Alice déconnecte le poste de Kim'; end if;
  v_j := public.link_extend(v_lid, now() + interval '16 hours');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.10 : Alice prolonge le poste de Kim'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated')::text, true);
  if jsonb_array_length(public.link_list()) <> 1 then raise exception 'ÉCHEC 16.10 : Kim ne voit pas son poste'; end if;
  v_j := public.link_extend(v_lid, now() + interval '16 hours');
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 16.10 : prolongation refusée (%)', v_j; end if;
  v_j := public.link_extend(v_lid, now() + interval '29 hours');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.10 : prolongation au-delà de 28 h acceptée'; end if;
  -- 16.11 Déverrouiller : seul le compte du poste approuve.
  v_j := public.link_open(encode(extensions.digest(v_sec || '-u', 'sha256'), 'hex'), encode(extensions.digest(v_key || '-u', 'sha256'), 'hex'), 'Chrome · Windows', 'unlock');
  v_lid2 := (v_j->>'id')::uuid;
  perform set_config('request.jwt.claims', json_build_object('sub',alice,'role','authenticated')::text, true);
  v_j := public.link_approve(v_lid2, v_sec || '-u', null);
  if v_j->>'err' <> 'other_account' then raise exception 'ÉCHEC 16.11 : un autre compte déverrouille (%)', v_j; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated')::text, true);
  v_j := public.link_approve(v_lid2, v_sec || '-u', null);
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 16.11 : déverrouillage refusé (%)', v_j; end if;
  -- 16.12 Kim déconnecte le poste : SA session (celle liée par le serveur) disparaît, le dépôt se ferme.
  v_j := public.link_revoke(v_lid);
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 16.12 : déconnexion refusée (%)', v_j; end if;
  reset role;
  select count(*) into v_cnt from auth.sessions where id = v_asid;
  if v_cnt <> 0 then raise exception 'ÉCHEC 16.12 : la session de compte du poste survit à la déconnexion'; end if;
  perform set_config('request.jwt.claims', json_build_object('role','anon')::text, true);
  set local role anon;
  if public.link_poll(v_lid, v_key)->>'status' <> 'revoked' then raise exception 'ÉCHEC 16.12 : le poste n''apprend pas sa déconnexion'; end if;
  v_j := public.link_deposit(v_lid, v_key, '{"id":"s-poste-3","data":{"live":false}}');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.12 : un poste déconnecté dépose encore'; end if;
  reset role;
  -- 16.13 L'heure de fin passée, la purge (en tête de tout appel) supprime la session du poste ; le dépôt reste ouvert.
  v_asid := gen_random_uuid();
  insert into auth.sessions(id, user_id) values (v_asid, kim);
  insert into public.device_links(kind, secret_hash, key_hash, open_until, user_id, status, ends_at, approved_at, claimed_at, auth_session)
    values ('connect', encode(extensions.digest('qr-fini-0123456789abcdef', 'sha256'), 'hex'),
            encode(extensions.digest('cle-fini-0123456789abcdef', 'sha256'), 'hex'), now() - interval '1 day',
            kim, 'claimed', now() - interval '1 minute', now() - interval '1 day', now() - interval '1 day', v_asid)
    returning id into v_lid2;
  perform set_config('request.jwt.claims', json_build_object('role','anon')::text, true);
  set local role anon;
  if public.link_poll(v_lid2, 'cle-fini-0123456789abcdef')->>'status' <> 'ended' then
    raise exception 'ÉCHEC 16.13 : un poste à l''heure de fin passée ne l''apprend pas'; end if;
  v_j := public.link_deposit(v_lid2, 'cle-fini-0123456789abcdef', '{"id":"s-poste-4","data":{"live":false}}');
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 16.13 : le dépôt se ferme à l''heure de fin (%)', v_j; end if;
  reset role;
  select count(*) into v_cnt from auth.sessions where id = v_asid;
  if v_cnt <> 0 then raise exception 'ÉCHEC 16.13 : la session du poste survit à l''heure de fin'; end if;
  -- 16.15 (A649) Le poste se termine lui-même (« Se déconnecter et effacer ») : il disparaît des « Appareils
  --       connectés ». Seule SA session le peut ; une session qui n'est pas un poste ne termine rien.
  v_asid2 := gen_random_uuid();
  insert into auth.sessions(id, user_id) values (v_asid2, kim);
  insert into public.device_links(kind, secret_hash, key_hash, open_until, user_id, status, ends_at, approved_at, claimed_at, auth_session, label)
    values ('connect', encode(extensions.digest('qr-fin2-0123456789abcdef', 'sha256'), 'hex'),
            encode(extensions.digest('cle-fin2-0123456789abcdef', 'sha256'), 'hex'), now(),
            kim, 'claimed', now() + interval '5 hours', now(), now(), v_asid2, 'Chrome')
    returning id into v_lid2;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated')::text, true);
  set local role authenticated;
  v_cnt := jsonb_array_length(public.link_list());
  if v_cnt < 1 then raise exception 'ÉCHEC 16.15 : le poste n''apparaît pas dans « Appareils connectés »'; end if;
  if (public.link_end()->>'ok')::boolean then raise exception 'ÉCHEC 16.15 : une session qui n''est pas un poste en termine un'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated','session_id',v_asid2)::text, true);
  v_j := public.link_end();
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 16.15 : le poste ne peut pas se terminer (%)', v_j; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated')::text, true);
  if jsonb_array_length(public.link_list()) <> v_cnt - 1 then
    raise exception 'ÉCHEC 16.15 : le poste terminé reste dans « Appareils connectés »'; end if;
  reset role;
  -- 16.16 (A651) Connexion temporaire PAR E-MAIL : la session courante se déclare poste, une seule fois ;
  --       ensuite elle a les limites d'un poste (n'approuve rien) et apparaît dans « Appareils connectés ».
  v_asid3 := gen_random_uuid();
  insert into auth.sessions(id, user_id) values (v_asid3, kim);
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated','session_id',v_asid3)::text, true);
  set local role authenticated;
  v_j := public.link_self(encode(extensions.digest('cle-mail-0123456789abcdef', 'sha256'), 'hex'), 'Firefox · Windows', now() + interval '40 hours');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.16 : une heure de fin au-delà de 28 h est acceptée'; end if;
  v_j := public.link_self('pas-une-empreinte', 'Firefox · Windows', now() + interval '5 hours');
  if (v_j->>'ok')::boolean then raise exception 'ÉCHEC 16.16 : une clé qui n''est pas une empreinte est acceptée'; end if;
  v_j := public.link_self(encode(extensions.digest('cle-mail-0123456789abcdef', 'sha256'), 'hex'), 'Poste IDE Urgences', now() + interval '5 hours');
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 16.16 : la session ne peut pas se déclarer temporaire (%)', v_j; end if;
  v_lid2 := (v_j->>'id')::uuid;
  if jsonb_array_length(public.link_list()) <> 0 then raise exception 'ÉCHEC 16.16 : la session déclarée n''a pas les limites d''un poste'; end if;
  if (public.link_self(encode(extensions.digest('cle-mail-0123456789abcdef', 'sha256'), 'hex'), 'Chrome', now() + interval '5 hours')->>'ok')::boolean then
    raise exception 'ÉCHEC 16.16 : une session se déclare poste deux fois'; end if;
  if (public.link_approve(v_lid, 'peu-importe', now() + interval '5 hours')->>'ok')::boolean then
    raise exception 'ÉCHEC 16.16 : une session temporaire par e-mail approuve un poste'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated')::text, true);
  if not exists (select 1 from jsonb_array_elements(public.link_list()) e where e->>'id' = v_lid2::text and e->>'label' = 'Navigateur') then
    raise exception 'ÉCHEC 16.16 : la connexion temporaire par e-mail n''apparaît pas (libellé fermé)'; end if;
  reset role;
  -- 16.17 (A654) Les RÈGLES de la connexion temporaire sont opposables : un INTERDIT s'applique à la session de poste
  --       (v_asid3, déclarée en 16.16) et à elle seule ; une suppression suit la règle « del » ; la durée maximale borne
  --       les connexions ; le réglage ne se modifie jamais depuis un poste.
  update public.app_settings set temp_rules = '{"edit":"non","del":"non","dur":12}'::jsonb where id = true;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated','session_id',v_asid3)::text, true);
  set local role authenticated;
  begin
    insert into public.cognitive_aids(id,owner,library_id,data) values ('f-poste-1',kim,null,'{"t":1}');
    raise exception 'ÉCHEC 16.17 : un poste crée une aide alors que la règle l''interdit';
  exception when insufficient_privilege then null; end;
  begin
    perform public.set_temp_rules('{"edit":"libre"}'::jsonb);
    raise exception 'ÉCHEC 16.17 : le réglage se modifie depuis un poste';
  exception when others then if sqlerrm like 'ÉCHEC%' then raise; end if; end;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated')::text, true);
  insert into public.cognitive_aids(id,owner,library_id,data) values ('f-perm-1',kim,null,'{"t":1}');   -- hors poste : permis
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated','session_id',v_asid3)::text, true);
  begin
    update public.cognitive_aids set deleted_at = now() where id = 'f-perm-1';
    raise exception 'ÉCHEC 16.17 : un poste supprime alors que la règle l''interdit';
  exception when insufficient_privilege then null; end;
  reset role;
  update public.app_settings set temp_rules = '{"edit":"libre","del":"tel","dur":12}'::jsonb where id = true;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated','session_id',v_asid3)::text, true);
  set local role authenticated;
  insert into public.cognitive_aids(id,owner,library_id,data) values ('f-poste-2',kim,null,'{"t":1}');   -- permis : la règle le permet
  update public.cognitive_aids set deleted_at = now() where id = 'f-poste-2';
  reset role;
  v_asid := gen_random_uuid();
  insert into auth.sessions(id, user_id) values (v_asid, kim);
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated','session_id',v_asid)::text, true);
  set local role authenticated;
  if (public.link_self(encode(extensions.digest('cle-dur-0123456789abcdef', 'sha256'), 'hex'), 'Chrome', now() + interval '20 hours')->>'ok')::boolean then
    raise exception 'ÉCHEC 16.17 : la durée maximale réglée (12 h) ne borne pas la connexion'; end if;
  if (public.get_temp_rules()->>'dur')::int <> 12 then raise exception 'ÉCHEC 16.17 : les règles ne se lisent pas'; end if;
  reset role;
  update public.app_settings set temp_rules = '{"edit":"v15","del":"tel","repl":"non","exp":"oui","dur":28}'::jsonb where id = true;
  -- 16.18 (A655) Un poste DÉCONNECTÉ à distance ne lit ni n'écrit plus, dès la requête suivante — son jeton
  --       (v_asid3) reste valable jusqu'à 900 s : c'est la base, pas le jeton, qui ferme. Une session de
  --       confiance du même compte n'est pas touchée.
  update public.app_settings set temp_rules = '{"edit":"libre"}'::jsonb where id = true;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated','session_id',v_asid3)::text, true);
  set local role authenticated;
  insert into public.cognitive_aids(id,owner,library_id,data) values ('f-poste-3',kim,null,'{"t":1}');   -- avant : permis
  if not exists (select 1 from public.cognitive_aids where id = 'f-poste-3') then
    raise exception 'ÉCHEC 16.18 : un poste encore connecté ne lit pas ses aides'; end if;
  reset role;
  select id into v_lid3 from public.device_links where auth_session = v_asid3;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated')::text, true);
  set local role authenticated;
  if not coalesce((public.link_revoke(v_lid3)->>'ok')::boolean, false) then
    raise exception 'ÉCHEC 16.18 : la déconnexion à distance échoue'; end if;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated','session_id',v_asid3)::text, true);
  set local role authenticated;
  begin
    insert into public.cognitive_aids(id,owner,library_id,data) values ('f-poste-4',kim,null,'{"t":1}');
    raise exception 'ÉCHEC 16.18 : un poste déconnecté crée encore une aide';
  exception when insufficient_privilege then null; end;
  update public.cognitive_aids set data = '{"t":2}' where id = 'f-poste-3';
  if exists (select 1 from public.cognitive_aids where id = 'f-poste-3') then
    raise exception 'ÉCHEC 16.18 : un poste déconnecté lit encore les aides du compte'; end if;
  if (public.link_poll(v_lid3, 'x')->>'ok') is null then
    raise exception 'ÉCHEC 16.18 : link_poll n''est plus appelable'; end if;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub',kim,'role','authenticated')::text, true);
  set local role authenticated;
  if (select data->>'t' from public.cognitive_aids where id = 'f-poste-3') <> '1' then
    raise exception 'ÉCHEC 16.18 : un poste déconnecté a modifié une aide'; end if;
  reset role;
  update public.app_settings set temp_rules = '{"edit":"v15","del":"tel","repl":"non","exp":"oui","dur":28}'::jsonb where id = true;
  -- 16.14 (A648) Aucun compte ne porte de mot de passe : ni le définir, ni s'inscrire avec. Un mot de
  --       passe VIDE (compte créé par code e-mail) passe.
  update auth.users set email = 'kim2@test.local' where id = kim;   -- toute autre mise à jour passe
  begin
    update auth.users set encrypted_password = 'empreinte-de-mot-de-passe-non-vide' where id = kim;
    raise exception 'ÉCHEC 16.14 : un compte peut se définir un mot de passe';
  exception when others then
    if sqlerrm not like '%passwords are disabled%' then raise exception 'ÉCHEC 16.14 : refus inattendu (%)', sqlerrm; end if;
  end;
  begin
    insert into auth.users (id, email, encrypted_password)
      values ('cdcdcdcd-0000-0000-0000-cdcdcdcdcdcd', 'mdp@test.local', 'empreinte-de-mot-de-passe-non-vide');
    raise exception 'ÉCHEC 16.14 : une inscription avec mot de passe passe';
  exception when others then
    if sqlerrm not like '%passwords are disabled%' then raise exception 'ÉCHEC 16.14 : refus inattendu (%)', sqlerrm; end if;
  end;


  ------------------------------------------------------------------ 17. Lot v5.115 (A663) : droits resserrés
  -- Comptes dédiés (lea : administratrice de sa bibliothèque ; max, noe : membres ; oda : administratrice
  -- de l'instance), pour ne dépendre d'aucun état laissé par les sections précédentes.
  reset role;
  perform set_config('request.jwt.claims', '', true);
  insert into auth.users (id, email, email_confirmed_at) values
    (lea,'lea@test.local',now()),(max,'max@test.local',now()),(noe,'noe@test.local',now()),(oda,'oda@test.local',now());
  insert into public.user_status(user_id,email,status) values
    (lea,'lea@test.local','approved'),(max,'max@test.local','approved'),(noe,'noe@test.local','approved'),(oda,'oda@test.local','approved')
    on conflict (user_id) do update set status='approved';
  insert into public.app_admins(user_id) values (oda) on conflict do nothing;
  insert into public.libraries(id,name,created_by) values ('lib-a663','A663',lea);   -- lea en devient admin (trigger)
  insert into public.memberships(user_id,library_id,role) values (max,'lib-a663','editor'),(noe,'lib-a663','viewer');

  -- 17.1 delete_my_account n'a plus qu'UNE définition, et elle emporte TOUT l'espace personnel — le suivi
  --      perso compris (A613 : la seconde définition, celle qui gagnait, l'avait perdu). Une note d'ÉQUIPE
  --      reste, sans auteur.
  perform set_config('request.jwt.claims', json_build_object('sub',max,'role','authenticated')::text, true);
  set local role authenticated;
  insert into public.cognitive_aids(id,owner,library_id,data) values ('f-max',max,null,'{"t":1}');
  insert into public.protocols(id,owner,library_id,data) values ('p-max',max,null,'{"t":1}');
  insert into public.sessions(id,owner,data) values ('s-max',max,'{"t":1}');
  insert into public.aid_notes(user_id,fiche_id,note) values (max,'f-max','note');
  insert into public.aid_followups(id,library_id,entity_id,kind,body) values ('fu-max-perso',null,'f-max','note','pour moi');
  insert into public.aid_followups(id,library_id,entity_id,kind,body) values ('fu-max-team','lib-a663','f-max','note','pour l''équipe');
  perform set_config('request.jwt.claims', json_build_object('sub',max,'role','authenticated',
    'amr',json_build_array(json_build_object('method','otp','timestamp',extract(epoch from now())::bigint)))::text, true);
  perform public.delete_my_account();
  reset role;
  select (select count(*) from public.cognitive_aids where owner=max) + (select count(*) from public.protocols where owner=max)
       + (select count(*) from public.sessions where owner=max) + (select count(*) from public.aid_notes where user_id=max)
       + (select count(*) from public.aid_followups where id='fu-max-perso') + (select count(*) from auth.users where id=max) into v_cnt;
  if v_cnt <> 0 then raise exception 'ÉCHEC 17.1 : la suppression du compte laisse % ligne(s) personnelle(s) (suivi perso, A613 ?)', v_cnt; end if;
  if not exists (select 1 from public.aid_followups where id='fu-max-team' and owner is null) then
    raise exception 'ÉCHEC 17.1 : la note d''équipe n''a pas survécu, sans auteur, au départ de son auteur'; end if;
  select count(*) into v_cnt from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname in ('delete_my_account','get_instance_stats','purge_user_data');
  if v_cnt <> 3 then raise exception 'ÉCHEC 17.1 : % définition(s) au catalogue pour trois fonctions', v_cnt; end if;
  if has_function_privilege('authenticated','public.purge_user_data(uuid)','execute') then
    raise exception 'ÉCHEC 17.1 : purge_user_data (identité en paramètre) est appelable par un client'; end if;

  -- 17.2 Tables du PARTAGE : l'hôte ne les écrit plus que par ses trois gestes (couper, rôle, terminer).
  perform set_config('request.jwt.claims', json_build_object('sub',lea,'role','authenticated')::text, true);
  set local role authenticated;
  v_j := public.share_open('sh-a663','sess-a663','fic-a663','{"title":"A663","status":"validated"}'::jsonb,'scribe',60);
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 17.2 : ouverture nominale refusée (%)', v_j; end if;
  v_j2 := public.share_join(v_j->>'code','Infirmier');
  if (v_j2->>'ok')::boolean is not true then raise exception 'ÉCHEC 17.2 : jointure refusée (%)', v_j2; end if;
  begin
    insert into public.shared_sessions(id,owner,session_id,fiche_id,fiche_snap,expires_at)
      values ('sh-direct',lea,'s','f','{"localInfo":"Tél régulation"}'::jsonb, now() + interval '10 years');
    raise exception 'ÉCHEC 17.2 : INSERT direct d''un partage (sans liste blanche, sans durée bornée)';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.session_participants(share_id,label,role) values ('sh-a663','Faux','lead');
    raise exception 'ÉCHEC 17.2 : INSERT direct d''un participant';
  exception when insufficient_privilege then null; end;
  begin
    update public.shared_sessions set fiche_snap = '{"localInfo":"x"}'::jsonb where id='sh-a663';
    raise exception 'ÉCHEC 17.2 : UPDATE direct de fiche_snap';
  exception when insufficient_privilege then null; end;
  begin
    update public.shared_sessions set code_hash = repeat('0',64), join_open_until = now() + interval '1 day' where id='sh-a663';
    raise exception 'ÉCHEC 17.2 : UPDATE direct du code d''appariement';
  exception when insufficient_privilege then null; end;
  begin
    update public.session_participants set label = '<b>texte libre</b>' where share_id='sh-a663';
    raise exception 'ÉCHEC 17.2 : UPDATE direct du libellé d''un participant (règle 15)';
  exception when insufficient_privilege then null; end;
  begin
    update public.session_participants set secret_hash = repeat('0',64) where share_id='sh-a663' and not is_owner;
    raise exception 'ÉCHEC 17.2 : UPDATE direct du secret d''un participant';
  exception when insufficient_privilege then null; end;
  begin
    delete from public.shared_sessions where id='sh-a663';
    raise exception 'ÉCHEC 17.2 : DELETE direct d''un partage';
  exception when insufficient_privilege then null; end;
  begin   -- les colonnes permises ne servent qu'à CLORE : ni repousser l'expiration, ni rester « active »
    update public.shared_sessions set expires_at = now() + interval '10 years' where id='sh-a663';
    raise exception 'ÉCHEC 17.2 : un PATCH direct repousse l''expiration d''un partage actif';
  exception when insufficient_privilege then null; end;
  begin
    update public.shared_sessions set status = 'ended', expires_at = now() + interval '10 years' where id='sh-a663';
    raise exception 'ÉCHEC 17.2 : un partage terminé garde une expiration à dix ans (jamais purgé)';
  exception when insufficient_privilege then null; end;
  -- les trois PATCH du client, tels qu'il les envoie
  update public.session_participants set role = 'lead' where share_id='sh-a663' and participant = (v_j2->>'me')::uuid;
  get diagnostics v_cnt = row_count;
  if v_cnt <> 1 then raise exception 'ÉCHEC 17.2 : l''hôte ne peut plus poser un rôle'; end if;
  update public.session_participants set revoked_at = now() where share_id='sh-a663' and participant = (v_j2->>'me')::uuid;
  get diagnostics v_cnt = row_count;
  if v_cnt <> 1 then raise exception 'ÉCHEC 17.2 : l''hôte ne peut plus couper un invité'; end if;
  update public.shared_sessions set status = 'ended', expires_at = now() where id='sh-a663';
  get diagnostics v_cnt = row_count;
  if v_cnt <> 1 then raise exception 'ÉCHEC 17.2 : l''hôte ne peut plus terminer son partage'; end if;
  begin   -- terminé ne se rouvre pas
    update public.shared_sessions set status = 'active', expires_at = now() + interval '1 hour' where id='sh-a663';
    raise exception 'ÉCHEC 17.2 : un partage terminé se rouvre par un PATCH direct';
  exception when insufficient_privilege then null; end;
  -- le partage d'AUTRUI reste hors d'atteinte (0 ligne, sans erreur)
  perform set_config('request.jwt.claims', json_build_object('sub',noe,'role','authenticated')::text, true);
  update public.shared_sessions set status = 'ended', expires_at = now() where id='sh-a663';
  get diagnostics v_cnt = row_count;
  if v_cnt <> 0 then raise exception 'ÉCHEC 17.2 : un tiers termine le partage d''autrui'; end if;
  -- share_open borne aussi l'identifiant de l'aide
  perform set_config('request.jwt.claims', json_build_object('sub',lea,'role','authenticated')::text, true);
  if (public.share_open('sh-a663b','sess','<script>','{"title":"x"}'::jsonb,'scribe',60)->>'err') is distinct from 'bad_request' then
    raise exception 'ÉCHEC 17.2 : share_open accepte un identifiant d''aide hors format'; end if;
  if (public.share_open('sh-a663c','sess',repeat('a',65),'{"title":"x"}'::jsonb,'scribe',60)->>'err') is distinct from 'bad_request' then
    raise exception 'ÉCHEC 17.2 : share_open accepte un identifiant d''aide de 65 caractères'; end if;

  -- 17.3 MEMBRES : ni INSERT ni réécriture de `user_id` en direct (le contrôle d'approbation est dans
  --      invite_member) ; le PATCH {role} et le DELETE du client passent toujours.
  reset role;
  insert into auth.users (id, email, email_confirmed_at) values (pia,'pia@test.local',now());
  update public.app_settings set require_approval = true where id = true;
  insert into public.user_status(user_id,email,status) values (pia,'pia@test.local','pending')
    on conflict (user_id) do update set status='pending';
  perform set_config('request.jwt.claims', json_build_object('sub',lea,'role','authenticated')::text, true);
  set local role authenticated;
  begin
    insert into public.memberships(user_id,library_id,role) values (pia,'lib-a663','editor');
    raise exception 'ÉCHEC 17.3 : une administratrice inscrit en direct un compte en attente';
  exception when insufficient_privilege then null; end;
  begin
    update public.memberships set user_id = pia where library_id='lib-a663' and user_id = noe;
    raise exception 'ÉCHEC 17.3 : une adhésion est réattribuée en direct à un compte en attente';
  exception when insufficient_privilege then null; end;
  if public.invite_member('lib-a663','pia@test.local','editor') <> 'not_found' then   -- A685 : réponse unique
    raise exception 'ÉCHEC 17.3 : invite_member ne refuse plus un compte en attente'; end if;
  update public.memberships set role = 'editor' where library_id='lib-a663' and user_id = noe;
  get diagnostics v_cnt = row_count;
  if v_cnt <> 1 then raise exception 'ÉCHEC 17.3 : le PATCH {role} du client ne passe plus'; end if;
  delete from public.memberships where library_id='lib-a663' and user_id = noe;
  get diagnostics v_cnt = row_count;
  if v_cnt <> 1 then raise exception 'ÉCHEC 17.3 : le retrait d''un membre par le client ne passe plus'; end if;
  if public.invite_member('lib-a663','noe@test.local','viewer') <> 'ok' then
    raise exception 'ÉCHEC 17.3 : invite_member ne ré-invite plus'; end if;
  reset role;
  update public.app_settings set require_approval = false where id = true;

  -- 17.4 user_status ne s'écrit plus en direct, même par une administratrice de l'instance : la RPC seule.
  perform set_config('request.jwt.claims', json_build_object('sub',oda,'role','authenticated')::text, true);
  set local role authenticated;
  begin
    update public.user_status set status = 'rejected' where user_id = noe;
    raise exception 'ÉCHEC 17.4 : PATCH direct de user_status par une administratrice (contourne set_user_status)';
  exception when insufficient_privilege then null; end;
  perform public.set_user_status(pia, 'approved');
  reset role;
  if (select status from public.user_status where user_id = pia) <> 'approved'
     or (select decided_by from public.user_status where user_id = pia) <> oda then
    raise exception 'ÉCHEC 17.4 : set_user_status n''écrit plus le statut'; end if;

  -- 17.5 POSTE PARTAGÉ : ni inviter, ni demander une bibliothèque, ni quitter (A647) ; ses documents suivent
  --      la règle `edit` (A654) ; déconnecté, il n'ouvre ni ne ré-arme un partage — mais TERMINE le sien.
  v_asid := gen_random_uuid();
  insert into auth.sessions(id, user_id) values (v_asid, lea);
  perform set_config('request.jwt.claims', json_build_object('sub',lea,'role','authenticated','session_id',v_asid)::text, true);
  set local role authenticated;
  v_j := public.link_self(encode(extensions.digest('cle-a663-0123456789abcdef', 'sha256'), 'hex'), 'Chrome', now() + interval '5 hours');
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 17.5 : la session ne se déclare pas poste (%)', v_j; end if;
  v_lid := (v_j->>'id')::uuid;
  begin
    perform public.invite_member('lib-a663','pia@test.local','viewer');
    raise exception 'ÉCHEC 17.5 : un poste partagé invite un membre';
  exception when others then if sqlerrm <> 'not allowed' then raise; end if; end;
  begin
    perform public.request_library('Depuis un poste');
    raise exception 'ÉCHEC 17.5 : un poste partagé demande une bibliothèque';
  exception when others then if sqlerrm <> 'not allowed' then raise; end if; end;
  begin
    perform public.leave_library('lib-a663');
    raise exception 'ÉCHEC 17.5 : un poste partagé quitte une bibliothèque';
  exception when others then if sqlerrm <> 'not allowed' then raise; end if; end;
  insert into storage.objects(bucket_id,name,metadata) values ('attachments','l/lib-a663/att-p1.pdf','{"v":1}');   -- règle par défaut : permis
  v_j := public.share_open('sh-poste','sess-poste','fic-poste','{"title":"Poste","status":"validated"}'::jsonb,'scribe',60);
  if (v_j->>'ok')::boolean is not true then raise exception 'ÉCHEC 17.5 : un poste CONNECTÉ ne partage plus sa session (%)', v_j; end if;
  reset role;
  update public.app_settings set temp_rules = '{"edit":"non","del":"tel"}'::jsonb where id = true;
  perform set_config('request.jwt.claims', json_build_object('sub',lea,'role','authenticated','session_id',v_asid)::text, true);
  set local role authenticated;
  begin
    insert into storage.objects(bucket_id,name) values ('attachments','l/lib-a663/att-p2.pdf');
    raise exception 'ÉCHEC 17.5 : un poste dépose un document alors que la règle interdit de modifier';
  exception when insufficient_privilege then null; end;
  begin
    update storage.objects set metadata='{"v":2}' where bucket_id='attachments' and name='l/lib-a663/att-p1.pdf';
    raise exception 'ÉCHEC 17.5 : un poste remplace un document alors que la règle interdit de modifier';
  exception when insufficient_privilege then null; end;
  perform set_config('request.jwt.claims', json_build_object('sub',lea,'role','authenticated')::text, true);
  update storage.objects set metadata='{"v":3}' where bucket_id='attachments' and name='l/lib-a663/att-p1.pdf';   -- hors poste : permis
  get diagnostics v_cnt = row_count;
  if v_cnt <> 1 then raise exception 'ÉCHEC 17.5 : la règle des postes touche une session de confiance'; end if;
  if not coalesce((public.link_revoke(v_lid)->>'ok')::boolean, false) then raise exception 'ÉCHEC 17.5 : déconnexion à distance'; end if;
  reset role;
  update public.app_settings set temp_rules = '{"edit":"v15","del":"tel","repl":"non","exp":"oui","dur":28}'::jsonb where id = true;
  perform set_config('request.jwt.claims', json_build_object('sub',lea,'role','authenticated','session_id',v_asid)::text, true);
  set local role authenticated;
  if (public.share_open('sh-mort','sess-mort','fic-mort','{"title":"x"}'::jsonb,'scribe',60)->>'ok')::boolean then
    raise exception 'ÉCHEC 17.5 : un poste déconnecté ouvre un partage'; end if;
  if (public.share_admit('sh-poste',60)->>'ok')::boolean then
    raise exception 'ÉCHEC 17.5 : un poste déconnecté ré-arme un code d''appariement'; end if;
  update public.shared_sessions set status = 'ended', expires_at = now() where id='sh-poste';
  get diagnostics v_cnt = row_count;
  if v_cnt <> 1 then raise exception 'ÉCHEC 17.5 : un poste déconnecté ne peut plus TERMINER le partage de sa session en cours'; end if;

  -- 17.6 AU MOINS UN ADMINISTRATEUR : le dernier ne se rétrograde pas, ne se retire pas, ne quitte pas ;
  --      un membre ordinaire quitte ; avec une seconde administratrice, la première peut partir.
  perform set_config('request.jwt.claims', json_build_object('sub',lea,'role','authenticated')::text, true);
  begin
    update public.memberships set role = 'viewer' where library_id='lib-a663' and user_id = lea;
    raise exception 'ÉCHEC 17.6 : la dernière administratrice se rétrograde';
  exception when others then if sqlerrm <> 'last_admin' then raise; end if; end;
  begin
    delete from public.memberships where library_id='lib-a663' and user_id = lea;
    raise exception 'ÉCHEC 17.6 : la dernière administratrice se retire';
  exception when others then if sqlerrm <> 'last_admin' then raise; end if; end;
  begin
    delete from public.memberships where library_id='lib-a663';
    raise exception 'ÉCHEC 17.6 : toutes les adhésions partent en une requête, administratrice comprise';
  exception when others then if sqlerrm <> 'last_admin' then raise; end if; end;
  if public.leave_library('lib-a663') <> 'last_admin' then raise exception 'ÉCHEC 17.6 : la dernière administratrice quitte la bibliothèque'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',oda,'role','authenticated')::text, true);
  begin   -- pas même par l'administratrice de l'instance, ni par invite_member qui réécrit un rôle
    perform public.invite_member('lib-a663','lea@test.local','viewer');
    raise exception 'ÉCHEC 17.6 : invite_member rétrograde la dernière administratrice';
  exception when others then if sqlerrm <> 'last_admin' then raise; end if; end;
  perform set_config('request.jwt.claims', json_build_object('sub',noe,'role','authenticated')::text, true);
  if public.leave_library('lib-inexistante') <> 'not_member' then raise exception 'ÉCHEC 17.6 : quitter une bibliothèque dont on n''est pas membre'; end if;
  if public.leave_library('lib-a663') <> 'ok' then raise exception 'ÉCHEC 17.6 : un lecteur ne peut pas quitter sa bibliothèque'; end if;
  if public.is_member('lib-a663') then raise exception 'ÉCHEC 17.6 : parti, le lecteur est encore membre'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',lea,'role','authenticated')::text, true);
  if public.invite_member('lib-a663','noe@test.local','admin') <> 'ok' then raise exception 'ÉCHEC 17.6 : nommer une seconde administratrice'; end if;
  -- A685 : une administratrice seulement INVITÉE ne compte pas — la première ne peut pas encore partir.
  if public.leave_library('lib-a663') <> 'last_admin' then raise exception 'ÉCHEC 17.6 : une invitation en attente compte comme une seconde administratrice'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',noe,'role','authenticated')::text, true);
  if public.answer_invitation('lib-a663', true) <> 'ok' then raise exception 'ÉCHEC 17.6 : la seconde administratrice ne peut pas accepter'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',lea,'role','authenticated')::text, true);
  if public.leave_library('lib-a663') <> 'ok' then raise exception 'ÉCHEC 17.6 : avec une seconde administratrice, la première ne peut pas partir'; end if;
  --      CE QUE LA RÈGLE NE BLOQUE PAS : le compte qui s'efface (droit à l'effacement), le compte refusé,
  --      la bibliothèque supprimée. noe est maintenant la SEULE administratrice.
  perform set_config('request.jwt.claims', json_build_object('sub',oda,'role','authenticated')::text, true);
  perform public.set_user_status(noe, 'rejected');
  reset role;
  if exists (select 1 from public.memberships where user_id = noe) then
    raise exception 'ÉCHEC 17.6 : un compte refusé garde son adhésion (la règle du dernier administrateur bloque la révocation)'; end if;
  insert into public.memberships(user_id,library_id,role) values (pia,'lib-a663','admin');
  perform set_config('request.jwt.claims', json_build_object('sub',pia,'role','authenticated',
    'amr',json_build_array(json_build_object('method','otp','timestamp',extract(epoch from now())::bigint)))::text, true);
  set local role authenticated;
  perform public.delete_my_account();   -- seule administratrice : le départ n'est pas bloqué
  reset role;
  if exists (select 1 from auth.users where id = pia) or exists (select 1 from public.memberships where user_id = pia) then
    raise exception 'ÉCHEC 17.6 : la seule administratrice d''une bibliothèque ne peut plus supprimer son compte'; end if;
  insert into public.memberships(user_id,library_id,role) values (lea,'lib-a663','admin');
  perform set_config('request.jwt.claims', json_build_object('sub',oda,'role','authenticated')::text, true);
  set local role authenticated;
  delete from public.libraries where id = 'lib-a663';
  reset role;
  if exists (select 1 from public.libraries where id = 'lib-a663') or exists (select 1 from public.memberships where library_id = 'lib-a663') then
    raise exception 'ÉCHEC 17.6 : la bibliothèque ne se supprime plus (la règle bloque la cascade)'; end if;

  -- 17.7 delete_rejected_user emporte les données du compte (il ne supprimait que la ligne auth.users), et
  --      supprimer le compte d'une administratrice qui a DÉCIDÉ d'un statut ne casse plus (`decided_by`).
  insert into public.cognitive_aids(id,owner,library_id,data) values ('f-noe',noe,null,'{"t":1}');
  insert into public.sessions(id,owner,data) values ('s-noe',noe,'{"t":1}');
  insert into public.aid_followups(id,owner,library_id,entity_id,kind,body) values ('fu-noe',noe,null,'f-noe','note','x');
  perform set_config('request.jwt.claims', json_build_object('sub',oda,'role','authenticated')::text, true);
  set local role authenticated;
  perform public.delete_rejected_user(noe);
  reset role;
  select (select count(*) from public.cognitive_aids where owner=noe) + (select count(*) from public.sessions where owner=noe)
       + (select count(*) from public.aid_followups where id='fu-noe') + (select count(*) from auth.users where id=noe) into v_cnt;
  if v_cnt <> 0 then raise exception 'ÉCHEC 17.7 : un compte refusé supprimé laisse % ligne(s)', v_cnt; end if;
  insert into auth.users (id, email, email_confirmed_at) values (pia,'pia@test.local',now());
  insert into public.user_status(user_id,email,status,decided_by) values (pia,'pia@test.local','approved',oda)
    on conflict (user_id) do update set decided_by = oda;
  delete from public.app_admins where user_id = oda;
  delete from auth.users where id = oda;   -- avant A663 : violation de clé étrangère sur user_status.decided_by
  if (select decided_by from public.user_status where user_id = pia) is not null then
    raise exception 'ÉCHEC 17.7 : decided_by ne passe pas à NULL'; end if;

  -- 17.8 Notes personnelles bornées (taille et clé), comme le suivi.
  perform set_config('request.jwt.claims', json_build_object('sub',lea,'role','authenticated')::text, true);
  set local role authenticated;
  insert into public.aid_notes(user_id,fiche_id,note) values (lea,'f-ok_1',repeat('é',10000));   -- la borne du client passe
  begin
    insert into public.aid_notes(user_id,fiche_id,note) values (lea,'f-long',repeat('a',10001));
    raise exception 'ÉCHEC 17.8 : une note de plus de 10 000 caractères est acceptée';
  exception when check_violation then null; end;
  begin
    insert into public.aid_notes(user_id,fiche_id,note) values (lea,'<img src=x>','x');
    raise exception 'ÉCHEC 17.8 : une note sous une clé hors format est acceptée';
  exception when check_violation then null; end;
  begin
    update public.aid_notes set note = repeat('a',10001) where user_id = lea and fiche_id = 'f-ok_1';
    raise exception 'ÉCHEC 17.8 : une note dépasse la borne par une mise à jour';
  exception when check_violation then null; end;
  reset role;


  ------------------------------------------------------------------ 18. Audit de sécurité (A676-A680)
  reset role;
  insert into auth.users (id, email, email_confirmed_at) values (quin,'quin@test.local',now()),(rui,'rui@test.local',now());
  insert into public.user_status(user_id,email,status) values (quin,'quin@test.local','approved'),(rui,'rui@test.local','approved')
    on conflict (user_id) do update set status='approved';

  -- 18.1 (A677) `updated_at` n'est plus antidatable : toute modification l'avance.
  perform set_config('request.jwt.claims', json_build_object('sub',quin,'role','authenticated')::text, true);
  set local role authenticated;
  insert into public.cognitive_aids(id,owner,library_id,data) values ('f-18',quin,null,'{"title":"v1"}');
  select updated_at into v_t0 from public.cognitive_aids where id='f-18';
  update public.cognitive_aids set data='{"title":"v2"}', updated_at = v_t0 - interval '1 hour' where id='f-18';
  select updated_at into v_t1 from public.cognitive_aids where id='f-18';
  if v_t1 <= v_t0 then raise exception 'ÉCHEC 18.1 : une modification antidatée garde updated_at (% -> %)', v_t0, v_t1; end if;
  update public.cognitive_aids set data='{"title":"v3"}', updated_at = v_t1 where id='f-18';
  select updated_at into v_t0 from public.cognitive_aids where id='f-18';
  if v_t0 <= v_t1 then raise exception 'ÉCHEC 18.1 : une modification à updated_at inchangé ne l''avance pas'; end if;
  update public.cognitive_aids set data='{"title":"v4"}', updated_at = now() + interval '1 day' where id='f-18';
  if (select updated_at from public.cognitive_aids where id='f-18') > now() + interval '1 minute' then
    raise exception 'ÉCHEC 18.1 : updated_at postdatable'; end if;
  reset role;

  -- 18.2 (A676) `link_end` supprime la session de compte du poste, en plus de clore le lien.
  insert into auth.sessions(id, user_id) values (v_s18a, quin), (v_s18b, quin), (v_s18c, quin);
  insert into public.device_links(kind, secret_hash, key_hash, open_until, user_id, status, ends_at, approved_at, claimed_at, auth_session)
    values ('connect', repeat('a',64), repeat('b',64), now(), quin, 'claimed', now() + interval '2 hours', now(), now(), v_s18a);
  perform set_config('request.jwt.claims', json_build_object('sub',quin,'role','authenticated','session_id',v_s18a)::text, true);
  set local role authenticated;
  v_j := public.link_end();
  reset role;
  if not (v_j->>'ok')::boolean then raise exception 'ÉCHEC 18.2 : link_end refusé (%)', v_j->>'err'; end if;
  if exists (select 1 from auth.sessions where id = v_s18a) then
    raise exception 'ÉCHEC 18.2 : la session de compte du poste survit à link_end'; end if;
  if (select status from public.device_links where auth_session = v_s18a) is distinct from 'ended' then
    raise exception 'ÉCHEC 18.2 : le lien n''est pas clos'; end if;

  -- 18.3 (A676) la purge resupprime la session d'un lien terminé ou révoqué dont la suppression avait
  -- échoué, et ne retire la ligne (7 j 30 min) qu'une fois la session partie.
  insert into public.device_links(kind, secret_hash, key_hash, open_until, user_id, status, ends_at, approved_at, claimed_at, auth_session)
    values ('connect', repeat('c',64), repeat('d',64), now(), quin, 'ended',   now() - interval '8 days', now(), now(), v_s18b),
           ('connect', repeat('e',64), repeat('f',64), now(), quin, 'revoked', now() + interval '1 hour', now(), now(), v_s18c);
  perform public.link_purge();
  if exists (select 1 from auth.sessions where id in (v_s18b, v_s18c)) then
    raise exception 'ÉCHEC 18.3 : la purge laisse vivre la session d''un lien terminé ou révoqué'; end if;
  if exists (select 1 from public.device_links where auth_session = v_s18b) then
    raise exception 'ÉCHEC 18.3 : la ligne échue depuis 8 jours n''est pas retirée une fois sa session partie'; end if;
  if not exists (select 1 from public.device_links where auth_session = v_s18c) then
    raise exception 'ÉCHEC 18.3 : une ligne révoquée non échue est retirée (la restriction tomberait)'; end if;

  -- 18.4 (A679) les LISTES d'administration sont fermées à une session de poste partagé.
  insert into public.app_admins(user_id) values (rui) on conflict do nothing;
  perform set_config('request.jwt.claims', json_build_object('sub',rui,'role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into v_cnt from public.list_accounts();
  if v_cnt = 0 then raise exception 'ÉCHEC 18.4 : un administrateur ne lit plus ses comptes'; end if;
  if public.get_instance_stats() is null then raise exception 'ÉCHEC 18.4 : un administrateur ne lit plus les statistiques'; end if;
  reset role;
  insert into auth.sessions(id, user_id) values (v_s18a, rui);
  insert into public.device_links(kind, secret_hash, key_hash, open_until, user_id, status, ends_at, approved_at, claimed_at, auth_session)
    values ('connect', repeat('1',64), repeat('2',64), now(), rui, 'claimed', now() + interval '2 hours', now(), now(), v_s18a);
  perform set_config('request.jwt.claims', json_build_object('sub',rui,'role','authenticated','session_id',v_s18a)::text, true);
  set local role authenticated;
  select (select count(*) from public.list_accounts()) + (select count(*) from public.list_users())
       + (select count(*) from public.list_all_libraries()) + (select count(*) from public.list_library_requests())
       + (select count(*) from public.list_user_memberships(alice)) into v_cnt;
  if v_cnt <> 0 then raise exception 'ÉCHEC 18.4 : une session de poste lit % ligne(s) d''administration', v_cnt; end if;
  if public.get_instance_stats() is not null then raise exception 'ÉCHEC 18.4 : une session de poste lit les statistiques'; end if;
  reset role;
  delete from public.app_admins where user_id = rui;

  -- 18.5 (A679) les aides internes « aucun grant » ne sont appelables par aucun client.
  select string_agg(f, ', ') into v_list from unnest(array['public.share_resolve(text,text)','public.share_purge()',
      'public.share_new_code()','public.share_kind_allowed(text,text)','public.share_val_ok(text,jsonb)',
      'public.session_is_poste()','public.admin_reads()']) f
   where has_function_privilege('authenticated', f, 'execute') or has_function_privilege('anon', f, 'execute');
  if v_list is not null then raise exception 'ÉCHEC 18.5 : aide interne appelable par un client : %', v_list; end if;

  -- 18.6 (A680) `share_push` : la valeur a le type de sa clé ; l'heure déclarée reste plausible.
  perform set_config('request.jwt.claims', json_build_object('sub',quin,'role','authenticated')::text, true);
  set local role authenticated;
  v_j := public.share_open('sh-18','sess-18','fic-18','{"title":"T"}'::jsonb,'scribe',60);
  reset role;
  if not (v_j->>'ok')::boolean then raise exception 'ÉCHEC 18.6 : ouverture refusée (%)', v_j->>'err'; end if;
  perform set_config('request.jwt.claims', json_build_object('role','anon')::text, true);
  set local role anon;
  v_j := public.share_join(v_j->>'code', 'IDE');
  v_sec := v_j->>'secret';
  v_j := public.share_push(v_sec, null, jsonb_build_array(
    jsonb_build_object('event_id','a6800000-0000-0000-0000-00000000000a','kind','counter','ts','2001-01-01T00:00:00Z',
      'payload', jsonb_build_object('id','__proto__ texte libre','v','douze','k','1:b1:0','running',1,'nav','x','ref','x','t','un mot')),
    jsonb_build_object('event_id','a6800000-0000-0000-0000-00000000000b','kind','timer_arm',
      'payload', jsonb_build_object('id','t1','running',true,'elapsedMs',1200,'cycles',2,'anchor',1700000000000,'t',1700000000000)),
    jsonb_build_object('event_id','a6800000-0000-0000-0000-00000000000c','kind','sig',
      'payload', jsonb_build_object('t','o','o','AbC-_123','to','p-1'))));
  reset role;
  if not (v_j->>'ok')::boolean or (v_j->>'accepted')::int <> 3 then
    raise exception 'ÉCHEC 18.6 : push refusé (%)', v_j; end if;
  if (select payload from public.session_events where share_id='sh-18' and event_id='a6800000-0000-0000-0000-00000000000a') is distinct from '{"k":"1:b1:0"}'::jsonb then
    raise exception 'ÉCHEC 18.6 : une valeur au type inattendu est conservée (%)',
      (select payload from public.session_events where share_id='sh-18' and event_id='a6800000-0000-0000-0000-00000000000a'); end if;
  if (select count(*) from jsonb_object_keys((select payload from public.session_events where share_id='sh-18' and event_id='a6800000-0000-0000-0000-00000000000b'))) <> 6 then
    raise exception 'ÉCHEC 18.6 : un évènement de minuteur légitime est amputé (%)',
      (select payload from public.session_events where share_id='sh-18' and event_id='a6800000-0000-0000-0000-00000000000b'); end if;
  if (select payload from public.session_events where share_id='sh-18' and event_id='a6800000-0000-0000-0000-00000000000c') is distinct from '{"t":"o","o":"AbC-_123","to":"p-1"}'::jsonb then
    raise exception 'ÉCHEC 18.6 : un évènement de signalisation légitime est amputé'; end if;
  if (select client_ts from public.session_events where share_id='sh-18' and event_id='a6800000-0000-0000-0000-00000000000a') < now() - interval '1 hour' then
    raise exception 'ÉCHEC 18.6 : une heure cliente de 2001 est conservée'; end if;

  -- 18.7 (A680) un lot refusé pour débit ne consomme pas le quota.
  update public.session_participants set window_count = 119, window_start = now(), events_count = 10
   where share_id='sh-18' and not is_owner;
  perform set_config('request.jwt.claims', json_build_object('role','anon')::text, true);
  set local role anon;
  v_j := public.share_push(v_sec, null, jsonb_build_array(
    jsonb_build_object('event_id','a6800000-0000-0000-0000-00000000000d','kind','check','payload','{}'::jsonb),
    jsonb_build_object('event_id','a6800000-0000-0000-0000-00000000000e','kind','check','payload','{}'::jsonb)));
  reset role;
  if v_j->>'err' is distinct from 'rate' then raise exception 'ÉCHEC 18.7 : limite de débit non appliquée (%)', v_j; end if;
  if (select events_count from public.session_participants where share_id='sh-18' and not is_owner) <> 10
     or (select window_count from public.session_participants where share_id='sh-18' and not is_owner) <> 119 then
    raise exception 'ÉCHEC 18.7 : un lot refusé a consommé le quota'; end if;

  -- 18.8 (A681) l'auteur d'une note d'équipe est l'adresse du jeton, et ne change plus ensuite.
  insert into public.libraries(id,name,created_by) values ('lib-18','Dix-huit',quin) on conflict (id) do nothing;
  insert into public.memberships(user_id,library_id,role) values (quin,'lib-18','admin'),(rui,'lib-18','editor')
    on conflict (user_id,library_id) do update set role = excluded.role;
  perform set_config('request.jwt.claims', json_build_object('sub',rui,'role','authenticated','email','rui@test.local')::text, true);
  set local role authenticated;
  insert into public.aid_followups(id,library_id,entity_id,kind,body,author) values ('fu-18','lib-18','f-18','note','n','quin@test.local');
  reset role;
  if (select author from public.aid_followups where id='fu-18') is distinct from 'rui@test.local' then
    raise exception 'ÉCHEC 18.8 : une note d''équipe est signée d''un autre (%)', (select author from public.aid_followups where id='fu-18'); end if;
  perform set_config('request.jwt.claims', json_build_object('sub',quin,'role','authenticated','email','quin@test.local')::text, true);
  set local role authenticated;
  insert into public.aid_followups(id,library_id,entity_id,kind,body,author) values ('fu-18','lib-18','f-18','note','réécrite','quin@test.local')
    on conflict (id) do update set body = excluded.body, author = excluded.author;
  reset role;
  if (select author || '|' || body from public.aid_followups where id='fu-18') is distinct from 'rui@test.local|réécrite' then
    raise exception 'ÉCHEC 18.8 : l''auteur d''une note change à la modification (%)', (select author from public.aid_followups where id='fu-18'); end if;

  -- 18.9 (A682) un id d'aide ou de protocole hors format est refusé ; un nom de bibliothèque démesuré aussi.
  perform set_config('request.jwt.claims', json_build_object('sub',quin,'role','authenticated')::text, true);
  set local role authenticated;
  begin
    insert into public.cognitive_aids(id,owner,library_id,data) values ('a b<x>',quin,null,'{}');
    raise exception 'ÉCHEC 18.9 : une aide à id hors format est acceptée';
  exception when check_violation then null; end;
  begin
    insert into public.protocols(id,owner,library_id,data) values (repeat('a',65),quin,null,'{}');
    raise exception 'ÉCHEC 18.9 : un protocole à id de 65 caractères est accepté';
  exception when check_violation then null; end;
  begin
    update public.libraries set name = repeat('n',121) where id = 'lib-18';
    raise exception 'ÉCHEC 18.9 : un nom de bibliothèque de 121 caractères est accepté';
  exception when check_violation then null; end;
  reset role;

  ------------------------------------------------------------------ 19. Quotas (A687)
  reset role;
  insert into auth.users (id, email, email_confirmed_at) values (sam,'sam@test.local',now()),(tom,'tom@test.local',now());
  insert into public.user_status(user_id,email,status) values (sam,'sam@test.local','approved'),(tom,'tom@test.local','approved')
    on conflict (user_id) do update set status='approved';
  insert into public.app_admins(user_id) values (sam) on conflict do nothing;
  select quotas into v_q0 from public.app_settings where id;

  -- 19.1 Lecture : tout compte validé lit les limites ; les défauts sont ceux annoncés.
  perform set_config('request.jwt.claims', json_build_object('sub',tom,'role','authenticated')::text, true);
  set local role authenticated;
  v_j := public.get_quotas();
  if (v_j->>'aids')::int <> coalesce((v_q0->>'aids')::int, 2000) or (v_j->>'docs') is null or (v_j->>'sessions') is null or (v_j->>'protocols') is null then
    raise exception 'ÉCHEC 19.1 : get_quotas ne rend pas les quatre limites (%)', v_j; end if;

  -- 19.2 Écriture : ni un compte ordinaire, ni une session de poste d'administrateur ; grammaire fermée.
  begin perform public.set_quotas('{"aids":10}'::jsonb);
    raise exception 'ÉCHEC 19.2 : un compte ordinaire règle les quotas';
  exception when others then if sqlerrm like 'ÉCHEC%' then raise; end if; end;
  reset role;
  insert into auth.sessions(id, user_id) values (v_s19, sam);
  insert into public.device_links(kind, secret_hash, key_hash, open_until, user_id, status, ends_at, approved_at, claimed_at, auth_session)
    values ('connect', repeat('7',64), repeat('8',64), now(), sam, 'claimed', now() + interval '2 hours', now(), now(), v_s19);
  perform set_config('request.jwt.claims', json_build_object('sub',sam,'role','authenticated','session_id',v_s19)::text, true);
  set local role authenticated;
  begin perform public.set_quotas('{"aids":10}'::jsonb);
    raise exception 'ÉCHEC 19.2 : une session de poste règle les quotas';
  exception when others then if sqlerrm like 'ÉCHEC%' then raise; end if; end;
  reset role;
  delete from public.device_links where auth_session = v_s19;
  perform set_config('request.jwt.claims', json_build_object('sub',sam,'role','authenticated')::text, true);
  set local role authenticated;
  foreach v_tbl in array array['{"aids":9}','{"aids":1000001}','{"aids":"12"}','{"aids":12.5}','{"autre":50}','{}','[]','{"aids":-20}'] loop
    begin perform public.set_quotas(v_tbl::jsonb);
      raise exception 'ÉCHEC 19.2 : set_quotas accepte %', v_tbl;
    exception when others then if sqlerrm like 'ÉCHEC%' then raise; end if; end;
  end loop;
  perform public.set_quotas('{"aids":10,"protocols":10,"sessions":10,"docs":10}'::jsonb);
  if public.get_quotas() is distinct from '{"aids":10,"protocols":10,"sessions":10,"docs":10}'::jsonb then
    raise exception 'ÉCHEC 19.2 : les quotas réglés ne se relisent pas (%)', public.get_quotas(); end if;
  reset role;

  -- 19.3 Espace personnel : la 11e aide vivante est refusée, avec le nom et la valeur de la limite ;
  -- réécrire une aide existante (l'upsert de la synchro) passe ; une tombe ne compte pas.
  perform set_config('request.jwt.claims', json_build_object('sub',tom,'role','authenticated')::text, true);
  set local role authenticated;
  insert into public.cognitive_aids(id,owner,library_id,data) select 'q19-'||g, tom, null, '{}'::jsonb from generate_series(1,10) g;
  begin
    insert into public.cognitive_aids(id,owner,library_id,data) values ('q19-11',tom,null,'{}');
    raise exception 'ÉCHEC 19.3 : une aide au-delà du quota est acceptée';
  exception when others then
    if sqlerrm like 'ÉCHEC%' then raise; end if;
    get stacked diagnostics v_list = pg_exception_detail, v_hack = pg_exception_hint;
    if sqlerrm <> 'quota_exceeded' or v_list is distinct from 'aids' or v_hack is distinct from '10' then
      raise exception 'ÉCHEC 19.3 : refus mal formé (% / % / %)', sqlerrm, v_list, v_hack; end if;
  end;
  insert into public.cognitive_aids(id,owner,library_id,data) values ('q19-3',tom,null,'{"title":"réécrite"}')
    on conflict (id) do update set data = excluded.data;
  if (select data->>'title' from public.cognitive_aids where id='q19-3') is distinct from 'réécrite' then
    raise exception 'ÉCHEC 19.3 : au quota, réécrire une aide existante est refusé'; end if;
  update public.cognitive_aids set deleted_at = now() where id = 'q19-1';
  insert into public.cognitive_aids(id,owner,library_id,data) values ('q19-11',tom,null,'{}');   -- une place s'est libérée
  insert into public.cognitive_aids(id,owner,library_id,data,deleted_at) values ('q19-tombe',tom,null,'{}',now());   -- une tombe passe toujours
  -- Les protocoles et les sessions ont leur propre compte.
  insert into public.protocols(id,owner,library_id,data) select 'q19p-'||g, tom, null, '{}'::jsonb from generate_series(1,10) g;
  begin
    insert into public.protocols(id,owner,library_id,data) values ('q19p-11',tom,null,'{}');
    raise exception 'ÉCHEC 19.3 : un protocole au-delà du quota est accepté';
  exception when others then if sqlerrm like 'ÉCHEC%' then raise; end if; end;
  insert into public.sessions(id,owner,data) select 'q19s-'||g, tom, '{}'::jsonb from generate_series(1,10) g;
  begin
    insert into public.sessions(id,owner,data) values ('q19s-11',tom,'{}');
    raise exception 'ÉCHEC 19.3 : une session au-delà du quota est acceptée';
  exception when others then if sqlerrm like 'ÉCHEC%' then raise; end if; end;
  reset role;

  -- 19.4 Le quota est PAR ESPACE : une bibliothèque a le sien, plein ou non indépendamment du personnel.
  insert into public.libraries(id,name,created_by) values ('lib-19','Dix-neuf',sam) on conflict (id) do nothing;
  insert into public.memberships(user_id,library_id,role) values (tom,'lib-19','editor')
    on conflict (user_id,library_id) do update set role = excluded.role;
  perform set_config('request.jwt.claims', json_build_object('sub',tom,'role','authenticated')::text, true);
  set local role authenticated;
  insert into public.cognitive_aids(id,owner,library_id,data) select 'q19l-'||g, tom, 'lib-19', '{}'::jsonb from generate_series(1,10) g;
  begin
    insert into public.cognitive_aids(id,owner,library_id,data) values ('q19l-11',tom,'lib-19','{}');
    raise exception 'ÉCHEC 19.4 : une bibliothèque dépasse son quota';
  exception when others then if sqlerrm like 'ÉCHEC%' then raise; end if; end;
  reset role;

  -- 19.5 Documents : la politique restrictive borne un dossier du bucket ; remplacer un objet existant passe.
  insert into storage.buckets(id,name) values ('attachments','attachments') on conflict (id) do nothing;
  insert into storage.objects(bucket_id,name) select 'attachments', 'u/'||tom||'/d'||g||'.pdf' from generate_series(1,10) g;
  if public.quota_att_ok('u/'||tom||'/d11.pdf') then raise exception 'ÉCHEC 19.5 : un 11e document passe le quota'; end if;
  if not public.quota_att_ok('u/'||tom||'/d3.pdf') then raise exception 'ÉCHEC 19.5 : remplacer un document existant est refusé'; end if;
  if not public.quota_att_ok('l/lib-19/d1.pdf') then raise exception 'ÉCHEC 19.5 : le quota d''un dossier ferme un autre dossier'; end if;
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='att_quota_ins' and permissive='RESTRICTIVE') then
    raise exception 'ÉCHEC 19.5 : la politique restrictive des documents est absente'; end if;
  delete from storage.objects where bucket_id='attachments' and name like 'u/'||tom||'/d%';

  -- 19.5b L'usage réel : l'administrateur lit le compte de l'espace le plus rempli ; personne d'autre.
  insert into storage.objects(bucket_id,name) select 'attachments', 'l/lib-19/u'||g||'.pdf' from generate_series(1,7) g;
  perform set_config('request.jwt.claims', json_build_object('sub',sam,'role','authenticated')::text, true);
  set local role authenticated;
  v_j := public.quota_usage();
  reset role;
  if (v_j->>'aids')::int < 10 or (v_j->>'protocols')::int < 10 or (v_j->>'sessions')::int < 10 or (v_j->>'docs')::int < 7 then
    raise exception 'ÉCHEC 19.5b : usage réel mal compté (%)', v_j; end if;
  if (v_j->>'aids')::int > (select count(*) from public.cognitive_aids where deleted_at is null) then
    raise exception 'ÉCHEC 19.5b : usage supérieur au total des aides (%)', v_j; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',tom,'role','authenticated')::text, true);
  set local role authenticated;
  if public.quota_usage() is not null then raise exception 'ÉCHEC 19.5b : un compte ordinaire lit l''usage de l''instance'; end if;
  reset role;
  insert into auth.sessions(id, user_id) values (v_s19, sam) on conflict (id) do nothing;
  insert into public.device_links(kind, secret_hash, key_hash, open_until, user_id, status, ends_at, approved_at, claimed_at, auth_session)
    values ('connect', repeat('5',64), repeat('6',64), now(), sam, 'claimed', now() + interval '2 hours', now(), now(), v_s19);
  perform set_config('request.jwt.claims', json_build_object('sub',sam,'role','authenticated','session_id',v_s19)::text, true);
  set local role authenticated;
  if public.quota_usage() is not null then raise exception 'ÉCHEC 19.5b : une session de poste lit l''usage de l''instance'; end if;
  reset role;
  delete from public.device_links where auth_session = v_s19;
  delete from storage.objects where bucket_id='attachments' and name like 'l/lib-19/u%';

  -- 19.6 Une écriture sans compte (dépôt d'un poste par sa clé) n'est pas comptée ; les aides internes sont fermées.
  perform set_config('request.jwt.claims', '', true);
  insert into public.sessions(id,owner,data) values ('q19s-depot',tom,'{}');
  select string_agg(f, ', ') into v_list from unnest(array['public.quotas()','public.quota_check()']) f
   where has_function_privilege('authenticated', f, 'execute') or has_function_privilege('anon', f, 'execute');
  if v_list is not null then raise exception 'ÉCHEC 19.6 : aide interne des quotas appelable par un client : %', v_list; end if;

  -- Restauration (le tout est de toute façon annulé par le ROLLBACK final).
  update public.app_settings set quotas = v_q0 where id;
  delete from public.app_admins where user_id = sam;
  ------------------------------------------------------------------ 20. Invitation avec acceptation (A685)
  reset role;
  insert into public.libraries(id,name,created_by) values ('lib-20','Vingt',quin) on conflict (id) do nothing;
  delete from public.memberships where library_id = 'lib-20' and user_id = rui;
  insert into public.cognitive_aids(id,owner,library_id,data) values ('f-20',quin,'lib-20','{"title":"secret"}');
  -- 20.1 L'invitation naît EN ATTENTE : elle ne donne rien — ni contenu, ni bibliothèque, ni membres.
  perform set_config('request.jwt.claims', json_build_object('sub',quin,'role','authenticated')::text, true);
  set local role authenticated;
  if public.invite_member('lib-20','rui@test.local','editor') <> 'ok' then raise exception 'ÉCHEC 20.1 : invitation refusée'; end if;
  if not exists (select 1 from public.list_members('lib-20') where user_id = rui and pending) then
    raise exception 'ÉCHEC 20.1 : l''administrateur ne voit pas l''invitation en attente'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',rui,'role','authenticated')::text, true);
  if public.is_member('lib-20') or public.member_role('lib-20') is not null then raise exception 'ÉCHEC 20.1 : une invitation en attente vaut adhésion'; end if;
  select (select count(*) from public.cognitive_aids where library_id='lib-20') + (select count(*) from public.libraries where id='lib-20')
       + (select count(*) from public.memberships where library_id='lib-20' and user_id <> rui) into v_cnt;
  if v_cnt <> 0 then raise exception 'ÉCHEC 20.1 : un invité non accepté lit % ligne(s) de la bibliothèque', v_cnt; end if;
  begin
    insert into public.cognitive_aids(id,owner,library_id,data) values ('f-20x',rui,'lib-20','{}');
    raise exception 'ÉCHEC 20.1 : un invité non accepté écrit dans la bibliothèque';
  exception when insufficient_privilege then null; end;
  -- … et il ne peut pas s'activer lui-même en direct.
  begin
    update public.memberships set pending = false where user_id = rui and library_id = 'lib-20';
    if not exists (select 1 from public.memberships where user_id = rui and library_id = 'lib-20' and pending) then
      raise exception 'ÉCHEC 20.1 : un invité s''active sans passer par answer_invitation'; end if;
  exception when insufficient_privilege then null; end;
  -- 20.2 Il voit SON invitation (nom, rôle, qui invite), et personne d'autre ne la voit à sa place.
  if not exists (select 1 from public.my_invitations() where library_id='lib-20' and name='Vingt' and role='editor' and invited_by='quin@test.local') then
    raise exception 'ÉCHEC 20.2 : l''invité ne voit pas son invitation'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',lea,'role','authenticated')::text, true);
  if exists (select 1 from public.my_invitations() where library_id='lib-20') then raise exception 'ÉCHEC 20.2 : un tiers voit l''invitation d''un autre'; end if;
  if public.answer_invitation('lib-20', true) <> 'not_found' then raise exception 'ÉCHEC 20.2 : un tiers répond à l''invitation d''un autre'; end if;
  -- 20.3 Refuser retire la ligne ; réinvité puis accepté, il devient membre et lit le contenu.
  perform set_config('request.jwt.claims', json_build_object('sub',rui,'role','authenticated')::text, true);
  if public.answer_invitation('lib-20', false) <> 'ok' then raise exception 'ÉCHEC 20.3 : refus impossible'; end if;
  reset role;
  if exists (select 1 from public.memberships where user_id = rui and library_id = 'lib-20') then raise exception 'ÉCHEC 20.3 : l''invitation refusée reste'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',quin,'role','authenticated')::text, true);
  set local role authenticated;
  perform public.invite_member('lib-20','rui@test.local','viewer');
  -- Depuis un poste partagé, on ne répond pas à une invitation.
  reset role;
  delete from public.device_links where user_id = rui; delete from auth.sessions where id = v_s18a;
  insert into auth.sessions(id, user_id) values (v_s18a, rui);
  insert into public.device_links(kind, secret_hash, key_hash, open_until, user_id, status, ends_at, approved_at, claimed_at, auth_session)
    values ('connect', repeat('3',64), repeat('4',64), now(), rui, 'claimed', now() + interval '2 hours', now(), now(), v_s18a);
  perform set_config('request.jwt.claims', json_build_object('sub',rui,'role','authenticated','session_id',v_s18a)::text, true);
  set local role authenticated;
  if public.answer_invitation('lib-20', true) <> 'refused' then raise exception 'ÉCHEC 20.3 : un poste partagé accepte une invitation'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub',rui,'role','authenticated')::text, true);
  if public.answer_invitation('lib-20', true) <> 'ok' then raise exception 'ÉCHEC 20.3 : acceptation impossible'; end if;
  if not public.is_member('lib-20') or (select count(*) from public.cognitive_aids where library_id='lib-20') <> 1 then
    raise exception 'ÉCHEC 20.3 : accepté, le membre ne lit pas la bibliothèque'; end if;
  if exists (select 1 from public.my_invitations()) then raise exception 'ÉCHEC 20.3 : l''invitation acceptée reste en attente'; end if;
  -- 20.4 Ré-inviter un membre déjà accepté ne le remet pas en attente (seul le rôle change).
  perform set_config('request.jwt.claims', json_build_object('sub',quin,'role','authenticated')::text, true);
  perform public.invite_member('lib-20','rui@test.local','editor');
  reset role;
  if (select role || '|' || pending::text from public.memberships where user_id = rui and library_id = 'lib-20') is distinct from 'editor|false' then
    raise exception 'ÉCHEC 20.4 : ré-inviter un membre le remet en attente'; end if;
  -- 20.5 S'inviter soi-même (l'administrateur de l'instance qui s'ajoute) rend membre aussitôt.
  insert into public.libraries(id,name,created_by) values ('lib-20b','Vingt bis',quin) on conflict (id) do nothing;
  insert into public.app_admins(user_id) values (rui) on conflict do nothing;
  perform set_config('request.jwt.claims', json_build_object('sub',rui,'role','authenticated')::text, true);
  set local role authenticated;
  v_hack := public.invite_member('lib-20b', 'rui@test.local', 'viewer');
  if v_hack <> 'ok' or not public.is_member('lib-20b') then
    raise exception 'ÉCHEC 20.5 : l''administrateur de l''instance qui s''ajoute n''est pas membre aussitôt (%)', v_hack; end if;
  reset role;
  delete from public.app_admins where user_id = rui;

  ------------------------------------------------------------------ FIN
  reset role;
  raise notice '✅ TOUS LES TESTS RLS PASSENT';
end $$;

rollback;  -- IMPORTANT : aucune donnée de test conservée.

-- Confirmation VISIBLE dans le SQL Editor (qui n'affiche pas les RAISE NOTICE) : cette ligne ne
-- s'exécute que si tout ce qui précède a réussi — un échec de test aurait interrompu le script.
select '✅ TOUS LES TESTS RLS PASSENT' as resultat;
