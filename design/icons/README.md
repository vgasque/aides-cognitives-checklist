# Icône de l'application — sources vectorielles

Masters SVG du jeu d'icônes (handoff design, juillet 2026). Le glyphe associe un **cerveau**
(cognition/mémoire) et une **croix médicale**, blanc sur **bleu clinique `#1F5FA6`**.

> Ces fichiers ne sont **ni servis ni précachés** (absents de `ASSETS` dans `sw.js`) : ce sont les
> sources d'export. Les seuls fichiers servis sont les PNG à la racine du dépôt.

## Fichiers

| Master | Usage |
|---|---|
| `ios-icon-1024-square.svg` | icône pleine (fond + glyphe), **carré plein** — source des PNG « any » |
| `icon-master-white-glyph.svg` | glyphe blanc, fond transparent (à poser sur un aplat) |
| `icon-master-clinical-glyph.svg` | glyphe `#1F5FA6`, fond transparent (sur blanc) |
| `android-adaptive-foreground.svg` / `-background.svg` | calques adaptive Android — source des PNG **maskable** |
| `android-monochrome.svg` | calque monochrome (themed icons Android 13+) |
| `favicon-glyph-clinical.svg`, `icon-rounded-preview.svg` | favicon vectoriel ; aperçu coins arrondis (**jamais livré tel quel**) |

## Ce qui est effectivement servi (racine du dépôt)

| Fichier | Taille | Origine | Référencé par |
|---|---|---|---|
| `favicon.ico` | 16+32+48 | **généré** (`scripts/build-favicons.mjs`) | `<link rel="icon" sizes="any">` + requête implicite `/favicon.ico` |
| `favicon.svg` | vectoriel | **généré** (copie du master arrondi) | `<link rel="icon" type="image/svg+xml">` |
| `favicon-16.png` | 16 | **généré** | `<link rel="icon" sizes="16x16">` |
| `favicon-32.png` | 32 | **généré** | `<link rel="icon" sizes="32x32">` |
| `icon-192.png` | 192 | **généré** (`scripts/build-app-icons.mjs`, glyphe ~88 %) | `manifest.webmanifest` (`any`) — **plus aucun `<link>`** |
| `icon-512.png` | 512 | **généré** (`scripts/build-app-icons.mjs`, glyphe ~88 %) | `manifest.webmanifest` (`any`) |
| `icon-512.png` | 512 | export carré plein | `manifest.webmanifest` (`any`) |
| `icon-192-maskable.png` | 192 | foreground adaptive aplati sur `#1F5FA6` | `manifest.webmanifest` (`maskable`) |
| `icon-512-maskable.png` | 512 | idem | `manifest.webmanifest` (`maskable`) |
| `apple-touch-icon.png` | 180 | export carré plein | `<link rel="apple-touch-icon">` |

Tous sont listés dans `ASSETS` (`sw.js`) : disponibles hors ligne dès l'installation.

## Règles d'export

- **DEUX FORMES, volontairement divergentes** (ne pas « harmoniser ») :
  - icônes d'**application** (`icon-*.png`, `apple-touch-icon.png`, maskables) = **carré plein**,
    jamais de coins pré-arrondis ni de transparence : iOS et Android appliquent leur propre masque
    (l'ancienne icône v4.x arrondissait elle-même — double arrondi, glyphe rogné) ;
  - **favicon** (`favicon.*`) = **coins arrondis** (rx 22,5 %, master `icon-rounded-preview.svg`) :
    il n'est masqué par personne et se pose dans un conteneur déjà arrondi — un carré à angles
    vifs y jure avec le fond de l'emplacement (constaté sur Safari, v4.22.4).
- Les favicons sont **générés**, jamais exportés à la main : `node scripts/build-favicons.mjs`
  (rendu à la taille finale depuis le SVG, `.ico` 16+32+48 écrit à la main, zéro dépendance
  runtime). Rejouer après toute retouche du master arrondi.
- **Ordre des `<link rel="icon">`** : WebKit exploite `sizes` moins finement que Blink et peut
  retenir la dernière déclaration comprise — terminer la liste par le **32 px** pour qu'un repli
  naïf reste correct, et ne JAMAIS y déclarer une grande taille (le 192 y provoquait le liseré).
- **Maskable** = calque *foreground* aplati sur `#1F5FA6` plein cadre : le glyphe occupe ≈ 62 % du
  canvas, donc reste dans le cercle sûr de 66 % quel que soit le masque du lanceur.
- **Taille du glyphe : deux réglages** (leçon v4.22.5). iOS pose l'icône PLEIN BORD → glyphe à
  ~72 % sur `apple-touch-icon.png` (= ~72 % de la case). macOS (Safari « Ajouter au Dock », Chrome
  installé) place l'icône du MANIFEST dans une tuile à ~80 % du canevas → un glyphe à 72 % n'y
  ferait que ~58 % de la case. On COMPENSE : `icon-192/512.png` (`any`) portent un glyphe à **~88 %**
  (`scripts/build-app-icons.mjs`), qui retrouve ~70 % de la case après la marge macOS. Ne PAS
  agrandir `apple-touch-icon` — l'iPhone est déjà à la bonne taille.
- **Servir la taille NATIVE de l'emplacement.** Un favicon de 192 px dans un onglet de 16 px force
  une réduction ×12 : le filtre du rasteriseur échantillonne hors de l'image et laisse une arête
  d'un pixel semi-transparente, lue comme un **liseré blanc** sur une barre d'onglets claire
  (constaté en v4.22.2, corrigé en v4.22.3 par `favicon-16/32.png`). Vérification d'un export :
  aucun pixel du contour ne doit avoir un alpha < 255.
- Toute nouvelle taille s'exporte **depuis ces SVG**, jamais par agrandissement d'un PNG.
- Le bleu `#1F5FA6` est la couleur de marque de l'icône ; il ne circule pas dans le CSS de
  l'app (les couleurs d'interface restent les tokens `:root` d'`index.html`).
