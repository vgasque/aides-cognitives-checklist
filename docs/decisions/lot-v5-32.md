# Lot v5.32 — le moment d'une étape (A382)

> Fichier normatif, suite de [`lot-v5-31.md`](lot-v5-31.md) (A377-A381). Les numéros A sont des
> adresses : ne jamais renuméroter. Demande de l'auteur (25/09/2026) : dans un bloc parcouru
> plusieurs fois, « on avait tendance à cocher une étape dont le moment n'était pas encore venu »
> (ACR : l'adrénaline « après le 3ᵉ choc » au 1ᵉʳ passage), sans passer par une complication ni
> par un bloc « 3ᵉ choc ? ». Maquettes sur canevas (page « Moment d'une étape », M0-M7), revues fil
> par fil ; la note verte « Retenu pour l'implémentation » en est le résumé.

## A382 — une étape dit QUAND elle se présente (v5.32.0)

**Le défaut.** « Continuer » exigeait toutes les coches du passage. Une étape qui ne se fait qu'au
3ᵉ choc devait donc être cochée faussement pour avancer, et depuis la v5.31 cette fausse coche
lançait « prochaine dose ».

**Le modèle** (sur l'item, `migrate` le valide) :
- `from: {counter, n}` — COMMENCE quand ce compteur atteint n. Absent : dès le 1ᵉʳ passage.
- `repeat` — PUIS REVIENT : `due` à l'échéance du minuteur que relance la coche (`starts`, ou
  `counts` sur un compteur à `timerId`) · `once` une seule fois · `need` au besoin. Absent : à
  chaque passage.
- Deux doses = deux étapes (amiodarone 300 `from` 3 `once`, 150 `from` 5 `once`).
- `momentOf` est PURE (compte, état du minuteur, « déjà faite » injectés) ; `stepMoment` la
  branche sur la session ; `visitNeed` dit ce que « Continuer » attend, et `instComplete` la suit.

**Le rendu** (`stepsListHtml`, un seul générateur) :
- **Pas encore** (`mo-wait`) : rangée et case en pointillé, sans `data-ck`, la règle en étiquette
  dans la marge d'A381 (« Chocs délivrés ≥ 3 », « À l'échéance »), dessous la progression
  (pastilles · « encore 2 ») ou le minuteur attendu, et « Faire maintenant » sur la même ligne.
  Elle ne retient pas « Continuer ».
- **Condition remplie** : la case revient SUR PLACE, même hauteur (A9 : la ligne du dessous est
  réservée d'un état à l'autre), sans défilement ni alerte — « ✓ Chocs délivrés ≥ 3 » en vert,
  « Échu » en ambre. `momWatch` (tick, coche) re-rend la carte ancrée quand un compte ou une
  échéance change un moment de la visite courante.
- **Une seule fois, faite** (`mo-gone`) : « Faite », plus de case.
- **Au besoin** : cochable, `data-cko` — ne compte que cochée.
- **Rangée cochée** : l'étiquette garde la règle de départ (`momDone`) — rien ne change sous le doigt.

**Décisions des fils de commentaires** (à ne pas rouvrir sans l'auteur) :
- « Faire maintenant », et jamais « en avance » : le compteur peut être mis à jour après coup, l'app
  ne qualifie pas le geste — elle consigne l'heure.
- Étiquettes de 2-3 mots ; le détail vit sur la ligne du dessous.
- Un compteur n'a pas de maximum : la tuile affiche le compte seul.
- Le minuteur de « à l'échéance » n'est jamais choisi une 2ᵉ fois. Coche sans minuteur : l'option
  reste visible, grisée, « aucun minuteur lié ». Minuteur retiré plus tard : repli « à chaque
  passage » (l'étape ne disparaît jamais), signalé en ambre dans l'éditeur.

**Éditeur** : « Commence » et « Puis » dans les outils de l'étape, après « Ce que fait la coche »,
réglés sur place (le focus reste) ; la règle se lit au repos sous l'étape. Parcours à plat et Page
l'annoncent sans état (`momRuleHtml`).

**Prompt IA** : section « MOMENT D'UNE ÉTAPE DANS UNE BOUCLE », schéma, vérification n° 18 — un
geste de la boucle qui n'arrive qu'à un tour ou à son délai y reste avec son moment ; le seuil ne
s'écrit plus dans le libellé. **Exemples** : ACR (adrénaline ≥ 3 puis à l'échéance, amiodarone
300/150 une seule fois, adrénaline non choquable à l'échéance) ; Anaphylaxie (« Adrénaline IM »
du bloc réfractaire à l'échéance de la réévaluation).

**Réglementaire** : § 2 « Le cas du moment d'une étape » écrit avant le code — règle de l'auteur
appliquée à un compte saisi ou à un minuteur lancé par l'équipe, régime des jalons.

**Témoins.** `tests.html` : `momentOf` (dix cas). `audit-doctrine` A382 : attente, étiquette et
pastilles, « Continuer » libre, « Faire maintenant », seuil, attente d'échéance, une seule fois,
échu, A9. `audit-prompt` : documenté, et `from`/`repeat` traversent `migrate` (ce qui pend tombe).
