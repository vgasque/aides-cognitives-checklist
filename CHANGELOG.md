# Journal des modifications

## [5.19.6] — 2026-08-31
### L'anneau de focus repris par un `#id` : une propriété corrigée, deux trous fermés (A285)

- **Un `#id` reprenait EN SILENCE la respiration d'A268** (A285, signalé sur capture : « la
  bordure du bouton *Tout* est toujours coupée par la fenêtre »). La feuille de filtres portait
  depuis la v5.6 `#filtSheetBody{padding:0 0 4px}` : un `#id` l'emporte sur `.ai-card>.ai-body`,
  et le RACCOURCI `padding` remettait l'axe inline à zéro — en laissant vivre la marge négative,
  qui dès lors ne compensait plus rien. Résultat PIRE que l'état d'avant A268 : chips 4 px à
  gauche du titre, pile sur la découpe, anneau de focus rasé. Mesuré : garde gauche 0 px pour
  « Tout », « Toutes » et « Gérer », contre 3,9 px dans les seize autres corps de fenêtre.
  Correctif d'une propriété : `padding-block:0 4px` — on n'écrit que l'axe qu'on règle, l'axe
  inline reste à la règle commune ; effet second voulu, les chips s'alignent enfin sur le titre.
- **Le trou de cascade se ferme en garde-fou** : `check-ring.mjs` (dans `npm run check`, donc en
  CI) lit les corps de fenêtre dans la coque — jamais une liste tenue à la main — et refuse toute
  règle qui les CIBLE par leur `#id` en posant une respiration inline < 4 px (les règles visant
  un DESCENDANT ne sont pas concernées). Né ROUGE sur l'état d'avant correctif.
- **Le trou de couverture aussi** : la feuille de filtres n'était ouverte par AUCUNE des
  vingt-cinq surfaces d'`audit-a11y` — c'est ce qui a laissé sept mois au défaut. Elle entre au
  balayage par son VRAI point d'entrée (`#filtTog`, qui n'existe que pendant une recherche) :
  conforme aux deux thèmes du premier coup. Leçon v4.75.0 redite au prix fort : un défaut hors
  périmètre n'est pas un défaut absent.

## [5.19.5] — 2026-08-31
### Les mineurs de l'audit : la rangée d'éditeur suit la largeur effective, la doctrine se navigue (A284)

- **La chaîne de compression de la rangée d'éditeur (640→430→360) passe aux paliers `zw`**
  (A284). Mesuré sous zoom texte 130 % : la recette anti-chevauchement des halos ne
  s'appliquait pas à largeur EFFECTIVE < 430 (le tap partait au dernier élément du DOM) et
  « Aperçu » restait en toutes lettres là où l'icône s'imposait. Équivalence exacte à zoom 1
  prouvée aux quatre témoins (620/420/350/700 px), deux moteurs — et le piège de mesure A267
  évité en route (un « débordement de 161 px » qui n'était qu'un artefact de repère visuel).
  Les quatre paliers de composition restants ne se convertissent pas d'office : arbitrage
  écrit dans A284.
- **`Share` et `Sync` se naviguent** : quatorze sous-bannières `/* ===== … ===== */` aux
  frontières logiques des deux modules (cadence, PULL, PUSH, annexes ; horloge, émission,
  cycle, application, gestes hôte/invité, passation, fins) — la commande d'index du
  monofichier les liste désormais. Aucun code déplacé.
- **`GUIDELINES.md` relu** (il l'exigeait lui-même) : les principes tiennent, une note datée
  renvoie les quatre surfaces refondues (accueil v5.18, colonne/pied v5.19, barres v5.15,
  sélection v5.17) vers leurs lots ; `design/README` corrige ses fiches « ~275 Ko » (réel :
  ~815) et consigne les deux `git gc`.

## [5.19.4] — 2026-08-31
### Phase 3 de l'audit : trois garde-fous nouveaux, le pli QR assaini, cinq duplications factorisées (A283)

- **Trois trous de l'audit fermés en garde-fous**, chacun né ROUGE sur défaut fabriqué puis
  restauré à l'octet : `check-tokens` (token CSS déclaré ↔ lu, le trou du survol `--hover`),
  `check-ids` sens inverse (sélecteur `#id` stylé → émis, le trou de `#f-validation`),
  `check-fns` (déclaration top-niveau → citée ailleurs, le trou de `catsUtiles`). Les
  commentaires sont dépouillés d'abord (`strip-comments.mjs`, source unique) — un nom cité
  dans la doctrine n'est pas un usage. **`check-fns` a attrapé un 4ᵉ mort dès sa naissance**
  (`enLigneOk`, locale jamais lue), supprimé.
- **Le pli reçu par QR passe par `slFoldSan`** — c'était le seul intrant distant pris brut :
  grammaires du chemin en ligne (shareNavNorm, vfMapNorm, tkRefNorm), bornes de
  sanitizeSession, liste fermée (un miroir ne réécrit rien), témoin dans tests.html (+7
  assertions, aucun label d'évènement ne traverse — règle 15). `ltSnapUnpack` décompresse
  borné à 4 Mo (le flux s'annule, comme `inflateBounded`).
- **Durcissements** : la purge des caches du SW se limite au préfixe `aides-cognitives-`
  (l'origine n'est pas le scope — un déploiement intranet en sous-répertoire n'effacera pas
  les PWA voisines) ; `esc()` rejoint les six sites d'id qui y avaient échappé (couverts par
  safeId en amont, mais la règle v5.10.2 « échapper au site » y était cassée).
- **Cinq duplications factorisées, comportement identique** : renommage inline
  minuteur/compteur (jumeaux), `selBounds` (×3), `slBusySheet` (refus « partage déjà actif »
  ×2), `attInfoFor` (×2), `ovNavPush`/`ovNavDone` (queue de navigation ×2).
- **Piège découvert et fermé en route** : deux commentaires JS citent `<style>` sans
  fermeture — sur le fichier brut, ils s'appariaient de travers avec tout bloc ajouté plus
  bas ; l'appariement des blocs se fait désormais commentaires retirés.
- Les cinq fonctions de test embarquées et les deux surfaces de harnais portent leur marqueur
  « délibéré » (décision Q3) — un futur audit ne les re-signalera pas.

## [5.19.3] — 2026-08-31
### Audit interne complet : le survol qui ne peignait rien, le code mort purgé, la doctrine qui dit vrai (A280-A282)

Audit transverse en quatre passes (code mort, PWA/performance, sécurité, outillage), chaque
constat contre-vérifié, cinq arbitrages posés à l'auteur avant le premier geste. Verdict
d'ensemble : aucune XSS atteignable, aucun secret exposé, RLS et `search_path` corrects sur les
24 fonctions `SECURITY DEFINER`, une seule vraie duplication de bloc dans 1,97 Mo de JS. Les
correctifs, sans changer un seul comportement voulu :

- **Deux survols inertes réparés (A280)** : `.rt-lnk` (sommaire d'une référence) et `.at-b`
  (onglets) lisaient `var(--hover)` — un token JAMAIS déclaré, déclaration invalide au calcul,
  survol qui ne peignait rien dans les deux thèmes. Peints avec la famille vivante (`--amb-2`
  le jour ; `--hover-dk` la nuit, `-hi` sur surface élevée), prouvé à la sonde : fond calculé
  non transparent au survol réel, 2 thèmes × 2 moteurs, 8/8.
- **Code mort purgé (règle 14, zéro émission vérifiée au grep)** : `catsUtiles` +
  `catNbSousFiltre` (remplacées par l'union v5.18, jamais purgées), `filtersActive`,
  `_ROLE_LBL` ; six tokens déclarés-jamais-lus (`--w-max`, `--g-cmd`, `--hit-crisis`,
  `--dur-1`, `--primary-300` ×2, `--shadow-dock`) ; deux sélecteurs `#id` orphelins
  (`#f-validation.val-bad`, `#readTopSeg` dans `@media print` — purge v5.6 enfin achevée).
- **Le palier 1200 n'a plus qu'UNE copie** : le bloc d'origine (§ LARGEURS) avait été réaffirmé
  plus bas pour gagner la cascade, puis les deux copies ont divergé en silence (`.ed-cockpit`
  240 ici, 220 là — la cascade tranchait pour 220, la copie d'origine était morte avec un
  commentaire annonçant 220 au-dessus d'une ligne écrivant 240). Le bloc mort est purgé, 220
  confirmé par l'auteur, la doctrine « pour une géométrie, ne jamais dépendre de l'ordre »
  déménagée sur la copie vivante.
- **Quatre commentaires qui mentaient corrigés** : `fitCtrlRow()` décrite au présent
  (supprimée en v5.6, son épitaphe existait 21 000 lignes plus loin), `--primary-300`
  documentée en service, « structure 220 » sur la ligne à 240, et `_headers` qui justifiait
  `no-cache` par une stratégie « réseau d'abord » révolue depuis v4.4.6.
- **La règle des 20 du CHANGELOG devient exécutoire (A281)** : `scripts/check-changelog.mjs`
  (dans `npm run check`, donc CI) — compte ≤ 20 et aucune entrée en double avec une archive.
  Né ROUGE sur l'état réel à 21 entrées, vert après archivage de [5.14.21] puis [5.14.22]
  (en FIN d'archive, convention constatée et désormais écrite). L'alias `npm run ci`, jamais
  appelé et divergent du workflow, est retiré.
- **Le périmètre de déploiement est tranché (A282, décision utilisateur)** : le dépôt est servi
  EN ENTIER — et ce qui ne doit pas être public SORT du dépôt : `sonde/index.html` (313 Ko de
  sonde WebRTC d'un spike clos v5.14, jumelle à l'octet d'un fichier délibérément gitignoré,
  publiée à `/sonde/` faute d'index) est supprimée.
- **La doctrine devient navigable par toute IA** : `docs/README.md` créé (carte plage A-xxx →
  fichier, sans passer par AGENTS.md) ; l'index d'AGENTS.md corrigé — le lot v5.13 (A192-A197,
  second chapitre de `lot-v5-12.md`) n'était indexé NULLE PART, trois plages annoncées étaient
  fausses (v5.12 « A170-A179 » pour A170-A197, v5.17 « A227-A230 » pour A227-A237, v5.18
  « A238-A261 » pour A238-A268) ; README remis d'aplomb (« onze harnais » → 21, hébergement
  Workers Assets + adresse de production, contenu du dépôt complété).
- **Écarté en connaissance de cause** : pas de `Cache-Control: immutable` sur `vendor/` —
  les fichiers n'y sont pas nommés par hash, un an d'immutabilité HTTP ferait servir un vieux
  pdf.js après une mise à jour de sécurité (le piège v5.0.0 « la mise à jour qui n'atteint
  personne », au niveau HTTP) ; et pas de re-fusion des `.md`, qui recréerait la troncature
  silencieuse à 797 Ko documentée en v5.10.3.

## [5.19.2] — 2026-08-31
### Le halo de cible se vérifie en capture, la feuille qui dépasse le dit (A278-A279)

Second volet de l'audit design v5.19 — publié avec la 5.19.1 (fusionnée ici), les deux
corrigent les quatre défauts réels que l'audit a mesurés sur l'app servie.

- **« filtres : aides » était une cible de 72×18 px, sous les 24 de WCAG 2.5.8 (A278).** Sa
  conformité reposait sur un halo `::after` de −8 px — rogné par la chaîne d'ancêtres en
  `overflow:hidden` qui ellipse les longs résumés : mesuré à l'`elementFromPoint`, un tap à
  5 px du rectangle atteignait `.dir-wrap`, jamais le bouton. Le dessin porte désormais
  lui-même les 24 px (`.dir-hf` en inline-flex, `min-height:24px` — la rangée absorbe les
  ~6 px), le halo ne restant qu'en bonus là où le clip le laisse vivre.
- **Le trou du garde-fou, plus grave que le défaut : `audit-a11y` créditait les halos SANS
  vérifier la capture.** La sonde cibles lisait les insets du `::after` et comptait la
  surface — tout halo rogné par un clip passait vert (famille v4.31.1 : un contrôle aveugle
  au défaut qu'il couvre ne prouve rien). Elle teste désormais la CAPTURE : pour tout élément
  dont la conformité repose sur le halo, `elementFromPoint` au milieu de chaque côté à halo
  non nul doit rendre l'élément — sinon « halo rogné, capture perdue ». Deux garde-fous
  appris à la première passe : garde d'occlusion (le centre inatteignable — fenêtre ouverte
  par-dessus — n'est pas un halo rogné : la sonde rougissait sur le chrome DERRIÈRE la
  feuille Plan), et abstention hors fenêtre. Plus une surface d'état nouvelle, « filtres
  posés » : le déclencheur n'existe qu'avec un filtre actif et ne vivait dans AUCUNE surface
  mesurée (un défaut hors scope n'est pas un défaut absent, v4.75.0). Preuve rouge→vert :
  sonde ajoutée AVANT le correctif, passe rouge sur le seul témoin visé, puis verte.
- **La Page SFAR annonce son débordement horizontal (A279).** Mesuré : 904 px visibles pour
  1131 de feuille à 1280 — la colonne « NE PAS OUBLIER » coupée en plein mot, et les barres
  de défilement en incrustation ne laissent aucun indice tant qu'on ne défile pas.
  L'ajustement d'office reste REFUSÉ (k ≈ 0,28 à 390 px tuerait toute cible — cf. `svZoom`
  et l'épitaphe `.pg-wide`) : ce qui manquait, c'est que la coupe se DISE. Un mot en encre
  seconde dans la barre d'échelle — « la feuille dépasse à droite — défiler, ou “⤢ Ajusté” » —
  posé/levé par `svApplyZoom` sur la mesure réelle du défileur, dans les deux logements de la
  feuille. Vérifié aux trois états : annoncé à l'ouverture, tu après « Ajusté » (80 %), de
  retour à 1:1.
- **Les trois autres signalements de l'audit, vérifiés puis classés** : la bascule de thème
  « lente » était un artefact de mesure (pane masqué au rendu étranglé — le thème s'applique
  en synchrone, aucune transition couleur > 0,3 s ; corriger au symptôme aurait été le piège
  A267) ; la troncature des titres du rail est un arbitrage écrit (« un titre ellipsé se
  devine, un renvoi tronqué ne se répare pas ») ; le bandeau auteur est déjà conditionnel
  (un seul créneau avec le bandeau système, fermeture définitive mémorisée).

## [5.19.1] — 2026-08-31
### La pile du quai se purge à toute fermeture, et une seule primaire verte (A277)

- **Le bug, mesuré à l'audit design v5.19** (desktop 1280, session vive) : Tout voir →
  Consulter → retour par « Un bloc » laissait le quai en « Revenir au bloc en cours » vert
  plein alors qu'on était déjà sur le bloc — il masquait la commande Consulter, et un tap le
  dissipait sans autre effet. La cause est une asymétrie de logement : à ≥ 1200 px la
  consultation vit en colonne DANS `main` (A15), que le rendu complet du retour d'excursion
  venait de détruire — mais son état (`body.ref-col-on`, le `dp-back` de `#refBtn`) vit HORS
  de `main` et survivait.
- **Réconciliation à chaque `render()`** : si l'état dit « colonne ouverte » mais qu'aucune
  `.ref-col` n'existe plus dans le DOM, la fermeture passe par `closeRefSheet()` — la porte
  unique, quelle que soit la porte de SORTIE. Sémantique de pile : dépiler un niveau du
  dessous emporte ce qui était posé dessus. Le même filet couvre le trou voisin jamais
  signalé : franchir le palier 1200 vers le bas avec la colonne ouverte la tuait de la même
  façon. (La feuille `#refModal` des voies étroites vit hors de `main` et survit à bon
  droit — rien à réconcilier.)
- **Une seule primaire verte — le sommet de pile.** SFAR + Consulter ouverts montraient DEUX
  vertes côte à côte (« Un bloc » + « Revenir ») : deux référents pour un même signe
  (AC 120-71B § 5.5). Quand Consulter est ouvert par-dessus, c'est lui le sommet : « Un
  bloc » garde libellé et geste mais rend le vert, et le reprend à la fermeture de la
  consultation. Écrit aux deux points qui peignent ces boutons (`applyViewChrome`,
  `syncRefBtn`).
- **Témoin de non-régression** : `audit-retour.mjs`, section « pile du QUAI » — cinq mesures
  (une seule verte à chaque étage, purge complète après la séquence croisée, re-tap qui
  rouvre une vraie consultation, vert qui redescend), vérifiées capables d'échouer contre
  l'`index.html` d'avant le correctif (3 rouges montrant les symptômes exacts), fichier
  restauré à l'octet.

## [5.19.0] — 2026-08-30
### La colonne gauche a trois étages, le pied ne dit plus deux fois la même chose (A269-A276)

- **Mesuré avant de décider** (iPad 11″ paysage, 1194 × 834 → 774 px utiles) : avec 3
  bibliothèques et 5 catégories, la colonne demandait **777 px**. Elle défilait d'un bloc, pied
  compris — le ✓ « contenu trouvable par la recherche » était donc **coupé en pleine phrase**
  (capture utilisateur), et avec lui le contrôle d'avant-départ « tout est sur l'appareil », qui
  est précisément ce qu'on vient vérifier avant de partir sans réseau. À 10 catégories il
  manquait 190 px.
- **Trois étages, un seul défile** : le PÉRIMÈTRE (bibliothèques) est fixe en haut, les
  CATÉGORIES sont le seul défileur — intertitre collant compris —, les COMMANDES et l'ÉTAT
  forment un socle fixe en bas. Ce qui ne grandit pas ne bouge plus. Le pied nomade atterrit
  désormais dans le socle (`.hs-foot`), ce qui est exactement ce qui le soustrait au défilement.
- **Densité** : catégories et commandes en rangées de 32 et 34 px (le corps reste à 13,5 px,
  seul le rembourrage tombe à 6) — **sept catégories tiennent sans défiler** là où cinq
  débordaient. ⚠ Les comptes restent collés à droite : la maquette leur réservait la colonne de
  34 px du crayon pour les aligner sur ceux des bibliothèques, écarté à la relecture
  (« ça fait bizarre sinon »).
- **La remise à zéro des catégories manquait** : « Toutes » existait pour les bibliothèques,
  rien en face — on ne revenait à l'union qu'en re-tapant la rangée active, un geste que rien
  n'annonce. Une rangée « Toutes les catégories » ferme la symétrie ; son compte est celui du
  PÉRIMÈTRE choisi, pas de l'application entière.
- **Une commande n'est plus dessinée comme un filtre** : icône, libellé en gras, chevron. Le
  nombre en queue voulait dire « ce que la liste montre » pour une catégorie et « ce qu'il y a
  derrière la porte » pour l'historique — deux sens pour un même signe.
- **Le pied ne dit plus deux fois la même chose** : au nominal, les deux phrases « Documents
  PDF : … » — qui commençaient par les mêmes mots et laissaient « (15) · Réindexer » partir
  seul à la ligne suivante — fusionnent en **une rangée** « ✓ 15 documents prêts hors ligne »,
  dépliable SUR PLACE (pas de fenêtre, règle 11). Dès qu'une des deux a quelque chose à
  demander, la synthèse s'efface et les deux lignes reprennent la parole telles quelles,
  registre ambre compris : **on ne masque jamais un état qui appelle un geste**.
- **Aucun aplat** : la maquette posait la synthèse sur un fond vert doux ; refusé à la relecture
  (« ça saute trop aux yeux ») — et le code disait déjà pourquoi, `refreshAttOffline` portant
  « P3-11 : nominal = neutre » et `.pers-warn` colorant le TEXTE, jamais un fond. Un aplat vert
  permanent aurait désensibilisé à l'ambre, seul registre qui doit se voir. L'accroche vient du
  CHIFFRE en encre pleine : c'est ce qu'on vérifie.
- **Le pied devient une colonne de rangées** (A271), sur les trois largeurs où il vit (250 px en
  socle de colonne, ~574 et ~300 en voie étroite). La coulée `flex-wrap` mettait la version en
  bout de la rangée des liens à 574 et la rejetait sous eux à 300 : l'ordre de lecture changeait
  avec la largeur, et **trois bords gauches cohabitaient** (18 px pour une marque, 28 pour le
  texte d'un lien, 36 pour celui d'un état), avec 2 px d'interligne entre des rangées de 32.
  Désormais : une colonne, un interligne de 4 px, et **une seule colonne de texte à 20 px** —
  marque de 14 px + gouttière de 6 — que les liens rejoignent en recevant leur icône (les mêmes
  que dans la colonne). La marque de l'état de stockage sort du texte (elle n'existait que dans
  l'état « Cloud », et décalait le premier mot d'une largeur variable selon l'état).
- **Les deux lignes d'état prennent le même dessin** — elles sont toutes deux des commandes
  (l'une ouvre la fenêtre Stockage, l'autre déplie) : marque, texte, chevron, et la hauteur de
  32 px que la règle 9 leur devait déjà. `#storageInfo` vivait à 15,4 px depuis toujours.
- **Une seule hauteur de rangée dans la colonne** : la première version densifiait les seules
  catégories (32 px) et laissait les bibliothèques à 38 — deux hauteurs, à un filet d'écart, pour
  deux listes qui font la même chose. 32 partout.
- **Un seul dessin de marque dans le pied** (A272) : la pastille de synchro était son seul OBJET
  — une pilule teintée de 22,7 px au milieu de lignes de 15,4 — et sa rangée n'avait rien dans la
  colonne de marque. La pilule tombe, l'état rejoint la colonne, et son point plein cède la place
  à un **glyphe par état** (✓ synchronisé, ↺ en cours, ⏸ hors-ligne, △ erreur, 🔒 en attente) au
  gabarit des trois autres. Les états qui appellent un geste gardent leur encre de registre sur
  le texte, jamais un fond.
- **Les deux commandes du pied deviennent des boutons discrets** en voie étroite : en lien, elles
  flottaient dans un bloc d'état, et leur cible se réduisait à la longueur du mot. Surface tonale
  sans contour, 36 px. Coût mesuré et assumé : à 390 px les deux libellés entiers ne tiennent pas
  sur une rangée (339 px pour 354 disponibles), elles s'empilent — 78 px au lieu de 32, compensé
  en partie par l'interligne du pied ramené de 4 à 2 px.
- **L'interligne du pied ne se réglait pas en pixels** : un `gap` unique se lisait 4, 12 puis
  19 px selon les rangées qu'il séparait, parce qu'elles n'avaient pas la même hauteur (20 px pour
  la version, 32 pour les deux commandes) et que le blanc interne d'une rangée s'ajoute au gap.
  Les trois rangées font désormais 32, le gap tombe à 0, et le seul écart qui reste (6 px) sépare
  les deux registres — commandes et état.
- **Les rangées d'état s'arrêtent à leur texte** : elles prenaient toute la largeur, donc le
  chevron se collait au bord droit en laissant des centaines de pixels de vide, et la marque
  restait seule à l'autre bout. Le groupe marque · texte · chevron redevient un objet, au même
  retrait (12 px) et au même rayon que les boutons du dessus ; la surface n'apparaît qu'au survol.
  Toutes les marques du pied tombent alors sur la même verticale, boutons compris.
- **Trois verticales dans la colonne, et trois seulement** (A273) : quatre libellés démarraient à
  quatre abscisses (24 · 41 · 45,5 · 46), chaque famille posant son texte où sa marque tombait.
  Une **colonne de marque de largeur fixe**, portée par toutes les rangées et laissée vide quand
  il n'y a rien à y mettre, remet tout d'aplomb — marque à 24, libellé à 44, nombre au bord droit.
  Le nombre passe **après** le crayon : c'est ce qui aligne les deux colonnes de comptes sans
  réserver la case du crayon partout. Une seule hauteur de rangée (32), un seul filet, et les deux
  pavés pleine largeur (« Nouvelle bibliothèque », « Gérer les catégories ») deviennent des
  rangées discrètes. Le socle suit le contenu au lieu de laisser un trou de 120 px au milieu.
- **Le socle se replie en une ligne** (A274) : il empilait cinq rangées de même forme sur 216 px
  pour dire deux commandes et un état. Au nominal, les quatre lignes d'état deviennent
  **« ✓ Tout est prêt · v5.19.0 »**, dépliable sur place ; dès qu'un fait appelle un geste
  (documents manquants, index en échec, synchro refusée, stockage presque plein), elles reprennent
  la parole telles quelles. Le dépliant est **subordonné** — ses rangées démarrent sous le texte
  de la synthèse, pas sous sa marque.
- **Intitulés réécrits, courts** : « Prêt hors ligne » puis « Utilisable sans réseau » ont été
  essayés et abandonnés — le premier se lisait comme un état de connexion, le second ne couvrait
  pas la recherche dans les documents. « 15 documents sur l'appareil », « Recherche dans les
  documents », « 3 documents à télécharger », « Indexation en cours (4) ». Les actions de ces
  rangées passent à 11 px : un lien de 13,5 px faisait un mot deux fois plus gros que sa phrase.
- **Trois blancs verticaux, pas sept** : la colonne séparait ses blocs par 10 · 2 · 14 · 4 · 8 ·
  12 · 31 px, chaque valeur héritée d'un réglage local. L'échelle est désormais 2 (entre rangées),
  10 (d'un intertitre à sa première rangée), 12 (au-dessus d'un intertitre et de part et d'autre
  d'un filet).
- **Le type à créer ne filtre plus la liste** (A275, signalé à l'usage : « Créer → aide cognitive
  mène à une vue filtrée qui n'est plus censée exister »). Le dialogue empruntait `state.section`
  depuis la v4.4.2 — juste quand l'accueil était une liste par type, faux depuis que la liste est
  l'union. Il a son propre cran. ⚠ **Deux harnais s'appuyaient sur ce défaut** : l'un gardait
  l'ancien contrat, l'autre cliquait le sélecteur du dialogue en croyant changer de section — et,
  la liste des protocoles étant vide dans le jeu d'exemple, ses deux témoins mesuraient l'accueil
  en croyant mesurer une lecture. Les deux sont réécrits, et la lacune du second est écrite dans
  le fichier.
- **Dire ce qu'est une aide cognitive, et un protocole** (A276) : le dialogue « Créer » l'explique
  en une phrase par nature, depuis la même source que les bandeaux. Et les deux bandeaux de
  bibliothèque vide fusionnent en **un seul** qui pose les deux natures côte à côte — écrits pour
  un accueil filtré par type, ils s'empilaient toujours ensemble depuis l'union, et la question
  qu'on se pose vraiment (« quelle est la différence ? ») n'avait de réponse nulle part.
- **Le rappel du raccourci suit le système** : `⌘K` sur Apple, `Ctrl K` ailleurs (le gestionnaire
  acceptait déjà les deux, plus « / »), et le champ réserve la largeur du plus long des deux.
- **En voie étroite, « Rangé par » et « Sélectionner » passent sous « Répertoire »** : ils
  gouvernent cette liste, ils ne la précèdent pas.
- **Les 18 px sous l'en-tête tombaient sur `#syncErrNotice`**, présent mais masqué — donc sur une
  boîte sans hauteur : le premier bandeau touchait l'en-tête.
- **Deux pièges payés en chemin**, tous deux notés sur place : (1) le bloc de style est déclaré
  AVANT `.hs-row`, donc `.hs-cat{min-height:32px}` perdait la cascade **en silence** (rangées
  mesurées à 38 px) — qualifié en `.hs-row.hs-cat` ; (2) la marge basse du filet de l'étage haut
  s'échappait de sa boîte et ouvrait une bande de 12 px entre les deux étages, assez pour laisser
  voir ce qui défile dessous : la marge tombe, et les deux étages fixes deviennent opaques et
  au-dessus. Écart mesuré à 0, intertitre collé au bord du défileur, socle immobile sous
  défilement (bas du pied identique avant et après).

## [5.18.5] — 2026-08-30
### L'anneau de focus n'est plus rogné par les fenêtres (A268)

- **Signalé sur captures** : « l'encadré de sélection des champs et des boutons est coupé par la
  fenêtre, dans plusieurs modales ». Cause : le corps des fenêtres (`.ai-body`) ferme son axe
  horizontal depuis la v5.10.5 — décision juste, gardée telle quelle — et un champ y occupe
  TOUTE la largeur : son anneau (2 px de trait + 2 px de décalage) tombait pile sur le bord de
  découpe et se voyait amputé à gauche et à droite. Un état de focus amputé est un défaut
  d'accessibilité, pas une coquetterie.
- **L'axe n'est pas rouvert** : le bord de découpe s'écarte de 4 px, rendus par une marge
  négative — le contenu ne bouge pas d'un pixel (mesuré 423..857 avant et après), la découpe
  respire. Vérifié au clavier à 1280 comme à 390 px : anneau entier, 4 px de marge de chaque
  côté. En HAUTEUR, `scroll-padding` évite qu'un champ atteint au clavier ne se colle au bord
  du scrollport.
- **`overflow-clip-margin` ne pouvait pas servir** — la propriété faite pour ça est ignorée dès
  que l'élément défile (`overflow-y:auto` en fait un conteneur de défilement) : c'est noté dans
  la doctrine pour la prochaine fois.
- **Trouvé en chemin** : le dépliant « Pourquoi créer un compte ? » n'avait AUCUNE règle de
  focus — il rendait l'anneau par défaut du navigateur (couleur hors palette, épaisseur non
  maîtrisée), seul de sa famille dans ce cas. Comblé.

## [5.18.4] — 2026-08-30
### Le clavier ne part plus tout seul (A267)

- **Signalé le jour même** : « si la page rétrécit pendant une recherche qui s'affine, le
  clavier disparaît ? ». Oui — et c'était une faille de conception, pas un réglage : la v5.18.3
  refermait le clavier sur l'ÉVÈNEMENT `scroll`, or une liste qui RACCOURCIT sous la frappe fait
  recaler le défilement par le navigateur, qui émet `scroll` sans qu'aucun doigt n'ait bougé. Le
  clavier se fermait donc en pleine saisie, au pire moment. La garde de 600 ms n'y pouvait rien :
  le cas arrive bien après l'ouverture.
- **Seul un GLISSEMENT réel referme désormais** : `touchmove` de plus de 10 px vertical, né HORS
  du dock (dans le champ, le geste est celui du curseur ; dans la rangée de crans, un défilement
  horizontal). Une remise en page n'émet jamais de touchmove. Vérifié dans les deux sens : le
  focus TIENT sur un recalage programmatique, il PART sur un glissement de 70 px.
- **La leçon, écrite dans la doctrine** : pour distinguer « l'utilisateur a fait X » de « il
  s'est passé X », écouter l'ENTRÉE, jamais la conséquence.

## [5.18.3] — 2026-08-30
### Suites du terrain iPhone (A266)

- **Défiler referme le clavier** (signalé : « en scrollant, la barre saute et la bande
  disparaît »). Suivre le viewport visuel pendant un défilement clavier-ouvert est
  structurellement saccadé (les variables sont sondées) — et l'utilisateur qui défile a fini de
  taper : au premier défilement (fenêtre ou viewport visuel, garde de 600 ms car l'ouverture du
  clavier émet ses propres évènements), le champ rend le focus, le clavier se referme, la
  liste se lit plein écran et la pilule revient en bas. Le patron d'iOS Mail/Safari.
- **La zone sûre du haut est couverte** (signalé en PWA installée : « le bandeau de sélection
  se retrouve sous l'heure », idem pour les intertitres collants). L'en-tête est statique
  depuis la v5.18 — une fois défilé, plus rien ne portait `env(safe-area-inset-top)` : un sol
  fixe couvre la bande de l'encoche (le contenu ne défile plus sous l'heure) et le bandeau de
  sélection comme les intertitres s'arrêtent dessous. Inerte en navigateur (env vaut 0).
- **Le rythme sous l'en-tête est UN** : le titre « Résultats — toutes les bibliothèques »
  naissait collé (marge haute nulle) — 18 px sous l'en-tête partout désormais (Accès direct,
  Résultats, et la voie large), mesuré aux deux largeurs.

## [5.18.2] — 2026-08-30
### Le clavier iPhone, au propre (A265)

- **La bande sous la barre d'accessoires iOS devient unie** (signalé, capture à l'appui :
  « alternance fond uni / fond transparent / clavier, ça fait bizarre »). La barre (flèches + ✓)
  est au SYSTÈME — ni retirable ni mesurable, le viewport visuel s'arrête au-dessus d'elle —
  mais ce qu'on voyait à travers était à nous : les rangées de la page qui continuent dessous.
  Un SOL opaque de 240 px sous le dock couvre tout l'entre-deux ; la barre translucide d'iOS se
  pose désormais sur un fond calme.
- **Taper la pilule ne fait plus défiler la page** (signalé : « le scroll fait n'importe quoi et
  descend »). Au focus d'un champ, iOS fait défiler le document pour « l'amener en vue » — or la
  pilule est FIXE et se repositionne déjà seule au viewport visuel : ce défilement automatique
  était inutile et partait vers le bas. En étroit sur l'accueil, le focus est pris à la main
  (preventDefault sur pointerdown puis focus sans défilement) : même geste, clavier inchangé,
  zéro mouvement.
- **La respiration en-tête → « Accès direct » s'aligne sur le large** : 34 px en étroit contre
  18 en large (le rembourrage de main s'ajoutait aux 16 px du titre de section) — 18 partout,
  mesuré aux deux largeurs.

## [5.18.1] — 2026-08-30
### Deux retours d'usage sur la v5.18.0, le jour même

- **L'ordre des blocs est le même à toutes les largeurs** (signalé : « pourquoi Rangé par
  apparaît au-dessus des épinglées, contrairement au bureau ? ») : tuiles d'accès direct
  D'ABORD, puis « Rangé par » + « Sélectionner », puis le RÉPERTOIRE. En deçà de 1200 px, la
  rangée de commandes s'émettait encore avant les tuiles — un vestige de l'ordre d'avant leur
  déménagement sur la ligne RÉPERTOIRE au bureau. Au passage, une liste VIDE n'émet plus de
  rangée de commandes du tout : rien à ranger, rien à sélectionner (le témoin doctrine acte
  cette absence).
- **Clavier ouvert, la barre de recherche épouse le clavier** (signalé sur iPhone, capture à
  l'appui : pilule flottant à ~130 px au-dessus du clavier, contenu nu dans l'entre-deux).
  Deux racines (A264) : la garde v5.14.1 « champ dans l'en-tête → ne jamais poser `html.kbd` »
  datait d'avant le déménagement du champ dans #homeDock — la classe ne se posait JAMAIS sur
  la recherche d'accueil, tout l'habillage clavier était mort ; et l'ancrage par CONSTANTE
  (bas du viewport − 84 px) cassait dès que la géométrie réelle divergeait. Désormais : la
  garde apprend le dock (qui gère sa propre géométrie), l'en-tête d'ACCUEIL est exempté du
  retrait sous clavier (il est statique — il défile — et il porte le champ qu'on tape), et le
  bas du dock épouse EXACTEMENT le bas du viewport visuel (`translateY(-100%)`, aucune
  constante, rangée de filtres comprise), en matière OPAQUE avec un filet haut. Mesuré au
  pixel en simulation ; le juge final reste l'iPhone réel.

## [5.18.0] — 2026-08-30
### L'accueil sans mécanisme — refonte complète, conçue sur maquettes et corrigée à l'usage

Chantier mené sur le canvas « Accueil — la barre d'en-tête » puis ajusté en direct sur captures
de l'auteur ; chaque arbitrage est consigné dans `docs/decisions/lot-v5-18.md` (A238-A262).
Point de départ : « le principe de l'en-tête qui se rétrécit est bien, l'implémentation est
mauvaise » — huit rouages (repli home-slim, seuils, hystérésis, re-mesures, rescues) pour 52 px.

- **L'en-tête n'a plus d'états** : il est statique et défile — le défilement EST l'état. En
  étroit, marque 21 px / logo 30 (descendus d'un cran après essai à 23/32 : « un peu trop
  gros ») et « Créer » garde son mot dès 390 px (palier déclaré). En voie large, la RECHERCHE
  est la barre du haut (⌘K en invite, effacée au focus), marque à la largeur de la sidebar.
- **L'accès vit dans le dock** : pilule de recherche FIXE en bas en étroit (zone du pouce,
  patron Safari/Maps), qui loge le champ sous le clavier (`--vvt`/`--vvh`) ; rangée d'en-tête
  en large. **Les filtres vivent dans la fonction recherche** : hors recherche la pilule est
  seule ; chercher fait paraître les crans Tout · Aides · Protocoles (qui agissent sans perdre
  la requête) et « Filtrer (n) » ; hors recherche, un filtre actif reste modifiable par le
  bouton « filtres : … » de la ligne RÉPERTOIRE — l'état n'est jamais piégé.
- **La liste est l'UNION des bibliothèques**, en trois rangements — « Rangé par
  <bibliothèque · catégorie · A–Z> ⌄ », une phrase-menu, **retenue par compte et synchronisée
  entre appareils** (`data.prefs.homeGroup`, sans jamais re-ranger l'écran ouvert). Sections
  en CARTES, intertitre collant DEDANS (il coiffe la carte au défilement), provenance des
  homonymes, pastille + nom de catégorie sur chaque rangée.
- **Un SEUL dessin de rangée à toutes les largeurs** (direction A du canvas « Accueil épuré »,
  retenue contre un tableau 6 colonnes essayé puis rejeté : ses colonnes répétaient les
  intertitres et ses cases vides s'écrivaient en tirets) : titre + ligne de méta — nature ·
  discriminant · catégorie · code · date seulement si elle existe. Au pointeur fin, l'étoile
  ne vit qu'au survol de sa rangée ; l'épinglée reste pleine, le tactile ne change pas.
- **La sidebar (≥ 780) filtre, à une seule grammaire** : « Toutes » ou une bibliothèque
  (filtre de vue, patron Finder — le rangement n'est jamais touché), catégories du périmètre
  choisi avec comptes stables ; le bouton filtre n'existe plus en voie large. « Rangé par » et
  « Sélectionner » rejoignent la ligne RÉPERTOIRE à ≥ 1200, harmonisée à 12 px.
- **Accès direct en TUILES à toutes les largeurs** — deux par ligne dès 390 px, titre long à
  4 lignes (13,5 px) en étroit ; la fiche reste aussi à sa place dans le répertoire.
- **Corrigés en route, sur captures** : le pied de page finit au-dessus du dock (page courte
  comme longue, `--sab` compté) ; la visée du rail A→Z ne soustrait plus un en-tête qui ne
  colle plus (65 px trop bas) et son centrage compte la réserve du dock ; les chips de type de
  la feuille avaient perdu leur habillage avec une purge (elles partagent désormais la recette
  des chips de catégorie) ; le fondu d'ouverture/fermeture d'une fiche est retiré (pilote View
  Transitions purgé — le glissement du retour de pile reste) ; tablette en rangées (la grille
  de cartes intermédiaire a vécu).
- **Sous le capot** : purge à grep de home-slim, des rescues, du seg de groupement et de
  `vtWrap` ; témoins doctrine réécrits sur la sémantique v5.18 (dix sections) ; passes
  complètes vertes à chaque étape (26/26 harnais, tests 1169 × 2 moteurs).

## [5.17.6] — 2026-08-28
### L'étoile revient au bord de sa carte

- **Signalé à l'usage, capture et flèche à l'appui** : « réduis l'espace entre l'étoile et la fin
  de la carte sur la page d'accueil — surtout visible en smartphone, c'est là que l'écart est le
  plus grand et ça sonne mauvais ».
- **Mesuré à 390 px** : le titre commence à 16 px du bord de la carte, l'étoile s'arrêtait à
  **47** — presque trois fois plus, sur une rangée dont c'est le seul autre objet. La rangée avait
  l'air de finir avant sa carte.
- **Le 40 px de rembourrage droit n'était pas un choix de dessin** : c'est 24 (l'ancienne valeur de
  base) + 16 (la compensation de la marge négative qui fait aller le fond d'une rangée d'un bord à
  l'autre de sa carte, v5.6). Personne n'avait re-regardé la somme. Il passe à **16**, égal au
  rembourrage gauche : la déclaration devient symétrique, ce qui est la seule forme qu'on retient
  sans la relire. Même correction en voie large (24 → 14, égal à son propre rembourrage gauche).
  Chaque rangée gagne au passage 24 px de largeur de titre en étroit.
- **Il reste 6-7 px d'écart optique, et c'est voulu** : ce sont les flancs de la *cible* de
  l'épingle (bouton de 30 px pour un glyphe de 18 — WCAG 2.5.8 se mesure sur la boîte, pas sur le
  dessin). Les rattraper collerait la zone tactile au bord de la carte, donc au rail A→Z.
- **Ce qui borne, c'est le rail, pas le goût** : à 390 px la carte finit à 364, le rail commence à
  366, et le halo de l'épingle s'arrête désormais à 351 — **15 px de franc**. Le plancher de 8 px
  de la gouttière carte↔rail ne bouge pas : son argument est la *peinture* (sous 6, le fond
  translucide du rail se poserait sur le bord de la rangée), et la surface tapable de la rangée
  elle-même atteignait **déjà** le bord de la carte, à 3 px du rail. Le commentaire de v5.10.8 qui
  affirmait « la cible la plus proche du rail finit 40 px avant la carte » a été corrigé sur
  place : une doctrine qui affirme un chiffre périmé est pire qu'aucune doctrine.
- Vérifié à 320, 390 et 1280 px : titre à 17, étoile à 23, cible de l'épingle 30 × 28.

## [5.17.5] — 2026-08-28
### L'anneau de focus des fenêtres se pose à la main

- **Correctif du lot précédent, signalé le lendemain** : « je ne sais pas quel bouton est
  sélectionné, et surtout ça paraît inconstant ». La v5.17.4 posait le bon focus à l'ouverture
  d'une fenêtre — sur l'action, ou sur « Annuler » quand l'action est destructrice — mais **sans le
  rendre visible**, et un état juste mais invisible est indiscernable d'un état absent.
- **La cause, mesurée sur les deux moteurs et cinq fenêtres.** `:focus-visible` n'est pas un état,
  c'est une **heuristique du navigateur** : sur un focus PROGRAMMATIQUE — celui que pose
  l'ouverture d'une fenêtre —, elle ne s'allume que si la dernière interaction était au clavier.
  Ouvrir un dialogue **à la souris**, c'est-à-dire le geste réel neuf fois sur dix, ne montrait
  donc **aucun anneau** ; l'ouvrir juste après une frappe clavier en montrait un. Le même dialogue,
  deux apparences — c'est exactement l'inconstance signalée, et elle vient du navigateur.
- **L'anneau se pose donc à la main**, sur le SEUL élément focalisé à l'ouverture, et il part au
  premier changement de focus : `:focus-visible` reprend alors la main **avec le même dessin**, si
  bien qu'aucune bascule ne se voit. Écarté : un `:focus` nu en cascade sur toute la fenêtre, qui
  aurait écrasé les anneaux accordés à leur fond (aplat primaire, matière système sombre) — un
  anneau bleu y disparaît purement et simplement.
- **Et la première mesure avait menti** : une sonde « y a-t-il un anneau ? » qui accepte
  `box-shadow` déclare marqué le bouton principal, qui porte une **élévation permanente**. Le seul
  bouton qui semblait indiqué était précisément celui qui ne l'était pas. Un anneau de focus se lit
  sur `outline`, jamais sur l'ombre.
- **Ce qui reste volontairement différent d'une fenêtre à l'autre** : le focus va sur l'action pour
  une confirmation ordinaire, sur « Annuler » pour une confirmation destructrice. Ce n'est plus une
  inconstance depuis que l'anneau se voit — c'est la convention système, et elle se **lit** : on
  sait, avant de frapper Entrée, si l'on va valider ou renoncer.

**Doctrine** : `docs/decisions/lot-v5-17.md`, entrée **A237**.
**Témoin** : `audit-doctrine.mjs`, section « Fenêtres · le bouton focalisé se voit, même ouvert à
la souris » — trois fenêtres, chacune ouverte **après un vrai geste souris** (c'est lui qui met le
navigateur dans l'état où le défaut existe), lecture de l'`outline` seule, et vérification
qu'aucun anneau ne reste collé après fermeture. **Vérifié capable d'échouer.**

## [5.17.4] — 2026-08-27
### Quatre écrans qui affirmaient du faux

Quatre retours d'usage sans rapport entre eux, sauf un : aucun ne plante, et tous les quatre se
lisent comme une panne — un pied de page qui dit « sur cet appareil seulement » alors que la
synchronisation tourne, une décision qui ne montre qu'une de ses deux branches, un bouton grisé
qui invoque la mauvaise cause, un dialogue où la première frappe d'Entrée annule au lieu de valider.

- **Le pied de page suit enfin la connexion, sans recharger** (signalé : « lorsqu'on se connecte,
  “sur cet appareil seulement” en bas de la page s'affiche toujours jusqu'à ce qu'on recharge »).
  L'état de stockage est calculé à partir d'un instantané MESURÉ (`navigator.storage.estimate`,
  asynchrone), et la présence d'un compte y était figée au moment de la mesure — laquelle n'est
  rejouée ni à la reconnexion au MÊME compte, ni à la déconnexion depuis une vue de lecture. Le
  pied continuait donc d'annoncer « copie unique · non protégé » à quelqu'un dont les fiches
  partaient déjà dans le cloud : l'inverse exact de la vérité, sur la seule ligne de l'écran qui
  répond à « suis-je à l'abri ? ». La présence d'un compte se relit désormais **à la peinture**,
  comme l'état réseau le fait déjà — deux libellés réécrits, aucune mesure relancée. Règle
  générale : dans un instantané mesuré, un champ qui peut changer SANS nouvelle mesure n'a rien à
  y faire.
- **Une décision montre toutes ses branches, même celles qui n'ont pas de bloc** (signalé : « le
  parcours s'affiche mal pour les blocs conditionnels : uniquement certains s'affichent »). Quand
  une option mène directement au point de convergence — le cas le plus ordinaire qui soit, « oui →
  on continue, non → détour » —, elle n'a aucune rangée à elle et son étiquette était effacée :
  sur l'aide d'exemple « Accouchement inopiné », la décision « Imminence » affichait
  « NON — TRANSPORT » et **rien** pour « OUI — SUR PLACE ». Une décision à deux issues qui n'en
  montre qu'une ne se lit pas comme un raccourci, elle se lit comme un rendu à moitié fait — et
  dans une colonne d'ORIENTATION, une branche cachée est une branche qu'on ne saura pas prendre.
  Le parcours écrit maintenant l'étiquette **et** dit où la branche mène (« → 4 Suite commune »,
  « ↺ 2 », « ▪ fin »). Ce n'est pas une grammaire nouvelle : la vue « Parcours » de « Tout voir »
  le faisait déjà — les deux vues divergeaient en silence, et c'est la plus consultée qui avait
  tort. Le renvoi reste inerte : le saut tapable vit sur la rangée de la décision juste au-dessus.
- **« En ligne » grisé dit désormais POURQUOI, et répond au tap** (signalé : « avec le mode direct
  on peut partager sans compte ; mais quand on clique sur “En ligne”, grisé, on ne sait pas
  pourquoi ça ne fonctionne pas »). Deux défauts, et le second explique le premier. (1) La légende
  ne connaissait qu'une cause — « “En ligne” reviendra avec internet » — alors que le cran est
  fermé pour deux raisons distinctes : pas d'internet, ou pas de compte. Sans compte, attendre le
  réseau n'apportera jamais rien : la phrase était fausse au moment où elle comptait, et le bandeau
  de la feuille d'appariement faisait la même erreur. (2) L'attribut `disabled` n'émet AUCUN
  évènement : le seul geste qu'on fait pour comprendre ne produisait littéralement rien. Le cran
  garde son apparence de fermé et reste annoncé fermé aux lecteurs d'écran, mais il **répond** — il
  dit la cause, puis les deux chemins qui marchent : « En direct » relie les appareils par un code
  à scanner sans serveur (un Wi-Fi commun suffit, même sans internet), « Par l'écran » passe la
  session en codes filmés à la caméra, sans aucun réseau. Cette seconde moitié s'affiche aussi pour
  qui EST connecté — c'était la demande.
- **Les fenêtres de dialogue se conduisent au clavier** (demandé : « tab pour passer d'annuler au
  bouton d'action, entrée pour valider ; implémentation système native, reste simple »). Le piège
  Tab, Échap et l'activation par Entrée existaient déjà — les deux derniers sont le comportement
  natif d'un bouton. Le trou était le focus d'OUVERTURE, posé sur la croix de fermeture : la
  première frappe d'Entrée fermait la fenêtre, et l'on n'atteignait « Confirmer » qu'après deux
  Tab. Le focus va maintenant sur **l'action** quand elle est ordinaire, et sur **« Annuler »**
  quand elle est destructrice ou encore fermée par une case à cocher — convention système, et un
  Entrée réflexe ne doit jamais supprimer une fiche ni arrêter une session. Entrée valide aussi
  depuis la case à cocher ou le corps de la fenêtre, jamais par-dessus un contrôle qui a son propre
  sens d'Entrée, et jamais sur un bouton fermé. Rien n'a été réécrit en `<dialog>` natif : la
  migration toucherait les 22 fenêtres pour un gain nul sur ce qui était demandé.

**Doctrine** : `docs/decisions/lot-v5-17.md`, entrées **A233 à A236**.
**Témoin** : `audit-doctrine.mjs`, section « Parcours inerte · une décision montre TOUTES ses
branches » — l'invariant est indépendant du dessin (le nombre d'étiquettes de branche vaut le
nombre d'options), et il est **vérifié capable d'échouer** (défaut réintroduit : 1 étiquette pour
2 options ; `index.html` restauré à l'octet). Les trois autres correctifs ont été mesurés par une
sonde jetable, verte sur les DEUX moteurs.
**Portes** : `npm run check` (21 contrôles) · `npm test` **1169 tests × 2 moteurs** ·
`npm run audit` **21 harnais, 26/26 tâches vertes**.

## [5.17.3] — 2026-08-26
### L'application ne s'ouvrait plus sur iPhone — et l'hébergement gagne ses en-têtes

- **⚠ CORRECTIF CRITIQUE, signalé à l'usage** : « Safari ne peut pas ouvrir la page — *Response
  served by service worker has redirections* ». L'application ne démarrait **pas du tout** sur
  iPhone. Pour un logiciel qu'on ouvre en urgence vitale, c'est le pire mode de défaillance
  possible.
- **La chaîne, mesurée de bout en bout.** Une requête de navigation a le mode de redirection
  `"manual"` : lui servir depuis le cache une réponse dont le drapeau `redirected` est vrai est
  une **erreur réseau**, pas une dégradation. Or le nouvel hébergeur normalise les URL et redirige
  `/index.html` vers `/` en 307 ; `fetch` suivait la redirection, la réponse obtenue portait
  `redirected: true`, et `addAll` la rangeait telle quelle à l'installation. La première
  navigation servie depuis ce cache était alors refusée.
- **Pourquoi personne ne l'avait vu : WebKit refuse, Chromium tolère.** Le défaut était donc
  **invisible sur la machine de développement** et fatal sur la cible principale déclarée du
  projet. Il avait même été repéré et mesuré la veille — sur Chromium — puis jugé « fenêtre de
  risque étroite ». Le jugement était faux parce que la mesure ne portait que sur un moteur.
- **Le correctif est dans `sw.js`, pas dans un réglage d'hébergeur**, et c'est délibéré :
  neutraliser la redirection côté Cloudflare (`html_handling: "none"`) supprimerait aussi le
  service de `/` — on échangerait un défaut contre une racine morte — et l'application doit
  **rester déployable ailleurs** (règle 13), où un autre hébergeur normaliserait autrement.
  Trois lignes de défense : l'installation **demande `./`** (la forme qu'aucun hébergeur ne
  redirige) tout en écrivant sous la clé `./index.html` ; `putDoc` **reconstruit** toute réponse
  redirigée avant de la ranger ; et le repli de navigation **refuse de servir** une entrée
  redirigée qu'un worker antérieur aurait laissée, retombant sur le réseau — dégradé, jamais mort.
- **La propriété tout-ou-rien du noyau est conservée** sans `addAll` : ou le document et le
  manifeste entrent tous les deux, ou l'installation échoue. Elle n'a jamais été étendue aux
  icônes, qui feraient échouer l'installation entière pour un favicon en 404.
- **Un vingt-et-unième harnais, parce que rien ne mesurait ce terrain** : `audit-sw.mjs`. Le
  hors-ligne est la fonction dont tout dépend en intervention, et `check-sw.mjs` n'en voyait que
  le **statique** (entrées présentes, noyau ⊆ ASSETS, `CACHE` aligné). Le nouveau harnais monte
  **deux serveurs** — l'un qui redirige `/index.html`, l'autre qui sert à plat — et joue les mêmes
  six contrôles sur chacun : le worker s'installe et remplit son cache, le noyau y est, **le
  document n'est pas une réponse redirigée**, c'est bien l'application, une navigation servie par
  le worker aboutit, la page est contrôlée. **12/12 sur Chromium ET sur WebKit.** Vérifié capable
  d'échouer : défaut réintroduit → rouge sur le cas qui redirige, **vert sur le cas à plat** (il
  discrimine le défaut, il ne signale pas « quelque chose ») ; `sw.js` restauré à l'octet,
  empreinte sha256 comparée.
- **Deux pièges de MESURE attrapés en écrivant ce harnais**, tous deux capables de fabriquer un
  faux rouge : (a) `page.waitForFunction` avec un prédicat **`async`** reçoit une **Promesse**,
  toujours vraie — l'attente réussissait au premier sondage sans rien vérifier, et la sonde lisait
  ensuite un cache pas encore écrit ; l'attente est désormais pilotée depuis Node, où le `await`
  est réel. (b) Sur WebKit, `Cache.match('./index.html')` **ne retrouve pas** une entrée pourtant
  présente — vérifié en dumpant `cache.keys()` : elle y est, sous son URL absolue. Les deux sont
  consignés sur place.

### L'hébergement passe sur Cloudflare — `_headers` cesse d'être décoratif

- **Toute la posture de sécurité est désormais SERVIE**, et mesurée sur le domaine : CSP en
  en-tête HTTP (en plus de la balise), `Strict-Transport-Security`, `X-Content-Type-Options`,
  `X-Frame-Options`, COOP, CORP, `Permissions-Policy` à 21 capacités, `Referrer-Policy`, et
  `Cache-Control: no-cache` sur `/`, `/index.html` et `/sw.js`. Le fichier `_headers` était
  maintenu à jour depuis un an **en sachant que GitHub Pages l'ignorait totalement** ; il est
  enfin appliqué. Le garde anti-iframe posé dans le document en v5.0.0 passe de rempart unique à
  seconde ligne.
- **L'origine ne change pas** (le domaine était déjà en place), donc **aucune donnée locale n'a
  été touchée** — c'est précisément ce que le nom de domaine avait acheté une version plus tôt.
- **`.assetsignore`** : l'ancien pipeline Pages excluait `node_modules`, `.git` et `.DS_Store`
  d'office, Workers Assets ne le fait pas. Le premier déploiement échouait sur un `workerd` de
  145 Mio que la chaîne de déploiement avait elle-même installé dans le dépôt. Vérifié : `.git`,
  `node_modules`, `_headers` et `wrangler.jsonc` répondent tous **404**.
- **`wrangler.jsonc` ferme les deux adresses publiques que Cloudflare ouvre par défaut** —
  le sous-domaine `*.workers.dev` et une Preview URL par branche et par commit. Une case décochée
  dans le tableau de bord ne tient pas : chaque publication la recoche. Ce n'est pas cosmétique —
  chaque adresse est une **origine** de plus servant la même application, et une PWA installée
  depuis l'une d'elles aurait une bibliothèque séparée, invisible depuis l'autre, sans aucun signe.
- **Ce qui n'a pas été fait, et pourquoi** : `html_handling` n'est pas touché (cf. plus haut), et
  `tests.html` cesse de fonctionner **depuis le site déployé** — il charge l'application dans une
  iframe, que `X-Frame-Options: DENY` interdit désormais. Sans effet sur `npm test`, qui tourne
  contre un serveur local ; c'est le durcissement qui fait son travail, pas une régression.

## [5.17.2] — 2026-08-26
### L'application a son propre nom de domaine

- **Ce qui change pour vous** : l'adresse. L'ancienne
  (`vgasque.github.io/aides-cognitives-checklist/`) redirige définitivement vers la nouvelle —
  rien à faire, sinon **réinstaller l'app** depuis la nouvelle adresse et **supprimer l'ancienne
  icône** de l'écran d'accueil.
- ⚠ **Les données sont stockées PAR ORIGINE, et l'origine vient de changer.** IndexedDB (fiches,
  sessions, documents joints), les préférences et le cache hors ligne appartiennent à l'adresse
  qui les a écrits : la nouvelle adresse s'ouvre donc sur une **bibliothèque vide**. Ce qui était
  synchronisé revient à la connexion ; **ce qui était purement local doit être exporté depuis
  l'ancienne installation** (fenêtre Compte → « Exporter mes données »), qui reste ouvrable tant
  que son service worker sert son propre cache. C'est le prix d'un déménagement d'origine, il se
  paie une fois — et pas deux : l'origine nous appartient désormais, elle ne bougera plus, même
  si l'hébergeur change un jour.
- **L'hébergeur, lui, ne change pas** : toujours GitHub Pages (DNS chez OVH, `CNAME aides →
  vgasque.github.io.`, certificat Let's Encrypt automatique, HTTPS forcé). Mesuré le jour de la
  bascule : service worker **actif** sur la nouvelle origine, les quatre caches remplis
  (application, actifs immuables, pdf.js, jsQR) — donc le **hors-ligne fonctionne dès la première
  visite** —, aucune erreur console, redirection `301` de l'ancienne URL vérifiée. Les en-têtes
  que GitHub Pages ne sert pas le restent (ni HSTS, ni `nosniff`, ni `X-Frame-Options`, seul
  `Cache-Control: max-age=600`) : le tableau du § 1.1 de `docs/deploiement-et-conformite.md`
  était exact et l'est resté.
- **Aucun code n'a eu à changer, et ce n'est pas de la chance** : tous les chemins de
  `manifest.webmanifest` et de `sw.js` sont relatifs (`./`), donc le passage d'un sous-répertoire
  à la racine d'un domaine ne casse aucun actif ; `"id": "./"` se résout sur l'origine et n'a
  surtout pas été touché (porte à sens unique) ; et la connexion Supabase se fait par **code à
  6 chiffres**, pas par lien de retour — il n'y avait donc aucune liste blanche de redirection à
  mettre à jour.
- **Pourquoi un sous-domaine et non l'apex du domaine** : l'identité d'une PWA vaut son ORIGINE
  ENTIÈRE, d'où la règle « ne pas héberger une seconde PWA sur la même origine ». L'apex d'un nom
  personnel est exactement l'endroit où un autre site finira par vivre.
- **Les QR d'appariement s'allègent d'un cran, et le témoin reste un témoin réel**
  (`audit-qr.mjs`) : le lien de production tombe de 64 à 35 caractères, soit **une version de QR
  5 → 3** (mesuré) — moins de modules, donc une cible plus facile pour l'appareil photo d'en
  face, à taille d'écran égale. Le lien en sous-répertoire est **conservé comme cas distinct**
  plutôt que remplacé : c'est la forme de tout déploiement en sous-chemin (intranet,
  `<compte>.github.io/<dépôt>/`), et l'échanger aurait laissé la version 5 — et la marche
  v3 → v5 — sans aucun témoin.
- **Documentation** : la décision est datée et écrite dans `docs/deploiement-et-conformite.md`
  § 1.1, à côté de celle du 2026-07-27 qu'elle prolonge ; le README donne l'adresse et avertit
  que l'adresse d'un déploiement se choisit **avant** de diffuser.

## [5.17.1] — 2026-08-21
### Mode moniteur : la bande de temps tient à plusieurs minuteurs (A231-A232)

- **Signalé à l'usage** : « lorsque plusieurs minuteurs, timeline ne s'affichent plus ».
  Reproduit et mesuré — c'étaient **deux défauts pour un seul symptôme**. Toutes les
  étiquettes d'échéance vivaient au même `top` sur une ligne unique : à quatre minuteurs
  qui tournent, mesuré à 390 px, **quatre chevauchements deux à deux** et **deux étiquettes
  entièrement hors de l'écran** (bords à 408 et 438 px pour 390 disponibles). Sur un
  afficheur qu'on lit à deux mètres, une bouillie. Un minuteur seul ne montrait rien — la
  bande ne paraît qu'à partir de deux objets à relier, d'où « lorsque plusieurs minuteurs ».
- **Une échéance par rangée, sur le même axe** : deux marques alignées verticalement se
  lisent désormais comme une simultanéité, ce que la bande existe pour montrer, et la ligne
  de « maintenant » les traverse toutes. L'étiquette **bascule à gauche de sa marque** passé
  la moitié de l'axe : elle grandit toujours vers le centre, donc elle ne peut plus sortir
  de la bande — la garantie est arithmétique (18 signes ≈ 115 px contre 142 px de
  demi-bande à 320 px, le plus étroit servi), pas espérée.
- **Les tours projetés appartiennent à LEUR minuteur** : versés dans un tas commun, un tiret
  ne disait plus de qui il était le tour suivant — l'information même que la bande porte.
- **Aucun écart tu** : au-delà de ce que la hauteur permet, la bande garde les échéances les
  plus proches et **dit combien attendent derrière**.
- **Le correctif a d'abord posé son propre défaut, et le paysage l'a révélé** : la bande
  étant `flex:none` au-dessus d'un `.mon-main` qui cède, quatre rangées sur un téléphone
  **couché** recouvraient le grand chiffre de 44 px (54 px à 667×375). En portrait, rien ne
  paraissait. La place est désormais **mesurée** à chaque rendu, et le grand chiffre cède —
  parce qu'il est primaire : un chiffre recouvert ne se lit pas du tout, un chiffre plus
  petit se lit encore très bien à deux mètres (120 → 71-78 px en paysage, jamais sous 64).
- **Pourquoi aucun témoin ne l'avait vu** : `monBandData` est pure et ses onze témoins
  étaient verts — ils n'exerçaient **qu'un seul minuteur**, et aucune fonction pure ne peut
  voir que quatre étiquettes se peignent au même endroit. Le défaut était **géométrique**.
  Deux témoins de pluralité rejoignent `tests.html`, et un harnais mesure désormais la
  chose elle-même : `audit-doctrine.mjs`, deux jeux de minuteurs × quatre géométries dont
  **deux en paysage** (aucun chevauchement, rien hors champ, la bande ne recouvre pas le
  chiffre, plancher de 64 px tenu, tours projetés tous rattachés, écart compté à l'écran).
  Vérifié capable d'échouer, `index.html` restauré à l'octet.
- Trois erreurs de mesure attrapées en chemin et consignées, parce que chacune rendait un
  calcul juste en apparence : le `scrollHeight` d'un conteneur **étiré** vaut sa boîte et
  non son contenu ; `clientHeight` **comprend le rembourrage** (qui porte ici les marges
  matérielles) ; un minuteur **échu** ajoute une troisième ligne à réserver. Doctrine :
  `docs/decisions/lot-v5-17.md` (A231-A232).

## [5.17.0] — 2026-08-21
### La barre de sélection tient sur une ligne (planche 20, A227-A230)

- **Une ligne, 56 px, à tout écran et dans tout état** — contre ~100 px sur téléphone.
  Le défaut n'était pas la largeur : la barre est **collante**, donc ses deux étages
  restaient à l'écran pendant tout le défilement, sur le seul axe qui manque sur
  téléphone. Et cette hauteur était payée pour rien — à l'ouverture, **quatre commandes
  sur six étaient mortes**. Le contenu est repris ; la coque (place collante, matière,
  périmètre) ne bouge pas. Le contenu remonte de 44 px, et il n'existe plus d'état où la
  barre grandit sous le doigt.
- **Les actes passent dans un tiroir** : « Actions » ouvre la feuille que « Bibliothèque… »
  et « Catégorie… » ouvraient déjà. Un tap de plus, une rangée de moins. **Rien de coché,
  rien de mort** : la touche d'actes n'est pas grisée, elle n'existe pas — la barre est
  alors trois objets sur une ligne courte. Les trois actes sont écrits **une seule fois** ;
  la feuille les rejoue, elle ne les duplique pas.
- **Les libellés disent ce qu'ils déclenchent** : « Tout » → **« Tout cocher »**, « Aucun »
  → **« Tout décocher »** (un adjectif seul n'annonce rien, et « Aucun » se lisait d'abord
  comme un compte) ; « Déplacer… » et « Ranger… » nomment désormais leur **destination** —
  **« Bibliothèque… »**, **« Catégorie… »** —, la phrase entière étant reprise dans la
  feuille et en nom accessible. Les infobulles longues disparaissent : un intitulé qui se
  suffit ne se double pas d'une infobulle.
- **Le compte porte l'état, et il ne se fait plus rogner.** Il est le seul élément
  élastique de la ligne ; c'est aussi lui qui dit pourquoi « Catégorie… » est fermée
  (« 3 cochés · deux bibliothèques ») — un `title` n'existe pas au doigt. Mesuré avant
  correctif : réduit à 47 px pour 58 nécessaires à 390 px, à zéro à 320 px. Sous 430 px la
  barre se comprime (écarts, rembourrages) ; sous 400 px le segment rejoint le tiroir —
  sauf à zéro coché, où il est la seule commande et où il n'y a pas de tiroir.
- **Le palier de dépliage est à 1200 px, pas à 560 comme l'annonçait la planche** — corrigé
  **à la mesure**, avec deux raisons : la barre dépliée réclame **757 px de largeur utile**
  (les intitulés entiers y sont pour beaucoup) et à 560 px elle n'en a que 514, d'où un
  débordement de 179 px ; et la largeur de la barre **n'est pas monotone** en largeur de
  fenêtre — à 780 px la colonne de gauche lui prend 224 px d'un coup (698 → 474 px mesurés).
  Le seuil passe par `html.zw1200`, jamais par une media query (règle 10 : une media query
  mesure le périphérique, pas la place disponible). Conséquence assumée : sur tablette et
  sur beaucoup de portables, la feuille est le régime normal.
- **Correctif de fond découvert au passage** : `syncZoomWidth()` ne se posait **qu'au
  rendu**. Une rotation, une fenêtre tirée, un clavier qui s'ouvre ne re-rendent rien — les
  paliers de largeur restaient donc ceux de la largeur précédente, indéfiniment sur un écran
  qu'on ne quitte pas. Elle se repose désormais au redimensionnement et à la rotation.
- **Accessibilité** : cibles remontées de 32 à **40 px** et corps de 11 à 13,5 px (les deux
  planchers de la règle 9 étaient abaissés ici, sur des commandes dont l'une est
  destructrice) ; le filet de « Supprimer… » passe à `--ctl-line` — `--critical-line` est un
  rose pâle à 1,4:1 qui ne tient pas 1.4.11 — le rouge restant dans l'encre et le fond
  (mesuré après correctif : filet 3,41:1 en clair, 3,33:1 en sombre) ; la croix garde son
  nom accessible entier, c'est le libellé visible qui se replie.
- **Témoin** : `audit-doctrine.mjs` mesure à 320, 390, 560, 744, 1200 et 1280 px, à zéro
  comme à plusieurs cochés — hauteur exacte, débordement nul, **un seul rang**, compte non
  tronqué, cibles ≥ 40 px, et le palier réellement franchi. Vérifié capable d'échouer : il a
  lui-même trouvé un piège de cascade (`.btn.sm{min-height:38px}`, déclarée plus bas à
  spécificité égale — 38 px mesurés là où 40 étaient écrits). Doctrine :
  `docs/decisions/lot-v5-17.md`.
