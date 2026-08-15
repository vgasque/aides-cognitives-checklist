# Journal des modifications

## [5.10.5] — 2026-08-15
### Le rail A→Z tient enfin sous le doigt, la fenêtre compte cesse de glisser, le partage montre les complications et la présence réelle

- **L'icône du filtre remplit son rond** (signalé à l'usage : « augmente la taille des traits dans
  filtrer pour que ça corresponde mieux à la taille du bouton »). Le tracé était écrit à 16 px dans
  la coque statique — calibre d'un temps où le rond en faisait 38 ; depuis que la v5.10.4 cale le
  bouton sur la hauteur MESURÉE du champ (48 px au tactile), il n'en occupait plus qu'un tiers, et
  trois traits fins perdus au centre d'un grand rond se lisent comme un pictogramme lointain, pas
  comme une commande. Porté à 20 px, soit le rapport encre/rond de « ＋ » (15 dans 36) : la rangée
  cesse d'avoir deux densités d'icône. L'ÉPAISSEUR SUIT D'ELLE-MÊME, ce qui était la demande —
  `stroke-width` vit dans le viewBox de 24, donc les traits passent de 1,47 px rendus à 1,83 sans
  qu'aucune valeur d'épaisseur ne soit écrite quelque part. La taille est posée en CSS et non dans
  le balisage : `width`/`height` y sont des attributs de PRÉSENTATION, que le CSS remplace — et le
  tracé étant DUPLIQUÉ dans la table `uiIcon`, toute édition du balisage serait à faire deux fois.
- **En-tête replié, le bouton filtrer prend le gabarit de « ＋ » et du compte** (signalé à l'usage :
  « lorsque l'en-tête d'accueil est replié quand on scrolle, change la taille du bouton filtre — et
  des traits dedans — pour que ça corresponde à la taille des boutons ＋ et compte »). Au repos il
  est SEUL en face du champ, et s'aligner sur lui est exactement ce que la mesure de `--srch-h` est
  venue garantir en v5.10.4. Mais une fois l'identité partie (7a), la rangée persistante porte
  « ＋ », le filtre et le compte : trois boutons voisins, dont un de 48 px contre deux de 36 —
  c'est-à-dire le défaut « deux contrôles d'une même rangée qui ne font pas la même hauteur se
  lisent comme deux niveaux », retourné, le champ n'étant plus le voisin. Sous `body.home-slim` il
  suit donc la troupe : 36 px (icône 16) comme `.hdr-new` et `.bar-acct`, 32 sous 360 px comme eux,
  et le halo rend la cible à 44 px dans les deux cas. Mesuré une fois replié : filtre 36 × 36,
  « ＋ » 36 × 36, compte 36 × 36, tous centrés sur le même axe ; à 340 px de large, les trois à
  32 × 32 avec le même halo `-6px -1px`, donc cible 34 × 44 inchangée.
  ⚠ La règle des 32 px est déclarée AU SITE DU BOUTON et non dans le bloc `359.98` du haut de
  feuille où vivent ses deux voisins : elle y aurait eu la MÊME spécificité (0,3,2) que celle des
  36 px écrite cinq mille lignes plus bas, donc perdu par le seul ORDRE, silencieusement. Pour une
  géométrie, on ne dépend jamais de l'ordre sans le dire.
- **Le rail A→Z ne se sélectionne plus** (signalé à l'usage : « le texte du rail est sélectionnable
  → bug, et ça sélectionne si on reste appuyé trop longtemps dessus »). Viser une lettre, c'est
  poser le doigt et glisser — un geste qui COMMENCE par un appui maintenu, donc précisément ce que
  WebKit interprète sur du texte comme le début d'une sélection : rectangle bleu, poignées, loupe,
  menu « Copier ». Le geste est alors CAPTURÉ par la sélection, le rail cesse de suivre le doigt,
  et il faut taper ailleurs pour désarmer. `touch-action:none` tenait déjà le défilement natif à
  distance, mais une sélection n'est pas un défilement : elle passait à côté. `user-select:none` +
  `-webkit-touch-callout:none` sur `.azrail`, et rien n'est perdu — ces vingt-six lettres ne sont
  pas un contenu qu'on copie, ce sont des commandes. `user-select` s'héritant, les boutons sont
  couverts par la même ligne (vérifié : `none` sur le conteneur ET sur le bouton).
- **Outillage d'audit — le cache vert est PAR HARNAIS et `--rouges` rejoue PAR SECTION** (travail
  déjà en place dans le dépôt, publié ici avec la version qui le nomme). Le cache était
  tout-ou-rien : un octet changé dans `audit-qr.mjs` faisait repayer `doctrine` (217 s). L'empreinte
  SHA-256 est désormais par harnais — socle commun + son script + ses `deps` déclarées — et la passe
  complète ne rejoue que ce dont un intrant a changé, en LISTANT les harnais réutilisés ; les
  `check-*.mjs` sont sciemment hors empreinte (aucun harnais ne les lit, les inclure fabriquait des
  repasses fantômes). `--rouges` lit les NOMS des sections rouges dans la sortie capturée et ne
  rejoue qu'elles, avec trois garde-fous : attribution seulement si le harnais a atteint son bilan
  (`##SEC` présent — sinon repli sur le harnais ENTIER, jamais trop peu), rouge FORCÉ si un `--grep`
  rejoue moins de sections qu'attendu, et jamais de vert de cache écrit par un rejeu par sections.
  Mesuré : confirmer un correctif tombe de 97 s à 0,5 s, repasse inchangée 0,25 s.

- **L'en-tête ne disparaît plus pendant la visée du rail A→Z** (signalé à l'usage, prouvé à la
  VIDÉO image par image : à chaque grande pose vers le haut, l'en-tête `sticky` quittait l'écran
  ~2 frames puis se recollait — pendant que le rail, `fixed` depuis v5.0.2, ne cillait pas). C'est
  le retard de compositeur WebKit sur les collants lors d'un `scrollTo` instantané en séquence
  tactile : aucun gel d'état n'y pouvait rien, ce n'est pas un état qui change, c'est le rendu d'un
  état juste. Pendant `html.azr-aim` l'en-tête passe donc en `fixed` (même famille de remède que le
  rail), `body` compense sa place par `--hdr-h`, et tout se remet en place à la relâche —
  géométriquement une identité, vérifiée à la sonde sur les deux moteurs. Au passage : les cibles
  de `jump` sont bornées au défilement maximal et calculées sur `stickHeight()` (somme de hauteurs,
  jamais le bas observé d'une pile translatable — le dernier lecteur de position que la purge
  v5.0.2 avait laissé), le relais de titre `ttl-on` est gelé pendant la visée, et `--hdr-h` est
  re-mesurée après chaque bascule d'état (elle restait périmée d'une passe : 63 px annoncés pour un
  en-tête de 115).
- **Le rail A→Z se centre sur l'écran en voie étroite** (vidéo : bloc de lettres à ~23 % de l'écran).
  Le centre se calculait sur `documentElement.clientHeight`, la seule mesure de la formule dont le
  comportement sous zoom DIVERGE entre moteurs ; il se dérive désormais de la boîte du rail
  elle-même (géométrie `svh`, stable par construction). La voie large garde la mesure d'origine —
  exacte sur coque fixe, témoin doctrine 1280×900 à l'appui.
- **Le sélecteur A-Z/Catégories se rapproche de l'en-tête** (2 px dessus, 8 px dessous — resserré
  deux fois à la demande), **ouvrir un protocole commence en haut de page** (même artefact Safari
  et même garde-fou que les éditeurs v4.4.7 : le haut est ré-affirmé à l'arrivée), et **les deux
  bascules de l'en-tête d'accueil ont leur micro-animation** — au dépliage l'identité et les chips
  fondent en place (140 ms, opacité + 3 px composite), au repli la rangée persistante recomposée
  fond sur le même tempo ; la hauteur, elle, ne s'anime jamais (check-anim, mesuré v4.41.0).
- **La fenêtre Compte & synchronisation ne glisse plus latéralement** (signalé avec vidéo,
  instrumenté SUR l'appareil : « corps +2 px » — un artefact d'arrondi au zoom fractionnaire, pas
  un contenu, 42 combinaisons balayées sans un élément trop large ; or 2 px suffisent à iOS pour
  ouvrir le pan élastique). La rangée des accents PLIE au lieu de figer 244 px (`flex:none` →
  `0 1 auto`), et les axes sans usage sont FERMÉS : X sur `.ai-modal` et `.ai-body` (dont l'axe
  implicite — `overflow-y:auto` seul calcule X en `auto`). La première pastille d'accent reprend la
  couleur RÉELLE du disque par défaut (`var(--sys)`, « Par défaut ») ; la consignation des
  compteurs (« consigné T+… · il y a … ») s'affiche aussi dans la sidebar, en sous-ligne au liseré
  — elle pesait comme un second titre.
- **Les plans inline ne capturent plus le pouce** (iPhone : le pan vertical restait piégé dans le
  tableau SFAR et l'organigramme, avec retour élastique même sans débordement — un axe `auto`
  rebondit sur iOS même vide). Sur écran tactile, `.sv-scroll` et `.flow-scroll` inline prennent
  leur hauteur entière et l'axe vertical est fermé : le pouce fait défiler la PAGE, le défilement
  horizontal des colonnes est conservé. Les feuilles plein écran gardent leur défileur — c'est leur
  surface, il n'y a pas de page dessous.
- **Le mode moniteur tient en paysage** (tout se superposait : le grand corps était calibré en
  `vw` seul — 169 px sur un écran de 390 de haut — et le centrage déversait le débordement sur la
  rangée du haut). Corps borné par `min(20vw, 32vh)`, centrage `safe`.
- **Partage : l'invité voit les complications, et ce qu'il voit est vrai.** L'ancre d'excursion
  voyage enfin (`SHARE_TRAVELS` listait `cxBack` depuis l'origine sans que le snapshot ni le
  payload `nav` ne l'aient jamais portée — la famille exacte du `fold.exercise` d'avant v4.50.0) :
  sans elle, la carte de complication passait chez l'invité pour un bloc terminal ordinaire
  (« Terminer l'algorithme ✓ » puis « surveillance en cours » au lieu du retour « ↩ Reprendre »).
  Références seules, validées contre la copie locale de la fiche (règle 15). La touche
  ⚡ Complications est rendue à l'invité en CONSULTATION (`jumpToBlock` — la navigation locale du
  plan, jamais d'entrée déclarée). Et les cartes minuteurs de la sidebar ne se bloquent plus par
  moments en partagé : `bindRailTm` empilait un écouteur à chaque coche (parité paire = carte
  inerte) — affectation `onclick`, idempotente.
- **Partage : la présence affichée est la présence réelle, sans juger un téléphone posé.** Trois
  régimes (retour utilisateur : « en urgence ça peut arriver de lâcher son téléphone 1, 2 min ») :
  silence ≤ 45 s, rien ; jusqu'à 3 min, présent et compté avec la mention « sans nouvelles ·
  N min » ; au-delà, « absent », hors compte ⇄ et menu. Le départ EXPLICITE n'attend pas :
  « Quitter le partage » émet `presence{quit}` (genre réservé depuis l'origine, jamais branché —
  la liste blanche du serveur l'acceptait déjà, zéro changement de schéma) et l'hôte affiche
  « parti » à la seconde. `last_seen_at` était renvoyé par le serveur et jamais lu.

## [5.10.4] — 2026-08-15
### L'en-tête ne bat plus sous le rail A→Z, le viewport iOS se recolle, le filtre est rond

- **L'en-tête d'accueil ne bat plus pendant le glisser sur le rail A→Z** (signalé à l'usage :
  « en haut de la liste, l'affichage saute très rapidement entre vue pliée/dépliée »). Chaque
  mouvement de doigt sur le rail pose un défilement ABSOLU ; près du haut de l'annuaire, deux
  lettres voisines encadrent l'hystérésis 80/40 de `syncHdrScroll` et le repli battait à la
  cadence du doigt (114 ↔ 62 px par évènement pointeur). L'hystérésis protège d'un doigt qui
  hésite EN DÉFILANT ; elle ne peut rien contre des sauts qui la traversent en entier. Pendant la
  visée (`html.azr-aim`), l'état plié/déplié est désormais FIGÉ — le geste du rail n'est pas un
  geste de défilement — et se rejoue UNE fois à la relâche. Vérifié à la sonde : état constant
  sur un va-et-vient A↔D complet, une seule bascule au lâcher.
- **Le décalage résiduel du viewport visuel iOS se répare d'office** (signalé à l'usage, capture :
  toast « fichier ignoré » au MILIEU de l'écran, en-tête invisible sous la barre d'état, bande
  vide sous le pied de page). Le clavier PANORAMIQUE le viewport visuel dans le viewport de mise
  en page (`offsetTop` > 0) ; à la fermeture, WebKit ne recolle pas toujours les deux — surtout
  quand le fond était verrouillé par une fenêtre, donc sans évènement de défilement pour
  resynchroniser. Hors pincement et hors clavier, un `offsetTop` non nul est TOUJOURS incohérent :
  on recolle en déplaçant le défilement de mise en page de l'offset (`scrollBy`) — le contenu
  visible ne bouge pas d'un pixel, seuls l'en-tête collant et les couches fixes retrouvent
  l'écran. Déclenché aux seuls moments où l'état peut naître (fermeture du clavier, perte de
  focus, retour de bfcache), jamais en continu. À confirmer à l'usage sur appareil (l'état n'est
  pas reproductible hors iOS réel).
- **Le déclencheur de filtre est un CERCLE calé sur le champ de recherche** (demande de l'auteur ;
  il rendait 38 × 48, un OVALE). `align-self:stretch` + `aspect-ratio:1` ne fait pas un rond en
  flex — la largeur se détermine AVANT que l'étirement ne fixe la hauteur, le transfert n'a jamais
  lieu (mesuré). Aucun nombre n'étant juste à écrire (champ à 48 px au tactile, ~44 au pointeur
  fin), la hauteur du champ est MESURÉE et posée dans `--srch-h` (`syncSrchH` — au rendu, au
  redimensionnement, au changement de taille du texte ; doctrine « une barre de chrome se mesure,
  elle ne se devine pas »). Mesuré après : 48 × 48.
- **Prompt IA resserré** (demandes de l'auteur ; les jalons de boucle y figuraient déjà depuis la
  v5.5.0). (1) Formulation LA PLUS COURTE POSSIBLE partout — étapes, surveillances, confirmation,
  notForget — avec l'exception écrite : les CRITÈRES diagnostiques restent COMPLETS, on raccourcit
  la formulation, jamais la liste. (2) Les noms de minuteurs/compteurs sont À LA FOIS titre et
  ligne de journal : 1 à 3 mots, relus seuls, et un compteur doit se lire SUIVI D'UN NUMÉRO
  (« Choc n° 3 » — objet compté au singulier, jamais un pluriel ni un intitulé abstrait). (3) La
  parcimonie ⚠/△ existait déjà (plafonds par bloc ET par fiche) : elle entre dans la check-list
  finale « AVANT DE RÉPONDRE », avec les libellés de compteurs. (4) Corrigé un bogue de l'exemple
  du schéma : l'id `"b2"` y figurait DEUX fois — l'exemple violait sa propre règle d'unicité.

## [5.10.3] — 2026-08-15
### Le tick gaté (jamais ralenti), les relances iOS comptées, AGENTS.md scindé

- **Le battement interne est GATÉ, pas ralenti** (R6, mesuré avant ET après). Une fiche simplement
  ouverte — sans session — payait le tick complet 3,3 fois par seconde : 40 travaux inutiles en
  3 s (refreshTimersDOM, paintCnAgo, updateRtStrip, monRender), et l'accueil balayait tout le
  document à la même cadence sans aucune session vive. La condition devient « une session AFFICHE
  du temps » (sessions vives, essai K5, invité). **La granularité est intouchée par
  construction** : la cadence de 300 ms ne bouge pas — retard de bascule de seconde mesuré
  79-288 ms avant, 97-304 ms après (même enveloppe), latence du geste 1 ms, travaux en session
  strictement identiques. ⚠ Le réveil « aligné sur la seconde », envisagé, est **rejeté au
  calcul** et le refus est écrit au site : chaque minuteur franchit sa seconde à sa propre phase —
  un réveil calé sur l'horloge murale afficherait la bascule jusqu'à une seconde en retard.
- **Les relances complètes se comptent** (P2, diagnostic de l'hypothèse d'éviction d'A153). Les
  2-3 s de blanc au retour vivent dans la couche iOS ; la seule question ouverte est leur
  FRÉQUENCE. Journal par jour (démarrages complets / reprises sans relance, fenêtre 14 j, une clé
  locale), lu dans Compte › « Sur cet appareil ». Instrumentation **temporaire** (précédent
  v4.29.x), jamais chez l'invité.
- **AGENTS.md scindé : 797 → 49 Ko de noyau.** Le fichier canonique dépassait la fenêtre de
  contexte de tout outil IA — les instructions étaient tronquées en silence à chaque session, le
  défaut exact que le découpage du changelog avait guéri en v5.0.0. La doctrine détaillée vit dans
  `docs/decisions/` (six fichiers, déplacement **à l'octet** : empreintes sha256 embarquées, 164
  entrées A réconciliées, zéro réécriture, classement chronologique par lot — le numéro A est
  l'adresse que la doctrine se cite à elle-même). AGENTS.md garde les 15 règles, la publication,
  les garde-fous et la carte ; toute nouvelle entrée A va dans le fichier de son lot.

## [5.10.2] — 2026-08-15
### Audit de code externe : quatre bogues, deux garde-fous, quatre duplications

Audit transverse du monofichier (code mort, duplication, PWA, sécurité) par balayage outillé —
836 fonctions, 1 916 interpolations, 245 ids, 227 exports de test — chaque constat **re-vérifié de
première main** avant correction : trois « morts » du balayage étaient des faux positifs
(`#addImg`, `wakeActive`, `SHARE_DROP`/`vfActor`), et la leçon est écrite (A157). Doctrine :
`AGENTS.md` A154 à A158.

**Les bogues utilisateur.**
- **Le diff « Versions » était aveugle sur cinq listes sur six.** `flattenFiche` lisait
  `f.confirmation`/`verify`/`notForget`/`differentials`/`posology` — des champs que `migrate`
  **supprime** depuis l'étape B (v5.0.0) : sur toute fiche réelle, restaurer une version se
  décidait sans voir aucune modification de ces listes. La table de libellés omettait en plus
  `posology`. Les deux passent par `listOf()`, la vue sur le pool — et les témoins, restés verts
  sur des fixtures brutes jamais migrées, **rencontrent désormais leur cas** (fixtures migrées,
  assertions sur les cinq listes).
- **La recherche ne trouvait jamais une fiche par son diagnostic différentiel** — le même résidu
  (`f.differentials` lu en direct) dans `ficheHaystack`, figé par son cache. Pour un répertoire
  dont le motif d'usage est « le tableau ne colle pas », c'était le trou le plus clinique du lot.
- **Les sessions synchronisées entraient sans assainisseur** : `sessionFromRow` écrivait le blob
  distant tel quel en IndexedDB (fiches et protocoles passent par `migrate`). `sanitizeSession`
  applique la règle 5 en **liste grise** — champs connus bornés par les grammaires existantes
  (`SHARE_KEY_RX`, `shareNavNorm`, `tkRefNorm`), champs inconnus qui traversent, motif
  `__proto__` fermé. 13 témoins.
- **Quatre lecteurs d'ids fantômes** (`#crisisCtrl` ×3, `#planBtn` ×2, `#endSess`) : l'un
  recalculait `--ctrl-h` à « 0px » **à chaque évènement de défilement** pour un élément parti en
  v5.6, les autres étaient des câblages morts. Purgés avec leurs épitaphes.

**Les garde-fous (le trou par lequel tout cela était entré).**
- `check-ids` : tout `getElementById` littéral doit avoir une émission (id littéral ou fabrique
  déclarée). `check-actest` : toute clé exportée vers `__ac_test__` doit être citée par un témoin
  ou un harnais, doublons interdits — trois doublons dédoublonnés, 13 clés sans valeur de test
  retirées, et le **cœur du modèle v4** (`poolOf`, `roleItems`, `setStepStr`, `v4SanItem`,
  `v4Level`, `V4_ROLES`) reçoit ses vrais témoins. Les deux vérifiés capables d'échouer.
- `check-colors` couvre désormais le **manifeste** : `theme_color`/`background_color` portaient
  des hex hors palette (#ffffff, #e9edf2) — splash hors tokens à chaque lancement, invisible d'un
  contrôle borné au `<style>`. Alignés sur `THEME_COLOR.light`.

**Les duplications** (« une seule vérité par geste ») : `paintCheckRow` — la peinture du cochage
vivait en deux copies mot pour mot, la divergence v4.42.0 revenue par une autre porte ;
`planCtx` — le préambule de plan recopié six fois, dont une où il était calculé puis jeté ;
`conduiteRows` — les rangées communes des menus invité/hôte (le sous-titre divergent de
« Consulter » est une raison documentée, pas un accident) ; `bindPreviewBack` et `blockTip` — les
paires jumelles fiche/protocole. Purgés avec leurs témoins (règle 14) : `flowOrder`,
`svBranchIssue`, `svLoopTargets`, `cxOne`.

**Sécurité** (audit exhaustif : **0 XSS exploitable**, RLS sans faille, 0 sink dangereux) : la
barrière devient **locale** — `esc()` sur 27 identifiants interpolés, `CSS.escape` sur les cinq
sélecteurs construits, le backtick non échappé **vérifié** inerte, invariant écrit sur
`_reportDoc` (seul endroit où une chaîne devient un document), commentaire de décision sur
l'absence de rate-limit de `share_join`.

**PWA** : cache statique pérenne `STATIC_CACHE` (~120 Ko de polices/icônes n'étaient
re-téléchargés à chaque release que parce que la clé de cache change — le motif pdf.js
généralisé), préchargement des quatre polices embarquées, `display_override` au manifeste.

**Et une attribution fausse corrigée dans la doctrine** : A153 imputait les 2-3 s de blanc iOS au
parse des 2,4 Mo. Mesuré (copie sans commentaires, CPU ×6) : **1,26 Mo de commentaires = ~0,1 s**
— le blanc vit dans la couche iOS (processus, WebKit, worker), hors de portée du code. Le retrait
des commentaires à la publication est **disqualifié** comme levier de démarrage ; reste
l'hypothèse d'éviction mémoire, à instrumenter avant d'agir.
## [5.10.1] — 2026-08-14
### Audit design externe : ce que les garde-fous ne voyaient pas

Audit mesuré au rendu (320 · 390 · 1280 px × les quatre réglages de taille du texte, deux thèmes),
sur le **contenu d'exemple livré avec le produit** — donc sur ce que voit le premier utilisateur,
le premier jour. Les dix-huit contrôles statiques étaient **verts** : chaque défaut ci-dessous
était, par construction, hors de leur portée. Doctrine : `AGENTS.md` A139 à A148.

**Ce que l'audit a établi sur le fond, et qu'il faut dire avant les correctifs.** Une sonde de
contraste indépendante (composition de l'opacité des ancêtres et du fond effectif) rend **0
violation AA** sur l'écran de crise dans les deux thèmes ; 22 couleurs peintes pour 123 jetons
déclarés, chacune avec un sens constant ; cases à cocher à 3,33:1 en sombre ; réserve du dock sans
un pixel masqué ; anneau de focus franc. Le système tient. Ce qui cédait, ce sont **trois bords que
rien ne balayait** : la grande police, la largeur plancher, le contenu long.

- **Le discriminant clinique n'était jamais peint.** « adulte » / « pédiatrique » vivait dans
  `#brandTitle`, qui s'ellipse — dernier enfant, donc premier amputé : à 390 px, 193 px de boîte
  pour 358 nécessaires, la pilule commençant au 308ᵉ pixel. Le champ créé pour distinguer deux
  procédures homonymes était exactement ce que la troncature emportait d'abord, avec une doctrine
  qui affirmait le contraire. Il rejoint le **sur-titre**, où il ne coûte **rien** : mesuré,
  l'en-tête fait 61 px avec et sans sur-titre, et le titre regagne les 50 px que la pilule
  consommait dans sa chaîne.
- **Le mécanisme anti-`@media` de la règle 10 était mort.** `syncZoomWidth()` posait
  `zw560/430/400/360` à chaque rendu et **aucune règle ne les lisait** — leurs consommateurs
  étaient partis avec la rangée de commandes en v5.6, le poseur était resté (`check-classes` ne
  peut pas le voir : le nom est calculé). Pendant ce temps le dock écrivait son palier en `@media`,
  donc il ne se déclenchait jamais sous zoom : mesuré à 390 px × 130 %, la mise en page dispose de
  300 px effectifs, `zw360` est bien posée, et les quatre étiquettes survivaient sur deux à trois
  lignes dans des touches de 76 px. Un **cinquième palier** naît de ce lot, `zw300`, qui ne peut
  naître que du zoom — aucun appareil ne fait 300 px.
- **Le budget d'écran comptait deux couches sur trois, et un réglage sur quatre.** En v5.6 la
  rangée de commandes est devenue le dock bas ; `audit-budget` est resté calibré sur les trois
  couches d'avant tout en n'en mesurant plus que deux — le seuil de 30 % n'a pas bougé, mais ce
  qu'il borne a perdu un tiers. Le harnais balaie désormais les quatre crans de texte et compte le
  dock. Mesuré avant correction à 320 × 640 × 130 % : chrome **41,3 %** et **zéro étape cochable**.
  Après compaction des rembourrages (jamais des cibles : `.sd-key` descend à 44 px, exactement le
  plancher d'A8) : **24/24 sur six configurations**.
- **Le plus grand corps de l'écran de crise appartenait à un libellé de navigation.** Relevé des
  corps peints : titre de bloc 21/700, étape vitale 17,5/800, cadence **11/600** — le plancher
  typographique pour « 30:2 — sans délai », qui gouverne le geste. Deux crans échangés : le titre
  descend, la cadence remonte juste sous l'étape qu'elle qualifie. Bénéfice second, mesuré : à
  320 px × 130 % le titre ne se coupe plus **en plein mot**. Une carte de **décision** garde le
  grand cran — A75 exige que son titre passe devant sa question.
- **Deux touches du dock, un seul glyphe, aucun mot.** « Tout voir » et « Consulter » partageaient
  ⤢ — choix juste en v4.25.0 — et A2 leur retire l'étiquette sous 360 px : restaient deux boutons
  voisins, même symbole, deux destinations, en mode crise. Aucune des deux règles n'est fautive ;
  leur **composition** l'était. « Consulter » prend `book`. Dans la foulée, les glyphes du dock
  passent par `uiIcon` (⚡︎ → `bolt`, ⏱︎ → `stopwatch`, entrée `backto`), et trois SVG littéraux
  dupliqués entre la coque et le peintre disparaissent.
- **Un jeton court est un item dur.** Le code « ANA » manquait de **un pixel** (29 rendus pour 30)
  et s'affichait « A… » : l'unité était fausse — un pixel manquant sur trois lettres en détruit
  deux, l'ellipse consommant la place qu'elle libère. Décision prise à l'émission, seuil cinq
  caractères. ⚠ Prioritaire, **pas rigide** : un témoin a montré qu'en le rendant immuable il était
  poussé hors de la boîte à 330 px, c'est-à-dire disparu.
- **« Tout voir » revient enfin où l'on était** *(signalé à l'usage)*. Reproduit : parti de y=300,
  l'excursion défilée jusqu'au bout, retour à **575 — le maximum du document**. L'ancre était
  traduite aux deux jambes ; elle est juste à l'aller, et restitue au retour la position de **fin
  d'excursion**. Le second symptôme signalé — « la barre flottante et les clics sont décalés
  jusqu'à ce qu'on remonte » — tombe avec le premier : atterrir à la borne est la condition exacte
  du rabat de fin de page et du rebond iOS. ⚠ On mémorise une **ancre**, pas un nombre : si un
  collègue avance le parcours pendant l'excursion, la page change de longueur et un `scrollY` brut
  redéposerait à la borne (cas construit et mesuré, document 1420 → 1769 px).
- **La carte de session vive** : « Reprendre » ne se détachait pas de sa carte (**1,69:1** — le
  défaut qu'A43 a nommé pour la pastille Compte, la limite d'un composant et non son texte). Il
  prend `--ok-sys` (**9,08:1**), qui est déjà le registre du retour d'excursion du dock — « vous
  êtes loin de chez vous, ceci vous y ramène ». Et « Reprendre » / « Terminer » avaient deux
  hauteurs (38 et 36) à 10 px l'un de l'autre : les deux passent à 44 px, l'écart s'ouvre.
- **L'étiquette de complication borne sa parenthèse** — « FV réfractaire.. » était clampée à deux
  lignes *et* encore tronquée, alors que savoir laquelle s'ouvre est tout l'objet du bouton. La
  parenthèse qualifie, elle n'identifie pas ; la phrase entière reste dans le nom accessible.
- **Les quatre touches du dock sont enfin égales** : `flex:1.3` donnait à ⏱ une piste 30 % plus
  large — mesuré 79/79/79/100 à 390 px et 46/46/88/110 à 320.
- **Les catégories vides sortent du rail de l'accueil.** Sur une installation neuve, neuf
  catégories dont **six à zéro** : six rangées menant à une liste vide, en tête du premier écran.
  Un filtre qui ne filtre rien n'est pas un filtre — et la taxinomie garde son lieu, « Gérer les
  catégories ». ⚠ La catégorie **sélectionnée** reste, même à zéro : la retirer rendrait le filtre
  invisible au moment précis où il explique une liste vide.
- **En crise, le préambule ne paie que ce qu'il montre** *(signalé à l'usage)*. À 390 px, session
  vive, **106 px** séparaient le bas de la capsule du haut de la carte, dont **24 px de pur
  espacement**. Ramenés à 4 px chacun : **96 px**, rythme régulier, première étape 10 px plus haut.
  Les boîtes du chapeau et de la ligne-bilan ne bougent pas — elles sont tapables (40 et 44 px) ;
  seule la respiration entre elles cède.
- ⚠ **La Page garde son défilement horizontal, et c'est un retour en arrière assumé.** J'avais fait
  céder la colonne d'état pour rendre à la feuille sa largeur d'auteur (227 px de débordement à
  1280 px). Refusé à l'usage, en deux symptômes qui n'en font qu'un : « le volet noter l'heure reste
  petit » et « les minuteurs apparaissent en bas de la page ». Déplacer une surface d'**état vive**
  pendant un soin coûte plus cher qu'un défilement horizontal sur une surface de **consultation** —
  et mon rapport classait d'ailleurs ce point en simple amélioration. Le débordement reste, sans
  solution gratuite : l'ajustement d'office ramènerait une cible de 44 px à 34, et rétrécir la
  feuille casserait « la même image partout ». Un témoin de non-régression tient désormais la
  propriété choisie : en voie large, l'état reste à droite du document.

⚠ **Deux pièges du dossier se sont produits pendant ce lot, et le second a masqué le premier** :
le script inline a été édité sans rejouer `csp-hashes.mjs` (règle 3), donc la CSP a bloqué le seul
script et l'application n'a plus démarré — pendant que l'onglet de développement affichait une page
parfaitement fonctionnelle, le service worker resservant l'ancien HTML. Ensemble, ils donnent
« ça marche chez moi, ça casse au harnais ».

Chaque correctif est vérifié au rendu, et le nouveau témoin d'excursion a été **vérifié capable
d'échouer** — défaut réintroduit, contrôle rouge, fichier restauré à l'octet.

## [5.10.0] — 2026-08-14
### La vue « Page » devient un document

La Page SFAR était une bonne vue d'algorithme enfermée dans une mauvaise page : une colonne qu'on
déroule, **sans titre, sans date, sans source**, et **sans les repères posologiques** — qui partent
dans le rail au-delà de 780 px, donc n'existaient nulle part sur le papier. Quatre lots d'un brief
d'implémentation externe, avec ses maquettes aux trois formats. Doctrine : `AGENTS.md` A133 à A138.

- **Une COQUE de feuille** — cartouche daté (sur-titre, titre, révision, comptes), trois cellules
  d'entrée, l'algorithme et sa **colonne de référence** (surveillances, complications « à tout
  moment », minuteurs et compteurs déclarés), les **doses en pied sur trois colonnes** avec la
  source et un pied de page. Ce qui n'a rien à dire n'existe pas : pas de dose → pas de bande, pas
  de surveillance ni d'excursion → pas de colonne, et l'algorithme prend toute la zone.
- **⚠ L'avertissement de validation s'affiche enfin.** Certaines fiches portent, dans leurs
  sources, « Fiche générée par IA le … — à relire et valider avant usage » — le prompt d'import
  l'impose. Cette phrase n'apparaissait **nulle part** à l'écran : une feuille imprimée et affichée
  au mur sans elle est un danger. Elle est dans le cartouche, au registre ALERTE en **contour**,
  jamais un aplat.
- **Le tracé passe en GRILLE UNIQUE** — six pistes, tronc sur quatre, centré. Les branches étaient
  des conteneurs imbriqués : la largeur se divisait à chaque niveau (1130 → 565 → 282 → 141), et
  sur une fiche à quatre niveaux la partie la plus **grave** de l'algorithme finissait dans la
  colonne la plus étroite, empilée, fourches masquées. Chaque nœud est désormais un **frère** placé
  par `grid-column`/`grid-row` : il occupe l'étendue libre à sa ligne, donc **une branche profonde
  peut être plus large que celle dont elle descend** (répartition au prorata de la hauteur, minimum
  une piste, reste à la plus haute). La fourche est dessinée **en divs**, ses bras en pourcentage
  du centre de chaque branche : la géométrie suit la grille sans qu'on la mesure.
- **Une largeur d'AUTEUR, et le zoom pour l'ajuster.** La feuille fait 1130 px à toutes les
  largeurs et **ne se reflue plus** : aux trois formats c'est la même image — celle qui se
  mémorise — et c'est l'échelle qui s'adapte (`⤢ Ajusté`, `−`/`＋`, `1:1`, par pas discrets).
  Elle s'ouvre toujours à la taille d'auteur : ajuster d'office mettrait toutes les cibles sous
  13 px réels dans un écran qu'on ouvre pendant un soin.
- **L'impression en fait un vrai document** : aucune cellule coupée, doses à 3 colonnes en paysage
  et 2 en portrait, k = 1 — et surtout **l'état de session ne s'imprime pas** (✓, « ici », « hors
  chemin », « ×n » décrivent une réanimation qui n'a plus lieu ; une feuille au mur qui porte le ✓
  d'une session passée est une feuille fausse). Le test du lot : si la sortie papier est utilisable
  **sans** l'application, la page est réussie.
- **« Tableau », avant le soin, ouvre la même feuille** — un seul générateur des deux côtés. Elle y
  est inerte au geste près de l'échelle : on vient la regarder, pas la conduire. **Et la même
  fenêtre s'ouvre depuis le soin**, par une porte « ⤢ Plein écran » de l'onglet Page : même coque,
  même sortie, même page — jamais une seconde surface à tenir.
- **Les retours ↺ ne mordent plus sur un bloc** (signalé à l'usage) : dans une grille à six pistes,
  la voie traversait les branches voisines. Ses deux extrémités sont bornées à la gouttière.
- **Ce qui n'est pas livré, et pourquoi** : le cartouche ne se répète pas en tête de chaque feuille
  imprimée — seul un en-tête de table le fait nativement, et le simuler demanderait de reperdre la
  grille unique. Le pied porte titre et révision, donc une page détachée reste identifiable.


## [5.9.0] — 2026-08-13
### L'atelier d'import va jusqu'à la question destructive

`5.8.0` avait posé le grain — l'entité — et `5.8.1` l'avait tenu partout. Restait le geste que
l'atelier existe précisément pour éclairer : **remplacer**. La rangée annonçait qu'une entité était
« déjà présente » sans dire ni **laquelle des deux versions est la plus fraîche**, ni **ce que
remplacer coûterait**. Doctrine : `AGENTS.md` A131 et A132.

- **La rangée dit laquelle des deux est la plus récente** — « le fichier est plus récent »,
  « votre version est plus récente », « même version ». Le second cas est le seul où remplacer
  **perd du travail** : il prend le registre ATTENTION, en texte et avec son glyphe, jamais un
  aplat. Aucun champ nouveau : `updatedAt` **est** la révision, celle-là même dont le compte rendu
  se sert déjà pour dire sur quelle version un soin a été conduit.
- **⚠ Et l'horodatage est lu *avant* la normalisation**, parce que celle-ci en pose un quand il
  manque — un fichier ancien se serait donc annoncé « plus récent » que tout ce qu'on possède, sur
  la seule question destructive du parcours. Sans date des deux côtés, la rangée **se tait** plutôt
  que de deviner.
- **« Comparer » déplie ce que remplacer changerait**, ligne à ligne : ce que le fichier
  apporterait, ce qu'il emporterait. C'est le comparateur de « Versions », inchangé — pas un
  second, qui finirait par répondre autre chose sur la même paire d'objets. Les **références** ont
  leur propre aplatissement (leur corps est du texte, ses lignes sont ses unités) : sans lui, la
  moitié de la bibliothèque n'aurait eu aucune réponse à la même question.
- **Ce qui n'est pas fait, et pourquoi** : descendre au **grain du bloc**. Un bloc ne porte que des
  identifiants d'items d'un pool partagé et se relie aux autres par ses branches — en importer un
  sous-ensemble produirait des blocs vides et des branches qui ne mènent nulle part. Un algorithme
  partiel n'est pas un algorithme allégé, c'est un algorithme cassé.

## [5.8.1] — 2026-08-13
### L'atelier d'import, jusqu'au bout : le filtre atteint tout ce qui s'écrit

`5.8.0` avait posé le grain de l'import — l'entité — sans le tenir partout : trois choses
raisonnaient encore **en bloc** derrière l'atelier, et la rangée taisait ce qui permet de décider.
Doctrine : `AGENTS.md` A130.

- **Les catégories suivent la sélection.** Elles entraient *toutes*, y compris celles que seules
  les entités décochées employaient : on repartait avec des catégories vides dans son rail, créées
  par un import qu'on venait justement de restreindre. La règle qui en sort est plus large que le
  cas : *le filtrage doit atteindre tout ce qui s'écrit, pas seulement les entités.*
- **La question destructive annonce la sélection, pas le fichier** — « remplacé(e)s par les
  **n éléments cochés** ». Depuis l'atelier les deux ne sont plus la même chose, et c'est la seule
  question destructive du parcours : y annoncer le fichier ferait croire qu'on récupère ce qu'on
  vient d'écarter.
- **« ⟳ déjà présent » se dit sur la rangée, avant la question « Doublons ».** La rangée porte le
  fait ; le sort reste décidé par la question groupée. Elle n'apparaît **que là où la collision
  peut avoir lieu** — identifiants conservés, donc même espace : sur un fichier venu d'ailleurs ils
  sont régénérés à l'écriture, et annoncer un doublon que l'écriture ne verra pas serait un
  mensonge. *Un contrôle « remplacer / garder les deux » par rangée a été écarté* : décocher porte
  déjà le grain, tandis que ce choix-là est une stratégie, globale par nature.
- **La rangée dit ce que l'entité embarque**, dans les mots de l'écran d'entrée : « 2 blocs ·
  1 minuteur · 1 complication déclarée ». C'est la seule chose qui distingue un algorithme complet
  d'une ébauche sans ouvrir le fichier. Une phrase, **deux lecteurs**, donc un seul calcul ; seuls
  les seuils diffèrent, et chacun est motivé.
- **Détail de plancher** : à 320 px les deux gestes de l'atelier tenaient sur une ligne mais s'y
  cassaient chacun en deux. La rangée enroule désormais plutôt que les mots — les boutons restent
  côte à côte à 44 px, c'est le compte qui passe dessous.

## [5.8.0] — 2026-08-13
### « Voir avant d'écrire, revenir sans chercher »

Fin du lot v5.7 : son dernier item de plan — **l'atelier d'import** —, les deux retours au soin
qui manquaient, et les deux correctifs *à zéro pixel* que le **refus** du « plan de vol » sur
l'écran de crise avait révélés. Comme le lot précédent, rien ici ne déduit quoi que ce soit d'un
paramètre patient. La doctrine est dans `AGENTS.md` § « Lot v5.7 » (A124 à A129).

**Ce qui entre dans la bibliothèque**

- **L'atelier d'import — le grain n'est plus le fichier, c'est l'entité.** Un `.json` ou un `.zip`
  entrait EN BLOC : on répondait à trois questions (destination, fusion, doublons) sans avoir
  jamais vu ce qu'il contenait. Sur un export de bibliothèque, c'est dix-huit aides qu'on acceptait
  sur la foi d'un nom de fichier, et le seul recours après coup était de les supprimer une par une.
  L'ordre est renversé : **d'abord ce que l'on importe, ensuite où**. Une rangée par entité — type,
  titre, **état déclaré par le fichier**, ce qu'il reste à relire, nombre de PDF —, tout coché au
  départ : l'atelier sert à *retirer*, il ne demande pas de tout re-cocher.
- **Le filtrage précède toute écriture**, et c'est le point dur : les deux listes sont réduites à
  la sélection *avant* les questions, donc avant `migrate`, `persist` et surtout `importAtts`. Un
  binaire du `.zip` n'entre **jamais** pour une entité décochée — non par un filtre posé après
  coup, mais parce que la liste filtrée est la seule qui existe ensuite.
- **L'état entrant est préservé** : les trois portes forçaient « Brouillon ». C'était un proxy de
  « vous n'avez pas encore relu ceci » ; l'atelier montre désormais cet état *avant* l'écriture,
  rangée par rangée. Le coût du forçage était réel — **restaurer une sauvegarde ramenait dix-huit
  aides validées en brouillon**, donc hors de l'accès de crise (un brouillon ne s'épingle pas et
  reste masqué aux lecteurs d'une bibliothèque partagée). L'objection est nommée dans la doctrine :
  ce qui protège du « Validée » non relu, c'est la rangée qui le dit, plus le prompt IA qui impose
  `"status":"draft"` — contrat vérifié par `audit-prompt`.
- **La pastille « △ n »** est le *même* calcul que le volet « Relecture » de l'éditeur : deux
  comptes écrits séparément divergeraient. Elle ne conditionne rien — une remarque de relecture
  n'est pas un refus.
- Trois défauts trouvés sur le trajet et corrigés : un fichier ne portant **que** des références
  répondait « Import interrompu » alors qu'il était parfaitement valide ; un contenu vide disait
  « 0 fiche importée », une phrase qui ne désigne pas sa cause ; les questions comptaient le
  *fichier* au lieu de la *sélection*.

**Revenir au soin**

- **Rouvrir l'application pendant une session vive dépose dans le soin**, plus sur l'accueil : un
  tap de moins au seul moment où l'on n'en a aucun à donner. Trois bornes — une seule session
  vive, dix minutes sans le moindre geste au plus, et jamais quand un lien d'invité est présent.
  Le « ‹ » de l'en-tête ramène à la bibliothèque : personne n'est enfermé.
- **La barre de retour au bloc courant** est affinée sur trois signalements : elle ne **clignote**
  plus au re-rendu (un nœud détaché n'est pas « hors zone » — l'observateur surveillait l'ancienne
  carte), elle prend la **boîte de la barre flottante** au lieu de celle de la page, et elle
  **s'empile** sur le volet du dock au lieu de le recouvrir, en redescendant d'elle-même à sa
  fermeture.
- **Le passage qu'on interrompt se replie.** Après une complication reprise, deux cartes ouvertes
  du même bloc se suivaient avec les mêmes étapes. La navigation, elle, était juste — un témoin
  écrit *avant* toute correction l'a tranché. L'invariant du journal n'est pas touché : on ne
  transforme pas le passage en chip, on pose le repli manuel, et un tap rouvre l'ancienne carte.

**Lire l'état**

- **Un minuteur armé puis mis en pause cesse d'être muet.** Il ne figurait dans aucun segment de
  la capsule et n'avait pas d'alarme à venir : il n'existait donc nulle part sans ouvrir le volet,
  alors qu'il porte un temps qui a cessé d'avancer. « ⏸ n en pause » rejoint le rappel du quai.
- **La progression d'un jalon sort de son bloc** : « Chocs 2/3 » disparaissait dès qu'on était
  ailleurs, pendant que le compte, lui, continuait d'avancer. Elle rejoint le volet, en quatrième
  famille — une ligne, pas une carte, et aucun geste n'y est posé.
- **Le plan de vol est refusé sur le chrome de crise et livré dans le moniteur.** Éprouvée contre
  le contenu réel des fiches, la proposition ne gardait qu'un bénéfice rare pour ~52 px permanents
  dans une colonne dont le budget est tenu à 30 % ; sur un afficheur qu'on lit à deux mètres, les
  pixels sont gratuits et une bande de temps est la bonne forme. Trois registres de trait, et l'on
  ne peut pas confondre un fait avec une promesse : point = c'est arrivé, trait plein = c'est daté,
  tiret = c'est projeté si rien n'est touché. Un jalon compté n'y entre jamais — le dater
  reviendrait à prédire le rythme auquel l'équipe va agir.

**Géométrie, densité, finitions**

- **En exercice, le volet recouvrait la capsule de 63 px** : le bandeau du placard vit dans le
  flux et pousse le quai vers le bas, alors que la position du volet se dérivait d'une *somme de
  hauteurs*. Il suit désormais le bas **réel** du quai — correctif borné au volet : partout
  ailleurs, une géométrie de chrome continue de ne jamais dériver d'une position de défilement.
- **En session, le haut de page cesse d'être du vide sous le quai** (18 → 8 px à 390, 24 → 14 à
  1280) : le quai ferme déjà le haut, cet écart n'y sépare plus deux objets.
- **La ligne de reprise après interruption** est refaite : une rangée *dans* la carte, un nombre
  qui **vit** (un nombre figé qui annonce « il y a 6:12 » ment dès la minute suivante), et une
  sortie explicite à 44 px.
- **Les cartes épinglées prennent le rythme du répertoire** — elles s'étalaient sur toute la
  largeur (976 px contre 320) pour l'accès le plus rapide du produit.
- **Le parcours inerte se resserre en deux passes** (416 → 368 px avant le soin, 435 → 411 en
  session) : les marges cèdent, jamais le contenu. Le plancher est dit — 32 px hors crise, et en
  session un **pas** de 44 px que la règle des cibles rend non négociable.
- **Balayage des glyphes littéraux** : six sites passent aux tracés `uiIcon`, et les deux familles
  qui restent en texte sont nommées (le vocabulaire abrégé des renvois, les glyphes de commande du
  dock).

**Témoins**

Deux entrées neuves : la section `A129 · l'atelier d'import` d'`audit-doctrine` — vrai `.zip`
fabriqué par `zipBuild`, entré par le point d'entrée réel, vérifiée capable d'échouer (filtrage
neutralisé et forçage réintroduit → trois rouges) — et la surface `atelier d'import` d'`audit-a11y`,
qui construit son cas avec les deux natures **et** une pastille : sans elles, la moitié des objets
de la rangée ne serait pas mesurée.

## [5.7.0] — 2026-08-13
### « La bonne information, au bon moment, au bon endroit »

Audit transverse passé à trois tests : le **LIEU** (l'information est-elle là où le geste a
lieu ?), le **MOMENT** (arrive-t-elle avant la décision ?), le **GESTE** (le plus fréquent est-il
le moins cher ?). **Rien dans ce lot ne déduit quoi que ce soit d'un paramètre patient** : chaque
apport est une soustraction d'horodatages, un comptage de cases, ou un déplacement d'information
déjà présente vers l'endroit où elle décide. La doctrine complète est dans `AGENTS.md`
§ « Lot v5.7 » (A113 à A123).

**Pendant le soin**

- **La barre de retour au bloc courant.** Trois mécanismes ramenaient déjà au soin et aucun ne
  couvrait le cas le plus fréquent : `landOnBout` ne joue qu'à la réentrée dans la fiche,
  `ovAdvanceRender` qu'au geste d'avancement, `cxScrollTo` qu'à l'entrée sur complication. On
  défilait pour relire une étape ou vérifier une dose, et l'on remontait en cherchant la carte à
  bordure bleue. Une zone flottante **bornée** — sur le précédent déjà accepté du geste d'entrée
  (v4.73.0) — n'existe que tant que la carte du bloc courant est *entièrement* hors de la zone
  utile, nomme sa destination et s'efface d'elle-même. Elle ne défile jamais toute seule.
- **Le retour d'interruption restitue la conscience de situation.** Vérifié : zéro occurrence d'un
  « temps depuis le dernier geste » dans le fichier — les cinq écouteurs de `visibilitychange`
  persistaient, reprenaient l'audio, redemandaient la veille, mais aucun ne disait à quelqu'un qui
  revient depuis combien de temps il n'était plus là. Une ligne, en tête de la carte du bloc
  courant, au-delà de deux minutes d'absence, effacée **au geste suivant** — jamais après un délai.
- **Un compteur dit « il y a », pas seulement « à ».** La trace disait l'instant du dernier
  incrément ; en réanimation la question est toujours « ça fait combien de temps ? ». Les deux
  désormais : le T+ se relit, le « il y a » décide. Vivant, sans re-rendu, **sans aucun seuil** —
  un seuil serait un jalon, et les jalons sont un champ d'auteur. Le chiffre pousse au tap
  (130 ms, `transform` seul, remplacée et jamais mise en file).
- **L'imminence d'un minuteur est un état, et le tri devient vivant.** L'ordre suit le temps
  restant, l'alarme passe devant ; un minuteur qui entre dans ses vingt dernières secondes est
  **marqué** — glyphe △ et encre ambre, sans aplat ni battement : l'aplat reste réservé à ce qui
  exige une action maintenant, le battement est la grammaire de l'alarme. La réorganisation est un
  FLIP en `transform` pur (180 ms). **Rien ne bouge sous un doigt posé**, ni pendant les 1,2 s qui
  suivent le geste : assez pour lire la réponse de la carte qu'on vient de toucher. Non bloquant
  par construction — le délai ne suspend que la réorganisation.

**Avant et après le soin**

- **« Terminer la session ? » dit ce qui reste ouvert** — deux lignes de faits comptés, au seul
  instant où ils servent encore. « Terminer » reste rouge plein et actif : une checklist annonce
  son incomplétude, elle n'interdit pas de la quitter. Ni score, ni pourcentage, ni « conformité ».
- **Ce que la fiche embarque se dit avant qu'on entre.** En voie étroite — la cible principale — un
  minuteur à cycles écrit par l'auteur était invisible tant qu'on n'avait pas démarré. Une ligne
  dérivée : « 6 blocs · 2 minuteurs · 1 complication déclarée ». Rien à dire, aucune ligne.
- **Une aide révisée depuis votre dernier passage le dit.** Dans une bibliothèque partagée, un
  collègue révise une aide qu'on croit connaître par cœur. La ligne ne conditionne rien et ne dit
  pas *ce qui* a changé — « Versions » est dans le menu ⋯ pour cela.
- **Le compte rendu donne l'écart, et rien d'autre.** Une colonne Δ entre deux gestes du **même**
  objet, nue : ni moyenne, ni intervalle cible, ni couleur qui vire — ce vocabulaire ferait
  basculer le document du côté de l'évaluation par le logiciel.

**Pour l'auteur**

- **La relecture cesse de ne signaler que des fautes : elle propose.** Les six détections
  existantes étaient toutes des manques. Trois détecteurs lisent désormais le texte *de l'auteur* :
  une cadence (« toutes les 3 min », « à 5 min », « q4h ») propose un minuteur à cycles **avec la
  période lue dans sa phrase** ; « renouveler / seconde dose / nouveau choc » propose un compteur ;
  une étape vitale sans aucune ★ propose le memory item. Rien n'est jamais créé automatiquement, le
  texte n'est jamais réécrit, le compteur naît **sans nom** — deviner un mot serait la
  dégénérescence de « PA 2 » sous un autre visage. Un seul chemin de création (`edAdd`), et un refus
  ne revient pas de la séance.

**Deux propositions retirées après vérification, et c'est la même leçon.** Le téléchargement de
fond des documents existe déjà, systématique et pour toute la bibliothèque — la proposition aurait
*restreint* aux épinglées une garantie volontairement universelle. Et le virage au vert de
« Continuer » est déjà entier ; il n'y manquait qu'un fondu, or le libellé bascule au même instant :
on aurait obtenu une couleur qui s'attarde sous des mots qui ont déjà sauté.

**Décor et garde-fous.** La fiche d'exemple ACR porte un second minuteur déclaré — le
réordonnancement vivant n'avait sinon aucun cas à rencontrer, et un témoin écrit sans cas est un
vert qui ne mesure rien ; il est à relance manuelle, un second minuteur *cyclique* faisant
disparaître le cas d'un autre témoin (`cycleHint`). Quatre sections entrent dans `audit-doctrine`
(P1, Q2, P4b, Q1), toutes **vérifiées capables d'échouer** — défauts réintroduits, 9 rouges au
total, fichiers restaurés à l'octet. Le cliquet `pointer-events:none` de `check-anim` passe de 18 à
19, motivé sur place. 47 témoins purs neufs (1040 au total, sur les deux moteurs).

## [5.6.0] — 2026-08-09
### Refonte complète du design — direction « verre clinique, mat »

Refonte menée avec Claude Design (phases 0 à 6 : audit de l'existant, directions explorées,
convergence, design system, écrans qui font foi, passation en sept lots). Les maquettes livrées
sont la référence d'implémentation ; ce qui suit est ce qui a été porté dans le monofichier, avec
les décisions consignées — la doctrine complète est dans `AGENTS.md` § « Refonte v5.6 ».

**TROIS MATIÈRES, TROIS NATURES.** Sombre (`--sys`) = SYSTÈME : la capsule d'état et le dock, les
deux seuls objets sombres du produit — trouvables sans lire. Blanc (`--work`) = TRAVAIL : carte,
feuilles, éditeurs ; seule matière qui projette une ombre. Gris (`--amb`) = AMBIANCE. La
séparation commandes/affichage de l'ECAM passe désormais par la MATIÈRE, plus par des bandes et
des filets empilés — ce qui **rouvre la v4.25.0** en gardant son esprit et en inversant sa forme.

- **Lot 1 — tokens.** Nouveau bloc `:root` (matières, encres, registres, échelle typographique
  fermée à sept crans `11 / 12 / 13,5 / 15 / 17,5 / 21 / 24`, rayons `8 / 10 / 12 / 14`, une
  seule ombre, cibles, mouvement) ; les anciens noms deviennent des ALIAS, aucune règle CSS n'a
  eu à changer pour que le fichier compile. **Un seul ambre** (`--verify` et `--alert` fusionnent
  en `--warn`) et **un seul rouge**. Nuit redessinée en OLED GRIS (`#0d0f13`) : sur OLED, le noir
  pur fait « trou » et le halo des textes clairs fatigue. Trois fontes vendorisées (Manrope
  variable 500-800, IBM Plex Mono 600/700, 45 Ko au total, précachées) : le SERIF ne sort que sur
  un titre de fiche, le MONO que sur une valeur, Manrope tient tout le reste.
  **⚠ TROIS TOKENS NE SONT PAS DES ALIAS, et les harnais l'ont prouvé** : `--paper` reste un
  blanc FIXE (aliasé sur la matière travail, le QR se peignait en encre sombre sur fond sombre —
  indéchiffrable, et le défaut ne se serait vu qu'au moment de scanner) ; `--shadow-up` garde son
  décalage négatif ; `--ctl-line` tient 3:1 là où le `--line-strong` du système n'en fait que 1,6
  — WCAG 2.2 § 1.4.11 vise les bordures de COMPOSANT, c'est-à-dire la case qu'on vise avec des
  gants. Le bloc de dérivation `color-mix` de la direction A est retiré : les valeurs tonales du
  nouveau système sont des accords qu'aucun mélange ne reproduit.
- **Lot 2 — chrome de crise : deux objets, deux natures.** `#crisisBand` (comme bande),
  `#crisisCtrl` et `#crisisDock` (comme rangées) laissent la place à une **capsule d'état**
  (matière système, gabarit constant de 50 px, tap = volet minuteurs/compteurs/journal) et à un
  **dock bas de quatre touches** (⤢ Tout voir · ▤ Consulter · ⚡︎ Complications · ⏱ Noter l'heure).
  Chrome haut **175 → 131 px** à 390 px, trois `border-bottom` empilés en moins, et les quatre
  gestes de session sous le pouce. En-tête à trois zones ancrées (A14) : le **sur-titre
  « ■ MODE CRISE » passe AU-DESSUS du titre** — accolé au nom de la fiche, le statut se lisait
  comme un fragment de ce nom — et la pilule `#hdrCrisis` est purgée (un seul énoncé du mode).
  `fitCtrlRow` disparaît avec la rangée qu'elle ajustait ; `syncHdrScroll` reste, parce que
  `--hdr-h` et `--stick-top` nourrissent le rail A→Z, le rail de lecture, `stickBase()` et le
  `scroll-margin` qui empêche le masquage total d'une cible d'ancre (exigence AA).
- **Lot 3 — carte de travail et journal.** L'étape critique se **MARQUE** (case rouge + ⚠ + corps
  17,5 px + cadence mono ambre) et ne prend plus **ni cadre ni aplat** : mesuré à l'usage, à cinq
  étapes l'aplat happait l'œil et détruisait la lecture de la séquence — l'aplat coloré est
  désormais réservé à l'alarme active, et il n'y en a qu'un à l'écran. « ICI » quitte la carte
  (trois signaux l'y désignaient déjà, `aria-current` compris) et ne vit plus que dans une LISTE.
  L'historique du journal se replie en **une ligne-bilan qui se tire** (« ⌄ fait · ✓ n passages ·
  a→b ») dès qu'elle existe : ~11 objets à l'écran contre 25.
- **Lot 4 — rail et cockpit.** Cartes de minuteur à gabarit FIXE entre veille et échu (A9 : un
  changement d'état non commandé ne déplace jamais rien — le piège n'est pas la structure, c'est
  le libellé qui passe sur deux lignes). **A15 : « Consulter » n'évince plus le bloc au cockpit**
  — à partir de 1200 px la référence s'ouvre dans la colonne d'état, le bloc reste sous les yeux
  et cochable ; sous 1200 px elle reste une excursion à retour nommé.
- **Lot 5 — accueil.** Navigation uniformisée : le sélecteur « A–Z | Catégories » choisit la CLÉ
  DE GROUPEMENT de la même liste, et le rail droit est le MÊME index dans les deux modes (lettres
  ↔ pastilles de catégorie) — on ne perd jamais de fiche en changeant de clé, c'est ce qui
  distingue un groupement d'un filtre. Le résumé des filtres actifs rejoint l'en-tête de section.
  La session vive devient le seul objet sombre de l'accueil.
- **Lots 6 et 7 — fenêtres, documents, éditeur.** Re-peau par les tokens ; les règles nommées du
  plan étaient déjà tenues (listes cochables jamais barrées, session terminée = archive sans
  matière système ni dock, exercice = placard permanent jamais filigrane).

**Volets système — doctrine d'occultation consignée (V1-V3).** Un volet ne s'ouvre que sur tap
d'une touche du dock ; fermeture triple (re-tap, ✕, tap hors volet) plus le retour système ;
l'alarme reste TOUJOURS en vue (capsule en haut, volets en bas — règle FMA de l'ECAM) ; hauteur
plafonnée à 45 % et l'interruption s'annonce en tête (AC 120-71B §5.5). **⏱ l'heure prime** : le
tap horodate immédiatement, le volet n'est que la nomination facultative. **⚡︎ bifurcation
annoncée** : nom, condition d'entrée et destination avant le tap — et **à un seul événement il n'y
a pas d'index**, la touche porte son nom et l'on entre d'un tap.

**Ce que les harnais ont attrapé, et qui n'aurait pas été vu autrement** : le QR indéchiffrable en
thème sombre, l'ombre montante devenue descendante, la capsule à 27 px de cible dans l'en-tête, le
focus invisible sur un champ d'éditeur, le segment ÉCHU sacrifié par la boucle d'ajustement parce
qu'un `flex:none` l'empêchait de rétrécir, et une fonction (`ovPaintLive`) emportée par une
suppression à la tranche. Les témoins ont été **retargés, jamais désarmés** : ce qui change est
l'adresse d'un composant, pas la propriété mesurée — et là où la propriété elle-même a changé
(l'échelle typographique, le seuil du code d'appariement, « ICI » sur la carte), le témoin dit
désormais ce que la règle veut dire plutôt qu'un chiffre.

**Passe de fidélité aux maquettes (même version).** Relecture écran par écran contre les planches
« 4 — Écrans », qui font foi ; les divergences relevées portaient toutes sur la MATIÈRE et la
DENSITÉ, jamais sur la structure :
- **Carte de bloc** : plus de liseré d'accent ni de pastille numérotée — la carte est une surface
  de travail (filet fin, rayon 14, rembourrage 18, l'ombre unique), son en-tête est « BLOC n » en
  petites capitales grises avec le compte en mono à droite, et le titre prend le cran 21. A12 est
  tenue autrement et mieux : la position se lit à ce que la carte est le seul bloc OUVERT, en tête
  de journal, et porte `aria-current="step"` — le seul des trois canaux qu'un lecteur d'écran voit.
- **Pied de carte** : « Vérifier :: » et « Continuer » sur UNE rangée, le premier à gauche, le
  second dernier et pleine largeur restante ; et « Vérifier :: » n'existe que si le bloc porte
  réellement des challenges (A7 était écrite, elle n'était pas appliquée).
- **Chapeau « Ne pas oublier »** : replié, ce n'est plus un pavé au registre ALERTE en tête de la
  colonne d'action mais une LIGNE — ■ rouge, mot en encre douce, compte en pilule neutre. Déplié
  et hors session, il reprend son cadre : c'est alors la condition d'entrée, et le registre est
  juste. Un pavé rouge permanent désensibilisait au rouge exactement comme l'aplat d'une étape.
- **Rail** : la colonne AFFICHE, on la touche pour COMMANDER. Une carte de minuteur y montre nom ·
  cycles · valeur (76 px) ; barre, « Cycles : n » et boutons ne paraissent qu'au tap — sauf pour un
  minuteur ÉCHU, dont le « RELANCER » reste sous les yeux, et pour les ± d'un compteur, devenu une
  RANGÉE. Un repère posologique signalé s'y marque sans aplat. Le panneau et le volet gardent la
  carte complète : on les ouvre justement pour régler.
- **Accueil** : la recherche devient une carte de travail (elle était un creux gris, lu comme une
  zone désactivée), l'avatar un carré arrondi de matière système à initiales (le disque bleu plein
  était le plus gros aplat coloré de l'écran, devant tout contenu clinique), les deux autres
  boutons d'en-tête des glyphes de commande, et le sélecteur « A–Z | Catégories » prend sa propre
  rangée au-dessus des sections qu'il réordonne.
- **Case d'étape à 26 px** (la cible reste la rangée entière, 60 px).
- **Au cockpit, la capsule cesse d'être une capsule** (signalé à l'usage : « sur ordinateur ça
  fait moche »). Montée dans l'en-tête, elle y gardait sa MATIÈRE SYSTÈME : une pilule sombre
  posée sur une barre claire, entre un titre et deux glyphes — un objet qui a l'air d'un contrôle
  sans en être un. La matière suit désormais le LOGEMENT : dans l'en-tête, l'état est du contenu
  d'en-tête (encre de la barre, registres du thème clair pour l'alarme, fond transparent), et il
  est CENTRÉ EN ABSOLU comme A14 l'exige — un titre long ne déplace plus l'alarme. Le sombre reste
  là où il veut dire quelque chose : la capsule en étroit et le dock. Coût de hauteur nul (65 px,
  inchangé), cible 44 px par le halo.
  ⚠ Deux défauts trouvés en le faisant : `flex:1` dans un conteneur en ajustement au contenu
  effondrait la boîte, et la boucle d'ajustement — qui MESURE — en concluait que plus rien ne
  tenait : elle sacrifiait le segment ÉCHU et n'affichait que « +1 ». Et `audit-a11y` CRÉDITAIT un
  halo forfaitaire de 8 px dès qu'un élément était en position relative, au lieu de lire l'inset
  réel : il déclarait trop petite une cible de 46 px, et — plus grave — en offrait 8 gratuitement à
  tout élément positionné pour un autre motif. Il mesure désormais ; il a immédiatement trouvé une
  compaction morte qui rabotait les touches du dock à 41 px.

⚠ Deux défauts introduits par cette passe et rattrapés par les harnais : le nom d'un minuteur repris
en `--ink-3` tombait à **2,32:1** (l'encre d'étiquette n'est jamais du texte porteur — règle écrite
depuis la v4.5), et l'étiquette d'un bloc HORS TRONC affichait « ⚡ Bloc » alors qu'un bloc détaché
n'a, par construction, pas de numéro.

Contrôles : `npm run check` vert (échelles typo, espacement, rayons, couleurs, paliers, SW,
vendor, uploads, SQL, stores, icônes, harnais, hashs CSP), `npm test` 952/952 sur les deux
moteurs, `npm run audit` **25/25 tâches vertes** (20 harnais), `design:build` régénéré.

## [5.5.0] — 2026-08-08
### Les boucles évoluent au compte : jalons, renvoi d'excursion, période de cycle

Audit demandé par l'auteur sur le déroulé de l'algorithme : *« l'ACR restera toujours
choquable / pas choquable / RACS — mais au bout de 3 CEE, se poser la question d'une FV
réfractaire, qui fera changer les pads ; puis l'analyse reste toutes les 2 minutes, commune
avec le début »*. Le déroulé en boucle était couvert (« ↺ reprendre à n », passages ×n,
convergence) ; ce qui n'existait pas, c'est un contenu qui **change au k-ième passage ou au
n-ième choc**. L'auteur n'avait que du texte statique (du bruit avant le seuil) ou une
excursion « à tout moment » dont l'**entrée reposait sur la mémoire du compte** — l'inverse de
la doctrine QRH, alors que le runtime connaît les deux nombres (`passInfo`, les compteurs).

- **P1 — le jalon de boucle** (`b.milestones`, facultatif, ≤ 3 par bloc) : une phrase d'auteur
  conditionnée « à partir du nᵉ passage » ou « quand le compteur X atteint n ». Modèle ECL sur
  la carte du bout : la ligne existe dès le premier passage, estompée, **condition en toutes
  lettres et progression vivante** (« Chocs délivrés 2/3 » en mono) ; au seuil elle passe au
  registre ATTENTION — ambre, jamais rouge, franchissement en ≥ (un fait ne s'acquitte pas), et
  **rien ne se déclenche** (règle 11 : pas de son, pas de saut — mesuré Δ = 0 px ; l'annonce
  passe par `#srLive`). Repeinture chirurgicale dans `setCounterVal`, **avant** le garde `!el` :
  en étroit, le volet des compteurs peut être absent du DOM pendant qu'un évènement distant
  incrémente — le jalon, lui, est sur la carte et doit suivre. Un compteur qui ne résout pas
  rejette la rangée dans `migrate` (un jalon qui ne mesure pas est mort).
- **P2 — le renvoi est une porte d'excursion, pas une navigation nouvelle** : `go` désigne la
  cible d'une excursion **déclarée** et le bouton ⚡ réutilise `data-cxgo`, donc `cxEnter`, ses
  gardes de partage et son retour prévu (« ↩ Reprendre » — l'analyse reprend, commune avec le
  début). Le bouton n'est tapable qu'au seuil : avant, la rangée ⚡ constante du pied suffit —
  l'action au pied de l'alerte est la règle ECAM déjà écrite pour `onDue`.
- **P3 — l'état au point de décision** : la progression vivante du jalon met le compte sous les
  yeux à l'endroit où l'on répond (le rang « passage n/N » existait déjà sur la carte).
- **P4 — la boucle dit sa période** : quand la fiche déclare **un seul** minuteur à cycles,
  les renvois de boucle textuels la portent (« ↺ reprendre à 2 · toutes les 2 min », statique
  et parcours) ; à deux minuteurs, rien — annoter serait une devinette.
- **Les vues de structure annoncent les jalons d'emblée** (rien de caché qui ne s'annonce) :
  marqueur △ + détail déplié dans l'Échelle (forme neutre — colonne désaturée), lignes inertes
  dans le Parcours et le Statique, condition en toutes lettres partout.
- **Éditeur** : rangées de jalon par bloc (condition · seuil · compteur · renvoi vers une
  excursion déclarée), porte d'ajout masquée au plafond de 3 ; la bascule vers « compteur »
  pré-pointe le premier compteur — on ne fabrique jamais l'état que `migrate` rejette.
- **La fiche d'exemple ACR exerce le mécanisme** (lot T13) : excursion « FV réfractaire (CEE
  inefficaces) », bloc hors chaîne (pads en antéro-postérieur), jalon « Chocs délivrés ≥ 3 »
  avec renvoi. Le **prompt IA** documente `milestones` et interdit d'inventer un seuil clinique.
- **Qualification réglementaire écrite avant le développement**
  (`docs/deploiement-et-conformite.md` § 2, « Le cas des jalons de boucle ») : une règle
  d'auteur affichée au moment que l'auteur a défini — même famille qu'`onDue` ; aucun paramètre
  patient (les compteurs comptent des gestes de l'équipe) ; la ligne à ne pas franchir est
  nommée (paramètre patient, seuil déduit par le logiciel, déclenchement autonome).
- **Témoins** : 17 contrôles purs (`tests.html` — sanitisation, progression, `cycleHint`),
  section doctrine « QRH · jalons de boucle » (12 contrôles qui construisent leur cas sur
  l'ACR, vérifiée **capable d'échouer** : activation neutralisée → 4 rouges, fichier restauré à
  l'octet), 2 contrôles de contrat dans `audit-prompt` (le jalon du schéma traverse `migrate`).
  `SHARE_KEEP` couvre déjà (`blocks` voyage entier) — `schema.sql` inchangé.

Rotation du journal (règle des 20 entrées) : 5.0.0 → 5.0.2 partent dans
`docs/changelog/v5.md` (créé), 4.77.0 → 4.79.0 rejoignent `docs/changelog/v4.md`.

## [5.4.4] — 2026-08-08
### Les audits cessent d'être chronophages — sections ciblables, tranches, cache vert (aucune sonde changée)

Audit du dispositif d'audit lui-même, demandé par l'auteur (« peut-on réduire le temps en
gardant la même sécurité ? »). Mesuré d'abord : la passe complète coûtait **216,7 s de temps
mural, et audit-doctrine à lui seul EST ce temps mural** (le pool absorbe les 19 autres harnais
pendant qu'il tourne) ; surtout, confirmer UN témoin corrigé coûtait le harnais ENTIER, « et ça
plusieurs fois, pour plusieurs fichiers » — 29 des 45 derniers commits touchant `index.html`
avaient dû toucher des `audit-*.mjs`.

- **Sections ciblables** (`secRunner` dans `harness.mjs`) : les 51 sections de doctrine et les
  23 de partage — indépendantes par construction, seul état partagé les compteurs ok/ko — sont
  enveloppées dans `await sec('nom', …)`. `node scripts/audit-doctrine.mjs --grep <motif>`
  confirme une section en **1,5 à 8 s au lieu de 216,7** ; un motif sans correspondance ÉCHOUE
  bruyamment en listant les sections (une passe vide aurait l'air verte) ; toute passe filtrée
  s'annonce PARTIELLE jusque dans son bilan final. La transformation (mécanique, script à garde
  d'abandon) est **vérifiée par équivalence** : sortie byte-identique à l'avant-refactor,
  737/737 et 291/291 contrôles, même ordre.
- **Tranches parallèles** (`tranches: n` dans `HARNAIS`) : doctrine se joue en 4 processus
  `--shard k/4`, a11y en 2 (découpe du tableau SURFACES ; la sonde focus 2.4.11 en tranche 1
  seule), partage en 2. Passe complète **216,7 → 156,4 s** au pool par défaut, **126,0 s** à
  `AC_JOBS=5` (mesuré vert ; le défaut RESTE 4 — protection CI et règle « un rouge sous charge
  se confirme en rejouant seul »). GARDE-FOU : chaque tranche imprime `##SEC joues=j total=N`
  et le lanceur vérifie que la somme couvre le total — une tranche qui perdrait des sections
  serait une troncature silencieuse ; vérifié CAPABLE D'ÉCHOUER (rouge fabriqué puis restauré).
- **`npm run audit -- --rouges`** rejoue les seuls harnais rouges de la dernière passe (état
  dans `.audit-etat.json`, racine, gitignoré), annoncé PARTIELLE ; aucun rouge enregistré → il
  le dit et sort vert.
- **Cache de passe verte** : une passe complète verte enregistre le SHA-256 de tout ce qui peut
  influencer un verdict (servables de la racine, `vendor/`, `scripts/*.mjs`, moteur) ; si rien
  n'a changé, `npm run audit` LE DIT au lieu de rejouer — des entrées identiques octet à octet
  donnent le même verdict — et `--force` rejoue quand même. Une passe partielle n'écrit ni ne
  consomme jamais ce cache.
- **Ce qui n'a pas été fait, et pourquoi** (écrit dans AGENTS.md) : pas de carte « fichier
  modifié → harnais à jouer » (monofichier + dix-neuf pièges de cascade : une édition CSS
  anodine casse des témoins dans des harnais sans rapport — une carte serait un vert menteur) ;
  pas de témoins auto-régénérés façon snapshots (un contrôle qui ne peut plus échouer ne prouve
  rien, leçon v4.31.1) ; k5 non découpé (scénario séquentiel monopage, ~67 s incompressibles).
  **La porte de commit est strictement inchangée** : la passe COMPLÈTE avant chaque commit, que
  la CI rejoue. Le coût de PENSER les témoins quand le code change n'est pas racheté : c'est lui
  la garantie.

## [5.4.3] — 2026-08-07
### Le rail droit se rééquilibre à 780-1199 px — les familles de traçabilité réunies partout

Audit demandé par l'auteur (« la sidebar n'est-elle pas trop chargée aux largeurs
intermédiaires ? ») puis décision R1+R2 sur maquette chiffrée à l'échelle des mesures réelles.

- **Le constat mesuré** (session réelle, fenêtre du rail 642 px) : 1 625 px de contenu —
  **60 % enterré** sous un pli invisible (barres de défilement masquées au repos), le journal à
  **583 px sous le pli**, séparé des compteurs par la posologie et toute l'Échelle : la
  séparation exacte que la v5.4.0 avait corrigée en étroit, jamais portée au rail.
- **R1 — le journal remonte contre les compteurs, en dépliant d'une ligne** (`details.rail-fold`,
  résumé en grammaire `.rail-head` + compte) : les trois familles de traçabilité redeviennent
  voisines à TOUTES les largeurs. Replié par défaut sous 1200 px, **déplié par défaut en
  cockpit** (rail à 4 zones). Le compte du résumé suit chaque repère, local ou distant.
- **R2 — sous 1200 px, l'Échelle devient un dépliant d'une ligne** annonçant son compte ET la
  position courante (« ici : ① Mesures immédiates »), régénérée à chaque navigation sans toucher
  à l'état ouvert/fermé. À ≥ 1200, rien ne change : l'Échelle vit dépliée dans la colonne du plan.
- **Rien ne se déplie ni ne se replie tout seul** (règle 11) : seul le tap sur le résumé (ou
  Entrée/Espace — `<details>` natifs, `aria-expanded`, cibles 44 px, focus visible). État
  transitoire par fiche (`SHARE_LOCAL`, remis aux défauts de largeur à l'ouverture) — regarder
  n'est pas régler. Conformité argumentée : une zone repliée qui S'ANNONCE est plus fidèle à
  l'ECAM qu'un contenu enterré muet (modèle ECL v4.16.4) ; l'état VIVANT (chronos, compteurs,
  échu) n'est jamais replié ; même grammaire de dépliant que le chapeau et l'index ⚡ (§5.5).
- **Résultat** : contenu du rail à 900 px **1 625 → ≤ 1 100 px**, plus rien de caché qui ne
  s'annonce. Divergence assumée avec la maquette (dite dans AGENTS.md) : « Surveiller ensuite »
  vit dans le corps de l'Échelle et se replie avec elle — sa source reste la section ③ du flux.
- Sondes dédiées vertes sur Chromium et WebKit (défauts par largeur, dépliage réel, comptes
  vivants, « ici » qui suit la navigation) ; passes complètes 16/16 check · 939 × 2 tests ·
  **20/20 harnais du premier coup**. Trois leçons de sonde consignées (compter les titres sans
  distinguer résumé et corps replié ; référence DOM détachée après re-rendu).

## [5.4.2] — 2026-08-07
### Six correctifs d'usage — clavier du volet, surligneur PDF, quai accès unique, repères qui suivent

Tous signalés à l'usage réel (PWA/smartphone), chacun vérifié à la mesure sur les deux moteurs.

- **Le bandeau système passe au-dessus du rail A→Z** : le rail (fixe, z 15, voile de fond)
  peignait par-dessus « Nouvelle version disponible », masquait sa droite et pouvait intercepter
  le tap sur son × (`touch-action:none` sur toute sa bande). `.sys-banner` prend
  `position:relative; z-index:16` — au-dessus du rail, toujours sous l'en-tête (20) : une
  notification qu'on doit lire et rejeter prime sur trois lettres d'index recouvertes
  transitoirement.
- **Modifier une heure dans le volet ne fait plus sauter le scroll** (« très mal géré quand le
  clavier s'ouvre ») — deux causes cumulées : le `focus()` programmatique défilait le DOCUMENT
  pour « révéler » un champ déjà sous le doigt dans une couche fixe (→ `preventScroll`, règle
  v4.78.0) ; et la hauteur du volet était bornée sur `--vvh`, que le CLAVIER rétrécit — elle
  passe à `100svh` (constante : ni barre d'outils ni clavier), la règle du rail A→Z (v5.0.1)
  appliquée au clavier près. Vérifié : focus → 0 px de saut page et volet, hauteur immune au
  rétrécissement de `--vvh`.
- **Le surligneur PDF est FIXE, il ne suit plus le thème** (« pas assez visible, encore plus en
  clair ») : une page PDF garde SES couleurs — `--verify-soft` + multiply donnait un crème quasi
  invisible en clair et un autre rendu en sombre pour le même document. Jetons fixes deux-thèmes
  `--pdf-hl`/`--pdf-hl-ring` : jaune surligneur universel en fondu NORMAL (multiply s'éteint sur
  fond sombre) + anneau ambre — bande effective #FFEE99 sur page blanche, voile éclaircissant +
  anneau sur page sombre. La pilule ‹ n/N · p. x › passe à l'**ardoise fixe** `--rt-*` (celle du
  toast) : identique dans les deux thèmes, lisible sur toute page.
- **« Dans les documents » respire** : 24 px au-dessus du titre du groupe (il se lisait comme la
  méta de la dernière carte de résultats).
- **Les repères posologiques suivent le bloc courant pendant la navigation** (bug confirmé — le
  classement v4.23.0 n'était calculé qu'au rendu complet) : générateurs à site unique
  (`posBlockHtml`/`posRailHtml`) et `repaintPoso()` rejouée par les trois chemins ciblés (journal,
  statique, mono-bloc) — jamais au cochage ; le pli « n autres repères » garde son état. Vérifié :
  « Continuer » vers un bloc → son médicament passe en tête.
- **Le quai est l'accès unique au panneau en étroit** (décision utilisateur : « il appartient
  maintenant au rail ») : la rangée repliée du flux est SUPPRIMÉE (`.rt-collapsed`, `#rtOpen`,
  `rtRowLabel` — règle 14, grep vérifié) — le double accès de la v5.4.1 avait perdu sa moitié le
  jour où le volet a su suivre le défilement. Le volet se rend même sans minuteur ni compteur (le
  journal y loge) ; le rappel du quai devient le seul annonciateur de ce qui est caché. Limite
  dite : sur une fiche mono-bloc en étroit, « Noter l'heure » s'atteint par le quai (cette carte
  n'a jamais porté le bouton M2 — l'aligner serait une décision séparée).
- Témoins : trois sondes passent par le vrai geste du quai (ex-`#rtOpen`) ; les fixtures des
  témoins d'atterrissage v5.0.7 construisent désormais leur cas (le panneau du flux payait ~70 px
  de leur marge de défilement — sans lui, le contrefactuel s'écrêtait). Passes : 16/16 check ·
  939 × 2 tests · 20/20 harnais.

## [5.4.1] — 2026-08-07
### Le volet du quai devient un étage du chrome, les familles se nomment, et le chrome ≥ 1200 px monte dans l'en-tête

Trois retours d'usage, chacun tranché sur maquette ou après itérations mesurées à l'écran.

- **Le dépliant du quai est un volet FIXE, étage du bloc de chrome** (question de l'auteur :
  « contraire à ECAM/QRH ? » — non : ouvert et fermé par l'utilisateur seul, jamais
  d'auto-ouverture, l'alarme jamais masquée — même statut de consultation que le menu ⋯). Il SUIT
  le défilement : minuteurs, compteurs et journal restent sous les yeux en parcourant les étapes.
  Après trois retours (« pas une continuité du quai », « fixed dans fixed », « deuxième niveau de
  scroll ») : PLEINE largeur, collé au quai (le filet du quai fait la séparation d'étages, patron
  #refBar), panneau intérieur sans boîte, UN seul défileur, en-tête ✕ non épinglé. Fermeture par
  re-tap du quai, ✕, Échap et retour système (`_histArm`/`_histBackAction`). La rangée du flux
  garde sa géométrie de poussée : deux accès, deux arbitrages.
- **Les familles se nomment** (« minuteurs / compteurs / journal peu identifiables — tout se colle
  et se mélange ») : sous-titres MINUTEURS / COMPTEURS / JOURNAL DES ACTIONS partout — grammaire
  `.tk-head` + compte en pilule dans le panneau et le volet, `.rail-head` + `.rail-n` dans le rail
  large. Les compteurs n'avaient aucun en-tête ; « ＋ Minuteur PA » rejoint la famille des
  minuteurs qu'il crée.
- **À ≥ 1200 px, le chrome de crise monte dans l'EN-TÊTE** (option A′, choisie sur maquette après
  DEUX itérations refusées — la bande pleine largeur réservait ~110 px pour des contrôles qui ne
  vivaient qu'à gauche ; la version « colonne du plan » empilait trois boutons en volant sa
  hauteur au plan). « Tout voir », « Consulter » et le chrono SESSION vivent dans
  `#hdrCrisisSlot`, entre le titre et les actions — chrome NOMADE au patron du pied de page
  (déplacés, jamais recréés), `body.chrome-hdr`, `stickBase`/`stickHeight` cessent de compter des
  rangées dont la hauteur est déjà celle de l'en-tête. **Coût de hauteur nul, mesuré** : en-tête
  65 px inchangé (compaction du dessin, jamais des cibles — halos de 44 px, attrapé par
  `audit-a11y` : 8 rouges sur le bouton Session à 37 px, réparés par le halo standard). Les trois
  colonnes commencent à ~83 px ; plus de bande ni d'« effet de tronquage » pour toute lecture de
  fiche à ce palier, statique et mono-bloc comprises. Sous 1200 px, rien ne change.
- Sondes dédiées 9/9 (Chromium + WebKit) : chrome dans l'en-tête, une seule rangée, en-tête ≤
  70 px, `--stick-top` = en-tête seul, état visible après 800 px de défilement, mono-bloc couvert,
  390 px inchangé. Passes complètes : 16/16 check · 939 × 2 tests · 20/20 harnais.

## [5.4.0] — 2026-08-07
### Le journal des actions rejoint le dépliant minuteurs, et l'heure se corrige comme on la tape

Trois retours d'usage en situation réelle, traités après proposition de solutions et décisions
de l'auteur ; plus un chantier vérifié resté en attente de publication (16 px tactile).

- **La correction d'heure accepte ce qui a un sens, et refuse en le disant** (« entrer 1547 pour
  15h47 ne fonctionne pas — trop strict ») : l'ancien format exigeait `H:MM[:SS]`, or le champ est
  `inputmode=numeric` et le clavier numérique d'iOS n'a pas de deux-points — le format canonique
  était intapable sur la cible principale ; et l'échec était MUET (saisie jetée sans un mot), d'où
  l'impression d'un format encore plus strict. `tkParseTime` (pure, 19 tests) lit les séparateurs
  libres (`15:47`, `15h47`, `15.47`, `15 47`) et les chiffres nus par longueur (`1547` → 15:47:00,
  `154723` → 15:47:23) ; une valeur impossible est REFUSÉE, plus écrêtée (« 15:87 » devenait
  15:59 — une heure fabriquée dans une trace de soin). Sur Entrée, l'illisible laisse le champ
  ouvert avec le registre ATTENTION (△ + « ex. 1547 ou 15:47 ») ; sur blur, le retour à l'ancienne
  heure s'annonce (#srLive).
- **Chips de recul « −1 · −2 · −5 min »** pendant l'édition d'une heure : le cas réel est
  « rattraper un geste noté en retard » — un tap vaut mieux qu'une heure retapée ; même mécanique
  non destructive (`origT` + « ↺ revenir »). Le tap passe par `preventDefault` au `pointerdown`
  (le blur détruirait la chip avant son click — leçon `.li-tools` v4.77.0), le chemin clavier par
  `relatedTarget`.
- **En étroit, le journal vit dans le dépliant minuteurs** (« ne pas mettre les compteurs et le
  journal au même endroit m'a perturbé — pour changer l'un puis l'autre on passe au-dessus des
  étapes ») : une seule rangée « Minuteurs · compteurs · journal — comptes », posée sous la carte
  du bloc (la place T2 du journal) ; ouverte du quai, tout arrive ensemble sous le quai (M11
  tenu : quai immobile, mesuré). Le geste fréquent ne bouge pas — « ⏱ Noter » et l'accusé restent
  dans la carte (M7) ; en large, le rail est inchangé ; une fiche sans minuteur ni compteur garde
  son journal autonome. `rtRowLabel` = source unique du libellé ; `renderTkOnly` repeint le compte
  de la rangée repliée quand le panneau n'est pas dans le DOM (repère posé depuis la carte ou reçu
  d'une session partagée — sinon compte périmé affiché comme vivant). Deux témoins d'`audit-partage`
  passent désormais par le vrai geste d'ouverture.
- **Un dépliant se reconnaît avant de se lire** (« difficile d'identifier que c'est un menu
  déroulant ») : rangée repliée en `--surface-3` — le ton du chrome, distinct dans les deux
  thèmes ; le contenu clinique reste seul en carte blanche — et déclencheur « ▾ Afficher » en
  pilule bordée. Niché dans le panneau, le journal est une section à filet, pas une carte dans la
  carte.
- **Publication du chantier « 16 px tactile » resté en attente** (signalé à l'usage iPhone :
  « quand on clique à l'intérieur d'un protocole l'écran zoome ») : le champ « Chercher dans la
  référence » était né à 12 px hors du bloc tactile des 16 px — Safari iOS zoomait au focus.
  `check-type` exige désormais que tout sélecteur posant < 16 px sur un champ figure dans la liste
  tactile ; il a attrapé trois autres champs jamais signalés (phase de bloc, lignes du chapeau,
  nom de minuteur). Les références « v5.3.2 » de ce chantier sont réalignées sur la version qui
  l'embarque réellement.
- Passes complètes : 16/16 check · 939 × 2 tests (Chromium + WebKit) · 20/20 harnais ; sonde de
  parcours dédiée 25/25 sur les deux moteurs (fusion, saisie, chips, refus annoncé, quai immobile,
  large inchangé, fiche sans minuteur).

## [5.3.1] — 2026-08-07
### Les résultats de recherche ne collent plus aux bordures — et un rembourrage mort depuis la v5.0.0

Signalé à l'usage sur la PWA (« résultats de recherche dans la barre fixée très collés à la
bordure du dessous ») ; les trois écarts mesurés avant/après.

- **⚠ Vingtième piège de cascade, et il préexistait** : `details.ref-toc[open]{padding-bottom:8px}`
  (0,2,1) perdait contre `#refBar>.ref-toc{padding:0 18px}` (1,1,1) — le rembourrage bas du
  dépliant « Rechercher · sommaire » de la barre fixée était silencieusement MORT depuis sa
  création (v5.0.0) : mesuré **1 px** entre le dernier objet et la bordure de coupure, pour le
  dernier lien du sommaire comme pour les rangées de résultats-documents (v5.3.0), qui ont hérité
  du défaut et l'ont rendu visible. Réparé en (1,1,2), jamais par l'ordre : 15 px sous le
  sommaire, 29 px sous une rangée seule.
- **Les rangées de résultats-documents respirent aussi vers le bas** : `.pf-docs` n'avait qu'une
  marge haute — dans la feuille « Toute la fiche », la rangée touchait le tableau SFAR en dessous
  (0 px mesuré). Marge basse de 14 px : un résultat n'est pas un en-tête de section, il ne se
  colle pas à ce qui suit.
- **Le « · Réindexer » du pied ne s'enroule plus en abandonnant son séparateur** : « · » restait
  orphelin en bout de ligne pendant que le bouton partait seul à la suivante — le geste est soudé
  à son séparateur (`.attix-act`, `white-space:nowrap`).
- **L'icône « Filtrer » passe aux réglettes** (décision utilisateur sur maquette comparative de
  cinq candidats) : l'entonnoir à queue pliée datait — trois curseurs horizontaux, la convention
  contemporaine du « affiner ce qu'on voit », dans la famille d'icônes au trait. Tracé mis à jour
  aux DEUX sites (SVG en dur de `#filtTog` + entrée `filter` d'`uiIcon`), duplication signalée
  des deux côtés comme pour l'icône `user`.
- Les autres surfaces livrées depuis la v5.2.0 (extrait « dans ‹nom› · p. n » des rangées, groupe
  « Dans les documents », pilule ‹ n/N › de la visionneuse) ont été re-mesurées : conformes aux
  gabarits existants. Passes complètes 17/17 check · 920 × 2 tests · 20/20 harnais.

## [5.3.0] — 2026-08-07
### La recherche dans les PDF va au bout du geste — auto-indexation, porteurs en résultats, surlignage dans la visionneuse

Quatre retours d'usage sur la v5.2.0, vécus sur la PWA de l'auteur le jour même, tous les quatre
livrés.

- **Le rattrapage d'indexation est AUTOMATIQUE — revirement assumé** (« l'indexation ne s'est pas
  lancée automatiquement, j'ai dû cliquer ») : la v5.2.0 exigeait un geste explicite pour ne
  jamais lancer de tâche de fond spontanée ; à l'usage, l'état nominal attendu est « mes
  documents sont trouvables », pas un bouton pour un travail que la machine sait faire seule.
  `ixLoadAll` met en file les documents en attente au démarrage — ~4 ms/page, un à la fois, à
  l'inactivité, et pdf.js ne se charge QUE s'il existe des documents à indexer (un démarrage
  ordinaire n'y touche pas). La ligne du pied devient un indicateur d'avancement ; son bouton
  « Indexer » reste, filet des cas où la file s'est arrêtée.
- **Le porteur du document est lui aussi un résultat** : chercher un mot qui ne vit que dans le
  PDF joint sort l'AIDE dans la liste (les trois vues, `entityDocHit` dans les filtres, renvoi
  croisé compris), avec l'extrait « dans ‹nom› · p. n » — le OÙ, jamais le contenu, qui n'est
  pas stocké. Le groupe « Dans les documents » reste : deux objets, deux gestes.
- **La recherche d'une entité couvre ses annexes** : le champ d'une référence et celui de la
  feuille « Toute la fiche » listent sous le champ (`#pfDocs`) les documents joints où tous les
  termes apparaissent ; un tap ouvre la visionneuse à la page, occurrences surlignées. Un mot
  absent replie la zone.
- **Les occurrences se surlignent dans la visionneuse et se naviguent** (« comme le texte des
  fiches ») : les PAGES viennent de l'index déjà en mémoire (coût nul), les POSITIONS sont
  retrouvées au rendu de chaque page visible (`pdfPaintHl` — `getTextContent` ~3 ms, en cache) et
  posées en rectangles `--verify-soft` en `mix-blend-mode:multiply`, même registre que le
  surlignage du texte. Pilule flottante ‹ n/N · p. x › : navigation par page d'occurrence. La
  position dans une ligne est approchée au prorata des caractères — le compromis qui évite
  d'embarquer la couche texte entière de pdf.js. Ouvert depuis sa RANGÉE : ni surlignage ni
  pilule — on vient lire, pas chercher.
- Vérification : `audit-pdfsearch` passe de 26 à **37 contrôles**, verts sur les deux moteurs —
  dont l'auto-rattrapage au démarrage sans clic, le repli sur mot absent, la boîte de chaque
  rectangle dans sa page, et l'ouverture neutre depuis la rangée. Deux témoins corrigés en les
  écrivant (un mot qui ne vivait que sur une page ne pouvait pas faire naviguer ; la rangée de
  documents d'une fiche vit dans « Consulter », pas dans le flux). Passes complètes 17/17 check ·
  920 × 2 tests · 20/20 harnais.

## [5.2.0] — 2026-08-07
### La recherche trouve dans les documents PDF — un index inversé, jamais une copie du texte

La recherche trouvait la FICHE, jamais l'endroit : un protocole de service joint en PDF pouvait
porter la seule mention d'une dilution, et rien ne la trouvait. Et deux correctifs de moindre
taille livrés dans la même version : le compte-rendu s'enregistre en PDF, et « Répéter en
exercice » n'allume plus l'accueil avant le premier geste.

- **Chercher dans les documents PDF** (`ixBuild`/`ixOpen`/`ixSearch`, purs et testés ; store
  IndexedDB `attidx`, base v6). La première approche — conserver le texte extrait et le balayer —
  a été REFUSÉE par l'auteur, à raison : ~100 % du poids du texte (546 Ko mesurés pour 200 pages)
  et un plafond obligatoire, donc des documents indexés à moitié. On fait ce que font Spotlight,
  Finder et Lucene : un **index inversé** — dictionnaire des mots distincts (front-codé) + pages
  de chaque mot (varint-delta, ou bitmap pour les mots trop fréquents). Le poids suit le
  VOCABULAIRE, qui sature : mesuré sur du français technique réel, 13,4 % du texte à 626 Ko
  (34 % à 49 Ko) — **aucun plafond, indexation intégrale, toujours**. L'index natif d'IndexedDB
  (`multiEntry`) a été mesuré et écarté : ×47 en occupation réelle ; SQLite FTS5 n'existe pas
  dans un navigateur et l'amener en WASM serait une seconde dépendance runtime (règle 13).
- **Aucun extrait dans les résultats, et c'est la clé** : la rangée « Dans les documents » donne
  le nom, le nombre de passages, les PAGES et la fiche qui porte le document — le contexte se lit
  dans le document, qu'un tap ouvre À LA PAGE (`openPdfViewer` accepte une page). pdf.js
  (1 773 Ko) n'est donc JAMAIS chargé pendant qu'on tape. Correspondance par sous-chaîne, comme
  le reste de la recherche (« drenalin » trouve « adrénaline »).
- **Indexation à l'arrivée du binaire — les CINQ arrivées** : `attPut(rec)` est le point
  d'étranglement unique (patron `persistLive`) ; trouvé en le posant, l'indexation n'était
  accrochée qu'à deux des cinq chemins (manquaient le « Télécharger » manuel, le téléchargement
  immédiat de la visionneuse et l'import .zip). `check-stores` compte désormais les sites
  d'écriture. File à l'inactivité, un document à la fois ; rattrapage des documents déjà là par
  un geste explicite (ligne du pied de la sidebar), jamais en tâche de fond spontanée.
- **Résilience** : deux familles d'échec distinguées — transitoire (binaire absent, pdf.js hors
  cache : rien n'est retenu, trois essais par session puis « Réessayer ») et durable (`scan` /
  `illisible` : état enregistré, sinon le compte « à indexer » ne descendrait jamais).
  `ixAdopt` est l'unique point d'adoption : un enregistrement illisible est JETÉ et le document
  redevient « à indexer » — le défaut inverse (un `null` rangé dans la table) aurait rendu tous
  les documents non ré-indexables au premier changement de version d'index. **Réindexer** existe
  pour tout (ligne du pied, avec confirmation) et pour un document (sa rangée d'éditeur). Le
  décodeur est TOTAL : enregistrement tronqué refusé en bloc, aucune boucle infinie possible,
  aucune page rendue hors du document.
- **Confidentialité** : l'index est DÉRIVÉ et strictement LOCAL — jamais synchronisé, jamais
  exporté (un dictionnaire EST la liste des mots d'un document clinique ; le faire voyager serait
  une catégorie nouvelle de donnée sortante, pour zéro gain — il se reconstruit en ~4 ms/page).
  Il vit dans la base de l'ESPACE : un compte par index sur un poste partagé, déménagé avec le
  reste, effacé avec le reste. Le contenu des PDF n'atteint jamais le DOM (aucun texte stocké,
  aucun extrait affiché) ; le seul texte non maîtrisé est le NOM du document, couvert par `esc()`
  et éprouvé par un témoin au nom hostile.
- **Le compte-rendu s'enregistre en PDF** (demande utilisateur) : « Télécharger » (.html) et
  « Imprimer » deviennent « Fichier .html » et « **Enregistrer en PDF** » (rempli) — le second
  EST le chemin d'impression (iframe A4), seul producteur de PDF du projet ; un seul bouton pour
  ce chemin (AC 120-71B §5.5), le .html restant le repli qui ne dépend d'aucun dialogue système,
  et le message d'échec le nomme.
- **« Répéter en exercice » n'allume plus l'accueil avant le premier geste** (signalé à l'usage :
  chrono figé à 0:00 et « Session en cours » dès l'entrée en exercice) : `startExercise`
  n'inscrit plus le runtime dans `liveSessions` — `ensureStarted` le fait au premier geste, comme
  pour une session réelle ; le prédicat `sessionLive()` (présence ET `started`) remplace les deux
  tests de présence de la rangée et de la tuile.
- Vérification : 26 contrôles `audit-pdfsearch` (nouveau harnais, PDF fabriqué xref calculé, vert
  sur les DEUX moteurs — dont « pdf.js n'est pas chargé par la frappe », mesuré sur page
  rechargée), 25 témoins unitaires de l'index (bitmap, front-codage, résilience), sonde dédiée du
  correctif exercice ; passes complètes 17/17 check · 920 × 2 tests · 20/20 harnais.
