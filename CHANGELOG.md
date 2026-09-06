# Journal des modifications

## [5.26.3] — 2026-09-07
### La bouée de bascule, et l'invité que rien n'atteint (A332, addendum)

- **Questions de l'auteur** : « et si pas de retour de l'hôte ? une bouée envoyée lors du passage
  de l'hôte en direct pour forcer les autres ? » ; « quid si un invité n'est pas sur le même
  réseau ? » ; « quid de la reprise en ligne après perte totale réseau et Wi-Fi ? ».
- **La bouée** : à sa bascule en direct, l'hôte le crie sur chaque canal dormant — le relais est
  mort pour lui, mais le canal vit. L'invité qui la reçoit suit en direct même si son propre relais
  répond encore, son billet cloud gardé ; au retour de l'hôte, il repasse en ligne seul. Avant, un
  invité dont le relais répondait restait sur un partage que plus personne n'alimentait.
- **L'invité hors du réseau commun**, que ni le direct ni la bouée n'atteignent, lit désormais
  « △ Hôte silencieux · ① Recevoir » dans le quai au-delà de 45 s sans nouvelles de l'hôte, et sa
  feuille dit ce qui reste vrai : ses gestes arrivent au journal et l'hôte les lira à son retour ;
  sa progression à lui se reçoit par l'écran. Rien n'est jugé : une heure recopiée, effacée dès que
  l'hôte reparle. Ses coches ne sont pas suspendues.
- **Reprise après perte totale** : mesurée dans les trois cas (canal mort à la coupure, canal
  survivant quelques secondes, rechargement pendant la panne) — même partage repris des deux côtés,
  gestes de l'hôte gardés ; un partage expiré pendant une longue coupure dit « Se reconnecter ».
- **Garde-fous** : section « hôte seul » réécrite autour de la bouée, section « invité hors du
  réseau commun » (9 contrôles au total), vérifiées capables d'échouer sur le code d'avant.

## [5.26.2] — 2026-09-07
### Ce que la panne fait aux gestes du partage (A332)

- **Signalé par l'auteur** : « arrêté depuis » n'apparaissait que chez celui qui avait arrêté le
  minuteur ; que se passe-t-il quand un participant perd internet mais garde le Wi-Fi, ou perd
  les deux ; et « quand les deux appareils passent hors ligne, l'invité ne peut plus rien cocher,
  puis au retour en ligne chacun avance de son côté ». Tout a été MESURÉ au banc avant de corriger
  (carte des situations dans la doctrine).
- **Le minuteur arrêté est daté chez l'autre** : l'arrêt reçu prend l'heure de l'évènement (jamais
  une clé de charge nouvelle — la liste blanche serveur est intacte), l'armement l'efface ; à la
  jointure et par l'écran aussi. Avant, l'autre écran n'avait rien, ou gardait la date de son
  propre arrêt précédent.
- **L'hôte ne perd plus ses gestes faits pendant une panne** : lien figé, une coche de l'hôte
  n'entrait pas dans la file (refusée pour péremption après que la base de comparaison avait
  avancé) et n'atteignait jamais le journal ni l'invité. L'hôte n'est plus jamais refusé pour
  péremption : la file persistée porte ses gestes au retour.
- **Panne côté hôte seul** (portail captif de l'hôte, invités qui gardent internet) : l'hôte
  basculait en direct sans qu'aucun invité le suive, puis restait en direct pour toujours au retour
  du réseau — chacun avançait de son côté. Il revient désormais seul sur le MÊME partage par son
  billet, même sans invité sur son hub, et les invités restés en ligne rattrapent ses gestes.
- **La reprise de l'invité repeint l'écran** : revenu seul après une panne, il reconstruisait son
  état sans le montrer et gardait l'écran d'avant la coupure. Le journal est rejoué par la voie
  vivante.
- **Le bridage de l'invité périmé se voit** : ses coches restent suspendues tant que le lien est
  figé (décision gardée : elles ne remontent pas par l'écran), mais les contrôles le montrent
  désormais, et la feuille comme le bandeau disent que seuls ses repères datés (« Noter l'heure »)
  repartent.
- **Garde-fous** : 4 tests unitaires (date d'arrêt = heure de l'évènement, aucune clé de charge
  nouvelle, pli optique), 2 sections d'`audit-partage` (9 contrôles), vérifiées capables d'échouer
  (6 rouges sur le code d'avant).

## [5.26.1] — 2026-09-06
### Les anneaux seuls, un temps après l'affichage (A331, addendum)

- **Demande de l'auteur** : plus de relèvement du quai à l'arrivée, seulement les trois anneaux —
  et qu'ils partent un peu après l'affichage de la page, pas d'emblée.
- **Ce qui change** : le premier anneau part à 800 ms, puis 2,1 s et 3,4 s ; tout est fini à
  4,7 s, toujours sous les 5 s. Le quai est simplement là, immobile, dès l'ouverture. Le
  `@keyframes` du relèvement est purgé.

## [5.26.0] — 2026-09-06
### Il reste un geste après avoir ouvert une carte, et le quai le dit (A331)

- **Demande de l'auteur** : attirer l'attention sur le fait qu'après avoir ouvert une aide, il
  faut encore démarrer la session — sans fondu en boucle (WCAG 2.2.2). Maquettes et démonstration
  rejouable validées sur canvas ; les formes refusées sont consignées dans la doctrine.
- **L'arrivée du quai** : à l'ouverture d'une fiche, avant la session, la capsule se relève une
  fois (14 px, 280 ms) puis trois anneaux s'en éloignent de 12 px et s'effacent, à 0,9, 2,2 et
  3,5 s — tout est fini à 4,8 s, rien ne boucle. L'anneau entoure la capsule entière, jamais le
  bouton seul : il ne touche ni la touche Exercice ni le bouton. Sombre le jour, clair la nuit ;
  nul sous « réduire les animations » ; jamais rejoué tant qu'on reste sur la fiche.
- **La bulle d'apprentissage**, 16 px au-dessus du quai, pointée sur le bouton : « Rien n'est
  lancé tant que vous consultez. Étapes, minuteurs, partage : "Démarrer la session". » Elle reste
  tant qu'aucune session n'a été démarrée sur l'appareil, puis disparaît pour de bon. La réserve
  de bas de page suit sa hauteur.
- **« Exo. »** : sous 430 px la touche Exercice garde un mot tronqué au lieu de perdre son libellé.
- **Garde-fous** : cliquet `pointer-events:none` de `check-anim` monté à 23 (l'anneau est un
  annonciateur pur). Doctrine A331 dans `docs/decisions/lot-v5-26.md`, index mis à jour.

## [5.25.1] — 2026-09-06
### La carte « Quand l'utiliser » respire pareil en haut et en bas (A330, addendum)

- **Signalé sur main** : sans diagnostic différentiel, le cadre « Quand l'utiliser » avait moins de
  respiration sous le dernier critère qu'au-dessus du premier (mesuré à 390 px : 15 px contre 4).
  Depuis que le titre vit au-dessus du cadre (v5.25.0), seul le lien « Le tableau ne colle pas ? »
  fermait la carte — et il n'existe que si la fiche déclare des différentiels.
- **Correction** : la carte porte 6 px en haut et en bas, la liste 4/4 ; le lien de sortie, quand
  il existe, reprend les 6 px du bas pour rester au ras du cadre. Mesuré après : 15/15 sans lien,
  lien au ras avec, hauteur de carte inchangée dans ce cas.

## [5.25.0] — 2026-09-06
### L'écran d'entrée d'une aide se lit comme un écran de démarrage (A330)

- **Demande de l'auteur** : « comprendre que c'est juste un écran de démarrage, que l'action se
  situe après ; le plan n'est qu'un plan ». Mesuré avant : « Prise en charge » en titre, des
  rangées blanches numérotées qui invitent au tap, des compteurs « 0/4 », et le seul mot qui disait
  le contraire — « inerte » — à 11 px gris clair. Maquettes itérées sur canvas.
- **Trois chapitres de même niveau, sans numéro** : les intitulés qui existaient sortent de leurs
  cadres — « ■ Quand l'utiliser », « ■ Ne pas oublier », « Parcours » (sous-ligne « Aperçu — se
  déroule après le démarrage ») —, un filet et un blanc ouvrent chacun. En session, rien ne change.
- **Le plan est un aperçu à plat** : ni carte, ni pastille, ni « 0/4 » ; numéros, titres et renvois
  gris ; la rangée de décision se tait quand ses branches sont étiquetées ; rangées de 32 px,
  toujours dépliables. « Surveiller ensuite » reste au rail. Tableau et Schéma vivent sous le titre
  « Parcours », à largeur de contenu, alignés à gauche.
- **Rien ne démarre sauf le chrono** (correction de l'auteur) : le rail « Ce qui démarrera » devient
  « En session » (« démarre avec la session » / « 2:00 cyclique, à lancer ») ; sur téléphone,
  « Minuteurs à disposition en session : Cycle RCP 2:00 · Adrénaline 4:00. » remplace la ligne
  « 5 blocs · 2 minuteurs · … ».
- **Le sur-titre dit l'état** : « Avant la session · adulte », encre neutre, dans le logement que
  « ■ Mode crise » prend au premier geste. Cockpit : même grammaire dans la colonne de gauche, sans
  « ICI ». Notes locales, note personnelle et pied passent en queue sous un filet ; la porte « Le
  tableau ne colle pas ? » à l'encre normale.
- **Garde-fous** : témoins d'audit-doctrine réalignés (boutons sous « Parcours » et au-dessus de
  l'aperçu, zéro « Prise en charge » avant la session), tests Q4 réécrits, `.conf-eh` purgé avec
  épitaphe. Doctrine A330 dans `docs/decisions/lot-v5-25.md` ; formes refusées consignées.

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
