# Lot v5.39 — le sommaire d'un PDF joint, optionnel (A418)

> Fichier normatif, suite de [`lot-v5-38.md`](lot-v5-38.md) (A400-A417). Les numéros A sont des adresses :
> ne jamais renuméroter. Demande de l'auteur du 28/09/2026.

## A418 — le sommaire d'un PDF, comme celui d'un protocole, mais qu'on peut replier

**Demande.** « S'il y a un sommaire, faire un sommaire cliquable en sticky ou en sidebar selon la largeur d'écran, comme
pour le texte des protocoles », puis « repliable, car ça doit rester une option », et « repliable en un petit bouton ».
Jusqu'ici (A392), les signets d'un PDF s'ouvraient dans une feuille `openPickMenu`, qui se refermait à chaque choix.

**Deux régimes, au seuil des protocoles (`mqReadWide`, 1000 px).** Le sommaire n'existe que si le PDF a des signets
(`getOutline`, trois niveaux, 200 entrées au plus, titres posés par `textContent`).
- **Dès 1000 px : une colonne à gauche des pages** (`.pdf-card.toc-side`, grille `--col-orient` + pages), sur
  l'ambiance, séparée par un filet. Elle est **ouverte d'office** et se **replie en un bouton ≡ de 40 px**
  (colonne de 56 px, `.toc-min`). Le bouton de la colonne dit ce qu'il fait (« Replier le sommaire », chevron ‹ ;
  replié, « Afficher le sommaire », ≡). L'appareil retient le choix (`ac-pdf-toc`, `localStorage`, simple
  confort d'affichage). Replier ou déplier élargit les pages : on remet à l'échelle en gardant la même place dans le
  document.
- **Sous 1000 px : une bande sous la barre**, bornée à 56 % de la hauteur. Elle est **fermée d'office**, s'ouvre par
  le bouton « Sommaire » (icône ≡, `aria-expanded`) et **se referme après un choix**, puisqu'elle prend la place du
  document. Le bouton quitte la rangée d'outils et monte sur la ligne du titre : à 390 px, avec lui, la rangée
  débordait (« Largeur » coupé, ⤓ hors de l'écran — défaut né en A392).
- En large, le bouton « Sommaire » de la barre est masqué : la colonne porte son propre bouton.

**Chaque titre porte son numéro de page**, et **la section en cours est en bleu** (registre du bloc courant,
`aria-current`) : dernier titre passé sous la ligne de lecture (haut du défileur + min(96 px, 20 %)), le dernier
visible en bas du document. Après un choix, c'est ce titre qui reste en cours tant qu'on n'a pas défilé
(`tocPin`), même si un titre voisin est sur la même ligne.

**On arrive sur le titre, plus en haut de sa page.** `pdfDestPos` lit la hauteur de la destination (XYZ, FitH, FitBH)
en plus de sa page, et `pdfPosY` la convertit par le viewport de la page. Cela vaut pour le sommaire et pour les
renvois internes du document (A392). **Au passage, un défaut de toujours** : les hauteurs des pages se lisaient par
`offsetTop` depuis la CARTE (premier ancêtre positionné), donc en comptant la barre. Chaque saut de la visionneuse
(liens, sommaire, occurrences d'une recherche, ouverture à une page) arrivait environ 60 px trop bas. `.pdf-scroll`
est désormais positionné, et les hauteurs se lisent depuis le défileur.

**Formes écartées.** Colonne permanente non repliable (demande explicite : le sommaire reste une option) ; bande
étroite ouverte d'office (elle mange la moitié du document au téléphone).

**Témoins** (section `audit-doctrine` « Page · A392 … », PDF fabriqué par Chromium) :
- à 1280 px, la colonne est ouverte, les numéros de page sont justes, la section en cours suit un choix ;
- repliée, il ne reste qu'un bouton de 56 px au plus, les pages s'élargissent, la position est gardée et le choix
  retenu ; la colonne se rouvre ;
- à 390 px, la bande est fermée d'office, s'ouvre sous la barre, n'a pas de bouton de repli et se referme après un
  choix qui fait défiler.

Ces contrôles échouent sur la version précédente, qui n'avait pas de `#pdfTocNav`.
