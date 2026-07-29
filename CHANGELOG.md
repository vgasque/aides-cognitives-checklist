# Journal des modifications

## [4.68.0] — 2026-07-29
### Le dessin des box et des boutons de l'éditeur, d'après la maquette

- **L'en-tête de bloc porte la pastille numérotée de la lecture** — ronde et bleue, losange ambre
  pour une décision — au lieu d'une pilule « ÉTAPES ». C'est le même repère qu'en crise.
- **Le chapeau porte son compte « n/4 »**, et la porte dit ce qui **reste** :
  « ＋ Rappel (1 restant) ». Un plafond qu'on voit approcher informe ; il n'a pas à crier avant
  d'être franchi — le garde-fou ambre ne parle qu'**au-delà** de 4.
- **Le ✕ s'écarte des réglages.** Un geste destructeur ne se met jamais au contact d'un
  interrupteur d'état : sinon le pouce corrige et supprime du même geste.
- **La poignée ⠿ vit à droite de la ligne et reste visible au repos** : c'est une affordance de
  réordonnancement, elle ne se découvre pas au tap.
- **Le champ actif porte la bordure d'accent.** En thème sombre, `--input-bg` seul est trop proche
  du fond de la rangée pour se voir — c'est le trait qui dit « ici on écrit ».

### La remarque vit sous la ligne qu'elle vise
Le volet du pied dit **combien** il reste à relire ; il ne dit pas **où** pendant qu'on écrit.
`stepNote` (pure, testée) rend la remarque qui concerne une étape, affichée sous elle et
seulement en édition — au repos, la page reste du texte.

Corollaire appliqué : `stepGuardTxt(steps,'bloc')` ne rend plus que la remarque de **bloc** (son
nombre d'étapes). Afficher la même remarque d'étape à deux endroits pour un seul défaut, c'était
du bruit — et cela se voyait à l'écran.

Vérifié : **801 tests × 2 moteurs** (+7), a11y 301/301, doctrine 112/112. Rien à rejouer côté
serveur.

## [4.67.0] — 2026-07-29
### L'éditeur d'étapes en quatre états — au repos, aucun chrome

Deux tentatives ont échoué avant celle-ci, et il faut savoir pourquoi : la v4.64 mettait les
outils sous le champ au focus (43 → 123 px, et ils poussaient le contenu à l'instant où le doigt
y entrait) ; la v4.66 réservait leur espace en permanence (plus rien ne bougeait, mais le champ
tombait à 173 px et chaque étape gardait son cadre — l'écran restait un formulaire dense).

La maquette retenue règle le problème **en amont**.

**1 · Repos — aucun chrome.** La ligne est du **texte** : ni bordure, ni fond, ni outils.
Exactement ce que le soignant lira. **38 px de hauteur, champ à 295 px** (contre 173). La rangée
entière est la cible : un tap n'importe où passe en édition.

**2 · Édition.** Le texte devient champ (≥ 16 px, donc pas de zoom iOS), curseur en place, et les
outils apparaissent **sous la ligne**. Une seule étape est en édition à la fois : la page au repos
reste aussi calme que la fiche en lecture. L'`<input>` reste dans le DOM en permanence — il porte
la valeur et l'auto-enregistrement ; c'est son **habillage** qui change, donc rien à re-rendre au
tap et rien qui saute.

**3 · ⏎ = item suivant.** Une checklist **se dicte** : la saisie en rafale ne doit jamais passer
par un menu. Entrée crée l'étape **juste en dessous**, vide, focus dedans, en étape **normale** —
les registres ⚠ et △ se posent après, par l'interrupteur, parce qu'on écrit d'abord et qu'on
qualifie ensuite. Et **un champ quitté vide fait disparaître l'item, sans dialogue** : jamais
pendant la frappe (effacer pour reformuler supprimerait la ligne sous le doigt), jamais la
dernière (un bloc garde une ligne où écrire), jamais pendant un déplacement.

**4 · Un « + » = une portée.** La palette ne vit qu'**entre** les blocs et ne liste que les objets
de niveau bloc — « Étape » n'y figure pas : dans un bloc, « + Étape » et ⏎ s'en chargent. La
position du bouton choisit la portée **à la place de l'auteur**, qui n'a jamais à se demander où
va atterrir ce qu'il ajoute. Chaque type dit sa **conséquence** en deux mots (« 2 branches »,
« durée + libellé »), pas sa définition.

Vérifié par une sonde dédiée sur **Chromium et WebKit** : repos sans cadre ni outils avec poignée
visible, outils sous la ligne et champ ≥ 16 px en édition, ⏎ qui crée une étape vide avec le focus
dedans, disparition au blur, palette sans « Étape ». Plus 794 tests × 2 moteurs, a11y 301/301,
doctrine 112/112. Rien à rejouer côté serveur.

## [4.66.0] — 2026-07-29
### Deux défauts d'usage de l'éditeur sur smartphone — signalés, puis mesurés

### La rangée d'outils poussait le contenu
Signalé : « c'est compliqué sur smartphone, la bande attention/déplacer/supprimer qui apparaît
prend beaucoup de place ». Mesuré : la rangée faisait passer l'étape de **43 à 123 px** — et
surtout elle **poussait le contenu à l'instant précis où le doigt entrait dans le champ**, ce que
la doctrine du projet interdit (« rien ne bouge sous le doigt »).

Les outils se **révèlent** désormais au lieu d'apparaître : `visibility` et non `display`. Leur
espace est réservé en permanence, donc la hauteur de la rangée et la largeur du champ ne changent
**jamais** — seule l'encre paraît. C'est le précédent des pilules d'option du mode statique,
masquées en `visibility:hidden` précisément pour que l'espace cesse d'osciller. `pointer-events`
suit la visibilité : un bouton invisible ne capte pas le tap voisin.

Les pixels rendus au champ sous 400 px viennent du **cadre** (rembourrage du bloc 14 → 9 px, case
26 → 22 px), jamais d'une cible tactile — les boutons gardent 32 px. Le champ passe de 161 à
**173 px**, et la rangée reste à **43 px, focus ou non**.

### Le bouton « déplacer » faisait sauter l'écran de 326 px
Signalé aussi. Deux causes cumulées : le re-rendu insère les interstices de dépôt **au-dessus** du
point regardé, et un `scrollIntoView` visait ensuite le bandeau « en main » — qui est *sticky*,
donc déjà visible sans qu'on défile.

Prendre et poser passent maintenant par **`keepAnchor`**, la mécanique d'ancrage du projet :
l'objet pris ne bouge plus que de **0,7 px**, le bloc receveur de **0,6 px**. Les cibles
apparaissent autour de ce que l'auteur regarde, au lieu de l'emporter ailleurs.

Vérifié : 794 tests × 2 moteurs, a11y 301/301, doctrine 112/112, aucun débordement horizontal à
390 px. Rien à rejouer côté serveur.

## [4.65.0] — 2026-07-29
### La porte « + » — une seule, et chaque type se présente

Six boutons d'ajout vivaient dispersés dans trois sections de l'éditeur : « + Bloc d'étapes »,
« + Décision (si… alors…) », « + Chronomètre », « + Minuteur (cycle) », « + Ajouter un compteur »,
« ＋ Complication ». Pour savoir ce qu'on **pouvait** ajouter, il fallait faire défiler la page
entière — et rien ne disait à quoi chaque type sert.

Une seule porte pointillée les rassemble : **« ＋ Étape · décision · minuteur… »**. Elle ouvre une
palette où **chaque type se présente** — le glyphe, le nom, et une ligne dans les mots du
soignant :

- **Bloc d'étapes** — une suite d'actions à cocher, l'unité de base d'une checklist
- **Décision (si… alors…)** — une question et ses branches : « Choquable ? » → chaque réponse mène
  à son bloc
- **Minuteur à cycles** — un temps qui se relance et compte les tours (ex. RCP 2 min)
- **Chronomètre** — un temps qui monte, sans échéance
- **Compteur** — ce qu'on compte pendant le soin : chocs, doses d'adrénaline…
- **Complication** — un événement qui peut survenir à tout moment, le retour est prévu

**C'est là que les registres s'apprennent, avant la crise.** Les explications sont écrites au
moment où l'auteur choisit, pas dans un guide qu'on replie une fois pour toutes.

La fenêtre passe par le gestionnaire de modales commun (Échap, clic de voile, piège de focus,
retour système d'Android) et se ferme à l'insertion, l'éditeur se re-rendant aussitôt — sinon la
porte demanderait un geste pour ouvrir et un autre pour retrouver ce qu'elle vient de créer. Les
six gestes sont intacts : on a supprimé les **portes**, pas les capacités.

**K5 est reporté** sur décision de l'utilisateur (« l'enregistrement se dit, ne se demande pas » :
auto-enregistrement horodaté dans la barre, « ▶ Essayer » promu bouton rempli unique). Il déplace
l'action primaire de l'écran, et l'éditeur s'auto-enregistre déjà sans le dire — c'est la promesse
affichée qui changerait, pas la mécanique.

Vérifié : 794 tests × 2 moteurs, a11y 301/301, doctrine 112/112. Rien à rejouer côté serveur.

## [4.64.0] — 2026-07-29
### K1 — on édite dans la grammaire de lecture

L'éditeur était un formulaire : champs empilés d'un côté, aperçu de l'autre. L'auteur composait à
l'aveugle et ne découvrait le rendu qu'en basculant. Désormais **le chapeau EST le cadre rouge**,
**un bloc EST sa carte**, **une étape EST sa rangée** — les champs prennent la place exacte du
texte final, aux mêmes corps et aux mêmes registres. Ce que l'auteur voit est ce que le soignant
verra : le garde-fou le plus puissant est visuel.

- Le bloc d'édition reprend l'anatomie de la carte de lecture : mêmes bordures, liseré gauche de
  4 px, même rayon — **ambre pour une décision**, neutre pour un bloc d'étapes, comme en lecture.
- Une étape ⚠ porte sa boîte rouge, une étape △ sa boîte ambre, avec la case à gauche.
- **Ce qui n'est pas copié, délibérément** : la case reste un **glyphe inerte**. Un éditeur où
  l'on pourrait cocher ferait croire qu'on prépare un état ; on rédige une aide, on ne la déroule
  pas.

### K3 — les outils suivent le focus
Trois boutons par étape multipliés par huit étapes, cela faisait vingt-quatre cibles pour un écran
où l'on écrit **une ligne à la fois**. La rangée ⚠ ✕ ⠿ n'existe désormais que sur l'étape
**active** — atteignable au clavier (`:focus-within` s'ouvre dès que la tabulation entre dans le
champ), et le survol est neutralisé sur pointeur grossier, où l'étape active est celle où l'on
écrit. Mesuré : **43 px au repos, 123 px active**.

### MK5-b — réordonner par « prendre / poser », deux taps, zéro maintien
Un tap sur la poignée ⠿ **soulève** l'objet et réécrit la page en cibles pleine largeur ≥ 44 px ;
un tap sur un interstice le **pose**. Pas de maintien ni de glisser — c'est le point de
défaillance du drag au doigt (gants, une seule main, véhicule qui bouge). Les boutons ↑ ↓
deviennent redondants et quittent la rangée d'outils.

- L'objet « en main » n'est **jamais persisté** : c'est un geste, pas un état du brouillon.
- **Échap ou ✕ le reposent** là où il était : un geste interrompu ne déplace rien.
- **Garde-fou QRH** : sortir une étape ⚠ de son bloc change son contexte — la cible s'annonce
  alors en △ **avant** le dépôt, sans jamais l'interdire. L'auteur reste l'expert de sa fiche.

### Deux pièges
- Les étapes d'un bloc vivent **hors** de `.list-edit` : leur rangée n'avait donc aucune règle de
  flex, et les trois objets (case, champ, outils) s'empilaient dès l'ajout de la case.
- La bibliothèque est **vide au premier démarrage** : une sonde d'éditeur doit passer par
  « Commencer » puis « Ajouter les fiches d'exemple », comme les autres harnais — sans quoi elle
  mesure une page sans fiche et conclut à tort que tout échoue.

Vérifié : 794 tests × 2 moteurs, a11y 301/301, doctrine 112/112, et une sonde dédiée sur
**Chromium et WebKit** (outils au focus, 12 cibles ≥ 44 px, garde-fou QRH, déplacement effectif,
Échap sans effet de bord, cadre rouge du chapeau). Rien à rejouer côté serveur.

## [4.63.0] — 2026-07-29
### Phase K — la doctrine relit par-dessus l'épaule, et la page revient au contenu clinique

L'éditeur est l'envers de la crise : on y travaille au calme, et chaque minute investie là achète
des secondes ici. Deux changements, sur l'éditeur existant.

### K2 — la relecture doctrinale, en une seule grammaire
Les garde-fous existaient déjà (chapeau à 4 rappels, bloc à 7 étapes, challenge trop long, étape
qui cumule des actions) — mais **dispersés**, chacun sous son champ. L'auteur ne savait pas, en
fermant l'éditeur, ce qu'il laissait derrière lui.

`reviewNotes(f)` (pure, testée) les rassemble : chaque remarque **nomme sa cible** et l'action
proposée. Un volet « △ Relecture · n » en pied de page les liste et **ancre** vers la ligne
concernée, qui clignote une fois — sans voler le curseur : l'auteur vient de lire le bilan, c'est
à lui de choisir ce qu'il corrige.

**Jamais bloquant, jamais rouge**, et le volet le dit en toutes lettres : « aucune de ces
remarques n'empêche d'enregistrer — c'est vous qui connaissez votre service ». L'ambre est le
registre du « c'est là qu'on se trompe » ; le rouge reste à ce qui tue. Le volet **disparaît**
quand il n'y a rien à dire : un panneau affichant « 0 remarque » serait du bruit permanent pour
une information qu'on lit une fois.

### K4 — « Identité » se replie
Titre, catégorie, bibliothèque, code, date de validation et état occupaient tout le haut de
l'éditeur : on traversait six champs administratifs avant d'atteindre ce qu'on vient écrire. Ils
vivent maintenant dans un dépliant dont l'en-tête **porte déjà le titre et le code** — replié, il
n'escamote donc rien qu'on vérifie d'un coup d'œil.

**Ouvert d'office en création, replié en modification** : sur une fiche neuve, le titre est le
premier geste ; sur une fiche existante, il est déjà écrit et ce qu'on vient corriger est le
contenu. La distinction se fait sur le **titre vide**, pas sur l'existence de la fiche — dupliquer
donne un titre, repartir de zéro n'en donne pas. Le statut éditorial reste **en plus** dans la
barre : c'est un état, il ne se replie pas.

### Piège mesuré
`scrollIntoView({behavior:'smooth'})` **ne défilait pas du tout** sur 6 400 px d'écart — et aucun
défilement de l'application n'est animé. L'ancrage est direct.

### Non engagé, et pourquoi
K1 (éditer dans la grammaire de lecture) et K5 (« ▶ Essayer » comme bouton rempli unique) changent
le **geste** d'édition ; K10 (raccourcis à la frappe, import/export markdown structuré) ouvre un
parseur ; K6 (le discriminant en champ séparé) ajoute un **champ modèle**, donc touche `migrate`,
l'export v3 et l'affichage des titres partout. Chacun se décide séparément.

Vérifié : **794 tests × 2 moteurs** (+9), a11y 301/301, doctrine 112/112, lecteur 14/14,
consulter 8/8. Rien à rejouer côté serveur.

## [4.62.0] — 2026-07-29
### I4 — une seule grammaire de progression : guidé, journal et lecteur ne font plus qu'une

Le chantier structurant de l'audit. Guidé, journal et mode lecteur n'étaient pas trois vues d'une
même chose : c'étaient **trois écritures** de la même chose.

### Pourquoi — c'est doctrinal
- **ECAM.** L'affichage d'Airbus repose sur UN format unique pour tous les états de l'avion : le
  pilote n'apprend pas trois écrans, il apprend UNE grammaire (position fixe, registres,
  priorités) qui se décline. Trois surfaces de progression, c'est l'anti-ECAM — trois
  cartographies mentales pour la même information. Harmonisées, celui qui a appris l'écran hôte
  **sait déjà** lire l'écran invité.
- **QRH.** Un manuel n'a qu'une mise en page de checklist, quel que soit le lecteur : celui qui
  lit et celui qui exécute regardent le **même document**, et c'est ce qui permet le cross-check à
  voix haute. Si le lecteur voit une autre structure que l'hôte, « bloc 2, ligne 2 » ne désigne
  plus la même chose et la vérification croisée se désynchronise.
- **FAA, facteurs humains.** La *mode confusion* naît d'un même écran qui se comporte
  différemment selon le mode sans signal univoque. La réponse canonique est : structure
  **constante** + annonciateur de mode saillant — pas des écrans différents. Ici l'interactivité
  et le placard changent ; la structure, jamais.
- **Et l'ingénierie qui en découle** : trois surfaces = trois endroits où un correctif peut
  diverger. Ce fichier a payé **deux fois** — les copies du cœur de cochage avaient divergé
  (v4.42.0), et un invité scribe **conduisait** la checklist depuis le lecteur parce que ses
  verbes portaient d'autres noms (v4.55.0).

### Ce qui est désormais unique
- **Le cœur** — `applyCheck` est LE point d'écriture de `state.checked` : garde de rôle, trace
  do-verify, acquittement haptique, drapeau de fin. Les trois appelants ne font plus que peindre.
  Le lecteur écrivait `state.checked` **en direct** ; c'était la troisième copie, jamais recensée.
- **Le vocabulaire** — le lecteur émet `data-ovnext`, `data-ovopt`, `data-cxback`. Plus de
  synonymes, donc plus de liste de gardes à tenir en double : un verbe ajouté demain est couvert
  des deux côtés d'office, parce qu'il n'y a plus de « deux côtés ».
- **La structure** — `stepsListHtml` génère l'unique `ol.steps > li[data-ck]`, trace de
  vérification comprise. Elle était écrite trois fois, et avait déjà divergé : le journal peignait
  la trace, la vue guidée non, pour la même donnée.

### Ce que ça change à l'écran
Le mode lecteur montre désormais **le bloc entier**, ligne courante en 22 px sur fond d'accent,
au lieu d'un paragraphe isolé. C'est le modèle **ECL Boeing** — liste entière + curseur — que
l'audit v4.28.0 opposait déjà au un-item-à-la-fois : perdre sa place est un mode de défaillance
premier (Degani & Wiener). Supprimés avec la structure qui les exigeait : `.rm-r` (la réponse
attendue vit dans la pilule de la ligne) et `.rm-ctx` (le contexte « précédent / suivant » était
une reconstruction manuelle de ce que la liste donne par construction).

### Deux pièges vécus
- `applyCheck` remet `state.flowEnded` à false — donc le test « la fin était actée, il faut
  re-rendre » de la vue guidée ne se déclenchait **plus jamais**. Il faut capturer l'état avant
  l'appel. Le journal, lui, teste la présence de `.flow-end` dans le DOM : il y était insensible.
  C'est `audit-doctrine` qui l'a attrapé.
- `data-rmopt` était un **homonyme** : « reader option » dans le lecteur, « remove option » dans
  l'éditeur — et comme `[data-rmopt]` figurait dans la liste des gestes muets, le bouton
  « supprimer une réponse » de l'**éditeur** était bridé en mode invité. Renommé `data-optdel`.

Un contrôle de harnais a été **réécrit, pas supprimé** : il cherchait `.rm-ctx` (le mécanisme) ; il
mesure désormais la propriété — le contexte est visible, l'étape précédente est marquée faite, et
toutes les lignes portent le même verbe. Il échouerait si la liste redevenait un item isolé.

Vérifié : 785 tests × 2 moteurs, a11y **301/301 sur les deux moteurs**, doctrine 112/112, lecteur
**14/14** (+1), partage 294/294, vérification 8/8, complications 20/20, exercice 20/20.
Rien à rejouer côté serveur.

## [4.61.0] — 2026-07-29
### Une voix typographique — Source Serif 4 pour les titres

Phase 5 du chantier d'audit (F5). Le système roulait tout en `system-ui` : sûr, mais anonyme.
**Source Serif 4** (licence SIL OFL, sous-ensemble latin seul, graisse 600 seule, **21 Ko**)
prend le **titre de fiche**, la **marque** et le **titre du compte rendu** — et rien d'autre.

Ce n'est pas une décoration : les titres sont les seuls survivants du scan sous stress, ils
méritent un dessin. Le texte courant reste `system-ui`, la police que l'appareil rend le mieux —
changer le corps d'une aide lue en réanimation n'a jamais été l'objet.

- **Embarquée, jamais appelée.** L'app fonctionne hors ligne par construction : une police de CDN
  ne s'afficherait pas là où elle sert, et `font-src 'self'` l'interdirait de toute façon. Elle
  entre dans `ASSETS` (précachée dès l'installation, règle 13) avec son README de provenance et
  de licence, sur le modèle de pdf.js.
- `font-display: swap` : le texte s'affiche immédiatement dans la police de repli et bascule
  quand la police est prête — jamais d'écran de titre vide, même au premier chargement.
- **Graisse 600, pas 800**, aux endroits qui étaient en 800 : c'est la seule graisse embarquée,
  en demander une autre produirait une graisse synthétique (plus lourde, moins nette).
- Le compte rendu **téléchargé** retombe sur Georgia — voulu : un document autonome ne dépend
  d'aucun serveur.

Piège rencontré : `check-sw` lit les chaînes d'`ASSETS` littéralement — un commentaire placé *à
l'intérieur* du tableau est pris pour une entrée de cache (25 faux problèmes). Il vit au-dessus.

Vérifié : 785 tests × 2 moteurs, a11y 301/301, doctrine 112/112, zoom-scroll 6/6, `check-sw`
13 assets. Rien à rejouer côté serveur.

## [4.60.0] — 2026-07-29
### Mode moniteur — le téléphone posé devient un afficheur

Phase 4 du chantier d'audit (D3). Sur un chariot, sur le tableau de bord d'une ambulance, ou sur
le second téléphone de l'invité, **personne ne tient l'appareil**. Le mode moniteur en fait un
écran d'état lisible **à deux mètres** : chrono de session, prochain minuteur (nom + temps en
très grand), dernier repère horodaté. C'est l'ECAM au sens propre — un écran qu'on lit sans le
toucher.

**Aucun contrôle, et c'est la propriété qui compte.** Un tap n'importe où revient à la fiche :
une surface sans commande ne peut pas être actionnée par mégarde, ce qu'on veut précisément d'un
appareil posé au milieu d'un soin.

- Le minuteur montré est choisi par `monPick` (pure, testée) : un **échu l'emporte toujours**
  (annonciateur ECAM — l'écart passe avant le nominal), sinon le plus proche de son échéance
  parmi ceux qui tournent.
- Registres inchangés : un échu s'y affiche en ambre **et avec le mot « échu »**, jamais la
  couleur seule.
- Le dernier repère passe par `tkLabels`, la même source que le compte rendu : aucune seconde
  vérité, et un repère sans étiquette retombe sur « Repère n » plutôt que sur un mot inventé.
- Coquille du mode lecteur (z-index 92, sous le flash d'alarme), armement du retour système à
  l'ouverture — toute surface plein écran doit se fermer au geste retour d'Android.
- Rafraîchi par le tick existant : **aucune horloge en plus**.
- Entrée par le menu ⋯ des deux rôles, groupe « conduite en cours », visible seulement quand la
  session est démarrée — jamais dans le chrome de crise, qui n'a que 2,1 px de marge à 320 px.

Piège de test rencontré : `lastStart` est un **horodatage**, pas un délai — posé à 0 sur un
minuteur qui tourne, il fait croire à `now` millisecondes écoulées, et le test mesure alors
l'ordre de la fiche au lieu du tri.

Vérifié : 785 tests × 2 moteurs (+5), a11y 301/301, doctrine 112/112, lecteur 13/13, exercice
20/20. Rien à rejouer côté serveur.

## [4.59.0] — 2026-07-29
### Grand écran : le cockpit trois zones — orientation | action | état

Phase 3 du chantier d'audit (F4). À partir de **1200 px**, la vue de lecture tient de front la
colonne « Se repérer » (le plan, à gauche), le parcours (au centre) et le rail minuteurs (à
droite) : l'idéal ECAM — E/WD et SD sous les yeux en même temps. Pour un binôme hospitalier,
c'est un poste fixe où l'aide-lecteur voit plan, parcours et minuteurs **sans un tap**.

**Palier 1200, pas 1000.** L'audit proposait 1000 px « puisque le palier existe ». Mesuré : à
1000 px les trois colonnes laissent **~390 px** au contenu clinique — moins qu'une tablette en
portrait, pour ce qu'on lit sous stress. À 1200 px : plan 240, action 594 (son plafond de 860
au-delà), rail 360. Aucun palier nouveau n'est créé.

**Le plan quitte le rail droit** à cette largeur : l'afficher aux deux endroits ferait deux
sources pour la même structure — la règle qui vaut déjà pour les minuteurs nominaux.

**L'ordre du DOM reste celui de la lecture.** La colonne de plan est posée *après* la colonne
d'action et ramenée à gauche par `order` : ni un lecteur d'écran ni une tabulation ne doivent
traverser le plan pour atteindre la checklist. Le plan de gauche est le même
`ovPlanLadderHtml` désaturé, **inerte au cochage** (décision figée) — seul son logement change.

Le franchissement du palier **re-rend** (comme le rail à 780 et l'aperçu d'éditeur à 1000) :
c'est un changement de structure, pas de style. Piège vécu au passage : la règle du palier 1200
est déclarée deux fois (en tête puis réaffirmée plus bas, piège de cascade documenté) — la
variante cockpit doit suivre aux deux sites, sinon elle perd à l'ordre.

Vérifié : 780 tests × 2 moteurs, a11y 301/301, doctrine 112/112, zoom-scroll 6/6, vérification
8/8. Rien à rejouer côté serveur.

## [4.58.0] — 2026-07-29
### L'état de mode cesse de bouger — il s'ancre au coin haut-droit

Phase 2 du chantier ouvert après l'audit de design (concept H/B).

La pilule « ■ Mode crise » vivait à droite de la bande-titre quand celle-ci était dépliée, puis
**sautait au milieu de la ligne fusionnée** dès qu'on faisait défiler — et changeait de mot au
passage (« ■ MODE CRISE » ici, « ■ CRISE » là). Or c'est l'objet qui doit se lire en moins d'une
seconde : il devrait être le plus stable de l'écran, pas le moins.

Il est désormais **accolé à ◐ ⋯**, les deux seuls objets qui ne bougent dans aucun des deux
états, et **ne dépend plus du défilement**. Mesuré : même pixel (231 px à 360), même mot, déplié
comme condensé.

### Ce que ce concept n'apporte pas
Les ~90 px rendus au titre étaient le mérite du **concept A** (la pilule descendait dans le
quai), écarté par l'audit lui-même : le quai est la rangée de la télémétrie vive, et pour
l'invité un jeton de mode y doublonnerait les jetons de partage existants. Le gain de B est la
**stabilité**, pas la largeur.

### Deux amendements à l'audit, mesurés
- Il proposait de **vider la bande-titre de son état**. Cela aurait retiré le placard
  « ▪ Vous suivez » posé sur décision utilisateur en v4.55.4 — précisément parce que le bandeau
  est « l'endroit le plus lu » — et fait tomber deux contrôles de harnais qui encodent cette
  doctrine. Le bandeau garde donc son annonce en toutes lettres : la redondance est **voulue**,
  comme l'alarme au quai et au rail.
- Un **repli au glyphe seul** sous 430 px rendait ~41 px au titre. Annulé : en état condensé le
  bandeau est parti, il ne resterait qu'un carré rouge — la couleur et la forme seules pour dire
  le mode, ce que WCAG 1.4.1 et la règle « la couleur n'est jamais seule » interdisent l'une
  comme l'autre.

Le **liseré de mode 10 px** proposé par l'audit n'est pas posé : le placard hachuré de v4.55.4
est déjà le canal périphérique pour l'exercice et l'invité, à coût de hauteur nul — un liseré
serait un troisième dispositif pour la même information.

Vérifié : 780 tests × 2 moteurs, a11y 301/301, doctrine 112/112, exercice 20/20, partage 294/294.
Rien à rejouer côté serveur.

## [4.57.0] — 2026-07-29
### Passe esthétique — profondeur, contraste, rythme (phase 1 des pistes de l'audit)

Première phase du chantier « tout » ouvert après l'audit de design : la PEAU. Les phases
suivantes (en-tête de lecture, cockpit desktop, mode moniteur, police embarquée, restructuration
de la lecture, éditeurs) viennent ensuite, une version à la fois.

### Le thème sombre devient le « Contraste + »
Décision utilisateur : plutôt qu'un 4ᵉ cran au cycle de thème, **le sombre adopte les codes
couleur de l'ex-« Contraste + »** et garde son nom. Motif d'usage : l'extra-hospitalier — soleil
direct sur un écran sombre, gants, appareil posé sur un chariot. Deux canaux, et deux seulement :
encre secondaire relevée (**~7:1** sur les surfaces au lieu de ~4,9:1) et filets renforcés
(**3:1**, le seuil WCAG 1.4.11 des composants — les cadres de carte se voyaient à peine dans le
noir). **Pas** l'encre pleine du bloc `prefers-contrast: more` : là c'est l'utilisateur qui demande
d'aplatir la hiérarchie, ici c'est le défaut de tous. **Pas** les graisses +100 que proposait
l'audit : la graisse porte déjà l'état sur les segmentés, et l'élargir changerait toutes les
largeurs de texte — donc les mesures à 320 px que quatre harnais surveillent.

### Profondeur, fond, rythme
- **`--bg` d'un cran plus profond** (E7) : les surfaces blanches « portent » sans ombre en plus.
- **Trois niveaux d'élévation, écrits** (E1/D6) : plat + filet = contenu clinique ; `--shadow` =
  surfaces vives (session, minuteurs) ; `--shadow-lg` = overlays. Une modale était au niveau 2,
  donc au même plan visuel qu'une carte de session — corrigé. La règle tient en trois lignes dans
  AGENTS.md ; toute surface ajoutée doit s'y ranger.
- **Interlettrage des capitales unifié à `.07em`** (E2, 64 déclarations) : relatif et non px, il
  suit la taille du texte au lieu de se dénaturer quand le corps change.
- **Micro-réponses au geste** (E5) : lévitation d'1 px au survol — **pointeur fin seulement**, car
  sur tactile le premier tap pose l'état hover et un hover qui bouge favorise le double-tap
  (leçon v4.4.4) — et `scale(.99)` à l'appui. Transform/opacity uniquement, inertes sous
  `prefers-reduced-motion`.
- **Le ⤢ devient un dessin de trait** (E6) : même dessin, même doctrine (grammaire des ouvertures
  plein écran), au trait de la famille d'icônes. **Piège mesuré** : un SVG occupe sa largeur
  pleine là où le glyphe Unicode en occupait moins — **4 px de débordement de la rangée de
  commandes à 320 px**, attrapés par `audit-doctrine`. Rendus sur la taille de l'icône (13 px,
  11 sous 400 px), jamais sur `.ctrl-sp` ni par un renommage.

### La tête de bilan du compte-rendu (F6)
Le document commençait par la chronologie : les totaux se reconstituaient de tête, au moment
précis — le débriefing d'équipe — où l'on veut les lire d'un regard. Il s'ouvre désormais sur la
**durée totale en mono 40 px** et les **compteurs de la fiche en tuiles neutres** (plafond 4).
Les compteurs à **zéro sont montrés** : « 0 choc » est une information de débriefing, souvent LA
question. Identique à l'écran et à l'impression.

Vérifié : `npm run check`, 780 tests × 2 moteurs, a11y **301/301 sur Chromium ET WebKit**
(contrastes recalculés sur le fond effectif dans les deux thèmes), doctrine 112/112, zoom-scroll
6/6, consulter 8/8, modeseg 2/2, lecteur 13/13. Rien à rejouer côté serveur.

## [4.56.3] — 2026-07-29
### Audit de design externe — le lot applicable, mesuré et posé

Audit sur 25 captures (1 constat P1, 7 P2, 12 P3, plus des pistes D/E/F/G/H/I/K). Tout ce qui
tenait aux tokens existants, sans rouvrir de décision figée ni créer de capacité, est appliqué ;
les pistes marquées DÉCISION restent à trancher une par une.

### Zone de crise
- **Critères diagnostiques en lignes à filet** (P1-1) — une boîte encadrée par critère
  contredisait la doctrine des listes (« normal = ligne, signalé = boîte ») et repoussait
  « ▶ Confirmé — démarrer la session » loin sous le pli. **53 px rendus, mesurés** sur une fiche à
  critères de deux lignes. Le reste de la distance tient à la RÉDACTION, désormais outillée :
- **le garde-fou du chapeau dit aussi le rappel TROP LONG** (110 c., le seuil télégraphique des
  challenges). Mesuré : quatre rappels dont un composé pèsent 221 px à 360 px — c'est la longueur
  autant que le nombre qui pousse la première action hors de l'écran. Non bloquant, registre
  ATTENTION. `nfGuardTxt` accepte désormais le tableau (le nombre reste toléré).
- **G1 — une action cochable = une ligne** : l'éditeur signale une étape qui cumule des actions
  (« · » ou « + » entourés d'espaces, ≥ 2 dans la partie CHALLENGE ; la réponse « :: » a le droit
  d'énumérer, c'est une valeur). Doctrine QRH : sinon on coche « à moitié fait ».
- **Cartes minuteur** (P2-1) : le nom passe en casse de phrase 13,5/700 et la précision entre
  parenthèses finales est reléguée en méta 12 px (`tmLabelParts`, pure testée) — un nom long en
  petites capitales se déchiffre lettre à lettre, l'inverse du besoin en crise. Le libellé complet
  reste dans les `aria-label`.
- **Le temps dit l'état** (P2-7) : encre à l'arrêt, `--link` EN COURS, ambre échu. `--link` est
  doctrinalement « le temps d'un minuteur en cours » — le défaut disait le contraire.
- **Compteurs** (P2-5) : « + » tonal et large, « − » contour compact (≥ 44 px). En session on
  incrémente dix fois pour une correction ; l'action fréquente prend la masse, jamais un rempli.
- **Une seule ligne d'état** dans le bloc actif (P2-2) : « Vous êtes ici » à gauche,
  Lecteur/Vérifier à droite — **−52 px par bloc actif**, là où deux rangées de chrome flottaient
  entre le titre et la première étape.
- **Rangées d'étape à 60 px** (D1) : le 44 px doctrinal est un minimum, pas un optimum — un pouce
  ganté dans une ambulance en mouvement ne vise pas une case de 24 px. La rangée entière cochait
  déjà ; seule sa hauteur change.
- **Acquittement haptique** (D10) : ~18 ms au cochage et à l'incrément (`tick()`). Avec des gants,
  dans le bruit, la confirmation tactile évite le double-tap de doute — qui sur un compteur
  FAUSSE la donnée. Inerte sur iOS, qui n'expose pas l'API Vibration.
- **Pilule posologique insécable** en statique (D8) ; `tabular-nums` sur les nombres d'état (D11).

### Hors crise
- **Fenêtre Compte** : tuiles d'état **neutres** (P3-1 — `--primary-soft` est la teinte des
  boutons tonals : de la lecture seule s'y donnait l'air cliquable) et **une ligne de conséquence
  par réglage**, la garantie clé en gras, le texte existant CONSERVÉ sous « En savoir plus ».
- **Hors ligne annoncé en neutre** (D7) : « Hors ligne — tout fonctionne sur l'appareil » au pied.
  C'est un état NOMINAL — l'ambre reste à l'échec d'action réseau explicite. `storageState` reste
  PURE : l'état entre par l'instantané, relu à la peinture et aux évènements réseau.
- P3-2 (glyphe « Avec l'IA » au registre INFORMATION), P3-3 (« Cycle »/« Chrono » en pilule
  neutre), P3-4 (« Synchronisé · 11:12 » — le mot ne se dit qu'une fois), P3-5 (« console
  d'administration » remplace le jargon d'infrastructure), P3-6 (colonnes de temps du compte-rendu
  en mono tabulaire), P3-8 (secondes retirées des listes de sessions, `sessStamp`), P3-11 (pied
  d'accueil : le nominal permanent n'affirme plus en vert), P3-12 (pilule de catégorie neutre dans
  Consulter), P3-13 (« Terminer » du bandeau de reprise en contour, cible 44 px), P3-14
  (placeholder de date, compte à rebours du code en `--verify` sous 30 s).

### Écarté, et pourquoi
**G2** — « ✓ Bloc n complet — Continuer vers X » — a été implémenté puis **retiré sur décision
utilisateur** : le bouton passe déjà au registre CONFIRMATION quand tout est coché, les cases le
disent, et deux formules pour un même geste sont exactement ce qu'AC 120-71B proscrit. Le libellé
reste « Continuer — X → », **identique aux deux sites** (journal et vue guidée).

### Un constat d'audit qui visait la doctrine, pas le code
**P2-3** signalait le segment « ⤢ Plan » absent du quai sur toutes les captures. Il l'était en
effet : « Se repérer » a quitté le quai en **v4.25.0** pour la rangée de commandes (architecture
ECP/ECAM). C'est AGENTS.md qui était périmé — deux de ses sections se contredisaient depuis. La
formulation « ORDRE FIXE ⤢ Plan · ● Session · minuteurs » est corrigée. **P2-4** (invité lisant
« ■ MODE CRISE ») est vérifié **conforme** : le placard « ▪ Vous suivez » est livré depuis v4.55.4.

### Non engagé
Les pistes marquées DÉCISION dans l'audit — D2 (« Contraste + », thème vraie nuit), D3 (mode
moniteur), E7 (valeur de `--bg`), F4 (cockpit 3 zones), F5 (police embarquée), F6 (tête de bilan),
H (concepts d'en-tête B/C), I (restructuration de la vue de lecture), K (refonte des éditeurs) —
créent une capacité, touchent un token ou ouvrent un chantier : à trancher séparément.

Vérifié : `npm run check`, **780 tests × 2 moteurs** (+14), a11y **301/301 sur Chromium ET
WebKit**, doctrine 112/112, vérification 8/8, lecteur 13/13, historique 16/16, partage 294/294,
et les 14 harnais verts. Rien à rejouer côté serveur.

## [4.56.2] — 2026-07-28
### Le badge « En cours » trouve sa place — et un bug WebKit de grille est neutralisé

### Badge « ● En cours » à droite de la tuile
Glissé dans la sous-ligne de 11 px, le badge l'étirait et semblait rapporté (« on a l'impression
qu'elle n'est pas adaptée », retour utilisateur). Il vit désormais À DROITE de la tuile, centré
verticalement, hors du bloc de texte — la structure de la maquette desktop : colonne
titre + sous-ligne à gauche (`.qa-tx`), badge en frère à droite. Les rangées du répertoire, qui
alignent déjà leurs pastilles sur une ligne dédiée, ne changent pas.

### Pistes de grille figées au redimensionnement — bug WebKit, reproduit puis neutralisé
Signalé à l'usage : « bug lorsqu'on diminue la largeur puis qu'on ré-augmente » — une rangée du
répertoire restait trop courte, titre rogné en haut, date en bas. IRREPRODUCTIBLE sur Chromium
(sondes discrètes puis fines, 100 % et 130 % de taille du texte : rien) ; reproduit sur WebKit
SEUL, au redimensionnement CONTINU : quand un changement du nombre de colonnes d'une grille
`auto-fill` fait ré-enrouler la sous-ligne d'une rangée, WebKit ne regrandit pas la piste — le
contenu centré dépasse (titre +11 px, date +5 px, mesurés, aux valeurs exactes de la capture
utilisateur) et l'état corrompu PERSISTE, y compris après re-rendu.

Remède : à la TRAÎNÉE du redimensionnement (120 ms, accueil seulement), chaque
`.dir-grid`/`.qa-grid` passe par `block` puis `grid` dans la même frame — écriture-lecture-
écriture synchrones, aucun repaint intermédiaire, donc aucun clignotement — et WebKit recalcule
ses pistes. On ne paie pas un reflow par évènement pendant le geste : l'artefact transitoire de
Safari peut fugacement apparaître pendant la traînée et se répare seul 120 ms après la pause.
Vérifié à la sonde sur les deux moteurs et les deux réglages de taille : état final propre
partout, Chromium jamais affecté. Piège documenté dans AGENTS.md (ne pas retirer ce listener ;
re-mesurer sur WebKit à toute retouche des grilles).

Vérifié : 766 tests × 2 moteurs, a11y 301/301 sur Chromium ET WebKit, doctrine 112/112,
`npm run check`. Rien à rejouer côté serveur.

## [4.56.1] — 2026-07-28
### Les tuiles rejoignent la grille fluide du répertoire

Retour utilisateur immédiat sur la v4.56.0 : « la gestion de la largeur des tuiles en responsive
est extrêmement mauvaise pour toutes les transitions de taille ». Mesuré, et confirmé : les
tuiles « Épinglée(s) » avaient un nombre de colonnes FIGÉ (2 sous 780 px, 3 au-delà) — au
franchissement du seuil, la sidebar et le rail mangent ~330 px d'un coup et une tuile passait de
~360 px à **~140 px** ; et leur rythme ne coïncidait jamais avec celui des rangées du répertoire,
posées juste dessous.

**Une seule règle fluide, partagée** : `.qa-grid` adopte l'`auto-fill minmax(290px,1fr)` et la
gouttière 8 px de `.dir-grid`. Tuiles et rangées ont désormais la MÊME largeur à toutes les
fenêtres et s'alignent colonne pour colonne ; mesuré sur toute l'échelle — 320 → 290 px (1 col),
779 → 2 × 356, 780 → 1 × 451, 1000 → 2 × 332, 1460 → 3 × 372, 1620 → 4 × 317 : tout vit dans la
bande ~290-450 px, une transition ne change plus que le NOMBRE de colonnes, jamais l'échelle.

La question qui a ouvert le dossier (« pourquoi la bulle rétrécit au-delà de ~1480 px ? ») a sa
réponse documentée dans AGENTS.md : c'est la redistribution d'une grille fluide quand une colonne
de plus tient (3 × ~390 → 4 × ~296 vers 1520 px) — bornée par le minimum de 290 px, c'est le
comportement normal, à ne pas « corriger ».

Vérifié : 766 tests × 2 moteurs, a11y 301/301, `npm run check`, design system régénéré (la démo
n'impose plus un nombre de colonnes que le vrai CSS n'a plus). Rien à rejouer côté serveur.

## [4.56.0] — 2026-07-28
### L'accueil devient un « poste accès direct » : épinglées, répertoire A→Z, rail alphabétique

Refonte des listes d'aides ET de protocoles d'après la maquette « 2c — poste accès direct » du
canvas Claude Design « Accueil bibliothèques » (modèle du téléphone d'urgence : les favoris sous
le pouce, l'annuaire complet derrière, l'index de tranche pour y sauter).

### Trois étages à la place de la grille de cartes
- **« Épinglée(s) ★ »** — les fiches épinglées en TUILES (liseré de catégorie, code · catégorie,
  « ● En cours »). Libellé accordé au type et au nombre ; **les épinglées seules**, décision
  utilisateur « juste les favoris » — la fréquence d'usage reste un critère de tri de RECHERCHE,
  jamais de mise en avant ; aucune épingle → la section disparaît. Titre en 15 px borné à
  **3 lignes** puis ellipse (2 lignes tronquaient trop pour reconnaître la fiche ;
  `overflow-wrap:break-word`, pas `anywhere` qui coupait « Anaphylaxie » en plein mot) ; le nom
  accessible et l'info-bulle gardent le texte entier.
- **RÉPERTOIRE A→Z** — rangées compactes groupées par lettre (hors A-Z → « # », rangé en fin),
  tri alphabétique STRICT (l'épinglée a sa tuile — la hisser en tête de sa lettre casserait la
  lecture d'annuaire) ; sous 640 px, chaque lettre devient une liste à filets dans une carte
  (maquette mobile). Les rangées gardent l'épingle ☆, le statut en attente, « À revérifier »,
  « À compléter », la catégorie EN TOUTES LETTRES (la couleur d'une pastille n'est jamais seule)
  et la date de validation en forme COURTE (`fmtDateShort` — « Validation : » pèserait plus que
  la donnée sur une sous-ligne de 11 px). Le répertoire ne se pagine JAMAIS : le rail promet
  « A→Z sous le doigt », un « Afficher plus » ferait des lettres injoignables.
- **RAIL ALPHABÉTIQUE** — tap = saut à la lettre, GLISSER le long des lettres = parcourir
  (index iOS ; pointer capture). Dès 2 lettres ; s'il ne tient pas en hauteur il DISPARAÎT
  (jamais de lettres coupées ni de cibles < 24 px). En étroit il est FIXE, ancré entre le bas
  de l'en-tête (`--hdr-h`) et la tab bar — un centrage sur la fenêtre passait sous l'en-tête
  à 320×640, mesuré puis corrigé.

### Ce qui ne change PAS (décisions utilisateur explicites)
La recherche RESTE dans l'en-tête (champ statique : le focus survit aux re-rendus, raccourci
« / » — la grande recherche du corps de la maquette est écartée) ; le filtre catégorie FILTRE
(l'« estompage sans déplacer » de la maquette est refusé) ; en recherche, liste plate triée par
pertinence (épinglées > frecency > titre), extraits contextuels et pagination inchangés.

### Historique GLOBAL des sessions
Le compte « n sauvegardées » des cartes disparaît ; à sa place, la fenêtre Historique gagne un
mode « toutes les fiches » (chaque rangée nomme la sienne, cliniques et exercices toujours
séparés) : rangée « Historique des sessions (n) » en bas de la sidebar en large, lien du pied de
page en étroit — masqués à zéro session (aucun bouton mort). L'entrée PAR FICHE du menu ⋯ est
inchangée. `openSessHist()` sans argument = mode global `'*'`.

### Sous le capot
- Fonctions pures testées : `azLetter`/`azGroups` (lettre désaccentuée, table en
  `Object.create(null)` — la clé vient d'un titre saisi) et `qaPick` ; +10 tests (766 × 2 moteurs).
- L'ancien composant `.card`/`.cards` est PURGÉ (émissions vérifiées au grep, règle 14 ; démo
  `design/build.mjs` refaite ; `newTonal`, champ mort d'avant la refonte, retiré). Le bouton-titre
  GARDE le nom `.card-open` : quatorze harnais ouvrent une fiche par ce sélecteur.
- Périmètre accueil d'`audit-a11y` : `.dir-wrap,.azrail` remplace `.cards` — un sélecteur mort
  ferait passer l'accueil sans le mesurer (leçon v4.31.1). Le bouton-titre des rangées porte un
  padding 6 px compensé : sa BOÎTE atteint 29 px (l'ancien titre passait la mesure parce qu'il
  s'enroulait sur deux lignes ; le `::after` étendu, lui, ne se mesure pas).
- Vérifié : `npm run check`, 766 tests × Chromium + WebKit, a11y **301/301 sur les deux
  moteurs**, doctrine 112/112, zoom-scroll 6/6, zéro débordement horizontal à 320 px, clair et
  sombre. Rien à rejouer côté serveur.

## [4.55.5] — 2026-07-28
### Deux défauts signalés à l'usage — un menu qui tombait dans la barre, une attribution qui suivait la mauvaise personne

### Le menu ⋯ s'ouvrait DANS l'en-tête — dixième piège de cascade
Dès qu'un placard était posé (exercice ou invité), ouvrir le menu ⋯ ne produisait plus une
fenêtre flottante : il retombait **dans le flux de la barre**, qu'il rallongeait d'autant.

Le placard, pour faire passer le contenu au-dessus de sa hachure, levait **tous les enfants
directs** de l'en-tête en `position:relative; z-index:1`. Or `.more-menu` est un enfant direct
**et se positionne lui-même** : `header.bar.exo>*` vaut (0,2,1) contre (0,1,0) pour
`.more-menu{position:absolute}`. La règle décorative écrasait la règle structurelle.

**On retire l'exigence plutôt que de l'assortir d'exceptions.** Nommer le menu dans un `:not()`
n'aurait fait que déplacer le piège au prochain calque ajouté là — c'est la leçon de la v4.55.3,
une version plus tôt. `header.bar` porte déjà `position:sticky; z-index:20`, donc elle **est** un
contexte d'empilement : un `::before` en `z-index:-1` s'y peint au-dessus du fond de la barre et
sous tout son contenu, **sans qu'aucun enfant ait à être positionné**. On **enfonce** la hachure
au lieu de **lever** ses frères ; l'un ne demande rien aux enfants, l'autre les contraint tous.

`#crisisBand` garde l'ancienne mécanique, et ce n'est pas une inconséquence : il est
`position:relative` **sans `z-index`**, donc pas un contexte d'empilement — un `z-index:-1` y
passerait sous son propre fond et la hachure disparaîtrait. Ses enfants sont tous statiques.

### « Avancé par … » nommait l'hôte pour les gestes de l'invité
La mention était un drapeau **global** qu'un seul site du fichier remettait à zéro : `cxEnter`,
l'entrée sur complication. **Aucun avancement ordinaire ne l'effaçait.** Posée une fois —
typiquement par le backlog rattrapé à la jointure, où toutes les navigations de l'hôte défilent
d'un coup — elle **suivait ensuite l'invité de carte en carte** et attribuait à « Hôte » les blocs
qu'il venait lui-même d'avancer.

Encore un demi-chemin : un effacement écrit d'un seul côté. Le remède n'est donc pas d'ajouter les
N sites manquants — c'est de **supprimer le besoin de s'en souvenir**. La mention porte désormais
le **numéro de visite** que l'avance distante a créé et ne s'affiche que sur celui-là ; le premier
passage minté localement en porte un autre, donc elle disparaît **par construction**.

Elle est posée **dans `shareApplyAnchored`**, seul point où une navigation distante devient la
position courante. `onEvents` le manquait dans un cas (le drain de la file par `rmResume` n'y
repasse pas) et le posait dans un autre où il ne fallait pas : une navigation **refusée** par le
mode lecteur nommait déjà son auteur alors que rien n'avait bougé. L'annonce au lecteur d'écran
garde, elle, une variable **locale au lot** — elle n'a ni la même durée de vie ni la même
condition que la mention affichée.

### Ce que le diagnostic a écarté en chemin
Deux hypothèses ont été **mesurées puis abandonnées** avant d'arriver à la bonne, et c'est ce qui
a évité de « corriger » du code sain : l'attribution est juste quand la liste des participants
est à jour (« avancé par Infirmier », vérifié), et il n'y a **aucun écho** — l'hôte ne repousse
pas sous son nom ce qu'il vient de recevoir. Le défaut n'était ni dans la résolution serveur de
l'acteur (le secret l'emporte sur l'identité, y compris quand les deux appareils sont connectés au
même compte) ni dans le rebasage du diff.

### Vérification
**294/294 contrôles partage** (+14, sur les deux moteurs), 756 tests × 2 moteurs, 14 harnais verts
sur Chromium **et** WebKit, 301 contrôles d'accessibilité, 112/112 doctrine.

Les deux défauts réintroduits en font tomber **sept** ; fichier restauré à l'octet. **Un témoin a
dû être refait** : la première version de la sonde d'attribution avançait par `next`, nul sur le
dernier bloc de la fiche d'exemple — l'avance locale n'avait donc jamais lieu et les deux contrôles
suivants mesuraient du vide. C'est le témoin lui-même qui l'a signalé. De même, la hachure est
mesurée par son **image de fond** et non par l'opacité : sur un en-tête sans placard le
pseudo-élément n'a pas de `content`, et `getComputedStyle` rend alors l'opacité par défaut `1` —
un témoin fondé sur l'opacité aurait été vert des deux côtés.

**Rien à rejouer côté serveur.**
