# Transition vers le modèle v4 — synthèse des décisions

> **Objet.** Ce document consolide **tout ce qui a été décidé** au cours des deux audits et des trois
> prototypes, et le met en ordre de marche. Il est destiné à qui implémentera — humain ou IA.
>
> **Ce qu'il est** : la spécification des décisions prises, l'ordre de livraison et les garde-fous à
> écrire. **Les huit décisions ouvertes ont été tranchées** (§ 8) : plus rien n'y est en suspens.
> **Ce qu'il n'est pas** : un remplacement d'`AGENTS.md` — qui décrit le code **actuel** et sera
> **réécrit** par le lot T11, la structure v4 le rendant faux sur au moins six points. Ni une
> autorisation de commencer. **Aucune ligne d'`index.html` n'a été modifiée à ce jour.**
>
> **Sources.** [`audit-j0.md`](audit-j0.md) (symptômes J0) · [`audit-structurel.md`](audit-structurel.md)
> (causes, modèle v4, chantiers) · prototypes [`proto-r4.html`](proto-r4.html) (téléphone,
> interactif) · [`proto-large.html`](proto-large.html) (éditeurs, tablette, ordinateur) ·
> [`proto-epure.html`](proto-epure.html) (épuration).

---

## 1 · Ce qui a été décidé

### 1.1 Décisions explicites de l'auteur

| # | Décision | Conséquence |
|---|---|---|
| **A1** | **v3 est abandonné.** Le format peut rompre. | Format v4 ; v3 devient **import seulement** |
| **A2** | `dual` en solo → **option (a)** : l'item se coche normalement, le compte rendu porte « confirmé seul » | Ne bloque jamais un soignant isolé ; la trace dit ce qui s'est passé |
| **A3** | Le **mode statique revient**, comme *présentation* du cran le plus large — pas comme quatrième mode | Cran 3 = **Parcours** · **Page SFAR** *(puis **Schéma**, cf. A10 — trois vues au total)* |
| **A4** | La légende **« ⚠ vital · △ à vérifier · bulle = réponse attendue » reste, inconditionnelle** | Ma proposition de la conditionner est abandonnée (elle était fausse : la bulle existe aussi sur des items de niveau 1) |
| **A5** | **R4** — bibliothèque unique, le type devient un filtre | La tab bar Aides/Protocoles disparaît |
| **A6** | **Épuration appliquée** aux deux prototypes | É2 · É3 · É4 · É5 retenus, É1 abandonné (cf. A4) |
| **A7** | Cadrage du 2ᵉ audit : produit entier, J0 **et** J30, contraintes maintenues, chantiers pluri-versions | Aucun tutoriel, aucune aide livrée en plus |
| **A8** | **Les huit décisions D1–D8 de ce document sont tranchées** (§ 8) | ⚠ Ne pas confondre avec les **J0-D1…J0-D8** du premier audit, dont cinq restaient orphelines : leur sort est désormais explicite (§ 8) |
| **A9** | **La doctrine et le prompt IA sont réécrits** | Lots **T11** et **T12** ; le prompt suit T6 immédiatement |
| **A10** | **Le schéma devient le 3ᵉ onglet de « Toute la fiche »** | Il quitte le menu ⋯ ; le cran 3 porte Parcours · Page SFAR · Schéma |

### 1.2 Décisions de conception, prises au fil des mesures

| # | Décision | Ce qui l'a tranchée |
|---|---|---|
| **C1** | **L'action passe devant l'orientation, en session** | Mesuré : 1ʳᵉ étape à 847 px sur 640 ; la **diète ne suffit pas** (2 configs sur 3), seul l'ordre fonctionne |
| **C2** | **Un axe de densité à 3 crans** remplace guidé / statique / lecteur / se repérer | Ce sont des densités, pas des modes ; un axe est **ordonné** |
| **C3** | **Trois surfaces** : AGIR · SE REPÉRER · CONSULTER, et chacune **ne montre pas** ce que l'autre montre | Règle ECAM : le SD ne rejoue pas l'E/WD |
| **C4** | **`ddx` à l'entrée, `watch` à la fin** — ce ne sont pas le même bloc | Deux questions, deux moments |
| **C5** | **⚡ = un bouton constant**, index QRH, retour automatique | N boutons rouges obligeraient à lire sous stress |
| **C6** | **⏱ au même rang dans les trois crans**, dernière rangée de la carte | Mesuré : l'écart de position tombe de 360 px à 109 px, sans rien pousser dehors |
| **C7** | **Le journal se lit derrière le quai**, le geste se fait dans la carte | Deux natures ; le quai porte tout l'état vivant |
| **C8** | **Compte rendu = feuille plein écran** sur téléphone | Idiome de la plateforme ; supprime le calcul de hauteur visible |
| **C9** | **Partage derrière le quai**, jeton fermé `⇄ n` | Aucun segment ajouté au quai |
| **C10** | **Exercice = drapeau de session**, pas une surface | Placard mesuré à **0 px** de coût |
| **C11** | **4 coques de fenêtres** au lieu de 22 | `dialog` · `picker` · `sheet` · `settings` |
| **C12** | **Sur grand écran, les 3 axes de filtre descendent en colonne latérale** | Résout la saturation de la piste de chips |
| **C13** | **≥ 1200 px : deux densités côte à côte** ; l'axe se réduit à « Une étape ou non » | E/WD + SD simultanés |
| **C14** | **Une référence n'a pas de chrome de crise** | 58 px au lieu de 184 |
| **C15** | **Éditeur : une coque, deux corps** | Écrire une procédure ≠ rédiger une référence |

---

## 2 · Le modèle v4 — spécification

### 2.1 L'item

```jsonc
{
  "id":     "i7",              // IDENTITÉ, jamais une position
  "role":   "do",              // entry | do | watch | dose | ddx
  "do":     "Adrénaline IM, cuisse",   // le challenge — ce qui se prononce
  "expect": "0,5 mg",          // la réponse attendue — l'état CONSTATÉ
  "level":  3,                 // 3 warning · 2 caution · 1 advisory
  "memory": true,              // immediate action item
  "dual":   true,              // confirmé par LES DEUX
  "note":   ""                 // glose de l'auteur, jamais lue à voix haute
}
```

**Six champs v3 disparaissent** — `confirmation`, `verify`, `posology`, `notForget`, `differentials`
deviennent des `role` ; `references` **reste à part** (`sources[]`, métadonnée, jamais du contenu de
crise).

**Prescription derrière chaque champ** : `id` → intégrité du compte rendu (défaut mesuré) ·
`do`/`expect` → AC 120-71B §5.2.2.1 + Degani & Wiener · `level` → hiérarchie d'alerte ECAM, ordonnée
donc calculable · `dual` → **AC 120-71B §5.2.2.5**, inexprimable aujourd'hui · `memory` → QRH, un
memory item **est** un item de la liste.

### 2.2 Le bloc

```jsonc
{
  "id":"b1", "title":"Mesures immédiates",
  "phase":"immediate",         // immediate | secondary | watch  → DECLUTTERING, pas inhibition
  "kind":"do",                 // do | decision
  "items":["i1","i7"], "next":"b2",
  "question":"Rythme choquable ?",
  "options":[{"label":"Oui","concl":"Choquable","target":"b3"}],
  "hors": false                // bloc d'excursion : aucun next n'y mène, hors numérotation
}
```

`options[].target` et `next` pointent **n'importe quel bloc** : imbrication et boucles n'exigent
aucun champ de plus (vérifié sur un graphe à 4 niveaux).

### 2.3 L'aide

```jsonc
{
  "v":4, "id":"a1", "kind":"procedure",   // procedure | reference
  "title":"Arrêt cardiaque", "discriminant":"adulte", "code":"ACR",
  "category":"c-urgences", "library":"samu44",
  "status":"validated", "validatedAt":"2025-01",
  "items":[…], "blocks":[…], "start":"b1",
  "excursions":[{"label":"Hyperkaliémie","target":"x1"}],   // 1 à 3
  "timers":[{"label":"Cycle RCP","seconds":120,"autoloop":true,"onDue":"Analyse du rythme"}],
  "counters":[…], "sources":[…], "docs":[…], "links":[…], "local":"…"
}
```

### 2.4 La session

```jsonc
{
  "id":"s1", "aidId":"a1", "aidRev":"r12",   // ← la RÉVISION lue pendant le soin
  "mode":"clinical",                          // clinical | exercise | trial
  "startedAt":…, "endedAt":…,
  "log":[{"t":…,"kind":"check","ref":"i7","by":"lead"}],
  "texts":{"i7":"Adrénaline IM, cuisse"}      // repli si la révision a disparu
}
```

`aidRev` + `texts` réparent le défaut mesuré : aujourd'hui la clé `visite:bloc:INDEX` désigne **une
autre étape** après une simple insertion, et le compte rendu archivé nomme le mauvais geste.

---

## 3 · Les surfaces

### 3.1 L'axe de densité — trois crans, un seul contrôle

| Cran | Remplace | Sert à |
|---|---|---|
| **Une étape** | mode lecteur | lire à voix haute, à deux (AC 120-71B §5.2.2.1) |
| **Un bloc** *(défaut)* | guidé · journal | agir — modèle E/WD |
| **Toute la fiche** | statique · se repérer · **schéma** | **trois** vues : **Parcours** (structure, état) · **Page SFAR** (un document, rien ne s'y coche) · **Schéma** (la vue spatiale) |

**Le schéma est le troisième onglet du cran 3** (décision de l'auteur), et il quitte le menu ⋯.
Ce n'est pas une densité — c'est une **autre représentation de la même chose** que le parcours, donc
sa place est auprès de lui. Trois manières de regarder l'aide entière : en **liste indentée**, en
**document**, en **graphe**. Les boucles et les convergences s'y lisent d'un coup d'œil, ce qu'une
liste ne montre pas.

*Cette décision lève au passage une contradiction interne : le § II.2 disait déjà « Échelle et Schéma
→ deux affichages de SE REPÉRER », et le § 3.1 avait ensuite écrit l'inverse.*

> ### ⚠ CONTRAINTE — le schéma est le CODE EXISTANT, on ne le réécrit pas
>
> **`buildFlowSVG` est repris tel quel.** Le schéma dessiné dans [`proto-r4.html`](proto-r4.html)
> est une **maquette jetable**, faite pour montrer l'emplacement de l'onglet : elle ne doit servir de
> modèle à rien. Le générateur de l'application porte **330 lignes** et, avec ce qui l'entoure,
> plusieurs versions de travail qu'une réécriture perdrait :
>
> - `buildFlowSVG(f, cache)` — géométrie **pure et sans état**, avec son cache `_flowCache` : la
>   géométrie n'est **jamais** reconstruite à la navigation ;
> - `flowPaintState` — l'état peint **par classes** après insertion (`fn-cur` / `fn-ok` / `fn-off`),
>   halo et badge ✓ bakés ;
> - `bindSvgNav` — taper un nœud = `jumpToBlock`, **jamais de cochage, jamais de démarrage** ;
> - `bindFlowZoom` + `openFlowFull` — zoom 25–400 %, plein écran, écouteurs conservés au dépliage ;
> - la **contre-inversion sombre** (`.flow-hl`, `--flow-hl-dk`, `--flow-cur` en primaire clair baké) —
>   toute nouvelle peinture SVG exige sa règle de contre-inversion, c'est écrit dans la doctrine ;
> - `wrapText`, exposé et testé.
>
> **Ce qu'on lui AJOUTE, et rien d'autre** : une zone **« ⚡ À tout moment »** portant les blocs
> d'excursion — **hors du tronc, sans numéro**, au registre alerte, comme dans l'Échelle et le
> Statique d'aujourd'hui. C'est un ajout de **rendu**, pas une refonte : `flowPlan` les exclut déjà
> de la numérotation, et `cxDetached` sait déjà les distinguer.
>
> **Pourquoi c'est une contrainte et pas une préférence** : réécrire ce générateur, ce serait
> reperdre les flèches mesurées, la contre-inversion, le cache et la navigation — c'est-à-dire
> exactement la classe de régression que la règle 14 et l'hygiène de suppression du dépôt existent
> pour empêcher.

### 3.2 Anatomie de la carte d'action (après épuration)

```
┌ Ne pas oublier · n rappels ▾ ──────────────────┐   44 px, replié en session
├ ① Titre du bloc                          0/3   ┤   en-tête
│ ⚠ vital · △ à vérifier · bulle = réponse       │   LÉGENDE — inconditionnelle (A4)
│ ☐ item                                         │
│ ☐ ⚠ item          ×2                           │   items
│ [ Continuer — bloc suivant → ]                 │   1 action primaire
│ [⚡ Complication ③] [⏱ Noter]                   │   1 exception + 1 traçabilité
└────────────────────────────────────────────────┘
```

**Mesuré après épuration**, 320 × 640 : carte 428 px, pile d'actions **117 px = 27 %** (contre 34 %),
items **51 %**, rangées d'action **2** (contre 3), rangée de contrôles sur **une ligne**.

### 3.3 Ce que porte chaque surface

| | AGIR | SE REPÉRER | CONSULTER |
|---|---|---|---|
| bloc courant, items cochables | **✓** | lecture seule | — |
| chapeau `memory` | ✓ (replié) | ✓ | — |
| structure, branches, boucles | — | **✓** | — |
| `ddx` (différentiels) | rappel « ça ne colle pas ? » | ✓ | — |
| `watch` (surveillances) | en fin de parcours | ✓ | ✓ |
| `dose`, documents, sources | — | ✓ (page SFAR) | **✓** |
| ⚡ excursions | bouton constant | section « à tout moment » | **rien** |

### 3.4 Grands écrans

| Surface | Téléphone | Tablette ≥ 780 | Ordinateur ≥ 1200 |
|---|---|---|---|
| Accueil | piste de chips + rail A→Z | **3 axes en colonne latérale**, répertoire 2 colonnes, plus de rail | répertoire 3 colonnes |
| Procédure | axe à 3 crans | 2 colonnes (action + état) | **3 colonnes** ; l'axe se réduit à « Une étape ou non » |
| Référence | document | + sommaire | sommaire · corps ≤ 780 px |
| Éditeur | formulaire | + structure **ou** relecture | 3 colonnes |

---

## 4 · Règles nouvelles, issues des mesures

Chacune est née d'un défaut **mesuré pendant cet audit**. Elles ont vocation à rejoindre `AGENTS.md`.

| # | Règle | Ce qui l'a produite |
|---|---|---|
| **N1** | **Un compteur de filtre se calcule dans la sélection des AUTRES filtres, jamais dans la sienne ; un chip ACTIF n'est jamais désactivé** | Piège sans issue trouvé en conduisant le prototype R4 |
| **N2** | **Sur la carte d'action : une action primaire, une entrée d'exception, une rangée de traçabilité — rien d'autre.** Budget : la pile d'actions ≤ 25 % de la hauteur de la carte, sur un bloc de taille doctrinale (4+ items) | 8 contrôles accumulés, 34 % de la carte |
| **N3** | **Deux natures, deux traitements** : l'exception (⚡) passe avant la traçabilité (⏱) quand la place manque | À 320 px, 3 boutons réclamaient 358 px pour 267 |
| **N4** | **Un contrôle garde le même RANG DE LECTURE dans toutes les densités** | ⏱ en tête au cran 1 : écart de 360 px |
| **N5** | **Une légende s'affiche inconditionnellement** là où le vocabulaire visuel s'apprend | A4 — la bulle existe aussi sur des items de niveau 1 |
| **N6** | **Boucle ou convergence : le critère est l'ANCÊTRE dans le graphe**, jamais le numéro | Numérotation DFS trompeuse |
| ~~**N7**~~ | ~~Le quai nomme ce que la FICHE DÉCLARE~~ — **RETIRÉE au lot T2** : le constat 6 de l'audit J0 qui la fondait était faux (`.rt-collapsed` nomme DÉJÀ « 1 minuteur · 1 compteur », visible sans défiler à 390 px). L'appliquer aurait dupliqué une constante sur deux canaux, ce que la v4.70.1 proscrit | Constat retiré, mesure corrigée |
| **N8** | **Sous 780 px, toute fenêtre est une feuille plein écran** avec retour système | Six versions de « bande basse iOS » |
| **N9** | **Rangée de CHROME** (en-tête, quai, barre, colonne latérale) : l'élément qui cède porte `min-width:0` et s'ellipse, les autres sont `flex:none`. **Rangée de LISTE** : l'enroulement est permis, **borné** (3 lignes + ellipse). Sur l'en-tête, **le titre cède, jamais le discriminant** | En-tête 53 → 91 px à 320 ; libellé de minuteur +17 ; colonne latérale +21 ; colonne structure +14 |

---

## 5 · Ce qui ne bouge pas — à protéger pendant toute la transition

- **Les cinq points d'écriture uniques** : `migrate()` · `applyCheck()` · `persistLive()` ·
  `edCommit()` · `_putSessionSafe()`. Aucun sixième.
- **Local-first, hors ligne, zéro dépendance runtime** (règles 5, 6, 13).
- **La sémantique des registres** : ⚠ tue / △ trompe, la couleur jamais seule, une seule masse rouge
  par écran. v4 les rend **calculables**, il ne les change pas.
- **Règle 15** : le partage ne transporte que des **références**. v4 aligne le local dessus.
- **Périmètre réglementaire** : aucun champ calculé, aucune déduction. v4 **décrit** mieux, il ne
  **déduit** rien.
- **Commandes hors de l'affichage** (ECP/ECAM, v4.25.0) — sauf si la décision D1 en décide autrement.
- **Les quatre surfaces qui enseignent déjà** : dialogue « Créer », porte « ＋ », écran invité,
  dialogue « Terminer la session ? ».
- **La carte « SESSION EN COURS » de l'accueil** — reprise en 1 geste, coches conservées.
- **La géométrie sous contrainte** : 0 px de débordement de 320 à 1280, à quatre tailles de texte,
  sur deux moteurs.
- **`buildFlowSVG` et son entourage** (`flowPaintState`, `bindSvgNav`, `bindFlowZoom`, `openFlowFull`,
  la contre-inversion sombre) — **repris tels quels**, augmentés de la seule zone « ⚡ À tout moment ».

---

## 6 · Plan de transition

Onze lots. **Chacun est livrable seul et mesurable seul.** L'ordre n'est pas négociable aux trois
premiers : ils préparent le terrain et réparent un défaut d'intégrité.

| Lot | Contenu | Préalable | Risque |
|---|---|---|---|
| **T0** | Scinder `AGENTS.md` : doctrine / journal des incidents — **NON FAIT**. La moitié « paliers auto-vérifiables » est ✅ **LIVRÉE** (`check-paliers.mjs`). | — | nul |
| ~~**T1**~~ | ✅ **LIVRÉ** — `stepTexts` archivé, classé `SESS_LOCAL`, absent de `shareSnap`. | — | faible |
| ~~**T2**~~ | ✅ **LIVRÉ** — « Noter l'heure » de **1829 → 1305 px** à 320, **1588 → 1101** à 390. | — | faible |
| ~~**T3**~~ | ✅ **LIVRÉ** — 172 → 46 px à 320, dérive de défilement **0 px** au dépliage. | — | moyen |
| ~~**T4**~~ | ✅ **LIVRÉ** — `scripts/audit-budget.mjs`, 3 budgets × 2 formats. Écrit AVANT T5, donc **rouge** sur le défaut qu'il couvre (0 étape visible à 320 × 640) : c'est la seule façon de savoir qu'il mesure quelque chose. | T3 | nul |
| ~~**T5**~~ | ✅ **LIVRÉ** — 1ʳᵉ étape de **721 → 525 px** à 320 × 640 et **611 → 453** à 390 × 844 ; le rail perd sa numérotation en session (une séquence qui se lirait à l'envers serait pire que pas de séquence). Un témoin d'`audit-partage` a dû être REFAIT : son montage (`scrollTo(0,0)` = « il regarde ailleurs ») était périmé par le réordonnancement même. | T3, T4 | **élevé** |
| **T5b** | Fusionner la rangée de commandes et le quai (décision D1). **⛔ DÉFINITIVEMENT BLOQUÉ EN L'ÉTAT, re-mesuré après T8/T9** : rangée **267 px** + quai **243 px** = **510 pour 320** sans aucun minuteur armé, **591** avec un minuteur (quai à 324). Le lot T8 a bien libéré « Se repérer » (313 → 267), mais **l'hypothèse du plan — « l'axe libère la rangée » — était fausse dans son ampleur** : il manque encore 190 à 271 px. Et compléter T8 l'AGGRAVE (axe à trois crans : 336 + 243 = 579). La fusion ne redeviendra arbitrable que si un contrôle QUITTE la zone de crise — décision de conception, pas d'ingénierie. | — | **élevé** |
| **T6** | **Modèle v4**. **✅ LIVRÉ CÔTÉ MODÈLE ET CÔTÉ RENDU** : `v3ToV4`/`v4ToV3` purs et réversibles, détection dans `migrate()`, et surtout **l'ITEM est devenu la source** (`b.items[]`, `b.steps[]` réduit à un miroir écrit pour les clients antérieurs) — 48 sites de lecture portés par `stepsOf`, 12 sites d'écriture par `bItems`/`setStepStr`/`syncSteps`. **RESTE** : l'export ne propose pas encore le choix v4/v3, le partage, LUI, emporte déjà `items` — ils vivent DANS `blocks`, qui est sur la liste blanche du serveur : rien à rejouer côté SQL, vérifié plutôt que supposé. | T0 | **élevé** |
| **T7** | Éditeur v4. **◐ PARTIELLEMENT LIVRÉ** : « ×2 » (`dual`, AC 120-71B §5.2.2.5) ET « ★ mémoire » de bout en bout — bascule dans l'éditeur, effet en lecture, persistance, survie à l'export. **RESTE** : `phase` seul, qui ne prend son sens qu'avec le decluttering (moitié non livrée de T8). | T6 rendu ✅ | moyen |
| **T8** | Axe de densité + page SFAR + onglet Schéma. **◐ PARTIELLEMENT LIVRÉ** (deux crans, trois onglets, « Se repérer » sorti de la rangée). **⛔ LE CRAN « UNE ÉTAPE » EST BLOQUÉ PAR L'ARITHMÉTIQUE, mesuré le 31/07/2026** : un troisième segment porte l'axe de 151 à **220 px**, donc la rangée de commandes de 267 à **336 px pour 320 disponibles** — elle s'enroulerait en PERMANENCE sur le plus petit écran servi, en pleine zone de crise, là où la doctrine tient la hauteur pour un coût permanent. À 360 : 372 pour 360. Elle ne tient qu'à partir de ~380 px, et un contrôle qui n'existe qu'au-delà d'une largeur est exactement ce que la v4.31.0 refuse (constance positionnelle). **VOIE RECOMMANDÉE, qui ne touche pas la rangée** : garder l'entrée actuelle du lecteur (bouton de la carte de bloc) et le rendre EN LIGNE au lieu d'un overlay — « le lecteur cesse d'être une surface » sans élargir quoi que ce soit. Coût : reprise d'`audit-lecteur` et de la règle de partage « lecteur ouvert refuse la navigation distante ». | T5, T6 | **élevé** |
| **T9** | **R4 ✅ LIVRÉ** : bibliothèque unique, type en filtre à trois crans (« Tout » par défaut), une TROISIÈME configuration `renderAll` plutôt qu'une fusion. **+ RENOMMAGE SQL** `fiches` → `cognitive_aids`, `fiche_notes` → `aid_notes` : bloc idempotent en tête de `schema.sql` + vues de compatibilité `security_invoker` pour les clients 4.x. **⚠ REJOUER `schema.sql` AVANT de publier le client.** | T8 | moyen |
| **T10** | **Couches CSS (`@layer`) + 4 coques de fenêtres**, sans aucun changement visuel. | — | moyen |
| **T11** | **Réécrire la doctrine.** `AGENTS.md` ne décrit plus le produit : six champs disparaissent, quatre surfaces deviennent trois, huit règles nouvelles entrent (§ 4), et **au moins six règles existantes sont rouvertes** — parcours ①②③, chapeau jamais replié, palier du cockpit, bascule Guidé/Statique, `#id` pour la géométrie, séparation ECP/ECAM (D1). | après T8 | **élevé s'il est fait en dernier** |
| **T12** | **Réécrire `AI_PROMPT`.** Il décrit le format v3 : `notForget`, `confirmation`, `verify`, `posology`, `differentials` n'existent plus ; `role`, `level`, `memory`, `dual`, `phase`, `concl` sont inconnus de lui. Une IA produirait aujourd'hui un JSON que l'import v4 refuserait. | T6 | moyen |
| **T13** | **Correctifs J0 restants** : enrichir les deux fiches d'exemple au format v4 (J0-D1), réduire l'écran de bienvenue (J0-D5), snackbar → bandeau système (J0-D6). Petits, indépendants, gain de compréhension immédiat. | T6 pour les fiches | faible |

### T14 — Retrait du mode lecteur (décidé le 31/07/2026, préparé, NON exécuté)

**Décision de l'auteur, sur mesures** : le lecteur ne gagne qu'à 320 px (63 % de l'écran aux étapes
contre 36 % pour la carte de bloc, 5 étapes contre 3) et **perd à 390** (47 % contre 59 %) ; sa
justification d'origine — « un item à la fois » — a été abandonnée par sa propre doctrine en
v4.28.0 (Degani & Wiener : perdre sa place est un mode de défaillance premier) ; et le cas qui la
motivait le mieux (McEvoy 2014, un seul appareil) se résout en **tendant le téléphone**, sans mode
dédié.

**Ampleur mesurée** : ~180 références — 213 lignes de JS (section + 4 auxiliaires), 51 règles CSS,
le balisage `#readerMode`, 2 entrées du menu ⋯, le bouton `[data-ovreader]` de la carte de bloc,
l'entrée de `_histBackAction`, `state.readerI`.

> #### ⛔ PRÉALABLE OBLIGATOIRE — trouvé en tentant l'excision, puis annulée
>
> **`rmResume` est le SEUL site qui draine la file `Share._defer`.** Or cette file ne reçoit pas
> que des évènements du lecteur : `SHARE_APPLY` classe **`verify` et `gap` en `'deferred'`**, et
> la ligne `if(mode!=='live')this._defer.push(e)` les y range indépendamment de lui. Retirer le
> lecteur sans re-loger le drain laisserait donc la trace do-verify d'un hôte **en file pour
> toujours** chez l'invité.
>
> **ET C'EST DÉJÀ UN DÉFAUT AUJOURD'HUI, indépendamment du retrait** : le drain n'existe que dans
> `rmResume`, c'est-à-dire **uniquement si quelqu'un ouvre le lecteur puis touche « reprendre »**.
> Un invité qui n'ouvre jamais le lecteur ne reçoit jamais les `verify`/`gap` de l'hôte — le
> régime `deferred` promet « attend un geste LOCAL » et n'attend en réalité qu'un geste du
> lecteur. C'est la même famille que le défaut consigné en v4.55 (« aucun site du fichier ne
> drainait `_defer` »), à moitié réparée.
>
> **À FAIRE AVANT LE RETRAIT** : donner à `deferred` un drain qui soit vraiment un geste local
> (cochage, avancement, ou entrée dans la vue), avec son témoin — et vérifier qu'il est capable
> d'échouer sur le cas « l'invité n'ouvre jamais le lecteur ».

**À NE PAS EMPORTER AVEC LE LOT (règle 14)** : `scripts/audit-lecteur.mjs` porte **14** contrôles
dont **6 n'ont rien à voir avec le lecteur** — l'ordre du menu ⋯, la normalisation de ses
séparateurs, ses icônes distinctes, et les **trois de la PILE DE RETOUR** (titre de l'origine sur
le « ‹ », garde anti double-tap de 700 ms, repli vers la bibliothèque). Le harnais se TAILLE, il ne
se supprime pas. Le **mode moniteur** partage la coquille CSS du lecteur (z 92) : ses règles ne
partent pas non plus.

**Perte assumée, chiffrée** : à 320 px, la part d'écran consacrée aux étapes retombe de 63 % à
36 %, et la cible de réponse de 72 px devient une case de 44. Bornée au plus petit écran servi.

---

**T11 et T12 ne sont pas de la documentation en fin de chantier.** `AI_PROMPT` est **un contrat
exécutable** — `audit-prompt.mjs` en extrait le schéma et le passe par `migrate()`. Il doit donc
suivre T6 **immédiatement**, sinon toute fiche générée par IA devient irrecevable en silence. Et
`AGENTS.md` est ce que lit le prochain contributeur : le laisser décrire un produit disparu, c'est
répéter exactement le défaut mesuré au § 2 de l'audit structurel (trois affirmations fausses
trouvées sans les chercher).

**Serveur** : T6 exige de rejouer `supabase/schema.sql` (liste blanche des champs + `SHARE_KEEP`).
Le précédent `discriminant` (v4.70.0) montre que c'est l'étape qu'on oublie.

---

## 7 · Garde-fous à écrire

| Harnais | Ce qu'il mesure | Échoue si |
|---|---|---|
| `audit-budget.mjs` | chrome permanent, étapes visibles au démarrage, part de la pile d'actions | chrome > 30 % à 320 · 0 étape visible · actions > 25 % (bloc ≥ 4 items) |
| `audit-filtres.mjs` | compteurs et état désactivé des chips | un chip **actif** est `disabled` · un compteur inclut son propre filtre |
| `audit-graphe.mjs` | boucles vs convergences, 4 niveaux d'imbrication | une convergence annoncée « ↺ » · un bloc déborde à 320 |
| `audit-integrite.mjs` | `stepTextFromKey` après édition | la même clé désigne un autre item |
| `check-paliers.mjs` | paliers déclarés vs paliers réels dans les media queries | un palier non déclaré · un palier déclaré absent |
| extension d'`audit-prompt` | `AI_PROMPT` contre le schéma v4 | un champ v4 absent du prompt |
| `check-lex.mjs` | `AC_LEX` est la source unique | un glyphe ou un libellé de registre écrit en dur hors de la table |

Rappel de méthode du dépôt : **chaque harnais doit être vérifié CAPABLE D'ÉCHOUER** (défaut
réintroduit, rouge constaté, fichier restauré à l'octet).

---

## 8 · Décisions — toutes tranchées

| # | Question | **Décision** | Ce qu'elle engage |
|---|---|---|---|
| **D1** | Fusionner la rangée de commandes et le quai | ✅ **OUI, on fusionne** | −53 px permanents (177 → 124, soit **27,7 % → 19,4 %** à 320 px). **Rouvre la séparation ECP/ECAM de la v4.25.0** : elle est *matérielle* chez Airbus (deux panneaux physiques), pas sur un téléphone. Devient le lot **T5b**, prototypé et mesuré **seul**. |
| **D2** | Organisation par défaut de l'accueil | ✅ **A→Z conservé** | La recherche reste au-dessus, le répertoire alphabétique en dessous. Le rail A→Z reste sur téléphone (indispensable : 31 écrans de liste à 200 aides), disparaît en tablette. |
| **D3** | Zone du pouce — R4 déplace le filtre de type du bas vers le haut | ✅ **OUI, on modifie** | La piste de filtres est **ancrée en bas** sur téléphone, sous la liste. Elle retrouve la zone atteignable à une main (la tab bar était centrée à y = 765 sur 844) sans réintroduire d'onglet. **À mesurer** : la convention « les filtres se lisent avant la liste » est renversée. |
| **D4** | Trois axes de filtre sur téléphone | ✅ **OUI** — la provenance quitte la piste | Elle passe dans un **sélecteur d'en-tête** (comme le scope actuel) ; type et catégorie restent sur la piste. Sur tablette et ordinateur, les trois descendent en colonne latérale (C12). La provenance reste **écrite sur chaque rangée**, jamais dépendante d'un filtre. |
| **D5** | Seuils du budget d'écran | ✅ **À RECALIBRER après T5** | Les valeurs 30 % (chrome) et 25 % (actions) sont des points de départ. Le harnais `audit-budget.mjs` est écrit dès T4 mais **ses seuils sont fixés après T5**, sur ce que la nouvelle structure permet réellement — sinon on calibre sur l'ancienne. |
| **D6** | Texte des étapes dans les sessions **synchronisées** | ✅ **`data: {v:2, enc:<blob>}`** — chiffré | Voir l'encadré ci-dessous. |
| **D7** | Compte rendu enrichi et périmètre réglementaire | ✅ **OK** — repasser la grille du § 2 de `deploiement-et-conformite.md` avant T8 | Il **recopie** et ne **déduit** rien : la qualification ne devrait pas bouger. À **confirmer**, pas à supposer. |
| **D8** | Deux éditeurs → une coque | ✅ **OUI**, deux corps distincts | Voir l'encadré ci-dessous. |

### ⚠ Collision d'étiquettes, et cinq décisions orphelines

**Trouvé à la relecture des passages narratifs, et c'est le défaut le plus grave de ce document.**
Le **premier audit** ([`audit-j0.md`](audit-j0.md) § 4) porte lui aussi **huit décisions numérotées
D1–D8**, sans aucun rapport avec celles ci-dessus. Deux séries homonymes dans le même dossier : un
implémenteur qui lit « D1 » ne sait pas laquelle. Elles sont donc désormais préfixées **J0-D1…J0-D8**.

Pire : **transition-v4 annonçait « plus aucune décision en suspens » alors que cinq d'entre elles
n'étaient reprises nulle part.** Voici leur sort, explicitement :

| Décision du 1ᵉʳ audit | Sort |
|---|---|
| **J0-D1** — enrichir les deux fiches d'exemple (posologie, complication, `onDue`, `discriminant`, une étape △ au premier écran) | **À FAIRE** — et le lot est désormais **T13**. Elles doivent de toute façon être réécrites au format v4 |
| **J0-D2** — la pilule de mode change de mot (« ▫ Lecture » avant démarrage) | ✅ **Résolu par la structure v4** : la pilule « ■ CRISE » disparaît ; c'est le **quai** qui énonce l'état (« ● Session », « ▲ Exercice », « ▪ Vous suivez »), et il ne l'énonce qu'une fois la session démarrée |
| **J0-D3** — le chevron du quai nomme ce qu'il cache | ❌ **Sans objet** : le constat qui la motivait était faux — l'information existe déjà dans le flux (`.rt-collapsed`) |
| **J0-D4** — « Consulter » entier sous 560 px | ✅ **Résolu autrement** par l'axe de densité : entier dès 320 px |
| **J0-D5** — réduire l'écran de bienvenue au seul paragraphe réglementaire | **À FAIRE** — lot **T13** |
| **J0-D6** — snackbar des exemples → bandeau système (elle masque 60,7 % du CTA) | **À FAIRE** — lot **T13** |
| **J0-D7** — extraire **`AC_LEX`** (une table `{glyphe, nom, conséquence}`, quatre consommateurs) | **À FAIRE** — **habilitant** : la légende des registres, les états vides et la porte « ＋ » en dépendent. Rattaché à **T7** |
| **J0-D8** — corriger `AGENTS.md` | ✅ **Devenu le lot T11** (réécriture complète) |

**Ce que cela révèle sur la méthode** : un document de transition qui consolide *ses propres*
décisions et oublie celles du document qu'il consolide. C'est le même défaut que la Cause V décrit
pour `AGENTS.md`, une troisième fois.

### D6 — ce que la question posait, en clair

**Le problème.** Le lot T1 fait archiver par la session le **texte des étapes cochées**, pour que le
compte rendu cesse de se décaler quand la fiche est éditée après coup. Mais depuis la v4.54.0, les
sessions peuvent être **synchronisées** vers le serveur (sur opt-in). Y mettre le texte, c'est faire
**monter du texte clinique** vers le serveur — ce que la **règle 15** interdit pour le *partage*, mais
qui n'est pas couvert pour l'*historique*.

**Trois issues étaient possibles** : (a) chiffrer le texte avant de l'envoyer ; (b) garder les textes
**locaux** et accepter que le compte rendu se décale sur les autres appareils ; (c) ne plus
synchroniser les sessions du tout.

**Décision : (a).** Le champ `data` accepte **déjà** `{v:2, enc:<blob>}` — c'est exactement la porte
prévue pour ce cas en v4.54.0. Le serveur ne voit qu'un blob ; l'appareil déchiffre. Rien de clinique
n'est lisible côté serveur, et le compte rendu reste juste partout.

### D8 — « une coque, deux corps », en clair

**La coque** = tout ce qui entoure l'édition et qui est **identique** aux deux types : la barre, le
dépliant Identité (titre, discriminant, catégorie, bibliothèque, code, validation, état), l'indicateur
d'enregistrement, l'anneau d'annulation ↶, le volet de relecture, les versions, la porte « ＋ ».

**Le corps** = la zone centrale d'édition, et elle diffère parce que le **geste** diffère :

| | Corps d'une **procédure** | Corps d'une **référence** |
|---|---|---|
| Unité | l'`Item` structuré | le texte rédigé |
| Outils | niveau ⚠/△/—, ★ mémoire, ×2 double, ⏎ = item suivant, poignée ⠿, phase du bloc, cible « puis → » | gras, titres, encadrés, tableaux, images, documents |
| Discipline | télégraphique, **une action par ligne** | prose, tableaux de doses, sources |
| Garde-fous | ≤ 110 caractères, ≤ 7 items, ≤ 2 items colorés par bloc | source datée obligatoire |

**Les fusionner serait une erreur** : écrire une procédure, c'est découper en gestes cochables ;
rédiger une référence, c'est écrire un document. Un éditeur unique imposerait les contraintes de l'un
à l'autre — soit une procédure devenue prose, soit une référence hachée en items.

## 9 · Angles morts — ce que rien ici ne prouve

### ⚠ La géométrie des maquettes n'est pas une preuve — mesuré le 31/07/2026

Question posée à la livraison du lot T8 : « comment ça se fait que ça tenait dans les maquettes ? »
**Ça n'y tenait pas.** La maquette n'avait simplement jamais été mise dans les conditions réelles,
et l'écart se chiffre sur trois axes.

| | maquette `proto-r4.html` | application |
|---|---|---|
| largeur du téléphone dessiné | **390 px, quelle que soit la fenêtre** (`.phone{max-width:390px}`) | plancher servi **320 px** |
| corps de l'axe et de « Consulter » | **12 px** | **13,5 px** (palier de l'échelle fermée, v4.71.1) |
| hauteur de « Consulter » | **38 px** | **44 px** (règle 9, cibles de crise) |
| objets portés | axe + 1 bouton | axe + **`.ctrl-sp` (22 px)** + bouton **avec son icône ⤢** |

**Le défaut d'instrument est le premier, et il est entièrement de mon fait** : redimensionner le
navigateur à 320 px ne rétrécit pas le téléphone dessiné — le mock reste à 390. J'ai donc regardé
une maquette « à 320 » qui n'y était jamais.

**Et même ainsi, elle ne tenait pas** : sa rangée exige **326 px** de largeur intrinsèque. À 390
elle passe ; à 320 elle déborde de 6 px — avec des corps de 12 px et des cibles de 38 px que la
doctrine interdit. Une fois remise aux normes du dépôt (13,5 px, 44 px, l'icône ⤢ ajoutée en
v4.57.0 qui avait déjà coûté 4 px, et l'écart `.ctrl-sp` que la v4.43.0 déclare ne pas être un
poste d'économie), on retombe sur les **336 px** mesurés dans l'application.

**RÈGLE À RETENIR POUR TOUTE MAQUETTE FUTURE** : une maquette prouve une INTENTION de conception,
jamais une géométrie. Pour qu'elle prouve une géométrie il lui faut, au minimum, la largeur du
plancher servi, l'échelle typographique fermée et les planchers de cible — c'est-à-dire les trois
choses qu'une maquette est justement tentée de relâcher pour « montrer l'idée ». Les prototypes de
cet audit sont fiables sur les FLUX et les DÉCISIONS ; ils ne le sont pas sur les largeurs.


1. **Le partage n'a jamais été joué.** Aucun serveur joint dans tout l'audit : jointure, latence,
   rattrapage de backlog, passation de la main, « continuer seul » — **non mesurés**. C'est le plus
   gros trou du dossier, et `dual` en dépend entièrement.
2. **Aucun utilisateur réel.** Tout est mesuré en pixels et en gestes. Que l'ordre de C1, l'axe de
   densité ou R4 soient plus **compréhensibles** reste une hypothèse.
3. **R4 est la rupture la plus visible** et la moins testée : on retire un repère de navigation
   permanent.
4. **T6 n'a pas été prototypé en volume.** L'aller-retour v3 ⇄ v4 est raisonné, pas exécuté.
5. **Pas d'iOS réel, pas de lecteur d'écran, pas de `forced-colors`.**
6. **Le cran 3 n'a été éprouvé qu'à deux niveaux d'imbrication réels** (le graphe en porte quatre,
   mais sur des blocs courts).
7. **La colonne structure de l'éditeur n'a été testée qu'à 10 blocs.**

**L'instrument qui manque, et qui existe déjà dans l'application** : le **mode exercice**. C'est le
seul moyen de savoir si ces décisions tiennent sous stress, et il devrait servir à valider T5, T8 et
T9 avant de les considérer comme acquis.

---

## 10 · Couverture — chaque proposition et son lot

**Vérification faite en réponse à la question « le plan couvre-t-il tout ? ». La réponse était non :**
le lot **T5b** était cité deux fois sans exister dans le tableau, et **quatre constats du premier
audit n'étaient rattachés à aucun lot**. Corrigé ci-dessous. La matrice est exhaustive : toute
proposition de tout le dossier y figure, avec son lot ou la raison de son abandon.

### Les 15 constats du premier audit

| Constat | Lot |
|---|---|
| 1 · l'état vide des protocoles ne dit pas la différence | **T9** — R4 réécrit les deux états vides |
| 2 · aucune légende des registres en lecture | **T8** — la carte d'action la porte, inconditionnelle (A4) |
| 3 · les fiches d'exemple n'exercent pas la doctrine | **T13** (J0-D1) |
| 4 · les abréviations du plan n'ont aucune clé (`→ ↺ ▪fin`) | **T8** — clé en pied de l'onglet « Parcours » |
| 5 · l'état vide des aides n'enseigne rien | **T9**, alimenté par `AC_LEX` (**T7**) |
| 6 · le minuteur est invisible sur téléphone | ❌ **Constat retiré** (mesure fausse) — rien à faire |
| 7 · la snackbar masque 60,7 % du CTA | **T13** (J0-D6) |
| 8 · « Lecteur » / « Vérifier » | ✅ **sans objet en v4** — deviennent des crans |
| 9 · le badge « △ À compléter » accuse sans dire où | **T7** — volet de relecture de l'éditeur |
| 10 · la pilule « ■ CRISE » avant toute session | ✅ **résolu par la structure** (J0-D2) : c'est le quai qui énonce l'état |
| 11 · le menu ⋯ porte 12 rangées | **T8** — l'axe de densité en absorbe quatre (lecteur, statique, se repérer, schéma). **À re-mesurer après T8.** |
| 12 · « Cons. » sur toute la gamme téléphone | ✅ **résolu autrement** (J0-D4) : entier dès 320 px |
| 13 · l'écran « Bienvenue » | **T13** (J0-D5) |
| 14 · sept symboles, aucun glossaire | **T8** (constats 2 et 4). **Pas de page « glossaire »** — écartée : personne ne l'ouvrirait |
| 15 · la porte « ＋ » est le meilleur professeur, enfermée dans l'éditeur | **T7** — extraction d'`AC_LEX` |

### Les chantiers et ruptures

| Origine | Devient |
|---|---|
| CH1 (action devant orientation) | **T3** + **T5** |
| CH2 (trois surfaces) | **T8** — sous la forme de l'axe de densité, pas du sélecteur d'origine |
| ~~CH3~~ (structure compatible v3) | ✅ **caduc** — contenu dans T6 |
| CH3′ (format v4) | **T6** |
| CH4 (`@layer`) | **T10** |
| CH5 (scinder la doctrine) | **T0**, puis **T11** pour la réécriture |
| CH6 (journal à portée de pouce) | **T2** |
| CH7 (budget d'écran) | **T4** |
| R1 · R2 · R3 (format, rôles, `notForget`) | **T6** |
| R4 (bibliothèque unique) | **T9** |
| R5 (sept surfaces → trois) | **T8** |
| R6 (22 fenêtres → 4 coques) | **T10** |
| R7 (sessions v3 conservées) | **T6** — contrainte, pas travail |
| R8 (`AGENTS.md` scindé) | **T0** |
| É2 · É3 · É5 (épuration de la carte) | **T8** |
| É4 (le quai n'énumère plus la session) | **T5b** — N7 retirée, l'arbitrage disparaît avec elle |
| Cause III bis (clés d'index) | **T1** |

### Les décisions

| Décision | Lot |
|---|---|
| **D1** fusion des deux bandes | **T5b** |
| **D2** A→Z conservé | aucun travail — statu quo confirmé |
| **D3** piste de filtres en bas | **T9** |
| **D4** provenance en sélecteur d'en-tête | **T9** |
| **D5** recalibrer les seuils | **T4**, seuils fixés **après T5** |
| **D6** textes de session chiffrés | **T1** — `data: {v:2, enc:<blob>}` |
| **D7** grille réglementaire du compte rendu | **avant T8**, préalable bloquant |
| **D8** une coque, deux corps | **T7** |
| **A10** le schéma en 3ᵉ onglet | **T8** — `buildFlowSVG` repris tel quel |

### Les garde-fous

| Harnais | Écrit dans |
|---|---|
| `check-paliers.mjs` | **T0** |
| `audit-integrite.mjs` | **T1** |
| `audit-budget.mjs` | **T4** (seuils fixés après T5) |
| `check-lex.mjs` | **T7** |
| `audit-graphe.mjs` | **T8** |
| `audit-filtres.mjs` | **T9** |
| extension d'`audit-prompt` | **T12** |

### Ce qui reste volontairement hors plan

- **Les cinq propositions écartées par contrainte** (tutoriel, fiches supplémentaires, protocole
  d'exemple, coach mark, page glossaire) — § 5 de l'audit J0.
- **Les trois retraits d'épuration écartés** (fusion vue comme épuration, retrait du chapeau,
  réduction à deux crans) — `proto-epure` § R.
- **Le schéma dessiné dans `proto-r4`** : maquette jetable, `buildFlowSVG` est repris tel quel.

---

## 11 · Index des livrables

| Fichier | Contenu |
|---|---|
| [`audit-j0.md`](audit-j0.md) | 15 constats J0, parcours chronométrés, décisions D1–D8 du 1ᵉʳ audit |
| [`audit-j0-maquettes.html`](audit-j0-maquettes.html) | 8 maquettes (légende, plan, états vides, quai, pilule, seeds, snackbar, outils) |
| [`audit-structurel.md`](audit-structurel.md) | 6 causes, 7 chantiers, modèle v4, parties II et III |
| [`audit-structurel-maquettes.html`](audit-structurel-maquettes.html) | 8 maquettes structurelles |
| [`proto-r4.html`](proto-r4.html) | **Interactif** — accueil unifié, axe de densité, graphe à 4 niveaux, journal, compte rendu, complications, partage, exercice |
| [`proto-large.html`](proto-large.html) | Tablette et ordinateur ; éditeurs procédure et référence ; `dual` et `phase` expliqués |
| [`proto-epure.html`](proto-epure.html) | Diagnostic de densité et les 5 retraits, avec leurs gains mesurés |
| **`transition-v4.md`** | **Ce document** |

### Cohérence entre les fichiers — passe faite

Six incohérences relevées entre les documents et **corrigées** ; elles venaient toutes de
corrections successives dont les fichiers antérieurs n'avaient pas été prévenus.

| # | Incohérence | Correction |
|---|---|---|
| 1 | **CH2** (audit structurel, partie I) et les maquettes **S3** / **S7** proposaient le sélecteur « Agir / Se repérer », abandonné en partie III | Bandeau **SUPERSÉDÉ** posé aux trois endroits, renvoyant à l'axe de densité |
| 2 | **C1** (audit J0) annonçait la légende « sur la ligne PARCOURS, 0 px » — contredit par la décision **A4** | Encadré de mise à jour : elle vit dans la carte, inconditionnelle, 23 px assumés |
| 3 | **É1** de `proto-epure` présentait encore le retrait de la légende comme retenu | Ligne barrée, marquée **ABANDONNÉ** avec le motif |
| 4 | **É4** de `proto-epure` annonçait « 1 minuteur ▾ » alors que l'implémentation retenue est « 1 minuteur · 1 compteur ▾ » | Corrigé, avec l'arbitrage explicité (constat 6 de l'audit J0) |
| 5 | **C8** (audit J0) proposait de renommer « Lecteur » / « Vérifier » — deux boutons qui **n'existent plus** en v4 | Marqué **sans objet en v4**, la mesure étant conservée |
| 6 | **D4** (audit J0) restait « à trancher » alors que l'axe de densité l'a résolu | Marqué **résolu autrement** : « Consulter » tient entier dès 320 px |

### Seconde passe — parties I et II relues

Sept incohérences de plus, dont **deux de fond** :

| # | Incohérence | Correction |
|---|---|---|
| 7 | **CH3** (« l'étape devient une structure **sans casser l'export v3** ») était encore présenté comme un chantier vivant, alors que v3 est abandonné (A1) | Marqué **CADUC**, entièrement contenu dans T6 |
| 8 | Le tableau des règles à rouvrir recommandait toujours « structure interne, chaîne conservée (CH3) » | Barré → **tranché : format v4** |
| 9 | **Le même tableau ne contenait pas la séparation ECP/ECAM**, que D1 rouvre pourtant | Ligne ajoutée, avec sa mesure et son lot (T5b) |
| 10 | **§ 5 listait QUATRE points d'écriture uniques** (`migrate` manquait) alors que § II.6 du **même document** en annonçait cinq | Corrigé à cinq, l'écart signalé sur place |
| 11 | **§ 6 « Ordre de livraison »** et **§ II.7 « Ordre proposé »** ignoraient les lots T11 (doctrine) et T12 (prompt IA) et traitaient CH3′ comme conditionnel | Les deux marqués **SUPERSÉDÉS** par le § 6 de ce document |
| 12 | **§ II.2** annonçait le sélecteur « agir ou se repérer ? », abandonné en partie III | Encadré de mise à jour : axe de densité, cran 3 à **trois** vues (A3 + A10) |
| **13** | **§ II.2 et § II.6 affirmaient — deux fois — que les deux bandes ECP/ECAM « ne bougent pas »**, ce que **D1 contredit frontalement** | Les deux passages corrigés ; l'invariant conservé est reformulé : ce n'est pas la *séparation* qui est intangible, c'est que **l'état ne disparaisse jamais** |

**La plus importante est la 13** : un invariant affirmé deux fois dans le document, et devenu faux par
une décision prise ailleurs. C'est exactement le mode de défaillance que la Cause V décrit pour
`AGENTS.md` — une doctrine qui affirme ce qui n'est plus vrai —, reproduit ici par moi, dans le
document qui le dénonce.

### Troisième passe — passages narratifs et vérification chiffrée

| # | Incohérence | Correction |
|---|---|---|
| **14** | **Collision d'étiquettes** : le premier audit porte lui aussi des décisions **D1–D8**, sans rapport avec celles de ce document | Les siennes préfixées **J0-D1…J0-D8** ; table de correspondance ajoutée au § 8 |
| **15** | **Cinq décisions du premier audit n'étaient reprises nulle part**, alors que ce document annonçait « plus aucune décision en suspens » | Sort explicité pour les huit ; lot **T13** créé ; `AC_LEX` rattaché à T7 |
| 16 | **§ III.2** écrivait que le schéma « garde une entrée à part », contredisant **§ II.2** (« Échelle et Schéma → deux **affichages** de SE REPÉRER ») | Tranché par l'auteur (**A10**) dans le sens du § II.2 : 3ᵉ onglet du cran « Toute la fiche » |
| 17 | « **deux vues** » pour le cran 3 subsistait après A10, qui en porte **trois** | Corrigé aux trois occurrences |
| **18** | **L'en-tête de lecture enroulait sur petit écran** — signalé à l'usage sur l'écran hôte, vérifié sur les quatre coques | Corrigé, cf. encadré |
| 19 | **Le quai de l'écran hôte enroulait à 320 px** (« ⇄ 2 · 1 minuteur · **2 repères** ▾ ») : maquette statique non touchée par l'épuration É4 | Aligné sur É4 seule (N7 retirée) : « ⇄ 2 · 1 minuteur ▾ » |

#### Défaut 18 — l'en-tête de lecture, mesuré

Signalé sur l'écran **hôte**, mais présent sur **les quatre** coques de lecture du prototype. Il ne
se voyait pas avec le titre court de la démonstration (« Arrêt cardiaque ») ; avec le titre de la
fiche **réellement livrée** — « Anaphylaxie (choc anaphylactique) » :

| | 320 px | 390 px |
|---|---|---|
| avant | **91 px**, titre sur **3 lignes** | 67 px, 2 lignes |
| après | **53 px**, une ligne, ellipse | **53 px** |

**Cause** : `flex:1` **sans `min-width:0`** — l'élément ne peut pas rétrécir sous la largeur de son
contenu, donc il **enroule** au lieu de s'ellipser (`text-overflow` était bien `clip`). C'est le
patron que `proto-large.html` appliquait déjà (`.bar .t`) et que `proto-r4.html` avait perdu : deux
prototypes du même dossier, deux comportements.

**Et le correctif porte une règle** : c'est **le titre qui cède, jamais le discriminant**. La
doctrine du champ (v4.70.0) veut qu'il soit « affiché là où le titre se tronque, dans sa propre
pilule, jamais dans la chaîne qui se coupe » — deux titres identiques sur un écran de crise sont un
piège, et c'est lui qui les sépare. Il est donc `flex:none`, comme le retour et le menu. Vérifié :
pilule « ADULTE » intacte à 59 px dans les quatre configurations.

#### Passe sur les autres prototypes — même famille de défauts

Le défaut 18 étant un patron, les quatre autres fichiers ont été balayés : **analyse statique**
(règles portant `flex:1` sans `min-width:0`) puis **épreuve dynamique** (injection d'un contenu
réaliste long, mesure de l'enflure du conteneur).

| # | Fichier · élément | Mesuré | Verdict |
|---|---|---|---|
| **20** | `proto-r4` — **libellé de minuteur** dans le panneau du quai | 49 → **66 px** (+17) | **Défaut.** Corrigé en reprenant l'anatomie **K7** de l'application (v4.70.0) : le nom occupe sa propre ligne, les réglages dessous |
| **21** | `proto-large` — **rangée de bibliothèque** en colonne latérale (244 px) | 36 → **57 px** (+21) | **Défaut.** Un nom de bibliothèque partagée est du contenu d'organisation : il s'ellipse |
| **22** | `proto-large` — **colonnes « parcours » et « structure »** (260–300 px) | 39 → **53 px** (+14) | **Défaut.** C'est la colonne dont `AI_PROMPT` dit qu'elle « mord le plus fort » et pour laquelle il exige des titres de 2 à 4 mots : elle **tronque** |
| — | `proto-r4` — onglets du cran 3 | 36 → 52 px | **Pas un défaut** (libellés fixes, aucun contenu utilisateur) — `nowrap` posé par robustesse à 130 % |
| — | `proto-epure`, `audit-j0-maquettes`, `audit-structurel-maquettes` | 0 | **Sains** |

##### Ce qu'il ne fallait PAS « corriger », et c'est le point important

Deux éléments enflent aussi — **les rangées et les tuiles du répertoire** (+23 et +21 px) — et ce
**n'est pas un défaut** : l'application borne délibérément le titre à **trois lignes** avec ellipse,
sur demande utilisateur explicite (« 2 lignes tronquaient trop pour reconnaître la fiche »). Les
« réparer » aurait **détruit** un comportement décidé.

D'où la formulation exacte de la règle, qui sépare deux natures de rangée :

> **N9 — Dans une rangée de CHROME à hauteur contrainte** (en-tête, quai, barre, colonne latérale,
> carte d'état), **l'élément qui cède porte `min-width:0` et s'ellipse ; les autres sont `flex:none`.**
> **Dans une rangée de LISTE**, l'enroulement est permis, **borné** et décidé (3 lignes + ellipse).
> Sur l'en-tête de lecture, c'est **le titre** qui cède, **jamais le discriminant**.

**Bilan des passes : vingt-deux incohérences et défauts trouvés et corrigés.**

**La 15 est la plus grave** — voir l'encadré du § 8.

**Ce que ces trois passes n'ont pas fait** : une relecture exhaustive, ligne à ligne, des 89 Ko. La
méthode a été : recherche ciblée sur les formulations que je savais avoir changées, puis lecture des
sections **structurantes** (chantiers, règles, ordres, invariants), puis vérification **chiffrée** des
énoncés répétés d'un fichier à l'autre (« trois surfaces », « quatre coques », « cinq points
d'écriture », numéros de lots et de règles).

**Ce qui peut encore contenir des restes** : les passages purement **descriptifs** — causes, mesures,
encadrés de méthode. Ils décrivent l'état mesuré de **v4.79.0** et n'engagent pas la cible, donc leur
risque est faible ; mais je ne prétends pas qu'ils soient propres.
