# Journal des modifications

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
