# Journal des modifications

## [5.137.0] — 2026-11-16
Les images voyagent en fichiers : la synchro s'allège et le serveur tient (A766). ⚠ **Serveur à mettre à jour** :
rejouer `supabase/schema.sql`. ⚠ **Mettre à jour TOUS les appareils** : une version antérieure ne sait pas lire les
nouvelles données.
- **Les images ne sont plus recopiées dans chaque aide ou protocole envoyé au serveur** : elles y sont rangées en
  fichiers, comme les documents PDF et les vidéos. Une modification de texte n'envoie plus que le texte ; le serveur ne
  construit plus des réponses de plusieurs dizaines de Mo (« Service indisponible »).
- **Sur l'appareil, rien ne change** : les images s'affichent, se modifient, s'exportent comme avant.
- **Une seule fois, au premier passage de cette version**, chaque appareil envoie ses images en fichiers puis renvoie
  ses aides et protocoles allégés — la pastille compte (« Envoi · n / N images »). Un autre appareil reçoit ensuite les
  éléments, légers, puis leurs images en fond (« Réception · n / N images »).
- **Les fichiers partent même si la réception échoue** : vidéos, documents et images ne restaient sur l'appareil que
  parce qu'une erreur de réception arrêtait toute la synchro.
- Une image ne quitte la ligne que lorsque son fichier est bien sur le serveur : aucune panne ne peut la perdre.
- ⚠ **Pour l'administrateur** : rejouer `supabase/schema.sql` **avant** d'ouvrir la nouvelle version (le stockage accepte
  les images ; elles ne comptent pas dans le quota de documents). Sans cela, les images restent dans les lignes, comme
  avant, et l'app le signale.

## [5.136.0] — 2026-11-16
L'écran reste allumé pendant un gros rattrapage de synchro ; la réception des fichiers se compte ; ⚠ correctif : les
documents et vidéos se téléchargent de nouveau (A764).
- ⚠ **Correctif important** : depuis la v5.135.2, plus aucun document PDF ni vidéo ne se téléchargeait sur un appareil
  (une erreur de code, silencieuse). Ils arrivent de nouveau, à la prochaine synchro.
- **L'écran ne se met plus en veille pendant un gros rattrapage** (beaucoup d'éléments ou de fichiers à recevoir ou à
  envoyer) : une web app ne synchronise qu'ouverte, et sur iPhone la veille coupait le lot en cours. Au plus 30 minutes
  par rattrapage, puis la veille normale reprend. Le bandeau le dit (« écran maintenu allumé ») ; le réglage « Veille
  active » est respecté.
- **La réception des fichiers se compte** : « Réception · 3 / 14 fichiers · 40 / 210 Mo », puis « Synchronisé ».
- **« Service indisponible » dit quelle étape a échoué** (A765) : la fenêtre d'erreur de synchro montre désormais
  l'étape (« envoi des protocoles »…) et le message exact du serveur, à transmettre si le problème dure.
- **Des lots plus prudents** : la synchro commence par un seul élément et vise 4 Mo par lot, pour ne pas buter sur la
  limite de temps d'une requête du serveur.

## [5.135.2] — 2026-11-16
Les vidéos montent mieux et la synchro dit où elle en est pendant leur envoi (A763) ; le bandeau ne promet plus ce
qu'il ne peut pas tenir (A762).
- **Les vidéos et les PDF ont le temps de monter** : chaque envoi avait 2 minutes, quelle que soit sa taille — une vidéo
  de 30 Mo sur une connexion lente n'y arrivait pas, et recommençait au début à chaque essai. Le délai suit désormais
  la taille du fichier.
- **L'envoi des fichiers se compte** : la pastille dit « Envoi · 2 / 14 fichiers · 48 / 210 Mo », et l'accueil montre
  le bandeau avec sa barre dès 6 fichiers ou 20 Mo — l'ordinateur restait sur « Synchro en cours » sans rien dire.
- **`supabase/rls-tests.sql` se rejoue de nouveau** : le témoin des vidéos (v5.134) supprimait directement dans le
  stockage, ce que Supabase refuse (« Direct deletion from storage tables is not allowed »). Le schéma, lui, ne change
  pas.
- Il disait « ce qui est reçu reste sur cet appareil » : faux sur un appareil connecté temporairement, dont les données
  sont effacées à la fin. Il dit désormais, à la réception comme à l'envoi : « une coupure reprendra où elle s'est
  arrêtée » — ce que la synchro garantit sur tout appareil.

## [5.135.1] — 2026-11-15
La synchronisation tient après un gros import : elle reçoit et envoie par petits lots, et reprend où elle s'est arrêtée (A760).
- **Le téléphone se synchronise de nouveau après un import massif fait ailleurs.** Il demandait toutes les nouveautés en
  une seule fois, images comprises : des centaines de Mo, que le serveur ou le réseau abandonnait — et chaque nouvel
  essai recommençait la même demande. Désormais : la liste légère d'abord, puis les éléments par petits lots.
- **Une synchro interrompue reprend où elle en était** (réseau coupé, application fermée) : ce qui est déjà arrivé
  n'est plus redemandé.
- **L'envoi part aussi par lots** : un gros import fait sur l'ordinateur n'est plus tenté d'un seul bloc.
- **La synchro dit où elle en est** (A761) : la pastille compte (« Réception · 34 / 120 protocoles ») et, pour un gros
  rattrapage, l'accueil montre un bandeau avec sa barre de progression. Si elle s'interrompt, elle dit où (« Arrêtée à
  34 / 120 protocoles : la reprise partira de là »).

## [5.135.0] — 2026-11-15
Les images se comptent en poids : 10 Mo par aide ou par protocole, et au-delà l'app propose de compresser (A759).
- **10 Mo d'images par aide ou par protocole**, au lieu de 60 images : environ 130 photos, 90 photos d'iPhone ou
  60 schémas. Le nombre passe à 200. Un élément déjà au-delà reste lisible et modifiable : rien n'est coupé.
- **La carte des images dit son poids** (« 6,1 Mo d'images »), en ambre à partir de 8 Mo ; au-delà de 10 Mo, une bande
  le dit, « ＋ Image » se ferme et « Compresser… » est proposé.
- **Au-delà, l'app propose de compresser, et vous décidez.** Elle cherche la compression la plus douce qui suffit :
  les images les plus lourdes d'abord, la meilleure qualité qui tient, une taille réduite seulement si nécessaire.
  La feuille montre le poids avant et après, ce qui change, et le même détail de l'image avant/après, à 100 %.
  « Compresser » : ↶ annule. « Ne pas compresser » : rien ne change, seules les nouvelles images qui tiennent entrent.
- **À l'import**, un élément au-delà de 10 Mo porte sa bande dans l'atelier : « Compresser » (par défaut) ou « Ne pas
  compresser », et « Comparer ». Ce qui ne tient pas n'est pas importé, et le message de fin le dit.

## [5.134.1] — 2026-11-15
L'import HTML de Notion retrouve mieux ses images, et dit pourquoi quand il n'y arrive pas (A758).
- **Un nom écrit autrement est retrouvé** : quand la page écrit un nom simplifié (« Capture_decran_2025-05-14_a_18.05.03.png »)
  et que l'archive garde le nom d'origine (« Capture d’écran 2025-05-14 à 18.05.03.png »), ou qu'un dossier porte
  l'identifiant de la page, l'image est retrouvée — seulement s'il n'y a qu'un fichier possible.
- **La vraie raison est dite** : une image présente mais illisible (format non reconnu, trop lourde) est nommée
  « Image illisible », et non plus « absente de l'archive ».
- **Une image hébergée ailleurs** (insérée par lien dans Notion) devient un lien, comme à l'import Markdown : elle
  disparaissait sans un mot.
- **Les listes ne se coupent plus** : un bloc repliable rangé sous une puce (« parasternal grand axe » et sa vidéo)
  reste dans la liste, en sous-puce ; les puces suivantes gardent leur niveau au lieu de devenir un bloc de code.
- **Une vidéo sous une puce** reste dans l'élément de liste, comme une image.

## [5.134.0] — 2026-11-15
Des vidéos dans les protocoles (A757). ⚠ **Serveur à mettre à jour** : rejouer `supabase/schema.sql`.
- **Ajouter une vidéo** : « ＋ Insérer › Vidéo » dans l'éditeur d'un protocole. Formats **MP4** (lu partout), **MOV**
  (la caméra de l'iPhone) et **WebM** (l'export de Notion) ; **30 Mo** au plus par vidéo, **20** par protocole.
- **À la lecture**, la vidéo joue en boucle et sans le son quand elle est à l'écran, et s'arrête quand on la quitte
  (avec « réduire les animations », elle attend qu'on la lance). Elle se range dans une grille comme une image.
- **Elle est gardée sur l'appareil**, consultable hors ligne, et synchronisée comme les documents PDF, avec les mêmes
  droits. Absente de l'appareil, ou illisible (un WebM sur un iPhone ancien), la vidéo le dit au lieu d'un cadre noir.
- **À l'import** : les vidéos d'une page Notion (export Markdown ou HTML, dans le .zip) et celles d'une archive
  exportée par l'app entrent avec le reste ; dans une page Notion à colonnes, chacune prend sa case de grille. Ce qui
  ne peut pas entrer est nommé dans le texte et compté. **À l'export**, « Avec les fichiers joints » les emporte.
- Le quota « Documents PDF » de l'administration compte aussi les vidéos.
- **Correctif serveur** : la liste des documents orphelins de l'administration présentait tous les documents comme
  orphelins (elle lisait un ancien nom de champ).
- ⚠ **Pour l'administrateur** : rejouer `supabase/schema.sql` (le stockage accepte désormais les vidéos, 30 Mo). Tant
  que ce n'est pas fait, les vidéos restent sur l'appareil qui les a ajoutées, et l'app le signale une fois.

## [5.133.0] — 2026-11-15
Importer une page Notion exportée en HTML : les colonnes deviennent une grille (A756).
- **L'export HTML de Notion est accepté**, en plus de l'export Markdown : une page `.html` seule, ou le `.zip`
  d'export avec son dossier d'images. Par les mêmes portes : « Importer un fichier », le dépôt, et « Page Notion »
  dans l'éditeur d'un protocole.
- **Les colonnes sont retrouvées** : l'export HTML garde la mise en page de Notion, si bien que des images posées
  côte à côte (« Fémoral · Normal · Thrombus ») arrivent en grille, sans avoir à la refaire.
- Titres repliables, listes, cases à cocher, tableaux, encadrés, gras, liens : repris comme à l'import Markdown. Une
  image absente de l'archive est nommée dans le texte ; une vidéo aussi (l'app ne lit pas encore les vidéos), et le
  message de fin les compte.
- Le fichier HTML n'est jamais affiché ni exécuté : seul son texte est repris.

## [5.132.0] — 2026-11-15
Des images côte à côte dans un protocole : la grille d'images (A755).
- **Une image seule dans une case de tableau s'affiche en vignette**, et un toucher l'agrandit. Un tableau d'images a
  des colonnes égales et tient dans la largeur de l'écran — au téléphone, trois colonnes côte à côte, comme dans
  Notion. Chaque case porte un libellé au-dessus de son image (« Fémoral », « Normal », « Thrombus »…).
- **« Mettre en grille »** : sélectionnez les libellés et leurs images, puis choisissez 2, 3 ou 4 colonnes — en mise
  en forme en direct, par la barre de sélection des blocs ; en mode texte, par « ＋ Insérer › Grille d'images ».
  Le texte autour est gardé. C'est vous qui choisissez les colonnes : l'export Markdown de Notion ne dit pas quelles
  images étaient côte à côte.
- Une image placée dans une grille n'est plus retirée en quittant l'éditeur ; « Retirer » une image vide aussi ses
  cases ; l'export « sans les fichiers joints » les retire aussi.

## [5.131.0] — 2026-11-15
Un protocole peut contenir 50 000 caractères, et le texte n'est plus jamais coupé sans le dire (A754).
- **La limite passe de 20 000 à 50 000 caractères** (environ 20 pages). Elle a été mesurée : sur un téléphone lent, un
  protocole de 50 000 caractères s'ouvre en moins de 0,7 seconde (0,4 seconde aujourd'hui à 20 000) ; au-delà, l'ouverture
  dépasserait une seconde, trop lent pour un protocole consulté pendant un soin.
- **Un compteur dans l'éditeur** : à partir de 40 000 caractères, il affiche « 41 200 / 50 000 caractères » sous le
  texte ; il passe en ambre à l'approche de la limite ; au-delà, il dit combien de caractères ne seront pas enregistrés
  et propose de raccourcir ou de partager en deux protocoles. Avant, la fin était coupée à l'enregistrement sans un mot.
- **À l'import** : un protocole trop long le dit sur sa ligne, avant toute écriture ; verser une page dans un protocole
  qui dépasserait la limite est annoncé ; le message de fin dit aussi les images non reprises au-delà de 60.
- **Synchronisation** : un protocole reçu plus long que ce que cette version de l'app peut garder ne s'ouvre pas dans
  l'éditeur — il faut d'abord mettre l'app à jour, sinon sa fin serait perdue.
- **Images** : la limite de 60 par aide ou protocole ne change pas. Mesurée, elle garde un protocole sous les 20 Mo
  qu'accepte le serveur.
- ⚠ **Pendant la mise à jour** : un appareil resté sur une version précédente coupe à 20 000 caractères un protocole plus
  long écrit ailleurs ; ne modifiez pas un long protocole depuis un appareil qui n'a pas encore reçu la mise à jour.

## [5.130.1] — 2026-11-15
Fenêtre d'import au bureau : la bulle « Bibliothèque » ne se coupe plus en deux lignes (A753, rectificatif).
- Avec une bibliothèque au nom un peu long, « Bibliothèque · » passait à la ligne dans l'en-tête de la colonne, le
  nom était réduit à « Cours … » et la bulle devenait plus haute que sa voisine « Catégorie ».
- Le mot « Bibliothèque » ne se coupe plus ; seul le nom de la bibliothèque se raccourcit s'il le faut, et se lit en
  entier au survol. La colonne Bibliothèque est un peu plus large.

## [5.130.0] — 2026-11-15
La fenêtre d'import refaite : une liste groupée au téléphone, des colonnes au bureau (A753).
- **Au téléphone**, l'import s'ouvre en feuille du bas, qu'on referme en la tirant par sa poignée. Une seule phrase
  d'introduction ; « Ranger les cochés dans » devient deux rangées « Bibliothèque › » et « Catégorie › » ; les
  éléments sont groupés par nature (« Aides · 3 sur 3 », « Protocoles · 1 sur 1 »), chacun avec son « Tout cocher » ou
  « Tout décocher ». La destination d'un élément se touche comme un lien (« Perso › »), plus en pastille en pointillé.
- **Au bureau**, quand la fenêtre est assez large : une ligne par élément, et deux colonnes, Bibliothèque et
  Catégorie. Les commandes qui règlent tous les cochés sont posées en tête de leur colonne, avec une case pour tout
  cocher ou décocher. « Comparer » déplie la différence sous la ligne, sur toute la largeur.
- **Protocole ou page Notion** : « Où va ce contenu ? » propose d'abord deux choix — « Nouveau protocole » ou
  « Verser dans un protocole » ; la recherche n'apparaît que pour verser. Rien n'est jamais remplacé.
- **Bibliothèque** : chaque choix dit qui la verra (« Perso — à vous seul », « SMUR — partagée · visible par ses
  membres »). Même liste pour « Déplacer vers une bibliothèque » de la sélection.
- **Catégorie** : « Garder la catégorie du fichier » nomme la catégorie gardée ; une catégorie se crée dans le menu
  même (v5.129).
- Rien ne change à ce qui est importé ni à l'endroit où chaque élément arrive.

## [5.129.0] — 2026-11-15
Une catégorie se crée dans le sélecteur, et elle est aussitôt choisie (A752).
- **Avant**, « ＋ Nouvelle catégorie » ouvrait la fenêtre de gestion des catégories : il fallait créer, fermer la
  fenêtre, rouvrir le menu, puis choisir la catégorie qu'on venait de faire.
- **Maintenant**, la rangée devient un champ dans le menu même : tapez le nom, Entrée (ou « Créer ») — la catégorie
  est créée dans la bonne bibliothèque et choisie, le menu se ferme. Échap replie le champ sans fermer le menu.
- **Plus court encore** : quand le menu a une recherche (« Filtrer… ») et que le nom tapé n'existe pas, la rangée
  propose « ＋ Créer « … » » — un toucher suffit.
- **Partout où l'on choisit une catégorie** : l'éditeur d'une aide ou d'un protocole, chaque rangée de la fenêtre
  d'import et son bandeau, et « Ranger » de la sélection (sa petite fenêtre à champ disparaît).
- Un nom qui existe déjà dans la bibliothèque n'en crée pas un second : l'existante est choisie, et un message le
  dit. Sur une bibliothèque en lecture seule, la rangée n'est plus proposée.
- Au téléphone, la feuille se lève au-dessus du clavier pendant la saisie.
- La couleur, le renommage et la suppression restent dans « Gérer les catégories ».

## [5.128.0] — 2026-11-15
Exporter une aide ou un protocole : avec ou sans les fichiers joints, toujours demandé (A751).
- **Avant**, la question n'était posée que si le contenu avait des documents PDF. Un protocole illustré mais sans PDF
  partait en .json sans un mot : ses images y étaient bien, mais rangées dans le fichier, invisibles — on pouvait
  croire qu'elles manquaient. Et l'option « sans » n'enlevait que les PDF.
- **Maintenant**, dès qu'il y a une image ou un document, l'export demande « Avec les fichiers joints » ou « Sans les
  fichiers joints », en disant combien il y en a. **Avec** : images comprises, et les PDF dans une archive .zip à
  réimporter telle quelle. **Sans** : un .json allégé qui ne garde que le texte (images, documents et liens vers les
  documents retirés). Même choix depuis la lecture, l'éditeur et la sélection de l'accueil.
- **iPhone, application installée** : l'archive .zip est préparée avant la question, si bien que le tap l'envoie
  aussitôt à la feuille de partage — elle pouvait auparavant ne pas s'ouvrir et l'archive ne jamais arriver.
- Les menus disent « Exporter l’aide » / « Exporter le protocole », sans « (.json) », qui n'était plus juste.

## [5.127.2] — 2026-11-14
Sur un grand écran, « Dans les documents » est aligné sur les résultats (A750).
- Sous les résultats d'une recherche, les documents trouvés partaient vers la gauche sur un écran large, alors que
  leur titre et la liste au-dessus étaient centrés. Ils sont maintenant alignés sur la liste, à toutes les largeurs.

## [5.127.1] — 2026-11-14
En sélection, « Annuler » et « Tout cocher » restent lisibles quand on fait défiler (A749).
- Au téléphone, en mode sélection, la liste défilait sous « Annuler » et « Tout cocher » sans fond derrière eux, alors
  que « Sélectionner » et « Créer » ont un fond flouté. La rangée de sélection prend maintenant le même fond dès que
  la liste passe dessous ; en haut de la liste, elle reste transparente comme avant.

## [5.127.0] — 2026-11-14
Un PDF reste net à fort zoom (A748).
- **Avant**, au-delà d'environ 250 % sur un téléphone (200 % sur un ordinateur), le texte devenait flou, même avec les
  boutons + et − : la page entière est dessinée dans une image dont la taille est limitée par la mémoire de
  l'appareil.
- **Maintenant**, quand vous arrêtez de défiler ou de zoomer, la partie de la page que vous regardez est redessinée
  en pleine définition, comme dans les lecteurs PDF courants. Elle devient nette environ un quart de seconde après.
- **Aucun changement à zoom ordinaire**, et le défilement reste aussi fluide (mesuré sur ordinateur, iPhone, Android
  et appareil peu puissant émulés). Si vous recommencez à défiler, le dessin en cours est abandonné. Sur un appareil
  peu puissant, la zone redessinée est plus petite pour ménager la mémoire.

## [5.126.6] — 2026-11-14
Dans un PDF, le surlignage tombe sur le mot, et un zoom au doigt redevient net (A746-A747).
- **Surlignage décalé.** Le rectangle jaune tombait à côté du mot : sur « cortico-réfractaires » il couvrait
  « -réfract », sur « macrovasculaire » il couvrait « ma ». Sa place était estimée au nombre de lettres ; elle est
  maintenant mesurée. Sur une ligne justifiée, un petit écart peut subsister.
- **Flou après un zoom au doigt.** Après un pincer, la page restait une image agrandie, donc floue, alors que les
  boutons + et − la redessinaient. Elle est maintenant redessinée aussi après un pincer, et dès que le défilement
  s'arrête.
- À très fort zoom (400 %), le texte reste moins net qu'à 140 %, même avec les boutons : la page entière est
  dessinée dans la limite de mémoire de l'iPhone. Une amélioration est notée, à décider
  (`docs/decisions/lot-v5-126-6.md`).

## [5.126.5] — 2026-11-14
Dans un PDF, zoomer avec les boutons ne fait plus changer de page (A745).
- Sur un long document, « + » ou « − » déplaçait la vue vers une autre page : de la page 30, deux « + » menaient à
  la page 17. Le mot surligné qu'on lisait sortait donc de l'écran.
- La page que vous regardez reste maintenant au centre de l'écran quand vous zoomez avec les boutons, quand vous
  choisissez « Page » ou « Largeur », et quand la fenêtre change de taille. Le pincer gardait déjà sa place.

## [5.126.4] — 2026-11-14
Dans un PDF, les mots surlignés sont attachés à la page et ne peuvent plus se perdre au zoom (A744).
- **Avant**, chaque rectangle de surlignage était placé pour une taille de page donnée. À chaque zoom il était
  retiré puis replacé, et il disparaissait dès que ce replacement n'avait pas lieu. Les deux versions précédentes
  corrigeaient ces cas un par un.
- **Maintenant**, le surlignage est placé une fois, en proportion de la page, comme dans les lecteurs PDF courants :
  il grandit et rétrécit avec elle, quel que soit le zoom, sans être retiré. Les liens cliquables du document suivent
  la même règle.
- Rien ne change dans l'emplacement du surlignage ni dans la navigation entre les occurrences.
