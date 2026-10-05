# Lot v5.44 — l'éditeur Markdown des références (A451-A458)

> Fichier normatif, suite de [`lot-v5-43.md`](lot-v5-43.md) (A450). Les numéros A sont des adresses : ne jamais
> renuméroter. Demande de l'auteur du 05/10/2026 : « comment améliorerais-tu l'éditeur markdown des protocoles ? »,
> puis canevas Design « Éditeur de protocoles » (bureau, tablette, téléphone, outils communs) validé et implémenté en
> trois passes vérifiées (1 + 2 + 3, puis 4 + 5 + 6, puis 7 + 8), avec contrôle final sur pliables.

## A451 — lier un document joint sans recopier d'identifiant

`[texte](att:ID)` exigeait un identifiant que rien n'affichait. Trois chemins le posent désormais :
« Insérer › Lien vers un document joint » (menu des PDF, libellé = sélection, sinon nom du fichier sans « .pdf »),
la frappe de « ](att: » (le menu complète l'identifiant), et le bouton lien de chaque rangée « Documents (PDF) »
(toucher : au curseur ; glisser vers le champ : là où on lâche — le dépôt de texte est natif). Sans document, la rangée
joint un PDF puis le lie (sélecteur ouvert dans le même geste, A71). **`#pN`** après l'identifiant ouvre la visionneuse à
la page N (`data-mdpage`) ; un client antérieur laisse le lien en clair (dégradation lisible, jamais de perte).

## A452 — une barre regroupée, des menus qui disent leur syntaxe

17 boutons à plat → B · I · S, puis quatre menus : **Titre**, **Liste** (puces, numérotée, cochable, citation),
**Encadré** (les quatre registres, glyphe + mot), **＋ Insérer** (tableau, lien vers un document, lien web, image, code,
séparateur). Les menus passent par `openPickMenu` (ancrés ≥ 780, feuille basse en dessous — même dessin que le menu ⋯) ;
chaque rangée porte la syntaxe qu'elle pose en sous-ligne. Barre collante sous l'en-tête, rendue au flux clavier ouvert
(`html.kbd`, A192). Paliers `zw` (règle 10) : libellés masqués sous 560 (lus), chevrons sous 430, « Insérer » réduit à
son ＋ sous 360 (écran externe d'un Z Fold, 344 px). Les tracés de l'ancienne barre entrent dans `uiIcon`
(`ul`, `ol`, `task`, `quote`, `code`, `link`, `hr`).

## A453 — la saisie au clavier, et ⌘Z qui annule aussi la barre

`mdSplice` (porte unique de tous les poseurs) écrit par `execCommand('insertText')` : le geste entre dans l'historique
NATIF du champ (repli `setRangeText`). `mdWrapSel` bascule (entoure ou retire) et sert aussi le gras des fiches
(`wrapBold`). Entrée continue une liste (`mdListCont`, pure : numéro + 1, case remise à vide, « > » des citations et
encadrés) et la termine sur un item vide ; Tab / Maj+Tab change le niveau d'une puce (un seul niveau, celui que lit
`mdBlocks`) et garde son rôle hors liste (sortir du champ) ; ⌘B, ⌘I, ⌘K.

## A454 — une disposition par largeur, un plan, un aperçu qui suit le curseur

Téléphone : « Écrire | Aperçu » dans la carte (`.seg`), toucher un bloc de l'aperçu ramène le curseur à sa ligne.
780-999 : texte et aperçu côte à côte. ≥ 1000 : la colonne d'aperçu (inchangée). Partout, un bouton **« Plan · section
courante »** (menu des titres, aller à une ligne : `mdLineTop` mesure par un double invisible aux métriques du champ) et
le bloc où l'on écrit marqué dans l'aperçu (`.md-here`, registre « bloc courant »), ramené dans la vue de SON défileur,
jamais la page. `mdBlocks` porte la ligne source de chaque bloc (`ln`, additif) ; `mdRender(…,{ln:true})` l'émet en
`data-ln` dans les seuls aperçus de l'éditeur. **Écart au canevas, nommé** : la colonne « Plan » du bureau et le
glisser-déposer de sections sont restés hors de ce lot (le menu Plan couvre la navigation à toutes les largeurs).

## A455 — le tableau en grille

« Insérer › Tableau » et le bouton contextuel **« Modifier en grille »** (visible seulement curseur dans un tableau)
ouvrent la fenêtre des outils (`#mdToolModal`, une fenêtre pour deux corps). `mdTableAt` (pure) lit le tableau au curseur
sans rien tronquer (une ligne plus longue élargit l'en-tête) ; `mdTableMd` (pure) l'écrit colonnes alignées, « | »
protégé. ＋/− ligne et colonne à la cellule visée, alignement par colonne, modèle « posologie » pour un tableau neuf,
Tab sur la dernière cellule ajoute une ligne, texte produit visible. Fermeture par `modalHandoffClose` : le focus revient
au texte, l'écriture passe par `mdSplice` (⌘Z rend le tableau d'avant). Focus d'ouverture par `data-dlgfocus`.

## A456 — coller depuis Word ou un PDF

Au collage, `mdFromPaste` choisit : `mdFromHtml` (presse-papiers riche ; `DOMParser`, document INERTE, scripts et médias
retirés ; puces « · » de Word et style `mso-list`, intertitres en gras, listes, tableaux, gras, italique, liens https) ou
`mdFromPlain` (puces littérales, tabulations en tableau, lignes d'un PDF recollées quand la suite commence en minuscule).
Rien de reconnu → collage natif, sans fenêtre. Sinon la fenêtre montre ce qui a été collé et ce qui sera inséré, avec ce
qui a été reconnu ; **la couleur n'est jamais reprise** (elle a un sens ici) et le dit (« à poser en encadré »).
« Coller le texte brut » reste toujours possible.

## A457 — la relecture de l'écriture (jamais du contenu)

`mdLint` (pure) relit la FORME : document lié absent, ligne de tableau incomplète ou trop longue, « ### » sans « ## »
au-dessus, encadré vide, et l'**écriture des doses** connue pour tromper la lecture — zéro manquant (« .5 mg »), zéro
superflu (« 5,0 mg »), « ug », « U », « cc ». Code ignoré. **Qualification § 2 (non-DM), écrite avant le code** : aucune
valeur n'est jugée ni calculée, aucune sortie individualisée ; c'est un correcteur typographique sur un vocabulaire
fermé. Liste sous le champ (absente quand il n'y a rien à dire), « Corriger » une par une — **pas de « tout corriger »,
à dessein** — remplacement exact vérifié contre le texte (`was`), annulable ; synthèse « Écriture » dans le volet
partagé. **Deux défauts existants corrigés en route** : sur une référence, les rangées du volet étaient inertes (le
gestionnaire ne cherchait que des blocs d'aide, et sous 1000 px `bindRevPanel` n'était jamais appelé) ; le volet en pied
ne suivait pas la frappe (`revProtoRefresh`).

## A458 — la coloration, par un calque sous le champ

`mdHlHtml` (pure) redessine le texte dans un calque aux métriques exactes du champ, dont le texte devient transparent :
marqueurs en gris, titres en 700 (Plex Mono : même chasse en 600 et 700), encadrés à LEUR registre, points de relecture
soulignés en ondulé ambre. Frappe, curseur, sélection et annulation restent ceux du champ natif. Défilement et largeur
de barre de défilement synchronisés. **Pointeur fin sans écran tactile seulement** : le champ d'iOS décale son texte de
quelques px, et un calque décalé serait pire que pas de calque. Alignement vérifié au pixel sur Chromium et WebKit (texte
du champ rendu en rouge par-dessus le calque : aucune doublure).

## Pliables (contrôle final)

Sous `horizontal-viewport-segments:2`, l'éditeur d'une référence prend la structure à colonne (`mqSeg`, re-rendu au
pli/dépli) : le texte sur le volet gauche, aperçu et relecture sur le droit, gouttière = charnière + 24 (règle de la
lecture, A405) ; barre au gabarit étroit. Mesuré (sonde CDP) : Surface Duo double portrait (charnière 34 px) et Pixel
Fold ouvert — champ, barre, aperçu, menu « Insérer » et fenêtre « Tableau » hors de la charnière ; Galaxy Z Fold fermé
(344 px), ouvert portrait (884) et paysage (1104), Galaxy Z Flip ouvert (412) : barre sur une ligne, aucun défilement
horizontal. **Reste ouvert** : la charnière HORIZONTALE (Surface Duo en double paysage, `vertical-viewport-segments`)
n'a de règle nulle part dans l'application — le contenu y défile à travers, comme en lecture.

## Formes écartées

Éditeur WYSIWYG (`contenteditable` : fragile sous iOS, et le Markdown perdrait sa portabilité) ; couleurs ou tailles de
police libres (elles casseraient les registres) ; modèles de protocole à doses pré-remplies (sortie individualisée, à
évaluer au § 2 avant tout développement) ; « tout corriger » dans la relecture.
