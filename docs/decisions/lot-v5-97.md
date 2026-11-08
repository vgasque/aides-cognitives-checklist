# Lot v5.97 — l'établi de l'éditeur de référence (A593)

> Fichier normatif. Les numéros A sont des adresses : ne jamais renuméroter. Décidé sur planche Claude Design
> « Éditeur de référence — redimensionner et aligner » (07/11/2026, variante **A** retenue), puis ajusté sur l'app
> servie avec l'auteur ; **implémenté en v5.97.0**. Amende A546 (« à parts égales ») et A455/A468 (la colonne d'aperçu
> de 280 px entre 780 et 999).

Demande de l'auteur : « option pour redimensionner la taille, lors de l'édition d'un protocole, entre le texte à
remplir et l'aperçu quand ils sont côte à côte ? Et ce n'est pas franchement aligné verticalement. »

## Constat — mesuré sur l'app servie (v5.96.2, 1280 px, interrupteur « Mise en forme en direct » coupé)

- **La source commençait à y ≈ 425, son rendu à y ≈ 330** : ≈ 95 px d'écart, et un écart qui VARIAIT avec la hauteur
  du volet « Relecture » (déplié, nombre de remarques). Au-dessus du champ : Identité, l'en-tête du contenu, la barre ;
  au-dessus du rendu : Relecture et « Aperçu en direct ». Rien de commun.
- **La liaison de défilement n'allait que dans un sens** (`mdScrollLink`, champ → rendu) et alignait un bloc en haut
  d'une colonne collante dont le haut n'était pas celui du champ ; défiler la page ne faisait bouger que la gauche.
- **Les parts étaient figées** (A546 : moitié-moitié au-delà de 1000 ; 280 px d'aperçu de 780 à 999).

## A593 — L'établi : texte et aperçu partent de la même ligne ; une poignée règle leur part (v5.97.0)

> **Corrigé par A604 (v5.102.1, `lot-v5-100.md`)** : déplier « Identité » ne fait plus déborder l'établi.
> **Corrigé par A594 (v5.98.0, `lot-v5-98.md`)** : au doigt, la poignée sautait entre trois valeurs (la part enregistrée
> était repeinte pendant le geste) ; en deçà des planchers, les bornes passent à 30 % / 70 % (au lieu de 40 % / 35 %).

*Amende A546 (« à parts égales » devient la valeur par défaut) et la colonne de 280 px d'A468 entre 780 et 999.
Garde A547 (mise en forme en direct, par défaut, inchangée) et le Plan d'A546.*

**Où** : dès 780 px, interrupteur « Mise en forme en direct » COUPÉ, hors Fold ouvert (la charnière décide, inchangé).
Au téléphone, « Écrire | Aperçu » reste ; en mise en forme en direct, le document est le rendu (A547), rien à partager.

1. **La page en une colonne.** Identité repliée tient sur UNE ligne, dans sa carte : « Identité », le titre en gras,
   puis « · code · catégorie » (un code vide ne s'écrit pas), « Modifier » au bout. Dépliée, elle redevient le
   formulaire d'A521.
2. **Une bande blanche commune** pleine largeur : « Contenu rédigé », Plan, interrupteur « Mise en forme en direct ».
3. **Deux cartes séparées**, texte et aperçu, sur le fond. Dans la carte du texte, la barre (B, I, Titre, Liste…) ;
   dans celle de l'aperçu, « Aperçu · toucher un passage ramène au texte » et le **badge « △ Relecture · n »** sur la
   PREMIÈRE ligne de la barre, à sa hauteur (32). La tête de l'aperçu prend la hauteur de ce qui précède le champ :
   **le champ et le rendu commencent à la même hauteur**, au pixel (mesuré 1280 et 880, barre sur deux lignes comprise).
   Bords intérieurs à 16 px partout (Identité, bande, cartes) : leurs textes tombent sur la même verticale.
4. **Même hauteur, défilement dedans** : l'établi prend la hauteur RESTANTE sous son bord haut (`calc(100dvh /
   var(--zf,1) − haut)`, haut en `offsetTop`, règle 10), plancher 420 px, et **s'arrête au-dessus de la porte
   « Ajouter »** flottante (sa hauteur lue sur elle, + 16 dessus et dessous) : rien ne couvre la fin du texte ni du
   rendu, et un seul défilement à la fois (la page ne défile que pour ce qui est dessous : aide-mémoire, Références).
5. **Liaison dans les deux sens**, ancrée sur les blocs (`mdScrollLink`, `mdScrollBack`) : la ligne en haut du champ a
   son bloc en haut du rendu, et l'inverse. Qui MÈNE se décide au geste (roue, doigt, pointeur, clavier) : le volet qui
   suit ne renvoie jamais l'écho, et le bloc courant que `mdCaretSync` ramène dans l'aperçu ne déplace pas le champ.
   Les rectangles sont divisés par `zoomF()` avant d'entrer dans un `scrollTop` (règle 10 — l'ancienne liaison ne le
   faisait pas).
6. **La poignée** (`.etab-sep`, `role="separator"`) dans la gouttière de 32 px : un trait de 1 px et un bouton de
   12 × 44 aux **trois points** (⋮) ; au survol et pendant le geste, bleu d'action (règle 8), trait tendu à 2 px, la part
   affichée (« Texte 62 % »). **Glisser** (aimanté à ⅓, ½, ⅔ à moins de 12 px ; Alt pour s'en passer) ; **double-clic**
   ou **Entrée** = moitié-moitié ; **← →** ±5 %, Maj ±1 %, **Début / Fin** = bornes. Bornes : texte ≥ 360 (la barre tient),
   aperçu ≥ 320 ; en deçà, 40 % / 35 % de la place (`mdsBounds`, `mdsSnap`, pures, ?__actest). La part est un
   pourcentage retenu **sur l'appareil** (`ac-mdsplit`, réglage d'affichage comme `ac-mdlive`, hors espace de compte
   donc hors `WIPE_SPACE_KEYS`).
7. **Relecture** : badge replié d'office (`revProtoHtml`) ; déplié, il se pose PAR-DESSUS l'aperçu (400 px, ombre
   flottante) au lieu de pousser le rendu ; aller à une remarque le referme.
8. **L'aide-mémoire de syntaxe** passe sous l'établi : le champ remplit sa carte.

**Écarts à la planche, faits avec l'auteur sur l'app servie** : l'intitulé, sa rangée et la barre restent sur du
blanc « comme avant » (la planche les posait sur le fond) — d'abord dans la carte du texte, puis, parce que sous
1000 px la rangée passait sur plusieurs lignes et creusait d'autant la tête de l'aperçu (« tout cet espace blanc pas
ouf »), en bande blanche au-dessus des deux cartes. L'interrupteur reste celui de l'app (la planche le dessinait en
« ◯ »). Moitié-moitié par défaut, comme A546.

**Formes écartées** :
- **B — trois crans « Texte · Égal · Aperçu »** (⅔–⅓, ½–½, ⅓–⅔) dans l'en-tête (planche) : plus simple au doigt, mais
  pas de réglage fin et un segmenté de plus dans un en-tête chargé. La poignée a été préférée par l'auteur.
- **Une seule carte blanche autour des deux volets** (premier jet) : refusée par l'auteur (« pas sous un même fond
  blanc mais séparé »).
- **La rangée et la barre posées sur le fond gris** (premier jet fidèle à la planche) : refusé (« c'était mieux avant »).
- **La porte « Ajouter » sur l'établi** (option d'origine) ou **une marge en fin d'aperçu** (option 2) : la porte
  couvrait la fin du rendu, ou le cadre ; **la porte posée sous les Références** (option 3) amendait sa place à la fin
  du formulaire, collante, et l'éloignait de l'écriture.

**Piège payé** : le préfixe `.mds-` était PRIS (fenêtre de taille d'image, `.mds`, `.mds-grip`…) ; un renommage
global l'avait cassée (poignée de l'image restaurée avant commit). Les classes de l'établi sont en `.etab-`.

Témoins : `tests.html` (`mdsBounds`, `mdsSnap`) ; `audit-doctrine` « Éditeur · A593 établi aligné et lié, poignée ;
Plan d'A546 » (remplace la section A546 : même ligne et même hauteur, badge replié, pied au-dessus de la porte,
liaison dans les deux sens au pixel près, poignée tirée et aimantée, clavier, survie au rendu, 880 px ; le Plan
d’A546 et le retrait de la bande d’A547 y restent vérifiés ; vérifié capable d’échouer : 7 rouges sur la v5.96.2).
