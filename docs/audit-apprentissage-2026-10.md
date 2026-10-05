# Audit — courbe d'apprentissage d'un nouvel utilisateur (v5.44.0, 05/10/2026)

> **Question posée** : qu'est-ce qui empêche un nouvel arrivant — urgentiste, interne, étudiant,
> infirmier expérimenté ou débutant — de *trouver* les choses, de *comprendre* l'interface et de
> s'en servir *sans formation* ?
>
> **Statut de ce document** : un constat et des propositions. Il ne fait pas doctrine. Toute
> correction retenue passe par une entrée A de son lot, comme d'habitude. Plusieurs propositions
> touchent des décisions déjà prises par l'auteur ; elles sont **signalées comme telles**
> (« ⚖ décision existante ») et ne sont pas présentées comme des défauts.

## Méthode

- **Parcours réel instrumenté** (Playwright, Chromium) depuis un appareil vierge, au même point
  d'entrée que les harnais (`amorce`, `ouvrirFiche`, `demarrerSession`) :
  - bienvenue → exemples → accueil → « Affichage » → « Créer » → Sessions → Compte ;
  - ouverture de « Arrêt cardiaque (ACR) » → menu ⋯ → mode Exercice → démarrage → cochage →
    volet des minuteurs → « Tout voir » → complication → « Horodater » → « Terminer » ;
  - éditeur d'une aide existante, puis d'une aide neuve.
- **Quatre configurations** : téléphone 390 × 844 · bureau 1280 × 800 · téléphone avec texte
  agrandi à 130 % (le cran que choisira un utilisateur presbyte) · thème sombre.
- **Lecture du code** (`index.html`) pour ce que l'écran ne dit pas : la recherche, les états,
  les gestes cachés, l'inventaire du vocabulaire visible (chaînes affichées seulement, sans les
  commentaires). Les numéros de ligne renvoient à `index.html` en v5.44.0.
- **Cinq profils** servent de grille de lecture (§ 1).

Ce qui n'a **pas** été fait : un test avec de vrais utilisateurs, et un passage sur un iPhone
physique. Les constats « mesurés » viennent du banc ; ceux qui dépendent du moteur (césure) sont
signalés.

---

## 0. Synthèse

**Ce qui marche déjà très bien, et qu'il faut garder.**
- La promesse de l'écran de bienvenue est claire : responsabilité du contenu, rien ne sort sans
  compte, et une porte « Découvrir avec 2 exemples ».
- L'écran d'entrée d'une aide se lit en trois chapitres (« Quand l'utiliser », « Ne pas
  oublier », « Parcours »). Le bouton principal dit ce qu'il fait : « Lance le chrono ·
  minuteurs prêts ».
- En session, la hiérarchie de l'étape est lisible. CRITIQUE et VIGILANCE sont écrits en mots ;
  la case occupe toute la rangée, et la progression « 0/12 étapes » est visible.
- Le mode Exercice est très bien signalé une fois activé : bande hachurée, « ▲ EXERCICE »,
  « Quitter l'exercice… ».
- La fenêtre « Terminer la session ? » rappelle l'étape vitale non cochée.
- La recherche ignore les accents et la casse, et tolère les fautes de frappe. Elle cherche
  aussi dans le contenu des étapes et dans les PDF joints, et met les termes trouvés en gras dans
  un extrait.

**Le diagnostic en une phrase.** L'app a été optimisée avec soin pour *quelqu'un qui la connaît
déjà*, sous stress. Le nouvel arrivant, lui, se heurte surtout à trois choses :
1. un **vocabulaire mouvant** : un même objet porte cinq noms, et une même vue trois ;
2. **l'absence de tout lieu où apprendre** : ni aide, ni glossaire, ni moyen de revoir l'accueil ;
3. des **signaux contradictoires sur la fiabilité d'une aide** : « Validée » et « À compléter »
   en même temps, et une aide vide née « Validée ».

### Les 10 priorités

| # | Constat | Gravité | Effort |
|---|---|---|---|
| 1 | Une aide **neuve et vide naît « ✓ Validée · Publiée — utilisable en situation »** | **Haute** (confiance / sécurité) | S |
| 2 | « Validée » + « △ À compléter » + bandeau « validez-les » : **trois messages contradictoires** sur les exemples | Haute | S |
| 3 | **Un objet, cinq noms** : fiche · aide · parcours · protocole · référence | Haute | M |
| 4 | **Une vue, trois noms** et un nom pour trois vues : Tout voir / Toute la fiche / Page / Tableau / Plein écran | Haute | M |
| 5 | **Aucun lieu pour apprendre** : pas d'aide, pas de glossaire, accueil impossible à revoir | Haute | M |
| 6 | **Texte à 130 %** : le titre devient « Arrêt ca… », « Horodate / r », « Tout voir » perd son libellé | Haute pour les profils presbytes | M |
| 7 | **Le champ « Discriminant » n'est pas cherché** (« pédiatrique » ne trouve pas l'aide « … — pédiatrique ») ; aucun champ de mots-clés ni de synonymes | Moyenne | S / M |
| 8 | **Boutons réduits à une icône** sur l'accueil au téléphone (horloge, +, silhouette, filtre) et ◑ en tête de chaque aide | Moyenne | S |
| 9 | **Gestes invisibles** : « Terminer » se *maintient* 1,2 s ; appui long ; poignées ⠿ ; raccourcis clavier jamais listés | Moyenne | S |
| 10 | **Abréviations et jargon visibles** : « Exo. », « Chocs déliv. », « Catég. », « Biblio. », « Discriminant », « Jalons », info-bulle « Do-Verify » en anglais | Moyenne | S |

Effort : S ≤ ½ journée · M ≤ 2 jours · L davantage.

---

## 1. Les cinq profils et ce qui les arrête

| Profil | Ce qu'il veut | Où il bute (constats) |
|---|---|---|
| **Urgentiste qui découvre l'app** (senior, pressé) | Lancer « ACR » en 2 gestes, faire confiance au contenu | Rien n'indique qu'épingler (☆) crée un accès direct (§ 4.3). En tête du mode crise, la touche « FV réfractaire » n'est pas reconnaissable comme une *complication* (§ 6.1). « Validée / À compléter » brouille la confiance (§ 3.2) |
| **Interne** (apprend la logique de l'algorithme) | Comprendre l'arbre, s'entraîner | Cinq façons de « voir l'aide » aux noms qui se recouvrent : Schéma, Tableau, Page, Se repérer, Tout voir (§ 2.2). Le mode Exercice est caché derrière « Exo. » (§ 2.3) |
| **Étudiant en médecine** | Découvrir sans casser, sans risque | Aucun glossaire de *session*, *exercice*, *essai*, *jalon*, *complication*, *revue* (§ 3.1). L'accueil disparaît pour toujours après la première fermeture (§ 3.1) |
| **Infirmier expérimenté**, peu à l'aise avec le numérique, souvent presbyte | Gros caractères, boutons qui disent ce qu'ils font | Le cran 130 % tronque ou casse le chrome de crise (§ 6.3). Boutons-icônes muets (§ 5.1). Il faut maintenir pour terminer (§ 5.2). Les info-bulles n'existent qu'au survol, donc pas au doigt (§ 5.3) |
| **Infirmier débutant** | Savoir quoi faire, ne pas se tromper | Vocabulaire changeant entre accueil, filtre et compte (§ 2.1). « Vérifier » et « Cochez les étapes restantes (4) » côte à côte (§ 6.2). La légende « réponse attendue » n'est pas expliquée (§ 6.2) |

---

## 2. Vocabulaire — le premier frein

### 2.1 Un objet, cinq noms · Haute

Sur le **seul écran d'accueil**, le même objet s'appelle :

| Où | Libellé | Ligne |
|---|---|---|
| Ligne de compte | « **2 parcours** » | 15475 |
| Bandeau après les exemples | « 2 **fiches** d'exemple ajoutées » | 11714 |
| Badge de rangée | « **AIDE** » | 14659 |
| Filtre « Afficher » | « **Aides** » | 26703 |
| Regrouper par type | « **Parcours** » / « Protocoles » | 10761 |
| Champ de recherche | « Rechercher une **aide**, un protocole… » | 8385 |
| Compte | « 2 **aides** · 0 protocole » | 28079 |
| Éditeur, aide neuve | « Nouvelle **fiche** » | 16972 |
| Bouton de l'éditeur | « Supprimer cette **fiche** » | 24833 |
| Fenêtre Créer | « **Aide de crise** » ; onglet « **Aide cognitive** » | 26658, 8614 |

Deux de ces mots ont en plus **un second sens** :
- **« parcours »** désigne aussi la *suite des blocs* à l'intérieur d'une aide (« Parcours ·
  4 blocs », « Recommencer le parcours ») ;
- **« référence »** désigne à la fois un *protocole* (« Chercher dans la référence… », « Aucune
  aide ni référence ») et la *bibliographie* (section « Références »).

Inventaire : environ 126 occurrences visibles de « fiche », 66 de « aide », 13 de « parcours ».

**Recommandation.** Fixer un **lexique fermé de deux noms**, écrit dans `AGENTS.md` comme une
règle, et le faire respecter par un garde-fou statique, sur le modèle de `check-type` (liste de
mots interdits dans les chaînes affichées).
- **Aide** = le parcours à cocher, en session.
- **Protocole** = le texte à lire.

Concrètement : remplacer « fiche » par « aide » dans les chaînes visibles, et remplacer
« 2 parcours » par « 2 aides ». Réserver « parcours » à l'arbre interne d'une aide, et
« Références » à la bibliographie. « Aide de crise » et « Aide cognitive » doivent devenir un
seul terme.

### 2.2 Une vue, plusieurs noms — et un nom, plusieurs vues · Haute

| Ce qu'on voit | Ses noms dans l'app |
|---|---|
| L'aide entière en une page | « **Tout voir** » (quai), « **Toute la fiche** » (réglage), « la fiche entière » / « l'aide entière » (lecteurs d'écran), onglet « **Page** » |
| La même page dans une fenêtre | « **Tableau** » (écran d'entrée), « **Plein écran** » (bouton de la Page) — et la fenêtre se rebaptise « Se repérer » selon la porte (20842) |
| L'organigramme | « **Schéma** » (menu ⋯), « **Algorithme — aperçu automatique** » (éditeur), « vue d'ensemble » (aide) |
| La liste des blocs | « **Se repérer** », « **Parcours** » |
| L'affichage à 2 m | « **Moniteur** » |

À l'inverse :
- **la même icône** (`expand`) sert à « Tout voir », « Moniteur » et « Plein écran » ;
- **« Tableau »** est aussi l'outil d'insertion de tableau Markdown ;
- **« Page »** est aussi le bouton de zoom de la visionneuse PDF ;
- la touche « Tout voir » du quai **change de nom** (« Un bloc ») selon l'état.

**Recommandation.** Un nom par vue, le même partout (bouton, titre de fenêtre, lecteur d'écran),
et une icône par vue. Par exemple : **Bloc par bloc** / **Aide entière** / **Schéma** /
**Plan des blocs** / **Moniteur**. La touche à deux états peut garder son principe (A-doctrine),
mais elle doit dire *où elle mène* sous une forme stable, par exemple « Voir : aide entière » ↔
« Voir : bloc ».

### 2.3 Abréviations et jargon visibles · Moyenne

| Terme | Où | Problème |
|---|---|---|
| « **Exo.** » | Quai, sous 430 px | Le mode le plus utile à l'apprenant est caché derrière une abréviation. Une fois armé, la touche devient « Annuler » pour les lecteurs d'écran seulement : le libellé visible reste « Exo. » (13904, CSS 1772) |
| « **Chocs déliv.** », « CHOCS DE… » | Tuile de compteur | Abrégé d'office (`SHORT_CN = 10`), puis tronqué encore |
| « **Catég.** », « **Biblio.** » | « Regrouper » | Aucun libellé complet nulle part |
| « **Discriminant** » | Éditeur | Terme de statisticien. « Précision (adulte, pédiatrique…) » serait immédiat |
| « **Jalons** » | Rail, éditeur | Jamais défini en lecture |
| « **réponse attendue** » | Légende en police à chasse fixe sous le titre du bloc | Ne dit pas à quoi elle se rapporte (le texte gris sous chaque étape) |
| « **Do-Verify : …** » | Info-bulle de « Vérifier » (20768) | Anglais, jargon aéronautique |
| « **Repères posologiques** » vs « **Doses & seuils** » | Lecture vs palette de l'éditeur (24140) | Deux noms pour la même section ; « Repère » sert aussi au repère horodaté |
| « **★ Mémoire** » vs « **Rappel en mémoire** » | Puce vs interrupteur de l'éditeur (24426 / 24467) | Deux mots pour un réglage |
| « **Confirmé — démarrer l'exercice** » | Bouton du mode Exercice | « Confirmé » n'a pas de sens pour une répétition |

**Recommandation.** Pas d'abréviation inventée dans le chrome :
- « Exo. » devient « Exercice », quitte à passer le libellé sur deux lignes ;
- le compteur garde son nom entier sur deux lignes avant toute coupe.

Les termes de métier qui restent (jalon, revue, complication) doivent renvoyer au glossaire
(§ 3.1).

### 2.4 Verbes · Basse

- Fin de session : « **Fin** » (quai) / « **Terminer la session** » (menu, fenêtre). Garder
  « Terminer » partout ; la place manque peu, et « Fin » se lit comme un état.
- Retrait : Supprimer (~34) / Retirer (~10) / Effacer / Abandonner. C'est cohérent dans
  l'ensemble (*Supprimer* = détruire, *Retirer* = délier), mais la nuance n'est écrite nulle part.
  À consigner dans le lexique.
- Fermeture : « Fermer » (~30) / « Annuler » (~15) dans des fenêtres équivalentes.

---

## 3. Premiers pas, aide et confiance

### 3.1 Aucun lieu pour apprendre · Haute

Constat (lignes 12338-12363 et l'inventaire des chaînes) :
- **L'écran de bienvenue ne revient jamais.** Il se ferme pour toujours au premier tap, y
  compris sur la petite « × » en haut à gauche, et aucune entrée de menu ne le rouvre.
- **Il n'y a** ni « Mode d'emploi », ni « À propos », ni glossaire, ni visite guidée.
- **Ne sont définis nulle part en lecture** : *session* / *exercice* / *essai* (trois façons de
  « dérouler »), *jalon*, *horodater*, *revue*, *complication*, *bibliothèque*.
- Les info-bulles (`title=`, environ 110) **n'existent qu'au survol de la souris**. Sur
  téléphone, qui est la cible principale, elles sont muettes.
- Les fenêtres vides font mieux : `EMPTY_INTRO` (15019) explique « aide cognitive » et
  « protocole ». Mais une bibliothèque qui contient déjà les exemples ne les montre jamais.

**Recommandation** (hors mode crise, pour respecter la règle 11) :
1. **Moi › « Prendre en main »**, une page statique de 10 rangées dépliables. Chaque rangée
   traite un geste (« Démarrer une aide », « S'entraîner sans patient », « Ajouter un
   minuteur »…) avec une capture.
2. **Moi › « Glossaire »** : 16 termes, une ligne chacun. Liste proposée en annexe A.
3. **Moi › « Revoir l'accueil »** : rouvre `#welcomeModal`.
4. Sur l'écran d'entrée d'une aide, **avant la session seulement**, un lien discret
   « Comment ça marche ? » vers la page 1.

Ces contenus parlent **de l'outil, jamais de clinique** : le statut non-dispositif-médical (§ 2
du document de conformité) n'est pas touché.

### 3.2 Des signaux contradictoires sur la fiabilité · Haute

1. **Une aide neuve naît « ✓ Validée »** :
   - `blankFiche()` (10937) ne pose pas d'état ;
   - `migrate` complète tout état manquant par `validated` (11367) ;
   - l'éditeur d'une aide *vide* affiche donc, dès l'ouverture, « ✓ Validée — Publiée —
     utilisable en situation ».

   C'est l'inverse de ce qu'attendent un débutant et un relecteur.
   ⚖ *Décision existante* : A304 note « une entité neuve naît `validated`, donc publiée
   aussitôt », et la création est *annoncée*. La proposition reste de faire **naître une aide
   neuve en « Brouillon »**, en gardant `validated` comme valeur de repli de `migrate` pour les
   imports anciens (qui ne doivent pas changer d'état). Une telle aide ne serait pas épinglable,
   puisque les brouillons ne le sont pas (10680) : c'est cohérent.
2. **Les deux exemples affichent en même temps trois messages** :
   - « Validée » dans l'éditeur ;
   - « △ À compléter » sur l'accueil ;
   - le bandeau « Relisez-les et validez-les ».

   Le badge est *calculé* (`completionSpots` cherche « à compléter » dans les sources), l'état
   est *choisi* : l'app ne dit nulle part que ce sont deux choses différentes. Sur l'accueil,
   l'explication est une info-bulle au survol, sans `data-todo` : un tap au doigt ne dit rien
   (15002).

   **Recommandation** :
   - livrer les exemples en « **À relire** » ;
   - rendre le badge de l'accueil tappable, comme celui de l'écran d'entrée, qui ouvre déjà une
     notice (25280) ;
   - nommer le badge par ce qu'il demande : « △ 1 champ à compléter : Références ».

### 3.3 Écran de bienvenue · Basse

- La « × » de fermeture est la porte la plus petite. Elle est aussi la seule qui ne laisse rien
  derrière elle : ni exemples, ni aide créée. Une rangée « Plus tard » serait plus honnête.
- « Les bons gestes, cochés au bon moment » est une bonne promesse. Il manque une phrase sur la
  différence entre les deux objets (§ 2.1) : *« Une aide se coche en situation ; un protocole
  se relit. »*

---

## 4. Trouver

### 4.1 Recherche · Moyenne

Ce qui est bien (10416-10522) :
- les accents et la casse sont ignorés ;
- tous les termes doivent être présents (ET) ;
- la correction orthographique bornée s'annonce : « affiché : « … » » ;
- un extrait montre les termes en gras ;
- les PDF joints sont cherchés, avec leurs pages.

Manques :
- **Le discriminant n'est pas cherché.** `ficheHaystack` (10427) prend le titre, le code, le
  contexte local, les listes, les blocs et la catégorie, mais pas `discriminant`. Taper
  « pédiatrique » ne trouve donc pas « Anaphylaxie — pédiatrique ». *Correctif d'une ligne,
  avec un test dans `tests.html`.*
- **Aucun champ de mots-clés ni de synonymes.** « AC », « arrêt », « RCP », « massage »,
  « choc » ne trouvent l'aide ACR que si le texte les contient. Pour un interne ou un étudiant,
  le *mot qui lui vient* n'est pas celui de l'auteur. Proposition : un champ facultatif
  « **Autres noms** » (ajout de champ, donc libre au sens de la règle 12), cherché et affiché
  dans l'extrait. Les tables `POSO_SYN` (11212) montrent que le patron existe déjà.
- **Entrée ne fait rien** dans `#q`. Au clavier, ouvrir le premier résultat sur Entrée est le
  geste attendu.
- Le raccourci « / » ou ⌘K n'est affiché qu'en largeur bureau.

### 4.2 Accès en peu de gestes · Moyenne

- **Épingler fonctionne** : l'étoile ☆ crée une tuile « Accès direct » en tête de l'accueil.
  Mais rien ne dit ce que fait l'étoile. Au téléphone, c'est une icône sans libellé, et la tuile
  n'apparaît qu'après coup.
  Proposition : à la première ouverture d'une aide, une ligne sur l'écran d'entrée,
  « ☆ Épinglez-la pour la retrouver en tête de l'accueil ». C'est hors mode crise, donc admis.
- **Aucune liste « Récents »** : le tri « Plus récentes » trie par *date de validation*, pas
  par ouverture. La fréquence d'usage (`frecencyScore`) existe, mais ne sert qu'à la recherche
  (10771).
- **Aucun lien direct vers une aide** (pas de `#a=<id>`), et **aucun raccourci d'app dans le
  manifeste** (`shortcuts`). Sur Android, un appui long sur l'icône pourrait proposer les
  épinglées. Sur iOS, un lien direct permettrait un raccourci sur l'écran d'accueil.

### 4.3 Accueil au téléphone · Moyenne

- **Trois boutons-icônes en tête** (horloge = Sessions, + = Créer, silhouette = Moi) et un
  **filtre-icône** en bas, sans un mot. Au bureau, la colonne gauche dit « Aides · Sessions ·
  Moi » en toutes lettres : *le téléphone, qui est la cible principale, est le seul à ne pas le
  dire*.
- « Sélectionner » est un bouton texte de même poids qu'un geste rare. « Affichage » est caché
  derrière l'icône de filtre, alors qu'au bureau c'est un bouton nommé.

**Recommandation.** Un libellé de 11-12 px sous chaque icône de l'en-tête au téléphone. La
hauteur se prend sur l'en-tête, pas sur le contenu.

---

## 5. Gestes et commandes invisibles

### 5.1 Boutons réduits à une icône · Moyenne

| Bouton | Ce qu'il fait | Où |
|---|---|---|
| ◑ `#hdrTheme` | Fait défiler le thème : Auto → Clair → Sombre | En tête de **chaque aide**, à la place la plus en vue, pour un réglage rare. Il ressemble à un bouton de contraste |
| ▶ `#hdrPreview` | « Essayer » le brouillon | Éditeur au téléphone : l'icône seule évoque « lecture » |
| ⋯ `#hdrMore` | Toutes les actions de l'aide (Modifier, Partager, Exercice, Exporter…) | Rien n'indique que « Modifier » est là |

**Recommandation.**
- Sortir ◑ de l'en-tête de lecture. Le thème est déjà réglable dans Moi › Affichage ; si un
  accès rapide nocturne est voulu, le mettre dans ⋯.
- Au téléphone, écrire « Essayer » à côté de ▶.

### 5.2 Gestes à maintenir et appuis longs · Moyenne

- **« Terminer » se maintient 1,2 s** (13600). Le texte « Maintenir 1,2 s. Relâcher annule. »
  est sous les boutons, mais le bouton lui-même dit « Terminer ». Un premier tap ne fait rien en
  apparence. *Le principe est juste* (protection contre la fin accidentelle) ; ce qui manque,
  c'est que le **bouton** l'écrive : « Maintenir pour terminer », avec la jauge déjà dessinée au
  repos.
- La **remise à zéro d'un minuteur** se maintient 0,8 s. C'est annoncé par « MAINTENIR » sous
  la valeur, en petites capitales : à garder, c'est le bon modèle.
- **Appui long sur une rangée** de l'accueil = sélection : rien ne l'annonce. Ce n'est pas
  grave, puisque « Sélectionner » existe.
- **Poignées ⠿** de l'éditeur : « touchez, puis touchez la destination » n'est dit qu'au
  survol de la souris.

### 5.3 Raccourcis clavier · Basse

« / », ⌘K, ⌘Z, ⌘B/I/K, Entrée, Échap, les flèches : aucun n'est listé. Une feuille « ? »
(raccourcis), au bureau seulement, coûte peu et sert l'urgentiste au poste fixe.

---

## 6. Le mode crise vu par un débutant

*La règle 11 interdit toute aide intrusive en session. Les propositions ci-dessous ne touchent
donc qu'au **libellé** et à la **forme** de ce qui est déjà là.*

### 6.1 Le quai · Moyenne

Le quai de session affiche : **Fin · Tout voir · FV réfractaire · Horodater**.
- La troisième touche porte **le nom de la complication de l'aide** (« FV réfractaire », éclair
  ⚡). Un nouvel arrivant ne sait pas que c'est la porte des *complications*, ni qu'elle change
  d'une aide à l'autre. Proposition : une sur-ligne fixe « Complication » au-dessus du nom,
  comme pour « Horodater · 1 ».
- « Horodater » : le verbe est juste. Après le tap, la feuille « REPÈRE POSÉ · 00:03 ✓ au
  journal » est claire.

### 6.2 La carte du bloc courant · Moyenne

- Deux boutons en pied : « **Vérifier** » et « **Cochez les étapes restantes (4)** ». Le second
  est un *état* présenté comme un *bouton* gris. Le premier ne dit pas ce qu'il vérifie (sa seule
  explication est une info-bulle en anglais, « Do-Verify »). Proposition :
  - « Relire le bloc » pour le premier ;
  - « 4 étapes à cocher » en texte, non boutonné, pour le second, jusqu'à ce qu'il devienne
    « Continuer → ».
- La légende « **réponse attendue** », en police à chasse fixe sous le titre, flotte sans
  rattachement. Proposition : la supprimer en session et laisser la pilule de l'étape parler.
  C'est déjà le cas sous 360 px (CSS 5439).
- La pilule « **Fait · diagnostic c…** » à côté de PARCOURS est tronquée à 390 px, et son sens
  (l'historique des décisions) n'est pas devinable.
- **Titre du bloc coupé au milieu d'un mot** à 390 px : « Reconnaissan / ce & alerte ». La
  colonne du titre ne fait que 155 px, car la pastille « EN COURS » en prend une partie. La
  césure `hyphens:auto` dépend du dictionnaire du moteur : sans dictionnaire (Chromium Linux
  mesuré), la coupe se fait sans trait d'union. *À vérifier sur iPhone* ; dans tous les cas,
  passer « EN COURS » sous le titre libérerait la largeur.

### 6.3 Texte agrandi à 130 % · Haute pour les profils presbytes

Mesuré au téléphone (390 px, cran 130 %, session ACR) :
- titre de l'aide : « **Arrêt ca…** » ; catégorie : « **S…** » ;
- compteur : « **CHOCS …** » ; résumé : « **2 minute…** » ;
- quai : « **Horodate / r** » (coupe au milieu du mot), « **FV réfracta…** », et « Tout voir »
  **perd son libellé** (icône seule) ;
- titre du bloc sur trois lignes : « Reconnaiss / ance & / alerte ».

C'est précisément le réglage que choisira l'infirmier expérimenté, et c'est celui où le chrome
de crise devient le moins lisible. Les paliers `zw` (règle 10) compressent bien la *mise en
page*, mais pas les *libellés*.

**Recommandation.** À 115 % et 130 %, au téléphone :
- le quai passe ses libellés sur deux lignes au lieu de les tronquer ;
- le titre de l'aide perd le sur-titre (catégorie) avant de se couper ;
- le compteur affiche son nom sur deux lignes.

Ajouter cette configuration à `audit-a11y` : aucune troncature `text-overflow` sur une touche
du quai à 130 %.

### 6.4 « Tout voir » au téléphone · Moyenne · ⚖ décision existante

La page « Tout voir » est une colonne A4 (740 px). À 390 px, le texte est coupé à droite
(« 1 mg, puis / 3–5 min », « FV RÉFRACT… ») et il faut défiler horizontalement. A279 a refusé
l'ajustement d'office et choisi d'*annoncer* le débordement.

Pour un débutant, c'est la vue « tout comprendre », et c'est la moins lisible au téléphone.
Proposition à arbitrer : au téléphone, faire mener « Tout voir » à la liste « Se repérer »
dépliée, qui est déjà un parcours lisible à 390 px. La Page A4 resterait accessible par
« Tableau ».

---

## 7. L'éditeur

- **Au téléphone, l'éditeur d'une aide est une page de 7 600 px** : identité, rappels, critères,
  blocs, minuteurs, compteurs, complications, repères, références. Le dépliant « Structure »
  aide. Proposition : replier **Identité** d'office dès qu'un titre existe, et ouvrir sur le
  premier bloc.
- **« Discriminant »** (§ 2.3) et **« Code »** : les aides de saisie sont bonnes (« deux ou
  trois mots… »), mais le libellé devrait se suffire à lui-même.
- **La pilule « Ajouter · bloc · minuteur · dose… »** est claire et bien placée (A441/A446).
- **« Réglages » d'une étape** (importance, ce que fait la coche, moment) : bonne idée
  (A383), mais trois notions avancées (*la coche lance un minuteur*, *la coche compte*,
  *à partir du n-ième passage*) sans exemple. Proposition : une phrase-exemple sous chaque
  section (« ex. : cocher “Adrénaline” relance le minuteur de 4 min »).
- **« Rédiger avec l'IA à partir d'un document »** est une excellente porte pour un nouvel
  utilisateur. Elle est en troisième position, en texte, sous les deux grandes cartes de
  « Créer ». Pour un débutant qui a déjà un protocole de service en PDF, c'est le chemin le plus
  court.

---

## 8. Plan d'action proposé

### Gains rapides (≤ ½ journée chacun, sans toucher la doctrine)

> **Suivi (v5.45.0, A460)** : les points 1, 2, 4 à 10 sont faits ; le point 3 est fait pour « Exo. »,
> et reporté pour le nom du compteur dans la capsule (la place manque à 64 px — décision de dessin).
> Détail et mesures : [`docs/decisions/lot-v5-45.md`](decisions/lot-v5-45.md).

1. `discriminant` dans `ficheHaystack`, avec un test.
2. Entrée dans `#q` ouvre le premier résultat.
3. « Exo. » devient « Exercice » ; « Chocs déliv. » passe sur deux lignes au lieu d'être abrégé.
4. « Catég. » et « Biblio. » écrits en entier, ou « Catégorie » / « Bibliothèque » sur deux
   lignes.
5. Info-bulle « Do-Verify » traduite et réécrite pour l'utilisateur.
6. Bouton de la fenêtre de fin : « Maintenir pour terminer ».
7. « Confirmé — démarrer l'exercice » devient « Démarrer l'exercice ».
8. Badge « À compléter » tappable sur l'accueil (`data-todo`), avec le champ manquant en clair.
9. Exemples livrés en « À relire », cohérents avec le bandeau.
10. « Moi › Revoir l'accueil ».

### Moyen terme (≤ 2 jours chacun)

11. **Lexique fermé** (aide / protocole) appliqué aux chaînes visibles, avec un garde-fou
    `check-lexique.mjs` qui refuse « fiche » dans une chaîne affichée.
12. **Un nom et une icône par vue** (§ 2.2).
13. **Libellés sous les icônes** de l'en-tête au téléphone ; ◑ sort de l'en-tête de lecture.
14. **Texte 130 %** : libellés du quai et du compteur sur deux lignes, et une sonde dans
    `audit-a11y`.
15. **Page « Prendre en main » + glossaire** dans Moi.
16. **Aide neuve en Brouillon** (⚖ amende A304).

### Structurant (à arbitrer)

17. Champ « **Autres noms** » (synonymes) cherché par l'accueil.
18. **Lien direct vers une aide** + `shortcuts` du manifeste vers les épinglées.
19. « Tout voir » au téléphone : liste lisible plutôt que page A4 (⚖ A279).
20. Un **exercice guidé** pour l'apprenant : sur une aide d'exemple, en mode Exercice
    uniquement, des bulles sur place (« ici, cochez », « ici, la complication »). Il est
    compatible avec la règle 11, puisque ce n'est pas une session réelle, et il fait du mode
    Exercice la porte d'apprentissage qu'il est presque déjà.

---

## Annexe A — Glossaire proposé (une ligne par terme)

| Terme | Définition proposée |
|---|---|
| Aide | Un parcours à cocher, bloc par bloc, en situation réelle ou en exercice. |
| Protocole | Un texte de référence à lire : posologies, procédures, consignes. Ne se coche pas. |
| Bibliothèque | Un ensemble d'aides et de protocoles, personnel ou partagé avec une équipe. |
| Catégorie | Le rangement d'une aide (SMUR, Urgences…), avec sa couleur. |
| Session | Le déroulé réel d'une aide : chrono, minuteurs, coches horodatées, compte-rendu. |
| Exercice | Une session de répétition, sans patient, marquée comme telle partout. |
| Essayer | Dérouler une aide en cours d'écriture, depuis l'éditeur. Rien n'est enregistré. |
| Bloc | Une étape du parcours : une liste d'actions à cocher. |
| Décision | Un bloc qui pose une question et ouvre une branche selon la réponse. |
| Complication | Un bloc à ouvrir à tout moment, hors de la suite normale (⚡). |
| Revue | Une liste à relire à tout moment (hypothèses, vérifications). |
| Jalon | Un seuil de compteur qui fait apparaître une consigne (« Chocs ≥ 3 : … »). |
| Horodater | Noter l'heure d'un geste, puis le nommer. Il entre au journal. |
| CRITIQUE / VIGILANCE | Ce qui tue si on l'oublie / là où l'on risque de se tromper. |
| Vérifier | Relire le bloc à deux : l'un lit, l'autre confirme. |
| Repères posologiques | Les doses et seuils à consulter pendant l'aide, sans les cocher. |

## Annexe B — Écrans parcourus

Téléphone 390 × 844 : bienvenue · accueil · Affichage · Créer · Sessions · Compte · écran
d'entrée ACR · menu ⋯ (avant et pendant la session) · Exercice armé · session · étape cochée ·
volet des minuteurs · Tout voir · complication · Horodater · Terminer · éditeur (aide existante
et aide neuve). Les mêmes en 130 % et en sombre pour la session et l'accueil.

Bureau 1280 × 800 : accueil · écran d'entrée · session (rail) · éditeur avec schéma.

Les captures ne sont pas versionnées : elles se reproduisent en quelques secondes avec
`amorce` / `ouvrirFiche` / `demarrerSession` de `scripts/harness.mjs`.
