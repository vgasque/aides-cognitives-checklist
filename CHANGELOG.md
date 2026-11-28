# Journal des modifications

## [5.168.0] — 2026-11-28
Trouver un PDF parmi des centaines pour le lier ou le joindre (A846). Aucune mise à jour du serveur.
- **Une recherche dans le choix d'un document** : par le nom du PDF, par l'aide ou le protocole qui le porte, et dans le
  texte des PDF déjà sur l'appareil — avec la page : choisir un résultat lie directement vers cette page. Une faute de
  frappe est corrigée, et c'est dit.
- **Sans rien taper** : « Joindre un PDF… » en tête, les documents de l'élément, les cinq derniers utilisés, puis une
  rangée par bibliothèque (et Perso) avec son nombre de documents, qui s'ouvre de A à Z.
- **Les PDF des autres bibliothèques sont proposés** (« sera copié ») : choisi, le document est copié dans la
  bibliothèque de l'élément.
- Le même choix sert à « Lien vers un document », à « Ajouter › Document (PDF) » et à « Joindre un document existant ».

## [5.167.0] — 2026-11-28
Lier un document PDF déjà présent dans la bibliothèque (A845). Aucune mise à jour du serveur.
- **« ＋ Insérer › Lien vers un document » propose tous les documents utiles** : ceux du protocole, ceux des autres
  aides et protocoles de la même bibliothèque (avec leur provenance), et « Joindre un PDF… » — même quand le protocole a
  déjà un document. Choisir un document d'ailleurs le joint au protocole et le lie, d'un geste.
- **« Ajouter › Document (PDF) » propose aussi les documents de la bibliothèque**, dans une aide comme dans un protocole.
- **Corrigé : en mise en forme en direct, joindre un PDF depuis le texte posait le lien au mauvais endroit**, au milieu
  d'un autre paragraphe. Le lien va désormais sur le mot sélectionné, et le bloc reste ouvert.
- **Corrigé : « ↵ À la ligne » disparaissait de la barre dès la première lettre tapée dans un paragraphe** (Chrome
  récent).

## [5.166.0] — 2026-11-27
Ouvrir un titre, une liste ou un encadré ne fait plus descendre la suite (A844). Aucune mise à jour du serveur.
- **Plus de boutons sous un titre, une liste ou un encadré ouverts** (niveau du titre ; « Dans l'élément : Image ·
  Vidéo » ; Alerte · Attention · Information · Confirmation). Ils ajoutaient 40 px sous le bloc ; la barre de mise en forme
  fait le même travail.
- **« Titre » et « Encadré » cochent l'état en cours** : le niveau du titre, le registre de l'encadré. Un menu de choix
  s'ouvre sur l'option cochée.
- **Corrigé : changer le registre d'un encadré par « Encadré » le remplace.** Avant, un second marqueur s'ajoutait sous le
  premier (« > [!WARNING] » puis « > [!NOTE] »), en mise en forme en direct comme en mode Texte.
- **« ＋ Insérer › Image › Dans l'élément » propose aussi les images déjà dans le protocole**, comme le bouton retiré.
- **« Sortir les images de la liste »** est dans « ⋯ » du bloc ouvert.

## [5.165.0] — 2026-11-27
Écrire un protocole sans que le bloc saute (A841-A843). Aucune mise à jour du serveur.
- **Plus de rangée de boutons sous le bloc ouvert** : « ⋯ » (bloc après ou avant, déplacer, sélectionner, dupliquer,
  supprimer) et « ✓ Terminé » sont au bout de la barre de mise en forme, à côté de « ＋ Insérer ». Ouvrir un paragraphe ne
  fait plus descendre la suite que d'environ 18 px au bureau (66 avant).
- **Au téléphone, les outils de la barre défilent** sous le doigt ; « ＋ » et « ✓ » restent fixes au bout.
- **Un titre ouvert garde sa taille et sa graisse** ; « ## » reste visible dans le cadre. Taper « ## » au début d'un
  paragraphe le fait aussitôt passer en titre.
- **Glisser sur des mots les sélectionne** (pour les copier) sans ouvrir le bloc ; un simple clic l'ouvre toujours.

## [5.164.1] — 2026-11-27
Le Plan s'affiche correctement (A840). Aucune mise à jour du serveur.
- **Au bureau, le Plan ouvert depuis le titre de l'en-tête s'ouvre juste en dessous**, comme un menu ; il s'affichait en
  bas à gauche de la fenêtre.
- **Au téléphone, l'arbre du Plan est lisible** : le trait qui relie les sections passe à gauche, il ne coupe plus « H2 »
  ni le début des sous-titres.

## [5.164.0] — 2026-11-27
Modifier un protocole : une tête qui ne saute plus, et la sélection à la souris rendue (A837-A839). Aucune mise à jour du
serveur.
- **La tête du contenu rédigé ne fait plus sauter la page.** Ouvrir un bloc remplace la tête (« Contenu rédigé ·
  facultatif », le Plan, le mode) par les outils, à la même place ; le refermer la rend. Avant, la barre d'outils
  apparaissait au-dessus du document, qui remontait de 46 px à chaque fermeture.
- **Une seule taille de texte dans cette tête** (plus de capitales, de 12 et de 13,5 mêlés), alignée sur le texte au
  bureau, sur une ligne au téléphone. La ligne « Touchez un passage pour le modifier » est retirée.
- **Le Plan reste à portée quand un bloc est ouvert** : l'en-tête de la page l'affiche, même en haut de page.
- **Au bureau, la poignée ⠿ paraît dès que la souris est dans la marge**, à hauteur du bloc (il fallait passer sur le
  texte).
- **Sélectionner plusieurs blocs à la souris** : le cadre part aussi de l'espace vide à droite d'une ligne (comme dans
  Notion), en plus de la marge droite. Un simple clic au même endroit ouvre toujours le bloc.
- Témoins : `audit-doctrine` « A837-A839 » ; A552, A634, A805 et A816 mis à jour.

## [5.163.1] — 2026-11-27
Une seule poignée, bien alignée (A836, amende A833). Aucune mise à jour du serveur.
- **Au bureau, une seule poignée « ⠿ » au survol d'un bloc, centrée sur sa première ligne** — titre, paragraphe, puce ou
  encadré. Les deux boutons empilés de la v5.163.0 mettaient ⠿ en face du bloc SUIVANT pour tout bloc d'une ligne, et
  la colonne était 3 à 5 px trop haute sur les titres.
- **Cliquer ⠿ ouvre « Ajouter dessous »** : les dix types de bloc en pastilles (Texte, les trois titres, Encadré, Liste,
  Cases, Tableau, Image, Filet) — deux clics pour ajouter, comme avant ; puis « Bloc dessus… », « Déplacer »,
  « Sélectionner », « Dupliquer », « Supprimer ». **Glisser ⠿** déplace le bloc, comme avant.
- Le texte de l'éditeur ne recule toujours que de 20 px.

## [5.163.0] — 2026-11-27
Modifier un protocole sans que la page saute (A833-A835). Aucune mise à jour du serveur.
- **Au bureau, un clic sur un bloc l'ouvre toujours.** Les « ＋ » qui paraissaient au survol mordaient sur le haut et le
  bas du texte, et la poignée ⠿ (invisible) sur la fin de la première ligne : un clic pour écrire ouvrait « Ajouter un
  bloc » ou prenait le bloc. « ＋ » (un bloc dessous ; ⌥ : dessus) et « ⠿ » vivent maintenant dans une colonne étroite à
  gauche du bloc survolé ; le texte ne recule que de 20 px. Rien n'est plus posé sur le texte. Le crayon ne paraît plus
  qu'au clavier (Tab). En fenêtre étroite (moins de 560 px), comme au téléphone : les boutons du bloc ouvert.
- **Les boutons d'un bloc ouvert tiennent sur une ligne**, au téléphone aussi (ils en faisaient trois, ≈ 140 px) :
  « ⠿ Déplacer », « ＋ Bloc », « ⋯ » (Bloc avant, Sélectionner, Dupliquer, Supprimer) et « Terminé ». Au bureau large, tous
  restent visibles. Après Entrée, le premier caractère ne fait plus descendre la suite de 92 px.
- **La barre de mise en forme tient sur une ligne**, y compris au-dessus du clavier et à 375 px (iPhone mini, SE) :
  « ↵ À la ligne » ne change plus de taille en cours de frappe.
- **Le Plan suit le bloc qu'on écrit** (il disait la dernière section du protocole pendant la frappe).
- Témoins : `audit-doctrine` (section A833-A835 ; témoins A610 et A829 mis à jour ; témoin A552 réparé : au téléphone il
  touchait « Retour » de l'en-tête), vérifiés capables d'échouer.

## [5.162.0] — 2026-11-27
- **Effacer au tout début d'un bloc ouvert ramène au bloc précédent** (mise en forme en direct, convention de Notion et Gutenberg, A832) : un bloc vide — celui qu'Entrée vient d'ouvrir — disparaît et le bloc précédent s'ouvre, curseur à sa fin ; un titre, une citation ou une puce redevient d'abord un paragraphe ; un paragraphe rejoint la fin du paragraphe, du titre, de la dernière puce ou de la citation qui le précède (jonction stricte, sans espace ajoutée). Un geste, une annulation (⌘Z ou ↶).
- **Écarts assumés, pour un protocole** : rien ne se passe devant une image, une vidéo, un tableau, un séparateur, un encadré ou du code (jamais de bloc sélectionné puis supprimé au second appui) ; un encadré ou du code ne se convertit jamais ; **la touche maintenue s'arrête à la frontière** — seul un appui neuf passe au bloc précédent, le texte de celui-ci n'est jamais entamé.
- Témoins : `tests.html` (groupe A832) et `audit-doctrine` (section A832, 1280 et 390 px), vérifiés capables d'échouer.

## [5.161.0] — 2026-11-27
Le trait des sous-listes, en essai (A831). Aucune mise à jour du serveur.
- **En lecture, plus de trait vertical à gauche des sous-puces** : le retrait et la puce ronde suffisent à montrer le
  niveau. Dans l'éditeur, le trait reste : c'est là qu'on construit la structure. C'est un essai, à revoir à l'usage.
- **Une image collée ou insérée au bout d'un paragraphe ne laisse plus deux lignes vides** dans le texte avant le bloc
  suivant (rien ne changeait à l'écran ; le Markdown est propre).

## [5.160.0] — 2026-11-26
La touche Entrée en mise en forme en direct (A829), et une correction de l'insertion des images (A830). Aucune mise à
jour du serveur.
- **Entrée termine le bloc et ouvre le suivant.** Dans un paragraphe, Entrée le coupe au curseur et ouvre la suite
  dessous ; au bout, un paragraphe vide s'ouvre, prêt à écrire. Un titre se valide et un paragraphe s'ouvre dessous.
  Une liste garde son Entrée (nouvelle puce) ; sur une puce vide, on sort vers un paragraphe. Un encadré ou un bloc de
  code vont à la ligne, et on en sort par deux Entrée au bout. ⌘ Entrée ou Échap ferment le bloc, comme avant.
- **Aller à la ligne dans le même paragraphe** : Maj+Entrée au clavier, et le bouton « ↵ À la ligne » de la barre (au
  téléphone surtout), visible quand le curseur est dans un paragraphe.
- **Les raccourcis s'affichent dans les boutons** à la souris : « Échap » sur « Terminé », « ⇧⏎ » sur « ↵ À la ligne ».
  Rien n'ajoute de hauteur : si la place manque, ils se taisent.
- Un paragraphe vide qu'on quitte sans rien écrire ne laisse aucune ligne vide dans le texte. ↶ défait une coupe d'un
  seul coup.
- **Corrigé** : une image insérée, collée ou une vidéo ajoutée depuis un paragraphe ouvert au milieu d'un mot coupait le
  paragraphe en deux ; elle se pose désormais après le paragraphe.
- Le Markdown entier ne change pas : Entrée y reste un retour à la ligne.

## [5.159.0] — 2026-11-26
Les titres de troisième niveau, redessinés (A828). Aucune mise à jour du serveur.
- **Un titre `###` devient une rubrique** : en capitales espacées, sans le trait qu'il avait dessous depuis la
  v5.157. Il ne se confond plus avec une ligne en gras (« **Mesure** : … »), et le trait ne coupe plus le titre de
  son contenu. Seul le `#` garde son trait, au-dessus : il sépare deux grandes sections. En lecture comme dans
  l'éditeur. Le texte écrit ne change pas (le Plan, le sommaire et la recherche gardent la casse) ; une unité
  écrite dans un `###` (« mL ») s'y affiche en capitales.

## [5.158.1] — 2026-11-26
Correctifs trouvés à la revue visuelle et à l'audit complet de la v5.158.0 (A826-A827). Aucune mise à jour du serveur.
- **Dans un éditeur, la barre du haut ne reste plus vide.** Après un petit défilement, le titre de la page (« Modifier
  l'aide », ou la rangée « Titre » d'un protocole) était déjà passé sous la barre, mais la barre ne l'affichait pas
  encore : elle attendait 110 px de défilement. Elle reprend maintenant le titre dès qu'il est à moitié caché.
- **Au téléphone, la barre de mise en forme monte au-dessus du clavier dès qu'un bloc s'ouvre**, sans le court délai
  qui pouvait la laisser en haut de page quand on passait d'un bloc à un autre clavier ouvert (A827).

## [5.158.0] — 2026-11-26
Aligner une image ou une vidéo, lui écrire une légende depuis l'éditeur ; et les corrections de la v5.157.0 que vous
avez signalées (A819-A825). Aucune mise à jour du serveur.
- **Aligner une image ou une vidéo : à gauche, au centre ou à droite.** Touchez-la en mise en forme en direct : au
  bureau, trois boutons dans sa barre ; au téléphone, « Gauche · Centre · Droite » dans la barre du bas. Dans le texte,
  l'alignement s'écrit avec la largeur : `![](img:ID){width=45% align=center}`. Il vaut pour une image seule sur sa
  ligne ; dans une liste ou un tableau, l'image suit sa puce ou sa colonne. En pleine largeur, les boutons sont grisés :
  il n'y a rien à aligner. Une image centrée a une poignée de largeur de chaque côté.
  ⚠ Un appareil resté sur une version antérieure n'affiche pas une image alignée (la ligne s'y lit en texte) : mettez
  tous les appareils à jour.
- **Écrire une légende depuis l'image** : « Légende » dans sa barre, ou l'invite « Ajouter une légende » sous l'image
  sélectionnée. La légende s'écrit entre les crochets de cet emplacement (`![Masque haute concentration](img:…)`) et
  s'affiche sous l'image, alignée comme elle. Pareil pour une vidéo.
- **Corrigé — un grand vide au-dessus du passage ouvert** quand on touchait directement un passage sous un autre déjà
  ouvert. La page défile pour garder la ligne touchée sous le doigt ; la mise en page ne bouge plus.
- **Corrigé — « En faire un titre » proposait toujours « ## »** : sous « ## Intoxication au CO », « Physiopathologie »
  devenait sa sœur. La relecture propose maintenant « Titre ## » ou « Sous-titre ### », le bon niveau mis en avant, et
  deux lignes converties à la suite deviennent sœurs.
- **« Tout convertir en titres (n) » et « Tout corriger l'écriture des doses (n) »** dans la relecture d'un protocole,
  dès deux points du même genre : un seul geste, un seul ↶ pour tout défaire. L'éditeur d'aide garde « une par une ».
- **Corrigé — la lecture et la mise en forme en direct avaient encore des écarts différents autour des titres** (4 à
  11 px) : ils sont maintenant identiques, mesurés, au téléphone comme au bureau.
- **Corrigé — le trait des sous-listes** tombait à droite de la puce et faisait un petit « | » isolé sous une seule
  sous-puce : il part maintenant de la puce, et s'arrête au milieu de la première ligne de la dernière sous-puce.
- **Corrigé — au téléphone, le bouton « Ajouter » recouvrait « Supprimer »** sous un passage ouvert : il s'efface tant
  qu'un passage est ouvert.

## [5.157.0] — 2026-11-26
Les protocoles se lisent mieux, et l'éditeur en mise en forme en direct ne « saute » plus (A811-A818). Aucune mise à jour
du serveur.
- **La structure se voit en lisant** :
  - Un titre colle à son contenu : de l'air au-dessus, peu dessous, et un sous-titre posé juste sous son titre s'en
    rapproche. L'interligne passe de 1,7 à 1,55 : les groupes se lisent.
  - **Un « ### » porte maintenant un filet fin dessous.** Il ne se confond plus avec une ligne en gras.
  - **Un trait fin relie une sous-liste à sa puce** : on voit d'un coup d'œil ce qui dépend de quoi.
- **L'éditeur et la lecture ont le même dessin** : interligne, marges, puces et titres sont identiques. Ce qu'on voit en
  écrivant est ce qu'on lira.
- **Toucher un passage l'ouvre sur place** : le texte ne bouge plus (le cadre est dessiné autour, plus dedans), le
  curseur se pose là où l'on a touché, et la ligne touchée reste sous le doigt. Les pastilles du bloc passent sous le
  texte. Au bureau, le bloc ouvert a la même coloration que le Markdown entier (marqueurs grisés, titre et gras plus
  noirs).
- **« Physiopathologie : » en gras devient un vrai titre si vous le voulez** : la relecture repère une ligne faite
  seulement de gras et propose « En faire un titre » (« ## Physiopathologie »). Elle apparaît alors dans le Plan et le
  sommaire, et se replie. Une ligne à la fois ; une phrase qui commence en gras n'est pas concernée.
- **Le Plan suit le défilement** : une fois le titre du protocole sorti de l'écran, l'en-tête écrit la section où vous
  êtes (avec la grande section au-dessus, dans la ligne « Édition »). Le toucher ouvre le Plan. Aucune place prise, et
  rien quand le clavier est ouvert.
- **Passer de la mise en forme en direct au Markdown entier (et retour) garde la même section à l'écran** : avant, on
  se retrouvait ailleurs, parfois au début.
- **Correctif — sélectionner des blocs au cadre, à la souris** : le cadre fait maintenant défiler la page quand on
  approche du bas (ou du haut) de l'écran, et la molette ou le trackpad pendant le geste étend la sélection. On peut
  enfin prendre des blocs qui n'étaient pas à l'écran.

## [5.156.0] — 2026-11-26
Listes plus faciles à manier dans l'éditeur de protocole, et les images se collent (A809, A810). Aucune mise à jour du
serveur.
- **Remonter d'un niveau, enfin facile** :
  - **Entrée sur une sous-puce vide** la remonte d'un niveau, au lieu de terminer toute la liste. Au premier niveau,
    Entrée termine la liste, comme avant. Une sous-puce qui remonte sous « 1. » devient « 2. ».
  - **Effacer juste après le « - »** (ou « 1. », ou la case) remonte la puce d'un niveau ; au premier niveau, la ligne
    redevient du texte.
  - **Deux boutons ⇤ ⇥ dans la barre d'outils**, quand le curseur est dans une liste. Ils prennent la place
    d'« Encadré » (et de « Titre » sur les petits téléphones), qui n'ont pas de sens dans une puce. Indispensables au
    téléphone, où il n'y a pas de touche Tab.
  - Au clavier, Maj+Tab au premier niveau rend aussi la ligne au texte. Une sélection de plusieurs puces monte ou
    descend d'un niveau en gardant sa structure. ⌘Z annule.
- **Les niveaux se voient mieux** : Tab et ⇥ écrivent maintenant 4 espaces par niveau au lieu de 2 — deux fois plus de
  retrait dans le bloc ouvert de la mise en forme en direct. Vos protocoles ne changent pas : un niveau se lit par
  rapport à la puce parente, qu'il soit écrit avec 2, 3 ou 4 espaces, et ⇤ retire toujours un niveau entier. L'import
  HTML de Notion et le collage depuis Word écrivent aussi 4 espaces.
- **Coller une photo ou une capture d'écran** l'ajoute au protocole, comme « Insérer › Image » (réduite, comptée dans
  les 10 Mo). Le curseur est dans une puce : l'image va dans la puce. Ailleurs : un bloc image. Un texte copié avec une
  image (Word, Excel, une page web) se colle toujours en texte. Sur iPhone, selon la version de Safari, une photo
  copiée depuis Photos peut ne pas arriver au collage : « Insérer › Image » reste là.

## [5.155.2] — 2026-11-22
Les intitulés des cartes de l'éditeur d'aide ont tous la même graisse. Aucune mise à jour du serveur.
- **« Minuteurs & compteurs », « Complications » et « Voir aussi »** passent au même gras que « Repères posologiques »,
  « Références » et les champs de l'Identité. Les intertitres posés au-dessus d'un groupe (« Ne pas oublier »,
  « Condition d'entrée ») restent plus légers, comme avant.

## [5.155.1] — 2026-11-22
Correctifs d'alignement dans l'éditeur d'aide, après revue des changements depuis la 5.154 (rectificatif d'A808). Aucune
mise à jour du serveur.
- **Colonne « Structure » du bureau, en mode « Réordonner »** : le numéro de chaque bloc était plus bas que son titre et
  que la poignée ⠿. Les trois sont maintenant sur la même ligne.
- **Intitulés des cartes alignés sur leur contenu** : « Minuteurs & compteurs », « Complications » et « Voir aussi »
  étaient décalés de 16 px vers la droite, contrairement à « Références » ou « Repères posologiques ». La ligne « Chaque
  bouton de plus dilue les autres. » des Complications suit.

## [5.155.0] — 2026-11-22
Les blocs d'une aide se réordonnent depuis la liste « Structure » (A808). Aucune mise à jour du serveur.
- **« Réordonner »** à droite de « Structure · n blocs » (au téléphone dans la liste, au bureau dans la colonne de
  gauche). Chaque bloc devient une rangée d'une ligne : touchez celle à déplacer, puis « Poser ici » à l'endroit
  voulu. Tout tient sur un écran, et l'on peut enchaîner plusieurs déplacements avant « Terminé ».
- Le bloc posé reste sous le doigt. ✕, Échap, toucher à côté ou retoucher la rangée annulent, comme ailleurs.
- **La poignée ⠿ d'un bloc ouvert reste** : elle montre toujours tous les blocs dépliés, pour placer un bloc en voyant
  le contenu de ses voisins.

## [5.154.0] — 2026-11-22
L'éditeur d'aide, plus léger au téléphone : des aides d'une ligne, et des listes vides qui disent quoi ajouter (A806,
A807). Aucune mise à jour du serveur.
- **Une aide d'une ligne, le détail quand on est dans le champ** (A806). Les explications sous les intitulés faisaient
  jusqu'à six lignes. Elles tiennent maintenant en quelques mots (« Discriminant · deux ou trois mots », « Code ·
  facultatif », « Repères posologiques · classés selon le bloc en cours »…). La phrase complète apparaît sous le champ
  dès qu'on le touche, et les lecteurs d'écran la lisent toujours. Même chose pour « Nom court » et « À l'échéance »
  d'un minuteur. Vaut aussi pour l'identité d'un protocole.
- **Une liste vide invite** (A807). Plus de rangée « … » ni de « + Ajouter une ligne » : « Ne pas oublier », les
  critères de la condition d'entrée et les références montrent une seule invitation qui dit ce qu'on ajoute et où ça
  s'affiche (« ＋ Ajouter un rappel — affiché en haut de l'aide, 4 au plus »). La toucher ouvre la première ligne,
  curseur dedans. Avec du contenu, le bouton dit aussi ce qu'il ajoute : « ＋ Ajouter un critère », « un repère »,
  « une surveillance »…
- **Le schéma attend deux blocs** : au téléphone, une aide d'un seul bloc ne montre plus de schéma.
- **« ＋ Lier une aide ou un protocole » tient sur une ligne**, le nombre disponible dans une pastille à droite.
- **Correctif : le détail d'un repère posologique passe sous sa ligne.** Il s'affichait à côté, et la dose comme le
  détail étaient coupés.
- Complications : l'aide devient « 1 à 3, à tout moment », avec une ligne fixe sous les rangées, « Chaque bouton de plus
  dilue les autres. »
