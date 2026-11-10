## A689 — Un document appartient à un seul espace

**Le défaut.** Un espace est « Perso » ou une bibliothèque. L'identité d'un document PDF était
GLOBALE : à la synchro, `_syncAttachments` déduisait le chemin distant d'un fichier de « la dernière
entité vivante qui le cite », et le téléversait dès qu'UNE entité citante était modifiable.

- « Dupliquer dans Perso » (`dupToPerso`) copiait l'élément avec les MÊMES ids de documents :
  l'original et la copie citaient un fichier qui ne vit qu'à un endroit. Selon l'ordre de parcours,
  les autres membres ne pouvaient plus le télécharger, ou la copie dépendait d'un fichier de la
  bibliothèque.
- Une ligne de bibliothèque écrite par quelqu'un d'autre, citant l'id d'un de mes PDF personnels,
  faisait téléverser ce fichier dans la bibliothèque par MON appareil, puis supprimer mon exemplaire
  personnel (audit de sécurité, lot v5.115.1, constat laissé ouvert).

**La règle.**

1. **L'enregistrement local du binaire porte son espace** (`scope` : `''` = Perso, sinon l'id de la
   bibliothèque). Absent sur un enregistrement ancien, il se déduit de `remotePath`
   (`attRecSpace`) ; inconnu (jamais envoyé), le binaire est adopté par l'espace qui le cite.
2. **Seul un geste local le change** : `attClaim`, appelé par `persist` et `persistProtocol`, donc
   par tout enregistrement fait sur cet appareil (publier, déplacer une sélection, convertir en
   collection, dupliquer, réparer). Pour chaque document de l'élément enregistré :
   - même espace → rien ;
   - autre espace, et plus aucun élément vivant ne le cite là-bas → DÉPLACEMENT : le binaire change
     d'espace, l'id est gardé ; la synchro téléverse au nouveau chemin, PUIS met l'ancien en file de
     suppression ;
   - autre espace, et un élément vivant le cite encore là-bas → COPIE : l'élément reçoit son
     exemplaire, sous un id neuf.
3. **La synchro ne déduit jamais un téléversement d'une ligne tirée** (`attPlan`, pure) : elle ne
   téléverse que vers l'espace de l'enregistrement, et seulement si un élément vivant de cet espace
   le cite et que je peux l'éditer. Cité seulement dans un AUTRE espace, un binaire non modifié est
   RÉÉTIQUETÉ sans rien envoyer — celui qui a déplacé l'élément (un autre éditeur, ou moi sur un
   autre appareil) a déjà téléversé. Modifié ici et cité seulement ailleurs, il ne part nulle part.
4. **Ordre déterministe** quand plusieurs espaces citent le même id (`attRefSpaces`) : Perso d'abord,
   puis les bibliothèques par id ; les vivants priment sur les tombes. Deux bibliothèques qui citent
   le même document : il reste où il est, sans va-et-vient.
5. **Suppression distante** : l'ancien chemin n'entre en file qu'APRÈS le téléversement réussi, et
   seulement s'il est chez moi ou dans une bibliothèque que je peux éditer (`attMayDelete`) — à la
   purge d'un binaire que plus personne ne cite aussi.
6. **Binaire absent de l'appareil** : chaque espace citant est essayé au téléchargement,
   bibliothèques d'abord (`attFetchPaths`).

**Les chemins qui changent un élément d'espace**, et ce que chacun fait désormais :

| Chemin | Nature | Documents |
|---|---|---|
| `dupToPerso` (4 entrées de menu), depuis une bibliothèque | copie | exemplaire neuf (`attCopyDocs`) |
| `dupToPerso` depuis Perso | copie dans le même espace | partagés, comme « joindre un PDF déjà présent » |
| `_reclaimBlocked` (droits perdus : copie de secours en Perso) | copie | exemplaire neuf (`attCopyDocs`) |
| Sélection « Déplacer vers… » et « Convertir en collection » (`entsMoveLib`) | déplacement | id gardé ; exemplaire neuf si un autre élément le cite encore au départ (`attClaim`) |
| Sélecteur d'espace de l'éditeur, à la publication | déplacement | idem (`attClaim`) |
| Import d'un autre espace | copie | exemplaire neuf (A669, inchangé ; `attRelink` en est extrait) |
| Import du même espace, « verser dans un protocole » | — | inchangés (même espace ; le versement ne porte pas de documents) |

**Binaire absent au moment d'une copie** (« △ à télécharger ») : `attCopyDocs` tente de le prendre là
où il vit ; s'il n'y parvient pas, la référence est RETIRÉE de la copie et le message le dit
(« n documents non copiés (absents de cet appareil) »). Jamais un id partagé entre deux espaces,
jamais un bouton « Document indisponible ».

**Coûts acceptés** (décision de l'auteur, 10/11/2026) : un PDF dupliqué existe en deux exemplaires
(jusqu'à 15 Mo chacun) et compte deux fois dans le quota de documents ; les deux exemplaires vivent
ensuite séparément.

**Formes écartées.**
- *Garder l'id et arbitrer à la synchro par un ordre de priorité seul* : la fuite reste possible dès
  que mon élément personnel disparaît et que la ligne étrangère reste seule à citer le document.
- *Se fier à l'auteur de la ligne (`updatedBy`)* pour distinguer « mon déplacement » d'« une ligne
  écrite par un autre » : déclaré par le client, et faux pour mes propres appareils.
- *Recopier d'office le binaire dans l'élément de bibliothèque qui le cite* : c'est la fuite
  elle-même, par un autre chemin.

**Limite dite.** Réétiqueter n'efface pas l'ancien objet distant : si une ligne étrangère reste seule
à citer un de mes anciens PDF personnels, l'objet sous `u/<moi>/…` devient orphelin (visible de
l'administrateur par `list_orphan_attachments`) ; le binaire local, lui, est gardé.

## A690 — Réparer l'existant, une fois par espace, sans rien perdre

Les duplications d'avant A689 ont laissé des documents cités à la fois par un élément de Perso et
par un élément de bibliothèque. `attRepairShared`, quatre secondes après le démarrage :

- plan PUR (`attSplitPlan`) : pour chaque tel document, l'élément PERSO vivant reçoit son exemplaire ;
- ordre : copier le binaire → réécrire les références (et les liens `att:`) → enregistrer par
  `persist`/`persistProtocol` (l'élément part « à envoyer ») ; **aucune suppression distante** ;
- un binaire dont le foyer est déjà mon Perso n'est pas copié : il y reste (A689 l'y garde) ;
- binaire absent de l'appareil : la paire est passée et le drapeau `ac-att-split` (par espace, dans
  `WIPE_SPACE_KEYS`) n'est PAS posé — on réessaie au lancement suivant ;
- jamais pendant une session (règle 11), jamais sur un appareil connecté temporairement.

**Écart assumé avec la demande initiale** : seul un élément PERSO est ré-identifié, jamais « le
second exemplaire d'une autre bibliothèque ». Copier d'office un binaire dans une bibliothèque parce
qu'une de ses lignes le cite est exactement ce qu'A689 interdit — la ligne peut avoir été écrite par
un autre. Deux bibliothèques qui citent le même id restent donc en l'état : le document vit dans
l'une, l'autre l'affiche « à télécharger » sans jamais l'obtenir ; le cas ne naît d'aucun geste de
l'application.

**Vérification.** Vingt témoins purs (`tests.html`, « A689-A690 ») et une section de
`audit-upload` sur de vrais enregistrements IndexedDB, réseau bouché dans la page : duplication,
attaque de l'audit (avant et après suppression de mon élément), déplacement, copie au déplacement,
lecteur seul, réparation (binaire absent puis présent). **Non vérifié** : le téléversement et la
suppression réels sur le stockage Supabase (aucune instance dans l'environnement de correction).
