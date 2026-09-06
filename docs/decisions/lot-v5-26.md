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
