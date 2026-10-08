# Lot v5.55 — A494-A495

Demande de l'auteur : « améliore le panneau Administration dans l'onglet Moi pour y ajouter de la structure et de la
clarté, il y a plein de nouvelles options qui sont apparues récemment. Je dois pouvoir gérer un petit nombre comme un
grand nombre d'utilisateurs, de bibliothèques ». Maquette validée sur canevas Claude Design (« Administration —
refonte », neuf planches : Moi, vue d'ensemble, comptes, un compte, bibliothèques, règles, petite instance, bureau).

## A494 — Administration devient une PAGE à sections, ouverte depuis Moi (v5.55.0)

**Avant** : en quatre lots (A438, A478-A479, A481, A483-A484), la zone « Administration » du bas de Moi avait empilé,
dans une seule colonne, huit blocs de nature différente — la rangée « Demandes de compte » (qui ouvrait une AUTRE
fenêtre, « Comptes en attente »), la file des demandes de bibliothèque, la règle de création à trois crans, les
personnes autorisées, la liste de TOUS les comptes (dépliables sur place), la liste de TOUTES les bibliothèques, les
quatre tuiles et les cartes Contenus / Stockage. Deux files « à traiter » vivaient à deux endroits ; l'interrupteur
« Exiger une validation pour les nouveaux comptes » était caché dans la fenêtre des comptes en attente ; à 200 comptes
la page devenait une liste interminable, filtrable au texte seulement.

**Décision** :

- **Une porte dans Moi**, sous la carte du compte (`admDoorHtml`, `#admDoor`) : « Administration », un résumé
  (n comptes · n bibliothèques · règles · état de l'instance) et une pastille « n à traiter ». La carte du compte
  elle-même ne change pas (demande de l'auteur : e-mail, Synchroniser · Exporter, « Se déconnecter » sur sa ligne).
  Rien de l'instance n'est plus empilé dans Moi.
- **Une page dédiée**, jamais une entrée de la colonne gauche (décision de l'auteur : « la sidebar est déjà
  chargée ») : page-fenêtre `#admModal` au téléphone et depuis une aide ; dès 780 sur l'accueil, VUE de la colonne
  (`state.homeTab='admin'`, patron d'A365) avec « ‹ Moi » et « Moi » reste courant dans la colonne. Au franchissement
  de 780 la surface change de peau, section gardée (`syncHomeTabs`).
- **Quatre sections** — onglets dès 780 (« Vue d'ensemble · Comptes · Bibliothèques · Règles », compteurs), rangées
  de navigation au téléphone :
  - *Vue d'ensemble* : **À traiter** (UNE file, les plus anciennes d'abord : demandes de compte et de bibliothèque,
    Refuser · Approuver/Créer sur place ; toutes les demandes de bibliothèque, trois demandes de compte, puis « Voir
    les n demandes de compte · approuver par lot » vers la liste filtrée ; à vide, « Rien à traiter » sans couleur),
    **Annuaire**, **Règles de l'instance** (deux rangées), **État de l'instance** (tuiles et cartes d'A438, inchangées).
  - *Comptes* : recherche, filtres à compteurs (Tous · En attente · Approuvés · Refusés · Peuvent créer ·
    Administrateurs — un filtre à zéro n'apparaît pas), tri (à traiter d'abord, groupé par statut · e-mail · inscription
    récente · plus de bibliothèques), 40 rangées à la fois (« Afficher n de plus »), **sélection pour approuver ou
    refuser par lot** (barre collante ; un envoi `set_user_status` par compte ; refuser un compte déjà approuvé est dit
    dans la confirmation : il perd ses adhésions).
  - *Un compte* : page à part au téléphone, **à côté de la liste** quand la vue fait ≥ 900 px rendus (`admSplit`) —
    accès (statut et son geste, « Peut créer des bibliothèques », qui dit quand il est SANS EFFET sous la règle en
    vigueur), bibliothèques avec le rôle sur place, « ＋ Ajouter à une bibliothèque… » (`invite_member`, comme
    Lecteur), « Créées par ce compte », zone sensible (Suspendre l'accès… · Supprimer le compte…).
  - *Bibliothèques* : recherche, filtres de SANTÉ (« △ Sans administrateur » en ambre — personne ne peut y inviter —,
    « Vides », « Dont je suis membre »), tri « à surveiller d'abord », pages de 40 ; une rangée ouvre Membres (A484).
  - *Règles* : **Nouveaux comptes** (l'interrupteur de l'ancienne fenêtre, `get/set_approval_required`) et
    **Création de bibliothèques** (trois choix DÉCRITS en boutons radio au lieu du segmenté à trois crans, « en
    vigueur », personnes autorisées). Les deux changements se confirment dans un bandeau (A481) — et le bandeau de la
    validation dit l'effet RÉEL, lu dans `schema.sql` : couper donne accès AUSSITÔT aux comptes déjà en attente
    (`my_status`, `is_approved` lisent le réglage) ; réactiver remet en attente ceux qui y étaient restés, les comptes
    créés entre-temps restant approuvés (`handle_new_user` les a écrits approuvés).
- **Petit ou grand nombre** : au-delà d'`ADM_INLINE` (8) comptes ou bibliothèques, la vue d'ensemble les résume en une
  rangée et la section porte recherche + filtres ; en deçà, la liste est POSÉE dans la vue d'ensemble, sans outil.
- **Une lecture** (`admLoad`) : sept RPC en parallèle, chacune tolérée seule — un schéma antérieur n'éteint que sa
  section (« Rejouez supabase/schema.sql (v5.5x) pour… »), et un serveur d'avant v5.52 garde la file des comptes
  en attente (`list_unapproved_users`). Relue après chaque geste, à la fermeture de Membres, à l'ouverture de la page ;
  la porte de Moi se repeint sans re-rendre Moi (`admPaintDoor`).
- **Retour système** (A430) : une section = un niveau, un compte ouvert depuis Comptes = deux ; une fenêtre posée
  par-dessus (Membres) se ferme d'abord. Vue large : la page compte un niveau de plus que Moi.
- **Statut affiché** : validation coupée, un compte encore « pending » en base a déjà accès — il se lit « Approuvé »
  (`admCat`). « En attente » prend l'ambre (choix de l'auteur), les autres statuts restent sans couleur.
- **Gestes et serveur** : aucune écriture neuve — `set_user_status`, `delete_rejected_user`, `set_library_creator`,
  `set_library_creation`, `set_approval_required`, `decide_library_request`, `invite_member`, PATCH/DELETE
  `memberships` (bornés bibliothèque ET compte). Aucun schéma à rejouer.

**Purgé** : la fenêtre « Comptes en attente » (`#pendingModal`, `openPending`/`renderPending`), `loadInstanceStats`,
`loadLibRights`, `loadAdmPeople`, `admUserPanel`, `_admOpen`, la zone `#authStats` de Moi, les règles `#admLibs`,
`#admPeople`, `.adm-req`, `.adm-go`, `.adm-list`, `.adm-user`, `.pend-badge`, `.btn.ghost-danger` (n'avaient plus de
porteur) et `memIni`.

**Formes écartées** : Administration dans la colonne gauche (sous-entrées de Moi, compteur) — refusée par l'auteur ;
la liste des comptes dépliable sur place (A483) — à 200 comptes, une rangée ouverte se perd ; garder le segmenté à
trois crans pour la règle de création — ses libellés longs passaient sur deux lignes à 390 px et ne disaient pas
l'effet.

Témoins : `audit-doctrine` « MOI · A478-A479, A483 » (réécrit : porte, vue de colonne, À traiter, règles confirmées,
compte à côté de la liste, A484 et relecture) et « MOI · A494 Administration à l'échelle » (390 → 1280 : 60 comptes,
filtre, lot, pages de 40, recherche qui garde le focus, retour système, franchissement de 780) ; `audit-a11y`
« administration », « administration · comptes », « administration · règles » (remplacent « comptes en attente »).

## A495 — deux retours sur la page (v5.55.1)

Signalés par l'auteur après la v5.55.0 :

- **« Nouveaux comptes » et « Création de bibliothèques » menaient à la MÊME page.** La vue d'ensemble posait deux
  rangées sous « Règles de l'instance », chacune ouvrant la page qui porte les deux règles. Deux portes pour une
  pièce promettent deux pièces. **Une seule rangée** : « Nouveaux comptes et bibliothèques », dont la sous-ligne dit
  les deux réglages en vigueur (« Comptes validés un par un · création : personnes autorisées (5) »). Séparer en deux
  pages a été écarté : la page des règles est courte, et les deux réglages se lisent mieux ensemble.
- **Le retour n'avait pas la même place selon la largeur** : au-dessus du titre en vue large (« ‹ Moi » sur
  « Administration »), SOUS le titre au téléphone (la fenêtre gardait « Administration » dans sa barre et posait
  « ‹ Administration » puis « Comptes » dans le corps — le mot écrit deux fois). Au téléphone, la barre de la fenêtre
  porte désormais le titre de la SECTION et le retour AU-DESSUS (`admTopPaint`, `#admBack`) : « ‹ Moi » sur
  « Administration » (Moi ouvert dessous), « ‹ Administration » sur « Comptes », « ‹ Comptes » sur « Compte » ; la
  croix reste sur la ligne du titre. Le corps ne répète plus ni retour ni titre. En vue large rien ne change : « ‹ Moi »
  au-dessus d'« Administration », les onglets portent la section.

Témoin : `audit-doctrine` « MOI · A494 Administration à l'échelle » (titre et retour aux trois niveaux, aucun retour
ni titre dans le corps, une seule rangée de règles).
