# Archive doctrinale — extraite d'AGENTS.md (v5.10.3)

> Contenu repris À L'OCTET depuis AGENTS.md (patron du découpage du changelog, v5.0.0) —
> aucune réécriture. Ces entrées restent NORMATIVES : elles portent les décisions et leurs
> raisons ; AGENTS.md garde les règles vivantes et renvoie ici. Empreinte du bloc extrait :
> sha256:61f82124f3c2.

## Refonte v5.6 — direction « verre clinique, mat »

> Ces entrées sont la **passation** de la refonte (planches Claude Design, phases 0 à 6). Elles
> ROUVRENT des décisions consignées : chacune est nommée avec ce qu'elle achète et ce qu'elle
> coûte. Une règle non consignée est une règle que la prochaine itération prudente défera.

**TROIS MATIÈRES, TROIS NATURES.** Sombre (`--sys`) = SYSTÈME : la capsule d'état et le dock, les
deux seuls objets sombres du produit — trouvables sans lire. Blanc (`--work`) = TRAVAIL : carte,
historique, feuilles, éditeurs ; seule matière qui projette une ombre. Gris (`--amb`) = AMBIANCE :
le fond, ce qui attend.
**ROUVRE** les bandes et filets empilés du chrome de crise (v4.25.0 et suivantes) : la séparation
commandes/affichage passe désormais par la MATIÈRE, plus par des rangées superposées.
**⚠ TROIS TOKENS NE SONT PAS DES ALIAS, et chacun l'a appris au prix d'un contrôle rouge** :
`--paper` reste un BLANC FIXE des deux thèmes (aliasé sur `--work`, le QR se peignait en encre
sombre sur fond sombre — indéchiffrable, et le défaut ne se serait vu qu'au moment de scanner) ;
`--shadow-up` garde son décalage NÉGATIF (une ombre montante qui descend fait paraître l'objet
enfoncé) ; `--ctl-line` tient 3:1 là où `--line-strong` du système n'en fait que 1,6 — WCAG 2.2
§ 1.4.11 vise les BORDURES DE COMPOSANT, c'est-à-dire la case qu'on vise avec des gants.
Sur la matière système, les registres ont leurs valeurs propres (`--ok-sys`, `--warn-sys` sur
`--warn-sys-bg`, `--crit-sys`, `--on-sys-fill`) : la capsule et le dock sont sombres dans les DEUX
thèmes, un registre du thème clair n'y tiendrait pas 4,5:1.

**A1. CLAVIER VS DOCK.** Au focus d'un champ, le dock s'efface (le clavier EST la surface de
saisie) ; il revient à la fermeture. Ne jamais empiler dock + clavier. Le champ du volet ⏱ est
EXCLU : il vit dans le dock, s'effacer sous les doigts de qui écrit dedans serait absurde.

**A2. 320 px.** Les touches d'excursion perdent leur étiquette (glyphe seul, `aria-label`
conservé). Hors du contrat « le mot Crise jamais au glyphe seul », qui ne vise que le STATUT, pas
les commandes — et les deux GESTES (⚡︎, ⏱) gardent leurs mots, parce qu'ils ÉCRIVENT.
⚠ **DEUX CORRECTIONS DE v5.10.1, ET LA PREMIÈRE EST UNE LEÇON DE COMPOSITION.** (1) Le palier
s'écrivait `@media (max-width:359.98px)` : il ne se déclenchait donc jamais sous zoom, c'est-à-dire
au moment précis où il sert (A140). Il passe en `html.zw360`. (2) Une fois les étiquettes tombées,
les deux touches d'excursion portaient le MÊME glyphe — deux destinations, un signe, aucun mot
(A143). Cette règle-ci et le choix d'un glyphe commun (v4.25.0) étaient justes séparément ; c'est
leur COMPOSITION qui ne l'était pas.

**A5. THÈME SOMBRE — OLED GRIS.** Fond `#0d0f13` (gris vrai, pas un noir théâtral : sur OLED le
noir pur fait « trou » et le halo des textes clairs fatigue), travail `#171a20` bordé, encres
remontées, signaux éclaircis, zéro ombre — la nuit ne projette pas, elle borde.

**A6. ÉCHELLE TYPOGRAPHIQUE FERMÉE — SEPT CRANS, UNE SEULE BANDE.** `11 / 12 / 13,5 / 15 / 17,5 /
21 / 24`, graisses 500-800. L'ancienne bande d'AFFICHAGE (20 · 24 · 26 · 34 · 40) disparaît avec sa
raison d'être : un chrono à 40 px pendant qu'une étape vitale plafonnait à 15,5 était l'enjeu
INVERSÉ. Seule dérogation, le multiplicateur global `--zf`, qui garde les crans solidaires.
`check-type` le vérifie ; son CLIQUET de plancher est remonté de 166 à 170 déclarations à 11 px —
les quatre étiquettes du dock (A13) —, et c'est un ÉCHANGE, pas une tolérance : l'étape critique
passe de 15,5 à 17,5 px dans le même mouvement.
ACHÈTE : le grand corps appartient à l'ACTE, plus au chrono.

**A7. « VÉRIFIER » EST UN GESTE DE BLOC.** Il rejoue les challenges « :: » du bloc courant
(Do-Verify, FAA Order 8900.1) : il vit dans la carte, en rangée de pied, à gauche de « Continuer »,
et SEULEMENT si le bloc porte des challenges. Le dock reste pur session.

**A8. CIBLES.** Aucun contrôle sous 44 px de cible en crise — ± des compteurs, RELANCER/PAUSE et ✕
compris. La cible vient du HALO, jamais du dessin : c'est ce qui permet à la capsule de se
compacter à 36 px dans l'en-tête sans perdre ses 44 px de cible.

**A9. HAUTEURS D'ÉTAT FIXES.** Un changement d'état NON commandé (un minuteur qui devient échu, une
alarme qui s'éveille) ne modifie JAMAIS une hauteur : capsule (50 px) et cartes de minuteur ont un
gabarit constant entre leurs états ; seuls matière, couleur et texte changent. L'expansion reste
permise quand elle est COMMANDÉE par un tap. ⚠ Le piège n'est pas la structure — elle est identique
d'un état à l'autre — c'est le LIBELLÉ : « Adrénaline » devient « Adrénaline — échu », un mot de
plus passe le nom sur deux lignes, et la carte grandit sous le doigt. D'où le clamp à deux lignes.

**A10. UNE ÉTAPE FAITE NE SE BARRE JAMAIS.** Le fait se marque (✓ + encre atténuée), il ne
s'ampute pas. Trois raisons : une checklist en boucle fait relire l'étape au passage suivant ; la
passe Do-Verify exige de pouvoir RELIRE ce qu'on a fait ; ni l'ECAM ni le QRH ne rayent une ligne
exécutée. Le barré reste admis hors crise, sur des listes non séquentielles, et pour ce qui est
ANNULÉ (repère annulé, participant déconnecté) — annulé n'est pas fait.

**A11. APLAT VS MARQUE.** La teinte en APLAT est réservée à ce qui exige une action MAINTENANT
(alarme active) — une seule masse colorée à l'écran, et le nominal s'éteint. Une étape critique se
MARQUE : case rouge + ⚠ + corps 17,5 px + cadence mono ambre, **sans cadre ni fond**. Mesuré à
l'usage : à cinq étapes, l'aplat happe l'œil et détruit la lecture de la séquence. Le CORPS est le
canal du danger — il ne hiérarchise que si toutes les lignes ne l'ont pas, d'où l'étape ordinaire à
`--t-item` et la seule critique à `--t-step`. La vigilance △ ne prend PAS le gain de corps : le
grand corps dit « ceci tue », l'étendre à « on s'y trompe » remettrait les deux à égalité.

**A12. « ICI » N'EXISTE QUE DANS UNE LISTE.** Sur la carte, le bloc ouvert est déjà désigné par
trois signaux (seul bloc ouvert, tête de journal, bordure d'accent) et par `aria-current="step"` :
l'étiquette y est redondante, seul le compte subsiste. Elle reste dans le rail Structure,
l'excursion « ⤢ Tout voir » et l'étiquette de retour du dock — là où elle sert à SE RETROUVER.

**A13. DEUX CRANS DE GLYPHE.** Glyphe de commande 15 px (‹ ◐ ⋯ ⤢ ▤ ⚡︎ ⏱ ✕ ±) ; micro-glyphe inline
(✓ ⚠ △ ●) au corps du texte qu'il accompagne. Étiquettes de touches à `--t-cap` 11 px. Tout glyphe
susceptible de basculer en emoji couleur (⚡︎ notamment) porte le sélecteur de présentation texte
U+FE0E : une couleur non contrôlée casse la sémantique du danger.
⚠ **DEPUIS v5.10.1, LES QUATRE GLYPHES DU DOCK SONT DES TRACÉS, PAS DES CARACTÈRES** (A143) : ⚡︎ et
⏱ passent par `uiIcon('bolt')` / `uiIcon('stopwatch')`. Le sélecteur U+FE0E était une PRÉCAUTION
contre un rendu qu'on ne maîtrise pas ; un tracé supprime le risque au lieu de le border, ce qui
est le motif d'A106. La règle des deux crans est inchangée — c'est le PORTEUR qui change.

**A14. EN-TÊTE À TROIS ZONES ANCRÉES.** Identité à gauche — **sur-titre `.brand-sur` AU-DESSUS du
titre**, parce qu'accolé au nom de la fiche le statut se lisait comme un fragment de ce nom ; état
au CENTRE en position absolue à partir de 1000 px (un titre long ne déplace plus l'alarme) ;
réglages à droite. Hauteur constante quel que soit l'état. **La pilule `#hdrCrisis` est PURGÉE** :
deux énoncés du même mode sur le même écran, c'est la duplication que la v4.70.1 proscrit — la
question n'était plus QUE supprimer mais LEQUEL, et le sur-titre gagne parce qu'il est du côté où
l'œil arrive et qu'il ne dispute plus sa place aux réglages.

**A15b. « PARCOURS » EST LA SÉQUENCE, « PAGE » EST LE CONTENU (v5.6).** Les deux onglets du cran
« Toute la fiche » montraient l'un et l'autre chaque étape de chaque bloc, dans deux mises en page —
deux vocabulaires pour une idée (§5.5). « Parcours » devient une rangée par bloc (état dans la
marque, renvois à droite) et seul le bloc COURANT développe ses items : c'est la rangée qui répond
à « où j'en suis », les autres n'ont rien à dire de plus que leur compte. « Quand l'utiliser » y
reste — la maquette ne la montre pas, mais retirer une condition d'entrée d'une vue « toute la
fiche » serait une perte sèche.

**A15. « CONSULTER » N'ÉVINCE PAS LE BLOC AU COCKPIT.** À partir de 1200 px la référence s'ouvre
dans la colonne d'état : le bloc reste sous les yeux et cochable (l'ECAM ne remplace que la zone
concernée). Sous 1200 px elle reste une excursion, retour nommé « ↩ REVENIR · n » à position
constante, même vert que « ↩ UN BLOC ». « Tout voir » garde le remplacement à tous les paliers :
c'est la même matière que le bloc — la fiche.

**A16. UNE LIGNE OU UNE CARTE — LA FORME DIT LA NATURE (v5.6, deuxième passe de fidélité).**
Ce qui se COMPTE prend une carte (les blocs d'une séquence : on les dénombre d'un coup d'œil) ; ce
qui se LIT prend une ligne (repères posologiques, surveillances, différentiels, documents,
références). Corollaires appliqués partout :
· **Un repère posologique est une RANGÉE** — nom à gauche, valeur mono à droite, MÊME grammaire
  dans le flux et dans le rail (deux habillages en feraient deux composants). Le registre △ se
  marque (glyphe + encre), il ne prend jamais d'aplat.
· **Plus aucune case inerte dans « Consulter »** — une case qu'on ne peut pas cocher, dans une
  surface dont l'INERTIE est la propriété qu'un harnais vérifie, invite au geste qu'elle refuse
  (même argument qu'en v5.0.0/M1 pour l'éditeur, où `.li-box` a été purgée pour cette raison).
  Ses sections sont des INTERTITRES 11 px dans leur carte, plus des rangées-menu de 52 px — la
  cible de 44 px est rendue par le rembourrage, jamais par un halo (sur une rangée pleine largeur
  il recouvrirait la première ligne de contenu, et un tap destiné à lire replierait la section).
· **Les surveillances de la colonne d'orientation restent des lignes** : elles n'ont pas de rang,
  et un item ellipsé y perd son contenu clinique là où un bloc se retrouve par son numéro.

**A17. UNE DÉCISION N'EST PAS UNE ALERTE (v5.6, maquette « cas difficiles »).** La carte de
décision était un APLAT ambre : dans une fiche à branches, c'est le bloc courant une fois sur
deux — la moitié du soin se déroulait sur un fond d'alerte, et l'ambre cessait de vouloir dire
« c'est là qu'on se trompe » (A11). Elle redevient une carte de TRAVAIL ; le registre est porté
par l'étiquette du bloc et le liseré gauche, qui restent ambre (v4.24.0 : un registre n'est jamais
masqué par un état). **Les issues prennent le registre de l'ACTION** — contour `--act` de 2 px,
poids strictement égal, aucune n'est suggérée — **et chacune ANNONCE SA DESTINATION** (« → bloc 4 ·
Stabilisé ») : un chevron dit que ça mène quelque part, pas OÙ, et c'est ce qu'on veut savoir avant
de choisir sous stress. Numéro du plan (numérotation commune) + titre tronqué : un numéro seul ne
parle pas à un humain (v4.16.2).

**A18. LE DOCK EST LA BARRE DE COMMANDE DE LA SESSION (v5.6, maquette 1c).** Ses quatre touches
— **de largeur ÉGALE, ce qui était FAUX jusqu'en v5.10.1** : `flex:1.3` donnait à ⏱ une piste 30 %
plus large, mesuré 79/79/79/100 à 390 px et 46/46/88/110 à 320, soit un rapport de 1 à 2,4 sur la
rangée dont toute la valeur tient à ce qu'on n'ait pas à la relire (A147). La largeur n'est pas le
canal de la fréquence ; le registre l'est —
n'apparaissent qu'une fois le soin DÉMARRÉ. Avant le premier geste, deux d'entre elles
DÉMARRERAIENT la session implicitement par un contrôle qui ne le dit pas (⏱, ⚡), et les deux
autres doublonnent ce que la page montre déjà — hors session la fiche est ENTIÈRE sous les yeux.
« Consulter » reste à un tap par la rangée d'annexes et par le renvoi de la condition d'entrée.
⚠ CE QUI N'EST PAS REPRIS DE LA MAQUETTE, ET POURQUOI : elle loge « Démarrer la session » DANS le
dock. Le bouton reste dans le flux, sous les critères — c'est le geste qui PORTE la confirmation
(« Confirmé — démarrer la session », v4.3.2) ; le déplacer en ferait un second énoncé du même verbe
(§5.5) ou obligerait à supprimer celui du flux, donc à rouvrir l'ordre « critères → memory items →
geste » (v5.0.8) et la zone flottante qui garantit qu'on l'atteint (v4.73.0). Trois décisions
mesurées pour un gain de position : à décider séparément, jamais par effet de bord.

**A19. LA CONDITION D'ENTRÉE A DEUX ÉTATS, DONC DEUX DESSINS.** Avant la session, « suis-je au bon
endroit ? » EST la question : carte au dessin de la maquette (« ■ Quand l'utiliser », un ■ rouge
par critère, renvoi discret vers les différentiels), sans chevron — il n'y a rien à replier quand
on n'a pas encore répondu. Après, c'est une ligne de traçabilité : le dépliant d'avant, inchangé.
⚠ CADRE NEUTRE, PAS ROUGE (maquette 1c contre 1b — les deux existent) : le chapeau « Ne pas
oublier » juste dessous EST un encadré rouge, et deux cadres rouges qui se suivent sont
l'inflation que ce dossier combat depuis la v4.23.0. Le registre vit dans le titre et les
marqueurs.

**A20. LE VOLET DU QUAI EST UN ÉTAGE DU CHROME, DONC IL EST SOMBRE.** La v5.4.1 en avait fait un
étage plutôt qu'une carte flottante — bonne structure, matière d'avant. Depuis les trois matières,
un étage du quai en blanc annoncerait qu'on est revenu dans le TRAVAIL. Cartes `--sys-2`, échu sur
`--warn-sys-bg`. Aucun contenu clinique n'y vit : ce sont des ÉTATS (temps, décomptes, repères),
c'est-à-dire ce que le quai porte déjà.

**A21. « NOTER L'HEURE » N'A QU'UNE ADRESSE.** C'est une touche du dock. Le panneau du journal ne
la porte plus : deux adresses pour un verbe, c'est ce que §5.5 proscrit, et la seconde vivait
derrière un dépliant — donc invisible à l'instant où l'on en a besoin. Le panneau redevient la
LECTURE du journal.

**A22. TROIS FAMILLES, TROIS TOKENS — ET UN GARDE-FOU (`check-fonts.mjs`).** Manrope (`--f-ui`),
IBM Plex Mono (`--f-mono`), Source Serif 4 (`--f-title`). Une `font-family` écrite en clair est
SILENCIEUSE : le texte s'affiche, dans la mauvaise voix, et sur un système où `system-ui` ressemble
à Manrope on ne le voit pas même en regardant. Deux sites l'enfreignaient depuis la refonte — la
pilule de discriminant du titre et les sept textes du schéma SVG, tous deux posés du temps où
l'interface ELLE-MÊME était en `system-ui`. ⚠ Un attribut SVG `font-family="…"` n'hérite pas d'une
propriété personnalisée : il porte la pile en clair, famille embarquée en tête. Le compte rendu
TÉLÉCHARGÉ est exempté par la RÉGION où il vit (pas par une liste de valeurs) : c'est un document
autonome, sans serveur, et ses polices système sont une décision (v5.2.0).

**A23. L'ÉCHELLE FERMÉE SE VÉRIFIE AU RENDU, PAS SEULEMENT DANS LA FEUILLE (v5.6, balayage).**
`check-type`/`check-space`/`check-radius` lisent le bloc `<style>` : un `style=` EN LIGNE dans la
coque statique leur échappe entièrement, et une règle qui ne s'applique pas dans un logement
(`.ai-card ol` quand la feuille s'ouvre dans la COLONNE du cockpit) laisse le navigateur poser son
défaut de 16 px. Le balayage du rendu (7 surfaces × 320/390/1280 × zoom 90/100/130) a trouvé
exactement quatre dérives, toutes invisibles au statique : `#confirmMsg` à 14,5 px et un `gap:9px`
en ligne, `.sv-band.sv-cxband` qui héritait du 16 px par défaut (texte NU, sans `.sv-t` pour le
porter), et la liste des références en colonne. Après : **zéro** taille et **zéro** rayon hors
échelle, l'espacement n'ayant plus que des compensations négatives documentées et la réserve du
dock — qui est une HAUTEUR MESURÉE, pas un espacement choisi, et ne doit pas être arrondie.

**A24. LE DOCK EST FLOTTANT PARTOUT, À LA LARGEUR DE SA COLONNE (v5.6, décision de l'auteur CONTRE
la planche 7c).** 7c le voulait en pied de colonne au-delà de 780 px ; à l'usage, une colonne de
lecture fait plusieurs milliers de pixels et le geste d'entrée comme les quatre touches de session
se retrouvaient à un défilement complet de ce qu'ils commandent, quand tout le dispositif est
adossé à la promesse d'une position CONSTANTE. Ce qu'on garde de 7c est sa vraie trouvaille : sa
LARGEUR. Le dock s'aligne sur la COLONNE D'ACTION, jamais sur la fenêtre — géométrie prise sur la
grille canonique, désormais en TOKENS (`--col-orient` 240 · `--col-state` 320 · `--col-gap` 20),
calculée en CSS : aucune mesure JS, rien à resynchroniser au redimensionnement. La mécanique
NOMADE du dock est purgée avec ce qu'elle servait (règle 14).

**A25. TROIS GABARITS DE FENÊTRE, DEUX RÉGIMES DE PLACEMENT (v5.6, planches 7e/8d).**
LARGEURS : CONFIRMATION 420 (`.dlg-confirm`) · DIALOGUE 480 (`.dlg-480`) · ATELIER 720 (défaut).
⚠ Une largeur écrite EN LIGNE (`style="max-width:…"`) échappe à TOUS les garde-fous statiques
(ils lisent le bloc `<style>`, leçon A23) : il n'y en a plus aucune, et un témoin le mesure au
RENDU. STRUCTURE : en-tête fixe, corps qui défile, pied fixe — la carte est le défileur, plafonnée
à la hauteur visible, et le corps SE NOMME (`.ai-body`) ; un « dernier enfant flexible » deviné en
CSS ferait de tout ajout futur un défileur par accident. Bornée par `:has(>.ai-body)` : les
fenêtres à contenu court et hétérogène gardent la modale pour défileur.
PLACEMENT — ET C'EST UNE NATURE, PAS UNE QUATRIÈME LARGEUR : « sous 780 px, toute fenêtre devient
une feuille pleine hauteur » (SPEC §6) vaut pour un DOCUMENT (long, non borné, qu'on parcourt) ;
un CHOIX (court, borné, dont on sort au geste suivant) reste centré, à la hauteur de son contenu
(`.dlg-center`, et `.dlg-confirm` qui l'avait déjà compris). Un titre unique partout :
`--t-step` / 800.

**A26. LES FILTRES SONT UNE FEUILLE (v5.6, planche 8c).** Le dépliant d'en-tête faisait GRANDIR le
chrome collant au moment précis où l'on demande à voir la liste — on ouvrait les filtres, l'écran
rendait MOINS de contenu —, les trois familles ne s'y voyaient jamais ensemble, et un dépliant ne
peut pas ANNONCER son résultat. La feuille le peut : « Voir les 11 résultats », c'est-à-dire savoir
ce qu'on obtient avant de refermer pour regarder. `state.filtersOpen` garde son nom et son statut
(le temps de la page, ni persisté ni synchronisé) : seule sa FORME change. Mesuré : ouvrir déplace
le contenu de 0 px et le chrome de 0 px.
⚠ CE QUI N'EST PAS REPRIS DE LA PLANCHE : « Créer » en bouton FLOTTANT sous 600 px. Une barre
flottante donne la place la plus saillante de l'écran, en permanence, à l'action la plus FROIDE de
l'accueil — l'inversion de saillance que l'audit A3-1 a relevée sur cet écran —, et le seul objet
flottant du produit porte des gestes d'URGENCE. Le besoin réel (ne pas remonter tout l'annuaire
pour créer) est déjà tenu : « ＋ » vit dans la rangée persistante et survit au défilement.

**A27. L'EN-TÊTE DE L'ACCUEIL SE RESSERRE AU DÉFILEMENT, ET RIEN N'Y BOUGE (v5.6, planche 7a).**
`body.home-slim`, posée par `syncHdrScroll` avec hystérésis (80 px vers le bas, 40 au retour) :
partent la marque, le logo et la rangée de chips ; restent le champ, « ＋ », le déclencheur de
filtre et le compte. Mesuré : 114 → 62 px à 390 (110 → 62 à 320), le champ à l'abscisse 18 dans
les deux états.
⚠ LA MICRO-ANIMATION EST DE PEINTURE, ET CE N'EST PAS UNE TIMIDITÉ : l'en-tête prend son ÉLÉVATION
(ombre + filet, ~160 ms, inerte sous reduced-motion). Faire FONDRE ce qui part a été essayé puis
mesuré faux — pour être fondus, la marque et le logo doivent rester dans le flux, or un élément de
largeur nulle CONSOMME QUAND MÊME les deux `column-gap` qui l'entourent, et le champ se déplaçait
de 18 à 34 px. Animer la HAUTEUR n'a jamais été une option (check-anim, et v4.41.0).
⚠ ET TOUTE GÉOMÉTRIE ANCRÉE À L'EN-TÊTE DOIT S'ANCRER À SON ÉTAT DÉPLOYÉ : le rail A→Z se posait
sur la hauteur DU MOMENT, si bien que tout re-rendu pendant qu'on avait défilé agrandissait sa
boîte de 52 px et déplaçait les lettres centrées de 26 px sous le doigt (règle de v5.0.9,
appliquée à un second objet).

**A28. DEUX NIVEAUX DE SÉPARATION DANS LE RAIL (v5.6, signalé à l'usage).** Une FAMILLE se sépare
par l'ESPACE et par son titre — petites capitales, graisse 800, son compte : un marqueur bien plus
fort qu'un filet, et ajouter un trait par-dessus est l'inflation de trait, la même faute que le
rouge permanent. Le FILET reste à l'ITEM, qui n'a que lui. ⚠ Une carte (`.rs-sec`) ne reçoit PAS ce
traitement : lui retirer son `border-top` lui ouvrirait le haut — une carte se sépare d'une autre
par un écart, point.

**A29. LE VOLET DU QUAI PROLONGE LA CAPSULE (v5.6, signalé à l'usage).** La v5.4.1 en avait fait un
ÉTAGE du chrome : bonne structure, géométrie d'avant — posé sous TOUT le bandeau et de bord à
bord, il se lisait comme une seconde barre. Il prend la largeur de la CAPSULE et se colle à elle,
coins vifs en haut, arrondis en bas : un seul objet, deux étages. Les deux valeurs viennent du
rembourrage du bandeau et vivent contre lui, sans une mesure JS. V1 et V2 inchangés et mesurés :
rien ne bouge derrière, la capsule reste en place et au-dessus.

**A30. LE THÈME A DEUX ADRESSES, ET C'EST UNE EXCEPTION ASSUMÉE (v5.6, décision utilisateur).** Le
réglage canonique est à froid, dans Compte › Affichage ; un RACCOURCI vit dans l'en-tête, en
LECTURE d'une aide ou d'une référence seulement. Deux contrôles pour une même valeur enfreint
§5.5 — l'exception se justifie par le MOMENT, pas par la commodité : une chambre qu'on éteint au
chevet pendant un soin, où ouvrir une fenêtre de réglages n'est pas envisageable. Il n'existe donc
PAS sur l'accueil, où la fenêtre Compte est à un tap. Trois crans, dans l'ordre du réglage : une
bascule à deux laisserait « Auto » inatteignable depuis la fiche. Sa condition est la VUE, jamais
la largeur (v4.31.0).
COROLLAIRE — LA RANGÉE D'ACTIONS N'A QU'UN GABARIT : 36 px de dessin, 44 de cible par le halo,
pour les quatre contrôles. Le menu ⋯ était le seul à 44 px de DESSIN (sur une rangée de glyphes,
le plus gros se lit comme le plus important) et l'avatar portait un halo calibré du temps où il
faisait 30 px — sa cible montait à 50 et CHEVAUCHAIT celle de son voisin. Et « Créer » ne change
plus d'habit selon l'état du CONTENU : la règle « un seul bouton rempli » vise les boutons de
TEXTE du flux, pas un glyphe du chrome sur la seule rangée qui ne doit jamais se réapprendre.

**A31. LES HACHURES SONT UN FILET, PAS UNE BANDE (v5.6, maquettes).** Fond `--primary-soft`, filet
d'UN pixel tous les dix à 12 % de l'encre primaire, à −45°. ⚠ La mise en phase de v5.0.5 CONTRAINT
la géométrie : la période s'écrit en POURCENTAGE de la ligne de dégradé — sur une tuile carrée de
31 px cette ligne vaut 43,84 px, donc 25 % donne un pas de 10,96 px et 2,3 % un filet de 1,0 px,
soit le dessin de la maquette ET quatre périodes exactes par tuile. Écrire « 1px / 10px » en dur
casserait le raccord entre l'en-tête et le bandeau. Jamais le raccourci `background`.

**A32. ⏱ UN COMPTEUR S'INCRÉMENTE DEPUIS LE VOLET — UN GESTE, DEUX FAITS, UNE SEULE LIGNE (v5.6,
demande utilisateur).** Incrémenter pose DÉJÀ son propre repère horodaté (v4.52.0) : appeler le
chemin du « + » depuis le volet ⏱ produirait DEUX lignes à la même seconde pour un seul acte —
le doublon que « ✓ Consigné à … » existe pour supprimer. La chip ATTACHE donc le compteur au
repère que le tap vient de poser, avec la valeur ATTEINTE ; le minuteur lié est armé comme au
« + » (même acte clinique, il ne peut pas avoir deux comportements selon l'endroit). TRANSPARENCE :
la chip dit sa destination AVANT le tap (« 0 → 1 »), et `#srLive` l'annonce après.
⚠ UN RANG NE GARANTIT RIEN, IL ORDONNE : sur un bloc de six étapes les compteurs tombaient au
septième rang et disparaissaient d'une liste bornée à six. `tagSuggest` reçoit un paramètre
FACULTATIF `garantis` qui leur réserve les premières places.

**A33. EN CRISE, LE HARNAIS D'ACCESSIBILITÉ MESURE TOUT — LES EXEMPTIONS SE NOMMENT (v5.6, planche
8f).** Une liste de racines est un contrôle par liste blanche : elle ne mesure que ce qu'on a pensé
à y mettre, et le dossier a payé ce trou trois fois. Dès qu'une session est à l'écran, `audit-a11y`
scanne la page entière ; hors crise la liste demeure (ces écrans n'ont pas le contrat des 44 px).
L'inversion a trouvé QUATRE violations AA qu'aucune racine ne contenait — `.skiplink` à 40 px,
trois textes de la carte de bloc en `--ink-3` à 2,32:1, la réponse attendue d'une étape cochée, et
un séparateur « · » à 1,33:1 (supprimé : un séparateur qui doit rester discret ne s'écrit pas en
lettres, c'est un ÉCART). Trois invariants entrent en même temps dans `audit-doctrine` : **A9**
(un changement d'état non commandé ne modifie aucune hauteur), **A6 au RENDU** (ce que check-type
ne peut pas voir), **A11** (au plus une masse colorée). ⚠ Un minuteur à CYCLES n'est jamais échu —
il se relance : couper la boucle avant de forcer l'échéance, sinon le témoin ne rencontre pas son
cas et mesure deux fois le nominal.

**A34. ACQUITTER N'EST NI RELANCER NI REMETTRE À ZÉRO (v5.6, signalé à l'usage : « un minuteur
sans relance, une fois échu, s'affiche dans le bandeau session et tout, c'est super ; mais aucun
moyen de le faire disparaître que de le relancer »).** La doctrine v4.2.0 disait « acquittement par
l'ACTION », et elle a raison sur le fond — une alarme ne se referme pas d'un revers de main. Mais
elle ne prévoyait qu'UNE façon d'agir, alors que l'action juste est parfois « c'est noté, je n'ai
plus besoin de ce minuteur ». Une TROISIÈME sortie s'ajoute donc, sur la carte du minuteur
concerné : « ✓ Vu » (`t.ack`). C'est le **master caution de l'ECAM** — on l'acquitte à SA station,
la panne reste écrite.
· **L'ÉTAT NE CHANGE PAS** : la carte continue de dire « échu », le compte rendu n'y perd rien ;
  seule l'ANNONCIATION cesse — le minuteur quitte la capsule. ⚠ Le filtre vit dans `run` et pas
  seulement dans `dueList` : en ÉTROIT le quai porte la liste ENTIÈRE (`withRem.slice(0,1)`), et
  filtrer plus bas ne changeait rien sur le format où le défaut a été signalé (mesuré).
· **LE DRAPEAU MEURT AVEC L'ALARME** : `toggleTimer` et `resetTimer` le remettent à faux — une
  nouvelle échéance est une nouvelle alarme, elle s'annonce.
· **LE BOUTON PARAÎT AU TICK, PAS AU RENDU** (`syncTimerBtns`) : une échéance survient sans qu'on
  touche à rien ; posé seulement par `timerCard`, il n'apparaîtrait qu'au prochain rendu complet,
  c'est-à-dire peut-être jamais. Le clic est donc DÉLÉGUÉ, jamais câblé au rendu.
· **GESTE OUVERT À TOUS LES RÔLES et LOCAL** : acquitter n'efface rien et ne conduit rien. Rien ne
  diverge, puisque l'état du minuteur est inchangé — c'est la même échéance, silencée ici et pas
  là-bas, ce que fait tout acquittement d'alarme.
· **⚠ A9 — IL NE PREND PAS UNE LIGNE DE PLUS** : mesuré d'abord à **214 → 264 px**. Dans une
  colonne de 136 px la rangée de commandes a DÉJÀ ses deux boutons l'un sous l'autre ; un
  troisième y ajoutait mécaniquement une ligne, quelle que soit sa largeur. « ✓ Vu » **se sert donc
  dans la part de la remise à zéro** (52 px pris, 62 px laissés au lieu de 120) : les seuils
  d'enroulement des deux états coïncident AU PIXEL — sans cette soustraction, il existerait une
  bande de largeurs où la carte échue serait plus COURTE que la nominale, le même défaut à
  l'envers. Il se glisse ENTRE le bouton principal et la remise à zéro : en tête, c'est lui qui
  aurait chassé le principal à la ligne suivante. Δ = 0 px mesuré à 136, 200, 250 et 320 px.
· **VINGT-ET-UNIÈME PIÈGE DE CASCADE** : `.rt-dock .tm-btn` (0,2,0) pose `flex:1 1 120px` — la
  règle du bouton, écrite en (0,1,0), perdait et la ligne de plus revenait. Portée à (0,2,0)
  ET (0,3,0), jamais par l'ordre de déclaration.
· **UN SEUL TÉMOIN POUR UNE SEULE MANŒUVRE** : l'acquittement est mesuré DANS la section A9, qui
  fait déjà échoir un minuteur volet ouvert — une section à part aurait rechargé le même contexte
  pour le même geste, et deux sections qui montent le même décor finissent par diverger.
· **⚠ LE TÉMOIN NE RENCONTRE SON CAS QU'EN COLONNE ÉTROITE** (vérifié : à 1280 il reste VERT sur
  le défaut, la rangée du rail ne s'enroulant pas), et il compare **les deux états ÉCHUS** — avec
  et sans le bouton — jamais l'échu au nominal : dans le rail, une carte nominale replie ses
  commandes et les rouvre en échéant, ce qui est une décision antérieure et une autre question.
· **LE LIBELLÉ RÉSERVE SES DEUX LIGNES (corrigé dans la foulée)** : en échéant, « Réévaluation
  après adrénaline » devient « ■ … — à réévaluer » et passait de UNE ligne à DEUX — carte 200 →
  214 px à 320. Le clamp à deux lignes BORNE le maximum, il ne fixe pas la hauteur : c'est
  `min-height:2lh` qui la fixe, sur `.rt-dock .tmcard .tm-label` (pas sur les compteurs, qui ne
  changent pas d'état). **On ne raccourcit pas le libellé à la place** — le suffixe dit ce qu'il
  faut FAIRE (action au pied de l'alerte), et le retirer ne garantirait rien : un nom qui tient
  tout juste sur une ligne se remettrait à enrouler pour le seul glyphe « ■ ». Coût dit : +14 px
  sur une carte à libellé court en colonne unique ; à 390 px la carte valait DÉJÀ 214 des deux
  côtés — la réserve harmonise plus qu'elle ne coûte.
· **EXCEPTION NOMMÉE, DANS LE RAIL** : une carte de minuteur y replie ses commandes et les ROUVRE
  en échéant (+6 px, mesurés). C'est une décision antérieure et elle est juste — les commandes
  d'une alarme doivent être sous la main à l'instant où elle sonne (ECAM : l'action au pied de
  l'alerte). Ne pas la « corriger » en supprimant la révélation.
· **⚠ MESURER LE CAS, PAS LE CORRECTIF** : depuis la réserve, la BOÎTE du libellé fait deux lignes
  dans les deux états — un témoin qui mesurerait sa hauteur mesurerait le correctif. On compte les
  lignes du TEXTE (`Range.getClientRects()`), insensibles au `min-height`, et **à 320 px seulement**
  (à 390 la colonne fait 136 px, le libellé y occupe déjà deux lignes des deux côtés : le contrôle
  y resterait vert sur le défaut).

**A35. LE SÉLECTEUR SEGMENTÉ EST UN COMPOSANT À N SEGMENTS (v5.6, signalé à l'usage : « le fond qui
glisse est trop large », « A–Z / Catégories devrait être comme les autres »).** La mécanique à N
vivait sur un `#id` (le sélecteur de taille de texte, v4.71.1) : ailleurs, la pastille était
dimensionnée par `flex:1`, **qui n'égalise pas deux libellés de longueurs différentes**
(`min-width:auto` recale chaque item sur son texte — mesuré 79 px de pastille pour un bouton de
43). Le composant porte désormais des PISTES DE GRILLE (`--seg-n`, `--seg-i`, `--seg-gap`) : la
pastille vaut une piste, par construction, quel que soit le nombre de segments. La mécanique à
DEUX est laissée intacte (`.seg.i1` continue de piloter la tab bar historique et « Créer »).
· **`.grp-seg` est un HABILLAGE, pas une seconde mécanique** : le groupement de l'accueil garde son
  fond et son contour, il ne réimplémente rien.
· **⚠ PIÈGE DE CASCADE** : `.seg` est déclarée ~4 000 lignes plus bas que la variante ; à
  spécificité égale, l'écart de gouttière était silencieusement ignoré — d'où `.seg.grp-seg`.
· **⚠ ET LA PASTILLE PREND LE REGISTRE DU COMPOSANT, jamais un aplat sombre** : mesuré 1,04:1 sur
  le libellé actif, la sonde d'`audit-a11y` remontant les ancêtres et trouvant un fond sombre sous
  une encre claire. Un objet en position absolue derrière du texte est un FOND, pas une décoration.

**A36. L'EN-TÊTE A UNE SEULE HAUTEUR, QUELLE QUE SOIT LA VUE (v5.6, signalé à l'usage).** Accueil et
lecture ne s'accordaient pas : le champ de recherche imposait sa hauteur propre à la rangée
d'identité. La rangée porte un `min-height` et le champ se règle en REMBOURRAGE — une rangée de
chrome dont la hauteur dépend de son contenu est une rangée qui se déplace en changeant de vue, et
tout le chrome de crise s'y ancre (`--hdr-h`, `stickBase()`).

**A37. LE VOLET DU DOCK A LA BOÎTE DE LA BARRE FLOTTANTE, ET IL EN EST SÉPARÉ (v5.6, signalé à
l'usage : « n'est plus adapté à la nouvelle taille de la barre, et est décalé »).** Depuis A24 la
barre s'aligne sur la COLONNE D'ACTION : le volet de ⏱/⚡ suit donc la même géométrie — mêmes
marges de grille, jamais la largeur de la fenêtre. Il se pose AU-DESSUS de la barre, à `--dock-h`
(hauteur MESURÉE, posée par `syncDock`) plus un écart : la maquette le montre légèrement détaché,
et un volet qui recouvrirait ses propres touches masquerait le geste qu'on vient de faire. Mesuré
identique à 390, 900 et 1280 px.

**A38. L'EXERCICE S'ARME, ET CE QUI S'ARME SE DÉSARME (v5.6, décision utilisateur).** Taper
« Exercice » ne démarre rien — comportement attendu, conservé —, mais il n'existait alors AUCUN
moyen de revenir en arrière : le mode restait armé jusqu'au démarrage. Re-taper la touche l'annule
(`cancelExercise`), et **le geste d'entrée dit ce qu'il va démarrer** (« Confirmé — démarrer
l'exercice » / « … la session ») : un bouton qui nomme autre chose que ce qu'il fait est la
première cause de mode confusion (FAA).

**A39. UN FILTRE POSÉ AGIT AUSSI EN RECHERCHE (v5.6, signalé à l'usage : « quand on change de
catégorie, rien ne se passe »).** Le cran (bibliothèque, catégorie) n'était appliqué qu'au
RÉPERTOIRE ; dès qu'on tapait, la liste passait en tri par pertinence et l'ignorait. Un filtre
visible qui ne filtre pas est pire qu'un filtre absent — c'est la règle « un filtre posé ne doit
jamais être invisible », prise par l'autre bout.

**A40. UNE FICHE D'UN SEUL BLOC EST UNE FICHE COMME LES AUTRES (v5.6, signalé à l'usage : « bloc mal
affiché, parcours inerte absent »).** Deux causes, une seule leçon. `hasFlow(f)` — « y a-t-il un
embranchement ? » — décidait de choses qu'il ne gouverne pas : l'existence du PARCOURS INERTE (une
fiche d'un bloc a un parcours : un bloc) et le mode de rendu. Et **le mode était résolu DEUX FOIS**,
au rendu et dans le binder, chacun avec sa formule : le compteur d'avancement restait figé sur
« 1/2 ». `readModeOf(f)` est la source UNIQUE, et la colonne d'orientation se conditionne à
l'existence de BLOCS, jamais à celle d'un embranchement.

**A41. UN CLIC QUI DÉPLACE LE FOCUS SE VOLE LUI-MÊME — LA LISTE DE LA v4.77.0 S'ÉTEND AUX PORTES
D'AJOUT (v5.6, signalé à l'usage : « ＋ Rappel n'enregistre pas ce que je viens de taper »).** Entre
`pointerdown` et `mouseup`, le champ perd le focus, la rangée referme ses outils (`:focus-within`),
la page se resserre — le bouton n'est plus sous le pointeur et **aucun `click` n'est émis**. Tout
contrôle voisin d'un champ éditable entre donc dans le `preventDefault` de `pointerdown`.
· **⚠ LEÇON DE SONDE, payée ici** : ma première mesure cliquait le bouton sans avoir fait défiler
  jusqu'à lui (y = 5 367) et concluait « ＋ n'ajoute jamais rien » — un diagnostic faux sur un
  défaut réel. Une sonde qui clique hors écran mesure l'écran, pas l'application.
· **⚠ ET UN `.click()` PROGRAMMATIQUE NE DÉPLACE AUCUN FOCUS** : le témoin doit cliquer pour de
  vrai, sinon il reste vert sur les sept familles de listes.

**A42. UN LOT DISTANT S'APPLIQUE TOUJOURS ; SEULE LA PEINTURE DÉPEND DE LA VUE (v5.6, signalé à
l'usage : « en session partagée, les blocs disparaissent chez l'hôte et ne reviennent pas »).**
`onEvents` sortait sans rien appliquer dès que la vue n'était pas `read`, et **la perte était
DÉFINITIVE** : le curseur est avancé par l'appelant AVANT cet appel, donc le lot n'est jamais relu.
Il suffisait que l'hôte revienne à la bibliothèque pendant que le collègue avance. Le commentaire
disait « le pli suffit » — vrai chez l'INVITÉ, dont l'état EST le pli ; chez l'hôte la session
locale fait autorité et rien ne la rattrape. On applique donc toujours, et l'on MUSELLE la seule
queue qui pouvait déclencher un rendu complet, c'est-à-dire arracher quelqu'un à l'écran qu'il
regarde. Le `catch` vide disparaît avec : il laissait un lot à moitié appliqué sur un curseur déjà
avancé.

**A43. UN OBJET PLEIN DOIT SE DÉTACHER DE SON FOND — LA PASTILLE DU COMPTE EN SOMBRE (v5.6,
signalé à l'usage).** Mesuré : le bouton Compte et la barre valent tous deux `--sys` en thème
sombre, soit **1,00:1**. Les initiales restent lisibles (14,4:1) — ce n'est donc pas un défaut de
TEXTE, et `audit-a11y`, qui mesure le texte, ne pouvait pas le voir : c'est la LIMITE DU COMPOSANT
que WCAG 2.2 § 1.4.11 protège. C'est le seul contrôle de la rangée à porter un APLAT (ses voisins
sont transparents et se lisent par leur glyphe, ce qui est leur nature) ; il reste un DISQUE
d'identité, on lui rend donc un filet plutôt qu'on ne le vide. `--ctl-line` (3,68:1 mesuré), en
ombre INTERNE et non en bordure — 36 px de dessin pour 44 px de cible, une bordure changerait la
boîte et l'alignement des quatre contrôles (A30). Le thème clair n'en a pas besoin : 15,8:1.

**A44. LE RAIL A→Z EST CENTRÉ SUR L'ÉCRAN, PAS DANS SA PROPRE BOÎTE (v5.6, signalé à l'usage).**
Sa boîte commence sous l'en-tête — la v5.0.0 l'y avait bornée pour qu'aucune lettre ne passe
derrière lui —, si bien que des lettres centrées DEDANS tombaient 58 px sous l'axe médian de
l'écran à 390 px (55 à 1280). On ne déplace pas la boîte : elle garde toute la place disponible,
donc le rail continue de s'afficher sur un alphabet complet. C'est le DÉCALAGE du premier
caractère qui est posé (`azrCentrer` : la colonne passe en `flex-start`), **clampé à la place
réellement disponible** — rendre plus rognerait des lettres, et une lettre coupée est injoignable
en silence.
· **LA CIBLE SE MESURE, ELLE NE SE DÉDUIT PAS** : le haut de la boîte vaut le bas de l'en-tête en
  voie étroite, mais PAS en voie large (110 px mesurés pour un en-tête de 61) — une formule
  « rends la hauteur de l'en-tête » y laissait 24 px d'écart.
· **LA HAUTEUR DE RÉFÉRENCE EST `documentElement.clientHeight`** : la seule qui ne suive NI la
  barre d'outils NI le clavier. Le calcul ne tourne qu'au rendu et au redimensionnement — rien qui
  bouge pendant qu'on vise (leçon v5.0.2, et c'est le même objet qui l'avait enseignée).
· **LA CLASSE N'EST POSÉE QU'UNE FOIS LE DÉCALAGE CALCULÉ** : avant, les lettres restent centrées
  dans leur boîte — jamais collées en haut le temps d'une image.

**A45. « VÉRIFIER » EXISTE SUR TOUT BLOC D'ÉTAPES — CORRECTION DE A7 (v5.6, signalé à l'usage :
« où est passé le bouton vérifier ?? »).** En écrivant A7 j'avais ajouté une condition que la
maquette ne demande pas : « seulement si le bloc porte des challenges “::” », au motif que « sans
::, il n'y a rien à rejouer ». **C'est faux**, et la doctrine v4.11.0 le dit depuis toujours : la
passe Do-Verify « redéroule TOUTES les étapes, déjà cochées comprises », et ses deux réponses —
« Constaté ✓ » qui coche, « △ Écart » qui avance sans cocher — ne dépendent d'aucune réponse
attendue. Le « :: » ENRICHIT la passe, il ne la conditionne pas. La condition rendait le bouton
invisible sur toute fiche qui n'écrit pas de challenges, c'est-à-dire presque toutes. Le libellé
perd son « :: » avec elle : un bouton ne nomme pas une syntaxe que le bloc n'emploie peut-être pas.
La PLACE ne change pas (pied de carte, à gauche de « Continuer ») et un bloc de DÉCISION en reste
exclu — il n'a pas d'étapes à re-constater.

**A46. UN TÉMOIN D'ANCRAGE NE MESURE RIEN S'IL EST COLLÉ AU BAS DE LA PAGE (v5.6, trouvé en
restaurant « Vérifier »).** Le témoin d'ancrage travaillait sur une fiche de six étapes : 982 px de
document pour une fenêtre de 900, donc un défilement collé au MAXIMUM. Décocher après la fin retire
la bannière de fin, la page raccourcit, **le navigateur rabat le défilement** — et les 22 px de
rabat étaient imputés à l'ancrage, qui ne peut rien contre une fin de page. Un simple bouton rendu
à la carte déplaçait cette limite et faisait rougir un correctif juste. Le témoin vérifie
désormais qu'il n'est PAS au bout, et sa fiche a de quoi défiler.
⚠ ET IL FAUT DIRE CE QU'IL PROUVE : sur ce chemin, rien ne change au-dessus de l'ancre — neutraliser
la compensation le laisse vert. Le contrôle de dérive est donc un GARDE ; celui qui est capable
d'échouer est « le remplacement est ANCRÉ » (un re-rendu nu le fait rougir).

**A47. UNE SORTIE DE MODE SE MET AU BOUT DE LA LIGNE QU'ELLE FERME (v5.6, signalé à l'usage : « sur
vérifier, l'option pour fermer ne tient pas sur une ligne — texte et croix ne sont pas sur la même
ligne, même en desktop »).** L'en-tête d'une carte de bloc est fait pour porter le titre sur toute
la largeur et les gestes DESSOUS (`.ov-tgl{flex:1 1 100%}`) : c'est juste pour « ↺ Refaire », qui
est une action de la LISTE, et faux pour la sortie d'un MODE — mesuré, le ✕ tombait seul sur une
seconde ligne, y compris à 1280 px, pour 133 px d'en-tête (89 après). Sa cible passe en outre à
44 px de LARGE : elle n'en faisait que 31, la règle n'ayant jamais été vérifiée sur un bouton qui
ne porte qu'un glyphe. Modificateur préfixé par son composant (`.ov-block.vfy`), en (0,3,0) :
il gagne quel que soit l'ordre de déclaration.

**A48. VINGT-DEUXIÈME DÉFAUT DE RANGÉE FLEX — L'EN-TÊTE DE BLOC DE L'ÉDITEUR (v5.6, trouvé au
BALAYAGE, pas signalé).** `nowrap` avec DEUX objets incompressibles (pastille, sélecteur de phase
à 191 px) et un seul capable de céder : le champ TITRE tombait à **26 px** pendant que la poignée ⠿
sortait de **35 px** du cadre, à 320. Même famille que la v4.74.0 (bandeau de déplacement) et la
v4.55.3 (croix du panneau) — quand tout est incompressible sauf un, c'est cet un-là qui paie, et le
débordement part par le côté opposé. **On enroule, on ne tronque jamais** : à l'étroit, phase et
poignée descendent d'une ligne et le titre garde 221 px ; à 1280 tout revient sur une rangée.

**A49. UN RENDU NE DOIT PAS S'INTERROMPRE LUI-MÊME (v5.6, trouvé au balayage).** Un champ d'étape
VIDE se supprime au départ du focus (MK-flux) — mais ce `blur` peut être celui du RENDU : remplacer
le contenu de `main` retire le champ focalisé, donc l'émet. Re-rendre depuis là revient à écrire
dans `main` pendant qu'on y écrit ; Chrome lève « The node to be removed is no longer a child of
this node », **le rendu extérieur avorte en plein milieu**, et ce qui le suivait — câblage des
écouteurs, restitution du focus, ancrage — ne s'exécute jamais. Un simple redimensionnement suffit
à le produire.
· **DEUX GARDES, ET LA SECONDE EST LA VRAIE** : on sort de la pile courante (`setTimeout`), et l'on
  ne supprime QUE si aucun rendu n'a eu lieu **depuis la POSE de l'écouteur** (`_renderN`).
· **⚠ DEUX DISCRIMINANTS ÉCARTÉS À LA MESURE** : `inp.isConnected` — au moment où l'évènement part,
  le nœud est encore attaché ; et le compteur lu AU BLUR — la trace est « render → renderEditor →
  blur », donc le rendu fautif a déjà incrémenté. Seule la valeur capturée au BIND répond à la
  vraie question : cet élément appartient-il encore au rendu courant ?
· **CE QUE CELA CHANGE POUR L'AUTEUR** : une ligne vide survit à un re-rendu qu'il n'a pas demandé.
  C'est voulu — ce n'est pas lui qui a quitté le champ.

**A50. DEUX BOÎTES QUI SE TOUCHENT NE FONT PAS DEUX NOIRS QUI SE TOUCHENT (v5.6, signalé à l'usage :
« le noir du bandeau ne touche pas le noir du début du menu »).** Le bas de la capsule et le haut du
volet étaient DÉJÀ au même pixel, mêmes bords, même largeur — mesuré. Ce qui se voyait n'était pas
un écart de géométrie mais un écart de PEINTURE : le quai porte 8 px de rembourrage sous la capsule,
il est de la matière d'AMBIANCE, et il peignait par-dessus le haut du volet (z 15 contre 14).
Le volet monte donc à **z 16**, entre le quai et l'en-tête.
· **V2 EST INTACTE** : le volet COMMENCE au bas de la capsule, il ne peut rien couvrir d'elle — il
  ne recouvre que le rembourrage, qui n'affiche rien.
· **⚠ ET LE TÉMOIN DE V2 MESURAIT LE MÉCANISME** : il exigeait `z(quai) > z(volet)`, donc il a
  rougi sur un correctif juste. Il mesure désormais la PROPRIÉTÉ que V2 promet — la capsule ne
  bouge pas et rien ne la recouvre (`elementFromPoint` en son centre).
· **ON MESURE LA COULEUR EFFECTIVE, PAS LES RECTANGLES** : c'est en remontant jusqu'au premier fond
  opaque que le défaut se voit ; comparer les boîtes laissait le témoin aveugle.

**A51. LE VOLET SE DÉROULE, EN `transform` PUR (v5.6, proposition de l'auteur).** L'animation répond
à un GESTE — elle ne survient pas toute seule : c'est la distinction que le dossier fait déjà pour
l'élévation de l'en-tête (A27) et la chip épinglée. **On ne peut pas animer une hauteur**
(`check-anim` : une propriété de mise en page coûte une passe de layout par image, v4.41.0), donc le
déroulé est un `scaleY` depuis le HAUT, **avec le contre-scale exact sur le contenu** — la boîte se
déroule, le texte ne s'étire pas. 180 ms, aucun résidu à la fin (mesuré), inerte sous
`prefers-reduced-motion` (la règle vit dans le bloc `no-preference`, donc l'inertie est acquise par
construction et non par une seconde règle à tenir).

**A52. « VÉRIFIER :: » GARDE SON LIBELLÉ DE MAQUETTE (v5.6, décision de l'auteur).** A45 avait
retiré la CONDITION (le bouton existe sur tout bloc d'étapes) et, dans la foulée, le « :: » du
libellé. C'était une correction de trop : le « :: » nomme la PASSE — challenge-réponse —, il
n'annonce pas un pré-requis du bloc. La maquette l'écrit ainsi ; le mot revient.

**A53. DEUX BOÎTES QUI SE TOUCHENT DOIVENT AUSSI S'ACCORDER PAR LEURS COINS (v5.6, signalé à
l'usage : « il reste des px blancs »).** Après A50, capsule et volet se touchaient au pixel, même
largeur, même noir — et il restait deux encoches claires : la capsule est ARRONDIE en bas, le volet
VIF en haut, et le fond de page passait dans les angles. Tant que le volet est ouvert, la capsule
perd ses coins bas (`body:has(.rt-dock)`). Un seul objet à deux étages : arrondi en haut, arrondi
en bas, jointure franche.

**A54. « ✓ VU » NE DOIT PAS COUPER SES VOISINS (v5.6, signalé à l'usage : « le texte est un petit
peu tronqué »).** Deux endroits, deux réponses, et la même règle — un mot COUPÉ est moins lisible
qu'un mot absent, et personne ne doit deviner un libellé.
· **DANS LE VOLET**, la remise à zéro porte deux lignes (« ↺ 05:00 » et l'indice « maintenir »),
  ~118 px de texte ; à côté de « ✓ Vu », dans une colonne de 160 px, il lui en restait 75 et
  l'indice sortait en « MAINTEN… ». L'indice s'efface TANT QUE l'acquittement est là — le maintien
  reste, son `title` et son nom accessible le disent, et l'indice revient dès l'alarme acquittée.
· **DANS LE RAIL**, la rangée fait 140 px et ne s'enroule pas : « Relancer » y tenait à ZÉRO pixel
  près (90 px de bouton pour 78 de contenu et 12 de rembourrage), donc coupé dès qu'une fonte rend
  deux pixels plus large. Rétrécir l'acquittement ne rendait que quatre pixels — dans une colonne
  de 301 px la valeur du minuteur prend déjà la moitié. La rangée ENROULE donc tant que « ✓ Vu »
  est là, ce qui est cohérent avec la décision antérieure du rail (une carte échue ouvre ses
  commandes) ; le coût d'une ligne est TRANSITOIRE, il disparaît au premier acquittement.

**A55. LE CHEVRON DU CHAPEAU VIT DANS LA PASTILLE DU COMPTE (v5.6, demande de l'auteur).**
« 4 › » est UN objet : la pastille dit à la fois combien il reste de rappels et qu'elle se déplie.
⚠ CONSÉQUENCE IMMÉDIATE, mesurée : le repli écrivait `textContent` sur la pastille, ce qui EFFACE
son enfant — le chevron disparaissait au premier dépliage. Le compte a donc son propre porteur
(`.fs-cnt`), et l'on n'écrit plus que dedans. Règle générale : **dès qu'un nœud gagne un enfant,
tout `textContent` posé sur lui devient une suppression.**

**A56. 43 px, C'EST UN PIXEL DE TROP PEU (v5.6, trouvé au balayage étendu).** En lecture, le retour
d'en-tête se resserre et son halo de −6 px rendait une cible de **43 × 52** — sous les 44 px de la
zone haute, invisible à l'œil et hors du champ d'`audit-a11y`, qui mesure les surfaces AU REPOS et
non la barre en session. Un pixel de halo de plus, aucune géométrie déplacée : c'est exactement ce
pour quoi le halo existe. Il a désormais son contrôle dans la section de la rangée d'actions.
⚠ **CE QUE LE BALAYAGE A ÉCARTÉ, ET POURQUOI C'EST À DIRE** : le ✕ des fenêtres « sort » de 10 px
de l'en-tête de sa carte — c'est le halo compensé qui lui donne ses 44 px, son bord reste DANS la
carte (mesuré) ; et les contrôles de l'accueil à 32/38 px sont au plancher HORS crise, où la règle
des 44 ne s'applique pas. Un balayage qui ne nomme pas ses non-défauts finit par les faire
« corriger ».

**A57. « T+ » SE COMPTE DEPUIS LE DÉBUT DE LA SESSION, PARTOUT (v5.6, signalé à l'usage : « passé
minuit, le journal ne montre la différence qu'à partir de minuit »).** Ce n'était PAS un défaut de
minuit — toutes les durées du fichier sont des différences d'horodatages, insensibles au changement
de date, et `fmtMs` tient au-delà de 24 h (vérifié : un repère à 00:30 d'une session de 23:30
affiche « +1:00:00 »). C'était une RÉFÉRENCE divergente : le journal partait du PREMIER REPÈRE,
quand le compte rendu, l'accusé du volet ⏱ et la trace d'un compteur partent tous de `startedAt`.
Deux origines pour un même « T+ », donc deux vocabulaires pour une idée (§ 5.5) — et celle du
journal trompait dès qu'on notait le premier repère longtemps après le début.

**A58. UN OBJET SANS NOM EXISTE QUAND MÊME (v5.6, signalé à l'usage : « un compteur sans nom ne
s'affiche pas dans Noter l'heure »).** Confirmé : `tagAll` jetait tout objet dont le libellé est
vide, alors que sa CARTE affiche un nom par défaut — l'objet était donc visible à l'écran et
introuvable au moment de l'horodater. Le vivier reprend LE MÊME défaut que la carte (« Compteur »,
« Minuteur », « Chronomètre »), jamais un mot inventé pour l'occasion. Un REPÈRE sans étiquette,
lui, garde sa règle propre (« Action n ») : c'est une trace, pas un objet de la fiche.

**A59. UN MENU QUI S'OUVRE NE DÉPLACE PAS LA PAGE (v5.6, signalé à l'usage).** `focus()` sur la
première rangée du menu ⋯ faisait remonter le document de **399 px** à 390 px — le navigateur amène
l'élément focalisé dans la vue en respectant le `scroll-padding`, et il le fait même pour un menu
`fixed`. `focus({preventScroll:true})` : le menu s'ouvre sous le doigt, à position constante, et
rien ne bouge derrière lui. Même remède qu'au re-rendu d'une ligne d'éditeur (v4.78.0).

**A60. UNE LIGNE-BILAN BASCULE, ELLE NE FAIT PAS QUE DÉPLIER (v5.6, signalé à l'usage).** Le geste
écrivait `false` en dur : le groupe des blocs faits s'ouvrait et ne se refermait plus, alors que sa
TÊTE reste à l'écran avec un chevron « ⌃ » qui promet l'inverse. Un contrôle qui survit à son geste
doit pouvoir le défaire, sinon c'est un bouton mort qui ment. Le repli reste PERSISTANT et le
dépliage une consultation transitoire (`ovDropOpens`) : seul le sens du tap change.

**A61. UNE PLACE RÉSERVÉE VAUT LA TAILLE DE L'OBJET RÉSERVÉ (v5.6, signalé à l'usage : « le ✕ se
superpose à “Son activé” »).** L'en-tête du panneau réserve un couloir à droite pour son ✕ ancré :
40 px, quand celui du volet en fait 48 — les 8 px manquants ÉTAIENT le recouvrement, mesuré à 600,
700 et 768 px (le seul régime où la rangée tient sur une ligne). La réserve vaut désormais 48 + 8
d'écart : deux cibles de 44 px qui se TOUCHENT sont déjà un défaut (règle du rail A→Z).

**A62. LA SORTIE D'UN MODE SE MET SUR LA LIGNE QUI NOMME LE MODE (v5.6, signalé à l'usage — suite
d'A47).** Le ✕ avait rejoint la ligne du TITRE du bloc ; l'auteur visait plus loin : le seul texte
qui nomme la passe est « Vérification — lisez le challenge… », et un glyphe nu ne dit pas ce qu'il
ferme. La sortie descend donc sur cette ligne et porte son VERBE (« ✕ Quitter ») ; le NOM du mode et
sa sortie tiennent sur une rangée à toutes les largeurs, la consigne passe dessous en casse normale
(mesuré : 85 → 44 px de rangée sous 780 px), et l'en-tête du bloc perd une rangée.

**A63. LE CHEVRON DU CHAPEAU N'ÉTAIT PAS TRONQUÉ, IL ÉTAIT ÉTOUFFÉ (v5.6, signalé à l'usage).**
`line-height:1` lui donnait une boîte de 11 px pour un glyphe qui en occupe 14 : il débordait des
deux côtés et se posait 3 px sous le chiffre. Il prend l'interligne de la pastille, et les deux
enfants s'alignent sur leur milieu.

**A64. LE DÉCLENCHEUR DE FILTRES EST UN BOUTON ROND, GLYPHE SEUL (v5.6, demande de l'auteur, « comme
sur Apple »).** Trois filets horizontaux qui RÉTRÉCISSENT de haut en bas (16 · 10 · 4 dans une boîte
de 24, écart constant de 5 px), 38 px de dessin — la hauteur du sélecteur d'en face, deux contrôles
d'une même rangée qui ne font pas la même hauteur se lisant comme deux niveaux — et 46 px de cible
par le halo. Le mot « Filtres » disparaît (`.filt-l` purgée, règle 14) : sur la rangée la plus
disputée du produit, un contrôle à POSITION CONSTANTE s'apprend par sa forme.
⚠ **LA RÈGLE 8 TIENT PAR LE NOMBRE** : l'état actif est dit par le COMPTE de filtres posés, en
pastille sur le coin — jamais par la seule couleur —, et le nom accessible l'écrit en toutes
lettres. La pastille est POSÉE SUR le bouton et ne l'allonge plus : la position du déclencheur ne
doit pas dépendre du nombre de filtres.

**A65. UN COMPOSANT À N SEGMENTS N'EMPORTE PAS LE RACCOURCI À DEUX (v5.6, signalé à l'usage : « la
bulle ne glisse pas d'une option à l'autre »).** Deux causes, et la seconde est un piège de
spécificité : (a) le rejeu du glissement appelait `.seg-replay`, classe PURGÉE en v5.0.0 avec le
composant qu'elle servait — l'appel était resté, donc un no-op ; (b) le sélecteur émettait AUSSI
`.i1`, dont la règle `.seg.i1 .seg-pill` (0,3,0) bat le transform piloté par `--seg-i` : tant que la
classe est là, reposer la variable ne déplace RIEN. Le composant à N ne porte donc plus `.i1`, et le
rejeu repose la pastille à l'ANCIEN cran sans transition, force le calcul, puis pose le nouveau —
c'est la transition CSS qui fait le trajet (mesuré : 21 → 46 → 74 → 94 → 102).
⚠ **ET LA LEÇON DE SONDE** : ma première mesure gardait une référence à la pastille À TRAVERS le
re-rendu — un nœud détaché, qui rend une position figée et une transition vide. On re-interroge le
DOM à chaque échantillon.

**A66. UN HALO NE MORD JAMAIS SUR LA CIBLE DU VOISIN — ET UNE CIBLE PARTAGÉE EST FICTIVE (v5.6,
BALAYAGE DE COLLISIONS, rien de signalé).** Une sonde nouvelle : elle compare deux à deux les zones
tactiles (dessin + halo) de tous les contrôles d'un même PLAN — un dock, un volet ou une fenêtre
recouvre le contenu par construction, c'est son office, et ces paires-là sont écartées. Elle a
trouvé quatre recouvrements, tous invisibles à l'œil :
· **en-tête de l'accueil**, « Créer » ∩ « Compte » : **10 px à 320**, 4 à 390 — deux halos de 6 px
  pour 2 px d'écart. Dans cette bande, c'est le DERNIER élément du DOM qui reçoit le tap : on
  visait Créer, on ouvrait le Compte ;
· **barre de l'éditeur**, « ▶ Essayer » ∩ « ⋯ » : 4 px à 320, 2 à 390 ;
· **rangée de l'annuaire**, le bouton-titre ∩ la pastille « △ à compléter » : 13 px ;
· **volet du quai**, deux boutons de minuteur empilés : 2 px (halos de 4, écart de 6).
**LA RÈGLE QUI EN SORT** : un halo se borne à la MOITIÉ de l'écart qui le sépare de son voisin, et
un écart vaut au moins la somme des halos qu'il sépare. Le halo VERTICAL, lui, reste entier quand
rien ne le dispute — c'est la direction où l'on a de la place.
**⚠ ET UN ARBITRAGE À CONNAÎTRE, car il RELÂCHE une règle écrite** : à 320 px, deux cibles de 44 px
de large ne tiennent pas dans une rangée qui n'a que 2 px d'écart. On garde donc les **44 px de
HAUTEUR** et l'on borne la LARGEUR à la place réellement disponible (34 px à 320, 40 à 390) — au
-dessus du plancher de 32 px, qui est la règle HORS crise, et c'est bien de l'accueil qu'il s'agit.
Le témoin de la rangée d'identité mesure désormais les trois choses : hauteur ≥ 44, largeur ≥ 32,
et AUCUN recouvrement. Il exigeait 44 en largeur — une exigence qu'aucune géométrie ne pouvait
honorer sans voler la cible d'à côté.
**⚠ UN CAS RÉSISTE, ET IL EST DIT** : dans la rangée de l'annuaire, le titre et la pastille
« △ à compléter » sont séparés de 4 px de texte, et la rangée a un RYTHME fixe de 71 px. Les deux
cibles ne peuvent pas être conformes (≥ 24) ET disjointes ; réduire le titre le fait tomber à 22 px
(`audit-a11y` l'a dit immédiatement). On garde les deux conformes, et les 5 px résiduels se
résolvent en faveur de la pastille, qui est AU-DESSUS — la cible la plus petite et la plus précise
gagne, le titre gardant 38 px de bande franche.
**⚠ LEÇON DE SONDE, deux fois** : (a) « visible » ne veut pas dire « peint » — un élément dans un
panneau replié ou une boîte clipée garde un rectangle non nul, et la sonde a d'abord vu une puce de
catégorie « recouvrir » une poignée qui vit 200 px plus haut ; on exige donc que l'élément soit la
cible du point en son centre. (b) Le halo se lit par axe : `insetBlockStart` est le VERTICAL, et
mesurer une largeur avec lui laisse la sonde aveugle à sa propre correction.

**A67. `--line-strong` N'EST PLUS LE TOKEN DES BORDURES DE COMPOSANT — C'EST `--ctl-line` (v5.6,
trouvé au balayage).** La doctrine écrit depuis la v4.5 que « cases à cocher et bordures de champs
= `--line-strong` (3:1, WCAG 1.4.11) », et la v5.0.0 le mesurait à 3,93 / 4,94. **La palette v5.6
l'a re-valué** : il ne tient plus que **1,62:1 en clair et 1,33 en sombre** sur la matière de
travail. Celui qui tient le seuil est `--ctl-line` — c'est d'ailleurs ce que dit A43. Les contrôles
qui s'appuyaient sur `--line-strong` pour leur LIMITE passent donc à `--ctl-line` : la rangée
« Consulter » (un bouton pleine largeur dont ni le fond — 1,09:1 — ni le filet ne se voyaient), le
déclencheur de filtres, « Vérifier :: » et la sortie de la passe.
· **`--ctl-line` EST ASSOMBRI D'UN CRAN EN CLAIR** (#8a94a0 → #828c98) : il tenait 3,08 sur le blanc
  du travail mais 2,82 sur le gris d'AMBIANCE, où vivent aussi des contrôles bordés. 3,13 et 3,41
  après ; le sombre tenait déjà (3,68 / 4,05).
· **CE QUI N'EST PAS CHANGÉ, ET POURQUOI C'EST À VOUS** : en thème SOMBRE, la matière de travail et
  l'ambiance ne sont séparées que de **1,10:1**, et le filet des cartes (`--work-line`) de 1,33 —
  une carte de bloc n'a donc, la nuit, ni ombre (doctrine : « la nuit ne projette pas, elle borde »)
  ni bord perceptible. Idem pour la capsule sur son quai. Renforcer ces filets « grillagerait » tout
  le thème sombre : c'est une décision de signature, pas un correctif, et elle vous revient.

**A68. LA NUIT, LA MATIÈRE DE TRAVAIL SE DÉTACHE ET SON FILET TIENT LE SEUIL (v5.6, variante C
choisie sur maquettes).** Mesuré avant : travail contre ambiance **1,10:1**, filet contre travail
**1,21:1** — une carte n'avait donc, la nuit, ni ombre (« la nuit ne projette pas, elle borde ») ni
bord perceptible, et sur une colonne de cartes c'est le COMPTAGE qui échoue, pas la lecture.
`audit-a11y` ne pouvait pas le voir : il mesure le TEXTE, et le texte était à 14:1.
Après : `--work` #171a20 → **#1e232b** (matière 1,22:1) et `--work-line` #262a31 → **#667080**
(filet **3,15:1**, seuil de WCAG 2.2 § 1.4.11).
· **DEUX CANAUX PLUTÔT QU'UN, ET C'EST LE MOTIF DU CHOIX** : renforcer le seul filet (variante A,
  3,68:1 sur la matière inchangée) tenait le seuil aussi, mais chargeait le TRAIT — sur des cartes
  empilées le dessin se rapproche d'une grille, ce que « verre clinique » cherche à éviter. Ici la
  matière fait la moitié du travail, donc le trait peut rester fin.
· **`--sys` NE BOUGE PAS** : la capsule et le dock sont de la matière SYSTÈME. Effet second et
  bienvenu — les deux matières, jusque-là identiques la nuit (1,00:1), se distinguent désormais.
· **COÛT MESURÉ** : l'encre principale passe de 14,4 à **13,1:1** sur la carte. Le thème clair
  n'est pas touché.
· **⚠ CE QU'UNE MATIÈRE PLUS CLAIRE ENTRAÎNE, ET QU'UN TÉMOIN A ATTRAPÉ** : le placard d'exercice
  est un aplat `--primary-soft` posé SUR cette matière — l'écart entre les deux bandes est tombé de
  44 à 26 (seuil 30), c'est-à-dire que la hachure d'exercice redevenait douteuse la nuit, le défaut
  même que la v4.28.0 avait corrigé. `--primary-soft` se creuse donc par le BLEU (#13233a →
  #12263f, écart 35) : on rend l'écart sans rendre la teinte plus claire.
· **TÉMOIN** : dans la section A9/A6/A11, qui monte déjà le décor — on bascule le thème, on mesure,
  on le rend. Quatre contrôles : limite ≥ 3:1, matière détachée de l'ambiance, SYSTÈME ≠ TRAVAIL,
  et l'encre qui ne paie pas la note. Vérifié capable d'échouer (tokens d'avant → 3 rouges).

**A69. REPLIÉE, LA CARTE EST UN STATUT D'UNE LIGNE — ET CETTE LIGNE EST CENTRÉE DANS LA CARTE
(v5.6, signalé à l'usage, puis re-signalé).** L'en-tête d'une carte OUVERTE est fait pour deux
rangées — l'étiquette et le compte au-dessus, le grand titre en dessous (`.ov-t{flex:1 1 100%}`,
aligné sur les BASELINES). Replié, la même mise en page donnait une boîte de **73 px** où le numéro
et le compte flottaient 23 px au-dessus du milieu et le titre 7 en dessous.
· **UNE SEULE LIGNE, ALIGNÉE SUR LE MILIEU** : tout y tient côte à côte, le titre prend la taille du
  texte courant et s'ellipse — il revient en entier au dépliage, qui est à un tap. 73 → 44 px.
· **ET L'ORDRE SUIT LA LECTURE** : les `order` de l'en-tête ouvert placent le compte et le chevron
  AVANT le titre, parce qu'ils y vivent sur la rangée du dessus ; sur une seule ligne cela donnait
  « BLOC 1 · 0/5 ▾ · Mesures immédiates », l'état inséré au milieu de l'identité. Replié, on lit
  d'abord ce que c'est, ensuite où ça en est.
· **⚠ CENTRER LA RANGÉE NE SUFFIT PAS, IL FAUT CENTRER LA CARTE** (le second signalement) :
  `.ov-head` porte `padding:18px 18px 0` — juste quand le corps suit en dessous, faux quand
  l'en-tête EST la carte. Mesuré : 31 px au-dessus du texte contre 13 en dessous, soit 9 px sous
  l'axe. Rembourrage symétrique en replié, retrait à gauche inchangé.
· **RÈGLE GÉNÉRALE** : un alignement se mesure sur les CENTRES, jamais sur les hauts — deux objets
  de tailles différentes n'ont pas le même haut. Et une mise en page pensée pour un état ne se
  transporte pas telle quelle dans l'autre.

**A70. UNE SECTION RESPIRE AUTANT DES DEUX CÔTÉS DE SON FILET (v5.6, signalé à l'usage : « le
journal replié s'affiche avec plus d'espace en bas qu'en haut — et même déplié vide »).** Le panneau
du journal posait toute sa respiration d'un seul côté (12 px sous son filet, rien après son contenu,
`padding:12px 0 0`) : replié, il n'a qu'un TITRE, et ce qu'on lisait alors était 12 px au-dessus
contre les 16 px de fin de volet en dessous. Rembourrage symétrique — dans le volet ET dans le rail
(`.rail-fold`, qui portait la même faute) —, et la fin du volet passe de 16 à 12 px pour cesser
d'être comptée comme la respiration de la dernière section.
⚠ **UN PANNEAU QUI PEUT ÊTRE VIDE SE JUGE VIDE** : c'est l'état où l'asymétrie se voit le plus,
puisqu'il n'y a aucun contenu pour la masquer — le témoin mesure donc le panneau REPLIÉ.

**A71. LE LOGO SE CALIBRE SUR LE FÛT DU MOT, ET IL S'AMINCIT VERS L'INTÉRIEUR (v5.6, signalé à
l'usage : « le logo contraste avec l'épaisseur du texte “aides cognitives” »).** Mesuré au canevas
avec la police réellement embarquée : le fût de la Source Serif 4 à 17,5 px / 600 vaut **2,20 px**
(« A » perpendiculaire au jambage, « d » 2,20 ; « I » 2,35), quand le trait du glyphe en rendait
**2,70** — soit 123 % du fût. Un monolinéaire paraissant plus lourd qu'une romane à épaisseur
égale, la cible est 85-90 % : trait 56 → **40**, qui rend 1,93 px (88 %).
· **AUCUNE PROPRIÉTÉ CSS NE PEUT LE FAIRE** : `.brand-logo` pose `logo-glyph.svg` en MASQUE, dont
  seul le canal alpha compte — l'épaisseur vit dans le fichier. Et le fichier est GÉNÉRÉ
  (`scripts/build-icons.mjs`, une seule géométrie pour les onze sorties) : l'éditer à la main,
  c'est écrire une divergence que la prochaine génération effacera.
· **ON AMINCIT VERS L'INTÉRIEUR, RAYON EXTÉRIEUR GELÉ** (`R = R_OUT − SW/2`, R_OUT=228) : l'emprise
  d'encre GAUCHE est ce sur quoi la marge de page s'aligne, via les marges négatives calibrées de
  `.brand-logo`. Mesurée après : **x0 = 181, inchangée**. La borne droite, portée par la pointe de
  la coche, recule de 0,35 px à 34 — sous le demi-pixel, les marges restent au cran, et les
  chiffres du commentaire sont mis à jour (il documente des mesures, il ne doit pas mentir).
· **⚠ ET L'ONGLET N'A PAS SURVÉCU À L'AMINCISSEMENT — « le bouton sur le dessus dépasse »** : son
  pied était une corde HORIZONTALE calée sur le bord INTÉRIEUR d'un trait de 56. Une corde n'est
  contenue dans la bande que si `dy ≥ R_in` au milieu ET `hypot(144,dy) ≤ R_OUT` au bord : à 56 la
  fenêtre est [172 ; 176,8] et le dessin y tenait au pixel près ; à 40 elle est VIDE (188 > 176,8).
  Le pied pointait donc dans le vide de l'anneau. Il suit désormais le cercle **MÉDIAN**, donc il
  est enfoui de SW/2 de chaque côté quel que soit le trait, et ses extrémités sont CALCULÉES.
· **MÉDIAN ET NON EXTÉRIEUR, et c'est une leçon de rendu** : posés sur le même arc, l'onglet et la
  bande partagent une frontière EXACTE — chacun n'y couvre que la moitié du pixel et
  l'anticrénelage rend un LISERÉ CLAIR le long de la jonction. **Deux encres qui se touchent
  doivent se RECOUVRIR.**
· **UNE SEULE ÉPAISSEUR POUR LES ONZE SORTIES — SAUF SOUS UN PIXEL DE TRAIT, OÙ L'ON HINTE.** Deux
  épaisseurs CHOISIES feraient diverger le glyphe entre l'en-tête, l'onglet et l'écran d'accueil ;
  une compensation de RENDU n'est pas de ce genre. Sur la tuile, un pixel vaut 51,2 unités : à 40
  l'anneau du raster de 16 px ne rend que **0,78 px**, c'est-à-dire aucune ligne pleine — il se
  délave en gris et la coche disparaît. Ce raster garde donc le trait de 56 (1,09 px). C'est le
  hinting d'une fonte : sous ~1 px on ne choisit plus une épaisseur, on subit une grille, et le
  dessin doit s'y poser. La borne est étroite et elle le reste — 32 px rend déjà 1,56 px à 40, net
  et plus juste ; toutes les autres sorties partagent SW ; et personne ne compare un onglet de
  16 px à l'en-tête. **La variante n'est pas un second dessin** : la géométrie entière (rayon
  médian, coupure, pied de l'onglet) DÉCOULE de `sw`, donc les deux rasters sortent de la même
  fonction — un dessin recopié finirait par diverger.
· **CE QUI A ÉTÉ MESURÉ PUIS ÉCARTÉ** : « aligner le sommet de l'anneau sur la hauteur de capitale
  plutôt que sur la hauteur d'x ». La prémisse est fausse — mesuré à 390 px, l'anneau commence à
  **20,3** et la capitale à **21,2** : ils sont déjà alignés à 0,9 px près. Ce qui reste est un
  centre d'anneau 3 px sous le centre de la bande capitale, et c'est JUSTE : le mot porte un
  jambage descendant (« cognitives »), les deux boîtes sont centrées l'une sur l'autre, et une
  forme ronde doit déborder pour paraître de la même taille qu'une capitale à sommet plat.
· **⚠ CHANGER CES OCTETS NE CHANGE PAS CE QUI EST INSTALLÉ** : le nom de fichier ne bouge pas et le
  cache du service worker est versionné par `APP_VERSION` — un appareil déjà installé garde
  l'ANCIEN glyphe jusqu'au prochain `./release.sh X.Y.Z` (même piège que pdf.js, règle 1 : on
  n'édite JAMAIS `CACHE` à la main).

**A72. UN COMMENTAIRE QUI DÉCRIT UN ÉLÉMENT MORT LE FERA RÉINTRODUIRE — LES PURGES ONT UNE ÉPITAPHE
(v5.6, audit externe 9c).** Un commentaire affirmait AU PRÉSENT que « la POSITION reste portée par
la pilule `.ov-here` », purgée six lots plus tôt par A12 : zéro émission dans le fichier. Dans ce
dépôt les commentaires SONT la documentation de conception — celui-là aurait fini par faire remettre
la pilule, quelqu'un lisant la phrase, constatant l'absence, et « réparant » une régression.
· **LE CONTRÔLE EST DANS `check-classes`, PAS DANS UN DIX-HUITIÈME SCRIPT** : il y possède déjà les
  trois ensembles (émises · stylées · commentaires). Toute classe citée dans un commentaire de la
  feuille est VIVANTE, ou porte au moins une ÉPITAPHE — une mention de purge — quelque part.
· **⚠ CE QU'ON NE PEUT PAS MESURER, ET POURQUOI LA RÈGLE EST CELLE-LÀ** : la moitié des citations de
  classes mortes sont des RÉCITS (« cf. `.mode-seg` v4.25.1 » comme précédent de cascade), et elles
  sont légitimes. Distinguer un récit d'une affirmation au présent demanderait de lire le TEMPS des
  verbes — aucune regex ne le fait. On exige donc le vérifiable : purger sans épitaphe redevient
  bruyant, citer l'histoire reste libre. Deux classes en manquaient (`.mode-seg`, `.pl-cxh`).

**A73. LES TROIS GABARITS DE FENÊTRE SONT DES TOKENS, ET LE TÉMOIN BALAIE AU LIEU DE LISTER (v5.6,
audit externe 9b).** A25 avait FIXÉ les trois largeurs — 420 · 480 · 720 — mais en littéraux
répartis dans la feuille, et sept surfaces s'en étaient écartées. `--dlg-confirm` / `--dlg-std` /
`--dlg-atelier` : une surface DIT quel gabarit elle prend, elle ne recopie plus un nombre.
· **CE QUI EST RATTACHÉ** : `.boot-card` 440 → confirmation (une phrase, aucun champ),
  `.up-drag-card` (elle avait la bonne valeur, elle a maintenant le TOKEN), `#shareBody` 460 → 480
  (le commentaire disait déjà « la lecture redevient celle d'un dialogue » — le nombre ne le disait
  pas), et `.endsess-dlg` perd sa largeur propre : terminer une session EST une confirmation.
· **DEUX EXCEPTIONS NOMMÉES SUR PLACE, jamais rabattues** : `.alert-toast` (520) mesure une PHRASE
  et n'est pas une fenêtre — elle ne se ferme pas pour révéler ce qu'il y a derrière ; `.lightbox
  .cap` (600) est une mesure de LISIBILITÉ (~70 signes). La règle générale : *une largeur libre
  n'est légitime que si elle mesure autre chose qu'une fenêtre — un texte, un champ, une colonne —
  et le dit sur place.*
· **DEUX DES « SEPT » ÉTAIENT DES FAUX POSITIFS D'UN AUDIT STATIQUE** : `560px` apparaissait dans
  deux `@media`. Un palier n'est pas une largeur de modale, et rien dans le texte ne les sépare.
· **⚠ ET `.endsess-dlg` N'AVAIT AUCUN EFFET** : `.dlg-confirm .ai-card` (0,2,0) battait `.endsess-dlg`
  (0,1,0), donc ses 400 px étaient morts depuis toujours. C'est ce qui a fait que le témoin est
  resté VERT quand j'ai réintroduit le défaut pour l'éprouver — il a fallu un défaut qui MORD
  (`#endSessModal .ai-card`) pour le voir rougir. Une déclaration qu'on croit fautive peut n'être
  que du bruit ; on le vérifie avant d'en tirer une leçon.
· **LE TÉMOIN BALAIE (même leçon que 8f)** : il n'ouvrait que cinq fenêtres NOMMÉES, et c'est par là
  que les sept étaient entrées. Il mesure désormais le `max-width` calculé de TOUTES les `.ai-card`
  du document — `getComputedStyle` résout `var()` même sur un élément `display:none`, donc sans en
  ouvrir aucune.

**A74. LA GOUTTIÈRE DU RAIL A→Z APPARTIENT À LA PAGE, PAS AU RAIL (v5.6, signalé à l'usage :
« l'absence de rail redistribue la largeur des cartes… c'est moche quand ça repasse à plusieurs
cartes »).** La v5.0.3 avait déjà tranché cela pour la RECHERCHE, et la voie LARGE le tient sans
condition depuis toujours — mais la règle étroite était accrochée à `.azr-on`, c'est-à-dire à
l'EXISTENCE du rail. Bibliothèque vide, une seule lettre, ou rail retiré faute de hauteur : la
colonne récupérait ses 16 px, tout s'élargissait, puis rétrécissait au retour. `.azr-on` est PURGÉE
avec la condition qu'elle servait (règle 14, plus aucun lecteur).
· **ET LA RANGÉE DE CONTRÔLES PORTE SA PROPRE RESPIRATION** (second volet du même signalement : « le
  bouton filtre peut se coller au bloc du dessous »). `.grp-row` n'avait de marge qu'EN HAUT : avec
  des cartes l'écart venait du titre de section — donc d'un VOISIN —, et le bloc « Aucune aide »
  n'en apporte aucun (0 px mesuré). 12 px en bas, et cela ne coûte rien là où l'écart existait :
  **les marges de frères adjacents FUSIONNENT**, max(12,16)=16, donc le répertoire ne bouge pas d'un
  pixel. C'est un plancher, pas une addition.
· **⚠ UN TÉMOIN VOISIN A ROUGI SUR CE CORRECTIF JUSTE, ET IL AVAIT TORT** : il exigeait du
  déclencheur de filtres un bord droit à ≤ 20 px de la FENÊTRE — la géométrie du cas SANS rail.
  Avec la gouttière réservée il vaut 34 px avec rail comme sans, ce qui EST la constance
  recherchée. Il mesure désormais l'écart à la COLONNE (affleurement, ±2), qui ne dépend d'aucun
  rail. Un témoin calé sur un repère extérieur mesure autre chose que sa propriété.

**A75. LA QUESTION D'UNE DÉCISION EST SOUS SON TITRE DANS LA HIÉRARCHIE, DONC SOUS LUI DANS
L'ÉCHELLE (v5.6, signalé à l'usage : « titre du bloc et question s'affichent en même grandeur ->
perturbant »).** Les deux étaient à 21 px / 700. La question descend à `--t-step`, LE MÊME cran que
ses options `.opt` : une question et ses réponses sont un seul objet de lecture, et c'est le CADRE
des options qui les distingue, pas leur corps.
· **AUCUN GARDE-FOU STATIQUE NE POUVAIT LE VOIR** : 21 est sur l'échelle fermée, donc `check-type`
  était vert — ce n'était pas la VALEUR qui était fausse, c'était le RAPPORT. Une hiérarchie ne se
  mesure qu'au rendu et par comparaison ; le témoin compare les trois corps entre eux.
· **⚠ UNE RÈGLE DE PALIER QUI RÉPÈTE LA VALEUR DE BASE EST UNE MINE** : un `@media (max-width:560px)`
  reposait `.question` à 21 px. No-op tant que la base valait 21 — et il aurait ANNULÉ la descente
  exactement sur le format où le défaut a été signalé.
· **ET LE TÉMOIN DE LA DÉCISION NE RENCONTRAIT PAS SON CAS** : « un bloc de décision n'a pas de
  “Vérifier” » cherchait `.ov-block.dec [data-ovverify]` alors qu'aucune décision n'était encore
  POSTÉE au journal — absent parce qu'absent, vert sans rien mesurer. La section avance désormais
  jusqu'à une décision et le vérifie d'abord. ⚠ Corollaire payé sur place : la trace do-verify se
  relève AVANT d'avancer, le journal condensant un passage terminé en ligne-bilan.

**A76. CE QUE L'AUDIT STATIQUE NE POUVAIT PAS VOIR, ET QUI ÉTAIT DÉJÀ FAIT (v5.6, réponses aux
points 9d et 9e).** Un audit qui lit `index.html` ne voit ni les harnais ni les gardes JS ; trois de
ses constats se règlent en ÉCRIVANT ce qui était vrai, au lieu de changer le code.
· **`.pdf-fnav` — LE SEUL VRAI DÉSACCORD, ET IL EST RETENU** : la pilule d'occurrences n'apparaît
  que si la visionneuse a été ouverte depuis un résultat, mais elle reste alors posée sur le
  document, page après page — et un document consulté pendant un soin peut porter EN BAS DE PAGE
  une posologie. Le geste qui l'a fait naître était « trouve ce mot », pas « couvre le bas de mes
  pages ». Sa bande est désormais RÉSERVÉE dans le défileur (`--pdfhl-r`, hauteur MESURÉE, 0 quand
  la pilule n'est pas là) : le document se TERMINE au-dessus d'elle, il n'y a plus rien à occulter.
  C'est la doctrine du dock — une bande réservée, jamais une superposition au contenu clinique.
· **`.alert-toast` NE SURGIT JAMAIS SUR L'ÉCRAN DE SOIN** (vérifié) : `onTimerFired` ne l'appelle que
  dans la branche `!activeVisible` — session hors de vue, autre fiche, ou app en arrière-plan. Sous
  les yeux, l'alarme reste sur place. Le noyau §2 vise ce qui SURGIT pendant qu'on regarde ; ici
  l'alerte est ROUTÉE vers quelqu'un qui regarde ailleurs, ce qui est l'exigence inverse. C'était
  écrit côté JS, pas au site CSS où l'audit a regardé : ça l'est maintenant.
· **`.sys-banner` EST EXEMPTÉ D'A11, EXPLICITEMENT** : A11 vise la surface de CRISE, où une masse
  colorée de plus vole l'œil à une étape vitale. Ce bandeau ne vit que sur l'ACCUEIL, sa teinte est
  INFORMATION, et rien d'autre ne peut s'y afficher en même temps (la notice d'auteur attend son
  acquittement). Étendre A11 à l'accueil interdirait la carte de session vive et les épinglées.
· **`.mi-sc` / `.mi-ins` (40 px) SONT CONSIGNÉS comme `.st-seg` l'a été** : galerie de l'ÉDITEUR,
  hors contrat des 44 px, très au-dessus des 24×24 de WCAG 2.2 § 2.5.8.
· **8f EST LIVRÉ** (A33) : dès qu'une session est à l'écran, `audit-a11y` scanne la page ENTIÈRE et
  compte le halo `::after` dans la zone tapable. L'audit le croyait ouvert parce qu'il ne lit pas
  `scripts/`.
· **LES DEUX CIBLES À 24 px NE RÉTRÉCISSENT PAS AU ZOOM** (`.azrail button`, `.rel-x`) : mesurées
  24,00 × 24,00 à 100 % comme à 200 % — ce sont des px CSS fixes, le zoom les agrandit visuellement
  au lieu de les rogner. La crainte de l'arrondi vise une taille DÉRIVÉE ; il n'y en a pas ici.

**A77. L'ÉCRAN D'ENTRÉE NE PORTE QUE CE QUI SERT À DÉCIDER D'ENTRER (v5.6, signalé à l'usage).**
Trois retraits et un déplacement, tous sur l'écran d'avant le soin — jamais sur le déroulé.
· **« Surveillances & pièges » N'Y EST PLUS** : c'est par définition ce qui vient APRÈS les gestes.
  Sur la page où l'on décide d'entrer, il n'est ni actionnable ni décisif, et il repousse d'autant
  le geste d'entrée. Il revient au PREMIER geste — rien n'est perdu, c'est différé au moment où
  cela sert —, et en voie large il n'a même pas disparu : la colonne d'orientation porte
  « Surveiller ensuite » en permanence. AC 120-71B veut les surveillances dans le FLUX ; cette
  règle vise le déroulé du soin, pas la page de garde.
· **NI LA RANGÉE « CONSULTER »** : elle appartient au soin. Elle reste à un tap par le renvoi
  « le tableau ne colle pas ? » de la condition d'entrée et par le menu ⋯ — aucun accès perdu.
· **« TABLEAU » ET « SCHÉMA » PASSENT AU-DESSUS DE « PRISE EN CHARGE »**, en boutons de contour de
  44 px au lieu de liens de texte de 12 px. Ils ouvrent la fiche ENTIÈRE : ce n'est pas un détail
  de cet étage, cela se lit avant lui. Contour et non rempli — le seul bouton rempli de l'écran
  reste le geste d'entrée (règle du bouton unique).

**A78. CE SONT DES EXCURSIONS, ET UNE EXCURSION SAIT REVENIR (v5.6, signalé à l'usage : « cliquer
sur tableau mène au tableau SFAR mais impossible de revenir, et on perd les sidebars ; cliquer sur
schéma ne fonctionne pas »).** Deux défauts, une cause commune : ces deux portes n'avaient pas été
traitées comme des excursions.
· **« Tableau » écrivait `state.readMode='static'` et re-rendait.** La page d'entrée était donc
  REMPLACÉE — or le retour d'excursion vit dans le DOCK (« ↩ Un bloc », lot A), et le dock n'existe
  pas avant le premier geste (A18) : on était enfermé. Et le format statique n'ayant pas de colonne
  de plan, le cockpit perdait ses DEUX colonnes au passage. Les deux portes ouvrent désormais une
  FEUILLE plein écran, qui se referme par son ✕, Échap, le voile et le retour système ; la page
  d'entrée reste dessous, intacte, colonnes comprises.
· **`state.readMode` N'EST PLUS TOUCHÉ** : on MONTRE la page, on ne bascule pas le format de
  lecture — « regarder n'est pas régler » (lot A). Le commentaire qui interdisait « Tableau » dans
  cette feuille (« ce serait une seconde porte vers le mode statique, dont #readTopSeg est le seul
  maître ») est caduc des deux côtés : `#readTopSeg` a été purgé au lot A, et il ne s'agit pas
  d'une porte vers un ÉTAT.
· **⚠ « Schéma » NE FAISAIT RIEN, EN SILENCE** : `openFlowFull(f)` prend la fiche en paramètre et
  l'appel l'omettait — `buildFlowSVG(undefined)` ne rend rien et ne lève pas. Un argument oublié
  ne se voit ni au `check`, ni aux tests : seul un témoin qui CLIQUE le trouve.
· **UNE COQUE, DEUX VUES** : la feuille « Se repérer » accepte `openPlanSheet('page')` — même ✕,
  même Échap, même retour système, rien de neuf à tenir. Et `svPaintArrows(racine)` est
  paramétrée : un second peintre recopié divergerait au premier réglage de flèche.

**A79. AVANT LE SOIN, LE PARCOURS SE RESSERRE — LES MARGES CÈDENT, JAMAIS LE CONTENU (v5.6, signalé
à l'usage : « le parcours inerte est trop long »).** Rangée 44 → 38 px, rembourrage 6/12 → 4/10,
écart de grille 6 → 4, pastille 26 → 24, étiquette de branche 38 → 28. **Mesuré : 454 → 388 px,
soit 15 %** — aucun mot retiré, aucun corps de texte changé.
· **POURQUOI SEULEMENT AVANT** : 44 px est le plancher de la CRISE et il ne se négocie pas une fois
  le soin démarré. Ici il n'y a pas de crise — `audit-a11y` mesure d'ailleurs cet écran sur la
  liste HORS crise, plancher 24 — et le geste qui fait basculer les deux géométries est le bouton
  de démarrage, donc COMMANDÉ : A9 interdit qu'une hauteur change sans qu'on l'ait demandé, pas
  qu'un écran se réorganise quand on entre dedans (c'est déjà ce que fait T5). 38 px reste au-dessus
  du plancher hors crise (32).
· **CE QUI N'A PAS ÉTÉ TOUCHÉ, ET POURQUOI C'EST À DIRE** : les rangées de surveillance à 48 px le
  sont parce que leur texte passe sur DEUX lignes — c'est du contenu, pas du rembourrage. Le
  raccourcir serait la perte d'information que la demande exclut.

**A80. CHANGER DE CRAN N'EST PAS NAVIGUER (v5.6, demande de l'auteur).** La bascule Tout / Aides /
Protocoles faisait glisser la liste (`.sec-anim-l/r`, PURGÉES avec leur mécanique — règle 14).
C'est un changement de FILTRE : la liste reste la même liste, seule sa clé change, et l'animer lui
donnait l'allure d'un changement d'écran. Le glissement de la PASTILLE du sélecteur suffit à accuser
le geste, et il est, lui, de la manipulation directe. Les keyframes `secInL/R` restent : elles
servent la pile de retour et la bascule de format en lecture, qui sont deux vraies navigations.

**A81. UN MINUTEUR ARRÊTÉ DIT DEPUIS QUAND (v5.6, planche 11j — le point le plus critique de la
série « intelligence »).** Au rechargement les minuteurs sont restaurés EN PAUSE et le temps passé
application fermée n'est PAS rattrapé : c'est juste, le rattraper fabriquerait un temps que personne
n'a mesuré. Mais rien ne disait **combien**. Un minuteur figé à 4:22 se lit d'un coup d'œil comme un
minuteur qui tourne à 4:22, et la décision qui suit — « ça fait quatre minutes, je redonne » — est
prise sur un chiffre qui a cessé d'avancer. C'est le seul endroit du produit où un chiffre commande
un geste médicamenteux, et c'est pour cela que cette ligne passe avant tout le reste.
· **UNE PHRASE, DEUX CAUSES** : « △ arrêté depuis 4:10 — application fermée, le temps n'a pas été
  rattrapé » s'il TOURNAIT à l'enregistrement (l'arrêt date de `savedAt`) ; « △ arrêté depuis 4:10 »
  s'il était déjà en pause. Une pause dont on a perdu le compte est le même piège, et distinguer
  les deux par deux formulations ferait deux phrases à lire.
· **AMBRE TEXTUEL, JAMAIS UN APLAT** (A11) : c'est une LECTURE, pas une alarme. Sur la matière
  SYSTÈME (le volet), le registre prend sa valeur propre `--warn-sys`.
· **⚠ AUCUN SEUIL, ET C'EST A9 QUI L'IMPOSE** : « n'afficher qu'au-delà de 30 s » ferait apparaître
  une ligne — donc grandir la carte — SANS geste. Elle paraît au tap de pause (geste commandé, la
  carte a le droit d'y gagner une ligne) ou est déjà là au chargement, et seul son NOMBRE avance
  ensuite. Un minuteur ÉCHU n'en reçoit aucune : il le devient tout seul, et l'alarme dit déjà ce
  qu'il faut savoir.
· **ELLE NAÎT AU TICK, PAS AU RENDU** — précédent exact d'A34 : la mise en pause passe par le
  chemin chirurgical (`syncTimerBtns`), pas par un re-rendu ; posée seulement par `timerCard`, la
  ligne n'apparaîtrait qu'au prochain rendu complet, c'est-à-dire peut-être jamais.
· **DEUX CHAMPS FACULTATIFS DANS L'INSTANTANÉ** (`running`, `stoppedAt`) : sans eux on ne peut pas
  distinguer « fermée pendant qu'il tournait » d'« en pause depuis dix minutes ». Un instantané
  ANTÉRIEUR retombe sur `savedAt` — au pire la durée annoncée est trop COURTE, jamais inventée
  (`tmStopFrom`, pure, 6 témoins).

**A68. MICRO-ANIMATION NON BLOQUANTE — CINQ CONDITIONS, ET UNE ANIMATION QUI EN MANQUE UNE NE SE
DISCUTE PAS (v5.6, planche 10d).** La règle était énoncée trois fois, à trois endroits, en trois
formulations — le déroulé du volet (A51), l'oscillation du bloc saisi (v4.75.0), l'élévation de
l'en-tête (A27). Écrite une fois, elle devient opposable.
1. **ELLE RÉPOND À UN GESTE.** Le mouvement non commandé est réservé à l'alarme (ECAM) : ce qui
   bouge tout seul dit « danger », ou ne dit rien.
2. **L'ÉTAT EST APPLIQUÉ D'ABORD, L'ANIMATION LE DÉCORE.** Aucune mutation n'attend un
   `animationend` — il ne sert qu'à NETTOYER (retirer une classe, un style, un `hidden`).
3. **`transform` ET `opacity` SEULEMENT** (check-anim) : aucune passe de mise en page par image.
   Une hauteur qui doit « se dérouler » se fait en `scaleY` + contre-scale du contenu (A51).
4. **INTERRUPTIBLE.** Un second geste pendant l'animation est honoré IMMÉDIATEMENT : l'animation
   est REMPLACÉE, jamais mise en file. Rien n'est `pointer-events:none` sauf un annonciateur qui
   ne reçoit rien (halo, dégradé, flash, coque du dock, fenêtre de dépôt, surlignage PDF).
5. **BORNÉE** : ≤ 200 ms, une seule oscillation amortie, JAMAIS de boucle — la boucle appartient à
   `alarmPulse` et au point de session. Et inerte sous `prefers-reduced-motion`, sans exception.
· **LA CONDITION 4 EST LA SEULE QUI N'ÉTAIT ÉCRITE NULLE PART**, et c'est celle que la demande
  formule (« pouvoir continuer à utiliser l'app pendant l'animation »). Elle était respectée PAR
  CONSTRUCTION, pas par règle : rien n'empêchait le prochain lot d'accrocher une mutation d'état à
  une fin d'animation. `check-anim` la mesure désormais — le corps d'un `animationend` ne peut
  contenir ni rendu, ni écriture sur `state`/`Runtime`, ni persistance —, plus un CLIQUET sur le
  nombre de `pointer-events:none` (18 aujourd'hui, tous des annonciateurs) : une nouvelle
  occurrence est une décision, et elle doit se voir dans un diff.
· **⚠ LA PORTÉE EST DITE** : la sonde lit le corps littéral du gestionnaire. Un `animationend` qui
  appellerait une fonction NOMMÉE écrivant l'état passerait au travers — elle attrape l'écriture
  directe, pas l'indirection. Un contrôle qui tait sa limite laisse croire à une couverture totale.
· **TROIS ANIMATIONS REFUSÉES, ET LE REFUS FAIT JURISPRUDENCE** : le chrono qui fond à chaque
  seconde (mouvement non commandé, permanent, sur la zone qui ne quitte jamais l'écran — la
  définition du bruit) ; le squelette de chargement animé du répertoire (il fabrique une attente là
  où il n'y en avait pas) ; le glissement d'écran sur un changement de filtre, déjà purgé en v5.6
  (A80) — la liste reste la même liste, seule sa clé change.

**A82. « PRÊT » SE DIT SUR LA FICHE, PAS SUR L'ACCUEIL (v5.6, planche 11a).** La jauge
`#attOffline` annonce sur l'ACCUEIL que des documents manquent — alors que la question se pose sur
la FICHE qu'on est en train d'ouvrir. C'est le test du LIEU pris en défaut : une information juste,
au mauvais endroit, qu'on découvre en perdant le réseau. Une ligne de corps sous la rangée des
excursions : « ✓ 3 documents · tous disponibles hors ligne », ou son ambre TEXTUEL avec le NOM de
ce qui manque et le geste (`dlMissingAtts` existe déjà).
· **ELLE NE CONDITIONNE RIEN, et c'est la propriété que le témoin mesure** : « Confirmé — démarrer »
  reste actif avec des pièces manquantes. Un soin ne s'arrête pas parce qu'un PDF n'est pas là — le
  manque est une INFORMATION, jamais une condition. Pas de bandeau, pas de fenêtre, pas de pastille.
· **LE NOM QUAND IL Y EN A UN SEUL** : « un document » n'aide pas à décider s'il faut attendre le
  réseau, « Protocole SFAR 2024 » oui. Au-delà d'un, on compte.
· **ET L'ABSENCE DE BOUTON S'EXPLIQUE** : sans compte ni chemin de stockage il n'y a rien à
  télécharger — on dit pourquoi, dans les mots exacts de la jauge d'accueil. Une absence non
  expliquée se lit comme une panne.
· **⚠ LA MOITIÉ « RÉVISION » DE LA PLANCHE N'EST PAS REPRISE, ET C'EST UNE CORRECTION DE PRÉMISSE** :
  elle la croyait absente de la page d'entrée, or la rangée de méta y porte déjà « Validation :
  01/2025 » — elle n'est masquée qu'EN SESSION (v4.31.0). L'écrire une seconde fois serait la
  duplication que § 5.5 proscrit. Une proposition juste peut reposer sur un constat faux ; on
  vérifie le constat avant de livrer la proposition.

**A83. LA CARTE DE SESSION DIT OÙ L'ON VA RETOMBER, AVANT LE GESTE (v5.6, planche 11c).**
« Bloc 7 · Reprise du massage — dernier repère 15h47 », sous le titre. `resumeSession` restaure
déjà le runtime entier ; ce qui manquait est le MOT qui permet de savoir, avant de toucher, où l'on
atterrit — sans quoi on reprend, puis on relit le journal pour se retrouver. Encore le test du
lieu : l'information qui décide du geste n'était disponible qu'APRÈS lui.
· **AUCUNE SURFACE NOUVELLE** : deux données déjà en mémoire, sur une carte qui existe. C'est la
  moins chère des propositions de la série.
· **ELLE NE DIT QUE CE QU'ELLE SAIT** (`liveWhereText`, pure, 6 témoins) : pas de bloc courant → pas
  de fragment de bloc ; aucun repère → pas d'heure ; rien des deux → chaîne vide et la ligne
  n'existe pas. Un « — » à la place d'une donnée absente serait du bruit à décoder.

**A84. L'ÉCRAN NE S'ÉTEINT PAS PENDANT UNE SESSION, ET IL LE DIT UNE FOIS (v5.6, planche 11k).**
Aucune occurrence de `wakeLock` dans le fichier : pendant une réanimation de vingt minutes l'écran
s'éteignait seul, et le geste suivant commençait par réveiller un téléphone — l'outil se retire
pendant qu'on s'en sert. Une ligne dans l'en-tête du volet, au registre et à la place de « Son
activé / Son coupé », qui règle déjà exactement ce genre de question.
· **QUATRE RÈGLES, ET CE SONT ELLES QUI ÉCRIVENT LE CODE** : demandé seulement en session vive,
  relâché à la fin et au masquage, redemandé au retour ; aucune fenêtre, aucune permission ;
  une ligne, dans le volet, sur geste ; un interrupteur, parce que c'est un réglage (batterie
  faible, transport long, tablette partagée) et que l'état se VOIT au lieu de se deviner.
· **`wakeApply` EST IDEMPOTENT, ET C'EST LE POINT DUR** : « un verrou redemandé en boucle est un
  bogue de consommation ». Il sort si la demande correspond déjà au verrou tenu, donc on peut
  l'appeler à chaque rendu de lecture sans rien redemander. **MESURÉ : 1 demande, et 5 rendus
  successifs n'en ajoutent aucune** — c'est le nombre de demandes que le témoin compte, pas la
  présence d'un interrupteur.
· **⚠ ON TESTE LA CAPACITÉ, PAS LA CLÉ** : `'wakeLock' in navigator` est VRAI même quand la
  propriété vaut `undefined`. Sans cela la ligne s'affichait là où rien ne peut se produire —
  l'inverse de la dégradation silencieuse. Un refus du système ne dit rien non plus : il laisse
  l'interrupteur sur « veille normale ».
· Le choix est PERSISTÉ par utilisateur, comme le thème et le son : le rallumer à chaque session
  serait un réglage qu'on ne peut pas régler.

**A85. LE MINUTEUR AD HOC DIT CE QU'IL CRÉE, ET SA DURÉE SE CHOISIT (v5.6, planche 11h).** Le geste
existait et il était juste — un tap, un objet déjà réglé, démarré, supprimable : *le risque n'est
pas la création, c'est la saisie*. Deux limites mesurées : la durée valait **300 s en dur**, et le
nom DÉGÉNÉRAIT (`'PA'+(n+1)` → « PA, PA 2, PA 3 »), c'est-à-dire trois minuteurs qui ne disaient
plus ce qu'ils surveillaient.
· Le bouton porte le **nom pressenti du dernier repère** (`tkLabels`, vocabulaire déjà normalisé) et
  l'annonce AVANT le tap ; son tap déplie **quatre durées**. Deux taps, **zéro clavier, zéro champ**,
  et UN seul ＋ qui déplie — jamais quatre ＋ dans une rangée que la largeur du volet ne supporte pas.
· **⚠ UN LIBELLÉ DE REPLI N'EST PAS UN NOM** (trouvé à la mesure, puis signalé à l'usage : « ne le
  nomme pas ＋ Minuteur Compteur »). Le dernier repère se résout parfois sur « Action 3 », ou sur le
  nom PAR DÉFAUT d'un objet sans nom (« Compteur », « Minuteur », « Chronomètre », A58) — repris
  tel quel, cela donnait « ＋ Minuteur Compteur » : la dégénérescence de « PA 2 » sous un autre
  visage. Sans nom réel, le bouton reprend son libellé d'avant : *la proposition n'invente pas de
  mot quand elle n'en a pas.*
· **ET LE LIBELLÉ NE PROMET PLUS « 5:00 »** : la durée n'est plus décidée d'avance. Un bouton qui
  annonce une valeur qu'il ne pose pas est de la mode confusion (A38).
· **RÈGLE 15 — VÉRIFIÉE, PAS SUPPOSÉE** : la planche demandait de trancher avant d'écrire si un nom
  tiré d'un repère voyage. Mesuré : `shareSnap` n'envoie d'un minuteur que
  `{running, elapsedMs, cycles, anchor}` sous sa CLÉ, et un minuteur ad hoc n'existe pas chez
  l'invité — il vit dans la session, qui ne voyage pas. La contrainte est donc tenue par
  CONSTRUCTION, pas par une garde à maintenir.

**A86. LE COMPTEUR AD HOC — L'ASYMÉTRIE MESURÉE, ET LE PLUS SÛR DES DEUX (v5.6, planche 11i).**
Les compteurs ne venaient que de `f.counters` : rien n'en créait en session, alors que les MINUTEURS
l'avaient depuis toujours. Or un compteur **ne sonne pas, n'échoit pas, n'entre jamais dans le
registre d'alarme** — c'est l'objet le moins risqué du volet, et le seul qu'on ne pouvait pas poser
quand il manquait (chocs, doses non prévues par l'auteur, relais de masseur : on comptait de tête).
· **CRÉÉ À 1, JAMAIS À 0** : on appuie parce que l'événement vient d'avoir lieu. Le premier incrément
  est donc déjà compté, et il pose son repère horodaté comme n'importe quel « ＋ » — même sans nom,
  le compte rendu garde l'heure de chaque unité.
· **NOMMER EST FACULTATIF ET DIFFÉRÉ** (doctrine du repère horodaté), et « — nommer » n'existe QUE
  sur un compteur ad hoc : celui de l'auteur porte un nom décidé au calme.
· **⚠ AUCUN `timerId`, ET ON NE LUI EN INVENTE PAS** : ce lien relance une alarme, c'est une
  décision d'AUTEUR.
· Ils vivent dans la session (`extraCounters`), exactement comme `extraTimers` — donc hors de
  l'export de la fiche, et hors du réseau.

**A87. UN VOLET QUI VIT DANS `main` SE FAIT REMONTER PAR CHAQUE RENDU (v5.6, signalé à l'usage :
« ajouter un minuteur/compteur réinitialise le contenu : on perd le fil et ça fait un fondu blanc
moche »).** Trois conséquences d'une même cause, et la première est une violation d'A68.
· **LE DÉROULÉ REJOUAIT À CHAQUE GESTE** : l'animation était portée par le MONTAGE de `.rt-dock`, or
  tout rendu complet le remonte. A68/1 dit que le mouvement répond au GESTE qui l'a demandé — la
  classe `.rt-roll` est donc posée UNE FOIS, par le tap du quai, et consommée par le rendu qui suit.
  Mesuré : `dockRoll` à l'ouverture, `none` après un ajout.
· **LE VOLET A SON DÉFILEMENT PROPRE**, et il repartait en haut. Même règle que `.read-side` depuis
  la v4.23.5 : on capture avant, on restaure après — la moitié étroite n'avait jamais été écrite.
· **LE DÉFILEMENT DE PAGE, LUI, NE BOUGEAIT PAS** (mesuré : 0 px). Ce qui « fait perdre le fil » est
  le volet qui se replie et se redéroule sous les doigts, pas la page — on corrige ce qu'on mesure.

**A89. UN TÉMOIN NE DOIT JAMAIS POUVOIR PENDRE — ET ON LIT LE CODE DE SORTIE, PAS LA DERNIÈRE LIGNE
(v5.6, deux heures perdues).** Changer la porte du minuteur (un tap déplie, le second crée) a cassé
un témoin du QUAI qui comptait sur « un tap = un minuteur » : sa boucle `while(ids.length<3)` dans
un `page.evaluate` ne se terminait plus, et la tranche `doctrine 1/4` restait vivante indéfiniment —
emportant la passe entière, sans un mot.
· **UNE BOUCLE DE SONDE EST BORNÉE, TOUJOURS.** `if(!b)break` ne suffit pas : le bouton EXISTE, il
  ne fait simplement plus ce qu'on croit. Une borne d'itérations transforme un blocage silencieux
  en rouge lisible.
· **⚠ ET J'AI ÉTÉ TROMPÉ PAR LE PIÈGE QUE CE FICHIER DOCUMENTE DÉJÀ** (v4.70.1) : `npm run audit |
  tail -6` rend le statut de `tail`, pas celui de l'audit. La tâche de fond a donc rapporté
  « exit 0 » sur une passe qui pendait, et j'ai cru la porte verte. **On lit le code de sortie de
  la CHAÎNE**, ou l'on redirige et l'on cherche la ligne de bilan.
· **ET LE TÉMOIN VOISIN NE RENCONTRAIT PLUS SON CAS** : il faisait « varier l'état » en cliquant la
  porte trois fois — depuis le dépliage, l'état ne variait plus du tout, et « le quai ne bouge pas
  quand l'état varie » se vérifiait sur un état constant. Il compte désormais les minuteurs avant
  et après, et échoue si rien n'a bougé.

**A88. LE PANNEAU NE SE TAIT PAS QUAND LA FICHE N'A RIEN À MONTRER (v5.6, signalé à l'usage :
« lorsque la session n'a pas de minuteur ou chronomètre pré-défini, l'option d'ajouter ne s'affiche
pas »).** En voie large, le rail sortait à vide dès que la fiche ne déclarait ni minuteur ni
compteur — emportant les deux PORTES avec lui, et rendant impossible de poser un objet ad hoc
précisément sur les fiches qui en ont le plus besoin : celles où l'auteur n'en a prévu aucun.
· **LA RÈGLE « UN PANNEAU VIDE EST DU BRUIT » VISE CE QUI AFFIRME**, pas ce qui INVITE. « 0 minuteur »
  est du bruit ; deux boutons qui ouvrent une capacité sont une porte. C'est exactement la
  distinction déjà tranchée pour le chapeau « Ne pas oublier », affiché vide (v4.76.0).
· Le panneau ne disparaît donc plus que **hors session** : sans soin en cours, il n'y a rien à créer.

**A90. LA RANGÉE DE REPÈRE QUI VIENT D'ÊTRE ÉCRITE SE DÉSIGNE (v5.6, planche 11g/1).** Le panneau du
journal est remplacé EN PLACE à chaque ajout : l'information est déjà à l'écran, mais rien ne disait
LAQUELLE des rangées est nouvelle — et sous stress on relit la liste entière pour s'en assurer.
L'animation ne fait que la désigner ; elle n'apporte aucune information de plus. C'est le cas le plus
net des quatre proposées, et le seul dont le gain ne se discute pas.
· **A68 EN ENTIER** : elle répond à un GESTE ; l'état est écrit AVANT (le repère est dans
  `Runtime.events` quand le panneau se rend) ; 140 ms, opacité + 5 px, `cbIn` qui existait déjà ;
  rien ne l'attend — le tap suivant écrit pendant qu'elle entre encore ; inerte sous
  `prefers-reduced-motion`.
· **⚠ LE DRAPEAU EST CONSOMMÉ PAR LE PREMIER RENDU** (`_tkFresh`, lu puis remis à null dans
  `timekeeperPanel`) : le panneau se repeint aussi au tick et à l'arrivée d'un évènement DISTANT, et
  une rangée qui re-clignoterait à chaque passage serait exactement le mouvement non commandé
  qu'A68/1 interdit. Le témoin mesure les DEUX moitiés — une seule rangée animée, et plus aucune
  après une repeinture.

**A91. LA SECONDE MICRO-ANIMATION EST REFUSÉE — SA PRÉMISSE NE TIENT PAS DANS CE BUILD (v5.6,
planche 11g/2, mesuré).** La proposition était : « depuis A12, la position est portée par la
BORDURE D'ACCENT du seul bloc ouvert, et elle apparaît sans transition, donc l'œil doit la
chercher » — 120 ms d'opacité sur la bordure seule.
· **MESURÉ** : `.ov-block.cur` ne porte AUCUNE bordure d'accent. Sa bordure vaut `--work-line`
  (`rgba(20,24,29,.08)`, la même que toute carte de travail) ; ce qui le désigne est son
  ÉLÉVATION (`--shadow-work`) et le fait d'être **le seul bloc ouvert** — mesuré : 1 carte ouverte.
· **ET L'ŒIL N'A PAS À LE CHERCHER** : la carte qui devient courante est POSTÉE au bout du journal,
  `ovAdvanceRender` y ancre le geste et défile jusqu'à elle si elle n'est pas déjà entière à
  l'écran ; et le changement visuel est massif (la précédente se condense, la nouvelle ouvre ses
  étapes). Une animation de plus n'ajouterait rien qu'on ne voie déjà.
· **CE QUI RESTERAIT POSSIBLE, ET POURQUOI ON NE LE FAIT PAS** : fondre l'ÉLÉVATION. Ce serait
  imperceptible à côté de l'ouverture de la carte, et cela ajouterait du mouvement à la surface de
  soin — là où l'ECAM le réserve à l'alarme. **Une proposition juste peut reposer sur un constat
  faux ; on vérifie le constat avant de livrer la proposition** (même leçon qu'A82 sur la révision
  déjà affichée).

**A92. UNE CLASSE POSÉE AU FOCUS ET RETIRÉE AU BLUR EST ORPHELINE SI LE CHAMP EST DÉTRUIT (v5.6,
signalé à l'usage : « renommer un nouveau compteur fait disparaître la barre flottante »).** A1
efface le dock au focus d'un champ (`kb-open`) — le clavier EST la surface de saisie. Le champ de
nommage vit dans le VOLET et son commit RE-REND : le champ disparaît **avant** que son `focusout`
ne parte, la classe reste posée, et le dock — donc « Noter l'heure », « ⚡ » et le geste d'entrée —
restait `display:none` jusqu'au prochain focus.
· **ON NE CORRIGE PAS EN EXEMPTANT LE CHAMP FAUTIF** : le prochain champ ajouté ailleurs rejouerait
  le défaut. La classe est **réévaluée à chaque rendu**, sur la seule question qui compte — y a-t-il
  un champ focalisé, MAINTENANT ? Même famille que la liste de placards d'A78 et que le compteur de
  rendu d'A49 : un état qui dépend d'un évènement de sortie doit avoir une seconde source de vérité.

**A93. LES OBJETS AD HOC SONT DES OBJETS DE LA SESSION, PAS DE LA FICHE (v5.6, signalé à l'usage :
« un nouveau compteur n'apparaît pas dans Noter l'heure »).** `tagAll` et `tagLabel` lisaient
`f.timers` / `f.counters` — or un objet créé EN SESSION vit dans le Runtime. Il était donc visible à
l'écran et introuvable au moment de l'horodater : **exactement le défaut qu'A58 avait corrigé pour
les objets SANS NOM, revenu par une autre porte** — et le minuteur ad hoc, lui, l'avait depuis
toujours.
· **LES DEUX FONCTIONS RESTENT PURES** : la session passe ses objets en PARAMÈTRE (`tagSrc`), elle
  n'est pas lue depuis leur corps. C'est ce qui permet au compte rendu d'une session ARCHIVÉE de
  résoudre les mêmes noms, en lisant `extraTimers`/`extraCounters` de l'instantané — un compte rendu
  se relit longtemps après, éventuellement pendant une autre session.
· **UN SEUL POINT DE LECTURE DU RUNTIME** (`rtExtra`) : six appelants, une expression — recopiée,
  elle aurait divergé.
· **LA SUPPRESSION SUIT SANS RIEN ÉCRIRE** : le vivier est CALCULÉ à chaque appel, donc un compteur
  supprimé en sort par construction. C'est la seconde moitié de la demande, et elle était acquise —
  on la mesure quand même, parce qu'« acquis par construction » se vérifie.

**A94. LE RÉPERTOIRE TOLÈRE LA FAUTE DE FRAPPE — ON CORRIGE LA REQUÊTE, JAMAIS LA LISTE (v5.6,
décision de l'auteur : « tolérance seule, sans table »).** Sous stress et avec des gants,
« anafilaxie » ne trouvait RIEN — et un répertoire qui répond « aucun résultat » sur une faute de
frappe fait renoncer à chercher là où le contenu est. QUATRE BORNES, et ce sont elles qui rendent
la chose admissible dans un logiciel d'urgence :
1. **ELLE NE SE DÉCLENCHE QUE SUR ZÉRO RÉSULTAT, DOCUMENTS COMPRIS.** Une liste littérale non vide
   n'est ni réordonnée ni complétée — le rapprochement flou est un DERNIER recours, jamais un
   classement (même garantie que `posoRank` et `tagRank`, prise par l'autre bout). Un mot trouvé
   dans un PDF joint EST un résultat : corriger par-dessus le masquerait.
2. **LES CANDIDATS VIENNENT DE VOTRE PROPRE BIBLIOTHÈQUE**, et de la liste VISIBLE sous les filtres
   du moment. Un lexique médical livré serait une seconde source de vérité à tenir, et du poids
   (règle 13) ; surtout, corriger vers un mot que le cran courant écarte rendrait zéro résultat.
3. **ELLE SE DÉCLARE EN TOUTES LETTRES** (« Aucun résultat pour X · affiché : Y »). Une recherche
   qui corrige en silence ment sur ce qu'elle montre, et l'on croirait avoir tapé juste. Registre
   INFORMATION, jamais ambre : la liste en dessous est juste, on dit seulement d'où elle vient.
4. **ELLE NE RÉÉCRIT PAS LE CHAMP.** Le texte tapé reste celui de l'utilisateur ; c'est le RÉSULTAT
   qui est élargi, pas la saisie corrigée sous les doigts.
· **UN PRÉFIXE N'EST JAMAIS CORRIGÉ** : on tape « anaph » en cours de frappe, et le corriger ferait
  sauter la liste sous le doigt. Un terme qui est sous-chaîne d'un mot du vocabulaire est laissé.
· **⚠ LE BUDGET SUIT LA LONGUEUR, ET IL LE FAUT (mesuré)** : à deux éditions, « anafilaxie » — la
  graphie PHONÉTIQUE, donc la faute la plus probable sur un mot qu'on n'écrit jamais — restait sans
  réponse (elle est à TROIS d'« anaphylaxie »). 1 · 2 · 3 selon la longueur, soit un tiers du mot au
  plus : au-delà ce n'est plus une faute de frappe, c'est un autre mot. Le risque d'un rapprochement
  FAUX est tenu par les quatre bornes, pas par l'étroitesse du budget — il ne coûte qu'une liste
  visiblement à côté, sous une ligne qui dit exactement ce qui a été cherché.
· **LA TRANSPOSITION COMPTE POUR UNE ÉDITION** (Damerau) : deux lettres voisines interverties sont
  la faute la plus fréquente au clavier, et deux substitutions la surestiment. La distance est
  BORNÉE — on sort dès qu'une ligne dépasse le budget, sinon un vocabulaire de plusieurs milliers
  de mots coûterait une passe complète par candidat, à chaque frappe.
· **DÉTERMINISTE** : à égalité de distance, l'ordre alphabétique tranche — sinon deux frappes
  identiques donneraient deux listes.
· **TÉMOINS AUX DEUX ÉTAGES** : `libVocab`/`spellFix`/`dlev` sont PURES (14 témoins dans
  `tests.html`), et une section d'`audit-doctrine` mesure le CÂBLAGE au rendu — c'est lui qui peut
  se tromper de cas. Elle RENCONTRE SON CAS d'abord (la requête juste doit trouver quelque chose),
  et elle est vérifiée capable d'échouer (déclenchement neutralisé → 2 rouges).

**A95. LES DEUX DERNIÈRES MICRO-ANIMATIONS — ET CE QU'ELLES ONT FAIT TROUVER (v5.6, planche 10d,
propositions 3 et 4).**
· **LE MINUTEUR ARMÉ REJOINT LA CAPSULE** : le geste a lieu EN BAS, dans le volet, et le segment
  naît EN HAUT — rien ne reliait les deux. `capIn`, 140 ms, `scaleY` depuis le bas + opacité.
  A68 en entier : elle répond à un geste ; l'état est écrit avant ; transform et opacité seulement ;
  rien ne l'attend ; bornée, une fois, inerte sous `prefers-reduced-motion` par construction.
  ⚠ **UN SEGMENT ÉCHU EN EST EXCLU** : l'alarme a sa grammaire — elle PULSE. Lui prêter l'entrée
  douce du nominal mêlerait deux registres dans la seule zone où l'ECAM réserve le mouvement à
  l'alerte.
  ⚠ **LE DRAPEAU SE CONSOMME QUAND LE SEGMENT EST PEINT, PAS QUAND ON LE LIT** (trouvé à la
  mesure) : la capsule sort tôt quand elle n'a rien à montrer, et sa boucle d'ajustement peut
  CACHER le segment — brûlé à la lecture, le drapeau perdait l'animation dans les deux cas.
· **LA PILULE D'OCCURRENCES PDF NAÎT EN FONDU**, sa RÉSERVE non : animer la bande réservée serait
  animer un rembourrage (A68/3). Et l'entrée ne joue qu'au passage caché → visible — `pdfHlSync`
  est appelée à chaque page peinte, une classe laissée en place rejouerait l'entrée pendant tout
  le défilement.
· **CE QUE LA MESURE A FAIT TROUVER, ET QUI VAUT PLUS QUE LES DEUX ANIMATIONS** — cf. A96.

**A96. LE QUAI ANNONCE CE QU'IL CACHE, MÊME QUAND C'EST LUI QUI L'A RETIRÉ (v5.6, défaut
PRÉEXISTANT trouvé en mesurant A95).** Le rappel du chevron (« n minuteurs · n compteurs ») était
conditionné à `!want.length` — « aucun minuteur ne prend la place ». Or `want` est ce que le quai
VEUT montrer, pas ce qu'il montre : la boucle d'ajustement retire des segments quand la place
manque. Mesuré à 390 px, un minuteur NOMINAL armé était donc retiré **sans un mot** — « +n » ne
compte que les ÉCHUS depuis la v5.6, et le rappel se taisait parce que le minuteur était « voulu ».
C'est la promesse ECAM prise en défaut dans la seule zone qui ne quitte jamais l'écran.
· **LE COMPTE SUIT CE QUI EST PEINT** : le libellé devient une fonction de `n` (`chevLblOf`). À
  `n=0` il rend exactement ce qu'il rendait, donc le cas nominal est inchangé au caractère près ;
  à `n=1` le minuteur montré ne se recompte pas — il ne peut pas concurrencer son propre segment.
· **UN TÉMOIN VOISIN A ROUGI, ET IL AVAIT TORT** : il exigeait que « le rappel s'efface » dès qu'un
  minuteur est armé — c'est-à-dire le MÉCANISME d'alors, avec son trou. La propriété recherchée n'a
  jamais été là : c'est « montré OU annoncé, jamais tu » et « jamais les deux à la fois ».
· **L'INTERMITTENCE EST CORRIGÉE EN A98** — le paragraphe qui la disait « mesurée, non corrigée »
  est caduc ; ce qui suit en tient lieu.
· **⚠ ET LE TÉMOIN ATTEND QUE LA CAPSULE SE STABILISE** avant de mesurer : à 140 ms fixes il
  mesurait l'instant, pas l'application. S'il n'obtient jamais son segment, il ROUGIT — il ne
  saute pas son cas (première version : l'assertion était conditionnelle, donc neutraliser
  l'animation la faisait simplement disparaître, et le témoin restait vert).

**A97. « P2 DOCUMENTS » ÉTAIT DÉJÀ LIVRÉ — VÉRIFIÉ, PAS SUPPOSÉ (v5.6, planche 10c).** La
proposition demandait qu'un mot cherché en session sorte les DOCUMENTS joints qui le portent, avec
leur page, sans ouvrir le document ni indexer à la demande. C'est la v5.3.0 (`#pfDocs`, rangées
`.doc-hit`), et `audit-pdfsearch` le mesure de bout en bout depuis : la feuille « Toute la fiche »
trouve dans le PDF joint, le tap ouvre à la bonne page avec surlignage, un mot absent replie la
zone, et l'index n'est jamais construit à la frappe. Rien n'a été réécrit ; trois témoins
s'ajoutent seulement pour l'entrée en fondu de la pilule. **Une proposition juste peut porter sur
un manque qui n'existe plus : on vérifie avant d'implémenter** (même leçon qu'A82 et A91).

**A98. LE QUAI SE MESURE SUR UN FANTÔME, ET NON EN S'ÉCRIVANT DESSUS (v5.6, demande de l'auteur —
suite d'A96).** La boucle d'ajustement ÉCRIVAIT ses candidats dans `#cbTimers` pour les mesurer :
chaque mesure détruisait et recréait les nœuds du quai. C'est ce qui obligeait à MÉMORISER la
décision — donc ce qui rendait une mauvaise mesure définitive. Le fantôme découple les deux.
· **IL EST UN ENFANT DE `#cbTimers`, et c'est ce qui le rend fidèle sans dupliquer une ligne de
  CSS** : les règles du quai sont toutes DESCENDANTES (`#cbTimers .seg` — vérifié, zéro
  combinateur enfant), donc elles s'appliquent à son contenu, et police comme couleurs s'héritent
  par l'arbre. `position:fixed` hors écran : pris hors flux, il n'est pas un item de la rangée,
  n'ajoute aucune zone défilable et ne peut rien recouvrir. Posé, mesuré, retiré dans la MÊME
  tâche — aucune image intermédiaire.
· **⚠ IL DOIT PORTER LES VALEURS, sinon il mesure un gabarit vide et croit que tout tient.** Le
  quai peint ses chiffres à part (`textContent`), donc la chaîne ne les contient pas : la première
  version du fantôme a fait DÉBORDER le quai à 320-430 px, et quatre témoins l'ont dit. Une seule
  liste de valeurs (`valsFor`) sert désormais le vivant et le fantôme.
· **UNE MESURE SANS MISE EN PAGE NE SE RETIENT PAS — c'était la cause principale.**
  `updateRtStrip` peut courir alors que la capsule n'a pas de géométrie (largeur nulle : premier
  rendu, ancêtre masqué) ; le test « ça tient » répond alors OUI à tout, et la décision prise sur
  du vide était mémorisée pour de bon. On ne mesure que si la largeur existe, et l'on ne touche
  pas à la clé sinon.
· **L'ÉTAT DE CHARGEMENT DES POLICES EST UN TERME DE LA CLÉ** : une largeur mesurée avec la fonte
  de repli n'est pas celle qu'on aura. Deux valeurs possibles, donc au plus une re-mesure.
· **ET LE QUAI RÉPOND AU GESTE, PLUS AU TICK** : armer un minuteur ne rafraîchissait que sa CARTE ;
  le segment n'entrait dans la capsule qu'au tick suivant — mesuré, 4 fois sur 8 il manquait encore
  150 ms après le tap. Dans une zone d'état, un changement COMMANDÉ se voit tout de suite, et c'est
  ce qui fait coïncider l'entrée du segment avec le geste (A68/1).
· **⚠ PAS DE RE-MESURE SPÉCULATIVE, ET C'EST LE HARNAIS QUI L'A TRANCHÉ** : un filet « re-mesurer
  une fois quand on cache quelque chose » a été écrit puis retiré — le fantôme vivant un instant
  DANS `#cbTimers`, une passe déclenchée hors changement de structure compte comme une destruction
  pour le témoin « aucun ÉLÉMENT du quai n'est détruit pendant les ticks », qui l'observe en
  `subtree`. Les trois causes étant traitées en amont, la boucle ne tourne plus qu'au changement de
  STRUCTURE — le seul moment où le quai est réécrit de toute façon.
· **MESURÉ APRÈS** : 8/8 le segment paraît immédiatement, 8/8 l'entrée joue pendant l'animation et
  ne laisse aucun résidu, 0 px de débordement de 320 à 700. Et le segment ne s'affiche que là où il
  TIENT (700) : à 320-430 il est retiré et l'annonce prend le relais — ce qui est le comportement
  juste, et non celui qu'un fantôme mal rempli faisait croire.
· **⚠ LA CLASSE D'ENTRÉE NE VIT PAS DANS LA CHAÎNE MÉMORISÉE** : posée dans le HTML, elle en fait
  partie — le tick suivant produit une chaîne différente, réécrit le quai et ARRACHE le segment en
  pleine animation (mesuré : elle survivait 5 fois sur 8). Elle est donc ajoutée au NŒUD après
  écriture, et `animationend` ne fait que la retirer (A68/2). La chaîne reste alors identique d'un
  tick à l'autre : le quai n'est pas réécrit et le nœud survit à son animation.

**A99. UNE PORTE NE DEVINE PAS UN NOM — ELLE DIT SA NATURE, ET L'ON NOMME APRÈS (v5.6, signalé à
l'usage : « comment as-tu trouvé l'intitulé automatique après ＋ Minuteur, c'est très mauvais et ça
ne se met pas à jour à chaque bloc »).** Le nom pressenti venait du DERNIER REPÈRE horodaté
(`tmAddName` → `tkLabels`) — une source qui n'a aucun rapport avec le bloc courant, donc incapable
de le suivre, et dont la qualité dépendait entièrement de ce qu'on avait étiqueté avant.
A85 avait déjà écrit la moitié de la règle (« la proposition n'invente pas de mot quand elle n'en a
pas ») ; elle vaut aussi pour la SOURCE : deviner à partir d'un objet sans rapport, c'est fabriquer
un mot. La porte ne dit plus que « ＋ Minuteur ».
· **LE NOM SE POSE SUR L'OBJET**, comme pour le compteur ad hoc (A86) : un ✎ sur la rangée du
  minuteur ouvre le même champ, avec le même commit. Le geste de création reste deux taps sans
  clavier ; le clavier n'entre que si l'on VEUT nommer.
· **⚠ LES GESTES VONT LÀ OÙ L'OBJET VIT** : un minuteur ad hoc n'est PAS rendu par `timerCard` —
  `runtimePanel` sépare `tl` (les minuteurs de la fiche, en cartes) de `minis` (les ad hoc, en
  rangées compactes). Ma première pose était donc du code MORT dans une branche que `t.adhoc` ne
  peut jamais atteindre. Et la SUPPRESSION existait déjà sur cette rangée (`data-tmrm`) : mon
  second gestionnaire l'écrasait silencieusement — deux `onclick` sur le même sélecteur, le
  dernier gagne. On lit le composant avant d'y greffer quoi que ce soit.
· `tmAddName`, `TM_GENERIQUE` et `.tm-add-n` (« d'après votre dernier repère ») sont PURGÉS avec la
  devinette qu'ils servaient — `check-classes` a d'ailleurs immédiatement signalé la règle morte.
· **DEUX TÉMOINS MESURAIENT LA DEVINETTE** et ont été réécrits sur la propriété : la porte ne dit
  que sa nature *quel que soit ce qu'on a horodaté avant*, le minuteur naît SANS nom, et sa rangée
  porte de quoi le nommer.

**A100. UN DÉFILEMENT LATÉRAL SE CORRIGE PAR LE GESTE, PAS PAR UN CLIP (v5.6, signalé à l'usage :
« fenêtre compte & synchronisation : le scroll se déplace de gauche à droite, surtout sur
smartphone »).**
· **PREMIÈRE TENTATIVE, ANNULÉE** : `overflow-x:hidden` sur la fenêtre. Rejetée à l'écran par
  l'auteur — « des éléments sont tronqués, notamment la barre d'input, et la ligne de scroll dans
  Safari tronque le contenu ». Il a raison : un `overflow:hidden` COUPE ce qui dépasse au lieu
  d'empêcher ce qui dépasse, et sur un défileur WebKit y réserve en plus sa gouttière. *Borner le
  symptôme n'est pas corriger la cause, et ici cela abîmait davantage que le défaut.*
· **CE QUE LA MESURE A ÉTABLI, ET C'EST ELLE QUI DÉSIGNE LE REMÈDE** : sous WebKit comme sous
  Chromium, à 320 / 390 / 430 px, déconnecté, connecté, avec un courriel de 70 caractères, avec le
  bloc admin « État de l'instance » rendu, et avec une chaîne INSÉCABLE injectée tour à tour dans
  seize conteneurs — **aucun élément de cette fenêtre n'est défilable en X, et rien ne dépasse de
  la carte**. Le contenu n'est donc pas en cause : le seul « débordement » visible est le halo
  compensé du ✕, voulu, et dont le bord reste dans le rembourrage (A76).
· **CE QUI RESTE EST LE GESTE** : `.ai-modal` est `overflow:auto`, donc un défileur sur les DEUX
  axes, et iOS laisse traîner un tel défileur horizontalement — avec rebond — même sans rien à
  faire défiler. `touch-action:pan-y` interdit ce panoramique **sans toucher à la géométrie** :
  aucun clip, aucune gouttière, aucune troncature possible. C'est exactement ce que la première
  tentative n'a pas su faire.
· **⚠ BORNÉ À LA FENÊTRE SIGNALÉE, DÉLIBÉRÉMENT** : `touch-action` se résout en prenant la
  contrainte la PLUS STRICTE de la chaîne d'ancêtres — un enfant ne peut donc pas rendre le
  panoramique horizontal à un tableau du mini-Markdown, à un bloc de code ou à une page de PDF
  zoomée. La fenêtre Compte n'héberge aucun défileur horizontal (vérifié) ; on étendra fenêtre par
  fenêtre, sur signalement, jamais d'un coup.
· **LEÇON GÉNÉRALE** : quand une mesure ne rencontre pas le défaut signalé, on ne borne pas le
  symptôme au jugé. Ou l'on cherche jusqu'à trouver ce qui, dans la MÉCANIQUE et non dans le
  contenu, peut le produire — ou l'on dit qu'on ne l'a pas trouvé.

**A101. UN FOND DE RANGÉE VA D'UN BORD À L'AUTRE DE SA CARTE (v5.6, signalé à l'usage, captures à
l'appui : « le fond de sélection ne s'affiche pas sur toute la largeur », « session en cours : le
vert ne prend pas toute la largeur »).** En voie étroite les rangées vivent dans une carte par
lettre, et c'est la CARTE qui porte les 16 px de rembourrage horizontal : la rangée commençait donc
17 px après son bord gauche et s'arrêtait 17 px avant le droit. Invisible tant qu'elle est
transparente — mais dès qu'elle prend un fond (survol, vert d'une session vive), le rectangle teinté
flotte au milieu avec deux bandes nues de part et d'autre. Mesuré à 390 px : **304 px de rangée dans
une carte de 338**. La rangée reprend les 16 px en marges NÉGATIVES et les rend en rembourrage : sa
BOÎTE va d'un bord à l'autre, son CONTENU ne bouge pas d'un pixel (titre à x=35 et épingle 285→315,
identiques avant/après). `.dir-book` reçoit `overflow:hidden` — sans quoi la première et la dernière
rangée dépasseraient des coins arrondis (aucun titre de lettre n'est collant : rien à casser).
· **⚠ UNE COMPENSATION VIT AVEC CE QU'ELLE COMPENSE (signalé dans la foulée : « tu as cassé
  l'affichage des cartes en 2/3 colonnes »)** : `.dir-book` perd son rembourrage à partir de 780 px.
  Posée au niveau racine, la marge négative y tirait les rangées 16 px HORS de leur colonne. Elle
  est bornée à `max-width:779.98px`, le palier même où le rembourrage existe. Vérifié à 390, 700,
  900, 1280 et 1600 : plus rien ne sort de sa carte, et la teinte va bien d'un bord à l'autre en
  voie étroite.

**A102. QUAND L'ALPHABET NE TIENT PAS CENTRÉ, ON L'ÉCLAIRCIT (v5.6, décision de l'auteur après
mesure).** Le clamp d'`azrCentrer` pousse les lettres aussi haut que la boîte l'autorise, et c'est
l'optimum — mais l'optimum n'est pas le centre. MESURÉ à 390 × 844 : la boîte commence à 121 px
(sous l'en-tête, pour qu'aucune lettre ne passe derrière lui), l'axe de l'écran est à 422, et un
alphabet complet mesure 650 px — il devrait donc commencer à 97. Il reste **24 px trop bas**, et
descendre les cibles au plancher WCAG de 24 px n'en rendrait que 13 : c'est géométriquement
impossible sans cacher des lettres.
· **LA SOLUTION EST CELLE DE L'INDEX DE CONTACTS D'iOS** : montrer MOINS d'entrées, un « · » à la
  place de deux lettres. L'index raccourci se centre alors exactement (mesuré : **écart 1 px** à
  320 et 390 px avec 26 lettres, contre 24 avant), les cibles gardent leurs **24 px**, et rien
  n'est injoignable — un point mène à la première lettre qu'il porte et son nom accessible les cite
  toutes les deux (« Aller à B ou C »).
· **ON NE FUSIONNE QUE DES PAIRES, ET SEULEMENT CE QU'IL FAUT** : un point qui avalerait cinq
  lettres ne serait plus un index. S'il en faudrait plus que la moitié de l'alphabet, on renonce —
  le rail se replie déjà tout seul quand il ne tient pas, ce qui vaut mieux qu'un index illisible.
· **RÉSERVÉ AUX LETTRES** : le rail des CATÉGORIES porte des pastilles de couleur, qui ne se
  remplacent pas par un point sans perdre ce qu'elles disent.
· **LA RÉCURSION EST BORNÉE À UN TOUR** (`azrCentrer(rail,true)`) : la seconde passe ne peut plus
  rien éclaircir puisque l'index tient désormais, et une boucle ici serait une boucle de rendu.
· **LES GESTES IGNORENT LES LETTRES REPLIÉES** : `snap()` filtrait sur `[data-azl]`, qui inclut les
  masquées — leurs rectangles nuls auraient faussé le mapping du glisser.
· **⚠ CE QUI N'ÉTAIT PAS EN CAUSE, ET QU'IL FAUT DIRE** : les bulles de session en tête de liste.
  Mesuré avec et sans, à 390 et à 1280 : **écart 1 px dans les quatre cas**. Le décentrage ne
  dépend que du NOMBRE de lettres, jamais du contenu de la liste.
· **TÉMOIN** : trois configurations, et il RENCONTRE SON CAS des deux côtés — à 26 lettres sur
  téléphone il exige des points, à 16 (ou en voie large) il exige qu'il n'y en ait AUCUN. Vérifié
  capable d'échouer (éclaircissement neutralisé → 2 rouges).

**A103. CINQ DÉFAUTS DU VOLET ET DE L'ACCUEIL, TOUS MESURÉS (v5.6, signalés à l'usage).**
· **« VOIR LE COMPTE-RENDU » ÉTAIT UN BOUTON MORT** : il portait `data-prelast`, un attribut émis
  UNE FOIS et câblé NULLE PART — un nom inventé à côté du `data-report` que `bindReadEvents` relie
  déjà à `exportSessionReport`. On ne rajoute pas un gestionnaire, on donne au bouton le nom du
  geste qu'il fait. *Règle : avant d'inventer un attribut, chercher celui qui nomme déjà l'action —
  un verbe qui a deux noms finit par n'en avoir aucun.*
· **LES RANGÉES COMPACTES DE MINUTEUR NE SE COLLENT PLUS** : le rail les posait à `margin-top:0`
  — mesuré, **0 px** entre deux rangées ET sous la carte qui précède, quand le volet leur donne
  8 px. Deux objets distincts qui se touchent se lisent comme un seul.
· **LA CROIX DU COMPTEUR AD HOC TENAIT SES 24 px EN HAUTEUR, PAS EN LARGEUR** : `min-height:32px`
  bornait un seul axe, la largeur valant le glyphe plus 12 px de rembourrage — **20 px** mesurés,
  sous WCAG 2.2 § 2.5.8. Le plancher se pose sur les DEUX axes.
· **LE CHAMP DE NOMMAGE AVAIT BESOIN D'UNE RANGÉE QUI ENROULE** : `.tm-label` est `nowrap`, donc
  `flex:1 1 100%` ne pouvait rien et le champ se partageait la ligne avec le nom et les deux
  boutons — **84 px de champ dans une rangée de 182**. `:has(.cn-input)` ouvre l'enroulement
  seulement quand le champ est là : 84 → **182 px**, et la rangée au repos ne change pas.
· **LE VERROU DE VEILLE PREND LE VOCABULAIRE DE SON VOISIN** : « Écran maintenu / Veille normale »
  disait deux choses différentes selon l'état et coûtait 131 px. Le bouton du SON dit « Son
  activé / Son coupé » ; celui-ci dit donc « Veille coupée / Veille active » — même grammaire, même
  longueur, l'état se lit sans réfléchir.
· **ET L'EN-TÊTE DU VOLET CESSE DE DONNER UNE LIGNE À UN SEUL BOUTON** : mesuré à 390 px, les trois
  contrôles demandaient 330 px pour 294 et « Veille coupée » tombait SEULE sur une troisième ligne.
  `#soundWarn` passe au glyphe seul sous 560 px (règle A2 : la touche perd son étiquette, jamais son
  nom accessible) — c'est le bon candidat, étant une CAUTION dont le texte entier s'affiche au tap,
  pas un contrôle dont le libellé porte l'état. **152 → 100 px** à 390, 430 et 560 ; 48 px au-delà.
  ⚠ **DEUX ESSAIS ÉCARTÉS PAR LA MESURE, ET ILS DISENT LA MÊME CHOSE** : déplacer le couloir du ✕
  sur le TITRE — en rembourrage, puis en largeur maximale — a été pire dans les deux cas (le titre
  s'enroulait SOUS le ✕, 176 px ; puis un autre contrôle montait à sa droite, donc sous le ✕).
  *Une réserve de rangée protège la ligne ENTIÈRE ; aucune borne posée sur un seul enfant ne le
  fait.* Coût dit : à 320 px le titre du volet ne tient pas sur une ligne, l'en-tête y reste à
  176 px — c'est le titre qui est long, pas la rangée qui est mal faite.

**A104. LE DÉCLENCHEUR DE FILTRE N'A QU'UNE ADRESSE : CONTRE LA RECHERCHE (v5.6, demande de
l'auteur : « il devrait apparaître à droite de la barre de recherche en tout temps »).** Il
changeait d'adresse selon le DÉFILEMENT — dans la rangée de groupement en haut de page, contre le
champ une fois l'en-tête resserré. Or les deux répondent à la même question (restreindre ce qu'on
voit), et un contrôle dont la place dépend de l'endroit où l'on se trouve dans la page est un
contrôle qu'on cherche à chaque fois. C'est le raisonnement de la planche 7b pour la recherche
elle-même, appliqué à son voisin.
· **⚠ IL Y AVAIT DEUX PLACEMENTS, ET C'EST LE SECOND QUI DÉCIDAIT** : `syncHomeNew` au défilement,
  et un `row.appendChild(ft)` à CHAQUE rendu. Corriger le premier seul laissait le défaut entier au
  chargement — le témoin l'a dit aussitôt (`dansChamp:false`). *Quand un objet est placé par deux
  chemins, corriger l'un ne corrige rien.*
· **IL PREND LA HAUTEUR DU CHAMP** (`align-self:stretch` + `aspect-ratio:1`) : il valait 38 px face
  à un champ de 48, et deux objets d'une même rangée qui ne s'alignent pas se lisent comme deux
  niveaux. Rond par construction, sans écrire un second nombre.
· **LE TÉMOIN A CHANGÉ DE VOISIN, PAS DE SUJET** : il mesurait le déclencheur contre le sélecteur de
  groupement — son adresse d'alors. Il mesure désormais « contre le champ, à sa droite, aligné », et
  **dans les deux états de défilement** : c'est cette seconde moitié qui couvre le défaut signalé.

**A105. DEUX RÉGLAGES JUMEAUX NE SE SÉPARENT JAMAIS (v5.6, signalé à l'usage : « le bouton veille
apparaît toujours en dessous du bouton son », puis « aussi en desktop dans la sidebar »).** Les deux
interrupteurs tenaient sur la même ligne à partir de 390 px et pas en dessous — mesuré : à 375 il
manquait DEUX pixels, à 360 dix-sept, à 320 trente-trois. Espérer qu'ils tiennent est une erreur de
méthode : ce qu'on veut n'est pas « qu'ils rentrent » mais qu'ils ne se séparent PAS — deux réglages
de même grammaire dont l'un tombe seul sous l'autre se lisent comme deux objets sans rapport.
Enveloppés (`.rt-togs`), ils enroulent ENSEMBLE. Mesuré : même ligne à 320 · 360 · 375 · 390 · 414 ·
430 · 560 · 700 · 900 · 1280, et dans le RAIL aussi, où le groupe (311 px) dépasse la colonne
(301 px) et enroule donc d'un bloc au lieu de se couper en deux.
· **ET LE GABARIT PORTAIT ENCORE LES ANCIENS LIBELLÉS** : seul `syncWakeBtn` avait été corrigé, si
  bien que la PREMIÈRE peinture disait « Écran maintenu » et la suivante « Veille coupée ». Quand un
  libellé est écrit à deux endroits, corriger l'un ne corrige que la moitié du temps.

**A106. UN GLYPHE VIENT DE `uiIcon`, JAMAIS ÉCRIT EN CLAIR (v5.6, signalé à l'usage : « il y a des
doublons d'icônes — le crayon pour modifier un minuteur créé existe déjà, pareil pour le
recommencer »).** La règle est posée depuis la v4.71.0 (« les anciens glyphes texte ✎ ✦ ⤓ ↺ rendaient
un dessin différent selon la police du système ») ; mes ajouts l'avaient enfreinte en réintroduisant
« ✎ » et « ⟲ » littéraux à côté des tracés `pen` et `undo` qui existaient déjà dans la table. Deux
dessins pour une même idée, c'est deux choses à apprendre — et `check-icons` ne peut pas le voir : il
vérifie que tout nom passé à `uiIcon` existe, pas qu'on ait pensé à l'appeler.

**A107. « DIAGNOSTIC CONFIRMÉ » RESTE UN ÉTAGE — TENTATIVE ANNULÉE, ET LA MESURE EST LA RAISON
(v5.6, demande de l'auteur : « déplace diagnostic confirmé dans le dépliant “x blocs faits —
diagnostic confirmé” »).** Le déplacement a été écrit et il FONCTIONNAIT : condition d'entrée avant
le démarrage (A19), trace dans l'historique après, repliée dans « ✓ n blocs faits · diagnostic
confirmé », jamais perdue entre les deux. `audit-partage` l'a rougi sur un invariant de crise — « il
regardait ailleurs : ce qu'il regarde ne bouge pas » — avec **457 px de dérive**.
· **⚠ LA CAUSE QUE J'AVAIS ÉCRITE ÉTAIT FAUSSE, ET LA MESURE L'A DÉFAITE.** J'avais attribué les
  457 px au bloc de confirmation changeant de logement : il fait **50 px replié** (mesuré), il ne
  peut pas produire cela. Ce qui vaut ~450-515 px dans cette scène, c'est la CONDENSATION R6 d'un
  passage achevé — carte de bloc 559 px à 390, 495 à 1100, contre 44 px de rangée.
· **CE QUE LA MESURE ÉTABLIT VRAIMENT, ET C'EST PLUS INSTRUCTIF** — deux faits, chacun vérifié :
  1. **`keepAnchor` NE COMPENSE RIEN DANS CE SCÉNARIO.** Il s'ancre sur la DERNIÈRE carte de bloc
     (`.ov-block[data-ovi]`) — précisément celle que le lot condense. Après le re-rendu le
     sélecteur ne matche plus, et la fonction sort par `if(!nl)return null` sans toucher au
     défilement. Mesuré `ancreSurvit:false` dans les DEUX versions du code. Tout changement de
     hauteur au-dessus du regard est donc transmis tel quel.
  2. **LE TÉMOIN EST GARÉ AU BAS DE LA PAGE** : il fait `scrollTo(0, scrollHeight)` pour signifier
     « il regarde ailleurs ». Ce qu'il mesure ensuite est donc la façon dont le NAVIGATEUR
     réconcilie un défilement collé au bout avec un document qui change de hauteur — c'est le piège
     que ce dossier a déjà consigné en **A46**, à 22 px près ; ici il vaut plusieurs centaines.
  Reproduit dans un état voisin : SANS le déplacement, dérive **79 px**, rabat 0 ; AVEC, dérive
  **1 px**, rabat −78. L'écart ne va donc même pas dans le sens que je supposais.
· **CE QUI RESTE VRAI MALGRÉ TOUT** : je n'ai pas reproduit l'état EXACT du témoin (le mien dérive
  déjà de 79 px sur le code livré, le sien de 0), donc je ne peux pas conclure que ses 457 px sont
  un artefact — ni qu'ils sont une régression. **On ne re-livre pas le déplacement sur une
  incertitude**, et l'annulation reste la bonne décision par défaut.
· **DEUX CHANTIERS SÉPARÉS EN SORTENT, ET ILS VALENT PLUS QUE LA FONCTIONNALITÉ** : (a) appliquer
  A46 à ce témoin — il ne doit pas mesurer depuis le bout de la page, sinon il mesure le navigateur ;
  (b) `keepAnchor` devrait savoir se rabattre sur un ancêtre survivant quand sa carte est condensée,
  au lieu de renoncer en silence — c'est un trou réel, indépendant de cette fonctionnalité.
· **CE QU'IL FAUDRAIT POUR LE FAIRE PROPREMENT** : que la confirmation soit une ligne-bilan DÈS le
  démarrage (« ✓ diagnostic confirmé »), qui gagne ensuite le compte des blocs dans son libellé —
  alors elle ne déménage jamais, seul son texte s'allonge. C'est une refonte de l'assemblage du
  journal, à décider séparément et à mesurer contre ce même témoin.
· **TROIS ORDONNANCEMENTS APPRIS EN CHEMIN, ET ILS RESTENT VRAIS** : le journal est construit
  ~200 lignes AVANT que la confirmation ne soit calculée dans `renderRead` (un drapeau posé après
  n'arrive qu'au rendu suivant) ; `renderOvOnly` re-rend le journal SEUL, bien plus souvent que
  `renderRead`, donc un drapeau à usage unique y est brûlé au premier passage ; et une décision
  prise dans `renderRead` ne se met pas à jour aux re-rendus du journal.

**A108. QUAND L'ANCRE DISPARAÎT, ON SE RABAT SUR CE QUE L'ŒIL REGARDE (v5.6, trouvé en cherchant
la cause des 457 px d'A107).** `keepAnchor` sortait par `if(!nl)return null` dès que son ancre
n'existait plus après le re-rendu — **sans compenser quoi que ce soit**, et en silence. Ce n'est pas
un cas rare : un lot distant qui fait avancer le parcours CONDENSE la dernière carte de bloc (R6),
or c'est exactement elle que `shareApplyAnchored` prend pour ancre. Mesuré `ancreSurvit:false`, donc
les ~500 px que la condensation retire au-dessus du regard partaient droit dans l'œil de quelqu'un
qui n'avait rien demandé. **Mesuré après : dérive 79 → 1 px.**
· **LE REPLI EST LA PROPRIÉTÉ, PAS UN SECOND SÉLECTEUR** : on capture, avant le re-rendu,
  **l'élément sous le centre de l'écran**. C'est la définition littérale de « rien ne bouge sous les
  yeux » — et c'est ce que le témoin de partage mesure, donc l'instrument et le remède visent enfin
  la même chose. Un second sélecteur écrit à la main aurait été un troisième endroit à tenir.
· **⚠ ON LE CHERCHE DANS `main`** (`elementsFromPoint`, premier élément du flux) : au centre de
  l'écran on tombe volontiers sur une couche FIXE — capsule, volet, dock — qui ne bouge JAMAIS, donc
  compenserait zéro tout en ayant l'air de compenser. Un repli qui ne peut pas échouer ne vaut rien.
· **⚠ ET SI L'ŒIL MEURT AUSSI, ON REMONTE SES ANCÊTRES** : un sous-arbre détaché garde sa chaîne
  `parentNode`, donc le premier ancêtre encore `isConnected` est un nœud réel du NOUVEAU document.
  Au pire on atteint `main`, dont le haut ne bouge pas : la compensation vaut alors zéro — c'est
  -à-dire exactement le comportement d'avant. **Ce repli ne peut rien dégrader**, ce qui est la
  condition pour toucher une fonction que tout le fichier appelle.
· **PORTÉE** : le chemin nominal est INCHANGÉ au caractère près (ancre présente → même calcul, même
  valeur de retour). Seul le cas « ancre absente ou disparue », qui rendait `null` sans rien faire,
  gagne un comportement. 983 témoins × 2 moteurs et les 25 tâches d'audit sont verts.

**A109. LE TÉMOIN DE DÉRIVE MESURAIT LE NAVIGATEUR — QUATRE DÉFAUTS D'INSTRUMENT, AUCUN DE PRODUIT
(v5.6, A46 appliqué au témoin de partage).** Il accusait 457 px sur un correctif juste. Reconstruit,
il en trouve zéro et rougit à 120 px quand on casse vraiment la propriété. Les quatre :
1. **IL SE GARAIT SUR LA BORNE** (`scrollTo(0, scrollHeight)`) : à défilement saturé, un document
   qui rétrécit se fait RABATTRE par le navigateur, et le rabat est imputé à l'app. **⚠ ET LA
   PARADE N'EST PAS UNE MARGE** — exiger 80 px de bande était géométriquement impossible (il n'y a
   qu'une centaine de pixels sous la rangée « Consulter »). On mesure LE RABAT lui-même : la borne
   d'après atteint-elle encore la position d'avant ?
2. **IL TENAIT UN NŒUD, PAS UN SÉLECTEUR** : un `innerHTML` détruit l'élément regardé, la mesure
   rendait `null`, et `null` était compté comme un échec — un rouge qui ne dit rien du produit.
3. **SON PRÉDICAT DE RÉGIME N'ÉTAIT PAS CELUI DE L'APPLICATION** : le témoin lisait « bout hors de
   vue » en `top >= 0 && top < vh-4`, l'app décide en `bottom > stickBase() && top < innerHeight`.
   Une carte HAUTE dont le bas dépasse encore est « sous les yeux » pour l'app et « ailleurs » pour
   le témoin : il exigeait l'immobilité pendant que l'app suivait le bord vif — **273 px mesurés,
   imputés à un comportement juste**. Deux définitions concurrentes d'un même régime, la divergence
   que ce dépôt a déjà payée quatre fois.
4. **SON LOT NE CHANGEAIT RIEN** : avec un seul bloc, la carte qui se condense et celle qui s'ouvre
   ont la même hauteur — journal à **30 px** près, donc le contrôle restait VERT même en retirant
   TOUT l'ancrage. L'hôte avance désormais de plusieurs blocs (le cas réel du retard rattrapé à la
   jointure) et le témoin **refuse de conclure** si le journal n'a pas bougé d'au moins 50 px.
· **⚠ ET LE FAIT LE PLUS UTILE DE TOUT LE DOSSIER : CE RÉGIME EST TENU PAR LE NAVIGATEUR.**
  Neutraliser `keepAnchor` ENTIÈREMENT laisse le témoin vert — l'ancrage natif (`overflow-anchor`)
  garde le contenu stable quand la hauteur change au-dessus. Ce n'est PAS un témoin cassé : il
  mesure la PROPRIÉTÉ (règle 11), pas le mécanisme du jour, et c'est ce que la doctrine demande.
  Corollaire à connaître avant d'écrire du code d'ancrage : **notre compensation ne sert que là où
  l'ancrage natif ne peut pas** — défilement à la borne, ou nœud d'ancrage supprimé. Partout
  ailleurs elle est un filet, pas le porteur.
· **BALAYAGE DES AUTRES TÉMOINS GARÉS SUR UNE BORNE — UN SEUL AUTRE CAS, ET TROIS NON-DÉFAUTS
  QU'IL FAUT NOMMER** (règle A56 : un balayage qui tait ses non-défauts finit par les faire
  « corriger »). Le piège n'est PAS « se garer au bout » : c'est **comparer une position de part et
  d'autre d'un changement de hauteur alors qu'on est au bout**. Sont donc légitimes, et le restent :
  le menu ⋯ défilé à son extrémité (`m.scrollTop=m.scrollHeight`) — la borne EST le sujet, « la
  dernière rangée est-elle atteignable », et rien ne change de hauteur ensuite ; la sonde qui écrit
  `scrollTop=999999` pour LIRE le maximum puis le restaure ; la sidebar de l'accueil, dont on
  vérifie précisément que le bas est joignable. Le seul à corriger était la barre de référence :
  son `scrollTo(0,1200)` est ÉCRÊTÉ sur un document plus court, donc « la barre reste visible loin
  dans la page » pouvait se vérifier sans qu'on soit jamais parti — il mesure désormais qu'il a
  bien défilé. Là non plus la borne ne fausse rien (la barre est FIXE) : c'est le CAS qui manquait.
· **CE QU'AUCUN TÉMOIN NE COUVRE, ET IL FAUT LE DIRE** : le repli d'A108 et l'ancre sur l'œil en
  régime 2 sont mesurés utiles à la borne (79 → 1 px) — précisément la position que ce témoin
  s'interdit désormais. Les deux sont conservés parce qu'ils **retombent sur un no-op** quand ils
  ne trouvent rien, jamais parce qu'un contrôle les prouve.

**A110. « DIAGNOSTIC CONFIRMÉ » EST UNE LIGNE DU JOURNAL, ET ELLE N'Y DÉMÉNAGE JAMAIS (v5.6,
demande de l'auteur — re-livré après l'annulation d'A107).** Avant le soin, la condition d'entrée
EST la question et reste une carte en tête du flux (A19). Une fois démarré, elle ne conduit plus
rien : c'est une TRACE, et sa place est celle des traces — la tête du journal, dont elle est
chronologiquement le premier élément.
· **CE QUI MANQUAIT À LA PREMIÈRE TENTATIVE, ET QUI EST ICI** : la garantie de non-déménagement.
  La ligne ouvre le journal dès le démarrage (« ✓ diagnostic confirmé ») ; quand le premier
  passage s'achève, la ligne-bilan des blocs faits **l'absorbe** au lieu de la pousser — seule sa
  légende s'allonge (« ✓ n blocs faits · a→b · diagnostic confirmé »). Mesuré : **y = 191 px avant
  comme après**. La fusion n'a lieu que si la ligne-bilan commence au PREMIER passage ; sinon la
  confirmation garde sa propre ligne, à la même place.
· **DANS LE DÉPLIANT, C'EST UNE RANGÉE COMME LES BLOCS** (demande de l'auteur) : verser les
  critères en vrac mettait sur le même plan quatre lignes de contenu et n rangées de blocs. Elle
  prend donc UNE rangée de la même anatomie (✓ · titre · compte · chevron), qui déroule ses
  critères d'un tap. Deux niveaux, une seule grammaire.
· **ELLE SE CALCULE DANS LE JOURNAL, JAMAIS PAR UN DRAPEAU** : `renderOvOnly` re-rend le journal
  SEUL, bien plus souvent que `renderRead` — un drapeau à usage unique y serait brûlé au premier
  passage. Les trois pièges d'ordonnancement d'A107 sont ainsi désarmés plutôt que contournés.
· **⚠ ET LE HARNAIS A IMMÉDIATEMENT TROUVÉ UN DÉFAUT PRÉEXISTANT** : `.ovr-chev` mesurait
  **2,13:1**. Rien ne pouvait le voir — la ligne-bilan n'existait qu'après un passage achevé, donc
  sur aucune des surfaces qu'`audit-a11y` monte. Le chevron prend l'encre de sa ligne
  (`color:inherit`). *Un défaut HORS PORTÉE n'est pas un défaut absent* (leçon v4.75.0, rejouée à
  l'identique) — et `aria-hidden` n'exempte pas du seuil, le glyphe reste peint.

**A111. LES RÉGLAGES DESCENDENT AU PIED — L'ÉTAT VIVANT PASSE DEVANT (v5.6, signalé à l'usage :
« deux boutons utilisés périodiquement prennent autant de place avant les minuteurs-compteurs-
journal d'action »).** A105 avait raison de rendre les deux interrupteurs INSÉPARABLES, et tort de
les laisser dans l'en-tête de famille : enveloppés, ils enroulaient ensemble — **ensemble sur une
SECONDE LIGNE**, y compris dans le rail de 301 px où le groupe en demande 311. Une rangée entière
au-dessus du contenu vivant, pour deux réglages qu'on touche une ou deux fois par soin.
· **C'EST UNE QUESTION DE NATURE, PAS DE PLACE** : le son et le verrou de veille sont des
  RÉGLAGES ; les minuteurs, les compteurs et le journal sont de l'ÉTAT. L'ordre ECAM met l'état
  d'abord, et le rail applique déjà la même idée (« l'illimité en dernier »). Ils descendent donc
  au PIED du panneau (`.rt-set`), après ce qu'ils règlent, séparés par un filet — jamais par un
  titre : deux interrupteurs se reconnaissent à leur forme, les annoncer serait du bruit.
· **ILS Y GARDENT LEURS MOTS** (A103) : l'état se lit sans réfléchir, et l'on n'a pas eu à les
  compacter au glyphe seul — ce qui aurait été la mauvaise réponse, puisque c'est le LIBELLÉ qui
  porte l'état d'un interrupteur. Mesuré à 320 · 390 · 430 · 1280 : jumeaux sur une même ligne,
  0 px de débordement, en-tête du rail ramené à **19 px**.
· **UNE RÈGLE MEURT AVEC SA CAUSE** : `.rt-wl` masquait « silencieux ? » sous 560 px parce que la
  rangée d'en-tête était pleine. Elle ne l'est plus — l'avertissement retrouve ses mots (une
  CAUTION muette n'avertit de rien) et la classe est PURGÉE, épitaphes posées aux deux sites qui
  la citaient (règle 14 + A72). Au pied, à 320 px, il prend sa propre ligne : **là, cela ne coûte
  rien.**

**A112. UN ATTRIBUT ÉMIS SANS LECTEUR EST UN CONTRÔLE QUI A L'AIR VIVANT — `check-actions`
(v5.6, généralisation du défaut « Voir le compte-rendu »).** A103 avait corrigé le cas d'espèce :
`data-prelast`, émis UNE fois et câblé NULLE PART, à côté du `data-report` que `bindReadEvents`
relie déjà à `exportSessionReport`. **Rien dans le dispositif ne pouvait le voir** — ce n'est ni
une classe, ni une icône, ni une couleur ; le bouton s'affiche, se survole, se focalise, et ne
fait RIEN. Dans une aide d'urgence, c'est le pire mode de défaillance.
· **LA RÈGLE EST AUTO-EXÉCUTOIRE DEPUIS** : tout `data-x=` écrit dans un gabarit doit avoir un
  LECTEUR dans le fichier — sélecteur `[data-x]` ou `[data-x="…"]` (les règles CSS comptent),
  `dataset.x`, ou `get/set/has/removeAttribute('data-x')`. Vérifié CAPABLE D'ÉCHOUER en
  réintroduisant `data-prelast` : rouge, avec le nom de l'attribut.
· **TROIS ATTRIBUTS MORTS SONT PARTIS AVEC** (règle 14) : `data-ai` (rangée de document de
  l'éditeur), `data-jli` (jalon, aux deux sites), `data-tgk` (vocabulaire du journal) — des
  repères d'index que plus rien ne lisait.
· **LES EXEMPTIONS NOMMENT LEUR LECTEUR, jamais leur raison** : `data-upkind` existe pour
  `audit-upload`, `data-i` comme poignée de mesure. Une liste d'exemptions sans lecteur nommé
  devient l'endroit où l'on range ce qu'on n'a pas compris — et le contrôle échoue aussi quand une
  exemption n'a plus d'objet, sinon la liste finirait par mentir.
· **⚠ CE QU'IL NE VOIT PAS, ET C'EST DIT DANS SA SORTIE** : un attribut lu par une expression
  CALCULÉE (`el.dataset[nom]`, un sélecteur assemblé) sort de la portée d'un contrôle statique —
  même limite que les noms d'icône calculés de `check-icons`. Il attrape l'ORPHELIN, pas
  l'indirection ; c'est exactement le cas qui l'a fait écrire.

**R6. LE PASSÉ S'ANNONCE ET SE TIRE.** Tout passage complet et non courant devient une chip, et la
rangée de chips se replie DÈS QU'ELLE EXISTE en ligne-bilan « ⌄ fait · ✓ n passages · a→b », qu'un
tap déplie sur place. Les deux invariants du journal sont intacts, et ce sont eux qui rendent le
repli admissible : un passage INCOMPLET n'est jamais une chip, le BOUT est toujours une carte.
ACHÈTE : le bloc seul au centre, ~11 objets à l'écran contre 25.
⚠ v5.6 — LE COMPOSANT CHIP EST PURGÉ (règle 14, zéro émission vérifiée) : DÉPLIÉE, la ligne-bilan
rend une CARTE DE RANGÉES (« ✓ n · titre · passage k/n · compte mono »), pas une rangée de chips.
Une chip abrège à treize caractères — sans importance tant qu'elle est repliée, rédhibitoire à
l'instant où l'on DÉPLIE, puisqu'on vient justement relire ce qui a été fait. Même grammaire que le
parcours : « la liste des blocs » se lit pareil partout.
⚠ CONSÉQUENCE MESURÉE : le journal ne grandit plus, donc à 390 px le contrôle d'avancement est
souvent DÉJÀ visible à la réouverture — `landOnBout` a alors raison de ne pas défiler, et le témoin
de réentrée mesure les DEUX régimes plutôt que d'exiger un atterrissage qui n'a plus lieu d'être.

**R9. LE PIED DE CARTE NE PORTE PLUS QU'UN GESTE.** Il en portait trois (⚡︎, ⏱, Vérifier) et la
pile dépassait le plafond de 25 % de la hauteur de carte sur un bloc court. Deux ne sont pas des
gestes de BLOC par nature — une complication survient quand elle survient, un horodatage se pose à
n'importe quel moment : ils sont partis au dock. **L'ACCUSÉ DE RÉCEPTION LES A SUIVIS** : la règle
« la réponse vit là où le geste a eu lieu » (M11) n'a pas bougé d'un mot, c'est le geste qui s'est
déplacé — le laisser derrière aurait produit DEUX réponses à un seul geste. `tkAckHtml`,
`state.tkAck` et les règles `.tk-ack*` sont purgés (règle 14).

**DEUX OBJETS, DEUX NATURES — ÉTAT EN HAUT, COMMANDES EN BAS.** Ceci ROUVRE la v4.25.0 (« deux
rangées, deux natures ») et la règle « une seule zone fixe, en haut ». L'ESPRIT de v4.25.0 est
conservé — commandes ≠ état, c'est l'architecture ECP/ECAM — mais la FORME est inversée : l'ÉTAT
monte dans une CAPSULE, les COMMANDES descendent dans un DOCK au pouce. La règle du chrome bas
visait les NOTIFICATIONS FLOTTANTES (règle 11), pas une surface de commandes stable ; trois risques
nommés et traités au code : safe-area iOS, clavier virtuel (A1), 320 px (A2).
GAIN MESURÉ : chrome haut **175 → 131 px** à 390 px, trois `border-bottom` empilés en moins.
⚠ `fitCtrlRow` est SUPPRIMÉE avec la rangée qu'elle ajustait — mais son appelant enchaînait
`fitCtrlRow()` puis `syncHdrScroll()`, et **le second appel reste** : `--hdr-h` et `--stick-top`
sont consommés par la capsule, le rail A→Z, le rail de lecture, `stickBase()` et le `scroll-margin`
qui empêche le masquage total d'une cible d'ancre (exigence AA, sonde 2.4.11).

**VOLETS SYSTÈME — DOCTRINE D'OCCULTATION.** L'occultation COMMANDÉE est conforme ECAM/QRH
(appeler une page remplace la page affichée) ; ce que la doctrine interdit, c'est l'occultation non
commandée et l'occultation piégeante.
- **V1.** Un volet ne s'ouvre que sur tap d'une touche du dock. Fermeture TRIPLE : re-tap, ✕ ≥ 44 px,
  tap hors volet — plus le retour système, qui passe par le même chemin. Rien ne bouge derrière (le
  volet est `fixed` : il ne change aucune géométrie de flux, le témoin M11 tient par construction).
- **V2.** L'alarme reste TOUJOURS en vue : capsule en HAUT, volets en BAS. Même volet ouvert,
  l'ambre qui pulse est visible (règle FMA de l'ECAM).
- **V3.** Hauteur plafonnée à ~45 % de la hauteur VISIBLE : jamais plein écran, le contexte reste
  lisible. Si une étape critique est non cochée, le volet l'annonce EN TÊTE (gestion d'interruption,
  AC 120-71B §5.5) — ce qu'on allait faire doit survivre à ce qu'on vient d'ouvrir.
- **⏱ L'HEURE PRIME.** Le tap pose l'horodatage IMMÉDIATEMENT au journal (l'instant du TAP, pas
  celui de la saisie) ; le volet n'est que la nomination facultative, annulable et renommable après
  coup. Pas de modale en crise. `tkNoteNow` reste le point d'écriture unique — on l'APPELLE, on ne
  le réécrit pas.
- **⚡︎ BIFURCATION ANNONCÉE.** Rangées ≥ 56 px : nom en toutes lettres + condition d'entrée +
  destination (« → bloc 9 · retour ↩ 7 »). On sait AVANT de taper où l'on va et qu'on reviendra.
  **À UN SEUL ÉVÉNEMENT, IL N'Y A PAS D'INDEX** : la touche porte son NOM et l'on entre d'un tap —
  ouvrir une liste d'un élément pour y choisir cet élément est le bouton mort de la doctrine, en
  plus lent. Et l'on ne propose pas d'entrer là où l'on est déjà : à un événement la touche
  disparaît, à deux la rangée courante s'annonce et cesse d'être tapable.

**NAVIGATION D'ACCUEIL UNIFORMISÉE — UNE LISTE, DEUX CLÉS.** Le sélecteur « A–Z | Catégories »
choisit la CLÉ DE GROUPEMENT de la MÊME liste, et le rail droit est le MÊME index dans les deux
modes (lettres ↔ pastilles de catégorie). On ne perd jamais de fiche en changeant de clé : c'est un
changement d'ordre, pas de contenu — et c'est ce qui distingue un groupement d'un FILTRE. Les
filtres, eux, gardent leur déclencheur à badge chiffré, et leur RÉSUMÉ en toutes lettres rejoint
l'en-tête de section (« · filtres : Perso · aides ») : un filtre posé ne doit jamais être invisible.
La SESSION VIVE est le seul objet sombre de l'accueil — c'est le même objet que la capsule de crise,
on le reconnaît sans lire.

**PARTAGE — CE QUI EST FERMÉ AU SCRIBE.** Exactement quatre gestes (`SHARE_KINDS_LEAD`) : décocher,
remettre un minuteur à zéro, démarrer, terminer — tous destructeurs ou structurants. Cocher
appartient au scribe : l'avancement est PARTAGÉ et chaque ligne porte son attribution. Une commande
fermée au scribe **n'apparaît pas éteinte : elle n'apparaît pas** (la touche ⚡︎ du dock n'existe pas
pour lui ; promu lead, elle paraît sans qu'aucune géométrie ne bouge).

