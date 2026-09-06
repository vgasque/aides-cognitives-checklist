# Lot v5.26 — il reste un geste après avoir ouvert une carte : le quai le dit (A331)

> Fichier normatif, suite de [`lot-v5-25.md`](lot-v5-25.md) (A330). Les numéros A sont des
> adresses : ne jamais renuméroter. Demande de l'auteur (06/09/2026) : « c'était un moyen de
> centrer l'attention sur le fait qu'il faille faire une action supplémentaire après avoir ouvert
> une carte sur la page d'accueil pour démarrer la session » — le fondu en boucle du bouton avait
> été écarté (WCAG 2.2.2) ; maquettes et démonstration rejouable validées sur canvas.

## A331 — l'arrivée sur une fiche : le quai se relève, trois anneaux, une bulle (v5.26.0)

**Le problème.** Le nouveau venu ouvre une carte, croit être « dedans », et ne comprend pas que
rien ne commence tant qu'il n'a pas tapé « Confirmé — démarrer la session ». A330 a rendu la
page lisible comme un écran de démarrage ; il restait à faire VOIR le geste.

**Ce qui est REFUSÉ, et pourquoi** (ne pas reproposer) :
- **le fondu en boucle du bouton**, ou un anneau infini : un mouvement automatique de plus de
  5 s exige un moyen de l'arrêter sur la page (WCAG 2.2.2, niveau A) ; l'arrêt au démarrage ne
  compte pas, le réglage système « réduire les animations » n'est pas un mécanisme de la page ;
- **une onde bleue qui déborde du quai** sur le gris de la page : invisible ET laide (auteur) ;
- **un anneau DANS le bouton** (contour blanc qui grandit du centre) : « pas très joli » ;
- **un carré rouge devant « Confirmé »** (marque du chapitre reprise) : casse la règle d'une
  seule masse colorée, n'apprend rien après la première fois ;
- **une ligne grise de 12 px** ou **la notice bleue** de l'app à la place de la bulle : trop
  discrète, ou mal placée — le principe retenu est « au-dessus du bouton d'intérêt ».

**Ce qui est retenu — deux signaux, aucun ne boucle.**
1. **L'arrivée du quai** (`#sessionDock.sd-arrive`, posée par `syncDock` UNE fois par ouverture
   de fiche — `_dockArriveFor` — jamais rejouée au re-rendu, retirée dès que le quai n'est plus
   celui d'avant-session) : la capsule se relève de 14 px en 280 ms (à 200 ms), puis **trois
   anneaux** s'en éloignent de 12 px et s'effacent — 0,9 · 2,2 · 3,5 s, fini à 4,8 s, sous les
   5 s. L'anneau est un `box-shadow` sur `.sd-in::after` : il entoure la CAPSULE ENTIÈRE, donc ne
   touche jamais la touche Exercice ni le bouton, et il prend l'encre du quai (`--dock-ring` :
   sombre le jour, clair la nuit — un signal, pas un registre). Transform, opacity, box-shadow
   seulement (peinture et composition, `check-anim`) ; nul sous `prefers-reduced-motion`.
2. **La bulle d'apprentissage** (`#dockHint`, matière travail, pointe vers le bouton, 16 px
   au-dessus de la capsule — au-delà des 12 px de l'anneau, mesuré : aucune superposition) :
   « Rien n'est lancé tant que vous consultez. — Étapes, minuteurs, partage : « Démarrer la
   session ». » Affichée tant qu'aucune session n'a été démarrée sur l'appareil (clé globale
   `ac-start-hint`, posée dans `startSessionGesture` — même régime que `ac-theme`, non effacée
   par « Effacer tout » : c'est un apprentissage de l'appareil, pas une donnée), puis plus
   jamais. Statique, hors 2.2.2. Elle entre dans la mesure de `--dock-h` ; la réserve de bas de
   page suit (`body.dock-hint`, 158 px = 84 + 58 de bulle + 16 d'écart).

**« Exo. » sous 430 px** (demande de l'auteur) : la touche Exercice perdait son mot ; elle garde
une TRONCATURE du même mot, « Exo. » (`.dp-lbl-s`, second libellé masqué ailleurs) — la règle
« un seul libellé à toutes les largeurs, une abréviation est une troncature, jamais un autre
mot » tient.

**Mesuré** (390 et 1440 px, thème clair) : bulle centrée sur la capsule au pixel (centres 195 et
680), classe `sd-arrive` posée, animations `sd-in-arrive` + `sd-ring` en cours, réserve 158 px ;
« Exo. » affiché à 390, « Exercice » à 1440 ; après « Confirmé » : bulle masquée, clé posée.
⚠ Piège de mesure : le pane MASQUÉ gèle les animations à leur première image (document.hidden) —
l'écart bulle-capsule y lit 30 px (16 + 14 de relèvement) ; la chronologie s'est vérifiée sur la
page de démonstration rejouable, pane visible.

**Garde-fous** : `check-anim` — cliquet `pointer-events:none` monté à 23 (l'anneau est un
annonciateur pur) ; `check-tokens` (`--dock-ring` déclaré et lu) ; `check-classes` / `check-ids`.

**Addendum v5.26.1 (demande de l'auteur).** Le RELÈVEMENT du quai est retiré : seuls les trois
anneaux restent, et ils partent un temps APRÈS l'affichage de la page, jamais d'emblée — 800 ms,
puis 0,8 · 2,1 · 3,4 s, fini à 4,7 s (toujours sous les 5 s). `@keyframes sd-in-arrive` purgé ;
`.sd-arrive` ne pilote plus que `.sd-in::after`. La démonstration rejouable garde son relèvement
à titre d'archive ; l'app fait foi.

## A332 — ce que la panne fait aux gestes : file de l'hôte, retour sans invité, reprise repeinte, arrêt daté (v5.26.2)

**Signalé par l'auteur** (06/09/2026) : (1) « arrêté depuis » ne s'affiche que chez celui qui a
arrêté le minuteur — est-ce par design ? (2) que se passe-t-il quand un participant perd internet
mais garde le Wi-Fi (portail captif), à un ou plusieurs invités ; et quand il perd les deux ?
(3) « lorsque les deux appareils passent hors ligne on transmet par écran → l'invité ne peut plus
rien cocher, et au retour en ligne le partage ne se synchronise plus, chacun avance de son côté ».

**Mesuré d'abord** (sonde jetable sur le banc relais d'`audit-partage`, deux pages, secours chaud
réel), avant toute ligne :

| Situation | Avant | Cause |
|---|---|---|
| Minuteur arrêté par l'un | l'autre reçoit `running:false, stoppedAt:0` — pas de ligne ; et s'il avait lui-même arrêté ce minuteur avant, il GARDE sa vieille date (durée fausse) | `shareSnap`/`shareFold` ne portaient pas la date d'arrêt et le récepteur de `timer_stop` ne la posait pas |
| Lien figé (> `staleLimit`, ≈ 5 s), l'HÔTE coche | coche locale, **file à 0**, absente du journal après le retour — perdue pour toujours | `emit` refusait l'hôte pour péremption après que `shareEmitDiff` avait avancé la base |
| Lien figé, l'INVITÉ coche | refusé (« figé » au quai, annonce lecteur d'écran seule) — et rien ne le montre ; « Recevoir » par l'écran n'y change rien | design (« ne jamais cocher dans le vide »), antérieur au mode par l'écran ; bridage visible promis « à venir » dans `emit` |
| L'INVITÉ SEUL perd internet, Wi-Fi commun intact | tente le direct sur son canal dormant, l'hôte ne le sert pas (il ne sert que quand SES sondages échouent) → figé, bandeau « Par l'écran » ; au retour, reprise seule mais **l'écran ne rattrape pas** les gestes de l'hôte faits pendant la panne | `Share.resume()` reconstruit le pli depuis zéro, rien ne repeint (`slBootCloudResume` appelle `openSharedFiche`, `slResumeCloud` non) |
| L'HÔTE SEUL perd internet, canaux vivants | bascule en direct en ~5 s, sert ses canaux ; les invités, dont le relais répond, ne suivent JAMAIS (le `go` est manuel, le `sig` passe par le relais mort) ; « ⇄0 » puis « Connexion perdue » ; **au retour, l'hôte reste en direct pour toujours** — le bandeau s'efface, chacun avance de son côté | `slBackTick` exigeait des invités sur le hub ; `slGoCloud` sans invité ouvrait un partage NEUF |
| Chute totale sans canal | figé des deux côtés ; les gestes NOUVEAUX se resynchronisent au retour | — |

A322 tenait « portail captif = chute totale » : vrai seulement si l'isolation client-à-client tue le
canal dormant. Sur de vrais téléphones le canal WebRTC met plusieurs secondes à se déclarer mort
et l'hôte bascule sur un canal que l'invité ne peut plus emprunter — c'est le cas « hôte seul »
ci-dessus, et vraisemblablement le terrain signalé. Réponse à la question 2 : le direct ne
s'active jamais « juste pour » un invité, il est conduit par l'hôte ; à N invités, ceux dont le
sondage échoue en même temps que celui de l'hôte suivent par leur canal (A209), les autres restent
sur le relais et reçoivent tout au retour de l'hôte (ci-dessous).

**Ce qui change** (aucune clé de charge nouvelle — la liste blanche serveur est intacte, A216) :
1. **L'arrêt d'un minuteur est daté chez l'autre.** La date d'arrêt est **l'heure de l'évènement**
   (`e.ts`, `_ets`) : `shareFold` la pose sur `timer_stop` et la remet à zéro sur `timer_arm`, le
   récepteur vivant la convertit en heure locale (`− Share.offset`), `openSharedFiche` convertit
   celle du pli à la jointure, `shareSnap` la porte pour le miroir optique (`slFoldSan` la garde ;
   `shareDiff` ne l'émet jamais). Mesuré : hôte et invité à 1 ms près. Arbitrage A9 assumé : la
   carte du récepteur gagne la ligne sans geste local — le régime `live` de `timer_stop` repeint
   déjà cette carte, et une pause reçue est un geste de l'équipe.
2. **L'hôte n'est jamais refusé pour péremption** (`emit`) : sa session locale fait autorité, la
   file persistée existe pour porter ses gestes après la panne. Mesuré : file à 1, coche au journal
   cloud et chez l'invité après le retour. Le refus reste entier pour l'invité.
3. **Un hôte en direct sans invité revient par son billet** (`slBackTick` : `invites || slSb.cloud`
   ; `slGoCloud` : sans invité MAIS avec billet → `rehost`, jamais un partage neuf). Mesuré :
   même partage, zéro `open`, le journal du hub (dont la coche faite pendant la panne) rejoint le
   fil et l'invité resté en ligne rattrape.
4. **La reprise repeint** : `Share.resume()` rejoue le journal par la voie vivante et idempotente
   (`onEvents`, celle de `_desync`) quand la session partagée est déjà à l'écran (`Runtime`
   démarré sans dossier local) ; au démarrage rien ne change (`openSharedFiche` reconstruit).
5. **Le bridage de l'invité périmé se voit** : `body.share-stale`, posé au tick (`updateRtStrip`),
   même dessin que `share-dead` (encre secondaire, surface neutre, sans opacité, gestes cliquables
   pour que le refus s'annonce). La feuille et le bandeau de l'invité disent ce qui reste ouvert :
   « Vos coches sont suspendues ; seuls vos repères datés (« Noter l'heure ») repartent » — c'est
   exactement ce que « Renvoyer » transporte (maquette 05). **Arbitrage** : on ne rouvre PAS les
   coches à l'invité figé — elles ne remontent pas par l'écran et seraient écrasées à la
   resynchronisation ; « Continuer seul » reste le repli pour qui veut conduire sa propre copie.

**Ce qui reste dit et non corrigé** : un invité dont le relais répond ne suit pas un hôte passé en
direct (il faudrait un signal hors relais ; le retour de l'hôte le rattrape désormais) ; un invité
SEUL sans internet n'a que « Par l'écran » et ses repères, par construction.

**Garde-fous** : `tests.html` — la date d'arrêt vient de `ts`, l'armement la remet à zéro, la charge
n'en porte pas, `slFoldSan` la garde (4 tests) ; `audit-partage` — deux sections A332 (« panne côté
hôte seul », « lien figé »), 9 contrôles, vérifiées CAPABLES D'ÉCHOUER : 6 rouges sur le code
d'avant (`index.html` et `tests.html` remisés puis restaurés à l'octet). ⚠ Le dernier contrôle
(reprise repeinte) reste vert sur le code d'avant DANS la section — la phase précédente laisse une
resynchronisation en attente qui repeint par accident ; sa preuve isolée est la sonde (invité seul :
« rattrape » faux avant, vrai après). Pièges de banc : la classe `share-stale` se pose au TICK
(attendre, pas lire l'instant du retour) ; le bridage ne se mesure qu'au-delà de `staleLimit`
(≈ 5 s pages visibles, 37 s pages masquées — `_base()` vaut 15 s en arrière-plan).

**Addendum v5.26.3 — la bouée, et l'invité que rien n'atteint (questions de l'auteur).**

*« Et si pas de retour de l'hôte ? Bouée envoyée lors du passage de l'hôte en direct pour forcer le
passage en direct chez les autres ? »* — Oui, et par le seul chemin qui vit encore : à la bascule,
l'hôte sert déjà les canaux dormants de ses invités ; il y envoie désormais une **bouée**
(`SL_BOUEE`, trame hors RPC : `slRpcUnpack` la rend nulle, ni le serveur du hub ni le client ne la
lisent), et l'invité qui la reçoit sur son canal dormant bascule en direct (`slSbGuestSwitch`, son
billet cloud gardé) **même si son propre relais répond encore** — le relais n'est mort que pour
l'hôte, mais un partage cloud que l'hôte n'alimente plus ne vaut rien. Au retour de l'hôte, `rc`
sur le hub le ramène en ligne (A322). Mesuré : bascule suivie, coche de l'hôte reçue en direct sans
aucun retour, retour sur le même partage, invité repassé en ligne. La ligne « limite connue » de
la section « hôte seul » est remplacée par ce témoin. L'écoute de la bouée est posée à la création
du canal (`slSbGuestKick`) et remplacée par le client dès la bascule (`slChanWire`).

*« Mais quid si un invité n'est pas sur le même réseau ? »* — Rien ne l'atteint : ni le direct ni
la bouée n'existent sans canal, et le relais est mort pour l'hôte. Ce qu'on lui doit, c'est la
vérité : **« △ Hôte silencieux · ① Recevoir »** dans le bandeau du quai (`slLink().hostQuiet`,
`shareHostSilenceMs` — le `seen` de la rangée propriétaire, mis à jour à chaque sondage de l'hôte,
lu en heure serveur : une heure recopiée, rien de jugé, § 2), au-delà du seuil clinique
`SHARE_SEEN_QUIET_MS` (45 s, le même que celui de l'hôte pour ses invités), effacé dès que l'hôte
reparle (fonction pure de l'état, A325). La feuille de l'invité dit la cause et ce qui reste vrai :
ses gestes arrivent au journal et l'hôte les lira à son retour (`rehost` reprend depuis son
curseur) ; ce qu'il ne voit plus, c'est la progression de l'hôte — « Recevoir » par l'écran
(`slRxQ`) reste sa porte. Ni « perdu » ni « par l'écran » : ses coches ne sont pas suspendues.

*« Et quid si reprise en ligne suite à perte totale réseau et Wi-Fi, pour l'hôte, pour l'invité ? »*
— Mesuré (banc, A322 + ce lot) : (1) canal mort à la coupure — les deux se figent ; au retour,
l'hôte pousse sa file (ses gestes de la panne, désormais gardés) sur le MÊME partage, l'invité
rattrape par son curseur ; (2) canal survivant quelques secondes — l'hôte bascule en direct,
l'invité suit par la bouée ou échoue sur un canal mourant ; au retour, l'hôte revient par son
billet (avec ou sans invité sur le hub), l'invité par le sien (`slGuestBack` → `slResumeCloud`,
écran repeint) ; (3) rechargement pendant la panne — A323 (hôte) et A325 (invité), billets en
`sessionStorage`. Ce qui reste vrai : les coches de l'invité pendant la panne n'existent pas
(bridage, dit) ; un partage cloud expiré pendant une longue coupure (3 h par défaut, purge 30 min
après) donne « Partage expiré — Se reconnecter » (A324), un nouveau code à scanner.

**Garde-fous** : section « hôte seul » réécrite (bouée, 4 contrôles) ; section « invité hors du
réseau commun » (5 contrôles : silence court tant que l'hôte sonde, qui grandit dès qu'il se tait —
au banc, son `_cycle` devient un no-op, un `clearTimeout` ne suffit pas car chaque émission
re-kicke —, bandeau ≤ 48 px, feuille, effacement). Sur le code d'avant : bouée → rouge (l'invité ne
suit pas), silence → la section échoue (`shareHostSilenceMs` inexistant).
