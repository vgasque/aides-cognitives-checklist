# design/ — export du Design System

Dossier **hors app** : rien ici n'est servi par la PWA (absent d'`ASSETS` dans `sw.js`).

1. **`ds/`** alimente le projet « Design System » de claude.ai/design
   (projectId `ded5aff6-1b5c-4813-919d-c9774c5163d1`).
2. **Les icônes** ne vivent plus ici : `design/icons/` a été SUPPRIMÉ avec l'identité de marque
   v1, et les masters vectoriels sont remplacés par **une géométrie unique dans un script**
   (§ 2 ci-dessous).

---

## 1. `ds/` — le design system généré

- `build.mjs` — génère `ds/` en **extrayant** tokens, `PALETTE` et CSS réels d'`index.html`
  (source de vérité unique ; **ne jamais éditer les fichiers générés**).
- `ds/` — sortie générée : **20 fiches HTML** (Fondations + Composants ; chaque fiche montre les
  deux thèmes et embarque le CSS complet, ce qui la rend **autonome** — c'est voulu, l'outil
  distant les lit isolément), `tokens/tokens.css`, et `GUIDELINES.md`.
- `ds/GUIDELINES.md` — **rédigé à la main**, seul fichier de `ds/` à éditer. ⚠ **Aucun script
  ne le régénère, donc rien ne signale sa péremption** : il est resté à la v4.34 pendant vingt et
  une versions, puis à la v4.55 pendant tout le chantier v5, décrivant trois surfaces supprimées.
  À relire à chaque lot qui touche une surface — c'est sa seule protection. Il RESTE dans `ds/` :
  la synchro pousse `design/ds/` *tel quel*, le déplacer d'un niveau le sortirait du périmètre
  envoyé au projet distant. `scripts/design-check.mjs` l'exclut donc explicitement de sa
  vérification de dérive (il n'est pas produit par `build.mjs`).

### Resynchroniser après une évolution du design

1. `node design/build.mjs`
2. Demander à Claude Code : « resynchronise le design system » (outil DesignSync, composant par
   composant — jamais de remplacement en bloc).

`npm run design:check` échoue si `ds/` a dérivé du CSS d'`index.html` ; `release.sh` régénère
automatiquement. Attention à sa mécanique en mode `--strict` : il régénère, compare, **puis
restaure** — un arbre propre après un échec ne veut donc pas dire qu'il n'y a pas de dérive.

> **Poids dans l'historique git.** Ces 20 fiches de ~275 Ko sont réécrites en bloc à chaque
> `design:build`, ce qui a représenté jusqu'à 190 Mo de blobs. Elles sont quasi identiques entre
> elles et d'une version à l'autre, donc elles se delta-compressent très bien : un simple `git gc`
> a ramené `.git` de 151 Mo à 6,2 Mo (v4.34.0). Ce n'est pas un défaut de structure — et il ne faut
> PAS dé-dupliquer leur CSS, qui est le prix de leur autonomie.

---

## 2. Les icônes — UNE géométrie, un script, dix cadrages

**`design/icons/` n'existe plus.** Il gardait une douzaine de masters SVG d'une identité
abandonnée (un cerveau associé à une croix médicale) ; l'identité de marque v1 les a tous
remplacés par **`scripts/build-icons.mjs`**, qui régénère **toutes** les icônes servies à
partir d'une seule géométrie déclarée en tête du fichier.

**La marque** : un **chronomètre coché à onglet** — un chronomètre dont la coupure de l'anneau
laisse sortir une coche, surmonté d'un onglet d'intercalaire. Le temps, la validation et le
protocole dans un seul signe, d'un trait d'épaisseur constante et à bouts coupés (SF Symbols
et Material 3 arrondissent ; l'arrondi date sa décennie).

**Pourquoi un script et non des fichiers binaires** : dix rasters dessinés à la main
divergent — c'est la leçon des listes tenues en double de ce dépôt. La marque n'existe qu'à un
seul endroit (`GLYPHE`), et chaque sortie n'est qu'un **cadrage** : couleur de fond, coins,
échelle.

```bash
node scripts/build-icons.mjs
```

> ⚠ **CHANGER CES OCTETS NE CHANGE PAS CE QUI EST INSTALLÉ.** `sw.js` range les icônes dans un
> cache versionné par `APP_VERSION` : sans `./release.sh X.Y.Z`, un appareil déjà installé garde
> les ANCIENNES icônes, indéfiniment et sans un mot — exactement le piège de pdf.js.

### Ce qui est servi (racine du dépôt)

Tous sont générés par `build-icons.mjs`, tous sont listés dans `ASSETS` (`sw.js`), donc
disponibles hors ligne dès l'installation.

| Fichier | Rôle |
|---|---|
| `favicon.ico` (16+32+48), `favicon.svg`, `favicon-16.png`, `favicon-32.png` | onglet |
| `icon-192.png`, `icon-512.png` | manifest, cadrage `any` |
| `icon-192-maskable.png`, `icon-512-maskable.png` | manifest, cadrage `maskable` |
| `icon-monochrome-512.png` | icône thématisée Android 13+ |
| `apple-touch-icon.png` | écran d'accueil iOS |
| `logo-glyph.svg` | la marque DANS l'app (accueil), posée en **masque CSS** sur `currentColor` |

### Règles d'export — ce qui ne se devine pas

- **L'échelle la plus contraignante n'est pas Apple mais Material 3** : l'icône adaptative ne
  garantit qu'un disque de 66 dp sur 108, soit **61 % du canevas**. Le cadrage `maskable` s'y
  tient ; les autres, que personne ne masque, respirent davantage.
- **DEUX FORMES, volontairement divergentes** (ne pas « harmoniser ») : les icônes
  d'**application** sont un **carré plein** — iOS et Android appliquent leur propre masque, et
  pré-arrondir produit un double arrondi qui rogne le glyphe ; le **favicon** est à **coins
  arrondis**, car personne ne le masque et il se pose dans un conteneur déjà arrondi.
- **Deux réglages de taille de glyphe** (leçon v4.22.5) : iOS pose l'icône PLEIN BORD, macOS
  (Safari « Ajouter au Dock », Chrome installé) la place dans une tuile à ~80 % du canevas — un
  glyphe calibré pour iOS y paraîtrait perdu. On compense sur le cadrage `any` ; ne PAS
  agrandir `apple-touch-icon`, l'iPhone est déjà à la bonne taille.
- **Ordre des `<link rel="icon">`** : WebKit exploite `sizes` moins finement que Blink et peut
  retenir la dernière déclaration comprise — terminer par le **32 px**, et ne JAMAIS y déclarer
  une grande taille (le 192 y provoquait un liseré).
- **Servir la taille NATIVE de l'emplacement** : un favicon de 192 px dans un onglet de 16 px
  force une réduction ×12, dont le filtre laisse une arête semi-transparente lue comme un
  **liseré blanc**. Vérification d'un export : aucun pixel du contour ne doit avoir un alpha
  < 255.
- Le bleu de marque ne circule pas dans le CSS de l'app : les couleurs d'interface restent les
  tokens `:root` d'`index.html`.

> ⚠ **DEUX SCRIPTS VESTIGES, à traiter** : `scripts/build-favicons.mjs` et
> `scripts/build-app-icons.mjs` lisent encore `design/icons/icon-rounded-preview.svg` et
> `design/icons/icon-master-white-glyph.svg`, **supprimés avec le dossier** — ils échouent donc
> si on les lance, et ils décrivent l'ancienne marque. `build-icons.mjs` les remplace tous les
> deux. Ils n'ont jamais eu de point d'entrée `npm`, ce qui explique que rien ne l'ait signalé.
