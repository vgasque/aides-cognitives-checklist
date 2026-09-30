import Foundation

// MODÈLE DE DONNÉES v4 — repris du grand commentaire d'architecture de `index.html`.
//
// Les structures sont TYPÉES pour l'interface, mais elles gardent un sac `extra` des clés
// inconnues aux niveaux où `migrate()` mute l'objet EN PLACE (aide, bloc, référence) : la PWA
// laisse « tout le reste voyager tel quel », et un client natif qui perdrait un champ ajouté
// demain par le web le supprimerait au prochain push de synchro. La sérialisation (`json`)
// rend exactement les clés qu'écrirait la PWA.

public enum Role: String, Codable, CaseIterable, Sendable {
    case entry, `do`, watch, dose, ddx
}

public enum Status: String, Codable, CaseIterable, Sendable {
    case validated, review, draft
    /// Libellés de l'éditeur (sélecteur segmenté).
    public var label: String {
        switch self { case .draft: return "Brouillon"; case .review: return "À revérifier"; case .validated: return "Validée" }
    }
}

/// Le MOMENT d'une étape dans un bloc parcouru plusieurs fois (A382).
public struct ItemFrom: Equatable, Hashable, Sendable {
    public var counter: String; public var n: Int
    public init(counter: String, n: Int) { self.counter = counter; self.n = n }
}
public enum Repeat: String, CaseIterable, Sendable { case due, once, need }

/// Un ITEM — l'unité de contenu (A-T6) : un objet à IDENTITÉ, plus une chaîne à une position.
public struct Item: Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var role: Role
    public var `do`: String
    public var expect: String
    /// 3 = ⚠ critique, 2 = △ vigilance, 1 = ordinaire.
    public var level: Int
    public var memory: Bool
    public var dual: Bool
    public var note: String
    /// A377 : la coche LANCE ce minuteur (exclusif avec `counts`).
    public var starts: String?
    /// A377 : la coche COMPTE sur ce compteur.
    public var counts: String?
    public var from: ItemFrom?
    public var `repeat`: Repeat?
    /// A396 : étape-revue (renvoi vers un bloc `review`).
    public var review: String?
    /// A397 : renvoi vers un repère posologique (item `dose`).
    public var poso: String?

    public init(id: String, role: Role = .do, do d: String = "", expect: String = "", level: Int = 1,
                memory: Bool = false, dual: Bool = false, note: String = "") {
        self.id = id; self.role = role; self.do = d; self.expect = expect; self.level = level
        self.memory = memory; self.dual = dual; self.note = note
    }

    public var isCritical: Bool { level == 3 }
    public var isVigilance: Bool { level == 2 }
    /// La chaîne v3 reconstruite (`v4ItemToStr`) : préfixe de registre, challenge, « :: », réponse.
    public var legacyString: String {
        (level == 3 ? "⚠ " : (level == 2 ? "△ " : "")) + self.do + (expect.isEmpty ? "" : " :: " + expect)
    }
}

public struct Excursion: Equatable, Hashable, Sendable {
    public var label: String
    public var target: String
    public var short: String?
    public init(label: String, target: String, short: String? = nil) { self.label = label; self.target = target; self.short = short }
}

public enum TimerKind: String, Sendable { case stopwatch, interval }

public struct TimerDef: Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var label: String
    public var type: TimerKind
    public var seconds: Int
    public var autoloop: Bool
    /// K7 : l'ACTION annoncée à l'échéance.
    public var onDue: String
    public var short: String?
    public init(id: String, label: String, type: TimerKind, seconds: Int = 0, autoloop: Bool = false, onDue: String = "", short: String? = nil) {
        self.id = id; self.label = label; self.type = type; self.seconds = seconds; self.autoloop = autoloop; self.onDue = onDue; self.short = short
    }
}

public struct CounterDef: Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var label: String
    public var step: Int
    public var start: Int
    /// Le « ＋ » relance ce minuteur ('' = aucun).
    public var timerId: String
    public var short: String?
    public init(id: String, label: String, step: Int = 1, start: Int = 0, timerId: String = "", short: String? = nil) {
        self.id = id; self.label = label; self.step = step; self.start = start; self.timerId = timerId; self.short = short
    }
}

/// Jalon de boucle (v5.5.0) : « au n-ième passage » ou « compteur ≥ n ».
public struct Milestone: Equatable, Hashable, Sendable {
    public enum At: String, Sendable { case pass, count }
    public var at: At
    public var n: Int
    public var counter: String
    public var text: String
    /// Renvoi vers une complication DÉCLARÉE ('' = aucun).
    public var go: String
    public init(at: At, n: Int, counter: String = "", text: String, go: String = "") {
        self.at = at; self.n = n; self.counter = counter; self.text = text; self.go = go
    }
}

public struct DecisionOption: Equatable, Hashable, Sendable {
    public var label: String
    public var target: String?
    public init(label: String, target: String?) { self.label = label; self.target = target }
}

public enum BlockKind: String, Sendable { case `do`, decision, review }

public struct Block: Equatable, Identifiable, Sendable {
    public var id: String
    public var kind: BlockKind
    public var title: String
    /// Héritée du bloc précédent si vide (`phaseOf`).
    public var phase: String
    public var image: String?
    public var imageW: Int
    public var imageH: Int
    /// A377 : minuteur relancé à chaque entrée dans le bloc.
    public var timer: String?
    public var milestones: [Milestone]
    // 'do' / 'review'
    public var items: [String]
    public var next: String?
    public var nextLbl: String
    // 'decision'
    public var question: String
    public var options: [DecisionOption]
    /// Clés inconnues, conservées telles quelles (voir l'en-tête du fichier).
    public var extra: [String: JSON]

    public init(id: String, kind: BlockKind = .do, title: String = "", phase: String = "", image: String? = nil,
                imageW: Int = 0, imageH: Int = 0, timer: String? = nil, milestones: [Milestone] = [],
                items: [String] = [], next: String? = nil, nextLbl: String = "",
                question: String = "", options: [DecisionOption] = [], extra: [String: JSON] = [:]) {
        self.id = id; self.kind = kind; self.title = title; self.phase = phase; self.image = image
        self.imageW = imageW; self.imageH = imageH; self.timer = timer; self.milestones = milestones
        self.items = items; self.next = next; self.nextLbl = nextLbl; self.question = question
        self.options = options; self.extra = extra
    }
    public var isDecision: Bool { kind == .decision }
}

public struct ImageRef: Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    /// data-URI base64 validée par `safeImg`.
    public var data: String
    public var w: Int
    public var h: Int
    public var caption: String
    /// Taille d'affichage, jeu fermé `MD_SCALES` (25/33/50/66/75/100).
    public var scale: Int
    public init(id: String, data: String, w: Int = 0, h: Int = 0, caption: String = "", scale: Int = 100) {
        self.id = id; self.data = data; self.w = w; self.h = h; self.caption = caption; self.scale = scale
    }
}

/// Métadonnées d'un document PDF joint (le binaire vit à part, jamais dans la fiche).
public struct Attachment: Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var size: Int
    public init(id: String, name: String, size: Int) { self.id = id; self.name = name; self.size = size }
}

/// Champs COMMUNS à une aide et à une référence (`sanitizeEntityCommon`).
public protocol Entity: Identifiable where ID == String {
    var id: String { get set }
    var title: String { get set }
    var code: String { get set }
    var discriminant: String { get set }
    var category: String { get set }
    var status: Status { get set }
    var validatedAt: String { get set }
    var images: [ImageRef] { get set }
    var docs: [Attachment] { get set }
    var links: [String] { get set }
    var sources: [String] { get set }
    var order: Double { get set }
    var updatedBy: String { get set }
    var updatedAt: Double { get set }
    var deletedAt: Double? { get set }
    var ownerId: String? { get set }
    var library: String? { get set }
    var extra: [String: JSON] { get set }
}

/// Une AIDE COGNITIVE (`kind: 'procedure'`).
public struct Fiche: Entity, Equatable, Sendable {
    public var id: String
    public var title: String = ""
    public var code: String = ""
    public var discriminant: String = ""
    public var category: String = ""
    public var status: Status = .validated
    public var validatedAt: String = ""
    public var images: [ImageRef] = []
    public var docs: [Attachment] = []
    public var links: [String] = []
    public var sources: [String] = []
    public var order: Double = 0
    public var updatedBy: String = ""
    public var updatedAt: Double = 0
    public var deletedAt: Double? = nil
    public var ownerId: String? = nil
    public var library: String? = nil
    public var extra: [String: JSON] = [:]
    // Spécifique à l'aide
    public var local: String = ""
    /// LE POOL : tous les items de l'aide, toutes portées confondues.
    public var items: [Item] = []
    public var excursions: [Excursion] = []
    public var blocks: [Block] = []
    public var start: String? = nil
    public var timers: [TimerDef] = []
    public var counters: [CounterDef] = []
    /// Marqueur LOCAL « à pousser » (jamais exporté).
    public var dirty: Bool = false

    public init(id: String) { self.id = id }
}

/// Une RÉFÉRENCE (ex-« protocole ») : document mini-Markdown et/ou PDF joints.
public struct Reference: Entity, Equatable, Sendable {
    public var id: String
    public var title: String = ""
    public var code: String = ""
    public var discriminant: String = ""
    public var category: String = ""
    public var status: Status = .validated
    public var validatedAt: String = ""
    public var images: [ImageRef] = []
    public var docs: [Attachment] = []
    public var links: [String] = []
    public var sources: [String] = []
    public var order: Double = 0
    public var updatedBy: String = ""
    public var updatedAt: Double = 0
    public var deletedAt: Double? = nil
    public var ownerId: String? = nil
    public var library: String? = nil
    public var extra: [String: JSON] = [:]
    /// Contenu rédigé (mini-Markdown, ≤ 20 000 caractères).
    public var body: String = ""
    public var dirty: Bool = false

    public init(id: String) { self.id = id }
}

public struct Category: Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var color: String
    /// nil = bibliothèque personnelle.
    public var library: String?
    public init(id: String, name: String, color: String, library: String? = nil) {
        self.id = id; self.name = name; self.color = color; self.library = library
    }
}

/// Note personnelle d'une aide (jamais exportée, synchronisée entre appareils du même compte).
public struct Note: Equatable, Sendable {
    public var t: String
    public var at: Double
    public var dirty: Bool
    public init(t: String, at: Double, dirty: Bool = false) { self.t = t; self.at = at; self.dirty = dirty }
}
