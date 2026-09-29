# Journal des modifications

## [5.39.4] — 2026-09-29
Deux retours d'usage (A421, doctrine `docs/decisions/lot-v5-39.md`).
- **« Afficher » Aides / Protocoles filtre enfin.** Ouverte par le bouton « Affichage » de la liste, la
  feuille changeait bien de type, puis repeignait aussitôt la liste d'ouverture (« Tout ») par-dessus :
  le choix semblait sans effet. Même chose pour un tri, un regroupement ou une catégorie choisis après
  avoir changé de type. La feuille re-rend désormais la liste du type choisi, quel que soit le bouton qui
  l'a ouverte. Le témoin d'A419 ouvrait la feuille par le bouton rond, le seul chemin sans défaut : un
  second témoin passe par « Affichage », rouge avant le correctif, vert après.
- **L'anneau autour de « Démarrer la session » est plus fluide.** Il animait une ombre, repeinte à chaque
  image pendant l'affichage d'une fiche neuve, d'où les saccades, sur iPhone surtout. C'est maintenant un
  trait de 2 px qui s'éloigne de la capsule par transformation et s'efface en fondu, deux propriétés que
  le processeur graphique compose sans rien repeindre. Il apparaît en fondu au lieu de surgir à pleine
  encre, et s'éloigne d'un seul mouvement, sans temps mort à chaque anneau. Mêmes trois anneaux, même
  départ (800 ms), fini à 4,7 s ; toujours rien sous « réduire les animations ».
- Vérifié : check complet, 1280 tests sous Chromium (WebKit absent de ce poste), audit complet.

## [5.39.3] — 2026-09-28
Outillage d'audit seulement : l'application ne change pas (A420, doctrine `docs/decisions/lot-v5-39.md`).
- **Le rouge WebKit d'A387 n'était pas une fuite.** Sous WebKit, « une session locale sur l'autre aide
  n'émet RIEN sur le fil de l'invité » échouait (2 ou 3 évènements reçus). Mesuré : ce sont des `sig`,
  l'offre et la réponse de négociation du canal direct de secours, que WebKit achève plus tard. Aucune
  coche ni navigation. Le contrôle ne compte plus que les évènements d'état (tout sauf `sig`), avec un
  témoin qui prouve que l'invité a bien lu le fil pendant la fenêtre.
- Vérifié capable d'échouer : la garde d'A387 neutralisée chez l'hôte, le contrôle rougit sur les deux
  moteurs et nomme ce qui fuit (coche, décoche, compteur, minuteur, navigation, démarrage).
- Vérifié : check complet, 1280 tests × 2 moteurs, audit complet après le numéro de version.

## [5.39.2] — 2026-09-28
Outillage d'audit seulement : l'application ne change pas (A420, doctrine `docs/decisions/lot-v5-39.md`).
- **Audit du temps des audits, mesuré.** Toutes les attentes fixes des 22 harnais ont été rejouées
  réduites à deux images, divisées par deux, puis triplées, et les 2 619 contrôles comparés un à un :
  même divisées par deux, 31 contrôles changent. Ces attentes sont donc presque toutes utiles, et aucune
  n'a été raccourcie en masse.
- **pdfsearch : 66 s → 16 s.** Trois attentes testaient `window.attIx`, qui n'existe pas (`attIx` est une
  constante du script), et payaient donc leur plafond entier (60 s) à chaque passe ; l'index est prêt en
  1 à 85 ms. La fenêtre de 10 s dont profitait par accident le témoin « pdf.js pas chargé au démarrage »
  est gardée, explicitement.
- **Tranches équilibrées par durée.** Le lanceur enregistre la durée de chaque section et de chaque
  tâche, et répartit les tranches par durée au lieu du modulo : doctrine 95-168 s → 119-120 s par
  tranche, partage 41-100 s → 58-67 s ; poids d'ordonnancement re-mesurés. Passe complète ~295 → 279 s,
  verdict identique sur les 2 619 contrôles. Sans mesure (CI), rien ne change.
- **Fiabilité de quatre contrôles de partage**, qui dépendaient de la vitesse du harnais : le compteur
  d'A387 est attendu avec la coche ; « le billet mort ne traîne pas » ne dépend plus du vrai serveur ;
  la grammaire des fenêtres se mesure après l'animation d'ouverture ; le rejeu de « continuer seul »
  porte enfin la même heure que l'original. Tous tiennent à attentes divisées par deux et triplées.
- Vérifié : check complet, 1280 tests × 2 moteurs, audit complet après le numéro de version.

## [5.39.1] — 2026-09-28
Deux correctifs signalés à l'usage (A419, doctrine `docs/decisions/lot-v5-39.md`).
- **Connexion.** Appuyer sur Entrée (ou « Envoyer » au clavier du téléphone) dans le champ e-mail envoie
  maintenant le code ; il fallait jusqu'ici toucher le bouton « Recevoir le code ».
- **Filtres de catégorie sur « Toutes ».** Choisir une catégorie (colonne de gauche ou feuille
  « Affichage ») pouvait montrer les aides d'une AUTRE catégorie, et allumer la mauvaise rangée. Cela
  arrivait quand une catégorie avait été renommée dans une bibliothèque alors qu'une autre bibliothèque
  gardait l'ancien nom. Le filtre retient désormais le nom de la catégorie choisie, et suit un
  renommage ou une suppression.

## [5.39.0] — 2026-09-28
Le sommaire d'un PDF joint se consulte comme celui d'un protocole, et reste une option (A418, doctrine
`docs/decisions/lot-v5-39.md`).
- **Sur ordinateur et tablette en paysage (1000 px et plus).** Quand le PDF a des signets, son sommaire
  est une colonne à gauche des pages, avec le numéro de page de chaque titre et la section en cours en
  bleu. Un petit bouton le replie en une icône ≡, qui le rouvre d'un tap ; l'appareil retient le choix.
- **Au téléphone.** Le bouton « Sommaire », sur la ligne du titre, ouvre la liste sous la barre ; elle se
  referme dès qu'on a choisi un titre.
- **On arrive sur le titre, plus en haut de la page.** Un signet ou un renvoi interne du PDF mène
  exactement là où il pointe. Les sauts de la visionneuse (sommaire, liens, occurrences d'une recherche)
  arrivaient aussi environ 60 px trop bas : corrigé.
- **Barre d'outils du téléphone.** Avec un sommaire, elle débordait (« Largeur » coupé, bouton de
  téléchargement hors de l'écran) ; « Sommaire » remonte sur la ligne du titre et tout tient.

## [5.38.2] — 2026-09-28
Le survol bleu pâle devient visible (A417, doctrine `docs/decisions/lot-v5-38.md`).
- **Survol.** Les boutons posés sur le fond bleu pâle (« + » du compteur, « J'ai compris » du bandeau,
  bouton Compte, rangée active de la colonne gauche) changent maintenant nettement de teinte au survol.
  La nuit, ce survol n'était pas visible du tout.
- **Focus.** Le halo autour d'un champ de l'éditeur en cours de saisie est plus lisible ; le bouton
  « Filtrer » actif est un cran plus soutenu.

## [5.38.1] — 2026-09-28
Nettoyage interne des couleurs, sans aucun changement à l'écran (A416, doctrine `docs/decisions/lot-v5-38.md`).
- **Un seul nom par couleur.** Trente-huit anciens noms de couleur (« alias ») gardés depuis la refonte
  v5.6 sont retirés : le code lit désormais partout le nom de référence. Le contrôle automatique des
  tokens refuse qu'un tel doublon réapparaisse.
- **Vérifié identique.** Les styles calculés de 4 714 éléments, sur huit écrans en thème clair, sombre
  et en large, sont les mêmes avant et après.

## [5.38.0] — 2026-09-27
Un audit design de l'application, mesuré puis maquetté sur l'app réelle, et ce qu'il a changé
(A400-A415, doctrine `docs/decisions/lot-v5-38.md`).
- **Lisible à distance.** Les noms de la barre des minuteurs et des touches du bas passent de 11 à
  13,5 px, en casse de phrase sur la barre du bas. Un nom trop long s'abrège tout seul (« Réévaluation
  après adrénaline » devient « Rééval. adrén. », « Bronchospasme réfractaire » devient
  « Bronchospasme ») ; un champ facultatif « Nom court » dans l'éditeur permet de choisir le sien. Les
  mots longs se coupent à la syllabe, avec un tiret, et plus au milieu du mot.
- **Le rouge ne sert plus qu'à ce qui compte.** « Mode crise » n'est plus en rouge, « Fin » garde son
  carré rouge mais son mot passe en gris, la touche de complication et son étiquette passent à
  l'ambre. Dans « Terminer la session ? », l'étape vitale oubliée est maintenant en rouge, avec le mot
  CRITIQUE. La barre d'un minuteur qui tourne est neutre ; il ne prend de couleur qu'à l'échéance.
- **Catégories.** La teinte vermillon, presque identique au rouge d'alerte, quitte le nuancier ;
  « Urgences » passe en prune et quatre teintes proches de l'ambre ou du vert d'alerte glissent un peu.
  Vos catégories existantes gardent leur couleur : « Gérer les catégories » signale celles qui sont trop
  proches d'une couleur d'alerte et propose la teinte voisine d'un tap.
- **Écrans pliables (Surface Duo, Pixel Fold, Galaxy Z Fold).** Rien ne se pose plus sur la charnière :
  la barre des minuteurs, la barre du bas et les fenêtres restent dans le volet gauche. La fenêtre
  « Terminer la session ? » était coupée en deux par la charnière.
- **Mots.** « Journal » devient « Horodater » (le geste reste le même : l'heure est notée d'un tap).
  « ×2 » devient l'étiquette « Double contrôle ». « Vérifier :: » devient « Vérifier ». Les réponses
  attendues s'écrivent en casse de phrase.
- **« Ne pas oublier ».** Le rappel vital de l'arrêt cardiaque s'affichait avec sa syntaxe de saisie
  (« ⚠ RCP immédiate :: 30:2 ») ; il se lit maintenant sur une ligne, CRITIQUE à droite.
- **Avant la session.** La bulle qui masquait le contenu devient une ligne dans le bouton de
  démarrage : « Lance le chrono · minuteurs prêts ».
- **Accueil.** « Créer » n'est plus le bouton le plus visible ; l'étoile d'épinglage et les croix
  répondent au doigt sur 44 px, sans changer de dessin. Sur tablette, la barre des minuteurs ne fait
  plus que la largeur du chrono quand les minuteurs sont dans la colonne de droite.
- **Contraste.** Dans le volet des minuteurs, « Maintenir » et une vingtaine de textes du thème sombre
  étaient sous le seuil de lisibilité ; corrigé. Le contrôle automatique d'accessibilité mesure
  désormais ce volet, calcule juste les fonds semi-transparents empilés, et un nouveau contrôle
  vérifie les écrans pliables.

## [5.37.2] — 2026-09-27
Deux alignements, mesurés (A399, doctrine `docs/decisions/lot-v5-37.md`).
- **Capsule CRITIQUE / VIGILANCE d'une hypothèse** : elle s'aligne exactement sur le début du
  libellé en dessous, à toutes les largeurs et tailles de texte (sur téléphone étroit elle partait
  10 px à gauche du texte).
- **« Repères de ce bloc » replié** : le titre, le résumé (« 2 à préparer ») et les noms des repères
  partent du même bord ; l'icône est dans la même colonne que celle des repères et le compte est sur
  la ligne du titre.

## [5.37.1] — 2026-09-27
Revue et repères du bloc : cinq retours d'usage (A398, doctrine `docs/decisions/lot-v5-37.md`).
- **La revue des causes réversibles se partage entre les blocs.** Cochée dans « Choquable », elle
  est retrouvée telle quelle dans « Non choquable » : c'est UNE revue pour toute la session, quel
  que soit le bloc qui la pose, et elle ne repart plus de zéro à chaque tour de boucle. « Nouvelle
  revue » la remet à zéro. Une session en cours reprise après la mise à jour garde ses coches.
- **Hypothèses « critique » ou « vigilance » lisibles.** L'étiquette se posait sur le libellé de
  l'hypothèse ; elle se place au-dessus. L'étape-revue elle-même avait sa case AU-DESSUS du texte,
  des hypothèses grisées et rapetissées (un nom de classe déjà pris par la liste « à relire ») :
  corrigé.
- **Pas de CRITIQUE / VIGILANCE avant le moment d'une étape.** Une étape qui attend son moment
  (en pointillé, sans case) n'affiche que sa règle ; le mot revient avec la case.
- **Repères de ce bloc.** Un repère dont l'étape n'a pas encore atteint son moment est « à
  préparer », plus « à faire » ; faite à un passage précédent (« une seule fois »), « fait ». Chaque
  repère se lit en deux lignes — nom et état en tête, posologie dessous sur toute la largeur — et le
  nom ne se coupe plus au milieu du mot sur téléphone ; sous 430 px, l'état passe sous le nom. Bande
  repliée : le résumé (« 2 à préparer ») passe sous le titre au téléphone au lieu de s'écraser à côté.
- **Icône des repères** : la gélule a une moitié pleine — elle se lisait comme un maillon de chaîne.

## [5.37.0] — 2026-09-27
La revue « à tout moment » et la bande des repères du bloc (A396-A397, doctrine `docs/decisions/lot-v5-37.md`).
- **Revue « à tout moment ».** Une question que l'équipe se pose pendant tout le soin — les causes
  réversibles (4H / 4T) de l'arrêt cardiaque — devient une liste d'hypothèses cochable. Elle se pose
  dans le fil comme une étape, dans chaque bloc où l'on doit y penser, avec le nom de la revue ; un
  toucher sur la rangée déplie les hypothèses dans sa boîte, chacune se coche sur place, la revue est
  faite d'elle-même quand toutes sont cochées et ne retient jamais « Continuer ». À chaque passage
  de la boucle, tout est à recocher ; « Nouvelle revue » remet la revue courante à zéro. Elle reste
  ouvrable à tout moment sous le bloc, sous le même nom, et se lit dans la colonne « À tout moment »
  du parcours et dans la Page. Les coches voyagent par le partage comme celles des étapes.
- **Repères de ce bloc.** Un repère posologique peut être lié à une étape (Réglages de l'étape ›
  « Repère posologique »). En session, les repères des étapes du bloc forment une bande au pied du
  bloc, dans l'ordre des étapes, avec un mot venu de la coche : fait · à faire · à préparer — pendant
  l'adrénaline, l'amiodarone est déjà lisible. La bande se replie d'un toucher (un seul état pour la
  session, la tête repliée garde le compte et le résumé) ; un toucher sur une ligne ouvre le détail
  du repère (préparation, dilution, administration), que l'éditeur écrit sous la ligne du repère.
  Les rangées d'étapes ne changent pas : la boîte grise entière reste la coche.
- **Éditeur.** Porte « Revue » de la palette ; carte propre pour chaque revue (titre, hypothèses avec
  leur indice, réglages) ; sections « Revue » et « Repère posologique » dans la feuille Réglages d'une
  étape ; détail sous chaque repère posologique.
- **Icônes.** Le glyphe ℞ est remplacé par une pilule dessinée comme les autres icônes ; la revue
  porte une grille.
- **Fiches d'exemple** : dans l'ACR, la revue des causes réversibles est posée dans les deux blocs
  de la boucle et l'adrénaline comme l'amiodarone sont liées à leur repère ; dans l'anaphylaxie,
  l'adrénaline IM et le remplissage le sont aussi.
- **Génération par IA** : bloc `review` et renvoi `review` d'un item (règle 19) ; un repère peut
  s'écrire en objet avec un `id` et une `note`, et chaque étape qui dose un produit y renvoie par
  `poso` (règle 20).

## [5.36.0] — 2026-09-27
Imprimer la Page sans surprise, exporter une sélection, les liens des PDF, et des branches qui se lisent comme des branches (A392-A395, doctrine `docs/decisions/lot-v5-36.md`).
- **Impression de la Page.** Sans l'option « imprimer les arrière-plans », les traits du tronc et des
  fourches disparaissaient, et les numéros de bloc aussi : ils s'impriment désormais dans tous les cas
  (traits en bordures, numéros encadrés). Les voies pointillées ne sont plus décalées d'une page ni
  « rallongées », quels que soient les en-têtes, pieds de page et marges ; la page blanche en fin de
  document et la page blanche au bureau (1280 px) ont disparu.
- **Le PDF enregistré porte le nom de l'aide** (ou du protocole), et non plus « Aides cognitives ».
- **Mode Page** : les cartes « À vérifier » et « Diagnostics » sous la feuille redisaient la Page ;
  seule « Références » reste.
- **Page : les jalons se lisent comme les réponses.** Dans une décision, le jalon vient après les
  réponses, sur une ligne « SI Chocs délivrés ≥ 3 : … ……… [⚡ FV réfractaire] », en gris ; les en-têtes
  de groupe d'étapes prennent le même « SI ». Le jalon ne coupe plus la question de ses réponses.
- **Parcours : « Branche » au lieu de « Chemin 2 ».** Une suite qui ne découle pas du bloc précédent
  s'annonce « Branche ◇ 2 « Non » » (la décision et sa réponse, un toucher y mène) ; ses blocs sont
  décalés d'un cran le long d'un trait gris. « ■ Fin » remplace « Fin du parcours ». La bulle ne touche
  plus le bord de la colonne.
- **Parcours : le chiffre des losanges est centré.**
- **« ✓ faite — plus à refaire »** : en mode guidé, une étape « une seule fois » déjà cochée le dit
  dans le parcours, la Page et le Schéma (jamais sur papier).
- **Exporter plusieurs aides ou protocoles d'un coup** : en mode Sélection, « Exporter… » produit un
  seul fichier, réimportable tel quel (avec les documents joints au choix).
- **PDF joints : liens cliquables et sommaire.** Les liens web (http, https, mailto, tel) s'ouvrent dans
  un nouvel onglet, les renvois internes mènent à leur page, et un bouton « Sommaire » apparaît quand
  le document a des signets.

## [5.35.0] — 2026-09-26
L'accueil en une colonne, l'éditeur plus navigable, un aperçu fidèle, et une Page et un Schéma lisibles (A389-A391, doctrine `docs/decisions/lot-v5-35.md`).
- **Accueil (tablette, bureau) : une seule colonne.** La grille de 2 ou 3 colonnes coupait les
  informations sous les titres ; la liste tient désormais en une colonne. « Détaillée » affiche une
  carte par aide ; « Compacte » tient sur une ligne au bureau (titre à gauche, informations à droite).
  Les deux réglages rendaient la même chose au-delà de 780 px : c'est corrigé.
- **Bibliothèques** : dans la colonne de gauche, le crayon et « Nouvelle bibliothèque » laissent place à
  un « Gérer » qui ouvre « Moi » à la section Bibliothèques.
- **« Tout voir »** perd l'onglet « Parcours », qui redisait « Se repérer » : il reste Page et Schéma.
- **Éditeur (tablette, téléphone) : la Structure revient.** Une carte « Structure · n blocs » reste collée
  sous l'en-tête, fermée par défaut ; toucher un bloc la referme et amène le bloc à l'écran.
- **« Essayer » montre la vraie page** : cartes, parcours, quai (Démarrer l'essai, Fin, Tout voir, ⚡,
  Journal) et minuteurs, comme en session. « Fin » rejoue l'essai depuis le début. Rien n'est enregistré,
  et ouvrir ou replier une carte dans l'aperçu ne change plus l'aide elle-même.
- **Page (Tableau) : des traits qui se rejoignent.** Le tronc touche enfin la pilule « revenir à… » ; un
  renvoi vers une branche de fourche rejoint la barre de la fourche (une seule pointe) ; un retour part
  du bas de sa pilule et ne croise plus rien ; la pointe d'un retour arrive par un vrai trait ; les
  tracés ne sont plus décalés quand la fenêtre s'ouvre.
- **Page et Schéma : les conditions en toutes lettres**, comme dans le parcours : « Si Chocs délivrés ≥ 3 : »
  en tête des étapes concernées, puis « · toutes les 4 min », « · si pas déjà faite », « · +1 Chocs délivrés ».
  Le jalon se lit « Si … : … » ; les durées et les noms entre guillemets ne se coupent plus en fin de ligne.

## [5.34.0] — 2026-09-26
Le parcours se lit d'un coup d'œil : dans la colonne, dans la carte « Parcours » et dans la feuille « Se repérer » (A388, doctrine `docs/decisions/lot-v5-34.md`).
- **Colonne repliée par défaut.** À gauche du bureau (dès 1200 px) et dans le rail de droite, le
  parcours ne montre plus que les titres, avant comme pendant la session. Un bloc se déplie d'un
  toucher sur son titre, « Tout déplier » ouvre tout. Une décision repliée garde ses réponses sur
  une ligne (« Oui ↓ 3 · Non → 4 »), et en session la réponse choisie porte ✓. Le bloc en cours dit
  « Ici ». Texte un cran plus petit (13,5 px) : la liste de l'arrêt cardiaque passe de 1 540 à 510 px.
- **Même geste partout.** La carte « Parcours » et la feuille « Se repérer » ont les mêmes chevrons,
  mais restent dépliées à l'ouverture. Replier ne fait pas sauter la page et ne ferme pas la feuille.
- **Les conditions de cochage en toutes lettres.** Les étapes qui ne se font qu'à partir d'un seuil
  sont regroupées sous « **Si** Chocs délivrés ≥ 3 : ». Le reste suit l'étape en gris : « si pas déjà
  faite », « toutes les 4 min », « au besoin », « +1 Chocs délivrés », « relance « Réévaluation » (5 min) ».
  Les étiquettes en capitales et les légendes à icône disparaissent du parcours.
- **Boucles, jalons et complications.** « ↺ retour à 2 · toutes les 2 min » ; un jalon se lit
  « Si Chocs délivrés ≥ 3 : … » avec un renvoi ⚡ vers sa complication ; les complications sont
  listées en fin de parcours, sous « À tout moment ».
- **Critique et Vigilance** : dans le parcours, le mot en couleur, sans fond, se place à droite de la
  première ligne. Le texte de l'étape ne se décale plus. La carte de session ne change pas.
- **Réponse attendue** : elle suit l'étape après un tiret, dans le texte (plus de police à chasse fixe
  bleue). Le titre de la colonne devient « Parcours » (au lieu de « Parcours inerte »), et Tableau ·
  Schéma tiennent sur une ligne.

## [5.33.2] — 2026-09-26
Deux bugs du partage de session côté invité (A385) et leur pendant côté hôte (A387), puis deux bugs d'affichage au téléphone (A386) — doctrine `docs/decisions/lot-v5-33.md`.
- **Connexion coupée : l'invité peut continuer.** Quand le lien se figeait (plus de réponse depuis
  quelques secondes), ses coches, compteurs et minuteurs étaient refusés et grisés. Ils sont
  désormais gardés sur l'appareil et partent au retour du réseau, comme ceux de l'hôte — le quai
  dit toujours « figé ». « Recevoir » par l'écran ne les efface pas.
- **Sa propre session reste la sienne.** Un invité qui rouvrait la même aide sur son profil et y
  lançait une session ou un exercice voyait les gestes de l'hôte s'y inscrire : elle devenait la
  session partagée. Les gestes de l'hôte ne vont plus qu'à la session partagée, et « Revenir à la
  session partagée » les montre tous. Une bascule automatique en direct ne l'arrache plus à sa session.
- **« Démarrer » et « Exercice » s'affichent** au quai sur les aides de l'invité (appareil qui lui
  appartient) ; ils n'étaient accessibles que par le menu ⋯.
- **Corriger une heure du journal (téléphone)** : le volet ne se referme plus au premier toucher, le
  champ et les raccourcis « −1/−2/−5 min » restent au-dessus du clavier, et après validation le dock
  du bas revient — il restait masqué et faisait sauter le contenu (A386).
- **Téléphone en paysage** : la colonne de droite (minuteurs, compteurs, journal) n'est plus coupée —
  elle défile avec la page au lieu d'une petite zone de 110 px (A386).
- **L'hôte peut consulter une autre aide pendant un partage** : les gestes de l'invité continuent
  d'arriver dans la session partagée (ils tombaient dans l'aide affichée et se perdaient), et une
  session ouverte sur l'autre aide n'envoie plus rien à l'invité (A387).

## [5.33.1] — 2026-09-26
Retours d'usage sur l'éditeur allégé de la v5.33 (A384, doctrine `docs/decisions/lot-v5-33.md`).
- **La réponse attendue vide se laisse cliquer** : toucher le champ repliait l'étape et le clic
  tombait sur l'étape suivante. La rangée reste désormais ouverte tant que le focus reste en elle.
- **Des champs d'une seule taille** : titre d'étape, réponse attendue, question d'une décision,
  réponses et blocs cibles prennent le gabarit des listes « Condition d'entrée » (15 px, environ
  40 px de haut ; 16 px sur écran tactile, contre le zoom d'iOS). Au repos, la réponse reste serrée
  sous le titre ; elle s'arrête avant le bouton « Réglages », qui ne touche plus le filet du dessus.
- **Un seul dessin pour les boutons d'outil de l'éditeur**, blanc comme les autres boutons : croix de
  suppression (rappels, listes, réponses, minuteurs, compteurs, jalons, complications, documents),
  gras **B**, **△** du repère à vérifier (fond ambre quand il est posé), → vers le bloc d'un rappel.
  Les anciennes cases blanches bordées et le pavé gris disparaissent.
- **Complications** : la croix ne chevauche plus la cible ; le champ « Événement » et la cible
  prennent le gabarit des autres champs.
- **Toutes les pastilles se glissent au doigt**, « Importance » comprise : le glisser est posé une
  fois pour toute l'app, un nouveau sélecteur n'a plus rien à câbler.
- **Feuille de réglages** : « ×2 Confirmée par les deux » dit ce qu'elle fait (« en session, marquée
  ×2 : les deux soignants la vérifient à voix haute ») ; le libellé de « Continuer » est dit
  facultatif ; de l'air sous « Importance ».


## [5.33.0] — 2026-09-26
L'éditeur s'allège : on écrit d'abord, on règle ensuite, jamais à plus d'un toucher (A383, doctrine
`docs/decisions/lot-v5-33.md`). Demande de l'auteur après audit mesuré (ACR, 390 px : une étape
touchée passait de 70 à plus de 500 px, onze commandes) ; maquettes E1-E7 et captures validées.
- **Écrire n'ouvre plus rien** : toucher le texte d'une étape n'allume que ses champs. Un bouton
  « Réglages » au bout de la ligne ouvre une feuille (basse au téléphone, centrée dès 780) à trois
  sections nommées : importance (Normale · Vigilance · Critique, Mémoire, ×2), ce que fait la coche,
  moment (« Dès le 1ᵉʳ passage / À partir d'un compte », seuil −/+, « Puis revient » en quatre cases).
  Sans minuteur ni compteur, « ＋ Créer un minuteur / un compteur » les crée et les lie sur place.
- **Ce qui est réglé se lit au repos**, en pastilles sous l'étape : Critique, Vigilance, ★ Mémoire,
  ×2, « lance … », « +1 … », « Chocs délivrés ≥ 3 », « à l'échéance ». La réponse attendue passe sous
  le texte ; les étapes sont plus compactes (≈ −20 %).
- **Ce qui ne peut servir à rien n'est plus montré** : le moment, le minuteur du bloc et les jalons
  n'apparaissent que si le bloc se répète (« ↺ Se répète ») ou s'ils sont déjà posés.
- **« Options du bloc »** en carte dépliable, résumé à droite, ouverte d'office quand une option est
  posée : bloc de départ, phase (qui quitte l'en-tête), libellé de « Continuer », minuteur du bloc,
  jalons, image. Un jalon se lit comme une phrase : « Chocs délivrés ≥ − 3 + ». Les règles d'usage
  ne sont plus répétées à chaque bloc.
- Témoins : section A383 d'`audit-doctrine`, `audit-k5` et `audit-a11y` (la feuille est mesurée).

## [5.32.0] — 2026-09-26
Une étape peut dire QUAND elle se présente dans un bloc parcouru plusieurs fois (A382, doctrine
`docs/decisions/lot-v5-32.md`). Demande de l'auteur, sur maquettes revues fil par fil : au 1ᵉʳ choc,
il fallait cocher l'adrénaline « après le 3ᵉ choc » pour pouvoir avancer.
- **Commence** : dès le 1ᵉʳ passage, ou quand un compteur atteint un seuil (« Chocs délivrés ≥ 3 »).
  **Puis revient** : à chaque passage, à l'échéance du minuteur que relance sa coche, une seule
  fois, ou au besoin.
- **Avant son moment**, l'étape reste visible, en pointillé et sans case, avec sa règle au-dessus
  et ce qui manque dessous (pastilles · « encore 2 », ou le minuteur qui court). « Continuer » ne
  l'attend pas. « Faire maintenant » la coche quand même, en un toucher.
- **Quand le moment vient**, la case revient sur place, à la même hauteur, sans défilement ni
  alerte : « ✓ Chocs délivrés ≥ 3 », ou « Échu » en ambre. Rien ne repart seul.
- **Une seule fois** : une fois faite, « Faite », plus de case. **Au besoin** : cochable, jamais
  attendue.
- **Éditeur** : « Commence » et « Puis » dans les outils de l'étape, réglés sur place. « À
  l'échéance » reste grisé avec sa raison quand la coche ne relance aucun minuteur. Si le minuteur
  disparaît, l'étape redevient « à chaque passage » et l'éditeur le signale.
- **Parcours à plat et Page** annoncent la règle sous l'étape.
- **Prompt IA** : il sait poser ces moments (seulement quand la source les énonce), écrire deux
  doses comme deux étapes, et ne plus laisser le seuil dans le libellé.
- **Fiches d'exemple** : dans l'**ACR**, l'adrénaline commence au 3ᵉ choc puis revient à
  l'échéance de « prochaine dose », l'amiodarone 300 mg (3ᵉ choc) et 150 mg (5ᵉ) ne se font qu'une
  fois ; dans l'**Anaphylaxie**, l'adrénaline IM du bloc réfractaire revient à l'échéance de la
  réévaluation.
- Réglementaire : § 2 « Le cas du moment d'une étape » (règle de l'auteur appliquée à un compte ou
  un minuteur de l'équipe, régime des jalons).

## [5.31.1] — 2026-09-25
Quatre retouches signalées à l'usage (A381, doctrine `docs/decisions/lot-v5-31.md`).
- **Notice « Vous êtes l'auteur… »** : la croix dépassait d'une notice d'une ligne (posée 4 px sous
  le haut, 32 px de haut pour une notice de 34). Elle se centre désormais sur la première ligne.
- **Recherche de l'accueil** : 16 px au téléphone au lieu de 17,5, en accord avec le reste de
  l'accueil. 16 px est le plancher d'iOS : en dessous, Safari zoome au toucher. 15 px sans écran
  tactile.
- **Cases des étapes CRITIQUE / VIGILANCE** : l'étiquette se loge dans une marge haute réservée,
  hors du flux. La case reste centrée sur le libellé, au même endroit que dans une rangée sans
  étiquette (elle était centrée sur l'ensemble étiquette + libellé + détail, donc visiblement
  plus basse).
- **Colonne « Parcours inerte » du bureau** (et rail 780-1199) : chaque bloc se plie à son titre,
  seul le bloc courant est déplié d'office. Une décision reste ouverte, puisque ses branches
  sont le chemin. Un chevron par bloc, au clavier comme au toucher. Le
  parcours de l'ACR tient désormais en entier à l'écran. Toucher un bloc de cette colonne ne
  faisait plus rien depuis la v5.30.6 (bascule orpheline) : ce geste revit ici.

## [5.31.0] — 2026-09-25
La coche d'une étape peut lancer un minuteur ou compter, un bloc peut porter son minuteur, et une
ligne discrète le dit sous l'étape (A377 à A380, doctrine `docs/decisions/lot-v5-31.md`). Demande de
l'auteur, choisie sur trois versions de maquettes ; puis des micro-mouvements logiques, la règle
« ne pas anticiper » et deux essais d'affichage à juger en conditions réelles.
- **La coche lance** (`starts` sur une étape) : cocher « Adrénaline 1 mg IV » lance « Adrénaline —
  prochaine dose » depuis zéro. **La coche compte** (`counts`) : cocher « Choc » ajoute 1 au
  compteur et pose l'heure au journal, comme le « + » de la carte.
- **Le bloc minute** (`timer` sur un bloc) : le minuteur repart à chaque entrée dans le bloc
  (Continuer, réponse, nouveau passage) ; au bloc où la session démarre, avec elle. Il s'arrête
  quand le parcours quitte la boucle. À l'échéance, rien n'est choisi et rien ne défile.
- **Tout se défait par la case** : décocher retire le + 1 et barre le repère ; décocher dans les
  10 s rend le minuteur à son état d'avant. Après, il continue et s'arrête depuis sa tuile.
- **Une légende d'une ligne** sous l'étape liée et sous le titre du bloc : 24 px réservés dans tous
  les états, la valeur d'abord (celle de la tuile), gris au repos, bleu sans fond quand ça tourne,
  pastille ambre pâle avec « Échu » à l'échéance. Aucune hauteur ne change sans geste. Annoncée sans
  état dans le parcours à plat, la Page et l'éditeur.
- **Éditeur** : « Ce que fait la coche » dans les outils d'une étape, « Minuteur du bloc » sous le
  bloc ; rien n'est proposé si la fiche n'a ni minuteur ni compteur.
- **Prompt IA de création** : nouvelle section « Minuteurs et compteurs liés », 0 à 3 liens par
  fiche et 0 ou 1 minuteur de bloc, seulement quand la source lie le geste au délai ou au compte ;
  vérification finale n° 17.
- **Fiches d'exemple** (proposées au premier lancement) : dans l'**ACR**, cocher « Choc immédiat »
  compte le choc, et cocher l'une des deux « Adrénaline » lance « prochaine dose ». Dans
  l'**Anaphylaxie**, les deux injections IM comptent sur « Adrénaline IM », et ce compteur relance
  la réévaluation à 5 min. Elle ne repart plus seule à la sonnerie (A379) : entre la sonnerie et
  l'injection, 30 s d'analyse ou un choc peuvent passer. Elle reste « Échu » jusqu'à la coche
  suivante. Le prompt IA gagne la règle « ne pas anticiper ». Pas de minuteur de bloc dans les exemples : aucune des deux fiches n'a
  de tentative bornée par passage. « — noter l’heure » disparaît de l’adrénaline IM : la coche
  pose désormais l’heure au journal.
- **Micro-mouvements** (A378), chacun répondant à un geste : cocher fait monter le chiffre ou
  remplir l'anneau (minuteur relancé depuis zéro), décocher fait redescendre la valeur, une jauge
  discrète se vide pendant les 10 s d'annulation, l'échéance se pose en fondu. Dans l'éditeur, la
  légende apparaît sous l'étape dès que le lien est choisi. Rien ne boucle, rien ne change de
  hauteur, et rien ne bouge en mouvement réduit.
- **Éditeur** : un minuteur d'intervalle neuf ne repart plus seul par défaut (A379) ; reboucler se
  coche. Le cycle RCP de l'ACR, lui, reste à cycles (décision de l'auteur).
- **Deux essais d'affichage à juger en conditions réelles** (A380), dans Moi › Affichage, sur
  l'appareil seulement, éteints par défaut :
  - **Capsule « horizon »** : les minuteurs en cours posés sur un axe de 5 min, à leur temps
    restant. Rien n'est extrapolé : ni cycle suivant, ni échéance future ; l'échu se pose sur
    « maintenant ».
  - **Instruments en bande** : dès la tablette, la capsule porte les minuteurs et les compteurs
    comme au téléphone et ouvre le volet des corrections ; la colonne de droite garde le journal
    et les repères posologiques.
- **Conformité** : § 2 de `docs/deploiement-et-conformite.md` complété avant le code (déclencheur
  toujours un geste de l'équipe, rien ne décide, tout se défait).
- **Sans doublon** : une seule fonction pour relancer un minuteur (quatre copies auparavant ; le ⟲
  d'un minuteur ad hoc et la relance par un compteur lèvent désormais aussi l'acquittement), une
  pour le « + » d'un compteur, une pour le nom par défaut d'un minuteur (sept copies) ; le parcours
  du graphe des blocs est partagé avec le grisé « hors chemin » ; glyphes pris dans la table
  d'icônes commune ; commentaires ramenés à une ligne, la doctrine vit dans le lot.
- **Témoins** : 33 tests unitaires (modèle, sortie de boucle, légende) et une section
  `audit-doctrine` « A377 » (25 contrôles, dont la fiche d'exemple Anaphylaxie, les mouvements et la sonnerie) et une section « A380 » (10 contrôles, les deux essais). Aucun changement côté serveur.
