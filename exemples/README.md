# Fiches d'exemple

Fiches prêtes à importer, pour démarrer et voir la structure attendue.

⚠️ **À relire et valider avant tout usage clinique.** Ces fiches sont volontairement **génériques**
et marquées « brouillon » : le contenu doit être vérifié et adapté à vos protocoles et aux
recommandations en vigueur. Vous restez l'auteur et le responsable du contenu.

## Importer
Dans l'application : bouton **« Importer »** (en bas) → choisir un fichier `.json` ci-dessous.
L'import **fusionne** avec votre bibliothèque (ne remplace rien pour un import d'une seule fiche).

## Contenu
- `last-toxicite-anesthesiques-locaux.json` — Toxicité systémique des anesthésiques locaux (LAST).
- `hemorragie-post-partum.json` — Hémorragie du post-partum (HPP).

Deux autres exemples (« Anaphylaxie peropératoire » et « Arrêt cardiaque ») sont déjà créés
automatiquement à la première ouverture de l'application.

## Format
Ces fichiers suivent le schéma d'export JSON `version: 3` (voir
[`prompt-IA-creation-fiche.md`](../prompt-IA-creation-fiche.md) pour générer vos propres fiches
via une IA). Les champs non renseignés prennent des valeurs par défaut à l'import.
