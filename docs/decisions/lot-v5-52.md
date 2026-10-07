# Lot v5.52 — A483

L'administrateur de l'instance voit tout et règle les droits (A483). Demande de l'auteur, après A478-A479 : « l'admin
de l'app doit pouvoir avoir une vision sur toutes les bibliothèques et gérer les droits », puis « une administration
des utilisateurs aussi ».

## A483 — comptes et bibliothèques de l'instance, dans Administration (v5.52.0)

**Avant** : Administration ne montrait que les comptes EN ATTENTE (fenêtre « Demandes de compte ») et les
bibliothèques dont l'administrateur était lui-même membre. Une bibliothèque créée par une personne autorisée (A478)
était invisible à l'administrateur de l'instance, qui ne pouvait ni la voir ni en régler les membres sans passer par
le tableau de bord Supabase. Un compte approuvé ne se suspendait pas depuis l'app.

**Décision** — deux cartes sous les droits de création, dans Moi › Administration, sans fenêtre neuve :

- **Comptes · n** : tous les comptes (approuvés, en attente, refusés), une rangée `menuRowHtml` chacun (e-mail ;
  statut · nombre de bibliothèques · « peut créer »). La rangée **se déplie sur place** (une seule ouverte, patron
  du gestionnaire de catégories) : statut et son geste (Approuver · Refuser · Suspendre l'accès… · Réapprouver ·
  Supprimer le compte…, par `set_user_status` / `delete_rejected_user` — un administrateur n'a aucun geste,
  `set_user_status` le refuse déjà), interrupteur « Peut créer des bibliothèques » (`set_library_creator`, A478),
  et ses bibliothèques avec le rôle en `<select>` et ✕ pour retirer (PATCH / DELETE `memberships`, permis à
  l'administrateur par `mem_write`, filtrés par bibliothèque ET compte).
- **Bibliothèques de l'instance · n** : toutes, avec membres · administrateurs · éléments · créateur ; la rangée
  ouvre la fenêtre Membres existante (`openMembers`), qui sert aussi aux bibliothèques dont l'administrateur
  n'est pas membre (`libName` retombe sur les noms relevés, `_admLibNames`).
- Un champ « Filtrer… » au-delà de 8 rangées par carte. Confirmations reprises de l'existant (refuser, supprimer),
  « Suspendre » dit ce qu'il coûte : les adhésions sont purgées par `user_status_revoke_memberships`, il faudra
  réinviter la personne si elle est réapprouvée.
- **Serveur** (`supabase/schema.sql` § 9ter, à rejouer) : trois lectures `security definer`, VIDES pour qui n'est
  pas administrateur — `list_accounts()`, `list_user_memberships(p_user)`, `list_all_libraries()`. Aucune écriture
  neuve : les gestes passent par les fonctions et politiques existantes. Tests RLS § 15.7.
- **Serveur antérieur** : l'appel échoue, la carte dit de rejouer le schéma ; rien d'autre ne change.
- Correctif au passage : la lecture des adhésions du profil (`loadProfile`) filtre `user_id = moi` — `mem_select`
  laisse l'administrateur lire TOUTES les adhésions, il aurait vu les bibliothèques des autres comme les siennes.

Témoin : `audit-doctrine` « MOI · A478-A479, A483 » (comptes et bibliothèques listés, rangée dépliée, PATCH borné
au compte, repli sur serveur antérieur).
