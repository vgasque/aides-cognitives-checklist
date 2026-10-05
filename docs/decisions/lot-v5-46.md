# Lot v5.46 — un vocabulaire, un nom par vue, des boutons qui se nomment (A461)

> Fichier normatif, suite de [`lot-v5-45.md`](lot-v5-45.md) (A460). Les numéros A sont des adresses : ne jamais
> renuméroter. Origine : [`docs/audit-apprentissage-2026-10.md`](../audit-apprentissage-2026-10.md), points 11, 12 et 13
> du § 8. Accord de l'auteur : « Ok poursuis ».

## A461 — trois chantiers de l'audit d'apprentissage

### 1. Le lexique est fermé : « aide », « protocole », « données »

« Fiche » cohabitait avec « aide », « parcours » et « référence » pour désigner le même objet, jusque sur un seul
écran (« 2 parcours », « 2 fiches d'exemple », « AIDE », « Aides »). Le texte affiché ne dit plus que trois mots :

| Mot | Ce qu'il désigne |
|---|---|
| **aide** | le parcours à cocher (ex-« fiche », ex-« parcours » quand il désignait le type, ex-« Aide de crise ») |
| **protocole** | le texte à lire (ex-« référence » quand il désignait le type) |
| **données** | aides et protocoles ensemble, dans les textes de compte, de synchro et de stockage. Le mot est féminin pluriel comme « fiches », donc les accords existants restent justes |

Restent à leur sens propre :
- **« parcours »** : l'arbre des blocs d'une aide (« Parcours · 4 blocs », « Recommencer le parcours ») ;
- **« Références »** : la bibliographie d'une aide.

« Doses & seuils », dans la palette de l'éditeur, devient « Repères posologiques », le nom de la section en
lecture.

Environ 85 chaînes sont réécrites. Les élisions sont écrites en dur (« l'aide », « d'aide »). Les deux fabriques à
accord variable (`confirmDraftLibChange`, `confirmNewInLib`) portent `la=fem?'l’':'le '`. Le prompt IA (`AI_PROMPT`)
n'est pas touché : il décrit le format JSON à une IA, et « fiche » y est un terme de format.

**Garde-fou : `scripts/check-lexique.mjs`**, branché sur `npm run check`.
- Il refuse « fiche » dans la PROSE : après un déterminant, un nombre ou une interpolation, ou avec une majuscule en
  tête de chaîne.
- Le code reste libre : `fiches`, `state.fiche`, clés de stockage.
- Il est vérifié capable d'échouer : un « fiche » réintroduit dans un `placeholder` est détecté.
- Limite dite : une tournure hors de ces contextes passe au travers. L'erreur tombe du côté du silence, jamais d'un
  faux rouge.

Deux harnais visaient un texte qui change ; ils visent désormais un attribut :
- `amorce()` cherchait « fiches d'exemple » et cherche maintenant `#seedAdd` ;
- la sonde de l'écran d'entrée cherchait « Tableau » et cherche maintenant `[data-prelink="page"]`.

### 2. Un nom et une icône par vue

| Vue | Nom (partout) | Icône |
|---|---|---|
| L'aide entière, en page | **Tout voir** (quai, réglage d'ouverture) ; « Page » est son onglet et sa fenêtre | `doc` |
| La même page dans une fenêtre | **Page** (ex-« Tableau », lien d'entrée et titre de fenêtre) | `doc` |
| L'organigramme | **Schéma** (ex-« Algorithme — aperçu automatique » dans l'éditeur) | `flow` |
| Le plan des blocs | **Se repérer** | `ladder` |
| L'affichage à 2 m | **Moniteur** | `monitor` (ex-`expand`) |
| Agrandir la Page | **Plein écran** (action, pas une vue) | `expand`, son seul usage |

Les noms accessibles disent « l'aide entière », plus « la fiche entière ». « Tableau » reste le nom de l'outil
d'insertion de tableau Markdown, qui est un autre objet.

### 3. Les pastilles de l'accueil se nomment, sous 780 px

Sous 780 px, l'en-tête d'accueil n'avait que trois icônes (horloge, +, silhouette) alors que la colonne large écrit
« Aides · Sessions · Moi ». Chaque pastille porte désormais son mot DESSOUS (`.hb-lbl`, ou `.hdr-new-lbl` pour
« Créer »), au palier `--t-cap`.
- **Disposition** : le mot est hors flux (`top:100%`), donc la cible ne change pas. L'en-tête gagne 24 px
  (16 en v5.46.0 : le mot restait à 3 px d'une carte suivante — 11 px au moins depuis v5.46.1).
- **Écart** : 14 px entre les pastilles (12 sous 400 px). « Sessions » déborde de 8 à 11 px de sa pastille.
- **Mesures** : libellés séparés d'au moins 9 px, et marque jamais coupée ni touchée, de 320 à 700 px et à 130 %.
- **Purge** : le palier 390 (« + Créer » en ligne, v5.18) et cinq règles d'écart A375 de l'en-tête d'accueil sont
  retirés avec leur cause.
- **Pas de `pointer-events:none`** : toucher le mot agit comme toucher la pastille (cliquet A68 inchangé).

**Non fait, par décision antérieure de l'auteur** : le bouton ◑ (thème) reste dans l'en-tête des aides et des
protocoles. C'est la décision v5.6 (« il faut le laisser visible en mode lecture/crise… c'est très important »).
L'audit le proposait au retrait ; il ne connaissait pas cette décision.
