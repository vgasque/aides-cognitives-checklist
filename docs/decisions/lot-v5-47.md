# Lot v5.47 — brouillon d'office, lien direct, texte agrandi, « Prendre en main » (A463-A466)

> Fichier normatif, suite de [`lot-v5-46.md`](lot-v5-46.md) (A461-A462). Les numéros A sont des adresses : ne jamais
> renuméroter. Origine : [`docs/audit-apprentissage-2026-10.md`](../audit-apprentissage-2026-10.md), points 14, 15, 16 et
> 18 du § 8, et les retouches « carte du bloc » et « éditeur ». Accord de l'auteur : « OK pour la suite. 16 OK, 17 non,
> 18 OK ». Les points 19 (« Tout voir » au téléphone) et 20 (exercice guidé) sont maquettés, non codés, en attente de
> l'auteur.

## A463 — une aide neuve naît en Brouillon (amende A304)

`newFiche()` et `newProtocol()` posent `status:'draft'`. Avant, une aide créée vide s'affichait « ✓ Validée — Publiée,
utilisable en situation ».

Le statut est posé à la création et non dans `blankFiche()`. Les tests prennent `blankFiche()` pour la fiche nominale,
et `migrate` garde `validated` comme valeur de repli pour les imports anciens, qui ne changent pas d'état.

La fenêtre de création dans une bibliothèque partagée disait « visible par tous les membres », ce qui est faux pour un
brouillon. Elle dit désormais : « … créée en brouillon dans « X » : les membres qui peuvent éditer la voient aussitôt,
les lecteurs une fois validée. »

## A464 — lien direct vers une aide

**`#a=<id>` ouvre l'aide ou le protocole.** Le lien sert de raccourci d'écran d'accueil, ou s'envoie à un collègue de
la même bibliothèque. La lecture est pure et testée (`deepLinkFromHash`) :
- l'identifiant suit `SAFE_ID` ;
- `BAD_KEYS` est refusé ;
- un code de partage `#j=` n'est jamais pris pour un lien direct.

**Quand le lien est lu** (`applyDeepLink`) :
- au démarrage, après la reprise d'une session vive ;
- au changement de fragment (`hashchange`) ;
- par `launchQueue` quand l'application installée est déjà ouverte.

**Ce qui l'encadre :**
- jamais par-dessus une session réelle à l'écran (règle 11) ;
- le fragment est retiré une fois lu ;
- une aide absente de l'appareil le dit dans une notice, au lieu de ne rien faire.

**Garde du retour système (A430).** Un fragment crée une entrée d'historique sans état, que le gestionnaire de
`popstate` prenait pour un « sous la base » : il faisait `history.back()` et annulait le lien. Il ignore désormais les
fragments de lien direct, et la lecture du lien replace l'entrée avec un état valide.

Le menu ⋯ d'une aide et d'un protocole gagne « Copier le lien direct ». Il passe par la feuille de partage native,
sinon par le presse-papiers.

**Raccourcis de l'icône d'app** (manifeste) : « Chercher une aide » (`#chercher`, focus sur la recherche) et
« Sessions » (`#sessions`).

**Forme écartée :** des raccourcis vers les aides épinglées. Le manifeste est statique, il ne peut pas lister les
épinglées de chaque utilisateur.

## A465 — texte agrandi, carte du bloc, éditeur

**Le quai garde ses mots.** Mesuré dans les deux Chromium (complet et headless shell), avant la correction :
- dès 115 %, « Tout voir » était réduit à son glyphe ;
- à 130 %, « FV réfractaire » et « Horodater » se coupaient au milieu d'un mot. `hyphens:auto` n'a pas de
  dictionnaire dans tous les moteurs, et `overflow-wrap:break-word` cassait alors le mot.

Sous `zw360`, la correction pose :
- des libellés à `--t-meta`, sur deux lignes, sans coupure de mot ;
- « Tout voir » avec son mot (52 px) ;
- « Fin » à 48 px ;
- un rembourrage latéral de 2 px.

Le nouveau témoin d'`audit-doctrine` (« QUAI · texte agrandi ») couvre 390 et 360 px à 130 %, et 320 px à 115 %. Il
est vérifié capable d'échouer sur la v5.46.2.

**Le titre de bloc ne perd plus la largeur d'un mot.**
- La pastille « EN COURS » passe en étiquette au-dessus du titre, au patron de CRITIQUE au-dessus d'une étape. À côté
  du titre, elle prenait la largeur d'un mot (« Reconnaissan / ce »).
- Une espace la sépare du titre pour les lecteurs d'écran : sans elle, ils lisaient « En coursReconnaissance ».
- Sous `zw360`, le titre passe à `--t-step` (17,5 × zoom, soit au moins 21 px vus).
- Reste dit : à 320 px et 115 %, ou 360 px et 130 %, un mot de 14 lettres ne tient pas dans la colonne. La césure
  française du système y met un trait d'union.

**La légende de la carte dit ce qu'elle désigne.** « réponse attendue » devient « sous l'étape, en gris : la réponse
attendue ».

**Éditeur.**
- L'« Identité » est repliée à l'ouverture d'une aide qui a déjà un titre, et ouverte pour une aide neuve (amende
  v5.30).
- Chaque section de la feuille « Réglages » d'une étape porte une phrase d'exemple (`.sst-ex`).

**Laissé en l'état, par doctrine :**
- « Cochez les étapes restantes (n) » est un bouton fermé qui dit sa cause (A235).
- La pastille d'historique « Fait · … » reste tronquée à 390 px, selon son dessin (A369).
- Le titre de l'aide en tête est tronqué : c'est un rappel, et le titre complet est sur l'écran d'entrée. Lui donner
  deux lignes dépasserait le budget de chrome à 320 × 640 et 130 %.

## A466 — « Prendre en main »

Moi › « Prendre en main » ouvre une page-fenêtre (`#guideModal`). Elle ne s'ouvre jamais pendant une session
(règle 11) et ne parle que de l'outil, jamais de clinique (§ 2). Elle contient :
- dix gestes en rangées dépliables (`GUIDE_GESTES`) ;
- le glossaire de seize termes (`GLOSSAIRE`), écrit au lexique d'A461 ;
- « Revoir l'accueil » (A460), qui quitte la carte « Sur cet appareil ».

Le focus d'ouverture se pose sur le premier geste.

**Défaut trouvé en route.** `_focusables` ignorait `<summary>` : le piège Tab des fenêtres (A313) sautait donc tous les
dépliants, dans toutes les fenêtres (« Pourquoi créer un compte ? », « En savoir plus »…). `summary` entre dans la
liste. La surface « prendre en main » entre dans `audit-a11y`.
