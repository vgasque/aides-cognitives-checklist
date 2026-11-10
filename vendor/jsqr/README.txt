Décodeur de codes QR — jsqr 1.4.0 (build UMD « dist/jsQR.js », non minifié par l'amont)

  jsQR.js (256885 octets)

Source  : https://unpkg.com/jsqr@1.4.0/dist/jsQR.js (paquet npm « jsqr », dépôt cozmo/jsQR)
Licence : Apache-2.0
Rôle    : lire les codes QR d'appariement et de synchro optique du partage sans serveur
          (lot v5.14 — l'encodeur reste maison ; seul le DÉCODAGE, hors de portée d'une
          implémentation raisonnable, est vendorisé — décision explicite de l'auteur,
          17/08/2026, sur le modèle pdf.js).
Chargé  : PARESSEUSEMENT (injection <script> au premier scan — jamais au démarrage),
          exposé en window.jsQR.
Cache   : dans ASSETS (sw.js), donc dans le cache PRINCIPAL versionné par APP_VERSION —
          contrairement à pdf.js, une mise à jour part avec la publication qui la porte :
          le piège « clé de cache inchangée » ne peut pas se produire ici.
Mise à jour = décision explicite (AGENTS.md § « Mettre à jour un actif vendorisé ») :
vérifier l'amont et ses avis de sécurité, remplacer le fichier, METTRE À JOUR la taille
ci-dessus (check-vendor compare l'octet), rejouer le témoin encode→décode et le test
hors-ligne complet sur appareil DÉJÀ INSTALLÉ.
SHA-256 (identique au paquet npm jsqr 1.4.0, verifie le 10/11/2026 ; compare par check-vendor) :
  jsQR.js sha256 bc40c8a15196236b2314db0856f72ca0b49980cd5413b8c852a7349f5fee0859
