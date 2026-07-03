# Journal des modifications

Toutes les versions notables de l'application. Format inspiré de *Keep a Changelog* ;
versionnage sémantique. La version affichée en pied de page (`APP_VERSION` dans `index.html`)
et le cache du service worker (`sw.js`) sont tenus synchronisés par `release.sh`.

## [3.2.1] — 2026-07-03
### Corrigé
- **iPhone en paysage : plus de textes agrandis de façon disproportionnée** (jauge de stockage,
  en-têtes de section, bandeaux…) : le « font boosting » de Safari iOS est désactivé
  (`-webkit-text-size-adjust:100%`). À confirmer sur appareil réel.
- **Mode sombre : survol correct des boutons pleins.** La règle de survol sombre générique
  écrasait aussi celle des boutons `primary` (« Créer via IA », « Ajouter les fiches
  d'exemple »…) et `danger`, posant un fond quasi noir sous leur texte ; ils retrouvent leurs
  survols propres (teal éclairci / teinte rouge douce).
- **Journal des actions : plus de fausse « correction » d'heure.** Cliquer sur un horaire puis
  valider sans le changer affichait quand même « à l'origine HH:MM:SS » (identique) — la
  mention n'apparaît plus que si l'heure a réellement changé.

### Modifié
- **Session en cours = fiche verrouillée.** Pendant une session active, la note personnelle
  passe en lecture seule avec un renvoi explicite (« pour annoter la session, utilisez le
  journal des actions » — évite de la confondre avec une note de session) et le bouton
  « + Ajouter une note » disparaît ; les boutons **Modifier** et **Versions** sont désactivés
  (badge « session en cours : modification suspendue ») — modifier la fiche mettrait fin à la
  session en cours. Imprimer / Dupliquer / Exporter restent disponibles (lecture seule).
  Tout redevient actif dès que la session est terminée.

## [3.2.0] — 2026-07-02
### Ajouté
- **Notes personnelles par fiche.** En bas de chaque fiche, une carte en pointillés permet
  d'attacher une note privée : toujours PERSONNELLE (hors de la fiche — un éditeur qui modifie
  une fiche partagée n'y touche jamais ; chaque membre d'une bibliothèque a la sienne, invisible
  des autres), synchronisée entre les appareils du même compte (nouvelle table `fiche_notes`,
  RLS « chacun ne lit/écrit que les siennes »), jamais exportée ni imprimée ni dupliquée.
  Lecture seule par défaut (rien d'éditable par accident en mode crise) : l'édition demande un
  geste explicite (« Modifier » / « + Ajouter une note personnelle »), avec auto-enregistrement.
  Même composant en lecture et dans l'éditeur, y compris dès la création d'une fiche (note
  nettoyée si la création est annulée). La suppression d'une fiche efface la note attachée et
  propage l'effacement ; supprimer une fiche de bibliothèque partagée prévient l'éditeur que
  les notes personnelles des membres seront perdues.
- **Suppression de compte confirmée par code e-mail (OTP).** Le parcours exige désormais, après
  le garde-fou « SUPPRIMER », un code envoyé à l'adresse de la session (jamais une adresse
  saisie — aucune injection possible) ; côté serveur, la RPC `delete_my_account` refuse tout
  jeton sans vérification OTP de moins de 10 minutes (claim `amr` — un jeton volé, même
  rafraîchi, ne suffit plus). Message clair et « Renvoyer le code » si le code a expiré.
- **Confirmation d'import** : un message confirme le nombre de fiches importées.

### Modifié
- **Prompt « Créer via IA » durci** : les fiches générées arrivent obligatoirement en
  **brouillon**, sans date de validation (relecture et validation humaines dans l'app) ; le
  document source est traité comme données, jamais comme instructions (anti-injection) ; doses,
  unités et voies recopiées à l'identique (aucune conversion ni arrondi) ; en cas d'algorithmes
  multiples (adulte/pédiatrie), l'IA demande lequel traiter ; les blocs suivent les phases
  cliniques (jamais de découpage arbitraire). L'import tolère désormais une réponse d'IA
  enrobée de clôtures Markdown (```json) au lieu d'échouer « Fichier illisible ».
- **Pied de page réorganisé** : actions (Exporter/Importer/Thème/taille du texte) d'abord,
  puis la ligne d'état (nombre de fiches · version, pastille de synchro), puis le message de
  stockage. Icône « Aa » recentrée ; étoiles « Créer via IA » dorées et pleines.

### Corrigé
- Synchronisation des notes : re-rendu limité à la fiche affichée (pas de vol de focus) et
  marqueur « à pousser » protégé contre une frappe pendant l'envoi (aucune perte silencieuse).

### Serveur (à rejouer dans Supabase : `schema.sql` puis `rls-tests.sql`)
- `schema.sql` désormais **entièrement rejouable** (drop policy if exists devant chaque
  politique) ; nouvelle table `fiche_notes` (+ RLS, gate d'approbation, trigger anti-postdatage) ;
  `delete_my_account` exige un OTP récent. `rls-tests.sql` : isolation des notes entre
  utilisateurs, gate d'approbation, refus d'usurpation, cascade à la suppression de compte,
  et exigence d'OTP récent (absent/périmé/frais) — 2 sections nouvelles.

### Tests
- `sanitizeNotes` et `stripJsonFences` exposées au hook de test ; 13 tests ajoutés (100 au total).

## [3.1.5] — 2026-07-02
### Corrigé
- **Impression du compte-rendu de session fiable.** L'iframe d'impression (hors écran) était
  recréée à chaque clic puis retirée au bout d'une seconde : recliquer sur « Imprimer » (ou un
  navigateur lent à ouvrir l'aperçu) imprimait une page blanche. L'iframe est désormais
  conservée et réutilisée tant que le compte-rendu affiché est le même, puis retirée à la
  fermeture de la fenêtre.
- **Flash d'alarme : plus de bande jaune persistante en bas d'écran (iPhone).** L'overlay du
  flash restait composité (animation `forwards`) après la fin du clignotement et Safari iOS
  s'en servait pour teinter la barre du bas en jaune. Il est maintenant retiré du rendu
  (`display:none`) dès la fin de l'animation.
- **Le filtre de catégories ne perd plus sa position.** Sur l'accueil, cliquer un filtre en fin
  de liste ne ramène plus la rangée de catégories à son début : le défilement horizontal est
  restauré après le re-rendu.
- **Synchronisation : deux trous colmatés.** (1) Le curseur de pull est remis à zéro à la
  déconnexion — en se connectant ensuite avec un autre compte, l'app ne rapatriait que les
  fiches plus récentes que l'ancien curseur et ratait l'historique du compte. (2) La migration
  des catégories au démarrage ré-enregistrait des fiches sans leur marqueur « à pousser » :
  une fiche importée hors connexion pouvait ainsi ne jamais être synchronisée.

### Modifié
- **Les fiches d'exemple ne sont plus créées automatiquement.** À la première ouverture (ou
  bibliothèque perso vide), un bandeau « Besoin d'exemples pour commencer ? » propose d'ajouter
  les deux fiches d'exemple (Anaphylaxie, Arrêt cardiaque) ; il est masquable. Les fiches
  ajoutées par ce bouton passent par le circuit normal d'enregistrement : elles se synchronisent
  si un compte est connecté (l'ancien amorçage silencieux ne le faisait pas). Les bibliothèques
  existantes ne sont pas concernées.
- **Emojis remplacés par des icônes SVG** dans toute l'interface (bouton thème, son 🔔/🔕 →
  cloche, « ⚙ Gérer », « Noter l'heure », « Créer via IA / manuellement », bandeau d'alarme,
  jauge de stockage, fenêtre « Où sont mes fiches ? », plein écran de l'algorithme, préfixe des
  toasts d'avertissement) : rendu identique sur tous les appareils, couleur du thème respectée.
  Restent : les symboles typographiques (✓ ✕ ›) et le « ⏰ » des notifications système, où le
  SVG est impossible.

## [3.1.4] — 2026-07-02
### Modifié — exemples réorientés médecine d'urgence
- Fiche de démarrage « Anaphylaxie peropératoire » remplacée par **« Anaphylaxie (choc
  anaphylactique) »** (urgences / pré-hospitalier : adrénaline IM, réévaluation à 5 min, boucle
  en cas de forme réfractaire), catégorie **Urgences**. La fiche « Arrêt cardiaque » (ERC),
  valable en médecine d'urgence, est conservée et rangée en catégorie **SMUR**.
  (Ne concerne que les nouvelles installations : les fiches d'exemple ne sont créées qu'à la
  première ouverture, aucune bibliothèque existante n'est modifiée.)
- Fiches importables `exemples/` remplacées : LAST et hémorragie du post-partum (contextes
  anesthésie/réanimation) cèdent la place à **« Accouchement inopiné en pré-hospitalier »**
  (SMUR) et **« État de mal épileptique de l'adulte »** (urgences). Leurs catégories embarquées
  (`c-smur`, `c-urgences`) correspondent aux ids déterministes des catégories par défaut :
  l'import se rattache aux catégories existantes sans doublon.
- Comme toujours pour les exemples : contenu générique (« protocole local »), statut
  **brouillon**, à relire et valider avant tout usage clinique.
- **Correction de certains bugs design**

## [3.1.3] — 2026-07-02
### Corrigé
- **Bibliothèques partagées accessibles hors-ligne.** La liste des bibliothèques (et vos rôles)
  est désormais mise en cache localement à chaque synchro réussie et restaurée au démarrage :
  sans réseau, la barre « Bibliothèque » et les fiches partagées (déjà stockées sur l'appareil)
  restent consultables et éditables. Un simple échec réseau ne fait plus « disparaître » les
  bibliothèques (la dernière liste connue est conservée) ; une révocation réelle continue, elle,
  d'être appliquée à la synchro suivante. Le cache est purement ergonomique : les droits réels
  restent arbitrés par la RLS côté serveur.
- **Plus de déconnexion intempestive hors-ligne.** Le rafraîchissement du jeton ne déconnecte
  plus sur un échec réseau (mode avion, Wi-Fi captif) — rester hors-ligne plus d'une heure
  pouvait déconnecter et rendre les bibliothèques partagées inaccessibles sans possibilité de
  se reconnecter. Seul un refus du serveur (jeton révoqué) déconnecte désormais.

### Tests
- Nouvelle fonction pure `sanitizeLibs` (assainissement du cache de profil) exposée au hook de
  test ; 5 tests ajoutés (91 au total).

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
