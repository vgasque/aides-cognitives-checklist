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
  v_hack text;
  v_cnt  int;
  v_leak int;
  v_tbl  text;
  v_tbls text[];
  v_list text;
  -- Liste blanche des fonctions du schéma `public` que le rôle anon a le droit d'exécuter.
  -- VIDE aujourd'hui, et c'est la posture du projet. À n'étendre qu'avec une justification
  -- écrite dans schema.sql, jamais « pour faire passer le test ».
  v_anon_fns_ok text[] := array['share_join','share_pull','share_push'];
  v_j    jsonb;
  v_j2   jsonb;
  v_code text;
  v_sec  text;
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
  insert into public.fiches(id,owner,library_id,data) values ('f-other',alice,'lib-other','{"t":1}')
    on conflict (id) do nothing;

  -- 8.1 Editor : peut créer/lire une fiche de SA bibliothèque.
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  set local role authenticated;
  insert into public.fiches(id,owner,library_id,data) values ('f-team',erin,'lib-team','{"t":1}');
  select count(*) into v_cnt from public.fiches where id='f-team';
  if v_cnt <> 1 then raise exception 'ÉCHEC : un editor ne peut pas créer une fiche dans sa bibliothèque'; end if;

  -- 8.2 Viewer : peut LIRE mais pas ÉCRIRE (RLS -> 0 ligne affectée, sans erreur, comme section 1).
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'role','authenticated')::text, true);
  select count(*) into v_cnt from public.fiches where id='f-team';
  if v_cnt <> 1 then raise exception 'ÉCHEC : un viewer ne voit pas une fiche de sa bibliothèque'; end if;
  update public.fiches set data='{"hack":1}' where id='f-team';
  reset role;
  select data->>'hack' into v_hack from public.fiches where id='f-team';
  if v_hack is not null then raise exception 'ÉCHEC : un viewer a pu modifier une fiche de sa bibliothèque'; end if;

  -- 8.2bis Déplacer une fiche partagée vers Perso (fonctionnalité VOULUE : sélecteur de
  -- bibliothèque de l'éditeur, cf. CHANGELOG 3.2.3 « déplacement de fiche entre bibliothèques »)
  -- reste réservé à un EDITOR/ADMIN de la bibliothèque d'origine — un simple viewer ne peut PAS
  -- s'en servir pour exfiltrer une fiche vers son propre espace perso. fiches_shared_write exige
  -- member_role in ('editor','admin') sur la ligne D'ORIGINE (USING) : un viewer échoue cette
  -- condition -> RLS -> 0 ligne affectée, sans erreur (même mécanique que le test précédent).
  reset role;
  insert into public.fiches(id,owner,library_id,data) values ('f-move',erin,'lib-team','{"t":1}')
    on conflict (id) do nothing;
  perform set_config('request.jwt.claims', json_build_object('sub',frank,'role','authenticated')::text, true);
  set local role authenticated;
  update public.fiches set library_id=null, owner=frank where id='f-move';
  reset role;
  select library_id into v_hack from public.fiches where id='f-move';
  if v_hack is distinct from 'lib-team' then raise exception 'ÉCHEC : un viewer a pu exfiltrer une fiche partagée vers son espace perso'; end if;

  -- Un EDITOR de la bibliothèque, en revanche, peut légitimement déplacer CETTE MÊME fiche vers
  -- Perso (non-régression : USING valide sur l'ancienne ligne — editor de lib-team — ET WITH
  -- CHECK valide sur la nouvelle — owner = soi-même, cf. fiches_perso).
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  set local role authenticated;
  update public.fiches set library_id=null, owner=erin where id='f-move';
  select count(*) into v_cnt from public.fiches where id='f-move' and library_id is null and owner=erin;
  if v_cnt <> 1 then raise exception 'ÉCHEC : un editor ne peut pas déplacer une fiche de sa bibliothèque vers Perso'; end if;

  -- 8.3 Non-membre : ni lecture ni écriture.
  perform set_config('request.jwt.claims', json_build_object('sub',gina,'role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into v_cnt from public.fiches where id='f-team';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un non-membre voit une fiche de la bibliothèque'; end if;
  begin
    insert into public.fiches(id,owner,library_id,data) values ('f-intru',gina,'lib-team','{"t":1}');
    raise exception 'ÉCHEC : un non-membre a pu écrire dans la bibliothèque';
  exception when insufficient_privilege then null; end;

  -- 8.4 Étanchéité entre bibliothèques : un membre de lib-team ne voit pas les fiches de lib-other.
  perform set_config('request.jwt.claims', json_build_object('sub',erin,'role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into v_cnt from public.fiches where id='f-other';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un membre de lib-team voit une fiche de lib-other'; end if;

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
  if v_hack <> 'not_approved' then raise exception 'ÉCHEC : invite_member a accepté un compte non approuvé (résultat : %)', v_hack; end if;
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
  select count(*) into v_cnt from public.fiches where id='f-team';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un compte rejeté lit encore une fiche partagée'; end if;
  select count(*) into v_cnt from public.protocols where id='p-team';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un compte rejeté lit encore un protocole partagé'; end if;
  select count(*) into v_cnt from storage.objects where bucket_id='attachments' and name='l/lib-team/att-t1.pdf';
  if v_cnt <> 0 then raise exception 'ÉCHEC : un compte rejeté lit encore un document du bucket partagé'; end if;

  -- 11.3 erin (rejetée) n'ÉCRIT plus rien de partagé (UPDATE -> 0 ligne sans erreur ; INSERT -> refus).
  update public.fiches set data='{"revoked":1}' where id='f-team';
  update storage.objects set metadata='{"revoked":1}' where bucket_id='attachments' and name='l/lib-team/att-t1.pdf';
  begin
    insert into public.fiches(id,owner,library_id,data) values ('f-revoked',erin,'lib-team','{"t":1}');
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
  select data->>'revoked' into v_hack from public.fiches where id='f-team';
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
  update public.fiches set data='{"t":2,"updatedBy":"chef@example.org"}' where id='f-team';
  reset role;
  select data->>'updatedBy' into v_hack from public.fiches where id='f-team';
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
  update public.fiches set data='{"t":3}' where id='f-team';
  reset role;
  select count(*) into v_cnt from public.fiches where id='f-team' and data ? 'updatedBy';
  if v_cnt <> 0 then raise exception 'ÉCHEC : updatedBy a été ajouté à un payload qui ne le portait pas'; end if;

  -- 12.4 SANS claim email (service_role, SQL Editor, maintenance) : la valeur déclarée est
  -- CONSERVÉE (ne pas casser les opérations d'administration). NB : set_config(..., true)
  -- persiste jusqu'à la fin de la transaction, même après reset role -> on vide explicitement
  -- les claims pour simuler l'absence de JWT.
  perform set_config('request.jwt.claims', '{}', true);
  update public.fiches set data='{"t":4,"updatedBy":"admin@ops.local"}' where id='f-team';
  select data->>'updatedBy' into v_hack from public.fiches where id='f-team';
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
  -- Et l'on nomme ce qui doit passer, plutôt que de se fier à un COMPTE : trois acceptés pourraient
  -- être les trois mauvais.
  if not exists (select 1 from public.session_events where share_id='sh-1' and kind='nav') then
    raise exception 'ÉCHEC 14.5 : le scribe ne peut pas faire avancer la checklist'; end if;
  if not exists (select 1 from public.session_events where share_id='sh-1' and kind='timer_stop') then
    raise exception 'ÉCHEC 14.5 : le scribe ne peut pas arrêter un minuteur'; end if;
  if exists (select 1 from public.session_events where share_id='sh-1'
              and kind in ('uncheck','timer_reset','end')) then
    raise exception 'ÉCHEC 14.5 : un geste DESTRUCTEUR du scribe a été écrit'; end if;

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


  ------------------------------------------------------------------ FIN
  reset role;
  raise notice '✅ TOUS LES TESTS RLS PASSENT';
end $$;

rollback;  -- IMPORTANT : aucune donnée de test conservée.

-- Confirmation VISIBLE dans le SQL Editor (qui n'affiche pas les RAISE NOTICE) : cette ligne ne
-- s'exécute que si tout ce qui précède a réussi — un échec de test aurait interrompu le script.
select '✅ TOUS LES TESTS RLS PASSENT' as resultat;
