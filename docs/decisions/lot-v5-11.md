# Lot v5.11 — l'atelier d'import dit aussi **où** ça va

> Entrées NORMATIVES, comme les autres fichiers de `docs/decisions/` : elles portent les décisions
> et leurs raisons ; `AGENTS.md` garde les règles vivantes et renvoie ici. Origine du lot : une
> question de l'auteur à l'usage — « comment définir les catégories et bibliothèques de une ou
> multiples fiches à l'import ? Maintenant qu'on a depuis 5.0 une nouvelle modale d'import de
> fiches extrêmement bien faite ».

**A159. LE GRAIN DE LA DESTINATION EST L'ENTITÉ, COMME CELUI DE LA SÉLECTION.** A129 avait renversé
l'ordre de l'import — d'abord CE QUE l'on importe, ensuite OÙ — mais le « OÙ » était resté ce qu'il
était avant l'atelier : une question oui/non posée APRÈS lui, et seulement si une bibliothèque
partagée éditable se trouvait sélectionnée à l'accueil. Trois manques, tous constatés à l'usage :
on ne pouvait viser QUE la bibliothèque déjà sélectionnée (depuis l'accueil « Perso », la question
ne se posait même pas et tout y tombait) ; la CATÉGORIE n'était pas réglable du tout ; et le grain
était le FICHIER, alors que celui de l'atelier est l'ENTITÉ depuis A129 — un export de bibliothèque
entière ne pouvait pas se répartir entre deux rayons. Chaque rangée porte donc sa destination,
bibliothèque **et** catégorie, VUE avant que rien ne soit écrit.

**A160. LE BANDEAU N'EST PAS UN RÉGLAGE GLOBAL À CÔTÉ DES RANGÉES : C'EST LA MÊME COMMANDE.** Il
affiche la valeur COMMUNE des rangées cochées, « Plusieurs » quand elles divergent, et la pose sur
ces mêmes rangées quand on l'actionne — jamais sur les décochées. Deux composants séparés (un
réglage d'en-tête, un réglage de rangée) auraient donné deux affordances à apprendre pour un seul
choix, et fini par se répondre différemment sur la même question. Un seul point d'écriture
(`impPoseLib`/`impPoseCat`), un seul prédicat de valeur commune (`impCommun2`).

**A161. LE BANDEAU DIT LE CHOIX, LA RANGÉE DIT SON EFFET.** Sur la même valeur, ils ne portent pas
le même libellé, et c'est délibéré. Mesuré à la sonde : en comparant les ÉTIQUETTES RENDUES, le
bandeau annonçait « Plusieurs » à l'OUVERTURE de l'atelier, alors que rien n'avait encore été
décidé — les rangées portaient bien toutes le même choix (« garder celle du fichier »), mais chacune
garde une catégorie différente, donc affiche un texte différent. « Plusieurs » désignait la
conséquence, pas la commande, et se lisait comme un désordre. Le bandeau compare donc la VALEUR
(`IMP_KEEP` et « aucune » ont le même sens partout ; un ID n'a de sens que dans sa bibliothèque,
cf. v5.10.9 — il n'est « commun » que si la bibliothèque l'est aussi), tandis que la rangée NOMME
ce qu'elle garde (« Garder Réanimation »), pour que l'auteur n'ait pas à rouvrir le fichier.

**A162. LE DÉFAUT NE DÉCIDE RIEN À LA PLACE DE L'AUTEUR.** La catégorie d'une rangée vaut
`IMP_KEEP` — « garder celle du fichier » —, qui est exactement le comportement d'avant ce lot,
réconcilié par nom dans la destination (v5.10.9). L'atelier ne se met à ranger que si on le lui
demande. La sentinelle ne peut pas être un identifiant : les valeurs de menu transitent par un
attribut, donc par une chaîne, et `SAFE_ID` (`[A-Za-z0-9_-]`) ne produit jamais de « ~ » — sans
quoi une catégorie nommée de la bonne façon vaudrait « garder », en silence.

**A163. CHANGER DE BIBLIOTHÈQUE INVALIDE LA CATÉGORIE CHOISIE.** Un id de catégorie n'a de sens que
dans SA bibliothèque : le conserver pointerait sur rien, ou pire sur autre chose (le défaut fermé en
v5.10.9). On retombe alors sur `IMP_KEEP`, le seul choix toujours valable ; « sans catégorie » est
conservé, lui, puisqu'il ne désigne aucun id.

**A164. LA DESTINATION VOYAGE AVEC SON ENTITÉ, JAMAIS À CÔTÉ.** Les deux tableaux sont filtrés sur
la sélection et la destination de chaque rangée gardée est rangée DANS LE MÊME PASSAGE. Une
destination retrouvée après coup par l'index d'origine se serait désalignée au premier filtrage, et
le défaut aurait été d'écrire une fiche dans la bibliothèque de sa voisine : silencieux, et faux là
où ça compte. Corollaire : la table de résolution des catégories est indexée par **(bibliothèque, id
source)**, parce que deux rangées peuvent GARDER la même catégorie du fichier vers deux destinations
où elle ne porte pas le même identifiant — une table indexée par le seul id source aurait renvoyé la
première résolution à toutes les autres, c'est-à-dire l'id d'une catégorie d'une AUTRE bibliothèque.
La résolution est PARESSEUSE : une catégorie n'est créée que lorsqu'une entité la réclame vraiment,
dans la bibliothèque où elle la réclame — et A130 s'en trouve resserrée, une catégorie du fichier
n'entrant plus si toutes ses entités ont été rangées ailleurs à l'atelier.

**A165. « REMPLACER TOUT » N'EST PLUS PROPOSÉ QUAND L'IMPORT VISE PLUSIEURS BIBLIOTHÈQUES.** Une
suppression totale doit NOMMER ce qu'elle vide : « remplacer les bibliothèques choisies » viderait
deux bibliothèques entières sur une phrase au pluriel, dont l'une peut-être pour une seule fiche
qu'on y a glissée. Le geste reste possible — on importe vers une destination à la fois — mais il ne
se propose pas par inadvertance. La fusion, elle, n'a jamais eu besoin d'une destination unique.

**A166. LA PROMESSE « JAMAIS EN SILENCE » CHANGE DE PORTEUR, PAS DE FORCE.** La question oui/non
« Où importer ? » disparaît ; ce qui la remplace est plus, pas moins — un choix par rangée, vu avant
d'écrire. Mais la moitié de cette question qui AVERTISSAIT (« publier dans une bibliothèque partagée
= visible par toute l'équipe ») doit rester : elle est reprise par un bandeau de pied qui NOMME les
bibliothèques visées et COMPTE les éléments cochés, et qui se tait quand tout va au Perso. Registre
ATTENTION (`--verify`), jamais rouge : ce n'est pas un danger, c'est une portée.

**A167. UN MENU ANCRÉ DANS UNE RANGÉE DE FENÊTRE NE TOMBE PAS OÙ ON CROIT — ET LA GÉOMÉTRIE NE LE
DIT PAS.** Un menu `absolute` se pose par rapport au premier ancêtre POSITIONNÉ, et une rangée
d'atelier n'en a aucun : à 1194×834, ouvert sur la dernière rangée, il atterrissait à 494→834, soit
une centaine de pixels SOUS le bas de la liste (394), détaché de la pastille qui l'ouvre. Positionner
la rangée ne répare pas davantage (même géométrie mesurée) et exposerait au contraire le menu à
l'`overflow` du corps de fenêtre. Les menus de l'atelier sont donc des FEUILLES à toute largeur —
la forme que le téléphone recevait déjà —, et le palier 780 passe de la feuille de style au JS pour
que la règle n'ait qu'UNE écriture (`openPickMenu` pose `.sheet` si l'appelant l'exige ou sous
780 px). Ce que ça change, et c'est dit : le menu ne se reforme plus si l'on pivote l'appareil menu
ouvert. **⚠ ET LE COROLLAIRE DE MÉTHODE, REPAYÉ ICI** : `getBoundingClientRect` ignore l'écrêtage
d'un ancêtre — un témoin géométrique restait VERT sur le défaut réintroduit. Le seul témoin qui
discrimine est le test de TOUCHER (`elementFromPoint`), qui respecte écrêtage et superposition.
Leçon v4.31.1 : un contrôle aveugle au défaut qu'il prétend couvrir ne vaut rien, et on ne
l'apprend qu'en réintroduisant le défaut.

**A168. UN MENU ANCRÉ, TROIS USAGES : ON EXTRAIT, ON NE RECOPIE PAS.** `openCatMenu` portait sa
machinerie (voile, piège clavier, filtre, fermeture, retour de focus, `aria-expanded` sur les
déclencheurs) ; l'atelier en avait besoin pour la catégorie ET pour la bibliothèque d'une rangée.
Trois copies de trente lignes auraient divergé — leçon du serveur statique recopié dans onze harnais
(v4.45.0) et des listes tenues à la main (MUTE_SEL). `openPickMenu` est le corps EXACT de l'ancien,
extrait ; le DOM et les classes sont inchangés, seul le nom de l'attribut d'option a bougé
(`data-catopt` → `data-pickopt`, qu'aucun harnais ne citait — vérifié au grep avant de toucher).

**A169. LA BIBLIOTHÈQUE GÉRÉE PEUT ÊTRE IMPOSÉE PAR L'APPELANT.** `activeCatScope()` la DÉDUIT du
contexte, ce qui suffit partout sauf ici : l'atelier règle la destination d'une RANGÉE, qui peut
viser une autre bibliothèque que celle affichée à l'accueil. Sans surcharge, « ＋ Nouvelle
catégorie » aurait créé la catégorie dans la MAUVAISE bibliothèque, en silence — et elle n'aurait
pas paru dans le menu qui venait de l'ouvrir. La surcharge ne survit pas à la fermeture. Corollaire :
`closeCatMgr` ne re-rend PAS la vue de fond quand l'atelier est ouvert derrière lui — cela le
détruirait sous l'auteur ; il repeint l'atelier sur place.
