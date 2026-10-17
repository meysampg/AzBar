import Foundation
import Testing
@testable import AzBarKit

@Suite struct ContentPackDecodingTests {
    @Test func miniPackDecodes() throws {
        let pack = try Fixture.decode(ContentPack.self, "pack-mini.json")
        #expect(pack.schemaVersion == 1)
        #expect(pack.poet.id == 2)
        #expect(pack.poems.count == 4)
        #expect(pack.categories.map(\.id) == [9, 24, 26, 674])
        let first = try #require(pack.poems.first)
        #expect(first.id == 2130)
        #expect(first.couplets.count == 7)
        #expect(first.recitations.count == 2)
    }

    @Test func miniPackRoundTrips() throws {
        let pack = try Fixture.decode(ContentPack.self, "pack-mini.json")
        let data = try JSONEncoder().encode(pack)
        let again = try JSONDecoder().decode(ContentPack.self, from: data)
        #expect(again == pack)
    }

    @Test func miniPackContainsParagraphCouplet() throws {
        let pack = try Fixture.decode(ContentPack.self, "pack-mini.json")
        let poem = try #require(pack.poems.first { $0.id == 77000 })
        #expect(poem.couplets.contains { $0.kind == .paragraph })
        #expect(poem.memorizableCouplets.count == poem.couplets.count - 1)
    }

    @Test func missingOptionalKeysDecode() throws {
        let json = """
        {"schemaVersion":1,"generatedAt":"x","source":"s","poet":{"id":1,"name":"a","fullName":"b","slug":"c","rootCategoryId":5},
         "categories":[{"id":5,"poetId":1,"title":"t"}],
         "poems":[{"id":9,"poetId":1,"categoryId":5,"title":"p","couplets":[]}]}
        """
        let pack = try JSONDecoder().decode(ContentPack.self, from: Data(json.utf8))
        #expect(pack.categories[0].children.isEmpty)
        #expect(pack.poems[0].recitations.isEmpty)
        #expect(pack.poems[0].summary == nil)
    }

    @Test func fullPackDecodesQuickly() throws {
        let url = Fixture.fullPackURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let start = Date()
        let data = try Data(contentsOf: url)
        let pack = try JSONDecoder().decode(ContentPack.self, from: data)
        let elapsed = Date().timeIntervalSince(start)
        #expect(pack.poems.count == 692)
        #expect(pack.poems.reduce(0) { $0 + $1.couplets.count } == 5185)
        #expect(elapsed < 3.0, "decode took \(elapsed)s")
        // Category summaries are consistent with the poems.
        for cat in pack.categories {
            for s in cat.poems { #expect(s.categoryId == cat.id) }
        }
        #expect(pack.categories.first { $0.id == 24 }?.poems.count == 495)
    }
}
