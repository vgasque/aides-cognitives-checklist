# Journal des modifications

## [4.54.2] — 2026-07-28
### CORRECTIF — l'historique synchronisé de la v4.54.0 ne synchronisait rien

Signalé à l'usage, et exact sur les trois points : la bascule ne suivait pas d'un appareil à
l'autre, les sessions antérieures à l'activation ne montaient pas, celles terminées après non plus.
**La table existait, les politiques RLS étaient vertes, la bascule s'allumait — et pas une ligne ne
partait.** Une fonctionnalité entièrement livrée, entièrement inerte.

### Une cause et demie
`_pushTable` ne pousse que les objets portant `dirty`, et **aucun site n'en posait jamais sur une
session**. Explique les deux symptômes de fond. Le troisième — la bascule qui ne suit pas — venait
d'un oubli distinct : le réglage n'entrait pas dans les préférences synchronisées, alors que le
vocabulaire personnel ajouté à la même version, lui, y entrait.

Le marquage vit désormais au **point d'étranglement de l'écriture** (`_putSessionSafe`), comme
l'émission du partage vit dans `persistLive` : toute mutation ajoutée demain sera couverte sans
qu'on y pense. La pierre tombale de la suppression y passe aussi — elle posait ses champs à la
main, ce qui rendait fausse, dès la ligne où elle était écrite, la doctrine « ici, et nulle part
ailleurs ».

### Deux pièges que la contre-expertise a trouvés, et qui auraient annulé le correctif
**`updatedAt` doit être posé en même temps que `dirty`.** Une session n'en portait pas — seulement
`savedAt`, qui ne bouge plus après l'archivage. Posé seul, `dirty` aurait fait gagner
**inconditionnellement** la copie distante à la résolution du dernier écrivain (`savedAt > 0`,
toujours vrai) — et **effacé la trace do-verify de chaque session à la première synchro**. Le
correctif du push, seul, aurait donc détruit des données.

**Le rattrapage ne peut pas se garder sur une transition.** Qui a activé l'option en v4.54.0 —
quand elle ne poussait rien — a déjà la clé à « 1 » : il ne reverra **jamais** le passage
éteint→allumé. Un rattrapage gardé par cette transition aurait donc raté **exactement les personnes
qui ont signalé le défaut**. La garde est une clé durable, et un réveil de synchro suit le
balayage : quand l'option est apprise par le pull des préférences, la poussée de la même passe est
déjà sortie par son garde d'entrée.

### Vérification
Nouveau harnais **`scripts/audit-historique.mjs`** — quatorzième —, **16/16 sur les deux moteurs**.
Il mesure ce qui **partirait** (transport bouchonné) plutôt que ce que le code déclare : rien sans
l'option, l'existant rattrapé, une session terminée après qui part, la trace do-verify qui reste et
dont l'absence est dite, une session **vive** qui ne part jamais, le réglage qui voyage et qu'une
préférence distante éteint — et le cas « déjà activé en v4.54.0 », qui a son propre contrôle.

**Vérifié capable d'échouer** : les trois défauts réintroduits à l'identique en font tomber six,
fichier restauré à l'octet. Une sonde a dû être corrigée en route — elle avait perdu son bouchon de
transport et accusait l'application de son propre oubli. 747 tests × 2 moteurs, 14 harnais verts,
301 contrôles d'accessibilité, 250/250 partage. **Rien à rejouer côté serveur.**

## [4.54.1] — 2026-07-28
### CORRECTIF — `rls-tests.sql` de la v4.54.0 ne s'exécutait pas, et rien ne pouvait le dire

Signalé au rejeu : `ERROR: 42703: column "v_share" does not exist`. Les trois sections ajoutées en
v4.54.0 (§ 14.15 à 14.17) employaient une variable qui n'existe pas dans le bloc — les conventions
de nommage du fichier n'avaient pas été relues avant d'y écrire.

**Deuxième rejeu perdu par la même famille de faute** (après le `$$` mutilé de la v4.44.1), et pour
la même raison de fond : `supabase/*.sql` n'est ni servi, ni chargé par les tests — sa seule épreuve
est le **collage dans l'éditeur SQL**, donc sur une instance réelle. Pire, PostgreSQL ne signale une
variable inconnue qu'à l'**exécution de la ligne fautive** : un test placé en fin de bloc casse
après trois minutes de travail réussi, et laisse croire que le reste est en cause.

### Les sections sont désormais AUTONOMES
Elles ouvrent leur propre partage et font rejoindre leur propre participant, au lieu de s'appuyer
sur l'état laissé par les tests précédents. Une assertion qui dépend de ce qu'un test antérieur a
bien voulu laisser derrière lui casse au premier réordonnancement — et c'est exactement ce qui
vient d'arriver. Un préalable explicite y a été ajouté : le § 14.12 remplit le quota de partages
vivants d'Alice, il faut donc les expirer avant d'en ouvrir un neuf, sinon l'ouverture échouerait
**pour une raison qui n'a rien à voir avec ce qu'on mesure**.

Deux assertions s'y ajoutent, qui manquaient : § 14.18 (la passation s'annonce des deux côtés) et
§ 14.19 (l'historique de sessions ne se prête pas — Bob ne lit ni n'écrit celui d'Alice).

### Le garde-fou qui aurait attrapé cela
`check-sql.mjs` collecte les variables **déclarées** d'un bloc `do $$ … declare … begin`, collecte
celles qui y sont **employées**, et compare. Statique, donc instantané, donc joué à chaque commit —
là où l'erreur coûtait jusqu'ici un aller-retour complet sur une instance de production.

**Vérifié capable d'échouer** en réintroduisant le défaut vécu à l'identique (`v_share`) : le
contrôle le nomme et donne sa ligne ; fichier restauré à l'octet. Il ne prétend pas remplacer un
analyseur plpgsql — il attrape la faute qui a été commise, ce qui est le seul critère qui vaille.

`schema.sql` de la v4.54.0 était correct et n'a pas à être rejoué ; **`rls-tests.sql` est à
rejouer**. 747 tests × 2 moteurs, 13 harnais verts.

## [4.54.0] — 2026-07-28
### La main se passe, l'historique suit le compte, et le serveur cesse de faire confiance au client

Lot 6 du chantier, la passation de la main, et les trois durcissements serveur annoncés en v4.53.1 —
un seul rejeu de schéma pour l'ensemble.

### La passation de la main
Le scribe ne conduit pas : il ne navigue pas, n'arrête pas un minuteur, ne termine pas. C'est la
forme canonique du travail à deux (AC 120-71B §5.2.2.1) — mais **sans passation, quelqu'un qui a
besoin de conduire n'a aucun recours**, et l'asymétrie devient une impasse. Le genre `handoff`
existait dans le vocabulaire depuis la v4.46.0 ; rien ne l'émettait, aucune surface ne l'offrait.

Trois temps, comme l'exige AC 61-115 « Positive Exchange of Flight Controls » : l'hôte **propose**,
l'autre **prend**, et le changement de rôle vaut confirmation. **Un `handoff` reçu n'accorde rien à
personne : il affiche** (invariant 2 — aucun écran ne change de capacité sans un geste effectué sur
cet écran). Le rôle lui-même ne vient **jamais** d'un évènement, toujours de la lecture suivante :
un rôle qu'un évènement suffirait à changer serait un rôle que n'importe qui s'accorderait.

`handoff` passe donc **aux deux rôles**, client et serveur. Ce n'est pas un relâchement : il ne
change aucun état, et la frontière de sécurité est l'écriture du rôle — un `UPDATE` que la RLS
réserve déjà au propriétaire du partage. Le réserver au lead aurait interdit à l'invité d'**accepter**,
c'est-à-dire d'accomplir le temps que la doctrine exige de lui.

**L'offre se dit dans le quai, le geste vit dans le menu** — doctrine de « Recommencer le parcours » :
une rangée qui apparaîtrait dans la colonne d'action ferait remonter le contenu clinique, sur
évènement distant. Jeton `offert`, sept caractères, position constante. Et `grantLead` **rétrograde
d'abord, promeut ensuite** : dans l'autre sens, une coupure réseau entre les deux écritures
laisserait **deux** leads ; ici le pire cas en laisse **zéro** — dégradé, mais jamais ambigu.

### L'historique de sessions suit le compte
La table lève un invariant écrit du projet — « les sessions vivent en local, jamais synchro » — dont
le **mode exercice tirait sa garantie de non-contamination clinique**. Une bascule qui inverse une
promesse doit dire ce qu'elle change : elle est **opt-in, défaut fermé**, dans la fenêtre Compte,
avec une confirmation qui énonce la portée. Par **utilisateur**, pas par appareil — l'activer ici et
la découvrir éteinte ailleurs serait la pire des surprises.

Ce qui remplace l'invariant :

- **Seules les sessions archivées montent.** Une session **vive** resynchronisée serait un second
  canal de partage — sans code, sans rôle, sans péremption, et sans aucun des garde-fous du premier.
- **L'exercice est ségrégé par une colonne**, plus par la localité : la propriété devient une donnée
  que l'on filtre et que le serveur voit.
- **La trace do-verify ne monte pas**, et **son absence est dite**. Un drapeau fait écrire au compte
  rendu consulté ailleurs : « son détail reste sur l'appareil qui l'a produite ». Une trace absente
  qui ne s'annonce pas se lit *« aucune vérification n'a été faite »* — l'exact contraire de ce que
  la seconde passe existe pour établir.
- **`data` accepte dès aujourd'hui `{v:2, enc:<blob>}`.** C'est la seule décision de forme qu'il
  fallait prendre maintenant : elle devient irréversible dès qu'il y a des données en place, et
  passer au chiffrement de bout en bout ne demandera donc aucune migration.

Suppression = **pierre tombale** dès que la synchro est active (sinon la session effacée revient au
pull suivant depuis l'appareil qui l'ignore), suppression franche sinon. Le tableau de bord compte
les sessions et leurs octets — l'exploitant ne doit pas être aveugle au poste que l'option fait
croître (leçon v4.49.0).

### Le serveur cesse de faire confiance au client
Trois durcissements, annoncés comme ouverts en v4.53.1 :

1. **Liste blanche des clés de payload.** Le serveur ne validait que le **type** et la **taille** —
   c'est de là que partaient les deux injections de la v4.53.1. Il ne garde désormais que seize clés
   nommées. **`label` n'y est pas, et c'est le point** : la promesse « aucun texte libre ne traverse
   le réseau » cesse de dépendre d'une discipline de client. Liste blanche, jamais noire.
2. **Le libellé d'un participant** perd tout métacaractère de balisage. On ne recopie pas en SQL la
   liste des neuf rôles (elle dériverait) : on retire ce qui n'a rien à faire dans un nom.
3. **La coupure mord au serveur.** `share_pull` renvoyait `status: revoked` **et le flux complet** —
   c'était l'application du coupé qui gelait son écran, donc un client modifié continuait de lire.
   Il ne reçoit plus ni évènements ni participants ; le **statut**, lui, reste renvoyé — il faut
   qu'il sache, sinon la coupure passerait pour une panne de réseau. Le § 3.1 du registre, qui
   signalait ce point comme « à durcir », est mis à jour.

### Vérification
747 tests × 2 moteurs (+8), **250/250 contrôles partage** (+18, sur les deux moteurs), 13 harnais
verts, 301 contrôles d'accessibilité sur les deux moteurs, 94/94 doctrine, `npm run check` vert.
Trois assertions RLS nouvelles (§ 14.15 à 14.17) couvrent les trois durcissements — dont une qui
pousse un `label` et vérifie qu'il **ne survit pas à l'insertion**. Un test qui encodait l'ancien
contrat (`handoff` réservé au lead) a été retourné plutôt que supprimé : il affirme désormais la
règle inverse et dit pourquoi.

**`supabase/schema.sql` est à rejouer**, puis `rls-tests.sql`.

## [4.53.1] — 2026-07-28
### SÉCURITÉ — un participant pouvait injecter du balisage dans la checklist des autres

Trouvé en cherchant à répondre à la question « un tiers malveillant peut-il faire voyager du
texte ? ». La réponse est pire que la question : **pas seulement du texte, du balisage**. Deux
injections d'attribut, reproduites avant correction, fermées ici. Aucune ne demande de compte : il
suffit d'avoir rejoint une session avec un client modifié — la console du navigateur suffit.

### Deux routes, et la barrière n'était que sur l'une
Un évènement distant atteint l'écran par **deux chemins distincts** :

- la **peinture** (`sharePaintLive`), en direct — elle normalisait déjà (`safeId`, `tkRefNorm`) ;
- le **pli** (`shareFold` → `buildRuntime` → rendu), qu'empruntent **tout invité qui rejoint** — il
  reçoit l'historique depuis le début — et **tout invité qui recharge**. Il recopiait **brut**.

Une barrière sur une branche et pas sur l'autre ne protège rien. C'est la même leçon que la v4.42.0
(deux copies du cœur de cochage qui avaient divergé), à un endroit qui touche la sécurité.

**Défaut A — l'identifiant d'un repère.** `payload.id` d'un `mark`, recopié tel quel par le pli,
puis interpolé **sans échappement** dans cinq attributs du journal. Le genre `mark` est ouvert au
scribe : n'importe quel participant pouvait donc poser un identifiant qui **sort de son attribut**
et ouvre une balise dans le journal de tous les autres.

**Défaut B — les numéros de visite.** Seuls `Array.isArray` et l'égalité des longueurs étaient
vérifiés ; les **éléments** de `navSeq` ne l'étaient pas. Or `navSeq[i]` fabrique la clé de cochage
écrite dans `data-ck`, et le régime de `nav` est « anchored » — donc appliqué **en direct, sans
rechargement**, sur l'écran de chacun, **dans la liste d'étapes elle-même**. C'est du code que
j'avais écrit trois versions plus tôt.

### Ce que la CSP faisait, et ce qu'elle ne faisait pas
La CSP porte les hashs SHA-256 des scripts inline : sur un navigateur à jour, `'unsafe-inline'` est
ignoré et un `onerror=` injecté **ne s'exécute pas**. Mais `style-src 'unsafe-inline'` est accordé,
lui — du balisage et du CSS arbitraires **dans la colonne d'action d'une réanimation** (masquer une
étape, en superposer une fausse avec une autre dose) suffisent à qualifier le défaut. On ne s'abrite
donc pas derrière la CSP : elle est le second rempart, pas le premier.

### Trois couches, et chacune vérifiée SEULE
1. **Assainir à l'entrée.** Le pli passe désormais par les mêmes fonctions que la peinture, cas par
   cas : identifiants par `safeId`, horodatages par une conversion numérique explicite, références
   par `tkRefNorm`. Les valeurs fautives ne sont pas **rejetées** mais **ramenées** à quelque chose
   d'inoffensif — un évènement perdu en pleine réanimation serait pire qu'un identifiant régénéré.
2. **Borner les formes.** Une clé de cochage vaut `visite:bloc:index` et rien d'autre — un jeu de
   caractères fermé la rend sûre **comme index d'objet** (règle 6, `__proto__` compris) **et comme
   valeur d'attribut**, d'un seul geste. `shareNavNorm` est la barrière **unique** du couple
   `nav`/`navSeq`, partagée par le pli et l'application ancrée.
3. **Échapper à la sortie.** Sept interpolations d'attribut reçoivent `esc()`. Un attribut
   s'échappe même quand l'entrée est assainie : les deux barrières couvrent des chemins différents.

**Les deux couches ont été éprouvées indépendamment** : en retirant l'assainissement d'entrée,
l'échappement de sortie bloque encore l'injection ; en retirant l'échappement, l'assainissement la
bloque aussi. C'est ce qui distingue une défense en profondeur d'un empilement de précautions.

### Vérification
Dix contrôles permanents dans `audit-partage.mjs` (242/242 sur les deux moteurs), **vérifiés
capables d'échouer** : les défauts réintroduits à l'identique en font tomber trois, fichier restauré
à l'octet. Ils mesurent la **sortie de balise**, jamais l'exécution — c'est la propriété qui compte,
l'exécution n'en est qu'une conséquence parmi d'autres. 738 tests × 2 moteurs, 13 harnais verts,
301 contrôles d'accessibilité, 94/94 doctrine. **Rien à rejouer côté serveur** — mais le serveur ne
valide toujours que le **type** et la **taille** d'un payload, jamais ses clés : c'est le client qui
doit se défendre, et c'est désormais le cas aux deux entrées.

## [4.53.0] — 2026-07-28
### Le partage survivait à la session qu'il reflétait — et la cadence supposait qu'un soin fait du bruit

Trois signalements d'usage, dont un qui n'a été trouvé qu'en cherchant à répondre à une question
sur la fréquence de rafraîchissement.

### Terminer la session ne coupait pas le partage
Signalé : *« la fenêtre hôte affiche toujours partage en cours »*. Vérifié — `endSession` ne touchait
pas au partage. Celui-ci **survivait à la session qu'il reflétait** : la fenêtre continuait
d'annoncer un partage vivant, l'invité sondait un miroir que plus rien n'alimentait, et le code
d'appariement restait valide jusqu'à son terme. Un partage sans session n'a pas d'objet.

L'arrêt est **annoncé** au serveur mais jamais **attendu** (règle 12) : fermer sa session ne doit
pas dépendre du réseau. Si l'annonce échoue, la ligne expire et sera purgée — c'est exactement à
cela que sert un relais transitoire. Cinq contrôles, **vérifiés capables d'échouer** (le correctif
retiré en fait tomber quatre, fichier restauré à l'octet).

### L'inactivité du support n'est pas l'inactivité du soin
En répondant à la question *« à quelle fréquence, sans websocket ? »*, la mesure a montré un trou.
La cadence se dégrade avec l'inactivité : 2 s dans les trente secondes d'un geste, 5 s ensuite,
**10 s au-delà de deux minutes**. Or pendant un cycle de compressions de deux minutes, **personne ne
touche l'écran, des deux côtés** — et le premier geste à la fin du cycle, c'est-à-dire au moment
précis où le rythme se réévalue, pouvait mettre jusqu'à 10 s à apparaître chez l'autre.

Plancher de 5 s tant qu'une crise est à l'écran. Le surcoût est de six requêtes vides par minute ;
le coût inverse était un miroir qui retarde au pire instant. `crisisOnScreen` sert de prédicat —
le même que le quai et la mise en attente des banderoles, pas un second critère qui divergerait.

Latences réelles, calculées sur les constantes du fichier (poussée débouncée à 250 ms, gigue ±20 %) :

| Situation | Période | Latence moyenne | Pire cas |
|---|---|---|---|
| Dans les 30 s d'un geste | 2 s | 1,25 s | 2,65 s |
| De 30 s à 2 min | 5 s | 2,75 s | 6,25 s |
| Au-delà de 2 min, **crise à l'écran** | 5 s | 2,75 s | 6,25 s |
| Au-delà de 2 min, hors crise | 10 s | 5,25 s | 12,25 s |

**Ce que la cadence ne retarde pas, et c'est l'essentiel** : les minuteurs voyagent avec une **ancre
absolue**, donc les deux appareils calculent la même valeur en continu **sans rien échanger** — un
cycle de deux minutes est exact des deux côtés même hors réseau, et le passage à « échu » ne dépend
d'aucun sondage.

### « Exporter » ne disait pas quoi
Signalé : dans le menu ⋯, *« exporter PDF et json, pas clair si on parle d'exporter la fiche ou une
session »*. Le doute portait précisément sur ce qui compte, dans une vue où une session tourne et où
« Compte-rendu » est à portée. Les libellés nomment désormais leur objet — « Exporter **l'aide**
(.json) », « Exporter **le protocole** en PDF » — et le sous-titre nomme l'autre chemin plutôt que
de laisser le chercher : pendant une session, « la session s'exporte par *Compte-rendu* ».

### Vérification
738 tests × 2 moteurs (+4), **232/232 contrôles partage** (+5, sur les deux moteurs), 13 harnais
verts, 301 contrôles d'accessibilité, 94/94 doctrine, `npm run check` vert. Un contrôle du harnais
qui visait un libellé exact (`Exporter (.json)`) a été élargi au groupe : il aurait échoué au moindre
renommage sans que rien ne soit cassé. **Rien à rejouer côté serveur.**

## [4.52.0] — 2026-07-28
### Le journal parle enfin des deux côtés — sans qu'un seul mot traverse le réseau

Lot 5 du chantier de partage. Un repère du journal voyageait comme `{identifiant, heure}` et rien
d'autre : chez l'invité, il s'affichait « Action 3 ». L'heure était juste — c'est ce qui compte
cliniquement — mais le mot manquait, et le compte rendu d'un même soin devenait difficile à
recouper.

### Une référence, jamais un mot
Un repère porte désormais une **référence**, et chaque appareil rend le libellé depuis **sa** copie
de la fiche. C'est ce qui tient la règle 15 sans condamner le journal au mutisme. Quatre sources,
cumulatives :

1. **La fiche elle-même** — minuteurs, compteurs, étapes, repères posologiques. Toute aide apporte
   son vocabulaire sans qu'on ait rien à déclarer, et il suit ses mises à jour.
2. **Un noyau universel livré** — ce qui se note dans toute intervention : renfort, régulation,
   départ de la base, arrivée sur place, bilan, transmission, relève, départ, arrivée à l'hôpital.
   **« Autre » n'y est pas, et ce n'est pas un oubli** : l'absence de référence *est* « autre », et
   une étiquette qui ne distingue rien n'apprend rien à qui relit.
3. **Le vocabulaire personnel, avec alias** — édité **à froid** dans la fenêtre Compte, synchronisé
   comme le thème. C'est là que vivent les abréviations qu'on se découvre à l'usage : « mru »
   trouve « Médecin régulateur ».
4. **Rien du tout**, et c'est le cas nominal. « Noter l'heure » reste **un tap** : l'heure est
   capturée, toujours, sans dépendre d'aucun vocabulaire. L'étiquetage est facultatif. Pire cas
   d'un vocabulaire incomplet : un repère non étiqueté côté partagé, et le mot exact **en local**
   chez celui qui l'a tapé.

**La résolution échoue proprement**, et c'est cette garantie qui autorise à faire voyager des
références : fiche d'une autre version, étape supprimée, étiquette effacée — le repère retombe sur
« Action n », **jamais sur un mot inventé**. Six contrôles l'encodent.

**On réordonne, on ne filtre jamais** — la règle des repères posologiques, appliquée telle quelle,
avec la même machinerie (troncature à partir de quatre caractères, table de synonymes). Un faux
positif coûte un rang ; un faux négatif coûte un mot au moment où on le cherche.

### Ce qui ne pouvait pas être une fenêtre
La règle 11 interdit les modales pendant un soin. Les propositions sont donc une rangée de chips
**sous** la ligne du journal — lequel vit en fin de rail, si bien que ce qui apparaît pousse vers le
bas et jamais vers le haut. Cibles 44 px, rien sous deux caractères saisis (tout ressemble à tout),
quatre propositions au plus.

Tant qu'aucune proposition n'est choisie, **le texte tapé reste strictement local** : mesuré, il
n'entre pas dans ce qui est émis. Choisir pose la référence et efface le libellé manuel — le mot
devient dérivé, donc identique sur les deux écrans.

**Une asymétrie est dite plutôt que tue** : une étiquette *personnelle* se résout sur les appareils
du même compte, pas chez un collègue qui ne l'a pas. Pendant un partage, elle est donc marquée
« · vous seul ». La taire aurait laissé croire à un mot partagé.

### La règle 15 vaut aussi à la réception
La réception d'un repère distant lisait un `label` venu du réseau. Inoffensif entre deux clients de
cette version — aucun émetteur n'en met — mais c'était une **porte** : un client modifié aurait
affiché un mot arbitraire sur l'écran d'en face. La lecture est supprimée ; le libellé se dérive de
la référence, et de rien d'autre. Le contrôle du harnais qui vérifiait l'inverse — il **encodait le
trou** — a été retourné : il pousse maintenant un `label` hostile et vérifie qu'il n'apparaît nulle
part.

### Un défaut d'accessibilité sur iOS, trouvé en jouant le harnais sur le bon moteur
Le `<select>` de rôle de l'écran d'entrée mesurait **23 px de haut sur WebKit** contre 44 sur Blink
— sous le plancher de cible, sur le seul écran qu'un invité sans compte verra jamais, et sur la
cible principale déclarée du projet. Invisible tant que le harnais d'accessibilité ne tournait que
sur Chromium : c'est la leçon de la v4.45.0, redite. Hauteur explicite et chevron dessiné
(`appearance:none` — sans lui, imposer une hauteur à un select natif iOS ne déplace pas son texte).

### Vérification
734 tests × 2 moteurs (+28), **227/227 contrôles partage** (+13, sur les deux moteurs), 13 harnais
verts, 301 contrôles d'accessibilité **sur les deux moteurs**, 94/94 doctrine, `npm run check` vert.
Le contrôle « le texte tapé n'est pas émis » est vérifié **capable d'échouer** (le libellé remis
dans l'instantané le fait tomber, fichier restauré à l'octet). Le commentaire de modèle du fichier,
qui décrivait un repère par trois clés depuis l'origine, en décrit désormais les huit — et dit
lesquelles voyagent. **Rien à rejouer côté serveur.**

## [4.51.0] — 2026-07-27
### Le miroir se figeait au premier « Continuer » de l'hôte

Annoncé en fin de v4.50.0, corrigé ici. Deux défauts, et le second n'était visible que parce que le
premier le masquait.

### La file était remplie et jamais vidée
`SHARE_APPLY` distingue trois régimes et les motive : `live` (chirurgie pure dans la checklist),
`anchored` (« reconstruit le journal, **donc** ancré et annoncé »), `deferred` (attend un geste
local). **Une seule ligne rangeait `anchored` et `deferred` dans la même file** — laquelle n'était
drainée nulle part.

Conséquence, mesurée : après une navigation distante, `Runtime.nav` ne contenait pas le bloc cible ;
au grep, aucun site de drainage. **L'invité voyait les coches du bloc courant, et plus rien
ensuite** — le contraire d'un miroir, et la fonction même pour laquelle le partage existe. C'est la
quatrième moitié de chemin de ce chantier, après `canWrite()` sans appelant, l'annexe d'un détaché
que personne ne lisait, et `fold.exercise` sans émetteur.

Une navigation distante s'applique désormais **ancrée** : on mesure la position d'un repère, on
re-rend, on compense le résidu — dérive **0 px** mesurée. Et on ne défile **pas** vers la nouvelle
carte : le geste n'est pas le sien. C'est la différence exacte avec `ovAdvanceRender`, qui défile
parce que c'est l'utilisateur qui vient d'appuyer sur « Continuer ».

Deux pièges rencontrés, tous deux attrapés par la sonde et non par la relecture : `state.nav` est un
**alias** du tableau de `Runtime` — lui affecter un tableau neuf casse l'alias en silence, et
l'application se met à lire deux navigations différentes selon l'endroit ; et `Runtime.seq` doit
être relevé au maximum des numéros reçus, faute de quoi une visite locale ultérieure réutiliserait
un numéro déjà pris — **deux passages partageraient alors leurs clés de cochage**.

### Le mode lecteur inverse la règle, et il le dit
Sa clé d'étape est calculée **au clic** depuis `state.nav`, jamais depuis le DOM peint : une
navigation distante arrivant entre le `pointerdown` et le `click` ferait cocher **la mauvaise
étape**, et le compte rendu l'imprimerait comme réalisée. Tant que le lecteur est ouvert, une
navigation distante est donc **refusée** — et **annoncée sur place** : « Le soignant a avancé —
reprendre à sa position », registre INFORMATION, levée par un geste local. Ne pas suivre en silence
était le pire des deux mondes : l'autre a avancé, et celui qui lit à voix haute l'ignore.

### Un rechargement ne perd plus la session
Un onglet mobile meurt tout seul — iOS recycle les onglets en arrière-plan — et l'invité perdait sa
participation **sans retour** : rien n'était persisté, et son code d'appariement est consommé, donc
il ne pouvait pas rejoindre. C'était l'invariant « l'invité ne garde rien » appliqué au-delà de ce
qu'il protège.

Un **billet** est écrit dans le `sessionStorage` : l'identifiant du partage et le secret,
**aucune donnée clinique** — vérifié par un contrôle qui cherche le titre de la fiche dans le
billet. Sa portée est *cet onglet, cette navigation* : effacé à la fermeture, jamais partagé, hors
IndexedDB et hors `localStorage`. L'étanchéité est tenue là où elle compte — rien de **durable** sur
le téléphone d'un tiers. Il survit à `freeze` (le lien meurt, l'écran reste) et meurt avec `stop`
(l'écran est quitté) ; un serveur qui refuse l'efface plutôt que de le laisser traîner.

Côté serveur, `share_pull` renvoie la fiche **uniquement sur une reprise complète** (`p_since = 0`,
et jamais à l'hôte) : les sondages ordinaires passent toutes les deux à dix secondes et n'ont aucun
besoin d'un instantané de plusieurs dizaines de kilo-octets. Aucune donnée nouvelle ne sort — c'est
le même instantané, filtré par la même liste blanche, que la jointure avait déjà remis.

### Vérification
706 tests × 2 moteurs, **214/214 contrôles partage** (+22, sur les deux moteurs), 13 harnais verts,
9/9 QR, 301 contrôles d'accessibilité, 94/94 doctrine, `npm run check` vert. Les dix contrôles du
miroir ont été **vérifiés capables d'échouer** : le défaut réintroduit en fait tomber cinq, fichier
restauré à l'octet. Le registre RGPD (§ 3.1) et `AGENTS.md` sont mis à jour dans le même commit —
le billet est une exception à un invariant écrit, elle se documente là où l'invariant est écrit.

**`supabase/schema.sql` est à rejouer** (`share_pull` seul est modifié), puis `rls-tests.sql`.

## [4.50.0] — 2026-07-27
### La conformité écrite noir sur blanc — et le placard d'exercice qui ne traversait pas le partage

Lot 7 du chantier de partage : la documentation opposable. Traité **avant** les lots 5 et 6, et pas
par ordre de numéro — c'est le seul reliquat qui engage l'établissement. Trois signalements d'usage
sont corrigés au passage, et un défaut a été trouvé **en écrivant la documentation**, ce qui est
exactement à quoi elle sert.

### Le placard d'exercice ne traversait pas
`openSharedFiche` lisait `fold.exercise` — **et aucun émetteur ne l'a jamais posé**. Moitié de
chemin écrite, la ligne se lisant comme si elle marchait : troisième occurrence dans ce chantier,
après `canWrite()` sans appelant et l'annexe d'un détaché que personne ne lisait.

Mesuré, témoin à l'appui : hôte en répétition = bandeau hachuré, en-tête hachuré, pilule
« ▲ Exercice », chrono « ▲ Exercice » ; **invité = « ■ Crise » et « ● Session »**. Un renfort qui
rejoint une répétition en la croyant réelle est précisément ce que le placard TRAINING existe pour
empêcher — l'annonciation **est** la raison d'être du mode exercice (v4.27.0), le reste étant
identique par construction.

Le drapeau voyage désormais sur `session_start`, et ce véhicule n'est pas un pis-aller : le drapeau
est posé par `startExercise`, qui passe par `freshRuntime` — il ne peut donc changer **qu'avec** le
démarrage. Aucun genre nouveau, donc **aucun schéma à rejouer** ; et `session_start` étant déjà
réservé au lead, un scribe ne peut pas déguiser une session réelle en répétition. Cinq tests, dont
**trois tombent** quand on réintroduit le défaut (fichier restauré à l'octet). « Quitter
l'exercice… » disparaît chez l'invité : le bouton appellerait `quitExercise` sur **son** Runtime
sans rien changer chez l'hôte — un contrôle qui ment sur sa portée.

### Trois signalements d'usage
**La fenêtre d'entrée n'avait pas de sortie.** Elle a été conçue comme le *remplacement* de
l'application sur un appareil vierge, où il n'y a rien derrière et où une croix ne mènerait nulle
part. Mais on y arrive aussi **depuis l'accueil**, en tapant le code dans la recherche : une
application tourne alors derrière, et un code mal recopié enfermait l'utilisateur. Croix, Échap et
retour système — les trois par le même chemin, comme le veut la doctrine des fenêtres —, affichés
**uniquement** s'il y a un « derrière ».

**L'hôte dictait un code déjà mort.** `share_join` met `code_hash` et `join_open_until` à NULL : la
porte se referme **derrière celui qui entre**, avant l'échéance des 120 s. L'hôte, lui, gardait sa
copie et affichait le code *avec son décompte* — « ouvert encore 97 s » sur une porte fermée. C'est
la donnée périmée présentée comme vivante, danger n°2 du palmarès ECRI 2015, que la doctrine du quai
nomme déjà pour les minuteurs. Corrigé **sans toucher au schéma** : une jointure est la seule chose
qui consomme un code, donc l'apparition d'un participant *est* l'observation. Le code et son QR
disparaissent, la fenêtre dit « **Untel a rejoint — le code a servi** », et « Nouveau code » devient
l'action évidente. Bénéfice second, non cherché : l'hôte obtient enfin l'**accusé de réception**
d'appariement que l'échange en trois temps suppose (AC 61-115).

**Le mode lecteur ne suivait pas.** Il vit hors de `main`, que `sharePaintLive` est seul à peindre :
mesuré, coche distante appliquée à l'état et peinte dans le journal (témoin `done` posé), **lecteur
inchangé** — le binôme qui lit à voix haute annonçait « suivant : … » sur une étape déjà faite.
Il se repeint désormais **à position conservée** : `_rmSync` remet le curseur à zéro et ferait
sauter le lecteur au premier item non coché, ce qui serait un mouvement autonome sous ses yeux.
La première sonde écrite pour ce défaut mesurait le **chrono** du lecteur et le voyait donc changer
à chaque seconde : elle a été refaite avant toute conclusion.

### La conformité, sourcée ligne à ligne
`docs/deploiement-et-conformite.md` affirmait encore « **Sessions : locales à l'appareil** » — faux
depuis la v4.46.0 — et sous-évaluait la conservation. Nouveau **§ 3.1** qui énumère, avec le SQL en
regard : les **14 champs** de la liste blanche serveur (et ce qu'elle retire — images, documents,
et `localInfo`, pré-rempli des téléphones de renfort et de régulation) ; ce qu'un geste transmet
(une référence et une heure — le libellé d'un repère **reste sur l'appareil qui l'a écrit**) ; ce
qu'est l'identité d'un participant (un identifiant opaque tiré par le serveur, un rôle choisi dans
une liste fermée de neuf intitulés) ; et les durées **mesurées** : fenêtre d'admission 120 s, partage
3 h par défaut borné à 12 h, purge 30 min après expiration, en cascade, déclenchée **en tête de
chaque appel** faute de tâche planifiée sur un hébergement statique.

Deux précisions qu'une lecture rapide du schéma ne donne pas, et qu'un DPO doit avoir : le contrôle
d'accès des invités **ne repose pas sur la RLS** mais sur la possession d'un secret (trois fonctions
`security definer`, seule surface non authentifiée de l'installation) ; et « couper un participant »
retire **l'écriture**, pas la lecture — le serveur lui répond `revoked` et c'est **son application**
qui gèle son écran. La formulation affichée à l'hôte est exacte sur ce point et ne doit pas être
élargie ; le durcissement serveur est identifié.

Le **§ 2** passe le partage à la grille MDCG 2019-11 : il ne calcule rien, il **recopie** un état
d'un écran à l'autre — qualification « communiquer ». L'argument contraire est écrit **et** réfuté
(il prouve trop : il vaudrait pour un tableau blanc), et la ligne à ne pas franchir est nommée — le
jour où le partage **déduirait** quelque chose de l'état partagé, la qualification serait à rouvrir.
Précaution de vocabulaire conservée : ne jamais présenter le partage comme un outil de *supervision*.

`AGENTS.md` reçoit une section « partage de session » complète et une **règle 15** — miroir additif,
jamais une dépendance ; aucun texte libre sur le réseau. Ses compteurs périmés sont corrigés :
onze → **treize** harnais, ~12 250 → **~14 400** lignes, 20 → **21** fenêtres modales, 22 → **25**
surfaces auditées en accessibilité.

### Ce qui reste, et qui est dit ici plutôt que découvert plus tard
La file `_defer` est **remplie et jamais vidée** : tout ce qui est classé `anchored` (`nav`,
`flow_end`, `cx`) ou `deferred` (`verify`, `gap`) n'atteint jamais l'écran de l'invité — **le miroir
se fige dès que l'hôte change de bloc**. Mesuré (`Runtime.nav` ne contient pas le bloc cible après
une navigation distante) et confirmé au grep (aucun site de drainage). Le commentaire de
`SHARE_APPLY` décrit pourtant le bon comportement. Et un invité qui recharge sa page **perd tout** :
rien n'est persisté, le code est consommé, il ne peut pas revenir. Les deux sont la prochaine
version.

706 tests × 2 moteurs (+5), 13 harnais verts, **192/192 contrôles partage** (+8, sur les deux
moteurs), 9/9 QR, 301 contrôles d'accessibilité, 94/94 doctrine, `npm run check` vert. **Rien à
rejouer côté serveur.**

## [4.49.0] — 2026-07-27
### Le repli hors dispositif, le bridage du scribe, et le filtre de contenu qui n'existait qu'en JavaScript

Dernière version du chantier de partage. Elle apporte les deux fonctions qui manquaient — poursuivre
seul quand le lien tombe, et brider le scribe sans rien lui masquer — et referme côté SERVEUR ce que
seul le client protégeait.

### « Continuer seul » : la trace remonte, l'état non
Le serveur savait tout faire depuis la v4.46.0 — colonne `detached_at`, genre `detach` autorisé,
règle « un lot qui porte un detach ne porte que lui », assertions RLS — mais **aucun code client ne
l'appelait**, et l'annexe qu'un détaché peut remonter n'était lue par personne. Quatre murs, tous
tombés :

**Au détachement, la file était JETÉE.** Au moment précis où la bifurcation devient officielle, on
détruisait la seule chose qui devait encore remonter. Elle est désormais **convertie** : chaque
geste en attente devient un `offline_mark`, qui rejoint le journal de l'hôte en annexe. Un détaché
ne peut plus écrire d'ÉTAT — ses coches porteraient sur des passages que l'hôte a quittés — mais il
peut écrire des repères horodatés : une heure reste une heure.

**Un détaché cessait de sonder.** Ses annexes n'auraient donc jamais atteint l'hôte. Un cycle lent
reste armé tant que sa file n'est pas vide.

**Chez l'hôte, l'annexe entre au journal et NULLE PART ailleurs**, à sa place chronologique, inerte
(ni champ ni bouton — on ne corrige pas le relevé d'un autre), avec la mention « rapporté — poursuit
seul ». L'état ne fusionne jamais : après la bifurcation, les numéros de visite sont mintés
indépendamment des deux côtés, si bien que « la visite 6 » de l'un et celle de l'autre désignent
deux passages différents. Ce n'est pas un conflit arbitrable, c'est une collision d'espace de noms —
fusionner produirait un résultat non pas discutable mais **faux, et plausible**.

### Le scribe ajoute, il ne défait pas
Forme canonique du travail à deux (AC 120-71B §5.2.2.1), pas un compromis. Ouvert au scribe : cocher,
constater, signaler un écart, **incrémenter** un compteur, **armer** un minuteur, poser et annuler un
repère. Fermé : décocher, avancer, terminer, choisir une branche, sauter à un bloc, **arrêter** ou
remettre à zéro. La distinction n'est pas arbitraire — ajouter est additif et réversible par le
journal, remettre à zéro détruit un décompte que personne ne peut restituer.

**Jamais par masquage** : masquer ferait sauter le contenu clinique de 46 px (mesuré), et sur
évènement DISTANT si le rôle change — sous le doigt de quelqu'un qui n'a rien demandé. La boîte
reste, la géométrie est identique refus ou non (mesuré ≤ 1 px), et le refus s'annonce sur `#srLive`,
seul canal admis pendant un soin.

**Une seule liste de verbes**, consommée par le CSS et par une garde déléguée en phase de capture ;
un contrôle du harnais lit la liste **depuis le script** et vérifie que chaque élément rendu porte
l'apparence désactivée — c'est la faille de la v4.42.0 prise à la racine. Deux gestes dépendent de
leur DIRECTION et ne peuvent pas être bridés en CSS : le cochage (`data-ck` porte cocher *et*
décocher) et le minuteur (armer *ou* arrêter) ; ils sont gardés dans leurs handlers, et pour le
cochage par un prédicat **unique** appelé aux deux copies du cœur.

### Le serveur ne se fiait qu'au client
**La liste blanche des champs de fiche n'existait qu'en JavaScript.** Un appel REST direct la
traversait : `images` (jusqu'à 24 Mo de base64), `localInfo` (les téléphones de renfort et de
régulation), la liste des documents, `ownerId`, `libraryId` — tout pouvait partir. Le schéma avait
pourtant déjà tiré cette leçon pour la TAILLE (« le plafond vaut contre le client ») sans jamais
l'appliquer au CONTENU. C'est une liste **blanche**, pas noire : on ne garde que les quatorze champs
autorisés, une liste noire oubliant ce qu'on ajoutera demain. Les images de BLOC sont retirées
séparément, elles vivent à l'intérieur de `blocks`.

**`is_approved()` traitait un JWT anonyme comme un compte approuvé.** Un tel jeton porte un
`auth.uid()` non nul et n'a aucune ligne dans `user_status` : le `coalesce` retombait sur
`'approved'` — y compris pour ouvrir un partage, c'est-à-dire faire sortir du contenu clinique de
l'instance. La porte n'était fermée que parce que personne n'avait activé l'option au tableau de
bord ; elle l'est maintenant par le schéma.

**`share_admit` ouvrait deux boucles infinies.** Il ne vérifiait ni l'expiration ni le quota : sur un
partage expiré ou plein, il rendait un code NEUF que l'hôte dictait et que `share_join` refusait
aussitôt, sans que personne, des deux côtés, ne puisse comprendre — et il écrasait au passage un code
peut-être encore vivant. Le motif est désormais détaillé, parce que l'appelant est le propriétaire
authentifié : l'argument d'oracle ne vaut que face à un anonyme, et le schéma le promettait sans
l'appliquer nulle part.

S'ajoutent un **plafond de cinq partages vivants par propriétaire** (il n'en existait aucun, alors
qu'un compte coûte une adresse jetable), le bornage de `session_id` — seul champ texte libre non
contraint —, les **octets des partages dans le total de stockage** et leur affichage au tableau de
bord (le serveur les calculait, l'écran ne les montrait pas : l'exploitant était aveugle au seul
poste que le partage fait croître), et le genre **`session_start`** : l'heure du soin voyage,
réservée à celui qui conduit. Un renfort arrivé à 14 h 12 sur une réanimation débutée à 13 h 55 ne
date plus le début du soin à son arrivée.

### Quatre signalements d'usage, et ce qu'ils étaient vraiment
**Le code du partage ne grandissait pas.** Il a été agrandi trois fois sans le moindre effet à
l'écran : `.ai-card p` pèse (0,1,1) — une classe ET un type — et l'emportait sur `.sh-code` (0,1,0)
en le ramenant à 13 px, **quel que soit l'ordre de déclaration**. C'est le 7ᵉ incident de cascade du
projet et le premier par SPÉCIFICITÉ ; les six précédents tenaient à l'ordre. Toute la typographie
des deux fenêtres passe par des sélecteurs à `#id`, et un contrôle mesure désormais la taille
**rendue**, jamais la valeur écrite. Le code fait 40 px (34 sous 360).

**Le QR portait le code seul.** Une « correction » de la veille faisait retomber `localhost` sur le
code, ce qui privait de la fonctionnalité au moment même où on l'essaie : toute origine http(s)
donne à nouveau l'URL complète, et le **lien entier est écrit en clair** sous le QR, sélectionnable
d'un appui — c'est lui qu'on dicte ou qu'on envoie quand la caméra ne sert pas. Le harnais QR, lui,
ne décodait que la MATRICE : il capture maintenant l'**image réellement peinte** et la donne au
décodeur d'Apple, à quatre configurations dont le thème sombre.

**La confirmation d'arrêt s'affichait derrière la fenêtre** (z-index 55 contre 94) : invisible, avec
le focus piégé dedans. Portée à 95.

**Les deux fenêtres du partage étaient les plus étroites de l'application** (420 et 460 px) : elles
prennent `dlg-480`, la largeur standard partagée par cinq autres. Et sous 780 px, où l'app transforme
toute fenêtre en feuille pleine largeur, leur contenu — majoritairement centré — courait d'un bord à
l'autre : mesuré, carte 744 × 1133 px pour 643 px de contenu. Le CORPS est borné à 460 px ; le titre
et le ✕, eux, restent au bord de la feuille, **identiques au pixel à une fenêtre existante** (mesuré
contre `#catModal` à 390, 744 et 1280 px) — fermer une fenêtre est le geste le plus appris de
l'application, le déplacer pour une seule d'entre elles était une faute.

### Rejoindre se tape dans la recherche
La rangée était dans le dialogue « Créer » : rejoindre n'ajoute rien à la bibliothèque, et quelqu'un
à qui l'on dicte un code n'irait pas le chercher sous « + ». Une ligne permanente en tête d'accueil a
été essayée puis écartée — 44 px d'attention à chaque ouverture pour un geste rare, alors que la
doctrine ECAM réserve le permanent à ce qui sert la conduite en cours. **Le code se tape dans le
champ de recherche** : huit caractères d'un alphabet fermé sont reconnaissables sans ambiguïté, la
ligne s'AJOUTE aux résultats sans les remplacer, et l'accueil au repos est **identique au pixel**
(mesuré). Registre INFORMATION, bouton rempli : à l'instant où elle paraît, elle est la seule action
de l'écran.

### Vérification
701 tests × 2 moteurs (+4), 13 harnais verts, **184/184 contrôles partage** (+41, sur les deux
moteurs), 9/9 QR, 301 contrôles d'accessibilité, 94/94 doctrine, `npm run check` vert. Quatre
assertions RLS nouvelles (§14.11 à 14.14) couvrent la liste blanche serveur, le plafond de partages,
les deux refus de `share_admit` et la réserve de `session_start`. `supabase/schema.sql` et
`rls-tests.sql` ont été rejoués sur l'instance avec succès.

Trois contrôles écrits pendant ce chantier ont dû être **corrigés parce qu'ils mesuraient le
mécanisme et non la propriété** : « le mode d'application vaut `none` » là où il fallait vérifier que
l'annexe ne touche pas l'état, « `started` vaut faux » là où il fallait vérifier qu'aucun dossier
n'est créé, et « pas de lien en local » qui encodait une règle infirmée. C'est la même erreur que la
taille du code, sous une autre forme : vérifier ce qu'on a écrit plutôt que ce que ça produit.

## [4.48.0] — 2026-07-27
### Le partage fonctionne enfin de bout en bout — et le miroir de l'invité était en lecture seule

Cette version rend le partage RÉEL : l'hôte peut l'ouvrir, montrer un code, voir qui a rejoint,
couper quelqu'un, arrêter. Et surtout, les gestes voyagent — ce qui n'était pas le cas.

### Le défaut central, trouvé par contre-expertise dans le code de la version précédente
**Les coches de l'invité ne quittaient jamais son téléphone.** L'émission s'accroche à
`persistLive`, qui sort immédiatement si la session locale n'a pas démarré — or l'invité avait
`started=false` par construction, et **une trentaine de sites de mutation sont eux-mêmes gardés par
`if(Runtime.started)`**. Le miroir était donc en lecture seule, silencieusement. C'est mot pour mot
le pire mode de défaillance nommé au plan de ce chantier : *cocher dans le vide en croyant
contribuer à une réanimation en cours*.

Le correctif inverse la logique. Sa session EST vive — c'est celle de l'hôte, il la suit et il y
contribue — donc `started` vaut vrai chez lui. Ce qui lui est refusé n'est pas la session, c'est
l'**enregistrement**, et ce refus vit désormais là où il a un sens, dans `persistLive` : aucune
écriture dans son stockage, aucune entrée dans son historique. Le contrôle censé couvrir cela
mesurait le MÉCANISME (`started === false`) au lieu de la PROPRIÉTÉ ; il mesure maintenant
l'étanchéité réelle — zéro session archivée, zéro session vive, aucun dossier — **et** que ses
gestes partent bien sur le fil.

Trois défauts de la même famille, tous dans du code écrit la veille : `canWrite()` — le prédicat qui
doit retirer l'écriture à un invité coupé ou périmé — **n'avait aucun appelant**, alors que le
commentaire attenant promettait « un invité périmé ou coupé PERD VISIBLEMENT l'écriture » ; le
compte de participants du quai filtrait sur `revoked_at` quand le serveur envoie `revoked`, si bien
que l'hôte aurait lu « ⇄ 2 » avec un seul participant présent ; et l'acteur d'un repère se perdait à
la peinture, rendant tout compte rendu inattribuable.

### Émission par différence — un seul point d'accroche
Le recensement avait trouvé **soixante verbes de mutation** (41 attributs `data-*` et 19 contrôles à
`id`). Les instrumenter un par un garantissait l'oubli, et surtout l'oubli SILENCIEUX de toute
mutation ajoutée plus tard. On DIFFE donc l'état, en un seul endroit : ce qui est couvert par
l'enregistrement local l'est mécaniquement par le partage. `shareSnap` et `shareDiff` sont PURS,
donc testables sans navigateur, sans réseau et sans horloge — et le test qui compte est
l'**aller-retour** : émettre puis plier redonne l'état de départ (coches, compteurs, minuteurs,
navigation, repères, annulations, trace do-verify). L'ouverture d'un partage **verse l'état courant
dans le fil** : l'instantané transmis est la FICHE, jamais la session, donc un partage ouvert après
vingt coches aurait sinon laissé l'invité devant une fiche vierge, à jour et fausse.

### La fenêtre d'appariement de l'hôte
Ordre imposé par la mesure, pas par l'esthétique : titre de l'aide et **code** en haut (ce qui se
dicte à voix haute), QR ensuite et plafonné, participants, arrêt en pied. Elle **ne verrouille pas
le fond** (`sheet-live`) : toute `.ai-modal` fige le défilement derrière elle au pointeur grossier,
et celle-ci reste ouverte pendant toute la fenêtre d'admission — la checklist de crise de l'hôte
serait devenue indéfilable au moment où elle sert.

**Couper quelqu'un n'est jamais peint de façon optimiste** : la rangée affiche « coupure… » et
n'accepte « coupé » que lorsque le sondage le rapporte ; le harnais mesure les deux moments, y
compris le RETOUR EN ARRIÈRE quand la requête échoue — un bouton qui laisserait « coupé » affiché
après un échec dirait à l'hôte qu'il a retiré un accès qu'il n'a pas retiré. Et « Arrêter le
partage » ramène `expires_at` à maintenant : le code s'aligne sur la promesse de purge faite à
l'invité, au lieu qu'on affaiblisse la promesse.

### Quatre défauts signalés à l'usage, et ce qu'ils étaient vraiment
**Le QR n'était pas corrompu : il contenait une adresse injoignable.** Il encodait
`location.origin + …` — servi depuis un poste de développement, cela donne une adresse LOCALE, que
l'iPhone décode et ne peut pas ouvrir : « aucune donnée utilisable trouvée ». Désormais, si
l'adresse n'est pas joignable depuis un autre appareil (fichier local, origine nulle, `localhost`),
c'est le **code seul** qui est encodé — le téléphone l'affiche comme texte — et la fenêtre le dit.
Le harnais QR, lui, ne décodait que la MATRICE : il était **aveugle à tout ce qui se passe entre
l'encodeur et l'appareil photo** (génération du SVG, variables CSS, `shape-rendering`, taille en
`vw`, rendu sous-pixel). Il capture maintenant l'IMAGE RÉELLEMENT PEINTE et la donne au décodeur
d'Apple, à quatre configurations dont le thème sombre.

**La confirmation d'arrêt s'affichait DERRIÈRE la fenêtre** : `#confirmModal` héritait du z-index 55
des fenêtres ordinaires alors que l'appariement est à 94 — dialogue invisible, focus piégé dedans.
Porté à 95, au-dessus des deux fenêtres hautes et sous le flash d'alarme.

**L'écran d'entrée ne suivait pas la grammaire de l'app** : il n'utilisait pas `.ai-card`, donc ni
son `margin:auto` (le centrage vertical de toutes les fenêtres), ni son échelle typographique — à
760 px la carte restait collée en haut, au-dessus de 450 px de vide. Et en la recalant, le **6ᵉ
piège de cascade du projet** : `.join-card` et `.ai-card` ont la même spécificité, la
`max-width:720px` déclarée plus bas l'emportait et la carte s'étalait sur 700 px. Sélecteurs par
`#id` pour les deux fenêtres, comme la règle l'impose pour toute géométrie.

**L'écran de saisie du code était introuvable sans QR.** Il est joignable depuis le dialogue
« Créer », sous un filet et formulé comme une question (« Un collègue partage sa session ? — ⇄
Entrer un code ») : c'est le seul point d'entrée atteignable à TOUTES les largeurs, l'accueil n'ayant
ni menu ⋯ ni barre latérale sous 780 px. Et l'**adresse de jointure est écrite en clair sous le QR**
— c'est elle qu'on dicte quand le scan ne peut pas servir.

Le code passe à **40 px** (34 sous 360 px), le champ de saisie de l'invité à 26 px. Cela a fait
tomber un contrôle, et c'est lui qui avait tort : il exigeait « Arrêter le partage » visible sans
défiler à toutes les largeurs, alors qu'à 320×568 la carte fait 734 px — aucune mise en page
honnête ne tient dans 568. L'objection d'origine disait autre chose : ce bouton ne doit jamais se
retrouver DANS une liste qui grandit, et doit rester atteignable. C'est ce qui est mesuré.

### Le miroir de l'invité
Le bouton « Confirmé — démarrer la session » — contrôle plein, le plus visible de l'écran — était
rendu chez lui alors qu'il ne démarre rien : retiré. L'entrée se fait au BOUT du journal et non en
tête de fiche (mesuré : la première étape cochable tombait à y=827 pour un écran de 844, et y=910
pour 568 — hors champ aux deux largeurs) ; le titre reste lisible par le relais d'en-tête, comme
pour tout utilisateur qui défile. Une annonce sans pixel (`#srLive`, seul canal admis pendant un
soin) dit ce qu'il suit.

**Et il a enfin une porte de sortie.** `Share.stop()` n'avait AUCUN appelant : le seul geste
disponible changeait la vue en laissant le mode et le sondage armés, sans chemin de retour. Le menu
⋯ de l'invité porte « Quitter le partage… », et le départ est SILENCIEUX côté serveur —
`Share.stop()`, jamais `emit('detach')` : un `detach` DATE un « je poursuis seul » dans le compte
rendu de l'hôte, or quelqu'un qui ferme son écran n'a rien affirmé de tel. Le même menu perd les
rangées qui, chez lui, étaient fausses ou muettes (exercice, recommencer, modifier, versions,
dupliquer, exports).

**Une incohérence d'étanchéité fermée au passage** : `beforeprint` n'était gardé que par la vue. Un
invité qui faisait Partager → Imprimer obtenait la fiche ENTIÈRE, mise en page pour le papier —
pendant qu'on lui refusait l'export du compte rendu au nom de cette même étanchéité.

### La rangée « Partager la session » n'est plus jamais grisée
La contrainte reste réelle (sans session démarrée, la première action de l'invité déclencherait un
re-rendu complet sous le doigt de l'hôte), mais la faire porter par une rangée MORTE obligeait à
deviner l'ordre des gestes. Elle propose maintenant de démarrer, par un dialogue qui dit ce que cela
engage — chrono, minuteurs, journal, entrée à l'historique : une session ne commence pas par
surprise au détour d'un menu.

### Vérification
691 tests × 2 moteurs (+2), 13 harnais verts, **124/124 contrôles partage** (+69, sur les deux
moteurs), **9/9 QR** (dont 4 sur l'image peinte), 301 contrôles d'accessibilité, 94/94 doctrine,
`npm run check` vert. Les nouveaux contrôles ont chacun été vérifiés capables d'échouer.
`supabase/schema.sql` est INCHANGÉ dans cette version : rien à rejouer.

## [4.47.0] — 2026-07-27
### Le transport du partage, la moitié invité — et ce qu'une contre-expertise a trouvé dans le code existant

Suite du chantier ouvert en v4.46.0. Un collègue peut désormais **rejoindre** une session et la
suivre en miroir ; l'autre moitié — l'écran depuis lequel on ouvre le partage — reste à écrire, si
bien que **rien n'est encore actionnable de bout en bout**. Ce qui l'est, en revanche, ce sont les
défauts que la préparation a mis au jour dans du code qui existait déjà, et qui n'attendaient pas
le partage pour nuire.

### Trois mécanismes existants que le partage rendait dangereux
Deux relectures adverses ont mesuré les surfaces prévues dans le code réel, avant qu'aucune ne soit
écrite. Elles ont invalidé l'ordre de travail : trois corrections devaient précéder toute nouvelle
interface, faute de quoi elle se serait appuyée sur un budget de place faux et sur un indicateur
qui ment.

**Le quai sacrifiait l'ALARME pour garder un chevron.** Quand la place manquait, la boucle
d'ajustement retirait les segments un à un et n'essayait « sans chevron » qu'une fois arrivée à
ZÉRO segment : elle sacrifiait donc le segment ambre du minuteur **échu** — la seule persistance de
l'alarme une fois le bip passé, dans une zone qui ne quitte jamais l'écran — pour garder un glyphe
`aria-hidden` que son propre commentaire qualifiait de « purement décoratif ». Et à court de
solutions, elle **réécrivait un état qu'elle venait de mesurer comme débordant**. Ordre inversé (le
décoratif tombe d'abord, à chaque palier) et plancher explicite.

**La cause de la pénurie était ailleurs : l'ellipse des intitulés n'avait jamais fonctionné.**
`.seg-l` déclare `text-overflow:ellipsis` depuis l'origine et un commentaire l'attribuait à un
« min-width:0 du segment » — qui n'existait pas. Sans plancher explicite, `min-width:auto`
dimensionne le segment sur son contenu le plus large ; en colonne, la règle flex qui annule le
minimum automatique porte sur la HAUTEUR, jamais sur cette largeur. Mesuré : un intitulé de
21 caractères portait le segment à **346 px pour 320 de large**, la boucle voyait un débordement et
expulsait le segment. Plancher chiffré à **112 px** = la valeur réelle la plus large
(« 999:59:59 », 95 px) plus les rembourrages : en dessous, l'intitulé s'ellipse — un MOT se
tronque, c'est admis ; au-dessus, la valeur ne peut jamais être rognée — un NOMBRE ne se tronque
pas — et si la place manque vraiment, le débordement est RÉEL, donc la boucle retire un segment et
le « +n » l'annonce. Le quai ne peut plus déborder en silence à aucune largeur servie.

**Le mot « échu » n'existait pas dans le quai**, alors qu'`AGENTS.md` l'affirmait : `segOf`
n'écrivait que l'intitulé et la valeur, si bien qu'un minuteur échu se distinguait d'un minuteur
nominal par la SEULE teinte — dans la zone la plus critique de l'application. Il ne pouvait pas
être ajouté en clair (l'ellipse l'aurait mangé le premier, et le segment aurait grossi jusqu'à se
faire expulser) : patron déjà retenu pour les étapes signalées — **glyphe `△` en PRÉFIXE**, qui
survit à l'ellipse, plus l'étiquette au lecteur d'écran. Piège trouvé au passage : cette étiquette,
en `position:absolute` sans ancêtre positionné, **échappait au `overflow:hidden`** et se posait à
488 px sur un quai de 320 — elle gonflait `scrollWidth`, c'est-à-dire qu'elle MENTAIT à la boucle
qu'on venait de corriger.

**Le seuil de péremption était INFÉRIEUR à la cadence nominale.** 4 s en constante, alors que la
période de sondage passe à 5 s après 30 s sans action et à 10 s après deux minutes : avec un réseau
PARFAIT, l'écran de l'invité se serait déclaré « figé » environ une seconde sur cinq au repos et
**six secondes sur dix pendant un cycle de compressions de deux minutes** — c'est-à-dire dans le
cas d'usage phare. Un indicateur qui crie au loup les deux tiers du temps n'est plus lu quand la
panne est réelle. Le seuil est désormais solidaire de la cadence courante et signifie « deux cycles
manqués » (facteur 2,5 : la gigue étant de ±20 %, deux périodes consécutives atteignent 2,4 fois la
base). Un statut terminal cesse en outre de sonder — le sondage tournait indéfiniment contre un
partage mort.

**La fin du partage n'est pas la fin du soin.** Le critère « une crise est à l'écran » s'écrivait,
pour un invité, `status === 'active'` : à l'instant EXACT où l'hôte coupait, deux mécanismes se
rallumaient sur la checklist que le collègue tient encore en main — le déversement des snackbars
retenues pendant tout le soin (jusqu'à huit) et la ré-apparition de la méta de lecture, qui décale
le contenu sous son doigt. Le critère juste est la PRÉSENCE d'une fiche de crise, d'où deux sorties
distinctes : `freeze` (le lien meurt, l'écran survit) et `stop` (l'écran est quitté).

### Le quai de l'invité existe, et il dit qui tient la main
Il n'apparaissait que si une session avait démarré **localement** — or un invité qui suit n'a rien
démarré, c'est le principe même du miroir. Les deux informations que la doctrine veut permanentes
(AC 120-71B §6.4 : qui tient la checklist ne souffre aucune ambiguïté ; et si ce qu'on voit est
encore vrai) n'avaient donc **aucun conteneur**. Un prédicat unique — celui-là même qui gouverne
déjà la mise en attente des banderoles — et un jeu **fermé** de jetons dans le libellé du chrono :
`main` / `suit`, `⇄n`, `figé`, `coupé`, `fini`, `seul`.

Trois emplacements ont été mesurés et écartés. Un **segment `⇄` propre** déplace le segment
d'alarme de 45 à 57 px selon la largeur, à son apparition ET à sa disparition — donc sur ÉVÈNEMENT
DISTANT, ce que la constance positionnelle ECAM interdit ; la **rangée de commandes** n'a que 2,1 px
de marge à 320 px ; une 2ᵉ pilule sur le **bandeau** fait tomber le titre de fiche de 172 à 58 px.
Le libellé du chrono, lui, coûte zéro pixel de mise en page : le segment est déjà étiré par le flex.
**Le lien REMPLACE la main**, il ne s'y ajoute pas — ce n'est pas une économie de place : quand le
lien n'est plus nominal, le rôle et le compte de participants ne sont PLUS CONNUS, et les afficher
serait la donnée périmée présentée comme vivante. Le vert cesse alors d'affirmer (encre neutre,
jamais l'ambre, réservé au minuteur échu).

### L'invité ne paie plus rien avant d'avoir lu
Mesuré sur profil vierge : charger `index.html#j=CODE` déposait **3,17 Mo** (le cache applicatif et
les 1 773 Ko de pdf.js), créait une base IndexedDB, écrivait quatre clés `localStorage`,
enregistrait un service worker — et appelait `navigator.storage.persist()`, c'est-à-dire demandait
au navigateur de rendre ce dépôt **non évinçable** — le tout AVANT que le premier mot de la notice
d'information ait pu s'afficher. Une information préalable posée sur une collecte déjà faite
n'informe rien.

Le mode invité devient donc une **décision de démarrage**, pas une classe CSS. Trois cas : pas de
code → démarrage normal ; code sur appareil VIERGE → stockage en mémoire, aucun worker, aucune
persistance demandée, aucun ensemencement, et l'écran d'entrée **à la place** de l'application ;
code sur un appareil qui utilise déjà l'app → démarrage normal (lui refuser son worker ne
protégerait rien et casserait son hors-ligne), écran par-dessus — **sauf si une fiche de crise est
à l'écran**, auquel cas le code est GARÉ et annoncé par le bandeau système, qui est déjà le canal
« information persistante, accueil seulement » (règle 11). Le fragment est retiré de l'historique
immédiatement. `ensureStarted` refuse de démarrer chez un invité : c'est le point exact où
l'étanchéité se joue — sans cette garde, sa première coche créerait un enregistrement de session
sur un téléphone emprunté. `launchQueue` est enfin consommé (le manifeste le déclarait depuis
v4.43.0 ; un lien entrant sur PWA installée était silencieusement perdu).

### Un écran d'entrée, et un refus qui ne prescrit pas l'impossible
L'écran porte l'information de l'article 13 — qui est responsable, ce qui est enregistré, pourquoi,
où, combien de temps, qui d'autre le voit — et il est audité en accessibilité dans les deux thèmes
à 320 px, la largeur la plus contrainte servie.

Le message de refus a été réécrit après mesure, et les trois formulations précédentes étaient
fautives. **« Vérifiez les 8 caractères » était du texte mort** : le contrôle local a déjà exigé
exactement huit caractères pris dans l'alphabet, deux lignes plus haut. **« Demandez de rouvrir
l'accès » est faux ou nuisible dans cinq causes de refus sur sept, dont deux boucles infinies** —
`share_admit` ne vérifie NI l'expiration NI le quota : il rend un code neuf que `share_join`
refusera encore, sans que personne ne comprenne pourquoi ; et sur une simple faute de frappe, il
TUE un code peut-être encore vivant. On nomme donc le RÉSULTAT (« un nouveau code »), jamais le
geste : l'hôte seul voit sa porte, et c'est lui qui décide. **Chiffrer la fenêtre et le nombre de
participants aurait été FAUX** — et l'argument n'est pas l'oracle, une chaîne statique ne portant
aucun état : `max_guests` est une COLONNE PAR PARTAGE (1-8, défaut 3) et la fenêtre vaut 120 s à
l'ouverture mais 15 à 600 s à chaque réadmission ; le client ne reçoit ni l'une ni l'autre. D'où
une règle de tri, écrite au-dessus des constantes : un chiffre n'entre dans un message que s'il est
détenu par le client, identique pour tout partage du déploiement, et capable de changer ce que le
lecteur fait ensuite. « 8 caractères » passe les trois ; « 2 minutes » et « 3 » échouent aux trois.

Trois rédactions, choisies sur la **provenance locale** du code — jamais sur la réponse du serveur,
identique dans les trois cas : code recopié à la main, code venu d'un QR (qu'on ne peut pas mal
recopier), et deuxième soumission du même code, qui coupe la boucle du re-tap puisque le champ
conserve sa valeur après échec. Le harnais vérifie que le serveur bouchonné rend la même chose et
que trois textes différents en sortent : un message qui varierait avec la réponse du serveur serait
un oracle.

Enfin, la géométrie : la rédaction précédente faisait **7 lignes et 145 px**, et à 320×568 le
bouton « Rejoindre » n'était plus visible que sur **23 px de ses 48** — sous le plancher de la
règle 9, et 0 px sur un écran de 480. Le défaut n'apparaissait qu'à la largeur la plus contrainte,
et aucun harnais ne regardait cet écran. Il en existe un désormais, et il échoue sur l'ancienne
rédaction.

### Deux questions tranchées, mesures à l'appui
**Le titre de l'aide sur l'écran d'entrée** : quatre chemins instruits, deux refusés. Une fonction
`share_peek(code)` serait un ORACLE par construction — elle sépare « titre » et « refusé » sans
consommer le code ni prendre de place, là où `share_join` fait les deux, et il n'existe aucune
limitation de débit sur la jointure. Le titre dans le QR rendrait **une photo de l'écran prise de
loin porteuse d'un diagnostic permanent**, là où elle ne porte aujourd'hui qu'un secret de 40 bits
mort en dix minutes au plus. Le titre est de toute façon **déjà peint dans la première image du
miroir** (`#crisisBand`, mesuré visible sans défiler à 320×568 comme à 390×844) : un écran de
confirmation intermédiaire coûterait un tap pour zéro information, et il est inécrivable tel quel —
au retour de `share_join` la liste des participants est vide et l'hôte s'appelle littéralement
« Hôte ». Il ira donc à côté du code sur l'écran de l'hôte.

**Un utilisateur sans compte peut-il OUVRIR un partage ?** Non, et l'arbitrage a été refait sur ses
vrais mérites — deux des trois arguments spontanés ne tiennent pas. « La surface d'abus l'interdit »
est faux comme argument discriminant : `require_approval` valant `false` par défaut, un compte coûte
une adresse jetable et un OTP, et `share_open` n'a de toute façon **aucun plafond par
propriétaire** — les 500 Mo en 40 secondes sont atteignables aujourd'hui, avec un compte.
« Aucun plafond ne peut exister sans `auth.uid()` » est faux aussi : c'est vrai d'un plafond PAR
APPELANT, hors sujet pour un plafond GLOBAL. Ce qui tient : `owner` est la SEULE colonne reliant un
contenu diffusé à une personne (la retirer ferait de l'exploitant l'hébergeur d'un contenu sans
auteur, sans retrait ciblé, et supprimerait la seule prise du droit à l'effacement) ; l'approbation
des comptes deviendrait décorative, le contournement s'appelant « Déconnexion » ; et **un hôte
anonyme serait un hôte infirme** — la qualité d'hôte n'a aucun porteur autre que le JWT, donc ni
réadmission, ni coupure, ni fin de partage : si la mauvaise personne entre, le partage reste vivant
jusqu'à expiration. Si la décision devait s'inverser un jour, le seul chemin défendable est un
compte ANONYME Supabase (vrai identifiant, journal, révocation, cascade d'effacement), jamais un
`owner` nullable, et derrière un interrupteur d'instance par défaut fermé.

### Journal des actions, et fin de session
Incrémenter un compteur **pose désormais un repère horodaté** dans le journal des actions —
« choc n° 3 à 14:32 » est exactement ce qu'on oublie de noter sous stress, et l'heure est ce qui
compte cliniquement. Le repère porte une RÉFÉRENCE, jamais un mot : son libellé se dérive de la
fiche à l'affichage, il traverse donc le partage sans texte libre et suit le compteur si on le
renomme. Le rail ne remonte pas (mise à jour chirurgicale).

Le `×` du journal **annule au lieu de supprimer** : ligne barrée, estompée, conservée, et le `×`
devient `↺` pour se raviser. Deux règles du projet le condamnaient déjà — « action destructrice en
situation de crise = geste maintenir, pas un simple tap », et le précédent `origT`, où la correction
d'heure est non destructive, visible et réversible. Le « maintenir » a été envisagé et écarté : il
protège du geste accidentel mais laisse la perte définitive, et ne dit rien à celui qui relit — or
le journal alimente le compte-rendu. **L'heure reste en encre pleine** (c'est la donnée clinique).
C'est aussi ce qui rend le geste admissible pour un scribe en session partagée : attribué, daté,
réversible — là où un décochage, qui détruit vraiment une information, lui reste fermé.

### Vérification
663 tests × 2 moteurs, 13 harnais verts, **94/94 contrôles doctrine** (+54), **301 contrôles
d'accessibilité** (+12, dont l'écran d'entrée dans les deux thèmes), 55/55 contrôles partage. Les
nouveaux contrôles ont chacun été **vérifiés capables d'échouer**, fichier restauré à l'octet
ensuite. `supabase/schema.sql` et `rls-tests.sql` ont été rejoués sur l'instance (le genre
d'évènement `mark_void` s'ajoute aux capacités du scribe).

**Incident de manipulation, consigné parce qu'il doit servir.** Un `git checkout -- index.html`,
lancé pour annuler une modification temporaire de démonstration, a effacé tout le travail non
committé du fichier — cette commande ne défait pas la dernière modification, elle restaure depuis
le dernier commit. Le fichier a été reconstruit depuis le transcript de session (79 éditions
rejouées dans l'ordre, deux ancrages réparés, deux modifications faites hors outil d'édition
retrouvées et re-appliquées), puis vérifié : audit systématique des 79 éditions (zéro manquante),
cohérence de la réparation manuelle sur ses 5 sites, absence de duplication, et surtout la suite
complète au vert — les tests et les treize harnais, eux, n'avaient pas été touchés, et c'est ce qui
a servi de juge. **Règle : pour annuler une modification expérimentale, restaurer depuis une
sauvegarde vérifiée par empreinte, jamais depuis git tant que le travail n'est pas committé.**

## [4.46.0] — 2026-07-27
### Partage de session en direct — le socle serveur, et six défauts trouvés en chemin

Premier jalon d'un chantier qui fera sortir une **session** de l'appareil : un collègue présent
dans la pièce pourra suivre et remplir une session de crise depuis SON téléphone, avec ou sans
compte, **pour cette session uniquement**. Rien n'est encore visible à l'écran. Cette version pose
le serveur, l'encodeur du code d'appariement et le noyau pur du transport — chacun vérifié
séparément, aucun ne dépendant du suivant.

### Ce que la doctrine dit vraiment, et une citation du projet qui était fausse
Les textes primaires ont été lus, pas leurs résumés — et deux résultats vont contre l'intuition.
**« Do-Verify » et « Challenge-Do-Verify » n'existent NULLE PART dans l'AC 120-71B** (recherche
exhaustive sur le document intégral : 6 chapitres + Appendix A, zéro occurrence ; la révision B
indique elle-même avoir retiré les exemples des appendices). Ces intitulés viennent de
l'**AC 120-71A (2003), que la révision B ANNULE**, où ils ne sont que des titres d'une liste de
sujets, sans définition. Les définitions rédigées qui circulent en ligne ne proviennent d'aucun
document FAA retrouvable. La pratique implémentée ne change pas d'un pixel — seule la référence
était fausse : la source correcte est le **FAA Order 8900.1, Vol. 3, Ch. 32, §3-3403.A**, et pour
la répartition à deux, l'AC 120-71B **§5.2.2.1** (« one crewmember reading the checklist and the
second crewmember confirming and responding »). Corrigé dans `AGENTS.md`, avec l'avertissement de
ne pas ré-inverser. De même, « la réponse porte l'état CONSTATÉ, jamais un *fait* » est de
**Degani & Wiener** (ligne directrice n°1, 1993), pas de la circulaire.

Deuxième résultat, structurant : **la co-édition symétrique n'est décrite nulle part**. Airbus
garantit l'exclusion mutuelle par le MATÉRIEL (un seul ECAM Control Panel) ; là où deux pointeurs
coexistent, l'industrie a écrit un verrou mono-écrivain à propriété visible, jamais une fusion. La
« vue dégradée » de l'invité n'est donc pas un compromis : c'est la forme canonique.

### Socle de sûreté — six défauts du code ACTUEL, sans rapport avec la nouveauté
- **`keepAnchor` confondait « 0 px » et « pas mesuré ».** Les trois sorties sans mesure renvoyaient
  `0`, c'est-à-dire la valeur qui signifie « ancrage parfait ». La plus grave : l'ancre a DISPARU
  pendant le re-rendu (une condensation du journal transforme la carte visée en chip). Démontré en
  réintroduisant le défaut — le cas guidé affiche **dérive 0 px ET résidu null** : l'ancien contrôle
  d'`audit-doctrine` passait au vert **sans avoir rien mesuré**, exactement sur le cas qu'il prétend
  couvrir. Troisième occurrence de la leçon v4.31.1. `keepAnchor` renvoie désormais `null`, que le
  harnais refuse (40/40).
- **La « prohibition ACTIVE » du rôle `anon` ne portait pas sur `PUBLIC`.** `revoke … from anon` ne
  retire que les privilèges accordés NOMMÉMENT à anon ; or PostgreSQL accorde `EXECUTE` à **PUBLIC**
  par défaut sur toute fonction (asymétrie avec les tables, qui n'en reçoivent aucun — d'où un
  revoke efficace côté tables et INOPÉRANT côté fonctions), et tout rôle hérite de PUBLIC. **Les
  20 fonctions du schéma étaient appelables sans compte.** Aucune escalade — chacune se protège par
  `auth.uid()` — mais la garantie annoncée n'existait pas.
- **`is_approved()` renvoyait `true` pour `anon`** : `auth.uid()` étant NULL, le `coalesce` retombait
  sur `'approved'`. Sans conséquence aujourd'hui (les politiques exigent en plus `owner = auth.uid()`),
  mais tout garde-fou futur écrit avec elle aurait été inopérant **en ayant l'air solide**. Règle
  écrite : un gate anon s'écrit `auth.uid() is not null`, jamais `is_approved()`.
- **Le balayage anon de `rls-tests.sql` (§13.5) était aveugle à ce qu'il prétend couvrir** : sept
  tables NOMMÉES EN DUR, zéro fonction. Remplacé par des assertions de **CATALOGUE** — aucun grant
  de table à anon, liste blanche EXACTE des fonctions exécutables par anon, et balayage dynamique de
  toutes les tables. Piège évité en l'écrivant : sous `anon`, `information_schema` ne montre rien,
  la boucle aurait tourné à vide et le test serait passé au vert sans rien balayer.
- **Aucun appel réseau n'avait de délai de garde.** Sur iOS, un `fetch` sans route ne rejette qu'au
  bout de 60 à 75 s : `Sync.running` reste vrai tout ce temps, le repli exponentiel ne peut pas
  s'armer (il ne démarre qu'APRÈS la première erreur), et `Auth.refresh()` — attendu avant CHAQUE
  appel REST — bloque tout ce qui suit. Les cinq `fetch` passent par `acFetch` (25 s, 120 s pour un
  binaire PDF : un téléversement légitime sur réseau lent ne doit pas être cassé par le correctif).

### Serveur — la première surface non authentifiée du projet
Trois tables (`shared_sessions`, `session_participants`, `session_events`) et six fonctions. La
surface `anon` est de **trois portes nommées, et rien d'autre**, ouvertes après la révocation
générale — placées avant, elles seraient effacées en silence quelques lignes plus bas.

Quatre décisions, chacune réparant une faille identifiée AVANT écriture : **aucune identité n'est
jamais un paramètre** (l'acteur se DÉDUIT du secret présenté ; le passer rendrait l'attribution
forgeable par tout porteur du code — or l'attribution EST le contrôle demandé) ; **le secret est
tiré par le serveur** (`gen_random_bytes`), jamais par le client, dont le seul générateur maison
rend ~41 bits et retombe sur `Math.random` ; **fenêtre d'admission** armée par l'hôte, code
**consommé** à la première jointure, ce qui rend la coupure d'un invité EFFECTIVE au lieu de
décorative ; **append-only strict** — un invité n'écrit que des lignes, l'état est un pli calculé
côté client, sinon le verrou de ligne d'un état matérialisé ferait attendre l'hôte derrière la file
d'un invité. La séquence est allouée **sous verrou, par partage** : un `bigserial` alloue à l'INSERT
et non au COMMIT, un évènement validé en retard resterait définitivement sous le curseur du lecteur.
Chaque évènement porte **deux horloges** — l'instant du geste et celui de l'arrivée — sans quoi une
action relevée hors réseau se rangerait au compte-rendu à l'heure du retour du réseau.

**Relais, pas entrepôt** : purge bornée en tête de CHAQUE appel (sur un hébergement statique,
une purge planifiée n'a personne pour la lancer). `delete_my_account` supprime les partages
**explicitement** — sans cela, soit ils survivent, soit la violation de clé étrangère annule toute
la fonction et le droit à l'effacement disparaît pour quiconque a partagé une fois.

**`supabase/schema.sql` est à REJOUER**, puis `rls-tests.sql` — dont le nouveau **§14 porte
31 assertions** : jointure d'un invité sans compte, code consommé, capacités du scribe, acteur non
falsifiable, coupure MOTIVÉE (« revoked », jamais un silence qu'on prendrait pour une panne),
détachement, purge, effacement RGPD.

### Deux garde-fous nés des erreurs de cette version
`check-sql.mjs` gagne deux contrôles, chacun **vérifié capable d'échouer** puis fichier restauré à
l'octet. (1) Tout `grant … to anon` doit citer une fonction de la liste blanche, et
`grant … on all …` est refusé quel que soit le rôle : le scénario visé n'est pas la malveillance
mais le dépannage — PostgREST accompagne un refus 42501 d'un `hint` qui nomme le grant manquant, et
la réponse la plus répandue en ligne est la forme globale. (2) Une fonction `language sql` ne peut
référencer aucun objet déclaré plus bas dans le fichier : elle est intégralement résolue À SA
CRÉATION (`42P01` au collage), là où une `language plpgsql` n'analyse son corps qu'à la première
exécution. Cette asymétrie ne se voit pas à la relecture et avait déjà coûté deux re-créations de
`get_instance_stats` ; elle en a coûté une troisième ici, découverte sur l'instance.

### Encodeur QR — sans dépendance, et relu par le décodeur d'Apple
Le code d'appariement s'affiche en QR sur l'écran de l'hôte : un QR affiché ne peut être scanné que
par quelqu'un qui est **là**, et il ne transite par aucun message, aucun journal d'accès, aucun
historique. L'app n'embarque **aucun décodeur** — iOS et Android décodent nativement depuis
l'appareil photo — et c'est cette asymétrie qui rend la fonctionnalité abordable (règle 13 intacte,
aucun fichier servi de plus). Mode octet, correction M, versions 1 à 10.

Choix de conception central : **une seule table de 20 nombres**, tout le reste se dérive — total de
mots-code par la géométrie, découpage en blocs par la division euclidienne, alignements par formule.
Une table recopiée est une erreur qui dort ; une dérivation se vérifie, et le test recoupe les deux
chemins. **La vérification a payé immédiatement** : le calcul des syndromes Reed-Solomon — qui
ÉVALUE le polynôme là où l'encodeur le DIVISE, donc n'emprunte rien à ce qu'il vérifie — a fait
tomber un polynôme générateur construit **à l'envers** (terme dominant non unitaire). Motifs au bon
endroit, format valide, structure impeccable : aucun contrôle de cohérence interne ne l'aurait vu,
et les codes produits auraient été parfaitement illisibles. Nouveau harnais `scripts/audit-qr.mjs` :
les codes sont relus par **CoreImage**, le décodeur d'Apple, celui de l'appareil photo de l'iPhone —
5 cas, v1 à v6, UTF-8 accentué compris, sur les deux moteurs. macOS seulement : ailleurs il AVERTIT
sans échouer, en disant explicitement que la vérification n'a pas eu lieu. Piège de thème évité :
`--ink` est CLAIR en sombre, un QR peint avec lui serait blanc sur blanc — d'où `--qr-ink`, fixe
dans les deux thèmes, sur le patron de `--paper`.

### Noyau pur du transport
Sept fonctions sans effet de bord. **La projection de fiche** (`sharePayload`) n'est pas la fiche :
deux listes explicites couvrent les **27 champs du modèle migré**, et un test échoue si l'une prend
du retard — ajouter demain un champ sans décider s'il se partage devient impossible (garde-fou
vérifié capable d'échouer). Ne partent pas : le gabarit local (téléphones de renfort et de
régulation, pré-remplis par `blankFiche`), les images (jusqu'à 24 Mo), les documents que l'invité ne
pourrait pas ouvrir, `ownerId`/`libraryId`. `shareFold` exclut l'annexe d'un détaché de l'état —
c'est un rapport, pas une commande. `shareStateHash` détecte la **divergence silencieuse**, celle
qu'un indicateur de péremption ne verra jamais parce que les mises à jour arrivent à l'heure et sont
fausses. `shareOffset` (Cristian) rejette toute mesure dont l'aller-retour dépasse le seuil : un
décalage faux daterait les gestes du compte-rendu et ferait sonner deux minuteurs à des instants
différents dans la même pièce. L'en-tête HTTP `Date` n'étant PAS lisible en fetch cross-origin,
l'heure serveur voyage dans le corps.

**560 tests × 2 moteurs, 12 harnais verts, 289 contrôles a11y, 40/40 doctrine.**

## [4.45.0] — 2026-07-27
### Factorisations — et ce qu'elles ont révélé
Trois duplications du reliquat d'audit, sans effet visible à l'écran. La troisième a fait tomber un
angle mort qu'aucune relecture n'aurait trouvé.

### L'ancrage ECAM : de 4 copies à 1, et enfin mesurable
Le motif « mesurer la position écran d'une ancre, re-rendre, compenser le défilement » existait en
quatre exemplaires — `renderKeepAnchor`, `renderOvOnlyKeepAnchor`, `ovAdvanceRender`, et le
remplacement chirurgical de `renderNavOnly`. C'est **l'invariant le plus cité du projet** (« rien
ne bouge sous le doigt ») et **une seule des quatre mesurait son résidu** : les trois autres
appliquaient le motif sans jamais pouvoir dire si elles y arrivaient. Source unique `keepAnchor`.

Ce qui **n'a pas** été unifié, et pourquoi : le focus clavier (seul le journal le déplace) et la
règle de visibilité (seul `ovAdvanceRender` défile vers la nouvelle carte, et seulement si elle
n'est pas déjà entièrement à l'écran). Le résidu reste **renvoyé, jamais corrigé** — la
compensation est bornée par le haut de page, et c'est cette limite qui fonde la doctrine de
`state.confOpen` ; la masquer rouvrirait le bug v4.3.2.

Deux contrôles permanents ajoutés à `audit-doctrine` (38/38) : dérive 0 px à la première action de
session et au remplacement du bloc en mode guidé. Tolérance 1 px, assumée : WebKit rend 1 px là où
Blink rend 0, arithmétique identique — du sous-pixel de compositeur, pas un défaut d'ancrage.

*Note : un `{preventScroll:true}` s'était glissé dans la restauration de focus. Il serait cohérent
avec les deux autres restaurations du fichier et protégerait l'ancrage qu'on vient d'appliquer —
mais c'est un changement de comportement, et un lot de factorisation n'en embarque pas. Retiré, et
signalé ici pour décision séparée.*

### `updateRtStrip` : un calcul écrit deux fois, un prédicat rédigé de deux façons
Le temps restant (qui sert au tri : échus d'abord, puis les plus urgents) était calculé à
l'identique pour le quai et pour la bande du mode lecteur, mais le prédicat « échu » différait —
`dueDone(t)||(interval && val==='00:00')` d'un côté, `interval && val==='00:00'` de l'autre.
L'extraction est **iso-sortie**, et la démonstration mérite d'être écrite : `dueDone` impose déjà
`type==='interval'`, et un minuteur échu et arrêté donne `within >= per`, donc `fmtMs(max(0,
per-within))` vaut « 00:00 » — le premier disjoint est absorbé par le second. Une **fonction**
appliquée deux fois, jamais un tableau partagé : chaque zone garde son tri et sa troncature.

### Les onze harnais n'auditaient pas la cible principale
`scripts/harness.mjs` : serveur statique, table MIME et choix du moteur, partagés. La duplication
avait déjà dérivé — `audit-lecteur.mjs` était le seul dont la table MIME omettait `.ico`.

Mais le vrai constat est ailleurs : **les onze lançaient `chromium.launch()` en dur**. `npm test`
tourne sur deux moteurs depuis v4.34.0 parce qu'iOS Safari est la cible principale et qu'un
comportement WebKit peut couper l'écran sans qu'aucune mesure ne le voie. Les harnais, eux,
n'auditaient que Blink. Le moteur se choisit désormais par `AC_ENGINE` — `chromium` par défaut,
donc rien ne change sans décision, et un nom inconnu échoue bruyamment plutôt que de retomber en
silence sur chromium.

**Le premier passage sur WebKit a immédiatement payé.** La sonde WCAG 2.4.11 signalait **8
masquages sur 11 cibles** — de quoi croire à un défaut d'accessibilité sur iPhone. La géométrie dit
autre chose : tous avaient un bas **négatif** (−352, −237, −138, −94 px), c'est-à-dire des éléments
pas encore revenus à l'écran. Sur WebKit, le défilement induit par un focus **programmatique** est
asynchrone ; la sonde lisait la position d'avant et mesurait la synchronicité du moteur, pas
l'application. Variable isolée (même sélecteur, même scénario, seule l'attente change) : lecture
immédiate → 8, lecture après 60 ms → **0, sur les deux moteurs**.

Ce n'était donc pas un défaut d'accessibilité — mais **on ne pouvait pas le savoir** tant que les
harnais ne tournaient que sur Blink. Règle ajoutée : toute sonde qui lit une géométrie après
`focus()` doit attendre.

**Les onze harnais passent désormais sur WebKit comme sur Chromium.**

513 tests × 2 moteurs, 11 harnais verts **sur les deux moteurs** (38/38 en doctrine),
289 contrôles d'accessibilité.

## [4.44.1] — 2026-07-27
### Correctif : `schema.sql` de v4.44.0 ne s'exécutait pas
Signalé par l'utilisateur au rejeu sur Supabase :
`ERROR: 42601: syntax error at or near "$"`, ligne 270.

Deux fonctions trigger — `clamp_updated_at` et `stamp_updated_by` — avaient perdu un dollar de
leur délimiteur de corps : `as $$` était devenu `as $`. Réparé, et vérifié qu'il n'en restait
aucun autre.

**La cause est une erreur de méthode de ma part, et elle mérite d'être écrite parce qu'elle se
reproduira.** `String.prototype.replace()` interprète `$$` **dans la chaîne de remplacement**
comme un dollar littéral unique — au même titre que `$&`, `` $` ``, `$'` et `$1`. Le script de
patch qui ajoutait `set search_path` aux deux fonctions réinjectait donc du SQL mutilé, en
silence. Remède : passer une **fonction** de remplacement (aucune substitution n'y est faite), ou
`split().join()`.

**Et le contrôle que j'avais fait ne pouvait pas l'attraper.** J'avais compté les `$$` et vérifié
la parité : 50, pair, vert. Or un `$$` amputé en `$` ne matche plus le motif — il disparaît du
compte **des deux côtés**, et la parité reste vraie. C'est un contrôle aveugle au défaut qu'il
prétend couvrir, exactement ce que la leçon v4.31.1 proscrit ; je l'ai redite au prix fort.

### `scripts/check-sql.mjs`, dans `npm run check`
`supabase/schema.sql` et `supabase/rls-tests.sql` n'étaient couverts par **rien** : ni servis, ni
chargés par les tests. Une erreur ne s'y voyait qu'au collage dans l'éditeur SQL de Supabase —
c'est-à-dire chez l'utilisateur, sur une instance de production. Trois contrôles : les **runs de
dollars** (un délimiteur de corps s'écrit `$$`, un dollar isolé est la signature exacte du défaut),
leur parité, et l'absence de `;` dans un en-tête de fonction avant son corps. Vérifié capable
d'échouer en réintroduisant le défaut vécu — il le signale par les **trois** voies — puis fichier
restauré à l'octet.

### Relecture complète du diff SQL
Toutes les modifications de v4.44.0 sur `schema.sql` ont été relues ligne à ligne :
**zéro ligne supprimée qui ne soit un en-tête de fonction**. Aucune logique, aucune politique,
aucun grant n'a été touché — uniquement l'ajout de `pg_temp` et, pour les deux fonctions trigger,
d'un `search_path`.

> **`supabase/schema.sql` est à rejouer**, cette fois avec succès, puis `rls-tests.sql`.

513 tests × 2 moteurs, 11 harnais verts, 289 contrôles d'accessibilité.

## [4.44.0] — 2026-07-27
### Durcissement, sécurité serveur, purge — et le filet qui manquait sur le service worker
Quatre lots techniques du reliquat d'audit, sans effet visible à l'écran.

### Durcissement
**`esc()` échappe désormais l'apostrophe.** La doctrine en fait « la SEULE barrière anti-XSS » : la
laisser suspendue à l'invariant non vérifié « aucun attribut n'est délimité par une apostrophe »
faisait reposer la sûreté de tout le fichier sur une convention que rien n'impose. Innocuité
établie avant écriture : 278 sites d'appel, dont **0 `textContent`, 0 `setAttribute`, 0 comparaison
de chaîne** — la sortie ne va que dans du HTML, où l'entité est re-décodée.

**Le backtick, lui, reste intact — et c'est une décision, pas un oubli.** Il a été échappé, puis
rétabli : trois tests du mini-Markdown tombent aussitôt, parce que `mdInline` échappe d'abord et
reconnaît la syntaxe ensuite — un backtick devenu `&#96;` n'est plus un délimiteur de code. Et ce
n'est pas un métacaractère HTML. L'échapper coûtait une fonctionnalité documentée pour zéro sûreté.
Les deux tests encodent maintenant la règle **et son exception**.

Le risque réel n'était pas la sûreté mais l'affichage : les textes français sont pleins
d'apostrophes. Balayage de **7 surfaces × 2 moteurs** (accueil, session vive, feuilles Consulter et
Se repérer, statique, éditeur, protocole) — **aucune entité littérale**, la sonde prouvant par
contre-épreuve qu'elle sait en voir une.

**`check-colors` : exemption resserrée à la règle, plus à la ligne.** Elle était `^.*\.acc-sw\..*$`
— ligne entière. Or ce CSS écrit plusieurs règles par ligne : trois lignes exemptées, dont **deux
portant six règles chacune**, et une troisième sans le moindre hex. Un hex collé en fin d'une de
ces lignes passait inaperçu ; il est désormais attrapé (démontré, puis fichier restauré à l'octet).

### Sécurité serveur
`pg_temp` ajouté en fin des **20** `search_path` épinglés, et les **2 fonctions trigger** —
`clamp_updated_at`, `stamp_updated_by` — qui n'en avaient aucune en reçoivent une. Nuance honnête :
`pg_temp` n'est jamais consulté pour résoudre une fonction ou un opérateur, seulement pour les
tables, et toutes les relations sont déjà qualifiées `public.…` — on ferme une porte déjà fermée
par ailleurs. On le fait parce que c'est gratuit et que l'absence est ce qu'un auditeur tiers
relève en premier. Vérifié : **0 `search_path` nu, 0 sans `pg_temp`**.

**`FORCE ROW LEVEL SECURITY` n'est PAS activé, et le piège est désormais écrit dans le schéma.**
L'ajouter par réflexe supprimerait **tous les app-admins** : `app_admins` et `app_settings` n'ont
volontairement ni politique ni grant, et ne sont lues que par `is_app_admin()`/`is_approved()`, qui
sont `security definer` précisément pour traverser cette invisibilité. Sous `force`, le
propriétaire redevient soumis aux politiques — il n'y en a aucune — donc plus aucune création de
bibliothèque ni validation de compte sur toute l'instance.

> ⚠ **`supabase/schema.sql` est à rejouer** sur l'instance Supabase, puis `rls-tests.sql`.

### Purge (règle 14) — zéro pixel changé
- **`state.showSess`** : déclaré, remis à false deux fois, **jamais lu**.
- **`_rtShowDirty`** : quatre écritures, **zéro lecture** — deux écouteurs globaux (`scroll`,
  `resize`) entretenaient une valeur que personne ne consultait, et le commentaire décrivait une
  optimisation qui n'existait plus.
- **Modificateur `compact`** : émis deux fois, **aucune règle CSS** dans tout le fichier.
- **Délégation du plan dans `bindOverviewEvents`** : trois branches inatteignables. Ce gestionnaire
  écoute `.ov-wrap`, le journal ; le plan l'a quitté en v4.23.0. Mesuré avant retrait dans
  **21 configurations** (3 largeurs × 7 états) : `.ov-wrap [data-pl*]` = **0 partout**, pendant que
  le rail en portait 9 dès 800 px et la feuille 9 une fois ouverte.
- **Trois règles CSS strictement dupliquées** (`.dock-plan:hover`, `.catchip{position:relative}`,
  `#crtIA .crt-ic`). Un **quatrième** doublon strict existe — `body.view-read .read-grid` @1200 —
  et il est **délibéré**, réaffirmé exprès après le bloc 1000 pour gagner par l'ordre de cascade.
  Il apparaît dans la même liste que les autres : ne jamais passer d'outil « supprimer les règles
  dupliquées » sur ce fichier.
- **`--pulse`** était la copie décimale **exacte** de `--ok` dans les deux thèmes (29,122,56 et
  55,214,122). Invisible au garde-fou couleurs, puisque c'était une déclaration de token : changer
  `--ok` aurait laissé le halo derrière. Source unique désormais — `--ok-rgb` porte le triplet,
  `--ok` en dérive. Vérifié au calculé : `rgb(29, 122, 56)` / `rgba(29, 122, 56, 0.45)` en clair,
  `rgb(55, 214, 122)` / `rgba(55, 214, 122, 0.45)` en sombre, identique sur les deux moteurs.
- **`#brandSub .sess-dot`** : CSS mort. `.sess-dot` n'est émis que dans les cartes « sessions en
  cours » de l'accueil ; `#brandSub` est un `<span>` de texte. 0 nœud sur 3 états × 2 moteurs.

### Commentaires qui mentaient
- `posoCardsHtml` s'annonçait « source unique **partagée par le flux et la feuille Consulter** — les
  deux rendus ne peuvent pas diverger ». Faux depuis v4.25.3, qui a retiré la posologie de la
  feuille : il ne reste qu'**un** site d'appel. Le commentaire promettait une garantie de
  non-divergence entre deux rendus dont l'un n'existe plus. **AGENTS.md portait la même
  affirmation**, en contradiction avec sa propre section « FEUILLE CONSULTER » deux paragraphes
  plus haut — corrigé aux deux endroits.
- `_vvhSync` annonçait « ~1 s » : il tourne à **3,3 fois par seconde** (`setInterval(…,300)`, appel
  placé avant le garde d'activité). Coût mesuré : **nul** — `vv.height` est déjà calculé, et
  l'écriture n'a lieu qu'au-delà de 0,5 px de variation. Le chiffre est corrigé parce qu'un
  commentaire faux sur une fréquence est ce qui fait ensuite « optimiser » au jugé une boucle qui
  ne coûte rien.

### Le filet manquant : `scripts/check-sw.mjs`
**La fonction dont tout dépend en intervention — exister hors ligne — était la seule que rien ne
mesurait** : aucun des onze harnais ne regardait `sw.js` ni le manifeste, et trois des défauts les
plus graves de cet audit vivaient là, trouvés à la lecture seule. Quatre contrôles **statiques**,
donc instantanés, donc dans `npm run check` à chaque commit : toute entrée d'`ASSETS` /
`CORE_ASSETS` / `PDFJS_ASSETS` existe sur le disque (une entrée fantôme dans `CORE_ASSETS` fait
échouer `addAll`, qui est tout-ou-rien, et supprime le hors-ligne entier) ; `CORE_ASSETS` ⊆
`ASSETS` ; tout fichier servable de la racine est dans `ASSETS` — la règle 13 ne s'auto-exécutait
pas ; `CACHE` aligné sur `APP_VERSION`, c'est-à-dire la règle 1. Vérifié capable d'échouer sur les
deux scénarios, fichier restauré à l'octet.

513 tests × 2 moteurs, 11 harnais verts (34/34 en doctrine), 289 contrôles d'accessibilité.

## [4.43.0] — 2026-07-27
### Deux arbitrages tranchés : 320 px est servi, et la production est GitHub Pages
Décisions utilisateur. Elles débloquent quatre constats du reliquat d'audit.

### 320 px — WCAG 1.4.10, et deux rognages silencieux
C'est le plancher de « Reflow », et deux surfaces y perdaient du contenu sans le dire :

- **rangée de commandes de crise** : 348 px requis pour 320, soit **28 px inatteignables** — le
  bouton restait opérable (44 px visibles, `aria-label` intact) mais se lisait « ⤢ Con », coupé en
  plein mot ;
- **`⋯` de l'éditeur** : **6,2 px hors écran**, bouton pourtant `display:grid` donc bien peint.

Identique sur Chromium et WebKit. Les pixels viennent de la recette v4.23.4 — écarts et
rembourrages — jamais d'un renommage (règle « troncature du même mot ») ni d'une 2ᵉ ligne (la
hauteur de crise est un coût permanent) : **34 px rendus pour 28 nécessaires** dans la crise,
~12 pour 6,2 dans l'éditeur.

Une analyse antérieure concluait que la recette était épuisée et qu'il faudrait sacrifier
`.ctrl-sp`. C'est faux, et pour une raison précise : elle visait les postes déjà compressés en
v4.30.0, jamais le rembourrage des deux segments de mode (12 px à lui seul) ni celui des deux
ouvertures. **`.ctrl-sp` n'est pas touché** — ces 4 px sont l'écart de Gestalt qui sépare le MODE
des OUVERTURES, raison d'être de la séparation ECP/ECAM de v4.25.0.

Le harnais gagne un contrôle qu'il n'avait pas : le **rognage par le conteneur**. Un bouton peut
tenir dans la fenêtre tout en étant coupé par sa boîte de contenu — c'est exactement ce qui se
produisait, et le contrôle « hors écran » seul passait au vert. `audit-doctrine` mesure désormais
320/360/375/390 pour la crise et 320/360 pour l'éditeur (34/34).

### Hébergement : GitHub Pages en production, déployable ailleurs
Décision datée dans `docs/deploiement-et-conformite.md` et en tête de `_headers`. Conséquence
assumée : **`_headers` est maintenu à jour bien que GitHub Pages l'ignore totalement** — il n'est
pas décoratif, c'est la posture servie sur tout autre hébergeur, et le supprimer ferait disparaître
le seul endroit où elle est écrite.

Ajoutés : `Cross-Origin-Opener-Policy` et `Cross-Origin-Resource-Policy` en `same-origin`
(`window.open` est absent du code — vérifié, 0 occurrence — donc aucun échange de fenêtre à
casser), et une `Permissions-Policy` portée de 3 à **21 capacités**.

**COEP `require-corp` est délibérément absent** : aucun `SharedArrayBuffer`, aucune ressource
cross-origin embarquée, donc il ne protège rien — et il casserait au premier ajout. Un en-tête qui
ne protège rien et casse plus tard est une dette.

Trois capacités restent **volontairement ouvertes**, et la liste a été établie par mesure, pas
recopiée d'un modèle :
- **`autoplay`** — le bip d'alarme passe par WebAudio, soumis à la politique d'autoplay. Le fermer
  rendrait l'alarme de minuteur **muette** : la sortie la plus critique de l'application.
- **`screen-wake-lock`** — inutilisé aujourd'hui, mais garder l'écran allumé pendant une
  réanimation est un besoin plausible.
- **`web-share`** — `navigator.share` est le chemin **obligatoire** du téléchargement PDF en PWA
  installée (v4.19.1 : WebKit ignore `download` en standalone).

`launch_handler: {client_mode: "focus-existing"}` ajouté au manifeste — la seule des quatre clés
manquantes qui porte un argument clinique (ne pas ouvrir une seconde fenêtre pendant une session
vive). iOS ne l'implémente pas ; Android et bureau si.

**`"id": "./"` n'est PAS modifié**, et la raison est écrite pour la prochaine fois : `id` se résout
par rapport à l'**origine**, pas au chemin du manifeste. Le changer ferait apparaître l'app comme
une **nouvelle application** chez tout utilisateur l'ayant installée — doublon sur l'écran
d'accueil, ancienne installation figée sur son cache. C'est une porte à sens unique. Contrainte qui
en découle : ne pas héberger une seconde PWA sur la même origine.

510 tests × 2 moteurs, 11 harnais verts (34/34 en doctrine), 289 contrôles d'accessibilité.

## [4.42.0] — 2026-07-27
### Le reliquat d'audit trié : 36 % était périmé
Les 70 constats jamais traités de la Phase 1 ont été reconfrontés au code actuel, chacun sous
contre-expertise. **25 sont tombés** : 2 déjà corrigés, 5 mal fondés, 18 dont la preuve se
reproduit mais dont le verdict s'inverse (victime inexistante ou remède pire que le mal). Restent
45, dont **22 sont des questions à trancher** et 23 des corrections — dont **4 seulement changent
quelque chose pour un soignant**. Ce sont ces quatre-là.

Deux familles se sont effondrées en bloc. Les constats de **performance** mesuraient des *comptes
d'appels* sans chronomètre : le tick de 300 ms coûte 0,5 ms/s de mise en page, le resize PDF
0,26 ms, `syncHdrScroll` 0,10 ms/s de gain potentiel — à comparer aux 126,8 ms/s du seul vrai
levier de v4.41.0. Les constats **« le dépôt ne documente pas X »** reposaient sur des greps qui
excluaient `CHANGELOG-archive.md`, qui est pourtant le canal de décision du projet.

### Décocher ne défaisait pas la fin de l'algorithme, en mode guidé
Le cœur du cochage existe en deux copies, guidé et journal, et elles avaient divergé. Le journal
remet `state.flowEnded` à false puis re-rend si la bannière traîne. Le guidé faisait le reset dans
la branche `else` d'un `if(nn)` — or quand la fin est actée, `#navNext` **n'existe plus** :
`navSection` le remplace par la bannière `.flow-end`. `nn` étant null, le bloc entier était sauté
et le reset ne s'exécutait **jamais dans le seul cas où il sert**. Mesuré sur une fiche mono-bloc
(ce que rend `blankFiche()`, donc toute fiche neuve) : « Algorithme terminé — surveillance en
cours » restait affiché après décochage et « Terminer l'algorithme » ne revenait pas.

**Ce chemin n'était couvert par aucun test** : `grep -rn 'nav-wrap\|navNext\|bindNavEvents'
tests.html scripts/` rendait 0. Cinq contrôles ajoutés à `audit-doctrine.mjs` (27/27), vérifiés
capables d'échouer — défaut réintroduit, 3 échecs, fichier restauré à l'octet.

### L'alarme routée était muette pour les lecteurs d'écran
Session hors de vue (autre fiche, autre vue), un minuteur sonne : banderole visuelle, flash écran,
et notification système **seulement si l'app est en arrière-plan**. Restait le bip — qui dit qu'un
minuteur a sonné, jamais **lequel** ni **sur quelle fiche**. C'est précisément le cas où
l'information manque : une session vive sur une autre fiche pendant qu'on lit un différentiel.
`announce()` écrit désormais dans `#srLive` (`role=alert`, `aria-live=assertive`) : audible côté
lecteur d'écran, **invisible à l'écran** — la règle 11 tient, rien ne bouge et rien ne se pose
par-dessus la checklist. Vérifié : une seule banderole ajoutée, pas deux (WCAG 4.1.3).

### Trois minuteurs de même id n'en armaient qu'un
`migrate()` déduplique les ids de blocs (`while(used[nid])`) mais pas ceux des minuteurs ni des
compteurs. Or `Runtime.timers` est indexé par id : trois entrées de même id, **une seule armée, la
dernière**, sans le moindre signal — et les ids DOM (`tmval-`, `cnval-`) se télescopent. Une fiche
importée, dupliquée ou reçue d'une bibliothèque partagée passe par là, et la règle 5 veut que
`migrate()` soit le point où une donnée entrante devient sûre. Le premier garde son id (les
références `counters[].timerId` continuent de résoudre sur lui) ; les suivants en reçoivent un
neuf. Mesuré : 3/3 ids distincts, 3/3 minuteurs armés, 3/3 cartes, 2/2 compteurs.

### Un pull de synchro avalait un tap en pleine réanimation
`if(applied)render()` reconstruisait tout le DOM dès qu'une seule ligne distante était écrite —
y compris en session vive. La règle 11 l'interdit déjà en toutes lettres (« aucune synchro
intrusive ») : ce n'était donc pas un arbitrage. Il suffisait qu'un coéquipier modifie une ligne
d'une bibliothèque partagée.

Le premier contrôle que j'avais écrit était faux, et il faut le dire : un `.click()` programmatique
sur un nœud détaché déclenche quand même son handler (la fermeture survit), et je comptais des
*clés* de `state.checked` alors que décocher écrit `false` et conserve la clé. Un tap réel est
`pointerdown → pointerup → click`, et le click n'est émis que si les deux atterrissent sur le même
élément : le défaut est donc « DOM remplacé entre les deux ». Reproduit à la vraie souris,
Chromium **et** WebKit — **témoin : 0 → 0 coche** (tap avalé) ; **après correctif : 0 → 1**, sans
re-rendu ; et hors session le rendu se déclenche toujours.

Rien n'est perdu pendant ce temps : la mémoire est déjà à jour, et toute sortie de crise passe par
`render()`. Ce qui reste vrai, et c'est voulu : **la fiche ouverte ne change pas sous les yeux du
soignant** — une aide partagée réécrite à distance en pleine réanimation ne se substitue pas à
celle qu'on déroule ; la nouvelle version arrive à la réouverture.

510 tests × 2 moteurs, 11 harnais verts (dont 27/27 en doctrine), 289 contrôles d'accessibilité.

## [4.41.0] — 2026-07-27
### Phase 3 (optimisation) — premier lot : le seul vrai levier de performance, et deux invariants
La campagne de mesure a couvert six dimensions (démarrage, re-rendus, calcul répété, service
worker, CSS, Web Vitals) sous vérification adversariale. **Le résultat principal est que
l'application est déjà rapide** : 26 « rien à faire » démontrés, 16 constats réfutés, et **un seul**
levier de performance réel. Les chiffres du budget, re-mesurés machine au repos : démarrage 66 ms
(CPU nominal) / 262 ms (×4) ; un parcours clinique complet ne déclenche que 5 `render()` complets ;
`esc()`, appelée 817 fois par rendu, coûte 0,06 ms.

### `transition:width` sur la barre de minuteur → `transform:scaleX()`
`width` est une propriété de **mise en page** : animée en continu, elle force un layout par image.
En session vive avec un minuteur d'intervalle armé et le panneau ouvert, six secondes sans le
moindre geste : **118 layouts/s, 123 recalculs de style/s**, soit 126,8 ms/s de fil principal à CPU
nominal, 206,9 à ×4 et 377,3 à ×6 — **jusqu'à 38 % d'un cœur brûlés pendant toute une réanimation**,
sans qu'aucun JS ne s'exécute.

Mesuré après application, sur le fichier réel contre un témoin `width` réinjecté :
115,0 → **11,4** ms/s (×1), 193,5 → **18,2** (×4), 248,0 → **25,9** (×6) ; 115 → **2** layouts/s.
WebKit, hors CDP : **+9,7 %** de débit utile du fil principal.

Un arbitrage annoncé n'a finalement pas eu lieu d'être. Deux vérificateurs divergeaient sur ce que
rend `scaleX` — l'un mesurait ~120 recalculs de style/s résiduels, ce qui aurait obligé à choisir
entre performance et rendu. L'A/B rejoué à trois variantes (actuel / `scaleX` / sans transition),
servies en mémoire, tranche : **17 recalculs/s**, l'animation est bien composée, et `scaleX` rend
autant que supprimer l'animation *sans changer le rendu*. Le gain est de la **marge CPU et de
l'autonomie**, pas de la fluidité (120 fps et latence de cochage identiques) — ne pas le vendre
autrement.

Rendu vérifié au pixel, et la première sonde était fausse : elle mesurait un minuteur **en marche**,
donc une cible mouvante (le « 0 % » relevait `scaleX(0.9912)` — le minuteur avait rebouclé). Refaite
à minuteur figé : géométrie identique à 0,01 px près, et la comparaison des captures ne diffère que
sur **une colonne de 4 px** — l'anticrénelage du bord mobile, écart max 73/255 — plus les deux
extrémités arrondies à 100 % (≤ 9/255). Identique dans les deux thèmes. Une source unique `barTf()`
sert le gabarit ET le tick : deux formats seulement équivalents (`scaleX(0.76)` vs `scaleX(0.7600)`)
feraient échouer la comparaison anti-churn et réécriraient le style 3,3 fois par seconde. Vérifié :
17 écritures en 5 s pour ~16,7 passages du tick, soit une par tick.

### Garde-fou `scripts/check-anim.mjs`, dans `npm run check`
Aucune propriété de mise en page dans un `transition` ni dans un `@keyframes`. La règle était déjà
respectée partout ailleurs (19 keyframes sur 19) — c'est le profil exact d'une règle qu'un seul oubli
trahit sans que rien ne le signale. Une exemption, motivée : `.skiplink` (glissement de 120 ms une
fois par focus ; le convertir mettrait en jeu une position dépendant d'`env(safe-area-inset-top)`,
soit un risque d'accessibilité pour un gain nul). Le contrôle a été **vérifié capable d'échouer**
(défaut réintroduit, message juste, fichier restauré à l'octet) — leçon v4.31.1 : un garde-fou qui
ne peut pas échouer ne prouve rien.

### `touch-action:manipulation` sur les étapes cochables
AGENTS.md § Interactif énonce que « tous les contrôles » le portent. Mesuré en session vive à
390×844 : **5 cibles en `touch-action:auto`** sur « Anaphylaxie », 3 sur « Arrêt cardiaque » — les
`li[role="checkbox"]` du parcours, que la règle de base ne couvrait pas alors que
`li.md-task[role="checkbox"]` (protocoles) le posait déjà. Après : **0**, sur Chromium et WebKit.
Le gain n'est pas un délai de tap — le délai de ~350 ms n'existe plus pour un viewport
`width=device-width`, et le commentaire qui l'affirmait encore avait servi à justifier de ne pas
étendre la règle : il est corrigé. Ce que le réglage évite est le **zoom parasite** quand deux taps
tombent à moins de ~40 px l'un de l'autre — 12 px mesurés entre deux étapes voisines, et en
réanimation on coche des étapes voisines à la chaîne.

### Un minuteur échu ne peignait pas son état sur les rangées compactes
Trouvé par la sonde du point précédent. `.tm-mini` (rangée compacte d'un minuteur ad hoc, le
« ＋ Minuteur PA ») partage l'id `tmcard-<id>` avec la carte pleine, et `syncTimerBtns` bornait son
basculement d'état à `.tmcard`. Mesuré sur **Chromium ET WebKit** : le modèle disait « échu », la
rangée restait NEUTRE tant qu'aucun re-rendu complet ne passait — alors que `.tm-mini.due` est bien
stylée (cadre et encre ambre). L'alarme n'était pas perdue (le quai porte l'ambre, canal
d'acquittement documenté), mais elle manquait là où l'œil se trouve quand le panneau est ouvert.
`paused` reste réservé à la carte pleine : `.tm-mini.paused` n'a pas de règle.

510 tests × 2 moteurs, 11 harnais verts, 289 contrôles d'accessibilité.

## [4.40.0] — 2026-07-26
### Les 4 dernières fenêtres : le harnais d'accessibilité couvre les 20 sur 20
`attPickModal`, `relPickModal`, `reportModal` et `newLibModal` étaient signalées « résistantes » en
v4.39.0. Elles ne résistaient pas : **mes appels étaient faux**. Les vraies signatures sont
`openAttPicker(entity, rerender)`, `openRelPicker(entity, rerender)` et surtout
`exportSessionReport(sessionId)` — un **ID**, pas l'objet session. `openNewLib()` est par ailleurs
gardée par `myIsAppAdmin` : garde métier légitime, dont la vraie barrière est la RLS serveur ; la
sonde la lève pour auditer le RENDU, ce qui est l'objet du harnais.

Le compte-rendu n'est atteignable que par le parcours COMPLET (ouvrir, démarrer, terminer) puisqu'il
lit `sessions`, les sessions **archivées**. C'est en le déroulant qu'un défaut de sonde plus gênant
est apparu.

### Défaut de sonde corrigé : trois fenêtres mesuraient un contexte FACTICE
Les surfaces « historique sessions », « terminer la session » et « complications » posaient
`state.view='read'; state.fiche=f; render()` à la main. Or ce n'est pas le point d'entrée :
`openRead(id)` appelle `buildRuntime` puis `bindStateToRuntime`, sans quoi **le Runtime n'est pas
installé** — le clic sur « démarrer la session » ne démarrait donc rien. Mesuré :
`Runtime.started=false`, `liveSessions=0`, `sessions=0`. Les trois fenêtres s'ouvraient bien, mais
dans un contexte SANS session vive, pas celui que le harnais annonçait ; une régression propre à la
session vive n'aurait pas été vue. Les trois passent par `openRead(f.id)`.

C'est le même travers que le `classList.add('on')` refusé en v4.39.0, en plus discret : reconstruire
un état à la main au lieu d'emprunter le chemin de l'utilisateur. Défaut du harnais, jamais de l'app.

### Résultat
**289 contrôles, 20 fenêtres × 2 thèmes, aucun défaut.** Les 4 dernières fenêtres n'ont rien révélé —
résultat en soi : les corrections de v4.37→v4.39 (associations `for=`, noms de champs, `[hidden]`
impératif, cibles) tenaient déjà sur les surfaces non encore auditées. Les 11 harnais restent verts,
510 tests sur Chromium et WebKit.

## [4.39.0] — 2026-07-26
### Harnais d'accessibilité : de 6 fenêtres auditées à 16 sur 20
Chaque fenêtre est ouverte par son **vrai point d'entrée**, après CONSTRUCTION de son contexte —
session vive pour « Terminer la session » et l'historique, sauvegarde de version pour « Versions
précédentes », complication déclarée pour l'index ⚡, document joint pour la visionneuse PDF. Jamais
un `classList.add('on')` : une fenêtre forcée vide n'a pas le contenu qu'on veut mesurer et
produirait des verdicts faux. Le mécanisme `prep` accepte donc désormais une **fonction**,
sérialisée par Playwright — la mise au point a d'ailleurs confirmé que la CSP du projet **interdit
bien `eval()`** : la première version de la sonde, qui passait du code en chaîne, a été bloquée.

Les 4 dernières (`attPickModal`, `relPickModal`, `reportModal`, `newLibModal`) résistent encore :
leurs points d'entrée attendent des arguments ou un état non reconstitué. Signalé plutôt que
contourné.

### Ce que ces dix fenêtres ont révélé
- **Un faux positif du harnais — corrigé dans le harnais, pas dans l'app.** `#pendToggle` était
  signalé à 13×13 px, sous le seuil de 24. Mais son `<label>` parent fait **358×65 px** et coche la
  case au clic : la CIBLE au sens de WCAG 2.5.8 (« la zone qui accepte l'action du pointeur ») était
  donc largement conforme. Le harnais mesure désormais le label quand il en existe un — même esprit
  que la recherche de l'anneau de focus sur les ancêtres, déjà en place. Agrandir les cases pour
  faire taire ce contrôle aurait été un changement visible pour un défaut inexistant.
- **Mais les cases se LISAIENT mal** (décision utilisateur) : aucune règle du projet ne les
  dimensionnait, elles gardaient les ~13 px du navigateur — dont l'interrupteur de sécurité
  « Exiger une validation pour les nouveaux comptes ». Passées à **20 px** avec
  `accent-color:var(--primary)` : la case cochée prend le bleu de l'app au lieu du bleu système.
  Appliqué aux **quatre** cases de l'app (confirmation, suppression locale, validation des comptes,
  boucle d'un minuteur) — les styler une par une aurait recréé l'incohérence.
- **Le bruit réseau est filtré nommément** : les fenêtres liées au compte interrogent Supabase et
  crient `ERR_INTERNET_DISCONNECTED` hors réseau. C'est le contexte de la sonde, pas un défaut de la
  page ; seul ce motif est filtré, pour ne pas masquer une vraie erreur.

**241/241** contrôles d'accessibilité — contre 121 avant, sur un périmètre deux fois plus étroit.

510 tests × 2 moteurs, 22/22 doctrine, 241/241 accessibilité, 163 contrôles d'audit, 10 sondes.
