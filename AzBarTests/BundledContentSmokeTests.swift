import Foundation
import Testing
@testable import AzBar

struct BundledContentSmokeTests {
    /// The test bundle is hosted by the app, so packs live in `Bundle.main` (resources are flattened).
    private func packURL(_ name: String) throws -> URL {
        for b in [Bundle.main, Bundle(for: BundleToken.self)] {
            if let url = b.url(forResource: name, withExtension: "json") { return url }
        }
        throw ContentError.notFound
    }

    private func source(_ name: String) throws -> BundledPoemSource {
        BundledPoemSource(packURL: try packURL(name))
    }

    /// Hafez is bundled whole; the other poets bundle selected categories only.
    @Test(arguments: [
        ("pack-hafez", 692), ("pack-khayyam", 178), ("pack-saeb", 1542), ("pack-saadi", nil as Int?)
    ])
    func packLoadsAndHasPoems(name: String, expectedPoems: Int?) async throws {
        let poems = await (try source(name)).allPoems()
        if let expectedPoems { #expect(poems.count == expectedPoems) } else { #expect(!poems.isEmpty) }
        #expect(poems.allSatisfy { !$0.couplets.isEmpty })
    }

    @Test func bundledHafezPackLoads() async throws {
        let source = try source("pack-hafez")
        let ghazal1 = try await source.poem(id: 2130)
        #expect(ghazal1.couplets.count == 7)
        #expect(ghazal1.recitations.first?.artist.isEmpty == false)
        let ghazals = try await source.category(id: 24)
        #expect(ghazals.poems.count == 495)
    }

    @Test func bundledPackIsSearchable() async throws {
        let source = try source("pack-hafez")
        let index = SearchIndex()
        await index.build(poems: await source.allPoems())
        let hits = await index.search("الا یا ایها الساقی", limit: 5)
        #expect(hits.first?.poemId == 2130)
    }

    @Test func khayyamRubaiyat() async throws {
        let source = try source("pack-khayyam")
        let cat = try await source.category(id: 31)
        #expect(cat.poems.count == 178)
        let poems = await source.allPoems()
        #expect(poems.count == 178)
        #expect(poems.allSatisfy { $0.memorizableCouplets.count == 2 })
        let root = try await source.rootCategory()
        #expect(root.children.first { $0.id == 31 }?.isOnlineOnly == false)
        #expect(root.children.contains { $0.isOnlineOnly })
    }

    @Test func saebSingleBeyts() async throws {
        let source = try source("pack-saeb")
        let cat = try await source.category(id: 282)
        #expect(cat.poems.count == 1542)
        let poems = await source.allPoems()
        #expect(poems.count == 1542)
        #expect(poems.allSatisfy { $0.memorizableCouplets.count == 1 })
        let parent = try await source.category(id: 280)
        #expect(parent.children.first { $0.id == 282 }?.isOnlineOnly == false)
        let others = parent.children.filter { $0.id != 282 }
        #expect(!others.isEmpty && others.allSatisfy(\.isOnlineOnly))
    }

    @Test func saadiGhazalsBustanGolestan() async throws {
        let source = try source("pack-saadi")
        let ghazals = try await source.category(id: 120)
        #expect(ghazals.poems.count == 637)
        #expect(try await source.category(id: 123).children.count == 11)
        #expect(try await source.category(id: 1665).children.count == 8)
        let root = try await source.rootCategory()
        #expect(root.children.contains { $0.isOnlineOnly })
        let poems = await source.allPoems()
        #expect(poems.contains { poem in
            poem.couplets.contains { $0.kind == .paragraph } && poem.memorizableCouplets.count < poem.couplets.count
        })
    }

    @Test func liveRepositorySearchesAcrossPacks() async throws {
        let repo = ContentRepository.live(bundle: .main)
        let saadi = await repo.search("بنی آدم اعضای یکدیگرند")
        #expect(saadi.contains { $0.poetId == 7 })
        let khayyam = await repo.search("این قافله عمر عجب می‌گذرد")
        #expect(khayyam.contains { $0.poetId == 3 })
    }
}

private final class BundleToken {}
