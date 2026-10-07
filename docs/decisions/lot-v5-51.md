# Lot v5.51 — A478-A482

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

## A480 — la tête d'une feuille : retour en lien, titre = le geste, une ligne de contexte (v5.51.1)

**Signalé (07/10/2026)** — dans une sous-feuille ouverte depuis « Actions », on lisait une rangée « ‹ Actions —
retour aux actions », puis « 2 éléments », puis « Bloc CHU » dessous : trois lignes sans hiérarchie, et aucune ne
disait CE QU'ON FAISAIT. **Décision de l'auteur, sur captures** : « ‹ Actions » devient un petit LIEN de retour
(`.mm-back`, sans sous-ligne), le TITRE de la feuille est le geste (`.mm-title`, 17,5/800 : « Déplacer vers une
bibliothèque », « Ranger dans une catégorie », « Ajouter à une collection », « Ajouter des aides »), puis UNE ligne
grise de contexte (`.mm-ctxl`, `selCtx()` : « 2 éléments · deux bibliothèques ») — la même sur toutes les feuilles de
la sélection et des collections. `openPickMenu` gagne `title` et `ctx` ; `head` ne porte plus que les notices.

- La feuille à cases porte l'icône de chaque collection (★ pour l'Accès direct, signet sinon — `menuRowHtml` gagne
  `ic2`), la case restant au bord (signalé : « pas d'étoile pour l'Accès direct »).
- **Défaut antérieur corrigé en route** : « Déplacer vers une bibliothèque » cochait « Ma bibliothèque perso » sur une
  sélection répartie entre deux bibliothèques (valeur `''` par défaut) — aucune rangée cochée quand c'est mêlé,
  patron de « Ranger » (A424).
- La case vide de la feuille à cases prend le contour `--ctl-line` (3:1 dans les deux thèmes, A67) : en sombre,
  `--line-strong` la rendait presque invisible.

## A481 — changer la règle de création se confirme (v5.51.1)

Signalé : un tap sur un autre cran du segmenté « Création de bibliothèques » appliquait aussitôt une règle qui vaut
pour TOUTE l'instance. Le tap ouvre désormais un bandeau sous le segmenté (patron de la notice système) qui dit
l'effet — « Passer à « Tout compte approuvé » : tout compte approuvé pourra créer des bibliothèques et en deviendra
administrateur » — avec Annuler / Confirmer ; rien ne part au serveur avant « Confirmer » (témoin réseau simulé).

## A482 — le design system se relève sur l'app (v5.51.1)

Audit avant synchro : la fiche Couleurs citait **31 tokens purgés en A416** (pastilles vides depuis la v5.38.1), et
neuf fiches montraient des composants retirés — rail ①②③ (v5.0), Échelle (A376), glyphes ⚠/△ (A345), quai d'avant
la v5.6, menu ⋯ d'avant A361. `design:check` restait vert : il ne contrôle que la régénération. **Décision de
l'auteur** : refaire ces fiches depuis le DOM RÉEL. `design/capture.mjs` (Playwright, dev seulement) relève sur
l'aide d'exemple l'écran de démarrage, les étapes, « Vérifier », le journal, le parcours, la Page (réduite à
l'échelle, ses voies étant mesurées), l'accueil, l'en-tête, la capsule, le quai et le menu ⋯ ; `build.mjs` les
intègre et échoue si une capture manque. La fiche Couleurs se construit sur les tokens actuels, rangés par registre,
et échoue si l'un disparaît. Nouvelle fiche « Rangement » (collections, feuille à cases, barre de sélection en
tiroir). `GUIDELINES.md` rattrapé de la v5.29.4 à la v5.51 (22 lots), vérifié : tout token, classe ou id qu'il cite
comme vivant existe dans le code. **À rejouer quand une surface capturée change** : `node design/capture.mjs`.
