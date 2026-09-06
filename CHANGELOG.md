# Journal des modifications

## [5.24.2] — 2026-09-06
### L'audit du partage passe de 220 s à ~75 s ; l'invité reprend le cloud à la sonde (A329)

- **Mesuré d'abord** : chaque section imprime désormais sa durée (`⏱`). Sur une tranche de 220 s, la
  section E2E des bascules pesait 167 à 208 s à elle seule ; à l'intérieur, une attente de 35 s (la
  montre de 30 s de l'invité sur une offre de canal perdue) et 7 à 9 s à chaque retour du réseau
  (l'invité attendait son prochain sondage pour reprendre le cloud).
- **L'app** : l'invité en direct qui tient un billet cloud et dont le canal faiblit reprend le cloud
  dès que la sonde de joignabilité répond (≤ 8 s), plus seulement à son prochain sondage (repli
  jusqu'à 30 s) — la promesse d'A322 tenue à la lettre.
- **Le harnais** : la section E2E devient cinq sections autonomes sur un banc partagé
  (`bancRelais`), jouées en cinq tranches ; montre d'offre réglable au banc (`__acKickMs`, 30 s
  inchangés en production) ; trois attentes fixes ramenées à ce qu'elles prouvent, une attente de
  300 ms passée sur condition. Résultat : harnais `partage` 220 s → 72 s de temps mural, passe complète 415 s → 251 s (pool 4).
- Doctrine A329 dans `docs/decisions/lot-v5-24.md` ; index `AGENTS.md`/`docs/README.md` à A327-A329.
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET après le numéro.

## [5.24.1] — 2026-09-06
### Trois signalements terrain de la v5.24.0 (A328)

- **« Montrer » ne mettait rien à jour chez l'invité** : la réception optique refusait tout
  instantané dès qu'une session était démarrée sur l'appareil hors miroir — l'invité qui suit en
  ligne ou en direct était exactement dans ce cas, et le refus était silencieux depuis le bandeau.
  Une session est « suivie » si c'est le miroir courant ou celle dont l'invité tient l'identifiant ;
  seule une autre session reste refusée. L'invité en ligne garde l'horloge du serveur.
- **En ligne → par l'écran → en ligne : « Partagé · 0 », participants disparus, « En direct ·
  prêt » à 0 participant** : le mode courant était lu comme « par l'écran » dès que ce mode était
  forcé, donc « En ligne » partait dans la bascule, fermait le partage et en ouvrait un neuf pendant
  que l'invité restait sur l'ancien (et son canal direct, pair-à-pair, survivait : « prêt »).
  Règle : le mode courant est le TRANSPORT ; « par l'écran » est une couche par-dessus. Choisir le
  transport déjà en cours ne fait que retirer la couche ; « En direct » depuis « par l'écran » passe
  par la vraie bascule en ligne → direct.
- **Bandeau au cockpit (≥ 1200)** : il montait dans l'en-tête avec la capsule et couvrait le titre ;
  il reste sous l'en-tête, en rangée compacte collante, centrée, bordée et arrondie — pas pleine
  largeur.
- **Focus d'ouverture** : l'anneau tombait sur le lien « Mode : automatique › » ; il va à l'action
  de l'étape. Libellés « compte nécessaire » et « Un mode indisponible reste tapable et dit
  pourquoi ».
- Garde-fous `audit-partage` : « par l'écran » forcé puis « En ligne » garde le même partage et ses
  participants ; un invité qui suit la session reçoit son instantané par l'écran, une autre session
  lui est refusée. Doctrine A328 dans `docs/decisions/lot-v5-24.md`.
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET après le numéro.

## [5.24.0] — 2026-09-06
### La feuille de partage dit quoi faire : l'app décide le canal, les étapes suivent (A327)

- **Plus de sélecteur en tête de feuille.** Une ligne d'état dit le mode et sa raison en un mot
  (« ● Partagé · en ligne — Internet répond, rien à régler » ; « · en direct — Pas d'internet, mais
  un Wi-Fi commun » ; « · par l'écran — Connexion perdue à HH:MM, aucun réseau »). Le canal est
  choisi par l'app : serveur joignable → en ligne ; serveur muet et adresse locale vue → en direct ;
  aucune adresse locale → **par l'écran d'office** (la phase « offer-warn », un QR d'appariement voué
  à l'échec sous un avertissement, disparaît).
- **Une rubrique « À faire, dans l'ordre »** : étapes numérotées, le bouton EST l'étape, une étape
  faite passe en ✓ vert avec le mot. En ligne : ① faire scanner (code au-dessus du QR, ordre mesuré
  à 320×568) ② rien. En direct : ① faire scanner ② « Scanner la réponse » + « Rien après 10 s ?
  Passer par l'écran » ③ rien. Par l'écran, en miroir : hôte ① Montrer ma progression ② Recevoir ses
  repères ③ refaire l'étape 1 à chaque bloc ; invité ① Recevoir la progression ② Renvoyer mes
  repères ③ refaire. L'invité en ligne lit « ✓ Rien » et son rôle expliqué en une phrase.
- **« Envoyer le lien… »** (feuille de partage native, sinon presse-papiers) remplace l'adresse
  brute ; « Nouveau code » devient « Inviter quelqu'un d'autre » ; participants sur deux lignes
  (nom + rôle, puis Donner la main / Couper à 44 px) avec une légende d'une phrase ; l'historique du
  lien reste au pied de chaque feuille.
- **Le bandeau du mode crise = l'étape ① de la feuille, compressée** : « △ Par l'écran », hôte
  « ① Montrer · ② Recevoir », invité « ① Recevoir · ② Renvoyer », ⓘ ouvre la feuille. **L'hôte
  reçoit aussi** (demande de l'auteur) : le retour invité → hôte a sa porte dans le bandeau et dans
  la feuille. **Le bandeau reste affiché tant que « par l'écran » est le mode en cours** (forcé,
  choisi d'office, ou miroir), pour montrer / recevoir sans rouvrir la feuille. 41 px mesurés, une
  ligne à 390 px.
- **Confirmations de bascule** (« Passer en direct ? », « Passer en ligne ? ») et « Arrêter le
  partage ? » réécrites pour se lire en un regard : une phrase, puis « qui fait quoi » en lignes
  courtes ; « secours pas prêt » oppose « Attendre » à « Basculer quand même ».
- **Porte de secours « Mode : automatique › »**, en petit sous la ligne d'état (« forcé, en
  direct » / « forcé, par l'écran » après un choix — dérivé de l'état) : feuille « Changer
  manuellement le mode » à quatre rangées, Automatique en tête (rend la main et réarme le retour
  en ligne), En ligne, En direct (« prêt » quand le secours chaud est formé), Par l'écran
  (« toujours »). Un mode fermé reste tapable et dit pourquoi. L'invité n'a pas cette porte.
- Une seule porte pour « quelle feuille montrer » (`slPhase`/`slSheetNow`) ; purges :
  `slModeSegHtml/Bind`, `slSegCap`, `slSegNetPaint`, `slSegDotRefresh`, `slLinkLine`, CSS
  `.sh-lead`/`.sh-lnk`/`.sh-note`/`.seg` de la feuille.
- Doctrine A327 dans `docs/decisions/lot-v5-24.md` ; index `AGENTS.md`/`docs/README.md`.
  Harnais `audit-partage` réalignés (lien porté par le bouton, feuille « Mode », bandeaux).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET après le numéro.

## [5.23.9] — 2026-09-06
### Trois signalements d'affichage : tuile « En cours », rangées « Gérer », gestionnaire de catégories (A326)

- **Tuile épinglée en session, écran étroit** : « ● En cours » vivait à DROITE d'une tuile de
  165 px et ne laissait qu'une soixantaine de pixels au titre, coupé à chaque ligne. Sous 780 px le
  badge descend sur la sous-ligne, à gauche du discriminant ; le titre reprend toute la largeur
  (mesuré à 390 px : 137 px de titre au lieu de ~60, hauteur de tuile inchangée). Le mot reste :
  jamais une couleur seule (règle 8). Au-dessus de 780 px, rien ne change.
- **Rangées « Gérer les catégories », « Rejoindre une session », « Historique des sessions »
  (feuille « Gérer » et colonne de gauche)** : le chevron — et, sur une rangée sans crayon, le
  nombre — vivaient HORS du bouton, dans l'enveloppe ; taper la flèche ne faisait rien. Sans acte
  frère, la queue entre dans le bouton (`hsRow`) : toute la rangée répond. Position de la queue
  inchangée au pixel (12 px du bord droit, mesuré), nombre toujours aligné à droite.
- **Gestionnaire de catégories** : (a) la colonne « xx éléments » était `auto` — chaque rangée
  taillait son champ de nom selon la longueur du compte (« 0 élément » ≠ « 12 éléments ») ; colonne
  fixe de 76 px, compte aligné à droite, champs de même largeur sur toutes les rangées (mesuré :
  189 px × 8). (b) Le bandeau rouge de confirmation collait au champ (≈ 6 px sur écran tactile, où
  le champ fait 40 px) et la rangée gardait le fond blanc, alors que la palette ouverte pose le
  fond gris de `--bg` : la rangée en confirmation prend la classe `.ask`, même sol que `.open`, et le
  bandeau respire de 8 px.
- Doctrine A326 dans `docs/decisions/lot-v5-23.md` ; index `AGENTS.md`/`docs/README.md` à
  A317-A326.
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET après le numéro.

## [5.23.8] — 2026-09-06
### L'invité rechargé en direct retrouve la session ; « Connexion perdue » (A325)

- **Demandes de l'auteur** : vérifier le rafraîchissement de la page invité pendant le direct ;
  remplacer « Lien perdu » par une formulation claire ; vérifier que la bannière disparaît quand la
  connexion revient et réapparaît si elle se perd de nouveau.
- **Rechargement de l'invité en direct** : il ne tenait plus que le billet du hub local, mort avec
  l'onglet — il se retrouvait chez lui. Son billet cloud est désormais gardé en `sessionStorage` ;
  au démarrage, si le serveur répond, la session est retrouvée seule ; sinon le billet attend et la
  sonde retente. Sans serveur ni canal : l'écran d'entrée et le code, seul chemin.
- **« Connexion perdue »** partout (bannière, feuille, journal, réveil) ; la feuille précise
  « partage manuel par l'écran en attendant » et le motif.
- **La bannière n'a pas de mémoire** : repeinte au tick depuis l'état vivant, elle s'efface quand
  la connexion revient et revient si elle se perd — deux cycles complets mesurés.
- Garde-fous : cinq contrôles ajoutés à la section E2E des bascules d'`audit-partage` (47 → 52),
  dont un vrai rechargement de la page invité, vérifiés capables d'échouer. Doctrine A325 dans
  `docs/decisions/lot-v5-23.md`. CHANGELOG à 20 ([5.22.0] archivée).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET 26/26 après le numéro.

## [5.23.7] — 2026-09-06
### « Lien perdu » : une source d'état, une rangée, une feuille qui dit la même chose (A324)

- **Demande de l'auteur** : quand ni « en ligne » ni « direct » ne portent plus, une petite bannière
  en haut, peu haute, cohérente avec la feuille de partage. Et la seconde limite d'A322, le partage
  expiré pendant une longue coupure.
- **Une source d'état** `slLink()` : « perdu » = plus aucun transport ne porte et rien n'est en
  train de reprendre ; « expiré » = le partage cloud a été refusé pendant la coupure. Tant que le lien
  est perdu, la sonde veille et les reprises automatiques repartent seules au retour du réseau.
- **Une rangée ambre de 41 px** sous la capsule, dans le quai collant (le rail se recale dessous) :
  « △ Lien perdu », puis selon le rôle « Recevoir » et « Renvoyer » (invité), « Montrer la
  progression » (hôte), « Se reconnecter… » (expiré), et ⓘ qui ouvre la feuille. Une ligne à 390 px.
- **La feuille de l'invité naît** : même ligne d'état, journal du lien, mêmes gestes ; les feuilles
  de l'hôte reçoivent la ligne d'état. Réception et retour optiques deviennent deux fonctions
  partagées par la feuille miroir, la feuille invité et la bannière.
- Garde-fous : sept contrôles ajoutés à la section E2E des bascules d'`audit-partage` (40 → 47),
  vérifiés capables d'échouer (source d'état neutralisée → 5 rouges). Doctrine A324 dans
  `docs/decisions/lot-v5-23.md`. CHANGELOG à 20 ([5.21.4] archivée).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET 26/26 après le numéro.

## [5.23.6] — 2026-09-06
### L'hôte rechargé reprend son partage cloud (A323)

- **Limite levée** : un rechargement de l'onglet de l'hôte tuait le partage. L'hôte tient
  désormais un billet cloud en `sessionStorage` (rien de durable, aucune donnée clinique) ; à
  « Reprendre » après un rechargement, si le serveur répond, il reprend son partage existant et y
  rembobine l'état complet — les invités le retrouvent seuls. Serveur muet : le billet attend et la
  sonde retente. Partage expiré ou purgé : billet effacé, chemin du partage neuf. Hôte en direct
  sans serveur : le QR reste le seul chemin, dit dans la feuille.
- Garde-fous : quatre contrôles ajoutés à la section E2E des bascules d'`audit-partage`
  (36 → 40), vérifiés capables d'échouer. Doctrine A323 dans `docs/decisions/lot-v5-23.md`.
  CHANGELOG à 20 ([5.21.3] archivée).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET 26/26 après le numéro.

## [5.23.5] — 2026-09-06
### Le réseau de terrain : chute totale du Wi-Fi, serveur en erreur, battement, portail captif (A322)

- **Demande de l'auteur** : vérifier que le partage tient si le Wi-Fi est instable, se coupe ou
  renvoie sur une page de portail — et tester les autres situations de terrain. Trois défauts
  trouvés à la mesure et corrigés.
- **Chute totale puis retour** : l'hôte reprend le MÊME partage cloud (id, code, secrets des
  invités inchangés) et y pousse les gestes faits pendant le direct ; un invité dont le canal direct
  est mort reprend SEUL avec son secret dès que le serveur répond — sans code, sans geste. Avant, un
  partage neuf était ouvert et l'invité restait bloqué.
- **Serveur en erreur au retour** : la tentative échouée gardait le retour désarmé à jamais ; il
  reste armé et aboutit quand le serveur répond de nouveau.
- **Battement** : l'hystérésis double à chaque retour automatique (jusqu'à 10 min) et se relâche
  après 10 min de calme ; l'évènement `offline` attend 1,5 s avant de trancher.
- **Portail captif** : couvert par construction — la sonde et les sondages échouent à l'interception
  HTTPS, et l'isolation du portail tue le canal direct : c'est la chute totale.
- Garde-fous : neuf contrôles ajoutés à la section E2E des bascules d'`audit-partage` (27 → 36),
  dont « panne sans canal dormant : le cloud reprend seul » et « serveur en erreur : retour armé »,
  vérifiés capables d'échouer (6 rouges sur le code d'avant). Doctrine A322 avec la carte des
  situations et de leurs témoins dans `docs/decisions/lot-v5-23.md`. CHANGELOG à 20 ([5.21.2]
  archivée).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET 26/26 après le numéro.

## [5.23.4] — 2026-09-05
### Le journal du lien : les cinq dernières transitions, sur demande (A321, étape 5 et fin du lot)

- **Un tap sur « Partager » montre ce qui s'est passé** : les cinq dernières transitions du lien,
  horodatées (« 14:02 Passe en direct », « 14:05 Repasse en ligne »), sous le sélecteur des deux
  feuilles de partage. Écrites par la même porte que le mot du quai et l'annonce, en mémoire
  seulement : rien ne sort de l'appareil, le journal meurt avec la session.
- **Bilan du lot « seamless »** : un seul état visible « ● Partagé » ; panne détectée en moins de
  2,5 s au lieu de 5,2 ; retour en ligne automatique sous hystérésis ; réveil qui ramène l'hôte
  seul ; chaque transition vue 8 s au quai et relue dans le journal.
- Garde-fous : deux contrôles ajoutés à la section E2E des bascules d'`audit-partage` (25 → 27),
  vérifiés capables d'échouer. Doctrine A321 dans `docs/decisions/lot-v5-23.md`. CHANGELOG à 20
  ([5.21.1] archivée).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET 26/26 après le numéro.

## [5.23.3] — 2026-09-05
### Au réveil, l'hôte revient seul en ligne si le retour est armé (A320, étape 4)

- **Avant** : la veille tue les canaux directs, et au réveil l'app demandait un geste, au lecteur
  d'écran seulement. **Désormais** : un hôte en direct après une panne, aux participants perdus,
  sonde le serveur au réveil ; s'il répond, le partage repasse en ligne aussitôt et sans
  hystérésis, un lien mort n'ayant rien à préserver. Sinon le quai dit « ● Lien à refaire » pendant
  8 s. Un invité dont le canal est mort re-rentre par le geste existant ; le QR reste le dernier
  recours.
- Garde-fous : deux contrôles ajoutés à la section E2E des bascules d'`audit-partage` (23 → 25),
  vérifiés capables d'échouer une fois l'hystérésis rendue inatteignable au banc (le veilleur
  masquait le réveil). Doctrine A320 dans `docs/decisions/lot-v5-23.md`. CHANGELOG à 20
  ([5.21.0] archivée).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET 26/26 après le numéro.

## [5.23.2] — 2026-09-05
### Le retour en ligne se fait seul après une panne, avec hystérésis (A319, étape 3)

- **Le sens retour devient automatique**, à trois conditions : la bascule vers le direct venait
  d'une panne (un choix manuel n'est jamais contredit), le serveur a répondu à trois sondes
  consécutives, et au moins soixante secondes se sont écoulées en direct. Les invités suivent par
  le billet d'admission remis par le canal chiffré, comme au tap. Rien ne s'ouvre à l'écran : le
  quai dit « ● Repasse en ligne » pendant 8 s, la phrase va au lecteur d'écran.
- **La sonde de joignabilité tourne aussi feuille fermée** tant que le retour est armé ; elle
  s'arrête d'elle-même ensuite. Le retour désarme : pas de boucle.
- **Conformité** : le § 3.2 de `docs/deploiement-et-conformite.md` dit le nouveau régime — rien de
  nouveau ne sort de l'appareil.
- Garde-fous : quatre contrôles ajoutés à la section E2E des bascules d'`audit-partage`
  (19 → 23), vérifiés capables d'échouer (armement retiré → 3 rouges). Doctrine A319 dans
  `docs/decisions/lot-v5-23.md`. CHANGELOG à 20 ([5.20.6] archivée).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET 26/26 après le numéro.

## [5.23.1] — 2026-09-05
### La panne se détecte en moins de 5 s, la transition se voit, le secours se dit (A318, étape 2)

- **Détection** : le secours direct n'était déclenché qu'au second sondage raté, après le repli
  exponentiel — 5,2 s mesurés en activité, jusqu'à 20 s au repos. Désormais, au premier raté la
  sonde de joignabilité tranche, et l'évènement `offline` du système tranche aussitôt : moins de
  2,5 s au harnais.
- **La transition se voit** : les annonces ne parlaient qu'aux lecteurs d'écran. Une porte unique,
  `slSay`, pose un mot au quai pendant 8 s (« ● Passe en direct », « ● Suivi en direct »,
  « ● Repasse en ligne ») et la phrase au lecteur d'écran. Aucune fenêtre, aucun toast.
- **« Secours prêt »** est dit une fois, des deux côtés, quand le canal dormant se forme : on sait
  avant la coupure si la bascule sera silencieuse.
- Garde-fous : quatre contrôles ajoutés à la section E2E des bascules d'`audit-partage`
  (15 → 19), vérifiés capables d'échouer (chemin rapide retiré → 5 230 ms). Doctrine A318 dans
  `docs/decisions/lot-v5-23.md`. CHANGELOG à 20 ([5.20.5] archivée).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET 26/26 après le numéro.

## [5.23.0] — 2026-09-05
### Un seul état visible : « ● Partagé » (A317, étape 1 du lot « seamless »)

- **Demande de l'auteur** : rendre le passage entre partage en ligne et partage direct le plus
  autonome et le plus transparent possible, sans que l'utilisateur ait à se demander s'il doit
  basculer. Six propositions acceptées, livrées en cinq étapes ; celle-ci est la première.
- **Le quai dit « ● Partagé »** dès qu'un partage est actif, quel que soit le canal (en ligne ou
  direct), là où il disait « ● Session » puis « ● Direct ». Le transport n'est plus un état à
  surveiller : il se lit dans la feuille de partage et aux transitions, une phrase sur place. Les
  états dégradés (« figé », « coupé ») gardent leurs mots.
- Garde-fou : deux contrôles dans la section E2E des bascules d'`audit-partage`, vérifiés
  capables d'échouer. Doctrine A317 dans `docs/decisions/lot-v5-23.md` (nouveau fichier du
  lot). CHANGELOG à 20 ([5.20.4] archivée).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET 26/26 après le numéro
  de version.

## [5.22.8] — 2026-09-05
### La pastille choisie ne mord plus ses voisines ; renommer repeint l'aperçu (A316)

- **Signalés par l'auteur** : la pastille sélectionnée mordait sur toutes les autres, bouton
  « palette » compris ; et le nouveau nom d'une catégorie ne s'affichait pas dans l'aperçu de la
  palette. Mesuré : échelle 1,12 plus anneau de 4 px = 5,92 px de débord pour 6 px d'écart, soit
  0,08 px de jeu — un contact à l'œil, horizontalement et vers la rangée du dessous ; et le champ
  de nom n'écrivait que le modèle, sans repeindre l'aperçu.
- **Correctifs** : écart des pastilles porté à 8 px (2,08 px de jeu) ; la frappe dans le champ de
  nom repeint l'aperçu de la palette ouverte.
- Garde-fous : deux contrôles ajoutés à la section A308 d'`audit-doctrine` (jeu ≥ 1,5 px entre
  l'anneau et toute voisine, mesuré au rectangle ; les deux chips de l'aperçu portent le nom
  saisi), vérifiés capables d'échouer (écart à 6 px → « jeu 0,08 px » ; repeinture retirée →
  rouge). Doctrine A316 dans `docs/decisions/lot-v5-22.md`. CHANGELOG à 20 ([5.20.3] archivée).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET 26/26 après le numéro
  de version.

## [5.22.7] — 2026-09-05
### Le curseur de teinte se replie derrière un bouton « palette », quatorzième pastille (A315)

- **Demande de l'auteur** : « cache la palette derrière un bouton à côté des presets avec un petit
  bouton svg montrant la palette », « utilise uiIcon ». Dans la palette ouverte d'une catégorie,
  les treize pastilles sont suivies d'une quatorzième : un bouton à icône `palette`, entrée
  ajoutée à la table d'`uiIcon` (trait, grille 24, tenue par `check-icons`). Le curseur « Autre
  teinte » et l'aperçu ne se rendent qu'au tap ; le pli fermé perd ≈ 110 px.
- **L'état se voit** : replié par défaut ; ouvert d'office quand la couleur n'est pas un preset,
  le bouton portant alors l'anneau de sélection comme la pastille d'un preset choisi ; le choix
  de l'utilisateur l'emporte ensuite jusqu'au prochain pli. Focus rendu au bouton après re-rendu.
- Garde-fou : deux contrôles ajoutés à la section A308 d'`audit-doctrine` (14 boutons, curseur
  absent puis présent au tap ; pli rouvert sur une couleur hors preset → curseur d'office et bouton
  marqué), vérifiés capables d'échouer. Doctrine A315 dans `docs/decisions/lot-v5-22.md`.
  CHANGELOG à 20 ([5.20.2] archivée).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET 26/26 (deux passes).

## [5.22.6] — 2026-09-05
### L'anneau du curseur passe par les presets ; la palette, mesurée, reste (A314)

- **« On ne pouvait pas mieux faire ? »** Pour le curseur, si : l'anneau d'A308 (clarté et chroma
  constantes) ne passait pas par les presets, et A312 n'était qu'un accrochage — la barre
  montrait l'anneau, le résultat sautait à treize endroits. Trois anneaux ont été chiffrés sur
  360° et dessinés sur le canvas ; retenu par l'auteur : **l'anneau ancré sur les presets**,
  clarté et chroma interpolées en teinte entre presets voisins, clarté bornée là où la pastille
  passait sous 4,5. Écart nul aux treize degrés, en gamut partout, blanc ≥ 5,50, pastille ≥ 4,50.
  Le curseur devient le prolongement continu de la palette ; l'accrochage d'A312 n'a plus rien
  à cacher.
- **La palette elle-même reste**, mesurée : écart minimal 5,9 ΔE entre presets, contrastes de la
  régression #3 partout, chips lisibles en sombre. Deux faiblesses connues (teintes vert-bleu
  resserrées à 16-22°, trois presets sous 3:1 en pleine couleur sur fond sombre) ne se corrigent
  pas sans coût : les contraintes clair et sombre se contredisent à cette chroma, et les couleurs
  déjà stockées ne changent jamais — une palette re-résolue coexisterait avec l'ancienne en
  quasi-doublons. Avec l'anneau ancré, les intervalles entre presets sont atteignables au curseur.
- Garde-fous : `tests.html` — l'anneau passe par chaque preset, la teinte suit le degré entre
  deux presets, le vermillon à 19° sans accrochage (1189 → 1190), contrastes sur 120 teintes
  conservés ; vérifiés capables d'échouer (anneau constant → 2 rouges). Doctrine A314 dans
  `docs/decisions/lot-v5-22.md`. CHANGELOG à 20 ([5.20.1] archivée).
- Vérifié : `npm run check` complet, 1190 tests × 2 moteurs, audit COMPLET 26/26 (deux passes).

## [5.22.5] — 2026-09-05
### Au clavier, le piège des fenêtres déplace lui-même le focus, l'anneau suit, les champs s'allument par la bordure (A313)

- **Signalé par l'auteur** : « Tab : le curseur se déplace mais pas le design autour du bouton ;
  et quelquefois le design autour du bouton se met autour des champs texte ». Mesuré sur les deux
  moteurs : le piège Tab ne prenait la main qu'aux deux bouts de la liste, et entre les deux c'est
  l'ordre natif du navigateur — WebKit saute les boutons par défaut (cinq Tab de champ en champ
  dans « Gérer les catégories », et dans une confirmation le troisième Tab sortait de la
  fenêtre). Les champs des fenêtres n'avaient pas de style de focus à eux (anneau du navigateur,
  noir 3 px sur WebKit) et le halo de bouton se posait sur le champ « Nouvelle catégorie… ».
- **Le piège déplace lui-même le focus à chaque Tab et Maj+Tab**, dans l'ordre du DOM avec
  bouclage, et **pose l'anneau** sur l'élément atteint (retiré au blur suivant) — le mécanisme
  d'A237 généralisé au clavier. **Le halo est réservé aux boutons** ; un champ de fenêtre signale
  son focus par sa bordure allumée, comme les champs des formulaires. Curseurs, cases et boutons
  radio gardent leur anneau.
- Garde-fou : cinq contrôles ajoutés à la section « Fenêtres · le bouton focalisé se voit… »
  d'`audit-doctrine` (Tab reste dans la fenêtre, chaque arrêt porte l'anneau, les boutons sont
  atteints, les champs portent la bordure allumée et jamais l'anneau du navigateur), verts sur
  Chromium ET WebKit, vérifiés capables d'échouer (code d'avant → 5 rouges sur WebKit). Doctrine
  A313 dans `docs/decisions/lot-v5-22.md`. CHANGELOG à 20 ([5.20.0] archivée).
- Vérifié : `npm run check` complet, 1189 tests × 2 moteurs, audit COMPLET 26/26 (deux passes).

## [5.22.4] — 2026-09-05
### Un degré, une couleur : le curseur rend le preset ou la couleur d'origine à leur degré (A312)

- **Signalé par l'auteur** : « même si le degré est le même je n'ai pas l'impression d'avoir la
  même couleur ; deux catégories marquées « proche de… », je joue avec la molette, je reviens à la
  couleur de base : plus de « proche de », et la couleur n'est pas la même ». Exact, et vérifié par
  le calcul : les treize presets ne sont pas sur l'anneau du curseur (L 0,48 · C 0,08) — au même
  degré, preset et couleur d'anneau diffèrent de 1,1 à 9,1 ΔE (le vermillon d'« Urgences » à 19°
  redevenait un brun terne). Revenir « au même degré » rendait donc une autre couleur, et la
  distance aux voisines changeait avec elle.
- **Correctif** : à un degré donné, toujours la même couleur — d'abord la couleur du pli à son
  ouverture (un hex importé hors anneau se retrouve), puis le preset dont le degré coïncide, et
  seulement sinon l'anneau. La pastille du preset s'allume quand le curseur l'atteint.
- Garde-fous : `tests.html` § « curseur : un degré, une couleur (A312) » (5 témoins, 1184 → 1189) ;
  un contrôle ajouté à la section A308 d'`audit-doctrine`, vérifié capable d'échouer. Doctrine
  A312 dans `docs/decisions/lot-v5-22.md`. CHANGELOG à 20 ([5.19.6] archivée).
- Vérifié : `npm run check` complet, 1189 tests × 2 moteurs, audit COMPLET 26/26 (deux passes).

## [5.22.3] — 2026-09-05
### Sur « Toutes », une bande collante par bibliothèque dans le gestionnaire de catégories (A311)

- **Demande de l'auteur** : « améliorer la séparation des bibliothèques dans la fenêtre de
  modification des catégories ; design clair ». Mesuré avant : chaque section n'était introduite
  que par une phrase et un filet, et le champ « Ajouter » de la suivante se collait à la liste de
  la précédente ; une fois le corps défilé, rien ne rappelait la bibliothèque.
- **Chaque bibliothèque devient une section ouverte par une bande collante**, au dessin exact de
  l'intertitre de l'accueil (fond de page, filet, capitales 11 px, compte en mono à droite) :
  glyphe personne pour « Espace personnel », livre pour une bibliothèque, mention « partagée » à
  côté du nom ; 24 px entre deux sections ; la bande tient au haut du défileur pendant qu'on fait
  défiler ses catégories. Le champ d'ajout d'une bibliothèque dit « Nouvelle catégorie
  partagée… », là où la phrase supprimée portait l'information. Rien d'autre ne bouge :
  « Ajouter » en tête, rangées et palette d'A308.
- Garde-fou : `audit-doctrine` § « Catégories · une bande collante par bibliothèque »
  (5 contrôles, 98 → 99 sections), vérifié capable d'échouer. Doctrine A311 dans
  `docs/decisions/lot-v5-22.md`. CHANGELOG à 20 ([5.19.5] archivée).
- Vérifié : `npm run check` complet, 1184 tests × 2 moteurs, audit COMPLET 26/26 (deux passes,
  avant et après le numéro de version).

## [5.22.2] — 2026-09-05
### La grille de lecture lit le token de colonne que le dock lisait déjà (A310)

- **Signalé par l'auteur** : « tu n'as pas adapté la taille de la barre flottante en bas depuis
  que tu as diminué la sidebar droite ». Exact : A308 avait posé `280px` en littéral dans la grille
  de lecture, alors que le dock flottant et son volet calculent leur marge droite sur `--col-state`,
  resté à 320 — contre la règle écrite à la déclaration des tokens (« une seule source »). Mesuré à
  820 px en session : le dock s'arrêtait 42 px avant le bord de la colonne d'action.
- **Correctif** : `--col-state` devient un token PAR PALIER (280 dès 780, 320 dès 1000) et les
  grilles de lecture (780, 1000, 1200, cockpit) lisent `var(--col-state)`, `var(--col-orient)`
  et `var(--col-gap)` — grille, dock et volet ne peuvent plus diverger. Reste l'écart symétrique
  et préexistant de 2 px entre le rembourrage du dock (20) et celui de la grille (18).
- Garde-fou : un contrôle ajouté à la section A309 de `audit-doctrine` (bord droit du dock à
  ≤ 3 px de la colonne d'action), vérifié capable d'échouer sur le défaut réel (littéral
  réintroduit → écart −42 px). Doctrine A310 dans `docs/decisions/lot-v5-22.md`. CHANGELOG à 20
  ([5.19.4] archivée).
- Vérifié : `npm run check` complet, 1184 tests × 2 moteurs, audit complet (deux passes ; la
  machine étant très chargée ce jour, plusieurs sections à délais ont dû être rejouées, vertes
  isolément et en tranches complètes).
