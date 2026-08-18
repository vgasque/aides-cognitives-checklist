# Lot v5.14 — partage sans serveur (A198-…)

> Lot ouvert le 17/08/2026 sur le GO de l'étude du spike « sonde P2P » (document hors dépôt,
> `.etude-partage-sans-serveur.md` ; maquettes UX figées par l'auteur, artefact claude.ai).
> Feuille de route = § 8 de l'étude : (1) couture `_io` complète · (2) `ShareLocal` sur
> RTCDataChannel, hôte-autorité par époques · (3) appariement QR + décodeur vendorisé ·
> (4) secours chaud pré-apparié, un mot dans le quai · (5) optique « Par l'écran », miroir
> daté + repères annexes · (6) conformité § 3.1 + notice · (7) limites documentées.

## A198 — La couture `_io` est complète : plus un seul appel réseau du partage hors d'elle

**Décision.** Les quatre opérations d'hôte qui appelaient PostgREST en dur — `revoke`
(couper un participant), `_reclaimLead` (reprendre la main), `endShare` (terminer),
`grantLead` (passer la main) — passent par trois nouveaux verbes de la couture `_io` :
`revoke(share,pid)`, `setRole(share,pid,role)`, `end(share)`. `grantLead` et `_reclaimLead`
écrivent le même geste (poser un rôle) : un seul verbe les sert.

**Pourquoi.** La couture `_io` (v4.x) isolait les trois appels du flux nominal
(open/admit/join/pull/push) mais pas les gestes d'hôte : un transport alternatif — l'objet
même de ce lot — aurait dû recopier leur sémantique au lieu de la brancher, et la recopie
est exactement le mode de défaillance que la couture existe pour interdire. Désormais,
implémenter un transport = implémenter HUIT verbes, et rien d'autre.

**Ce qui ne change pas d'un octet.** Les implémentations par défaut émettent les mêmes
requêtes (URL, corps, en-têtes identiques) ; le harnais `audit-partage`, qui intercepte
`rest` et vérifie l'ordre « couper PUIS rendre la main », passe tel quel (134/134) — c'est
la preuve que le fil n'a pas bougé. Hashs CSP rejoués (règle 3), passe d'audit complète
verte (25/25).

## A199 — Le noyau pur du transport local : signalisation compacte, trame RPC, hub d'hôte

**Décision (étape 2a).** Trois pièces PURES, testées une à une (14 témoins, deux moteurs) :
`slSdpExtract`/`slSdpRebuild` (jamais le SDP brut — le quintuple ufrag/pwd/empreinte/rôle/
candidats, aller-retour sans perte, quintuple incomplet → null) ; `slRpcPack`/`slRpcReply`/
`slRpcUnpack` (trame {i,n,p}→{i,r}|{i,e}, l'illisible rend null, jamais d'exception depuis le
fil) ; `slHub` — la sémantique serveur tenue par l'HÔTE : séquence sous compteur unique, dédup
par event_id, **actor déduit du secret** (jamais un paramètre), capacités par `shareCan`
(miroir existant du serveur), empreinte de flux au format exact de `_streamHash`. Le temps
s'INJECTE (`now`) : l'horloge de l'hôte fait foi — il est déjà l'autorité clinique.

**Durcissement assumé** : au hub, un participant coupé perd lecture ET écriture — le § 3.1
notait côté serveur « couper ne retire que l'écriture » comme point à durcir ; entre deux
appareils, on durcit d'emblée. **Piège de vocabulaire payé en route** : `handoff` est un verbe
OUVERT (c'est ainsi qu'un invité ACCEPTE la main) — le témoin de capacité vise `uncheck`,
réellement lead-seulement. Étape 2b à suivre : câblage WebRTC + objet ShareLocal sur les huit
verbes, canal injectable (RTCDataChannel en prod, paire locale au harnais — les portes restent
déterministes, jamais dépendantes de l'état réseau du poste).

## A200 — La couture entière sur un canal injectable : slServe / slClient / slHostIo

**Décision (étape 2b).** Le transport local parle par un CANAL au contrat minimal
`{send(txt), onmessage}` : `slServe(hub, wire)` côté hôte (trame → verbe du hub → réponse,
jamais d'exception depuis le fil), `slClient(wire)` côté invité (les HUIT verbes `_io`,
corrélés par identifiant, TIMEOUT borné — un verbe ne pend jamais), `slHostIo(hub)` pour que
l'hôte parle à son propre hub par la même couture, sans fil. `slWirePair()` fournit la paire
locale des témoins : les portes du dépôt restent DÉTERMINISTES, jamais suspendues à l'état
réseau du poste (leçon VPN du spike).

**Deux économies doctrinales.** (1) La colle WebRTC (RTCPeerConnection, gathering) n'est PAS
posée ici : sans appelant d'interface elle serait du code mort — elle arrive à l'étape 3 avec
la feuille de partage qui l'appelle. (2) Aucun « ping » d'horloge dédié : chaque `pull` porte
déjà `server_time`, le chemin `_sample`/`shareOffset` existant fait de l'horloge de l'hôte la
référence sans un octet de plus. 6 témoins neufs (join/push/pull par le canal, revoke par la
couture hôte, verbe inconnu → erreur nommée, personne en face → timeout).

## Exigence pour l'étape 5 (notée le 17/08, question de l'auteur : « et si les deux téléphones
## n'ont pas la même heure à la minute près ? »)

En ligne et en direct, la question est réglée par construction : `shareOffset` corrige chaque
appareil vers la référence (serveur, ou hôte via le `server_time` du hub — déjà branché, zéro
code). PAR L'ÉCRAN, il n'y a pas d'échantillons : **l'instantané optique doit porter l'heure
d'émission de l'hôte**, et l'invité en déduit un décalage grossier (précision ≈ durée du
transfert, quelques secondes) pour dater ses repères annexes — sans cela, un invité décalé de
deux minutes classerait ses repères au mauvais endroit du journal de l'hôte. L'erreur ABSOLUE
de l'horloge de l'hôte est assumée : une seule ligne de temps cohérente, celle de l'autorité
clinique — l'ordre et les durées sont exacts, les étiquettes murales suivent sa montre.

## A201 — Le décodeur QR entre au vendor : jsQR 1.4.0, sur le motif pdf.js exactement

**Décision (étape 3a).** L'app va SCANNER (appariement direct, synchro optique) ; décoder —
binarisation, perspective, Reed-Solomon en lecture — est hors de portée d'une implémentation
maison raisonnable. jsQR 1.4.0 (Apache-2.0, 256 885 octets, build UMD amont non minifié) est
vendorisé avec TOUTE la discipline du précédent : `vendor/jsqr/` + `README.txt` (version,
taille à l'octet, licence, marche de mise à jour) ; cache SÉPARÉ `JSQR_CACHE` versionné par SA
version (précaché best-effort, jamais bloquant pour l'install) ; chargement PARESSEUX
(`qrDecLoad`, injection `<script>` au premier scan — `script-src 'self'` le permet, jamais au
démarrage) ; routage fetch et purge d'activation étendus. `check-sw` compte ses entrées,
`check-vendor` relie note↔clé↔octets — VÉRIFIÉ CAPABLE D'ÉCHOUER sur la taille ET sur la clé,
puis restauré. `AGENTS.md` (préambule + règle 13) dit désormais DEUX exceptions vendorisées.

**Le témoin est le couple, pas la bibliothèque** : `qrSelftest` encode avec l'encodeur MAISON,
peint, RELIT avec le décodeur vendorisé (chargement paresseux compris) — deux témoins au
commit (charge courte, charge v10 près du plafond), et c'est le même geste qui servira au test
hors-ligne d'une future mise à jour de jsQR.

## A202 — La colle WebRTC : le canal réel derrière le même contrat, témoins sans connectivité

**Décision (étape 3b).** `slPcHost`/`slPcGuest` (RTCPeerConnection à `iceServers:[]` — aucun
serveur, pas même STUN : sur un réseau local les candidats hôte suffisent, validé iPhones),
négociation NON-TRICKLE (rassemblement attendu, plafonné 5 s) pour que l'offre tienne dans UN
code ; `slChanWire` coule le RTCDataChannel dans le contrat `{send,onmessage}` de la couture.
**Doctrine des témoins** : ils vérifient la NÉGOCIATION (SDP reconstruits ACCEPTÉS des deux
côtés, état `stable`, offre invalide refusée nommément) et JAMAIS la connectivité — elle dépend
de l'état réseau du poste (leçon VPN du spike), et une porte de commit doit être déterministe ;
la connectivité, c'est le terrain et la sonde qui la prouvent. 5 témoins, deux moteurs — WebKit
accepte la reconstruction à CHAQUE commit désormais. Reste de l'étape 3 (3c) : l'interface
d'appariement dans `#shareModal` selon les maquettes figées, l'entrée invité, et le branchement
de `Share` sur `slHostIo`/`slClient`.

## A203 — L'assemblage : « Partager » sans compte ou sans internet ouvre l'appariement direct

**Décision (étape 3c).** Le MÊME geste « Partager la session » : sans compte OU sans internet,
la feuille `#shareModal` montre l'appariement direct (l'ancien refus « demande un compte »
cesse d'être un mur). Hôte : QR d'offre (jeton dedans, préflight « aucun réseau local vu » en
notice six mots) → scan de la réponse (caméra éphémère, réponse d'un appariement périmé
refusée à voix haute) → canal → `slServe(hub)` et **`Share.host()` INCHANGÉ sur `slHostIo`** ;
multi-invités par « Inviter un autre » (offre+jeton neufs, même hub). Invité : `#joinScreen`
gagne « Scanner le code de l'hôte » → réponse en QR → **`Share.joinByCode()` et TOUTE la
machinerie invitée existante courent sur le canal** (le join local ignore le code : la porte,
c'est le canal apparié). Vocabulaire à l'écran : « en direct », jamais WebRTC/P2P.

**Payé en route, et c'est la leçon de l'étape** : la charge d'appariement compressée
(deflate+b64) DÉBORDAIT d'un code QR dès qu'un candidat mDNS s'invitait — ufrag, pwd,
empreinte et UUID sont de l'ENTROPIE, deflate n'y mord pas. `slPairPack`/`slPairUnpack`
empaquettent en BINAIRE (IPv4 6 o, mDNS 18 o, empreinte 32 o bruts, l'illisible rend null) :
~95 octets, un code avec marge. Le témoin de taille est SYNTHÉTIQUE et figé (pire cas courant,
mDNS + IPv4) — jamais l'offre de l'environnement, qui varie d'un poste à l'autre.

**Restes nommés de l'étape 3** (pas des oublis) : harnais UI de l'appariement local (machine à
états pilotée par charges synthétiques, sans caméra) ; fermeture de la feuille pendant
l'appariement = pc abandonné sans fuite bruyante mais sans nettoyage exhaustif ; billet de
reprise invité inopérant en local (rechargement → ré-appariement, cohérent avec l'étude M6).

## A204 — Étape 4 : la bascule est un ré-appariement dit d'avance ; le quai n'a rien à apprendre

**Décision.** Deux boutons symétriques, deux dialogues qui disent le prix AVANT : la feuille
cloud gagne « Passer en direct… » (fin du partage serveur → appariement local, mêmes gestes) ;
la feuille locale gagne « Passer en ligne… » (visible seulement si compte + internet). Toujours
un RÉ-APPARIEMENT propre — jamais une migration à chaud : l'état de l'hôte est la source, les
participants re-scannent/re-rejoignent, la session de l'hôte ne bouge pas d'un pixel.

**Le quai n'a RIEN eu à apprendre, et c'est une découverte d'architecture** : ses mots (`figé`,
`coupé`, `⇄N`, `main`/`suit`) émergent de la péremption et des statuts, pas du transport — en
local, un canal mort produit `figé` par la même mécanique que le cloud. Le transport se lit dans
la FEUILLE (« ✓ En direct — sans serveur »), le quai reste la zone d'état à position constante.

**DÉFÉRÉ, et pourquoi** : le secours chaud pré-apparié (M9 — signalisation du canal via le
relais pendant que le cloud marche) exige un CANAL DE SIGNALISATION côté serveur
(schema.sql + rejeu sur l'instance = geste de l'utilisateur). Inscrit comme exigence de la
prochaine évolution serveur, avec la bascule AUTOMATIQUE qui en dépend. La bascule manuelle
ci-dessus est le régime intermédiaire assumé.

## A205 — Étape 5 : « Par l'écran » — la synchro optique entre dans l'app

**Décision.** Le canal du ZÉRO réseau, porté de la sonde avec ses trois leçons de terrain :
fontaine SYSTÉMATIQUE (les k blocs dans l'ordre puis ⌈k/4⌉ réparations — la fontaine naïve
perdait contre un carrousel, mesuré), trames binaires AUTO-DESCRIPTIVES 18+195 o (accrochage
sur n'importe quelle trame, redémarrage détecté par graine), QR en mode octet à masque épinglé
(`qrEncodeB` ; `qrSvg` refactorisé en `qrSvgQ`+wrapper, rendu inchangé à l'octet).
La CHARGE porte les deux invariants gravés au lot : {sess, fiche (projection liste blanche),
at (heure d'émission de l'hôte, `Share.now()`), snap}. Émission : « Par l'écran… » dans la
feuille locale (offre ET live) — 6 codes/s, arrêt d'un tap. Réception : « Recevoir par
l'écran » dans #joinScreen — jauge qui ne descend jamais, puis MIROIR DATÉ (annonce « Vue à
HH:MM — miroir, pas du direct ») via `openSharedFiche()` inchangé (Share.fiche/fold posés,
offset grossier = at − horloge locale : des horloges décalées de minutes se rattrapent à
l'épaisseur du transfert).

**L'invariant qui refuse** : une émission dont l'identité n'est pas MA session vive (ou mon
miroir précédent de la même session) = un message, ZÉRO écriture — la doctrine « Continuer
seul » (fusion inter-sessions = faux plausible) appliquée à l'optique. Témoins : charge
optique (identité+fiche+heure), transfert simulé 30 % de pertes + ordre mélangé → intègre,
trame étrangère → null, QR binaire 213 o. RESTES nommés : pas de retour invité→hôte (repères
annexes optiques — exigera le format et le geste symétriques), pas d'a11y dédiée aux nouveaux
états de feuille (états, pas fenêtres), débit non re-mesuré in-app (le spike fait foi :
20 Kio ≈ 4 s).

## A206 — Étapes 6-7 : la conformité dit les deux régimes, les limites sont écrites

**Décision.** La notice de `#joinScreen` (« Où et combien de temps ») distingue désormais les
trois canaux : en ligne = relais Supabase purgé ; en direct / par l'écran = « rien ne quitte
les appareils présents — réseau local chiffré ou lumière de l'écran, sans serveur ni tiers ».
Le registre gagne un **§ 3.2** (docs/deploiement-et-conformite.md) : pour les modes sans
serveur, la ligne destinataires/sous-traitants est VIDE, les durées serveur sont sans objet,
l'hôte tient l'autorité que le serveur tenait — et les QUATRE limites mesurées au spike sont
écrites (app déjà installée requise ; réseau local commun exigé, isolation/VPN/« Réseau
local » iOS ; verrouillage = suspension, réparée par ré-appariement ; « par l'écran » = synchro
par geste, ~20 Kio ≈ 4 s). Notice et registre évoluent ensemble, ou aucun (règle 15).
Le § 2 (statut non-DM) n'a pas bougé : les deux modes RECOPIENT — l'un par le réseau local,
l'autre par la lumière — et ne déduisent rien ; le miroir daté affiche une heure, jamais une
alerte d'âge.

**LE LOT v5.14 A SES SEPT ÉTAPES.** Restent, hors lot et nommés : le harnais UI de
l'appariement/optique (charges synthétiques), le secours chaud M9 (canal de signalisation
serveur + rejeu = geste utilisateur), le retour optique invité→hôte (repères annexes), la
release `./release.sh 5.14.0` + CHANGELOG, et le TEST TERRAIN à deux iPhones du flux intégré.

## A207 — v5.14.2 : le premier passage réel corrige neuf défauts d'assemblage

L'auteur a essayé la v5.14.0 en conditions réelles : neuf défauts, tous corrigés le jour même
(détail au CHANGELOG 5.14.2). Les leçons durables : (1) **une entrée hors ligne doit exister
AVANT la fonctionnalité** — l'écran « Rejoindre » n'était joignable que par code/lien, donc par
internet ; il vit désormais au menu de l'accueil ; (2) **deux régimes de feuille ne partagent
pas un minuteur de re-rendu** — le `_shTimer` de la feuille cloud repeignait par-dessus la
feuille locale (le « deux clics ») : tout changement de régime commence par `closeShareSheet()` ;
(3) **un état d'interface se REGARDE, ne se mémorise pas** — `SL.live` mentait après « Arrêter » ;
la garde est `slLiveOk()` (mode+statut de `Share`), jamais un drapeau local ; (4) **chaque
ouverture d'écran repart d'un état propre** — un bouton grisé n'est jamais un verrou définitif ;
(5) le harnais a attrapé la seule dérive maquette mesurable (QR > 200 px) — les huit autres
étaient INVISIBLES aux portes : l'essai réel reste la dernière porte, comme au spike.

## A208 — v5.14.3 : la conformité aux maquettes se VÉRIFIE à la capture, pas à l'intention

L'auteur a comparé l'implémentation aux maquettes figées : « pas du tout respecté ». Reprise
composant par composant, chaque état CAPTURÉ dans le navigateur avant release : écran de scan
PLEIN ÉCRAN unique aux quatre usages (visée quatre coins, quatre mots, flash vert + vibration,
Annuler fixe — piège payé : `hidden` n'est pas une propriété des éléments SVG, la jauge restait
invisible) ; jauge anneau de réception (peinture seule) ; segmenté « Mode » (composant
`statuseg` existant) dans LES DEUX feuilles avec l'indisponible expliqué ; point pulsant ;
patron refus caméra (un bouton qui répare + l'échappatoire) ; le mot du quai « ● Session » →
« ● Direct » (un mot, 18 caractères ECAM) ; « Rejoindre une session » en voie ÉTROITE du pied
de page (patron histBtn — la sidebar n'existe pas sur mobile/tablette). Cliquet
pointer-events:none monté à 20 (flash = annonciateur pur, A68/4). MÉTHODE RETENUE : une reprise
d'interface se clôt par des captures d'écran état par état contre la maquette — l'intention ne
compte pas, le pixel oui. Restes nommés au CHANGELOG (fondu du mot du quai, écran 09a, badge
09b, fondu inter-codes écarté sciemment).

## A209 — M9 : le secours chaud — la bascule qui n'existe pas

**Décision (v5.14.5, GO de l'auteur).** Pendant qu'un partage EN LIGNE fonctionne, l'invité
propose en silence un canal direct (évènement `sig` via le relais : offre compacte slPairPack),
l'hôte répond, le canal s'ouvre et DORT. À deux échecs de sondage (~10 s), l'hôte rejoue le
geste manuel ÉPROUVÉ (stop → hub → Share.host() : le diff initial rembobine tout l'état — zéro
machinerie de fusion neuve), sert les canaux dormants ; l'invité re-joint par le sien et
reconstruit son pli. Le quai passe à « ● Direct », une annonce d'une phrase, rien d'autre.
Retour au cloud = un TAP (le sens panne est automatique, le sens confort est un choix).
L'invité n'amorce JAMAIS pendant une panne (l'offre passerait par un relais muet) ; un join
raté garde le canal pour la détection suivante — le rythme est celui du sondage, jamais une
boucle serrée.

**Trois garde-fous ont travaillé** : check-sql (parité client/serveur des capacités — `sig`
ajouté aux DEUX vocabulaires, 20/20) ; le témoin « tout genre est classé » (a EXIGÉ le régime
`sig:'none'`) ; le pli ignore `sig` (témoin dédié — jamais dans le journal ni le compte-rendu).
**⚠ schema.sql À REJOUER sur l'instance** (le serveur refuse `sig` jusque-là — le secours ne
s'amorce pas, rien d'autre ne change). Registre § 3.2 complété : les descripteurs du canal
(adresses IP locales) transitent par le relais pendant la préparation, purgés comme le reste.

## A210 — La bascule MANUELLE emprunte les canaux dormants (personne ne re-scanne)

**Signalé à l'usage (v5.14.8)** : « lorsque je switche en ligne → en direct, tous les
participants sont déconnectés ». Le secours chaud (A209) pré-apparie les canaux directs pendant
que le cloud marche — mais le geste MANUEL du sélecteur les ignorait et repartait sur du QR :
la même destination par deux chemins, dont un cassé. Corrigé en réutilisant le chemin éprouvé :

- **`sig {t:'go'}`** — le réseau marche encore au moment du geste, donc l'hôte PRÉVIENT :
  l'évènement est poussé DIRECTEMENT (hors file, `_io.push` immédiat) avant la transition ;
  les invités le reçoivent à leur cadence de sondage (≤ 5 s) et re-joignent par leur canal
  dormant. Aucun QR, aucun geste invité.
- **La transition hôte est CELLE de la panne** (`slSbHostSwitch`, inchangée) — pas un second
  mécanisme à fiabiliser ; seule l'annonce diffère (« Le partage passe en direct — les
  participants suivent. » au lieu de « Le réseau a lâché »).
- **Tentatives espacées côté invité** : l'hôte sert peut-être une ou deux secondes APRÈS le
  join — trois essais à 2 s couvrent la course (jamais de boucle serrée). Un échec garde le
  canal, comme en A209.
- **Le partage cloud est TERMINÉ côté serveur après coup** (meilleur effort, `_ioRest.end`) :
  pas de session zombie jusqu'au TTL, et un invité SANS canal dormant voit l'écran « partage
  terminé » existant — pas un silence.
- **Le dialogue dit la vérité AVANT le geste** : « les participants basculent automatiquement »
  si tous les canaux dorment, « N sur M basculent, les autres devront scanner » sinon, et
  l'ancien texte (chacun re-scanne) uniquement quand AUCUN canal n'est prêt — l'honnêteté du
  compte remplace une promesse uniforme.

**Limite nommée** : le sens retour (direct → en ligne) reste un re-appariement par code — le
canal direct ne peut pas distribuer de nouveaux secrets cloud sans machinerie d'admission
inverse ; à ouvrir si le besoin se confirme sur le terrain.

## A211 — Les deux sens de bascule tiennent, prouvés de bout en bout (E2E réel au harnais)

**Signalé à l'usage (v5.14.9)** : « ne fonctionne pas ; inversement non plus » — la v5.14.8
avait raccordé la bascule manuelle aux canaux dormants sans JAMAIS exercer la chaîne complète
(seules ses briques étaient testées). La section E2E d'`audit-partage` la joue désormais en
entier : deux PAGES réelles dans un même contexte, un relais en mémoire (slHub +
BroadcastChannel) qui joue Supabase, et de VRAIS `RTCPeerConnection` entre les pages — la
première exécution a reproduit l'échec du terrain, puis chaque correctif s'est vérifié contre
elle (9/9).

- **La montre de 30 s** : un échec ICE laissait le verrou d'appariement (`slSb.pc`) posé À
  JAMAIS — plus aucune tentative ensuite, secours mort en silence. Canal jamais ouvert → on
  jette, et le prochain sondage sain re-propose. Les canaux FERMÉS se purgent des deux côtés
  (`onclose`), et le compte du dialogue ne compte que les canaux réellement OUVERTS.
- **La pastille « En direct » dit l'état RÉEL du canal dormant** (verte = prêt) — c'est aussi
  le diagnostic de terrain : si elle ne verdit jamais, l'appariement silencieux échoue sur ce
  réseau (mDNS/Bonjour filtré ?) et la bascule sans QR ne peut pas suivre — le parcours QR
  reste alors le chemin, et le dialogue le dit.
- **Sens direct → EN LIGNE sans re-saisie** : un code cloud n'a qu'un LOGEMENT et meurt à la
  première entrée — l'hôte sert donc les invités UN PAR UN (`admit` → billet `sig {t:'gc',to,
  code}` poussé par le hub encore branché → attente de l'entrée → suivant). Échec d'ouverture
  cloud (internet menteur) : on RE-HÉBERGE sur le MÊME hub — les secrets des invités restent
  valides, le nouvel instantané complet est idempotent au pli, personne n'est déconnecté. Le
  hub survit 20 s après la migration puis se ferme : un invité resté local voit « partage
  terminé », jamais un silence.
- **Le canal dormant ne se propose que sur le transport SERVEUR** (`_io === _ioRest`) — en
  mode direct, l'offre partirait dans le hub local pour rien.
- **Artefact de banc nommé** : Chromium headless masque les IP locales derrière des noms mDNS
  mais ne fait tourner AUCUN répondeur — ICE échoue à coup sûr entre deux pages. Le harnais
  lève l'obfuscation (`--disable-features=WebRtcHideLocalIpsWithMdns`) DANS LA SECTION
  SEULEMENT ; en production, Safari/Chrome embarquent Bonjour.

## A212 — L'invité déconnecté re-rentre en un geste ; un seul œil pour trois codes

- **« Rejoindre à nouveau… »** sur l'écran gelé de l'invité (terminé, expiré) : quitte sans le
  dialogue de départ (le partage est déjà mort) et rouvre l'écran d'entrée. JAMAIS sur
  « retiré » : reproposer l'entrée à quelqu'un qu'on vient de couper expressément contredirait
  la décision du conducteur (exigence explicite de l'auteur).
- **Scanner UNIQUE à l'écran d'entrée** (« ne peut-on pas simplifier avec un seul bouton ? ») :
  un bouton, trois familles reconnues au FORMAT — trame optique (binaire 0xF7 → fontaine,
  jauge), offre d'appariement (« SO: » → réponse à faire scanner), code du partage en ligne
  (lien `#j=` ou code nu → jointure serveur, rédaction « scanné » au refus). C'est le payload
  qui décide, jamais un réglage ; une fontaine en cours n'est pas interrompue par un autre code
  aperçu dans le champ.

## A213 — La mise à jour se DEMANDE, elle ne fait plus que s'annoncer

**Signalé à l'usage (v5.14.10)** : « il ne me prévient plus tout le temps quand des mises à
jour sont dispo ». Deux défauts, un ancien et un structurel :

- **Le créneau #sysBanner est PARTAGÉ et le bouton était à qui l'avait pris en dernier** : les
  écrivains « fiches d'exemple » (v5.0.0) et « code de session reçu » (v4.47.0) réaffectent
  #sbReload (« J'ai compris », « Rejoindre ») ; l'écrivain « Nouvelle version », premier arrivé
  historiquement, ne restaurait RIEN — après un passage des autres (fréquent depuis les tests
  du partage v5.14), son bandeau s'affichait avec un bouton qui ne rechargeait plus. RÈGLE :
  chaque écrivain du bandeau pose texte ET action, toujours (`sbNewVersion`).
- **L'annonce à l'activation ne touche que les pages OUVERTES à cet instant** : une activation
  app fermée (cas fréquent en PWA iOS — la vérification de sw.js court en parallèle du
  lancement) était perdue À JAMAIS, et personne ne redemandait. GUICHET DE VERSION dans sw.js
  (`{type:'sw-version'}` → réponse du même type) : la page interroge le worker au chargement et
  à chaque retour au premier plan. La réponse porte un type DISTINCT de `sw-activated` pour
  rester SILENCIEUSE quand les versions concordent — l'égalité est l'état normal, pas une
  nouvelle ; seule une discordance affiche le bandeau. Prouvé sous sonde dynamique (vrai worker,
  vraie page contrôlée : réponse `aides-cognitives-v5.14.9`, bandeau resté caché sur égalité,
  bouton « Recharger »).
