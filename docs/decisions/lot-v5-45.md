# Lot v5.45 — les gains rapides de l'audit d'apprentissage (A460)

> Fichier normatif, suite de [`lot-v5-44.md`](lot-v5-44.md) (A452-A459). Les numéros A sont des adresses : ne jamais
> renuméroter. Origine : [`docs/audit-apprentissage-2026-10.md`](../audit-apprentissage-2026-10.md) (05/10/2026),
> § 8 « Gains rapides ». Accord de l'auteur : « Ok go ». Les chantiers « moyen terme » et « structurant » du même
> audit restent À DÉCIDER : ils ne sont pas couverts ici.

## A460 — ce qu'un nouvel arrivant ne trouvait pas, ou lisait de travers

Neuf corrections et un report, toutes sans changement de modèle. Chacune est vérifiée dans le vrai navigateur, au
point d'entrée réel (`amorce` / `ouvrirFiche` / `demarrerSession`).

1. **Le discriminant est cherché.** `ficheHaystack` et `protocolHaystack` l'indexent. Avant, taper « pédiatrique » ne
   trouvait pas « Anaphylaxie — pédiatrique », alors que le mot est affiché sur la rangée. `protocolHaystack` entre
   dans `__ac_test__` ; deux témoins sont ajoutés dans `tests.html`.

2. **Entrée ouvre le premier résultat** de la recherche d'accueil. Le rendu débouncé est d'abord rattrapé, pour que la
   liste ouverte soit celle de la frappe. La cible est la première rangée `.dir-row:not(.selm) .card-open` : jamais
   une tuile épinglée (masquées pendant une recherche), jamais une rangée en mode sélection. Les modificateurs et la
   composition IME sont ignorés.

3. **« Exercice » en toutes lettres dès 360 px effectifs.** Sous 430, la touche resserre son rembourrage (14 → 8 px)
   au lieu de tronquer le mot ; « Exo. » ne tombe plus que sous `zw360`. Cela amende v5.26.0, qui tronquait dès 430.

   Mesures, de 320 à 430 px et de 100 à 130 % :
   - le mot entier coûte 16 px au bouton de démarrage à 390 px ;
   - aucun débordement nouveau n'apparaît.

   **Le libellé court suit l'état.** Une fois armée, la touche disait encore « Exo. » à l'écran et « Annuler » au seul
   lecteur d'écran. Elle affiche maintenant « Annul. », troncature du même mot.

   **Reporté : le nom du compteur dans la capsule.** « Chocs déliv. » y devient « CHOCS DE… » (abréviation d'office
   A403, puis ellipse CSS). Deux pistes ont été mesurées :
   - la casse de phrase ne tient qu'à 390 px en taille normale ;
   - deux lignes n'entrent pas dans la capsule de 64 px (A347/A410).

   C'est une décision de dessin, laissée À DÉCIDER.

4. **« Regrouper » écrit ses crans en entier.** « Catégorie » et « Bibliothèque » portent une césure douce (`­`)
   et passent sur deux lignes dans la hauteur L 44 (`.vs-seg.vs-wrap`). À zoom 1, aucun débordement de 320 à 1280 px.
   À 130 % sous 400 px, le débordement reste de 0 à 7 px, du même ordre qu'avec l'abréviation.

5. **L'info-bulle de « Vérifier » est en français, pour l'utilisateur.** « Do-Verify : … » devient « Relire ce bloc
   étape par étape : … ». Le terme reste dans la doctrine, plus dans l'interface.

6. **Le geste « maintenir » s'écrit dans le bouton de fin.** Le bouton porte « Terminer » sur une ligne et
   « maintenir 1,2 s » en sous-ligne. Le libellé principal est un `.tmr-lab` : `holdToReset` n'écrit « Maintenir… »
   que dans lui, et la hauteur ne bouge pas pendant l'appui. Sous les boutons : « Relâcher avant la fin annule. »
   La couleur rouge (A409) et la durée (A346) sont inchangées.

7. **« Confirmé — » ne coiffe plus un exercice ni un essai.** Il acquitte les critères « Quand l'utiliser » devant un
   patient (doctrine QRH v4.3.2) ; une répétition n'a rien à confirmer. Le bouton dit donc « Démarrer l'exercice » et
   « Démarrer l'essai ».

8. **Le badge « À compléter » de l'accueil se tape.** Il ouvre la même notice que l'écran d'entrée : la porte
   `[data-todo]` existante et la même phrase. Il passe au-dessus du voile `.card-open::after`, sinon le tap ouvrait
   l'aide, avec un halo de 32 px de haut (règle 9). En mode sélection, il redevient inerte : la rangée se coche.

9. **Les exemples arrivent « À relire ».** Avant, l'éditeur disait « ✓ Validée », le badge « △ À compléter » et le
   bandeau « validez-les » : trois messages pour une seule fiche. Le commentaire de `seed` disait déjà « ces fiches
   arrivent en brouillon et le disent » : c'est désormais vrai. Le statut est posé dans `addSeedFichesOnce`, et
   non dans `seed()`, que les tests utilisent comme fiche « nominale ».

   Le bandeau devient : « 2 aides d'exemple ajoutées, « À relire ». Adaptez-les à votre service puis validez-les : vous
   êtes responsable du contenu clinique. » Effet connu, et voulu : la notice « À relire » existante paraît sur
   l'écran d'entrée des exemples.

   **Corollaire mesuré : la notice « À relire » ne paraît plus EN SESSION.** Devenue visible sur la fiche
   de référence des harnais, elle repoussait la 1ʳᵉ étape sous le pli à 320 × 640 et 130 % (`audit-budget`, y = 488
   pour un pli à 640). C'est un signal de maintenance : il se lit avant de démarrer et n'appelle aucun geste pendant.
   « Brouillon » (« pas encore validée pour l'usage clinique ») reste affiché partout, session comprise.

10. **Moi › « Revoir l'accueil ».** L'écran de bienvenue se fermait pour toujours au premier tap, croix comprise.
    `openWelcome()` le rouvre depuis la carte « Sur cet appareil ». Ses portes restent vraies :
    - **« Découvrir avec 2 exemples »** s'efface si un exemple est déjà là (`SEED_TITLES`). `addSeedFiches` n'a pas de
      garde contre le doublon, et n'en avait pas besoin tant que la porte ne servait qu'une fois.
    - **« Me connecter »** s'efface une fois connecté, ainsi que le point qui le sépare de la porte voisine.

**Formes écartées.**
- « Maintenir pour terminer » comme libellé unique : il passait sur deux lignes à 390 px et changeait le mot de l'acte.
- Un champ de mots-clés pour la recherche : c'est un ajout au modèle, qui relève du « structurant » de l'audit.
