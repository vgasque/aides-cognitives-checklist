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
