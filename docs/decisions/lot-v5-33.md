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
