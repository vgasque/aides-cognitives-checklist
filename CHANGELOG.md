# Journal des modifications

## [5.51.0] — 2026-10-07
Qui peut créer une bibliothèque, et comment la demander (A478-A479, doctrine `docs/decisions/lot-v5-51.md`).
**⚠ Rejouer `supabase/schema.sql`** (§ 9 et 9bis) pour en profiter ; sans cela, l'app garde l'ancienne règle
(administrateurs seulement) et Administration le signale.
- **Administration › Création de bibliothèques** : trois réglages — *Administrateurs seulement*, *Personnes
  autorisées*, *Tout compte approuvé*. Par défaut, « Personnes autorisées » avec une liste vide : rien ne change tant
  que vous n'autorisez personne. « ＋ Autoriser une personne… » choisit parmi les comptes approuvés ; « Retirer » rend
  la règle commune. Une personne autorisée devient administratrice de ce qu'elle crée, et ne peut créer qu'à son nom.
- **Les autres demandent** : « ＋ Demander une bibliothèque… » ouvre la même fenêtre que la création (nom, avec qui,
  rôle des invités ; sans invité, elle rappelle qu'une collection suffit pour ranger). La demande apparaît en tête
  d'Administration : « Créer » ouvre la bibliothèque au nom du demandeur et y invite les personnes indiquées ;
  « Refuser » la classe. Dans Moi, chacun voit ses demandes en attente (Annuler) ou refusées (Effacer).
- **Données** : les adresses des personnes à inviter ne sont gardées que jusqu'à la décision (registre RGPD § 3).

## [5.50.0] — 2026-10-07
Les collections : ranger ses aides sans rien déplacer (A475-A477, doctrine `docs/decisions/lot-v5-50.md`).
- **Une collection est votre rangement, à vous seul** : une liste nommée d'aides et de protocoles venus de n'importe
  quelle bibliothèque, même en lecture seule. Rien n'est copié ni déplacé, et une même aide peut être dans plusieurs
  collections. Elles suivent votre compte sur tous vos appareils ; les autres membres d'une bibliothèque ne les voient pas.
- **Où les trouver** : au téléphone, une rangée « Mes collections » sous l'Accès direct ; au bureau, dans la colonne de
  gauche ; dans la feuille Affichage ; dans Moi. L'Accès direct est la première collection.
- **Ranger** : « Ajouter à une collection… » dans le menu ⋯ de chaque aide et protocole (même quand « Modifier » est
  grisé) et en tête de la feuille Actions d'une sélection. Des cases : cocher range, décocher retire.
- **Une collection ouverte** dit qu'elle est à vous seul et d'où vient son contenu, propose « Ajouter des aides » et,
  par ⋯, Renommer, Retirer les indisponibles, Supprimer — les aides restent toujours où elles sont.
- **La barre de sélection ouvre ses actes par « Actions » à toutes les largeurs** : avec « Collection… », les cinq actes
  en toutes lettres ne tiennent plus sur la ligne au bureau.
- **« Nouvelle bibliothèque » demande d'abord « Avec qui ? »** et invite ces personnes à la création. Sans invité, elle
  propose une collection, qui suffit pour ranger. Une bibliothèque partagée avec personne peut être **convertie en
  collection** depuis sa fenêtre : ses éléments passent dans Perso, rien n'est supprimé.
- **Mettez à jour tous vos appareils** : une version antérieure ne connaît pas les collections (elle ne les efface pas).

## [5.49.0] — 2026-10-06
L'étape qui attend un seuil dit enfin ce qui est compté et quand sa case s'ouvre (A474), et quatre retours d'usage corrigés (A473, doctrine `docs/decisions/lot-v5-48.md`).
- **La jauge d'un seuil vit dans son étiquette.** « CHOCS DÉLIVRÉS ≥ 3 ●○□ » : les points comptent le compteur
  nommé juste avant, et le dernier repère a la forme d'une case — c'est là que l'étape devient cochable. Sous le
  libellé, les points et « encore 3 » se lisaient comme le compte de l'étape (« cochable encore 3 fois »).
- **Avant son seuil, la case de l'étape est là, estompée** (pleine et pâle) au lieu d'un pointillé qui se lisait
  « inatteignable » — « Faire maintenant » la coche à tout moment, à droite de la rangée. Au seuil, l'étiquette
  passe au vert, jauge pleine, et la case reprend son trait.
- **L'instant du seuil se voit** : au choc qui atteint le seuil, l'étape qui s'ouvre rebondit et s'éclaire brièvement
  de vert, une fois — seulement sur l'appareil qui a fait le geste, et jamais avec « réduire les animations ».
- **« Se déconnecter » ne déconnecte plus que cet appareil.** Il révoquait toutes les sessions du compte : les autres
  appareils se retrouvaient déconnectés au rafraîchissement suivant.
- **La capsule de session montre deux compteurs quand ils tiennent, toujours avec leur nom entier.** Le rappel à côté
  du chevron dit « +1 compteur » (ou « +1 minuteur ») quand une partie est déjà montrée : « 1 compteur » à côté d'une
  tuile de compteur se lisait comme le total. Un nom de compteur n'est plus jamais coupé (« Chocs délivr… » quand un
  minuteur tournait) : la tuile cède la place plutôt que de s'abréger. Les minuteurs restent prioritaires.
- **« Relâcher avant la fin annule »** se pose 14 px sous les boutons de la fenêtre de fin (il les touchait).
- **Moi : « Exporter mes données », « Prendre en main » et « Un problème ? »** sont espacés de la même façon (12 px).

## [5.48.9] — 2026-10-06
Au téléphone, dans Safari, toucher juste sous les boutons de la barre d'outils marche (A472, doctrine `docs/decisions/lot-v5-48.md`).
- **Ce qui se passait** : sous la barre, la bande blanche jusqu'à la barre « ⌃ ⌄ ✓ » du clavier n'appartient pas à la
  page mais à Safari (sa barre d'adresse flottante, environ 43 px). Un toucher y déplie Safari et ferme le clavier ;
  l'app ne le reçoit jamais, donc ne peut ni l'empêcher ni le rendre au bouton visé.
- **Une bande de 12 px sous les boutons fait désormais partie de la barre**, dans Safari seulement : un doigt qui vise un
  peu bas tombe chez l'app et va au bouton le plus proche. Elle prend 12 px au texte.
- **App installée sur l'écran d'accueil** : la bande de Safari n'existe pas, la barre reste à 41 px.

## [5.48.8] — 2026-10-06
Au téléphone, toucher un peu à côté d'un bouton de la barre d'outils ne ferme plus le clavier (A471, doctrine `docs/decisions/lot-v5-48.md`).
- **Mesuré avant correction** : un toucher sur sept à un sur quatre dans la barre (entre deux boutons, sur les bords,
  dans le vide avant « Insérer ») et environ 40 % des touchers entre les lignes d'un menu ouvert faisaient perdre la
  main au texte, donc fermaient le clavier.
- **Toute la barre et tout le menu gardent maintenant le clavier ouvert**, et un toucher à côté d'un bouton (jusqu'à
  12 px) va au bouton le plus proche ; une bande de 8 px au-dessus de la barre fait de même.
- **La barre garde sa hauteur de 41 px** : clavier et barre de Safari ouverts, elle laisse au texte la même place
  qu'avant (sur iPhone 15, environ 12 lignes visibles).

## [5.48.7] — 2026-10-06
Au téléphone, toucher la barre d'outils au-dessus du clavier marche à chaque fois (A470, doctrine `docs/decisions/lot-v5-48.md`).
- **Le clavier ne se ferme plus quand on touche un bouton de la barre ou une ligne de ses menus.** Sur iPhone, il se
  fermait une fois sur deux : le toucher retirait parfois le focus au texte avant que l'app ait pu l'en empêcher, et le
  bouton touché ne répondait alors pas toujours.
- **Retoucher le bouton d'un menu ouvert le ferme** (avant, il se refermait et se rouvrait aussitôt).
- Un glissé du doigt sur la barre ne déclenche rien.

## [5.48.6] — 2026-10-06
Au téléphone, les menus de la barre d'outils fonctionnent pendant qu'on écrit (A469, doctrine `docs/decisions/lot-v5-48.md`).
- **Titre, Liste, Encadré et Insérer s'ouvrent juste au-dessus de la barre**, sur toute sa largeur, quand elle est posée
  au-dessus du clavier. Avant, toucher l'un d'eux fermait le clavier : la barre redescendait sous le doigt et le menu
  s'ouvrait en bas de l'écran, sous le clavier.
- **Le clavier reste ouvert** pendant le choix, et après : on reprend la frappe là où l'on était. Toucher le texte
  referme le menu.

## [5.48.5] — 2026-10-06
Deux retouches de l'éditeur des références signalées à l'usage (A468, doctrine `docs/decisions/lot-v5-48.md`).
- **Sur tablette (780 à 999 px), l'aperçu sort de la carte** : il passe dans une colonne à droite, comme sur
  ordinateur, au lieu de s'afficher dans un cadre à l'intérieur du cadre « Contenu rédigé ». La barre d'outils prend
  alors le format compact (icônes) et tient sur une ligne.
- **Au téléphone, la barre d'outils se pose au-dessus du clavier** pendant qu'on écrit, comme la recherche de
  l'accueil. Le texte ne bouge pas quand elle se détache. Toucher un outil (B, I, S) n'abaisse plus le clavier ;
  les menus (Titre, Liste, Encadré, Insérer) l'abaissent le temps du choix, puis le texte reprend la main. À
  vérifier sur iPhone réel : le rendu dépend du clavier d'iOS.

## [5.48.4] — 2026-10-06
- **Exercice guidé, « Cochez les étapes restantes » :** le bloc en cours reste entièrement net, sans anneau, et le
  reste de l'écran (en-tête, capsule, quai) s'estompe — on voit d'un coup d'œil où cocher (A467).

## [5.48.3] — 2026-10-06
- **La proposition d'exercice guidé saute aux yeux.** Sur les aides d'exemple, la rangée « Apprendre avec cette
  aide » prend le dessin du mode Exercice : fond hachuré bleu pâle, bord en pointillé, titre et bouton en bleu —
  comme la bande d'exercice et la touche « ▲ Exercice ». Elle se distingue des cartes de l'aide en clair comme en
  sombre ; « Démarrer la session » reste le seul bouton plein de l'écran (A467).

## [5.48.2] — 2026-10-05
Retour d'essai sur iPhone de l'exercice guidé (A467) : la bulle cachait ce que le geste ouvrait, et le défilement
saccadait.
- **La bulle devient une carte fixe au-dessus du quai.** Elle ne suit plus la page, donc plus de saccade ; la commande
  visée se montre par son anneau. La page réserve sa hauteur en bas : on peut toujours défiler jusqu'à la dernière ligne.
- **Plus rien de caché.** Le volet des minuteurs s'arrête au-dessus de la carte (et défile). Pour « Cochez les étapes
  restantes », aucune bulle ni anneau devant les cases : toutes les cases libres sont amenées en vue, puis l'anneau
  se pose sur « Continuer » quand il est prêt. Dans une complication, la carte dit où l'on est et que le bloc quitté
  attend, coches gardées.
- **La capsule s'apprend par la main** au téléphone : l'ouvrir, puis la refermer.
- **▾ réduit la carte** en une pastille « ▲ Guide 4/8 » pour voir tout l'écran ; un toucher la rouvre.
- Le guide ne ramène jamais la page vers la cible quand on défile soi-même.
- Au bureau, la carte se pose dans la colonne d'action, en ligne ; sur un pliable, d'un seul côté de la charnière.
- `audit-guide` vérifie désormais tout cela, pliable émulé compris.

## [5.48.1] — 2026-10-05
- **Exercice guidé : tout l'écran s'estompe, sauf la commande visée.** En v5.48.0, seuls certains éléments
  pâlissaient (les blocs, les touches du quai, la capsule) ; l'en-tête, la bande « Exercice », la ligne « Parcours »,
  les cartes sous le bloc et la fenêtre de fin restaient nets. Un voile unique, léger, couvre désormais tout l'écran
  et laisse la cible nette ; il ne bloque aucun toucher. Il suit le thème clair ou sombre (A467).
- Le harnais `audit-guide` vérifie ce voile à chaque bulle : il couvre la fenêtre et son ouverture correspond à la
  cible.

## [5.48.0] — 2026-10-05
L'exercice guidé (A467, doctrine `docs/decisions/lot-v5-48.md`), dernier point de l'audit de prise en main.
- **Apprendre avec une aide d'exemple, geste par geste.** Sur l'ACR et l'anaphylaxie d'exemple, une carte propose
  « Commencer le guide » ou « Ne plus proposer ». Le guide lance un exercice et pose une bulle sur la vraie commande
  de l'écran : démarrer, cocher une étape, lire la capsule, passer au bloc suivant et répondre à la question, ouvrir la
  revue des causes réversibles, ouvrir une complication puis « Reprendre », horodater, terminer en maintenant 1,2 s.
  La bulle de la complication explique aussi le jalon (« … quand Chocs délivrés atteint 3 »).
- On avance en faisant le geste ; « Suivant » quand il n'y a qu'à regarder ; « Passer » et « Quitter le guide » à tout
  moment, l'exercice continuant seul. Le reste de l'écran s'estompe légèrement et reste utilisable. À la fin, une carte
  récapitule les gestes et propose de refaire le guide.
- Le guide n'existe qu'en exercice : jamais pendant une session réelle, rien n'est enregistré comme soin. On le
  relance par le menu ⋯ de l'aide d'exemple ou par Moi › Prendre en main › « Lancer l'exercice guidé ».
- **Le guide et « Prendre en main » suivent l'app** : leurs mots et leurs cibles viennent de l'écran et de l'aide.
  Deux nouveaux garde-fous les vérifient à chaque changement : `check-guide` (libellés cités, commandes visées) et
  le harnais `audit-guide` (déroulé complet à 390, 1280 et 360 px à 130 %).

## [5.47.0] — 2026-10-05
Troisième lot de l'audit de prise en main (A463-A466, doctrine `docs/decisions/lot-v5-47.md`).
- **« Prendre en main », dans Moi** : dix gestes expliqués (trouver, démarrer, cocher, chrono et minuteurs,
  complication, horodater, tout voir, partager, terminer, écrire une aide) et un glossaire de seize termes (session,
  exercice, essai, complication, revue, jalon…). « Revoir l'accueil » y vit désormais.
- **Une aide ou un protocole neuf naît en brouillon**, et non plus « Validée ». Vous la validez une fois relue. Dans une
  bibliothèque partagée, la fenêtre de création dit qui la voit.
- **Lien direct vers une aide** : menu ⋯ › « Copier le lien direct ». Le lien ouvre l'aide sur tout appareil qui la
  possède (raccourci d'écran d'accueil, collègue de la même bibliothèque). Un appui long sur l'icône de l'app propose
  « Chercher une aide » et « Sessions ».
- **Texte agrandi (115 et 130 %)** : les touches du quai gardent leur mot entier (« Tout voir » n'est plus un glyphe
  seul, plus de « Horoda / ter »). Le titre du bloc en cours ne se coupe plus au milieu d'un mot : « EN COURS » passe
  au-dessus de lui.
- La légende sous le titre d'un bloc dit en clair : « sous l'étape, en gris : la réponse attendue ».
- **Éditeur** : l'identité d'une aide existante s'ouvre repliée, et l'éditeur s'ouvre sur le contenu. Chaque section
  des réglages d'une étape porte un exemple.
- **Accessibilité** : au clavier, la touche Tab atteint de nouveau les rubriques dépliables des fenêtres
  (« Pourquoi créer un compte ? »…).

## [5.46.2] — 2026-10-05
- **Le compteur affiché dans la capsule de session dit son nom en entier.** Au téléphone, la tuile montrait
  « CHOCS DE… ». Elle se lit maintenant en ligne : la valeur d'abord, puis le nom complet sur deux lignes
  (« 0 Chocs délivrés »). Si vous avez donné un nom court au compteur, c'est lui qui s'affiche. Le nom n'est coupé
  qu'à 320 px ou en très grand texte (A462).
- Éditeur : le champ « Nom court » d'un compteur propose le nom entier comme valeur par défaut, et non plus un
  abrégé.

## [5.46.1] — 2026-10-05
- **Accueil au téléphone** : plus d'air sous « Sessions · Créer · Moi ». L'en-tête gagne 8 px en bas. Avant, ces mots
  étaient à 3 px de la carte « Besoin d'exemples » et à 5 px du bandeau ; ils en sont maintenant à 11 et 13 px, et à
  19 px de la liste (A461).

## [5.46.0] — 2026-10-05
Deuxième lot de l'audit de prise en main : un seul vocabulaire, un nom par vue, des boutons qui se nomment (A461, doctrine `docs/decisions/lot-v5-46.md`).
- **Un seul vocabulaire.** L'app dit « aide » (le parcours à cocher) et « protocole » (le texte à lire), plus jamais
  « fiche ». Quand un texte parle des deux à la fois (compte, synchronisation, stockage), il dit « vos données ».
  L'accueil compte « 2 aides », et non plus « 2 parcours ». Un contrôle automatique (`check-lexique`) empêche
  « fiche » de revenir dans le texte affiché.
- **Un nom et une icône par vue.**
  - « Tableau », sur l'écran d'entrée d'une aide, s'appelle « Page », comme son onglet.
  - Le réglage d'ouverture propose « Un bloc » ou « Tout voir », comme le quai.
  - L'aperçu de l'éditeur s'appelle « Schéma ».
  - « Tout voir » prend une icône de page et « Moniteur » une icône d'écran. L'icône d'agrandissement ne sert plus
    qu'à « Plein écran ».
- **Accueil au téléphone** : les trois boutons de l'en-tête portent leur nom en dessous (Sessions · Créer · Moi),
  comme la colonne de gauche sur grand écran.
- Éditeur : « Doses & seuils » devient « Repères posologiques », le nom de la section en lecture.
- Inchangé, par décision antérieure : le bouton ◑ (thème) reste dans l'en-tête des aides, pour éteindre l'écran au
  chevet sans ouvrir de réglage.

## [5.45.0] — 2026-10-05
Premier lot de l'audit de prise en main (`docs/audit-apprentissage-2026-10.md`) : ce qu'un nouvel utilisateur ne trouvait pas, ou lisait de travers (A460, doctrine `docs/decisions/lot-v5-45.md`).
- **Recherche** :
  - la précision d'une aide (« adulte », « pédiatrique »…) est désormais cherchée, pour les aides comme pour les
    protocoles ;
  - **Entrée** ouvre le premier résultat.
- **« Exercice » écrit en entier** sur le quai dès 360 px de large ; « Exo. » ne reste que sur les plus petits écrans.
  Une fois armée, la touche affiche aussi « Annuler » à l'écran, et plus seulement pour les lecteurs d'écran.
- **Affichage › Regrouper** : « Catégorie » et « Bibliothèque » en toutes lettres (sur deux lignes si besoin), au lieu
  de « Catég. » et « Biblio. ».
- **Fin de session** : le bouton rouge dit lui-même « Terminer · maintenir 1,2 s ». Un tap bref ne faisait rien en
  apparence, et la consigne était écrite plus bas.
- **Mode exercice** : le bouton dit « Démarrer l'exercice ». « Confirmé — » reste réservé à la session réelle, où il
  acquitte les critères « Quand l'utiliser ».
- **Accueil** : le badge « △ À compléter » se touche et dit ce qui reste à remplacer ; son explication n'existait
  qu'au survol de la souris.
- **Les deux aides d'exemple arrivent « À relire »**, et non plus « Validée », avec un bandeau qui le dit. Valider
  reste votre geste. La notice « À relire » se lit avant la session et n'occupe plus l'écran pendant.
- **Moi › « Revoir l'accueil »** rouvre l'écran de bienvenue. Il se fermait pour toujours au premier tap. Ses portes
  déjà sans objet s'effacent (exemples déjà présents, compte déjà connecté).
- L'info-bulle de « Vérifier » est en français (« Relire ce bloc étape par étape… »).
- Non traité dans ce lot : le nom du compteur dans la capsule (« CHOCS DE… ») — la place manque à 64 px, décision de
  dessin à prendre.

## [5.44.0] — 2026-10-05
L'éditeur des références (protocoles) devient un vrai éditeur de texte, au téléphone comme sur ordinateur (A452-A459, doctrine `docs/decisions/lot-v5-44.md`).
- **Lier un PDF joint sans recopier son identifiant** : « ＋ Insérer › Lien vers un document joint », ou taper `](att:`
  et choisir le document dans la liste, ou toucher (ou glisser vers le texte) le nouveau bouton lien de chaque document.
  `#p12` après l'identifiant ouvre le PDF à la page 12.
- **Une barre d'outils regroupée** : B · I · S, puis quatre menus — Titre, Liste, Encadré, ＋ Insérer (tableau, lien
  vers un document, lien web, image, code, séparateur). Chaque choix montre la syntaxe qu'il pose. La barre reste
  visible en haut pendant qu'on fait défiler le texte et tient sur une ligne jusqu'à 344 px de large.
- **Le clavier** : Entrée continue une liste (puces, numéros, cases, citations) et la termine sur une ligne vide ;
  Tab et Maj+Tab changent le niveau d'une puce ; ⌘B, ⌘I et ⌘K font gras, italique et lien. **⌘Z annule aussi les
  gestes de la barre.**
- **Une disposition par écran** : au téléphone, « Écrire | Aperçu » ; sur tablette, le texte et l'aperçu côte à côte ;
  sur ordinateur, l'aperçu dans la colonne de droite. Un bouton « Plan » mène à chaque titre, l'aperçu marque le
  passage où l'on écrit, et toucher l'aperçu ramène le curseur au bon endroit du texte.
- **Les tableaux se remplissent dans une grille** (« Insérer › Tableau », ou « Modifier en grille » quand le curseur
  est dans un tableau) : ajouter ou retirer lignes et colonnes, aligner une colonne, modèle « posologie ».
- **Coller depuis Word ou un PDF** : titres, puces, tableaux et gras sont reconnus, et l'app montre ce qui sera inséré
  avant de le faire. La couleur n'est pas reprise (elle a un sens dans l'app) : la fenêtre le dit. « Coller le texte
  brut » reste possible.
- **Une relecture de l'écriture** sous le texte : lien vers un document absent, ligne de tableau incomplète, titre ou
  encadré mal posé, et les écritures de dose qui trompent la lecture — « .5 mg » (→ 0,5 mg), « 5,0 mg » (→ 5 mg),
  « ug », « U », « cc ». Chaque point se corrige un par un, d'un tap, et s'annule. Elle relit la façon d'écrire,
  jamais le contenu clinique.
- **Sur ordinateur, le texte se colore** : marqueurs en gris, encadrés à leur couleur, points de relecture soulignés.
- **Écrans pliables** (Surface Duo, Pixel Fold ouverts) : le texte sur un écran, l'aperçu et la relecture sur l'autre,
  plus rien à cheval sur la charnière. Vérifié aussi sur Galaxy Z Fold (fermé et ouvert) et Z Flip.
- Corrigé : dans une référence, les lignes du volet « Relecture » ne réagissaient pas au toucher, et sous 1000 px le
  volet ne suivait pas la frappe.

## [5.43.1] — 2026-10-05
La barre de sélection et l'en-tête de l'accueil ne rognent plus rien sous Windows et Linux (A451, doctrine `docs/decisions/lot-v5-43.md`, second chapitre).
- **Une case pour tout cocher** : à gauche du compte, une case du même dessin que celle des rangées remplace les deux
  boutons « Tout cocher / Tout décocher ». Vide quand rien n'est coché, un tiret quand une partie l'est, une coche quand
  tout l'est ; un tap coche tout, ou décoche tout si tout était coché. Elle est là à toutes les largeurs (sur un petit
  téléphone, « Tout décocher » ne passe plus par le tiroir « Actions »).
- **Sur grand écran, les actes portent leur glyphe** : Bibliothèque, Catégorie, Exporter, Supprimer, avec les mêmes
  dessins que dans le tiroir « Actions ». Le compte « 2 cochés » se lit en entier : sous Windows et Linux, vers 1200 px,
  il était réduit à « … » depuis l'arrivée d'« Exporter… ».
- **« 0 coché »** remplace « Rien de coché », qui était coupé sur les écrans de 320 px.
- **Sur téléphone, le nom « Aides cognitives » de l'accueil est un peu plus petit** (sous 480 px de large) : il touchait
  presque les boutons de l'en-tête, et les débordait sous Linux.
- Pourquoi seulement sous Windows et Linux : le texte y est un peu plus large (lettres arrondies au pixel) et la barre de
  défilement prend de la place ; sur Mac ces lignes tenaient au pixel près. Les audits de la CI, qui tournent sous Linux,
  échouaient sur ces deux points depuis la v5.30.
