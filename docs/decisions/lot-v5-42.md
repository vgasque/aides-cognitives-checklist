# Lot v5.42 — la revue « à tout moment » se dessine (A449)

> Fichier normatif, suite de [`lot-v5-41.md`](lot-v5-41.md) (A441-A448). Les numéros A sont des adresses :
> ne jamais renuméroter. Demande de l'auteur du 04/10/2026 ; forme choisie sur canevas (« Revue non bloquante »,
> planches Aujourd'hui, A, B, C — retenue : A + C).

## A449 — la revue ne ressemble plus à ce qui retient la suite (v5.42.0)

**La demande.** « Sur les blocs de type Revue (ex. causes réversibles), comment mieux faire passer le message qu'on
n'est pas obligé de cocher ces cases tout de suite, qu'on peut le faire à n'importe quel moment et que ce ne sera pas
bloquant pour passer à l'étape suivante ? Sans écrire de texte, en jouant sur le design. »

**Ce qui disait le contraire (mesuré dans le code).** Le modèle était juste depuis A396 (la revue ne retient jamais
« Continuer », `visitNeed`), c'est le DESSIN qui affirmait l'obligation, par quatre signaux :
1. la grille s'ouvrait d'office tant que la revue n'était pas faite (`open = !rs.done`) : huit cases de plus DANS le
   fil, qui repoussaient « Continuer » sous le quai — l'œil lisait huit étapes à faire avant de passer ;
2. une CASE (pointillée, mais une case) dans la colonne des cases obligatoires ;
3. la ligne « 0/8 à faire » au bleu `--act`, le registre de l'ACTION (règle 8 : ce qui ne demande rien n'a pas de
   couleur) ;
4. des mots d'obligation : « à faire », « en cours ».

**La forme retenue (A + C du canevas).**
- **Fermée.** La rangée-revue ne s'ouvre qu'au geste (`state.revOpen`, plus de valeur par défaut tirée de l'état).
- **Hors de la matière des étapes.** Pas de fond `--amb-2`, contour pointillé `--ctl-line` — le vocabulaire qu'A382 a
  donné à « pas maintenant, ne retient pas Continuer » (étape en attente de son moment). Le libellé descend d'un cran
  (`--t-item`, 15) : l'étape-revue n'est pas un geste du fil (amende A345 pour ce seul cas).
- **Une jauge, pas une case** (`revRingHtml`) : un segment par hypothèse, piste FINE (`--ctl-line`, 2 px) et
  segments faits ÉPAIS à l'encre (4 px) — une quantité qui s'accumule, dans n'importe quel ordre, pas une case qui
  attend. Au-delà de douze hypothèses, un arc continu (les segments deviendraient des points). Pleine et verte à n/n,
  ✓ au centre et le mot « faite » (règle 8 : jamais la couleur seule). `--line-strong` a été essayé pour la piste et
  ÉCARTÉ : #2c313a la nuit, invisible sur la carte.
- **Une ligne neutre.** « k/n » en `--ink-2`, chevron ; « à faire » et « en cours » retirés, l'icône grille aussi (la
  jauge identifie). Un texte `sr-only` dit au lecteur d'écran ce que le dessin dit à l'œil.
- **Ouverte : des JETONS, pas une liste.** Ni case à gauche ni numéro ; un jeton bordé (`--ctl-line`), vert pâle et
  bordé de vert une fois coché, ✓ à DROITE dans une place réservée (32 px). Cocher ne déplace RIEN du libellé : ni
  « ✓ » devant la réponse (`::before` neutralisé), ni changement de graisse (demande de l'auteur : « ne pas décaler le
  texte de la coche validée par rapport aux non validées »). La réponse (« :: ») SUIT le libellé dans la ligne au
  lieu de passer dessous : 44 px par jeton au lieu de 56 (« ne pas prendre trop d'espace »).
- **Colonnes au libellé.** « Les libellés des revues peuvent être longs, donc pas forcément deux colonnes. » La grille
  est `repeat(auto-fit, minmax(min(100%, n × 0,92ch + 42px), 1fr))`, où `n` (`--rv-ch`, posé par `revGridHtml`) est
  le plus long LIBELLÉ en caractères — la réponse peut passer à la ligne, elle ne compte pas. `auto-fit` décide sur la
  largeur RENDUE : juste sous zoom (règle 10) sans media query. Le 0,92 est MESURÉ (Manrope 700 à 15 px : un libellé
  réel occupe 0,76 à 0,96 `ch`, sur dix libellés cliniques) ; à 390 px deux jetons par ligne tiennent jusqu'à environ
  onze caractères — la fiche d'exemple (« Hypo / hyperkaliémie », 20) reste donc sur une colonne au téléphone, et
  passe à deux là où la colonne d'action est assez large.
- **La tête est le bouton.** `role="button"`, `data-revtg` et `aria-expanded` passent de la rangée à `.rv-head` : la
  rangée contenait des cases (rôle interactif imbriqué). Anneau de focus au patron des étapes. `revAfterCheck` repeint
  jauge et ligne depuis la tête.
- **« Nouvelle revue » reste au PIED de la grille.** La première maquette du canevas l'avait collée au chevron de la
  tête pour gagner 40 px : refusé — elle efface toutes les coches de la revue pour la session, et un geste destructeur
  à côté d'un geste fréquent, c'est une erreur de doigt sous stress. Le témoin exige plus de 200 px entre les deux.

**Formes écartées (canevas).** B, le tiroir collé au-dessus du quai qui suit la session d'un bloc à l'autre : le
signal « à tout moment » le plus fort, mais il sort la revue du fil (contre A396, « posée là où l'on doit y penser »)
et ajoute un élément flottant au mode crise (règle 11). Un mot « facultatif » ou « à tout moment » : refusé par la
demande elle-même.

**Ce qui ne change pas.** Le modèle (clés `r:revue:index`, A398), le partage, le compte-rendu, la carte de session
sous le bloc (même `revGridHtml`, donc mêmes jetons), le parcours et la Page.

**Témoin.** `audit-doctrine` « Revue · A449 » : sur la fiche d'exemple en session à 390 px — fermée d'office, pas de
case mais une jauge vide à 0, ligne hors `--act`, « Continuer » actif revue à 0, une colonne pour les libellés longs,
DEUX pour la même revue aux libellés raccourcis (sans ce cas, « une colonne » serait vert même sans adaptation),
libellé immobile à la coche (position et largeur), jauge remplie à la première coche, « Nouvelle revue » au pied et à
plus de 200 px du chevron. Rejoué sur l'`index.html` d'avant : cinq rouges, exactement les invariants changés.
