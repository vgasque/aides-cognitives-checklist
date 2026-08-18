# Journal des modifications

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

## [5.14.6] — 2026-08-18
### Le sélecteur de mode est LE segmenté de l'application — pas une imitation

- Le sélecteur « En ligne · En direct · Par l'écran » utilise désormais le composant segmenté
  CANONIQUE de l'application (`.seg`/`.seg-pill`/`.seg-btn` — celui de « Créer » et de la
  bascule d'affichage) : pastille glissante sur trois pistes égales, registre
  `--primary-soft`/`--primary-dk`, cibles 44 px. Les deux tentatives intermédiaires (boutons
  bordés de `.statuseg`, puis un conteneur-pilule maison) sont SUPPRIMÉES — le design system
  existait, il suffisait de le réutiliser (signalé à l'usage, capture à l'appui). La légende
  dit la raison quand un cran est indisponible (« “En ligne” reviendra avec internet »).
- Vérifié à la capture contre la maquette 08 : ligne d'état à point pulsant, segmenté à
  pastille, légende, actions empilées pleine largeur.

## [5.14.5] — 2026-08-18
### Le secours chaud : internet tombe, le partage ne s'en aperçoit presque pas

- **La bascule automatique en ligne → en direct existe** (M9 de l'étude). Pendant qu'un partage
  en ligne fonctionne, l'invité propose EN SILENCE un canal direct (évènement `sig` par le
  relais — l'offre compacte de ~130 octets), l'hôte répond par le même chemin, et le canal
  s'ouvre puis DORT. Si le sondage échoue (~10 s de panne), l'hôte rejoue automatiquement le
  geste manuel déjà éprouvé — le diff initial rembobine tout l'état dans le hub local — et sert
  les canaux dormants ; l'invité re-joint par son canal et reconstruit son pli : AUCUNE fusion,
  aucun geste, l'écran annonce d'une phrase et le quai passe à « ● Direct ».
- **Le retour au cloud reste un tap** (segmenté « En ligne ») : le sens PANNE est automatique,
  le sens confort reste un choix — automatisable plus tard si l'usage le réclame.
- **`sig` est de la plomberie, et trois garde-fous le savent** : émissible par les deux rôles
  (parité client/serveur vérifiée par check-sql, 20 capacités), ignoré par le pli donc par le
  journal et le compte-rendu (témoin), régime d'application `none` (le témoin « tout genre est
  classé » l'a exigé). Le registre § 3.2 dit ce qui transite désormais par le relais pendant la
  préparation (descripteurs du canal, dont des adresses IP locales — purgés comme le reste).
- **⚠ `supabase/schema.sql` est À REJOUER sur l'instance** (le serveur doit accepter le genre
  `sig`) : sans ce rejeu, le secours chaud ne s'amorce pas — et rien d'autre ne change.
- Maquette 08 complétée au passage : le sélecteur de mode porte ses SOUS-MOTS
  (continu/ponctuel, ou la raison d'une indisponibilité) et la légende « l'app choisit seule —
  forcer si besoin ».

## [5.14.4] — 2026-08-18
### Le code du partage en ligne revient, et les feuilles collent enfin aux maquettes

- **Le code du partage en ligne avait disparu — trouvé et corrigé** : un essai « en direct »
  remplaçait la couture réseau du partage et ne la rendait JAMAIS — tout partage en ligne
  suivant passait en silence par le canal local (ouverture locale → pas de code → « la porte
  est fermée »). La couture d'origine est mémorisée et RESTAURÉE sur tout chemin cloud
  (héberger comme rejoindre par code).
- **Conformité aux maquettes, vérifiée capture contre capture cette fois** (03 et 07 côte à
  côte avec l'app) : notices fines d'une ligne aux mots exacts (« ⚠ Pas d'internet — partage
  en direct »), QR dans sa carte bordée, légende « l'invité scanne, puis vous scannez sa
  réponse », **boutons empilés pleine largeur** (primaire → neutre → fantôme) au lieu des
  rangées.
- **L'échec d'appariement suit la maquette 07** : « ⚠ Ça n'a pas abouti » + trois sorties,
  toujours les mêmes, toujours dans cet ordre — Réessayer (tout à neuf), Par l'écran,
  Continuer sans partage. Jamais un code d'erreur.
- **Plus d'autofocus du champ code** à l'ouverture de « Rejoindre une session » : sur mobile
  il levait le clavier d'office, alors que taper un code n'est plus le seul chemin.

## [5.14.3] — 2026-08-18
### Les écrans du partage rejoignent les maquettes — captures à l'appui

Reprise design complète contre les maquettes figées « Partage sans effort » (signalé à
l'usage : « tu n'as pas du tout respecté les mockups »), chaque état vérifié par capture :

- **L'écran de scan est PLEIN ÉCRAN** (maquettes 03b/04b) : la caméra est la surface, cadre de
  visée à quatre coins, consigne en quatre mots (« Visez le code de l'hôte »), **flash vert
  240 ms + vibration** à la lecture, « Annuler » toujours au même endroit. Les quatre scans
  (réponse hôte, offre invité, réception optique, mise à jour du miroir) partagent ce seul
  composant. Piège payé : `hidden` n'est pas une propriété des éléments SVG — la jauge restait
  invisible ; par attribut, toujours.
- **La réception optique a sa JAUGE ANNEAU** qui ne fait que monter, pourcentage au centre —
  transition de peinture seule, éteinte sous `prefers-reduced-motion`.
- **Le sélecteur segmenté « Mode »** (maquette 08) remplace les boutons « Passer en… » dans
  les deux feuilles : En ligne · En direct · Par l'écran, l'actif marqué, l'indisponible grisé
  avec sa raison dans la ligne d'aide (« “En ligne” reviendra avec internet »).
- **La ligne d'état à point pulsant** (« ● 2 participants · en direct ») — pulsation d'opacité
  2 s, le cliquet `pointer-events:none` monté à 20 pour le flash (décision motivée dans
  check-anim, A68/4).
- **Le refus d'autorisation suit la maquette 05** : « ⚠ Caméra non autorisée » + UN bouton qui
  répare (« Autoriser la caméra ») + « Continuer sans partage », partout.
- **Le mot du quai** (maquette 02) : en partage local, « ● Session » devient « ● Direct » —
  un seul mot change, à position constante, dans le budget ECAM des 18 caractères.
- **« Rejoindre une session » existe aussi SANS sidebar** (signalé : rien sur
  tablette/smartphone) : en bas de la page d'accueil, voie étroite du pied de page — le patron
  exact de « Historique des sessions », masqué en large où la sidebar prend le relais.
- Restes nommés, non couverts et dits : le fondu croisé du mot du quai (le texte se repeint
  sans fondu), l'écran de reprise « La session n'a rien perdu. » (09a), le badge « hors
  ligne · HH:MM » au journal (09b), et le fondu entre codes optiques — écarté SCIEMMENT : la
  netteté des trames prime pour le décodeur d'en face.

## [5.14.2] — 2026-08-18
### Le partage en direct remis d'aplomb — neuf défauts d'usage, signalés et corrigés

Premier passage en conditions réelles de la v5.14.0 (merci au rapporteur) — neuf corrections :

- **L'invité peut enfin arriver hors ligne** : le menu de l'accueil gagne « Rejoindre une
  session » — c'est cet écran qui porte « Scanner le code de l'hôte » et « Recevoir par
  l'écran ». Avant, il n'était joignable que par un code tapé ou un lien, donc par internet.
- **Les feuilles locales suivent les maquettes** : notices registre (glyphe + mot sur fond
  doux), QR cadré et plafonné à 200 px comme la feuille en ligne, rangées de boutons à
  gouttière, légendes courtes — fini le « barbouilli ».
- **La caméra est bornée** (tablette : la fenêtre photo débordait du cadre) : ratio 3/4,
  largeur maximale, jamais une hauteur en vh.
- **« Arrêter le partage » arrête vraiment** : la feuille « en direct » ne s'affiche plus que
  si le partage l'est (garde d'état) — plus de fenêtre fantôme à la réouverture.
- **« Scanner le code de l'hôte » ne reste plus grisé** : chaque ouverture de l'écran d'entrée
  repart d'un état propre (caméra coupée, boutons rendus, vidéos cachées).
- **« Passer en direct » ne demande plus deux clics** : le minuteur de re-rendu de la feuille
  en ligne repeignait par-dessus la feuille locale — il est coupé avant chaque bascule, et
  l'émission « par l'écran » fait de même.
- **Un partage en direct actif se ré-affiche** au tap sur « Partager », il ne se re-crée pas
  par-dessus lui-même.
- **« Par l'écran » est joignable de partout côté hôte** : depuis la feuille en ligne aussi
  (l'émission optique est additive, elle marche sans aucun réseau), avec retour à la bonne
  feuille à l'arrêt.
- **Le miroir n'est plus un cul-de-sac** : sa feuille (tap sur « Partager ») affiche « vue à
  HH:MM » et porte « Recevoir une mise à jour ». La passation par l'écran, elle, reste une
  limite écrite (§ 3.2) : le retour invité→hôte est un chantier nommé, pas un oubli.

## [5.14.1] — 2026-08-17
### Le clavier de l'accueil revient — le champ ne se tue plus lui-même

- **Depuis la v5.13.4, taper le champ de recherche de l'accueil n'ouvrait plus le clavier sur
  téléphone et tablette** (signalé à l'usage). La cause : « pendant la frappe, l'en-tête
  s'efface » (`html.kbd header.bar{display:none}`) avait été conçu pour la recherche des
  RÉFÉRENCES, dont le champ vit dans la colonne — mais le champ de l'accueil vit DANS
  l'en-tête. Le clavier s'ouvrait, l'en-tête disparaissait, **le champ qu'on venait de toucher
  était détruit avec lui**, le focus tombait, le clavier se refermait aussitôt : le champ se
  tuait lui-même, en une fraction de seconde, et aucune mesure du harnais ne pouvait le voir
  (il ne pilote pas le clavier).
- **La règle devient : l'en-tête ne s'efface que si le champ actif vit AILLEURS.** Quand le
  champ focalisé est dans l'en-tête, c'est LUI le chrome de frappe — il reste. C'est le
  principe même de la 5.13.4 (« un seul chrome à la fois ») appliqué dans les deux sens. La
  recherche des références garde son plein-écran de frappe, l'accueil retrouve son clavier.
- Un seul poseur de `html.kbd`, vérifié : `body.kb-open` (l'effacement du dock au focus) est
  une autre classe, un autre mécanisme — les deux ne se marchent pas dessus.

## [5.14.0] — 2026-08-17
### Le partage sans serveur — en direct sur le réseau local, ou par la lumière de l'écran

Le partage de session ne dépend plus d'internet. Trois canaux, un seul geste (« Partager ») :

- **En direct (nouveau).** Sans compte ou sans internet, la feuille de partage affiche un code
  QR d'appariement : l'invité le scanne (« Rejoindre une session » → « Scanner le code de
  l'hôte »), montre sa réponse, et les deux appareils dialoguent **directement sur le réseau
  local** — un Wi-Fi commun suffit, même sans internet, sans serveur, pas même un STUN (validé
  sur iPhones réels : appariement ~10 s, une fiche de 2 Mio en 0,3 s). L'appareil de l'hôte
  tient l'autorité que le serveur tenait : numérotation, attribution par secret, rôles — le
  même vocabulaire fermé voyage, jamais un texte libre. Multi-invités par « Inviter un autre » ;
  une réponse d'un appariement précédent est refusée à voix haute (jeton).
- **Par l'écran (nouveau).** Sans AUCUN réseau, un instantané daté de la session passe par la
  lumière : l'hôte affiche une boucle de codes (code fontaine systématique, trames binaires
  auto-descriptives — ~20 Kio en ~4 s mesurés), l'autre appareil filme, la jauge ne descend
  jamais, et son écran devient un **miroir daté** (« Vue à 14:02 — miroir, pas du direct »).
  L'instantané porte l'identité de session — une émission qui n'est pas la session attendue est
  refusée avec un message, **zéro écriture** — et l'heure d'émission de l'hôte, qui rattrape
  des horloges décalées de plusieurs minutes à quelques secondes près.
- **Bascule dite d'avance.** « Passer en direct… » depuis la feuille en ligne, « Passer en
  ligne… » depuis la feuille locale : toujours un ré-appariement propre annoncé par un dialogue
  (les participants re-scannent, la session de l'hôte ne bouge pas) — jamais de migration à
  chaud. Le quai n'a rien eu à apprendre : « figé »/« coupé » émergent de la même péremption
  quel que soit le canal.
- **Deuxième exception à la règle zéro-dépendance** (décision de l'auteur, modèle pdf.js) :
  le décodeur de QR jsQR 1.4.0 (Apache-2.0) entre vendorisé — chargé paresseusement au premier
  scan, cache séparé versionné par sa version, garde-fous `check-vendor`/`check-sw` étendus et
  vérifiés capables d'échouer, témoin encodeur-maison → décodeur-vendorisé dans les tests.
- **Sous le capot** : la couture `_io` du partage est désormais COMPLÈTE (revoke/setRole/end —
  un transport = huit verbes, plus rien à recopier) ; noyau pur `slHub` (séquence, dédup par
  identifiant d'évènement, capacités par rôle) testé témoin par témoin ; l'encodeur QR maison
  accepte les octets bruts et un masque épinglé (`qrEncodeB`, rendu de `qrSvg` inchangé).
- **Conformité** : la notice de l'écran d'entrée distingue les trois canaux, et le registre
  gagne un § 3.2 — pour les modes sans serveur, la ligne destinataires/sous-traitants est VIDE,
  et les quatre limites mesurées sont écrites (application déjà installée requise ; réseau
  local commun exigé — isolation client, VPN et autorisation « Réseau local » iOS peuvent
  bloquer ; verrouillage d'écran = suspension, réparée par ré-appariement ; « par l'écran » =
  synchro par geste, pas du direct). Le § 2 ne bouge pas : ces modes RECOPIENT, rien n'est
  déduit. Doctrine du lot : `docs/decisions/lot-v5-14.md` (A198-A206).

## [5.13.5] — 2026-08-16
### « Vous gardez le contrôle »

- Le volet **Relecture** des deux éditeurs — aide cognitive et référence — disait « aucune de ces
  remarques n'empêche d'enregistrer, **c'est vous qui connaissez votre service** ». Il dit désormais
  « **vous gardez le contrôle** » (décision de l'auteur). Le rôle de la phrase ne change pas : dire
  en toutes lettres que le volet n'est **jamais bloquant**, ce qui est la contrepartie du registre
  ambre. Un seul texte, une seule occurrence, les deux éditeurs le partagent. La doctrine qui le
  cite (`conventions-de-code.md`) est mise à jour en même temps — une formule citée ailleurs qu'à
  son point d'émission est une formule qui diverge.

## [5.13.4] — 2026-08-16
### Pendant la frappe, l'en-tête s'efface — deux chromes ne se disputent pas une bande

- **La v5.13.3 faisait recouvrir l'en-tête par la colonne** (« pas une bonne solution », capture à
  l'appui). Le fond du problème : *libérer* l'en-tête ne suffisait pas. Libéré, il défile — donc il
  **revient en haut du document** quand on y remonte, et se retrouve alors **dans la même bande**
  que la colonne du champ. Lui passer devant masquait le champ ; lui passer dessous faisait
  recouvrir l'en-tête, ce qui se voit et ne ressemble à rien.
- **Deux chromes qui se disputent la même bande n'ont pas de bon ordre d'empilement : il faut qu'un
  seul soit là.** Pendant la frappe, c'est la colonne — elle porte ce qu'on écrit et ce qu'on
  cherche. L'en-tête (retour, statut, thème, menu) n'a aucun rôle à ce moment-là : il **s'efface**,
  et revient intact dès que le clavier se ferme. Rien ne se superpose, rien ne se masque, rien ne
  saute.
- Mesuré aux deux moteurs et aux deux largeurs : clavier ouvert l'en-tête est `display:none` et la
  colonne occupe le rectangle visible de bout en bout ; clavier fermé l'en-tête est de retour,
  collant à 0. `npm run check` 20/20, `npm test` 2×1126, audit COMPLET 25/25.

## [5.13.3] — 2026-08-16
### La colonne passe devant la décoration — sinon on la perd en remontant

- **Dernier point signalé, capture à l'appui** : « quand je suis avec le clavier et que je rescroll
  en haut, je perds le champ ». La colonne était bien épinglée au rectangle visible ; mais l'en-tête
  est **libéré** — il défile avec la page —, donc il disparaît dès qu'on descend et **revient en
  haut du document** quand on y remonte. Il repassait alors **par-dessus** la colonne (rang 20
  contre 16) et masquait précisément le champ qu'on est en train de taper.
- **La couche du champ prend donc le rang le plus haut du chrome** : entre les deux, c'est ce qu'on
  écrit qui gagne, jamais ce qui décore. Elle reste sous les fenêtres — une modale recouvre tout —
  et reçoit un fond opaque, sans quoi le texte de la page défilerait au travers.
- **Ce que je n'ai pas touché, et c'est une décision** : la barre de recherche de la voie étroite.
  Je lui avais appliqué le même traitement qu'à la colonne ; la mesure l'a refusé — sa boîte ne fait
  que la hauteur de son résumé (45 px) et le champ est rendu **en dessous**, si bien qu'un plafond
  avec défileur l'**écrêtait** et faisait disparaître le champ. Le cas signalé est la colonne ;
  toucher au second logement sans qu'il soit en cause est exactement le schéma qui a coûté onze
  versions à ce dossier. Il reste tel qu'il était et se traitera le jour où il sera signalé, avec
  sa géométrie propre.
- Mesuré aux deux moteurs : page défilée de 1500 px **et** remontée en haut, le champ reste
  atteignable (`elementFromPoint` le rend lui-même) et dans la zone visible. `npm run check` 20/20,
  `npm test` 2×1126, audit COMPLET 25/25.
