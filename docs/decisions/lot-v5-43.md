# Lot v5.43 — le parcours suit l'arbre, borné à deux crans (A450)

> Fichier normatif, suite de [`lot-v5-42.md`](lot-v5-42.md) (A449). Les numéros A sont des adresses : ne jamais
> renuméroter. Signalement de l'auteur du 04/10/2026 (capture à l'appui) ; forme choisie sur canevas (« Revue non
> bloquante », page « Début de branche » : Actuel, A, B, C, puis imbriqué et colonne réelle de 223 px — retenue :
> « C borné à deux retraits »).

## A450 — le parcours suit l'arbre de `flowPlan`, deux crans au plus (v5.43.0, amende A394)

**Le signalement.** Dans la colonne du parcours (cockpit, tablette), l'en-tête « BRANCHE ◇ 4 « Convulsions arrêtées » »
débordait : le texte sortait du fond ambré de sa pastille. Mesuré : la ligne « BRANCHE » + pastille ne laissait que
~110 px à la pastille, qui rétrécissait sous son mot le plus long (« « Convulsions », ~130 px) — 17 px de débordement.
A393 mesurait la BOÎTE contre la colonne, jamais le texte contre la boîte : il restait vert.

**Ce que le correctif a révélé — et les essais refusés.** Trois réponses ont été essayées et refusées par l'auteur avant
de revenir au canevas :
1. la pastille passée SOUS « BRANCHE » quand elle ne tient pas : l'en-tête n'est plus une ligne, la pastille se lit comme
   une rangée de plus ;
2. une carte ambrée « BRANCHE ◇ 2 / réponse » : trop proche des cartes de DÉCISION, l'en-tête se lit comme un bloc ;
3. le losange de la décision posé dans la colonne des numéros, « SI réponse » à côté : le losange répété se lit comme un
   SECOND bloc 2, et la décision dit « → 4 » quand l'en-tête renvoie à 2 — le numéro promis n'est plus celui qu'on lit.

Le canevas a ensuite posé la vraie question : avec des décisions IMBRIQUÉES, la liste à plat d'A394 (« deux colonnes de
numéros au plus, une branche de branche ouvre sa propre branche ») perd la hiérarchie — la branche de ◇8 a le même retrait
que celle de ◇2 dont elle sort, et trois décisions qui répondent « Non » ne se distinguent que par leurs numéros.

**La forme retenue : l'arbre, borné à deux crans.**
- **La liste suit l'arbre que `flowPlan` construisait déjà** (`bropen`/`brclose`, profondeur) et que la colonne aplatissait.
  La numérotation ne bouge PAS : `flowPlan` numérote dans l'ordre même où il parcourt l'arbre (« le tronc d'abord »,
  A344, partagé avec le journal, la Page et le Schéma) — vérifié sur les trois fiches d'exemple et le scénario à quatre
  décisions.
- **Chaque réponse d'une décision ouvre SA branche sous elle**, au même dessin pour toutes : « SI réponse » (mono gris
  puis la réponse à l'ambre des réponses de la carte de décision), sans fond — seule la décision est une carte. Un filet
  part de l'en-tête par un coin arrondi et descend le long de la branche. L'en-tête est un bouton qui mène à la décision.
- **Une branche dans une branche se décale d'un cran de plus, deux crans au plus** (14 px en colonne, 20 ailleurs). Au
  troisième niveau la branche reste au second cran (`.plat`) et son en-tête dit sa décision : « SI Non à ◇11 ». Mesuré à
  223 px avec des libellés longs : 125 px de titre au second cran (111 au troisième sans la borne), hauteur égale à l'arbre
  non borné.
- **Les renvois d'une décision deviennent « ↓ n »** dès que la branche s'ouvre juste dessous (`below`) ; un témoin
  vérifie que chaque « ↓ n » tombe sur le bloc n.
- **Une réponse sans bloc propre n'ouvre pas d'en-tête vide** (retour en boucle, réponse qui rejoint la convergence) : la
  ligne de la décision le dit déjà (« ↺ 2 », « → 7 »). **La convergence** reprend au niveau de la décision, sans en-tête.
- **Une suite rangée ailleurs** (sortie d'une boucle chaînée après le tronc, bloc à plusieurs entrées) garde un en-tête
  explicite : « SI réponse à ◇n », « Suite de n », « Autre entrée ».
- **Le losange d'une décision n'est jamais redessiné dans la colonne des numéros.**

**Purges (règle 14).** L'ancienne pastille `.pf-dec` et l'étiquette « Branche » (`.pf-segl` dans `.pf-br>.pf-seg`) ne sont
plus émises : leurs règles partent. `.pf-seg`/`.pf-segl` restent pour « À tout moment » ; `.pf-src` reste pour
« ← aussi depuis ».

**Témoins.** `audit-doctrine` : « la liste écrit les chemins (décisions imbriquées) » réécrite — chaque branche signée
« SI réponse » par sa décision, trois colonnes de numéros au plus (≥ 12 px par cran), chaque « ↓ n » sur le bloc n, aucune
branche à plat à deux niveaux ; A392/A393 suivent l'en-tête neuf (« SI », jeu de 12 px) ; nouvelle section « A450
au-delà de deux crans » (« à ◇11 », blocs au second cran, numéro de décision unique, aucun débordement). Rejoués sur
l'`index.html` d'avant : huit rouges puis trois, exactement les invariants changés.
