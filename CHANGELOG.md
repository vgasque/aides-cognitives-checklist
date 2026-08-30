# Journal des modifications

## [5.18.0] — 2026-08-30
### L'accueil sans mécanisme — refonte complète, conçue sur maquettes et corrigée à l'usage

Chantier mené sur le canvas « Accueil — la barre d'en-tête » puis ajusté en direct sur captures
de l'auteur ; chaque arbitrage est consigné dans `docs/decisions/lot-v5-18.md` (A238-A262).
Point de départ : « le principe de l'en-tête qui se rétrécit est bien, l'implémentation est
mauvaise » — huit rouages (repli home-slim, seuils, hystérésis, re-mesures, rescues) pour 52 px.

- **L'en-tête n'a plus d'états** : il est statique et défile — le défilement EST l'état. En
  étroit, marque 21 px / logo 30 (descendus d'un cran après essai à 23/32 : « un peu trop
  gros ») et « Créer » garde son mot dès 390 px (palier déclaré). En voie large, la RECHERCHE
  est la barre du haut (⌘K en invite, effacée au focus), marque à la largeur de la sidebar.
- **L'accès vit dans le dock** : pilule de recherche FIXE en bas en étroit (zone du pouce,
  patron Safari/Maps), qui loge le champ sous le clavier (`--vvt`/`--vvh`) ; rangée d'en-tête
  en large. **Les filtres vivent dans la fonction recherche** : hors recherche la pilule est
  seule ; chercher fait paraître les crans Tout · Aides · Protocoles (qui agissent sans perdre
  la requête) et « Filtrer (n) » ; hors recherche, un filtre actif reste modifiable par le
  bouton « filtres : … » de la ligne RÉPERTOIRE — l'état n'est jamais piégé.
- **La liste est l'UNION des bibliothèques**, en trois rangements — « Rangé par
  <bibliothèque · catégorie · A–Z> ⌄ », une phrase-menu, **retenue par compte et synchronisée
  entre appareils** (`data.prefs.homeGroup`, sans jamais re-ranger l'écran ouvert). Sections
  en CARTES, intertitre collant DEDANS (il coiffe la carte au défilement), provenance des
  homonymes, pastille + nom de catégorie sur chaque rangée.
- **Un SEUL dessin de rangée à toutes les largeurs** (direction A du canvas « Accueil épuré »,
  retenue contre un tableau 6 colonnes essayé puis rejeté : ses colonnes répétaient les
  intertitres et ses cases vides s'écrivaient en tirets) : titre + ligne de méta — nature ·
  discriminant · catégorie · code · date seulement si elle existe. Au pointeur fin, l'étoile
  ne vit qu'au survol de sa rangée ; l'épinglée reste pleine, le tactile ne change pas.
- **La sidebar (≥ 780) filtre, à une seule grammaire** : « Toutes » ou une bibliothèque
  (filtre de vue, patron Finder — le rangement n'est jamais touché), catégories du périmètre
  choisi avec comptes stables ; le bouton filtre n'existe plus en voie large. « Rangé par » et
  « Sélectionner » rejoignent la ligne RÉPERTOIRE à ≥ 1200, harmonisée à 12 px.
- **Accès direct en TUILES à toutes les largeurs** — deux par ligne dès 390 px, titre long à
  4 lignes (13,5 px) en étroit ; la fiche reste aussi à sa place dans le répertoire.
- **Corrigés en route, sur captures** : le pied de page finit au-dessus du dock (page courte
  comme longue, `--sab` compté) ; la visée du rail A→Z ne soustrait plus un en-tête qui ne
  colle plus (65 px trop bas) et son centrage compte la réserve du dock ; les chips de type de
  la feuille avaient perdu leur habillage avec une purge (elles partagent désormais la recette
  des chips de catégorie) ; le fondu d'ouverture/fermeture d'une fiche est retiré (pilote View
  Transitions purgé — le glissement du retour de pile reste) ; tablette en rangées (la grille
  de cartes intermédiaire a vécu).
- **Sous le capot** : purge à grep de home-slim, des rescues, du seg de groupement et de
  `vtWrap` ; témoins doctrine réécrits sur la sémantique v5.18 (dix sections) ; passes
  complètes vertes à chaque étape (26/26 harnais, tests 1169 × 2 moteurs).

## [5.17.6] — 2026-08-28
### L'étoile revient au bord de sa carte

- **Signalé à l'usage, capture et flèche à l'appui** : « réduis l'espace entre l'étoile et la fin
  de la carte sur la page d'accueil — surtout visible en smartphone, c'est là que l'écart est le
  plus grand et ça sonne mauvais ».
- **Mesuré à 390 px** : le titre commence à 16 px du bord de la carte, l'étoile s'arrêtait à
  **47** — presque trois fois plus, sur une rangée dont c'est le seul autre objet. La rangée avait
  l'air de finir avant sa carte.
- **Le 40 px de rembourrage droit n'était pas un choix de dessin** : c'est 24 (l'ancienne valeur de
  base) + 16 (la compensation de la marge négative qui fait aller le fond d'une rangée d'un bord à
  l'autre de sa carte, v5.6). Personne n'avait re-regardé la somme. Il passe à **16**, égal au
  rembourrage gauche : la déclaration devient symétrique, ce qui est la seule forme qu'on retient
  sans la relire. Même correction en voie large (24 → 14, égal à son propre rembourrage gauche).
  Chaque rangée gagne au passage 24 px de largeur de titre en étroit.
- **Il reste 6-7 px d'écart optique, et c'est voulu** : ce sont les flancs de la *cible* de
  l'épingle (bouton de 30 px pour un glyphe de 18 — WCAG 2.5.8 se mesure sur la boîte, pas sur le
  dessin). Les rattraper collerait la zone tactile au bord de la carte, donc au rail A→Z.
- **Ce qui borne, c'est le rail, pas le goût** : à 390 px la carte finit à 364, le rail commence à
  366, et le halo de l'épingle s'arrête désormais à 351 — **15 px de franc**. Le plancher de 8 px
  de la gouttière carte↔rail ne bouge pas : son argument est la *peinture* (sous 6, le fond
  translucide du rail se poserait sur le bord de la rangée), et la surface tapable de la rangée
  elle-même atteignait **déjà** le bord de la carte, à 3 px du rail. Le commentaire de v5.10.8 qui
  affirmait « la cible la plus proche du rail finit 40 px avant la carte » a été corrigé sur
  place : une doctrine qui affirme un chiffre périmé est pire qu'aucune doctrine.
- Vérifié à 320, 390 et 1280 px : titre à 17, étoile à 23, cible de l'épingle 30 × 28.

## [5.17.5] — 2026-08-28
### L'anneau de focus des fenêtres se pose à la main

- **Correctif du lot précédent, signalé le lendemain** : « je ne sais pas quel bouton est
  sélectionné, et surtout ça paraît inconstant ». La v5.17.4 posait le bon focus à l'ouverture
  d'une fenêtre — sur l'action, ou sur « Annuler » quand l'action est destructrice — mais **sans le
  rendre visible**, et un état juste mais invisible est indiscernable d'un état absent.
- **La cause, mesurée sur les deux moteurs et cinq fenêtres.** `:focus-visible` n'est pas un état,
  c'est une **heuristique du navigateur** : sur un focus PROGRAMMATIQUE — celui que pose
  l'ouverture d'une fenêtre —, elle ne s'allume que si la dernière interaction était au clavier.
  Ouvrir un dialogue **à la souris**, c'est-à-dire le geste réel neuf fois sur dix, ne montrait
  donc **aucun anneau** ; l'ouvrir juste après une frappe clavier en montrait un. Le même dialogue,
  deux apparences — c'est exactement l'inconstance signalée, et elle vient du navigateur.
- **L'anneau se pose donc à la main**, sur le SEUL élément focalisé à l'ouverture, et il part au
  premier changement de focus : `:focus-visible` reprend alors la main **avec le même dessin**, si
  bien qu'aucune bascule ne se voit. Écarté : un `:focus` nu en cascade sur toute la fenêtre, qui
  aurait écrasé les anneaux accordés à leur fond (aplat primaire, matière système sombre) — un
  anneau bleu y disparaît purement et simplement.
- **Et la première mesure avait menti** : une sonde « y a-t-il un anneau ? » qui accepte
  `box-shadow` déclare marqué le bouton principal, qui porte une **élévation permanente**. Le seul
  bouton qui semblait indiqué était précisément celui qui ne l'était pas. Un anneau de focus se lit
  sur `outline`, jamais sur l'ombre.
- **Ce qui reste volontairement différent d'une fenêtre à l'autre** : le focus va sur l'action pour
  une confirmation ordinaire, sur « Annuler » pour une confirmation destructrice. Ce n'est plus une
  inconstance depuis que l'anneau se voit — c'est la convention système, et elle se **lit** : on
  sait, avant de frapper Entrée, si l'on va valider ou renoncer.

**Doctrine** : `docs/decisions/lot-v5-17.md`, entrée **A237**.
**Témoin** : `audit-doctrine.mjs`, section « Fenêtres · le bouton focalisé se voit, même ouvert à
la souris » — trois fenêtres, chacune ouverte **après un vrai geste souris** (c'est lui qui met le
navigateur dans l'état où le défaut existe), lecture de l'`outline` seule, et vérification
qu'aucun anneau ne reste collé après fermeture. **Vérifié capable d'échouer.**

## [5.17.4] — 2026-08-27
### Quatre écrans qui affirmaient du faux

Quatre retours d'usage sans rapport entre eux, sauf un : aucun ne plante, et tous les quatre se
lisent comme une panne — un pied de page qui dit « sur cet appareil seulement » alors que la
synchronisation tourne, une décision qui ne montre qu'une de ses deux branches, un bouton grisé
qui invoque la mauvaise cause, un dialogue où la première frappe d'Entrée annule au lieu de valider.

- **Le pied de page suit enfin la connexion, sans recharger** (signalé : « lorsqu'on se connecte,
  “sur cet appareil seulement” en bas de la page s'affiche toujours jusqu'à ce qu'on recharge »).
  L'état de stockage est calculé à partir d'un instantané MESURÉ (`navigator.storage.estimate`,
  asynchrone), et la présence d'un compte y était figée au moment de la mesure — laquelle n'est
  rejouée ni à la reconnexion au MÊME compte, ni à la déconnexion depuis une vue de lecture. Le
  pied continuait donc d'annoncer « copie unique · non protégé » à quelqu'un dont les fiches
  partaient déjà dans le cloud : l'inverse exact de la vérité, sur la seule ligne de l'écran qui
  répond à « suis-je à l'abri ? ». La présence d'un compte se relit désormais **à la peinture**,
  comme l'état réseau le fait déjà — deux libellés réécrits, aucune mesure relancée. Règle
  générale : dans un instantané mesuré, un champ qui peut changer SANS nouvelle mesure n'a rien à
  y faire.
- **Une décision montre toutes ses branches, même celles qui n'ont pas de bloc** (signalé : « le
  parcours s'affiche mal pour les blocs conditionnels : uniquement certains s'affichent »). Quand
  une option mène directement au point de convergence — le cas le plus ordinaire qui soit, « oui →
  on continue, non → détour » —, elle n'a aucune rangée à elle et son étiquette était effacée :
  sur l'aide d'exemple « Accouchement inopiné », la décision « Imminence » affichait
  « NON — TRANSPORT » et **rien** pour « OUI — SUR PLACE ». Une décision à deux issues qui n'en
  montre qu'une ne se lit pas comme un raccourci, elle se lit comme un rendu à moitié fait — et
  dans une colonne d'ORIENTATION, une branche cachée est une branche qu'on ne saura pas prendre.
  Le parcours écrit maintenant l'étiquette **et** dit où la branche mène (« → 4 Suite commune »,
  « ↺ 2 », « ▪ fin »). Ce n'est pas une grammaire nouvelle : la vue « Parcours » de « Tout voir »
  le faisait déjà — les deux vues divergeaient en silence, et c'est la plus consultée qui avait
  tort. Le renvoi reste inerte : le saut tapable vit sur la rangée de la décision juste au-dessus.
- **« En ligne » grisé dit désormais POURQUOI, et répond au tap** (signalé : « avec le mode direct
  on peut partager sans compte ; mais quand on clique sur “En ligne”, grisé, on ne sait pas
  pourquoi ça ne fonctionne pas »). Deux défauts, et le second explique le premier. (1) La légende
  ne connaissait qu'une cause — « “En ligne” reviendra avec internet » — alors que le cran est
  fermé pour deux raisons distinctes : pas d'internet, ou pas de compte. Sans compte, attendre le
  réseau n'apportera jamais rien : la phrase était fausse au moment où elle comptait, et le bandeau
  de la feuille d'appariement faisait la même erreur. (2) L'attribut `disabled` n'émet AUCUN
  évènement : le seul geste qu'on fait pour comprendre ne produisait littéralement rien. Le cran
  garde son apparence de fermé et reste annoncé fermé aux lecteurs d'écran, mais il **répond** — il
  dit la cause, puis les deux chemins qui marchent : « En direct » relie les appareils par un code
  à scanner sans serveur (un Wi-Fi commun suffit, même sans internet), « Par l'écran » passe la
  session en codes filmés à la caméra, sans aucun réseau. Cette seconde moitié s'affiche aussi pour
  qui EST connecté — c'était la demande.
- **Les fenêtres de dialogue se conduisent au clavier** (demandé : « tab pour passer d'annuler au
  bouton d'action, entrée pour valider ; implémentation système native, reste simple »). Le piège
  Tab, Échap et l'activation par Entrée existaient déjà — les deux derniers sont le comportement
  natif d'un bouton. Le trou était le focus d'OUVERTURE, posé sur la croix de fermeture : la
  première frappe d'Entrée fermait la fenêtre, et l'on n'atteignait « Confirmer » qu'après deux
  Tab. Le focus va maintenant sur **l'action** quand elle est ordinaire, et sur **« Annuler »**
  quand elle est destructrice ou encore fermée par une case à cocher — convention système, et un
  Entrée réflexe ne doit jamais supprimer une fiche ni arrêter une session. Entrée valide aussi
  depuis la case à cocher ou le corps de la fenêtre, jamais par-dessus un contrôle qui a son propre
  sens d'Entrée, et jamais sur un bouton fermé. Rien n'a été réécrit en `<dialog>` natif : la
  migration toucherait les 22 fenêtres pour un gain nul sur ce qui était demandé.

**Doctrine** : `docs/decisions/lot-v5-17.md`, entrées **A233 à A236**.
**Témoin** : `audit-doctrine.mjs`, section « Parcours inerte · une décision montre TOUTES ses
branches » — l'invariant est indépendant du dessin (le nombre d'étiquettes de branche vaut le
nombre d'options), et il est **vérifié capable d'échouer** (défaut réintroduit : 1 étiquette pour
2 options ; `index.html` restauré à l'octet). Les trois autres correctifs ont été mesurés par une
sonde jetable, verte sur les DEUX moteurs.
**Portes** : `npm run check` (21 contrôles) · `npm test` **1169 tests × 2 moteurs** ·
`npm run audit` **21 harnais, 26/26 tâches vertes**.

## [5.17.3] — 2026-08-26
### L'application ne s'ouvrait plus sur iPhone — et l'hébergement gagne ses en-têtes

- **⚠ CORRECTIF CRITIQUE, signalé à l'usage** : « Safari ne peut pas ouvrir la page — *Response
  served by service worker has redirections* ». L'application ne démarrait **pas du tout** sur
  iPhone. Pour un logiciel qu'on ouvre en urgence vitale, c'est le pire mode de défaillance
  possible.
- **La chaîne, mesurée de bout en bout.** Une requête de navigation a le mode de redirection
  `"manual"` : lui servir depuis le cache une réponse dont le drapeau `redirected` est vrai est
  une **erreur réseau**, pas une dégradation. Or le nouvel hébergeur normalise les URL et redirige
  `/index.html` vers `/` en 307 ; `fetch` suivait la redirection, la réponse obtenue portait
  `redirected: true`, et `addAll` la rangeait telle quelle à l'installation. La première
  navigation servie depuis ce cache était alors refusée.
- **Pourquoi personne ne l'avait vu : WebKit refuse, Chromium tolère.** Le défaut était donc
  **invisible sur la machine de développement** et fatal sur la cible principale déclarée du
  projet. Il avait même été repéré et mesuré la veille — sur Chromium — puis jugé « fenêtre de
  risque étroite ». Le jugement était faux parce que la mesure ne portait que sur un moteur.
- **Le correctif est dans `sw.js`, pas dans un réglage d'hébergeur**, et c'est délibéré :
  neutraliser la redirection côté Cloudflare (`html_handling: "none"`) supprimerait aussi le
  service de `/` — on échangerait un défaut contre une racine morte — et l'application doit
  **rester déployable ailleurs** (règle 13), où un autre hébergeur normaliserait autrement.
  Trois lignes de défense : l'installation **demande `./`** (la forme qu'aucun hébergeur ne
  redirige) tout en écrivant sous la clé `./index.html` ; `putDoc` **reconstruit** toute réponse
  redirigée avant de la ranger ; et le repli de navigation **refuse de servir** une entrée
  redirigée qu'un worker antérieur aurait laissée, retombant sur le réseau — dégradé, jamais mort.
- **La propriété tout-ou-rien du noyau est conservée** sans `addAll` : ou le document et le
  manifeste entrent tous les deux, ou l'installation échoue. Elle n'a jamais été étendue aux
  icônes, qui feraient échouer l'installation entière pour un favicon en 404.
- **Un vingt-et-unième harnais, parce que rien ne mesurait ce terrain** : `audit-sw.mjs`. Le
  hors-ligne est la fonction dont tout dépend en intervention, et `check-sw.mjs` n'en voyait que
  le **statique** (entrées présentes, noyau ⊆ ASSETS, `CACHE` aligné). Le nouveau harnais monte
  **deux serveurs** — l'un qui redirige `/index.html`, l'autre qui sert à plat — et joue les mêmes
  six contrôles sur chacun : le worker s'installe et remplit son cache, le noyau y est, **le
  document n'est pas une réponse redirigée**, c'est bien l'application, une navigation servie par
  le worker aboutit, la page est contrôlée. **12/12 sur Chromium ET sur WebKit.** Vérifié capable
  d'échouer : défaut réintroduit → rouge sur le cas qui redirige, **vert sur le cas à plat** (il
  discrimine le défaut, il ne signale pas « quelque chose ») ; `sw.js` restauré à l'octet,
  empreinte sha256 comparée.
- **Deux pièges de MESURE attrapés en écrivant ce harnais**, tous deux capables de fabriquer un
  faux rouge : (a) `page.waitForFunction` avec un prédicat **`async`** reçoit une **Promesse**,
  toujours vraie — l'attente réussissait au premier sondage sans rien vérifier, et la sonde lisait
  ensuite un cache pas encore écrit ; l'attente est désormais pilotée depuis Node, où le `await`
  est réel. (b) Sur WebKit, `Cache.match('./index.html')` **ne retrouve pas** une entrée pourtant
  présente — vérifié en dumpant `cache.keys()` : elle y est, sous son URL absolue. Les deux sont
  consignés sur place.

### L'hébergement passe sur Cloudflare — `_headers` cesse d'être décoratif

- **Toute la posture de sécurité est désormais SERVIE**, et mesurée sur le domaine : CSP en
  en-tête HTTP (en plus de la balise), `Strict-Transport-Security`, `X-Content-Type-Options`,
  `X-Frame-Options`, COOP, CORP, `Permissions-Policy` à 21 capacités, `Referrer-Policy`, et
  `Cache-Control: no-cache` sur `/`, `/index.html` et `/sw.js`. Le fichier `_headers` était
  maintenu à jour depuis un an **en sachant que GitHub Pages l'ignorait totalement** ; il est
  enfin appliqué. Le garde anti-iframe posé dans le document en v5.0.0 passe de rempart unique à
  seconde ligne.
- **L'origine ne change pas** (le domaine était déjà en place), donc **aucune donnée locale n'a
  été touchée** — c'est précisément ce que le nom de domaine avait acheté une version plus tôt.
- **`.assetsignore`** : l'ancien pipeline Pages excluait `node_modules`, `.git` et `.DS_Store`
  d'office, Workers Assets ne le fait pas. Le premier déploiement échouait sur un `workerd` de
  145 Mio que la chaîne de déploiement avait elle-même installé dans le dépôt. Vérifié : `.git`,
  `node_modules`, `_headers` et `wrangler.jsonc` répondent tous **404**.
- **`wrangler.jsonc` ferme les deux adresses publiques que Cloudflare ouvre par défaut** —
  le sous-domaine `*.workers.dev` et une Preview URL par branche et par commit. Une case décochée
  dans le tableau de bord ne tient pas : chaque publication la recoche. Ce n'est pas cosmétique —
  chaque adresse est une **origine** de plus servant la même application, et une PWA installée
  depuis l'une d'elles aurait une bibliothèque séparée, invisible depuis l'autre, sans aucun signe.
- **Ce qui n'a pas été fait, et pourquoi** : `html_handling` n'est pas touché (cf. plus haut), et
  `tests.html` cesse de fonctionner **depuis le site déployé** — il charge l'application dans une
  iframe, que `X-Frame-Options: DENY` interdit désormais. Sans effet sur `npm test`, qui tourne
  contre un serveur local ; c'est le durcissement qui fait son travail, pas une régression.

## [5.17.2] — 2026-08-26
### L'application a son propre nom de domaine

- **Ce qui change pour vous** : l'adresse. L'ancienne
  (`vgasque.github.io/aides-cognitives-checklist/`) redirige définitivement vers la nouvelle —
  rien à faire, sinon **réinstaller l'app** depuis la nouvelle adresse et **supprimer l'ancienne
  icône** de l'écran d'accueil.
- ⚠ **Les données sont stockées PAR ORIGINE, et l'origine vient de changer.** IndexedDB (fiches,
  sessions, documents joints), les préférences et le cache hors ligne appartiennent à l'adresse
  qui les a écrits : la nouvelle adresse s'ouvre donc sur une **bibliothèque vide**. Ce qui était
  synchronisé revient à la connexion ; **ce qui était purement local doit être exporté depuis
  l'ancienne installation** (fenêtre Compte → « Exporter mes données »), qui reste ouvrable tant
  que son service worker sert son propre cache. C'est le prix d'un déménagement d'origine, il se
  paie une fois — et pas deux : l'origine nous appartient désormais, elle ne bougera plus, même
  si l'hébergeur change un jour.
- **L'hébergeur, lui, ne change pas** : toujours GitHub Pages (DNS chez OVH, `CNAME aides →
  vgasque.github.io.`, certificat Let's Encrypt automatique, HTTPS forcé). Mesuré le jour de la
  bascule : service worker **actif** sur la nouvelle origine, les quatre caches remplis
  (application, actifs immuables, pdf.js, jsQR) — donc le **hors-ligne fonctionne dès la première
  visite** —, aucune erreur console, redirection `301` de l'ancienne URL vérifiée. Les en-têtes
  que GitHub Pages ne sert pas le restent (ni HSTS, ni `nosniff`, ni `X-Frame-Options`, seul
  `Cache-Control: max-age=600`) : le tableau du § 1.1 de `docs/deploiement-et-conformite.md`
  était exact et l'est resté.
- **Aucun code n'a eu à changer, et ce n'est pas de la chance** : tous les chemins de
  `manifest.webmanifest` et de `sw.js` sont relatifs (`./`), donc le passage d'un sous-répertoire
  à la racine d'un domaine ne casse aucun actif ; `"id": "./"` se résout sur l'origine et n'a
  surtout pas été touché (porte à sens unique) ; et la connexion Supabase se fait par **code à
  6 chiffres**, pas par lien de retour — il n'y avait donc aucune liste blanche de redirection à
  mettre à jour.
- **Pourquoi un sous-domaine et non l'apex du domaine** : l'identité d'une PWA vaut son ORIGINE
  ENTIÈRE, d'où la règle « ne pas héberger une seconde PWA sur la même origine ». L'apex d'un nom
  personnel est exactement l'endroit où un autre site finira par vivre.
- **Les QR d'appariement s'allègent d'un cran, et le témoin reste un témoin réel**
  (`audit-qr.mjs`) : le lien de production tombe de 64 à 35 caractères, soit **une version de QR
  5 → 3** (mesuré) — moins de modules, donc une cible plus facile pour l'appareil photo d'en
  face, à taille d'écran égale. Le lien en sous-répertoire est **conservé comme cas distinct**
  plutôt que remplacé : c'est la forme de tout déploiement en sous-chemin (intranet,
  `<compte>.github.io/<dépôt>/`), et l'échanger aurait laissé la version 5 — et la marche
  v3 → v5 — sans aucun témoin.
- **Documentation** : la décision est datée et écrite dans `docs/deploiement-et-conformite.md`
  § 1.1, à côté de celle du 2026-07-27 qu'elle prolonge ; le README donne l'adresse et avertit
  que l'adresse d'un déploiement se choisit **avant** de diffuser.

## [5.17.1] — 2026-08-21
### Mode moniteur : la bande de temps tient à plusieurs minuteurs (A231-A232)

- **Signalé à l'usage** : « lorsque plusieurs minuteurs, timeline ne s'affichent plus ».
  Reproduit et mesuré — c'étaient **deux défauts pour un seul symptôme**. Toutes les
  étiquettes d'échéance vivaient au même `top` sur une ligne unique : à quatre minuteurs
  qui tournent, mesuré à 390 px, **quatre chevauchements deux à deux** et **deux étiquettes
  entièrement hors de l'écran** (bords à 408 et 438 px pour 390 disponibles). Sur un
  afficheur qu'on lit à deux mètres, une bouillie. Un minuteur seul ne montrait rien — la
  bande ne paraît qu'à partir de deux objets à relier, d'où « lorsque plusieurs minuteurs ».
- **Une échéance par rangée, sur le même axe** : deux marques alignées verticalement se
  lisent désormais comme une simultanéité, ce que la bande existe pour montrer, et la ligne
  de « maintenant » les traverse toutes. L'étiquette **bascule à gauche de sa marque** passé
  la moitié de l'axe : elle grandit toujours vers le centre, donc elle ne peut plus sortir
  de la bande — la garantie est arithmétique (18 signes ≈ 115 px contre 142 px de
  demi-bande à 320 px, le plus étroit servi), pas espérée.
- **Les tours projetés appartiennent à LEUR minuteur** : versés dans un tas commun, un tiret
  ne disait plus de qui il était le tour suivant — l'information même que la bande porte.
- **Aucun écart tu** : au-delà de ce que la hauteur permet, la bande garde les échéances les
  plus proches et **dit combien attendent derrière**.
- **Le correctif a d'abord posé son propre défaut, et le paysage l'a révélé** : la bande
  étant `flex:none` au-dessus d'un `.mon-main` qui cède, quatre rangées sur un téléphone
  **couché** recouvraient le grand chiffre de 44 px (54 px à 667×375). En portrait, rien ne
  paraissait. La place est désormais **mesurée** à chaque rendu, et le grand chiffre cède —
  parce qu'il est primaire : un chiffre recouvert ne se lit pas du tout, un chiffre plus
  petit se lit encore très bien à deux mètres (120 → 71-78 px en paysage, jamais sous 64).
- **Pourquoi aucun témoin ne l'avait vu** : `monBandData` est pure et ses onze témoins
  étaient verts — ils n'exerçaient **qu'un seul minuteur**, et aucune fonction pure ne peut
  voir que quatre étiquettes se peignent au même endroit. Le défaut était **géométrique**.
  Deux témoins de pluralité rejoignent `tests.html`, et un harnais mesure désormais la
  chose elle-même : `audit-doctrine.mjs`, deux jeux de minuteurs × quatre géométries dont
  **deux en paysage** (aucun chevauchement, rien hors champ, la bande ne recouvre pas le
  chiffre, plancher de 64 px tenu, tours projetés tous rattachés, écart compté à l'écran).
  Vérifié capable d'échouer, `index.html` restauré à l'octet.
- Trois erreurs de mesure attrapées en chemin et consignées, parce que chacune rendait un
  calcul juste en apparence : le `scrollHeight` d'un conteneur **étiré** vaut sa boîte et
  non son contenu ; `clientHeight` **comprend le rembourrage** (qui porte ici les marges
  matérielles) ; un minuteur **échu** ajoute une troisième ligne à réserver. Doctrine :
  `docs/decisions/lot-v5-17.md` (A231-A232).

## [5.17.0] — 2026-08-21
### La barre de sélection tient sur une ligne (planche 20, A227-A230)

- **Une ligne, 56 px, à tout écran et dans tout état** — contre ~100 px sur téléphone.
  Le défaut n'était pas la largeur : la barre est **collante**, donc ses deux étages
  restaient à l'écran pendant tout le défilement, sur le seul axe qui manque sur
  téléphone. Et cette hauteur était payée pour rien — à l'ouverture, **quatre commandes
  sur six étaient mortes**. Le contenu est repris ; la coque (place collante, matière,
  périmètre) ne bouge pas. Le contenu remonte de 44 px, et il n'existe plus d'état où la
  barre grandit sous le doigt.
- **Les actes passent dans un tiroir** : « Actions » ouvre la feuille que « Bibliothèque… »
  et « Catégorie… » ouvraient déjà. Un tap de plus, une rangée de moins. **Rien de coché,
  rien de mort** : la touche d'actes n'est pas grisée, elle n'existe pas — la barre est
  alors trois objets sur une ligne courte. Les trois actes sont écrits **une seule fois** ;
  la feuille les rejoue, elle ne les duplique pas.
- **Les libellés disent ce qu'ils déclenchent** : « Tout » → **« Tout cocher »**, « Aucun »
  → **« Tout décocher »** (un adjectif seul n'annonce rien, et « Aucun » se lisait d'abord
  comme un compte) ; « Déplacer… » et « Ranger… » nomment désormais leur **destination** —
  **« Bibliothèque… »**, **« Catégorie… »** —, la phrase entière étant reprise dans la
  feuille et en nom accessible. Les infobulles longues disparaissent : un intitulé qui se
  suffit ne se double pas d'une infobulle.
- **Le compte porte l'état, et il ne se fait plus rogner.** Il est le seul élément
  élastique de la ligne ; c'est aussi lui qui dit pourquoi « Catégorie… » est fermée
  (« 3 cochés · deux bibliothèques ») — un `title` n'existe pas au doigt. Mesuré avant
  correctif : réduit à 47 px pour 58 nécessaires à 390 px, à zéro à 320 px. Sous 430 px la
  barre se comprime (écarts, rembourrages) ; sous 400 px le segment rejoint le tiroir —
  sauf à zéro coché, où il est la seule commande et où il n'y a pas de tiroir.
- **Le palier de dépliage est à 1200 px, pas à 560 comme l'annonçait la planche** — corrigé
  **à la mesure**, avec deux raisons : la barre dépliée réclame **757 px de largeur utile**
  (les intitulés entiers y sont pour beaucoup) et à 560 px elle n'en a que 514, d'où un
  débordement de 179 px ; et la largeur de la barre **n'est pas monotone** en largeur de
  fenêtre — à 780 px la colonne de gauche lui prend 224 px d'un coup (698 → 474 px mesurés).
  Le seuil passe par `html.zw1200`, jamais par une media query (règle 10 : une media query
  mesure le périphérique, pas la place disponible). Conséquence assumée : sur tablette et
  sur beaucoup de portables, la feuille est le régime normal.
- **Correctif de fond découvert au passage** : `syncZoomWidth()` ne se posait **qu'au
  rendu**. Une rotation, une fenêtre tirée, un clavier qui s'ouvre ne re-rendent rien — les
  paliers de largeur restaient donc ceux de la largeur précédente, indéfiniment sur un écran
  qu'on ne quitte pas. Elle se repose désormais au redimensionnement et à la rotation.
- **Accessibilité** : cibles remontées de 32 à **40 px** et corps de 11 à 13,5 px (les deux
  planchers de la règle 9 étaient abaissés ici, sur des commandes dont l'une est
  destructrice) ; le filet de « Supprimer… » passe à `--ctl-line` — `--critical-line` est un
  rose pâle à 1,4:1 qui ne tient pas 1.4.11 — le rouge restant dans l'encre et le fond
  (mesuré après correctif : filet 3,41:1 en clair, 3,33:1 en sombre) ; la croix garde son
  nom accessible entier, c'est le libellé visible qui se replie.
- **Témoin** : `audit-doctrine.mjs` mesure à 320, 390, 560, 744, 1200 et 1280 px, à zéro
  comme à plusieurs cochés — hauteur exacte, débordement nul, **un seul rang**, compte non
  tronqué, cibles ≥ 40 px, et le palier réellement franchi. Vérifié capable d'échouer : il a
  lui-même trouvé un piège de cascade (`.btn.sm{min-height:38px}`, déclarée plus bas à
  spécificité égale — 38 px mesurés là où 40 étaient écrits). Doctrine :
  `docs/decisions/lot-v5-17.md`.

## [5.16.1] — 2026-08-20
### L'invitation au dépôt parle au pluriel (addendum A225)

- **« Déposez UN PDF ou UNE image ici » se lisait comme une limite** (re-signalé après la
  v5.16.0 : « quand je drag plusieurs PDF, ça me montre "déposer un fichier ou une image" et
  un seul s'affiche ») : le singulier de la table `UP_KINDS` — écrit pour NOMMER une nature —
  servait aussi d'invitation. La fenêtre de dépôt dit désormais « Déposez **vos** PDF ou
  **vos** images ici », son sous-titre et celui des zones ajoutent « **plusieurs fichiers à
  la fois** » ; le refus, lui, garde le singulier — il désigne UN fichier fautif. Nouveau
  champ `pl` dans la table (l'invitation et le refus ne partagent plus le même mot).
- **La troncature elle-même n'a pas été reproduite** : trois sondes (sélecteur multiple, drop
  DOM, drop CDP à vrais fichiers — éditeurs de fiche ET de protocole) entrent tous les
  fichiers, comme depuis la v5.0.0. Causes résiduelles côté poste, notées dans la doctrine :
  drag depuis la barre de téléchargements ou une pile macOS (UN seul fichier porté), PDF
  > 15 Mo refusé (message de 8 s, ratable), service worker servant encore l'ancienne version.
  Addendum : `docs/decisions/lot-v5-16.md` (A225).

## [5.16.0] — 2026-08-20
### Plusieurs fichiers d'un geste, des QR lisibles de plus loin (A225-A226)

- **Importer plusieurs `.json`/`.zip` d'un seul geste** (demandé à l'usage) : le sélecteur
  comme le glisser-déposer acceptent désormais plusieurs fichiers de données, traités **en
  file** — un atelier après l'autre, jamais deux superposés, chaque atelier **nommant son
  fichier** (« nom.json » — fichier 1/3). Les questions de destination, fusion et doublons
  restent posées PAR import (l'argument de l'ancienne règle « un seul fichier », conservé
  tel quel) ; annuler un atelier n'abandonne que son fichier, les suivants se présentent
  quand même. Les refus nomment aussi leur fichier — indispensable au milieu d'une file.
  Sous le capot, `readImportFile` rend une promesse tenue à la FIN du parcours complet, et
  une erreur de lecture ne gèle plus la file (`FileReader.onerror` traité).
  Les images et les PDF, eux, acceptaient déjà le geste multiple partout (porte unique
  v5.0.0) — rien n'a changé de ce côté.
- **Tous les QR grandissent d'un cran** (demandé à l'usage : « lisibles de plus loin ») —
  la marge au-dessus du seuil de scan s'encaisse en distance et en tolérance d'angle :
  240 px en fenêtre d'appariement (56vw plafonné ; le palier < 360 px ne bouge pas, c'est
  le cas mesuré de v4.47.0 où « Arrêter le partage » passait sous la ligne de flottaison),
  et **260 px** pour les QR qui se scannent d'écran à écran (appariement direct, synchro
  optique, réponse de l'invité, aller-retour). Au passage, `audit-partage` a attrapé un
  conflit de spécificité jusque-là invisible (la règle `#shareBody` battait le plafond de
  la carte d'appariement — les deux disaient 200, le conflit ne se voyait pas) : la règle
  de la carte est scopée `#shareModal`, et le témoin « plafonné à 240 px » reste MESURÉ.
- **Vérifié** : sonde deux moteurs (sélecteur multiple, deux ateliers en file nommés,
  annulation sans cascade), `audit-qr` 9/9 (décodage réel des captures), passe d'audit
  complète 25/25 verte. Doctrine : `docs/decisions/lot-v5-16.md` (A225-A226).

## [5.15.0] — 2026-08-20
### Les barres flottantes deviennent lisibles — planches Claude Design 17 et 18 (A222-A224)

- **La nuit, la capsule et le dock se voient enfin** (planche 17, direction 1a) : la matière
  système ne tenait que 1,09:1 contre le fond sombre — les trois matières n'en faisaient
  qu'une. Elle MONTE (`#171a20` → `#333b47`) : le jour la plus sombre, la nuit la plus
  claire — dans les deux cas la plus éloignée des deux autres. Un périmètre `--sys-edge`
  (5,3:1, ombre interne de 1 px, le patron de la pastille Compte) borde carte de session,
  quai, volet et capsule ; ≥ 1200 px la capsule quitte la matière et n'est pas cerclée.
- **Ce que l'éclaircissement obligeait à déplacer, déplacé** : le creux de la touche ⏱ passe
  au token `--sys-key` (.10 jour / .14 nuit), le filet ambre de l'alarme passe à `--alarm-bd`
  (`--warn-line` le jour, `--warn-sys` la nuit — il tombait à 2,25:1), et la touche ⚡ ouverte
  prend `--sys-hi` (attrapé par `audit-a11y` : l'encre rouge tombait à 3,9:1 sur le creux
  générique). Nouveau token `--ctl-sys` : la limite d'un CONTRÔLE posé sur matière système
  tient 3:1 dans les deux thèmes (« Terminer », chips et champ du volet, touche Exercice) —
  les séparateurs gardent `--sys-line`, un séparateur n'est pas une cible.
- **Le jour, le quai projette** (planche 18/P) : son ombre vivait en dur (noir pur, aveugle au
  thème) et 6 px à 6 % ne se voyaient pas sous un tableau de posologies qui touche la barre
  (colonne 358 px, quai 362). Elle passe au token `--shadow-up`, élargie 12 px / 32 px / 26 %,
  à l'encre du thème. Aucune hauteur ne bouge. Deux pistes essayées et écartées, notées dans
  la doctrine : fondu vers l'ambiance (1,06:1, invisible), bande de flou (halo noir dans les
  coins arrondis).
- **« Démarrer la session » se détache de sa barre** (planche 18/2a) : `--act` ne tenait que
  1,68:1 contre le quai — la forme du bouton se confondait avec lui (le défaut de
  « Reprendre » v5.10.0, jamais rejoué sur le geste d'entrée). Nouveau registre
  `--act-sys:#7ab3f0` (7,2:1 clair, 5,1:1 sombre), encre `--on-sys-fill` ; libellé au corps de
  l'acte (17,5 px) sans changer le gabarit ; sous 430 px effectifs « Exercice » passe au
  glyphe seul (classe `zw430`, règle 10 — cible 44 px et `aria-label` conservés) et le geste
  gagne 62 px de piste. Le coût, nommé : le bleu du quai n'est plus le bleu de la page — déjà
  le régime des trois autres registres.
- **Témoins** : nouvelle section doctrine « QUAI · le geste d'entrée se détache de sa barre »
  (aplat ≥ 3:1 deux thèmes, périmètre nocturne ≥ 3:1, ombre montante le jour, cible du glyphe
  seul), vérifiée capable d'échouer, défaut réintroduit puis fichier restauré à l'octet.
  Doctrine complète : `docs/decisions/lot-v5-15.md` (A222-A224).

## [5.14.22] — 2026-08-19
### La file voyage avec l'invité — et le partage meurt avec sa session

- **Plus aucune action perdue à la bascule** (signalé) : ce qui n'avait pas encore été
  transmis au moment d'un passage en ligne ⇄ en direct voyageait à la poubelle — la file de
  l'invité est désormais emportée et re-poussée après la jointure (témoin de bout en bout :
  panne d'écriture, bascule, l'évènement atteint l'hôte).
- **Terminer la session termine son partage** (signalé : « l'invité se reconnecte sur
  l'ancienne session ») : le partage zombie survivait des heures et le billet de reprise de
  l'invité le ressuscitait — vieux gestes et « reprise après interruption » compris. Les
  invités lisent désormais « Le soignant a terminé la session ».
- **Sans aucun réseau, « Par l'écran » est proposé sur place** (signalé) — le direct ne peut
  pas aboutir sans Wi-Fi commun, le chemin qui marche est à un tap.
- **Après la veille, les mots justes** (signalé) : un invité perdu → « Ré-apparier — nouveau
  code » (fini le « Inviter un autre » qui faisait bizarre), et l'hôte est prévenu au réveil
  que le lien direct n'a pas survécu. En ligne, la reconnexion était déjà automatique ; en
  direct, un re-scan reste physiquement nécessaire.
- **« Renvoyer mes repères » explique le zéro** (signalé) : les coches ne remontent jamais
  par l'écran — seuls les repères datés annotent le journal de l'hôte ; le message le dit et
  donne le geste.

## [5.14.21] — 2026-08-19
### La pastille « En ligne » s'allume vraiment — le serveur refusait la question, pas la réponse

- **Corrigé pour de bon** (signalé : « en 5.14.19 elle ne s'allumait pas ») : la sonde de
  joignabilité interrogeait le serveur d'une manière qu'il refuse par principe (HEAD → 405),
  et ce refus était lu « injoignable » — pastille grise à jamais, même avec un internet
  parfait. La sonde interroge désormais en GET, et tout statut HTTP vaut « joignable » :
  c'est la joignabilité qu'on mesure, pas la santé du service. Vérifié contre la vraie
  instance, depuis un vrai navigateur.

## [5.14.20] — 2026-08-19
### L'entrée « Partager » mesure le réseau, l'invité figé se reconnecte, le départ dit le non-transmis

- **« Partager la session » choisit son mode en MESURANT** (signalé) : serveur injoignable
  mesuré → appariement direct d'emblée ; échec d'ouverture en ligne (Wi-Fi sans internet) →
  bascule automatique vers le direct avec un mot — plus jamais « vérifiez votre connexion ».
- **Invité au lien figé** : « Se reconnecter… » au menu (scanner ou saisir un nouveau code,
  l'écran figé reste intact tant qu'on n'a pas rejoint), et le retour du réseau relance le
  sondage immédiatement. La pastille « En ligne » gagne aussi une mesure au retour au premier
  plan (iOS ne tire pas toujours l'évènement réseau en PWA).
- **Quitter le partage n'avertit que s'il y a de quoi** (demandé) : file transmise → fenêtre
  habituelle ; actions en attente → le dialogue détaille ce qui serait perdu (« 2 coches,
  1 repère, 1 minuteur… ») ; chez le miroir, les repères non renvoyés — avec le geste qui les
  sauverait.

## [5.14.19] — 2026-08-19
### La pastille « En ligne » mesure vraiment — et le chrome de crise lâche les aides propres de l'invité

- **La pastille « En ligne » verdit quand le serveur répond, et seulement alors** (signalé :
  « retrouver internet ne rend pas la pastille verte — pareil en Wi-Fi sans connexion ») :
  tant que le sélecteur de mode est à l'écran, une sonde légère interroge le serveur toutes
  les 8 secondes et repeint la pastille sur place. Un Wi-Fi sans internet ne la trompe plus,
  et le retour d'internet se voit en quelques secondes, dans tous les modes.
- **Le bandeau « Vous suivez » ne suit plus l'invité sur ses propres aides** (signalé — la
  v5.14.18 avait corrigé l'entrée, pas l'en-tête) : bandeau, mot du mode, mode crise et
  bridage du scribe ne valent plus que sur la fiche réellement suivie ; retour, aller et
  chrome vérifiés par sonde dans les deux sens.

## [5.14.18] — 2026-08-18
### Les aides propres de l'invité redeviennent normales — et l'invité relaie par l'écran

- **Consulter ses propres aides pendant un partage redevient normal** (signalé) : plus de
  coches fantômes ni de bandeau de session sur une aide non démarrée — et un invité sur SON
  appareil peut démarrer ses propres sessions (le refus ne vaut plus que sur appareil sans
  trace) ; ses sessions locales n'alimentent jamais le fil de l'hôte.
- **« Montrer à un autre écran »** (signalé : « pas de bouton pour redonner le code ») :
  l'invité — miroir ou en ligne/direct — relaie la session en fontaine optique ; l'hôte
  reconnaît la session relayée, retours compris. La feuille d'émission s'adapte au rôle.
- **Le compte de participants est juste** (signalé : « 2 participants » à un seul) : la
  feuille directe comptait l'hôte avec — elle compte désormais les invités présents, comme la
  feuille en ligne.
- **La notice du mode direct dit son prérequis** (signalé) : « même Wi-Fi requis — un réseau
  local SANS internet convient (Wi-Fi d'établissement, box coupée) ».
- **Audit de sécurité du canal direct** (question) : modèle de menace écrit au registre
  (§ 3.2) — chiffrement de bout en bout authentifié par empreinte via QR physique ou relais
  authentifié, rien n'écoute, l'admission est le canal apparié, l'optique exige d'être filmé.

## [5.14.17] — 2026-08-18
### L'invité navigue sans perdre sa session — et une aide reçue ne s'exporte pas

- **Consulter ses propres aides pendant un partage ne piège plus l'invité** (signalé) : le
  menu de partage ne suit plus l'invité partout (il ne vaut que sur la fiche partagée), et
  deux chemins de retour existent — « Revenir à la session partagée » dans le menu ⋯ de toute
  autre aide, et une carte « Session partagée » / « Miroir » à l'accueil, avec Reprendre.
  Sous le capot, naviguer DÉTRUISAIT la session reçue : l'invité en ligne se reconstruit de
  son pli, le miroir optique est garé et restauré tel quel.
- **Une aide reçue temporairement ne s'exporte pas** (signalé : « c'est voulu ? » — non) : le
  miroir optique n'ayant aucun mode de transport, l'aide reçue portait le menu complet
  (Exporter, Dupliquer, Modifier). Elle porte désormais le menu de l'invité — et la réponse à
  la question : oui, l'envoi est temporaire par construction (projection en liste blanche,
  reconstruite en mémoire, jamais écrite sur l'appareil ni le compte).

## [5.14.16] — 2026-08-18
### L'aller-retour « par l'écran » — et l'instantané optique qui partait vide

- **Synchronisation par l'écran, dans les deux sens** (demandé) : l'invité qui a reçu un
  miroir peut « Renvoyer mes repères » — l'hôte tape « Recevoir en retour », filme, et son
  journal s'annote de repères datés (jamais une coche : la sémantique de la maquette 05,
  « Continuer seul » réutilisé). L'émission reprend ensuite d'elle-même, enrichie. Même
  session reconnue automatiquement ; une fontaine d'une autre session ou d'une autre aide est
  refusée sans rien écrire ; re-scanner ne duplique rien.
- **L'instantané optique partait VIDE depuis la v5.14.0** (trouvé par le nouveau témoin) : la
  fiche voyageait, les coches, minuteurs et repères jamais — le miroir montrait une session au
  propre. Corrigé (`shareSnap(Runtime,…)`).
- **La jauge ne s'affiche que pendant une fontaine** (demandé) : un scan de code unique se
  conclut par un flash vert 120 ms + vibration, sans son ni jauge (maquette 03).
- **L'émission parle comme la maquette 04** : « le code change tout seul — restez face à
  face » + « en cours d'envoi » — fini le « bloc x/x / réparation ».

## [5.14.15] — 2026-08-18
### La feuille directe a les commandes de l'hôte, la réouverture retrouve son mode

- **« Donner la main » et « Couper » existent désormais en mode direct** (signalé) : le moteur
  local savait déjà les faire, seule la feuille ne les montrait pas — les rangées de
  participants sont maintenant communes aux deux feuilles, avec les mêmes états (relève,
  conduit, parti, sans nouvelles…).
- **La pastille « En ligne » verdit quand le retour est possible** (compte + internet),
  symétrique de « En direct » = canal dormant prêt. Vert = disponible, pilule = actif.
- **Rouvrir le partage rouvre le mode EN COURS** (signalé : « le mode direct ne se rouvre
  pas ») : le menu ouvrait la feuille cloud en dur — partage fantôme sans code ni
  participants. Direct vif → feuille directe ; miroir → miroir ; sinon → cloud.
- La ligne de diagnostic (v5.14.13) est retirée : service rendu — elle a désigné le défaut
  serveur en un aller-retour.

## [5.14.14] — 2026-08-18
### Le vrai coupable du secours chaud : le serveur amputait l'offre

- **L'appariement silencieux ne pouvait fonctionner sur AUCUN réseau** (trouvé grâce à la
  ligne de diagnostic v5.14.13 : « en attente de l'offre… » à demeure) : la liste blanche des
  CLÉS de payload de `share_push` — l'étage jumeau du vocabulaire des genres — ne connaissait
  pas les clés du secours chaud : le serveur acceptait l'évènement `sig` et le vidait de son
  offre. ⚠ **`supabase/schema.sql` est à REJOUER sur l'instance** : c'est le correctif.
- **Le banc ne peut plus mentir sur ce point** : le hub local du harnais ampute désormais les
  payloads exactement comme le serveur, et `check-sql` garde la parité des clés comme celle
  des genres (39 identiques, camelCase compris) — vérifié capable d'échouer des deux côtés.
