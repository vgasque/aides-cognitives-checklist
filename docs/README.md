# Index de `docs/` — pour tout lecteur, humain ou IA

> Créé à l'audit v5.19.3. Ce répertoire n'avait AUCUN index en propre : le seul vivait dans
> `AGENTS.md` (que `CLAUDE.md` importe), donc un outil qui explore `docs/` en premier — une IA
> générique, un moteur de recherche de code — arrivait sur six fichiers portant le MÊME titre
> « Archive doctrinale » et ne pouvait pas résoudre un renvoi « cf. A140 » sans grep intégral.
> Ce fichier est l'index ; **il ne fait autorité sur rien d'autre** — la doctrine fait foi.

## Comment la doctrine se cite

Les décisions de conception portent des numéros **A1 → A296** (et ça continue), attribués dans
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
| A286-A296 | `lot-v5-20.md` | Le rail A→Z pose sous ce qui coiffe (barre de sélection, bande de zone sûre) ; la gestion des catégories et des bibliothèques descend au socle en voie étroite ; les défileurs de l’accueil large gardent leur position à travers un re-rendu |
| A297-A307 | `lot-v5-21.md` | Le gestionnaire de catégories suit la bibliothèque affichée et montre une section par périmètre ; les catégories homonymes fusionnent en une rangée à pastille multicolore ; la jauge de « Maintenir » et la bordure du volet des minuteurs réparées ; l’hôte qui coupe le partage ne gèle plus celui qui conduit, et la main se reprend sans couper personne ; le compte des relances iOS clôt le diagnostic P2 (le poids du fichier est un non-sujet runtime, instrumentation retirée) |
| A308-A316 | `lot-v5-22.md` | Le gestionnaire de catégories en liste (une palette à la fois, « Ajouter » en tête, curseur de teinte OKLCH lisible par construction) ; le rail de session à 280 px entre 780 et 999, et ses deux ajouts sur une rangée ; la grille lit le token de colonne que le dock lisait déjà. |
| A317-A326 | `lot-v5-23.md` | Le partage sans question : un seul état « ● Partagé », détection de panne en 5 s et secours annoncé, retour automatique au cloud avec hystérésis, réveil qui ré-apparie seul, journal du lien. |
| A327-A329 | `lot-v5-24.md` | La feuille de partage dit quoi faire : canal choisi par l'app (par l'écran d'office sans adresse locale), étapes numérotées en miroir hôte/invité, bandeau = étape ①, l'hôte reçoit aussi, porte de secours « Mode : automatique › ». |
| A330 | `lot-v5-25.md` | L'écran d'entrée d'une aide se lit comme un écran de démarrage : trois chapitres sans numéro (les intitulés sortent de leurs cadres), aperçu du plan à plat, Tableau/Schéma à largeur de contenu, « En session » (rien ne démarre sauf le chrono), sur-titre « Avant la session » ; formes refusées consignées. |
| A331 | `lot-v5-26.md` | L'arrivée sur une fiche : le quai se relève puis trois anneaux (< 5 s, jamais de boucle), bulle d'apprentissage au-dessus du bouton jusqu'à la première session, « Exo. » sous 430 px ; formes refusées consignées. |
| A332 | `lot-v5-26.md` | Ce que la panne fait aux gestes : arrêt de minuteur daté chez l'autre, file de l'hôte jamais refusée pour péremption, retour de l'hôte sans invité par son billet, reprise de l'invité repeinte, bridage visible de l'invité périmé ; carte des situations réseau mesurées ; v5.26.3 : bouée de bascule sur les canaux dormants, « Hôte silencieux » chez l'invité que rien n'atteint. |
| A333-A335 | `lot-v5-27.md` | « Reprendre » après une complication ramène le passage interrompu (même visite, coches gardées) avec la carte ⚡ juste avant — renverse A126 ; replis et « entrée suivante du fil » suivent ; la barre « ↩ Bloc… » se resynchronise à tout changement de vue (elle survivait à « Terminer » sur l'accueil) ; l'inset de zone sûre compté deux fois sous la barre et le volet (42 px sur iPhone), icône `backto` sur les deux retours, éclair `bolt` rempli à la place de l'emoji ⚡. |
| A336-A343 | `lot-v5-28.md` | « Terminer la session… » au pied du volet et du rail (la fenêtre reste la seule porte) ; menu ⋯ refait — tuiles, intertitres, pli « L'aide », sans doublon du dock en session ; méta des rangées d'accueil : identité à gauche, un état en mots à droite ; retrait de profondeur du parcours en token additif (`--pl-ind`) ; fermer une photo garde la page où elle était (le moteur repose sa position une frame plus tard) ; moniteur — plafond du grand chiffre pris sur la bande rendue, plancher en taille VUE ; le dernier repère quitte le pied et se pose sur la bande à son instant (étiquettes en escalier, « + n repères avant », hors fenêtre au bord) ; la Page n'a qu'un axe vertical dans la fenêtre « Tableau » comme dans main (portée `main` de C87 retirée pour `.sv-scroll`) |
| A344 | `lot-v5-29.md` | La Page devient l'arbre lui-même : largeur A4, le numéro est l'ancre de tout trait, tronc/fourche/rail dessinés dans la colonne des numéros, sorties écrites et tracées à droite, cellules façon ECAM ; `flowPlan` numérote le tronc d'abord (arêtes de retour hors post-dominance, convergence à deux options au moins, sorties après le tronc) ; `svTreePlan` remplace `svGridPlan` |
| (transverse) | `conventions-de-code.md` | La doctrine PAR COMPOSANT — registres, chrome, accueil, partage, stockage… (498 Ko : chercher par intitulé, cf. la carte d'`AGENTS.md`) |
| C1-C135 | `doctrine-css.md` | Les commentaires longs du `<style>` d'index.html, repris à l'octet (A292) : un renvoi « doctrine-css.md C‹n› » dans la feuille se résout ici, sous l'id cité |
| J1-J239 | `doctrine-js.md` | Les commentaires longs du grand script d'index.html, repris à l'octet (A293) : un renvoi « doctrine-js.md J‹n› » dans le code se résout ici, sous l'id cité |

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
