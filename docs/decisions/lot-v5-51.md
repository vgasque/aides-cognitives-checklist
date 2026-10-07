# Lot v5.51 — A478-A479

Qui crée une bibliothèque (A478), et qui la demande (A479). Suite du canevas « Rangement de l'accueil » : les
collections (A475) retirent le besoin de créer une bibliothèque pour ranger ; reste la vraie question — qui décide
qu'un nouvel ESPACE PARTAGÉ existe.

## A478 — le droit de créer une bibliothèque (v5.51.0)

**Avant** : seuls les administrateurs de l'instance (`app_admins`, tableau de bord Supabase) — la politique
`lib_insert` exigeait `is_app_admin()`.

**Décision** (canevas, modèles B + C + D) : un réglage d'instance dans Moi › Administration, « Création de
bibliothèques », à trois crans — *Administrateurs seulement* · *Personnes autorisées* · *Tout compte approuvé*.
Défaut **Personnes autorisées avec une liste vide** : exactement le comportement d'avant, rien ne change sans geste.

- **Serveur** (`supabase/schema.sql` § 9, à rejouer) : `app_settings.library_creation`, table `library_creators`
  (sans politique ni grant, comme `app_admins`), `can_create_library()` (approuvé ET règle), politique `lib_insert`
  réécrite — **un non-administrateur ne crée que pour lui-même** (`created_by = auth.uid()`, sans quoi le trigger
  `lib_add_creator` ferait administrateur un autre compte). RPC administrateur : `get/set_library_creation`,
  `list_users` (comptes approuvés), `set_library_creator`.
- **Client** : `myCanCreateLib` (profil, mis en cache) remplace `myIsAppAdmin` aux portes de création (colonne,
  feuille Gérer, Moi, fenêtre). **Serveur antérieur** (schéma pas rejoué) : l'appel échoue, repli sur
  l'administrateur seul — rien ne casse ; Administration le dit.
- **Administration** : le segmenté à pastille (patron A350), la liste des personnes autorisées (« Retirer ») et
  « ＋ Autoriser une personne… » (`openPickMenu`, filtre dès 9 comptes). La phrase rappelle que ranger n'exige
  aucun droit : les collections sont à tous.
- Tests RLS (§ 15 de `rls-tests.sql`) : refus par défaut, table illisible, auto-autorisation refusée, création pour
  soi seulement, règle « admins ».

## A479 — demander une bibliothèque (v5.51.0)

Qui n'a pas le droit voit « ＋ Demander une bibliothèque… » à la place de « Nouvelle bibliothèque » : **la même
fenêtre** (A477), même question « Avec qui ? », même garde-fou (sans invité, une collection suffit), action
« Envoyer la demande ».

- **Serveur** (§ 9bis) : `library_requests` (nom, e-mails des invités, rôle ; 3 demandes en attente au plus, 20
  invités), RPC `request_library`, `my_library_requests`, `cancel_library_request`, `list_library_requests`
  (administrateur), `decide_library_request` : **accepter** crée la bibliothèque au nom du demandeur (il en devient
  administrateur), invite les personnes (`invite_member` — jamais le demandeur lui-même, qui serait rétrogradé) et
  **supprime la demande** ; **refuser** garde la ligne « refusée » mais vide les e-mails.
- **Données personnelles** : les e-mails des invités ne vivent que jusqu'à la décision — registre RGPD § 3 complété.
- **Moi** : mes demandes en rangées (« en attente » · Annuler ; « refusée » · Effacer). **Administration** : la file
  en tête, « Refuser » / « Créer » par demande, sans fenêtre neuve.
