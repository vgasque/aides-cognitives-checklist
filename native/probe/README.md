# Sonde du lot 0 — ce qui a été MESURÉ, et ce qui ne l'est pas encore

Mesures du **5 août 2026**, sur `index.html` v5.1.2 servi tel quel, macOS 26.5 / WebKit du système,
Xcode 26.6. Rejouer :

```bash
swiftc -O -o /tmp/acprobe native/probe/main.swift -framework WebKit -framework AppKit
/tmp/acprobe "$PWD"
```

La sonde sert le **vrai monofichier** sous `aidescog://app/` via un `WKURLSchemeHandler`, le laisse
**démarrer pour de bon** (l'écran de bienvenue s'affiche, `.boot-load` est retiré), puis interroge la
page. Elle ne reconstruit aucun état.

## Ce qui est acquis

| Point du plan | Mesure | Verdict |
|---|---|---|
| Origine stable | `location.origin` = `aidescog://app` | ✅ |
| Contexte sécurisé | `isSecureContext` vrai ; `crypto.subtle.digest` rend 32 octets | ✅ |
| IndexedDB | aller-retour réel ✓ ; **marque retrouvée au lancement suivant** | ✅ |
| **Invariant d'origine sous OTA** | contenu servi depuis `/tmp/webroot-v2` (autre dossier) → **marque toujours retrouvée** | ✅ |
| pdf.js `import()` | module chargé, `getDocument` présent | ✅ |
| **Worker pdf.js** | `getDocument({data}).promise` → 1 page — le worker démarre vraiment | ✅ |
| CSP `<meta>` à hashs | **0 violation** | ✅ |
| Service worker | **0 enregistrement, page non contrôlée** | ✅ (rien ne combattra l'OTA) |

**Conséquence sur le plan** : le repli « remplacer la visionneuse par PDFKit natif », prévu au cas où
`import()` ou le Worker échoueraient, **n'est pas nécessaire**. Et la garde `Platform.web` sur
l'enregistrement du service worker reste utile par propreté, mais elle ne corrige aucun conflit : il
n'y en a pas.

Le type MIME **n'est pas un détail** : `import()` exige un type JavaScript. Un
`application/octet-stream` par défaut ferait échouer pdf.js sans qu'aucun message ne dise pourquoi.
C'est pourquoi le gestionnaire de schéma tient une table explicite (`mimeFor`), et c'est le premier
endroit à regarder si le PDF cesse de s'ouvrir dans la coquille.

## ⚠ Ce que cette sonde ne dit PAS, et qu'il ne faut pas lui faire dire

**L'inventaire d'API relevé ici est celui de macOS, et il n'est PAS transposable à iOS.** Relevé :

```
✓Notification ✓navigator.share ✗navigator.vibrate ✓storage.persist
✓serviceWorker ✓wakeLock ✓visualViewport ✗showOpenFilePicker
```

En WKWebView **iOS**, `Notification` et `navigator.share` sont attendus **absents** — c'est
précisément ce qui motive les coutures du pont. Ce tableau est donc à **re-mesurer sur simulateur
iOS**, et tant qu'il ne l'a pas été, il ne justifie ni ne dispense d'aucune couture.

Restent également non mesurés, et ils demandent iOS puis un **appareil réel** (point 5 du lot 0) :

- `env(safe-area-inset-*)` avec `viewport-fit=cover` et `contentInsetAdjustmentBehavior` ;
- `--vvh` à l'ouverture du clavier logiciel ;
- `document.documentElement.style.zoom`, la propriété la plus dépendante du moteur du fichier ;
- tout ce que fait le **compositeur** (rebond, hachures des placards, sticky) — que le dossier
  documente comme invisible à toute mesure de la page.

**Prérequis bloquant** : aucun runtime de simulateur n'est installé sur cette machine
(`xcrun simctl list runtimes` est vide).
