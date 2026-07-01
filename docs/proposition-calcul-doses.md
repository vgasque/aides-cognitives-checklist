# Proposition (mise de côté) — calcul de doses pédiatriques

> **Statut : NON développé, volontairement.** Ce document décrit une piste d'implémentation pour
> mémoire. Avant toute réalisation, lire `docs/statut-non-dm.md` : un calcul de dose à partir de
> données d'un patient ferait très probablement basculer l'application dans la catégorie
> **dispositif médical** (MDR 2017/745), avec les obligations correspondantes (classification,
> marquage CE, système de management de la qualité, matériovigilance). C'est un choix stratégique,
> pas seulement technique.

## Besoin
En pédiatrie / SMUR, la source d'erreur la plus fréquente est le calcul de dose au poids, sous
stress. Un outil qui, à partir d'un poids, afficherait les doses/volumes des médicaments d'une
fiche aurait une forte valeur clinique.

## Esquisse fonctionnelle (si un jour assumé réglementairement)
- **Modèle de données** : ajouter à un bloc/étape un champ optionnel `dose` :
  `{ drug, mgPerKg, maxMg, concentration_mgPerMl, round }`. Rétrocompatible (facultatif, géré dans
  `migrate()` comme les autres champs 3.x).
- **Saisie** : un unique champ « Poids (kg) » dans le bandeau du mode crise (jamais d'autre donnée
  patient ; pas de nom, pas d'âge stocké — le poids reste en mémoire de session, non persisté).
- **Rendu** : à côté de l'étape, « Adrénaline 0,15 mg (1,5 mL à 0,1 mg/mL) » calculé et **arrondi
  à un palier sûr**, avec plafond (`maxMg`) et affichage de la formule (traçabilité, détrompage).
- **Sécurité clinique** (indispensable si réalisé) :
  - bornes de poids plausibles, refus hors bornes ;
  - double affichage dose **et** volume, jamais l'un sans l'autre ;
  - arrondis explicites et paliers ; mention « vérifier » systématique ;
  - aucune administration « automatique » : l'outil propose, l'humain vérifie et décide.

## Alternative NON réglementée (piste préférable à court terme)
Plutôt qu'un calcul individualisé, fournir des **tables de doses pré-calculées par tranches de
poids** que l'utilisateur rédige lui-même dans une fiche (texte/tableau). L'app reste un simple
support d'affichage → **hors périmètre dispositif médical**. Moins ergonomique qu'un calcul
dynamique, mais sans bascule réglementaire. C'est l'option compatible avec le positionnement actuel.

## Décision
Fonctionnalité **écartée** pour préserver le statut non-DM de l'application. À réévaluer seulement
si l'établissement décide d'assumer le parcours dispositif médical.
