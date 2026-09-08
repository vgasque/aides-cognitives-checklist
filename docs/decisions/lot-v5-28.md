# Lot v5.28 — la session se termine là où elle se lit (A336) ; le menu ⋯ ne répète pas le dock (A337) ; la méta d'accueil, un état en mots (A338)

> Fichier normatif, suite de [`lot-v5-27.md`](lot-v5-27.md) (A333-A335). Les numéros A sont des
> adresses : ne jamais renuméroter. Demande de l'auteur (07/09/2026) : « améliorer l'emplacement du
> bouton Terminer la session, sans pouvoir l'activer par erreur », puis « en profiter pour revoir
> le menu ⋯ ». Quatre pistes dessinées sur le chrome réel (canevas « Terminer la session »), une
> retenue ; le menu refait sur la même planche.

## A336 — « Terminer la session… » au pied du volet et du rail, la fenêtre reste la seule porte

**Mesuré avant de dessiner.** En session, « Terminer la session… » était la 14ᵉ et DERNIÈRE rangée
du menu ⋯ — 695 px de menu à 390 px de large. Sûr (aucun tap direct n'arrête rien), mais
introuvable sans le savoir : la doctrine interdisait, à raison, « un bouton Terminer en zone de tap
fréquente » (commentaire d'`applyViewChrome`), et le menu était devenu la seule place restante.

**La règle.** *La session se termine là où elle se lit.* L'état de session vit dans la capsule
« ● SESSION » ; le geste qui la clôt vit au PIED de ce que la capsule ouvre — le volet en étroit
(`.rt-panel`, sous le journal et les réglages son/veille), le rail d'état en large (sous « Son /
Veille »). Dernière rangée, séparée d'un filet (`.rt-sess`), avec un intertitre « Session · depuis
HH:MM » : c'est l'objet qu'on ferme qui s'annonce. Deux gestes délibérés avant la fenêtre en
étroit (ouvrir le volet, le faire défiler jusqu'au pied), aucune proximité avec « Noter l'heure »
ni avec le dock.

**Ce qui ne change pas — et c'est le cœur de la protection.** Le tap OUVRE la fenêtre « Terminer
la session ? » (`endCurrentSession` → `confirmEndSession`), SEULE porte de sortie (SPEC crise § 3,
v4.3.0) : contexte, état de ce qui reste ouvert, conséquences, « Poursuivre » en focus initial.
La rangée porte la mention « confirmation demandée » sous son libellé pour que le tap ne soit pas
craint. Registre : CONTOUR, jamais un aplat (`--critical` sur `--line-strong` en clair,
`--crit-sys` sur la matière système dans le volet) ; glyphe `stop` + mot. Le menu ⋯ garde SA
rangée « Terminer la session… » (porte universelle des actions globales, celle que les
utilisateurs connaissent) : l'emplacement nouveau est le BOUTON, le menu reste l'accès
générique. Deux sites, pas trois : la fin d'algorithme (piste B du canevas) n'a pas été retenue —
une session s'arrête aussi avant la fin, la porte doit être permanente.

**Un seul bouton permanent, pas plusieurs rappels (réponse à l'auteur).** Chaque site de plus est
une surface de tap accidentel de plus, une position de plus à apprendre (constance positionnelle
ECAM), et un point de maintenance de plus (le code compte déjà trois portes vers le même dialogue).
Aucun rappel ne surgit jamais (règle 11) ; un rappel qui DÉDUIRAIT quelque chose de l'état de la
session rouvrirait la qualification § 2.

**Jamais chez l'invité.** `sharedShown()` exclut la rangée : sa porte est « Quitter le partage… ».
Ni en aperçu (`state.previewFrom`). En exercice, le libellé dit « Terminer l'exercice… » comme
le menu.

**Formes refusées** (canevas, à ne pas reproposer sans nouvel élément) : un « Maintenir 0,8 s » à
la place du tap dans la fenêtre (deux verrous en série — réservé si le terrain montrait un tap
accidentel malgré la fenêtre) ; une carte « Et ensuite » sous « Algorithme terminé » ; une phrase
d'explication sous la rangée du volet (« Rien ne s'arrête à ce tap… », retirée à la demande de
l'auteur : la mention « confirmation demandée » suffit).

**Témoins.** Sonde de lot : rangée présente au pied du volet (390) et du rail (1280), 52 px,
tap → `#endSessModal.on` avec le focus sur « Poursuivre ». `check-ids` tient `#rtEndSess`
(émis dans `runtimePanel`, lu dans `bindReadEvents`).

## A337 — le menu ⋯ : tuiles, intertitres, pli « L'aide », et il ne répète pas le dock

**Ce que le menu portait.** Jusqu'à seize rangées en lecture, dans un ordre juste (v4.28.0 :
conduite → cycle de vie → gestion → exports, danger en dernier) mais un VOLUME que rien ne bornait,
et des sous-titres inline qui passaient sur deux ou trois lignes selon le texte (« Partager la
session… — un collègue suit sur son téléphone » : trois lignes à 262 px). Quatre changements, un
seul moteur (`mmRowHtml`/`mmNorm`/`openMoreMenu`), rendu par `setMoreMenu` inchangé pour tous les
autres appelants (accueil, protocoles, éditeurs — une rangée reste une rangée).

1. **En session, le menu ne répète pas le dock.** « Complication » et « Consulter » sont des
   touches CONSTANTES du dock (`#cxKey`, `#refBtn`), toujours visibles en session ; leurs rangées
   sortent du menu dès que la session a démarré. **Ceci remplace, en session, la règle de v4.26.1**
   (« la MÊME entrée au menu ⋯ », conventions-de-code.md « Déclencheur ») : elle datait d'un
   déclencheur posé sur la carte du bloc, que le dock de v5.6 a remplacé — le menu n'avait pas
   suivi. Le dock sait déjà s'effacer quand la proposition devient fausse (une seule complication
   et l'on est dedans, v5.0.0) ; la rangée du menu, elle, restait. AVANT la session, la rangée
   « Complication » reste et en tête : le dock n'y porte que « Exercice » et « Démarrer », le
   menu est la seule porte, et c'est le premier geste de conduite. Le cerclage de la première
   rangée vu aux captures n'était que l'anneau de focus d'un clic SYNTHÉTIQUE (sonde) : mesuré
   au vrai clic et au vrai tap, sur les deux moteurs, il ne s'affiche pas (`:focus-visible`).
2. **Les ouvertures en tuiles** (`{tiles:[…]}` → `.mm-tiles` / `.mm-row.mm-tile`) : Moniteur,
   Se repérer, Schéma (et Consulter hors session) ouvrent une vue et ne font rien d'autre —
   quatre rangées de 44 px tiennent en une rangée de 56, glyphe 18 px + mot. Même classe
   `.mm-row` : clavier (flèches), focus initial et témoins (`querySelectorAll('.mm-row')`)
   inchangés. Le sous-titre d'une tuile vit dans son `aria-label`.
3. **Des intertitres** (`{head:'…'}` → `.mm-head`, 11 px capitales) remplacent les filets entre
   groupes : « Session », « L'aide ». À huit rangées et plus, on balaie par groupe avant de lire.
4. **Le sous-titre passe SOUS le libellé** (`.mm-row.two`, `.mm-tx`, `.mm-sub` une ligne coupée
   au besoin) : hauteur de rangée PRÉVISIBLE, 44 ou 52 px, plus de rangée à trois lignes. Les
   sous-titres sont raccourcis en conséquence (« un collègue suit en direct », « le contenu, pas
   la session », « la session : par « Compte-rendu » »). Largeur 262 → `min(300px, 100vw − 28px)`.
5. **En session, la gestion de l'aide se replie** derrière une rangée « L'aide › — modifier,
   versions, exporter » (`{fold:[…]}`) : le menu se REMPLACE SUR PLACE (même position, même
   largeur, `_moreView`), première rangée = retour (icône `backto`, « retour au menu »), et
   « Modifier »/« Versions » y gardent leur mention « session en cours » (doctrine v4.5 : visible,
   désactivé, mention explicite). Avant la session la gestion reste À PLAT sous l'intertitre
   « L'aide » : c'est là qu'on l'édite. ⚠ Le pli et le retour RE-RENDENT le menu : le bouton tapé
   en sort, et le clic qui remonte au `document` le croirait « hors menu » (fermeture) —
   `stopPropagation` sur ces deux gestes, mesuré (le menu se fermait au retour).
6. **La rangée `danger` devient un pied encadré** (`.mm-end` : 6 px de vide, cadre
   `--critical-bd` à 45 %) ; le `'sep'` qui la précédait tombe dans `mmNorm` — le cadre porte la
   séparation. Vaut aussi pour « Quitter le partage… » du menu de l'invité.
7. **« Recommencer le parcours » n'existe qu'en session** : rien à recommencer avant le premier
   geste.

**Compte.** En session : 14 → 7 rangées (tuiles · Session : Partager, Répéter en exercice,
Recommencer, Historique · L'aide › · Terminer). Avant la session : 13 → 11 (Complication · tuiles ·
Session : Partager, Répéter, Historique · L'aide : Modifier, Versions, Dupliquer, Export .json,
Export PDF). `fitMoreMenu` (hauteur mesurée, v4.73.2) est inchangé et reste nécessaire en grande
police.

**Témoins adaptés.** `audit-complications` : « menu ⋯ en session : AUCUNE rangée Complication —
le dock la porte » (au lieu de « UNE entrée constante ») ; `audit-retour` : l'ordre conduite →
session → gestion → export se lit désormais avant la session, tuiles et intertitres compris.
`audit-exercice`, `audit-doctrine` (menu qui tient dans la zone visible aux zooms) et
`audit-partage` (menu de l'invité) passent sans modification.

**Ouvert, non tranché.** Un export unique « Exporter l'aide… » qui demanderait le format (gardés
à deux : chacun nomme ce qu'il exporte).

## A338 — la méta d'une rangée d'accueil : identité à gauche, UN état en mots à droite

**Demande de l'auteur** : les informations sous les cartes étaient tronquées et « pas toujours au
même endroit » (« Validé » qui paraît ou non, chrono de session entre deux objets). Causes
mesurées : « Validé » ne s'affichait que pour une fiche validée SANS date ; le chrono s'insérait
après la nature et effaçait la date ; le discriminant s'abrégeait (« a… ») sous 400 px. Options
dessinées sur le canevas (D à J), **J retenue**.

**La règle.** À gauche, l'identité dans l'ordre choisi par l'auteur : nature · discriminant ·
● catégorie (· bibliothèque d'origine pour un homonyme). À droite, calé au bord, **un seul état,
en mots, le plus urgent** : En cours 12:04 › Brouillon / À relire › À compléter › Sans date ›
À revérifier 06/2023 › Validée 01/2025. Une taille, une graisse ; aucun glyphe ; l'ambre pour
ce qui attend quelque chose de vous (À relire, À compléter, Sans date, À revérifier). Le mot
« Validé » n'apparaît qu'avec sa date ; sans date, la fiche dit « Sans date ». Le code sort de la
rangée (il reste dans la fiche, la recherche, l'en-tête). Les points séparateurs disparaissent :
un espace de 10 px.

**Alignement.** La ligne s'aligne sur la LIGNE DE BASE (`align-items:baseline` : nature 11 px et
texte 12 px partagent la même base), la pastille se cale au milieu des bas-de-casse
(`vertical-align:middle`). Mesuré : écart de base ≤ 1 px sur toutes les rangées à 320 et 390.

**Ce qui s'abrège, et dans quel ordre.** Nature et état sont durs. La catégorie s'abrège la
première (`flex-shrink:4`, plancher 2,5 em, 1,6 sous 400), le discriminant ensuite et jamais sous
4 em — un discriminant de trente signes existe dans le témoin. **Sous 360 px effectifs**
(`html.zw360`), identité et état ne tiennent pas sur une ligne (268 px pour 208, mesuré) : l'état
passe SOUS l'identité (`.dir-id` enveloppe l'identité, `display:contents` au-dessus de 360), sur
toutes les rangées, et la rangée du livre prend une hauteur unique de 76 px. Mesuré : 320 → toutes
les rangées à 76, identité entière, aucun débordement ; 390 → 60 px, une ligne, écart de base 1 px.
Témoin « ACCUEIL · la rangée a un rythme régulier » : vert à 330, 390, 700, 1000, 1400, 1600.

**Remplace** la règle d'ordre de v5.0.0 (« la queue tombe, donc l'importance d'abord ») : depuis
que les items s'abrègent au lieu de tomber, l'ordre suit la lecture. « À compléter » n'est plus
un bouton sur la rangée (cible de 24 px en fin de ligne impossible sans déborder — mesuré) : ses
points restent en info-bulle et sur la fiche. `dirLiveHtml` purgé, `dirStateHtml` le remplace ;
`paintDirLive` inchangé (le dernier nœud du chrono reste un texte nu).

## A339 — le retrait de profondeur du parcours : un token additif, une seule échelle

**SIGNALÉ À L'USAGE (08/09/2026)** : « parcours dans la page de démarrage d'une aide : indentation
pas la bonne, notamment avec des blocs conditionnels hiérarchisés ». Reproduit et **mesuré avant
d'être touché**, sur une fiche à décision imbriquée (Instable ? → oui → Rythme choquable ? →
choquable / non choquable).

**CONSTAT — L'ARBRE ÉTAIT PLAT, ET PAS SEULEMENT LÀ.** Retraits mesurés (bord gauche du texte, en
px, aperçu de l'écran de démarrage à 390 comme à 1400) :

| rangée | profondeur | avant | attendu |
|---|---|---|---|
| `2 Instable ?` | 0 | 18 | 18 |
| étiquette `OUI` | 1 | 26 | 30 |
| `3 Rythme choquable ?` | 1 | 38 | 30 |
| étiquette `CHOQUABLE` | 2 | **26** | 42 |
| `4 Choc` | 2 | 46 | 42 |

Deux niveaux d'étiquette **au même x** : la hiérarchie qu'elles nomment n'existait plus. Et le
renvoi d'une branche sans rangée (`→ 6 Surveillance`, profondeur 1) se posait à 8 px, c'est-à-dire
**plus à gauche que le tronc**. En SESSION, pire : les onze rangées du rail à `padding-left:10px`,
étiquettes comprises — **aucun retrait du tout**.

**LA CAUSE — UN RACCOURCI `padding` BAT TOUJOURS UN `padding-left` DE PROFONDEUR.** Quatre régimes
écrivaient leurs retraits en ABSOLU (plan 24/32/48, colonne 20/28/40, rail 16/28/40, aperçu à plat
18/32/40) ; or chaque régime pose aussi sa gouttière par un raccourci (`padding:2px 10px`) dont le
sélecteur est plus spécifique que les classes de profondeur — il remet donc `padding-left` à la
gouttière, **où que soient écrites les règles de retrait**. Les trois retraits de l'aperçu à plat
nés en v5.25.0 n'ont ainsi JAMAIS rien fait : ils étaient écrasés par un bloc de la v5.6 posé
soixante lignes plus bas ; le CHANGELOG de v5.25.0 annonce « trois retraits ramenés sur l'échelle
d'espacement » — trois retraits morts. Même mécanisme pour les étiquettes (`.pl-brc`, `.pl-jmp`),
avec en plus une seconde règle de même spécificité posée après elles.

**DÉCISION — LE RETRAIT S'AJOUTE À LA GOUTTIÈRE, IL NE LA REMPLACE PAS.** Une seule échelle
(12/24/32, celle de `.pc-row` dans la vue « Parcours » — pas une échelle de plus), portée par un
token de profondeur commun aux trois objets de la colonne :

```css
.pl-line.d1,.pl-brc.d1,.pl-jmp.d1{--pl-ind:12px}   /* +24, +32 aux niveaux suivants */
```

et chaque régime écrit sa gouttière `calc(<sa valeur> + var(--pl-ind,0px))`. Trois conséquences
qui sont l'essentiel du correctif :

- **un raccourci ne peut plus effacer le retrait** sans effacer aussi la gouttière, c'est-à-dire
  sans se voir immédiatement ;
- **l'alignement « la chip de branche sur le marqueur du bloc enfant » (v5.6) devient structurel**
  au lieu d'être recopié : étiquette et rangée partagent la gouttière du régime et ajoutent le
  même token — à l'épaisseur du filet près (1 px, la rangée est une carte, l'étiquette non), ce que
  le témoin d'`audit-doctrine` tolère déjà. Le triplet `.rail-lad` (16/28/40) qui existait pour
  cela seul est retiré ;
- **douze règles de retrait absolu disparaissent** pour trois déclarations de token.

**MESURÉ APRÈS** : aperçu de démarrage 0/12/24, étiquette et rangée enfant au même x à tous les
niveaux (30 et 30, 42 et 42) ; session 10/22/34, étiquette 1 px à gauche du marqueur ; le renvoi
d'une branche sans rangée suit sa branche. Aucun autre pixel ne bouge : les régimes gardent leurs
gouttières, leurs hauteurs et leurs corps.

**Le témoin ne pouvait pas le voir**, et c'est la leçon : « la chip s'aligne sur le marqueur »
compare l'étiquette à la rangée SUIVANTE — quand tout est à plat, elles sont alignées, et le
contrôle est vert précisément parce que la hiérarchie a disparu. Un alignement ne prouve un retrait
que si l'on mesure aussi que les niveaux DIFFÈRENT.
