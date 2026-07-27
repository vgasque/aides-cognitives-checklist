# Déploiement en établissement & conformité

Document unique regroupant : le **kit de déploiement** d'une instance partagée (§ 1), le
**statut réglementaire** de l'application (§ 2), un **modèle de fiche de registre RGPD** (§ 3, dont
le **§ 3.1 détaille tout ce que le partage de session fait sortir de l'appareil**), un **modèle de
conditions d'utilisation** (§ 4) et l'**annexe** sur le calcul de doses, fonctionnalité
volontairement écartée (§ 5).

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
1. Copier tout le dépôt (au minimum : `index.html`, `sw.js`, `manifest.webmanifest`, les icônes,
   `vendor/pdfjs/`). Les fichiers de développement (`scripts/`, `tests.html`, `.github/`,
   `package.json`) peuvent rester : ils ne sont pas servis à l'utilisateur final. Le dépôt est la
   **seule forme servie** (pas d'étape de build) : la racine se déploie telle quelle.
2. Publier en **HTTPS**. Attention : les protections diffèrent selon l'hébergeur, car le fichier
   `_headers` fourni (CSP, HSTS, anti-iframe, `no-cache` sur `sw.js`) est une convention
   **Netlify / Cloudflare Pages** — **GitHub Pages l'ignore totalement**.

   | | GitHub Pages | Netlify / Cloudflare Pages |
   |---|---|---|
   | Mise en place | Settings → Pages → branche `main`, racine | glisser-déposer le dossier |
   | CSP | balise `<meta>` d'`index.html` seulement | `<meta>` **et** en-tête HTTP (`_headers`) |
   | HSTS, `nosniff`, anti-iframe (`X-Frame-Options`) | ✗ non appliqués | ✓ appliqués |
   | `Cache-Control: no-cache` sur `sw.js` | ✗ (cache ~10 min par défaut) | ✓ appliqué |
   | `Cache-Control: no-cache` sur `/` et `/index.html` | ✗ non appliqué | ✓ appliqué |
   | `Referrer-Policy` | ✓ via la balise `<meta name="referrer">` | ✓ en-tête **et** balise |

   Les deux hébergent l'app correctement — l'essentiel de la sécurité (échappement du contenu,
   politiques RLS) est dans le code et côté serveur — mais **Netlify / Cloudflare Pages offrent la
   posture complète**. Sur GitHub Pages, accepter explicitement la perte des en-têtes HTTP
   ci-dessus (la mise à jour du service worker reste fonctionnelle : les navigateurs revérifient
   `sw.js` au plus tard toutes les 24 h).

   **DÉCISION DATÉE (2026-07-27).** La production est **GitHub Pages**, et l'application doit
   **rester déployable ailleurs** (Netlify, Cloudflare Pages, intranet hospitalier HTTPS). Deux
   conséquences pratiques, à ne pas « simplifier » plus tard :

   - `_headers` est **maintenu à jour bien qu'inappliqué en production**. Il n'est pas décoratif :
     c'est la posture servie sur tout autre hébergeur, et le supprimer ferait perdre le seul
     endroit où elle est écrite. Il a reçu en v4.43.0 `Cross-Origin-Opener-Policy` et
     `Cross-Origin-Resource-Policy` (`same-origin` — sans risque, `window.open` étant absent du
     code) et une `Permissions-Policy` étendue à 21 capacités. **COEP `require-corp` est
     délibérément absent** : il n'apporte rien ici et casserait au premier ajout de ressource
     externe. Trois capacités restent **volontairement ouvertes** et ne doivent pas être fermées
     par zèle — `autoplay` (le bip d'alarme passe par WebAudio, le fermer rendrait l'alarme
     muette), `screen-wake-lock` (besoin plausible en réanimation) et `web-share` (chemin
     obligatoire du téléchargement PDF en PWA installée). Le détail est commenté dans `_headers`.
   - **`"id": "./"` du manifeste NE DOIT PAS ÊTRE MODIFIÉ.** Par spécification, `id` se résout
     par rapport à l'**origine**, pas au chemin du manifeste : sur un déploiement en
     sous-répertoire (`<compte>.github.io/<dépôt>/`), l'identité vaut donc l'origine entière.
     C'est une **porte à sens unique** : changer `id` ferait apparaître l'app comme une NOUVELLE
     application chez tout utilisateur l'ayant déjà installée — donc un doublon sur l'écran
     d'accueil, l'ancienne installation restant figée sur son propre cache. Contrainte qui en
     découle, à respecter : **ne pas héberger une seconde PWA sur la même origine**. Un
     déploiement sur une autre origine (Netlify, intranet) est en revanche sans problème :
     l'identité y vaut cette origine-là.

   **Conséquence du `no-cache` manquant sur la PAGE.** Le service worker sert l'application
   « cache d'abord » et rafraîchit sa copie en arrière-plan ; ce rafraîchissement suppose que son
   `fetch` atteigne le SERVEUR. Servi depuis un cache HTTP intermédiaire, il peut ramener une
   copie périmée et la réécrire dans le cache hors-ligne — une nouvelle version met alors plus
   longtemps à arriver. Ce n'est pas une panne (la publication suivante corrige d'elle-même), mais
   c'est la raison pour laquelle `_headers` pose `no-cache` sur `/` et `/index.html` autant que
   sur `sw.js`.
3. Ouvrir l'URL : l'app doit se charger et proposer « Installer l'app ».

> **Risque résiduel assumé (défense en profondeur).** L'architecture monofichier impose une CSP
> avec `script-src 'unsafe-inline'` : la CSP ne peut donc PAS servir de second rempart contre le
> XSS — toute la protection repose sur l'échappement systématique (`esc()`) et l'assainissement
> des imports (`migrate` / `migrateProtocol` / `sanitizeCats`), maintenus par des tests. Comme les
> jetons de session Supabase (accès **et** rafraîchissement) vivent en `localStorage`, une faille
> XSS non couverte vaudrait un vol de session durable. Conséquences pratiques : (a) ne jamais
> relâcher la discipline `esc()` / garde-fous `safe*` lors d'une évolution ; (b) préférer un
> hébergeur qui applique `_headers` (les en-têtes HTTP durcissent le reste de la posture).
> **Durcissement en place (v4.1.1)** : `release.sh` calcule à chaque version les hashs SHA-256 des
> deux `<script>` inline (`scripts/csp-hashes.mjs`) et les injecte dans la CSP (`<meta>` **et**
> `_headers`). Un hash étant présent, les navigateurs CSP niveau 2+ **ignorent `'unsafe-inline'`**
> et n'exécutent QUE ces scripts : un `<script>` ou un handler `on*=` injecté est bloqué
> (`'unsafe-inline'` reste comme repli pour les très vieux navigateurs — dégradation douce).
> `style-src 'unsafe-inline'` demeure (attributs `style=` non hachables, portée moindre). Deux
> points RLS mineurs à connaître, sans impact en l'état :
> `is_approved()` considère un compte **authentifié** sans ligne `user_status` comme approuvé
> (choix délibéré, évite une panne de synchro silencieuse — mais elle refuse depuis la v4.49.0 le
> rôle `anon` **et** les JWT anonymes, pour qui ce laxisme n'a jamais été voulu), et la politique de
> LECTURE des pièces jointes partagées (`att_lib_read`) ne réapplique pas la regex de nom stricte de
> l'écriture.

### 1.2 Créer le projet Supabase
1. Créer un compte sur supabase.com, **New project**, région **UE (Francfort)** conseillée.
2. Page *Security* à la création : *Enable Data API* **ON**, *Auto-expose new tables* **OFF**,
   *Enable automatic RLS* **ON**.
   **Laisser *Anonymous sign-ins* sur OFF** (valeur par défaut) : l'application n'en a aucun besoin
   — un invité de session partagée passe par des fonctions `security definer`, sans compte ni
   jeton. Le schéma ferme de toute façon la porte depuis la v4.49.0 (`is_approved()` refuse un JWT
   anonyme, qui autrement portait un `auth.uid()` non nul et passait pour un compte approuvé), mais
   une garantie qui repose sur une case décochée ailleurs n'en est pas une : les deux valent mieux
   qu'une.
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
4. **Fonction d'archivage, de consultation et de communication.** Consulter et cocher une
   checklist relève de la documentation et de l'aide-mémoire ; la transmettre à un collègue
   présent relève de la communication. Ni l'une ni l'autre n'est une aide à la décision
   individualisée.

> Analogie MDCG 2019-11 : un logiciel qui se contente de *stocker, archiver, communiquer ou
> effectuer une recherche simple* n'est pas un dispositif médical. C'est le cas ici.

#### Le cas du partage de session en direct (v4.46.0 → v4.49.0)

Fonctionnalité récente, et **première à faire sortir un état de session de l'appareil** : elle
mérite d'être passée à la grille explicitement plutôt que couverte par analogie.

- **Aucune sortie individualisée n'est créée.** Le partage ne calcule rien : il **recopie** un état
  (cases cochées, minuteurs, position dans l'algorithme, heures) d'un écran à l'autre. Aucune règle
  ne s'exécute sur le contenu, aucun seuil, aucune interprétation. Un évènement transmis est une
  référence — clé d'étape, identifiant de minuteur — et une heure.
- **Aucune donnée de patient n'est introduite.** Le format transmis ne comporte **aucun champ de
  texte** ; ce n'est pas un filtrage mais une propriété de structure, ce qui la rend vérifiable
  (tests unitaires sur `shareDiff`, liste blanche appliquée côté serveur). Le libellé qu'un
  utilisateur écrirait sur un repère de son journal n'est **pas** dans le format et reste sur son
  appareil.
- **Qualification MDCG 2019-11** : *communiquer* — au sens propre, un relais transitoire entre deux
  écrans de la même équipe, purgé après usage. Le logiciel ne traite pas les données au bénéfice
  d'un patient individuel ; il les transporte entre deux professionnels qui, eux, soignent.

**L'argument contraire, et pourquoi il ne prospère pas.** On pourrait soutenir qu'un dispositif qui
affiche à un second soignant « ce qui a été fait » influence sa conduite, donc participe à la
décision. L'objection prouve trop : elle vaudrait pour un tableau blanc, une feuille de surveillance
ou une transmission orale. Ce qui distingue le dispositif médical n'est pas l'influence, c'est le
**traitement** — l'application ne dérive, n'agrège ni n'interprète : elle montre à B ce que A a
coché. La ligne à ne pas franchir reste la même que partout ailleurs dans ce document : le jour où
le partage **calculerait** quelque chose (un score d'équipe, une alerte « étape omise depuis
n minutes », une recommandation de reprise), il faudrait rouvrir la qualification. Signaler qu'une
étape n'est pas cochée **parce que l'utilisateur l'a demandé** reste de l'affichage ; la déclencher
seule, sur un seuil temporel, serait autre chose.

**Précaution de rédaction, à conserver.** Ne jamais présenter le partage comme un outil de
*supervision* ou de *contrôle de qualité des soins* : ce vocabulaire suggère une évaluation par le
logiciel. Le vocabulaire retenu dans l'application — « suivre la session », « savoir qui a fait
quoi », « compte rendu », « débriefing » — décrit une trace, pas un jugement.

### Ce qui ferait BASCULER l'app en dispositif médical (à éviter, ou à assumer)
Toute fonctionnalité produisant une **recommandation ou un calcul individualisé** :

- **Calcul de doses** à partir d'un poids/âge saisi (voir l'annexe § 5 : mis de côté précisément
  pour cette raison).
- Scores cliniques calculés (Glasgow, qSOFA…) avec interprétation.
- Alertes déclenchées par des valeurs patient saisies.
- Toute logique « si tel paramètre patient alors telle conduite » évaluée par le logiciel.
- **Sur le partage de session** : toute alerte que le logiciel déclencherait **de lui-même** à
  partir de l'état partagé — « étape non cochée depuis n minutes », score d'adhérence, suggestion
  de reprise. Recopier un état est de la communication ; en tirer une conclusion ne l'est plus.

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
| **Catégories de personnes** | Professionnels de santé utilisateurs (comptes) ; **participants d'une session partagée, avec ou sans compte** (cf. § 3.1). **Aucun patient.** |
| **Catégories de données** | Adresse e-mail professionnelle (compte) ; contenu des fiches rédigées ; préférences (thème, épingles) ; horodatages de sessions. **Pour une session partagée** : identifiant opaque de participant, rôle déclaré, horodatages des gestes, références d'étapes / minuteurs / compteurs, projection de la fiche (cf. § 3.1). **Aucune donnée identifiante de patient.** |
| **Données sensibles** | Aucune donnée identifiante de patient n'est saisie ni transmise. Nuance à porter au DPO plutôt qu'à taire : le déroulé d'une session décrit des **actes de soin** et peut être rapproché d'une prise en charge par ceux qui y étaient. C'est précisément pourquoi (a) aucun texte libre ne circule, (b) la notice affichée à tout participant demande de n'inscrire aucune information identifiante, (c) le serveur ne conserve rien (§ 3.1). |
| **Destinataires** | Membres des bibliothèques partagées (contenu d'équipe) ; **les autres participants d'une session partagée, pour la durée de cette session** ; sous-traitants techniques (ci-dessous) |
| **Sous-traitants** | Supabase (hébergement base + auth, **et relais des sessions partagées**) ; Brevo (envoi des e-mails de code) ; hébergeur statique [GitHub/Netlify/Cloudflare/intranet] |
| **Transferts hors UE** | À éviter : choisir la région UE (Francfort) pour Supabase. Vérifier la localisation de l'hébergeur statique. |
| **Durée de conservation** | Comptes : tant qu'actif ; suppression à la demande (fonction intégrée « Supprimer mon compte »). Fiches partagées : durée d'exploitation de la bibliothèque. **Sessions : sur l'appareil, sans durée fixée par l'application** (l'utilisateur les supprime depuis l'historique). **Session partagée sur le serveur : purgée automatiquement 30 min après son expiration** (§ 3.1) — c'est un relais, pas un entrepôt. |
| **Droits des personnes** | Accès/rectification : via l'app. Effacement : « Supprimer mon compte » (efface fiches, catégories personnelles, **partages ouverts et leurs évènements**, puis le compte). Contact DPO pour les autres droits. |
| **Mesures de sécurité** | HTTPS ; isolation des données par politiques RLS (serveur) ; authentification par code e-mail à usage unique ; CSP par hashs et en-têtes de sécurité ; aucune dépendance tierce chargée ; pas de traceur/analytics. **Partage** : secret propre à chaque participant tiré côté serveur (seul son SHA-256 est stocké), code d'appariement consommé à la première jointure, fenêtre d'admission de 120 s, liste blanche serveur des champs de fiche, plafonds de taille et de nombre, purge auto-exécutoire. |
| **Analyse d'impact (AIPD)** | A priori non requise (pas de donnée identifiante de patient, pas de traitement à grande échelle de données sensibles). **À reconfirmer avec le DPO depuis l'ajout du partage de session**, qui fait sortir de l'appareil des données décrivant des actes de soin. |

**Notes.** Le point déterminant pour le RGPD : **l'application ne traite pas de données de
patients**. Les seules données personnelles sont celles des **professionnels utilisateurs**
(e-mail + contenu qu'ils produisent + trace de leur participation à une session) ; veiller à ce que
cela reste vrai. La fonction « Supprimer mon compte » couvre le droit à l'effacement pour l'espace
personnel ; les contributions à des bibliothèques partagées restent (contenu collectif) — à
mentionner dans l'information des utilisateurs.

### 3.1 Partage de session en direct — ce qui sort de l'appareil, précisément

> Cette sous-section existe parce qu'une affirmation générale ne suffit pas à un DPO. Tout ce qui
> suit est vérifiable dans [`supabase/schema.sql`](../supabase/schema.sql) (section « partage de
> session ») et dans les fonctions `shareSnap` / `shareDiff` d'`index.html`.

**Rappel de ce que c'est.** Un soignant ouvre le partage de la session qu'il déroule ; un collègue
**présent auprès de lui** rejoint avec un code à 8 caractères montré à l'écran, et voit la même
checklist se remplir. Ce n'est **pas** un partage d'aide cognitive (les bibliothèques partagées font
cela, avec adhésions et RLS) : la portée est **une** session, elle meurt avec elle, et l'invité ne
conserve rien.

**Trois catégories de données, et rien d'autre.**

| Ce qui part | Contenu exact | Pourquoi |
|---|---|---|
| **La projection de la fiche** | **14 champs, liste blanche appliquée par le serveur** : `id`, `title`, `code`, `status`, `validation`, `blocks` (images retirées), `start`, `timers`, `counters`, `confirmation`, `verify`, `notForget`, `differentials`, `posology` | L'invité doit voir la checklist. Sont **retirés** : les images (jusqu'à plusieurs Mo de base64), les documents joints, les références, et surtout `localInfo` — pré-rempli « Tél renfort / Tél régulation ». Une fiche au statut **brouillon** ne peut pas être partagée. |
| **Les gestes, comme des références** | Clé d'étape (`visite:bloc:index`), identifiant de minuteur ou de compteur et sa valeur, position dans l'algorithme, horodatage. Un repère du journal voyage comme **{identifiant, heure}** — son libellé, s'il en a un, **reste sur l'appareil de celui qui l'a écrit** | C'est le journal **référentiel** : chaque appareil rend le mot depuis **sa** copie de la fiche. **Aucun texte libre ne traverse le réseau** — non par filtrage, mais parce qu'aucun champ de texte n'entre dans le format transmis. |
| **L'identité d'un participant** | Un identifiant **opaque** tiré au hasard par le serveur, le **rôle déclaré** (choisi dans une liste fermée de neuf intitulés — « Médecin », « Interne », « IADE »… — le serveur le borne à 24 caractères), et pour un participant **connecté** son identifiant de compte | L'attribution *est* le contrôle demandé par l'hôte (« savoir ce que l'invité a modifié ») et elle alimente le compte rendu de débriefing. Un invité **sans compte** n'a ni compte ni adresse : rien de plus que le rôle qu'il a choisi. |

**Durées, mesurées et non déclaratives.**

| | Valeur |
|---|---|
| Fenêtre d'admission d'un code | **120 s**, armée par un geste de l'hôte ; le code est **consommé** à la première jointure |
| Durée de vie d'un partage | **3 h par défaut**, bornée à 10 min – 12 h ; « Terminer » ramène l'expiration à l'instant même |
| Purge du serveur | **30 min après l'expiration**, en cascade (partage → participants → évènements) |
| Déclenchement de la purge | **au début de chaque appel** au serveur — l'hébergement étant statique, une purge planifiée n'aurait personne pour la lancer, et une durée annoncée sans mécanisme serait fausse au registre |
| Plafonds | 5 partages vivants par compte ; 1 à 8 participants (3 par défaut) ; 2 Mio pour la fiche, 4 Kio par évènement |

**Deux précisions que le DPO doit avoir, et qu'une lecture rapide du schéma ne donne pas.**

1. **Le contrôle d'accès des invités ne repose pas sur la RLS**, mais sur la possession d'un secret.
   Les trois tables ont la sécurité au niveau ligne activée — et leurs politiques ne visent que
   l'hôte authentifié. Les invités n'ont **aucun privilège de table** ; ils passent exclusivement
   par trois fonctions `security definer` (`share_join`, `share_pull`, `share_push`), qui
   s'exécutent avec les droits de leur propriétaire et échappent donc, par construction, aux
   politiques. C'est la **seule surface non authentifiée** de toute l'installation, et c'est
   délibéré : un invité sans compte n'a pas de jeton. Les gardes internes de ces trois fonctions
   sont donc le contrôle d'accès réel, et toute modification de leur corps est une modification
   de sécurité.
2. **« Couper un participant » retire l'écriture, pas la lecture.** Le serveur refuse ses écritures
   et lui répond `status: revoked` ; c'est **son application** qui gèle alors son écran. Un client
   modifié pourrait continuer à lire les évènements jusqu'à l'expiration du partage. La formulation
   affichée à l'hôte est exacte sur ce point (« lui retire l'écriture immédiatement ») et ne doit
   pas être élargie. *Ce point est identifié comme à durcir côté serveur.*

**Ce qui ne sort jamais.** Le compte rendu de session reste **local**, sur l'appareil de chaque
participant. Un invité **sans compte** ne dépose rien sur son appareil : le stockage bascule en
mémoire, aucun service worker n'est installé, aucun stockage permanent n'est demandé. Un invité
**connecté** ne voit ni sa bibliothèque, ni ses catégories, ni son historique modifiés.

**Ce que l'application dit aux participants.** Avant de rejoindre, tout invité lit une notice
(article 13) qui nomme le responsable (« le soignant qui vous a montré le code — lui, ou son
établissement »), ce qui est enregistré, la finalité, la base légale, la durée, les autres
destinataires, et le fait que **ce qui a déjà été relevé reste dans le compte rendu de l'hôte : un
enregistrement de soin ne s'efface pas rétroactivement**. Le registre de l'établissement doit rester
**cohérent avec ce texte** — s'il évolue, les deux évoluent ensemble.

**Le point à trancher avec le DPO.** L'application ne peut pas nommer le responsable de traitement
d'une session partagée : elle ne connaît ni le soignant ni son établissement, et le dit
explicitement à l'invité. Dans un déploiement d'établissement, **c'est l'établissement qui est
responsable** et il lui revient de porter cette information par ses propres voies (charte, note de
service). En usage individuel, le soignant l'est pour lui-même.

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

**4.5 bis Partage de session en direct.** L'utilisateur qui ouvre un partage **décide de faire
sortir de son appareil** l'état de la session en cours (cases cochées, minuteurs, position,
horodatages) vers les participants qu'il admet. Il en reste **responsable** : c'est lui, ou son
établissement, que l'information de l'article 13 désigne aux invités. Le partage est **transitoire**
— il expire, puis le relais est purgé (§ 3.1) ; il ne donne accès **ni à la bibliothèque, ni aux
autres sessions, ni aux documents** de l'hôte. **Aucune information permettant d'identifier un
patient ne doit être inscrite**, ni dans la fiche, ni dans le journal d'actions. Ce que chaque
participant a relevé demeure dans les comptes rendus déjà constitués : un enregistrement de soin ne
s'efface pas rétroactivement.

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
