# Journal des modifications

## [4.48.0] — 2026-07-27
### Le partage fonctionne enfin de bout en bout — et le miroir de l'invité était en lecture seule

Cette version rend le partage RÉEL : l'hôte peut l'ouvrir, montrer un code, voir qui a rejoint,
couper quelqu'un, arrêter. Et surtout, les gestes voyagent — ce qui n'était pas le cas.

### Le défaut central, trouvé par contre-expertise dans le code de la version précédente
**Les coches de l'invité ne quittaient jamais son téléphone.** L'émission s'accroche à
`persistLive`, qui sort immédiatement si la session locale n'a pas démarré — or l'invité avait
`started=false` par construction, et **une trentaine de sites de mutation sont eux-mêmes gardés par
`if(Runtime.started)`**. Le miroir était donc en lecture seule, silencieusement. C'est mot pour mot
le pire mode de défaillance nommé au plan de ce chantier : *cocher dans le vide en croyant
contribuer à une réanimation en cours*.

Le correctif inverse la logique. Sa session EST vive — c'est celle de l'hôte, il la suit et il y
contribue — donc `started` vaut vrai chez lui. Ce qui lui est refusé n'est pas la session, c'est
l'**enregistrement**, et ce refus vit désormais là où il a un sens, dans `persistLive` : aucune
écriture dans son stockage, aucune entrée dans son historique. Le contrôle censé couvrir cela
mesurait le MÉCANISME (`started === false`) au lieu de la PROPRIÉTÉ ; il mesure maintenant
l'étanchéité réelle — zéro session archivée, zéro session vive, aucun dossier — **et** que ses
gestes partent bien sur le fil.

Trois défauts de la même famille, tous dans du code écrit la veille : `canWrite()` — le prédicat qui
doit retirer l'écriture à un invité coupé ou périmé — **n'avait aucun appelant**, alors que le
commentaire attenant promettait « un invité périmé ou coupé PERD VISIBLEMENT l'écriture » ; le
compte de participants du quai filtrait sur `revoked_at` quand le serveur envoie `revoked`, si bien
que l'hôte aurait lu « ⇄ 2 » avec un seul participant présent ; et l'acteur d'un repère se perdait à
la peinture, rendant tout compte rendu inattribuable.

### Émission par différence — un seul point d'accroche
Le recensement avait trouvé **soixante verbes de mutation** (41 attributs `data-*` et 19 contrôles à
`id`). Les instrumenter un par un garantissait l'oubli, et surtout l'oubli SILENCIEUX de toute
mutation ajoutée plus tard. On DIFFE donc l'état, en un seul endroit : ce qui est couvert par
l'enregistrement local l'est mécaniquement par le partage. `shareSnap` et `shareDiff` sont PURS,
donc testables sans navigateur, sans réseau et sans horloge — et le test qui compte est
l'**aller-retour** : émettre puis plier redonne l'état de départ (coches, compteurs, minuteurs,
navigation, repères, annulations, trace do-verify). L'ouverture d'un partage **verse l'état courant
dans le fil** : l'instantané transmis est la FICHE, jamais la session, donc un partage ouvert après
vingt coches aurait sinon laissé l'invité devant une fiche vierge, à jour et fausse.

### La fenêtre d'appariement de l'hôte
Ordre imposé par la mesure, pas par l'esthétique : titre de l'aide et **code** en haut (ce qui se
dicte à voix haute), QR ensuite et plafonné, participants, arrêt en pied. Elle **ne verrouille pas
le fond** (`sheet-live`) : toute `.ai-modal` fige le défilement derrière elle au pointeur grossier,
et celle-ci reste ouverte pendant toute la fenêtre d'admission — la checklist de crise de l'hôte
serait devenue indéfilable au moment où elle sert.

**Couper quelqu'un n'est jamais peint de façon optimiste** : la rangée affiche « coupure… » et
n'accepte « coupé » que lorsque le sondage le rapporte ; le harnais mesure les deux moments, y
compris le RETOUR EN ARRIÈRE quand la requête échoue — un bouton qui laisserait « coupé » affiché
après un échec dirait à l'hôte qu'il a retiré un accès qu'il n'a pas retiré. Et « Arrêter le
partage » ramène `expires_at` à maintenant : le code s'aligne sur la promesse de purge faite à
l'invité, au lieu qu'on affaiblisse la promesse.

### Quatre défauts signalés à l'usage, et ce qu'ils étaient vraiment
**Le QR n'était pas corrompu : il contenait une adresse injoignable.** Il encodait
`location.origin + …` — servi depuis un poste de développement, cela donne une adresse LOCALE, que
l'iPhone décode et ne peut pas ouvrir : « aucune donnée utilisable trouvée ». Désormais, si
l'adresse n'est pas joignable depuis un autre appareil (fichier local, origine nulle, `localhost`),
c'est le **code seul** qui est encodé — le téléphone l'affiche comme texte — et la fenêtre le dit.
Le harnais QR, lui, ne décodait que la MATRICE : il était **aveugle à tout ce qui se passe entre
l'encodeur et l'appareil photo** (génération du SVG, variables CSS, `shape-rendering`, taille en
`vw`, rendu sous-pixel). Il capture maintenant l'IMAGE RÉELLEMENT PEINTE et la donne au décodeur
d'Apple, à quatre configurations dont le thème sombre.

**La confirmation d'arrêt s'affichait DERRIÈRE la fenêtre** : `#confirmModal` héritait du z-index 55
des fenêtres ordinaires alors que l'appariement est à 94 — dialogue invisible, focus piégé dedans.
Porté à 95, au-dessus des deux fenêtres hautes et sous le flash d'alarme.

**L'écran d'entrée ne suivait pas la grammaire de l'app** : il n'utilisait pas `.ai-card`, donc ni
son `margin:auto` (le centrage vertical de toutes les fenêtres), ni son échelle typographique — à
760 px la carte restait collée en haut, au-dessus de 450 px de vide. Et en la recalant, le **6ᵉ
piège de cascade du projet** : `.join-card` et `.ai-card` ont la même spécificité, la
`max-width:720px` déclarée plus bas l'emportait et la carte s'étalait sur 700 px. Sélecteurs par
`#id` pour les deux fenêtres, comme la règle l'impose pour toute géométrie.

**L'écran de saisie du code était introuvable sans QR.** Il est joignable depuis le dialogue
« Créer », sous un filet et formulé comme une question (« Un collègue partage sa session ? — ⇄
Entrer un code ») : c'est le seul point d'entrée atteignable à TOUTES les largeurs, l'accueil n'ayant
ni menu ⋯ ni barre latérale sous 780 px. Et l'**adresse de jointure est écrite en clair sous le QR**
— c'est elle qu'on dicte quand le scan ne peut pas servir.

Le code passe à **40 px** (34 sous 360 px), le champ de saisie de l'invité à 26 px. Cela a fait
tomber un contrôle, et c'est lui qui avait tort : il exigeait « Arrêter le partage » visible sans
défiler à toutes les largeurs, alors qu'à 320×568 la carte fait 734 px — aucune mise en page
honnête ne tient dans 568. L'objection d'origine disait autre chose : ce bouton ne doit jamais se
retrouver DANS une liste qui grandit, et doit rester atteignable. C'est ce qui est mesuré.

### Le miroir de l'invité
Le bouton « Confirmé — démarrer la session » — contrôle plein, le plus visible de l'écran — était
rendu chez lui alors qu'il ne démarre rien : retiré. L'entrée se fait au BOUT du journal et non en
tête de fiche (mesuré : la première étape cochable tombait à y=827 pour un écran de 844, et y=910
pour 568 — hors champ aux deux largeurs) ; le titre reste lisible par le relais d'en-tête, comme
pour tout utilisateur qui défile. Une annonce sans pixel (`#srLive`, seul canal admis pendant un
soin) dit ce qu'il suit.

**Et il a enfin une porte de sortie.** `Share.stop()` n'avait AUCUN appelant : le seul geste
disponible changeait la vue en laissant le mode et le sondage armés, sans chemin de retour. Le menu
⋯ de l'invité porte « Quitter le partage… », et le départ est SILENCIEUX côté serveur —
`Share.stop()`, jamais `emit('detach')` : un `detach` DATE un « je poursuis seul » dans le compte
rendu de l'hôte, or quelqu'un qui ferme son écran n'a rien affirmé de tel. Le même menu perd les
rangées qui, chez lui, étaient fausses ou muettes (exercice, recommencer, modifier, versions,
dupliquer, exports).

**Une incohérence d'étanchéité fermée au passage** : `beforeprint` n'était gardé que par la vue. Un
invité qui faisait Partager → Imprimer obtenait la fiche ENTIÈRE, mise en page pour le papier —
pendant qu'on lui refusait l'export du compte rendu au nom de cette même étanchéité.

### La rangée « Partager la session » n'est plus jamais grisée
La contrainte reste réelle (sans session démarrée, la première action de l'invité déclencherait un
re-rendu complet sous le doigt de l'hôte), mais la faire porter par une rangée MORTE obligeait à
deviner l'ordre des gestes. Elle propose maintenant de démarrer, par un dialogue qui dit ce que cela
engage — chrono, minuteurs, journal, entrée à l'historique : une session ne commence pas par
surprise au détour d'un menu.

### Vérification
691 tests × 2 moteurs (+2), 13 harnais verts, **124/124 contrôles partage** (+69, sur les deux
moteurs), **9/9 QR** (dont 4 sur l'image peinte), 301 contrôles d'accessibilité, 94/94 doctrine,
`npm run check` vert. Les nouveaux contrôles ont chacun été vérifiés capables d'échouer.
`supabase/schema.sql` est INCHANGÉ dans cette version : rien à rejouer.

## [4.47.0] — 2026-07-27
### Le transport du partage, la moitié invité — et ce qu'une contre-expertise a trouvé dans le code existant

Suite du chantier ouvert en v4.46.0. Un collègue peut désormais **rejoindre** une session et la
suivre en miroir ; l'autre moitié — l'écran depuis lequel on ouvre le partage — reste à écrire, si
bien que **rien n'est encore actionnable de bout en bout**. Ce qui l'est, en revanche, ce sont les
défauts que la préparation a mis au jour dans du code qui existait déjà, et qui n'attendaient pas
le partage pour nuire.

### Trois mécanismes existants que le partage rendait dangereux
Deux relectures adverses ont mesuré les surfaces prévues dans le code réel, avant qu'aucune ne soit
écrite. Elles ont invalidé l'ordre de travail : trois corrections devaient précéder toute nouvelle
interface, faute de quoi elle se serait appuyée sur un budget de place faux et sur un indicateur
qui ment.

**Le quai sacrifiait l'ALARME pour garder un chevron.** Quand la place manquait, la boucle
d'ajustement retirait les segments un à un et n'essayait « sans chevron » qu'une fois arrivée à
ZÉRO segment : elle sacrifiait donc le segment ambre du minuteur **échu** — la seule persistance de
l'alarme une fois le bip passé, dans une zone qui ne quitte jamais l'écran — pour garder un glyphe
`aria-hidden` que son propre commentaire qualifiait de « purement décoratif ». Et à court de
solutions, elle **réécrivait un état qu'elle venait de mesurer comme débordant**. Ordre inversé (le
décoratif tombe d'abord, à chaque palier) et plancher explicite.

**La cause de la pénurie était ailleurs : l'ellipse des intitulés n'avait jamais fonctionné.**
`.seg-l` déclare `text-overflow:ellipsis` depuis l'origine et un commentaire l'attribuait à un
« min-width:0 du segment » — qui n'existait pas. Sans plancher explicite, `min-width:auto`
dimensionne le segment sur son contenu le plus large ; en colonne, la règle flex qui annule le
minimum automatique porte sur la HAUTEUR, jamais sur cette largeur. Mesuré : un intitulé de
21 caractères portait le segment à **346 px pour 320 de large**, la boucle voyait un débordement et
expulsait le segment. Plancher chiffré à **112 px** = la valeur réelle la plus large
(« 999:59:59 », 95 px) plus les rembourrages : en dessous, l'intitulé s'ellipse — un MOT se
tronque, c'est admis ; au-dessus, la valeur ne peut jamais être rognée — un NOMBRE ne se tronque
pas — et si la place manque vraiment, le débordement est RÉEL, donc la boucle retire un segment et
le « +n » l'annonce. Le quai ne peut plus déborder en silence à aucune largeur servie.

**Le mot « échu » n'existait pas dans le quai**, alors qu'`AGENTS.md` l'affirmait : `segOf`
n'écrivait que l'intitulé et la valeur, si bien qu'un minuteur échu se distinguait d'un minuteur
nominal par la SEULE teinte — dans la zone la plus critique de l'application. Il ne pouvait pas
être ajouté en clair (l'ellipse l'aurait mangé le premier, et le segment aurait grossi jusqu'à se
faire expulser) : patron déjà retenu pour les étapes signalées — **glyphe `△` en PRÉFIXE**, qui
survit à l'ellipse, plus l'étiquette au lecteur d'écran. Piège trouvé au passage : cette étiquette,
en `position:absolute` sans ancêtre positionné, **échappait au `overflow:hidden`** et se posait à
488 px sur un quai de 320 — elle gonflait `scrollWidth`, c'est-à-dire qu'elle MENTAIT à la boucle
qu'on venait de corriger.

**Le seuil de péremption était INFÉRIEUR à la cadence nominale.** 4 s en constante, alors que la
période de sondage passe à 5 s après 30 s sans action et à 10 s après deux minutes : avec un réseau
PARFAIT, l'écran de l'invité se serait déclaré « figé » environ une seconde sur cinq au repos et
**six secondes sur dix pendant un cycle de compressions de deux minutes** — c'est-à-dire dans le
cas d'usage phare. Un indicateur qui crie au loup les deux tiers du temps n'est plus lu quand la
panne est réelle. Le seuil est désormais solidaire de la cadence courante et signifie « deux cycles
manqués » (facteur 2,5 : la gigue étant de ±20 %, deux périodes consécutives atteignent 2,4 fois la
base). Un statut terminal cesse en outre de sonder — le sondage tournait indéfiniment contre un
partage mort.

**La fin du partage n'est pas la fin du soin.** Le critère « une crise est à l'écran » s'écrivait,
pour un invité, `status === 'active'` : à l'instant EXACT où l'hôte coupait, deux mécanismes se
rallumaient sur la checklist que le collègue tient encore en main — le déversement des snackbars
retenues pendant tout le soin (jusqu'à huit) et la ré-apparition de la méta de lecture, qui décale
le contenu sous son doigt. Le critère juste est la PRÉSENCE d'une fiche de crise, d'où deux sorties
distinctes : `freeze` (le lien meurt, l'écran survit) et `stop` (l'écran est quitté).

### Le quai de l'invité existe, et il dit qui tient la main
Il n'apparaissait que si une session avait démarré **localement** — or un invité qui suit n'a rien
démarré, c'est le principe même du miroir. Les deux informations que la doctrine veut permanentes
(AC 120-71B §6.4 : qui tient la checklist ne souffre aucune ambiguïté ; et si ce qu'on voit est
encore vrai) n'avaient donc **aucun conteneur**. Un prédicat unique — celui-là même qui gouverne
déjà la mise en attente des banderoles — et un jeu **fermé** de jetons dans le libellé du chrono :
`main` / `suit`, `⇄n`, `figé`, `coupé`, `fini`, `seul`.

Trois emplacements ont été mesurés et écartés. Un **segment `⇄` propre** déplace le segment
d'alarme de 45 à 57 px selon la largeur, à son apparition ET à sa disparition — donc sur ÉVÈNEMENT
DISTANT, ce que la constance positionnelle ECAM interdit ; la **rangée de commandes** n'a que 2,1 px
de marge à 320 px ; une 2ᵉ pilule sur le **bandeau** fait tomber le titre de fiche de 172 à 58 px.
Le libellé du chrono, lui, coûte zéro pixel de mise en page : le segment est déjà étiré par le flex.
**Le lien REMPLACE la main**, il ne s'y ajoute pas — ce n'est pas une économie de place : quand le
lien n'est plus nominal, le rôle et le compte de participants ne sont PLUS CONNUS, et les afficher
serait la donnée périmée présentée comme vivante. Le vert cesse alors d'affirmer (encre neutre,
jamais l'ambre, réservé au minuteur échu).

### L'invité ne paie plus rien avant d'avoir lu
Mesuré sur profil vierge : charger `index.html#j=CODE` déposait **3,17 Mo** (le cache applicatif et
les 1 773 Ko de pdf.js), créait une base IndexedDB, écrivait quatre clés `localStorage`,
enregistrait un service worker — et appelait `navigator.storage.persist()`, c'est-à-dire demandait
au navigateur de rendre ce dépôt **non évinçable** — le tout AVANT que le premier mot de la notice
d'information ait pu s'afficher. Une information préalable posée sur une collecte déjà faite
n'informe rien.

Le mode invité devient donc une **décision de démarrage**, pas une classe CSS. Trois cas : pas de
code → démarrage normal ; code sur appareil VIERGE → stockage en mémoire, aucun worker, aucune
persistance demandée, aucun ensemencement, et l'écran d'entrée **à la place** de l'application ;
code sur un appareil qui utilise déjà l'app → démarrage normal (lui refuser son worker ne
protégerait rien et casserait son hors-ligne), écran par-dessus — **sauf si une fiche de crise est
à l'écran**, auquel cas le code est GARÉ et annoncé par le bandeau système, qui est déjà le canal
« information persistante, accueil seulement » (règle 11). Le fragment est retiré de l'historique
immédiatement. `ensureStarted` refuse de démarrer chez un invité : c'est le point exact où
l'étanchéité se joue — sans cette garde, sa première coche créerait un enregistrement de session
sur un téléphone emprunté. `launchQueue` est enfin consommé (le manifeste le déclarait depuis
v4.43.0 ; un lien entrant sur PWA installée était silencieusement perdu).

### Un écran d'entrée, et un refus qui ne prescrit pas l'impossible
L'écran porte l'information de l'article 13 — qui est responsable, ce qui est enregistré, pourquoi,
où, combien de temps, qui d'autre le voit — et il est audité en accessibilité dans les deux thèmes
à 320 px, la largeur la plus contrainte servie.

Le message de refus a été réécrit après mesure, et les trois formulations précédentes étaient
fautives. **« Vérifiez les 8 caractères » était du texte mort** : le contrôle local a déjà exigé
exactement huit caractères pris dans l'alphabet, deux lignes plus haut. **« Demandez de rouvrir
l'accès » est faux ou nuisible dans cinq causes de refus sur sept, dont deux boucles infinies** —
`share_admit` ne vérifie NI l'expiration NI le quota : il rend un code neuf que `share_join`
refusera encore, sans que personne ne comprenne pourquoi ; et sur une simple faute de frappe, il
TUE un code peut-être encore vivant. On nomme donc le RÉSULTAT (« un nouveau code »), jamais le
geste : l'hôte seul voit sa porte, et c'est lui qui décide. **Chiffrer la fenêtre et le nombre de
participants aurait été FAUX** — et l'argument n'est pas l'oracle, une chaîne statique ne portant
aucun état : `max_guests` est une COLONNE PAR PARTAGE (1-8, défaut 3) et la fenêtre vaut 120 s à
l'ouverture mais 15 à 600 s à chaque réadmission ; le client ne reçoit ni l'une ni l'autre. D'où
une règle de tri, écrite au-dessus des constantes : un chiffre n'entre dans un message que s'il est
détenu par le client, identique pour tout partage du déploiement, et capable de changer ce que le
lecteur fait ensuite. « 8 caractères » passe les trois ; « 2 minutes » et « 3 » échouent aux trois.

Trois rédactions, choisies sur la **provenance locale** du code — jamais sur la réponse du serveur,
identique dans les trois cas : code recopié à la main, code venu d'un QR (qu'on ne peut pas mal
recopier), et deuxième soumission du même code, qui coupe la boucle du re-tap puisque le champ
conserve sa valeur après échec. Le harnais vérifie que le serveur bouchonné rend la même chose et
que trois textes différents en sortent : un message qui varierait avec la réponse du serveur serait
un oracle.

Enfin, la géométrie : la rédaction précédente faisait **7 lignes et 145 px**, et à 320×568 le
bouton « Rejoindre » n'était plus visible que sur **23 px de ses 48** — sous le plancher de la
règle 9, et 0 px sur un écran de 480. Le défaut n'apparaissait qu'à la largeur la plus contrainte,
et aucun harnais ne regardait cet écran. Il en existe un désormais, et il échoue sur l'ancienne
rédaction.

### Deux questions tranchées, mesures à l'appui
**Le titre de l'aide sur l'écran d'entrée** : quatre chemins instruits, deux refusés. Une fonction
`share_peek(code)` serait un ORACLE par construction — elle sépare « titre » et « refusé » sans
consommer le code ni prendre de place, là où `share_join` fait les deux, et il n'existe aucune
limitation de débit sur la jointure. Le titre dans le QR rendrait **une photo de l'écran prise de
loin porteuse d'un diagnostic permanent**, là où elle ne porte aujourd'hui qu'un secret de 40 bits
mort en dix minutes au plus. Le titre est de toute façon **déjà peint dans la première image du
miroir** (`#crisisBand`, mesuré visible sans défiler à 320×568 comme à 390×844) : un écran de
confirmation intermédiaire coûterait un tap pour zéro information, et il est inécrivable tel quel —
au retour de `share_join` la liste des participants est vide et l'hôte s'appelle littéralement
« Hôte ». Il ira donc à côté du code sur l'écran de l'hôte.

**Un utilisateur sans compte peut-il OUVRIR un partage ?** Non, et l'arbitrage a été refait sur ses
vrais mérites — deux des trois arguments spontanés ne tiennent pas. « La surface d'abus l'interdit »
est faux comme argument discriminant : `require_approval` valant `false` par défaut, un compte coûte
une adresse jetable et un OTP, et `share_open` n'a de toute façon **aucun plafond par
propriétaire** — les 500 Mo en 40 secondes sont atteignables aujourd'hui, avec un compte.
« Aucun plafond ne peut exister sans `auth.uid()` » est faux aussi : c'est vrai d'un plafond PAR
APPELANT, hors sujet pour un plafond GLOBAL. Ce qui tient : `owner` est la SEULE colonne reliant un
contenu diffusé à une personne (la retirer ferait de l'exploitant l'hébergeur d'un contenu sans
auteur, sans retrait ciblé, et supprimerait la seule prise du droit à l'effacement) ; l'approbation
des comptes deviendrait décorative, le contournement s'appelant « Déconnexion » ; et **un hôte
anonyme serait un hôte infirme** — la qualité d'hôte n'a aucun porteur autre que le JWT, donc ni
réadmission, ni coupure, ni fin de partage : si la mauvaise personne entre, le partage reste vivant
jusqu'à expiration. Si la décision devait s'inverser un jour, le seul chemin défendable est un
compte ANONYME Supabase (vrai identifiant, journal, révocation, cascade d'effacement), jamais un
`owner` nullable, et derrière un interrupteur d'instance par défaut fermé.

### Journal des actions, et fin de session
Incrémenter un compteur **pose désormais un repère horodaté** dans le journal des actions —
« choc n° 3 à 14:32 » est exactement ce qu'on oublie de noter sous stress, et l'heure est ce qui
compte cliniquement. Le repère porte une RÉFÉRENCE, jamais un mot : son libellé se dérive de la
fiche à l'affichage, il traverse donc le partage sans texte libre et suit le compteur si on le
renomme. Le rail ne remonte pas (mise à jour chirurgicale).

Le `×` du journal **annule au lieu de supprimer** : ligne barrée, estompée, conservée, et le `×`
devient `↺` pour se raviser. Deux règles du projet le condamnaient déjà — « action destructrice en
situation de crise = geste maintenir, pas un simple tap », et le précédent `origT`, où la correction
d'heure est non destructive, visible et réversible. Le « maintenir » a été envisagé et écarté : il
protège du geste accidentel mais laisse la perte définitive, et ne dit rien à celui qui relit — or
le journal alimente le compte-rendu. **L'heure reste en encre pleine** (c'est la donnée clinique).
C'est aussi ce qui rend le geste admissible pour un scribe en session partagée : attribué, daté,
réversible — là où un décochage, qui détruit vraiment une information, lui reste fermé.

### Vérification
663 tests × 2 moteurs, 13 harnais verts, **94/94 contrôles doctrine** (+54), **301 contrôles
d'accessibilité** (+12, dont l'écran d'entrée dans les deux thèmes), 55/55 contrôles partage. Les
nouveaux contrôles ont chacun été **vérifiés capables d'échouer**, fichier restauré à l'octet
ensuite. `supabase/schema.sql` et `rls-tests.sql` ont été rejoués sur l'instance (le genre
d'évènement `mark_void` s'ajoute aux capacités du scribe).

**Incident de manipulation, consigné parce qu'il doit servir.** Un `git checkout -- index.html`,
lancé pour annuler une modification temporaire de démonstration, a effacé tout le travail non
committé du fichier — cette commande ne défait pas la dernière modification, elle restaure depuis
le dernier commit. Le fichier a été reconstruit depuis le transcript de session (79 éditions
rejouées dans l'ordre, deux ancrages réparés, deux modifications faites hors outil d'édition
retrouvées et re-appliquées), puis vérifié : audit systématique des 79 éditions (zéro manquante),
cohérence de la réparation manuelle sur ses 5 sites, absence de duplication, et surtout la suite
complète au vert — les tests et les treize harnais, eux, n'avaient pas été touchés, et c'est ce qui
a servi de juge. **Règle : pour annuler une modification expérimentale, restaurer depuis une
sauvegarde vérifiée par empreinte, jamais depuis git tant que le travail n'est pas committé.**

## [4.46.0] — 2026-07-27
### Partage de session en direct — le socle serveur, et six défauts trouvés en chemin

Premier jalon d'un chantier qui fera sortir une **session** de l'appareil : un collègue présent
dans la pièce pourra suivre et remplir une session de crise depuis SON téléphone, avec ou sans
compte, **pour cette session uniquement**. Rien n'est encore visible à l'écran. Cette version pose
le serveur, l'encodeur du code d'appariement et le noyau pur du transport — chacun vérifié
séparément, aucun ne dépendant du suivant.

### Ce que la doctrine dit vraiment, et une citation du projet qui était fausse
Les textes primaires ont été lus, pas leurs résumés — et deux résultats vont contre l'intuition.
**« Do-Verify » et « Challenge-Do-Verify » n'existent NULLE PART dans l'AC 120-71B** (recherche
exhaustive sur le document intégral : 6 chapitres + Appendix A, zéro occurrence ; la révision B
indique elle-même avoir retiré les exemples des appendices). Ces intitulés viennent de
l'**AC 120-71A (2003), que la révision B ANNULE**, où ils ne sont que des titres d'une liste de
sujets, sans définition. Les définitions rédigées qui circulent en ligne ne proviennent d'aucun
document FAA retrouvable. La pratique implémentée ne change pas d'un pixel — seule la référence
était fausse : la source correcte est le **FAA Order 8900.1, Vol. 3, Ch. 32, §3-3403.A**, et pour
la répartition à deux, l'AC 120-71B **§5.2.2.1** (« one crewmember reading the checklist and the
second crewmember confirming and responding »). Corrigé dans `AGENTS.md`, avec l'avertissement de
ne pas ré-inverser. De même, « la réponse porte l'état CONSTATÉ, jamais un *fait* » est de
**Degani & Wiener** (ligne directrice n°1, 1993), pas de la circulaire.

Deuxième résultat, structurant : **la co-édition symétrique n'est décrite nulle part**. Airbus
garantit l'exclusion mutuelle par le MATÉRIEL (un seul ECAM Control Panel) ; là où deux pointeurs
coexistent, l'industrie a écrit un verrou mono-écrivain à propriété visible, jamais une fusion. La
« vue dégradée » de l'invité n'est donc pas un compromis : c'est la forme canonique.

### Socle de sûreté — six défauts du code ACTUEL, sans rapport avec la nouveauté
- **`keepAnchor` confondait « 0 px » et « pas mesuré ».** Les trois sorties sans mesure renvoyaient
  `0`, c'est-à-dire la valeur qui signifie « ancrage parfait ». La plus grave : l'ancre a DISPARU
  pendant le re-rendu (une condensation du journal transforme la carte visée en chip). Démontré en
  réintroduisant le défaut — le cas guidé affiche **dérive 0 px ET résidu null** : l'ancien contrôle
  d'`audit-doctrine` passait au vert **sans avoir rien mesuré**, exactement sur le cas qu'il prétend
  couvrir. Troisième occurrence de la leçon v4.31.1. `keepAnchor` renvoie désormais `null`, que le
  harnais refuse (40/40).
- **La « prohibition ACTIVE » du rôle `anon` ne portait pas sur `PUBLIC`.** `revoke … from anon` ne
  retire que les privilèges accordés NOMMÉMENT à anon ; or PostgreSQL accorde `EXECUTE` à **PUBLIC**
  par défaut sur toute fonction (asymétrie avec les tables, qui n'en reçoivent aucun — d'où un
  revoke efficace côté tables et INOPÉRANT côté fonctions), et tout rôle hérite de PUBLIC. **Les
  20 fonctions du schéma étaient appelables sans compte.** Aucune escalade — chacune se protège par
  `auth.uid()` — mais la garantie annoncée n'existait pas.
- **`is_approved()` renvoyait `true` pour `anon`** : `auth.uid()` étant NULL, le `coalesce` retombait
  sur `'approved'`. Sans conséquence aujourd'hui (les politiques exigent en plus `owner = auth.uid()`),
  mais tout garde-fou futur écrit avec elle aurait été inopérant **en ayant l'air solide**. Règle
  écrite : un gate anon s'écrit `auth.uid() is not null`, jamais `is_approved()`.
- **Le balayage anon de `rls-tests.sql` (§13.5) était aveugle à ce qu'il prétend couvrir** : sept
  tables NOMMÉES EN DUR, zéro fonction. Remplacé par des assertions de **CATALOGUE** — aucun grant
  de table à anon, liste blanche EXACTE des fonctions exécutables par anon, et balayage dynamique de
  toutes les tables. Piège évité en l'écrivant : sous `anon`, `information_schema` ne montre rien,
  la boucle aurait tourné à vide et le test serait passé au vert sans rien balayer.
- **Aucun appel réseau n'avait de délai de garde.** Sur iOS, un `fetch` sans route ne rejette qu'au
  bout de 60 à 75 s : `Sync.running` reste vrai tout ce temps, le repli exponentiel ne peut pas
  s'armer (il ne démarre qu'APRÈS la première erreur), et `Auth.refresh()` — attendu avant CHAQUE
  appel REST — bloque tout ce qui suit. Les cinq `fetch` passent par `acFetch` (25 s, 120 s pour un
  binaire PDF : un téléversement légitime sur réseau lent ne doit pas être cassé par le correctif).

### Serveur — la première surface non authentifiée du projet
Trois tables (`shared_sessions`, `session_participants`, `session_events`) et six fonctions. La
surface `anon` est de **trois portes nommées, et rien d'autre**, ouvertes après la révocation
générale — placées avant, elles seraient effacées en silence quelques lignes plus bas.

Quatre décisions, chacune réparant une faille identifiée AVANT écriture : **aucune identité n'est
jamais un paramètre** (l'acteur se DÉDUIT du secret présenté ; le passer rendrait l'attribution
forgeable par tout porteur du code — or l'attribution EST le contrôle demandé) ; **le secret est
tiré par le serveur** (`gen_random_bytes`), jamais par le client, dont le seul générateur maison
rend ~41 bits et retombe sur `Math.random` ; **fenêtre d'admission** armée par l'hôte, code
**consommé** à la première jointure, ce qui rend la coupure d'un invité EFFECTIVE au lieu de
décorative ; **append-only strict** — un invité n'écrit que des lignes, l'état est un pli calculé
côté client, sinon le verrou de ligne d'un état matérialisé ferait attendre l'hôte derrière la file
d'un invité. La séquence est allouée **sous verrou, par partage** : un `bigserial` alloue à l'INSERT
et non au COMMIT, un évènement validé en retard resterait définitivement sous le curseur du lecteur.
Chaque évènement porte **deux horloges** — l'instant du geste et celui de l'arrivée — sans quoi une
action relevée hors réseau se rangerait au compte-rendu à l'heure du retour du réseau.

**Relais, pas entrepôt** : purge bornée en tête de CHAQUE appel (sur un hébergement statique,
une purge planifiée n'a personne pour la lancer). `delete_my_account` supprime les partages
**explicitement** — sans cela, soit ils survivent, soit la violation de clé étrangère annule toute
la fonction et le droit à l'effacement disparaît pour quiconque a partagé une fois.

**`supabase/schema.sql` est à REJOUER**, puis `rls-tests.sql` — dont le nouveau **§14 porte
31 assertions** : jointure d'un invité sans compte, code consommé, capacités du scribe, acteur non
falsifiable, coupure MOTIVÉE (« revoked », jamais un silence qu'on prendrait pour une panne),
détachement, purge, effacement RGPD.

### Deux garde-fous nés des erreurs de cette version
`check-sql.mjs` gagne deux contrôles, chacun **vérifié capable d'échouer** puis fichier restauré à
l'octet. (1) Tout `grant … to anon` doit citer une fonction de la liste blanche, et
`grant … on all …` est refusé quel que soit le rôle : le scénario visé n'est pas la malveillance
mais le dépannage — PostgREST accompagne un refus 42501 d'un `hint` qui nomme le grant manquant, et
la réponse la plus répandue en ligne est la forme globale. (2) Une fonction `language sql` ne peut
référencer aucun objet déclaré plus bas dans le fichier : elle est intégralement résolue À SA
CRÉATION (`42P01` au collage), là où une `language plpgsql` n'analyse son corps qu'à la première
exécution. Cette asymétrie ne se voit pas à la relecture et avait déjà coûté deux re-créations de
`get_instance_stats` ; elle en a coûté une troisième ici, découverte sur l'instance.

### Encodeur QR — sans dépendance, et relu par le décodeur d'Apple
Le code d'appariement s'affiche en QR sur l'écran de l'hôte : un QR affiché ne peut être scanné que
par quelqu'un qui est **là**, et il ne transite par aucun message, aucun journal d'accès, aucun
historique. L'app n'embarque **aucun décodeur** — iOS et Android décodent nativement depuis
l'appareil photo — et c'est cette asymétrie qui rend la fonctionnalité abordable (règle 13 intacte,
aucun fichier servi de plus). Mode octet, correction M, versions 1 à 10.

Choix de conception central : **une seule table de 20 nombres**, tout le reste se dérive — total de
mots-code par la géométrie, découpage en blocs par la division euclidienne, alignements par formule.
Une table recopiée est une erreur qui dort ; une dérivation se vérifie, et le test recoupe les deux
chemins. **La vérification a payé immédiatement** : le calcul des syndromes Reed-Solomon — qui
ÉVALUE le polynôme là où l'encodeur le DIVISE, donc n'emprunte rien à ce qu'il vérifie — a fait
tomber un polynôme générateur construit **à l'envers** (terme dominant non unitaire). Motifs au bon
endroit, format valide, structure impeccable : aucun contrôle de cohérence interne ne l'aurait vu,
et les codes produits auraient été parfaitement illisibles. Nouveau harnais `scripts/audit-qr.mjs` :
les codes sont relus par **CoreImage**, le décodeur d'Apple, celui de l'appareil photo de l'iPhone —
5 cas, v1 à v6, UTF-8 accentué compris, sur les deux moteurs. macOS seulement : ailleurs il AVERTIT
sans échouer, en disant explicitement que la vérification n'a pas eu lieu. Piège de thème évité :
`--ink` est CLAIR en sombre, un QR peint avec lui serait blanc sur blanc — d'où `--qr-ink`, fixe
dans les deux thèmes, sur le patron de `--paper`.

### Noyau pur du transport
Sept fonctions sans effet de bord. **La projection de fiche** (`sharePayload`) n'est pas la fiche :
deux listes explicites couvrent les **27 champs du modèle migré**, et un test échoue si l'une prend
du retard — ajouter demain un champ sans décider s'il se partage devient impossible (garde-fou
vérifié capable d'échouer). Ne partent pas : le gabarit local (téléphones de renfort et de
régulation, pré-remplis par `blankFiche`), les images (jusqu'à 24 Mo), les documents que l'invité ne
pourrait pas ouvrir, `ownerId`/`libraryId`. `shareFold` exclut l'annexe d'un détaché de l'état —
c'est un rapport, pas une commande. `shareStateHash` détecte la **divergence silencieuse**, celle
qu'un indicateur de péremption ne verra jamais parce que les mises à jour arrivent à l'heure et sont
fausses. `shareOffset` (Cristian) rejette toute mesure dont l'aller-retour dépasse le seuil : un
décalage faux daterait les gestes du compte-rendu et ferait sonner deux minuteurs à des instants
différents dans la même pièce. L'en-tête HTTP `Date` n'étant PAS lisible en fetch cross-origin,
l'heure serveur voyage dans le corps.

**560 tests × 2 moteurs, 12 harnais verts, 289 contrôles a11y, 40/40 doctrine.**

## [4.45.0] — 2026-07-27
### Factorisations — et ce qu'elles ont révélé
Trois duplications du reliquat d'audit, sans effet visible à l'écran. La troisième a fait tomber un
angle mort qu'aucune relecture n'aurait trouvé.

### L'ancrage ECAM : de 4 copies à 1, et enfin mesurable
Le motif « mesurer la position écran d'une ancre, re-rendre, compenser le défilement » existait en
quatre exemplaires — `renderKeepAnchor`, `renderOvOnlyKeepAnchor`, `ovAdvanceRender`, et le
remplacement chirurgical de `renderNavOnly`. C'est **l'invariant le plus cité du projet** (« rien
ne bouge sous le doigt ») et **une seule des quatre mesurait son résidu** : les trois autres
appliquaient le motif sans jamais pouvoir dire si elles y arrivaient. Source unique `keepAnchor`.

Ce qui **n'a pas** été unifié, et pourquoi : le focus clavier (seul le journal le déplace) et la
règle de visibilité (seul `ovAdvanceRender` défile vers la nouvelle carte, et seulement si elle
n'est pas déjà entièrement à l'écran). Le résidu reste **renvoyé, jamais corrigé** — la
compensation est bornée par le haut de page, et c'est cette limite qui fonde la doctrine de
`state.confOpen` ; la masquer rouvrirait le bug v4.3.2.

Deux contrôles permanents ajoutés à `audit-doctrine` (38/38) : dérive 0 px à la première action de
session et au remplacement du bloc en mode guidé. Tolérance 1 px, assumée : WebKit rend 1 px là où
Blink rend 0, arithmétique identique — du sous-pixel de compositeur, pas un défaut d'ancrage.

*Note : un `{preventScroll:true}` s'était glissé dans la restauration de focus. Il serait cohérent
avec les deux autres restaurations du fichier et protégerait l'ancrage qu'on vient d'appliquer —
mais c'est un changement de comportement, et un lot de factorisation n'en embarque pas. Retiré, et
signalé ici pour décision séparée.*

### `updateRtStrip` : un calcul écrit deux fois, un prédicat rédigé de deux façons
Le temps restant (qui sert au tri : échus d'abord, puis les plus urgents) était calculé à
l'identique pour le quai et pour la bande du mode lecteur, mais le prédicat « échu » différait —
`dueDone(t)||(interval && val==='00:00')` d'un côté, `interval && val==='00:00'` de l'autre.
L'extraction est **iso-sortie**, et la démonstration mérite d'être écrite : `dueDone` impose déjà
`type==='interval'`, et un minuteur échu et arrêté donne `within >= per`, donc `fmtMs(max(0,
per-within))` vaut « 00:00 » — le premier disjoint est absorbé par le second. Une **fonction**
appliquée deux fois, jamais un tableau partagé : chaque zone garde son tri et sa troncature.

### Les onze harnais n'auditaient pas la cible principale
`scripts/harness.mjs` : serveur statique, table MIME et choix du moteur, partagés. La duplication
avait déjà dérivé — `audit-lecteur.mjs` était le seul dont la table MIME omettait `.ico`.

Mais le vrai constat est ailleurs : **les onze lançaient `chromium.launch()` en dur**. `npm test`
tourne sur deux moteurs depuis v4.34.0 parce qu'iOS Safari est la cible principale et qu'un
comportement WebKit peut couper l'écran sans qu'aucune mesure ne le voie. Les harnais, eux,
n'auditaient que Blink. Le moteur se choisit désormais par `AC_ENGINE` — `chromium` par défaut,
donc rien ne change sans décision, et un nom inconnu échoue bruyamment plutôt que de retomber en
silence sur chromium.

**Le premier passage sur WebKit a immédiatement payé.** La sonde WCAG 2.4.11 signalait **8
masquages sur 11 cibles** — de quoi croire à un défaut d'accessibilité sur iPhone. La géométrie dit
autre chose : tous avaient un bas **négatif** (−352, −237, −138, −94 px), c'est-à-dire des éléments
pas encore revenus à l'écran. Sur WebKit, le défilement induit par un focus **programmatique** est
asynchrone ; la sonde lisait la position d'avant et mesurait la synchronicité du moteur, pas
l'application. Variable isolée (même sélecteur, même scénario, seule l'attente change) : lecture
immédiate → 8, lecture après 60 ms → **0, sur les deux moteurs**.

Ce n'était donc pas un défaut d'accessibilité — mais **on ne pouvait pas le savoir** tant que les
harnais ne tournaient que sur Blink. Règle ajoutée : toute sonde qui lit une géométrie après
`focus()` doit attendre.

**Les onze harnais passent désormais sur WebKit comme sur Chromium.**

513 tests × 2 moteurs, 11 harnais verts **sur les deux moteurs** (38/38 en doctrine),
289 contrôles d'accessibilité.

## [4.44.1] — 2026-07-27
### Correctif : `schema.sql` de v4.44.0 ne s'exécutait pas
Signalé par l'utilisateur au rejeu sur Supabase :
`ERROR: 42601: syntax error at or near "$"`, ligne 270.

Deux fonctions trigger — `clamp_updated_at` et `stamp_updated_by` — avaient perdu un dollar de
leur délimiteur de corps : `as $$` était devenu `as $`. Réparé, et vérifié qu'il n'en restait
aucun autre.

**La cause est une erreur de méthode de ma part, et elle mérite d'être écrite parce qu'elle se
reproduira.** `String.prototype.replace()` interprète `$$` **dans la chaîne de remplacement**
comme un dollar littéral unique — au même titre que `$&`, `` $` ``, `$'` et `$1`. Le script de
patch qui ajoutait `set search_path` aux deux fonctions réinjectait donc du SQL mutilé, en
silence. Remède : passer une **fonction** de remplacement (aucune substitution n'y est faite), ou
`split().join()`.

**Et le contrôle que j'avais fait ne pouvait pas l'attraper.** J'avais compté les `$$` et vérifié
la parité : 50, pair, vert. Or un `$$` amputé en `$` ne matche plus le motif — il disparaît du
compte **des deux côtés**, et la parité reste vraie. C'est un contrôle aveugle au défaut qu'il
prétend couvrir, exactement ce que la leçon v4.31.1 proscrit ; je l'ai redite au prix fort.

### `scripts/check-sql.mjs`, dans `npm run check`
`supabase/schema.sql` et `supabase/rls-tests.sql` n'étaient couverts par **rien** : ni servis, ni
chargés par les tests. Une erreur ne s'y voyait qu'au collage dans l'éditeur SQL de Supabase —
c'est-à-dire chez l'utilisateur, sur une instance de production. Trois contrôles : les **runs de
dollars** (un délimiteur de corps s'écrit `$$`, un dollar isolé est la signature exacte du défaut),
leur parité, et l'absence de `;` dans un en-tête de fonction avant son corps. Vérifié capable
d'échouer en réintroduisant le défaut vécu — il le signale par les **trois** voies — puis fichier
restauré à l'octet.

### Relecture complète du diff SQL
Toutes les modifications de v4.44.0 sur `schema.sql` ont été relues ligne à ligne :
**zéro ligne supprimée qui ne soit un en-tête de fonction**. Aucune logique, aucune politique,
aucun grant n'a été touché — uniquement l'ajout de `pg_temp` et, pour les deux fonctions trigger,
d'un `search_path`.

> **`supabase/schema.sql` est à rejouer**, cette fois avec succès, puis `rls-tests.sql`.

513 tests × 2 moteurs, 11 harnais verts, 289 contrôles d'accessibilité.

## [4.44.0] — 2026-07-27
### Durcissement, sécurité serveur, purge — et le filet qui manquait sur le service worker
Quatre lots techniques du reliquat d'audit, sans effet visible à l'écran.

### Durcissement
**`esc()` échappe désormais l'apostrophe.** La doctrine en fait « la SEULE barrière anti-XSS » : la
laisser suspendue à l'invariant non vérifié « aucun attribut n'est délimité par une apostrophe »
faisait reposer la sûreté de tout le fichier sur une convention que rien n'impose. Innocuité
établie avant écriture : 278 sites d'appel, dont **0 `textContent`, 0 `setAttribute`, 0 comparaison
de chaîne** — la sortie ne va que dans du HTML, où l'entité est re-décodée.

**Le backtick, lui, reste intact — et c'est une décision, pas un oubli.** Il a été échappé, puis
rétabli : trois tests du mini-Markdown tombent aussitôt, parce que `mdInline` échappe d'abord et
reconnaît la syntaxe ensuite — un backtick devenu `&#96;` n'est plus un délimiteur de code. Et ce
n'est pas un métacaractère HTML. L'échapper coûtait une fonctionnalité documentée pour zéro sûreté.
Les deux tests encodent maintenant la règle **et son exception**.

Le risque réel n'était pas la sûreté mais l'affichage : les textes français sont pleins
d'apostrophes. Balayage de **7 surfaces × 2 moteurs** (accueil, session vive, feuilles Consulter et
Se repérer, statique, éditeur, protocole) — **aucune entité littérale**, la sonde prouvant par
contre-épreuve qu'elle sait en voir une.

**`check-colors` : exemption resserrée à la règle, plus à la ligne.** Elle était `^.*\.acc-sw\..*$`
— ligne entière. Or ce CSS écrit plusieurs règles par ligne : trois lignes exemptées, dont **deux
portant six règles chacune**, et une troisième sans le moindre hex. Un hex collé en fin d'une de
ces lignes passait inaperçu ; il est désormais attrapé (démontré, puis fichier restauré à l'octet).

### Sécurité serveur
`pg_temp` ajouté en fin des **20** `search_path` épinglés, et les **2 fonctions trigger** —
`clamp_updated_at`, `stamp_updated_by` — qui n'en avaient aucune en reçoivent une. Nuance honnête :
`pg_temp` n'est jamais consulté pour résoudre une fonction ou un opérateur, seulement pour les
tables, et toutes les relations sont déjà qualifiées `public.…` — on ferme une porte déjà fermée
par ailleurs. On le fait parce que c'est gratuit et que l'absence est ce qu'un auditeur tiers
relève en premier. Vérifié : **0 `search_path` nu, 0 sans `pg_temp`**.

**`FORCE ROW LEVEL SECURITY` n'est PAS activé, et le piège est désormais écrit dans le schéma.**
L'ajouter par réflexe supprimerait **tous les app-admins** : `app_admins` et `app_settings` n'ont
volontairement ni politique ni grant, et ne sont lues que par `is_app_admin()`/`is_approved()`, qui
sont `security definer` précisément pour traverser cette invisibilité. Sous `force`, le
propriétaire redevient soumis aux politiques — il n'y en a aucune — donc plus aucune création de
bibliothèque ni validation de compte sur toute l'instance.

> ⚠ **`supabase/schema.sql` est à rejouer** sur l'instance Supabase, puis `rls-tests.sql`.

### Purge (règle 14) — zéro pixel changé
- **`state.showSess`** : déclaré, remis à false deux fois, **jamais lu**.
- **`_rtShowDirty`** : quatre écritures, **zéro lecture** — deux écouteurs globaux (`scroll`,
  `resize`) entretenaient une valeur que personne ne consultait, et le commentaire décrivait une
  optimisation qui n'existait plus.
- **Modificateur `compact`** : émis deux fois, **aucune règle CSS** dans tout le fichier.
- **Délégation du plan dans `bindOverviewEvents`** : trois branches inatteignables. Ce gestionnaire
  écoute `.ov-wrap`, le journal ; le plan l'a quitté en v4.23.0. Mesuré avant retrait dans
  **21 configurations** (3 largeurs × 7 états) : `.ov-wrap [data-pl*]` = **0 partout**, pendant que
  le rail en portait 9 dès 800 px et la feuille 9 une fois ouverte.
- **Trois règles CSS strictement dupliquées** (`.dock-plan:hover`, `.catchip{position:relative}`,
  `#crtIA .crt-ic`). Un **quatrième** doublon strict existe — `body.view-read .read-grid` @1200 —
  et il est **délibéré**, réaffirmé exprès après le bloc 1000 pour gagner par l'ordre de cascade.
  Il apparaît dans la même liste que les autres : ne jamais passer d'outil « supprimer les règles
  dupliquées » sur ce fichier.
- **`--pulse`** était la copie décimale **exacte** de `--ok` dans les deux thèmes (29,122,56 et
  55,214,122). Invisible au garde-fou couleurs, puisque c'était une déclaration de token : changer
  `--ok` aurait laissé le halo derrière. Source unique désormais — `--ok-rgb` porte le triplet,
  `--ok` en dérive. Vérifié au calculé : `rgb(29, 122, 56)` / `rgba(29, 122, 56, 0.45)` en clair,
  `rgb(55, 214, 122)` / `rgba(55, 214, 122, 0.45)` en sombre, identique sur les deux moteurs.
- **`#brandSub .sess-dot`** : CSS mort. `.sess-dot` n'est émis que dans les cartes « sessions en
  cours » de l'accueil ; `#brandSub` est un `<span>` de texte. 0 nœud sur 3 états × 2 moteurs.

### Commentaires qui mentaient
- `posoCardsHtml` s'annonçait « source unique **partagée par le flux et la feuille Consulter** — les
  deux rendus ne peuvent pas diverger ». Faux depuis v4.25.3, qui a retiré la posologie de la
  feuille : il ne reste qu'**un** site d'appel. Le commentaire promettait une garantie de
  non-divergence entre deux rendus dont l'un n'existe plus. **AGENTS.md portait la même
  affirmation**, en contradiction avec sa propre section « FEUILLE CONSULTER » deux paragraphes
  plus haut — corrigé aux deux endroits.
- `_vvhSync` annonçait « ~1 s » : il tourne à **3,3 fois par seconde** (`setInterval(…,300)`, appel
  placé avant le garde d'activité). Coût mesuré : **nul** — `vv.height` est déjà calculé, et
  l'écriture n'a lieu qu'au-delà de 0,5 px de variation. Le chiffre est corrigé parce qu'un
  commentaire faux sur une fréquence est ce qui fait ensuite « optimiser » au jugé une boucle qui
  ne coûte rien.

### Le filet manquant : `scripts/check-sw.mjs`
**La fonction dont tout dépend en intervention — exister hors ligne — était la seule que rien ne
mesurait** : aucun des onze harnais ne regardait `sw.js` ni le manifeste, et trois des défauts les
plus graves de cet audit vivaient là, trouvés à la lecture seule. Quatre contrôles **statiques**,
donc instantanés, donc dans `npm run check` à chaque commit : toute entrée d'`ASSETS` /
`CORE_ASSETS` / `PDFJS_ASSETS` existe sur le disque (une entrée fantôme dans `CORE_ASSETS` fait
échouer `addAll`, qui est tout-ou-rien, et supprime le hors-ligne entier) ; `CORE_ASSETS` ⊆
`ASSETS` ; tout fichier servable de la racine est dans `ASSETS` — la règle 13 ne s'auto-exécutait
pas ; `CACHE` aligné sur `APP_VERSION`, c'est-à-dire la règle 1. Vérifié capable d'échouer sur les
deux scénarios, fichier restauré à l'octet.

513 tests × 2 moteurs, 11 harnais verts (34/34 en doctrine), 289 contrôles d'accessibilité.

## [4.43.0] — 2026-07-27
### Deux arbitrages tranchés : 320 px est servi, et la production est GitHub Pages
Décisions utilisateur. Elles débloquent quatre constats du reliquat d'audit.

### 320 px — WCAG 1.4.10, et deux rognages silencieux
C'est le plancher de « Reflow », et deux surfaces y perdaient du contenu sans le dire :

- **rangée de commandes de crise** : 348 px requis pour 320, soit **28 px inatteignables** — le
  bouton restait opérable (44 px visibles, `aria-label` intact) mais se lisait « ⤢ Con », coupé en
  plein mot ;
- **`⋯` de l'éditeur** : **6,2 px hors écran**, bouton pourtant `display:grid` donc bien peint.

Identique sur Chromium et WebKit. Les pixels viennent de la recette v4.23.4 — écarts et
rembourrages — jamais d'un renommage (règle « troncature du même mot ») ni d'une 2ᵉ ligne (la
hauteur de crise est un coût permanent) : **34 px rendus pour 28 nécessaires** dans la crise,
~12 pour 6,2 dans l'éditeur.

Une analyse antérieure concluait que la recette était épuisée et qu'il faudrait sacrifier
`.ctrl-sp`. C'est faux, et pour une raison précise : elle visait les postes déjà compressés en
v4.30.0, jamais le rembourrage des deux segments de mode (12 px à lui seul) ni celui des deux
ouvertures. **`.ctrl-sp` n'est pas touché** — ces 4 px sont l'écart de Gestalt qui sépare le MODE
des OUVERTURES, raison d'être de la séparation ECP/ECAM de v4.25.0.

Le harnais gagne un contrôle qu'il n'avait pas : le **rognage par le conteneur**. Un bouton peut
tenir dans la fenêtre tout en étant coupé par sa boîte de contenu — c'est exactement ce qui se
produisait, et le contrôle « hors écran » seul passait au vert. `audit-doctrine` mesure désormais
320/360/375/390 pour la crise et 320/360 pour l'éditeur (34/34).

### Hébergement : GitHub Pages en production, déployable ailleurs
Décision datée dans `docs/deploiement-et-conformite.md` et en tête de `_headers`. Conséquence
assumée : **`_headers` est maintenu à jour bien que GitHub Pages l'ignore totalement** — il n'est
pas décoratif, c'est la posture servie sur tout autre hébergeur, et le supprimer ferait disparaître
le seul endroit où elle est écrite.

Ajoutés : `Cross-Origin-Opener-Policy` et `Cross-Origin-Resource-Policy` en `same-origin`
(`window.open` est absent du code — vérifié, 0 occurrence — donc aucun échange de fenêtre à
casser), et une `Permissions-Policy` portée de 3 à **21 capacités**.

**COEP `require-corp` est délibérément absent** : aucun `SharedArrayBuffer`, aucune ressource
cross-origin embarquée, donc il ne protège rien — et il casserait au premier ajout. Un en-tête qui
ne protège rien et casse plus tard est une dette.

Trois capacités restent **volontairement ouvertes**, et la liste a été établie par mesure, pas
recopiée d'un modèle :
- **`autoplay`** — le bip d'alarme passe par WebAudio, soumis à la politique d'autoplay. Le fermer
  rendrait l'alarme de minuteur **muette** : la sortie la plus critique de l'application.
- **`screen-wake-lock`** — inutilisé aujourd'hui, mais garder l'écran allumé pendant une
  réanimation est un besoin plausible.
- **`web-share`** — `navigator.share` est le chemin **obligatoire** du téléchargement PDF en PWA
  installée (v4.19.1 : WebKit ignore `download` en standalone).

`launch_handler: {client_mode: "focus-existing"}` ajouté au manifeste — la seule des quatre clés
manquantes qui porte un argument clinique (ne pas ouvrir une seconde fenêtre pendant une session
vive). iOS ne l'implémente pas ; Android et bureau si.

**`"id": "./"` n'est PAS modifié**, et la raison est écrite pour la prochaine fois : `id` se résout
par rapport à l'**origine**, pas au chemin du manifeste. Le changer ferait apparaître l'app comme
une **nouvelle application** chez tout utilisateur l'ayant installée — doublon sur l'écran
d'accueil, ancienne installation figée sur son cache. C'est une porte à sens unique. Contrainte qui
en découle : ne pas héberger une seconde PWA sur la même origine.

510 tests × 2 moteurs, 11 harnais verts (34/34 en doctrine), 289 contrôles d'accessibilité.

## [4.42.0] — 2026-07-27
### Le reliquat d'audit trié : 36 % était périmé
Les 70 constats jamais traités de la Phase 1 ont été reconfrontés au code actuel, chacun sous
contre-expertise. **25 sont tombés** : 2 déjà corrigés, 5 mal fondés, 18 dont la preuve se
reproduit mais dont le verdict s'inverse (victime inexistante ou remède pire que le mal). Restent
45, dont **22 sont des questions à trancher** et 23 des corrections — dont **4 seulement changent
quelque chose pour un soignant**. Ce sont ces quatre-là.

Deux familles se sont effondrées en bloc. Les constats de **performance** mesuraient des *comptes
d'appels* sans chronomètre : le tick de 300 ms coûte 0,5 ms/s de mise en page, le resize PDF
0,26 ms, `syncHdrScroll` 0,10 ms/s de gain potentiel — à comparer aux 126,8 ms/s du seul vrai
levier de v4.41.0. Les constats **« le dépôt ne documente pas X »** reposaient sur des greps qui
excluaient `CHANGELOG-archive.md`, qui est pourtant le canal de décision du projet.

### Décocher ne défaisait pas la fin de l'algorithme, en mode guidé
Le cœur du cochage existe en deux copies, guidé et journal, et elles avaient divergé. Le journal
remet `state.flowEnded` à false puis re-rend si la bannière traîne. Le guidé faisait le reset dans
la branche `else` d'un `if(nn)` — or quand la fin est actée, `#navNext` **n'existe plus** :
`navSection` le remplace par la bannière `.flow-end`. `nn` étant null, le bloc entier était sauté
et le reset ne s'exécutait **jamais dans le seul cas où il sert**. Mesuré sur une fiche mono-bloc
(ce que rend `blankFiche()`, donc toute fiche neuve) : « Algorithme terminé — surveillance en
cours » restait affiché après décochage et « Terminer l'algorithme » ne revenait pas.

**Ce chemin n'était couvert par aucun test** : `grep -rn 'nav-wrap\|navNext\|bindNavEvents'
tests.html scripts/` rendait 0. Cinq contrôles ajoutés à `audit-doctrine.mjs` (27/27), vérifiés
capables d'échouer — défaut réintroduit, 3 échecs, fichier restauré à l'octet.

### L'alarme routée était muette pour les lecteurs d'écran
Session hors de vue (autre fiche, autre vue), un minuteur sonne : banderole visuelle, flash écran,
et notification système **seulement si l'app est en arrière-plan**. Restait le bip — qui dit qu'un
minuteur a sonné, jamais **lequel** ni **sur quelle fiche**. C'est précisément le cas où
l'information manque : une session vive sur une autre fiche pendant qu'on lit un différentiel.
`announce()` écrit désormais dans `#srLive` (`role=alert`, `aria-live=assertive`) : audible côté
lecteur d'écran, **invisible à l'écran** — la règle 11 tient, rien ne bouge et rien ne se pose
par-dessus la checklist. Vérifié : une seule banderole ajoutée, pas deux (WCAG 4.1.3).

### Trois minuteurs de même id n'en armaient qu'un
`migrate()` déduplique les ids de blocs (`while(used[nid])`) mais pas ceux des minuteurs ni des
compteurs. Or `Runtime.timers` est indexé par id : trois entrées de même id, **une seule armée, la
dernière**, sans le moindre signal — et les ids DOM (`tmval-`, `cnval-`) se télescopent. Une fiche
importée, dupliquée ou reçue d'une bibliothèque partagée passe par là, et la règle 5 veut que
`migrate()` soit le point où une donnée entrante devient sûre. Le premier garde son id (les
références `counters[].timerId` continuent de résoudre sur lui) ; les suivants en reçoivent un
neuf. Mesuré : 3/3 ids distincts, 3/3 minuteurs armés, 3/3 cartes, 2/2 compteurs.

### Un pull de synchro avalait un tap en pleine réanimation
`if(applied)render()` reconstruisait tout le DOM dès qu'une seule ligne distante était écrite —
y compris en session vive. La règle 11 l'interdit déjà en toutes lettres (« aucune synchro
intrusive ») : ce n'était donc pas un arbitrage. Il suffisait qu'un coéquipier modifie une ligne
d'une bibliothèque partagée.

Le premier contrôle que j'avais écrit était faux, et il faut le dire : un `.click()` programmatique
sur un nœud détaché déclenche quand même son handler (la fermeture survit), et je comptais des
*clés* de `state.checked` alors que décocher écrit `false` et conserve la clé. Un tap réel est
`pointerdown → pointerup → click`, et le click n'est émis que si les deux atterrissent sur le même
élément : le défaut est donc « DOM remplacé entre les deux ». Reproduit à la vraie souris,
Chromium **et** WebKit — **témoin : 0 → 0 coche** (tap avalé) ; **après correctif : 0 → 1**, sans
re-rendu ; et hors session le rendu se déclenche toujours.

Rien n'est perdu pendant ce temps : la mémoire est déjà à jour, et toute sortie de crise passe par
`render()`. Ce qui reste vrai, et c'est voulu : **la fiche ouverte ne change pas sous les yeux du
soignant** — une aide partagée réécrite à distance en pleine réanimation ne se substitue pas à
celle qu'on déroule ; la nouvelle version arrive à la réouverture.

510 tests × 2 moteurs, 11 harnais verts (dont 27/27 en doctrine), 289 contrôles d'accessibilité.

## [4.41.0] — 2026-07-27
### Phase 3 (optimisation) — premier lot : le seul vrai levier de performance, et deux invariants
La campagne de mesure a couvert six dimensions (démarrage, re-rendus, calcul répété, service
worker, CSS, Web Vitals) sous vérification adversariale. **Le résultat principal est que
l'application est déjà rapide** : 26 « rien à faire » démontrés, 16 constats réfutés, et **un seul**
levier de performance réel. Les chiffres du budget, re-mesurés machine au repos : démarrage 66 ms
(CPU nominal) / 262 ms (×4) ; un parcours clinique complet ne déclenche que 5 `render()` complets ;
`esc()`, appelée 817 fois par rendu, coûte 0,06 ms.

### `transition:width` sur la barre de minuteur → `transform:scaleX()`
`width` est une propriété de **mise en page** : animée en continu, elle force un layout par image.
En session vive avec un minuteur d'intervalle armé et le panneau ouvert, six secondes sans le
moindre geste : **118 layouts/s, 123 recalculs de style/s**, soit 126,8 ms/s de fil principal à CPU
nominal, 206,9 à ×4 et 377,3 à ×6 — **jusqu'à 38 % d'un cœur brûlés pendant toute une réanimation**,
sans qu'aucun JS ne s'exécute.

Mesuré après application, sur le fichier réel contre un témoin `width` réinjecté :
115,0 → **11,4** ms/s (×1), 193,5 → **18,2** (×4), 248,0 → **25,9** (×6) ; 115 → **2** layouts/s.
WebKit, hors CDP : **+9,7 %** de débit utile du fil principal.

Un arbitrage annoncé n'a finalement pas eu lieu d'être. Deux vérificateurs divergeaient sur ce que
rend `scaleX` — l'un mesurait ~120 recalculs de style/s résiduels, ce qui aurait obligé à choisir
entre performance et rendu. L'A/B rejoué à trois variantes (actuel / `scaleX` / sans transition),
servies en mémoire, tranche : **17 recalculs/s**, l'animation est bien composée, et `scaleX` rend
autant que supprimer l'animation *sans changer le rendu*. Le gain est de la **marge CPU et de
l'autonomie**, pas de la fluidité (120 fps et latence de cochage identiques) — ne pas le vendre
autrement.

Rendu vérifié au pixel, et la première sonde était fausse : elle mesurait un minuteur **en marche**,
donc une cible mouvante (le « 0 % » relevait `scaleX(0.9912)` — le minuteur avait rebouclé). Refaite
à minuteur figé : géométrie identique à 0,01 px près, et la comparaison des captures ne diffère que
sur **une colonne de 4 px** — l'anticrénelage du bord mobile, écart max 73/255 — plus les deux
extrémités arrondies à 100 % (≤ 9/255). Identique dans les deux thèmes. Une source unique `barTf()`
sert le gabarit ET le tick : deux formats seulement équivalents (`scaleX(0.76)` vs `scaleX(0.7600)`)
feraient échouer la comparaison anti-churn et réécriraient le style 3,3 fois par seconde. Vérifié :
17 écritures en 5 s pour ~16,7 passages du tick, soit une par tick.

### Garde-fou `scripts/check-anim.mjs`, dans `npm run check`
Aucune propriété de mise en page dans un `transition` ni dans un `@keyframes`. La règle était déjà
respectée partout ailleurs (19 keyframes sur 19) — c'est le profil exact d'une règle qu'un seul oubli
trahit sans que rien ne le signale. Une exemption, motivée : `.skiplink` (glissement de 120 ms une
fois par focus ; le convertir mettrait en jeu une position dépendant d'`env(safe-area-inset-top)`,
soit un risque d'accessibilité pour un gain nul). Le contrôle a été **vérifié capable d'échouer**
(défaut réintroduit, message juste, fichier restauré à l'octet) — leçon v4.31.1 : un garde-fou qui
ne peut pas échouer ne prouve rien.

### `touch-action:manipulation` sur les étapes cochables
AGENTS.md § Interactif énonce que « tous les contrôles » le portent. Mesuré en session vive à
390×844 : **5 cibles en `touch-action:auto`** sur « Anaphylaxie », 3 sur « Arrêt cardiaque » — les
`li[role="checkbox"]` du parcours, que la règle de base ne couvrait pas alors que
`li.md-task[role="checkbox"]` (protocoles) le posait déjà. Après : **0**, sur Chromium et WebKit.
Le gain n'est pas un délai de tap — le délai de ~350 ms n'existe plus pour un viewport
`width=device-width`, et le commentaire qui l'affirmait encore avait servi à justifier de ne pas
étendre la règle : il est corrigé. Ce que le réglage évite est le **zoom parasite** quand deux taps
tombent à moins de ~40 px l'un de l'autre — 12 px mesurés entre deux étapes voisines, et en
réanimation on coche des étapes voisines à la chaîne.

### Un minuteur échu ne peignait pas son état sur les rangées compactes
Trouvé par la sonde du point précédent. `.tm-mini` (rangée compacte d'un minuteur ad hoc, le
« ＋ Minuteur PA ») partage l'id `tmcard-<id>` avec la carte pleine, et `syncTimerBtns` bornait son
basculement d'état à `.tmcard`. Mesuré sur **Chromium ET WebKit** : le modèle disait « échu », la
rangée restait NEUTRE tant qu'aucun re-rendu complet ne passait — alors que `.tm-mini.due` est bien
stylée (cadre et encre ambre). L'alarme n'était pas perdue (le quai porte l'ambre, canal
d'acquittement documenté), mais elle manquait là où l'œil se trouve quand le panneau est ouvert.
`paused` reste réservé à la carte pleine : `.tm-mini.paused` n'a pas de règle.

510 tests × 2 moteurs, 11 harnais verts, 289 contrôles d'accessibilité.

## [4.40.0] — 2026-07-26
### Les 4 dernières fenêtres : le harnais d'accessibilité couvre les 20 sur 20
`attPickModal`, `relPickModal`, `reportModal` et `newLibModal` étaient signalées « résistantes » en
v4.39.0. Elles ne résistaient pas : **mes appels étaient faux**. Les vraies signatures sont
`openAttPicker(entity, rerender)`, `openRelPicker(entity, rerender)` et surtout
`exportSessionReport(sessionId)` — un **ID**, pas l'objet session. `openNewLib()` est par ailleurs
gardée par `myIsAppAdmin` : garde métier légitime, dont la vraie barrière est la RLS serveur ; la
sonde la lève pour auditer le RENDU, ce qui est l'objet du harnais.

Le compte-rendu n'est atteignable que par le parcours COMPLET (ouvrir, démarrer, terminer) puisqu'il
lit `sessions`, les sessions **archivées**. C'est en le déroulant qu'un défaut de sonde plus gênant
est apparu.

### Défaut de sonde corrigé : trois fenêtres mesuraient un contexte FACTICE
Les surfaces « historique sessions », « terminer la session » et « complications » posaient
`state.view='read'; state.fiche=f; render()` à la main. Or ce n'est pas le point d'entrée :
`openRead(id)` appelle `buildRuntime` puis `bindStateToRuntime`, sans quoi **le Runtime n'est pas
installé** — le clic sur « démarrer la session » ne démarrait donc rien. Mesuré :
`Runtime.started=false`, `liveSessions=0`, `sessions=0`. Les trois fenêtres s'ouvraient bien, mais
dans un contexte SANS session vive, pas celui que le harnais annonçait ; une régression propre à la
session vive n'aurait pas été vue. Les trois passent par `openRead(f.id)`.

C'est le même travers que le `classList.add('on')` refusé en v4.39.0, en plus discret : reconstruire
un état à la main au lieu d'emprunter le chemin de l'utilisateur. Défaut du harnais, jamais de l'app.

### Résultat
**289 contrôles, 20 fenêtres × 2 thèmes, aucun défaut.** Les 4 dernières fenêtres n'ont rien révélé —
résultat en soi : les corrections de v4.37→v4.39 (associations `for=`, noms de champs, `[hidden]`
impératif, cibles) tenaient déjà sur les surfaces non encore auditées. Les 11 harnais restent verts,
510 tests sur Chromium et WebKit.

## [4.39.0] — 2026-07-26
### Harnais d'accessibilité : de 6 fenêtres auditées à 16 sur 20
Chaque fenêtre est ouverte par son **vrai point d'entrée**, après CONSTRUCTION de son contexte —
session vive pour « Terminer la session » et l'historique, sauvegarde de version pour « Versions
précédentes », complication déclarée pour l'index ⚡, document joint pour la visionneuse PDF. Jamais
un `classList.add('on')` : une fenêtre forcée vide n'a pas le contenu qu'on veut mesurer et
produirait des verdicts faux. Le mécanisme `prep` accepte donc désormais une **fonction**,
sérialisée par Playwright — la mise au point a d'ailleurs confirmé que la CSP du projet **interdit
bien `eval()`** : la première version de la sonde, qui passait du code en chaîne, a été bloquée.

Les 4 dernières (`attPickModal`, `relPickModal`, `reportModal`, `newLibModal`) résistent encore :
leurs points d'entrée attendent des arguments ou un état non reconstitué. Signalé plutôt que
contourné.

### Ce que ces dix fenêtres ont révélé
- **Un faux positif du harnais — corrigé dans le harnais, pas dans l'app.** `#pendToggle` était
  signalé à 13×13 px, sous le seuil de 24. Mais son `<label>` parent fait **358×65 px** et coche la
  case au clic : la CIBLE au sens de WCAG 2.5.8 (« la zone qui accepte l'action du pointeur ») était
  donc largement conforme. Le harnais mesure désormais le label quand il en existe un — même esprit
  que la recherche de l'anneau de focus sur les ancêtres, déjà en place. Agrandir les cases pour
  faire taire ce contrôle aurait été un changement visible pour un défaut inexistant.
- **Mais les cases se LISAIENT mal** (décision utilisateur) : aucune règle du projet ne les
  dimensionnait, elles gardaient les ~13 px du navigateur — dont l'interrupteur de sécurité
  « Exiger une validation pour les nouveaux comptes ». Passées à **20 px** avec
  `accent-color:var(--primary)` : la case cochée prend le bleu de l'app au lieu du bleu système.
  Appliqué aux **quatre** cases de l'app (confirmation, suppression locale, validation des comptes,
  boucle d'un minuteur) — les styler une par une aurait recréé l'incohérence.
- **Le bruit réseau est filtré nommément** : les fenêtres liées au compte interrogent Supabase et
  crient `ERR_INTERNET_DISCONNECTED` hors réseau. C'est le contexte de la sonde, pas un défaut de la
  page ; seul ce motif est filtré, pour ne pas masquer une vraie erreur.

**241/241** contrôles d'accessibilité — contre 121 avant, sur un périmètre deux fois plus étroit.

510 tests × 2 moteurs, 22/22 doctrine, 241/241 accessibilité, 163 contrôles d'audit, 10 sondes.

## [4.38.0] — 2026-07-26
### Tous les champs de l'éditeur ont enfin un nom
**39 champs sur 53 n'étaient nommés que par leur `placeholder`** — qui disparaît dès qu'on tape.
Concrètement : on revient sur un champ déjà rempli, et plus rien ne dit ce qu'il contient ; un
lecteur d'écran annonce « champ, texte » sur ce qui est peut-être la dose d'un protocole de
réanimation. C'est WCAG 3.3.2 et 4.1.2, et c'est l'antipattern le plus répandu des formulaires.

Le diagnostic a montré que ces 39 champs n'étaient **pas de même nature**, et qu'un `aria-label`
uniforme aurait été la mauvaise réponse :
- **4 gabarits avaient déjà un `<label>` visible ET un `id`** : il suffisait de les associer
  (`for=`). Aucune duplication, et le libellé devient cliquable pour focaliser le champ.
- **Les autres sont des LIGNES DE LISTE** — « Ne pas oublier », étapes d'un bloc, options d'une
  décision — coiffées par un `<label>` de section qui ne peut être associé à aucune en particulier.
  Elles reçoivent un nom qui dit leur liste ET leur rang : « Ne pas oublier — ligne 1 »,
  « Étape 3 », « Libellé de la réponse 2 ».
- **Les rangées de minuteur et de compteur** reçoivent le nom de ce qu'elles règlent (« Nom du
  cycle », « Nom du chronomètre », « Nom du compteur »), et le sélecteur de relance — jusqu'ici
  nommé par un simple `title`, pis-aller que tous les lecteurs ne lisent pas et qui n'existe pas
  sur mobile — reçoit un vrai `aria-label`.

Vérifié : **0 champ anonyme et 0 champ nommé par son placeholder** sur les 53 de l'éditeur, et
**aucun nom n'est une simple copie du placeholder** (contrôlé explicitement — recopier « ex. Oui »
n'aurait rien nommé du tout).

Aucun changement de rendu : le diff est de 11 lignes modifiées pour 11, uniquement des attributs,
et aucune règle CSS du fichier ne cible `label[for]` ni `[aria-label]` (vérifié).

510 tests × 2 moteurs, 22/22 doctrine, 121/121 accessibilité, 143 contrôles d'audit, 10 sondes.

## [4.37.0] — 2026-07-26
Deux garde-fous élargis, et **un bouton fantôme trouvé grâce à l'un d'eux**. Aucun changement de
rendu voulu — et aucun constaté, vérifié par comparaison des couleurs calculées avant/après dans
les deux thèmes.

### Garde-fou couleurs — il ne voyait que la moitié de la règle
`check-colors.mjs` n'inspectait que les **hex**. Un token recopié en DÉCIMAL passait donc au
travers, et c'est exactement la dérive que la règle proscrit : cinq occurrences de `rgba(16,27,40,…)`
— la valeur de `--ink` — vivaient dans les voiles et les élévations. Si `--ink` changeait, elles
seraient restées derrière.

Sur les 34 valeurs littérales du CSS, le tri est net et toutes ne sont pas des dérives :
- **5 étaient de vraies copies de token** → tokenisées, à valeur **strictement identique** :
  `--scrim-soft` (voile du menu de catégories), `--scrim` (fenêtres), `--scrim-full` (visionneuse
  d'image), `--shadow-dock` et `--shadow-bar`. Aucun override sombre ajouté : ces valeurs n'en
  avaient pas, en créer un serait un changement visible.
- **Le reste n'est PAS de la palette** et est exempté avec sa raison dans le script : noir et blanc
  PURS (profondeur, voiles neutres — ils ne portent aucune sémantique de registre) et les deux
  teintes de l'alerte de minuteur, dérivées d'aucun token. Un garde-fou qui crie sur ce qui va bien
  finit ignoré.

Le contrôle accepte désormais `rgb()`, `rgba()`, `hsl()`, `hsla()`. Contre-épreuve faite : remettre
`rgba(16,27,40,.55)` à la place de `var(--scrim)` le fait échouer.

### Harnais d'accessibilité — de 2 fenêtres auditées à 6
Il ne mesurait que `#planModal` et `#refModal` sur les **20** `.ai-modal` de l'application. Quatre
de plus y entrent (dialogue Créer, gérer les catégories, fenêtre Compte, « où sont mes fiches »),
ouvertes par leur **vrai point d'entrée** — jamais par un `classList.add('on')`, qui donnerait une
fenêtre vide et des verdicts faux. Les 16 autres exigent un contexte construit (session vive,
document joint, sélection, erreur de synchro) : mesuré, aucune ne s'ouvre par un simple appel —
c'est un chantier à part, avec une fixture par fenêtre.

**Ces quatre fenêtres ont immédiatement révélé deux défauts réels :**
- **`[hidden]` était une suggestion, pas une instruction.** La feuille du navigateur pose
  `display:none` pour cet attribut, mais avec une spécificité si faible que toute règle de classe
  portant un `display` l'écrase. Le projet compensait par une règle ponctuelle par composant —
  **vingt** au total — qu'il fallait penser à écrire, et `.tlink` avait été oublié : `#authAnon`,
  pourtant marqué `hidden`, s'affichait en **bouton VIDE de 20×32 px** dans la fenêtre Compte.
  Une règle globale `[hidden]{display:none!important}` ferme la classe entière de bugs ; vérifié
  qu'aucune règle du fichier n'affiche volontairement un élément `[hidden]`.
- **`.crt-chev`** (le chevron des cartes du dialogue Créer) était en `--line-strong` : 4,32:1, sous
  le seuil AA. C'est la règle déjà écrite dans `AGENTS.md` — `--line-strong` vise 3:1 pour les
  BORDURES et échoue en couleur de TEXTE — simplement jamais appliquée ici, faute que cette fenêtre
  soit mesurée. Passée à `--ink-soft`.

**121/121** contrôles d'accessibilité (117 avant l'élargissement, sur un périmètre plus étroit).

510 tests × 2 moteurs, 22/22 doctrine, 121/121 accessibilité, 143 contrôles d'audit, 10 sondes.

## [4.36.0] — 2026-07-26
### Corrigé — 1,77 Mo chargés pour ne rien dessiner
Ouvrir une fiche portant un PDF déclenchait le chargement de **pdf.js en entier** — `pdf.min.js`
389 Ko à +106 ms, `pdf.worker.min.js` 1 384 Ko à +181 ms — alors qu'aucun document n'avait été tapé.
Cela contredisait la règle du projet (« pdf.js chargé paresseusement, `import()` au premier document
OUVERT, jamais au démarrage »), sur l'écran de soin lui-même.

**Et c'était pire que ça.** Depuis la v4.23.0, la liste « Documents » d'une FICHE a quitté la colonne
d'action pour la feuille « Consulter », qui ne s'ouvre qu'à la demande. Mesuré à l'ouverture d'une
fiche : **0 rangée `[data-att]`, 0 emplacement `[data-thumb]` dans toute la page** — les 1,77 Mo
n'avaient littéralement rien à peindre. La chaîne `bindReadEvents` → `bindAttList` →
`hydrateAttThumbs` appelait la génération de vignettes **inconditionnellement**, alors que
`bindAttList` cherche ses rangées dans `main`, où il n'y en a plus. Travail intégralement perdu, et
redondant de surcroît : `renderRefSheet` rappelle `hydrateAttThumbs` à l'ouverture de la feuille,
là où les rangées existent.

Correctif d'une ligne — ne générer les vignettes que si une rangée est réellement dans le flux :
`if(main.querySelector('[data-thumb]')) hydrateAttThumbs(entity);`. Vérifié sur les trois cas qui
comptent : fiche seule → **0 Ko au lieu de 1 773** ; feuille « Consulter » ouverte → pdf.js chargé
et vignette peinte (96×128 px) ; **protocole → comportement inchangé** (ses documents sont dans le
flux, la condition est vraie pour lui).

> Nuance conservée pour la suite : ce n'est pas du réseau en usage normal (`sw.js` précache pdf.js à
> l'installation), mais le PARSING de 1,8 Mo de JS minifié et le démarrage d'un worker, en CPU, sur
> la vue utilisée pendant un soin. Le travail était différé par `_idle()` — donc il ne bloquait pas
> le premier rendu — mais une tâche d'idle n'est pas préemptible une fois commencée.

### Sécurité serveur — réserve de v4.34.0 LEVÉE
Les modifications SQL n'avaient pas pu être exécutées ici (ni Postgres ni Docker sur le poste) et
étaient livrées relues à la main. **Elles ont été rejouées sur l'instance réelle** : `schema.sql`
appliqué sans erreur, et `rls-tests.sql` répond « ✅ TOUS LES TESTS RLS PASSENT » — donc la
**section 13** (élévation de privilège, rôle anonyme, invitation à e-mail non vérifié) passe, et le
durcissement (`revoke all … from anon`, `alter default privileges`, `email_confirmed_at` exigé)
n'a rien cassé du flux existant.

510 tests × 2 moteurs, 22/22 doctrine, 73/73 accessibilité, 135 contrôles d'audit, 10 sondes.

## [4.35.0] — 2026-07-26
**Phase 4 de l'audit externe : simplification de la structure**, validée sur plan. Aucune ligne de
code applicatif touchée — documentation, arborescence et maintenance du dépôt. Les mesures ont
contredit l'énoncé de départ sur trois points, et le plus gros gain n'était pas dans la doc.

### Le plus gros gain : 144 Mo dans `.git`
- **151 Mo → 6,2 Mo en 2,8 secondes**, par un simple `git gc`. Mesuré avant : `count: 2922` objets
  **lâches** occupant 152 232 Ko, contre 219 objets packés tenant dans 1,1 Mo. `design/ds/`
  représentait **190 Mo sur 365 Mo** de blobs de l'historique, ses 20 fiches de ~275 Ko étant
  réécrites en bloc à chaque `design:build` (46 commits). Elles sont quasi identiques entre elles et
  d'une version à l'autre : elles se delta-compressent presque parfaitement.
- **Conclusion importante : `design/ds/` n'a AUCUN problème de structure.** L'hypothèse d'une
  dé-duplication de son CSS est ÉCARTÉE — l'autonomie de chaque fiche est intentionnelle (l'outil
  distant les lit isolément), la duplication en est le prix assumé. Ce n'était que de la maintenance
  jamais faite. Vérifié après coup : HEAD identique, 299 commits, 125 tags, `git fsck` sans erreur.

### Documentation — 9 → 8 fichiers, et un point d'entrée
- **`AGENTS.md` reçoit un socle « Si vous ne lisez qu'une chose »** : 14 règles qui ne se négocient
  pas (publication, `npm run check`, hashs CSP, `esc()`, `migrate()`, `safeId()`, tokens de couleur,
  registres, plancher 11 px, hauteurs sous zoom, mode crise jamais interrompu, compatibilité
  ascendante, zéro dépendance, vérification d'une suppression au grep) — suivies d'une **carte
  thématique** qui renvoie aux intitulés existants. Le problème n'était pas la longueur du fichier
  mais sa PLATITUDE : 1 297 lignes en une seule liste, sans point d'entrée, où l'on ne pouvait pas
  savoir ce qui est impératif sans tout lire. **Le diff est un AJOUT PUR** (+64/−0 lignes) : aucune
  règle déplacée ni réécrite, vérifié ligne à ligne contre la version précédente.
- **`CHANGELOG.md` : 221 Ko → 51 Ko** (112 → 20 entrées). Les 92 plus anciennes rejoignent
  `CHANGELOG-archive.md` **telles quelles** — 153 entrées avant, 153 après, zéro ligne de contenu
  absente (vérifié par comparaison exhaustive). La règle d'archivage existait déjà et n'avait servi
  qu'une fois ; elle est maintenant inscrite dans la règle de publication, avec son seuil.
- **`design/icons/README.md` fusionné dans `design/README.md`** — deux fichiers pour un seul sujet.
  Au passage, deux erreurs corrigées : le tableau des icônes listait `icon-512.png` **deux fois**
  avec des origines contradictoires, et `design/README.md` annonçait 15 fiches pour 20.
  `scripts/build-favicons.mjs` pointait vers le fichier supprimé : référence mise à jour.
- **`design/ds/GUIDELINES.md` remis à jour** (daté v4.22) : il décrivait encore au présent les trois
  affichages du Plan et le fil d'ancêtres sticky, supprimés en v4.25.0. Or ce fichier est **poussé
  tel quel** vers le projet Design distant : il documentait un composant inexistant auprès d'un
  outil externe. Son idée survit d'ailleurs ailleurs — l'épinglage des bandes-questions du mode
  statique (v4.32.0) — et c'est dit.

### Ce que je n'ai PAS fait, et pourquoi
- **`GUIDELINES.md` n'est PAS déplacé hors de `ds/`**, contrairement à ce que proposait le plan : la
  configuration de synchro dit « la synchro pousse `design/ds/` tel quel », le sortir d'un niveau
  l'aurait retiré du périmètre envoyé. Le plan annonçait donc −2 fichiers ; le résultat réel est −1.
- **Aucun `GEMINI.md`, `.cursorrules` ni `.github/copilot-instructions.md` ajouté.** `AGENTS.md` est
  le standard convergent (Codex, Cursor, Aider, Copilot le lisent), et `CLAUDE.md` l'importe en six
  lignes au lieu de le dupliquer. Ajouter des copies multiplierait les fichiers — contre la demande —
  pour créer la pire configuration : des sources qui divergent.
- **L'arborescence est inchangée.** Six dossiers thématiques, profondeur 3, aucun fichier égaré :
  « regrouper par fonctionnalité plutôt que par type » ne s'applique pas à un projet dont la seule
  fonctionnalité livrée est `index.html`. Et « réduire les niveaux d'abstraction » présupposait des
  couches qui n'existent pas : les deux seules indirections (`Data` sur trois backends, `Sync`)
  gagnent leur place.
- **Aucune règle supprimée d'`AGENTS.md`.** Le constat de phase 1 « AGENTS.md est un changelog
  déguisé » était EXAGÉRÉ : mesuré, 13 % des lignes citent une version, et ces citations sont de la
  traçabilité (« décision utilisateur v4.25.0 ») — elles disent pourquoi une règle existe et qui l'a
  tranchée, ce qui est précisément ce qui empêche de la « corriger » par ignorance.

### Une honnêteté sur les chiffres
Le plan annonçait « 433 Ko → ~230 Ko » de documentation. **C'est faux, et le total AUGMENTE
légèrement** (464 Ko) : les 92 entrées archivées sont DÉPLACÉES, pas supprimées, et le socle ajoute
6 Ko. Le gain réel porte sur le fichier qu'on LIT et que les outils chargent — `CHANGELOG.md`, −76 %
— et sur la navigabilité, pas sur le volume du dépôt.

510 tests × 2 moteurs, 22/22 doctrine, 73/73 accessibilité, 135 contrôles d'audit, 9 sondes dédiées.

## [4.34.0] — 2026-07-26
Troisième lot de l'audit externe : **sécurité serveur, couverture de test et documentation**. Aucun
changement de rendu. Un point à connaître : les modifications SQL n'ont PAS pu être exécutées ici
(ni Postgres ni Docker sur ce poste) — elles sont relues à la main, et doivent être rejouées sur une
instance de test avant d'atteindre la production.

### Sécurité serveur — trois trous de la suite RLS
- **Un membre invité perdait silencieusement son accès à sa première connexion.** Chaîne complète :
  `invite_member` cherchait le compte par e-mail SANS exiger `email_confirmed_at`, or la simple
  DEMANDE d'un code crée déjà la ligne `auth.users` (le client passe `create_user:true`) ; un tel
  compte n'a pas encore de ligne `user_status`, la garde d'approbation lisait donc NULL →
  `coalesce(…,'approved')` → invitation ACCEPTÉE ; puis sa première vraie connexion créait
  `user_status='pending'`, ce qui déclenchait `revoke_memberships` et EFFAÇAIT l'adhésion. L'admin
  voyait « ok », la personne apparaissait dans la liste des membres, et l'accès disparaissait sans
  trace ni message — le scénario le plus banal (« je t'ajoute, connecte-toi »). L'e-mail vérifié est
  désormais exigé : l'invitation prématurée retourne `not_found`, ce que le message client annonçait
  DÉJÀ (« la personne doit d'abord se connecter une fois ») — c'était le SQL qui ne tenait pas le
  contrat, pas l'interface. Le trigger de purge reste sur `insert or update` à dessein (le
  restreindre à UPDATE ouvrirait un trou) : la cause est fermée à la source, et c'est documenté sur
  place pour que la question ne se rouvre pas.
- **« Rien pour le rôle anonyme » était une ABSENCE de grant, pas une interdiction.** Le schéma
  n'ôtait jamais un privilège (0 `revoke` dans tout le fichier) : ne rien accorder à `anon` ne
  garantit rien si le projet porte des privilèges par défaut hérités de sa création, invisibles
  depuis le dépôt. Or la clé publishable est publiée en clair dans `index.html` : `anon` est
  utilisable par quiconque contre l'API REST. La posture affichée — « grants restrictifs PUIS
  RLS » — n'avait donc qu'un seul rempart démontrable. Ajout de `revoke all … from anon` sur les
  tables et les fonctions, **et sur les privilèges FUTURS** (`alter default privileges`), pour
  qu'une table ajoutée plus tard ne soit pas exposée par oubli.
- **Les politiques d'ÉLÉVATION DE PRIVILÈGE n'étaient jamais exercées.** Les onze écritures de la
  suite sur `memberships` et `user_status` étaient TOUTES faites en tant que propriétaire de table,
  qui CONTOURNE la RLS : `mem_write`, `lib_update`, `lib_delete` et `user_status_write` n'avaient
  jamais été testées, alors que `memberships` est la table dont dépendent toutes les autres
  politiques partagées (`member_role()` est consultée par cinq d'entre elles — une faille d'écriture
  y compromettrait tout d'un coup). **Section 13** ajoutée, chaque test en `set local role
  authenticated` : un viewer ne s'élève pas admin, un non-membre ne s'ajoute pas, un editor ne
  renomme ni ne supprime la bibliothèque, personne ne s'approuve soi-même, `anon` ne lit AUCUNE des
  sept tables publiques, et une invitation à un e-mail non vérifié est refusée.

### Tests — la cible principale n'était pas testée
- **`npm test` joue désormais Chromium ET WebKit.** iOS Safari est la cible principale (PWA
  installée sur iPhone, usage SMUR) et toute la suite tournait sur Blink seul — alors que le dossier
  « bande basse iOS » (v4.29.x) a précisément montré qu'un comportement WebKit peut couper l'écran
  sans qu'aucune mesure web ne le voie. Les fonctions pures ne sont pas à l'abri non plus
  (`DecompressionStream` de l'import .zip, regex, normalisation Unicode). WebKit absent produit un
  AVERTISSEMENT et non un échec, même dégradation douce que pour Playwright lui-même ; la CI
  l'installe. Résultat : **510 tests verts sur les deux moteurs**.
- `run-tests.mjs` ne JETTE plus les erreurs console quand la page ne boote pas : c'est le mode
  d'échec le plus probable (hashs CSP périmés, erreur de syntaxe) et il produisait jusqu'ici la
  sortie la moins lisible — l'exception emportait la seule information utile.

### Sécurité côté document
- **`<meta name="referrer" content="no-referrer">`** : c'est le SEUL des cinq en-têtes de `_headers`
  qui ait un équivalent balise, donc le seul récupérable là où `_headers` est ignoré — GitHub Pages,
  intranet nu. HSTS, `nosniff`, `X-Frame-Options` et `frame-ancestors` n'existent qu'en en-tête HTTP :
  rien à faire côté document, et c'est dit.
- La doc de déploiement sous-estimait la perte sur GitHub Pages : son tableau citait le `no-cache`
  sur `sw.js` mais omettait celui sur `/` et `/index.html`. Or la stratégie « cache d'abord »
  suppose que le rafraîchissement de fond atteigne le SERVEUR : servi depuis un cache
  intermédiaire, il peut réécrire une copie périmée dans le cache hors-ligne. Deux lignes ajoutées
  au tableau, et la conséquence expliquée.

### Documentation — trois affirmations fausses
- « **éditeurs alignés sur leur vue de lecture (fiche ≤ 860 px)** » : mesuré faux — l'éditeur rend
  1fr+320 au-delà de 1200 px. La règle du palier listait bien `body.view-edit`, mais le bloc 1000 la
  reprend **2 293 lignes plus bas** à spécificité ÉGALE (`:is()` prend le max de ses arguments) et
  gagne par l'ORDRE : la règle était MORTE tout en donnant l'illusion d'être appliquée. **4ᵉ incident
  de ce type** après `.read-grid`, `.cbt-n` et `.mode-seg`. Le membre inopérant est RETIRÉ de la
  règle du palier — zéro changement visuel, prouvé à 1400 px — plutôt que réaffirmé plus bas :
  aligner réellement l'éditeur sur 860+360 serait un changement VISIBLE, à décider séparément.
- Le **plan du monofichier** annonçait « ~5 600 lignes » pour 12 250 et décrivait 16 sections sur
  **54**. Il est présenté pour ce qu'il est — un RÉSUMÉ, pas un index — avec la commande `grep` qui
  donne l'index exact et à jour, et le découpage global en lignes. Des numéros de ligne figés dans
  la doc seraient périmés au commit suivant : mieux vaut la commande.
- `AGENTS.md` disait `npm test` sur un seul moteur.

510 tests × 2 moteurs, 22/22 doctrine, 73/73 accessibilité, 135 contrôles d'audit, 9 sondes dédiées.

## [4.33.0] — 2026-07-26
Second lot de l'audit externe : les correctifs dont le RENDU change, volontairement séparés du lot
invisible de v4.32.0. Chacun restaure une doctrine que le code violait, ou rend audible une surface
qui ne l'était pas. Deux découvertes faites en cours de route, hors du relevé initial.

### Corrigé — registres perdus
- **`.pl-stp` : la régression jumelle de v4.25.0.** La purge du Plan « Détails » avait emporté les
  cinq règles de cette classe alors que `ovPlanLadderHtml` l'émet TOUJOURS : pendant six versions,
  une étape **⚠ (memory item)** s'affichait en encre ordinaire dans le détail de « Se repérer »,
  avec les puces disque du navigateur, indiscernable d'une étape banale — dans une surface visible
  en permanence dans le rail dès 780 px et ouvrable d'un tap du quai de crise. Le pendant statique
  (`.sv-stp li.crit`), lui, n'avait jamais cessé d'être peint : deux surfaces de la même app
  donnaient une lecture différente du même contenu vital. Règles restaurées à l'identique de
  v4.24.0 ; vérifié dans les deux thèmes (⚠ = `--critical`, △ = `--verify`, graisse renforcée en
  second canal non chromatique, corps 11,5 px, puces « · »).
- **`.sv-x`** (compteur de passages « ×n » du statique) était émis sans aucune règle. Stylé en encre
  DOUCE et non bleue, contrairement à son jumeau `.pl-x` : dans le statique, « aucun texte bleu dans
  les cellules » — le bleu n'y marque que la position et la reprise. Copier `.pl-x` aurait réparé la
  taille en cassant la doctrine.

### Corrigé — contenu qui sortait de l'écran
- **Cinq `vh` NUS** subsistaient malgré la règle « toute hauteur relative à la fenêtre s'écrit
  `calc(…/var(--zf))` » : le réglage de taille du texte est un `zoom` sur `<html>`, qui agrandit la
  valeur APRÈS sa résolution. Conséquence mesurée à 130 % : dans la visionneuse d'image, 8 px
  d'image et **51 px de légende hors écran**, sans aucun défilement possible — et c'est précisément
  l'utilisateur qui a AGRANDI le texte qui voit mal. Corrigés (visionneuse, schéma, compte-rendu,
  feuille de catégories, sélecteur de documents) ; vérifié à 100 / 115 / 130 %.
- Le harnais qui prétendait couvrir cette règle ne regardait que deux surfaces nommées : il reçoit
  une **sonde générique** qui balaie le CSS résolu de tout élément visible et échoue sur toute
  hauteur bornante dépassant la fenêtre, quel que soit son nom.

### Accessibilité
- **La vue de lecture n'avait AUCUN titre.** Son unique `<h2>` était éteint par `display:none` à
  l'écran (il ne servait qu'à l'impression) — donc absent de l'arbre d'accessibilité — et les sept
  intertitres de section sont des `<div>`/`<span>`. Sur la surface CLINIQUE, il n'y avait donc rien
  à parcourir : il fallait traverser toute la fiche linéairement pour atteindre « Repères
  posologiques ». Le titre passe HORS ÉCRAN (propriétés de `.sr-only`, rien ne change à l'œil) et
  les intertitres reçoivent `role="heading" aria-level="2"` — sémantique sans changer la balise ni
  le CSS. Mesuré : **0 → 25 titres** parcourables, en portrait comme en paysage.
- **`#flowFull` et `.lightbox` : calques OPAQUES plein écran sans sémantique de dialogue.** Ni rôle,
  ni nom, ni déplacement du focus : mesuré, **14 tabulations sur 14 sortaient derrière le calque**,
  atterrissant sur « ⤢ Se repérer » ou des étapes cochables invisibles, en pleine session. C'est
  WCAG 2.4.11, le défaut corrigé en v4.30.0 pour les couches collantes et resté entier pour les
  overlays. Rôle + `aria-modal` + nom, focus déplacé à l'ouverture et RENDU à la fermeture, verrou
  de fond, piège Tab. Ils ne deviennent pas des `.ai-modal` (CSS distinct, et Échap leur est câblé
  nommément — les inscrire dans `_topModal()` aurait cassé leur fermeture, qui cherche un `.ai-x`
  qu'ils n'ont pas) : de nouvelles primitives `_layerEnter`/`_layerLeave` réutilisent les mêmes
  briques. L'image agrandie reçoit enfin un `alt` — sa LÉGENDE : `alt=""` la rendait décorative
  alors qu'elle est le contenu même de la couche. Vérifié : 0 sortie sur 14.
- **`--primary` en couleur de TEXTE** sur trois contrôles (lien d'évitement, pilule du mode lecteur,
  « Pourquoi créer un compte ? ») : 3,44:1 en thème sombre, sous le seuil AA. La règle du projet
  l'énonce déjà — en sombre `--primary` est un REMPLISSAGE, l'accent TEXTE est `--link` (8,24:1).
  Les trois y échappaient parce qu'ils vivent hors du périmètre du harnais.
- **Plancher typographique 11 px** : `.status-tag` (présent sur les cartes d'accueil, les vues de
  lecture et les éditeurs) et `.cx-tag` étaient à 10,5 px. Plus rien sous 11 px dans tout le fichier.
- **Six gabarits sans nom accessible** → 0 contrôle anonyme sur 53 (13 avant) : sélecteur de bloc
  suivant, durée d'un cycle (minutes/secondes), pas et valeur de départ d'un compteur, case
  « boucle », boutons de suppression. Les libellés « min », « s », « pas », « départ » étaient des
  `<span>` VOISINS, jamais associés — un lecteur d'écran annonçait « champ numérique, vide » sur la
  durée d'un cycle de réanimation. Reste 39 champs nommés par leur seul `placeholder` (antipattern
  connu : il disparaît à la saisie) — chantier distinct, consigné.
- **Orientation libérée** (`"any"`, décision utilisateur) : le manifeste verrouillait le portrait, si
  bien que l'app INSTALLÉE refusait le paysage — WCAG 1.3.4, et une tablette fixée au chariot
  d'urgence était inutilisable. Mesuré à 844×390 : aucun débordement, et le rail d'orientation
  APPARAÎT, donnant « action + structure de front » — l'idéal ECAM que le portrait n'atteint pas
  à 390 px.

### Découvert en cours de route (hors relevé initial)
- **Une cible tactile sous le seuil DANS la zone de crise** : `.dock-plan` (« Se repérer » /
  « Consulter ») mesurait **38 px** là où la crise exige 44. Le défaut avait échappé au harnais
  parce que son périmètre listait `#crisisDock` — le quai d'ÉTAT — mais pas `#crisisCtrl`, la rangée
  de COMMANDES qui en a été séparée en v4.25.0 : le trou de couverture cachait un défaut réel sur la
  surface la moins permissive de l'app. Corrigé par **halo** (`inset:-3px 0`) et non par
  grossissement : la hauteur de la zone haute est un coût PERMANENT en crise (177 px sur 640 déjà)
  et passer à 44 px l'aurait épaissie de 6 px ; c'est le patron déjà employé pour les contrôles de
  36 px de la barre. Vérifié à 360/390/1280 : cible 44 px, visuel inchangé, rangée toujours à
  59 px, aucun empiètement sur le quai. `#crisisCtrl` entre dans le périmètre du harnais.
- **GARDE-FOU « une classe émise a une règle »** (`scripts/check-classes.mjs`, dans `npm run check`).
  C'est le contrôle qui manquait pour attraper une purge ASYMÉTRIQUE — celle qui retire du CSS mort
  et, dans le même geste, du CSS vivant. Contre-épreuve faite : retirer les cinq règles `.pl-stp` le
  fait échouer. Il a d'ailleurs trouvé seul le défaut `.sv-x`. Trois exemptions documentées, toutes
  des CROCHETS de délégation JS (`.ov-wrap`, `.ov-journal`, `.seg-ic`). Son premier jet portait le
  faux négatif exact qu'il combat — il extrayait les sélecteurs commentaires COMPRIS, or les
  commentaires citent les classes qu'ils expliquent : noté dans le fichier.

510 tests, 22/22 doctrine, 73/73 accessibilité, 135 contrôles d'audit, 9 sondes dédiées.

## [4.32.0] — 2026-07-26
Premier lot d'un audit externe complet (phase 1 : relevé de 138 constats mesurés, 3 réfutés par
contre-audit ; phase 2 : correctifs à comportement INCHANGÉ). Trois défauts critiques éliminés,
chacun reproduit AVANT correction puis vérifié APRÈS par sonde Playwright — plus une demande
utilisateur : l'intitulé d'une décision reste sous les yeux en mode statique sur téléphone.

### Corrigé — trois chemins vers une page blanche
- **« Réparer l'application » pouvait rendre l'app INDISPONIBLE hors ligne.** Sa sonde réseau
  (`fetch('./sw.js')`) était interceptée par le service worker qu'elle s'apprêtait à détruire :
  `cache:'no-store'` pilote le cache HTTP, PAS le Cache API. Dès qu'un appel avait réussi une fois
  en ligne, `sw.js` était dans le cache stale-while-revalidate ; hors ligne la sonde répondait 200,
  la purge s'exécutait, et le rechargement donnait un écran blanc — en intervention, sans réseau.
  Le commentaire du code énonçait exactement ce risque et croyait s'en prémunir. Deux verrous :
  jeton unique par appel (`?_probe=`+Date.now(), clé de cache inédite) et **le worker refuse
  désormais de se mettre lui-même en cache**. Reproduit hors ligne, serveur arrêté : la sonde
  rejette maintenant avec ET sans jeton.
- **Un échec sur pdf.js supprimait TOUT le hors-ligne, silencieusement.** Le précache de 1,73 Mio
  vivait dans le même `waitUntil` que le noyau ; un 503 ou une coupure faisait rejeter
  l'installation entière (mesuré : `{active:false, controller:false}`, app non servie hors ligne),
  et le `.catch(()=>{})` de l'enregistrement rendait la panne invisible. Précache pdf.js
  best-effort ; `addAll` (tout-ou-rien) réservé à `CORE_ASSETS` = index.html + manifest, les
  10 icônes passant en best-effort — un favicon en 404 ne peut plus emporter l'app avec lui.
- **Le bouton « Recharger » de l'écran d'échec de démarrage était MORT.** Seul attribut `onclick=`
  du fichier, il était inerte : dès qu'un hash figure dans `script-src`, les navigateurs ignorent
  `'unsafe-inline'` et un gestionnaire inline exigerait `'unsafe-hashes'` (absent). C'était le
  dernier recours quand IndexedDB ne répond pas — et en PWA installée, il n'y a ni barre d'adresse
  ni bouton de rechargement. Câblé en DOM (jamais en assouplissant la CSP), avec témoin de
  non-régression : un `onclick` inline reste bloqué, violation CSP journalisée.

### Sécurité
- **`zipParse` : les bornes anti-« zip bomb » annoncées n'existaient qu'à moitié.** Rien ne bornait
  la SOMME des tailles, et N entrées de noms distincts pouvaient pointer sur le MÊME en-tête local
  (PoC exécuté : **18 Ko → 256 Mio**). Un `.zip` est le format de partage d'une bibliothèque : il
  circule par mail ou clé USB, sans contrôle. Trois bornes ajoutées — 256 Mo cumulés, offsets
  locaux dédoublonnés, et `inflateBounded` qui **arrête net la décompression** au-delà de la taille
  déclarée (`usize` est lu DANS le fichier : il peut mentir, et la vérification d'après ne servait
  à rien puisque la mémoire était déjà consommée). **Sept tests** ajoutés : la fonction, qui lit
  des octets étrangers, n'était couverte par aucun.

### Ajouté
- **INTITULÉ DE DÉCISION COLLANT en mode statique sous 640 px** (demande utilisateur, `svStickBands`).
  En pile, la bande-question sortait de l'écran pendant qu'on lisait encore ses étapes : **844 px
  de contenu lus sans elle** sur une décision imbriquée à 360×640, contre **0 px côte à côte** —
  le bornage à ce palier est donc celui du problème, pas un réglage esthétique. La bande s'épingle
  sous `--stick-top`, chaque niveau imbriqué se rangeant SOUS son ancêtre.
  **La hauteur n'est PAS forcée** : compacter à une ligne aurait rendu les décalages arithmétiques
  (donc CSS pur) mais TRONQUÉ toute question de plus de deux lignes — or la question EST
  l'information. D'où une mesure, réduite à UNE passe par rendu en fin de `svPaintArrows`
  (lectures groupées puis écritures, ÷ `zoomF()`), là où l'ex-fil d'ancêtres de la vue « Détails »
  recalculait à chaque événement de défilement. Décrochage NATIF (bornage par `.sv-decwrap`),
  z-ordre décroissant (modèle ECL : un niveau se replie DERRIÈRE son ancêtre), plafond 3 niveaux,
  `scroll-margin-top` pour le focus clavier (WCAG 2.4.11). Six contrôles au harnais de doctrine.
- **Garde-fou de fraîcheur des hashs CSP** (`csp-hashes.mjs --check`, dans `npm run check`) : le
  piège « on édite le script inline, on oublie de rejouer csp-hashes, la CSP bloque le seul script
  de l'app » s'était produit trois fois, dont une pendant cette session. Le même contrôle refuse
  tout attribut `on*=`, ce qui rend le correctif ci-dessus non-régressable. Contre-épreuve faite.
- CI : `npm run check` EN ENTIER (elle n'appelait que son premier maillon — `check-colors.mjs`,
  présenté comme « auto-exécutoire », ne tournait dans AUCUNE barrière automatique), `npm ci` au
  lieu de `npm install` (CI reproductible), cache des navigateurs Playwright, et les **11 harnais
  d'audit** en mode non bloquant — la doctrine était jusqu'ici vérifiée seulement si quelqu'un y
  pensait, mais un échec y demande un arbitrage humain, pas un blocage de merge.

### Supprimé — la purge v4.25.0, achevée
`AGENTS.md` affirmait la suppression du Plan « Détails » faite alors qu'elle l'était à moitié : la
pire configuration, puisque celui qui lit la doctrine croit le terrain propre. Étaient restés
**20 classes CSS mortes** (38 lignes, avec 45 lignes de commentaires décrivant en détail un
composant inexistant) : `.pl-cols`, `.pl-decwrap`, `.pl-nd*`, `.pm-views`, `.ovs-tgl`, `.pinchip`,
`.stuck`, `@keyframes pinIn`, `.pd0…pd3`, `.pl-end`, `.pl-offtag`, `.svgv`, `.diff-anchor`,
`.rail-sep`, `.ov-offtag`, `.ov-block.off` — chacune vérifiée à ZÉRO émission dans tout le dépôt
avant retrait. Plus quatre branches de délégation `data-plfold` inatteignables, deux
`querySelector('.pl-nd[data-plgo]')` qui ne pouvaient que renvoyer `null` (leur repli `||` faisait
croire à deux structures possibles), `ovPlanStick()` vide appelée depuis quatre sites, et la démo
`planDemo` de `design/build.mjs` qui PUBLIAIT le composant disparu — sept de ses classes n'ayant
plus aucune règle, le design system le documentait cassé (réécrite sur l'Échelle, à partir du
balisage réellement émis).
- **Un faux positif du harnais, plus grave que le CSS mort** : `audit-doctrine.mjs` cliquait sur
  `.pl-nd`, classe plus jamais émise — le contrôle passait SANS avoir rien cliqué, si bien que
  l'invariant « taper un nœud du plan ne DÉMARRE ni ne COCHE » n'était plus vérifié depuis v4.25.0.
  Corrigé sur `.pl-line[data-plln]`, avec une assertion qui vérifie que le clic a bien eu lieu :
  un contrôle qui ne peut pas échouer ne prouve rien.
- `.condensed` : le repli d'en-tête au défilement était décrit au présent par trois commentaires,
  renvoi « cf. CSS » compris, et la classe était posée par le JS — mais **la règle n'a jamais
  existé dans tout l'historique du dépôt** (vérifié). Ce n'était donc pas une régression mais une
  intention jamais implémentée : le toggle est retiré (aucun changement visuel possible) et la
  hauteur d'en-tête constante est désormais énoncée pour ce qu'elle est.

### Performance
- **`index.html` était téléchargé DEUX FOIS par publication** : `ASSETS` listait `'./'` ET
  `'./index.html'`, soit le même document sous deux URL que le cache HTTP ne peut pas dédupliquer —
  290 Ko en double, pour une entrée JAMAIS servie (le repli de navigation cherche
  `'./index.html'` d'abord). Entrée retirée : une seule copie en cache au lieu de deux.
- **La synchro reconstruisait tout le DOM après VOS PROPRES modifications.** `_pullTable` comptait
  les lignes REÇUES et non APPLIQUÉES : or `_pushTable` pousse l'horodatage LOCAL et, dans `full()`,
  le pull précède le push — la ligne qu'on vient de pousser revient au pull suivant, n'est pas
  appliquée (horodatages égaux) et déclenchait quand même un `render()` complet, focus perdu et
  journal de plusieurs milliers de nœuds réécrit, en pleine session. Le compteur porte désormais
  sur les écritures effectives (`puts`+`dels`).
- Une réponse que le cache REFUSE d'enregistrer (quota, réponse partielle) devenait un ÉCHEC RÉSEAU
  pour la page : `respondWith` recevait la promesse qui contenait le `put`. Découplé, comme le fait
  déjà la branche de navigation — reproduit avec une réponse 206, qui atteint maintenant la page.

### Documentation
- `AGENTS.md` et `README.md` disaient que la CI rejouait `check` (faux pour sa moitié) et
  annonçaient « deux harnais Playwright » là où il y en a onze. Corrigé, avec la leçon de la purge
  incomplète consignée à l'endroit fautif.
- Six blocs de commentaires décrivaient au présent des symboles inexistants (`ovPlanTreeHtml`,
  `ovPlanPin`, `state.ovPlanView`, `#ovPlanD`, `data-plview`, `--pl-stick`) : un commentaire qui
  décrit un mécanisme absent est pire qu'absent — il envoie le lecteur suivant, humain ou IA,
  chercher ce qui n'existe pas.
- `release.sh` synchronise désormais `package-lock.json` (resté figé à 4.3.0 pendant 28 versions,
  alors que `npm ci` installe d'après ce fichier) — édité comme du JSON, jamais par regex.

510 tests (503 + 7), 22/22 contrôles de doctrine (16 avant), 133 contrôles d'audit, 3 sondes
dédiées (critiques 9/9, service worker 6/6, intitulé collant 8/8).

## [4.31.0] — 2026-07-26
Second lot de l'audit design externe (axes couleurs / hiérarchie / priorisation), décisions
utilisateur.

### Ajouté
- **Garde-fou couleurs auto-exécutoire** (`scripts/check-colors.mjs`, dans `npm run check`) :
  un hex n'est admis dans le CSS que dans une déclaration de token (`--…`), où qu'elle vive
  (`:root`, bloc sombre, blocs d'accent) ; seuls les nuanciers littéraux `.acc-sw` sont
  exemptés. La règle d'AGENTS.md n'est plus déclarative. Le garde-fou a d'ailleurs trouvé PLUS
  que les 4 hex de l'audit : des `#fff` de canevas et deux `stroke:#1f5fa6` — copie hex du
  token primaire, la dérive exacte que la règle proscrit.
- **Raccourci clavier vers la recherche** : « / » et Cmd/Ctrl+K focalisent la recherche de
  l'accueil (inerte dans un champ, sous une fenêtre, ou hors accueil).
- **`prefers-contrast: more`** : texte secondaire à l'encre pleine, filets au gris de composant.

### Modifié
- **Tokenisation complète** : `--shadow-primary(-sm)` (les cinq `rgba(23,71,127,…)` éparses),
  `--hover-dk(-hi)` et `--flow-hl-dk` (ex-hex des overrides sombres), `--lb-cap`/`--lb-ink`
  (lightbox), `--paper` (canevas SVG, pages PDF, impression), `--flow-cur` (nœud courant du
  SVG), `--on-primary` sur les remplissages verts/rouges. Zéro changement visuel (valeurs
  identiques), zéro hex hors token.
- **En session vive, la rangée méta de lecture s'efface** (statut, catégorie, validation —
  vus à l'ouverture, ils ne conduisent rien pendant le soin ; même doctrine que l'état de
  stockage retiré des pieds en crise). Sélecteur `:has(#cbTimers)`, écran seulement, saut
  absorbé par `renderKeepAnchor`.
- **« Non protégé » du pied d'accueil : registre NEUTRE** — un état permanent en ambre s'use
  (banner blindness) et émousse l'ambre des états actionnables (« presque plein », PDF
  manquants), qui le gardent. Le test unitaire encode la nouvelle règle.
- **Guide rouge/ambre de l'éditeur de blocs : `<details>` repliable** — ouvert tant qu'on ne
  l'a pas replié, puis le choix persiste (`ac-cg-folded`).
- **Bouton du mode lecteur : « ⤢ Lecteur »** — le glyphe des ouvertures plein écran (même
  grammaire que Se repérer/Consulter) le fait lire comme une surface. Décision d'audit : pas
  d'entrée dans le chrome de crise (12 px libres à 360 px, et une commande qui apparaît selon
  la largeur romprait la constance positionnelle) — les entrées restent la carte du bout et
  le menu ⋯.

503 tests (dont le test du registre de stockage mis à jour), 11 harnais verts.

## [4.30.0] — 2026-07-26
Correctifs P0/P1/P2 de l'audit design externe (axe « conformité aux normes »).

### Corrigé (P0 — mesurés avant/après)
- **WCAG 2.2 § 2.4.11 « Focus Not Obscured » (AA) : NON-CONFORMITÉ levée.** Un Shift+Tab
  remontant déposait l'élément focalisé ENTIÈREMENT sous les couches collantes (en-tête +
  commandes + quai : 238 px mesurés à 360 px en session — dont la case « Alerter, appeler du
  renfort » et l'étape critique « ⚠ RCP immédiate », masquées à 100 %). Le défilement déclenché
  par le focus clavier est celui du navigateur, que `stickBase()` ne voit pas : seul
  `scroll-padding` le pilote — `html{scroll-padding-top:calc(var(--stick-top,64px)+8px)}`
  (la variable existait déjà, mesurée et divisée par le zoom). Corollaire : le
  `scroll-margin-top:130px` forfaitaire de `.rt-panel` (qui s'ADDITIONNE désormais) est ramené
  à 6 px. Vérifié : 0 masquage après correctif ; sonde 2.4.11 ajoutée à `audit-a11y.mjs`
  (73/73).
- **Rangée de commandes `#crisisCtrl` rognée sur les deux largeurs mobiles les plus répandues.**
  Elle exigeait 386 px : « Cons. » perdait 11 px à 375 (iPhone SE/mini) et 26 px à 360 (Android
  standard), sans défilement horizontal — pixels INACCESSIBLES, débordement silencieux dans la
  zone de crise. Compression mesurée sous 400 px (gaps/paddings, recette v4.23.4) : ~346 px à
  360 après, positions constantes conservées. Sondes « sans rognage » à 360/375/390 ajoutées à
  `audit-doctrine.mjs` (15/15).

### Ajouté (P1)
- **Le retour SYSTÈME (Android, geste/bouton) ne sort plus de l'app en pleine session.**
  History API branchée (0 pushState/popstate jusqu'ici) : une entrée sentinelle ré-armée, le
  popstate empruntant le MÊME chemin que l'affordance visible — fenêtre du dessus (✕ ou clic de
  voile : « Terminer la session ? » ferme sur Poursuivre, jamais Terminer), sinon lecteur,
  schéma plein écran, visionneuse, sinon le « ‹ » d'en-tête (pile readStack + garde double-tap
  700 ms héritées). À l'accueil nu, le retour sort réellement (aucun appui mort) ; une
  sentinelle survivant à un rechargement est neutralisée au boot. Vérifié en scénario réel :
  dialogue fermé sans terminer la session, puis retour à la bibliothèque, puis sortie.

### Ajouté (P2)
- **Filet `forced-colors` (Windows High Contrast)** : `.acct-dot`, `.cat-dot` et `.seg-pill`
  gardent leur couleur (`forced-color-adjust:none`) — le reste s'appuie sur « la couleur jamais
  seule ». Filet minimal, à valider sur machine Windows réelle.
- **Dialogue de bienvenue : « Commencer » ancré en bas de la feuille sur mobile** (zone du
  pouce). Sous 780 px la fenêtre est plein écran : le bouton flottait à mi-écran dans ~700 px
  de vide. Carte en colonne flex, action au bord bas ; ordinateur inchangé.

503 tests, 11 harnais verts (a11y 73/73 avec la sonde 2.4.11, doctrine 15/15 avec les sondes
anti-rognage).

## [4.29.10] — 2026-07-26
### Retiré
- **Dossier « bande basse iOS » clos — correctif v4.29.9 confirmé sur appareil.**
  L'instrumentation temporaire est retirée : ligne de diagnostic de la fenêtre Compte
  (`ih/vv/dvh/sab/sat/scr/vvV/sc/ot`) et règle visuelle (`_vvRuler`, calque rouge + trait bleu
  au toucher). Pour ré-instrumenter un jour : tags v4.29.5 à v4.29.9. Restent en place, acquis
  durables du dossier : le verrou de fond par `overflow:hidden` (jamais de `position:fixed` sur
  `body`), les overlays dimensionnés par `--vvh` (visualViewport, resynchronisée en continu),
  et le fond peint sur `html` (ceinture rebond).

503 tests, 11 harnais verts.

## [4.29.9] — 2026-07-26
### Corrigé (bande basse iOS — LE COUPABLE)
- La règle visuelle (v4.29.8) a produit la preuve : sur l'ACCUEIL, `bottom:0` touche le bord
  physique de l'écran — la WebView est saine ; **fenêtre ouverte, il flotte ~60 px au-dessus**.
  Ce qui change entre les deux états : le verrou de fond passait `body` en
  `position:fixed; top:-scrollY` (v4.21.0). Sur iPhone, un body fixé RÉTRÉCIT le rendu des
  éléments fixés qui en descendent (~60 px coupés en bas) sans qu'aucune mesure web ne le voie
  (`ih/vv/dvh/vvV` disaient tous 874) — et cette bande était MASQUÉE depuis v4.23.3 par le fond
  peint sur `html` (le commentaire de l'époque décrivait déjà « une bande vide en bas à
  l'ouverture de n'importe quelle fenêtre » : il masquait le symptôme, le rétrécissement
  restait). **Le verrou change de technique** : `overflow:hidden` sur `html` et `body` (fiable
  depuis iOS 16), qui bloque le défilement de fond sans toucher au repère des fixés ; position
  restaurée au pixel en ceinture ; même périmètre qu'avant (toucher pour les dialogues, tous
  pointeurs pour les feuilles opaques). Vérifié par sonde : couverture 0→874, fond immobile au
  geste, position restaurée, déverrouillage propre (Chromium et WebKit).
- La bascule de la barre d'état vers `default` (entamée en cours d'investigation) est ANNULÉE :
  l'accueil est parfait en `black-translucent`, la meta n'était pas en cause.
- Diag + règle visuelle CONSERVÉS jusqu'à confirmation sur l'appareil ; retrait prévu ensuite.

503 tests, 11 harnais verts.
