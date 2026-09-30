import Foundation

/// PARTAGE — TOUS les mots de l'interface, recopiés À L'IDENTIQUE de la PWA (apostrophes
/// typographiques `’` et espaces insécables U+00A0 compris : ce sont les mêmes phrases sur les
/// deux clients, et certaines — la notice de l'écran d'entrée — sont un document OPPOSABLE,
/// couplé au registre RGPD `docs/deploiement-et-conformite.md` § 3.1 : les deux changent
/// ensemble, ou aucun).
///
/// ⚠ La notice promet « Rien n'est installé sur cet appareil » : c'est vrai d'un navigateur,
/// PAS d'une app native installée (spec E § 21 Q15). `joinIntroWeb` est donc gardée pour
/// référence, et l'app native doit faire valider sa propre formulation avant publication.
public enum ShareStrings {
    // MARK: Quai (§ 16.3)
    public static let quaiShared = "● Partagé", quaiSession = "● Session", quaiExercise = "▲ Exercice"
    public static let statusTag: [String: String] = ["revoked": "coupé", "expired": "fini", "ended": "fini", "detached": "seul"]
    public static let tagStale = "figé", tagOffered = "offert", tagLead = "main", tagScribe = "suit"
    /// Mots du quai posés 8 s par `slSay`.
    public static let sayDirect = "Passe en direct", sayFollowDirect = "Suivi en direct", sayBackOnline = "Repasse en ligne",
        sayStandbyReady = "Secours prêt", sayExpired = "Partage expiré", sayLost = "Connexion perdue"

    // MARK: Phrases du lecteur d'écran (§ 17.12)
    public static func following(_ title: String) -> String { "Vous suivez : " + title }
    public static func joined(_ label: String?) -> String { (label?.isEmpty == false ? label! : "Un participant") + " a rejoint la session." }
    public static func advanced(_ label: String?) -> String { (label?.isEmpty == false ? label! : "un participant") + " a avancé la checklist." }
    public static func actions(_ n: Int) -> String { n == 1 ? "Une action d’un participant" : "\(n) actions d’un participant" }
    public static let leadBack = "La main vous revient."
    public static let leadReturnedToHost = "La main est revenue au soignant qui a ouvert la session."
    public static let tookLead = "Vous avez pris la main."
    public static let gaveLead = "Vous avez passé la main."
    public static let continueAloneDone = "Vous poursuivez seul."
    public static func mirrorSeenAt(_ hhmm: String) -> String { "Vue à " + hhmm + " — miroir, pas du direct." }
    public static let returnReceived = "Repères de l’invité reçus — le journal est annoté."
    public static let followingOnline = "Vous suivez en ligne."
    // Phrases longues de `slSay`
    public static let srStandbyReady = "Secours direct prêt — la session continuerait sans internet."
    public static let srNetDropped = "Le réseau a lâché — le partage continue en direct."
    public static let srGoDirect = "Le partage passe en direct — les participants suivent."
    public static let srFollowDirect = "Vous suivez en direct."
    public static let srBackOnlineHost = "Internet est revenu — le partage repasse en ligne."
    public static let srBackOnlineGuest = "Internet est revenu — vous suivez de nouveau en ligne."
    public static let srBackOnlineGeneric = "Le partage repasse en ligne."
    public static let srRehosted = "Le partage reprend après le rechargement."
    public static let srExpired = "Le partage a expiré pendant la coupure — reconnectez-vous avec un nouveau code."
    public static let srWakeLost = "Le lien direct n’a pas survécu à la veille — ré-appariez depuis la feuille de partage."

    // MARK: Refus d'un geste (§ 11.13)
    public static let refuseStopped = "Le partage est arrêté : votre action n’est pas transmise."
    public static let refuseCheck = "Vous ne pouvez pas cocher cette étape."
    public static let refuseUncheck = "Décocher revient à celui qui conduit la checklist."
    public static let refuseLeadOnly = "Ce geste revient à celui qui conduit la checklist."
    public static let refuseLeadOnlyStopped = "Le partage est arrêté : ce geste n’est pas transmis."
    public static let refuseRevoked = "Votre accès a été retiré : ce geste n’est plus transmis."
    public static let refuseEnded = "Le partage est terminé : ce geste n’est plus transmis."

    // MARK: Bandeau figé de l'invité (§ 17.8)
    public static let frozenTitle = "Le partage de session a été interrompu."
    public static let frozenCause: [String: String] = [
        "revoked": "Votre accès a été retiré par le soignant qui conduit la session.",
        "expired": "Le partage a atteint sa durée maximale.",
        "ended": "Le soignant a terminé la session.",
    ]
    public static let frozenSolo = "Vous teniez la main : cet écran reste le vôtre et vous poursuivez la checklist — plus rien n’y est transmis ni reçu."
    public static let frozenStatic = "Cet écran reste lisible, figé sur le dernier état reçu — plus rien n’y est transmis ni reçu."
    public static let rejoin = "Rejoindre à nouveau…", quit = "Quitter le partage…"

    // MARK: Feuilles (§ 17.1-17.7)
    public static let sheetHostTitle = "Partager cette session", sheetGuestTitle = "Session partagée"
    public static let stepsHeader = "À faire, dans l’ordre", stepsHeaderShort = "À faire"
    public static let modeOnline = "en ligne", modeDirect = "en direct", modeOptic = "par l’écran"
    public static let modeWordAuto = "automatique", modeWordForcedOptic = "forcé, par l’écran", modeWordForcedDirect = "forcé, en direct"
    public static func modeLink(_ w: String) -> String { "Mode : " + w + " ›" }
    public static func participantsCount(_ n: Int) -> String { n == 0 ? "" : " · \(n) participant" + (n > 1 ? "s" : "") }
    public static func whyLost(_ hhmm: String, guest: Bool) -> String {
        "Connexion perdue à " + hhmm + " — aucun réseau : chacun vise l’écran de l’autre, à tour de rôle."
            + (guest ? " Continuez : vos gestes sont gardés et partiront au retour du réseau." : "")
    }
    public static func whyHostQuiet(_ hhmm: String) -> String {
        "L’hôte ne donne plus signe depuis " + hhmm + " (écran verrouillé, autre application ou réseau\u{00a0}: la cause n’est pas connue). Rien n’est perdu\u{00a0}: ce que vous relevez lui parviendra, et sa progression se mettra à jour à son retour. Sans réseau de son côté, recevez-la par l’écran."
    }
    public static let whyCloud = "Internet répond — rien à régler."
    public static let whyOptic = "Aucun réseau : chacun vise l’écran de l’autre, à tour de rôle."
    public static let whyDirectNoAccount = "Sans compte, le partage se fait en direct — un Wi-Fi commun suffit, même sans internet."
    public static let whyDirectReachable = "Sans passer par le serveur — par le Wi-Fi commun."
    public static let whyDirectNoInternet = "Pas d’internet, mais un Wi-Fi commun : vos téléphones se relient entre eux."
    public static let whyMirror = "Instantané daté, pas du direct\u{00a0}: chacun vise l’écran de l’autre, à tour de rôle."

    public static let opticHost: [(title: String, sub: String)] = [
        ("Montrer ma progression", "votre collègue vise votre écran avec son appareil photo"),
        ("Recevoir ses repères", "vous visez son écran ; ses heures notées entrent dans votre journal"),
        ("Refaire l’étape 1 après chaque bloc franchi", "dès que le réseau revient, le partage reprend seul — et ainsi de suite"),
    ]
    public static let opticGuest: [(title: String, sub: String)] = [
        ("Recevoir la progression", "visez l’écran de la personne qui mène la session"),
        ("Renvoyer mes repères", "elle vise votre écran ; vos heures notées entrent dans son journal"),
        ("Refaire l’étape 1 après chaque bloc franchi", "dès que le réseau revient, le partage reprend seul — et ainsi de suite"),
    ]
    public static let hintHostReceives = "Visez l’écran de l’invité", hintGuestReceives = "Visez l’écran de l’hôte"
    public static let hintAnswer = "Visez la réponse de l’invité", hintAny = "Visez le code ou l’écran de l’hôte", hintDefault = "Visez le code"
    public static let answerStale = "Réponse périmée — attendez la nouvelle"
    public static let connecting = "Connexion…"
    public static let showAnswer = "Montrez ce code à l’hôte, la connexion suivra."
    public static let pairFailedRetry = "Ça n’a pas abouti — réessayez."
    public static let codeIllisible = "Code illisible — réessayez."

    // Hôte, en ligne
    public static let stepScanCode = ("Faites scanner ce code", "ou dictez-le — il ne sert qu’à une personne, pendant 2 min")
    public static let stepThatsAll = ("C’est tout", "votre collègue apparaît ci-dessous ; ce qu’il coche et note entre dans votre journal")
    public static func stepCodeTaken(_ by: String?) -> (String, String) {
        ("Code scanné", (by != nil ? by! + " a rejoint" : "la porte est fermée") + " — un code ne sert qu’une fois")
    }
    public static let stepNothingElse = ("Rien d’autre", "la session se suit seule ; si internet se coupe, les étapes s’affichent ici")
    public static func countdown(_ ms: Double) -> String {
        ms > 0 ? "encore \(Int((ms / 1000).rounded(.up))) s" : "code expiré — « Inviter quelqu’un d’autre » en donne un nouveau"
    }
    public static let sendLink = "Envoyer le lien…"
    public static let noShareableAddress = "Cette page n’a pas d’adresse partageable (fichier local) : le code seul est encodé. Donnez à votre collègue l’adresse de l’application."
    public static let linkCopied = "Lien copié — collez-le dans un message."
    public static let copyFailed = "⚠ Copie impossible — dictez l’adresse de l’application, puis le code."
    public static let inviteOther = "Inviter quelqu’un d’autre"
    public static let admitFailed = "⚠ Impossible d'ouvrir un nouveau code."
    public static let stopShare = "Arrêter le partage…"
    public static let stopTitle = "Arrêter le partage ?", stopYes = "Arrêter"
    public static func stopTextLeadHeld(_ label: String?) -> String {
        "⚠ " + (label?.isEmpty == false ? label! : "Un participant") + " conduit la session — vous lui avez donné la main.\n"
            + "• Arrêter coupe le lien : son écran reste le sien, mais vous ne verrez plus ce qu’il fait, et sa suite n’entrera pas dans votre compte-rendu.\n"
            + "• Pour reprendre la conduite sans couper : « Reprendre la main »."
    }
    public static let stopText = "Les participants ne suivront plus la session.\n• Votre session continue.\n• Le relevé de chacun reste dans votre compte-rendu."
    public static let stopTextDirect = "Les participants ne suivront plus la session.\n• Votre session continue."

    // Hôte, en direct
    public static let stepPairScan = ("Faites scanner ce code", "avec l’appareil photo de son téléphone")
    public static let stepPairAnswer = ("Scannez la réponse", "elle s’affiche sur son écran")
    public static let scanAnswer = "Scanner la réponse"
    public static let tryOptic = "Rien après 10\u{00a0}s\u{00a0}? Passer par l’écran"
    public static let stepDirectAll = ("C’est tout", "la session suit en direct\u{00a0}; si internet revient, le partage repasse en ligne seul")
    public static let stepInvite = ("Inviter quelqu’un", "personne ne suit encore"), inviteNew = "Inviter — nouveau code"
    public static let stepRepair = ("Ré-apparier", "un invité a perdu le lien — un nouveau code à scanner"), repairNew = "Ré-apparier — nouveau code"
    public static let pairFailed = "⚠ Ça n’a pas abouti", retry = "Réessayer", byScreen = "Par l’écran", continueWithout = "Continuer sans partage"

    // Participants
    public static let participantsHeader = "Participants", nobody = "Personne pour l’instant.", guestDefault = "Invité"
    public static let partRevoked = "coupé", partDetached = "seul", partLeft = "parti", partAbsent = "absent", partCutting = "coupure…",
        partLead = "conduit", partScribe = "relève"
    public static func partQuiet(_ minutes: Int) -> String { "· sans nouvelles \(minutes) min" }
    public static let reclaimLead = "Reprendre la main", giveLead = "Donner la main", leadOffered = "proposée…", cut = "Couper"
    public static let partLegend = "Relève : coche et note, ne revient pas en arrière. Donner la main : il mène la session à votre place. Couper : il ne suit plus, sans perdre son écran."
    public static let reclaimFailed = "⚠ La main n'a pas pu être reprise — réessayez."
    public static let cutFailed = "⚠ La coupure n'a pas pu être transmise — réessayez."

    // Invité
    public static let guestFollowing = "● Vous suivez la session", guestMirror = "● Miroir"
    public static let stepReconnect = ("Se reconnecter", "le partage a expiré pendant la coupure — demandez un nouveau code"), reconnect = "Se reconnecter…"
    public static let stepReceiveQuiet = ("Recevoir la progression", "par l’écran de l’hôte, s’il n’a plus de réseau\u{00a0}; sinon tout se met à jour à son retour"), receive = "Recevoir"
    public static let stepNothing = ("Rien", "la session se suit seule\u{00a0}; si le réseau se perd, les étapes s’affichent ici")
    public static let yourRole = "Votre rôle"
    public static let roleLead = "Conduit\u{00a0}: vous menez la session\u{00a0}; l’hôte peut reprendre la main."
    public static let roleScribe = "Relève\u{00a0}: vous cochez et notez, sans revenir en arrière — «\u{00a0}Noter l’heure\u{00a0}» (dock) pose un repère daté."
    public static let showOtherScreen = "Montrer à un autre écran"

    // Optique (§ 17.5)
    public static let opticNote = "⇆ Par l’écran — l’autre appareil filme, c’est tout · instantané daté, pas du direct"
    public static let returnNote = "⇆ Retour — l’hôte filme cet écran · repères datés seulement"
    public static let loopCaption = "le code change tout seul — restez face à face", sending = "en cours d’envoi"
    public static let receiveBack = "Recevoir en retour", stop = "Arrêter", done = "Terminé"
    public static let qrLabelOptic = "Synchro par l’écran", qrLabelCode = "Code de session à scanner",
        qrLabelPair = "Code d’appariement — à scanner par l’invité", qrLabelAnswer = "Réponse — à faire scanner par l’hôte"
    public static let rxIllegible = "Réception illisible — réessayez.", snapIllegible = "Instantané illisible."
    public static let opticOtherSession = "Cet écran diffuse une AUTRE session — réception refusée, rien n’a été écrit."
    public static let returnOtherSession = "Ce retour concerne une AUTRE session — rien n’a été écrit."
    public static let returnDone = "Repères reçus — le journal est annoté, aucune coche modifiée."
    public static let returnNothing = "Aucun repère daté à renvoyer. Les coches ne remontent pas par l’écran — seuls les repères datés annotent le journal de l’hôte : « Noter l’heure » (dock) en crée un."
    public static let cameraRefused = "⚠ Caméra non autorisée", allowCamera = "Autoriser la caméra", cancel = "Annuler"

    // Bandeau de lien (§ 16.4)
    public static let linkOptic = "Par l’écran", linkHostQuiet = "Hôte silencieux"
    public static func linkTitleHostQuiet(_ hhmm: String) -> String { "L’hôte ne donne plus signe depuis " + hhmm + " — cause non connue (veille, autre application ou réseau)\u{00a0}; rien n’est perdu" }
    public static func linkTitleLost(_ hhmm: String, guest: Bool) -> String { "Connexion perdue depuis " + hhmm + (guest ? " — vos gestes partiront au retour du réseau" : "") }
    public static let linkTitleOptic = "Mode par l’écran — chacun vise l’écran de l’autre"
    public static let linkShow = "① Montrer", linkRx = "② Recevoir", linkRx1 = "① Recevoir", linkRet = "② Renvoyer"
    public static let linkWhyLabel = "Pourquoi ? — les étapes du partage", linkWhyTitle = "Pourquoi ?"

    // Feuille « Mode » (§ 17.4)
    public static let modeSheetTitle = "Changer manuellement le mode", back = "‹ Retour"
    public static let modeLegend = "Utile seulement si l’app se trompe. Un choix fait ici tient jusqu’au retour à « Automatique ». Vos invités suivent sans rien faire entre en ligne et en direct ; par l’écran, leurs étapes s’affichent chez eux."
    public static let modeRows: [(title: String, sub: String)] = [
        ("Automatique", "l’app choisit le mode et bascule seule, dans les deux sens"),
        ("En ligne", "par internet, avec votre compte"),
        ("En direct", "Wi-Fi commun, sans internet — chacun scanne l’autre une fois"),
        ("Par l’écran", "sans aucun réseau — montrer et recevoir, à tour de rôle"),
    ]
    public static let modeActive = "actif", modeNeedsAccount = "compte nécessaire", modeNoInternet = "pas d’internet", modeReady = "prêt", modeAlways = "toujours"
    public static let modeFooter = "Un mode indisponible reste tapable et dit pourquoi."
    public static func cloudWhy(noAccount: Bool) -> String {
        (noAccount ? "« En ligne » nécessite un compte : c’est le serveur du compte qui héberge la session."
                   : "« En ligne » nécessite internet.")
            + " « En direct » relie les appareils par un code à scanner, sans serveur (un Wi-Fi commun suffit, même sans internet) ; « Par l’écran » passe la session en codes filmés à la caméra, sans aucun réseau."
    }
    public static let goDirectTitle = "Passer en direct ?", goDirectYes = "Passer en direct"
    public static let goOnlineTitle = "Passer en ligne ?", goOnlineYes = "Passer en ligne"
    public static func goDirectReady(ready: Int, total: Int) -> String {
        "Le partage continue en direct, sans serveur.\n"
            + (ready >= total ? "• Vos participants basculent seuls — personne ne scanne."
               : "• \(ready) participant" + (ready > 1 ? "s" : "") + " sur \(total) bascule" + (ready > 1 ? "nt" : "") + " seul" + (ready > 1 ? "s" : "") + ".\n• Les autres scannent le nouveau code.")
            + "\n• Votre session ne bouge pas."
    }
    public static let goDirectNobody = "Le partage passe en direct, sans serveur.\n• Personne n’a encore rejoint : un code à scanner s’affichera.\n• Votre session ne bouge pas."
    public static let goDirectNotReady = "Le secours direct n’est pas encore prêt — il se forme quelques secondes après chaque arrivée.\n• Maintenant : chaque participant scanne un nouveau code.\n• Dans quelques secondes (« prêt » dans la liste) : bascule sans scan."
    public static let goDirectNotReadyYes = "Basculer quand même", goDirectNotReadyNo = "Attendre"
    public static let goOnlineWithGuests = "Le partage repasse en ligne, par le serveur.\n• Vos participants basculent seuls — personne ne ressaisit de code.\n• Votre session ne bouge pas."
    public static let goOnlineFresh = "Le partage repasse en ligne, par le serveur.\n• Chaque participant rejoint avec le nouveau code.\n• Votre session ne bouge pas."
    public static let draftRefused = "⚠ Une fiche en brouillon ne se diffuse pas hors du compte."
    public static let staysDirect = "⚠ Internet indisponible — le partage reste en direct."
    public static let serverUnreachable = "⚠ Serveur injoignable — partage en direct."
    public static let directFailed = "⚠ Le partage en direct n’a pas pu démarrer."

    // Menus (§ 17.10)
    public static func menuShareOngoing(_ n: Int) -> (String, String) { ("Partage en cours (\(n))", "code, participants, arrêt") }
    public static let menuShare = "Partager la session…", menuShareSubStarted = "un collègue suit en direct", menuShareSubStart = "démarre la session, puis partage"
    public static let menuTakeLead = ("Prendre la main", "vous conduirez la checklist")
    public static let menuReconnect = ("Se reconnecter…", "scanner ou saisir un nouveau code de l’hôte")
    public static let menuContinueAlone = ("Continuer seul…", "le lien ne répond plus")
    public static let menuByScreen = ("Par l’écran…", "resynchroniser ou renvoyer vos repères")
    public static let menuShowOther = ("Montrer à un autre écran", "la session défile en codes — l’autre filme")
    public static let menuQuit = ("Quitter le partage…", "vous ne suivrez plus la session")
    public static let menuBackToShared = "Revenir à la session partagée"

    // Dialogues (§ 17.11)
    public static let startShareTitle = "Démarrer et partager ?", startShareYes = "Démarrer et partager"
    public static let startShareText = "Partager exige une session en cours. Démarrer la session maintenant (chrono, minuteurs et journal des actions) puis ouvrir le partage ?"
    public static let startShareTextLocal = "Partager exige une session en cours. Démarrer la session maintenant (chrono, minuteurs et journal des actions) ?"
    public static let openAidFirst = "⚠ Ouvrez d’abord l’aide cognitive à partager."
    public static let continueAloneTitle = "Continuer seul ?", continueAloneYes = "Continuer seul"
    public static let continueAloneText = "Vous ne verrez plus ce que fait l’équipe, mais vous gardez cet écran et pouvez continuer. Ce que vous avez relevé sera reporté au compte rendu du soignant, en annexe, dès que le réseau reviendra — vos coches, elles, ne remonteront pas."
    public static let quitTitle = "Quitter le partage ?", quitYes = "Quitter"
    /// Texte du dialogue « Quitter le partage ? » (`quitShare`).
    public static func quitText(unsent: (n: Int, txt: String, mirror: Bool)?, noTrace: Bool) -> String {
        var alert = ""
        if let u = unsent {
            alert = "⚠ " + u.txt + " relevé" + (u.n > 1 ? "s" : "") + " ici n’" + (u.n > 1 ? "ont" : "a") + " pas été transmis"
                + (u.mirror ? " — « Renvoyer mes repères » avant de quitter les remettrait à l’hôte." : " à l’hôte — ils seront perdus.") + " "
        }
        return alert + "Vous ne verrez plus cette session. Ce que vous avez déjà relevé " + (unsent != nil ? "d’AVANT la coupure " : "")
            + "reste dans le compte-rendu du soignant — c’est un enregistrement de soin. "
            + (noTrace ? "Pour revenir, il faudra un NOUVEAU code : un code ne sert qu’une fois." : "Votre bibliothèque et vos fiches sont inchangées.")
    }
    /// `shareUnsent` : la file de l'invité décomptée par nature (« 2 coches, 1 repère »).
    public static func unsentSummary(queue: [JSON]) -> (n: Int, txt: String, mirror: Bool)? {
        guard !queue.isEmpty else { return nil }
        func cnt(_ ks: [String]) -> Int { queue.filter { ks.contains($0["kind"]?.string ?? "") }.count }
        var parts: [String] = []
        let c = cnt(["check"]); if c > 0 { parts.append("\(c) coche" + (c > 1 ? "s" : "")) }
        let m = cnt(["mark", "mark_void"]); if m > 0 { parts.append("\(m) repère" + (m > 1 ? "s" : "")) }
        let n = cnt(["counter"]); if n > 0 { parts.append("\(n) compteur" + (n > 1 ? "s" : "")) }
        let t = cnt(["timer_arm", "timer_stop"]); if t > 0 { parts.append("\(t) minuteur" + (t > 1 ? "s" : "")) }
        let rest = queue.count - (c + m + n + t); if rest > 0 { parts.append("\(rest) autre" + (rest > 1 ? "s" : "")) }
        return (queue.count, parts.joined(separator: ", "), false)
    }

    // MARK: Écran d'entrée (§ 17.9)
    public static let joinAppName = "Aides cognitives", joinTitle = "Rejoindre une session"
    public static let joinIntroWeb = "Vous allez suivre en direct la session ouverte par le soignant qui vous a montré ce code. Rien n'est installé sur cet appareil, et l'accès s'arrête avec la session."
    public static let joinCodeLabel = "Code affiché sur son écran", joinCodePlaceholder = "XXXX-XXXX"
    public static let joinRoleLabel = "Votre rôle, tel qu'il apparaîtra à l'équipe"
    /// Les NEUF intitulés — une liste FERMÉE (règle 15 : ce sélecteur ne devient jamais un champ).
    public static let roles = ["Médecin", "Interne", "IADE", "IDE", "Ambulancier", "Sage-femme", "Aide-soignant(e)", "Étudiant(e)", "Renfort"]
    public static let defaultRole = "Renfort"
    public static let joinButton = "Rejoindre", joinOffline = "Sans internet — l'hôte affiche un code d'appariement", scanCode = "Scanner un code"
    public static let joinNoticeSummary = "Ce qui est enregistré, et par qui"
    /// Les six paragraphes de la notice, SANS balisage. Côté web sont en gras : la phrase d'ouverture
    /// de chaque paragraphe (jusqu'au premier point ; « Vous pouvez partir à tout moment » pour le
    /// sixième), « Aucun texte libre n'est transmis », « en ligne », « relais », « en direct » et
    /// « par l'écran ».
    public static let joinNotice: [String] = [
        "Qui est responsable. La session appartient au soignant qui vous a montré le code — lui, ou son établissement. Cette application ne les connaît pas et ne peut donc pas les nommer ici : c'est à lui que s'adressent vos questions et vos droits.",
        "Ce qui est enregistré. Le rôle choisi ci-dessus, l'heure de vos actions et les étapes que vous cochez ou constatez. Aucun texte libre n'est transmis, et rien de ce que vous écririez sur cet appareil ne part : les repères voyagent comme des références, jamais comme des mots. N'inscrivez aucune information permettant d'identifier le patient.",
        "Pourquoi. Tenir la trace des gestes réalisés en équipe pendant le soin, pour le compte rendu et le débriefing. Base légale : l'intérêt légitime du responsable à disposer d'une trace fiable de la prise en charge.",
        "Où et combien de temps. Avec un code de session (en ligne), les évènements transitent par le serveur de synchronisation de cette installation (Supabase), qui n'est qu'un relais : il est purgé automatiquement peu après la fin de la session. Avec un code d'appariement scanné (en direct) ou une réception par l'écran, rien ne quitte les appareils présents : les données passent de l'un à l'autre directement — réseau local chiffré ou lumière de l'écran — sans serveur ni tiers. Le compte rendu, lui, reste sur l'appareil de l'hôte, sans durée fixée par l'application.",
        "Qui d'autre le voit. Les autres participants de cette session voient votre rôle et vos actions — c'est le but : savoir qui a fait quoi.",
        "Vous pouvez partir à tout moment (et l'hôte peut vous retirer l'accès). Ce que vous avez déjà relevé reste dans son compte rendu : c'est un enregistrement de soin, il ne s'efface pas rétroactivement.",
    ]
    public static func joinBadChars(_ chars: [String]) -> String {
        "Ces caractères ne figurent jamais dans un code : " + chars.joined(separator: " ") + ". Le jeu évite 0, 1, I et O, qui se confondent à l’œil."
    }
    public static func joinLength(_ n: Int) -> String { "Un code compte 8 caractères — vous en avez saisi \(n)." }
    public static let joinNoNetwork = "Pas de réseau. Rejoindre une session demande une connexion — une fois entré, une coupure ne vous met pas dehors."
    public static let joinRefusedTyped = "Ce code n’ouvre pas de session. Relisez-le sur l’écran du soignant, puis demandez-lui un nouveau code : un code ne sert qu’une fois."
    public static let joinRefusedScanned = "Ce code n’ouvre pas de session. Demandez un nouveau code au soignant : un code ne sert qu’une fois."
    public static let joinRefusedAgain = "Ce code a déjà été refusé. Seul un nouveau code peut ouvrir la session — le soignant le voit sur son écran."
    public static let codeRecognized = ("Code de session reconnu", "Vous allez suivre la session d’un collègue")
    public static func joinWithCode(_ fmt: String) -> String { "Rejoindre " + fmt }
    public static let codeReceivedBanner = "Un code de session partagée a été reçu.", codeReceivedJoin = "Rejoindre"

    /// Le refus du serveur ne dit QU'UN mot (`refused`, sept causes indistinguables à dessein) :
    /// la rédaction se choisit sur des faits LOCAUX — déjà refusé ici ? scanné ou tapé ?
    public static func joinRefusal(code: String, refusedBefore: String?, scanned: Bool) -> String {
        if refusedBefore == code { return joinRefusedAgain }
        return scanned ? joinRefusedScanned : joinRefusedTyped
    }
}
