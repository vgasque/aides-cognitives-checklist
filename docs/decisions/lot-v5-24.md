# Lot v5.24 — la feuille de partage dit quoi faire : l'app décide, les étapes suivent (A327)

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
   (« toujours »). Un mode fermé garde son encre, reste tapable et dit pourquoi (v5.17.4,
   `slCloudWhy`). Les bascules confirment comme avant (`slModeApply` reprend `slModeSegBind`).
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
