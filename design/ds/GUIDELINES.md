# Aides cognitives — Lignes directrices du design (v4.5)

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
