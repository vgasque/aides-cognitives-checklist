# Lot v5.34 — le parcours : un dessin, trois lieux, des réglages en mots (A388)

> Fichier normatif, suite de [`lot-v5-33.md`](lot-v5-33.md) (A383-A387). Les numéros A sont des
> adresses : ne jamais renuméroter. Demande de l'auteur (26/09/2026) : le « Parcours » de la colonne
> doit se replier, en continuité avec la carte dépliable et la feuille « Se repérer » ; les
> conditions de cochage de la v5.31 (seuil, échéance, une seule fois, minuteurs, compteurs) doivent
> se comprendre « très rapidement » ; Critique / Vigilance à mieux afficher « sans trop changer ».
> Audit mesuré, puis huit maquettes revues une à une avec l'auteur (P1 → P8) avant le code.

## A388 — le lieu fixe densité et repli ; les réglages de coche s'écrivent en mots

**Amende** A381 (la décision se plie désormais, sa ligne de branches restant visible ; le bloc courant n'est plus déplié d'office ; le titre passe de 15 à 13,5 px en colonne) et A376 (le jalon perd son △ ambre).

**Le défaut mesuré (v5.33.2, ACR, 1280 px).** La colonne du cockpit (223 px utiles) rendait le
parcours au corps de la page : titre 17,5 px avant la session, 15 px pendant (le même titre changeait
de taille au démarrage), étapes 15 px. Le repli d'A381 ne dépendait que de `Runtime.started` : avant
la session, tout était déplié, soit 1 540 px de liste pour une colonne de 670. La décision ne se
pliait jamais (354 px en permanence) ; un bloc replié ne montrait que son titre. Les réglages de
coche s'écrivaient avec trois grammaires sous une même étape : la réponse en police à chasse fixe bleue,
la règle du moment en capitales grises (`.mo-rule`, « CHOCS DÉLIVRÉS ≥ 3 · UNE SEULE FOIS ») et
la légende à icône (`.wt-flat`, coupée par l'ellipse en colonne). Enfin, les complications
« à tout moment » n'apparaissaient nulle part dans la liste.

**La règle.** `preFlowFlatHtml(f, st)` reçoit `st.place` : `'card'` (carte « Parcours » de l'écran
d'entrée), `'sheet'` (feuille « Se repérer ») ou `'col'` (colonne du cockpit ≥ 1200 et rail
780-1199). **C'est le lieu qui décide, jamais l'état de la session.**
- **Tout bloc se plie**, décisions et complications comprises, par un chevron sur son titre
  (`data-plfold`). La colonne naît **repliée**, avant comme pendant la session, bloc courant compris
  (décision de l'auteur, Q1). La carte et la feuille naissent **dépliées** (Q2). Un choix explicite
  vit dans `state.ovFold[pfFoldKey(place,id)]` (préfixes `l:` colonne, `ls:` feuille, `lc:` carte).
  `openRead` le remet à zéro. Replier ne repeint QUE la liste (`pfRepaint`) : le défileur qui la
  porte garde sa position.
- **Replié = le titre seul**, sans registre, moment ni minuteur (décision de l'auteur). **Une décision
  repliée garde sa ligne de branches** (« Oui ↓ 3 · Non → 4 », le mot court avant « — »), car
  la raison d'A381 tient : ses branches SONT le chemin. En session, la branche prise porte ✓.
- **Le bloc courant** dit « Ici » dans la ligne de son titre, en plus du cadre bleu : le mot, pas
  la couleur seule.
- **La colonne est un cran plus bas** sur l'échelle fermée : titre et étapes en 13,5, légendes en
  12 ou 11, numéro sur 22 px, losange sur 16 px (une fois tourné, il occupe la colonne de 22 et les
  numéros restent sur UNE verticale). « Tout déplier / Tout replier » coiffe la liste en colonne
  (`data-plall`). Le séparateur « Chemin n » y écrit la réponse courte. Tableau · Schéma tiennent sur
  une ligne.
- **L'en-tête** : « Parcours », avant comme pendant (« Parcours inerte » était du vocabulaire de
  doctrine affiché à l'écran).

**Les réglages de coche, en mots** (`pfStepQual`, parcours seulement ; la Page et l'éditeur ne
changent pas).
- **Le seuil coiffe son groupe** : des étapes CONSÉCUTIVES au même `from` partagent un en-tête
  « **Si** Chocs délivrés ≥ 3 : ». Un filet vertical montre jusqu'où la condition porte. L'ordre de
  l'auteur n'est jamais changé : deux étapes au même seuil séparées par une autre font deux groupes.
- **Le reste suit l'étape**, en gris, joint par « · » : « si pas déjà faite » (`once`, un état de
  la session et pas une quantité : « 1 fois » se lisait comme une dose, objection de l'auteur),
  « au besoin », « toutes les 4 min » (`due` d'un minuteur à décompte que la coche lance ou relance :
  il se refait à chaque fin de ce minuteur), « +1 Chocs délivrés », « relance « Réévaluation » (5 min) »,
  « lance « … » (4 min) ». `due` sans minuteur à décompte : « quand « X » ne tourne pas » ; sans
  minuteur du tout, rien, car le moteur retombe sur « à chaque passage ». Les durées passent par
  `durTxt`, factorisée depuis `cycleTxt`.
- **Minuteur de bloc** sous le titre : « lance « Cycle RCP » (2 min) à chaque entrée ».
- **Retour de boucle** : « ↺ retour à 2 · toutes les 2 min ». Le titre de la cible part (le
  numéro suffit, le nom reste dans l'`aria-label`) ; la cadence vient de `cycleTxt`.
- **Jalon** : « **Si** Chocs délivrés ≥ 3 : texte », suivi d'un renvoi ⚡ vers la rangée de sa
  complication. Le △ et l'ambre d'A376 partent : le jalon se lit comme une étape conditionnelle.
- **Les complications ferment la liste** sous « À tout moment » : un éclair à la place du numéro
  (hors chaîne, donc hors numérotation), pliables, sans « Fin du parcours ».
- **La réponse attendue** suit le libellé après un tiret, au corps du texte et en gris (`.pf-r`,
  la chasse fixe bleue `.pl-r` est purgée). **L'action** est à l'encre pleine, en graisse 500
  (`.pf-lb`). Il reste trois styles de texte : l'action, le contexte en gris, le mot-clé « Si ».

**Critique / Vigilance (option A de l'auteur, après un premier choix B).** Le mot garde sa couleur
et son registre (A345), mais dans le parcours il perd son aplat et **se cale à droite de la première
ligne** (`float:right`) : le texte le contourne, **le libellé ne bouge pas** (une seule abscisse par
bloc, témoin) et il n'y a aucune ligne de plus. Rien n'est tronqué ; la première ligne perd
seulement ~65 px. Mesure contre B (mot au-dessus sans aplat) sur les étapes marquées : colonne ACR
269 → 235 px, Anaphylaxie 378 → 345 px ; carte ACR 211 → 220 px, Anaphylaxie 292 → 260 px. En
colonne, 3 libellés marqués sur 8 prennent une ligne de plus. La carte de session ne change pas.

**Écarté, et pourquoi.**
- Des étiquettes cerclées pour le moment, comme en session (P1) : trop chargé.
- « Si » au-dessus du libellé (P3) : on ne voyait pas à quelle étape il s'appliquait.
- « Si … : action » sur la ligne de chaque étape (P4, P5) : la condition était répétée à chaque étape.
- La puce en case colorée au registre (P1 G1) : elle redisait le mot.
- Le mot du registre à la place de la puce (P7) : il décalait le texte.
- Le mot au-dessus du libellé sans aplat (P8 B) : implémenté d'abord, puis remplacé par A à la demande de l'auteur.
- Des pastilles de registre, de moment ou de minuteur dans le repli (P4 de l'audit) : refusées par
  l'auteur, le repli est le titre seul.

**Témoins.** `audit-doctrine` : la section « Parcours · A388 lieu, repli, conditions en mots » vérifie
que la colonne est repliée avant et pendant la session, qu'une décision repliée garde ses branches
et que le titre et les étapes sont à 13,5 px. Elle vérifie aussi que la complication ferme la liste,
que « Tout déplier » ouvre tout en gardant le focus, que les groupes « Si » sont bien formés, que
les réglages s'écrivent en mots et que le mot du registre, sans aplat, laisse une seule abscisse
aux libellés. Côté feuille, chaque bloc a son chevron, tout est déplié d'office, et replier ne
ferme pas la feuille. Les témoins du jalon et des registres de la colonne déplient d'abord, comme
le ferait l'utilisateur.

**En suspens (demande de l'auteur) :** la réponse de l'adrénaline dans la fiche d'exemple ACR
(« 1 mg, puis / 3–5 min ») redit « toutes les 4 min ». Le contenu n’est pas touché tant que
l'auteur ne l'a pas décidé.
