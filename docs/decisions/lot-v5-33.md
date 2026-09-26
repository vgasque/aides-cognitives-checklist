# Lot v5.33 — l'éditeur : écrire d'abord, régler ensuite (A383)

> Fichier normatif, suite de [`lot-v5-32.md`](lot-v5-32.md) (A382). Les numéros A sont des adresses :
> ne jamais renuméroter. Demande de l'auteur (26/09/2026) : « le mode édition ne doit pas être trop
> superflu d'informations et de clics — un novice qui veut juste cocher des cases et écrire ne doit pas
> être perdu ; l'utilisateur aguerri doit trouver les réglages sans sous-sous-menus ». Audit mesuré
> (ACR, 390 px : 9 200 px d'éditeur, 196 commandes ; une étape touchée passait de 70 à plus de 500 px),
> puis maquettes sur canevas (page « Éditeur », E1-E7) revues fil par fil, et captures réelles validées.

## A383 — une étape s'écrit sans rien ouvrir ; ses réglages sont à UN toucher (v5.33.0)

**Le défaut.** Toucher le texte d'une étape dépliait onze commandes (registre, ★, ×2, lien de coche,
« Commence », seuil, « Puis », supprimer…) ; certaines ne pouvaient servir à rien (le moment dans un bloc
qui ne se répète pas — régression de la v5.32) ; les listes empilées n'avaient pas d'intitulé.

**La rangée d'étape** (`blockEditor`) : poignée · texte 17,5/700 · bouton « Réglages » (`.li-set`, 40 px,
bleu doux quand quelque chose est réglé) ; dessous la réponse attendue, puis ce qui est réglé en
PASTILLES (`edStepSum` : Critique / Vigilance, ★ Mémoire, ×2 en chasse fixe, « ⏱ lance … » / « +1 … »,
« Chocs délivrés ≥ 3 », « à l'échéance » / « une seule fois » / « au besoin »). Le registre se dit par la
pastille, plus par une marque ni une teinte dans le champ (`.li-mk`, `.li-crit` purgés). Écrire n'allume
que les champs (`:has(input:focus)`, jamais le focus du bouton). Filet entre étapes, marges de 4 px :
≈ −20 % de hauteur, cibles tenues (champ 32 px, réponse ≥ 24 px, bouton 40 px, corps ≥ 16 px).

**La feuille « Réglages de l'étape »** (`#stepSetModal`, `stepSetHtml`) : feuille basse au téléphone
(grammaire de la feuille ⋯), fenêtre centrée dès 780 (celle de « Affichage » — un panneau latéral sous
voile ne montrait rien de plus). « OK » ferme. Trois sections nommées : IMPORTANCE (segmenté Normale ·
Vigilance · Critique, interrupteurs Mémoire et ×2), CE QUE FAIT LA COCHE (la liste ; sans minuteur ni
compteur, deux boutons « ＋ Créer » qui créent ET lient, nommés d'après l'étape), MOMENT (segmenté « Dès le
1ᵉʳ passage / À partir d'un compte », compteur + pas −/+, grille « Puis revient » en quatre cases ; « À
l'échéance » dit de quel minuteur, ou pourquoi il est fermé — son toucher mène à la coche, A235).
« Supprimer l'étape » en bouton danger. Chaque réglage re-rend l'éditeur ancré sur la rangée et garde le
focus dans la feuille ; fermer le rend au bouton « Réglages ».

**Point 2 — ce qui ne peut servir à rien n'est pas montré** : le Moment, le minuteur du bloc et les jalons
n'existent que si le bloc SE RÉPÈTE (`blkInLoop`, déduit du parcours — rien à déclarer) ou s'ils sont déjà
posés (on ne cache jamais une donnée). Hors boucle, une phrase dit où le moment se règle. Le bloc qui se
répète le dit (« ↺ Se répète » sous le titre).

**Le bloc** : titre en texte au repos (21/800), étapes, « + Ajouter une étape », étape suivante, puis
« Options du bloc » — la carte dépliable de l'app (`foldCardHtml`), résumé à droite, ouverte d'office
quand une option est posée (le départ seul ne compte pas) : rangées libellé | valeur (bloc de départ en
interrupteur, phase, libellé de « Continuer », minuteur du bloc, jalons, image). La phase QUITTE l'en-tête.
« Supprimer le bloc » hors de la carte, en bouton danger. Les règles d'usage (« Rouge, ambre, réponse
attendue ») : une fois, en tête de « Prise en charge ».

**Le jalon se lit comme une phrase** : [Passages du bloc | compteur ▾] ≥ [− n +] — la même forme que le
moment et que la pastille « Chocs délivrés ≥ 3 » (l'ancien « quand un compteur atteint n » tronqué, puis
un nombre, puis le compteur, n'avait pas de lecture).

**Refusés** (à ne pas reproposer sans l'auteur) : un mode « simple / expert » global (l'utilisateur qui
change d'avis ne retrouve rien) ; un menu ⋯ à sous-menus ; un panneau latéral au bureau.

**Écart nommé aux maquettes** : la réponse attendue reste dans la police du texte à 16 px (la maquette
la voulait en chasse fixe 13,5 : sous 16 px, iOS zoome au toucher — règle 9).

**Témoins.** `audit-doctrine` A383 (écrire n'ouvre rien, boucle, point 2, pastilles, feuille qui écrit le
brouillon et garde le focus, retour du focus, phrase hors boucle, feuille basse à 390 / centrée à 1280) ;
T7 pose l'étoile par la feuille ; `audit-k5` (suppression d'étape par la feuille, registre, phase dans
les options) ; `audit-a11y` mesure la feuille.

## A384 — v5.33.1 : retours d'usage sur l'éditeur allégé

**La rangée d'étape reste ouverte tant que le focus reste en elle** (`.ed-on`, posée en JS au
`focusin`, retirée au `focusout` seulement si `relatedTarget` sort de la rangée). Mesuré : cliquer
la réponse attendue VIDE repliait l'étape. `:has(input:focus)` se relâchait ENTRE le blur du titre et
le focus du champ — le champ passait à `display:none`, le navigateur abandonnait le focus (trace :
`focusout rel=li-exp`, aucun `focusin`) et le clic tombait sur l'étape suivante. ⚠ Tout champ qui ne
paraît « qu'au focus de sa rangée » a ce défaut s'il est piloté par `:has(:focus)` ou `:focus-within`.

**Le gabarit des champs du bloc est celui des listes du chapeau** (« Condition d'entrée », « Ne pas
oublier ») : 15 px, rembourrage 8, ≈ 40 px (M) ; 16 px au toucher (règle 9, liste du bloc
`pointer:coarse`). Vaut pour le titre d'étape (700), la réponse attendue À L'ÉDITION, la question
d'une décision (son style en ligne est parti), les réponses et les cibles (`select` à 40 : son
rembourrage le portait à 41,5). Au REPOS la réponse attendue reste une ligne de texte serrée sous le
titre (marge −8 qui reprend le rembourrage du titre) ; à l'édition elle devient un champ, 6 px dessous.
Amende l'« écart nommé » d'A383 : 15 px au pointeur fin, 16 au toucher. La réponse s'arrête avant
« Réglages » (marge droite 48), qui ne déborde plus sur le filet du dessus.

**Le glisser de la pastille est délégué une fois au document** : `bindSegDrag` n'existe plus. Chaque
sélecteur devait l'appeler à sa naissance, et chaque sélecteur neuf l'oubliait (« Importance »). Tout
`.seg` à `.seg-pill` directe glisse ; l'engagement reste un click synthétique sur le cran visé.

**Un seul dessin pour les boutons d'outil de l'éditeur** (`.ed-ic`) : M 40 sur la matière blanche des
boutons de l'app (`.fz` — fond `--work`, filet, ombre). Une première version SANS fond (celle de
« Réglages ») a été refusée à l'usage : sur le gris de la ligne éditée, le B ne se lisait plus comme un bouton. Il remplace QUATRE dessins nés à des époques différentes : la case blanche bordée
(`.mini.del`, rappels · réponses · minuteurs · compteurs · documents), sa variante rouge des listes, le pavé
gris `.tk-del` (complications, jalons) et les cases B / △ des listes (`.mini.bld`, `.crit-tgl`, purgés
avec `.fg-go` et `.li-tools .mini.del`). La croix rougit au SURVOL seulement (un rouge au repos répété sur
chaque ligne criait plus fort que les étapes critiques) ; le △ posé prend le fond ambre du registre. Le
`.mini.bld` de la barre Markdown du protocole reste : c'est une barre d'outils à libellés, pas une rangée.
**La croix d'une complication chevauchait la cible** : `padding-right:32px` pour une croix de 38 ;
réservé désormais à 48 (40 + 8). Le champ « Événement » n'avait pas `type="text"` — aucune règle de
champ ne l'atteignait (bordure carrée du navigateur) ; la cible se dessine comme le `<select>` d'une réponse.

**Textes** : « ×2 Confirmée par les deux » dit sa portée (« en session, marquée ×2 : les deux soignants
la vérifient à voix haute ») ; « Libellé de « Continuer » » est dit facultatif ; 8 px sous
« Importance ».
