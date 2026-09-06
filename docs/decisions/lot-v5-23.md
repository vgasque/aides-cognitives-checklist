# Lot v5.23 — le partage sans question : un état, une détection rapide, un retour seul (A317-A325)

> Fichier normatif, suite de [`lot-v5-22.md`](lot-v5-22.md) (A308-A316). Les numéros A sont des
> adresses : ne jamais renuméroter. Demande de l'auteur (05/09/2026) : « améliorer le passage entre
> mode en ligne et mode direct, le plus autonome possible, le plus seamless possible, avec une
> transparence discrète » — six propositions acceptées, livrées en cinq étapes.

**Mesuré avant le chantier** : sondage du miroir 2 s en activité, 5 s au repos, 10 s sans crise à
l'écran ; secours direct déclenché après DEUX sondages ratés (8-11 s en activité, jusqu'à 20 s au
repos), à condition qu'un canal dormant existe ; sonde de joignabilité toutes les 8 s SEULEMENT
feuille de partage ouverte ; retour au cloud manuel ; réveil après veille : canaux morts, annonce et
geste demandé.

## A317 — un seul état visible : « ● Partagé » (v5.23.0)

Le quai disait « ● Session » en ligne et « ● Direct » en local (A208, maquette 02) : le mot du
transport, à position constante. L'auteur veut que l'utilisateur n'ait plus la question « dois-je
basculer ? » — le transport n'est pas son affaire, être partagé l'est. Le quai dit désormais
**« ● Partagé »** dès qu'un partage est actif, quel que soit le canal (budget 18 : « ● Partagé ·
⇄2 » = 14) ; les états dégradés (« figé », « coupé ») gardent leurs mots. Le canal se lit dans la
feuille de partage (sélecteur, pastilles) et aux transitions (une phrase sur place, jamais une
fenêtre — règle 11). La maquette 02 n'est pas reniée sur le fond : un mot, une position ; seul le
mot change de niveau d'abstraction.

**Garde-fou** : deux contrôles dans la section E2E « v5.14.9 · bascule en ligne⇄direct » d'
`audit-partage` (le quai dit « ● Partagé » après la bascule vers le direct, et toujours après le
retour en ligne), vérifiés CAPABLES D'ÉCHOUER (ancien libellé remis → 2 rouges, `index.html`
restauré à l'octet).

## A318 — la panne se détecte en moins de 5 s, la transition se voit, le secours se dit (v5.23.1)

**Trois défauts mesurés.** (1) Le secours n'était déclenché qu'au DEUXIÈME sondage raté, or le
second sondage attend le repli exponentiel : 4 s en activité, jusqu'à 20 s au repos — mesuré au
harnais, 5 230 ms entre la panne et la bascule. (2) `announce()` n'écrit que dans la zone
`aria-live` : les transitions ne parlaient QU'AUX LECTEURS D'ÉCRAN, et depuis A317 le quai ne
disait plus le canal — visuellement, plus rien ne signalait une bascule. (3) Le secours chaud se
formait en silence : l'utilisateur ne savait pas, avant la coupure, si la bascule serait
silencieuse ou demanderait un QR.

**Ce qui change.** (1) `slSbFail` : au premier raté, la sonde de joignabilité (garde 3,5 s)
tranche — si le serveur ne répond pas, la bascule part sans attendre le second sondage ; et
l'évènement `offline` du système tranche aussitôt. Mesuré au harnais : < 2,5 s (le seuil du témoin),
contre 5,2 s avant. (2) `slSay(mot, phrase)` — UNE porte pour toute transition : un mot au quai
pendant 8 s, lu au tick par `updateRtStrip` (« ● Passe en direct », « ● Suivi en direct »,
« ● Repasse en ligne », « ● Secours prêt », tous ≤ 18 caractères), et la phrase au lecteur d'écran ;
les quatre annonces éparses passent par elle (aucun doublon). Aucune fenêtre, aucun toast (règle
11) : le mot vit là où l'état vit déjà. (3) `slSbReadySay` : « Secours prêt » dit UNE fois par
formation du canal dormant, hôte et invité ; le drapeau se remet à zéro avec les canaux.

**Ce qui n'a pas changé** : le pré-appariement se retente déjà à chaque sondage sain une fois la
montre de 30 s écoulée (A209) — la proposition « retenter toutes les 30 s » était déjà vraie, rien
à ajouter.

**Garde-fous** (section E2E des bascules, `audit-partage`, 15 → 19 contrôles) : « Secours prêt »
dit des deux côtés ; « ● Passe en direct » puis « ● Partagé » ; « ● Repasse en ligne » ; bascule en
moins de 2,5 s après la panne brutale (sonde stubée à « injoignable ») — vérifié CAPABLE D'ÉCHOUER
(chemin rapide retiré → 5 230 ms, rouge ; `index.html` restauré à l'octet).

## A319 — le retour en ligne se fait seul après une panne, avec hystérésis (v5.23.2)

**Avant** : le sens panne était automatique (A209), le sens retour un tap — « le sens confort est
un choix ». L'auteur veut que l'utilisateur n'ait pas à y penser ; la conformité (§ 3.2) dit le
nouveau régime AVANT le code, comme la règle 12 l'exige pour tout ce qui change ce qui sort de
l'appareil (ici : rien de nouveau, le même billet `gc` par le même canal chiffré).

**Ce qui change.** La bascule DE PANNE arme le retour (`slSb.auto`) ; le geste manuel « En
direct » le désarme — un choix explicite n'est jamais contredit. Tant que le retour est armé, la
sonde de joignabilité tourne aussi feuille FERMÉE (`slNetWatch` n'a plus une condition d'arrêt mais
deux raisons de vivre, aucune boucle dupliquée) et décide (`slBackTick`) : trois sondes consécutives
OK, au moins 60 s passées en direct, des invités à ramener, aucune bascule en cours → `slGoCloud`
par le chemin du tap, en mode DISCRET (la feuille ne s'ouvre pas : règle 11), avec le mot
« ● Repasse en ligne » et la phrase « Internet est revenu ». Le retour désarme (pas de boucle) ; un
échec du retour laisse le direct en place (`slGoCloud` re-héberge sur le même hub, inchangé).
Bancs : `__acBackDwell` et `__acProbeMs` raccourcissent hystérésis et cadence, comme `__acNetOk`.

**Garde-fous** (section E2E des bascules, 19 → 23 contrôles) : la panne ARME le retour ; réseau
revenu, l'hôte repasse en ligne TOUT SEUL et l'invité suit par le billet « gc » ; le retour DÉSARME —
vérifiés CAPABLES D'ÉCHOUER (armement retiré → 3 rouges, `index.html` restauré à l'octet).

## A320 — au réveil, l'hôte revient seul en ligne si le retour est armé (v5.23.3)

**Avant** (v5.14.22) : la veille tue les canaux WebRTC ; au réveil l'app annonçait « ré-appariez
depuis la feuille » — un geste demandé, et seulement au lecteur d'écran.

**Ce qui change.** Le corps du gestionnaire `visibilitychange` devient `slWake()` : un hôte en direct
dont des participants sont perdus (`shareSeenLost`) et dont le retour est ARMÉ (bascule de panne,
A319) sonde le serveur ; s'il répond, `slGoCloud` discret AUSSITÔT — sans hystérésis, un lien mort
n'a rien à préserver. Sinon (mode direct choisi, ou serveur muet), le mot « ● Lien à refaire » au
quai et la phrase au lecteur d'écran, par `slSay`. Limite écrite : un invité dont le canal est mort
ne peut pas suivre le billet `gc` — il re-rentre par le geste d'A212 ; le QR reste le dernier
recours, réservé au cas sans serveur ni canal.

**Garde-fous** (section E2E des bascules, 23 → 25 contrôles) : seconde panne → les deux repassent en
direct (secours re-formé après le retour d'A319) ; participants « perdus » (prédicat stubé), serveur
revenu, hystérésis rendue inatteignable → `slWake()` ramène l'hôte en ligne seul. ⚠ Première
écriture NON discriminante : le veilleur d'A319 ramenait l'hôte de toute façon (dwell raccourci au
banc) — c'est en rendant l'hystérésis inatteignable que le témoin mesure le réveil et lui seul ;
vérifié CAPABLE D'ÉCHOUER (branche de retour retirée → rouge, `index.html` restauré à l'octet).

## A321 — le journal du lien : les cinq dernières transitions, sur demande (v5.23.4)

**Ce qui change.** `slSay` — déjà la porte unique des transitions (A318) — retient aussi chaque mot
horodaté dans `slSb.log` (cinq au plus, en mémoire seulement : le journal meurt avec la session,
rien ne sort de l'appareil). `slLogHtml()` le rend dans les deux feuilles de partage, en ligne et
en direct, sous le sélecteur : une liste sobre « 14:02 Passe en direct · 14:05 Repasse en ligne ».
C'est la transparence discrète demandée : rien n'interrompt, tout se retrouve d'un tap sur
« Partager ». Une seule source (le même appel qui parle au quai et au lecteur d'écran) — aucune
transition ne peut être dite sans être journalisée, ni l'inverse.

**Garde-fous** (section E2E des bascules, 25 → 27 contrôles) : le journal retient « Passe en
direct » et « Repasse en ligne » (≤ 5 entrées) ; la feuille en montre autant de lignes ; vérifiés
CAPABLES D'ÉCHOUER (écriture retirée → rouge, `index.html` restauré à l'octet).

**Bilan du lot** (mesuré au harnais, E2E réel à deux pages) : détection de panne 5,2 s → < 2,5 s ;
retour en ligne manuel → automatique sous hystérésis ; réveil : geste demandé → retour seul ; un seul
état visible ; chaque transition vue au quai 8 s et lue dans le journal. Le partage reste un miroir
ADDITIF (règle 15) : aucune de ces mesures n'attend le réseau sur un tap ou un rendu.

## A322 — le réseau de terrain : Wi-Fi instable, chute totale, portail captif, serveur en erreur (v5.23.5)

**Demande de l'auteur** (06/09/2026) : « vérifie que ça tienne si la connexion Wi-Fi est instable,
se déconnecte, repasse sur une page de connexion portail ; et quelles autres situations similaires
pourraient bloquer en situation critique ? Teste-les. »

**Ce que la mesure a trouvé avant correction.** (1) **Chute totale du Wi-Fi** (cloud ET canal
direct perdus, puis retour) : l'hôte revenait en ligne sur un partage NEUF, le billet `gc` partait
sur des canaux morts, l'invité restait en direct sur un canal mort — geste obligatoire des deux
côtés. (2) **Serveur en erreur au retour** (internet revenu, Supabase en 5xx ou maintenance) : la
tentative de retour échouait et DÉSARMAIT le retour automatique — plus aucune tentative ensuite. (3)
**Battement** (Wi-Fi qui hoquette) : détection agressive (A318) sans garde côté panne, hystérésis
fixe côté retour — une oscillation à chaque hoquet.

**Ce qui change.**
- **Reprise du MÊME partage cloud.** À la bascule de panne, l'hôte garde son billet cloud (id, code,
  curseur) et l'invité le sien (id, secret). Au retour, `Share.rehost` reprend le partage existant
  (aucun `open` : mêmes secrets, rien à re-saisir), pousse au journal cloud les gestes faits pendant
  le direct (le hub local ne contient QUE ceux-là ; dédoublonnage par identifiant d'évènement), puis
  dit `rc` aux invités encore sur le canal direct. Un invité au canal MORT reprend SEUL
  (`slResumeCloud`, par le billet de reprise existant) dès que la sonde dit le serveur joignable —
  sans code, sans geste. Un billet ne se consomme qu'à la réussite ; un échec restaure le transport
  qui marchait (jamais de demi-état). Le partage neuf + `gc` reste le repli si le partage cloud a
  expiré ou a été purgé.
- **Le retour reste armé tant qu'il n'a pas abouti** : `slGoCloud` rend vrai ou faux ; un échec
  remet le compteur de sondes et garde l'armement (test (c) : serveur en erreur puis rétabli → le
  retour aboutit, l'invité suit).
- **Garde anti-battement** : l'hystérésis double à chaque retour automatique (60 s → 120 → … ≤ 10
  min) et se relâche après 10 min de calme ; l'évènement `offline` attend 1,5 s avant de trancher.
- **Portail captif** : aucune ligne à changer, mesuré au raisonnement du contrat — le portail
  intercepte l'HTTPS de la sonde (erreur TLS/CORS → `fetch` rejette → « injoignable ») et les
  sondages du miroir (JSON illisible → échec) ; l'isolation client-à-client des portails tue aussi
  le canal direct : c'est le cas « chute totale », couvert. L'écran de connexion du portail, lui,
  n'est pas l'affaire de l'app.

**Carte des situations de terrain** (E2E réel, deux pages, section « v5.14.9 · bascule »,
27 → 36 contrôles) :

| Situation | Comportement | Témoin |
|---|---|---|
| Relais mort, canal direct vivant | direct en < 2,5 s, retour seul (A318-A319) | oui |
| Chute totale puis retour | même partage repris des deux côtés, gestes du direct au journal | oui |
| Panne SANS canal dormant (invité sur un autre réseau, Wi-Fi isolé) | pas de bascule ; le cloud reprend seul au retour | oui |
| Serveur en erreur au retour | direct maintenu, retour toujours armé, aboutit ensuite | oui |
| Réveil après veille | A320 | oui |
| Wi-Fi qui hoquette | détection 1,5 s côté `offline`, hystérésis doublée côté retour | mécanisme mesuré (dwell doublé), pas de scénario chronométré — non déterministe au banc |
| Portail captif | = chute totale (contrat de la sonde) | par construction, non simulé |
| Bascule Wi-Fi ↔ 4G d'un appareil | = canal mort + serveur joignable (reprise seule) | couvert par « chute totale » |
| Partage cloud expiré pendant une longue panne | repli partage neuf + `gc` | chemin d'A210, non rejoué ici |
| Rechargement de l'HÔTE pendant un partage direct | le hub meurt avec l'onglet — limite connue, hors lot | non |

**Garde-fous** : 9 contrôles ajoutés ; vérifiés CAPABLES D'ÉCHOUER (reprise du même partage et
reprise seule de l'invité retirées → 6 rouges, `index.html` restauré à l'octet). ⚠ Deux pièges de
banc : le relais du banc ne portait pas la fiche (une reprise réelle la reçoit) — corrigé dans
`io.open` ; et « en direct » chez l'invité se lit à `Share._io !== Share._ioRest`, jamais à
`share === 'local'` (marqueur de l'hôte) — c'est ce prédicat faux qui laissait l'invité sans reprise.

## A323 — l'hôte rechargé reprend son partage cloud (v5.23.6)

**Limite levée** (écrite en A322 : « rechargement de l'hôte pendant un partage direct — le hub meurt
avec l'onglet »). Le hub local et les canaux WebRTC meurent avec l'onglet, c'est une propriété du
navigateur ; ce qui peut survivre, c'est le PARTAGE CLOUD, et c'est lui que les invités savent
reprendre seuls (A322).

**Ce qui change.** L'hôte tient désormais un billet cloud en `sessionStorage` (id, code, curseur,
fiche — même arbitrage que le billet de l'invité, J224 : rien de durable, aucune donnée clinique),
écrit à `host()` et à `rehost()`, effacé à « Arrêter » et au geste manuel « En direct ». À la
reprise de session (« Reprendre » après un rechargement), `slHostRehost` sonde le serveur : s'il
répond, `Share.rehost` reprend le partage existant — et rembobine l'ÉTAT COMPLET vers le journal
cloud (`shareEmitDiff`, le hub local ayant disparu) ; les invités le retrouvent seuls. Serveur
muet : le billet attend, la sonde (`slBackTick`, seconde raison d'armement) retente à chaque
réponse. Refus définitif (expiré, purgé) : billet effacé, chemin du partage neuf. Le cas « hôte
en direct sans serveur, rechargé » reste ce qu'il est — un QR ; c'est le seul chemin sans serveur
ni canal, et il est dit dans la feuille.

**Garde-fous** (section E2E des bascules, 36 → 40 contrôles) : billet présent ; « rechargement »
simulé (Share à zéro, hub mort, billet gardé) ; serveur muet → rien ne repart, le billet attend ;
serveur revenu → l'hôte reprend SON partage sans nouvel `open`, l'invité n'a rien eu à faire —
vérifiés CAPABLES D'ÉCHOUER (reprise retirée → rouge, `index.html` restauré à l'octet). Limite du
banc écrite : un vrai `location.reload()` tuerait le relais du banc, qui vit dans la page de
l'hôte — le témoin rejoue l'ÉTAT que laisse un rechargement, pas le rechargement.

## A324 — « Lien perdu » : une source d'état, une rangée, une feuille qui dit la même chose (v5.23.7)

**Demande de l'auteur** : quand ni « en ligne » ni « direct » ne portent plus, une petite bannière
en haut — « connexion perdue, envoyer ma progression / recevoir une progression » —, peu haute, et
cohérente avec ce que dit la feuille de partage quand on la rouvre : on sait ce qui se passe et
pourquoi. Et la seconde limite d'A322 : un partage cloud expiré pendant une longue coupure.

**Une source.** `slLink()` rend `{lost, why, since}` pour les deux rôles : « perdu » = plus aucun
transport ne porte ET rien n'est en train de reprendre (pas de canal dormant, serveur injoignable
à la sonde) ; chez l'hôte en direct, après 15 s de bascule et 45 s sans signe d'aucun invité
(`SHARE_SEEN_QUIET_MS`) ; « expiré » = le partage cloud a été REFUSÉ pendant la coupure (un refus
`ok:false` du serveur, distinct d'une panne, dans `slResumeCloud`). Tant que le lien est perdu, la
sonde veille (`slBackArmed` y ajoute cette raison) : c'est elle qui verra revenir le réseau, et les
mécanismes d'A319-A323 reprennent seuls.

**Une rangée.** `#linkBar` vit DANS `#crisisDock`, sous la capsule — le quai collant, dont la
hauteur entre déjà dans `--stick-top` (le rail se recale dessous, aucune mesure nouvelle) ; le
bandeau `#crisisBand`, premier logement essayé, est masqué dans la mise en page courante — leçon
« mesurer l'app, pas lire le CSS ». Ambre (registre △ : là où l'on risque de se tromper sur un
miroir figé), 36-41 px, une ligne à 390 px (mesuré 41 ; « depuis HH:MM » vit dans la feuille,
sinon la rangée passait à 81 px), peinte au tick par `updateRtStrip` sur signature (aucun
re-rendu inutile). Gestes selon le rôle, cibles 32 px + halo 44 (règle 9) : hôte « Montrer la
progression » (émission optique) ; invité « Recevoir » (filmer l'hôte) et « Renvoyer » (ses
repères datés) ; expiré « Se reconnecter… » (écran d'entrée) ; et ⓘ « Pourquoi ? » ouvre la
feuille. Termes retenus : « Lien perdu » (état), « Recevoir » / « Renvoyer » (gestes) — courts,
sans jargon de transport.

**Une feuille.** L'invité n'avait PAS de feuille de partage (« Partager » ouvrait la feuille cloud
de l'hôte, avec son code) : `slSheet('guest')` — même ligne d'état (`slLinkLine`), journal du
lien (A321), Recevoir / Renvoyer / Montrer, « Se reconnecter… » si expiré ; `slBusySheet` y mène.
Les feuilles de l'hôte reçoivent la même ligne d'état. Réception et retour optiques deviennent
DEUX fonctions (`slRxStart`, `slRetTx`) partagées par la feuille miroir, la feuille invité et la
bannière — deux blocs inline en moins.

**Garde-fous** (section E2E des bascules, 40 → 47 contrôles) : direct vivant → pas perdu, pas de
bannière ; invité au canal mort et serveur muet → bannière « Lien perdu » avec Recevoir/Renvoyer/ⓘ,
≤ 48 px ; hôte aux invités silencieux → « Montrer la progression » ; « Partager » chez l'invité →
même vérité (état, gestes, journal) ; réseau revenu → reprise seule et bannières effacées des deux
côtés ; partage expiré → l'invité le sait, « Se reconnecter… ». Vérifiés capables d'échouer (source
d'état neutralisée → rouges, `index.html` restauré à l'octet).

## A325 — l'invité rechargé en direct retrouve la session ; « Connexion perdue » (v5.23.8)

**Demandes de l'auteur** : « vérifie côté invité si on rafraîchit la page pendant le direct » ; « Lien
perdu » n'est pas clair — « Connexion perdue — partage manuel ».

**Mesuré.** Un invité passé en direct n'avait plus que le billet du hub local en `sessionStorage`
(écrasé par `joinByCode` sur le canal) ; rechargé, `Share.resume()` pullait le serveur avec l'id du
hub local, était refusé, effaçait le billet — l'invité se retrouvait chez lui, sans session. Le hub
et le canal WebRTC meurent avec l'onglet ; le seul fil qui peut survivre est le partage cloud.

**Ce qui change.** Le billet cloud de l'invité (`slSb.cloud`, A322) est écrit en `sessionStorage`
sous sa propre clé (`SL_CLOUD_TK`, `slCloudTkSave/Read` — même arbitrage J224), consommé à la
reprise ou au refus. Au démarrage, si la reprise par le billet local échoue et qu'un billet cloud
existe, `slBootCloudResume` sonde le serveur : s'il répond, `slResumeCloud` reprend le partage et
`openSharedFiche` rouvre la session ; sinon le billet ATTEND, et la sonde (`slBackArmed`, troisième
raison : mode `off` + billet cloud) retente à chaque réponse. Sans serveur ni canal : l'écran d'entrée
et le code, seul chemin — dit.

**Les mots.** « Lien perdu » devient **« Connexion perdue »** (bannière, feuille, journal, réveil) ;
la feuille précise « partage manuel par l'écran en attendant » et le motif ; la bannière garde ses
gestes courts (Recevoir · Renvoyer · Montrer la progression · Se reconnecter…) et tient sa ligne.

**Garde-fous** (section E2E des bascules, 47 → 50 contrôles) : billet cloud en `sessionStorage`
une fois en direct ; page invité RECHARGÉE (vrai `reload`, guichet du relais réinstallé par script
d'initialisation) sans serveur → rien ne repart, le billet attend ; serveur revenu → reprise seule et
session retrouvée. Vérifiés capables d'échouer (reprise au démarrage retirée → rouge, `index.html`
restauré à l'octet).

**Et la bannière n'a pas de mémoire** (demande de l'auteur : « vérifie qu'elle disparaît si la
connexion revient, et qu'elle peut réapparaître, et ainsi de suite ») : elle est repeinte à chaque
tick depuis `slLink()`, fonction PURE de l'état vivant (sondages ratés, sonde de joignabilité, canal
dormant, drapeau « expiré ») — aucun état propre, sauf la signature qui évite de repeindre à
l'identique. L'état redevenu sain, `lost` tombe et la rangée se cache ; l'état retombé, elle
revient. Seul « expiré » colle, effacé par une nouvelle jointure. Mesuré : deux cycles complets
(perdue → effacée → perdue → effacée) au banc, 50 → 52 contrôles.
