# Journal des modifications

## [4.63.0] — 2026-07-29
### Phase K — la doctrine relit par-dessus l'épaule, et la page revient au contenu clinique

L'éditeur est l'envers de la crise : on y travaille au calme, et chaque minute investie là achète
des secondes ici. Deux changements, sur l'éditeur existant.

### K2 — la relecture doctrinale, en une seule grammaire
Les garde-fous existaient déjà (chapeau à 4 rappels, bloc à 7 étapes, challenge trop long, étape
qui cumule des actions) — mais **dispersés**, chacun sous son champ. L'auteur ne savait pas, en
fermant l'éditeur, ce qu'il laissait derrière lui.

`reviewNotes(f)` (pure, testée) les rassemble : chaque remarque **nomme sa cible** et l'action
proposée. Un volet « △ Relecture · n » en pied de page les liste et **ancre** vers la ligne
concernée, qui clignote une fois — sans voler le curseur : l'auteur vient de lire le bilan, c'est
à lui de choisir ce qu'il corrige.

**Jamais bloquant, jamais rouge**, et le volet le dit en toutes lettres : « aucune de ces
remarques n'empêche d'enregistrer — c'est vous qui connaissez votre service ». L'ambre est le
registre du « c'est là qu'on se trompe » ; le rouge reste à ce qui tue. Le volet **disparaît**
quand il n'y a rien à dire : un panneau affichant « 0 remarque » serait du bruit permanent pour
une information qu'on lit une fois.

### K4 — « Identité » se replie
Titre, catégorie, bibliothèque, code, date de validation et état occupaient tout le haut de
l'éditeur : on traversait six champs administratifs avant d'atteindre ce qu'on vient écrire. Ils
vivent maintenant dans un dépliant dont l'en-tête **porte déjà le titre et le code** — replié, il
n'escamote donc rien qu'on vérifie d'un coup d'œil.

**Ouvert d'office en création, replié en modification** : sur une fiche neuve, le titre est le
premier geste ; sur une fiche existante, il est déjà écrit et ce qu'on vient corriger est le
contenu. La distinction se fait sur le **titre vide**, pas sur l'existence de la fiche — dupliquer
donne un titre, repartir de zéro n'en donne pas. Le statut éditorial reste **en plus** dans la
barre : c'est un état, il ne se replie pas.

### Piège mesuré
`scrollIntoView({behavior:'smooth'})` **ne défilait pas du tout** sur 6 400 px d'écart — et aucun
défilement de l'application n'est animé. L'ancrage est direct.

### Non engagé, et pourquoi
K1 (éditer dans la grammaire de lecture) et K5 (« ▶ Essayer » comme bouton rempli unique) changent
le **geste** d'édition ; K10 (raccourcis à la frappe, import/export markdown structuré) ouvre un
parseur ; K6 (le discriminant en champ séparé) ajoute un **champ modèle**, donc touche `migrate`,
l'export v3 et l'affichage des titres partout. Chacun se décide séparément.

Vérifié : **794 tests × 2 moteurs** (+9), a11y 301/301, doctrine 112/112, lecteur 14/14,
consulter 8/8. Rien à rejouer côté serveur.

## [4.62.0] — 2026-07-29
### I4 — une seule grammaire de progression : guidé, journal et lecteur ne font plus qu'une

Le chantier structurant de l'audit. Guidé, journal et mode lecteur n'étaient pas trois vues d'une
même chose : c'étaient **trois écritures** de la même chose.

### Pourquoi — c'est doctrinal
- **ECAM.** L'affichage d'Airbus repose sur UN format unique pour tous les états de l'avion : le
  pilote n'apprend pas trois écrans, il apprend UNE grammaire (position fixe, registres,
  priorités) qui se décline. Trois surfaces de progression, c'est l'anti-ECAM — trois
  cartographies mentales pour la même information. Harmonisées, celui qui a appris l'écran hôte
  **sait déjà** lire l'écran invité.
- **QRH.** Un manuel n'a qu'une mise en page de checklist, quel que soit le lecteur : celui qui
  lit et celui qui exécute regardent le **même document**, et c'est ce qui permet le cross-check à
  voix haute. Si le lecteur voit une autre structure que l'hôte, « bloc 2, ligne 2 » ne désigne
  plus la même chose et la vérification croisée se désynchronise.
- **FAA, facteurs humains.** La *mode confusion* naît d'un même écran qui se comporte
  différemment selon le mode sans signal univoque. La réponse canonique est : structure
  **constante** + annonciateur de mode saillant — pas des écrans différents. Ici l'interactivité
  et le placard changent ; la structure, jamais.
- **Et l'ingénierie qui en découle** : trois surfaces = trois endroits où un correctif peut
  diverger. Ce fichier a payé **deux fois** — les copies du cœur de cochage avaient divergé
  (v4.42.0), et un invité scribe **conduisait** la checklist depuis le lecteur parce que ses
  verbes portaient d'autres noms (v4.55.0).

### Ce qui est désormais unique
- **Le cœur** — `applyCheck` est LE point d'écriture de `state.checked` : garde de rôle, trace
  do-verify, acquittement haptique, drapeau de fin. Les trois appelants ne font plus que peindre.
  Le lecteur écrivait `state.checked` **en direct** ; c'était la troisième copie, jamais recensée.
- **Le vocabulaire** — le lecteur émet `data-ovnext`, `data-ovopt`, `data-cxback`. Plus de
  synonymes, donc plus de liste de gardes à tenir en double : un verbe ajouté demain est couvert
  des deux côtés d'office, parce qu'il n'y a plus de « deux côtés ».
- **La structure** — `stepsListHtml` génère l'unique `ol.steps > li[data-ck]`, trace de
  vérification comprise. Elle était écrite trois fois, et avait déjà divergé : le journal peignait
  la trace, la vue guidée non, pour la même donnée.

### Ce que ça change à l'écran
Le mode lecteur montre désormais **le bloc entier**, ligne courante en 22 px sur fond d'accent,
au lieu d'un paragraphe isolé. C'est le modèle **ECL Boeing** — liste entière + curseur — que
l'audit v4.28.0 opposait déjà au un-item-à-la-fois : perdre sa place est un mode de défaillance
premier (Degani & Wiener). Supprimés avec la structure qui les exigeait : `.rm-r` (la réponse
attendue vit dans la pilule de la ligne) et `.rm-ctx` (le contexte « précédent / suivant » était
une reconstruction manuelle de ce que la liste donne par construction).

### Deux pièges vécus
- `applyCheck` remet `state.flowEnded` à false — donc le test « la fin était actée, il faut
  re-rendre » de la vue guidée ne se déclenchait **plus jamais**. Il faut capturer l'état avant
  l'appel. Le journal, lui, teste la présence de `.flow-end` dans le DOM : il y était insensible.
  C'est `audit-doctrine` qui l'a attrapé.
- `data-rmopt` était un **homonyme** : « reader option » dans le lecteur, « remove option » dans
  l'éditeur — et comme `[data-rmopt]` figurait dans la liste des gestes muets, le bouton
  « supprimer une réponse » de l'**éditeur** était bridé en mode invité. Renommé `data-optdel`.

Un contrôle de harnais a été **réécrit, pas supprimé** : il cherchait `.rm-ctx` (le mécanisme) ; il
mesure désormais la propriété — le contexte est visible, l'étape précédente est marquée faite, et
toutes les lignes portent le même verbe. Il échouerait si la liste redevenait un item isolé.

Vérifié : 785 tests × 2 moteurs, a11y **301/301 sur les deux moteurs**, doctrine 112/112, lecteur
**14/14** (+1), partage 294/294, vérification 8/8, complications 20/20, exercice 20/20.
Rien à rejouer côté serveur.

## [4.61.0] — 2026-07-29
### Une voix typographique — Source Serif 4 pour les titres

Phase 5 du chantier d'audit (F5). Le système roulait tout en `system-ui` : sûr, mais anonyme.
**Source Serif 4** (licence SIL OFL, sous-ensemble latin seul, graisse 600 seule, **21 Ko**)
prend le **titre de fiche**, la **marque** et le **titre du compte rendu** — et rien d'autre.

Ce n'est pas une décoration : les titres sont les seuls survivants du scan sous stress, ils
méritent un dessin. Le texte courant reste `system-ui`, la police que l'appareil rend le mieux —
changer le corps d'une aide lue en réanimation n'a jamais été l'objet.

- **Embarquée, jamais appelée.** L'app fonctionne hors ligne par construction : une police de CDN
  ne s'afficherait pas là où elle sert, et `font-src 'self'` l'interdirait de toute façon. Elle
  entre dans `ASSETS` (précachée dès l'installation, règle 13) avec son README de provenance et
  de licence, sur le modèle de pdf.js.
- `font-display: swap` : le texte s'affiche immédiatement dans la police de repli et bascule
  quand la police est prête — jamais d'écran de titre vide, même au premier chargement.
- **Graisse 600, pas 800**, aux endroits qui étaient en 800 : c'est la seule graisse embarquée,
  en demander une autre produirait une graisse synthétique (plus lourde, moins nette).
- Le compte rendu **téléchargé** retombe sur Georgia — voulu : un document autonome ne dépend
  d'aucun serveur.

Piège rencontré : `check-sw` lit les chaînes d'`ASSETS` littéralement — un commentaire placé *à
l'intérieur* du tableau est pris pour une entrée de cache (25 faux problèmes). Il vit au-dessus.

Vérifié : 785 tests × 2 moteurs, a11y 301/301, doctrine 112/112, zoom-scroll 6/6, `check-sw`
13 assets. Rien à rejouer côté serveur.

## [4.60.0] — 2026-07-29
### Mode moniteur — le téléphone posé devient un afficheur

Phase 4 du chantier d'audit (D3). Sur un chariot, sur le tableau de bord d'une ambulance, ou sur
le second téléphone de l'invité, **personne ne tient l'appareil**. Le mode moniteur en fait un
écran d'état lisible **à deux mètres** : chrono de session, prochain minuteur (nom + temps en
très grand), dernier repère horodaté. C'est l'ECAM au sens propre — un écran qu'on lit sans le
toucher.

**Aucun contrôle, et c'est la propriété qui compte.** Un tap n'importe où revient à la fiche :
une surface sans commande ne peut pas être actionnée par mégarde, ce qu'on veut précisément d'un
appareil posé au milieu d'un soin.

- Le minuteur montré est choisi par `monPick` (pure, testée) : un **échu l'emporte toujours**
  (annonciateur ECAM — l'écart passe avant le nominal), sinon le plus proche de son échéance
  parmi ceux qui tournent.
- Registres inchangés : un échu s'y affiche en ambre **et avec le mot « échu »**, jamais la
  couleur seule.
- Le dernier repère passe par `tkLabels`, la même source que le compte rendu : aucune seconde
  vérité, et un repère sans étiquette retombe sur « Repère n » plutôt que sur un mot inventé.
- Coquille du mode lecteur (z-index 92, sous le flash d'alarme), armement du retour système à
  l'ouverture — toute surface plein écran doit se fermer au geste retour d'Android.
- Rafraîchi par le tick existant : **aucune horloge en plus**.
- Entrée par le menu ⋯ des deux rôles, groupe « conduite en cours », visible seulement quand la
  session est démarrée — jamais dans le chrome de crise, qui n'a que 2,1 px de marge à 320 px.

Piège de test rencontré : `lastStart` est un **horodatage**, pas un délai — posé à 0 sur un
minuteur qui tourne, il fait croire à `now` millisecondes écoulées, et le test mesure alors
l'ordre de la fiche au lieu du tri.

Vérifié : 785 tests × 2 moteurs (+5), a11y 301/301, doctrine 112/112, lecteur 13/13, exercice
20/20. Rien à rejouer côté serveur.

## [4.59.0] — 2026-07-29
### Grand écran : le cockpit trois zones — orientation | action | état

Phase 3 du chantier d'audit (F4). À partir de **1200 px**, la vue de lecture tient de front la
colonne « Se repérer » (le plan, à gauche), le parcours (au centre) et le rail minuteurs (à
droite) : l'idéal ECAM — E/WD et SD sous les yeux en même temps. Pour un binôme hospitalier,
c'est un poste fixe où l'aide-lecteur voit plan, parcours et minuteurs **sans un tap**.

**Palier 1200, pas 1000.** L'audit proposait 1000 px « puisque le palier existe ». Mesuré : à
1000 px les trois colonnes laissent **~390 px** au contenu clinique — moins qu'une tablette en
portrait, pour ce qu'on lit sous stress. À 1200 px : plan 240, action 594 (son plafond de 860
au-delà), rail 360. Aucun palier nouveau n'est créé.

**Le plan quitte le rail droit** à cette largeur : l'afficher aux deux endroits ferait deux
sources pour la même structure — la règle qui vaut déjà pour les minuteurs nominaux.

**L'ordre du DOM reste celui de la lecture.** La colonne de plan est posée *après* la colonne
d'action et ramenée à gauche par `order` : ni un lecteur d'écran ni une tabulation ne doivent
traverser le plan pour atteindre la checklist. Le plan de gauche est le même
`ovPlanLadderHtml` désaturé, **inerte au cochage** (décision figée) — seul son logement change.

Le franchissement du palier **re-rend** (comme le rail à 780 et l'aperçu d'éditeur à 1000) :
c'est un changement de structure, pas de style. Piège vécu au passage : la règle du palier 1200
est déclarée deux fois (en tête puis réaffirmée plus bas, piège de cascade documenté) — la
variante cockpit doit suivre aux deux sites, sinon elle perd à l'ordre.

Vérifié : 780 tests × 2 moteurs, a11y 301/301, doctrine 112/112, zoom-scroll 6/6, vérification
8/8. Rien à rejouer côté serveur.

## [4.58.0] — 2026-07-29
### L'état de mode cesse de bouger — il s'ancre au coin haut-droit

Phase 2 du chantier ouvert après l'audit de design (concept H/B).

La pilule « ■ Mode crise » vivait à droite de la bande-titre quand celle-ci était dépliée, puis
**sautait au milieu de la ligne fusionnée** dès qu'on faisait défiler — et changeait de mot au
passage (« ■ MODE CRISE » ici, « ■ CRISE » là). Or c'est l'objet qui doit se lire en moins d'une
seconde : il devrait être le plus stable de l'écran, pas le moins.

Il est désormais **accolé à ◐ ⋯**, les deux seuls objets qui ne bougent dans aucun des deux
états, et **ne dépend plus du défilement**. Mesuré : même pixel (231 px à 360), même mot, déplié
comme condensé.

### Ce que ce concept n'apporte pas
Les ~90 px rendus au titre étaient le mérite du **concept A** (la pilule descendait dans le
quai), écarté par l'audit lui-même : le quai est la rangée de la télémétrie vive, et pour
l'invité un jeton de mode y doublonnerait les jetons de partage existants. Le gain de B est la
**stabilité**, pas la largeur.

### Deux amendements à l'audit, mesurés
- Il proposait de **vider la bande-titre de son état**. Cela aurait retiré le placard
  « ▪ Vous suivez » posé sur décision utilisateur en v4.55.4 — précisément parce que le bandeau
  est « l'endroit le plus lu » — et fait tomber deux contrôles de harnais qui encodent cette
  doctrine. Le bandeau garde donc son annonce en toutes lettres : la redondance est **voulue**,
  comme l'alarme au quai et au rail.
- Un **repli au glyphe seul** sous 430 px rendait ~41 px au titre. Annulé : en état condensé le
  bandeau est parti, il ne resterait qu'un carré rouge — la couleur et la forme seules pour dire
  le mode, ce que WCAG 1.4.1 et la règle « la couleur n'est jamais seule » interdisent l'une
  comme l'autre.

Le **liseré de mode 10 px** proposé par l'audit n'est pas posé : le placard hachuré de v4.55.4
est déjà le canal périphérique pour l'exercice et l'invité, à coût de hauteur nul — un liseré
serait un troisième dispositif pour la même information.

Vérifié : 780 tests × 2 moteurs, a11y 301/301, doctrine 112/112, exercice 20/20, partage 294/294.
Rien à rejouer côté serveur.

## [4.57.0] — 2026-07-29
### Passe esthétique — profondeur, contraste, rythme (phase 1 des pistes de l'audit)

Première phase du chantier « tout » ouvert après l'audit de design : la PEAU. Les phases
suivantes (en-tête de lecture, cockpit desktop, mode moniteur, police embarquée, restructuration
de la lecture, éditeurs) viennent ensuite, une version à la fois.

### Le thème sombre devient le « Contraste + »
Décision utilisateur : plutôt qu'un 4ᵉ cran au cycle de thème, **le sombre adopte les codes
couleur de l'ex-« Contraste + »** et garde son nom. Motif d'usage : l'extra-hospitalier — soleil
direct sur un écran sombre, gants, appareil posé sur un chariot. Deux canaux, et deux seulement :
encre secondaire relevée (**~7:1** sur les surfaces au lieu de ~4,9:1) et filets renforcés
(**3:1**, le seuil WCAG 1.4.11 des composants — les cadres de carte se voyaient à peine dans le
noir). **Pas** l'encre pleine du bloc `prefers-contrast: more` : là c'est l'utilisateur qui demande
d'aplatir la hiérarchie, ici c'est le défaut de tous. **Pas** les graisses +100 que proposait
l'audit : la graisse porte déjà l'état sur les segmentés, et l'élargir changerait toutes les
largeurs de texte — donc les mesures à 320 px que quatre harnais surveillent.

### Profondeur, fond, rythme
- **`--bg` d'un cran plus profond** (E7) : les surfaces blanches « portent » sans ombre en plus.
- **Trois niveaux d'élévation, écrits** (E1/D6) : plat + filet = contenu clinique ; `--shadow` =
  surfaces vives (session, minuteurs) ; `--shadow-lg` = overlays. Une modale était au niveau 2,
  donc au même plan visuel qu'une carte de session — corrigé. La règle tient en trois lignes dans
  AGENTS.md ; toute surface ajoutée doit s'y ranger.
- **Interlettrage des capitales unifié à `.07em`** (E2, 64 déclarations) : relatif et non px, il
  suit la taille du texte au lieu de se dénaturer quand le corps change.
- **Micro-réponses au geste** (E5) : lévitation d'1 px au survol — **pointeur fin seulement**, car
  sur tactile le premier tap pose l'état hover et un hover qui bouge favorise le double-tap
  (leçon v4.4.4) — et `scale(.99)` à l'appui. Transform/opacity uniquement, inertes sous
  `prefers-reduced-motion`.
- **Le ⤢ devient un dessin de trait** (E6) : même dessin, même doctrine (grammaire des ouvertures
  plein écran), au trait de la famille d'icônes. **Piège mesuré** : un SVG occupe sa largeur
  pleine là où le glyphe Unicode en occupait moins — **4 px de débordement de la rangée de
  commandes à 320 px**, attrapés par `audit-doctrine`. Rendus sur la taille de l'icône (13 px,
  11 sous 400 px), jamais sur `.ctrl-sp` ni par un renommage.

### La tête de bilan du compte-rendu (F6)
Le document commençait par la chronologie : les totaux se reconstituaient de tête, au moment
précis — le débriefing d'équipe — où l'on veut les lire d'un regard. Il s'ouvre désormais sur la
**durée totale en mono 40 px** et les **compteurs de la fiche en tuiles neutres** (plafond 4).
Les compteurs à **zéro sont montrés** : « 0 choc » est une information de débriefing, souvent LA
question. Identique à l'écran et à l'impression.

Vérifié : `npm run check`, 780 tests × 2 moteurs, a11y **301/301 sur Chromium ET WebKit**
(contrastes recalculés sur le fond effectif dans les deux thèmes), doctrine 112/112, zoom-scroll
6/6, consulter 8/8, modeseg 2/2, lecteur 13/13. Rien à rejouer côté serveur.

## [4.56.3] — 2026-07-29
### Audit de design externe — le lot applicable, mesuré et posé

Audit sur 25 captures (1 constat P1, 7 P2, 12 P3, plus des pistes D/E/F/G/H/I/K). Tout ce qui
tenait aux tokens existants, sans rouvrir de décision figée ni créer de capacité, est appliqué ;
les pistes marquées DÉCISION restent à trancher une par une.

### Zone de crise
- **Critères diagnostiques en lignes à filet** (P1-1) — une boîte encadrée par critère
  contredisait la doctrine des listes (« normal = ligne, signalé = boîte ») et repoussait
  « ▶ Confirmé — démarrer la session » loin sous le pli. **53 px rendus, mesurés** sur une fiche à
  critères de deux lignes. Le reste de la distance tient à la RÉDACTION, désormais outillée :
- **le garde-fou du chapeau dit aussi le rappel TROP LONG** (110 c., le seuil télégraphique des
  challenges). Mesuré : quatre rappels dont un composé pèsent 221 px à 360 px — c'est la longueur
  autant que le nombre qui pousse la première action hors de l'écran. Non bloquant, registre
  ATTENTION. `nfGuardTxt` accepte désormais le tableau (le nombre reste toléré).
- **G1 — une action cochable = une ligne** : l'éditeur signale une étape qui cumule des actions
  (« · » ou « + » entourés d'espaces, ≥ 2 dans la partie CHALLENGE ; la réponse « :: » a le droit
  d'énumérer, c'est une valeur). Doctrine QRH : sinon on coche « à moitié fait ».
- **Cartes minuteur** (P2-1) : le nom passe en casse de phrase 13,5/700 et la précision entre
  parenthèses finales est reléguée en méta 12 px (`tmLabelParts`, pure testée) — un nom long en
  petites capitales se déchiffre lettre à lettre, l'inverse du besoin en crise. Le libellé complet
  reste dans les `aria-label`.
- **Le temps dit l'état** (P2-7) : encre à l'arrêt, `--link` EN COURS, ambre échu. `--link` est
  doctrinalement « le temps d'un minuteur en cours » — le défaut disait le contraire.
- **Compteurs** (P2-5) : « + » tonal et large, « − » contour compact (≥ 44 px). En session on
  incrémente dix fois pour une correction ; l'action fréquente prend la masse, jamais un rempli.
- **Une seule ligne d'état** dans le bloc actif (P2-2) : « Vous êtes ici » à gauche,
  Lecteur/Vérifier à droite — **−52 px par bloc actif**, là où deux rangées de chrome flottaient
  entre le titre et la première étape.
- **Rangées d'étape à 60 px** (D1) : le 44 px doctrinal est un minimum, pas un optimum — un pouce
  ganté dans une ambulance en mouvement ne vise pas une case de 24 px. La rangée entière cochait
  déjà ; seule sa hauteur change.
- **Acquittement haptique** (D10) : ~18 ms au cochage et à l'incrément (`tick()`). Avec des gants,
  dans le bruit, la confirmation tactile évite le double-tap de doute — qui sur un compteur
  FAUSSE la donnée. Inerte sur iOS, qui n'expose pas l'API Vibration.
- **Pilule posologique insécable** en statique (D8) ; `tabular-nums` sur les nombres d'état (D11).

### Hors crise
- **Fenêtre Compte** : tuiles d'état **neutres** (P3-1 — `--primary-soft` est la teinte des
  boutons tonals : de la lecture seule s'y donnait l'air cliquable) et **une ligne de conséquence
  par réglage**, la garantie clé en gras, le texte existant CONSERVÉ sous « En savoir plus ».
- **Hors ligne annoncé en neutre** (D7) : « Hors ligne — tout fonctionne sur l'appareil » au pied.
  C'est un état NOMINAL — l'ambre reste à l'échec d'action réseau explicite. `storageState` reste
  PURE : l'état entre par l'instantané, relu à la peinture et aux évènements réseau.
- P3-2 (glyphe « Avec l'IA » au registre INFORMATION), P3-3 (« Cycle »/« Chrono » en pilule
  neutre), P3-4 (« Synchronisé · 11:12 » — le mot ne se dit qu'une fois), P3-5 (« console
  d'administration » remplace le jargon d'infrastructure), P3-6 (colonnes de temps du compte-rendu
  en mono tabulaire), P3-8 (secondes retirées des listes de sessions, `sessStamp`), P3-11 (pied
  d'accueil : le nominal permanent n'affirme plus en vert), P3-12 (pilule de catégorie neutre dans
  Consulter), P3-13 (« Terminer » du bandeau de reprise en contour, cible 44 px), P3-14
  (placeholder de date, compte à rebours du code en `--verify` sous 30 s).

### Écarté, et pourquoi
**G2** — « ✓ Bloc n complet — Continuer vers X » — a été implémenté puis **retiré sur décision
utilisateur** : le bouton passe déjà au registre CONFIRMATION quand tout est coché, les cases le
disent, et deux formules pour un même geste sont exactement ce qu'AC 120-71B proscrit. Le libellé
reste « Continuer — X → », **identique aux deux sites** (journal et vue guidée).

### Un constat d'audit qui visait la doctrine, pas le code
**P2-3** signalait le segment « ⤢ Plan » absent du quai sur toutes les captures. Il l'était en
effet : « Se repérer » a quitté le quai en **v4.25.0** pour la rangée de commandes (architecture
ECP/ECAM). C'est AGENTS.md qui était périmé — deux de ses sections se contredisaient depuis. La
formulation « ORDRE FIXE ⤢ Plan · ● Session · minuteurs » est corrigée. **P2-4** (invité lisant
« ■ MODE CRISE ») est vérifié **conforme** : le placard « ▪ Vous suivez » est livré depuis v4.55.4.

### Non engagé
Les pistes marquées DÉCISION dans l'audit — D2 (« Contraste + », thème vraie nuit), D3 (mode
moniteur), E7 (valeur de `--bg`), F4 (cockpit 3 zones), F5 (police embarquée), F6 (tête de bilan),
H (concepts d'en-tête B/C), I (restructuration de la vue de lecture), K (refonte des éditeurs) —
créent une capacité, touchent un token ou ouvrent un chantier : à trancher séparément.

Vérifié : `npm run check`, **780 tests × 2 moteurs** (+14), a11y **301/301 sur Chromium ET
WebKit**, doctrine 112/112, vérification 8/8, lecteur 13/13, historique 16/16, partage 294/294,
et les 14 harnais verts. Rien à rejouer côté serveur.

## [4.56.2] — 2026-07-28
### Le badge « En cours » trouve sa place — et un bug WebKit de grille est neutralisé

### Badge « ● En cours » à droite de la tuile
Glissé dans la sous-ligne de 11 px, le badge l'étirait et semblait rapporté (« on a l'impression
qu'elle n'est pas adaptée », retour utilisateur). Il vit désormais À DROITE de la tuile, centré
verticalement, hors du bloc de texte — la structure de la maquette desktop : colonne
titre + sous-ligne à gauche (`.qa-tx`), badge en frère à droite. Les rangées du répertoire, qui
alignent déjà leurs pastilles sur une ligne dédiée, ne changent pas.

### Pistes de grille figées au redimensionnement — bug WebKit, reproduit puis neutralisé
Signalé à l'usage : « bug lorsqu'on diminue la largeur puis qu'on ré-augmente » — une rangée du
répertoire restait trop courte, titre rogné en haut, date en bas. IRREPRODUCTIBLE sur Chromium
(sondes discrètes puis fines, 100 % et 130 % de taille du texte : rien) ; reproduit sur WebKit
SEUL, au redimensionnement CONTINU : quand un changement du nombre de colonnes d'une grille
`auto-fill` fait ré-enrouler la sous-ligne d'une rangée, WebKit ne regrandit pas la piste — le
contenu centré dépasse (titre +11 px, date +5 px, mesurés, aux valeurs exactes de la capture
utilisateur) et l'état corrompu PERSISTE, y compris après re-rendu.

Remède : à la TRAÎNÉE du redimensionnement (120 ms, accueil seulement), chaque
`.dir-grid`/`.qa-grid` passe par `block` puis `grid` dans la même frame — écriture-lecture-
écriture synchrones, aucun repaint intermédiaire, donc aucun clignotement — et WebKit recalcule
ses pistes. On ne paie pas un reflow par évènement pendant le geste : l'artefact transitoire de
Safari peut fugacement apparaître pendant la traînée et se répare seul 120 ms après la pause.
Vérifié à la sonde sur les deux moteurs et les deux réglages de taille : état final propre
partout, Chromium jamais affecté. Piège documenté dans AGENTS.md (ne pas retirer ce listener ;
re-mesurer sur WebKit à toute retouche des grilles).

Vérifié : 766 tests × 2 moteurs, a11y 301/301 sur Chromium ET WebKit, doctrine 112/112,
`npm run check`. Rien à rejouer côté serveur.

## [4.56.1] — 2026-07-28
### Les tuiles rejoignent la grille fluide du répertoire

Retour utilisateur immédiat sur la v4.56.0 : « la gestion de la largeur des tuiles en responsive
est extrêmement mauvaise pour toutes les transitions de taille ». Mesuré, et confirmé : les
tuiles « Épinglée(s) » avaient un nombre de colonnes FIGÉ (2 sous 780 px, 3 au-delà) — au
franchissement du seuil, la sidebar et le rail mangent ~330 px d'un coup et une tuile passait de
~360 px à **~140 px** ; et leur rythme ne coïncidait jamais avec celui des rangées du répertoire,
posées juste dessous.

**Une seule règle fluide, partagée** : `.qa-grid` adopte l'`auto-fill minmax(290px,1fr)` et la
gouttière 8 px de `.dir-grid`. Tuiles et rangées ont désormais la MÊME largeur à toutes les
fenêtres et s'alignent colonne pour colonne ; mesuré sur toute l'échelle — 320 → 290 px (1 col),
779 → 2 × 356, 780 → 1 × 451, 1000 → 2 × 332, 1460 → 3 × 372, 1620 → 4 × 317 : tout vit dans la
bande ~290-450 px, une transition ne change plus que le NOMBRE de colonnes, jamais l'échelle.

La question qui a ouvert le dossier (« pourquoi la bulle rétrécit au-delà de ~1480 px ? ») a sa
réponse documentée dans AGENTS.md : c'est la redistribution d'une grille fluide quand une colonne
de plus tient (3 × ~390 → 4 × ~296 vers 1520 px) — bornée par le minimum de 290 px, c'est le
comportement normal, à ne pas « corriger ».

Vérifié : 766 tests × 2 moteurs, a11y 301/301, `npm run check`, design system régénéré (la démo
n'impose plus un nombre de colonnes que le vrai CSS n'a plus). Rien à rejouer côté serveur.

## [4.56.0] — 2026-07-28
### L'accueil devient un « poste accès direct » : épinglées, répertoire A→Z, rail alphabétique

Refonte des listes d'aides ET de protocoles d'après la maquette « 2c — poste accès direct » du
canvas Claude Design « Accueil bibliothèques » (modèle du téléphone d'urgence : les favoris sous
le pouce, l'annuaire complet derrière, l'index de tranche pour y sauter).

### Trois étages à la place de la grille de cartes
- **« Épinglée(s) ★ »** — les fiches épinglées en TUILES (liseré de catégorie, code · catégorie,
  « ● En cours »). Libellé accordé au type et au nombre ; **les épinglées seules**, décision
  utilisateur « juste les favoris » — la fréquence d'usage reste un critère de tri de RECHERCHE,
  jamais de mise en avant ; aucune épingle → la section disparaît. Titre en 15 px borné à
  **3 lignes** puis ellipse (2 lignes tronquaient trop pour reconnaître la fiche ;
  `overflow-wrap:break-word`, pas `anywhere` qui coupait « Anaphylaxie » en plein mot) ; le nom
  accessible et l'info-bulle gardent le texte entier.
- **RÉPERTOIRE A→Z** — rangées compactes groupées par lettre (hors A-Z → « # », rangé en fin),
  tri alphabétique STRICT (l'épinglée a sa tuile — la hisser en tête de sa lettre casserait la
  lecture d'annuaire) ; sous 640 px, chaque lettre devient une liste à filets dans une carte
  (maquette mobile). Les rangées gardent l'épingle ☆, le statut en attente, « À revérifier »,
  « À compléter », la catégorie EN TOUTES LETTRES (la couleur d'une pastille n'est jamais seule)
  et la date de validation en forme COURTE (`fmtDateShort` — « Validation : » pèserait plus que
  la donnée sur une sous-ligne de 11 px). Le répertoire ne se pagine JAMAIS : le rail promet
  « A→Z sous le doigt », un « Afficher plus » ferait des lettres injoignables.
- **RAIL ALPHABÉTIQUE** — tap = saut à la lettre, GLISSER le long des lettres = parcourir
  (index iOS ; pointer capture). Dès 2 lettres ; s'il ne tient pas en hauteur il DISPARAÎT
  (jamais de lettres coupées ni de cibles < 24 px). En étroit il est FIXE, ancré entre le bas
  de l'en-tête (`--hdr-h`) et la tab bar — un centrage sur la fenêtre passait sous l'en-tête
  à 320×640, mesuré puis corrigé.

### Ce qui ne change PAS (décisions utilisateur explicites)
La recherche RESTE dans l'en-tête (champ statique : le focus survit aux re-rendus, raccourci
« / » — la grande recherche du corps de la maquette est écartée) ; le filtre catégorie FILTRE
(l'« estompage sans déplacer » de la maquette est refusé) ; en recherche, liste plate triée par
pertinence (épinglées > frecency > titre), extraits contextuels et pagination inchangés.

### Historique GLOBAL des sessions
Le compte « n sauvegardées » des cartes disparaît ; à sa place, la fenêtre Historique gagne un
mode « toutes les fiches » (chaque rangée nomme la sienne, cliniques et exercices toujours
séparés) : rangée « Historique des sessions (n) » en bas de la sidebar en large, lien du pied de
page en étroit — masqués à zéro session (aucun bouton mort). L'entrée PAR FICHE du menu ⋯ est
inchangée. `openSessHist()` sans argument = mode global `'*'`.

### Sous le capot
- Fonctions pures testées : `azLetter`/`azGroups` (lettre désaccentuée, table en
  `Object.create(null)` — la clé vient d'un titre saisi) et `qaPick` ; +10 tests (766 × 2 moteurs).
- L'ancien composant `.card`/`.cards` est PURGÉ (émissions vérifiées au grep, règle 14 ; démo
  `design/build.mjs` refaite ; `newTonal`, champ mort d'avant la refonte, retiré). Le bouton-titre
  GARDE le nom `.card-open` : quatorze harnais ouvrent une fiche par ce sélecteur.
- Périmètre accueil d'`audit-a11y` : `.dir-wrap,.azrail` remplace `.cards` — un sélecteur mort
  ferait passer l'accueil sans le mesurer (leçon v4.31.1). Le bouton-titre des rangées porte un
  padding 6 px compensé : sa BOÎTE atteint 29 px (l'ancien titre passait la mesure parce qu'il
  s'enroulait sur deux lignes ; le `::after` étendu, lui, ne se mesure pas).
- Vérifié : `npm run check`, 766 tests × Chromium + WebKit, a11y **301/301 sur les deux
  moteurs**, doctrine 112/112, zoom-scroll 6/6, zéro débordement horizontal à 320 px, clair et
  sombre. Rien à rejouer côté serveur.

## [4.55.5] — 2026-07-28
### Deux défauts signalés à l'usage — un menu qui tombait dans la barre, une attribution qui suivait la mauvaise personne

### Le menu ⋯ s'ouvrait DANS l'en-tête — dixième piège de cascade
Dès qu'un placard était posé (exercice ou invité), ouvrir le menu ⋯ ne produisait plus une
fenêtre flottante : il retombait **dans le flux de la barre**, qu'il rallongeait d'autant.

Le placard, pour faire passer le contenu au-dessus de sa hachure, levait **tous les enfants
directs** de l'en-tête en `position:relative; z-index:1`. Or `.more-menu` est un enfant direct
**et se positionne lui-même** : `header.bar.exo>*` vaut (0,2,1) contre (0,1,0) pour
`.more-menu{position:absolute}`. La règle décorative écrasait la règle structurelle.

**On retire l'exigence plutôt que de l'assortir d'exceptions.** Nommer le menu dans un `:not()`
n'aurait fait que déplacer le piège au prochain calque ajouté là — c'est la leçon de la v4.55.3,
une version plus tôt. `header.bar` porte déjà `position:sticky; z-index:20`, donc elle **est** un
contexte d'empilement : un `::before` en `z-index:-1` s'y peint au-dessus du fond de la barre et
sous tout son contenu, **sans qu'aucun enfant ait à être positionné**. On **enfonce** la hachure
au lieu de **lever** ses frères ; l'un ne demande rien aux enfants, l'autre les contraint tous.

`#crisisBand` garde l'ancienne mécanique, et ce n'est pas une inconséquence : il est
`position:relative` **sans `z-index`**, donc pas un contexte d'empilement — un `z-index:-1` y
passerait sous son propre fond et la hachure disparaîtrait. Ses enfants sont tous statiques.

### « Avancé par … » nommait l'hôte pour les gestes de l'invité
La mention était un drapeau **global** qu'un seul site du fichier remettait à zéro : `cxEnter`,
l'entrée sur complication. **Aucun avancement ordinaire ne l'effaçait.** Posée une fois —
typiquement par le backlog rattrapé à la jointure, où toutes les navigations de l'hôte défilent
d'un coup — elle **suivait ensuite l'invité de carte en carte** et attribuait à « Hôte » les blocs
qu'il venait lui-même d'avancer.

Encore un demi-chemin : un effacement écrit d'un seul côté. Le remède n'est donc pas d'ajouter les
N sites manquants — c'est de **supprimer le besoin de s'en souvenir**. La mention porte désormais
le **numéro de visite** que l'avance distante a créé et ne s'affiche que sur celui-là ; le premier
passage minté localement en porte un autre, donc elle disparaît **par construction**.

Elle est posée **dans `shareApplyAnchored`**, seul point où une navigation distante devient la
position courante. `onEvents` le manquait dans un cas (le drain de la file par `rmResume` n'y
repasse pas) et le posait dans un autre où il ne fallait pas : une navigation **refusée** par le
mode lecteur nommait déjà son auteur alors que rien n'avait bougé. L'annonce au lecteur d'écran
garde, elle, une variable **locale au lot** — elle n'a ni la même durée de vie ni la même
condition que la mention affichée.

### Ce que le diagnostic a écarté en chemin
Deux hypothèses ont été **mesurées puis abandonnées** avant d'arriver à la bonne, et c'est ce qui
a évité de « corriger » du code sain : l'attribution est juste quand la liste des participants
est à jour (« avancé par Infirmier », vérifié), et il n'y a **aucun écho** — l'hôte ne repousse
pas sous son nom ce qu'il vient de recevoir. Le défaut n'était ni dans la résolution serveur de
l'acteur (le secret l'emporte sur l'identité, y compris quand les deux appareils sont connectés au
même compte) ni dans le rebasage du diff.

### Vérification
**294/294 contrôles partage** (+14, sur les deux moteurs), 756 tests × 2 moteurs, 14 harnais verts
sur Chromium **et** WebKit, 301 contrôles d'accessibilité, 112/112 doctrine.

Les deux défauts réintroduits en font tomber **sept** ; fichier restauré à l'octet. **Un témoin a
dû être refait** : la première version de la sonde d'attribution avançait par `next`, nul sur le
dernier bloc de la fiche d'exemple — l'avance locale n'avait donc jamais lieu et les deux contrôles
suivants mesuraient du vide. C'est le témoin lui-même qui l'a signalé. De même, la hachure est
mesurée par son **image de fond** et non par l'opacité : sur un en-tête sans placard le
pseudo-élément n'a pas de `content`, et `getComputedStyle` rend alors l'opacité par défaut `1` —
un témoin fondé sur l'opacité aurait été vert des deux côtés.

**Rien à rejouer côté serveur.**

## [4.55.4] — 2026-07-28
### L'invité sait qu'il est invité — et un bouton pressé répond enfin

Les deux derniers signalements du lot. Avec eux, les dix remontés à l'usage sont traités.

### Le placard de l'invité
Il lisait « ■ Mode crise » — **exactement ce que lit l'hôte** — alors que sa situation est autre :
il **suit** une session qu'il ne conduit pas et qui peut s'arrêter sans lui. Le quai le disait déjà
par un jeton de sept caractères ; le bandeau le dit maintenant en toutes lettres, à l'endroit le
plus lu de l'écran : « **▪ Vous suivez** », hachure **bleue**, l'en-tête relayant « ▪ Suivi » au
pixel où le titre passe dessous.

**Même mécanique que le placard d'exercice, au trait près** — `::before` en fondu, relais au
défilement, enfants en `z-index:1`. Rien de neuf à inventer, donc rien de neuf à casser. Et **coût
nul en hauteur**, mesuré : c'est la seule condition qui vaille dans une zone où la rangée de
commandes n'a que 2,1 px de marge à 320 px.

Registre **bleu**, jamais l'ambre ni le rouge : suivre la session d'un collègue n'est ni une alerte
ni une vigilance, c'est un état. Le mot le porte ; la hachure ne fait que le rendre reconnaissable
d'un coup d'œil.

**L'exercice garde la priorité**, et ce n'est pas négociable : *« ceci est une répétition »* prime
sur *« vous suivez »* — le premier protège d'une méprise clinique, le second est une information de
rôle que le quai porte en permanence de toute façon. Un contrôle l'encode.

### Répondre à un geste n'est pas interrompre
La règle 11 — *« en session de crise, aucune notification flottante »* — vise ce qui **arrive** :
une erreur de synchro, un conflit, une nouvelle de fond, quelque chose qui s'impose à quelqu'un qui
n'a rien demandé, au pire moment. Elle ne visait pas la **réponse** à un bouton qu'on vient de
presser.

Or la file les retenait tous : taper « silencieux ? », ou « Partager la session » sur une fiche en
brouillon, ne produisait **rien du tout** — et le message surgissait plus tard, au retour à
l'accueil, détaché de son geste, donc incompréhensible.

Le troisième argument de `toast()` marque une réponse directe. Il est **explicite**, et non déduit
d'une proximité temporelle avec un clic : une nouvelle de fond qui tomberait dans la seconde suivant
un tap serait alors affichée par accident — exactement ce que la règle interdit. Quatre sites
marqués, tous atteignables pendant un soin.

### Vérification
**280/280 contrôles partage** (+9, sur les deux moteurs), 756 tests × 2 moteurs, 14 harnais verts,
301 contrôles d'accessibilité sur les deux moteurs, 112/112 doctrine. Les deux défauts réintroduits
en font tomber quatre ; fichier restauré à l'octet. Le contrôle du placard mesure l'opacité du
`::before` — pas la classe : c'est la hachure qu'on veut voir, pas l'intention de la poser.

**Rien à rejouer côté serveur.** Les dix signalements d'usage de ce lot sont traités.

## [4.55.3] — 2026-07-28
### Trois rognages que personne ne mesurait

Les trois défauts d'affichage signalés à l'usage, tous reproduits au pixel avant correction.

### Le titre décalé : neuvième piège de cascade, premier par `:not()`
Sur écran étroit, une règle transforme toute fenêtre en feuille pleine largeur et lui pose **18 px
de rembourrage haut**. Or « Se repérer » et « Consulter » se donnent `padding:0` — leur barre de
titre est `sticky top:0` et doit affleurer le bord.

Elles perdaient, et pas par l'ordre : `.ai-modal:not(.pdf-modal):not(.dlg-confirm) .ai-card` vaut
**(0,3,0)**, parce que **`:not()` compte la spécificité de son argument** — contre (0,2,0) pour
`:is(.plan-modal,.ref-modal) .ai-card`. Résultat mesuré : 18 px de fond nu au-dessus du titre, et
**65 px sur un iPhone à encoche** où `env(safe-area-inset-top)` s'ajoute — bande qui restait
visible au défilement, la barre étant collante.

On exclut désormais la **classe** `.sheet-full` plutôt que les deux fenêtres nommément : la
prochaine feuille plein écran héritera de l'exclusion au lieu de rejouer le défaut.

### La croix qui sortait du cadre
**110 px hors du cadre à 320 px**, 70 à 360, 40 à 390, 7 à 430 — et seulement sur écran **tactile**,
où « silencieux ? » et le bouton son montent à 44 px de cible. `.rt-head` est une rangée flex sans
retour à la ligne et dont rien n'est compressible : son contenu exige 331 px pour 221 disponibles.

Remède = le patron déjà éprouvé de la carte-bilan (v4.29.2) : conteneur `relative`, croix **ancrée**
en haut à droite, et un `padding-right` qui lui réserve sa place à toutes les largeurs. Le reste
s'enroule dessous plutôt que de la pousser hors de l'écran — on ne tronque pas un libellé de
commande, on lui donne une seconde ligne.

### La ligne d'Échelle qui sortait du plan
Débordement dès **quatre options à 320 px**, cinq à 390, six à 430, et jusqu'à **280 px dehors à
huit** — le titre de la décision étant écrasé à 0 px de large bien avant. Les renvois abrégés
(`FIBRIL→2 ASYSTO→3 …`) sont en `flex:none` et `nowrap` : leur largeur croît avec le nombre de
branches, sans borne.

On **enroule** plutôt que de tronquer. Dans un plan, une branche cachée est une branche qu'on ne
saura pas prendre — c'est la différence avec le quai, où l'on abrège et où l'on annonce « +n » :
ici la place existe, verticalement.

### Les contrôles ont dû être refaits, et c'est le point
Six contrôles permanents dans `audit-doctrine.mjs` (112/112, sur les deux moteurs). **La première
version restait verte avec les trois défauts réintroduits** : elle mesurait la fiche d'exemple —
deux options, donc jamais de débordement — et un contexte non tactile, où les cibles ne gonflent
pas. Elle ne rencontrait pas le défaut, donc elle ne le couvrait pas.

La version retenue **construit le cas** : une décision à huit branches, un contexte `hasTouch`, et
la mesure prise contre le bord **intérieur** du cadre — un bouton qui touche la bordure est déjà
coupé. Réépreuve : les cinq défauts réintroduits à l'identique en font tomber **huit** ; fichier
restauré à l'octet.

756 tests × 2 moteurs, 14 harnais verts, 301 contrôles d'accessibilité, 271/271 partage.
**Rien à rejouer côté serveur.** Restent deux signalements : le bandeau d'en-tête de l'invité et les
notifications retenues jusqu'à l'accueil.

## [4.55.2] — 2026-07-28
### Le menu ne suivait pas l'état du partage — et « Prendre la main » n'était nulle part

Trois signalements d'usage, deux causes. La première explique pourquoi la passation semblait sans
effet : **le geste n'avait pas de porte.**

### Un menu construit au rendu, dans un dispositif qui interdit de rendre
Les rangées du menu ⋯ sont bâties **au rendu** et stockées telles quelles. Or la règle 3 interdit de
re-rendre sur évènement distant — c'est elle qui empêche qu'un écran bouge sous le doigt de
quelqu'un qui coche. Conséquence : « Partage en cours **(n)** » gardait le compte du moment où la
fiche avait été ouverte, et **« Prendre la main » ne paraissait jamais**, puisqu'une offre arrive
par le réseau.

On mémorise donc le **constructeur** des rangées, pas seulement son résultat, et on le rejoue quand
l'état du partage change. Le menu vit dans l'en-tête, hors de `main` : **pas une ligne de la
checklist ne bouge** — vérifié, le nœud témoin est le même objet avant et après, à 0 px.

Et la rangée elle-même était **au mauvais endroit** : posée dans le menu de l'hôte, où sa condition
`Share.mode === 'guest'` ne pouvait jamais être vraie. Elle n'existait donc nulle part. Elle vit
maintenant dans le menu de l'invité, le seul où elle ait un sens.

### Un lien mort qui laissait agir sans rien dire
Après « Couper », l'invité ne pouvait plus cocher — mais il pouvait encore **incrémenter un
compteur**. Le geste ne partait pas, et **rien ne le lui disait**. C'est mot pour mot le pire mode
de défaillance nommé au plan : *« un invité qui continue de cocher dans le vide en croyant
contribuer à une réanimation en cours »*.

La garde couvrait les gestes **réservés** ; il en manquait une pour le cas où le **lien est mort**,
qui n'a rien à voir avec le rôle. Toute mutation est désormais refusée et **annoncée** sur `#srLive`
— seul canal admis pendant un soin (règle 11 : ni modale, ni banderole).

**`detached` n'en fait pas partie, et c'est délibéré** : celui qui a poursuivi seul travaille sur
*sa* session. Lui refuser ses gestes reviendrait à lui retirer le repli hors dispositif qu'on vient
de lui donner (AC 120-64 §9.a). Un contrôle l'encode.

### Vérification
**271/271 contrôles partage** (+8, sur les deux moteurs), 756 tests × 2 moteurs, 14 harnais verts,
301 contrôles d'accessibilité, 94/94 doctrine. Les trois défauts réintroduits à l'identique en font
tomber trois ; fichier restauré à l'octet.

Deux sondes ont encore dû être corrigées avant de conclure : l'une cherchait un bouton de compteur
dans un panneau **replié** — elle ne mesurait rien et concluait que le geste était bloqué ; l'autre
lisait la zone d'annonce **sans la vider**, et y trouvait le message précédent. Même travers que
depuis le début de ce chantier : mesurer le mécanisme au lieu de la propriété.

**Rien à rejouer côté serveur.** Restent trois signalements : le bandeau d'en-tête de l'invité, les
trois défauts de mise en page, et les notifications retenues jusqu'à l'accueil.

## [4.55.1] — 2026-07-28
### CORRECTIF — les assertions ajoutées en v4.55.0 lisaient une table sous le rôle `anon`

`ERROR: 42501: permission denied for table shared_sessions`. Les trois vérifications que la v4.55.0
ajoutait au § 14.5 — « nommer ce qui doit passer plutôt que compter » — interrogent la table en
direct, alors que le bloc est encore sous le rôle **`anon`**, posé au § 14.3 et jamais rendu.

Correction : on reprend les droits le temps de la lecture, puis **on restitue le rôle exactement
comme on l'a trouvé** — les sections suivantes s'appuient dessus.

### Le troisième rejeu perdu, et le garde-fou qui ferme cette famille
C'est la troisième fois qu'une erreur SQL vous coûte un aller-retour : un `$$` mutilé (v4.44.1), une
variable non déclarée (v4.54.1), et maintenant un accès de table sous un rôle sans privilèges.
Toutes trois ont la même cause de fond : **`supabase/*.sql` n'est ni servi ni chargé par les
tests**, sa seule épreuve était le collage dans l'éditeur.

`check-sql.mjs` gagne un troisième contrôle statique. Il est **volontairement borné à `anon`** :
ce rôle n'a aucun privilège de table par construction — c'est tout l'objet du § 13 —, donc toute
lecture directe pendant qu'il est actif est une erreur **certaine**. Sous `authenticated`,
interroger une table est légitime, et c'est même ainsi qu'on prouve que la RLS filtre (le § 14.19
lit l'historique d'Alice sous Bob et attend zéro ligne). Une règle plus large aurait produit des
faux positifs **sur les tests mêmes qui font le travail** — un garde-fou qui crie sur du code juste
finit ignoré. Les appels de fonction ne comptent pas : `share_join`, `share_pull` et `share_push`
sont `security definer`, et c'est précisément leur raison d'être.

**Vérifié capable d'échouer** en réintroduisant le défaut vécu à l'identique : il nomme la table, la
ligne, et le remède. Fichier restauré à l'octet.

`schema.sql` de la v4.55.0 était correct et **n'a pas à être rejoué** ; **`rls-tests.sql` est à
rejouer**. 756 tests × 2 moteurs, 14 harnais verts, `npm run check` 6/6.

## [4.55.0] — 2026-07-28
### Le scribe conduit — j'avais mal lu ma propre source

Objection d'usage, et elle porte : le médecin partage **pour se libérer les mains** — faire des
gestes, téléphoner, parler à l'équipe. Si un infirmier demande au scribe « c'est quoi les étapes
d'après ? mets le minuteur en pause, il reprend un rythme », le scribe ne pouvait rien faire, et le
médecin devait reprendre son téléphone pour valider avant de repasser la main.

### Ce que la source dit vraiment
AC 120-71B §5.2.2.1 — « one crewmember reading the checklist and the second confirming and
responding » — décrit une répartition de **la parole**, pas un système de permissions. Et dans ce
modèle, **c'est celui qui lit qui fait avancer la liste** ; le lead est celui dont les mains sont
prises. J'avais transposé l'inverse.

Les autres sources convergent : la **SFAR** (« le lecteur : sa seule tâche est de lire et de
**guider** »), l'**ECAM** (le pilot monitoring actionne l'ECP, le pilot flying pilote), et surtout
**McEvoy 2014** — 99,5 % contre 70 % d'adhérence, la meilleure donnée du dossier — où **le lecteur
tenait l'unique appareil**. La conception précédente empêchait exactement la configuration la mieux
documentée.

Et le critère juste était **déjà écrit dans ce dépôt**, pour `mark_void` : « annuler CONSERVE,
décocher DÉTRUIT — ce n'est donc pas une action destructrice, et la règle qui réserve celles-ci au
lead ne s'y applique pas. » Naviguer est append-only ; arrêter un minuteur conserve son `elapsedMs`.
Rien ne les réservait.

### La nouvelle ligne
| Ouvert au scribe | Réservé |
|---|---|
| cocher · constater · écart · incrémenter · armer · repère | **décocher** — efface une information |
| **avancer · choisir une branche · terminer un bloc** | **remettre à zéro** — efface un décompte que personne ne restitue |
| **arrêter un minuteur** · entrer sur une complication | **terminer le partage** · dater le début du soin |

**L'objection d'ambiguïté** (§5.5, « qui fait quoi », qu'Airbus supprime par un ECP unique) reçoit
la réponse constante du projet : **on n'interdit pas, on annonce.** Une avance venue d'en face pose
une mention « avancé par ‹rôle› » sur la carte courante, à côté de « Vous êtes ici » — même
information, vue par l'autre angle. Elle s'efface au geste de navigation suivant.

### Le lecteur était une troisième copie, jamais recensée
Signalé aussi : « pourquoi l'invité peut passer de bloc en bloc en mode lecteur mais pas sur la
page ? ». C'était vrai — `data-rmnext` et `data-rmopt` sont les mêmes verbes que `data-ovnext` et
`data-ovopt` sous d'autres noms, et la liste ne les nommait pas. Ce n'était **pas** un défaut de
portée (la garde en capture atteint bien `#readerMode`, prouvé en injectant `data-plgo` sur un de
ses boutons) mais de **prédicat**.

Trois choses en sont sorties, indépendantes du redécoupage :

- **`data-rmok` écrivait `state.checked` en direct**, sans passer par le prédicat unique. La
  doctrine annonce **deux** copies du cœur de cochage ; le lecteur en était une **troisième**.
  Mesuré : un invité au lien **arrêté** cochait quand même depuis le lecteur alors que le même
  geste était refusé sur la page.
- **Huitième piège de cascade du projet, second par spécificité** : `#readerMode .rm-ok` porte un
  **id** (1,1,0) et l'emportait sur `body.share-scribe :is([data-rmnext])` (0,2,1). Le geste était
  bloqué, mais le bouton restait vert plein, 72 px, graisse 800 — il **invitait** à un geste refusé.
- **Une émission refusée laissait le miroir divergent en silence** : la base de diff avance *avant*
  l'émission, si bien qu'un genre refusé n'était jamais renvoyé, même après promotion. Le miroir se
  déclare désormais périmé et redemande tout.

### Deux correctifs d'usage
**L'intitulé du journal ne se propageait pas.** `shareDiff` ne comparait que l'annulation d'un
repère : **étiqueter après coup** — le geste normal, puisque « Noter l'heure » ne demande rien — ou
corriger l'heure n'émettait rien. En le réparant, un second défaut est apparu : la réception
**empilait** un repère déjà connu au lieu de le mettre à jour ; le correctif seul aurait doublé la
ligne. Un test encodait le défaut (son couple de comparaison changeait la référence *et*
l'annulation) — variable isolée.

**Couper celui qui tient la main la rend à l'hôte.** Après « donner la main » puis « couper », le
partage gardait un lead révoqué et un hôte resté scribe : plus personne pour conduire, l'état que
l'invariant 1 interdit (« jamais deux, **jamais zéro** »). Ce n'est pas bloquant — les gardes de
l'hôte sortent sur `mode !== 'guest'` — mais faire reposer un invariant affiché sur la porte de
sortie d'une garde, c'est le laisser dépendre d'un détail d'implémentation.

### Le garde-fou qui manquait
`SHARE_KINDS_ANY`/`_LEAD` et `share_kind_allowed` sont **la même règle en deux langages**. Elles ont
divergé : le redécoupage a été porté des deux côtés, mais l'assertion qui l'éprouve ne l'a pas été —
et le défaut n'est apparu qu'au collage dans l'éditeur SQL. Une divergence est **silencieuse et
asymétrique** : client plus permissif, un geste part et le serveur le jette sans que l'auteur le
sache ; serveur plus strict, un geste légitime est refusé sans raison lisible.

`check-sql.mjs` compare désormais les deux listes à chaque commit. **Vérifié capable d'échouer** en
reproduisant la divergence exacte de cette version (serveur redécoupé, client en arrière) : il nomme
les quatre genres des deux côtés ; fichier restauré à l'octet.

### Vérification
756 tests × 2 moteurs (+9), **263/263 contrôles partage** (+13, sur les deux moteurs), 14 harnais
verts, 301 contrôles d'accessibilité, 94/94 doctrine. Quatre contrôles du harnais encodaient
l'ancienne ligne : retournés plutôt que supprimés, ils affirment la nouvelle et disent pourquoi.
Quatre sondes ont dû être corrigées avant de rien conclure — l'une relevait les boutons **avant**
d'ouvrir leur panneau, une autre cochait « tant que Continuer n'existe pas » alors que le bouton est
rendu d'emblée : elle mesurait la règle d'avancement, pas le bridage.

**`supabase/schema.sql` est à rejouer** (`share_kind_allowed` change), puis `rls-tests.sql`.

## [4.54.2] — 2026-07-28
### CORRECTIF — l'historique synchronisé de la v4.54.0 ne synchronisait rien

Signalé à l'usage, et exact sur les trois points : la bascule ne suivait pas d'un appareil à
l'autre, les sessions antérieures à l'activation ne montaient pas, celles terminées après non plus.
**La table existait, les politiques RLS étaient vertes, la bascule s'allumait — et pas une ligne ne
partait.** Une fonctionnalité entièrement livrée, entièrement inerte.

### Une cause et demie
`_pushTable` ne pousse que les objets portant `dirty`, et **aucun site n'en posait jamais sur une
session**. Explique les deux symptômes de fond. Le troisième — la bascule qui ne suit pas — venait
d'un oubli distinct : le réglage n'entrait pas dans les préférences synchronisées, alors que le
vocabulaire personnel ajouté à la même version, lui, y entrait.

Le marquage vit désormais au **point d'étranglement de l'écriture** (`_putSessionSafe`), comme
l'émission du partage vit dans `persistLive` : toute mutation ajoutée demain sera couverte sans
qu'on y pense. La pierre tombale de la suppression y passe aussi — elle posait ses champs à la
main, ce qui rendait fausse, dès la ligne où elle était écrite, la doctrine « ici, et nulle part
ailleurs ».

### Deux pièges que la contre-expertise a trouvés, et qui auraient annulé le correctif
**`updatedAt` doit être posé en même temps que `dirty`.** Une session n'en portait pas — seulement
`savedAt`, qui ne bouge plus après l'archivage. Posé seul, `dirty` aurait fait gagner
**inconditionnellement** la copie distante à la résolution du dernier écrivain (`savedAt > 0`,
toujours vrai) — et **effacé la trace do-verify de chaque session à la première synchro**. Le
correctif du push, seul, aurait donc détruit des données.

**Le rattrapage ne peut pas se garder sur une transition.** Qui a activé l'option en v4.54.0 —
quand elle ne poussait rien — a déjà la clé à « 1 » : il ne reverra **jamais** le passage
éteint→allumé. Un rattrapage gardé par cette transition aurait donc raté **exactement les personnes
qui ont signalé le défaut**. La garde est une clé durable, et un réveil de synchro suit le
balayage : quand l'option est apprise par le pull des préférences, la poussée de la même passe est
déjà sortie par son garde d'entrée.

### Vérification
Nouveau harnais **`scripts/audit-historique.mjs`** — quatorzième —, **16/16 sur les deux moteurs**.
Il mesure ce qui **partirait** (transport bouchonné) plutôt que ce que le code déclare : rien sans
l'option, l'existant rattrapé, une session terminée après qui part, la trace do-verify qui reste et
dont l'absence est dite, une session **vive** qui ne part jamais, le réglage qui voyage et qu'une
préférence distante éteint — et le cas « déjà activé en v4.54.0 », qui a son propre contrôle.

**Vérifié capable d'échouer** : les trois défauts réintroduits à l'identique en font tomber six,
fichier restauré à l'octet. Une sonde a dû être corrigée en route — elle avait perdu son bouchon de
transport et accusait l'application de son propre oubli. 747 tests × 2 moteurs, 14 harnais verts,
301 contrôles d'accessibilité, 250/250 partage. **Rien à rejouer côté serveur.**

## [4.54.1] — 2026-07-28
### CORRECTIF — `rls-tests.sql` de la v4.54.0 ne s'exécutait pas, et rien ne pouvait le dire

Signalé au rejeu : `ERROR: 42703: column "v_share" does not exist`. Les trois sections ajoutées en
v4.54.0 (§ 14.15 à 14.17) employaient une variable qui n'existe pas dans le bloc — les conventions
de nommage du fichier n'avaient pas été relues avant d'y écrire.

**Deuxième rejeu perdu par la même famille de faute** (après le `$$` mutilé de la v4.44.1), et pour
la même raison de fond : `supabase/*.sql` n'est ni servi, ni chargé par les tests — sa seule épreuve
est le **collage dans l'éditeur SQL**, donc sur une instance réelle. Pire, PostgreSQL ne signale une
variable inconnue qu'à l'**exécution de la ligne fautive** : un test placé en fin de bloc casse
après trois minutes de travail réussi, et laisse croire que le reste est en cause.

### Les sections sont désormais AUTONOMES
Elles ouvrent leur propre partage et font rejoindre leur propre participant, au lieu de s'appuyer
sur l'état laissé par les tests précédents. Une assertion qui dépend de ce qu'un test antérieur a
bien voulu laisser derrière lui casse au premier réordonnancement — et c'est exactement ce qui
vient d'arriver. Un préalable explicite y a été ajouté : le § 14.12 remplit le quota de partages
vivants d'Alice, il faut donc les expirer avant d'en ouvrir un neuf, sinon l'ouverture échouerait
**pour une raison qui n'a rien à voir avec ce qu'on mesure**.

Deux assertions s'y ajoutent, qui manquaient : § 14.18 (la passation s'annonce des deux côtés) et
§ 14.19 (l'historique de sessions ne se prête pas — Bob ne lit ni n'écrit celui d'Alice).

### Le garde-fou qui aurait attrapé cela
`check-sql.mjs` collecte les variables **déclarées** d'un bloc `do $$ … declare … begin`, collecte
celles qui y sont **employées**, et compare. Statique, donc instantané, donc joué à chaque commit —
là où l'erreur coûtait jusqu'ici un aller-retour complet sur une instance de production.

**Vérifié capable d'échouer** en réintroduisant le défaut vécu à l'identique (`v_share`) : le
contrôle le nomme et donne sa ligne ; fichier restauré à l'octet. Il ne prétend pas remplacer un
analyseur plpgsql — il attrape la faute qui a été commise, ce qui est le seul critère qui vaille.

`schema.sql` de la v4.54.0 était correct et n'a pas à être rejoué ; **`rls-tests.sql` est à
rejouer**. 747 tests × 2 moteurs, 13 harnais verts.
