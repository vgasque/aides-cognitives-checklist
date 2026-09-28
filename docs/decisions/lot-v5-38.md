# Lot v5.38 — l'audit UX du 27/09/2026 (A400-A415)

> Fichier normatif, suite de [`lot-v5-37.md`](lot-v5-37.md) (A396-A399). Les numéros A sont des adresses :
> ne jamais renuméroter. Audit design demandé par l'auteur (cinq axes : normes ECAM/QRH/AC 120-71B et
> WCAG 2.2, couleurs, hiérarchie, priorisation, remise en question), MESURÉ sur l'app servie, puis deux
> passes de maquettes rendues sur l'app réelle (propositions injectées dans le navigateur de test,
> jamais dans le code). Chaque point ci-dessous a été tranché par l'auteur sur capture ; les formes
> REFUSÉES sont en fin de fichier pour ne pas être reproposées.

## A400 — le volet Outils est enfin mesuré, et le harnais compose l'alpha

**Défauts.** « MAINTENIR » (consigne des remises à zéro, geste destructif) : 2,64:1 en clair — collision
de cascade, `.tm-reset .tmr-hint` (plus loin, même spécificité) repeignait `--ink-soft` sur la matière
système ; le sélecteur du volet est hissé (`.rt-dock .tm-reset .tmr-hint`, 6,33:1). La nuit, les cartes
du volet posent `--sys-2` (blanc 12 %) sur une matière déjà éclaircie : une vingtaine de textes
secondaires à 3,13:1 ; `--sys-ink-2` relevé à `#c0c8d3` DANS le volet seulement (4,62:1 sur carte, 6,70
sur la matière nue) — la hiérarchie des autres surfaces système ne bouge pas.

**Le harnais.** Aucune surface d'`audit-a11y` n'ouvrait le volet : « état · volet Outils » l'ajoute (rouge
sur l'ancien code, vert après). Et `over()`/`bgOf` composaient deux voiles translucides empilés comme un
fond BLANC opaque (le premier mélange rendait `a:1`) — faux « + » à 1,21:1, et faux verts possibles pour
un texte sombre sur la même pile. Composition « source over » avec l'alpha du dessous : la passe complète
ne révèle aucun défaut masqué ailleurs.

## A401 — un rappel du chapeau se lit sur une ligne

`forgetStrip` rendait `v4ItemToStr(it)` : le memory item de l'ACR s'affichait dans sa SYNTAXE DE SAISIE
(« ⚠ RCP immédiate :: 30:2 — sans délai ») — l'élément vital de la fiche, dans son format le moins
lisible, et le glyphe ⚠ qu'A345 avait retiré des étapes. `forgetItemHtml` : le dessin du parcours (A388)
— mot CRITIQUE / VIGILANCE sans aplat, calé à droite de la ligne ; réponse à la suite, « · » et gris,
même police que la ligne (l'option mono a été écartée : la seule ligne de la carte à changer de police).

## A402 — « ×2 » devient « Double contrôle »

La double confirmation (AC 120-71B) ne vivait que dans un `title` sur un « ×2 » de 11 px — un `title`
n'existe pas au toucher. Étiquette « Double contrôle » (terme de la pratique hospitalière des médicaments
à risque) dans le logement `.stp-mks`, même boîte que CRITIQUE (20 px, alignées au pixel), en encre
neutre à filet `--ctl-line` : c'est une consigne, pas un registre de danger. `.stp-x2` purgé ; éditeur
(pastille et bascule) au même mot.

## A403 — le nom court : automatique, surchargeable, lu à distance

**Nom court.** Champ facultatif `short` (24 c.) sur les minuteurs, compteurs et complications (`migrate`
: absent quand vide, la forme des objets ne change pas). Sinon, abréviation PURE par budget de
caractères (testable, stable d'un rendu à l'autre — la boucle d'ajustement de la capsule s'y fie) :
parenthèse finale, puis mots-outils, puis DEUX grammaires. Un minuteur se distingue souvent par son
DERNIER mot (« Réévaluation après adrénaline » → « Rééval. adrén. ») : on abrège d'abord les premiers,
puis on ne garde que le premier et le dernier. Une complication se NOMME par son PREMIER (« Bronchospasme
réfractaire » → « Bronchospasme ») : on retire les derniers, jamais on ne l'abrège. Mesuré : l'automatique
seul abrégeait « Bronc. réfractaire » — l'algorithme ne sait pas quel mot porte le sens, d'où le champ.
L'éditeur montre l'abréviation d'office en indication du champ. Le nom complet reste à un tap (volet,
titre du bloc de complication, index ⚡).

**13,5 px et césure.** Capsule et quai passent de 11 à 13,5 (critère FAA HF-STD-001 : ≥ 16′ d'arc ; une
capitale de 11 px faisait ≈ 7,5′ à 60 cm). Le quai passe en CASSE DE PHRASE : en capitales, « HORODATER »
demandait 82 px pour 73 disponibles à 390 (mesuré) ; en casse de phrase il tient d'une ligne jusqu'à 375.
`hyphens:auto` (le document est `lang="fr"`) sur le quai ET les titres de bloc : « Bronchospas / me… » et
« Bronchospasm / e réfractaire » se coupaient au milieu du mot. Sous 375 px, la césure et l'ellipse
restent les derniers filets — le nom court est le remède voulu des petits écrans.

## A404 — 44 px actifs hors crise

Étoile d'épinglage, croix de la notice et boutons du bandeau système : dessin de 32, halo à 44 (HIG). Les
deux boutons du bandeau sont VOISINS : halo vertical pour « J'ai compris », la croix ne s'étend que vers
le bord. Vérifié à la capture (`elementFromPoint` à 5 px hors du dessin), deux thèmes.

## A405 — pliables : rien ne se pose sur la charnière

Exigence de l'auteur : Surface Duo, Pixel Fold, Galaxy Z Fold. La règle des segments (v5.30) existait
mais rien ne la vérifiait ; émulée (CDP `displayFeature`) : en session, la capsule traversait la
charnière, la gouttière de 24 px était plus étroite qu'une charnière de 34, et la fenêtre « Terminer la
session ? » — centrée sur l'écran — était COUPÉE EN DEUX. `--hinge` (écart entre `viewport-segment-right
0 0` et `viewport-segment-left 1 0`) : gouttière = charnière + 24, capsule, quai et feuilles bornés au
volet gauche, et le voile des fenêtres borne sa zone au même volet (`html body .ai-modal.on[class]` :
spécificité au-dessus du plein écran étroit). Nouveau harnais `audit-pliables` (Duo 1114×705, Fold
841×701) : 16/16, ROUGE (8 échecs) sur l'ancien code. ⚠ `page.screenshot` de Playwright EFFACE
l'émulation de charnière : mesurer avant, capturer par CDP. WebKit n'expose pas les segments (harnais
annoncé SAUTÉ) : un iPhone pliable ne déclenchera ces règles que le jour où Safari les exposera.

## A406 — le rouge réservé à CRITIQUE et à l'alarme

Sur l'écran de session, le rouge portait quatre sens (catégorie « Urgences », « ■ Mode crise », « Fin »,
complication) en plus de l'étape critique — et la doctrine du bandeau blanc le disait déjà : un rouge
permanent désensibilise. « ■ Mode crise » en encre secondaire (glyphe et mot gardés) ; « Fin » : le ■
garde le rouge de l'arrêt, le mot passe au gris des touches secondaires ; la touche ⚡ et l'étiquette
« ⚡ complication » en ambre ; les ■ des critères d'entrée dans l'historique en neutre. Part de rouge à
l'écran de session : 0,38 % → 0,16 % des pixels (mesuré).

## A407 — poste de pilotage sombre : la barre du minuteur est neutre

Mesuré : une barre bleue n'ajoutait que 0,06 point de bleu à l'écran, mais le principe ECAM tranche — un
état nominal qui ne demande rien n'a pas de couleur ; la couleur vient quand il faut agir (l'ambre de
l'échéance existe déjà). La distinction « lancé / pas lancé » n'y perd rien : la capsule ne montre QUE les
minuteurs en cours ou échus ; un minuteur à lancer ou en pause se compte dans le rappel (« 1 minuteur »,
« ⏸ 1 en pause »), et le rail garde les chiffres bleus du minuteur en cours. Le « ● SESSION » reste vert
(ECAM : système nominal). Règle 8 réécrite en conséquence (AGENTS.md).

## A408 — le nuancier sort des registres

Mesuré en OKLab : le vermillon d'« Urgences » (#b23240) était à 0,048 du rouge critique — plus près que
deux catégories voisines ne le sont entre elles (0,059). Règle posée : une catégorie n'est JAMAIS plus
proche d'un registre (rouge, ambre, vert) que deux presets entre eux. Contraintes simultanées : lisible en
texte (`catLisible`, 4,5:1 blanc sur couleur ET couleur sur teinte 15 %), l'anneau passe par chaque preset
(A314), le contraste de nuit ne baisse pas de plus de 0,1, l'écart minimal entre presets ne baisse pas.
Résultat : le vermillon QUITTE le nuancier (12 presets) et « Urgences » prend la prune (#7a2f6b, 0,141 du
rouge) ; SMUR #905a39, SSE #6f684a, mousse #4f6727, Pédiatrie #116b4c. Les couleurs stockées ne sont
jamais réécrites (A314) : le gestionnaire signale une catégorie proche d'une couleur d'alerte et la teinte
voisine sûre se prend d'un tap (`catRegNear`, `catSafeTwin` : l'ancien preset → son remplaçant).

## A409 — l'étape vitale oubliée se dit en rouge

« Terminer la session ? » peignait tout son encadré en ambre, y compris « 1 étape vitale non cochée » —
exactement le cas rouge de la règle 8. Encadré neutre ; chaque ligne porte son registre : l'étape vitale
avec l'étiquette CRITIQUE, le minuteur en cours en neutre. Le « △ » des repères posologiques, lui, RESTE
(correction de l'audit) : c'est le marqueur de vigilance posé par l'auteur sur une dose — le registre
ambre de la règle 8.

## A410 — la capsule garde sa silhouette, à la largeur de son contenu

À 780 px et plus, quand les minuteurs sont au rail, la capsule ne porte que le chrono : elle prend la
largeur de son contenu (105 px au lieu de 1 260) et perd le filet qui ne sépare plus rien. L'auteur tenait
à ce qu'elle rappelle le téléphone : l'objet reste, la masse vide part. Au téléphone, rien ne change.

## A411 — la réponse attendue en casse de phrase

Mono, casse de phrase, sans interlettrage (était : capitales espacées). Compatible AC 120-71B / QRH : la
réponse reste typographiquement DISTINCTE du libellé (police), ce que le défi-réponse exige ; FAA
HF-STD-001 recommande la casse mixte pour le texte lu, les capitales pour les étiquettes courtes. L'ECAM
est tout en capitales, donc sans contraste de casse à perdre. A351 (« réponse en mono neutre ») tient.

## A412 — « Horodater »

La touche « Journal » écrit dès qu'on la touche (A349 : le geste est gardé) ; son nom nommait un lieu.
« Horodater · n » : un verbe, un sens. Candidats écartés : Noter l'heure (le plus long), Pointer et Tracer
(ambigus), Consigner (ne dit pas l'heure), Top (argot).

## A413 — « Créer » n'est plus le bouton le plus saillant de l'accueil

L'accueil d'un outil d'urgence sert d'abord à TROUVER. Au téléphone, le dessin du bouton Historique
voisin ; en large, le tonal d'« Affichage » et « Sélectionner ».

## A414 — « Vérifier », sans « :: »

« :: » est un symbole d'auteur (la syntaxe du défi-réponse) : il sort du bouton et de son infobulle.

## A415 — la bulle d'apprentissage devient la sous-ligne du geste d'entrée (amende A331)

La bulle masquait la carte suivante de l'écran de démarrage — une première utilisation peut être une vraie
urgence. La phrase entre DANS le bouton, en sous-ligne, sous la même règle (tant que l'appareil n'a jamais
démarré de session, `startHintSeen`) : « Lance le chrono · minuteurs prêts ». Exacte — démarrer ne lance
que le chrono, les minuteurs sont « à lancer » (A330) ; « et compteurs » ne tenait qu'à partir de 390 px.
`#dockHint`, `.sd-hint*` et `body.dock-hint` purgés (règle 14, zéro émission au grep).

## Formes refusées (ne pas reproposer)

- **H1** — « En cours » en étiquette au-dessus du titre du bloc courant (« moche ») ; et le compactage du
  haut de session en général : le gain mesuré n'était que de 24 à 30 px.
- **H3** — les minuteurs au même lieu à toutes les largeurs : en large, le rail les montre AVEC leurs
  commandes sans rien ouvrir.
- **H5** — retirer la pilule « EN COURS » : quand l'historique du parcours est ouvert, deux blocs sont
  dépliés et la pilule est le seul MOT qui double la bordure bleue.
- **P2** — signaler à l'accueil une session sans geste depuis longtemps.
- « Fin » tout neutre (le ■ rouge est gardé) ; la barre de minuteur bleue (neutre retenue).
- H4 : la mise en garde « Attention : » en ambre avant l'étape (un septième style de texte) et la réponse
  en police de ligne grise (revenait sur A351).
- C3 : éclaircir les presets pour la nuit — la couleur de catégorie sert aussi de TEXTE (4,5:1).
- P4 : « Exercice » en toutes lettres sur la touche — mesuré, il demande 56 px pour 28 disponibles ;
  « Exo. » reste.
