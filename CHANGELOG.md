# Journal des modifications

## [4.2.2] — 2026-07-13
Étapes : doctrine rouge/ambre affichée, gras retiré, chiffres plus lisibles ; références sur
les protocoles ; prompt IA actualisé.

### Corrigé
- **Étape vigilance (ambre) invisible dans l'« Aperçu en direct »** de l'éditeur : la colonne
  d'aperçu ne traitait que les étapes critiques (rouges) — une étape `△` s'y affichait comme
  une étape normale. Elle apparaît désormais au registre ATTENTION (fond et texte ambre),
  comme en lecture.

### Ajouté
- **Consigne d'usage rouge/ambre dans l'éditeur de blocs** (affichée au-dessus des étapes, là
  où se prend la décision) : **rouge** = ce qui tue si on l'oublie (memory item, geste vital) ;
  **ambre** = là où l'on risque de se tromper (dose/dilution à vérifier avant injection,
  contre-indication à écarter, confusion voie/site/produit, seuil à contrôler avant de
  poursuivre) ; une étape des deux registres → rouge. Les infobulles du bouton ⚠/△ reprennent
  la doctrine, ainsi que le prompt IA et AGENTS.md.
- **Références sur les protocoles** : même section « Références » que les aides cognitives —
  liste dans l'éditeur (sous le contenu rédigé), affichée en bas de la lecture, indexée par la
  recherche. Champ facultatif, export v3 inchangé (un ancien client l'ignore).

### Modifié
- **Gras retiré des étapes** (bouton « B » et raccourci Ctrl/Cmd-B) : le texte des étapes est
  déjà affiché en gras — un **fragment** y était invisible ; le relief d'une étape passe par
  son TYPE (rouge/ambre). Le gras reste disponible dans les listes (À vérifier, Ne pas
  oublier, Repères posologiques…) ; l'ancien contenu contenant `**` reste rendu (compat).
- **Chiffres des étapes** (mode crise) : 14 → 16 px et **centrés verticalement** sur l'axe de
  la case à cocher — le numéro est l'ancre de suivi de position de la lecture à voix haute
  (challenge-response, logique QRH) ; il reste en encre douce pour ne pas concurrencer le
  texte, et suit les registres rouge/ambre/coché.
- **Prompt IA actualisé** : le gras y est désormais exclu des étapes (réservé aux listes) ;
  la doctrine rouge/ambre ci-dessus remplace l'ancienne définition du `△` ; nouvelle règle —
  **ne jamais générer de chronomètre « Temps écoulé »** (l'app affiche déjà un chrono global
  de session qui démarre à la première action), un `stopwatch` ne servant qu'à une durée
  spécifique explicitement demandée par la source (garrot, no-flow…) ; l'exemple du schéma
  est corrigé en conséquence. Déjà à jour et vérifiés : `code`, types d'étapes ⚠/△, repères
  posologiques.

## [4.2.1] — 2026-07-13
### Corrigé
- **App tronquée à droite sur certains navigateurs** : sur les navigateurs à barres de
  défilement classiques (Windows/Linux — pas macOS/iOS, d'où le « certains »),
  `scrollbar-gutter: stable` posé sur `html` réservait ~15 px à droite **en permanence**, même
  quand rien ne défile (accueil = coque fixe, fiche courte) : l'en-tête, le bandeau MODE CRISE
  et tout le contenu s'arrêtaient avant le bord de la fenêtre — alors que les éléments fixes
  (tab bar, notifications) allaient, eux, jusqu'au bord. La réservation est retirée de `html` ;
  l'anti-décalage qu'elle assurait (bascule Aides ↔ Protocoles) est déplacé **dans les panneaux
  défilants de l'accueil large** (`.home-side`/`.home-main`), seul endroit où il agit encore
  depuis la coque fixe V5. Vérifié : l'app atteint désormais exactement le bord droit à toutes
  les largeurs, sans débordement horizontal.

## [4.2.0] — 2026-07-13
Liens croisés « Voir aussi », alarmes de minuteur au standard aviation (QRH/ECAM), thème
accessible en mode crise.

### Ajouté
- **Liens croisés « Voir aussi »** : une aide cognitive OU un protocole peut désormais être lié
  aux deux (et plus seulement des fiches). Le choix se fait dans un **sélecteur filtrable au
  même design que « Joindre un document existant »** (icône par nature — feuille = aide,
  livre = protocole —, nature en 2ᵉ ligne, code en colonne droite), commun aux deux éditeurs ;
  il remplace l'ancien menu déroulant. En lecture, la section s'appelle « Voir aussi » partout
  (fiches ET protocoles), chaque raccourci porte l'icône de sa nature et ouvre la bonne vue.
  Compatibilité : `related` reste un tableau d'ids (export v3 inchangé) — un ancien client
  ignore simplement les ids de protocole qu'il ne résout pas. Même périmètre uniquement
  (Perso ou même bibliothèque), comme les documents partagés.

### Modifié
- **Alarme de minuteur en mode crise — règle QRH/ECAM** : un minuteur qui arrive à échéance ne
  **déplace plus jamais le contexte de travail** quand la session est sous les yeux — plus
  d'ouverture automatique du panneau minuteurs (qui décalait la checklist en cours de lecture),
  plus de banderole jaune par-dessus l'écran de travail. À la place : bip/vibration + flash
  bref (l'attention, façon *master caution*), puis un **segment ambre persistant** dans la
  barre de minuteurs de l'en-tête — le minuteur échu y reste affiché « 00:00 » tant qu'il n'est
  ni relancé ni réarmé (l'acquittement passe par l'action, pas par un « OK » de plus). La
  banderole cliquable, le flash écran et la notification système sont **réservés à la session
  hors de vue** (autre vue, autre fiche, app en arrière-plan) : là, l'alerte doit être routée.
- **Bouton thème en mode crise (mobile)** : il reste visible pendant une session (retour sur la
  v4.1.2 — décision : la luminosité ambiante change pendant une intervention, extérieur/
  intérieur) ; seule la pastille de compte s'efface. Les intitulés de minuteurs s'ellipsent un
  peu plus tôt (< 430 px) pour que barre + thème + menu ⋯ tiennent ensemble sur 375 px.

## [4.1.2] — 2026-07-13
Correctifs d'affichage et retouches de design, surtout sur mobile.

### Corrigé
- **Fenêtre « Modifier la bibliothèque »** : Annuler / Enregistrer remontent **sous le champ
  Nom** (ils ne portent que sur lui) au lieu de suivre la liste des membres — placés en bas,
  ils laissaient croire qu'un ajout ou un retrait de membre devait être « enregistré », alors
  que ces changements s'appliquent immédiatement (précisé aussi dans la légende des rôles).
  Les messages du renommage s'affichent désormais sous le champ Nom, ceux des membres restent
  sous la rangée d'invitation.
- **Minuteurs de l'en-tête sur mobile** : un intitulé de minuteur long poussait le temps hors
  du cadre (coupé net) sur les écrans < 430 px — l'intitulé s'ellipse à nouveau (« ● Session »
  reste toujours entier) et les segments se resserrent. En complément, pendant une session de
  crise sur écran étroit, les boutons **thème** et **compte** s'effacent de la barre (inutiles
  en pleine prise en charge, accessibles partout ailleurs) : toute la place revient aux
  minuteurs. Le menu ⋯ reste.
- **Badge d'état fantôme dans l'en-tête** : après « Enregistrer » dans l'éditeur, le badge
  « ✓ Validée · auto-enregistré » survivait au retour en lecture de la fiche — redondant avec
  la pastille de statut du haut de page et envahissant sur mobile. L'en-tête masque désormais
  son badge à chaque rendu ; seules les vues qui en déclarent un (éditeurs, lecture de
  protocole, aperçus) le réaffichent.

### Modifié
- **Tab bar basse de l'accueil (mobile)** : hauteur réduite (~72 → ~55 px hors encoche) —
  boutons 44 px (cible tactile minimale conservée), paddings resserrés.
- **« Supprimer mon compte et mes données »** (et « Supprimer cette demande de compte ») :
  même grammaire destructrice que « Supprimer la bibliothèque… » — zone sensible avec bouton
  **contour rouge**, à la place de l'ancien lien discret (`.auth-danger` retiré).
- **Bouton thème de l'en-tête** : rond (40 px) en format compact sans libellé, comme le bouton
  Créer — il était ovale ; la forme pilule revient avec le libellé (≥ 780 px).
- **Dialogue « Créer » (aide ET protocole)** : icônes des cartes remplacées par des **icônes
  SVG uniformes 26 px** (crayon, étincelles, import, reprise de brouillon) — les anciens
  glyphes texte ✎ ✦ ⤓ ↺ rendaient à des tailles inégales selon la police du système.
- **Fenêtre « Où sont mes fiches ? »** mise à jour des évolutions V5 : le conseil d'export
  pointe vers « Compte → Exporter mes données » (l'ancien bouton « Exporter tout » du pied de
  page n'existe plus) et mentionne le chemin d'import (dialogue Créer). Mêmes corrections dans
  la fenêtre de bienvenue et deux messages d'erreur qui citaient encore « Exporter tout ».
- Lanceur de tests : variable `AC_CHROMIUM` pour pointer un Chromium déjà installé
  (environnements distants/CI sans téléchargement Playwright).

## [4.1.1] — 2026-07-12
Correctifs et nettoyage issus d'un audit complet (code mort, duplication, sécurité, PWA/perf).
Aucun changement de comportement visible : mêmes écrans, mêmes données.

### Corrigé
- **Droits perdus en cours d'utilisation** (rétrogradé lecteur ou retiré d'une bibliothèque
  pendant que l'app est ouverte) : une modification locale non poussée d'une bibliothèque où
  l'on ne peut plus écrire divergeait en silence pour toujours (jamais poussée, jamais
  réconciliée, pastille verte). Désormais : la modification est **copiée dans « Perso »**
  (rien ne se perd), la copie partagée **revient à la version de l'équipe** (ou disparaît si
  l'on n'est plus membre), et l'utilisateur est **prévenu**. Une suppression bloquée est
  annulée (version de l'équipe restaurée). En complément, l'ouverture de l'éditeur d'une
  fiche/protocole **partagé** revérifie le rôle auprès du serveur quand on est en ligne.
  Rappel : il n'y a pas de synchro périodique — droits et contenus se rafraîchissent au
  démarrage, après chaque écriture locale, au retour au premier plan et au retour en ligne.
- **Fuite d'écouteurs de l'aperçu d'édition** : un écouteur `input` s'empilait sur `#main` à
  chaque ouverture d'éditeur — un seul est désormais posé (les frappes ne déclenchaient plus,
  après plusieurs éditions, qu'un seul aperçu au lieu de N).
- **Service worker** : le handler de navigation ne met plus en cache que la page de l'app —
  visiter `tests.html` ou une fiche de `design/` ne peut plus remplacer la copie hors-ligne.
- **Défense en profondeur du mini-Markdown** : liens et images nettoyés au point d'insertion
  (`href`, `safeImg`) — la sûreté ne dépend plus d'un invariant d'ordre.

### Ajouté
- **Réservation d'espace des images** (anti-décalage de mise en page) : chaque image mémorise ses
  dimensions ; `width`/`height` émis en lecture réservent le bon ratio avant décodage, sans
  jamais déformer un schéma. Import ancien sans dimensions : inchangé.
- **Manifest** : `orientation` portrait, `categories`, `dir` — fiche d'installation plus complète.

### Modifié
- **Recherche transverse à toutes les bibliothèques** : dès qu'on tape une recherche, elle porte
  sur la bibliothèque perso ET toutes les bibliothèques partagées accessibles (plus seulement
  celle affichée) ; chaque résultat porte une pastille indiquant sa bibliothèque (si l'on a des
  bibliothèques partagées). Les brouillons restent masqués là où l'on n'a pas le droit d'éditer.
  Sans recherche, la navigation par bibliothèque/catégorie est inchangée.
- **Correctifs mobile** : la loupe de la recherche ne chevauche plus le placeholder ; le crayon ✎
  d'édition de bibliothèque ne déborde plus de la chip et réagit au tap.
- **Facteur commun fiche/protocole** : sanitisation des entités (`sanitizeEntityCommon`), en-tête
  et sortie des éditeurs mutualisés — une évolution ne peut plus diverger d'un seul côté.
- `render()` allégé (chrome d'en-tête extrait dans `applyViewChrome`) ; `renderLibrary` renommée
  `renderFiches` (elle rend les fiches, pas les bibliothèques).

### Supprimé
- Code mort : `timeAgo()`, variable `_rtShow`, 17 règles CSS orphelines (vestiges des
  remplacements V5). Chaîne de build `dist/` retirée (dossier, `build-dist.mjs`, `terser`) : le
  dépôt est la seule forme servie.

### Sécurité
- **CSP durcie** : `release.sh` calcule les hashs SHA-256 des scripts inline
  (`scripts/csp-hashes.mjs`) et les injecte dans la CSP (`<meta>` + `_headers`). Sur navigateur
  récent (CSP 2+), `'unsafe-inline'` est ignoré et seuls ces scripts s'exécutent : un `<script>`
  ou un handler `on*=` injecté est bloqué (repli `'unsafe-inline'` conservé pour les très vieux
  navigateurs). `style-src 'unsafe-inline'` demeure (attributs `style=` non hachables). Risque
  résiduel restant documenté (`docs/deploiement-et-conformite.md` § 1.1 : jetons Supabase en
  `localStorage`, discipline `esc()`).

### Documentation
- `CHANGELOG.md` allégé : les versions 3.x déplacées dans `CHANGELOG-archive.md` (rien de
  fusionné ni perdu — le journal courant ne garde que le 4.x). Références mortes purgées
  (`dist/`, `renderLibrary`) dans AGENTS.md, README, kit de déploiement et `design/`.

## [4.1.0] — 2026-07-12
Version consolidée : intégration complète du design Claude Design « V5 Explorations » et des
spécifications écrites qui l'ont suivi (largeurs, écrans de gestion, mode crise, dialogue
bibliothèque), plus l'audit UX/ECAM/WCAG appliqué. Remplace les versions locales 4.0.4 → 4.4.1,
jamais publiées, écrasées en une seule entrée.

### Ajouté
- **Écrans de gestion** : dialogue « Créer » (3 méthodes — rédiger, avec l'IA, importer un
  fichier ; tout import par ce dialogue arrive en Brouillon ; carte « Reprendre le brouillon ») ;
  **menu ⋯** en lecture (Modifier, Versions, Dupliquer, Exports, Historique des sessions en
  modale, « Terminer la session… » — remplace les barres d'autorat et le bandeau session) ;
  **auto-enregistrement des brouillons** (store meta `draftpark`, fantôme restaurable,
  « ‹ Retour » remplace « Annuler ») ; dialogue bibliothèque unifié (membres + zone sensible).
- **Mode crise V5** : bandeau TITRE au registre ALERTE (« ■ MODE CRISE »), minuteurs segmentés
  dans la barre à toutes les largeurs + chrono GLOBAL « ● Session », rail droit ≥ 1000 px,
  cartes minuteur refondues (état TEXTUEL, barre 4 px du temps restant, échu = ambre,
  « ↺ durée »), **minuteurs ad hoc** (`extraTimers`), compteur lié (`counters[].timerId`),
  bouton Continuer à 2 états (destination annoncée, champ `nextLbl`), confirmation diagnostique
  = condition d'entrée visible hors session, colonne de contenu au canvas (SPEC-crise).
- **Statuts 3 états** (validé / à relire / brouillon, pilule achromatique unique), champ `code`
  court indexé, étapes critiques « ⚠ » et vigilance « △ », section « Repères posologiques »,
  aperçu d'édition en direct (colonne ≥ 1000 px).
- **Couleur d'accent par utilisateur** (5 nuances AA + bleu clinique, connecté seulement :
  accueil entier + en-têtes ; le contenu clinique reste bleu) ; préférences par utilisateur
  (thème + taille du texte + accent) synchronisées via `data.prefs`.
- Fenêtre Compte restructurée (gabarit dlg-480, « synchronisé à HH:MM », zones Cet appareil /
  Administration / Zone sensible, avatar en initiales de l'e-mail).

### Modifié
- **Palette V5 « bleu clinique »** et tokens (trois rouges distincts, `--ok` confirmation,
  `--soft` décoratif seulement, `--done-*`/`--tag-*`/`--link`/`--verify-bd`) ; taxonomie des
  notices à 5 registres ; nouveau logo (bouclier + tracé ECG) ; icônes SVG harmonisées.
- **Largeurs fermées par vue** (breakpoints 430→1200) : accueil = sidebar 255 px sur coque FIXE
  + grille ≤ 1320 px ; fiche ≤ 860 px + rail 320→360 px ; protocole ≤ 780 px ; éditeurs alignés
  sur leur lecture + aperçu sticky 360 px. Pied de page nomade en bas de la sidebar de
  l'accueil ; export via la fenêtre Compte, import via le dialogue Créer.
- **Audit ECAM/WCAG appliqué** : contrastes (texte secondaire `--ink-soft`, champs/cases
  `--line-strong`), plancher typographique 11 px, garde 700 ms anti double-tap sur les retours
  empilés, halos tactiles 44 px, cartes d'accueil sobres (pilule de catégorie neutre, couleur
  au liseré seul), impression qui déplie les sections repliées.
- Docs consolidées : la spécification des largeurs vit dans AGENTS.md (le fichier
  `docs/SPEC-largeurs.md` est supprimé) ; export Design System (`design/`) régénéré.

### Supprimé
- **Chaîne de build `dist/`** (dossier, `scripts/build-dist.mjs`, dépendance `terser`, étape 6
  de `release.sh`) : le dépôt est la seule forme servie — l'entre-deux « build optionnel
  jamais déployé » était le pire des deux mondes.


## [4.0.3] — 2026-07-11
Lot de cohérence issu de l'audit design v4 (registres visuels, saillance, accessibilité).

### Modifié
- **Les protocoles parlent la même langue visuelle que les fiches.** Les titres de section du
  contenu rédigé (`#`, `##`) reprennent le registre des en-têtes de section des fiches (petites
  capitales grasses espacées) au lieu d'un simple gras : une seule grammaire de titres dans
  toute l'app, en lecture comme dans l'aperçu de l'éditeur.
- **Le titre n'apparaît dans la barre d'en-tête qu'au défilement** (fiches et protocoles,
  lecture et édition). En haut de page, le corps affiche déjà le titre : la barre garde la
  marque, puis bascule sur « titre + nature du contenu » une fois le titre du corps sorti de
  l'écran — le motif « grand titre » d'iOS, déjà utilisé par l'accueil, appliqué entièrement.
  Hauteur de barre inchangée entre les deux états ; plus jamais deux titres affichés à la fois.
- **Un seul bouton rempli par écran.** Quand l'accueil affiche « Reprendre » (session en cours,
  teal plein), « Créer » — action d'autorat, rare en situation d'urgence — passe en ton doux ;
  il reste plein quand aucune session n'est affichée. Règle notée dans AGENTS.md.
- **« Validation : MM/AAAA »** remplace « Validée MM/AAAA » : le même libellé sert aux fiches
  (féminin) et aux protocoles (masculin), l'accord unique était fautif pour l'un des deux.
- **Doc — sémantique du vermillon régularisée** (`:root` + AGENTS.md) : `--critical` couvre la
  destruction **et l'arrêt d'un processus vivant** (« Terminer » une session stoppe les
  minuteurs — registre du rouge « raccrocher ») ; le bouton, volontairement vermillon, n'est
  plus une exception à la règle.

### Corrigé
- **Cartes de liste accessibles au lecteur d'écran.** La carte entière était un « bouton »
  contenant d'autres boutons (épingle, badge « À compléter ») — structure proscrite (ARIA).
  Le titre est désormais le vrai bouton, sa zone de tap étendue à toute la carte ; épingle et
  badge restent des commandes indépendantes, au clavier comme au doigt. Aucun changement visuel.
- **Pastilles de catégories : zone de tap portée à ~44 px** (halo invisible autour de chaque
  pastille, filtres de l'accueil et choix de catégorie des éditeurs) — taille visuelle inchangée.

## [4.0.2] — 2026-07-11
### Corrigé
- **Synchronisation : certains contenus n'arrivaient jamais sur un appareil déjà synchronisé**
  (constaté sur des protocoles, mais valable pour les fiches). Le rattrapage incrémental ne
  demandait au serveur que les lignes **plus récentes que la dernière synchro** ; or deux cas
  réels produisent des lignes « dans le passé » : du contenu créé **avant votre adhésion** à une
  bibliothèque partagée (l'accès le révèle d'un coup, avec ses dates d'origine), et un appareil
  à l'**horloge en retard** (l'horodatage vient de l'appareil qui enregistre). Ces contenus
  n'apparaissaient qu'en repartant de zéro (nouveau navigateur) — même la synchro manuelle ne
  les ramenait pas. Chaque synchro effectue désormais un **repêchage de complétude** : un
  inventaire léger (identifiants + dates) de tout ce qui est visible, puis récupération ciblée
  des seules lignes manquées, appliquées avec les mêmes règles qu'avant (la version la plus
  récente gagne, une saisie locale plus fraîche n'est jamais écrasée).

### Modifié
- **Barre d'en-tête harmonisée entre fiches et protocoles en lecture.** Un protocole ouvert
  affichait « Protocole » sous son titre, mais une fiche ouverte n'affichait rien sous le sien.
  La lecture d'une fiche porte désormais le libellé « Aide cognitive » au même endroit — les
  deux barres ont la même structure (titre + nature du contenu). Le bandeau teal reste dédié à
  l'état (mode crise, session en cours) et ne change pas.

## [4.0.1] — 2026-07-11
### Corrigé
- **Titre dans la barre d'en-tête : comportement unifié entre fiches et protocoles, lecture et
  édition.** En lecture de protocole, le titre s'affichait en petite troisième ligne sous
  « Aides cognitives / Protocole » et se retrouvait **coupé par le bas de la barre** (rangée
  d'identité plafonnée à 44 px) ; en édition (fiche comme protocole), aucun titre n'apparaissait.
  Désormais, dans toute vue fiche/protocole, le titre **remplace la marque** sur une seule ligne
  ellipsée à l'échelle du titre d'accueil (17 px), avec le libellé « Protocole » ou « Édition »
  dessous — même géométrie qu'avant, la hauteur de barre ne change pas. En édition, le titre de
  la barre **suit la saisie en direct** dans le champ « Titre » ; champ vidé, la marque revient
  (création d'une nouvelle fiche). Le mode crise est inchangé (même motif, désormais partagé).

## [4.0.0] — 2026-07-09
### Ajouté
- **Documents PDF joints aux fiches.** Chaque fiche peut porter jusqu'à 10 PDF (15 Mo max
  chacun : protocoles de service, recommandations…), ajoutés depuis l'éditeur (le contenu du
  fichier est vérifié, pas seulement son extension) et lisibles hors ligne. Un document peut
  être **partagé entre plusieurs fiches/protocoles du même périmètre** (« Joindre un document
  existant ») : le remplacer le met à jour partout, il n'est supprimé que quand plus rien ne le
  référence. Les PDF sont stockés en Blob natif dans IndexedDB (jamais en base64 dans la fiche)
  et n'alourdissent pas l'export JSON (seules leurs métadonnées y figurent). Le binaire est
  stocké en ArrayBuffer (fiable sur tous les navigateurs, y compris Safari/iOS où le stockage
  de Blob dans IndexedDB a des bugs connus) ; en cas de problème, la visionneuse distingue
  clairement « composant non téléchargé » (hors-ligne avant première utilisation) de
  « fichier endommagé ».
- **Visionneuse PDF intégrée, toutes pages, tous appareils.** Lecture dans l'app (iPhone, iPad,
  Android, ordinateur) : défilement de toutes les pages, zoom −/+/Largeur, plein écran, Échap
  pour fermer. Rendu par pdf.js **vendorisé** (`vendor/pdfjs`, version figée 4.10.38, précaché
  par le service worker → fonctionne hors ligne dès l'installation, chargé paresseusement →
  aucun coût au démarrage) : **exception unique et documentée à la règle zéro-dépendance**
  (AGENTS.md). Rendu virtualisé (les pages éloignées de l'écran sont libérées : un long PDF ne
  sature pas la mémoire d'un iPhone).
- **Synchronisation cloud des documents.** Bucket privé Supabase Storage avec politiques RLS
  strictes : le chemin encode le périmètre (`u/<compte>/…` personnel — propriétaire approuvé
  seul ; `l/<bibliothèque>/…` partagé — lecture pour tout membre, écriture éditeur/admin),
  plafonds de taille et de type appliqués par le serveur, aucun accès sans session. Les
  documents manquants sont **téléchargés systématiquement** en arrière-plan à la synchro
  (disponibles hors ligne en urgence), déplacements entre bibliothèques et suppressions
  propagés, orphelins listés pour l'app-admin (`list_orphan_attachments`, purge manuelle).
  Nouveaux tests RLS (section 9) : lecture croisée refusée, usurpation de chemin refusée,
  rôles respectés, anonyme sans accès.
- **Nouvelle section « Protocoles ».** Le **titre de la page d'accueil devient le sélecteur**
  dans la barre fixe : « Aides cognitives | Protocoles » en titres à onglets — une ligne de
  base court sous les deux titres et un indicateur ajusté au titre actif glisse de l'un à
  l'autre avec un léger ressort — transition de contenu fluide et jamais bloquante, bascule à
  tout moment, mémorisée par compte. Sépare les aides cognitives de crise des protocoles de
  référence.
  Un protocole = titre, catégorie (jeu partagé avec les fiches), bibliothèque (perso ou
  partagée), date de validation, état brouillon/validé, **un ou plusieurs PDF** et/ou un
  **contenu rédigé dans l'app**. Recherche plein texte, export/import JSON (champ
  rétrocompatible), synchronisation cloud complète (table `protocols`, mêmes politiques RLS
  que les fiches — tests section 10).
- **Contenu rédigé en mise en forme simple (mini-Markdown maison, sans dépendance).** Titres
  (`#`/`##`/`###`), listes à puces et numérotées avec **sous-listes** (2 espaces d'indentation),
  **citations** (`>`), **code** en ligne et en bloc (```` ``` ````), séparateur (`---`),
  **gras**, *italique*, liens web, liens vers un PDF joint, images intégrées (réduites et
  stockées hors ligne). Éditeur avec barre d'outils (B, I, H2, H3, listes, citation, code,
  lien, image) et aperçu en direct. Rendu sûr par construction (échappement d'abord,
  `javascript:` et identifiants hostiles refusés, aucun balisage interprété dans le code —
  testés) ; balisage non reconnu laissé visible, le rendu ne casse jamais.
- **Recherche transversale.** La recherche de l'accueil évalue aussi la requête sur l'autre
  section : un bloc discret « N protocoles correspondent aussi à cette recherche » (et
  inversement) bascule de section en conservant la recherche — en urgence, pas besoin de se
  souvenir d'où vit un contenu.

### Modifié
- **En-tête clair (inversion) + identité d'accueil.** La barre fixe prend la couleur du fond de
  page (hairline de séparation), le teal se retire dans les **accents**. L'accueil retrouve la
  **ligne d'identité** « Aides cognitives » + compte, avec en dessous la rangée d'onglets
  « **Aides | Protocoles** » (la section est renommée pour lever le doublon avec le nom de
  l'app). Le **mode crise** ne recolore plus la barre : il s'annonce par un **bandeau d'état
  étiqueté** sous la barre (« Mode crise · session en cours… », pattern des systèmes
  critiques — texte + couleur + position), le titre de la fiche gardant l'emplacement et le
  corps du titre d'accueil ; le **rappel minuteurs y est fusionné** (chrono compact cliquable à
  droite du bandeau — un seul bloc d'état, apparition en fondu discret jamais bloquant). Sur
  l'accueil, la **ligne d'identité se replie au défilement** (pattern grand titre : espaces
  confortables en haut de page, barre minimale en navigation). Propagé partout : bouton Compte
  et pastille d'état, thème sombre, couleur de la barre d'état système.
- **Base locale IndexedDB v4 → v5** (stores `attachments` et `protocols`). Migration
  automatique et silencieuse ; si un vieil onglet de l'app bloque la mise à jour du stockage,
  un message invite à le fermer (au lieu d'un repli silencieux vers une bibliothèque vide).
- La jauge de stockage indique le poids des documents PDF ; le tableau de bord app-admin
  affiche protocoles et poids du bucket ; le message d'erreur « contenu trop volumineux »
  couvre les documents.
- Chrome de l'accueil (sélecteur de section, barre de bibliothèques, catégories, recherche)
  et composants Documents **factorisés** entre fiches et protocoles (aucune logique dupliquée).
- **Correctifs de l'audit design 4.0.0** (conformité WCAG 2.2 AA + cohérence des palettes) :
  - **Pastilles d'état du compte et de la synchro** : couleurs sémantiques qui suivent le thème
    (ok = teal, attente = ambre, erreur = vermillon, inactif = gris) — les anciennes valeurs
    vives, calibrées pour l'en-tête sombre d'avant l'inversion, tombaient à 1,3–2,4:1 sur la
    barre claire (3:1 requis) ; désormais ≥ 3:1 dans les deux thèmes.
  - **Manifest et barre système alignés sur le chrome clair** : `theme_color`/`background_color`
    du manifest et balise `theme-color` initiale = fond de page (plus de barre teal au-dessus
    d'une app claire à l'installation) ; la couleur suit le thème sombre dès avant le premier
    rendu. Le **verrou portrait est retiré** (usage tablette en paysage possible).
  - **Plancher typographique 11 px** (étiquettes du bandeau de crise, indice « maintenir »,
    numéros du fil d'Ariane, badges) et **zones de tap** : chrono du bandeau de crise ≥ 44 px,
    jauge de stockage ≥ 24 px (WCAG 2.5.8).
  - **Palettes dé-dupliquées** : les overrides du thème sombre qui recopiaient des valeurs de
    tokens en hex sont supprimés (les tokens suivent seuls le thème) ; nouveau token
    `--input-bg` pour tous les fonds de champs ; plus aucun style inline sur les pastilles de
    catégorie (classes `.on`/`.mgr` tokenisées) ; le panneau de navigation garde son liseré
    teal en thème sombre (perdu jusqu'ici par un override trop large).
  - **Sémantique** : la marque devient le `h1` du document, les titres de cartes des `h2`
    (plan de titres propre pour lecteurs d'écran) ; le sélecteur de section est un vrai
    `tablist` (flèches ←/→, focus itinérant, `aria-selected`) ; badge « À compléter » souligné
    en pointillés (affordance d'action) ; **bouton « Créer » dans les états vides** ;
    breakpoints consolidés sur une échelle fermée (430/560/640/780/900 px, notée AGENTS.md).

### Sécurité
- Nouveaux garde-fous : `safeAttachment` (id jamais régénéré, entrée invalide rejetée,
  extension `.pdf` garantie même après renommage), `safeFileName`, validateurs du
  mini-Markdown — tous testés (246 tests). Un PDF endommagé affiche un message clair et ne
  bloque jamais la navigation (rendu isolé dans un worker, jamais de code exécuté depuis un
  document). La suppression de compte (RGPD) emporte aussi les protocoles personnels.

### À savoir
- Le schéma serveur doit être re-exécuté (`supabase/schema.sql`) puis validé avec
  `supabase/rls-tests.sql` pour activer bucket et table `protocols`.
- Multi-onglets : si la bibliothèque semble vide après la mise à jour, fermez les autres
  onglets de l'app puis rechargez (migration de la base locale en attente).
