# Journal des modifications

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

## [3.5.5] — 2026-07-09
### Corrigé
- **La barre Enregistrer/Supprimer s'efface pendant la saisie sur téléphone.** Le retrait de
  l'encart bas (3.5.4) ne suffisait pas : selon les navigateurs, un espace résiduel subsistait
  au-dessus du clavier virtuel, et la barre elle-même mangeait un écran déjà réduit de moitié.
  Sur écran tactile, la barre est donc masquée tant qu'un champ de saisie texte a le focus
  (clavier ouvert) et réapparaît dès la fin de la saisie. Sur ordinateur (pas de clavier
  virtuel), elle reste visible pendant la frappe, comportement inchangé.

## [3.5.4] — 2026-07-09
### Corrigé
- **Plus d'espace vide entre la barre Enregistrer/Supprimer et le clavier.** Dans l'éditeur, la
  barre collée en bas conservait son encart `env(safe-area-inset-bottom)` (zone du geste système,
  ~34 px sur iPhone) pendant la saisie : quand la fenêtre est réduite au-dessus du clavier
  virtuel (PWA installée notamment), cet encart s'intercalait en bandeau vide entre les boutons
  et le clavier. L'encart est maintenant retiré tant qu'un champ de saisie texte a le focus
  (clavier à l'écran, il recouvre la zone du geste système) et rétabli dès la fin de la saisie ;
  sans clavier virtuel (ordinateur), l'encart vaut 0 et rien ne change. Les champs sans clavier
  (cases à cocher, boutons) sont exclus de la détection.

## [3.5.3] — 2026-07-09
### Corrigé
- **Ouvrir une fiche affiche son début.** Après avoir défilé dans la bibliothèque, ouvrir une
  fiche conservait la position de défilement (on arrivait au milieu de la fiche). Le défilement
  est désormais géré par transition de vue : haut de page à l'ouverture d'une fiche (ou au
  changement de fiche via une banderole d'alerte) et à l'entrée en édition ; au retour à la
  bibliothèque, la position de la liste est restaurée là où on en était. Les re-rendus en lecture
  (cocher une étape, minuteurs) ne provoquent toujours aucun saut, usage en crise oblige.

### Modifié
- **Icône « attention » unifiée.** Le triangle arrondi du bandeau « Brouillon » devient le dessin
  unique de l'avertissement : bandeau « Ne pas oublier », toasts, fenêtre de suppression de compte
  et erreurs de synchro l'utilisent désormais via un tracé partagé (`WARN_GLYPH`, servi par
  `uiIcon('warn')`) — plus de SVG dupliqués en dur (quatre copies divergentes supprimées). Dans le
  badge d'en-tête de section (« Ne pas oublier »), le tracé est recentré optiquement pour rester
  aligné avec le titre.

## [3.5.2] — 2026-07-08
### Ajouté
- **Barre de vie des notifications.** Une fine barre en bas des toasts se vide de gauche à droite
  sur la durée d'affichage : on voit d'un coup d'œil quand la notification va disparaître. Elle
  équipe le toast bas d'écran (durée variable selon le message) et la banderole ambre de fin de
  minuteur (10 s). Barre en `currentColor` (contraste garanti sur fond sombre comme ambre, aucune
  nouvelle couleur), purement décorative pour les lecteurs d'écran (`aria-hidden`), durée
  synchronisée avec la temporisation de disparition.

## [3.5.1] — 2026-07-07
### Corrigé
- **Message de mise à jour exact.** Le toast introduit en 3.5.0 annonçait « la nouvelle version
  sera utilisée à la prochaine ouverture » alors que, dans le cas normal (en ligne), la stratégie
  « réseau d'abord » venait déjà de servir le nouvel index.html : l'utilisateur ÉTAIT déjà sur la
  nouvelle version. Le service worker annonce désormais sa version à la page (postMessage à
  l'activation) ; la page la compare à `APP_VERSION` et affiche le bon message — « vous utilisez
  déjà la nouvelle version » (versions égales, cas normal) ou « rechargez la page pour l'utiliser »
  (page encore servie par l'ancien cache hors-ligne).
- Au passage : la file des messages du worker est démarrée explicitement
  (`navigator.serviceWorker.startMessages()`) — indispensable avec `addEventListener`, sans quoi
  les messages restaient en file indéfiniment et aucun toast ne s'affichait. Les deux branches du
  message ont été vérifiées en navigateur.

## [3.5.0] — 2026-07-07
Version issue d'un audit complet (qualité de code, PWA, sécurité, performance). L'audit sécurité
n'a trouvé aucune faille exploitable (échappement et assainissement complets, RLS couvrante).

### Ajouté
- **Notification de mise à jour** : un toast « Application mise à jour » s'affiche quand une
  nouvelle version du service worker s'active — la mise à jour n'est plus silencieuse ; jamais de
  rechargement forcé (l'onglet ouvert continue sur la version en cours).
- **Build optionnel `npm run build`** : produit `dist/` (copie déployable allégée d'~25 %,
  commentaires du code retirés via terser sans aucune transformation du code ; devDependency
  uniquement, le runtime reste sans dépendance). Le dépôt servi tel quel reste le défaut.
- **Manifest** : champ `id` (identité d'installation stable) et icône maskable 192 px
  (`icon-192-maskable.png`, aussi pré-cachée par le service worker).
- **Tests** : couverture directe de `flattenFiche` et de `buildFlowSVG`/`wrapText`
  (structure du SVG, échappement, boucle de décision ambrée pointillée) — 179 tests.

### Performance
- **Démarrage** : les lectures IndexedDB (catégories, fiches, sessions, notes) se font en
  parallèle, et la lecture des fiches faite par le test « base vide ? » est réutilisée au lieu
  d'un second `getAll` complet.
- **Recherche débouncée (150 ms)** : la bibliothèque n'est plus re-rendue à chaque frappe.
- **Rappel minuteurs de l'en-tête** : la géométrie (`getBoundingClientRect`, reflow forcé) n'est
  relue qu'au défilement/redimensionnement/re-rendu, plus toutes les 300 ms.

### Modifié
- **Refactor sans changement de comportement** (vérifié : sortie SVG identique octet pour octet
  sur jeux d'essai, 179 tests, parcours complet en navigateur) :
  `buildFlowSVG` scindé en quatre étapes nommées (`flowMeasure`/`flowPlace`/`flowRoute`/
  `flowNodesSVG`) ; `renderAuth` scindé par écran (suppression, en attente/refusé, connecté,
  connexion) ; `renderRead`/`renderEditor` scindés en gabarit + câblage (`bindReadEvents`,
  `bindEditorEvents`) ; calcul d'affichage des minuteurs unifié (`timerDisplay`, une seule
  formule pour carte/tick/en-tête) ; pastilles de catégorie unifiées (`catChipHtml`) ;
  bandeau « Ne pas oublier » rendu via `staticBlock`.
- **`release.sh` synchronise aussi `package.json`** (bloqué à 3.1.0 depuis plusieurs versions).
- **Docs hébergement** : comparatif explicite GitHub Pages vs Netlify/Cloudflare Pages —
  `_headers` (CSP HTTP, HSTS, `no-cache` sur `sw.js`) n'est appliqué que par ces derniers.
- **CHANGELOG** : les versions 3.0.0 → 3.3.7 sont déplacées dans `CHANGELOG-archive.md`.

### Retiré (code mort, aucun impact visible)
- Helper `textTrunc` jamais appelé ; `ficheNeedsCompletion` (doublon de
  `completionSpots().length`, tests réécrits sur cette dernière) ; classes CSS orphelines
  (`.auth-who`, `.bar-act`, `.fiche-img`, `.h-steps`, `.read-actions`, `.read-img`, `.ro-hint`,
  `.tk-empty`, `.thumb` — dont une règle sombre `filter:brightness(.92)` qui ne ciblait plus
  aucune classe émise depuis un renommage passé ; à réintroduire sur `.gthumb img` si
  l'atténuation des images en thème sombre est souhaitée).

## [3.4.9] — 2026-07-07
### Corrigé
- **Contraste des boutons d'action en thème sombre.** Le texte blanc sur fond `--primary` (devenu
  un teal clair en sombre) tombait à 2,6:1 — illisible sous WCAG AA. Nouveau token `--on-primary`
  (blanc en clair, encre foncée en sombre) appliqué aux boutons primaires, cases cochées et avatar.
- **Minuteurs visibles pendant tout le déroulé des étapes.** Le panneau « Minuteurs & compteurs »
  disparaissait de l'écran dès qu'on descendait dans les étapes cochables ; un bandeau apparaît
  maintenant dans l'en-tête (collant) dès qu'un minuteur tourne et que le panneau est hors champ —
  le temps restant reste toujours lisible, un tap ramène au panneau.
- **L'algorithme (schéma) ne masque plus la première étape.** Il s'affichait déplié par défaut à
  l'ouverture d'une fiche, poussant la première case cochable sous ~700 px de contenu ; replié par
  défaut désormais (reste à un tap via « Voir l'algorithme »), déplié à la demande seulement.
- **Cibles tactiles remontées à 44 px** en mode crise et dans les fenêtres : fermeture des
  modales, boutons minuteurs/compteurs/son/réinit., bouton compte de l'en-tête, croix des
  banderoles d'alerte.
- **Bouton Son ambigu** : affichait juste « Son »/« Muet » sans dire si c'était l'état ou l'action.
  Libellé d'état explicite (« Son activé »/« Son coupé », `aria-pressed`), et l'état coupé — un
  choix risqué en crise — passe en ambre pour rester visible.
- **Horodatage du journal des actions** : l'heure cliquable (correction manuelle) n'avait pas
  d'équivalent clavier ; Entrée/Espace fonctionnent désormais.
### Modifié
- **Couleurs consolidées vers les tokens existants** : les rouges « erreur » (4 valeurs), les ors
  « attente/décision » et les teals « identité/temps réel » dispersés en dur convergent vers
  `--critical`, `--verify`, `--live` (nouveau) ; nouveau `--line-hover` unique pour les survols de
  boutons/chips ; l'état « minuteur en cours » passe du chaud (orange, proche de l'alarme) à un
  teal froid — le chaud reste réservé aux alarmes et aux gestes de remise à zéro.
- **Bordures des champs de saisie** relevées à `--line-strong` (contraste composant ≥ 3:1) ;
  `::placeholder` stylé explicitement (n'était pas maîtrisé sur les fonds personnalisés).
- **Wording clarifié** : « Reprendre » (session vive de l'accueil), « Rouvrir » (session archivée
  de l'historique) et « Relancer » (minuteur en pause) ne se recouvrent plus ; « Réinit. » /
  « Recommencer » unifiés en « Remettre à zéro » ; retour de l'éditeur renommé
  « Quitter sans enregistrer » (il jette bien le brouillon en cours).
- **Fil d'Ariane masqué au premier bloc** de la prise en charge (faisait doublon avec le titre du
  bloc sans offrir de retour possible) ; apparaît dès le 2ᵉ bloc visité.
- **Enregistrer (éditeur) collant en bas de l'écran** sur le formulaire, désormais long à faire
  défiler ; pied de page réduit à l'état (masque Exporter/Importer/Thème) pendant une session en
  cours, pour ne pas ajouter de cibles non pertinentes en crise.
- Couleur de catégorie retirée de la palette (`#0d5b56`, identique à `--primary` — une catégorie
  sélectionnée ne doit jamais ressembler à un bouton d'action).
- Ajout d'un lien d'évitement clavier (« Aller au contenu »).

## [3.4.8] — 2026-07-06
### Corrigé
- **Le gras n'éclate plus les lignes des listes de fiche.** Les puces de « Ne pas oublier »,
  « Confirmation diagnostique », « À vérifier » et « Diagnostics différentiels », ainsi que les
  boutons d'option des nœuds de décision, sont des conteneurs flex : un `**gras**` au milieu du
  texte le découpait en plusieurs éléments flex séparés par l'espacement de la puce (espaces
  parasites autour du gras, texte rendu en « colonnes » sur les lignes longues). Le texte formaté
  est désormais toujours enveloppé dans un `<span>` unique (même schéma que les étapes) ;
  suppression au passage du paramètre `forget` de `staticBlock` et de la règle CSS `ul.forget`,
  vestiges jamais utilisés de ce correctif.

## [3.4.7] — 2026-07-06
### Modifié
- **Un seul bouton « Se déconnecter » dans la fenêtre Compte.** « Changer de compte » faisait
  exactement la même chose (déconnexion → écran de connexion, où l'on peut saisir n'importe
  quel e-mail) : la v3.3.5 avait déjà regroupé leurs gestionnaires en un seul point de code,
  les deux boutons visibles n'avaient plus de raison d'être. Le message de confirmation couvre
  le cas « autre compte » (« Vous pourrez ensuite vous reconnecter, ou utiliser un autre
  compte. ») ; retiré des deux écrans (connecté, en attente/refusé).
- **Champ « Saisissez le code » : 8 points.** L'espace réservé des deux saisies de code
  (connexion, suppression de compte) affichait 6 points alors que le code reçu par e-mail
  compte 8 chiffres.

## [3.4.6] — 2026-07-06
### Ajouté
- **Retour des fiches « hors compte » pour un compte non validé.** Les fiches emportées à la
  connexion dans un compte **en attente de validation** ou **refusé** restaient dans l'espace
  local de ce compte : en suivant le conseil « réessayer avec une autre adresse e-mail », elles
  devenaient inaccessibles (aucun chemin d'interface n'y menait plus). Trois chemins de retour,
  réservés aux comptes jamais synchronisés depuis l'appareil (garde `canReturnToAnon`, pure et
  testée : jamais pour un compte déjà synchronisé, dont les ids sont réclamés dans le cloud) :
  - bouton **« Ramener mes fiches hors compte »** sur l'écran Compte (en attente / refusé) ;
  - case « Ramener d'abord les fiches… » dans la confirmation de **« Changer de compte »** et
    **« Se déconnecter »** (nouvelle option `checkSafe` de la fenêtre de confirmation : une case
    protectrice ne peint plus le bouton en rouge) ;
  - retour **automatique** après « Supprimer cette demande de compte » (sans lui, l'espace du
    compte supprimé devenait définitivement orphelin, l'OTP ne fonctionnant plus).
  Le déplacement précède toujours la déconnexion et la bascule d'espace : en cas d'échec, rien
  ne bouge. 6 tests ajoutés (162 tests).

### Modifié
- **Textes honnêtes pour les comptes non validés.** Le dialogue « emporter dans ce compte » dit
  « synchronisées une fois le compte validé, si l'instance exige une validation » (au lieu d'une
  promesse de synchro immédiate) ; l'écran de suppression d'une demande n'évoque plus de
  « bibliothèque synchronisée supprimée du cloud » (rien n'y a jamais été envoyé) et la case
  « Effacer aussi les fiches de cet appareil » avertit qu'elles n'existent nulle part ailleurs.

## [3.4.5] — 2026-07-06
### Modifié
- **Prompt IA : cinq règles ajoutées, tirées de la relecture d'une fiche ACR (ERC 2025) générée
  avec le prompt 3.4.1.** Les défauts observés remontaient à des règles absentes :
  1. *Une étape = un seul moment* : interdiction de fusionner deux temps distincts sur une ligne
     (ex. « après 3ᵉ choc : amiodarone 300 mg ; après 5ᵉ choc : 150 mg ») — cochée au premier
     temps, la case masquait le rappel du second.
  2. *Gestes uniques hors des boucles* : une boucle de réévaluation ne contient que ce qui se
     refait à chaque cycle ; les gestes uniques (accès vasculaire, intubation…) sortent de la
     boucle, sinon l'app les re-propose à cocher à chaque tour.
  3. *Pas de gouvernance dans les étapes* : les positions d'organisation non actionnables en
     situation (« technique X seulement si taux de succès > 95 % ») vont dans « Ne pas
     oublier » ou sont exclues.
  4. *Critères d'arrêt / limitation* : s'ils existent dans la source, ils figurent dans la
     fiche (« quand s'arrêter » est le point de bascule le plus difficile) ; sinon invite locale.
  5. *Une interdiction par ligne* dans « Ne pas oublier » (fini les lignes qui en empilent trois).
  Liste de vérification finale du prompt mise à jour en conséquence ; 4 invariants de test
  ajoutés (156 tests).

## [3.4.4] — 2026-07-05
### Modifié
- **Message du badge « À compléter » reformulé sans jargon.** « Invites “à compléter” dans :
  Références » employait « invite » (calque de l'anglais *prompt*), incompréhensible pour
  l'utilisateur. Le toast et l'infobulle disent désormais « Reste à compléter : Références »,
  et en lecture « — remplacez les mentions “à compléter” par vos informations locales. »
  (règle du projet : aucun jargon technique dans les textes visibles).

## [3.4.3] — 2026-07-05
### Ajouté
- **Le badge « À compléter » est tapable.** L'emplacement des invites n'était donné que par
  l'infobulle `title`, invisible sur mobile (pas de survol). Un tap / clic / Entrée ou Espace
  sur le badge affiche désormais un toast listant les emplacements (« Invites “à compléter”
  dans : Références · Bloc “Traitement” »). Le badge reste visuellement discret : la cible
  tactile (~36 px) est étendue par un pseudo-élément invisible ; `role="button"`, `tabindex`
  et `:focus-visible` posés. Sur une carte de la bibliothèque, taper le badge n'ouvre PAS la
  fiche (même garde que l'épingle `data-pin`).

## [3.4.2] — 2026-07-05
### Corrigé
- **Cliquer le libellé « Contexte local » déclenchait le bouton « B » (gras).** Le bouton était
  placé DANS le `<label>` : sans attribut `for`, un label adopte comme contrôle implicite son
  premier élément de formulaire descendant — le bouton — et tout clic sur le libellé le
  déclenchait. Le bouton est sorti du label (ligne `lab-row` label + bouton) ; cliquer le
  libellé est redevenu inerte, le bouton et Ctrl/Cmd-B fonctionnent comme avant.
- **Badge « À compléter » : fin des faux positifs et emplacement des invites affiché.** Le badge
  se déclenchait sur n'importe quel « ⚠ », alors que ce symbole sert aussi de simple marqueur
  d'avertissement clinique (« ⚠ NE PAS associer… ») : ces fiches paraissaient « à compléter »
  sans qu'aucune invite ne soit visible. Seul le texte « à compléter » (accents facultatifs)
  compte désormais — le marqueur IA « ⚠ À COMPLÉTER : … » le contient et reste détecté. Et comme
  une invite peut être discrète (ex. « Exemple à compléter » dans les références des fiches
  d'exemple), l'infobulle du badge liste maintenant les emplacements concernés (« Invites
  “à compléter” dans : Références · Bloc “Traitement” »). Nouvelle fonction pure
  `completionSpots`, testée (152 tests).

## [3.4.1] — 2026-07-05
### Ajouté
- **Gras dans les textes de fiche.** Un fragment entouré de `**double astérisque**` s'affiche en
  gras en lecture et en mode crise (étapes, listes Confirmation / À vérifier / Ne pas oublier /
  Différentiels / Références, question et options des décisions, contexte local, compte-rendu de
  session). Réservé aux doses time-critical et aux interdictions. Données stockées inchangées
  (chaînes brutes : export/import et anciennes versions inchangés) ; balisage non apparié affiché
  tel quel (la coquille reste visible, le rendu ne casse jamais) ; échappement `esc()` appliqué
  avant la conversion ; l'algorithme SVG et la recherche plein texte ignorent les `**`.
  Dans l'éditeur : bouton « B » à côté des champs concernés (entoure/retire sur la sélection)
  et raccourci Ctrl/Cmd-B. Fonctions pures `fmt`/`stripBold` testées.
- **Badge « À compléter ».** En bibliothèque et en tête de fiche, un badge discret (couleur
  avertissement) signale une fiche contenant des invites laissées en suspens (« à compléter »,
  marqueur ⚠) — gabarit local non renseigné ou manque signalé par la génération IA. Fonction
  pure `ficheNeedsCompletion` testée.
- **Fin de parcours explicite.** Le bout d'une branche sans suite affiche « FIN — fin de cette
  branche de prise en charge. » (lève le doute « ai-je tout déroulé ? »).
- **Gabarit de contexte local.** Une fiche créée à la main part avec les invites « Tél renfort :
  à compléter » et « Tél régulation : à compléter » (les deux contextes d'exercice : structure
  et SMUR).

### Modifié
- **Prompt IA refondu** (fenêtre « Créer via IA »), aligné sur les référentiels d'aides
  cognitives de crise (Stanford Emergency Manual, fiches CAMR/SFAR) : double contexte
  structure/SMUR (renfort sur place ou régulation) avec renfort imposé dans le premier bloc ;
  critères de priorisation de l'extraction (time-critical d'abord, cibles chiffrées dans
  « À vérifier », interdictions dans « Ne pas oublier », causes réversibles traitées comme des
  actions) ; traçabilité obligatoire (source datée + ligne « Fiche générée par IA le … ») ;
  manques marqués « ⚠ À COMPLÉTER » et contradictions de la source signalées, jamais tranchées ;
  verbes flous (« envisager / considérer ») remplacés par une forme conditionnelle ou de
  vérification active ; dilutions de la source recopiées mais jamais calculées, avec invite
  locale « Dilutions / protocoles locaux si différents » ; gras `**…**` autorisé avec parcimonie ;
  consignes par type de source (page web, PDF long, image/scan). Invariants du prompt testés.

## [3.4.0] — 2026-07-05
### Ajouté
- **Les fiches « hors compte » restent accessibles depuis l'écran de connexion.** L'espace local
  suivant le dernier compte connecté, les fiches créées sans compte puis « laissées hors compte »
  à la connexion devenaient définitivement invisibles sur l'appareil (rien ne ramenait jamais à
  l'espace sans compte). L'écran de connexion affiche désormais, si cet espace contient des
  fiches, un lien « Cet appareil contient N fiches hors compte — les consulter sans se
  connecter » : il bascule sur l'espace sans compte (même bascule atomique qu'un changement de
  compte, proposée uniquement déconnecté — jamais de mélange entre bibliothèques). Une connexion
  ultérieure depuis cet espace re-propose de les emporter dans le compte : ce choix n'est plus
  définitif, et le dialogue « Fiches locales » l'explique désormais.

### Modifié
- Le comptage des fiches hors compte est sans effet de bord (n'attribue jamais la base
  historique à un espace, ne crée aucune base fantôme) ; fonction pure `liveFicheCount` testée.


---
Versions antérieures (3.0.0 → 3.3.7) : voir [CHANGELOG-archive.md](CHANGELOG-archive.md).
