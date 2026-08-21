# Journal des modifications

## [5.17.0] — 2026-08-21
### La barre de sélection tient sur une ligne (planche 20, A227-A230)

- **Une ligne, 56 px, à tout écran et dans tout état** — contre ~100 px sur téléphone.
  Le défaut n'était pas la largeur : la barre est **collante**, donc ses deux étages
  restaient à l'écran pendant tout le défilement, sur le seul axe qui manque sur
  téléphone. Et cette hauteur était payée pour rien — à l'ouverture, **quatre commandes
  sur six étaient mortes**. Le contenu est repris ; la coque (place collante, matière,
  périmètre) ne bouge pas. Le contenu remonte de 44 px, et il n'existe plus d'état où la
  barre grandit sous le doigt.
- **Les actes passent dans un tiroir** : « Actions » ouvre la feuille que « Bibliothèque… »
  et « Catégorie… » ouvraient déjà. Un tap de plus, une rangée de moins. **Rien de coché,
  rien de mort** : la touche d'actes n'est pas grisée, elle n'existe pas — la barre est
  alors trois objets sur une ligne courte. Les trois actes sont écrits **une seule fois** ;
  la feuille les rejoue, elle ne les duplique pas.
- **Les libellés disent ce qu'ils déclenchent** : « Tout » → **« Tout cocher »**, « Aucun »
  → **« Tout décocher »** (un adjectif seul n'annonce rien, et « Aucun » se lisait d'abord
  comme un compte) ; « Déplacer… » et « Ranger… » nomment désormais leur **destination** —
  **« Bibliothèque… »**, **« Catégorie… »** —, la phrase entière étant reprise dans la
  feuille et en nom accessible. Les infobulles longues disparaissent : un intitulé qui se
  suffit ne se double pas d'une infobulle.
- **Le compte porte l'état, et il ne se fait plus rogner.** Il est le seul élément
  élastique de la ligne ; c'est aussi lui qui dit pourquoi « Catégorie… » est fermée
  (« 3 cochés · deux bibliothèques ») — un `title` n'existe pas au doigt. Mesuré avant
  correctif : réduit à 47 px pour 58 nécessaires à 390 px, à zéro à 320 px. Sous 430 px la
  barre se comprime (écarts, rembourrages) ; sous 400 px le segment rejoint le tiroir —
  sauf à zéro coché, où il est la seule commande et où il n'y a pas de tiroir.
- **Le palier de dépliage est à 1200 px, pas à 560 comme l'annonçait la planche** — corrigé
  **à la mesure**, avec deux raisons : la barre dépliée réclame **757 px de largeur utile**
  (les intitulés entiers y sont pour beaucoup) et à 560 px elle n'en a que 514, d'où un
  débordement de 179 px ; et la largeur de la barre **n'est pas monotone** en largeur de
  fenêtre — à 780 px la colonne de gauche lui prend 224 px d'un coup (698 → 474 px mesurés).
  Le seuil passe par `html.zw1200`, jamais par une media query (règle 10 : une media query
  mesure le périphérique, pas la place disponible). Conséquence assumée : sur tablette et
  sur beaucoup de portables, la feuille est le régime normal.
- **Correctif de fond découvert au passage** : `syncZoomWidth()` ne se posait **qu'au
  rendu**. Une rotation, une fenêtre tirée, un clavier qui s'ouvre ne re-rendent rien — les
  paliers de largeur restaient donc ceux de la largeur précédente, indéfiniment sur un écran
  qu'on ne quitte pas. Elle se repose désormais au redimensionnement et à la rotation.
- **Accessibilité** : cibles remontées de 32 à **40 px** et corps de 11 à 13,5 px (les deux
  planchers de la règle 9 étaient abaissés ici, sur des commandes dont l'une est
  destructrice) ; le filet de « Supprimer… » passe à `--ctl-line` — `--critical-line` est un
  rose pâle à 1,4:1 qui ne tient pas 1.4.11 — le rouge restant dans l'encre et le fond
  (mesuré après correctif : filet 3,41:1 en clair, 3,33:1 en sombre) ; la croix garde son
  nom accessible entier, c'est le libellé visible qui se replie.
- **Témoin** : `audit-doctrine.mjs` mesure à 320, 390, 560, 744, 1200 et 1280 px, à zéro
  comme à plusieurs cochés — hauteur exacte, débordement nul, **un seul rang**, compte non
  tronqué, cibles ≥ 40 px, et le palier réellement franchi. Vérifié capable d'échouer : il a
  lui-même trouvé un piège de cascade (`.btn.sm{min-height:38px}`, déclarée plus bas à
  spécificité égale — 38 px mesurés là où 40 étaient écrits). Doctrine :
  `docs/decisions/lot-v5-17.md`.

## [5.16.1] — 2026-08-20
### L'invitation au dépôt parle au pluriel (addendum A225)

- **« Déposez UN PDF ou UNE image ici » se lisait comme une limite** (re-signalé après la
  v5.16.0 : « quand je drag plusieurs PDF, ça me montre "déposer un fichier ou une image" et
  un seul s'affiche ») : le singulier de la table `UP_KINDS` — écrit pour NOMMER une nature —
  servait aussi d'invitation. La fenêtre de dépôt dit désormais « Déposez **vos** PDF ou
  **vos** images ici », son sous-titre et celui des zones ajoutent « **plusieurs fichiers à
  la fois** » ; le refus, lui, garde le singulier — il désigne UN fichier fautif. Nouveau
  champ `pl` dans la table (l'invitation et le refus ne partagent plus le même mot).
- **La troncature elle-même n'a pas été reproduite** : trois sondes (sélecteur multiple, drop
  DOM, drop CDP à vrais fichiers — éditeurs de fiche ET de protocole) entrent tous les
  fichiers, comme depuis la v5.0.0. Causes résiduelles côté poste, notées dans la doctrine :
  drag depuis la barre de téléchargements ou une pile macOS (UN seul fichier porté), PDF
  > 15 Mo refusé (message de 8 s, ratable), service worker servant encore l'ancienne version.
  Addendum : `docs/decisions/lot-v5-16.md` (A225).

## [5.16.0] — 2026-08-20
### Plusieurs fichiers d'un geste, des QR lisibles de plus loin (A225-A226)

- **Importer plusieurs `.json`/`.zip` d'un seul geste** (demandé à l'usage) : le sélecteur
  comme le glisser-déposer acceptent désormais plusieurs fichiers de données, traités **en
  file** — un atelier après l'autre, jamais deux superposés, chaque atelier **nommant son
  fichier** (« nom.json » — fichier 1/3). Les questions de destination, fusion et doublons
  restent posées PAR import (l'argument de l'ancienne règle « un seul fichier », conservé
  tel quel) ; annuler un atelier n'abandonne que son fichier, les suivants se présentent
  quand même. Les refus nomment aussi leur fichier — indispensable au milieu d'une file.
  Sous le capot, `readImportFile` rend une promesse tenue à la FIN du parcours complet, et
  une erreur de lecture ne gèle plus la file (`FileReader.onerror` traité).
  Les images et les PDF, eux, acceptaient déjà le geste multiple partout (porte unique
  v5.0.0) — rien n'a changé de ce côté.
- **Tous les QR grandissent d'un cran** (demandé à l'usage : « lisibles de plus loin ») —
  la marge au-dessus du seuil de scan s'encaisse en distance et en tolérance d'angle :
  240 px en fenêtre d'appariement (56vw plafonné ; le palier < 360 px ne bouge pas, c'est
  le cas mesuré de v4.47.0 où « Arrêter le partage » passait sous la ligne de flottaison),
  et **260 px** pour les QR qui se scannent d'écran à écran (appariement direct, synchro
  optique, réponse de l'invité, aller-retour). Au passage, `audit-partage` a attrapé un
  conflit de spécificité jusque-là invisible (la règle `#shareBody` battait le plafond de
  la carte d'appariement — les deux disaient 200, le conflit ne se voyait pas) : la règle
  de la carte est scopée `#shareModal`, et le témoin « plafonné à 240 px » reste MESURÉ.
- **Vérifié** : sonde deux moteurs (sélecteur multiple, deux ateliers en file nommés,
  annulation sans cascade), `audit-qr` 9/9 (décodage réel des captures), passe d'audit
  complète 25/25 verte. Doctrine : `docs/decisions/lot-v5-16.md` (A225-A226).

## [5.15.0] — 2026-08-20
### Les barres flottantes deviennent lisibles — planches Claude Design 17 et 18 (A222-A224)

- **La nuit, la capsule et le dock se voient enfin** (planche 17, direction 1a) : la matière
  système ne tenait que 1,09:1 contre le fond sombre — les trois matières n'en faisaient
  qu'une. Elle MONTE (`#171a20` → `#333b47`) : le jour la plus sombre, la nuit la plus
  claire — dans les deux cas la plus éloignée des deux autres. Un périmètre `--sys-edge`
  (5,3:1, ombre interne de 1 px, le patron de la pastille Compte) borde carte de session,
  quai, volet et capsule ; ≥ 1200 px la capsule quitte la matière et n'est pas cerclée.
- **Ce que l'éclaircissement obligeait à déplacer, déplacé** : le creux de la touche ⏱ passe
  au token `--sys-key` (.10 jour / .14 nuit), le filet ambre de l'alarme passe à `--alarm-bd`
  (`--warn-line` le jour, `--warn-sys` la nuit — il tombait à 2,25:1), et la touche ⚡ ouverte
  prend `--sys-hi` (attrapé par `audit-a11y` : l'encre rouge tombait à 3,9:1 sur le creux
  générique). Nouveau token `--ctl-sys` : la limite d'un CONTRÔLE posé sur matière système
  tient 3:1 dans les deux thèmes (« Terminer », chips et champ du volet, touche Exercice) —
  les séparateurs gardent `--sys-line`, un séparateur n'est pas une cible.
- **Le jour, le quai projette** (planche 18/P) : son ombre vivait en dur (noir pur, aveugle au
  thème) et 6 px à 6 % ne se voyaient pas sous un tableau de posologies qui touche la barre
  (colonne 358 px, quai 362). Elle passe au token `--shadow-up`, élargie 12 px / 32 px / 26 %,
  à l'encre du thème. Aucune hauteur ne bouge. Deux pistes essayées et écartées, notées dans
  la doctrine : fondu vers l'ambiance (1,06:1, invisible), bande de flou (halo noir dans les
  coins arrondis).
- **« Démarrer la session » se détache de sa barre** (planche 18/2a) : `--act` ne tenait que
  1,68:1 contre le quai — la forme du bouton se confondait avec lui (le défaut de
  « Reprendre » v5.10.0, jamais rejoué sur le geste d'entrée). Nouveau registre
  `--act-sys:#7ab3f0` (7,2:1 clair, 5,1:1 sombre), encre `--on-sys-fill` ; libellé au corps de
  l'acte (17,5 px) sans changer le gabarit ; sous 430 px effectifs « Exercice » passe au
  glyphe seul (classe `zw430`, règle 10 — cible 44 px et `aria-label` conservés) et le geste
  gagne 62 px de piste. Le coût, nommé : le bleu du quai n'est plus le bleu de la page — déjà
  le régime des trois autres registres.
- **Témoins** : nouvelle section doctrine « QUAI · le geste d'entrée se détache de sa barre »
  (aplat ≥ 3:1 deux thèmes, périmètre nocturne ≥ 3:1, ombre montante le jour, cible du glyphe
  seul), vérifiée capable d'échouer, défaut réintroduit puis fichier restauré à l'octet.
  Doctrine complète : `docs/decisions/lot-v5-15.md` (A222-A224).

## [5.14.22] — 2026-08-19
### La file voyage avec l'invité — et le partage meurt avec sa session

- **Plus aucune action perdue à la bascule** (signalé) : ce qui n'avait pas encore été
  transmis au moment d'un passage en ligne ⇄ en direct voyageait à la poubelle — la file de
  l'invité est désormais emportée et re-poussée après la jointure (témoin de bout en bout :
  panne d'écriture, bascule, l'évènement atteint l'hôte).
- **Terminer la session termine son partage** (signalé : « l'invité se reconnecte sur
  l'ancienne session ») : le partage zombie survivait des heures et le billet de reprise de
  l'invité le ressuscitait — vieux gestes et « reprise après interruption » compris. Les
  invités lisent désormais « Le soignant a terminé la session ».
- **Sans aucun réseau, « Par l'écran » est proposé sur place** (signalé) — le direct ne peut
  pas aboutir sans Wi-Fi commun, le chemin qui marche est à un tap.
- **Après la veille, les mots justes** (signalé) : un invité perdu → « Ré-apparier — nouveau
  code » (fini le « Inviter un autre » qui faisait bizarre), et l'hôte est prévenu au réveil
  que le lien direct n'a pas survécu. En ligne, la reconnexion était déjà automatique ; en
  direct, un re-scan reste physiquement nécessaire.
- **« Renvoyer mes repères » explique le zéro** (signalé) : les coches ne remontent jamais
  par l'écran — seuls les repères datés annotent le journal de l'hôte ; le message le dit et
  donne le geste.

## [5.14.21] — 2026-08-19
### La pastille « En ligne » s'allume vraiment — le serveur refusait la question, pas la réponse

- **Corrigé pour de bon** (signalé : « en 5.14.19 elle ne s'allumait pas ») : la sonde de
  joignabilité interrogeait le serveur d'une manière qu'il refuse par principe (HEAD → 405),
  et ce refus était lu « injoignable » — pastille grise à jamais, même avec un internet
  parfait. La sonde interroge désormais en GET, et tout statut HTTP vaut « joignable » :
  c'est la joignabilité qu'on mesure, pas la santé du service. Vérifié contre la vraie
  instance, depuis un vrai navigateur.

## [5.14.20] — 2026-08-19
### L'entrée « Partager » mesure le réseau, l'invité figé se reconnecte, le départ dit le non-transmis

- **« Partager la session » choisit son mode en MESURANT** (signalé) : serveur injoignable
  mesuré → appariement direct d'emblée ; échec d'ouverture en ligne (Wi-Fi sans internet) →
  bascule automatique vers le direct avec un mot — plus jamais « vérifiez votre connexion ».
- **Invité au lien figé** : « Se reconnecter… » au menu (scanner ou saisir un nouveau code,
  l'écran figé reste intact tant qu'on n'a pas rejoint), et le retour du réseau relance le
  sondage immédiatement. La pastille « En ligne » gagne aussi une mesure au retour au premier
  plan (iOS ne tire pas toujours l'évènement réseau en PWA).
- **Quitter le partage n'avertit que s'il y a de quoi** (demandé) : file transmise → fenêtre
  habituelle ; actions en attente → le dialogue détaille ce qui serait perdu (« 2 coches,
  1 repère, 1 minuteur… ») ; chez le miroir, les repères non renvoyés — avec le geste qui les
  sauverait.

## [5.14.19] — 2026-08-19
### La pastille « En ligne » mesure vraiment — et le chrome de crise lâche les aides propres de l'invité

- **La pastille « En ligne » verdit quand le serveur répond, et seulement alors** (signalé :
  « retrouver internet ne rend pas la pastille verte — pareil en Wi-Fi sans connexion ») :
  tant que le sélecteur de mode est à l'écran, une sonde légère interroge le serveur toutes
  les 8 secondes et repeint la pastille sur place. Un Wi-Fi sans internet ne la trompe plus,
  et le retour d'internet se voit en quelques secondes, dans tous les modes.
- **Le bandeau « Vous suivez » ne suit plus l'invité sur ses propres aides** (signalé — la
  v5.14.18 avait corrigé l'entrée, pas l'en-tête) : bandeau, mot du mode, mode crise et
  bridage du scribe ne valent plus que sur la fiche réellement suivie ; retour, aller et
  chrome vérifiés par sonde dans les deux sens.

## [5.14.18] — 2026-08-18
### Les aides propres de l'invité redeviennent normales — et l'invité relaie par l'écran

- **Consulter ses propres aides pendant un partage redevient normal** (signalé) : plus de
  coches fantômes ni de bandeau de session sur une aide non démarrée — et un invité sur SON
  appareil peut démarrer ses propres sessions (le refus ne vaut plus que sur appareil sans
  trace) ; ses sessions locales n'alimentent jamais le fil de l'hôte.
- **« Montrer à un autre écran »** (signalé : « pas de bouton pour redonner le code ») :
  l'invité — miroir ou en ligne/direct — relaie la session en fontaine optique ; l'hôte
  reconnaît la session relayée, retours compris. La feuille d'émission s'adapte au rôle.
- **Le compte de participants est juste** (signalé : « 2 participants » à un seul) : la
  feuille directe comptait l'hôte avec — elle compte désormais les invités présents, comme la
  feuille en ligne.
- **La notice du mode direct dit son prérequis** (signalé) : « même Wi-Fi requis — un réseau
  local SANS internet convient (Wi-Fi d'établissement, box coupée) ».
- **Audit de sécurité du canal direct** (question) : modèle de menace écrit au registre
  (§ 3.2) — chiffrement de bout en bout authentifié par empreinte via QR physique ou relais
  authentifié, rien n'écoute, l'admission est le canal apparié, l'optique exige d'être filmé.

## [5.14.17] — 2026-08-18
### L'invité navigue sans perdre sa session — et une aide reçue ne s'exporte pas

- **Consulter ses propres aides pendant un partage ne piège plus l'invité** (signalé) : le
  menu de partage ne suit plus l'invité partout (il ne vaut que sur la fiche partagée), et
  deux chemins de retour existent — « Revenir à la session partagée » dans le menu ⋯ de toute
  autre aide, et une carte « Session partagée » / « Miroir » à l'accueil, avec Reprendre.
  Sous le capot, naviguer DÉTRUISAIT la session reçue : l'invité en ligne se reconstruit de
  son pli, le miroir optique est garé et restauré tel quel.
- **Une aide reçue temporairement ne s'exporte pas** (signalé : « c'est voulu ? » — non) : le
  miroir optique n'ayant aucun mode de transport, l'aide reçue portait le menu complet
  (Exporter, Dupliquer, Modifier). Elle porte désormais le menu de l'invité — et la réponse à
  la question : oui, l'envoi est temporaire par construction (projection en liste blanche,
  reconstruite en mémoire, jamais écrite sur l'appareil ni le compte).

## [5.14.16] — 2026-08-18
### L'aller-retour « par l'écran » — et l'instantané optique qui partait vide

- **Synchronisation par l'écran, dans les deux sens** (demandé) : l'invité qui a reçu un
  miroir peut « Renvoyer mes repères » — l'hôte tape « Recevoir en retour », filme, et son
  journal s'annote de repères datés (jamais une coche : la sémantique de la maquette 05,
  « Continuer seul » réutilisé). L'émission reprend ensuite d'elle-même, enrichie. Même
  session reconnue automatiquement ; une fontaine d'une autre session ou d'une autre aide est
  refusée sans rien écrire ; re-scanner ne duplique rien.
- **L'instantané optique partait VIDE depuis la v5.14.0** (trouvé par le nouveau témoin) : la
  fiche voyageait, les coches, minuteurs et repères jamais — le miroir montrait une session au
  propre. Corrigé (`shareSnap(Runtime,…)`).
- **La jauge ne s'affiche que pendant une fontaine** (demandé) : un scan de code unique se
  conclut par un flash vert 120 ms + vibration, sans son ni jauge (maquette 03).
- **L'émission parle comme la maquette 04** : « le code change tout seul — restez face à
  face » + « en cours d'envoi » — fini le « bloc x/x / réparation ».

## [5.14.15] — 2026-08-18
### La feuille directe a les commandes de l'hôte, la réouverture retrouve son mode

- **« Donner la main » et « Couper » existent désormais en mode direct** (signalé) : le moteur
  local savait déjà les faire, seule la feuille ne les montrait pas — les rangées de
  participants sont maintenant communes aux deux feuilles, avec les mêmes états (relève,
  conduit, parti, sans nouvelles…).
- **La pastille « En ligne » verdit quand le retour est possible** (compte + internet),
  symétrique de « En direct » = canal dormant prêt. Vert = disponible, pilule = actif.
- **Rouvrir le partage rouvre le mode EN COURS** (signalé : « le mode direct ne se rouvre
  pas ») : le menu ouvrait la feuille cloud en dur — partage fantôme sans code ni
  participants. Direct vif → feuille directe ; miroir → miroir ; sinon → cloud.
- La ligne de diagnostic (v5.14.13) est retirée : service rendu — elle a désigné le défaut
  serveur en un aller-retour.

## [5.14.14] — 2026-08-18
### Le vrai coupable du secours chaud : le serveur amputait l'offre

- **L'appariement silencieux ne pouvait fonctionner sur AUCUN réseau** (trouvé grâce à la
  ligne de diagnostic v5.14.13 : « en attente de l'offre… » à demeure) : la liste blanche des
  CLÉS de payload de `share_push` — l'étage jumeau du vocabulaire des genres — ne connaissait
  pas les clés du secours chaud : le serveur acceptait l'évènement `sig` et le vidait de son
  offre. ⚠ **`supabase/schema.sql` est à REJOUER sur l'instance** : c'est le correctif.
- **Le banc ne peut plus mentir sur ce point** : le hub local du harnais ampute désormais les
  payloads exactement comme le serveur, et `check-sql` garde la parité des clés comme celle
  des genres (39 identiques, camelCase compris) — vérifié capable d'échouer des deux côtés.

## [5.14.13] — 2026-08-18
### La feuille de l'hôte dit où l'appariement silencieux casse

- **Une ligne de diagnostic sous le sélecteur de mode** (signalé : pastille jamais verte sur le
  même Wi-Fi alors que l'appariement QR fonctionne) : « en attente de l'offre… », « offre
  reçue (n candidats) · réponse envoyée · connexion : … », « canal prêt ». Elle dit, avec ce
  que l'hôte sait, lequel des trois maillons casse — l'émission de l'offre, le rassemblement
  des candidats sans caméra (iOS), ou la résolution mDNS que certains réseaux filtrent (le
  flux QR y survit : sa réponse, créée caméra allumée, porte de vraies IP).

## [5.14.12] — 2026-08-18
### Le secours chaud survit aux rôles échangés — et la panne brutale est prouvée

- **« Canaux pas prêts » pour toujours, corrigé** (signalé : « j'ai rejoint depuis plusieurs
  minutes, toujours ce message ») : un état d'appariement périmé d'une participation
  précédente (deux téléphones qui échangent leurs rôles à chaque essai) bloquait toute
  nouvelle proposition de canal. L'ardoise est désormais remise à neuf à l'entrée de chaque
  participation — et la pastille « En direct » ne peut plus verdir sur un canal mort d'un
  ancien rôle.
- **Réponses croisées neutralisées** : quand plusieurs offres d'appariement vivent dans le
  journal, la réponse d'une offre morte pouvait empoisonner la connexion en cours (empreinte
  d'un autre pair). Chaque offre porte un jeton ; une réponse sans le bon jeton est ignorée.
- **La question « et si perte de réseau brutale ? » a sa preuve** : la section E2E du harnais
  joue désormais le cycle entier — appariement silencieux, bascule manuelle, retour en ligne,
  re-formation du secours, puis mort brutale du relais : l'hôte et l'invité se retrouvent en
  direct SANS AUCUN geste (12 témoins verts). Le canal dormant est un lien Wi-Fi local :
  la perte d'internet ne le touche pas ; seule la perte du Wi-Fi lui-même le tue (il reste
  alors « Par l'écran »), et un invité hors du réseau local ne peut pas se pré-apparier
  (pastille grise à demeure).

## [5.14.11] — 2026-08-18
### Le dialogue « Passer en direct ? » dit la bonne chose dans chaque cas

- **« Chaque participant devra scanner… » ne s'affiche plus quand personne n'a rejoint**
  (signalé : « pourquoi c'est marqué… ») : ce message confondait deux réalités. Personne n'a
  encore rejoint → il n'y a personne à emporter, le dialogue dit simplement que le code
  d'appariement s'affichera. Des participants suivent mais leurs canaux dormants ne sont pas
  prêts → le dialogue explique la pastille (grise = pas prêt, comptez quelques secondes après
  chaque arrivée), annonce le coût du « maintenant » (re-scan) et le bénéfice d'attendre la
  pastille verte (bascule sans scan) — bouton « Passer en direct quand même ».

## [5.14.10] — 2026-08-18
### La mise à jour prévient à nouveau, à coup sûr

- **Le bandeau « Nouvelle version » retrouve son bouton** (signalé : « il ne me prévient plus
  tout le temps ») : le créneau du bandeau système est partagé, et deux autres messages
  (« fiches d'exemple », « code de session reçu ») réaffectaient le bouton sans que l'écrivain
  de mise à jour ne le restaure — après un passage des autres, « Recharger » ne rechargeait
  plus. Chaque écrivain pose désormais texte ET action.
- **Une mise à jour activée app fermée n'est plus perdue** : l'annonce ne touchait que les
  pages ouvertes à l'instant de l'activation — cas raté fréquent en PWA iOS. La page interroge
  désormais le worker (guichet de version) au chargement et à chaque retour au premier plan ;
  silence complet quand les versions concordent, bandeau seulement en cas de retard réel.

## [5.14.9] — 2026-08-18
### Les bascules prouvées de bout en bout, l'invité qui re-rentre en un geste, un seul œil pour trois codes

- **Les deux sens de bascule marchent, et c'est prouvé** (signalé : « ne fonctionne pas ;
  inversement non plus ») : une section E2E du harnais joue désormais le flux COMPLET — deux
  pages réelles, un relais en mémoire, de vrais canaux WebRTC — et sa première exécution a
  reproduit l'échec du terrain. Corrigé : un échec d'appariement silencieux laissait un verrou
  posé à jamais (plus aucune tentative ensuite) — une montre de 30 s jette et retente ; les
  canaux fermés se purgent ; la fin du partage cloud est différée pour que le signal de bascule
  ait le temps d'atteindre chacun.
- **Direct → en ligne devient seamless aussi** : au tap « En ligne », chaque invité reçoit par
  le canal direct un code d'admission neuf (un par un — un code ne loge qu'une entrée) et
  rejoint le serveur tout seul. Si internet ment, personne n'est déconnecté : le partage reste
  en direct et le dit.
- **La pastille « En direct » dit l'état réel du canal dormant** (verte = prêt) : si elle ne
  verdit jamais sur votre réseau, l'appariement silencieux n'y passe pas (multicast filtré ?)
  et le parcours QR reste le chemin — le dialogue l'annonce honnêtement.
- **L'invité déconnecté re-rentre en un geste** (signalé) : « Rejoindre à nouveau… » sur
  l'écran gelé rouvre directement l'écran d'entrée — jamais proposé à un participant COUPÉ
  expressément.
- **Un seul bouton « Scanner un code »** à l'écran d'entrée (signalé) : le format décide —
  rafale optique, code d'appariement direct, ou code du partage en ligne (lien ou QR de la
  feuille de l'hôte), reconnus à la volée.
- Registre § 3.2 complété : les bascules choisies empruntent les mêmes chemins déclarés ; le
  code d'admission (opaque, huit caractères) transite par le canal direct chiffré.

## [5.14.8] — 2026-08-18
### Passer en direct ne déconnecte plus personne

- **La bascule choisie emprunte les canaux dormants** (signalé : « quand je switche en ligne →
  en direct, tous les participants sont déconnectés ») : le secours chaud pré-apparie déjà les
  canaux directs pendant que le cloud marche — le geste manuel du sélecteur les utilise
  désormais au lieu de repartir sur du QR. L'hôte prévient par le relais encore vivant
  (`sig « go »`), transite par le chemin éprouvé de la panne, et les invités re-joignent seuls
  par leur canal (trois essais espacés couvrent la course). Personne ne scanne rien.
- **Le dialogue dit le compte exact** : « les participants basculent automatiquement » si tous
  les canaux dorment, « N sur M basculent, les autres devront scanner » sinon — et l'ancien
  parcours par QR ne reste que quand aucun canal n'est prêt (premières secondes du partage).
- **Le partage en ligne est terminé proprement côté serveur** après la bascule : un invité sans
  canal dormant voit l'écran « partage terminé », pas un silence.
- Limite nommée : le sens retour (direct → en ligne) reste un re-appariement par code.

## [5.14.7] — 2026-08-18
### Le sélecteur de mode partout, dans son conteneur, en haut — et plus de cul-de-sac

- **Le sélecteur ne disparaît plus** (signalé : « parfois pas de sélecteur, et si je clique il
  disparaît ») : un seul constructeur le pose sur TOUS les états de la feuille — en ligne,
  appariement, en direct, émission optique, échec. Cliquer un cran mène toujours à un état qui
  le porte aussi ; cliquer le cran actif ne fait rien.
- **Les pastilles de la maquette 08** : point vert sur le cran actif, gris sinon, ⧗ pour
  « Par l'écran » — dans le composant segmenté canonique (pastille glissante), habillé du
  CONTENEUR du sélecteur de l'accueil (fond d'ambiance, filet, coins arrondis, pastille en
  retrait), et placé EN HAUT de la feuille, sous la notice (signalé : « en bas — ce serait
  mieux en haut »).
- **« Aucune session en cours à transmettre » n'est plus un cul-de-sac** (signalé) : la garde
  commune fait ce que fait tout le reste de l'app — session démarrée → on y va ; fiche ouverte
  sans session → « Démarrer et partager ? » ; pas de fiche du tout → le seul vrai refus, qui
  dit quoi faire (« Ouvrez d'abord l'aide cognitive à partager »).
