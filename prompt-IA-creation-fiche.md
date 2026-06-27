# Prompt type — Générer une fiche importable à partir d'un document

Copiez le bloc ci-dessous dans une IA (ChatGPT, Claude, etc.) **en y joignant** votre
source : un PDF, une image/capture, ou le texte d'une recommandation. L'IA renvoie un
fichier JSON que vous **enregistrez avec l'extension `.json`** puis importez dans
l'application (bouton **Importer**).

> Rappel : vous restez l'auteur et le responsable du contenu clinique. Relisez la fiche
> générée, vérifiez les doses/seuils par rapport à la source, et tenez la date de
> validation à jour. L'IA ne doit rien inventer qui ne figure pas dans le document.

---

## Le prompt (à copier tel quel, avec votre document)

```
RÔLE
Tu es un assistant qui transforme un document médical (recommandation, protocole,
algorithme, chapitre, image/capture) en une « aide cognitive » de crise, destinée à
être consultée pendant une situation critique (anesthésie / urgences / réanimation)
pour ne rien oublier. Principe : la bonne information, au bon endroit, au bon moment.

TÂCHE
À partir du document que je te fournis, produis UNIQUEMENT un objet JSON valide,
conforme au schéma ci-dessous, prêt à être enregistré en .json et importé dans mon
application. N'ajoute aucun texte avant ou après le JSON, aucune balise Markdown,
aucun commentaire, aucune virgule finale.

EXIGENCES DE FOND
- Langue : français. Style des étapes : phrases courtes, à l'impératif, actionnables.
- Fidélité absolue à la source : n'invente aucune dose, seuil, ni médicament absent du
  document. Si une information manque, laisse un champ vide plutôt que de l'inventer.
- Structure l'arbre de prise en charge en BLOCS :
  - bloc « steps » = liste d'étapes cochables, menant éventuellement à un bloc suivant ;
  - bloc « decision » = une question avec des options, chaque option pointant vers un
    autre bloc (branchement « si oui → A, si non → B »).
  - Une option/`next` peut renvoyer vers un bloc précédent (boucle de réévaluation).
- Mets dans :
  - confirmation = critères qui confirment le diagnostic / déclenchent la fiche ;
  - verify       = points à vérifier (accès, monitorage, prélèvements…) ;
  - notForget    = pièges et points critiques à ne pas oublier ;
  - differentials= diagnostics différentiels ;
  - references   = source(s) précise(s) du document (titre, société savante, année).
- timers / counters : seulement s'ils ont un sens (ex. cycle de réévaluation, nombre
  de bolus). Sinon, tableaux vides.
- images : toujours [] (j'ajouterai les schémas moi-même dans l'application).
- category : "" (je classerai la fiche après import). Laisse "categories": [].

ERGONOMIE DE L'ALGORITHME (conception d'aide cognitive de crise, esprit SFAR / SFMU)
- Une étape = UNE seule action concrète, commençant par un verbe à l'impératif
  ("Administrer…", "Appeler…", "Vérifier…"). Pas de paragraphe ni de phrase longue.
- Ordre = priorité clinique réelle et chronologique : sécuriser d'abord (ABC, appel à
  l'aide), puis traitement de 1re intention SANS délai, puis 2e intention, puis surveillance.
- Place tôt l'APPEL À L'AIDE et la répartition des rôles ; mets en tête les gestes qui
  sauvent et le plus time-critical (ex. adrénaline si anaphylaxie, MgSO4 si éclampsie) —
  ne les enfouis pas dans la liste.
- Doses, voies et débits explicites et VÉRIFIABLES (ex. "MgSO4 4 g IV sur 20 min").
- Chaque étape doit être COCHABLE en situation (fais-le / vérifie-le) : évite les étapes
  vagues, non actionnables ou non vérifiables.
- Réserve les blocs « decision » aux VRAIS points de bifurcation (si récidive -> …), pas
  pour enchaîner une simple séquence.
- Quand la prise en charge est cyclique, crée une BOUCLE DE RÉÉVALUATION : un bloc de
  surveillance dont le « next » renvoie vers la décision de réévaluation, et associe un
  minuteur de cycle (timer interval, autoloop).
- Limite la charge cognitive : titres de blocs courts, listes ramassées, une idée par ligne.
- Répartition : confirmation = critères diagnostiques déclenchant la fiche ; verify = ce qui
  doit être contrôlé/monitoré ; notForget = pièges et points critiques (détrompage) ;
  differentials = diagnostics différentiels.

COHÉRENCE DES IDENTIFIANTS (très important)
- Chaque bloc a un "id" unique au sein de la fiche (ex. "b1", "b2", "bd").
- "start" doit être l'id d'un bloc existant.
- Pour un bloc "steps", "next" est l'id d'un bloc existant ou null.
- Pour un bloc "decision", chaque "target" d'option est l'id d'un bloc existant.
- Ne mets PAS de champ "id" au niveau de la fiche (il sera généré à l'import).

SCHÉMA EXACT
{
  "version": 3,
  "categories": [],
  "fiches": [
    {
      "title": "Titre de la situation",
      "category": "",
      "validation": "AAAA-MM",                // période de validation/parution
      "localInfo": "Numéros utiles, particularités locales (laisse un gabarit à compléter)",
      "confirmation": ["…"],
      "verify": ["…"],
      "notForget": ["…"],
      "differentials": ["…"],
      "references": ["…"],
      "images": [],
      "timers": [
        { "id": "t1", "label": "Temps écoulé", "type": "stopwatch" },
        { "id": "t2", "label": "Cycle de réévaluation", "type": "interval", "seconds": 180, "autoloop": true }
      ],
      "counters": [
        { "id": "n1", "label": "Bolus", "step": 1, "start": 0 }
      ],
      "start": "b1",
      "blocks": [
        { "id": "b1", "type": "steps",    "title": "Mesures immédiates", "image": null, "steps": ["…", "…"], "next": "bd" },
        { "id": "bd", "type": "decision", "title": "Réévaluation", "image": null, "question": "…?", "options": [ { "label": "Oui", "target": "b2" }, { "label": "Non", "target": "b3" } ] },
        { "id": "b2", "type": "steps",    "title": "Évolution favorable", "image": null, "steps": ["…"], "next": null },
        { "id": "b3", "type": "steps",    "title": "Réfractaire", "image": null, "steps": ["…"], "next": "bd" }
      ]
    }
  ]
}

VALEURS AUTORISÉES
- type d'un bloc : "steps" ou "decision" (exactement).
- type d'un timer : "stopwatch" (chronomètre) ou "interval" (minuteur à cycle).
  Pour "interval" : "seconds" = durée du cycle, "autoloop" = true pour reboucler.
- "validation" au format "AAAA-MM" (ex. "2025-06").

AVANT DE RÉPONDRE, VÉRIFIE
1. Le JSON est strictement valide (pas de virgule finale, guillemets droits).
2. "start" et tous les "next"/"target" pointent vers des "id" de blocs réellement présents.
3. Aucune donnée patient. Aucune dose inventée.
4. Tu n'as renvoyé QUE le JSON.
```

---

## Après génération

1. Enregistrez la réponse de l'IA dans un fichier `ma-fiche.json`.
2. Dans l'application → **Importer** → choisissez ce fichier.
   - L'import d'une seule fiche **fusionne** toujours (il n'écrase jamais votre bibliothèque).
   - En cas d'identifiant déjà présent, l'app propose de remplacer ou de garder les deux.
3. Ouvrez la fiche, **relisez-la**, ajoutez la catégorie, les images/schémas, et ajustez
   le contexte local et la date de validation.
