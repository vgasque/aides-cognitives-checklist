# Lot v5.41 — la porte « Ajouter » dit quoi, et quatre signalements (A441-A445)

> Fichier normatif, suite de [`lot-v5-40.md`](lot-v5-40.md) (A440). Les numéros A sont des adresses :
> ne jamais renuméroter. Signalements de l'auteur du 03/10/2026 ; porte « Ajouter » choisie sur canevas
> (« Bouton « + » de l'éditeur », planches Actuel, A-G — retenue : E).

## A441 — la porte de l'éditeur devient une pilule nommée à sous-titre (v5.41.0)

**Le signalement.** « Le bouton + bleu de rajout d'un bloc n'est peut-être pas assez visible. » Mesuré : depuis la
v5.30 la porte était un carré tonal de 56 px (`--primary-soft` sur le fond d'ambiance), glyphe seul, son mot et sa glose
masqués (`.edd-l`, `.edd-c` en `sr-only`). Deux défauts : peu de contraste avec le fond, et aucun mot — la règle 8
(« une couleur n'est jamais seule : glyphe ET mot ») n'était tenue que pour les lecteurs d'écran. Et le nouvel
utilisateur ne savait pas QUOI on ajoute.

**Décision (de l'auteur, planche E).** Une PILULE de 56 px, toujours tonale (`--primary-soft`), cerclée d'un filet
`--act` de 1,5 px qui la détache du fond jour et nuit, le mot « Ajouter » (15/800) et, dessous, l'exemple
« bloc · minuteur · dose… » (12/600, `--ink-2`) — à TOUTES les largeurs (le palier qui effaçait la glose sous 430 px est
retiré : la glose est désormais la raison d'être du dessin). Le nom accessible reste complet (« Ajouter à cette aide
bloc · minuteur · dose… », complément en `sr-only`). Même dessin dans l'éditeur de protocole (« document · référence… »).
Rien ne change à son comportement : collante dans le flux, `flat` pendant un déplacement, la palette inchangée.

**La condition de l'auteur, mesurée** : « tant que tout en bas ça ne bloque pas de contenu ». La porte est `sticky`, pas
`fixed` : au bas de la page elle reprend SA rangée dans le flux. Sonde `elementsFromPoint` aux quatre bords de la
pilule, au bas de la page, à 320, 390 et 1400 px : aucun élément dessous. En cours de défilement elle recouvre, comme
avant, la partie droite d'une rangée — 195 px de large au lieu de 56, prix accepté de la planche E.

**Formes écartées sur le canevas** (ne pas reproposer sans motif neuf) : pilule PLEINE (B — concurrence l'action
principale, un seul bouton plein par écran) ; BARRE de pied pleine largeur (C — 92 px pris en permanence, c'est la
porte d'avant la v5.30) ; points d'insertion « ＋ Bloc ici » entre les blocs (D) ; bulle d'apprentissage la première
fois (F) et raccourcis en fin de liste (G — deux portes pour un même geste) — F et G restent des pistes si E ne suffit
pas.

## A442 — « Afficher » : la pastille se peint AVANT d'agir (v5.41.0)

Signalé sous Chrome (pas sur iOS) : dans la feuille « Affichage », le premier clic sur Tout / Aides / Protocoles /
À relire filtrait la liste, la pastille ne suivait qu'au second. NON reproduit (pane intégré, Playwright Chromium avec
vrais gestes de souris, ouverture par le vrai bouton, 1400 et 390 px). Mais le gestionnaire peignait la pastille
APRÈS `setSection()`, qui re-rend toute la liste : toute interruption de ce rendu laissait l'état changé et la pastille
en place, et au second clic `setSection` sort tôt (section inchangée) — exactement le symptôme. La pastille et
`aria-checked` se posent désormais en premier ; l'action suit. Si le signalement revient, relever l'erreur de console
du premier clic : elle nommera la vraie cause.

## A443 — le cadenas d'une bibliothèque fait partie de la rangée (v5.41.0)

Signalé : dans la colonne gauche, taper le cadenas ou le nombre d'une bibliothèque ne la sélectionnait pas. `hsRow`
plaçait l'acte (et donc le compte qui le suit) HORS du bouton, parce que l'acte était un bouton ✎ frère (un bouton n'en
contient pas un autre). A389 a retiré le ✎ : il ne reste qu'un cadenas INERTE, qui restait dehors. Règle : un acte qui
n'est pas lui-même un `<button>` entre dans le bouton de la rangée, avec le compte. La colonne des comptes ne bouge
pas ; les cadenas se décalent tous de 2 px (écart du bouton 6 px contre 4 dans l'enveloppe), donc restent alignés.

## A444 — « Options du bloc » toujours repliée à l'ouverture (v5.41.0)

Amende A383. La carte s'ouvrait d'office dès qu'une option était posée : sur une aide réglée, chaque bloc se dépliait
à l'ouverture de l'éditeur. Le résumé de l'en-tête (« Départ · Minuteur · 2 jalons ») dit déjà ce qui est posé —
l'auteur l'a relevé. Repliée d'office ; un dépliage par l'auteur reste mémorisé le temps de l'édition (`state.edBlkOpt`).

## A445 — le nom d'un minuteur ou d'un compteur n'est plus plus petit que son nom court (v5.41.0)

Le champ du nom, en tête de carte, était à 13,5 px quand « Nom court » dessous était à 16 px : la hiérarchie était
renversée. Il passe à 17,5/800 (`--t-step`) — d'où sa sortie de la liste « 16 px tactile » de fin de feuille, qui
l'aurait rabaissé à 16 au toucher. Sous « Nom court », une ligne discrète (11 px, `.tme-sh`, fabrique `tmeShortRow`
commune au minuteur et au compteur) : « Facultatif — le nom sur la capsule en session ; vide, il est abrégé d'office. »
