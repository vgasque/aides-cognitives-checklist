# Aides cognitives — application PWA hors ligne

Base de données d'aides cognitives cliniques **personnalisable**, que vous rédigez et
modifiez vous-même. Hors ligne, installable, avec images/captures, checklists
conditionnelles (décisions « si oui → liste A, si non → liste B »), catégories colorées
éditables, aperçu automatique de l'algorithme, et un poste de minuteurs/compteurs/sessions
pour l'usage en temps réel.

## Ce que fait l'application (vue d'ensemble)
- **Deux natures de contenu**, dans une seule bibliothèque : les **aides cognitives**
  (parcours à cocher, en blocs d'étapes et de décisions) et les **protocoles** (textes de
  référence en mini-Markdown, avec documents PDF joints — visionneuse intégrée, sommaire,
  recherche dans les PDF).
- **Mode crise (session)** : étapes CRITIQUE / VIGILANCE annoncées en mots, réponse attendue,
  minuteurs et compteurs (une coche peut lancer un minuteur ou compter), moment d'une étape
  (« à partir de n chocs », « à chaque échéance »), complications « à tout moment » avec retour
  au passage interrompu, revue « à tout moment » (ex. causes réversibles), journal horodaté,
  vues **Se repérer**, **Page** (l'algorithme entier, imprimable en PDF), **Schéma** et
  **Moniteur** ; mode **Exercice** et **exercice guidé** sur les aides d'exemple.
- **Partage de session en direct** entre appareils (en ligne, en direct sur le réseau local,
  ou « par l'écran » par QR codes) — miroir sans texte libre, jamais bloquant.
- **Rangement** : catégories (par bibliothèque, couleur), **collections** personnelles (une aide
  peut être dans plusieurs), Accès direct, filtres et tris de l'accueil, sélection multiple.
- **Équipes** (optionnel, avec compte) : bibliothèques partagées à rôles, demandes de
  bibliothèque, page **Administration** pour l'administrateur de l'instance.

Code réalisé avec Claude AI.

> Vous êtes l'auteur et le responsable du contenu clinique. Validez chaque fiche avec
> les recommandations en vigueur et tenez la date de validation à jour.

## Contenu du dépôt
- `index.html` — **toute l'application** (HTML + CSS + JS vanille, sans dépendance) ;
- `sw.js`, `manifest.webmanifest`, `icon-*.png` — service worker (hors ligne) et installation PWA ;
- `exemples/` — aides d'exemple prêtes à importer ;
- `supabase/` — schéma et tests de sécurité (RLS) de la synchronisation optionnelle ;
- `CHANGELOG.md` — les 20 dernières versions ; `docs/changelog/vN.md` — l'archive, une par
  version majeure ;
- `docs/deploiement-et-conformite.md` — kit de déploiement en établissement + statut
  réglementaire (non-DM), modèles RGPD et conditions d'utilisation ;
- `docs/decisions/` — la doctrine détaillée du projet (décisions numérotées A1…, par lot) ;
  l'index de navigation est dans `docs/README.md` ;
- `AGENTS.md` — instructions pour les contributeurs (humains ou IA) ; `CLAUDE.md` l'importe ;
- `vendor/` — les deux seules bibliothèques embarquées (pdf.js, jsQR — vendorisées, chargées
  paresseusement) et les polices ;
- `design/` — le design system généré depuis `index.html` (`npm run design:build`) ;
- `_headers`, `wrangler.jsonc`, `.assetsignore` — en-têtes de sécurité et déploiement
  Cloudflare Workers Assets (la production) ;
- `tests.html`, `scripts/`, `release.sh` — tests et outillage de publication.

Les fichiers de l'application (`index.html`, `sw.js`, manifest, icônes) doivent rester ensemble
dans le même dossier.

## Minuteurs, compteurs & sessions (temps réel)
- L'éditeur d'une fiche permet de définir des **chronomètres**, des **minuteurs à cycle**
  programmables (ex. 2 min « analyse du rythme ») qui bouclent, comptent les cycles et alertent
  (son + vibration + flash), et des **compteurs** (ex. nombre de doses).
- En mode crise, ces outils vivent dans un **rail à droite** de la checklist (écrans larges)
  ou un panneau repliable au-dessus (écrans étroits), avec un **journal d'horodatage** des
  actions (libellés renommables, même a posteriori). On peut aussi lancer un **minuteur
  ponctuel** (« ＋ Minuteur ») sans modifier la fiche.
- La **session** (étapes cochées, parcours, compteurs, temps/cycles, horodatages) s'enregistre
  automatiquement, en local, par appareil ; on peut la reprendre, la terminer, en tirer un
  **compte-rendu** imprimable.

## Créer une aide avec une IA
Le dialogue « Créer » fait d'abord choisir le type (**Aide cognitive** ou **Protocole**), puis
propose de rédiger soi-même, **« Rédiger avec l'IA à partir d'un document »** (aides seulement :
un prompt type à copier dans une IA — ChatGPT, Claude… — en y joignant un PDF, une image ou une
recommandation ; l'IA renvoie un fichier JSON), ou **« Importer un fichier (.json ou .zip) »**.
Toute aide créée ou importée arrive en statut **Brouillon** : relisez-la toujours avant usage.

## Aides d'exemple (`exemples/`)
Deux aides sont proposées à la première ouverture à la première ouverture (« Anaphylaxie (choc
anaphylactique) », « Arrêt cardiaque (ACR) — algorithme »). Le dossier `exemples/` en fournit deux autres à importer
(dialogue « Créer » → « Importer un fichier » ; l'import d'une seule aide fusionne, ne remplace
jamais la bibliothèque) :
- `accouchement-inopine-prehospitalier.json` — accouchement inopiné en pré-hospitalier (SMUR) ;
- `etat-de-mal-epileptique.json` — état de mal épileptique de l'adulte (urgences).

⚠️ **À relire et valider avant tout usage clinique** : contenu volontairement générique, marqué
« brouillon », à adapter à vos protocoles et aux recommandations en vigueur.

## Installer comme application (PWA)
Ouvrez l'adresse où l'application est servie, puis « Installer l'app »
(iPhone : Safari → Partager → Sur l'écran d'accueil).

La production de l'auteur est servie sur **Cloudflare Workers Assets** (configuration :
`wrangler.jsonc` + `.assetsignore`) à l'adresse `https://aides.gasque.fr/`.

Pour héberger la vôtre : mode installable + hors ligne complet = hébergement **https** (le service
worker ne fonctionne ni en fichier local ni en http simple) : Cloudflare (Workers Assets ou
Pages), GitHub Pages, Netlify, ou intranet https. ⚠ **Les données sont stockées par ORIGINE**
(IndexedDB) : changer
d'adresse plus tard repart d'une bibliothèque vide sur chaque appareil déjà installé — choisissez
l'adresse définitive avant de diffuser (détail : `docs/deploiement-et-conformite.md`, § 1.1).

Sans hébergement, ouvrir `index.html` suffit : l'app fonctionne et enregistre vos fiches ; seuls
l'installation et le cache automatique demandent l'https.

## Données & synchronisation
Par défaut, tout est stocké **localement, par appareil** : l'application fonctionne entièrement
hors-ligne et **sans compte**. Pour transférer sans cloud : « Exporter mes données »
(dans « Moi ») puis dialogue « Créer » → « Importer un fichier » sur l'autre appareil — toute la
bibliothèque, une sélection (accueil → Sélectionner → « Exporter la sélection… ») ou une seule aide (menu ⋯).
Avec des PDF joints, l'export peut être un `.zip` « avec documents ». (Les sessions ne sont pas
incluses dans l'export.)

**Synchronisation multi-appareils (optionnelle).** En vous connectant (**Moi** → Compte), votre
bibliothèque personnelle devient accessible sur tous vos appareils, avec des **bibliothèques
partagées** d'équipe (rôles lecteur/éditeur/admin). Le principe reste **local-first** : IndexedDB
demeure la source de vérité, le cloud n'est qu'un miroir, et la synchro ne bloque jamais l'usage.
En cas de modification concurrente, la version la plus récente s'applique et **la précédente est
conservée** (« Versions » dans le menu ⋯ de l'aide).

L'activation nécessite une configuration unique (Supabase + Brevo, ~30 min, gratuite) : suivre le
**kit de déploiement** dans [`docs/deploiement-et-conformite.md`](docs/deploiement-et-conformite.md).

## Note son
La première alerte sonore nécessite une interaction (démarrer un minuteur) pour activer l'audio du
navigateur. Un bouton 🔔/🔕 coupe le son. Sur iPhone en mode silencieux, l'alarme peut être
inaudible : le flash d'écran sert d'alerte de secours.

## Développement
- **Publier une version** : `./release.sh X.Y.Z` synchronise les numéros de version (index.html +
  sw.js + package.json + package-lock.json), recalcule les hashs CSP et vérifie syntaxe/tests ; le rédacteur (humain ou IA) complète ensuite le
  CHANGELOG et committe avec les notes de version. Ne jamais modifier le numéro à la main (voir `AGENTS.md`).
- **Tests** : `npm test` (Playwright headless) ou ouvrir `tests.html` **servi en http**
  (`python3 -m http.server` puis `http://localhost:8000/tests.html`). `npm run check` enchaîne
  les **27 garde-fous statiques** (syntaxe, couleurs, classes, échelles typographique et
  d'espacement, service worker, SQL, CHANGELOG, lexique, guide, hashs CSP…) ; `npm run audit`
  rejoue les **23 harnais** de mesure (accessibilité, doctrine, partage, surfaces).
- **Contribuer avec une IA** : `AGENTS.md` donne les quinze règles, la méthode de recherche
  dans la doctrine (`docs/decisions/`) à suivre avant toute modification, et la procédure de
  commit. L'intégration continue
  (`.github/workflows/ci.yml`) rejoue check + `design:check` + tests à chaque push, et l'audit en
  mode indicatif (non bloquant).

## Sécurité & confidentialité
- **Aucune dépendance externe** : un seul fichier HTML en JavaScript « vanille », sans CDN. Deux
  bibliothèques seulement sont **embarquées** dans le dépôt (pdf.js pour les PDF, jsQR pour les QR
  du partage), avec les polices ; chargées paresseusement, servies par la même origine. Rien n'est
  chargé depuis un autre domaine.
- **Content-Security-Policy stricte** (`index.html` et `_headers`) : `default-src 'self'`, seules
  les connexions vers votre projet Supabase sont autorisées, `object-src 'none'`. Nota : le fichier
  `_headers` est appliqué par la production Cloudflare (Workers Assets), comme par Netlify et
  Cloudflare Pages ; GitHub Pages l'ignore et seule la CSP de la balise `<meta>` s'y applique
  (comparatif : `docs/deploiement-et-conformite.md`, § 1.1).
- **Contenu importé neutralisé** : tout JSON importé ou reçu du cloud est nettoyé (échappement
  HTML systématique, identifiants et couleurs validés, images limitées) — un fichier piégé ne peut
  pas exécuter de code.
- **Isolation des données côté serveur** : imposée par les politiques RLS de Supabase, jamais par
  le navigateur. La clé `key` (publishable) dans `index.html` est **publique par conception**.
- **Connexion sans mot de passe** : code à usage unique par e-mail (OTP).

## Données personnelles (RGPD)
- **Par défaut, tout reste sur l'appareil** (IndexedDB) : rien n'est envoyé tant que vous ne créez
  pas de compte. La synchro cloud est **facultative**.
- **Suppression du compte** intégrée (efface aides, protocoles et catégories **personnels**, les partages ouverts, puis le compte ;
  les contributions aux bibliothèques **partagées** restent, contenu d'équipe).
- **Hébergement UE** possible (région Supabase Francfort conseillée).
- **Ne saisissez aucune donnée patient** : les aides sont génériques.
- Modèles de registre RGPD et de conditions d'utilisation : voir
  [`docs/deploiement-et-conformite.md`](docs/deploiement-et-conformite.md).

## Limites connues
- **Navigateur récent requis** (IndexedDB, `fetch`, service worker).
- **Conflits en « dernière écriture gagne »** : pas de fusion champ par champ ; la version écrasée
  reste récupérable (« Versions »).
- **Grandes bibliothèques** : affichage par pages (« Afficher plus ») ; la recherche reste
  instantanée.
- **Version** : le numéro affiché au pied de l'accueil (`APP_VERSION`) et le cache de `sw.js`
  sont tenus synchronisés par `release.sh` — ne pas les modifier à la main.
