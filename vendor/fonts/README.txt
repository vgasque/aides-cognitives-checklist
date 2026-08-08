Fontes vendorisées — sous-ensembles LATIN, format woff2. Trois familles, trois offices.

Fichiers  : source-serif-4-latin-600.woff2 (21 488 octets)   — TITRES de fiches, marque, compte rendu
            manrope-latin-var.woff2 (24 576 octets)          — INTERFACE (variable, graisses 500 à 800)
            ibm-plex-mono-latin-600.woff2 (10 120 octets)    — VALEURS mono (chronos, doses, comptes)
            ibm-plex-mono-latin-700.woff2 (10 128 octets)    — idem, graisse forte
Origine   : Google Fonts (fonts.gstatic.com) — Source Serif 4 v14, Manrope v20, IBM Plex Mono v20
Licence   : SIL Open Font License 1.1 pour les trois — redistribution autorisée, y compris
            embarquée. Source Serif 4 : https://github.com/adobe-fonts/source-serif/blob/main/LICENSE.md
            Manrope : https://github.com/sharanda/manrope/blob/master/LICENSE
            IBM Plex Mono : https://github.com/IBM/plex/blob/master/LICENSE.txt

POURQUOI EMBARQUÉES ET NON APPELÉES. L'application fonctionne HORS LIGNE par construction (SMUR,
sous-sol, mode avion) : une police appelée sur un CDN ne s'afficherait pas là où elle sert. Elles
sont donc servies depuis le dépôt, précachées par sw.js (entrées dans ASSETS) — et la CSP
n'autorise aucune origine externe pour les polices (font-src 'self').

POURQUOI LE SEUL SOUS-ENSEMBLE LATIN. Chaque sous-ensemble (latin-ext, grec, cyrillique) est du
poids embarqué pour rien : l'app est en français.

POURQUOI MANROPE EN FONTE VARIABLE, ET PLEX MONO EN DEUX STATIQUES. L'interface emploie QUATRE
graisses de l'échelle (500 · 600 · 700 · 800) : quatre fichiers statiques auraient pesé plus qu'un
seul variable de 24 Ko, et une graisse manquante aurait été SYNTHÉTISÉE par le moteur (plus lourde,
moins nette). Le mono n'en emploie que deux, où deux statiques sont plus légères qu'un variable.

CE QUE CE POIDS ACHÈTE (refonte v5.6, « verre clinique »). Les trois familles portent trois
natures et ne se croisent jamais : le SERIF ne sort que sur un titre de fiche (identité clinique
de v4.61, conservée), le MONO ne sort que sur une valeur qui ne doit jamais être amputée, Manrope
tient tout le reste. 45 Ko au total, précachés une fois.

MISE À JOUR = décision explicite (comme pdf.js) : re-télécharger, re-mesurer le poids, mettre ce
fichier à jour, rejouer `npm run check` (check-vendor compare les octets annoncés à ceux du
disque ; check-sw vérifie que chaque fichier existe et figure dans ASSETS).
