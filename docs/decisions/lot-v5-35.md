# Lot v5.35 — l’accueil en une colonne, « Tout voir » à deux onglets, l’éditeur : Structure repliable et aperçu fidèle, la Page (A389-A391)

> Fichier normatif, suite de [`lot-v5-34.md`](lot-v5-34.md) (A388). Les numéros A sont des adresses :
> ne jamais renuméroter. Demandes de l'auteur (26/09/2026, capture de l'accueil au bureau) :
> « vue compacte/détaillée : pas de différence sur tablette/desktop » ; « pas très grand fan de la vue
> à 2-3 colonnes » ; retirer le ✎ et « + Nouvelle bibliothèque » de la colonne gauche, ou un seul
> « Gérer » vers « Moi » ; retirer l'onglet « Parcours » de « Tout voir », redondant avec « Se repérer ».

## A389 — une colonne à toutes les largeurs ; « Gérer » les bibliothèques ; « Parcours » quitte « Tout voir »

**Amende** A347 (le répertoire en livres côte à côte dès 780 px). **Retire** l'onglet « Parcours »
de « Tout voir » (lot T8, v5.0.0 M9, v5.6).

**1. Accueil : le défaut mesuré.** Dès 780 px, le répertoire posait un livre par groupe, en grille
de colonnes de 320 px (`repeat(auto-fit,minmax(320px,1fr))`). Dans chaque colonne, la méta était
tronquée : « Ré… », « CH », « Fic… » sur la capture de l'auteur. Le réglage « Densité » n'agissait
que dans un bloc `@media (max-width:779.98px)` : au-delà, « Détaillée » et « Compacte » rendaient
exactement la même chose.

**La règle.**
- **Une seule colonne à toutes les largeurs**, bornée à 960 px (`.dir-book`, et la ligne de compte
  qui porte « Affichage » et « Sélectionner » suit la même borne).
- **« Détaillée »** : une carte par aide, à toutes les largeurs (le dessin du téléphone, v5.30 et A362 :
  liseré de catégorie, discriminant sur sa ligne, méta complète qui passe à la ligne).
- **« Compacte »** : la liste à filets. Au bureau (≥ 1200 px effectifs, donc sans `html.zw1200` —
  règle 10, le zoom compte), le titre et la méta tiennent sur UNE ligne, la méta à droite
  (rangée de 48 px au lieu de 76). En dessous, deux lignes comme au téléphone : mesuré à 900 px,
  la ligne unique coupait les titres (« Suspicion de soumission… ») et même l'état (« À comp »).
- Mesure (15 aides en 5 catégories) : zéro méta tronquée aux deux densités, à 1280 comme à 900 px.

**2. Colonne gauche de l'accueil.** Les bibliothèques n'ont plus de ✎ par rangée, et « Nouvelle
bibliothèque » quitte la colonne. L'intertitre « Bibliothèques » porte un lien **« Gérer »**, sur le
patron de celui des catégories, et seulement s'il y a quelque chose à gérer (`mgrDeux()` : administrateur
d'une bibliothèque, ou de l'application). Il ouvre « Moi » posé sur sa section Bibliothèques
(`openLibMgr`, ancre `#acctLibs`). C'est là que vivent les rangées modifiables et « ＋ Nouvelle
bibliothèque » (A364). Chaque rangée de la colonne ne dit plus que son accès : cadenas fermé en
lecture seule, ouvert sinon. Le ✎ des intertitres de la liste (rangement par bibliothèque) et la
feuille « Gérer » du socle au téléphone ne changent pas.

**3. « Tout voir » perd l'onglet « Parcours ».** Depuis A388, il redisait la feuille « Se repérer »,
qui rend le même parcours à la même largeur. Les deux onglets restants sont la Page (par défaut) et
le Schéma. Sont purgés, règle 14 : `ovParcoursHtml`, ses cartes `.pc-*` (84 lignes de CSS), et
`.pl-brc`, `.pl-here`, `.pl-sech`, qu'il était seul à émettre (le retrait de profondeur `--pl-ind`
part avec eux). Les témoins qui mesuraient l'onglet mesurent désormais les MÊMES propriétés
ailleurs, sans disparaître avec leur porteur :
- sur « Se repérer » : réponse qui passe à la ligne sans sortir de sa rangée, branches nommées,
  vue inerte, complications « À tout moment » ;
- dans la colonne dépliée : jalon en toutes lettres, cadence de la boucle ;
- sur la Page : la recherche survit au passage par le Schéma.

**Tranché par l'auteur (26/09/2026) : « À tout moment » RESTE dans la colonne** — la décision de v5.0.0 est renversée. En v5.0.0, l'auteur avait retiré « À tout moment »
de la COLONNE d'orientation (« c'est inutile »). A388 l'y a remis, par la question Q3 (« section
“À tout moment” dans le parcours : oui »), et les maquettes validées la montraient en colonne. Les
témoins d'avant ne le voyaient plus : leurs sélecteurs visaient l'Échelle purgée en A376 et passaient
à vide. Le témoin de `audit-complications` mesure désormais l'état actuel (présente, un éclair, sans
numéro).

**Témoins.** La section `audit-doctrine` « Accueil · A389 une colonne, deux densités, gestion des
bibliothèques » vérifie quatre choses :
- une seule abscisse de groupe aux deux densités ;
- aucune méta coupée ;
- en large, « Compacte » tient sur une ligne et ses rangées sont plus basses que les cartes de
  « Détaillée » ;
- la colonne gauche n'a ni ✎ ni « Nouvelle bibliothèque », et « Gérer » n'y paraît que s'il y a à gérer.

## A390 — la Structure de l'éditeur sous 1200 px ; l'aperçu (« Essayer ») suit la vraie page

**Demande de l'auteur (26/09/2026).** Rendre à l'éditeur, sur tablette et téléphone, la Structure
que le bureau montre en colonne, « peut-être comme le Sommaire des protocoles », pour naviguer dans
une aide longue « sans que ça prenne trop d'espace lorsqu'on n'en a pas besoin ». Revoir l'aperçu :
les réorganisations depuis la v5.30 n'y apparaissaient pas. Et ne pas enregistrer les replis faits
dans l'aperçu.

**1. La Structure sous 1200 px.** La colonne (K11) n'existe qu'à 1200 px ; en dessous, elle était
masquée entre 1000 et 1199 px et n'était pas rendue du tout sous 1000. Elle devient **le dépliant
du sommaire des protocoles**, avec le même dessin et les mêmes classes (`.ref-tocwrap`,
`details.ref-toc`, `.rt-sum` : badge ≡, « Structure », compte de blocs) :
- collée sous l'en-tête, **fermée d'office** : une ligne quand on n'en a pas besoin ;
- ouverte, bornée à 56 % de l'écran et défilant seule ;
- mêmes rangées que la colonne (`edStructHtml(f,{nohead:true})` : phases, décisions, « À tout
  moment ») ;
- toucher un bloc **referme le dépliant** puis amène le bloc à l'écran (`revGoFlash`) ;
- l'état ouvert survit aux re-rendus de l'éditeur (`state.edTocOpen`), pas à sa réouverture ;
- dès 1200 px, la colonne prend le relais et le dépliant se retire (`body.view-edit .ed-tocwrap`,
  même palier que `.ed-struct`).

**2. L'aperçu suit la vraie page.** Depuis K5 (v4.72.0), l'essai a son propre Runtime et démarre au
premier geste (`ensureStarted`). Mais une quinzaine de conditions `!state.previewFrom` écartaient de
l'aperçu tout ce qui est né depuis la v5.30. L'auteur essayait donc une page qui n'existait plus :
« Ne pas oublier » avant « Quand l'utiliser », les intertitres « Prise en charge / Parcours », les
repères et les surveillances en vrac, ni quai ni minuteurs. Sont retirées les conditions qui ne
faisaient que figer ce dessin : cartes d'avant la session, cartes sous le bloc, chapitre « Parcours »,
minuteurs (`runtimePanel`, `timekeeperPanel`), colonne du cockpit, repères classés, quai
(Démarrer / Fin / Tout voir / ⚡ / Journal) et feuille « Se repérer ». Restent **celles qui
protègent** :
- rien n'est écrit ni émis (garde `essai` de `persistLive`/`endSession`, hors `liveSessions`) ;
- pas de note personnelle ni de partage ;
- pas d'exercice, puisque l'essai n'enregistre rien ;
- un menu ⋯ réduit à ce qui sert à dérouler l'essai (Se repérer, Schéma ; « Complication » avant
  la session).

Le quai dit « démarrer l'essai ». **« Fin » en aperçu** demande « Terminer l'essai ? » et rejoue
l'aperçu depuis le début (`openDraftPreview`), au lieu de ramener à l'accueil avec un aperçu à moitié
ouvert. Le commentaire du quai qui affirmait qu'« en aperçu d'essai, `ensureStarted` refuse » était
faux depuis K5 ; il est corrigé.

**3. Les replis de l'aperçu ne s'enregistrent pas.** L'aperçu porte l'identifiant de l'aide :
déplier une carte y écrivait donc l'état de la VRAIE aide. `mdFoldGet`/`mdFoldSet` lisent et
écrivent une mémoire vive (`_pvFold`) tant que `state.previewFrom` est posé, vidée à chaque
ouverture d'aperçu (aide et protocole). Les cartes de session de l'essai repartent aussi de zéro
(`state.sessFold`).

**Témoins.** La section `audit-doctrine` « Éditeur · A390 Structure repliable, aperçu fidèle »
vérifie, à 390 px :
- le dépliant est collant, fermé d'office, avec une rangée par bloc ;
- il s'ouvre, se referme au saut, et le bloc visé est à l'écran ;
- avant l'essai, l'aperçu a les MÊMES cartes que la vraie lecture ;
- le quai démarre « l'essai », sans exercice ;
- pendant l'essai, le quai de session et les cartes sous le bloc sont là, sans aucune session vive ;
- les replis de l'aide sont intacts après l'aperçu.

À 1200 px, elle vérifie que la colonne remplace le dépliant.

## A391 — la Page : une entrée, une pointe ; les retours par le bas ; l'échelle mesurée ; les moments en mots

**Signalé à l'usage (26/09/2026, deux captures du Tableau).** Des tracés qui s'entrecroisent, des coudes à 90°
qui ne se rejoignent pas toujours, une pointe « au centre du trait » qui ne dit plus où elle pointe. Et le
contenu des étapes à aligner sur le parcours (A388). Chaque défaut a été reproduit avant d'être corrigé :
l'ACR pour les retours, une fiche où une sortie vise une branche de fourche pour les pointes.

**1. Une entrée, une pointe.** Une sortie (« aller à n ») qui visait la PREMIÈRE rangée d'une branche de fourche
traçait son propre chemin jusqu'au numéro. Elle passait 8 px au-dessus de la barre de la fourche, puis posait
une seconde pointe collée à celle que la fourche dessine déjà : deux pointes l'une au-dessus de l'autre sur
le même axe, lues comme une seule pointe au milieu d'un trait. Désormais elle REJOINT la barre de la fourche
(`.sv-fork::before`, centre à `fk.t−7`) au sommet de SA branche (`.sv-br::after`, à 14 px du bord), sans pointe
propre : c'est la pointe de la fourche qui dit l'entrée. `svTreePlan` ne pose plus de marge de cible
(`sv-tgt`) sur une telle rangée (`ouvreFourche`), qui avait déjà son entrée.

**2. Les retours par le bas.** Un retour qui part d'une PILULE (« ↺ revenir à n ») sortait par son bord gauche,
à sa hauteur. Il repassait donc sur le raccord qui ENTRE dans la pilule (`.sv-jrow::before`) et traversait
le tronc de sa colonne. Dans un collecteur de fourche, le retour de la branche de droite descendait le long
de la pilule de gauche puis courait sur sa bordure basse. Il sort désormais par le BAS de la pilule (16 px du
bord) et descend tout droit : après une pilule, le tronc ne continue pas, donc rien n'est croisé. La barre
du collecteur passe 10 px sous toutes les colonnes qu'elle longe. Une ligne de décision (source `alt`) garde
l'interstice, comme avant.

**3. L'échelle se mesure.** Les voies étaient converties avec `zoomF() × svZoom`, ce qui ignorait la
transformation d'OUVERTURE de la fenêtre Tableau. Peintes pendant l'animation (échelle ≈ 0,985), elles étaient
toutes décalées d'1,5 %, soit 6 px à mi-feuille, justement là où un pointillé devait rejoindre un trait plein.
Et le `ResizeObserver` ne les redessinait pas, puisqu'une transformation ne change pas la taille. L'échelle
est maintenant la **largeur rendue ÷ la largeur de mise en page** de la feuille : elle couvre l'animation,
le zoom de la feuille et la taille du texte, dans `svPaintArrows` comme dans `svPaginate`. **Et chaque
segment pointillé est un chemin à part** : un coude tombé dans un blanc du motif semblait ne pas rejoindre
son voisin, alors que chaque segment commence maintenant sur un tiret.

**5. La jonction du tronc et la pointe du retour (signalé après une première livraison : « toujours le problème de
jonction », puis une pointe entourée).** Deux défauts de plus, mesurés :
- **Jonction.** Le tronc qui mène à une pilule doit descendre jusqu'à son raccord
  (`:has(+ .sv-jrow)` → `bottom:-24px`). Mais la règle de base portait ses exclusions en `:not()` (spécificité
  0,6,0) : ce prolongement (0,3,0) ne s'appliquait JAMAIS, et le tronc s'arrêtait 12 px avant le raccord, aux
  trois largeurs. Les trois prolongements voisins (fourche, cible, réunion) avaient le même défaut. Les exclusions
  passent dans `:where()` (spécificité nulle).
- **Pointe.** La voie de retour descendait à 7 px du numéro, et la pointe (6 px) s'arrête 5 px avant lui : il
  restait 2 px de trait (mesuré : 3), donc la pointe se posait sur le coude, à cheval sur la voie verticale. La
  voie s'écarte désormais à 18 px du numéro (`laneX`), bornée à 3 px du bord de la feuille.

**4. Les moments en mots, comme le parcours.** La Page écrivait les réglages de coche en capitales
(« CHOCS DÉLIVRÉS ≥ 3 · UNE SEULE FOIS ») et en légendes à icône. Elle reprend la grammaire d'A388 :
- « **Si** seuil : » coiffe les étapes consécutives au même seuil, reliées par un filet (`.sv-gh`, `.sv-g`) ;
- le reste s'écrit en gris sous le libellé (`pfStepQual`) ;
- le minuteur de bloc s'écrit en toutes lettres (`blkTimerTxt`) ;
- le jalon devient « Si … : … · ⚡ cible ».

**Le Schéma aussi** (demande de l'auteur, dans la foulée). `buildFlowSVG` n'écrivait aucun réglage de coche
(« libellé — réponse » seulement). Il reprend la même grammaire, dans le dessin SVG :
- une ligne « **Si** seuil : » en gris, puis les étapes du groupe en retrait le long d'un filet ;
- le réglage en petit sous l'étape ;
- le jalon sous la question (« Si … : … → cible ») et le minuteur de bloc en tête de ses étapes.

`pfStepQual` est scindée en `stepQualTxt` (texte seul, pour le SVG) et son habillage HTML. Enfin, `wrapText`
respecte l'espace insécable (sa normalisation `\s+` l'effaçait). Les durées (« 5 min ») et les noms entre
guillemets (`guil`) ne se coupent donc plus au milieu, dans le Schéma comme dans le texte.

Le registre de la Page (⚠ / △ et couleur du libellé) ne change pas. Le regroupement par seuil et le texte du
minuteur de bloc sont désormais deux fabriques partagées (`stepGroups`, `blkTimerTxt`). `momRuleHtml` et
`wtStaticHtml`, qui n'avaient plus d'appelant, sont purgés avec `.mo-rule` et `.wt-sv` (règle 14).

**Témoins.** La section `audit-doctrine` « Page · A391 entrées, retours, échelle, moments en mots » vérifie,
sur une fiche construite pour l'occasion :
- la sortie vers une branche de fourche finit SUR la barre, à moins de 1 px ;
- elle n'a ni seconde pointe ni marge de cible.

Sur l'ACR, elle vérifie :
- chaque retour de pilule part de son bas ;
- deux en-têtes « Si … : » sont présents, ainsi que les qualificatifs en mots, et plus aucune capitale ;
- le jalon se lit « Si … : ».

Deux mesures s'y ajoutent : le tronc rejoint le raccord de chaque pilule au pixel, et au moins 10 px de trait précèdent chaque pointe de retour. Le témoin a été vu ÉCHOUER sur la version commitée (8 rouges sur 8 ; jonctions −12 px, 3 px avant la pointe), puis passer. La section A344 (« aucun
segment ne pénètre une cellule, une boîte, un intitulé, une pilule ou un numéro ») reste verte.
