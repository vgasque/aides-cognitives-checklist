import XCTest
@testable import AidesCore

final class LibraryTests: XCTestCase {
    var tmp: URL!
    override func setUp() { tmp = FileManager.default.temporaryDirectory.appendingPathComponent("ac-test-\(UUID().uuidString)") }
    override func tearDown() { try? FileManager.default.removeItem(at: tmp) }

    func seedFiche() throws -> JSON { try Oracle.cases("seeds")[0].output["fiche"]! }

    func testLoadSeedsDefaultCategoriesAndPersistsDirty() throws {
        let store = LocalStore(base: tmp)
        let lib = Library(space: store.open(""))
        lib.load()
        XCTAssertEqual(lib.categories.map(\.id).first, "c-anesthesie")
        XCTAssertEqual(lib.categories.count, 8)
        let f = Sanitize.fiche(try seedFiche())
        XCTAssertTrue(lib.persist(f))
        XCTAssertTrue(lib.isDirty(ficheId: f.id))
        // Relecture : tout repasse par migrate, le drapeau reste dans l'enregistrement.
        let lib2 = Library(space: store.open(""))
        lib2.load()
        XCTAssertEqual(lib2.fiches.first?.title, f.title)
        XCTAssertEqual(lib2.fiches.first?.blocks.count, f.blocks.count)
    }

    func testAnonymousDeleteIsHardAccountDeleteIsTombstone() throws {
        let store = LocalStore(base: tmp)
        let anon = Library(space: store.open("")); anon.load()
        let f = Sanitize.fiche(try seedFiche()); anon.persist(f)
        anon.delete(f)
        XCTAssertNil(anon.space.fiches.get(f.id), "espace anonyme hors connexion : suppression définitive")
        let acc = Library(space: store.open("user-1")); acc.load()
        acc.persist(f); acc.delete(acc.fiches[0])
        XCTAssertNotNil(acc.space.fiches.get(f.id)?["deletedAt"]?.number, "espace d'un compte : une TOMBE, pour propager")
        XCTAssertTrue(acc.fiches.isEmpty)
        XCTAssertEqual(acc.heldEdits, [f.id], "modifié hors connexion dans l'espace d'un compte : retenu")
    }

    func testExportImportRoundTripWithZip() throws {
        let store = LocalStore(base: tmp)
        let src = Library(space: store.open("")); src.load()
        var f = Sanitize.fiche(try seedFiche())
        let pdf = Data("%PDF-1.4\nbonjour".utf8)
        let att = try src.addAttachment(data: pdf, name: "protocole")
        XCTAssertEqual(att.name, "protocole.pdf")
        f.docs = [att]; f.category = "c-urgences"
        src.persist(f)
        let env = Exporter.envelope(fiches: src.fiches, references: [], categories: nil, all: src.categories, space: "")
        XCTAssertEqual(env["version"], 3)
        XCTAssertNil(env["fiches"]?[0]?["library"], "champs locaux retirés")
        let out = Exporter.build(envelope: env, withDocuments: true, attachmentIds: Exporter.attachmentIds(fiches: src.fiches, references: []), store: src.space)
        XCTAssertTrue(out.isZip); XCTAssertEqual(out.missing, 0)
        // Import dans un AUTRE espace : ids régénérés, binaire restauré depuis le zip.
        let dst = Library(space: store.open("user-2")); dst.load()
        let file = try Importer.read(out.data, currentSpace: "user-2")
        XCTAssertFalse(file.sameSpace)
        let rows = Importer.rows(file, library: dst, defaultLibrary: nil)
        XCTAssertEqual(rows.count, 1)
        let res = Importer.apply(file, rows: rows, library: dst, merge: true, replaceDuplicates: false)
        XCTAssertEqual(res.message, "1 fiche importée dans votre bibliothèque perso.")
        let g = dst.fiches[0]
        XCTAssertNotEqual(g.id, f.id)
        XCTAssertEqual(g.category, "c-urgences", "catégorie retrouvée par son nom")
        XCTAssertEqual(dst.space.attachmentData(att.id), pdf)
    }

    func testImportRejectsNonExportAndAcceptsAIFences() throws {
        XCTAssertThrowsError(try Importer.read(Data(#"{"a":1}"#.utf8), currentSpace: ""))
        XCTAssertThrowsError(try Importer.read(Data("pas du json".utf8), currentSpace: ""))
        let ai = "```json\n{\"aids\":[{\"title\":\"X\",\"blocks\":[{\"kind\":\"do\",\"items\":[\"⚠ A :: b\"]}]},{\"kind\":\"reference\",\"title\":\"R\",\"body\":\"# T\"}]}\n```"
        let file = try Importer.read(Data(ai.utf8), currentSpace: "")
        XCTAssertEqual(file.imp["fiches"]?.array?.count, 1)
        XCTAssertEqual(file.imp["protocols"]?.array?.count, 1)
        let f = Sanitize.fiche(file.imp["fiches"]?[0])
        XCTAssertEqual(f.items.first?.level, 3)
        XCTAssertEqual(f.items.first?.expect, "b")
    }
}
