import Foundation
import Testing
@testable import AzBar

struct BundledContentSmokeTests {
    /// The test bundle is hosted by the app, so the pack lives in `Bundle.main` (resources are flattened).
    private func packURL() throws -> URL {
        for b in [Bundle.main, Bundle(for: BundleToken.self)] {
            if let url = b.url(forResource: "pack-hafez", withExtension: "json") { return url }
        }
        throw ContentError.notFound
    }

    @Test func bundledHafezPackLoads() async throws {
        let source = BundledPoemSource(packURL: try packURL())
        let poems = await source.allPoems()
        #expect(poems.count == 692)
        let ghazal1 = try await source.poem(id: 2130)
        #expect(ghazal1.couplets.count == 7)
        #expect(ghazal1.recitations.first?.artist.isEmpty == false)
        let ghazals = try await source.category(id: 24)
        #expect(ghazals.poems.count == 495)
    }

    @Test func bundledPackIsSearchable() async throws {
        let source = BundledPoemSource(packURL: try packURL())
        let index = SearchIndex()
        await index.build(poems: await source.allPoems())
        let hits = await index.search("الا یا ایها الساقی", limit: 5)
        #expect(hits.first?.poemId == 2130)
    }
}

private final class BundleToken {}
