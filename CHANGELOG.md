# Journal des modifications

## [5.148.0] — 2026-11-18
La fenêtre « Tableau » ne montre plus chaque bouton deux fois : les réglages du tableau sont en haut, le média s'ajoute
dans la case (A792). Aucune mise à jour du serveur.
- **La fenêtre « Tableau » range ses boutons (A792, planche « Fenêtre Tableau »).** Au bureau, une seule **ligne d'outils au-dessus de la grille** : « En-tête » avec ses deux bascules (1ʳᵉ ligne · 1ʳᵉ colonne), puis « Largeur · choisie ▾ » (ou « auto ») qui ouvre un menu — montrer ou masquer la règle, ajuster au contenu, colonnes égales, et « Même hauteur » seulement sur une grille d'images. La rangée d'options sous la grille et les trois boutons de largeur au-dessus disparaissent ; l'aide du clavier descend au pied, en petit.
- **Au téléphone, plus rien en double.** Une **ligne d'état** au-dessus de la grille (« En-tête : ligne · colonne | Largeur : choisie › ») ouvre la feuille « Tableau », la même que « ⋯ » : en-têtes, largeur des colonnes, ajouter en fin, Modifier le Markdown. Sous la grille, il ne reste que la barre au pouce ; la grille arrive plus haut.
- **Le média s'ajoute dans la case** : un « ＋ » sur la case active, et seulement elle (Image ou Vidéo, puis le choix du média), dans tout tableau. Il est posé à cheval sur le filet de la case : il ne cache aucun texte, n'épaissit aucune ligne, et reste visible quand la case dépasse de l'écran (il passe alors à gauche). « ＋ Image » et « ＋ Vidéo » ne sont plus ni sous la grille ni dans « ⋯ ».
- Rien ne change pour les protocoles enregistrés.

## [5.147.0] — 2026-11-18
La largeur des colonnes se règle sur les colonnes elles-mêmes, et une vidéo montre sa première image (A790-A791). Aucune
mise à jour du serveur.
- **La règle des colonnes est au-dessus des colonnes** : dans la grille d'un tableau, « Largeur » change les petits
  onglets en une règle, un segment par colonne avec sa part, et une pastille sur chaque filet. On tire la pastille : la
  colonne s'élargit sous vos yeux.
- **La grille d'édition prend les proportions de la lecture** : vous voyez ce que vous réglez. Une colonne trop étroite
  pour y écrire garde 112 px dans la grille et le dit (« 15 % · min. ») ; en lecture, elle aura bien sa part.
- **Une vidéo montre sa première image** au lieu du mot « Vidéo » : dans la grille d'un tableau, dans le texte tant
  qu'elle n'est pas arrivée sur l'appareil, et dans le choix d'un média, avec ▶ et sa durée. Elle est capturée quand vous
  ajoutez la vidéo ; pour les vidéos déjà là, l'appareil qui a le fichier la capture de lui-même.
- La première image voyage avec le protocole : sur un autre appareil, elle s'affiche avant que la vidéo soit arrivée.
- Une vidéo que le navigateur ne sait pas lire (un MOV hors de Safari) garde le mot « Vidéo ».

## [5.146.1] — 2026-11-18
Correctifs du réglage de la largeur, après vos retours (A789). Aucune mise à jour du serveur.
- **Un seul réglage** : une image ou une vidéo ouverte par « Modifier… » ne montre plus ses anciens pictogrammes de
  taille, qui faisaient doublon. Elle s'affiche à sa largeur, et une ligne rappelle qu'elle se règle en touchant l'image
  dans le document puis en tirant son bord. La fiche d'une image (« Images du texte ») garde le réglage, pour tous ses
  passages à la fois.
- **La barre de l'image sélectionnée se voit en mode sombre** : elle se fondait dans le contenu, surtout sur iPhone.
  Elle a maintenant un bord clair la nuit. Au téléphone, elle reste en bas de l'écran.
- **Sur iPhone, tirer une poignée ou une pastille ne sélectionne plus de texte.**
- Dans un tableau qu'on fait défiler de côté, le cadre de l'image sélectionnée suit l'image.
- Vérifié sur Chrome et Edge (le même moteur), Safari (le moteur WebKit, avec un iPhone et un iPad simulés, en clair et
  en sombre) et Firefox.

## [5.146.0] — 2026-11-18
Une liste écrite dans une case de tableau s'affiche en liste (A788). Aucune mise à jour du serveur.
- **Dans une case**, des lignes qui commencent par « - », « * » ou « 1. » deviennent une vraie liste, à puces ou
  numérotée — elles s'affichaient avec leur tiret. Une ligne décalée fait un sous-niveau (c'est aussi la forme que garde
  l'import de Notion). Un libellé au-dessus reste au-dessus.
- Rien ne change pour une case sans liste, ni pour « 5 - 10 mg » (un tiret au milieu d'une ligne n'est pas une liste).

## [5.145.0] — 2026-11-18
Les anciennes tailles d'image rejoignent la largeur qu'on tire, et l'import de Notion garde les largeurs (A787). Aucune
mise à jour du serveur.
- **Une image dont la taille avait été réglée** (¼, ½, ¾…) garde cette taille quand vous ouvrez le protocole dans
  l'éditeur : elle devient la largeur de son passage dans le texte, qu'on tire ensuite comme les autres. Rien ne change
  tant que vous n'enregistrez pas, et rien ne change en lecture.
- **La fiche d'une image** (« Images du texte ») règle maintenant sa largeur à tous ses passages — dans le texte, dans
  une liste et dans une case — et dit combien il y en a.
- **Import de l'export HTML de Notion** : une image que vous aviez réduite dans Notion garde sa taille, et des colonnes
  de largeurs différentes gardent leurs proportions.

## [5.144.0] — 2026-11-18
On choisit la largeur des colonnes de n'importe quel tableau, et la colonne d'en-tête d'un tableau large reste visible
quand on le fait défiler (A786). Aucune mise à jour du serveur.
- **La largeur des colonnes** : dans la grille d'un tableau, « Largeur » ouvre une barre qui représente le tableau, une
  part par colonne. Tirez une pastille entre deux colonnes : ce que l'une gagne, l'autre le perd (par pas de 5 %, ou au
  clavier avec ← →). Puis « Mettre à jour le tableau ». Vaut pour une posologie comme pour une grille d'images.
- **Boutons rapides** : « Ajuster au contenu » (comme avant), « Colonnes égales », « Même hauteur » (dans une grille
  d'images, chaque colonne prend la place qu'il faut pour que les images aient la même hauteur).
- En lecture, une colonne ne descend jamais sous son mot le plus long : une dose ne se coupe pas au milieu. Si le tableau
  ne tient pas, il défile de côté, comme avant.
- **Les filets restent** : un tableau de texte qui porte une photo (une boîte de médicament, par exemple) garde ses
  lignes et ses colonnes ; seule une vraie grille d'images s'affiche sans filets. Les tableaux concernés changent donc
  d'aspect.
- **La colonne d'en-tête reste visible** quand on fait défiler de côté un tableau plus large que l'écran (au téléphone
  surtout), si sa première colonne est une colonne d'en-tête. Réglage : Moi › Affichage › « Tableaux larges » — En-tête
  fixe (par défaut) ou Tout défile.
- La largeur s'écrit dans le texte, sur la ligne qui suit le tableau (`{widths="30 25 45"}`).
- ⚠ Un appareil resté sur une version **antérieure à la 5.142** affiche cette ligne en clair sous le tableau : mettez à
  jour vos appareils.

## [5.143.0] — 2026-11-18
On règle la largeur d'une image ou d'une vidéo en tirant son bord, dans le texte, dans une liste et dans un tableau
(A785). Aucune mise à jour du serveur.
- **Touchez une image ou une vidéo** en mise en forme en direct : elle se sélectionne (un cadre bleu, une poignée sur
  son bord, une petite barre). Tirez la poignée : la largeur suit, par pas de 5 %, aimantée au quart, au tiers, à la
  moitié… et à la largeur de sa voisine. La part s'affiche pendant le geste. ↶ annule.
- **Partout** : une image seule dans le texte, une image sous une étape de liste, une image dans une case de tableau.
  Dans une liste, deux ou trois images réduites se placent côte à côte sous l'étape.
- **Boutons rapides** : « Même largeur » et « Même hauteur » (les images d'une étape s'alignent sur une même hauteur,
  chacune selon sa forme). Le menu de la part propose ¼, ⅓, ½, ⅔, ¾, Pleine ou « Par défaut ». « Modifier… », un double
  clic ou Entrée ouvrent le bloc (la grille pour un tableau).
- **Au téléphone**, la barre se pose en bas, sous le pouce, et la proportion choisie est gardée — une image n'est jamais
  affichée sous 80 px de large.
- La largeur appartient à l'endroit où l'image est posée : la même image peut être grande dans le texte et petite dans
  une case. Elle s'écrit dans le texte (`{width=45%}` collé à la ligne de l'image).
- Les tailles déjà réglées ne changent pas. La taille réglée dans la fiche d'une image (« Images du texte ») vaut là où
  aucune largeur n'est écrite.
- ⚠ Un appareil resté sur une version **antérieure à la 5.142** n'affiche pas une image dont la largeur a été réglée :
  mettez à jour vos appareils.

## [5.142.0] — 2026-11-18
Préparation de la taille des images et des vidéos partout, et de la largeur des colonnes d'un tableau (A784). Rien ne
change à l'écran. Aucune mise à jour du serveur.
- **Pourquoi cette version d'abord** : les prochaines versions écriront la largeur d'une image ou d'une vidéo, et celle
  des colonnes, directement dans le texte du protocole (`![](img:…){width=45%}`, `{widths="30 25 45"}` sous un
  tableau). Sur une version d'avant celle-ci, une image ainsi écrite **disparaîtrait** de l'écran. Cette version sait
  déjà les lire : installée partout avant les suivantes, aucun appareil ne perdra d'image.
- Elle lit ces deux indications partout (texte, élément de liste, case de tableau, recherche, export, import) sans en
  tenir compte encore, et ne les affiche jamais en clair.

## [5.141.0] — 2026-11-18
Les vidéos ont leurs dimensions, et la dernière carte d'une recherche retrouve son bord bas (A782-A783). Aucune mise à
jour du serveur.
- **Une vidéo a sa largeur et sa hauteur** : elles sont mesurées quand on l'ajoute (bouton, glisser-déposer, collage,
  import Notion). Les vidéos déjà là sont mesurées d'elles-mêmes sur l'appareil qui les a, puis repartent avec leur
  protocole vers vos autres appareils.
- **Son cadre a donc sa vraie forme** tant qu'elle n'est pas arrivée (16:9, portrait…), au lieu d'un 4:3 imposé : la
  vidéo prend sa place sans faire bouger la page.
- **Recherche depuis l'accueil** : sur un écran large, la dernière carte des résultats avait perdu son bord bas (elle
  paraissait coupée). Elle l'a retrouvé.
- Une vidéo que le navigateur ne sait pas lire (un MOV hors de Safari) garde le cadre 4:3.

## [5.140.0] — 2026-11-17
Une image, une vidéo ou un document qui n'est pas encore sur l'appareil le dit, à sa place (A781). Aucune mise à jour
du serveur.
- **Une image en cours de réception a son cadre**, exactement à la taille qu'elle aura : « Image en cours de
  réception », son poids, et sa légende déjà en dessous. Avant, la page ne montrait rien à sa place. Le cadre vaut
  dans le texte d'un protocole, dans un élément de liste, dans une case de tableau, dans le bloc d'une aide et dans
  « Tout voir ».
- **L'image prend sa place dès qu'elle est reçue**, une par une, sans que le texte bouge — l'écran n'attend plus la
  fin de toute la réception. En session aussi : l'image arrive dans son cadre, aucune étape ne bouge, rien ne s'affiche
  d'autre.
- **Sous le titre de l'élément ouvert**, une ligne dit ce qui lui manque et où en est la réception : « 4 images, 1
  vidéo et 1 document en cours de réception · 2 / 6 ». Elle disparaît quand tout est là. Jamais en session.
- **L'élément que vous ouvrez passe devant** : ses images, ses vidéos et ses documents sont reçus avant le reste de la
  bibliothèque, même si la réception avait déjà commencé.
- **Les mêmes mots pour les trois** : en réception (gris, rien à faire) ; « pas encore sur cet appareil » (ambre) hors
  ligne, avec « arrivera à la reconnexion » ; « introuvable » (ambre) si le serveur ne l'a pas. La rangée d'un document
  dit « ↓ en réception » ou « △ pas sur cet appareil » à la place de « △ à télécharger » ; une vidéo dit « Vidéo en
  cours de réception ».
- Une image que le serveur n'a pas le dit, et n'est plus redemandée à chaque passage (30 minutes d'attente, comme les
  autres fichiers).
- Limite : le cadre d'une vidéo garde sa forme 4 : 3 tant que la vidéo n'est pas là (ses dimensions ne sont pas
  connues avant) ; sa hauteur peut donc encore changer à l'arrivée.
- Vérifié sur Chromium, WebKit (le moteur de Safari) et Firefox : le cadre et l'image posée ont la même taille.

## [5.139.2] — 2026-11-17
Correctif : au téléphone, clavier ouvert, la grille d'un tableau n'a plus qu'un seul défilement (A780). Aucune mise à
jour du serveur.
- **Deux défilements emboîtés, clavier ouvert** : la fenêtre « Tableau » gardait la hauteur de l'écran alors que le
  clavier en cache une partie — la fenêtre défilait en plus de son contenu, et la barre du bas (‹ › Ligne · Colonne ·
  ⋯) restait derrière le clavier. La fenêtre prend maintenant la hauteur réellement visible : « Annuler · OK » en haut
  et la barre en bas ne bougent plus, seule la grille défile entre les deux.
- **La case que l'on touche reste visible** au-dessus de la barre du bas (elle pouvait se retrouver dessous).
- La tête « collée » de la v5.139.1, qui recouvrait le haut de la grille, est retirée.
- Sur tablette, la 1ʳᵉ colonne collée s'élargit (jusqu'à 168 px) ; le libellé « Dans la case » nomme la case active
  (« Dans la case Ligne 2, Dose »), sous la grille comme dans « ⋯ ».
- Vérifié sur WebKit (le moteur de Safari, clavier simulé comme sur iPhone), et sur huit profils : Android téléphone et
  tablette, iPhone, iPad, Chrome, Safari et Firefox au bureau.

## [5.139.1] — 2026-11-16
Correctif : la grille des tableaux est fluide au téléphone, sa 1ʳᵉ colonne prend moins de place, et tout reste à portée clavier ouvert (A777-A779). Aucune mise
à jour du serveur.
- **La grille ne fige plus l'écran** : chaque ouverture et chaque geste (insérer, déplacer une ligne, en-tête, média,
  ↶) recalculaient la mise en page case par case — près de 100 fois pour un tableau de 6 × 15. C'est fait en une fois :
  l'ouverture est environ trois fois plus rapide.
- **La 1ʳᵉ colonne, toujours collée, est plus étroite au téléphone** (112 px au lieu de 132) ; ses mots se coupent aux
  syllabes (« Médica-ment ») au lieu de se casser en plein mot, et un filet marque son bord pendant le défilement.
- Faire défiler la grille de côté n'entraîne plus la fenêtre.
- **Clavier ouvert, tout reste à portée** (A778) : sur un long tableau, la grille ne défile plus à l'intérieur de la
  fenêtre (on ne pouvait plus atteindre ce qui est dessous) ; la tête « Annuler · Tableau · ↶ · OK » reste en haut ; un
  bouton « ⋯ » dans la barre du bas réunit les en-têtes, l'image ou la vidéo de la case, « une ligne / une colonne en
  fin » et « Modifier le Markdown ».
- **‹ › n'ouvrent plus le clavier** : clavier fermé, elles déplacent la case active (cadre bleu) ; touchez la case pour
  l'écrire. Clavier ouvert, elles passent à la case suivante, comme avant.
- **D'après une capture d'iPhone** (A779) : plus de bouts de cases visibles à gauche de la colonne collée ; une colonne
  de texte long s'élargit et ses mots se coupent avec un tiret au lieu de se casser au milieu ; le libellé de la barre
  du bas se termine par « … » au lieu d'être rogné.

## [5.139.0] — 2026-11-16
L'éditeur de protocole fait ce que l'import Notion faisait déjà : des images et des vidéos dans une liste et dans un
tableau, une grille de tableau redessinée, la taille d'une vidéo, un glisser-déposer qui montre où le fichier ira
(A772-A776). Aucune mise à jour du serveur.
- **Une image ou une vidéo DANS un élément de liste** : ouvrez la liste, placez le curseur dans l'élément — « Dans
  l'élément 2 : Image · Vidéo ». On choisit depuis l'appareil ou parmi les images du protocole ; elle s'affiche sous
  l'élément, la liste ne se coupe pas. « ＋ Insérer › Image » demande aussi « Dans l'élément » ou « Après la liste ».
- **Toucher un tableau ouvre la grille**, la même fenêtre qu'à sa création ; « Modifier le Markdown » reste à un
  toucher. La pastille « Modifier en grille » disparaît.
- **La grille, sans la rangée de gros boutons** : un onglet ··· au-dessus de chaque colonne et ⋮ à gauche de chaque
  ligne ouvre son menu (aligner, insérer, monter / descendre d'un cran, en-tête, supprimer) ; des bandes « ＋ » au bord
  ajoutent une colonne ou une ligne ; les en-têtes restent visibles sous la grille.
- **Une case peut porter une image ou une vidéo** : vignette sous le libellé, ✕ pour la retirer, « ＋ Image » ·
  « ＋ Vidéo » dans la case active.
- **Au téléphone, la grille se parcourt au pouce** : une barre en bas (‹ › case précédente / suivante, « Ligne ▾ »,
  « Colonne ▾ ») garde le clavier ouvert ; les cases ne sont plus rognées (la grille défile, la 1ʳᵉ colonne reste
  visible) ; « Annuler · Tableau · ↶ · OK » en tête.
- **La taille d'une vidéo** se règle comme celle d'une image (¼ à Pleine, poignée) ; « Remplacer… » garde la taille.
  Un appareil resté sur une version antérieure montre la vidéo en pleine largeur.
- **Glisser-déposer : on voit où ça va** : une ligne bleue suit le pointeur et dit l'endroit — entre deux blocs, dans
  un élément de liste, dans une case d'une grille d'images ; en mode Texte, la ligne visée (jamais au milieu d'un
  tableau), et l'aperçu montre le même endroit. Les vidéos se déposent aussi.

## [5.138.0] — 2026-11-16
Administration › Stockage : les fichiers que plus rien n'utilise, listés et supprimables (A771). ⚠ **Serveur à mettre à
jour** : rejouer `supabase/schema.sql` (sans cela, la liste suit l'ancienne règle et aucune suppression ne passe).
- **Une nouvelle section « Stockage »** dans Administration (onglet au bureau, rangée « Fichiers sans élément » dans la
  vue d'ensemble) : chaque fichier du serveur qu'aucune aide ni aucun protocole ne cite plus, avec sa nature (document
  PDF, vidéo, image), son espace (Perso de qui, quelle bibliothèque), son poids et sa date.
- **Supprimer un fichier, ou « Tout supprimer »**, après confirmation. Le serveur revérifie chaque fichier au moment
  même : un fichier de nouveau cité n'est jamais supprimé.
- **Un fichier de moins de 7 jours se voit mais ne se supprime pas** : un appareil peut être en train d'envoyer
  l'élément qui le cite.
- **Règle plus prudente** : un fichier est cité dès que son identifiant apparaît n'importe où dans une aide ou un
  protocole vivant (pièces, vidéos, images, lignes du texte). L'ancienne liste pouvait rester vide à tort.
- Réservé à l'administrateur de l'instance, jamais depuis un poste partagé.
- `supabase/rls-tests.sql` : section 22 (liste réservée, fichier récent ou cité intouchable, ligne du texte protectrice).

## [5.137.4] — 2026-11-16
Correctif : la réception ne tourne plus en boucle sur des fichiers qui n'existent plus (A770). Aucune mise à jour du
serveur.
- **Un fichier introuvable partout** (ni sur l'appareil, ni sur le serveur — les vidéos perdues avant la v5.137.2) était
  recherché à chaque synchronisation : « Réception · 17 / 20 fichiers » revenait sans fin, et comptait ses échecs comme
  des fichiers reçus. Il n'est plus recherché pendant 30 minutes et ne relance plus le bandeau ; s'il est envoyé
  entre-temps par un autre appareil, il arrive à l'essai suivant.
- Ces références disparaissent quand le protocole concerné est réimporté puis l'ancien supprimé.

## [5.137.3] — 2026-11-16
Correctif : l'envoi des images ne tourne plus en boucle à chaque synchronisation (A769). Aucune mise à jour du serveur
de plus que celle de la v5.137.
- **Une même image citée dans deux espaces** (une copie dans Perso d'un protocole de bibliothèque, un Markdown collé
  d'un autre protocole) était renvoyée à chaque synchro vers l'un, puis vers l'autre, chaque envoi effaçant le fichier
  de l'autre chemin. Chaque espace a désormais son propre fichier, envoyé une fois.
- **Une image refusée par le serveur n'est plus renvoyée de toute la session** : le bandeau « Envoi · n / N images » ne
  revient plus à chaque passage. Le message dit de mettre le serveur à jour (rejouer `supabase/schema.sql`) ; l'envoi
  reprend à l'ouverture suivante de l'app.
- Une suppression sur le serveur protège aussi les images qu'un élément cite encore.
- Le message d'une vidéo absente dit la vérité : « introuvable, ni sur cet appareil ni sur le serveur » — si un autre
  appareil l'a encore, l'y ouvrir ; sinon, la réimporter depuis son fichier d'origine.

## [5.137.2] — 2026-11-16
⚠ **Correctif urgent** : depuis la v5.134, chaque ouverture de l'app effaçait les vidéos de l'appareil et demandait
leur suppression sur le serveur (A768). Aucune mise à jour du serveur. **Mettre à jour tous les appareils.**
- **Les vidéos ne sont plus effacées à l'ouverture de l'app.** Le ménage du démarrage, qui retire les fichiers que
  plus rien n'utilise, ne reconnaissait que les documents PDF : il prenait chaque vidéo pour un fichier abandonné.
  Même défaut à l'abandon d'un brouillon. Les deux reconnaissent désormais les vidéos, et tout fichier que le texte
  d'un protocole cite encore.
- **Une suppression sur le serveur se revérifie au moment de partir** : un fichier qu'un élément cite encore à cet
  endroit n'est jamais supprimé, même s'il avait été mis en file à tort par une version précédente.
- **Récupération** : une vidéo absente de sa bibliothèque est aussi cherchée dans votre espace Perso du serveur (là où
  elle était partie avant le déplacement de son protocole) ; retrouvée, elle revient sur l'appareil et repart vers la
  bibliothèque — « ↻ n fichiers retrouvés dans votre espace Perso du serveur ».
- Si une lecture des protocoles échoue pendant une synchro, plus rien n'est effacé à ce passage.
- Une vidéo qui n'était plus nulle part (ni sur l'appareil, ni sur le serveur) ne peut pas revenir d'elle-même : la
  réimporter depuis son fichier d'origine (l'export Notion, par exemple).

## [5.137.1] — 2026-11-16
⚠ Correctif : une vidéo pouvait rester absente du serveur alors que l'appareil qui l'avait ajoutée disait
« Synchronisé » (A767). Aucune mise à jour du serveur.
- **Une vidéo suit désormais son protocole quand il change d'espace** (de Perso à une bibliothèque, ou l'inverse) :
  seuls les documents PDF suivaient. La vidéo restait rangée « Perso » sur le serveur ; l'appareil notait qu'elle était
  dans la bibliothèque sans l'y envoyer, et les autres appareils ne la trouvaient jamais.
- **Réparation automatique de l'existant** : à chaque lancement, l'appareil vérifie que les documents et vidéos qu'il
  croit envoyés sont bien sur le serveur (une liste par dossier) et renvoie ce qui manque — « ↻ n fichiers manquaient
  sur le serveur : renvoyés ». Ouvrir l'app sur l'ordinateur qui a ajouté les vidéos suffit ; le téléphone les reçoit
  à sa synchro suivante.
- **« Copier dans Perso »** d'un protocole de bibliothèque emporte aussi ses vidéos (comme ses documents).
- **Une vidéo introuvable sur le serveur le dit** : « pas encore sur le serveur — ouvrez l'app sur l'appareil qui l'a
  ajoutée », au lieu de promettre qu'elle arrive avec la synchronisation.
- Audit : huit témoins instables sous charge réécrits sans rien desserrer (capter une animation à sa naissance, figer
  une transition, mesurer une fenêtre posée, compter des sondages plutôt que des millisecondes, tenir les synchros de
  fond à l'écart d'une mesure, attendre l'appel plutôt qu'un texte, lire « reste court » comme un rafraîchissement).

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
