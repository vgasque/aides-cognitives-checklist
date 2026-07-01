# Statut réglementaire — pourquoi l'application n'est pas un dispositif médical

> Document de travail interne, non juridique. À faire relire par le référent qualité / affaires
> réglementaires de votre établissement avant tout déploiement. Il sert de **grille de décision**
> pour évaluer chaque évolution.

## Ce qu'est l'application
Un **support de contenu** : elle stocke, affiche et minute des aides cognitives (checklists,
arbres décisionnels) **rédigées et validées par l'utilisateur lui-même**. Elle n'apporte aucune
connaissance médicale propre : livrée sans contenu clinique (hors deux fiches d'exemple
explicitement « à relire »), elle est équivalente, sur le plan fonctionnel, à un classeur de
protocoles papier plastifié, augmenté de minuteurs et de cases à cocher.

## Pourquoi, en l'état, elle reste hors périmètre « dispositif médical »
Au sens du règlement (UE) 2017/745 (MDR), un logiciel est un dispositif médical s'il a une
**finalité médicale propre** (diagnostic, prévention, prédiction, pronostic, traitement) reposant
sur un traitement des données **au bénéfice d'un patient individuel**. Les éléments suivants
maintiennent l'application en dehors de cette qualification :

1. **Aucune sortie individualisée.** L'app ne calcule rien à partir de données d'un patient
   (pas de dose, pas de score, pas d'alerte conditionnée par des paramètres saisis). Les minuteurs
   et compteurs sont des chronomètres génériques, indépendants de tout patient.
2. **Aucune donnée patient.** L'app n'invite jamais à saisir de données patient et n'en stocke pas
   (cf. `prompt-IA-creation-fiche.md` et le présent dépôt : aucun champ patient).
3. **Contenu sous responsabilité de l'utilisateur.** Le professionnel est l'auteur et le validateur
   du contenu ; l'app le lui rappelle (bandeau, date de validation, statut brouillon/validée).
4. **Fonction d'archivage/consultation.** Consulter et cocher une checklist relève de la
   documentation et de l'aide-mémoire, pas de l'aide à la décision individualisée.

> Analogie MDCG 2019-11 : un logiciel qui se contente de *stocker, archiver, communiquer ou
> effectuer une recherche simple* n'est pas un dispositif médical. C'est le cas ici.

## Ce qui ferait BASCULER l'app en dispositif médical (à éviter, ou à assumer)
Toute fonctionnalité produisant une **recommandation ou un calcul individualisé** :

- **Calcul de doses** à partir d'un poids/âge saisi (voir `docs/proposition-calcul-doses.md` : mis
  de côté précisément pour cette raison).
- Scores cliniques calculés (Glasgow, qSOFA…) avec interprétation.
- Alertes déclenchées par des valeurs patient saisies.
- Toute logique « si tel paramètre patient alors telle conduite » évaluée par le logiciel.

Si l'une de ces fonctions devient souhaitable, elle doit faire l'objet d'une **évaluation
réglementaire dédiée** (classification, marquage CE, système qualité) **avant** développement.

## Bonnes pratiques à conserver pour rester dans ce cadre
- Ne jamais introduire de saisie de données patient.
- Garder les minuteurs/compteurs génériques (non liés à un patient).
- Maintenir la mention de responsabilité et la date de validation par fiche.
- Documenter toute nouvelle fonctionnalité au regard de la grille ci-dessus (cf. `CLAUDE.md`).
