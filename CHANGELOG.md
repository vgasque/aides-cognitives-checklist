# Journal des modifications

Toutes les versions notables de l'application. Format inspiré de *Keep a Changelog* ;
versionnage sémantique. La version affichée en pied de page (`APP_VERSION` dans `index.html`)
et le cache du service worker (`sw.js`) sont tenus synchronisés par `release.sh`.

## [3.1.2] — 2026-07-02
### Modifié
- Éditeur, champ « État » : l'option affiche simplement **« Brouillon »** pour une fiche
  personnelle ; la précision « (masquée aux lecteurs) » n'apparaît que si la fiche est dans une
  **bibliothèque partagée**, et le libellé se met à jour immédiatement quand on déplace la fiche
  d'une bibliothèque à l'autre.

### Corrigé
- Le choix Validée/Brouillon est désormais conservé pendant l'édition : auparavant, tout
  re-rendu du formulaire (changement de bibliothèque ou de catégorie, ajout d'étape…) le
  réinitialisait silencieusement à la valeur enregistrée.

## [3.1.1] — 2026-07-02
### Corrigé
- **Service worker** : les réponses d'erreur (404/500) et les pages interceptées par un portail
  captif Wi-Fi (hôtel, hôpital) ne sont **plus jamais mises en cache** — la copie hors-ligne de
  l'application ne peut plus être écrasée par une page cassée.
- Effacement local (« Supprimer mon compte ») : les épingles et le marqueur d'accueil sont
  désormais aussi effacés.

### Optimisé
- **Recherche plein texte** : le contenu indexé de chaque fiche est mis en cache — plus de
  re-parcours de toute la bibliothèque à chaque frappe.
- **Synchronisation** : le rapatriement (pull) est paginé — une très grosse bibliothèque arrive
  entière dès la première synchro (au lieu d'être plafonnée à 1 000 fiches par passage).
- Vignettes de la galerie chargées en différé (`loading="lazy"`), favicon ajouté.

### Nettoyé (audit de code, comportement identique)
- Gestionnaire de catégories **unifié** : l'éditeur ouvre la même fenêtre que l'accueil (avec le
  déplacement des fiches avant suppression), au lieu d'un panneau dupliqué.
- Fermeture des fenêtres (✕ / fond / Échap) factorisée (`bindModalDismiss`), suppression de code
  mort (`state.id`, alias `updateTimers`, CSS orphelin), `fileSlug` réutilise `catSlug`.

### Documentation
- `AGENTS.md` devient le fichier d'instructions **canonique**, lisible par tout outil IA
  (`CLAUDE.md` l'importe) ; il inclut un plan de navigation du monofichier.
- Docs consolidées : `docs/deploiement-et-conformite.md` regroupe kit de déploiement, statut
  non-dispositif-médical, modèles RGPD et CGU, et l'annexe « calcul de doses (écarté) »
  (5 fichiers → 1). `prompt-IA-creation-fiche.md` supprimé (doublon du prompt embarqué dans
  l'app, source unique désormais) ; `exemples/README.md` fusionné dans le README, lui-même
  allégé (le kit de déploiement n'y est plus dupliqué).

## [3.1.0] — 2026-07-02
### Ajouté
- Recherche **plein texte** : la recherche porte désormais sur tout le contenu des fiches (étapes,
  décisions, « ne pas oublier »…), pas seulement le titre et la catégorie.
- **Épinglage** de fiches en tête de bibliothèque, **synchronisé** entre les appareils d'un même
  utilisateur (par-utilisateur, via le document de catégories perso).
- **Compte-rendu de session** (chronologie horodatée, étapes réalisées, compteurs, minuteurs)
  depuis l'historique d'une fiche : **aperçu dans l'app**, puis **Imprimer** ou **Télécharger** —
  sans impression automatique ni nouvel onglet.
- **Comparaison de versions** dans la fenêtre « Versions » (ce qu'une restauration changerait).
- **Fiches liées** (« Voir aussi ») et **statut brouillon/validée** (les brouillons sont masqués
  aux lecteurs d'une bibliothèque partagée).
- **Attribution des modifications** : les fiches partagées indiquent le dernier modificateur.
- **Réglage de la taille du texte** (icône « Aa », 100/110/125 %), persistant par appareil.
- **Écran d'accueil** à la première ouverture (3 repères).
- **État de l'instance** dans l'écran Compte de l'app-admin (comptes, fiches, stockage) via la RPC
  `get_instance_stats`.
- Deuxième fiche d'exemple intégrée (« Arrêt cardiaque ») et fiches importables dans `exemples/`.
- Annonces **aria-live** (fin de minuteur, toasts) pour les lecteurs d'écran.

### Modifié
- Les `confirm()` bloquants natifs sont remplacés par une fenêtre de confirmation accessible.
- Compression des images en **WebP** (repli JPEG) — fichiers plus légers.
- Palette de catégories : 7 teintes assombries pour respecter le contraste WCAG AA.
- Cibles tactiles agrandies (boutons ≥ 44 px, navigation en mode crise).
- Fenêtre « Versions » : masquée aux lecteurs (jamais de version pour eux) et recadrée en
  bibliothèque partagée (« Récupérer ma version écrasée » — sauvegardes locales, pas un historique
  d'équipe).

### Outillage & docs
- `release.sh` (synchronise les numéros de version, vérifie syntaxe + tests ; ne committe pas),
  `CHANGELOG.md`, `CLAUDE.md`, intégration continue GitHub Actions, en-têtes de sécurité (`_headers`).
- Suite de tests étendue (`tests.html`) aux nouvelles fonctions pures.
- Tests des politiques RLS (`supabase/rls-tests.sql`) et documentation
  (statut non-dispositif-médical, kit de déploiement, modèles RGPD/CGU).

## [3.0.4] — 2026-07-01
### Ajouté
- Accessibilité des fenêtres (rôle dialog, piège de focus, Échap), libellés des minuteurs/compteurs.
- Runner de tests autonome (`tests.html`).
### Modifié
- Version du cache du service worker alignée sur `APP_VERSION`.
- Contrastes WCAG AA, cibles tactiles, `alert()` remplacés par des toasts, pagination de la bibliothèque.

## [3.0.3] — antérieur
- Validation des comptes désactivée par défaut ; correctif du statut « en attente » affiché à tort.

## [3.0.2] — antérieur
- Correctif de la pastille de synchro affichée à tort après déconnexion/suppression de compte.

## [3.0.1] — antérieur
- Nettoyage du code (doublons regroupés), garde-fou de taille SQL, correctifs de pastilles de statut,
  largeur de l'éditeur sur petit écran iOS.

## [3.0.0] — antérieur
- Synchronisation cloud (Supabase) optionnelle, multi-utilisateur, bibliothèques partagées, RLS.
