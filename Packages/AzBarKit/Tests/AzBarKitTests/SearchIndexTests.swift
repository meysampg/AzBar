import Foundation
import Testing
@testable import AzBarKit

@Suite struct SearchIndexTests {
    private func miniPoems() throws -> [Poem] {
        try Fixture.decode(ContentPack.self, "pack-mini.json").poems
    }

    @Test func queryWithoutDiacriticsFindsDiacriticMesra() async throws {
        let index = SearchIndex()
        await index.build(poems: try miniPoems())
        let hits = await index.search("الا یا ایها الساقی")
        let hit = try #require(hits.first)
        #expect(hit.poemId == 2130)
        #expect(hit.coupletIndex == 0)
        #expect(hit.matchedText.contains("اَیُّهَا"))
        #expect(hit.poetId == 2)
    }

    @Test func zwnjAndLetterVariantsAreInsensitive() async throws {
        let poem = Poem(id: 1, poetId: 2, categoryId: 3, title: "تست", fullTitle: "تست", urlSlug: "t", fullUrl: "/t",
                        couplets: [Couplet(index: 0, kind: .beyt, verses: [
                            Verse(id: 1, order: 1, position: 0, text: "گفتم که می\u{200C}خواهم ز عشق"),
                            Verse(id: 2, order: 2, position: 1, text: "كه يار")])])
        let index = SearchIndex()
        await index.build(poems: [poem])
        #expect(await index.search("میخواهم").count == 1)       // no ZWNJ in query
        #expect(await index.search("می\u{200C}خواهم").count == 1)
        #expect(await index.search("که یار").count == 1)       // Persian ye/kaf vs Arabic in text
        #expect(await index.search("نیست").isEmpty)
    }

    @Test func titleHitsHaveNoCoupletIndex() async throws {
        let index = SearchIndex()
        await index.build(poems: try miniPoems())
        let hits = await index.search("رباعی شماره ۱")
        let hit = try #require(hits.first)
        #expect(hit.coupletIndex == nil)
        #expect(hit.poemId == 2051)
    }

    @Test func shortQueriesAndLimit() async throws {
        let index = SearchIndex()
        await index.build(poems: try miniPoems())
        #expect(await index.search("ا").isEmpty)
        #expect(await index.search("  ").isEmpty)
        #expect(await index.search("را", limit: 3).count == 3)
    }

    @Test func buildIsIdempotent() async throws {
        let index = SearchIndex()
        let poems = try miniPoems()
        await index.build(poems: poems)
        let n = await index.entryCount
        await index.build(poems: poems)
        #expect(await index.entryCount == n)
        #expect(await index.isBuilt)
    }

    @Test func fullPackSearchIsFast() async throws {
        let url = Fixture.fullPackURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let source = BundledPoemSource(packURL: url)
        let poems = await source.allPoems()
        let index = SearchIndex()
        let start = Date()
        await index.build(poems: poems)
        let hits = await index.search("الا یا ایها الساقی", limit: 20)
        let elapsed = Date().timeIntervalSince(start)
        #expect(hits.first?.poemId == 2130)
        #expect(elapsed < 3.0, "index+search took \(elapsed)s")
        let t2 = Date()
        _ = await index.search("حافظ", limit: 100)
        #expect(Date().timeIntervalSince(t2) < 1.0)
    }
}
