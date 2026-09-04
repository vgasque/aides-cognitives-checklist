# Lot v5.22 — le gestionnaire de catégories en liste, le rail de session à 280 px sur tablette

> Fichier normatif, suite de [`lot-v5-21.md`](lot-v5-21.md) (A297-A307). Les numéros A sont des
> adresses : ne jamais renuméroter.

## A308 — une palette à la fois, « Ajouter » en tête, un curseur de teinte ; le rail de session à 280 px entre 780 et 999 (v5.22.0)

**Demande de l'auteur** (revue design du 04/09/2026, canvas « Catégories et rail tablette ») :
améliorer « Gérer les catégories », permettre plus de couleurs, et juger la colonne droite d'une
session sur tablette en portrait.

**Mesuré avant de décider** (app servie, Chromium, 820 × 1180) :

- la fenêtre répétait la palette sous CHAQUE catégorie — 104 pastilles pour 8 catégories, rangées
  de 140 px, fenêtre de 1 144 px, et le champ « Ajouter », seule action de création, à 1 298 px sous
  le haut, donc hors écran ;
- en session, la grille 780-1199 donnait 444 px à la colonne d'action et 320 au rail (41 % de la
  largeur) : la colonne lue sous stress avait la largeur d'un téléphone, et le rail laissait sa
  moitié basse vide. À 1024 px (648 / 320, 32 %), rien à redire.

**Ce qui change.**

1. **Gestionnaire en liste** : « Ajouter » en tête de chaque section, rangées de 44 px (pastille ·
   nom · compte · ×), plus de cartes bordées. La palette ne s'ouvre que pour la catégorie dont on
   tape la pastille (`catPickKey`, une seule rangée `.open` à la fois), le focus revient sur la
   pastille après re-rendu (A236). Huit catégories tiennent en 715 px, « Ajouter » visible sans
   défiler. Les portes ne changent pas : accueil, feuille « Gérer », atelier d'import ET les deux
   éditeurs (« ＋ Nouvelle catégorie » du menu Catégorie) ouvrent la même fenêtre `#catModal`
   — vérifié au témoin sur l'éditeur de fiche et celui de protocole.
2. **Plus de couleurs, sans toucher au modèle** : `safeColor` accepte déjà tout hex et la synchro
   le transporte tel quel. Le curseur « Autre teinte » parcourt l'anneau OKLCH **L 0,48 · C 0,08**
   — la chroma MAXIMALE qui reste dans le gamut sRGB sur tout le tour (0,081, limitée vers 195°) ;
   à 0,10, le cyan s'écrêtait et l'aller-retour hex → OKLCH sortait de l'anneau (rouge attrapé par
   le témoin, corrigé avant livraison). Sur les 360 degrés : blanc sur teinte pleine ≥ 6,2, teinte
   sur fond à 15 % ≥ 5,0 — les deux contraintes de la régression #3 tiennent PAR CONSTRUCTION.
   Conversion maison (Ottosson), aucune dépendance ; le dégradé du curseur est calculé en JS et posé
   en style inline (aucune couleur littérale dans la feuille, `check-colors` inchangé). Aperçu en
   direct (pastille teintée, chip pleine) et un garde-fou de PROXIMITÉ : « △ proche de « X » » sous
   4,0 ΔE OKLab d'une catégorie du même périmètre — on avertit, on n'interdit pas ; un hex importé
   illisible est dit « △ contraste faible » (`catLisible`). Ce qui n'est pas fait, et pourquoi :
   pas de second anneau plus clair (le texte blanc du chip tomberait sous 4,5), pas de saisie hex
   libre (contraste non garanti). Les presets restent les treize de J1, inchangés.
3. **Rail 280 px entre 780 et 999**, 320 dès 1000 (palier déjà déclaré, aucune addition à l'échelle).
   Rendu mesuré à 280 : cartes minuteur 261 px, repères posologiques même hauteur, aucun
   débordement nouveau. Gain honnête : +40 px pour l'action (9 %). L'épitaphe de `.pg-wide` reste
   vraie — c'est un palier, pas un geste en session.

**Garde-fous** : `tests.html` § « anneau de teinte (A308) » (8 témoins : contrastes sur 120
teintes, `catLisible`, aller-retour, plancher 4,0 entre presets) ; `audit-doctrine` § « Catégories ·
une palette à la fois, Ajouter en tête, même fenêtre depuis les éditeurs » (10 contrôles, 96 → 97
sections), vérifié CAPABLE D'ÉCHOUER (palette forcée ouverte → 3 rouges sur les bonnes assertions,
`index.html` restauré à l'octet).
