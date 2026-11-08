# Lot v5.95 — l'accueil à l'échelle : vos collections en tête (A587-A589)

> Fichier normatif. Les numéros A sont des adresses : ne jamais renuméroter. Décidé sur planche, **implémenté en
> v5.95.0** (les écarts à la planche, faits à l'implémentation, sont dits sur place). Amende A489 (sur l'accueil
> seulement), A506/A515 (intertitre), A537 (tuile).

Demande de l'auteur : « comment améliorer l'affichage avec une centaine d'aides et protocoles ? — avec plusieurs
collections, catégories, bibliothèques ». Planche Claude Design « Accueil à 100 aides » (06/11/2026), variante **F2**
retenue par l'auteur : « F2, vas-y, rédige la décision. Par contre garde une option pour tout afficher comme avant
(par catégorie, par bibliothèque, etc.). Adapte as you see fit. »

## Constat — mesuré sur l'app servie (v5.94.0)

Jeu de charge par sonde jetable : 76 aides + 36 protocoles ; Perso, Bloc central (admin), SMUR 75 (éditeur),
Réanimation CHU (lecture) ; 20 catégories dont 3 « Pédiatrie » et 2 « Obstétrique » ; 7 collections ; 6 épingles.

- **Téléphone (390 × 844) : 9 789 px, soit 11,6 écrans.** Les rangées font déjà 53 px ; à 104 éléments, la densité
  compacte ne gagnait que 8 % (7 006 → 6 436 px). Le problème n'est pas la densité, c'est l'orientation.
- **17 groupes de catégorie mêlent les quatre bibliothèques à l'alphabet** (« À trier » de Perso, « ALR » du Bloc,
  « Cardio » du SMUR…) ; « Ventilation » commence à 9 312 px.
- **Les intertitres ne collent plus** : `.dir-book .dir-l{position:static}` depuis les groupes arrondis (A506, A515),
  sans décision écrite ; le commentaire de `renderLibrary` dit encore « intertitres COLLANTS ».
- **Large (1280 × 900) : la colonne gauche fait 1 069 px pour 386 visibles** — aucune des 20 catégories n'est à
  l'écran ; « Bloc centr… », « Réanimatio… » tronqués par le mot de partage.
- **Six épingles prennent tout le premier écran du téléphone**, et aucune tuile ne dit sa bibliothèque : deux « Arrêt
  cardiaque » épinglés (SMUR, Bloc) ne se distinguent que par leur catégorie — écart à A242.
- **La pastille de provenance avale le séparateur** qui la précède (« adulte ·⧉Perso ») et fait passer la méta à la
  ligne au téléphone.

Les collections, mesurées sur le même jeu : 71 aides rangées quelque part, 22 dans deux collections ou plus,
**41 éléments dans aucune** (5 aides et les 36 protocoles).

## A587 — « Vos collections » en tête de l'accueil, « Tout » dessous ; un réglage rend l'accueil d'avant

> **Amendé par A597 (v5.98.0, `lot-v5-98.md`)** : au-delà de 6 collections, la section garde les 5 vues le plus
> récemment (en ordre alphabétique), puis « Toutes les collections · n ».

*Amende A489 (forme écartée « mes rangements d'abord, le catalogue ensuite », option 3) sur l'ACCUEIL seulement : la
colonne gauche garde son ordre. Étend A475 ; garde A515, A523, A537, A545, A556.*

**Le principe d'A475, appliqué à l'échelle : « une bibliothèque, c'est avec qui ; une collection, c'est pour moi ».**
À cent aides, la collection est le raccourci que chacun s'est fait ; l'accueil la montre avant le répertoire, sans
rien retirer au répertoire. C'est la logique de l'Accès direct (« un raccourci ne déménage rien », A515), qui EST la
première collection (`COLL_PIN`).

1. **Au repos, l'accueil se lit en quatre parties, dans cet ordre, à toutes les largeurs (A263)** : En cours (A523) ;
   Accès direct (tuiles, A537 — non répété plus bas) ; **Vos collections · pour vous** ; **Tout**. « Au repos » : ni
   recherche, ni filtre (type, bibliothèque, collection, catégorie), ni sélection — comme le groupe « En cours » se
   retire en sélection (A523). Sous un filtre ou une recherche, l'accueil est celui d'aujourd'hui.
2. **« Vos collections »** : une rangée groupée (A506) par collection personnelle (`colls`), dans l'ordre alphabétique
   (pas d'ordre manuel, A475) — signet, nom, compte des éléments DISPONIBLES, chevron. **Repliée par défaut** : la
   section est un sommaire de quelques rangées. Toucher une rangée la **déplie sur place** (`aria-expanded`), sans
   niveau de retour — l'arborescence « Parcourir » reste écartée (A545). Dépliée, ses rangées sont celles du
   répertoire (même `cfg.row`), avec la provenance selon A242 et « aussi dans … » (`collAlsoHtml`, étendu au groupe
   déplié, la collection elle-même exclue) ; en pied, « Ouvrir la collection › » mène à la vue d'A475 (en-tête,
   « Ajouter », ⋯). Le pli de chaque collection se retient par appareil.
3. **Aucune collection : la section n'existe pas** — pas de section vide ; l'invitation à créer vit déjà dans
   « Afficher » (A545) et dans Moi (A475). Une collection VIDE garde sa rangée (compte 0) ; dépliée, elle dit
   « Cette collection est vide. » au-dessus de « Ouvrir », où se trouve « Ajouter ».
4. **« Tout »** : le répertoire actuel, inchangé, rangé par le réglage « Regrouper ». Intertitre de section « Tout »,
   le compte, et une sous-ligne qui nomme le regroupement (« par catégorie », « par bibliothèque »…). Mot pesé : A493
   a établi que « Tout » dit « aucun tri par collection » ; « Tout le catalogue » (planche) ajoutait un nom que
   l'interface n'emploie nulle part.
5. **Une aide rangée paraît deux fois — dans sa collection dépliée et dans « Tout » — et c'est la même aide** (même
   id, jamais une copie, même étoile, même état). Ce n'est pas le risque d'A242 (deux homonymes de deux
   bibliothèques), qui garde sa provenance.
6. **Le réglage « comme avant »** (demande de l'auteur). Un réglage **« Vos collections : En tête / Non »**, « En
   tête » par défaut, dans « Trier et présenter » au téléphone (A556) et dans la partie « Présenter » d'« Affichage »
   en large (A429) — un segmenté à deux crans, le dessin des autres réglages de la feuille (la planche disait
   « interrupteur » : un interrupteur seul au milieu de segmentés aurait été un second langage pour la même chose).
   Il n'existe que s'il y a une collection. **« Non », l'accueil est celui de la v5.94** : ni section « Vos
   collections », ni intertitre « Tout ».
   Dans les deux positions, Trier (A → Z, Plus récentes), Regrouper (Non, Type, Catégorie, Bibliothèque, A–Z) et
   Densité gardent leurs crans et leur sens : par catégorie, par bibliothèque, etc. restent disponibles tels quels.
   Préférence `ac-home-colls` (`spaceKey`), posée par le même chemin que le rangement (A256) : `localStorage` par
   compte, voyage dans `data.prefs.homeColls`, ÉCRITE par la synchro mais jamais appliquée à l'écran ouvert. Les plis
   (`ac-home-fold` : collections ouvertes, groupes pliés) restent par appareil. Les deux clés entrent dans
   `WIPE_SPACE_KEYS` (A290) : les plis portent des identifiants de collection et des noms de catégorie.
7. **En large, deux gestes, pas deux portes.** La colonne garde son ordre (Bibliothèques, puis Collections, A489) et
   FILTRE (vue de la collection) ; la section de la liste DÉPLIE sur place. C'est déjà le cas de l'Accès direct
   (rangée de la colonne et tuiles de la liste).

**Formes écartées** (planche, par l'auteur ou sur mesure) :
- **F1 — regrouper l'accueil par collection** au lieu des bibliothèques ou catégories : 137 rangées pour 112 éléments
  (une par collection qui contient l'aide) ; « Hors collection » est le plus gros groupe (41) et doit être rangé
  autrement ; un nouveau membre d'une équipe, sans collection, ne verrait que lui.
- Collections **dépliées** par défaut : dans le jeu mesuré, la section repousserait « Tout » de 96 rangées.
- Rouvrir l'app sur la dernière collection ouverte : une liste filtrée à l'ouverture fait croire qu'une aide manque.
- Rangée de puces de collections sous l'Accès direct (A545) ; ordre manuel des collections (A475).

## A588 — Le répertoire se plie par groupe ; le groupe courant se dit en défilant

*Amende A506 et A515 (intertitre statique au-dessus du groupe — conséquence non écrite) ; renoue avec A251 ; garde A542.*

1. **Chaque intertitre de groupe de « Tout » devient un bouton** (`aria-expanded`, compte toujours visible) qui plie
   et déplie son groupe sur place. **Déplié par défaut** : l'accueil d'avant reste l'accueil d'avant. Le pli se retient
   par appareil, par regroupement et par libellé (plier « Trauma » en rangement par catégorie ne plie rien en A–Z).
   « Tout replier » / « Tout déplier » (rangée « Groupes ») dans « Trier et présenter » (et « Présenter » en large) :
   ils agissent sur les groupes de « Tout », les collections gardent leur pli. Replié entièrement, le répertoire
   devient son propre sommaire — un tap par groupe, sans niveau de retour. Activé au CLAVIER, le focus revient à
   l'intertitre redessiné ; au pointeur, aucun anneau (A492).
2. **Le groupe courant se dit en défilant.** Au téléphone, une seule bande en haut (A542) : pas de seconde bande
   collante ; c'est le **petit titre de la barre collée** qui nomme le groupe sous le pouce (« Trauma », coiffé de sa
   section — « Tout » ou le nom de la collection dépliée), au lieu de redire « Aides ». En large, l'intertitre colle
   en tête de sa carte (`position:sticky`, sous ce qui coiffe — hauteur divisée par `--zf`, règle 10), comme A251 le
   voulait. Le commentaire de `renderLibrary` est corrigé en conséquence.
3. ~~Toucher le petit titre collé remonte en haut de l'accueil~~ — **retiré à l'implémentation** : le petit titre est
   un texte décoratif (`aria-hidden`, il double le grand titre) ; en faire une cible aurait créé un contrôle sans nom
   ni rôle, et le geste du système (toucher la barre d'état d'iOS) remonte déjà en haut.
4. Le rail A→Z (A243) est inchangé : il n'existe qu'en rangement A–Z ; le pli s'y applique par lettre.

**Formes écartées** : un cran « Bibliothèque › Catégorie » dans Regrouper (planche A — reporté : les collections en
tête et le pli répondent sans sixième cran ; à rouvrir si la mêlée des bibliothèques gêne à l'usage) ; groupes repliés
par défaut ; un rail de catégories (A243 : des mots, pas des lettres) ; une seconde bande collante au téléphone (A542).

## A589 — La provenance : la tuile la dit, le séparateur ne se perd plus, la colonne ne tronque plus le nom

*Amende A537 §2 (contenu de la tuile) ; applique A242 et A489.*

1. **La tuile d'Accès direct dit sa bibliothèque** dès que le compte a une bibliothèque partagée (la condition de la
   provenance des rangées, `searchLibTag`) : « SMUR 75 » en texte, puis « ● Cardio » dessous. La planche la voulait
   sur une ligne ; mesurée à 390 px, la ligne coupait les deux noms (« Bloc centr… · Obstétri… ») : deux lignes. Sans
   bibliothèque partagée, rien ne change. C'est le régime d'A242 (hors rangement par bibliothèque, toute rangée dit sa
   bibliothèque), que la tuile n'appliquait pas — et une tuile vit hors de tout rangement.
2. **Le séparateur « · » se pose hors de la pastille de provenance** (défaut de dessin mesuré sur captures). *(Amendé par A621, v5.109.6 : il devient l'`::after` de l'élément d'avant, collé par une espace insécable.)*
3. **Pas de redite dans la méta détaillée** : sous un intertitre de catégorie, la rangée ne redit pas la catégorie
   (la compacte le fait déjà, A537) ; sous un intertitre de bibliothèque, la provenance ne paraît que pour un homonyme
   (A242, déjà écrit). La méta tient alors sur une ligne au téléphone dans la plupart des cas.
4. **Colonne large : le nom d'une bibliothèque ne se tronque plus pour son mot de partage** — le mot (« partagée »,
   « lecture », « vous seul ») prend la place qui RESTE (base 0, calé à droite contre le compte) et cède le premier,
   comme l'indice d'un en-tête de colonne (A489). Une répartition par facteurs de rétrécissement (essayée d'abord)
   rognait encore un pixel au nom, donc posait son ellipse.

## Laissé en l'état (arbitrages de la planche, tranchés « as you see fit »)

- **« Pédiatrie » dans trois bibliothèques** : le filtre de catégorie retient un NOM (A419), inchangé.
- **Six épingles au téléphone** : les tuiles gardent leur dessin (A537) ; la ligne de provenance (A589) les allonge
  peu (elle remplace la ligne de catégorie).
- **La feuille « Afficher »** (planche C : bibliothèques pliées, catégories dedans) : non retenue pour ce lot ; les
  bibliothèques restent en puces (A556). À rouvrir avec le cran « Bibliothèque › Catégorie ».

## Mesuré après implémentation (v5.95.0, même jeu de charge)

- Réglage « Non » : 9 169 px au téléphone au lieu de 9 789 — le seul effet d'A589 §3 (la catégorie ne se redit plus,
  les méta passent moins à la ligne). Réglage « En tête » : la section ajoute 7 rangées repliées (≈ 420 px).
- Tous les groupes pliés : le répertoire tient en 17 intertitres ; « Garde SMUR » déplié montre ses 25 aides sur place.
- Colonne large : « Bloc central », « Réanimation CHU » entiers ; le mot de partage s'ellipse à sa place.

## Témoins et couplages

- `audit-doctrine` « Accueil · A587-A589 collections en tête, groupes pliables, provenance » (390 et 1280, 22
  contrôles) : section au repos, repliée, dépliée sur place avec « aussi dans » et « Ouvrir », la même aide dans
  « Tout » ; absente sous type, catégorie, sélection, recherche ; « Non » = même répertoire sans section ; pli retenu
  au rechargement ; pli d'un groupe propre au regroupement ; « Tout replier / déplier » ; collant en large, petit
  titre au téléphone ; tuile, séparateur, catégorie non redite ; nom de bibliothèque entier. **Vérifié capable
  d'échouer** : section affichée sous filtre, tuile sur une ligne, intertitre non collant → 5 rouges.
- Réécrit sciemment : « bouton rond : Trier et présenter » (A556) — la feuille gagne « Vos collections » et « Groupes »,
  toujours aucun filtre.
- Surface capturée : `design/captures/accueil.html` relevée, `design/ds` régénéré ; `GUIDELINES.md` (accueil, place
  des collections) mis à jour.
- Lien `#collection=<id>` (A586) inchangé : il ouvre la vue filtrée, pas le groupe déplié.
