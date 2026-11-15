# Journal des modifications

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

## [5.126.3] — 2026-11-14
Dans un PDF, les mots surlignés restent en place quand on zoome (A743).
- La v5.126.2 ne réglait que le zoom aller-retour rapide. Les mots surlignés (et les liens du document) pouvaient
  encore disparaître : le temps que la page soit redessinée sur un gros document, ou pour de bon quand le dessin
  échouait à fort zoom sur iPhone.
- Ils sont maintenant replacés à la nouvelle taille dès le zoom, sans attendre que la page soit redessinée.

## [5.126.2] — 2026-11-14
Deux correctifs : la recherche ne prend plus deux mots pour un code de session (A741), et le surlignage d'un PDF
revient après un zoom (A742).
- **PDF : mots surlignés perdus après un zoom.** Zoomer puis dézoomer (ou l'inverse) faisait disparaître les mots
  surlignés, et avec eux les liens cliquables du document. Ils reviennent maintenant à leur place.
- Taper « ACR réfrac » affichait « Code de session reconnu · Rejoindre ACRR-FRAC » : les deux mots étaient collés et
  la lettre accentuée retirée, ce qui donnait huit caractères, la longueur d'un code.
- La ligne « Rejoindre » n'apparaît plus que si vous tapez un code tel qu'il s'écrit : 8 caractères d'un seul
  tenant, ou 4 + 4 séparés par un tiret ou une espace, sans accent.
- Un mot de 8 lettres sans accent (« fentanyl ») peut encore l'afficher ; elle s'ajoute alors aux résultats, sans
  les remplacer.

## [5.126.1] — 2026-11-13
Les résultats d'une recherche ne sont plus collés les uns aux autres (A740).
- Chaque résultat est une carte à part, avec un petit espace entre deux. Sur ordinateur et tablette, les cartes se
  touchaient ; au téléphone, elles formaient un seul bloc séparé par des traits.
- Les listes de l'accueil, des bibliothèques et des collections ne changent pas.

## [5.126.0] — 2026-11-13
Une faute de frappe sur un mot du contenu ne laisse plus la recherche sans réponse (A739).
- **Avant**, la recherche ne rattrapait une faute que vers un mot d'un titre, d'un code ou d'une catégorie :
  « anafilaxie » trouvait « Anaphylaxie », mais « amiodaronne » ou « absende » ne trouvaient rien si le mot juste
  n'était écrit que dans une étape, une posologie ou le corps d'un protocole.
- **Maintenant**, quand il n'y a aucun résultat, la recherche propose aussi le mot le plus proche du contenu de vos
  aides et protocoles. Comme avant, elle le dit au-dessus de la liste (« Aucun résultat pour "absende" · affiché :
  "absente" ») et ne modifie pas ce que vous avez tapé. L'extrait sous le titre montre la ligne où se trouve le mot.
- **Prudence sur les noms proches.** Un mot tapé juste n'est jamais remplacé. Pour un mot du contenu, l'écart admis
  est plus petit que pour un titre : une lettre jusqu'à 8 lettres, deux au-delà. À écart égal, un mot de titre passe
  avant.
- Les mots des PDF joints ne servent pas à corriger ; un mot trouvé dans un PDF reste un résultat.

## [5.125.0] — 2026-11-13
La recherche classe ses résultats par pertinence (A735-A738). La liste des résultats ne change pas, sauf là où la
recherche ne trouvait rien à tort.
- **L'ordre des résultats.** Un mot trouvé dans le titre ou le code pèse plus que dans le contenu, un mot entier plus
  qu'un fragment au milieu d'un autre mot. Pour « ACR réfractaire », les éléments qui portent les deux mots dans
  leur titre viennent en tête. L'accès direct (étoile) et les ouvertures récentes ne servent plus qu'à départager
  deux résultats de même pertinence. Un élément trouvé seulement par un PDF joint arrive en fin de liste.
- **Les petits mots et la ponctuation.** « et », « de », « la », « pour »… ne sont plus exigés : « ACR et réfractaire »
  trouve « ACR réfractaire ». « l'adrénaline » trouve « adrénaline », « ACR, réfractaire » et « (ECPR) » trouvent ce
  qu'on attend. Un petit mot tapé tout en capitales (« LES », « DES ») est cherché comme un sigle.
- **L'extrait sous le titre** montre la ligne qui contient le plus de mots cherchés, et ne met plus les petits mots
  en gras.
- **Pluriel, trait d'union, unité.** « réfractaires » trouve « réfractaire », « vitaux » trouve « vital » ;
  « anticoagulant » et « anti-coagulant » se trouvent l'un l'autre ; « 300mg » trouve « 300 mg ». Le pluriel vaut
  aussi dans les PDF joints.
- **Une aide se trouve aussi par** la note d'une étape, une complication, un minuteur (et son action à l'échéance),
  un compteur, un jalon, une phase, le nom d'un document joint, la légende d'une image. Un protocole, par la légende
  d'une image.
- Reste à décider : qu'un mot de 2 ou 3 lettres (« ACR ») ne corresponde qu'en début de mot — aujourd'hui il trouve
  encore « macrolide », en bas de liste (`docs/decisions/lot-v5-125.md`).

## [5.124.4] — 2026-11-13
Un premier chargement de compte interrompu se reprend, et l'accueil le dit (A734).
- **L'app fermée pendant le chargement.** Si l'app était fermée (ou l'onglet) au milieu du premier chargement d'un
  compte, sa réouverture montrait la liste à moitié reçue comme si tout était là. Elle reprend désormais le
  chargement, avec « Chargement de votre compte… », jusqu'à ce que tout soit arrivé.
- **Le réseau qui tombe pendant le chargement.** Le chargement s'arrête, la liste reçue s'affiche, et la bannière dit
  « Chargement du compte interrompu · La liste n'est pas encore complète · Nouvelle tentative automatique en cours ».
  La nouvelle tentative reprend là où le chargement s'était arrêté.
- **Un chargement qui dure.** Au-delà de 20 secondes (grosse bibliothèque, réseau lent), l'accueil affiche la liste
  sans attendre, avec la mention « la liste n'est pas encore complète », qui disparaît quand tout est arrivé.
- Rien ne change pour un appareil où le compte est déjà chargé : sa liste s'affiche tout de suite.

## [5.124.3] — 2026-11-13
À la connexion, l'accueil ne montre plus une liste partielle avant la vraie (A733).
- **« Chargement de votre compte… » jusqu'au bout.** Sur un appareil où le compte n'a encore jamais été chargé
  (connexion temporaire, ou nouvel appareil), l'accueil affichait d'abord « Aides » et quelques aides seulement, puis
  changeait d'aspect une fois tout reçu. Les aides arrivent avant les protocoles, et l'état « chargement » s'arrêtait
  dès les premières. Il tient désormais jusqu'à ce que tout soit arrivé, puis l'accueil s'affiche en une fois.
- Au téléphone, le titre reste « Accueil » pendant le chargement.
- Rien ne change pour un compte déjà chargé sur l'appareil : sa liste s'affiche tout de suite. Une recherche lancée
  pendant le chargement montre ce qui est déjà arrivé. Au-delà de 20 secondes, l'accueil s'affiche quoi qu'il arrive.
