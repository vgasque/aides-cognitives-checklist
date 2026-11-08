# Lot v5.98 — la poignée au doigt ; l'accueil dit ses bibliothèques ; des dizaines de collections (A594-A598)

> Fichier normatif. Les numéros A sont des adresses : ne jamais renuméroter. Décidé en discussion avec l'auteur sur la
> planche Claude Design « Accueil téléphone — quelles bibliothèques ? » (08/11/2026) ; **implémenté en v5.98.0**.

Demandes de l'auteur :
- « sur page d'accueil smartphone, pas clair qu'on affiche toutes les bibliothèques » (4-5 bibliothèques, 15 au plus) ;
- « et pareil collections, si plusieurs dizaines, comment tout afficher sur l'accueil ? » ;
- « sur téléphone, avec la poignée déplacée au doigt, pourquoi que 3 options 40/50/65 % ? » — puis « oui, ça saute
  entre les 3 tailles ».

Arbitrage : pistes **1** (dire la portée) et **2** (liste) retenues pour les bibliothèques ET les collections ; les
pistes **3** — regrouper « Bibliothèque › Catégorie » (déjà reportée en A588) et l'étoile « en tête » d'une collection —
**mises de côté**, à rouvrir comme options au choix de chacun.

## A594 — Au doigt, la poignée de l'établi suit le geste ; 30-70 % aux largeurs étroites

*Corrige A593 §6.*

**Constat (reproduit sur Chromium en émulant le doigt, iPad 820 px)** : pendant le geste, la part lue sur la poignée
revenait à 50 (l'ancienne valeur) entre deux positions du doigt. La carte du texte change de largeur à chaque
`pointermove` ; son `ResizeObserver` relance `fit()`, qui repeint la grille avec la part ENREGISTRÉE (`r`), mise à jour
seulement au lâcher. La grille oscillait entre le doigt et l'ancienne valeur ; au lâcher, elle restait sur une borne ou
sur l'aimant du milieu — d'où « 40, 50, 65 ». Le témoin à la souris ne le voyait pas : il ne lisait que la valeur finale.
Le zoom n'y était pour rien (même résultat à 115 %).

1. **La part suit le doigt** : `r` est tenu à jour pendant le geste ; tout repeint (`fit()`) repart de la part courante.
2. **Bornes aux largeurs étroites : 30 % / 70 %** (au lieu de 40 % / 35 % de la place). Les planchers en pixels
   (texte 360, aperçu 320) restent ceux d'A593 dès qu'ils tiennent ; en deçà, chacun garde 30 % de la place. Vers 800 px,
   la plage allait de 40 à 65 % : trois crans à peine. Le prix : la barre du texte passe sur deux lignes sous 360 px,
   ce qu'A593 §3 sait déjà aligner (la tête de l'aperçu suit).

Témoin : `audit-doctrine` (section A593) lit la part PENDANT un geste au doigt simulé à 880 px — croissante, de 30 à 70 ;
vérifié capable d'échouer (6 lectures à 50 sur l'ancien code). `tests.html` : `mdsBounds(500)` = 30 / 70.

## A595 — Au téléphone, l'accueil dit ses bibliothèques

*Étend A545 (le titre dit ce que la liste montre) à la bibliothèque ; amende A242/A589 (provenance) sous filtre de
bibliothèque.*

1. **Au repos, la sous-ligne compte les bibliothèques mêlées** dès qu'il y en a deux : « Tout · 5 bibliothèques · 112 ».
   « Tout » ne disait que « aucun tri par collection » (A493) ; rien ne disait le mélange.
2. **Une bibliothèque choisie prend le grand titre**, comme une collection ou une catégorie : « SMUR 75 ⌄ », coiffé de
   son œil (« Bibliothèque · partagée | lecture | vous seul », icône du partage), sous-ligne « n éléments », bouton
   « Tout afficher » (qui retire aussi la bibliothèque). L'axe du titre (`pgAxis`) vaut alors `lib` : la puce
   « Bibliothèque : … » n'est plus redite. Ordre de priorité inchangé : collection, puis catégorie, puis bibliothèque.
3. **La rangée ne redit pas sa bibliothèque** quand une seule est affichée (`searchLibTag`) : le titre la dit, et la
   pastille faisait passer la méta sur deux lignes.
4. Le mot de partage a une seule source, `libWho` (colonne, feuille, titre).
5. Défaut trouvé en chemin : un long nom dans le petit titre collé (`.pg-tt`, `nowrap`) poussait « Créer » hors de
   l'écran — la colonne centrale de `.pg-top` est désormais `minmax(0,auto)` et le petit titre s'ellipse.

## A596 — Dans « Afficher », les bibliothèques en liste

*Amende A556 (la Bibliothèque en puces dans la feuille du téléphone) ; garde A428 (absente s'il n'y en a qu'une).*

Une liste de rangées de menu (`menuRowHtml`, le dessin des collections et des catégories) sous l'intertitre
« Bibliothèque » : icône du partage, nom, mot de partage, compte, coche sur la courante ; « Toutes » en tête.
**Repliée au-delà de 6** (`LIB_FOLD`) — « Voir les n autres » — la bibliothèque choisie restant toujours visible ; à
6 + 1, rien ne se replie (replier une rangée n'économise rien). Ça reste un **réglage** (A556) : un tap coche, la feuille
reste ouverte. À 15, les puces passaient sur quatre lignes, sans compte, et repoussaient collections et catégories hors
de l'écran. En large, la feuille « Affichage » garde ses puces (la colonne liste déjà les bibliothèques).

## A597 — Des dizaines de collections : l'accueil garde les récentes ; « Afficher » se filtre

*Amende A587 §2 (toutes les collections, dans l'ordre alphabétique).*

1. **Au-delà de 6 collections, la section « Vos collections » garde les 5 vues le plus récemment** (`COLL_HEAD`) — et
   toute collection dépliée —, **dans l'ordre alphabétique** (une rangée qui change de place sous le doigt se perd), puis
   **« Toutes les collections · n »** : au téléphone, elle ouvre la feuille « Afficher », où vit la liste entière ; en
   large, elle porte le focus sur les collections de la colonne. Jusqu'à 6, rien ne change.
2. **« Vue »** = la vue de la collection ouverte, ou la collection dépliée sur l'accueil (`collSeen`). Retenu par appareil
   dans la clé des plis (`ac-home-fold`, champ `vu`, 60 au plus) — déjà dans `WIPE_SPACE_KEYS`, aucune clé nouvelle.
   Jamais vue : l'ordre alphabétique départage.
3. **Le champ « Filtrer » de « Afficher » paraît au-delà de 12 rangées** (collections et catégories ; `seuilFiltre`, muselé
   à 999 jusqu'ici). **Au doigt, il ne prend pas le focus à l'ouverture** (`filtreAuToucher`) : le clavier montait sur une
   feuille qu'on ouvrait pour choisir d'un tap. Au pointeur fin et au clavier, il le prend, comme avant.

**Formes écartées (mises de côté par l'auteur, « ça resterait une option »)** :
- **Regrouper « Bibliothèque › Catégorie »** (piste 3 de la planche) : la réponse au MÉLANGE, quand l'annonce ne suffit
  plus ; un sixième cran de « Regrouper », à rouvrir.
- **L'étoile « en tête »** sur une collection pour la fixer parmi les cinq : à rouvrir si la récence ne suffit pas.
- Replier les collections dans la feuille « Afficher » comme les bibliothèques : le champ « Filtrer » y suffit (non fait).

Témoins : `audit-doctrine` « Accueil · A595-A597 bibliothèques dites, liste, collections nombreuses » (390 px, 10
bibliothèques, 14 collections : sous-ligne, cinq de tête et « Toutes les collections », collection ouverte entrée en tête
dans l'ordre alphabétique, feuille ouverte sans focus au doigt, liste repliée puis dépliée, mots de partage, coche sans
fermer, titre et œil, ni puce ni provenance redites, « Créer » à l'écran malgré un long nom, « Tout afficher » ; rouge sur
la v5.97.0).

## A598 — « Garder en tête de l'accueil » : une collection reste dans « Vos collections » (v5.99.0)

*Étend A597 ; reprend la piste « étoile en tête » mise de côté plus haut. Demande de l'auteur : « ou alors possibilité de
mettre des collections ou bibliothèques en Accès direct ? » — puis, après discussion, « oui, fais l'étoile ».*

1. **Dans le ⋯ d'une collection** : « Garder en tête de l'accueil » (sous-ligne « toujours dans « Vos collections » ») ;
   l'inverse, « Ne plus garder en tête » (« elle suit l'ordre des plus récentes »). Un toast confirme.
2. **Sur l'accueil**, au-delà de 6 collections : les collections gardées en tête prennent leur place parmi les
   `COLL_HEAD` (toutes, même si elles sont plus nombreuses), les plus récentes prennent les places restantes ; l'ordre
   d'affichage reste alphabétique (A597).
3. **Le signe est un signet PLEIN** (`collIc`, classe `coll-top`), partout où la collection paraît (accueil, feuille
   « Afficher », en-tête, colonne). **Pas une étoile** : l'étoile dit déjà l'Accès direct sur chaque aide — deux sens
   pour un glyphe, c'est ce que la règle 8 refuse aux couleurs.
4. **Modèle** : champ `top` (booléen, absent = non) sur la collection ; `sanitizeColls` ne laisse passer que `true`
   (règle 5) ; synchronisé avec les collections dans le document perso ; le registre RGPD (§ 3) le nomme.

**Formes écartées** :
- **Une collection ou une bibliothèque comme tuile de l'Accès direct** (demande d'origine) : l'Accès direct promet UN tap
  pour ouvrir une AIDE, le geste de l'urgence ; une tuile qui ouvre une liste ajoute une étape et mêle deux natures de
  tuile. L'Accès direct est déjà une collection (A515) : y ranger des collections, c'est une collection de collections.
  Une bibliothèque en tuile revient à ouvrir l'app filtrée, écarté en A587.
- **Une étoile** comme signe : prise par l'Accès direct (ci-dessus).
- **Le geste depuis la rangée de la feuille « Afficher »** : une rangée y est une destination (un tap ouvre) ; lui
  greffer un second bouton aurait fait deux cibles dans 44 px. Le ⋯ de la collection suffit.

Témoins : `tests.html` (`sanitizeColls` : seul `true` passe) ; `audit-doctrine` « Accueil · A595-A597 » (le ⋯ pose le
signet, retenu dans `ac-colls`, la collection garde sa place parmi cinq quand cinq autres sont plus récentes ; rouge sur
la v5.98.0).
