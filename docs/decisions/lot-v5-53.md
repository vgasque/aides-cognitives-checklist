# Lot v5.53 — A485-A489

Retours d'usage après les collections (v5.50-v5.52), et la décision de lecture de la colonne gauche (canevas
« Rangement de l'accueil », planches 11 à 16, option 1 retenue par l'auteur).

## A485 — la pastille d'une catégorie homonyme (v5.53.0)

Signalé : une catégorie créée dans une bibliothèque, homonyme d'une catégorie d'une autre, prenait dans l'intertitre
de section la couleur de l'AUTRE. `catGroups` lisait `categories.find(c=>c.name===n)` — la première du nom, toutes
bibliothèques confondues. La couleur se lit désormais sur les catégories des ÉLÉMENTS de la section (`catCols`) ;
plusieurs couleurs → pastille multicolore, le dessin d'A299 de la colonne (factorisé : `catDotHtml`).

## A486 — « Nouvelle catégorie… » depuis Ranger crée et range

« ＋ Nouvelle catégorie » ouvrait le gestionnaire complet : la catégorie créée, la fenêtre fermée, la feuille Ranger
avait disparu et la sélection n'était rangée nulle part. Patron de « ＋ Nouvelle collection… » : un nom
(`confirmDlg` à champ), « Créer et ranger » — créée là où le nom manque dans les bibliothèques de la sélection
(`catNew`, factorisé avec le gestionnaire), puis `selSetCat`.

## A487 — épingles : brouillon et animation

- La case « Accès direct » d'une sélection contenant un BROUILLON restait « en partie » pour toujours : un brouillon ne
  s'épingle pas (K5), chaque appui tentait d'ajouter et ne retirait jamais. Les brouillons non épinglés sortent du
  compte de cette case, et la rangée le dit (« 1 brouillon ne s'épingle pas »).
- Toucher une étoile faisait s'animer TOUTES les étoiles allumées : `.pinbtn.on svg{animation}` rejouait à chaque
  re-rendu. L'animation passe sur `.pinbtn.on.pop`, posée sur la seule étoile touchée (`pinTap`).

## A488 — « Ajouter à « … » » dans une collection

Le bouton « Ajouter des aides » devient « ＋ Ajouter » (on ajoute aussi des protocoles), la feuille s'intitule
« Ajouter à « ‹collection› » » — et pas « Ajouter à une collection », titre de la feuille INVERSE (choisir des
collections pour une aide) —, sous-titre « Aides et protocoles · rien n'est déplacé ». Chaque rangée porte la pastille
de sa catégorie et « nature · catégorie · bibliothèque ».

## A489 — la colonne dit AVEC QUI (option 1)

Constat (point « critique à la lecture » de l'auteur) : le principe du canevas — « une bibliothèque ne s'affiche
jamais seule, toujours avec son partage » — n'avait pas été appliqué à la colonne. « Perso » s'y lisait comme une
collection de plus, juste au-dessus d'« Accès direct ».

- **Bibliothèques · avec qui** : icône de personnes (`user` pour Perso, `users` — nouvelle — pour une partagée) et un
  mot (vous seul · partagée · lecture), à la place des cadenas (`.hs-act` et l'icône `lockopen` purgés, `hsRow`
  simplifiée). **Collections · pour vous** dans la colonne (« Mes » redisait « pour vous » et l'en-tête débordait de
  11 px), avec « Gérer » vers Moi › Mes collections (`openMoiZone`). Un en-tête de colonne ne passe plus à la ligne :
  l'indice cède le premier.
- **Une seule bibliothèque** : « Bibliothèque », une rangée active (elle EST « Toutes »), ni « Toutes » ni « Gérer »,
  et la porte « ＋ Partager avec une équipe… » (créer ou demander : la fenêtre d'A477/A479). Le verbe dit
  l'intention — personne ne « partage » pour ranger.
- Feuille Affichage : la puce d'une bibliothèque partagée prend `users` ; la section « Bibliothèque » reste réservée à
  deux bibliothèques non vides au moins (décision de l'auteur : pas pour une bibliothèque vide).
- Écartés : la bibliothèque en sélecteur (option 2 — un geste de plus, renverse A238-A269), « mes rangements
  d'abord, le catalogue ensuite » (option 3 — Perso reste à soi ET dans le catalogue). Le nombre de personnes par
  bibliothèque demanderait une fonction serveur : non fait.

## Au passage

- Menu ⋯ d'une collection : en tablette et au bureau il s'ouvrait en bas à gauche de l'écran (`.coll-acts` n'était pas
  un repère de positionnement) ; il s'ouvre sous son bouton, vers la gauche.
- Moi : le survol de la première rangée d'une carte (`.acct-list`) touchait le bord haut — 4 px d'air.

Témoin : `audit-doctrine` « ACCUEIL · A485-A489 » (390 et 1280 px).
