# Lot v5.49 — A473-A474

Deux chapitres : quatre retours d'usage corrigés (A473), et l'étape qui attend un seuil (A474, amende A382).

## A473 — quatre retours d'usage (v5.49.0)

**Signalé (06/10/2026)** — quatre défauts, chacun mesuré avant d'être corrigé.

- **« Se déconnecter » déconnectait TOUS les appareils.** `Auth.signOut` appelait `/auth/v1/logout` sans paramètre ;
  le défaut de GoTrue est `scope=global` : tous les jetons de rafraîchissement du compte tombent, et les autres
  appareils se retrouvent déconnectés à leur prochain rafraîchissement. `?scope=local` ne révoque que la session de
  CET appareil — ce que le bouton promet. Valable pour les quatre appelants (déconnexion, retour hors compte, rafraîchissement
  refusé, suppression du compte : le compte supprimé n'a plus de session ailleurs de toute façon).
- **Le quai disait « 1 compteur » à côté d'une tuile de compteur.** Le rappel compte ce qui n'est PAS montré (J53) :
  avec deux compteurs dont le premier en tuile, « 1 compteur » était juste mais se lisait comme le total. Deux
  changements : (1) un « + » devant une sorte dont une partie est déjà montrée (« +1 compteur », « +1 minuteur ») ;
  (2) la capsule accueille DEUX compteurs (la boucle d'ajustement essaie 2, 1, 0 — toujours après les minuteurs, qui
  gardent la priorité). **Et un défaut voisin, antérieur** : la boucle mesurait le débordement du quai, jamais l'ellipse
  DANS une tuile — un minuteur lancé à 390 px laissait « Chocs délivr… » (A462 promet le nom entier). Le fantôme refuse
  désormais toute tuile dont le nom s'ellipse (largeur STRICTE : 47 contre 46 px suffit à l'ellipse, la tolérance d'un
  pixel l'avait laissé passer) ; plafond du nom 72 → 96 px, pour qu'un mot comme « Adrénaline » tienne. Mesuré sur
  l'ACR (deux compteurs) à 360, 390, 430 et 600 px : deux tuiles entières au repos ; minuteur lancé, une tuile entière
  sous 600 px, le rappel tombe le premier (J53), le chevron reste.
- **« Relâcher avant la fin annule » collait aux boutons.** La règle posait 14 px, mais `.ai-card p` (0,1,1) battait
  `.endsess-hint` (0,1,0) : marge haute à 0. Sélecteur `.ai-card p.endsess-hint` — 14 px mesurés.
- **Moi : « Exporter mes données » / « Prendre en main » / « Un problème ? » inégalement espacés.** Deux `.auth-actions`
  collés : 12 px à l'intérieur de chacun, 0 entre eux. Un seul conteneur — 12 px partout, en colonne comme en rangée
  (≥ 780).

## A474 — la jauge d'un seuil vit dans son étiquette, la case attend estompée (v5.49.0, amende A382)

**Signalé (06/10/2026)** : sous une étape « cochable si Chocs délivrés ≥ 3 », les petits points qui se remplissent et
« encore 3 » se lisaient comme le compte DE L'ÉTAPE (« on peut encore la cocher 3 fois ») — ils étaient posés sous son
libellé, à l'endroit exact de ce qui appartient à l'étape. Exploré sur canevas avec l'auteur (douze planches) avant le code.

- **La jauge entre dans l'étiquette du seuil** : « CHOCS DÉLIVRÉS ≥ 3 ●○□ ». Les points sont collés au NOM du compteur
  qu'ils comptent ; le « ≥ 3 » reste (l'auteur y tient : c'est la définition de « cochable »). « encore n » disparaît.
  Au-delà de 8, « n/N » en chasse fixe. Lecteur d'écran : « — n sur N ».
- **Le dernier repère a la forme d'une CASE** (carré au trait plein, même taille et même écart que les points) : la
  jauge se lit « encore un, puis la case ». Une case plus grande et pointillée au bout (planche A5) se lisait comme un
  compte en plus, ou comme un but inatteignable — refusée.
- **La case de l'étape est là, ESTOMPÉE** (pleine, trait à 50 % de `--ctl-line`, fond `--work`) au lieu d'être
  pointillée : le pointillé disait « inatteignable », or « Faire maintenant » la coche à tout instant. Le contour
  pointillé de la RANGÉE reste (A382 : « pas maintenant, ne retient pas Continuer »). Vaut pour toute attente
  (`mo-wait`), échéance comprise.
- **« Faire maintenant » se pose au bout de la rangée** quand la rangée n'a pas de ligne du dessous dans ses autres
  états (seuil seul). Sinon (lien de coche, « à l'échéance »), la ligne reste réservée — A9, la rangée ne change pas de
  hauteur — mais VIDE avant le seuil : la légende du lien y était coupée par le bouton (« 04:00 à la coc… ») ; elle
  revient avec la case. Symétriquement, une étape à seuil seul ne réserve plus de ligne vide une fois le seuil atteint.
- **Au seuil** : étiquette verte « ✓ … ≥ 3 », jauge pleine (case comprise), la case de l'étape reprend son trait.

**Formes écartées** (planches du canevas) : jauge sous le libellé (l'état d'avant) ; pastille nommée sous l'étape (B) ;
intertitre de seuil coiffant les étapes (C) ; la case comme jauge segmentée (A1 — trop proche de la JAUGE DE LA REVUE,
A449, qui mesure l'étape elle-même : le contresens qu'on corrige) ; un cadenas dans la case (A2 — dit « interdit »,
alors que « Faire maintenant » existe) ; l'étiquette accrochée à la case par un trait (A3) ; « ≥3 » écrit dans la case
(A4 — se lit comme une valeur à saisir). Reste ouvert : un micro-mouvement à l'instant du seuil (planche A6), à la
grammaire d'A378.
