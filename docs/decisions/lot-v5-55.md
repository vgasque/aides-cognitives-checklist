# Lot v5.55 — A494-A497

Le chantier « cases en session », ouvert après v5.54.0 : douze tours de maquettes sur l'app réelle, puis un essai à
trancher en conditions réelles.

## A494 — essai « Étapes » : trois dessins de l'étape en session, au choix de l'appareil (v5.55.0)

**La demande.** « Les cases sont théoriquement très bien alignées mais très moches en vision globale ; on se perd dans
toutes les infos des étapes (vérification, dose, conditions type chocs délivrés ≥ 3 avec le “Faire maintenant”,
minuteurs déclenchés…) et on perd l'information la plus importante, l'intitulé de l'étape avec sa réponse. » Puis,
devant trois propositions finales : « Je n'arrive pas à me décider : implémente avec des options pour switcher dans
Moi, comme ça a déjà été fait par le passé. Je veux tester V1, V2, S6c. Quand je choisirai, enlever les autres options
doit être très simple, sans chambouler le code, et une autre session doit pouvoir le faire très facilement. »

**Mesuré avant (v5.54.0, aide « Arrêt cardiaque »).** Chaque case se centrait sur la première ligne de SON libellé, et
le libellé descendait sous l'étiquette CRITIQUE ou la jauge d'un seuil : la case prenait 7 hauteurs de 10 à 47 px du
haut de sa tuile ; rembourrage 32 / 10 ; trois matières côte à côte ; « Faire maintenant » tantôt dans la ligne,
tantôt dessous ; six niveaux de texte dans une même étape.

**Le canevas.** « Cases en session — second tour » (Claude Design), douze tours, vingt-sept pistes capturées sur l'app
réelle et passées à un contrôle géométrique automatique (aucune boîte ni ligne qui en chevauche une autre, aucune
boîte dessinée à moins de 2 px d'une autre, rien hors de sa tuile ; 40 cas par piste : 5 états × 360, 390, 820, 1280
px × aide normale et étape CHARGÉE — CRITIQUE + condition + minuteur, VIGILANCE + condition + compteur). Les formes
refusées et leur raison, à ne pas reproposer :
- tag à droite de l'intitulé / étiquette qui coiffe la case / hauteur commune case centrée (premier canevas) ;
- une feuille à filets (« pas individualisé ») ; le libellé d'abord, la condition dessous (« la condition se lit
  AU-DESSUS ») ; un fil reliant les cases (« ça laisse penser qu'il faut suivre un ordre ») ; la case à droite (trop
  de polices et de tailles flagrantes) ; la tuile-case ; le rangement par moment (« ne règle pas le problème ») ;
- une ligne de tête réservée vide dans toutes les tuiles (« la ligne vide en haut, c'est pas possible ») ;
- l'onglet seul en haut (« casse un peu la liste ») ; la légende au coin bas droit (« pas fan ») ;
- la tête dans la colonne du texte, Material ou Apple (« tout agrégé en haut puis le titre plus bas : effet décalé »).

**Ce que les trois variantes ont en commun** (`html.essai-et`).
- Une étape en TROIS parties : la TÊTE (ce qui précède la coche : CRITIQUE / VIGILANCE, condition du moment, « Double
  contrôle »), le CORPS (case · intitulé · réponse · « Faire maintenant »), le PIED (ce que fait la coche : minuteur ou
  compteur, avec son nom). Tête et pied n'existent que s'ils ont quelque chose à dire.
- Deux niveaux de texte : l'intitulé (17,5, très gras) et sa réponse (mono 15, encre pleine) ; tout le reste en UN style
  de 12 px, sans pastille (la condition en casse de phrase).
- Le corps ne bouge jamais : la case est à 12 px du haut du corps dans toutes les étapes, l'intitulé centré sur elle.
- « Faire maintenant » est un lien à droite de l'intitulé (cible de 44 px par halo).
- Les mots du pied : la valeur puis le NOM, sans « à la coche » (la place le dit) — « +1 Chocs délivrés » puis « 4
  Chocs délivrés » ; « 04:00 Adrén. dose ». Pendant les 10 s d'annulation, « décocher annule · 6 s » (modèle inchangé).
- Les réserves vides d'A9 (`<span class="wt"></span>`) disparaissent : le pied naît avec ce qu'il dit. Conséquence
  assumée : une étape qui passe de l'attente à son moment gagne un pied.

**Les variantes.**
- **V1** — tête et pied sont des BANDEAUX sur toute la largeur, DANS la tuile, teintés (6 % d'encre) ; rectangle net,
  écart de 8 px entre tuiles. La case est à 12 px du haut d'une tuile sans tête, 40 px sous une tête.
- **V2** — les mêmes bandeaux, de la matière de la tuile, séparés du corps par un filet.
- **S6c** — tête et pied sont des ONGLETS à cheval sur les arêtes (avant en haut à gauche, après en bas à droite) ;
  CRITIQUE / VIGILANCE dans une pastille teintée (rouge pâle, ambre ; grise une fois faite), séparée de la condition ;
  écart de 24 px (10 + 10 + 4 : l'onglet du bas d'une tuile et celui du haut de la suivante ne se touchent jamais —
  à 20 px ils se touchaient à 390 px, défaut trouvé par l'audit et corrigé). La case est à 12 px du haut de chaque tuile.

**Où l'on choisit.** Moi › Affichage, « Essai · Étapes » : Actuel | V1 | V2 | S6c. Réglage d'APPAREIL (`ac-essai-et`,
localStorage, jamais synchronisé). Défaut « Actuel » : aucune classe posée, `stepsListHtml` rend exactement l'ancien
DOM. Changer d'essai redessine aussitôt l'aide ouverte (c'est un geste de l'utilisateur, pas une action non commandée).
Les jetons d'une revue ouverte (`ol.steps.rev`) gardent leur dessin dans les trois variantes.

**Où vit le code — tout est balisé.** `grep -n "ESSAI ET\|essaiEt\|essai-et\|etLiHtml\|etWt" index.html scripts/*.mjs`
- `index.html`, JS : le registre `ESSAI_ET`, `essaiEt()`, `essaiEtPose()`, `essaiEtSet()` (bloc « ESSAI ET ▼ … ▲ »
  après la purge des essais A380) ; dans `stepsListHtml`, la ligne `const ET=…` et DEUX lignes `if(ET)return
  etLiHtml(…)` (rangée en attente de son moment, rangée ordinaire) ; juste après `stepsListHtml`, le bloc « ESSAI ET ▼ »
  avec `etLiHtml` et `etWt` ; `etWt(…)` enveloppe `wtModelFor` dans `wtSpanHtml` et `paintWitness`.
- `index.html`, CSS : UN bloc « ESSAI ET ▼ … ▲ » après les règles de l'étape cochée, en trois parties : COMMUN
  (`html.essai-et …`), « — ESSAI ET · V1 et V2 » (`html:is(.essai-et-v1,.essai-et-v2)`, puis une ligne
  `html.essai-et-v1` et deux lignes `html.essai-et-v2`), « — ESSAI ET · S6c » (`html.essai-et-s6c`).
- `index.html`, Moi : la rangée « Essai · Étapes » (`#etSeg`, balisée) et sa liaison (`body.querySelector('#etSeg')`).
- `scripts/audit-doctrine.mjs` : la section « v5.55 · A494 ».

**Procédure — le jour où l'auteur tranche.** Chaque étape se vérifie par `npm run check` puis la section d'audit.

*Garder UNE variante (ex. S6c) — le geste sûr, sans toucher à la spécificité :*
1. JS — `function essaiEt()` devient `function essaiEt(){return 's6c';}` ; `ESSAI_ET` ne garde que `s6c` (pour S6f :
   `return 's6f'` et `ESSAI_ET` ne garde que `s6f`, dont l'entrée pose les DEUX classes) ; supprimer
   `essaiEtSet` et la purge éventuelle de la clé (ajouter `localStorage.removeItem('ac-essai-et')` au démarrage, à côté
   de la purge des essais A380).
2. CSS — supprimer le sous-bloc des variantes écartées (pour garder S6c : tout le sous-bloc « — ESSAI ET · V1 et V2 » ;
   pour garder V1 : le sous-bloc S6c et les deux lignes `html.essai-et-v2` ; pour garder V2 : le sous-bloc S6c et la
   ligne `html.essai-et-v1` ; pour garder **S6f** : le sous-bloc « V1 et V2 » seulement — S6f se pose PAR-DESSUS
   S6c, ses deux sous-blocs restent, cf. A496). Ne PAS retirer les préfixes `html.essai-et` des règles gardées : ils portent la
   spécificité qui l'emporte sur `html.zw360 ol.steps li` et sur les règles d'étiquette d'avant.
3. Moi — supprimer la rangée « Essai · Étapes » (entre ses balises) et la liaison `#etSeg`.
4. Audit — la section A494 ne boucle plus que sur `['','<variante gardée>']`, puis seulement sur la variante (le rendu
   « Actuel » n'existant plus, son contrôle « ni tête ni pied » part).
5. Nettoyage (facultatif, même commit ou plus tard) : dans `stepsListHtml`, `const ET=opts.cls==='rev'?'':essaiEt();`
   devient `const ET=opts.cls!=='rev';`, et les anciens `return \`<li …` qui suivent les deux `if(ET)` deviennent du
   code mort : les supprimer avec la ligne de réserve A9 (`if(mt&&!wt&&…)wt='<span class="wt"></span>'`) ; puis, au grep
   (règle 14), purger ce qui n'est plus émis (`.stp-mks` dans `ol.steps li`, `.mo-line`, `.has-wt`, la marge haute
   réservée d'A381 `ol.steps li:has(>.txt>.stp-mks)`) — `check-classes` et `check-fns` disent ce qui reste mort.

*Retirer TOUT l'essai (garder « Actuel ») :*
1. Supprimer les deux blocs JS « ESSAI ET ▼ … ▲ » (registre ; `etLiHtml`/`etWt`), la ligne `const ET=…` et les deux
   lignes `if(ET)return etLiHtml(…)` de `stepsListHtml`, et rendre `wtModelFor(…)` nu dans `wtSpanHtml` et
   `paintWitness` (retirer `etWt(` et sa parenthèse).
2. Supprimer le bloc CSS « ESSAI ET ▼ … ▲ » en entier.
3. Supprimer la rangée de Moi et sa liaison ; ajouter `localStorage.removeItem('ac-essai-et')` à la purge de démarrage.
4. Supprimer la section d'audit A494 (garder sa partie A495, qui ne dépend pas de l'essai).
5. `grep -n "ESSAI ET\|essaiEt\|essai-et\|etLiHtml\|etWt" index.html scripts/*.mjs` ne doit plus rien rendre, hors
   l'épitaphe à écrire ici.

**Témoin.** `audit-doctrine` « v5.55 · A494 » : pour chaque variante, l'étape chargée à 390 et 1280 px, aux trois
moments (seuil atteint, après la coche, 2ᵉ passage) — aucun chevauchement ni contact de boîtes, rien hors de sa
tuile ; la case au même endroit dans le corps de chaque étape ; tête et pied présents ; sans essai, ni tête ni pied ;
Moi pose et retire la variante. Vérifié capable d'échouer (écart S6c ramené à 16 px : rouge à 390 px).

## A495 — l'anneau de la revue à la taille de la case, dans toutes les options (v5.55.0)

Signalé pendant l'essai : « harmonise l'alignement de la case à cocher sur le bloc de revue pour toutes les options,
j'ai l'impression qu'il est un peu plus haut que les autres ». Mesuré : le cercle visible de l'anneau (A449) faisait
32 px pour une case de 36 (rayon 15), donc son bord haut était 2 px plus bas mais son intitulé, un cran plus petit
(15 px, A449), se centrait 1,5 px plus haut que celui d'une étape ; et dans le dessin actuel, la revue posait son
anneau à 10 px du haut de sa tuile quand une étape simple pose sa case à 14-15.

Corrigé partout (y compris « Actuel ») : rayon 16 — l'anneau occupe, trait plein compris, les 36 px de la case ;
l'intitulé de la revue descend de 2 px (`padding-top` 8) et se centre sur l'anneau comme celui d'une étape sur sa
case ; dans le dessin actuel la rangée prend 14 px en haut (comme une étape simple). Mesuré : centre de l'anneau =
centre de la case (30 px dans les trois variantes), intitulé à 0,5 px près. Ce qui reste : en V1 / V2, une étape
AVEC en-tête descend sa case de la hauteur du bandeau (28 px) ; la revue, qui n'en a pas, reste en haut — c'est la
limite connue des bandeaux, pas un défaut d'alignement.

**Témoin.** Même section : rayon 16, centre de l'anneau = centre de la case voisine (variantes), à ±1 px de 32 dans le
dessin actuel.

## A496 — S6f : les onglets de S6c collés aux bords, en intercalaire (v5.55.1)

Question de l'auteur sur S6c : « pourquoi tu n'as pas collé plus à gauche l'onglet supérieur ? c'était pour ne pas le
mettre au-dessus de la case ? » — oui : en S6c l'onglet commence au bord droit de la case (48 px), le mot tombe
au-dessus de l'intitulé, et la colonne des cases reste vide ; collé à gauche, il passerait à 2 px du haut de la case.
Maquetté sur l'app réelle (treizième tour du canevas) : S6e (bord de l'onglet sur celui de la case) et S6f (onglet
au bord de la tuile). Recommandation donnée : garder S6c (colonne des cases vide, condition lue avec l'intitulé ; S6e
crée un troisième alignement). Décision de l'auteur : corriger S6f sur maquette, puis l'ajouter en option.

**S6f.** L'onglet du haut part du bord gauche de la tuile (la pastille CRITIQUE s'aligne sur la case), le pied touche
le bord droit. Deux défauts vus sur la première maquette, corrigés : sous l'onglet, le coin arrondi de la tuile faisait
un cran (le rayon de la tuile dépasse les 10 px de l'onglet qui y entrent) — la tuile perd ce coin (`.et-hd` : coin haut
gauche ; `.et-ft` : coin bas droit), le bord devient continu ; le pointillé de l'étape en attente ne double plus. La case
descend de 12 à 16 px dans TOUTES les étapes, revue comprise : sinon l'onglet passe à 2 px du haut de la case. Prix :
4 px par étape.

**Code.** Une entrée de plus dans `ESSAI_ET` (`s6f`) dont la classe est `essai-et-s6c essai-et-s6f` : S6f n'est qu'un
réglage PAR-DESSUS S6c, `essaiEtPose` pose chaque classe de la liste. Un sous-bloc CSS « — ESSAI ET · S6f » de six
lignes à la fin du bloc de l'essai ; le segmenté de Moi compte ses crans sur le registre (`--seg-n`). Mêmes balises,
même grep, même procédure (A494).

**Témoin.** La section A494 boucle aussi sur `s6f` (chevauchements, case au même endroit, tête et pied, anneau de la
revue) ; Moi : cinq crans, S6f pose ses deux classes, revenir à S6c retire `essai-et-s6f`.

## A497 — où se lit CRITIQUE : en tête, à droite de l'intitulé, ou collé au-dessus (v5.55.2)

Question de l'auteur : « pourquoi on a décidé de mettre critique en haut ? et si on le redescendait ? ». En haut parce
qu'A345 avait posé le mot en étiquette AU-DESSUS du libellé et que l'essai l'a rangé dans la tête (« ce qu'on lit avant
de cocher »), avec la condition. Maquetté sur l'app réelle (quatorzième tour du canevas), libellés courts et LONGS :
B1 (à droite de la première ligne de l'intitulé — le dessin du parcours, A388), B2 (dans l'onglet du bas — retiré par
l'auteur), B3 (au-dessus de l'intitulé, case descendue de 24 px — refusé : « sans décaler la coche ») puis B4 (collé
au-dessus, case immobile). Décision de l'auteur : B1 et B4 en options dans Moi.

**Réglage.** Moi › Affichage, « Essai · Critique » : En tête | À droite | Au-dessus — réglage d'APPAREIL distinct
(`ac-essai-mk`), valable pour les quatre dessins de l'essai, sans effet hors essai (`essaiMk()` rend `''` si
`essaiEt()` est vide). Classes `essai-mk-b1` / `essai-mk-b4` sur `<html>`, posées par `essaiEtPose`.

**Rendu.** `etLiHtml` : si `essaiMk()`, le mot (`stepMarkHtml`, `sr-only` compris) quitte la tête et ouvre `.txt`
dans `<span class="et-mk">` — la tête ne garde que la condition et disparaît sans elle ; le lecteur d'écran lit
« Étape critique. » avant l'intitulé. Mot en pastille teintée (crit-soft, warn-soft, gris une fois fait). B1 : la
pastille flotte à droite de la PREMIÈRE ligne (les suivantes reprennent toute la largeur — un libellé long gagne au
plus une ligne). B4 : `.txt` perd ses 6 px de haut et la pastille se pose collée au-dessus de l'intitulé ; la case ne
bouge pas, l'intitulé descend d'environ 12 px dans les étapes critiques (la case fait face au bloc mot + intitulé).
Pas de conflit avec « Faire maintenant », qui flotte aussi à droite : avant son moment une étape n'affiche pas son
registre (A398).

**Code.** Balisé « ESSAI ET » comme le reste : `ESSAI_MK`, `essaiMk`, `essaiMkSet` (bloc JS du registre), deux lignes
dans `etLiHtml`, le sous-bloc CSS « — ESSAI ET · CRITIQUE dans le corps », la rangée « Essai · Critique » de Moi ; la
liaison des deux segmentés de Moi est factorisée (`segs`). Garder une position : `essaiMk()` renvoie la clé gardée et
le CSS de l'autre part ; garder « En tête » : supprimer ces lignes et la clé (`ac-essai-mk` à purger au démarrage).

**Témoin.** La section A494 joue aussi S6c et S6f × B1 et B4 (chevauchements, case au même endroit, tête et pied) et
vérifie où est le mot (dans le corps, plus dans la tête — et l'inverse sans réglage) ; Moi : trois crans, B4 se pose et
se retire.
