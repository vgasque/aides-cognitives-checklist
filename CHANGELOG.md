# Journal des modifications

## [5.9.0] — 2026-08-13
### L'atelier d'import va jusqu'à la question destructive

`5.8.0` avait posé le grain — l'entité — et `5.8.1` l'avait tenu partout. Restait le geste que
l'atelier existe précisément pour éclairer : **remplacer**. La rangée annonçait qu'une entité était
« déjà présente » sans dire ni **laquelle des deux versions est la plus fraîche**, ni **ce que
remplacer coûterait**. Doctrine : `AGENTS.md` A131 et A132.

- **La rangée dit laquelle des deux est la plus récente** — « le fichier est plus récent »,
  « votre version est plus récente », « même version ». Le second cas est le seul où remplacer
  **perd du travail** : il prend le registre ATTENTION, en texte et avec son glyphe, jamais un
  aplat. Aucun champ nouveau : `updatedAt` **est** la révision, celle-là même dont le compte rendu
  se sert déjà pour dire sur quelle version un soin a été conduit.
- **⚠ Et l'horodatage est lu *avant* la normalisation**, parce que celle-ci en pose un quand il
  manque — un fichier ancien se serait donc annoncé « plus récent » que tout ce qu'on possède, sur
  la seule question destructive du parcours. Sans date des deux côtés, la rangée **se tait** plutôt
  que de deviner.
- **« Comparer » déplie ce que remplacer changerait**, ligne à ligne : ce que le fichier
  apporterait, ce qu'il emporterait. C'est le comparateur de « Versions », inchangé — pas un
  second, qui finirait par répondre autre chose sur la même paire d'objets. Les **références** ont
  leur propre aplatissement (leur corps est du texte, ses lignes sont ses unités) : sans lui, la
  moitié de la bibliothèque n'aurait eu aucune réponse à la même question.
- **Ce qui n'est pas fait, et pourquoi** : descendre au **grain du bloc**. Un bloc ne porte que des
  identifiants d'items d'un pool partagé et se relie aux autres par ses branches — en importer un
  sous-ensemble produirait des blocs vides et des branches qui ne mènent nulle part. Un algorithme
  partiel n'est pas un algorithme allégé, c'est un algorithme cassé.

## [5.8.1] — 2026-08-13
### L'atelier d'import, jusqu'au bout : le filtre atteint tout ce qui s'écrit

`5.8.0` avait posé le grain de l'import — l'entité — sans le tenir partout : trois choses
raisonnaient encore **en bloc** derrière l'atelier, et la rangée taisait ce qui permet de décider.
Doctrine : `AGENTS.md` A130.

- **Les catégories suivent la sélection.** Elles entraient *toutes*, y compris celles que seules
  les entités décochées employaient : on repartait avec des catégories vides dans son rail, créées
  par un import qu'on venait justement de restreindre. La règle qui en sort est plus large que le
  cas : *le filtrage doit atteindre tout ce qui s'écrit, pas seulement les entités.*
- **La question destructive annonce la sélection, pas le fichier** — « remplacé(e)s par les
  **n éléments cochés** ». Depuis l'atelier les deux ne sont plus la même chose, et c'est la seule
  question destructive du parcours : y annoncer le fichier ferait croire qu'on récupère ce qu'on
  vient d'écarter.
- **« ⟳ déjà présent » se dit sur la rangée, avant la question « Doublons ».** La rangée porte le
  fait ; le sort reste décidé par la question groupée. Elle n'apparaît **que là où la collision
  peut avoir lieu** — identifiants conservés, donc même espace : sur un fichier venu d'ailleurs ils
  sont régénérés à l'écriture, et annoncer un doublon que l'écriture ne verra pas serait un
  mensonge. *Un contrôle « remplacer / garder les deux » par rangée a été écarté* : décocher porte
  déjà le grain, tandis que ce choix-là est une stratégie, globale par nature.
- **La rangée dit ce que l'entité embarque**, dans les mots de l'écran d'entrée : « 2 blocs ·
  1 minuteur · 1 complication déclarée ». C'est la seule chose qui distingue un algorithme complet
  d'une ébauche sans ouvrir le fichier. Une phrase, **deux lecteurs**, donc un seul calcul ; seuls
  les seuils diffèrent, et chacun est motivé.
- **Détail de plancher** : à 320 px les deux gestes de l'atelier tenaient sur une ligne mais s'y
  cassaient chacun en deux. La rangée enroule désormais plutôt que les mots — les boutons restent
  côte à côte à 44 px, c'est le compte qui passe dessous.

## [5.8.0] — 2026-08-13
### « Voir avant d'écrire, revenir sans chercher »

Fin du lot v5.7 : son dernier item de plan — **l'atelier d'import** —, les deux retours au soin
qui manquaient, et les deux correctifs *à zéro pixel* que le **refus** du « plan de vol » sur
l'écran de crise avait révélés. Comme le lot précédent, rien ici ne déduit quoi que ce soit d'un
paramètre patient. La doctrine est dans `AGENTS.md` § « Lot v5.7 » (A124 à A129).

**Ce qui entre dans la bibliothèque**

- **L'atelier d'import — le grain n'est plus le fichier, c'est l'entité.** Un `.json` ou un `.zip`
  entrait EN BLOC : on répondait à trois questions (destination, fusion, doublons) sans avoir
  jamais vu ce qu'il contenait. Sur un export de bibliothèque, c'est dix-huit aides qu'on acceptait
  sur la foi d'un nom de fichier, et le seul recours après coup était de les supprimer une par une.
  L'ordre est renversé : **d'abord ce que l'on importe, ensuite où**. Une rangée par entité — type,
  titre, **état déclaré par le fichier**, ce qu'il reste à relire, nombre de PDF —, tout coché au
  départ : l'atelier sert à *retirer*, il ne demande pas de tout re-cocher.
- **Le filtrage précède toute écriture**, et c'est le point dur : les deux listes sont réduites à
  la sélection *avant* les questions, donc avant `migrate`, `persist` et surtout `importAtts`. Un
  binaire du `.zip` n'entre **jamais** pour une entité décochée — non par un filtre posé après
  coup, mais parce que la liste filtrée est la seule qui existe ensuite.
- **L'état entrant est préservé** : les trois portes forçaient « Brouillon ». C'était un proxy de
  « vous n'avez pas encore relu ceci » ; l'atelier montre désormais cet état *avant* l'écriture,
  rangée par rangée. Le coût du forçage était réel — **restaurer une sauvegarde ramenait dix-huit
  aides validées en brouillon**, donc hors de l'accès de crise (un brouillon ne s'épingle pas et
  reste masqué aux lecteurs d'une bibliothèque partagée). L'objection est nommée dans la doctrine :
  ce qui protège du « Validée » non relu, c'est la rangée qui le dit, plus le prompt IA qui impose
  `"status":"draft"` — contrat vérifié par `audit-prompt`.
- **La pastille « △ n »** est le *même* calcul que le volet « Relecture » de l'éditeur : deux
  comptes écrits séparément divergeraient. Elle ne conditionne rien — une remarque de relecture
  n'est pas un refus.
- Trois défauts trouvés sur le trajet et corrigés : un fichier ne portant **que** des références
  répondait « Import interrompu » alors qu'il était parfaitement valide ; un contenu vide disait
  « 0 fiche importée », une phrase qui ne désigne pas sa cause ; les questions comptaient le
  *fichier* au lieu de la *sélection*.

**Revenir au soin**

- **Rouvrir l'application pendant une session vive dépose dans le soin**, plus sur l'accueil : un
  tap de moins au seul moment où l'on n'en a aucun à donner. Trois bornes — une seule session
  vive, dix minutes sans le moindre geste au plus, et jamais quand un lien d'invité est présent.
  Le « ‹ » de l'en-tête ramène à la bibliothèque : personne n'est enfermé.
- **La barre de retour au bloc courant** est affinée sur trois signalements : elle ne **clignote**
  plus au re-rendu (un nœud détaché n'est pas « hors zone » — l'observateur surveillait l'ancienne
  carte), elle prend la **boîte de la barre flottante** au lieu de celle de la page, et elle
  **s'empile** sur le volet du dock au lieu de le recouvrir, en redescendant d'elle-même à sa
  fermeture.
- **Le passage qu'on interrompt se replie.** Après une complication reprise, deux cartes ouvertes
  du même bloc se suivaient avec les mêmes étapes. La navigation, elle, était juste — un témoin
  écrit *avant* toute correction l'a tranché. L'invariant du journal n'est pas touché : on ne
  transforme pas le passage en chip, on pose le repli manuel, et un tap rouvre l'ancienne carte.

**Lire l'état**

- **Un minuteur armé puis mis en pause cesse d'être muet.** Il ne figurait dans aucun segment de
  la capsule et n'avait pas d'alarme à venir : il n'existait donc nulle part sans ouvrir le volet,
  alors qu'il porte un temps qui a cessé d'avancer. « ⏸ n en pause » rejoint le rappel du quai.
- **La progression d'un jalon sort de son bloc** : « Chocs 2/3 » disparaissait dès qu'on était
  ailleurs, pendant que le compte, lui, continuait d'avancer. Elle rejoint le volet, en quatrième
  famille — une ligne, pas une carte, et aucun geste n'y est posé.
- **Le plan de vol est refusé sur le chrome de crise et livré dans le moniteur.** Éprouvée contre
  le contenu réel des fiches, la proposition ne gardait qu'un bénéfice rare pour ~52 px permanents
  dans une colonne dont le budget est tenu à 30 % ; sur un afficheur qu'on lit à deux mètres, les
  pixels sont gratuits et une bande de temps est la bonne forme. Trois registres de trait, et l'on
  ne peut pas confondre un fait avec une promesse : point = c'est arrivé, trait plein = c'est daté,
  tiret = c'est projeté si rien n'est touché. Un jalon compté n'y entre jamais — le dater
  reviendrait à prédire le rythme auquel l'équipe va agir.

**Géométrie, densité, finitions**

- **En exercice, le volet recouvrait la capsule de 63 px** : le bandeau du placard vit dans le
  flux et pousse le quai vers le bas, alors que la position du volet se dérivait d'une *somme de
  hauteurs*. Il suit désormais le bas **réel** du quai — correctif borné au volet : partout
  ailleurs, une géométrie de chrome continue de ne jamais dériver d'une position de défilement.
- **En session, le haut de page cesse d'être du vide sous le quai** (18 → 8 px à 390, 24 → 14 à
  1280) : le quai ferme déjà le haut, cet écart n'y sépare plus deux objets.
- **La ligne de reprise après interruption** est refaite : une rangée *dans* la carte, un nombre
  qui **vit** (un nombre figé qui annonce « il y a 6:12 » ment dès la minute suivante), et une
  sortie explicite à 44 px.
- **Les cartes épinglées prennent le rythme du répertoire** — elles s'étalaient sur toute la
  largeur (976 px contre 320) pour l'accès le plus rapide du produit.
- **Le parcours inerte se resserre en deux passes** (416 → 368 px avant le soin, 435 → 411 en
  session) : les marges cèdent, jamais le contenu. Le plancher est dit — 32 px hors crise, et en
  session un **pas** de 44 px que la règle des cibles rend non négociable.
- **Balayage des glyphes littéraux** : six sites passent aux tracés `uiIcon`, et les deux familles
  qui restent en texte sont nommées (le vocabulaire abrégé des renvois, les glyphes de commande du
  dock).

**Témoins**

Deux entrées neuves : la section `A129 · l'atelier d'import` d'`audit-doctrine` — vrai `.zip`
fabriqué par `zipBuild`, entré par le point d'entrée réel, vérifiée capable d'échouer (filtrage
neutralisé et forçage réintroduit → trois rouges) — et la surface `atelier d'import` d'`audit-a11y`,
qui construit son cas avec les deux natures **et** une pastille : sans elles, la moitié des objets
de la rangée ne serait pas mesurée.

## [5.7.0] — 2026-08-13
### « La bonne information, au bon moment, au bon endroit »

Audit transverse passé à trois tests : le **LIEU** (l'information est-elle là où le geste a
lieu ?), le **MOMENT** (arrive-t-elle avant la décision ?), le **GESTE** (le plus fréquent est-il
le moins cher ?). **Rien dans ce lot ne déduit quoi que ce soit d'un paramètre patient** : chaque
apport est une soustraction d'horodatages, un comptage de cases, ou un déplacement d'information
déjà présente vers l'endroit où elle décide. La doctrine complète est dans `AGENTS.md`
§ « Lot v5.7 » (A113 à A123).

**Pendant le soin**

- **La barre de retour au bloc courant.** Trois mécanismes ramenaient déjà au soin et aucun ne
  couvrait le cas le plus fréquent : `landOnBout` ne joue qu'à la réentrée dans la fiche,
  `ovAdvanceRender` qu'au geste d'avancement, `cxScrollTo` qu'à l'entrée sur complication. On
  défilait pour relire une étape ou vérifier une dose, et l'on remontait en cherchant la carte à
  bordure bleue. Une zone flottante **bornée** — sur le précédent déjà accepté du geste d'entrée
  (v4.73.0) — n'existe que tant que la carte du bloc courant est *entièrement* hors de la zone
  utile, nomme sa destination et s'efface d'elle-même. Elle ne défile jamais toute seule.
- **Le retour d'interruption restitue la conscience de situation.** Vérifié : zéro occurrence d'un
  « temps depuis le dernier geste » dans le fichier — les cinq écouteurs de `visibilitychange`
  persistaient, reprenaient l'audio, redemandaient la veille, mais aucun ne disait à quelqu'un qui
  revient depuis combien de temps il n'était plus là. Une ligne, en tête de la carte du bloc
  courant, au-delà de deux minutes d'absence, effacée **au geste suivant** — jamais après un délai.
- **Un compteur dit « il y a », pas seulement « à ».** La trace disait l'instant du dernier
  incrément ; en réanimation la question est toujours « ça fait combien de temps ? ». Les deux
  désormais : le T+ se relit, le « il y a » décide. Vivant, sans re-rendu, **sans aucun seuil** —
  un seuil serait un jalon, et les jalons sont un champ d'auteur. Le chiffre pousse au tap
  (130 ms, `transform` seul, remplacée et jamais mise en file).
- **L'imminence d'un minuteur est un état, et le tri devient vivant.** L'ordre suit le temps
  restant, l'alarme passe devant ; un minuteur qui entre dans ses vingt dernières secondes est
  **marqué** — glyphe △ et encre ambre, sans aplat ni battement : l'aplat reste réservé à ce qui
  exige une action maintenant, le battement est la grammaire de l'alarme. La réorganisation est un
  FLIP en `transform` pur (180 ms). **Rien ne bouge sous un doigt posé**, ni pendant les 1,2 s qui
  suivent le geste : assez pour lire la réponse de la carte qu'on vient de toucher. Non bloquant
  par construction — le délai ne suspend que la réorganisation.

**Avant et après le soin**

- **« Terminer la session ? » dit ce qui reste ouvert** — deux lignes de faits comptés, au seul
  instant où ils servent encore. « Terminer » reste rouge plein et actif : une checklist annonce
  son incomplétude, elle n'interdit pas de la quitter. Ni score, ni pourcentage, ni « conformité ».
- **Ce que la fiche embarque se dit avant qu'on entre.** En voie étroite — la cible principale — un
  minuteur à cycles écrit par l'auteur était invisible tant qu'on n'avait pas démarré. Une ligne
  dérivée : « 6 blocs · 2 minuteurs · 1 complication déclarée ». Rien à dire, aucune ligne.
- **Une aide révisée depuis votre dernier passage le dit.** Dans une bibliothèque partagée, un
  collègue révise une aide qu'on croit connaître par cœur. La ligne ne conditionne rien et ne dit
  pas *ce qui* a changé — « Versions » est dans le menu ⋯ pour cela.
- **Le compte rendu donne l'écart, et rien d'autre.** Une colonne Δ entre deux gestes du **même**
  objet, nue : ni moyenne, ni intervalle cible, ni couleur qui vire — ce vocabulaire ferait
  basculer le document du côté de l'évaluation par le logiciel.

**Pour l'auteur**

- **La relecture cesse de ne signaler que des fautes : elle propose.** Les six détections
  existantes étaient toutes des manques. Trois détecteurs lisent désormais le texte *de l'auteur* :
  une cadence (« toutes les 3 min », « à 5 min », « q4h ») propose un minuteur à cycles **avec la
  période lue dans sa phrase** ; « renouveler / seconde dose / nouveau choc » propose un compteur ;
  une étape vitale sans aucune ★ propose le memory item. Rien n'est jamais créé automatiquement, le
  texte n'est jamais réécrit, le compteur naît **sans nom** — deviner un mot serait la
  dégénérescence de « PA 2 » sous un autre visage. Un seul chemin de création (`edAdd`), et un refus
  ne revient pas de la séance.

**Deux propositions retirées après vérification, et c'est la même leçon.** Le téléchargement de
fond des documents existe déjà, systématique et pour toute la bibliothèque — la proposition aurait
*restreint* aux épinglées une garantie volontairement universelle. Et le virage au vert de
« Continuer » est déjà entier ; il n'y manquait qu'un fondu, or le libellé bascule au même instant :
on aurait obtenu une couleur qui s'attarde sous des mots qui ont déjà sauté.

**Décor et garde-fous.** La fiche d'exemple ACR porte un second minuteur déclaré — le
réordonnancement vivant n'avait sinon aucun cas à rencontrer, et un témoin écrit sans cas est un
vert qui ne mesure rien ; il est à relance manuelle, un second minuteur *cyclique* faisant
disparaître le cas d'un autre témoin (`cycleHint`). Quatre sections entrent dans `audit-doctrine`
(P1, Q2, P4b, Q1), toutes **vérifiées capables d'échouer** — défauts réintroduits, 9 rouges au
total, fichiers restaurés à l'octet. Le cliquet `pointer-events:none` de `check-anim` passe de 18 à
19, motivé sur place. 47 témoins purs neufs (1040 au total, sur les deux moteurs).

## [5.6.0] — 2026-08-09
### Refonte complète du design — direction « verre clinique, mat »

Refonte menée avec Claude Design (phases 0 à 6 : audit de l'existant, directions explorées,
convergence, design system, écrans qui font foi, passation en sept lots). Les maquettes livrées
sont la référence d'implémentation ; ce qui suit est ce qui a été porté dans le monofichier, avec
les décisions consignées — la doctrine complète est dans `AGENTS.md` § « Refonte v5.6 ».

**TROIS MATIÈRES, TROIS NATURES.** Sombre (`--sys`) = SYSTÈME : la capsule d'état et le dock, les
deux seuls objets sombres du produit — trouvables sans lire. Blanc (`--work`) = TRAVAIL : carte,
feuilles, éditeurs ; seule matière qui projette une ombre. Gris (`--amb`) = AMBIANCE. La
séparation commandes/affichage de l'ECAM passe désormais par la MATIÈRE, plus par des bandes et
des filets empilés — ce qui **rouvre la v4.25.0** en gardant son esprit et en inversant sa forme.

- **Lot 1 — tokens.** Nouveau bloc `:root` (matières, encres, registres, échelle typographique
  fermée à sept crans `11 / 12 / 13,5 / 15 / 17,5 / 21 / 24`, rayons `8 / 10 / 12 / 14`, une
  seule ombre, cibles, mouvement) ; les anciens noms deviennent des ALIAS, aucune règle CSS n'a
  eu à changer pour que le fichier compile. **Un seul ambre** (`--verify` et `--alert` fusionnent
  en `--warn`) et **un seul rouge**. Nuit redessinée en OLED GRIS (`#0d0f13`) : sur OLED, le noir
  pur fait « trou » et le halo des textes clairs fatigue. Trois fontes vendorisées (Manrope
  variable 500-800, IBM Plex Mono 600/700, 45 Ko au total, précachées) : le SERIF ne sort que sur
  un titre de fiche, le MONO que sur une valeur, Manrope tient tout le reste.
  **⚠ TROIS TOKENS NE SONT PAS DES ALIAS, et les harnais l'ont prouvé** : `--paper` reste un
  blanc FIXE (aliasé sur la matière travail, le QR se peignait en encre sombre sur fond sombre —
  indéchiffrable, et le défaut ne se serait vu qu'au moment de scanner) ; `--shadow-up` garde son
  décalage négatif ; `--ctl-line` tient 3:1 là où le `--line-strong` du système n'en fait que 1,6
  — WCAG 2.2 § 1.4.11 vise les bordures de COMPOSANT, c'est-à-dire la case qu'on vise avec des
  gants. Le bloc de dérivation `color-mix` de la direction A est retiré : les valeurs tonales du
  nouveau système sont des accords qu'aucun mélange ne reproduit.
- **Lot 2 — chrome de crise : deux objets, deux natures.** `#crisisBand` (comme bande),
  `#crisisCtrl` et `#crisisDock` (comme rangées) laissent la place à une **capsule d'état**
  (matière système, gabarit constant de 50 px, tap = volet minuteurs/compteurs/journal) et à un
  **dock bas de quatre touches** (⤢ Tout voir · ▤ Consulter · ⚡︎ Complications · ⏱ Noter l'heure).
  Chrome haut **175 → 131 px** à 390 px, trois `border-bottom` empilés en moins, et les quatre
  gestes de session sous le pouce. En-tête à trois zones ancrées (A14) : le **sur-titre
  « ■ MODE CRISE » passe AU-DESSUS du titre** — accolé au nom de la fiche, le statut se lisait
  comme un fragment de ce nom — et la pilule `#hdrCrisis` est purgée (un seul énoncé du mode).
  `fitCtrlRow` disparaît avec la rangée qu'elle ajustait ; `syncHdrScroll` reste, parce que
  `--hdr-h` et `--stick-top` nourrissent le rail A→Z, le rail de lecture, `stickBase()` et le
  `scroll-margin` qui empêche le masquage total d'une cible d'ancre (exigence AA).
- **Lot 3 — carte de travail et journal.** L'étape critique se **MARQUE** (case rouge + ⚠ + corps
  17,5 px + cadence mono ambre) et ne prend plus **ni cadre ni aplat** : mesuré à l'usage, à cinq
  étapes l'aplat happait l'œil et détruisait la lecture de la séquence — l'aplat coloré est
  désormais réservé à l'alarme active, et il n'y en a qu'un à l'écran. « ICI » quitte la carte
  (trois signaux l'y désignaient déjà, `aria-current` compris) et ne vit plus que dans une LISTE.
  L'historique du journal se replie en **une ligne-bilan qui se tire** (« ⌄ fait · ✓ n passages ·
  a→b ») dès qu'elle existe : ~11 objets à l'écran contre 25.
- **Lot 4 — rail et cockpit.** Cartes de minuteur à gabarit FIXE entre veille et échu (A9 : un
  changement d'état non commandé ne déplace jamais rien — le piège n'est pas la structure, c'est
  le libellé qui passe sur deux lignes). **A15 : « Consulter » n'évince plus le bloc au cockpit**
  — à partir de 1200 px la référence s'ouvre dans la colonne d'état, le bloc reste sous les yeux
  et cochable ; sous 1200 px elle reste une excursion à retour nommé.
- **Lot 5 — accueil.** Navigation uniformisée : le sélecteur « A–Z | Catégories » choisit la CLÉ
  DE GROUPEMENT de la même liste, et le rail droit est le MÊME index dans les deux modes (lettres
  ↔ pastilles de catégorie) — on ne perd jamais de fiche en changeant de clé, c'est ce qui
  distingue un groupement d'un filtre. Le résumé des filtres actifs rejoint l'en-tête de section.
  La session vive devient le seul objet sombre de l'accueil.
- **Lots 6 et 7 — fenêtres, documents, éditeur.** Re-peau par les tokens ; les règles nommées du
  plan étaient déjà tenues (listes cochables jamais barrées, session terminée = archive sans
  matière système ni dock, exercice = placard permanent jamais filigrane).

**Volets système — doctrine d'occultation consignée (V1-V3).** Un volet ne s'ouvre que sur tap
d'une touche du dock ; fermeture triple (re-tap, ✕, tap hors volet) plus le retour système ;
l'alarme reste TOUJOURS en vue (capsule en haut, volets en bas — règle FMA de l'ECAM) ; hauteur
plafonnée à 45 % et l'interruption s'annonce en tête (AC 120-71B §5.5). **⏱ l'heure prime** : le
tap horodate immédiatement, le volet n'est que la nomination facultative. **⚡︎ bifurcation
annoncée** : nom, condition d'entrée et destination avant le tap — et **à un seul événement il n'y
a pas d'index**, la touche porte son nom et l'on entre d'un tap.

**Ce que les harnais ont attrapé, et qui n'aurait pas été vu autrement** : le QR indéchiffrable en
thème sombre, l'ombre montante devenue descendante, la capsule à 27 px de cible dans l'en-tête, le
focus invisible sur un champ d'éditeur, le segment ÉCHU sacrifié par la boucle d'ajustement parce
qu'un `flex:none` l'empêchait de rétrécir, et une fonction (`ovPaintLive`) emportée par une
suppression à la tranche. Les témoins ont été **retargés, jamais désarmés** : ce qui change est
l'adresse d'un composant, pas la propriété mesurée — et là où la propriété elle-même a changé
(l'échelle typographique, le seuil du code d'appariement, « ICI » sur la carte), le témoin dit
désormais ce que la règle veut dire plutôt qu'un chiffre.

**Passe de fidélité aux maquettes (même version).** Relecture écran par écran contre les planches
« 4 — Écrans », qui font foi ; les divergences relevées portaient toutes sur la MATIÈRE et la
DENSITÉ, jamais sur la structure :
- **Carte de bloc** : plus de liseré d'accent ni de pastille numérotée — la carte est une surface
  de travail (filet fin, rayon 14, rembourrage 18, l'ombre unique), son en-tête est « BLOC n » en
  petites capitales grises avec le compte en mono à droite, et le titre prend le cran 21. A12 est
  tenue autrement et mieux : la position se lit à ce que la carte est le seul bloc OUVERT, en tête
  de journal, et porte `aria-current="step"` — le seul des trois canaux qu'un lecteur d'écran voit.
- **Pied de carte** : « Vérifier :: » et « Continuer » sur UNE rangée, le premier à gauche, le
  second dernier et pleine largeur restante ; et « Vérifier :: » n'existe que si le bloc porte
  réellement des challenges (A7 était écrite, elle n'était pas appliquée).
- **Chapeau « Ne pas oublier »** : replié, ce n'est plus un pavé au registre ALERTE en tête de la
  colonne d'action mais une LIGNE — ■ rouge, mot en encre douce, compte en pilule neutre. Déplié
  et hors session, il reprend son cadre : c'est alors la condition d'entrée, et le registre est
  juste. Un pavé rouge permanent désensibilisait au rouge exactement comme l'aplat d'une étape.
- **Rail** : la colonne AFFICHE, on la touche pour COMMANDER. Une carte de minuteur y montre nom ·
  cycles · valeur (76 px) ; barre, « Cycles : n » et boutons ne paraissent qu'au tap — sauf pour un
  minuteur ÉCHU, dont le « RELANCER » reste sous les yeux, et pour les ± d'un compteur, devenu une
  RANGÉE. Un repère posologique signalé s'y marque sans aplat. Le panneau et le volet gardent la
  carte complète : on les ouvre justement pour régler.
- **Accueil** : la recherche devient une carte de travail (elle était un creux gris, lu comme une
  zone désactivée), l'avatar un carré arrondi de matière système à initiales (le disque bleu plein
  était le plus gros aplat coloré de l'écran, devant tout contenu clinique), les deux autres
  boutons d'en-tête des glyphes de commande, et le sélecteur « A–Z | Catégories » prend sa propre
  rangée au-dessus des sections qu'il réordonne.
- **Case d'étape à 26 px** (la cible reste la rangée entière, 60 px).
- **Au cockpit, la capsule cesse d'être une capsule** (signalé à l'usage : « sur ordinateur ça
  fait moche »). Montée dans l'en-tête, elle y gardait sa MATIÈRE SYSTÈME : une pilule sombre
  posée sur une barre claire, entre un titre et deux glyphes — un objet qui a l'air d'un contrôle
  sans en être un. La matière suit désormais le LOGEMENT : dans l'en-tête, l'état est du contenu
  d'en-tête (encre de la barre, registres du thème clair pour l'alarme, fond transparent), et il
  est CENTRÉ EN ABSOLU comme A14 l'exige — un titre long ne déplace plus l'alarme. Le sombre reste
  là où il veut dire quelque chose : la capsule en étroit et le dock. Coût de hauteur nul (65 px,
  inchangé), cible 44 px par le halo.
  ⚠ Deux défauts trouvés en le faisant : `flex:1` dans un conteneur en ajustement au contenu
  effondrait la boîte, et la boucle d'ajustement — qui MESURE — en concluait que plus rien ne
  tenait : elle sacrifiait le segment ÉCHU et n'affichait que « +1 ». Et `audit-a11y` CRÉDITAIT un
  halo forfaitaire de 8 px dès qu'un élément était en position relative, au lieu de lire l'inset
  réel : il déclarait trop petite une cible de 46 px, et — plus grave — en offrait 8 gratuitement à
  tout élément positionné pour un autre motif. Il mesure désormais ; il a immédiatement trouvé une
  compaction morte qui rabotait les touches du dock à 41 px.

⚠ Deux défauts introduits par cette passe et rattrapés par les harnais : le nom d'un minuteur repris
en `--ink-3` tombait à **2,32:1** (l'encre d'étiquette n'est jamais du texte porteur — règle écrite
depuis la v4.5), et l'étiquette d'un bloc HORS TRONC affichait « ⚡ Bloc » alors qu'un bloc détaché
n'a, par construction, pas de numéro.

Contrôles : `npm run check` vert (échelles typo, espacement, rayons, couleurs, paliers, SW,
vendor, uploads, SQL, stores, icônes, harnais, hashs CSP), `npm test` 952/952 sur les deux
moteurs, `npm run audit` **25/25 tâches vertes** (20 harnais), `design:build` régénéré.

## [5.5.0] — 2026-08-08
### Les boucles évoluent au compte : jalons, renvoi d'excursion, période de cycle

Audit demandé par l'auteur sur le déroulé de l'algorithme : *« l'ACR restera toujours
choquable / pas choquable / RACS — mais au bout de 3 CEE, se poser la question d'une FV
réfractaire, qui fera changer les pads ; puis l'analyse reste toutes les 2 minutes, commune
avec le début »*. Le déroulé en boucle était couvert (« ↺ reprendre à n », passages ×n,
convergence) ; ce qui n'existait pas, c'est un contenu qui **change au k-ième passage ou au
n-ième choc**. L'auteur n'avait que du texte statique (du bruit avant le seuil) ou une
excursion « à tout moment » dont l'**entrée reposait sur la mémoire du compte** — l'inverse de
la doctrine QRH, alors que le runtime connaît les deux nombres (`passInfo`, les compteurs).

- **P1 — le jalon de boucle** (`b.milestones`, facultatif, ≤ 3 par bloc) : une phrase d'auteur
  conditionnée « à partir du nᵉ passage » ou « quand le compteur X atteint n ». Modèle ECL sur
  la carte du bout : la ligne existe dès le premier passage, estompée, **condition en toutes
  lettres et progression vivante** (« Chocs délivrés 2/3 » en mono) ; au seuil elle passe au
  registre ATTENTION — ambre, jamais rouge, franchissement en ≥ (un fait ne s'acquitte pas), et
  **rien ne se déclenche** (règle 11 : pas de son, pas de saut — mesuré Δ = 0 px ; l'annonce
  passe par `#srLive`). Repeinture chirurgicale dans `setCounterVal`, **avant** le garde `!el` :
  en étroit, le volet des compteurs peut être absent du DOM pendant qu'un évènement distant
  incrémente — le jalon, lui, est sur la carte et doit suivre. Un compteur qui ne résout pas
  rejette la rangée dans `migrate` (un jalon qui ne mesure pas est mort).
- **P2 — le renvoi est une porte d'excursion, pas une navigation nouvelle** : `go` désigne la
  cible d'une excursion **déclarée** et le bouton ⚡ réutilise `data-cxgo`, donc `cxEnter`, ses
  gardes de partage et son retour prévu (« ↩ Reprendre » — l'analyse reprend, commune avec le
  début). Le bouton n'est tapable qu'au seuil : avant, la rangée ⚡ constante du pied suffit —
  l'action au pied de l'alerte est la règle ECAM déjà écrite pour `onDue`.
- **P3 — l'état au point de décision** : la progression vivante du jalon met le compte sous les
  yeux à l'endroit où l'on répond (le rang « passage n/N » existait déjà sur la carte).
- **P4 — la boucle dit sa période** : quand la fiche déclare **un seul** minuteur à cycles,
  les renvois de boucle textuels la portent (« ↺ reprendre à 2 · toutes les 2 min », statique
  et parcours) ; à deux minuteurs, rien — annoter serait une devinette.
- **Les vues de structure annoncent les jalons d'emblée** (rien de caché qui ne s'annonce) :
  marqueur △ + détail déplié dans l'Échelle (forme neutre — colonne désaturée), lignes inertes
  dans le Parcours et le Statique, condition en toutes lettres partout.
- **Éditeur** : rangées de jalon par bloc (condition · seuil · compteur · renvoi vers une
  excursion déclarée), porte d'ajout masquée au plafond de 3 ; la bascule vers « compteur »
  pré-pointe le premier compteur — on ne fabrique jamais l'état que `migrate` rejette.
- **La fiche d'exemple ACR exerce le mécanisme** (lot T13) : excursion « FV réfractaire (CEE
  inefficaces) », bloc hors chaîne (pads en antéro-postérieur), jalon « Chocs délivrés ≥ 3 »
  avec renvoi. Le **prompt IA** documente `milestones` et interdit d'inventer un seuil clinique.
- **Qualification réglementaire écrite avant le développement**
  (`docs/deploiement-et-conformite.md` § 2, « Le cas des jalons de boucle ») : une règle
  d'auteur affichée au moment que l'auteur a défini — même famille qu'`onDue` ; aucun paramètre
  patient (les compteurs comptent des gestes de l'équipe) ; la ligne à ne pas franchir est
  nommée (paramètre patient, seuil déduit par le logiciel, déclenchement autonome).
- **Témoins** : 17 contrôles purs (`tests.html` — sanitisation, progression, `cycleHint`),
  section doctrine « QRH · jalons de boucle » (12 contrôles qui construisent leur cas sur
  l'ACR, vérifiée **capable d'échouer** : activation neutralisée → 4 rouges, fichier restauré à
  l'octet), 2 contrôles de contrat dans `audit-prompt` (le jalon du schéma traverse `migrate`).
  `SHARE_KEEP` couvre déjà (`blocks` voyage entier) — `schema.sql` inchangé.

Rotation du journal (règle des 20 entrées) : 5.0.0 → 5.0.2 partent dans
`docs/changelog/v5.md` (créé), 4.77.0 → 4.79.0 rejoignent `docs/changelog/v4.md`.

## [5.4.4] — 2026-08-08
### Les audits cessent d'être chronophages — sections ciblables, tranches, cache vert (aucune sonde changée)

Audit du dispositif d'audit lui-même, demandé par l'auteur (« peut-on réduire le temps en
gardant la même sécurité ? »). Mesuré d'abord : la passe complète coûtait **216,7 s de temps
mural, et audit-doctrine à lui seul EST ce temps mural** (le pool absorbe les 19 autres harnais
pendant qu'il tourne) ; surtout, confirmer UN témoin corrigé coûtait le harnais ENTIER, « et ça
plusieurs fois, pour plusieurs fichiers » — 29 des 45 derniers commits touchant `index.html`
avaient dû toucher des `audit-*.mjs`.

- **Sections ciblables** (`secRunner` dans `harness.mjs`) : les 51 sections de doctrine et les
  23 de partage — indépendantes par construction, seul état partagé les compteurs ok/ko — sont
  enveloppées dans `await sec('nom', …)`. `node scripts/audit-doctrine.mjs --grep <motif>`
  confirme une section en **1,5 à 8 s au lieu de 216,7** ; un motif sans correspondance ÉCHOUE
  bruyamment en listant les sections (une passe vide aurait l'air verte) ; toute passe filtrée
  s'annonce PARTIELLE jusque dans son bilan final. La transformation (mécanique, script à garde
  d'abandon) est **vérifiée par équivalence** : sortie byte-identique à l'avant-refactor,
  737/737 et 291/291 contrôles, même ordre.
- **Tranches parallèles** (`tranches: n` dans `HARNAIS`) : doctrine se joue en 4 processus
  `--shard k/4`, a11y en 2 (découpe du tableau SURFACES ; la sonde focus 2.4.11 en tranche 1
  seule), partage en 2. Passe complète **216,7 → 156,4 s** au pool par défaut, **126,0 s** à
  `AC_JOBS=5` (mesuré vert ; le défaut RESTE 4 — protection CI et règle « un rouge sous charge
  se confirme en rejouant seul »). GARDE-FOU : chaque tranche imprime `##SEC joues=j total=N`
  et le lanceur vérifie que la somme couvre le total — une tranche qui perdrait des sections
  serait une troncature silencieuse ; vérifié CAPABLE D'ÉCHOUER (rouge fabriqué puis restauré).
- **`npm run audit -- --rouges`** rejoue les seuls harnais rouges de la dernière passe (état
  dans `.audit-etat.json`, racine, gitignoré), annoncé PARTIELLE ; aucun rouge enregistré → il
  le dit et sort vert.
- **Cache de passe verte** : une passe complète verte enregistre le SHA-256 de tout ce qui peut
  influencer un verdict (servables de la racine, `vendor/`, `scripts/*.mjs`, moteur) ; si rien
  n'a changé, `npm run audit` LE DIT au lieu de rejouer — des entrées identiques octet à octet
  donnent le même verdict — et `--force` rejoue quand même. Une passe partielle n'écrit ni ne
  consomme jamais ce cache.
- **Ce qui n'a pas été fait, et pourquoi** (écrit dans AGENTS.md) : pas de carte « fichier
  modifié → harnais à jouer » (monofichier + dix-neuf pièges de cascade : une édition CSS
  anodine casse des témoins dans des harnais sans rapport — une carte serait un vert menteur) ;
  pas de témoins auto-régénérés façon snapshots (un contrôle qui ne peut plus échouer ne prouve
  rien, leçon v4.31.1) ; k5 non découpé (scénario séquentiel monopage, ~67 s incompressibles).
  **La porte de commit est strictement inchangée** : la passe COMPLÈTE avant chaque commit, que
  la CI rejoue. Le coût de PENSER les témoins quand le code change n'est pas racheté : c'est lui
  la garantie.

## [5.4.3] — 2026-08-07
### Le rail droit se rééquilibre à 780-1199 px — les familles de traçabilité réunies partout

Audit demandé par l'auteur (« la sidebar n'est-elle pas trop chargée aux largeurs
intermédiaires ? ») puis décision R1+R2 sur maquette chiffrée à l'échelle des mesures réelles.

- **Le constat mesuré** (session réelle, fenêtre du rail 642 px) : 1 625 px de contenu —
  **60 % enterré** sous un pli invisible (barres de défilement masquées au repos), le journal à
  **583 px sous le pli**, séparé des compteurs par la posologie et toute l'Échelle : la
  séparation exacte que la v5.4.0 avait corrigée en étroit, jamais portée au rail.
- **R1 — le journal remonte contre les compteurs, en dépliant d'une ligne** (`details.rail-fold`,
  résumé en grammaire `.rail-head` + compte) : les trois familles de traçabilité redeviennent
  voisines à TOUTES les largeurs. Replié par défaut sous 1200 px, **déplié par défaut en
  cockpit** (rail à 4 zones). Le compte du résumé suit chaque repère, local ou distant.
- **R2 — sous 1200 px, l'Échelle devient un dépliant d'une ligne** annonçant son compte ET la
  position courante (« ici : ① Mesures immédiates »), régénérée à chaque navigation sans toucher
  à l'état ouvert/fermé. À ≥ 1200, rien ne change : l'Échelle vit dépliée dans la colonne du plan.
- **Rien ne se déplie ni ne se replie tout seul** (règle 11) : seul le tap sur le résumé (ou
  Entrée/Espace — `<details>` natifs, `aria-expanded`, cibles 44 px, focus visible). État
  transitoire par fiche (`SHARE_LOCAL`, remis aux défauts de largeur à l'ouverture) — regarder
  n'est pas régler. Conformité argumentée : une zone repliée qui S'ANNONCE est plus fidèle à
  l'ECAM qu'un contenu enterré muet (modèle ECL v4.16.4) ; l'état VIVANT (chronos, compteurs,
  échu) n'est jamais replié ; même grammaire de dépliant que le chapeau et l'index ⚡ (§5.5).
- **Résultat** : contenu du rail à 900 px **1 625 → ≤ 1 100 px**, plus rien de caché qui ne
  s'annonce. Divergence assumée avec la maquette (dite dans AGENTS.md) : « Surveiller ensuite »
  vit dans le corps de l'Échelle et se replie avec elle — sa source reste la section ③ du flux.
- Sondes dédiées vertes sur Chromium et WebKit (défauts par largeur, dépliage réel, comptes
  vivants, « ici » qui suit la navigation) ; passes complètes 16/16 check · 939 × 2 tests ·
  **20/20 harnais du premier coup**. Trois leçons de sonde consignées (compter les titres sans
  distinguer résumé et corps replié ; référence DOM détachée après re-rendu).

## [5.4.2] — 2026-08-07
### Six correctifs d'usage — clavier du volet, surligneur PDF, quai accès unique, repères qui suivent

Tous signalés à l'usage réel (PWA/smartphone), chacun vérifié à la mesure sur les deux moteurs.

- **Le bandeau système passe au-dessus du rail A→Z** : le rail (fixe, z 15, voile de fond)
  peignait par-dessus « Nouvelle version disponible », masquait sa droite et pouvait intercepter
  le tap sur son × (`touch-action:none` sur toute sa bande). `.sys-banner` prend
  `position:relative; z-index:16` — au-dessus du rail, toujours sous l'en-tête (20) : une
  notification qu'on doit lire et rejeter prime sur trois lettres d'index recouvertes
  transitoirement.
- **Modifier une heure dans le volet ne fait plus sauter le scroll** (« très mal géré quand le
  clavier s'ouvre ») — deux causes cumulées : le `focus()` programmatique défilait le DOCUMENT
  pour « révéler » un champ déjà sous le doigt dans une couche fixe (→ `preventScroll`, règle
  v4.78.0) ; et la hauteur du volet était bornée sur `--vvh`, que le CLAVIER rétrécit — elle
  passe à `100svh` (constante : ni barre d'outils ni clavier), la règle du rail A→Z (v5.0.1)
  appliquée au clavier près. Vérifié : focus → 0 px de saut page et volet, hauteur immune au
  rétrécissement de `--vvh`.
- **Le surligneur PDF est FIXE, il ne suit plus le thème** (« pas assez visible, encore plus en
  clair ») : une page PDF garde SES couleurs — `--verify-soft` + multiply donnait un crème quasi
  invisible en clair et un autre rendu en sombre pour le même document. Jetons fixes deux-thèmes
  `--pdf-hl`/`--pdf-hl-ring` : jaune surligneur universel en fondu NORMAL (multiply s'éteint sur
  fond sombre) + anneau ambre — bande effective #FFEE99 sur page blanche, voile éclaircissant +
  anneau sur page sombre. La pilule ‹ n/N · p. x › passe à l'**ardoise fixe** `--rt-*` (celle du
  toast) : identique dans les deux thèmes, lisible sur toute page.
- **« Dans les documents » respire** : 24 px au-dessus du titre du groupe (il se lisait comme la
  méta de la dernière carte de résultats).
- **Les repères posologiques suivent le bloc courant pendant la navigation** (bug confirmé — le
  classement v4.23.0 n'était calculé qu'au rendu complet) : générateurs à site unique
  (`posBlockHtml`/`posRailHtml`) et `repaintPoso()` rejouée par les trois chemins ciblés (journal,
  statique, mono-bloc) — jamais au cochage ; le pli « n autres repères » garde son état. Vérifié :
  « Continuer » vers un bloc → son médicament passe en tête.
- **Le quai est l'accès unique au panneau en étroit** (décision utilisateur : « il appartient
  maintenant au rail ») : la rangée repliée du flux est SUPPRIMÉE (`.rt-collapsed`, `#rtOpen`,
  `rtRowLabel` — règle 14, grep vérifié) — le double accès de la v5.4.1 avait perdu sa moitié le
  jour où le volet a su suivre le défilement. Le volet se rend même sans minuteur ni compteur (le
  journal y loge) ; le rappel du quai devient le seul annonciateur de ce qui est caché. Limite
  dite : sur une fiche mono-bloc en étroit, « Noter l'heure » s'atteint par le quai (cette carte
  n'a jamais porté le bouton M2 — l'aligner serait une décision séparée).
- Témoins : trois sondes passent par le vrai geste du quai (ex-`#rtOpen`) ; les fixtures des
  témoins d'atterrissage v5.0.7 construisent désormais leur cas (le panneau du flux payait ~70 px
  de leur marge de défilement — sans lui, le contrefactuel s'écrêtait). Passes : 16/16 check ·
  939 × 2 tests · 20/20 harnais.

## [5.4.1] — 2026-08-07
### Le volet du quai devient un étage du chrome, les familles se nomment, et le chrome ≥ 1200 px monte dans l'en-tête

Trois retours d'usage, chacun tranché sur maquette ou après itérations mesurées à l'écran.

- **Le dépliant du quai est un volet FIXE, étage du bloc de chrome** (question de l'auteur :
  « contraire à ECAM/QRH ? » — non : ouvert et fermé par l'utilisateur seul, jamais
  d'auto-ouverture, l'alarme jamais masquée — même statut de consultation que le menu ⋯). Il SUIT
  le défilement : minuteurs, compteurs et journal restent sous les yeux en parcourant les étapes.
  Après trois retours (« pas une continuité du quai », « fixed dans fixed », « deuxième niveau de
  scroll ») : PLEINE largeur, collé au quai (le filet du quai fait la séparation d'étages, patron
  #refBar), panneau intérieur sans boîte, UN seul défileur, en-tête ✕ non épinglé. Fermeture par
  re-tap du quai, ✕, Échap et retour système (`_histArm`/`_histBackAction`). La rangée du flux
  garde sa géométrie de poussée : deux accès, deux arbitrages.
- **Les familles se nomment** (« minuteurs / compteurs / journal peu identifiables — tout se colle
  et se mélange ») : sous-titres MINUTEURS / COMPTEURS / JOURNAL DES ACTIONS partout — grammaire
  `.tk-head` + compte en pilule dans le panneau et le volet, `.rail-head` + `.rail-n` dans le rail
  large. Les compteurs n'avaient aucun en-tête ; « ＋ Minuteur PA » rejoint la famille des
  minuteurs qu'il crée.
- **À ≥ 1200 px, le chrome de crise monte dans l'EN-TÊTE** (option A′, choisie sur maquette après
  DEUX itérations refusées — la bande pleine largeur réservait ~110 px pour des contrôles qui ne
  vivaient qu'à gauche ; la version « colonne du plan » empilait trois boutons en volant sa
  hauteur au plan). « Tout voir », « Consulter » et le chrono SESSION vivent dans
  `#hdrCrisisSlot`, entre le titre et les actions — chrome NOMADE au patron du pied de page
  (déplacés, jamais recréés), `body.chrome-hdr`, `stickBase`/`stickHeight` cessent de compter des
  rangées dont la hauteur est déjà celle de l'en-tête. **Coût de hauteur nul, mesuré** : en-tête
  65 px inchangé (compaction du dessin, jamais des cibles — halos de 44 px, attrapé par
  `audit-a11y` : 8 rouges sur le bouton Session à 37 px, réparés par le halo standard). Les trois
  colonnes commencent à ~83 px ; plus de bande ni d'« effet de tronquage » pour toute lecture de
  fiche à ce palier, statique et mono-bloc comprises. Sous 1200 px, rien ne change.
- Sondes dédiées 9/9 (Chromium + WebKit) : chrome dans l'en-tête, une seule rangée, en-tête ≤
  70 px, `--stick-top` = en-tête seul, état visible après 800 px de défilement, mono-bloc couvert,
  390 px inchangé. Passes complètes : 16/16 check · 939 × 2 tests · 20/20 harnais.

## [5.4.0] — 2026-08-07
### Le journal des actions rejoint le dépliant minuteurs, et l'heure se corrige comme on la tape

Trois retours d'usage en situation réelle, traités après proposition de solutions et décisions
de l'auteur ; plus un chantier vérifié resté en attente de publication (16 px tactile).

- **La correction d'heure accepte ce qui a un sens, et refuse en le disant** (« entrer 1547 pour
  15h47 ne fonctionne pas — trop strict ») : l'ancien format exigeait `H:MM[:SS]`, or le champ est
  `inputmode=numeric` et le clavier numérique d'iOS n'a pas de deux-points — le format canonique
  était intapable sur la cible principale ; et l'échec était MUET (saisie jetée sans un mot), d'où
  l'impression d'un format encore plus strict. `tkParseTime` (pure, 19 tests) lit les séparateurs
  libres (`15:47`, `15h47`, `15.47`, `15 47`) et les chiffres nus par longueur (`1547` → 15:47:00,
  `154723` → 15:47:23) ; une valeur impossible est REFUSÉE, plus écrêtée (« 15:87 » devenait
  15:59 — une heure fabriquée dans une trace de soin). Sur Entrée, l'illisible laisse le champ
  ouvert avec le registre ATTENTION (△ + « ex. 1547 ou 15:47 ») ; sur blur, le retour à l'ancienne
  heure s'annonce (#srLive).
- **Chips de recul « −1 · −2 · −5 min »** pendant l'édition d'une heure : le cas réel est
  « rattraper un geste noté en retard » — un tap vaut mieux qu'une heure retapée ; même mécanique
  non destructive (`origT` + « ↺ revenir »). Le tap passe par `preventDefault` au `pointerdown`
  (le blur détruirait la chip avant son click — leçon `.li-tools` v4.77.0), le chemin clavier par
  `relatedTarget`.
- **En étroit, le journal vit dans le dépliant minuteurs** (« ne pas mettre les compteurs et le
  journal au même endroit m'a perturbé — pour changer l'un puis l'autre on passe au-dessus des
  étapes ») : une seule rangée « Minuteurs · compteurs · journal — comptes », posée sous la carte
  du bloc (la place T2 du journal) ; ouverte du quai, tout arrive ensemble sous le quai (M11
  tenu : quai immobile, mesuré). Le geste fréquent ne bouge pas — « ⏱ Noter » et l'accusé restent
  dans la carte (M7) ; en large, le rail est inchangé ; une fiche sans minuteur ni compteur garde
  son journal autonome. `rtRowLabel` = source unique du libellé ; `renderTkOnly` repeint le compte
  de la rangée repliée quand le panneau n'est pas dans le DOM (repère posé depuis la carte ou reçu
  d'une session partagée — sinon compte périmé affiché comme vivant). Deux témoins d'`audit-partage`
  passent désormais par le vrai geste d'ouverture.
- **Un dépliant se reconnaît avant de se lire** (« difficile d'identifier que c'est un menu
  déroulant ») : rangée repliée en `--surface-3` — le ton du chrome, distinct dans les deux
  thèmes ; le contenu clinique reste seul en carte blanche — et déclencheur « ▾ Afficher » en
  pilule bordée. Niché dans le panneau, le journal est une section à filet, pas une carte dans la
  carte.
- **Publication du chantier « 16 px tactile » resté en attente** (signalé à l'usage iPhone :
  « quand on clique à l'intérieur d'un protocole l'écran zoome ») : le champ « Chercher dans la
  référence » était né à 12 px hors du bloc tactile des 16 px — Safari iOS zoomait au focus.
  `check-type` exige désormais que tout sélecteur posant < 16 px sur un champ figure dans la liste
  tactile ; il a attrapé trois autres champs jamais signalés (phase de bloc, lignes du chapeau,
  nom de minuteur). Les références « v5.3.2 » de ce chantier sont réalignées sur la version qui
  l'embarque réellement.
- Passes complètes : 16/16 check · 939 × 2 tests (Chromium + WebKit) · 20/20 harnais ; sonde de
  parcours dédiée 25/25 sur les deux moteurs (fusion, saisie, chips, refus annoncé, quai immobile,
  large inchangé, fiche sans minuteur).

## [5.3.1] — 2026-08-07
### Les résultats de recherche ne collent plus aux bordures — et un rembourrage mort depuis la v5.0.0

Signalé à l'usage sur la PWA (« résultats de recherche dans la barre fixée très collés à la
bordure du dessous ») ; les trois écarts mesurés avant/après.

- **⚠ Vingtième piège de cascade, et il préexistait** : `details.ref-toc[open]{padding-bottom:8px}`
  (0,2,1) perdait contre `#refBar>.ref-toc{padding:0 18px}` (1,1,1) — le rembourrage bas du
  dépliant « Rechercher · sommaire » de la barre fixée était silencieusement MORT depuis sa
  création (v5.0.0) : mesuré **1 px** entre le dernier objet et la bordure de coupure, pour le
  dernier lien du sommaire comme pour les rangées de résultats-documents (v5.3.0), qui ont hérité
  du défaut et l'ont rendu visible. Réparé en (1,1,2), jamais par l'ordre : 15 px sous le
  sommaire, 29 px sous une rangée seule.
- **Les rangées de résultats-documents respirent aussi vers le bas** : `.pf-docs` n'avait qu'une
  marge haute — dans la feuille « Toute la fiche », la rangée touchait le tableau SFAR en dessous
  (0 px mesuré). Marge basse de 14 px : un résultat n'est pas un en-tête de section, il ne se
  colle pas à ce qui suit.
- **Le « · Réindexer » du pied ne s'enroule plus en abandonnant son séparateur** : « · » restait
  orphelin en bout de ligne pendant que le bouton partait seul à la suivante — le geste est soudé
  à son séparateur (`.attix-act`, `white-space:nowrap`).
- **L'icône « Filtrer » passe aux réglettes** (décision utilisateur sur maquette comparative de
  cinq candidats) : l'entonnoir à queue pliée datait — trois curseurs horizontaux, la convention
  contemporaine du « affiner ce qu'on voit », dans la famille d'icônes au trait. Tracé mis à jour
  aux DEUX sites (SVG en dur de `#filtTog` + entrée `filter` d'`uiIcon`), duplication signalée
  des deux côtés comme pour l'icône `user`.
- Les autres surfaces livrées depuis la v5.2.0 (extrait « dans ‹nom› · p. n » des rangées, groupe
  « Dans les documents », pilule ‹ n/N › de la visionneuse) ont été re-mesurées : conformes aux
  gabarits existants. Passes complètes 17/17 check · 920 × 2 tests · 20/20 harnais.

## [5.3.0] — 2026-08-07
### La recherche dans les PDF va au bout du geste — auto-indexation, porteurs en résultats, surlignage dans la visionneuse

Quatre retours d'usage sur la v5.2.0, vécus sur la PWA de l'auteur le jour même, tous les quatre
livrés.

- **Le rattrapage d'indexation est AUTOMATIQUE — revirement assumé** (« l'indexation ne s'est pas
  lancée automatiquement, j'ai dû cliquer ») : la v5.2.0 exigeait un geste explicite pour ne
  jamais lancer de tâche de fond spontanée ; à l'usage, l'état nominal attendu est « mes
  documents sont trouvables », pas un bouton pour un travail que la machine sait faire seule.
  `ixLoadAll` met en file les documents en attente au démarrage — ~4 ms/page, un à la fois, à
  l'inactivité, et pdf.js ne se charge QUE s'il existe des documents à indexer (un démarrage
  ordinaire n'y touche pas). La ligne du pied devient un indicateur d'avancement ; son bouton
  « Indexer » reste, filet des cas où la file s'est arrêtée.
- **Le porteur du document est lui aussi un résultat** : chercher un mot qui ne vit que dans le
  PDF joint sort l'AIDE dans la liste (les trois vues, `entityDocHit` dans les filtres, renvoi
  croisé compris), avec l'extrait « dans ‹nom› · p. n » — le OÙ, jamais le contenu, qui n'est
  pas stocké. Le groupe « Dans les documents » reste : deux objets, deux gestes.
- **La recherche d'une entité couvre ses annexes** : le champ d'une référence et celui de la
  feuille « Toute la fiche » listent sous le champ (`#pfDocs`) les documents joints où tous les
  termes apparaissent ; un tap ouvre la visionneuse à la page, occurrences surlignées. Un mot
  absent replie la zone.
- **Les occurrences se surlignent dans la visionneuse et se naviguent** (« comme le texte des
  fiches ») : les PAGES viennent de l'index déjà en mémoire (coût nul), les POSITIONS sont
  retrouvées au rendu de chaque page visible (`pdfPaintHl` — `getTextContent` ~3 ms, en cache) et
  posées en rectangles `--verify-soft` en `mix-blend-mode:multiply`, même registre que le
  surlignage du texte. Pilule flottante ‹ n/N · p. x › : navigation par page d'occurrence. La
  position dans une ligne est approchée au prorata des caractères — le compromis qui évite
  d'embarquer la couche texte entière de pdf.js. Ouvert depuis sa RANGÉE : ni surlignage ni
  pilule — on vient lire, pas chercher.
- Vérification : `audit-pdfsearch` passe de 26 à **37 contrôles**, verts sur les deux moteurs —
  dont l'auto-rattrapage au démarrage sans clic, le repli sur mot absent, la boîte de chaque
  rectangle dans sa page, et l'ouverture neutre depuis la rangée. Deux témoins corrigés en les
  écrivant (un mot qui ne vivait que sur une page ne pouvait pas faire naviguer ; la rangée de
  documents d'une fiche vit dans « Consulter », pas dans le flux). Passes complètes 17/17 check ·
  920 × 2 tests · 20/20 harnais.

## [5.2.0] — 2026-08-07
### La recherche trouve dans les documents PDF — un index inversé, jamais une copie du texte

La recherche trouvait la FICHE, jamais l'endroit : un protocole de service joint en PDF pouvait
porter la seule mention d'une dilution, et rien ne la trouvait. Et deux correctifs de moindre
taille livrés dans la même version : le compte-rendu s'enregistre en PDF, et « Répéter en
exercice » n'allume plus l'accueil avant le premier geste.

- **Chercher dans les documents PDF** (`ixBuild`/`ixOpen`/`ixSearch`, purs et testés ; store
  IndexedDB `attidx`, base v6). La première approche — conserver le texte extrait et le balayer —
  a été REFUSÉE par l'auteur, à raison : ~100 % du poids du texte (546 Ko mesurés pour 200 pages)
  et un plafond obligatoire, donc des documents indexés à moitié. On fait ce que font Spotlight,
  Finder et Lucene : un **index inversé** — dictionnaire des mots distincts (front-codé) + pages
  de chaque mot (varint-delta, ou bitmap pour les mots trop fréquents). Le poids suit le
  VOCABULAIRE, qui sature : mesuré sur du français technique réel, 13,4 % du texte à 626 Ko
  (34 % à 49 Ko) — **aucun plafond, indexation intégrale, toujours**. L'index natif d'IndexedDB
  (`multiEntry`) a été mesuré et écarté : ×47 en occupation réelle ; SQLite FTS5 n'existe pas
  dans un navigateur et l'amener en WASM serait une seconde dépendance runtime (règle 13).
- **Aucun extrait dans les résultats, et c'est la clé** : la rangée « Dans les documents » donne
  le nom, le nombre de passages, les PAGES et la fiche qui porte le document — le contexte se lit
  dans le document, qu'un tap ouvre À LA PAGE (`openPdfViewer` accepte une page). pdf.js
  (1 773 Ko) n'est donc JAMAIS chargé pendant qu'on tape. Correspondance par sous-chaîne, comme
  le reste de la recherche (« drenalin » trouve « adrénaline »).
- **Indexation à l'arrivée du binaire — les CINQ arrivées** : `attPut(rec)` est le point
  d'étranglement unique (patron `persistLive`) ; trouvé en le posant, l'indexation n'était
  accrochée qu'à deux des cinq chemins (manquaient le « Télécharger » manuel, le téléchargement
  immédiat de la visionneuse et l'import .zip). `check-stores` compte désormais les sites
  d'écriture. File à l'inactivité, un document à la fois ; rattrapage des documents déjà là par
  un geste explicite (ligne du pied de la sidebar), jamais en tâche de fond spontanée.
- **Résilience** : deux familles d'échec distinguées — transitoire (binaire absent, pdf.js hors
  cache : rien n'est retenu, trois essais par session puis « Réessayer ») et durable (`scan` /
  `illisible` : état enregistré, sinon le compte « à indexer » ne descendrait jamais).
  `ixAdopt` est l'unique point d'adoption : un enregistrement illisible est JETÉ et le document
  redevient « à indexer » — le défaut inverse (un `null` rangé dans la table) aurait rendu tous
  les documents non ré-indexables au premier changement de version d'index. **Réindexer** existe
  pour tout (ligne du pied, avec confirmation) et pour un document (sa rangée d'éditeur). Le
  décodeur est TOTAL : enregistrement tronqué refusé en bloc, aucune boucle infinie possible,
  aucune page rendue hors du document.
- **Confidentialité** : l'index est DÉRIVÉ et strictement LOCAL — jamais synchronisé, jamais
  exporté (un dictionnaire EST la liste des mots d'un document clinique ; le faire voyager serait
  une catégorie nouvelle de donnée sortante, pour zéro gain — il se reconstruit en ~4 ms/page).
  Il vit dans la base de l'ESPACE : un compte par index sur un poste partagé, déménagé avec le
  reste, effacé avec le reste. Le contenu des PDF n'atteint jamais le DOM (aucun texte stocké,
  aucun extrait affiché) ; le seul texte non maîtrisé est le NOM du document, couvert par `esc()`
  et éprouvé par un témoin au nom hostile.
- **Le compte-rendu s'enregistre en PDF** (demande utilisateur) : « Télécharger » (.html) et
  « Imprimer » deviennent « Fichier .html » et « **Enregistrer en PDF** » (rempli) — le second
  EST le chemin d'impression (iframe A4), seul producteur de PDF du projet ; un seul bouton pour
  ce chemin (AC 120-71B §5.5), le .html restant le repli qui ne dépend d'aucun dialogue système,
  et le message d'échec le nomme.
- **« Répéter en exercice » n'allume plus l'accueil avant le premier geste** (signalé à l'usage :
  chrono figé à 0:00 et « Session en cours » dès l'entrée en exercice) : `startExercise`
  n'inscrit plus le runtime dans `liveSessions` — `ensureStarted` le fait au premier geste, comme
  pour une session réelle ; le prédicat `sessionLive()` (présence ET `started`) remplace les deux
  tests de présence de la rangée et de la tuile.
- Vérification : 26 contrôles `audit-pdfsearch` (nouveau harnais, PDF fabriqué xref calculé, vert
  sur les DEUX moteurs — dont « pdf.js n'est pas chargé par la frappe », mesuré sur page
  rechargée), 25 témoins unitaires de l'index (bitmap, front-codage, résilience), sonde dédiée du
  correctif exercice ; passes complètes 17/17 check · 920 × 2 tests · 20/20 harnais.

## [5.1.2] — 2026-08-05
### Purge des commentaires orphelins (règle 14) — et la rangée de commandes ne disparaît plus d'une fiche sans annexe

Passe d'hygiène demandée sur les ~839 Ko de commentaires du monofichier : le croisement de tous
les identifiants cités en commentaire avec le code réel n'a trouvé que 34 absents, presque tous
des mentions historiques volontaires (tombstones, renvois aux pièges de cascade) — conservées.
Le reste, les vrais vestiges, est purgé ; et la purge a mis au jour un défaut réel.

- **⚠ Correctif `syncDock` (retombée de purge, règle 14)** : depuis les lots T8/A (v5.0.0) la
  rangée de commandes porte `#allBtn` et `#refBtn`, mais son test de visibilité lisait encore
  `#modeSeg` et `#planBtn` (toujours null) en ignorant `#allBtn` — une fiche À ALGORITHME mais
  SANS annexe (Consulter masqué) perdait donc la rangée entière, « ⤢ Tout voir » compris, en
  silence. Les fiches d'exemple ayant toutes des annexes, aucun harnais ne rencontrait le cas.
  Prouvé par une sonde qui le CONSTRUIT : rouge sur l'ancienne logique (rangée masquée, bouton à
  0 px), verte sur la corrigée, fichier restauré à l'octet entre les deux (leçon v4.31.1).
- **Six blocs de commentaires orphelins du sélecteur de mode** (`#modeSeg`, `.ctrl-sp` — purgés au
  lot A) flottaient dans le CSS sans plus aucune règle en dessous : remplacés par un tombstone de
  trois lignes. La seule doctrine encore vivante — le fond de pastille n'est jamais `--surface`,
  qui s'inverse entre thèmes — déménage sur le composant `.seg` générique, où elle s'applique.
- **Le « HUITIÈME PIÈGE DE CASCADE » vivait en DEUX versions successives** (l'originale et sa
  réécriture v4.55.0, conservées côte à côte par erreur) : dédoublonné, et mis à jour — la
  surface qu'il cite (mode lecteur) est partie au lot T14 ; la leçon de spécificité reste.
- **Trois commentaires remis au vrai** : la recette 320 px citait `.ctrl-sp` au présent ; le bloc
  d'enroulement portait une phrase MUTILÉE par une ancienne édition (deux moitiés de phrases
  recollées) ; la délégation de la feuille Plan justifiait son choix par `#pmViews`, disparu en
  v4.25.0. Et la bannière « ORGANIGRAMME HYBRIDE (mode Détails) » — vue supprimée en v4.25.0 —
  renommée « ÉCHELLE DU PLAN », ce qu'elle contient réellement.
- **Code mort purgé** : `modeTopSegH` (constante vide et son interpolation, vestige de la bascule
  d'en-tête) et le mécanisme `kb-open` entier — deux écouteurs posaient une classe que plus
  aucune règle CSS ne lit depuis que les actions d'éditeur vivent dans l'en-tête sticky.
- **Le CHANGELOG revient à 20 entrées** (il en comptait 28) : les neuf plus anciennes (4.70.1 →
  4.74.0) rejoignent `docs/changelog/v4.md` telles quelles, sans réécriture.

Bilan : 88 lignes supprimées, 36 ajoutées. Vérifié : `npm run check` complet, 894 tests × deux
moteurs, passe d'audit COMPLÈTE (19 harnais). Le gisement « commentaires périmés » était petit à
dessein — le reste des 839 Ko est de la doctrine volontaire, et il reste en place.

## [5.1.1] — 2026-08-05
### La palette de catégories re-résolue en espace perceptuel — six teintes corrigées, à problème nommé chacune

L'action 7 de l'audit v5.0.0 (« désaturer les catégories ») avait été refusée sur mesure — à
raison pour une désaturation d'ensemble. Rejouée en OKLCH (point 1 de l'audit direction A), la
bonne métrique montre que le problème était PONCTUEL, pas global : trois catégories étaient
perceptuellement COLLÉES à un registre d'alerte, deux l'étaient entre elles, et quatre passaient
sous 3:1 sur surface sombre.

- **Ce qui était mesuré (dE_OK, distance OKLab ×100)** : l'olive #806311 à **3,0** du registre
  ambre `--verify` — au premier regard, une catégorie pouvait se lire comme un signal de
  vigilance ; le vermillon à 3,1 de `--critical-bd` ; le vert #1d7449 à 3,3 de `--ok` ; les deux
  sarcelle/bleu à 5,1 l'une de l'autre ; et #45556b, #0d5b56, #4b3fa6, #7a2f6b entre 2,26 et
  2,56:1 sur le sombre (la couleur stockée est rendue brute dans les deux thèmes).
- **La correction est chirurgicale** : six teintes bougent (0, 2, 4, 5, 6, 9), sept sont
  intactes. Déplacements minuscules — dE_OK 1,3 à 2,8, sauf l'indigo (6,2) qui devait remonter
  pour son contraste sombre (2,37 → 3,10). Plancher des distances : **3,0 → 4,0**. Le caractère
  sourd de la palette est conservé (chroma quasi inchangée) : un premier solveur qui maximisait
  librement les distances proposait des néons, et a été corrigé en objectif lexicographique sur
  les plus petites distances.
- **⚠ Les contraintes de clair sont celles du test de régression #3**, pas « sur blanc » : texte
  couleur sur sa teinte à 15 % ≥ 4,5:1 ET blanc sur couleur pleine ≥ 4,5:1. Un premier jet
  contraint « sur blanc » a produit trois teintes que `npm test` a refusées (3,74-3,95) — le
  garde-fou a fait son travail, et le solveur reprend désormais `tint15`/`ratio` à l'identique.
- **Sans rupture par construction** : la couleur vit dans la catégorie stockée — les choix
  existants ne changent pas d'un pixel ; seuls le nuancier proposé et `defaultCats` (nouvelles
  installations) sont corrigés. Trois teintes restent < 3:1 en sombre (#45556b, #0d5b56,
  #7a2f6b) : aucun candidat conforme n'existe dans le budget de reconnaissabilité (vérifié au
  solveur) — dit, pas caché, et atténué par la règle « la couleur n'est jamais seule ».
- **Et « Urgences » par défaut porte enfin le vermillon.** `defaultCats()` lui donnait `#1f5fa6` —
  le bleu `--primary` — depuis sa création en v3.0.0 ; la règle « pas de bleu primaire pour une
  catégorie » posée en v4.1.0 avait corrigé le nuancier **sans toucher le jeu par défaut**
  (vérifié à l'historique : le commit de la règle ne modifie pas `defaultCats`). Aligné sur
  `#b23240`, la couleur que la doctrine destine nommément aux catégories d'urgence — nouvelles
  installations seulement, aucune migration des catégories existantes.

## [5.1.0] — 2026-08-05
### Direction « Instrument clinique » — six lots de matière issus d'un audit UX externe, aucun contrôle déplacé

Un audit UX/direction artistique complet (7 axes, mesures sur l'application réelle à 320/390/1280,
deux thèmes) a conclu que l'interface était conforme et confortable, et a proposé une direction de
modernisation « Instrument clinique », validée sur prototype comparatif A/B. Tout ce qui suit est
de la MATIÈRE : aucune position de contrôle ne change, aucune règle de sûreté n'est touchée.

- **Une seule voix système à la fois.** Mesuré à 390×844 : au premier lancement, le bandeau
  « 2 fiches d'exemple ajoutées » et la notice « Vous êtes l'auteur… » s'empilaient — premier
  contenu clinique à 39 % de l'écran, et les deux textes énonçaient la même responsabilité
  éditoriale. Le bandeau absorbe désormais le texte de la notice ; tant qu'il est visible, la
  notice attend son tour et paraît à l'acquittement (« J'ai compris » ou ✕). ⚠ La garde teste la
  classe `body.view-home` — le même prédicat que la visibilité CSS du bandeau — et non
  `state.view`, qui vaut `'library'` sur l'accueil (payé à la première livraison).
- **La recherche est un creux.** Le champ passe sur `--surface-2` avec un filet d'1 px (les 2 px
  de bordure rendus au rembourrage) : une zone de saisie se distingue d'une carte de contenu par
  le renfoncement — et en sombre `--surface-2` est plus foncé que la surface, le creux tient dans
  les deux thèmes. Le placeholder garde sa phrase entière et s'**ellipse** quand la place manque,
  au lieu de se couper en plein mot (défaut mesuré à 390 px).
- **Les lettres du répertoire parlent serif.** La lettre de classement (`.dir-l`) passe en Source
  Serif 4 13,5 px/600 — la police et la graisse déjà embarquées : un index d'ouvrage, pas du
  chrome. Le rail A→Z reste en mono (cibles minuscules, la lisibilité prime).
- **Une seule famille d'ombres en clair.** Les élévations du thème clair (`--shadow`, `-lg`,
  `-up`, `-dock`, `-bar`) sont teintées primaire (23,71,127), comme l'étaient déjà les boutons
  remplis ; les voiles restent à l'encre (un voile assombrit, il n'élève pas) et le sombre garde
  ses ombres noires.
- **Neuf variantes tonales suivent leur base.** `--primary-soft/-100/-200`, `--ok-soft`,
  `--done-bg`, `--tag-bg` (clair) et leurs pendantes sombres se **dérivent** par `color-mix`
  (`@supports`, repli hex intact), aux pourcentages mesurés qui reproduisent le hex actuel à
  ≤ 4/255 par canal — aucun changement visible, mais changer une base met à jour sa famille.
  `--primary-300`, `--critical-soft` et `--verify-soft` restent en hex : leur écart au mélange
  pur (Δ 5 à 16) est un accord de teinte voulu.
- **Au palier cockpit (≥ 1200 px), le chrome s'efface derrière ses contrôles.** Mesuré à
  1280 px : la rangée de commandes était une bande blanche de bord à bord au contenu arrêté à
  x = 256 (1024 px de vide). Les deux rangées collantes prennent le fond de page ; boutons et
  cartes, qui portent déjà leurs bordures, se lisent comme des contrôles posés sur la page.
- **Pilote View Transitions.** Les traversées accueil → fiche (sans session vive) et
  fiche → bibliothèque se font en fondu de 180 ms piloté par le moteur (`vtWrap`) — trois
  gardes : API présente (sinon comportement d'avant au caractère près), aucune crise à l'écran
  (le mouvement reste réservé à l'alarme), et `prefers-reduced-motion` coupe tout. ⚠ Sous VT le
  rendu est asynchrone d'une frame : deux sondes qui lisaient le DOM juste après un clic de
  carte ont été mises au standard du dépôt (attente de condition réelle, discipline `amorce()`).
- **L'écran de bienvenue étroit est composé.** Le glyphe de marque (masque `logo-glyph.svg`,
  couleur de filet, décoratif) habite les ~430 px de vide mesurés entre le texte et
  « Commencer » ; `text-wrap:balance` équilibre les titres non clampés.
- **Étudiés et écartés, avec la raison** (consignée dans AGENTS.md) : entrées `@starting-style`
  (les keyframes `veilIn`/`riseIn`/`menuIn` couvrent déjà le besoin), duplication des neutres en
  oklch (une copie par token est la liste tenue en double de v4.37.0), scrims dérivés de
  `--ink` (en sombre l'encre est claire : le voile deviendrait blanchâtre).

## [5.0.10] — 2026-08-05
### Une connexion IndexedDB fermée n'est plus une panne : elle se reprend toute seule

Signalé à l'usage sur un appareil synchronisé — « Erreur inattendue · Détail technique : Failed to
execute 'transaction' on 'IDBDatabase' : The database connection is closing ».

- **La cause.** Une connexion IndexedDB se ferme **sans que l'application le demande** : quand un
  autre onglet migre la base ou l'efface, `onversionchange` la libère (c'est nous qui appelons
  `close()` là) ; une page qui commence à se recharger les ferme toutes — et la bascule d'espace
  comme l'écouteur `storage` déclenchent un `location.reload()` sans arrêter la synchronisation ;
  un moteur mobile peut enfin les reprendre en arrière-plan. Le handle mort restait posé, et
  **toute transaction suivante levait `InvalidStateError`** : la synchronisation échouait, et le
  message affiché livrait le libellé brut du moteur — qui ne désigne pas sa cause et envoie
  chercher la panne du mauvais côté (réseau, serveur, compte).
- **Le remède, en un seul point d'écriture.** Toute méthode publique du backend IndexedDB est
  enveloppée **par une boucle, jamais par une liste** : une méthode ajoutée demain est couverte
  sans qu'on y pense (même patron que `persistLive` pour la session et `edCommit` pour le
  brouillon — une liste recopiée finit toujours par diverger, et le trou est silencieux). Un
  handle mort n'est plus jamais gardé, et l'appel qui tombe dessus **rouvre et réessaie une fois**
  — au-delà l'erreur remonte, une base réellement indisponible devant se voir. Un drapeau
  interdit cette reprise pendant un **effacement** de données : rouvrir recréerait la base qu'on
  efface.
- **⚠ Piège de spécification, appris à la mesure** : l'événement `close` ne se déclenche **pas**
  sur une fermeture explicite — il est réservé aux fermetures anormales. Un correctif qui n'aurait
  écouté que lui serait resté inerte sur le chemin le plus fréquent.
- **Le message cesse de livrer le libellé du moteur.** Nouvelle famille d'erreur de
  synchronisation : « Stockage momentanément indisponible » dit la cause probable (application
  ouverte dans un autre onglet, page en cours de rechargement), **qu'aucune donnée n'est perdue**
  et que la synchronisation reprend automatiquement.
- **Le dernier angle mort du dispositif est fermé** (`scripts/audit-stockage.mjs`, 19ᵉ harnais).
  Le stockage local — la fonction dont tout dépend en intervention — n'était mesuré que par ses
  parties **pures** : `npm run check` lit du texte, `npm test` charge `index.html?__actest`, qui
  n'amorce pas l'application et n'ouvre donc **aucune base réelle**. Les deux garde-fous étaient
  verts pendant que la synchronisation échouait chez l'utilisateur. Le harnais coupe la connexion
  *sous* l'application, exactement comme le moteur le ferait, et vérifie que l'appel suivant
  réussit — lecture comme écriture groupée, par où passe le pull de synchronisation. Vérifié
  capable d'échouer sur les deux moteurs.

## [5.0.9] — 2026-08-04
### Quatre défauts d'affichage signalés à l'usage, et l'un d'eux n'était mesurable par aucun harnais

- **La réponse attendue enroule au lieu d'écraser le geste** (vue « Toute la fiche » › Parcours,
  capture à l'appui). `.pc-r` était `flex:none` dans une rangée qui n'enroulait pas : le seul objet
  compressible était donc l'**action** (`.pc-t`, `min-width:0`). Mesuré sur un cas adverse à
  320 px — « Curariser… » tombait à quelques pixels de large pendant que la pilule sortait de la
  carte. On perdait ainsi l'information principale *et* la secondaire. Le remède est déjà écrit
  dans ce fichier pour ce défaut exact, sur la feuille « Consulter » (`.rs-v`) : la pilule prend sa
  propre ligne, alignée sur le texte. **Une seule grammaire — on enroule, on ne tronque jamais.**
- **Chaque branche d'une décision porte son étiquette, et une branche sans carte n'est plus
  muette.** L'étiquette était mise en attente puis posée devant la première *carte* de la branche —
  or `flowPlan` n'en émet pas toujours : une branche qui rejoint le point de convergence ou qui
  reboucle sur un bloc déjà décrit ne produit qu'un renvoi. Mesuré sur la fiche d'exemple
  Anaphylaxie : seule « NON — RÉFRACTAIRE » s'affichait, « OUI — STABILISÉ » n'a **jamais** été
  rendue. L'étiquette s'émet désormais à l'ouverture de la branche (même position dans le cas
  nominal, présente dans les autres), et le renvoi se dessine — « → n », « ↺ n », « ▪ fin », le
  vocabulaire abrégé de l'Échelle — mais **seulement quand la branche n'a pas de carte** : sinon le
  pied de la carte précédente le dit déjà, et l'on écrirait deux fois la même chose. Tout y reste
  **inerte** (doctrine du plan, vérifiée).
- **⚡ Les cibles de complication se reconnaissent dans le schéma** (proposition de l'auteur :
  « mettre un éclair et en rouge ? »). Le SVG était la **seule** des quatre vues de structure où
  une cible de complication se dessinait comme un bloc d'étapes ordinaire — donc comme *l'étape
  d'après*, le défaut exact mesuré en v4.26.0 (« 5 Laryngospasme »). L'Échelle, le tableau Statique
  et la vue Parcours ont toutes leur section « À tout moment ». Registre **ALERTE en CONTOUR**
  (v4.26.1) : bandeau d'en-tête teinté, liseré et cadre rouges, **corps du bloc inchangé** — un
  aplat rouge permanent désensibilise au rouge, qui appartient ici aux étapes vitales dessinées à
  l'intérieur. La couleur n'est jamais seule (règle 8) : pastille « ⚡ À TOUT MOMENT » en toutes
  lettres, reprise dans le nom accessible du nœud. L'éclair est un **tracé** et non le caractère
  « ⚡ », qui sortirait en emoji couleur sur iOS dans un dessin qui n'a d'autre couleur que ses
  registres.
- **Un bloc complet l'est sur toute sa bordure** (« uniquement le bord gauche devient vert et pas
  le reste »). `.done` n'écrivait que `border-left-color` : un bloc **courant et complet** portait
  un cadre bleu avec une seule arête verte — deux registres sur un même trait, exactement ce que la
  v4.24.0 a corrigé en sens inverse pour la décision. Et c'est la configuration **nominale** : on
  finit de cocher le bloc où l'on est. La carte *repliée* le faisait déjà (`.closed.done`) — le
  même bloc changeait donc de registre selon qu'il était plié. Pas de fond teinté sur la carte
  ouverte, qui est la colonne d'action et porte des étapes ⚠/△ dont la boîte doit rester lisible ;
  une **décision reste exclue**, son ambre prime sur l'état.

### ⚠ Le chrome collant ne se dérive plus d'une position de défilement

« Barre d'en-tête inférieure, scroll pas très réactif, beaucoup d'à-coups » — vidéo à l'appui, où
les deux rangées collantes se désolidarisent de l'en-tête et laissent une bande vide à leur place.

`--hdr-h` est le `top` collant de la rangée de commandes, donc du quai empilé dessus. Il était
dérivé du **`bottom`** de l'en-tête, c'est-à-dire d'une *position*. Or, au rebond de fin de course,
iOS **translate tout le document**, en-tête collant compris : `bottom` grandit, `--hdr-h` grandit
avec lui, les deux rangées descendent — puis reviennent. À la cadence du doigt, c'est le
tremblement filmé. C'est la **hauteur** qu'il fallait mesurer : elle ne dépend d'aucun défilement,
et c'est la seule des deux qui exprime ce que la valeur veut dire. Idem pour `--stick-top`, devenu
une somme de hauteurs ; `stickBase()` garde ses rectangles là où c'est juste — `ovScrollEl`, qui
vise une position d'écran à l'instant du saut.

Même famille que le rail A→Z (v5.0.2) et que la hachure des placards (v5.0.6) : **on n'ancre
jamais à un repère qu'on ne contrôle pas**, et ce que le compositeur fait du rendu n'est visible
dans aucune mesure de la page — un harnais Blink reste vert. Le témoin **déplace** donc l'en-tête
sans changer sa hauteur, stand-in fidèle de ce que fait le compositeur, et vérifie que la géométrie
du chrome ne bouge pas d'un pixel (vérifié capable d'échouer : défaut réintroduit → 3 rouges).

Bénéfice second, et il compte autant : la valeur devenant **constante**, la garde d'écriture
devient un vrai no-op — on cesse d'invalider le style de tout le document (une propriété
personnalisée posée sur `<html>`) à chaque évènement de défilement. Et la passe est désormais
**coalescée par image** au lieu d'être branchée sur l'évènement : elle lit quatre rectangles puis
écrit trois propriétés, un couple lecture/écriture qu'on n'intercale plus dans le pipeline de
défilement (même discipline que `svPaintArrows`, v4.14.10). L'appel direct de `render()` reste
synchrone — `landOnBout` se mesure contre `stickBase()`, qui doit avoir été resynchronisé avant.

### Témoins

`audit-doctrine` : trois sections neuves (15 contrôles) — le parcours sur un cas **adverse
construit** (réponse longue, branche qui reboucle, à 320 px : sur les fiches d'exemple aucune
réponse ne déborde, le contrôle serait resté vert sur le défaut), la géométrie du chrome sous
déplacement, et les quatre côtés d'un bloc complet. `audit-complications` : 5 contrôles sur le
schéma, dont un qui vérifie d'abord que le nœud **existe** — et l'on y mesure la *propriété* (le
nœud se distingue par un mot ET par le registre, aucun autre ne l'emprunte), jamais la valeur d'un
hex isolé, qui rougirait sur un changement de token qui serait juste.

**⚠ Une leçon de méthode, payée à l'écriture.** Le correctif du bloc complet a d'abord été livré
inerte : le commentaire qui l'explique portait un **`*/` en trop**, le texte restait à nu et le
parseur avalait la règle suivante — le défaut de cascade décrit dans `AGENTS.md` depuis la
v4.74.2, reproduit à la lettre. C'est la mesure qui l'a dit, pas la relecture ; `check-syntax` le
nomme précisément (« fermeur de commentaire sans ouvreur »), il suffisait de le lancer avant.

## [5.0.8] — 2026-08-04
### Le chapeau se glisse entre les critères et le bouton

Question posée : « remonter *Confirmer le diagnostic* au-dessus de *Ne pas oublier* — est-ce
incompatible ECAM/QRH ? ». **Non — c'est l'ordre canonique, et c'est celui d'avant qui s'en
écartait.** Un QRH imprime le titre et la condition d'entrée au-dessus des recall items ; sur ECAM
le titre de l'alerte — qui *est* la condition — précède les lignes d'action. La séquence est
condition → memory items → read-and-do ; on avait memory items → condition.

- **Le chapeau ne passe pas SOUS le bouton, et c'est tout l'arbitrage.** Le descendre simplement
  sous l'étage de la condition d'entrée le mettrait *après* « Confirmé — démarrer la session », le
  bouton vivant dans cet étage : on l'aurait rangé derrière le geste qu'il doit précéder. Il se
  glisse donc **entre les deux** — la lecture devient exactement celle du QRH, et le bouton porte
  l'acquittement des deux.
- **Une fois la session démarrée, rien ne change de ce qui existait** : le chapeau replié revient
  en tête et la condition d'entrée descend avec son étage (T3 + T5). Le débat ne portait que sur
  l'écran d'avant.
- **⚠ Ce que cela coûte, mesuré, et il faut le savoir** : le chapeau quitte le premier écran dès
  que les critères sont longs (fiche à 8 critères, 390 × 844 : il naissait à y = 130, il naît à
  y = 813). Sur une fiche ordinaire il y reste **entier** (571 → 786 à 390 × 844). Et comme le
  bouton flotte quand il est sous le pli (v4.73.0), on peut démarrer sans avoir défilé jusqu'aux
  memory items.
- **Ce qui rend ce coût acceptable est le lot T7** : un memory item ★ **reste dans son bloc** — le
  chapeau *agrège*, il ne possède pas. Rien n'est perdu : l'item se re-vérifie à sa place dans la
  checklist, ce qui est précisément le geste QRH (réciter de mémoire, puis confirmer sur la liste).
- **La condition est la présence du BOUTON, pas l'état de la session** : chez l'invité et en aperçu
  d'essai `sessStartH` est vide — une séquence qui mène à un bouton absent n'a rien à ordonner, et
  le chapeau reprend sa place en tête. Idem sur une fiche sans critères, et en mode statique, où le
  tableau porte déjà son propre ordre (`svExtras`).
- **⚠ La constante est déclarée avant le `if(useSv)`** : la coque de `main.innerHTML` la lit aussi
  (c'est elle qui décide si le chapeau est encore rendu en tête de colonne). Posée dans la branche,
  elle aurait été hors de portée — même zone morte temporelle que celle payée au lot T3.
- Témoins dans `audit-doctrine` (6 contrôles) : ordre critères → chapeau → bouton, chapeau rendu
  **une seule fois**, retour en tête en session, et la branche sans critères. Vérifiés capables
  d'échouer. La fixture de la section « démarrage » a dû être **rallongée à onze critères** : avec
  le chapeau descendu, huit ne suffisaient plus à faire défiler à 390 px, et le contrôle ne
  rencontrait donc plus son cas.

## [5.0.7] — 2026-08-04
### Démarrer une session dépose sur le haut du premier bloc

Signalé à l'usage : « lorsqu'on clique sur *démarrer la session*, s'assurer que le haut du premier
bloc d'étapes soit visible ».

- **Ce que le geste fait disparaître au-dessus du doigt.** Presser « Confirmé — démarrer la
  session » replie le chapeau « Ne pas oublier » en une ligne (T3), referme la condition d'entrée
  (acquittement par l'action) et remonte l'étage « Prise en charge » en tête (T5). Le défilement,
  lui, ne bougeait pas : on atterrissait **au milieu** de la carte du bloc, son numéro, son titre
  et « Vous êtes ici » au-dessus du pli, à l'instant précis où le soin commence.
- **Mesuré, sur le cas pour lequel `.sess-start.afloat` existe** — une condition d'entrée longue
  (8 critères), qu'on lit en défilant pendant que le bouton suit, flottant : après le clic, le haut
  de la carte tombait à **−206 px à 320 × 640** (324 px au-dessus des couches collantes) et à
  **+20 px à 390 × 844**, soit 98 px *sous* l'en-tête collant. Après : **+8 px sous le quai** dans
  les deux formats, et **2 → 5 étapes cochables** entièrement visibles à 320 px.
- **Ce n'est pas un défilement automatique (règle 11).** La règle vise l'écran qui bouge sous
  quelqu'un qui n'a rien demandé ; ici la page vient d'être rendue de neuf et le geste est une
  navigation demandée d'un tap — même arbitrage que `landOnBout` à la réentrée et que `cxEnter`.
- **Un seul point d'écriture** (`startSessionGesture`), partagé par le bouton du parcours et son
  homologue du tableau statique — les deux copies faisaient déjà la même chose à la ligne près.
- **⚠ Ce chemin est celui du BOUTON, jamais celui du cochage** : un démarrage implicite (cocher une
  étape, armer un minuteur) passe par `renderKeepAnchor` et continue de ne pas déplacer d'un pixel
  l'élément touché (invariant ECAM v4.4.0).
- **⚠ Et la règle de visibilité de `landOnBout` a été essayée puis mesurée fausse ici** : elle exige
  la carte ENTIÈRE à l'écran, or une carte de bloc dépasse presque toujours le pli (615 px sur 640).
  Elle défilait donc même quand le haut était déjà à sa place, y compris sur les fiches courtes, et
  laissait la page décalée pour les gestes suivants — **deux témoins de dépliant l'ont dit, à
  −51 px** (le panneau du quai ne se posait plus sous le quai). On ne garantit que ce que l'usage
  demande : **le HAUT** de la carte sous les couches collantes, et rien ne bouge s'il y est déjà.
- **Les trois densités ont chacune leur porteur** : `.ov-block` (journal), `.sv-cell.cur`
  (statique), `.nav-wrap` (vue guidée d'une fiche sans algorithme) — oublier le troisième, c'était
  ne rien faire précisément sur les fiches mono-bloc, sans que rien ne le dise.
- Témoins dans `audit-doctrine` (11 contrôles) : le cas est **construit** (les fiches d'exemple ne
  le rencontrent pas), il est prouvé par **contrefactuel** (on repose la page où elle était au clic
  et l'on remesure), la vue guidée a le sien, et la **non-régression** est l'autre moitié — sur une
  fiche courte, le démarrage ne déplace pas la page d'un pixel. Vérifiés capables d'échouer.
