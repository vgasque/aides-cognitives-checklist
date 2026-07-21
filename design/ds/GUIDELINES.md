# Aides cognitives — Lignes directrices du design (v4.22)

PWA médicale monofichier, utilisée **en urgence vitale, sous stress** : la clarté et la
robustesse priment sur toute considération esthétique. Tout choix de design se juge à
l'aune d'une question : *est-ce lisible et actionnable par un soignant en crise ?*
La grammaire s'inspire des normes aéronautiques (ECAM/QRH) : état annoncé en texte,
jamais la couleur seule, conditions d'entrée visibles, anti-accident systématique.

## Source de vérité

Les tokens (`tokens/tokens.css`) et le CSS des fiches de ce projet sont **extraits
automatiquement** de `index.html` par `design/build.mjs` — ne jamais les éditer ici.
Toute évolution se fait dans l'app, puis se resynchronise.

## Couleur — sémantique FIXE

- **Aucune couleur hex hors tokens** (`:root`) et `PALETTE` (13 teintes de catégories),
  y compris dans le thème sombre (pas de copie hex d'un token).
- `--primary` (**bleu clinique**) = identité, action.
- `--ok` (vert) = **confirmation / issue positive** : étape cochée (`--done-*`),
  « Continuer » actif, fin d'algorithme, pastilles d'état ok, sessions vives.
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
- `--link` = liens ET temps d'un minuteur en cours (accent froid).
- `--alert-*` (ambre vif) = banderoles d'alerte, volontairement distinct de `--verify`.
- `--alarm` (chaud) = alarme ou jauge du geste destructif UNIQUEMENT.
- `--rt-*` : ardoise FIXE des toasts (identique dans les deux thèmes). Le panneau
  minuteurs, lui, **suit le thème** depuis V5.
- Statuts éditoriaux **achromatiques** : pilule `.status-tag` unique (✓ Validée,
  △ À relire, ○ Brouillon — `--tag-bg`/`--tag-ink`). Sur les cartes d'accueil, la
  pilule de catégorie est NEUTRE : la couleur de catégorie ne vit que dans le liseré.
- Pastilles d'état (compte/synchro) : ok = `--ok`, attente = `--verify`,
  erreur = `--critical`, inactif = `--line-strong`.
- Fond des champs de saisie = `--input-bg`, partout.
- Contraste : texte ≥ 4.5:1, composants ≥ 3:1 (WCAG 2.2 AA), dans les DEUX thèmes.
- La couleur n'est **jamais le seul canal** : toujours texte, forme ou position en plus.

## Couleur d'accent par utilisateur (v4.5)

5 accents prédéfinis AA (sarcelle, violet, indigo, framboise, ardoise) + bleu clinique
par défaut. **Connecté seulement** (l'accent tombe à la déconnexion). Portée : l'accueil
ENTIER + l'EN-TÊTE de toutes les vues (l'identité reste visible partout) ; le **contenu
clinique** (fiches en crise, protocoles, éditeurs) **reste bleu clinique**. Jamais de
vert/ambre/rouge en accent : les registres sémantiques sont réservés.

## Typographie

- Police système (`--sans`) ; mono (`--mono`, tabular-nums) réservée aux valeurs qui
  défilent (chronos, compteurs, numéros d'étape) et aux codes courts.
- **Plancher : 11 px** pour tout texte courant ; seules les pilules-capitales à forte
  graisse (`.status-tag`, `.tm-label`, 10.5 px / 700+) y dérogent (spec canvas).
- **Un seul registre de titres de section** : petites capitales grasses (`.block-h`),
  repris par les titres du contenu rédigé (`.md-h1`/`.md-h2`). Pas de nouveau style de titre.
- Le contenu (15–16 px) reste plus grand que ses titres de section.

## Saillance

- **Un seul bouton rempli** (`--primary` plein) par écran. Si deux actions coexistent,
  la moins critique passe en tonal (`--primary-soft`).
- Grammaire des boutons de gestion : **pointillé** = créer, **contour** = gérer /
  secondaire, **plein** = action primaire.
- En lecture, toutes les actions secondaires vivent dans le **menu ⋯** (rangées 44 px,
  séparateurs entre groupes, action destructrice DERNIÈRE et rouge — jamais première).
- En crise, le chrome s'efface : aucune notification flottante (toasts mis en attente),
  une seule zone fixe en haut, jamais en bas.

## Interaction

- Cible tactile ≥ 32 px ; **≥ 44 px pour les contrôles du mode crise**. Quand le
  contrôle visuel est plus petit (36–40 px), halo cliquable en `::after`.
- Tout élément interactif : `:focus-visible` (outline 2 px `--primary`) + équivalent
  clavier (Entrée/Espace).
- Action destructrice en crise = geste **« maintenir »** (jauge `--alarm` qui se
  remplit), jamais un simple tap ; la réinitialisation d'un minuteur ANNONCE ce qu'elle
  redonnera (« ↺ 05:00 »).
- **Garde temporelle 700 ms** (`.guarded`, opacité réduite) entre deux boutons
  « retour » empilés — un double-tap ne doit jamais franchir deux niveaux (ECAM).
- Un bouton désactivé n'est jamais muet : il DIT pourquoi et combien il reste
  (« Cochez les étapes restantes (2) ») ; actif, il ANNONCE sa destination
  (« Continuer — réévaluation à 5 min → »).
- Les éditeurs s'auto-enregistrent (brouillon « fantôme » restaurable) : « ‹ Retour »
  remplace « Annuler ».
- Animations en transform/opacity uniquement (jamais bloquantes), coupées par
  `prefers-reduced-motion`.

## Grille & formes

- Breakpoints **fermés** : 430 / 560 / 640 / 780 / 900 / 1000 / 1200 px. Aucun nouveau
  palier sans décision explicite (référence : `AGENTS.md`, § Largeurs).
- Largeurs par vue : accueil = sidebar 255 px + grille ≤ 1320 px (coque FIXE ≥ 780 :
  seuls la sidebar et le contenu défilent) ; fiche ≤ 860 px + rail minuteurs
  320 → 360 px (≥ 1000) ; protocole ≤ 780 px ; éditeurs alignés sur leur vue de
  lecture + aperçu sticky 360 px.
- Rayons : `--radius` 14 px (cartes), `--radius-md` 11 px (boutons/champs),
  `--radius-sm` 9 px (petits contrôles), 20 px (pastilles).
- Fenêtres : gabarit unique `dlg-480` (480 px, titre 17/800, croix 44 px) ; plein écran
  < 640 px SAUF les confirmations `dlg-confirm` (420 px, toujours centrées) ; la ZONE
  SENSIBLE est séparée par un filet et vient en dernier.

## Patterns signés

- **Barre d'en-tête claire** (couleur du fond) : la couleur d'identité se retire dans
  les accents ; en lecture le titre remplace la marque. Le mode crise est porté par le
  **bandeau TITRE au registre ALERTE** (`--critical-soft`, « ■ MODE CRISE » : texte +
  couleur + position, trois canaux) ; minuteurs segmentés dans la barre à toutes les
  largeurs, suivis du chrono GLOBAL « ● Session ».
- **Cartes minuteur** : l'état change le TEXTE de l'étiquette (« — en pause »,
  « ■ … — à réévaluer »), barre 4 px du temps restant qui SE VIDE, échu = ambre.
  Minuteurs AD HOC en rangées compactes (ajoutés en session sans modifier la fiche).
- **Condition d'entrée** (QRH) : la « Confirmation diagnostique » est VISIBLE hors
  session, repliée en session — jamais supprimée.
- **Notes personnelles** : carte en pointillés (registre « annotation informelle »,
  distinct du contenu clinique validé). Actions d'ajout = bordures pointillées.
- **Toast** : non bloquant, ardoise `--rt-*` fixe, barre de vie ; l'alerte de minuteur
  est une banderole ambre vif pulsée, distincte du chrome ; en session de crise, tout
  est mis en attente.

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

## Plan de l'aide (v4.10.0 / v4.12.0 / v4.18.0)

Sous le journal, la **structure complète** façon algorithme papier / checklist
conditionnelle QRH. Le tronc reprend au point de convergence, une cible déjà décrite
devient « ↺ reprendre à n » (les BOUCLES deviennent lisibles), chaque bloc n'apparaît
qu'UNE fois. Sa numérotation est **COMMUNE** à toutes les vues (journal, chips, statique).

- **Le plan est IMMUABLE et INERTE côté cochage** (leçon v4.6, re-confirmée v4.12) :
  jamais de cases — la trace vit dans le journal. Il porte un état LÉGER (✓, ● ici, ×n)
  et sert à **NAVIGUER**.
- **Organigramme hybride** : branches côte à côte quand l'écran le permet, empilées sinon
  — **une seule colonne sous 640 px** (retour d'usage : des colonnes de ~150 px émiettaient
  les mots cliniques lettre à lettre).
- **Rail de branche 3 px** : bleu = prise, pointillé estompé + « hors chemin » = écartée.
  La couleur n'est jamais seule. Branche hors chemin auto-repliée, jamais bloquant.
- **Trois affichages** (ordre ECAM E/WD → SD : l'ACTION d'abord, la structure en annexe) :
  **Détails** (organigramme), **Échelle** (une ligne par bloc), **Schéma** (le SVG spatial).
- **Fil d'ancêtres sticky** : les cartes-questions RÉELLES s'épinglent sous l'en-tête —
  aucune copie synthétique, aucun mouvement autonome (tout mouvement est le geste de
  défilement). Chaque niveau se replie derrière son ancêtre au décrochage (modèle ECL :
  une sous-procédure terminée se referme dans sa procédure mère).

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

## Challenge-response (v4.11.0 — AC 120-71B, Do-Verify)

Trois briques, **aucun champ ajouté au modèle** (l'export reste inchangé, un ancien client
reste lisible) :

1. **« challenge :: réponse »** — séparateur explicite DANS la chaîne d'étape (même
   philosophie opt-in que ⚠/△). Rendu en pilule mono : la **réponse attendue**.
2. **Mode Vérification** — la passe redéroule TOUTES les étapes, déjà cochées comprises.
   « Constaté ✓ » coche ; « △ Écart » avance **sans cocher** et ne **DÉCOCHE JAMAIS** (la
   coche est la trace). Résumé final = liste des non-cochées.
3. **Mode lecteur** (binôme, plein écran) — UN challenge à la fois, gros caractères, zone
   de validation ≥ 72 px. Jamais d'avance tant que tout n'est pas confirmé.

**Garde-fou télégraphique** non bloquant : un bloc > 7 étapes ou un challenge > 110
caractères est signalé à la rédaction — une checklist ne se lit pas en paragraphes.

## Mouvement & ancrage (doctrine ECAM)

Le mouvement est un signal, pas une décoration. En situation de soin :

- **Rien ne bouge sous le doigt.** Tout re-rendu de démarrage ou d'avancement est **ANCRÉ** :
  l'élément déclencheur ne se déplace pas d'un pixel à l'écran (compensation mesurée).
- On ne défile vers une nouvelle carte que si elle n'est **pas déjà entièrement visible**.
- Une **alarme ne déplace jamais le contexte de travail** quand la session est sous les yeux :
  bip/vibration + flash bref, puis persistance en segment ambre. Banderole, flash écran et
  notification système sont **réservés à la session hors de vue**.
- Le mouvement est réservé à l'alarme : minuteurs et chapeau « Ne pas oublier » n'animent
  jamais. Tout est en transform/opacity, et inerte sous `prefers-reduced-motion`.
- **Piège de mesure** : le réglage de taille du texte est un zoom CSS — toute mesure relue
  doit être divisée par ce zoom avant d'être réinjectée.

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

## Ce qui a été RETIRÉ (ne pas réintroduire sans besoin constaté)

- **Minimaps** (v4.17.0) : la bande de chips-blocs de l'en-tête et le panneau « Algorithme —
  position » du rail droit sont supprimés — redondants depuis que le fil condensé et le plan
  portent la numérotation commune, l'état par bloc et le saut vers un bloc.
- **Panneau « Algorithme » avant le journal** (v4.18.0) : le SVG est devenu le 3ᵉ affichage du
  plan ; il ne subsiste en tête que pour les fiches SANS algorithme.
- **Bulles d'ancêtres synthétiques** du plan (v4.22.1) : remplacées par l'épinglage des cartes
  RÉELLES — quatre itérations ont montré qu'une copie flottante coûte plus qu'elle ne rend.
