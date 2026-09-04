# Journal des modifications

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

## [5.20.3] — 2026-09-01
### La suppression de compte oubliait une clé que la déconnexion retirait (A290)

- **Un reliquat d'« éditions retenues » survivait à l'effacement TOTAL de l'appareil** :
  `wipeLocal()` (suppression de compte) et `wipeCurrentSpace()` (déconnexion en effaçant
  l'appareil) recopiaient chacun leur liste de clés locales — la seconde retirait
  `ac-held-edits`, la première non, et sa boucle générique de rattrapage exige un `@` que la
  forme nue de la clé n'a pas. Prouvé à la sonde par le vrai appel, deux moteurs : la clé nue
  SURVIT quand tout le reste part.
- **Correctif structurel, pas une ligne dans une liste** : `WIPE_SPACE_KEYS`, liste UNIQUE des
  clés d'espace, consommée par les deux effacements (`wipeLocal` y concatène ses extras
  d'appareil). Une liste recopiée diverge, une liste unique non — même remède que `MUTE_SEL`
  (v4.4.2) et `SHARE_KINDS` (A216). Rouge→vert rejoué à la sonde après correctif. Détail : A290
  (`docs/decisions/lot-v5-20.md`).

## [5.20.2] — 2026-09-01
### Assainissement mesuré : trois garde-fous nés rouges, purges prouvées, vingt factorisations (A289)

- **Trois trous de garde-fous fermés, chacun PROUVÉ né ROUGE** sur l'état d'avant correctif :
  `check-fns` détecte les `let` top-niveau écrits mais jamais LUS (deux vivaient ainsi, dont un
  au commentaire décrivant une comparaison jamais écrite) ; `check-ids` gagne le sens « id émis →
  lu » — **20 croix de fermeture de modales** portaient un id que rien ne lisait (le câblage
  passe par `.ai-x`), dont une née en v5.20.0 PENDANT l'inventaire même ; `check-icons` gagne la
  passe « entrée de table jamais citée » — trois en-têtes (`h-main`, `h-img`, `h-forget`)
  vivaient en fantômes (dictionnaire + CSS + un commentaire, zéro émission).
- **Code mort purgé au grep** (règle 14, zéro citation restante) : douze purges CSS (`.tag.draft`,
  `.pl-lnk.loop`, cinq états de `.pc-card`, `.blk-type.steps/.decision`, `.hs-row.hs-cmd`, la
  famille `h-*`, quatre écrasements dont un `gap:10px` écrasé par la ligne ADJACENTE, trois
  copies de palier strictement incluses — la copie du « dix-neuvième piège de cascade » est
  GARDÉE, son ordre est sa raison d'être) ; côté JS `flowCtx.curId` (7 écritures, 0 lecture),
  les 20 ids, quatre commentaires menteurs. Faux positifs écartés avec preuve (FLOWK destructuré,
  POSO_SYN indexé dynamiquement).
- **Vingt factorisations à sortie identique** — les invariants que la doctrine énonçait sans les
  tenir n'existent plus qu'une fois : récepteur de fontaine optique (la plus grosse zone
  dupliquée du fichier, sa divergence de ré-armement neutralisée), fermetures mémoire de la
  synchro (« ne jamais ré-insérer un supprimé » vivait en six copies), cœur de cochage
  local/distant, tri unique de l'accueil, gestes communs de « Consulter », empreinte SHA-256 de
  protocole, « pli neuf » de l'invité identique sur ses deux portes, marquage des préférences
  (six copies qui se citaient l'une l'autre en commentaire) ; deux fetch bornés artisanaux
  passent par `acFetch`.
- **Le ✓ de « Quand l'utiliser » retrouve son vert** : la règle `:not(.cur):not(.done)` pesait
  (0,4,0) avec deux états MORTS et écrasait `.pc-n.ok` — badge sur fond neutre, encre grise,
  prouvé à la sonde par le vrai chemin (session → Tout voir → Parcours) sur deux moteurs, avant
  et après correctif (fond `--ok`, encre `--on-primary` désormais).
- **Verdict performance, chiffré pour ne plus y revenir** : le boot est dominé par le PARSE
  (510 ms sur 673 à CPU ×6 ; le JS applicatif pèse ~40 ms), les interactions tiennent en
  10-16 ms même bridées, +0 écouteur par coche, timers déjà gatés — rien à optimiser ; le seul
  levier mesurable est la masse de commentaires (55,6 % du fichier), chantier documentaire à
  arbitrer séparément. Détail complet : A289 (`docs/decisions/lot-v5-20.md`).

## [5.20.1] — 2026-09-01
### En voie large, l'accueil repartait de zéro à chaque re-rendu (A288)

- **« On ne revient pas au scroll initial, on revient en haut de la page »** (A288, signalé à
  l'usage après le ✎ *modifier bibliothèque* pris dans la LISTE de cartes). Le ✎ n'y est pour
  rien : c'est la fermeture qui, après un enregistrement de nom, re-rend l'accueil. Or à partir de
  780 px la page ne défile plus — ce sont `.home-main` (la liste) et `.hs-scroll` (les catégories
  de la colonne gauche) qui portent le défilement, et tous deux sont **reconstruits** par
  `main.innerHTML`. Mesuré : **600 → 0** pour la liste, **80 → 0** pour la colonne, à CHAQUE
  re-rendu — donc aussi en épinglant, en filtrant, en cochant. En voie étroite le défileur est la
  page, que le navigateur ne bouge pas : le même geste n'avait donc pas le même effet à 390 et à
  1280, et c'est cette asymétrie qui tranchait la question.
- **Correctif au patron de `.read-side`** (v4.23.5, même défaut sur le rail de lecture) : capture
  avant, restauration après, **bornée au nouveau contenu** — une liste raccourcie par un filtre ne
  doit pas poser hors borne. La mémoire par section de `setSection` l'emporte toujours : deux
  crans ne partagent pas une position.
- **Un piège de mesure évité en route** (famille A267) : la première sonde interrogeait le nœud
  capturé AVANT le re-rendu — donc un nœud DÉTACHÉ, qui répond 0 quoi qu'il arrive, et qui aurait
  affiché « rouge » même une fois le défaut corrigé. Le défaut a été re-mesuré avec une sonde qui
  re-interroge le document ; le témoin (`audit-doctrine`, « le défilement survit au re-rendu »)
  couvre les deux défileurs ET le geste signalé par son vrai chemin, et il est né ROUGE.

## [5.20.0] — 2026-09-01
### Le rail A→Z posait sa lettre sous ce qui coiffe l'écran ; la gestion descend au pouce (A286-A287)

- **Le premier résultat de la lettre était masqué** (A286, signalé à l'usage : « depuis la refonte
  de l'en-tête, le scroll s'affiche mal — le premier résultat de la lettre est masqué »). C'est un
  reste de la v5.18 : l'en-tête d'accueil y est devenu STATIQUE, la cible du saut a donc cessé de
  soustraire quoi que ce soit — mais DEUX objets coiffent encore le haut du défileur. La **barre
  de sélection** (collante à 0) avalait l'intertitre entier et **17 px de la première rangée** ;
  la **bande de zone sûre** de l'iPhone installé — posée dans ce même lot v5.18 pour que rien ne
  défile sous l'heure — faisait s'épingler l'intertitre à 47 px, où il recouvrait la rangée qu'il
  annonce (**39 px de 60 mesurés**). La cible ôte désormais cette coiffe, LUE au moment du saut et
  jamais écrite en constante ; équivalence prouvée au pixel là où rien ne coiffe, en voie étroite
  comme en voie large, sur les deux moteurs.
- **Pourquoi vingt et un harnais ne voyaient rien, et ce qui change** : `env(safe-area-inset-top)`
  vaut 0 dans un navigateur — la moitié du défaut n'existait que sur un appareil INSTALLÉ, l'autre
  demandait le mode sélection, qu'aucune sonde du rail n'activait. Le témoin (`audit-doctrine`,
  « le rail A→Z pose sous ce qui coiffe ») joue trois cas — nominal, sélection, **encoche
  simulée** par un littéral de 47 px — et il est né ROUGE sur les trois assertions qu'il fallait.
- **Gérer les catégories et les bibliothèques, sans colonne gauche** (A287, signalé à l'usage :
  « sur smartphone il n'y a pas de sidebar : je ne peux plus gérer les catégories, et les
  bibliothèques je ne peux les gérer qu'en vue *Rangé par bibliothèque* »). Sous 780 px, « Gérer
  les catégories » n'était atteignable QUE par la feuille de filtres, dont le déclencheur n'existe
  que pendant une recherche ; et le ✎ d'une bibliothèque administrée ne paraît que sur
  l'intertitre de section, donc dans un rangement sur trois. Une **rangée au socle**, masquée
  ≥ 780 px où la colonne gauche reprend la main — même patron et même cause que « Rejoindre une
  session » (v5.14.3). Elle **n'invente aucune fenêtre** : mêmes rangées, mêmes attributs, mêmes
  lecteurs que la colonne (`#catModal`, `#membersModal`, `#newLibModal`). Le socle n'ouvre jamais
  une feuille d'UNE rangée — sans bibliothèque à administrer, elle dit « Gérer les catégories » et
  va droit au gestionnaire ; et l'on ne liste que ce qui se gère (une bibliothèque en lecture
  seule serait une commande morte, règle 14). La feuille entre dans les surfaces d'`audit-a11y`
  par son vrai point d'entrée.

## [5.19.6] — 2026-08-31
### L'anneau de focus repris par un `#id` : une propriété corrigée, deux trous fermés (A285)

- **Un `#id` reprenait EN SILENCE la respiration d'A268** (A285, signalé sur capture : « la
  bordure du bouton *Tout* est toujours coupée par la fenêtre »). La feuille de filtres portait
  depuis la v5.6 `#filtSheetBody{padding:0 0 4px}` : un `#id` l'emporte sur `.ai-card>.ai-body`,
  et le RACCOURCI `padding` remettait l'axe inline à zéro — en laissant vivre la marge négative,
  qui dès lors ne compensait plus rien. Résultat PIRE que l'état d'avant A268 : chips 4 px à
  gauche du titre, pile sur la découpe, anneau de focus rasé. Mesuré : garde gauche 0 px pour
  « Tout », « Toutes » et « Gérer », contre 3,9 px dans les seize autres corps de fenêtre.
  Correctif d'une propriété : `padding-block:0 4px` — on n'écrit que l'axe qu'on règle, l'axe
  inline reste à la règle commune ; effet second voulu, les chips s'alignent enfin sur le titre.
- **Le trou de cascade se ferme en garde-fou** : `check-ring.mjs` (dans `npm run check`, donc en
  CI) lit les corps de fenêtre dans la coque — jamais une liste tenue à la main — et refuse toute
  règle qui les CIBLE par leur `#id` en posant une respiration inline < 4 px (les règles visant
  un DESCENDANT ne sont pas concernées). Né ROUGE sur l'état d'avant correctif.
- **Le trou de couverture aussi** : la feuille de filtres n'était ouverte par AUCUNE des
  vingt-cinq surfaces d'`audit-a11y` — c'est ce qui a laissé sept mois au défaut. Elle entre au
  balayage par son VRAI point d'entrée (`#filtTog`, qui n'existe que pendant une recherche) :
  conforme aux deux thèmes du premier coup. Leçon v4.75.0 redite au prix fort : un défaut hors
  périmètre n'est pas un défaut absent.

## [5.19.5] — 2026-08-31
### Les mineurs de l'audit : la rangée d'éditeur suit la largeur effective, la doctrine se navigue (A284)

- **La chaîne de compression de la rangée d'éditeur (640→430→360) passe aux paliers `zw`**
  (A284). Mesuré sous zoom texte 130 % : la recette anti-chevauchement des halos ne
  s'appliquait pas à largeur EFFECTIVE < 430 (le tap partait au dernier élément du DOM) et
  « Aperçu » restait en toutes lettres là où l'icône s'imposait. Équivalence exacte à zoom 1
  prouvée aux quatre témoins (620/420/350/700 px), deux moteurs — et le piège de mesure A267
  évité en route (un « débordement de 161 px » qui n'était qu'un artefact de repère visuel).
  Les quatre paliers de composition restants ne se convertissent pas d'office : arbitrage
  écrit dans A284.
- **`Share` et `Sync` se naviguent** : quatorze sous-bannières `/* ===== … ===== */` aux
  frontières logiques des deux modules (cadence, PULL, PUSH, annexes ; horloge, émission,
  cycle, application, gestes hôte/invité, passation, fins) — la commande d'index du
  monofichier les liste désormais. Aucun code déplacé.
- **`GUIDELINES.md` relu** (il l'exigeait lui-même) : les principes tiennent, une note datée
  renvoie les quatre surfaces refondues (accueil v5.18, colonne/pied v5.19, barres v5.15,
  sélection v5.17) vers leurs lots ; `design/README` corrige ses fiches « ~275 Ko » (réel :
  ~815) et consigne les deux `git gc`.

## [5.19.4] — 2026-08-31
### Phase 3 de l'audit : trois garde-fous nouveaux, le pli QR assaini, cinq duplications factorisées (A283)

- **Trois trous de l'audit fermés en garde-fous**, chacun né ROUGE sur défaut fabriqué puis
  restauré à l'octet : `check-tokens` (token CSS déclaré ↔ lu, le trou du survol `--hover`),
  `check-ids` sens inverse (sélecteur `#id` stylé → émis, le trou de `#f-validation`),
  `check-fns` (déclaration top-niveau → citée ailleurs, le trou de `catsUtiles`). Les
  commentaires sont dépouillés d'abord (`strip-comments.mjs`, source unique) — un nom cité
  dans la doctrine n'est pas un usage. **`check-fns` a attrapé un 4ᵉ mort dès sa naissance**
  (`enLigneOk`, locale jamais lue), supprimé.
- **Le pli reçu par QR passe par `slFoldSan`** — c'était le seul intrant distant pris brut :
  grammaires du chemin en ligne (shareNavNorm, vfMapNorm, tkRefNorm), bornes de
  sanitizeSession, liste fermée (un miroir ne réécrit rien), témoin dans tests.html (+7
  assertions, aucun label d'évènement ne traverse — règle 15). `ltSnapUnpack` décompresse
  borné à 4 Mo (le flux s'annule, comme `inflateBounded`).
- **Durcissements** : la purge des caches du SW se limite au préfixe `aides-cognitives-`
  (l'origine n'est pas le scope — un déploiement intranet en sous-répertoire n'effacera pas
  les PWA voisines) ; `esc()` rejoint les six sites d'id qui y avaient échappé (couverts par
  safeId en amont, mais la règle v5.10.2 « échapper au site » y était cassée).
- **Cinq duplications factorisées, comportement identique** : renommage inline
  minuteur/compteur (jumeaux), `selBounds` (×3), `slBusySheet` (refus « partage déjà actif »
  ×2), `attInfoFor` (×2), `ovNavPush`/`ovNavDone` (queue de navigation ×2).
- **Piège découvert et fermé en route** : deux commentaires JS citent `<style>` sans
  fermeture — sur le fichier brut, ils s'appariaient de travers avec tout bloc ajouté plus
  bas ; l'appariement des blocs se fait désormais commentaires retirés.
- Les cinq fonctions de test embarquées et les deux surfaces de harnais portent leur marqueur
  « délibéré » (décision Q3) — un futur audit ne les re-signalera pas.
