import XCTest
@testable import AidesCore

/// Fonctions pures du compte et de la synchro, comparées à la PWA (`oracle-cases/sync.mjs`).
final class SyncOracleTests: XCTestCase {
    func testMatchesWeb() throws {
        let cases = try Oracle.cases("sync")
        XCTAssertGreaterThan(cases.count, 80)
        for (i, c) in cases.enumerated() {
            let fn = c.input["fn"]!.string!, arg = c.input["arg"]!
            let a = arg.array ?? []
            var web = c.output
            var mine: JSON
            switch fn {
            case "restErrStatus": mine = restErrStatus(arg.string!).map { .number(Double($0)) } ?? .null
            case "isPersoRepairCandidate": mine = .bool(isPersoRepairCandidate(a[0].string!, isPerso: a[1].truthy))
            case "explainSyncError":
                let r = explainSyncError(message: arg.string!)
                mine = ["title": .string(r.title), "detail": .string(r.detail)]
            case "explainSyncErrorTypeError":
                let r = explainSyncError(message: arg.string!, isTypeError: true)
                mine = ["title": .string(r.title), "detail": .string(r.detail)]
            case "pullMissedIds":
                let by = a[1].object ?? [:]
                mine = .array(SyncRows.pullMissedIds(a[0].array!) { id in by[id].map { jsNumberOrZero($0["updatedAt"]) } }.map { .string($0) })
                // `byId['__proto__']` d'un objet ordinaire vaut Object.prototype côté oracle ; le moteur
                // utilise une table sans prototype — l'id est retenu dans les deux cas (absent/non supprimé).
            case "canReturnToAnon":
                mine = .bool(canReturnToAnon(status: a[0].string.flatMap(AccountStatus.init(rawValue:)), everSynced: a[1].truthy, liveCount: Int(a[2].number!)))
            case "dbNameFor": mine = .string(dbNameFor(space: a[0].string!, owner: a[1].string))
            case "spaceKeyFor": mine = .string(spaceKeyFor(base: a[0].string!, space: a[1].string!, owner: a[2].string))
            case "spaceTag": mine = .string(LocalStore.spaceTag(arg.string!))
            case "sanitizePins": mine = .array(sanitizePins(arg).map { .string($0) })
            case "sanitizeUsage": mine = usageJSON(sanitizeUsage(arg))
            case "mergeUsage": mine = usageJSON(mergeUsage(sanitizeUsage(a[0]), sanitizeUsage(a[1])))
            case "sanitizeTags": mine = .array(sanitizeTags(arg).map(\.json))
            case "catSlug": mine = .string(catSlug(arg.string!))
            case "attStoragePath": mine = .string(attStoragePath(library: a[0].string, ownerUid: a[1].string!, attId: a[2].string!))
            case "dateParse": mine = JSDate.parse(arg.string!).map { .number($0) } ?? .null
            case "toISOString": mine = .string(JSDate.iso(arg.number!))
            case "ficheToRow": mine = SyncRows.entityToRow(a[0], uid: a[1].string!, now: 0)
            case "ficheFromRow":
                mine = SyncRows.ficheFromRow(arg, now: 0).json
                dropOrderIfAbsent(&mine, &web, arg)
            case "protocolFromRow":
                mine = SyncRows.referenceFromRow(arg, now: 0).json
                dropOrderIfAbsent(&mine, &web, arg)
            case "sessionToRow": mine = SyncRows.sessionToRow(a[0], uid: a[1].string!, now: 0)
            case "sessionFromRow": mine = SyncRows.sessionFromRow(arg, now: 0)
            default: XCTFail("cas inconnu \(fn)"); continue
            }
            assertJSONEqual(normalizeGenerated(mine, input: c.input), normalizeGenerated(web, input: c.input), "cas \(i) \(fn)")
        }
    }

    /// `order` absent de la ligne → `Date.now()` des deux côtés, à des instants différents.
    private func dropOrderIfAbsent(_ mine: inout JSON, _ web: inout JSON, _ row: JSON) {
        guard row["data"]?["order"] == nil else { return }
        if case .object(var m) = mine { m["order"] = nil; mine = .object(m) }
        if case .object(var w) = web { w["order"] = nil; web = .object(w) }
    }

    func testTimeoutIsClassifiedAsUnreachable() {
        // ÉCART VOULU (spec D, Q7) : le web classe « NET timeout » en « Erreur inattendue ».
        XCTAssertEqual(explainSyncError(CloudError.timeout(ms: 25000)).title, "Serveur injoignable")
        XCTAssertEqual(explainSyncError(CloudError.network("x")).title, "Serveur injoignable")
        XCTAssertEqual(explainSyncError(CloudError.http(status: 401, body: "")).title, "Session expirée")
        XCTAssertEqual(explainSyncError(CloudError.localStore("disque plein")).title, "Stockage momentanément indisponible")
        XCTAssertEqual(CloudError.timeout(ms: 25000).message, "NET timeout 25000 ms")
        XCTAssertNil(restErrStatus(CloudError.timeout(ms: 25000).message))
    }

    func testEncodeURIComponent() {
        XCTAssertEqual(jsEncodeURIComponent("2026-09-30T08:56:13.046Z"), "2026-09-30T08%3A56%3A13.046Z")
        XCTAssertEqual(jsEncodeURIComponent("personal:a b+é"), "personal%3Aa%20b%2B%C3%A9")
        XCTAssertEqual(jsEncodeURIComponent("A-z_0.!~*'()"), "A-z_0.!~*'()")
    }

    func testAttachmentPathRegex() {
        XCTAssertTrue(isAttachmentPath("u/5b7c1f0e-8a1d-4c0e-9f00-0123456789ab/a1.pdf"))
        XCTAssertTrue(isAttachmentPath("l/L1/a_1-x.pdf"))
        XCTAssertFalse(isAttachmentPath("x/L1/a.pdf"))
        XCTAssertFalse(isAttachmentPath("l/L1/a.png"))
        XCTAssertFalse(isAttachmentPath("l/L 1/a.pdf"))
        XCTAssertFalse(isAttachmentPath("l/L1/sub/a.pdf"))
        XCTAssertFalse(isAttachmentPath("l//a.pdf"))
    }

    func testLibraryIdShape() {
        let id = AccountAPI.newLibraryId(name: "Équipe déchocage")
        XCTAssertTrue(id.hasPrefix("lib-equipe-dechocage-"))
        XCTAssertEqual(id.count, "lib-equipe-dechocage-".count + 4)
        XCTAssertTrue(AccountAPI.newLibraryId(name: "!!!").hasPrefix("lib-x-"))
        XCTAssertTrue(Guard.isSafeId(id))
    }
}
