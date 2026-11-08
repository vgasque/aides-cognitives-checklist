# Journal des modifications

## [5.101.0] — 2026-11-08
Premier pas de la nouvelle architecture (A601, lot 1 d'A600) : un catalogue des bibliothèques, ajouté sans rien
retirer à l'accueil. Rien à rejouer côté serveur.
- **Un onglet « Bibliothèques »** au téléphone (une rangée « Bibliothèques » dans la colonne sur tablette et
  ordinateur). Il montre vos bibliothèques, puis, dans chacune, SES catégories — plus de « Pédiatrie » de trois
  équipes mêlées — puis les aides et protocoles d'une catégorie.
- **« Tout »**, en tête : aides et protocoles de toutes les bibliothèques, à filtrer (type, bibliothèque, catégorie),
  trier et sélectionner.
- **Le dock se glisse** : faire glisser le doigt d'un onglet à l'autre change d'onglet au relâchement, comme les
  sélecteurs de Moi.
- L'accueil ne change pas : ses filtres, ses collections et sa liste restent tels quels.

## [5.100.0] — 2026-11-08
La barre de sélection change de dessin (A599) ; la nouvelle architecture de l'accueil est décidée (A600, à venir par
lots). Rien à rejouer côté serveur.
- **La barre de sélection est sombre**, dans la matière des objets « système » (carte de session, notifications) : on
  voit d'un coup d'œil qu'on est en sélection — un tap coche au lieu d'ouvrir. La nuit, elle s'éclaircit pour rester
  visible.
- **« Collection… » et « Exporter… » directement sur la barre**, le reste derrière **⋯** (déplacer vers une
  bibliothèque, ranger dans une catégorie, supprimer — qui garde ainsi une étape de plus).
- **Au téléphone, la barre prend la place des onglets, en bas** ; « Annuler » et « Tout cocher » sont en haut.
- Quand la place manque (petit écran, grand texte), la barre revient à « Actions ▾ » plutôt que de couper le nombre
  d'éléments cochés.
- Corrigé : la barre d'onglets restait affichée pendant une sélection au téléphone.
- Décidé (A600) : l'accueil deviendra un **lanceur** (session en cours, Accès direct, collections, récentes) et un
  **catalogue** portera bibliothèques, catégories et la liste complète « Tout » (filtrer, trier, sélectionner) —
  ajouté d'abord sans rien retirer.

## [5.99.0] — 2026-11-08
Une collection peut rester en tête de l'accueil (A598). Rien à rejouer côté serveur.
- **« Garder en tête de l'accueil »**, dans le menu ⋯ d'une collection : elle reste dans « Vos collections » sur
  l'accueil, même quand d'autres ont été ouvertes plus récemment ; les places restantes vont aux plus récentes.
  « Ne plus garder en tête » la rend à l'ordre des plus récentes.
- **Un signet plein** la signale partout où elle paraît. Pas une étoile : l'étoile reste le signe de l'Accès direct
  sur chaque aide.
- Le choix voyage avec vos collections sur vos autres appareils.

## [5.98.0] — 2026-11-08
La poignée de l'éditeur suit enfin le doigt ; l'accueil du téléphone dit quelles bibliothèques il affiche, et tient
des dizaines de collections (A594-A597). Rien à rejouer côté serveur.
- **La poignée entre le texte et l'aperçu suit le doigt.** Sur tablette, elle sautait entre trois positions (40, 50,
  65 %) : pendant le geste, l'ancienne valeur était repeinte. Elle glisse maintenant en continu, et aux largeurs
  étroites la plage va de 30 à 70 %.
- **L'accueil dit ses bibliothèques.** Sous « Aides », la sous-ligne compte les bibliothèques affichées (« Tout ·
  5 bibliothèques · 112 »). Une bibliothèque choisie prend le grand titre (« SMUR 75 », avec « Bibliothèque ·
  partagée » au-dessus) et « Tout afficher » revient à toutes ; les aides n'y répètent plus le nom de la bibliothèque.
- **Dans « Afficher », les bibliothèques sont une liste** : partage, nombre d'aides, coche sur la courante ; au-delà
  de six, « Voir les n autres ».
- **Des dizaines de collections** : au-delà de six, l'accueil garde les cinq ouvertes le plus récemment (dans l'ordre
  alphabétique), puis « Toutes les collections », qui ouvre « Afficher ». Un champ « Filtrer » y paraît dès qu'il y a
  beaucoup de rangées, sans faire monter le clavier au doigt.
- Corrigé : un long nom de bibliothèque ou de collection poussait « Créer » hors de l'écran une fois la page défilée.

## [5.97.0] — 2026-11-07
L'éditeur de référence aligne enfin le texte et son aperçu, et une poignée règle leur largeur (A593, amende
A546). Rien à rejouer côté serveur.
- **Le texte et l'aperçu partent de la même ligne.** Sur ordinateur et tablette (à partir de 780 px de large), avec
  « Mise en forme en direct » coupée, le texte Markdown et son rendu sont deux cartes côte à côte, de même hauteur ;
  la ligne en haut du texte a son bloc en haut de l'aperçu. Avant, l'aperçu commençait une centaine de pixels plus
  haut, et l'écart changeait selon le volet « Relecture ».
- **Le défilement est lié dans les deux sens** : faire défiler l'aperçu ramène le texte au même endroit, et
  inversement.
- **Une poignée ⋮ entre les deux règle leur part** : la tirer (elle s'aimante au tiers, à la moitié, aux deux
  tiers), double-clic ou Entrée pour revenir à moitié-moitié, flèches au clavier (5 %, 1 % avec Maj). Le réglage est
  retenu sur l'appareil.
- **« Relecture » devient un badge** dans la tête de l'aperçu ; il s'ouvre par-dessus le rendu sans le pousser.
- **Identité tient sur une ligne** (titre, code, catégorie, « Modifier ») ; « Contenu rédigé », Plan et
  l'interrupteur forment une bande au-dessus des deux cartes ; l'aide-mémoire de syntaxe passe dessous.
- **L'éditeur tient dans l'écran** et s'arrête au-dessus du bouton « Ajouter », qui ne couvre plus la fin du texte.
- Inchangé : au téléphone, « Écrire | Aperçu » ; en « Mise en forme en direct » (le réglage par défaut), le document
  par blocs ; sur un écran pliable ouvert, la charnière sépare toujours texte et aperçu.

## [5.96.2] — 2026-11-07
Correctif : les collections restent dans l'ordre alphabétique (A592). Rien à rejouer côté serveur.
- **Renommer une collection la remet à sa place** : une collection renommée restait à son ancien rang, alors que la
  liste est promise par ordre alphabétique (A475, A587).
- **L'ordre se rétablit au chargement**, y compris pour les collections reçues d'un autre appareil par la synchro :
  une liste déjà dérangée par un ancien renommage se remet en ordre d'elle-même, sans rien faire.

## [5.96.1] — 2026-11-07
La carte « Session terminée » suit le nouveau dessin de l'accueil, et un défaut de la 5.96.0 est corrigé (A591).
Rien à rejouer côté serveur.
- **La carte « Session terminée » perd son trait vert à gauche** : la coche et le mot disent déjà que c'est fait.
- **Elle a une seule place**, sous le titre « Aides », juste avant « En cours », au téléphone comme sur grand écran
  (sur grand écran, elle passait au-dessus du titre).
- **Le nombre de blocs se dit en mots** : « 2 blocs terminés sur 3 » au lieu de « 2/3 blocs ✓ » — l'ancienne forme
  mettait une coche même quand aucun bloc n'était fait.
- **Correctif** : en thème sombre, sur ordinateur, survoler « Terminer… » dans la bande « En cours » noircissait le
  bouton ; il s'éclaircit désormais comme les autres boutons de la bande.

## [5.96.0] — 2026-11-07
La session en cours se reconnaît de nouveau à l'accueil, et « Reprendre » et « Terminer » y reviennent (A590, amende
A523). Rien à rejouer côté serveur.
- **Plus d'étoile dans « En cours »** : elle se confondait avec Accès direct, où paraît la même aide. L'aide reste
  épinglable dans Accès direct et dans la liste.
- **La rangée « En cours » reprend la bande sombre** de la carte « Session en cours » d'avant la v5.67, sans revenir
  à une carte en double : c'est la rangée de l'aide, sur fond sombre, avec le chrono en vert. Elle a désormais le
  même dessin que la carte d'une session partagée.
- **« Reprendre » et « Terminer… » sont de retour à l'accueil** (ils avaient disparu en v5.67.0), sous la rangée au
  téléphone, à droite sur grand écran. « Terminer… » demande la même confirmation maintenue que « Fin » en session ;
  il n'est pas rouge. Toucher la rangée reprend toujours la session.
- **La rangée dit où l'on en est** : le bloc courant sous la ligne d'état (« 1 · Reconnaissance & alerte »).
- **En thème sombre**, la bande et la carte d'une session partagée prennent un contour vert : sans lui, le fond
  sombre ne se détachait plus.

## [5.95.0] — 2026-11-06
L'accueil tient à cent aides et protocoles : vos collections en tête, des groupes qui se plient, la provenance mieux
dite (A587-A589). Rien à rejouer côté serveur.
- **« Vos collections » en tête de l'accueil**, repliées : un sommaire de vos collections, chacune avec son compte.
  Toucher une collection la déplie sur place — ses aides, « aussi dans … », puis « Ouvrir » pour la vue de la
  collection (Ajouter, ⋯). Absente sous une recherche, un filtre ou une sélection, et tant qu'aucune collection
  n'existe.
- **« Tout » dessous** : le répertoire complet, inchangé, rangé par « Regrouper ». Une aide sans collection y reste à
  sa place ; une aide rangée y paraît aussi — c'est la même aide, pas une copie.
- **L'accueil d'avant reste disponible** : « Trier et présenter » (« Affichage » sur grand écran) › « Vos
  collections : Non ». Regrouper par catégorie, par bibliothèque, par type ou de A à Z ne change pas. Le réglage suit
  votre compte sur vos appareils.
- **Chaque groupe se plie** en touchant son intertitre (le compte reste visible) ; le pli est retenu sur l'appareil,
  pour le regroupement en cours. « Tout replier » et « Tout déplier » dans « Trier et présenter ».
- **En défilant, on sait où l'on est** : au téléphone, la barre du haut nomme le groupe affiché (« Trauma ») ; sur
  grand écran, l'intertitre du groupe reste en tête pendant qu'il défile.
- **Provenance** : une tuile d'Accès direct dit sa bibliothèque au-dessus de sa catégorie (deux « Arrêt cardiaque »
  de deux bibliothèques se distinguent) ; le « · » ne tombe plus dans la pastille de bibliothèque ; rangée par
  catégorie, une aide ne redit plus sa catégorie ; dans la colonne de gauche, le nom d'une bibliothèque n'est plus
  coupé pour « partagée ».

## [5.94.0] — 2026-11-06
Des liens pour ouvrir l'application à un endroit précis, depuis une autre app ou l'app Raccourcis d'Apple (A586). Rien
à rejouer côté serveur.
- **Nouveaux liens** : `#creer` ouvre « Créer une aide », `#acces-direct` ouvre vos aides épinglées,
  `#bibliotheques` la liste des bibliothèques, `#bibliotheque=…` une bibliothèque, `#collection=…` une collection.
  Ils s'ajoutent à `#chercher`, `#sessions` et au lien direct d'une aide.
- **Moi › « Liens et raccourcis »** : une rangée par lien, toucher pour le partager ou le copier. Dans l'app
  Raccourcis, l'action « Ouvrir les URL » suivie du lien crée un raccourci à lancer par Siri ou depuis l'écran
  d'accueil.
- **Appui long sur l'icône** (Android, ordinateur) : Accès direct, Chercher une aide, Créer une aide, Sessions.
- Un lien ne change jamais l'écran pendant une session. Une collection ou une bibliothèque absente de l'appareil est
  signalée par une notice.
- **Limite d'iPhone et d'iPad** : un lien ouvert depuis une autre app s'ouvre souvent dans Safari, qui n'a pas les
  données de l'app installée. Essayez le raccourci une fois avant d'en dépendre.

## [5.93.0] — 2026-11-06
Les images d'une aide en grille, chacune avec sa feuille (A585). Rien à rejouer côté serveur.
- **Dans l'éditeur d'une aide, « Schémas & captures » devient une grille** de vignettes repliée à deux rangs, la
  légende sous chaque vignette et « ▣ Bloc n » sur celle qu'un bloc affiche. Elle remplace une grande carte par image.
- **Toucher une image ouvre sa feuille**, la même que pour les références : la légende, « Affichée dans » (aucun bloc
  ou un bloc), remplacer (le bloc qui l'affiche suit), retirer de l'aide (avec ↶ pour annuler).

## [5.92.0] — 2026-11-06
La taille d'une image se voit et se tire (A584). Rien à rejouer côté serveur.
- **Plus de pourcentages** : la taille d'une image se choisit parmi six pictogrammes, une colonne et la part qu'occupe
  l'image (¼ · ⅓ · ½ · ⅔ · ¾ · Pleine), sur le bloc image ouvert comme dans la feuille de l'image.
- **On voit le résultat** : l'image s'affiche dans un cadre qui représente la page lue sur grand écran, à la taille
  choisie, même au téléphone. Une phrase rappelle qu'au téléphone l'image prend toujours toute la largeur.
- **On peut tirer le bord** : la poignée bleue au bord de l'image se tire au doigt ou à la souris ; l'image s'aimante
  à la taille la plus proche, affichée pendant le geste (« ½ · 50 % »).

## [5.91.0] — 2026-11-06
Les images d'une référence en grille, chacune avec sa feuille (A583). Rien à rejouer côté serveur.
- **Dans l'éditeur d'une référence, les images forment une carte « Images du texte »** sous le contenu rédigé : une
  grille de vignettes, repliée à deux rangs (« n de plus » pour déplier). Elle remplace la liste d'une rangée par
  image, qui pouvait occuper plusieurs écrans.
- **Chaque vignette dit son usage** : « ×2 » quand l'image sert à deux passages, « △ hors texte » quand plus aucun
  passage ne l'affiche (elle sera retirée en quittant l'éditeur, comme avant).
- **Toucher une image ouvre sa feuille** : insérer au curseur, aller au passage (un toucher de plus passe au suivant),
  taille d'affichage, remplacer (tous les passages suivent), retirer de la référence (avec ↶ pour annuler).
- **« Image » entre dans le bouton « Ajouter »** de la référence. Déposer une image n'importe où dans l'éditeur et
  l'outil image de la barre marchent toujours.
- Les documents PDF restent au-dessus du texte : c'est là qu'ils s'affichent en lecture.

## [5.90.2] — 2026-11-06
Un correctif de la Page en session (A582). Rien à rejouer côté serveur.
- **En session, zoomer la Page « Tout voir » ne dérange plus la barre d'échelle** : quand la feuille dépasse, « la
  feuille dépasse à droite » s'affiche sous la barre, à droite, et « + » et « 1:1 » restent à leur place — comme dans
  la fenêtre « Page » depuis la 5.90.1.

## [5.90.1] — 2026-11-06
Trois correctifs d'affichage (A579-A581). Rien à rejouer côté serveur.
- **À l'accueil, les titres ne perdent plus le bas de leurs lettres** (g, q, y, p, ç) ni le haut des accents des
  capitales, en vue détaillée comme compacte. La hauteur des rangées ne change pas.
- **La Page « Tout voir » est centrée** dans sa colonne, en session comme hors session, au lieu d'être collée à gauche
  sur un écran large.
- **Dans la fenêtre « Page », zoomer ne dérange plus la barre** : quand la feuille dépasse, « la feuille dépasse à
  droite » s'affiche sous la barre, à droite, sans déplacer le titre ni les boutons de zoom.

## [5.90.0] — 2026-11-06
L'alarme d'un minuteur et l'écran de démarrage d'une aide au design actuel ; en session, les sections reprennent le même dessin (A577, A578). Rien à rejouer côté serveur.
- **La banderole d'un minuteur échu** (quand la session n'est pas à l'écran) reprend le dessin de l'échu dans la
  capsule : fond et bord ambre, pastille réveil, « △ ÉCHU · nom de l'aide » puis le nom du minuteur en grand. Elle se
  voit aussi bien en thème sombre. « — terminé » devient « Échu », le mot de la capsule.
- **Elle ne se pose plus sur la session** : dès que la session qu'elle annonce revient à l'écran (retour dans l'app,
  ou en y allant), elle disparaît — la capsule porte déjà l'alarme. Celle d'une autre aide reste.
- **Avant la session, « Quand l'utiliser » et « Ne pas oublier »** sont des cartes comme celles du dessous (pastille,
  titre, nombre), toujours ouvertes.
- **Au bureau, « Prêts pour la session »** est une liste, comme les minuteurs de la session : nom, valeur de départ,
  « au démarrage » ou « à lancer ».
- **En session, les sections sous le bloc redeviennent des cartes** (Ne pas oublier, revue, À vérifier,
  diagnostics, repères, références), comme sur l'écran de démarrage et comme avant la v5.89.0 — la liste
  « Pendant toute l'aide » disparaît (A578).

## [5.89.4] — 2026-11-06
Deux correctifs des étapes qui attendent leur moment (A576). Rien à rejouer côté serveur.
- **Une étape pas encore cochable se touche comme les autres** : toucher son texte (et plus seulement sa case) affiche
  « Prévue dans … » avec « Cocher » / « Annuler ». Toucher de nouveau referme la question ; relire la question ne la
  referme pas.
- **Un sigle garde ses capitales** dans la question : « Prévue dans 2 CEE. » au lieu de « 2 cEE. » (les mots
  ordinaires restent en minuscule : « 2 chocs délivrés »).

## [5.89.3] — 2026-11-06
Deux correctifs de la session (A574, A575). Rien à rejouer côté serveur.
- **La Page garde sa barre d'échelle en session** : en agrandissant beaucoup (pincer ou « + »), la barre « Plein écran ·
  ⤢ Ajusté · − 300 % + · 1:1 » passait sous l'en-tête et l'on ne pouvait plus dézoomer. Elle reste maintenant
  accrochée sous le quai de session, à toute échelle et à tout défilement.
- **La barre verte de retour au bloc** (« ↩ le bloc en cours ») reprend le même vert que le reste de la session en
  thème clair, avec un texte blanc — elle gardait le vert clair du thème sombre.

## [5.89.2] — 2026-11-06
Correctif d'affichage du rail du bureau (A573). Rien à rejouer côté serveur.
- **Un minuteur en marche, en pause ou échu** n'est plus coupé (« Cycle de… », « arrêté depuis… », « MAINTEN… ») :
  le nom et le temps sur la première ligne, puis la barre, l'état, et « Relancer » / « ↺ maintenir » sur leur ligne.
- **La consignation d'un compteur** (« consigné T+00:42 · il y a 23:20 ») passe sous le nom du compteur, en petit,
  au lieu d'être collée sous les boutons − / +.

## [5.89.1] — 2026-11-06
Correctif de la v5.89.0 (A571). Rien à rejouer côté serveur.
- À 320 px, la capsule dit de nouveau combien de minuteurs elle cache (« 1 minuteur ») : le nouveau chevron lui prenait
  la place, et le mot disparaissait quand le texte est rendu un peu plus large (constaté sur la CI Linux).
