import Foundation

// ÉTAT ET ERREURS DE SYNCHRO — ports de `restErrStatus`, `isPersoRepairCandidate`,
// `explainSyncError`, `setSyncChip` (états et libellés) et `notifyConflicts`.
//
// Une erreur de synchro est montrée à un soignant, pas à un informaticien : elle se traduit en
// {icône, titre, détail} en français, et le DÉTAIL dit toujours ce qui se passe pour ses fiches
// (« vos modifications restent sur cet appareil »). Les textes sont repris À L'OCTET de la PWA.

/// `restErrStatus(message)` : statut HTTP lu dans un message « REST <code> … » (sinon nil).
public func restErrStatus(_ message: String) -> Int? {
    guard message.hasPrefix("REST ") else { return nil }
    let digits = message.dropFirst(5).prefix { $0.isASCII && $0.isNumber }
    return digits.isEmpty ? nil : Int(digits)
}

/// `isPersoRepairCandidate(message, isPerso)` : une fiche PERSO refusée en 403 = son id est déjà
/// pris dans le cloud par un AUTRE compte (clé primaire globale) — candidate à la réparation.
public func isPersoRepairCandidate(_ message: String, isPerso: Bool) -> Bool {
    isPerso && restErrStatus(message) == 403
}

/// Familles d'icônes (`SYNC_ERR_ICONS`) : un dessin par nature d'erreur.
public enum SyncErrorIcon: String, Sendable, CaseIterable {
    case lock, forbidden, image, warning, server, offline, unknown
}

public struct SyncErrorInfo: Equatable, Sendable {
    public var icon: SyncErrorIcon
    public var title: String
    public var detail: String
    public init(icon: SyncErrorIcon, title: String, detail: String) { self.icon = icon; self.title = title; self.detail = detail }
    /// Repli de la fenêtre d'erreur quand aucune erreur n'est connue.
    public static let unknownFallback = SyncErrorInfo(icon: .unknown, title: "Erreur inconnue", detail: "Aucun détail disponible.")
}

/// Port de `explainSyncError(e)`.
///
/// ÉCART VOULU (spec D, Q7) : un délai dépassé (`NET timeout 25000 ms`) tombait sur le web dans
/// « Erreur inattendue » (le message ne ressemble à aucun motif réseau). Le natif le classe en
/// « Serveur injoignable » — c'est ce qu'il est, et la conduite à tenir est la même (attendre, la
/// synchro réessaie seule). Une erreur du stockage local est classée « Stockage momentanément
/// indisponible », son équivalent natif du `InvalidStateError` d'IndexedDB.
public func explainSyncError(_ error: Error) -> SyncErrorInfo {
    if let c = error as? CloudError {
        switch c {
        case .timeout, .network: return SyncErrorTexts.offline
        case .localStore: return SyncErrorTexts.storage
        default: return explainSyncError(message: c.message)
        }
    }
    if error is URLError { return SyncErrorTexts.offline }
    return explainSyncError(message: String(describing: error))
}

/// Même classement, à partir du seul MESSAGE (forme testée contre la PWA). `isTypeError` reproduit
/// `e instanceof TypeError` (les erreurs de `fetch`).
public func explainSyncError(message msg: String, isTypeError: Bool = false) -> SyncErrorInfo {
    let status = restErrStatus(msg)
    if status == 401 { return SyncErrorTexts.expired }
    if status == 403 { return SyncErrorTexts.forbidden }
    if status == 413 { return SyncErrorTexts.tooLarge }
    if status == 409 { return SyncErrorTexts.conflict }
    if let s = status, s >= 500 { return SyncErrorTexts.server }
    // `!status` : en JS 0 est aussi « sans statut » (« REST 0 » n'existe pas en pratique).
    let noStatus = status == nil || status == 0
    let lower = msg.lowercased()
    if noStatus && (isTypeError || ["fetch", "network", "internet", "load failed"].contains(where: { lower.contains($0) })) {
        return SyncErrorTexts.offline
    }
    if noStatus && ["database connection is closing", "database is closing", "invalidstateerror", "idb-closed"].contains(where: { lower.contains($0) }) {
        return SyncErrorTexts.storage
    }
    return SyncErrorInfo(icon: .unknown, title: "Erreur inattendue", detail: "Détail technique : " + JS.prefix(msg, 200))
}

enum SyncErrorTexts {
    static let expired = SyncErrorInfo(icon: .lock, title: "Session expirée",
        detail: "Votre connexion au compte a expiré. Reconnectez-vous depuis la fenêtre « Compte » pour reprendre la synchronisation.")
    static let forbidden = SyncErrorInfo(icon: .forbidden, title: "Écriture refusée",
        detail: "Le serveur a refusé d'enregistrer certaines fiches. Cause la plus fréquente : vos droits sur une bibliothèque partagée ont changé (rôle modifié ou accès retiré par un administrateur) — ces fiches restent lisibles mais vos modifications n'y sont plus publiées. Autre cause possible : une fiche venue d'un autre compte (import) porte un identifiant déjà pris ; l'app la répare alors automatiquement à la prochaine tentative. Le reste de votre bibliothèque continue de se synchroniser.")
    static let tooLarge = SyncErrorInfo(icon: .image, title: "Contenu trop volumineux",
        detail: "Une fiche contient des images trop lourdes, ou un document PDF dépasse la taille maximale autorisée (15 Mo). Réduisez ou supprimez des images, ou allégez le document, puis réessayez.")
    static let conflict = SyncErrorInfo(icon: .warning, title: "Conflit de données",
        detail: "Une incohérence a été détectée en enregistrant vos données. Nouvelle tentative automatique en cours ; si le problème persiste, exportez vos fiches par sécurité (fenêtre Compte → « Exporter mes données »).")
    static let server = SyncErrorInfo(icon: .server, title: "Service indisponible",
        detail: "Le service de synchronisation rencontre un problème de son côté (indépendant de votre appareil ou de votre connexion). Nouvelle tentative automatique en cours.")
    static let offline = SyncErrorInfo(icon: .offline, title: "Serveur injoignable",
        detail: "La connexion Internet semble fonctionner, mais le service de synchronisation n'a pas répondu (réseau instable, Wi-Fi d'hôtel/hôpital filtrant, coupure temporaire...). Nouvelle tentative automatique en cours ; vos modifications restent sur cet appareil en attendant.")
    static let storage = SyncErrorInfo(icon: .warning, title: "Stockage momentanément indisponible",
        detail: "L'accès au stockage de cet appareil s'est interrompu pendant la synchronisation — le plus souvent parce que l'application est ouverte dans un autre onglet, ou parce que la page était en train d'être rechargée. Aucune donnée n'est perdue : vos fiches restent sur cet appareil et la synchronisation reprend automatiquement. Si le message revient, fermez les autres onglets de l'application puis rechargez cette page.")
}

// MARK: - Pastille d'état (`setSyncChip`)

/// Les six états de la pastille, SOURCE UNIQUE des trois surfaces (pastille du pied, bandeau
/// d'accueil, ligne d'état de la fenêtre Compte).
public enum SyncState: String, Sendable, CaseIterable {
    case ok, busy, off, err, pending, rejected
    /// Nom d'icône (`SYNC_ICO`).
    public var icon: String {
        switch self {
        case .ok: return "check"
        case .busy: return "history"
        case .off: return "pause"
        case .err, .rejected: return "warn"
        case .pending: return "lock"
        }
    }
    /// La pastille ouvre quelque chose au toucher (fenêtre d'erreur, ou fenêtre Compte).
    public var isTappable: Bool { self == .err || self == .pending || self == .rejected }
    /// Infobulle (`chip.title`).
    public var tooltip: String {
        switch self {
        case .err: return "Cliquer pour voir le détail de l'erreur"
        case .pending, .rejected: return "Cliquer pour plus d'informations"
        default: return ""
        }
    }
}

public struct SyncStatus: Equatable, Sendable {
    public var state: SyncState
    public var text: String
    public init(_ state: SyncState, _ text: String) { self.state = state; self.text = text }

    public static let connected = SyncStatus(.ok, "Connecté")
    public static let synced = SyncStatus(.ok, "Synchronisé")
    public static let busy = SyncStatus(.busy, "Synchro en cours")
    public static let offline = SyncStatus(.off, "Hors-ligne")
    public static let error = SyncStatus(.err, "Erreur de synchro")
    public static let pending = SyncStatus(.pending, "En attente de validation")
    public static let rejected = SyncStatus(.rejected, "Compte refusé")

    /// Ligne d'état de la fenêtre Compte (`authStateHtml`) : à l'état `ok`, l'heure de la
    /// dernière synchro réussie est ajoutée (« Synchronisé · 14:05 ») — la FRAÎCHEUR est une
    /// information de confiance.
    public func accountLine(lastSyncAt: Double, timeZone: TimeZone = .current) -> String {
        guard state == .ok, lastSyncAt > 0 else { return text }
        return text + " · " + hhmm(lastSyncAt, timeZone: timeZone)
    }

    /// Bandeau d'accueil (`updateSyncBanner`) : (titre gras, suite) ou nil.
    public func homeBanner(lastError: SyncErrorInfo?) -> (bold: String, rest: String)? {
        switch state {
        case .err: return ("Erreur de synchronisation", " — " + (lastError?.title ?? "Erreur de synchronisation") + " · Nouvelle tentative automatique en cours")
        case .pending: return ("Compte en attente de validation", " — vos fiches restent sur cet appareil en attendant")
        case .rejected: return ("Demande de compte refusée", " — vos fiches restent sur cet appareil")
        default: return nil
        }
    }
}

/// « HH:MM » (heure locale) d'un horodatage en millisecondes.
public func hhmm(_ ms: Double, timeZone: TimeZone = .current) -> String {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = timeZone
    let c = cal.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: ms / 1000))
    let h = c.hour ?? 0, m = c.minute ?? 0
    return (h < 10 ? "0" : "") + String(h) + ":" + (m < 10 ? "0" : "") + String(m)
}

// MARK: - Nouvelles non bloquantes (toasts)

/// Ce que la synchro a à DIRE à l'utilisateur. L'app les affiche en toast — et les RETIENT pendant
/// une session de crise (règle 11 : aucune notification flottante sur une checklist), pour les
/// rejouer à la fin.
public enum SyncNotice: Equatable, Sendable {
    /// `notifyConflicts` : des fiches modifiées ici ont été remplacées par une version plus récente.
    case conflicts([String])
    /// `_reclaimBlocked` : modifications non publiables, droits perdus sur une bibliothèque.
    case rightsLost(names: [String], copied: Bool, restoredDelete: Bool)

    public var message: String {
        switch self {
        case .conflicts(let l):
            let n = l.count, s = n > 1 ? "s" : ""
            return "⚠ \(n) fiche\(s) modifiée\(s) sur un autre appareil. Version la plus récente appliquée ; votre version précédente est conservée (bouton « Versions » dans la fiche)."
        case .rightsLost(let names, let copied, let restoredDelete):
            let n = names.count
            var m = "Vos modifications sur « " + (names.first ?? "") + " »"
            if n > 1 { m += " (et \(n - 1) autre" + (n > 2 ? "s" : "") + ")" }
            m += " n\u{2019}ont pas pu être publiées : vos droits sur la bibliothèque ont changé."
            if copied { m += " Votre version a été copiée dans « Perso »." }
            if restoredDelete { m += " La suppression a été annulée (version de l\u{2019}équipe restaurée)." }
            return m
        }
    }
    /// Durée d'affichage (ms).
    public var durationMs: Int {
        switch self { case .conflicts: return 9000; case .rightsLost: return 12000 }
    }
}
