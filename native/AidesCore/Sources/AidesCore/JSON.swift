import Foundation

/// Valeur JSON DYNAMIQUE — l'équivalent natif de « n'importe quoi » en JavaScript.
///
/// Toute donnée qui entre (import JSON/ZIP, pull cloud, stockage relu, lot de partage) est NON
/// FIABLE : elle peut porter n'importe quel type à n'importe quelle clé. On la lit donc d'abord
/// en `JSON`, jamais directement en structure typée : un `Decodable` strict rejetterait le
/// fichier ENTIER au premier champ inattendu, là où la PWA assainit champ par champ
/// (`migrate()`, `sanitizeCats()`). La conversion vers le modèle typé passe par `Sanitize`.
public enum JSON: Equatable, Hashable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSON])
    case object([String: JSON])

    // MARK: Accès tolérant (jamais d'exception : un mauvais type rend nil)

    public subscript(key: String) -> JSON? {
        if case .object(let o) = self { return o[key] }
        return nil
    }
    public subscript(index: Int) -> JSON? {
        if case .array(let a) = self, index >= 0, index < a.count { return a[index] }
        return nil
    }
    public var string: String? { if case .string(let s) = self { return s }; return nil }
    public var number: Double? { if case .number(let n) = self { return n }; return nil }
    public var bool: Bool? { if case .bool(let b) = self { return b }; return nil }
    public var array: [JSON]? { if case .array(let a) = self { return a }; return nil }
    public var object: [String: JSON]? { if case .object(let o) = self { return o }; return nil }
    public var isNull: Bool { if case .null = self { return true }; return false }

    /// Vérité « à la JavaScript » (`!!x`) : utile pour recopier fidèlement les tests de la PWA.
    public var truthy: Bool {
        switch self {
        case .null: return false
        case .bool(let b): return b
        case .number(let n): return n != 0 && !n.isNaN
        case .string(let s): return !s.isEmpty
        case .array, .object: return true
        }
    }

    /// Coercition en chaîne « à la JavaScript » (`String(x)`) — pour `sstr` qui accepte un nombre.
    public var jsString: String {
        switch self {
        case .null: return "null"
        case .bool(let b): return b ? "true" : "false"
        case .number(let n): return JSON.formatNumber(n)
        case .string(let s): return s
        case .array(let a): return a.map { $0.isNull ? "" : $0.jsString }.joined(separator: ",")
        case .object: return "[object Object]"
        }
    }

    static func formatNumber(_ n: Double) -> String {
        if n.isNaN { return "NaN" }
        if n.isInfinite { return n > 0 ? "Infinity" : "-Infinity" }
        if n == n.rounded(), abs(n) < 1e15 { return String(Int64(n)) }
        return String(n)
    }

    // MARK: Lecture / écriture

    /// Lecture par `JSONDecoder` (et non `JSONSerialization`) : le décodeur distingue sans
    /// ambiguïté `true` de `1` sur toutes les plateformes (voir `init(from:)`).
    public static func parse(_ data: Data) throws -> JSON {
        try JSONDecoder().decode(JSON.self, from: data)
    }
    public static func parse(_ text: String) throws -> JSON {
        try parse(Data(text.utf8))
    }

    public init(any: Any?) {
        switch any {
        case nil: self = .null
        case is NSNull: self = .null
        case let s as String: self = .string(s)
        case let n as NSNumber:
            // JSONSerialization rend les booléens en NSNumber : on les distingue par leur type
            // (piège classique : `n as? Bool` réussit aussi pour 0 et 1 sur les plateformes Apple).
            #if canImport(Darwin)
            if CFGetTypeID(n) == CFBooleanGetTypeID() { self = .bool(n.boolValue); return }
            #endif
            self = .number(n.doubleValue)
        case let a as [Any]: self = .array(a.map { JSON(any: $0) })
        case let o as [String: Any]:
            var r: [String: JSON] = [:]
            for (k, v) in o { r[k] = JSON(any: v) }
            self = .object(r)
        default: self = .null
        }
    }

    public var anyValue: Any {
        switch self {
        case .null: return NSNull()
        case .bool(let b): return b
        case .number(let n):
            if n == n.rounded(), abs(n) < 9e15 { return Int64(n) }
            return n
        case .string(let s): return s
        case .array(let a): return a.map { $0.anyValue }
        case .object(let o): return o.mapValues { $0.anyValue }
        }
    }

    public func data(pretty: Bool = false) -> Data {
        let e = JSONEncoder()
        e.outputFormatting = pretty ? [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes] : [.sortedKeys, .withoutEscapingSlashes]
        return (try? e.encode(self)) ?? Data("null".utf8)
    }
    public func text(pretty: Bool = false) -> String {
        String(decoding: data(pretty: pretty), as: UTF8.self)
    }
}

extension JSON: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral,
                ExpressibleByBooleanLiteral, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral,
                ExpressibleByNilLiteral {
    public init(stringLiteral v: String) { self = .string(v) }
    public init(integerLiteral v: Int) { self = .number(Double(v)) }
    public init(floatLiteral v: Double) { self = .number(v) }
    public init(booleanLiteral v: Bool) { self = .bool(v) }
    public init(arrayLiteral e: JSON...) { self = .array(e) }
    public init(dictionaryLiteral e: (String, JSON)...) {
        var o: [String: JSON] = [:]
        for (k, v) in e { o[k] = v }
        self = .object(o)
    }
    public init(nilLiteral: ()) { self = .null }
}

extension JSON: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Double.self) { self = .number(n) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([JSON].self) { self = .array(a) }
        else if let o = try? c.decode([String: JSON].self) { self = .object(o) }
        else { self = .null }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let b): try c.encode(b)
        case .number(let n):
            // Un entier s'écrit sans « .0 » (identique à JSON.stringify côté web).
            if n == n.rounded(), abs(n) < 9e15 { try c.encode(Int64(n)) } else { try c.encode(n) }
        case .string(let s): try c.encode(s)
        case .array(let a): try c.encode(a)
        case .object(let o): try c.encode(o)
        }
    }
}
