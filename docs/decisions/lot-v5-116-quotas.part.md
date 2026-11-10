<!-- Fragment à replier dans le fichier du lot v5.116 (A687-A688). -->

## A687 — Quotas par espace, appliqués par le serveur (à rejouer)

**Le constat** (audit de sécurité, lot v5.115.1 puis v5.115.2 « reste ouvert ») : seule la TAILLE
d'une ligne et d'un fichier était bornée, jamais leur NOMBRE. Un seul compte — malveillant, ou un
client en boucle — pouvait remplir le quota de l'instance et arrêter la synchro de tous. Décision de
l'auteur (10/11/2026) : « Quota → OK, avec option pour modifier, depuis le panneau d'admin ».

**Ce qui est borné**, PAR ESPACE — l'espace personnel d'un compte (`library_id is null`, compté par
`owner`) et chaque bibliothèque (`library_id`) :

| Clé | Ce qui est compté | Défaut |
|---|---|---|
| `aids` | aides vivantes d'un espace | 2000 |
| `protocols` | protocoles vivants d'un espace | 2000 |
| `sessions` | sessions vivantes d'un compte | 5000 |
| `docs` | documents PDF d'un dossier du bucket (`u/<compte>/`, `l/<bibliothèque>/`) | 1000 |

Les limites vivent dans `app_settings.quotas` (jsonb, comme `temp_rules`) ; `quotas()` les complète
par les défauts.

**Les règles qui comptent plus que les chiffres :**

1. **Seuls les AJOUTS sont refusés.** Réécrire une ligne qui existe passe toujours : l'upsert de la
   synchro (`resolution=merge-duplicates`) traverse `BEFORE INSERT` même quand l'id existe, le
   déclencheur regarde donc d'abord si la ligne est là. Un quota abaissé sous l'usage courant ne
   supprime rien et ne fige rien.
2. **Seules les lignes VIVANTES comptent** (`deleted_at is null`). Pousser une tombe n'est jamais
   refusé ; supprimer libère une place.
3. **Une écriture sans compte n'est pas comptée** (`auth.uid() is null`) : c'est le dépôt d'un poste
   partagé par sa clé (`link_deposit`), après quoi le poste s'efface. Un compte rendu de soin ne se
   perd pas pour un quota.
4. **Le refus dit ce qu'il refuse** : `raise exception 'quota_exceeded'` (SQLSTATE `P0001`),
   `detail` = la clé, `hint` = la limite. PostgREST répond 400 avec
   `{"code":"P0001","details":"aids","hint":"2000","message":"quota_exceeded"}`.
5. **Documents** : une politique RESTRICTIVE d'insertion sur `storage.objects` (`att_quota_ins`),
   par un relais en definer (`quota_att_ok`), comme `att_temp_ins`. Remplacer un objet existant
   (x-upsert) passe. Le stockage répond alors 403, comme pour tout refus de politique : il ne sait
   pas dire « quota ».
6. **Le compte est pris sans verrou** : deux ajouts simultanés peuvent dépasser d'une ligne. C'est
   une borne d'abus, pas une comptabilité. Deux index partiels (`… (owner) where library_id is
   null`) évitent qu'un lot poussé relise la table.

**Réglage** : `get_quotas()` (tout compte validé — l'app dit la limite dans son message) et
`set_quotas(jsonb)` — administrateur, jamais depuis une connexion temporaire (un poste resté ouvert
ne desserre pas une borne), grammaire FERMÉE : les quatre clés, des entiers, de 10 à 1 000 000.
`quotas()` et `quota_check()` sont révoquées nominativement des clients.

**Formes écartées.**
- *Un quota par COMPTE, toutes bibliothèques confondues.* Une bibliothèque d'équipe se remplirait
  sur le compte de qui importe ; la limite doit suivre l'espace que l'on remplit.
- *Compter les tombes.* Elles ne se purgent pas à la main : un espace resterait plein après
  suppression, sans geste possible.
- *Une limite à 0 ou sans plancher.* Un geste d'administrateur fermerait l'écriture à tous.
- *Un quota en octets.* Chaque ligne est déjà bornée (20 Mo, 1 Mo pour une session, 15 Mo par PDF) :
  le nombre suffit à borner le total, et se lit d'un coup d'œil.
- *Refuser le lot entier côté client.* `_pushTable` rejoue déjà un lot refusé ligne à ligne : ce
  qui existe part, seul l'ajout en trop reste « à envoyer ».

**Limites dites.** Les sessions d'un compte très actif finiront par approcher 5000 : la limite se
relève dans l'administration. Les tables `category_sets`, `aid_notes`, `aid_followups` ne sont pas
comptées (une ligne par espace pour la première ; les deux autres sont bornées en taille par ligne
et restent à décider si l'usage le demande). Vérifié sur un PostgreSQL 16 local avec bouchons
Supabase (§ 19 de `rls-tests.sql`, vu rouge sur l'ancien schéma) — pas sur une instance Supabase : la
forme exacte du refus de stockage (403) et le corps de l'erreur PostgREST restent à constater en
production.

## A688 — Les quotas se règlent dans Administration › Règles, et l'app dit le refus

**Administration › Règles › « Quotas »**, sous « Connexion temporaire » : quatre champs numériques
(aides, protocoles, sessions enregistrées, documents PDF), chacun avec ce qu'il compte. Même
confirmation sur place que les autres réglages (A661) : la saisie DEMANDE (« la limite passe de 2000
à 500 … »), « Confirmer » applique. Une saisie hors bornes est ramenée dans 10 – 1 000 000. Sur un
serveur d'avant v5.116, le bloc dit que le schéma est à rejouer, comme les autres sections.
Aucune règle CSS nouvelle : rangée `.adm-urow`, champ `.auth-field` (16 px).

**Le refus** arrive par la surface d'erreur de synchro existante (`explainSyncError` → pastille et
fenêtre « Erreur de synchro ») : « Quota atteint — … la limite de 2000 aides par espace … est
atteinte. Rien n'est perdu … ». Jamais une fenêtre qui s'ouvre seule, rien pendant une session
(règle 11) : c'est le chemin des autres refus de publication. `quotaErrInfo` ne lit du corps que la
clé (jeu fermé) et la valeur (chiffres) — jamais un texte du serveur à l'écran. Le texte du refus 403
dit désormais qu'un document PDF peut aussi être refusé par le quota de documents.

**Le guide, sur place** (demande de l'auteur : « avec guide pour les quotas, histoire qu'on sache
comment les remplir »). Sous chaque champ : ce qui est compté, puis une ligne de repère — « Le plus
rempli aujourd'hui : 312. Par défaut : 2 000. De 10 à 1 000 000. ». Le premier nombre est RÉEL : le
compte de l'espace le plus chargé de l'instance, rendu par `quota_usage()` (administrateur seulement,
jamais depuis un poste partagé — `admin_reads` ; des nombres, aucun nom de compte ni de bibliothèque).
Deux paragraphes ferment le bloc : « Quand une limite est atteinte » et « Comment choisir » — ces
limites arrêtent un compte qui s'emballe, elles ne réservent pas de place ; le vrai plafond est la
taille de base et de stockage de l'offre Supabase (20 Mo par aide ou protocole, 1 Mo par session,
15 Mo par PDF : chiffres relus dans `schema.sql`).

**Une valeur sous l'usage actuel n'est PAS refusée** (l'administrateur peut vouloir geler la
croissance) : une ligne « △ En dessous de l'usage actuel (1 204) : plus aucun ajout dans les espaces
concernés. Rien n'est supprimé. » paraît sous le champ, et la demande de confirmation le redit.

**Le même guide par écrit** : `docs/deploiement-et-conformite.md` § 1.8, avec les requêtes SQL pour
lire et relever les limites sans l'application. L'écran et le document disent la même chose
(`ADM_QUOTA_ROWS` le rappelle) : ils se changent ensemble.

**Ce que l'app ne fait pas.** Elle n'affiche pas, à chaque utilisateur, de jauge « 1 874 / 2 000 » : compter demanderait un
appel de plus à chaque synchro, pour une limite que presque personne n'approchera. Elle ne bloque
pas la création locale : l'aide existe sur l'appareil et reste « à envoyer » ; la limite est celle
du serveur, et hors ligne l'app n'en sait rien.
