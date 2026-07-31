# Écarts entre les maquettes et l'implémentation — relevé du 01/08/2026

Passe demandée sur `proto-r4.html`, `proto-large.html`, `proto-epure.html` et les deux jeux de
maquettes d'audit, comparés à l'application telle qu'elle est **après** le chantier v5.0.0.

**Méthode.** Chaque écart est relevé sur la maquette (citation) puis mesuré dans l'application (sonde
`?__actest` + rendu réel). Aucun point ci-dessous n'est écrit de mémoire. Ce qui est **déjà fait**
est dit tel quel, pour que la liste ne gonfle pas artificiellement.

---

## 1 · Ce qui est DÉJÀ conforme — vérifié, à ne pas refaire

| Point | Vérification |
|---|---|
| Le quai nomme les minuteurs et compteurs déclarés | `● SESSION 00:00 · 1 minuteur · 1 compteur ▾` |
| Bibliothèque unique, type en filtre | trois crans `Tout · Aides · Protocoles` |
| Rail alphabétique A→Z | présent, conservé (demande explicite) |
| Le rail ①②③ disparaît en session | lot T5 — `ol.care-path` absent, mesuré |
| « ⚡ À tout moment » dans la structure | présent dans la colonne de plan |
| Une référence n'a pas de chrome de crise | **65 px** mesurés (maquette : 58) ; pas d'axe de densité |
| Le journal des actions vit dans le rail (ordinateur) | présent |
| Trois colonnes en lecture ≥ 1200 px | plan · action · état |

---

## 2 · Les écarts, un par un

### A — Le bloc, en lecture

**A1 · La légende des registres n'est pas sur la carte.**
*Maquette* (`proto-r4`, tous les écrans) : sous le titre du bloc, une ligne
`⚠ vital · △ à vérifier · bulle = réponse attendue`.
*Aujourd'hui* : absente en lecture (elle n'existe que dans l'éditeur, `.crit-guide`).
*Écart* : réel. C'est le **seul endroit du produit où les registres s'apprennent** — l'épuration
l'avait proposée au retrait, et **la décision de l'auteur a été de la garder, inconditionnelle**
(É1, « remets l'information, ne l'enlève pas »). Elle n'a jamais été implémentée.
**Coût** : ~23 px par bloc. **Verdict : à faire.**

**A2 · « ⏱ Noter » n'est pas dans la carte du bloc.**
*Maquette* : rangée `⚡ Complication 3 · ⏱ Noter`, deux contrôles sur **une** ligne, sous les items.
*Aujourd'hui* : le journal et son bouton vivent **sous** la carte (lot T2), pas **dedans**.
*Écart* : réel, et c'est la moitié non faite de T2 — j'avais rapproché le journal, pas intégré le
geste. **Verdict : à faire**, avec le repli intelligent d'intitulés (voir A3).

**A3 · Le petit bloc de propositions d'intitulés.**
*Maquette* : après un horodatage, une rangée de chips propose des libellés.
*Aujourd'hui* : `tagAll`/`tagRank` **existent et sont testés** (journal référentiel, v4.52.0), et les
chips existent dans le panneau du journal — mais pas **sous le bouton de la carte**.
*Écart* : le calcul est fait, l'emplacement non. **Verdict : à faire, petit.**

**A4 · Les cases cochables dans l'ÉDITEUR.**
*Maquette* (`proto-large`, éditeur) : la ligne d'item n'a **aucune case** — `⠿ RCP immédiate :: …`.
*Aujourd'hui* : `.li-box` est rendu, en glyphe inerte (v4.64.0 : « la case reste un GLYPHE INERTE »).
*Écart* : réel, et la maquette est plus juste — une case inerte dans un éditeur invite à cocher.
**Verdict : à faire.** ⚠ En LECTURE les cases restent (la maquette les garde aussi).

**A5 · Le numéro de bloc.**
*Maquette* : pastille `3` sur l'en-tête du bloc, pas de rail à gauche.
*Aujourd'hui* : pastille `.ov-n` présente **et** rail `.care-path` hors session.
*Écart* : le rail subsiste **hors session**. **Verdict : à discuter** (question 3 ci-dessous).

### B — L'éditeur

**B1 · Deux champs par item : `do` et `expect`.**
*Maquette* : la ligne porte `do`, puis la réponse attendue en champ propre.
*Aujourd'hui* : **un seul champ**, où l'auteur tape `::` à la main.
*Écart* : réel, et le modèle v4 le rend naturel (`do` et `expect` sont deux champs depuis l'étape B).
**Verdict : à faire.** C'est probablement le meilleur rapport gain/coût de la liste.

**B2 · Les outils portent leur MOT.**
*Maquette* : `⚠ △ — ★ mémoire ×2 double ✕`.
*Aujourd'hui* : glyphes seuls (`⚠`, `★`, `×2`), le mot en `title`.
*Écart* : réel. Et c'est la règle 8 du dépôt — « la couleur n'est jamais seule », que la doctrine
étend aux glyphes. **Verdict : à faire**, sous réserve de largeur à 320 px (à mesurer).
*Note* : la maquette propose aussi un **trois-états** `⚠ △ —` au lieu du cycle actuel.

**B3 · La phase sur l'en-tête de bloc.**
*Maquette* : `phase : immédiate ▾`, et un **repli des phases non courantes** dans la structure
(mesuré : 2 686 → 1 995 px, **−26 %** à 320 px).
*Aujourd'hui* : le champ n'existe pas au repos.
*Écart* : réel. **Trois réserves écrites dans la maquette elle-même** : (1) sur un algorithme
linéaire la phase est redondante avec l'ordre ; (2) les trois valeurs viennent d'`AI_PROMPT` et
**rien n'établit que les cliniciens pensent en ces trois-là** ; (3) le champ doit rester
**facultatif et hérité**. **Verdict : à discuter** (question 2).

**B4 · « Condition d'entrée ».**
*Maquette* : section `Condition d'entrée — quand déclencher cette procédure`, avec
`＋ Critère · ＋ Diagnostic à éliminer`.
*Aujourd'hui* : « Confirmation diagnostique » (critères seuls) ; les différentiels sont une **autre**
section, plus bas.
*Écart* : réel — la maquette **réunit** les deux sous une condition d'entrée, ce qui est le geste
QRH (on entre, ou on n'entre pas). **Verdict : à faire.**

**B5 · Le bloc « ⚡ Complications » redessiné.**
*Maquette* : rangées `⠿ libellé → cible ✕`, plus la phrase « 1 à 3 — chaque entrée de plus dilue
les autres ».
*Aujourd'hui* : rangées libellé + bouton-cible, garde-fou 1-3 présent mais pas énoncé ainsi.
*Écart* : cosmétique et faible. **Verdict : à faire, petit.**

**B6 · La colonne de droite porte la RELECTURE, pas le schéma.**
*Maquette* : `structure 260 · formulaire 1fr (max 720) · relecture 320`.
*Aujourd'hui* : `structure · formulaire · SCHÉMA` (v4.74.0), la relecture étant un volet en pied.
*Écart* : réel, et c'est une **inversion de décision** : la v4.74.0 a mis le schéma à droite en
disant « ce qui ne se voit nulle part en écrivant, c'est la STRUCTURE » — mais la structure a déjà
sa colonne à gauche. **Verdict : à discuter** (question 4).

**B7 · Le déplacement par boutons à gauche.**
*Maquette* : poignées `⠿` en tête de ligne, à gauche.
*Aujourd'hui* : poignée `⠿` à **droite** de la ligne (v4.68.0, décision assumée).
*Écart* : réel mais c'est un **revirement** d'une décision motivée. **Verdict : à discuter**
(question 4).

### C — Les surfaces

**C1 · Boutons Parcours / Statique / Schéma.**
*Aujourd'hui* : trois **onglets** dans le cran « Toute la fiche » (lot T8) — `Parcours · Page ·
Schéma`. La maquette en fait la même chose.
*Écart* : **aucun**, sauf le nom : la maquette dit « Page SFAR », nous disons « Page ».
**Verdict : fait.**

**C2 · La fenêtre de partage intégrée.**
*Maquette* (`proto-r4`) : le partage est une **feuille dans le flux**, pas une fenêtre modale.
*Aujourd'hui* : `#shareModal`, une fenêtre — et c'est celle qui porte **14 des 23 règles CSS sur
mesure** du produit.
*Écart* : réel. **Verdict : à discuter** (question 4) — c'est la surface la plus complexe du
produit, et le gain est d'ergonomie, pas de mesure.

**C3 · Les popups d'ajout des fiches d'exemple.**
*Aujourd'hui* : bandeau système (lot T13, J0-D6) — recouvrement du bouton **60,7 % → 0 %**.
*Écart* : à préciser — la demande peut viser autre chose que ce qui a été fait. **Question 1.**

**C4 · Lecture d'une référence : le sommaire.**
*Maquette* : `sommaire 260 px · corps max 780`, plus `Documents` et `Voir aussi` dans la colonne.
*Aujourd'hui* : chrome déjà léger (65 px), **mais pas de sommaire**.
*Écart* : réel. **Verdict : à faire.**

---

## 3 · Ce que je propose, dans cet ordre

| Lot | Contenu | Risque |
|---|---|---|
| **M1** | **B1** (deux champs `do`/`expect`) + **B2** (mots à côté des glyphes) + **A4** (retrait des cases de l'éditeur) | faible |
| **M2** | **A1** (légende sur la carte) + **A2/A3** (« ⏱ Noter » dans le bloc + chips d'intitulés) | faible |
| **M3** | **B4** (Condition d'entrée) + **B5** (bloc complications) | faible |
| **M4** | **C4** (sommaire d'une référence) | moyen |
| **M5** | ce qui sortira des questions ci-dessous | à définir |

---

## 4 · Mes doutes — à trancher avant d'implémenter

1. **« Protocoles et Procédures intégré au quai d'accueil »** — je ne sais pas ce que « quai
   d'accueil » désigne ici. Aujourd'hui le type est un segmenté à trois crans dans la **tab bar
   basse**. La maquette `proto-r4` met les filtres en **chips dans une piste horizontale**, sous la
   recherche. Est-ce cela ? Et « popups d'ajout des fiches d'exemple » vise-t-il autre chose que le
   bandeau système déjà livré ?
2. **La phase** — la maquette elle-même pose trois réserves, dont « rien n'établit que les
   cliniciens pensent en exactement ces trois valeurs ». On la fait quand même (immédiate /
   2ᵉ intention / surveillance, facultative), ou on attend ?
3. **Le rail ①②③ hors session** — la maquette ne le montre nulle part, les numéros vivant sur les
   blocs. On le retire aussi **hors** session (donc partout), ou on le garde pour l'orientation
   avant de démarrer ?
4. **Trois revirements de décisions motivées** — la poignée `⠿` qui repasse à gauche (v4.68.0 l'a
   mise à droite pour éloigner le geste destructeur), la colonne de droite de l'éditeur qui passe du
   schéma à la relecture (v4.74.0), et le partage qui quitte la fenêtre pour le flux. Chacun est
   défendable ; aucun n'est neutre. Lesquels engage-t-on ?
