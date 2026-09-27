# Journal des modifications

## [5.37.2] — 2026-09-27
Deux alignements, mesurés (A399, doctrine `docs/decisions/lot-v5-37.md`).
- **Capsule CRITIQUE / VIGILANCE d'une hypothèse** : elle s'aligne exactement sur le début du
  libellé en dessous, à toutes les largeurs et tailles de texte (sur téléphone étroit elle partait
  10 px à gauche du texte).
- **« Repères de ce bloc » replié** : le titre, le résumé (« 2 à préparer ») et les noms des repères
  partent du même bord ; l'icône est dans la même colonne que celle des repères et le compte est sur
  la ligne du titre.

## [5.37.1] — 2026-09-27
Revue et repères du bloc : cinq retours d'usage (A398, doctrine `docs/decisions/lot-v5-37.md`).
- **La revue des causes réversibles se partage entre les blocs.** Cochée dans « Choquable », elle
  est retrouvée telle quelle dans « Non choquable » : c'est UNE revue pour toute la session, quel
  que soit le bloc qui la pose, et elle ne repart plus de zéro à chaque tour de boucle. « Nouvelle
  revue » la remet à zéro. Une session en cours reprise après la mise à jour garde ses coches.
- **Hypothèses « critique » ou « vigilance » lisibles.** L'étiquette se posait sur le libellé de
  l'hypothèse ; elle se place au-dessus. L'étape-revue elle-même avait sa case AU-DESSUS du texte,
  des hypothèses grisées et rapetissées (un nom de classe déjà pris par la liste « à relire ») :
  corrigé.
- **Pas de CRITIQUE / VIGILANCE avant le moment d'une étape.** Une étape qui attend son moment
  (en pointillé, sans case) n'affiche que sa règle ; le mot revient avec la case.
- **Repères de ce bloc.** Un repère dont l'étape n'a pas encore atteint son moment est « à
  préparer », plus « à faire » ; faite à un passage précédent (« une seule fois »), « fait ». Chaque
  repère se lit en deux lignes — nom et état en tête, posologie dessous sur toute la largeur — et le
  nom ne se coupe plus au milieu du mot sur téléphone ; sous 430 px, l'état passe sous le nom. Bande
  repliée : le résumé (« 2 à préparer ») passe sous le titre au téléphone au lieu de s'écraser à côté.
- **Icône des repères** : la gélule a une moitié pleine — elle se lisait comme un maillon de chaîne.

## [5.37.0] — 2026-09-27
La revue « à tout moment » et la bande des repères du bloc (A396-A397, doctrine `docs/decisions/lot-v5-37.md`).
- **Revue « à tout moment ».** Une question que l'équipe se pose pendant tout le soin — les causes
  réversibles (4H / 4T) de l'arrêt cardiaque — devient une liste d'hypothèses cochable. Elle se pose
  dans le fil comme une étape, dans chaque bloc où l'on doit y penser, avec le nom de la revue ; un
  toucher sur la rangée déplie les hypothèses dans sa boîte, chacune se coche sur place, la revue est
  faite d'elle-même quand toutes sont cochées et ne retient jamais « Continuer ». À chaque passage
  de la boucle, tout est à recocher ; « Nouvelle revue » remet la revue courante à zéro. Elle reste
  ouvrable à tout moment sous le bloc, sous le même nom, et se lit dans la colonne « À tout moment »
  du parcours et dans la Page. Les coches voyagent par le partage comme celles des étapes.
- **Repères de ce bloc.** Un repère posologique peut être lié à une étape (Réglages de l'étape ›
  « Repère posologique »). En session, les repères des étapes du bloc forment une bande au pied du
  bloc, dans l'ordre des étapes, avec un mot venu de la coche : fait · à faire · à préparer — pendant
  l'adrénaline, l'amiodarone est déjà lisible. La bande se replie d'un toucher (un seul état pour la
  session, la tête repliée garde le compte et le résumé) ; un toucher sur une ligne ouvre le détail
  du repère (préparation, dilution, administration), que l'éditeur écrit sous la ligne du repère.
  Les rangées d'étapes ne changent pas : la boîte grise entière reste la coche.
- **Éditeur.** Porte « Revue » de la palette ; carte propre pour chaque revue (titre, hypothèses avec
  leur indice, réglages) ; sections « Revue » et « Repère posologique » dans la feuille Réglages d'une
  étape ; détail sous chaque repère posologique.
- **Icônes.** Le glyphe ℞ est remplacé par une pilule dessinée comme les autres icônes ; la revue
  porte une grille.
- **Fiches d'exemple** : dans l'ACR, la revue des causes réversibles est posée dans les deux blocs
  de la boucle et l'adrénaline comme l'amiodarone sont liées à leur repère ; dans l'anaphylaxie,
  l'adrénaline IM et le remplissage le sont aussi.
- **Génération par IA** : bloc `review` et renvoi `review` d'un item (règle 19) ; un repère peut
  s'écrire en objet avec un `id` et une `note`, et chaque étape qui dose un produit y renvoie par
  `poso` (règle 20).

## [5.36.0] — 2026-09-27
Imprimer la Page sans surprise, exporter une sélection, les liens des PDF, et des branches qui se lisent comme des branches (A392-A395, doctrine `docs/decisions/lot-v5-36.md`).
- **Impression de la Page.** Sans l'option « imprimer les arrière-plans », les traits du tronc et des
  fourches disparaissaient, et les numéros de bloc aussi : ils s'impriment désormais dans tous les cas
  (traits en bordures, numéros encadrés). Les voies pointillées ne sont plus décalées d'une page ni
  « rallongées », quels que soient les en-têtes, pieds de page et marges ; la page blanche en fin de
  document et la page blanche au bureau (1280 px) ont disparu.
- **Le PDF enregistré porte le nom de l'aide** (ou du protocole), et non plus « Aides cognitives ».
- **Mode Page** : les cartes « À vérifier » et « Diagnostics » sous la feuille redisaient la Page ;
  seule « Références » reste.
- **Page : les jalons se lisent comme les réponses.** Dans une décision, le jalon vient après les
  réponses, sur une ligne « SI Chocs délivrés ≥ 3 : … ……… [⚡ FV réfractaire] », en gris ; les en-têtes
  de groupe d'étapes prennent le même « SI ». Le jalon ne coupe plus la question de ses réponses.
- **Parcours : « Branche » au lieu de « Chemin 2 ».** Une suite qui ne découle pas du bloc précédent
  s'annonce « Branche ◇ 2 « Non » » (la décision et sa réponse, un toucher y mène) ; ses blocs sont
  décalés d'un cran le long d'un trait gris. « ■ Fin » remplace « Fin du parcours ». La bulle ne touche
  plus le bord de la colonne.
- **Parcours : le chiffre des losanges est centré.**
- **« ✓ faite — plus à refaire »** : en mode guidé, une étape « une seule fois » déjà cochée le dit
  dans le parcours, la Page et le Schéma (jamais sur papier).
- **Exporter plusieurs aides ou protocoles d'un coup** : en mode Sélection, « Exporter… » produit un
  seul fichier, réimportable tel quel (avec les documents joints au choix).
- **PDF joints : liens cliquables et sommaire.** Les liens web (http, https, mailto, tel) s'ouvrent dans
  un nouvel onglet, les renvois internes mènent à leur page, et un bouton « Sommaire » apparaît quand
  le document a des signets.

## [5.35.0] — 2026-09-26
L'accueil en une colonne, l'éditeur plus navigable, un aperçu fidèle, et une Page et un Schéma lisibles (A389-A391, doctrine `docs/decisions/lot-v5-35.md`).
- **Accueil (tablette, bureau) : une seule colonne.** La grille de 2 ou 3 colonnes coupait les
  informations sous les titres ; la liste tient désormais en une colonne. « Détaillée » affiche une
  carte par aide ; « Compacte » tient sur une ligne au bureau (titre à gauche, informations à droite).
  Les deux réglages rendaient la même chose au-delà de 780 px : c'est corrigé.
- **Bibliothèques** : dans la colonne de gauche, le crayon et « Nouvelle bibliothèque » laissent place à
  un « Gérer » qui ouvre « Moi » à la section Bibliothèques.
- **« Tout voir »** perd l'onglet « Parcours », qui redisait « Se repérer » : il reste Page et Schéma.
- **Éditeur (tablette, téléphone) : la Structure revient.** Une carte « Structure · n blocs » reste collée
  sous l'en-tête, fermée par défaut ; toucher un bloc la referme et amène le bloc à l'écran.
- **« Essayer » montre la vraie page** : cartes, parcours, quai (Démarrer l'essai, Fin, Tout voir, ⚡,
  Journal) et minuteurs, comme en session. « Fin » rejoue l'essai depuis le début. Rien n'est enregistré,
  et ouvrir ou replier une carte dans l'aperçu ne change plus l'aide elle-même.
- **Page (Tableau) : des traits qui se rejoignent.** Le tronc touche enfin la pilule « revenir à… » ; un
  renvoi vers une branche de fourche rejoint la barre de la fourche (une seule pointe) ; un retour part
  du bas de sa pilule et ne croise plus rien ; la pointe d'un retour arrive par un vrai trait ; les
  tracés ne sont plus décalés quand la fenêtre s'ouvre.
- **Page et Schéma : les conditions en toutes lettres**, comme dans le parcours : « Si Chocs délivrés ≥ 3 : »
  en tête des étapes concernées, puis « · toutes les 4 min », « · si pas déjà faite », « · +1 Chocs délivrés ».
  Le jalon se lit « Si … : … » ; les durées et les noms entre guillemets ne se coupent plus en fin de ligne.

## [5.34.0] — 2026-09-26
Le parcours se lit d'un coup d'œil : dans la colonne, dans la carte « Parcours » et dans la feuille « Se repérer » (A388, doctrine `docs/decisions/lot-v5-34.md`).
- **Colonne repliée par défaut.** À gauche du bureau (dès 1200 px) et dans le rail de droite, le
  parcours ne montre plus que les titres, avant comme pendant la session. Un bloc se déplie d'un
  toucher sur son titre, « Tout déplier » ouvre tout. Une décision repliée garde ses réponses sur
  une ligne (« Oui ↓ 3 · Non → 4 »), et en session la réponse choisie porte ✓. Le bloc en cours dit
  « Ici ». Texte un cran plus petit (13,5 px) : la liste de l'arrêt cardiaque passe de 1 540 à 510 px.
- **Même geste partout.** La carte « Parcours » et la feuille « Se repérer » ont les mêmes chevrons,
  mais restent dépliées à l'ouverture. Replier ne fait pas sauter la page et ne ferme pas la feuille.
- **Les conditions de cochage en toutes lettres.** Les étapes qui ne se font qu'à partir d'un seuil
  sont regroupées sous « **Si** Chocs délivrés ≥ 3 : ». Le reste suit l'étape en gris : « si pas déjà
  faite », « toutes les 4 min », « au besoin », « +1 Chocs délivrés », « relance « Réévaluation » (5 min) ».
  Les étiquettes en capitales et les légendes à icône disparaissent du parcours.
- **Boucles, jalons et complications.** « ↺ retour à 2 · toutes les 2 min » ; un jalon se lit
  « Si Chocs délivrés ≥ 3 : … » avec un renvoi ⚡ vers sa complication ; les complications sont
  listées en fin de parcours, sous « À tout moment ».
- **Critique et Vigilance** : dans le parcours, le mot en couleur, sans fond, se place à droite de la
  première ligne. Le texte de l'étape ne se décale plus. La carte de session ne change pas.
- **Réponse attendue** : elle suit l'étape après un tiret, dans le texte (plus de police à chasse fixe
  bleue). Le titre de la colonne devient « Parcours » (au lieu de « Parcours inerte »), et Tableau ·
  Schéma tiennent sur une ligne.

## [5.33.2] — 2026-09-26
Deux bugs du partage de session côté invité (A385) et leur pendant côté hôte (A387), puis deux bugs d'affichage au téléphone (A386) — doctrine `docs/decisions/lot-v5-33.md`.
- **Connexion coupée : l'invité peut continuer.** Quand le lien se figeait (plus de réponse depuis
  quelques secondes), ses coches, compteurs et minuteurs étaient refusés et grisés. Ils sont
  désormais gardés sur l'appareil et partent au retour du réseau, comme ceux de l'hôte — le quai
  dit toujours « figé ». « Recevoir » par l'écran ne les efface pas.
- **Sa propre session reste la sienne.** Un invité qui rouvrait la même aide sur son profil et y
  lançait une session ou un exercice voyait les gestes de l'hôte s'y inscrire : elle devenait la
  session partagée. Les gestes de l'hôte ne vont plus qu'à la session partagée, et « Revenir à la
  session partagée » les montre tous. Une bascule automatique en direct ne l'arrache plus à sa session.
- **« Démarrer » et « Exercice » s'affichent** au quai sur les aides de l'invité (appareil qui lui
  appartient) ; ils n'étaient accessibles que par le menu ⋯.
- **Corriger une heure du journal (téléphone)** : le volet ne se referme plus au premier toucher, le
  champ et les raccourcis « −1/−2/−5 min » restent au-dessus du clavier, et après validation le dock
  du bas revient — il restait masqué et faisait sauter le contenu (A386).
- **Téléphone en paysage** : la colonne de droite (minuteurs, compteurs, journal) n'est plus coupée —
  elle défile avec la page au lieu d'une petite zone de 110 px (A386).
- **L'hôte peut consulter une autre aide pendant un partage** : les gestes de l'invité continuent
  d'arriver dans la session partagée (ils tombaient dans l'aide affichée et se perdaient), et une
  session ouverte sur l'autre aide n'envoie plus rien à l'invité (A387).

## [5.33.1] — 2026-09-26
Retours d'usage sur l'éditeur allégé de la v5.33 (A384, doctrine `docs/decisions/lot-v5-33.md`).
- **La réponse attendue vide se laisse cliquer** : toucher le champ repliait l'étape et le clic
  tombait sur l'étape suivante. La rangée reste désormais ouverte tant que le focus reste en elle.
- **Des champs d'une seule taille** : titre d'étape, réponse attendue, question d'une décision,
  réponses et blocs cibles prennent le gabarit des listes « Condition d'entrée » (15 px, environ
  40 px de haut ; 16 px sur écran tactile, contre le zoom d'iOS). Au repos, la réponse reste serrée
  sous le titre ; elle s'arrête avant le bouton « Réglages », qui ne touche plus le filet du dessus.
- **Un seul dessin pour les boutons d'outil de l'éditeur**, blanc comme les autres boutons : croix de
  suppression (rappels, listes, réponses, minuteurs, compteurs, jalons, complications, documents),
  gras **B**, **△** du repère à vérifier (fond ambre quand il est posé), → vers le bloc d'un rappel.
  Les anciennes cases blanches bordées et le pavé gris disparaissent.
- **Complications** : la croix ne chevauche plus la cible ; le champ « Événement » et la cible
  prennent le gabarit des autres champs.
- **Toutes les pastilles se glissent au doigt**, « Importance » comprise : le glisser est posé une
  fois pour toute l'app, un nouveau sélecteur n'a plus rien à câbler.
- **Feuille de réglages** : « ×2 Confirmée par les deux » dit ce qu'elle fait (« en session, marquée
  ×2 : les deux soignants la vérifient à voix haute ») ; le libellé de « Continuer » est dit
  facultatif ; de l'air sous « Importance ».


## [5.33.0] — 2026-09-26
L'éditeur s'allège : on écrit d'abord, on règle ensuite, jamais à plus d'un toucher (A383, doctrine
`docs/decisions/lot-v5-33.md`). Demande de l'auteur après audit mesuré (ACR, 390 px : une étape
touchée passait de 70 à plus de 500 px, onze commandes) ; maquettes E1-E7 et captures validées.
- **Écrire n'ouvre plus rien** : toucher le texte d'une étape n'allume que ses champs. Un bouton
  « Réglages » au bout de la ligne ouvre une feuille (basse au téléphone, centrée dès 780) à trois
  sections nommées : importance (Normale · Vigilance · Critique, Mémoire, ×2), ce que fait la coche,
  moment (« Dès le 1ᵉʳ passage / À partir d'un compte », seuil −/+, « Puis revient » en quatre cases).
  Sans minuteur ni compteur, « ＋ Créer un minuteur / un compteur » les crée et les lie sur place.
- **Ce qui est réglé se lit au repos**, en pastilles sous l'étape : Critique, Vigilance, ★ Mémoire,
  ×2, « lance … », « +1 … », « Chocs délivrés ≥ 3 », « à l'échéance ». La réponse attendue passe sous
  le texte ; les étapes sont plus compactes (≈ −20 %).
- **Ce qui ne peut servir à rien n'est plus montré** : le moment, le minuteur du bloc et les jalons
  n'apparaissent que si le bloc se répète (« ↺ Se répète ») ou s'ils sont déjà posés.
- **« Options du bloc »** en carte dépliable, résumé à droite, ouverte d'office quand une option est
  posée : bloc de départ, phase (qui quitte l'en-tête), libellé de « Continuer », minuteur du bloc,
  jalons, image. Un jalon se lit comme une phrase : « Chocs délivrés ≥ − 3 + ». Les règles d'usage
  ne sont plus répétées à chaque bloc.
- Témoins : section A383 d'`audit-doctrine`, `audit-k5` et `audit-a11y` (la feuille est mesurée).

## [5.32.0] — 2026-09-26
Une étape peut dire QUAND elle se présente dans un bloc parcouru plusieurs fois (A382, doctrine
`docs/decisions/lot-v5-32.md`). Demande de l'auteur, sur maquettes revues fil par fil : au 1ᵉʳ choc,
il fallait cocher l'adrénaline « après le 3ᵉ choc » pour pouvoir avancer.
- **Commence** : dès le 1ᵉʳ passage, ou quand un compteur atteint un seuil (« Chocs délivrés ≥ 3 »).
  **Puis revient** : à chaque passage, à l'échéance du minuteur que relance sa coche, une seule
  fois, ou au besoin.
- **Avant son moment**, l'étape reste visible, en pointillé et sans case, avec sa règle au-dessus
  et ce qui manque dessous (pastilles · « encore 2 », ou le minuteur qui court). « Continuer » ne
  l'attend pas. « Faire maintenant » la coche quand même, en un toucher.
- **Quand le moment vient**, la case revient sur place, à la même hauteur, sans défilement ni
  alerte : « ✓ Chocs délivrés ≥ 3 », ou « Échu » en ambre. Rien ne repart seul.
- **Une seule fois** : une fois faite, « Faite », plus de case. **Au besoin** : cochable, jamais
  attendue.
- **Éditeur** : « Commence » et « Puis » dans les outils de l'étape, réglés sur place. « À
  l'échéance » reste grisé avec sa raison quand la coche ne relance aucun minuteur. Si le minuteur
  disparaît, l'étape redevient « à chaque passage » et l'éditeur le signale.
- **Parcours à plat et Page** annoncent la règle sous l'étape.
- **Prompt IA** : il sait poser ces moments (seulement quand la source les énonce), écrire deux
  doses comme deux étapes, et ne plus laisser le seuil dans le libellé.
- **Fiches d'exemple** : dans l'**ACR**, l'adrénaline commence au 3ᵉ choc puis revient à
  l'échéance de « prochaine dose », l'amiodarone 300 mg (3ᵉ choc) et 150 mg (5ᵉ) ne se font qu'une
  fois ; dans l'**Anaphylaxie**, l'adrénaline IM du bloc réfractaire revient à l'échéance de la
  réévaluation.
- Réglementaire : § 2 « Le cas du moment d'une étape » (règle de l'auteur appliquée à un compte ou
  un minuteur de l'équipe, régime des jalons).

## [5.31.1] — 2026-09-25
Quatre retouches signalées à l'usage (A381, doctrine `docs/decisions/lot-v5-31.md`).
- **Notice « Vous êtes l'auteur… »** : la croix dépassait d'une notice d'une ligne (posée 4 px sous
  le haut, 32 px de haut pour une notice de 34). Elle se centre désormais sur la première ligne.
- **Recherche de l'accueil** : 16 px au téléphone au lieu de 17,5, en accord avec le reste de
  l'accueil. 16 px est le plancher d'iOS : en dessous, Safari zoome au toucher. 15 px sans écran
  tactile.
- **Cases des étapes CRITIQUE / VIGILANCE** : l'étiquette se loge dans une marge haute réservée,
  hors du flux. La case reste centrée sur le libellé, au même endroit que dans une rangée sans
  étiquette (elle était centrée sur l'ensemble étiquette + libellé + détail, donc visiblement
  plus basse).
- **Colonne « Parcours inerte » du bureau** (et rail 780-1199) : chaque bloc se plie à son titre,
  seul le bloc courant est déplié d'office. Une décision reste ouverte, puisque ses branches
  sont le chemin. Un chevron par bloc, au clavier comme au toucher. Le
  parcours de l'ACR tient désormais en entier à l'écran. Toucher un bloc de cette colonne ne
  faisait plus rien depuis la v5.30.6 (bascule orpheline) : ce geste revit ici.

## [5.31.0] — 2026-09-25
La coche d'une étape peut lancer un minuteur ou compter, un bloc peut porter son minuteur, et une
ligne discrète le dit sous l'étape (A377 à A380, doctrine `docs/decisions/lot-v5-31.md`). Demande de
l'auteur, choisie sur trois versions de maquettes ; puis des micro-mouvements logiques, la règle
« ne pas anticiper » et deux essais d'affichage à juger en conditions réelles.
- **La coche lance** (`starts` sur une étape) : cocher « Adrénaline 1 mg IV » lance « Adrénaline —
  prochaine dose » depuis zéro. **La coche compte** (`counts`) : cocher « Choc » ajoute 1 au
  compteur et pose l'heure au journal, comme le « + » de la carte.
- **Le bloc minute** (`timer` sur un bloc) : le minuteur repart à chaque entrée dans le bloc
  (Continuer, réponse, nouveau passage) ; au bloc où la session démarre, avec elle. Il s'arrête
  quand le parcours quitte la boucle. À l'échéance, rien n'est choisi et rien ne défile.
- **Tout se défait par la case** : décocher retire le + 1 et barre le repère ; décocher dans les
  10 s rend le minuteur à son état d'avant. Après, il continue et s'arrête depuis sa tuile.
- **Une légende d'une ligne** sous l'étape liée et sous le titre du bloc : 24 px réservés dans tous
  les états, la valeur d'abord (celle de la tuile), gris au repos, bleu sans fond quand ça tourne,
  pastille ambre pâle avec « Échu » à l'échéance. Aucune hauteur ne change sans geste. Annoncée sans
  état dans le parcours à plat, la Page et l'éditeur.
- **Éditeur** : « Ce que fait la coche » dans les outils d'une étape, « Minuteur du bloc » sous le
  bloc ; rien n'est proposé si la fiche n'a ni minuteur ni compteur.
- **Prompt IA de création** : nouvelle section « Minuteurs et compteurs liés », 0 à 3 liens par
  fiche et 0 ou 1 minuteur de bloc, seulement quand la source lie le geste au délai ou au compte ;
  vérification finale n° 17.
- **Fiches d'exemple** (proposées au premier lancement) : dans l'**ACR**, cocher « Choc immédiat »
  compte le choc, et cocher l'une des deux « Adrénaline » lance « prochaine dose ». Dans
  l'**Anaphylaxie**, les deux injections IM comptent sur « Adrénaline IM », et ce compteur relance
  la réévaluation à 5 min. Elle ne repart plus seule à la sonnerie (A379) : entre la sonnerie et
  l'injection, 30 s d'analyse ou un choc peuvent passer. Elle reste « Échu » jusqu'à la coche
  suivante. Le prompt IA gagne la règle « ne pas anticiper ». Pas de minuteur de bloc dans les exemples : aucune des deux fiches n'a
  de tentative bornée par passage. « — noter l’heure » disparaît de l’adrénaline IM : la coche
  pose désormais l’heure au journal.
- **Micro-mouvements** (A378), chacun répondant à un geste : cocher fait monter le chiffre ou
  remplir l'anneau (minuteur relancé depuis zéro), décocher fait redescendre la valeur, une jauge
  discrète se vide pendant les 10 s d'annulation, l'échéance se pose en fondu. Dans l'éditeur, la
  légende apparaît sous l'étape dès que le lien est choisi. Rien ne boucle, rien ne change de
  hauteur, et rien ne bouge en mouvement réduit.
- **Éditeur** : un minuteur d'intervalle neuf ne repart plus seul par défaut (A379) ; reboucler se
  coche. Le cycle RCP de l'ACR, lui, reste à cycles (décision de l'auteur).
- **Deux essais d'affichage à juger en conditions réelles** (A380), dans Moi › Affichage, sur
  l'appareil seulement, éteints par défaut :
  - **Capsule « horizon »** : les minuteurs en cours posés sur un axe de 5 min, à leur temps
    restant. Rien n'est extrapolé : ni cycle suivant, ni échéance future ; l'échu se pose sur
    « maintenant ».
  - **Instruments en bande** : dès la tablette, la capsule porte les minuteurs et les compteurs
    comme au téléphone et ouvre le volet des corrections ; la colonne de droite garde le journal
    et les repères posologiques.
- **Conformité** : § 2 de `docs/deploiement-et-conformite.md` complété avant le code (déclencheur
  toujours un geste de l'équipe, rien ne décide, tout se défait).
- **Sans doublon** : une seule fonction pour relancer un minuteur (quatre copies auparavant ; le ⟲
  d'un minuteur ad hoc et la relance par un compteur lèvent désormais aussi l'acquittement), une
  pour le « + » d'un compteur, une pour le nom par défaut d'un minuteur (sept copies) ; le parcours
  du graphe des blocs est partagé avec le grisé « hors chemin » ; glyphes pris dans la table
  d'icônes commune ; commentaires ramenés à une ligne, la doctrine vit dans le lot.
- **Témoins** : 33 tests unitaires (modèle, sortie de boucle, légende) et une section
  `audit-doctrine` « A377 » (25 contrôles, dont la fiche d'exemple Anaphylaxie, les mouvements et la sonnerie) et une section « A380 » (10 contrôles, les deux essais). Aucun changement côté serveur.

## [5.30.6] — 2026-09-25
Huit retouches de cohérence listées par l'auteur après 5.30.5, et l'« Échelle » du plan s'en va
(A376, doctrine `docs/decisions/lot-v5-30.md`).
- **Notices** : « Vous êtes l'auteur… » prend le dessin de la bulle système (même bord, même rayon,
  même rembourrage) — deux dessins pour un même rôle.
- **Moi** : « Exporter mes données » et « Un problème ? » espacés de 12 px ; dès 780 px, en rangée à
  largeur de contenu au lieu de 720 px chacun.
- **Cockpit** : la ligne « Parcours · Fait · n étapes » collait à 4 px de l'en-tête qui porte la
  capsule ; 20 px, comme sous la capsule ailleurs.
- **Une seule barre d'outils** : Schéma en ligne et plein écran, Page, et les ‹ › de toutes les
  recherches partagent une règle — M 40, matière de travail v5.30, rayon 12, corps 13,5 gras.
- **« Vérifier :: »** : secondaire de la rangée de flux, à la hauteur de « Continuer » (56), matière
  calme, corps 15.
- **Options d'une décision** : le corps des étapes en session (17,5) ; le renvoi « → bloc n · titre »
  ne coupe plus le titre à 17 caractères, l'ellipse prend la place disponible.
- **« Le tableau ne colle pas ? »** : la carte des différentiels se signale 2,4 s d'un anneau qui
  s'efface (fixe sous `prefers-reduced-motion`, jamais une couleur seule).
- **Le parcours n'a plus qu'un dessin** : la liste numérotée à renvois écrits (A349) rend aussi la
  feuille « Se repérer », la colonne du cockpit et le rail 780-1199, avec l'état de session (rangée
  courante en bleu et `aria-current`, blocs cochés en vert, hors chemin en pointillé ; rien ne se
  coche là). L'ancienne Échelle n'avait plus d'appelant : purgée avec ses 65 règles et treize
  classes, épitaphe posée dans la feuille.
- Vérifié : check complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.30.5] — 2026-09-25
Une échelle fermée pour les CONTRÔLES (A375, doctrine `docs/decisions/lot-v5-30.md`). Retour de
l'auteur après l'audit typographique : les lettres tenaient leur échelle, les boîtes n'en avaient
aucune — mesuré, 18 hauteurs de bouton entre 28 et 70 px, champs 40 · 44 · 48, segments 35 à 44 ;
sur le seul accueil : en-tête 36, « Sélectionner » 40 × 130, filtre 44, recherche 44, carte 115.
« Bigger is not better » : tout descend ou s'aligne, une seule montée.
- **S 32** : mini-boutons de l'éditeur (32 à 48 avant), chips de catégorie, ✕ de bandeau, épingle,
  bulle d'historique, barre d'outils Markdown.
- **M 40** : boutons d'en-tête de toutes les vues (l'accueil monte de 36 à 40 — la seule montée,
  choisie), filtre rond, « Sélectionner » en pilule SANS icône sur la matière du chrome, `.btn.sm`,
  ✕ de toutes les fenêtres avec un seul glyphe.
- **L 44** : champs de l'éditeur (48), touches du quai en session (50), boutons de « Terminer » (46),
  « Rejoindre » (48), segments de la feuille Affichage (40).
- **XL 56** : Démarrer, Exercice, Continuer, Découvrir, porte « Ajouter à cette aide » (60 avant).
- **Rangées 52** : cartes dépliables (54), tuiles du menu ⋯ (56), réglages du compte (70), bloc du
  journal (50).
- **Cartes d'accueil au téléphone** : titre 17,5 → 15/700 comme en large (décision de l'auteur,
  renverse A359 sur ce point) — la carte passe de 115 à 92 px.
- Mesuré après, à 390 px : boutons sur 32 · 40 · 44 · 52 · 56 · 64 pour 190 des 202, le reste étant
  des libellés sur deux lignes. Dette dite : le garde-fou `check-ctrl` reste à écrire.
- Vérifié : check complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.30.4] — 2026-09-24
Audit typographique demandé par l'auteur, MESURÉ sur 46 surfaces à 390 px (tactile) et 1100 px
(A374, doctrine `docs/decisions/lot-v5-30.md`) : l'échelle fermée est respectée, mais six écarts
de rôle la contredisaient. Tous refermés et re-mesurés.
- **Accueil** : recherche du dock à 17,5 px au téléphone, face aux titres de carte 17,5 gras (A359
  l'écrivait, la règle disait 15) ; en large elle reste à 15, comme la carte. Nature de rangée
  « AIDE / PROTOCOLE » 11 → 12, catégorie 12 aux deux largeurs (11 en large avant).
- **Feuille « Se repérer »** : nœuds 12 → 13,5, renvois 11 → 12, titre de rail 12 aux deux largeurs —
  il n'était stylé qu'au-dessus de 780 px et tombait sur le 16 px du navigateur au téléphone.
- **Menu ⋯** : tuiles « Se repérer » et « Schéma » 11 → 13,5 gras (corps de commande, pas de sur-titre).
- **Compte** : note de confidentialité 13,5 aux deux largeurs (11 en large avant).
- **Éditeur** : libellés de champ 12 → 13,5, l'aide reste à 12 — la question se distingue de son explication.
- Laissés tels quels, motivés dans A374 : le 16 px des champs (plancher iOS, règle 9) et les titres
  de fenêtre 24 / 17,5 (A352 fait foi, classement de Stockage, Versions et Catégories encore ouvert).
- Vérifié : check complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.30.3] — 2026-09-24
Retours de l'auteur sur 5.30.2 (A373, doctrine `docs/decisions/lot-v5-30.md`).
- **Le contenu descend sous le fondu d'iOS 27, et c'est réversible en une ligne** : le sol d'A370
  rend le voile invisible sur l'inset, mais son fondu (~16 pt au-delà) tombait sur le haut de
  l'en-tête. Un token nommé porte le contournement — `--ios27-top:min(env(safe-area-inset-top),16px)`
  et `--sat` = inset + ce décalage, lu par les quinze consommateurs de l'inset haut (en-tête, sol,
  colonne et barre de sélection, alertes, plein écran, moniteur, fenêtres, barres PDF et Page, lien
  d'évitement). Nul sans inset : les navigateurs ne bougent pas d'un pixel. **Le jour où Apple
  corrige : `--ios27-top:0px`, rien d'autre.**
- **Version au pied de l'accueil au téléphone**, et **« Un problème ? » dans Moi / Mon compte**
  (carte « Sur cet appareil », connecté ou non) : ouvre la fenêtre de stockage qui porte « Réparer
  l'application » — la maquette v5 avait masqué le socle au téléphone, et avec lui la seule issue
  d'une app installée bloquée sur une vieille version.
- **Le code de connexion se colle à nouveau** : la bulle « Coller » était absente parce que la classe
  du geste « Maintenir » (qui bloque sélection et bulles pendant l'appui) restait collée au body
  quand le bouton de remise à zéro était re-rendu pendant l'appui — plus aucune bulle nulle part
  jusqu'au rechargement. La fin du geste s'écoute désormais sur le document, et un champ qui prend
  le focus retire la classe par ceinture. Un collage ne garde que les chiffres, Entrée valide.
- Vérifié : check complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.30.2] — 2026-09-24
Trois signalements d'iPhone, mesurés au simulateur iOS 27 avant d'être traités (A370-A372,
doctrine `docs/decisions/lot-v5-30.md`).
- **iOS 27, le verre flou du bord haut (A370)** : ce n'est pas l'app — le système compose son
  propre voile PAR-DESSUS la vue web, sur tout l'inset de l'heure puis en fondu sur ~16 pt, quel
  que soit ce que la page fixe dessous (sonde rouge : un sol opaque est lui-même délavé ; un vrai
  `<div>` fixé, testable au toucher ou non, subit la même chose). Le remède retenu rend le voile
  invisible : un sol de la couleur du fond sous l'heure sur TOUTES les vues (accueil, lecture,
  édition, aides et protocoles), au-dessus des fenêtres et des feuilles — reste le fondu de 16 pt
  au défilement, celui de toute app native iOS 26+ ; en thème sombre, rien ne se voit. Le `<head>`
  portait DEUX balises de style de barre d'état (`default` d'A368 puis `black-translucent`) : la
  seconde l'emportait, A368 n'a jamais été en vigueur — une seule désormais, `black-translucent`.
  Le style `default` a été mesuré : barre grise opaque plus sombre que la page, contenu jamais
  flouté, mais mise en page à reprendre (inset nul) — non retenu, choix laissé à l'auteur.
  ⚠ Réinstaller l'app pour la balise ; le sol arrive par la mise à jour.
- **Le pied de lecture qu'on croyait masqué (A371)** : « Cet appareil seulement · x Mo · vX » en
  bas d'une fiche ou d'un protocole n'était pas `footer.tools` (déjà masqué depuis des versions —
  le correctif de 5.30.1 était mort) mais une rangée émise par le rendu. Purgée avec son CSS, son
  rafraîchissement et sa règle d'impression ; le doublon de 5.30.1 part avec.
- **« Recevoir le code » (A372)** : la fenêtre Compte disparaissait sur iPhone après l'envoi
  (état posé, position perdue — non reproduit au simulateur). Le formulaire relâche désormais le
  champ actif AVANT de remplacer le DOM, pour que le clavier se ferme par la voie normale et que
  les deux viewports se recollent ; et « E-mail invalide » ne vide plus le champ.
- Vérifié : check complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.

## [5.30.1] — 2026-09-24
Suite de la refonte v5 : les décisions restantes sont prises, la feuille « Consulter » a vécu, et
la page de lecture s'aligne sur une seule grammaire de cartes, de menus et de flèches (A363-A369,
doctrine `docs/decisions/lot-v5-30.md`).
- **Décisions de l'auteur** : les volets Outils et Journal restent sur la matière système, le quai
  garde ses quatre touches (écarts d'A350 clos) ; « Moi » liste les bibliothèques avec leur rôle
  (A364) ; **Sessions et Moi sont des VUES de la colonne ≥ 780 px** (A365) — mêmes portes, mêmes
  rendus que les pages-fenêtres, qui restent la règle au téléphone et depuis une fiche ; au
  franchissement de 780 la surface change de peau sans se perdre.
- **Accueil** : un seul filet au pied de la colonne ; la feuille « Affichage » a le même contenu à
  toutes les largeurs ; « Affichage » et « Sélectionner » sont un même bouton ; recherche et filtre
  du bas à 44 px (retour sur A359) ; titre de la carte « Session en cours » 17,5/800 partout ;
  la croix du rappel « Session terminée » est bornée à 32 px ; les sous-feuilles de la sélection
  (bibliothèque, catégorie) proposent « ‹ Actions » (A366).
- **Page de lecture** : les quatre cartes de la session (À vérifier, différentiels, repères,
  Références) existent AVANT la session, fermées d'office comme « Parcours », en mode « Toute la
  fiche » et sur une aide sans parcours aussi ; une seule fabrique (`foldCardsH`). **La feuille
  « Consulter » est retirée** (A367) : « Le tableau ne colle pas ? » et « Documents · n » mènent à
  la carte de la page, ouverte seule ; rien d'autre n'y menait (vérifié au grep). Plus de pied de
  page en lecture ; ligne des minuteurs à la gouttière ; « Repères posologiques » sans trait sous
  son titre ; tuiles du menu ⋯ sans filet ; « Parcours » repliée à 56 px comme les autres.
- **En session — la bulle d'historique** (A369, planche A) : la ligne-bilan devient une bulle
  centrée entre « PARCOURS » et le compte (« Fait · 1→2 · diagnostic confirmé », icône
  d'historique, 28 px, matière discrète), qui s'allume une fois quand un bloc coché la rejoint ; un
  tap l'ouvre en carte de rangées. 40 px rendus au premier bloc. Les colonnes latérales s'arrêtent
  au-dessus du quai et ne bougent plus à l'ouverture. Compte et chevron du bloc en cours et des
  rangées d'historique comme sur les cartes ; **un seul chevron** (`uiIcon('chev')`, trait, gris,
  tourné par une classe) sur toute la page de lecture — cartes, bloc, historique, bulle, rails,
  aperçu du schéma.
- **iOS 27** : barre d'état déclarée en style « default » contre le verre flou posé par le système
  sur le haut du contenu (A368) — à vérifier sur l'appareil.
- **Garde-fous** : `audit-consulter` réécrit autour des cartes ; témoins adaptés (fenêtres
  ouvertes depuis une fiche en large, Parcours ouverte pour lire ses liens, dérive du journal
  mesurée DANS le fil, croix du rappel centrée, menu ⋯ en feuille) ; palier 924 retiré, `data-rs`
  purgé ; [5.25.1] archivée.

## [5.30.0] — 2026-09-22
### La refonte v5 : la marque d'une étape critique, « Fin » au quai, l'accueil et la fiche alignés sur la maquette (A345-A351)

- **Demande de l'auteur** : implémenter la maquette v5 (smartphone à fidélité haute, planche large
  en grille A) dans l'ordre tokens → étapes critiques → accueil → fiche → session → protocole →
  paliers → pliables, sans nouveau token ni valeur hors échelle, en réutilisant l'existant. La
  décision typographique jointe est normative : l'échelle A6 reste fermée à sept crans, seule
  l'affectation monte d'un cran.
- **Tokens** : `--g-cmd` (glyphe de commande, 17,5) et `--shadow-cur` (l'ombre du seul bloc
  courant, `none` la nuit) ; aucun autre.
- **A345 — la marque d'une étape critique (« 6b »), A11 rouvert** : toutes les étapes d'une liste
  partagent le même corps (17,5 en session, 15 en lecture) et la même colonne ; le danger est porté
  par le MOT en étiquette au-dessus du libellé (« CRITIQUE » / « VIGILANCE »), la bordure de la case
  (36 px, 2,5 px au registre) et le préfixe lecteur d'écran — aucun glyphe ⚠/△, aucune encre colorée
  sur le texte. Une fabrique (`stepMarkHtml`) pour la rangée cochable et l'aperçu à plat. Rangées de
  64 px arrondies sur l'ambiance, cochée en vert doux avec case pleine ; titre de bloc et question à
  21 ; carte de décision ambre doux, options 15/800, issue prise à la matière système. L'encre de
  « VIGILANCE » est `--warn` : `--warn-line` sur `--warn-soft` tombe à 3,19:1 la nuit (calculé).
- **A346 — « Fin » au quai** : touche au registre critique de la matière système, ouvre la fenêtre
  « Terminer la session ? » (seule porte, inchangée) dont la confirmation se MAINTIENT 1,2 s
  (relâcher annule ; clavier direct) par la mécanique de remise à zéro des minuteurs. Les touches
  constantes du quai restent ; « Se repérer · Schéma » en rangée sous le bloc courant (< 1200) ; budget de chrome reposé à
  32 / 39 % (capsule 64 px).
- **A347 — accueil** : plus d'intertitre « Répertoire » (ligne de compte, « Affichage » à pastille,
  Sélectionner), rangement par catégorie par défaut, rangées 64 px / méta 13,5, badges d'attente
  achromatiques (seul « À revérifier » reste ambre), tuiles 76 px à liseré 6 px et point pulsant,
  livres en grille dès 780. **Fiche** : sur-titre CATÉGORIE · CODE à pastille carrée, chips 12/800,
  trois cartes dépliables à état par fiche (« Quand l'utiliser », « Ne pas oublier », « Parcours »,
  critères et rappels à 17,5), statut de l'éditeur en segmenté à pastille glissante. **Session** :
  capsule de 64 px sur une ligne (chrono 24, tuiles à barre 3 px), « + Minuteur » 1 · 2 · 3 · 5 min
  libellé par la durée, pastille numérotée du bloc sur la ligne du titre.
- **A348 — large et pliables** : la capsule ne monte dans l'en-tête qu'au cockpit (≥ 1200) ; grille
  du protocole sur `--col-orient` ; dépliant « Sommaire · n sections » avec compte par titre et
  sections sans résultat repliées en recherche ; `horizontal-viewport-segments:2` — deux volets,
  gouttière 24 px sur la pliure, quai borné au volet gauche.
- **A349 — seconde passe sur les captures** (demande de l'auteur) : « Journal · n » au quai (le tap
  pose l'heure puis relit le journal), premier compteur en tuile dans la capsule ; accueil en CARTES
  (voie étroite), feuille « Affichage » (afficher · trier · regrouper · densité), « Sessions » dans
  l'en-tête ; écran de bienvenue de la maquette (trois portes) ; « Créer » par deux cartes de type ;
  parcours de l'écran d'entrée en liste numérotée avec renvois écrits (`preFlowFlatHtml`) ;
  « Parcours · x/y », pilule « EN COURS », « Ne pas oublier » en carte ; historique des sessions en
  cartes ; sommaire de protocole en carte, titres 17,5, chevron à gauche ; identité de l'éditeur
  ouverte, porte « Ajouter » en bouton flottant tonal (la palette garde toutes ses options).
- **A350 — troisième passe, la cohérence du style** (demandes de l'auteur : « l'ENSEMBLE du style »,
  « les sélecteurs glissants comme la maquette », « plus d'en-tête blanche sur smartphone ») : UNE
  pastille glissante pour tous les segmentés (piste `--amb-2`, pastille blanche à ombre, encre
  `--ink`) ; l'en-tête sur l'ambiance sans filet, commandes en pastilles de 40 px (« + » rempli, compte
  sur `--primary-soft`), titre de lecture en sans 15/700, sur-titre réduit à CATÉGORIE · MODE sous
  430 ; quai hors session sans matière (« Démarrer » rempli `--act`, « Exercice » pointillé) ;
  lecture : titre 24/800 dans la page, méta en une ligne 13,5, options sur deux colonnes,
  « Continuer » rempli, « Mode écran » ; taille du texte à trois crans ; éditeur : champs `--amb-2`
  à filet 1,5 px, intitulés 12/800, cartes blanches, chapeau à badge « ! » ; fenêtre Compte en
  cartes ; « Sessions » en cartes ; carte « Session en cours » de l'accueil en carte blanche (plus de
  bande verte, « Reprendre » bleu — demande de l'auteur). `--act-sys` purgé. Écran de bienvenue : titre 38 rendu (il perdait
  contre `.ai-card h3`).
- **A351 — relecture de l'auteur sur les captures** : la pastille se glisse partout (feuille Affichage,
  statut) ; carte « Session en cours » à liseré vert (téléphone) et bande système (large) ; le titre
  n'est jamais écrit deux fois (dans la page au téléphone, dans la barre dès 780, discriminant sur la
  ligne du titre) ; réponse attendue en mono neutre ; colonne gauche de la planche large (marque,
  Aides · Sessions · Moi, « Gérer » en lien, compte au pied, en-tête réduit à recherche + Créer) ; bordure
  bleue du bloc courant ; en session « Ne pas oublier » PUIS À vérifier, différentiels, repères en cartes
  dépliables SOUS le bloc ; « Mode écran » au menu ⋯ ; titres de protocole à chevron droit sans
  indentation ; socle de l'accueil supprimé au téléphone (Rejoindre → Sessions, Gérer → Affichage) ;
  sommaire de protocole sous le titre, collant en défilant ; compte des cartes contre le chevron.
- **A352 — cinquième passe (relecture de l'auteur)** : DEUX MATIÈRES DE FENÊTRE — les six destinations
  (Sessions, Compte, Catégories, Stockage, Bibliothèque, Versions) deviennent des page-fenêtres
  (`.ai-modal.page` : fond d'ambiance, cartes, titre 24, pastille de fermeture ; plein écran au téléphone,
  panneau au gabarit document dès 780), les dialogues restent des cartes blanches ; barre de sélection ≥ 780 en carte
  entière ; `.btn` à la matière v5 (primaire `--act` plein, `--shadow-primary` purgé) ; anneaux de focus
  jamais rognés (corps de fenêtre respirant sur les deux axes, anneau intérieur sous `overflow:hidden`,
  colonne) ; cartes d'historique resserrées (17,5 / 44 px) ; Compte en cartes (appareil, connexion,
  vocabulaire) ; recherche large à 40 px ; logo et code de session dans la recherche MESURÉS conformes.
  Quatre témoins adaptés à A351 (dont un qui PENDAIT 30 s sur une barre cachée).
- **A353 — sixième passe** : bandeau système en BULLE (trois largeurs) ; UNE feuille « Affichage » pour
  le rangement ET les filtres (la feuille Filtrer est purgée, groupe Catégorie et pied « Tout effacer ·
  Voir les n résultats » repris), ouverte par le bouton ROND à gauche de la recherche (52 px, permanent,
  même matière qu'elle — renverse A238 sur ce point), un seul « ＋ Créer » à l'état vide,
  « Moi » porte les initiales du compte (pied « Compte » supprimé), « · discriminant » respire dans
  l'en-tête, Tableau · Schéma alignés, consigne du dialogue Terminer dégagée, croix du bilan centrée ;
  préférences d'affichage vérifiées persistantes, commentaire du tableau ≥ 1200 corrigé ; fenêtre Compte
  relue à la mesure (quatre paliers, rien sous 12, graisse 650 purgée) et **`.btn` à 15/700 partout**.
- **A354 — septième passe** : « Références » en carte dépliable sous les cartes de session (schémas,
  documents, sources, renvois), « Consulter » quitte le quai, le bas de fiche et la colonne du cockpit
  (quatre touches de largeur égale, « Fin » au gabarit commun) ; « Mode écran » retiré ; le rail perd
  « Terminer la session… » ; la capsule ne monte dans l'en-tête qu'au bureau (≥ 1440), une tablette en
  paysage garde la bande.
- **A355 — huitième passe (canevas)** : un filet discret entre les touches du quai ; la rangée « session en
  cours » perd son aplat vert (carte blanche, liseré 6 px, « ● En cours » en vert), en vue détaillée et compacte.
- **A356 — neuvième passe** : légende « réponse attendue » à la voix mono des réponses, plus de « Terminer la
  session… » dans le volet du quai (A336 amendée : la session se termine au quai), contraste des boutons de la
  carte « Session en cours » (bord critique au téléphone, encre et bord `--crit-sys` et « Reprendre » plein sur la bande).
- **A357 — dixième passe (canevas)** : une seule grammaire pour les cinq dépliants de session (tête commune
  avec compte et chevron, rangées à filet sans marque, réponse ou dose en mono, Références sans carte imbriquée).
- **A358 — onzième passe** : UNE carte dépliable (`foldCardHtml`) pour l'écran d'entrée et la session — même
  tête, même corps, même rangées ; « Ne pas oublier » perd son gestionnaire à part ; seconde ligne des
  différentiels et des repères en corps 13,5 ; « Sources » dans la carte Références.
- **A359 — douzième passe** : barre de sélection, dialogues et « Rejoindre » sur la matière des boutons v5 ;
  texte de la recherche du téléphone à 17,5 et icône de filtre à 24 ; la dernière carte d'un groupe de
  l'accueil garde son bord bas (invisible en sombre).
- **A360 — treizième passe** : la feuille « Actions » de la sélection (téléphone/tablette) parle la
  grammaire du menu ⋯ — icône, sous-ligne et chevron par rangée (`openPickMenu` : `ic`/`sub`/`chev`),
  matière de travail, en-tête 17,5 sans filet, rangées 52 px à filets entre elles, danger à l'écart.
- **A361 — quatorzième passe** : UN dessin de menu — `menuRowHtml` émet la rangée `.mm-row` du menu ⋯
  et des sélecteurs, coque `.popmenu` ancrée ou en feuille ; le menu ⋯ devient une FEUILLE BASSE sous
  780 px (montée sur `<body>`, voile, poignée) ; le pied danger encadré a vécu (A337 amendée).
- **A362 — quinzième passe** : à l'accueil en cartes, 8 px entre les cartes d'un groupe et 24 px avant
  chaque intertitre (elles se touchaient) ; le livre compact ne change pas. Le témoin partage « rien ne
  bouge » mesure la dérive dans le fil (la rangée « Connexion perdue » du quai le décalait sous charge).
- **Écarts restants, à décider avec l'auteur** (doctrine A350-A362) : volets Outils/Journal blancs, quai à trois tuiles, bibliothèques dans Moi, Sessions/Moi en vraies vues de la colonne
  ≥ 780 ; deux formes refusées d'A330 reprises sur maquette
  (intitulés dans les cartes, Parcours dépliable — ouvert par défaut).
- Témoin `audit-doctrine` « v5.30 · A345 » ; doctrine `docs/decisions/lot-v5-30.md`, index,
  `design/ds` régénéré, CHANGELOG à 20 ([5.25.0] archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro.

## [5.29.4] — 2026-09-11
### La destination devient une pastille, les voies cessent de se superposer, et le papier se pagine avant d'être peint (A344)

- **Signalés à l'usage** : « il reste des soucis de superposition des flèches, et des flèches qui
  passent au-dessus des blocs » ; « les options à droite dans les blocs sont encadrées, contrairement
  à l'app » ; « le bout de la flèche n'est pas visible » ; « puis fais le paginateur mesuré ».
- **La destination est une pastille**, comme sur la maquette retenue : « CONTINUER ↓ 4 » au registre
  de la décision (cadre ambre plein), « ALLER À 7 » et « REVENIR À 2 » au registre des voies (cadre
  bleu pointillé, fond pâle), « ▪ FIN » reste un mot. Elle donne surtout au trait un bord d'où
  partir : une sortie part du bord droit de la pastille, un retour du bord gauche de la boîte — de la
  pastille il traversait le libellé de sa propre ligne (mesuré deux fois sur l'état de mal).
- **Un bus, pas n traits superposés** : trois décisions sortaient vers le même bloc et descendaient
  dans le même couloir, **615 px l'une sur l'autre**. Les lignes rejoignent le couloir par un tiret,
  la descente est unique. Toutes les voies passent par un registre de couloirs partagé (une abscisse
  prise glisse de 5 px), et le collecteur d'une fourche descend dans l'interstice de sa branche au
  lieu de longer la colonne des numéros. Une pointe s'arrête à 5 px du numéro, qui porte un halo et
  passait devant elle.
- **Le paginateur mesuré, et les voies reviennent sur le papier** : `svPaginate` pose lui-même les
  sauts de page, donc il les connaît — hauteur utile mesurée en millimètres, blocs insécables dans
  l'ordre du flux, saut avant celui qui déborderait. Les chemins s'écrivent en points, se coupent aux
  frontières et se décalent : un trait sort en bas d'une page et reprend en haut de la suivante, à la
  bonne cellule. Il peut renoncer et le dit (un bloc plus haut qu'une page), le calque restant alors
  masqué. Coût mesuré : l'état de mal passe de 3 à 4 pages, une fourche insécable laissant du blanc.
- **La feuille imprimée garde sa géométrie d'écran** et se centre dans les 210 mm : un padding
  différent décalait le calque de 28 px, et le couloir de droite passait sur le texte des cellules.
- **Témoin** (`audit-doctrine`) : aucun segment ne pénètre une cellule, un numéro, un intitulé, une
  pilule ou un texte de décision ; aucune superposition ; imprimer une aide imprime la Page ; le
  paginateur a posé ses pages ; l'écran retrouve son état. ⚠ Sa première écriture était **aveugle** —
  elle testait un recouvrement sur les deux axes alors qu'un segment a une épaisseur nulle, donc la
  condition ne pouvait jamais être vraie. Corrigée en testant l'appartenance, vérifiée capable
  d'échouer, elle a immédiatement trouvé deux vrais défauts.
- Doctrine A344 (trois addenda), index, `design/ds` régénéré, CHANGELOG à 20 ([5.24.2] archivée).
- Vérifié : `npm run check` complet, 1202 tests × 2 moteurs, audit complet après le numéro de version.
