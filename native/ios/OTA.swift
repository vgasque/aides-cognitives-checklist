/* ═══ MISE À JOUR OTA DU CONTENU — signée, vérifiée, et RÉVERSIBLE ═══════════════════════════
 *
 * POURQUOI. Sur le web, un correctif clinique arrive en MINUTES. En natif, il attendrait une revue
 * Apple (1 à 3 jours) : pour une aide utilisée en urgence vitale, c'est une régression de sécurité.
 * Apple autorise explicitement ce mécanisme (App Review 3.3.2 : du code interprété exécuté par
 * WebKit peut être téléchargé tant qu'il ne change pas la finalité de l'application).
 *
 * CE QUI SE MET À JOUR : le CONTENU (index.html, pdf.js, police, icônes). PAS la coquille, qui est
 * du code natif et passe par l'App Store. D'où le `minShell` du manifeste : un contenu qui exige un
 * verbe de pont plus récent REFUSE de s'installer sur une coquille trop ancienne, et l'appareil
 * reste sur la version précédente — plutôt que de démarrer dégradé sans le dire.
 *
 * ⚠ LA BASCULE N'A JAMAIS LIEU EN SESSION. On télécharge, on vérifie, on RANGE — et l'on applique
 * AU PROCHAIN LANCEMENT. Remplacer le contenu sous les doigts de quelqu'un qui déroule une
 * réanimation serait exactement ce que la règle 11 interdit, en pire : ce n'est pas une fenêtre
 * qui s'ouvre, c'est l'application qui change.
 *
 * ⚠ ET LE REPLI EST OBLIGATOIRE, PAS UNE PRÉCAUTION. Un payload accepté mais qui ne démarre pas
 * rendrait l'application INUTILISABLE HORS LIGNE, EN INTERVENTION, SANS RECOURS — le pire mode de
 * défaillance possible ici. Le JS poste `boot.ok` quand il a démarré ; sans ce signal dans les 8 s,
 * la coquille revient à la version précédente au lancement suivant. C'est la seule raison pour
 * laquelle on s'autorise à remplacer le contenu d'une application de crise.
 */

import Foundation
import CryptoKit

enum OTA {
  private static let dActif = "ota.actif"       // version servie (absente = celle du bundle)
  private static let dPrec  = "ota.precedente"  // version d'avant, pour le repli
  private static let dAttente = "ota.enAttente" // téléchargée, appliquée au prochain lancement
  private static let dEssai = "ota.essai"       // vraie tant que `boot.ok` n'est pas venu
  private static let dRefus = "ota.refusees"    // versions qui n'ont jamais démarré — jamais réessayées

  static var base: String? {
    /* L'URL de production n'est PAS écrite dans le dépôt (décision d'hébergement, cf.
       docs/deploiement-et-conformite.md). Elle vient de l'Info.plist, posé au build. Absente,
       l'OTA est simplement INACTIVE : la coquille sert le bundle, ce qui est le comportement
       correct en développement. */
    (Bundle.main.object(forInfoDictionaryKey: "ACOTABase") as? String)
      .flatMap { $0.isEmpty ? nil : $0 }
  }

  private static var dossiers: URL {
    let u = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("webroots")
    try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
    return u
  }
  private static func dossier(_ v: String) -> URL { dossiers.appendingPathComponent("v" + v) }

  /* ── Ce qui est servi MAINTENANT ──────────────────────────────────────────────────────────
     Appelée une fois au démarrage : la racine ne change JAMAIS en cours de session. */
  static func racineAuDemarrage(bundle: URL) -> URL {
    let d = UserDefaults.standard

    // (1) Un essai non confirmé signifie que le lancement précédent n'a jamais posté `boot.ok`.
    //     On revient à la version d'avant, et l'on ne réessaie pas : un payload qui ne démarre
    //     pas ne démarrera pas davantage la seconde fois.
    if d.bool(forKey: dEssai) {
      d.set(false, forKey: dEssai)
      if let mauvaise = d.string(forKey: dActif) { quarantaine(mauvaise) }
      let prec = d.string(forKey: dPrec)
      d.set(prec, forKey: dActif)
      NSLog("OTA : le contenu précédent n'a pas confirmé son démarrage — repli sur \(prec ?? "le bundle").")
    }

    // (2) Une version téléchargée attend : on l'applique, en probation.
    if let att = d.string(forKey: dAttente), FileManager.default.fileExists(atPath: dossier(att).path) {
      d.set(d.string(forKey: dActif), forKey: dPrec)
      d.set(att, forKey: dActif)
      d.removeObject(forKey: dAttente)
      d.set(true, forKey: dEssai)
    }

    if let a = d.string(forKey: dActif) {
      let u = dossier(a)
      if FileManager.default.fileExists(atPath: u.appendingPathComponent("index.html").path) { return u }
      // Dossier disparu (purge système, place disque) : on retombe sur le bundle, jamais sur rien.
      d.removeObject(forKey: dActif); d.set(false, forKey: dEssai)
    }
    return bundle
  }

  /// Un contenu est en probation : il a été appliqué mais n'a pas encore confirmé son démarrage.
  static var enProbation: Bool { UserDefaults.standard.bool(forKey: dEssai) }

  /* REPLI IMMÉDIAT — sans lui, un payload qui ne démarre pas laisserait l'utilisateur devant un
     écran mort jusqu'à ce qu'il pense à forcer la fermeture puis à relancer. En intervention,
     personne ne pense à cela. On revient donc à la version précédente DANS LA SECONDE, et la
     WebView est rechargée : l'incident coûte quelques secondes, pas une réanimation. */
  static func replierMaintenant() -> URL? {
    let d = UserDefaults.standard
    guard d.bool(forKey: dEssai) else { return nil }
    d.set(false, forKey: dEssai)
    if let mauvaise = d.string(forKey: dActif) { quarantaine(mauvaise) }
    let prec = d.string(forKey: dPrec)
    d.set(prec, forKey: dActif)
    NSLog("OTA : aucun démarrage confirmé en 8 s — repli immédiat sur \(prec ?? "le bundle").")
    guard let p = prec else { return nil }
    let u = dossier(p)
    return FileManager.default.fileExists(atPath: u.appendingPathComponent("index.html").path) ? u : nil
  }

  /* QUARANTAINE — SANS ELLE, LE REPLI BOUCLE. Une version qui n'a pas démarré serait
     re-téléchargée au lancement suivant, ré-appliquée, et re-échouerait : chaque démarrage
     coûterait 8 secondes d'écran mort, indéfiniment. Le repli sans quarantaine n'est donc pas un
     filet, c'est une boucle. Une version refusée l'est DÉFINITIVEMENT sur cet appareil ; la
     suivante, elle, sera essayée normalement — c'est par une NOUVELLE publication qu'on répare,
     pas en réessayant celle qui est cassée. */
  private static func quarantaine(_ v: String) {
    let d = UserDefaults.standard
    var l = d.stringArray(forKey: dRefus) ?? []
    if !l.contains(v) { l.append(v); d.set(l.suffix(20).map { $0 }, forKey: dRefus) }
    NSLog("OTA : v\(v) mise en quarantaine — elle ne sera plus proposée sur cet appareil.")
  }
  static func refusee(_ v: String) -> Bool {
    (UserDefaults.standard.stringArray(forKey: dRefus) ?? []).contains(v)
  }

  /// Le contenu a démarré : on lève la probation. Appelé par le verbe `boot.ok`.
  static func demarrageConfirme() {
    let d = UserDefaults.standard
    guard d.bool(forKey: dEssai) else { return }
    d.set(false, forKey: dEssai)
    NSLog("OTA : démarrage confirmé pour \(d.string(forKey: dActif) ?? "?").")
  }

  // ── Recherche d'une mise à jour ────────────────────────────────────────────────────────────
  static func chercher(versionServie: String, _ fini: @escaping (String?) -> Void) {
    guard let base = base, let cle = clePublique() else { fini(nil); return }
    let racine = base.hasSuffix("/") ? base : base + "/"
    guard let uMan = URL(string: racine + "ota/manifest.json"),
          let uSig = URL(string: racine + "ota/manifest.sig") else { fini(nil); return }

    telecharger(uMan) { manData in
      guard let manData = manData else { fini(nil); return }
      telecharger(uSig) { sigData in
        guard let sigData = sigData,
              let sigB64 = String(data: sigData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              let sig = Data(base64Encoded: sigB64) else { fini(nil); return }

        /* LA SIGNATURE D'ABORD, LE CONTENU ENSUITE. On ne lit RIEN du manifeste avant de savoir
           qu'il vient de nous : sinon un intermédiaire pourrait faire télécharger n'importe quoi
           en pointant des URL de son choix. */
        guard cle.isValidSignature(sig, for: manData) else {
          NSLog("OTA : signature du manifeste INVALIDE — mise à jour refusée."); fini(nil); return
        }
        guard let m = try? JSONSerialization.jsonObject(with: manData) as? [String: Any],
              let version = m["version"] as? String,
              let fichiers = m["fichiers"] as? [[String: Any]] else { fini(nil); return }

        if version == versionServie { fini(nil); return }
        if refusee(version) { fini(nil); return }   // déjà essayée, elle n'a jamais démarré
        let minShell = (m["minShell"] as? Int) ?? 0
        guard minShell <= SHELL_VERSION else {
          // On ne télécharge même pas : ce contenu exige un pont que cette coquille n'a pas.
          NSLog("OTA : v\(version) exige une coquille ≥ \(minShell), celle-ci est \(SHELL_VERSION) — ignorée.")
          fini(nil); return
        }

        installer(racine: racine, version: version, fichiers: fichiers) { ok in
          if ok {
            UserDefaults.standard.set(version, forKey: dAttente)
            NSLog("OTA : v\(version) prête — sera appliquée au prochain lancement.")
          }
          fini(ok ? version : nil)
        }
      }
    }
  }

  private static func installer(racine: String, version: String,
                                fichiers: [[String: Any]], _ fini: @escaping (Bool) -> Void) {
    let fm = FileManager.default
    let tmp = dossiers.appendingPathComponent("tmp-v" + version)
    try? fm.removeItem(at: tmp)
    try? fm.createDirectory(at: tmp, withIntermediateDirectories: true)

    let groupe = DispatchGroup()
    var echec = false
    for f in fichiers {
      guard let p = f["p"] as? String, let attendu = f["sha256"] as? String else { echec = true; continue }
      let rel = p.hasPrefix("./") ? String(p.dropFirst(2)) : p
      guard let u = URL(string: racine + rel) else { echec = true; continue }
      groupe.enter()
      telecharger(u) { d in
        defer { groupe.leave() }
        guard let d = d else { echec = true; return }
        /* CHAQUE FICHIER EST VÉRIFIÉ CONTRE SON HASH. La signature garantit le manifeste ; les
           hashs garantissent que ce qu'on a réellement reçu EST ce que le manifeste décrit. Sans
           eux, un fichier tronqué par une coupure réseau s'installerait sans un mot. */
        guard SHA256.hash(data: d).map({ String(format: "%02x", $0) }).joined() == attendu else {
          NSLog("OTA : « \(p) » ne correspond pas à son empreinte — mise à jour abandonnée.")
          echec = true; return
        }
        let dest = tmp.appendingPathComponent(rel)
        try? fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        do { try d.write(to: dest) } catch { echec = true }
      }
    }

    groupe.notify(queue: .main) {
      if echec {
        try? fm.removeItem(at: tmp)
        fini(false); return
      }
      /* BASCULE ATOMIQUE : le dossier définitif n'apparaît qu'une fois TOUT vérifié et écrit. Un
         payload à moitié téléchargé ne peut donc jamais être servi. */
      let dest = dossier(version)
      try? fm.removeItem(at: dest)
      do { try fm.moveItem(at: tmp, to: dest) } catch { fini(false); return }
      menage(sauf: [version, UserDefaults.standard.string(forKey: dActif) ?? "",
                    UserDefaults.standard.string(forKey: dPrec) ?? ""])
      fini(true)
    }
  }

  /// On garde l'actif, le précédent (pour le repli) et le nouveau. Le reste est du poids mort.
  private static func menage(sauf: [String]) {
    let fm = FileManager.default
    let garder = Set(sauf.filter { !$0.isEmpty }.map { "v" + $0 })
    for n in (try? fm.contentsOfDirectory(atPath: dossiers.path)) ?? [] where !garder.contains(n) {
      try? fm.removeItem(at: dossiers.appendingPathComponent(n))
    }
  }

  private static func clePublique() -> Curve25519.Signing.PublicKey? {
    guard let d = Data(base64Encoded: OTA_PUBKEY_B64.trimmingCharacters(in: .whitespacesAndNewlines)),
          let k = try? Curve25519.Signing.PublicKey(rawRepresentation: d) else { return nil }
    return k
  }

  private static func telecharger(_ u: URL, _ fini: @escaping (Data?) -> Void) {
    var r = URLRequest(url: u)
    r.cachePolicy = .reloadIgnoringLocalCacheData   // sinon on revérifierait une copie périmée
    r.timeoutInterval = 20
    URLSession.shared.dataTask(with: r) { d, resp, _ in
      let ok = (resp as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
      fini(ok ? d : nil)
    }.resume()
  }
}
