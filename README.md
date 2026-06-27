# Aides cognitives — application PWA hors ligne

Base de données d'aides cognitives cliniques **personnalisable**, que vous rédigez et
modifiez vous-même. Hors ligne, installable, avec images/captures, checklists
conditionnelles (décisions « si oui → liste A, si non → liste B »), catégories colorées
éditables, aperçu automatique de l'algorithme, et un poste de minuteurs/compteurs/sessions
pour l'usage en temps réel.

Code réalisé avec Claude AI.

## Contenu de l'archive
- index.html — l'application
- sw.js — service worker (hors ligne)
- manifest.webmanifest — app installable
- icon-192.png, icon-512.png, icon-512-maskable.png, apple-touch-icon.png — icônes
- prompt-IA-creation-fiche.md — prompt type pour générer une fiche via une IA

Gardez tous les fichiers ensemble dans le même dossier.

## Minuteurs, compteurs & sessions (temps réel)
- Dans une fiche, l'éditeur permet de définir des **chronomètres** (compte le temps
  écoulé), des **minuteurs à cycle** programmables (ex. 2 min « analyse du rythme »,
  3 min « adrénaline ») qui se relancent en boucle, comptent les cycles et alertent
  (son + vibration + flash), et des **compteurs** (ex. nombre de doses).
- En mode crise, ces outils apparaissent dans un bandeau en haut de la fiche.
- **Horodatage des actions** : un bouton permet de marquer instantanément chaque action
  avec un libellé renommable (même a posteriori).
- **Enregistrer la session** sauvegarde l'état complet (étapes cochées, parcours,
  compteurs, temps écoulé/cycles, horodatages). On peut la **rouvrir et reprendre** ou la
  **supprimer** depuis la fiche. Les sessions sont stockées localement, par appareil.

## Créer une fiche avec une IA
Le bouton « ✨ Créer via IA » (en bas) ouvre un prompt type à copier dans une IA
(ChatGPT, Claude…) en y joignant un PDF, une image ou une recommandation. L'IA renvoie un
fichier JSON que vous importez ensuite (bouton « Importer »). Le prompt est aussi fourni
dans [prompt-IA-creation-fiche.md](prompt-IA-creation-fiche.md). Relisez toujours la fiche
générée avant usage.

## Installer comme application (PWA)
Mode installable + hors ligne complet = hébergement **https** (le service worker ne
fonctionne ni en fichier local ni en http simple) :
1. GitHub Pages — fichiers à la racine d'un dépôt, activez Pages.
2. Netlify / Cloudflare Pages — glissez-déposez le dossier, URL https immédiate.
3. Intranet de l'établissement en https.

Ouvrez l'URL, puis « Installer l'app » (iPhone : Safari → Partager → Sur l'écran d'accueil).

## Sans hébergement
Ouvrez index.html : l'app fonctionne hors ligne et enregistre vos fiches. Seuls
l'installation et la mise en cache automatique nécessitent l'https.

## Données & synchronisation
Tout est stocké localement, par appareil. Pas de synchronisation automatique entre
appareils : utilisez Exporter / Importer (JSON, en bas) pour sauvegarder et transférer
iPhone ↔ ordinateur. On peut exporter **toute la bibliothèque** ou **une seule fiche**
(depuis la fiche). (Les sessions ne sont pas incluses dans l'export, étant liées à un
usage en cours sur l'appareil.)

## Note son
La première alerte sonore nécessite une interaction (démarrer un minuteur) pour activer
l'audio du navigateur. Un bouton 🔔/🔕 permet de couper le son. Sur iPhone, si le
téléphone est en mode silencieux l'alarme sonore peut ne pas être audible (le flash
d'écran sert d'alerte de secours).

> Vous êtes l'auteur et le responsable du contenu clinique. Validez chaque fiche avec
> les recommandations en vigueur et tenez la date de validation à jour.
