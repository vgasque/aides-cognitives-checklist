# Kit de déploiement en établissement

Guide pas-à-pas pour déployer une instance partagée (synchronisation multi-appareils et
bibliothèques d'équipe). L'usage **sans compte** (100 % local) ne nécessite rien de tout ceci.

## 0. Vue d'ensemble
- **Hébergement statique** en HTTPS (GitHub Pages, Netlify, Cloudflare Pages, ou intranet HTTPS).
- **Supabase** (gratuit) : base de données + authentification.
- **Brevo** (gratuit) : envoi des e-mails de code de connexion.
Durée : ~30 min. Aucune compétence serveur avancée requise.

## 1. Héberger les fichiers
1. Copier tout le dépôt (au minimum : `index.html`, `sw.js`, `manifest.webmanifest`, les icônes).
   Les fichiers de développement (`scripts/`, `tests.html`, `.github/`, `package.json`) peuvent
   rester : ils ne sont pas servis à l'utilisateur final.
2. Publier en **HTTPS** :
   - **GitHub Pages** : dépôt → Settings → Pages → source = branche `main`, dossier racine.
   - **Netlify / Cloudflare Pages** : glisser-déposer le dossier ; le fichier `_headers` fourni
     applique automatiquement la CSP et les en-têtes de sécurité.
3. Ouvrir l'URL : l'app doit se charger et proposer « Installer l'app ».

## 2. Créer le projet Supabase
1. Créer un compte sur supabase.com, **New project**, région **UE (Francfort)** conseillée.
2. Page *Security* à la création : *Enable Data API* **ON**, *Auto-expose new tables* **OFF**,
   *Enable automatic RLS* **ON**.
3. SQL Editor → coller le contenu de [`supabase/schema.sql`](../supabase/schema.sql) → **Run**.
4. (Recommandé) SQL Editor → exécuter [`supabase/rls-tests.sql`](../supabase/rls-tests.sql) :
   il doit afficher « ✅ TOUS LES TESTS RLS PASSENT » (il n'écrit rien de définitif).

## 3. Configurer l'envoi d'e-mails (Brevo)
1. Compte gratuit sur brevo.com, **vérifier une adresse expéditrice**, générer une **clé SMTP**.
2. Supabase → *Authentication → Emails → SMTP Settings* → *Custom SMTP* :
   hôte `smtp-relay.brevo.com`, port `587`, login + clé Brevo, expéditeur vérifié.
3. *Authentication → Providers → Email* → **désactiver** « Confirm email ».
4. *Authentication → Emails* → modèles **Magic Link** ET **Confirm signup** → insérer le code :
   `<p>Votre code : {{ .Token }}</p>`.

## 4. Relier l'app à Supabase
Dans `index.html`, la constante `SUPA` (`url` + `key` *publishable*) doit pointer vers votre projet
(Settings → API). La clé *publishable* est **publique par conception** (la sécurité vient des
politiques RLS, pas du secret de cette clé).

## 5. Se nommer administrateur
1. Ouvrir l'app, **Compte → Recevoir le code**, se connecter une première fois.
2. Supabase → SQL Editor :
   ```sql
   insert into public.app_admins(user_id)
   select id from auth.users where email = 'vous@etablissement.fr';
   ```
3. Rouvrir l'app : vous pouvez créer des bibliothèques partagées, ouvrir « Comptes en attente », et
   l'écran **Compte** affiche l'**état de l'instance** (nombre de comptes, fiches, stockage consommé…).

## 6. Gouvernance (au choix)
- **Validation des comptes** : *Compte → Comptes en attente* → activer « Exiger une validation ».
  Chaque nouveau compte reste « en attente » jusqu'à votre approbation.
- **Rôles de bibliothèque** : lecteur (consultation), éditeur (rédaction), admin (gestion des
  membres). Le statut *brouillon* masque une fiche non validée aux lecteurs.

## 7. Conformité (voir modèles fournis)
- [`docs/statut-non-dm.md`](statut-non-dm.md) — pourquoi l'app n'est pas un dispositif médical.
- [`docs/rgpd-registre-modele.md`](rgpd-registre-modele.md) — modèle de fiche de registre RGPD.
- [`docs/cgu-modele.md`](cgu-modele.md) — modèle de conditions d'utilisation.

## Dépannage
- **Pas d'e-mail de code** : vérifier SMTP Brevo et le modèle *Confirm signup* (pas seulement
  *Magic Link*).
- **« en attente » inattendu** : la validation des comptes est active ; approuver le compte.
- **Le service worker ne s'installe pas** : l'hébergement doit être en HTTPS (ni `file://` ni HTTP).
