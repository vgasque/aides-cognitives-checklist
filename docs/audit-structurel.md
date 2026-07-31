# Second audit — structure, design, règles de base

> **Cadrage validé avec l'auteur.** Périmètre : **le produit entier**, et **les deux bouts de la
> courbe** — ce qui bloque un néophyte à J0 **et** ce qui ralentit quelqu'un qui connaît l'app à
> J30. Contraintes du premier audit **maintenues et non négociables** : *aucun tutoriel*, *aucune
> aide cognitive livrée en plus*. Ambition : **chantiers assumés, plusieurs versions** — on
> s'autorise à déplacer une vue, changer un palier, ajouter un champ modèle et **rouvrir une règle
> d'`AGENTS.md`**, mais jamais par effet de bord : chaque réouverture est nommée, argumentée et
> laissée à l'arbitrage de l'auteur.
>
> Ce document ne remplace pas [`audit-j0.md`](audit-j0.md) : celui-ci listait des **symptômes** et
> des correctifs bornés ; celui-là cherche les **causes** et propose des chantiers.
> Version auditée **v4.79.0**, Chromium et WebKit, base vierge, 320 / 390 / 780 / 1280 px, clair et
> sombre, 130 % via `applyZoom(130)`. Maquettes :
> **[`audit-structurel-maquettes.html`](audit-structurel-maquettes.html)**.
>
> **Mise à jour.** L'auteur a ensuite tranché que **v3 est abandonné** et demandé une structure
> reprise **à zéro**. La **[partie II](#partie-ii--table-rase--la-structure-que-je-propose)** y
> répond : modèle, surfaces, squelette de fenêtres, fonctions premières — et **remplace** les
> chantiers CH3 et CH3′ de la partie I. La partie I reste le **diagnostic mesuré** qui la motive.
>
> **Prototypes** : [`proto-r4.html`](proto-r4.html) (téléphone, interactif) et
> [`proto-large.html`](proto-large.html) (éditeurs, tablette, ordinateur).
>
> **Partie III** : R4 est **prototypé et fonctionnel** — [`proto-r4.html`](proto-r4.html) — et
> chaque décision de design y est remise en question, y compris ma propre proposition S7.
>
> **Aucune modification de code, aucun commit.**

---

## 1 · Verdict

L'application est **remarquablement bien tenue et structurellement mal ordonnée**. Sa géométrie ne
casse nulle part, sa doctrine est écrite, ses garde-fous sont exécutables — et pourtant, **au moment
précis où elle sert, elle montre autre chose que ce qu'il faut faire**.

Un seul chiffre porte tout le reste : **à 320 × 640, quand la session démarre, la première étape à
exécuter est à 847 px du haut — soit 207 px sous le pli, et zéro étape visible à l'écran.** À 130 %
de taille de texte sur un écran de 390, c'est 1 124 px et zéro étape. Le même chiffre vaut à la
**reprise** d'une session depuis l'accueil : on revient sur sa réanimation et l'on doit défiler
avant de pouvoir cocher.

Ce n'est pas un défaut de réglage, et c'est le résultat le plus important de cet audit : **j'ai
simulé la diète** (replier le chapeau à une ligne, retirer les titres de section) et elle **ne
suffit pas** dans deux configurations sur trois. Seul **le changement d'ordre** fonctionne. Le
problème n'est donc pas que l'orientation prend trop de place : c'est qu'elle **précède** l'action.

Cinq autres causes, toutes mesurées, expliquent le reste : la fiche existe en **sept
présentations** dont trois rendent les mêmes étapes ; la **chaîne d'étape porte quatre
préoccupations orthogonales** dans un seul `String` ; **la clé d'une coche est un index**, si bien
qu'un compte-rendu de soin archivé **nomme la mauvaise étape** dès que la fiche est éditée après
coup (prouvé, sur les deux gestes d'édition) ; la cascade CSS est **contournée 199 fois par un
`#id`** au lieu d'être ordonnée ; et la doctrine — 271 Ko, 2 989 lignes — est devenue si lourde
qu'**elle se trompe sur son propre code** (trois affirmations fausses relevées).

Une hypothèse a été instruite à la demande de l'auteur : **si la règle 12 pouvait être cassée**,
que ferait-on du format ? La réponse tient en sept champs, et chacun répare une prescription
d'ECAM ou de l'AC 120-71B que la chaîne rend aujourd'hui **inexprimable** — dont la confirmation
d'un item critique **par les deux** opérateurs (§5.2.2.5), qui est la seule capacité clinique que
ce document propose d'ajouter au produit. C'est le chantier **CH3′**, et c'est la seule décision
irréversible de tout l'audit.

Enfin, ce que le produit fait de mieux mérite d'être nommé pour être protégé : la carte
« SESSION EN COURS » de l'accueil, le dialogue « Créer », la porte « ＋ », l'écran invité et le
dialogue « Terminer la session ? » sont **exemplaires**, et plusieurs chantiers ci-dessous ne font
que généraliser ce qu'ils font déjà.

---

## 2 · Les six causes

### Cause I — L'orientation précède l'action, et la diète n'y peut rien

**Mesuré**, session démarrée, `scrollY = 0`, position de la **première étape cochable** et nombre
d'étapes entièrement visibles (le bloc en compte 5) :

| Régime | 320 × 640 | 390 × 844 | 390 @ 130 % |
|---|---|---|---|
| **Aujourd'hui** | **847 px — 0/5** | 698 px — 2/5 | **1 124 px — 0/5** |
| **Diète** — chapeau replié à une ligne + titres de section retirés | 661 px — 0/5 | 551 px — 3/5 | 882 px — 0/5 |
| **Ordre changé** — le bloc courant passe en tête | **418 px — 2/5** | **346 px — 5/5** | **601 px — 2/5** |
| *La diète fait-elle passer la 1ʳᵉ étape au-dessus du pli ?* | **NON** | oui | **NON** |

Décomposition de ce qui occupe les 847 px à 320 px : bandeau-titre **64**, chapeau « Ne pas
oublier » **172**, étape ① repliée **80**, carte minuteurs **90**, titres de section et en-tête de
bloc **~165**, plus le chrome collant (barre 65 + commandes 59 + quai 53 = **177 px permanents**,
soit **27,7 % de l'écran** à 320, **43,9 % à 130 %**).

**Pourquoi c'est la cause et non un symptôme.** Le rail ①②③ (v4.4.0) est une bonne idée de
**lecture** : il raconte le parcours de soin. Mais il a été posé **dans la colonne d'action**, en
amont d'elle, et il y reste une fois la session démarrée — c'est-à-dire au moment où l'on n'a plus
rien à s'orienter et tout à exécuter. L'ECAM fait l'inverse : l'E/WD porte **les actions restantes**
et le SD, l'orientation, sur une **autre surface**. La v4.59.0 a d'ailleurs eu l'intuition juste en
créant le cockpit à trois colonnes — mais **seulement au-dessus de 1 200 px**, c'est-à-dire jamais
sur l'appareil de terrain.

**À J0 comme à J30, le même défaut** : le néophyte ne comprend pas que la fiche sert à cocher
(il voit un document) ; l'expert défile deux fois par reprise de session.

---

### Cause II — Sept présentations de la même fiche, trois qui rendent les mêmes étapes

**Mesuré** — surfaces qui rendent tout ou partie d'une fiche : `navSection` (guidé), `overviewSection`
(journal), `svTableHtml` (statique), `ovPlanLadderHtml` (Se repérer), `railLadHtml` (rail),
`buildFlowSVG` (schéma), `readerRender` (lecteur), `renderRefSheet` (Consulter), `monPick`
(moniteur), `exportSessionReport` (compte-rendu). **Dix fonctions de rendu, sept surfaces
utilisateur.**

Duplication réelle, vérifiée en cherchant les mêmes phrases dans chaque surface d'une même fiche :

| Contenu | Rendu dans | Surfaces |
|---|---|---|
| une étape ordinaire | **3** | guidé · statique · lecteur |
| une étape ⚠ | **3** | guidé · statique · lecteur |
| « Ne pas oublier » | 2 | guidé · statique |
| « À vérifier » | 2 | guidé · statique |
| différentiels | 2 | Consulter · statique |

La v4.62.0 (I4) a unifié la **grammaire** — `applyCheck` est le point d'écriture unique,
`stepsListHtml` la structure unique. Le travail s'est arrêté au bon endroit mais à mi-chemin : les
**grammaires** ont fusionné, pas les **surfaces**. Le coût n'est plus la divergence (elle est
verrouillée), c'est **le choix** : à J0 il faut deviner laquelle des trois regarder, et à J30 il
faut se souvenir de laquelle on avait choisie.

Le mode **statique** est le cas limite : c'est la seule surface qui contient *tout* (mesuré : c'est
la seule où l'on retrouve les cinq témoins), donc la seule qu'on puisse lire d'un bout à l'autre —
et c'est celle que rien ne recommande.

---

### Cause III — Une chaîne d'étape porte quatre préoccupations orthogonales

`"⚠ Adrénaline IM, face antéro-latérale de cuisse :: dose du protocole local"` encode, dans un seul
`String` :

1. le **texte** clinique ;
2. le **registre** (`⚠` / `!` / `△`) — `STEP_CRIT_RX`, `STEP_VIG_RX` ;
3. la **réponse attendue** (`::`) — `stepCR` ;
4. et, depuis K10 (v4.69.0), le **raccourci de saisie** (`!` ou `?` en tête).

**Mesuré** : 9 fonctions et 2 expressions régulières vivent uniquement pour désencoder cette
chaîne — `stepText` **27 références**, `stepIsCrit` 22, `stepIsVigil` 21, `stepCR` 12.

Le choix est **historiquement juste** : la règle 12 interdit de casser l'export v3, et une chaîne
reste lisible par un client antérieur. Mais son coût est désormais visible et **documenté par
`AGENTS.md` lui-même** : le raccourci K10 a d'abord été inatteignable parce que `STEP_CRIT_RX`
reconnaissait déjà `!`, produisant « ⚠ ! Choc immédiat » à l'écran. C'est la signature d'un encodage
saturé : deux préoccupations se disputent le même caractère.

Conséquence côté utilisateur, et elle est directe : **un auteur ne peut pas écrire une étape dont le
texte commence par un point d'exclamation, ni contenant `::` ailleurs qu'en séparateur**, et rien ne
le lui dit.

---

### Cause III bis — La clé d'une coche est un **index** : un compte-rendu archivé se décale

**Mesuré**, preuve pure via le hook `?__actest` (déterministe, sans rendu). Une coche est enregistrée
sous la clé `visite:bloc:INDEX` ; le compte-rendu résout ensuite cette clé avec `stepTextFromKey`
**contre la fiche ACTUELLE** (`index.html:7060` pour les étapes réalisées, `:7072` pour les écarts
do-verify) — car `snapshotSession` archive `ficheId` et `ficheTitle`, **jamais le texte des étapes**.

| | Ce que la clé `1:b1:2` désigne |
|---|---|
| au moment du soin | `⚠ Adrénaline IM, cuisse :: 0,5 mg` |
| après **insertion** d'une étape en tête du bloc | `Appeler à l'aide` |
| après **déplacement** de l'étape d'un rang (poignée ⠿) | `Appeler à l'aide` |

**Un compte-rendu de soin archivé nomme donc la mauvaise étape dès que la fiche est éditée après
coup — silencieusement.** Le défaut est ancien, mais il est devenu **beaucoup plus atteignable**
depuis MK5-b (v4.64.0) : réordonner une étape coûte désormais deux taps, et rien n'avertit que le
geste réécrit l'interprétation des sessions passées.

C'est la même cause que la III — l'étape n'a pas d'identité, seulement une position — et c'est
l'argument le plus fort du chantier CH3′.

---

### Cause IV — La cascade n'est pas ordonnée, elle est contournée

**Mesuré** dans les 4 256 lignes de CSS : **2 113 blocs de règles**, **199 sélecteurs portant un
`#id`**, 85 sélecteurs à quatre classes ou plus, 37 sélecteurs à `:not()` (dont chaque argument
compte dans la spécificité). `!important` n'est utilisé que **15 fois** — la discipline est réelle.

`AGENTS.md` recense **dix « pièges de cascade »** vécus, tous de la même forme : deux règles de
spécificité égale, l'ordre de déclaration tranche, et le correctif est *« passer par un `#id`, qui
l'emporte quel que soit l'ordre »*. **Le contournement est devenu la convention.** Ce n'est pas une
faute de goût : c'est une dette qui se paie à chaque ajout, parce qu'un `#id` est une exception qui
ne se compose pas — le onzième piège viendra d'un `#id` contre un autre `#id`.

Corollaire mesuré, sur les **paliers de largeur** : `AGENTS.md` déclare une échelle **fermée** de
neuf valeurs (360/400/430/560/640/780/900/1000/1200). Les media queries en contiennent **douze
distinctes**, dont **479,98 px** (`.tg-row`) et **924 px** (`.rs-bar`) qui ne figurent dans aucune
liste — et **900 px, qui est déclaré mais n'existe pas**. Une échelle fermée qui a fui est une
échelle ouverte qu'on croit fermée.

---

### Cause V — La doctrine est porteuse, et elle se trompe sur son propre code

**Mesuré** : `AGENTS.md` fait **271 Ko et 2 989 lignes**. Il contient 61 occurrences de « mesuré »,
32 « décision utilisateur », 30 « signalé à l'usage », 10 « piège de cascade ». Le `CHANGELOG`
courant, ramené à 20 versions, pèse encore **89 Ko**. Le CSS est commenté à **50 %**, le JS à
**45 %**.

C'est un actif rare : presque chaque règle porte l'incident qui l'a produite, et cet audit n'aurait
pas été possible sans lui. Mais il a franchi le seuil où **plus personne ne peut le tenir à jour
intégralement**, et cela se mesure — trois affirmations fausses trouvées **sans les chercher** :

| Affirmation d'`AGENTS.md` | Mesure |
|---|---|
| « ~14 400 lignes » | **18 541** |
| « **57** bannières `/* ===== … ===== */` » | **61** |
| « Breakpoints : 360 / 400 / 430 / 560 / 640 / 780 / **900** / 1000 / 1200 — pas de nouveau palier sans décision explicite » | **12 paliers réels**, dont 479,98 et 924 non déclarés ; **900 déclaré mais absent** |

Le fichier mélange deux natures qui n'ont pas la même durée de vie : la **doctrine** (stable,
courte, opposable) et le **journal des incidents** (croissant, daté, narratif). Tant qu'ils sont
confondus, la doctrine est illisible et le journal est faux.

---

## 3 · Chantiers

Chacun : ce qu'il change · pourquoi · **coût** · **risque** · **règle rouverte** · **versions**.
Ordonnés par gain/coût. **CH1 et CH2 sont les seuls qui changent vraiment le produit** ; les autres
sont de l'hygiène de fond.

---

### CH1 — L'action passe devant l'orientation, en session seulement · **le chantier principal**

**Ce qui change — l'ORDRE DU FLUX, et rien d'autre.** Aucun élément n'est supprimé, aucun n'est
déplacé dans une autre vue : c'est la **suite verticale** de la colonne centrale qui est réécrite, et
**seulement une fois la session démarrée**.

| Rang | Aujourd'hui (en session) | Proposé (en session) |
|---|---|---|
| 1 | bandeau-titre de la fiche | **bloc courant — les étapes cochables** |
| 2 | chapeau « Ne pas oublier » (entier, 172 px) | ⋮ |
| 3 | rail ① « Diagnostic confirmé » (replié, 80 px) | chapeau « Ne pas oublier » *(replié en 1 ligne — CH1a)* |
| 4 | titre de section « Prise en charge » | rail ①②③ |
| 5 | carte minuteurs & compteurs | carte minuteurs & compteurs |
| 6 | titre de section « Parcours » | bandeau-titre de la fiche |
| 7 | **bloc courant — les étapes cochables** | reste du journal, annexes |
| 8 | reste du journal, annexes | ⋮ |

Autrement dit : **ce qui sert à agir monte en tête, ce qui sert à s'orienter descend d'un cran** — et
reste à un geste de défilement, entier, au même endroit relatif les uns par rapport aux autres.

**Hors session, rien ne bouge du tout** : la fiche s'ouvre exactement comme aujourd'hui, parce
qu'avant d'agir on s'oriente — le chapeau entier, le rail ①②③ et les critères diagnostiques restent
en tête. La bascule se fait au moment précis où l'on presse « Confirmé — démarrer la session », et
elle se défait à la fin de la session.

**Pourquoi.** Mesuré : c'est la **seule** transformation qui fasse passer la première étape au-dessus
du pli dans les trois configurations (418 / 346 / 601 px contre 847 / 698 / 1 124), là où la diète
échoue deux fois sur trois. C'est aussi l'application au téléphone de ce que la v4.59.0 a déjà admis
au-dessus de 1 200 px avec le cockpit — **la structure était juste, son seuil était faux**.

**Ce que le chapeau devient**, et c'est la partie délicate : « Ne pas oublier » porte les *memory
items*, et la doctrine QRH veut qu'ils soient vus **avant** d'agir. Ils le sont : à l'ouverture de
la fiche, hors session, en tête et entiers. Une fois la session lancée, ils se replient en **une
ligne rouge permanente et dépliable** — le registre et le mot restent, la surface part. C'est
exactement ce que la v4.16.0 a fait au journal (une carte complète devient une ligne d'état
relisible), appliqué au chapeau.

- **Coût** — moyen. Réordonnancement dans `renderRead`, un état de repli du chapeau, et
  `renderKeepAnchor` à honorer sur la transition. ~120 lignes.
- **Risque** — **élevé et à traiter frontalement.** C'est la vue la plus mesurée du dépôt : cinq
  harnais ancrent sur `.ov-block.cur`, `stickBase()` et `--stick-top` calculent des positions,
  `ovAdvanceRender` compense au pixel. À livrer avec ses propres témoins avant tout.
- **Règles rouvertes** — **« Parcours de soin » (v4.4.0)** : le rail cesse d'être l'ossature de la
  vue en session. **« Le chapeau reste le CHAPEAU, jamais replié »** : il se replie, en session
  seulement. **Le palier du cockpit (v4.59.0, 1 200 px)** : sa doctrine descend au téléphone sous
  une autre forme.
- **Versions** — 2 à 3 : (a) le chapeau repliable en session, mesurable seul ; (b) le
  réordonnancement ; (c) l'ajustement des ancrages.

---

### CH2 — Trois surfaces, pas sept : *agir · se repérer · consulter*

> **⚠ SUPERSÉDÉ — lire d'abord la partie III.** Cette proposition gardait un sélecteur
> « Agir / Se repérer », donc encore un **choix de présentation** sous stress. Elle est **abandonnée**
> au profit de l'**axe de densité à trois crans** (§ III.2). Le texte est conservé parce qu'il porte
> le raisonnement sur les surfaces, qui reste valable ; c'est son **contrôle** qui a changé.


**Ce qui change.** Le mode **statique** cesse d'être un troisième mode de lecture pour devenir la
**vue « se repérer »** — c'est déjà la seule surface qui contient tout (mesuré). « Se repérer »
(l'Échelle) et « Schéma » deviennent deux **affichages** de cette même surface, comme ils l'étaient
avant la v4.25.0. Le **mode lecteur** cesse d'être une surface : il devient une **densité** de la
colonne d'action — ce que la v4.62.0 avait déjà écrit sans aller au bout (« le lecteur en est la
densité `.rm-steps` »). Le **mode moniteur** reste à part : il n'est pas une vue de la fiche, c'est
un afficheur d'état, et il est déjà juste.

**Pourquoi.** Le bouton « Guidé / Statique » demande aujourd'hui à l'utilisateur d'arbitrer entre
deux **présentations** — un choix que ni un néophyte ni un expert sous stress ne devrait avoir à
faire. Après CH2, la bascule ne demande plus « comment veux-tu lire ? » mais **« veux-tu agir ou te
repérer ? »**, qui est une question à laquelle on sait répondre en réanimation.

- **Coût** — élevé. C'est une refonte de la navigation de la vue lecture.
- **Risque** — moyen : les rendus existent tous et sont déjà unifiés par `stepsListHtml` et
  `applyCheck`. On déplace des surfaces, on n'écrit pas de moteur.
- **Règles rouvertes** — **« Trois affichages du Plan » (v4.18.0)** et **« Plan = une seule vue »
  (v4.25.0)**, qui s'annulent déjà partiellement l'une l'autre ; **la bascule Dynamique ↔ Statique
  (v4.16.0)**.
- **Versions** — 3 à 4, et **à ne pas commencer avant CH1** : réordonner d'abord la vue qui reste.

---

### CH3 — L'étape devient une structure, sans casser l'export v3

> **⚠ CADUC — l'auteur a décidé que v3 est abandonné (décision A1).** Ce chantier cherchait le
> compromis compatible ; il est **entièrement contenu** dans le format v4 (CH3′ puis partie II,
> lot **T6**). Conservé pour son raisonnement sur l'encodage saturé, qui reste la cause.


**Ce qui change.** Le modèle stocke, en plus de la chaîne, les champs facultatifs de l'étape :
`{ t, reg, r }` (texte, registre, réponse). **La chaîne reste écrite** — c'est elle qui voyage dans
l'export, dans le partage et vers les clients antérieurs (règle 12 tenue à la lettre) ; les champs
sont **dérivés au `migrate()`** et redeviennent la source d'affichage.

**Pourquoi.** Cela supprime la classe entière de défauts dont K10 est l'exemple : un `!` de texte
cesse d'être un marqueur, un `::` de texte cesse d'être un séparateur, et l'auteur récupère son
clavier. Cela permet aussi ce que l'éditeur ne peut pas faire aujourd'hui : **valider** un registre
sans réécrire la chaîne, et **compter** les étapes signalées sans expression régulière.

- **Coût** — moyen. `migrate()`, l'éditeur, et un aller-retour chaîne ⇄ structure testé dans les
  deux sens.
- **Risque** — **le plus élevé du lot**, parce qu'il touche le point d'entrée de toute donnée
  (règle 5) et le format d'export (règle 12). À n'engager qu'avec des tests d'aller-retour
  exhaustifs, sur des chaînes pathologiques (`!`, `::` multiples, `⚠ △` combinés).
- **Règles rouvertes** — aucune. Les règles 5 et 12 sont **respectées** ; c'est leur interprétation
  « donc tout doit rester une chaîne » qui est rouverte.
- **Versions** — 2, sans effet visible à la première.

---

### CH3′ — **Si l'on pouvait casser l'export v3 : le format v4** · *hypothèse instruite à la demande*

> **Cadre.** La règle 12 (« ne jamais supprimer un champ du modèle ; un export v3 doit rester
> lisible par un client antérieur ») est **suspendue le temps de ce chantier seulement**. Tout ce
> qui suit est un scénario ; rien n'est recommandé sans l'arbitrage explicite de l'auteur, parce
> qu'une rupture de format est la seule décision de ce document qu'on ne peut pas défaire.
>
> **Boussole retenue** : ce que le format doit permettre, c'est **ce qu'ECAM et l'AC 120-71B
> prescrivent et que la chaîne interdit aujourd'hui**. Ce n'est pas un exercice d'élégance : chacun
> des sept points ci-dessous répare une prescription documentée que le modèle actuel rend
> inexprimable, ou un défaut mesuré.

#### Les sept changements, et la prescription qui les motive

**1 · Chaque étape porte une IDENTITÉ, pas une position.**
`{ id: "s7", … }`, et les clés de session deviennent `visite:itemId`.
*Motif* — la **Cause III bis, mesurée** : aujourd'hui la même clé désigne une autre étape après une
simple insertion, et un compte-rendu archivé nomme le mauvais geste. Un enregistrement de soin dont
le sens dépend d'une édition ultérieure n'est pas un enregistrement. C'est le point qui, à lui seul,
justifierait la rupture.

**2 · Le challenge et la réponse sont une PAIRE, pas une chaîne à séparateur.**
`{ do: "Adrénaline IM, cuisse", expect: "0,5 mg" }`.
*Motif* — **AC 120-71B §5.2.2.1** : « one crewmember reading the checklist and the second
crewmember confirming and responding ». Ce sont deux énoncés tenus par deux personnes ; les coller
dans un `String` avec `::` est un encodage, pas un modèle. Et **Degani & Wiener (1993)** : `expect`
porte l'état **constaté**, jamais un simple « fait » — ce que le dépôt a déjà admis en séparant
`verified` de `checked` (v4.23.0), sans pouvoir l'écrire dans la fiche.

**3 · Le registre devient un NIVEAU ordonné.**
`level: 3 | 2 | 1` — 3 = warning (rouge, action immédiate), 2 = caution (ambre, vigilance),
1 = advisory / normal.
*Motif* — c'est **littéralement la hiérarchie d'alerte ECAM**, que le produit applique déjà par ses
couleurs. Un nombre ordonné remplace deux expressions régulières et rend la règle « les deux →
rouge » triviale (`max`). Bénéfice second : le **plafond de deux étapes colorées par bloc**
qu'`AI_PROMPT` impose déjà à une IA devient **calculable**, donc signalable par l'éditeur comme les
autres garde-fous.

**4 · `dual: true` — l'item critique est confirmé par LES DEUX.**
*Motif* — **AC 120-71B §5.2.2.5**, qui l'exige explicitement pour les items critiques. C'est
**aujourd'hui inexprimable**, et c'est la fonctionnalité la plus directement débloquée par la
rupture : le partage de session existe déjà, les rôles existent déjà, `applyCheck` est un point
d'écriture unique — il ne manque que le champ pour qu'une étape ne se coche qu'après confirmation de
l'hôte **et** du second. C'est, de tout ce document, le seul endroit où le produit gagnerait une
capacité clinique qu'il n'a pas.

**5 · Les memory items redeviennent des ÉTAPES, et le chapeau devient une VUE.**
`memory: true` sur l'étape ; `notForget` disparaît en tant que champ.
*Motif* — en QRH, un memory item **est** un item de checklist : exécuté de mémoire, **puis vérifié
sur la liste**. Le séparer en liste parallèle produit exactement ce qu'on mesure dans la fiche
d'exemple livrée : « Adrénaline IM = 1ʳᵉ intention, ne pas retarder » (notForget) et « ⚠ Adrénaline
IM, face antéro-latérale de cuisse » (étape b1) sont **la même instruction, écrite deux fois, dans
deux formulations** — donc deux textes à tenir accordés, dont un seul est cochable et traçable. Le
chapeau reste **affiché à l'identique**, mais comme filtre (`memory:true`), pas comme second texte.

**6 · Le bloc porte sa PHASE.**
`phase: "immediate" | "secondary" | "surveillance"`.
*Motif* — l'ECAM **inhibe** l'affichage selon la phase de vol, c'est le cœur de son
« decluttering » ; `AI_PROMPT` demande d'ailleurs déjà à l'auteur de « scinder en PHASES cliniques —
mesures immédiates / 2ᵉ intention / surveillance », mais seulement dans le **titre**, donc
inexploitable. En champ, la phase permet de replier ce qui n'est pas la phase courante — c'est-à-dire
**CH1 par une seconde voie, structurelle celle-là**.

**7 · Une option de décision porte sa CONCLUSION.**
`{ label: "Non", concl: "Réfractaire", target: "b3" }`.
*Motif* — `AI_PROMPT` réclame déjà des « libellés-conclusions » parce que les vues abrégées
n'affichent que **titre + réponse**, et qu'un « Oui » relu seul peut signifier l'inverse du sens
réel. Le prompt demande à l'IA de contourner une limite du format ; le champ la supprime.

#### Ce qu'on ne fait **pas**, même la règle 12 suspendue

- **Aucun champ calculé** — pas de dose, pas de score, pas de seuil déduit. C'est le **périmètre
  réglementaire** (`docs/deploiement-et-conformite.md` § 2) : le jour où l'application *déduit*
  quelque chose du contenu clinique, sa qualification de non-dispositif-médical est à rouvrir. Le
  format v4 décrit **mieux** ce que l'auteur a écrit ; il n'en tire jamais rien.
- **Aucun texte libre supplémentaire sur le réseau de partage** — la règle 15 n'est pas suspendue :
  `do`, `expect` et `concl` sont des champs de **fiche**, qui voyagent déjà comme le titre et le
  discriminant ; le journal continue de ne transporter que des **références**.
- **On ne convertit pas les sessions déjà archivées.** Réécrire un enregistrement de soin passé
  serait pire que le défaut qu'on corrige.

#### Migration — la rupture se fait dans un seul sens

| | |
|---|---|
| **Lecture** | `migrate()` lit **v3 et v4**. v3 → v4 est **sans perte** (v3 est strictement plus pauvre) ; les `id` d'étape sont mintés **une fois**, à la première ouverture, puis persistés. |
| **Écriture** | Export **v4 par défaut**, plus une sortie **« .json v3 — compatible clients antérieurs »** avec sa **perte annoncée** (`dual`, `phase`, `memory`, les `id`). C'est la règle 12 rendue *optionnelle et explicite* au lieu d'être *implicite et permanente*. |
| **Partage** | `SHARE_KEEP` et la **liste blanche SQL** à rejouer — le serveur est l'autorité (même geste que pour `discriminant` en v4.70.0, et il avait été oublié). |
| **Sessions passées** | Conservées telles quelles, marquées `keyFormat:'idx'`. |

#### Le correctif **immédiat** que ce chantier révèle, et qui ne demande aucune rupture

La Cause III bis se répare **aujourd'hui**, sans toucher au format : que `snapshotSession` archive le
**texte des étapes cochées** en même temps que leurs clés. Une session devient alors autonome, et le
compte-rendu cesse de dépendre de l'état actuel de la fiche.

- **Coût** — faible. **Risque** — faible. **Bénéfice** — l'intégrité de l'enregistrement de soin.
- **Décision à trancher** : les sessions peuvent être **synchronisées** depuis la v4.54.0. Y archiver
  le texte des étapes fait monter du **texte clinique** vers le serveur. La règle 15 vise le
  **partage**, pas l'historique — mais l'esprit mérite l'arbitrage de l'auteur, et le champ `data`
  accepte déjà `{v:2, enc:<blob>}` (chiffré), ce qui est exactement la porte prévue pour ce cas.

- **Coût de CH3′** — élevé. **Risque** — le plus élevé du document ; c'est la seule décision
  irréversible. **Règle rouverte** — **la 12**, frontalement.
- **Versions** — 4 à 6, et **jamais avant CH1, CH5 et le correctif `snapshotSession` ci-dessus**.

---

### CH4 — Ordonner la cascade au lieu de la contourner

**Ce qui change.** Le CSS est découpé en couches déclarées (`@layer socle, composants, vues,
paliers, etats`) et les 199 `#id` de contournement redeviennent des classes. L'ordre cesse d'être un
accident et devient une déclaration.

**Pourquoi.** Dix pièges vécus, tous de la même forme, tous « corrigés » par un `#id`. Une couche
supprime la cause : à l'intérieur d'une couche l'ordre reste local, entre couches il est garanti.
Bénéfice mesurable : le nombre de sélecteurs à `#id` doit tomber, et `check-colors`/`check-type`
peuvent recevoir un contrôle de plus — *aucun `#id` dans une règle de géométrie*.

- **Coût** — élevé en volume, faible en risque unitaire. Mécanique, vérifiable règle à règle.
- **Risque** — moyen, et **entièrement mesurable** : la page rendue doit être identique au pixel
  avant/après, ce que les seize harnais savent déjà vérifier.
- **Règle rouverte** — **« pour une géométrie, ne jamais dépendre de l'ordre de déclaration —
  passer par un `#id` »**. La règle reste vraie ; c'est son **remède** qui change.
- **Versions** — 3 à 5, une couche à la fois, sans jamais mélanger avec un changement visuel.

---

### CH5 — Scinder `AGENTS.md` : la doctrine d'un côté, le journal de l'autre

**Ce qui change.** `AGENTS.md` ne garde que ce qui **contraint** : les quinze règles, les
invariants, les périmètres, les tokens, les paliers — court, opposable, vérifiable. Tout le récit
(« signalé à l'usage », les diagnostics, les décisions datées) part dans un
`docs/journal-de-doctrine.md`, et chaque règle y renvoie.

**Pourquoi.** 271 Ko et 2 989 lignes, trois affirmations fausses trouvées sans les chercher. Un
document opposable qui se trompe sur le nombre de lignes de son propre fichier ne peut pas être la
référence d'un chantier structurel. **Et ce chantier est un préalable** : CH1 à CH4 rouvrent tous
une règle — il faut savoir avec certitude ce qu'elle dit.

**À faire en même temps, parce que ça coûte trois lignes** : rendre les trois chiffres
auto-vérifiables (un contrôle dans `npm run check` qui compare la liste des paliers déclarés aux
paliers réellement présents dans les media queries). La leçon du dépôt s'applique à sa propre
documentation : *une règle qui ne peut pas échouer ne prouve rien.*

- **Coût** — faible en risque, réel en temps de rédaction.
- **Risque** — nul pour le produit.
- **Règle rouverte** — aucune ; c'est la forme du document qui change, pas son contenu.
- **Versions** — 1.

---

### CH6 — Le journal des actions remonte à portée de pouce

**Ce qui change.** « Noter l'heure » cesse de vivre en **fin** de colonne.

**Mesuré** : à 390 px, en session, le bouton `.tk-add` est à **y = 1 588 px** sur un écran de 844 —
soit **744 px sous le pli**. C'est le geste de traçabilité le plus fréquent d'une réanimation, et il
est le plus loin. Au-dessus de 780 px il vit dans le rail, donc visible : **le trou est de nouveau
sur le téléphone**.

**Proposition** : l'horodatage rejoint la carte du bloc courant, à côté de « Continuer » — c'est là
que le geste se produit. Alternative moins chère : il rejoint le panneau du quai, déjà à un tap.

- **Coût** — faible. **Risque** — faible.
- **Règle rouverte** — aucune ; l'ordre du rail (« ce qui est de longueur illimitée en dernier »,
  v4.23.0) est **conservé** puisqu'on ne touche pas au rail.
- **Versions** — 1.

---

### CH7 — Un budget d'écran, mesuré à chaque commit

**Ce qui change.** Un dix-septième harnais mesure, en session, sur les configurations contraintes :
la **part de l'écran occupée par le chrome** et le **nombre d'étapes entièrement visibles**. Il
échoue si le chrome dépasse un seuil décidé (par exemple 30 % à 320 px) ou si aucune étape n'est
visible.

**Pourquoi.** Le dépôt sait déjà mesurer ce qui **déborde** ; il ne mesure pas ce qui **recule**. Les
177 px de chrome permanent et les 847 px avant la première étape ne sont l'échec d'aucun contrôle
existant — ils se sont accumulés version après version, chacune justifiée. C'est le seul chantier
qui **empêche la cause I de revenir**.

- **Coût** — faible (le harnais est écrit à 80 % dans les sondes de cet audit).
- **Risque** — nul. **Versions** — 1, mais **à livrer avec CH1**, pas avant : il échouerait
  aujourd'hui.

---

## 4 · Règles de base proposées à la réouverture

Une par ligne. **Rien ici n'est décidé** ; chacune est l'arbitrage de l'auteur.

| Règle | Ce qu'elle dit | Pourquoi la rouvrir | Recommandation |
|---|---|---|---|
| **Parcours de soin ①②③** (v4.4.0) | Le rail structure la vue lecture | Il structure aussi la vue **d'action**, où il coûte 847 px avant la 1ʳᵉ étape | **Le garder hors session, le faire descendre en session** (CH1) |
| **Le chapeau ne se replie jamais** | Memory items toujours entiers, en tête | Ils sont vus à l'ouverture ; en session ils repoussent l'action de 172 px à 320 px | **Une ligne rouge dépliable en session** (CH1) |
| **Cockpit à 1 200 px** (v4.59.0) | Trois colonnes au-dessus de 1 200 | La doctrine (action et orientation de front) est juste ; le seuil la réserve aux écrans qui n'en ont pas besoin | **Descendre l'idée au téléphone par l'ordre**, pas par les colonnes |
| **Bascule Guidé ↔ Statique** (v4.16.0) | Deux présentations, choix de l'utilisateur | Demande un arbitrage de présentation sous stress | **Devenir « agir / se repérer »** (CH2) |
| **Pour la géométrie, passer par un `#id`** | Remède aux pièges de cascade | 199 occurrences ; le remède ne se compose pas | **Remplacer par `@layer`** (CH4) |
| **Échelle de paliers fermée** | 9 valeurs, pas de nouveau palier sans décision | **12 paliers réels**, 2 non déclarés, 1 déclaré-absent | **Rendre la fermeture auto-exécutoire** (CH5) |
| **Tout reste une chaîne** (lecture de la règle 12) | L'étape est un `String` | Encodage saturé : 4 préoccupations, 1 champ, un bug déjà payé | ~~Structure interne, chaîne conservée (CH3)~~ → **TRANCHÉ : format v4, v3 en import seulement** (A1, lot T6) |
| **Séparation ECP / ECAM** (v4.25.0) — commandes au-dessus, état au-dessous | Deux bandes collantes distinctes | 177 px permanents, **27,7 % de l'écran à 320 px**, 43,9 % à 130 %. La séparation Airbus est **matérielle** ; un téléphone n'a qu'une surface | **TRANCHÉ : on fusionne** (décision D1, lot T5b) — ce que les § II.2 et II.6 affirmaient encore comme intangible |
| **Règle 12 elle-même** — « un export v3 doit rester lisible par un client antérieur » | Le format ne rompt jamais | Mesuré : la clé d'une coche est un **index**, un compte-rendu archivé nomme la mauvaise étape après édition ; et **AC 120-71B §5.2.2.5** (confirmation par les deux) est **inexprimable** | **Rendre la compatibilité v3 optionnelle et explicite** (export « .json v3 » à perte annoncée) plutôt qu'implicite et permanente — **CH3′, décision irréversible, à trancher seule** |
| **Jeu de jetons du quai fermé** | Aucun segment ajouté | Question ouverte au 1ᵉʳ audit (nommer les minuteurs cachés) | À trancher avec D3 de l'audit 1 |

---

## 5 · Ce qui ne doit surtout pas bouger

Mesuré, vérifié, et cité ici pour être **protégé** d'un chantier voisin :

- **`migrate`, `applyCheck`, `persistLive`, `edCommit`, `_putSessionSafe`** — les **cinq** points
  d'écriture uniques. Toute la robustesse du produit tient à ces goulots ; aucun chantier ne doit en
  créer un sixième. *(Cette liste en comptait quatre : `migrate` y manquait, alors que le § II.6 du
  même document en annonçait cinq — corrigé.)*
- **La carte « SESSION EN COURS » de l'accueil** — reprise en **1 geste**, coches conservées
  (mesuré : 2/2 après aller-retour). C'est le meilleur objet de l'application.
- **La géométrie sous contrainte** — 0 px de débordement de 320 à 1 280 px, à quatre tailles de
  texte, sur deux moteurs. Chaque chantier doit rendre cette propriété intacte.
- **Le dialogue « Terminer la session ? »**, **la porte « ＋ »**, **le dialogue « Créer »**,
  **l'écran invité** — les quatre surfaces qui enseignent déjà sans tutoriel.
- **Les registres et leur doctrine** (⚠ tue / △ trompe, la couleur jamais seule, le rouge rare) —
  cet audit propose de les **montrer** mieux, jamais de les changer.

---

## 6 · Ordre de livraison proposé

> **⚠ SUPERSÉDÉ par [`transition-v4.md`](transition-v4.md) § 6**, qui porte les **treize lots**
> T0–T12 et intègre les décisions D1–D8. En particulier : **CH3 est caduc** (A1) et **CH3′ n'est plus
> conditionnel** — la rupture de format est décidée. L'ordre ci-dessous est conservé comme trace du
> raisonnement.


1. **CH5** — scinder la doctrine et rendre les paliers auto-vérifiables. *Préalable* : les autres
   chantiers rouvrent des règles, il faut savoir ce qu'elles disent.
2. **Le correctif d'intégrité** — `snapshotSession` archive le texte des étapes cochées. Petit,
   sans rupture de format, et il répare **aujourd'hui** la Cause III bis (un compte-rendu de soin
   qui nomme la mauvaise étape). À faire avant tout le reste s'il ne devait y en avoir qu'un.
3. **CH6** — le journal des actions remonte. Petit, isolé, gain immédiat à J30.
4. **CH1 (a)** — le chapeau repliable en session. Mesurable seul, réversible seul.
5. **CH7** — le harnais de budget d'écran, calibré sur le résultat de CH1 (a).
6. **CH1 (b, c)** — le réordonnancement et ses ancrages. *Le cœur.*
7. **CH4** — les couches CSS, en parallèle, sans jamais mélanger avec un changement visuel.
8. **CH3** — la structure d'étape, quand le reste est stable.
9. **CH2** — la refonte des surfaces : elle suppose que la vue qui reste soit déjà juste.
10. **CH3′** — la rupture de format, **en dernier et seulement si elle est décidée pour elle-même**.
    Elle rend CH3 caduc (elle le contient), et elle est la seule étape non réversible du document.

---

## 7 · Écarté par contrainte

Les contraintes ayant été maintenues, quatre pistes structurelles ont été formées puis abandonnées :

- **Une surface « Découvrir » permanente** dans la tab bar, à côté d'Aides et Protocoles — c'est un
  tutoriel avec un autre nom.
- **Une fiche « bac à sable »** générée à la volée pour montrer tous les mécanismes sans polluer la
  bibliothèque — c'est une troisième fiche livrée, même si elle est éphémère.
- **Un mode « première session accompagnée »** qui annoterait la vue au premier démarrage — coach
  marks.
- **Un protocole d'exemple** pour donner un matériel à la moitié « Protocoles » du produit, qui n'en
  a aujourd'hui aucun. C'est la contrainte 2 ; elle est respectée, mais **c'est le seul endroit où
  je la trouve coûteuse** — la moitié du produit n'a aucun exemplaire. Le constat 1 de l'audit 1
  (l'état vide qui dit la différence) reste le meilleur substitut disponible.

---

## 8 · Ce que je n'ai pas pu mesurer

- **Le partage en fonctionnement** (pas de Supabase joignable) : les causes I et II sont mesurées
  côté hôte seul. La vue de l'invité, qui hérite de la même structure, est donc **présumée** touchée
  par CH1 — non vérifié.
- **La visionneuse PDF, le QR, la synchronisation, les bibliothèques partagées, l'import/export ZIP,
  les versions** — hors de portée sans compte, sans serveur et sans documents.
- **Le coût réel de CH4** : je n'ai pas rejoué la feuille en `@layer` pour vérifier l'identité au
  pixel. La faisabilité est solide, l'estimation de volume ne l'est pas.
- **Un vrai appareil iOS en PWA installée**, un vrai lecteur d'écran, `forced-colors`.
- **Le comportement sous stress réel.** Tout ce document mesure des pixels et des gestes. Que
  l'ordre proposé par CH1 soit *effectivement* plus sûr en réanimation ne peut se savoir qu'en
  simulation — et c'est précisément ce que le **mode exercice** de la v4.27.0 permettrait de tester,
  ce qui en fait le meilleur outil d'évaluation de ces chantiers.
- **CH3′ n'a été ni prototypé ni chiffré.** L'aller-retour v3 ⇄ v4 est raisonné, pas exécuté ; le
  volume de code touché (partage, SQL, éditeur, compte-rendu, migration) est une estimation. La
  seule partie **mesurée** du chantier est ce qui le motive : la dérive des clés d'index.
- **Le nombre 30 % du budget d'écran de CH7** est une proposition, pas une mesure : il est calé sur
  les 27,7 % actuels à 320 px, il devra être décidé.

---

## 9 · Maquettes

**[`audit-structurel-maquettes.html`](audit-structurel-maquettes.html)** — quatre maquettes, état
mesuré à gauche, proposition à droite, tokens repris d'`index.html`, thèmes clair et sombre :

| | Maquette | Chantier |
|---|---|---|
| S1 | L'écran au démarrage d'une session, à 320 × 640 : aujourd'hui / diète / ordre changé | CH1 |
| S2 | Le chapeau « Ne pas oublier » replié en une ligne rouge | CH1 (a) |
| S3 | « Agir / Se repérer » remplace « Guidé / Statique » | CH2 |
| S4 | L'étape, de la chaîne à la structure — et ce que l'auteur récupère | CH3 |
| S5 | **Le format v4** — les sept champs, la prescription qui motive chacun, et ce qu'ils débloquent | CH3′ |
| S6 | **Table rase — l'item, cinq rôles** : les six listes plates deviennent un tableau | II.1 |
| S7 | **Trois surfaces au lieu de sept**, et ce que chacune ne montre pas | II.2 |
| S8 | **Quatre coques de fenêtres au lieu de vingt-deux** | II.3 |

---
---

# Partie II — Table rase : la structure que je propose

> **Cadre.** L'auteur a tranché : **v3 est abandonné**. Cette partie ne cherche donc plus le
> compromis compatible — elle repart de zéro et propose une structure de données, de surfaces et de
> fonctions, dictée par **SFAR**, **ECAM** et **AC 120-71B / FAA Order 8900.1**. Les deux contraintes
> du premier audit tiennent toujours : *aucun tutoriel*, *aucune aide livrée en plus*.
>
> Ce qui suit **remplace CH3 et CH3′** de la partie I. Les chantiers CH1, CH2, CH4, CH5, CH6, CH7
> restent valables et deviennent, pour la plupart, des **conséquences** de cette structure plutôt
> que des chantiers séparés.
>
> **Rien n'est décidé ici.** Chaque rupture est nommée en § II.7.

---

## II.0 · Ce que les trois sources prescrivent réellement

Le point de départ n'est pas « ce qu'on aimerait refaire », c'est **ce que les trois références
imposent et que la structure actuelle ne peut pas exprimer**.

| Source | Prescription | La structure v3 peut-elle l'exprimer ? |
|---|---|---|
| **AC 120-71B §5.2.2.1** | Un opérateur **lit**, l'autre **confirme et répond** | Partiellement — `::` dans une chaîne |
| **AC 120-71B §5.2.2.5** | Un item **critique** est vérifié par **les deux** | **Non** |
| **AC 120-71B / QRH** | Un *memory item* est un **item de la liste**, fait de mémoire **puis vérifié dessus** | **Non** — liste séparée, texte dupliqué (mesuré) |
| **AC 120-71B** | Une checklist a une **condition d'entrée** explicite | Oui (`confirmation`) |
| **AC 120-71B** | Après **interruption**, on re-vérifie | Oui (`cxResume`) |
| **FAA Order 8900.1 §3-3403.A** | **Do-Verify** : une seconde passe qui constate | Oui, mais **hors modèle** (état de session seul) |
| **Degani & Wiener 1993** | La réponse porte l'état **constaté**, jamais « fait » | Partiellement |
| **ECAM** | Niveaux d'alerte **ordonnés** : warning / caution / advisory | Non — deux préfixes, non ordonnés |
| **ECAM** | **Decluttering** : inhiber ce qui n'est pas la phase courante | **Non** |
| **ECAM** | E/WD (agir) et SD (se repérer) montrent **des choses différentes** | **Non** — 3 surfaces rendent les mêmes étapes (mesuré) |
| **ECAM / ECP** | Les **commandes** vivent hors de l'**affichage** | Oui (v4.25.0) — à conserver |
| **SFAR** | Une aide tient sur **une page** qu'on parcourt sans naviguer | Oui, mais c'est le mode « statique », que rien ne recommande |

**Cinq « non ».** Ce sont eux qui justifient la table rase — pas l'esthétique.

---

## II.1 · Le modèle — un item, cinq rôles, trois niveaux

### L'unité atomique : l'`Item`

```jsonc
{
  "id":     "i7",              // IDENTITÉ, jamais une position (Cause III bis)
  "role":   "do",              // entry | do | watch | dose | ddx
  "do":     "Adrénaline IM, cuisse",   // le CHALLENGE : ce qui se prononce
  "expect": "0,5 mg",          // la RÉPONSE ATTENDUE : l'état constaté
  "level":  3,                 // 3 warning · 2 caution · 1 advisory  (ECAM)
  "memory": true,              // immediate action item (AC 120-71B / QRH)
  "dual":   true,              // vérifié par LES DEUX (§5.2.2.5)
  "note":   "…"                // glose de l'auteur — jamais lue à voix haute
}
```

**Ce que cela supprime.** Les six listes plates de la fiche v3 — `confirmation`, `verify`,
`posology`, `notForget`, `differentials`, `references` — **n'existent plus comme champs**. Ce sont
des **rôles** d'un même `Item`, donc des **vues** :

| Champ v3 | Devient | Ce que le rôle gagne au passage |
|---|---|---|
| `confirmation` | `role:"entry"` | un `expect` (« Pouls central :: absent en 10 s ») et un niveau |
| `notForget` | `role:"do"` + `memory:true` | **cochable et traçable** — il cesse d'être un second texte |
| `verify` | `role:"watch"` | un `expect` chiffré (« PAS :: ≥ 80 mmHg ») |
| `posology` | `role:"dose"` | un niveau (△ imposé par la doctrine v4.23.0, désormais **vérifiable**) |
| `differentials` | `role:"ddx"` | un `expect` (« Asthme :: pas d'urticaire ») |
| `references` | **reste à part** (`sources[]`) | — c'est de la métadonnée bibliographique, jamais du contenu de crise |

**Six champs deviennent un tableau et un enum.** Ce n'est pas de l'abstraction pour elle-même :
ECAM n'a **qu'un** format de ligne, une QRH **qu'un** format d'item. Le rôle dit **où** l'item
s'affiche, pas **ce qu'il est**.

**Le gain le plus concret**, mesuré dans la fiche livrée : « Adrénaline IM = 1ʳᵉ intention, ne pas
retarder » (`notForget`) et « ⚠ Adrénaline IM, face antéro-latérale de cuisse » (étape b1) sont
**la même instruction, écrite deux fois, dans deux formulations**, dont une seule est cochable. Avec
`memory:true`, il n'y a plus qu'un texte — et le chapeau reste affiché à l'identique, comme **filtre**.

### Le groupe : le `Block`

```jsonc
{
  "id": "b1", "title": "Mesures immédiates",
  "phase": "immediate",        // immediate | secondary | watch   (inhibition ECAM)
  "kind":  "do",               // do | decision
  "items": ["i1","i7","i8"],   // des RÉFÉRENCES, pas des objets
  "next":  "b2",
  // kind:"decision" :
  "question": "Rythme choquable ?",
  "options": [ { "label":"Oui", "concl":"Choquable", "target":"b2" } ]
}
```

`phase` rend le **decluttering ECAM** possible : replier ce qui n'est pas la phase courante — c'est
**CH1 obtenu par le modèle** au lieu d'un réordonnancement de rendu. `concl` supprime le
contournement qu'`AI_PROMPT` impose déjà à l'IA (« des libellés-conclusions, parce que les vues
abrégées n'affichent que titre + réponse »).

### L'aide

```jsonc
{
  "v": 4, "id": "a1", "kind": "procedure",   // procedure | reference
  "title": "Anaphylaxie", "discriminant": "adulte", "code": "ANA",
  "category": "c-urgences", "library": null,
  "status": "validated", "validatedAt": "2025-01",
  "items":   [ /* Item[] — TOUS, à plat, identifiés */ ],
  "blocks":  [ /* Block[] */ ],  "start": "b1",
  "excursions": [ { "label":"Bronchospasme réfractaire", "target":"bx1" } ],
  "timers": [], "counters": [], "sources": [], "docs": [], "links": [],
  "local":  "Tél renfort : …"
}
```

**`kind`** absorbe les protocoles : un « protocole » est une aide de type `reference` (corps rédigé,
documents, rien à cocher). **Motif J0 mesuré** : l'état vide des protocoles décrit un *format* et
jamais la *différence*, et la bascule Aides/Protocoles est la **première décision imposée** à
quelqu'un qui ne connaît ni l'une ni l'autre. Une bibliothèque unique, un répertoire A→Z unique, et
le type devient un **filtre** au même rang que la catégorie — on ne demande plus de choisir avant de
chercher.

### La session — référentielle, append-only

```jsonc
{
  "id":"s1", "aidId":"a1", "aidRev":"r12",     // ← la RÉVISION lue pendant le soin
  "mode":"clinical",                            // clinical | exercise | trial
  "startedAt":…, "endedAt":…,
  "log": [ { "t":…, "kind":"check", "ref":"i7", "by":"lead" },
           { "t":…, "kind":"verify","ref":"i7", "by":"scribe" } ],
  "texts": { "i7":"Adrénaline IM, cuisse" }     // repli si la révision a disparu
}
```

**`aidRev` + `texts` répare la Cause III bis** : un compte-rendu ne dépend plus de l'état actuel de
la fiche. `log` est **exactement le format que le partage a déjà inventé** (`shareSnap`/`shareDiff` :
des références et des heures, jamais de texte libre) — le modèle local rattrape ici le protocole
réseau, et non l'inverse.

---

## II.2 · Les surfaces — trois, et elles montrent des choses différentes

C'est la règle ECAM que la structure actuelle enfreint : **le SD ne rejoue pas l'E/WD autrement
disposé, il montre autre chose.**

| Surface | Modèle | Contenu | Ce qu'elle ne contient PAS |
|---|---|---|---|
| **AGIR** | E/WD | Le bloc courant : ses items, cochables, dans l'ordre. Le chapeau `memory` replié. Le contrôle d'avancement. | La structure, les doses, les différentiels |
| **SE REPÉRER** | SD + **la page SFAR** | Toute l'aide en **une page** : blocs, branches, état, condition d'entrée, phases. **Titres et états, pas le texte intégral des items.** Inerte. | Aucune case à cocher |
| **CONSULTER** | STATUS / amplification QRH | `dose`, `watch`, `ddx`, documents, sources, liens | Rien de ce qui est déjà sous les yeux |

**Ce qui cesse d'être une surface :**

- **Mode lecteur** → une **densité** d'AGIR (bascule « à deux voix ») : même structure, typographie
  agrandie, boutons de réponse. C'est ce que la v4.62.0 avait déjà écrit (« le lecteur en est la
  densité `.rm-steps` ») sans aller au bout.
- **Mode statique** → **devient** SE REPÉRER. Mesuré, c'est déjà la seule surface qui contient tout.
- **Échelle et Schéma** → deux **affichages** de SE REPÉRER, comme avant la v4.25.0.
- **Mode exercice** → un **drapeau de session**, pas une vue. Déjà vrai.
- **Mode moniteur** → **reste** une surface distincte : ce n'est pas une vue de l'aide, c'est un
  afficheur d'état pour appareil posé. Il est déjà juste.

**Sept présentations deviennent trois.**

> **⚠ DEUX MISES À JOUR sur ce paragraphe.**
>
> **(1) Le sélecteur.** J'écrivais qu'il demanderait « agir ou se repérer ? ». **Abandonné en
> partie III** : c'était encore un choix de *présentation* sous stress. Il est remplacé par
> l'**axe de densité à trois crans** (Une étape · Un bloc · Toute la fiche), le cran le plus large
> portant **trois vues** — Parcours, **Page SFAR** et **Schéma** (décisions A3 et A10). Le tableau des trois surfaces
> ci-dessus, lui, reste juste.
>
> **(2) Les deux bandes persistantes.** J'écrivais qu'elles « ne bougent pas ». **La décision D1 les
> fusionne** : mesuré, elles coûtent 177 px permanents — 27,7 % de l'écran à 320 px, 43,9 % à 130 %.
> La séparation ECP/ECAM d'Airbus est **matérielle** (deux panneaux physiques) ; sur un téléphone il
> n'y a qu'une surface. Lot **T5b**, prototypé et mesuré seul.

---

## II.3 · Le squelette de fenêtres — quatre coques au lieu de vingt-deux

**Mesuré** : `index.html` déclare **22 fenêtres `.ai-modal`**, plus cinq surfaces plein écran. Or
elles se rangent en **quatre familles** qui partagent déjà leur comportement (`bindModalDismiss`)
sans partager leur coque :

| Coque | Remplace | Paramètres |
|---|---|---|
| **`dialog`** | `confirmModal`, `endSessModal`, `syncErrModal`, `pendingModal`, `welcomeModal` | titre, corps, actions, registre (`danger` / neutre) |
| **`picker`** | `attPickModal`, `relPickModal`, `catModal`, la cible de complication | titre, liste filtrable, groupes, rappel de sélection |
| **`sheet`** (plein écran) | `refModal`, `planModal`, `pdfModal`, la visionneuse d'image, le schéma | titre, contenu, sections dépliables |
| **`settings`** | `authModal`, `storageModal`, `membersModal`, `newLibModal`, `versModal`, `sessModal` | groupes de réglages, lignes libellé/contrôle |

Restent hors coque, à dessein : `readerMode` (densité d'AGIR), `monMode` (afficheur), `joinScreen`
(écran d'entrée), `shareModal`, `createModal`, `edAddModal`, `reportModal` — sept surfaces qui ont
chacune une raison propre.

**Bénéfice** : une seule mécanique d'accessibilité, de verrou de fond, de retour système et de focus
à tenir — au lieu de vingt-deux qui divergent une par une. Et **la porte « ＋ » devient réutilisable**
(constat 15 de l'audit 1) : c'est un `picker` avec une table `AC_LEX`.

---

## II.4 · Les fonctions premières — sept, et le reste en découle

Ce que le produit **fait**, dans l'ordre de fréquence réelle. Chacune doit être atteignable sans
apprentissage, et sa place découle du modèle ci-dessus.

| # | Fonction première | Surface | Coût en gestes visé |
|---|---|---|---|
| 1 | **Dérouler** une procédure sous stress | AGIR | ouvrir + démarrer = **2** |
| 2 | **Savoir où j'en suis** | SE REPÉRER | **1** |
| 3 | **Retrouver une dose, un piège** | CONSULTER | **1** |
| 4 | **Tracer** (horodater un geste) | AGIR — dans la carte du bloc | **1** *(aujourd'hui : y = 1 588 px, hors écran)* |
| 5 | **Écrire / valider** une aide | Éditeur | **3** depuis l'accueil |
| 6 | **S'entraîner** | drapeau de session | 2 |
| 7 | **Partager** avec un binôme | drapeau de session | 2 |

### Les points d'écriture uniques — le squelette du code

Le produit en a **cinq**, et c'est sa meilleure propriété. La structure v4 en garde cinq, aux mêmes
rôles :

| Fonction | Ce qu'elle est la seule à écrire |
|---|---|
| `migrate()` | toute donnée **entrante** (règle 5, conservée telle quelle) |
| `applyCheck()` | toute mutation de **progression** — et c'est là que `dual` s'appliquera |
| `persistLive()` | toute persistance d'une session **vive** (et l'émission de partage) |
| `edCommit()` | toute écriture d'un **brouillon** |
| `_putSessionSafe()` | toute écriture d'une session **archivée** |

**Trois nouvelles, et elles remplacent des familles entières :**

- **`AC_LEX`** — une table `{ glyphe, nom, conséquence en trois mots }` par type d'item et par
  niveau. Consommée par la porte « ＋ », par la légende des registres (constat 2 de l'audit 1), par
  les états vides (constats 1 et 5) et par le prompt IA. **Une source, quatre consommateurs.**
- **`itemsOf(block, role)`** — la seule façon d'obtenir des items. Remplace les neuf fonctions de
  désencodage de chaîne (`stepText`, `stepIsCrit`, `stepIsVigil`, `stepCR`, `stepNote`…) et les deux
  expressions régulières.
- **`renderSurface(nom)` + `paint(delta)`** — un rendu par surface, une peinture chirurgicale pour
  tout le reste. Remplace `renderRead` / `renderOvOnly` / `renderNavOnly` / `renderSvOnly` /
  `renderTkOnly` / `repaintRailLad` / `readerRepaint`.

---

## II.5 · Ce que la table rase permet et que v3 interdisait

Cinq capacités, toutes prescrites par les sources, toutes **inexprimables aujourd'hui** :

1. **La double confirmation d'un item critique** (`dual`, AC 120-71B §5.2.2.5). Le partage de session
   existe, les rôles existent, `applyCheck` est un goulot unique : il ne manque que le champ. **C'est
   la seule capacité clinique nouvelle de tout l'audit.**
2. **Le decluttering par phase** (ECAM) : replier ce qui n'est pas la phase courante.
3. **Le memory item cochable et traçable** — il apparaît au compte-rendu, ce qui est exactement ce
   qu'une QRH attend d'un *immediate action item*.
4. **La vérification calculable** : le plafond de deux items colorés par bloc, que `AI_PROMPT` impose
   déjà à une IA, devient signalable par l'éditeur comme les autres garde-fous.
5. **Un compte-rendu qui ne se décale plus** (`aidRev` + `texts`).

---

## II.6 · Ce qui ne bouge pas, et pourquoi

- **Local-first, hors ligne, zéro dépendance runtime** (règles 5, 6, 13) — c'est la raison d'être.
- **Les cinq points d'écriture uniques** — la robustesse tient à eux.
- **La sémantique des registres** : ⚠ tue / △ trompe, la couleur jamais seule, le rouge rare
  (règle 8). v4 la rend **calculable**, il ne la change pas.
- **Le partage ne transporte que des références** (règle 15) — v4 **aligne le local dessus**.
- **Le périmètre réglementaire** : aucun champ calculé, aucune déduction. v4 décrit mieux ce que
  l'auteur écrit ; il n'en tire jamais rien.
- ~~**Les commandes hors de l'affichage** (ECP, v4.25.0).~~ **⚠ RETIRÉ de cette liste par la
  décision D1** : les deux bandes fusionnent (lot T5b). Ce qui reste intangible, c'est que **l'état
  ne disparaît jamais** — chrono et minuteurs restent visibles en permanence, fusion ou non.
- **Les quatre surfaces qui enseignent déjà sans tutoriel** : dialogue « Créer », porte « ＋ »,
  écran invité, dialogue « Terminer la session ? ».

---

## II.7 · Les ruptures, nommées

Rien de tout cela ne se décide par effet de bord.

| # | Rupture | Ce qu'elle coûte | Recommandation |
|---|---|---|---|
| R1 | **Format v4**, v3 en **import seulement** | Un importeur v3 → v4 sans perte ; export v4 seul | **Oui** — c'est la décision déjà prise |
| R2 | **Six listes plates → un `Item[]` + `role`** | Réécriture de l'éditeur et de tous les rendus | **Oui** — c'est le cœur du gain |
| R3 | **`notForget` disparaît comme champ** | Le chapeau devient une vue ; migration : chaque rappel devient un item `memory` **non rattaché à un bloc** tant que l'auteur ne l'a pas placé | **Oui**, avec un écran de reprise en éditeur |
| R4 | **Protocoles fusionnés dans les aides** (`kind`) | La tab bar Aides/Protocoles disparaît ; filtre à la place | **Oui** — motivé par une mesure J0 ; **la décision la plus visible pour l'utilisateur** |
| R5 | **Sept surfaces → trois** | Refonte de la navigation de lecture | **Oui**, après R1/R2 |
| R6 | **22 fenêtres → 4 coques + 7 surfaces propres** | Mécanique, vérifiable au pixel | **Oui**, en dernier |
| R7 | **Les sessions archivées v3 sont conservées telles quelles** | Deux formats de session à lire | **Oui** — on ne réécrit pas un enregistrement de soin |
| R8 | **`AGENTS.md` scindé** (CH5) | Rédaction | **Préalable** à tout le reste |

### Ordre proposé

> **⚠ SUPERSÉDÉ par [`transition-v4.md`](transition-v4.md) § 6** (lots T0–T12, avec T11 « réécrire
> la doctrine » et T12 « réécrire `AI_PROMPT` », absents d'ici).

1. **CH5** (doctrine scindée, paliers auto-vérifiables) — préalable.
2. **R1 + R2 + R3** : le modèle, l'importeur, l'éditeur. Sans changement de surface.
3. **CH1 / R5** : AGIR en tête, puis les trois surfaces. `phase` rend CH1 structurel.
4. **CH7** : le harnais de budget d'écran, calibré sur le résultat.
5. **R4** : la fusion Aides/Protocoles — seule, parce que c'est la plus visible.
6. **CH4 + R6** : les couches CSS et les coques de fenêtres, sans aucun changement visuel.

---

## II.8 · Ce que je ne sais pas

- **Le volume réel.** Aucune ligne de v4 n'a été écrite ; les estimations de la partie I valent
  encore moins ici. Le seul chiffrage solide est ce que la structure **supprime** : 6 champs,
  9 fonctions de désencodage, 2 expressions régulières, 4 présentations, ~18 coques de fenêtres.
- **R4 est la seule rupture que je n'ai pas pu tester auprès d'un utilisateur**, et c'est la plus
  visible. Elle est motivée par une mesure J0 (l'état vide ne peut pas dire la différence), pas par
  une observation d'usage. Si un seul point devait être prototypé avant d'être décidé, c'est
  celui-là.
- **`dual` suppose un binôme réellement présent.** En solo, le champ doit se dégrader proprement
  (l'item se coche normalement) — sinon il bloque un soignant seul, ce qui serait l'inverse du but.
  Le comportement en solo est à décider, pas déductible des sources.
- **Rien ici n'est validé sous stress.** Le mode exercice reste le seul instrument capable de le
  faire.

---
---

# Partie III — R4 prototypé, et le design remis en question

> **Livrable interactif : [`proto-r4.html`](proto-r4.html)** — deux écrans qui **fonctionnent**
> (tapez, filtrez, épinglez, cochez, changez de densité), plus la revue de chaque décision de design.
> Consigne suivie : je m'affranchis des règles, **y compris des miennes**.

## III.1 · Ce que le prototype R4 a appris en étant conduit

**Un piège de filtres, trouvé en le construisant, et il vaut règle générale.** La première version
comptait les effectifs de type sur l'ensemble *hors filtre de catégorie*. Dès qu'une catégorie était
prise, tous les compteurs de type tombaient à zéro, **tous les chips passaient `disabled` — y compris
celui qui était actif**. L'utilisateur ne pouvait plus relâcher son propre filtre : **piège sans
issue**, mesuré par la sonde (le clic sur le chip actif expirait au bout de 30 s).

Deux règles en découlent, et elles valent pour **toute** barre de filtres du produit :

1. **Un compteur se calcule dans la sélection des AUTRES filtres, jamais dans la sienne.**
2. **Un chip ACTIF n'est jamais désactivé** — c'est la seule sortie.

C'est exactement la famille « aucun bouton mort » que la doctrine applique déjà ailleurs (le lien
Historique masqué à zéro session), mais énoncée du côté opposé : ici le bouton mort est **le seul
qui pouvait défaire l'état**.

**Vérifications de la version corrigée** (deux moteurs, deux thèmes) : recherche traversant les deux
types (« intub » → 1 procédure + 1 référence), filtres composables et relâchables dans les deux
ordres, épinglage en un tap, état vide avec sortie, **0 texte sous 11 px, 0 cible sous 32 px,
0 débordement horizontal, 0 erreur JS**.

## III.2 · Ce que le prototype propose, et que je n'avais pas proposé

**J'abandonne ma propre proposition S7.** J'y gardais un sélecteur « Agir / Se repérer » — donc
encore un **choix de présentation**, sous stress. Les quatre présentations actuelles (lecteur,
guidé, statique, se repérer) ne sont pas quatre *modes* : ce sont quatre **densités** du même
contenu, et une densité est un axe **ordonné**.

| Cran | Remplace | Sert à |
|---|---|---|
| **Une étape** | mode lecteur | lire à voix haute, à deux (AC 120-71B §5.2.2.1) |
| **Un bloc** | guidé · journal | agir seul — modèle E/WD |
| **Toute la fiche** | statique · se repérer | la page SFAR : se situer, préparer, imprimer |

Un axe ordonné se parcourt **sans se rappeler des noms**, et il est réversible sans perte —
l'état de cochage est le même aux trois crans, ce qui est vrai depuis `applyCheck`. Vérifié dans le
prototype : cocher au cran 2, passer au cran 3, la coche a suivi.

**Ce qu'il ne faut pas prétendre** : le **schéma** (vue spatiale de l'algorithme) n'est pas une
densité, c'est une *autre représentation*.

> **⚠ MISE À JOUR (décision A10).** J'ajoutais ici « il garde une entrée à part », ce qui
> **contredisait le § II.2** du même document (« Échelle et Schéma → deux **affichages** de
> SE REPÉRER »). L'auteur a tranché dans le sens du § II.2 : le schéma est le **troisième onglet du
> cran “Toute la fiche”**, aux côtés de Parcours et Page SFAR, et il quitte le menu ⋯.

**Effet de bord mesuré** : avec un seul contrôle et un seul bouton, la rangée de commandes peut
fusionner avec le quai d'état — **53 px de chrome permanent rendus** (177 → 124 px, soit
**27,7 % → 19,4 %** de l'écran à 320 px).

## III.3 · Verdicts sur les décisions de design

| Verdict | Décision | Argument |
|---|---|---|
| **On jette** | Tab bar Aides / Protocoles | 51 px permanents à 320 pour une taxonomie **interne**, imposée avant la recherche |
| **On jette** | Sélecteur « Guidé / Statique » **et mon « Agir / Se repérer »** | Un choix de présentation sous stress ; ce sont des densités |
| **On jette** | Les modales sur téléphone | Six versions du changelog pour faire tenir des fenêtres centrées dans un viewport mouvant. Sous 780 px : **feuille plein écran + retour système**, une seule coque |
| **À rouvrir** | Deux bandes collantes (ECP/ECAM, v4.25.0) | 177 px, **27,7 %** de l'écran à 320, **43,9 %** à 130 %. La séparation Airbus est **matérielle** ; sur un téléphone il n'y a qu'une surface |
| **À rouvrir** | Répertoire A→Z par défaut | A→Z suppose qu'on connaisse le **nom** ; en crise on connaît la **situation**. La recherche est le meilleur parcours mesuré (2 gestes) |
| **À rouvrir** | Deux éditeurs séparés | Une **coque** unique, **deux corps** — fusionner les corps serait une erreur |
| **À rouvrir** | Lecture d'une référence | Elle hérite du chrome de crise alors qu'**on ne s'y déroule rien**. `kind` le rend exprimable |
| **On garde** | Quai d'état permanent · carte « SESSION EN COURS » · registres et leur rareté · les quatre surfaces qui enseignent | Le meilleur du produit — modèle, pas matière à refonte |

## III.4 · Ce que je n'ai toujours pas mesuré

- **R4 n'a pas été testé auprès d'un utilisateur.** Le prototype prouve que ça *marche*, pas que ça
  se *comprend*. La perte est réelle et nommée : on retire un repère de navigation permanent, et
  quelqu'un qui pense « je vais dans mes protocoles » doit apprendre un filtre.
- **L'axe de densité non plus.** Trois crans supposent qu'on sache lequel on veut ; c'est une
  hypothèse, pas une observation.
- **La fusion des deux bandes n'est pas prototypée** — seuls les 53 px sont mesurés, pas la perte de
  constance positionnelle qu'elle coûte.
- Le prototype tourne sur **douze aides fictives**. Rien n'y éprouve la montée en charge (200 aides,
  bibliothèques partagées, recherche plein texte).

---

## III.5 · Montée en charge et repère de navigation — mesurés

### Montée en charge : la performance n'est pas le problème, la HAUTEUR l'est

Prototype chargé de N aides générées, 390 × 844 :

| N | rendu | frappe (pire) | nœuds DOM | hauteur de liste | objets visibles sans défiler |
|---|---|---|---|---|---|
| 12 | 0,9 ms | 1,7 ms | 139 | 1 341 px — 2,8 écrans | 6 |
| 60 | 1,0 ms | 1,3 ms | 619 | 5 652 px — 13 écrans | 6 |
| **200** | **1,8 ms** | 3,6 ms | 1 999 | **15 018 px — 31 écrans** | **6** |
| **400** | **2,8 ms** | 3,8 ms | 3 970 | **33 936 px — 78 écrans** | **6** |

**Le rendu et la recherche ne bougent pas** (2,8 ms à 400 aides, frappe sous 4 ms) : la pagination
n'a aucune justification technique. **Ce qui explose, c'est la hauteur** — 31 écrans à 200 aides, et
toujours **6 objets visibles**. Sans dispositif de saut, le répertoire cesse d'être praticable entre
60 et 200 aides.

**Ce que la montée en charge a révélé dans mon prototype** : je n'y avais pas mis le **rail
alphabétique**. Il est désormais implanté et vérifié — il apparaît dès 2 lettres, disparaît s'il ne
tient pas, et ses cibles font **46 à 52 px** à toutes les échelles testées (règle 9 : jamais sous
24 px). Un saut mesuré : `scrollTop` 0 → 14 272 px en un tap. **Le rail de l'application réelle
n'est pas un ornement : c'est ce qui rend le répertoire utilisable**, et c'est la montée en charge
qui le démontre.

### Repère de navigation : ce qui se mesure, et ce qui ne se mesure pas

| Question | Mesure |
|---|---|
| L'information de type survit-elle sans la tab bar ? | **200 / 200 rangées** portent l'étiquette `Procédure` / `Référence`. Elle ne dépend jamais du filtre. |
| Atteindre toutes les références coûte-t-il plus cher ? | **1 geste** dans les deux cas (onglet ou chip). Égalité. |
| Chercher sans savoir dans quelle moitié ? | **1 geste**, et la recherche traverse les deux types (vérifié : « intub » → procédure + référence alternées). |
| **Le contrôle reste-t-il sous le pouce ?** | **Non.** La tab bar est centrée à **y = 765 sur 844** — dans le tiers inférieur, atteignable à une main. La rangée de filtres est **en haut**. |

**Trois égalités et une perte réelle.** La perte n'est pas la trouvabilité — c'est
l'**ergonomie à une main** : R4 déplace le contrôle de type du bord atteignable au bord opposé. Sur
un appareil tenu d'une main pendant un soin, ce n'est pas un détail, et **c'est le seul argument
sérieux pour conserver la tab bar**.

Piste, non prototypée : ancrer la rangée de filtres **en bas** plutôt qu'en haut, sous la liste.
Elle garde alors la zone du pouce sans réintroduire un onglet — mais elle change une convention
forte (les filtres se lisent avant la liste, pas après), et cela se teste, cela ne se décide pas.

**Ce que je continue de ne pas savoir** : rien de tout ceci ne mesure la **compréhension**. Un
utilisateur qui pense « je vais dans mes protocoles » n'a pas de repère persistant dans R4, et aucune
de ces quatre lignes ne dit ce que cela lui coûte.

## III.6 · Blocs conditionnels — l'oubli, et sa réparation

**Question de l'auteur, et la réponse est non : ce n'était pas volontaire.** Le premier prototype
n'avait qu'une suite linéaire avec une décision qui ne branchait pas. C'était un défaut sérieux,
parce que ma revendication « le cran *Toute la fiche* remplace le mode statique » n'était **pas
éprouvée là où elle est difficile** — c'est-à-dire sur un algorithme qui branche, converge, s'imbrique
et reboucle, précisément ce qui a coûté au projet les flèches mesurées, les gouttières et les
élargissements du mode statique.

Le prototype porte désormais un **vrai graphe** de forme ACR : décision → deux branches →
**convergence** → décision **imbriquée** dans une branche → **deux arcs de retour** vers un bloc
antérieur. Le cran 3 en rend le plan : numérotation commune en parcours de profondeur, branches
indentées avec leur libellé-conclusion, et renvois.

**Et il a produit un défaut instructif.** Ma première détection annonçait « ↺ reprendre au bloc n »
pour **toute** cible déjà décrite — donc aussi pour une **convergence**, où l'on avance. Le critère
que j'avais pris (comparer les numéros) est faux : la numérotation en profondeur peut donner un
numéro plus petit à un bloc qu'on rejoint en avançant. Le critère juste est celui du graphe : la
cible est-elle un **ancêtre du chemin courant** ?

- ancêtre → **arc arrière** → boucle : « ↺ reprendre au bloc 2 »
- sinon → **post-dominateur** → convergence : « → rejoint le bloc 4 »

C'est exactement la distinction que `flowPlan` fait déjà dans l'application. Vérifié dans le
prototype : deux boucles vers le bloc 2 correctement marquées `↺`, une convergence vers le bloc 4
correctement marquée `→`, registres distincts (bleu pour le retour, neutre pour la convergence —
on ne peint pas en couleur d'action un simple raccord).

**Ce que cela confirme sur le modèle v4** : `options[].target` et `next` pointant un bloc
quelconque suffisent — aucun champ supplémentaire n'est nécessaire pour l'imbrication ni pour les
boucles. La structure de la partie II tient. **Ce que cela ne prouve toujours pas** : que le cran 3
reste lisible sur un algorithme à quatre niveaux d'imbrication. Le prototype en a **deux**.

---

## III.7 · Quatre points soulevés, quatre réponses mesurées

### 1. Le cran 3 à **quatre niveaux d'imbrication**

Graphe porté à quatre niveaux (décision → décision → décision → décision, avec deux arcs de retour
et deux convergences). Rendu **vérifié** :

```
1 RECONNAISSANCE & ALERTE
2 ANALYSE DU RYTHME
    CHOQUABLE   3 CHOQUABLE
                4 APRÈS 3 CHOCS
                    FV RÉFRACTAIRE  5 FV RÉFRACTAIRE
                                    6 CAUSES RÉVERSIBLES
                                        CAUSE TRAITABLE  7 TRAITER LA CAUSE
                                                         8 RÉPONSE AU TRAITEMENT
                                                             RACS POSSIBLE   9 POURSUITE
                                                                             ↺ bloc 2
                                                             SANS RÉPONSE    ↺ bloc 2
                                        AUCUNE           → rejoint le bloc 9
                    RYTHME CHANGÉ                        → rejoint le bloc 9
    NON CHOQUABLE 10 NON CHOQUABLE
                                                         → rejoint le bloc 6
```

**Mesuré à 320 px** : indentation de 13 px par niveau, largeur du bloc **294 px au niveau 0 → 242 px
au niveau 4**, soit **−18 %** de largeur de texte. **0 bloc en débordement, 0 défilement horizontal**
à 320 comme à 390. Boucles et convergences correctement distinguées jusqu'au niveau 4.

**Verdict** : quatre niveaux tiennent, mais 242 px est la limite basse du confortable. Le plafond
d'indentation de l'application réelle (4 niveaux) est donc **le bon plafond, et il est serré** — au
cinquième, il faudrait cesser d'indenter et basculer sur un renvoi numéroté.

### 2. Le retour du **mode statique**, comme présentation du cran 3

Demande retenue telle quelle, et la solution proposée par l'auteur est la bonne : **l'axe de densité
reste à trois crans**, et c'est **le cran le plus large qui porte deux présentations** —

- **Parcours** : la structure, l'état, les branches, le « ICI ». On se situe.
- **Page SFAR** : un **document**. Aucun état de progression, aucune case, aucun « ICI » — on ne
  suit rien, on **lit**. Six cellules dans l'ordre d'une aide SFAR : *quand l'utiliser · éliminer
  d'abord · gestes immédiats · algorithme · doses · surveiller*.

**Mesuré** : 6 cellules, largeur minimale **145 px à 320** / 180 à 390, **2,2 écrans** de haut
(contre 4,4 pour le parcours), **0 défilement horizontal**, **0 texte sous 11 px**. En impression,
la grille passe à trois colonnes.

C'est le bon endroit pour ce mode : il ne consomme **aucun cran** de l'axe, il n'ajoute **aucun
bouton** à la rangée de commandes, et il ne se propose qu'à quelqu'un qui a déjà demandé la vue la
plus large — c'est-à-dire exactement le public qui veut « une SFAR, sans étapes guidées ».

### 3. Différentiels et surveillances — **non, ce n'est pas le même bloc**

C'est la question la plus juste des quatre, parce que je les avais rangés ensemble dans
« Consulter » sans jamais le justifier. Ils répondent à **deux questions différentes, à deux moments
différents** :

| | Question posée | Moment | Où il vit désormais |
|---|---|---|---|
| **`ddx` — différentiels** | « ça ne colle pas » | c'est un **doute sur la condition d'entrée** | **avec les critères d'entrée**, en tête — plus un rappel « Ça ne colle pas ? → 3 diagnostics à éliminer », appelable à tout instant (le doute peut naître plus tard) |
| **`watch` — surveillances** | « qu'est-ce que je surveille maintenant » | c'est l'**après** | **en fin de parcours**, et consultable avant. Modèle **STATUS d'ECAM** : ce qui reste à tenir une fois les actions faites |

Les mettre dans la même section de « Consulter » était une **erreur de rangement** : cela plaçait
un doute diagnostique (qui doit surgir tôt) au même endroit qu'un plan de surveillance (qui vient
tard). Dans la page SFAR, ils occupent d'ailleurs deux cellules distinctes, aux deux extrémités du
document — « Éliminer d'abord » en haut, « Surveiller » en bas.

### 4. Les **bibliothèques partagées** — elles n'existaient pas dans le prototype

Trou réel, comblé. Une bibliothèque n'est **pas un filtre comme les autres** : c'est une
**provenance**, et elle porte une **autorité** (qui a validé ? puis-je modifier ?). Elle apparaît
donc à **deux** endroits, jamais à un seul :

- **Sur la rangée, en toutes lettres, toujours** — `SAMU 44`, `CHU — Anesth. ⌧`. L'information ne
  dépend jamais d'un filtre. « Perso » ne s'écrit pas : le défaut n'a pas besoin d'étiquette.
- **En tête de la piste de filtres, séparée par un filet**, parce que c'est un axe d'une autre
  nature que « type » et « catégorie ».
- Le glyphe **⌧ = lecture seule** : la couleur n'est jamais seule (règle 8).

**Mesuré** : 0 rangée en débordement à 320 et 390. **Mais le coût est réel** : à 320 px la
sous-ligne passe à **trois lignes** et la rangée monte de **67 à 89 px** (+33 %). Et la piste de
filtres porte désormais **13 chips** — elle défile horizontalement, donc les catégories sont
**hors écran à l'ouverture**.

**Ce que cela remet en cause** : à trois axes (provenance × type × catégorie), une piste unique ne
suffit plus. Deux pistes coûtaient 98 px (mesuré § III.5) — c'est-à-dire plus que la tab bar
supprimée. **Il faut donc trancher** : soit la provenance quitte la piste pour un sélecteur d'en-tête
(comme le « scope » actuel de l'application), soit les catégories deviennent secondaires. Le
prototype montre le problème ; il ne le résout pas, et je ne veux pas le masquer.

---

## III.8 · Éditeurs et grands écrans — [`proto-large.html`](proto-large.html)

Cinq écrans construits à leurs **dimensions réelles** : accueil tablette 834 × 1112, lecture d'une
procédure 1440 × 900, lecture d'une référence 1440 × 760, éditeur de procédure 1440 × 940, éditeur de
référence 1440 × 820. Vérifiés : **0 texte sous 11 px, 0 débordement, deux thèmes, 0 erreur**.

### Le grand écran RÉSOUT le problème que le téléphone laissait ouvert

C'est le résultat le plus utile de cette passe. À trois axes de filtre — **provenance × type ×
catégorie** — la piste de chips sature : 13 chips, catégories hors écran (mesuré § III.7). Au-dessus
de 780 px, **les trois axes descendent dans la colonne latérale**, tous visibles à la fois, à coût de
hauteur nul. La contrainte reste donc entière **sur le téléphone seulement** — et c'est là, et là
seulement, qu'il faut trancher.

Autre conséquence, symétrique : **le rail alphabétique disparaît** en tablette. Le répertoire à deux
colonnes montre trois fois plus de rangées, et un rail vertical n'y désigne plus une position unique.
Il reste sur téléphone, où il est indispensable (31 écrans de liste à 200 aides).

### L'axe de densité se réduit tout seul sur grand écran

Au-dessus de 1200 px, **deux densités tiennent côte à côte** : « Toute la fiche » à gauche (parcours,
inerte), « Un bloc » au centre (action), l'état à droite. Le sélecteur ne porte alors plus qu'**un
seul choix utile** : passer ou non en « Une étape » (lecture à deux voix, qui prend tout l'écran).

C'est l'E/WD et le SD d'ECAM enfin simultanés — ce que la v4.59.0 avait vu avec son cockpit, mais en
juxtaposant **trois colonnes de contenu** au lieu de **deux densités du même contenu**. La nuance
n'est pas rhétorique : deux densités partagent le même état de cochage, donc rien ne peut diverger.

### La référence perd le chrome de crise

Point relevé en III.3 et réglé ici : une référence s'ouvre comme un **document** — sommaire, corps
plafonné à 780 px, documents, sources. **Ni bascule de densité, ni quai d'état, ni chrono.**
Mesuré sur la maquette : **58 px de chrome au lieu de 184**.

### L'éditeur : une coque, deux corps

Barre, identité, état d'enregistrement, anneau d'annulation, relecture, versions : **identiques**
pour les deux types. Seul le corps diffère — items structurés d'un côté, texte rédigé de l'autre.
Les fusionner serait une erreur : écrire une procédure et rédiger une référence ne sont pas le même
geste.

**Ce qui est nouveau dans l'éditeur de procédure, et ce n'est pas cosmétique** — deux boutons sur la
ligne d'item en édition :

- **★ mémoire** → l'item apparaît aussi dans le chapeau « Ne pas oublier ». Cela **supprime la liste
  `notForget` comme champ**, donc la duplication mesurée dans la fiche d'exemple livrée (deux
  formulations de la même instruction, une seule cochable).
- **×2 double** → **AC 120-71B §5.2.2.5**, l'item critique confirmé par les deux opérateurs.
  Aujourd'hui **inexprimable**.

Trois autres choix visibles sur la maquette : le **niveau** est un sélecteur à trois crans
(⚠ / △ / —) et non deux bascules — parce que `level` est ordonné ; la **phase** du bloc est un
sélecteur (`immédiate`), ce qui rend le decluttering ECAM éditable ; et la colonne **structure**
porte en toutes lettres qu'elle ne s'écrit pas — *« elle découle des blocs et de leurs cibles. Taper
une ligne y amène ; rien ne s'y modifie. »*

### Ce que ces maquettes ne prouvent pas

Elles sont **statiques**. Le geste d'édition — ⏎ qui crée l'item suivant, `!`/`?` en tête, prendre et
poser à la poignée, le repli du chapeau — n'y est pas éprouvé. Et la colonne structure à 260 px n'a
été testée qu'avec **10 blocs** : au-delà, elle défile, et le comportement du défilement pendant
qu'on écrit dans la colonne centrale n'est pas mesuré.

---

## III.9 · Le journal des actions sur téléphone — le manque, et sa réponse

**Question de l'auteur, et la réponse est non : je ne l'avais montré que sur l'écran d'ordinateur**
(colonne de droite, § III.8, écran B). C'était un manque d'autant plus gênant que **CH6 est mon
propre constat** et que le téléphone est la cible.

### La mesure qui motive le chantier

| | 320 × 640 | 390 × 844 |
|---|---|---|
| **Application réelle** — `.tk-add` | y = **1 829 px**, soit **1 189 px sous le pli** | y = **1 588 px**, **744 px sous le pli** |
| visible sans défiler | **non** | **non** |
| **Prototype** — « ⏱ Noter l'heure » | y = 435 px dans la colonne | y = 388 px |
| visible sans défiler | **oui** | **oui** |

Le geste de traçabilité le plus fréquent d'une réanimation était le plus loin de la main.

### Deux choses distinctes, deux emplacements

- **LE GESTE** (noter) vit dans la carte du **bloc courant**, sous « Continuer » : c'est là que le
  geste se produit, donc là qu'on l'horodate.
- **LA LECTURE** (le journal) vit **derrière le quai**, avec les minuteurs et les compteurs. Tout ce
  qui est l'**état vivant de la session** est au même endroit, et le quai le nomme :
  « 1 minuteur · 1 compteur · 1 repère ▾ ». C'est la même correction que le constat 6 du premier
  audit, étendue au journal.

### L'accusé de réception est **en place**, jamais flottant

Taper « Noter l'heure » ouvre, **sous le bouton**, une bande verte « ✓ 02:14 noté » avec les
propositions d'étiquette en chips. **Aucune modale, aucune notification** : c'est la doctrine
« répondre à un geste n'est pas interrompre » (v4.55.4). Le vocabulaire montre **4 propositions +
« … »** — sept chips d'emblée occupaient trois rangées sur téléphone.

**Mesuré** : l'accusé fait 156 px, et à 390 px il **ne fait pas croître la colonne** (elle avait déjà
la place) ; à 320 px il ajoute 164 px, qui disparaissent dès qu'une étiquette est choisie ou qu'on
navigue.

### Un défaut de saillance que le prototype a révélé

Ma première version faisait de « Noter l'heure » un bouton **pleine largeur**, sous « Continuer » :
même poids visuel pour un geste **secondaire** et pour celui qui fait avancer le soin. Corrigé —
largeur **auto (121 px)**, hauteur 44 px, registre tonal léger. **Un seul bouton pleine largeur par
carte, et c'est celui qui avance.** C'est la règle de la v4.77.0 (« Noter l'heure passe tonal »),
appliquée cette fois aussi à la **taille** et pas seulement à la couleur.

---

## III.10 · Deux manques de plus, comblés

### 1. On ne pouvait pas noter l'heure au cran « Une étape » — et c'était le pire endroit

**Non, on ne pouvait pas** — ni dans mon prototype, ni dans l'application réelle (le mode lecteur est
un plein écran, et le journal vit dans le rail ≥ 780 px). **C'est l'endroit où l'omission coûte le
plus** : au cran « Une étape », l'appareil est tenu par **le lecteur**, c'est-à-dire par la personne
dont le rôle est précisément d'énoncer et de **tracer** (AC 120-71B §5.2.2.1). La fonction manquait
là où la personne qui en a besoin tient le téléphone.

**Corrigé — après une première version fausse, signalée par l'auteur.** J'avais mis une **icône
compacte 44 × 44 en tête de carte**, au motif que le cran 1 est dépouillé (un challenge en 22 px,
deux grands boutons de réponse) et qu'un troisième bouton pleine largeur l'aurait dilué.

**L'objection était juste, et la mesure l'a tranchée** : un contrôle qui change de place selon le
cran doit être **retrouvé** — c'est exactement ce que la constance positionnelle interdit, et cela
contredit la promesse de l'axe (« le contenu ne change pas, sa densité si »).

| | 320 × 640 | 390 × 844 |
|---|---|---|
| **A — ⏱ en tête** (ma version) | écart de position entre crans : **360 px** | **313 px** |
| **B — ⏱ en bas**, même rangée, même forme | **109 px** | **62 px** |
| B déborde-t-il ? | **non** (488 px de contenu pour 488 de colonne) | non |
| les deux boutons de réponse restent visibles ? | **oui** | oui |

**B retenu.** Ma justification ne tenait pas : la rangée du bas tient à 320 × 640 sans rien pousser
dehors. Le ⏱ occupe désormais **le même rang dans les trois crans** — dernière rangée de la carte,
même libellé, même forme (121 × 44 px). L'écart résiduel (109 / 62 px) vient de ce que le cran 1 a
**deux** boutons de réponse là où le cran 2 en a un : c'est le même **rang de lecture**, pas le même
pixel, et c'est ce que la constance positionnelle demande réellement ici.

**Hygiène** : le composant `.ticon` n'étant plus émis nulle part, son CSS part avec lui (règle 14 —
zéro occurrence vérifiée).

### 2. Le compte rendu de session sur téléphone

Jamais montré non plus. Sur téléphone c'est une **feuille plein écran**, pas une modale centrée —
l'idiome de la plateforme, et cela supprime le calcul de hauteur visible qui a coûté six versions au
dossier « bande basse iOS ».

Contenu, entièrement dérivé du **journal référentiel** (aucun texte libre) :

1. **Tête de bilan** — durée en mono 40 px + quatre tuiles (chocs, adrénaline, étapes faites, repères).
   C'est le F6 de la v4.57.0, conservé.
2. **Chronologie** — les repères horodatés, avec leur étiquette.
3. **Étapes réalisées** — avec leur registre (⚠ / △ / ·) et leur réponse attendue.
4. **Vérification (do-verify)** — constatés et écarts, ou l'absence **dite** (« aucune passe de
   vérification sur cette session ») plutôt que tue.
5. **Items critiques** — et c'est là qu'apparaît la décision prise pour `dual` : « RCP immédiate —
   **confirmé seul** ». L'option (a) ne bloque pas le soignant isolé, et **la trace dit ce qui s'est
   réellement passé**.
6. **Pied** — « les libellés proviennent de la révision de l'aide lue pendant le soin
   (`aidRev r12`) ». C'est la Cause III bis réglée, et visible dans le document.

**Mesuré** : **1,0 écran à 390 px**, 1,4 à 320 px ; 0 texte sous 11 px, 0 débordement horizontal ; les
deux actions (Télécharger · Imprimer) sont **ancrées en pied de feuille**, donc toujours atteignables
sans défiler jusqu'au bout.

**Ce qui reste à décider** : le compte rendu est une sortie **individualisée** au sens du périmètre
réglementaire — il faut vérifier qu'enrichir sa tête de bilan ne le fait pas franchir la ligne du
§ 2 de `deploiement-et-conformite.md`. Il **recopie** et ne **déduit** rien : à ce titre la
qualification ne bouge pas, mais c'est un point à confirmer, pas à supposer.

---

## III.11 · Partage de session et mode exercice sur téléphone

Deux surfaces que je n'avais montrées **nulle part** — ni en téléphone, ni en grand écran.

### Le partage vit derrière le quai

Même règle que le journal (§ III.9) : **tout ce qui est l'état vivant de la session est au même
endroit**, et le quai le nomme — « ⇄ 2 · 1 minuteur · 2 repères ▾ ». Derrière : le code
d'appariement, les participants et leurs rôles, « passer la main », « couper ».

| Rangée | Pourquoi là |
|---|---|
| Code &amp; QR | Ne sert qu'à l'appariement, **une fois**. Rien à laisser dans le chrome. |
| Participants et rôles | C'est de l'état vivant, comme les minuteurs. Le rôle vient d'un `<select>` de neuf intitulés — **jamais un champ libre** (règle 15). |
| Couper · passer la main | Gestes rares et lourds : ils ne doivent **pas** être à portée de pouce pendant un soin. |

**La contrainte dure est respectée** : le quai porte un **jeton fermé** (`⇄ 2`), aucun segment
ajouté. Un segment qui apparaîtrait sur évènement **distant** déplacerait le segment d'alarme sous
les yeux de quelqu'un qui n'a rien demandé.

### Le partage rend enfin `dual` réel

C'est l'objection que je portais moi-même : **hors binôme, `dual` n'est qu'un badge**. En partage il
a un mécanisme, et l'écran de l'hôte le montre : ⚠ Choc 200 J est en **1/2** — « annoncé par vous,
attend l'IADE ». **Le compte du bloc reste 1/2**, et le compte rendu ne l'inscrit pas. Sur l'appareil
de l'IADE, le même item porte « Confirmer ».

Hors binôme, la décision retenue **(a)** s'applique : l'item se coche normalement, le compte rendu
porte « **confirmé seul** » — visible dans la maquette du § III.10.

### Le lien coupé : le texte reste lisible, les contrôles se ferment

Bandeau **dans le flux**, registre ATTENTION (pas ALERTE : une liaison qui s'arrête n'est pas un
geste clinique manqué), portant la **cause** (« l'hôte a clos la session à 04:31 ») et **la sortie**
(« Quitter le partage… »). Le texte clinique reste **pleinement lisible** — c'est le dernier état
connu du soin ; seuls les **contrôles** prennent l'apparence fermée. **Aucune `opacity` d'ensemble** :
elle affadirait aussi le rouge et l'ambre, qui portent le sens.

### L'exercice est un drapeau, pas une surface

Même écran, mêmes gestes, mêmes minuteurs, même journal — **seule l'annonciation change** : hachure
bleue sur l'en-tête, pilule « ▲ Exercice », quai qui dit « ▲ Exercice », bande « Répétition — aucune
trace clinique » avec sa sortie. Un mode « simplifié » entraînerait au mauvais outil.

**Mesuré : le placard coûte 0 px de hauteur** (en-tête 53 px avec et sans hachure, dans les deux
thèmes). C'est la condition qui rend ces annonciations admissibles là où le chrome n'a que 2,1 px de
marge à 320 px.

### Trois annonciations, une règle de priorité

| Mode | Hachure | Pilule | Registre |
|---|---|---|---|
| **Exercice** | bleue | ▲ Exercice | bleu pointillé — **ni rouge ni ambre** : ce n'est pas une alerte |
| **Invité** | bleue | ▪ Suivi | bleu — vous suivez, vous ne conduisez pas |
| **Essai** (auteur) | neutre | ■ Aperçu | MEMO — le bleu est pris par les deux autres |

**L'exercice garde la priorité, et ce n'est pas négociable** : « ceci est une répétition » prime sur
« vous suivez » — le premier protège d'une méprise clinique, le second est une information de rôle
que le quai porte de toute façon.

### Ce qui n'est toujours pas éprouvé

Le partage est **maquetté, pas fonctionnel** : aucun serveur n'a été joint dans tout cet audit.
La jointure, la latence de propagation, le rattrapage de backlog, la passation de la main et la
bascule « continuer seul » restent **non mesurés** — c'est le plus gros angle mort du document, et
il l'est depuis la première page.

---

## III.12 · Les complications — nommées dans le modèle, montrées nulle part

Troisième trou du même genre : `excursions` figurait dans le modèle v4 (§ II.1) et n'apparaissait
**dans aucune maquette** — ni en lecture, ni dans l'éditeur, ni sur grand écran. Implanté et vérifié.

### Le modèle

```jsonc
excursions: [ { "label":"Hyperkaliémie",           "target":"x1" },
              { "label":"Pneumothorax compressif", "target":"x2" },
              { "label":"Anaphylaxie",             "target":"@aide:a1" } ]
```

Les blocs cibles sont **hors séquence** : aucun `next` n'y mène, leur propre `next` est `null`, et
**ils n'entrent pas dans la numérotation du tronc** — numérotés, ils se liraient « l'étape d'après »,
l'exact contraire d'un évènement qui survient à tout moment. La cible peut aussi être **une autre
aide**.

### Le déclencheur : un bouton constant, pas un par évènement

C'est le modèle **QRH** — un index à onglets, pas un bouton de cockpit par urgence. N boutons rouges
qui se ressemblent obligeraient à **lire** chacun sous stress ; un mot constant à position constante
s'apprend. Registre **ALERTE en contour, jamais rempli** : un aplat rouge permanent désensibilise.

**Un défaut mesuré au passage.** J'avais d'abord mis ⚡ dans la rangée de traçabilité, à côté de
⏱ et Journal. À 320 px les trois boutons réclamaient **358 px pour 267 disponibles** : la rangée
enroulait et **le ⚡ tombait sous la zone visible**. Or c'est le seul des trois qui doive être
atteignable **à tout instant**.

**Deux natures, deux rangées** : ⚡ prend sa propre rangée pleine largeur au-dessus ; ⏱ et Journal
restent en dessous. Résultat mesuré à 320 × 640 : ⚡ **visible sans défiler**, une seule ligne ; la
rangée de traçabilité demande **49 px de défilement**. Arbitrage assumé — l'exception passe avant la
traçabilité, qui est fréquente mais jamais urgente.

### L'excursion et le retour

Entrer pose un bandeau — « ⚡ Hyperkaliémie — le parcours est **interrompu**, pas terminé · retour
prévu : Reconnaissance & alerte » — et **« Terminer » disparaît** : le parcours n'est pas fini.
Le bouton rempli devient **« ↩ Reprendre — <bloc> → »**, toujours actif (on reprend quand
l'évènement est maîtrisé, pas quand les cases sont cochées). La reprise crée un **nouveau passage du
bloc interrompu, cases neuves** : après une interruption, on re-vérifie (AC 120-71B). Le journal
enregistre « ⚡ Hyperkaliémie » puis « ↩ reprise », horodatés.

Vérifié dans le prototype : entrée → bandeau + CTA de reprise ; reprise → bandeau retiré, CTA
« Continuer » revenu, deux repères au journal.

### Où elles apparaissent, surface par surface

| Surface | Ce qu'on y voit |
|---|---|
| **AGIR** (cran 1 et 2) | le bouton ⚡ constant, et le bandeau + « ↩ Reprendre » pendant l'excursion |
| **SE REPÉRER** (cran 3) | une section **« ⚡ À tout moment · hors numérotation »**, après le parcours et avant « Surveiller » — vérifié : 3 blocs rendus |
| **CONSULTER** | **rien** — une complication est une **action**, pas une référence |
| **Éditeur** | une carte « ⚡ Complications » (1 à 3), libellé + cible ; et la colonne structure sépare « ⚡ Hors séquence · 2 » du tronc |
| **Grand écran** | la colonne parcours porte la section ⚡ ; l'éditeur porte la carte et la structure séparée |

### Création et modification

Par la **porte « ＋ »** (entrée « ⚡ Complication — à tout moment »), qui crée d'un geste **le bloc
hors séquence et sa déclaration**. Dans l'éditeur : le **libellé** est le *nom de l'évènement*,
discriminant au premier mot — il devient un bouton tapé sous stress, jamais « En cas de survenue
d'un… ». La **cible** se choisit dans le `picker` partagé (blocs de cette aide d'abord, puis les
autres aides). **Le retour ne se déclare pas** : il est automatique, et c'est ce qui fait qu'il n'est
jamais laissé à la mémoire.

---

## III.13 · Grands écrans — mise à jour

[`proto-large.html`](proto-large.html) est réaligné sur les décisions prises depuis :

- **Lecture (écran B)** — la carte du bloc porte désormais la même pile qu'au téléphone :
  « Continuer », puis **⚡ Complication (3)** pleine largeur en contour alerte, puis la rangée
  **⏱ Noter l'heure · Journal**. La colonne parcours reçoit la section **⚡ À tout moment**, et la
  colonne d'état est titrée **« ⇄ 2 participants »** — le partage y vit avec les minuteurs, les
  compteurs et le journal, comme derrière le quai sur téléphone.
- **Éditeur (écran D)** — carte **⚡ Complications** (libellé + cible, 1 à 3), et la colonne structure
  affiche **« 10 + 2 blocs »** avec un groupe **« ⚡ Hors séquence »** distinct du tronc.

Vérifié après mise à jour : **0 texte sous 11 px, 0 écran en débordement, deux thèmes, 0 erreur**.
