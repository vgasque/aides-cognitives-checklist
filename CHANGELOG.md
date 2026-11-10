# Journal des modifications

## [5.117.0] — 2026-11-10
Le délai de revérification se règle, et le volet des minuteurs du téléphone se resserre (A698-A699). Rien à faire côté
serveur.
- **À revérifier — un délai par aide et par protocole.** Jusqu'ici, une validation de plus de deux ans s'affichait
  « À revérifier » pour tout le monde. Dans l'éditeur, sous la date de validation, on choisit maintenant « tous les
  ans », « tous les 2 ans » ou « tous les 3 ans ». Rien ne change pour l'existant : le délai reste de deux ans tant
  qu'on n'y touche pas.
- **Sur une rangée validée**, l'info-bulle dit à partir de quand l'élément sera à revérifier.
- **« À faire » liste les validations échues** de ce que vous pouvez modifier, dans une section « À revérifier —
  validation échue », avec « Ouvrir ». Ce n'est pas une tâche : la liste est calculée à l'affichage, rien n'est
  enregistré ni envoyé, et elle disparaît dès que la date de validation est mise à jour.
- **Minuteurs et compteurs au téléphone** : dans le volet de la capsule, chaque minuteur tient en une tuile plus
  basse — « ↺ maintenir » à côté du temps, une seule commande en dessous. Toucher n'importe où sur un minuteur à
  l'arrêt le lance ; un minuteur en marche ne répond qu'à son bouton « Pause ». Un compteur se lit « − n + » sur une
  ligne, avec un « + » large. Le bureau ne change pas.

## [5.116.1] — 2026-11-10
Les sept points restés ouverts de l'audit de sécurité (A689-A693, A695-A697).
**À faire côté serveur : rejouer `supabase/schema.sql`, puis redéployer la fonction `link-claim`** (dans cet ordre ;
aucun ordre n'est bloquant). `supabase/rls-tests.sql` pour vérifier.
- **Documents PDF** : un document appartient à un seul espace. Dupliquer une aide ou un protocole d'une bibliothèque
  vers Perso lui donne ses propres PDF — deux exemplaires, comptés deux fois au quota, qui vivent ensuite séparément.
  Un élément écrit par quelqu'un d'autre ne peut plus faire partir un de vos PDF personnels vers une bibliothèque. Au
  premier lancement, les copies issues d'anciennes duplications reçoivent leur exemplaire. Si un PDF n'est pas sur
  l'appareil au moment de dupliquer, la copie ne le cite pas, et le message le dit.
- **Appareil connecté temporairement** : la règle « créer, modifier » couvre aussi les catégories d'une bibliothèque,
  les notes et le suivi ; une suppression ne peut plus modifier le contenu au passage. La confirmation est désormais
  exigée par le serveur, plus seulement par l'app : passé 5 ou 15 minutes après le dernier accord, un envoi attend un
  nouvel accord (« Confirmer pour envoyer »). En usage normal, le nombre de gestes ne change pas.
- **Connexion d'un appareil** : la fonction serveur ne rend plus que l'identifiant et l'adresse du compte, et un même
  lien ne se réclame que cinq fois.
- **Aides et protocoles reçus** : un champ que l'application ne connaît pas est gardé s'il est petit, retiré s'il est
  lourd — un appareil pas encore à jour n'efface donc pas les champs d'une version plus récente.
- **Recherche dans les PDF** : l'indexation s'arrête à 5 000 pages par document, retient un document qui l'a fait
  échouer trois fois (il est alors dit illisible ; « Réindexer » le rouvre), et n'indexe jamais pendant une session.
- **Outillage** : les actions de la CI sont épinglées par empreinte.

## [5.116.0] — 2026-11-10
Invitation avec acceptation, et quotas réglables (A685-A688) — les deux derniers points de l'audit de sécurité.
**À faire côté serveur : rejouer `supabase/schema.sql`**, puis `supabase/rls-tests.sql` pour vérifier.
- **Être invité dans une bibliothèque n'y inscrit plus d'office.** L'invitation paraît dans **Moi › Bibliothèques**,
  avec le nom de la bibliothèque, le rôle proposé et l'adresse de qui invite : **Rejoindre** ou **Refuser**. Tant
  qu'elle n'est pas acceptée, rien de la bibliothèque n'arrive sur vos appareils. Une invitation nouvelle s'annonce une
  fois (jamais pendant une session).
- **Pour qui invite** : la personne paraît dans la liste des membres avec « invitation en attente » ; elle devient
  membre en acceptant. Un administrateur seulement invité ne compte pas encore comme administrateur. Le message est le
  même, qu'aucun compte n'existe à cette adresse ou qu'il ne soit pas validé.
- **Quotas** : chaque espace — l'espace personnel d'un compte, ou une bibliothèque — a une limite d'aides (2 000 par
  défaut), de protocoles (2 000) et de documents PDF (1 000) ; chaque compte, une limite de sessions enregistrées
  (5 000). Ce qui est supprimé ne compte pas.
- **Administration › Règles › Quotas** : les quatre limites se règlent là, avec leur guide — ce qui est compté, l'usage
  de l'espace le plus rempli aujourd'hui, la valeur par défaut, la plage permise, et ce qui se passe quand la limite est
  atteinte. Baisser une limite sous l'usage ne supprime rien : cela arrête les ajouts.
- **Limite atteinte** : l'élément refusé reste sur l'appareil et repartira dès qu'une place se libère ou que la limite
  est relevée ; la synchro le dit (« Quota atteint »), sans rien interrompre.
- Guide d'exploitation : `docs/deploiement-et-conformite.md` § 1.8 (lire et relever les quotas sans l'app).

## [5.115.2] — 2026-11-10
Audit de sécurité, suite : le serveur (A676-A683).
**À faire côté serveur : rejouer `supabase/schema.sql`**, puis `supabase/rls-tests.sql` pour vérifier. La fonction
`link-claim` n'a pas changé.
- **Partage en direct — régression de la v5.115.1 corrigée** : après une bascule en direct, le canal pouvait se fermer
  au bout de trente secondes ; l'invité perdait alors le lien et ne suivait plus le retour en ligne.
- **Poste partagé** : « Se déconnecter et effacer » ferme réellement la session du compte sur le serveur. Avant, un
  jeton copié sur le poste pouvait redevenir, une semaine plus tard, un accès complet au compte.
- **Aides partagées** : une modification ne peut plus être antidatée — tous les appareils la reçoivent.
- **Connexion d'un poste** : la limite de demandes ne se contourne plus, et un afflux de demandes ne bloque plus le
  déverrouillage d'un poste déjà connecté.
- **Administration** : les listes (comptes, bibliothèques, demandes) ne se lisent plus depuis un poste partagé.
- **Partage de session** : le serveur refuse toute valeur qui n'a pas la forme attendue (plus de texte libre glissé
  dans un évènement) ; un envoi refusé pour débit ne compte plus dans le quota.
- **Suivi** : l'auteur d'une note d'équipe est posé par le serveur — on ne signe plus à la place d'un collègue.
- **Identifiants** : le serveur refuse une aide ou un protocole dont l'identifiant n'a pas la forme attendue, et un nom
  de bibliothèque de plus de 120 caractères.
- **Lien `?__actest`** : sans effet sur le site publié (il donnait une application qui ne démarrait pas).
- **Outillage** : `check-vendor` compare l'empreinte de pdf.js et de jsQR à celle notée dans leur notice.
- Restent à décider : l'invitation avec acceptation et les quotas par compte (`docs/decisions/lot-v5-115-2.md`).

## [5.115.1] — 2026-11-10
Les corrections de l'audit de sécurité (A664-A675), côté application et outillage. L'audit n'a trouvé ni injection de
code (XSS), ni secret dans le dépôt, ni fuite entre bibliothèques. **Rien à rejouer côté serveur pour cette version** ;
les constats qui touchent `supabase/schema.sql` sont listés dans `docs/decisions/lot-v5-115-1.md`, en attente de décision.
- **Partage de session** : un participant au logiciel modifié ne peut plus dérégler la session des autres (minuteurs et
  coches fantômes), ni envoyer l'écran d'un autre invité vers une autre aide, ni le figer ; un participant coupé ne
  revient plus par le même canal en partage direct ; le partage direct a les mêmes plafonds que le partage en ligne.
- **Aides et protocoles reçus** (import, bibliothèque partagée) : un identifiant piégé ne rend plus une aide inouvrable
  ni son Schéma inutilisable ; une aide démesurée ne fige plus l'application au lancement.
- **Import** : un document PDF venu d'un fichier d'ailleurs ne peut plus prendre la place d'un document existant ; un
  fichier ne peut plus faire disparaître ce qu'il importe ; un fichier mal formé ne gèle plus l'onglet.
- **Poste partagé** : « Se déconnecter et effacer » retire aussi le nom de vos bibliothèques et vos rôles ; une
  connexion temporaire par e-mail interrompue avant d'être enregistrée se ferme au lieu de rester ouverte.
- **Suivi** : une note d'équipe ne s'affiche que sur un élément de sa propre bibliothèque. Une aide déplacée d'une
  bibliothèque à une autre ne montre donc plus les notes d'équipe de l'ancienne (elles restent dans « À faire »).
- **Page affichée dans un autre site** : les gestes y sont tous arrêtés, clavier compris.
- **Outillage** : les serveurs de test n'écoutent plus que sur la machine elle-même ; le jeton de la CI ne fait que lire.

## [5.115.0] — 2026-11-10
Les corrections de l'audit complet (A659-A663) : des filets de session qui ne se déclenchaient pas, des gestes qui
promettaient plus que le code, et quelques portes du serveur refermées.
**À faire côté serveur : rejouer `supabase/schema.sql`, et vérifier que le secret `APP_ORIGIN` est posé AVANT de
redéployer la fonction `link-claim`** (sans lui, la connexion par le téléphone échoue désormais — amende A650).
- **En session** : le rappel « ⚠ n étape critique en attente » s'affiche enfin (il ne pouvait jamais) ; le compte
  « x/y étapes » suit chaque coche (il restait à 0 jusqu'au rendu suivant) ; la synchro ne change plus l'écran, le
  thème ni la taille du texte pendant un soin ; l'écran reste allumé tant qu'un minuteur tourne, même en lisant un
  document ; la banderole d'alarme passe au-dessus du schéma plein écran, du moniteur et du partage ; le compte rendu
  montre aussi les compteurs et minuteurs ajoutés en cours de session.
- **Alarmes** : la permission de notification ne se demande plus au premier geste d'une session. Elle se donne dans
  **Moi › Alarmes**, où « Tester l'alarme » fait entendre et voir l'alarme. Sur Android, les notifications partent
  enfin (par le service worker).
- **Partage** : deux écrans aux horloges décalées affichent le même minuteur ; « Continuer seul » et « Arrêter le
  partage » n'attendent plus le réseau, et un « continuer seul » fait hors ligne ne se défait plus ; un invité qui
  rejoint ne voit plus un écart sur une étape cochée depuis.
- **Éditeur** : supprimer un bloc n'ajoute plus ses étapes ★ à « Ne pas oublier » ; le nom court d'un minuteur ou d'un
  compteur est enregistré ; la relecture signale un minuteur à durée nulle, une réponse ou une complication sans cible,
  un bloc sans titre ; mêmes accusés « ↶ pour annuler » à chaque suppression ; ouvrir l'éditeur sans rien changer ne
  chasse plus les versions.
- **Import** : un fichier d'IA sans état entre en Brouillon (il entrait « validé » — amende A129) et les notices disent
  vrai ; la bibliothèque de destination s'affiche ; le message dit ce qui n'a pas pu entrer.
- **Compte et poste partagé** : à la prise de garde de nuit une heure de fin est toujours proposée ; « Se déconnecter
  et effacer » refuse pendant une session et prévient de ce qui n'est pas envoyé ; erreurs de code véridiques, en
  français, et « Renvoyer le code » ; « Quitter cette bibliothèque… » ; le dernier administrateur d'une bibliothèque ne
  peut plus être retiré.
- **Données** : versions précédentes pour les protocoles ; une suppression faite ailleurs n'efface plus une
  modification locale sans archive ni avis ; le stockage de secours s'annonce ; quatre clés oubliées à l'effacement
  de l'appareil (dont les aides ouvertes récemment).
- **Recherche et texte** : « oedeme » trouve « Œdème », rangé à O ; liens `tel:` et `mailto:` dans un protocole ; une
  adresse contenant `==` ne casse plus son lien.
- **Lisibilité et impression** : textes gris de la session passés à une encre lisible ; « Continuer » ne vire plus au
  vert au survol ; imprimer depuis le thème sombre sort en encre sombre, sans le suivi d'équipe ; si l'application ne
  démarre pas, un message et « Recharger » remplacent « Chargement… ».
- **Serveur (A663)** : « Supprimer mon compte » efface de nouveau le suivi personnel ; les tables du partage ne
  s'écrivent plus en direct ; un poste partagé ne peut plus inviter ni demander une bibliothèque ; les documents
  suivent la règle « modifier » de la connexion temporaire. Droits retirés : INSERT/DELETE directs sur le partage et
  les adhésions, UPDATE direct de `user_status`.
- Détail, constats écartés et suite possible : `docs/decisions/lot-v5-115.md`.

## [5.114.1] — 2026-11-10
Le retour système ne recule plus deux fois (A657) ; un appareil déconnecté pendant une synchro n'efface plus ses aides
(A658). Rien à rejouer côté serveur.
- **Correctif** : fermer une feuille (Se repérer, une fenêtre, l'écran de démarrage) environ une seconde après une
  autre fermeture pouvait faire reculer DEUX fois quand le navigateur était lent à parcourir son historique : l'aide
  ouverte se refermait et l'on revenait à l'accueil, en pleine session. Le filet de secours d'une fermeture réagissait
  à la fermeture suivante, encore en route, et relançait un recul. Chaque filet ne veille plus que sa propre fermeture.
- C'était la cause des deux témoins d'audit qui rougissaient « de temps en temps » sous charge : `audit-doctrine`
  « aucun rognage dans les feuilles ni le panneau » (vu en CI, 390 px) et `audit-partage` « l'hôte coupe, le
  CONDUCTEUR poursuit » (passe parallèle). Aucun des deux n'est modifié.
- Garde-fou : `audit-retour.mjs` « le filet d'un parcours déjà arrivé ne relance pas le suivant (A657) », reproduction
  déterministe (rouge sur le code d'avant : trois reculs, retour à l'accueil).
- **Correctif** : un appareil connecté temporairement, déconnecté depuis un autre appareil PENDANT une synchro, pouvait
  perdre les aides de ses bibliothèques — celle d'une session en cours comprise : la synchro continuait contre un serveur
  qui ne lui répondait plus que du vide, et en concluait que les aides avaient disparu. Elle s'arrête désormais dès que
  la déconnexion est connue, et n'efface jamais rien sur la foi d'une réponse reçue après.
- Garde-fou : `audit-lier.mjs` section « 6 bis » (rouge sur le code d'avant : aide effacée) ; le contrôle « la synchro ne
  tourne plus » attend que la synchro de la connexion soit retombée.

## [5.114.0] — 2026-11-10
Un appareil déconnecté s'arrête aussitôt (A655) ; « Connecter un appareil » refait (A656). **Côté serveur : rejouer
`supabase/schema.sql`** (fonction `link_dead`, politiques `*_link_dead`), puis `supabase/rls-tests.sql`.
- **Correctif (signalé)** : un appareil déconnecté depuis un autre appareil restait utilisable — modifier, lancer des
  sessions — jusqu'au rechargement, et son accès au serveur durait jusqu'à 15 min. Désormais il l'apprend en 15 s au
  plus, le retient même rechargé, et ne fait plus que finir la session en cours puis s'effacer : créer, modifier,
  supprimer, importer et démarrer une session sont refusés, la synchro s'arrête. Le serveur lui ferme lecture et
  écriture dès la requête suivante. Des sessions qui ne peuvent plus rejoindre l'historique sont nommées (comptes
  rendus en PDF depuis « Sessions ») avant tout effacement. Une session EN COURS n'est jamais coupée — ni par la
  déconnexion, ni par l'heure de fin : elle continue, se sauvegarde, rejoint l'historique (heure de fin), puis l'appareil
  s'efface.
- **Moi › Connexions temporaires** : les appareils connectés sont listés sur place (ordinateur, tablette, téléphone),
  avec leur heure de fin, en ambre à moins d'une heure ; toucher un appareil ouvre son heure de fin en grand,
  « ＋ 1 h », « Jusqu'à » la prochaine fin de garde, et « Déconnecter et effacer ». « Mes fins de garde » y a sa rangée.
- **Le viseur** dit quoi viser et où trouver le code (« Le code n'est pas affiché ? »).
- **Confirmer, une étape à la fois** : le nombre, puis l'heure ; plus de bouton grisé ; au 2ᵉ faux nombre, « Annuler »
  devient le bouton principal. « Appareil connecté » s'affiche en vert avec « Rien ne s'ouvre devant vous ? Déconnecter ».
- Le temps restant ne dit plus « 8 h 60 ».
- Garde-fous : `rls-tests.sql` 16.18, `audit-lier.mjs` (70 contrôles, sections 3, 6 et 7 — l'heure de fin qui passe en pleine session), `tests.html`.

## [5.113.0] — 2026-11-10
Régler la connexion temporaire dans Administration (A654). **Côté serveur : rejouer `supabase/schema.sql`**
(colonne `app_settings.temp_rules`, fonctions `get_temp_rules`/`set_temp_rules`, politiques restrictives), puis
`supabase/rls-tests.sql`.
- **Administration › Règles › Connexion temporaire** : ce qu'on peut faire sur un appareil connecté temporairement,
  pour toute l'application — créer ou modifier (libre, verrou 5 min, verrou 15 min, confirmer, interdit), supprimer et
  remplacer une bibliothèque (confirmer à chaque fois, interdit), exporter (permis, interdit), durée maximale (12, 24
  ou 28 h). Les défauts sont les règles d'avant : rien ne change tant qu'on n'y touche pas. L'administration et la
  suppression du compte restent toujours interdites.
- **Le serveur applique les interdits et la durée**, tout de suite, aux appareils déjà connectés : une écriture
  interdite est refusée même hors de l'application. Les confirmations et le verrou restent faits par l'app.
- Une connexion temporaire par e-mail au-delà de la durée maximale se ramène à la dernière heure permise, et l'écran
  le dit ; la feuille « Connecter un appareil » ne propose plus d'heure au-delà.
- Garde-fous : `rls-tests.sql` 16.17, `tests.html` (règles et heures bornées), `audit-lier.mjs` section 5 (52 contrôles).

## [5.112.1] — 2026-11-10
L'accueil pendant le chargement du compte (A653). Rien à rejouer côté serveur.
- À la connexion d'un compte sur un appareil neuf, l'accueil disait « Votre bibliothèque est vide » et proposait les
  aides d'exemple le temps que les aides arrivent. Il montre maintenant « Chargement de votre compte… » et trois
  rangées qui respirent, puis le vrai contenu. Rien ne bouge si le système demande moins de mouvement ; un compte
  déjà synchronisé, ou hors ligne, s'affiche aussitôt.
- Garde-fou : `audit-doctrine.mjs`, section « Accueil · A653 ».

## [5.112.0] — 2026-11-10
Se connecter : temporaire ou permanente (A651-A652). **Côté serveur : rejouer `supabase/schema.sql`** (nouvelle
fonction `link_self`), puis `supabase/rls-tests.sql`.
- **Une carte « Se connecter »** dans Moi : ⏱ Temporaire (« jusqu'à la fin de la garde, puis tout s'efface ») ou
  ∞ Permanente (« vous restez connecté »). Rien n'est choisi d'office, au bureau comme au téléphone. « Pas encore de
  compte ? Créer un compte » a sa propre entrée.
- **Temporaire › Avec un appareil connecté** : le code à viser s'affiche dans la page (plus de fenêtre), avec trois
  étapes ; il se renouvelle seul 5 fois, puis « Afficher un nouveau code ».
- **Temporaire › Par e-mail** (nouveau) : sans appareil connecté sous la main, le code e-mail puis l'heure de fin de
  garde ouvrent une connexion temporaire — mêmes limites, même effacement, même « Appareils connectés » que par le code
  à viser. Refusée (compte non validé), elle ne reste pas ouverte.
- **« Un appareil connecté »** remplace « le téléphone » partout : on peut confirmer depuis un téléphone, une tablette
  ou un ordinateur, et connecter n'importe quel appareil temporairement (« Connecter un appareil », « Connecter
  jusqu'à 19:30 »).
- **Une fois connecté temporairement** : une seule carte dans Moi (l'heure de fin en grand, une seule sortie « Se
  déconnecter et effacer ») ; la bande de l'accueil devient neutre, ambre à l'approche de la fin, et porte
  « Déverrouiller » quand l'édition est verrouillée.
- Garde-fous : `rls-tests.sql` 16.16, `audit-lier.mjs` (46 contrôles, dont le parcours par e-mail).

## [5.111.2] — 2026-11-09
Trois défauts signalés (A649). **Côté serveur : rejouer `supabase/schema.sql`** (nouvelle fonction `link_end`).
- **La notification de mise à jour** (« Application mise à jour… ») se posait sur la barre d'onglets du téléphone
  depuis la 5.100, et sur un tiers de la largeur (trois lignes) : elle passe au-dessus de la barre, centrée, à sa
  largeur. Le bandeau « Nouvelle version disponible » n'avait pas de défaut.
- **Bibliothèques › Tout, au bureau** : les filtres Type, Bibliothèque, Catégorie et A → Z ouvraient leur menu en bas à
  gauche de l'écran ; il s'ouvre sous le bouton touché.
- **Appareils connectés** : « Se déconnecter et effacer » sur un poste partagé le retire aussitôt de la liste du
  téléphone (il y restait jusqu'à son heure de fin). La liste ouverte se met à jour au retour dans l'app.
- Garde-fous : nouveau harnais `audit-flottants.mjs`, `rls-tests.sql` 16.15.

## [5.111.1] — 2026-11-08
Aucun mot de passe sur les comptes, et des jetons de 15 min (A648). **Côté serveur : rejouer `supabase/schema.sql`.**
- **Aucun compte ne peut porter de mot de passe** : un déclencheur sur `auth.users` le refuse, à l'inscription comme à
  la modification. L'app ne se connecte que par code e-mail et par le téléphone ; sans ce refus, une session (celle
  d'un poste partagé comprise) pouvait se définir un mot de passe durable, qui survivait à la déconnexion à distance.
  Remplace le « Password Verification Attempt hook », réservé aux plans payants. Vérification après le rejeu :
  `select count(*) from auth.users where encrypted_password <> '';` doit rendre 0.
- **Jeton d'accès de 900 s** sur l'instance (réglage du tableau de bord, consigné au § 1.2 du guide de déploiement) :
  un poste révoqué garde l'accès à l'API 15 min au plus, au lieu d'1 h. Aucun effet visible dans l'app.
- `rls-tests.sql` 16.14 garde le refus des mots de passe.

## [5.111.0] — 2026-11-08
Connecter un ordinateur de service avec son téléphone (A643-A647). **Côté serveur : rejouer `supabase/schema.sql`, puis déployer la fonction `link-claim`** (`supabase functions deploy link-claim --no-verify-jwt`, cf. `docs/deploiement-et-conformite.md` § 1.2).
- **Sur l'ordinateur** (Moi › « Se connecter avec le téléphone ») : un QR et un nombre de contrôle, ni e-mail ni code
  à recopier. **Sur le téléphone** (Moi › Appareils › « Connecter un ordinateur ») : viser le QR (ou l'ouvrir avec
  l'appareil photo), toucher le nombre que montre l'écran, choisir l'heure de fin de garde, « Connecter ». L'ordinateur
  reçoit sa propre session, jamais celle du téléphone.
- **Des heures de fin de garde, pas des durées** : deux repères, 10:00 et 19:30 par défaut, réglables dans « Mes fins
  de garde » ; trois choix au plus, entre 1 h et 28 h (une garde de 24 h qui déborde passe).
- **Le poste partagé ne perd rien** : fermer le navigateur, perdre le réseau ou redémarrer ne fait rien perdre, et une
  session en cours se reprend. À l'heure de fin, il s'efface — jamais pendant une session, jamais avant que les
  sessions faites dessus aient rejoint l'historique (jusqu'à 7 jours après, même sans connexion au compte).
- **Une session en cours sur un poste partagé est sauvegardée en ligne toutes les 2 minutes** (s'il y a eu un geste) :
  si l'ordinateur ou le réseau lâche, l'historique la montre « △ Interrompue », compte rendu partiel ; la session
  terminée la remplace.
- **Appareils connectés** (téléphone) : voir les postes, les prolonger d'une heure, les déconnecter à distance.
- **Navigateur rouvert sur le poste** : consulter et reprendre restent libres ; créer, modifier et gérer redemandent
  le téléphone.
- **Caméra** : `_headers` passe à `camera=(self)` — le viseur (partage de session, connexion) marche aussi sous Chrome
  (Android, ordinateur), qui appliquait l'interdiction.
- **Ce qu'un poste partagé ne fait pas** (A647) : supprimer demande le téléphone à chaque fois ; l'administration
  (instance, membres, bibliothèques) et « Remplacer » à l'import y sont refusés ; « Supprimer mon compte » n'y apparaît
  pas ; les réglages valent pour ce poste seulement ; 15 minutes sans geste reverrouillent la modification
  (jamais une session) ; un fichier exporté y est signalé comme restant sur l'ordinateur.
- **Sécurité, revue avant publication** : deux secrets (le QR ne sert qu'au téléphone, une clé jamais affichée sert au
  poste), session du poste créée et liée par le serveur, une session de poste ne peut ni approuver ni prolonger un
  poste ni supprimer le compte, dépôt de sessions durci, plafond de demandes par machine. Un lien de connexion reçu par
  message mène au viseur, jamais droit à l'approbation ; après l'approbation, « Rien ne s'ouvre devant vous ?
  Déconnecter ». Recommandé : `APP_ORIGIN` sur la fonction, un « Password Verification Hook », des jetons plus courts.
- À savoir : sans la fonction serveur déployée, la connexion par le téléphone échoue proprement et l'e-mail reste là.

## [5.110.0] — 2026-11-08
Une image dans une liste reste dans son élément (A642). Rien à rejouer côté serveur.
- **Image dans un élément de liste** (import Notion surtout) : l'image indentée sous un élément s'affiche sous son
  texte, à sa largeur (300 px au plus), et la liste continue — la numérotation ne repart plus à 1 après l'image.
- **L'import Notion garde la place de l'image** sous l'élément qu'elle illustre.
- **Éditeur de protocole** : sur une liste qui porte une image, « Sortir l'image de la liste » la remet en bloc
  pleine largeur après la liste.
- L'image d'un élément compte comme utilisée : elle n'est plus retirée en quittant l'éditeur.
- À savoir : un appareil resté sur une version antérieure affiche cette ligne image en texte brut tant qu'il ne
  s'est pas mis à jour.

## [5.109.9] — 2026-11-08
Plus aucune fenêtre centrée pour choisir une aide, un protocole ou un document (A641). Rien à rejouer côté serveur.
- **« Voir aussi », la cible d'une complication et « Joindre un document existant »** s'ouvrent comme les autres
  choix de l'app : au bureau, une liste qui se déroule sous le bouton touché ; au téléphone, la feuille du bas.
- **Recherche dans les trois, dès le premier élément** (nom, code d'une aide, provenance d'un document) ; les groupes
  restent (« Aides » / « Protocoles », « Blocs de cette aide » d'abord pour une complication, la cible actuelle cochée).
- Rien à choisir : une notice le dit, au lieu d'ouvrir une fenêtre vide.

## [5.109.8] — 2026-11-08
Éditeur de protocole : le suivi ne disparaît plus (A636) ; mise en garde des images (A637), déroulants au bureau (A638), gras de Notion (A639), listes coupées par une image (A640). Rien à rejouer côté serveur.
- **Le volet « Suivi » de l'éditeur de protocole reste visible** : il disparaissait de la colonne de droite dès qu'on
  tapait dans le texte, et après un aller-retour « Mise en forme en direct ».
- **Texte et aperçu côte à côte** : le suivi reste en bas de page, et la pastille « n tâches » paraît dans l'en-tête
  dès qu'il y a une note ou une tâche (elle l'ouvre sans quitter sa place), comme en lecture.
- **« Une image hors texte sera retirée… »** ne s'affiche plus que s'il y a vraiment une image retirée du texte.
- **Au bureau, plus de petites fenêtres pour choisir** dans l'atelier d'import (catégorie, bibliothèque, « Dans »),
  pour l'élément lié d'une tâche, « Ajouter à une collection… » et l'Administration : une liste se déroule sous le
  bouton touché. Au téléphone, rien ne change.
- **Gras de Notion** : `****texte****` et `****titre** : suite**` s'affichent en gras.
- **Image dans une liste (import Notion)** : l'image reste un bloc à elle et ferme la liste, mais ce qui la suit
  redevient une liste au lieu de s'afficher en texte « - … ».

## [5.109.7] — 2026-11-08
Atelier d'import (A622), cases rondes et vocabulaire (A623), tâches liées (A624), échéances (A625), recherche (A626), « À faire » et menus au bureau (A627-A631), « Créer » aux Bibliothèques (A632), page Notion dans l'éditeur (A633), sélection de blocs et « Modifier » (A634-A635). Rien à rejouer côté serveur.
- **Renommer à l'import : on touche le titre** (export ZIP ou page .md de Notion). Le bouton « Renommer » de chaque
  rangée disparaît : le titre se présente comme un champ de texte (encadré gris léger, comme sur iOS), lisible en entier. Toucher le titre
  ne coche ni ne décoche la rangée ; Entrée valide, Échap annule.
- **Les cases à cocher sont rondes partout** : celles de l'atelier d'import et des fenêtres de confirmation étaient
  restées carrées.
- **« Protocole » partout** : les derniers « référence » qui désignaient un protocole (suivi, import, relecture, images)
  sont renommés ; « Références » ne désigne plus que la bibliographie.
- **Tâches « À fusionner avec » / « À confronter à »** : l'aide ou le protocole lié se choisit dans la feuille de choix
  de l'app (au téléphone, la feuille du bas ; sur ordinateur, une liste qui se déroule sous le champ ; aides et
  protocoles séparés, recherche dès 8 éléments) ; et la tâche paraît
  maintenant AUSSI dans le suivi de l'élément visé (« Liées depuis d'autres éléments »), où l'on peut la cocher.
- **Échéance passée** : une tâche en retard le dit (« △ en retard depuis le 15/11 », en ambre) et remonte en tête de sa
  priorité ; « À faire » et le catalogue le signalent aussi. Pas de notification ni d'alerte.
- **Toute fenêtre où l'on choisit une aide ou un protocole a son champ « Rechercher… »**, même avec peu d'éléments :
  tâche liée, « Ajouter » d'une collection, « Voir aussi », « Dans » de l'atelier d'import.
- **« À faire » s'ouvre en page** sur tablette et ordinateur (comme Sessions et Moi), et chaque tâche a un
  « Ouvrir › » qui mène à son aide ou à son protocole.
- **Au bureau, les menus de la barre de sélection s'ouvrent au-dessus d'elle**, et « Ajouter » d'une collection sous
  son bouton, au lieu d'un panneau en bas de l'écran. Au téléphone, rien ne change.
- **Catalogue** : « △ n à relire » ne passe plus sur le nom d'une catégorie ; une liste qui s'ouvre dans une fenêtre
  n'est plus coupée sur un écran peu haut.
- **« Créer » dans l'onglet Bibliothèques** ; créé depuis une bibliothèque, l'élément y est rangé d'office.
- **Une page Notion (.md ou .zip) s'ajoute au protocole ouvert** : déposez-la dans l'éditeur, ou « Ajouter › Page
  Notion ». Le texte va à la suite (↶ l'annule), les images suivent, le titre est repris s'il était vide.
- **Sélection de blocs à la souris** : un glisser parti du texte sélectionne du texte ; un glisser parti de la marge
  trace un cadre qui prend les blocs ; un clic ailleurs désélectionne ; « Ajouter » s'efface pendant la sélection.
- **« Modifier » s'ouvre tout de suite**, sans attendre le serveur (la vérification des droits se fait en arrière-plan).

## [5.109.6] — 2026-11-08
Sous-ligne des rangées (A621). Rien à rejouer côté serveur.
- **Le « · » ne commence plus une ligne** : quand la ligne de détails d'une aide passe à la ligne (« △ À relire »,
  pastille « Cours DESMU »…), le point reste au bout de la ligne précédente et la suivante commence au mot, sans
  décalage.

## [5.109.5] — 2026-11-08
Alignement des rangées sans catégorie (A620). Rien à rejouer côté serveur.
- **Une aide ou une référence sans catégorie ne décale plus son texte** : dans une liste où les autres rangées ont un
  point de couleur (« Ouvertes récemment », une collection…), elle garde la place du point, vide, et son titre
  s'aligne sur celui des voisines. Une liste sans aucune catégorie reste inchangée.
