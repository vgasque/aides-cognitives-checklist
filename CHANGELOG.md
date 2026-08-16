# Journal des modifications

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

## [5.13.2] — 2026-08-16
### La sidebar ne bouge plus, quoi qu'il arrive — parce qu'elle décrit le rectangle visible

- **Question de l'auteur, après que « libérer » a échoué** : « pas moyen de fixer la sidebar de
  manière à ce que ça ne bouge pas quoi qu'il arrive, tout en la gardant défilable si le contenu est
  plus long que l'écran ? » **Si** — et la preuve était sous nos yeux depuis la v5.10.9 : les
  **fenêtres** ne bougent pas, ce que l'usage avait confirmé. Pourquoi elles et pas le reste ? Parce
  qu'elles sont **épinglées ET dimensionnées** sur le viewport visuel (`top` = décalage,
  `height` = hauteur visible). Elles ne décrivent pas une position dans la page : **elles décrivent
  le rectangle visible**. Rien ne peut les en sortir.
- **Tout ce qui a échoué n'en faisait qu'une moitié** : « collant sous l'en-tête » (une position,
  pas de taille), « collant + décalage » (position corrigée, taille toujours celle de la page),
  « libéré » (ni l'un ni l'autre). Une moitié de rectangle ne tient pas.
- Le temps que le clavier est ouvert, **le logement du champ de recherche devient donc une couche du
  viewport visuel** — la colonne sommaire en voie large, la barre fixée en voie étroite. Et comme sa
  hauteur est exactement celle du visible, **elle défile à l'intérieur** dès que son contenu
  dépasse : c'est la seconde moitié de la demande, et elle vient avec la première. `left` et
  `width` restent `auto`, donc la colonne garde la place que la grille lui donne — rien n'est mesuré
  en JS.
- Mesuré aux deux moteurs et aux deux largeurs, en la soumettant à **tout** ce qui la faisait bouger
  jusqu'ici : zone visible de 400 px commençant 380 px plus bas → elle est à 380, haute de 400, dans
  sa colonne ; on défile la page de 1200 px → **elle ne bouge pas d'un pixel** ; le système
  re-panoramique (ce que fait iOS à chaque frappe) → elle suit exactement le nouveau rectangle et le
  champ reste visible ; clavier refermé → elle retrouve son ancrage d'avant.
- La décoration, elle, reste **libérée** (v5.13.0) : en-tête, quai de crise, barre de sélection,
  poignée d'édition, volet du quai, rail A→Z. `npm run check` 20/20, `npm test` 2×1126, audit
  COMPLET 25/25.

## [5.13.1] — 2026-08-16
### On libère la décoration, jamais le logement de ce qu'on écrit

- **Correction d'une régression de la v5.13.0, introduite une heure plus tôt** (signalée à l'usage :
  « la barre suit bien au scroll **sauf avec le clavier** : dans ce cas out of view, ça remonte et
  je ne vois pas ce que je tape »). En libérant le chrome, j'avais rendu au flux **la barre fixée
  d'une référence et la colonne sommaire** — or c'est là que vit le champ de recherche. Rendus au
  flux, ils reprennent leur place **en haut du document** ; le navigateur, qui doit montrer le champ
  focalisé, n'a alors qu'un moyen d'y parvenir : **ramener la page en haut**. D'où le retour au
  début et la perte de l'endroit qu'on lisait.
- **La règle devient plus précise qu'« on libère tout »** : on libère la **décoration** — ce qui
  oriente, annonce, commande (en-tête, quai de crise, barre de sélection, poignée d'édition, volet
  du quai, rail A→Z) — et **jamais le logement de ce qu'on est en train d'écrire**. Celui-là reste
  épinglé : c'est le seul élément dont le navigateur garantit lui-même la visibilité, et le laisser
  fixe est précisément ce qui permet de taper sans perdre sa page.
- Mesuré aux deux moteurs : clavier ouvert, l'en-tête est `static` et défile de −600 px avec la
  page, tandis que la colonne sommaire — qui porte le champ — reste `sticky`. `npm run check`
  20/20, `npm test` 2×1126, audit COMPLET 25/25.

## [5.13.0] — 2026-08-16
### Clavier ouvert : plus rien n'est épinglé — on cesse de poursuivre le viewport

- **Décision de l'auteur après onze versions de correctifs**, et c'est la seule qui supprime la
  classe de défauts au lieu de la déplacer. Le problème, dit simplement : sur iOS, ouvrir le
  clavier logiciel ne rétrécit pas le viewport de **mise en page** — il **panoramique** le viewport
  visuel à l'intérieur. Or c'est au premier que se calent `position:fixed` **et** `position:sticky`
  (les deux — c'est ce que la v5.12.10 avait supposé à tort). Tout chrome épinglé sort donc de
  l'écran, et le poursuivre avec une variable recalculée à chaque évènement revient à courir après
  une cible que le système déplace pendant qu'on la vise : onze versions y sont passées, pour
  remplacer une disparition par des sauts.
- **Ce qu'on fait à la place : on ne poursuit rien.** Tant que le clavier est ouvert, le chrome de
  page redevient du **flux** — en-tête, quai de crise, barre de sélection, poignée d'édition,
  colonne sommaire, volet du quai, barre fixée d'une référence. Il défile avec le contenu, comme
  n'importe quoi d'autre. Rien ne peut plus sauter, puisque plus rien n'essaie de tenir une
  position. Et ce qui compte pendant la frappe reste sous les yeux : **le navigateur garde le champ
  focalisé visible**, c'est son travail et il le fait mieux que nous — il est le seul à savoir où
  il vient de panoramiquer.
- **Ce qu'on perd, et c'est assumé** : pendant la frappe, l'en-tête et le sommaire ne sont plus
  épinglés ; ils reprennent leur place dès que le clavier se ferme. On échange une position tenue
  par intermittence contre un comportement stable et prévisible.
- **Les couches plein écran ne sont pas concernées** : une fenêtre modale, la visionneuse PDF ou
  l'écran d'entrée d'un invité n'ont pas de flux où retomber — elles recouvrent la page. Elles
  gardent le dispositif de la v5.10.9, que l'usage avait confirmé.
- Le rail A→Z, qui est `fixed` et n'a aucun flux, **se retire** pendant la frappe : on tape, on ne
  vise pas une lettre. La compensation de flux de la barre fixée est annulée avec elle — une barre
  rendue au flux occupe sa place, et garder la compensation créerait une bande morte (défaut déjà
  payé une fois, dossier « bande basse iOS »).
- Le garde-fou est **inversé** et garde la nouvelle règle : aucun chrome de page ne peut lire le
  décalage du viewport, et la règle qui libère doit exister **et** couvrir l'en-tête. Vérifié
  capable d'échouer dans les deux sens — il a d'ailleurs raté le second au premier essai, faute
  d'une frontière de mot (`html.kbdX` satisfaisait le motif).
- Mesuré aux deux moteurs et aux deux largeurs : sans clavier l'en-tête est collant, clavier ouvert
  il est `static` et défile de −600 px avec la page, clavier refermé il revient se coller à 0.
  `npm run check` 20/20, `npm test` 2×1126, audit COMPLET 25/25.

## [5.12.11] — 2026-08-16
### Retour à l'état v5.12.9 — j'arrête les correctifs à l'aveugle et je pose le problème

- **La v5.12.10 était une régression, et elle est annulée.** J'avais retiré le décalage du viewport
  visuel aux couches `sticky` en supposant qu'elles suivent la page. Le retour d'usage est sans
  appel — *« le volet continue de sauter, l'en-tête disparaît au scroll en recherche, la sidebar
  aussi »* : sur iOS, une couche `sticky` se cale sur le viewport de **mise en page**, exactement
  comme une couche `fixed`. Les deux disparaissent quand le viewport visuel est panoramiqué. Ma
  distinction était fausse.
- **Ce qui est gardé de la série**, parce que ces points-là ont été mesurés et confirmés : plus
  aucun `scrollIntoView` inutile pendant la frappe (v5.12.9), le compte d'occurrences à chasse fixe
  qui empêchait le bouton « › » de se dérober (v5.12.6), la croix d'effacement centrée sur son
  champ (v5.12.4), la garde du clavier qui empêche le rebond élastique de déplacer quoi que ce soit
  (v5.12.5). Aucune de ces quatre corrections n'était en cause.
- **Ce qui reste ouvert, et que je ne corrigerai pas d'une onzième hypothèse** : le comportement du
  chrome quand un clavier LOGICIEL est ouvert. Onze versions ont été livrées sur un mécanisme que
  le harnais ne peut pas piloter — `visualViewport` n'est pas scriptable en test — et chacune
  reposait sur un modèle mental d'iOS, pas sur une mesure. C'est la faute de méthode, pas le
  réglage.
- La suite tient en un choix, posé à l'auteur plutôt que tranché seul : instrumenter l'appareil
  (afficher les valeurs réelles du viewport pendant qu'on tape, pour corriger sur des chiffres),
  ou **renoncer à épingler le chrome pendant la frappe** (le laisser défiler et laisser le
  navigateur garder le champ focalisé visible, ce qu'il fait très bien) — solution la plus simple
  et la seule qui supprime la classe de défauts au lieu de la déplacer.

## [5.12.10] — 2026-08-16
### Ce qui est `sticky` ne se décale pas — ce qui est `fixed`, si (retour en arrière assumé)

- **L'auteur a fini de cerner le cas** : « ça fonctionne nickel **sauf avec les claviers à l'écran**
  sur tablette/smartphone ». Or le décalage du viewport visuel ne vaut jamais autre chose que zéro
  hors clavier logiciel : **tout** ce qui a été signalé depuis la v5.12.0 — en-tête qui saute, qui
  disparaît, qui est poussé vers le bas avec du contenu au-dessus — vit exactement dans le seul cas
  que ce décalage touche. C'était lui.
- **La distinction que je n'avais pas faite**, et qui explique toutes les observations :
  - `position:sticky` vit **dans le flux**. Quand le clavier s'ouvre, le système fait défiler la
    **page** pour amener le champ focalisé sous les yeux — et un élément collant suit son document.
    Lui ajouter le décalage, c'est le compter **deux fois** : il descend dans la zone visible et
    laisse voir du contenu au-dessus de lui (capturé à t = 5,0 s sur la première vidéo).
  - `position:fixed` est ancré au viewport de **mise en page** et ne suit rien. Lui a bel et bien
    besoin du décalage — c'est le correctif v5.10.9 des couches plein écran, que l'auteur avait
    confirmé, et c'est `#refBar`, la barre de recherche d'une référence, dont la disparition avait
    ouvert tout ce dossier.
- **Retour en arrière assumé sur les v5.12.0 à v5.12.3** : l'en-tête, le quai de crise, la barre de
  sélection, la poignée d'édition et les cinq colonnes collantes (sommaire, rail de lecture, plan)
  retrouvent leur ancrage nu. Gardent le décalage : les couches plein écran, `#refBar`, le volet du
  quai, et la coque de l'accueil large — qui n'est ni collante ni défilante, donc ne peut suivre par
  elle-même. Le token `--stick-off`, créé en v5.12.3 pour les colonnes, part avec elles (plus aucun
  lecteur, règle 14).
- **Le garde-fou est inversé, et c'est désormais le `position:` qui décide** : une couche fixe doit
  porter le décalage, une couche collante ne doit pas. Vérifié capable d'échouer **dans les deux
  sens**. Il a d'ailleurs raté le second au premier essai — `top:var(--hdr-off)` ne mentionne
  littéralement aucune hauteur — ce qui est exactement la forme qu'avait prise le défaut : un
  contrôle qui ne voit pas la forme du défaut ne vaut rien.
- `npm run check` 20/20, `npm test` 2×1126, audit COMPLET 25/25 ; sondes mises au nouveau contrat.
  ⚠ **Ce qu'il faut vérifier sur appareil** : si l'en-tête redevenait introuvable clavier ouvert, la
  conclusion serait que `sticky` ne suit pas ce panoramique — et le remède ne serait pas un décalage
  de plus, mais de passer l'en-tête en `fixed` piloté sur l'évènement du viewport.

## [5.12.9] — 2026-08-16
### Ce qui bougeait à chaque frappe, c'était un défilement inutile — pas le chrome

- **Deuxième vidéo, et elle a écarté ma dernière hypothèse** (« moins marqué mais toujours présent
  à chaque frappe de clavier »). J'y ai d'abord cherché la barre de suggestions d'iOS, qui aurait
  changé la hauteur du clavier à chaque lettre : l'enregistrement montre qu'elle **ne bouge pas**.
  La cause était ailleurs, et bien plus simple.
- **`pfRun` se termine par `pfGo(0)`** : chaque lettre tapée relançait un `scrollIntoView` vers la
  première occurrence. Mesuré au harnais : la page ne bougeait **pas d'un pixel** (`scrollY`
  identique d'une frappe à l'autre) — mais **l'appel** était bien émis à chaque fois, **cinq fois
  pour six lettres**. Or sur iOS c'est l'appel lui-même qui fait re-panoramiquer le viewport visuel
  pour garder le champ focalisé sous les yeux ; le chrome, qui suit ce panoramique, bougeait donc à
  chaque lettre.
- **On ne supprime pas le suivi, on supprime le geste inutile qui le déclenchait** : pendant la
  frappe, la page ne se déplace que si la première occurrence n'est **pas déjà sous les yeux** —
  et « sous les yeux » se calcule sur la bande réellement visible (clavier compris) et sous le
  chrome collant. Les flèches ‹ ›, elles, visent explicitement une occurrence et défilent toujours.
- Mesuré aux deux moteurs : **zéro** appel pendant les six frappes quand la première occurrence est
  visible, **un** quand elle ne l'est pas, **un** par clic sur ‹ ›. Vérifié capable d'échouer
  (comportement d'avant réintroduit : cinq appels).
- `npm run check` 20/20, `npm test` 2×1126, audit COMPLET 25/25.

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
