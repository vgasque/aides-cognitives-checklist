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
  erin  uuid := '55555555-5555-5555-5555-555555555555';
  frank uuid := '66666666-6666-6666-6666-666666666666';
  gina  uuid := '77777777-7777-7777-7777-777777777777';
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

  ------------------------------------------------------------------ FIN
  reset role;
  raise notice '✅ TOUS LES TESTS RLS PASSENT';
end $$;

rollback;  -- IMPORTANT : aucune donnée de test conservée.

-- Confirmation VISIBLE dans le SQL Editor (qui n'affiche pas les RAISE NOTICE) : cette ligne ne
-- s'exécute que si tout ce qui précède a réussi — un échec de test aurait interrompu le script.
select '✅ TOUS LES TESTS RLS PASSENT' as resultat;
