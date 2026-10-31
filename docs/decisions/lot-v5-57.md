# Lot v5.57 — A499-A501

Question de l'auteur, après le lot v5.56 : « le petit indicateur pastille sur le compte est-il toujours bien
désigné depuis les modifications ? Pareil pour le bas de page « Tout est prêt » ». Mesuré sur l'app réelle à 390 et
1280 px, jour et nuit, compte simulé dans la page (`Auth.signedIn`/`Auth.user` surchargés, `setSyncChip` appelé —
la vraie porte), puis planche composée des captures pour décider.

## A499 — « Tout est prêt » déplié ne répète plus la version (v5.57.0)

**Avant.** Replié, la synthèse était conforme à A272 : « ✓ Tout est prêt v5.56.0 › ». Dépliée, la première rangée
du dépliant répétait la version (« ✓ Synchronisé v5.56.0 » sous « Tout est prêt v5.56.0 ») — le libellé `#count`,
né pour compter les éléments, porte la version depuis la v5 et personne ne l'avait retiré quand la synthèse l'a
prise (A272 : « le numéro de version l'accompagne, replié compris »). Sans compte, la chip de synchro cachée, la
rangée ne contenait plus QUE ce doublon, sur 32 px.

**Après, en CSS seul.** Sous une synthèse visible (`footer.tools:has(#footSum:not([hidden]))`), la version se tait
et la rangée d'état sans chip disparaît. Sans synthèse (erreur, attente, stockage presque plein — les cas qui
l'ouvrent de force), la version reste et se cale à droite (`margin-left:auto`) : quand le libellé d'erreur occupe
la ligne, elle passe dessous alignée au bord, comme un cachet, plus comme une ligne égarée à gauche.

## A500 — La pastille du compte suit l'avatar de la colonne ; anneau de nuit renforcé (v5.57.0)

**Le constat.** La pastille (`.acct-dot`) vit sur le bouton Compte de l'en-tête. Le commentaire du CSS disait
« un seul endroit, constant, dans toutes les vues » ; c'était vrai avant la refonte v5. Depuis A351, l'accueil
≥ 780 n'a plus de bouton Compte dans l'en-tête : « Moi » vit dans la colonne gauche, avec l'avatar à initiales
(A353, A435) — et sans pastille. Mesuré : `#acctTop` fait 0 × 0 sur l'accueil à 1280. Au téléphone la pastille est
sur « Moi » du dock (le bouton de l'en-tête y est déplacé) ; au bureau elle n'apparaît qu'en lecture et en édition.
L'état de synchro n'était lisible sur l'accueil bureau que par le pied, et seulement quand un fait l'ouvre de
force — ni « en cours », ni « hors ligne » (qui se résolvent seuls, A272).

**Trois options montrées sur planche** (captures de l'app réelle, quatre états, jour et nuit) : A, la même pastille
sur l'avatar de la colonne, tous états ; B, seulement les états qui appellent un geste ; C, rien. **Décision de
l'auteur : A.** C'est la grammaire déjà posée (« connecté = buste plein + pastille »), et le vert nominal est admis
par la règle 8 réécrite en A407 (« système nominal »).

**Après.** L'avatar `.hs-avatar` de la rangée « Moi » porte un `.acct-dot` à l'état courant (`_syncUi.state`),
9 px à −3/−3 du coin (l'avatar fait 22 px, le bouton de l'en-tête 40), même liseré `--work`. `setSyncChip` — la
porte unique — repeint les deux sites d'un même geste ; un re-rendu de la colonne le lit dans `_syncUi`. Pas de
pastille sans compte (l'avatar n'existe qu'avec des initiales).

**Anneau « en cours » la nuit.** Tracé en `--line` (le filet le plus doux), il se fondait dans l'avatar sombre.
`--line-strong` sur les deux sites (décision de l'auteur, sur planche).

**Témoin.** `audit-doctrine` « ACCUEIL · A499-A500 … » : rangée d'état absente sans compte, version tue sous la
synthèse et présente en erreur, pastille de colonne à l'état de l'en-tête (ok, err, busy), anneau en
`--line-strong` (couleur calculée comparée au token).

## A501 — La colonne gauche de l'accueil pose sous la barre d'état (v5.57.1)

**Signalé sur capture, iPad installé (iPadOS, 31/10/2026).** En tête de la colonne gauche, la marque « Aides
cognitives » passait sous la barre d'état : texte coupé et délavé par le fondu d'iOS 27 (A370), alors que la
recherche et « Créer », à droite, avaient leur dégagement.

**Cause.** Depuis la planche large (v5.30, A351), la colonne `.home-side` est `position:fixed;top:0` et son premier
étage `.hs-top` porte un rembourrage haut de 12 px — un littéral. L'en-tête de droite lit `--sat` depuis toujours
(`calc(12px + var(--sat))`) ; la colonne, née après, ne l'a jamais lu. Le SOL d'A370 (`body::before` sous l'heure) et
les collants qui s'y calent ne vivent que sous 780 px : au-dessus, rien ne portait l'inset à gauche. Invisible en
navigateur et sur Mac, où `env(safe-area-inset-top)` vaut 0 — c'est pourquoi aucun harnais ne le voyait (même
famille qu'A286).

**Après, en une propriété.** `.hs-top{padding-top:calc(12px + var(--sat) / var(--zf,1))}` dans le bloc ≥ 780 —
même source que les collants du téléphone (`--sat` = inset + décalage iOS 27, réversible par `--ios27-top`),
divisée par le zoom (règle 10). La zone ainsi dégagée est un aplat `--work` : le verre d'iOS 27 n'y a rien à
flouter. Rien ne change sans inset.

**Témoin.** `audit-doctrine` « ACCUEIL LARGE · A501 … » : à 1180 px, `--sat` substitué à 40 px (24 de barre d'état
iPad + 16 de fondu), la marque descend exactement d'autant et reste entière sous la bande, la recherche de
l'en-tête suit le même inset ; sans inset, la marque est à 12 px (équivalence à l'octet avec l'état d'avant).
**À vérifier sur l'appareil** (iPad installé, portrait et paysage) : la mesure simule l'inset, elle ne le lit pas.

