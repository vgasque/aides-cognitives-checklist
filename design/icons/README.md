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
| `icon-192.png` | 192 | export carré plein | `manifest.webmanifest` (`any`), `<link rel="icon">` |
| `icon-512.png` | 512 | export carré plein | `manifest.webmanifest` (`any`) |
| `icon-192-maskable.png` | 192 | foreground adaptive aplati sur `#1F5FA6` | `manifest.webmanifest` (`maskable`) |
| `icon-512-maskable.png` | 512 | idem | `manifest.webmanifest` (`maskable`) |
| `apple-touch-icon.png` | 180 | export carré plein | `<link rel="apple-touch-icon">` |

Tous sont listés dans `ASSETS` (`sw.js`) : disponibles hors ligne dès l'installation.

## Règles d'export

- **Jamais de coins pré-arrondis** ni de transparence sur les icônes « any » / iOS : iOS et Android
  appliquent leur propre masque (l'ancienne icône v4.x arrondissait elle-même — double arrondi).
- **Maskable** = calque *foreground* aplati sur `#1F5FA6` plein cadre : le glyphe occupe ≈ 62 % du
  canvas, donc reste dans le cercle sûr de 66 % quel que soit le masque du lanceur.
- Toute nouvelle taille s'exporte **depuis ces SVG**, jamais par agrandissement d'un PNG.
- Le bleu `#1F5FA6` est la couleur de marque de l'icône ; il ne circule pas dans le CSS de
  l'app (les couleurs d'interface restent les tokens `:root` d'`index.html`).
