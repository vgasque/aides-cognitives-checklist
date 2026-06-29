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
Par défaut, tout est stocké **localement, par appareil** : l'application fonctionne
entièrement hors-ligne et **sans compte**. Pour transférer sans cloud, utilisez
Exporter / Importer (JSON, en bas) : **toute la bibliothèque** ou **une seule fiche**
(depuis la fiche). (Les sessions ne sont pas incluses dans l'export.)

**Synchronisation multi-appareils (optionnelle).** En vous connectant (bouton **Compte**),
votre bibliothèque personnelle devient accessible sur tous vos appareils. Le principe reste
**local-first** : IndexedDB demeure la source de vérité, le cloud n'est qu'un miroir ;
l'application reste pleinement utilisable hors-ligne, et la synchro se fait en arrière-plan
sans jamais interrompre l'usage. En cas de modification concurrente sur deux appareils, la
version la plus récente est appliquée et **la précédente est conservée** (bouton « Versions »
dans la fiche, pour comparer/restaurer). L'activation requiert une configuration unique
décrite ci-dessous.

## Activer la synchronisation (installation, une seule fois)
La synchro s'appuie sur **Supabase** (base + authentification, offre gratuite) et un service
d'envoi d'e-mails **Brevo** (gratuit) pour les codes de connexion. À faire une fois par le
responsable de l'instance :

1. **Créer un projet Supabase** (région UE/Francfort conseillée). À l'écran *Security* :
   *Enable Data API* coché, *Auto-expose new tables* **décoché**, *Enable automatic RLS* coché.
2. **Exécuter le schéma** : SQL Editor → coller le contenu de [`supabase/schema.sql`](supabase/schema.sql) → Run.
   (Crée les tables, la sécurité par ligne *RLS*, les rôles et les bibliothèques partagées.)
3. **Brancher l'envoi d'e-mails (Brevo)** — nécessaire pour recevoir les codes de connexion :
   - Créer un compte gratuit sur brevo.com, **vérifier une adresse expéditrice** (un e-mail à
     vous suffit, aucun domaine requis), puis générer une **clé SMTP** (menu *SMTP & API*).
   - Dans Supabase → *Authentication → Emails → SMTP Settings* → activer **Custom SMTP** :
     hôte `smtp-relay.brevo.com`, port `587`, login et clé SMTP Brevo, adresse expéditrice vérifiée.
   - Désactiver *Authentication → Providers → Email → « Confirm email »* (pour une connexion par
     code, saisir le code prouve déjà la possession de l'adresse ; évite l'e-mail de confirmation).
   - Puis *Authentication → Emails → modèles « Magic Link » **et** « Confirm signup »* : insérer le
     code de connexion avec la variable `{{ .Token }}` (ex. `<p>Votre code : {{ .Token }}</p>`).
   - Si vous utilisez un SMTP grand public (ex. **Gmail** : hôte `smtp.gmail.com`, port `587`,
     « mot de passe d'application »), l'expéditeur doit être votre propre adresse — les services
     type Brevo refusent d'envoyer « au nom » d'un domaine Gmail/Outlook sans domaine vérifié.
4. **Renseigner les identifiants dans l'app** : dans `index.html`, la constante `SUPA`
   (`url` + `key` *publishable*, publique par conception) pointe vers votre projet.
5. **Se nommer administrateur** (pour créer des bibliothèques partagées) : se connecter une fois
   dans l'app, puis exécuter le petit `insert into app_admins …` indiqué en bas de `schema.sql`.

Côté utilisateur, il suffit ensuite d'ouvrir l'app, **Compte → Recevoir le code**, saisir le
code reçu par e-mail. Sécurité : l'isolation des données (espace personnel vs bibliothèques
partagées, rôles lecture/édition) est imposée **côté serveur** par les politiques RLS, jamais
par le navigateur.

## Note son
La première alerte sonore nécessite une interaction (démarrer un minuteur) pour activer
l'audio du navigateur. Un bouton 🔔/🔕 permet de couper le son. Sur iPhone, si le
téléphone est en mode silencieux l'alarme sonore peut ne pas être audible (le flash
d'écran sert d'alerte de secours).

> Vous êtes l'auteur et le responsable du contenu clinique. Validez chaque fiche avec
> les recommandations en vigueur et tenez la date de validation à jour.
