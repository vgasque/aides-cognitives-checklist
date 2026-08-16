# Journal des modifications

## [5.12.8] — 2026-08-16
### Le décalage du clavier n'était ni trop suivi ni trop gelé : il était déphasé

- **Une vidéo de l'auteur a tranché** — la première preuve directe de cette série, et elle montre
  les deux symptômes à **0,6 seconde d'intervalle** sur le même geste (recherche dans une
  référence, clavier ouvert, iPad) :
  - **t = 4,4 s** — l'en-tête a **complètement disparu**, le contenu monte sous la barre du
    navigateur : le décalage n'était **pas encore** appliqué ;
  - **t = 5,0 s** — l'en-tête est **poussé vers le bas**, avec du contenu visible **au-dessus** de
    lui : le décalage était appliqué alors qu'il n'était **déjà plus** bon.
- Ce n'était donc ni « trop suivre » (v5.12.0) ni « trop geler » (v5.12.5) : c'était **déphasé**.
  Le délai de repos de 180 ms introduit en v5.12.7 produisait les **deux** symptômes tour à tour.
  Une couche calée sur le viewport visuel doit se recaler **à l'instant exact où il bouge** — il
  n'y a pas de bon délai, il n'y a que le bon moment. Le décalage s'applique désormais sans aucun
  différé.
- **Ce qui reste, et qui n'était pas en cause** : la garde du clavier (v5.12.5) — sans clavier,
  aucun décalage n'est retenu, donc le rebond élastique de fin de course ne déplace rien ; et le
  compte d'occurrences à chasse fixe (v5.12.6), qui empêchait le bouton « › » de se dérober sous
  le doigt.
- `npm run check` 20/20, `npm test` 2×1126, audit COMPLET 25/25 ; les cinq sondes de la série
  restent vertes. ⚠ Ce réglage ne se juge que sur appareil : le harnais ne pilote pas
  `visualViewport`. C'est précisément pourquoi la vidéo valait trois versions de tâtonnement — et
  la leçon est consignée (A188) : **quand un instrument ne peut pas voir le défaut, demander une
  trace plutôt que d'itérer à l'aveugle.**

## [5.12.7] — 2026-08-16
### Le chrome suit le clavier — mais il se pose, au lieu de tout suivre ou de tout geler

- **Il ne s'affichait toujours pas au premier résultat d'une recherche, clavier ouvert** (signalé à
  l'usage). Ma v5.12.5 gelait **trop** : `--vvt` n'était relue qu'au changement de **hauteur** du
  viewport visuel — or le panoramique du clavier arrive **après** son ouverture, pas avec elle. Le
  décalage retenu était donc celui de l'instant du redimensionnement, c'est-à-dire **zéro**, et le
  chrome restait hors de l'écran tant qu'aucune autre ouverture ou fermeture ne survenait.
- **Deux modes de défaillance opposés, et la frontière était mal placée.** Tout suivre (v5.12.0)
  faisait sauter le chrome à chaque saut d'occurrence, parce que le système re-panoramique pour
  garder le champ focalisé sous les yeux ; tout geler (v5.12.5) le laissait hors de l'écran au
  premier résultat. La bonne frontière n'est ni « toujours » ni « jamais » : c'est **quand ça s'est
  arrêté de bouger**. Un changement de hauteur (le clavier s'ouvre ou se ferme) s'applique
  immédiatement — c'est un fait accompli. Un changement de décalage seul attend un court repos :
  une rafale de sauts d'occurrence ne produit alors qu'**un** recalage, à la fin, au lieu d'un par
  clic.
- C'est la version « qui se pose » de la règle du dossier (*une géométrie de chrome ne se dérive
  pas d'un état transitoire*, v5.0.9) : on ne refuse plus l'information, on attend qu'elle soit
  stable.
- `npm run check` 20/20, `npm test` 2×1126, audit COMPLET 25/25 ; les cinq sondes de la série
  restent vertes. ⚠ Limite inchangée et redite : le harnais ne peut pas piloter
  `visualViewport.offsetTop` — il mesure le câblage et la géométrie, jamais la réaction d'iOS. Ce
  réglage-là se juge sur appareil.

## [5.12.6] — 2026-08-16
### Le bouton « › » ne se dérobe plus sous le doigt, et un double-tap ne sélectionne plus le texte

- **Le saut résiduel n'était pas le chrome : c'était le bouton lui-même** (signalé à l'usage : « ça
  saute moins mais encore un peu »). Mesuré sur douze sauts d'affilée : la largeur du compte
  d'occurrences prend **neuf valeurs distinctes** (27,1 → 34,3 px) — les chiffres n'ont pas la même
  chasse, et « 10 / 70 » est plus long que « 9 / 70 » — si bien que le bouton « › » **se déplaçait
  de 7 px à chaque clic**, c'est-à-dire sous le doigt qui le vise. Chiffres à chasse fixe et
  largeur minimale : après correctif, **une** seule largeur, **une** seule position, sur les mêmes
  douze sauts et aux deux moteurs.
- **Un double-tap sur un contrôle est un geste, pas une intention de lire** (« empêche sélection de
  texte en appuyant sur les boutons ‹ et › »). La navigation d'occurrences ne se sélectionne plus —
  même idiome que le rail A→Z, qui le fait depuis toujours pour la même raison. Les titres
  repliables des références suivent : on les tape aussi plusieurs fois de suite.
- `npm run check` 20/20, `npm test` 2×1126, audit COMPLET 25/25 ; les cinq sondes de la série
  restent vertes.

## [5.12.5] — 2026-08-16
### Le chrome ne saute plus quand on parcourt les occurrences — une géométrie de chrome ne se dérive pas du défilement

- **L'en-tête et la sidebar sautaient à chaque clic sur ‹ / ›** (signalé à l'usage). Le harnais ne
  reproduit rien sur ordinateur : à 1280 px, vingt-six sauts d'occurrence, l'en-tête reste à 0, la
  colonne à 69, `--hdr-h` et `--stick-top` constants. C'est donc **le clavier**. Ouvert, chaque
  défilement programmatique fait **re-panoramiquer** le viewport visuel pour garder le champ
  focalisé sous les yeux : `offsetTop` change à chaque saut, et le chrome — qui le suit depuis la
  v5.12.0 — sautait avec lui.
- **La règle existait déjà dans ce dossier, une famille plus loin** : *une géométrie de chrome ne
  se dérive jamais d'un état qui dépend du défilement* (v5.0.9, puis le rail A→Z en v5.6, dont le
  haut est mesuré puis **gelé** pour exactement la même raison — sinon ses lettres bougent sous le
  doigt). Le décalage se relit donc quand la **hauteur** du viewport visuel change — c'est-à-dire
  quand le clavier s'ouvre, se ferme ou change de taille — et reste **gelé** entre deux. Le chrome
  est immobile pendant qu'on parcourt les occurrences.
- **Ce que ça coûte, et c'est dit** : si le système re-panoramique sans changer la hauteur (passer
  le focus à un champ plus bas, clavier déjà ouvert), le chrome garde le décalage du dernier
  évènement de hauteur. Le bon compromis : ce cas laisse le chrome à quelques dizaines de pixels
  près, quand l'ancien comportement le faisait sauter à **chaque** geste de lecture.
- Les cinq sondes de la série restent vertes aux deux moteurs (chrome collant, coque large, colonne
  sommaire, croix, navigation d'occurrences) ; `npm run check` 20/20, `npm test` 2×1126, audit
  COMPLET 25/25. ⚠ Comme pour toute la série `--vvt` : le comportement **sous vrai clavier iOS** ne
  se vérifie que sur appareil — le harnais mesure le câblage et la géométrie, pas la réaction du
  système.

## [5.12.4] — 2026-08-16
### La croix d'effacement cesse de bouger avec ce qu'on tape

- **Elle était trop basse, trop à droite — et elle se déplaçait pendant la frappe** (signalé à
  l'usage, deux fois : « pas centrée ni verticalement ni horizontalement », puis « en fait change
  de position en fonction de ce qu'on écrit »). Une seule cause : je l'avais centrée sur le
  **conteneur** du champ, et ce conteneur est une colonne qui **grandit avec ce qu'on tape** — la
  navigation d'occurrences puis les documents trouvés s'y ajoutent. Mesuré : 52 px à vide, 88 px
  dès la première occurrence, donc une croix qui descend de 14 px à la deuxième lettre ; et son
  bord droit dépassait de 2 px celui du champ, le conteneur ayant 8 px de rembourrage que le champ
  n'a pas.
- **Le repère doit être le champ, jamais ce qui l'entoure.** La croix a désormais sa propre boîte,
  qui n'enveloppe que l'input : centrée dessus une fois pour toutes, à 6 px de son bord droit —
  la même géométrie que la croix de l'accueil, dont elle est déjà le composant.
- Mesuré aux deux moteurs et aux deux largeurs, sur les quatre états successifs d'une frappe
  (une lettre, des résultats, zéro résultat, des résultats à nouveau) : écart vertical **0**,
  écart droit **6 px**, position **identique** dans les quatre. Cible tactile 44 px conservée (ce
  champ vit aussi dans la feuille « Toute la fiche » du mode crise).
- Note de méthode : mes premiers témoins mesuraient le centrage **contre le conteneur** — ils
  étaient donc verts sur le défaut même qu'ils prétendaient couvrir. Un témoin doit mesurer contre
  la référence que l'œil utilise, pas contre la boîte la plus facile à interroger.

## [5.12.3] — 2026-08-16
### La colonne sommaire suit le clavier, elle aussi — la même faute, une famille plus loin

- **La sidebar ne suivait pas** (signalé à l'usage : « lorsqu'on est en haut de page et qu'on doit
  scroller en bas avec le mode recherche — défilement automatique à la 1ʳᵉ occurrence — la sidebar
  ne suit pas »). Mesuré : la colonne suit parfaitement… **clavier fermé**. Or on est en train de
  taper dans son champ de recherche, donc le clavier est ouvert — et elle s'ancre sur
  **`--stick-top`**, un SECOND token que le garde-fou de la v5.12.1 ne surveillait pas.
- **Deux tokens d'ancrage existaient, je n'en avais corrigé qu'un.** `--hdr-h` (l'en-tête seul) et
  `--stick-top` (toute la pile collante, quai de crise compris). Les **cinq** colonnes ancrées sur
  le second — sommaire d'une référence, rail de lecture, plan de l'aide — ont donc continué de
  disparaître clavier ouvert pendant une version de plus. `--stick-off` est leur origine ;
  `--stick-top` reste la **hauteur** qu'il a toujours été (une hauteur ne se décale pas, seule une
  origine le fait — les mélanger raccourcirait les colonnes en plus de les déplacer).
- **Le garde-fou surveille désormais les deux**, et il a immédiatement attrapé un **sixième site**
  que je n'avais pas vu : le volet du quai de crise, qui s'ouvrait hors de l'écran clavier ouvert.
  Neuf couches contrôlées, une exemption motivée. Vérifié capable d'échouer sur le nouveau token.
- Le **rembourrage de défilement** (`scroll-padding-top`) suit la même origine : c'est lui qui
  décide où atterrit un `scrollIntoView` — donc exactement le geste signalé.
- Mesuré aux deux moteurs : après le saut à la 1ʳᵉ occurrence la colonne est à 69 px ; à 370 px de
  panoramique elle passe à 439, et le champ de recherche reste dans la zone visible. Hors clavier,
  géométrie identique à l'octet. `npm run check` 20/20, `npm test` 2×1126, audit COMPLET 25/25.

## [5.12.2] — 2026-08-16
### L'en-tête cesse de sauter au défilement, et l'accueil large suit enfin le clavier

- **L'en-tête sautait au défilement, et la page continuait de descendre en fin de course**
  (signalé à l'usage, sur téléphone, tablette ET ordinateur, en portrait comme en paysage). C'est
  une **régression de la v5.12.0**, et elle mérite d'être nommée : en rendant le chrome collant
  tributaire de `--vvt`, je l'ai rendu tributaire d'une valeur **qui n'est pas stable pendant le
  défilement**. `visualViewport.offsetTop` devient non nul pendant le rebond élastique de fin de
  course et pendant un pincement, **sans qu'aucun clavier ne soit ouvert** : l'en-tête suivait ces
  micro-décalages, donc il sautait, et il descendait avec le rebond.
- **La garde est la définition même du cas à couvrir** : un clavier **occupe de la hauteur**. Le
  panoramique n'est retenu que si le viewport visuel est réellement plus **court** que celui de
  mise en page ; un panoramique sans rétrécissement n'est pas un clavier, c'est un artefact de
  geste. Le seuil (60 px) est sous toute barre d'accessoires de clavier et très au-dessus de
  l'amplitude d'un rebond, qui ne rétrécit rien. C'est le pendant exact de la garde d'`unpan()`
  (v5.10.4), qui refuse d'agir tant qu'un champ est focalisé — les deux décrivent la même
  frontière, chacune de son côté.
- **En accueil large, la barre de recherche ne suivait toujours pas** (« ça fonctionne mieux quand
  elle est dans l'en-tête, mais quand elle est dans la sidebar elle ne suit pas »). Le correctif de
  la v5.12.0 déplaçait des couches **collantes** ; là il n'y en a aucune — la coque est de hauteur
  fixe (`100dvh`) et les colonnes défilent dedans. Or `dvh` **ne rétrécit pas** quand le clavier
  s'ouvre : il suit le chrome du navigateur, pas le clavier. Le cadre restait donc à pleine
  hauteur, le clavier en recouvrait le bas, et le panoramique emportait le haut hors de l'écran.
  La coque se borne désormais à la hauteur **réellement visible** et descend du panoramique : elle
  occupe exactement le rectangle visible, ses colonnes défilent dedans comme avant. Mesuré : zone
  visible de 440 px commençant 394 px plus bas → coque de 440 px à 394, champ de recherche à 407,
  donc dedans.
- Hors clavier, les deux règles sont **à l'octet** celles d'avant : `--vvt` vaut 0 et `--vvh`
  retombe sur `100dvh`. Sondes 6/6 (coque) et 5/5 (chrome collant) aux deux moteurs ;
  `npm run check` 20/20, `npm test` 2×1126, audit COMPLET 25/25.
- Note de méthode, pour la prochaine fois : la constante de garde a d'abord été **référencée sans
  être déclarée** — `npm run check` restait **vert** (une `ReferenceError` n'est pas une erreur de
  syntaxe) et l'application ne démarrait plus. C'est `npm test` qui l'attrape, comme il attrape le
  piège des hashs CSP : une porte statique ne remplace pas un démarrage réel.

## [5.12.1] — 2026-08-16
### La barre de recherche d'une référence suit le clavier, elle aussi — et la règle cesse d'être tenue à la main

- **`#refBar` restait en arrière** (signalé à l'usage : « l'en-tête apparaît maintenant mais pas le
  bandeau recherche sur iPad/iPhone »). La v5.12.0 a fait suivre le viewport visuel au chrome
  collant — clavier ouvert, un `sticky` calé sur le viewport de **mise en page** passe au-dessus de
  l'écran — mais le décalage « sous l'en-tête » était **recopié dans cinq règles** et je n'en avais
  corrigé que trois. La barre de recherche d'une référence est restée sur l'ancien calcul, et
  continuait donc de disparaître exactement dans le cas qu'on venait de réparer.
- **Un token, un seul lecteur par site** : `--hdr-off` porte la hauteur de l'en-tête **et** le
  décalage du viewport visuel ; les cinq règles le lisent. Mesuré : à 370 px de panoramique,
  l'en-tête passe de 0 à 370 et la barre de recherche de 61 à 431 — elles restent solidaires.
- **Et la règle devient auto-exécutoire** (`check-stick.mjs`, dix-neuvième garde-fou) : aucune
  propriété `top` ne peut s'ancrer sur la hauteur de l'en-tête sans tenir compte du clavier. C'est
  la faute que ce dépôt paie le plus souvent et qu'il a déjà nommée ailleurs (MUTE_SEL, la table
  MIME des harnais) — une règle répartie dans *n* sites finit corrigée dans *n*−2, en silence.
  Vérifié capable d'échouer : la règle remise dans son état d'avant fait rougir le contrôle, qui la
  nomme.
- Une **exemption nommée et motivée** : le rail A→Z. Son haut est mesuré puis **gelé** (v5.6 — une
  géométrie de chrome ne se dérive jamais d'un état qui dépend du défilement, sinon ses lettres,
  qui sont centrées, se déplacent de 26 px sous le doigt). Lui faire suivre le viewport déplacerait
  son haut sans son bas : un demi-correctif pire que le défaut, et le cas ne se rencontre pas —
  clavier ouvert, on tape dans la recherche, on ne vise pas une lettre du rail.

## [5.12.0] — 2026-08-16
### Agir sur plusieurs fiches d'un geste, et replier un long document

- **Sélection multiple dans la bibliothèque** (demande de l'auteur). « ⊞ Sélectionner » ouvre un
  mode où l'on coche des rangées — l'appui long sur une rangée y mène aussi — puis **Déplacer…**
  (vers une autre bibliothèque), **Ranger…** (dans une catégorie) et **Supprimer…**. Chacun de ces
  gestes coûtait jusqu'ici un aller-retour PAR FICHE, et le seul recours après un import raté était
  de supprimer une par une. Le déclencheur vit dans la **rangée A–Z / Catégories**, pas dans
  l'en-tête (« l'en-tête est déjà saturé ») ; en sélection cette rangée s'efface, avec les notices
  et les cartes de session vive — on ne re-range pas pendant qu'on coche.
- **Trois garde-fous qui ne se négocient pas** : le mode **ne survit pas à l'accueil** (l'accueil
  est aussi l'écran qu'on ouvre en urgence) et se ferme quand on change de bibliothèque ; **on ne
  coche que ce qu'on peut modifier** — sur une bibliothèque dont on est lecteur, le déclencheur
  n'existe pas ; **« Ranger » se ferme** quand les éléments cochés ne partagent pas une
  bibliothèque, et dit pourquoi — un id de catégorie n'a de sens que dans la sienne.
- **La suppression en lot fait LIRE** (décision de l'auteur : confirmation forte). La fenêtre
  **énumère les titres** qui vont disparaître, signale ceux qui sont dans une bibliothèque partagée,
  et le bouton reste **fermé** tant que « J'ai lu cette liste » n'est pas coché. Un nombre à
  retaper se tape sans regarder ce qu'il compte ; un mot à recopier se recopie de même.
- **Titres H1/H2/H3 repliables dans une référence** (demande de l'auteur), avec « Tout replier /
  Tout déplier » dans l'en-tête du sommaire. Replier un H1 emporte ses H2 et H3 ; un titre sans
  corps n'est pas repliable. **Les replis sont mémorisés par protocole** — mais dans une préférence
  LOCALE, jamais dans le document : ils n'ont rien à faire dans ce qu'on partage, exporte et
  synchronise. La clé est le **titre**, pas son rang, pour survivre à une insertion ailleurs. Le
  sommaire et la recherche **ouvrent ce qu'ils visent** (un résultat dans une section repliée est
  invisible ; un sommaire qui mène à un titre sans son corps ne mène nulle part). Sur papier, tout
  se déploie. Le titre **reste un titre** : le bouton vit dedans, pour ne pas lui retirer sa
  sémantique au moment précis où l'on ajoute une raison de s'en servir.
- **Recherche dans une référence** : une **croix** efface le champ, retire les surlignages et rend
  le sommaire — c'est celle de l'accueil, pas un second dessin. Et **le sommaire s'efface dès la
  première lettre** : sommaire et résultats répondent à la même question et se contredisent à
  l'écran ; ne l'escamoter que sur résultat le faisait réapparaître entre deux frappes, et le
  contenu sautait à chaque lettre.
- **L'en-tête ne se perd plus quand le clavier s'ouvre** (signalé à l'usage). Même cause que les
  fenêtres coupées de la v5.10.9, que j'y avais explicitement laissée hors de portée : ouvrir le
  clavier panoramique le viewport visuel dans le viewport de mise en page, et un `sticky` calé sur
  le second passe au-dessus de l'écran — on perdait la barre de recherche au moment précis où l'on
  tape dedans. `header.bar` et ce qui colle sous lui suivent désormais `--vvt`.
- Sous le capot, quatre choses apprises **à la mesure**, consignées avec ce qu'elles corrigent
  (`docs/decisions/lot-v5-12.md`, A170-A179) : un `sticky` se règle sur **son** défileur et
  l'accueil en a deux (128 px de vide mesurés à 1194 px) ; une marge négative ne rattrape pas le
  rembourrage d'un défileur ; un `z-index` ne compare que des frères de **contexte** (la barre
  `sticky` en créait un et enfermait le menu sous le rail A–Z) ; et une coche glissée dans une
  grille à deux pistes ouvre un fossé qui grandit avec la carte. Une case grisée « lecture seule »
  que j'avais dessinée a été **retirée** : la sonde a prouvé qu'aucun écran ne peut l'atteindre.
- Sondes jetables 29/29 (sélection) et 43/43 (repli), aux deux moteurs et aux deux largeurs,
  vérifiées capables d'échouer ; `npm run check` 19/19, `npm test` 2×1126, audit COMPLET 25/25 —
  dont un rouge attrapé au passage : la nouvelle croix faisait 38 px pour un seuil de 44 sur une
  surface de crise.

## [5.11.1] — 2026-08-16
### La pastille de destination dit le mot « catégorie » — un verbe ne désigne pas son objet

- **« Garder Réanimation » ne disait pas ce qu'on gardait** (signalé à l'usage : « "Garder" pas
  suffisamment clair pour dire qu'on parle de la catégorie »). Le libellé NOMMAIT bien la valeur —
  l'exigence tenue en A83 — mais laissait le CHAMP à deviner : posé à côté d'une pastille
  « Perso », il pouvait se lire comme « garder cette fiche ». Les quatre états de la pastille
  portent désormais le nom du champ : **« Catégorie du fichier : Réanimation »** (défaut, quand le
  fichier classe l'entité), **« Catégorie du fichier : aucune »** (défaut, quand il ne la classe
  pas), **« Catégorie : Réanimation »** (choix explicite, avec sa pastille de couleur) et **« Sans
  catégorie »**. La provenance reste dite — « du fichier » signifie que rien n'a été décidé à votre
  place. Le menu suit : « Garder **la catégorie** du fichier ».
- **Et le bandeau ne dit plus deux fois « Plusieurs »** : ses deux pastilles étant côte à côte, un
  même mot sur les deux ne se distinguait pas. Elles nomment leur champ dans tous leurs états —
  « Plusieurs bibliothèques » / « Plusieurs catégories », et « Catégorie du fichier » sans nom pour
  le défaut commun (le bandeau commande plusieurs rangées, chacune garde la sienne : c'est la
  rangée qui la nomme).
- Le **titre au survol prolonge** le libellé au lieu de le répéter (plus de « Catégorie de
  destination : Catégorie du fichier : X ») : il dit ce que le geste fera — « toucher pour
  changer » — et, sur le défaut, ce que « du fichier » implique à l'écriture.
- Pas d'abréviation en « Cat. » : le mot entier tient (la ligne s'enroule déjà), et une
  abréviation est exactement ce qu'on ne relit pas sous fatigue. Sonde jetable 12/12 aux deux
  moteurs et aux deux largeurs ; `npm run check`, `npm test` (2×1126) et l'audit COMPLET (25/25)
  verts.

## [5.11.0] — 2026-08-16
### L'atelier d'import dit aussi **où** ça va — bibliothèque et catégorie, rangée par rangée

- **On peut enfin choisir la destination d'un import, et pas seulement son contenu** (question de
  l'auteur : « comment définir les catégories et bibliothèques de une ou multiples fiches à
  l'import ? »). La v5.0 avait renversé l'ordre — d'abord CE QUE l'on importe, ensuite OÙ — mais
  le « OÙ » était resté ce qu'il était avant l'atelier : une question oui/non posée APRÈS lui, et
  seulement si une bibliothèque partagée éditable se trouvait sélectionnée à l'accueil. Trois
  manques : on ne pouvait viser QUE cette bibliothèque-là (depuis l'accueil « Perso », la question
  ne se posait même pas et tout y tombait) ; la **catégorie n'était pas réglable du tout** ; et le
  grain était le FICHIER, alors que celui de l'atelier est l'ENTITÉ depuis la v5.0 — un export de
  bibliothèque entière ne pouvait pas se répartir entre deux rayons. **Chaque rangée porte
  désormais sa destination** : une bibliothèque et une catégorie, réglées d'une touche, vues avant
  que rien ne soit écrit.
- **Le bandeau de tête n'est pas un réglage global à côté des rangées : c'est la même commande.**
  Il affiche la valeur commune des rangées **cochées**, « Plusieurs » quand elles divergent, et la
  pose sur ces mêmes rangées quand on l'actionne — jamais sur les décochées. « Tout ranger dans
  Réanimation » est donc « tout cocher » puis un geste, et régler une seule rangée est le même
  geste sur elle seule.
- **Le défaut ne décide rien à votre place** : chaque rangée part sur « garder celle du fichier »
  — le comportement d'avant, réconcilié par nom dans la destination (v5.10.9) — et le dit en
  nommant ce qu'elle garde (« Garder Réanimation »), pour ne pas avoir à rouvrir le fichier.
  Changer la bibliothèque d'une rangée **remet sa catégorie sur ce défaut** : un id de catégorie
  n'a de sens que dans sa bibliothèque, le conserver pointerait sur rien — ou sur autre chose.
- **La question « Où importer ? » disparaît, l'avertissement qu'elle portait reste.** Publier dans
  une bibliothèque partagée n'est jamais silencieux : un bandeau de pied **nomme** les
  bibliothèques visées et **compte** les éléments cochés (« 3 éléments iront dans « CH Le Mans » :
  visibles par tous les membres »), et se tait quand tout va au Perso. Registre attention, jamais
  rouge : ce n'est pas un danger, c'est une portée.
- **« Remplacer tout » n'est plus proposé quand l'import vise plusieurs bibliothèques.** Une
  suppression totale doit nommer ce qu'elle vide ; « remplacer les bibliothèques choisies »
  viderait deux bibliothèques entières sur une phrase au pluriel, dont l'une peut-être pour une
  seule fiche qu'on y a glissée. Le geste reste possible — on importe vers une destination à la
  fois — mais il ne se propose plus par inadvertance. La fusion, elle, n'a jamais eu besoin d'une
  destination unique.
- Sous le capot, trois décisions qui se voient à l'usage : la destination **voyage avec son
  entité** (une destination retrouvée après coup par l'index d'origine se désaligne au premier
  filtrage — une fiche écrite dans la bibliothèque de sa voisine, en silence) ; la table de
  résolution des catégories est indexée par **(bibliothèque, id source)**, parce que deux rangées
  peuvent garder la même catégorie du fichier vers deux destinations où elle ne porte pas le même
  identifiant ; et une catégorie n'est créée que lorsqu'une entité la réclame **dans la
  bibliothèque où elle la réclame**.
- Le menu de choix est **le même composant** pour la catégorie de l'éditeur, la catégorie d'une
  rangée et sa bibliothèque : trois copies de sa machinerie (voile, piège clavier, filtre, retour
  de focus) auraient divergé. Il se présente en **feuille à toute largeur** dans l'atelier —
  mesuré : ancré, il atterrissait une centaine de pixels sous le bas de la liste, détaché de la
  pastille qui l'ouvre, une rangée n'ayant aucun ancêtre positionné. Et « déplié » marque enfin la
  pastille touchée, non les boutons du bandeau.
- Détail de la doctrine (`docs/decisions/lot-v5-11.md`, A159-A169), dont deux corrections de ce
  que j'allais écrire, prises à la mesure : le bandeau annonçait « Plusieurs » à l'ouverture parce
  qu'il comparait les étiquettes rendues et non le choix ; et le remplacement d'un menu par le
  suivant est une **ceinture**, pas la réparation d'un symptôme — la feuille couvre les autres
  pastilles, aucun doigt ne peut en atteindre une seconde sans avoir refermé la première.
  Sonde jetable : 36 contrôles, deux moteurs, deux largeurs, vérifiée capable d'échouer.

## [5.10.9] — 2026-08-16
### Une fenêtre coupée par le clavier, une catégorie qui vient d'à côté, et « la protocole »

- **La fenêtre et son voile gris étaient coupés, clavier ouvert** (signalé à l'usage avec quatre
  captures : « fenêtre et fond gris parfois coupés sans raison sur smartphone / tablette, que ce
  soit la page d'accueil ou des fenêtres qui s'ouvrent — avec clavier c'est beaucoup plus
  visible »). Ce n'était pas « sans raison », et le décalage se LIT sur les captures : voile haut
  de 290 px alors que la zone visible en faisait ~660, carte amputée de son titre, page à nu
  dessous. Depuis la v4.29.4, `--vvh` donnait aux couches plein écran la BONNE HAUTEUR — mais à
  une MAUVAISE ORIGINE. Sur iOS, ouvrir le clavier ne rétrécit pas le viewport de MISE EN PAGE :
  il PANORAMIQUE le viewport VISUEL à l'intérieur (`visualViewport.offsetTop` > 0) pour montrer le
  champ focalisé. Or `position:fixed` s'ancre au viewport de mise en page : la couche restait
  collée à un `top:0` désormais au-dessus de l'écran, d'où une bande de `hauteur − décalage`
  — ~290 px pour un décalage mesuré de ~370. Une position ne se déduit pas d'une hauteur :
  `--vvt` porte désormais ce décalage, et `top` + `height` décrivent ensemble le rectangle
  RÉELLEMENT visible. Vaut pour les cinq couches plein écran (fenêtres, visionneuse d'image, plan
  plein écran, écran d'entrée d'un invité, mode moniteur) — une seule aurait été un correctif à
  moitié. **À ne pas confondre avec le recollage `unpan()` de la v5.10.4** : celui-là traite le
  décalage RÉSIDUEL après FERMETURE du clavier et s'interdit d'agir tant qu'un champ est focalisé,
  c'est-à-dire pendant tout ce que montrent les captures ; les deux sont complémentaires. Mesuré à
  la sonde sur les deux moteurs : au repos, géométrie identique à l'octet (aucune régression) ;
  à 370 px de décalage, la couche descend de 370 et son bas atteint le bord bas du viewport
  visuel ; sous le réglage « taille du texte » à 130 %, elle retombe aux mêmes 370 px d'écran
  (le décalage se divise par `--zf`, règle v4.24.0 — sans quoi elle raterait l'écran de 111 px).
- **Une catégorie importée pouvait venir de la bibliothèque d'à côté, ou se dédoubler**
  (signalé à l'usage : « à l'import de fiches qui ont des catégories qui ne sont pas dans la
  bibliothèque d'import, elles s'affichent quand même — encore plus s'il y a une catégorie qui
  porte le même nom »). L'import ne regardait que l'ID, or **un id de catégorie n'a de sens que
  dans SA bibliothèque** : ils sont déterministes au Perso (`c-reanimation`, dérivé du nom) et
  aléatoires en bibliothèque partagée. D'où deux défauts symétriques, tous deux visibles au rail.
  *Vers une bibliothèque partagée* : l'id Perso entrant n'y existait pas, on posait donc une
  SECONDE catégorie du MÊME id — et `catOf()`, qui résolvait un id sans regarder la bibliothèque,
  renvoyait la première du tableau : la carte portait le nom et la couleur de l'AUTRE. Rejoué à la
  sonde avec le défaut réintroduit : une fiche importée dans « lib-test » s'affichait
  « Anesthésie », couleur `#226a71`, celle du Perso. *Vers le Perso* : l'id partagé entrant étant
  aléatoire, il n'était jamais reconnu — une catégorie « Réanimation » de plus à côté de celle qui
  existait, même nom, deux rangées, les fiches réparties entre les deux. La clé de réconciliation
  est désormais le **nom** (comparé sans casse ni accents, comme partout ailleurs), l'id n'étant
  qu'une adresse locale au fichier : on réutilise la catégorie de destination dès que le nom s'y
  trouve, on n'en crée une qu'à défaut, un id déjà pris — fût-ce dans une autre bibliothèque — est
  régénéré, et les entités importées sont repointées. `catOf()` résout enfin **dans la
  bibliothèque de l'entité** : une référence qui n'y résout pas n'est pas une catégorie d'à côté,
  c'est une référence morte, et on n'affiche rien.
- **« Publier la protocole », « Déplacer la protocole »** (signalé à l'usage). Les deux textes de
  changement de bibliothèque sont partagés par les fiches (féminin) et les protocoles (masculin),
  et leurs articles étaient figés au féminin dans la chaîne — avec eux le démonstratif (« Cette
  protocole »), le pronom et le participe (« va être publiée »). Les cinq mots qui s'accordent
  sont désormais portés par des variables, pas par la chaîne.

## [5.10.8] — 2026-08-15
### Le volet respire, un chronomètre dit qu'il en est un, et la porte « ＋ » de l'éditeur ramène enfin sur ce qu'elle crée

- **La porte « ＋ » de l'éditeur amenait bien sur l'objet créé — une micro-tâche l'annulait**
  (signalé à l'usage : « en mode édition, quand on clique sur ajouter (étape, chronomètre,
  minuteur, compteur…) le scroll ne descend pas jusqu'à la case qui vient d'être créée »). Le
  geste était JUSTE : trace instrumentée, `edAdd` défilait de y = 1200 à 4996 dans la même tâche
  que le clic. C'est l'observateur de fenêtres qui rembobinait juste après — `_bgUnlock` restaure
  la position mémorisée à l'ouverture de la fenêtre, et ramenait à 1200, l'objet neuf restant
  3 000 px sous le pli. Le symptôme « rien ne se passe » était donc un geste correct, défait 1 ms
  plus tard. **Et seulement sur tactile** : cette restauration est gardée par `pointer:coarse` —
  sur ordinateur le défilement tenait, défaut invisible partout où l'on développe et systématique
  partout où l'on soigne (même famille que le dossier « bande basse iOS »). La ceinture reste (elle
  protège d'un moteur qui bougerait pendant le verrou) ; on lui ajoute le cas où l'appelant PREND
  LA MAIN : `modalHandoffClose` met le retour de focus à néant et lève le verrou de fond
  SYNCHRONIQUEMENT, sans restaurer — l'observateur, qui est une micro-tâche, trouve ensuite le fond
  déjà déverrouillé et ne dérange rien. Couper d'avance est une propriété ; espérer un ordre
  d'exécution est un pari. Les fermetures ordinaires (✕, Échap, tap hors fenêtre) gardent leur
  comportement, qui est le bon. Vaut aussi pour la porte des RÉFÉRENCES (`edAddProto`).
- **Le début de l'objet créé se pose sous les couches collantes, il ne se centre plus**
  (question de l'auteur : « le scroll peut-il afficher le début du bloc en haut de la page ? sinon
  peu visible »). `block:'center'` centre la BOÎTE dans la fenêtre sans rien savoir du chrome
  collant : mesuré, un bloc d'étapes neuf fait 552 px et une décision 587 — sur une fenêtre de 844
  le titre tombait à 181 px (visible, mais 120 px de vide au-dessus) ; sur une fenêtre de **667**
  (iPhone SE, ou n'importe quel téléphone en paysage) le même calcul le posait à **40**, c'est-à-dire
  DERRIÈRE un en-tête de 61 — on ne voyait plus le titre de ce qu'on venait de créer, et le cas
  s'aggrave avec la hauteur de l'objet. `block:'start'` suffit, sans rien calculer : le
  `scroll-padding-top` global (`--stick-top + 8`, déjà divisé par le zoom), posé en v4.30.0 pour
  WCAG 2.4.11, est honoré par le défilement natif et sert ici une seconde fois. Mesuré après :
  **haut = 69 px** pour les cinq types structurés, aux deux hauteurs. **Les listes gardent leur
  centrage**, et ce n'est pas un oubli : une dose, une vérification, un différentiel, une source
  sont UNE ligne de 44 px dont le sens vient du titre de section au-dessus d'elle — l'ancrer en
  haut la collerait sous l'en-tête et pousserait sa section hors de l'écran. Règle : *on ancre en
  haut ce qui a une tête à soi, on centre ce qui n'est qu'une ligne.*
- **« + Ajouter une réponse » rejoint ses frères** : c'était le dernier ajout de l'éditeur à faire
  un `renderEditor()` nu — le focus retombait sur `body` et la rangée neuve naissait au ras du bord
  bas (mesuré : haut à 770 pour 844 de fenêtre). Étape, rappel et jalon ancrent et focalisent
  depuis la v4.77.0 ; cette rangée avait simplement été oubliée.
- **UNE SONDE TIENT DÉSORMAIS CE CHEMIN, qui n'était mesuré par RIEN** (`audit-doctrine`, section
  « ÉDITEUR · la porte "＋" amène sur ce qu'elle crée »). C'est la leçon la plus coûteuse de ce lot :
  `check-*` est statique, `tests.html` n'exerce que des fonctions PURES, et aucun des vingt harnais
  n'ouvrait cette palette — si bien que, pendant le correctif lui-même, une `ReferenceError` a vécu
  dans `edAdd` (une déclaration `const CIBLE` emportée par une réécriture de commentaire) en
  laissant **toute la passe verte**, seule la console du navigateur la voyant. La sonde ouvre la
  vraie porte (`openEdit`, jamais un `state.view` posé à la main), en pointeur GROSSIER émulé et
  aux deux hauteurs 844 et 667, et mesure l'ANCRAGE (`haut ≈ --stick-top`) plutôt que la
  visibilité — un témoin « l'objet est visible » aurait été vert dans les deux cas du défaut. Deux
  témoins gardent la sonde honnête : le régime tactile doit être réellement émulé (sans lui, le
  défaut ne peut pas se produire et le vert ne vaudrait rien) et l'objet doit avoir été réellement
  créé. Vérifiée **capable d'échouer sur les trois défauts**, fichier restauré à l'octet
  (sha256 recontrôlé) : porte qui ne passe pas la main → 14 rouges ; retour au centrage → 9 rouges ;
  `ReferenceError` → capturée par `pageerror`. À noter, et c'est le genre de fait qu'on n'apprend
  qu'en essayant : réintroduire la seule restauration de `_bgUnlock` ne reproduit PLUS rien, le
  déverrouillage synchrone la désamorçant en amont.
- **La ligne « Minuteurs · compteurs · journal » du volet est fondue dans le sous-titre
  « Minuteurs »** (signalé à l'usage : « prend beaucoup de hauteur »). Les deux rangées disaient la
  même chose à un mot près, avec la MÊME grammaire CSS (11 px, petites capitales) : c'est le doublon
  de vocabulaire qu'AC 120-71B §5.5 proscrit, payé en hauteur d'écran pendant un soin. Le titre du
  volet devient le premier sous-titre de famille et le ✕ vit dans SA rangée ; « Compteurs » et
  « Jalons » ne bougent pas. Le ✕ repasse EN FLUX (ancré hors flux, il obligeait à réinjecter
  `min-height:48px` sur le titre pour ne pas flotter — on payait sa hauteur deux fois) et prend ses
  48 px de cible par un HALO vertical : 36 px de dessin, 0 px de hauteur en plus. Mesuré à 390 px :
  **81 px → 44 px** avant la première carte, fermeture triple intacte, aucun débordement de rangée.
  Trois règles CSS devenues sans cause sont purgées (règle 14).
- **Un chronomètre dit qu'il en est un** (signalé à l'usage : « les chronomètres s'affichent pareils
  que les minuteurs, impossible à distinguer visuellement »). Il n'y avait aucune marque positive :
  la seule différence était une ABSENCE — pas de barre, pas de « Cycles : n » —, et une absence ne
  se lit pas, surtout à côté d'un minuteur neuf où « Cycles : 0 » ressemble déjà à rien. Le nom par
  défaut disait bien « Chronomètre », mais il disparaît dès que l'auteur nomme l'objet, c'est-à-dire
  toujours. Or un temps qui MONTE et un temps qui DESCEND commandent des gestes opposés. La ligne
  « ⏱ Chronomètre · le temps monte » occupe EXACTEMENT l'emplacement de la barre et du compte de
  cycles : même silhouette, c'est la ligne qui sépare, pas la hauteur. Glyphe et mot (règle 8),
  aucune couleur — ce n'est pas un état, c'est une nature.
- **Un journal vide dit par quel geste on le remplit** : « Chaque tap sur "Noter l'heure", en bas de
  l'écran, inscrit ici l'heure d'un geste. » Le panneau ne montrait que son titre au-dessus du vide —
  et dans le rail, le titre lui-même est masqué par le dépliant qui le porte, si bien qu'il ne
  restait STRICTEMENT rien, à l'endroit précis où l'on découvre la capacité (le geste vit dans le
  dock depuis que « Noter l'heure » a quitté le panneau en v5.6). C'est une INVITATION, pas un état :
  rien n'affirme « 0 repère ». Elle ne paraît qu'en session — hors session la touche qu'elle nomme
  n'existe pas — et ne peut pas clignoter, un repère annulé restant dans la chronologie.
- **Les cartes d'accueil gagnent 9 px sur le rail A→Z, en voie étroite** (signalé à l'usage, puis
  « rétrécis encore »). Gouttière 16 → 8 px et rail 27 → 24 px. Le motif des 16 px a été RE-MESURÉ
  et avait vieilli : il protégeait le halo de l'épingle ☆, or `.pinbtn` s'arrête aujourd'hui 40 px
  avant le bord et n'a pas de halo — il n'y avait plus rien à protéger. **Le texte du rail, lui, ne
  pouvait pas baisser** : 11 px EST le plancher typographique (règle 9), `check-type` le refuse, et
  cela n'aurait rien gagné — la largeur du rail vient du `min-width:24px` des boutons, cible
  minimale WCAG 2.5.8, pas du glyphe. Les 3 px récupérables étaient le rembourrage horizontal du
  rail. Résultat mesuré à 390 px : rangée 355 → 363, rail à 366, jointure de 3 px, soit l'écart de
  la voie large (2 px à 1280) — les deux régimes cessent d'avoir deux valeurs pour une même
  jointure. Vérifié aussi à 320 et 768. **La largeur de carte est identique avec et sans rail**
  (342 px mesurés en répertoire ET en recherche) : la gouttière n'a jamais été conditionnée au rail
  depuis la v5.6, et la règle est désormais écrite sur place pour ne pas se reperdre.

## [5.10.7] — 2026-08-15
### Le rail A→Z ne saute plus en fin de liste — en PWA installée aussi

- **Le maximum de défilement se calcule avec la plus grande des deux hauteurs** (`pageMaxScroll`,
  signalé à l'usage : « sur l'app PWA ça saute encore alors que même numéro de version » — Safari
  sain, PWA seule en défaut). Reproduit et MESURÉ dans le simulateur, en vraie web app installée :
  en STANDALONE, `documentElement.clientHeight` rapporte 812 px pour un `innerHeight` de 874 — la
  borne `scrollHeight − clientHeight` surestimait donc le maximum de ~60 px, chaque pose du bas du
  rail partait au-delà de la fin réelle du document, et l'élastique iOS enchaînait les rebonds
  (5 réversions de direction mesurées sur un seul geste). Dans l'ONGLET Safari,
  `clientHeight = innerHeight` et la borne était exacte — c'est pourquoi le défaut ne se voyait
  qu'en PWA, et survivait à tous les correctifs validés en onglet. La borne prend désormais la plus
  grande des deux hauteurs (`clientHeight` vs `innerHeight ÷ zoomF()`) : écrêter quelques pixels
  avant le bord est invisible, écrêter au-delà rebondit. Après correctif, même geste, même
  appareil : 0 réversion, le défilement s'arrête à la fin exacte. Les deux écrêtages (cible de
  `jump` et re-borne à la relâche) passent par la même fonction — une seule vérité.

## [5.10.6] — 2026-08-15
### Republication — la v5.10.5 existait en deux exemplaires et la PWA installée gardait le premier

- **Pourquoi une 5.10.6 sans nouveau contenu : le cache `5.10.5` est brûlé.** Deux publications
  distinctes ont porté le numéro 5.10.5 le même jour (les correctifs du filtre le matin, puis le
  lot complet — rail, fenêtre compte, partage — le soir, tag déplacé). Or `sw.js` était IDENTIQUE
  À L'OCTET entre les deux : le navigateur ne détecte une mise à jour qu'au changement de ce
  fichier, donc une PWA installée sur la v5.10.5 du matin ne se mettait PLUS JAMAIS à jour — même
  nom de cache, précache du matin servi à vie, pied de page affichant « v5.10.5 » en toute bonne
  foi (vécu sur appareil : le rail sautait encore alors que Safari, hors PWA, était sain). C'est
  le piège documenté en tête d'AGENTS.md (« changer les fichiers ne suffit pas à changer ce qui
  tourne »), version collision : un numéro de version est un NOM DE CACHE, il ne se réutilise
  jamais pour des octets différents — re-taguer une version déjà construite quelque part revient
  à publier deux caches sous une seule clé. Le contenu de cette version est celui de l'entrée
  5.10.5 ci-dessous, intégralement.

## [5.10.5] — 2026-08-15
### Le rail A→Z tient enfin sous le doigt, la fenêtre compte cesse de glisser, le partage montre les complications et la présence réelle

- **L'icône du filtre remplit son rond** (signalé à l'usage : « augmente la taille des traits dans
  filtrer pour que ça corresponde mieux à la taille du bouton »). Le tracé était écrit à 16 px dans
  la coque statique — calibre d'un temps où le rond en faisait 38 ; depuis que la v5.10.4 cale le
  bouton sur la hauteur MESURÉE du champ (48 px au tactile), il n'en occupait plus qu'un tiers, et
  trois traits fins perdus au centre d'un grand rond se lisent comme un pictogramme lointain, pas
  comme une commande. Porté à 20 px, soit le rapport encre/rond de « ＋ » (15 dans 36) : la rangée
  cesse d'avoir deux densités d'icône. L'ÉPAISSEUR SUIT D'ELLE-MÊME, ce qui était la demande —
  `stroke-width` vit dans le viewBox de 24, donc les traits passent de 1,47 px rendus à 1,83 sans
  qu'aucune valeur d'épaisseur ne soit écrite quelque part. La taille est posée en CSS et non dans
  le balisage : `width`/`height` y sont des attributs de PRÉSENTATION, que le CSS remplace — et le
  tracé étant DUPLIQUÉ dans la table `uiIcon`, toute édition du balisage serait à faire deux fois.
- **En-tête replié, le bouton filtrer prend le gabarit de « ＋ » et du compte** (signalé à l'usage :
  « lorsque l'en-tête d'accueil est replié quand on scrolle, change la taille du bouton filtre — et
  des traits dedans — pour que ça corresponde à la taille des boutons ＋ et compte »). Au repos il
  est SEUL en face du champ, et s'aligner sur lui est exactement ce que la mesure de `--srch-h` est
  venue garantir en v5.10.4. Mais une fois l'identité partie (7a), la rangée persistante porte
  « ＋ », le filtre et le compte : trois boutons voisins, dont un de 48 px contre deux de 36 —
  c'est-à-dire le défaut « deux contrôles d'une même rangée qui ne font pas la même hauteur se
  lisent comme deux niveaux », retourné, le champ n'étant plus le voisin. Sous `body.home-slim` il
  suit donc la troupe : 36 px (icône 16) comme `.hdr-new` et `.bar-acct`, 32 sous 360 px comme eux,
  et le halo rend la cible à 44 px dans les deux cas. Mesuré une fois replié : filtre 36 × 36,
  « ＋ » 36 × 36, compte 36 × 36, tous centrés sur le même axe ; à 340 px de large, les trois à
  32 × 32 avec le même halo `-6px -1px`, donc cible 34 × 44 inchangée.
  ⚠ La règle des 32 px est déclarée AU SITE DU BOUTON et non dans le bloc `359.98` du haut de
  feuille où vivent ses deux voisins : elle y aurait eu la MÊME spécificité (0,3,2) que celle des
  36 px écrite cinq mille lignes plus bas, donc perdu par le seul ORDRE, silencieusement. Pour une
  géométrie, on ne dépend jamais de l'ordre sans le dire.
- **Le rail A→Z ne se sélectionne plus** (signalé à l'usage : « le texte du rail est sélectionnable
  → bug, et ça sélectionne si on reste appuyé trop longtemps dessus »). Viser une lettre, c'est
  poser le doigt et glisser — un geste qui COMMENCE par un appui maintenu, donc précisément ce que
  WebKit interprète sur du texte comme le début d'une sélection : rectangle bleu, poignées, loupe,
  menu « Copier ». Le geste est alors CAPTURÉ par la sélection, le rail cesse de suivre le doigt,
  et il faut taper ailleurs pour désarmer. `touch-action:none` tenait déjà le défilement natif à
  distance, mais une sélection n'est pas un défilement : elle passait à côté. `user-select:none` +
  `-webkit-touch-callout:none` sur `.azrail`, et rien n'est perdu — ces vingt-six lettres ne sont
  pas un contenu qu'on copie, ce sont des commandes. `user-select` s'héritant, les boutons sont
  couverts par la même ligne (vérifié : `none` sur le conteneur ET sur le bouton).
- **Outillage d'audit — le cache vert est PAR HARNAIS et `--rouges` rejoue PAR SECTION** (travail
  déjà en place dans le dépôt, publié ici avec la version qui le nomme). Le cache était
  tout-ou-rien : un octet changé dans `audit-qr.mjs` faisait repayer `doctrine` (217 s). L'empreinte
  SHA-256 est désormais par harnais — socle commun + son script + ses `deps` déclarées — et la passe
  complète ne rejoue que ce dont un intrant a changé, en LISTANT les harnais réutilisés ; les
  `check-*.mjs` sont sciemment hors empreinte (aucun harnais ne les lit, les inclure fabriquait des
  repasses fantômes). `--rouges` lit les NOMS des sections rouges dans la sortie capturée et ne
  rejoue qu'elles, avec trois garde-fous : attribution seulement si le harnais a atteint son bilan
  (`##SEC` présent — sinon repli sur le harnais ENTIER, jamais trop peu), rouge FORCÉ si un `--grep`
  rejoue moins de sections qu'attendu, et jamais de vert de cache écrit par un rejeu par sections.
  Mesuré : confirmer un correctif tombe de 97 s à 0,5 s, repasse inchangée 0,25 s.

- **L'en-tête ne disparaît plus pendant la visée du rail A→Z** (signalé à l'usage, prouvé à la
  VIDÉO image par image : à chaque grande pose vers le haut, l'en-tête `sticky` quittait l'écran
  ~2 frames puis se recollait — pendant que le rail, `fixed` depuis v5.0.2, ne cillait pas). C'est
  le retard de compositeur WebKit sur les collants lors d'un `scrollTo` instantané en séquence
  tactile : aucun gel d'état n'y pouvait rien, ce n'est pas un état qui change, c'est le rendu d'un
  état juste. Pendant `html.azr-aim` l'en-tête passe donc en `fixed` (même famille de remède que le
  rail), `body` compense sa place par `--hdr-h`, et tout se remet en place à la relâche —
  géométriquement une identité, vérifiée à la sonde sur les deux moteurs. Au passage : les cibles
  de `jump` sont bornées au défilement maximal et calculées sur `stickHeight()` (somme de hauteurs,
  jamais le bas observé d'une pile translatable — le dernier lecteur de position que la purge
  v5.0.2 avait laissé), le relais de titre `ttl-on` est gelé pendant la visée, et `--hdr-h` est
  re-mesurée après chaque bascule d'état (elle restait périmée d'une passe : 63 px annoncés pour un
  en-tête de 115).
- **Le rail A→Z se centre sur l'écran en voie étroite** (vidéo : bloc de lettres à ~23 % de l'écran).
  Le centre se calculait sur `documentElement.clientHeight`, la seule mesure de la formule dont le
  comportement sous zoom DIVERGE entre moteurs ; il se dérive désormais de la boîte du rail
  elle-même (géométrie `svh`, stable par construction). La voie large garde la mesure d'origine —
  exacte sur coque fixe, témoin doctrine 1280×900 à l'appui.
- **Le sélecteur A-Z/Catégories se rapproche de l'en-tête** (2 px dessus, 8 px dessous — resserré
  deux fois à la demande), **ouvrir un protocole commence en haut de page** (même artefact Safari
  et même garde-fou que les éditeurs v4.4.7 : le haut est ré-affirmé à l'arrivée), et **les deux
  bascules de l'en-tête d'accueil ont leur micro-animation** — au dépliage l'identité et les chips
  fondent en place (140 ms, opacité + 3 px composite), au repli la rangée persistante recomposée
  fond sur le même tempo ; la hauteur, elle, ne s'anime jamais (check-anim, mesuré v4.41.0).
- **La fenêtre Compte & synchronisation ne glisse plus latéralement** (signalé avec vidéo,
  instrumenté SUR l'appareil : « corps +2 px » — un artefact d'arrondi au zoom fractionnaire, pas
  un contenu, 42 combinaisons balayées sans un élément trop large ; or 2 px suffisent à iOS pour
  ouvrir le pan élastique). La rangée des accents PLIE au lieu de figer 244 px (`flex:none` →
  `0 1 auto`), et les axes sans usage sont FERMÉS : X sur `.ai-modal` et `.ai-body` (dont l'axe
  implicite — `overflow-y:auto` seul calcule X en `auto`). La première pastille d'accent reprend la
  couleur RÉELLE du disque par défaut (`var(--sys)`, « Par défaut ») ; la consignation des
  compteurs (« consigné T+… · il y a … ») s'affiche aussi dans la sidebar, en sous-ligne au liseré
  — elle pesait comme un second titre.
- **Les plans inline ne capturent plus le pouce** (iPhone : le pan vertical restait piégé dans le
  tableau SFAR et l'organigramme, avec retour élastique même sans débordement — un axe `auto`
  rebondit sur iOS même vide). Sur écran tactile, `.sv-scroll` et `.flow-scroll` inline prennent
  leur hauteur entière et l'axe vertical est fermé : le pouce fait défiler la PAGE, le défilement
  horizontal des colonnes est conservé. Les feuilles plein écran gardent leur défileur — c'est leur
  surface, il n'y a pas de page dessous.
- **Le mode moniteur tient en paysage** (tout se superposait : le grand corps était calibré en
  `vw` seul — 169 px sur un écran de 390 de haut — et le centrage déversait le débordement sur la
  rangée du haut). Corps borné par `min(20vw, 32vh)`, centrage `safe`.
- **Partage : l'invité voit les complications, et ce qu'il voit est vrai.** L'ancre d'excursion
  voyage enfin (`SHARE_TRAVELS` listait `cxBack` depuis l'origine sans que le snapshot ni le
  payload `nav` ne l'aient jamais portée — la famille exacte du `fold.exercise` d'avant v4.50.0) :
  sans elle, la carte de complication passait chez l'invité pour un bloc terminal ordinaire
  (« Terminer l'algorithme ✓ » puis « surveillance en cours » au lieu du retour « ↩ Reprendre »).
  Références seules, validées contre la copie locale de la fiche (règle 15). La touche
  ⚡ Complications est rendue à l'invité en CONSULTATION (`jumpToBlock` — la navigation locale du
  plan, jamais d'entrée déclarée). Et les cartes minuteurs de la sidebar ne se bloquent plus par
  moments en partagé : `bindRailTm` empilait un écouteur à chaque coche (parité paire = carte
  inerte) — affectation `onclick`, idempotente.
- **Partage : la présence affichée est la présence réelle, sans juger un téléphone posé.** Trois
  régimes (retour utilisateur : « en urgence ça peut arriver de lâcher son téléphone 1, 2 min ») :
  silence ≤ 45 s, rien ; jusqu'à 3 min, présent et compté avec la mention « sans nouvelles ·
  N min » ; au-delà, « absent », hors compte ⇄ et menu. Le départ EXPLICITE n'attend pas :
  « Quitter le partage » émet `presence{quit}` (genre réservé depuis l'origine, jamais branché —
  la liste blanche du serveur l'acceptait déjà, zéro changement de schéma) et l'hôte affiche
  « parti » à la seconde. `last_seen_at` était renvoyé par le serveur et jamais lu.

## [5.10.4] — 2026-08-15
### L'en-tête ne bat plus sous le rail A→Z, le viewport iOS se recolle, le filtre est rond

- **L'en-tête d'accueil ne bat plus pendant le glisser sur le rail A→Z** (signalé à l'usage :
  « en haut de la liste, l'affichage saute très rapidement entre vue pliée/dépliée »). Chaque
  mouvement de doigt sur le rail pose un défilement ABSOLU ; près du haut de l'annuaire, deux
  lettres voisines encadrent l'hystérésis 80/40 de `syncHdrScroll` et le repli battait à la
  cadence du doigt (114 ↔ 62 px par évènement pointeur). L'hystérésis protège d'un doigt qui
  hésite EN DÉFILANT ; elle ne peut rien contre des sauts qui la traversent en entier. Pendant la
  visée (`html.azr-aim`), l'état plié/déplié est désormais FIGÉ — le geste du rail n'est pas un
  geste de défilement — et se rejoue UNE fois à la relâche. Vérifié à la sonde : état constant
  sur un va-et-vient A↔D complet, une seule bascule au lâcher.
- **Le décalage résiduel du viewport visuel iOS se répare d'office** (signalé à l'usage, capture :
  toast « fichier ignoré » au MILIEU de l'écran, en-tête invisible sous la barre d'état, bande
  vide sous le pied de page). Le clavier PANORAMIQUE le viewport visuel dans le viewport de mise
  en page (`offsetTop` > 0) ; à la fermeture, WebKit ne recolle pas toujours les deux — surtout
  quand le fond était verrouillé par une fenêtre, donc sans évènement de défilement pour
  resynchroniser. Hors pincement et hors clavier, un `offsetTop` non nul est TOUJOURS incohérent :
  on recolle en déplaçant le défilement de mise en page de l'offset (`scrollBy`) — le contenu
  visible ne bouge pas d'un pixel, seuls l'en-tête collant et les couches fixes retrouvent
  l'écran. Déclenché aux seuls moments où l'état peut naître (fermeture du clavier, perte de
  focus, retour de bfcache), jamais en continu. À confirmer à l'usage sur appareil (l'état n'est
  pas reproductible hors iOS réel).
- **Le déclencheur de filtre est un CERCLE calé sur le champ de recherche** (demande de l'auteur ;
  il rendait 38 × 48, un OVALE). `align-self:stretch` + `aspect-ratio:1` ne fait pas un rond en
  flex — la largeur se détermine AVANT que l'étirement ne fixe la hauteur, le transfert n'a jamais
  lieu (mesuré). Aucun nombre n'étant juste à écrire (champ à 48 px au tactile, ~44 au pointeur
  fin), la hauteur du champ est MESURÉE et posée dans `--srch-h` (`syncSrchH` — au rendu, au
  redimensionnement, au changement de taille du texte ; doctrine « une barre de chrome se mesure,
  elle ne se devine pas »). Mesuré après : 48 × 48.
- **Prompt IA resserré** (demandes de l'auteur ; les jalons de boucle y figuraient déjà depuis la
  v5.5.0). (1) Formulation LA PLUS COURTE POSSIBLE partout — étapes, surveillances, confirmation,
  notForget — avec l'exception écrite : les CRITÈRES diagnostiques restent COMPLETS, on raccourcit
  la formulation, jamais la liste. (2) Les noms de minuteurs/compteurs sont À LA FOIS titre et
  ligne de journal : 1 à 3 mots, relus seuls, et un compteur doit se lire SUIVI D'UN NUMÉRO
  (« Choc n° 3 » — objet compté au singulier, jamais un pluriel ni un intitulé abstrait). (3) La
  parcimonie ⚠/△ existait déjà (plafonds par bloc ET par fiche) : elle entre dans la check-list
  finale « AVANT DE RÉPONDRE », avec les libellés de compteurs. (4) Corrigé un bogue de l'exemple
  du schéma : l'id `"b2"` y figurait DEUX fois — l'exemple violait sa propre règle d'unicité.

## [5.10.3] — 2026-08-15
### Le tick gaté (jamais ralenti), les relances iOS comptées, AGENTS.md scindé

- **Le battement interne est GATÉ, pas ralenti** (R6, mesuré avant ET après). Une fiche simplement
  ouverte — sans session — payait le tick complet 3,3 fois par seconde : 40 travaux inutiles en
  3 s (refreshTimersDOM, paintCnAgo, updateRtStrip, monRender), et l'accueil balayait tout le
  document à la même cadence sans aucune session vive. La condition devient « une session AFFICHE
  du temps » (sessions vives, essai K5, invité). **La granularité est intouchée par
  construction** : la cadence de 300 ms ne bouge pas — retard de bascule de seconde mesuré
  79-288 ms avant, 97-304 ms après (même enveloppe), latence du geste 1 ms, travaux en session
  strictement identiques. ⚠ Le réveil « aligné sur la seconde », envisagé, est **rejeté au
  calcul** et le refus est écrit au site : chaque minuteur franchit sa seconde à sa propre phase —
  un réveil calé sur l'horloge murale afficherait la bascule jusqu'à une seconde en retard.
- **Les relances complètes se comptent** (P2, diagnostic de l'hypothèse d'éviction d'A153). Les
  2-3 s de blanc au retour vivent dans la couche iOS ; la seule question ouverte est leur
  FRÉQUENCE. Journal par jour (démarrages complets / reprises sans relance, fenêtre 14 j, une clé
  locale), lu dans Compte › « Sur cet appareil ». Instrumentation **temporaire** (précédent
  v4.29.x), jamais chez l'invité.
- **AGENTS.md scindé : 797 → 49 Ko de noyau.** Le fichier canonique dépassait la fenêtre de
  contexte de tout outil IA — les instructions étaient tronquées en silence à chaque session, le
  défaut exact que le découpage du changelog avait guéri en v5.0.0. La doctrine détaillée vit dans
  `docs/decisions/` (six fichiers, déplacement **à l'octet** : empreintes sha256 embarquées, 164
  entrées A réconciliées, zéro réécriture, classement chronologique par lot — le numéro A est
  l'adresse que la doctrine se cite à elle-même). AGENTS.md garde les 15 règles, la publication,
  les garde-fous et la carte ; toute nouvelle entrée A va dans le fichier de son lot.

## [5.10.2] — 2026-08-15
### Audit de code externe : quatre bogues, deux garde-fous, quatre duplications

Audit transverse du monofichier (code mort, duplication, PWA, sécurité) par balayage outillé —
836 fonctions, 1 916 interpolations, 245 ids, 227 exports de test — chaque constat **re-vérifié de
première main** avant correction : trois « morts » du balayage étaient des faux positifs
(`#addImg`, `wakeActive`, `SHARE_DROP`/`vfActor`), et la leçon est écrite (A157). Doctrine :
`AGENTS.md` A154 à A158.

**Les bogues utilisateur.**
- **Le diff « Versions » était aveugle sur cinq listes sur six.** `flattenFiche` lisait
  `f.confirmation`/`verify`/`notForget`/`differentials`/`posology` — des champs que `migrate`
  **supprime** depuis l'étape B (v5.0.0) : sur toute fiche réelle, restaurer une version se
  décidait sans voir aucune modification de ces listes. La table de libellés omettait en plus
  `posology`. Les deux passent par `listOf()`, la vue sur le pool — et les témoins, restés verts
  sur des fixtures brutes jamais migrées, **rencontrent désormais leur cas** (fixtures migrées,
  assertions sur les cinq listes).
- **La recherche ne trouvait jamais une fiche par son diagnostic différentiel** — le même résidu
  (`f.differentials` lu en direct) dans `ficheHaystack`, figé par son cache. Pour un répertoire
  dont le motif d'usage est « le tableau ne colle pas », c'était le trou le plus clinique du lot.
- **Les sessions synchronisées entraient sans assainisseur** : `sessionFromRow` écrivait le blob
  distant tel quel en IndexedDB (fiches et protocoles passent par `migrate`). `sanitizeSession`
  applique la règle 5 en **liste grise** — champs connus bornés par les grammaires existantes
  (`SHARE_KEY_RX`, `shareNavNorm`, `tkRefNorm`), champs inconnus qui traversent, motif
  `__proto__` fermé. 13 témoins.
- **Quatre lecteurs d'ids fantômes** (`#crisisCtrl` ×3, `#planBtn` ×2, `#endSess`) : l'un
  recalculait `--ctrl-h` à « 0px » **à chaque évènement de défilement** pour un élément parti en
  v5.6, les autres étaient des câblages morts. Purgés avec leurs épitaphes.

**Les garde-fous (le trou par lequel tout cela était entré).**
- `check-ids` : tout `getElementById` littéral doit avoir une émission (id littéral ou fabrique
  déclarée). `check-actest` : toute clé exportée vers `__ac_test__` doit être citée par un témoin
  ou un harnais, doublons interdits — trois doublons dédoublonnés, 13 clés sans valeur de test
  retirées, et le **cœur du modèle v4** (`poolOf`, `roleItems`, `setStepStr`, `v4SanItem`,
  `v4Level`, `V4_ROLES`) reçoit ses vrais témoins. Les deux vérifiés capables d'échouer.
- `check-colors` couvre désormais le **manifeste** : `theme_color`/`background_color` portaient
  des hex hors palette (#ffffff, #e9edf2) — splash hors tokens à chaque lancement, invisible d'un
  contrôle borné au `<style>`. Alignés sur `THEME_COLOR.light`.

**Les duplications** (« une seule vérité par geste ») : `paintCheckRow` — la peinture du cochage
vivait en deux copies mot pour mot, la divergence v4.42.0 revenue par une autre porte ;
`planCtx` — le préambule de plan recopié six fois, dont une où il était calculé puis jeté ;
`conduiteRows` — les rangées communes des menus invité/hôte (le sous-titre divergent de
« Consulter » est une raison documentée, pas un accident) ; `bindPreviewBack` et `blockTip` — les
paires jumelles fiche/protocole. Purgés avec leurs témoins (règle 14) : `flowOrder`,
`svBranchIssue`, `svLoopTargets`, `cxOne`.

**Sécurité** (audit exhaustif : **0 XSS exploitable**, RLS sans faille, 0 sink dangereux) : la
barrière devient **locale** — `esc()` sur 27 identifiants interpolés, `CSS.escape` sur les cinq
sélecteurs construits, le backtick non échappé **vérifié** inerte, invariant écrit sur
`_reportDoc` (seul endroit où une chaîne devient un document), commentaire de décision sur
l'absence de rate-limit de `share_join`.

**PWA** : cache statique pérenne `STATIC_CACHE` (~120 Ko de polices/icônes n'étaient
re-téléchargés à chaque release que parce que la clé de cache change — le motif pdf.js
généralisé), préchargement des quatre polices embarquées, `display_override` au manifeste.

**Et une attribution fausse corrigée dans la doctrine** : A153 imputait les 2-3 s de blanc iOS au
parse des 2,4 Mo. Mesuré (copie sans commentaires, CPU ×6) : **1,26 Mo de commentaires = ~0,1 s**
— le blanc vit dans la couche iOS (processus, WebKit, worker), hors de portée du code. Le retrait
des commentaires à la publication est **disqualifié** comme levier de démarrage ; reste
l'hypothèse d'éviction mémoire, à instrumenter avant d'agir.
## [5.10.1] — 2026-08-14
### Audit design externe : ce que les garde-fous ne voyaient pas

Audit mesuré au rendu (320 · 390 · 1280 px × les quatre réglages de taille du texte, deux thèmes),
sur le **contenu d'exemple livré avec le produit** — donc sur ce que voit le premier utilisateur,
le premier jour. Les dix-huit contrôles statiques étaient **verts** : chaque défaut ci-dessous
était, par construction, hors de leur portée. Doctrine : `AGENTS.md` A139 à A148.

**Ce que l'audit a établi sur le fond, et qu'il faut dire avant les correctifs.** Une sonde de
contraste indépendante (composition de l'opacité des ancêtres et du fond effectif) rend **0
violation AA** sur l'écran de crise dans les deux thèmes ; 22 couleurs peintes pour 123 jetons
déclarés, chacune avec un sens constant ; cases à cocher à 3,33:1 en sombre ; réserve du dock sans
un pixel masqué ; anneau de focus franc. Le système tient. Ce qui cédait, ce sont **trois bords que
rien ne balayait** : la grande police, la largeur plancher, le contenu long.

- **Le discriminant clinique n'était jamais peint.** « adulte » / « pédiatrique » vivait dans
  `#brandTitle`, qui s'ellipse — dernier enfant, donc premier amputé : à 390 px, 193 px de boîte
  pour 358 nécessaires, la pilule commençant au 308ᵉ pixel. Le champ créé pour distinguer deux
  procédures homonymes était exactement ce que la troncature emportait d'abord, avec une doctrine
  qui affirmait le contraire. Il rejoint le **sur-titre**, où il ne coûte **rien** : mesuré,
  l'en-tête fait 61 px avec et sans sur-titre, et le titre regagne les 50 px que la pilule
  consommait dans sa chaîne.
- **Le mécanisme anti-`@media` de la règle 10 était mort.** `syncZoomWidth()` posait
  `zw560/430/400/360` à chaque rendu et **aucune règle ne les lisait** — leurs consommateurs
  étaient partis avec la rangée de commandes en v5.6, le poseur était resté (`check-classes` ne
  peut pas le voir : le nom est calculé). Pendant ce temps le dock écrivait son palier en `@media`,
  donc il ne se déclenchait jamais sous zoom : mesuré à 390 px × 130 %, la mise en page dispose de
  300 px effectifs, `zw360` est bien posée, et les quatre étiquettes survivaient sur deux à trois
  lignes dans des touches de 76 px. Un **cinquième palier** naît de ce lot, `zw300`, qui ne peut
  naître que du zoom — aucun appareil ne fait 300 px.
- **Le budget d'écran comptait deux couches sur trois, et un réglage sur quatre.** En v5.6 la
  rangée de commandes est devenue le dock bas ; `audit-budget` est resté calibré sur les trois
  couches d'avant tout en n'en mesurant plus que deux — le seuil de 30 % n'a pas bougé, mais ce
  qu'il borne a perdu un tiers. Le harnais balaie désormais les quatre crans de texte et compte le
  dock. Mesuré avant correction à 320 × 640 × 130 % : chrome **41,3 %** et **zéro étape cochable**.
  Après compaction des rembourrages (jamais des cibles : `.sd-key` descend à 44 px, exactement le
  plancher d'A8) : **24/24 sur six configurations**.
- **Le plus grand corps de l'écran de crise appartenait à un libellé de navigation.** Relevé des
  corps peints : titre de bloc 21/700, étape vitale 17,5/800, cadence **11/600** — le plancher
  typographique pour « 30:2 — sans délai », qui gouverne le geste. Deux crans échangés : le titre
  descend, la cadence remonte juste sous l'étape qu'elle qualifie. Bénéfice second, mesuré : à
  320 px × 130 % le titre ne se coupe plus **en plein mot**. Une carte de **décision** garde le
  grand cran — A75 exige que son titre passe devant sa question.
- **Deux touches du dock, un seul glyphe, aucun mot.** « Tout voir » et « Consulter » partageaient
  ⤢ — choix juste en v4.25.0 — et A2 leur retire l'étiquette sous 360 px : restaient deux boutons
  voisins, même symbole, deux destinations, en mode crise. Aucune des deux règles n'est fautive ;
  leur **composition** l'était. « Consulter » prend `book`. Dans la foulée, les glyphes du dock
  passent par `uiIcon` (⚡︎ → `bolt`, ⏱︎ → `stopwatch`, entrée `backto`), et trois SVG littéraux
  dupliqués entre la coque et le peintre disparaissent.
- **Un jeton court est un item dur.** Le code « ANA » manquait de **un pixel** (29 rendus pour 30)
  et s'affichait « A… » : l'unité était fausse — un pixel manquant sur trois lettres en détruit
  deux, l'ellipse consommant la place qu'elle libère. Décision prise à l'émission, seuil cinq
  caractères. ⚠ Prioritaire, **pas rigide** : un témoin a montré qu'en le rendant immuable il était
  poussé hors de la boîte à 330 px, c'est-à-dire disparu.
- **« Tout voir » revient enfin où l'on était** *(signalé à l'usage)*. Reproduit : parti de y=300,
  l'excursion défilée jusqu'au bout, retour à **575 — le maximum du document**. L'ancre était
  traduite aux deux jambes ; elle est juste à l'aller, et restitue au retour la position de **fin
  d'excursion**. Le second symptôme signalé — « la barre flottante et les clics sont décalés
  jusqu'à ce qu'on remonte » — tombe avec le premier : atterrir à la borne est la condition exacte
  du rabat de fin de page et du rebond iOS. ⚠ On mémorise une **ancre**, pas un nombre : si un
  collègue avance le parcours pendant l'excursion, la page change de longueur et un `scrollY` brut
  redéposerait à la borne (cas construit et mesuré, document 1420 → 1769 px).
- **La carte de session vive** : « Reprendre » ne se détachait pas de sa carte (**1,69:1** — le
  défaut qu'A43 a nommé pour la pastille Compte, la limite d'un composant et non son texte). Il
  prend `--ok-sys` (**9,08:1**), qui est déjà le registre du retour d'excursion du dock — « vous
  êtes loin de chez vous, ceci vous y ramène ». Et « Reprendre » / « Terminer » avaient deux
  hauteurs (38 et 36) à 10 px l'un de l'autre : les deux passent à 44 px, l'écart s'ouvre.
- **L'étiquette de complication borne sa parenthèse** — « FV réfractaire.. » était clampée à deux
  lignes *et* encore tronquée, alors que savoir laquelle s'ouvre est tout l'objet du bouton. La
  parenthèse qualifie, elle n'identifie pas ; la phrase entière reste dans le nom accessible.
- **Les quatre touches du dock sont enfin égales** : `flex:1.3` donnait à ⏱ une piste 30 % plus
  large — mesuré 79/79/79/100 à 390 px et 46/46/88/110 à 320.
- **Les catégories vides sortent du rail de l'accueil.** Sur une installation neuve, neuf
  catégories dont **six à zéro** : six rangées menant à une liste vide, en tête du premier écran.
  Un filtre qui ne filtre rien n'est pas un filtre — et la taxinomie garde son lieu, « Gérer les
  catégories ». ⚠ La catégorie **sélectionnée** reste, même à zéro : la retirer rendrait le filtre
  invisible au moment précis où il explique une liste vide.
- **En crise, le préambule ne paie que ce qu'il montre** *(signalé à l'usage)*. À 390 px, session
  vive, **106 px** séparaient le bas de la capsule du haut de la carte, dont **24 px de pur
  espacement**. Ramenés à 4 px chacun : **96 px**, rythme régulier, première étape 10 px plus haut.
  Les boîtes du chapeau et de la ligne-bilan ne bougent pas — elles sont tapables (40 et 44 px) ;
  seule la respiration entre elles cède.
- ⚠ **La Page garde son défilement horizontal, et c'est un retour en arrière assumé.** J'avais fait
  céder la colonne d'état pour rendre à la feuille sa largeur d'auteur (227 px de débordement à
  1280 px). Refusé à l'usage, en deux symptômes qui n'en font qu'un : « le volet noter l'heure reste
  petit » et « les minuteurs apparaissent en bas de la page ». Déplacer une surface d'**état vive**
  pendant un soin coûte plus cher qu'un défilement horizontal sur une surface de **consultation** —
  et mon rapport classait d'ailleurs ce point en simple amélioration. Le débordement reste, sans
  solution gratuite : l'ajustement d'office ramènerait une cible de 44 px à 34, et rétrécir la
  feuille casserait « la même image partout ». Un témoin de non-régression tient désormais la
  propriété choisie : en voie large, l'état reste à droite du document.

⚠ **Deux pièges du dossier se sont produits pendant ce lot, et le second a masqué le premier** :
le script inline a été édité sans rejouer `csp-hashes.mjs` (règle 3), donc la CSP a bloqué le seul
script et l'application n'a plus démarré — pendant que l'onglet de développement affichait une page
parfaitement fonctionnelle, le service worker resservant l'ancien HTML. Ensemble, ils donnent
« ça marche chez moi, ça casse au harnais ».

Chaque correctif est vérifié au rendu, et le nouveau témoin d'excursion a été **vérifié capable
d'échouer** — défaut réintroduit, contrôle rouge, fichier restauré à l'octet.
