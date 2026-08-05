/* SONDE DU LOT 0, POINT 5 — LA GÉOMÉTRIE, ET ELLE NE SE MESURE QUE SUR iOS.
 *
 * La sonde macOS (native/probe/main.swift) a tranché l'origine, le stockage, les modules, les
 * workers et la CSP. Elle ne peut rien dire de ce qui suit, et le dossier du projet est explicite
 * sur ce point : `--vvh`, `env(safe-area-inset-*)` et `zoom` sur <html> sont les mécanismes les
 * plus dépendants du moteur de tout le fichier, et plusieurs dossiers douloureux (« bande basse
 * iOS », rebond du rail A→Z, hachure des placards) ont montré que ce que le compositeur fait du
 * rendu n'est visible dans AUCUNE mesure de la page.
 *
 * CE QU'ELLE MESURE, ET RIEN D'AUTRE : des valeurs que la page peut lire. Elle ne prétend donc PAS
 * couvrir le compositeur — cela reste à voir à l'œil sur appareil réel. Une sonde qui laisserait
 * croire l'inverse serait pire qu'aucune sonde.
 *
 * LA COQUILLE EST CELLE DU PORTAGE, PAS UNE MAQUETTE : WebView plein cadre (pas la zone sûre),
 * `contentInsetAdjustmentBehavior = .never`, rebond coupé. Mesurer dans une WebView posée dans la
 * zone sûre donnerait des insets nuls et ferait conclure à tort que `viewport-fit=cover` ne sert
 * à rien.
 */

import UIKit
import WebKit

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
  default:            return "application/octet-stream"
  }
}

final class RootHandler: NSObject, WKURLSchemeHandler {
  let root: URL
  init(root: URL) { self.root = root }
  func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
    guard let url = task.request.url else { task.didFinish(); return }
    var path = url.path
    if path.isEmpty || path == "/" { path = "/index.html" }
    let file = root.appendingPathComponent(path).standardizedFileURL
    guard file.path.hasPrefix(root.path), let data = try? Data(contentsOf: file) else {
      let r = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1",
                              headerFields: ["Content-Type": "text/plain"])!
      task.didReceive(r); task.didReceive(Data()); task.didFinish(); return
    }
    let r = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                            headerFields: ["Content-Type": mimeFor(file.pathExtension),
                                           "Content-Length": String(data.count)])!
    task.didReceive(r); task.didReceive(data); task.didFinish()
  }
  func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

func dire(_ s: String) { print(s); fflush(stdout) }

let sondeJS = """
const out = {};
const px = v => Math.round(parseFloat(v) || 0);

out.booted = !document.querySelector('.boot-load');
out.origin = String(location.origin);
out.secureContext = !!window.isSecureContext;

/* (1) env(safe-area-inset-*) — mesuré par un élément qui les CONSOMME, pas par une variable que
   l'app aurait pu poser elle-même. Sans `viewport-fit=cover` ET une WebView plein cadre, ces
   quatre valeurs seraient nulles. */
const s = document.createElement('div');
s.style.cssText = 'position:fixed;top:0;left:0;width:1px;height:1px;visibility:hidden;'
  + 'padding:env(safe-area-inset-top) env(safe-area-inset-right)'
  + ' env(safe-area-inset-bottom) env(safe-area-inset-left)';
document.body.appendChild(s);
const cs = getComputedStyle(s);
out.safeArea = `haut ${px(cs.paddingTop)} · droite ${px(cs.paddingRight)}`
             + ` · bas ${px(cs.paddingBottom)} · gauche ${px(cs.paddingLeft)}`;
s.remove();

// La variable --sab, que l'app expose au JS (env() n'est pas lisible depuis un script).
out.sab = getComputedStyle(document.documentElement).getPropertyValue('--sab').trim() || '(vide)';

/* (2) Les quatre hauteurs qui divergent sur iOS. En coquille native, sans barre d'outils qui se
   replie, elles DOIVENT coïncider — c'est le bénéfice annoncé du portage, et il se vérifie. */
const vvh = getComputedStyle(document.documentElement).getPropertyValue('--vvh').trim();
out.hauteurs = `innerHeight ${window.innerHeight} · visualViewport `
  + (window.visualViewport ? Math.round(window.visualViewport.height) : '—')
  + ` · --vvh ${vvh || '(vide)'} · screen ${screen.height}`;
const d = document.createElement('div');
d.style.cssText = 'position:fixed;top:0;left:0;width:1px;visibility:hidden;height:100dvh';
document.body.appendChild(d);
const hDvh = px(getComputedStyle(d).height);
d.style.height = '100svh'; const hSvh = px(getComputedStyle(d).height);
d.style.height = '100lvh'; const hLvh = px(getComputedStyle(d).height);
d.remove();
out.unitesVh = `dvh ${hDvh} · svh ${hSvh} · lvh ${hLvh}`
             + (hDvh === hSvh && hSvh === hLvh ? '  → IDENTIQUES (pas de barre mobile)' : '  → DIVERGENTES');

/* (3) `zoom` sur <html> : la propriété la plus dépendante du moteur du fichier. On parcourt les
   quatre paliers réels et l'on vérifie que `zoomF()` (le pendant JS, lu par toutes les mesures
   réinjectées) suit bien la valeur posée. */
const paliers = [];
for (const z of [90, 100, 115, 130]) {
  applyZoom(z);
  const zf = (typeof zoomF === 'function') ? zoomF() : null;
  const zfCss = getComputedStyle(document.documentElement).getPropertyValue('--zf').trim();
  paliers.push(`${z}% → zoomF ${zf} / --zf ${zfCss || '(vide)'}`);
}
applyZoom(100);
out.zoom = paliers.join(' | ');

/* (4) L'INVENTAIRE QUE macOS NE POUVAIT PAS DONNER. C'est lui qui dimensionne les coutures :
   chaque absence ici est un pont à écrire. */
out.api = [
  ['Notification',       typeof Notification !== 'undefined'],
  ['navigator.share',    typeof navigator.share === 'function'],
  ['canShare',           typeof navigator.canShare === 'function'],
  ['vibrate',            typeof navigator.vibrate === 'function'],
  ['storage.persist',    !!(navigator.storage && navigator.storage.persist)],
  ['serviceWorker',      'serviceWorker' in navigator],
  ['wakeLock',           !!navigator.wakeLock],
  ['visualViewport',     !!window.visualViewport],
  ['print',              typeof window.print === 'function']
].map(([n, p]) => (p ? '✓' : '✗') + n).join(' ');

try {
  const regs = ('serviceWorker' in navigator) ? await navigator.serviceWorker.getRegistrations() : [];
  out.sw = regs.length + ' enregistrement(s)'
         + (navigator.serviceWorker?.controller ? ', page CONTRÔLÉE' : ', non contrôlée');
} catch (e) { out.sw = 'refusé : ' + e.message; }

/* (5) `window.print()` IMPRIME-T-IL ? Sa PRÉSENCE ne le dit pas : une fonction qui ne fait rien
   existe tout autant qu'une fonction qui agit. Ce qui décide, c'est si les évènements
   `beforeprint`/`afterprint` sont ÉMIS — car toute la préparation du document imprimé de
   l'application vit dans ces deux écouteurs. S'ils ne partent pas, `window.print()` imprimerait
   l'écran de crise REPLIÉ au lieu du compte rendu, et il faut un pont. */
out.print = await new Promise(res => {
  let avant = false, apres = false, leve = null;
  const fa = () => { avant = true; }, fb = () => { apres = true; };
  window.addEventListener('beforeprint', fa);
  window.addEventListener('afterprint', fb);
  const t0 = performance.now();
  try { window.print(); } catch (e) { leve = e.name + ' : ' + e.message; }
  const dt = Math.round(performance.now() - t0);
  setTimeout(() => {
    window.removeEventListener('beforeprint', fa);
    window.removeEventListener('afterprint', fb);
    res(`beforeprint ${avant} · afterprint ${apres} · retour en ${dt}ms · exception ${leve || 'aucune'}`);
  }, 2000);
});

/* (6) `navigator.wakeLock` : PRÉSENCE ≠ OBTENTION. C'est la demande qui tranche — si elle est
   accordée, l'écran qui s'éteint en pleine réanimation se corrige sans une ligne de Swift ; si
   elle est refusée, il faut `isIdleTimerDisabled` et donc un pont. */
try {
  if (!navigator.wakeLock) out.wakeLock = 'API absente';
  else {
    const s = await navigator.wakeLock.request('screen');
    out.wakeLock = `ACCORDÉ (type ${s.type}, released ${s.released})`;
    await s.release();
    out.wakeLock += ` · release ok (released ${s.released})`;
  }
} catch (e) { out.wakeLock = `REFUSÉ SANS GESTE : ${e.name} — ${e.message}`; }

/* ⚠ UN REFUS ICI NE TRANCHE PAS. `NotAllowedError` peut vouloir dire « le moteur ne l'accorde
   pas » OU « il manque une activation utilisateur transitoire » — et la différence décide de
   tout : dans le second cas l'application a des gestes à revendre (démarrer une session EST un
   tap) et aucun pont n'est nécessaire. On re-demande donc DEPUIS UN VRAI CLIC. */
window.__wl = null;
const bouton = document.createElement('button');
bouton.id = '__wlbtn';
bouton.textContent = 'SONDE WAKE LOCK — TAPER';
bouton.style.cssText = 'position:fixed;inset:auto 0 0 0;z-index:99999;height:120px;'
  + 'font-size:20px;font-weight:700;background:#17477f;color:#fff;border:0';
bouton.onclick = async () => {
  try {
    const s = await navigator.wakeLock.request('screen');
    window.__wl = `ACCORDÉ APRÈS GESTE (type ${s.type}, released ${s.released})`;
    await s.release();
    window.__wl += ' · release ok';
  } catch (e) { window.__wl = `REFUSÉ MÊME APRÈS GESTE : ${e.name} — ${e.message}`; }
};
document.body.appendChild(bouton);

out.idb = await new Promise(res => { try {
  const rq = indexedDB.open('__ac_probe__', 1);
  rq.onupgradeneeded = () => rq.result.createObjectStore('s');
  rq.onerror = () => res('ÉCHEC : ' + (rq.error && rq.error.name));
  rq.onsuccess = () => { const db = rq.result;
    const t = db.transaction('s', 'readwrite'); t.objectStore('s').put({ v: 1 }, 'k');
    t.oncomplete = () => res('ok'); t.onerror = () => res('ÉCHEC écriture'); };
} catch (e) { res('ÉCHEC : ' + e.message); } });

return out;
"""

final class VC: UIViewController, WKNavigationDelegate {
  var web: WKWebView!

  override func viewDidLoad() {
    super.viewDidLoad()
    let root = Bundle.main.resourceURL!.appendingPathComponent("web").standardizedFileURL
    let cfg = WKWebViewConfiguration()
    cfg.setURLSchemeHandler(RootHandler(root: root), forURLScheme: SCHEME)
    cfg.websiteDataStore = .default()
    cfg.allowsInlineMediaPlayback = true

    web = WKWebView(frame: view.bounds, configuration: cfg)
    web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    // PLEIN CADRE, pas la zone sûre : c'est la condition pour que viewport-fit=cover ait un sens.
    web.scrollView.contentInsetAdjustmentBehavior = .never
    web.scrollView.bounces = false          // supprime la classe du rebond (dossier rail A→Z)
    web.navigationDelegate = self
    view.addSubview(web)
    web.load(URLRequest(url: URL(string: "\(SCHEME)://app/index.html")!))
  }

  func webView(_ w: WKWebView, didFinish nav: WKNavigation!) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
      w.callAsyncJavaScript(sondeJS, arguments: [:], in: nil, in: .page) { r in
        dire("── Sonde iOS — lot 0, point 5 (géométrie) ──")
        switch r {
        case .success(let v):
          if let d = v as? [String: Any] {
            for k in ["booted", "origin", "secureContext", "safeArea", "sab",
                      "hauteurs", "unitesVh", "zoom", "api", "print", "wakeLock", "sw", "idb"] {
              dire(String(format: "  %-14@ %@", k as NSString,
                          String(describing: d[k] ?? "—") as NSString))
            }
          } else { dire("  (retour inattendu : \(v))") }
        case .failure(let e):
          dire("  ✗ la sonde a échoué : \(e.localizedDescription)")
        }
        dire("──ATTENTE TAP (bouton bleu en bas)──")
        // On interroge jusqu'à ce que le clic réel ait répondu — 40 × 500 ms.
        var n = 0
        func sonder() {
          n += 1
          w.evaluateJavaScript("window.__wl") { v, _ in
            if let s = v as? String {
              dire(String(format: "  %-14@ %@", "wakeLockGeste" as NSString, s as NSString))
              dire("──FIN──")
            } else if n < 40 {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { sonder() }
            } else {
              dire("  wakeLockGeste  (aucun tap reçu en 20 s)"); dire("──FIN──")
            }
          }
        }
        sonder()
      }
    }
  }
  func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: Error) {
    dire("  ✗ navigation refusée : \(e.localizedDescription)"); dire("──FIN──")
  }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(_ a: UIApplication,
                   didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = VC()
    window?.makeKeyAndVisible()
    return true
  }
}
