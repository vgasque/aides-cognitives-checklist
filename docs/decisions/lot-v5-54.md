# Lot v5.54 — A490-A493

Quatre retours d'usage de l'auteur sur l'accueil et les fenêtres, mesurés avant d'être corrigés.

## A490 — une bibliothèque vide se voit dans la colonne (v5.54.0)

Signalé : « mes bibliothèques que je viens de créer ne s'affichent pas dans la sidebar si elles sont vides ». Ce
n'était pas un choix mais un effet de construction : la colonne naissait de `bibGroups(aides visibles)`, qui ne forme
un groupe que pour une bibliothèque contenant quelque chose. `bibGroups(list, toutes)` : la colonne liste Perso et
TOUTES les bibliothèques de l'utilisateur, compte 0 compris. La feuille Affichage, elle, garde sa règle (décision de
l'auteur, A489) : pas de filtre pour une bibliothèque vide.

## A491 — le retour à l'accueil repose la liste où on l'avait laissée, à toute largeur

L'intention existait (`_libScrollY`, « revenir restaure là où on en était dans la liste ») mais ne lisait que
`window.scrollY`. Mesuré : 390 px → position gardée ; 820 et 1280 px → retour EN HAUT, parce que dès 780 px la
liste défile dans `.home-main` (et la colonne dans `.hs-scroll`), recréés à chaque retour. `_libInner` mémorise les
deux défileurs au départ, `renderLibrary` les repose au retour (bornés au nouveau contenu, patron d'A288).
**Quand ne pas restaurer** : après « Terminer la session », l'accueil s'ouvre en haut — la carte-bilan de la session y
est, c'est elle qu'on vient voir. Partout ailleurs (retour système, retour d'en-tête, après une modification) la
position revient : les filtres et le rangement sont conservés, la liste est la même.

## A492 — l'anneau d'ouverture suit la modalité (amende A237 / J235, décision de l'auteur)

Signalé : « des éléments d'une liste peuvent être encadrés, des boutons qui n'en ont pas vraiment besoin ». Audit au
VRAI pointeur (souris et toucher, Chromium et WebKit, 390 et 1280 px) : les menus (`.popmenu`) n'encadrent rien ;
CHAQUE fenêtre posait un anneau à l'ouverture (A237 : posé à la main pour le clavier) — la carte « Aide cognitive »
dans Créer, le segment « Tout » dans Affichage, le premier dépliant de Prendre en main, « Rejoindre une session » dans
Sessions, et le CLAVIER qui s'ouvrait au téléphone dans Moi et Catégories (focus sur un champ).

- **Au clavier, rien ne change** : point d'entrée + anneau (A237), piège Tab (A313).
- **Au doigt ou à la souris** (`_ptrNav` : un pointeur a parlé depuis la dernière touche) : une DÉCISION
  (`.dlg-confirm`, nom d'une bibliothèque, tableau/collage, partage — `DLG_DECIDE`) reçoit le focus sur son action ou
  son champ, SANS anneau (Entrée garde son sens : l'action, ou « Annuler » si elle détruit) ; une fenêtre qu'on
  PARCOURT le reçoit sur son TITRE (`.dlg-anchor`, `tabindex=-1`) — rien de présélectionné, aucun clavier ouvert. Le
  premier Tab rallume l'anneau.
- Ce que disait A237 (« deux apparences pour un même dialogue ») est tenu autrement : l'apparence dépend de la
  modalité, jamais du hasard ; au pointeur, l'action se reconnaît à son registre (bouton plein), pas à un anneau.

## A493 — « Tout » en tête des collections de la colonne

Les deux autres sections ont leur remise à zéro (« Toutes », « Toutes les catégories ») ; les collections n'en avaient
pas (re-toucher la collection active). Rangée « Tout », cran rond, allumée quand aucune collection n'est choisie.
Mot pesé avec l'auteur : « Toutes les aides » oublie les protocoles ; « Toutes » se lirait « toutes mes
collections » (ce qui est rangé quelque part) ; « Sans collection » dirait l'inverse ; « Tout afficher » est un ordre
dans une colonne d'états. « Tout » dit « aucun tri par collection ».

Témoins : `audit-doctrine` « Fenêtres · A492 » (réécrit : souris → pas d'anneau, clavier → anneau, Compte → titre) et
« ACCUEIL · A490-A493 » (390 et 1280 px ; le témoin « Terminer » vérifié capable d'échouer).
