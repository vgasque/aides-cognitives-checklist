# Archive doctrinale — extraite d'AGENTS.md (v5.10.3)

> Contenu repris À L'OCTET depuis AGENTS.md (patron du découpage du changelog, v5.0.0) —
> aucune réécriture. Ces entrées restent NORMATIVES : elles portent les décisions et leurs
> raisons ; AGENTS.md garde les règles vivantes et renvoie ici. Empreinte du bloc extrait :
> sha256:2ff30a89c419.

## Lot v5.10 — « Page » : la feuille SFAR devient un document

> Brief d'implémentation externe (quatre lots, maquettes aux trois formats). La vue « Page » du
> cran « Toute la fiche » était une bonne vue d'algorithme enfermée dans une mauvaise page : une
> colonne qu'on déroule, sans titre, sans date, sans source, et **sans les repères posologiques**
> — qui partent dans le rail au-delà de 780 px, donc n'existent nulle part sur le papier.

**A133. UNE PAGE A UNE LARGEUR D'AUTEUR, ET C'EST L'ÉCHELLE QUI S'ADAPTE (v5.10.0, lot 3).**
`.sv-sheet{width:var(--sheet-w,1130px)}` — jamais un pourcentage. C'est ce qui en fait une PAGE :
la géométrie ne dépend plus de l'écran, donc l'image est la même au chariot, sur le téléphone et
sur le papier — et **c'est cette image qui se mémorise** (« les doses sont en bas » ne s'apprend
que si c'est vrai sur les trois appareils). Sous 640 px, AUCUNE règle de composition : pas de
reflux, pas de pile, pas de réordonnancement.
· **POURQUOI PAS DE REFLUX SUR TÉLÉPHONE — c'est contre-intuitif et c'est le cœur du lot** : une
  pile lisible EXISTE DÉJÀ, c'est l'onglet « Parcours ». Si la Page se refluait aussi, les deux
  onglets convergeraient vers le même objet et l'un des trois ne gagnerait plus rien.
· **L'AGRANDISSEMENT EST UNE TRANSFORMATION** (`transform:scale`, cinq pas discrets), **jamais un
  `zoom` CSS** — celui-ci refait la mise en page au lieu de la transformer, et à petite échelle les
  tailles minimales de police des moteurs mobiles reprennent la main, c'est-à-dire exactement ce
  qu'on cherchait à figer. Ni pinch écrit à la main (il exigerait `touch-action:none`, qui tue le
  défilement et ne se rend pas depuis un enfant), ni échelle continue (une échelle qui glisse fait
  travailler une image en cache — c'est là que le texte « bave »).
· **UN CALANT PARENT reçoit W×k et H×k**, sinon le défileur ignore la transformation et ne défile
  sur rien. Il est mesuré en `offsetWidth`/`offsetHeight`, qui sont des mesures de MISE EN PAGE :
  elles ignorent le `transform`, donc **elles ne se divisent ni par l'échelle ni par `zoomF()`**.
  À k = 1 on ne pose RIEN — le cas nominal n'a ni transformation, ni taille forcée, ni image
  intermédiaire à la première peinture.
· ⚠ **L'AJUSTEMENT NE SE FAIT PAS TOUT SEUL À L'OUVERTURE — arbitrage MESURÉ contre le brief.**
  Il demandait « ⤢ ajuster à CHAQUE ouverture ». À 390 px, ajuster une feuille de 1130 px donne
  k ≈ 0,28 : **toute cible tapable tombe alors sous 13 px réels**, dans un écran qu'on ouvre
  PENDANT un soin — et `audit-a11y`, que la recette du brief exige de garder vert, le dit aussitôt.
  La feuille s'ouvre donc à la taille d'auteur et « ⤢ Ajusté » est UN TAP. L'échelle n'est **jamais
  mémorisée** (consultation, pas réglage — même statut que `state.allTab`).

**A134. LE TRACÉ EN GRILLE UNIQUE — UNE BRANCHE PROFONDE PEUT ÊTRE PLUS LARGE QUE SA PARENTE
(v5.10.0, lot 2, `svGridPlan`).** Les branches d'une décision étaient des conteneurs IMBRIQUÉS :
chaque branche vivait dans la boîte de sa mère, donc la largeur se divisait à chaque niveau —
1130 → 565 → 282 → 141. Sur une fiche réelle à quatre niveaux, la partie la plus GRAVE de
l'algorithme se retrouvait dans la colonne la plus étroite, sous le plancher d'auto-fit, empilée et
fourches masquées. Désormais **chaque nœud est un FRÈRE** placé par `grid-column`/`grid-row` sur
UNE grille de 6 pistes (tronc sur 4, centré) : il occupe l'étendue libre à sa ligne, pas une
fraction de sa parente.
· **SIX PISTES** parce que c'est le plus petit nombre divisible par 2 ET par 3 : deux branches se
  partagent 3+3, trois branches 2+2+2, sans piste orpheline. **La piste libre de chaque côté du
  tronc n'est pas décorative** — c'est elle que les branches viennent occuper.
· ⚠ **LE TEST LE PLUS SIMPLE ET LE PLUS DÉCISIF DU LOT** : `querySelectorAll('.sv-algo
  [style*="display:grid"]').length === 0`. Une seconde grille à l'intérieur reconstruirait le
  problème que ce lot existe pour supprimer. Mesuré au rendu, aux trois formats.
· ⚠ **UN ARBITRAGE ASSUMÉ CONTRE LE PSEUDO-CODE DU BRIEF, TRANCHÉ PAR SA PROPRE MAQUETTE.** Le
  brief décrit une répartition RECALCULÉE LIGNE PAR LIGNE, avec « si une seule branche est encore
  vivante, elle reprend la position de TRONC (4 pistes) ». Or sur la fiche de référence, la branche
  « réfractaire » reçoit 5 pistes et les GARDE sur toute sa hauteur alors que sa voisine est close
  dès la première ligne : la règle par ligne l'aurait **rétrécie de 5 à 4** en descendant, soit
  l'inverse de l'effet cherché. La répartition est donc faite **UNE FOIS par décision** (colonnes
  stables d'une ligne à l'autre, donc lisibles), et la « reprise de largeur » vient d'où elle vient
  réellement : **les branches d'une décision se partagent l'étendue ENTIÈRE de leur contexte**, pas
  la part de leur parente. Vérifié sur la maquette : décision 8 → 5 + 1 pistes, bloc 9 sur 5 pistes
  contre 4 au tronc. Prorata de la hauteur totale, minimum 1 piste, reste à la plus haute, départage
  par l'index — deux appels donnent la même sortie.
· **REPLI** (« en cas de doute, le rendu simple, jamais le rendu embrouillé ») : au-delà d'une
  branche par piste disponible, on n'émiette pas — les branches s'EMPILENT à pleine étendue,
  chacune sous son étiquette.
· **LA FOURCHE EST DESSINÉE EN DIVS, PAS EN SVG.** Un calque SVG exige des coordonnées, donc une
  mesure après rendu, donc un recalage à chaque changement de contenu — ça a été tenté et ça a
  cassé deux fois (viewBox déclaré ≠ boîte réelle → déformation non uniforme). Les bras se posent en
  POURCENTAGE de l'étendue, calculés sur le CENTRE de chaque branche : justes quelles que soient
  les largeurs réparties, **sans qu'on mesure quoi que ce soit**.
· **LA CONVERGENCE REDEVIENT DU TEXTE** : la pilule « → n » / « ↺ n » était déjà la vérité (elle
  survit à l'impression, au lecteur d'écran, à une branche repliée) ; le brin gris qui la doublait
  disparaît, et `svPaintArrows` n'a plus qu'un office — les RETOURS ↺ en gouttière.
· ⚠ **LA VOIE DE RETOUR NE SORT JAMAIS DE LA GOUTTIÈRE** (signalé à l'usage : « le début de la
  flèche se superpose à un bloc »). Avant la grille, TOUT le contenu commençait au même x : le
  trait tiré du contenu vers la gouttière était un talon de 6 px qui ne pouvait rien traverser. Dans
  une grille à six pistes, une pilule de retour vit en piste 3 ou 5 — le même trait traversait alors
  les branches voisines, et la flèche d'arrivée entrait dans le bord gauche d'un bloc du tronc en
  coupant la piste libre. **Les deux extrémités sont bornées au bord gauche de la grille** : mesuré
  après, tracé entre x = 25 et 31, première cellule à 31.

**A135. LA COQUE DE FEUILLE — ET L'AVERTISSEMENT DE VALIDATION, QUI EST UN POINT DE SÉCURITÉ
(v5.10.0, lot 1).** Cartouche · entrée · algorithme · référence · doses, dans cet ordre, toujours :
la composition change aux paliers, **l'ordre du DOM jamais** (ce sont des GRILLES, pas un
réordonnancement — un lecteur d'écran lit la même suite aux trois largeurs, et la même qu'avant le
lot ; un témoin compare le `textContent` de `.sv-sheet` à 360, 768 et 1280).
· ⚠ **CERTAINES FICHES PORTENT « Fiche générée par IA le … — à relire et valider avant usage »**,
  que le prompt d'import IMPOSE en dernière ligne des sources — et **cette phrase n'apparaissait
  NULLE PART à l'écran**. Une feuille imprimée et affichée au mur sans elle est un danger. Elle est
  donc dans le cartouche, au registre ALERTE **en CONTOUR** (bord gauche + encre), jamais un aplat :
  A11 réserve la masse colorée au minuteur échu, et une feuille teintée désensibiliserait au rouge
  des étapes vitales qu'elle porte. La détection lit `f.sources` sur le motif que le prompt écrit —
  elle ne devine rien, et `audit-prompt` en vérifie le contrat.
· **DÉGRADATION — ce qui n'a rien à dire N'EXISTE PAS** : pas de source → pas de bloc ; pas de dose
  → pas de bande de pied (jamais un titre seul) ; ni surveillance ni excursion → pas de colonne de
  référence, et l'algorithme prend toute la zone. Un panneau qui affirmerait « 0 minuteur » est le
  bruit que ce dossier refuse partout.
· **LES COMPLICATIONS QUITTENT LE PIED DU TABLEAU POUR LA COLONNE DE RÉFÉRENCE** : elles ne sont
  pas la suite de l'algorithme, elles sont ce qui peut survenir pendant qu'on le déroule. Elles y
  gardent leur ⚡ et n'ont toujours pas de numéro de séquence (le numéroter les ferait lire comme
  « l'étape d'après », défaut mesuré en v4.26.0).
· **UN SEUL POINT DE LECTURE DES REPÈRES** (`posoParts`) : la table à trois colonnes ne pouvait pas
  reprendre le balisage des cartes, mais recopier la coupure sur « : » aurait fini par découper
  autrement ici et là — sur la seule donnée du fichier qui porte une dose.
· **LA RECHERCHE DE L'ONGLET COUVRE LA FEUILLE ENTIÈRE** (`.sv-sheet` et non plus le seul tableau) :
  cartouche, référence et doses seraient sinon restés introuvables.
· **LA FENÊTRE « TABLEAU » DE L'ÉCRAN D'ENTRÉE MONTRE LA MÊME FEUILLE** (demande de l'auteur : « ça
  ouvre une fenêtre déjà toute prête ») — un seul générateur (`svSheetHtml`) des deux côtés ; deux
  rendus de la même page auraient fini par diverger, et c'est justement AVANT le soin qu'on vient la
  lire en entier. Elle y est INERTE au geste près de l'ÉCHELLE : on vient la REGARDER, pas la
  conduire.
· **ET LA MÊME FENÊTRE S'OUVRE DEPUIS LE SOIN** (demande de l'auteur) : l'onglet « Page » porte une
  porte « ⤢ Plein écran » qui appelle le MÊME chemin (`openPlanSheet('page')`), donc la même coque,
  la même sortie (✕, Échap, voile, retour système) et le même générateur. Une seconde surface plein
  écran recopiée serait un second objet à tenir — et l'on perdrait la propriété qui fait tout le
  lot, à savoir que c'est la MÊME page partout. Elle n'est pas émise DANS la fenêtre : un bouton
  qui rouvre la surface où l'on se trouve déjà est le bouton mort de la doctrine.

**A136. A8 S'APPLIQUE À LA FEUILLE, ET AUX TROIS FORMATS (v5.10.0).** Le brief bornait les 44 px
« sous 640 px seulement ; au-dessus, la densité prime ». Mesuré, cela ferait DEUX images de la même
feuille — or l'argument central du lot est qu'elle est la même partout. Et `audit-a11y` mesure à
390 px, session ouverte : il l'a dit à la première passe (bande de décision à 31 px, sortie à 32).
Le plancher est donc posé une fois pour toutes sur `.sv-cell[role=button]`, `.sv-band`, `.sv-opt`,
`.sv-jump` et les touches d'échelle. Coût dit : la feuille est un peu plus haute — c'est le bon
côté du compromis pour un document qu'on lit avec des gants.

**A137. CE QUI EST PURGÉ, ET POURQUOI LES BANDES COLLANTES PARTENT MALGRÉ L'INTERDIT (v5.10.0,
règle 14, émissions vérifiées au grep).** `.sv-tb`, `.sv-decwrap`, `.sv-cols`, `.sv-br`,
`.sv-fork`, `.sv-merge`, `.sv-cxband`, les brins gris `.lg`/`.lgh` de la gouttière, `svExtras`,
`svTableHtml`, le peintre de fourches/convergences et son élargissement par niveau, les attributs
`data-jto`/`data-jback` (A112 : un attribut émis sans lecteur est un contrôle qui a l'air vivant),
et **`svStickBands`** avec ses `top` cumulés, son plafond à trois niveaux et son z-ordre.
· **LES BANDES COLLANTES ÉTAIENT DANS LES INTERDITS DU BRIEF, ET IL FAUT DIRE POURQUOI ELLES
  PARTENT** : elles existaient pour UN cas — la branche EMPILÉE sous 640 px, où la question sortait
  de l'écran pendant qu'on lisait ses étapes (844 px de contenu mesurés sans elle en v4.13.1). Le
  lot 3 supprime l'empilement : la feuille garde sa géométrie et c'est l'échelle qui s'adapte. Il
  n'y a donc plus de branche empilée, plus de question qui s'échappe, et plus de pile de décalages à
  mesurer. **La cause est partie, le mécanisme la suit.** Partent avec elles, pour la même raison,
  les deux autres ajouts « sous 640 px » du brief : le rappel de décision (`.sv-branch-recall`) et
  le corps de lecture agrandi — tous deux présupposaient la pile, et le second changerait en outre
  la géométrie que le lot existe pour figer.
· **LA SECTION DE DOCTRINE QUI LES MESURAIT A CHANGÉ DE PROPRIÉTÉ, PAS DE SUJET** : elle vérifie
  désormais ce que le lot PROMET, c'est-à-dire la définition du fini du brief — aucune grille
  imbriquée, largeur d'auteur et six pistes identiques à 360 / 768 / 1280, même placement de chaque
  nœud, même texte dans le même ordre.

**A138. CE QUI N'EST PAS LIVRÉ, ET IL FAUT LE DIRE (v5.10.0).** Le cartouche **ne se RÉPÈTE PAS**
en tête de chaque feuille imprimée. Seul un `<thead>` de table se répète nativement ; le simuler
demanderait un `position:fixed` qui recouvrirait le contenu de toutes les pages sauf la première,
ou de refaire la feuille en table — c'est-à-dire de reperdre la grille unique que le lot 2 vient
d'écrire. Ce qui EST tenu : le cartouche ne se sépare pas de ce qu'il titre (`break-after:avoid`),
aucune cellule ne se coupe, le pied porte titre + révision (donc une page détachée reste
identifiable), les doses passent à 3 colonnes en paysage et 2 en portrait, k = 1 (le papier n'hérite
jamais du zoom d'écran) — et surtout **L'ÉTAT DE SESSION NE S'IMPRIME PAS** : ✓, « ici », « hors
chemin », « ×n » décrivent une réanimation qui n'a plus lieu, et une feuille au mur qui porte le ✓
d'une session passée est une feuille FAUSSE. À rouvrir avec une vraie maquette papier multi-pages.

