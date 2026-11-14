# Journal des modifications

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

## [5.124.2] — 2026-11-13
Import d'une page Notion : un tableau dont les cases tiennent sur plusieurs lignes reste un tableau (A732).
- **Le tableau ne se défait plus.** Dans l'export de Notion, une case qui contient plusieurs lignes (retours à la ligne,
  ligne vide, liste à tirets) est écrite telle quelle, sur plusieurs lignes du fichier. L'import n'y reconnaissait plus
  de tableau : la page affichait des « | » et des « -- » au milieu du texte. La case est désormais recollée, chaque
  ligne y garde sa place, et le retrait des lignes décalées (« → … ») est conservé.
- **La première rangée n'est plus écrite en petites capitales.** Notion présente toujours sa première rangée comme une
  ligne de titres, même quand ce n'en est pas une. Quand elle tient sur plusieurs lignes, c'est du contenu : elle
  s'affiche désormais comme les autres rangées.
- Une ligne de texte ordinaire qui commence par « | », hors d'un tableau, n'est pas touchée ; un bloc de code non plus.
- Pour corriger une page déjà importée : importer à nouveau le `.zip`.

## [5.124.1] — 2026-11-12
Import d'une page Notion : les images rangées dans un dossier dont le nom contient des parenthèses s'importent (A731).
- **Les images ne se perdent plus.** Notion range les images d'une page dans un dossier au nom de la page, et ne code
  pas les parenthèses de ce nom — par exemple `Complications aiguës du diabète (DT1, DT2) hypogly/image 1.png`. La
  lecture du lien s'arrêtait à la première parenthèse fermante : l'image était déclarée « absente de l'archive » et un
  morceau du chemin restait dans le texte. Le lien est désormais lu en entier, et l'image arrive dans le protocole.
- Vaut pour le `.zip` d'export comme pour un `.md` seul, et pour un nom tronqué par Notion au milieu d'une parenthèse.
- Un lien vers une autre page Notion dont le titre contient des parenthèses garde, lui aussi, son seul texte.
- Pour récupérer les images d'une page déjà importée : importer à nouveau le `.zip`.

## [5.124.0] — 2026-11-12
Aux Bibliothèques, la bibliothèque ouverte se gère d'où l'on est, sans doublon (A730).
- **« Gérer la bibliothèque » sous ses catégories.** En ouvrant une bibliothèque partagée, la rangée « Gérer la
  bibliothèque » suit désormais « Gérer les catégories » : elle ouvre la fenêtre de la bibliothèque (nom, membres,
  invitations). Jusqu'ici, ce bouton n'existait que dans « Tout », une fois filtré sur une bibliothèque, et il y reste.
- **Plus de doublon sur ordinateur et tablette.** Quand une bibliothèque est ouverte, la colonne de gauche ne répète
  plus « Gérer les catégories » et « Gérer les bibliothèques » : seules restent les portes de la bibliothèque ouverte,
  à côté d'elle. « Partager avec une équipe… » reste à gauche. En revenant sur « Tout », la colonne de gauche retrouve
  ses portes générales.
- « Gérer la bibliothèque » n'apparaît qu'à qui peut la gérer : son administrateur, ou l'administrateur de
  l'application. Pas pour « Perso », qui n'a ni membres ni nom à gérer.
- « Gérer les catégories » prend l'icône d'étiquette qu'il porte déjà ailleurs, pour ne pas le confondre avec la
  rangée de la bibliothèque. Au téléphone, chaque niveau a sa page : rien ne change à la racine.

## [5.123.1] — 2026-11-12
Copier-coller le texte d'un protocole dans un autre garde ses images (A729).
- **Les images suivent le copier-coller.** Dans un protocole, le texte ne contient qu'un renvoi vers chaque image
  (`![…](img:…)`) ; l'image elle-même reste rangée dans son protocole. Coller ce texte dans un autre protocole
  recopiait le renvoi sans l'image : rien ne s'affichait, ni dans l'éditeur ni en lecture. Désormais, l'image est
  reprise du protocole d'origine dès le collage : elle paraît dans le texte, dans « Images du texte », et se lit une
  fois le protocole enregistré. Le curseur reste où il était.
- **Les protocoles déjà touchés se réparent seuls** : ouvrir l'éditeur d'un protocole où un tel collage a été fait
  ramène les images manquantes, tant que le protocole d'origine les a encore sur cet appareil. Il suffit ensuite
  d'enregistrer.
- Limite : un texte copié depuis un autre appareil ou un autre compte n'apporte pas ses images ; il faut les ajouter
  à nouveau.

## [5.123.0] — 2026-11-11
Le sommaire d'un protocole dit où l'on se trouve (A728).
- **Au téléphone, la carte « Sommaire » suit la lecture.** Dans un long protocole, coupé de grandes images, le titre
  de la section n'est plus à l'écran. Une fois qu'on a commencé à descendre, la carte collée en haut écrit la section
  en cours sur deux lignes — par exemple « Poignet », puis « Entorse scapho-lunaire ». En tête du protocole elle dit
  toujours « Sommaire · 6 sections ». La toucher l'ouvre comme avant.
- **Sur ordinateur, la section en cours est surlignée dans le sommaire de gauche**, comme dans le sommaire d'un PDF.
  Si le sommaire est long, il se recale seul pour garder cette ligne visible.
- La page ne bouge jamais d'elle-même : le sommaire suit le défilement, il ne le provoque pas. Seuls les titres `#` et
  `##` sont suivis, comme dans le sommaire.

## [5.122.0] — 2026-11-11
Deux défauts de lecture des protocoles, signalés sur capture (A726-A727).
- **Une liste dans un encadré s'affiche comme une liste.** Dans un encadré (« Information », « Attention »…), une ligne
  « - … » restait écrite avec son tiret, sous un vide. Elle s'affiche maintenant en puce, avec ses sous-éléments. Les
  encadrés importés de Notion en profitent sans rien refaire.
- **En lecture, une grande image tient à l'écran.** Sur ordinateur, une image « Pleine » prenait toute la colonne et
  pouvait dépasser la hauteur de la fenêtre. Elle est maintenant limitée aux deux tiers de la hauteur, sans être
  déformée ; un toucher l'agrandit toujours. Dans l'éditeur, « Pleine » reste toute la colonne. Au téléphone, seules les
  images très hautes changent. L'image d'un élément de liste garde sa petite taille.
- À savoir : une case à cocher écrite dans un encadré s'y lit (« [ ] ») mais ne s'y coche pas.

## [5.121.0] — 2026-11-11
Aux Bibliothèques, ce qu'on crée ou importe arrive là où l'on se trouve (A725).
- **Créer depuis une catégorie : la catégorie est déjà choisie.** Dans une bibliothèque, l'aide ou le protocole créé y
  naissait déjà ; ouvert dans une de ses catégories, il naît maintenant aussi dans cette catégorie.
- **Importer depuis une bibliothèque ou une catégorie : la destination est déjà posée.** Un fichier d'export, une page
  Notion (`.md`) ou une archive (`.zip`) importés depuis les Bibliothèques proposent d'emblée la bibliothèque ouverte, et
  la catégorie ouverte s'il y en a une. Jusqu'ici l'import proposait la bibliothèque filtrée à l'Accueil, et jamais de
  catégorie. Chaque ligne de l'import reste modifiable avant de valider.
- **Si le fichier déclarait une autre catégorie, l'import le dit.** Sous la catégorie proposée, une ligne l'écrit :
  « Le fichier la rangeait dans « Cardio ». » Rien n'est rangé ailleurs sans que ce soit écrit.
- **Dans « Tout », les filtres comptent.** Avec le filtre Bibliothèque posé (sur une bibliothèque où vous pouvez
  écrire), ce qu'on crée ou importe y arrive ; avec le filtre Catégorie, dans la catégorie de ce nom si la bibliothèque
  d'arrivée en a une.
- À l'Accueil, rien ne change : un import garde la catégorie que le fichier déclare.

## [5.120.0] — 2026-11-11
Les titres d'un protocole se lisent enfin comme des titres, et un correctif de l'éditeur (A723-A724).
- **Protocole, en lecture : trois niveaux de titre qui se distinguent.** `#` et `##` avaient exactement le même dessin,
  et `###` la taille du texte : on écrivait trois niveaux, on en lisait un et demi. `#` est maintenant le plus grand
  (21), précédé d'un trait épais et d'un grand blanc ; `##` vient ensuite (17,5), sans trait ; `###` reste à la taille
  du texte (15), en gras. Le texte lui-même ne change pas.
- **Éditeur de protocole : les mêmes titres qu'en lecture.** L'éditeur affichait les titres en petites capitales, plus
  petits que le texte qu'ils coiffaient : la structure d'un texte long ne se voyait plus. « Mise en forme en direct » et
  l'aperçu montrent désormais les titres de la lecture, et le texte y passe à la même taille qu'en lecture (15 au lieu
  de 16). Le champ où l'on écrit garde sa taille.
- **Éditeur de protocole, sur ordinateur : « Ajouter un bloc » ne fait plus remonter la page.** En bas d'un long
  protocole, le clic renvoyait la page plus haut et le choix du bloc s'ouvrait loin du bouton. Le choix s'ouvre
  maintenant contre le bouton, et la page ne bouge pas. Le téléphone n'était pas touché.
- Vérifié sur un protocole chargé (images, tableaux, encadrés, listes, titres de trois lignes), au téléphone, à 320 px,
  sur grand écran, en thème sombre et sections repliées. À savoir : un `###` suivi d'un paragraphe qui commence par du
  gras lui ressemble encore.

## [5.119.5] — 2026-11-11
Sept correctifs signalés, un raccourci et une règle changée (A716-A722). **Serveur à rejouer** (`supabase/schema.sql`) :
une bibliothèque ne reste plus jamais sans membre, et son administrateur peut la supprimer.
- **Session : le compte de « Horodater », en bas de l'écran, suit les coches.** Cocher une étape qui compte (un choc,
  une dose) pose un repère au journal, mais la touche gardait l'ancien nombre jusqu'au rendu suivant. Elle se met à
  jour aussitôt, volet ouvert ou fermé.
- **Éditeur : renommer un minuteur ou un compteur met à jour les blocs qui l'utilisent.** Les étapes liées, les
  réglages d'étape et les jalons gardaient l'ancien nom tant qu'on ne rouvrait pas l'aide. Le nouveau nom s'affiche
  partout dès qu'on quitte le champ, et le champ suivant (Tab ou toucher) garde le focus.
- **Barre d'onglets du téléphone : elle suit la fenêtre redimensionnée.** En réduisant la fenêtre depuis le bureau, la
  pastille bleue de l'onglet courant restait à sa taille d'avant, et le mot « Accueil » disparaissait. La pastille et les
  mots se recalent maintenant à chaque largeur.
- **Colonne de gauche : un seul trait sous les collections.** Il y en avait deux, sans rien entre.
- **Bibliothèques : le seul membre ne peut plus la quitter.** « Quitter cette bibliothèque… » était proposé même quand
  on en est le seul membre, et Administration permettait de retirer ce seul membre : la bibliothèque restait sans
  personne. Le bouton est remplacé par une ligne qui dit quoi faire (la supprimer, la convertir en collection, ou
  inviter quelqu'un d'abord) ; Administration le refuse en le disant. Le serveur le refuse aussi, par tous les chemins.
- **Bibliothèques › Tout : « Gérer la bibliothèque ».** Quand le filtre Bibliothèque est posé, un bouton ouvre la
  fenêtre de cette bibliothèque (nom, membres, rôles), pour son administrateur et celui de l'application.
- **L'administrateur d'une bibliothèque peut la supprimer.** C'était réservé à l'administrateur de l'application, alors
  qu'il pouvait déjà en retirer tous les membres. « Supprimer la bibliothèque… » est dans sa fenêtre, avec la même
  confirmation. Si le serveur refuse, l'app le dit au lieu d'annoncer « Bibliothèque supprimée ».
- **Moi › Bibliothèques : un lecteur ou un éditeur peut quitter une bibliothèque.** Seules les bibliothèques qu'on
  administre répondaient au toucher ; les autres étaient inertes, et rien ne permettait d'en partir. Toucher la rangée
  propose maintenant « Quitter », avec confirmation.
- **Éditeur de protocole : des blocs sélectionnés à la suite forment un seul cadre.** Chaque bloc avait le sien :
  certains se chevauchaient (un titre et la liste qui le suit), d'autres non. Un fin trait sépare chaque bloc à
  l'intérieur du cadre, pour les compter. Le contour de survol ne se superpose plus à la sélection.
