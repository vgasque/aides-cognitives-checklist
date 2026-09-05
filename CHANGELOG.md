# Journal des modifications

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

## [5.21.0] — 2026-09-01
### Six signalements d'usage : les catégories retrouvent leur bibliothèque, la main se reprend (A297-A303)

- **« Gérer les catégories » n'affichait plus rien** (A297). Deux causes empilées. (1)
  `x.onclick=openCatMgr` **en référence nue** : `openCatMgr(lib)` prend une bibliothèque depuis
  A159, il recevait donc l'**ÉVÈNEMENT de clic** comme périmètre — `_catScopeForce` valait un
  `MouseEvent`, `catsForScope` ne trouvait rien, la fenêtre s'ouvrait vide sous un en-tête
  « Catégories de la bibliothèque » sans nom. La porte du pouce (`openHomeMgr`) appelait sans
  argument : d'où le « pas sur téléphone ». Deux sites enveloppés (`paintFiltSheet`,
  `bindHomeChrome`), comme `paintMgrSheet` le faisait déjà. (2) Derrière, `activeCatScope()`
  lisait `state.scope`, que **plus rien n'écrit à l'accueil depuis la v5.18** (la colonne gauche
  filtre par `state.homeLib`) : le gestionnaire retombait toujours sur le Perso, quelle que soit
  la bibliothèque affichée.
- **Le gestionnaire montre une SECTION PAR BIBLIOTHÈQUE** (A298, décision de l'auteur : « c'est un
  vrai bug » de ne pas distinguer les catégories selon leur bibliothèque). Il suit désormais le
  filtre de la colonne ; sur « Toutes », il liste chaque périmètre administrable sous son propre
  intitulé (Perso puis chacune), avec sa palette, **ses comptes bornés à elle** (`catCount(id,
  scope)` — deux bibliothèques peuvent porter le même id), **ses cibles de déplacement bornées à
  elle** (déplacer une fiche de bibliothèque vers une catégorie du Perso serait une référence
  morte), une clé de suppression portée à `scope|id`, et **son propre « ＋ Ajouter »** — plutôt
  qu'un sélecteur de destination. Les bibliothèques en lecture seule en sont exclues (commande
  morte, règle 14).
- **Une seule rangée par nom dans la colonne gauche** (A299). Le filtre de catégorie compare par
  NOM à travers l'union depuis la v5.18 : deux homonymes de bibliothèques différentes
  produisaient **deux rangées qui filtraient exactement la même chose**, ne différant que par la
  couleur de leur pastille. Elles fusionnent (compte cumulé, cran lu sur le nom comme le filtre)
  et, quand les couleurs divergent, la **pastille les montre TOUTES** (`.cat-multi`, parts
  égales) : aucune n'est reniée. Écartés à la mesure : une seule couleur (elle mentirait sur les
  autres) et un filtre par bibliothèque (il reviendrait sur la v5.18).
- **La jauge de « Maintenir » ne s'affichait plus** dans le volet des minuteurs (A300, signalé).
  `.rt-dock .tm-btn:hover` vaut (0,3,0) et battait `.tm-reset.holding` (0,2,0) : son raccourci
  `background:` remettait `background-image` à **none** — le piège déjà nommé au bloc de survol
  nocturne. Invisible à toute sonde qui dispatche un `pointerdown` **sans déplacer le pointeur**,
  et sur iPhone le survol reste collé après le toucher, donc la jauge manquait aussi là.
  `:not(.holding)` ; vérifié au VRAI survol sur les deux moteurs (`background-image:none` avant,
  jauge à 47 % après).
- **La bordure du volet suit enfin la partie qui se déroule** (A301, signalé). Capsule et volet
  forment un objet à deux étages (mêmes bords, volet ancré au bas de la capsule, coins bas
  transférés) — mais le périmètre nocturne `--sys-edge` était posé sur `#cbTimers` seul, et le
  volet, qui ne projette pas d'ombre la nuit, n'avait **aucun bord**. Trois côtés (gauche, droite,
  bas) : le haut est la JOINTURE, où la capsule pose déjà son trait — un anneau complet doublerait
  la ligne à 2 px. Inerte le jour (`--sys-edge` transparent, le volet garde son élévation).
- **L'hôte qui coupe ne gèle plus celui qui CONDUIT** (A302, signalé). L'hôte qui a donné la main
  garde le droit d'arrêter (**propriété de la ligne, pas capacité de rôle** : `endShare`, `revoke`,
  `admit`, `setRole` passent par la RLS `owner = auth.uid()`) : son arrêt figeait l'écran de celui
  qui conduisait la checklist. Trois réponses. (1) `Share.soloLead`, décidé dans `_cycle` **à la
  transition de statut**, sur le rôle que le serveur vient de rapporter — après, on ne sonde plus :
  le lien meurt, la conduite continue, même machinerie que « Continuer seul » (rien ne part,
  `canWrite` exige `status==='active'`), bandeau qui le dit et **pas de « Rejoindre à nouveau »**,
  qui raserait le Runtime en pleine conduite. `revoked` EXCLU : couper rend d'abord la main
  (`_reclaimLead`), et c'est une décision qui concerne la personne. (2) Le dialogue d'arrêt cessait
  de dire vrai — « Votre session, elle, continue » était écrit en supposant que l'hôte conduit :
  il **nomme** désormais celui qui a la main et rappelle la porte non destructrice. (3) **« Reprendre
  la main »** : `_reclaimLead` existait **sans aucune porte**, le seul moyen de reprendre la conduite
  était de COUPER la personne. Un UPDATE de rôle, rien d'autre ne bouge. Et perdre la main
  s'annonce chez l'invité, symétrique de `takeLead`.
- **Ce qu'on déplace ne disparaît plus de l'écran** (A303, signalé). « La destination devient la
  vue » était écrit sur `state.scope`, que l'accueil ne lit plus depuis la v5.18 : la ligne était
  un **no-op** et le défaut qu'elle prévenait était revenu — filtre posé sur la bibliothèque A,
  déplacement d'une sélection vers B, **la liste tombe de deux rangées à zéro sans un mot** (mesuré
  au vrai trajet). Le filtre SUIT désormais la destination ; sur « Toutes » on n'en pose **aucun**
  (rien ne disparaît, et l'utilisateur n'a rien demandé) ; vers le Perso il suit vers Perso (`''`)
  et non vers « Toutes » (`null`). `state.cat=''` reste inconditionnel — cette moitié-là n'était
  pas morte : le déplacement invalide la catégorie.
- **Garde-fous** : deux sections neuves, chacune **vérifiée capable d'échouer** (défaut réintroduit,
  rouge exactement sur les bonnes assertions, fichier restauré à l'octet). `audit-partage`
  « l'hôte coupe, le CONDUCTEUR poursuit » (11 contrôles, trois témoins : scribe → gèle, coupé →
  gèle, promu → poursuit) et sa section « couper celui qui conduit » étendue à la feuille ;
  `audit-doctrine` « ce qu'on déplace ne disparaît pas de l'écran » (9 contrôles, trois branches).
  Un dixième contrôle est né NON DISCRIMINANT — il lisait `state.scope` en fin de parcours, où
  l'ancien code écrivait `null` de toute façon : déplacé au point où il mesure. Partage 331 → 349
  contrôles, doctrine 92 → 93 sections.
- **Signalé, non traité** (arbitrage en attente) : `state.scope` vaut toujours `null` à l'accueil,
  et six autres lecteurs s'en remettent encore à lui — `selTogHtml` et `#hdrNew` proposent
  « Sélectionner » et « Créer » sur une bibliothèque en LECTURE SEULE (commandes mortes),
  `newFiche`/`newProtocol` créent au Perso quel que soit le filtre, `impLibDefaut` propose Perso à
  l'import, le renvoi croisé de recherche sous-compte, `activeCatScope` retombe dessus en édition
  de PROTOCOLE, et la ligne « Cette bibliothèque partagée est vide » est morte (une bibliothèque
  vide n'a pas de rangée dans la colonne). Compromis assumé de ce lot : la rangée du conducteur
  porte deux boutons, donc un nom long y tronque comme il tronquait déjà sur les rangées de
  scribe — deux mises en page mesurées et écartées (elles font passer TOUTES les rangées à deux
  lignes, y compris à 430 px).
- Vérifié : `npm run check` complet, 1176 tests × 2 moteurs, audit COMPLET 26/26. CHANGELOG à 20
  ([5.18.3] archivée en fin de `docs/changelog/v5.md`).

## [5.20.9] — 2026-09-01
### La vue guidée est purgée : le journal sert tout, l'aperçu vide compris (A296)

- **Le vestige mis au jour en A295 tombe** : `navSection`, `bindNavEvents`, `renderNavOnly`, la
  mécanique `scrollNavNext`/`scrollNavIntoView`, le fil d'Ariane, `.nav-wrap`, `.flow-nav` et
  les commandes `#navNext`/`#navFwd`/`#navResume`/`#navBack`/`data-goto`/`data-crumb` ne
  servaient plus que l'aperçu d'un brouillon SANS bloc — où la vue ne rendait RIEN. Mesuré avant
  de trancher : le journal rend cette même fiche sans planter (« Parcours » vide, même chrome).
  `readModeOf` n'a plus que deux réponses, `'guided'` sort de `READ_MODES` (une ancienne
  préférence retombe sur `'overview'`), et `jumpToBlock` se décide sur `readModeOf` — au
  passage, un saut sur fiche mono-bloc rejoint le comportement du journal, la doctrine v5.6
  enfin vraie partout.
- **Purge disciplinée (règle 14)** : suppressions par pré-image vérifiée UNIQUE, épitaphe CSS au
  format exigé par `check-classes`, membres retirés des unions partagées sans toucher leurs
  frères vivants (`.opt`, `.options`, `.question`, `.arr`, `.pass-n`, `.btn.cont`, `.flow-end`,
  `.tmr-hint` — le journal et les minuteurs les émettent), harnais doctrine mis au propre. Ce
  sont les garde-fous d'A289 qui ont énuméré le CSS orphelin : une purge à moitié faite façon
  `.pl-stp` (v4.25.0) ne peut plus passer. Bilan : ~265 lignes et ~16 Ko de vue morte en moins.
  Vérifié : check complet, 1 176 tests × 2 moteurs, audit complet 26/26. Détail : A296
  (`docs/decisions/lot-v5-20.md`).

## [5.20.8] — 2026-09-01
### Le signalement d'A294, re-mesuré : un vestige, pas un trou — et le témoin qui manquait (A295)

- **Mesurer avant de corriger, et le signalement s'est dégonflé** : `#navNext` et `data-goto`
  — les deux sites sans `persistLive` d'A294 — ne vivent que dans la vue guidée, que
  `readModeOf` ne sert qu'aux fiches SANS AUCUN BLOC (l'aperçu d'un brouillon vide, fusion
  v4.16). Sondé sur fiche à blocs (journal et statique, session vive) : zéro occurrence des
  deux contrôles ; sur fiche sans bloc : aucun non plus (rien à continuer). L'implication
  décrite en A294 — l'invité qui resterait en arrière — ne pouvait pas se produire : le
  « Continuer » réel est celui du journal (`data-ovnext`), qui persiste et émet. Les deux
  `,false` tombent quand même (uniformisation, neutre par construction) ; `persist:false` ne
  reste que sur `cxGo`, qui persiste autrement.
- **La propriété qui compte gagne son témoin** : `audit-partage` § « l'avancée chez l'hôte
  ÉMET » — session réelle, bloc coché par ses vrais gestes (le cran « Continuer » est fermé
  tant que le bloc ne l'est pas, A234), base de diff remise à zéro, tap sur `data-ovnext`,
  exigence d'un évènement `nav` au fil portant le COUPLE nav/navSeq complet. Vérifié CAPABLE
  D'ÉCHOUER (méthode v4.31.1) : défaut réintroduit sur le site → rouge exactement sur
  l'assertion d'émission, l'avancée locale restant verte ; restauré à l'octet, re-vert.
  Détail : A295 (`docs/decisions/lot-v5-20.md`).

## [5.20.7] — 2026-09-01
### La quadruple mutation de navigation n'existe plus qu'une fois (A294)

- **`nav.push · navSeq.push(++seq) · navPos=bout · persistLive` survivait en clair sur huit
  sites** malgré la factorisation partielle de v5.19.4 (`ovNavPush`/`ovNavDone`, bornée au
  journal). C'est l'invariant le plus critique du mode crise : les clés de cochage valent
  `seq:idBloc:index` — un décalage nav/navSeq orpheline les coches (48 disparues en un rendu,
  le précédent documenté) — et le partage transporte le couple indissociablement (`shareFold`
  refuse des longueurs divergentes). `navAdvance(id,persist)` porte désormais la mutation
  entière ; le re-rendu, seule chose qui différait légitimement, reste chez l'appelant.
- **Ralliés à sortie identique** : `cxGo`, `cxResume`, les deux branches de `jumpToBlock`, le
  « Continuer » guidé, `data-goto`, `data-ovnext`, `svJump`. Hors motif à dessein :
  `ovNavPush`/`ovNavDone` (le journal pousse parfois deux ids avant de conclure) et la remise à
  zéro de `restartCourse` (un reset n'est pas une avancée).
- **Signalement mis au jour, comportement conservé tel quel** : le « Continuer » guidé et
  `data-goto` n'appelaient historiquement aucun `persistLive` — les deux sites portent désormais
  `persist:false` en toutes lettres, et corriger ce trou est un choix d'un caractère qui attend
  un arbitrage (il change ce qui s'écrit sur le disque à chaque « Continuer »). Détail : A294
  (`docs/decisions/lot-v5-20.md`).

## [5.20.6] — 2026-09-01
### Les commentaires longs du script suivent ceux de la feuille (A293) — le chantier d'assainissement est clos

- **Le pendant JS de la v5.20.5, plus gros gisement** : les 239 blocs de commentaires JS de PLUS
  de dix lignes (384 Ko — le JS portait 54 % de commentaires) sont repris **à l'octet** dans
  `docs/decisions/doctrine-js.md` sous les ids stables **J1…J239**, puis resserrés sur place :
  les invariants en toutes lettres (« la SEULE barrière anti-XSS », « migrate est le point
  d'ASSAINISSEMENT », « ICI, ET NULLE PART AILLEURS »…), les ⚠, les marqueurs Q/K/R/P, les
  renvois A-xxx, et « Détail : doctrine-js.md J‹n› ». Le grand commentaire d'architecture de
  tête et les 261 blocs de 7-10 lignes déjà denses ne bougent pas.
- **La différence technique avec le CSS** : un run de `//` ne se reconnaît pas à l'œil — une
  ligne commençant par `//` DANS un template literal est du code. Les blocs ont été cartographiés
  au tokeniseur d'états et le masque PROUVÉ juste avant toute édition (le script blanchi de tous
  les commentaires détectés doit compiler, `vm.Script`) ; les blocs enjambant une ligne de code
  gardent leurs délimiteurs de bord. Hashs CSP rejoués à chaque tranche (règle 3) ; les contrôles
  sensibles aux commentaires (`check-fns`, `check-actions`, `check-actest`, `check-upload`,
  `check-stores`) verts de bout en bout — aucun nom ne vivait par le seul commentaire supprimé.
- **Bilan des deux déménagements (A292 + A293)** : `index.html` passe de **2 891 à 2 440 Ko
  (−451 Ko, −15,6 %)** et de 33 874 à 29 059 lignes. Mesuré au même protocole que la phase 0 :
  boot à CPU ×6 **714 → 691 ms** (vierge) et **354 → 334 ms** (avec données) ; pleine vitesse
  103 → 99 / 57 → 51 ms (Chromium), 110 → 105 / 74 → 68 ms (WebKit) — la fraction attendue de la
  borne parse d'A289. Le chantier ouvert au rapport de phase 0 est clos ; restent en attente
  d'arbitrage les blocs de 7-10 lignes, les écrasements CSS PROBABLES, les treize factorisations
  PROBABLES et le repli `Math.random` de `uid`. Détail : A293 (`docs/decisions/lot-v5-20.md`).

## [5.20.5] — 2026-09-01
### Les commentaires longs de la feuille de style déménagent, comme AGENTS.md avant eux (A292)

- **La méthode du déménagement v5.10.3, pas celle du résumé destructeur** : les 135 blocs de
  commentaires CSS de PLUS de dix lignes (252 Ko sur les 66,6 % de commentaires que pèse la
  feuille) sont d'abord repris **à l'octet** dans `docs/decisions/doctrine-css.md`, chacun sous
  un id stable **C1…C135** — puis le commentaire en place est resserré à l'essentiel : la
  contrainte que le code ne peut pas dire, les ⚠, les renvois A-xxx, et « Détail :
  doctrine-css.md C‹n› ». Rien n'est perdu par construction ; les 19 bannières de section et les
  137 blocs de 7-10 lignes déjà denses ne bougent pas.
- **Discipline d'exécution** : aucune ligne de code CSS touchée, les épitaphes de purge (que
  `check-classes` exige) survivent dans chaque résumé, aucun résumé ne cite une couleur littérale
  ni ne contient une fermeture de commentaire en son milieu (le piège v4.74.0). Vérifié :
  135/135 renvois posés, check complet, 1 176 tests × 2 moteurs, audit complet 26/26.
- **Bilan** : `index.html` perd **~196 Ko** (2 891 → 2 695 Ko) ; l'effet au démarrage est la
  fraction correspondante de la borne parse mesurée en A289. Détail : A292
  (`docs/decisions/lot-v5-20.md`). Les commentaires JS suivent au lot suivant.

## [5.20.4] — 2026-09-01
### Soixante-quatre gardes `typeof` d'un monde révolu (A291)

- **`if(typeof Sync!=='undefined')Sync.schedule();` et ses soixante-trois cousines** — des gardes
  sur des symboles top-niveau du seul script applicatif, héritées des chantiers où `Sync`,
  `Share` ou `zoomF` n'existaient pas encore — sont purgées. L'argument est structurel, pas un
  inventaire : pour un `const` en zone morte temporelle, `typeof` LÈVE au lieu de répondre
  `'undefined'` (la garde ne pouvait pas rendre le service qu'elle affichait), et le
  run-to-completion garantit que tout gestionnaire ou timer court après l'évaluation complète du
  script. Zéro comportement changé — 1 176 tests × 2 moteurs et l'audit complet le confirment.
- **Gardés en connaissance de cause** : les vrais tests d'API sur des objets
  (`navigator.wakeLock`, `document.elementsFromPoint`, `AbortController`) et les tests de type
  sur des données ou des paramètres — eux disent quelque chose de vrai. Le repli `Math.random`
  de `uid` reste en attente d'arbitrage. Détail : A291 (`docs/decisions/lot-v5-20.md`).
