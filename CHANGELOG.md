# Journal des modifications

## [3.3.4] — 2026-07-04
### Ajouté
- **« Se déconnecter » et « Changer de compte » proposent d'effacer aussi les fiches de ce
  compte sur cet appareil.** Jusqu'ici, ni l'un ni l'autre ne touchait aux données locales
  (promesse hors-ligne : les fiches restaient visibles sans compte connecté) — de la valeur sur
  un appareil personnel, mais un vrai risque sur un appareil partagé (tablette d'équipe), où
  elles restaient lisibles par la personne suivante tant que personne d'autre ne se connectait
  à un compte différent. Une case à cocher (facultative, décochée par défaut) permet désormais
  d'effacer la copie locale du compte courant au moment de partir ; les fiches restent intactes
  dans le cloud, à re-synchroniser à la prochaine connexion. Nouvelle fonction `wipeCurrentSpace`
  — distincte de `wipeLocal` (effacement total de l'appareil, réservé à la suppression de
  compte) : seul l'espace du compte courant est effacé, les autres comptes déjà utilisés sur cet
  appareil ne sont pas touchés. Même case et mêmes boutons pour les deux actions (elles
  appellent la même fonction en interne) : proposer l'effacement seulement à l'une des deux
  aurait été redondant et propice à l'erreur.

## [3.3.3] — 2026-07-04
### Tests
- **Vérification du finding #1 de l'audit sécurité (3.3.2) : un lecteur seul ne peut pas déplacer
  une fiche partagée vers son espace perso, seul un editor/admin de la bibliothèque le peut.**
  Rejoué pour de vrai contre une instance Postgres locale (schéma + politiques RLS réels, pas
  seulement une relecture) : un viewer échoue bien (RLS -> 0 ligne, aucune modification), un
  editor réussit (fonctionnalité voulue, non-régression). Ce rejeu a mis au jour un bug dans le
  test ajouté en 3.3.2 (compte de test « gina » référencé dans `user_status` sans ligne
  `auth.users` correspondante — violation de contrainte de clé étrangère) : corrigé.
- **Découverte en marge de cette vérification :** le message de confirmation final de
  `rls-tests.sql` (`select '✅ TOUS LES TESTS RLS PASSENT'`, après le `rollback`) s'affiche même
  après l'échec d'un test — reproduit à la main en cassant délibérément une politique. Le
  `raise notice` émis en fin de bloc `do $$…$$` reste fiable (il ne s'affiche que si tout a
  réussi) ; c'est la ligne décorative qui ne l'est pas. Non corrigé dans cette version — à
  discuter avant de retoucher la structure de sécurité du fichier de tests.

## [3.3.2] — 2026-07-04
### Sécurité
- **Bibliothèque partagée : un compte non approuvé (liste d'attente/refusé) ne peut plus y être
  invité.** La validation des comptes (liste d'attente) n'était jusqu'ici câblée que sur l'espace
  perso ; un admin de bibliothèque pouvait, sans le savoir, donner un accès lecture/écriture
  immédiat à une bibliothèque d'équipe à un compte jamais validé. `invite_member()` applique
  désormais la même règle pour l'invité que pour l'espace perso ; l'écran « Gérer les membres »
  explique le refus.
### Tests
- **Bibliothèques partagées : première couverture RLS des rôles.** Aucun test ne créait jusqu'ici
  une vraie bibliothèque avec des membres pour vérifier viewer/editor/non-membre et l'étanchéité
  entre bibliothèques — c'est cette lacune qui avait laissé passer la faille ci-dessus. Ajout
  d'une section dédiée (`supabase/rls-tests.sql`), y compris une non-régression sur l'invitation
  d'un compte non approuvé.
- **`Sync._push` : la classification « fiche perso à réparer » (403 sur une fiche sans
  bibliothèque, cf. 3.3.1) est extraite en fonction pure testée** (`restErrStatus`,
  `isPersoRepairCandidate`), conformément à la règle du projet sur les fonctions pures.
### Corrigé
- **Appareil partagé, deux onglets ouverts sur deux comptes différents : un onglet resté sur
  l'ancien compte pouvait continuer d'écrire (épingles, curseur de synchro, modifications
  retenues) sous le nouvel espace actif de l'appareil**, sous l'effet d'un changement de compte
  fait dans un autre onglet. Un onglet est maintenant averti (évènement `storage` sur
  `ac-space`) et se recharge aussitôt, comme s'il venait de se connecter lui-même.
### Documentation
- Kit de déploiement : rappel que l'anti-spam de la liste d'attente n'est pas une limite de
  débit — à configurer côté Supabase (*Authentication → Rate Limits*).

## [3.3.1] — 2026-07-04
### Corrigé
- **Changement de compte : une seule fiche refusée n'immobilisait plus toute la synchro.** La
  clé primaire du cloud est globale (tous comptes confondus) : une fiche transférée entre
  comptes (export/import, qui conservait l'identifiant) était refusée par le serveur (RLS) au
  moment de la publier, et l'envoi se faisait en un seul lot — une fiche refusée bloquait alors
  indéfiniment *toute* la bibliothèque, avec un message l'attribuant à tort à des droits perdus
  sur une bibliothèque partagée. La synchro réessaie désormais fiche par fiche pour isoler la
  fautive ; une fiche personnelle ainsi bloquée est réparée automatiquement (nouvel identifiant,
  note/épingle/sessions/versions déplacées) puis repoussée. Un refus partiel n'empêche plus la
  réconciliation des bibliothèques partagées ni la synchro des catégories et des notes. Le
  message d'erreur distingue maintenant les deux causes réelles (droits partagés / identifiant
  déjà pris) sans promettre à tort que "le reste continue normalement".
- **Export / import entre comptes : identifiants régénérés.** Un fichier exporté embarque une
  empreinte (non réversible) de l'espace d'origine ; l'import ne conserve les identifiants que
  s'il provient du même espace (vraie restauration/fusion multi-appareils) — dans tous les
  autres cas, ils sont régénérés pour ne plus jamais entrer en collision avec une fiche
  possédée par un autre compte dans le cloud.
- **Compte approuvé mais synchro refusée en boucle (cas rare).** Les comptes sans ligne de
  statut connue (installations antérieures à la validation des comptes) étaient déclarés
  « Connecté » par l'app alors que la politique serveur refusait malgré tout chaque écriture.
  Alignement du schéma sur la même règle des deux côtés.
- **Appareil partagé : moins de surprises.** Le dialogue « Les emporter dans ce compte ? »
  (fiches créées avant toute connexion) liste désormais leurs titres. Les fiches créées,
  modifiées ou supprimées pendant qu'un compte était déconnecté sur l'appareil ne sont plus
  synchronisées en silence à la reconnexion : le titulaire du compte est d'abord invité à les
  reconnaître (synchroniser ou écarter et rétablir les versions du cloud).

Toutes les versions notables de l'application. Format inspiré de *Keep a Changelog* ;
versionnage sémantique. La version affichée en pied de page (`APP_VERSION` dans `index.html`)
et le cache du service worker (`sw.js`) sont tenus synchronisés par `release.sh`.

## [3.3.0] — 2026-07-04
### Ajouté
- **Espaces locaux par compte (multi-profils).** Tout le stockage local (fiches, notes
  personnelles, sessions, versions, épingles, catégories, curseur de synchro) est désormais
  cloisonné par compte : changer de compte ne mélange plus jamais deux bibliothèques, et revenir
  à un compte retrouve instantanément son cache local. L'espace suit le **dernier compte
  connecté** : une déconnexion — même forcée par un jeton révoqué — ne change rien à l'affichage
  (promesse hors-ligne intacte) ; la bascule n'a lieu qu'à la connexion d'un **autre** compte,
  par un rechargement propre. Migration **sans copie** : la base historique est attribuée à son
  propriétaire actuel, les installations existantes ne voient aucune différence. Passage
  « sans compte -> premier compte » : dialogue « Les emporter dans ce compte ? » (déplacement des
  fiches, notes, sessions et épingles). Entre deux comptes : jamais de transfert (export/import
  si besoin). Garde-fous : la synchro refuse structurellement de tourner sur l'espace d'un autre
  compte, et une bascule interrompue (app fermée au mauvais moment) est reprise au démarrage.
  Avant : les fiches de l'ancien compte restaient affichées chez le nouveau, pouvaient être
  versées dans son cloud, et les identifiants déjà synchronisés provoquaient une erreur de
  synchro permanente.
- **Bouton « Réparer l'application »** (fenêtre « Où sont mes fiches ? ») : désinscrit le
  service worker et vide ses caches (le code de l'app, pas les données) puis recharge une copie
  neuve — remède au cas « l'app semble bloquée sur une ancienne version ». Fiches, notes et
  sessions intactes (et le texte le dit).

### Corrigé
- **Suppression hors-ligne : plus de divergence entre appareils.** Supprimer une fiche en étant
  déconnecté posait une suppression locale dure, sans tombstone : la fiche restait dans le cloud
  et sur les autres appareils, définitivement. Dans l'espace d'un compte, la suppression
  hors-ligne pose désormais un tombstone « à pousser », propagé à la reconnexion. (La
  suppression dure ne subsiste que dans l'espace « sans compte », où il n'y a aucun cloud.)
- **Jauge rouge du « maintenir pour réinitialiser » enfin constante.** En mode sombre, la règle
  de survol générique (raccourci `background:`) effaçait la jauge de progression du bouton
  « Recommencer » pendant l'appui (le tap déclenche `:hover` sur mobile) — visible en clair,
  invisible en sombre. La règle exclut désormais les boutons en cours d'appui, et l'animation
  de jauge redémarre à coup sûr (reflow forcé entre deux appuis rapprochés).
- **Barre d'état iOS (heure/batterie) à jour.** iOS ne relit pas un meta `theme-color` modifié
  sur place : la balise est désormais **remplacée** (helper unique `setThemeColorMeta`). Au
  changement de thème, la barre suit immédiatement ; pendant le flash d'alarme, elle passe
  volontairement au jaune d'alerte puis est explicitement restaurée (fin d'animation + filet
  temporisé). À confirmer sur appareil réel.
- **Note personnelle : plus de saut en haut de page.** « + Ajouter » et « Terminer »
  reconstruisaient la vue et renvoyaient le défilement en haut ; la position est mémorisée et
  restaurée, et le focus de la zone de saisie est pris sans défilement.

## [3.2.5] — 2026-07-03
### Tests
- **`rls-tests.sql` : faux échec corrigé** (« ÉCHEC : un compte pending a pu écrire une note »).
  La section 5bis, ajoutée en 3.2.3, se termine en rôle propriétaire (nécessaire pour semer
  `auth.users`) ; la section 6 (notes personnelles), écrite avant elle, supposait encore le rôle
  `authenticated` — en propriétaire, la RLS est contournée par définition et le test concluait
  à tort à une faille. La section 6 rétablit désormais explicitement rôle et claims, avec un
  commentaire de garde pour les prochaines insertions de sections. Aucun changement de schéma ni
  de politique : les déploiements existants sont sains, seul le harnais de test était en cause.

## [3.2.4] — 2026-07-03
### Corrigé
- **Fenêtre Compte : zone tampon anti-mauvais-tap.** « Changer de compte » commençait 9 px sous
  « Synchroniser maintenant » — un tap légèrement trop bas déconnectait (avec la confirmation de
  la 3.2.3 en second filet). L'action fréquente est maintenant séparée des actions de compte par
  24 px d'espace inerte ; les boutons restent cliquables sur toute leur surface (44 px).
- **Icône « Aa » alignée sur la ligne de base, mesures à l'appui.** Le viewBox gardait 1,4 px de
  vide sous les lettres : tout recentrage du cadre laissait les « A » trop bas. ViewBox recadré
  au ras du dessin, puis bas des « A » calé sur la ligne de base réelle du texte voisin
  (métriques de police vérifiées au pixel dans le navigateur) ; calibration documentée dans le
  CSS pour éviter les futurs ajustements à l'aveugle.

## [3.2.3] — 2026-07-03
### Corrigé
- **« Ma version écrasée » fonctionne enfin dans le cas courant.** La sauvegarde locale n'était
  créée qu'en cas de conflit (modification locale non poussée) : une fiche partagée mise à jour
  par un collègue remplaçait votre copie sans rien archiver. La version locale est désormais
  archivée à **chaque** remplacement par une version distante (5 versions max par fiche).
- **Déconnexions intempestives.** (1) `Auth.refresh()` est désormais *single-flight* : deux
  rafraîchissements simultanés du jeton (synchro de démarrage + fenêtre Compte + « Synchroniser
  maintenant ») partaient avec le même refresh token — GoTrue rejetait le second (« déjà
  utilisé ») et déconnectait. (2) « Changer de compte », voisin de « Synchroniser maintenant »,
  déconnectait instantanément sans confirmation : il en demande une désormais.
- **Journal des actions** : valider un horaire sans le changer n'affiche plus de fausse mention
  « à l'origine HH:MM:SS » (posée pour un simple écart de millisecondes).
- **Bibliothèque partagée vide** : le texte s'adapte aux droits — un lecteur voit « Cette
  bibliothèque partagée est vide. » au lieu de l'appel à « créer votre première aide cognitive ».
- **Icône « Aa »** recentrée d'un pixel supplémentaire.

### Modifié
- **Import : destination explicite.** Perso par défaut ; si une bibliothèque partagée éditable
  est sélectionnée, l'app demande où importer (publier à l'équipe n'est jamais silencieux).
  Les catégories importées rejoignent le jeu de la bibliothèque de destination, « REMPLACER »
  ne touche plus que la destination (avant : toutes les bibliothèques !), l'app bascule sur la
  destination et le toast la nomme.
- **Déplacement de fiche entre bibliothèques : confirmations.** Sortir une fiche d'une
  bibliothèque partagée prévient que les membres perdront l'accès à la fiche et à leurs notes
  personnelles ; la déplacer vers une bibliothèque partagée confirme la publication à l'équipe.
- **« dernière modification par … »** remplace « modifiée par … » sur les fiches partagées
  (l'ancien libellé laissait croire à un auteur unique de la fiche).
- **« Synchroniser maintenant » laisse la fenêtre ouverte** : la ligne d'état au-dessus montre
  « Synchro en cours » puis le résultat — un vrai retour, au lieu d'une fermeture muette.
- **« Reprendre »** remplace « Ouvrir » pour les sessions (bandeau d'accueil et historique) :
  le bouton recharge l'état complet (étapes, minuteurs, compteurs), pas une simple ouverture.
- **Rappel de session dans l'en-tête** : « MODE CRISE · ● session en cours » (point pulsé),
  visible en permanence pendant une session — sans recolorer l'en-tête ni exposer de bouton
  « Terminer » en zone de tap fréquente (action destructrice = jamais rendue plus accessible).
- **Suppression de compte : avertissement « seul administrateur »** — si vous êtes l'unique
  admin de bibliothèques partagées, l'écran vous invite à nommer un remplaçant avant de partir
  (sinon seul l'administrateur de l'instance pourra en gérer les membres). Non bloquant.

### Serveur (à rejouer dans Supabase : `schema.sql` puis `rls-tests.sql`)
- **Anti-spam de la liste d'attente** : un compte n'entre dans `user_status` (« Comptes en
  attente ») qu'une fois son e-mail **vérifié** (code OTP saisi). Avant, demander un code
  suffisait : n'importe qui pouvait remplir la liste de fausses adresses, approuvables par
  erreur. La migration du script ignore les e-mails non vérifiés (un rejeu ne les ressuscite
  pas) et un nettoyage purge les inscriptions fantômes existantes. Test RLS ajouté (5bis).

## [3.2.2] — 2026-07-03
### Corrigé
- **Anti double-clic sur tout le parcours compte.** Les boutons « Recevoir le code »,
  « Valider » (connexion) et ceux de la suppression de compte (envoi, renvoi, suppression)
  se désactivent pendant l'appel réseau avec un libellé d'attente (« Envoi du code… »,
  « Vérification… », « Suppression… ») et se réactivent en cas d'échec. Un double clic
  envoyait deux requêtes : le 2ᵉ code OTP invalidait le 1ᵉʳ reçu par e-mail (« Code invalide »
  incompréhensible) et GoTrue rate-limitait l'envoi. Le champ SUPPRIMER ne peut plus réactiver
  le bouton au milieu d'une requête.
- **La fenêtre Compte dit la vérité sur la synchro.** « Synchronisation active » était codé en
  dur alors que le pied de page affichait « Hors-ligne » ou « Erreur de synchro ». La ligne
  d'état de la fenêtre reflète désormais exactement le même état que la pastille (source
  unique `_syncUi` posée par setSyncChip — aucune logique dupliquée), mise à jour en direct
  si la fenêtre est ouverte quand l'état change.

### Modifié
- **Hors-ligne dit clairement son nom.** Tenter de se connecter/s'inscrire (ou de recevoir un
  code de suppression) sans réseau affiche « Hors ligne : une connexion Internet est
  nécessaire… » avant tout appel, au lieu d'un échec réseau cryptique. Le bouton
  « Synchroniser maintenant » est grisé hors-ligne — légitime ici car la ligne d'état juste
  au-dessus explique pourquoi, et il se réactive en direct au retour du réseau ; les boutons
  de connexion, eux, restent actifs (pas d'indicateur réseau sur cet écran : un clic → message
  vaut mieux qu'un bouton grisé inexpliqué).
- **Suppression de compte : le processus est annoncé avant le bouton.** Le texte explique
  désormais « Par sécurité, votre identité doit être vérifiée : un code de confirmation vous
  sera envoyé à votre-adresse@… » — le bouton « Recevoir le code de confirmation » n'introduit
  plus le concept de code sans prévenir, et l'utilisateur sait quelle boîte mail surveiller.

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
