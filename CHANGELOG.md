# Journal des modifications

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

## [5.10.0] — 2026-08-14
### La vue « Page » devient un document

La Page SFAR était une bonne vue d'algorithme enfermée dans une mauvaise page : une colonne qu'on
déroule, **sans titre, sans date, sans source**, et **sans les repères posologiques** — qui partent
dans le rail au-delà de 780 px, donc n'existaient nulle part sur le papier. Quatre lots d'un brief
d'implémentation externe, avec ses maquettes aux trois formats. Doctrine : `AGENTS.md` A133 à A138.

- **Une COQUE de feuille** — cartouche daté (sur-titre, titre, révision, comptes), trois cellules
  d'entrée, l'algorithme et sa **colonne de référence** (surveillances, complications « à tout
  moment », minuteurs et compteurs déclarés), les **doses en pied sur trois colonnes** avec la
  source et un pied de page. Ce qui n'a rien à dire n'existe pas : pas de dose → pas de bande, pas
  de surveillance ni d'excursion → pas de colonne, et l'algorithme prend toute la zone.
- **⚠ L'avertissement de validation s'affiche enfin.** Certaines fiches portent, dans leurs
  sources, « Fiche générée par IA le … — à relire et valider avant usage » — le prompt d'import
  l'impose. Cette phrase n'apparaissait **nulle part** à l'écran : une feuille imprimée et affichée
  au mur sans elle est un danger. Elle est dans le cartouche, au registre ALERTE en **contour**,
  jamais un aplat.
- **Le tracé passe en GRILLE UNIQUE** — six pistes, tronc sur quatre, centré. Les branches étaient
  des conteneurs imbriqués : la largeur se divisait à chaque niveau (1130 → 565 → 282 → 141), et
  sur une fiche à quatre niveaux la partie la plus **grave** de l'algorithme finissait dans la
  colonne la plus étroite, empilée, fourches masquées. Chaque nœud est désormais un **frère** placé
  par `grid-column`/`grid-row` : il occupe l'étendue libre à sa ligne, donc **une branche profonde
  peut être plus large que celle dont elle descend** (répartition au prorata de la hauteur, minimum
  une piste, reste à la plus haute). La fourche est dessinée **en divs**, ses bras en pourcentage
  du centre de chaque branche : la géométrie suit la grille sans qu'on la mesure.
- **Une largeur d'AUTEUR, et le zoom pour l'ajuster.** La feuille fait 1130 px à toutes les
  largeurs et **ne se reflue plus** : aux trois formats c'est la même image — celle qui se
  mémorise — et c'est l'échelle qui s'adapte (`⤢ Ajusté`, `−`/`＋`, `1:1`, par pas discrets).
  Elle s'ouvre toujours à la taille d'auteur : ajuster d'office mettrait toutes les cibles sous
  13 px réels dans un écran qu'on ouvre pendant un soin.
- **L'impression en fait un vrai document** : aucune cellule coupée, doses à 3 colonnes en paysage
  et 2 en portrait, k = 1 — et surtout **l'état de session ne s'imprime pas** (✓, « ici », « hors
  chemin », « ×n » décrivent une réanimation qui n'a plus lieu ; une feuille au mur qui porte le ✓
  d'une session passée est une feuille fausse). Le test du lot : si la sortie papier est utilisable
  **sans** l'application, la page est réussie.
- **« Tableau », avant le soin, ouvre la même feuille** — un seul générateur des deux côtés. Elle y
  est inerte au geste près de l'échelle : on vient la regarder, pas la conduire. **Et la même
  fenêtre s'ouvre depuis le soin**, par une porte « ⤢ Plein écran » de l'onglet Page : même coque,
  même sortie, même page — jamais une seconde surface à tenir.
- **Les retours ↺ ne mordent plus sur un bloc** (signalé à l'usage) : dans une grille à six pistes,
  la voie traversait les branches voisines. Ses deux extrémités sont bornées à la gouttière.
- **Ce qui n'est pas livré, et pourquoi** : le cartouche ne se répète pas en tête de chaque feuille
  imprimée — seul un en-tête de table le fait nativement, et le simuler demanderait de reperdre la
  grille unique. Le pied porte titre et révision, donc une page détachée reste identifiable.


## [5.9.0] — 2026-08-13
### L'atelier d'import va jusqu'à la question destructive

`5.8.0` avait posé le grain — l'entité — et `5.8.1` l'avait tenu partout. Restait le geste que
l'atelier existe précisément pour éclairer : **remplacer**. La rangée annonçait qu'une entité était
« déjà présente » sans dire ni **laquelle des deux versions est la plus fraîche**, ni **ce que
remplacer coûterait**. Doctrine : `AGENTS.md` A131 et A132.

- **La rangée dit laquelle des deux est la plus récente** — « le fichier est plus récent »,
  « votre version est plus récente », « même version ». Le second cas est le seul où remplacer
  **perd du travail** : il prend le registre ATTENTION, en texte et avec son glyphe, jamais un
  aplat. Aucun champ nouveau : `updatedAt` **est** la révision, celle-là même dont le compte rendu
  se sert déjà pour dire sur quelle version un soin a été conduit.
- **⚠ Et l'horodatage est lu *avant* la normalisation**, parce que celle-ci en pose un quand il
  manque — un fichier ancien se serait donc annoncé « plus récent » que tout ce qu'on possède, sur
  la seule question destructive du parcours. Sans date des deux côtés, la rangée **se tait** plutôt
  que de deviner.
- **« Comparer » déplie ce que remplacer changerait**, ligne à ligne : ce que le fichier
  apporterait, ce qu'il emporterait. C'est le comparateur de « Versions », inchangé — pas un
  second, qui finirait par répondre autre chose sur la même paire d'objets. Les **références** ont
  leur propre aplatissement (leur corps est du texte, ses lignes sont ses unités) : sans lui, la
  moitié de la bibliothèque n'aurait eu aucune réponse à la même question.
- **Ce qui n'est pas fait, et pourquoi** : descendre au **grain du bloc**. Un bloc ne porte que des
  identifiants d'items d'un pool partagé et se relie aux autres par ses branches — en importer un
  sous-ensemble produirait des blocs vides et des branches qui ne mènent nulle part. Un algorithme
  partiel n'est pas un algorithme allégé, c'est un algorithme cassé.

## [5.8.1] — 2026-08-13
### L'atelier d'import, jusqu'au bout : le filtre atteint tout ce qui s'écrit

`5.8.0` avait posé le grain de l'import — l'entité — sans le tenir partout : trois choses
raisonnaient encore **en bloc** derrière l'atelier, et la rangée taisait ce qui permet de décider.
Doctrine : `AGENTS.md` A130.

- **Les catégories suivent la sélection.** Elles entraient *toutes*, y compris celles que seules
  les entités décochées employaient : on repartait avec des catégories vides dans son rail, créées
  par un import qu'on venait justement de restreindre. La règle qui en sort est plus large que le
  cas : *le filtrage doit atteindre tout ce qui s'écrit, pas seulement les entités.*
- **La question destructive annonce la sélection, pas le fichier** — « remplacé(e)s par les
  **n éléments cochés** ». Depuis l'atelier les deux ne sont plus la même chose, et c'est la seule
  question destructive du parcours : y annoncer le fichier ferait croire qu'on récupère ce qu'on
  vient d'écarter.
- **« ⟳ déjà présent » se dit sur la rangée, avant la question « Doublons ».** La rangée porte le
  fait ; le sort reste décidé par la question groupée. Elle n'apparaît **que là où la collision
  peut avoir lieu** — identifiants conservés, donc même espace : sur un fichier venu d'ailleurs ils
  sont régénérés à l'écriture, et annoncer un doublon que l'écriture ne verra pas serait un
  mensonge. *Un contrôle « remplacer / garder les deux » par rangée a été écarté* : décocher porte
  déjà le grain, tandis que ce choix-là est une stratégie, globale par nature.
- **La rangée dit ce que l'entité embarque**, dans les mots de l'écran d'entrée : « 2 blocs ·
  1 minuteur · 1 complication déclarée ». C'est la seule chose qui distingue un algorithme complet
  d'une ébauche sans ouvrir le fichier. Une phrase, **deux lecteurs**, donc un seul calcul ; seuls
  les seuils diffèrent, et chacun est motivé.
- **Détail de plancher** : à 320 px les deux gestes de l'atelier tenaient sur une ligne mais s'y
  cassaient chacun en deux. La rangée enroule désormais plutôt que les mots — les boutons restent
  côte à côte à 44 px, c'est le compte qui passe dessous.

## [5.8.0] — 2026-08-13
### « Voir avant d'écrire, revenir sans chercher »

Fin du lot v5.7 : son dernier item de plan — **l'atelier d'import** —, les deux retours au soin
qui manquaient, et les deux correctifs *à zéro pixel* que le **refus** du « plan de vol » sur
l'écran de crise avait révélés. Comme le lot précédent, rien ici ne déduit quoi que ce soit d'un
paramètre patient. La doctrine est dans `AGENTS.md` § « Lot v5.7 » (A124 à A129).

**Ce qui entre dans la bibliothèque**

- **L'atelier d'import — le grain n'est plus le fichier, c'est l'entité.** Un `.json` ou un `.zip`
  entrait EN BLOC : on répondait à trois questions (destination, fusion, doublons) sans avoir
  jamais vu ce qu'il contenait. Sur un export de bibliothèque, c'est dix-huit aides qu'on acceptait
  sur la foi d'un nom de fichier, et le seul recours après coup était de les supprimer une par une.
  L'ordre est renversé : **d'abord ce que l'on importe, ensuite où**. Une rangée par entité — type,
  titre, **état déclaré par le fichier**, ce qu'il reste à relire, nombre de PDF —, tout coché au
  départ : l'atelier sert à *retirer*, il ne demande pas de tout re-cocher.
- **Le filtrage précède toute écriture**, et c'est le point dur : les deux listes sont réduites à
  la sélection *avant* les questions, donc avant `migrate`, `persist` et surtout `importAtts`. Un
  binaire du `.zip` n'entre **jamais** pour une entité décochée — non par un filtre posé après
  coup, mais parce que la liste filtrée est la seule qui existe ensuite.
- **L'état entrant est préservé** : les trois portes forçaient « Brouillon ». C'était un proxy de
  « vous n'avez pas encore relu ceci » ; l'atelier montre désormais cet état *avant* l'écriture,
  rangée par rangée. Le coût du forçage était réel — **restaurer une sauvegarde ramenait dix-huit
  aides validées en brouillon**, donc hors de l'accès de crise (un brouillon ne s'épingle pas et
  reste masqué aux lecteurs d'une bibliothèque partagée). L'objection est nommée dans la doctrine :
  ce qui protège du « Validée » non relu, c'est la rangée qui le dit, plus le prompt IA qui impose
  `"status":"draft"` — contrat vérifié par `audit-prompt`.
- **La pastille « △ n »** est le *même* calcul que le volet « Relecture » de l'éditeur : deux
  comptes écrits séparément divergeraient. Elle ne conditionne rien — une remarque de relecture
  n'est pas un refus.
- Trois défauts trouvés sur le trajet et corrigés : un fichier ne portant **que** des références
  répondait « Import interrompu » alors qu'il était parfaitement valide ; un contenu vide disait
  « 0 fiche importée », une phrase qui ne désigne pas sa cause ; les questions comptaient le
  *fichier* au lieu de la *sélection*.

**Revenir au soin**

- **Rouvrir l'application pendant une session vive dépose dans le soin**, plus sur l'accueil : un
  tap de moins au seul moment où l'on n'en a aucun à donner. Trois bornes — une seule session
  vive, dix minutes sans le moindre geste au plus, et jamais quand un lien d'invité est présent.
  Le « ‹ » de l'en-tête ramène à la bibliothèque : personne n'est enfermé.
- **La barre de retour au bloc courant** est affinée sur trois signalements : elle ne **clignote**
  plus au re-rendu (un nœud détaché n'est pas « hors zone » — l'observateur surveillait l'ancienne
  carte), elle prend la **boîte de la barre flottante** au lieu de celle de la page, et elle
  **s'empile** sur le volet du dock au lieu de le recouvrir, en redescendant d'elle-même à sa
  fermeture.
- **Le passage qu'on interrompt se replie.** Après une complication reprise, deux cartes ouvertes
  du même bloc se suivaient avec les mêmes étapes. La navigation, elle, était juste — un témoin
  écrit *avant* toute correction l'a tranché. L'invariant du journal n'est pas touché : on ne
  transforme pas le passage en chip, on pose le repli manuel, et un tap rouvre l'ancienne carte.

**Lire l'état**

- **Un minuteur armé puis mis en pause cesse d'être muet.** Il ne figurait dans aucun segment de
  la capsule et n'avait pas d'alarme à venir : il n'existait donc nulle part sans ouvrir le volet,
  alors qu'il porte un temps qui a cessé d'avancer. « ⏸ n en pause » rejoint le rappel du quai.
- **La progression d'un jalon sort de son bloc** : « Chocs 2/3 » disparaissait dès qu'on était
  ailleurs, pendant que le compte, lui, continuait d'avancer. Elle rejoint le volet, en quatrième
  famille — une ligne, pas une carte, et aucun geste n'y est posé.
- **Le plan de vol est refusé sur le chrome de crise et livré dans le moniteur.** Éprouvée contre
  le contenu réel des fiches, la proposition ne gardait qu'un bénéfice rare pour ~52 px permanents
  dans une colonne dont le budget est tenu à 30 % ; sur un afficheur qu'on lit à deux mètres, les
  pixels sont gratuits et une bande de temps est la bonne forme. Trois registres de trait, et l'on
  ne peut pas confondre un fait avec une promesse : point = c'est arrivé, trait plein = c'est daté,
  tiret = c'est projeté si rien n'est touché. Un jalon compté n'y entre jamais — le dater
  reviendrait à prédire le rythme auquel l'équipe va agir.

**Géométrie, densité, finitions**

- **En exercice, le volet recouvrait la capsule de 63 px** : le bandeau du placard vit dans le
  flux et pousse le quai vers le bas, alors que la position du volet se dérivait d'une *somme de
  hauteurs*. Il suit désormais le bas **réel** du quai — correctif borné au volet : partout
  ailleurs, une géométrie de chrome continue de ne jamais dériver d'une position de défilement.
- **En session, le haut de page cesse d'être du vide sous le quai** (18 → 8 px à 390, 24 → 14 à
  1280) : le quai ferme déjà le haut, cet écart n'y sépare plus deux objets.
- **La ligne de reprise après interruption** est refaite : une rangée *dans* la carte, un nombre
  qui **vit** (un nombre figé qui annonce « il y a 6:12 » ment dès la minute suivante), et une
  sortie explicite à 44 px.
- **Les cartes épinglées prennent le rythme du répertoire** — elles s'étalaient sur toute la
  largeur (976 px contre 320) pour l'accès le plus rapide du produit.
- **Le parcours inerte se resserre en deux passes** (416 → 368 px avant le soin, 435 → 411 en
  session) : les marges cèdent, jamais le contenu. Le plancher est dit — 32 px hors crise, et en
  session un **pas** de 44 px que la règle des cibles rend non négociable.
- **Balayage des glyphes littéraux** : six sites passent aux tracés `uiIcon`, et les deux familles
  qui restent en texte sont nommées (le vocabulaire abrégé des renvois, les glyphes de commande du
  dock).

**Témoins**

Deux entrées neuves : la section `A129 · l'atelier d'import` d'`audit-doctrine` — vrai `.zip`
fabriqué par `zipBuild`, entré par le point d'entrée réel, vérifiée capable d'échouer (filtrage
neutralisé et forçage réintroduit → trois rouges) — et la surface `atelier d'import` d'`audit-a11y`,
qui construit son cas avec les deux natures **et** une pastille : sans elles, la moitié des objets
de la rangée ne serait pas mesurée.

## [5.7.0] — 2026-08-13
### « La bonne information, au bon moment, au bon endroit »

Audit transverse passé à trois tests : le **LIEU** (l'information est-elle là où le geste a
lieu ?), le **MOMENT** (arrive-t-elle avant la décision ?), le **GESTE** (le plus fréquent est-il
le moins cher ?). **Rien dans ce lot ne déduit quoi que ce soit d'un paramètre patient** : chaque
apport est une soustraction d'horodatages, un comptage de cases, ou un déplacement d'information
déjà présente vers l'endroit où elle décide. La doctrine complète est dans `AGENTS.md`
§ « Lot v5.7 » (A113 à A123).

**Pendant le soin**

- **La barre de retour au bloc courant.** Trois mécanismes ramenaient déjà au soin et aucun ne
  couvrait le cas le plus fréquent : `landOnBout` ne joue qu'à la réentrée dans la fiche,
  `ovAdvanceRender` qu'au geste d'avancement, `cxScrollTo` qu'à l'entrée sur complication. On
  défilait pour relire une étape ou vérifier une dose, et l'on remontait en cherchant la carte à
  bordure bleue. Une zone flottante **bornée** — sur le précédent déjà accepté du geste d'entrée
  (v4.73.0) — n'existe que tant que la carte du bloc courant est *entièrement* hors de la zone
  utile, nomme sa destination et s'efface d'elle-même. Elle ne défile jamais toute seule.
- **Le retour d'interruption restitue la conscience de situation.** Vérifié : zéro occurrence d'un
  « temps depuis le dernier geste » dans le fichier — les cinq écouteurs de `visibilitychange`
  persistaient, reprenaient l'audio, redemandaient la veille, mais aucun ne disait à quelqu'un qui
  revient depuis combien de temps il n'était plus là. Une ligne, en tête de la carte du bloc
  courant, au-delà de deux minutes d'absence, effacée **au geste suivant** — jamais après un délai.
- **Un compteur dit « il y a », pas seulement « à ».** La trace disait l'instant du dernier
  incrément ; en réanimation la question est toujours « ça fait combien de temps ? ». Les deux
  désormais : le T+ se relit, le « il y a » décide. Vivant, sans re-rendu, **sans aucun seuil** —
  un seuil serait un jalon, et les jalons sont un champ d'auteur. Le chiffre pousse au tap
  (130 ms, `transform` seul, remplacée et jamais mise en file).
- **L'imminence d'un minuteur est un état, et le tri devient vivant.** L'ordre suit le temps
  restant, l'alarme passe devant ; un minuteur qui entre dans ses vingt dernières secondes est
  **marqué** — glyphe △ et encre ambre, sans aplat ni battement : l'aplat reste réservé à ce qui
  exige une action maintenant, le battement est la grammaire de l'alarme. La réorganisation est un
  FLIP en `transform` pur (180 ms). **Rien ne bouge sous un doigt posé**, ni pendant les 1,2 s qui
  suivent le geste : assez pour lire la réponse de la carte qu'on vient de toucher. Non bloquant
  par construction — le délai ne suspend que la réorganisation.

**Avant et après le soin**

- **« Terminer la session ? » dit ce qui reste ouvert** — deux lignes de faits comptés, au seul
  instant où ils servent encore. « Terminer » reste rouge plein et actif : une checklist annonce
  son incomplétude, elle n'interdit pas de la quitter. Ni score, ni pourcentage, ni « conformité ».
- **Ce que la fiche embarque se dit avant qu'on entre.** En voie étroite — la cible principale — un
  minuteur à cycles écrit par l'auteur était invisible tant qu'on n'avait pas démarré. Une ligne
  dérivée : « 6 blocs · 2 minuteurs · 1 complication déclarée ». Rien à dire, aucune ligne.
- **Une aide révisée depuis votre dernier passage le dit.** Dans une bibliothèque partagée, un
  collègue révise une aide qu'on croit connaître par cœur. La ligne ne conditionne rien et ne dit
  pas *ce qui* a changé — « Versions » est dans le menu ⋯ pour cela.
- **Le compte rendu donne l'écart, et rien d'autre.** Une colonne Δ entre deux gestes du **même**
  objet, nue : ni moyenne, ni intervalle cible, ni couleur qui vire — ce vocabulaire ferait
  basculer le document du côté de l'évaluation par le logiciel.

**Pour l'auteur**

- **La relecture cesse de ne signaler que des fautes : elle propose.** Les six détections
  existantes étaient toutes des manques. Trois détecteurs lisent désormais le texte *de l'auteur* :
  une cadence (« toutes les 3 min », « à 5 min », « q4h ») propose un minuteur à cycles **avec la
  période lue dans sa phrase** ; « renouveler / seconde dose / nouveau choc » propose un compteur ;
  une étape vitale sans aucune ★ propose le memory item. Rien n'est jamais créé automatiquement, le
  texte n'est jamais réécrit, le compteur naît **sans nom** — deviner un mot serait la
  dégénérescence de « PA 2 » sous un autre visage. Un seul chemin de création (`edAdd`), et un refus
  ne revient pas de la séance.

**Deux propositions retirées après vérification, et c'est la même leçon.** Le téléchargement de
fond des documents existe déjà, systématique et pour toute la bibliothèque — la proposition aurait
*restreint* aux épinglées une garantie volontairement universelle. Et le virage au vert de
« Continuer » est déjà entier ; il n'y manquait qu'un fondu, or le libellé bascule au même instant :
on aurait obtenu une couleur qui s'attarde sous des mots qui ont déjà sauté.

**Décor et garde-fous.** La fiche d'exemple ACR porte un second minuteur déclaré — le
réordonnancement vivant n'avait sinon aucun cas à rencontrer, et un témoin écrit sans cas est un
vert qui ne mesure rien ; il est à relance manuelle, un second minuteur *cyclique* faisant
disparaître le cas d'un autre témoin (`cycleHint`). Quatre sections entrent dans `audit-doctrine`
(P1, Q2, P4b, Q1), toutes **vérifiées capables d'échouer** — défauts réintroduits, 9 rouges au
total, fichiers restaurés à l'octet. Le cliquet `pointer-events:none` de `check-anim` passe de 18 à
19, motivé sur place. 47 témoins purs neufs (1040 au total, sur les deux moteurs).

## [5.6.0] — 2026-08-09
### Refonte complète du design — direction « verre clinique, mat »

Refonte menée avec Claude Design (phases 0 à 6 : audit de l'existant, directions explorées,
convergence, design system, écrans qui font foi, passation en sept lots). Les maquettes livrées
sont la référence d'implémentation ; ce qui suit est ce qui a été porté dans le monofichier, avec
les décisions consignées — la doctrine complète est dans `AGENTS.md` § « Refonte v5.6 ».

**TROIS MATIÈRES, TROIS NATURES.** Sombre (`--sys`) = SYSTÈME : la capsule d'état et le dock, les
deux seuls objets sombres du produit — trouvables sans lire. Blanc (`--work`) = TRAVAIL : carte,
feuilles, éditeurs ; seule matière qui projette une ombre. Gris (`--amb`) = AMBIANCE. La
séparation commandes/affichage de l'ECAM passe désormais par la MATIÈRE, plus par des bandes et
des filets empilés — ce qui **rouvre la v4.25.0** en gardant son esprit et en inversant sa forme.

- **Lot 1 — tokens.** Nouveau bloc `:root` (matières, encres, registres, échelle typographique
  fermée à sept crans `11 / 12 / 13,5 / 15 / 17,5 / 21 / 24`, rayons `8 / 10 / 12 / 14`, une
  seule ombre, cibles, mouvement) ; les anciens noms deviennent des ALIAS, aucune règle CSS n'a
  eu à changer pour que le fichier compile. **Un seul ambre** (`--verify` et `--alert` fusionnent
  en `--warn`) et **un seul rouge**. Nuit redessinée en OLED GRIS (`#0d0f13`) : sur OLED, le noir
  pur fait « trou » et le halo des textes clairs fatigue. Trois fontes vendorisées (Manrope
  variable 500-800, IBM Plex Mono 600/700, 45 Ko au total, précachées) : le SERIF ne sort que sur
  un titre de fiche, le MONO que sur une valeur, Manrope tient tout le reste.
  **⚠ TROIS TOKENS NE SONT PAS DES ALIAS, et les harnais l'ont prouvé** : `--paper` reste un
  blanc FIXE (aliasé sur la matière travail, le QR se peignait en encre sombre sur fond sombre —
  indéchiffrable, et le défaut ne se serait vu qu'au moment de scanner) ; `--shadow-up` garde son
  décalage négatif ; `--ctl-line` tient 3:1 là où le `--line-strong` du système n'en fait que 1,6
  — WCAG 2.2 § 1.4.11 vise les bordures de COMPOSANT, c'est-à-dire la case qu'on vise avec des
  gants. Le bloc de dérivation `color-mix` de la direction A est retiré : les valeurs tonales du
  nouveau système sont des accords qu'aucun mélange ne reproduit.
- **Lot 2 — chrome de crise : deux objets, deux natures.** `#crisisBand` (comme bande),
  `#crisisCtrl` et `#crisisDock` (comme rangées) laissent la place à une **capsule d'état**
  (matière système, gabarit constant de 50 px, tap = volet minuteurs/compteurs/journal) et à un
  **dock bas de quatre touches** (⤢ Tout voir · ▤ Consulter · ⚡︎ Complications · ⏱ Noter l'heure).
  Chrome haut **175 → 131 px** à 390 px, trois `border-bottom` empilés en moins, et les quatre
  gestes de session sous le pouce. En-tête à trois zones ancrées (A14) : le **sur-titre
  « ■ MODE CRISE » passe AU-DESSUS du titre** — accolé au nom de la fiche, le statut se lisait
  comme un fragment de ce nom — et la pilule `#hdrCrisis` est purgée (un seul énoncé du mode).
  `fitCtrlRow` disparaît avec la rangée qu'elle ajustait ; `syncHdrScroll` reste, parce que
  `--hdr-h` et `--stick-top` nourrissent le rail A→Z, le rail de lecture, `stickBase()` et le
  `scroll-margin` qui empêche le masquage total d'une cible d'ancre (exigence AA).
- **Lot 3 — carte de travail et journal.** L'étape critique se **MARQUE** (case rouge + ⚠ + corps
  17,5 px + cadence mono ambre) et ne prend plus **ni cadre ni aplat** : mesuré à l'usage, à cinq
  étapes l'aplat happait l'œil et détruisait la lecture de la séquence — l'aplat coloré est
  désormais réservé à l'alarme active, et il n'y en a qu'un à l'écran. « ICI » quitte la carte
  (trois signaux l'y désignaient déjà, `aria-current` compris) et ne vit plus que dans une LISTE.
  L'historique du journal se replie en **une ligne-bilan qui se tire** (« ⌄ fait · ✓ n passages ·
  a→b ») dès qu'elle existe : ~11 objets à l'écran contre 25.
- **Lot 4 — rail et cockpit.** Cartes de minuteur à gabarit FIXE entre veille et échu (A9 : un
  changement d'état non commandé ne déplace jamais rien — le piège n'est pas la structure, c'est
  le libellé qui passe sur deux lignes). **A15 : « Consulter » n'évince plus le bloc au cockpit**
  — à partir de 1200 px la référence s'ouvre dans la colonne d'état, le bloc reste sous les yeux
  et cochable ; sous 1200 px elle reste une excursion à retour nommé.
- **Lot 5 — accueil.** Navigation uniformisée : le sélecteur « A–Z | Catégories » choisit la CLÉ
  DE GROUPEMENT de la même liste, et le rail droit est le MÊME index dans les deux modes (lettres
  ↔ pastilles de catégorie) — on ne perd jamais de fiche en changeant de clé, c'est ce qui
  distingue un groupement d'un filtre. Le résumé des filtres actifs rejoint l'en-tête de section.
  La session vive devient le seul objet sombre de l'accueil.
- **Lots 6 et 7 — fenêtres, documents, éditeur.** Re-peau par les tokens ; les règles nommées du
  plan étaient déjà tenues (listes cochables jamais barrées, session terminée = archive sans
  matière système ni dock, exercice = placard permanent jamais filigrane).

**Volets système — doctrine d'occultation consignée (V1-V3).** Un volet ne s'ouvre que sur tap
d'une touche du dock ; fermeture triple (re-tap, ✕, tap hors volet) plus le retour système ;
l'alarme reste TOUJOURS en vue (capsule en haut, volets en bas — règle FMA de l'ECAM) ; hauteur
plafonnée à 45 % et l'interruption s'annonce en tête (AC 120-71B §5.5). **⏱ l'heure prime** : le
tap horodate immédiatement, le volet n'est que la nomination facultative. **⚡︎ bifurcation
annoncée** : nom, condition d'entrée et destination avant le tap — et **à un seul événement il n'y
a pas d'index**, la touche porte son nom et l'on entre d'un tap.

**Ce que les harnais ont attrapé, et qui n'aurait pas été vu autrement** : le QR indéchiffrable en
thème sombre, l'ombre montante devenue descendante, la capsule à 27 px de cible dans l'en-tête, le
focus invisible sur un champ d'éditeur, le segment ÉCHU sacrifié par la boucle d'ajustement parce
qu'un `flex:none` l'empêchait de rétrécir, et une fonction (`ovPaintLive`) emportée par une
suppression à la tranche. Les témoins ont été **retargés, jamais désarmés** : ce qui change est
l'adresse d'un composant, pas la propriété mesurée — et là où la propriété elle-même a changé
(l'échelle typographique, le seuil du code d'appariement, « ICI » sur la carte), le témoin dit
désormais ce que la règle veut dire plutôt qu'un chiffre.

**Passe de fidélité aux maquettes (même version).** Relecture écran par écran contre les planches
« 4 — Écrans », qui font foi ; les divergences relevées portaient toutes sur la MATIÈRE et la
DENSITÉ, jamais sur la structure :
- **Carte de bloc** : plus de liseré d'accent ni de pastille numérotée — la carte est une surface
  de travail (filet fin, rayon 14, rembourrage 18, l'ombre unique), son en-tête est « BLOC n » en
  petites capitales grises avec le compte en mono à droite, et le titre prend le cran 21. A12 est
  tenue autrement et mieux : la position se lit à ce que la carte est le seul bloc OUVERT, en tête
  de journal, et porte `aria-current="step"` — le seul des trois canaux qu'un lecteur d'écran voit.
- **Pied de carte** : « Vérifier :: » et « Continuer » sur UNE rangée, le premier à gauche, le
  second dernier et pleine largeur restante ; et « Vérifier :: » n'existe que si le bloc porte
  réellement des challenges (A7 était écrite, elle n'était pas appliquée).
- **Chapeau « Ne pas oublier »** : replié, ce n'est plus un pavé au registre ALERTE en tête de la
  colonne d'action mais une LIGNE — ■ rouge, mot en encre douce, compte en pilule neutre. Déplié
  et hors session, il reprend son cadre : c'est alors la condition d'entrée, et le registre est
  juste. Un pavé rouge permanent désensibilisait au rouge exactement comme l'aplat d'une étape.
- **Rail** : la colonne AFFICHE, on la touche pour COMMANDER. Une carte de minuteur y montre nom ·
  cycles · valeur (76 px) ; barre, « Cycles : n » et boutons ne paraissent qu'au tap — sauf pour un
  minuteur ÉCHU, dont le « RELANCER » reste sous les yeux, et pour les ± d'un compteur, devenu une
  RANGÉE. Un repère posologique signalé s'y marque sans aplat. Le panneau et le volet gardent la
  carte complète : on les ouvre justement pour régler.
- **Accueil** : la recherche devient une carte de travail (elle était un creux gris, lu comme une
  zone désactivée), l'avatar un carré arrondi de matière système à initiales (le disque bleu plein
  était le plus gros aplat coloré de l'écran, devant tout contenu clinique), les deux autres
  boutons d'en-tête des glyphes de commande, et le sélecteur « A–Z | Catégories » prend sa propre
  rangée au-dessus des sections qu'il réordonne.
- **Case d'étape à 26 px** (la cible reste la rangée entière, 60 px).
- **Au cockpit, la capsule cesse d'être une capsule** (signalé à l'usage : « sur ordinateur ça
  fait moche »). Montée dans l'en-tête, elle y gardait sa MATIÈRE SYSTÈME : une pilule sombre
  posée sur une barre claire, entre un titre et deux glyphes — un objet qui a l'air d'un contrôle
  sans en être un. La matière suit désormais le LOGEMENT : dans l'en-tête, l'état est du contenu
  d'en-tête (encre de la barre, registres du thème clair pour l'alarme, fond transparent), et il
  est CENTRÉ EN ABSOLU comme A14 l'exige — un titre long ne déplace plus l'alarme. Le sombre reste
  là où il veut dire quelque chose : la capsule en étroit et le dock. Coût de hauteur nul (65 px,
  inchangé), cible 44 px par le halo.
  ⚠ Deux défauts trouvés en le faisant : `flex:1` dans un conteneur en ajustement au contenu
  effondrait la boîte, et la boucle d'ajustement — qui MESURE — en concluait que plus rien ne
  tenait : elle sacrifiait le segment ÉCHU et n'affichait que « +1 ». Et `audit-a11y` CRÉDITAIT un
  halo forfaitaire de 8 px dès qu'un élément était en position relative, au lieu de lire l'inset
  réel : il déclarait trop petite une cible de 46 px, et — plus grave — en offrait 8 gratuitement à
  tout élément positionné pour un autre motif. Il mesure désormais ; il a immédiatement trouvé une
  compaction morte qui rabotait les touches du dock à 41 px.

⚠ Deux défauts introduits par cette passe et rattrapés par les harnais : le nom d'un minuteur repris
en `--ink-3` tombait à **2,32:1** (l'encre d'étiquette n'est jamais du texte porteur — règle écrite
depuis la v4.5), et l'étiquette d'un bloc HORS TRONC affichait « ⚡ Bloc » alors qu'un bloc détaché
n'a, par construction, pas de numéro.

Contrôles : `npm run check` vert (échelles typo, espacement, rayons, couleurs, paliers, SW,
vendor, uploads, SQL, stores, icônes, harnais, hashs CSP), `npm test` 952/952 sur les deux
moteurs, `npm run audit` **25/25 tâches vertes** (20 harnais), `design:build` régénéré.

## [5.5.0] — 2026-08-08
### Les boucles évoluent au compte : jalons, renvoi d'excursion, période de cycle

Audit demandé par l'auteur sur le déroulé de l'algorithme : *« l'ACR restera toujours
choquable / pas choquable / RACS — mais au bout de 3 CEE, se poser la question d'une FV
réfractaire, qui fera changer les pads ; puis l'analyse reste toutes les 2 minutes, commune
avec le début »*. Le déroulé en boucle était couvert (« ↺ reprendre à n », passages ×n,
convergence) ; ce qui n'existait pas, c'est un contenu qui **change au k-ième passage ou au
n-ième choc**. L'auteur n'avait que du texte statique (du bruit avant le seuil) ou une
excursion « à tout moment » dont l'**entrée reposait sur la mémoire du compte** — l'inverse de
la doctrine QRH, alors que le runtime connaît les deux nombres (`passInfo`, les compteurs).

- **P1 — le jalon de boucle** (`b.milestones`, facultatif, ≤ 3 par bloc) : une phrase d'auteur
  conditionnée « à partir du nᵉ passage » ou « quand le compteur X atteint n ». Modèle ECL sur
  la carte du bout : la ligne existe dès le premier passage, estompée, **condition en toutes
  lettres et progression vivante** (« Chocs délivrés 2/3 » en mono) ; au seuil elle passe au
  registre ATTENTION — ambre, jamais rouge, franchissement en ≥ (un fait ne s'acquitte pas), et
  **rien ne se déclenche** (règle 11 : pas de son, pas de saut — mesuré Δ = 0 px ; l'annonce
  passe par `#srLive`). Repeinture chirurgicale dans `setCounterVal`, **avant** le garde `!el` :
  en étroit, le volet des compteurs peut être absent du DOM pendant qu'un évènement distant
  incrémente — le jalon, lui, est sur la carte et doit suivre. Un compteur qui ne résout pas
  rejette la rangée dans `migrate` (un jalon qui ne mesure pas est mort).
- **P2 — le renvoi est une porte d'excursion, pas une navigation nouvelle** : `go` désigne la
  cible d'une excursion **déclarée** et le bouton ⚡ réutilise `data-cxgo`, donc `cxEnter`, ses
  gardes de partage et son retour prévu (« ↩ Reprendre » — l'analyse reprend, commune avec le
  début). Le bouton n'est tapable qu'au seuil : avant, la rangée ⚡ constante du pied suffit —
  l'action au pied de l'alerte est la règle ECAM déjà écrite pour `onDue`.
- **P3 — l'état au point de décision** : la progression vivante du jalon met le compte sous les
  yeux à l'endroit où l'on répond (le rang « passage n/N » existait déjà sur la carte).
- **P4 — la boucle dit sa période** : quand la fiche déclare **un seul** minuteur à cycles,
  les renvois de boucle textuels la portent (« ↺ reprendre à 2 · toutes les 2 min », statique
  et parcours) ; à deux minuteurs, rien — annoter serait une devinette.
- **Les vues de structure annoncent les jalons d'emblée** (rien de caché qui ne s'annonce) :
  marqueur △ + détail déplié dans l'Échelle (forme neutre — colonne désaturée), lignes inertes
  dans le Parcours et le Statique, condition en toutes lettres partout.
- **Éditeur** : rangées de jalon par bloc (condition · seuil · compteur · renvoi vers une
  excursion déclarée), porte d'ajout masquée au plafond de 3 ; la bascule vers « compteur »
  pré-pointe le premier compteur — on ne fabrique jamais l'état que `migrate` rejette.
- **La fiche d'exemple ACR exerce le mécanisme** (lot T13) : excursion « FV réfractaire (CEE
  inefficaces) », bloc hors chaîne (pads en antéro-postérieur), jalon « Chocs délivrés ≥ 3 »
  avec renvoi. Le **prompt IA** documente `milestones` et interdit d'inventer un seuil clinique.
- **Qualification réglementaire écrite avant le développement**
  (`docs/deploiement-et-conformite.md` § 2, « Le cas des jalons de boucle ») : une règle
  d'auteur affichée au moment que l'auteur a défini — même famille qu'`onDue` ; aucun paramètre
  patient (les compteurs comptent des gestes de l'équipe) ; la ligne à ne pas franchir est
  nommée (paramètre patient, seuil déduit par le logiciel, déclenchement autonome).
- **Témoins** : 17 contrôles purs (`tests.html` — sanitisation, progression, `cycleHint`),
  section doctrine « QRH · jalons de boucle » (12 contrôles qui construisent leur cas sur
  l'ACR, vérifiée **capable d'échouer** : activation neutralisée → 4 rouges, fichier restauré à
  l'octet), 2 contrôles de contrat dans `audit-prompt` (le jalon du schéma traverse `migrate`).
  `SHARE_KEEP` couvre déjà (`blocks` voyage entier) — `schema.sql` inchangé.

Rotation du journal (règle des 20 entrées) : 5.0.0 → 5.0.2 partent dans
`docs/changelog/v5.md` (créé), 4.77.0 → 4.79.0 rejoignent `docs/changelog/v4.md`.
