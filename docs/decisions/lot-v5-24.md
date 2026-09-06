# Lot v5.24 — la feuille de partage dit quoi faire : l'app décide, les étapes suivent (A327-A328)

> Fichier normatif, suite de [`lot-v5-23.md`](lot-v5-23.md) (A317-A326). Les numéros A sont des
> adresses : ne jamais renuméroter. Demande de l'auteur (06/09/2026) : « maintenant que le partage
> est seamless, simplifier la fenêtre pour un novice — tout doit être automatique, insister sur les
> étapes dans leur ordre, en situation critique on n'a pas le temps de se poser la question » ;
> maquettes validées sur canvas (Claude Design), puis « garde une petite option pour changer
> manuellement le mode », « le bandeau de l'hôte doit aussi pouvoir recevoir ».

## A327 — « l'app décide, la feuille dit quoi faire » (v5.24.0)

**Mesuré avant** (v5.23.9, 390 px, serveur bouchonné comme dans `audit-partage`) : la feuille de
l'hôte ouvrait sur le SÉLECTEUR de canal (« En ligne · En direct · Par l'écran », légende « l'app
choisit seule — forcer si besoin »), puis trois formes du même accès (code, QR, lien en clair), un
compte à rebours, une liste « Participants (0) » et une note sur « Couper » avant d'avoir invité qui
que ce soit. Après jointure : « le code a servi. Un code ne sert qu'une fois. » L'invité avait trois
boutons sans explication (« Recevoir la progression », « Renvoyer mes repères », « Montrer à un
autre écran »). Le bandeau « △ Connexion perdue » de l'hôte n'offrait que « Montrer ».

**Ce qui change — un seul dessin, hôte et invité.**
1. **Plus de sélecteur en tête.** Une LIGNE D'ÉTAT dit le mode et sa raison en un mot (`slStatusHtml`,
   `slWhy`) : « ● Partagé · en ligne — Internet répond, rien à régler » ; « · en direct — Pas
   d'internet, mais un Wi-Fi commun » (sans compte : « Sans compte, le partage se fait en direct ») ;
   « · par l'écran — Connexion perdue à HH:MM, aucun réseau ». Le canal est CHOISI par l'app :
   serveur joignable → en ligne ; serveur muet + adresse locale vue (`slLocalCand`) → en direct ;
   aucune adresse locale → **par l'écran d'office** (`slOffer` : la phase `optic` remplace
   `offer-warn`, qui montrait un QR d'appariement voué à l'échec avec un avertissement).
2. **Une rubrique, « À faire, dans l'ordre »** (`slStep`) : étapes numérotées, le bouton EST l'étape ;
   une étape faite passe en ✓ vert avec le mot (« Code scanné », « Rien d'autre »). En ligne : ①
   faire scanner (code AU-DESSUS du QR — l'ordre mesuré à 320×568 en v4.47.0 est gardé) ② rien. En
   direct : ① faire scanner ② « Scanner la réponse » + issue de secours « Rien après 10 s ? Passer
   par l'écran » ③ rien. Par l'écran (`slOpticStepsHtml`, en MIROIR) : hôte ① Montrer ma
   progression ② Recevoir ses repères ③ refaire l'étape 1 à chaque bloc ; invité ① Recevoir la
   progression ② Renvoyer mes repères ③ refaire. L'invité en ligne lit « ✓ Rien — si le réseau se
   perd, les étapes s'affichent ici » et son rôle expliqué en une phrase.
3. **Le lien brut ne s'affiche plus** : « Envoyer le lien… » (`slSendLink` — feuille de partage
   native, sinon presse-papiers) ; l'adresse ne s'écrit que si la page n'en a pas de partageable.
   « ouvert encore 118 s » devient « encore N s » sous le code, et « code expiré — “Inviter
   quelqu'un d'autre” en donne un nouveau » ; « Nouveau code » devient « Inviter quelqu'un d'autre ».
4. **Participants** sur deux lignes (nom + rôle, puis Donner la main / Couper à 44 px pleins) et une
   légende d'une phrase pour ces trois mots ; la note sur « Couper » ne précède plus l'invitation.
5. **L'historique du lien (A321) reste au pied** de chaque feuille : c'est là qu'on voit que le cycle
   réseau → coupure → retour → coupure se répète sans que rien ne reste bloqué.
6. **Le bandeau du mode crise (A324) = l'étape ① de la feuille, compressée** (`slLinkPaint`) : « △
   Par l'écran » (le mot du MODE, celui de la ligne d'état — la cause « Connexion perdue depuis
   HH:MM » vit dans le `title`, la feuille et l'historique), puis hôte « ① Montrer · ② Recevoir »,
   invité « ① Recevoir · ② Renvoyer », expiré « Se reconnecter… », ⓘ ouvre la feuille. **L'hôte
   reçoit aussi** (demande de l'auteur : « ce n'est plus l'hôte qui détient forcément toutes les
   infos ») — `slRxStart(fin, hint)` prend la consigne de visée, le retour invité→hôte (A205) a enfin
   sa porte dans le bandeau et dans la feuille. **Le bandeau reste tant que « par l'écran » est le
   mode en cours** (`slOpticOn` : forcé, choisi d'office sans adresse locale, ou miroir) et pas
   seulement quand le lien est perdu — demande de l'auteur : « envoyer / récupérer plus rapidement »
   sans rouvrir la feuille ; il s'efface au retour à Automatique ou d'un autre mode. Mesuré : 41 px,
   une ligne à 390 px.
7. **La porte de secours, hors du chemin** : « Mode : automatique › » en petit sous la ligne d'état
   (« Mode : forcé, en direct › » / « forcé, par l'écran › » après un choix — le mot se DÉRIVE de
   l'état, `slModeWord`, jamais d'un drapeau à part), ouvre « Changer manuellement le mode »
   (`slModeSheet`) : quatre rangées radio, Automatique en tête (rend la main et RÉARME le retour en
   ligne, A319), En ligne, En direct (« prêt » quand le secours chaud est formé), Par l'écran
   (« toujours »). Un mode fermé garde son encre — jamais grisé —, reste tapable et dit pourquoi
   (v5.17.4, `slCloudWhy`) ; son état se lit en ambre (« compte nécessaire », « pas d'internet »). Les bascules confirment comme avant (`slModeApply` reprend `slModeSegBind`).
   L'invité n'a pas cette porte. **Les confirmations de bascule** (et « Arrêter le partage ? »)
   sont réécrites sur un patron lisible en un regard : une phrase sur ce qui se passe, puis « qui
   fait quoi » en lignes courtes (« • Vos participants basculent seuls — personne ne scanne. • Votre
   session ne bouge pas. ») ; le cas « secours pas prêt » oppose « Attendre » à « Basculer quand
   même » (`#confirmMsg` est déjà en `pre-line`). Seul état nouveau : `slSb.optic` (choix manuel « par l'écran »),
   remis à zéro par `slSbReset`, « Arrêter » et « Automatique ».
8. **Une seule porte pour « quelle feuille montrer »** : `slPhase()` (cloud · live · offer · optic ·
   guest · mirror) et `slSheetNow()` — le menu, la fin d'émission optique (`ltStop`) et le retour de
   la feuille « Mode » y passent ; `slBusySheet` en dérive.

**Ce qui n'a pas changé** : détection et bascules (A318-A325), le vocabulaire des transports, le
quai « ● Partagé » (A317), la feuille d'entrée de l'invité, les dialogues de confirmation des
bascules manuelles, la règle 15 (rien de nouveau ne voyage).

**Purges** : `slModeSegHtml/Bind`, `slSegCap`, `slSegNetPaint` (→ `slModePaint`), `slSegDotRefresh`,
`slLinkLine`, la phase `offer-warn` ; CSS `.sh-lead`, `.sh-lnk`, `.sh-adr` (hors `.warn`),
`.sh-note`, `#shareBody .seg*`, `.sdot` ; l'exemption `seg-cap` de `check-classes`.

**Garde-fous** (`audit-partage`, sections « fenêtre d'appariement de l'hôte », « bascule
en ligne⇄direct », « lien perdu ») : le lien est porté par « Envoyer le lien… » (URL complète avec le
code), la feuille dit QUI a rejoint, « Inviter quelqu'un d'autre » reste offert, la feuille « Mode »
dit « prêt » quand le canal dormant l'est et c'est par elle que passent les bascules manuelles, la
bannière de l'hôte porte « ① Montrer · ② Recevoir », celle de l'invité « ① Recevoir · ② Renvoyer »
avec le mot « Par l'écran » ; a11y : la feuille « Mode » et les feuilles à étapes entrent dans les
surfaces mesurées par l'ouverture réelle. Vérifié : `npm run check`, 1190 tests × 2 moteurs,
audit complet après le numéro de version.

## A328 — trois signalements terrain de la v5.24.0 (v5.24.1)

**1. « Montrer » ne mettait rien à jour chez l'invité.** `slOptiqueGot` refusait tout instantané dès
qu'une session était démarrée sur l'appareil et qu'il ne s'agissait pas d'un miroir (« Cet écran
diffuse une AUTRE session ») — or un invité qui suit EN LIGNE ou EN DIRECT est exactement dans ce
cas, et depuis le bandeau le refus était silencieux (`#slStat` absent). Une session est « suivie »
si c'est le miroir courant OU la session dont l'invité tient le `sessId` (`Share.fold.sessId`,
posé par `session_start`) ; seule une AUTRE session reste refusée. L'invité en ligne garde
l'horloge du serveur (`Share.offset` n'est plus écrasé par l'heure de l'hôte).

**2. En ligne → par l'écran → en ligne : « Partagé · 0 », participants disparus, plus de synchro,
« En direct · prêt » à 0 participant.** `slModeCur` rendait « optic » dès que le mode était forcé :
« En ligne » n'était donc jamais « le mode courant » et partait dans la branche de bascule, qui
FERMAIT le partage en ligne et en ouvrait un NEUF (0 participant, nouveau code) pendant que l'invité
restait sur l'ancien (« suit ») — et le canal direct dormant, pair-à-pair, survivait à la fermeture
côté serveur, d'où « prêt ». Symétriquement, « En direct » depuis « par l'écran » lançait un
appariement SANS fermer le partage en ligne. Règle : **le mode courant est le TRANSPORT** (cloud ·
direct · aucun) ; « par l'écran » est une couche par-dessus, jamais un transport. Choisir le
transport déjà en cours ne fait que retirer la couche ; la feuille « Mode » coche « Par l'écran »
quand la couche est posée.

**3. Bandeau au cockpit (≥ 1200).** Enfant du quai, il MONTAIT avec lui dans le créneau de l'en-tête
(`placeCrisisChrome`) et couvrait le titre. Il ne monte plus : `placeCrisisChrome` le laisse dans le
flux, sous l'en-tête (`rescueCrisisChrome` le rend au quai en étroit — patron nomade, jamais recréé),
en rangée COMPACTE collante (`top` sur `--hdr-off`), centrée, bordée, arrondie (`--r-2`) — jamais
pleine largeur (« overkill », arbitrage de l'auteur). Mesuré à 1400 px : 330 × 42, centrée sous la
capsule, 11 px sous l'en-tête, suit le défilement.

**4. Le focus d'ouverture encadrait « Mode : automatique › »** (iPhone : l'anneau posé par
`_dlgEnter`, A237, tombait sur le premier bouton du corps — ce lien discret, aux marges négatives).
`slPrefFocus` marque `data-dlgfocus` sur l'ACTION de l'étape (« Envoyer le lien… », « Scanner la
réponse », « Montrer ma progression »…) ou la rangée choisie de la feuille « Mode ». Libellés :
« compte nécessaire » (et non « demande un compte »), « Un mode indisponible reste tapable et dit
pourquoi » (rien n'est grisé).

**Garde-fous** (`audit-partage`) : section « bascule en ligne⇄direct » — « par l'écran » forcé puis
« En ligne » garde le MÊME partage et ses participants ; section « retour optique » — un invité qui
suit la session reçoit son instantané par l'écran, une autre session lui reste refusée.
