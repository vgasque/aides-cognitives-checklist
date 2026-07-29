Source Serif 4 — sous-ensemble LATIN, graisse 600, format woff2.

Fichier   : source-serif-4-latin-600.woff2 (21 488 octets)
Origine   : Google Fonts (fonts.gstatic.com), famille « Source Serif 4 » v14
Licence   : SIL Open Font License 1.1 — redistribution autorisée, y compris embarquée.
            https://github.com/adobe-fonts/source-serif/blob/main/LICENSE.md

POURQUOI EMBARQUÉE ET NON APPELÉE. L'application fonctionne HORS LIGNE par construction (SMUR,
sous-sol, mode avion) : une police appelée sur un CDN ne s'afficherait pas là où elle sert. Elle
est donc servie depuis le dépôt, précachée par sw.js (entrée dans ASSETS) — et la CSP n'autorise
aucune origine externe pour les polices.

POURQUOI LE SEUL SOUS-ENSEMBLE LATIN, ET UNE SEULE GRAISSE. Chaque sous-ensemble (latin-ext, grec,
cyrillique) et chaque graisse est du poids embarqué pour rien : l'app est en français, et la
police ne sert QUE les titres (fiche, compte rendu, marque) en graisse 600. Le texte courant reste
system-ui — c'est la police que l'appareil rend le mieux, et changer le corps de texte d'une aide
lue sous stress n'a jamais été l'objet.

MISE À JOUR = décision explicite (comme pdf.js) : re-télécharger, re-mesurer le poids, rejouer
`npm run check` (check-sw vérifie que le fichier existe et qu'il est dans ASSETS).
