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

---

# Second chapitre — ce qui tenait sur Mac à 0 px près (v5.43.1, A451)

> Question de l'auteur du 05/10/2026 (« pourquoi doctrine 3 et 4 sont en échec, en local et en CI ? ») ; formes
> choisies sur canevas (« Rognages Linux — pistes » : X1-X4 pour la barre à 1200 px, trois libellés à 320 px, E1/E2
> pour l'en-tête — retenues : X3, « 0 coché », E2).

## A451 — case maîtresse, « 0 coché », marque à 17,5 sous 480 px (v5.43.1)

**Le constat.** Deux sections de `audit-doctrine` échouaient en CI depuis la v5.30.0 (la troisième mesure depuis la
v5.36.0), en silence puisque l'audit y est `continue-on-error` : « SÉLECTION · une ligne, 56 px » (compte tronqué à
320 px à zéro coché, et à 1200 px à deux cochés) et « En-tête d'accueil » (réserve < 8 px à 320, 360 et 430 px). Le
numéro de tranche variait d'une passe à l'autre (`AC_PLAN` répartit par durée) ; les sections, jamais.

**La cause — mesurée, pas supposée.** Rejoué dans l'image Playwright officielle (`mcr.microsoft.com/playwright:v1.61.1-noble`,
le Linux de la CI), à l'identique des chiffres du journal CI. Deux effets s'additionnent :
1. **Le texte est plus large sous Linux, police embarquée identique** : Chromium headless Linux arrondit l'avance de
   chaque glyphe au pixel entier (« Aides cognitives » en Manrope 700 16 px : 128,04 px sur Mac, 130 sous Linux ; le
   mot-marque de l'accueil : 161,6 contre 171,8 px).
2. **Une barre de défilement classique prend 15 px** : en voie large la barre de sélection vit dans le défileur
   `.home-main` (889 px au lieu de 904). Sur Mac la barre se superpose.
Sur Mac, ces trois mises en page tenaient à **0 px de jeu** (compte « 2 cochés » 58/58 px à 1200, « Rien de coché »
97/97 à 320, réserve d'en-tête 8 px pile à 360 et 430). **Le cas 1200 px est un vrai défaut**, pas un artefact :
Windows et Linux de bureau ont la barre de défilement classique, donc le compte y était tronqué entre ~1200 et ~1215 px.

**Les corrections.**
- **Case maîtresse à trois états** (`#selAll`, `.dir-ck.sel-ck`) à la place du segment « Tout cocher / Tout décocher »,
  à TOUTES les largeurs : le dessin de la case d'une rangée, cible 40 px, `role="checkbox"`, `aria-checked`
  false · mixed · true lu sur ce que la liste MONTRE (calcul dans `bindSelBar`, avant la peinture — le gabarit ne
  connaît pas la liste). Aucun ou une partie → tout cocher ; tout → tout décocher ; le nom accessible dit le geste.
  Le segment rendait 259 px ; la case 40. Corollaires : la règle `zw400` qui renvoyait le segment au tiroir et la
  face « Tout décocher » rejouée par `openSelActs` sont purgées (la case est toujours là) ; le compte (`flex:1 1 auto`)
  pousse seul les actes au bord.
- **Les actes dépliés portent leur glyphe** (`book`, `tag`, `download`, `trash` — ceux du tiroir) : un dessin, deux lieux.
- **« 0 coché »** au lieu de « Rien de coché » : la forme de « 1 coché », « 2 cochés », seul le chiffre change ; l'encre
  secondaire à zéro est gardée. Mesuré sous Linux : 54 px pour 90 disponibles (« Aucun coché » : 89, 1 px de jeu ;
  « 0 élément » : 68, mais deux vocabulaires pour un même compte).
- **E2 — le mot-marque de l'accueil passe à 17,5 sous 480 px effectifs** (`html.zw480`, palier 480 ajouté à
  `ZOOM_W_STEPS` ; il était déjà dans l'échelle fermée). Réserve mesurée, Linux / Mac : 320 px 33 / 44, 360 px 25 / 36,
  430 px 23 / 36 ; ≥ 480 la marque reprend 21 px (46 / 58 de réserve). « Créer » garde son mot à 430.

**Jeu du compte après correctif, Linux** : ≈ 75 px à 1200 (X3 calculé), 36 px à 320 à zéro coché, ≈ 18 px à 320 à
deux cochés (la case coûte 46 px sur la ligne repliée — mesuré vert).

**Témoins.** « SÉLECTION · A451 case maîtresse » (390 et 1200 px) : état annoncé et nom à chaque pas (vide → mixed →
true → vide), cible 40 px, ce que le geste fait aux rangées, glyphes des actes dépliés. Les sections « SÉLECTION · une
ligne » et « En-tête d'accueil » passent désormais sur les DEUX plateformes (vérifié dans le conteneur Linux).

**Formes écartées.** X1 (une seule bascule, sans glyphes) : juste, mais « Tout cocher » disparaissait dès une coche ;
X2 (glyphes + × seul) : ≈ 24 px de jeu seulement sous Linux ; X4 (actes en glyphes seuls, nom au survol) : pas de survol
au toucher sur une tablette de 1200 px. Palier de dépliage relevé à 1280 (piste A) : non retenu au profit de X3. Forcer
sous Linux un rendu de texte identique au Mac (options de lancement) : refusé comme remède — il cacherait le cas réel de
la barre de défilement classique.
