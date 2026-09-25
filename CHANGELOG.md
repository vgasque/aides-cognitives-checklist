# Journal des modifications

## [5.31.0] — 2026-09-25
La coche d'une étape peut lancer un minuteur ou compter, un bloc peut porter son minuteur, et une
ligne discrète le dit sous l'étape (A377, doctrine `docs/decisions/lot-v5-31.md`). Demande de
l'auteur, choisie sur trois versions de maquettes.
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

## [5.30.6] — 2026-09-25
Huit retouches de cohérence listées par l'auteur après 5.30.5, et l'« Échelle » du plan s'en va
(A376, doctrine `docs/decisions/lot-v5-30.md`).
- **Notices** : « Vous êtes l'auteur… » prend le dessin de la bulle système (même bord, même rayon,
  même rembourrage) — deux dessins pour un même rôle.
- **Moi** : « Exporter mes données » et « Un problème ? » espacés de 12 px ; dès 780 px, en rangée à
  largeur de contenu au lieu de 720 px chacun.
- **Cockpit** : la ligne « Parcours · Fait · n étapes » collait à 4 px de l'en-tête qui porte la
  capsule ; 20 px, comme sous la capsule ailleurs.
- **Une seule barre d'outils** : Schéma en ligne et plein écran, Page, et les ‹ › de toutes les
  recherches partagent une règle — M 40, matière de travail v5.30, rayon 12, corps 13,5 gras.
- **« Vérifier :: »** : secondaire de la rangée de flux, à la hauteur de « Continuer » (56), matière
  calme, corps 15.
- **Options d'une décision** : le corps des étapes en session (17,5) ; le renvoi « → bloc n · titre »
  ne coupe plus le titre à 17 caractères, l'ellipse prend la place disponible.
- **« Le tableau ne colle pas ? »** : la carte des différentiels se signale 2,4 s d'un anneau qui
  s'efface (fixe sous `prefers-reduced-motion`, jamais une couleur seule).
- **Le parcours n'a plus qu'un dessin** : la liste numérotée à renvois écrits (A349) rend aussi la
  feuille « Se repérer », la colonne du cockpit et le rail 780-1199, avec l'état de session (rangée
  courante en bleu et `aria-current`, blocs cochés en vert, hors chemin en pointillé ; rien ne se
  coche là). L'ancienne Échelle n'avait plus d'appelant : purgée avec ses 65 règles et treize
  classes, épitaphe posée dans la feuille.
- Vérifié : check complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.30.5] — 2026-09-25
Une échelle fermée pour les CONTRÔLES (A375, doctrine `docs/decisions/lot-v5-30.md`). Retour de
l'auteur après l'audit typographique : les lettres tenaient leur échelle, les boîtes n'en avaient
aucune — mesuré, 18 hauteurs de bouton entre 28 et 70 px, champs 40 · 44 · 48, segments 35 à 44 ;
sur le seul accueil : en-tête 36, « Sélectionner » 40 × 130, filtre 44, recherche 44, carte 115.
« Bigger is not better » : tout descend ou s'aligne, une seule montée.
- **S 32** : mini-boutons de l'éditeur (32 à 48 avant), chips de catégorie, ✕ de bandeau, épingle,
  bulle d'historique, barre d'outils Markdown.
- **M 40** : boutons d'en-tête de toutes les vues (l'accueil monte de 36 à 40 — la seule montée,
  choisie), filtre rond, « Sélectionner » en pilule SANS icône sur la matière du chrome, `.btn.sm`,
  ✕ de toutes les fenêtres avec un seul glyphe.
- **L 44** : champs de l'éditeur (48), touches du quai en session (50), boutons de « Terminer » (46),
  « Rejoindre » (48), segments de la feuille Affichage (40).
- **XL 56** : Démarrer, Exercice, Continuer, Découvrir, porte « Ajouter à cette aide » (60 avant).
- **Rangées 52** : cartes dépliables (54), tuiles du menu ⋯ (56), réglages du compte (70), bloc du
  journal (50).
- **Cartes d'accueil au téléphone** : titre 17,5 → 15/700 comme en large (décision de l'auteur,
  renverse A359 sur ce point) — la carte passe de 115 à 92 px.
- Mesuré après, à 390 px : boutons sur 32 · 40 · 44 · 52 · 56 · 64 pour 190 des 202, le reste étant
  des libellés sur deux lignes. Dette dite : le garde-fou `check-ctrl` reste à écrire.
- Vérifié : check complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.30.4] — 2026-09-24
Audit typographique demandé par l'auteur, MESURÉ sur 46 surfaces à 390 px (tactile) et 1100 px
(A374, doctrine `docs/decisions/lot-v5-30.md`) : l'échelle fermée est respectée, mais six écarts
de rôle la contredisaient. Tous refermés et re-mesurés.
- **Accueil** : recherche du dock à 17,5 px au téléphone, face aux titres de carte 17,5 gras (A359
  l'écrivait, la règle disait 15) ; en large elle reste à 15, comme la carte. Nature de rangée
  « AIDE / PROTOCOLE » 11 → 12, catégorie 12 aux deux largeurs (11 en large avant).
- **Feuille « Se repérer »** : nœuds 12 → 13,5, renvois 11 → 12, titre de rail 12 aux deux largeurs —
  il n'était stylé qu'au-dessus de 780 px et tombait sur le 16 px du navigateur au téléphone.
- **Menu ⋯** : tuiles « Se repérer » et « Schéma » 11 → 13,5 gras (corps de commande, pas de sur-titre).
- **Compte** : note de confidentialité 13,5 aux deux largeurs (11 en large avant).
- **Éditeur** : libellés de champ 12 → 13,5, l'aide reste à 12 — la question se distingue de son explication.
- Laissés tels quels, motivés dans A374 : le 16 px des champs (plancher iOS, règle 9) et les titres
  de fenêtre 24 / 17,5 (A352 fait foi, classement de Stockage, Versions et Catégories encore ouvert).
- Vérifié : check complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.30.3] — 2026-09-24
Retours de l'auteur sur 5.30.2 (A373, doctrine `docs/decisions/lot-v5-30.md`).
- **Le contenu descend sous le fondu d'iOS 27, et c'est réversible en une ligne** : le sol d'A370
  rend le voile invisible sur l'inset, mais son fondu (~16 pt au-delà) tombait sur le haut de
  l'en-tête. Un token nommé porte le contournement — `--ios27-top:min(env(safe-area-inset-top),16px)`
  et `--sat` = inset + ce décalage, lu par les quinze consommateurs de l'inset haut (en-tête, sol,
  colonne et barre de sélection, alertes, plein écran, moniteur, fenêtres, barres PDF et Page, lien
  d'évitement). Nul sans inset : les navigateurs ne bougent pas d'un pixel. **Le jour où Apple
  corrige : `--ios27-top:0px`, rien d'autre.**
- **Version au pied de l'accueil au téléphone**, et **« Un problème ? » dans Moi / Mon compte**
  (carte « Sur cet appareil », connecté ou non) : ouvre la fenêtre de stockage qui porte « Réparer
  l'application » — la maquette v5 avait masqué le socle au téléphone, et avec lui la seule issue
  d'une app installée bloquée sur une vieille version.
- **Le code de connexion se colle à nouveau** : la bulle « Coller » était absente parce que la classe
  du geste « Maintenir » (qui bloque sélection et bulles pendant l'appui) restait collée au body
  quand le bouton de remise à zéro était re-rendu pendant l'appui — plus aucune bulle nulle part
  jusqu'au rechargement. La fin du geste s'écoute désormais sur le document, et un champ qui prend
  le focus retire la classe par ceinture. Un collage ne garde que les chiffres, Entrée valide.
- Vérifié : check complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.30.2] — 2026-09-24
Trois signalements d'iPhone, mesurés au simulateur iOS 27 avant d'être traités (A370-A372,
doctrine `docs/decisions/lot-v5-30.md`).
- **iOS 27, le verre flou du bord haut (A370)** : ce n'est pas l'app — le système compose son
  propre voile PAR-DESSUS la vue web, sur tout l'inset de l'heure puis en fondu sur ~16 pt, quel
  que soit ce que la page fixe dessous (sonde rouge : un sol opaque est lui-même délavé ; un vrai
  `<div>` fixé, testable au toucher ou non, subit la même chose). Le remède retenu rend le voile
  invisible : un sol de la couleur du fond sous l'heure sur TOUTES les vues (accueil, lecture,
  édition, aides et protocoles), au-dessus des fenêtres et des feuilles — reste le fondu de 16 pt
  au défilement, celui de toute app native iOS 26+ ; en thème sombre, rien ne se voit. Le `<head>`
  portait DEUX balises de style de barre d'état (`default` d'A368 puis `black-translucent`) : la
  seconde l'emportait, A368 n'a jamais été en vigueur — une seule désormais, `black-translucent`.
  Le style `default` a été mesuré : barre grise opaque plus sombre que la page, contenu jamais
  flouté, mais mise en page à reprendre (inset nul) — non retenu, choix laissé à l'auteur.
  ⚠ Réinstaller l'app pour la balise ; le sol arrive par la mise à jour.
- **Le pied de lecture qu'on croyait masqué (A371)** : « Cet appareil seulement · x Mo · vX » en
  bas d'une fiche ou d'un protocole n'était pas `footer.tools` (déjà masqué depuis des versions —
  le correctif de 5.30.1 était mort) mais une rangée émise par le rendu. Purgée avec son CSS, son
  rafraîchissement et sa règle d'impression ; le doublon de 5.30.1 part avec.
- **« Recevoir le code » (A372)** : la fenêtre Compte disparaissait sur iPhone après l'envoi
  (état posé, position perdue — non reproduit au simulateur). Le formulaire relâche désormais le
  champ actif AVANT de remplacer le DOM, pour que le clavier se ferme par la voie normale et que
  les deux viewports se recollent ; et « E-mail invalide » ne vide plus le champ.
- Vérifié : check complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.30.1] — 2026-09-24
Suite de la refonte v5 : les décisions restantes sont prises, la feuille « Consulter » a vécu, et
la page de lecture s'aligne sur une seule grammaire de cartes, de menus et de flèches (A363-A369,
doctrine `docs/decisions/lot-v5-30.md`).
- **Décisions de l'auteur** : les volets Outils et Journal restent sur la matière système, le quai
  garde ses quatre touches (écarts d'A350 clos) ; « Moi » liste les bibliothèques avec leur rôle
  (A364) ; **Sessions et Moi sont des VUES de la colonne ≥ 780 px** (A365) — mêmes portes, mêmes
  rendus que les pages-fenêtres, qui restent la règle au téléphone et depuis une fiche ; au
  franchissement de 780 la surface change de peau sans se perdre.
- **Accueil** : un seul filet au pied de la colonne ; la feuille « Affichage » a le même contenu à
  toutes les largeurs ; « Affichage » et « Sélectionner » sont un même bouton ; recherche et filtre
  du bas à 44 px (retour sur A359) ; titre de la carte « Session en cours » 17,5/800 partout ;
  la croix du rappel « Session terminée » est bornée à 32 px ; les sous-feuilles de la sélection
  (bibliothèque, catégorie) proposent « ‹ Actions » (A366).
- **Page de lecture** : les quatre cartes de la session (À vérifier, différentiels, repères,
  Références) existent AVANT la session, fermées d'office comme « Parcours », en mode « Toute la
  fiche » et sur une aide sans parcours aussi ; une seule fabrique (`foldCardsH`). **La feuille
  « Consulter » est retirée** (A367) : « Le tableau ne colle pas ? » et « Documents · n » mènent à
  la carte de la page, ouverte seule ; rien d'autre n'y menait (vérifié au grep). Plus de pied de
  page en lecture ; ligne des minuteurs à la gouttière ; « Repères posologiques » sans trait sous
  son titre ; tuiles du menu ⋯ sans filet ; « Parcours » repliée à 56 px comme les autres.
- **En session — la bulle d'historique** (A369, planche A) : la ligne-bilan devient une bulle
  centrée entre « PARCOURS » et le compte (« Fait · 1→2 · diagnostic confirmé », icône
  d'historique, 28 px, matière discrète), qui s'allume une fois quand un bloc coché la rejoint ; un
  tap l'ouvre en carte de rangées. 40 px rendus au premier bloc. Les colonnes latérales s'arrêtent
  au-dessus du quai et ne bougent plus à l'ouverture. Compte et chevron du bloc en cours et des
  rangées d'historique comme sur les cartes ; **un seul chevron** (`uiIcon('chev')`, trait, gris,
  tourné par une classe) sur toute la page de lecture — cartes, bloc, historique, bulle, rails,
  aperçu du schéma.
- **iOS 27** : barre d'état déclarée en style « default » contre le verre flou posé par le système
  sur le haut du contenu (A368) — à vérifier sur l'appareil.
- **Garde-fous** : `audit-consulter` réécrit autour des cartes ; témoins adaptés (fenêtres
  ouvertes depuis une fiche en large, Parcours ouverte pour lire ses liens, dérive du journal
  mesurée DANS le fil, croix du rappel centrée, menu ⋯ en feuille) ; palier 924 retiré, `data-rs`
  purgé ; [5.25.1] archivée.

## [5.30.0] — 2026-09-22
### La refonte v5 : la marque d'une étape critique, « Fin » au quai, l'accueil et la fiche alignés sur la maquette (A345-A351)

- **Demande de l'auteur** : implémenter la maquette v5 (smartphone à fidélité haute, planche large
  en grille A) dans l'ordre tokens → étapes critiques → accueil → fiche → session → protocole →
  paliers → pliables, sans nouveau token ni valeur hors échelle, en réutilisant l'existant. La
  décision typographique jointe est normative : l'échelle A6 reste fermée à sept crans, seule
  l'affectation monte d'un cran.
- **Tokens** : `--g-cmd` (glyphe de commande, 17,5) et `--shadow-cur` (l'ombre du seul bloc
  courant, `none` la nuit) ; aucun autre.
- **A345 — la marque d'une étape critique (« 6b »), A11 rouvert** : toutes les étapes d'une liste
  partagent le même corps (17,5 en session, 15 en lecture) et la même colonne ; le danger est porté
  par le MOT en étiquette au-dessus du libellé (« CRITIQUE » / « VIGILANCE »), la bordure de la case
  (36 px, 2,5 px au registre) et le préfixe lecteur d'écran — aucun glyphe ⚠/△, aucune encre colorée
  sur le texte. Une fabrique (`stepMarkHtml`) pour la rangée cochable et l'aperçu à plat. Rangées de
  64 px arrondies sur l'ambiance, cochée en vert doux avec case pleine ; titre de bloc et question à
  21 ; carte de décision ambre doux, options 15/800, issue prise à la matière système. L'encre de
  « VIGILANCE » est `--warn` : `--warn-line` sur `--warn-soft` tombe à 3,19:1 la nuit (calculé).
- **A346 — « Fin » au quai** : touche au registre critique de la matière système, ouvre la fenêtre
  « Terminer la session ? » (seule porte, inchangée) dont la confirmation se MAINTIENT 1,2 s
  (relâcher annule ; clavier direct) par la mécanique de remise à zéro des minuteurs. Les touches
  constantes du quai restent ; « Se repérer · Schéma » en rangée sous le bloc courant (< 1200) ; budget de chrome reposé à
  32 / 39 % (capsule 64 px).
- **A347 — accueil** : plus d'intertitre « Répertoire » (ligne de compte, « Affichage » à pastille,
  Sélectionner), rangement par catégorie par défaut, rangées 64 px / méta 13,5, badges d'attente
  achromatiques (seul « À revérifier » reste ambre), tuiles 76 px à liseré 6 px et point pulsant,
  livres en grille dès 780. **Fiche** : sur-titre CATÉGORIE · CODE à pastille carrée, chips 12/800,
  trois cartes dépliables à état par fiche (« Quand l'utiliser », « Ne pas oublier », « Parcours »,
  critères et rappels à 17,5), statut de l'éditeur en segmenté à pastille glissante. **Session** :
  capsule de 64 px sur une ligne (chrono 24, tuiles à barre 3 px), « + Minuteur » 1 · 2 · 3 · 5 min
  libellé par la durée, pastille numérotée du bloc sur la ligne du titre.
- **A348 — large et pliables** : la capsule ne monte dans l'en-tête qu'au cockpit (≥ 1200) ; grille
  du protocole sur `--col-orient` ; dépliant « Sommaire · n sections » avec compte par titre et
  sections sans résultat repliées en recherche ; `horizontal-viewport-segments:2` — deux volets,
  gouttière 24 px sur la pliure, quai borné au volet gauche.
- **A349 — seconde passe sur les captures** (demande de l'auteur) : « Journal · n » au quai (le tap
  pose l'heure puis relit le journal), premier compteur en tuile dans la capsule ; accueil en CARTES
  (voie étroite), feuille « Affichage » (afficher · trier · regrouper · densité), « Sessions » dans
  l'en-tête ; écran de bienvenue de la maquette (trois portes) ; « Créer » par deux cartes de type ;
  parcours de l'écran d'entrée en liste numérotée avec renvois écrits (`preFlowFlatHtml`) ;
  « Parcours · x/y », pilule « EN COURS », « Ne pas oublier » en carte ; historique des sessions en
  cartes ; sommaire de protocole en carte, titres 17,5, chevron à gauche ; identité de l'éditeur
  ouverte, porte « Ajouter » en bouton flottant tonal (la palette garde toutes ses options).
- **A350 — troisième passe, la cohérence du style** (demandes de l'auteur : « l'ENSEMBLE du style »,
  « les sélecteurs glissants comme la maquette », « plus d'en-tête blanche sur smartphone ») : UNE
  pastille glissante pour tous les segmentés (piste `--amb-2`, pastille blanche à ombre, encre
  `--ink`) ; l'en-tête sur l'ambiance sans filet, commandes en pastilles de 40 px (« + » rempli, compte
  sur `--primary-soft`), titre de lecture en sans 15/700, sur-titre réduit à CATÉGORIE · MODE sous
  430 ; quai hors session sans matière (« Démarrer » rempli `--act`, « Exercice » pointillé) ;
  lecture : titre 24/800 dans la page, méta en une ligne 13,5, options sur deux colonnes,
  « Continuer » rempli, « Mode écran » ; taille du texte à trois crans ; éditeur : champs `--amb-2`
  à filet 1,5 px, intitulés 12/800, cartes blanches, chapeau à badge « ! » ; fenêtre Compte en
  cartes ; « Sessions » en cartes ; carte « Session en cours » de l'accueil en carte blanche (plus de
  bande verte, « Reprendre » bleu — demande de l'auteur). `--act-sys` purgé. Écran de bienvenue : titre 38 rendu (il perdait
  contre `.ai-card h3`).
- **A351 — relecture de l'auteur sur les captures** : la pastille se glisse partout (feuille Affichage,
  statut) ; carte « Session en cours » à liseré vert (téléphone) et bande système (large) ; le titre
  n'est jamais écrit deux fois (dans la page au téléphone, dans la barre dès 780, discriminant sur la
  ligne du titre) ; réponse attendue en mono neutre ; colonne gauche de la planche large (marque,
  Aides · Sessions · Moi, « Gérer » en lien, compte au pied, en-tête réduit à recherche + Créer) ; bordure
  bleue du bloc courant ; en session « Ne pas oublier » PUIS À vérifier, différentiels, repères en cartes
  dépliables SOUS le bloc ; « Mode écran » au menu ⋯ ; titres de protocole à chevron droit sans
  indentation ; socle de l'accueil supprimé au téléphone (Rejoindre → Sessions, Gérer → Affichage) ;
  sommaire de protocole sous le titre, collant en défilant ; compte des cartes contre le chevron.
- **A352 — cinquième passe (relecture de l'auteur)** : DEUX MATIÈRES DE FENÊTRE — les six destinations
  (Sessions, Compte, Catégories, Stockage, Bibliothèque, Versions) deviennent des page-fenêtres
  (`.ai-modal.page` : fond d'ambiance, cartes, titre 24, pastille de fermeture ; plein écran au téléphone,
  panneau au gabarit document dès 780), les dialogues restent des cartes blanches ; barre de sélection ≥ 780 en carte
  entière ; `.btn` à la matière v5 (primaire `--act` plein, `--shadow-primary` purgé) ; anneaux de focus
  jamais rognés (corps de fenêtre respirant sur les deux axes, anneau intérieur sous `overflow:hidden`,
  colonne) ; cartes d'historique resserrées (17,5 / 44 px) ; Compte en cartes (appareil, connexion,
  vocabulaire) ; recherche large à 40 px ; logo et code de session dans la recherche MESURÉS conformes.
  Quatre témoins adaptés à A351 (dont un qui PENDAIT 30 s sur une barre cachée).
- **A353 — sixième passe** : bandeau système en BULLE (trois largeurs) ; UNE feuille « Affichage » pour
  le rangement ET les filtres (la feuille Filtrer est purgée, groupe Catégorie et pied « Tout effacer ·
  Voir les n résultats » repris), ouverte par le bouton ROND à gauche de la recherche (52 px, permanent,
  même matière qu'elle — renverse A238 sur ce point), un seul « ＋ Créer » à l'état vide,
  « Moi » porte les initiales du compte (pied « Compte » supprimé), « · discriminant » respire dans
  l'en-tête, Tableau · Schéma alignés, consigne du dialogue Terminer dégagée, croix du bilan centrée ;
  préférences d'affichage vérifiées persistantes, commentaire du tableau ≥ 1200 corrigé ; fenêtre Compte
  relue à la mesure (quatre paliers, rien sous 12, graisse 650 purgée) et **`.btn` à 15/700 partout**.
- **A354 — septième passe** : « Références » en carte dépliable sous les cartes de session (schémas,
  documents, sources, renvois), « Consulter » quitte le quai, le bas de fiche et la colonne du cockpit
  (quatre touches de largeur égale, « Fin » au gabarit commun) ; « Mode écran » retiré ; le rail perd
  « Terminer la session… » ; la capsule ne monte dans l'en-tête qu'au bureau (≥ 1440), une tablette en
  paysage garde la bande.
- **A355 — huitième passe (canevas)** : un filet discret entre les touches du quai ; la rangée « session en
  cours » perd son aplat vert (carte blanche, liseré 6 px, « ● En cours » en vert), en vue détaillée et compacte.
- **A356 — neuvième passe** : légende « réponse attendue » à la voix mono des réponses, plus de « Terminer la
  session… » dans le volet du quai (A336 amendée : la session se termine au quai), contraste des boutons de la
  carte « Session en cours » (bord critique au téléphone, encre et bord `--crit-sys` et « Reprendre » plein sur la bande).
- **A357 — dixième passe (canevas)** : une seule grammaire pour les cinq dépliants de session (tête commune
  avec compte et chevron, rangées à filet sans marque, réponse ou dose en mono, Références sans carte imbriquée).
- **A358 — onzième passe** : UNE carte dépliable (`foldCardHtml`) pour l'écran d'entrée et la session — même
  tête, même corps, même rangées ; « Ne pas oublier » perd son gestionnaire à part ; seconde ligne des
  différentiels et des repères en corps 13,5 ; « Sources » dans la carte Références.
- **A359 — douzième passe** : barre de sélection, dialogues et « Rejoindre » sur la matière des boutons v5 ;
  texte de la recherche du téléphone à 17,5 et icône de filtre à 24 ; la dernière carte d'un groupe de
  l'accueil garde son bord bas (invisible en sombre).
- **A360 — treizième passe** : la feuille « Actions » de la sélection (téléphone/tablette) parle la
  grammaire du menu ⋯ — icône, sous-ligne et chevron par rangée (`openPickMenu` : `ic`/`sub`/`chev`),
  matière de travail, en-tête 17,5 sans filet, rangées 52 px à filets entre elles, danger à l'écart.
- **A361 — quatorzième passe** : UN dessin de menu — `menuRowHtml` émet la rangée `.mm-row` du menu ⋯
  et des sélecteurs, coque `.popmenu` ancrée ou en feuille ; le menu ⋯ devient une FEUILLE BASSE sous
  780 px (montée sur `<body>`, voile, poignée) ; le pied danger encadré a vécu (A337 amendée).
- **A362 — quinzième passe** : à l'accueil en cartes, 8 px entre les cartes d'un groupe et 24 px avant
  chaque intertitre (elles se touchaient) ; le livre compact ne change pas. Le témoin partage « rien ne
  bouge » mesure la dérive dans le fil (la rangée « Connexion perdue » du quai le décalait sous charge).
- **Écarts restants, à décider avec l'auteur** (doctrine A350-A362) : volets Outils/Journal blancs, quai à trois tuiles, bibliothèques dans Moi, Sessions/Moi en vraies vues de la colonne
  ≥ 780 ; deux formes refusées d'A330 reprises sur maquette
  (intitulés dans les cartes, Parcours dépliable — ouvert par défaut).
- Témoin `audit-doctrine` « v5.30 · A345 » ; doctrine `docs/decisions/lot-v5-30.md`, index,
  `design/ds` régénéré, CHANGELOG à 20 ([5.25.0] archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro.

## [5.29.4] — 2026-09-11
### La destination devient une pastille, les voies cessent de se superposer, et le papier se pagine avant d'être peint (A344)

- **Signalés à l'usage** : « il reste des soucis de superposition des flèches, et des flèches qui
  passent au-dessus des blocs » ; « les options à droite dans les blocs sont encadrées, contrairement
  à l'app » ; « le bout de la flèche n'est pas visible » ; « puis fais le paginateur mesuré ».
- **La destination est une pastille**, comme sur la maquette retenue : « CONTINUER ↓ 4 » au registre
  de la décision (cadre ambre plein), « ALLER À 7 » et « REVENIR À 2 » au registre des voies (cadre
  bleu pointillé, fond pâle), « ▪ FIN » reste un mot. Elle donne surtout au trait un bord d'où
  partir : une sortie part du bord droit de la pastille, un retour du bord gauche de la boîte — de la
  pastille il traversait le libellé de sa propre ligne (mesuré deux fois sur l'état de mal).
- **Un bus, pas n traits superposés** : trois décisions sortaient vers le même bloc et descendaient
  dans le même couloir, **615 px l'une sur l'autre**. Les lignes rejoignent le couloir par un tiret,
  la descente est unique. Toutes les voies passent par un registre de couloirs partagé (une abscisse
  prise glisse de 5 px), et le collecteur d'une fourche descend dans l'interstice de sa branche au
  lieu de longer la colonne des numéros. Une pointe s'arrête à 5 px du numéro, qui porte un halo et
  passait devant elle.
- **Le paginateur mesuré, et les voies reviennent sur le papier** : `svPaginate` pose lui-même les
  sauts de page, donc il les connaît — hauteur utile mesurée en millimètres, blocs insécables dans
  l'ordre du flux, saut avant celui qui déborderait. Les chemins s'écrivent en points, se coupent aux
  frontières et se décalent : un trait sort en bas d'une page et reprend en haut de la suivante, à la
  bonne cellule. Il peut renoncer et le dit (un bloc plus haut qu'une page), le calque restant alors
  masqué. Coût mesuré : l'état de mal passe de 3 à 4 pages, une fourche insécable laissant du blanc.
- **La feuille imprimée garde sa géométrie d'écran** et se centre dans les 210 mm : un padding
  différent décalait le calque de 28 px, et le couloir de droite passait sur le texte des cellules.
- **Témoin** (`audit-doctrine`) : aucun segment ne pénètre une cellule, un numéro, un intitulé, une
  pilule ou un texte de décision ; aucune superposition ; imprimer une aide imprime la Page ; le
  paginateur a posé ses pages ; l'écran retrouve son état. ⚠ Sa première écriture était **aveugle** —
  elle testait un recouvrement sur les deux axes alors qu'un segment a une épaisseur nulle, donc la
  condition ne pouvait jamais être vraie. Corrigée en testant l'appartenance, vérifiée capable
  d'échouer, elle a immédiatement trouvé deux vrais défauts.
- Doctrine A344 (trois addenda), index, `design/ds` régénéré, CHANGELOG à 20 ([5.24.2] archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.29.3] — 2026-09-11
### Les voies partent du bord de la boîte ; la feuille imprimée EST la page A4 (A344)

- **Signalé à l'usage** : « les flèches commencent encore à l'intérieur du bloc en superposant au
  texte et traversent des blocs », et « l'impression au format PDF rajoute des marges sur A4, quitte
  à ajuster la taille globale proportionnellement ».
- **Mesuré avant** (sonde : chaque segment du calque contre chaque cellule des deux fiches réelles) :
  **six croisements**, tous du même type — une ligne « SI … ALLER À n » occupe toute la largeur
  intérieure de sa boîte, donc partir de son bord droit, c'était partir sur le dernier mot et
  traverser la bordure, 27 px de trait dans la boîte. **Correctif** : une voie garde l'ordonnée de sa
  ligne et prend l'abscisse de sa BOÎTE. Et le collecteur d'une fourche descend désormais dans
  l'interstice de 12 px à gauche de sa branche, 14 px sous la source la plus basse (relevé au besoin
  pour passer sous une colonne sœur) — il descendait au bas de la fourche entière en longeant la
  colonne des numéros, soit un grand rectangle vide lu comme un trait à travers l'algorithme.
  **Mesuré après : zéro croisement.**
- **La feuille imprimée est la page** : `width:210mm` et un padding calculé
  (`calc((210mm - 710px) / 2)`) qui garde la zone de contenu à la largeur d'auteur au pixel près —
  sans quoi le contenu se refluerait. Les marges horizontales ne viennent plus de `@page`, qu'un
  moteur peut ignorer (WebKit) en ajoutant les siennes puis en réduisant la feuille pour l'y faire
  tenir, d'où une image plus petite entourée de blanc. Mesuré : colonne racine 670 px inchangée,
  texte de 11 à 198 mm sur 210, même nombre de pages selon que `@page` est respecté ou non.
- ⚠ **Les voies mesurées ne s'impriment plus, et c'est une question de justesse** : le calque est un
  élément absolu à l'échelle de la feuille, que la pagination coupe net alors qu'elle POUSSE le
  contenu. Mesuré sur l'ACR : le bloc visé descend de 37 à 64 mm sur sa page selon ce qui a été
  repoussé, pendant que la flèche reste où le flux non paginé l'avait mise — elle désigne le mauvais
  bloc. Rien n'est perdu : la ligne « SI … ALLER À n » et la pilule « ↺ revenir à n » sont la vérité
  textuelle depuis A134, et le dessin de structure (tronc, fourche, rail) vit dans le flux, donc il
  suit la pagination et reste juste.
- Doctrine A344 (deux addenda), index, `design/ds` régénéré, CHANGELOG à 20 ([5.24.1] archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.29.2] — 2026-09-11
### Impression : un intitulé de branche ne finit jamais une page seul (A344)

- Suite de la mesure page par page de v5.29.1 : une fourche plus haute qu'une page se déroule
  cellule par cellule comme le tronc (mesuré sur l'état de mal : coupe entre 13 et 14, le trait de
  la colonne reprend page suivante) ; restait le cas de l'intitulé « si ‹option› » en bas de page,
  sa première cellule partant page suivante — `break-after:avoid` sur l'intitulé, comme sur la
  décision. Une cellule plus haute qu'une page reste un problème de contenu (l'éditeur signale au-delà
  de 8 étapes) ; un paginateur mesuré ne s'écrira que sur une fiche réelle qui imprime mal.
- Doctrine A344 (addendum), CHANGELOG à 20 ([5.24.0] archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.29.1] — 2026-09-11
### « Exporter en PDF » imprime la Page (A344, impression)

- **Demande de l'auteur** : « vérifie que quand on clique sur imprimer cette aide ça imprime bien
  cette page — pas les historiques de sessions ». Mesuré avant : le gestionnaire d'impression
  forçait la vue d'ensemble (journal + plan Détails) depuis v4.18.0 ; session en cours, c'est le
  journal de cette session qui partait sur le papier, et le quai de session, fixé, se répétait au
  bas de chaque page.
- **Ce qui s'imprime est la Page** : cran Page forcé au moment d'imprimer pour toute aide à plus
  d'un bloc (une aide mono-bloc garde la vue d'ensemble dépliée), `body.print-page` masque tout ce
  qui n'est pas la feuille (titre d'écran, onglets, recherche, bulle, retour au bloc), le quai est
  masqué sans condition, la coque ne réclame plus une hauteur d'écran et la marge sous la feuille
  n'ouvre plus une page vide.
- **Mesuré page par page** (Chromium, A4, après le vrai `beforeprint`) : état de mal sur 3 pages,
  ACR sur 2 ; les voies mesurées restent alignées d'une page à l'autre (une sortie émise page 1 entre
  dans son bloc page 2). Une cellule et une décision ne se coupent jamais, la décision reste avec ce
  qui la suit, une fourche peut se couper entre deux cellules — la garder entière repoussait la
  moitié de l'algorithme à la page suivante en laissant une demi-page blanche. Ouvert : une fourche
  plus haute qu'une page.
- Doctrine A344 (addendum impression), index, CHANGELOG à 20 ([5.23.9] archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.29.0] — 2026-09-11
### La Page : l'arbre est le fil (A344)

- **Brief de l'auteur** : mieux voir les étapes, mieux voir sur smartphone, garder l'esprit « tout
  sur une page A4 ». Deux fiches réelles fournies pour mesurer les enjeux (arrêt cardiorespiratoire
  2026, état de mal tonico-clonique à quinze blocs), douze planches explorées sur un canevas, la
  douzième retenue : « super on part sur E12 », puis « ok implémente ».
- **Mesuré avant** : à 1130 px la grille à six pistes rendait l'état de mal sur 2 432 px et, ajustée
  à 390 px, tombait à 32 % (corps de 3,5 px) ; chaque décision de l'escalade rejouait une fourche
  pleine largeur dont une branche n'était qu'un renvoi ; la sortie commune portait le numéro 5 et
  « fin de l'algorithme » tombait au milieu de la feuille. À 11 px, une fiche à quinze blocs ne
  tient sur un A4 dans aucune composition : ce qui se garde de l'A4 est la largeur.
- **La composition est l'arbre.** Une colonne de largeur A4 (740 px), la référence en pied partout.
  Le NUMÉRO est l'ancre de tout trait (entrée par le haut, retour par la gauche) ; la colonne des
  numéros est la surface de dessin — tronc plein, fourche = barre + descentes, réunion = barre +
  entrée ; une sortie s'écrit « SI … ALLER À n » dans la décision et se trace en pointillé par la
  voie de droite ; un retour part du bout de la branche vers la voie de gauche (collecteur sous une
  fourche, tiret et ▲ vers un rail) ; deux branches à contenu = fourche côte à côte, au-delà = rail
  en retrait de 32 px avec une équerre par branche ; un trait ne croise jamais rien, sinon la ligne
  écrite suffit. Tronc, fourche et rail se dessinent en CSS à géométrie locale, sans mesure ; seules
  les voies se mesurent (`svPaintArrows`).
- **Les cellules, façon ECAM** : case · libellé · points de conduite · réponse attendue en mono à
  droite, ou sous le libellé quand elle ne tient pas sur la ligne de sa colonne. Registre par le
  glyphe et la couleur, ✓ dans la case, texte jamais barré. « ▪ fin de l'algorithme » dans le bloc
  terminal.
- **La numérotation suit le tronc** (`flowPlan`, partagée par le journal, le Parcours et le
  schéma) : les arêtes de retour ne comptent plus pour la post-dominance, la convergence d'une
  décision est le plus proche post-dominateur commun à deux options au moins, les options hors
  convergence sont des sorties chaînées après le tronc. État de mal : 1-12 puis 13 relais · 14
  surveillance · 15 récidive ; ACR : 4 FV · 5 asystolie · 6 causes · 7 RACS.
- **Mesuré après** (1280 × 900) : état de mal 740 × 2 992, ACR 740 × 1 839, les deux fiches d'exemple
  sur une page A4 (959 et 929 px) ; « Ajusté » à 390 px = 48 %. L'onglet s'appelle « Page ».
- `svTreePlan` (pure) remplace `svGridPlan`/`svDistribute` ; `.sv-fk`, `.sv-r`, les paliers d'écran
  de la feuille et la colonne de référence latérale sont purgés ; `@page{margin:10mm 7mm}` pour
  imprimer la feuille à sa largeur. Témoins : `tests.html` (svTreePlan, flowPlan sur graphe à
  boucle et sur sortie hors convergence), `audit-doctrine` (numéros alignés, aucune cellule sous
  260 px, même image aux trois largeurs ; deux témoins du Parcours suivent la nouvelle convergence).
  Doctrine `docs/decisions/lot-v5-29.md`, index, `design/ds` régénéré, CHANGELOG à 20 ([5.23.8]
  archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.28.4] — 2026-09-08
### La Page n'a qu'un axe vertical, dans la fenêtre « Tableau » comme dans la fiche (A343)

- **Signalé à l'usage** : depuis « Tableau » de l'écran de démarrage d'une aide (ou « Plein écran »
  du cran Toute la fiche), « le scroll vertical à l'intérieur de la page n'est pas bloqué et ça fait
  double scroll » — alors que dans la fiche et dans la feuille Consulter, l'axe est fermé.
- **La cause est une portée** : la règle tactile de la v5.10.5 (C87 — axe vertical fermé par
  `overflow-y:clip`, parce qu'un axe `auto` rebondit sur iOS même vide et capture le pouce) était
  bornée à `main`, « le plein écran garde son défileur ». Vrai du schéma, qui a le sien ; faux de la
  Page, rendue aussi dans la fenêtre « Tableau », qui défile elle-même. Dedans, la feuille
  gardait un second axe : un défileur dans le défileur.
- **Mesuré avant** (390 × 844, pointeur grossier, Chromium et WebKit) : `overflow-y: auto` dans la
  fenêtre, `hidden` dans la fiche. **Correctif** : la portée `main` est retirée pour `.sv-scroll`
  (ses deux sites de rendu vivent dans un défileur de page) ; `.flow-scroll` garde la sienne.
  **Mesuré après** : même axe fermé des deux côtés, l'échelle fait grandir la fenêtre et jamais un
  axe interne, le défilement horizontal des colonnes intact.
- **Témoin** (`audit-doctrine`) : ouvre par le vrai lien « Tableau », vérifie que le régime tactile
  est émulé, lit le style calculé des deux sites, exige que l'échelle grandisse la fenêtre. Vérifié
  capable d'échouer sur l'état d'avant.
- Doctrine A343 + addendum C87, index (`AGENTS.md`, `docs/README.md`), `design/ds` régénéré,
  CHANGELOG à 20 ([5.23.7] archivée).

## [5.28.3] — 2026-09-08
### Le dernier repère quitte le pied du moniteur et se pose sur la bande, à son instant (A342)

- **Demande de l'auteur** : « et si on mettait plutôt le dernier repère sur la timeline de manière
  générale ? ». Ça faisait sens pour une raison précise : la bande portait **déjà** un point par
  repère des deux dernières minutes, mais ils étaient **anonymes** ; le pied disait *quoi* et
  *quand* sans aucune position dans le temps. Deux objets pour un seul fait, chacun amputé de la
  moitié de l'autre.
- **L'échelle est le vrai problème, et elle se mesure** : la zone du passé fait 101 px pour 120 s,
  soit **1 px ≈ 1,2 s**. Quatre repères d'un ACR en 80 s tiennent dans 61 px quand une étiquette en
  fait 90 à 115 : deux repères qui se suivent ne peuvent jamais tenir côte à côte.
- **La règle : l'étiquette COMMENCE à son instant.** Son bord gauche est le moment, il n'y a donc
  aucun segment horizontal — et donc rien à croiser. Le plus récent occupe la rangée du **bas**,
  contre la bande ; les plus anciens montent. La propriété tient par construction, à n'importe quel
  nombre de repères : le trait d'un repère plus ancien est toujours à gauche des étiquettes des plus
  récents, qui commencent plus à droite que lui. (Le premier dessin alignait les étiquettes à
  gauche ; c'est ce segment horizontal qui fabriquait les croisements — l'auteur l'a vu.)
- **Ce qui n'est pas nommé est compté** : « **+ 3 repères avant** », la phrase que la bande dit déjà
  de l'autre côté (« + 1 minuteur plus tard »), retournée vers le passé. Écarté : « 4 gestes en
  1 min 20 » — *geste* est un second mot pour ce que l'app appelle partout un **repère**, et la
  durée est déjà dessinée par l'étalement des points.
- **Sept points de robustesse, tenus et mesurés** : le plus récent ne fusionne **jamais** (la
  fusion des points trop proches ne vaut plus que pour les muets) ; libellé borné à 18 signes ; le
  trait de rappel reste **1 px en encre douce** (2 px en encre pleine est le registre « daté ») ;
  les étiquettes ne dérivent pas l'une par rapport à l'autre ; **hors des −2 min**, demi-point au
  bord gauche et âge en toutes lettres, de sorte que le dernier repère existe toujours quelque part
  — c'est ce que le pied garantissait ; le nombre de noms est une **mesure** (`min(3, rangs)`, le
  budget des échéances : trois en portrait, un seul à 130 % en paysage) ; la bande apparaît dès
  **un** repère, puisqu'il n'a plus d'autre endroit où se dire.
- **Mesuré après, 20 configurations** (390×844, 320×568, 844×390 à 100 et 130 % ; rafale de quatre,
  un seul, deux, huit serrés, dernier hors fenêtre) : zéro croisement, zéro chevauchement, rien hors
  cadre, zéro recouvrement du grand chiffre, compte exact.
- **Témoin** « MONITEUR · le passé se nomme, et il tient en rafale » (12 combinaisons). ⚠ Un trait
  se glisse **sous** sa propre étiquette de 3 px — c'est le rattachement, pas un croisement : le
  contrôle ne compte que les traits qui traversent l'étiquette d'une AUTRE rangée (sa première
  version comptait les siens et rougissait sur un dessin juste). Vérifié capable d'échouer : l'ordre
  inversé donne 8 rouges. Témoins `monBandData` réécrits (trois nommés au plus, ce sont les plus
  récents, eux ne fusionnent jamais).
- **Purge** (règle 14) : `.mon-foot` / `#monFoot` — élément, CSS, rendu et lecture de hauteur — et
  `.mb-dot b`, le compte par point que la phrase remplace. L'afficheur regagne 46 px.
- Doctrine A342 dans `docs/decisions/lot-v5-28.md`, index `AGENTS.md` / `docs/README.md`,
  CHANGELOG à 20 ([5.23.6] archivée).
- Vérifié : `npm run check` complet, 1200 tests × 2 moteurs, audit COMPLET 29/29 après le numéro
  de version.

## [5.28.2] — 2026-09-08
### Fermer une photo garde la page où elle était, et le grand chiffre du moniteur ne recouvre plus la bande (A340-A341)

- **A340 — la photo, tout en bas d'un protocole.** Signalé : « fermeture photo sur protocole remet
  le scroll tout en haut », puis la précision décisive de l'auteur : *seulement page défilée tout en
  bas, par la croix ou par un tap hors image*. **Trente configurations de banc étaient vertes**
  (quatre portes de fermeture, deux moteurs, tactile et souris, zoom 100 et 130, `isMobile` posé
  pour que la garde `(pointer:coarse)` soit celle du téléphone) : le défaut n'existe que sur le vrai
  moteur. Mesuré sur iPhone (simulateur iOS 26.5, Safari réel, copie de banc instrumentée) : juste
  après la fermeture la position est **encore juste** (1886), et c'est **à la frame suivante** que
  WebKit repose la sienne — 0. La restauration de `_bgUnlock` n'était pas fausse, elle était trop
  tôt : tant que `html{overflow:hidden}` tient, le moteur garde une position à lui et la repose au
  layout suivant. Elle se repose donc aussi **après** le layout (deux frames), et seulement si la
  position a bougé — jamais contre un geste de l'utilisateur. Vaut pour **toutes** les fenêtres,
  pas seulement la photo. Prouvé sur l'appareil : +rAF, +100, +400, +900 ms → 1886.
- **A341 — le moniteur en paysage, texte agrandi.** Trouvé en mesurant, puis demandé : le grand
  chiffre **recouvrait la bande de 18 à 60 px** dès 130 % de taille de texte — ce qu'A232 avait
  fermé, rouvert par deux portes. (1) Le chrome de la bande était **estimé par des littéraux** justes
  à 100 % : 167 px rendus pour 90 estimés. Le plafond se prend désormais sur la bande **réellement
  rendue** — ce n'est pas circulaire, sa hauteur ne dépend jamais du chiffre — et le chrome mesuré
  sert au nombre de rangées du tic suivant. (2) Le plancher de 64 px était écrit en pixels de **mise
  en page**, donc il ne cédait jamais sous le réglage de taille du texte, qui est un `zoom`
  (règle 10) : il devient une taille **vue** (64 ÷ zoom), et sous elle le chiffre prend la place
  restante plutôt que de recouvrir la bande (A232 : « un chiffre recouvert ne se lit pas du tout »).
- **Ce que la mesure dit aussi** : à 844×390 avec le texte à 130 % et quatre minuteurs dont un en
  pause et un échu, l'afficheur a 300 px pour 388 px de contenu — **il manque 88 px**, et ils ne sont
  pas du côté du chiffre. Ce qu'il faudrait couper au-delà (pied, chrono de session, légende) est
  une décision d'auteur : elle n'est pas prise ici.
- **Témoins.** « PROTOCOLE · fermer une photo garde la page où elle était » **modèle** le moteur
  (un `requestAnimationFrame` repose 0 après la fermeture) — sans ce modèle, aucun banc ne voit le
  défaut ; deux portes, page tout en bas. « MONITEUR · la bande de temps tient à plusieurs
  minuteurs » gagne la dimension **zoom** (100 et 130 %, sept formats), vérifie le plancher en
  taille VUE, et sur un écran sur-souscrit ne s'exempte pas : il **borne** le recouvrement au manque
  mesuré. Les deux vérifiés capables d'échouer, `index.html` restauré à l'octet.
- Doctrine A340-A341 dans `docs/decisions/lot-v5-28.md`, index `AGENTS.md` / `docs/README.md`,
  CHANGELOG à 20 ([5.23.5] archivée).
- Vérifié : `npm run check` complet, 1196 tests × 2 moteurs, audit COMPLET 29/29 après le numéro
  de version.

## [5.28.1] — 2026-09-08
### Le parcours dit enfin sa profondeur : un retrait par niveau, dans les quatre régimes (A339)

- **Signalé à l'usage** : « parcours dans la page de démarrage d'une aide : indentation pas la
  bonne, notamment avec des blocs conditionnels hiérarchisés ». Reproduit et **mesuré avant
  correction**, sur une fiche à décision imbriquée.
- **Ce qui était faux.** Dans l'aperçu de l'écran de démarrage, les étiquettes de branche étaient
  toutes au MÊME retrait quel que soit leur niveau (« CHOQUABLE », profondeur 2, au même x que
  « OUI », profondeur 1) et le renvoi d'une branche sans rangée se posait à GAUCHE du tronc. En
  session, pire : les onze rangées de la colonne d'orientation à 10 px, étiquettes comprises —
  **aucun retrait du tout**.
- **La cause.** Quatre régimes écrivaient leurs retraits en ABSOLU (plan 24/32/48, colonne
  20/28/40, rail 16/28/40, aperçu à plat 18/32/40), et chacun pose aussi sa gouttière par un
  raccourci `padding` dont le sélecteur est plus spécifique : il remet `padding-left` à la
  gouttière, **où que soient écrites les règles de retrait**. Les trois retraits de l'aperçu à plat
  nés en v5.25.0 n'ont ainsi jamais rien fait.
- **Le correctif.** Le retrait devient un token ADDITIF (`--pl-ind` : 12 / 24 / 32 px, l'échelle
  déjà utilisée par la vue « Parcours »), ajouté à la gouttière de chaque régime
  (`calc(<gouttière> + var(--pl-ind,0px))`). Un raccourci ne peut plus l'effacer sans effacer aussi
  la gouttière ; l'alignement « la chip de branche sur le marqueur du bloc enfant » (v5.6) devient
  STRUCTUREL au lieu d'être recopié ; douze règles de retrait absolu disparaissent pour trois
  déclarations.
- **Mesuré après** : aperçu de démarrage 0/12/24, étiquette et rangée enfant au même x à chaque
  niveau ; session 10/22/34 ; le renvoi d'une branche suit sa branche. Aucune autre géométrie ne
  bouge (gouttières, hauteurs et corps inchangés).
- **Témoin** (`audit-doctrine`, « PARCOURS · le retrait dit la profondeur ») : fiche à décision
  imbriquée, retrait STRICTEMENT croissant avant et pendant la session, étiquettes comprises.
  Vérifié capable d'échouer (5 rouges sur l'état d'avant correctif). L'ancien témoin ne pouvait pas
  voir le défaut : il comparait l'étiquette à sa rangée — quand tout est à plat, elles sont
  alignées, et il était vert PARCE QUE la hiérarchie avait disparu.
- Doctrine A339 dans `docs/decisions/lot-v5-28.md`, index `AGENTS.md` / `docs/README.md`,
  `design/ds` régénéré, CHANGELOG à 20 ([5.23.4] archivée).
- Vérifié : `npm run check` complet, 1196 tests × 2 moteurs, audit COMPLET 29/29 après le numéro
  de version.

## [5.28.0] — 2026-09-08
### « Terminer la session » se trouve là où la session se lit, le menu ⋯ ne répète plus le dock, et la méta des cartes d'accueil dit un état en mots (A336-A338)

- **Demandes de l'auteur**, dessinées d'abord sur un canevas (quatre pistes, puis le menu, puis
  sept options de méta), validées avant tout code.
- **A336 — Terminer la session.** Une rangée « Terminer la session… — confirmation demandée »
  ferme le volet de session (étroit) et le rail d'état (large), sous un intertitre « Session ·
  depuis HH:MM ». Contour, jamais un aplat ; le tap ouvre la fenêtre « Terminer la session ? »,
  qui reste la SEULE porte. Jamais chez l'invité ni en aperçu. Un seul bouton permanent, pas de
  rappels ; formes refusées listées dans la doctrine.
- **A337 — Menu ⋯.** Trois natures de rangée de plus (`{head}`, `{tiles}`, `{fold}`) : les
  ouvertures (Moniteur, Se repérer, Schéma, Consulter hors session) en tuiles, des intertitres
  « Session » / « L'aide », le sous-titre SOUS le libellé sur une ligne (rangées 44 ou 52 px),
  largeur 300 px, la rangée danger en pied encadré. **En session le menu ne répète pas le dock** :
  Complication et Consulter en sortent (remplace la double entrée de v4.26.1) ; la gestion de
  l'aide se replie derrière « L'aide › ». 14 → 7 rangées en session. « Recommencer le parcours »
  n'existe qu'en session. Piège mesuré : le pli re-rend le menu, le clic remontait au document
  et le fermait (`stopPropagation`).
- **A338 — Méta des cartes d'accueil** (option J). À gauche l'identité : nature · discriminant ·
  ● catégorie ; à droite UN état en mots, le plus urgent : En cours 12:04 › Brouillon / À relire ›
  À compléter › Sans date › À revérifier 06/2023 › Validée 01/2025. Une taille, une graisse, aucun
  glyphe ni point, l'ambre pour ce qui attend. « Validé » n'apparaît plus qu'avec sa date ;
  le code sort de la rangée. Ligne de base alignée (écart 1 px mesuré) ; la catégorie s'abrège
  la première, le discriminant ensuite (plancher 4 em), jamais la nature ni l'état. Sous 360 px
  effectifs l'état passe sous l'identité, hauteur de rangée unique 76 px (320 : aucun
  débordement).
- Témoins adaptés : `audit-complications` (aucune rangée Complication en session),
  `audit-retour`, `audit-doctrine` (date lue dans `.dir-st`). Doctrine dans
  `docs/decisions/lot-v5-28.md` (nouveau), index AGENTS.md / docs/README.md, `design/ds/`
  régénéré. CHANGELOG à 20 ([5.23.3] archivée).
- Vérifié : `npm run check` complet, 1196 tests × 2 moteurs, audit COMPLET après le numéro de
  version.

## [5.27.1] — 2026-09-07
### La barre de retour colle au quai, et les deux retours portent l'icône (A335)

- **Demande de l'auteur** : rapprocher un peu la barre verte « retour au bloc » de la barre
  flottante, et remplacer les ↩ par une icône (barre et bouton « Reprendre » d'une complication).
- **Mesuré** : 8 px en navigateur — mais `#blkReturn` et `#dockSheet` ajoutaient
  `env(safe-area-inset-bottom)` à `--dock-h`, qui le contient déjà (hauteur mesurée du quai) :
  42 px sur un iPhone installé. Le terme en double est retiré des deux règles ; 8 px partout,
  prouvé à inset simulé (méthode A286).
- **Icône `backto`** (celle de « Un bloc ») sur la barre et sur « Reprendre — ‹bloc› → », dans
  le flux du texte pour rester collée au mot au passage à la ligne.
- **Deux finitions** vues à la capture : « Bloc Bloc 1 » (préfixe en double) et les tags
  « ⚡ complication » / « passage 1/2 » repris dans le libellé de la barre.
- **L'éclair aussi** (demande de l'auteur) : les quinze « ⚡ » emoji restants passent par la
  fabrique `boltIcon` ; classe `bolt`, seul glyphe REMPLI de la famille (`--bolt`/`--bolt-edge`,
  deux thèmes) pour ressortir autant que l'emoji qu'il remplace. Le sélecteur « renvoi du
  jalon » garde l'emoji dans ses `<option>` (pas de SVG possible, décision de l'auteur).
- Doctrine A335 dans `docs/decisions/lot-v5-27.md`, `design/ds/` régénéré. CHANGELOG à 20
  ([5.23.2] archivée).
- Vérifié : `npm run check` complet, 1196 tests × 2 moteurs, audit COMPLET après le numéro de
  version.

## [5.27.0] — 2026-09-07
### « Reprendre » revient sur l'étape interrompue, et la barre de retour ne survit plus à la fiche (A333-A334)

- **Reprise après complication (A333)** — signalé par l'auteur : « ouvre une nouvelle étape,
  devrait revenir vers l'ancienne et placer le bloc complication juste avant ; un bloc laissé
  ouvert, c'est perturbant ». Mesuré avant : trois passages pour un geste (l'ancien replié avec sa
  coche, la carte ⚡, un neuf vide). Désormais « ↩ Reprendre » RAMÈNE le passage interrompu au
  bout du journal — même visite, coches gardées, plus de « passage 1/2 » — et la carte ⚡ se range
  juste avant lui (`navRestore`, en place : `state.nav` reste l'alias de `Runtime.nav`). Ce
  choix RENVERSE A126 (« nouveau passage, cases neuves ») par décision de l'auteur — et le
  bouton l'a toujours dit : « ↩ Reprendre — ‹bloc› → » annonce un retour, pas un passage neuf ;
  le texte d'origine est barré dans `conventions-de-code.md`, pas effacé.
- **Ce que le réordonnement entraîne** : les replis, indexés par position, suivent leur visite
  (`ovFoldRemap`, rejoué aussi chez l'invité qui reçoit le fil) ; « l'entrée suivante du fil »
  saute les excursions (`navNextIdx`, pure) — sans cela une décision déjà répondue se rouvrait
  parce qu'une carte ⚡ s'était rangée entre elle et sa cible (mesuré : la décision reste une
  chip, sa réponse reste affichée, re-taper la réponse défile au lieu de reposter). Sans ancre
  ni passage à retrouver, l'ancien chemin reste (passage neuf) — jamais un journal cassé.
- **Barre « ↩ Bloc… » (A334)** — signalé : « apparaît sur la page d'accueil lorsqu'on termine la
  session et qu'elle est visible ; est-ce la seule situation ? » Non : mesuré aux quatre portes,
  « Terminer » la laissait pour toujours (le tick des minuteurs, seul à la resynchroniser,
  s'arrête avec la session) et le retour d'en-tête une seconde. `render()` la resynchronise à
  tout changement de vue.
- Garde-fous : `audit-complications` et `audit-doctrine` réécrits sur la nouvelle règle (même
  visite, coches gardées, une seule carte du bloc, ⚡ juste avant), un test unitaire
  (`instComplete` saute une excursion). Doctrine A333-A334 dans `docs/decisions/lot-v5-27.md`
  (nouveau fichier du lot), index AGENTS.md et docs/README.md. CHANGELOG à 20 ([5.23.1]
  archivée).
- Vérifié : `npm run check` complet, 1196 tests × 2 moteurs, audit COMPLET après le numéro de
  version.
