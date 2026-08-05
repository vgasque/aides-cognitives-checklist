/* SONDE DU LOT 0 — WKWebView + WKURLSchemeHandler (portage natif, v5.1.2).
 *
 * POURQUOI CE FICHIER EXISTE. Le portage natif repose entièrement sur un pari : que le monofichier
 * réel, servi tel quel sous un SCHÉMA PERSONNALISÉ, se comporte dans une WKWebView comme il se
 * comporte sur le web. Ce pari n'est pas vérifiable par lecture — il tient à ce que WebKit fait
 * d'un schéma qu'il ne connaît pas : contexte sécurisé ou non, `import()` dynamique servi ou non,
 * Worker démarré ou non, IndexedDB accordé ou non, CSP appliquée ou non. Quatre réponses binaires
 * qui décident du plan entier, et qu'aucune documentation ne donne avec certitude.
 *
 * CETTE SONDE EST JETABLE ET ELLE MESURE — elle n'affirme rien. Elle sert le VRAI `index.html`
 * (pas une maquette), le laisse démarrer POUR DE BON, puis interroge la page. C'est la doctrine
 * du dépôt appliquée au portage : une sonde ouvre par le vrai point d'entrée, elle ne reconstruit
 * jamais l'état.
 *
 * CIBLE macOS À DESSEIN. Le moteur est le même WebKit que sur iOS pour tout ce qui est mesuré ici
 * (origine, stockage, modules, workers, CSP) et il ne demande AUCUN runtime de simulateur — absent
 * de cette machine. Ce que macOS ne peut PAS dire est la GÉOMÉTRIE (safe areas, `--vvh` au clavier,
 * `zoom`) : c'est le point 5 du lot 0, et il reste à mesurer sur simulateur puis sur appareil.
 * Ne pas conclure d'ici sur la mise en page.
 *
 * Compilation et exécution :
 *   swiftc -O -o /tmp/acprobe native/probe/main.swift -framework WebKit -framework AppKit
 *   /tmp/acprobe "$PWD"
 */

import AppKit
import WebKit

// ── Racine servie ────────────────────────────────────────────────────────────────────────────
let ROOT = URL(fileURLWithPath: CommandLine.arguments.count > 1
               ? CommandLine.arguments[1]
               : FileManager.default.currentDirectoryPath).standardizedFileURL
let SCHEME = "aidescog"

func mimeFor(_ ext: String) -> String {
  switch ext.lowercased() {
  case "html":        return "text/html; charset=utf-8"
  case "js", "mjs":   return "text/javascript; charset=utf-8"
  case "json":        return "application/json; charset=utf-8"
  case "webmanifest": return "application/manifest+json; charset=utf-8"
  case "css":         return "text/css; charset=utf-8"
  case "woff2":       return "font/woff2"
  case "png":         return "image/png"
  case "svg":         return "image/svg+xml"
  case "ico":         return "image/vnd.microsoft.icon"
  case "pdf":         return "application/pdf"
  default:            return "application/octet-stream"
  }
}

/* Sert les fichiers du dépôt sous `aidescog://app/…`. Le type MIME sort d'UNE table (mimeFor) :
   pdf.js est chargé par `import()`, qui EXIGE un type JavaScript — un `application/octet-stream`
   par défaut ferait échouer le module sans que rien ne dise pourquoi. */
final class RootHandler: NSObject, WKURLSchemeHandler {
  var served: [String] = []
  var missing: [String] = []

  func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
    guard let url = task.request.url else { task.didFinish(); return }
    var path = url.path
    if path.isEmpty || path == "/" { path = "/index.html" }
    let file = ROOT.appendingPathComponent(path).standardizedFileURL

    // Confinement sous ROOT : une sonde n'a aucune raison de servir hors du dépôt.
    guard file.path.hasPrefix(ROOT.path) else { task.didFinish(); return }

    if let data = try? Data(contentsOf: file) {
      served.append(path)
      let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                 headerFields: ["Content-Type": mimeFor(file.pathExtension),
                                                "Content-Length": String(data.count)])!
      task.didReceive(resp); task.didReceive(data); task.didFinish()
    } else {
      missing.append(path)
      let resp = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1",
                                 headerFields: ["Content-Type": "text/plain"])!
      task.didReceive(resp); task.didReceive(Data()); task.didFinish()
    }
  }

  func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

// ── Mise en place ────────────────────────────────────────────────────────────────────────────
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let handler = RootHandler()
let cfg = WKWebViewConfiguration()
cfg.setURLSchemeHandler(handler, forURLScheme: SCHEME)
cfg.websiteDataStore = .default()          // PERSISTANT — `nonPersistent()` viderait IndexedDB.

/* Les violations CSP se captent depuis un MONDE ISOLÉ : injecté dans le monde de la page, ce
   script serait lui-même soumis à la CSP à hashs qu'il est censé observer. */
let cspWatch = """
window.__cspv = [];
document.addEventListener('securitypolicyviolation', e => {
  window.__cspv.push((e.violatedDirective || '?') + ' ← ' + (e.blockedURI || '(inline)'));
});
"""
cfg.userContentController.addUserScript(
  WKUserScript(source: cspWatch, injectionTime: .atDocumentStart,
               forMainFrameOnly: true, in: .defaultClient))

let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 430, height: 844), configuration: cfg)
let win = NSWindow(contentRect: web.frame, styleMask: [.titled], backing: .buffered, defer: false)
win.contentView = web
win.orderFront(nil)

var lignes: [String] = []
var fini = false
func dire(_ s: String) { lignes.append(s); FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

// ── Les sondes, dans le monde de la PAGE (l'environnement réel) ──────────────────────────────
let sondeJS = """
const out = {};
out.origin        = String(location.origin);
out.secureContext = !!window.isSecureContext;
out.booted        = !document.querySelector('.boot-load');
out.hasIDB        = (typeof indexedDB !== 'undefined');
out.hasCrypto     = !!(window.crypto && window.crypto.subtle);
out.hasWorker     = (typeof Worker !== 'undefined');
out.ecran         = document.querySelector('#welcome:not([hidden])') ? 'bienvenue'
                  : (document.querySelector('.dir-row') ? 'bibliothèque (fiches rendues)'
                  : (document.body.textContent.includes('Commencer') ? 'bienvenue (texte)' : '?'));
out.mainNonVide   = (document.getElementById('main') || {}).children?.length || 0;

// (1) crypto.subtle réellement utilisable — l'app en fait un digest SHA-256 (L21119).
try {
  const d = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('x'));
  out.subtleDigest = (d.byteLength === 32) ? 'ok' : 'taille ' + d.byteLength;
} catch (e) { out.subtleDigest = 'ÉCHEC : ' + e.message; }

// (2) IndexedDB : aller-retour réel, ET SURVIE À UN REDÉMARRAGE — c'est la preuve de
//     l'invariant d'origine, la seule qui compte. On LIT avant d'écrire : au second lancement,
//     la marque du premier doit être là. Un aller-retour intra-session ne prouve rien.
const idbRes = await new Promise(res => {
  try {
    const rq = indexedDB.open('__ac_probe__', 1);
    rq.onupgradeneeded = () => rq.result.createObjectStore('s');
    rq.onerror = () => res({ ar: 'ÉCHEC ouverture : ' + (rq.error && rq.error.name), pers: '—' });
    rq.onsuccess = () => {
      const db = rq.result;
      const g0 = db.transaction('s', 'readonly').objectStore('s').get('marque');
      g0.onsuccess = () => {
        const avant = g0.result;                       // écrit par un lancement PRÉCÉDENT
        const t = db.transaction('s', 'readwrite');
        t.objectStore('s').put({ v: 42 }, 'k');
        t.objectStore('s').put({ t: Date.now() }, 'marque');
        t.oncomplete = () => {
          const g = db.transaction('s', 'readonly').objectStore('s').get('k');
          g.onsuccess = () => res({
            ar: g.result && g.result.v === 42 ? 'ok (aller-retour)' : 'relecture fausse',
            pers: avant ? 'ok — marque du lancement précédent retrouvée'
                        : 'aucune marque (1er lancement, ou stockage NON persistant)'
          });
          g.onerror = () => res({ ar: 'ÉCHEC relecture', pers: '—' });
        };
        t.onerror = () => res({ ar: 'ÉCHEC écriture : ' + (t.error && t.error.name), pers: '—' });
      };
      g0.onerror = () => res({ ar: 'ÉCHEC lecture initiale', pers: '—' });
    };
  } catch (e) { res({ ar: 'ÉCHEC : ' + e.message, pers: '—' }); }
});
out.idb        = idbRes.ar;
out.idbPersist = idbRes.pers;

// (3) pdf.js : import() dynamique PUIS Worker, par le chemin exact de l'app (L18250).
try {
  const m = await import('./vendor/pdfjs/pdf.min.js');
  out.pdfImport = m && m.getDocument ? 'ok' : 'module sans getDocument';
  m.GlobalWorkerOptions.workerSrc = './vendor/pdfjs/pdf.worker.min.js';
  // Un PDF minimal suffit : ce qu'on mesure est le démarrage du WORKER, pas le rendu.
  const pdf = '%PDF-1.4\\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\\n'
            + '2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\\n'
            + '3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\\n'
            + 'trailer<</Root 1 0 R>>';
  const bytes = Uint8Array.from(pdf, c => c.charCodeAt(0));
  const doc = await m.getDocument({ data: bytes }).promise;
  out.pdfWorker = 'ok (' + doc.numPages + ' page)';
} catch (e) { out.pdfWorker = out.pdfWorker || ('ÉCHEC : ' + (e && e.message)); }

// (4) Inventaire des API que le pont devra remplacer. On mesure leur ABSENCE plutôt que de la
//     supposer : c'est ce qui dimensionne les coutures.
out.apiAbsentes = [
  ['Notification',        typeof Notification !== 'undefined'],
  ['navigator.share',     typeof navigator.share === 'function'],
  ['navigator.vibrate',   typeof navigator.vibrate === 'function'],
  ['storage.persist',     !!(navigator.storage && navigator.storage.persist)],
  ['serviceWorker',       'serviceWorker' in navigator],
  ['wakeLock',            !!navigator.wakeLock],
  ['visualViewport',      !!window.visualViewport],
  ['showOpenFilePicker',  typeof window.showOpenFilePicker === 'function']
].map(([n, present]) => (present ? '✓' : '✗') + n).join(' ');

// (5) Le service worker s'enregistre-t-il RÉELLEMENT sous ce schéma ? La présence de l'API ne
//     répond pas : ce qui compte est le résultat de la tentative que l'app fait au démarrage
//     (L22458). Un worker actif dans la coquille resservirait du contenu figé et combattrait
//     l'OTA — c'est l'urgence de la garde `Platform.web` qui se joue ici.
try {
  if ('serviceWorker' in navigator) {
    const regs = await navigator.serviceWorker.getRegistrations();
    out.swEnregistre = regs.length + ' enregistrement(s)'
                     + (navigator.serviceWorker.controller ? ', page CONTRÔLÉE' : ', page non contrôlée');
  } else out.swEnregistre = 'API absente';
} catch (e) { out.swEnregistre = 'refusé : ' + e.message; }

return out;
"""

let lireCSP = "return (window.__cspv || []).join(' | ') || '(aucune)';"

final class Nav: NSObject, WKNavigationDelegate {
  func webView(_ w: WKWebView, didFinish nav: WKNavigation!) {
    // L'app démarre pour de bon (IndexedDB, seed, rendu) : on lui laisse le temps réel de le faire.
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
      w.callAsyncJavaScript(sondeJS, arguments: [:], in: nil, in: .page) { r in
        switch r {
        case .success(let v):
          if let d = v as? [String: Any] {
            for k in ["origin", "secureContext", "booted", "ecran", "mainNonVide",
                      "hasIDB", "hasCrypto", "hasWorker", "subtleDigest",
                      "idb", "idbPersist", "pdfImport", "pdfWorker", "apiAbsentes", "swEnregistre"] {
              dire(String(format: "  %-14@ %@", k as NSString,
                          String(describing: d[k] ?? "—") as NSString))
            }
          } else { dire("  (retour inattendu : \(v))") }
        case .failure(let e):
          dire("  ✗ la sonde elle-même a échoué : \(e.localizedDescription)")
        }
        w.callAsyncJavaScript(lireCSP, arguments: [:], in: nil, in: .defaultClient) { r2 in
          if case .success(let v) = r2 { dire(String(format: "  %-14@ %@", "cspViolations" as NSString,
                                                     String(describing: v) as NSString)) }
          dire("")
          dire("Fichiers servis (\(handler.served.count)) : "
               + handler.served.prefix(12).joined(separator: ", ")
               + (handler.served.count > 12 ? " …" : ""))
          if !handler.missing.isEmpty { dire("404 : " + handler.missing.joined(separator: ", ")) }
          fini = true
        }
      }
    }
  }
  func webView(_ w: WKWebView, didFail nav: WKNavigation!, withError e: Error) {
    dire("  ✗ navigation échouée : \(e.localizedDescription)"); fini = true
  }
  func webView(_ w: WKWebView, didFailProvisionalNavigation nav: WKNavigation!, withError e: Error) {
    dire("  ✗ navigation refusée : \(e.localizedDescription)"); fini = true
  }
}

let nav = Nav()
web.navigationDelegate = nav

dire("── Sonde WKWebView — lot 0, points 1 à 4 ──")
dire("racine : \(ROOT.path)")
dire("")
web.load(URLRequest(url: URL(string: "\(SCHEME)://app/index.html")!))

let limite = Date().addingTimeInterval(45)
while !fini && Date() < limite {
  RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.1))
}
if !fini { dire("  ✗ délai dépassé (45 s) — la page n'a pas répondu.") }
exit(fini ? 0 : 1)
