# Déploiement en établissement & conformité

Document unique regroupant : le **kit de déploiement** d'une instance partagée (§ 1), le
**statut réglementaire** de l'application (§ 2), un **modèle de fiche de registre RGPD** (§ 3),
un **modèle de conditions d'utilisation** (§ 4) et l'**annexe** sur le calcul de doses,
fonctionnalité volontairement écartée (§ 5).

> Les § 2 à 4 sont des documents de travail internes, **non juridiques**. À faire relire par le
> référent qualité / affaires réglementaires / DPO de votre établissement avant tout déploiement.

---

## 1. Kit de déploiement

Guide pas-à-pas pour déployer une instance partagée (synchronisation multi-appareils et
bibliothèques d'équipe). L'usage **sans compte** (100 % local) ne nécessite rien de tout ceci.

### 1.0 Vue d'ensemble
- **Hébergement statique** en HTTPS (GitHub Pages, Netlify, Cloudflare Pages, ou intranet HTTPS).
- **Supabase** (gratuit) : base de données + authentification.
- **Brevo** (gratuit) : envoi des e-mails de code de connexion.

Durée : ~30 min. Aucune compétence serveur avancée requise.

### 1.1 Héberger les fichiers
1. Copier tout le dépôt (au minimum : `index.html`, `sw.js`, `manifest.webmanifest`, les icônes).
   Les fichiers de développement (`scripts/`, `tests.html`, `.github/`, `package.json`) peuvent
   rester : ils ne sont pas servis à l'utilisateur final.
   *Option* : `npm run build` produit dans `dist/` une copie **allégée** (~25 % plus légère à
   charger — commentaires du code retirés, comportement strictement identique) ; déployer alors le
   contenu de `dist/` au lieu de la racine.
2. Publier en **HTTPS**. Attention : les protections diffèrent selon l'hébergeur, car le fichier
   `_headers` fourni (CSP, HSTS, anti-iframe, `no-cache` sur `sw.js`) est une convention
   **Netlify / Cloudflare Pages** — **GitHub Pages l'ignore totalement**.

   | | GitHub Pages | Netlify / Cloudflare Pages |
   |---|---|---|
   | Mise en place | Settings → Pages → branche `main`, racine | glisser-déposer le dossier |
   | CSP | balise `<meta>` d'`index.html` seulement | `<meta>` **et** en-tête HTTP (`_headers`) |
   | HSTS, `nosniff`, anti-iframe (`X-Frame-Options`) | ✗ non appliqués | ✓ appliqués |
   | `Cache-Control: no-cache` sur `sw.js` | ✗ (cache ~10 min par défaut) | ✓ appliqué |

   Les deux hébergent l'app correctement — l'essentiel de la sécurité (échappement du contenu,
   politiques RLS) est dans le code et côté serveur — mais **Netlify / Cloudflare Pages offrent la
   posture complète**. Sur GitHub Pages, accepter explicitement la perte des en-têtes HTTP
   ci-dessus (la mise à jour du service worker reste fonctionnelle : les navigateurs revérifient
   `sw.js` au plus tard toutes les 24 h).
3. Ouvrir l'URL : l'app doit se charger et proposer « Installer l'app ».

> **Risque résiduel assumé (défense en profondeur).** L'architecture monofichier impose une CSP
> avec `script-src 'unsafe-inline'` : la CSP ne peut donc PAS servir de second rempart contre le
> XSS — toute la protection repose sur l'échappement systématique (`esc()`) et l'assainissement
> des imports (`migrate` / `migrateProtocol` / `sanitizeCats`), maintenus par des tests. Comme les
> jetons de session Supabase (accès **et** rafraîchissement) vivent en `localStorage`, une faille
> XSS non couverte vaudrait un vol de session durable. Conséquences pratiques : (a) ne jamais
> relâcher la discipline `esc()` / garde-fous `safe*` lors d'une évolution ; (b) préférer un
> hébergeur qui applique `_headers` (les en-têtes HTTP durcissent le reste de la posture) ;
> (c) une piste de durcissement documentée est de générer, à la publication, les hashs SHA-256 des
> blocs `<script>` inline et de les injecter dans `_headers` pour retirer `'unsafe-inline'` côté
> scripts (Netlify / Cloudflare). Deux points RLS mineurs à connaître, sans impact en l'état :
> `is_approved()` considère un compte sans ligne `user_status` comme approuvé (choix délibéré,
> évite une panne de synchro silencieuse), et la politique de LECTURE des pièces jointes partagées
> (`att_lib_read`) ne réapplique pas la regex de nom stricte de l'écriture.

### 1.2 Créer le projet Supabase
1. Créer un compte sur supabase.com, **New project**, région **UE (Francfort)** conseillée.
2. Page *Security* à la création : *Enable Data API* **ON**, *Auto-expose new tables* **OFF**,
   *Enable automatic RLS* **ON**.
3. SQL Editor → coller le contenu de [`supabase/schema.sql`](../supabase/schema.sql) → **Run**.
4. (Recommandé) SQL Editor → exécuter [`supabase/rls-tests.sql`](../supabase/rls-tests.sql) :
   il doit afficher « ✅ TOUS LES TESTS RLS PASSENT » (il n'écrit rien de définitif).

### 1.3 Configurer l'envoi d'e-mails (Brevo)
1. Compte gratuit sur brevo.com, **vérifier une adresse expéditrice**, générer une **clé SMTP**.
2. Supabase → *Authentication → Emails → SMTP Settings* → *Custom SMTP* :
   hôte `smtp-relay.brevo.com`, port `587`, login + clé Brevo, expéditeur vérifié.
3. *Authentication → Providers → Email* → **désactiver** « Confirm email ».
4. *Authentication → Emails* → modèles **Magic Link** ET **Confirm signup** → insérer le code :
   `<p>Votre code : {{ .Token }}</p>`.

Si vous utilisez un SMTP grand public (ex. **Gmail** : hôte `smtp.gmail.com`, port `587`,
« mot de passe d'application »), l'expéditeur doit être votre propre adresse — les services
type Brevo refusent d'envoyer « au nom » d'un domaine Gmail/Outlook sans domaine vérifié.

**Limiter les abus (OTP/inscriptions).** `handle_new_user()` (`supabase/schema.sql`) masque les
adresses non vérifiées de la liste d'attente admin, mais ce n'est **pas** une limite de débit :
une adresse peut redemander un code indéfiniment tant qu'elle n'est pas confirmée. La seule vraie
protection est côté GoTrue, hors de ce dépôt : Supabase → *Authentication → Rate Limits* (débit
d'envoi d'e-mails, tentatives par IP) — à vérifier/ajuster à chaque déploiement, en particulier si
le SMTP par défaut de Supabase (limité) est remplacé par Brevo.

### 1.4 Relier l'app à Supabase
Dans `index.html`, la constante `SUPA` (`url` + `key` *publishable*) doit pointer vers votre projet
(Settings → API). La clé *publishable* est **publique par conception** (la sécurité vient des
politiques RLS, pas du secret de cette clé).

### 1.5 Se nommer administrateur
1. Ouvrir l'app, **Compte → Recevoir le code**, se connecter une première fois.
2. Supabase → SQL Editor :
   ```sql
   insert into public.app_admins(user_id)
   select id from auth.users where email = 'vous@etablissement.fr';
   ```
3. Rouvrir l'app : vous pouvez créer des bibliothèques partagées, ouvrir « Comptes en attente », et
   l'écran **Compte** affiche l'**état de l'instance** (nombre de comptes, fiches, stockage consommé…).

### 1.6 Gouvernance (au choix)
- **Validation des comptes** : *Compte → Comptes en attente* → activer « Exiger une validation ».
  Chaque nouveau compte reste « en attente » jusqu'à votre approbation.
- **Rôles de bibliothèque** : lecteur (consultation), éditeur (rédaction), admin (gestion des
  membres). Le statut *brouillon* masque une fiche non validée aux lecteurs.

### 1.7 Dépannage
- **Pas d'e-mail de code** : vérifier SMTP Brevo et le modèle *Confirm signup* (pas seulement
  *Magic Link*).
- **« en attente » inattendu** : la validation des comptes est active ; approuver le compte.
- **Le service worker ne s'installe pas** : l'hébergement doit être en HTTPS (ni `file://` ni HTTP).

---

## 2. Statut réglementaire — pourquoi l'application n'est pas un dispositif médical

> Grille de décision : toute évolution de l'application doit être évaluée au regard de ce paragraphe
> **avant** développement.

### Ce qu'est l'application
Un **support de contenu** : elle stocke, affiche et minute des aides cognitives (checklists,
arbres décisionnels) **rédigées et validées par l'utilisateur lui-même**. Elle n'apporte aucune
connaissance médicale propre : livrée sans contenu clinique (hors fiches d'exemple explicitement
« à relire »), elle est équivalente, sur le plan fonctionnel, à un classeur de protocoles papier
plastifié, augmenté de minuteurs et de cases à cocher.

### Pourquoi, en l'état, elle reste hors périmètre « dispositif médical »
Au sens du règlement (UE) 2017/745 (MDR), un logiciel est un dispositif médical s'il a une
**finalité médicale propre** (diagnostic, prévention, prédiction, pronostic, traitement) reposant
sur un traitement des données **au bénéfice d'un patient individuel**. Les éléments suivants
maintiennent l'application en dehors de cette qualification :

1. **Aucune sortie individualisée.** L'app ne calcule rien à partir de données d'un patient
   (pas de dose, pas de score, pas d'alerte conditionnée par des paramètres saisis). Les minuteurs
   et compteurs sont des chronomètres génériques, indépendants de tout patient.
2. **Aucune donnée patient.** L'app n'invite jamais à saisir de données patient et n'en stocke pas
   (aucun champ patient dans le modèle de données).
3. **Contenu sous responsabilité de l'utilisateur.** Le professionnel est l'auteur et le validateur
   du contenu ; l'app le lui rappelle (bandeau, date de validation, statut brouillon/validée).
4. **Fonction d'archivage/consultation.** Consulter et cocher une checklist relève de la
   documentation et de l'aide-mémoire, pas de l'aide à la décision individualisée.

> Analogie MDCG 2019-11 : un logiciel qui se contente de *stocker, archiver, communiquer ou
> effectuer une recherche simple* n'est pas un dispositif médical. C'est le cas ici.

### Ce qui ferait BASCULER l'app en dispositif médical (à éviter, ou à assumer)
Toute fonctionnalité produisant une **recommandation ou un calcul individualisé** :

- **Calcul de doses** à partir d'un poids/âge saisi (voir l'annexe § 5 : mis de côté précisément
  pour cette raison).
- Scores cliniques calculés (Glasgow, qSOFA…) avec interprétation.
- Alertes déclenchées par des valeurs patient saisies.
- Toute logique « si tel paramètre patient alors telle conduite » évaluée par le logiciel.

Si l'une de ces fonctions devient souhaitable, elle doit faire l'objet d'une **évaluation
réglementaire dédiée** (classification, marquage CE, système qualité) **avant** développement.

### Bonnes pratiques à conserver pour rester dans ce cadre
- Ne jamais introduire de saisie de données patient.
- Garder les minuteurs/compteurs génériques (non liés à un patient).
- Maintenir la mention de responsabilité et la date de validation par fiche.
- Documenter toute nouvelle fonctionnalité au regard de la grille ci-dessus (cf. `AGENTS.md`).

---

## 3. Modèle — fiche de registre des activités de traitement (RGPD, art. 30)

> Modèle à adapter puis à intégrer au registre de votre établissement. À faire valider par votre
> DPO (délégué à la protection des données).

| Rubrique | Contenu proposé (à adapter) |
|---|---|
| **Nom du traitement** | Application « Aides cognitives » — support de checklists cliniques |
| **Responsable de traitement** | [Établissement / service], représenté par [nom, fonction] |
| **DPO** | [nom, e-mail] |
| **Finalité** | Mise à disposition et partage d'aides cognitives (checklists) rédigées par les professionnels ; synchronisation multi-appareils optionnelle |
| **Base légale** | Intérêt légitime de l'établissement (organisation des soins) / mission d'intérêt public |
| **Catégories de personnes** | Professionnels de santé utilisateurs (comptes). **Aucun patient.** |
| **Catégories de données** | Adresse e-mail professionnelle (compte) ; contenu des fiches rédigées ; préférences (thème, épingles) ; horodatages de sessions. **Aucune donnée de santé de patient.** |
| **Données sensibles** | Aucune (pas de donnée patient, pas de donnée de santé identifiante) |
| **Destinataires** | Membres des bibliothèques partagées (contenu d'équipe) ; sous-traitants techniques (ci-dessous) |
| **Sous-traitants** | Supabase (hébergement base + auth) ; Brevo (envoi des e-mails de code) ; hébergeur statique [GitHub/Netlify/Cloudflare/intranet] |
| **Transferts hors UE** | À éviter : choisir la région UE (Francfort) pour Supabase. Vérifier la localisation de l'hébergeur statique. |
| **Durée de conservation** | Comptes : tant qu'actif ; suppression à la demande (fonction intégrée « Supprimer mon compte »). Sessions : locales à l'appareil. Fiches partagées : durée d'exploitation de la bibliothèque. |
| **Droits des personnes** | Accès/rectification : via l'app. Effacement : « Supprimer mon compte » (efface fiches et catégories personnelles + le compte). Contact DPO pour les autres droits. |
| **Mesures de sécurité** | HTTPS ; isolation des données par politiques RLS (serveur) ; authentification par code e-mail à usage unique ; CSP et en-têtes de sécurité ; aucune dépendance tierce chargée ; pas de traceur/analytics. |
| **Analyse d'impact (AIPD)** | A priori non requise (pas de donnée de santé de patient, pas de traitement à grande échelle de données sensibles). À confirmer avec le DPO. |

**Notes.** Le point déterminant pour le RGPD : **l'application ne traite pas de données de
patients**. Les seules données personnelles sont celles des **professionnels utilisateurs**
(e-mail + contenu qu'ils produisent) ; veiller à ce que cela reste vrai. La fonction « Supprimer
mon compte » couvre le droit à l'effacement pour l'espace personnel ; les contributions à des
bibliothèques partagées restent (contenu collectif) — à mentionner dans l'information des
utilisateurs.

---

## 4. Modèle — conditions d'utilisation

> Modèle court à adapter et faire valider (référent qualité / juridique).

**4.1 Objet.** L'application « Aides cognitives » met à disposition des professionnels de santé un
outil de consultation et de rédaction d'**aides cognitives** (checklists, arbres décisionnels)
avec minuteurs et compteurs, utilisable hors ligne.

**4.2 Nature de l'outil — responsabilité du contenu.** L'application est un **support** : elle
n'apporte aucune recommandation médicale propre. Le contenu des fiches est **rédigé, vérifié et
validé par les utilisateurs eux-mêmes**. Chaque utilisateur reste **seul responsable** de
l'exactitude, de la mise à jour et de l'usage des fiches. L'outil ne remplace ni le jugement
clinique, ni les recommandations et protocoles en vigueur.

**4.3 Absence de données patient.** L'application ne doit **jamais** servir à saisir ou stocker
des données de patients. Les fiches sont des aides génériques. Les minuteurs et compteurs sont des
outils de chronométrage sans lien avec un patient identifié.

**4.4 Comptes et données personnelles.** La création d'un compte (facultative, pour la
synchronisation) nécessite une adresse e-mail professionnelle. Le traitement des données est décrit
dans la fiche de registre RGPD de l'établissement (§ 3). L'utilisateur peut supprimer son compte à
tout moment depuis l'application.

**4.5 Bibliothèques partagées.** Le contenu ajouté à une bibliothèque partagée constitue un
**contenu d'équipe** : il reste accessible aux membres même après le départ d'un contributeur. Les
rôles (lecteur, éditeur, admin) déterminent les droits ; le statut « brouillon » masque une fiche
non validée aux lecteurs.

**4.6 Disponibilité et limites.** L'application fonctionne hors ligne (les données sont d'abord
stockées sur l'appareil). La synchronisation dépend de services tiers (hébergeur, Supabase, Brevo)
et peut être temporairement indisponible sans que l'usage local en soit affecté.

**4.7 Sécurité.** L'accès aux données est protégé côté serveur (isolation par politiques de
sécurité). L'utilisateur s'engage à protéger l'accès à son compte et à son appareil.

**4.8 Évolutions.** Ces conditions peuvent être mises à jour ; la version en vigueur est celle
publiée avec l'application. Contact : [référent / e-mail].

---

## 5. Annexe — calcul de doses pédiatriques (proposition écartée)

> **Statut : NON développé, volontairement.** Cette annexe décrit une piste d'implémentation pour
> mémoire. Avant toute réalisation, relire le § 2 : un calcul de dose à partir de données d'un
> patient ferait très probablement basculer l'application dans la catégorie **dispositif médical**
> (MDR 2017/745), avec les obligations correspondantes (classification, marquage CE, système de
> management de la qualité, matériovigilance). C'est un choix stratégique, pas seulement technique.

### Besoin
En pédiatrie / SMUR, la source d'erreur la plus fréquente est le calcul de dose au poids, sous
stress. Un outil qui, à partir d'un poids, afficherait les doses/volumes des médicaments d'une
fiche aurait une forte valeur clinique.

### Esquisse fonctionnelle (si un jour assumé réglementairement)
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

### Alternative NON réglementée (piste préférable à court terme)
Plutôt qu'un calcul individualisé, fournir des **tables de doses pré-calculées par tranches de
poids** que l'utilisateur rédige lui-même dans une fiche (texte/tableau). L'app reste un simple
support d'affichage → **hors périmètre dispositif médical**. Moins ergonomique qu'un calcul
dynamique, mais sans bascule réglementaire. C'est l'option compatible avec le positionnement actuel.

### Décision
Fonctionnalité **écartée** pour préserver le statut non-DM de l'application. À réévaluer seulement
si l'établissement décide d'assumer le parcours dispositif médical.
