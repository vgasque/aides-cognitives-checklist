import XCTest
@testable import AidesCore

/// Remplace les identifiants GÉNÉRÉS (absents de l'entrée) par des jetons stables, dans l'ordre
/// d'un parcours à clés triées : deux sorties équivalentes deviennent égales, quel que soit l'aléa.
func normalizeGenerated(_ out: JSON, input: JSON) -> JSON {
    var known = Set<String>()
    func collect(_ j: JSON) {
        switch j {
        case .string(let s): known.insert(s)
        case .array(let a): a.forEach(collect)
        case .object(let o): o.keys.forEach { known.insert($0) }; o.values.forEach(collect)
        default: break
        }
    }
    collect(input)
    var map: [String: String] = [:]
    func isGen(_ s: String) -> Bool {
        guard !known.contains(s), s.count >= 14, s.count <= 24, Guard.isSafeId(s) else { return false }
        return s.dropFirst().allSatisfy { $0.isNumber || ($0.isLowercase && $0.isASCII) }
    }
    func walk(_ j: JSON) -> JSON {
        switch j {
        case .string(let s) where isGen(s):
            if map[s] == nil { map[s] = "<gen\(map.count)>" }
            return .string(map[s]!)
        case .array(let a): return .array(a.map(walk))
        case .object(let o):
            // Clés GÉNÉRÉES (ids régénérés utilisés comme clés) : renommées par l'ordre de leur
            // VALEUR normalisée, seule chose qui ne dépende pas de l'aléa.
            var r: [String: JSON] = [:]
            let gen = o.keys.filter(isGen)
            for k in o.keys.sorted() where !isGen(k) { r[k] = walk(o[k]!) }
            let vals = gen.map { (k: $0, v: walk(o[$0]!)) }.sorted { $0.v.text() < $1.v.text() }
            for (i, x) in vals.enumerated() { r["<genkey\(i)>"] = x.v }
            return .object(r)
        default: return j
        }
    }
    return walk(out)
}

func assertJSONEqual(_ a: JSON, _ b: JSON, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
    if a == b { return }
    // Localiser la première divergence pour un message utile.
    func diff(_ x: JSON, _ y: JSON, _ path: String) -> String? {
        switch (x, y) {
        case (.object(let o1), .object(let o2)):
            for k in Set(o1.keys).union(o2.keys).sorted() {
                guard let v1 = o1[k] else { return "\(path).\(k) absent côté natif (web: \(o2[k]!.text()))" }
                guard let v2 = o2[k] else { return "\(path).\(k) en trop côté natif (\(v1.text()))" }
                if let d = diff(v1, v2, "\(path).\(k)") { return d }
            }
            return nil
        case (.array(let a1), .array(let a2)):
            if a1.count != a2.count { return "\(path) longueur \(a1.count) ≠ web \(a2.count)" }
            for i in a1.indices { if let d = diff(a1[i], a2[i], "\(path)[\(i)]") { return d } }
            return nil
        default:
            return x == y ? nil : "\(path) : natif \(x.text()) ≠ web \(y.text())"
        }
    }
    XCTFail("\(label) : \(diff(a, b, "$") ?? "?")", file: file, line: line)
}

final class MigrateOracleTests: XCTestCase {
    func testMigrateMatchesWeb() throws {
        for (i, c) in try Oracle.cases("migrate").enumerated() {
            let mine = Sanitize.fiche(c.input).json
            assertJSONEqual(normalizeGenerated(mine, input: c.input), normalizeGenerated(c.output, input: c.input), "cas \(i)")
        }
    }
    func testSeedsAreStable() throws {
        let cs = try Oracle.cases("seeds")
        let c = cs[2]
        let input = c.output["input"]!, web = c.output["output"]!
        assertJSONEqual(Sanitize.fiche(input).json, web, "seed")
        // Idempotence : migrate(migrate(x)) == migrate(x)
        for s in cs.prefix(2) {
            let f = s.output["fiche"]!
            assertJSONEqual(Sanitize.fiche(Sanitize.fiche(f).json).json, Sanitize.fiche(f).json, "idempotence")
        }
    }
}
