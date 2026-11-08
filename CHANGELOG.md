# Journal des modifications

## [5.111.0] — 2026-11-08
Connecter un ordinateur de service avec son téléphone (A643-A647). **Côté serveur : rejouer `supabase/schema.sql`, puis déployer la fonction `link-claim`** (`supabase functions deploy link-claim --no-verify-jwt`, cf. `docs/deploiement-et-conformite.md` § 1.2).
- **Sur l'ordinateur** (Moi › « Se connecter avec le téléphone ») : un QR et un nombre de contrôle, ni e-mail ni code
  à recopier. **Sur le téléphone** (Moi › Appareils › « Connecter un ordinateur ») : viser le QR (ou l'ouvrir avec
  l'appareil photo), toucher le nombre que montre l'écran, choisir l'heure de fin de garde, « Connecter ». L'ordinateur
  reçoit sa propre session, jamais celle du téléphone.
- **Des heures de fin de garde, pas des durées** : deux repères, 10:00 et 19:30 par défaut, réglables dans « Mes fins
  de garde » ; trois choix au plus, entre 1 h et 28 h (une garde de 24 h qui déborde passe).
- **Le poste partagé ne perd rien** : fermer le navigateur, perdre le réseau ou redémarrer ne fait rien perdre, et une
  session en cours se reprend. À l'heure de fin, il s'efface — jamais pendant une session, jamais avant que les
  sessions faites dessus aient rejoint l'historique (jusqu'à 7 jours après, même sans connexion au compte).
- **Une session en cours sur un poste partagé est sauvegardée en ligne toutes les 2 minutes** (s'il y a eu un geste) :
  si l'ordinateur ou le réseau lâche, l'historique la montre « △ Interrompue », compte rendu partiel ; la session
  terminée la remplace.
- **Appareils connectés** (téléphone) : voir les postes, les prolonger d'une heure, les déconnecter à distance.
- **Navigateur rouvert sur le poste** : consulter et reprendre restent libres ; créer, modifier et gérer redemandent
  le téléphone.
- **Caméra** : `_headers` passe à `camera=(self)` — le viseur (partage de session, connexion) marche aussi sous Chrome
  (Android, ordinateur), qui appliquait l'interdiction.
- **Ce qu'un poste partagé ne fait pas** (A647) : supprimer demande le téléphone à chaque fois ; l'administration
  (instance, membres, bibliothèques) et « Remplacer » à l'import y sont refusés ; « Supprimer mon compte » n'y apparaît
  pas ; les réglages valent pour ce poste seulement ; 15 minutes sans geste reverrouillent la modification
  (jamais une session) ; un fichier exporté y est signalé comme restant sur l'ordinateur.
- **Sécurité, revue avant publication** : deux secrets (le QR ne sert qu'au téléphone, une clé jamais affichée sert au
  poste), session du poste créée et liée par le serveur, une session de poste ne peut ni approuver ni prolonger un
  poste ni supprimer le compte, dépôt de sessions durci, plafond de demandes par machine. Un lien de connexion reçu par
  message mène au viseur, jamais droit à l'approbation ; après l'approbation, « Rien ne s'ouvre devant vous ?
  Déconnecter ». Recommandé : `APP_ORIGIN` sur la fonction, un « Password Verification Hook », des jetons plus courts.
- À savoir : sans la fonction serveur déployée, la connexion par le téléphone échoue proprement et l'e-mail reste là.

## [5.110.0] — 2026-11-08
Une image dans une liste reste dans son élément (A642). Rien à rejouer côté serveur.
- **Image dans un élément de liste** (import Notion surtout) : l'image indentée sous un élément s'affiche sous son
  texte, à sa largeur (300 px au plus), et la liste continue — la numérotation ne repart plus à 1 après l'image.
- **L'import Notion garde la place de l'image** sous l'élément qu'elle illustre.
- **Éditeur de protocole** : sur une liste qui porte une image, « Sortir l'image de la liste » la remet en bloc
  pleine largeur après la liste.
- L'image d'un élément compte comme utilisée : elle n'est plus retirée en quittant l'éditeur.
- À savoir : un appareil resté sur une version antérieure affiche cette ligne image en texte brut tant qu'il ne
  s'est pas mis à jour.

## [5.109.9] — 2026-11-08
Plus aucune fenêtre centrée pour choisir une aide, un protocole ou un document (A641). Rien à rejouer côté serveur.
- **« Voir aussi », la cible d'une complication et « Joindre un document existant »** s'ouvrent comme les autres
  choix de l'app : au bureau, une liste qui se déroule sous le bouton touché ; au téléphone, la feuille du bas.
- **Recherche dans les trois, dès le premier élément** (nom, code d'une aide, provenance d'un document) ; les groupes
  restent (« Aides » / « Protocoles », « Blocs de cette aide » d'abord pour une complication, la cible actuelle cochée).
- Rien à choisir : une notice le dit, au lieu d'ouvrir une fenêtre vide.

## [5.109.8] — 2026-11-08
Éditeur de protocole : le suivi ne disparaît plus (A636) ; mise en garde des images (A637), déroulants au bureau (A638), gras de Notion (A639), listes coupées par une image (A640). Rien à rejouer côté serveur.
- **Le volet « Suivi » de l'éditeur de protocole reste visible** : il disparaissait de la colonne de droite dès qu'on
  tapait dans le texte, et après un aller-retour « Mise en forme en direct ».
- **Texte et aperçu côte à côte** : le suivi reste en bas de page, et la pastille « n tâches » paraît dans l'en-tête
  dès qu'il y a une note ou une tâche (elle l'ouvre sans quitter sa place), comme en lecture.
- **« Une image hors texte sera retirée… »** ne s'affiche plus que s'il y a vraiment une image retirée du texte.
- **Au bureau, plus de petites fenêtres pour choisir** dans l'atelier d'import (catégorie, bibliothèque, « Dans »),
  pour l'élément lié d'une tâche, « Ajouter à une collection… » et l'Administration : une liste se déroule sous le
  bouton touché. Au téléphone, rien ne change.
- **Gras de Notion** : `****texte****` et `****titre** : suite**` s'affichent en gras.
- **Image dans une liste (import Notion)** : l'image reste un bloc à elle et ferme la liste, mais ce qui la suit
  redevient une liste au lieu de s'afficher en texte « - … ».

## [5.109.7] — 2026-11-08
Atelier d'import (A622), cases rondes et vocabulaire (A623), tâches liées (A624), échéances (A625), recherche (A626), « À faire » et menus au bureau (A627-A631), « Créer » aux Bibliothèques (A632), page Notion dans l'éditeur (A633), sélection de blocs et « Modifier » (A634-A635). Rien à rejouer côté serveur.
- **Renommer à l'import : on touche le titre** (export ZIP ou page .md de Notion). Le bouton « Renommer » de chaque
  rangée disparaît : le titre se présente comme un champ de texte (encadré gris léger, comme sur iOS), lisible en entier. Toucher le titre
  ne coche ni ne décoche la rangée ; Entrée valide, Échap annule.
- **Les cases à cocher sont rondes partout** : celles de l'atelier d'import et des fenêtres de confirmation étaient
  restées carrées.
- **« Protocole » partout** : les derniers « référence » qui désignaient un protocole (suivi, import, relecture, images)
  sont renommés ; « Références » ne désigne plus que la bibliographie.
- **Tâches « À fusionner avec » / « À confronter à »** : l'aide ou le protocole lié se choisit dans la feuille de choix
  de l'app (au téléphone, la feuille du bas ; sur ordinateur, une liste qui se déroule sous le champ ; aides et
  protocoles séparés, recherche dès 8 éléments) ; et la tâche paraît
  maintenant AUSSI dans le suivi de l'élément visé (« Liées depuis d'autres éléments »), où l'on peut la cocher.
- **Échéance passée** : une tâche en retard le dit (« △ en retard depuis le 15/11 », en ambre) et remonte en tête de sa
  priorité ; « À faire » et le catalogue le signalent aussi. Pas de notification ni d'alerte.
- **Toute fenêtre où l'on choisit une aide ou un protocole a son champ « Rechercher… »**, même avec peu d'éléments :
  tâche liée, « Ajouter » d'une collection, « Voir aussi », « Dans » de l'atelier d'import.
- **« À faire » s'ouvre en page** sur tablette et ordinateur (comme Sessions et Moi), et chaque tâche a un
  « Ouvrir › » qui mène à son aide ou à son protocole.
- **Au bureau, les menus de la barre de sélection s'ouvrent au-dessus d'elle**, et « Ajouter » d'une collection sous
  son bouton, au lieu d'un panneau en bas de l'écran. Au téléphone, rien ne change.
- **Catalogue** : « △ n à relire » ne passe plus sur le nom d'une catégorie ; une liste qui s'ouvre dans une fenêtre
  n'est plus coupée sur un écran peu haut.
- **« Créer » dans l'onglet Bibliothèques** ; créé depuis une bibliothèque, l'élément y est rangé d'office.
- **Une page Notion (.md ou .zip) s'ajoute au protocole ouvert** : déposez-la dans l'éditeur, ou « Ajouter › Page
  Notion ». Le texte va à la suite (↶ l'annule), les images suivent, le titre est repris s'il était vide.
- **Sélection de blocs à la souris** : un glisser parti du texte sélectionne du texte ; un glisser parti de la marge
  trace un cadre qui prend les blocs ; un clic ailleurs désélectionne ; « Ajouter » s'efface pendant la sélection.
- **« Modifier » s'ouvre tout de suite**, sans attendre le serveur (la vérification des droits se fait en arrière-plan).

## [5.109.6] — 2026-11-08
Sous-ligne des rangées (A621). Rien à rejouer côté serveur.
- **Le « · » ne commence plus une ligne** : quand la ligne de détails d'une aide passe à la ligne (« △ À relire »,
  pastille « Cours DESMU »…), le point reste au bout de la ligne précédente et la suivante commence au mot, sans
  décalage.

## [5.109.5] — 2026-11-08
Alignement des rangées sans catégorie (A620). Rien à rejouer côté serveur.
- **Une aide ou une référence sans catégorie ne décale plus son texte** : dans une liste où les autres rangées ont un
  point de couleur (« Ouvertes récemment », une collection…), elle garde la place du point, vide, et son titre
  s'aligne sur celui des voisines. Une liste sans aucune catégorie reste inchangée.

## [5.109.4] — 2026-11-08
Sélection depuis l'accueil (A619). Rien à rejouer côté serveur.
- **Un appui long sur une aide de l'accueil sélectionne sur place** : depuis une collection, « Ouvertes récemment » ou
  l'Accès direct, l'accueil ne bascule plus sur la liste complète des aides (la rangée pressée partait ailleurs et la
  page sautait). Chaque rangée prend sa case ; une aide présente à deux endroits est cochée aux deux ; « Annuler »
  rend l'accueil tel qu'il était.

## [5.109.3] — 2026-11-08
Barre de sélection en bas sur tablette et ordinateur (A618). Rien à rejouer côté serveur.
- **La barre sombre de la sélection descend aussi en large** : sur tablette et ordinateur, quand on coche des éléments
  dans la liste (accueil ou catalogue « Tout »), elle ne reste plus collée en haut de la liste ; elle flotte en bas
  de la colonne principale, comme le dock du téléphone (même hauteur, même pilule, 24 px du bas). La case « Tout
  cocher » et la croix restent sur la ligne ; la liste garde de la place en bas pour que la dernière rangée reste
  atteignable.

## [5.109.2] — 2026-11-08
Retour depuis une collection (A617). Rien à rejouer côté serveur.
- **Une collection ouverte depuis l'accueil a son bouton « ‹ Accueil »**, en haut à gauche (un simple « ‹ » sur les
  petits écrans).
- **Le geste retour du téléphone y ramène aussi à l'accueil** — il faisait quitter l'application.

## [5.109.1] — 2026-11-08
Correctif du suivi (A616). Rien à rejouer côté serveur.
- **Ouverte depuis la feuille « Suivi » ou depuis « À faire », la fenêtre d'une note ou d'une tâche s'affiche
  désormais par-dessus** : elle se ferme normalement et se rouvre. Avant, elle restait cachée dessous, et « ＋ Tâche »
  ne rouvrait plus rien.

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
