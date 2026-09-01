# Doctrine CSS — les commentaires longs du monofichier, repris à l'octet (v5.20.5, A292)

> Ce fichier est le pendant CSS du déménagement v5.10.3 : les blocs de commentaires de PLUS de
> dix lignes du `<style>` d'index.html sont repris ici À L'OCTET, chacun sous un id stable
> **C`n`** — et le commentaire en place est resserré à l'essentiel (la contrainte que le code ne
> peut pas dire) avec le renvoi « doctrine-css.md C`n` ». RIEN n'est réécrit : chaque section
> contient le texte d'origine, verbatim. L'ordre suit la feuille de style. Les intitulés sont la
> première ligne de chaque bloc. Un bloc resserré qui doit regagner du détail le retrouve ici.

## C1 — Tokens : TOUTE nouvelle couleur passe par ici (pas de hex ad hoc dans les règles).

```
  /* Tokens : TOUTE nouvelle couleur passe par ici (pas de hex ad hoc dans les règles).
     PALETTE V5 « bleu clinique » (canvas V5 Explorations, v4.0.4) : --primary bleu = identité et
     action ; --ok vert = confirmation/issue positive (nouveau registre V5 : pastilles d'état,
     fin d'algorithme) ; --verify ambré = décisions/vigilance ; --critical vermillon = danger.
     Neutres : --surface-2 (panneaux/survols), --surface-3 (badges neutres, statuts achromatiques),
     --line-strong (bordures de composants, contraste >= 3:1). Gamme primaire claire :
     --primary-100 (fonds de tags), --primary-200 (bordures douces).
     --primary-hi : fond de SURVOL des boutons remplis (en sombre, --primary-dk devient
     l'accent TEXTE clair — le survol ne peut plus s'y adosser). --verify-line/--critical-line :
     bordures DOUCES des encadrés ambrés/vermillon ; les notices de la taxonomie V5 (bord gauche
     4px) empruntent la couleur du texte sémantique lui-même. --alert-* : banderoles d'alarme
     (ambre vif, volontairement distinct de --verify). --rt-* : SNACKBAR (ardoise bleu nuit fixe
     dans les deux thèmes) — le panneau minuteurs suit le THÈME depuis V5. --alarm : jauge de
     maintien/flash (chaud = alarme ou geste destructif UNIQUEMENT, jamais un état neutre).
     --critical = erreur/destruction OU ARRÊT D'UN PROCESSUS VIVANT (« Terminer » une session :
     les minuteurs s'arrêtent — registre du rouge « raccrocher » iOS ; l'action est archivante et
     réversible, mais son coût d'erreur en crise est opérationnel) — jamais une simple décision
     (ça, c'est --verify). Pastilles d'état (compte / synchro) : tokens SÉMANTIQUES qui suivent le
     thème — ok = --ok (vert, V5), attente = --verify, erreur = --critical, inactif = --line-strong ;
     tous >= 3:1 sur --bg dans les DEUX thèmes.
     --input-bg : fond des champs de saisie (blanc en clair, très sombre en sombre) — aucun fond
     de champ codé en dur. Les overrides du thème sombre passent EUX AUSSI par les tokens (pas de
     copie hex : une copie désaccorde les palettes au premier retoucher de token).
     Échelle responsive FERMÉE : 430 / 560 / 640 / 780 / 900 / 1000 px (1000 = colonne droite de
     la vue fiche, V5). Plancher typographique : 11px (app consultée sous stress — rien en dessous).
     --line-hover : bordure des survols de boutons/chips (un seul gris au lieu de trois). */
  /* F5 (v4.61.0, audit design) — UNE VOIX TYPOGRAPHIQUE POUR LES TITRES.
     Le système roulait tout en system-ui : sûr, mais anonyme. Source Serif 4 (SIL OFL, sous-
     ensemble latin, graisse 600, 21 Ko, vendorisée dans `vendor/fonts/`) prend les TITRES —
     titre de fiche, marque, compte rendu — et rien d'autre. Ce n'est pas une décoration : les
     titres sont les seuls survivants du scan sous stress, ils méritent un dessin ; le texte
     courant restait system-ui, la police que l'appareil rend le mieux, et changer le corps d'une
     aide lue en réanimation n'a jamais été l'objet.
     `font-display: swap` : le texte s'affiche IMMÉDIATEMENT dans la police de repli et bascule
     quand la police est prête — jamais d'écran de titre vide, même au tout premier chargement.
     Précachée par sw.js (règle 13) : hors ligne dès l'installation. */
```

## C2 — --ctl-line : LA SEULE DÉVIATION ASSUMÉE À tokens.css, et elle est motivée. Le système pose

```
  /* --ctl-line : LA SEULE DÉVIATION ASSUMÉE À tokens.css, et elle est motivée. Le système pose
     --line-strong:#c3ccd6, soit 1,6:1 sur blanc : parfait pour un filet de carte, INSUFFISANT
     pour la bordure d'un composant, que WCAG 2.2 § 1.4.11 exige à 3:1. Or ce token habille aussi
     les CASES À COCHER et les bordures de champs — c'est-à-dire l'objet qu'on vise avec des gants,
     sous stress, au soleil. On garde donc la valeur du système partout où il s'agit de dessiner,
     et un token à 3:1 là où il s'agit de VISER. Deux rôles, deux tokens : la règle 8 du dossier. */
  /* ⚠ 3:1 SUR L'AMBIANCE AUSSI, PAS SEULEMENT SUR LE TRAVAIL (v5.6, trouvé au balayage). Le token
     des BORDURES DE COMPOSANT (WCAG 2.2 § 1.4.11 — « la case qu'on vise avec des gants ») tenait
     3,08:1 sur le blanc du travail mais seulement 2,82 sur le gris d'ambiance, où vivent pourtant
     des contrôles bordés (le déclencheur de filtres de l'accueil). Assombri d'un cran : 3,13 sur
     l'ambiance, 3,41 sur le travail — les deux au-dessus du seuil, et le dessin ne change pas de
     nature. Le thème sombre tenait déjà (3,68 / 4,05). */
```

## C3 — ⚠ `--shadow-up` N'EST PAS UN ALIAS DE `--shadow-work`, et le harnais l'a rattrapé. Une ombre

```
  /* ⚠ `--shadow-up` N'EST PAS UN ALIAS DE `--shadow-work`, et le harnais l'a rattrapé. Une ombre
     MONTANTE (porte « ＋ » collée en pied, barre d'actions basse) doit se répandre vers le HAUT,
     du côté d'où vient le contenu : avec un décalage POSITIF, l'objet paraît enfoncé au lieu de
     flotter — et pour un objet à coins arrondis, c'est son ombre qui épouse le rayon, jamais un
     voile (v4.78.0). MÊME ENCRE que l'ombre unique — c'est bien UNE matière qui projette, seule
     sa direction change — mais PLUS LARGE ET PLUS DENSE depuis v5.15.0 (planche 18/P : 6→12 px,
     24→32 px, 6 %→26 %) : sur du papier blanc, un objet sombre qui flotte au-dessus d'un tableau
     de posologies doit PROJETER, et 6 px à 6 % ne se voyaient pas — sur téléphone la colonne de
     lecture fait 358 px et le quai 362, le contenu touche la barre ; le desktop, lui, a son
     couloir calme par construction (260/340 px de marge). Deux pistes ESSAYÉES ET ÉCARTÉES sur
     maquettes, à ne pas reproposer « pour renforcer » : un fondu vers l'ambiance (blanc contre
     ambiance = 1,06:1, invisible — et sur matière sombre la teinte se lit comme une bande claire,
     à l'envers) ; une bande de flou backdrop-filter (sur une barre à coins arrondis, sans
     recouvrement il reste des angles nets dans l'arrondi, avec recouvrement le flou échantillonne
     la barre sombre et étale un halo noir autour d'elle). La nuit ne projette toujours pas
     (--shadow-up:none en sombre) : la séparation nocturne vient du périmètre --sys-edge. */
```

## C4 — --shadow-primary(-sm) : élévation TEINTÉE PRIMAIRE des boutons remplis (v4.31.0 — les

```
  /* --shadow-primary(-sm) : élévation TEINTÉE PRIMAIRE des boutons remplis (v4.31.0 — les
     rgba(23,71,127,…) éparses sont consolidées ici). Tokens FIXES des deux thèmes (jamais
     surchargés en sombre, comme --rt-*) : --lb-cap/--lb-ink = légende et glyphe de la lightbox
     (fond noir constant) ; --paper = canevas BLANC du SVG d'algorithme, des pages PDF et de
     l'impression (le SVG est peint pour fond clair puis contre-inversé en sombre, une page PDF
     est du papier) ; --flow-cur = trait du nœud courant du SVG, primaire CLAIR baké (même
     logique — la version sombre passe par --flow-hl-dk après inversion). */
  /* ===== THÈME SOMBRE (usage dans le noir) : on redéfinit les variables + quelques fonds codés en dur.
     Contraste maintenu pour la lisibilité en situation critique.
     v4.57.0 (audit design, piste D2 — décision utilisateur « c'est le NOUVEAU mode sombre ») :
     le sombre adopte les codes couleur de l'ex-« Contraste + » plutôt que d'ajouter un 4ᵉ cran au
     cycle de thème. Motif d'usage : l'extra-hospitalier — soleil direct sur un écran en mode
     sombre, gants, appareil posé sur un chariot. Deux canaux, et deux seulement :
       · ENCRE SECONDAIRE relevée (#93a5b5 → #b7c6d6) : ~7:1 sur --surface au lieu de ~4,9:1.
         PAS l'encre pleine du bloc `prefers-contrast: more` : là c'est l'utilisateur qui demande
         d'APLATIR la hiérarchie, ici c'est le défaut de tous — un texte secondaire indiscernable
         du principal ferait perdre le repère « ce qui compte est plus clair ».
       · FILETS renforcés (#24303f → #3b4b5d, l'ex `--line-hover`) : 3:1 sur --surface, seuil
         WCAG 1.4.11 des composants — les cadres de carte se voyaient à peine dans le noir.
     Les GRAISSES ne bougent PAS (l'audit proposait +100) : la graisse porte déjà l'état sur les
     segmentés et les registres, et l'élargir changerait toutes les largeurs de texte — donc les
     mesures à 320 px que quatre harnais surveillent. Un canal par signification.

     v4.71.0 (décision utilisateur, « noir pour tout le mode sombre partout ») — LE FOND DESCEND
     À #000. Motif : la « vraie nuit » d'un écran OLED n'allume tout simplement pas ses pixels
     noirs, ce qui vaut de l'autonomie sur un appareil qu'on tient trois heures en intervention,
     et le contenu d'alerte y détache d'un cran de plus (le cadre rouge « Ne pas oublier » est ce
     qu'on doit voir en premier). SURFACES EN GRIS NEUTRE, décision utilisateur : j'avais proposé
     de garder la famille bleue sur les surfaces (les pastilles de catégorie et l'accent restent
     alors les seuls objets colorés d'un écran gris, ce qui change le caractère de l'app) ; la
     variante neutre a été choisie sur maquette comparative, les deux ayant été mesurées côte à
     côte. Elle a un mérite qu'il faut nommer : sur du gris strictement neutre, TOUTE couleur à
     l'écran porte un sens — registre, catégorie ou accent —, et c'est exactement la règle 8.
     Les hors-teintes de survol suivent (`--hover-dk`), sans quoi le « gris pur » se lirait bleu
     au premier passage de souris.
     CE QUE LE NOIR OBLIGE À DÉPLACER, et c'est le vrai travail : sur #000, une OMBRE NE DIT
     PLUS RIEN — assombrir du noir ne produit aucun contraste. Les trois niveaux d'élévation
     écrits en v4.57.0 (plat+filet / --shadow / --shadow-lg) ne peuvent donc plus reposer sur
     l'ombre : ici c'est la SURFACE qui monte (#000 → #0d1720 → #17242f) et le FILET qui la
     borde. Les ombres RESTENT déclarées et ne sont pas du gaspillage : une modale se détache
     encore de la carte qu'elle recouvre, qui n'est pas noire. Filets relevés en conséquence
     (#3b4b5d → #334352 : le seuil 3:1 de WCAG 1.4.11 se calcule sur --surface, qui a bougé).
     ENCRES ET REGISTRES INCHANGÉS : le noir est un changement de FOND, pas de sémantique — les
     rouges, ambres et verts gardent leurs valeurs, et l'a11y a été rejouée avec la palette
     réellement posée dans le fichier (301/301, contraste calculé sur le fond EFFECTIF). ===== */
  /* ══ NUIT — DESSINÉE, PAS CALCULÉE (A5 : OLED gris) ══════════════════════════════════════
     Fond gris VRAI, pas un noir théâtral : sur OLED en salle sombre, le noir pur fait « trou »
     et le halo des textes blancs fatigue — un effet gênant pour les personnes astigmates. La
     nuit ne projette pas d'ombre : elle BORDE. Mêmes objets, valeurs propres. */
```

## C5 — ⚠ LA MATIÈRE DE TRAVAIL SE DÉTACHE DE LA NUIT, ET SON FILET TIENT LE SEUIL (v5.6, variante C

```
  /* ⚠ LA MATIÈRE DE TRAVAIL SE DÉTACHE DE LA NUIT, ET SON FILET TIENT LE SEUIL (v5.6, variante C
     choisie sur maquettes). Mesuré avant : travail contre ambiance **1,10:1**, filet contre travail
     **1,21:1** — une carte n'avait donc, la nuit, ni ombre (« la nuit ne projette pas, elle borde »)
     ni bord perceptible, et sur une colonne de cartes c'est le COMPTAGE qui échoue : on ne voit plus
     où l'une finit et où la suivante commence. Après : matière **1,22:1**, filet **3,15:1** — le
     seuil de WCAG 2.2 § 1.4.11 pour la limite d'un composant.
     ⚠ DEUX CANAUX PLUTÔT QU'UN, ET C'EST LE MOTIF DU CHOIX : renforcer le seul filet (variante A,
     3,68:1 sur la matière inchangée) tenait aussi le seuil, mais chargeait le TRAIT — sur des cartes
     empilées le dessin se rapproche d'une grille, ce que « verre clinique » cherche à éviter. Ici la
     matière fait la moitié du travail, donc le trait peut rester fin.
     COÛT MESURÉ : l'encre principale passe de 14,4:1 à 13,1:1 sur la carte (très au-dessus du
     seuil). `--sys` NE BOUGE PAS — la capsule et le dock sont de la matière SYSTÈME, pas TRAVAIL,
     et les deux matières cessent donc d'être confondues la nuit : c'est un gain de doctrine, pas un
     effet de bord. Le thème clair n'est pas touché. */
```

## C6 — ⚠ LA NUIT, LA MATIÈRE SYSTÈME **MONTE** (v5.15.0, planche 17/1a — le « --sys NE BOUGE PAS »

```
  /* ⚠ LA NUIT, LA MATIÈRE SYSTÈME **MONTE** (v5.15.0, planche 17/1a — le « --sys NE BOUGE PAS »
     de la variante C ci-dessus est levé, mesures à l'appui) : à #171a20, capsule et dock ne
     tenaient que 1,09:1 contre l'ambiance et 1,12:1 contre une carte — les trois matières n'en
     faisaient plus qu'une, et c'est ce qui se voyait à l'usage. Le jour, système = la matière la
     plus SOMBRE ; la nuit, la plus CLAIRE — dans les deux cas la plus ÉLOIGNÉE des deux autres,
     qui est la vraie règle. Encres rejouées sur la nouvelle matière : --sys-ink 9,4:1,
     --sys-ink-2 4,5:1, --ok-sys 6,5:1, --crit-sys 5,7:1 — au-dessus du seuil. L'ombre portée ne
     rattrapait rien (assombrir du noir ne dit rien, v4.71.0) : la séparation vient du PÉRIMÈTRE
     --sys-edge, 5,3:1 contre l'ambiance. Coûts nommés : le creux de la touche ⏱ passe à .14
     (--sys-key), et le filet ambre de l'alarme tombait à 2,25:1 sur la capsule éclaircie —
     --alarm-bd passe à --warn-sys (6,8:1). */
```

## C7 — iOS Safari (paysage) : sans ce réglage, le « font boosting » agrandit certains textes de

```
  /* iOS Safari (paysage) : sans ce réglage, le « font boosting » agrandit certains textes de
     façon disproportionnée (jauge de stockage, en-têtes de section, bandeaux…). */
  /* PAS de scrollbar-gutter:stable sur html (retiré v4.2.1) : sur les navigateurs à barres de
     défilement CLASSIQUES (Windows/Linux), il réservait ~15px à droite EN PERMANENCE, même quand
     rien ne défile (accueil = coque fixe, fiche courte) — l'app semblait TRONQUÉE à droite
     (en-tête/bandeau de crise arrêtés avant le bord, éléments fixed allant eux jusqu'au bord).
     L'anti-décalage de la bascule Aides <-> Protocoles vit désormais DANS les panneaux
     défilants de l'accueil large (.home-side/.home-main), seul endroit où il agit encore. */
  /* FOND SUR `html` AUSSI (v4.23.3) — pas seulement sur `body`. Historique : l'ancien verrou de
     fond mettait `body` en position:fixed, dont la zone non couverte apparaissait comme une bande
     vide en bas — cette règle la MASQUAIT en peignant html. v4.29.9 : ce verrou est REMPLACÉ
     (html{overflow:hidden}) car sur iPhone il ne faisait pas que dépeindre : il RÉTRÉCISSAIT le
     rendu des fenêtres fixées (~60 px coupés en bas, cf. la règle du verrou). Le fond sur html
     RESTE : ceinture universelle (rebond iOS, zones hors flux), suit le thème via :root. */
```

## C8 — Écrans tactiles : `manipulation` garde défilement et pincement, ne retire que le DOUBLE-TAP

```
  /* Écrans tactiles : `manipulation` garde défilement et pincement, ne retire que le DOUBLE-TAP
     ZOOM. Ce que ce réglage évite AUJOURD'HUI, ce n'est plus le délai de ~350 ms (Safari ne l'a
     plus depuis iOS 9.3 pour un viewport `width=device-width`, ce qui est notre cas — la version
     précédente de ce commentaire l'affirmait encore, et cette erreur a servi à justifier de ne pas
     étendre la règle) : c'est le ZOOM PARASITE quand deux taps rapprochés tombent à moins de ~40 px
     l'un de l'autre. En réanimation, on coche des étapes voisines à la chaîne — 12 px mesurés entre
     deux points de tap réalistes. `[role="checkbox"]` a été AJOUTÉ ici (v4.41.0) : les étapes
     cochables du parcours en sont, et 5 d'entre elles restaient en `touch-action:auto` en session
     vive alors qu'AGENTS.md § Interactif énonce l'invariant « tous les contrôles portent
     touch-action:manipulation ». Le précédent `li.md-task[role="checkbox"]` (listes cochables des
     protocoles) le posait déjà : la règle était connue, appliquée à un endroit sur deux. */
```

## C9 — overflow-x:clip = filet anti-débordement horizontal (un enfant trop large ne peut plus

```
  /* overflow-x:clip = filet anti-débordement horizontal (un enfant trop large ne peut plus
     élargir la page ni créer de bande vide à droite sur iOS). 'clip' plutôt que 'hidden' :
     ne crée PAS de conteneur de défilement -> l'en-tête sticky et les scrollers internes
     (aperçu algorithme, barres de puces) continuent de fonctionner. */
  /* LARGEURS (consignes Claude Design ; SOURCE DE VÉRITÉ = AGENTS.md, « Largeurs & échelles
     fermées ». L'ancienne SPEC dédiée a été supprimée quand la règle a été consolidée dans
     AGENTS.md, mais sa citation était restée ici — seule référence pendante du dépôt, trouvée à
     l'audit v5.0.0.) : le CADRE .app est fluide — l'en-tête et le
     pied occupent toute la largeur à tous les écrans ; chaque vue PLAFONNE et CENTRE son
     contenu (l'espace supplémentaire sert au centrage et aux panneaux persistants, JAMAIS à
     allonger les lignes de texte — ~75 caractères max par ligne) :
       accueil  : sidebar 240 + grille <= 1320 (4 colonnes max)  -> main <= 1622px
       fiche    : checklist <= 860 (>= 1200px) + rail 320 -> 360  -> main <= 1282px
       protocole: <= 780px À TOUTES les largeurs
       éditeurs : MÊMES largeurs que la lecture correspondante (demande utilisateur v4.5) —
                  fiche : formulaire <= 860 + aperçu 320 -> 360 ; protocole : <= 780 + aperçu 360 */
```

## C10 — ≥ 1200 : TROIS pistes symétriques — le corps revient exactement au milieu de la fenêtre par

```
    /* ≥ 1200 : TROIS pistes symétriques — le corps revient exactement au milieu de la fenêtre par
       construction, et le sommaire occupe la marge gauche. La piste de droite reste vide : c'est
       le prix d'un texte centré, et c'est l'arbitrage déjà retenu pour la vue fiche. */
    /* ⚠ LE RAIL DE GAUCHE A UN PLANCHER. Sans lui, la piste `1fr` valait 168 px à 1200 : le
       sommaire passait de 260 à 168 puis revenait à 260 — un rétrécissement au moment PRÉCIS où
       l'on gagne de la place, c'est-à-dire l'inverse de ce qu'on attend. Avec `minmax(260px,1fr)`
       il ne rétrécit jamais ; c'est la piste de DROITE qui absorbe, et le corps se recentre
       PROGRESSIVEMENT (décalage 92 px à 1200, nul à partir de ~1370). Un mouvement continu, jamais
       un saut. */
    /* ≥ 1200 : la grille canonique, avec la piste de droite VIDE — une référence n'a pas d'état
       à porter. Le corps garde sa largeur de lecture (780 px reste le plafond documenté d'un
       document qu'on LIT, v4.x) : c'est la seule dérogation, et elle porte sur le CONFORT DE
       LECTURE d'un texte long, pas sur la grille. */
```

## C11 — EN-TÊTE CLAIR par défaut (inversion 4.0.0) : la barre prend la couleur du fond de page —

```
  /* EN-TÊTE CLAIR par défaut (inversion 4.0.0) : la barre prend la couleur du fond de page —
     plus de bloc coloré détaché sur l'accueil, le bleu se retire dans les ACCENTS (indicateur
     d'onglet, focus) — et redevient TEAL PLEIN en mode crise (.crisis, posée par render()) :
     l'immersion colorée reste la signature fonctionnelle de la crise. Un hairline sépare la
     barre du contenu qui défile dessous (mêmes fonds). */
  /* EN-TÊTE CLAIR PARTOUT (accueil, lecture, édition) : plus aucune recoloration du chrome.
     Le MODE CRISE se signale par le BANDEAU D'ÉTAT étiqueté #crisisBand sous la barre (pattern
     des systèmes critiques : texte + couleur + position, trois canaux redondants) — la barre
     reste identique, le titre de la fiche prend l'emplacement et le corps du titre d'accueil. */
  /* Barre à ESPACES CONFORTABLES, de hauteur CONSTANTE : rien ne se replie au défilement. Un
     repli « grand titre » iOS était décrit ici, mais sa règle n'a jamais existé — et il serait
     contraire à la doctrine du chrome de crise (un en-tête qui raccourcit son encombrement de
     flux fait remonter tout le contenu d'un coup). Seul le TITRE entre dans la barre, par relais
     mesuré (.ttl-on), sans changer sa hauteur. Jamais de texte tassé. */
  /* ⚠ L'EN-TÊTE SUIT LE VIEWPORT VISUEL (signalé à l'usage : « si clavier ouvert en mode
     smartphone/tablette, l'en-tête n'est plus sticky, donc on perd la barre de recherche »).
     Même cause que les couches plein écran de la v5.10.9, et je l'avais explicitement laissée
     hors de portée là-bas — « le chrome collant de la PAGE est ancré au viewport de mise en page
     avec le document qu'il commande ». L'usage tranche : ouvrir le clavier PANORAMIQUE le viewport
     visuel dans le viewport de mise en page, et un `sticky` calé sur `top:0` de ce dernier passe
     AU-DESSUS de l'écran — on perd la barre au moment précis où l'on tape dedans.
     `--vvt` porte ce décalage (÷ --zf comme toute mesure réinjectée, règle v4.24.0). À clavier
     fermé elle vaut 0 et la règle est à l'octet celle d'avant.
     ⚠ CE QUI RESTE HORS DE PORTÉE, et c'est dit : les défileurs INTERNES (la colonne `.home-main`
     de l'accueil large) ne sont pas le viewport — leur `sticky` se règle sur leur propre bord, et
     le panoramique du clavier ne s'y applique pas de la même façon. Le cas signalé est le
     téléphone et la tablette, où la page EST le défileur. */
  /* ═══ CLAVIER LOGICIEL OUVERT : RIEN N'EST ÉPINGLÉ (v5.13.0) ═══════════════════════════════
     Décision de l'auteur après onze versions de correctifs, et c'est la seule qui SUPPRIME la
     classe de défauts au lieu de la déplacer.
     LE PROBLÈME, DIT SIMPLEMENT : sur iOS, ouvrir le clavier ne rétrécit pas le viewport de MISE
     EN PAGE — il PANORAMIQUE le viewport visuel à l'intérieur. Or c'est au premier que se calent
     `position:fixed` ET `position:sticky` (les deux, contrairement à ce que la v5.12.10 avait
     supposé). Tout chrome épinglé sort donc de l'écran, et le poursuivre avec une variable
     recalculée à chaque évènement, c'est courir après une cible que le système déplace pendant
     qu'on la vise : onze versions y ont été passées, avec pour seul résultat de remplacer une
     disparition par des sauts — l'auteur a vu tour à tour l'en-tête absent, l'en-tête poussé vers
     le bas avec du contenu au-dessus, et le volet qui saute à chaque frappe.
     CE QU'ON FAIT À LA PLACE : on ne poursuit rien. Le temps que le clavier est ouvert, le chrome
     REDEVIENT DU FLUX — il défile avec la page, comme n'importe quel contenu. Rien ne peut plus
     sauter, puisque plus rien n'essaie de tenir une position. Et ce qui compte pendant la frappe
     reste sous les yeux : le navigateur garde LE CHAMP FOCALISÉ visible, c'est son travail et il
     le fait bien — mieux que nous, puisqu'il est le seul à savoir où il vient de panoramiquer.
     CE QU'ON PERD, ET C'EST ASSUMÉ : pendant la frappe, l'en-tête et le sommaire ne sont plus
     épinglés ; ils reviennent à leur place dès que le clavier se ferme. On échange une position
     tenue par intermittence contre un comportement stable et prévisible.
     ⚠ LES COUCHES PLEIN ÉCRAN NE SONT PAS CONCERNÉES : une fenêtre modale, la visionneuse ou
     l'écran d'entrée d'un invité n'ont pas de flux où retomber — elles RECOUVRENT la page. Elles
     gardent le dispositif de la v5.10.9 (`--vvh` + `--vvt`), que l'usage avait confirmé.
     ⚠ ET C'EST UNE CLASSE, PAS UNE MEDIA QUERY : la présence d'un clavier ne se déduit d'aucune
     largeur. `html.kbd` est posée par l'observateur du viewport visuel, sur le même prédicat que
     `--vvt` (un clavier OCCUPE de la hauteur). */
```

## C12 — ⚠ ON NE LIBÈRE JAMAIS LE CONTENEUR DU CHAMP QU'ON TAPE, et c'est la correction d'une

```
  /* ⚠ ON NE LIBÈRE JAMAIS LE CONTENEUR DU CHAMP QU'ON TAPE, et c'est la correction d'une
     régression que j'ai introduite en écrivant cette règle (signalée à l'usage : « la barre suit
     bien au scroll SAUF avec le clavier, dans ce cas out of view, ça remonte et je ne vois pas ce
     que je tape »). J'avais rendu au flux la barre fixée d'une référence ET la colonne sommaire —
     or c'est là que vit le champ de recherche. Rendus au flux, ils reprennent leur place EN HAUT
     DU DOCUMENT ; le navigateur, qui doit montrer le champ focalisé, n'a alors qu'un moyen : y
     ramener la page. D'où le retour en haut, et la perte de l'endroit qu'on lisait.
     LA RÈGLE EST DONC PLUS PRÉCISE QU'« ON LIBÈRE TOUT » : on libère la DÉCORATION — ce qui
     oriente, annonce, commande —, jamais le logement de ce qu'on est en train d'écrire. Celui-là
     reste épinglé : c'est le seul élément dont le navigateur garantit lui-même la visibilité, et
     le laisser fixe est ce qui permet de taper sans perdre sa page. */
  /* Le rail A→Z est `fixed` et ne peut pas retomber dans un flux : il n'en a pas. Pendant la
     frappe il ne sert à rien (on tape, on ne vise pas une lettre) et il flotterait à côté de la
     zone visible — il se retire, et revient avec le clavier. */
```

## C13 — Compact (< 780px, icône seule) : cercle 40px — même gabarit que .hdr-new compact ;

```
  /* Compact (< 780px, icône seule) : cercle 40px — même gabarit que .hdr-new compact ;
     en large le libellé revient et le bouton reprend la forme pilule. */
  /* Thème et « Créer » : des GLYPHES DE COMMANDE (A13), pas des pastilles teintées. Trois
     disques bleus alignés en tête d'écran pesaient plus que l'annuaire qu'ils surmontent. */
  /* (A−/A+ : absents de Claude Design — la taille du texte se règle dans la fenêtre Compte.) */
  /* Menu ⋯ (SPEC gestion §4) : bouton 36px (halo 44), menu ancré sous la barre à droite,
     rangées 44px — regroupe les actions de GESTION, remplace les barres d'actions de bas de page.
     Jamais d'action destructive ici (Supprimer reste dans l'éditeur). */
  /* ⚠ 36 px DE DESSIN COMME SES VOISINS, 44 DE CIBLE PAR LE HALO (v5.6, signalé à l'usage : « les
     boutons de l'en-tête ne sont pas de la même taille »). Il était le seul à 44 px de DESSIN :
     sur une rangée de trois glyphes, le plus gros se lit comme le plus important, alors qu'il
     n'ouvre qu'un menu d'actions secondaires. La cible réglementaire ne bouge pas d'un pixel —
     c'est tout l'objet du halo, et la recette est déjà celle de « Créer » et du thème. */
```

## C14 — LE MENU NE DÉPASSE JAMAIS L'ÉCRAN (correctif — « si le menu est grand et la hauteur de la

```
  /* LE MENU NE DÉPASSE JAMAIS L'ÉCRAN (correctif — « si le menu est grand et la hauteur de la
     fenêtre réduite, il ne s'adapte pas », puis « et pareil, menu ⋯ tronqué » en GRANDE POLICE).
     En lecture il porte jusqu'à seize rangées, et en grande taille de texte chaque rangée passe sur
     deux ou trois lignes : les dernières — dont « Terminer la session… » — tombaient hors de
     l'écran SANS défilement, donc inatteignables en silence.
     LA HAUTEUR EST POSÉE PAR LA MESURE, PAS PAR UN `calc()` (v4.73.2). La première version
     l'exprimait en CSS : `var(--vvh) / var(--zf) - var(--hdr-h) - 16px`. Le calcul est juste sur
     Blink et l'est resté FAUX en pratique, parce qu'il repose sur trois hypothèses de plateforme à
     la fois — ce que `visualViewport.height` compte sous `zoom`, comment le zoom d'`<html>` se
     combine aux unités de fenêtre, et ce que vaut `--hdr-h` quand `env(safe-area-inset-top)` s'y
     ajoute. Le dossier « bande basse iOS » a déjà montré qu'aucune de ces trois-là ne se déduit :
     elles se MESURENT. `fitMoreMenu()` lit donc la position réelle du menu et la hauteur réellement
     visible, et pose la hauteur en pixels — un seul chemin, valable sur les deux moteurs et sous
     n'importe quel réglage. `overscroll-behavior:contain` : arrivé au bout du menu, on ne fait pas
     défiler la page derrière. */
```

## C15 — Clavier ouvert : le dock LOGE le champ qu'on tape — il ne se retire jamais (v5.13), il se

```
  /* Clavier ouvert : le dock LOGE le champ qu'on tape — il ne se retire jamais (v5.13), il se
     cale au bas du viewport VISUEL (--vvt/--vvh : couche calée sur le viewport, exemptée par
     check-stick). 84 px = hauteur du dock hors zone sûre. */
  /* v5.18.1 (signalé sur iPhone : « barre très moche clavier ouvert ») — l'ancrage par
     CONSTANTE de hauteur (top = bas du viewport − 84 px, − 128 avec la rangée de filtres)
     laissait un vide au-dessus du clavier dès que la géométrie réelle divergeait (barre
     d'accessoires, réglages). Le bas du dock épouse désormais EXACTEMENT le bas du viewport
     visuel : top = vvt + vvh, remonté de sa PROPRE hauteur (translateY(-100%) — transform
     statique, aucune constante, la rangée de filtres comprise). Et clavier ouvert, le dock
     flotte en plein écran : matière OPAQUE + filet haut (le fondu est la robe du bas d'écran,
     pas d'une barre ancrée au clavier — A222). */
```

## C16 — V5 : bandeau TITRE du mode crise — le titre de la fiche vit ici en permanence (toujours

```
  /* V5 : bandeau TITRE du mode crise — le titre de la fiche vit ici en permanence (toujours
     lisible en crise, canvas turn 6), registre ALERTE, bord à bord.
     v4.70.1 : il ne porte PLUS « ■ MODE CRISE ». Cf. « DEUX ANNONCIATEURS, DEUX OFFICES »
     plus bas — la barre dit le MODE, le bandeau ne dit que l'EXCEPTION. */
  /* ZONE HAUTE DE CRISE (v4.23.0) — deux éléments, deux comportements, hors de l'en-tête :
       #crisisBand  = le TITRE. Information CONSTANTE -> il vit dans le flux et s'en va au
                      défilement ; #hdrCrisis en prend le relais dans la rangée d'identité.
       #cbTimers    = l'ÉTAT VIVANT (session, minuteur échu). Information qui CHANGE -> rangée
                      COLLANTE sous l'en-tête, elle ne quitte jamais l'écran. C'est la zone de
                      statut permanente de l'ECAM : ce qui bouge reste sous les yeux, et il n'y
                      a donc AUCUN chrono condensé à loger dans la barre (une version miniature
                      y était illisible — retour d'usage).
     Ni l'un ni l'autre n'est DANS header.bar : un en-tête qui se replie raccourcit son propre
     encombrement de flux et fait remonter tout le contenu d'un coup. Ici la hauteur d'en-tête
     est CONSTANTE, le bandeau glisse dessous et la rangée se cale — aucun saut, aucune
     compensation de scroll à écrire, rien à inhiber sous prefers-reduced-motion (le seul
     mouvement est le geste de défilement : compositeur, réversible au pixel — même doctrine
     que le fil d'ancêtres collant, v4.22.1).
     BANDEAU BLANC (décision utilisateur) : un bandeau d'état PERMANENT teinté en rouge
     désensibilise au rouge. L'ECAM réserve la couleur aux alertes RÉELLES — ici le minuteur
     échu (ambre) et les étapes critiques (rouge) ; le statut, lui, s'annonce en TEXTE. Le rouge
     du mode crise ne subsiste donc que dans le libellé « ■ Crise » et son glyphe — porté par
     la barre depuis la v4.70.1, plus par le bandeau. */
```

## C17 — QUAI DE CRISE (v4.23.0, canvas 2a/3a) : rangée PLEINE LARGEUR et COLLANTE sous l'en-tête.

```
  /* QUAI DE CRISE (v4.23.0, canvas 2a/3a) : rangée PLEINE LARGEUR et COLLANTE sous l'en-tête.
     Elle porte l'état vivant (minuteurs) et l'accès permanent au Plan — les deux choses qui
     doivent rester joignables où que l'on soit dans le journal.
     52px de haut : chaque cible dépasse les 44px exigés d'un contrôle du mode crise.
     --hdr-h : hauteur RÉELLE de l'en-tête, mesurée et posée par syncHdrScroll (elle varie avec
     l'encoche, la taille du texte et la rotation — une constante aurait laissé le quai flotter
     sous la barre ou passer dessous). Un top:0 le ferait glisser SOUS l'en-tête.
     z-index 15 : au-dessus du contenu, sous l'en-tête (20) et sous les modales (55). */
  /* RANGÉE DE COMMANDES (v4.25.0) — l'ECP : ce que je commande. Collée directement sous
     l'en-tête, au-dessus de l'état, parce que le MODE gouverne l'existence de « Se repérer ». */
  /* ⚠ LES TROIS RANGÉES DU HAUT PARTENT DU MÊME x (signalé à l'usage : « aligne le compteur de
     session sur Tout voir »). Mesuré : à 900 px, « Tout voir » était à 10, la session à 18 et le
     contenu à 18 — c'est donc la RANGÉE DE COMMANDES qui était décalée, pas la session, et la
     demande s'inverse : on aligne les commandes sur les deux autres. Sous 780 px, l'inverse : la
     session était à 0, alignée sur rien, et on ne peut pas la porter à 18 sans voler 14 px à une
     rangée dont chaque pixel est compté à 320 (cf. `fitCtrlRow`) — elle prend donc le retrait des
     commandes, palier par palier. Une verticale au-dessus de 780, une au-dessous : jamais deux. */
```

## C18 — (Les commentaires du sélecteur de mode — écart `.ctrl-sp`, géométrie/registre/graisse de la

```
  /* (Les commentaires du sélecteur de mode — écart `.ctrl-sp`, géométrie/registre/graisse de la
     pastille `#modeSeg` — sont partis avec le composant, PURGÉ au lot A v5.0.0, règle 14 ; la
     doctrine de la pastille vit sur le composant `.seg` générique et dans AGENTS.md.) */
  /* RANGÉE D'ÉTAT — l'affichage : ce qui se passe. Collée sous l'en-tête. (Elle se collait sous
     la rangée de commandes #crisisCtrl via `--ctrl-h` ; la rangée est partie en v5.6 — dock bas —
     et la variable, restée écrite à 0px à chaque scroll pour un élément inexistant, est PURGÉE en
     v5.10.2 : son `top` ne cumule plus que la hauteur d'en-tête.) */
  /* LA CAPSULE D'ÉTAT (lot 2) — matière SYSTÈME, l'un des deux seuls objets sombres du produit.
     Elle ne porte plus de bande : c'est la MATIÈRE qui la sépare du travail, plus un filet. Son
     conteneur reste collant sous l'en-tête et transparent — la capsule flotte sur l'ambiance.
     A9 — HAUTEUR D'ÉTAT FIXE : 50 px de haut quel que soit l'état (veille, échu, alarme). Un
     changement d'état NON commandé ne déplace jamais rien ; seule l'expansion COMMANDÉE par un
     tap (le volet) a droit à la hauteur. */
```

## C19 — Accès au Plan : contour, jamais rempli (« un seul bouton rempli par écran » — le rempli est

```
  /* Accès au Plan : contour, jamais rempli (« un seul bouton rempli par écran » — le rempli est
     « Continuer », dans l'action). Libellé en toutes lettres dès qu'il y a la place ; en dessous,
     le glyphe seul garde son aria-label. */
  /* 15px : même corps que ‹ Bibliothèque (.hdr-back), l'autre contrôle de navigation du chrome
     de crise. 13px n'était en défaut d'AUCUNE règle (WCAG 2.2 ne fixe pas de taille minimale, le
     plancher projet est à 11px et la cible fait 52px) — mais c'était le plus petit libellé
     d'action de l'écran, lu à bout de bras et sous stress. La saillance doit suivre le rôle. */
  /* Plan est le PREMIER segment de la bande (< 780) : pas de filet à gauche (bord du quai), un
     filet à DROITE le sépare de « ● Session ». À ≥ 780 il redevient une carte détachée. */
  /* ⚠ MÊME HAUTEUR PARTOUT, ET ELLE NE COÛTE RIEN (signalé à l'usage : « en dessous de 780 px le
     bouton se rétrécit encore, sans raison valable » — vérifié, il n'y en avait pas). Il tombait
     de 46 à 38 px sous ce seuil, en s'en remettant au halo `::after` pour atteindre les 44 px de
     cible. Or MESURÉ, la rangée fait 59 px des deux côtés : c'est le sélecteur de mode (46 px) qui
     la dimensionne, pas ce bouton. Le rétrécissement ne rendait donc AUCUN pixel — il ne faisait
     que désaligner les deux contrôles de la même rangée et rendre la cible dépendante d'un halo
     qui ne se mesure pas. */
  /* ══ LE DOCK DE SESSION — quatre touches au pouce (lot 2) ═══════════════════════════════
     Barre BASSE fixe : la doctrine « une seule zone fixe, en haut » visait les notifications
     flottantes, pas une surface de commandes stable (cf. la note de la coque). Matière SYSTÈME,
     comme la capsule : les deux seuls objets sombres, et ils se répondent — l'état en haut, les
     commandes en bas. Marge basse du matériel prise en compte (indicateur d'accueil iPhone). */
```

## C20 — ⚠ LE DOCK RESTE FLOTTANT À TOUTES LES LARGEURS — décision de l'auteur, contre la planche 7c

```
  /* ⚠ LE DOCK RESTE FLOTTANT À TOUTES LES LARGEURS — décision de l'auteur, contre la planche 7c
     qui le voulait en pied de colonne au-delà de 780. Le motif est mesuré : une colonne de
     lecture fait plusieurs milliers de pixels, et un dock posé à son pied met le geste d'entrée
     — comme les quatre touches de session — à un défilement complet de ce qu'il commande. Une
     barre FIXE tient au contraire la promesse de position constante à laquelle tout le
     dispositif est adossé.
     CE QU'ON GARDE DE 7c, ET C'EST SA VRAIE TROUVAILLE : sa LARGEUR. Le dock s'aligne sur la
     COLONNE D'ACTION, jamais sur la fenêtre — sur un cockpit il ne s'étale plus d'un bord à
     l'autre par-dessus l'orientation et l'état, il se cale exactement sous ce qu'il commande.
     La géométrie est celle de la grille canonique (240 · 1fr · 320, gouttière 20), calculée en
     CSS : aucune mesure JS, donc rien à resynchroniser au redimensionnement. */
```

## C21 — RETOUR D'EXCURSION : registre CONFIRMATION et bouton REMPLI — c'est le contrôle qui ramène,

```
  /* RETOUR D'EXCURSION : registre CONFIRMATION et bouton REMPLI — c'est le contrôle qui ramène,
     donc le seul de l'écran qui doit se voir sans être cherché (même grammaire que
     `↩ Reprendre — <bloc>` pendant une complication, v4.26.0).
     ⚠ IL S'APPELLE `dp-back`, PAS `back` — et c'est la leçon de collision de la v4.23.2, rejouée
     ici au prix d'une mesure : `.back` est une classe AUTONOME du projet (le retour d'en-tête) et
     porte `margin-bottom:14px`. En la réutilisant comme modificateur d'état, la rangée de
     commandes gagnait 14 px de haut À L'INSTANT DE LA BASCULE (59 → 73 px, mesuré) et les deux
     boutons se désalignaient de 7 px — un saut de chrome sous le doigt, exactement ce que la
     doctrine interdit. Un modificateur d'état porte TOUJOURS le préfixe de son composant. */
  /* ⚠ EN SOMBRE, `--ok` EST UN REMPLISSAGE CLAIR : l'encre doit être le FOND, pas le blanc —
     mesuré 1,9:1 avec `--on-primary`, c'est-à-dire illisible. C'est la règle déjà écrite pour les
     pastilles du rail (« en sombre l'encre des pastilles = --bg »), qui vaut pour tout aplat vert. */
  /* LE RETOUR D'EXCURSION est le seul contrôle REMPLI VERT du dock — « vous êtes loin de chez
     vous, ceci vous y ramène ». Même registre que « ↩ Reprendre » d'une complication. */
```

## C22 — A2 — À 320 px, LES DEUX OUVERTURES PASSENT AU GLYPHE SEUL (aria-label conservé). Hors du

```
  /* A2 — À 320 px, LES DEUX OUVERTURES PASSENT AU GLYPHE SEUL (aria-label conservé). Hors du
     contrat « le mot Crise jamais au glyphe seul », qui ne vise que le STATUT, pas les commandes :
     les GESTES (⚡︎, ⏱) gardent leurs mots, eux, parce qu'ils écrivent.
     ⚠ CE PALIER EST UNE CLASSE, PAS UNE MEDIA QUERY — RÈGLE 10, ET ELLE A ÉTÉ ENFREINTE ICI
     (audit externe v5.10.0). Écrit `@media (max-width:359.98px)`, il interrogeait la fenêtre du
     PÉRIPHÉRIQUE. Mesuré à 390 px × 130 % : la mise en page dispose de 300 px effectifs,
     `syncZoomWidth()` pose correctement `zw360` sur <html> — et la media query lisait 390, donc
     restait muette : les quatre étiquettes survivaient sur DEUX À TROIS lignes dans des touches
     de 76 px, c'est-à-dire que le palier de compression ne se déclenchait jamais au moment précis
     où l'on en a le plus besoin. C'est mot pour mot le piège que la règle 10 décrit.
     ⚠ ET LE PLUS INSTRUCTIF : c'était le PREMIER lecteur des classes `zw*`. Elles étaient posées
     à chaque rendu et à chaque redimensionnement, et AUCUNE règle du fichier ne les consommait —
     leurs consommateurs étaient partis avec la rangée de commandes en v5.6 (règle 14, appliquée
     au composant mais pas à sa mécanique), le poseur était resté. `check-classes` ne pouvait pas
     le voir : le nom est CALCULÉ (`'zw'+b`), donc hors de portée d'un contrôle statique — la même
     limite que les noms d'icône calculés de `check-icons`. Tout palier de largeur de la zone de
     crise ajouté demain se cale ici, jamais en `@media`. */
```

## C23 — ⚠ ET LE CHROME SE COMPACTE EN HAUTEUR, PAS SEULEMENT EN LARGEUR (audit externe v5.10.0).

```
  /* ⚠ ET LE CHROME SE COMPACTE EN HAUTEUR, PAS SEULEMENT EN LARGEUR (audit externe v5.10.0).
     Le budget d'écran comptait DEUX couches quand il y en a trois — le dock, devenu chrome
     permanent en v5.6, n'était pas dans la somme (cf. `audit-budget`). Compté, il fait passer le
     plancher servi à 30,5 % dès 100 %, et à 39,6 % au plus grand réglage de texte, où PLUS AUCUNE
     étape n'était cochable sans défiler. On rend les pixels là où ils ne coûtent rien : le
     rembourrage. Les CIBLES ne bougent pas — `.sd-key` garde ses 50 px de dessin, le quai ses
     44 px —, seule la respiration cède, et seulement sous 360 px EFFECTIFS, c'est-à-dire là où le
     budget est réellement disputé. */
  /* ⚠ LE REMBOURRAGE BAS NE CHANGE PAS, ET UN TÉMOIN L'A DIT TOUT DE SUITE. A29 colle le volet du
     quai à la capsule par `top:calc(var(--quai-b) - 8px)` : ces 8 px SONT le rembourrage bas du
     quai, « les deux valeurs vivent l'une contre l'autre ». Réduit ici à 4, le volet recouvrait la
     capsule de 4 px au lieu de l'effleurer. On ne compacte donc que le HAUT — la moitié qui
     n'engage personne. */
```

## C24 — « Cons. » sous 560px : TRONCATURE du même mot, pas un autre mot — c'est ce qui distingue cette

```
  /* « Cons. » sous 560px : TRONCATURE du même mot, pas un autre mot — c'est ce qui distingue cette
     abréviation de l'ancien « Réf. », qui donnait deux NOMS au même bouton (retour d'usage : « on
     s'y perd »). Le mot tronqué reste reconnaissable, l'identité du bouton ne change pas. Objectif
     mesuré : rendre au quai la largeur d'un segment de minuteur en étroit. */
  /* ⚠ UN SEUL LIBELLÉ, À TOUTES LES LARGEURS (demande utilisateur). L'abréviation « Cons. »
     datait d'avant la mesure : depuis que `fitCtrlRow` mesure le débordement RÉEL et descend d'un
     palier de compression avant d'enrouler (v4.74.2), la place existe — vérifié de 320 à 430 px
     aux quatre tailles de texte. Un bouton qui change de mot selon la largeur est un bouton qu'on
     relit ; la constance du libellé est la même exigence que la constance de sa position. */
  /* Le libellé « Plan » ne disparaît à AUCUNE largeur : le glyphe ⤢ jouxte le chevron ▾ des
     minuteurs, et deux pictogrammes voisins sans mot se confondent sous stress. Ce sont les
     segments de minuteurs qui cèdent la place (ils s'ellipsent déjà). */
  /* ═══ LES PALIERS DE LA RANGÉE DE COMMANDES NE SONT PLUS DES MEDIA QUERIES (v4.73.1) ══════════
     Signalé à l'usage, EN GRANDE POLICE : « ⤢ Se repérer » coupé net et « ⤢ Consulter » hors
     écran. Le réglage de taille du texte est un `zoom` sur `<html>` : la place réellement
     disponible pour la mise en page vaut donc `largeur ÷ zoom` — 331 px sur un écran de 430 à
     130 % — alors qu'une media query, elle, continue de mesurer la fenêtre du PÉRIPHÉRIQUE et
     répond 430. Les trois paliers de compression (560 / 430 / 400 / 360) ne se déclenchaient donc
     JAMAIS sous zoom, au moment précis où ils sont le plus nécessaires. Mesuré à 430 × 130 % :
     rangée exigeant 594 px visuels pour 430 disponibles, soit 164 px inaccessibles — le même
     débordement SILENCIEUX que la v4.30.0 et la v4.43.0 ont corrigé à zoom 1, et dans la même
     zone de crise.
     C'est la règle 10 sous une forme qu'on n'avait pas encore rencontrée : on savait que les
     HAUTEURS relatives à la fenêtre devaient être divisées par `--zf` ; les SEUILS de largeur le
     doivent aussi, et le CSS n'a aucun moyen de le faire (une media query ne connaît pas `--zf`).
     Les paliers passent donc par des classes posées sur `<html>` par `syncZoomWidth()`, à partir
     de `innerWidth ÷ zoomF()`. **À zoom 1, `innerWidth ÷ 1` EST la largeur de la media query** :
     le comportement est identique au pixel, rien ne change là où rien n'allait mal.
     `@container` a été envisagé et ÉCARTÉ : `container-type:inline-size` implique
     `contain:layout`, ce qui fait de l'ancêtre un bloc conteneur pour les descendants `fixed` —
     donc casserait le menu ⋯, les overlays plein écran et le placard hachuré. Le projet a déjà
     payé ce piège (« fixed dans un ancêtre transformé », v4.21.0).
     L'ORDRE DE DÉCLARATION DÉCIDE TOUJOURS, comme avec les media queries : `zw360` est déclarée
     APRÈS `zw400`, à spécificité égale (0,2,0 contre 0,2,0). Ne pas les intervertir — c'est le
     même piège que les blocs 359.98/399.98 qu'elles remplacent, avec les mêmes conséquences.
     SOUS 400 px (v4.30.0, audit externe — MESURÉ) : la rangée de commandes exigeait 386 px — à
     375 px (iPhone SE/mini) 11 px du bouton « Cons. » étaient ROGNÉS, 26 px à 360 px (Android
     standard), sans défilement horizontal : des pixels INACCESSIBLES. Un débordement SILENCIEUX,
     précisément la catégorie d'écart que ce projet s'interdit (ECAM), dans la zone de crise
     elle-même. On rend les pixels par COMPRESSION (gaps/paddings — recette v4.23.4 de la rangée
     d'identité), JAMAIS par un renommage (règle « troncature du même mot ») ni une 2ᵉ ligne (la
     hauteur de crise est un coût permanent). Mesuré après correctif : ~346 px à 360. Bloc déclaré
     APRÈS les règles 429.98 px (spécificité égale : l'ordre décide — 4ᵉ piège de cascade du
     projet, cf. .cbt-n v4.23.5). Harnais : audit-doctrine « rangée de commandes sans rognage ». */
  /* 320 px SERVI (v4.43.0, décision utilisateur) — WCAG 1.4.10 « Reflow » fixe le plancher à
     320 px, et la rangée y exigeait 348 px : 28 px de contenu ROGNÉS, sans défilement, dans la
     zone de crise. Le bouton restait opérable (44 px visibles, aria-label intact) mais se lisait
     « ⤢ Con », coupé en plein mot. Mesuré identique sur Chromium et WebKit.
     LES PIXELS VIENNENT DE QUATRE POSTES, aucun d'eux n'étant `.ctrl-sp` : bord de rangée 8→4
     (8 px), écarts 6→4 sur trois intervalles (6 px), rembourrage des deux segments de mode 7→4
     (12 px), rembourrage des deux ouvertures 8→6 (8 px). Budget rendu 34 px pour 28 nécessaires,
     donc 6 px de marge — la recette v4.23.4 n'était pas épuisée, elle n'avait simplement jamais
     été appliquée à ces postes-là.
     CE QUI N'ÉTAIT PAS TOUCHÉ : `.ctrl-sp` restait à 4 px — l'écart de Gestalt qui séparait le
     MODE des OUVERTURES (séparation ECP/ECAM de v4.25.0) ; il est parti depuis avec le sélecteur
     de mode (lot A v5.0.0, règle 14). Aucun renommage non plus
     (règle « troncature du même mot ») et pas de 2ᵉ ligne (la hauteur de crise est un coût
     permanent). Les positions restent constantes entre appareils : seules les MARGES bougent.
     Déclaré APRÈS le bloc 399.98 (spécificité égale, l'ordre décide — 5ᵉ piège de cascade du
     projet). Harnais : audit-doctrine mesure désormais 320 en plus de 360/375/390. */
  /* QUAND LA COMPRESSION NE SUFFIT PLUS, LA RANGÉE S'ENROULE (v4.73.1 — doctrine d'ORIGINE ;
     le mécanisme de MESURE qui la servait, `fitCtrlRow`, a été supprimé en v5.6 avec la rangée
     qu'il ajustait : cf. son épitaphe près de `syncZoomWidth`. L'enroulement est depuis NATUREL,
     `flex-wrap` — commentaire suivant. Le raisonnement reste, il explique la règle vivante). La recette de compression (v4.30.0, v4.43.0) est calibrée pour le PLANCHER SERVI,
     320 px. À 130 % sur un écran de 390, la mise en page n'a que 300 px effectifs — sous ce
     plancher — et aucun réglage de marge ne peut plus rendre les pixels manquants. Le choix n'est
     donc plus « compresser ou déborder » mais « un libellé inaccessible ou une seconde ligne ».
     On prend la seconde ligne : quelqu'un qui a choisi la plus GRANDE taille de texte a déjà
     accepté d'échanger de la hauteur contre de la lisibilité — c'est la seule lecture cohérente de
     son réglage. La doctrine « pas de 2ᵉ ligne » vise le coût PERMANENT d'une rangée qui
     s'épaissirait pour tout le monde ; ici elle n'apparaît que lorsque la rangée déborde VRAIMENT.
     LA DÉCISION ÉTAIT UNE MESURE, exactement comme celle du quai (« on écrit, et tant que ça
     déborde on retire un segment ») : `fitCtrlRow()` remettait la rangée à plat, lisait son
     débordement réel, et n'enroulait que s'il existait. Aucun seuil de largeur en dur — ceux qui
     avaient été essayés pour le quai se sont révélés FAUX, et ici ils dépendraient en plus de la
     fonte du système, de la longueur des libellés et du zoom. Corollaire, toujours vrai avec le
     `flex-wrap` naturel : le comportement de tous les appareils servis reste inchangé au pixel,
     puisqu'il n'y a rien à enrouler quand rien ne déborde.
     CE QUI EST PRÉSERVÉ : l'ORDRE des contrôles, les
     libellés ENTIERS (aucun renommage, aucun pictogramme orphelin : « deux pictogrammes voisins
     sans mot se confondent sous stress »), les cibles de 44 px, et la constance positionnelle —
     dans une configuration donnée, tout reste au même endroit. */
  /* LA COUPURE TOMBE ENTRE LES DEUX OUVERTURES — il n'y a plus qu'elles (`.ctrl-sp` est PURGÉ
     avec le sélecteur de mode qu'il séparait, règle 14). L'enroulement est donc NATUREL : la
     rangée passe en `flex-wrap` et coupe au seul endroit possible. Doctrine d'origine (v4.73.1),
     pour mémoire : la coupure devait tomber sur `.ctrl-sp`, le saut de ligne séparant alors le
     MODE des OUVERTURES — sans point de coupure désigné, « Se repérer » restait avec le mode et
     « Consulter » descendait seul, séparant les deux contrôles de même nature (Gestalt). */
```

## C25 — L'ELLIPSE DES INTITULÉS N'A JAMAIS FONCTIONNÉ (correctif v4.47.0). `.seg-l` déclare

```
  /* L'ELLIPSE DES INTITULÉS N'A JAMAIS FONCTIONNÉ (correctif v4.47.0). `.seg-l` déclare
     `text-overflow:ellipsis` depuis l'origine et le commentaire ci-dessous l'attribuait à un
     « min-width:0 du segment » — qui n'existait pas. Sans plancher explicite, `min-width:auto`
     dimensionne le segment sur son contenu le plus large ; en colonne, la règle flex qui annule le
     minimum automatique porte sur l'axe PRINCIPAL, donc sur la hauteur, jamais sur cette largeur.
     Un intitulé un peu long ne se coupait donc pas : il ÉLARGISSAIT le segment (mesuré 346 px pour
     320 de large), la boucle d'ajustement voyait un débordement et EXPULSAIT le segment — quand
     c'était l'ALARME, elle disparaissait au profit d'un « +1 » muet.
     Le plancher est CHIFFRÉ, et c'est ce qui tient les deux bouts : 112 px = la valeur réelle la
     plus large (« 999:59:59 », 95 px) plus les rembourrages du palier étroit. En dessous du
     plancher l'intitulé s'ellipse — un MOT se tronque, c'est admis (cf. « Cons. ») ; au-dessus, la
     valeur ne peut jamais être rognée — un NOMBRE ne se tronque pas, et si la place manque
     vraiment le segment déborde POUR DE BON, donc la boucle en retire un et le « +n » l'annonce.
     Vérifié aux deux extrêmes sur Chromium ET WebKit. Le bloc ≥ 780 px porte déjà son propre
     plancher (132 px, cartes détachées). */
  /* Un segment est une LIGNE, plus une colonne : dans une capsule de 50 px, l'empilement
     libellé/valeur volait la hauteur que A9 fige. Le gabarit de 30 px est le MÊME en veille et en
     alarme — seuls matière, couleur et texte changent. */
```

## C26 — ⚠ SOUS UNE BARRE COLLANTE, LE REMBOURRAGE DE PAGE SE LIT COMME DU VIDE (v5.7, signalé à

```
  /* ⚠ SOUS UNE BARRE COLLANTE, LE REMBOURRAGE DE PAGE SE LIT COMME DU VIDE (v5.7, signalé à
     l'usage : « trop d'espace mort entre le bandeau session et Ne pas oublier »). Mesuré en
     session : 18 px à 390, 24 px à 1280 entre le bas du quai et le chapeau. Ce rembourrage est
     juste sur une page qui commence sous rien ; en session, le quai FERME déjà le haut, et l'écart
     ne sépare plus deux objets — il éloigne le premier du bord qui le porte.
     Borné à la SESSION, où chaque pixel au-dessus de la première ligne actionnable est compté par
     `audit-budget` : hors session, l'écran d'entrée garde sa respiration. */
  /* ⚠ 8 → 4 px (audit externe v5.10.1, signalé à l'usage : « réduis ENCORE l'espace »). Le
     raisonnement ci-dessus tenait ; il s'arrêtait à mi-chemin. En session le quai FERME le haut,
     donc ces pixels ne séparent pas deux objets — ils éloignent le premier du bord qui le porte,
     et 4 px suffisent à ce que le chapeau ne colle pas au filet. */
```

## C27 — « +n » et chevron sont des <span> DANS le bouton #cbTimers (jamais tapables seuls) : leur

```
  /* « +n » et chevron sont des <span> DANS le bouton #cbTimers (jamais tapables seuls) : leur
     rembourrage de 14px n'obéit à aucune règle de cible et coûtait 78px à eux deux. En étroit on
     le resserre — mesuré, c'est ce qui rend la place d'un segment de minuteur. DÉCLARÉE APRÈS la
     règle de base : à spécificité égale une media query ne l'emporte QUE par l'ordre (piège déjà
     rencontré sur .read-grid — placée avant, elle était silencieusement sans effet). */
  /* ≥ 780px : les segments cessent de s'étirer et deviennent des CARTES détachées (le vocabulaire
     du rail des maquettes tablette/desktop). Les cartes nominales restent en contour NEUTRE —
     seule l'échue prend le registre ATTENTION : une bande de statut ne se colore pas.
     CLUSTER À GAUCHE (ECAM) : ⤢ Plan puis ● Session, tous deux AVANT les minuteurs — donc à
     position FIXE quel que soit leur nombre ; les minuteurs coulent à droite, le blanc part au
     bord droit (barre d'outils normale). Aucun vide central, aucun élément qui se déplace. */
```

## C28 — LOGO DE MARQUE (v4.23.1) — ACCUEIL SEULEMENT, comme le nom de l'app qu'il accompagne

```
  /* LOGO DE MARQUE (v4.23.1) — ACCUEIL SEULEMENT, comme le nom de l'app qu'il accompagne
     (règle SPEC §5 : la marque ne vit que sur l'accueil ; ailleurs la barre porte le retour et le
     titre du contenu). On sert `favicon.svg` : c'est le master VECTORIEL à coins arrondis, déjà
     précaché par sw.js (donc hors ligne) — les icônes d'application, elles, sont des carrés pleins
     destinés au masque d'iOS/Android et afficheraient un angle vif ici. `alt=""` : le nom « Aides
     cognitives » est juste à côté, le logo n'ajoute aucune information pour un lecteur d'écran.
     COLORABLE PAR MASQUE : on ne peut pas teinter un <img>, donc le glyphe (`logo-glyph.svg` —
     le master SANS tuile, seul son canal alpha sert) est posé en masque sur un aplat de couleur.
     Il suit ainsi le THÈME et l'ACCENT par construction, au lieu d'être un bleu fixe qui jurait
     avec les accents violet/framboise et pesait en thème sombre. */
  /* ⚠ UN LOGO SE CALE SUR SON DESSIN, JAMAIS SUR SA BOÎTE (v5.0.5, signalé à l'usage : « rapproche
     le logo de “Aides cognitives”, ça fait très étrange »). La v5.0.0 le CENTRAIT dans le blanc de
     gauche (`position:relative; left:-4px`) : bonne intention — il paraissait collé au texte —,
     mauvais repère. Centrer une marque dans une gouttière la fait FLOTTER, alors qu'un logo et son
     mot-marque se lisent comme UN objet ; et la mesure disait déjà l'inverse de l'impression :
     l'écart optique au texte valait 14,5 px quand celui au bord n'en valait que 2.
     LA CAUSE EST DANS LE MASQUE : `logo-glyph.svg` porte son propre blanc — mesuré au canvas,
     l'encre occupe x ∈ [181, 878] sur 1024, soit **17,7 % à gauche et 14,3 % à droite** (6,0 et
     4,9 px à 34 ; 5,3 et 4,3 à 30). La boîte de 34 px n'a donc jamais été le logo : on calait un
     rectangle dont un cinquième était vide.
     ⚠ CES CHIFFRES SONT UNE MESURE, ILS SE REJOUENT APRÈS TOUT CHANGEMENT DU DESSIN (v5.6) :
     l'amincissement du trait s'est fait vers l'INTÉRIEUR — rayon extérieur gelé à 228 dans
     `scripts/build-icons.mjs` — précisément pour que la borne GAUCHE, qui est celle sur laquelle
     la marge de page s'aligne, ne bouge pas d'un pixel (181, inchangée). La borne droite, elle,
     est portée par la pointe de la coche et a reculé de 0,35 px à 34 : sous le demi-pixel, donc
     les marges restent au cran. Au-delà, ré-arrondir −6 / −4 sur l'échelle d'espacement.
     ON ROGNE DONC LA BOÎTE SUR L'ENCRE, par deux marges négatives prises sur l'échelle
     d'espacement (−6 / −4, les deux insets arrondis au cran). Deux conséquences, et ce sont les
     deux demandes : l'encre commence **exactement à la marge de page** — donc alignée sur les
     rangées du répertoire dessous, ce qu'on attend d'un logo —, et le `column-gap` de la rangée
     devient l'écart optique RÉEL (14,5 → 10 px à 34). Rien n'est ajouté ni élargi : le rognage
     REND 10 px de largeur à la rangée d'identité, celle qui se dispute chaque pixel à 320.
     Les valeurs valent pour les deux tailles (à 30 px l'écart au cran est de 0,7 px, invisible) :
     un second jeu par palier ferait deux vérités pour un seul dessin. */
```

## C29 — ⚠ 320 px — L'ACCUEIL N'AVAIT JAMAIS REÇU LA RECETTE (v5.0.3, signalé à l'usage : « pourquoi ça

```
  /* ⚠ 320 px — L'ACCUEIL N'AVAIT JAMAIS REÇU LA RECETTE (v5.0.3, signalé à l'usage : « pourquoi ça
     ne passe pas en 320 px ? »). La v4.43.0 a déclaré ce plancher SERVI et l'a mesuré sur la rangée
     de crise et sur la barre des éditeurs — jamais sur l'en-tête d'ACCUEIL, qui est pourtant le
     premier écran ouvert. Mesuré : logo 30 + mot-marque 126 + actions 136 = 292 px, plus deux
     écarts de 8, soit 308 px pour 284 disponibles. `.id-row` est en `flex-wrap`, et le flex CASSE
     LA LIGNE avant de rétrécir (leçon v4.23.4) : les trois boutons ronds tombaient sur une seconde
     rangée et l'en-tête payait **38 px de haut**, là où la hauteur est la plus rare.
     24 px manquaient, la recette en rend 28, et elle ne touche NI le mot-marque NI le logo — que
     l'audit A3-1 vient de calibrer : écarts (−8, −8) et taille des boutons (−12). 36 px reste
     au-dessus du plancher de 32 px (règle 9, hors crise) et le halo `::after` porte la cible à
     44 px : c'est exactement ce que la doctrine admet en zone haute pour ne pas l'épaissir.
     ⚠ DIX-NEUVIÈME PIÈGE DE CASCADE, rencontré en l'écrivant : `header.bar.home .id-row` vaut
     (0,3,1) — la MÊME spécificité que la règle `column-gap:8px` du bloc 429.98 juste au-dessus.
     Placé plus haut dans la feuille, ce bloc était silencieusement sans effet (mesuré : 8 px
     obtenus pour 4 demandés). Il est donc déclaré APRÈS, comme la v4.43.0 l'avait déjà fait pour
     la barre des éditeurs — pour une GÉOMÉTRIE, on ne dépend jamais de l'ordre sans le dire. */
  /* ⚠ 400 px — LE PALIER INTERMÉDIAIRE, TROUVÉ PAR LA MESURE DE LA MARGE. À 360 px la rangée
     tenait sur une ligne avec **6 px** de réserve : vrai aujourd'hui, faux au premier rendu de
     police un peu plus large. Le mot-marque mesure d'ailleurs 126 px sur Chromium complet et
     **136 sur le headless shell** — 10 px d'écart pour le même code, soit davantage que la
     réserve. Un booléen « ça tient » reste donc vert jusqu'au dernier pixel puis casse d'un coup
     en +38 px de hauteur : c'est la MARGE qu'il faut tenir, et le témoin la mesure.
     Recette LÉGÈRE ici — les écarts seuls (−8, −8), les boutons gardent leur taille : 22 px de
     réserve à 360 au lieu de 6. La recette complète reste réservée au plancher de 320. */
```

## C30 — LA CIBLE NE DESCEND PAS AVEC LE BOUTON : le halo passe de 4 à 6 px, donc 32 + 12 = 44 px,

```
    /* LA CIBLE NE DESCEND PAS AVEC LE BOUTON : le halo passe de 4 à 6 px, donc 32 + 12 = 44 px,
       la cible d'origine au pixel près. C'est tout l'objet d'un halo en zone haute — rétrécir le
       DESSIN sans rétrécir la CIBLE. Règle propre plutôt qu'un membre de plus dans la liste
       générique `:is(.hdr-new,…)::after` : (0,4,1) gagne par la SPÉCIFICITÉ, jamais par l'ordre
       (dix-septième piège de cascade, où un membre de cette liste écrasait un halo particulier). */
    /* ⚠ ET LE HALO NE MORD PAS SUR LA CIBLE DU VOISIN (v5.6, trouvé au balayage de COLLISIONS) :
       à 320 px l'écart de la rangée vaut 2 px et deux halos de 6 se RECOUVRAIENT de 10 px — dans
       cette bande, c'est le dernier élément du DOM qui reçoit le tap, donc on visait « Créer » et
       l'on ouvrait le Compte. Le halo reste entier en HAUTEUR (il n'y dispute rien) et se borne à
       1 px en largeur : cible 34 × 44, au-dessus du plancher de 32 px qui est la règle HORS crise
       — et plus aucun recouvrement. */
```

## C31 — Titre de la fiche/du protocole dans la barre (révélé au défilement) : ÉCHELLE DU TITRE

```
  /* Titre de la fiche/du protocole dans la barre (révélé au défilement) : ÉCHELLE DU TITRE
     D'ACCUEIL (17px/700, même emplacement) — la hiérarchie typographique ne bouge pas entre
     les vues. Une ligne, ellipsé. */
  /* LA MÊME VOIX QUE LE BANDEAU (correctif — « le texte en police serif ne se met pas à jour dans
     les fiches quand l'en-tête se replie : c'est fait exprès ? » — non, c'est un oubli). Le titre
     de fiche a reçu Source Serif en v4.61.0 sur `#crisisBand .cb-ttl` ; son RELAIS dans la barre
     est resté en `system-ui`, si bien que le même titre changeait de typographie au défilement.
     C'est un seul libellé porté tour à tour par deux éléments (§ « le titre n'est jamais absent,
     seulement porté par l'un ou l'autre ») : il doit se lire pareil des deux côtés.
     Graisse 600 et non 700 : c'est la SEULE graisse embarquée, en demander une autre produirait
     une graisse SYNTHÉTIQUE — plus lourde et moins nette (v4.61.0). Corps inchangé (16,5 px, un
     palier de l'échelle fermée) : c'est la voix qui s'aligne, pas la hiérarchie. */
  /* ⚠ `.bt-d` EST PURGÉE — LE DISCRIMINANT VIVAIT DANS LA CHAÎNE QUI SE TRONQUE (audit externe
     v5.10.0, règle 14 : épitaphe posée ici). K6 avait écrit la bonne règle — « il reste une PILULE
     À PART, jamais dans la chaîne qui se tronque, c'est tout son objet » — et l'implémentation la
     démentait : la pilule était le DERNIER ENFANT de `#brandTitle`, qui porte
     `overflow:hidden ; nowrap ; ellipsis`. Mesuré à 390 px : boîte de 193 px pour 358 px
     nécessaires, la pilule commençant au 308ᵉ pixel — elle n'était donc JAMAIS peinte, et à 130 %
     il ne restait que 32 % du titre. Le champ créé pour distinguer « adulte » de « pédiatrique »
     était exactement ce que la troncature mangeait en premier : le défaut que K6 existe pour
     supprimer, avec une doctrine qui affirmait la protection.
     ⚠ CE QU'ON N'A PAS FAIT, ET POURQUOI. Le sortir en FRÈRE de `#brandTitle` — la réponse
     évidente — lui aurait donné ~50 px pris sur un titre DÉJÀ tronqué à 66 %. Décision de
     l'auteur : ni hauteur d'en-tête en plus, ni titre coupé davantage. Le discriminant rejoint
     donc le SUR-TITRE (`.bs-d`), qui est la ligne d'identité du dessus et qui a de la place :
     MESURÉ, l'en-tête fait 61 px avec ET sans sur-titre — A14 dit vrai, la rangée porte deux
     lignes dans tous les états, et l'afficher coûte donc ZÉRO pixel de hauteur comme de largeur
     de titre. Le titre y regagne même les 50 px que la pilule consommait dans sa chaîne. */
```

## C32 — Icône Compte dans l'en-tête (présence utilisateur), avec pastille d'état de synchro discrète.

```
  /* Icône Compte dans l'en-tête (présence utilisateur), avec pastille d'état de synchro discrète. */
  /* 40px (>= 32 exigés — ce n'est pas un contrôle du mode crise) : c'est lui qui fixe la hauteur
     de la rangée d'identité, la barre d'accueil reste sous ~85px hors encoche. */
  /* Avatar Compte (canvas) : cercle --primary PLEIN, 36px — même gabarit que Créer/Thème. */
  /* L'AVATAR : carré ARRONDI, matière système, initiales (maquette). Le disque bleu plein en
     faisait le plus gros aplat coloré de l'accueil — devant tout contenu clinique —, alors qu'il
     ne porte qu'une identité de fenêtre. La couleur d'ACCENT reste son unique surface (v5.0.0) :
     elle se pose dessus quand un compte est connecté. */
  /* L'avatar au gabarit de la maquette (1a/2f) : 30 px, rayon 10, matière SYSTÈME — le seul
     objet sombre de l'en-tête, comme la capsule est le seul objet sombre de la crise. Sa CIBLE
     reste à 44 px par le halo : on compacte le dessin, jamais la zone qu'on vise. */
```

## C33 — Rappel MINUTEURS toujours visible : 2e ligne de l'en-tête sticky, n'apparaît que si un minuteur

```
  /* Rappel MINUTEURS toujours visible : 2e ligne de l'en-tête sticky, n'apparaît que si un minuteur
     tourne ET que le panneau minuteurs est sorti de l'écran (mis à jour par tickAll). Tap -> remonte
     au panneau. Fait partie de l'en-tête -> aucun calcul de position, reste sous l'encoche. */
  /* (L'ancien rappel minuteurs #rtStrip est FUSIONNÉ dans le bandeau de crise : cf. #cbTimers.) */
  /* CONNECTÉ, il porte les INITIALES sur la même matière : l'identité se lit, elle ne change pas
     la nature de l'objet. Le survol éclaircit la matière système, il ne la remplace pas par un
     aplat d'accent — c'était le « fond bleu » signalé. */
  /* ⚠ LE SURVOL NE PEUT PAS ÊTRE `--sys-2` : c'est un BLANC À 7 % D'OPACITÉ, pensé pour se
     COMPOSER par-dessus la matière système. Employé comme fond, il REMPLACE `--sys` — le disque
     devenait presque transparent et laissait passer le blanc de la barre (signalé à l'usage :
     « le hover du bouton compte ne s'affiche pas correctement »). Il faut une matière OPAQUE :
     `--sys-hi`, le cran clair du système. */
```

## C34 — ⚠ EN SOMBRE, L'EN-TÊTE EST DÉJÀ DE LA MATIÈRE SYSTÈME — LA PASTILLE S'Y DISSOUT (v5.6,

```
  /* ⚠ EN SOMBRE, L'EN-TÊTE EST DÉJÀ DE LA MATIÈRE SYSTÈME — LA PASTILLE S'Y DISSOUT (v5.6,
     signalé à l'usage : « en mode sombre la pastille du compte ne ressort pas »). Mesuré : fond du
     bouton et fond de la barre valent tous deux `--sys`, soit **1,00:1** — les initiales se lisent
     (14,4:1) mais l'OBJET n'existe pas, et WCAG 2.2 § 1.4.11 vise précisément la limite d'un
     composant. C'est le seul contrôle de l'en-tête à porter un APLAT : ses voisins sont
     transparents et se lisent par leur glyphe, ce qui est leur nature ; celui-ci est un DISQUE
     d'identité (A-accent), il doit donc rester un disque.
     Le filet vient de `--ctl-line`, le token que la doctrine assigne aux bordures de composant
     (3:1, « la case qu'on vise avec des gants ») : 3,68:1 mesuré contre la barre. Il est posé en
     ombre INTERNE et non en bordure — le bouton fait 36 px de dessin pour 44 px de cible, et une
     bordure changerait sa boîte, donc son alignement avec ses trois voisins (A30). Le thème CLAIR
     n'en a pas besoin : le disque sombre y vaut déjà 15,8:1 sur le blanc, et l'y ajouter ne serait
     qu'un anneau de plus autour d'un objet qui se voit. */
```

## C35 — Bandeau système (registre INFORMATION persistant : mise à jour de l'app) : pleine largeur

```
  /* Bandeau système (registre INFORMATION persistant : mise à jour de l'app) : pleine largeur
     sous l'en-tête, rejetable, visible SEULEMENT SUR L'ACCUEIL (v4.20.0, retour d'usage : en
     lecture de fiche il glissait sous l'en-tête sticky au défilement — à moitié masqué par le
     bandeau rouge du titre ; et recharger depuis un écran de soin n'est jamais souhaitable —
     l'invitation attend le retour à l'accueil, la nouvelle version arrive de toute façon à
     l'ouverture suivante). */
  /* v5.4.2 — LE BANDEAU SYSTÈME PASSE AU-DESSUS DU RAIL A→Z (signalé à l'usage, capture : le
     fond du rail — fixe, z 15, voile `color-mix` — se peignait PAR-DESSUS « Nouvelle version
     disponible », masquait sa droite et pouvait même intercepter le tap sur son ×, le rail étant
     `touch-action:none` sur toute sa bande). Le bandeau est PLEINE LARGEUR et vit HORS de `main`,
     donc hors de la gouttière que le répertoire réserve au rail (v5.0.3) — il est le seul objet
     de l'accueil à passer sous lui. Sans `position`, un z-index est inerte : les deux vont
     ensemble. z 16 : au-dessus du rail (15), toujours SOUS l'en-tête collant (20) — une
     notification qu'on doit pouvoir lire et REJETER prime sur trois lettres d'index qu'elle
     recouvre transitoirement (le bandeau défile avec le flux, ou se ferme d'un tap). */
  /* ⚠ EXEMPTÉ D'A11, ET IL FAUT LE DIRE (audit externe 9d) : A11 réserve l'APLAT teinté à ce qui
     exige une action MAINTENANT, et n'en admet qu'un seul à l'écran — mais elle vise la SURFACE DE
     CRISE, où une masse colorée de plus vole l'œil à une étape vitale. Ce bandeau ne vit que sur
     l'ACCUEIL (`body.view-home`, v4.20.0) : il n'y a là ni étape, ni alarme, ni registre à
     disputer, et sa teinte est `--primary-soft` — INFORMATION, jamais alerte, exactement la
     taxonomie des notices. Il ne peut pas non plus s'y trouver en même temps qu'une autre masse :
     la notice d'auteur ATTEND qu'il soit acquitté (`sysBannerOn()`), décision de la direction A.
     Étendre A11 à l'accueil interdirait aussi la carte de session vive et la rangée d'épinglées,
     qui sont ce que l'écran existe pour montrer. */
```

## C36 — Tuile : UN SEUL <button> (★ et ● sont des spans — pas de descendant interactif), liseré de

```
  /* Tuile : UN SEUL <button> (★ et ● sont des spans — pas de descendant interactif), liseré de
     catégorie 4px par ::before (même canal --stripe que les anciennes cartes). */
  /* UNE SEULE RÈGLE FLUIDE, PARTAGÉE AVEC LE RÉPERTOIRE (v4.56.1, retour utilisateur « la
     gestion de la largeur des tuiles en responsive est extrêmement mauvaise ») : l'ancien nombre
     de colonnes FIGÉ (2 < 780, 3 au-delà) faisait passer une tuile de ~360 px à ~140 px au
     franchissement du seuil — la sidebar mange l'espace — et son rythme ne coïncidait jamais
     avec celui des rangées. En auto-fill minmax(290px,1fr), MÊME minimum et MÊME gouttière que
     .dir-grid : tuiles et rangées s'alignent colonne pour colonne à toutes les largeurs, chaque
     bulle vit dans la même bande (~290-430 px), et une transition ne change que le NOMBRE de
     colonnes (redistribution en dents de scie bornée, inhérente aux grilles fluides — c'est elle
     qu'on observait vers 1520 px : 3 × ~390 → 4 × ~296), jamais l'échelle. */
```

## C37 — Un long titre ne fait ni déborder ni gonfler la tuile sans borne : 3 lignes max puis

```
  /* Un long titre ne fait ni déborder ni gonfler la tuile sans borne : 3 lignes max puis
     ellipse — demande utilisateur « un peu plus de titre », 2 lignes tronquaient trop pour
     reconnaître la fiche (le nom accessible et l'info-bulle restent le texte complet). 15 px :
     un cran sous les 16 de la maquette, des caractères en plus par ligne au même encombrement. */
  /* 15,5 px — ET NON 16,5 COMME LA RANGÉE DU RÉPERTOIRE (v5.0.0, audit design A3-1 : monté puis
     REVENU, sur signalement à l'usage « les titres s'affichent sur trois lignes et dépassent »).
     Les deux surfaces montrent le même objet, mais elles n'ont pas la même CONTRAINTE, et c'est
     la contrainte qui décide du palier :
       · la RANGÉE a un clamp à 2 lignes dans une boîte FIXE de 71 px, où la mesure montre 6 à
         7 px de marge restante à 16,5 px — le titre grandit, la rangée ne bouge pas ;
       · la TUILE a un clamp à 3 lignes et une hauteur FLUIDE. Mesuré à 16,5 px sur un titre long :
         72 → **107 px**, et comme les tuiles sont des éléments de grille, la rangée ENTIÈRE suit —
         une tuile à titre court passait elle aussi à 107. Rien n'était coupé (débord mesuré
         négatif, clip 0), mais on payait ~35 px par rangée de tuiles, c'est-à-dire exactement le
         budget vertical que ce lot cherche à rendre au contenu.
     ET LE CONSTAT D'AUDIT NE S'APPLIQUE PAS ICI : il disait « la marque est plus grosse que le
     contenu ». Dans une tuile, le titre est DÉJÀ l'élément dominant de sa propre carte — il n'y a
     aucune inversion à corriger. Le clamp à 3 lignes est un réglage mesuré (v4.56.0, demande
     utilisateur « un peu plus de titre ») : le monter à 16,5 le déréglait sans rien gagner. */
```

## C38 — Répertoire : en-tête de lettre (mono, accent texte) + grille de rangées compactes.

```
  /* Répertoire : en-tête de lettre (mono, accent texte) + grille de rangées compactes. */
  /* Direction A (audit v5.0.10) : la lettre de classement en SERIF — un index d'ouvrage, pas du
     chrome d'interface. Graisse 600 = la seule embarquée (v4.61.0) ; le rail A→Z, lui, RESTE en
     mono (cibles minuscules, la lisibilité y prime sur la voix). */
  /* La lettre de classement est en SERIF : c'est un index d'ouvrage, pas du chrome (la même
     voix que les titres de fiches, qui est l'identité clinique de v4.61). En clé « Catégories »,
     elle porte en plus la pastille de la catégorie — la couleur n'est jamais seule, le nom est là. */
  /* ══ LE RÉPERTOIRE EST UN LIVRE, PAS UNE PILE DE CARTES (v5.6, maquette 1a) ════════════════
     Chaque lettre avait SA carte : sur une bibliothèque réelle, l'annuaire devenait un empilement
     de boîtes dont aucune ne dit rien — et le rail d'index, posé à l'extérieur, ne se rattachait
     visuellement à rien. UNE carte contient tout ; les lettres y sont des INTERTITRES avec leur
     filet, et le rail vit DEDANS, contre la marge droite que la carte lui réserve. */
  /* ⚠ DEUX RÉGIMES, ET C'EST CE QUI MANQUAIT (v5.6, signalé à l'usage : « l'affichage des cartes
     d'accueil n'est pas responsive »). En ÉTROIT (maquette 1a) le répertoire est UNE carte, les
     fiches y sont des rangées à filet : un empilement de cartes sur 358 px de large ne serait
     qu'une pile de cadres. En LARGE (maquette 2f) ce sont des CARTES INDIVIDUELLES dans une
     grille fluide : la largeur existe, et une liste d'une seule colonne au milieu de 1 200 px
     laisse le regard traverser du vide. Le basculement suit le palier du rail (780), là où
     l'accueil passe de la voie unique à la coque à deux colonnes. */
  /* v5.18 — le livre s'efface : chaque SECTION (bibliothèque, catégorie ou lettre selon le
     rangement) a son intertitre COLLANT (position:sticky — zéro JS, zéro état ; il colle au
     défileur de sa largeur : la page en étroit, .home-main en large) et sa grille de rangées.
     En étroit la carte est portée par .dir-grid (coins nets, intertitres dehors). */
```

## C39 — Le sélecteur de clé de groupement — grammaire des chips de filtre (c'est de la même famille :

```
  /* Le sélecteur de clé de groupement — grammaire des chips de filtre (c'est de la même famille :
     un objet qui décide de ce qu'on voit), poussé au bout de l'en-tête de section. */
  /* Le sélecteur de clé a SA rangée, au-dessus des sections qu'il réordonne (maquette 1a) : au
     bout du titre « Répertoire », il se lisait comme une propriété de cette seule section, alors
     qu'il gouverne la liste entière. */
  /* ⚠ LA RANGÉE PORTE SA PROPRE RESPIRATION DES DEUX CÔTÉS (v5.6, signalé à l'usage : « le bouton
     filtre peut se coller au bloc du dessous »). Elle n'avait de marge qu'EN HAUT : avec des
     cartes, l'écart venait du titre de section qui suit (16 px mesurés) — donc d'un voisin, pas
     d'elle ; bibliothèque vide, le bloc « Aucune aide » n'en apporte aucune et le bouton Filtres
     touchait le cadre, à 0 px mesuré. Une rangée de contrôles dont l'espacement dépend de ce qui
     la suit change d'aspect selon le contenu de la page.
     12 px EN BAS, et cela ne coûte rien là où l'écart existait déjà : les marges de frères
     ADJACENTES fusionnent (max(12,16)=16), donc le répertoire ne bouge pas d'un pixel — c'est un
     PLANCHER, pas une addition. */
  /* v5.10.5 (demande utilisateur, resserré deux fois : « réduis encore en haut et en bas
     légèrement ») : le sélecteur A-Z/Catégories se cale à 2 px sous l'en-tête et 8 px au-dessus
     du répertoire (valeurs de l'échelle fermée ; l'essentiel du blanc restant est le rembourrage
     de `main`, commun à toutes les vues). */
```

## C40 — ⚠ LA COUCHE ÉTAIT BONNE, SA PLACE NE L'ÉTAIT PAS — trois retours de l'auteur, et le dernier

```
  /* ⚠ LA COUCHE ÉTAIT BONNE, SA PLACE NE L'ÉTAIT PAS — trois retours de l'auteur, et le dernier
     corrige ce que j'avais déduit du premier :
       1. « revois le design du bandeau de sélection qui est fixed, ça rend très mal sur écrans
          moins larges que desktop » + « le bandeau est très bas : A-Z/Catégories et Sélectionner
          disparaît quand il apparaît -> espace mort en haut » ;
       2. « mais si doit rester sticky en scroll » ;
       3. « la couche flottante était parfaite, c'est juste que c'était mal placé car trop
          d'espace mort entre le haut et le bandeau ».
     J'avais lu (1) comme « ne pas flotter » et fondu le bandeau DANS la rangée de groupement —
     ce qui lui coûtait le suivi au défilement, exactement ce que (2) réclamait. (3) tranche : le
     défaut n'était pas de flotter, c'était de flotter LOIN. Le bandeau était inséré en tête du
     RÉPERTOIRE, donc APRÈS le bandeau de jointure, les cartes de session vive et les notices : au
     repos il tombait à ~200 px du haut, et tout ce qui le séparait de l'en-tête se lisait comme
     du vide entre la commande et ce sur quoi elle agit.
     Il est donc redevenu ce qu'il était — une couche collante — mais PREMIER élément de la
     colonne, sous l'en-tête réel (`--hdr-h`, mesurée par `syncHdrScroll` ; patron de
     `#crisisDock`, jamais une constante). Même endroit au repos et en défilement, ce qui est
     exactement ce qu'on attend d'une barre de sélection. Il s'enroule au lieu de se comprimer :
     sur 320 px, sept commandes tiennent en trois rangs lisibles plutôt qu'en une ligne illisible.
     LEÇON DE MÉTHODE, consignée parce qu'elle a coûté deux allers-retours : un retour qui dit
     « ça rend mal » nomme un SYMPTÔME, pas une cause. J'ai supprimé le mécanisme au lieu de
     chercher ce qui, de sa position ou de sa nature, produisait le symptôme. */
  /* ⚠ ET LE DÉCALAGE DÉPEND DE QUI DÉFILE — c'est la cause MESURÉE du « toujours trop bas, crée
     beaucoup d'espace mort » qui restait après la remontée en tête de colonne. Un `sticky` se
     règle sur son PROPRE défileur, et l'accueil en a deux : sous 780 px c'est la PAGE (le
     décalage doit alors valoir la hauteur de l'en-tête fixe, sinon la barre passe dessous), au-delà
     c'est `.home-main` lui-même (`overflow-y:auto`, coque fixe) — et là le même décalage s'ajoute
     À L'INTÉRIEUR du défileur, sous un en-tête qui ne le recouvre pas. Mesuré à 1194 px : bas de
     l'en-tête 61, haut de la barre 189, soit 128 px de vide, dont 61 dus à ce seul `--hdr-h`.
     Deux défileurs, deux décalages : `--hdr-h` en étroit, ZÉRO en large (le second est posé dans
     le bloc ≥ 780 px, auprès de la déclaration qui rend `.home-main` défilant). */
  /* ══ LE CONTENU DE LA BARRE — PLANCHE 20 : UNE LIGNE, 56 px, TOUJOURS ═══════════════════════
     La COQUE ci-dessus ne bouge pas (place collante, matière, périmètre, marge) ; seul ce qu'elle
     porte est repris, sous une contrainte unique : **la barre ne dépasse jamais 56 px de haut**,
     à tout écran et dans tout état.
     CE QUI RENDAIT MAL N'ÉTAIT PAS LA LARGEUR, C'ÉTAIT LA HAUTEUR (planche 20a, mesuré à 390 px) :
     huit objets dans un `flex-wrap` avec une entretoise élastique, donc un rendu étroit SUBI et
     non dessiné — dès que la ligne casse, `.sel-sp{flex:1 1 auto}` n'a plus rien à pousser, les
     commandes se rangent dans un ordre que personne n'a choisi, et « Supprimer… » atterrissait
     JUSTE SOUS « Tout », là où le pouce venait de taper. Le coût réel se payait en hauteur : la
     barre étant collante, ses ~100 px de deux étages restaient à l'écran pendant TOUT le
     défilement, sur le seul axe qui manque sur téléphone. Et cette hauteur était payée pour rien —
     à l'ouverture, QUATRE commandes sur six sont mortes (rien n'est coché).
     `.sel-sp` — l'entretoise élastique — EST PURGÉE (v5.17), pas masquée : elle n'est plus ni
     émise ni stylée, et c'est ici son épitaphe. C'était le COUPLE `flex-wrap:wrap` + entretoise
     qui fabriquait l'ordre aléatoire au repli ; en retirer un seul des deux aurait laissé l'autre
     prêt à le refaire. Le compte devient le seul élément élastique — il porte `flex:1 1 auto` et
     s'ellipse dans SON espace, ce qui garantit qu'aucun autre objet ne peut pousser la ligne.
     Les deux planchers de la règle 9, abaissés ici à 32 px et 11 px sur des commandes dont l'une
     est destructrice, remontent à 40 px et var(--t-body). */
```

## C41 — ⚠ LE SEUIL DE DÉPLIAGE PASSE PAR `html.zw1200`, PAS PAR UNE MEDIA QUERY (règle 10), ET IL EST

```
  /* ⚠ LE SEUIL DE DÉPLIAGE PASSE PAR `html.zw1200`, PAS PAR UNE MEDIA QUERY (règle 10), ET IL EST
     À 1200 px, PAS À 560. Deux corrections à la planche, toutes deux MESURÉES avant d'être
     décidées — la planche dessine ses maquettes à la largeur d'un écran, or ni l'une ni l'autre
     de ces deux quantités n'est celle dont la barre dispose.
       1. PAS UNE MEDIA QUERY. Elle mesure la fenêtre du PÉRIPHÉRIQUE, pas la place de la mise en
          page : sur une tablette de 1000 px au plus grand réglage de texte, la place réelle vaut
          769 px et la media query répond 1000. La barre se déplierait dans une largeur qu'elle
          n'a pas, en `nowrap`, donc en débordement SILENCIEUX — précisément ce que la règle 10
          existe pour empêcher, et que le `nowrap` qu'on vient de poser aggrave.
       2. PAS 560 px. Mesuré : la barre DÉPLIÉE réclame 757 px de largeur UTILE (compte 58 +
          segment 221 + Bibliothèque 121 + Catégorie 104 + Supprimer 107 + filet + Annuler 77 +
          six écarts + rembourrage). Les intitulés de la consigne 5 y sont pour beaucoup —
          « Bibliothèque… » et « Catégorie… » coûtent 33 px de plus que « Déplacer… » et
          « Ranger… ». À 560 px de fenêtre la barre n'a que 514 px : dépliée, elle débordait de
          179 px, le compte écrasé à ZÉRO et tronqué. La maquette 20b tient parce qu'elle se
          dessine à 744 px de BARRE ; à 744 px de FENÊTRE la barre en fait 698.
       3. ET LA LARGEUR DE LA BARRE N'EST PAS MONOTONE EN LARGEUR DE FENÊTRE : à 780 px, la
          colonne de gauche apparaît et lui PREND 224 px d'un coup — mesuré, la barre tombe de
          698 px (fenêtre 744) à 474 px (fenêtre 780). Aucun palier ne peut donc être choisi
          « au plus juste » : il faut celui à partir duquel la barre est large partout au-dessus.
          Mesures : fenêtre 1000 -> barre 694 (insuffisant) ; 1100 -> 794 ; 1200 -> 894. Le palier
          est donc 1200, déjà déclaré dans l'échelle fermée, avec 137 px de marge.
     `@container`, qui mesurerait la vraie contrainte, reste ÉCARTÉ (cf. règle 10). */
  /* REPLIÉ — une seule face du segment, les actes dans le tiroir, « Annuler » réduit à sa croix. */
```

## C42 — ⚠ UN FOND DE RANGÉE VA D'UN BORD À L'AUTRE DE SA CARTE (v5.6, signalé à l'usage, captures à

```
  /* ⚠ UN FOND DE RANGÉE VA D'UN BORD À L'AUTRE DE SA CARTE (v5.6, signalé à l'usage, captures à
     l'appui : « carte avec hover : le fond de sélection ne s'affiche pas sur toute la largeur » et
     « session en cours : le vert ne prend pas toute la largeur »).
     En voie étroite les rangées vivent DANS une carte par lettre, et c'est la CARTE qui porte le
     rembourrage horizontal (16 px) : la rangée commençait donc 17 px après son bord gauche et
     s'arrêtait 17 px avant le droit. Tant qu'elle est transparente cela ne se voit pas — mais dès
     qu'elle prend un fond (survol, ou le vert d'une session vive) le rectangle teinté flotte au
     milieu de la carte, avec deux bandes non peintes de part et d'autre. Mesuré à 390 px : rangée
     de 304 px dans une carte de 338.
     La rangée reprend donc les 16 px en marges NÉGATIVES et les rend en rembourrage : sa BOÎTE va
     d'un bord à l'autre, son CONTENU ne bouge pas d'un pixel. C'est une compensation, écrite comme
     telle — et elle vaut exactement le rembourrage de `.dir-book`, jamais un nombre choisi. */
```

## C43 — ⚠ ET LA COMPENSATION EST BORNÉE AU PALIER OÙ LA CARTE A UN REMBOURRAGE (signalé à l'usage dans

```
  /* ⚠ ET LA COMPENSATION EST BORNÉE AU PALIER OÙ LA CARTE A UN REMBOURRAGE (signalé à l'usage dans
     la foulée : « tu as cassé l'affichage des cartes en 2/3 colonnes »). `.dir-book` perd son
     `padding` à partir de 780 px — posée au niveau racine, la marge négative y tirait donc les
     rangées 16 px HORS de leur colonne. Une compensation vit avec ce qu'elle compense. */
  /* ⚠ ET LE REMBOURRAGE DROIT REDEVIENT CELUI DE GAUCHE (v5.17.6, signalé à l'usage, capture et
     flèche à l'appui : « réduis l'espace entre l'étoile et la fin de la carte sur la page
     d'accueil, surtout en smartphone — c'est là que l'écart est le plus grand et ça sonne
     mauvais »). MESURÉ à 390 px : le titre commence à 16 px du bord de la carte, l'étoile
     s'arrêtait à **47** — presque trois fois plus, sur une rangée dont c'est le seul autre
     objet. La rangée avait l'air de finir avant sa carte.
     Le 40 n'était pas un choix de dessin : c'est 24 (l'ancienne valeur de base) + 16 (la
     compensation de la marge négative ci-dessus), et personne n'avait re-regardé la somme.
     À 16, la déclaration devient SYMÉTRIQUE — même rembourrage des deux côtés —, ce qui est la
     seule forme qu'on retient sans la relire.
     ⚠ IL RESTE 6-7 px D'ÉCART OPTIQUE (étoile à 23 du bord contre titre à 16), ET C'EST VOULU :
     ce sont les flancs de la CIBLE de l'épingle (bouton 30 px pour un glyphe de 18, cf.
     `.dir-row .pinbtn` — WCAG 2.5.8 se mesure sur la boîte, pas sur le dessin). Les rattraper par
     une marge négative collerait la zone tactile au bord de la carte, donc au rail A→Z.
     ⚠ ET C'EST LE RAIL QUI BORNE, PAS LE GOÛT : mesuré à 390 px, la carte finit à 364 et le rail
     commence à 366 ; avec ce rembourrage le halo de l'épingle (`::before`, +4 px) s'arrête à 351,
     soit 15 px de franc. C'est la contrainte à recalculer si l'un des deux bouge — pas le
     nombre 16. */
  /* v5.18 : la carte est la SECTION (.dir-g), intertitre collant DEDANS — au défilement il
     coiffe la carte au lieu de laisser les rangées passer à nu sous lui (signalé à l'usage :
     « la bordure supérieure s'affiche mal »). `overflow:clip` arrondit sans devenir défileur
     (hidden ferait de la carte le scrollport du sticky, qui ne collerait plus jamais). La
     DERNIÈRE rangée rend son filet (sinon il longe le coin arrondi), et le survol ne teinte que
     le FOND — repeindre le seul filet bas dessinait une bordure partielle. */
```

## C44 — ⚠ LES ÉPINGLÉES SONT UN RÉPERTOIRE COMME LES AUTRES (v5.7, signalé à l'usage : « les cartes

```
  /* ⚠ LES ÉPINGLÉES SONT UN RÉPERTOIRE COMME LES AUTRES (v5.7, signalé à l'usage : « les cartes
     épinglées prennent toute la largeur de la page — autant en mettre plusieurs colonnes quand la
     largeur le permet »). Leurs rangées vivaient DIRECTEMENT dans le livre, sans le `.dir-grid`
     que chaque groupe de lettre porte : mesuré à 1280 px, une rangée du répertoire fait 320 px
     (trois colonnes) et une épinglée 976 — pleine largeur, pour l'accès le plus rapide du
     produit. Elles prennent la MÊME grille : c'est la règle « un seul dessin de rangée » (A16),
     et le rythme de l'annuaire ne doit pas changer d'une section à l'autre. */
  /* Rangée : le TITRE est le vrai <button> (clavier natif) et son ::after couvre la rangée ;
     épingle et badge « À compléter » repassent au-dessus via z-index — même patron ARIA APG que
     les anciennes cartes (pas de bouton dans un bouton). Anneau de focus porté par la rangée. */
  /* LA RANGÉE DE RÉPERTOIRE — V2 (v5.0.0, maquette validée). Le défaut réel n'était pas le style
     mais la HAUTEUR VARIABLE : la sous-ligne était une rangée `flex-wrap` de six à sept pilules de
     largeurs quelconques, donc chaque rangée se repliait différemment (52 à 86 px mesurés) et
     l'annuaire n'avait aucun rythme. Elle est désormais À HAUTEUR FIXE, avec un TITRE SUR DEUX
     LIGNES et une MÉTA SUR UNE SEULE, ellipsée.
     ⚠ LE CORPS RESTE SUR L'ÉCHELLE FERMÉE (remarque de l'auteur, et elle a corrigé deux maquettes
     hors échelle) : le titre est à 15,5 px, un palier. Ce qui se resserre pour tenir en 71 px est
     l'INTERLIGNE et le REMBOURRAGE, jamais la police — descendre à 13,5 mettrait le titre d'une
     fiche au corps du TEXTE COURANT, et il perdrait le relief que l'échelle existe pour tenir.
     DEUX ÉCONOMIES GRATUITES, qui rendent la place des deux lignes : la pastille de catégorie est
     REDONDANTE avec le liseré (même couleur, même information — la catégorie reste nommée en
     toutes lettres dans la méta), et l'étoile passe de 34 à 26 px en gardant sa cible de 44 par un
     halo `::after` — patron déjà employé par les contrôles de l'en-tête. */
  /* DEUX colonnes : le contenu, l'épingle. Le CODE a rejoint la méta (maquette) — en colonne
     séparée il prenait une piste au titre et se retrouvait au milieu de la rangée, entre le titre
     et l'épingle, là où rien ne le rattache à ce qu'il nomme.
     ⚠ TOUT ENFANT AJOUTÉ ICI DOIT AVOIR SA PISTE : dans une rangée à hauteur FIXE, un enfant de
     trop passe à la ligne implicite, donc HORS de la boîte, en silence (mesuré une fois : épingle
     à 244 px de large). */
  /* ⚠ CINQ PIXELS SE TROUVENT DANS LE CHROME, PAS DANS UNE COLONNE EN MOINS (signalé à l'usage :
     « ça commence à être juste »). Mesuré avec des données ORDINAIRES, la méta manquait de 5 px à
     la configuration la plus serrée — quatre colonnes de 312 px, entre 1600 et 1690. Élargir la
     piste minimale les aurait rendus, mais en supprimant une colonne entière sur toute cette
     bande : 25 % de fiches en moins à l'écran, pour la queue d'un mot. On les prend donc sur les
     écarts (gap 10 → 5, retrait gauche 14 → 12) et sur le chrome du tag de nature, qui est du
     TEXTE et non une pastille. Mesuré après : 0 item tronqué de 360 à 1900 px, sauf 3 items à
     2 px dans la seule bande des quatre colonnes serrées. */
  /* ⚠ DÉLIMITATION DES COMPOSANTS INTERACTIFS — `--line-strong`, PAS `--line` (v5.0.0, audit
     design A1-3, WCAG 2.2 § 1.4.11). MESURÉ : en thème sombre, une carte (`--surface` #0d0d0f)
     contre la page (`--bg` #0a0a0c) vaut **1,02:1** — autant dire rien — et il ne restait que le
     filet `--line` à **1,60:1**. En clair : 1,18 et 1,39. Le TEXTE se lit parfaitement ; c'est le
     COMPTAGE qui échoue — où finit une rangée, combien y en a-t-il — et c'est précisément ce que
     1.4.11 protège.
     `--line-strong` donne 3,93:1 en clair et 4,94:1 en sombre. Ce n'est pas un token neuf : la
     doctrine l'assigne DÉJÀ aux « bordures de composants, contraste >= 3:1 » (cases à cocher,
     champs de saisie) — on l'étend aux cartes CLIQUABLES, qui sont des composants au même titre.
     ⚠ UN TOKEN `--line-card` A ÉTÉ ENVISAGÉ PUIS ÉCARTÉ : il aurait valu `var(--line-strong)`
     dans les deux thèmes, c'est-à-dire un ALIAS — exactement le défaut relevé sur `--done-ink`
     dans le même audit. On ne corrige pas une duplication en en créant une autre.
     `--line` reste inchangé sur ses 160 autres usages (séparateurs, cadres non cliquables) : le
     déplacer globalement garantissait des effets de bord pour un gain hors périmètre. */
```

## C45 — EN RECHERCHE, LA RANGÉE REPREND SA HAUTEUR NATURELLE (v5.0.0, signalé à l'usage : « en mode

```
  /* EN RECHERCHE, LA RANGÉE REPREND SA HAUTEUR NATURELLE (v5.0.0, signalé à l'usage : « en mode
     recherche le texte dépasse des cartes d'accueil »). Les 71 px fixes sont le RYTHME DE
     L'ANNUAIRE : ils ont été posés pour que le répertoire A→Z ait un pas régulier, sur un contenu
     BORNÉ par construction — titre à 2 lignes, méta à 1. En recherche la rangée porte EN PLUS
     l'extrait contextuel, et la boîte ne peut pas le contenir : mesuré à 360 px, `.dir-main`
     atteint 81 à 99 px pour 71 disponibles, l'extrait dépassant de 10 à 29 px. Il était donc
     CLIPÉ en plein milieu d'une ligne (`overflow:hidden`) — et la rangée étant centrée, le titre
     l'était aussi par le haut : on promettait un extrait et on le rendait illisible.
     LA LISTE DE RECHERCHE N'EST PAS LE RÉPERTOIRE — elle est plate, triée par pertinence, et son
     contenu est variable par nature ; `.dir-grid.flat` est exactement ce marqueur. Le rythme n'est
     pas abandonné pour autant : `min-height` garde le pas de 71 px, donc une rangée SANS extrait
     (le cas nominal d'une recherche par titre, où `searchSnippet` rend une chaîne vide) ne bouge
     pas d'un pixel, et l'extrait RÉSERVE ses deux lignes — il n'existe donc que DEUX hauteurs
     possibles, jamais N.
     Spécificité (0,3,0) : elle gagne sur `.dir-row` et sur sa variante < 640 px quel que soit
     l'ordre de déclaration — pour une GÉOMÉTRIE, ne jamais dépendre de l'ordre (règle du dossier,
     quatre incidents). */
```

## C46 — padding 6px compensé par marges négatives : la BOÎTE du bouton atteint 29px (cible WCAG

```
  /* padding 6px compensé par marges négatives : la BOÎTE du bouton atteint 29px (cible WCAG
     2.5.8 mesurable ≥ 24 — le ::after étendu ne se mesure pas), le rendu ne bouge pas d'un px. */
  /* 16,5 px (v5.0.0, audit design A3-1) — le TITRE d'une aide était à 15,5 quand la MARQUE était
     à 18/20 : l'objet le plus important de l'écran était plus petit que le nom du logiciel, qui
     n'apprend rien à qui l'a déjà ouvert. Les deux se rejoignent désormais sur le même palier.
     Coût en hauteur NUL : la rangée est à 71 px fixes et le contenu (2 lignes × 1,15 + méta) y
     tient — c'est l'INTERLIGNE qui avait été resserré pour cette rangée, jamais la police. */
  /* ⚠ LE CLAMP VIT SUR UN <span>, JAMAIS SUR LE <button> (v5.0.0 — défaut ANTÉRIEUR, présent
     depuis la v4.56.0, trouvé en montant le corps du titre et signalé à l'usage : « les titres
     s'affichent sur trois lignes et dépassent »).
     `.card-open` est un BOUTON, et les navigateurs BLOCKIFIENT `display:-webkit-box` sur un
     contrôle de formulaire : le display calculé vaut `flow-root`, mesuré, et `-webkit-line-clamp`
     ne s'applique qu'à un conteneur `-webkit-box`. Le clamp à 2 lignes était donc INERTE depuis
     son écriture — il ne « marchait » que parce que les titres d'exemple tenaient sur deux lignes.
     Le monter à 16,5 px n'a pas créé le défaut : il l'a RÉVÉLÉ, en faisant passer des titres
     réels à trois lignes dans une boîte de hauteur FIXE.
     La TUILE ne l'avait pas, et c'est ce qui met sur la piste : elle clampe `.qa-t`, un <span>
     INTERNE au bouton. On applique ici le même patron. Le bouton garde sa boîte, son rembourrage
     compensé (donc sa cible mesurable ≥ 24 px, WCAG 2.5.8) et son nom de classe — quatorze
     harnais ouvrent une fiche par `.card-open`, et un <span> à l'intérieur ne change ni son
     `textContent` ni son `click()`. */
  /* ⚠ LE REMBOURRAGE COMPENSÉ RESTE SYMÉTRIQUE, ET C'EST UN ARBITRAGE MESURÉ (v5.6). Le réduire
     en bas supprimait le dernier recouvrement avec la pastille « △ à compléter » — mais faisait
     tomber la cible du titre à 22 px, sous le seuil de 24 (audit-a11y, immédiat). Dans une rangée
     dont le RYTHME est fixé à 71 px et où les deux textes ne sont séparés que de 4 px, les deux
     cibles ne peuvent pas être conformes ET disjointes : on garde les deux conformes, et le
     recouvrement résiduel (5 px de haut sur 36 de large) se résout en faveur de la pastille, qui
     est au-dessus (`z-index:1`) — la cible la plus PETITE et la plus précise gagne, le titre
     gardant 38 px de bande franche. */
```

## C47 — ⚠ PAS DE `line-clamp` STANDARD À CÔTÉ DU `-webkit-line-clamp` (v5.0.0, mesuré) : déclarée

```
  /* ⚠ PAS DE `line-clamp` STANDARD À CÔTÉ DU `-webkit-line-clamp` (v5.0.0, mesuré) : déclarée
     ensuite, la propriété moderne fait basculer Chromium sur son nouvel algorithme, qui
     recalcule `display` en `flow-root` — donc DÉSACTIVE le clamp hérité sans rien mettre à sa
     place. Mesuré : display calculé `flow-root`, trois lignes rendues pour un clamp à 2. On
     s'en tient au trio hérité, seul universellement supporté sur les deux moteurs cibles. */
  /* DEUX LIGNES, GARANTIES PAR LA HAUTEUR — et non par le seul `-webkit-line-clamp`.
     Le clamp hérité donne l'ELLIPSE, qui est le rendu qu'on veut ; mais il ne s'applique qu'à
     un conteneur `-webkit-box`, et MESURÉ dans cette page le display calculé du titre retombe
     sur `flow-root` — le clamp était donc INERTE, et un titre long prenait trois lignes dans
     une boîte de 71 px, poussant la méta hors du cadre (signalé à l'usage, capture à l'appui).
     `max-height` ne dépend d'AUCUNE particularité de moteur : deux lignes, partout, toujours.
     Les deux sont posées ensemble et ne se gênent pas — là où le clamp s'applique on gagne
     l'ellipse, là où il ne s'applique pas la hauteur tient quand même la promesse.
     ⚠ NE PAS AJOUTER la propriété standard `line-clamp` à côté : déclarée ensuite, elle fait
     basculer Chromium sur son nouvel algorithme et recalcule `display` (essayé, mesuré). */
```

## C48 — ⚠ CE QUI DÉBORDE NE DOIT PAS AFFAMER LE RESTE (signalé à l'usage : avec un code long, la

```
  /* ⚠ CE QUI DÉBORDE NE DOIT PAS AFFAMER LE RESTE (signalé à l'usage : avec un code long, la
     DATE disparaissait). Ellipser la LIGNE entière fait tomber la queue — donc l'élément le moins
     large, quel que soit le coupable. On distingue donc deux natures :
       · les items DURS (chrono, registre, statut, date) ne rétrécissent jamais : ils sont courts,
         bornés, et un chiffre amputé est pire qu'absent (règle du quai) ;
       · les items SOUPLES (discriminant, bibliothèque, catégorie, code) rétrécissent chacun POUR
         SOI, avec leur propre ellipse — le flex répartit le manque au prorata, donc c'est le PLUS
         LONG qui cède le plus, et tous restent présents.
     Résultat : un code de trente caractères s'abrège lui-même au lieu d'effacer la date. */
  /* ⚠ ET LA NATURE NE SUFFIT PAS À DÉCIDER : C'EST LA LONGUEUR DU JETON (audit externe v5.10.0).
     Le partage ci-dessus range le CODE parmi les souples parce qu'un code peut être long. Mesuré
     à 390 px sur la première fiche d'exemple : le code « ANA » manquait de UN pixel (29 rendus
     pour 30 nécessaires) et s'affichait « A… ». Le chiffre du dossier — « 3 items à 2 px, donc
     négligeable » — est exact, mais l'unité est fausse : un manque d'un pixel sur un jeton de
     trois lettres en détruit DEUX, parce que l'ellipse consomme elle-même la place qu'elle
     libère. « Urgences » → « Urgenc… » reste reconnaissable ; « ANA » → « A… » n'est plus rien,
     et le code est l'identifiant de crise. Un plancher exprimé en `em` est aveugle à cela : il
     borne une largeur, pas une PERTE D'INFORMATION.
     La règle devient donc : un jeton de 5 caractères ou moins est un item DUR, quelle que soit sa
     nature — il n'a pas de redondance à céder. La classe est posée à l'ÉMISSION par `metaDur()`,
     seul point de décision, parce que le CSS ne sait pas compter des caractères. */
```

## C49 — La cible du « △ À compléter » : rembourrage compensé, comme le bouton-titre — sans lui elle

```
  /* La cible du « △ À compléter » : rembourrage compensé, comme le bouton-titre — sans lui elle
     tomberait à la hauteur du texte (11 px), sous le seuil WCAG 2.5.8. */
  /* ⚠ LA COMPENSATION SE PARTAGE L'ÉCART, ELLE NE LE PREND PAS TOUT (v5.6, balayage de
     collisions). Le bouton-titre est JUSTE au-dessus, et sa cible descend elle aussi : leurs deux
     textes ne sont séparés que de 4 px, si bien qu'une compensation de 6 px les faisait se
     recouvrir de 13 px — dans cette bande, on croit ouvrir la fiche et l'on annonce ce qui reste
     à compléter. 4 px de chaque côté : plus de recouvrement, et la pastille garde une cible de
     19 × 23 px que son ISOLEMENT rend conforme (WCAG 2.5.8 admet la cible réduite quand l'écart
     aux voisines est suffisant — c'est le cas ici, elle est seule sur sa ligne).
     ⚠ ET LA COMPENSATION NE PART PAS VERS LE BAS : essayé, mesuré — la pastille passait alors sur
     le titre de la rangée SUIVANTE, ce qui est pire (on change de fiche). */
```

## C50 — Rail alphabétique : tap = saut, glisser = parcourir (touch-action:none — le geste est le

```
  /* Rail alphabétique : tap = saut, glisser = parcourir (touch-action:none — le geste est le
     parcours, jamais un défilement de page). Débordement : le rail se masque (bindAzRail) —
     jamais de lettres coupées ni de cibles rétrécies sous 24 px. */
  /* ⚠ ANCRÉES EN HAUT, ET PARTOUT (signalé à l'usage : « sa position bouge sans cesse »). La
     v4.73.0 avait posé `flex-start` sur la seule variante ÉTROITE ; en vue LARGE le rail restait
     `justify-content:center`, donc la position des lettres dépendait de LEUR NOMBRE — filtrer ou
     chercher en changeait la quantité et déplaçait toute la colonne (mesuré : première lettre à
     307 px, ailleurs dès qu'une lettre disparaît). Un index d'annuaire doit être là où l'on a
     appris à le viser, quel que soit ce qu'il contient. */
  /* Rembourrage ASYMÉTRIQUE d'un pixel, à dessein : le filet gauche de la variante large est à
     l'intérieur de la boîte (box-sizing global), donc un rembourrage égal décalait les lettres
     d'un pixel vers la droite. Mesuré, puis compensé — « centré » veut dire centré. */
  /* CENTRÉ VERTICALEMENT, COLLÉ À DROITE (v5.0.0, demande utilisateur — revirement assumé de
     l'ancrage en haut). ⚠ CE QUE LE CENTRAGE COÛTE, ET IL FAUT LE SAVOIR : la position des
     lettres dépend alors de LEUR NOMBRE — filtrer ou chercher en change la quantité et déplace
     la colonne. C'est le défaut signalé en v5.0.0 (« sa position bouge sans cesse ») ; il est
     INHÉRENT au centrage, aucune technique ne l'évite, et c'est un arbitrage de l'auteur.
     CE QUI RESTE GARANTI, parce que c'était l'autre moitié du problème : le rail ne bouge NI au
     défilement NI pendant qu'on s'en sert. Sa BOÎTE est stable — en étroit elle est bornée par
     `--hdr-h` (constante dans une vue) et par le bas de fenêtre, en large elle occupe la coque
     fixe de l'accueil. Un centrage dans une boîte qui, elle, ne bouge pas, ne bouge pas non plus. */
  /* ⚠ LE RAIL SE CENTRE SUR LA PAGE, PAS SUR SA PROPRE BOÎTE (v5.6, signalé à l'usage : « le rail
     A→Z n'est pas centré au milieu de la page »). Sa boîte commence sous l'en-tête — la v5.0.0
     l'y avait bornée pour qu'aucune lettre ne passe DERRIÈRE lui —, si bien que des lettres
     centrées dans cette boîte tombaient 58 px sous l'axe médian de l'écran à 390 px (55 à 1280).
     On ne déplace donc pas la BOÎTE (elle garde toute la place disponible, donc le rail continue
     de s'afficher sur un alphabet complet) : on rend au bas de la boîte, en rembourrage, la
     hauteur de l'en-tête — le centre du contenu redescend alors exactement sur l'axe de l'écran.
     ⚠ ET C'EST CLAMPÉ À LA PLACE RESTANTE (`azrCentrer`, en JS) : rendre plus que le libre
     rognerait des lettres, ou ferait disparaître le rail sur un alphabet complet, là où il tenait.
     Le calcul n'a QUE des entrées stables (hauteur de boîte dérivée de `100svh`, hauteur
     intrinsèque des lettres) et ne tourne QU'au rendu et au redimensionnement : rien qui suive la
     barre d'outils, donc rien qui bouge sous le doigt (leçon v5.0.2). */
  /* ⚠ LE RAIL NE SE SÉLECTIONNE PAS (signalé à l'usage : « le texte du rail est sélectionnable →
     bug, et ça sélectionne si on reste appuyé trop longtemps dessus »). Viser une lettre, c'est
     POSER LE DOIGT ET GLISSER — un geste qui commence par un appui maintenu, donc précisément ce
     que WebKit interprète sur du texte comme le début d'une sélection : rectangle bleu, poignées,
     loupe, menu « Copier ». Le geste est alors CAPTURÉ par la sélection, le rail cesse de suivre
     le doigt, et il faut taper ailleurs pour désarmer. `touch-action:none` tenait déjà le
     défilement natif à distance, mais une sélection n'est pas un défilement : elle passe à côté.
     Rien n'est perdu — ces vingt-six lettres ne sont pas un contenu qu'on copie, ce sont des
     commandes, et `user-select` s'hérite, donc les boutons sont couverts par la même ligne. */
  /* ⚠ LE RAIL SE RESSERRE PAR SON REMBOURRAGE, PAS PAR SON CORPS DE TEXTE (v5.10.8, demande de
     l'auteur : « réduis légèrement la taille du texte du rail pour diminuer encore l'espace »).
     LES DEUX MOITIÉS DE LA DEMANDE N'ONT PAS LE MÊME SORT, et il faut dire pourquoi.
     · LE CORPS NE PEUT PAS BAISSER : 11 px EST le plancher typographique (règle 9), et `.azrail
       button` y est déjà posé. Descendre en dessous ne serait pas un arbitrage de goût — la règle
       tient pour un écran tenu à bout de bras, en gant, sous stress — et `check-type` le refuse.
     · ET CELA N'AURAIT DE TOUTE FAÇON RIEN GAGNÉ : mesuré, la largeur du rail ne vient PAS du
       glyphe (une lettre à 11 px en fait ~7) mais du `min-width:24px` des boutons, qui est la
       cible minimale WCAG 2.5.8 et que la sonde a11y vérifie (`w < 24` ⇒ rouge, à toute largeur).
       Un corps plus petit aurait rendu les lettres moins lisibles pour exactement 0 px.
     Ce qui restait de vraiment récupérable, c'est le rembourrage HORIZONTAL du rail lui-même :
     3 px (2 à droite, 1 à gauche) posés autour de boutons déjà centrés dans leurs 24 px. Rail
     27 → 24 px, mesuré, et ces 3 px vont à la colonne. Le rembourrage VERTICAL de 8 px reste : il
     est le pas du calage de `bindAzRail` (`--azr-pt`), pas une décoration. */
```

## C51 — Ancré ENTRE le bas de l'en-tête (--hdr-h, mesurée par syncHdrScroll — un centrage sur la

```
    /* Ancré ENTRE le bas de l'en-tête (--hdr-h, mesurée par syncHdrScroll — un centrage sur la
       fenêtre passait sous l'en-tête à 320×640) et la tab bar ; lettres centrées dans la boîte. */
    /* LES LETTRES NE BOUGENT PLUS (correctif — « la liste de lettres monte et descend en même
       temps, par moment »). Elles étaient CENTRÉES (`justify-content:center`) dans une boîte
       fixée par son haut ET son bas : toute variation de la hauteur réellement visible déplaçait
       donc chaque lettre de la moitié de cette variation. Or cette hauteur varie précisément
       PENDANT un défilement — la barre d'outils du navigateur mobile se replie et se redéploie, et
       `position:fixed` se dimensionne sur le grand viewport (le dossier « bande basse iOS » l'a
       déjà établi pour les overlays). Le glisser en devient un asservissement instable : le rail
       défile, la barre bouge, les lettres se décalent sous le doigt, la lettre visée change, le
       rail défile ailleurs.
       La boîte est bornée par `top` — c'est-à-dire `--hdr-h`, que l'en-tête garde CONSTANTE dans
       une vue donnée (« sans changer sa hauteur », § header.bar) — et par une hauteur qui, elle
       aussi, doit être CONSTANTE.
       ⚠ ET C'EST `svh`, SURTOUT PAS `--vvh` NI `dvh` (correctif, signalé à l'usage : « il bouge
       sous mon doigt alors qu'il est censé rester fixe »). Le centrage a été rétabli à la demande
       de l'auteur en gardant la hauteur `--vvh` — c'est-à-dire `visualViewport.height`, LA mesure
       qui suit la barre d'outils du navigateur mobile. Le défaut de la v4.73.0 est donc revenu
       tel quel, et par le pire chemin : le glisser fait DÉFILER la page, le défilement replie la
       barre, `--vvh` grandit, la boîte grandit, les lettres centrées descendent de la MOITIÉ de
       l'écart, la lettre sous le doigt change, le rail défile ailleurs — un asservissement qui
       s'entretient lui-même. `100svh` est le SMALL viewport : la hauteur que la fenêtre a barre
       d'outils DÉPLOYÉE, donc une constante que ni le défilement ni le repli ne touchent. La
       boîte ne peut alors jamais dépasser le bord visible (elle est bornée par le plus petit des
       deux états) et le test de débordement de `bindAzRail` reste fiable — il l'est même plus,
       n'étant plus mesuré sur une hauteur qui change d'un instant à l'autre.
       Le clavier n'est pas un cas : le rail n'existe qu'en RÉPERTOIRE, et saisir dans la
       recherche bascule sur la liste plate, où il n'est pas rendu.
       ⚠ LES 68 px RÉSERVÉS EN BAS ÉTAIENT UN VESTIGE DE LA TAB BAR, supprimée au lot M4 — mesuré,
       le rail s'arrêtait 68 px au-dessus du bord pour un objet qui n'existe plus (`grep tabBar` :
       0 occurrence). Invisible tant que les lettres étaient ancrées en haut ; en les centrant, ce
       vide décalait tout le rail vers le haut. Corollaire de la règle 14 : une suppression emporte
       ce qui RÉSERVE sa place, pas seulement ce qui la cite. */
    /* v5.18 : les deux ancres sont des CONSTANTES — l'en-tête n'est plus collant (rien à
       mesurer en haut) et le dock borne le bas. --azr-top reste une variable : azrCentrer
       s'en sert comme repli avant sa première mesure. */
```

## C52 — ⚠ ET LA MARGE BASSE DU MATÉRIEL EST LE SECOND TERME QUI BOUGE — `svh` NE SUFFISAIT PAS

```
    /* ⚠ ET LA MARGE BASSE DU MATÉRIEL EST LE SECOND TERME QUI BOUGE — `svh` NE SUFFISAIT PAS
       (signalé à l'usage : « ça persiste en partie, surtout quand on scroll vers le bas sur le
       rail : il remonte »). Dans Safari iOS, `env(safe-area-inset-bottom)` n'est PAS une
       constante : la barre d'outils du bas COUVRE la bande de l'indicateur d'accueil, donc
       l'inset vaut 0 tant qu'elle est déployée et saute à ~34 px dès qu'elle se replie — c'est-
       à-dire au défilement, exactement comme `--vvh`. La hauteur perdait alors 34 px et les
       lettres centrées REMONTAIENT de 17 px, au mot près ce qui a été rapporté. Le retirer ne
       découvre rien : `100svh` est déjà la hauteur BARRE DÉPLOYÉE, son bord bas se situe donc
       au-dessus de cette barre, donc au-dessus de l'indicateur.
       EN APP INSTALLÉE, l'arbitrage s'inverse et c'est pourquoi la règle est dédoublée : sans
       barre d'outils, `svh` descend jusqu'au bord de l'écran, indicateur compris — mais l'inset y
       est CONSTANT, faute de chrome qui bouge. On le retranche là, et là seulement.
       RÈGLE : dans une hauteur qui doit être stable, `env(safe-area-inset-bottom)` est aussi
       suspect que `--vvh` — le vérifier avant de l'écrire. */
```

## C53 — ⚠ CE N'EST PAS UN TAMPON ANTI-FAUSSE-MANŒUVRE, C'EST UNE RÉSERVATION (v5.0.3, question

```
    /* ⚠ CE N'EST PAS UN TAMPON ANTI-FAUSSE-MANŒUVRE, C'EST UNE RÉSERVATION (v5.0.3, question
       utilisateur : « l'espace entre les cartes et le rail me paraît grand — est-ce fait exprès
       pour ne pas cliquer sans faire exprès sur une carte ? »). En voie étroite le rail est
       `position:fixed` : sans rembourrage réservé il RECOUVRIRAIT le bord droit des rangées, donc
       l'épingle ☆. Il ne fallait donc jamais 24 px — le rail fait 27 px de large et mord déjà sur
       les 18 px de marge de page, il n'en faut que 9 pour ne rien couvrir. Le reste était du vide.
       16 px laissent 7 px entre la carte et le rail, et 11 px entre la ZONE TACTILE de l'épingle
       (halo compris, qui finit 4 px avant le bord de la carte) et la première lettre : les deux
       cibles ne se touchent pas, ce qui est la seule contrainte réelle. 8 px rendus à chaque
       rangée, à toutes les largeurs étroites.
       ⚠ ET ELLE EST RÉSERVÉE MÊME QUAND LE RAIL N'EST PAS LÀ (v5.6, signalé à l'usage : « l'absence
       de rail redistribue la largeur des cartes, c'est moche quand ça repasse à plusieurs cartes
       et que la largeur diminue »). La règle était accrochée à `.azr-on`, donc à l'EXISTENCE du
       rail : bibliothèque vide, une seule lettre, ou rail retiré faute de hauteur, et la colonne
       récupérait ses 16 px — les cartes et le bloc « aucune aide » s'élargissaient, puis
       rétrécissaient au retour. C'est le MÊME défaut que la v5.0.3 avait corrigé côté RECHERCHE et
       que la voie LARGE tient depuis toujours (`padding-right:32px`, sans condition) : la moitié
       étroite était restée conditionnelle. Un annuaire dont le pas change selon ce qu'il contient
       est un annuaire qu'on réapprend ; la gouttière appartient à la PAGE, pas au rail.
       ⚠ 16 → 12 px (v5.10.8, signalé à l'usage : « diminue l'écart entre les cartes d'accueil et le
       rail A-Z », en voie ÉTROITE — la voie large n'est pas concernée, ses 32 px de gouttière pour
       un rail de 30 laissent DEUX pixels, mesurés à 1280). Le raisonnement de v5.0.3 est inchangé,
       seule sa marge de sécurité se resserre : mesuré à 390 px, la carte finissait à 355 et le rail
       commence à 363 — 8 px de blanc, quand la contrainte réelle est que les deux ZONES TACTILES
       ne se touchent pas. RE-MESURÉ AVANT DE DÉCIDER, et le chiffre de 2020 a vieilli : dans la
       rangée d'aujourd'hui l'épingle ☆ n'est PAS au bord (`.pinbtn` s'arrête à 319, elle n'a pas de
       halo, et la date puis le chevron la séparent du bord) — la cible la plus proche du rail finit
       donc 40 px avant la carte, pas 4. Il n'y avait plus rien à protéger dans ces 8 px. À 12, la
       carte finit à 359, la première lettre commence toujours à 364, et 45 px séparent l'épingle du
       rail. On rend 4 px de largeur à CHAQUE rangée, à toutes les largeurs étroites.
       ⚠ CE CHIFFRE DE 40 A VIEILLI À SON TOUR (v5.17.6) : le rembourrage droit de la rangée est
       passé de 40 à 16 px et l'épingle s'est rapprochée du bord — son halo s'arrête désormais à
       351, soit 15 px avant le rail et non 45. LE PLANCHER DE 8 NE BOUGE PAS POUR AUTANT, parce
       qu'il ne repose pas sur cette distance : son argument est la PEINTURE (sous 6, le fond
       translucide du rail se poserait sur le bord de la rangée), et la surface tapable de la
       rangée elle-même — `.card-open::after{inset:0}` — atteignait DÉJÀ le bord de la carte,
       à 3 px du rail. Rapprocher l'épingle ne crée donc pas une adjacence neuve : elle change
       seulement laquelle des deux actions de la rangée occupe cette bande.
       ⚠ PUIS 12 → 10, PUIS 10 → 8 px (« rétrécis encore l'espace entre les cartes et le rail »),
       et 8 est le PLANCHER — il se déduit, il ne se choisit pas. Le rail vient de passer de 27 à
       24 px (son rembourrage horizontal, cf. `.azrail`) : il commence donc à 366 pour 18 px de
       marge de page, dont il mord 6. Une gouttière de 8 place le bord de rangée à 363 (mesuré :
       372 de colonne − 8 de gouttière − 1 de bordure du livre), soit 3 px de jointure, du même
       ordre que les 2 px de la voie large mesurés à 1280 — les deux régimes cessent d'avoir deux
       écarts différents pour une même jointure. À 6, le fond translucide du rail
       (`color-mix(… 85%, transparent)`) se poserait SUR le bord de la rangée, qui transparaîtrait
       dessous. Ce plancher est une géométrie, pas un goût — et il se recalcule si le rail change
       de largeur : gouttière = 18 (marge de page) − (rail − 12).
       ⚠ ET LA GOUTTIÈRE NE DÉPEND PAS DU RAIL — c'est la moitié de la règle qu'il ne faut jamais
       reperdre (« même largeur de carte, rail ou pas »). Elle est posée sur `body.view-home`, sans
       condition : `.azr-on` a été PURGÉE en v5.6 précisément pour cela, et le rail est `fixed`,
       donc hors flux — il ne peut par construction rien retirer à la colonne. Répertoire, recherche,
       bibliothèque vide, une seule lettre, rail retiré faute de hauteur : le pas de la grille est le
       même partout. Toute règle future qui accrocherait cette valeur à l'existence du rail
       réintroduirait l'annuaire qu'on réapprend à chaque geste. */
```

## C54 — ⚠ ET LA CAUSE RESTANTE N'EST PAS UNE MESURE, C'EST LE REBOND DE FIN DE PAGE (signalé à

```
    /* ⚠ ET LA CAUSE RESTANTE N'EST PAS UNE MESURE, C'EST LE REBOND DE FIN DE PAGE (signalé à
       l'usage : « ça se produit quand on arrive en fin de scroll de page, quand il y a le
       bounce »). Pendant le rubber-band, WebKit TRANSLATE le document ET les éléments
       `position:fixed` : le rail part avec le rebond, puis revient — sous le doigt qui le vise.
       Aucune formule ne s'en protège, et c'est pour cela que les trois correctifs précédents ne
       pouvaient pas y suffire : ce n'est pas une valeur qui change, c'est une transformation
       appliquée au rendu, par le compositeur, en dehors de toute mesure lisible en JS.
       `overscroll-behavior-y:none` supprime le rebond DU DOCUMENT. Il est borné à l'accueil en
       voie étroite — le seul endroit où une surface FIXE se vise au pixel et à la cadence du
       doigt ; ailleurs le rebond reste, c'est une affordance native qui dit « fin de liste ».
       En voie large l'accueil est une coque fixe (le document ne défile pas) et le rail y est
       `absolute` dans le flux : il n'a jamais été concerné.
       ⚠ La déclaration vit sur `html` ET sur `body` : la propagation vers le viewport se fait
       depuis la racine, et la poser sur le corps seul est sans effet.
       ⚠⚠ ET ELLE NE DURE QUE LE GESTE (signalé à l'usage : « le scroll des cartes n'est plus très
       ergonomique, s'arrête, est lent »). Posée en permanence sur l'accueil, elle corrigeait bien
       le rail — mais sur WebKit `overscroll-behavior` ne supprime pas que le REBOND : il ampute
       aussi l'INERTIE, donc le défilement des cartes, c'est-à-dire le geste le plus fréquent de
       l'écran, payait le confort d'un geste rare. La classe est posée au `pointerdown` sur le
       rail et retirée au relâchement : hors visée, le défilement du document est exactement celui
       du système, rebond et inertie compris. C'est aussi la portée JUSTE — le rebond n'a besoin
       d'être supprimé que pendant qu'on VISE une surface fixe. */
```

## C55 — ÉTAT VIDE PÉDAGOGIQUE (v5.0.0) — le MÊME `.empty` (cadre pointillé = la grammaire de

```
  /* ÉTAT VIDE PÉDAGOGIQUE (v5.0.0) — le MÊME `.empty` (cadre pointillé = la grammaire de
     « créer », partagée avec la porte ＋ des éditeurs), enrichi de l'anatomie du type. Le titre
     et la phrase restent CENTRÉS, l'anatomie s'aligne à GAUCHE : une liste centrée n'a pas de
     bord d'appel pour l'œil, et c'est une liste qu'on parcourt, pas une accroche qu'on lit.
     Rembourrage ramené de 56 à 24 px : les 56 px existaient pour donner du corps à un état vide
     de trois mots — ici le contenu le donne, et deux cartes empilées doivent tenir sur un écran. */
  /* ⚠ LARGEUR PLAFONNÉE ET CENTRÉE (signalé à l'usage : « ils prennent toute la place en mode
     desktop »). Mesuré à 1920 px, la carte s'étirait à ~1870 px pour trois lignes de texte — une
     ligne de 1870 px se lit mal (l'œil perd le début de la suivante), et surtout l'état vide
     s'affirmait plus fort que n'importe quel contenu réel de l'accueil, dont les rangées sont
     plafonnées et grillées.
     780 px, ce n'est PAS un pourcentage arbitraire : c'est la largeur de lecture d'une référence
     et un palier déclaré du projet — la même valeur, pour la même raison (au-delà, une colonne de
     texte cesse d'être confortable). La réduction demandée (~60 % sur un écran large) y tombe
     naturellement.
     `max-width` ne contraint QUE si la place existe : sous 780 px la carte occupe 100 % de son
     conteneur, donc rien ne rétrécit sur téléphone — le responsive est acquis par construction,
     sans media query ni palier nouveau. */
```

## C56 — ⚠ LE BOUTON DE DÉMARRAGE A QUITTÉ LE FLUX (v5.6, décision de l'auteur : « uniformise le

```
  /* ⚠ LE BOUTON DE DÉMARRAGE A QUITTÉ LE FLUX (v5.6, décision de l'auteur : « uniformise le
     design ; préférentiellement opte pour le nouveau »). Il vit dans le DOCK, où sa position est
     CONSTANTE à toutes les largeurs et atteignable au pouce. Sont PURGÉS avec lui (règle 14) :
     `.sess-start`, `.ss-hint`, la rangée du carrelage statique, et toute la mécanique `.afloat`
     de la v4.73.0 — elle n'existait QUE parce que le bouton naissait sous le pli sur une fiche à
     critères longs, et un dock fixe résout cela par construction, sans objet qui se détache et
     se rattache selon le défilement (donc sans zone fixe transitoire à justifier contre SPEC §5). */
  /* ----- Parcours de soin (v4.4.0, « option B ») : rail vertical numéroté ① Confirmer →
     ② Prise en charge → ③ Surveillances & pièges. Pastilles : bleu = étape active,
     vert ✓ = faite, neutre cerclé = à venir — JAMAIS d'ambre/rouge ici (registres d'alerte).
     En sombre, l'encre des pastilles passe à --bg (mêmes raisons AA que .hs-row.on).
     La ligne de liaison est décorative (aria-hidden porté par les pastilles ; l'état vit
     dans le texte des en-têtes). Responsive : gouttière réduite < 430px. */
  /* EN SESSION (lot T5) : les mêmes étages, sans rail ni numérotation — cf. le commentaire de
     `pathH`. Aucune couleur, aucun registre ne change : seule l'ossature s'en va. L'écart entre
     sections est celui du rail (20 px), pour que le passage d'un état à l'autre ne fasse pas
     respirer la page différemment. */
  /* Onglets du cran « Toute la fiche » (lot T8) : le gabarit des chips du dépôt, pas un composant
     de plus. Cible 44 px, filet bas continu pour que la rangée se lise comme une rangée. */
  /* « ×2 » — registre NEUTRE (cf. le commentaire de stepsListHtml) : ce n'est ni un danger ni un
     piège, c'est une consigne de procédure. Mono tabulaire, comme les autres pilules d'état. */
```

## C57 — SOUS 1000 px : LE VOLET S'ACCROCHE SOUS L'EN-TÊTE (demande utilisateur). Un dépliant posé

```
  /* SOUS 1000 px : LE VOLET S'ACCROCHE SOUS L'EN-TÊTE (demande utilisateur). Un dépliant posé
     dans le flux disparaît dès qu'on descend de deux écrans — or chercher dans une référence, on
     le fait précisément quand on est loin dans le texte. Collé, il est atteignable en permanence,
     sans occuper de place tant qu'il est replié : c'est le même arbitrage que le quai de crise,
     à ceci près qu'on est ici hors session.
     DÉPLIÉ, IL EST BORNÉ ET DÉFILE : une référence à trente titres remplirait l'écran et
     masquerait ce qu'on cherche à atteindre. La hauteur suit la règle 10 — jamais un `dvh` nu,
     toujours divisé par le zoom du réglage de taille du texte. Et le résumé RESTE visible pendant
     que la liste défile : sans lui on ne saurait plus comment refermer. */
  /* ⚠ IL PROLONGE L'EN-TÊTE, IL NE FLOTTE PAS DESSOUS (signalé à l'usage : « lorsque ça colle ça
     ne fusionne pas à l'en-tête et ça fait moche »). Une carte arrondie avec ses marges, collée
     sous la barre, se lit comme un objet POSÉ sur la page — deux surfaces séparées par un liseré
     de fond. Ici c'est le MÊME chrome : il déborde les marges du contenu (`margin-inline` négatif
     compensé), n'a ni rayon ni bord latéral, et ne porte qu'un FILET BAS — exactement la
     grammaire de `header.bar`. L'ombre ne paraît qu'OUVERT — c'est-à-dire au seul moment où il
     RECOUVRE le texte ; replié il ne recouvre rien, et une ombre permanente y recréerait la
     séparation qu'on vient de supprimer. */
  /* La barre prend les traits de `header.bar` : même fond, filet bas, pleine largeur, aucun
     rayon — rien qui la détache de la rangée du dessus. `--refbar-h` (mesurée par
     `syncRefBar`, divisée par le zoom comme toute mesure réinjectée) réserve sa place dans le
     flux : le contenu naît SOUS elle, donc rien ne se glisse derrière. */
  /* CONTINUITÉ AVEC LE BANDEAU-TITRE, AU TRAIT PRÈS (demande utilisateur : « garde le même style
     que le bandeau pour une bonne continuité ») : même fond `--surface`, même rembourrage
     horizontal de 18 px, aucun rayon, aucune ombre au repos. LE FILET DE SÉPARATION EST GARDÉ
     (demande utilisateur : « marque tout de même une petite ligne de séparation … comme pour les
     aides ») : c'est exactement la grammaire de `#crisisCtrl` au-dessus de `#crisisDock` — deux
     rangées de MÊME chrome, chacune bordée en bas. Continuité ne veut pas dire indistinction :
     le fond commun fait le bloc, le filet dit qu'il a deux étages. */
```

## C58 — CHERCHER DANS LA RÉFÉRENCE : le champ vit dans le sommaire — on cherche là où l'on s'oriente.

```
  /* CHERCHER DANS LA RÉFÉRENCE : le champ vit dans le sommaire — on cherche là où l'on s'oriente. */
  /* « Sommaire » ne colle plus à la ligne du dessus (signalé à l'usage). */
  /* ⚠ AUTANT D'AIR DE PART ET D'AUTRE DU FILET (signalé à l'usage : « Sommaire est collé à la
     barre du dessus, alors qu'il y a plus d'espace entre la barre et l'input »). Le rembourrage
     bas de la zone de recherche s'ajoutait à la marge du titre : 8 + 16 = 24 px au-dessus du
     filet contre 12 en dessous. On annule le rembourrage bas de la recherche et l'on pose la même
     valeur des deux côtés — une séparation se lit à sa symétrie, pas à son trait. */
  /* L'AIDE-MÉMOIRE DE SYNTAXE SE REPLIE (signalé à l'usage : « c'est moche »). C'était un
     paragraphe de vingt lignes sous le champ, permanent : on le lit une fois, on le subit
     ensuite. Replié, il tient en une ligne ; déplié, il devient LISIBLE — chaque règle sur sa
     propre ligne au lieu d'une phrase continue, et les exemples en mono se détachent. Même
     gabarit que les autres dépliants du produit (`.crit-guide`, `.rev-panel`). */
```

## C59 — ⚠ LE COMPTE NE DOIT PAS DÉPLACER LES BOUTONS QU'ON TAPE (signalé à l'usage : « ça saute moins

```
  /* ⚠ LE COMPTE NE DOIT PAS DÉPLACER LES BOUTONS QU'ON TAPE (signalé à l'usage : « ça saute moins
     mais encore un peu »). Mesuré, douze sauts d'affilée : la largeur du compte prend NEUF valeurs
     distinctes (27,1 → 34,3 px) — les chiffres n'ont pas la même chasse et « 10 / 70 » est plus
     long que « 9 / 70 » — et le bouton « › » se déplaçait donc de 7 px À CHAQUE CLIC, c'est-à-dire
     sous le doigt qui le vise. Deux remèdes cumulés : chiffres à chasse FIXE (`tabular-nums`), et
     une largeur MINIMALE qui absorbe le passage à trois caractères. Le bouton ne bouge plus.
     ⚠ ET ON NE SÉLECTIONNE PAS DU TEXTE EN TAPANT DEUX FOIS (même signalement : « empêche
     sélection de texte en appuyant sur les boutons ‹ et ›, ça sélectionne quand on clique
     plusieurs fois rapidement dessus »). Un double-tap sur un contrôle est un GESTE, pas une
     intention de lire : même idiome que le rail A→Z, qui le fait depuis toujours pour la même
     raison. */
```

## C60 — ⚠ SEIZIÈME PIÈGE DE CASCADE, ET IL SE VOYAIT À L'ŒIL (signalé à l'usage, capture à l'appui :

```
  /* ⚠ SEIZIÈME PIÈGE DE CASCADE, ET IL SE VOYAIT À L'ŒIL (signalé à l'usage, capture à l'appui :
     « les icônes dans la zone de texte se superposent avec le texte »). La marque est réservée par
     ⚠ v5.6 : `--shadow-primary-sm` est devenue `none` avec l'ombre unique — le champ en édition
     n'avait donc plus qu'un filet d'1,5 px pour dire le focus, et `audit-a11y` l'a vu (« focus NON
     visible au clavier », éditeur 1100 px). Le filet d'accent reste ; l'ANNEAU revient, en teinte
     tonale plutôt qu'en ombre — c'est un état d'interaction, pas une élévation.
     un `padding-left` LONGHAND ; 1 350 lignes plus bas, `.blk .li input[type=text]:focus` repose un
     `padding` RACCOURCI — même spécificité (0,4,1) que la règle de la marque, déclaré APRÈS, donc
     gagnant. Mesuré au FOCUS à 390 px : rembourrage 11 px, texte commençant à 96 px pour une icône
     finissant à 101 — le ⚠ passait SOUS la première lettre. C'est le même mécanisme que le
     quinzième piège (`.rt-h2`), et la même leçon : un longhand ne survit pas à un raccourci
     ultérieur. On passe par `:is()` à (0,5,1), qui gagne quel que soit l'ordre, et l'on couvre le
     repos ET le focus. */
```

## C61 — v5.4.1 — LE VOLET DU QUAI (décision utilisateur : « un menu déroulant qui part du quai —

```
  /* v5.4.1 — LE VOLET DU QUAI (décision utilisateur : « un menu déroulant qui part du quai —
     comme ça il suit si besoin »). Ouvert PAR LE QUAI, le panneau devient un volet FIXE sous les
     couches collantes : il SUIT le défilement — minuteurs, compteurs et journal restent sous les
     yeux pendant qu'on parcourt les étapes — au prix ASSUMÉ de recouvrir le contenu tant qu'il
     est ouvert. C'est l'arbitrage inverse de la rangée du flux (qui pousse sans couvrir) ; les
     deux accès coexistent, chacun avec sa géométrie. CE QUI LE REND ADMISSIBLE (ECAM/QRH —
     question posée par l'auteur) : ouvert et fermé par l'utilisateur SEUL (re-tap du quai, ✕,
     Échap, retour système), JAMAIS d'auto-ouverture — l'échéance s'annonce sur place (règle 11) ;
     même statut de consultation que le menu ⋯, qui est déjà un volet fixe de l'en-tête. z-index
     14, SOUS le quai (15) : l'alarme n'est jamais masquée. Hauteur bornée sur --vvh ÷ --zf
     (règle 10, dossier « bande basse iOS ») avec défilement INTERNE ; l'en-tête du panneau (✕)
     reste épinglé en tête du volet (marges négatives compensant le rembourrage du panneau). */
  /* v5.4.1 (2e passe, retours utilisateur : « pas une continuité du quai », « fixed dans fixed »,
     « deuxième niveau de scroll ») : le volet n'est PAS une carte flottante — c'est un ÉTAGE de
     plus du bloc de chrome, comme la barre d'une référence (#refBar : « le fond commun fait le
     BLOC, le filet dit les étages »). Pleine largeur, collé au quai (le filet bas du quai fait la
     séparation), fond `--surface`, coins vifs ; l'ombre dit qu'il RECOUVRE. C'est le VOLET
     lui-même qui défile (un seul défileur, aucun en-tête épinglé dedans — l'en-tête ✕ passe avec
     le contenu : la fermeture vit aussi sur le quai, re-tap/Échap/retour). Le panneau intérieur
     perd sa boîte : deux cadres emboîtés se liraient comme deux objets (règle du journal niché). */
  /* ⚠ LE VOLET A LA LARGEUR DE LA CAPSULE, ET IL LUI EST COLLÉ (v5.6, signalé à l'usage : « le
     menu qui se déroule du chronomètre de session devrait être designé comme s'il était intégré
     au bandeau session — la largeur doit être la même, et il devrait être collé »).
     La v5.4.1 en avait fait un ÉTAGE du chrome plutôt qu'une carte flottante ; c'était la bonne
     structure, mais la GÉOMÉTRIE était restée celle d'une barre pleine largeur, posée sous TOUT
     le bandeau (`--stick-top`) et de bord à bord. Il se lisait donc comme une seconde barre
     collée au chrome, pas comme le dépliant DE LA CAPSULE.
     Les deux valeurs viennent de la même source que le bandeau — son rembourrage de 8/14 px :
     `left`/`right` valent son rembourrage horizontal, et le `top` retranche son rembourrage BAS
     de `--stick-top`, qui est le bas du bandeau. Aucune mesure JS : deux constantes CSS écrites
     une fois, à côté de celles qu'elles suivent. Si le rembourrage du bandeau change, ces deux
     lignes changent avec lui — et c'est pour cela qu'elles vivent ici, contre lui. */
  /* ⚠ ET LA CAPSULE PERD SES COINS BAS TANT QUE LE VOLET EST OUVERT (v5.6, signalé à l'usage :
     « il reste des px blancs »). Les deux boîtes se touchent et ont la même largeur — mais la
     capsule est ARRONDIE en bas et le volet VIF en haut : aux deux angles, le fond de page passait
     dans l'encoche, et c'est cela qu'on voyait. Un seul objet à deux étages : le haut est arrondi,
     le bas aussi, et la jointure est franche. */
```

## C62 — ⚠ LE VOLET PASSE AU-DESSUS DU REMBOURRAGE DU QUAI, SINON LES DEUX NOIRS NE SE TOUCHENT PAS

```
  /* ⚠ LE VOLET PASSE AU-DESSUS DU REMBOURRAGE DU QUAI, SINON LES DEUX NOIRS NE SE TOUCHENT PAS
     (v5.6, signalé à l'usage : « le noir du bandeau ne touche pas le noir du début du menu »).
     Les BOÎTES se touchaient déjà — bas de la capsule et haut du volet au même pixel, mêmes bords,
     même largeur (mesuré). Ce qui se voyait n'était pas un écart de géométrie mais un écart de
     PEINTURE : le quai (`#crisisDock`, z 15) porte 8 px de rembourrage sous la capsule, il est de
     la matière d'AMBIANCE, et il peignait par-dessus les 8 premiers pixels du volet (z 14) —
     mesuré au pixel avec `elementFromPoint` : la bande appartenait au quai, en clair.
     Le volet monte donc à z 16. ⚠ CELA N'ENFREINT PAS V2 (« l'alarme reste toujours en vue ») :
     le volet COMMENCE au bas de la capsule, il ne peut donc rien couvrir d'elle — il ne recouvre
     que le rembourrage du quai, qui n'affiche rien. Et il reste SOUS l'en-tête et le bandeau
     (z 20), qui restent les couches système du dessus. */
  /* Le volet du quai s'accroche au BAS de la capsule (`--quai-b`, mesurée) — il rejoint donc la
     même règle que les autres couches de chrome : + le panoramique du viewport visuel, sinon il
     s'ouvre hors de l'écran clavier ouvert (attrapé par `check-stick` en étendant celui-ci au
     second token d'ancrage — je ne l'avais pas vu). */
```

## C63 — ⚠ TROIS RÈGLES SONT PURGÉES ICI (v5.10.8, règle 14) ET C'EST LEUR CAUSE COMMUNE QUI A DISPARU.

```
  /* ⚠ TROIS RÈGLES SONT PURGÉES ICI (v5.10.8, règle 14) ET C'EST LEUR CAUSE COMMUNE QUI A DISPARU.
     Elles répondaient toutes à un ✕ HORS FLUX dans une rangée qui débordait : la réserve
     `padding-right:56px` (« une place réservée qui ne vaut pas la taille de l'objet réservé n'est
     pas une réserve », le ✕ recouvrant « Son activé » à 600-768 px), les 48 px de bouton, et le
     `min-height:48px` réinjecté sur le TITRE pour que le ✕ ne paraisse pas posé une demi-ligne
     trop bas. Depuis la fusion de l'en-tête et du sous-titre « Minuteurs », la rangée n'a plus que
     deux enfants — un mot court et un ✕ EN FLUX —, elle ne peut plus déborder, il n'y a plus rien
     à réserver, et les deux se centrent l'un sur l'autre sans qu'on l'écrive. Le ✕ garde ses 48 px
     de CIBLE, qui viennent maintenant du halo (36 + 12) et ne coûtent plus de hauteur.
     ⚠ CE QUI RESTE VRAI ET NE DOIT PAS ÊTRE REPERDU : le couloir du ✕ appartient à la RANGÉE,
     jamais au titre. Deux essais l'ont mesuré en v5.6 — un rembourrage sur le titre le faisait
     enrouler SOUS le ✕ (176 px, quatre lignes), une largeur maximale laissait un autre contrôle
     monter à sa droite, donc sous le ✕. Le jour où l'on remet quoi que ce soit dans cette rangée,
     c'est la rangée qui protège la ligne, pas une borne posée sur un seul enfant. */
```

## C64 — ⚠ A9 — LE LIBELLÉ RÉSERVE SES DEUX LIGNES, IL NE LES PREND PAS EN ÉCHÉANT (v5.6, mesuré).

```
  /* ⚠ A9 — LE LIBELLÉ RÉSERVE SES DEUX LIGNES, IL NE LES PREND PAS EN ÉCHÉANT (v5.6, mesuré).
     En échéant, « Réévaluation après adrénaline » devient « ■ Réévaluation après adrénaline — à
     réévaluer » : à 320 px le texte passait de UNE ligne à DEUX et la carte de 200 à 214 px —
     un changement de hauteur que personne n'a commandé, exactement ce que A9 interdit. Le clamp
     à deux lignes BORNE le maximum, il ne fixe pas la hauteur ; c'est `min-height` qui la fixe.
     ⚠ ON NE RACCOURCIT PAS LE LIBELLÉ À LA PLACE : le suffixe dit ce qu'il faut FAIRE (doctrine
     ECAM de l'action au pied de l'alerte), et le retirer ne garantirait rien — un nom qui tient
     tout juste sur une ligne se remettrait à enrouler pour le seul glyphe « ■ ». Réserver est la
     seule garantie STRUCTURELLE, indépendante de la longueur du nom.
     COÛT DIT : +14 px sur une carte à libellé court en colonne unique (200 → 214) ; à 390 px la
     carte valait DÉJÀ 214 des deux côtés — la réserve harmonise donc plus qu'elle ne coûte, et
     les cartes d'une même grille cessent de dépendre de la longueur de leur nom.
     Borné à `.tmcard` : une carte de COMPTEUR ne change pas d'état, réserver chez elle serait
     payer une ligne pour rien. */
```

## C65 — ⚠ UN SEUL DESSIN D'INTERTITRE dans la colonne (signalé à l'usage : « à tout moment plus à

```
  /* ⚠ UN SEUL DESSIN D'INTERTITRE dans la colonne (signalé à l'usage : « à tout moment plus à
     droite que le reste, hors numérotation qui sort de nulle part »). Il y en avait DEUX —
     `.pl-cxh` avec 9 px de retrait et un `space-between` qui renvoyait « hors numérotation » sur
     sa propre ligne, et `.pl-sech` avec 2 px. On garde le second et l'on n'en fait qu'un : même
     retrait que les rangées, et la précision suit le titre dans la même phrase.
     `.pl-cxh` est donc PURGÉE avec sa règle (règle 14) — et son sélecteur avait été recopié dans
     `audit-complications`, qui serait resté vert sans rien mesurer : une purge emporte les SONDES
     qui désignaient le composant. */
  /* ⚠ L'INTERTITRE S'ALIGNE SUR LES RANGÉES (signalé à l'usage : « à tout moment paraît décalé
     par rapport au reste »). Il vivait à 2 px du bord quand les rangées commencent à 9 : deux
     colonnes de départ dans une colonne qui n'en a qu'une. */
  /* ⚠ L'INTERTITRE S'ALIGNE SUR LES RANGÉES DE SA COLONNE — et celles-ci ont un retrait de 2 px,
     pas de 9 (première correction : j'avais aligné sur le retrait de la carte de LECTURE, ce qui
     décalait l'intertitre de 7 px dans la colonne désaturée, exactement le défaut signalé, à
     l'envers). On mesure, on n'extrapole pas d'une surface à l'autre. */
  /* ⚠ TOUS LES INTERTITRES DE LA COLONNE PARTENT DU MÊME x (demande utilisateur) : « ⚡ À tout
     moment » et « Surveiller après les gestes » s'alignent sur « Parcours inerte » — et, en rail
     unique, sur « Minuteurs & compteurs » et « Repères posologiques », qui sont des `.rail-title`
     sans retrait. Mesuré avant : 18 / 20 / 23 px ; après : 18 partout. Les RANGÉES gardent leur
     retrait de 2 px : ce sont elles qui s'indentent sous leur titre, pas l'inverse. */
  /* ⚠ UN SEUL ÉCART ENTRE UN TITRE ET SES RANGÉES (demande utilisateur, et « Surveiller ensuite
     était trop collé à la ligne du dessus »). Les en-têtes de queue vivent DANS l'échelle, donc
     ils y prennent la même marge basse que celui de tête (10 px) et une marge haute qui les
     détache franchement de la section précédente (20 px) — quel qu'en soit le nombre. */
```

## C66 — LA BARRE D'ACTIONS DU COMPTE-RENDU (M8). Sous 560 px, elle est COLLANTE au bas de la feuille

```
  /* LA BARRE D'ACTIONS DU COMPTE-RENDU (M8). Sous 560 px, elle est COLLANTE au bas de la feuille
     et les boutons occupent toute la largeur : le compte-rendu peut faire plusieurs écrans, et
     l'action ne doit pas se chercher au bout d'un défilement. Elle n'enfreint pas « aucune zone
     fixe en bas » (SPEC §5), qui vise le CHROME d'une vue de crise : ici on est dans une feuille
     de débriefing, hors session, et la barre appartient à la feuille — pas à l'application.
     Au-dessus, elle redevient une rangée alignée à droite : la place existe, le geste est rare.
     ⚠ v5.6 (planche 7e) — ELLE N'A PLUS BESOIN D'ÊTRE COLLANTE : la carte est le défileur et le
     pied est son enfant FIXE, comme dans les deux autres gabarits. `position:sticky` y était le
     seul moyen de tenir la promesse quand c'était la MODALE qui défilait ; garder les deux
     mécanismes pour un même effet, c'est en laisser un diverger. Le filet remplace l'ombre
     montante : un pied posé sur son propre fond, dans une carte, se sépare par un trait. */
```

## C67 — Repères posologiques (canvas) : cartes ; « ⚠ » en tête = registre ALERTE.

```
  /* Repères posologiques (canvas) : cartes ; « ⚠ » en tête = registre ALERTE. */
  /* ══ UN REPÈRE : NOM FACULTATIF, PUIS UN CORPS LIBRE (7d, « Points ouverts ») ═════════════
     Le corps est du TEXTE D'AUTEUR, potentiellement long — quatre lignes, du gras interne, et
     parfois pas de nom du tout. Ni troncature, ni `nowrap`, ni hauteur fixe : un dosage tronqué
     est une faute clinique. La carte grandit, c'est tout.
     ⚠ J'AVAIS MIS LA VALEUR EN LIGNE APRÈS LE NOM à la passe précédente, sur la foi d'une
     maquette où toutes les valeurs tenaient en cinq mots. Sur du texte réel, cela colle une
     phrase de quatre lignes à la suite d'un nom en petites capitales et l'on ne sait plus où
     commence la dose. Le nom prend sa ligne, le corps la sienne. */
  /* ⚠ LE FILET D'UN ITEM N'EST PAS CELUI D'UNE FAMILLE (v5.6, signalé à l'usage). Les deux
     étaient un trait de 1 px pleine largeur. Celui de la FAMILLE reste ainsi — franc, d'un bord à
     l'autre ; celui de l'ITEM RENTRE de 10 px. C'est le retrait qui les distingue au premier coup
     d'œil, pas une nuance de gris qu'il faudrait comparer.
     ⚠ LE RETRAIT EST SUR LE TRAIT, JAMAIS SUR LA BOÎTE (mesuré, puis corrigé). Écrit en
     `padding-left`, il volait 10 px au TEXTE : une posologie longue passait sur une ligne de
     plus, et un témoin de partage a immédiatement signalé 21 px de dérive sous les yeux de
     quelqu'un qui n'avait rien demandé. Le filet est donc un pseudo-élément — il rentre, la
     colonne de texte ne bouge pas d'un pixel. */
```

## C68 — Rangée cochable (lot 8, v4.23.0 — retours d'usage successifs : « box dans box surchargé »,

```
  /* Rangée cochable (lot 8, v4.23.0 — retours d'usage successifs : « box dans box surchargé »,
     puis « tout plat = immonde et on identifie moins bien les items non colorés »). RÈGLE RETENUE :
     c'est la BOX PARENTE À BORD BLEU qui porte l'emphase « ici l'action » — les étapes à
     l'intérieur n'ont donc PAS besoin d'être des boîtes elles-mêmes (ce double encadrement était
     la faute d'origine). Dedans : lignes plates uniformes à filet fin, et une étape signalée est
     une BANDE INTÉGRÉE (teinte + liseré) qui file jusqu'aux bords du bloc — jamais une boîte
     arrondie détachée, qui écrasait visuellement les lignes voisines.
     Le NUMÉRO d'étape est SUPPRIMÉ : on coche dans n'importe quel ordre et il n'ancrait aucune
     référence croisée (les renvois →/↺ visent le numéro de BLOC, `.ov-n`, conservé). */
  /* D1 (audit design v4.56) : la rangée ENTIÈRE est déjà la cible (le <li> porte data-ck) —
     sa hauteur passe de 54 à 60 px : le 44 px doctrinal est un MINIMUM, pas un optimum, et un
     pouce ganté dans une ambulance en mouvement ne vise pas une case de 24 px. */
```

## C69 — v4.13.1 : min-width:0 + césure — sans eux, un mot long (« compressions ») fixe le

```
  /* v4.13.1 : min-width:0 + césure — sans eux, un mot long (« compressions ») fixe le
     min-content du texte et pousse la CASE hors du cadre en étroit / grande taille de texte. */
  /* LE RELIEF REVIENT AU REGISTRE (v4.74.2, signalé à l'usage : « le gras des étapes n'est pas
     très esthétique et serait questionnable »). Chaque étape était à 800 — le poids d'un titre
     appliqué à un paragraphe : plus rien ne ressortait, ce qui est mot pour mot le reproche fait
     à l'inflation du rouge. 600 pour une étape ORDINAIRE, 800 conservé pour les seules étapes
     `⚠`/`△` : la hiérarchie passe alors par le TYPE d'étape, ce que la doctrine dit déjà vouloir
     (« le gras est exclu des étapes, le relief passe par le type »). Même geste que la v4.73.0 sur
     les chronos (700 → 500) et pour la même raison : l'état ne crie pas plus fort que l'action.
     Le CORPS ne bouge pas (16,5 px, palier de l'échelle fermée) : c'est la graisse qui s'aligne. */
  /* v5.6 — LE CORPS EST LE CANAL DU DANGER, PAS LE FOND. Une étape ordinaire est à --t-item ;
     seule l'étape CRITIQUE monte à --t-step (A11). C'est l'écart de corps qui hiérarchise, et il
     ne peut le faire que si toutes les lignes ne l'ont pas. */
```

## C70 — PAS de bandeau ambre sur une étape en écart (retiré v4.25.2, retour d'usage). Le liseré

```
  /* PAS de bandeau ambre sur une étape en écart (retiré v4.25.2, retour d'usage). Le liseré
     inset de 3 px est le canal du REGISTRE de l'étape (⚠/△ — une propriété du CONTENU, cf. la
     doctrine « normal = ligne, signalé = boîte » de v4.24.0). L'écart, lui, est un ÉTAT DE LA
     PASSE de vérification. Réutiliser le même trait pour les deux rendait le signal ambigu : on ne
     pouvait plus dire si l'ambre annonçait « étape de vigilance » ou « écart constaté ». L'état de
     la passe est déjà porté, sans ambiguïté, par la pilule « △ écart » — mot + glyphe. */
  /* Case à cocher À GAUCHE (v4.23.0) : ordre naturel du DOM, aucune propriété `order`. Le côté
     DROIT venait du canvas V5 et ne valait que pour cette surface — les listes cochables des
     protocoles (`li.md-task`) ont toujours eu la case à GAUCHE : les deux sont désormais
     cohérentes. À gauche, les cases forment une COLONNE que l'œil descend (scannabilité) —
     d'où l'exigence absolue ci-dessous : cette colonne ne doit JAMAIS se décaler. */
  /* Case à 26 px (maquette) : la CIBLE n'en dépend pas — c'est la RANGÉE entière qui est
     cochable (60 px de haut, `role="checkbox"` sur le `li`), et la doctrine D1 le dit déjà. Une
     case de 36 px était un objet de plus dans une colonne qui doit se scanner. */
```

## C71 — Étape SIGNALÉE = BANDE INTÉGRÉE. Le liseré est un `inset box-shadow`, PAS une bordure : une

```
  /* Étape SIGNALÉE = BANDE INTÉGRÉE. Le liseré est un `inset box-shadow`, PAS une bordure : une
     bordure décalerait le contenu de 3px et briserait l'alignement de la colonne de cases (tout
     l'intérêt du passage à gauche). Le débordement est compensé au pixel par le padding, donc la
     case reste EXACTEMENT sur la même verticale que celle des lignes normales. */
  /* ══ A11 (v5.6) — L'APLAT EST RÉSERVÉ À CE QUI EXIGE UNE ACTION MAINTENANT ═════════════════
     L'étape signalée était une BANDE TEINTÉE pleine largeur (fond + liseré inset + texte coloré).
     Mesuré à l'usage sur un bloc de cinq étapes : deux bandes colorées happaient l'œil et
     DÉTRUISAIENT la lecture de la séquence — on ne lisait plus une checklist, on lisait deux
     alarmes entourées de gris. Or l'aplat coloré est le registre de l'échelon AU-DESSUS : ce qui
     exige une action MAINTENANT, c'est-à-dire l'alarme active — et il n'y en a qu'UNE à l'écran.
     UNE ÉTAPE CRITIQUE SE MARQUE, ELLE NE SE REMPLIT PAS : case rouge + glyphe ⚠ + CORPS à 17,5 px
     + cadence mono ambre. Quatre canaux, aucun aplat, aucun cadre — et le corps est le canal le
     plus fort de tous, celui que la v5 donnait au chrono. La couleur n'est jamais seule (règle 8) :
     le glyphe et son étiquette `.sr-only` restent.
     ⚠ LE `--step-bleed` PART AVEC LA BANDE : il n'existait que pour que le liseré inset déborde
     sans décaler la colonne de cases. Plus de bande, plus de compensation à faire — et la colonne
     de cases est alignée par CONSTRUCTION, ce qui était tout l'enjeu du passage à gauche. */
  /* ⚠ UNE ÉCHELLE ORDONNÉE, PAS DEUX ÉTATS BINAIRES (signalé à l'usage : « difficile de
     différencier étapes vitales de à vérifier »). Mesuré avant : une étape △ ne différait d'une
     étape ORDINAIRE que par la couleur de son glyphe et de sa case — même corps, même graisse,
     même encre. Deux signaux de 13 px sur une ligne de 15, dans une colonne où toutes les lignes
     se ressemblent : le registre intermédiaire était illisible.
     La GRAISSE devient le troisième canal, et elle est MONOTONE — 600 ordinaire, 700 vigilance,
     800 vital — de sorte que les trois se rangent d'eux-mêmes sans qu'on ait à les comparer deux
     à deux. Le CORPS reste le canal du seul vital (15 → 17,5) : l'étendre à « on s'y trompe »
     remettrait les deux registres à égalité, et l'on aurait déplacé l'inflation au lieu de la
     supprimer. Toujours aucun aplat, aucun cadre (A11). */
```

## C72 — Étape COCHÉE : l'état « fait » s'aplatit avec la ligne — l'information est portée par la

```
  /* Étape COCHÉE : l'état « fait » s'aplatit avec la ligne — l'information est portée par la
     COCHE verte pleine + l'encre douce + la graisse (400 contre 600). La coche ENTRE avec le
     « pop » (canvas ; transform seul, composité). Une étape SIGNALÉE cochée CONVERGE vers le vert
     doux (doctrine V5 : l'urgence est traitée) : sa bande perd sa teinte d'alerte et son liseré
     passe au vert.
     ⚠ NI OPACITÉ NI BARRÉ (v5.0.0, audit design A1-1 — MESURÉ, et c'est la seule violation AA
     qu'ait porté ce fichier). `opacity:.6` + `--done-ink` composaient un texte à **2,55:1 en
     clair et 1,95:1 en SOMBRE**, quand l'étape non cochée juste en dessous mesure 17,36 / 16,65 :
     un facteur 7 à 9 entre deux lignes voisines. L'exemption WCAG « composant inactif » ne joue
     PAS — une étape cochée reste un `role="checkbox"` `tabindex="0"` décochable.
     TROIS SOURCES CONVERGENTES, et la troisième est ce fichier lui-même. (a) ECAM : une action
     accomplie passe au vert et RESTE pleinement lisible — le decluttering retire ce qui n'est
     plus PERTINENT, il ne rend pas illisible ce qu'on vient de faire, précisément parce que la
     relecture est le mécanisme de reprise. (b) AC 120-71B §5.4 + Degani & Wiener : « perdre sa
     place est un mode de défaillance premier », ce que ce dossier cite déjà pour justifier
     l'abandon du un-item-à-la-fois (v4.28.0) — une ligne à 1,95:1 barrée EST une ligne perdue.
     (c) LA CONTRADICTION INTERNE : `.sv-stp li.done` porte le commentaire « texte JAMAIS barré
     (relecture) » et `li.md-task.done` la même règle ; la vue de SOIN, seule des trois à compter
     en crise, était la seule à barrer ET estomper. Deux vocabulaires pour une idée, ce qu'AC
     120-71B §5.5 proscrit.
     APRÈS : 5,93:1 en clair, 11,15:1 en sombre. Rien n'est perdu — la distinction fait/à faire
     garde TROIS canaux (case verte pleine, graisse, encre), donc la couleur n'est jamais seule
     (règle 8). Et l'exception `@media print` qui remettait `opacity:1` + `text-decoration:none`
     A DISPARU avec la cause : l'écran et le papier disent enfin la même chose.
     ⚠ Ne pas « restaurer » l'opacité pour retrouver du contraste d'état : le canal d'état est la
     COCHE, pas l'effacement du texte. */
  /* La case FAITE est une pastille DOUCE, pas un aplat plein : sur une liste où la moitié des
     lignes finit cochée, l'aplat vert faisait une colonne de masses colorées — et A11 réserve
     l'aplat à ce qui exige une action MAINTENANT. Le ✓ garde son encre pleine, l'information est
     dans le glyphe. */
```

## C73 — Options de décision : MÊME hauteur que les rangées d'étapes (64px — retour utilisateur,

```
  /* Options de décision : MÊME hauteur que les rangées d'étapes (64px — retour utilisateur,
     conforme au canvas) ; une seule échelle de cliquables dans le parcours. */
  /* 16.5px comme `ol.steps li .txt` (v4.24.0) : choisir une branche est au moins aussi engageant
     que cocher une étape — rien ne justifiait de le rendre MOINS lisible. La graisse reste 700 (et
     non 800) : c'est un CHOIX, pas une action. */
  /* Le CHOIX prend le registre de l'ACTION (maquette) : contour `--act` de 2 px sur fond de
     travail, les deux issues de poids STRICTEMENT égal — aucune n'est suggérée. L'ambre reste
     au REGISTRE du bloc (son étiquette, son liseré), pas au geste. */
  /* ⚠ LE CONTOUR D'UNE ISSUE PREND LE REGISTRE DE SA CARTE (v5.6, question de l'auteur : « la
     couleur de contour des options dans les blocs conditionnels ne devrait-elle pas être celle de
     la bordure du bloc, ambre ? »). Elle a raison sur ce point précis, et A17 n'en souffre pas :
     ce que A17 protège est que les issues soient de POIDS STRICTEMENT ÉGAL et qu'AUCUNE ne soit
     suggérée — ce que le contour ne dit pas. Il dit à quel OBJET on appartient, et deux boutons
     bleus dans une carte bordée d'ambre annonçaient deux registres sur une même carte, ce que le
     dossier proscrit partout ailleurs (v4.24.0, « un registre n'est jamais masqué par un état »).
     ⚠ ET CE N'EST PAS UNE ALERTE DE PLUS : l'ambre est DÉJÀ déclaré au niveau de la carte
     (étiquette + liseré) ; le reprendre sur ses issues ne crée aucun signal neuf, il rattache.
     LA DESTINATION, elle, GARDE `--act` : « → bloc 4 · Stabilisé » est ce qui MÈNE quelque part,
     et c'est le seul endroit où le registre d'action a un sens ici. */
```

## C74 — Masqué visuellement mais lu par les lecteurs d'écran (zone aria-live).

```
  /* Masqué visuellement mais lu par les lecteurs d'écran (zone aria-live). */
  /* ═══ COMPLICATIONS « à tout moment » (v4.26.0) ═══
     Registre ALERTE en CONTOUR, jamais rempli : l'entrée d'un événement vital mérite le rouge
     (doctrine v4.2.2 : ce qui tue si on l'oublie), mais un aplat permanent désensibiliserait
     (règle du bandeau blanc). Glyphe ⚡ + mot en toutes lettres — la couleur jamais seule. */
  /* ═══ MODE EXERCICE (v4.27.0) — annonciation « placard TRAINING » : hachures + mot, en BLEU
     (ni rouge ni ambre : ce n'est pas une alerte). Le vert « ● Session » reste réservé au RÉEL. */
  /* HACHURES BLEUTÉES (v4.28.0, retour utilisateur) : surface/surface-2 était quasi invisible
     en SOMBRE (#121d2b vs #101823, delta infime) — les bandes alternent désormais avec
     --primary-soft : le REGISTRE exercice (bleu) porte la texture, lisible dans les deux thèmes.
     Et le placard ne quitte plus l'écran : le QUAI COLLANT (#crisisDock.exo) porte les mêmes
     hachures (les segments reprennent un fond plein pour rester lisibles dessus), et le relais
     d'en-tête #hdrCrisis.exo devient la même pilule bleu pointillé que .cb-tag.exo. */
  /* v4.29.0 (retour utilisateur : hachurer le QUAI était illisible — « immonde ») : la hachure
     SUIT LE TITRE. Tant que le bandeau-titre est visible, lui seul est hachuré ; au pixel où il
     passe sous la barre (.ttl-on, mécanique du relais #hdrCrisis), c'est L'EN-TÊTE qui prend la
     hachure — même texture, même relais que le titre lui-même. Le quai reste une zone d'état
     PROPRE (les chiffres n'ont pas à vivre sur une texture).
     v4.29.1 (retour utilisateur « ça saute ») : la hachure vit sur un ::before en FONDU
     d'opacité — l'entrée/sortie du mode ET le passage bandeau → en-tête au défilement se font
     en ~300 ms au lieu d'un aplat instantané ; le fondu est neutralisé par la règle globale
     prefers-reduced-motion (transition:none). Les enfants passent en z-index:1 : le ::before
     est AU-DESSUS du fond de l'élément, jamais au-dessus de son contenu.
     v5.0.5 (signalé à l'usage, capture à l'appui) — LA HACHURE EST ANCRÉE AU VIEWPORT, PAS À SON
     ÉLÉMENT. Un placard est UN placard, porté par deux boîtes (l'en-tête et le bandeau) ; chacune
     générait pourtant son dégradé depuis SON propre coin haut-gauche, si bien que les rayures se
     brisaient net à la frontière — deux textures voisines au lieu d'une seule qui traverse.
     ⚠ PREMIÈRE TENTATIVE, `background-attachment:fixed`, RETIRÉE SUR SIGNALEMENT — et l'erreur
     de méthode vaut d'être gardée. L'ancrage au viewport est le raisonnement JUSTE (deux boîtes
     dont l'écart change à chaque frame ne peuvent partager une phase que via un repère commun qui
     ne soit ni l'une ni l'autre), il était vert aux deux moteurs en headless, et il est FAUX SUR
     L'APPAREIL : « celui d'en haut bouge lors du scroll ; et ils ne sont pas toujours synchronisés ».
     WebKit ne repeint pas un fond fixé en même temps qu'il défile — la texture retarde, glisse,
     puis se recale. Même famille que le dossier « bande basse iOS » et que le rebond du rail A→Z :
     ce que le compositeur fait du rendu n'est visible dans AUCUNE mesure de la page, donc un
     harnais vert ne dit rien ici. On n'ancre plus à un repère que l'on ne contrôle pas.
     CE QUI TIENT SA PLACE — chaque hachure appartient à SA barre, et l'on cale la phase de celle
     du bas sur celle du haut par un décalage MESURÉ, `--hdr-h`. Les deux boîtes de dégradé sont
     les boîtes de rembourrage des deux barres : même bord gauche, et un écart vertical qui vaut
     exactement la hauteur de l'en-tête. Un `background-position` de cette valeur les met en phase,
     sans un octet de JS et sans que rien ne dépende du défilement.
     ⚠ CE QUE CE DÉCALAGE EXIGE, ET QUI EST LE VRAI TRAVAIL : un décalage PAVE, or un dégradé
     répétitif est dimensionné sur sa boîte et sa phase s'ancre à son coin BAS-DROIT — deux boîtes
     de hauteurs différentes ne sont donc jamais en phase, et le pavage coudrait à chaque report.
     On fixe donc une TUILE CARRÉE (`background-size`) et l'on exprime les bandes en POURCENTAGE de
     la ligne de dégradé : à −45° cette ligne vaut côté × √2, et une période de 50 % en met deux
     par tuile, exactement — la tuile est raccordable par construction, à n'importe quelle taille,
     sans jamais écrire √2 dans une feuille de style. 31 px de côté redonnent la période d'origine
     (21,9 px pour 22) au dixième de pixel près, et un entier pave net à 1×, 2× et 3×.
     RESTE la contrepartie, assumée et bornée : la phase n'est commune qu'au repos. Dès qu'on
     défile, chaque texture suit SA barre — c'est ce que fait une texture peinte sur un objet, rien
     ne bouge tout seul, et le bandeau part de toute façon sous la barre en moins de 60 px.
     ⚠ TOUTE VARIANTE DE HACHURE S'ÉCRIT EN `background-image`, jamais avec le raccourci
     `background`, qui remettrait `background-size` et `background-position` à leur défaut et
     casserait l'alignement de ce placard-là seulement — donc en silence. */
```

## C75 — L'EN-TÊTE NE LÈVE PAS SES ENFANTS, ELLE ENFONCE SA HACHURE — et ce n'est pas une élégance,

```
  /* L'EN-TÊTE NE LÈVE PAS SES ENFANTS, ELLE ENFONCE SA HACHURE — et ce n'est pas une élégance,
     c'est le correctif d'un défaut signalé à l'usage : `header.bar.exo>*{position:relative}`
     vaut (0,2,1) et écrasait `.more-menu{position:absolute}` (0,1,0). Le menu ⋯, qui est un
     enfant DIRECT de l'en-tête, retombait donc dans son flux — il s'ouvrait DANS la barre au
     lieu de flotter dessous, dès que le placard d'exercice ou d'invité était posé.
     Un `>*` qui impose `position` casse tout enfant qui se positionne lui-même. Nommer le menu
     dans un `:not()` ne ferait que déplacer le piège au prochain calque ajouté ici ; on retire
     donc l'exigence au lieu de l'assortir d'exceptions. `header.bar` porte déjà
     `position:sticky; z-index:20`, donc elle EST un contexte d'empilement : un `::before` en
     `z-index:-1` s'y peint au-dessus du fond de la barre et sous TOUT son contenu, sans que le
     moindre enfant ait à être positionné.
     POURQUOI `#crisisBand` GARDE L'ANCIENNE MÉCANIQUE : il est `position:relative` mais sans
     `z-index`, donc PAS un contexte d'empilement — un `z-index:-1` y passerait sous son propre
     fond et la hachure disparaîtrait. Ses enfants sont tous statiques, la levée ne casse rien. */
```

## C76 — ⚠ LES TROIS GESTES DE BLOC PARTAGENT UNE SEULE BOÎTE (signalé à l'usage : « uniformise taille

```
  /* ⚠ LES TROIS GESTES DE BLOC PARTAGENT UNE SEULE BOÎTE (signalé à l'usage : « uniformise taille
     texte / style boutons entre Complications, Noter l'heure et Vérifier »). Mesuré avant, ils
     différaient sur TROIS axes : corps 13,5 / 13,5 / 12 px, rembourrage 8-14 / 8-12 / 6-10, et
     trois traitements de fond. Le troisième perdait en plus contre `.ov-redo`, déclarée ailleurs
     avec la même spécificité — le gabarit qu'on lui avait écrit ne s'appliquait qu'à moitié.
     Ils sont de MÊME RANG (trois actions qu'on prend après avoir déroulé les étapes), donc même
     boîte : 44 px de cible, 13,5/700, rembourrage et rayon identiques. SEUL LE REGISTRE DISTINGUE,
     et il porte du sens : « Noter l'heure » est TONAL (le geste le plus fréquent), la complication
     est en CONTOUR d'alerte — jamais remplie, un aplat rouge permanent désensibilise (v4.26.1) —,
     « Vérifier » est neutre. Sélecteur en (0,2,0) pour battre `.ov-redo` quel que soit l'ordre :
     pour une géométrie, ne jamais dépendre de la position dans la feuille. */
  /* Le pied de carte : « Vérifier :: » à gauche, « Continuer » en dernier, pleine largeur
     restante — un seul rang, comme dans la maquette. */
```

## C77 — LA CROIX DÉBORDAIT DU CADRE (v4.55.3, retour d'usage). `.rt-head` est une rangée flex qui ne

```
  /* LA CROIX DÉBORDAIT DU CADRE (v4.55.3, retour d'usage). `.rt-head` est une rangée flex qui ne
     passe pas à la ligne et dont rien n'est compressible : mesuré sur écran TACTILE, son contenu
     exige 331 px pour 221 disponibles à 320 — la croix sortait de **110 px**, 70 à 360, 40 à 390,
     7 à 430. Deux enfants gonflent au toucher (« silencieux ? » 100 px, le bouton son 64 px sur
     deux lignes) parce que les cibles y montent à 44 px.
     Remède = le patron déjà éprouvé de la carte-bilan (v4.29.2) : conteneur `relative`, croix
     ANCRÉE en haut à droite, et un `padding-right` qui lui réserve sa place à TOUTES les largeurs.
     Le reste s'enroule dessous plutôt que de la pousser hors de l'écran — on ne tronque pas un
     libellé de commande, on lui donne une seconde ligne. */
  /* ⚠ L'AVERTISSEMENT A RETROUVÉ SES MOTS, ET SA RÈGLE EST PURGÉE AVEC SA CAUSE (v5.6). Il passait
     au glyphe seul sous 560 px parce que l'en-tête du volet portait le titre, cet avertissement, le
     son ET la veille — 330 px demandés pour 294 à 390 px. Les deux interrupteurs sont descendus au
     pied (`.rt-set`) : la rangée est libre, et une CAUTION muette n'aurait de toute façon rien
     averti. La classe `.rt-wl` disparaît avec la règle qui la servait (règle 14). */
```

## C78 — ⚠ ÉPILOGUE DE L'ANCRAGE (v5.10.8) — LA CROIX EST REDEVENUE UN ENFANT DE LA RANGÉE. Le patron

```
  /* ⚠ ÉPILOGUE DE L'ANCRAGE (v5.10.8) — LA CROIX EST REDEVENUE UN ENFANT DE LA RANGÉE. Le patron
     `absolute` + `padding-right` réservé ci-dessus répondait à une rangée QUI DÉBORDAIT : titre +
     avertissement + son + veille, 331 px demandés pour 221 à 320 px. Cette rangée n'existe plus —
     les deux interrupteurs sont au pied (`.rt-set`), `.rt-wl` est purgée, et depuis la v5.10.8 le
     titre est le sous-titre « Minuteurs » : il reste DEUX enfants, un mot court et un ✕.
     Ancrer une croix hors flux dans une rangée qui ne peut plus déborder coûtait alors une vraie
     hauteur : la rangée se dimensionnait sur le seul titre (17 px), et l'on RÉINJECTAIT à la main
     `min-height:48px` sur ce titre pour que la croix ne paraisse pas flotter une demi-ligne trop
     bas — c'est-à-dire qu'on payait la hauteur de la croix DEUX fois. En flux, la rangée fait
     exactement la hauteur du plus grand de ses deux enfants, et les deux se centrent d'eux-mêmes.
     La réserve `padding-right` part avec l'ancrage : elle protégeait une place que plus rien ne
     dispute. */
```

## C79 — A11 dans le rail : un repère posologique SIGNALÉ se marque (△ + encre ambre + filet), il ne

```
  /* A11 dans le rail : un repère posologique SIGNALÉ se marque (△ + encre ambre + filet), il ne
     prend pas d'aplat — sinon deux repères font deux masses colorées dans une colonne dont toute
     la doctrine est la désaturation, et l'aplat cesse de vouloir dire « maintenant ». */
  /* ══ LE RAIL EST UNE COLONNE D'ÉTAT, PAS UN PANNEAU DE COMMANDE (v5.6, maquette) ═══════════
     Mesuré avant : une carte de minuteur y occupait ~190 px (nom, précision, valeur 34 px, barre,
     « Cycles : n », puis DEUX boutons pleine largeur), et un compteur ~150 px en carte centrée.
     Trois minuteurs et deux compteurs enterraient la posologie et l'Échelle sous un pli invisible
     — le défaut que la v5.4.3 avait déjà dû corriger en repliant deux zones.
     LA MAQUETTE INVERSE LE RAPPORT : la colonne AFFICHE (nom · cycles · valeur, 76 px), et les
     COMMANDES ne paraissent qu'au tap sur la carte. Deux exceptions, et ce sont les deux qui
     comptent : un minuteur ÉCHU garde son « RELANCER » sous les yeux — c'est l'acquittement de
     l'alarme, il ne se cherche pas —, et les ± d'un compteur restent, parce qu'incrémenter est le
     geste le plus fréquent du rail. A8 est tenue : tout ce qui reste visible fait 44 px.
     ⚠ BORNÉ AU RAIL. Le panneau et le volet gardent la carte COMPLÈTE — on les ouvre justement
     pour régler, et c'est là que vivent la barre de progression et la remise à zéro. */
```

## C80 — Anatomie du canvas (rail droit) : UNE variable d'état --tcol pilote libellé + temps +

```
  /* Anatomie du canvas (rail droit) : UNE variable d'état --tcol pilote libellé + temps +
     barre (+ bordure via --tbd) ; courant = bleu, ÉCHU = AMBRE (le rouge reste réservé aux
     memory items / vital), en pause = encre douce + texte « — EN PAUSE » (jamais couleur seule). */
  /* P2-7 (audit design v4.56) : --link est doctrinalement « le temps d'un minuteur EN COURS » —
     le défaut (arrêt) passe en ENCRE, .run porte l'accent ; .due/.paused déclarées APRÈS gagnent. */
  /* ══ A9 — HAUTEURS D'ÉTAT FIXES ═══════════════════════════════════════════════════════════
     Un changement d'état NON commandé (un minuteur qui devient échu, une alarme qui s'éveille)
     ne modifie JAMAIS une hauteur : seuls matière, couleur et texte changent. C'est le corollaire
     direct de « rien ne bouge sous le doigt » — et le point le plus facile à rater, parce que la
     structure DOM est identique d'un état à l'autre : ce qui varie, c'est le LIBELLÉ (« Adrénaline »
     devient « Adrénaline — échu »), et un mot de plus fait passer le nom sur deux lignes, donc la
     carte grandit sous le doigt de quelqu'un qui n'a rien demandé.
     Deux verrous : la carte a un gabarit MINIMAL, et le libellé est borné à deux lignes (au-delà
     il s'ellipse — un nom de minuteur est court par convention, et le nom accessible reste
     entier). L'expansion COMMANDÉE par un tap (volet, carte dépliée) n'est pas concernée. */
```

## C81 — La barre est TOUJOURS pleine largeur et se vide par `scaleX` — JAMAIS par `width` (v4.41.0).

```
  /* La barre est TOUJOURS pleine largeur et se vide par `scaleX` — JAMAIS par `width` (v4.41.0).
     `width` est une propriété de MISE EN PAGE : animée en continu, elle faisait tourner une passe
     de layout par image pendant TOUTE la durée d'une réanimation. Mesuré (médiane de 3, fenêtre
     de 6 s sans aucun geste, session vive + 1 minuteur d'intervalle, CDP Performance.getMetrics) :
     118 layouts/s et 123 recalculs de style/s, pour 126,8 ms/s de fil principal à CPU nominal,
     206,9 à ×4 et 377,3 à ×6 — soit jusqu'à 38 % d'un cœur consommés à ne rien faire d'autre.
     En `scaleX` (composé, hors mise en page) : 2 layouts/s, 17 recalculs/s, 13,3 / 14,3 / 27,7 ms/s
     — autant que supprimer l'animation (11,7 / 14,7 / 21,5), mais SANS changer le rendu. WebKit,
     hors CDP : +9,7 % de débit utile du fil principal, contre +9,3 % pour la suppression.
     RENDU, mesuré et non supposé : la géométrie peinte est identique à 0,01 px près à valeurs
     figées (198,36 px contre 198,36 à 76 % sur un wrap de 261 px), et la comparaison AU PIXEL des
     deux captures ne diffère que sur UNE colonne de 4 px — l'anticrénelage du bord mobile, écart
     max 73/255 — plus les deux extrémités arrondies à 100 % (écart ≤ 9/255). Identique dans les
     deux thèmes. Invisible sur un bord qui se déplace de toute façon en continu, mais ce n'est pas
     bit-à-bit : ne pas écrire « rendu identique » sans cette nuance.
     Précédent interne : `.t-life` (barre de vie des toasts) fait déjà exactement cela.
     `transform-origin:left` est OBLIGATOIRE (sans lui la barre se viderait par les deux bords). */
```

## C82 — Carte-bilan de fin de session (v4.16.3) : registre CONFIRMATION (bord gauche --ok),

```
  /* Carte-bilan de fin de session (v4.16.3) : registre CONFIRMATION (bord gauche --ok),
     éphémère et jamais bloquante — grammaire des notices (couleur + icône + texte). */
  /* REJOINDRE UNE SESSION — ligne discrète de la zone des sessions. Ni carte, ni bouton rempli :
     ce n'est pas l'action principale de l'accueil, et la doctrine n'admet qu'un seul bouton rempli
     par écran. Cible 44 px quand même : on la tape sous stress, avec le code d'un collègue en
     tête. Elle ne porte AUCUN liseré de gauche — ce canal appartient aux registres (état d'une
     session, alerte), et rejoindre n'est pas un état. */
  /* BRIDAGE VISIBLE — JAMAIS PAR MASQUAGE. Masquer les contrôles réservés au lead ferait sauter le
     contenu clinique de 46 px (mesuré), et sur ÉVÈNEMENT DISTANT si le rôle change : quelqu'un qui
     n'a rien demandé verrait sa checklist bouger sous son doigt. La boîte reste donc en place, à
     la même géométrie, et le scribe APPREND où sont les choses.
     PAS D'`opacity` : un texte à 50 % tombe sous le seuil AA, et le projet a déjà tranché ce point
     pour le « hors chemin » du rail. On passe par l'encre secondaire, qui est conforme, plus le
     curseur — et le refus s'annonce au lecteur d'écran quand le geste est tenté.
     LA LISTE EST LA MÊME QUE `LEAD_ONLY_SEL` côté script : deux listes divergeraient, d'où un
     contrôle de harnais qui parcourt la liste du SCRIPT et vérifie que chaque élément rendu porte
     bien l'apparence désactivée. */
  /* DEUX SÉLECTEURS, ET LE SECOND N'EST PAS DÉCORATIF : `.btn.cont.okay` pèse (0,3,0) et
     l'emportait sur un `body.share-scribe :is([attr])` à (0,3,1)… non, à (0,2,1) — un scribe
     voyait donc un « Continuer » pleinement vert, prêt à l'emploi, alors que le geste lui est
     fermé. La variante `.btn:is(…)` monte à (0,3,1) et reprend la main. Même leçon que les six
     pièges de cascade précédents, sous sa forme la plus fine : ici ce n'est pas l'ORDRE qui
     trompe, c'est la SPÉCIFICITÉ. */
```

## C83 — ⚠ « REPRENDRE » EST UN RETOUR D'EXCURSION, ET IL EN PREND LE REGISTRE (audit externe v5.10.0,

```
  /* ⚠ « REPRENDRE » EST UN RETOUR D'EXCURSION, ET IL EN PREND LE REGISTRE (audit externe v5.10.0,
     décision de l'auteur). Rempli en `--act`, il ne tenait que 1,69:1 CONTRE SA CARTE : l'encre
     blanche était lisible (9,36) mais la FORME du bouton ne se détachait pas de la matière système
     — c'est le défaut qu'A43 a nommé pour la pastille Compte, et que WCAG 2.2 § 1.4.11 vise, la
     limite d'un composant et non son texte. `--ok-sys` mesure 9,08:1 sur la même carte.
     ET CE N'EST PAS QU'UNE AFFAIRE DE CONTRASTE : c'est déjà le remplissage de `.sd-key.dp-back`,
     le retour d'excursion du dock — « vous êtes loin de chez vous, ceci vous y ramène ». Reprendre
     une session vive est ce geste à l'échelle de l'application, et la carte porte déjà son point et
     son chrono en `--ok-sys` : un seul registre, du haut en bas de l'objet.
     ⚠ L'ENCRE EST `--on-sys-fill`, JAMAIS `--on-primary` : sur un aplat CLAIR posé sur la matière
     sombre, le blanc ne tient que 1,74:1 — le token existe pour ce cas précis et le dit.
     ⚠ LA RÈGLE DU BOUTON REMPLI UNIQUE TIENT : les seuls autres remplis de l'accueil vivent dans
     les cartes d'état vide, qui ne peuvent pas coexister avec une session vive.
     Le survol NE CHANGE PAS le fond, comme `.sd-key.dp-back:hover` : sur un registre d'action, la
     réponse au geste est l'élévation, pas un second vert. L'anneau de focus passe à `--sys-ink` —
     `--primary` ne tient que 1,69:1 sur cette carte, donc l'anneau y était aussi peu visible que
     le bouton. (0,3,0) : `.btn.primary` vaut (0,2,0) comme `.ls-card .btn`, et l'ordre trancherait. */
```

## C84 — Couleur AMBRE volontairement distincte de l'en-tête vert (sinon les deux bandeaux se confondent

```
  /* Couleur AMBRE volontairement distincte de l'en-tête vert (sinon les deux bandeaux se confondent
     et on rate l'alerte) : halo + quelques pulsations pour attirer l'œil. */
  /* ⚠ 520 N'EST PAS UNE QUATRIÈME LARGEUR DE FENÊTRE (audit 9b) : une banderole n'est pas une
     fenêtre — elle ne se ferme pas pour révéler ce qu'il y a derrière, elle s'efface seule au bout
     de dix secondes. Sa largeur mesure une PHRASE (titre + nom de fiche sur deux lignes), pas une
     surface modale ; la rattacher à un gabarit couperait le nom d'une aide en deux.
     ET ELLE N'APPARAÎT JAMAIS PENDANT QU'ON REGARDE LA SESSION (audit 9d, vérifié) : `onTimerFired`
     ne l'appelle QUE dans la branche `!activeVisible` — session hors de vue, autre fiche, ou app
     en arrière-plan. Sous les yeux, l'alarme reste sur place (carte clignotée + segment ambre du
     quai, acquittement par l'action). Le noyau §2 vise ce qui SURGIT sur l'écran de soin : ici
     l'alerte est ROUTÉE vers quelqu'un qui regarde ailleurs, ce qui est l'exigence inverse. */
```

## C85 — LE MENU DEVIENT UNE BOTTOM SHEET (poignée, voile, rangées 48px, au pouce). La poignée vit

```
  /* LE MENU DEVIENT UNE BOTTOM SHEET (poignée, voile, rangées 48px, au pouce). La poignée vit
     dans l'en-tête collant (.catmenu-head) ; touch-action:none sur le voile : un glissement sur
     le fond assombri ne doit jamais faire défiler la page derrière.
     ⚠ LE PALIER EST PASSÉ DE LA FEUILLE AU JS (v5.11.0), et la règle a donc UNE seule écriture.
     Elle vivait dans `@media (max-width:779.98px)`, ce qui liait la FORME du menu à la seule
     largeur ; or l'atelier d'import en a besoin en feuille À TOUTE LARGEUR. La raison est
     MESURÉE, et ce n'est pas celle qu'on croit : un menu `absolute` se pose par rapport au
     premier ancêtre POSITIONNÉ, et une rangée d'atelier n'en a aucun — à 1194×834, ouvert sur la
     dernière rangée, il atterrissait à 494→834, soit une CENTAINE de pixels sous le bas de la
     liste (394), détaché de la pastille qui l'ouvre. Positionner la rangée ne répare pas
     davantage (même géométrie mesurée) et exposerait au contraire le menu à l'`overflow` du
     corps de fenêtre. La feuille, elle, se pose toujours au même endroit et ne dépend d'aucun
     ancêtre — c'est déjà ce que le téléphone recevait.
     ⚠ ET LA GÉOMÉTRIE NE PROUVE PAS LA VISIBILITÉ : `getBoundingClientRect` ignore l'écrêtage
     d'un ancêtre — mesuré, un témoin géométrique restait VERT sur le défaut réintroduit. Le seul
     témoin qui discrimine est le test de TOUCHER (`elementFromPoint`), et c'est lui que porte la
     sonde. Leçon v4.31.1, repayée ici.
     `openPickMenu` pose donc `.sheet` quand l'appelant l'exige OU sous 780 px : même seuil, même
     rendu, une définition. Ce que ça change, et c'est dit : le menu ne se reforme plus si l'on
     PIVOTE l'appareil menu ouvert — il garde la forme qu'il avait à l'ouverture, ce qui est sans
     conséquence pour une surface transitoire. */
```

## C86 — Aperçu d'algorithme de l'éditeur étroit (< 1000 px) — ENTREBÂILLÉ, JAMAIS FERMÉ (demande

```
  /* Aperçu d'algorithme de l'éditeur étroit (< 1000 px) — ENTREBÂILLÉ, JAMAIS FERMÉ (demande
     utilisateur : « ce serait bien qu'il ne soit pas totalement replié, pour qu'on puisse voir
     qu'il existe — un néophyte ne verra pas qu'il existe »). L'argument est juste et il est
     doctrinal : un titre replié dit qu'une chose EXISTE, il ne dit pas CE QU'ELLE EST, et un
     schéma est précisément ce qui ne se raconte pas. On en montre donc la tête — assez pour
     reconnaître un organigramme, pas assez pour repousser la première étape à écrire.
     PAS UN `<details>` : un `details` fermé ne rend RIEN de son contenu, et rendre visible un
     enfant d'un `details` fermé n'est pas fiable d'un moteur à l'autre (le contenu vit dans un
     slot du shadow tree). C'est donc un conteneur ordinaire + un vrai bouton, et l'entrebâillement
     est un simple `max-height`. Aucune TRANSITION dessus : `max-height` est une propriété de MISE
     EN PAGE, l'animer est interdit ici (check-anim) — et rien dans ce fichier n'animerait un
     changement de hauteur de toute façon.
     Le fondu du bas n'est pas un ornement : c'est LUI qui dit « ça continue ». Il fond vers
     `--paper`, le fond du canevas, parce que c'est le DESSIN qu'on estompe, pas la page. */
```

## C87 — ⚠ SUR ÉCRAN TACTILE, LE PLAN INLINE NE DÉFILE PLUS VERTICALEMENT EN INTERNE (v5.10.5,

```
  /* ⚠ SUR ÉCRAN TACTILE, LE PLAN INLINE NE DÉFILE PLUS VERTICALEMENT EN INTERNE (v5.10.5,
     signalé à l'usage : « ok de défiler de droite à gauche, mais pas de haut en bas à l'intérieur
     du plan — problématique en navigation iPhone en inline ; en plein écran, le problème ne se
     pose plus »). Un défileur interne BORNÉ en hauteur avale le pan VERTICAL : au milieu d'une
     page qu'on parcourt au pouce, le geste de page se fait capturer par le plan. Le défilement
     HORIZONTAL n'a pas ce défaut — un conteneur qui ne déborde qu'en X laisse le pan vertical
     remonter à la page (comportement natif) — il est donc CONSERVÉ. En inline tactile, le plan
     prend sa hauteur entière et c'est la page qui défile ; le PLEIN ÉCRAN garde son défileur
     (c'est sa surface à lui, il n'y a pas de page dessous à atteindre). Portée : `main` — les
     feuilles plein écran vivent hors de lui.
     ⚠ ET L'AXE VERTICAL EST FERMÉ, PAS SEULEMENT VIDÉ (`overflow-y:clip`, retour utilisateur
     après le premier correctif : « j'ai quand même un retour de scroll — effet élastique — en
     vertical »). `max-height:none` supprimait le DÉBORDEMENT, pas la DÉFILABILITÉ : un axe
     `auto` rebondit sur iOS même sans un pixel à défiler. `clip` retire l'axe lui-même — le pan
     vertical remonte à la page sans élastique, l'horizontal défile comme avant. */
  /* La règle vaut pour les DEUX défileurs inline du plan : `.flow-scroll` (organigramme) ET
     `.sv-scroll` (tableau statique façon SFAR — c'est LUI que le signalement visait : « mode
     plan de page SFAR », défilement horizontal des colonnes de branches).
     ⚠ ELLE VIT DANS LE BLOC TACTILE DE FIN DE FEUILLE, PAS ICI (v5.10.5, CI rouge le jour même) :
     `check-type` localise la liste « 16 px tactile » sur la PREMIÈRE occurrence du littéral média
     « hover:none et pointer:coarse, accolade collée » — un second bloc identique posé plus haut
     dans la feuille l'a AVEUGLÉ (les six champs de la liste déclarés « absents ») ; et il scanne
     le texte BRUT, commentaires compris — écrire le littéral dans ce commentaire suffisait à le
     re-casser, c'est arrivé dans la même heure. Le bloc de fin de feuille est la source de vérité
     unique du média tactile : on s'y range, et on ne le cite pas au motif près. */
  /* CODE QR — taille en px et non en %, parce qu'un QR se scanne : trop petit, le lecteur cale.
     240 px (v5.16.0, demandé à l'usage : « lisibles plus facilement / de plus loin ») met chaque
     module au-dessus de 5 px dès la version 10 — le gain se prend sur la DISTANCE de scan, pas
     sur un seuil de lisibilité qui était déjà tenu à 200. Les contextes serrés gardent leur
     plafond propre (cf. .sh-qr et le bloc #shareBody plus bas).
     Encre et fond fixes dans les deux thèmes (cf. --qr-ink), bordure pour détacher la zone de
     silence d'un fond clair — sans elle le blanc du QR se fond dans la surface et le lecteur
     perd le repère. */
```

## C88 — La porte elle-même : pointillé (grammaire « créer »), pleine largeur, ≥ 44 px.

```
  /* La porte elle-même : pointillé (grammaire « créer »), pleine largeur, ≥ 44 px. */
  /* LA PORTE RESTE À PORTÉE, ET ELLE NE DEVIENT PAS UNE ZONE FIXE (signalé à l'usage : « le
     bouton + est peu visible et il faut beaucoup descendre — et s'il était flottant ? »).
     La question posée était la bonne : SPEC §5 dit « une seule zone fixe, et en HAUT », et pour
     les ÉDITEURS elle dit en propre « AUCUN pied d'éditeur » — un bouton `fixed` en bas de
     l'écran est exactement ce que cette ligne interdit, clavier mobile compris. La réponse est
     donc `sticky`, pas `fixed` : la porte reste le DERNIER ENFANT de son fieldset, elle se colle
     au bas de l'écran TANT QU'ON EST DANS « Prise en charge » et se décroche d'elle-même à la
     fin de la section — le bornage est natif, comme celui des bandes-questions du mode statique
     et du fil d'ancêtres. Elle ne prend AUCUNE hauteur de plus (elle était déjà dans le flux),
     rien ne se décale, et aucune couche fixe ne s'ajoute au chrome.
     VISIBILITÉ : le pointillé reste (grammaire « créer », inchangée), mais il lui fallait un fond
     PLEIN et une élévation — collée, elle passe au-dessus du contenu, et un bouton transparent
     s'y serait lu par-dessus le texte d'un bloc. */
  /* LA PORTE SE VOIT (signalé à l'usage : « peu identifiable, le blanc ne ressort pas bien du
     reste et on identifie peu qu'il est sticky »). Trois changements, tous dans la grammaire :
     le POINTILLÉ reste (c'est la grammaire de « créer », inchangée depuis la v4.3.0) mais sur un
     fond TONAL `--primary-soft` au lieu du blanc — le blanc était la couleur de toutes les cartes
     autour d'elle, donc la seule chose qui la distinguait était son trait ; le « ＋ » entre dans
     une PASTILLE ronde, qui est ce qu'on reconnaît avant d'avoir lu ; et un filet haut la détache
     du flux, de sorte qu'elle se lise comme une COUCHE POSÉE — c'est ce qui rend son
     comportement collant lisible sans qu'on ait à le deviner.
     ELLE NE DEVIENT PAS L'ACTION PRIMAIRE pour autant : l'unique bouton REMPLI de l'écran reste
     « ▶ Essayer » (règle « un seul bouton rempli par écran », v4.0.3). Tonal, pas plein. */
```

## C89 — LA PROFONDEUR SANS L'EXCÈS (v4.78.0, question utilisateur : « peut-être qu'il n'apparaît pas

```
  /* LA PROFONDEUR SANS L'EXCÈS (v4.78.0, question utilisateur : « peut-être qu'il n'apparaît pas
     assez au-dessus du reste du contenu ? comment lui ajouter de la profondeur sans que ça n'en
     fasse trop ? »). Trois choses la donnent, et une seule est une ombre :
       · L'ÉLÉVATION passe au niveau 3, `--shadow-lg`. Ce n'est pas un réglage arbitraire : la
         v4.57.0 a écrit trois niveaux, et le troisième est celui des OVERLAYS — or une porte
         collante EST une couche posée sur le contenu, pas une carte du flux.
       · UN VOILE AU-DESSUS d'elle : 22 px de dégradé vers le fond de page, si bien que le contenu
         s'ESTOMPE en passant dessous au lieu de s'y couper net. C'est ce voile, plus que l'ombre,
         qui dit « il y a quelque chose derrière » — et c'est aussi ce qui rend son comportement
         collant lisible sans qu'on ait à le deviner.
       · RIEN D'AUTRE. Pas de translation, pas de grossissement, pas de second contour : ce qui
         donne la profondeur ici est la CONTINUITÉ du contenu qui disparaît dessous, et une porte
         qui bougerait en plus attirerait l'œil pendant qu'on écrit.
     Le voile est PEINT, jamais en mise en page : `position:absolute` sur un `::before`, donc aucune
     hauteur prise au flux et aucun décalage possible (check-anim n'a rien à y voir, rien n'est
     animé). `pointer-events:none` : il couvre du texte, il ne doit rien intercepter. */
  /* L'OMBRE SUIT LA FORME — LE VOILE, NON (v4.78.0, signalé à l'usage : « l'effet d'ombre blanc est
     très mal fait et probablement à l'envers ou pas adapté à un bouton à bords arrondis »). Les
     deux reproches sont justes. Un dégradé posé en `::before` est un RECTANGLE : ses angles ne
     suivent pas le rayon du bouton, et sur une carte blanche il se lit comme une bande grise à
     bords vifs — pas comme une profondeur. Et il montait vers `--bg`, la couleur du FOND DE PAGE,
     donc il éclaircissait au lieu d'assombrir : à l'envers, littéralement.
     Le bon outil pour un objet arrondi qui flotte est SA PROPRE OMBRE, qui épouse le rayon par
     construction — et pour une barre collée EN BAS elle doit se répandre VERS LE HAUT, du côté d'où
     vient le contenu. D'où `--shadow-up`, un token (les valeurs d'ombre sont tokenisées depuis la
     v4.37.0, jamais écrites en clair dans une règle) : mêmes encres et mêmes alphas que
     `--shadow-lg`, décalage inversé. Rien d'autre — pas de voile, pas de contour. */
```

## C90 — MICRO-ANIMATIONS DU PASSAGE EN MODE DÉPLACEMENT (lot 2, v4.75.0 — proposition utilisateur :

```
  /* MICRO-ANIMATIONS DU PASSAGE EN MODE DÉPLACEMENT (lot 2, v4.75.0 — proposition utilisateur :
     « je trouve le passage entre les deux modes brutal ; fondre l'apparition des blocs poser ici,
     et peut-être faire se balancer un tout petit peu le bloc sélectionné »). Les deux idées sont
     retenues, la seconde avec une borne : UNE oscillation AMORTIE, jamais une boucle. Le mouvement
     continu est réservé à l'alarme dans cette app (ECAM) ; un objet qui se balance indéfiniment
     finirait par se lire comme une alerte, et ce n'en est pas une — prendre un objet n'est ni une
     erreur ni un danger. Troisième mouvement ajouté au passage, à coût nul : le bandeau collant
     entre par le haut, dans le sens où il arrive.
     La CASCADE des interstices est ce qui explique « ce qui vient d'apparaître » : 22 ms par rang,
     bornée à six (au-delà, un décalage n'informe plus, il fait attendre).
     `transform` et `opacity` SEULEMENT (check-anim), et tout est inerte sous reduced-motion. */
```

## C91 — LA POIGNÉE DU BLOC VIT EN TÊTE, À DROITE DU TITRE (signalé à l'usage : « le bouton ⠿ des

```
  /* LA POIGNÉE DU BLOC VIT EN TÊTE, À DROITE DU TITRE (signalé à l'usage : « le bouton ⠿ des
     blocs est probablement mal placé — ne devrait-il pas être en haut à droite ? »). Elle était
     en pied, au CONTACT de « Supprimer le bloc » : c'est précisément ce que la v4.68.0 avait
     corrigé pour les étapes (« un geste destructeur ne se met jamais au contact d'un autre
     bouton, sinon le pouce corrige et supprime du même geste ») — la règle n'avait pas été
     appliquée à l'échelon du bloc. Elle rejoint donc l'anatomie déjà retenue pour l'étape :
     poignée à DROITE de la ligne qu'elle déplace, visible au repos, en encre douce. */
  /* ⚠ VINGT-DEUXIÈME DÉFAUT DE RANGÉE FLEX — LA PHASE POUSSAIT LA POIGNÉE HORS DE LA CARTE
     (v5.6, trouvé au balayage). La rangée était en `nowrap` avec DEUX objets incompressibles (la
     pastille, le sélecteur de phase à 191 px) et un seul objet capable de céder — le champ TITRE,
     qui tombait à 26 px pendant que la poignée ⠿ sortait de 35 px du cadre. C'est exactement le
     défaut de la v4.74.0 (bandeau de déplacement) et de la v4.55.3 (croix du panneau) : quand tout
     est incompressible sauf un, c'est cet un-là qui paie, et le débordement part par le côté
     opposé. On ENROULE, on ne tronque jamais : à l'étroit, la phase et la poignée descendent d'une
     ligne et le titre garde sa largeur ; dès qu'il y a la place, tout revient sur une rangée. */
```

## C92 — « Maintenir pour réinitialiser » un minuteur : jauge = fond qui se remplit pendant l'appui

```
  /* « Maintenir pour réinitialiser » un minuteur : jauge = fond qui se remplit pendant l'appui
     (le texte reste lisible au-dessus). Libellé sur 2 lignes -> indice « maintenir » visible. */
  /* « ✓ Vu » : registre de l'ÉTAT acquitté, jamais du danger — l'ambre appartient à l'alarme qui
     sonne encore, et le vert dirait « c'est fait » alors que rien n'a été fait. Encre neutre,
     contour, comme les autres commandes de la carte. */
  /* ⚠ A9 — LE BOUTON NE PREND JAMAIS UNE LIGNE DE PLUS (mesuré d'abord à 214 → 264 px). Un
     minuteur échoit SANS que personne n'ait rien commandé : si sa carte grandit à cet instant,
     tout ce qui la suit se déplace sous les doigts. La rangée de commandes du volet ENROULE, et
     dans une colonne de 136 px les deux boutons sont DÉJÀ l'un sous l'autre — un troisième y
     ajoutait mécaniquement une troisième ligne, quelle que soit sa largeur.
     « ✓ VU » SE SERT DONC DANS LA PART DE LA REMISE À ZÉRO : il vaut 52 px, la remise à zéro cède
     exactement autant (120 − 52 − 6 d'écart), et les deux occupent ensemble la place que la
     remise à zéro occupait seule. Les seuils d'enroulement des deux états coïncident alors AU
     PIXEL — sans cette soustraction, il existerait une bande de largeurs où la carte échue serait
     plus COURTE que la carte nominale, ce qui est le même défaut à l'envers. Il se glisse ENTRE le
     bouton principal et la remise à zéro : placé en tête, c'est lui qui aurait chassé le bouton
     principal à la ligne suivante. Mesuré : Δ = 0 px à 136, 200, 250 et 320 px de colonne. */
  /* ⚠ VINGT-ET-UNIÈME PIÈGE DE CASCADE, rencontré ici même : `.rt-dock .tm-btn` vaut (0,2,0) et
     pose `flex:1 1 120px` — écrit en (0,1,0), `.tm-ack` perdait, le bouton reprenait la base des
     autres et la ligne de plus revenait. On porte donc la règle à (0,2,0) ET (0,3,0), jamais par
     l'ordre de déclaration : pour une GÉOMÉTRIE, on ne dépend pas de la position dans la feuille. */
```

## C93 — ⚠ DANS LE RAIL, LA RANGÉE NE FAIT QUE 148 px ET NE S'ENROULE PAS (v5.6, signalé à l'usage :

```
  /* ⚠ DANS LE RAIL, LA RANGÉE NE FAIT QUE 148 px ET NE S'ENROULE PAS (v5.6, signalé à l'usage :
     « aussi le bouton Relancer en mode desktop »). « ✓ Vu » y prenait 52 px et laissait 90 au
     bouton principal pour 78 de contenu — six pixels de marge, c'est-à-dire un libellé coupé dès
     que la fonte du système est un peu plus large que celle du harnais. On rend huit pixels : le
     bouton d'acquittement garde son MOT et ses 44 px de cible (33 px de texte y tiennent), et le
     principal passe à 98 px, soit 14 de marge. Mesuré aux trois paliers du rail. */
  /* ⚠ DANS LE RAIL, LA RANGÉE FAIT 140 px ET « RELANCER » Y TIENT AU PIXEL PRÈS (v5.6, signalé à
     l'usage : « aussi le bouton Relancer en mode desktop »). Mesuré : bouton 90 px pour 78 px de
     contenu et 12 de rembourrage — ZÉRO marge, donc un libellé coupé dès qu'une fonte rend deux
     pixels plus large. Rétrécir « ✓ Vu » ne rend que quatre pixels : dans une colonne de 301 px,
     la valeur du minuteur prend déjà la moitié, et DEUX commandes n'y tiennent pas côte à côte.
     On ENROULE donc tant que l'acquittement est là — le principal prend sa ligne, entière — et
     c'est cohérent avec la décision antérieure du rail : une carte échue OUVRE ses commandes,
     parce que celles d'une alarme doivent être sous la main quand elle sonne. Le coût (une ligne)
     est TRANSITOIRE : il disparaît au premier « ✓ Vu ». */
```

## C94 — Section de bloc : en-tête = LIGNE D'ÉTAT toujours visible (n°, titre, compteur, chevron),

```
  /* Section de bloc : en-tête = LIGNE D'ÉTAT toujours visible (n°, titre, compteur, chevron),
     corps repliable. Pastille : bleu = position courante, vert ✓ = bloc complet, neutre sinon —
     jamais d'ambre/rouge (registres d'alerte) ; la décision garde sa carte ambrée (comme .nav-wrap.dec). */
  /* LA CARTE DU PARCOURS EST UNE SURFACE (v4.74.2, signalé à l'usage : « pourquoi les étapes de
     blocs sont de la même couleur que le fond de page et pas en fond blanc comme les autres
     blocs ? »). Ce n'était pas une décision : `.ov-block` n'avait AUCUN `background`, donc le fond
     de page, quand `.conf-block`, `.local`, `.forget-strip` et les cartes de l'éditeur sont tous
     en `--surface`. Rien dans AGENTS.md ne justifiait l'exception, et le précédent existe en sens
     inverse — la v4.59.0 a mis l'Échelle sur une surface parce qu'elle était « la seule zone de la
     vue lecture à ne pas être une surface, ses filets se lisant comme des restes de trait ». Le
     même argument vaut ici, et plus fort depuis que le sombre est quasi noir (v4.71.0, puis #0a0a0c
     en v5.0.0 — sur un fond aussi sombre une
     ombre ne dit plus rien, c'est la SURFACE qui monte et le FILET qui borde). C'est la colonne
     d'ACTION : elle mérite le niveau 2, pas le fond nu.
     Les registres ne bougent pas : `.dec` garde sa teinte ambre, une étape `⚠`/`△` sa boîte. */
  /* ══ LA CARTE DE TRAVAIL, D'APRÈS LA MAQUETTE (v5.6) ══════════════════════════════════════
     Le liseré gauche de 4 px et le cadre d'accent bleu du bloc courant sont RETIRÉS : la carte
     est une SURFACE DE TRAVAIL posée sur l'ambiance — filet fin, rayon 14, rembourrage 18, et la
     SEULE ombre du système. C'est la matière qui la distingue, plus un trait de couleur.
     ⚠ A12 EST TENUE AUTREMENT, ET MIEUX : la position se lit à ce que la carte est le SEUL bloc
     OUVERT, qu'elle est en tête de journal, et qu'elle porte `aria-current="step"` (le seul des
     trois canaux qu'un lecteur d'écran voit). Le bleu ne servait qu'à redire ce que la structure
     disait déjà — et il mettait une quatrième couleur dans un écran qui n'en veut qu'une. */
```

## C95 — Un bloc de DÉCISION garde son ambre même quand il est le bloc courant (v4.24.0, décision

```
  /* Un bloc de DÉCISION garde son ambre même quand il est le bloc courant (v4.24.0, décision
     utilisateur). Avant, `.cur` était déclarée APRÈS `.dec` et repeignait la bordure en bleu : le
     même bloc changeait de couleur selon qu'on venait d'y arriver ou qu'on y remontait — le
     REGISTRE (une décision est toujours une décision) était masqué par un ÉTAT transitoire, ce
     qu'ECAM interdit.
     ⚠ CE COMMENTAIRE DISAIT « la POSITION reste portée par la pilule “VOUS ÊTES ICI”
     (`.ov-here`) » — ce n'est plus vrai depuis A12 (v5.6), qui a PURGÉ cette pilule ; zéro
     émission dans le fichier, cf. le bloc qui l'explique plus bas. Le principe, lui, tient : un
     canal par signification. La position est désormais portée par la carte elle-même — seul bloc
     OUVERT, en tête de journal, bordure d'accent, `aria-current="step"` — et le mot « ici » ne
     vit plus que là où il sert à SE RETROUVER parmi d'autres (rail Structure, « ⤢ Tout voir »,
     étiquette de retour du dock).
     LA LEÇON EST GÉNÉRALE, et c'est pour elle que ce paragraphe existe : dans ce fichier les
     commentaires SONT la documentation de conception, donc un commentaire qui décrit un élément
     supprimé finira par le faire RÉINTRODUIRE — on lira « la position est portée par `.ov-here` »,
     on constatera son absence, et on la remettra en croyant réparer une régression. **Purger une
     classe (règle 14), c'est aussi chercher les commentaires qui la citent**, pas seulement les
     règles et les émissions. */
```

## C96 — ⚠ UN BLOC COMPLET L'EST SUR TOUTE SA BORDURE (v5.0.9, signalé à l'usage : « bloc d'étape où

```
  /* ⚠ UN BLOC COMPLET L'EST SUR TOUTE SA BORDURE (v5.0.9, signalé à l'usage : « bloc d'étape où
     on a coché toutes les étapes : uniquement le bord gauche devient vert et pas le reste »).
     `.done` n'écrivait que `border-left-color`, si bien qu'un bloc courant ET complet portait un
     cadre BLEU avec une seule arête verte — deux registres sur un même trait, exactement ce que
     la v4.24.0 a corrigé en sens inverse pour la décision. Et c'est la configuration NOMINALE :
     on finit de cocher le bloc où l'on est. La carte REPLIÉE le faisait déjà (`.closed.done`) ;
     ouverte, elle ne le faisait pas — un bloc changeait donc de registre selon qu'il était plié.
     Le cadre entier passe au registre CONFIRMATION ; la POSITION reste portée sans ambiguïté par
     la pilule « VOUS ÊTES ICI », un canal par signification (v4.24.0).
     PAS DE FOND TEINTÉ ici, contrairement à `.closed.done` : la carte ouverte est la colonne
     d'ACTION et porte des étapes ⚠/△ dont la boîte teintée doit rester lisible sur `--surface` ;
     repliée, elle n'est plus qu'un statut d'une ligne et l'aplat y dit « c'est fait ».
     UNE DÉCISION EST EXCLUE : son registre ambre prime sur l'état (v4.24.0, même raisonnement
     qu'au-dessus) — elle garde son cadre et ne prend que son liseré vert, comme avant. */
```

## C97 — P2-2 (audit design v4.56) : UNE seule ligne d'état — pilule « Vous êtes ici » à gauche,

```
  /* P2-2 (audit design v4.56) : UNE seule ligne d'état — pilule « Vous êtes ici » à gauche,
     Lecteur/Vérifier à droite (−52 px par bloc actif ; la rangée vide flottait en plein cœur de
     la zone balayée par l'œil). */
  /* LA LIGNE D'ÉTAT S'ENROULE, ET SON DÉBORDEMENT NE PART JAMAIS À GAUCHE (v4.73.1, signalé à
     l'usage en GRANDE POLICE : « VOUS ÊTES ICI » était coupée par le bord GAUCHE de la carte).
     Deux causes cumulées, et la seconde est le piège : (1) la rangée ne s'enroulait PAS, alors que
     ses trois objets — pilule + Lecteur + Vérifier — sont tous en `nowrap` et ne peuvent donc pas
     se rétrécir ; (2) `justify-content:flex-end` fait déborder par le côté OPPOSÉ, c'est-à-dire
     par le DÉBUT : le premier objet sortait de la carte au lieu du dernier. Un débordement qui
     part vers l'extérieur de son conteneur ne peut même pas être rattrapé par un défilement.
     On enroule (`wrap`), on aligne au DÉBUT, et c'est le premier BOUTON qui porte le
     `margin-left:auto` — l'aspect est identique tant que tout tient sur une ligne (pilule à
     gauche, boutons à droite), et quand les boutons passent à la ligne l'auto les garde à droite.
     La pilule, elle, reste à sa place : c'est un état, il ne se déplace pas. */
```

## C98 — Le TITRE du bloc prend le cran 21 — c'est l'objet qu'on lit en premier dans la carte, et le

```
  /* Le TITRE du bloc prend le cran 21 — c'est l'objet qu'on lit en premier dans la carte, et le
     grand corps appartient à l'ACTE. Il vit sur sa propre ligne, sous l'étiquette. */
  /* A6 REPRISE JUSQU'AU BOUT — LE PLUS GRAND CORPS DE L'ÉCRAN DE CRISE APPARTIENT À L'ACTE, PAS
     À SON LIBELLÉ (audit externe v5.10.0). Relevé des corps peints, session vive, 390 px : titre
     de bloc 21/700 · étape vitale 17,5/800 · étape ordinaire 15/600 · CADENCE 11/600. La réforme
     v5.6 s'était donné pour but de réparer l'inversion « l'étape qui sauve plafonnait à 15,5 px
     quand le chrono avait droit à 34 » ; elle a relevé le LIBELLÉ de l'étape et laissé le plus
     grand corps à « Reconnaissance & alerte », qui est un repère de navigation, et le plus petit
     à « 30:2 — sans délai », qui gouverne le geste. Deux crans échangés (voir aussi `.stp-r`) :
     le titre descend à --t-step, l'étape vitale garde --t-step ET sa graisse 800, son registre,
     sa case et son ⚠ — elle reste la ligne dominante, et le repère cesse de lui disputer l'œil.
     ⚠ BÉNÉFICE SECOND, MESURÉ : à 320 px × 130 % le titre à 21 px ne tenait plus dans sa colonne
     et se coupait EN PLEIN MOT (« Reconnaissa / nce & alerte »). `overflow-wrap:break-word` est
     le bon choix et n'était pas en cause — c'est un corps FIXE dans une colonne qui rétrécit qui
     l'était. Ne pas « corriger » la propriété de coupure : elle est le filet, pas la cause. */
```

## C99 — ----- Journal de parcours (v4.9.0) : instances repliées = lignes d'état, suite, réponse -----

```
  /* ----- Journal de parcours (v4.9.0) : instances repliées = lignes d'état, suite, réponse ----- */
  /* Instance COMPLÈTE repliée = LIGNE ECAM verte (relisible d'un tap) ; décision repliée garde
     sa carte ambrée + sa réponse en toutes lettres (.ov-ans) — la couleur n'est jamais seule. */
  /* ⚠ REPLIÉE, LA CARTE EST UN STATUT D'UNE LIGNE — ET SA LIGNE EST CENTRÉE (v5.6, signalé à
     l'usage : « quand le bloc est enroulé, le numéro et le titre se déplacent mais ne sont pas
     centrés verticalement »). L'en-tête OUVERT est fait pour deux rangées — l'étiquette et le
     compte au-dessus, le grand titre en dessous (`.ov-t{flex:1 1 100%}`, aligné sur les BASELINES) :
     c'est juste quand la carte est ouverte, et faux quand elle se replie, où la même mise en page
     donnait une boîte de 73 px avec le numéro 23 px au-dessus du milieu et le titre 7 en dessous.
     Repliée, la rangée ne porte plus qu'une ligne : tout y tient côte à côte, aligné sur le MILIEU,
     et le titre prend la taille du texte courant puis s'ellipse — il revient en entier au dépliage,
     qui est à un tap. */
  /* ⚠ ET LA RANGÉE EST CENTRÉE DANS LA CARTE, PAS SEULEMENT EN ELLE-MÊME (v5.6, second
     signalement : « il est toujours plus bas que le centre de la carte repliée »). L'en-tête porte
     `padding:18px 18px 0` — juste quand la carte est OUVERTE, puisque le corps suit en dessous ;
     replié, l'en-tête EST la carte, et ces 18 px de haut contre 0 en bas poussaient le texte 9 px
     sous l'axe (31 px au-dessus, 13 en dessous, mesurés). On symétrise, et le retrait à gauche
     reste celui de la carte ouverte (6 + les 12 de la rangée = 18). */
```

## C100 — ----- Fil condensé (v4.16.0) : les passages anciens complets deviennent des CHIPS -----

```
  /* ----- Fil condensé (v4.16.0) : les passages anciens complets deviennent des CHIPS ----- */
  /* Rangée de chips = un TRONÇON chronologique du fil (l'ordre est préservé — une carte ou une
     ligne d'état coupe la rangée) ; chip = bouton natif ≥ 44 px, tap = déplier sur place.
     Étape faite = registre CONFIRMATION (fond --done-bg + ✓ vert) ; décision répondue = registre
     ATTENTION (bordure --verify-bd) avec la réponse en toutes lettres — la couleur jamais seule. */
  /* Ligne-bilan ECL (v4.16.4) : une rangée de + de 4 chips repliée en un statut synthétique
     vert — même grammaire que la ligne d'état d'une instance complète, pleine largeur. */
  /* LA LIGNE-BILAN (v5.6, maquette) : un DÉCLENCHEUR de texte, pas une carte — ce qui est
     derrière est déjà fait, il n'a rien à réclamer. La carte, c'est le DÉPLIÉ. */
  /* ⚠ EN CRISE, LE PRÉAMBULE NE PAIE QUE CE QU'IL MONTRE (signalé à l'usage : « réduis encore
     l'espace entre le “ne pas oublier”, l'en-tête et la ligne-bilan »). Mesuré à 390 px, session
     vive : 106 px séparaient le bas de la capsule du haut de la carte, dont **24 px de pur
     espacement** — 8 au-dessus du chapeau, 6 sous lui, 2 + 8 autour de la ligne-bilan. Aucun de
     ces pixels ne porte d'information. Ils tombent à 4 chacun (12 px rendus, ~11 % du préambule).
     ⚠ CE QUI NE CÈDE PAS, ET C'EST LA MOITIÉ DE LA RÈGLE : les deux objets sont TAPABLES — le
     chapeau se déplie, la ligne-bilan aussi. Leurs BOÎTES gardent donc leurs 40 et 44 px (A8,
     et `.ov-runline` a son `min-height` juste en dessous) ; seule la respiration ENTRE eux cède.
     Chercher davantage reviendrait à retirer du contenu, ce que la demande exclut. */
```

## C101 — ----- v4.12.0 : ÉCHELLE ECAM (mode compact) — une ligne par bloc, renvois abrégés. -----

```
  /* ----- v4.12.0 : ÉCHELLE ECAM (mode compact) — une ligne par bloc, renvois abrégés. ----- */
  /* UNE DÉCISION À BEAUCOUP D'OPTIONS SORTAIT DU PLAN (v4.55.3, retour d'usage). Les renvois
     abrégés (`FIBRIL→2 ASYSTO→3 …`) sont en `flex:none` et `nowrap` : leur largeur croît avec le
     nombre de branches, sans borne. Mesuré : débordement dès **4 options à 320 px**, 5 à 390, 6 à
     430, et jusqu'à 280 px hors du cadre à 8 options — la ligne devenait illisible, et le titre de
     la décision était écrasé à 0 px de large bien avant.
     On enroule plutôt que de tronquer : dans un PLAN, une branche cachée est une branche qu'on ne
     saura pas prendre. C'est la différence avec le quai, où l'on abrège et où l'on annonce « +n » —
     ici la place existe, verticalement. */
  /* LA RANGÉE DU PARCOURS INERTE (v5.0.0, maquette) : pastille RONDE numérotée à gauche — la
     même grammaire que les pastilles de bloc de la lecture —, titre au centre, renvois en mono à
     droite. Pas de liseré coloré sur une rangée ordinaire : l'état vit dans la PASTILLE, et la
     position dans le fond de la rangée courante. Un liseré de plus ferait deux canaux pour un
     seul état, et hacherait la colonne. */
  /* ══ LA RANGÉE DEVIENT UNE CARTE (v5.6, maquette — « mixte entre la maquette et l'existant »)
     La maquette pose chaque bloc dans une carte blanche bordée, séparée par 6 px, et met le
     numéro DANS le titre (« 7 · Reprise du massage »). Ce qui est repris : la CARTE (une pile de
     lignes à filet se lit comme un tableau, une pile de cartes se compte d'un coup d'œil), les
     renvois en `--act`, les comptes en mono `--ink-3`, et le pointillé du hors-chemin.
     CE QUI NE L'EST PAS, et c'est le « mixte » : le MARQUEUR reste une pastille. C'est la
     doctrine de la colonne depuis la v4.23.0 — l'état n'y vit que là, et le losange d'une
     décision porte la même grammaire. Un numéro fondu dans le titre rendrait l'état au TEXTE,
     c'est-à-dire à la couleur seule (règle 8), et ferait diverger cette colonne des pastilles de
     la carte de travail. La maquette n'inline pas non plus les items du bloc courant ici : au
     cockpit la carte est juste à côté, ce serait la recopier. */
```

## C102 — ⚠ LE LOSANGE A EXACTEMENT LE STYLE DE LA PASTILLE — même filet, même fond, mêmes états ;

```
  /* ⚠ LE LOSANGE A EXACTEMENT LE STYLE DE LA PASTILLE — même filet, même fond, mêmes états ;
     seule la FORME change, et elle porte le numéro. Le carré tourné vit dans un `::before` À
     L'INTÉRIEUR de la boîte : un élément de 26 px tourné à 45° en ferait 37 de diagonale et serait
     rogné par la colonne (leçon v5.0.0). Le chiffre, lui, n'est PAS tourné — il se lit droit. */
  /* ⚠ `z-index:-1` SANS CONTEXTE D'EMPILEMENT PASSE SOUS LE FOND DU PARENT (v5.6, signalé à
     l'usage : « dans le parcours inerte les chiffres des blocs conditionnels n'ont pas de contour
     du tout »). `.pl-line` est `position:static` et porte un fond BLANC : le losange, posé en
     `z-index:-1`, se peignait donc DERRIÈRE ce fond — invisible, et la décision se retrouvait
     sans marqueur là où tous ses voisins en ont un. `isolation:isolate` fait de la pastille son
     propre contexte : le losange remonte juste au-dessus d'elle et reste sous son chiffre.
     C'est la même famille que les dix-neuf pièges de cascade du dossier — une valeur négative ne
     dit pas « derrière mon frère », elle dit « derrière tout ce qui n'est pas isolé ». */
```

## C103 — ⚠ AVANT LE SOIN, LE PARCOURS SE RESSERRE (v5.6, signalé à l'usage : « le parcours inerte est

```
  /* ⚠ AVANT LE SOIN, LE PARCOURS SE RESSERRE (v5.6, signalé à l'usage : « le parcours inerte est
     trop long — réduis un peu la taille des étapes sans perdre la lisibilité ni d'informations »).
     Rien n'est retiré : ce sont les MARGES qui cèdent, jamais le contenu ni le corps du texte.
     · rangée 44 → 38 px, rembourrage 6/12 → 4/10, écart de grille 6 → 4 ;
     · la pastille passe de 26 à 24 px — elle reste plus grande que son chiffre (11 px).
     POURQUOI SEULEMENT AVANT : 44 px est le plancher de la CRISE, et il ne se négocie pas une fois
     le soin démarré. Ici il n'y a pas de crise — `audit-a11y` le mesure d'ailleurs sur la liste
     hors-crise, plancher 24 — et le geste qui fait basculer les deux géométries est le bouton de
     démarrage, donc COMMANDÉ : A9 interdit qu'une hauteur change sans qu'on l'ait demandé, pas
     qu'un écran se réorganise quand on entre dedans (c'est déjà ce que fait le lot T5).
     38 px reste au-dessus du plancher HORS crise (32) et très au-dessus des 24×24 de WCAG. */
  /* ⚠ SECONDE PASSE DE RESSERREMENT (v5.7, signalé à l'usage : « le parcours inerte, essaie de
     rétrécir en hauteur encore plus sans perte d'information : il n'y a pas assez qui s'affiche »).
     A79 avait descendu la rangée de 44 à 38 px ; on va à 34, et la pastille de 24 à 22. Le
     PLANCHER est 32 px (cible hors crise) et il n'est pas négociable : c'est lui, et non le goût,
     qui borne l'exercice — le dire évite qu'on cherche encore 6 px la prochaine fois.
     Ce qui cède reste le REMBOURRAGE et l'ÉCART, jamais un mot ni un corps de texte. */
```

## C104 — ⚠ EN SESSION, MÊME DESSIN — MAIS LE PAS RESTE 44 px, ET C'EST DE L'ARITHMÉTIQUE (v5.7,

```
  /* ⚠ EN SESSION, MÊME DESSIN — MAIS LE PAS RESTE 44 px, ET C'EST DE L'ARITHMÉTIQUE (v5.7,
     signalé à l'usage : « en mode session, le parcours inerte est resté à la taille antérieure :
     compresse et harmonise »). Tout ce qui est GRAPHIQUE s'aligne sur l'avant-session (pastille
     22, rembourrage 2/10, écart 8, séparations resserrées) ; ce qui ne peut pas céder est le PAS
     entre deux rangées : ce sont des cibles tactiles, la règle 9 impose 44 px en crise, et deux
     cibles voisines ne peuvent être disjointes que si le pas vaut au moins 44. Le DESSIN descend
     donc à 38 px et la cible est rendue par un HALO de 3 px (A8 : la cible vient du halo, jamais
     du dessin) : 38 px de dessin, halo de 3 px, sur la gouttière de 6 px que la crise portait
     DÉJÀ — les deux halos se touchent sans se mordre (A66 : un écart vaut au moins la somme des
     halos qu'il sépare). Pas = 38 + 6 = 44, exactement.
     ⚠ LE PAS SE PREND SUR LA RANGÉE, JAMAIS SUR L'ÉCART : j'avais commencé par porter la
     gouttière à 6 px alors qu'elle y était, et par réduire la marge BASSE des titres. Un témoin a
     rougi aussitôt — « chaque titre a le même écart avec ses rangées », [10, 8] mesurés : en
     session, un des deux titres échappe au sélecteur `.rail-lad`. La marge basse appartient au
     rythme des sections ; la respiration se prend au-DESSUS, où elle n'engage personne.
     GAIN MESURÉ : **435 → 409 px, −6 %** — et non les −15 % que j'avais écrits avant de mesurer.
     L'ÉCART QUI RESTE AVEC L'AVANT-SESSION (409 contre 368) EST EXACTEMENT LE PAS : six rangées
     à 44 au lieu de 38, soit 36 px. Il est irréductible tant que ces rangées sont tapables, et le
     dire évite qu'on cherche encore à les rapetisser — `audit-a11y` rougirait aussitôt. Tout le
     reste du dessin, lui, est désormais identique aux deux régimes. */
```

## C105 — ⚠ DES BOUTONS, PLUS DES LIENS DE TEXTE (v5.6, demande de l'auteur : « rends-les plus

```
  /* ⚠ DES BOUTONS, PLUS DES LIENS DE TEXTE (v5.6, demande de l'auteur : « rends-les plus
     visibles »). Ils ouvrent la fiche ENTIÈRE — c'est le geste le plus utile de cet écran après
     « démarrer » — et ils se lisaient comme une note de bas de section : 12 px, sans bord, sous
     le titre de l'étage. Ils deviennent des boutons de CONTOUR au filet de composant
     (`--ctl-line`, le seul qui tienne 3:1, cf. A67), corps du texte courant, glyphe de commande à
     15 px (A13). CONTOUR et non rempli : le seul bouton rempli de l'écran reste « Confirmé —
     démarrer la session » (règle du bouton unique) — ce sont des LECTURES, elles ne démarrent
     rien. Ils s'étirent à parts égales sous 430 px, où deux libellés courts laissaient une rangée
     déséquilibrée. */
  /* Ligne « prêt » : du TEXTE à sa place, encre secondaire au nominal, ambre TEXTUEL quand une
     pièce manque — jamais un aplat (A11), jamais une pastille. Elle s'enroule plutôt que de
     tronquer un nom de document. */
```

## C106 — Étapes du détail d'une ligne de l'Échelle. RESTAURÉES À L'IDENTIQUE (valeurs de v4.24.0) :

```
  /* Étapes du détail d'une ligne de l'Échelle. RESTAURÉES À L'IDENTIQUE (valeurs de v4.24.0) :
     la purge v4.25.0 a emporté ces cinq règles alors que `ovPlanLadderHtml` émet TOUJOURS
     `.pl-stp` — une étape ⚠ (memory item) s'affichait donc en encre ordinaire, avec les puces
     disque du navigateur, indiscernable d'une étape banale, dans une surface visible en
     permanence dans le rail dès 780 px et ouvrable d'un tap du quai de crise. Le pendant statique
     (`.sv-stp li.crit`) n'a jamais cessé d'être stylé : deux surfaces de la même app donnaient une
     lecture différente du même contenu vital. Leçon : une suppression de composant doit vérifier
     au grep que chaque classe retirée est bien à ZÉRO émission — celle-ci en avait une.
     (La distinction ⚠ rouge / △ ambre repose ici sur la teinte ET la graisse, sans glyphe, comme
     en statique : `stepText` retire le préfixe. Sujet TRANSVERSE aux deux vues, à traiter d'un
     seul geste — ne pas le corriger dans une seule, ce serait recréer l'écart qu'on vient de
     refermer.) */
```

## C107 — ----- Challenge :: réponse (v4.11.0, AC 120-71B) : la pilule mono = RÉPONSE ATTENDUE ;

```
  /* ----- Challenge :: réponse (v4.11.0, AC 120-71B) : la pilule mono = RÉPONSE ATTENDUE ;
     cocher = readback (✓ + vert), porté par le CSS seul — le toggle chirurgical n'y touche pas. */
  /* LA CADENCE EST UNE MONO AMBRE, PLUS UNE PILULE BLEUE (v5.6, A11). La réponse attendue d'un
     challenge « :: » est le quatrième canal du marquage d'une étape critique — avec la case, le
     glyphe et le corps — et l'ambre est SON registre (« c'est là qu'on se trompe »). En pilule
     bleue, elle empruntait le registre de l'ACTION et ajoutait une masse de plus à une ligne qui
     doit se lire d'un trait. Elle passe donc à la ligne, sans fond : c'est une CADENCE, pas un
     bouton. Le bleu du dossier reste ce qu'il était — la position et l'action. */
  /* ⚠ ET ELLE QUITTE LE PLANCHER TYPOGRAPHIQUE (audit externe v5.10.0). La cadence était le PLUS
     PETIT corps de tout l'écran de crise — 11 px, le plancher, celui qu'A6 réserve aux exceptions
     motivées — alors qu'elle porte les nombres qui gouvernent le geste (« 30:2 — sans délai »,
     « toutes les 2 min »). A11 la nomme pourtant comme le quatrième canal du marquage d'une étape
     vitale : un canal au plancher n'est pas un canal. Elle passe à --t-body, c'est-à-dire JUSTE
     SOUS l'étape qu'elle qualifie (--t-item) et jamais au-dessus — elle précise l'acte, elle ne
     le remplace pas. Le cliquet de plancher de `check-type` descend d'autant : c'est un ÉCHANGE
     rendu, pas une tolérance prise. */
```

## C108 — I4 (v4.62.0) — DENSITÉ « LECTEUR » : la liste est celle de la page (`ol.steps > li[data-ck]`),

```
  /* I4 (v4.62.0) — DENSITÉ « LECTEUR » : la liste est celle de la page (`ol.steps > li[data-ck]`),
     seuls les CORPS changent. La ligne courante domine (22 px, encre pleine, fond d'accent) ; les
     autres restent lisibles au-dessus et au-dessous — c'est le contexte que le lecteur
     reconstruisait à la main, et le modèle ECL : liste entière + curseur. */
  /* (`.rm-r` supprimée en v4.62.0 avec le paragraphe isolé du lecteur — la réponse attendue vit
     dans la pilule `.stp-r` de la ligne, agrandie par la densité. Règle 14.) */
  /* v4.28.0 — l'ÉTAT ne disparaît jamais (ECAM) : l'overlay couvrait le quai #cbTimers, donc le
     lecteur porte sa PROPRE bande de minuteurs (tous, échus d'abord en ambre + mot « échu » ;
     pas de « +n » : la bande passe à la ligne, rien n'est caché). Carte des blocs = modèle ECL
     (la liste reste visible autour du curseur — un item isolé fait perdre sa place) : mêmes
     pastilles que le rail de soin (vert ✓ fait, bleu ici, neutre à venir — jamais d'alerte). */
  /* (`.rm-ctx` supprimée en v4.62.0 : le contexte « précédent / suivant » était une
     reconstruction manuelle — la liste le donne par construction. Règle 14.) */
```

## C109 — (create-band supprimée — le choix de méthode vit dans le dialogue « Créer », SPEC §2.1.)

```
  /* (create-band supprimée — le choix de méthode vit dans le dialogue « Créer », SPEC §2.1.) */
  /* Pied de page COMPACT (une seule ligne qui replie au besoin) : version · synchro · stockage
     — tout le contenu passif tient sur ~34px ; « Installer l'app » s'y glisse s'il apparaît. */
  /* ══ v5.19 — LE PIED EST UNE COLONNE DE RANGÉES, PLUS UNE COULÉE QUI ENJAMBE ════════════════
     MESURÉ sur trois largeurs (250 px en socle de colonne, 574 et ~300 en voie étroite) : la
     coulée `flex-wrap` mettait la VERSION en bout de la rangée des liens à 574, la rejetait sous
     eux à 300, et n'alignait rien — trois bords gauches cohabitaient (18 px pour l'icône, 28 pour
     le texte d'un lien, 36 pour celui d'un état), avec 2 px d'interligne entre des rangées de
     32 px et 14 px de gouttière. L'ordre de lecture y changeait avec la largeur.
     UNE COLONNE, UN BORD, UN RYTHME : les commandes gardent leur rangée (elles peuvent tenir à
     deux de front), l'état descend en rangées empilées, et toutes les lignes partagent la même
     colonne de texte à 19 px (marque de 14 px + 6 px). Interligne unique de 4 px.
     Les deux lignes d'état sont des COMMANDES (l'une ouvre la fenêtre Stockage, l'autre déplie) :
     elles prennent donc le même dessin — marque, texte, chevron — et la hauteur de 32 px que la
     règle 9 leur devait déjà (`#storageInfo` en était à 15,4 px depuis toujours). */
```

## C110 — « ai- » : préfixe HISTORIQUE (première fenêtre = « Créer via IA ») devenu le préfixe GÉNÉRIQUE

```
  /* « ai- » : préfixe HISTORIQUE (première fenêtre = « Créer via IA ») devenu le préfixe GÉNÉRIQUE
     de toutes les modales (Compte, PDF, confirmations…) — ai-modal/ai-card/ai-x/ai-top/ai-actions.
     Ne pas y lire un lien avec l'IA ; renommer casserait sélecteurs CSS+JS pour un gain nul. */
  /* ⚠ ON CONTRAINT LE GESTE, PAS LA BOÎTE (v5.6, signalé à l'usage : « fenêtre compte &
     synchronisation : le scroll se déplace de gauche à droite, surtout sur smartphone »).
     PREMIÈRE TENTATIVE, ANNULÉE : `overflow-x:hidden` sur la fenêtre. L'auteur l'a rejetée à
     l'écran — « des éléments sont tronqués, notamment la barre d'input, et la ligne de scroll dans
     Safari tronque le contenu » — et il a raison : un `overflow:hidden` COUPE ce qui dépasse au
     lieu d'empêcher ce qui dépasse, et sur un défileur WebKit y réserve en plus sa gouttière.
     CE QUE LA MESURE DIT, ET C'EST CE QUI DÉSIGNE LE REMÈDE : sous WebKit comme sous Chromium, à
     320 / 390 / 430 px, déconnecté, connecté, avec un courriel de 70 caractères, avec le bloc
     admin « État de l'instance » rendu, et avec une chaîne INSÉCABLE injectée tour à tour dans
     seize conteneurs — **aucun élément de cette fenêtre n'est défilable en X, et rien ne dépasse
     de la carte** (390/390, 320/320). Le contenu n'est donc pas en cause.
     Ce qui reste est le GESTE : `.ai-modal` est `overflow:auto`, donc un défileur sur les DEUX
     axes, et iOS laisse traîner un tel défileur horizontalement — avec rebond — même quand il n'y
     a rien à faire défiler. `touch-action:pan-y` interdit ce panoramique SANS toucher à la
     géométrie : aucun clip, aucune gouttière, aucune troncature possible.
     ⚠ BORNÉ À LA FENÊTRE SIGNALÉE, et c'est délibéré : `touch-action` se résout en prenant la
     contrainte la plus stricte de la chaîne d'ancêtres, donc un enfant ne peut PAS rendre le
     panoramique horizontal à un tableau du mini-Markdown ou à une page de PDF zoomée. La fenêtre
     Compte, elle, n'héberge aucun défileur horizontal — vérifié ci-dessus. On étendra si le même
     glissement est signalé ailleurs, fenêtre par fenêtre. */
```

## C111 — ⚠ L'AXE HORIZONTAL DES FENÊTRES EST FERMÉ (`overflow-x:clip`, v5.10.5 — signalé à l'usage

```
  /* ⚠ L'AXE HORIZONTAL DES FENÊTRES EST FERMÉ (`overflow-x:clip`, v5.10.5 — signalé à l'usage
     avec vidéo puis MESURÉ par instrumentation sur l'appareil : « on peut scroller de gauche à
     droite dans la fenêtre compte »). CE N'EST PAS un cache-misère : le contenu a été balayé
     7 largeurs × 3 zooms × 2 moteurs sans un seul élément plus large que la carte, et le
     débordement résiduel mesuré SUR l'appareil est de 2 px — un artefact d'ARRONDI au zoom
     fractionnaire (taille S = 90 %), pas un contenu. Or sur iOS, 2 px suffisent : l'axe devient
     panoramiquable, et l'élastique donne au geste une amplitude de dizaines de pixels. Une
     fenêtre est un DOCUMENT VERTICAL par construction (tout contenu large y défile dans son
     propre conteneur interne) : fermer l'axe ne retire rien à personne — il supprime un axe que
     rien n'utilise, et que seul l'arrondi savait ouvrir. */
  /* iOS Safari — LA FENÊTRE ÉTAIT COUPÉE EN BAS (retour utilisateur v4.29.3 : « le contenu ne
     scrolle pas sur cette bande ») : un overlay `fixed; inset:0` se dimensionne sur le GRAND
     viewport iOS (barre d'outils repliée) — barre visible, le bas de l'overlay passe DERRIÈRE
     elle, et comme l'overlay est aussi le DÉFILEUR, la fin du contenu est inatteignable (on peut
     scroller jusqu'au bout, mais le bout est sous la barre). `100dvh` suit le viewport DYNAMIQUE :
     la fenêtre s'arrête toujours au bord réellement visible. ÷ --zf (règle v4.24.0) ; les
     navigateurs sans dvh gardent `inset:0` (état antérieur). Chromium/desktop : strictement
     identique (dvh = viewport), vérifié par sonde à 90/100/130 %. */
  /* v4.29.4 : sur l'appareil réel (PWA installée, AUCUNE barre dynamique), la fenêtre restait
     coupée ~60 px au-dessus du bord — `100dvh` ment donc sur iOS dans certaines configurations
     (viewport visuel non restauré après clavier, quirks standalone). La seule source de vérité
     est `window.visualViewport.height` : --vvh est posée et tenue à jour par JS (resize/scroll
     du visualViewport), dvh ne sert plus que de REPLI avant la première mesure. Même division
     par --zf que toute hauteur de fenêtre (règle v4.24.0). */
  /* ⚠ v5.10.9 — UNE HAUTEUR NE SUFFIT PAS : IL FAUT AUSSI LA POSITION (signalé à l'usage avec
     quatre captures : « fenêtre et fond gris coupés, avec clavier c'est beaucoup plus visible »).
     `--vvh` donnait la BONNE hauteur à une couche posée à la MAUVAISE origine. Sur iOS, ouvrir le
     clavier ne rétrécit pas le viewport de MISE EN PAGE : il PANORAMIQUE le viewport VISUEL à
     l'intérieur (`visualViewport.offsetTop` > 0) pour montrer le champ focalisé. Or `position:fixed`
     s'ancre au viewport de mise en page : la couche restait collée à un `top:0` désormais AU-DESSUS
     de l'écran. Mesuré sur les captures : hauteur ~660 px, décalage ~370 — il ne restait qu'une
     bande de 290 px de voile gris en haut de l'écran, la carte amputée de son titre, et le reste de
     la page à nu SOUS le voile. Ce n'était donc jamais « sans raison » : le défaut se voit
     exactement quand `offsetTop` n'est pas nul, c'est-à-dire surtout clavier ouvert.
     `--vvt` porte ce décalage et la couche se repose dessus : `top` + `height` décrivent alors le
     rectangle RÉELLEMENT visible, et non plus sa seule taille. Hors iOS (et clavier fermé) `--vvt`
     vaut 0 et la règle est à l'octet celle d'avant — vérifié à la sonde aux deux moteurs.
     ⚠ NE PAS confondre avec le recollage `unpan()` (v5.10.4), qui traite le décalage RÉSIDUEL après
     fermeture du clavier : il s'interdit d'agir tant qu'un champ est focalisé — donc précisément
     pendant tout ce que montrent les captures. Les deux sont complémentaires : `unpan` répare un
     état incohérent, `--vvt` rend les couches justes dans un état parfaitement cohérent.
     ⚠ BORNÉ AUX COUCHES PLEIN ÉCRAN, et c'est délibéré : le chrome collant de la PAGE (en-tête,
     quai, dock) est ancré au viewport de mise en page avec le document qu'il commande — le suivre
     séparément le décollerait de son contenu. */
```

## C112 — Le QR est PLAFONNÉ, et rétréci au palier le plus contraint : à 320×568 la carte dépassait de

```
  /* Le QR est PLAFONNÉ, et rétréci au palier le plus contraint : à 320×568 la carte dépassait de
     2 px et « Arrêter le partage » perdait 6 px de sa cible — pour un code qui reste scannable
     bien en dessous (4,8 px par module à 197 px, relu par le décodeur d'Apple ; à 141 px on est
     encore à 3,4 px par module, au-dessus du seuil pratique d'un appareil photo à 20 cm).
     v5.16.0 : plafond 200 → 240 px et 52 → 56 vw (« lisible de plus loin », demandé à l'usage) —
     le palier < 360 px, lui, ne bouge PAS : c'est le cas mesuré ci-dessus, et y grossir le QR
     referait passer « Arrêter le partage » sous la ligne de flottaison.
     ⚠ PORTÉE `#shareModal` OBLIGATOIRE (attrapé par audit-partage en posant v5.16.0) : la carte
     d'appariement vit AUSSI dans #shareBody, dont la règle « 260 px d'écran à écran » (id, plus
     spécifique qu'un couple de classes) battrait ce plafond-ci — le conflit existait avant, il
     était juste invisible tant que les deux règles disaient 200. */
```

## C113 — CALQUÉE SUR LES AUTRES FENÊTRES DE L'APP, et pas seulement par cohérence de style : `.ai-card`

```
  /* CALQUÉE SUR LES AUTRES FENÊTRES DE L'APP, et pas seulement par cohérence de style : `.ai-card`
     apporte `margin:auto`, donc le CENTRAGE VERTICAL dans le conteneur flex. Sans lui la carte
     restait collée en haut d'une page opaque — acceptable sur un téléphone où elle occupe presque
     tout l'écran, franchement cassé à 760 px de large où elle flottait au-dessus de 450 px de vide.
     On hérite aussi de l'échelle typographique (titre 18 px, paragraphes 13 px) : un `h1` à 22 px
     n'existe nulle part ailleurs dans l'application. */
  /* PAR UN `#id`, JAMAIS PAR L'ORDRE. `.join-card` et `.ai-card` ont la même spécificité : la
     largeur maximale de 720 px d'`.ai-card`, déclarée PLUS BAS, l'emportait — la carte s'étalait
     sur 700 px et les paragraphes couraient sur toute la largeur. C'est le 6ᵉ incident de cascade
     du projet (cf. `.read-grid`, `.cbt-n`, `.mode-seg` — PURGÉ en v5.0.0 avec le sélecteur de
     mode, remplacé par l'excursion « ⤢ Tout voir » / « ↩ Un bloc » —, les éditeurs) et la règle
     est écrite : pour une GÉOMÉTRIE, on ne dépend jamais de l'ordre de déclaration. */
  /* Les deux fenêtres du partage prennent la largeur STANDARD des dialogues du projet (480 px,
     comme Créer, Compte, Catégories, Membres, Nouvelle bibliothèque). Elles étaient à 420 et
     460 px — les plus étroites de l'application, ce qui se voyait.
     ET LE CONTENU EST BORNÉ À L'INTÉRIEUR. Sous 780 px, l'application transforme TOUTE fenêtre en
     feuille pleine largeur (`max-width:none; width:100%`) — c'est sa convention, et on n'y touche
     pas. Mais le contenu de celle-ci est majoritairement CENTRÉ (le code, le QR) : sur une tablette
     à 744 px il courait d'un bord à l'autre, avec le code perdu au milieu d'une surface vide.
     Mesuré : carte 744×1133 pour 643 px de contenu. On borne donc l'intérieur, pas la feuille —
     la convention est respectée, la lecture redevient celle d'un dialogue.
     LE TITRE ET LA CROIX NE SONT PAS BORNÉS, et c'est une exigence de cohérence : dans toutes les
     fenêtres de l'application, l'en-tête occupe la largeur de la feuille et le ✕ vit à son coin
     supérieur droit. Les rentrer avec le contenu aurait fait de celle-ci la seule fenêtre où l'on
     ferme ailleurs qu'ailleurs — or c'est le geste le plus appris de toutes. Seul le CORPS, dont
     la lecture souffre d'une largeur excessive, est ramené à une colonne. */
  /* ⚠ CE N'EST PAS UNE LARGEUR DE FENÊTRE, c'est une COLONNE DE LECTURE dans une feuille pleine
     largeur — et elle prend la mesure du gabarit DIALOGUE, puisque la phrase ci-dessus dit
     exactement cela : « la lecture redevient celle d'un dialogue ». Elle était à 460, un nombre
     qui n'était celui de rien (audit 9b). */
```

## C114 — Fenêtre ouverte = page de fond VERROUILLÉE (v4.21.0 ; TECHNIQUE CHANGÉE v4.29.9). L'ancien

```
  /* Fenêtre ouverte = page de fond VERROUILLÉE (v4.21.0 ; TECHNIQUE CHANGÉE v4.29.9). L'ancien
     verrou figeait body en position:fixed + top:-scrollY — or c'est LUI qui produisait la
     « bande morte » d'~60 px en bas des fenêtres sur iPhone (dossier v4.29.x, prouvé à la règle
     visuelle : accueil sans verrou → bottom:0 AU bord physique ; fenêtre ouverte, body fixé →
     bottom:0 flotte 60 px AU-DESSUS — iOS rétrécit l'espace des fixés descendant d'un body
     lui-même fixé, sans qu'AUCUNE mesure web ne le voie : ih/vv/dvh disaient tous 874).
     Nouveau verrou : overflow:hidden sur html ET body (fiable depuis iOS 16), qui BLOQUE le
     défilement de fond SANS reparenter le repère des fixés ni perdre la position (restaurée en
     ceinture à la fermeture). overscroll-behavior:none coupe le chaînage du rebond. Les fenêtres
     (position:fixed) restent leurs propres défileurs. AU TOUCHER pour les dialogues (au pointeur
     fin, masquer la barre de défilement décalerait le fond visible), à TOUS les pointeurs pour
     les feuilles opaques (.modal-full, v4.23.0 : rien du fond n'est visible). */
```

## C115 — FEUILLE « PLAN » (v4.23.0) : PLEIN ÉCRAN à toutes les largeurs — c'est une vue d'ensemble,

```
  /* FEUILLE « PLAN » (v4.23.0) : PLEIN ÉCRAN à toutes les largeurs — c'est une vue d'ensemble,
     elle a besoin de toute la place (les intitulés cliniques ne se tronquent pas). Barre collante
     en tête de la carte : titre, sélecteur d'affichage, ✕. Le corps est le seul défileur. */
  /* align-items reste à flex-start (valeur de .ai-modal) : avec `stretch`, la carte est FIGÉE à
     la hauteur de l'écran, le plan déborde sans être défilable — et le seul défileur qui reste
     est la page DERRIÈRE (bogue constaté). Ici la carte GRANDIT avec son contenu et c'est la
     modale qui défile (overflow:auto + overscroll-behavior:contain hérités de .ai-modal), donc
     le fond ne bouge jamais. min-height:100dvh : un plan court remplit quand même l'écran. */
  /* overscroll-behavior:none (plus strict que le `contain` de .ai-modal) : au bout du plan, le
     geste ne se propage NI à la page NI au navigateur (rebond, tirer-pour-recharger). La feuille
     est opaque et plein écran — rien derrière elle ne doit bouger, jamais. */
```

## C116 — ⚠ VINGT-TROISIÈME DÉFAUT DE RANGÉE FLEX — L'EN-TÊTE DE FENÊTRE (v5.6, signalé à l'usage :

```
  /* ⚠ VINGT-TROISIÈME DÉFAUT DE RANGÉE FLEX — L'EN-TÊTE DE FENÊTRE (v5.6, signalé à l'usage :
     « fenêtre compte & synchronisation : le scroll se déplace de gauche à droite »). Deux objets,
     un titre et un ✕ de 44 px, et AUCUN des deux ne cédait : un `h3` a `min-width:auto`, donc sa
     largeur minimale est celle de son texte. Mesuré à 390 px sur « Compte & synchronisation » :
     314 + 10 + 44 = 368 pour 358 disponibles — le ✕ sortait de 10 px, et sur écran tactile cela
     donne un défilement horizontal de la fenêtre entière. Même famille que le bandeau de
     déplacement (v4.74.0), la croix du panneau minuteurs (v4.55.3) et l'en-tête de bloc de
     l'éditeur (A48) : quand tout est incompressible sauf rien, c'est le dernier qui sort.
     ON ENROULE, ON NE TRONQUE JAMAIS : le titre peut rétrécir (`min-width:0`) et son texte passe à
     la ligne — un titre de fenêtre se lit en entier, et la hauteur est libre ici. Le ✕ garde ses
     44 px et sa place. */
```

## C117 — `:not(.sheet-full)` AJOUTÉ (v4.55.3, retour d'usage « les titres sont décalés vers le bas »).

```
    /* `:not(.sheet-full)` AJOUTÉ (v4.55.3, retour d'usage « les titres sont décalés vers le bas »).
       Cette règle transforme toute fenêtre en feuille pleine largeur sur écran étroit et lui pose
       18 px de rembourrage haut. Or « Se repérer » et « Consulter » se donnent DÉJÀ `padding:0`
       (leur barre de titre est `sticky top:0` et doit affleurer le bord) — mais elles perdaient :
       `.ai-modal:not(.pdf-modal):not(.dlg-confirm) .ai-card` vaut (0,3,0), car `:not()` COMPTE LA
       SPÉCIFICITÉ DE SON ARGUMENT, contre (0,2,0) pour `:is(.plan-modal,.ref-modal) .ai-card`.
       Mesuré : 18 px de fond nu au-dessus de la barre, et 65 px sur un iPhone à encoche, où le
       `env(safe-area-inset-top)` s'ajoute — la barre étant collante, la bande restait visible en
       défilant. NEUVIÈME piège de cascade du projet, TROISIÈME par spécificité, et le premier par
       `:not()`. Les deux autres fenêtres plein écran étaient déjà exclues nommément ; on exclut
       désormais la CLASSE qui les désigne, pour que la prochaine hérite de l'exclusion. */
```

## C118 — ----- ACCUEIL V5 (canvas turn 6) : une seule interface responsive. < 780px : recherche pleine

```
  /* ----- ACCUEIL V5 (canvas turn 6) : une seule interface responsive. < 780px : recherche pleine
     largeur, chips bibliothèques/catégories, TAB BAR basse à pastille glissante (au pouce).
     >= 780px : colonne gauche (sections, bibliothèques, catégories) + répertoire fluide.
     L'état n'est jamais porté par la couleur seule : pastille + encre + graisse + aria-selected
     (rôles tablist/tab, flèches + focus itinérant — WCAG 1.4.1 & APG). ----- */
  /* Compacte (v4.1.2) : 44px de haut (cible tactile minimale préservée) + paddings resserrés —
     l'ancienne barre (52px + 8/12 de padding) mangeait trop d'écran sur mobile. */
  /* DEUX GROUPES SUR UNE LIGNE, chacun avec son intitulé — et l'enroulement comme filet : à
     320 px avec plusieurs bibliothèques, deux groupes comprimés seraient illisibles. */
  /* REPLI DES FILTRES (v5.0.0, audit design A3-1/A5-3 ; DÉCLENCHEUR DÉMÉNAGÉ EN v5.0.3) —
     cf. `filterFoldHtml` pour la doctrine. Il vit désormais CONTRE la recherche, dans l'en-tête :
     il ne coûte plus une ligne au premier écran, et il est GLYPHE SEUL, la place horizontale
     d'une rangée d'en-tête étant la plus disputée du produit. Registre neutre au repos, registre
     de SÉLECTION quand il est ouvert — le même couple que les chips, donc rien à apprendre —
     et registre de SÉLECTION PLEIN, avec le NOMBRE de filtres posés, dès qu'un filtre agit :
     la couleur n'est jamais seule (règle 8), c'est le chiffre qui porte l'information. */
  /* LA FEUILLE DE FILTRES (v5.6, planche 8c). Le dépliant d'en-tête est PURGÉ avec sa classe
     `.filterfold` (règle 14) : il faisait grandir le chrome COLLANT de l'accueil au moment même
     où l'on cherche à voir la liste, et les trois familles ne s'y voyaient jamais ensemble — on
     déroulait une rangée après l'autre dans un espace qui poussait le contenu vers le bas.
     Dans une feuille, elles tiennent d'un coup, l'écran entier leur appartient, et le pied peut
     ANNONCER le résultat avant de fermer : on sait ce qu'on va trouver avant d'y aller. */
```

## C119 — ⚠ SA HAUTEUR EST CELLE DU CHAMP, ET ELLE NE PEUT PAS ÊTRE ÉCRITE (signalé à l'usage : « la

```
  /* ⚠ SA HAUTEUR EST CELLE DU CHAMP, ET ELLE NE PEUT PAS ÊTRE ÉCRITE (signalé à l'usage : « la
     taille du bouton filtre est moins longue que le champ de recherche — c'est voulu ? » — non).
     Une hauteur FIXE de 36 px, celle des contrôles ronds de l'en-tête, laissait 4 px de jeu en haut
     comme en bas : le champ monte à 43 px sur écran TACTILE (police de 16 px, plancher de la règle
     9) et redescend à 38 px au pointeur fin — il n'existe donc aucun nombre juste à écrire ici.
     `align-self:stretch` fait porter la hauteur par la RANGÉE, quelle que soit celle du champ, et
     `min-height` garde la cible réglementaire si la rangée devenait un jour plus courte. */
  /* Le déclencheur de filtre (maquette accueil) : sur la rangée des contrôles de liste, à son
     bord DROIT, avec son MOT — glyphe seul, il fallait l'apprendre. Cible 44 px par le halo,
     dessin 36 px : il ne doit pas épaissir la rangée. */
  /* ⚠ BOUTON ROND, GLYPHE SEUL (v5.6, demande de l'auteur : « comme sur Apple »). Le tracé est
     trois filets horizontaux qui RÉTRÉCISSENT de haut en bas — 16 · 10 · 4 dans une boîte de 24,
     donc centrés et d'écart constant (5 px), ce qui est la seule façon que le dessin se lise à
     16 px. Le mot « Filtres » disparaît : sur la rangée la plus disputée du produit, un contrôle
     qui vit à POSITION CONSTANTE s'apprend par sa forme (mêmes 36 px de dessin et 44 de cible que
     ses voisins de l'en-tête, A30).
     ⚠ LA RÈGLE 8 RESTE TENUE : la couleur n'est jamais seule — c'est le NOMBRE de filtres posés
     qui dit l'état actif, en pastille, et le nom accessible le dit en toutes lettres. */
```

## C120 — ⚠ LE GLYPHE SUIT LE BOUTON (signalé à l'usage : « augmente la taille des traits dans filtrer

```
  /* ⚠ LE GLYPHE SUIT LE BOUTON (signalé à l'usage : « augmente la taille des traits dans filtrer
     pour que ça corresponde mieux à la taille du bouton »). Le tracé est écrit à 16 px dans la
     coque statique — calibre d'un temps où le rond en faisait 38 ; contre un champ de 48 il n'en
     occupait plus qu'un tiers, et trois traits fins perdus au centre d'un grand rond se lisent
     comme un pictogramme lointain, pas comme une commande. 20 px pour 48, c'est le rapport
     encre/rond de « ＋ » (15 dans 36) : la rangée cesse d'avoir deux densités d'icône.
     ON NE TOUCHE PAS À LA COQUE : `width`/`height` y sont des attributs de PRÉSENTATION, que le
     CSS remplace — et le tracé est DUPLIQUÉ dans `uiIcon`, donc chaque édition du balisage est
     une édition à faire deux fois. L'ÉPAISSEUR SUIT D'ELLE-MÊME, ce qui est tout l'objet de la
     demande : `stroke-width` vit dans le viewBox de 24, les traits passent donc de 1,47 px rendus
     à 1,83 sans qu'aucune valeur d'épaisseur ne soit écrite quelque part. */
```

## C121 — Sélecteur SEGMENTÉ à pastille glissante — composant GÉNÉRIQUE (v4.4.2), partagé par la tab

```
  /* Sélecteur SEGMENTÉ à pastille glissante — composant GÉNÉRIQUE (v4.4.2), partagé par la tab
     dialogue « Créer » (Aide <-> Protocole) et le sélecteur de taille du texte.
     L'état vit sur la RACINE (.seg.i1 = 2e segment actif) et la racine n'est JAMAIS re-rendue
     -> la pastille GLISSE au lieu de sauter. Deux segments.
     v4.71.1 : le composant accepte N segments (`--seg-n` / `--seg-i`), pour la TAILLE DU TEXTE
     qui en a quatre. La mécanique à DEUX est laissée strictement intacte — `.seg.i1` continue de
     piloter la tab bar, « Créer » et #modeSeg. Le cas N passe par un `#id` et non par une classe
     de plus : à spécificité égale ce serait l'ORDRE de déclaration qui trancherait, et le projet
     a déjà payé cinq fois ce piège (cf. .read-grid, .cbt-n, .mode-seg, les largeurs d'éditeur). */
  /* ⚠ LA MÉCANIQUE À N SEGMENTS EST CELLE DU COMPOSANT, PLUS CELLE D'UN `#id` (v5.6, signalé à
     l'usage : « dans la fenêtre Compte, le fond qui glisse d'option en option est trop large et
     ne correspond pas à une autre »). Elle vivait sur `#zoomSeg` seul : le sélecteur de THÈME,
     ajouté ensuite avec trois crans, héritait donc de la pastille à DEUX — mesuré 79 px de
     pastille pour un segment de 43. Une mécanique écrite pour un porteur est une mécanique que
     le porteur suivant n'aura pas.
     ⚠ ET LA GRILLE REMPLACE LE FLEX : `flex:1` n'égalise PAS des libellés de longueurs
     différentes (`min-width:auto` recale chaque item sur son texte — c'est la leçon v4.25.1, qui
     avait déjà imposé une grille pour le cas à deux). `repeat(var(--seg-n,2),1fr)` donne des
     pistes strictement égales quel que soit le nombre de crans, donc une pastille qui tombe
     juste sans qu'on ait à la calculer par sélecteur.
     Le défaut par défaut vaut DEUX : `calc((100% - 8px)/2)` est exactement l'ancien
     `calc(50% - 4px)`, et `.seg.i1` continue de piloter les deux-crans par l'ORDRE. */
```

## C122 — UNE RANGÉE, UN SEUL SURVOL (signalé à l'usage : « l'ombre des boutons de bibliothèque bugue

```
  /* UNE RANGÉE, UN SEUL SURVOL (signalé à l'usage : « l'ombre des boutons de bibliothèque bugue
     en desktop — maintenant on a 2 boutons au même fond, et en sélectionner un casse
     l'affichage »). Depuis que l'aplat de sélection vit sur le CONTENEUR, la micro-réponse E5 du
     bouton-titre (lévitation d'1 px + ombre au survol) le décollait de son propre fond : le
     titre montait, le crayon restait, et l'ombre se peignait par-dessus le bleu — deux objets là
     où il n'y a qu'une bibliothèque. C'est le conteneur qui répond au geste, comme c'est lui qui
     porte l'état ; le bouton-titre et son crayon n'ont plus d'état de survol propre.
     La micro-réponse E5 est donc portée par `.hs-wrap` (inscrit dans la liste nominative du bloc
     « E5 » plus bas, d'où `.hs-row` reste inscrit pour les rangées SANS conteneur : sections,
     catégories, historique) et neutralisée sur le bouton-titre — spécificité (0,3,0) contre
     (0,2,0), donc l'ordre de déclaration ne décide de rien (5ᵉ piège de cascade du projet). */
```

## C123 — LA SÉLECTION VA JUSQU'AU BORD DROIT (demande utilisateur) — sous le bouton « modifier », le

```
  /* LA SÉLECTION VA JUSQU'AU BORD DROIT (demande utilisateur) — sous le bouton « modifier », le
     cadenas ou l'écart, qui appartiennent à la même rangée. Une bibliothèque est UNE ligne : que
     l'aplat s'arrête avant son propre bouton d'édition la coupait en deux, et laissait croire que
     le geste vise autre chose que la rangée sélectionnée. C'est le CONTENEUR qui porte l'état ;
     le bouton garde le sien (même couleur, donc aucune couture visible). */
  /* ⚠ LE CONTENEUR SUIT LA MÊME TEINTE QUE LA RANGÉE (signalé à l'usage : « hover/couleur des
     listes de bibliothèques bug »). Les rangées de TYPE et de CATÉGORIE sont passées à la teinte
     de sélection ; celle-ci, portée par le CONTENEUR, était restée en aplat primaire PLEIN — la
     même colonne montrait donc deux encodages de la même chose, et l'encre blanche du bouton
     d'édition se retrouvait sur un fond clair dès qu'on la corrigeait à moitié. Un seul
     encodage : teinte + encre `--act`, ici comme ailleurs. */
```

## C124 — ⚠ EN ACCUEIL LARGE, LA COQUE EST DE HAUTEUR FIXE ET LES COLONNES DÉFILENT DEDANS — donc

```
    /* ⚠ EN ACCUEIL LARGE, LA COQUE EST DE HAUTEUR FIXE ET LES COLONNES DÉFILENT DEDANS — donc
       rien, ici, ne « suit » le viewport visuel : c'est la coque ENTIÈRE qu'il faut recadrer
       (signalé à l'usage : « ça fonctionne mieux quand la barre de recherche est dans l'en-tête,
       mais quand elle est dans la sidebar elle ne suit pas »). Le correctif de la v5.12.0 déplaçait
       des couches COLLANTES ; ici il n'y en a aucune — la barre vit en tête d'une colonne qui
       défile à l'intérieur d'un cadre calé sur `100dvh`, et `dvh` ne rétrécit PAS quand le clavier
       s'ouvre (il suit le chrome du navigateur, pas le clavier). Le cadre restait donc à pleine
       hauteur, le clavier en recouvrait le bas, et le panoramique emportait le haut hors de l'écran.
       On borne la coque à la hauteur RÉELLEMENT visible et on la descend du panoramique : elle
       occupe alors exactement le rectangle visible, et ses colonnes défilent dedans comme avant.
       `--vvh`/`--vvt` valent 0 et 100dvh hors clavier (cf. la garde `VVT_MIN_CLAVIER`) : la règle
       est alors à l'octet celle d'avant. */
```

## C125 — ⚠ ÉPITAPHE — `.pg-wide` A EXISTÉ LE TEMPS D'UNE ITÉRATION ET A ÉTÉ PURGÉE (règle 14), sur

```
    /* ⚠ ÉPITAPHE — `.pg-wide` A EXISTÉ LE TEMPS D'UNE ITÉRATION ET A ÉTÉ PURGÉE (règle 14), sur
       signalement à l'usage. Elle faisait céder la colonne d'ÉTAT pour rendre à la Page sa
       largeur d'auteur
       (227 px de débordement mesurés à 1280 px en cockpit). Le calcul était juste et le résultat a
       été REFUSÉ à l'usage, en deux mots qui disent tout : « le volet noter l'heure reste petit, et
       les minuteurs apparaissent en bas de la page ». Deux effets, une cause — la colonne d'action
       passait de 904 à 1244 px pendant que le dock gardait son plafond de 660, si bien qu'il
       paraissait rétréci ; et une surface d'ÉTAT VIVE se retrouvait sous le document, en pleine
       session. Déplacer l'état pendant un soin coûte plus cher qu'un défilement horizontal sur une
       surface de consultation.
       CE QUI RESTE VRAI ET N'A PAS DE SOLUTION GRATUITE : la feuille fait 1130 px (A133) dans un
       défileur de 904. L'ajustement d'office reste refusé — il demande k = 0,775, ce qui ramène
       une cible de 44 px à 34 (A8) —, et rétrécir la feuille casserait « la même image partout »,
       qui est tout le lot Page. L'échelle reste donc un GESTE : « ⤢ Ajusté », un tap. */
    /* --stick-top : bas de ce qui est DÉJÀ collé en haut (en-tête + quai de crise), mesuré par
       syncHdrScroll — une constante laisserait le rail passer sous le quai. */
    /* HAUTEUR DÉFINIE (pas max-height) : les trois zones se répartissent l'espace, et chacune
       borne son propre débordement — sans hauteur définie, `flex:1` sur l'Échelle n'aurait rien
       à répartir et tout retomberait dans un défileur unique (le défaut corrigé v4.23.0). */
```

## C126 — UN SEUL DÉFILEUR (v4.23.0, retour d'usage). Un temps découpé en trois zones bornées

```
    /* UN SEUL DÉFILEUR (v4.23.0, retour d'usage). Un temps découpé en trois zones bornées
       défilant chacune sur elle-même : la posologie ne se faisait plus repousser, mais chaque
       section devenait un HUBLOT (les minuteurs tombaient à 132px pour 1559px de contenu) et on
       perdait la vue d'ensemble d'une section. Sur-correction.
       L'invariant réellement nécessaire est plus faible : **ce qui est de longueur ILLIMITÉE
       passe en DERNIER**. Ordre = minuteurs → posologie → Échelle → horodatage : la posologie est
       avant l'Échelle, donc plus rien ne peut l'enterrer, et le rail redevient une colonne
       continue qu'on lit d'un trait.
       Ce qui rend cet allègement sûr : l'état critique (session + minuteur ÉCHU) est déjà porté
       en permanence par le QUAI — le rail n'a donc pas à l'épingler une seconde fois. */
    /* ══ DEUX NIVEAUX DE SÉPARATION, ET ILS NE SE RESSEMBLENT PLUS (v5.6, signalé à l'usage :
       « les séparations entre repères posologiques sont les mêmes qu'entre les grands blocs, ce
       qui pose un problème de hiérarchie »). C'était exact et mesuré : un ITEM (`.pos-card`) et
       une FAMILLE (`.rail-sec`) portaient le MÊME filet de 1 px en `--line`. Deux traits
       identiques pour deux niveaux ne hiérarchisent rien — c'est l'argument de l'échelle
       typographique (v4.71.1) appliqué aux filets.
       ⚠⚠ ET MA PREMIÈRE LECTURE ÉTAIT FAUSSE — CORRIGÉE PAR L'AUTEUR (v5.6 : « enlever les lignes
       séparatrices entre minuteurs-compteurs / journal / repères posologiques n'était pas une
       bonne idée ; ce que je te disais, c'est que les séparateurs DANS les repères se
       ressemblaient trop »). J'avais supprimé le filet de FAMILLE, alors que le défaut était la
       RESSEMBLANCE des deux niveaux. Le filet de famille est ce qui donne au rail sa structure :
       il revient, franc et pleine largeur. C'est le séparateur d'ITEM qui change de nature — il
       RENTRE de 10 px, donc il ne peut plus se lire comme une frontière de famille. Deux niveaux,
       deux dessins ; retirer l'un des deux n'était pas hiérarchiser, c'était appauvrir.
       ⚠ ET « CONSULTER » ENTRE DANS LA MÊME RÈGLE (signalé dans le même message : « diagnostics
       différentiels et références sont collés entre eux ») : ses sections sont des `.rs-sec`, qui
       n'avaient ni marge ni rembourrage — donc deux familles à touche-touche, séparées par le
       seul trait qu'on vient de retirer aux autres. ⚠ MAIS ELLES NE REÇOIVENT PAS LE MÊME
       TRAITEMENT, ET C'EST UNE QUESTION DE NATURE : une `.rs-sec` est une CARTE (fond, bordure,
       rayon) — lui retirer son `border-top` lui ouvrirait le haut. Une carte se sépare d'une
       autre carte par un ÉCART, un point. */
    /* ⚠ UNE SECTION VIDE NE COMPTE PAS COMME VOISINE (v5.6, mesuré sur une fiche mono-bloc) : la
       zone des minuteurs est ÉMISE même quand la fiche n'en a aucun — hauteur 0, mais elle
       existe, et le filet de famille se posait donc AU-DESSUS de la première section réellement
       remplie, comme un trait suspendu au-dessus du vide. `:empty` ne suffit pas (la section
       contient un conteneur vide) : on la retire du flux quand elle ne rend rien. */
```

## C127 — REPÈRES DU RAIL — chrome désaturé, registre CONSERVÉ. Doctrine ECAM appliquée finement : on

```
    /* REPÈRES DU RAIL — chrome désaturé, registre CONSERVÉ. Doctrine ECAM appliquée finement : on
       calme la PRÉSENTATION, jamais la sémantique d'une donnée anormale. Les repères ordinaires
       sont des LIGNES (ni cadre ni fond, nom en `--ink` et non en bleu — le bleu est l'accent
       d'ACTION, il n'a rien à faire dans une colonne qui oriente) ; un repère « ⚠ » GARDE sa carte
       teintée et son encre rouge : une erreur de dilution tue. Le contraste entre les deux devient
       porteur de sens au lieu d'être uniforme, et une ligne tient 58px là où une carte en prenait
       85. La DOSE reste en encre PLEINE : la hiérarchie avec le nom passe par la GRAISSE, jamais
       par l'encre — adoucir un dosage serait l'inversion à ne pas faire. */
    /* v5.6 : le rail n'a PLUS RIEN à surcharger — le flux et la colonne partagent désormais la
       même rangée inline. Deux habillages pour un même objet en feraient deux composants. */
    /* ⚠ CETTE RÈGLE NE VAUT QUE POUR UNE LIGNE QUI SUIT UNE BOÎTE (signalé à l'usage : « la
       bordure du haut des repères en dessous du premier est tronquée »). Elle a été écrite quand
       le repère ORDINAIRE était une ligne à filet : après une boîte ambre, ce filet ferait double
       trait. Mais deux BOÎTES qui se suivent — ce qui est le cas dès que deux repères sont
       signalés △, donc sur les deux fiches d'exemple depuis le lot T13 — n'ont pas ce problème :
       la seconde se retrouvait alors sans bord haut, et se lisait comme rognée.
       C'est la même leçon que « normal = ligne, signalé = boîte » : une règle écrite pour une
       LIGNE ne doit pas s'appliquer à une BOÎTE. */
    /* AUCUNE section bornée (v4.23.0, retour d'usage « où sont passés mes minuteurs ? »).
       Une tentative de borner la seule section minuteurs a suffi à FAIRE DISPARAÎTRE le compteur
       et le bouton « ＋ Minuteur PA » : 327px affichés pour 413px de contenu, et la barre de
       défilement étant invisible au repos (macOS/iOS), rien ne signalait la troncature.
       LEÇON : dans une colonne déjà défilante, un sous-conteneur borné ne « range » pas, il
       ESCAMOTE. Le rail est donc une colonne ENTIÈREMENT continue ; le seul dispositif retenu
       contre l'enterrement de la posologie est l'ORDRE (l'illimité en dernier). */
    /* `flex-wrap` + titre INSÉCABLE (correctif — « le design du plan de gauche n'est pas
       harmonieux ») : dans la colonne de 240 px du cockpit, l'en-tête ne tenait pas et c'est le
       TITRE qui cassait, en « PLAN — » / « ÉCHELLE ». Un intitulé coupé en deux se lit comme un
       défaut de mise en page. Désormais c'est « ⤢ complet » qui passe à la ligne — un contrôle
       qui descend d'un rang reste un contrôle, un titre haché n'est plus un titre. */
```

## C128 — ÉCHELLE DÉSATURÉE : mêmes lignes que le Plan, mais l'état n'est plus porté que par le

```
    /* ÉCHELLE DÉSATURÉE : mêmes lignes que le Plan, mais l'état n'est plus porté que par le
       MARQUEUR (✓ vert = fait, ● bleu = ici, ⑂ ambre = décision). On retire les APLATS et les
       liserés colorés : le rail oriente, il ne doit pas rivaliser de saillance avec l'action.
       L'information reste intégralement — seule la compétition visuelle disparaît. */
    /* L'ÉCHELLE EST UNE SURFACE, comme tout le reste de la page (correctif d'harmonie). Elle était
       posée à NU sur le fond `--bg` — donc la seule zone de la vue lecture à ne pas être une
       surface, entre une colonne d'action faite de cartes blanches et un rail dont les minuteurs
       sont des cartes blanches. Sur du fond, ses hairlines se lisaient comme des restes de trait
       plutôt que comme les lignes d'un tableau ; en cockpit, où elle occupe toute la colonne de
       gauche, cela sautait aux yeux. MÊME TRAITEMENT DANS LES DEUX LOGEMENTS (rail droit ≥ 780,
       colonne de gauche ≥ 1200) : c'est le même composant, seul son logement change — deux
       habillages en feraient deux composants.
       Le fond `--surface` ne rétablit AUCUN aplat d'état : la désaturation ci-dessous reste
       entière, l'état n'est porté que par le marqueur. */
    /* ⚠ CE BLOC A ÉTÉ RÉÉCRIT (v5.0.0) — il datait du dessin PLAT, où l'état n'était porté que
       par la COULEUR DU TEXTE du marqueur. Avec la pastille PLEINE de la maquette, sa règle
       `.pl-line.cur .n{color:var(--link)}` peignait l'encre en bleu SUR un fond bleu : le numéro
       du bloc courant était invisible, mesuré `color === background === rgb(31,95,166)`. Un
       héritage de dessin ne se corrige pas au cas par cas, il se REPREND.
       PLUS DE CARTE BLANCHE (maquette) : les rangées vivent sur le fond de la colonne, séparées
       par un filet. Une carte ajoutait un cadre autour de ce qui est déjà une colonne, et deux
       niveaux de surface pour un seul objet.
       LA DÉSATURATION RESTE, et elle est même plus nette : aucun aplat de rangée sauf la COURANTE,
       aucun texte coloré — tout l'état vit dans la PASTILLE, qui est le marqueur. */
```

## C129 — Occurrence surlignée sur la page PDF : rectangle en superposition, multiply pour laisser le

```
  /* Occurrence surlignée sur la page PDF : rectangle en superposition, multiply pour laisser le
     texte lisible dessous — même registre que mark.pf-h (le surlignage de recherche du texte). */
  /* v5.4.2 — LE SURLIGNEUR PDF EST FIXE, IL NE SUIT PAS LE THÈME (signalé à l'usage : « pas assez
     visible, encore plus en mode clair »). Une page PDF garde SES couleurs quel que soit le thème
     de l'app : teinter le surlignage par un token thématisé (`--verify-soft` + multiply) donnait
     un crème quasi invisible sur page blanche en clair, et une teinte différente en sombre — deux
     rendus pour un même document. Jetons FIXES deux-thèmes (famille des --rt- et --paper) : le JAUNE
     SURLIGNEUR universel, en fondu NORMAL (multiply s'éteint sur un fond sombre de PDF) avec un
     anneau ambre — visible sur fond clair (bande jaune #ffee99 effectif) COMME sur fond sombre
     (voile qui éclaircit + anneau). La couleur n'est pas un registre de l'app : c'est le code du
     surligneur papier, appris partout ailleurs (Aperçu, Acrobat). */
```

## C130 — ⚠ LA PILULE NE RECOUVRE RIEN — SA BANDE EST RÉSERVÉE (v5.6, audit externe 9d). Elle flotte

```
  /* ⚠ LA PILULE NE RECOUVRE RIEN — SA BANDE EST RÉSERVÉE (v5.6, audit externe 9d). Elle flotte
     au-dessus du document, et un document consulté pendant un soin peut porter EN BAS DE PAGE une
     posologie ou un tableau de doses : une ardoise opaque posée dessus est une occultation que
     personne n'a commandée (V1). Le geste qui l'a fait naître était « trouve ce mot », pas
     « couvre le bas de mes pages », et elle persiste ensuite de page en page.
     Trois réponses étaient possibles — la faire apparaître au geste, l'assumer par écrit, ou
     réserver la bande. C'est la troisième : le document se TERMINE au-dessus de la barre, donc il
     n'y a plus rien à occulter, et c'est déjà la doctrine du dock (une bande réservée, jamais une
     superposition au contenu clinique). La réserve est une hauteur MESURÉE (`--pdfhl-r`, posée par
     `pdfHlSync`) et vaut 0 tant que la pilule n'existe pas : aucun pixel perdu dans le cas
     ordinaire, où l'on n'a pas cherché.
     ⚠ ELLE SE MESURE EN `offsetHeight`, PAS EN `getBoundingClientRect` : le réglage de taille du
     texte est un `zoom` sur `<html>`, et le rect rendrait des px VISUELS qu'il faudrait diviser
     par `zoomF()` (règle 10) — `offsetHeight` est déjà dans le repère de l'élément. */
```

## C131 — « Ne pas oublier » : bandeau compact SOUS le titre (les rappels critiques se voient sans défiler).

```
  /* « Ne pas oublier » : bandeau compact SOUS le titre (les rappels critiques se voient sans défiler). */
  /* Registre ALERTE compact (canvas turn 6) : kicker « ■ NE PAS OUBLIER » + items en coulée
     « · » — le rappel critique tient en quelques lignes sous le titre. */
  /* ══ LE CHAPEAU EN SESSION EST UNE RANGÉE, PAS UN PAVÉ ROUGE (v5.6, maquette) ══════════════
     REPLIÉ, il n'est plus un encadré au registre ALERTE mais une ligne de rappel : ■ rouge, le
     mot en encre douce, et le compte dans une pilule neutre. Le motif est celui de A11 poussé un
     cran plus loin — un pavé rouge PERMANENT en tête de la colonne d'action désensibilisait au
     rouge exactement comme l'aplat d'une étape critique, et il occupait la place la plus chère de
     l'écran pour dire une chose qu'on a déjà lue avant de démarrer.
     DÉPLIÉ (et hors session, où l'on s'oriente avant d'agir), il REPREND son cadre : c'est alors
     la condition d'entrée QRH, on la lit, et le registre est juste. La couleur n'est jamais seule
     dans les deux états : le ■ et le mot restent. */
```

## C132 — La trace d'un compteur : muette, permanente, à l'endroit du geste. Aucune hauteur tant

```
  /* La trace d'un compteur : muette, permanente, à l'endroit du geste. Aucune hauteur tant
     qu'il n'y a rien à dire (`:empty`). */
  /* ⚠ REGISTRE CORRIGÉ APRÈS RELECTURE ECAM (question de l'auteur : « bonne couleur ? bon
     comportement ? »). CE N'EST PAS UNE CONFIRMATION : le vert du dossier dit « ce que l'on VIENT
     DE FAIRE est acquis » — étape cochée, algorithme terminé —, c'est-à-dire la réponse à un
     geste. Ici c'est un FAIT PASSIF, affiché en permanence sur chaque compteur : en vert, il
     diluerait le vert des étapes cochées exactement comme un rouge permanent dilue le rouge des
     étapes vitales. Registre MEMO (neutre), donc — celui de l'information qui n'appelle aucune
     action.
     ET IL RESTE, C'EST VOULU : un fait n'expire pas. C'est l'analogue du « last actuation » d'un
     synoptique ECAM — un état de l'objet, pas une alerte à acquitter. Le faire disparaître au bout
     de n secondes rendrait la question « ai-je consigné ? » à nouveau sans réponse, ce qui est
     précisément ce qu'il vient réparer. */
```

## C133 — Le chevron suit la convention du dépliant, et elle est la même partout : « › » fermé,

```
  /* Le chevron suit la convention du dépliant, et elle est la même partout : « › » fermé,
     « ▾ » ouvert. Il pointait vers le HAUT une fois déplié — l'inverse de ce que fait tout
     `<details>` du fichier, et de ce qu'on lit ailleurs dans le produit. */
  /* ⚠ LE CHEVRON VIT DANS LA PASTILLE DU COMPTE (v5.6, demande de l'auteur) : « 4 › » est UN
     objet, pas un chiffre suivi d'un signe — la pastille dit à la fois combien il en reste et
     qu'elle se déplie. Il garde son écart au chiffre et reste `aria-hidden` : l'état est déjà
     porté par `aria-expanded` sur le bouton, et le compte par l'étiquette lisible. */
  /* ⚠ `line-height:1` COUPAIT LE CHEVRON (v5.6, signalé à l'usage : « la flèche › est tronquée
     dans sa bulle »). Sa boîte de ligne valait 11 px pour un glyphe qui en occupe 14 : il
     débordait par le haut et par le bas, et se posait 3 px sous le chiffre — d'où l'impression
     d'un signe rogné et mal calé. Le chevron prend l'interligne de la pastille, et les deux
     enfants s'alignent sur leur milieu : un seul objet, une seule ligne de base. */
```

## C134 — Panneau minuteurs REPLIÉ tant que rien n'est démarré : le contenu clinique passe devant.

```
  /* Panneau minuteurs REPLIÉ tant que rien n'est démarré : le contenu clinique passe devant. */
  /* v5.4.2 : la rangée repliée `.rt-collapsed` est SUPPRIMÉE avec son CSS (règle 14) — le volet
     du quai est l'accès unique en étroit (cf. runtimePanel) ; la grammaire tonale « un dépliant
     se reconnaît avant de se lire » (v5.4.0) survit là où des dépliants demeurent. */
  /* Bouton à MAINTENIR sur fond clair (Recommencer l'algorithme) : même geste anti-accidentel que les minuteurs. */
  /* Compteurs : « + » (geste principal) plus large et teinté ; « − » (correction) plus discret. */
  /* P2-5 (audit design v4.56) : en session on incrémente 10 fois pour 1 correction — l'action
     fréquente prend la MASSE (tonal --primary-soft, jamais un rempli : réservé au CTA), la
     corrective reste un contour compact ≥ 44 px. */
  /* « — nommer » / « ✎ » / « ✕ » d'un compteur ad hoc : des LIENS dans le libellé, pas des
     boutons de la rangée de commandes — ils ne comptent rien, ils règlent l'objet. Cible 32 px,
     plancher HORS registre d'alarme (un compteur ne sonne pas) ; le volet n'a pas 44 px à donner
     à trois contrôles de plus sur une carte qui en porte déjà trois. */
  /* Les quatre durées : une rangée de crans, cibles de 44 px (on est en crise), corps du texte
     courant en chasse fixe — ce sont des VALEURS, elles s'alignent. Aucun champ, aucun clavier. */
```

## C135 — E5 (audit design v4.57.0) : l'app paraît « vivante sous le doigt » sans rien déplacer —

```
  /* E5 (audit design v4.57.0) : l'app paraît « vivante sous le doigt » sans rien déplacer —
     survol = 1 px de lévitation, APPUI = léger enfoncement. transform/opacity SEULEMENT (règle
     v4.41.0 : jamais une propriété de mise en page), 120 ms, et le survol ne s'applique qu'au
     POINTEUR FIN : sur tactile, le premier tap pose l'état hover et un hover qui bouge favorise
     le double-tap (leçon v4.4.4). L'appui, lui, vaut partout — c'est le retour du geste. */
  /* v4.71.0 : ÉTENDU AUX SURFACES CALMES, et à elles seules. La restriction de la v4.57.0 aux
     tuiles d'accueil était un reste de chantier, pas une doctrine — l'audit écrivait E5 pour
     toute l'app. Ce qui EST une doctrine, et qui borne la liste : en crise, le MOUVEMENT EST
     RÉSERVÉ À L'ALARME (ECAM). Rien du chrome de crise ne lévite ni ne s'enfonce — ni les
     rangées d'étape, ni les segments du quai, ni les cartes de minuteur, ni le rail, ni le plan.
     Noter que la moitié SURVOL ne pourrait de toute façon pas s'y déclencher (`pointer:fine` =
     une souris, pas le téléphone du terrain) ; c'est la moitié APPUI qui impose la borne.
     ET PAS DE BALAYAGE EN GROS sur `.btn` ni sur `.ai-card` : ces sélecteurs attrapent aussi le
     dialogue « Terminer la session ? » et l'index des complications, qui s'ouvrent PENDANT un
     soin. La liste est donc nominative — sidebar d'accueil, palette d'ajout, volet de relecture,
     rangées de document et de sélecteur, versions, porte « + » de l'éditeur. */
```

