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
