# Lot v5.19 — la colonne à trois étages, le pied qui ne se répète plus (A269-A276)

> Conçu sur l'artefact « Sidebar et bas de page » (canvas Claude Design, 30/08/2026), chaque
> décision mesurée sur l'app SERVIE avant d'être retenue. Point de départ : deux captures — la
> colonne gauche dont le pied est coupé en pleine phrase, et le bas de page entouré en rouge.

**A269. LA COLONNE GAUCHE A TROIS ÉTAGES, ET UN SEUL DÉFILE.** Mesuré avant de décider (iPad 11″
paysage, 1194 × 834 → 774 px utiles) : avec 3 bibliothèques et 5 catégories, la colonne demandait
**777 px**. Elle défilait D'UN BLOC, pied compris — le ✓ « contenu trouvable par la recherche »
était donc coupé EN PLEINE PHRASE, et avec lui le contrôle d'avant-départ « tout est sur
l'appareil », qui est précisément ce qu'on vient vérifier avant de partir sans réseau. À 10
catégories il manquait 190 px. Le remède n'est pas de raccourcir le pied mais de **cesser de le
faire défiler** : `.hs-top` (bibliothèques) fixe, `.hs-scroll` (catégories) seul défileur avec son
intertitre collant, `.hs-foot` (commandes + état) socle fixe — et `placeFooter` vise désormais le
socle, ce qui EST le mécanisme du correctif. Quatre décisions autour :

- **Densité prise à la direction B écartée** : TOUTES les rangées à 32 px, corps INCHANGÉ à
  13,5 px (seul le rembourrage tombe à 6) — sept catégories tiennent sans défiler là où cinq
  débordaient. ⚠ La première version densifiait les seules CATÉGORIES (32) et laissait les
  bibliothèques à 38 : deux hauteurs, à un filet d'écart, pour deux listes qui font la même chose
  (filtrer la vue). C'était un reste du panachage de deux directions de maquette, pas une
  décision — relevé par l'auteur, corrigé à 32 partout. Ce qui n'a PAS été pris à B : le sélecteur de bibliothèque. Il gagnait 120 px mais
  coûtait les comptes 7 / 9 lisibles d'un coup d'œil et un tap de plus pour changer de
  bibliothèque — c'est ce qui dit d'où vient quoi.
- **Les comptes restent collés à droite.** La maquette leur réservait, sur les catégories, la
  colonne de 34 px que le crayon occupe sur les bibliothèques, pour que tous les nombres tombent
  au même x (mesuré : 187 contre 225 aujourd'hui). ÉCARTÉ par l'auteur — « ça fait bizarre
  sinon » : un nombre décollé de son bord n'est plus lu comme la queue de sa rangée.
- **La remise à zéro des catégories manquait** (`data-catall`). « Toutes » existait pour les
  bibliothèques, rien en face : on ne revenait à l'union qu'en re-tapant la rangée active, un
  geste que rien n'annonce. Le compte affiché est celui du PÉRIMÈTRE choisi, pas de l'application.
- **Une commande n'est pas un filtre** (`.hs-cmd`) : icône, libellé en gras, chevron. Le nombre en
  queue voulait dire « ce que la liste montre » pour une catégorie et « ce qu'il y a derrière la
  porte » pour l'historique — deux sens pour un même signe, dans la même colonne.

**Deux pièges payés, notés sur place.** (1) Le bloc de style est déclaré AVANT `.hs-row` : à
spécificité égale, `.hs-cat{min-height:32px}` perdait la cascade EN SILENCE (rangées mesurées à
38 px au premier essai). Qualifié en `.hs-row.hs-cat` plutôt que déplacé loin de son commentaire.
(2) La marge basse du filet de `.hs-top` s'échappait de sa boîte (fusion de marges) et ouvrait une
bande de 12 px entre les deux étages, assez pour laisser voir ce qui défile dessous. La marge
tombe ET les deux étages fixes deviennent opaques au-dessus du défileur : deux causes possibles,
deux réponses, aucune ne coûte un pixel de mise en page. Vérifié à la sonde : écart 0, intertitre
collé au bord du défileur, bas du pied identique avant et après défilement.

**A270. LE PIED NE DIT PLUS DEUX FOIS LA MÊME CHOSE — ET SURTOUT PAS SUR UN APLAT.** Au nominal,
`#attOffline` et `#attIdx` affichaient deux phrases commençant par les mêmes mots (« Documents
PDF : … »), la seconde laissant « (15) · Réindexer » partir seul à la ligne suivante — le compte
orphelin de sa phrase, et la seule chose actionnable au bout d'un mur gris de cinq lignes de
11 px, juste au-dessus du seul contrôle qu'on vise vraiment (la recherche). Elles fusionnent en
UNE rangée `#attSum`, dépliable SUR PLACE (règle 11 : pas de fenêtre).

- **La synthèse n'existe QUE si les deux sont au nominal.** `_attSum` retient le compte de chaque
  ligne quand elle est au vert, `null` sinon — l'état ne se déduit JAMAIS du HTML rendu (un état
  lu dans sa propre peinture est un état qu'on finit par mal lire). Dès qu'une des deux a quelque
  chose à demander, la synthèse s'efface et les deux lignes reprennent la parole telles quelles,
  registre ambre et boutons compris : **on ne masque jamais un état qui appelle un geste**. Les
  six branches réelles (nominal · manquants · indexation en cours · sans texte · échec ·
  divergence) sont inchangées.
- **AUCUN APLAT, et c'est une règle, pas un goût.** La maquette posait la synthèse sur
  `--ok-soft` ; refusée par l'auteur (« ça saute trop aux yeux ») — et le code disait déjà
  pourquoi : `refreshAttOffline` porte « P3-11 : nominal = neutre », et `.pers-warn` colore le
  TEXTE, jamais un fond. Un aplat vert PERMANENT en pied d'accueil aurait désensibilisé à l'ambre
  exactement comme le pavé rouge du chapeau désensibilisait au rouge (A11). L'accroche vient du
  CHIFFRE en encre pleine (`.att-n`) : c'est ce qu'on vérifie.
- **La synthèse est une RANGÉE, pas une phrase suivie d'un lien.** Premier essai mesuré à 47,4 px
  de haut dans la colonne de 226 px : le texte passait à deux lignes ET le `.tlink` imposait ses
  32 px — plus haut que les DEUX lignes remplacées, gain nul. Une seule cible (`.att-more`) de la
  largeur du pied, 32 px (règle 9), chevron en queue selon la convention `.md-fch` (à droite
  fermé, vers le bas ouvert). Le mot « PDF » tombe ICI et seulement ici : le dépliant le dit deux
  fois juste dessous, et ces 22 px sont ce qui garde la ligne sur UNE ligne à trois chiffres.
- **L'ouverture est volatile par choix** : on rouvre l'application pour travailler, pas pour
  retrouver un panneau de diagnostic ouvert.

**A271. LE PIED EST UNE COLONNE DE RANGÉES, PLUS UNE COULÉE QUI ENJAMBE.** Mesuré sur les trois
largeurs où il vit (250 px en socle de colonne, ~574 et ~300 en voie étroite) : le `flex-wrap`
d'origine mettait la VERSION en bout de la rangée des liens à 574, la rejetait sous eux à 300, et
n'alignait rien — **trois bords gauches cohabitaient** (18 px pour la marque d'un état, 28 pour le
texte d'un lien, 36 pour celui d'un état), avec 2 px d'interligne entre des rangées de 32 px et
14 px de gouttière. L'ordre de lecture changeait avec la largeur, ce qui est le contraire d'un
pied de page.

- **Une colonne, un bord, un rythme.** Les commandes gardent leur rangée (elles peuvent tenir à
  deux de front), l'état descend en rangées empilées, interligne unique de 4 px.
- **Une seule colonne de texte, à 20 px** — marque de 14 px + gouttière de 6. Elle vaut pour
  TOUTES les lignes : les liens reçoivent leur marque (⤓, 🗄, ⇄ — les mêmes que les rangées de
  commande de la colonne), la ligne de version reçoit un retrait vide, et les lignes du dépliant
  un alinéa négatif pour que la suite d'une phrase tombe sous son premier mot, jamais sous sa
  marque. 20 et non 19 : l'échelle d'espacement est fermée (`check-space`).
- **La marque de l'état de stockage sort du texte.** `storageState` la rendait DANS la chaîne, et
  seulement dans l'état « Cloud » : le premier mot se décalait d'une largeur qui changeait avec
  l'état, et les deux états « cet appareil » n'avaient aucune marque. Elle devient un champ
  `mark` à part (`phone` pour l'appareil seul, `cloud` pour le compte), rendu dans la colonne.
- **Les deux lignes d'état sont des COMMANDES** — l'une ouvre la fenêtre Stockage (depuis la
  v4.56, `role="button"`), l'autre déplie. Elles prennent donc le même dessin exactement :
  marque, texte, chevron — et la hauteur de 32 px que la règle 9 leur devait déjà. `#storageInfo`
  vivait à 15,4 px depuis toujours : personne ne l'avait vu, parce qu'un contrôle qui ressemble à
  une légende ne se mesure pas comme un contrôle.

**A272. UN SEUL DESSIN DE MARQUE DANS LE PIED, ET LES COMMANDES DEVIENNENT DES BOUTONS.** Trois
retours d'affichage, une même cause : le pied mélangeait des idiomes.

- **La pastille de synchro était le seul OBJET du pied** — une pilule teintée de 22,7 px au milieu
  de lignes de 15,4 — et sa rangée n'avait rien dans la colonne de marque : elle flottait entre
  deux rangées qui, elles, commencent par un glyphe (« le numéro de version et Synchronisé ne sont
  pas alignés »). La pilule tombe ; l'état REJOINT la colonne de marque, et la couleur reste au
  glyphe et au mot. Les états qui appellent un geste (erreur, en attente, refusé) gardent leur
  encre de registre sur le TEXTE, jamais un fond — doctrine `.pers-warn`, déjà appliquée aux
  lignes de documents.
- **Le point cède la place à un glyphe** (« l'icône nuage et validé/en cours/croix, peux-tu
  harmoniser l'affichage ? »). Le pied posait deux idiomes côte à côte : des glyphes tracés de
  14 px pour le stockage et les documents, un disque plein pour la synchro. `SYNC_ICO` donne un
  glyphe par état (✓ synchronisé, ↺ en cours, ⏸ hors-ligne, △ erreur, 🔒 en attente) au même
  gabarit et dans la même colonne. Le nom est CALCULÉ, donc hors portée de `check-icons` : les six
  sont vérifiés à la main, et c'est écrit sur place.
- **Les deux commandes deviennent des boutons discrets** (demande de l'auteur pour la voie
  étroite). En lien, elles flottaient dans un bloc d'état : rien ne disait qu'on pouvait taper, et
  la cible se réduisait à la longueur du mot. Surface TONALE sans contour, 36 px — la grammaire
  des boutons du fichier est respectée (le pointillé reste à « créer », le contour plein à
  « gérer ») : ici c'est une NAVIGATION, donc la forme la plus effacée qui soit encore un objet.
  COÛT ASSUMÉ ET MESURÉ : à 390 px les deux libellés entiers ne tiennent pas sur une rangée
  (339 px demandés pour 354 disponibles à 13,5 px, et il faudrait descendre à 12 px pour les
  faire tenir — au prix d'un palier de plus dans l'échelle typographique du pied). Elles
  s'empilent donc, 78 px au lieu de 32. Compensé en partie par l'interligne du pied ramené de 4
  à 2 px, les rangées d'état étant déjà hautes de 32.

**Deux corrections d'affichage venues du terrain, dans la même version.** (1) *« Espacement
toujours pas bon »* : un `gap` unique de 2 px se lisait 4, 12 puis 19 px selon les rangées qu'il
séparait, parce qu'elles ne faisaient pas la même hauteur (20 px pour la version, 32 pour les deux
commandes) et que le blanc interne d'une rangée S'AJOUTE au gap. **Un interligne ne se règle pas
en pixels, il se règle en rendant les rangées comparables** : les trois font 32, le gap tombe à 0,
et le seul écart qui subsiste (6 px) sépare les deux REGISTRES — commandes et état. (2) *« Les
glyphes seuls tout à gauche, il manque quelque chose »* : les rangées d'état occupaient toute la
largeur, si bien qu'à 574 px comme à 1194 le chevron partait se coller au bord droit en laissant
plusieurs centaines de pixels de vide entre lui et sa phrase — la marque, à l'autre bout, restait
seule au bord. En `fit-content`, le groupe marque · texte · chevron redevient un OBJET, du même
retrait (12 px) et du même rayon (10) que les boutons du dessus ; la surface tonale n'apparaît
qu'au survol, l'état restant du texte. Toutes les marques du pied tombent alors sur la même
verticale, boutons compris.

**A273. TROIS VERTICALES DANS LA COLONNE, ET TROIS SEULEMENT.** Mesuré sur la colonne livrée :
quatre libellés démarraient à quatre abscisses — 24 px (bibliothèque, aucune marque), 41
(catégorie, pastille 9 + 8), 45,5 (commande, le ⇄ faisant 13,5 px là où le glyphe en fait 14), 46
(ligne d'état, le pied gardant 2 px de rembourrage hérité de sa vie en bas de page). Chaque
famille posait son texte là où sa marque tombait ; rien ne tenait une verticale. Le remède n'est
pas de régler chaque cas mais une **colonne de marque de largeur fixe**, portée par TOUTES les
rangées et laissée VIDE quand il n'y a rien à y mettre : marque à 24, libellé à 44, nombre au bord
droit. Une seule fabrique (`hsRow`) les émet.

- **Le nombre passe APRÈS l'acte.** C'est ce qui aligne les deux colonnes de comptes (176 contre
  218) sans réserver la case du crayon sur les rangées qui n'en ont pas — réserve écartée à la
  relecture (A269). Un bouton n'en contient pas un autre : le compte vit donc dans l'ENVELOPPE,
  qui porte désormais le fond, la sélection et le rembourrage droit. Le harnais doctrine lisait le
  compte dans le bouton ; il a été mis à jour avec la structure.
- **Une seule hauteur, un seul filet.** Toutes les rangées à 32 px ; `.hs-sep` et le filet du
  socle font la même largeur (la boîte de contenu de l'étage), avec 12 px de part et d'autre.
- **Les deux pavés pleine largeur deviennent des rangées** (`.hs-wrap.quiet`). La grammaire
  pointillé = créer / contour = gérer vaut dans un ÉDITEUR ; dans une colonne de navigation elle
  donnait le plus de poids visuel aux deux actions les plus rares et coupait la seule liste qu'on
  parcourt. Décision d'auteur, sur maquette.
- **Le socle suit le contenu** (`flex:0 1 auto` sur le défileur) : un trou de 120 px au milieu se
  lit comme un défaut. Dès que la liste déborde, le défileur prend la place et le socle revient en
  bas. Contrepartie assumée : la hauteur de l'état bouge quand on ajoute une bibliothèque.

**A274. LE SOCLE SE REPLIE EN UNE LIGNE (S1), ET SES INTITULÉS DISENT CE QU'ILS DISENT.** Le socle
empilait CINQ rangées de même forme sur 216 px — un tiers de la colonne — pour dire deux commandes
et un état qu'on consulte une fois avant de partir. Cinq rangées identiques annoncent cinq choses
de même nature ; il y en a deux. Au nominal, les quatre lignes d'état se replient donc en une
seule, dépliable SUR PLACE (règle 11).

- **Ce qui force l'ouverture est la liste des faits ACTIONNABLES, et elle seule** : documents
  manquants ou index en échec, synchro en erreur / en attente / refusée, stockage presque plein.
  « Hors-ligne » et « synchro en cours » n'y sont pas — ils se résolvent seuls, et les états de
  synchro qui appellent un geste lèvent DÉJÀ `#syncErrNotice` en tête de liste. On ne replie
  jamais un état actionnable.
- **Le dépliant est SUBORDONNÉ** : ses rangées démarrent sous le TEXTE de la synthèse (44/64) et
  non sous sa marque — sans quoi rien ne dit qu'elles en découlent. Le retrait n'existe que
  lorsque la synthèse existe : forcé ouvert, le dépliant n'a pas de parent au-dessus de lui.
- **Les intitulés, réécrits courts** (demande de l'auteur : « très clair et concis »). « Prêt hors
  ligne » a été essayé puis abandonné — il se lisait comme un état de CONNEXION (« je suis en
  ligne ou pas ? ») ; « Utilisable sans réseau » aussi, parce que la synthèse couvre trois faits
  distincts dont la recherche dans les documents, qui n'a rien à voir avec le réseau. Reste
  **« Tout est prêt »**, qui dit exactement ce que la ligne garantit : rien ne demande d'action.
  Le numéro de version l'accompagne, replié compris — c'est ce qu'on demande à un utilisateur au
  téléphone, et le dépliant serait un geste de trop. Les lignes du dépliant suivent :
  « 15 documents sur l'appareil », « Recherche dans les documents », « 3 documents à télécharger »,
  « Indexation en cours (4) », « 2 documents sans texte », « 1 document non indexé ».
- **Les actions des rangées d'état passent à 11 px** (`.stg-act`) : un `.tlink` de 13,5 px faisait
  un mot deux fois plus gros que sa phrase et cassait le bloc. La cible garde ses 32 px.

**A275. LE TYPE À CRÉER N'EST PLUS LE FILTRE DE LA LISTE.** Signalé à l'usage : « Créer → aide
cognitive et/ou protocoles mène à une vue filtrée qui n'est plus censée exister ». `openCreateFor`
et le sélecteur du dialogue appelaient `setSection` depuis la v4.4.2 — c'était juste tant que
l'accueil ÉTAIT une liste par type : choisir ce qu'on allait créer et filtrer ce qu'on regardait
étaient alors le même geste. Depuis la v5.18 la liste est l'UNION et le type est un filtre de
recherche : le dialogue filtrait donc la vue DERRIÈRE lui, sans que rien ne l'ait demandé. Il a
désormais son propre cran (`_crtKind`), initialisé au type filtré s'il y en a un, jamais écrit.

⚠ **DEUX HARNAIS S'APPUYAIENT SUR CE DÉFAUT**, et c'est le vrai enseignement. (1) `audit-doctrine`
affirmait `state.section===k` après un clic sur « Créer » : il gardait l'ancien contrat, il a été
réécrit sur le cran VISIBLE du sélecteur, avec un témoin de plus — « sans filtrer la liste
derrière le dialogue ». (2) `audit-zoom-scroll` cliquait `.seg-btn` en croyant basculer de section
et attrapait celui du dialogue « Créer » ; la liste des protocoles étant vide dans le jeu
d'exemple, aucune fiche ne s'ouvrait et ses deux témoins mesuraient l'ACCUEIL en croyant mesurer
une LECTURE. Le harnais dit maintenant ce qu'il couvre, et la lacune (pas de fiche assez courte
dans le jeu d'exemple pour distinguer « défilement dans le vide » de « page plus longue que la
fenêtre ») est écrite sur place. Un contrôle qui passe parce qu'il ne mesure rien est pire qu'un
contrôle absent.

**A276. DIRE CE QU'EST UNE AIDE COGNITIVE, ET UN PROTOCOLE, LÀ OÙ LA QUESTION SE POSE.**

- **Le dialogue « Créer » le dit** (une phrase par nature, sous le sélecteur), depuis la MÊME
  source que les bandeaux (`EMPTY_INTRO.dlg`) — jamais un texte recopié.
- **Les deux bandeaux de bibliothèque vide fusionnent en un seul.** Ils avaient été écrits quand
  l'accueil était filtré par type : chacun paraissait seul, en réponse à « cette liste-là est
  vide ». Depuis l'union, ils s'empilaient toujours ensemble — deux titres « Aucune… », deux
  boutons pleins — et la question qu'on se pose vraiment (« quelle est la différence ? ») n'avait
  de réponse nulle part. Un seul bandeau pose les deux natures CÔTE À CÔTE, donc comparables, et
  garde un seul bouton plein (grammaire : une seule action primaire ; le second est en contour).

**Trois corrections venues du terrain dans la même passe.** (1) Le rappel du raccourci affichait
`⌘K` sur tous les systèmes : le libellé suit désormais la plateforme (`Ctrl K` hors Apple) et le
champ réserve la largeur du PLUS LONG des deux, la place réservée ne devant pas dépendre du
clavier de celui qui regarde ; le gestionnaire, lui, acceptait déjà `⌘`, `Ctrl` et `/`. (2) En
voie étroite, « Rangé par » et « Sélectionner » passent SOUS l'intertitre « Répertoire » : ils
gouvernent cette liste, ils ne la précèdent pas. (3) Les 18 px qui séparent le contenu de
l'en-tête tombaient sur `#syncErrNotice`, présent mais MASQUÉ — donc sur une boîte sans hauteur,
et le premier bandeau touchait l'en-tête.

**A278. LE HALO SE VÉRIFIE EN CAPTURE, PAS SEULEMENT EN GÉOMÉTRIE** (audit design externe
v5.19.0, mesuré sur l'app servie).

- **Le défaut** : le bouton « filtres : aides » (`.dir-hf`, ligne Répertoire) mesurait 72×18 px
  et sa cible reposait sur un halo `::after` de −8 px — or ce halo était ROGNÉ par la chaîne
  d'ancêtres en `overflow:hidden` qui ellipse les longs résumés : `elementFromPoint` à 5 px du
  rectangle rendait `.dir-wrap`, jamais le bouton. Zone réelle 72×18, sous les 24 px de
  WCAG 2.5.8.
- **Le trou du garde-fou, plus grave que le défaut** : `audit-a11y` lisait les insets du halo et
  créditait la surface SANS vérifier qu'un tap y atteint l'élément — tout halo rogné par un clip
  passait vert. La famille exacte de la leçon v4.31.1 : un contrôle aveugle au défaut qu'il
  prétend couvrir ne prouve rien.
- **Les deux réponses** : (1) le dessin porte lui-même les 24 px (`.dir-hf` en inline-flex,
  `min-height:24px` — la rangée `.dir-h` absorbe les ~6 px ; le halo ne reste qu'en bonus là où
  le clip le laisse vivre) ; (2) la sonde cibles d'`audit-a11y` teste désormais la CAPTURE : pour
  tout élément dont la conformité repose sur le halo, `elementFromPoint` au milieu de chaque côté
  à halo non nul doit rendre l'élément — sinon « halo rogné, capture perdue ».
- **Deux garde-fous de la sonde elle-même**, appris à la première passe : une GARDE D'OCCLUSION
  (si le centre même de l'élément n'est pas atteignable — fenêtre ouverte par-dessus — le halo
  n'est pas le sujet : la première passe rougissait sur le chrome DERRIÈRE la feuille Plan, un
  rouge fabriqué) ; et hors fenêtre on S'ABSTIENT, on ne fabrique pas de verdict.
- **Et une surface d'état nouvelle, « filtres posés »** : le déclencheur `.dir-hf` n'existe
  qu'avec un filtre actif — il ne vivait donc dans AUCUNE des surfaces mesurées (un défaut hors
  scope n'est pas un défaut absent, leçon v4.75.0). Le filtre se pose par l'état que l'app lit
  elle-même (`state.section`), puis `render()` décide.
- **Preuve rouge→vert** : sonde ajoutée AVANT le correctif — passe rouge sur le seul témoin visé
  (deux thèmes), puis correctif CSS, passe verte (541/541).

**A279. LA FEUILLE QUI DÉPASSE LE DIT** (même audit, mesuré : 904 px visibles pour 1131 de
feuille à 1280 — la colonne « NE PAS OUBLIER » coupée en plein mot, et les barres de défilement
en incrustation ne laissent aucun indice tant qu'on ne défile pas).

- **Ce qui ne change PAS** : l'ajustement d'office à l'ouverture reste refusé, pour les raisons
  déjà écrites (k ≈ 0,28 à 390 px ramène toute cible sous 13 px ; même à 1280, k = 0,775 ramène
  44 px à 34 — cf. le commentaire de `svZoom` et l'épitaphe de `.pg-wide`). L'échelle reste un
  geste.
- **Ce qui change** : la coupe se DIT. Un mot dans la barre d'échelle — « la feuille dépasse à
  droite — défiler, ou “⤢ Ajusté” » — en encre seconde (pas un registre d'alerte : la feuille
  n'a rien de faux, elle a un bord), posé/levé par `svApplyZoom` sur la MESURE du défileur
  (`scrollWidth > clientWidth + 4`), donc juste à chaque échelle, à chaque largeur, dans les
  DEUX logements de la feuille (onglet Page et fenêtre « Tableau » — svApplyZoom est déjà leur
  passe commune de mesure). Il vit dans la barre d'échelle parce que les gestes qui y répondent
  y vivent aussi, « ⤢ Ajusté » en tête. `flex-wrap` sur la barre : en voie étroite le mot passe
  à la ligne, il ne pousse jamais un bouton hors de portée.
- **Vérifié aux trois états** : annoncé à l'ouverture (904/1131), tu après « Ajusté » (80 %),
  de retour à 1:1.
