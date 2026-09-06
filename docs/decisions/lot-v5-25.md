# Lot v5.25 — l'écran d'entrée d'une aide se lit comme un écran de démarrage (A330)

> Fichier normatif, suite de [`lot-v5-24.md`](lot-v5-24.md) (A327-A329). Les numéros A sont des
> adresses : ne jamais renuméroter. Demande de l'auteur (06/09/2026) : « améliorer la structure de
> l'écran de démarrage d'une aide — comprendre que c'est juste un écran de démarrage, que l'action
> se situe après ; le plan n'est qu'un plan ». Maquettes itérées sur canvas (Claude Design), trois
> directions puis cinq reprises de la retenue ; ce fichier consigne AUSSI ce qui a été refusé,
> pour qu'on ne le repropose pas.

## A330 — trois chapitres, un aperçu à plat, rien ne « démarre » sauf le chrono (v5.25.0)

**Mesuré avant** (v5.24.2, fiche ACR d'exemple, 390 px). L'écran d'avant session ressemblait déjà
à la session : « PRISE EN CHARGE » en titre d'étage, des rangées BLANCHES numérotées à pastille
(la grammaire de la colonne d'orientation en session), des compteurs « 0/4 » qui parlent de
progression, des renvois en bleu qui invitent au tap, et le seul mot qui disait le contraire —
« inerte » — à 11 px, gris clair, à droite. Le rail « Ce qui démarrera · 3 » affirmait que le
cycle RCP et l'adrénaline PARTAIENT avec la session : faux, ce sont des minuteurs À DISPOSITION.
Tableau et Schéma, deux boutons pleine largeur sous « Ne pas oublier », étaient les contrôles les
plus voyants après le quai.

**Ce qui change.**

- **Trois chapitres de MÊME niveau, sans numéro** (`preChapH`, `.pre-ch`, 15 px/700) : les
  intitulés qui existaient SORTENT de leurs cadres et deviennent les chapitres — « ■ Quand
  l'utiliser » (rouge, le cadre blanc ne porte plus que les critères et la porte de sortie),
  « ■ Ne pas oublier » (rouge, la bande ne porte plus que les items), « Parcours » (noir,
  sous-ligne « Aperçu — se déroule après le démarrage. »). Chacun s'ouvre par un filet et un blanc
  (20 px, ou le bas d'étage de 20 px) ; le premier, sous la méta, n'a pas de filet. Les titres
  sont des `role="heading"` de niveau 2. En session, rien ne change : `.conf-block` reprend son
  dépliant « Diagnostic confirmé », `.forget-strip` son bouton `.fs-k` replié.
- **Le plan est un APERÇU À PLAT** (`ovPlanLadderHtml(…,{flat:true})`, `.pre-lad.flat`) : ni
  carte, ni pastille, ni « 0/4 » ; numéro, titre et renvois gris ; la rangée de décision se tait
  quand toutes ses options portent un libellé (les étiquettes de branche disent déjà « oui → 3 ·
  non → 4 ») ; rangée de 32 px, plancher hors crise, toujours dépliable. Le titre « Parcours · n
  blocs » et le mot « inerte » ont disparu (`.pre-head`/`.pre-t`/`.pre-inert` purgés). Sur
  téléphone, « Surveiller ensuite » ne s'affiche plus (`noWatch`) : il reste au rail, où l'on
  s'oriente.
- **Tableau / Schéma** vivent SOUS le titre « Parcours », à largeur de contenu, alignés à gauche
  (plus d'étirement à parts égales sous 430 px) ; hauteur de cible inchangée (44 px).
- **Le cockpit (≥ 1200)** prend la même grammaire dans sa colonne de gauche : chapitre
  « Parcours », les deux boutons, l'aperçu à plat SANS « ICI » (`cur:false` — on n'est nulle part
  avant le soin ; le rail en affichait un), « Surveiller ensuite » gardé. L'étage central n'a
  alors pas de corps. Entre 780 et 1199, deux colonnes 564 + 280 comme avant : le chapitre reste
  dans la colonne principale.
- **Rien ne démarre sauf le chrono.** Le rail « Ce qui démarrera » devient « En session » : chrono
  « démarre avec la session », minuteurs « 2:00 cyclique, à lancer ». Sur téléphone la ligne
  « 5 blocs · 2 minuteurs · … » devient « Minuteurs à disposition en session : Cycle RCP 2:00 ·
  Adrénaline 4:00. » (`carryLineHtml` ne porte plus que les minuteurs, nom et période ; rien sans
  minuteur ; `carryParts` reste le calcul de l'atelier d'import, A130 — la phrase d'entrée a
  divergé À DESSEIN, elle ne juge pas une fiche, elle prépare un soin).
- **Le sur-titre dit l'état en mots** : « Avant la session · adulte », encre neutre (`.brand-sur.pre`),
  dans le logement que « ■ Mode crise » prend au premier geste — jamais chez l'invité, jamais en
  aperçu d'essai, seulement pour une fiche à algorithme.
- **La queue** (`.pre-tail`) : notes locales à plat, note personnelle, pied de stockage, sous un
  filet, hors chapitres. La porte « Le tableau ne colle pas ? → n diagnostics » passe à l'encre
  normale et au corps de texte : sur l'écran dont la question est « est-ce le bon cas », elle n'est
  pas hors chemin.

**Mesuré après** (390 px) : méta 21 px, chapitre 1 à 126 px, carte 170 px, chapitre 2 à 339 px,
bande 136 px, chapitre 3 à 560 px, boutons 172 et 174 × 44 px au ras de la marge gauche, quatre
rangées de 32 px sans fond ni bordure, ligne des minuteurs, queue sous filet ; page de 1 192 px
pour 1 334 avant. À 900 : grille 564 + 280, boutons 102 et 104 px de large. À 1440 : grille
240 + 804 + 320, chapitre « Parcours » et boutons dans `.read-plan`, aucun `.pl-here`, zéro `.cp-h`.

**Ce que l'auteur a REFUSÉ pendant l'itération** — ne pas le reproposer :
- deux temps « ○ Avant d'entrer / ● Après le démarrage » avec glyphes, filet de sommaire à gauche,
  « 4 étapes » en colonne de droite (« beaucoup de textes encadrés et glyphes différents ») ;
- la direction B (plan replié derrière une rangée « Aperçu du parcours · 4 blocs ▸ ») ; la
  direction C (bande d'état sous l'en-tête + plan en cadre pointillé atténué) mise de côté ;
- des titres de chapitre qui doublonnent l'intitulé du cadre (« Confirmation diagnostique »,
  « À garder en tête ») ; des chapitres numérotés ; une perte de densité (titres à 17,5 px et
  30 px de blanc) ; Tableau / Schéma en liens texte à droite du titre ; un chapitre « Sur place »
  pour les notes locales (« remets-le où il était »).

**Garde-fous.** `audit-doctrine`, section « CHAPEAU · condition d'entrée → memory items → bouton »
(390 et 1280) : Tableau/Schéma SOUS le titre « Parcours » et AU-DESSUS de la première rangée,
zéro `.cp-h` avant la session, rangée compacte 32 ≤ h < 44 inchangée. `tests.html` Q4 réécrit sur
la nouvelle phrase (à disposition, jamais « démarre », libellé échappé). `check-classes` a fait
purger `.conf-eh` (épitaphe posée) ; `check-space` a ramené trois retraits sur l'échelle fermée.

**Addendum v5.25.1 — respiration symétrique de la carte « Quand l'utiliser » (signalé sur main).**
Mesuré à 390 px : sans différentiel, 15 px au-dessus du premier critère contre 4 px sous le dernier —
le titre parti au-dessus du cadre (A330), le `padding-bottom:0` de la carte n'était plus compensé
que par le lien « Le tableau ne colle pas ? », absent quand la fiche n'a pas de différentiel. La
carte porte 6 px en haut ET en bas, la liste 4/4 ; le lien, quand il existe, reprend les 6 px du
bas (`margin-bottom:-6px`) pour rester au ras du cadre. Mesuré après : 15/15 sans lien, lien au ras
(1 px de bordure) avec — hauteur de carte inchangée dans le cas avec lien.
