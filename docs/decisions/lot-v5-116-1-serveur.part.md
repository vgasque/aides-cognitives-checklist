## A691 — `link-claim` : ce qu'elle rend, et ce qui la borne (fonction à redéployer)

Deux constats de l'audit de sécurité sur la seule pièce qui tient la clé de service.

1. **Elle rendait l'objet utilisateur ENTIER de GoTrue** (adresse, identités, métadonnées, dates),
   alors que son en-tête disait « l'e-mail ne sort jamais d'ici ». L'app ne lit de l'utilisateur que
   `id` (l'espace local du compte) et `email` (affichée sur le poste, et signature des modifications
   qu'on y fait) — vérifié sur tous les `Auth.user()` du fichier. La fonction ne rend plus que ces
   deux champs. L'en-tête est corrigé : l'adresse SORT, vers le poste que son titulaire vient
   d'approuver, et tout rafraîchissement de jeton la lui rendrait de toute façon. Le registre RGPD
   (`docs/deploiement-et-conformite.md` § 3.3) affirmait la même chose inexacte : rectifié.
2. **Aucune borne.** Ce qui se borne, et où :
   - une requête à clé FAUSSE ne coûte qu'une lecture par clé primaire et une empreinte, et n'écrit
     rien (la clé est vérifiée avant tout, A679) — rien à ajouter ;
   - une clé JUSTE pouvait réclamer sans fin pendant deux minutes, et chaque réclamation fait
     fabriquer une session par GoTrue : **cinq réclamations au plus par lien** (`device_links.claims`),
     comptées EN SQL, après la clé. La fonction est sans état ; le compteur tient d'une instance à
     l'autre et part avec la ligne (purge existante) ;
   - le corps de la requête est borné à 1 Kio.

**Pourquoi pas un compteur par adresse.** Il ne peut pas tenir les trois exigences à la fois : compté
avant la clé, il laisse quelqu'un derrière la même adresse de sortie (un hôpital entier sort souvent
par une seule) bloquer les postes des autres ; compté après un échec, il n'épargne aucun travail (la
lecture a déjà eu lieu) et en AJOUTE (une écriture par requête). Le compteur par lien, lui, ne bouge
que pour qui tient la clé du poste : personne ne l'épuise à la place d'un autre.

**Ce que la fonction ne peut pas borner** : le nombre de ses INVOCATIONS. Une limite par adresse se
règle à la passerelle du projet (hébergeur), pas dans le code.

**Signature inchangée** (`link_claim_srv(uuid, text)`) : ancienne fonction et nouveau schéma
s'entendent, et l'inverse aussi. Ordre conseillé : schéma, puis fonction.

**Non vérifié** : la fonction ne s'exécute pas dans l'environnement de développement (ni Deno, ni
Supabase). Le changement tient en trois endroits, relus ligne à ligne.

## A692 — Sur un appareil temporaire, la règle « créer, modifier » couvre aussi les catégories partagées, les notes et le suivi

Noté « à décider » depuis A663 : sous « modification interdite », un poste réécrivait encore les
catégories d'une bibliothèque, les notes personnelles et le suivi.

**Décidé.** La règle dit « cet appareil ne modifie pas le compte », pas « pas les aides ».
- **Catégories d'une bibliothèque, suivi (pour moi comme pour l'équipe), notes personnelles** : même
  règle que les aides et les protocoles — refusés sous « interdit » (`poste_forbidden`), soumis à la
  fenêtre d'écriture sous un verrou ou « confirmer » (A693). Déclencheurs `*_temp_guard` sur
  `category_sets` (lignes de bibliothèque), `aid_followups`, `aid_notes`.
- **Le document PERSONNEL de `category_sets` reste ouvert à un poste.** L'app l'écrit SEULE, sans
  geste : l'usage récent des aides à chaque ouverture, les préférences reçues recopiées telles
  quelles (A647). Le fermer casserait la synchro d'un poste en silence. Catégories personnelles,
  épingles et collections vivent dans ce même document : sur un poste, c'est l'app qui les garde,
  pas le serveur — limite dite.
- **Une suppression ne modifie pas.** Sous « modifier : interdit » et « supprimer : permis », un poste
  changeait le contenu dans la MÊME écriture qui supprimait (une politique ne voit que la ligne
  nouvelle). Depuis un poste, une suppression garde désormais le contenu, la bibliothèque et le
  propriétaire d'avant, quelle que soit la règle (`temp_guard_doc`).

**L'app suit** (sinon le serveur refuserait en silence ce qu'elle laisse saisir) : ouvrir l'éditeur de
suivi, cocher une tâche, convertir une collection en tâches, écrire une note personnelle et ouvrir le
gestionnaire de catégories dès qu'il montre une bibliothèque passent par `linkGate` (nouveau
`linkThen` pour les gestes courts). Sous « interdit » : refusé, et dit pourquoi ; sous un verrou :
« Déverrouiller » ; sous « confirmer » : un accord par geste. Administration › Règles nomme ce que la
règle couvre : « aides, protocoles, catégories partagées, notes et suivi ».

**Formes écartées.** (1) Fermer aussi le document personnel sous « interdit » : synchro du poste
cassée, usage récent perdu. (2) Y comparer catégories et collections champ par champ dans un
déclencheur : le serveur annulerait en silence ce que l'écran montre fait. (3) Traiter un suivi
supprimé comme une « suppression » (règle `del`) : ce n'est pas la suppression irréversible d'une aide
que cette règle vise.

## A693 — La confirmation d'un appareil temporaire est appliquée par le serveur

Le verrou d'un poste rouvert et « confirmer sur un appareil connecté » n'existaient que dans l'app
(un drapeau `sessionStorage`) : avec la console du navigateur, ou le jeton du poste, on écrivait
sans téléphone tout ce que la règle ne faisait que soumettre à confirmation. A654 l'avait laissé à
l'app parce que « le serveur ne sait pas dater le geste ». Il sait dater un ACCORD.

**La fenêtre d'écriture.** Par poste, sur sa ligne `device_links` :
- `unlocked_until` (créer, modifier) — ouverte à la connexion du poste (`link_bind_srv`, `link_self`)
  et à chaque demande `unlock` approuvée (`link_approve` ; la demande retient le poste qui la pose,
  `target`). Durée : celle que l'app applique déjà — **15 min** sous « verrou 15 min », **5 min** sous
  « verrou 5 min » et « confirmer ». Elle se PROLONGE tant qu'on se sert du poste (`link_touch`,
  appelée par l'app au plus toutes les 30 s pendant qu'il y a des gestes) et seulement tant qu'elle
  est encore ouverte : sans geste, elle se referme seule, et seul un nouvel accord la rouvre ;
- `del_until` (supprimer) — **5 min** après un accord, jamais prolongée.

Hors fenêtre, le serveur refuse aides, protocoles, catégories partagées, notes et suivi par une
**erreur nommée** (`poste_locked`, HTTP 400), et le dépôt d'un document par sa politique (403).

**Pourquoi une erreur nommée et pas une politique.** L'app traite un 403 sur l'espace personnel comme
« identifiant déjà pris par un autre compte » et RENOMME l'élément pour réparer. Un refus de verrou
en 403 aurait renommé l'aide à chaque synchro, sur tout poste pas encore à jour.

**Jamais retenus** : la table `sessions` (sauvegarde d'une session en cours, A645 ; sessions terminées)
et le dépôt par la clé du poste (`link_deposit`). Testé (§ 21.2).

**Côté app — mêmes gestes qu'avant en usage normal.** Avant d'envoyer, la synchro lit l'état
(`linkHold`) et RETIENT ce que le serveur refuserait (`linkSkip`) : rien ne part, rien ne se perd,
aucune erreur. Sous un verrou, une fenêtre trouvée fermée reverrouille l'onglet (« Déverrouiller »,
déjà là) ; sous « confirmer », la bande de l'accueil dit « des modifications attendent l'accord d'un
appareil connecté pour partir » et offre **« Confirmer pour envoyer »**. L'accord reçu, ce qui
attendait part seul. Un refus qui passerait quand même (course) n'est ni une pastille rouge ni une
relance en boucle (`linkHeldErr`).

**Ce qui change pour l'utilisateur** : seulement hors ligne. Une modification faite sur un poste sans
réseau partait à son retour ; si la fenêtre s'est refermée entre-temps, elle attend désormais un
accord. C'est la conséquence directe de la règle : le serveur ne peut pas distinguer cet envoi
tardif d'un envoi fait sans téléphone.

**Ce qui reste à l'app, et pourquoi — dit, pas maquillé.**
1. **Le verrou de RÉOUVERTURE.** Le serveur ne sait pas qu'un onglet a été fermé puis rouvert : dans
   les minutes où la fenêtre est encore ouverte, un onglet rouvert est verrouillé à l'écran et pas au
   serveur. Au-delà (5 ou 15 min sans geste), les deux le sont.
2. **« À chaque fois ».** Sous « confirmer », le serveur exige un accord dans les 5 minutes
   (prolongées tant qu'on travaille dans l'éditeur ouvert par cet accord), pas un accord par geste.
   Supprimer est plus strict : 5 minutes, jamais prolongées.
3. **Qui tient le poste pendant la fenêtre peut la prolonger** (`link_touch`) : c'est exactement ce
   que permet déjà un onglet resté déverrouillé. La fenêtre ne protège pas d'une personne assise
   devant le poste déverrouillé ; elle ferme le poste laissé seul, et le jeton copié.
4. Les **interdits fixes** (administration, membres, suppression du compte) étaient déjà au serveur.

**Compatibilité, dans les deux sens.**
- *App à jour, serveur pas encore rejoué* : `link_touch` n'existe pas, l'état reste inconnu, rien
  n'est retenu — comme avant. Les portes nouvelles (notes, suivi, catégories) s'appliquent à l'écran.
- *Serveur rejoué, app pas encore à jour sur un poste* : elle ne prolonge pas la fenêtre. Passé 5 ou
  15 minutes après la connexion ou le dernier accord, ses envois sont refusés (HTTP 400) : elle
  affiche « Erreur inattendue — poste_locked », garde tout sur l'appareil, ne renomme rien, et
  reprend seule une fois mise à jour (au lancement suivant) ou au prochain accord. Refus fermé, rien
  de corrompu ; le message n'est pas beau, il est vrai.

**Formes écartées.** (1) Une fenêtre fixe après l'accord, sans prolongation : sous « verrou 15 min »,
on aurait redemandé le téléphone toutes les 15 minutes à quelqu'un qui travaille sans s'arrêter — un
geste de plus, contre la consigne. (2) Faire porter l'heure du geste par l'app : c'est elle qu'on ne
croit pas. (3) Fermer aussi les sessions hors fenêtre : un compte rendu de soin ne se perd pas pour
un verrou. (4) Refuser par politique (403) : cf. la réparation d'identifiant. (5) Verrouiller le
dépôt d'un document par un déclencheur sur `storage.objects` : table de l'hébergeur — une politique
suffit, au prix d'un 403 que l'app sait, sur un poste retenu, ne pas prendre pour une panne.

**Vérification.** `supabase/rls-tests.sql` § 21 (21.1 à 21.8), sur PostgreSQL 16 local à bouchons ;
chaque garde retiré, le test correspondant rougit (cinq témoins négatifs). `audit-lier` § 10 :
retenue, reverrouillage, envoi après accord, bande sous « confirmer », portes sous « interdit ».
