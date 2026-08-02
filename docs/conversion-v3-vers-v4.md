# Convertir un export **v3** en **v4** — prompt pour une IA

> **À qui ça sert.** À partir de la version 5.0.0, l'application ne lit plus que le format **v4**.
> Un fichier `.json` exporté par une version 4.x n'est plus importable tel quel. Ce document
> contient un **prompt à copier-coller** dans une IA (Claude, ChatGPT, Gemini…) avec votre fichier :
> elle vous rend un fichier v4 que l'application accepte.
>
> **Pourquoi ce n'est pas dans l'application.** Un convertisseur embarqué serait du code mort dès
> que tout le monde aurait migré — et du code mort dans un logiciel utilisé en urgence vitale est
> une dette qu'on finit par payer. La conversion est un geste **unique**, fait **à froid**, sur un
> fichier : sa place est ici.
>
> **⚠ Avant de commencer.** Exportez vos données depuis votre ancienne version (fenêtre Compte →
> « Exporter mes données ») et **gardez le fichier d'origine**. La conversion ne le modifie pas ;
> en cas de doute, vous pouvez toujours recommencer à partir de lui.
>
> **⚠ Les documents PDF ne passent pas par ici.** S'ils étaient dans un `.zip`, décompressez-le :
> convertissez le `donnees.json`, puis re-zippez-le avec le dossier `documents/` **inchangé**.

---

## Ce qui change, en trois idées

1. **Une étape cesse d'être une chaîne de caractères pour devenir un objet.** En v3, un geste
   s'écrivait `"⚠ Adrénaline IM :: 0,5 mg"` : le registre était un préfixe, la réponse attendue un
   séparateur. En v4 c'est `{ "id": "i7", "do": "Adrénaline IM", "expect": "0,5 mg", "level": 3 }`.
   L'intérêt n'est pas cosmétique : un objet a une **identité**, donc on peut lui accrocher des
   propriétés (`memory`, `dual`) et un compte rendu ne se décale plus quand on insère une ligne.

2. **Les six listes du haut de fiche deviennent des items à rôle.** `confirmation`, `notForget`,
   `verify`, `posology`, `differentials` n'existent plus comme champs : leurs lignes rejoignent le
   **pool `items[]`** avec un `role`. Les blocs ne contiennent plus que des **identifiants**.

3. **Plusieurs champs sont renommés** pour dire ce qu'ils sont, maintenant qu'aides et protocoles
   vivent dans une bibliothèque unique.

---

## Le prompt — à copier-coller intégralement

```text
RÔLE
Tu convertis un fichier d'export de l'application « Aides cognitives » du format v3 vers le
format v4. Tu ne fais QUE convertir : tu ne réécris aucun contenu clinique, tu n'ajoutes rien,
tu ne retires rien, tu ne corriges ni l'orthographe ni la formulation. Si une information n'a
pas de logement en v4, tu la conserves telle quelle plutôt que de la perdre.

ENTRÉE
Un JSON qui commence par {"version": 3, ...} et contient "categories" et "fiches" (et
éventuellement "protocols").

SORTIE
Un JSON, et RIEN d'autre — pas de texte avant, pas de commentaire après, pas de bloc de code.
Il commence par {"version": 4, ...}.

═══ RÈGLE 1 — CHAQUE FICHE DEVIENT UNE « AIDE » ═══

Renommages, à appliquer tels quels :
  libraryId    → library
  validation   → validatedAt
  localInfo    → local
  references   → sources        (métadonnée, PAS un item : ce n'est pas du contenu de crise)
  attachments  → docs
  related      → links
  complications → excursions
Champs inchangés : id, title, discriminant, code, category, images, timers, counters, start,
order, ownerId, updatedBy, updatedAt, deletedAt.

Deux champs s'ajoutent :
  "v": 4
  "kind": "procedure"           (toujours "procedure" pour une fiche ; "reference" est réservé
                                 aux protocoles, voir RÈGLE 6)

Le champ "status" change de vocabulaire :
  ""        → "validated"
  "review"  → "review"
  "draft"   → "draft"

═══ RÈGLE 2 — LES ÉTAPES DEVIENNENT DES ITEMS, DANS UN POOL ═══

L'aide reçoit un tableau "items" à sa racine. Chaque ligne de texte de la v3 y devient un objet :

  { "id": "i1", "role": "do", "do": "…", "expect": "", "level": 1,
    "memory": false, "dual": false, "note": "" }

  · "id"     — invente-le : "i1", "i2", "i3"… dans l'ordre où tu rencontres les lignes.
               UNIQUE dans l'aide. Ne réutilise jamais un id.
  · "role"   — d'où venait la ligne :
               "confirmation"   → role "entry"
               "notForget"      → role "do"  ET  "memory": true
               étapes d'un bloc → role "do"
               "verify"         → role "watch"
               "posology"       → role "dose"
               "differentials"  → role "ddx"
  · "do"     — le texte, DÉBARRASSÉ du préfixe de registre et de la partie après « :: ».
  · "expect" — ce qui suivait « :: », espaces retirés aux deux bouts. "" s'il n'y en avait pas.
  · "level"  — 3 si la ligne commençait par « ⚠ » (ou « ! »), 2 si elle commençait par « △ »,
               sinon 1. Le préfixe DISPARAÎT du texte : il est devenu ce nombre.
  · "memory" — true UNIQUEMENT pour les lignes qui venaient de "notForget". Jamais deviné.
  · "dual"   — TOUJOURS false. La v3 ne pouvait pas l'exprimer, donc la source ne le contient
               pas. Ne l'invente sous aucun prétexte.
  · "note"   — toujours "".

ORDRE DU POOL : d'abord les "confirmation", puis les "notForget", puis les étapes des blocs dans
l'ordre des blocs, puis "verify", puis "posology", puis "differentials". Cet ordre n'a pas
d'importance fonctionnelle mais rend la relecture possible.

Les six champs "confirmation", "notForget", "verify", "posology", "differentials" DISPARAISSENT
de l'aide. ("references" ne disparaît pas : il devient "sources", cf. RÈGLE 1.)

═══ RÈGLE 3 — LES BLOCS NE CONTIENNENT PLUS QUE DES IDENTIFIANTS ═══

  { "id": "b1", "title": "…", "kind": "do", "phase": "",
    "items": ["i5", "i6"], "next": "b2", "image": null, "hors": false }

  · "type": "steps"    → "kind": "do"
  · "type": "decision" → "kind": "decision"
  · "steps": [...]     → "items": [ids des items créés pour ce bloc, dans le MÊME ordre]
  · "phase" — toujours "". La v3 ne l'exprime pas.
  · "hors" — voir RÈGLE 4.
  · Un bloc "decision" garde "question" et "options", et n'a PAS de "items" (tableau vide).
    Chaque option devient { "label": "…", "concl": "", "target": "…" } — "concl" toujours "".
  · "next", "nextLbl", "image" : inchangés.

═══ RÈGLE 4 — « hors » SE CALCULE, IL NE SE DEVINE PAS ═══

Un bloc est "hors": true si AUCUN chemin ne l'atteint depuis "start" — c'est-à-dire s'il n'est
la cible d'aucun "next" et d'aucun "options[].target", en partant de "start" et en suivant les
liens de proche en proche. Ce sont les blocs d'excursion (complications). Tous les autres :
"hors": false.

═══ RÈGLE 5 — LES SESSIONS ═══

Si le fichier contient des sessions, pour chacune :
  ficheId    → aidId
  ficheTitle → aidTitle
  ajoute "aidRev": null        (la révision lue n'est pas connue rétrospectivement — null le DIT,
                                 au lieu d'inventer un numéro)
  "exercise": true  → "mode": "exercise" ; sinon "mode": "clinical". Retire "exercise".
  stepTexts  → texts           (s'il est absent, mets {})
Le reste (checked, verified, vgaps, nav, navSeq, counters, timers, events, startedAt, savedAt,
live, name, id) est INCHANGÉ.

⚠ Les clés de "checked", "verified" et "vgaps" valent "visite:bloc:index" et gardent l'INDEX.
Ne les réécris pas : elles désignent une position dans un bloc, et cette position n'a pas changé.

═══ RÈGLE 6 — LES PROTOCOLES ═══

Un protocole devient une aide de "kind": "reference". Il garde "body" (son texte markdown),
"title", "code", "category", et subit les MÊMES renommages que la règle 1. Il n'a ni "items",
ni "blocks", ni "start".

═══ CE QU'IL NE FAUT SURTOUT PAS FAIRE ═══

· N'INVENTE JAMAIS "dual", "memory" hors des "notForget", "phase", "concl" ou "aidRev". Un champ
  que la source n'exprime pas naît vide ou false. Deviner, ici, c'est écrire du contenu clinique
  à la place de quelqu'un.
· NE CORRIGE RIEN dans les textes : ni orthographe, ni abréviation, ni unité, ni dosage. Une
  ligne « à compléter » reste « à compléter ».
· NE FUSIONNE NI NE DÉDOUBLONNE aucune ligne, même si deux se ressemblent.
· NE CHANGE AUCUN identifiant existant (ids de blocs, de minuteurs, de compteurs, de documents,
  de catégories). Seuls les ids d'ITEMS sont neufs, puisque les items n'existaient pas.
· Si un champ t'est inconnu, RECOPIE-LE tel quel à sa place. Perdre une donnée est pire que
  transporter un champ qu'on ne comprend pas.

═══ VÉRIFICATION AVANT DE RÉPONDRE ═══

Contrôle ces cinq points, et refais si l'un échoue :
 1. Chaque id cité dans un "items" de bloc existe dans le pool "items" de l'aide.
 2. Chaque "next" et chaque "options[].target" est l'id d'un bloc existant, ou null.
 3. Le nombre total d'items = confirmation + notForget + toutes les étapes de blocs + verify
    + posology + differentials de la v3. Aucune ligne perdue, aucune en double.
 4. Aucun "do" ne commence par « ⚠ », « ! » ou « △ », et aucun ne contient « :: ».
 5. La sortie est un JSON valide et commence par {"version": 4.

RÉPONDS UNIQUEMENT PAR LE JSON.
```

---

## Après la conversion

1. Dans l'application (v5), **fenêtre Créer → Importer un fichier**, et choisissez le JSON produit.
2. Ouvrez **une** fiche et vérifiez trois choses : le nombre d'étapes de son premier bloc, la
   présence des repères posologiques, et que le chapeau « Ne pas oublier » contient bien ce qu'il
   contenait avant.
3. **Gardez votre export v3 d'origine** tant que vous n'avez pas fait cette vérification sur
   plusieurs fiches.

Si l'import échoue, c'est presque toujours l'un de ces trois cas : l'IA a ajouté du texte autour
du JSON (supprimez tout ce qui précède `{` et suit `}`), elle a tronqué un fichier trop long
(convertissez fiche par fiche), ou elle a « corrigé » un contenu (recommencez en lui rappelant la
section « CE QU'IL NE FAUT SURTOUT PAS FAIRE »).
