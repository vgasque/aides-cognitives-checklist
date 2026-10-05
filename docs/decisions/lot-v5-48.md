# Lot v5.48 — l'exercice guidé (A467)

> Fichier normatif, suite de [`lot-v5-47.md`](lot-v5-47.md) (A463-A466). Les numéros A sont des adresses : ne jamais
> renuméroter. Origine : [`docs/audit-apprentissage-2026-10.md`](../audit-apprentissage-2026-10.md), point 20 du § 8,
> maquetté sur le canevas (planches « Guide 1-4 »). Décisions de l'auteur, une par une : « 1. laisser le choix ;
> 2. ajouter les revues, et le jalon ; 3. mélange des deux ; 4. on s'arrête là ; 5. selon 1 ; 6. estomper un petit
> peu ». Puis : « assure-toi que Prendre en main et l'exercice guidé suivent les mises à jour au fil du temps ».

## A467 — l'exercice guidé : une bulle par geste, sur la vraie commande

**Ce que c'est.** Un exercice (A-mode exercice, v4.27.0) accompagné d'une bulle qui désigne, un geste après l'autre,
la commande réelle de l'écran : démarrer, cocher, lire la capsule, passer au bloc suivant et répondre à la décision,
ouvrir la revue, ouvrir une complication puis « Reprendre », horodater, terminer en maintenant. Huit étapes sur l'ACR
d'exemple, sept sur l'anaphylaxie (pas de revue : l'étape se retire d'elle-même).

**Où on le lance (décision 1 : le choix, jamais imposé).**
- Sur les deux aides d'exemple, avant la session : la rangée « Apprendre avec cette aide » (« Commencer le guide »,
  bouton secondaire — la seule primaire reste « Démarrer » ; croix « Ne plus proposer »). L'exercice libre reste la
  touche « Exercice » du quai. UNE rangée, jamais une carte haute : la première forme (liste des gestes + deux
  boutons, 230 px) repoussait « Ne pas oublier » sous le bouton de démarrage — le témoin CHAPEAU (séquence QRH
  critères → memory items → geste) l'a rougie. Sous 430 px effectifs, le bouton passe sous le texte (`zw430`).
- La carte disparaît une fois le guide fait ou refusé (`ac-guide` = `done` | `off`, préférence de l'appareil).
- Ensuite, à la demande : menu ⋯ de l'aide d'exemple › « Exercice guidé », ou Moi › Prendre en main › « Lancer
  l'exercice guidé » (qui rajoute les exemples s'ils ont été supprimés).
- Pas sur les aides de l'utilisateur pour l'instant ; le moteur saute déjà une étape dont l'aide n'a pas l'objet
  (`ok`), l'élargir ne demandera que d'ouvrir `guideFor`.

**Ce qui est guidé (décision 2).** La revue a sa propre étape : c'est l'objet le moins évident (pointillé, ne retient
pas « Continuer », se coche d'elle-même). Le jalon n'a pas d'étape — l'atteindre demanderait trois tours de boucle —
mais une phrase dans la bulle de la complication, écrite à partir de l'aide : « Elle se propose aussi d'elle-même quand
« Chocs délivrés » atteint 3 : c'est un jalon. »

**Comment on avance (décision 3 : le mélange).** Quand le geste est sans risque et s'apprend par la main, la bulle
attend qu'il soit FAIT, et elle le lit dans l'état de l'app (`done`), jamais dans un clic sur la bulle. Quand il n'y a
qu'à regarder (la capsule), « Suivant ». Toujours « Passer », sauf démarrer et terminer ; toujours « Quitter le
guide » (l'exercice continue). Un geste fait d'avance compte : l'étape est validée en passant.

**Ce qui n'est jamais guidé (décision 4).** Une session réelle (règle 11 : la bulle n'existe qu'en exercice, la carte
et la rangée du menu disparaissent dès qu'une session démarre) ; le partage, l'éditeur, la synchronisation. Les bulles
parlent de l'outil, jamais de clinique (§ 2).

**Estomper un peu (décision 6).** TOUT ce qui n'est pas visé s'estompe d'un même voile (`#gdVeil`, token
`--gd-veil` : l'ambiance à 42 %, qui éclaircit le jour et assombrit la nuit — estomper, pas voiler) percé autour de
la cible (`clip-path: path(evenodd…)`, 8 px de marge, coins de 12) ; en-tête, bande « Exercice », capsule, quai,
cartes et fenêtre de fin compris. Le voile est inerte au pointeur : tout RESTE UTILISABLE. La cible porte un anneau
`--act` (l'action, règle 8), `--sys-ink` dans le quai sombre — jamais l'ambre ni le rouge, qui sont des registres.
La bulle est en matière système (tokens seulement), donc suit le thème.
**v5.48.1 (signalé par l'auteur sur les captures : « tout le contenu n'est pas estompé, seulement certains
éléments »).** La v5.48.0 estompait une LISTE de sélecteurs (`opacity:.7` sur les blocs, les touches, la capsule) :
l'en-tête, la bande d'exercice, la ligne « Parcours », les cartes sous le bloc et la fenêtre de fin y échappaient, et
toute surface ajoutée plus tard y aurait échappé aussi — l'inverse de « suivre l'app ». Le voile unique n'énumère
rien. `audit-guide` l'exige à chaque bulle (couvre la fenêtre, trou = rectangle de la cible à 2 px, inerte) ;
vérifié capable d'échouer (voile désactivé : 47 rouges). Le cliquet `pointer-events:none` de `check-anim` passe à
24, motivé sur place.

**Placement — v5.48.2 : une CARTE ANCRÉE, plus une bulle qui suit (essai de l'auteur sur iPhone : « la bulle cache
le contenu » du volet des minuteurs, des étapes restantes et de la complication ; « le scroll est saccadé »).** Les trois
défauts avaient une cause : une infobulle posée À CÔTÉ de sa cible se met là où le geste ouvre quelque chose, et une
bulle `fixed` recalée en JavaScript à chaque défilement court derrière le défilement natif, qui est composé à part.
La v5.48.0-1 plaçait sous ou sur la cible, avec flèche et voile recalculés au défilement ; ils sont retirés.
- La carte se pose **au-dessus du quai, dans sa largeur** (`#sessionDock .sd-in`) — donc dans la colonne d'action au
  bureau (en ligne : texte à gauche, actes à droite dès 560 px), sur le volet du quai d'un pliable, jamais à cheval
  sur la charnière — ou au-dessus de ce que le quai a ouvert (volet d'horodatage, barre « ↩ Bloc »), `_gdBas`.
  Une cible fixée qui tomberait dessous (bouton de la fenêtre de fin) fait monter la carte en haut de l'écran.
- Elle **ne bouge jamais au défilement** ; la cible se montre par son anneau (`outline`, natif, sans retard). Le
  voile s'efface pendant un défilement et revient 220 ms après.
- Elle **réserve sa hauteur** au bas de la page (`body.gd-on`, `--gd-h`) : on défile toujours jusqu'à la dernière
  ligne, et le volet des minuteurs s'arrête au-dessus d'elle (il défile en lui-même).
- Le guide amène la cible dans la bande visible (sous la capsule, au-dessus de la carte) au début d'une phase — six
  essais espacés de 500 ms, l'app défilant elle-même après « Continuer » — et **ne le fait plus dès qu'on a défilé à
  la main** pendant la phase (molette, doigt, touches : seuls ces gestes le disent, un `scrollBy` n'en émet aucun).
  Mesuré en route : le premier jet ramenait la page vers la cible quand on défilait soi-même.
- **▾ réduit** la carte en une pastille « ▲ Guide k/n » (44 px, focus posé dessus), sans voile ; un toucher la rouvre.
- Trois phases réécrites pour dire ce qu'on voit : **capsule** (au téléphone, l'ouvrir puis la refermer EST le geste ;
  le voile découvre capsule ET volet, `avec`) ; **« Cochez les étapes restantes »** sans anneau ni rien devant les
  cases, la page amène TOUTES les cases restantes en vue (`voir`), puis l'anneau sur « Continuer » une fois prêt ;
  **dans la complication**, la carte nomme le bloc et dit que celui qu'on quitte attend, coches gardées.
Mesuré : `scrollBy` se compte en pixels de l'appareil comme les rectangles, `scroll-margin` non (sous zoom,
`scrollIntoView` ne bougeait pas). Positions réinjectées ÷ `zoomF()` (règle 10). Pourquoi pas de bulle au bureau ni
sur pliable : la saccade et l'occultation ne dépendent pas de la largeur, et un seul dessin est un seul comportement à
apprendre et à garder juste ; l'éloignement de la carte et de sa cible au bureau est compensé par l'anneau et le texte
(« la capsule, en haut »). Maquettes : canevas, rangée « 20 bis ».

**La fin.** Quand l'exercice se termine — par le guide ou par « Quitter l'exercice… » — une carte résume les gestes
(✓ fait, « – passé »), renvoie au compte rendu (Sessions) et à Moi › Prendre en main, et propose « Refaire le guide ».

**LE GUIDE SUIT L'APP (demande de l'auteur).** Il ne redessine rien : chaque étape POINTE un sélecteur vivant (`tgt`),
et ses mots viennent de l'aide ou de l'écran (question de la décision, titre de la revue, nom de la complication,
compteur et seuil du jalon, nom du compteur TEL QUE la capsule l'affiche). Trois gardes :
- `check-guide.mjs` (dans `npm run check`) : chaque libellé cité « … » dans GUIDE_GESTES, GLOSSAIRE et GUIDE_ETAPES
  existe ailleurs dans l'app ; chaque `#id`, `.classe`, `[data-…]` visé est émis ; chaque icône existe ; chaque étape a
  son geste dans le harnais. Vérifié capable d'échouer (bouton « Rédiger avec l'IA » renommé, cible `#tkKey` renommée).
- `audit-guide.mjs` : déroule le guide EN ENTIER par les vraies commandes, sur l'ACR à 390, 1280 et 360 px à 130 %,
  sur un pliable émulé (charnière à 540) et sur l'anaphylaxie : chaque phase trouve sa cible, la carte ne la couvre
  pas, tient dans la fenêtre, se pose au-dessus du quai dans sa largeur et d'un seul côté de la charnière ; elle ne
  bouge pas sous la molette, le voile se retire pendant, et au bout de la page rien ne reste sous elle ; ▾ et la
  pastille ; le geste réel la fait avancer ; la carte de fin compte tous les gestes ; aucune session réelle n'est créée ; l'ACR d'exemple doit exercer
  TOUTES les étapes (changer l'exemple au point d'en perdre une rougit : guide et exemple se revoient ensemble).
  Il ouvre aussi « Prendre en main » : tous les gestes, tout le glossaire, et le lancement du guide.
- `audit-a11y` : surfaces « carte exercice guidé » et « bulle exercice guidé ».
Règle : **toucher un geste de session (libellé, commande, comportement) = mettre à jour GUIDE_ETAPES et GUIDE_GESTES
dans le même commit.**

**Formes écartées.** Une bulle flottante près de sa cible, à toutes les largeurs (v5.48.2, ci-dessus) ; une carte d'entrée haute qui liste les gestes (séquence QRH, ci-dessus) ; un voile sombre qui bloque l'écran (décision 6 : estomper un peu) ; une bulle par-dessus une
session réelle (règle 11) ; avancer au clic sur la bulle pour les gestes (le guide apprend par la main) ; dessiner des
copies des commandes dans la bulle (elles divergeraient).
