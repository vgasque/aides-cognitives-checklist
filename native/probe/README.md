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

## Point 5 — la géométrie, mesurée sur iOS (simulateur iPhone 17 Pro, iOS 26.5)

`native/probe/ios/build.sh [UDID]` construit et lance la sonde iOS. La WebView y est **plein
cadre** (`contentInsetAdjustmentBehavior = .never`, `bounces = false`) : mesurer dans une WebView
posée dans la zone sûre donnerait des insets nuls et ferait conclure à tort que `viewport-fit=cover`
ne sert à rien.

| Mesure | Résultat |
|---|---|
| `env(safe-area-inset-*)` | **haut 62 · bas 34** (Dynamic Island respectée) ; `--sab` = 34px |
| Hauteurs | `innerHeight` = `visualViewport` = `--vvh` = `screen` = **874** |
| Unités | **`dvh` = `svh` = `lvh` = 874 — IDENTIQUES** |
| `zoom` sur `<html>` | les 4 paliers fonctionnent ; `zoomF()` et `--zf` suivent (0.9 / 1 / 1.15 / 1.3) |
| IndexedDB | ok |

**Le bénéfice annoncé du portage est donc mesuré, pas supposé** : sans barre d'outils qui se replie,
les trois unités de fenêtre coïncident. Toute la classe de défauts qui a coûté les dossiers
« bande basse iOS » (v4.29.x), « rebond du rail A→Z » (v5.0.2) et les corrections successives de
`--vvh` disparaît **par construction** dans la coquille.

### L'inventaire d'API, cette fois sur le vrai WebKit iOS

```
✗Notification  ✓navigator.share  ✓canShare  ✗vibrate  ✓storage.persist
✗serviceWorker ✓wakeLock  ✓visualViewport  ✓print
```

**Trois corrections au plan, et elles réduisent le travail :**

1. **`navigator.share` et `canShare` sont PRÉSENTS.** Le plan les donnait pour absents en WKWebView
   iOS et prévoyait un pont pour `dlBlob`. Il n'est **pas nécessaire** : le chemin de partage
   existant fonctionne tel quel dans la coquille.
2. **`navigator.wakeLock` est PRÉSENT.** Le plan affirmait que l'API « n'est de toute façon pas
   disponible en PWA iOS » et prévoyait `isIdleTimerDisabled`. ⚠ Présence n'est pas obtention : il
   reste à vérifier qu'une `request('screen')` est réellement ACCORDÉE. Si oui, l'écran qui s'éteint
   en pleine réanimation se corrige **sans une ligne de Swift**.
3. **`serviceWorker` est totalement ABSENT** sous le schéma personnalisé (sur macOS l'API existait
   mais n'enregistrait rien). Le chemin est donc inerte par construction : la garde `Platform.web`
   reste de la propreté, elle ne corrige aucun conflit.

Inchangé, et conforme au plan : **`Notification` et `vibrate` sont absents** — ce sont les deux
ponts réellement nécessaires, avec les notifications locales pour les alarmes en arrière-plan.

⚠ **`window.print` EXISTE comme fonction, ce qui ne dit pas qu'il IMPRIME.** La sonde n'a mesuré
que sa présence ; le plan retient de WebKit iOS qu'il ne l'implémente pas et n'émet ni `beforeprint`
ni `afterprint`. **Ce point n'est pas tranché** — c'est la première chose à mesurer au lot 1, et
l'extraction `printPrepare`/`printRestore` (déjà livrée) est justement ce qui permettra d'en sortir
sans rien réécrire.

### Vérifié à l'écran, pas seulement à la sonde

Parcours réel piloté sur le simulateur : écran de bienvenue → « Commencer » → « Ajouter les fiches
d'exemple » → répertoire A→Z → ouverture d'Anaphylaxie → « Confirmé — démarrer la session ». Le mode
crise se rend intégralement — pilule « ■ CRISE », rangée de commandes, quai (chrono `SESSION 00:05`,
« 1 minuteur · 1 compteur »), chapeau replié « 4 RAPPELS », registres ⚠ rouge et △ ambre, marqueur
`×2`, pilules mono de réponse attendue.

## ⚠ Ce que ces sondes ne disent PAS, et qu'il ne faut pas leur faire dire

**L'inventaire d'API de la sonde macOS n'est PAS transposable à iOS**, et la comparaison le prouve :
macOS voyait `✓Notification` et `✓serviceWorker` là où iOS répond `✗` aux deux. La sonde macOS
tranche l'origine, le stockage, les modules et la CSP — rien d'autre. Se servir de son inventaire
d'API pour dimensionner une couture serait une erreur.

Restent non mesurés, et ils demandent un **appareil réel** :

- **le clavier logiciel** : `--vvh` n'a été mesuré qu'au repos, jamais champ focalisé ;
- **tout ce que fait le compositeur** — rebond, hachures des placards, sticky au défilement — que le
  dossier documente comme **invisible à toute mesure de la page** (leçons v5.0.2, v5.0.5, v5.0.9).
  Un simulateur ne le dit pas mieux qu'un harnais headless : il faut un appareil et un œil ;
- **`window.print`** : présent, comportement non vérifié (voir ci-dessus) ;
- **`navigator.wakeLock`** : présent, obtention non vérifiée.
