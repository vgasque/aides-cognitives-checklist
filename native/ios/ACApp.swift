/* ═══ COQUILLE NATIVE iOS / iPadOS — « Aides cognitives » ═══════════════════════════════════
 *
 * CE QUE CETTE COQUILLE FAIT, ET RIEN DE PLUS : héberger le monofichier, GARANTIR SON ORIGINE,
 * et offrir les trois capacités que le web n'a pas sur iOS. Elle ne contient aucune logique
 * métier, aucun rendu, aucune donnée : `index.html` reste la source unique, servi à l'octet, et
 * c'est le MÊME fichier que sur le web. Tout ce qui se décide ici est une propriété de
 * plateforme — jamais un comportement de l'application.
 *
 * ⚠ INVARIANT N°1 — L'ORIGINE NE CHANGE JAMAIS. `aidescog://app` est gravé : IndexedDB y est
 * attaché, et en changer effacerait la bibliothèque de tous les appareils, sans recours et sans
 * un mot. C'est la même porte à sens unique que `"id": "./"` du manifeste web. Mesuré au lot 0 :
 * les données survivent au redémarrage ET à un changement de dossier de contenu (le scénario
 * OTA), précisément parce que l'origine ne dépend pas du chemin sur disque.
 * À PROSCRIRE : `file://` (origine opaque — `import()` et les Workers cassent, donc pdf.js meurt)
 * et un serveur local `http://127.0.0.1:<port>` (le port varie donc l'origine aussi, et `http`
 * n'est pas un contexte sécurisé, ce qui tuerait `crypto.subtle`).
 *
 * CE QUI N'EST PAS ICI, ET POURQUOI : pas de wake lock (mesuré au lot 0 — `navigator.wakeLock`
 * est accordé dès qu'un geste est en cours, c'est donc du JavaScript, et la PWA en profite
 * aussi) ; pas de partage de fichier (`navigator.share` fonctionne en WKWebView) ; pas de
 * neutralisation du service worker (il ne s'enregistre pas sous un schéma personnalisé).
 * Trois ponts prévus au départ ont donc disparu à la mesure. Ne pas les réintroduire « au cas où ».
 */

import UIKit
import WebKit
import UserNotifications

// ── Identité de la coquille ──────────────────────────────────────────────────────────────────
/* VERSION DU CONTRAT, PAS DE L'APPLICATION. Elle ne bouge QUE si le pont change (verbe ajouté,
   signature modifiée). Le JS la lit dans `Native.shell` ; un futur manifeste OTA pourra exiger un
   minimum, de sorte qu'un contenu récent refuse de s'installer sur une coquille trop ancienne
   plutôt que de démarrer dégradé sans le dire. */
let SHELL_VERSION = 1
let SCHEME = "aidescog"

/* LES VERBES QUE CETTE COQUILLE SAIT FAIRE — la liste est ANNONCÉE au JS, jamais devinée par lui.
   C'est tout le contrat de compatibilité : le contenu demande `Native.can(verbe)` avant d'agir et
   retombe sur le comportement web si la réponse est non. Ajouter un verbe = l'ajouter ICI et
   monter SHELL_VERSION. */
let VERBES = ["haptic", "print.page", "print.html", "notify.ask", "timers.sync"]

func mimeFor(_ ext: String) -> String {
  switch ext.lowercased() {
  case "html":        return "text/html; charset=utf-8"
  case "js", "mjs":   return "text/javascript; charset=utf-8"   // ⚠ exigé par import() — cf. plus bas
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

/* ── Le service du contenu ────────────────────────────────────────────────────────────────────
   ⚠ LE TYPE MIME N'EST PAS UN DÉTAIL. pdf.js est chargé par `import()`, qui EXIGE un type
   JavaScript : un `application/octet-stream` par défaut ferait échouer le module SANS qu'aucun
   message ne dise pourquoi — la visionneuse de documents mourrait en silence. C'est le premier
   endroit à regarder si un PDF cesse de s'ouvrir. */
final class WebRootHandler: NSObject, WKURLSchemeHandler {
  let racine: URL
  init(racine: URL) { self.racine = racine }

  func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
    guard let url = task.request.url else { task.didFinish(); return }
    var chemin = url.path
    if chemin.isEmpty || chemin == "/" { chemin = "/index.html" }
    let fichier = racine.appendingPathComponent(chemin).standardizedFileURL

    // Confinement sous la racine : un `..` dans une URL ne doit pas sortir du contenu servi.
    guard fichier.path.hasPrefix(racine.path), let data = try? Data(contentsOf: fichier) else {
      let r = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1",
                              headerFields: ["Content-Type": "text/plain; charset=utf-8"])!
      task.didReceive(r); task.didReceive(Data()); task.didFinish(); return
    }
    let r = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                            headerFields: ["Content-Type": mimeFor(fichier.pathExtension),
                                           "Content-Length": String(data.count)])!
    task.didReceive(r); task.didReceive(data); task.didFinish()
  }

  func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

// ── Le pont ──────────────────────────────────────────────────────────────────────────────────
/* UN SEUL CANAL, `window.webkit.messageHandlers.ac`, et un seul format : `{verbe, arg}`.
   `WithReply` plutôt que le handler simple : l'appelant reçoit une PROMESSE, donc il peut savoir
   qu'un geste a été fait — un `postMessage` sans retour ne dit jamais si quelque chose a eu lieu,
   et « tombé dans le vide » est exactement l'état qu'on ne veut pas pouvoir confondre avec « fait ».
   UN VERBE INCONNU RÉPOND null : le JS a déjà refusé de l'appeler (`Native.can`), donc y arriver
   signifie que les deux listes ont divergé — on ne lève pas, on rend une valeur que l'appelant
   traite comme « capacité absente ». */
final class Bridge: NSObject, WKScriptMessageHandlerWithReply {
  weak var vc: RootVC?

  func userContentController(_ ucc: WKUserContentController,
                             didReceive message: WKScriptMessage,
                             replyHandler: @escaping (Any?, String?) -> Void) {
    guard let d = message.body as? [String: Any], let verbe = d["verbe"] as? String else {
      replyHandler(nil, nil); return
    }
    let arg = d["arg"] as? [String: Any]

    switch verbe {
    case "haptic":
      /* L'acquittement haptique du cochage (D10) était INERTE sur iOS : `navigator.vibrate` n'y
         existe pas. Avec des gants, dans le bruit d'un SMUR, c'est la confirmation qui évite le
         double-tap de doute — lequel, sur un compteur, FAUSSE la donnée. */
      let style = (arg?["style"] as? String) ?? "light"
      let g = UIImpactFeedbackGenerator(style: style == "medium" ? .medium : .light)
      g.impactOccurred()
      replyHandler(true, nil)

    case "print.page":
      // Imprime la vue elle-même : les 7 blocs `@media print` de l'app restent la seule mise en page.
      vc?.imprimer(formatter: vc?.web.viewPrintFormatter(), titre: (arg?["titre"] as? String) ?? "Document")
      replyHandler(true, nil)

    case "print.html":
      /* Le compte rendu est un document HTML AUTONOME (iframe srcdoc côté web). On le charge dans
         une WebView HORS ÉCRAN et l'on imprime SON formatter — surtout pas
         `UIMarkupTextPrintFormatter`, dont le support CSS est trop pauvre pour ce document. */
      guard let html = arg?["html"] as? String else { replyHandler(nil, nil); return }
      vc?.imprimerHTML(html, titre: (arg?["titre"] as? String) ?? "Compte rendu")
      replyHandler(true, nil)

    case "notify.ask":
      UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .sound]) { ok, _ in
          DispatchQueue.main.async { replyHandler(ok, nil) }
        }

    case "timers.sync":
      Alarmes.programmer((arg?["dues"] as? [[String: Any]]) ?? [])
      replyHandler(true, nil)

    default:
      replyHandler(nil, nil)
    }
  }
}

/* ── LES ALARMES QUI SURVIVENT À L'ÉCRAN ÉTEINT ───────────────────────────────────────────────
   REMPLACEMENT ATOMIQUE, JAMAIS UN DIFFÉRENTIEL : le JS remet la TOTALITÉ des échéances à venir,
   on efface tout et l'on repose. C'est ce qui rend le pont sans mémoire — aucune comptabilité de
   ce qui a été programmé, donc rien qui puisse diverger de l'état réel de l'application. Le coût
   est nul : `timerSync()` ne franchit le pont que si la liste a changé (anti-churn côté JS).

   ⚠ UNE ÉCHÉANCE DÉJÀ PASSÉE N'EST PAS REPROGRAMMÉE : l'application rattrape les cycles manqués
   toute seule au retour au premier plan (`Math.floor(within/per)`). Une notification pour un
   cycle déjà écoulé sonnerait dans le vide et ferait douter de toutes les autres. */
enum Alarmes {
  static func programmer(_ dues: [[String: Any]]) {
    let c = UNUserNotificationCenter.current()
    c.removeAllPendingNotificationRequests()
    if CommandLine.arguments.contains("-acdiag") {
      // Trace de développement : une coquille n'a pas de console, et « le minuteur n'a pas
      // sonné » ne dit pas SI l'échéance avait été programmée.
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        c.getPendingNotificationRequests { r in
          let d = r.sorted { ($0.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval ?? 0
                           < ($1.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval ?? 0 }
                   .prefix(3)
                   .map { "\($0.content.title) dans \(Int(($0.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval ?? 0))s" }
          print("── DIAG ALARMES ── reçues \(dues.count), en attente \(r.count) : \(d.joined(separator: " | "))")
          fflush(stdout)
        }
      }
    }
    let maintenant = Date().timeIntervalSince1970
    for d in dues {
      guard let id = d["id"] as? String,
            let at = d["at"] as? Double else { continue }
      let dans = at / 1000.0 - maintenant
      if dans <= 0.5 { continue }
      let n = UNMutableNotificationContent()
      // Le libellé vient de `timerAlertText` côté JS — il n'est JAMAIS reconstruit ici : deux
      // formulations du même évènement seraient deux vocabulaires pour une chose.
      n.title = (d["titre"] as? String) ?? "Minuteur"
      n.body  = (d["corps"] as? String) ?? ""
      n.sound = .default
      if let f = d["fiche"] as? String { n.userInfo = ["fiche": f] }
      c.add(UNNotificationRequest(
        identifier: id, content: n,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: dans, repeats: false)))
    }
  }
}

// ── L'écran ──────────────────────────────────────────────────────────────────────────────────
final class RootVC: UIViewController, WKNavigationDelegate {
  var web: WKWebView!
  private let pont = Bridge()
  private var webImpression: WKWebView?      // retenue le temps de l'impression, sinon libérée

  override func viewDidLoad() {
    super.viewDidLoad()
    pont.vc = self

    let racine = Bundle.main.resourceURL!.appendingPathComponent("web").standardizedFileURL
    let cfg = WKWebViewConfiguration()
    cfg.setURLSchemeHandler(WebRootHandler(racine: racine), forURLScheme: SCHEME)
    /* PERSISTANT — jamais `nonPersistent()`, qui viderait IndexedDB à chaque lancement, donc
       toute la bibliothèque. C'est l'erreur la plus coûteuse possible dans ce fichier. */
    cfg.websiteDataStore = .default()
    cfg.allowsInlineMediaPlayback = true

    /* L'ANNONCE DES CAPACITÉS, POSÉE AVANT LE PREMIER SCRIPT DE LA PAGE. `Native` la lit à
       l'initialisation ; injectée plus tard, elle arriverait après et le contenu croirait tourner
       sans coquille. Monde de la PAGE (et non isolé) : c'est le JS de l'application qui doit la voir. */
    /* ⚠ L'ANNONCE SE SÉRIALISE EN JSON, JAMAIS PAR INTERPOLATION D'UN TABLEAU SWIFT.
       `\(VERBES)` rend la `description` de Swift, pas du JSON : les guillemets finissent DANS les
       chaînes, `verbes` contient alors des éléments comme «"haptic"» (guillemets compris) et
       `Native.can('haptic')` répond faux pour TOUS les verbes. Le pont s'annonce, le JS le voit,
       et pourtant rien ne marche — un symptôme qui ne désigne pas sa cause. Payé une fois : le
       bouton « Exporter en PDF » ne faisait rien, et seule la trace `-acdiag` l'a montré
       (`{"on":true,"peut":[]}`). */
    let annonceJSON = String(
      data: try! JSONSerialization.data(withJSONObject: ["shell": SHELL_VERSION, "verbes": VERBES]),
      encoding: .utf8)!
    let annonce = "window.__acNative = \(annonceJSON);"
    cfg.userContentController.addUserScript(
      WKUserScript(source: annonce, injectionTime: .atDocumentStart, forMainFrameOnly: true))
    cfg.userContentController.addScriptMessageHandler(pont, contentWorld: .page, name: "ac")

    web = WKWebView(frame: view.bounds, configuration: cfg)
    web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    web.navigationDelegate = self
    /* PLEIN CADRE, PAS LA ZONE SÛRE — c'est la condition pour que `viewport-fit=cover` ait un sens
       et que `env(safe-area-inset-*)` rende autre chose que zéro (mesuré au lot 0 : haut 62,
       bas 34 sur un iPhone à Dynamic Island). */
    web.scrollView.contentInsetAdjustmentBehavior = .never
    /* LE REBOND EST COUPÉ, et ce n'est pas cosmétique : pendant le rubber-band, WebKit TRANSLATE
       les éléments `position:fixed` — le rail A→Z partait sous le doigt qui le visait (dossier
       v5.0.2, corrigé côté web au prix d'une classe posée au pointerdown). Ici le problème
       n'existe simplement pas. */
    web.scrollView.bounces = false
    // Le geste « retour » horizontal fermerait la fiche sans passer par la pile de retour de l'app.
    web.allowsBackForwardNavigationGestures = false
    view.addSubview(web)

    web.load(URLRequest(url: URL(string: "\(SCHEME)://app/index.html")!))
  }

  /* TRACE DE DÉVELOPPEMENT, sur argument de lancement seulement (`-acdiag`). Elle existe parce
     qu'une coquille n'a PAS de console : sans elle, un pont qui ne s'annonce pas se manifeste par
     « le bouton ne fait rien », symptôme qui ne désigne pas sa cause. À lancer par
     `simctl launch --console-pty <udid> fr.aidescognitives.app -acdiag`. */
  func webView(_ w: WKWebView, didFinish nav: WKNavigation!) {
    guard CommandLine.arguments.contains("-acdiag") else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
      w.evaluateJavaScript("""
        JSON.stringify({ pont: !!(window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.ac),
                         annonce: !!window.__acNative, native: Platform.native,
                         on: Native.on, shell: Native.shell,
                         peut: (window.__acNative.verbes||[]).filter(v=>Native.can(v)) })
      """) { v, e in
        print("── DIAG PONT ── \(v ?? "erreur : \(String(describing: e))")")
        fflush(stdout)
      }
    }
  }

  // ── Impression ─────────────────────────────────────────────────────────────────────────────
  /* `window.print()` est un NO-OP en WebKit iOS, et — c'est ce qui compte — il n'émet NI
     `beforeprint` NI `afterprint` (mesuré au lot 0 : false/false, retour en 0 ms, aucune
     exception). Or toute la préparation du document imprimé de l'application vit dans ces deux
     écouteurs. Sans ce pont, « Exporter en PDF » imprimerait l'écran de crise REPLIÉ au lieu du
     compte rendu : un document faux, présenté comme le bon. */
  func imprimer(formatter: UIViewPrintFormatter?, titre: String) {
    guard let f = formatter else { return }
    let info = UIPrintInfo.printInfo()
    info.outputType = .general
    info.jobName = titre
    let c = UIPrintInteractionController.shared
    c.printInfo = info
    c.printFormatter = f
    c.present(animated: true, completionHandler: nil)
  }

  func imprimerHTML(_ html: String, titre: String) {
    let w = WKWebView(frame: CGRect(x: 0, y: 0, width: 794, height: 1123))   // A4 à 96 ppp
    webImpression = w
    let del = ChargeurImpression(titre: titre) { [weak self] in
      self?.imprimer(formatter: w.viewPrintFormatter(), titre: titre)
      self?.webImpression = nil
    }
    chargeur = del
    w.navigationDelegate = del
    w.loadHTMLString(html, baseURL: nil)
  }
  private var chargeur: ChargeurImpression?
}

/* Le formatter d'une WebView n'est exploitable qu'une fois le document RENDU : imprimer dès
   `loadHTMLString` donnerait des pages blanches. On attend donc `didFinish`. */
final class ChargeurImpression: NSObject, WKNavigationDelegate {
  let titre: String
  let pret: () -> Void
  init(titre: String, pret: @escaping () -> Void) { self.titre = titre; self.pret = pret }
  func webView(_ w: WKWebView, didFinish nav: WKNavigation!) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.pret() }
  }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  var window: UIWindow?
  var vc: RootVC?

  func application(_ a: UIApplication,
                   didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let r = RootVC()
    vc = r
    let w = UIWindow(frame: UIScreen.main.bounds)
    w.rootViewController = r
    w.makeKeyAndVisible()
    window = w
    UNUserNotificationCenter.current().delegate = self
    return true
  }

  /* APPLICATION AU PREMIER PLAN : ON NE PRÉSENTE RIEN. L'application a déjà son propre dispositif
     d'alarme — bip, flash, segment ambre persistant dans le quai — et il obéit à une règle que le
     système ignore : en mode crise, RIEN ne se pose par-dessus la checklist (règle 11). Une
     bannière système y serait exactement l'interruption proscrite.
     ⚠ CE CHOIX EST FAIT ICI, ET SURTOUT PAS EN JS : côté web il faudrait suivre la visibilité de
     la page pour décider, c'est-à-dire tenir une SECONDE source de vérité sur un état que le
     système connaît déjà. Le JS reste ignorant. */
  func userNotificationCenter(_ c: UNUserNotificationCenter,
                              willPresent n: UNNotification,
                              withCompletionHandler h: @escaping (UNNotificationPresentationOptions) -> Void) {
    h([])
  }

  /* NOTIFICATION TAPÉE : on ouvre LA FICHE concernée, pas l'accueil. Sans cela, un tap sur
     « adrénaline — 5 min » déposerait sur la bibliothèque, et il faudrait retrouver la
     réanimation en cours à la main. C'est la contrepartie obligatoire du fait que chaque échéance
     porte son `ficheId`. */
  func userNotificationCenter(_ c: UNUserNotificationCenter,
                              didReceive r: UNNotificationResponse,
                              withCompletionHandler h: @escaping () -> Void) {
    if let f = r.notification.request.content.userInfo["fiche"] as? String,
       let w = vc?.web {
      let sur = f.replacingOccurrences(of: "\\", with: "\\\\")
                 .replacingOccurrences(of: "'", with: "\\'")
      w.evaluateJavaScript("try{openRead('\(sur)')}catch(e){}", completionHandler: nil)
    }
    h()
  }
}
