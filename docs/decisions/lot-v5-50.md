# Lot v5.50 — A475-A477

Les COLLECTIONS : un rangement personnel qui ne déplace rien (A475), la barre de sélection en tiroir à toute
largeur (A476), et la fenêtre « Nouvelle bibliothèque » qui demande d'abord « Avec qui ? » (A477). Audit et
maquettes : canevas « Rangement de l'accueil » (07/10/2026), piste D retenue par l'auteur.

## A475 — les collections : ranger sans déplacer (v5.50.0)

**Constat (signalé par l'auteur)** — « je crée des bibliothèques partagées pour ranger mes aides perso ». La
bibliothèque était le seul contenant nommé au-dessus de la catégorie, or elle dit QUI A ACCÈS : la détourner coûte un
espace serveur, une ligne dans Moi, et ne range ni une aide en lecture seule ni une aide à deux endroits (il fallait
la dupliquer — deux versions qui divergent).

**Décision.** Une collection est une liste nommée d'ids, PERSONNELLE : aucune copie, une aide peut être dans
plusieurs, y compris une aide en lecture seule. Le principe que chaque écran dit à sa façon : *une bibliothèque, c'est
avec qui ; une collection, c'est pour moi.*

- **Modèle** : `colls` = `[{id,name,ids}]` (50 collections, 300 ids, nom 60 car.), assaini par `sanitizeColls` à
  toute entrée ; `localStorage` par espace (`ac-colls`, dans `WIPE_SPACE_KEYS` et le transfert hors compte → compte) ;
  synchronisé dans le document PERSO (`data.colls`), à côté des épingles. Un document sans le champ (client
  antérieur) ne les efface pas ; un tableau vide, si.
- **L'Accès direct EST la première collection** (`COLL_PIN`) : mêmes cases, même filtre, mais il reste servi par
  `pins`/`togglePin` (un brouillon n'y entre pas, K5) et ses tuiles ne bougent pas.
- **Filtre** `state.coll` (`collOn`) dans les deux prédicats de liste, compté dans `filtersList` (puce « Collection :
  … »), retiré par `dropFilter`. Les tuiles d'Accès direct s'effacent dans une collection ouverte.
- **Portes** : au téléphone une rangée de puces sous l'Accès direct (absente tant qu'aucune collection n'existe) ;
  au bureau une section de la colonne gauche, avant les catégories ; une famille « Mes collections » dans la feuille
  Affichage (toujours, avec « ＋ Nouvelle collection ») ; une zone dans Moi (connecté ou non).
- **En-tête d'une collection ouverte** (`collHeadHtml`) : « COLLECTION · À VOUS SEUL », nom, « n éléments venus de k
  bibliothèques — rien n'a été déplacé », indisponibles comptés ; « Ajouter des aides » (feuille à cases sur tout
  l'accueil, filtre dès 9) et ⋯ (Renommer, Retirer les indisponibles, Supprimer — « les aides restent où elles sont »).
- **« Ajouter à une collection… »** : menu ⋯ de chaque aide et protocole (sous-ligne lue à l'ouverture : « dans
  Accès direct et Garde SMUR »), et feuille Actions de la sélection (en tête). **Active en lecture seule**, juste sous
  « Modifier » grisé : la preuve par le geste.
- **Réutilisation** : `openPickMenu` gagne `multi` (rangées `menuitemcheckbox`, la feuille reste ouverte, `onToggle`
  rend l'état, tiret = sélection rangée en partie), `done` (pied « Terminé ») et `onClose` ; `confirmDlg` gagne
  `input` (nommer, renommer) — aucune fenêtre neuve. Icône `bookmark` (le signet), distincte du livre.
- « aussi dans … » sous une rangée, seulement dans une collection ouverte.

**Formes écartées** (canevas) : dossiers (un seul endroit, profondeur sous stress), étiquettes à facettes (tout
étiqueter, recouvre la catégorie), renommer « Bibliothèque » (le nom n'était pas la cause ; « Équipe » reste le
second temps si le détournement continue), « Mon ordre » manuel (pas de glisser à l'accueil — l'ordre suit
Affichage).

## A476 — la barre de sélection : le tiroir à toute largeur (v5.50.0, applique A228)

**Mesuré** : dépliée, la barre utilisait 962 px pour 960 disponibles (la liste est bornée à 960, A389) avec quatre
actes ; « Collection… » en demande ≈ 140 de plus. **Décision de l'auteur** : A228 appliquée strictement — le palier est
celui où les libellés entiers tiennent, il n'existe plus ; « Actions ▾ » ouvre la feuille à toutes les largeurs,
« Annuler » en croix. **Refusé** : réduire « Exporter » et « Supprimer » à leur glyphe (l'audit design exige les
libellés entiers). `.sel-sep`, `.sel-lbl` et les styles d'actes dépliés purgés (règle 14) ; témoins de la planche 20
et d'A451 mis à jour.

## A477 — « Nouvelle bibliothèque » demande d'abord « Avec qui ? » (v5.50.0)

- La fenêtre dit qu'une bibliothèque sert à **partager**, et demande les personnes à inviter (e-mails, rôle) —
  invitées à la création (`inviteAll`, RPC `invite_member` existante ; échecs nommés dans le toast).
- **Personne d'invité** : une notice « une collection suffit » et l'action principale devient « Créer une
  collection » ; « Créer la bibliothèque quand même » reste. Trois boutons : la principale sur sa ligne, en tête.
- **Convertir en collection** (« Gérer la bibliothèque », admin, bibliothèque partagée avec personne) : les éléments
  passent dans Perso par le cœur du déplacement (`entsMoveLib`, factorisé de `selMoveLib` — catégories suivies par
  leur nom) et forment une collection du même nom. **Rien n'est supprimé** : la bibliothèque vide garde sa propre
  fenêtre de suppression.
- Au passage : deux écritures mortes de `state.scope` (création et suppression de bibliothèque) passent à
  `state.homeLib` (famille A303).
