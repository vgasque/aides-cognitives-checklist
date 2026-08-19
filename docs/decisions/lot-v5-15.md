# Lot v5.15 — les barres flottantes deviennent lisibles (planches 17 et 18)

> Doctrine du lot v5.15 — **A222 à A224**. Deux planches Claude Design arbitrées par l'auteur
> (19/08/2026) : « Mode sombre — bandeau session en cours et dock » (planche 17, direction **1a**
> retenue sur maquettes comparatives, 1b écartée) et « Démarrer la session — quand du contenu
> passe sous le quai » (planche 18, lots **P** et **2a**). Les planches se posent dans l'ordre
> 17 puis 18 ; toutes les mesures citées viennent des maquettes, rejouées sur l'app par le témoin
> « QUAI · le geste d'entrée se détache de sa barre » (`audit-doctrine.mjs`) et par `audit-a11y`.

## A222 — la nuit, la matière système MONTE (planche 17, direction 1a)

**CONSTAT.** En thème clair, la carte de session et le dock sont les seuls objets sombres du
produit : 14,4:1 contre l'ambiance — on les trouve sans lire. La nuit, l'ambiance descend à
`#0d0f13` et `--sys` restait à `#171a20` : 1,09:1 contre le fond, 1,12:1 contre une carte de
travail. Les trois matières n'en faisaient plus qu'une, et c'est exactement ce qui se voyait à
l'usage. L'ombre portée du dock (`0 -6px 24px rgba(0,0,0,.22)`, du noir pur en dur) ne rattrapait
rien : assombrir du noir ne produit aucun contraste (v4.71.0).

**DÉCISION (1a, « recommandée », retenue).** `--sys` passe de `#171a20` à `#333b47`, au-dessus de
la matière travail (`#1e232b`) au lieu d'en dessous. Le jour, système = la matière la plus
SOMBRE ; la nuit, la plus CLAIRE — dans les deux cas **la plus éloignée des deux autres, qui est
la vraie règle**. Mesuré : matière 1,69:1 contre l'ambiance, périmètre `--sys-edge` (`#7c879a`)
à 5,3:1 contre l'ambiance en ombre INTERNE de 1 px (le patron de la pastille Compte — aucun coût
de hauteur), posé sur `.ls-card`, `.sd-in`, `.ds-card` et `#cbTimers`. Encres rejouées sur la
nouvelle matière : `--sys-ink` 9,4:1, `--sys-ink-2` 4,5:1, `--ok-sys` 6,5:1, `--crit-sys` 5,7:1.
La variante **1b** (matière inchangée + bord `#6f7a8b` + arête de lumière) gardait la doctrine
intacte mais laissait la masse confondue (1,09:1), tout reposant sur 1 px — écartée.

**LES COÛTS, NOMMÉS, ET CE QU'ILS OBLIGENT À DÉPLACER :**
- le creux de la touche ⏱ perd un cran sur matière plus claire : il passe au token `--sys-key`
  (`.10` jour → `.14` nuit) — il vivait en `rgba()` en dur, garde-fou `check-colors` ;
- sur la capsule éclaircie, le filet ambre de l'alarme (`--warn-line`) tombait de 3,5:1 à
  2,25:1 : il passe au token `--alarm-bd` — `--warn-line` le jour, `--warn-sys` la nuit (6,8:1).
  L'aplat et l'encre ne changent pas. C'était le seul avantage technique de 1b, et il est payé ici ;
- ≥ 1200 px la capsule QUITTE la matière système (`body.chrome-hdr`, elle monte dans l'en-tête) :
  l'anneau y est annulé — on cerclerait un objet transparent ;
- **attrapé par `audit-a11y` en posant le lot, hors maquettes** : ouverte, la touche ⚡ prenait le
  creux générique `.on` (`--sys-2`, 12 % de blanc composé sur la matière éclaircie) et l'encre
  `--crit-sys` de « Complications · n » tombait à 3,9:1. `.sd-key.sd-cx.on` prend `--sys-hi` — le
  vocabulaire de `.sd-exo.on` — où elle tient 4,8:1 en sombre, 6,4:1 en clair. Leçon : les
  maquettes mesurent la matière de BASE ; les états composés (`.on`, survols) se mesurent sur
  l'app, et c'est le rôle des harnais.

**DEUX RÔLES, DEUX TOKENS, PORTÉS À LA MATIÈRE SYSTÈME.** Le filet des contrôles posés sur
matière système ne tenait 3:1 dans aucun thème (1,83:1 clair, 1,6 sombre — exemption 1.4.11 :
identifiables par leur libellé). La doctrine `--ctl-line` y est portée : `--sys-line` DESSINE
(séparateurs `.ds-row` — un séparateur n'est pas une cible), **`--ctl-sys` se VISE** (`#6a7381`
clair 3,3:1, `#7c879a` sombre 3,1:1) sur `.ls-card .btn`, `.ls-card .ls-end`, `.ds-chip`,
`.ds-in` et `.sd-key.sd-exo`. Les états plus spécifiques (`.btn.primary`, `.sd-exo.on`) gardent
leur bordure propre ; la règle est écrite APRÈS les déclarations de base — à spécificité égale,
l'ordre tranche.

## A223 — l'ombre du quai passe au token, et le jour elle PROJETTE (planche 18, lot P)

Le quai est opaque : son bord contre le contenu tient 14:1 — le défaut n'est pas là. Il est dans
ce qui l'entoure : sur téléphone la colonne de lecture fait 358 px et le quai 362 — un tableau de
posologies touche la barre, et dans un champ chargé rien n'est pré-attentif. Sur desktop le quai
flotte avec 260/340 px de marge : son couloir calme existe par construction — c'est pourquoi
« en desktop ça va encore ».

`.sd-in` portait son ombre en dur (`0 -6px 24px rgba(0,0,0,.22)`) : du noir pur, identique dans
les deux thèmes, donc aveugle au thème. Elle passe au token `--shadow-up`, dont la valeur claire
s'élargit sur les trois axes — **6→12 px, 24→32 px, 6 %→26 %** — et repasse à l'ENCRE du thème
(`rgba(20,24,29,.26)`) comme toutes les autres ombres : c'est UNE matière qui projette, seule sa
direction change (v4.78.0). `.bkr` consommait déjà le token. La nuit ne projette toujours pas
(`--shadow-up:none` en sombre, override préexistant, non dupliqué) : la séparation nocturne vient
du périmètre d'A222. **Rien ne bouge dans le flux** : ni hauteur, ni réserve, ni `--dock-h` ni
`--sheet-h` — une ombre ne prend pas de place ; si une mesure bouge, c'est un défaut.

**DEUX PISTES ESSAYÉES ET ÉCARTÉES sur maquettes, à ne pas reproposer « pour renforcer » :**
un fondu vers l'ambiance (ce qui passe sous le quai est la matière TRAVAIL, pas l'ambiance :
blanc contre ambiance = 1,06:1 en clair, 1,22:1 en sombre — invisible ; et sur le quai sombre la
teinte se lisait comme une bande claire, à l'envers) ; une bande de flou `backdrop-filter` (sur
une barre à coins arrondis le raccord ne se règle pas — sans recouvrement il reste des angles
nets dans l'arrondi, avec recouvrement le flou échantillonne la barre sombre et étale un halo
noir autour d'elle).

## A224 — le bleu de l'action prend sa valeur sur matière système : `--act-sys` (planche 18, lot 2a)

Le produit avait déjà `--ok-sys`, `--warn-sys` et `--crit-sys` : des registres à valeurs propres
et FIXES des deux thèmes, parce que les valeurs du thème clair ne tiennent pas sur la matière
système. **Il manquait `--act-sys`.** `--act` ne tenait que 1,68:1 sur le quai : le texte du
geste d'entrée était lisible (blanc sur bleu, 8,6:1) mais la FORME du bouton se confondait avec
sa propre barre — le défaut nommé et corrigé par l'audit v5.10.0 sur « Reprendre » de la carte de
session (1,69:1), jamais rejoué sur le geste d'entrée.

`--act-sys:#7ab3f0` — 7,2:1 contre le quai clair, 5,1:1 contre le quai nocturne éclairci d'A222 ;
encre `--on-sys-fill` 8,7:1. C'est un REGISTRE, pas un alias de `--act` : ne pas le dériver en
`color-mix` (bloc retiré en v5.6), ne pas le redéclarer en sombre. **Le coût, nommé : le bleu du
quai n'est plus le bleu de la page** — déjà le régime des trois autres registres. Seule la
déclaration de `.sd-key.sd-start` change : les autres consommateurs de `--act` (liens, bordure du
nœud courant, chips) restent sur la matière du thème.

**Deux canaux de plus, gratuits en hauteur :**
- le libellé passe au corps de l'ACTE (`--t-step`, 17,5 px — A6 : « le grand corps appartient à
  l'acte ») sans changer le gabarit de 50 px ; à 320 px, « Confirmé — démarrer la session »
  s'ellipse par le `-webkit-line-clamp:2` existant au lieu de pousser la barre (mesuré : quai
  62 px, touche 50 px, inchangés) ;
- sous 430 px EFFECTIFS, « Exercice » passe au glyphe seul — le patron des deux ouvertures du
  dock — et le geste d'entrée gagne 62 px de piste. **Classe `html.zw430`, jamais une media
  query** (règle 10, enfreinte puis payée en v5.10.0 sur ce même quai) ; plancher
  `min-width:var(--hit)` sans lequel la touche tombe à 41 px (15 de glyphe + 2×14 de
  rembourrage) ; le nom reste dit — `render()` pose `aria-label` sur `#exoKey` à chaque rendu, on
  masque le MOT, pas l'information.

**Le survol n'ajoute pas un second bleu, il éclaire le même** : `--primary-hi` ramenait l'ancien
bleu à la souris et le défaut réapparaissait. Le fond est RE-déclaré dans la règle de survol —
sans lui, le survol générique `.sd-key:hover` (`--sys-2`) reprendrait la main à spécificité
égale. L'anneau de focus sort de 2 px et se pose sur la barre sombre (9,4:1) : dessiné SUR
l'aplat bleu clair, `--sys-ink` n'y tiendrait que 3,2:1, et `--primary` que 1,7:1.

**CE QUE LE LOT NE TOUCHE PAS.** Le libellé reste « Démarrer la session » (« Confirmé — … » dès
qu'il y a des critères : le mot porte la confirmation, doctrine QRH v4.3.2). La règle du bouton
rempli unique tient. La géométrie du quai, ses marges par palier et sa réserve de flux sont
inchangées. Une fois la session démarrée, les quatre touches reprennent le quai à l'identique.

**TÉMOINS (exigés par les planches, § consignes).** Section
« QUAI · le geste d'entrée se détache de sa barre (planches 17-18) » d'`audit-doctrine.mjs`,
vérifiée CAPABLE D'ÉCHOUER (défaut `--act` réintroduit → rouge à 1,68:1, fichier restauré à
l'octet) : aplat ≥ 3:1 sur sa barre dans les deux thèmes, périmètre nocturne en ombre interne
≥ 3:1 contre l'ambiance (et jamais d'ombre portée la nuit), ombre montante posée le jour, cible
≥ 44 px et nom accessible d'« Exercice » au glyphe seul. Les encres sur la matière éclaircie sont
couvertes par `audit-a11y` (les 21 fenêtres + surfaces, deux thèmes).
