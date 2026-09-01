# Lot v5.20 — ce qui coiffe le haut, ce qui manque au pouce (A286-A287)

> Deux signalements à l'usage du 01/09/2026, tous deux nés de la refonte d'accueil v5.18 : le rail
> A→Z qui pose sa lettre SOUS un objet collant, et la gestion (catégories, bibliothèques) devenue
> injoignable sur téléphone faute de colonne gauche. Mesurés sur l'app SERVIE avant tout correctif.

**A286. UN SAUT DU RAIL A→Z SE POSE SOUS CE QUI COIFFE LE HAUT DU DÉFILEUR, PAS SOUS LE BORD DE
L'ÉCRAN.** Signalé mot pour mot : « depuis la refonte de l'en-tête, le premier résultat de la
lettre est masqué ». Le mécanisme est un reste de la v5.18 : l'en-tête d'accueil y est devenu
STATIQUE, la cible du saut a donc cessé de soustraire quoi que ce soit (`offY(g) - 8`) — ce qui
était juste ce jour-là. Deux objets ont continué, eux, à coiffer ce haut :

- la **barre de sélection** (`.sel-bar`, collante à 0) — mesuré : intertitre de lettre entièrement
  avalé, **17 px de la première rangée** sous la barre ;
- la **bande de zone sûre** de l'iPhone INSTALLÉ (`body.view-home::before`, posée dans le même lot
  v5.18 pour que le contenu ne défile plus sous l'heure ; l'intertitre collant s'arrête dessous).
  Le saut posait la section à 8 px du bord d'écran, donc SOUS la bande : l'intertitre s'épinglait
  alors à 47 px et recouvrait la rangée qu'il annonce — **39 px de 60 mesurés**.

Correctif : la cible ôte la coiffe, LUE au moment du saut (`coiffe(g)`) et jamais écrite en
constante — le `top` calculé de l'intertitre porte déjà `env ÷ --zf`, la hauteur de la barre est
une mesure visuelle donc divisée par `zoomF()` (règle 10). Les deux branches (page en étroit,
`.home-main` en large) partagent la même soustraction. **Équivalence prouvée là où rien ne
coiffe** : nominal inchangé au pixel, en étroit comme en large, sur les deux moteurs.

⚠ **POURQUOI VINGT ET UN HARNAIS N'ONT RIEN VU, ET CE QUI CHANGE.** `env(safe-area-inset-top)`
vaut **0** dans un navigateur : la moitié du défaut n'existait que sur un appareil installé, et
l'autre moitié demandait le mode SÉLECTION, qu'aucune sonde du rail n'activait. Le témoin
(`audit-doctrine`, section « le rail A→Z pose sous ce qui coiffe ») joue donc TROIS cas — nominal,
sélection, et **encoche simulée** : on substitue la même géométrie par un littéral de 47 px, sans
toucher au code mesuré. Il est né ROUGE sur les trois assertions qu'il fallait (l'intertitre
coiffé en sélection, la rangée recouverte dans les deux cas), vert après correctif sur Chromium et
WebKit.

**A287. LA GESTION DESCEND AU POUCE — MÊME PATRON, MÊME CAUSE QUE « REJOINDRE UNE SESSION »
(v5.14.3).** Signalé : « sur smartphone il n'y a pas de sidebar : je ne peux plus gérer les
catégories, et les bibliothèques je ne peux les gérer qu'en vue *Rangé par bibliothèque* ».
Constaté au relevé : sous 780 px, « Gérer les catégories » n'était atteignable QUE par la feuille
de filtres — dont le déclencheur `#filtTog` n'existe que PENDANT une recherche (v5.18) ; et le ✎
d'une bibliothèque administrée ne paraît que sur l'intertitre de section, donc dans un seul
rangement sur trois. La colonne gauche portait les deux entrées ; elle n'existe pas ici.

Une **rangée au socle** (`#mgrBtn`), masquée ≥ 780 px où la colonne gauche reprend la main —
exactement le patron de `#joinBtn`, né du même signalement en v5.14.3. Elle **n'invente aucune
fenêtre** : la feuille `#mgrSheet` est faite des rangées de la colonne (`hsRow`), avec les mêmes
attributs et les mêmes lecteurs (`data-catmgr` → `#catModal`, `data-libedit` → `#membersModal`,
`data-newlib` → `#newLibModal`). Deux règles de politesse, écrites parce qu'elles se discutent :

- **le socle n'ouvre jamais une feuille d'UNE rangée** : sans bibliothèque à administrer — le cas
  de tout usage solo —, la rangée dit « Gérer les catégories » et va DROIT au gestionnaire.
  Libellé et destination disent alors la même chose, et l'on n'ajoute pas un tap pour rien ;
- **on ne liste que ce qui se gère** : une bibliothèque en lecture seule n'a rien à modifier, une
  rangée pour elle serait une commande morte (règle 14). Elle reste lisible partout ailleurs
  (intertitres, colonne gauche), avec son cadenas.

La feuille rejoint les surfaces d'`audit-a11y` **par son vrai point d'entrée** (`#mgrBtn`, profil
posé dans l'état que l'application lit elle-même puis `render()` — jamais un `classList.add('on')`
sur une fenêtre vide, doctrine v4.40.0) : contraste, cibles et anneau de focus mesurés dans les
deux thèmes.
