# Journal des modifications

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

## [5.22.1] — 2026-09-04
### Dans le rail, les deux ajouts sur une rangée sous les compteurs (A309)

- **« ＋ Minuteur » et « ＋ Compteur » partagent une rangée** placée sous les compteurs, dans le rail
  de session seulement. Ils occupaient deux boutons pointillés pleine largeur, chacun sous sa
  famille (≈ 118 px au milieu de la colonne d'état, là où le rail coûte le plus à l'action à
  820 px). Ce sont des gestes de session — minuteur ad hoc, compteur créé à 1 —, pas de
  l'édition : ils gardent 44 px et restent visibles sans tap de plus (la variante « ＋ Ajouter… »
  à choix a été écartée pour cette raison). Gain ≈ 54 px. Le choix de durée s'ouvre sous la
  rangée ; le volet étroit ne change pas (« ＋ Minuteur » y reste dans sa famille, v5.4.1).
- Garde-fou : `audit-doctrine` § « RAIL · les deux ajouts sur une rangée sous les compteurs »
  (5 contrôles, 97 → 98 sections), vérifié capable d'échouer. Doctrine A309 dans
  `docs/decisions/lot-v5-22.md`. CHANGELOG à 20 ([5.19.3] archivée).
- Vérifié : `npm run check` complet, 1184 tests × 2 moteurs, audit COMPLET 26/26 (deux passes).

## [5.22.0] — 2026-09-04
### Le gestionnaire de catégories en liste, plus de couleurs, le rail de session à 280 px sur tablette (A308)

- **« Gérer les catégories » passe en LISTE.** La fenêtre répétait la palette sous chaque catégorie
  (104 pastilles pour 8 catégories, 1 144 px de haut à 820 px de large) et le champ « Ajouter »,
  seule action de création, était à 1 298 px sous le haut — hors écran. Désormais : « Ajouter » en
  tête de chaque section, rangées de 44 px (pastille · nom · compte · ×), et la palette ne s'ouvre
  que pour la catégorie dont on tape la pastille, une seule à la fois ; le focus revient sur la
  pastille après le re-rendu. Huit catégories tiennent en 715 px. Toutes les portes mènent à la même
  fenêtre — accueil, feuille « Gérer », atelier d'import, et « ＋ Nouvelle catégorie » des éditeurs
  de fiche et de protocole (vérifié au témoin).
- **Plus de couleurs, sans toucher au modèle.** Un curseur « Autre teinte » parcourt l'anneau
  OKLCH L 0,48 · C 0,08 — la chroma maximale qui reste dans le gamut sur tout le tour ; les deux
  contrastes de la régression #3 (blanc sur teinte pleine, teinte sur fond à 15 %) tiennent par
  construction sur les 360 degrés (≥ 6,2 et ≥ 5,0). Aperçu en direct (pastille, chip), et un
  garde-fou de proximité : « △ proche de « X » » sous 4,0 ΔE d'une catégorie du même périmètre ;
  un hex importé illisible est dit « △ contraste faible ». Conversion maison, aucune dépendance,
  aucune couleur littérale dans la feuille. Les treize presets ne changent pas. ⚠ Un premier jet à
  C 0,10 écrêtait le cyan hors gamut — attrapé par le témoin d'aller-retour, corrigé avant livraison.
- **Rail de session à 280 px entre 780 et 999 px** (320 dès 1000, palier déjà déclaré). Mesuré à
  820 px : le rail prenait 41 % de la largeur et laissait 444 px à la colonne d'action, la largeur
  d'un téléphone. Rendu à 280 : cartes minuteur 261 px, aucun débordement nouveau ; +40 px pour
  l'action. À 1024 px rien ne change (648 / 320).
- Garde-fous : `tests.html` § « anneau de teinte (A308) » (8 témoins), `audit-doctrine`
  § « Catégories · une palette à la fois… » (10 contrôles, 96 → 97 sections), vérifié capable
  d'échouer. Doctrine : `docs/decisions/lot-v5-22.md`. CHANGELOG à 20 ([5.19.2] archivée).
- Vérifié : `npm run check` complet, 1184 tests × 2 moteurs, audit COMPLET 26/26.

## [5.21.4] — 2026-09-03
### Le compte des relances est posé : l'éviction n'est pas le sujet, l'instrumentation part (A307)

- **Le diagnostic P2 des relances iOS (v5.10.3) est CLOS par la mesure qu'il demandait.** Lu sur
  l'iPhone de l'auteur, Compte › « Sur cet appareil » : **33 relances complètes sur 7 jours pour
  109 reprises sans relance** — un retour sur quatre à froid (≈ 4,7 par jour), trois sur quatre
  depuis la mémoire. Le critère posé en v5.10.3 (« b élevé et PROCHE de r = évincée presque à
  chaque retour ») n'est pas atteint, et le quart restant mêle des causes qui n'ont rien à voir
  avec la pression mémoire : premier lancement de la journée, retour après plusieurs heures (iOS
  jette un contenu web resté longtemps en arrière-plan, quel que soit son poids), fermetures par
  le sélecteur d'apps, et les **rechargements de mise à jour** — cinq publications dans la fenêtre.
- **Verdict : l'hypothèse d'éviction d'A153 tombe, le poids du monofichier est définitivement un
  NON-SUJET runtime.** Même sur la fraction réellement évincée, le levier serait nul : la décision
  de jetsam d'iOS se prend sur l'empreinte du processus WebKit (tas, DOM, code compilé — des
  dizaines de Mo contre des plafonds en centaines), dont les 2,4 Mo de source, et les 1,26 Mo de
  commentaires qui n'alimentent rien de tout cela, sont quelques pour cent. Les pistes (a) et (b)
  d'A153 restent fermées, « monofichier sans build » n'est pas rouvert, le CSS critique (R2)
  reste abandonné. Rien n'est implémenté côté empreinte : il n'y a rien à implémenter.
- **L'instrumentation part avec le diagnostic** (précédent : la ligne diag `ih/vv/dvh` de
  v4.29.x) : `bootLogBump` et son écouteur `visibilitychange`, la ligne « Relances complètes »
  du Compte et sa lecture. La clé `ac-boot-log` déposée par les versions 5.10.3 à 5.21.3 est
  effacée au démarrage (une ligne au site de l'ancien journal, patron du retrait d'`ac-pins`) ;
  pour ré-instrumenter un jour, le tag v5.21.3 porte le code. Retrait vérifié au grep (zéro
  émission), hashs CSP rejoués.
- Doctrine : A307 dans `docs/decisions/lot-v5-21.md`, index AGENTS.md et `docs/README.md` mis à
  jour (A297-A307). CHANGELOG à 20 ([5.19.1] archivée). Vérifié : check complet, 1176 tests ×
  2 moteurs, audit COMPLET 26/26 (deux passes, avant et après le numéro de version).

## [5.21.3] — 2026-09-03
### La pastille d'un homonyme ne montre que ce qu'elle compte (A306)

- **La pastille multicolore de la colonne gauche ne se mettait pas à jour** (signalé : « si une
  catégorie double de même nom mais couleur différente s'affiche puis se retire sur la sidebar,
  la pastille bicolore ne se met pas à jour »). Mesuré sur les deux moteurs : sur « Toutes », la
  rangée « Réanimation » portait TROIS couleurs, dont celle d'une homonyme à **zéro** élément ; sur
  une seule bibliothèque, où une seule catégorie de ce nom existe, elle restait tricolore.
  **Cause** : A299 (v5.21.0) construisait les couleurs sur `categories` BRUT, là où le compte de la
  même rangée ne lisait que le périmètre. Une couleur ne contribue désormais que si sa catégorie
  est **du périmètre affiché** (`homeLibOn`, le prédicat de la liste) **et y compte au moins un
  élément** — ou porte le filtre actif, seule rangée qui reste à zéro. A299 n'est pas renié :
  quand deux homonymes comptent, la pastille les montre toutes.
- **Attrapé en route : le compte de la colonne était indexé par id**, or deux bibliothèques peuvent
  porter le même id de catégorie (A298) — deux « Trauma » de même id, Perso et bibliothèque, se
  comptaient DEUX FOIS (mesuré : 6 pour 3 fiches). `catOf` résout déjà le couple id + bibliothèque ;
  le compte est une `Map` par objet de catégorie.
- **Signalement voisin MESURÉ et NON reproduit** : « en voie étroite, le ✎ d'une bibliothèque
  dans le quart supérieur de l'écran remet le défilement en haut à l'ouverture de *Modifier la
  bibliothèque* ». Dix-huit cas joués sans qu'un pixel ne bouge — Chromium et WebKit au pointeur
  grossier (le verrou de fond n'existe QUE sous `pointer:coarse`), cinq hauteurs ; **simulateur
  iPhone 17 (iOS 26.5), en Safari puis en app INSTALLÉE** (zone sûre réelle), copie instrumentée
  avec témoin de défilement à l'écran et liste des membres stubée, intertitre collé et non collé,
  fermeture par ✕ et par « Enregistrer » ; `render()` rejoué fenêtre ouverte sous verrou (le cas
  d'un pull de synchro chez un compte connecté) ; zoom de texte 1,15 et 1,3. Non joué : un iOS
  antérieur à 26.5, le vrai compte de l'auteur. Pistes restantes écrites dans A306 ; le patron reste
  celui d'A295 — on ne corrige pas ce qu'on n'a pas reproduit.
- Garde-fou : `audit-doctrine` § « la pastille d'un homonyme suit le périmètre affiché »
  (7 contrôles, 95 → 96 sections), vérifié CAPABLE D'ÉCHOUER (`index.html` remis à HEAD → 7 rouges,
  restauré à l'octet). CHANGELOG à 20 ([5.19.0] archivée). Vérifié : check complet, 1176 tests ×
  2 moteurs, audit COMPLET (un aléa de délai sur « un rechargement ne perd plus la session »,
  vert deux fois en rejeu isolé, sans rapport).

## [5.21.2] — 2026-09-02
### Deux commandes qui mentaient : la lecture seule, et le compte du gestionnaire (A305)

- **Le gestionnaire de catégories s'ouvrait sur une bibliothèque en LECTURE SEULE** — et c'était
  **pire qu'une commande morte**. Mesuré : champ de nom éditable, 13 pastilles de couleur, bouton
  Supprimer, « ＋ Ajouter » ; et le renommage **s'appliquait localement** (`Trauma` → `RENOMMÉ`,
  marqué « à pousser ») avant d'être refusé par la RLS. L'utilisateur croyait contribuer — le pire
  mode de défaillance du dossier, transposé aux catégories.
  **Cause : le filtre `canEditScope` n'était posé que sur UNE des deux branches** de
  `catMgrScopes()` — celle de « Toutes ». Le cas « une seule bibliothèque affichée » passait au
  travers. Un seul prédicat désormais, appliqué aux deux : `…filter(canEditScope)`.
- **La commande disparaît à ses trois portes** (colonne gauche, puce « Gérer » de la feuille
  étroite, feuille du pouce) via un prédicat unique `catMgrOn()`, et `#mgrBtn` se masque quand il
  n'y a plus rien à gérer du tout — sinon son libellé dit désormais « Gérer les bibliothèques ».
  Défense en profondeur : forcée par un autre chemin, la fenêtre **dit pourquoi** elle est vide et
  n'affiche pas un seul contrôle.
- **Le gestionnaire n'affichait pas le bon nombre** (signalé). Il ne comptait que les **fiches**,
  alors que la colonne gauche compte l'union fiches + protocoles : les deux divergeaient du nombre
  exact de protocoles rangés dans la catégorie. Et le défaut ne s'arrêtait pas à l'affichage —
  **supprimer une catégorie ne déplaçait que les fiches**, laissant la `category` des protocoles
  pointer sur une catégorie disparue. `catItems(id,scope)` devient la source unique du contenu
  d'une catégorie : le compte, la confirmation et le déplacement en découlent, chaque nature
  repassant par SON point de persistance (patron de `selWrite`). Le libellé suit : « n éléments »,
  comme le répertoire, puisque les deux natures y sont.
- ⚠ **Deux fausses pistes écartées à la mesure, pas au raisonnement.** (1) Les entités
  soft-supprimées semblaient comptées — `load()` les écarte déjà (`fiches=allFiches.filter(f=>!f.deletedAt)`),
  le cas était fabriqué par ma sonde. (2) La colonne gauche semblait avoir perdu son compte —
  `hsRow` le pose **à côté** du bouton, dans `.hs-wrap` : le chercher DANS `[data-cat]` rend
  toujours « absent ». Le témoin porte ce piège en commentaire, sans quoi il aurait mesuré un vert
  sur un rouge.
- **Garde-fous** : `audit-doctrine` § « le gestionnaire compte comme la colonne, et déplace tout »
  (6 contrôles, 94 → 95 sections) et deux contrôles ajoutés à § « le périmètre affiché commande… »
  (même décor, une manœuvre une section). **Vérifiés capables d'échouer** : les deux défauts
  réintroduits → 6 rouges exactement sur les bonnes assertions, `index.html` restauré à l'octet.
- Vérifié : `npm run check` complet, 1176 tests × 2 moteurs, audit COMPLET 26/26 (deux passes,
  avant et après le numéro de version).

## [5.21.1] — 2026-09-02
### Le périmètre affiché commande enfin les commandes (A304)

- **Suite d'A303, et même cause de fond.** `state.scope` vaut **toujours `null` à l'accueil**
  depuis la v5.18 : `canEditScope(state.scope)` répondait donc « oui » partout, et six lecteurs
  décidaient sur un champ mort. Tous ralliés à `homeScope()` — **source unique** du périmètre
  affiché (`null` = « Toutes », `''` = Perso, sinon un id) — plutôt qu'à six copies qui
  divergeraient à nouveau.
- **Plus de commandes mortes sur une bibliothèque en LECTURE SEULE** (mesuré : les deux
  s'affichaient). « Sélectionner » disparaît — ce que son propre commentaire promettait déjà —,
  « Créer » aussi, et la création est refusée avec sa raison.
- **Créer dans la bibliothèque qu'on regarde, et le DIRE.** Une fiche naissait **au Perso** quelle
  que soit la bibliothèque affichée. Elle naît désormais dans celle-ci — mais une entité neuve naît
  `validated` (migrate ne laisse pas la chaîne vide), donc **visible de tous les membres
  aussitôt** : la publication est annoncée AVANT qu'aucun brouillon n'existe (« publier à l'équipe
  jamais silencieux », A166), refuser ne crée rien, et le dépliant d'identité de l'éditeur —
  ouvert d'office sur une fiche neuve — montre la destination. Idem protocoles.
- **La destination par défaut de l'atelier d'import** suit la bibliothèque affichée
  (`impLibDefaut`), et **le renvoi croisé de recherche compte dans les MÊMES crans que la liste** :
  il ne voyait que le Perso, et comparait la catégorie par id là où la v5.18 compare par **nom**.
- **L'édition de PROTOCOLE gère les catégories de SA bibliothèque** (`activeCatScope` y retombait
  sur `state.scope`), et la ligne « Cette bibliothèque partagée est vide » redevient atteignable.
- ⚠ **LE PIÈGE DE LA CORRECTION ELLE-MÊME, attrapé avant livraison.** Une condition constante
  devenue **variable** ne peut plus vivre dans `applyViewChrome` seul : un tap de la colonne gauche
  ne rejoue que la LISTE (`cfg.rerender`), et `#hdrNew` restait celui de la bibliothèque
  précédente. La décision vit donc dans `syncNewBtn()`, appelée des deux côtés — patron exact de
  `syncMgrBtn`. Le témoin le prouve : sans l'appel de `bindHomeChrome`, « lecture seule : pas de
  Créer » vire au rouge.
- **Garde-fou** : `audit-doctrine` § « le périmètre affiché commande *Créer* et *Sélectionner* »
  (13 contrôles, 93 → 94 sections), **vérifié capable d'échouer** deux fois — lecteurs remis sur
  `state.scope` → 9 rouges ; appel de `syncNewBtn` retiré de `bindHomeChrome` → 1 rouge, celui du
  périmage. `index.html` restauré à l'octet après chaque essai. Il vérifie aussi que `newFiche()`
  reste **SYNCHRONE** dans le cas nominal : trois harnais font `newFiche(); render();`, et le
  court-circuit sur `lib` AVANT l'`await` est ce qui le garantit.
- Vérifié : `npm run check` complet, 1176 tests × 2 moteurs, audit COMPLET 26/26 (deux passes,
  avant et après le numéro de version). CHANGELOG à 20 ([5.18.4] archivée).
