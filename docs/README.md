# Index de `docs/` — pour tout lecteur, humain ou IA

> Créé à l'audit v5.19.3. Ce répertoire n'avait AUCUN index en propre : le seul vivait dans
> `AGENTS.md` (que `CLAUDE.md` importe), donc un outil qui explore `docs/` en premier — une IA
> générique, un moteur de recherche de code — arrivait sur six fichiers portant le MÊME titre
> « Archive doctrinale » et ne pouvait pas résoudre un renvoi « cf. A140 » sans grep intégral.
> Ce fichier est l'index ; **il ne fait autorité sur rien d'autre** — la doctrine fait foi.

## Comment la doctrine se cite

Les décisions de conception portent des numéros **A1 → A288** (et ça continue), attribués dans
l'ordre CHRONOLOGIQUE, par lot de travail. Le numéro EST l'adresse : la doctrine se cite
elle-même par « cf. A140 », et c'est pourquoi le classement est par lot, jamais par thème — une
réorganisation thématique casserait chaque renvoi. Pour chercher par SUJET, la carte thématique
vit dans `AGENTS.md` (tableau « Où trouver quoi »).

## Où vit chaque plage A-xxx (`docs/decisions/`)

| Plage | Fichier | Sujet |
|---|---|---|
| A1-A112 | `refonte-v5-6.md` | Refonte « verre clinique, mat » — capsule/dock, trois matières |
| A113-A132 | `lots-v5-7-a-v5-9.md` | Retour au bloc, tri vivant, atelier d'import |
| A133-A138 | `lot-v5-10.md` | La Page devient un document (grille unique) |
| A139-A153 | `lot-v5-10-1.md` | Audit design externe |
| A154-A158 | `lot-v5-10-2.md` | Audit de code externe |
| A159-A169 | `lot-v5-11.md` | L'atelier d'import dit aussi où ça va |
| A170-A191 | `lot-v5-12.md` | Sélection multiple, titres repliables, chrome collant |
| A192-A197 | `lot-v5-12.md` (**second chapitre : lot v5.13**) | Clavier ouvert : le chrome cesse de poursuivre le viewport |
| A198-A221 | `lot-v5-14.md` | Partage sans serveur (clos, validé terrain) |
| A222-A224 | `lot-v5-15.md` | Lisibilité des barres flottantes |
| A225-A226 | `lot-v5-16.md` | Multi-import, QR agrandis |
| A227-A237 | `lot-v5-17.md` | Barre de sélection sur une ligne, moniteur multi-minuteurs, écrans véridiques |
| A238-A268 | `lot-v5-18.md` | L'accueil sans mécanisme |
| A269-A285 | `lot-v5-19.md` | Colonne à trois étages, pied unifié, audit design (halo en capture), audit interne v5.19.3-5 (tokens/ids/fonctions gardés par contrôle, CHANGELOG exécutoire, périmètre de déploiement, pli QR assaini, chaîne d'éditeur en paliers zw), anneau de focus repris par un `#id` (A285) |
| A286-A288 | `lot-v5-20.md` | Le rail A→Z pose sous ce qui coiffe (barre de sélection, bande de zone sûre) ; la gestion des catégories et des bibliothèques descend au socle en voie étroite ; les défileurs de l’accueil large gardent leur position à travers un re-rendu |
| (transverse) | `conventions-de-code.md` | La doctrine PAR COMPOSANT — registres, chrome, accueil, partage, stockage… (498 Ko : chercher par intitulé, cf. la carte d'`AGENTS.md`) |

⚠ Six fichiers (`conventions-de-code`, `refonte-v5-6`, `lots-v5-7-a-v5-9`, `lot-v5-10`,
`lot-v5-10-1`, `lot-v5-10-2`) partagent le titre H1 « Archive doctrinale — extraite d'AGENTS.md
(v5.10.3) » : ils ont été déplacés **à l'octet** (empreintes sha256 en tête) et ne seront pas
retitres — c'est CE tableau qui les distingue. Toute NOUVELLE entrée A va dans le fichier de son
lot, jamais dans `AGENTS.md`.

## Le reste de `docs/`

| Fichier | Contenu |
|---|---|
| `deploiement-et-conformite.md` | Kit de déploiement en établissement, statut réglementaire (non-dispositif-médical, § 2), registre RGPD **opposable** (§ 3-3.1), comparatif des hébergeurs (§ 1.1) |
| `conversion-v3-vers-v4.md` | Chemin de reprise d'un export v3 (hors application — cf. règle 12 d'`AGENTS.md`) |
| `changelog/v3.md`, `v4.md`, `v5.md` | Archives du CHANGELOG, une par version majeure ; les entrées s'y AJOUTENT EN FIN, telles quelles, quand `CHANGELOG.md` dépasse 20 (garde-fou : `scripts/check-changelog.mjs`) |
