import Foundation
import Testing
@testable import AzBarKit

@Suite struct BundledPoemSourceTests {
    let source = BundledPoemSource(packURL: Fixture.url("pack-mini.json"))

    @Test func looksUpPoetCategoriesAndPoems() async throws {
        let poet = try await source.poet(id: 2)
        #expect(poet.fullName == "حافظ شیرازی")
        let root = try await source.rootCategory()
        #expect(root.id == 9)
        #expect(root.children.map(\.id) == [24, 26, 674])
        let ghazal = try await source.category(id: 24)
        #expect(ghazal.poems.map(\.id) == [2130, 2131])
        #expect(ghazal.poems[0].coupletCount == 7)
        let poem = try await source.poem(id: 2051)
        #expect(poem.categoryId == 26)
        #expect(await source.allPoems().count == 4)
        #expect(await source.poemCount() == 4)
    }

    @Test func missingItemsThrowNotFound() async {
        await #expect(throws: ContentError.notFound) { try await source.poem(id: 1) }
        await #expect(throws: ContentError.notFound) { try await source.category(id: 1) }
        await #expect(throws: ContentError.notFound) { try await source.poet(id: 7) }
    }

    @Test func badPackThrowsDecoding() async {
        let bad = BundledPoemSource(packURL: Fixture.url("sync-2840.json"))
        await #expect(throws: ContentError.self) { try await bad.poem(id: 1) }
        let missing = BundledPoemSource(packURL: URL(fileURLWithPath: "/nonexistent/pack.json"))
        #expect(await missing.allPoems().isEmpty)
    }

    @Test func repositoryServesBundledPack() async throws {
        let catalog = PoetCatalog(schemaVersion: 1, poets: [
            PoetCatalogEntry(id: 2, slug: "hafez", name: "حافظ", fullName: "حافظ شیرازی", rootCategoryId: 9,
                             bundledPack: "pack-mini", falCategoryId: 24, birthYearHijri: 726, deathYearHijri: 792,
                             sortOrder: 0, isEnabled: true)])
        let remote = GanjoorRemoteSource(cacheDirectory: FileManager.default.temporaryDirectory.appendingPathComponent("azbar-test-\(UUID().uuidString)"))
        let repo = ContentRepository(catalog: catalog, bundledPacks: [2: Fixture.url("pack-mini.json")], remote: remote)
        let root = try await repo.rootCategory(poetId: 2)
        #expect(root.id == 9)
        let cat = try await repo.category(24, poetId: 2)
        #expect(cat.poems.count == 2)
        let cat2 = try await repo.category(24, poetId: 2)
        #expect(cat2 == cat)
        let fal = try await repo.randomFalPoem(poetId: 2)
        #expect([2130, 2131].contains(fal.id))
        let poem = try await repo.poem(2130, poetId: 2)
        #expect(poem.couplets.count == 7)
        let artists = await repo.recitationArtists(poetId: 2)
        #expect(!artists.isEmpty)
        let hits = await repo.search("ساقی")
        #expect(!hits.isEmpty)
        #expect(await repo.search("ا").isEmpty)
        await #expect(throws: ContentError.notFound) { try await repo.randomFalPoem(poetId: 99) }
    }
}
