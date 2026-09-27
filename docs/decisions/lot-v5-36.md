# Lot v5.36 — le papier, les doublons, les liens des PDF, l'export d'une sélection, « ✓ faite » (A392)

> Fichier normatif, suite de [`lot-v5-35.md`](lot-v5-35.md) (A389-A391). Les numéros A sont des adresses :
> ne jamais renuméroter. Demandes de l'auteur du 27/09/2026, dont un PDF imprimé à l'appui.

## A392 — six retours d'usage

**1. L'impression de la Page (le PDF de l'auteur à l'appui).** Trois défauts, reproduits par une impression PDF réelle
de Chromium (`page.pdf`), avec et sans arrière-plans, zoom de confort 100 et 115 %, en-têtes et pieds de page :
- **Sans « imprimer les arrière-plans », les traits du tronc et des fourches disparaissaient** : ils étaient dessinés
  en `background`. Il ne restait que les pointes (bordures). Tous les traits de la Page (tronc, raccord de pilule,
  réunion, barre et descentes de fourche, rail, barreau) sont désormais des **bordures**.
- **Les voies pointillées étaient décalées d'une page, « très rallongées », avec une page blanche en fin.** Un
  calque SVG unique couvrait la feuille et se recalait page par page, d'après une hauteur imprimable et une position
  de la feuille sur le papier que rien ne connaît : elles dépendent des en-têtes, des pieds de page, des marges du
  moteur et de ce qui précède la feuille. Le calque, plus haut que le contenu, fabriquait aussi la page blanche.
  **Nouveau principe : une cale par page.** `svPaginate` insère une vraie boîte de 12 px (`.sv-pgb`, portant
  `break-before:page`) avant la rangée qui ouvre chaque page suivante. `svPaintArrows` dessine chaque morceau de voie
  dans le calque de SA page (`.sv-gutk`, accroché à la cale, coordonnées locales). Le calque suit la cale où que le
  navigateur la pose, et ne dépasse jamais sa page. Il faut une boîte et non une marge : Chromium supprime la marge
  haute après un saut forcé, et le calque sortait alors de la page. La frontière passe 4 px sous le haut de la cale
  (`SV_PGB`) : sous le pied des pilules de la page d'avant, au-dessus de l'approche de la cible. Une **marge de
  sécurité** de 48 px garde nos sauts avant ceux du navigateur.
- **Un re-rendu pendant l'impression** (passage à la largeur A4) emportait cales et calques : seules les voies de la
  page 1 survivaient. `svPaintArrows` **repagine** désormais si la pagination est absente ou pointe vers des éléments
  retirés du document.
- **Les numéros de bloc perdaient leur cadre sans les arrière-plans** (signalé par l'auteur) : à l'écran, c'est une
  pastille pleine (fond encre, chiffre blanc), donc sur papier il ne restait qu'un chiffre blanc sur blanc. À
  l'impression, le numéro devient un **cadre** : fond papier, chiffre à l'encre, bordure de 2 px (ambre pour une
  décision). Il est identique avec ou sans arrière-plans ; l'écran ne change pas.
- En plus : **la page s'imprimait BLANCHE à 1280 px** dès qu'une seconde étape suivait la Page (enveloppe
  `.care-flat`, que la règle « tout sauf la feuille » masquait en entier). Les sélecteurs d'impression visent
  désormais ce qui ne contient pas la feuille, et masquent aussi la note locale voisine.

Mesuré sur une fiche proche de celle de l'auteur (7 blocs, sortie « aller à 7 », boucle vers 3) : deux pages, les
voies justes et à leur place sur les deux, aucune page blanche, dans les quatre configurations.

**2. Les cartes sous la Page étaient en double** (signalé : « à vérifier / diagnostics différentiels / références
juste en dessous de la Page sont redondants »). La Page porte déjà « À vérifier », les diagnostics à éliminer, les
doses et les sources. En mode Page, **seule « Références » reste** : c'est la porte unique des documents joints,
des schémas et des renvois « Voir aussi » (A367), que la Page ne montre pas.

**3. Le chiffre des losanges du parcours était décentré** (mesuré : 1,6 px en colonne, le « 2 » touchait le bord).
C'est la pastille elle-même qui était tournée de 45°, le chiffre contre-tourné. Désormais la **pastille reste
droite**, le chiffre est centré sans aucune rotation (`line-height:1`), et le **losange se dessine dessous**
(`::before` tourné, `inset:4px`, et 3 px en colonne). Mesuré : 0 px d'écart en colonne, 0,5 px dans la carte. Les
numéros restent sur une seule verticale.

**4. Exporter une sélection** (accueil, mode Sélection). Un bouton « Exporter… » (`selExp`) dans la barre, repris
par la feuille « Actions » au téléphone (« Exporter la sélection… »). Il produit **un seul fichier**, avec la même
enveloppe que l'export global (`exportData` : version 3, catégories utilisées, protocoles à part, documents joints
au choix en .zip), donc réimportable tel quel. Au passage, un export fait uniquement de protocoles emportait zéro
catégorie : les catégories se déduisent maintenant des aides ET des protocoles. La barre tient toujours sur une
ligne de 56 px à 1200 px : le quatrième acte y tronquait le compte « n cochés » (29 px manquants, rattrapé par le
témoin de la planche 20), et la marge intérieure des actes passe donc de 14 à 10 px.

**5. Les liens des PDF joints** (lecteur). Deux ajouts, sans nouvelle dépendance (pdf.js les fournit déjà) :
- `pdfPaintLinks` lit les annotations « Link » de chaque page rendue et pose une zone cliquable sur chacune. Une
  adresse externe s'ouvre dans un nouvel onglet, `noopener noreferrer`, et **seulement en http(s), mailto ou tel**
  (`PDF_URL_OK` : jamais `javascript:` ni `data:`, le PDF étant un contenu non maîtrisé), par propriétés DOM et
  jamais par HTML. Un renvoi interne fait défiler jusqu'à sa page (`pdfDestPage`).
- Le bouton **« Sommaire »** n'apparaît que si le document a des signets (`getOutline`). Il liste trois niveaux au
  plus, dans une feuille `openPickMenu` qui échappe les titres, et un tap mène à la page.

**6. « ✓ faite — plus à refaire »** (demande : « dire si une action avec un moment unique a été réalisée, si on a
utilisé le mode guidé »). Une étape `repeat:'once'` déjà cochée dans la session (`onceFaite`, tous passages
confondus) l'affiche, en vert avec son ✓, à la place de « si pas déjà faite » :
- dans le parcours de la colonne et de la feuille « Se repérer » (qui portent l'état de session) ;
- dans la Page ;
- dans le Schéma : le dessin est mis en cache sans état, donc il porte les DEUX textes, et `flowPaintState` choisit
  par la classe `faite`.

Hors mode guidé rien n'est coché, donc rien ne change. **Sur le papier, jamais** : l'état d'une session ne
s'imprime pas (Lot 4), et la Page imprime la règle (`.q-pr`).

**Témoins.** La section `audit-doctrine` « Page · A392 impression, doublons, losange, export, « ✓ faite » » vérifie :
- en mode Page, seule « Références » est sous la feuille ;
- le tronc est une bordure, et chaque numéro de bloc est encadré à l'impression ;
- à l'impression, une cale par page suivante porte son calque, la pagination se refait après un re-rendu, et tout
  disparaît ensuite ;
- le chiffre du losange est centré ;
- « ✓ faite » apparaît dans le parcours et le Schéma sur la bonne étape seulement ;
- l'export d'une sélection produit un fichier réimportable ;
- le lecteur PDF rend cliquable le lien externe (http(s), `noopener`), écarte le lien `javascript:`, mène le renvoi
  interne à sa page et propose le sommaire. Ce dernier contrôle est sauté sous WebKit, qui ne produit pas de PDF.

Le témoin a été vu échouer sur la version précédente.

## A393 — le nom du PDF, la pastille du « Chemin » dans la colonne

**Le nom du fichier PDF.** « Enregistrer en PDF » (Chrome, Safari, iOS) propose le **titre du document** comme nom de
fichier. C'était toujours « Aides cognitives ». Pendant l'impression, le titre devient celui de l'aide ou du protocole
imprimé (`printTitleOn` à `beforeprint`, que l'impression vienne du menu ou de ⌘P), puis revient à `afterprint`
(`printTitleOff`). L'invité n'imprime pas, donc il n'est pas concerné. Le système garde la main sur le reste : dossier,
caractères interdits, et le nom reste modifiable dans le dialogue.

**La pastille de branche collait au bord de la colonne** (signalé sur capture). Dans la colonne, « réponse « Non » »
débordait la rangée de 2 px et le filet était réduit à zéro ; « Non choquable » débordait de 16 px. Dans la colonne,
la pastille dit maintenant `◇ n « Non »` (le mot « réponse » reste dans la carte et la feuille). Une réponse longue
passe à la ligne **dans** la pastille, et le filet garde au moins 12 px.

**Témoins** (section A392) : le titre du document pendant et après l'impression ; dans la colonne, au moins 12 px
de jeu et de filet pour chaque pastille. Les deux témoins ont échoué sur la version précédente.

## A394 — « ↳ Branche » : une suite qui ne découle pas du bloc précédent se lit comme une branche

**Amende A376** (« la liste n'indente pas, elle écrit »). Le parcours numérotait « Chemin 2, 3… » chaque suite qui ne
découlait pas du bloc précédent. C'était un rang dans la liste, sans sens clinique, qui se confondait avec le numéro
de la décision (« Chemin 2 ◇ 2 « Non » »). Juste au-dessus, « ■ Fin du parcours » laissait croire qu'un parcours se
terminait et qu'un autre commençait. Demande de l'auteur : qu'on comprenne que c'est une branche, pas un nouveau
parcours, en travaillant les marges et les indentations.

- **L'en-tête dit la nature et l'origine, sans compteur** : « Branche » puis la pastille `◇ n « réponse »` de sa
  décision (un tap y mène). Venue d'un bloc d'étapes : « Suite de [n] ». Sans entrée (bloc joint seulement par une
  complication) : « Autre entrée ». Le groupe porte un nom accessible (« Branche de la décision 2, réponse « Non » »).
- **Ses blocs sont indentés d'un cran** (20 px, 14 px en colonne) le long d'**un seul trait** de 2 px : il part du milieu de
  l'en-tête, tourne vers « Branche » par un coin arrondi et descend jusqu'au dernier bloc. Une première version
  utilisait le glyphe ↳ de la police au-dessus d'un filet : il était plus fin que les autres flèches (la police de
  l'app ne l'a pas, le système le remplace) et le filet se superposait à lui. Refusé par l'auteur : pas de glyphe, un
  trait unique dessiné en CSS (bordures gauche et haute du même `::before`). La branche suivante repart de la marge. Il y a donc deux colonnes de numéros au plus :
  le tronc, et les branches. Les branches ne s'imbriquent pas : la liste reste à plat, une branche de branche ouvre
  sa propre branche.
- **Les marges** : 20 px de blanc avant la branche (12 en colonne), qui la détachent de ce qui précède ; l'en-tête
  est serré contre son premier bloc. Le filet horizontal de l'ancien séparateur part (le filet vertical le remplace),
  et la pastille garde 12 px de jeu à droite dans la colonne.
- **« ■ Fin »** remplace « ■ Fin du parcours » : c'est la fin de ce chemin, et il peut y en avoir plusieurs.

S'applique aux trois lieux du parcours (carte de l'écran d'entrée, feuille « Se repérer », colonne). La Page et le
Schéma ne changent pas.

**Témoins.** La section de la liste imbriquée : une branche signée par sa décision, et deux colonnes de numéros au
plus, les branches à 12 px au moins à droite du tronc, avant comme pendant la session. La section A392 vérifie
l'en-tête et le nom du groupe, l'absence de « Chemin n » et de « Fin du parcours », le filet et l'indentation dans la
colonne, et le jeu de la pastille. Tous ont échoué sur la version précédente.

## A395 — dans la Page, le jalon se lit comme une réponse, et il n'y a qu'un dessin de « SI »

**Amende A391** (« Si … : » comme le parcours). Dans une décision de la Page, deux dessins de « Si » cohabitaient : celui
du jalon, en gras à l'encre pleine, et celui des réponses, « SI » en chasse fixe ambre. Le premier, plus lourd,
prenait le dessus sur les réponses. Et le jalon s'intercalait entre la question et ses réponses, qui ne se lisaient
plus d'un tenant (signalé par l'auteur, capture à l'appui).

- **Le jalon suit les réponses**, sous un pointillé, et prend **leur forme de ligne** :
  « SI ‹compteur ≥ n› : ‹texte› ……… [⚡ complication] ». La complication visée est une pastille à droite, là où les
  réponses ont leur destination. Sans complication, pas de pointillé ni de pastille.
- **Il est gris et non ambre** (« SI », texte, pointillé, pastille fine) : il dépend d'un compteur et ne répond pas à
  la question. Le mot en gras du texte reste à l'encre.
- Dans un bloc d'étapes, même ligne, sous les étapes.
- **Les en-têtes de groupe d'étapes** (« SI Chocs délivrés ≥ 3 : ») prennent le même « SI » gris en chasse fixe.

Il y a donc **un seul dessin de « SI » dans la Page** : chasse fixe, graisse 600, ambre pour une réponse et gris pour
un seuil. Le parcours garde son « **Si** » en gras, qui convient à une liste lue de haut en bas ; le Schéma ne change
pas.

**Témoins** (section « Page · A391 ») : le jalon d'une décision vient après ses réponses et porte sa pastille ⚡ ;
réponses, jalon et groupes ont la même police et la même graisse de « SI », le jalon et les groupes sont de la même
couleur, différente de celle des réponses. Les témoins ont échoué sur la version précédente.
