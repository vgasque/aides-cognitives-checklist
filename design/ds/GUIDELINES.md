# Aides cognitives — Lignes directrices du design (v4.55)

PWA médicale monofichier, utilisée **en urgence vitale, sous stress** : la clarté et la
robustesse priment sur toute considération esthétique. Tout choix de design se juge à
l'aune d'une question : *est-ce lisible et actionnable par un soignant en crise ?*
La grammaire s'inspire des normes aéronautiques (ECAM/QRH) : état annoncé en texte,
jamais la couleur seule, conditions d'entrée visibles, anti-accident systématique.

## Source de vérité

Les tokens (`tokens/tokens.css`) et le CSS des fiches de ce projet sont **extraits
automatiquement** de `index.html` par `design/build.mjs` — ne jamais les éditer ici.
Toute évolution se fait dans l'app, puis se resynchronise.

**Ce fichier-ci fait exception : il est rédigé à la main.** Aucun script ne le régénère,
donc rien ne signale sa péremption — il était resté à la v4.34 pendant vingt et une
versions, dont tout le chantier du partage de session. À relire à chaque lot qui touche
une surface.

## Couleur — sémantique FIXE

- **Aucune couleur hex hors DÉCLARATION DE TOKEN** (propriété `--…`, où qu'elle vive :
  `:root`, thème sombre, blocs `data-accent`) et `PALETTE` (13 teintes de catégories).
  La règle n'est plus déclarative : `scripts/check-colors.mjs` la fait respecter à chaque
  commit. Seule exception listée, les nuanciers littéraux `.acc-sw` — et l'exemption
  porte sur la **règle**, pas sur la ligne (un hex collé en fin de ligne était admis, il
  ne l'est plus).
- `--primary` (**bleu clinique**) = identité, action.
- `--ok` (vert) = **confirmation / issue positive** : étape cochée (`--done-*`),
  « Continuer » actif, fin d'algorithme, pastilles d'état ok, sessions vives.
  `--ok-rgb` en porte la version décomposée : `--pulse` en était la copie décimale
  EXACTE dans les deux thèmes, donc une seconde source de vérité invisible au garde-fou
  (une déclaration de token n'est jamais signalée).
- `--critical` (vermillon) = erreur, destruction **et arrêt d'un processus vivant**
  (« Terminer » une session stoppe les minuteurs : registre du rouge « raccrocher » —
  ne pas le « corriger » en ambre).
- `--verify` (ambre) = attente, avertissement, décision — y compris le minuteur ÉCHU
  (`--verify-bd`/`--verify-hi` : c'est une attente, pas une erreur). Jamais l'inverse
  de `--critical`.
- **TROIS ROUGES distincts, jamais fusionnés** : `--critical` = texte/icônes ;
  `--critical-bd` = bordures des cartes et bandeaux rouges ; le rouge « Urgences » de
  PALETTE (#b6382f) = couleur de CATÉGORIE (liseré/pastille), jamais un signal d'alerte.
- `--soft` = **décoratif seulement** (jamais une couleur de texte) ; texte secondaire =
  `--ink-soft` (4.5:1). Cases à cocher et bordures de champs = `--line-strong` (3:1).
- `--link` = liens ET temps d'un minuteur en cours (accent froid). En thème SOMBRE,
  `--primary` est un **remplissage** (3,75:1 en texte) : l'accent TEXTE y est `--link`,
  seul admis pour un numéro ou un libellé accentué.
- `--alert-*` (ambre vif) = banderoles d'alerte, volontairement distinct de `--verify`.
- `--alarm` (chaud) = alarme ou jauge du geste destructif UNIQUEMENT.
- `--rt-*` : ardoise FIXE des toasts (identique dans les deux thèmes). Le panneau
  minuteurs, lui, **suit le thème** depuis V5.
- Statuts éditoriaux **achromatiques** : pilule `.status-tag` unique (△ À relire,
  ○ Brouillon, △ À revérifier — `--tag-bg`/`--tag-ink`). **« ✓ Validé(e) » ne s'affiche
  PAS là où la DATE de validation est visible** : la date dit la même chose en plus
  précis, et une carte ne porte un statut que si elle ATTEND quelque chose. Sans date, la
  pastille reste — sinon rien ne distinguerait une fiche validée d'une fiche sans statut.
  Sur les cartes d'accueil, la pilule de catégorie est NEUTRE : la couleur de catégorie
  ne vit que dans le liseré.
- Pastilles d'état (compte/synchro) : ok = `--ok`, attente = `--verify`,
  erreur = `--critical`, inactif = `--line-strong`, synchro EN COURS = anneau tournant
  (activité ≠ alerte).
- Fond des champs de saisie = `--input-bg`, partout.
- Contraste : texte ≥ 4.5:1, composants ≥ 3:1 (WCAG 2.2 AA), dans les DEUX thèmes.
- La couleur n'est **jamais le seul canal** : toujours texte, forme ou position en plus.
- **Modes de contraste système.** Sous `forced-colors` (Windows High Contrast) : filet
  MINIMAL — `.acct-dot`, `.cat-dot` et `.seg-pill` gardent leur couleur
  (`forced-color-adjust:none` : l'information EST la couleur) ; le reste s'appuie sur
  « la couleur jamais seule ». Sous `prefers-contrast: more`, `--ink-soft` passe à
  `--ink` et `--line` à `--line-strong` — **bloc déclaré en FIN de feuille** : à
  spécificité égale il doit gagner sur les tokens des deux thèmes.

## Couleur d'accent par utilisateur (v4.5)

5 accents prédéfinis AA (sarcelle, violet, indigo, framboise, ardoise) + bleu clinique
par défaut. **Connecté seulement** (l'accent tombe à la déconnexion). Portée : l'accueil
ENTIER + l'EN-TÊTE de toutes les vues (l'identité reste visible partout) ; le **contenu
clinique** (fiches en crise, protocoles, éditeurs) **reste bleu clinique**. Jamais de
vert/ambre/rouge en accent : les registres sémantiques sont réservés.

Le **logo de marque** (accueil seulement) est posé en **masque CSS** sur un aplat de
`currentColor`, donc l'ENCRE : il suit le thème tout seul et ne concurrence AUCUN accent
— l'accent colore déjà la loupe, les boutons et les liens, une marque neutre s'y lit
comme une marque.

## Typographie

- Police système (`--sans`) ; mono (`--mono`, tabular-nums) réservée aux valeurs qui
  défilent (chronos, compteurs, numéros d'étape) et aux codes courts.
- **Plancher : 11 px** pour tout texte courant ; seules les pilules-capitales à forte
  graisse (`.status-tag`, `.tm-label`, 10.5 px / 700+) y dérogent (spec canvas).
- **Un seul registre de titres de section** : petites capitales grasses (`.block-h`),
  repris par les titres du contenu rédigé (`.md-h1`/`.md-h2`). Pas de nouveau style de titre.
- Le contenu (15–16 px) reste plus grand que ses titres de section.
- **Champs ≥ 16 px sur écran tactile** : sous 16 px, Safari iOS zoome la page au focus et
  les taps se perdent. Un compact < 16 px n'est admis qu'au pointeur fin.

## Saillance

- **Un seul bouton rempli** (`--primary` plein) par écran. Si deux actions coexistent,
  la moins critique passe en tonal (`--primary-soft`).
- Grammaire des boutons de gestion : **pointillé** = créer, **contour** = gérer /
  secondaire, **plein** = action primaire.
- En lecture, toutes les actions secondaires vivent dans le **menu ⋯** (rangées 44 px,
  séparateurs entre groupes, action destructrice DERNIÈRE et rouge — jamais première).
  **Ordre = logique ECAM E/WD → SD** : la conduite EN COURS d'abord (Complications, mode
  lecteur, Se repérer, Schéma, Consulter), puis le cycle de vie de la session, puis la
  gestion, puis les exports. **Jamais deux entrées d'un même menu avec le même dessin**,
  ni deux dessins quasi identiques côte à côte.
- En crise, le chrome s'efface : aucune notification flottante qui ARRIVE, une seule zone
  fixe en haut, jamais en bas.

## Interaction

- Cible tactile ≥ 32 px ; **≥ 44 px pour les contrôles du mode crise**. Quand le
  contrôle visuel est plus petit (36–40 px), halo cliquable en `::after`.
- Tout élément interactif : `:focus-visible` (outline 2 px `--primary`) + équivalent
  clavier (Entrée/Espace). Le focus ne doit **jamais être masqué par une couche
  collante** (WCAG 2.2 § 2.4.11) : le défilement induit par le focus est celui du
  NAVIGATEUR, il ne se pilote que par `scroll-padding-top`.
- Action destructrice en crise = geste **« maintenir »** (jauge `--alarm` qui se
  remplit), jamais un simple tap ; la réinitialisation d'un minuteur ANNONCE ce qu'elle
  redonnera (« ↺ 05:00 »).
- **Garde temporelle 700 ms** (`.guarded`, opacité réduite) entre deux boutons
  « retour » empilés — un double-tap ne doit jamais franchir deux niveaux (ECAM). La
  même garde couvre le retour SYSTÈME (geste Android), qui emprunte le chemin de
  l'affordance visible plutôt qu'un routage parallèle.
- Un bouton désactivé n'est jamais muet : il DIT pourquoi et combien il reste
  (« Cochez les étapes restantes (2) ») ; actif, il ANNONCE sa destination
  (« Continuer — réévaluation à 5 min → »).
- Les éditeurs s'auto-enregistrent (brouillon « fantôme » restaurable) : « ‹ Retour »
  remplace « Annuler ».
- **Un sélecteur segmenté se GLISSE** : la pastille se laisse traîner au doigt (seuil
  6 px, commit au relâchement seulement). Elle suit le doigt même sous
  `prefers-reduced-motion` — une manipulation directe EST le geste, pas un mouvement
  autonome ; seul le rattrapage final passe par la transition.
- **La graisse ne change pas avec l'état** dans un segmenté : 800 contre 700 élargit le
  mot et décale les DEUX libellés à chaque bascule. L'état est porté par la pastille et
  la couleur.
- Tous les contrôles portent `touch-action:manipulation` (supprime le délai double-tap
  de Safari iOS).

## Grille & formes

- **320 px est SERVI** (v4.43.0) — c'est le plancher de WCAG 1.4.10 « Reflow », et donc
  la largeur à laquelle toute nouvelle addition au chrome se mesure. Deux surfaces y
  rognaient en silence avant qu'on ne le décide. On rend les pixels par la **recette des
  écarts et rembourrages**, jamais par un renommage ni une seconde ligne.
- **Paliers RÉELS de la feuille**, à jour au 28/07/2026 :
  **360 · 400 · 430 · 480 · 560 · 640 · 780 · 924 · 1000 · 1200**.
  Trois précisions que l'ancienne liste taisait :
  - **900 n'existe plus** (retiré depuis la V5) et figurait pourtant encore ici ;
  - **924 est DÉRIVÉ**, pas arbitraire : c'est 860 (largeur de checklist) + 2 × 32 de
    marge, le point où la barre de compte-rendu peut se centrer sur la colonne ;
  - **480 est un palier NON DÉCLARÉ**, introduit en v4.52.0 pour la rangée du vocabulaire
    du journal (libellé + alias + suppression). Mesuré : il n'est **pas porteur** — sans
    lui, à 430 px le champ libellé offre 151 px utiles pour les 140,4 px de « Médecin
    régulateur », le plus long libellé du noyau. Il est donc **candidat au repli sur
    430**, ce qui restaurerait la liste fermée ; c'est un changement VISIBLE entre 430 et
    479 px, donc une décision à prendre séparément.
  Aucun nouveau palier sans décision explicite — et la décision s'écrit **ici**, sans
  quoi la liste redevient fausse, comme elle vient de l'être.
- Largeurs par vue : accueil = sidebar 255 px + grille ≤ 1320 px (coque FIXE ≥ 780 :
  seuls la sidebar et le contenu défilent) ; fiche ≤ 860 px + **rail de lecture dès
  780 px**, 300 → 320 (≥ 1000) → 360 px (≥ 1200) ; protocole ≤ 780 px.
- **Les éditeurs ne sont PAS alignés sur leur vue de lecture** — cette ligne l'affirmait,
  c'était faux et mesuré tel quel (1400 px rend 900 + 320, jamais 860 + 360). L'éditeur
  de FICHE est une colonne d'édition **fluide** (1fr) + aperçu sticky 320 px dès 1000 px ;
  seul l'éditeur de PROTOCOLE est plafonné (780 + 360). Aligner l'un sur l'autre serait un
  changement visible, à décider séparément.
- **Deux seuils distincts, à ne jamais refusionner** : 780 = rail de LECTURE ;
  1000 = aperçu en direct des ÉDITEURS.
- Rayons : `--radius` 14 px (cartes), `--radius-md` 11 px (boutons/champs),
  `--radius-sm` 9 px (petits contrôles), 20 px (pastilles).
- Fenêtres : gabarit unique `dlg-480` (480 px, titre 17/800, croix 44 px) ; plein écran
  < 640 px SAUF les confirmations `dlg-confirm` (420 px, toujours centrées) ; la ZONE
  SENSIBLE est séparée par un filet et vient en dernier.
- **Feuilles plein écran** (`.sheet-full` : Se repérer, Consulter) : rembourrage haut nul,
  leur barre de titre étant collante et devant affleurer le bord. L'exclusion se fait sur
  la CLASSE, jamais sur les fenêtres nommément — la prochaine feuille en hérite.
- **Tout overlay défilable** reçoit une hauteur bornée au viewport VISIBLE
  (`--vvh`, repli `calc(100dvh / var(--zf,1))`) : un `inset:0` se dimensionne sur le grand
  viewport iOS et sa fin devient inatteignable derrière la barre d'outils.
- **Toute hauteur relative à la fenêtre s'écrit `calc(100dvh / var(--zf,1))`** : le réglage
  de taille du texte est un `zoom` sur `<html>`, un `vh` nu se fait agrandir par lui.

## Débordement — abréger, enrouler, ou annoncer

Trois réponses, et le choix se déduit de ce que coûte l'information cachée :

- **Une zone d'ÉTAT abrège et ANNONCE.** Le quai retire un segment, qui repasse dans le
  « +n » — jamais un chiffre, jamais le « +n » lui-même. Elle n'ampute jamais un NOMBRE
  (`fmtMs` passe en `h:mm:ss` au-delà de l'heure) ; un MOT, oui.
- **Une STRUCTURE enroule.** Dans le plan, une branche cachée est une branche qu'on ne
  saura pas prendre : la ligne d'Échelle passe à la ligne plutôt que de tronquer ses
  renvois. La place existe verticalement — l'argument du quai ne s'y transpose pas.
- **Une COMMANDE ne se tronque pas** : la croix d'un panneau s'ancre en haut à droite et
  le reste s'enroule dessous, plutôt que de la pousser hors écran.
- Abréger, quand il le faut, c'est **tronquer le MÊME mot** (« Cons. »), jamais en choisir
  un autre : deux noms pour un bouton, « on s'y perd ».

## Patterns signés

- **Barre d'en-tête claire** (couleur du fond) : la couleur d'identité se retire dans
  les accents ; en lecture le titre remplace la marque, et le « ‹ » porte le TITRE de la
  fiche d'origine quand on est arrivé par un lien (pile de retour, plafond 8).
- **DEUX RANGÉES COLLANTES, DEUX NATURES** (v4.25.0) — `#crisisCtrl` (les COMMANDES :
  bascule de mode, ⤢ Se repérer, ⤢ Consulter) **au-dessus** de `#crisisDock` (l'ÉTAT :
  chrono de session, minuteurs). C'est l'architecture ECAM à la lettre : sur un Airbus
  les commandes vivent sur l'ECP, un panneau DISTINCT de l'affichage. Fusionnées, elles
  se disputaient la place à chaque ajout ; séparées, l'arbitrage disparaît.
  - Dans les commandes : le MODE d'abord (il gouverne l'existence de « Se repérer »),
    puis un écart FIXE, puis les deux ouvertures — l'écart sépare les deux natures sans
    ajouter de trait, et il est fixe, non `flex:1` (pousser les ouvertures au bord droit
    les éloignerait de tout sur grand écran).
  - Dans l'état, ordre FIXE `⤢ Plan · ● Session · minuteurs` : les constants AVANT la
    partie variable, sinon un contrôle placé après un nombre variable de minuteurs ne
    peut rester immobile qu'ancré au bord (vide central) ou avec des créneaux vides
    (trou). La constance positionnelle est la règle cardinale d'une zone d'état.
  - **Le bandeau de crise reste BLANC** : un aplat rouge permanent désensibilise au
    rouge. Le statut s'annonce en TEXTE (« ■ Mode crise »).
- **Une bascule de mode est un SÉLECTEUR SEGMENTÉ, jamais un interrupteur** : « Guidé » et
  « Statique » sont deux modes PAIRS, aucun n'est la négation de l'autre. Un bouton d'état
  y serait ambigu — dit-il où je suis ou où je vais ? — et l'erreur coûterait le
  remplacement de toute la vue de travail en pleine réanimation.
- **Aucun contrôle ne vit dans le quai.** Il réécrit son `innerHTML` une fois par seconde :
  un tap sur un élément vivant y est AVALÉ dans 13 % des cas, mesuré, sur les deux
  moteurs. Les commandes vivent dans la colonne d'ACTION et au menu ⋯.
- **Cartes minuteur** : l'état change le TEXTE de l'étiquette (« — en pause »,
  « ■ … — à réévaluer »), barre 4 px du temps restant qui SE VIDE, échu = ambre + glyphe
  `△` en PRÉFIXE (il survit à l'ellipse) + étiquette lecteur d'écran. Minuteurs AD HOC en
  rangées compactes (ajoutés en session sans modifier la fiche).
- **Condition d'entrée** (QRH) : la « Confirmation diagnostique » est VISIBLE hors
  session, repliée en session — jamais supprimée, et jamais repliée par un démarrage
  IMPLICITE.
- **Notes personnelles** : carte en pointillés (registre « annotation informelle »,
  distinct du contenu clinique validé). Actions d'ajout = bordures pointillées.
- **Toast** : non bloquant, ardoise `--rt-*` fixe, barre de vie. **En session de crise, ce
  qui ARRIVE est mis en attente ; ce qui RÉPOND à un bouton pressé s'affiche** (v4.55.4).
  La distinction est explicite dans l'appel, jamais déduite d'une proximité temporelle
  avec un clic — une nouvelle de fond tombant dans la seconde suivant un tap serait alors
  affichée par accident, exactement ce que la règle interdit.
- **Le « non protégé » est NEUTRE** : un état PERMANENT en ambre s'use et émousse l'ambre
  des états réellement actionnables. L'ambre est réservé à « presque plein » et aux
  documents manquants.

## Les placards — exercice, invité (v4.27.0 / v4.55.4)

Un placard dit **dans quel régime on est**, à l'endroit le plus lu de l'écran. Deux
existent, ils partagent le même mécanisme au trait près : hachure sur un `::before` en
**fondu d'opacité** (~300 ms), portée par le bandeau-titre tant qu'il est visible, puis
relayée par l'EN-TÊTE au pixel où le titre passe dessous, enfants en `z-index:1`.
**Coût nul en hauteur** — seule condition qui vaille là où la rangée de commandes n'a que
2,1 px de marge à 320 px.

- **Exercice** — « ▲ Exercice », hachure `--surface`/`--primary-soft`, pilule BLEUE
  pointillée. Ni rouge ni ambre : ce n'est pas une alerte, c'est le placard TRAINING de
  l'aviation. Le « ● Session » vert reste réservé au réel.
- **Invité** — « ▪ Vous suivez » / « ▪ Suivi » en relais, hachure BLEUE. Il lisait
  « ■ Mode crise », exactement ce que lit l'hôte, alors que sa situation est autre : il
  SUIT une session qu'il ne conduit pas et qui peut s'arrêter sans lui.
- **L'EXERCICE GARDE LA PRIORITÉ**, non négociable : « ceci est une répétition » prime sur
  « vous suivez » — le premier protège d'une méprise clinique, le second est une
  information de rôle que le quai porte en permanence de toute façon.
- **Ce qu'on ne hachure pas** : le QUAI. Il a été essayé et annulé (« immonde ») — des
  chiffres n'ont pas à vivre sur une texture.

## Parcours de soin — le rail ①②③ (v4.4.0)

La vue lecture d'une fiche est structurée par un rail vertical numéroté
(`<ol class="care-path">`) : ① **Confirmer le diagnostic** → ② **Prise en charge** →
③ **Surveillances & pièges**, puis les annexes (journal, galerie, documents, note).

- Pastilles : bleu = active (`aria-current="step"`), vert ✓ = faite, neutre cerclé =
  à venir. **Jamais d'ambre ni de rouge dans le rail** : ce sont des registres d'alerte,
  ils y perdraient leur sens.
- La séquence est **SUGGÉRÉE, jamais bloquante** : la 1ʳᵉ action démarre la session, où
  qu'elle soit. Étapes vides omises (numérotation recalculée) ; une seule étape → pas de rail.
- « Ne pas oublier » reste le **CHAPEAU hors numérotation** (`.forget-strip`, bord
  `--critical-bd`) : ce qui tue si on l'oublie se lit AVANT toute séquence.

## Le rail de LECTURE, dès 780 px (v4.23.0)

Action et orientation de front — l'idéal ECAM (E/WD et SD simultanés). De haut en bas :
minuteurs épinglés → repères posologiques → Échelle du plan → horodatage.

- **Une colonne ENTIÈREMENT CONTINUE, aucun sous-défileur.** Trois essais ont échoué avant
  celui-là : un défileur unique enterrait la posologie ; trois zones bornées faisaient de
  chacune un HUBLOT ; une seule zone bornée a fait **disparaître** le compteur et le bouton
  « ＋ Minuteur PA » (327 px affichés pour 413 de contenu, barre de défilement invisible au
  repos). **Dans une colonne déjà défilante, un sous-conteneur borné ne range pas, il
  ESCAMOTE.** Le seul dispositif retenu est l'ORDRE : ce qui est de longueur ILLIMITÉE en
  DERNIER.
- **Chaque en-tête de zone annonce son TOTAL** (`.rail-n`) : sans ce compte, une zone
  tronquée paraît complète — ce que l'ECAM interdit.
- **Chrome désaturé, registre CONSERVÉ** : le rail oriente, la colonne agit. Les repères
  ordinaires sont des LIGNES ; un repère signalé garde sa carte teintée. La DOSE reste en
  encre pleine — la hiérarchie passe par la GRAISSE, jamais par l'encre.
- **Un repère posologique est AMBRE, jamais rouge** : c'est une RÉFÉRENCE, pas un geste.
  Trois masses rouges d'égale valeur à l'écran faisaient perdre leur prééminence aux
  memory items. Une seule masse rouge par écran.

## Les deux modes de lecture d'une aide (v4.13.0, fusionnés v4.16.0)

Une fiche À ALGORITHME se lit de deux façons, par une bascule **UNIQUE** en tête
(`#readTopSeg`, masquée si la fiche n'a pas d'algorithme) :

- **Dynamique** — le JOURNAL chronologique : ce que je fais, maintenant.
- **Statique** — le TABLEAU complet façon aide SFAR : toute l'aide d'un coup d'œil.

Les deux vues partagent le MÊME état de session ; la préférence est **par utilisateur**.
L'ancien 3ᵉ mode « guidé » n'existe plus : il est fusionné dans le journal.

## Journal de parcours & fil condensé (v4.9.0 / v4.16.0 — modèle ECAM)

**Doctrine fondatrice (leçon v4.6→v4.9)** : ne JAMAIS poser un état temporel sur une carte
spatiale — un bloc parcouru plusieurs fois y perd l'utilisateur. La chronologie EST la
structure : chaque passage est une **carte POSTÉE à la suite**, rien ne mute au-dessus, on
lit toujours vers le bas. Pas de curseur : la position est le BOUT.

Trois présentations par passage, calculées par une fonction pure :

1. **carte dépliée** — le bout, et tout passage incomplet ;
2. **ligne d'état** relisible — un passage complet récent ;
3. **chip** — n° + titre abrégé + ✓, ou n° + « › réponse » **en toutes lettres** pour une
   décision (le numéro seul ne parle pas à un humain).

**Invariants** : le BOUT est toujours une carte ; un passage **INCOMPLET n'est JAMAIS une
chip** (c'est ce qui fait la conformité) ; une rangée de plus de 4 chips se replie en
**ligne-bilan ECL** (« ✓ n passages · a→b ») — modèle Boeing : une checklist terminée se
referme en un statut d'une ligne. Le repli manuel PERSISTE ; le dépliage est une
**consultation transitoire**, effacée au geste de navigation suivant.

Changer d'avis ne réécrit jamais le passé : c'est un **nouveau passage** en bout de journal.

**Le journal des actions ANNULE, il ne supprime pas** (v4.49.0) : le `×` barre la ligne et
la conserve, et devient `↺` pour se raviser. Deux règles l'imposaient déjà — un geste
destructeur en crise se fait en « maintenant », et la correction d'heure est non
destructive depuis toujours. Le « maintenir » a été envisagé puis écarté : il protège du
geste accidentel mais laisse la perte définitive, et ne dit rien à celui qui relit. Or le
journal alimente le compte-rendu : une trace qu'un tap efface sans laisser de marque n'est
pas une trace. **L'heure reste en encre pleine** — c'est la donnée clinique.

## Plan de l'aide (v4.10.0 / v4.12.0 / v4.18.0 / v4.25.0)

Sous le journal, la **structure complète** façon algorithme papier / checklist
conditionnelle QRH. Le tronc reprend au point de convergence, une cible déjà décrite
devient « ↺ reprendre à n » (les BOUCLES deviennent lisibles), chaque bloc n'apparaît
qu'UNE fois. Sa numérotation est **COMMUNE** à toutes les vues (journal, chips, statique).

- **Le plan est IMMUABLE et INERTE côté cochage** (leçon v4.6, re-confirmée v4.12) :
  jamais de cases — la trace vit dans le journal. Il porte un état LÉGER (✓, ● ici, ×n)
  et sert à **NAVIGUER**.
- **UNE SEULE VUE depuis v4.25.0, l'Échelle** (une ligne par bloc, retraits de profondeur avec
  chips d'étiquette, renvois mono abrégés). « Détails » — l'organigramme — était la seule des trois
  à RECOPIER les étapes : elle rejouait la vue d'action au lieu de montrer autre chose, ce qu'un SD
  ECAM ne fait jamais. Le Schéma a rejoint le menu ⋯, en plein écran avec zoom.
- **Le fil d'ancêtres sticky est mort avec elle** — il n'existait que pour ses cartes-questions, et
  l'Échelle n'a pas d'ancêtres à épingler. Son idée SURVIT ailleurs et en mieux : en mode STATIQUE
  sur petit écran (v4.32.0), les bandes-questions RÉELLES s'épinglent, chaque niveau imbriqué se
  rangeant sous son ancêtre, avec le même z-ordre décroissant (modèle ECL : une sous-procédure
  terminée se referme dans sa procédure mère). Différence décisive : une seule mesure par rendu au
  lieu d'un recalcul à chaque événement de défilement — la hauteur n'est pas forcée, car compacter
  à une ligne tronquerait une question longue, et la question EST l'information.
- **Registre jamais masqué par un état** : un bloc de DÉCISION garde sa bordure ambre même
  quand il est le bloc courant. La POSITION est portée, elle, par la pilule « VOUS ÊTES
  ICI » — un canal par signification.

## Mode statique — le tableau (v4.13.0 / v4.14.0)

Toute l'aide en **cellules télégraphiques carrelées** à joint 3 px, dans l'esprit des aides
SFAR/CAMR. Tronc = cellules pleine largeur ; décision = **bande au registre ATTENTION**
(titre + question) + branches en colonnes ; **une seule colonne sous 640 px**, avec
indentation et rail de branche (la fourche étant masquée en pile, rail + chip portent la
structure).

- **INERTE côté cochage**, comme le plan : l'état de session est PEINT en lecture seule.
- Taper une cellule = y aller. **Jamais de démarrage de session, jamais de défilement** :
  rien ne bouge sous le doigt (flash d'acquittement).
- **AUCUN texte bleu dans les cellules** : le bleu ne marque QUE la position (● ici) et la
  reprise ↺. La réponse attendue y est une pilule mono **neutre**.
- Les flèches (fourche ambre, convergence grise, retours bleus) sont **mesurées après
  rendu**. Empilé, elles disparaissent : **la flèche n'est jamais seule**, l'information
  reste textuelle.
- **L'intitulé de décision est COLLANT sous 640 px** : en pile, la bande-question sortait de
  l'écran pendant qu'on lisait ses étapes — 844 px de contenu lus sans elle, mesuré, contre
  0 px côte à côte. Le bornage à ce palier n'est pas esthétique, c'est la borne du problème.

## Listes d'étapes — normal = LIGNE, signalé = BOÎTE

- Une étape normale est une **ligne à filet**, sans cadre, sans fond, sans liseré, et sans
  numéro (on coche dans n'importe quel ordre). Seule une étape `⚠`/`△` est une **boîte
  teintée**. Ainsi la couleur RESSORT au lieu de se noyer dans des cadres partout.
- **Le glyphe est OBLIGATOIRE** : depuis que le normal est plat, `⚠` rouge et `△` ambre ne
  se distingueraient QUE par la hue sans lui (WCAG 1.4.1).
- **Pas de liseré doublé** : le bord du bloc est le canal de l'état du BLOC, celui d'une
  bande le registre de l'ÉTAPE. Les confondre ferait porter deux sens au même trait et
  hacherait le bleu « vous êtes ici ». C'est le liseré de la BANDE qui est supprimé.
- Étape COCHÉE = aplatie ; une étape signalée cochée garde sa boîte, cadre vert doux.

## Challenge-response (v4.11.0 — FAA Order 8900.1 Vol. 3 Ch. 32 §3-3403.A)

**Correction de source, vérifiée sur le texte primaire** : « Do-Verify » et
« Challenge-Do-Verify » ne figurent NULLE PART dans l'AC 120-71B — ils viennent de
l'AC 120-71A (2003), que la révision B ANNULE, et n'y sont que des INTITULÉS d'une liste de
sujets. La méthode se cite par l'Order 8900.1 ; la répartition à deux, par l'AC 120-71B
§5.2.2.1. La pratique ne change pas d'un pixel — seule la référence était fausse.

Trois briques, **aucun champ ajouté au modèle** (l'export reste inchangé, un ancien client
reste lisible) :

1. **« challenge :: réponse »** — séparateur explicite DANS la chaîne d'étape (même
   philosophie opt-in que ⚠/△). Rendu en pilule mono : la **réponse attendue**.
2. **Mode Vérification** — la passe redéroule TOUTES les étapes, déjà cochées comprises.
   « Constaté ✓ » coche ; « △ Écart » avance **sans cocher** et ne **DÉCOCHE JAMAIS** (la
   coche est la trace). **Retour immédiat** : le résultat s'affiche dès qu'il est prononcé,
   pas en fin de bloc — la boucle est challenge → réponse → CONFIRMATION.
3. **Mode lecteur** (binôme, plein écran) — UN challenge à la fois, gros caractères, zone
   de validation ≥ 72 px. Bande minuteurs propre, carte des blocs, contexte local
   (précédent / suivant) — le un-item-à-la-fois n'est PAS le modèle aviation (ECL Boeing =
   liste entière + curseur), et perdre sa place est un mode de défaillance premier.

**La trace de vérification est un état DISTINCT du cochage** : une étape cochée à
l'exécution doit rester discernable d'une étape CONSTATÉE par observation — c'est
précisément ce que la seconde passe existe pour produire. **Même libellé pendant et après
la passe**, celui du GESTE (« constaté ») : deux mots pour un même état, c'est ce que
l'AC 120-71B proscrit. **Aucun bandeau ambre sur l'étape en écart** : le liseré est le canal
du REGISTRE, l'écart est un ÉTAT DE LA PASSE — la pilule, mot + glyphe, suffit.

**Garde-fou télégraphique** non bloquant : un bloc > 7 étapes ou un challenge > 110
caractères est signalé à la rédaction — une checklist ne se lit pas en paragraphes.

## Partage de session en direct (v4.46.0 → v4.55.4)

Une session de crise se remplit à plusieurs : l'hôte partage, un invité rejoint par code
ou QR, **sans avoir installé l'app**. C'est le premier chantier qui fait sortir une
session de l'appareil.

**Règle fondatrice : le partage est un miroir ADDITIF, jamais une dépendance.** Aucun
chemin d'interface n'attend un appel réseau — ni au tap, ni au rendu, ni à la fin de
session. Couper le réseau ne change, sur l'écran de l'hôte, **qu'un mot dans le quai**.

**Aucun texte libre ne traverse le réseau.** Un repère de journal voyage comme une
**référence** ({bloc, index} · minuteur · compteur · étiquette du noyau), jamais comme un
mot ; chaque appareil rend le libellé depuis SA copie. Le vocabulaire personnel (avec
alias : « mru », « regul », « dbase ») s'édite **à froid**, dans la fenêtre Compte — on ne
rédige pas son vocabulaire en réanimation. Le filet qui rend ce vocabulaire non critique :
le geste primaire reste **« Noter l'heure »**, un tap, qui pose un repère SANS étiquette.
L'heure — ce qui compte cliniquement — est capturée toujours.

**Ce que l'invité peut faire** (v4.55.0, après une objection d'usage qui a renversé la
conception) : cocher, constater, écart, incrémenter, **armer ET arrêter** un minuteur,
poser un repère, **AVANCER, choisir une branche, terminer un bloc**, entrer sur une
complication. **Ce qui reste au lead** : décocher, remettre à zéro, terminer le partage,
dater le début du soin. Le critère est celui que le dépôt avait déjà écrit pour
l'annulation d'un repère — **annuler CONSERVE, décocher DÉTRUIT** : naviguer est
append-only, arrêter un minuteur conserve son temps écoulé.
*Pourquoi ce renversement :* la conception initiale bridait le scribe au motif que « celui
qui lit ne décide pas ». C'était une mauvaise lecture — l'AC 120-71B §5.2.2.1 décrit une
répartition de LA PAROLE, et dans ce modèle c'est **celui qui lit qui fait avancer la
liste**, le lead étant celui dont les mains sont prises. La SFAR (« le lecteur : lire et
GUIDER »), l'ECAM (le pilot monitoring actionne l'ECP) et surtout McEvoy 2014 — 99,5 %
contre 70 %, où **le lecteur tenait l'unique appareil** — convergent.

**Sur l'ambiguïté « qui fait quoi »** (§5.5, qu'Airbus supprime en n'ayant qu'un seul ECP),
la réponse constante du projet : **on n'interdit pas, on ANNONCE** — une avance venue d'en
face pose « avancé par ‹rôle› » sur la carte courante, à côté de « Vous êtes ici ».

### Ce que le partage n'a PAS le droit de faire à l'écran

Ces contraintes ont été **mesurées** avant d'être écrites ; ce sont elles qui ont dessiné
les surfaces.

- **Aucun `render()` sur événement distant.** Application chirurgicale seule ; les verbes
  qui re-rendent sont mis en FILE et appliqués au prochain geste **local** de navigation.
- **Rien ne mute au-dessus** : la condensation du fil ne se recalcule jamais sur un
  événement distant.
- **Aucun contrôle dans le quai** (13 % de taps avalés, cf. Patterns signés).
- **Aucun segment `⇄` supplémentaire** : son insertion déplace le segment d'ALARME de 45 à
  57 px selon la largeur, à l'apparition ET à la disparition, **sur événement distant** —
  exactement ce que la constance positionnelle interdit. Le compte de participants devient
  un jeton du libellé de chrono, ou n'existe pas.
- **Jetons FERMÉS et courts** dans le libellé du chrono, jamais de prose : `main`, `suit`,
  `⇄n`, `figé`, `coupé`, `fini`, `seul` — 8 caractères au plus. Mesuré à 320 px : « · main »
  passe (42 px), « · vous conduisez » déborde de 15 px. **Le lien REMPLACE la main** quand
  il n'est plus nominal : ce n'est pas une économie de place, c'est que le rôle et le
  compte ne sont alors PLUS CONNUS — les afficher serait de la donnée périmée présentée
  comme vivante (danger n° 2 du palmarès ECRI 2015). Le vert `--ok` cesse alors d'affirmer :
  encre neutre, jamais l'ambre, réservé au minuteur échu.
- **Le bridage se fait par DÉSACTIVATION VISIBLE, jamais par masquage** : masquer les
  commandes replie `#crisisCtrl` et fait remonter le contenu clinique de **46 px** — la
  hauteur d'une ligne d'étape, sous les yeux de quelqu'un qui n'a rien demandé, et sur
  événement distant si le rôle change. La boîte reste, la géométrie ne bouge pas.
- **Rien n'est ajouté à `#crisisCtrl`** (2,1 px de marge à 320 px) ni à `#crisisBand`
  (une 2ᵉ pilule fait tomber le titre de fiche de 172 à 58 px).
- **La fenêtre d'appariement de l'hôte n'est pas une `.ai-modal` ordinaire** : elle
  gèlerait le défilement de sa propre checklist pendant toute la fenêtre d'admission.
- **Rejoindre se tape dans la barre de RECHERCHE de l'accueil** : pas de champ dédié, pas
  de bouton de plus — le code est reconnu à sa forme.
- **Aucun toast, aucune modale, aucun défilement** à l'arrivée d'un invité, à la passation,
  à la coupure. Un COMPTE change de valeur dans la zone d'état ; le détail vit au menu ⋯.

### Voir la trace PENDANT l'action

Une trace lisible seulement dans le compte-rendu ne sert à rien au moment où elle compte.
Quatre niveaux, du permanent au demandé — discipline ECAM : ce qui sert la conduite en
cours est PERMANENT et sur place, le reste s'appelle.

1. **Sur la ligne, sans geste** : *attribution* (marque neutre, seulement pour ce qu'un
   AUTRE a touché — quarante pilules « moi » seraient du bruit) et *divergence* (pilule au
   registre ATTENTION). **Surtout pas le liseré inset de 3 px** : ce trait est le canal du
   REGISTRE de l'étape, le réutiliser rendrait le signal ambigu.
2. **L'historique d'une ligne, à un tap, EN PLACE** — mécanisme des chips du fil condensé,
   jamais une modale.
3. **Le brin annexe** : les relevés d'un participant détaché s'insèrent à leur place
   chronologique, visuellement distincts — ce sont des rapports, pas des passages.
4. **Le journal complet attribué, à la demande**, depuis le menu ⋯. C'est le SD.

### Hors réseau, et le repli

**« Continuer seul »** : si le réseau ne revient pas, l'instantané que l'invité a déjà en
main devient une session locale normale — le repli hors dispositif qu'exige l'AC 120-64
§9.a. **Aucune fusion automatique au retour** : on peut toujours réunir deux JOURNAUX, on
ne peut pas réunir deux ÉTATS (les clés de cochage portent un numéro de visite minté
indépendamment de chaque côté — ce n'est pas un conflit arbitrable, c'est une collision
d'espace de noms, et le résultat serait faux ET plausible, ce qui est pire). Le relevé
revient donc **en ANNEXE**, daté à l'heure du geste, jamais plié dans l'état.

**La péremption est un contrat affiché**, pas une propriété émergente : le seuil est
solidaire de la cadence COURANTE (`max(4 s, 2,5 × période)` — 2,5 signifie « deux cycles
manqués », la gigue étant de ±20 %), et c'est le **quai entier** qui change d'état, pas un
segment. Un invité périmé perd VISIBLEMENT ses capacités d'écriture ; ses cartes de
minuteur portent « non confirmé » — la valeur reste **affichée** (une zone d'état n'ampute
jamais un nombre), elle est simplement marquée comme non garantie.

**Un seul appareil sonne** : bip et flash appartiennent au lead. L'invité voit le segment
ambre « échu » — l'ÉTAT ne disparaît jamais, le SON est unique.

## Historique de sessions synchronisé (v4.54.0)

**Opt-in, défaut fermé**, bascule dans la fenêtre Compte : cela inverse un invariant
documenté (« les sessions vivent en local, jamais synchro »), donc cela se décide, jamais
par effet de bord. Sessions ARCHIVÉES seulement — une session vive resynchronisée serait
un second mécanisme de partage, sans code, sans rôle et sans péremption.

**La trace do-verify (`verified`/`vgaps`) ne monte pas**, et **son absence est DITE** : le
compte-rendu distant porte « trace de vérification disponible sur l'appareil d'origine ».
Une absence qui ne s'annonce pas se lirait « aucune vérification n'a été faite ».

Les sessions d'**exercice** restent strictement ségrégées (colonne dédiée) : la propriété
« zéro contamination clinique » était jusque-là DÉRIVÉE de la localité des sessions.

## Mouvement & ancrage (doctrine ECAM)

Le mouvement est un signal, pas une décoration. En situation de soin :

- **Rien ne bouge sous le doigt.** Tout re-rendu de démarrage ou d'avancement est **ANCRÉ** :
  l'élément déclencheur ne se déplace pas d'un pixel à l'écran (compensation mesurée).
  Le motif « mesurer, re-rendre, compenser » vit dans **une seule** fonction depuis
  v4.45.0 — il existait en quatre copies, et **une seule des quatre mesurait son résidu**.
  Le résidu est RENVOYÉ, jamais corrigé en silence : la compensation est bornée par le haut
  de page, et masquer cette limite rouvrirait un bug de saut de contenu.
- **Un `0` de dérive doit être discernable d'une ancre PERDUE.** Sinon le contrôle qui
  vérifie « dérive 0 px » est vert sur le cas exact qu'il prétend couvrir.
- On ne défile vers une nouvelle carte que si elle n'est **pas déjà entièrement visible**.
- Une **alarme ne déplace jamais le contexte de travail** quand la session est sous les yeux :
  bip/vibration + flash bref, puis persistance en segment ambre. Banderole, flash écran et
  notification système sont **réservés à la session hors de vue** — et l'alarme routée
  s'annonce aussi sur `#srLive` : le bip seul ne dit ni QUEL minuteur ni SUR QUELLE FICHE.
- **ON ANIME LA COMPOSITION, JAMAIS LA MISE EN PAGE** (v4.41.0, `scripts/check-anim.mjs`) :
  une `transition` ou une `@keyframes` ne porte que sur `transform` et `opacity`. Animer
  `width`/`height`/`top`/`margin` force une passe de mise en page **par image**. Mesuré sur
  la barre de progression d'un minuteur : `transition:width` coûtait **126,8 ms/s** de fil
  principal à CPU nominal et jusqu'à 38 % d'un cœur à ×6, sans qu'aucun geste ne soit fait ;
  en `transform:scaleX()` + `transform-origin:left`, 13,3 ms/s — **autant que supprimer
  l'animation, sans changer le rendu d'un pixel**. Le gain est de la MARGE CPU et de
  l'AUTONOMIE sur appareil lent, pas de la fluidité : ne pas le vendre pour autre chose.
  Les propriétés de PEINTURE seule (couleurs, ombres, contours) ne sont pas concernées.
- Le mouvement est réservé à l'alarme : minuteurs et chapeau « Ne pas oublier » n'animent
  jamais. Tout est inerte sous `prefers-reduced-motion`.
- **Piège de mesure** : le réglage de taille du texte est un zoom CSS — toute mesure relue
  doit être divisée par ce zoom avant d'être réinjectée.
- **Toute sonde qui lit une géométrie après `focus()` doit ATTENDRE** (v4.45.0) : sur
  WebKit, le défilement induit par un focus PROGRAMMATIQUE est asynchrone. Une sonde
  pressée mesure la synchronicité du moteur, pas l'application — elle a signalé 8 défauts
  d'accessibilité qui n'existaient pas.

## Contenu rédigé (v4.4.3 / v4.5.4)

- La **seule couleur admise** y est celle des registres, via des **encadrés typés** (syntaxe
  des alerts GitHub) — jamais de couleur décorative libre : ici, rouge = « ça tue si on
  l'oublie », ambre = « c'est là qu'on se trompe ». Un rouge de mise en page dégraderait la
  crédibilité du rouge des étapes critiques.
- `==surligné==` = surligneur **achromatique** (registre MEMO) : faire ressortir un mot sans
  emprunter une couleur qui a un sens vital.
- **Listes cochables** `- [ ]` pour la vérification rapide en lecture : coches **éphémères**
  par ouverture, case cochée au registre CONFIRMATION, **texte jamais barré** (on doit
  pouvoir relire).
- Taille des images réglée **par image dans le modèle** (jeu fermé), jamais dans la syntaxe,
  et rendue par une CLASSE — jamais un nombre interpolé dans un style.

## La cascade — neuf pièges, et ce qu'ils ont en commun

Neuf fois, une règle de GÉOMÉTRIE a été silencieusement annulée par une autre. Six par
l'ORDRE de déclaration à spécificité égale (`.read-grid`, `.cbt-n`, `.mode-seg`, les
largeurs d'éditeur, les paliers 320 px…), trois par la SPÉCIFICITÉ :

- `.ai-card p` (0,1,1) l'emportant sur `.sh-code` (0,1,0) ;
- un `#id` (1,1,0) battant un sélecteur de classes plus long (0,2,1) — le geste était bloqué
  mais le bouton restait vert plein et **invitait au geste refusé** ;
- **`:not()` compte la spécificité de son argument** :
  `.ai-modal:not(.pdf-modal):not(.dlg-confirm) .ai-card` vaut (0,3,0) et bat (0,2,0).

**Règle qui en découle : pour une GÉOMÉTRIE, ne jamais dépendre de l'ordre de déclaration.**
Passer par un `#id`, ou vérifier la position dans la feuille — et compter les `:not()`.

## Ce qui a été RETIRÉ (ne pas réintroduire sans besoin constaté)

- **Minimaps** (v4.17.0) : la bande de chips-blocs de l'en-tête et le panneau « Algorithme —
  position » du rail droit sont supprimés — redondants depuis que le fil condensé et le plan
  portent la numérotation commune, l'état par bloc et le saut vers un bloc.
- **Panneau « Algorithme » avant le journal** (v4.18.0) : le SVG est devenu un affichage du plan,
  puis (v4.25.0) une entrée du menu ⋯ en plein écran ; il ne subsiste en tête que pour les fiches
  SANS algorithme.
- **Vue « Détails » du plan** (v4.25.0) : supprimée — voir ci-dessus. Son CSS orphelin et ses
  vestiges JS n'ont été purgés qu'en v4.32.0 : une suppression annoncée doit être VÉRIFIÉE au grep,
  faute de quoi la doctrine affirme un nettoyage qui n'a pas eu lieu.
- **Bulles d'ancêtres synthétiques** du plan (v4.22.1) : remplacées par l'épinglage des cartes
  RÉELLES — quatre itérations ont montré qu'une copie flottante coûte plus qu'elle ne rend.
- **Surveillances et posologie dans la feuille « Consulter »** (v4.25.3) : elles pesaient
  **57 % de sa hauteur** alors qu'elles existent déjà ailleurs (jusqu'à quatre exemplaires).
  Ces copies repoussaient de ~450 px le contenu réellement unique : on faisait défiler ce
  qu'on avait déjà sous les yeux pour atteindre ce qu'on venait chercher — l'inverse du
  decluttering ECAM.
- **La méta de lecture en session vive** (v4.31.0) : statut, catégorie et validation sont
  masqués pendant le soin — vus à l'ouverture, ils ne conduisent rien.
- **La pastille « ▲ Exercice : date » dans la méta** (v4.29.0) : elle captait l'œil à côté
  de la date de validation pour une information non clinique.
