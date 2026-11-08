# Journal des modifications

## [5.109.0] — 2026-11-08
Le suivi s'atteint d'un toucher, sans rien ajouter à la barre du haut (A615). Rien à rejouer côté serveur.
- **Une pastille « 2 tâches »** (ou « 1 note ») apparaît sous le titre d'une aide ou d'une référence qui a du suivi,
  à côté de « À relire ». Elle ouvre le suivi en feuille : cocher, ajouter, modifier sans perdre sa place.
- Pas de pastille sans suivi, ni pendant une session.

## [5.108.0] — 2026-11-08
Le volet « Suivi » dans l'éditeur (A614). Rien de nouveau à rejouer côté serveur (le schéma de la 5.107.0 suffit).
- **En modifiant une aide ou une référence**, le suivi est là : dans la colonne de droite sur ordinateur, sous la
  relecture ; en bas du formulaire au téléphone. Notes et tâches s'ajoutent, se cochent et se modifient sans quitter
  l'éditeur — même sur une aide ou une référence que vous êtes en train de créer.
- Le suivi reste à côté du contenu : il ne change pas la version validée.
- « Ajouter une note personnelle » disparaît aussi de l'éditeur (« ＋ Note » le remplace).

## [5.107.0] — 2026-11-08
Le suivi : des notes et des tâches sur chaque aide et chaque référence, pour vous ou pour l'équipe (A613).
**Schéma serveur à rejouer** (`supabase/schema.sql` : nouvelle table `aid_followups`, puis `supabase/rls-tests.sql`).
- **« Suivi »** en bas d'une aide ou d'une référence : « ＋ Note », « ＋ Tâche ». Une note peut être **pour vous**
  (privée) ou **pour l'équipe** de sa bibliothèque — les spécificités de votre centre, lues par tous les membres et
  modifiables par tous les éditeurs. Une tâche : à revoir, à fusionner avec une autre aide, à confronter à une
  référence ou à une reco, à compléter, autre ; une priorité (D'abord · Ensuite · Plus tard) et une échéance.
- **« À faire »** (onglet Moi au téléphone, colonne de gauche sur ordinateur) : toutes vos tâches **par priorité**,
  ou **par élément** pour voir ce qu'il reste sur chaque aide ; Moi · Équipe · Tout ; l'historique « Fait » est gardé.
- **Catalogue « Tout »** : filtre « Avec des tâches », tri « Tâches d'abord », et sur chaque rangée le nombre de tâches
  et la plus urgente.
- **Vos collections « À revoir », « À fusionner »…** se convertissent en tâches d'un geste (menu ⋯ de la collection,
  ou « À faire ») ; la collection reste.
- **Pendant une session**, seules les notes restent, repliées ; aucune tâche ne s'affiche.
- Une note s'ajoute désormais par « Suivi » ; votre note personnelle existante reste lisible et modifiable.

## [5.106.0] — 2026-11-08
Déplacer plusieurs blocs d'un coup (A612). Rien à rejouer côté serveur.
- **« ⠿ Déplacer » dans la barre de sélection des blocs** : les blocs sélectionnés, même non voisins, se déplacent
  ensemble — touchez « Poser ici », « en tête » ou « en fin ». Ils gardent leur ordre et restent sélectionnés à
  l'arrivée ; ✕ ou Échap annule, ↶ rend l'ordre d'avant.

## [5.105.0] — 2026-11-08
Tableaux, blocs et import de l'éditeur de référence (A609-A611). Rien à rejouer côté serveur.
- **Un tableau se rouvre en grille** : ouvrez-le dans le document, « Modifier en grille ».
- **En-têtes au choix** dans la grille : 1ʳᵉ ligne, 1ʳᵉ colonne, les deux ou aucun. **Entrée passe à la ligne dans une
  case**, et la grille a son propre ↶ / ↷.
- **La fenêtre du tableau ne se ferme plus** quand une sélection de texte se termine hors de la carte (vaut pour toutes
  les fenêtres).
- **« ＋ » au-dessus et au-dessous du bloc survolé** à la souris ; au doigt, « Bloc avant » rejoint « Bloc après ».
- **Sélectionner plusieurs blocs** pour les copier ou les supprimer : Maj-clic, ⌘/Ctrl-clic ou sélection glissée à la
  souris, « Sélectionner » au doigt ; Suppr supprime, ↶ rend tout.
- **Un bloc vidé propose de redevenir** paragraphe, titre, encadré, liste, cases, tableau, image ou séparateur.
- **Import** : « Renommer » chaque élément avant de l'importer ; une page (Notion…) peut être **versée dans une référence
  déjà créée** — elle remplit son contenu vide ou s'ajoute à la suite, jamais d'écrasement ; la référence garde son titre,
  sa catégorie et sa bibliothèque.

## [5.104.0] — 2026-11-08
Le Markdown copié depuis Notion se lit tel quel, et quatre défauts de lecture corrigés (A607-A608). Rien à rejouer côté
serveur.
- **Gras et italique imbriqués** : `***gras italique***`, un gras qui contient un italique
  (`**indications *systématiques* en AVP**`) et un italique qui contient un gras sont rendus ; un balisage croisé reste
  visible plutôt que de casser la ligne. **`~~barré~~`** est rendu.
- **Listes sur six niveaux** : l'indentation fait le niveau (celle de Notion comprise, 4 espaces) ; Tab / Maj+Tab
  changent d'un niveau dans l'éditeur ; les cases `- [ ]` sont lues à tout niveau. Avant, tout au-delà du 2ᵉ niveau
  était aplati.
- **Dans l'éditeur, tout marqueur d'emphase se grise** (le 3ᵉ astérisque de `***` restait à l'encre du texte).
- **Image « Pleine »** : elle prend toute la largeur de la colonne, même petite — tirer la poignée au-delà de ¾ ne la
  fait plus rétrécir.
- **Le Plan** d'une référence se lit comme un arbre : chaque titre en retrait de son niveau, rattaché à son parent.
- **La pastille de bibliothèque d'une rangée** : icône alignée sur le texte, marge intérieure rétablie.
- **En sélection**, toucher le titre d'une aide ne le surligne plus en gris comme un lien.

## [5.103.0] — 2026-11-08
La nouvelle architecture est en place (A606, lots 2 et 3 d'A600) : l'accueil lance, le catalogue range. Rien à rejouer
côté serveur.
- **L'accueil devient un lanceur** dès que vous avez plus de vingt aides et protocoles : session en cours, Accès
  direct, vos collections, **les aides ouvertes récemment**, et « Toutes les aides et protocoles », qui mène au
  catalogue. En dessous de vingt, l'accueil reste la liste complète : tout y tient.
- **L'onglet « Aides » s'appelle « Accueil »** (icône maison), au téléphone comme sur ordinateur.
- **La colonne de gauche ne filtre plus** (ordinateur, tablette) : navigation et collections seulement. Les
  bibliothèques et leurs catégories sont dans « Bibliothèques », avec « Gérer les catégories », « Gérer les
  bibliothèques » et « Partager avec une équipe… ».
- **Le catalogue** ne montre plus les catégories vides d'une bibliothèque ; sur ordinateur, un nom long n'est plus
  coupé par « à relire ».
- **Les liens** « Bibliothèques » (Moi › Liens et raccourcis, raccourcis de l'app) ouvrent le catalogue.
- Corrigé : sur ordinateur, revenir dans le catalogue pouvait faire disparaître le pied de page et bloquer l'écran
  suivant.

## [5.102.1] — 2026-11-08
Correctifs de l'éditeur de référence et du dock (A604-A605). Rien à rejouer côté serveur.
- **Déplier « Identité » ne fait plus déborder l'éditeur** (texte et aperçu côte à côte) : il se réajuste à la place
  restante et la page défile ; replié, il reprend sa hauteur. Avant, son bas passait sous l'écran.
- **La pastille du dock est fluide** : elle glisse et change de largeur d'un seul mouvement, et les mots des onglets
  changent de couleur à son rythme (A605) — elle sautait.

## [5.102.0] — 2026-11-08
Le catalogue des bibliothèques gagne le geste « retour » et des volets sur grand écran (A602). Rien à rejouer côté
serveur.
- **Le geste « retour » remonte d'un niveau** dans le catalogue : d'une catégorie à sa bibliothèque, puis à la liste
  des bibliothèques — au téléphone comme sur ordinateur.
- **Des volets sur tablette et ordinateur** : les bibliothèques à gauche, les catégories de celle choisie au milieu
  (sur un écran assez large ; sinon elles se déplient sous la bibliothèque), et les aides à droite. « Tout » s'affiche
  d'office.
- **La pastille du dock glisse** d'un onglet à l'autre, comme celle des sélecteurs de Moi — au tap comme en faisant
  glisser le doigt (A603).

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
