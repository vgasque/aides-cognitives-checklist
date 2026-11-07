# Journal des modifications

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

## [5.89.0] — 2026-11-06
La session, deuxième passe « Natif » : ce qui entoure les étapes se rapproche d'iOS et de Material 3 (A571, doctrine
`docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Le titre de l'aide n'est plus coupé** en session : il passe sur deux lignes, et « · adulte » le suit.
- **L'historique redevient discret** : une ligne de texte gris, sans pastille, jamais coupée. Elle dit
  « Historique · diagnostic confirmé », puis « Historique · 2 blocs ». Le mot « Parcours » a disparu ; le compte des
  étapes reste à droite. Ouvert, il montre une boîte grise en retrait : la confirmation et ses critères, puis les blocs faits.
- **Les boutons « Vérifier » et « Cochez les n restantes »** tiennent sur une ligne, en pilules.
- **Le quai du bas est aligné et plus compact** : plus de séparateurs, une barre en pilule. Au téléphone, toutes les
  icônes sur une même ligne et chaque mot sur la sienne ; sur tablette et au bureau, l'icône à gauche du mot. Avec plusieurs complications, la touche dit « Complications » et le nombre s'affiche dans une
  pastille sur l'éclair.
- **Sous le bloc, une seule liste « Pendant toute l'aide »** remplace les six cartes (Ne pas oublier, revue,
  À vérifier, diagnostics, repères, références) ; chaque section se déplie sur place. La note locale s'intitule
  « Contexte local ».
- **Au bureau, la colonne de droite passe en listes** : chaque minuteur a son bouton « Démarrer » visible, chaque
  compteur une pilule « − n + », « Ajouter un minuteur » et « Ajouter un compteur » sont au pied de leur liste, le son
  et la veille deviennent des interrupteurs.

## [5.88.1] — 2026-11-06
Retours sur la v5.88.0 : la confirmation d'une étape qui attend son moment dit ce qui reste, plus de lignes vides, et
l'exercice guidé l'enseigne (A570 §10, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- Toucher la case d'une étape en attente affiche maintenant **ce qui reste** : « Prévue dans 2 chocs délivrés. »,
  « Prévue dans 1 choc délivré. », ou « Prévue dans 03:56. » (le temps défile), puis **« Cocher »** ou **« Annuler »**.
- **Plus de ligne vide** sous une étape en attente : sous une étape qui lance un minuteur ou compte, la ligne dit ce
  que fera la coche (« ◷ 04:00 Adrén. dose ») ; sinon, il n'y a pas de ligne.
- **L'exercice guidé** montre une étape qui attend son moment et la question de sa case ; « Prendre en main » gagne le
  geste « Une étape qui attend son moment », et le glossaire le terme « Moment d'une étape ».

## [5.88.0] — 2026-11-06
Les étapes « complexes » en session (registre, compteur ou minuteur liés, étapes qui attendent leur moment) sont
redessinées sur une seule grammaire, plus légère (A570, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté
serveur.
- **Une place pour chaque chose.** Au-dessus du libellé, en petits mots : quand et quel risque (CRITIQUE, VIGILANCE,
  DOUBLE CONTRÔLE, « CHOCS DÉLIVRÉS ≥ 3 ●○○ », « À L'ÉCHÉANCE ◯ 03:57 », ✓✓ CONSTATÉ). Dessous : ce que fait
  la coche.
- **Une liste, sans cadres.** Les étapes sont séparées par un simple filet. Plus de cadre pointillé autour des étapes
  qui attendent, plus de fond vert sous les étapes faites : la case et la couleur du texte disent l'état, et seule
  l'étape à faire maintenant reste en noir.
- **Une seule taille de libellé**, revue des causes réversibles comprise.
- **Des mots plus courts** : « +1 Chocs délivrés » au lieu de « 3 → 4 à la coche · Chocs délivrés », « annulable 9 s »
  au lieu de « décocher annule · 9 s », « relance à 05:00 ».
- Le minuteur qu'attend une étape « à l'échéance » s'affiche à côté de sa condition ; quand il arrive au bout, l'étape
  dit **« ✓ À L'ÉCHÉANCE »** en vert, comme un seuil atteint (au lieu de « Échu », qui disait l'état du minuteur).
- Une étape à faire une seule fois, déjà faite à un passage précédent, dit **« ✓ DÉJÀ FAITE »**.
- **Une seule coche** : l'icône de la case, reprise en petit dans les mots du dessus ; le « ✓ » devant la réponse d'une
  étape cochée disparaît (il doublait la case verte).
- Une étape garde sa hauteur quand son moment arrive (rien ne bouge sans geste).
- La trace de vérification (« ✓✓ constaté », « △ écart ») rejoint les autres mots au-dessus du libellé.
- **Une seule police dans l'étape** : la réponse attendue et les valeurs quittent la police à chasse fixe ; la réponse
  reste distincte du libellé par sa taille et sa couleur.
- **Plus de bouton « Faire maintenant ».** Pour cocher une étape avant son moment, on touche sa case : la ligne du
  dessous dit « Pas encore le moment. » et propose « Cocher quand même » ou « Annuler ». Une coche par erreur (qui
  lancerait un minuteur) est ainsi rattrapée, et rien n'encombre la rangée au repos.
- Audit : un témoin mesure la nouvelle grammaire, dont l'écart entre le mot de registre et son libellé.

## [5.87.0] — 2026-11-05
Les étapes « complexes » en session — celles qui attendent leur moment, comptent, lancent un minuteur — retrouvent
leurs couleurs et s'allègent (A569, doctrine `docs/decisions/lot-v6-0.md`). Rien à rejouer côté serveur.
- **Correctif : trois étiquettes d'étape avaient perdu leur couleur** depuis la v5.61. Au 3ᵉ choc, l'étiquette
  « ✓ Chocs délivrés ≥ 3 » de l'étape qui devient faisable redevient **verte** ; « Échu » (l'échéance du minuteur
  de l'étape) redevient **ambre** ; « Faite » (une étape à faire une seule fois, déjà faite) redevient verte. Elles
  sortaient toutes grises, comme une règle encore en attente.
- **Correctif : l'étape qui s'ouvre au seuil ne vire plus au gris.** Son éclairage vert finissait sur l'ancien fond
  gris des étapes, puis disparaissait d'un coup ; il s'éteint maintenant en douceur vers la rangée nue.
- L'étape « faite une fois » vit à plat, comme les autres étapes : son cadre gris disparaît. Seule l'étape qui
  attend son moment garde un cadre, en pointillé.
- Les règles de moment s'écrivent en phrase (« Chocs délivrés ≥ 3 », « À l'échéance », « Au besoin ») au lieu de
  capitales espacées ; les mots d'état (« Échu », « Faite »), comme CRITIQUE et VIGILANCE, restent en capitales —
  la règle et l'état se distinguent d'un coup d'œil.
- « passage 4/4 » ne se coupe plus entre le mot et le compte au téléphone.
- Audit : un témoin lit désormais la couleur et la casse de ces étiquettes (aucun ne le faisait).
