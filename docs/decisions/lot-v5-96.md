# Lot v5.96 — la rangée « En cours » redevient la bande de session (A590)

> Fichier normatif. Les numéros A sont des adresses : ne jamais renuméroter. Décidé sur maquettes (captures de l'app
> servie, modifiées en place), **implémenté en v5.96.0**. Amende A523 ; reprend A356 et le périmètre nocturne d'A222.

Signalé par l'auteur, à l'usage : « liste des sessions en cours sur la page d'accueil : enlève l'étoile, car on peut
la confondre avec Accès direct ; et à quel moment les boutons Reprendre et Terminer ont-ils disparu ? » Puis, sur
maquette : « tu ne proposes pas de changer le style comme avant, pour identifier que c'est une session en cours ? »,
et « ça donnerait quoi en mode sombre ? ». Retenu par l'auteur : la bande sombre, contour vert en thème sombre.

## Constat — v5.95.0

- **Reprendre et Terminer ont disparu en v5.67.0 (A523)**, avec la carte sombre « Session en cours » : l'aide en
  session montait dans le groupe « En cours » avec la rangée commune. A523 le disait : « Terminer » depuis l'accueil
  restait à un tap, dans la session (« Fin » du quai). Reprendre, c'était le tap de la rangée — sans mot pour le dire.
- **L'étoile y était restée** parce que la rangée est la même partout. Dans « En cours », juste au-dessus d'« Accès
  direct » où paraît la même aide, une étoile pleine se lisait « accès direct », pas « session ».
- **Une session en cours avait deux dessins** : la carte d'une session PARTAGÉE gardait la matière système sombre
  (A523 l'avait conservée), la session de l'appareil n'était qu'une rangée blanche.
- **Le vert seul ne distinguait pas** : le même « ● Session 04:12 » paraît sur la tuile d'Accès direct.
- **La ligne « où l'on en est »** (« 1 · Reconnaissance & alerte », `liveWhereText`) était partie avec la carte.

## A590 — La rangée « En cours » est la bande de session (v5.96.0)

*Amende A523 (qui gardait la rangée commune) ; reprend A356 (bande système, « Reprendre » plein clair) et le
périmètre --ok de la carte en thème sombre.*

Dans le groupe « En cours » — et là seulement (`_rowCtx.live`, même mécanisme que la tuile et la collection, A589) —
la rangée d'une aide en session :

1. **N'a pas d'étoile.** L'aide reste épinglable dans Accès direct et dans le répertoire, où l'étoile veut dire
   « épingler ».
2. **Prend la matière système** (`--sys`, encre `--sys-ink`, méta `--sys-ink-2`, chrono `--ok-sys`) : une seule
   rangée, pas de carte en double (ce qu'A523 retirait), mais habillée comme la carte d'une session partagée. C'est le
   seul aplat sombre de l'accueil : sa rareté le fait voir, sans lire.
3. **Dit le bloc courant** sous la méta (`liveWhereText`, 12 px, ellipsé).
4. **Porte deux actions de 44 px** : « Reprendre » plein clair (A356) — le tap de la rangée reprend toujours — et
   « Terminer… » en contour (`--ctl-sys`), **jamais rouge** : rien de permanent n'est rouge (règle 8, A407) ; le rouge
   vit dans la confirmation. « Terminer… » passe par la **même confirmation maintenue 1,2 s** que « Fin » du quai
   (`confirmEndSession`, A346) puis la même fin (`endSession`, bilan en tête) — jamais une fin sèche. Les actions sont
   sur la rangée en large, dessous sous 560 px EFFECTIFS (`html.zw560`, règle 10), « Reprendre » prenant la largeur.
5. **En thème sombre**, la matière système est un gris plus clair que les rangées et ne se détache plus : périmètre
   `--ok-sys` de 2 px sur le groupe (le vert = système nominal, règle 8). **La carte d'une session partagée prend le
   même périmètre** (elle avait le `--sys-edge` gris d'A222) : une session en cours a un seul dessin.

Le mode crise n'est pas concerné (règle 11) : l'accueil n'en fait pas partie, et la confirmation de fin existait déjà
à l'accueil avant v5.67.

*Formes écartées (par l'auteur, sur maquette)* :
- **« Terminer… » à la place de l'étoile, rangée blanche** (variante B) : le plus petit changement, mais Reprendre
  restait implicite et rien ne distinguait la session d'un coup d'œil.
- **La rangée blanche avec Reprendre en bleu** : lisible, mais le seul signe de la session restait le chrono vert,
  présent aussi sur la tuile d'Accès direct.
- **La bande sans contour en thème sombre** : un gris à peine plus clair que les rangées.
- **« Reprendre » en vert plein** (essayé en thème sombre) : le vert dit « fait » ou « nominal », pas l'action.
- **« Terminer » en rouge** (la carte d'avant v5.67) : contraire à la règle 8 réécrite en A407.

Témoin : `audit-doctrine` « Accueil · A523 groupe « En cours », A524 une recherche, A590 la bande de session » (390 et
1280 : bande `--sys`, aucune `.pinbtn`, bloc courant, deux boutons ≥ 44 px, « Terminer… » ouvre `#endSessModal` et
« Annuler » garde la session ; vérifié capable d'échouer sur la v5.95.0 : 4 rouges).
