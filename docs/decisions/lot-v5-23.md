# Lot v5.23 — le partage sans question : un état, une détection rapide, un retour seul (A317-A321)

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
