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
| A345-A376 | `lot-v5-30.md` | La refonte v5 (puis v5.30.2 : verre flou iOS 27 peint par le système, sol sous l’heure sur toutes les vues ; pied de lecture purgé ; blur avant re-rendu du compte — A370-A372) : marque d'étape critique « 6b » (mot + bordure + sr-only, même corps — A11 rouvert), « Fin » au quai et confirmation maintenue, accueil/fiche/session alignés sur la maquette (badges achromatiques, cartes dépliables par fiche, capsule 64 px, pastille numérotée), capsule en en-tête au seul cockpit, sommaire de protocole en recherche, pliables ; A350 : une pastille glissante, en-tête sur l'ambiance, quai hors session sans matière, éditeur et Compte en cartes |
| A377-A381 | `lot-v5-31.md` | Minuteurs et compteurs LIÉS aux étapes : la coche lance (`starts`), la coche compte (`counts`), le bloc minute à chaque entrée (`timer`, avec la session au bloc de départ) ; effets dans le geste local seulement ; annulable par la case (10 s pour un minuteur), arrêt à la sortie de boucle, rien n'est choisi à l'échéance ; une légende d'une ligne (gris au repos, bleu sans fond en cours, pastille ambre à l'échéance, 24 px réservés) ; prompt IA : 0 à 3 liens par fiche ; micro-mouvements logiques de la légende (monter / remplir / redescendre, jauge des 10 s), rien sous mouvement réduit (A378) ; un délai repart au geste, jamais à la sonnerie (A379) ; essais d'affichage X1 « horizon » et X2 « bande », procédure garder/retirer (A380) A381 : quatre retouches (notice, recherche 16 px, étiquette hors flux, parcours du rail pliable). |
| A382 | `lot-v5-32.md` | Le moment d'une étape : commence au seuil d'un compteur, revient à l'échéance, une seule fois ou au besoin ; avant son moment, visible sans case et « Continuer » ne l'attend pas ; « Faire maintenant ». |
| A383 | `lot-v5-33.md` | L'éditeur : écrire n'ouvre rien, une feuille de réglages par étape (importance · coche · moment), pastilles au repos, moment/minuteur du bloc/jalons seulement si le bloc se répète, options du bloc repliées |
| A384 | `lot-v5-33.md` | Retours d'usage (v5.33.1) : rangée d'étape ouverte tant que le focus y reste (`.ed-on`), champs du bloc au gabarit des listes (15 px, M 40), glisser de pastille délégué au document, un dessin `.ed-ic` pour les boutons d'outil de l'éditeur |
| A385 | `lot-v5-33.md` | Partage (v5.33.2) : l'invité figé garde ses gestes (file, envoi au retour — renverse l'arbitrage d'A332) ; chez l'invité un lot ne s'applique qu'à la session partagée (sa propre session de la même aide recevait les coches de l'hôte) ; « Démarrer »/« Exercice » visibles sur ses aides |
| A386 | `lot-v5-33.md` | Le volet du quai sous le clavier (un champ du volet le garde en place, `kb-open` resynchronisée après la correction d'heure, le volet défile pour montrer le champ) ; rail rendu au flux en paysage de téléphone (`zh500`) |
| A387 | `lot-v5-33.md` | L'hôte qui consulte une autre aide : les gestes de l'invité vont à la session partagée (`hostedRt`, état séparé de la peinture — `shareStateLive`/`shareNavState`/`shareVfState`, `shareApplyAway`) ; seule la session hébergée émet (`shareEmitDiff`) |
| A388 | `lot-v5-34.md` | Le parcours : un dessin, trois lieux (carte, feuille, colonne) qui fixent densité et repli ; la colonne naît repliée, décisions comprises (branches gardées) ; réglages de coche en mots (« Si seuil : » par groupe, « si pas déjà faite », « toutes les 4 min ») ; complications « À tout moment » ; registre sans aplat, calé à droite de la première ligne |
| A389 | `lot-v5-35.md` | Accueil en une colonne (960 px), « Détaillée » cartes / « Compacte » une ligne au bureau ; « Gérer » les bibliothèques vers Moi ; « Tout voir » sans l'onglet « Parcours » (purge `.pc-*`) |
| A390 | `lot-v5-35.md` | Structure de l'éditeur en dépliant collant sous 1200 px ; aperçu « Essayer » fidèle à la vraie page (cartes, quai, minuteurs), « Fin » rejoue l'essai ; replis de l'aperçu non enregistrés |
| A391 | `lot-v5-35.md` | Page : sortie vers une branche de fourche qui rejoint sa barre (une pointe), retours de pilule par le bas, échelle des voies mesurée (animation d'ouverture), pointillés par segment ; moments en mots comme le parcours |
| A392 | `lot-v5-36.md` | Impression de la Page (bordures, une cale et un calque par page, repagination), Page sans cartes en double, losange centré, export d'une sélection, liens et sommaire des PDF, « ✓ faite » |
| A393 | `lot-v5-36.md` | Le PDF enregistré porte le nom de l'aide ; la pastille « Chemin » tient dans la colonne |
| A394 | `lot-v5-36.md` | « Branche » remplace « Chemin n » : blocs indentés le long d'un trait unique (coin + filet), « ■ Fin » (amende A376) |
| A395 | `lot-v5-36.md` | Page : le jalon suit les réponses en ligne « SI … [⚡] », en gris ; un seul dessin de « SI » (amende A391) |
| A396 | `lot-v5-37.md` | La revue « à tout moment » : bloc `review` hors tronc, étape-revue (nom hérité), grille dans la boîte, coches `visite:revue:index`, faite d'elle-même |
| A397 | `lot-v5-37.md` | La bande des repères du bloc : `item.poso`, un repère par étape liée, « fait · à faire · à préparer » venus de la coche, repliable, détail `item.note` ; icônes `pill`/`grid` |
| A398 | `lot-v5-37.md` | Une revue par session (`r:revue:index`, amende A396), collision `.rev-row` → `rv-step`, étiquettes de la grille, pas de CRITIQUE/VIGILANCE avant le moment, bande : « à préparer » avant le moment, rangées en deux lignes, gélule à moitié pleine |
| A399 | `lot-v5-37.md` | La capsule CRITIQUE/VIGILANCE d'une hypothèse s'ancre sur son libellé (plus de décalage en px) ; la tête de la bande des repères sur la grille des rangées |
| A400 | `lot-v5-38.md` | Le volet Outils mesuré (« MAINTENIR » 2,64 → 6,33:1, encre de nuit du volet), surface ajoutée à `audit-a11y`, et le harnais compose enfin l'alpha (deux voiles empilés ≠ blanc opaque) |
| A401 | `lot-v5-38.md` | Un rappel du chapeau sur une ligne, au dessin du parcours (`forgetItemHtml`) — plus la syntaxe de saisie |
| A402 | `lot-v5-38.md` | « ×2 » devient l'étiquette « Double contrôle », alignée sur CRITIQUE |
| A403 | `lot-v5-38.md` | Nom court (`short`, facultatif) sinon abrégé d'office (`autoShort`/`autoShortHead`) ; capsule et quai à 13,5, quai en casse de phrase, césure française |
| A404 | `lot-v5-38.md` | 44 px actifs hors crise par halo (épingle, notice, bandeau) |
| A405 | `lot-v5-38.md` | Pliables : `--hinge`, gouttière = charnière + 24, capsule/quai/fenêtres bornés au volet gauche ; harnais `audit-pliables` |
| A406 | `lot-v5-38.md` | Le rouge réservé à CRITIQUE et à l'alarme (Mode crise, Fin, complication, critères) |
| A407 | `lot-v5-38.md` | Barre de minuteur neutre (poste de pilotage sombre) ; règle 8 réécrite |
| A408 | `lot-v5-38.md` | Nuancier sorti des registres (vermillon retiré, Urgences en prune, quatre presets), garde-fou `catRegNear` au gestionnaire |
| A409 | `lot-v5-38.md` | « Terminer ? » : encadré neutre, l'étape vitale oubliée au registre critique |
| A410 | `lot-v5-38.md` | Capsule à la largeur du chrono quand les minuteurs sont au rail |
| A411 | `lot-v5-38.md` | Réponse attendue en mono casse de phrase (AC 120-71B / HF-STD-001) |
| A412 | `lot-v5-38.md` | « Journal » devient « Horodater » |
| A413 | `lot-v5-38.md` | « Créer » neutre au téléphone, tonal en large |
| A414 | `lot-v5-38.md` | « Vérifier » sans « :: » |
| A415 | `lot-v5-38.md` | La bulle d'apprentissage devient la sous-ligne du geste d'entrée (amende A331) |
| A416 | `lot-v5-38.md` | Les 38 alias purs purgés (table de correspondance), `check-tokens` refuse tout alias pur ; bleus pâles NON fusionnés (pas de survol) |
| A417 | `lot-v5-38.md` | Le survol bleu pâle devient visible (`--primary-100` : 1,6 → 5,4 ΔE le jour, 0 → 6,2 la nuit) |
| A418 | `lot-v5-39.md` | Le sommaire d'un PDF joint : colonne repliable en un bouton ≡ dès 1000 px, bande sous la barre en dessous ; numéros de page, section en cours, saut sur le titre (`pdfDestPos`), sauts de la visionneuse ~60 px trop bas corrigés |
| A419 | `lot-v5-39.md` | Le filtre de catégorie retient le NOM (`catKey`) : une catégorie renommée garde l'id de son homonyme d'une autre bibliothèque, et le filtre visait la mauvaise ; Entrée envoie l'e-mail de connexion |
| A420 | `lot-v5-39.md` | Le temps des audits se mesure : attentes fixes presque toutes utiles (rejouées réduites et triplées), pdfsearch ne paie plus 60 s de délais, tranches équilibrées par durée mesurée (`AC_PLAN`), quatre contrôles de partage qui dépendaient de la vitesse du harnais |
| A421 | `lot-v5-39.md` | « Afficher » ouvert par le bouton « Affichage » repeignait la vue d'ouverture par-dessus le type choisi (`viewSheetRedo`) ; l'anneau d'arrivée du quai devient un trait composé (`transform`/`opacity`, amende A331 sur la technique) |
| A422 | `lot-v5-39.md` | L'état d'une carte d'accueil passe au palier méta (12, 700 s'il attend quelque chose) : il était en 13,5/800, plus gras que le titre |
| A423 | `lot-v5-39.md` | Au téléphone, la recherche et le filtre flottent, opaques et séparés, sur un bord doux (plus de bande) — le modèle d'iOS 26 sans le verre ; `--shadow-float` |
| A424 | `lot-v5-39.md` | Ranger une sélection sur plusieurs bibliothèques : par nom, chacun dans la sienne, le sélecteur dit qui va où avant le geste (`selCatPlan`, `catNamed`) |
| A425 | `lot-v5-39.md` | Accueil sur écran très large : la colonne de 960 px se centre, l'en-tête et le bandeau suivent son axe (`--home-g`) ; six mises en page explorées, la colonne unique gardée pour son ordre de lecture |
| A426 | `lot-v5-39.md` | Cadenas de la colonne gauche alignés (colonne du nombre à 3 ch) ; pastilles d'accent décollées du cadre |
| A427 | `lot-v5-39.md` | Au retour dans l'app installée, les viewports visuel et de mise en page se recollent (`visibilitychange`, garde clavier, décalage négatif) |
| A428 | `lot-v5-39.md` | Filtrer par bibliothèque dans la feuille « Affichage » (même cran que la colonne gauche, `homeVis()`) |
| A429 | `lot-v5-39.md` | Feuille « Affichage » en deux parties (Filtrer / Présenter) ; filtres posés en puces effaçables sous la ligne de compte, même sans résultat (`filtersList`, `dropFilter`) ; « À relire » compté |
| A430 | `lot-v5-39.md` | Retour système en PILE RÉELLE : une entrée d'historique par niveau ouvert (`_H_LAYERS`, `_histSync`), rien poussé dans le retour — le balayage d'iOS et le retour prédictif d'Android montrent le bon écran ; amende J238 (v4.30.0) |
| A431 | `lot-v5-39.md` | La colonne gauche n'a qu'un bord droit : les étages fixes réservent la gouttière du défileur des catégories (« Gérer » ×2 alignés) |
| A432 | `lot-v5-39.md` | Gestionnaire de catégories : gouttière de carte (anneaux et palette hors du bord) ; l'avertissement « proche d'une couleur d'alerte » retrouve son ambre (`.ai-card p` l'écrasait) |
| A433 | `lot-v5-39.md` | La barre « ↩ Bloc » réserve sa hauteur au bas de page tant qu'elle est montrée (`bkrShow`, `body.bkr-on`) : la fin des références n'est plus dessous |
| A434 | `lot-v5-39.md` | Essais A380 tranchés : capsule en tuiles, instruments en colonne — les deux essais et leur outillage retirés, clés `ac-essai-*` purgées |
| A435 | `lot-v5-39.md` | Pastilles d'accent = l'avatar réel (carré arrondi, initiales, « Par défaut » bleu pâle) ; l'accent teinte les trois avatars du compte |
| A436 | `lot-v5-39.md` | Refus de caméra en carte ambre `.sl-cam` (icône, consigne, gestes) ; flèche ▾/▴ sur « Ce qui est enregistré, et par qui » |
| A437 | `lot-v5-39.md` | Le bandeau « Filtrer » réserve la cible de « Tout effacer » : 43 px avec ou sans filtre |
| A438 | `lot-v5-39.md` | « Administration » de Moi : rangée d'action en tête, tuiles de lecture, deux cartes côte à côte dès que la place le permet (`auto-fit`) |
| A439 | `lot-v5-39.md` | Sous charge (processeur ralenti) : k5 attend la fin de `grabWake`, `amorce()` n'ajoute plus les exemples en double, garde `_seeding` dans l'app, `keepAnchor` ne lit plus une ancre transformée (décalage permanent jusqu'à 6 px) |
| A440 | `lot-v5-40.md` | Une étape qui compte sur un compteur qui relance un minuteur : deux lignes de légende (compte, puis minuteur), grâce de 10 s étendue à la relance, « et relance … » dans les Réglages, « Compté par n étapes » sur la carte du compteur, avertissement « △ Minuteur cyclique » |
| A441 | `lot-v5-41.md` | La porte « Ajouter » de l'éditeur devient une pilule nommée à sous-titre (« Ajouter · bloc · minuteur · dose… »), filet `--act`, glose à toutes les largeurs ; ne recouvre rien en bas de page (mesuré) ; formes B, C, D, F, G écartées |
| A442 | `lot-v5-41.md` | Feuille « Affichage » : la pastille d'« Afficher » se peint avant l'action (signalé sous Chrome, non reproduit) |
| A443 | `lot-v5-41.md` | Colonne gauche : un acte inerte (cadenas) et le compte entrent dans le bouton de la rangée — les taper sélectionne la bibliothèque |
| A444 | `lot-v5-41.md` | « Options du bloc » toujours repliée à l'ouverture de l'éditeur (amende A383) ; le résumé de l'en-tête suffit |
| A445 | `lot-v5-41.md` | Nom d'un minuteur/compteur à 17,5/800 (n'est plus plus petit que « Nom court ») ; ligne « Facultatif — … » sous « Nom court » (`tmeShortRow`) |
| A446 | `lot-v5-41.md` | La porte « Ajouter » de l'éditeur devient REMPLIE `--act`, encre `--on-primary` (amende A441) — seule action primaire de l'éditeur |
| A447 | `lot-v5-41.md` | Recherche : le titre dit la bibliothèque filtrée (`homeResTitle`), les puces des filtres posés s'affichent sous les résultats, « Dans les documents » suit les mêmes crans |
| A448 | `lot-v5-41.md` | Parcours : une décision repliée n'est plus plus haute que dépliée — réponse, flèche et « · » forment une unité insécable (`.pf-brief .pf-opt` en `nowrap`) ; témoin rouge→vert |
| A449 | `lot-v5-42.md` | La revue « à tout moment » se dessine : fermée d'office, contour pointillé, jauge de n segments au lieu d'une case (`revRingHtml`), ligne neutre ; ouverte, des jetons à coche à droite (libellé immobile), réponse dans la ligne, colonnes au plus long libellé (`--rv-ch`, `auto-fit`) ; tête = bouton (`.rv-head`) |
| A450 | `lot-v5-43.md` | Le parcours suit l'arbre de `flowPlan` (numérotation inchangée), deux crans au plus : chaque réponse ouvre sa branche « SI réponse » sous sa décision, sans fond ; au-delà, « à ◇n » ; renvois « ↓ n » ; plus de pastille « Branche » (amende A394) |
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
