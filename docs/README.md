# Index de `docs/` — pour tout lecteur, humain ou IA

> Créé à l'audit v5.19.3. Ce répertoire n'avait AUCUN index en propre : le seul vivait dans
> `AGENTS.md` (que `CLAUDE.md` importe), donc un outil qui explore `docs/` en premier — une IA
> générique, un moteur de recherche de code — arrivait sur six fichiers portant le MÊME titre
> « Archive doctrinale » et ne pouvait pas résoudre un renvoi « cf. A140 » sans grep intégral.
> Ce fichier est l'index ; **il ne fait autorité sur rien d'autre** — la doctrine fait foi.

## Comment la doctrine se cite

Les décisions de conception portent des numéros **A1 → A729** à la v5.123.1 (lot v6.0 compris ; A694 et A705 non attribués) (et ça continue — la
prochaine est A698), attribués dans
l'ordre CHRONOLOGIQUE, par lot de travail. Le numéro EST l'adresse : la doctrine se cite
elle-même par « cf. A140 », et c'est pourquoi le classement est par lot, jamais par thème — une
réorganisation thématique casserait chaque renvoi. Pour chercher par SUJET, la carte thématique
vit dans `AGENTS.md` (« Où trouver quoi » › « Carte par sujet »), avec la MÉTHODE de recherche à
suivre avant toute modification (lire la doctrine que le code cite, chercher par nom, la dernière
décision gagne, ne jamais reproposer une forme refusée).

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
| A382 | `lot-v5-32.md` | Le moment d'une étape : commence au seuil d'un compteur, revient à l'échéance, une seule fois ou au besoin ; avant son moment, visible sans case et « Continuer » ne l'attend pas ; « Faire maintenant » (retiré en A570 §9 : la case demande confirmation). |
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
| A451 | `lot-v5-43.md` | Case maîtresse à trois états à la place du segment « Tout cocher / Tout décocher », actes dépliés à glyphes, « 0 coché », mot-marque d'accueil à 17,5 sous 480 px — ce qui tenait sur Mac à 0 px près et débordait sous Linux/Windows (texte arrondi au pixel, barre de défilement classique) |
| A452-A459 | `lot-v5-44.md` | L'éditeur Markdown des références : liens vers les PDF joints sans identifiant à recopier, barre regroupée, saisie des listes au clavier, disposition par largeur et plan, tableau en grille, collage Word/PDF, relecture de l'écriture (doses), coloration ; pliables |
| A460 | `lot-v5-45.md` | Gains rapides de l'audit d'apprentissage : recherche (discriminant, Entrée), libellés entiers (Exercice, Catégorie, Bibliothèque), fin de session qui dit « maintenir », exemples « À relire », « Revoir l'accueil » |
| A461-A462 | `lot-v5-46.md` | Lexique fermé du texte affiché (aide · protocole · données, garde-fou `check-lexique`), un nom et une icône par vue, pastilles de l'accueil nommées sous 780 px ; tuile de compteur de la capsule : valeur puis nom entier (A462) |
| A463-A466 | `lot-v5-47.md` | Aide neuve en brouillon, lien direct et raccourcis d'icône, texte agrandi (quai, titre de bloc), « Prendre en main » et glossaire |
| A467-A472 | `lot-v5-48.md` | L'exercice guidé (une bulle par geste sur la vraie commande, en exercice seulement ; voile unique percé, v5.48.1) ; le guide et « Prendre en main » suivent l'app (`check-guide`, `audit-guide`) ; A468 (v5.48.5) : éditeur d'une référence, aperçu en colonne dès 780 et barre au-dessus du clavier ; A469 (v5.48.6) : ses menus au-dessus de la barre, clavier gardé ; A470 (v5.48.7) : toucher sans lâcher le champ ; A471 (v5.48.8) : toute la surface garde le champ ; A472 (v5.48.9) : sous la barre, la zone de Safari (rattrapage de 12 px)  |
| A473-A474 | `lot-v5-49.md` | A473 : déconnexion d'un seul appareil, deux compteurs entiers dans la capsule et « +n » au rappel, deux espacements ; A474 : la jauge d'un seuil dans son étiquette, case estompée (amende A382), l'instant du seuil animé chez celui qui a fait le geste |
| A475-A477 | `lot-v5-50.md` | A475 : les collections, rangement personnel sans copie (Accès direct = première collection, filtre, cases, lecture seule) ; A476 : barre de sélection en tiroir à toute largeur ; A477 : « Avec qui ? » à la création d'une bibliothèque, collection proposée sans invité, conversion |
| A478-A479 | `lot-v5-51.md` | A478 : le droit de créer une bibliothèque (règle d'instance, personnes autorisées, `can_create_library`) ; A479 : demander une bibliothèque, file de l'administrateur |
| A480-A482 | `lot-v5-51.md` | A480 : tête de feuille (lien de retour, titre = le geste, ligne de contexte) ; A481 : confirmation de la règle de création ; A482 : design system relevé sur l'app (captures du DOM réel) |
| A483-A484 | `lot-v5-52.md` | Administration : tous les comptes (dépliables : statut, droit de créer, rôles) et toutes les bibliothèques de l'instance ; A484 : gérer celle d'un autre (membres, nom, suppression) sans en être membre |
| A485-A489 | `lot-v5-53.md` | Retours après les collections ; la colonne dit avec qui (option 1), une seule bibliothèque = une rangée et « Partager avec une équipe… » |
| A490-A493 | `lot-v5-54.md` | Bibliothèque vide dans la colonne, position gardée au retour (toute largeur), anneau d'ouverture au clavier seulement, « Tout » des collections |
| A494-A495 | `lot-v5-55.md` | Administration devient une page à sections ouverte depuis Moi : À traiter, comptes et bibliothèques à l'échelle (recherche, filtres, pages de 40, lot), règles confirmées ; une rangée de règles, retour au-dessus du titre à toute largeur |
| A496-A498 | `lot-v5-56.md` | La collection se choisit à la création (rangée « Collections » de la pancarte d'identité, feuille à cases de l'accueil réutilisée), « Nouveau protocole » ; le voile d'une feuille absorbe le tap au lieu de le laisser passer à ce qu'il couvre ; le menu des catégories dit ce qu'est une catégorie |
| A499-A501 | `lot-v5-57.md` | Le pied « Tout est prêt » déplié ne répète plus la version ; la pastille du compte suit l'avatar « Moi » de la colonne au bureau, anneau de nuit renforcé ; A501 : la colonne gauche de l'accueil pose sous la barre d'état de l'iPad installé |
| A502-A510, A513-A515 | `lot-v6-0.md` | REFONTE « Natif » (décidée sur maquettes ; implémentée par lots de v5.58 à v5.66, A515-A522) : direction retenue et formes écartées (Cockpit, Document, verre généralisé) ; capsule et quai en verre clair en thème clair ; barre d'onglets au téléphone ; grand titre 34 px ; listes groupées à rangée à quatre emplacements ; cases rondes ; feuilles du bas et menu ⋯ ancré ; A509 : le moniteur reste un afficheur, bande en carte à rangées nommées ; A510 : arbitrages après mesure de 266 vues (verre à 90 % et volets en verre, onglet ≠ niveau de retour, recherche au clavier, titres 15/17,5, menu ⋯ en feuille au téléphone, aide en cours en tête), ordre des lots révisé, défauts actuels relevés |
| A511 | `lot-v5-57.md` | Correctifs d'une mesure sans a priori (1 436 mesures) : en paysage bas la capsule monte dans l'en-tête (exception à A354) ; le quai garde ses mots à toute largeur (étend A465) ; retour nommé, contrastes `--ink-3`, halos de session ; garantie du moniteur sur la bande rendue. (A502-A510 : refonte « Natif », lot v6.0) |
| A512 | `lot-v5-57.md` | Zones sûres latérales (`--sal`/`--sar`) : rien sous l'encoche ni l'île en paysage — trouvé au simulateur iOS ; césure des étapes sous Safari iOS laissée en question |
| A513 | `lot-v6-0.md` | Refonte : la carte de décision perd son fond ambré (mot seul en ambre, renverse A345) ; un téléphone tourné prend la colonne gauche, iPhone SE compris |
| A514 | `lot-v6-0.md` | Lot 2 de la refonte, outillage : `audit-verre` (contraste au pixel sous capsule et quai), `audit-retour` au téléphone, crans 34/28 du titre de page admis pour `.pg-ttl` seul |
| A515 | `lot-v6-0.md` | Lot 3 de la refonte (v5.58.0) : cases rondes partout (36 px en session, jauge en rond plus grand) ; accueil en rangées groupées, plus de liseré, épinglées en premier groupe (renverse A261, tuiles purgées) |
| A516 | `lot-v6-0.md` | Lot 3 réaligné sur la maquette (v5.58.1) : point de catégorie 10 px en tête, sous-ligne « Aide · SMUR · adulte · △ À relire », rangée 52 px, filet au texte, groupes sans bord, intertitres en phrase ; amende A338 (nature en minuscules, état à la suite) et A422 (état sans aplat) |
| A517 | `lot-v6-0.md` | Lot 4 de la refonte (v5.59.0) : au téléphone, barre d'onglets flottante (Aides · Sessions · Moi + recherche), Sessions/Moi en onglets sans niveau de retour, rangée du haut (Sélectionner, Créer) et grand titre 34 qui se replie, champ et pastilles de filtre ; en large, titre 28 ; le titre précède l'Accès direct |
| A518 | `lot-v6-0.md` | Lot 5 de la refonte (v5.60.0) : capsule, quai et volets en verre clair en thème clair (tokens système redéclarés en contexte, repli opaque) ; sonde `audit-verre` qui lit `color()` ; moniteur Natif (« ● Session », « Revenir » en pilule, barre de progression neutre, carte à rangées nommées, étiquette = le temps) |
| A519 | `lot-v6-0.md` | Session Natif, arbitrages de l'auteur (lot 6, v5.61.0) : étapes à plat et registre sans fond (amende A345), légende du bloc retirée et numéro discret, « Session » au lieu de « MODE CRISE » et thème dans ⋯ (amende A14), repères en une ligne et jalon au pied (amende A397, A450) ; décision sans fond ambré (A513 §1) |
| A520 | `lot-v6-0.md` | Surfaces Natif, arbitrages de l'auteur (lots 7-11 ; démarrage v5.62.0, Sessions et Moi v5.63.0, éditeur habillage v5.64.0) : démarrage en listes groupées (amende A330), éditeur en rangées de réglages en deux lots (habillage puis navigation), Sessions en rangées par jour, Administration en liste et fiche au bureau (amende A494) ; Moi et la Page proposés sans question |
| A521 | `lot-v6-0.md` | L'éditeur se parcourt (lot 10, v5.65.0) : Identité en rangées « Titre · valeur › », structure en liste dans le fil (amende A390, `edTocHtml` purgé), un bloc s'ouvre sur sa page (`state.edFocus`, classes `ed-ov`/`ed-focus`, niveau du retour système) |
| A522 | `lot-v6-0.md` | Administration au bureau et la Page à la maquette (lot 11, v5.66.0) : sections en segmenté, intertitres en phrase, statut en pastille ; Page avec « Fermer », échelle segmentée dans la barre, Imprimer · Exporter en PDF, feuille centrée sur fond gris |
| A523 | `lot-v6-0.md` | Groupe « En cours » en tête de l'accueil (A510 §6, v5.67.0) : l'aide en session quitte sa section, « ● Session mm:ss » ; carte sombre retirée (sauf session partagée), « Terminer » reste dans la session |
| A524 | `lot-v6-0.md` | Une seule recherche au téléphone, le rond de la barre d'onglets (v5.67.1, arbitrage de l'auteur) : champ-leurre sous le titre purgé (amende A517) ; « ● Session » sans « · » orphelin |
| A525 | `lot-v6-0.md` | Menu ⋯ ancré en large : voile transparent qui absorbe le tap de fermeture (A510 §5, v5.68.0) |
| A526 | `lot-v6-0.md` | Un téléphone tourné prend la colonne gauche quelle que soit sa largeur (A513 §2, v5.68.0) : une liste de media queries partagée par le CSS et `mqHomeWide` |
| A527 | `lot-v6-0.md` | Seul le protocole dit sa nature sur sa rangée ; l'aide n'écrit plus « Aide » (arbitrage de l'auteur, v5.69.0) |
| A528 | `lot-v6-0.md` | Au téléphone, « Affichage » est la première pastille ; plus de ligne du compte (arbitrage de l'auteur, v5.69.0) |
| A529 | `lot-v6-0.md` | La Page n'a qu'un bouton « Imprimer ou PDF » (arbitrage de l'auteur, v5.69.0) |
| A530 | `lot-v6-0.md` | Remesure : tout ce qui se clique répond au survol, une rangée ne se soulève plus (v5.70.0) |
| A531 | `lot-v6-0.md` | Remesure : intertitres et étiquettes en phrase partout, mots d'état en capitales (v5.70.0) |
| A532 | `lot-v6-0.md` | Remesure : téléphone tourné, « Schéma » au menu ⋯ ; sous 360 px l'état « Avant la session » se retire (v5.70.0) |
| A533 | `lot-v6-0.md` | Remesure : grand chiffre du moniteur à 28 vw en portrait (v5.70.0) |
| A534 | `lot-v6-0.md` | Conformité aux maquettes (v5.71.0) : colonne « Parcours » en liste légère, « Cochez les n restantes », comptes de la colonne gauche |
| A535 | `lot-v6-0.md` | Rail de session à la maquette (v5.72.0) : compteur « − 1 + », minuteur en aplat gris, jalon à jauge et sous-ligne |
| A536 | `lot-v6-0.md` | Bords au téléphone (v5.72.1) : barre collante pleine largeur, « Fermer » de la Page, rien de fixé sous une feuille opaque (bande de Safari 26) |
| A537 | `lot-v6-0.md` | Vue compacte au dessin Natif (52 px au téléphone, 44 px en large), accès direct en tuiles (renverse A515 §4), « Affichage » aligné (v5.73.0) |
| A538 | `lot-v6-0.md` | Recherche du bas à la hauteur de la barre d'onglets (62, clavier fermé) ; contraste du dock sombre mesuré (v5.73.0) |
| A539 | `lot-v6-0.md` | Onglet actif en pastille pleine (1,2 → 7,8:1), avatar de « Moi » et point vivant bordés (v5.73.0) |
| A540 | `lot-v6-0.md` | Barre collante de l'accueil en verre dans l'app installée (`--sat` lu 0 : `insetPx`) ; piste « default » d'iOS 27 mesurée, non retenue |
| A541 | `lot-v6-0.md` | Au téléphone, l'en-tête vidé par les onglets garde la réserve de la barre d'état : accueil, Moi, Sessions n'étaient plus tronqués au repos (v5.73.2) |
| A542 | `lot-v6-0.md` | Une seule bande en haut une fois défilé : le sol sous l'heure prend la teinte de la barre collée (v5.73.3) |
| A543 | `lot-v6-0.md` | Barre d'onglets et recherche au bas d'iOS (`--tb-bot`, 24 pt sur Face ID, 12 px sinon) (v5.73.3) |
| A544 | `lot-v6-0.md` | Recherche → filtre → quitter : la barre d'onglets revient (focusout du dock, tap hors du dock) (v5.73.4) |
| A545 | `lot-v6-0.md` | Au téléphone, le titre choisit : feuille « Afficher » (collections, catégories, comptes), un filtre à la fois, plus de rangée de pastilles ; « Affichage » en rond (v5.74.0) |
| A546 | `lot-v6-0.md` | Éditeur de référence : voir en écrivant — bande du bloc rendu au téléphone (œil retenu), source et rendu à parts égales au bureau (défilement lié), vignette des images dans le calque, sections déplacées par le Plan (v5.75.0) |
| A547 | `lot-v6-0.md` | Mise en forme en direct : le document s'édite par blocs (rendu = éditeur, un bloc ouvert en Markdown, gestes et ajout de blocs, copie en Markdown), interrupteur retenu sur l'appareil ; bande au-dessus du clavier retirée (v5.76.0) |
| A548 | `lot-v6-0.md` | Bloc ouvert réglé sur place : registre d'un encadré en pastilles, image et sa taille, « Remplacer… » ; glisser un bloc à la souris (v5.77.0) |
| A549 | `lot-v6-0.md` | Déplacer un bloc d'une référence par « Prendre / Poser », le geste de l'éditeur d'aide (bandeau, cibles « Poser ici », reste inerte) ; Monter/Descendre et la poignée de glisser retirés (v5.78.0) |
| A550 | `lot-v6-0.md` | Le document par blocs garde le rythme de la lecture : marges du rendu, survol en outline, « ＋ » entre blocs retirés (« Bloc après »), bloc ouvert allégé (v5.78.1) |
| A551 | `lot-v6-0.md` | Toute modification pose son point de reprise (↶) : gestes du document par blocs, et une 3ᵉ accroche `change` délégué (taille d'image, date de validation) (v5.78.2) |
| A552 | `lot-v6-0.md` | Un toucher en dehors referme le bloc ouvert, donc découpe un collage en ses blocs ; barre, menus, fenêtres exclus ; ↶ défait le collage entier (v5.78.3) |
| A553 | `lot-v6-0.md` | « ↷ Rétablir » (pile `_edRedo`, Maj-Cmd/Ctrl-Z, Ctrl-Y) ; le découpage d'un collage s'annonce ; un accusé de geste remplace le précédent (v5.79.0) |
| A554 | `lot-v6-0.md` | Pincer pour zoomer la Page et le PDF « comme une feuille » (`pinchBind`, `pan-x pan-y`, calque transformé pendant le geste, re-tramé au lâcher, point sous les doigts) ; renverse le « pas de pinch » d'A133/J175 ; canevas PDF plafonné, plus de page blanche après zoom (v5.80.0) |
| A555 | `lot-v6-0.md` | Le pincer d'A554 s'applique aux images ouvertes : défileur `#lbScroll`, taille posée en ligne au lâcher (`lbFit`), ajustée → ×6, tap sur le fond qui ferme, ✕ au-dessus (v5.81.0) |
| A556 | `lot-v6-0.md` | Au téléphone, « Aides ⌄ » = QUOI (type et bibliothèque en tête d'« Afficher », « Gérer » avec les catégories), le bouton rond ↑↓ = COMMENT (« Trier et présenter », pied « Terminé ») ; `#filtTog` purgé, `syncDockFilt` ; amende A545, A353 (v5.82.0) |
| A557 | `lot-v6-0.md` | Redimensionner en état zoomé garde le point regardé (image, PDF, Page) : point au centre retenu en proportion du repère, remis au centre ; `_svAncre` pour la Page re-rendue (v5.82.0) |
| A558 | `lot-v6-0.md` | Le pincer d'A554 s'applique au plein écran du schéma (`#flowFull`) : SVG transformé pendant le geste, `flowZoom` fixé et re-tracé au lâcher, 40-400 % (v5.83.0) |
| A559 | `lot-v6-0.md` | L'aperçu du schéma dans la page se pince aussi (`flowPinchBind`, échelle `flowZoom` partagée, défileur vertical choisi à la volée, `_flowAncre` au redimensionnement) (v5.84.0) |
| A560 | `lot-v6-0.md` | « Identité » se plie depuis son intertitre (« Modifier ⌄ » / « Replier ⌃ », `.id-tgl`) ; ouverte, la carte ne rogne plus le menu des catégories (v5.85.0) |
| A561 | `lot-v6-0.md` | Toucher à côté annule un déplacement « prendre / poser », dans les deux éditeurs (`grabOutBind`, `GRAB_KEEP`, tap absorbé hors barre d'en-tête) (v5.85.0) |
| A562 | `lot-v6-0.md` | Importer une page Notion telle qu'exportée : .zip (page .md + dossier d'images en chemins relatifs) ou .md seul → une référence en brouillon (`notionMd`, `notionImgPaths`, `notionRefs`) (v5.86.0) |
| A563 | `lot-v6-0.md` | Le retour système ne recule jamais deux fois : un parcours d'historique en retard n'est pas perdu (`_hWatch`, amende A430) ; trois sondes fiabilisées sous charge (v5.86.1) |
| A564 | `lot-v6-0.md` | Les harnais attendent que l'écran se pose, pas une durée : `__acCalme`/`calme` (pauses de rendu < 700 ms), horloge gardée ; témoin `audit-calme` (outillage) |
| A565 | `lot-v6-0.md` | Le pool d'audit suit la machine (2 × cœurs, 8 au plus, borné par la mémoire) ; doctrine en 6 tranches, a11y en 3, guide en 2 (outillage) |
| A566 | `lot-v6-0.md` | En CI, l'audit en trois lots parallèles (`--lot k/n`) ; `--bilan` exige que leur union soit la passe complète ; poids de `HARNAIS` re-mesurés (outillage) |
| A567 | `lot-v6-0.md` | Les optimisations de l'audit se gardent seules : cliquet `check-pauses` (pauses fixes courtes), alertes de fin de passe « poids à re-mesurer » / « à découper » (outillage) |
| A568 | `lot-v6-0.md` | Quai à 320 × 130 % : cran `lbl-fit` (« Fin » et « Tout voir » à 44 px quand un mot déborde encore au plancher) ; sondes « bridage » et A465 (v5.86.2) |
| A569 | `lot-v6-0.md` | Étapes complexes : « ✓ … ≥ n » vert, « Échu » ambre, « Faite » vert rendus (régression d'A519, sans témoin), l'instant du seuil finit à plat, « faite une fois » sans contour, règles de moment en phrase et mots d'état en capitales (étend A531), « passage n/N » insécable (v5.87.0) |
| A570 | `lot-v6-0.md` | Étapes complexes : une place par chose (tête = quand en mots nus, pied = ce que fait la coche), liste à filets sans cadre ni aplat (renverse A519 §1, A382/A474/A449 pour le pointillé), une seule taille de libellé, minuteur attendu dans la tête, « ✓ À l'échéance » (comme un seuil atteint), « ✓ Déjà faite », une seule coche (relevé « ✓ » de la réponse retiré), une police dans la rangée (amende A411), plus de « Faire maintenant » : la case demande confirmation sur place et dit ce qui reste (« Prévue dans 2 chocs délivrés. », v5.88.1), mots courts, hauteur fixe ; mesuré contre la maquette (v5.88.0) |
| A571 | `lot-v6-0.md` | Session, passe 2 Natif : titre sur deux lignes, chevron de la capsule, historique en texte gris « Historique · … » sans le mot « Parcours » (amende A369/A510), boutons du bloc en capsules de 48, quai aligné par le haut sans filets et « Complications » à pastille (renverse A355), sections en une liste « Pendant toute l'aide » (amende A519), « Contexte local », rail en listes groupées (A506 ; renverse C79, A309) |
| A572 | `lot-v6-0.md` | Le pool d'audit compte la mémoire DISPONIBLE (macOS : free + inactive + speculative via `vm_stat`, `memDispo()`), plus `freemem()` seule qui donnait pool 1 sur un Mac en usage ; un pool bridé par la mémoire s'annonce « △ pool n au lieu de m » avec sa mesure (amende A565, outillage) |
| A573 | `lot-v6-0.md` | Le minuteur du rail en marche, en pause ou échu s'empile (nom · temps, barre, état, boutons sur leur ligne) ; la consignation d'un compteur en sous-ligne de l'interface (corrige A571 §7) |
| A574 | `lot-v6-0.md` | La barre « ↩ Bloc » rejoint les redéclarations du verre clair (A518) : le vert de page, plus le vert nocturne |
| A575 | `lot-v6-0.md` | En session, la barre d'échelle de la Page colle à `--stick-top` : pincer ne la fait plus passer sous l'en-tête |
| A576 | `lot-v6-0.md` | L'étape en attente s'arme en touchant toute sa rangée, comme une étape ordinaire se coche (amende A570 §9) ; « Prévue dans 2 CEE. » : la minuscule de `momRestLbl` épargne les sigles |
| A577 | `lot-v6-0.md` | Banderole d'un minuteur échu au dessin du segment « Échu » de la capsule (forme C, amende C84), retirée quand la session qu'elle annonce redevient visible ; « Quand l'utiliser » et « Ne pas oublier » en cartes à tête sans porte (amende A520 §1) ; « Prêts pour la session » en liste groupée |
| A578 | `lot-v6-0.md` | En session, les sections sous le bloc redeviennent des cartes, le dessin du démarrage (renverse A571 §6 ; l'intertitre « Pendant toute l'aide » part, « Contexte local » reste) |
| A579 | `lot-v6-0.md` | Titre d'une rangée de l'accueil : interligne 1,3 (était 1,15) sous le masque du clamp, marge −0,075 em — g, q, y, p, ç et accents des capitales ne sont plus rognés, hauteur d'une rangée inchangée |
| A580 | `lot-v6-0.md` | La Page « Tout voir » se centre dans sa colonne (règle `.sv-calant` de la fenêtre « Tableau » généralisée) |
| A581 | `lot-v6-0.md` | Fenêtre « Page » : l'annonce « la feuille dépasse à droite » pend sous la barre en languette, hors du flux — elle ne pousse plus les outils sous le titre au zoom |
| A582 | `lot-v6-0.md` | En session, l'annonce du débordement pend sous la barre d'échelle collante (étend A581) : « + » et « 1:1 » ne passent plus à la ligne au zoom |
| A583 | `lot-v6-0.md` | Les images d'une référence : une grille repliée « Images du texte » sous le contenu rédigé, une feuille par image (insérer, aller au passage, taille, remplacer, retirer) ; l'image entre dans la porte ; les PDF restent au-dessus (ordre lu) |
| A584 | `lot-v6-0.md` | La taille d'une image se voit et se tire : un cadre (la colonne lue), une poignée aimantée aux crans, six pictogrammes ¼ ⅓ ½ ⅔ ¾ Pleine ; bloc ouvert et feuille de l'image (amende A548) |
| A585 | `lot-v6-0.md` | Les images d'une aide : la grille et la feuille des références (légende sous la vignette, « ▣ Bloc n », feuille avec légende, « Affichée dans », remplacer, retirer) ; feuille rendue générique (`_miCtx`) |
| A586 | `lot-v5-94.md` | Liens d'application : `#creer`, `#acces-direct`, `#bibliotheques`, `#bibliotheque=<id>`, `#collection=<id>` (table fermée, écriture inverse) ; Moi › « Liens et raccourcis » donne chaque lien ; quatre raccourcis au manifeste ; limite d'iOS dite (amende A464) |
| A587 | `lot-v5-95.md` | Accueil à l'échelle (v5.95.0) : « Vos collections » en tête, repliées, dépliables sur place ; « Tout » dessous, rangé par « Regrouper » ; réglage « Vos collections : En tête / Non » (« Non » = l'accueil de la v5.94) ; F1 « regrouper par collection » écartée (amende A489 sur l'accueil) |
| A588 | `lot-v5-95.md` | Le répertoire se plie par groupe (déplié par défaut, pli retenu par regroupement, « Tout replier ») ; le groupe courant se dit dans le petit titre collé au téléphone (A542), intertitre collant en large (amende A506/A515) |
| A589 | `lot-v5-95.md` | Provenance : la tuile d'Accès direct dit sa bibliothèque (amende A537), séparateur hors pastille, pas de redite de catégorie dans la méta, nom de bibliothèque jamais tronqué pour son mot de partage |
| A590 | `lot-v5-96.md` | La rangée « En cours » de l'accueil redevient la bande de session (amende A523, reprend A356) : matière système, sans étoile, bloc courant, « Reprendre » et « Terminer… » (confirmation maintenue, jamais rouge) ; périmètre vert en thème sombre, partagé avec la carte de session partagée |
| A591 | `lot-v5-96.md` | La carte « Session terminée » suit la bande (v5.96.1) : plus de liseré de 4 px, une seule place (sous le titre, juste avant « En cours »), compte des blocs en mots sans coche ; survol de « Terminer… » corrigé en thème sombre (A590) |
| A592 | `lot-v5-96.md` | L'ordre alphabétique des collections se rétablit à l'entrée (v5.96.2) : `sanitizeColls` trie (`collCmp`), renommer re-range ; corrige le renommage et le pull cloud qui laissaient la liste hors d'ordre (applique A475, A587) |
| A593 | `lot-v5-97.md` | L'établi de l'éditeur de référence (amende A546, A468) : texte et aperçu en deux cartes partant de la même ligne, même hauteur, défilement lié dans les deux sens ; poignée ⋮ (glisser aimanté ⅓ ½ ⅔, clavier, double-clic), part retenue sur l'appareil (`ac-mdsplit`) ; relecture en badge ; identité sur une ligne ; pied au-dessus de la porte « Ajouter » |
| A594 | `lot-v5-98.md` | La poignée de l'établi suit le doigt (le `ResizeObserver` repeignait l'ancienne part : « ça saute entre 3 tailles ») ; bornes 30-70 % aux largeurs étroites (corrige A593) |
| A595 | `lot-v5-98.md` | Au téléphone, l'accueil dit ses bibliothèques : « Tout · n bibliothèques · m » au repos ; une bibliothèque choisie prend le grand titre (œil « Bibliothèque · … », « Tout afficher ») ; la rangée ne la redit pas ; `libWho` ; « Créer » ne sort plus de l'écran |
| A596 | `lot-v5-98.md` | « Afficher » : les bibliothèques en liste (partage, compte, coche), repliées au-delà de 6 — un réglage, la feuille reste ouverte (amende A556) |
| A597 | `lot-v5-98.md` | Des dizaines de collections : l'accueil garde les 5 vues le plus récemment, en ordre alphabétique, puis « Toutes les collections · n » (amende A587) ; « Filtrer » au-delà de 12 rangées, sans focus au doigt ; pistes 3 mises de côté |
| A598 | `lot-v5-98.md` | « Garder en tête de l'accueil » (⋯ d'une collection) : signet plein, place gardée parmi les cinq ; champ `top` ; collection ou bibliothèque en tuile d'Accès direct écartée |
| A599 | `lot-v5-100.md` | La barre de sélection en matière système : « Collection… » et « Exporter… » directs, ⋯ pour le reste (Supprimer à une étape) ; au téléphone en bas à la place des onglets, « Annuler » et « Tout cocher » en haut ; « Actions ▾ » quand le compte ne tient pas (mesuré) — amende A476, A451 |
| A600 | `lot-v5-100.md` | Architecture CIBLE : l'accueil devient un LANCEUR (session, Accès direct, collections, récentes), un CATALOGUE porte bibliothèque › catégorie › éléments et « Tout » (filtrer, trier, sélectionner) ; par lots (catalogue ajouté, accueil allégé, nettoyage) — rouvre A545 (« Parcourir ») et A588, renoue avec T9 |
| A601 | `lot-v5-100.md` | Lot 1 d'A600 : onglet / rangée « Bibliothèques » → catalogue (racine « Tout » + bibliothèques, une bibliothèque et SES catégories, une catégorie sans redites, « Tout » filtrable et sélectionnable), état propre (`state.cnav`, `state.ctf`) ; le dock se glisse comme un sélecteur segmenté |
| A602 | `lot-v5-100.md` | Catalogue : le geste « retour » remonte d'un niveau (`ctgDepth`/`ctgUp`, A430) ; volets en large (bibliothèques · catégories ≥ 1200 · éléments ; catégories dépliées dans le volet 1 en deçà) |
| A603 | `lot-v5-100.md` | La pastille du dock est un objet qui GLISSE (courbe de `.seg-pill`), suit le doigt au glissé, prend la largeur de l'onglet ; seul `transform` est animé |
| A604 | `lot-v5-100.md` | L'établi se réajuste quand ce qui le précède change de hauteur (« Identité » dépliée : plancher 420, la page défile) — corrige A593 §4 |
| A605 | `lot-v5-100.md` | La pastille du dock se DÉCOUPE (`clip-path` animé) : glisse et s'élargit d'un seul mouvement ; les mots changent de couleur à son rythme (amende A603) |
| A606 | `lot-v5-100.md` | Lots 2-3 d'A600 : au-delà de 20 éléments l'accueil est un LANCEUR (récentes, porte « Toutes les aides et protocoles ») ; « Aides » → « Accueil » ; la colonne ne filtre plus (purge) ; portes de gestion au catalogue ; liens `#bibliotheques` → catalogue ; pied de page protégé |
| A607 | `lot-v5-104.md` | Le Markdown de Notion : `***gras italique***`, gras contenant un italique, `~~barré~~`, listes sur 6 niveaux par l'indentation, calque qui grise tout marqueur |
| A608 | `lot-v5-104.md` | Image « Pleine » = toute la colonne ; Plan en arbre (retrait par niveau) ; pastille de provenance alignée dans la rangée ; en sélection, ni voile gris d'iOS ni sélection de texte |
| A609 | `lot-v5-104.md` | Tableau : « Modifier en grille » sur un tableau ouvert ; en-têtes au choix (ligne vide = sans en-tête, 1ʳᵉ case en gras = colonne d'en-tête) ; `<br>` dans une case ; ↶ ↷ de la grille ; le voile ne ferme que si le geste y commence |
| A610 | `lot-v5-104.md` | Blocs : « ＋ » au-dessus/au-dessous du seul bloc survolé (amende A550), « Bloc avant » au doigt ; sélection multiple (Maj/⌘-clic, sélection glissée, « Sélectionner » au doigt) → Copier · Supprimer ; bloc vidé → choisir un type |
| A611 | `lot-v5-104.md` | Import : « Renommer » par rangée ; « Dans : … » verse une page dans une référence existante (remplit un contenu vide, s'ajoute à la suite sinon, images comprises) |
| A612 | `lot-v5-104.md` | « ⠿ Déplacer » dans la barre de sélection : les blocs sélectionnés (même non contigus) se déplacent ensemble par « Prendre / Poser », restent sélectionnés à l'arrivée (`mdBlkMoveSet`) |
| A613 | `lot-v5-107.md` | Le SUIVI : notes et tâches sur une aide ou une référence, « pour moi » ou « pour l'équipe » (écrites par tous les éditeurs) ; table `aid_followups` (une ligne par objet, RLS) ; bloc « Suivi » en lecture (notes seules et repliées en session) ; « À faire » par priorité / par élément, historique ; catalogue « Avec des tâches » ; collections converties à la demande |
| A614 | `lot-v5-107.md` | Le volet « Suivi » des deux éditeurs (colonne de droite au bureau, pied ailleurs), brouillon neuf compris ; « Ajouter une note personnelle » quitte aussi l'éditeur |
| A615 | `lot-v5-107.md` | La pastille « n tâches » dans la ligne d'état sous le titre (option B, discrète) ouvre le suivi en feuille ; jamais en session ni dans la barre du haut |
| A616 | `lot-v5-107.md` | La fenêtre d'une note / tâche passe au-dessus de la feuille « Suivi » et de « À faire » (ordre du document = ordre d'empilement) — elle ne se rouvrait plus |
| A617 | `lot-v5-107.md` | Une collection ouverte depuis l'accueil a son « ‹ Accueil » (chevron seul sous 360 px) et devient un niveau du retour système (`collUp`) |
| A618 | `lot-v5-107.md` | En large aussi, la barre de sélection flotte en bas de la colonne principale (`.sel-flot`, 62 px, 24 px du bas), case maîtresse et croix gardées (amende A599 §5) |
| A619 | `lot-v5-107.md` | Un appui long sur l'accueil au repos (lanceur, collection, ouvertes récemment) sélectionne sur place (`state.selRepos`) au lieu de basculer sur le répertoire |
| A620 | `lot-v5-107.md` | Une rangée sans catégorie garde l'emplacement vide du point quand ses voisines en ont un (amende A516) |
| A621 | `lot-v5-107.md` | Le « · » de la sous-ligne se colle à ce qui le précède (insécable devant, coupure derrière) : jamais en tête de ligne (amende A589 §2) |
| A622 | `lot-v5-107.md` | À l'import, le titre de la rangée est la commande « Renommer » (plus de bouton à part ; amende A611) |
| A623 | `lot-v5-107.md` | Les cases natives deviennent rondes (A515) ; « référence » ne désigne plus le type (A461, garde-fou `check-lexique` étendu) |
| A624 | `lot-v5-107.md` | L'élément lié d'une tâche se choisit dans la feuille de l'app ; la tâche paraît aussi chez l'élément visé (« Liées depuis d'autres éléments ») |
| A625 | `lot-v5-107.md` | Une échéance passée se dit (« △ en retard depuis le… », ambre) et remonte en tête de sa priorité — ni notification ni alerte |
| A626 | `lot-v5-107.md` | Tout choix d'une aide ou d'un protocole a son champ « Rechercher une aide, un protocole… », dès le premier élément |
| A627 | `lot-v5-107.md` | Catalogue : « à relire » sous le nom d'une catégorie (plus de chevauchement dans le volet) |
| A628 | `lot-v5-107.md` | Au bureau, « À faire » est une page de la colonne (onglet `todo`), pas une fenêtre |
| A629 | `lot-v5-107.md` | Un menu ancré est borné par le bas de ce qui l'écrête (fenêtre défilante) : tout ce qu'il montre se touche |
| A630 | `lot-v5-107.md` | Une tâche qui nomme son élément porte « Ouvrir › » vers lui |
| A631 | `lot-v5-107.md` | Au bureau, les menus de la barre de sélection se déroulent au-dessus d'elle ; « Ajouter » d'une collection sous son bouton |
| A632 | `lot-v5-107.md` | « Créer » aux Bibliothèques ; dans une bibliothèque du catalogue, l'élément y naît (`crtScope`) |
| A633 | `lot-v5-107.md` | Une page Notion (.md, .zip) se verse dans le protocole ouvert (dépôt ou « Ajouter › Page Notion ») |
| A634 | `lot-v5-107.md` | Blocs : glisser du texte = texte, glisser de la marge = cadre de blocs ; clic dehors désélectionne ; « Ajouter » s'efface pendant la sélection (amende A610) |
| A635 | `lot-v5-107.md` | « Modifier » s'ouvre sur le rôle en cache ; la revérification du rôle part en arrière-plan |
| A636 | `lot-v5-107.md` | Le suivi de l'éditeur de protocole survit à la frappe et à l'établi (pastille dans l'en-tête, bloc en bas) |
| A637 | `lot-v5-107.md` | La mise en garde « image hors texte » ne paraît que s'il y en a une |
| A638 | `lot-v5-107.md` | Au bureau, un choix dans une fenêtre est un déroulant flottant (`fixed`) : import, élément lié, ⋯ › collection, Administration (amende A167) |
| A639 | `lot-v5-107.md` | `****gras****` (Notion) se lit en gras ; un gras qui ouvre ou ferme un gras aussi |
| A640 | `lot-v5-107.md` | Après une image qui coupe une liste (import Notion), l'élément indenté suivant repart en liste |
| A641 | `lot-v5-107.md` | « Voir aussi », cible d'une complication, « Joindre un document existant » : des choix (déroulant au bureau, feuille au téléphone), avec recherche |
| A642 | `lot-v5-107.md` | Une image indentée sous un élément de liste lui appartient (import Notion) ; la liste continue ; « Sortir l'image de la liste » |
| A643 | `lot-v5-111.md` | Le POSTE PARTAGÉ se connecte par le téléphone : QR + nombre de contrôle, DEUX secrets (QR pour le téléphone, clé du poste), session propre au poste créée et liée par le serveur (fonction `link-claim`), ce qu'un poste ne peut jamais faire (`link_is_poste`), revue de sécurité, données sur le disque jusqu'à l'heure de fin, effacement jamais pendant une session ni avant le dépôt des sessions, verrou d'édition après réouverture, « Appareils connectés » (prolonger, déconnecter) ; table `device_links` |
| A644 | `lot-v5-111.md` | Des heures de FIN de garde, pas des durées : deux repères réglables (10:00, 19:30), choix entre 1 h et 28 h, « Prolonger d'1 h » ; pas d'heure libre |
| A645 | `lot-v5-111.md` | Sur un poste partagé, une session en cours se SAUVEGARDE en ligne toutes les 2 min (s'il y a eu un geste) : compte rendu partiel « △ Interrompue » remplacé par la session terminée (amende J209) |
| A646 | `lot-v5-111.md` | `_headers` : `camera=(self)` — le viseur du partage et de la connexion par le téléphone marche aussi sous Chrome |
| A647 | `lot-v5-111.md` | Ce qu'un poste partagé ne fait pas : supprimer = le téléphone à chaque fois, administration et « Remplacer » interdits, réglages pour ce poste seulement, reverrouillage après 15 min sans geste |
| A648 | `lot-v5-111.md` | Aucun compte ne porte de mot de passe (déclencheur `forbid_passwords` sur `auth.users`) ; jeton d'accès de 900 s sur l'instance (v5.111.1) |
| A649 | `lot-v5-111.md` | Trois défauts signalés : la notification (`.toast`) au-dessus de la barre d'onglets et à sa largeur ; les filtres de « Tout » ouvrent leur menu sous leur bouton au bureau ; le poste partagé se déclare terminé (`link_end`) et quitte « Appareils connectés » (v5.111.2) |
| A650 | `lot-v5-111.md` | `link-claim` sert plusieurs adresses de l'app : `APP_ORIGIN` en liste séparée par des virgules (le domaine ET le miroir GitHub Pages), l'origine listée est renvoyée ; écartés : `*`, origine reflétée, motif `*.github.io` |
| A651 | `lot-v5-112.md` | Connexion temporaire PAR E-MAIL : Temporaire › Par e-mail, heure de fin, `link_self` (la session fraîche se déclare poste ; refusée, elle ne reste pas ouverte) |
| A652 | `lot-v5-112.md` | La carte « Se connecter » : Temporaire · Permanente, rien d'office ; le code à viser DANS la page (5 renouvellements) ; « un appareil connecté », jamais « le téléphone » ; carte du poste à une sortie ; bande neutre (amende A643) |
| A653 | `lot-v5-112.md` | Le compte se charge : « Chargement de votre compte… » et trois rangées qui respirent pendant le premier tirage, au lieu de « vide » ; 20 s au plus ; mouvement réduit respecté |
| A654 | `lot-v5-113.md` | Les règles de la connexion temporaire, réglées dans Administration › Règles pour toute l'application (créer/modifier, supprimer, remplacer, exporter, durée max) ; le serveur applique interdits et durée (RLS restrictives, `temp_rules`), le client confirmations et verrou ; Administration et suppression du compte toujours interdites (amende A647) |
| A655 | `lot-v5-114.md` | Déconnecté depuis un autre appareil : l'appareil s'arrête aussitôt (veille 15 s, état retenu, plus d'édition ni de nouvelle session, session en cours préservée) et le serveur lui ferme les tables dès la requête suivante (`link_dead`, politiques `*_link_dead`) — le jeton restait valable 15 min |
| A656 | `lot-v5-114.md` | « Connecter un appareil » : Moi › Connexions temporaires sur place (icône par type, ambre à < 1 h), viseur titré avec « Le code n'est pas affiché ? », confirmation une étape à la fois sans bouton grisé, « Connecté » en vert, feuille « gérer » (＋ 1 h, jusqu'à la prochaine fin de garde) (amende A652) |
| A657 | `lot-v5-114.md` | Le filet d'un parcours d'historique ne veille que le sien (`_hGen`) : le filet d'une fermeture échu pendant la suivante relançait un recul, l'aide se refermait (deux témoins d'audit rouges sous charge) (amende A563) |
| A658 | `lot-v5-114.md` | Déconnecté pendant une synchro : `Sync.full` s'arrête entre deux étapes (`fin()`), la réconciliation revérifie après sa lecture — les tables fermées répondent du vide, elle effaçait les aides de bibliothèque (complète A655) |
| A659 | `lot-v5-115.md` | Corrections de l'audit complet, session et partage : rappel d'étape critique enfin affiché, « x/y étapes » repeint au cochage, ancre des minuteurs en heure serveur, pli qui lève la trace de vérification, « Continuer seul »/« Arrêter » sans attente réseau, permission de notification dans Moi › Alarmes, notifications par le service worker, écran tenu allumé tant qu'un minuteur vif tourne |
| A660 | `lot-v5-115.md` | Éditeur, import, accueil : bloc supprimé retiré du pool, nom court publié, fichier d'IA sans état en Brouillon (amende A129), clés oubliées à l'effacement, relecture d'aide étendue, plafonds dits |
| A661 | `lot-v5-115.md` | Compte, stockage, synchro : garde de nuit toujours proposée, effacement gardé, versions des protocoles, aucun re-rendu de synchro en soin, stockage de secours annoncé, œ/æ repliés (amende l'invariant 1:1 de `txNorm` : `txNormMap`/`txNorm1`), liens `tel:`/`mailto:` |
| A662 | `lot-v5-115.md` | Feuille de style et coque : encres de session lisibles, « Continuer » bleu au survol, alarme au-dessus des couches plein écran, impression depuis le sombre, message si l'app ne démarre pas, lien d'évitement sans hash |
| A663 | `lot-v5-115.md` | Serveur (à rejouer) : suppression de compte complète (`purge_user_data`), partage non inscriptible en direct, gardes du poste partagé, au moins un administrateur par bibliothèque, `leave_library`, `link-claim` exige `APP_ORIGIN` (amende A650) |
| A664 | `lot-v5-115-1.md` | Audit de sécurité : un id sûr n'est jamais un nom hérité d'`Object.prototype` (`badKey`), tables de session sans prototype, chemin vivant du partage nettoyé comme le pli, ligne tirée à id mal formé ignorée |
| A665 | `lot-v5-115-1.md` | Partage sans serveur : un canal = un participant (`slServe`), un coupé ne revient pas, bornes du hub |
| A666 | `lot-v5-115-1.md` | La signalisation (`sig`) n'obéit qu'à l'hôte ; une offre de canal par participant |
| A667 | `lot-v5-115-1.md` | Rien de la charge d'appariement n'entre brut dans le SDP (`slSdpRebuild`) |
| A668 | `lot-v5-115-1.md` | Le pool d'items et les items d'un bloc sont bornés dans `migrate` |
| A669 | `lot-v5-115-1.md` | Import : un document venu d'ailleurs entre sous un id neuf ; un fichier n'apporte jamais une suppression |
| A670 | `lot-v5-115-1.md` | Entrées de fichier : expressions régulières bornées, budget partagé des archives imbriquées |
| A671 | `lot-v5-115-1.md` | « Se déconnecter et effacer » retire le cache de profil et dix clés oubliées |
| A672 | `lot-v5-115-1.md` | Une connexion temporaire par e-mail interrompue ne reste pas ouverte (`ac-temp-pending`) |
| A673 | `lot-v5-115-1.md` | Une note d'équipe ne s'affiche que sur un élément de sa bibliothèque |
| A674 | `lot-v5-115-1.md` | Garde anti-iframe aux gestes réels ; en-têtes de sécurité du document en cache |
| A675 | `lot-v5-115-1.md` | Outillage : serveurs de test en boucle locale, sans `..` ; jeton de CI en lecture |
| A676 | `lot-v5-115-2.md` | Serveur (à rejouer) : aucune session de poste partagé ne survit à sa ligne (`link_end`, `link_purge`) |
| A677 | `lot-v5-115-2.md` | `updated_at` n'est plus antidatable (`clamp_updated_at`) |
| A678 | `lot-v5-115-2.md` | `link_open` : adresse lue dans l'en-tête de la passerelle, plafond global par nature |
| A679 | `lot-v5-115-2.md` | Listes d'administration fermées au poste (`admin_reads`), aides internes révoquées, `share_admit` et compte validé |
| A680 | `lot-v5-115-2.md` | `share_push` : la valeur a le type de sa clé (`share_val_ok`), quota non consommé par un refus, heure cliente bornée |
| A681 | `lot-v5-115-2.md` | L'auteur d'une note d'équipe est posé par le serveur (`followups_stamp_author`) |
| A682 | `lot-v5-115-2.md` | Forme des identifiants d'aide et de protocole, nom de bibliothèque borné (contraintes `not valid`) |
| A683 | `lot-v5-115-2.md` | `?__actest` réservé au cadre de test et à la machine locale ; empreintes SHA-256 des actifs vendorisés (`check-vendor`) |
| A684 | `lot-v5-115-2.md` | Régression de la v5.115.1 corrigée : le canal direct en service n'est plus fermé par le minuteur des offres (`__acOpen`) ; plafond d'offres en nombre |
| A685 | `lot-v5-116.md` | Serveur (à rejouer) : une invitation n'est pas une adhésion — `memberships.pending`, `my_invitations`, `answer_invitation`, `is_member`/`member_role` ignorent l'attente, réponse unique de `invite_member` |
| A686 | `lot-v5-116.md` | Moi › Bibliothèques : mes invitations, Refuser · Rejoindre ; « invitation en attente » dans la fenêtre des membres |
| A687 | `lot-v5-116.md` | Serveur (à rejouer) : quotas par espace (aides, protocoles, sessions, documents) — `app_settings.quotas`, `quota_check`, `get_quotas`/`set_quotas`, `quota_usage` |
| A688 | `lot-v5-116.md` | Administration › Règles › Quotas, avec leur guide ; « Quota atteint » à la synchro ; `docs/deploiement-et-conformite.md` § 1.8 |
| A689 | `lot-v5-116-1.md` | Un document PDF appartient à un seul espace : exemplaire neuf à la duplication, la synchro ne téléverse plus à cause d'une ligne tirée (`attClaim`, `attPlan`, `attMayDelete`) |
| A690 | `lot-v5-116-1.md` | Réparation de l'existant, une fois par espace (`attRepairShared`, `ac-att-split`) |
| A691 | `lot-v5-116-1.md` | `link-claim` (à redéployer) : rend `{id, email}` seulement, cinq réclamations par lien |
| A692 | `lot-v5-116-1.md` | Appareil temporaire : la règle « créer, modifier » couvre catégories partagées, notes et suivi ; une suppression ne modifie pas |
| A693 | `lot-v5-116-1.md` | La confirmation d'un appareil temporaire est appliquée par le serveur (fenêtre d'écriture, `link_touch`, `poste_locked`) ; le verrou de réouverture reste côté app |
| A695 | `lot-v5-116-1.md` | `migrate` : champs inconnus bornés sans liste blanche (`borneInconnus`), bloc de décision assaini, pool dédoublonné |
| A696 | `lot-v5-116-1.md` | Actions de la CI épinglées par empreinte de commit |
| A697 | `lot-v5-116-1.md` | Indexation des PDF : 5 000 pages et deux millions de mots, essais interrompus retenus, jamais pendant un soin (amende « indexation intégrale ») |
| A698 | `lot-v5-117.md` | Délai de revérification réglable par élément (`reviewEvery` : 12 · 24 · 36 mois, `reviewDue`) ; section calculée « À revérifier » dans « À faire » (amende le seuil fixe de 2 ans) |
| A699 | `lot-v5-117.md` | Volet des minuteurs et compteurs du téléphone en tuiles : « ↺ maintenir » à côté du temps, la tuile à l'arrêt lance, « − n + » sur une rangée |
| A700 | `lot-v5-118.md` | Frise du compte-rendu : un couloir par compteur, Repères, Complications (`sessFrise`, SVG en ligne) ; ni blocs ni minuteurs, que le modèle ne date pas |
| A701 | `lot-v5-119.md` | Volet du téléphone au dessin de la maquette : tuiles pleines, maintenir la tuile pour réarmer ou remettre à zéro (amende A460 pour ce volet, remplace la mise en page d'A699), `dockFold` |
| A702 | `lot-v5-119.md` | « △ À revérifier » : le glyphe revient sur la rangée d'accueil (amende A347 ; règle 8) |
| A703 | `lot-v5-119-2.md` | La fenêtre d'une bibliothèque (`#membersModal`) déclarée après `#admModal` : elle s'ouvrait derrière Administration au téléphone (ordre du document = empilement, A616) |
| A704 | `lot-v5-119-3.md` | Règles de la connexion temporaire au sélecteur segmenté de l'app (`.seg`, pastille qui glisse au tap et au doigt) ; le tap peint sur place (`admTrPaint`, `#admTrAsk`), `.adm-topt` purgé |
| A706 | `lot-v5-119-4.md` | Partage : celui qui poursuit seul coche ; `rehost` et rejeu sans régression (`SHARE_REPLAY_OWN`, `_floor`) ; lien mort sans resynchronisation ; minuteurs du pli en marche ; `cxb` en liste blanche (serveur à rejouer) ; hub direct (détaché, coupé, silence) ; « parti » |
| A707 | `lot-v5-119-4.md` | Sessions : une vive par aide ; orpheline rangée ; texte archivé des étapes (`stepArch`) ; `aidRev` ; `persistLive` auto ; essai qui sonne ; minuteur sans durée ; « Versions » depuis l'éditeur ; `*` et `==` collés au texte |
| A708 | `lot-v5-119-4.md` | Accueil et catalogue : filtre de type non hérité, recherche du téléphone, `syncHomeTabs` à la rotation, `ctgDepth`, `_homeN`, plafond de l'Accès direct |
| A709 | `lot-v5-119-4.md` | Éditeurs et import : `mdBlkDel`, brouillon sans titre gardé et reprise des deux types, `edKeepCx`, doublons du même espace, entrées non-objets, nom de catégorie vide |
| A710 | `lot-v5-119-4.md` | Compte et synchro : `_reconcileTable` paginée, `_adoptDisk` (deux onglets), 401 rattrapé, bibliothèque créée depuis une aide ouverte, invitation retirée, adhésions en échec |
| A711 | `lot-v5-119-4.md` | Mode crise : `ckNoLink` (« Constaté ✓ » puis décocher), `syncBlkReturn` sous feuille plein écran, `monClose` sans défilement, Échap de `inlineRename`, `renderTkOnly` et champ d'heure |
| A712 | `lot-v5-119-4.md` | Affichage : toast sous zoom, champs à 16 px, `.cm-top` sous zw360, `.cx-tgt` empilé, « · » des tuiles épinglées, `.pp-tiles`, titre borné en session au bureau |
| A713 | `lot-v5-119-4.md` | Arbitrages de l'auteur : « Créer » reste aux Bibliothèques (`crtScope` retombe sur Perso, précise A632) ; cibles tactiles à 32 px hors session (`.tg-sw`, `.hs-lnk`, `summary`, `.pg-tb`), seuil d'`audit-a11y` relevé de 24 à 32, lien étiré mesuré sur sa rangée |
| A714 | `lot-v5-119-4.md` | L'hôte écrit toujours, même après avoir donné la main (`canWrite`, `share_push` : `is_owner`) — amende A302 § 4 ; serveur à rejouer |
| A715 | `lot-v5-119-4.md` | Barre d'onglets du téléphone : `tbFit` mesure, `tb-compact` ne laisse son mot qu'à l'onglet courant quand les quatre ne tiennent plus (130 % sur écran étroit) ; `aria-label` sur chaque onglet |
| A716 | `lot-v5-119-5.md` | « Horodater · n » peint par `paintTkKey` (aussi depuis `renderTkOnly`) ; nom de minuteur ou de compteur : rendu de l'éditeur au `change`, focus reposé (`edRedoKeepFocus`) |
| A717 | `lot-v5-119-5.md` | Barre d'onglets : pastille et mots remesurés à chaque changement de largeur (`ResizeObserver`, sans glissement : `tb-still`) ; `collSideHtml` sans filet de fin (amende rien : applique A366 § 1) |
| A718 | `lot-v5-119-5.md` | Une bibliothèque ne reste jamais sans membre : `memberships_keep_admin` et `leave_library` refusent le dernier membre accepté (`last_member`, serveur à rejouer) ; fenêtre de la bibliothèque et Administration le disent |
| A719 | `lot-v5-119-5.md` | « ⚙ Gérer la bibliothèque » dans la rangée des filtres de « Tout » quand le filtre Bibliothèque vise une bibliothèque partagée (`openMembers`, administrateurs seulement) |
| A720 | `lot-v5-119-5.md` | L'administrateur d'une bibliothèque la supprime (`lib_delete` : `member_role(id) = 'admin'`, serveur à rejouer) ; la suppression se vérifie (`return=representation`) |
| A721 | `lot-v5-119-5.md` | Moi : la rangée d'une bibliothèque non administrée mène à « Quitter » (`libLeaveAsk`, refus dits) — amende A364 |
| A722 | `lot-v5-119-5.md` | Blocs sélectionnés de l'éditeur de protocole : cadre en `::after`, une suite contiguë en un seul cadre (`sel-t`/`sel-b`, `--selgap`) ; pas de contour de survol sur un bloc pris (précise A610) |
| A723 | `lot-v5-120.md` | Titres du texte rédigé à trois crans (`.md-h1` 21 + filet 2 px, `.md-h2` 17,5, `.md-h3` 15), en lecture, dans `.md-doc` et `.md-preview` ; corps de l'éditeur à 15 ; amende la ligne « Protocole » du lot v5.30 |
| A724 | `lot-v5-120.md` | Éditeur de protocole au bureau : « Ajouter un bloc » en pied ouvre un déroulant flottant (`addMenu` → `deskFlot`) — la page ne saute plus vers un menu mal ancré |
| A725 | `lot-v5-121.md` | Aux Bibliothèques, créer ou importer pré-remplit bibliothèque ET catégorie (`crtScope`, `crtCat`, `crtToutOn` ; `impLibDefaut`/`impRowsOf`) ; dans « Tout », les filtres valent contexte ; étend A632 |
| A726 | `lot-v5-122.md` | Le corps d'un encadré se rend en paragraphes et listes dès qu'il porte un élément de liste (`qBody`, `qLi`, `MD_QLI_RX`) ; sinon rendu en ligne inchangé ; tâche non cochable dans un encadré |
| A727 | `lot-v5-122.md` | En lecture, une image seule est plafonnée aux deux tiers de la fenêtre par sa largeur (`mdFigAr`, classes `fh1..6`) ; éditeur inchangé ; amende A608 en lecture |
| A728 | `lot-v5-123.md` | Le sommaire d'un protocole dit où l'on est : carte collante du téléphone (`#` puis `##`), lien courant marqué (`aria-current`, grammaire A418), `refTocSpy` ; lit le défilement sans le provoquer |
| A729 | `lot-v5-123-1.md` | Coller le Markdown d'un autre protocole emporte ses images : une ligne `![…](img:ID)` orpheline reprend l'image d'un autre protocole de l'appareil, même identifiant (`pImgAdopt`), à l'ouverture de l'éditeur et à la saisie ; carte « Images du texte » repeinte sur place (`miCardRefresh`) ; jamais en lecture |
| (transverse) | `conventions-de-code.md` | La doctrine PAR COMPOSANT — registres, chrome, accueil, partage, stockage… (498 Ko : chercher par intitulé, cf. la carte d'`AGENTS.md`) |
| (transverse) | `garde-fous-et-audits.md` | L'histoire et la raison de chaque garde-fou `check-*` et de chaque piège de harnais — l'ancienne section « Avant chaque commit » d'`AGENTS.md`, reprise à l'octet à l'audit des instructions (31/10/2026) ; `AGENTS.md` garde la procédure |
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
| `deploiement-et-conformite.md` | Kit de déploiement en établissement, statut réglementaire (non-dispositif-médical, § 2), registre RGPD **opposable** (§ 3-3.2), comparatif des hébergeurs (§ 1.1) |
| `conversion-v3-vers-v4.md` | Chemin de reprise d'un export v3 (hors application — cf. règle 12 d'`AGENTS.md`) |
| `changelog/v3.md`, `v4.md`, `v5.md` | Archives du CHANGELOG, une par version majeure ; les entrées s'y AJOUTENT EN FIN, telles quelles, quand `CHANGELOG.md` dépasse 20 (garde-fou : `scripts/check-changelog.mjs`) |
| `audit-apprentissage-2026-10.md` | Audit de la courbe d'apprentissage (v5.44.0) : vocabulaire, premiers pas, recherche, texte à 130 %, plan d'action — d'où les lots v5.45 à v5.48 (A460-A472) |
