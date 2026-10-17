// STUB (WP0): replace implementation, keep signatures
import Foundation

public struct SearchHit: Sendable, Hashable, Identifiable {
    public let id: String
    public let poemId: Int
    public let poetId: Int
    public let poemTitle: String
    public let coupletIndex: Int?
    public let matchedText: String

    public init(id: String, poemId: Int, poetId: Int, poemTitle: String, coupletIndex: Int?, matchedText: String) {
        self.id = id
        self.poemId = poemId
        self.poetId = poetId
        self.poemTitle = poemTitle
        self.coupletIndex = coupletIndex
        self.matchedText = matchedText
    }
}

public extension ContentRepository {
    typealias SearchHit = AzBarKit.SearchHit
}

public final class ContentRepository: Sendable {
    public let catalog: PoetCatalog
    private let bundled: [PoetID: BundledPoemSource]
    private let remote: GanjoorRemoteSource

    public init(catalog: PoetCatalog, bundledPacks: [PoetID: URL], remote: GanjoorRemoteSource) {
        self.catalog = catalog
        self.bundled = bundledPacks.mapValues { BundledPoemSource(packURL: $0) }
        self.remote = remote
    }

    public static let empty = ContentRepository(
        catalog: PoetCatalog(),
        bundledPacks: [:],
        remote: GanjoorRemoteSource(cacheDirectory: FileManager.default.temporaryDirectory.appendingPathComponent("Ganjoor"))
    )

    public static func live(bundle: Bundle) -> ContentRepository {
        let catalog: PoetCatalog
        if let url = bundle.url(forResource: "poets-catalog", withExtension: "json"),
           let loaded = try? PoetCatalog.load(from: url) {
            catalog = loaded
        } else {
            catalog = PoetCatalog()
        }
        var packs: [PoetID: URL] = [:]
        for entry in catalog.poets {
            if let name = entry.bundledPack, let url = bundle.url(forResource: name, withExtension: "json") {
                packs[entry.id] = url
            }
        }
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let remote = GanjoorRemoteSource(cacheDirectory: caches.appendingPathComponent("Ganjoor", isDirectory: true))
        return ContentRepository(catalog: catalog, bundledPacks: packs, remote: remote)
    }

    public func poet(_ id: PoetID) async throws -> Poet {
        if let b = bundled[id] { return try await b.poet(id: id) }
        return try await remote.poet(id: id)
    }

    public func rootCategory(poetId: PoetID) async throws -> PoemCategory {
        if let b = bundled[poetId] { return try await b.rootCategory() }
        guard let entry = catalog.entry(poetId) else { throw ContentError.notFound }
        return try await remote.category(id: entry.rootCategoryId)
    }

    public func category(_ id: CategoryID, poetId: PoetID) async throws -> PoemCategory {
        if let b = bundled[poetId] { return try await b.category(id: id) }
        return try await remote.category(id: id)
    }

    public func poem(_ id: PoemID, poetId: PoetID) async throws -> Poem {
        if let b = bundled[poetId] { return try await b.poem(id: id) }
        return try await remote.poem(id: id)
    }

    public func randomFalPoem(poetId: PoetID) async throws -> Poem {
        guard let catId = catalog.entry(poetId)?.falCategoryId else { throw ContentError.notFound }
        let cat = try await category(catId, poetId: poetId)
        guard let pick = cat.poems.randomElement() else { throw ContentError.notFound }
        return try await poem(pick.id, poetId: poetId)
    }

    /// Bundled poets only in v1; query normalized; minimum 2 characters.
    public func search(_ query: String, limit: Int = 100) async -> [SearchHit] {
        let q = PersianText.normalizeForSearch(query)
        guard q.count >= 2 else { return [] }
        var hits: [SearchHit] = []
        for (poetId, source) in bundled.sorted(by: { $0.key < $1.key }) {
            for poem in await source.allPoems() {
                for couplet in poem.couplets {
                    for verse in couplet.verses where PersianText.normalizeForSearch(verse.text).contains(q) {
                        hits.append(SearchHit(id: "\(poem.id):\(couplet.index):\(verse.id)", poemId: poem.id, poetId: poetId,
                                              poemTitle: poem.title, coupletIndex: couplet.index, matchedText: verse.text))
                        if hits.count >= limit { return hits }
                    }
                }
            }
        }
        return hits
    }

    /// Distinct recitation artists sorted by frequency descending (bundled poets).
    public func recitationArtists(poetId: PoetID) async -> [String] {
        guard let source = bundled[poetId] else { return [] }
        var counts: [String: Int] = [:]
        for poem in await source.allPoems() {
            for r in poem.recitations { counts[r.artist, default: 0] += 1 }
        }
        return counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.map(\.key)
    }
}
