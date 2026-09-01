# Lot v5.21 — les catégories retrouvent leur bibliothèque, la main se reprend (A297-A303)

> Six signalements d'usage du 01/09/2026, plus un vestige mis au jour en les instruisant. Trois
> d'entre eux ont la MÊME cause de fond : la refonte d'accueil v5.18 a remplacé `state.scope` par
> `state.homeLib` sans que tous ses lecteurs suivent. Tous mesurés sur l'app SERVIE, au vrai
> trajet, avant tout correctif.

## A297 — « Gérer les catégories » n'affichait plus rien (v5.21.0)

Signalé : « Cliquer sur *Gérer les catégories* n'affiche plus aucune catégorie dans la sidebar
(pas sur téléphone). » Deux causes empilées, la seconde cachée sous la première.

**(1) Une référence de fonction nue passée à un gestionnaire d'évènement.**
`b.querySelectorAll('[data-catmgr]').forEach(x => x.onclick = openCatMgr)` — or `openCatMgr(lib)`
prend une **bibliothèque** depuis A159 (surcharge de périmètre pour l'atelier d'import). Le
gestionnaire lui passait donc l'**ÉVÈNEMENT de clic** comme périmètre : `_catScopeForce` valait un
`MouseEvent`, `catsForScope(scope)` comparait `catScope(c) === (event || null)` et ne trouvait
jamais rien. Mesuré à la sonde : `activeCatScope()` → `{isTrusted:false}`, zéro rangée, en-tête
« Catégories de la bibliothèque **‹vide›** (partagées avec ses membres) ».

Deux sites fautifs (`paintFiltSheet`, `bindHomeChrome`) ; un troisième était déjà correct
(`paintMgrSheet`, qui enveloppe). La porte du **pouce** (`#mgrBtn` → `openHomeMgr`) appelle sans
argument — d'où le « pas sur téléphone », qui n'était pas une différence de largeur mais une
différence de **point d'entrée**.

⚠ RÈGLE : jamais `onclick = f` en référence nue quand `f` prend un paramètre optionnel. Le
gestionnaire d'évènement n'est pas un appel à zéro argument.

**(2) Le périmètre lui-même venait d'un champ mort.** `activeCatScope()` retombait sur
`state.scope`, que **plus rien n'écrit à l'accueil depuis la v5.18** : la colonne gauche filtre par
`state.homeLib` (cf. `homeLibOn`). Le gestionnaire montrait donc toujours le Perso, quelle que soit
la bibliothèque affichée — la première cause masquait la seconde, et corriger l'une sans l'autre
aurait produit un vert menteur.

## A298 — le gestionnaire de catégories montre une SECTION PAR BIBLIOTHÈQUE (v5.21.0)

Décision de l'auteur, en toutes lettres : « comment gérer les catégories lorsqu'on est sur le
filtre *Toutes* des bibliothèques pour distinguer les catégories en fonction de leur bibliothèque,
car c'est un vrai bug ».

`activeCatScope()` suit désormais le filtre de la colonne (`state.homeLib`), et une valeur
supplémentaire — `CAT_ALL` (`'*'`) — dit « Toutes ». Le gestionnaire liste alors **un périmètre par
section**, sous son propre intitulé (Perso d'abord, puis chaque bibliothèque **administrable**),
chacune avec :

- **sa palette** et ses rangées ;
- **ses comptes bornés à elle** — `catCount(id, scope)` ajoute le filtre de bibliothèque, parce que
  deux bibliothèques peuvent porter le même id de catégorie (doctrine « un id se résout dans sa
  bibliothèque ») ;
- **ses cibles de déplacement bornées à elle** au moment de supprimer une catégorie non vide :
  proposer une catégorie du Perso pour des fiches de bibliothèque produirait une référence morte ;
- une **clé de suppression portée à `scope|id`** (`catDelId`), sinon deux rangées homonymes de
  périmètres différents ouvriraient la même confirmation ;
- **son propre « ＋ Ajouter »** (`data-cnew` / `data-cadd` portant le périmètre), plutôt qu'un
  sélecteur de destination — la rangée d'ajout sous sa section ne peut pas se tromper de cible.

Le périmètre d'une rangée voyage en `data-cscope`, **jamais en variable de fermeture** : une
section n'écrit que dans SA bibliothèque, et `saveCats(scp)` reçoit toujours un périmètre explicite.

⚠ `CAT_ALL` ne doit JAMAIS atteindre `saveCats`, qui en ferait une clé de synchro. Tous les
appelants passent un périmètre réel ; c'est la seule contrainte que le code ne dit pas tout seul.

Les bibliothèques en **lecture seule** sont exclues des sections : on ne liste que ce qui SE GÈRE
(règle 14, même raisonnement qu'à la feuille « Gérer » d'A287).

## A299 — une seule rangée par NOM dans la colonne gauche (v5.21.0)

Le filtre de catégorie compare **par nom** à travers l'union depuis la v5.18 (`catFilterOn` →
`_catFiltName`). Or la colonne listait `categories` brut : deux homonymes de bibliothèques
différentes produisaient **deux rangées qui filtraient exactement la même chose**, ne différant que
par la couleur de leur pastille. Un filtre, une rangée : elles fusionnent, le compte est cumulé, et
le cran se lit sur le NOM comme le filtre lui-même.

Reste la question posée par l'auteur : « deux catégories d'un même texte peuvent avoir une couleur
différente ». Elles le peuvent, et la rangée ne doit en renier aucune — quand les couleurs
divergent, **la pastille les montre TOUTES** en parts égales (`.cat-multi`, dégradé linéaire
construit sur des valeurs déjà passées par `safeColor`). Le réglage par bibliothèque, lui, vit dans
le gestionnaire (A298), seul endroit où l'on agit sur une catégorie précise.

**Deux pistes écartées à la décision** : une seule couleur (elle mentirait sur les autres) ; un
filtre par catégorie RÉELLE, id + bibliothèque (il reviendrait sur la v5.18, où « Urgences »
désigne délibérément les urgences de toutes les bibliothèques).

## A300 — le survol effaçait la jauge de « Maintenir » (v5.21.0)

Signalé : « avec le nouveau design la barre de progression du bouton *Maintenir* pour
minuteurs/chronomètres ne s'affiche plus ».

`.rt-dock .tm-btn:hover { background: var(--sys-2) }` vaut **(0,3,0)** et bat
`.tm-reset.holding` **(0,2,0)** : son raccourci `background:` remet `background-image` à **none**,
donc la jauge disparaît entièrement. C'est mot pour mot le piège déjà nommé au bloc de survol
nocturne (`:not(.holding)`, ~ligne 670), réintroduit par les règles du volet sombre de la v5.6.

⚠ **POURQUOI TROIS SONDES SUCCESSIVES L'ONT MANQUÉ.** Un `dispatchEvent(new PointerEvent(
'pointerdown'))` **ne pose pas l'état `:hover`** : la jauge s'y mesurait parfaitement (`background-
size` de 0 % à 100 %, `background-image` présent), sur les deux moteurs, en clair comme en sombre.
Le défaut n'apparaît qu'au **vrai survol** — `page.mouse.move()` puis `mouse.down()` — et, sur
iPhone, le survol reste **collé après le toucher**, donc l'utilisateur le rencontrait à chaque
appui. RÈGLE : toute sonde qui mesure un état de pression sur un contrôle doit AMENER LE POINTEUR,
pas seulement émettre l'évènement.

Correctif : `:not(.holding)` sur la règle de survol. Vérifié au vrai survol, Chromium et WebKit :
`background-image: none` avant, jauge à 47 % après.

## A301 — l'anneau nocturne suit la partie qui se déroule (v5.21.0)

Signalé : « en mode crise la barre flottante avec les minuteurs qui se déroule : bordure de la
barre ne suit pas la partie qui se déroule, ça fait bizarre ».

La capsule et le volet forment **un objet à deux étages** — mêmes bords à 14 px, volet ancré au bas
de la capsule, coins bas transférés (`body:has(.rt-dock) #cbTimers`). Mais le périmètre nocturne
`--sys-edge` était posé sur `#cbTimers` **seul** ; le volet, dont l'ombre est `none` la nuit (« la
nuit ne projette pas, elle borde », A222/v5.15), n'avait donc **aucun bord**. Mesuré :
`box-shadow` = `inset 0 0 0 1px #7c879a` sur la capsule, `none` sur le volet, géométrie pourtant
parfaitement continue (14 → 361, jointure exacte à 119 px).

**TROIS côtés seulement** (gauche, droite, bas) : le haut est la JOINTURE, où la capsule pose déjà
son propre trait — un anneau complet doublerait la ligne à 2 px. Inerte le jour, où `--sys-edge`
est transparent et où le volet garde son élévation.

## A302 — l'hôte qui coupe ne gèle plus celui qui CONDUIT (v5.21.0)

Signalé : « si j'ai donné la main et que l'hôte qui a créé la session coupe le partage, la session
est aussi coupée pour celui à qui on a proposé la main… ». L'auteur a demandé, avant tout
correctif, ce que « donner la main » fait RÉELLEMENT. La réponse, mesurée, est la clé du lot :

**Ce que la passation transfère, et ce qu'elle ne transfère pas.**

1. C'est une offre en trois temps (AC 61-115) : `offerLead` n'écrit aucun rôle, il émet
   `handoff{to}` ; l'invité voit « Prendre la main » ; `grantLead` inscrit alors hôte → `scribe`,
   invité → `lead`.
2. Le rôle ne borne **que le fil** : `shareCan` / `share_kind_allowed` réservent au lead `uncheck`,
   `timer_reset`, `session_start`, `end`. Cocher, naviguer, armer ou arrêter un minuteur, compteurs,
   repères, complications restent ouverts aux deux.
3. **L'hôte n'est jamais bridé sur son propre écran** : `bindLeadGuard` sort sur `mode !== 'guest'`.
   C'est écrit dans `revoke` — « il conduit sa propre session quoi qu'il arrive ». Il continue de
   décocher et de remettre un minuteur à zéro, et cela s'applique chez lui.
4. …mais ces gestes-là **ne partent plus** (`canWrite` refuse sur le rôle `scribe`) : le miroir se
   déclare périmé et resynchronise. Un « remettre à zéro » de l'hôte après passation n'atteint donc
   jamais l'invité.
5. **Les droits de PROPRIÉTÉ ne se transfèrent pas du tout** : arrêter (`endShare`), couper
   (`revoke`), rouvrir un code (`admit`), réécrire un rôle (`setRole`) passent par la RLS
   `owner = auth.uid()`, jamais par le rôle.

**La passation n'est donc pas définitive dans le modèle — mais elle était à sens unique dans
l'interface** : `_reclaimLead` existait **sans aucune porte**, et le seul moyen de reprendre la
conduite était de COUPER la personne. Trois réponses.

**(1) Le conducteur ne gèle plus.** `Share.soloLead` se décide dans `_cycle`, **à la transition de
statut**, sur le rôle que le serveur vient de rapporter — après, on ne sonde plus. Le lien meurt, la
conduite continue : même machinerie que « Continuer seul » (rien ne part, `canWrite` exige
`status === 'active'`), écran pleinement opérable, `body.share-dead` non posé, `MUTE_SEL` non
appliqué. Le bandeau le DIT et n'offre **pas** « Rejoindre à nouveau », qui raserait le Runtime
(`rejoinShare`) en pleine conduite. `revoked` est **EXCLU** : couper rend d'abord la main
(`_reclaimLead`), et c'est une décision qui concerne la personne. Comme après un détachement, rien
n'est archivé chez l'invité (`started` reste faux, doctrine « l'invité ne dépose rien »).

**(2) Le dialogue d'arrêt cesse de mentir.** « Les participants ne suivront plus la session. Votre
session, elle, continue » était écrit en supposant que l'hôte conduit. Quand il a donné la main,
c'est l'écran de l'AUTRE qui est en jeu : le texte le **nomme** et rappelle la porte non
destructrice.

**(3) « Reprendre la main »** dans la feuille de partage, là où « Donner la main » n'a plus de sens.
Un UPDATE de rôle, rien d'autre ne bouge, la personne reste dans la session. Et perdre la main
s'annonce chez l'invité (`announce`), symétrique de `takeLead` — sinon les gestes réservés se
ferment sans cause visible.

**Compromis assumé** : la rangée du conducteur porte désormais deux boutons, donc un nom long y
tronque comme il tronquait déjà sur les rangées de scribe. Deux mises en page mesurées et
ÉCARTÉES — `flex-wrap` avec base de 140 px, puis plancher de 96 px : les deux font passer TOUTES
les rangées à deux ou trois lignes, y compris à 430 px.

## A303 — ce qu'on déplace ne disparaît plus de l'écran (v5.21.0)

Vestige mis au jour en instruisant A297. « La destination devient la vue : sinon les éléments
déplacés *disparaîtraient* de l'écran » — le commentaire était juste, la ligne ne l'était plus :
elle écrivait `state.scope`, que l'accueil ne lit plus depuis la v5.18. **No-op, et le défaut
qu'elle prévenait était revenu.**

Mesuré au vrai trajet (colonne gauche → « Sélectionner » → cocher → « Bibliothèque… » →
destination → confirmer), deux bibliothèques administrables : filtre posé sur A, déplacement d'une
sélection vers B → **la liste tombe de deux rangées à ZÉRO**, `state.homeLib` reste `lib-a`,
`state.scope` passe à `lib-b` que personne ne lit. Les fiches avaient bien migré.

Trois branches, parce que la bonne réponse n'est pas la même :

- **un filtre est posé** → il SUIT la destination ;
- **« Toutes »** (`homeLib` null) → on ne pose **aucun** filtre : rien ne disparaît (la liste est
  l'union), et l'utilisateur n'a rien demandé ;
- **destination Perso** → le filtre suit vers Perso (`''`), jamais vers « Toutes » (`null`) — dans
  la convention `homeLib`, ce sont deux crans distincts.

`state.cat = ''` reste **inconditionnel** : cette moitié-là n'était pas morte. Le déplacement
invalide la catégorie (`e.o.category = ''` quand la destination n'a pas d'équivalent par nom), donc
sans elle les éléments disparaîtraient par le filtre de CATÉGORIE, y compris sur « Toutes ».

⚠ **CE QUI RESTE OUVERT, ET QUI EST MESURÉ.** `state.scope` vaut **toujours `null` à l'accueil**, et
six autres lecteurs s'en remettent encore à lui :

| Lecteur | Mesuré | Verdict |
|---|---|---|
| `selTogHtml()` | bibliothèque en lecture seule filtrée → `canEditScope(null)` = **true**, « Sélectionner » présent | commande morte |
| `#hdrNew` (`applyViewChrome`) | même filtre → « Créer » visible | commande morte |
| `newFiche` / `newProtocol` | filtre sur une bibliothèque admin → brouillon créé **au Perso** ; garde « lecture seule » inopérante | pas de fuite de droits (tout atterrit au Perso), mais le bouton ne respecte pas le contexte |
| `impLibDefaut()` | filtre posé → `null` | l'atelier d'import propose Perso |
| `cran()` du renvoi croisé | ne compte que le Perso alors que la liste est l'union | sous-compte |
| `activeCatScope()` (repli) | corrigé à l'accueil et en édition de fiche ; retombe encore sur `state.scope` en édition de **protocole** | devrait lire `state.pdraft.library` |

Et la ligne « Cette bibliothèque partagée est vide » est **doublement morte** : jamais atteinte, et
inatteignable — une bibliothèque vide n'a pas de rangée dans la colonne (`bibGroups` ne liste que
les groupes ayant des items), on ne peut donc pas filtrer dessus.

## Les garde-fous du lot, et pourquoi ils tiennent

Deux sections neuves, chacune **vérifiée capable d'échouer** (défaut réintroduit, rouge exactement
sur les assertions visées, fichier restauré à l'octet — sha256 comparé) :

- `audit-partage` · « l'hôte coupe, le CONDUCTEUR poursuit » — 11 contrôles, passant par le VRAI
  chemin (la bascule se décide dans `_cycle`, la poser à la main ne mesurerait rien), avec trois
  témoins de discrimination : scribe → gèle, coupé → gèle, promu → poursuit. Sa voisine « couper
  celui qui conduit rend la main » est étendue à la feuille (rangée, dialogue, reprise sans
  coupure) plutôt que dupliquée — même décor, une seule manœuvre, une seule section.
- `audit-doctrine` · « ce qu'on déplace ne disparaît pas de l'écran » — 9 contrôles, les trois
  branches ci-dessus.

⚠ **UN DIXIÈME CONTRÔLE EST NÉ NON DISCRIMINANT**, et c'est la leçon v4.31.1 rejouée : « l'ancien
`state.scope` n'est plus écrit par ce chemin » restait VERT sous le défaut, parce qu'il lisait en
fin de parcours, où le dernier déplacement visait le Perso et où l'ancien code écrivait `null` de
toute façon. Déplacé au point où il mesure. **Un contrôle aveugle au défaut qu'il prétend couvrir
ne vaut rien** — il faut le vérifier rouge, pas seulement l'écrire.

Bilan : partage 331 → 349 contrôles, doctrine 92 → 93 sections.
