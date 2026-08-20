# Lot v5.16 — plusieurs fichiers d'un geste, des QR lisibles de plus loin

> Doctrine du lot v5.16 — **A225 et A226**. Deux demandes d'usage (20/08/2026) : « pouvoir
> glisser-déposer et ajouter via les clics plusieurs PDF ou images d'un coup (et pourquoi pas
> plusieurs zip ou json pour l'import) » et « augmenter un peu la taille des QR codes pour qu'ils
> soient lisibles plus facilement / de plus loin — pour tous les QR codes ».

## A225 — l'import de données accepte PLUSIEURS fichiers, en FILE, jamais en parallèle

**CONSTAT.** Les images et les PDF acceptaient déjà le dépôt et la sélection MULTIPLES partout
(porte unique v5.0.0 : `upTake` boucle, les preneurs bouclent, `multiple=true` passé aux deux
gestes) — la première moitié de la demande était déjà servie, il n'y avait rien à changer. Le
seul manque était l'import de données (`.json`/`.zip`) : `files[0]` seul, et c'était une
**décision documentée** de v5.11 (« Un seul fichier : importer deux bibliothèques d'un geste n'a
pas de sens, et les questions de destination/fusion sont posées PAR import »). La demande de
l'auteur annule la première moitié de cette phrase ; la seconde moitié — l'argument réel — est
précisément ce que la file préserve.

**DÉCISION.** Plusieurs `.json`/`.zip` d'un geste (sélecteur comme dépôt, dialogue « Créer »
comme accueil), traités **en file séquentielle** : un atelier après l'autre, jamais deux
superposés. Les questions de destination/fusion/doublons restent posées PAR import — c'était
tout l'argument de l'ancienne règle, et il est conservé tel quel. Mécanique :

- `readImportFile(file, pos)` rend désormais une **promesse tenue quand TOUT le parcours est
  fini** (atelier, questions, écritures — ou abandon) ; le corps du `FileReader.onload` devient
  `_importRead(buf, lbl)`. C'est ce qui permet d'enchaîner sans superposer.
- **L'atelier NOMME son fichier** quand plusieurs s'enchaînent : `pos` ({i,n}) fabrique
  l'étiquette « nom.json » (fichier i/n), passée à `importWorkshop` (4ᵉ paramètre) et aux refus
  (« illisible », « pas un export », « rien à importer »). Trois ateliers muets d'affilée ne
  diraient pas lequel montre quoi — et le refus d'un fichier au milieu d'une file doit désigner
  LEQUEL.
- **Annuler un atelier n'abandonne QUE son fichier** : les suivants se présentent quand même —
  chaque import est indépendant, et un refus en cascade silencieux serait pire que trois gestes.
- `openAfter` (méthode IA : ouvrir la fiche importée) ne vaut que pour le **DERNIER** fichier de
  la file : ouvrir chaque fiche au milieu écraserait l'écran au moment où l'atelier suivant
  s'ouvre.
- `FileReader.onerror` est désormais traité (toast + résolution) : dans une file, un lecteur qui
  échoue en silence gèlerait la promesse et donc TOUS les fichiers suivants.

**VÉRIFIÉ** (sonde jetable, Chromium ET WebKit) : sélecteur multiple ouvert par le clic, deux
ateliers en file nommés 1/2 puis 2/2, deux fiches écrites, et l'annulation du premier atelier
qui laisse le second se présenter. La passe complète (`npm run audit`) est restée la porte.

**ADDENDUM v5.16.1 — LE SINGULIER DE GRAMMAIRE SE LIT COMME UNE LIMITE.** Re-signalé après
livraison : « quand je drag plusieurs PDF, ça me montre "déposez UN pdf ou UNE image" et il n'y
a qu'un seul fichier dans la liste ». Trois sondes n'ont PAS reproduit la troncature (sélecteur
multiple, drop DOM synthétique, drop CDP à vrais fichiers — fiche ET protocole, 2, 3 et 5
documents entrés et affichés) : le code prend tout depuis la v5.0.0. Mais le TEXTE, lui, disait
bien « Déposez un PDF ou une image ici » — le `un` de la table (`UP_KINDS[].un`, écrit pour
NOMMER une nature) servait aussi d'invitation, où il se lit comme « un seul à la fois ». La
table gagne un champ `pl` (« vos PDF », « vos images », « vos fichiers .json ou .zip ») :
l'INVITATION (fenêtre de dépôt, sous-titre des zones « plusieurs fichiers à la fois ») parle au
pluriel, le REFUS garde `un` — il désigne UN fichier fautif, et là le singulier est juste.
Leçon : un même mot ne sert pas deux registres (nommer / inviter) — c'est la version textuelle
de « une couleur n'est jamais seule ». Les causes résiduelles d'une troncature RÉELLE chez
l'utilisateur, notées pour le terrain : glisser depuis la barre de téléchargements de Chrome ou
une pile macOS (le drag ne porte qu'UN fichier), un PDF > 15 Mo refusé (toast de 8 s, ratable),
ou une PWA installée servant encore l'ancienne version par son service worker.

## A226 — les QR grandissent d'un cran : la marge se prend en DISTANCE de scan

**CONSTAT.** Tous les QR étaient plafonnés à 200 px — un plafond POSÉ SUR MESURE en v4.47.0
(4,8 px par module à 197 px, relu par le décodeur d'Apple) pour que la carte d'appariement
tienne à 320×568. Mais le seuil de lisibilité n'est pas le confort de lecture : signalé à
l'usage, on scanne souvent à bout de bras, en tendant le téléphone par-dessus un brancard — la
marge au-dessus du seuil s'encaisse en distance et en tolérance d'angle.

**DÉCISION.** Un cran, pas un doublement (« un peu », dit la demande), et chaque contexte garde
son plafond propre :

- `.qr` (base) : 200 → **240 px** ;
- `#shareModal .sh-qr .qr` (partage en ligne) : `min(200px, 52vw)` → `min(240px, 56vw)`.
  **Le palier < 360 px ne bouge PAS** (40vw) : c'est le cas mesuré de v4.47.0 — y grossir le QR
  referait passer « Arrêter le partage » sous la ligne de flottaison ;
- `#shareBody .qr, #jsAnswer .qr` (appariement direct, synchro optique, réponse de l'invité) :
  `min(100%, 200px)` → `min(100%, 260px)` + `height:auto`. 260 et pas 240 : ces QR-là se
  scannent **d'écran à écran**, où chaque pixel compte double (l'appareil photo filme un écran,
  moiré et rafraîchissement compris), et la feuille a la largeur pour. Le `height:auto` empêche
  la hauteur de base (240 px) de letterboxer un SVG dont la largeur suit `min(100%, 260px)`.

Le témoin `audit-partage` « le QR est présent et plafonné » passe de ≤ 200 à ≤ 240 px — le
plafond reste MESURÉ, pas déclaré. `audit-qr` (décodage réel des captures par le décodeur
système) reste inchangé : un QR plus grand ne peut que mieux se décoder, et c'est lui qui le
prouve.
