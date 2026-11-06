# Lot v5.94 — liens d'application (A586)

> Fichier normatif. Les numéros A sont des adresses : ne jamais renuméroter. Amende A464 (lien direct).

Demande de l'auteur : « créer des liens accessibles pour d'autres apps, ou des liens, ou l'app Raccourcis d'Apple —
avec des raccourcis créables type « Créer une fiche », ou qui affiche la liste des bibliothèques, ou qui affiche les
aides favorites ».

## A586 — un fragment stable par destination

**Les liens.** A464 avait ouvert `#a=<id>` (une aide), `#chercher` et `#sessions`. S'y ajoutent :

| Fragment | Ce qu'il ouvre |
|---|---|
| `#creer` | la fenêtre « Créer » (aide par défaut ; le type se change dans la fenêtre) |
| `#acces-direct` | l'accueil filtré sur l'Accès direct — les « favorites » sont les épinglées (`COLL_PIN`) |
| `#bibliotheques` | la liste des bibliothèques : en large, la colonne gauche (son rang actif prend le focus) ; au téléphone, la feuille « Afficher » du grand titre, qui les porte en tête (A556) |
| `#bibliotheque=<id>` · `#bibliotheque=perso` | l'accueil restreint à une bibliothèque (`state.homeLib`) |
| `#collection=<id>` | l'accueil filtré sur une collection personnelle (A475) |

**Lecture pure, table fermée.** `deepLinkFromHash` lit les mots dans `APP_LINKS` (un mot hors table n'est pas un lien,
et `hasOwnProperty` écarte `#constructor` ou `#toString`) ; un identifiant suit la même garde que `#a=`
(`[A-Za-z0-9_-]{1,64}`, `BAD_KEYS` refusé). `appLinkFrag` est l'écriture inverse, seule source des liens affichés ;
`tests.html` vérifie que l'une relit l'autre.

**Le lien porte une destination, jamais une donnée.** `#acces-direct` ouvre les épinglées de l'appareil qui l'ouvre ;
un identifiant de bibliothèque ou de collection n'apprend rien à qui ne l'a pas. Une destination absente de l'appareil
(collection supprimée, bibliothèque dont on n'est pas membre) le dit dans une notice et ne change pas l'écran.

**Ce qui ne change pas d'A464.** Jamais par-dessus une session réelle (règle 11) ; le fragment est retiré une fois lu ;
même lecture au démarrage, à `hashchange` et par `launchQueue` ; le retour système ignore ces fragments.

**Arrivée sans saut.** Une destination de l'accueil (Accès direct, collection, bibliothèque) se pose dans l'état
AVANT le rendu : on arrive sur la liste déjà filtrée, la recherche vidée, en haut de page. Les fenêtres et feuilles
(`#creer`, `#bibliotheques`) s'ouvrent après le rendu, parce qu'elles lisent l'écran.

**Où l'on prend les liens : Moi › « Liens et raccourcis »**, connecté ou non, sous « Mes collections ». Une rangée par
destination stable (Accès direct, Chercher une aide, Créer une aide, Bibliothèques, Sessions), puis une par
bibliothèque s'il y en a une partagée, puis une par collection. La sous-ligne montre le fragment ; toucher la rangée
DONNE le lien (feuille de partage native, sinon presse-papiers, `giveLink` — le même chemin que « Copier le lien
direct »), elle n'y va pas. Le dépliant « En savoir plus » dit la recette Apple (« Ouvrir les URL ») et la limite iOS.

**Raccourcis de l'icône (manifeste).** Quatre : Accès direct, Chercher une aide, Créer une aide, Sessions (Android en
montre quatre à l'appui long). Le manifeste reste statique : il ne liste pas les épinglées une à une — la forme
écartée par A464 le reste ; c'est le contenu de `#acces-direct` qui est dynamique.

**La limite d'iOS, dite et non contournée.** Sur iPhone et iPad, une app web installée ne capture pas les liens : un
lien ouvert depuis une autre app (Raccourcis compris) s'ouvre en général dans Safari, dont le stockage est distinct de
celui de l'app installée — l'utilisateur y trouve un accueil vide, ou ses seules données synchronisées s'il s'y
connecte. La notice demande donc d'essayer le raccourci une fois avant d'en dépendre. Piste signalée par des retours
d'utilisateurs, **non vérifiée sur appareil** : sous iOS 26, préfixer l'URL par `webapp://` dans l'action « Ouvrir les
URL » ouvrirait l'app installée. Elle n'entre pas dans l'interface tant qu'elle n'est pas mesurée sur un iPhone (et
qu'on ne sait pas si le fragment survit).

**Formes écartées.**
- Une feuille dédiée « Liens et raccourcis » (une fenêtre de plus, auditée par `audit-a11y`) : la zone de Moi suffit,
  c'est l'endroit où l'on règle.
- Une rangée qui navigue au lieu de donner le lien : elle ferait doublon avec « Mes collections » et la colonne.
- Des alias (`#favoris`, `#epinglees`) : un nom par destination, celui que l'interface dit (« Accès direct »).
- Un paramètre de requête (`?go=`) : le fragment n'est envoyé à aucun serveur (même raison que `#j=`, A464).

**Témoins.** `tests.html` (lecture, refus, écriture inverse) ; `audit-doctrine`, section « A586 » : chaque lien par le
vrai point d'entrée (le fragment), la notice d'une collection absente, la règle 11, la copie depuis Moi, la colonne en
large.
