# Lot v5.39 — le sommaire d'un PDF joint, optionnel (A418) ; filtre de catégorie par nom, connexion par Entrée (A419)

> Fichier normatif, suite de [`lot-v5-38.md`](lot-v5-38.md) (A400-A417). Les numéros A sont des adresses :
> ne jamais renuméroter. Demande de l'auteur du 28/09/2026.

## A418 — le sommaire d'un PDF, comme celui d'un protocole, mais qu'on peut replier

**Demande.** « S'il y a un sommaire, faire un sommaire cliquable en sticky ou en sidebar selon la largeur d'écran, comme
pour le texte des protocoles », puis « repliable, car ça doit rester une option », et « repliable en un petit bouton ».
Jusqu'ici (A392), les signets d'un PDF s'ouvraient dans une feuille `openPickMenu`, qui se refermait à chaque choix.

**Deux régimes, au seuil des protocoles (`mqReadWide`, 1000 px).** Le sommaire n'existe que si le PDF a des signets
(`getOutline`, trois niveaux, 200 entrées au plus, titres posés par `textContent`).
- **Dès 1000 px : une colonne à gauche des pages** (`.pdf-card.toc-side`, grille `--col-orient` + pages), sur
  l'ambiance, séparée par un filet. Elle est **ouverte d'office** et se **replie en un bouton ≡ de 40 px**
  (colonne de 56 px, `.toc-min`). Le bouton de la colonne dit ce qu'il fait (« Replier le sommaire », chevron ‹ ;
  replié, « Afficher le sommaire », ≡). L'appareil retient le choix (`ac-pdf-toc`, `localStorage`, simple
  confort d'affichage). Replier ou déplier élargit les pages : on remet à l'échelle en gardant la même place dans le
  document.
- **Sous 1000 px : une bande sous la barre**, bornée à 56 % de la hauteur. Elle est **fermée d'office**, s'ouvre par
  le bouton « Sommaire » (icône ≡, `aria-expanded`) et **se referme après un choix**, puisqu'elle prend la place du
  document. Le bouton quitte la rangée d'outils et monte sur la ligne du titre : à 390 px, avec lui, la rangée
  débordait (« Largeur » coupé, ⤓ hors de l'écran — défaut né en A392).
- En large, le bouton « Sommaire » de la barre est masqué : la colonne porte son propre bouton.

**Chaque titre porte son numéro de page**, et **la section en cours est en bleu** (registre du bloc courant,
`aria-current`) : dernier titre passé sous la ligne de lecture (haut du défileur + min(96 px, 20 %)), le dernier
visible en bas du document. Après un choix, c'est ce titre qui reste en cours tant qu'on n'a pas défilé
(`tocPin`), même si un titre voisin est sur la même ligne.

**On arrive sur le titre, plus en haut de sa page.** `pdfDestPos` lit la hauteur de la destination (XYZ, FitH, FitBH)
en plus de sa page, et `pdfPosY` la convertit par le viewport de la page. Cela vaut pour le sommaire et pour les
renvois internes du document (A392). **Au passage, un défaut de toujours** : les hauteurs des pages se lisaient par
`offsetTop` depuis la CARTE (premier ancêtre positionné), donc en comptant la barre. Chaque saut de la visionneuse
(liens, sommaire, occurrences d'une recherche, ouverture à une page) arrivait environ 60 px trop bas. `.pdf-scroll`
est désormais positionné, et les hauteurs se lisent depuis le défileur.

**Formes écartées.** Colonne permanente non repliable (demande explicite : le sommaire reste une option) ; bande
étroite ouverte d'office (elle mange la moitié du document au téléphone).

**Témoins** (section `audit-doctrine` « Page · A392 … », PDF fabriqué par Chromium) :
- à 1280 px, la colonne est ouverte, les numéros de page sont justes, la section en cours suit un choix ;
- repliée, il ne reste qu'un bouton de 56 px au plus, les pages s'élargissent, la position est gardée et le choix
  retenu ; la colonne se rouvre ;
- à 390 px, la bande est fermée d'office, s'ouvre sous la barre, n'a pas de bouton de repli et se referme après un
  choix qui fait défiler.

Ces contrôles échouent sur la version précédente, qui n'avait pas de `#pdfTocNav`.

## A419 (v5.39.1) — le filtre de catégorie retient un NOM ; Entrée envoie l'e-mail

**1. Signalé : « sur Toutes, en large, les filtres n'ont pas l'air de fonctionner tout le temps ».** Reproduit au banc.
L'id d'une catégorie dérive de son nom D'ORIGINE (`detCatId`, « Urgences » → `c-urgences`). Renommée (« Urgences
adultes » dans le Perso), elle garde cet id, que porte aussi « Urgences » d'une autre bibliothèque. Depuis la v5.18, le
filtre compare par NOM à travers l'union (A299), mais il retrouvait ce nom par « la première catégorie qui porte cet
id » (`_catFiltName`). Taper « Urgences » filtrait donc sur « Urgences adultes », et c'est cette rangée qui s'allumait.
Même défaut dans la feuille « Affichage », dont les pastilles portaient l'id.

**Correctif : `state.cat` retient le nom normalisé (`catKey` = `txNorm(nom)`)**, la clé que le filtre, la colonne
(une rangée par nom) et les pastilles utilisaient déjà pour regrouper. Plus aucune lecture ne passe par un id. Deux
suites nécessaires :
- **renommer** la catégorie filtrée fait suivre le filtre si plus aucune catégorie ne porte l'ancien nom. Sans cela,
  le filtre deviendrait invisible, ce que la doctrine interdit (« un filtre posé ne doit jamais être invisible ») ;
- **supprimer** une catégorie en déplaçant ses éléments reporte le filtre sur la catégorie cible.

Un id reste la bonne clé partout où l'on agit sur UNE catégorie précise (gestionnaire, sélecteur de l'éditeur,
déplacement) : il y est toujours lu avec sa bibliothèque (`catOf`, `catItems`).

**2. Signalé : à l'écran de connexion, Entrée dans le champ e-mail n'envoyait rien.** Le champ du code avait son geste
Entrée (A373), pas celui de l'adresse. Il a maintenant le même (`keydown` Entrée → le bouton, hors composition IME),
et `enterkeyhint="send"` pour que le clavier du téléphone affiche « Envoyer ».

**Témoins** (section `audit-doctrine` « Accueil · A419 … ») : deux homonymes au même id d'origine, chacune ne montre
que ses aides et n'allume que sa rangée, dans la colonne ET la feuille ; « Afficher » (Aides / Protocoles) sur « Toutes »,
avec une aide et un protocole d'une bibliothèque partagée, donne le bon type dans les cinq rangements (vérifié à la
demande de l'auteur : ce filtre n'avait pas le défaut, il ne passe par aucun id) ; Entrée dans le champ e-mail déclenche l'envoi
(appel réseau remplacé). Trois contrôles sur quatre échouent sur la v5.39.0 : le quatrième, la rangée Perso, passait
déjà par chance, puisque c'est elle que la recherche par id trouvait en premier.

## A420 (v5.39.2) — le temps des audits se MESURE : presque aucune attente n'est inutile

**Demande de l'auteur : « optimiser le temps des audits sans supprimer de choses », puis « ces temps sont-ils vraiment
inutiles ? méfie-toi des harnais ».** Une première relecture du code (huit lectures, 22 harnais) estimait à −430 s ce que
rapporterait la conversion des attentes fixes en attentes sur condition, en supposant que `render`, `openRead`,
`tickAll`… produisent leur effet sur-le-champ. **La mesure l'a démentie**, et c'est elle qui fait foi.

**Méthode (copies jetables, sondes intactes).** Les 491 sommeils et 121 `waitForTimeout` des harnais ont été transformés
puis les 2 619 contrôles comparés un à un à une passe de référence (bruit de fond mesuré entre deux passes normales : nul).

| Attentes | Temps cumulé | Contrôles qui changent |
|---|---|---|
| telles quelles | 1 189 s | 0 |
| ≈ 2 images | 427 s | 66 au rouge, 5 harnais plantent (416 contrôles non joués) |
| divisées par 2 | 767 s | 31 (doctrine, partage, k5, a11y, pdfsearch, retour) |
| triplées | 2 732 s | 6, et un plantage (partage) |

Transitions, anti-rebonds, écritures IndexedDB, ticks et réseau sont réels : **les attentes fixes ne se raccourcissent pas
en masse**. Écartés aussi, mesures à l'appui : bloquer le service worker (0 s de gagné sur une tranche de 96 s), passer le
pool à 6 (trois rouges de charge), retirer les « attentes mortes » (relues : chacune laisse finir une transition avant le
geste suivant). La machine reste peu chargée (≈ 2 cœurs sur 8) : les harnais attendent l'app, ils ne calculent pas.

**Ce qui est prouvé et appliqué.**
1. **pdfsearch payait 60 s de délais par un défaut de condition.** `waitForFunction` de toute la passe chronométrés
   (1 693 appels) : les trois seuls qui expirent en vert sont ceux de pdfsearch, qui testaient `window.attIx` — `attIx`
   est un `const` du script classique, jamais propriété de `window`. L'index est prêt en 1 à 85 ms. Le témoin « pdf.js
   pas chargé » (règle 13) profitait par accident de 10 s d'observation après le démarrage : **elles sont gardées,
   explicitement**, pour ne pas l'affaiblir. 66 → 16 s, 40/40 contrôles identiques.
2. **Tranches équilibrées par durée.** Le modulo groupait les lourdes (doctrine 3/4 : 168 s contre 95 ; partage 1/5 : 98
   contre 32). `audit-run` enregistre la durée ⏱ de chaque section et de chaque tâche (`mesures`, par moteur, dans
   `.audit-etat.json`) et transmet aux tranches un plan glouton (la plus longue d'abord, tranche la moins chargée)
   `AC_PLAN` ; une section absente du plan retombe au modulo, un plan illisible ou hors bornes ÉCHOUE, un `AC_PLAN` du
   terminal n'atteint jamais un enfant, et le contrôle ##SEC de couverture est inchangé. **Préalable : les 155 sections
   de doctrine et partage, jouées SEULES, sont toutes vertes** — l'ordre de regroupement ne change aucun verdict.
   Mesuré : doctrine 119-120 s par tranche, partage 58-67 s, passe complète ~295 → 279 s, 2 619 contrôles identiques.
   Le gain sur la passe complète est modeste parce que le pool de 4 est plein : il porte surtout sur les passes ciblées.
3. **Poids d'ordonnancement re-mesurés** (doctrine déclaré 217 pour 478 réels) ; ils ne servent plus qu'à défaut de mesure.

**Les biais trouvés dans les harnais — un vert qui ne tenait qu'à la vitesse du harnais.**
- A387 « … et son compteur aussi » : le compteur, parti 200 ms après la coche, était lu dès l'arrivée de la coche. Il est
  maintenant attendu lui aussi.
- « Le billet mort ne traîne pas » : `Share.resume` interrogeait le VRAI Supabase après rechargement. La requête est
  désormais refusée par le banc (`page.route`) ; l'app efface le billet sur tout échec, réseau comme refus.
- Grammaire des fenêtres : une largeur lue 250 ms après une animation de 220 ms (357 contre 358 px sous charge). Le
  harnais attend désormais la fin des animations finies, EN PLUS des attentes existantes (plafond 1 s).
- « Continuer seul » : l'évènement « rejoué » recalculait `Date.now()`. L'identité d'une annexe étant `ax-<t>-<seq>`, une
  milliseconde d'écart en faisait un autre évènement, et le doublon observé sous charge était légitime : le harnais avait
  tort, pas le dédoublonnage. L'heure est fixée une fois.
Ces quatre corrections tiennent à attentes divisées par deux ET triplées (58/58 contrôles).

**Restent ouverts, signalés et non corrigés.** pdfsearch compte tantôt 1, tantôt 2 rectangles surlignés d'une passe à
l'autre (le contrôle passe dans les deux cas).

**v5.39.3 — le rouge WebKit d'A387 était un biais du harnais, pas une fuite.** Sous WebKit, « une session locale sur
l'autre aide n'émet RIEN sur le fil de l'invité » échouait déjà sur la v5.39.1 (3/3, deux ou trois évènements reçus ;
la passe par défaut, sous Chromium, ne le voyait pas). Relevé de la NATURE des évènements lus par l'invité pendant la
fenêtre : deux `sig` (offre et réponse de négociation du canal direct de secours, que WebKit achève plus tard), aucune
coche ni navigation ; sous Chromium, aucun. Le contrôle comptait `Share.applied`, qui additionne aussi cette plomberie
(`sig` est routé à `slSbOnSig`, jamais peint). Il compte désormais les seuls évènements d'état lus au fil (tout sauf
`sig`), avec un TÉMOIN — l'invité a lu le fil au moins une fois pendant la fenêtre — sans lequel un zéro ne prouverait
rien. Vérifié capable d'échouer : `Share.hostedRt` neutralisé chez l'hôte (le défaut d'origine d'A387), le contrôle rougit
sur les deux moteurs et nomme `uncheck, counter, timer_stop, nav, session_start, check`.

**Formes REFUSÉES** : convertir les attentes fixes en masse (le gain supposé ne résiste pas à la mesure, et la moindre
réduction casse des contrôles) ; accélérer les délais de l'app au banc (`page.clock`, réglages ad hoc) — cela changerait ce
qui est prouvé ; regrouper les petits harnais dans un seul processus (2 à 3 s pour un rouge moins lisible).

## A421 — « Afficher » suit le type choisi ; l'anneau d'arrivée ne repeint plus (v5.39.4)

**Signalé à l'usage** : « problème de filtrage persistant entre Aides et Protocoles dans le menu
Affichage, ça ne filtre pas » ; « rendre l'animation autour de Commencer la session plus fluide ».

**Le filtre. Cause mesurée.** La feuille « Affichage » a DEUX portes : le bouton rond de la recherche
(`[data-filttog]`, `openViewSheet()` sans rappel) et le bouton « Affichage » de la liste (`#rangBtn`,
`openViewSheet(cfg.rerender)`). Par la seconde, la feuille gardait la vue d'OUVERTURE comme rappel
(`renderAll` sur « Tout ») : « Aides » appelait `setSection`, qui rendait la bonne liste, puis ce rappel
figé repeignait l'union par-dessus. Tout geste suivant de la même feuille (tri, regroupement, densité,
catégorie) ramenait aussi la vue d'ouverture. Le témoin d'A419 (« vérifié sans défaut ») ouvrait par le
bouton rond, le seul chemin sain : il ne pouvait pas voir celui-ci.
**Correctif** : `viewSheetRedo()`, seule porte de re-rendu de la feuille ; à l'accueil elle appelle
`renderLibrary`, qui aiguille selon `state.section` ; ailleurs le rappel reçu, sinon `render()`.
**Témoin** (`audit-doctrine`, section A419) : quatre crans par `#rangBtn`, chacun suivi d'un tri dans la
même feuille, comptes d'aides et de protocoles attendus. Rouge sur le code d'avant, vert après.

**L'anneau (amende A331 sur la TECHNIQUE, pas sur le signal).** Il animait un `box-shadow` d'étalement
0 → 12 px : une peinture par image sur le fil principal, précisément pendant le rendu d'une fiche neuve
(les saccades se voyaient sur iPhone). Il surgissait aussi à pleine encre au bord de la capsule, et le
palier immobile 60-100 % de chaque itération hachait le rythme. Désormais :
- `.sd-in::after` est un TRAIT de 2 px (`--dock-ring`) dessiné une fois à sa place finale : un
  `outline` décalé de 10 px sur une boîte à la taille de la capsule (`inset:0`), et non une bordure à
  `inset:-12px` — celle-ci entrait dans le débordement de la capsule et le témoin ECAM « sans rognage »
  rougissait (12 px, à toutes les largeurs) ; un contour n'y entre jamais et suit le rayon de la boîte ; il part de la capsule par `transform:scale(--sd-sx,--sd-sy)`
  et s'efface par `opacity` — deux propriétés composées, rien n'est repeint ;
- l'échelle de départ est MESURÉE par axe dans `syncDock` au moment où `sd-arrive` se pose, après la
  sous-ligne du bouton (qui change la hauteur) : 12 px pèsent 3 % sur 360 px de large, 30 % sur 56 de
  haut, une échelle uniforme décollerait le trait du bord. Ratio sans unité : les 12 px sont ramenés à
  l'écran par `zoomF()` (vérifié à 130 % : 0,70 en hauteur comme à 100 %) ;
- fondu d'entrée (0 → 1 sur 20 %), puis un seul mouvement décéléré (`cubic-bezier(.22,.61,.36,1)`)
  jusqu'à l'effacement, sans palier.
Inchangé : trois anneaux, départ à 800 ms, 1,3 s chacun, fini à 4,7 s (WCAG 2.2.2), autour de la
CAPSULE entière et jamais du bouton seul, rien sous `prefers-reduced-motion`. Mesuré à 390 (clair et
sombre, images figées à 0, 10, 25, 50, 80 %) et à 1440 px.
**Forme refusée ici** : garder l'ombre en changeant seulement la courbe — le coût de peinture, cause des
saccades, restait entier.

