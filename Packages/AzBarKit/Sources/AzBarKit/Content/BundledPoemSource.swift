import Foundation

public actor BundledPoemSource: PoemSource {
    private let packURL: URL
    private var pack: ContentPack?
    private var poemsById: [PoemID: Poem] = [:]
    private var categoriesById: [CategoryID: PoemCategory] = [:]

    public init(packURL: URL) {
        self.packURL = packURL
    }

    private func load() throws -> ContentPack {
        if let pack { return pack }
        do {
            let data = try Data(contentsOf: packURL)
            let decoded = try JSONDecoder().decode(ContentPack.self, from: data)
            pack = decoded
            poemsById = Dictionary(decoded.poems.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            categoriesById = Dictionary(decoded.categories.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            return decoded
        } catch {
            throw ContentError.decoding(String(describing: error))
        }
    }

    public func poet(id: PoetID) async throws -> Poet {
        let p = try load()
        guard p.poet.id == id else { throw ContentError.notFound }
        return p.poet
    }

    public func rootCategory() async throws -> PoemCategory {
        let p = try load()
        guard let c = categoriesById[p.poet.rootCategoryId] else { throw ContentError.notFound }
        return c
    }

    public func category(id: CategoryID) async throws -> PoemCategory {
        _ = try load()
        guard let c = categoriesById[id] else { throw ContentError.notFound }
        return c
    }

    public func poem(id: PoemID) async throws -> Poem {
        _ = try load()
        guard let p = poemsById[id] else { throw ContentError.notFound }
        return p
    }

    /// The category if the pack contains it; nil when absent. Throws only `ContentError.decoding`.
    public func categoryIfPresent(id: CategoryID) throws -> PoemCategory? {
        _ = try load()
        return categoriesById[id]
    }

    public func poemIfPresent(id: PoemID) throws -> Poem? {
        _ = try load()
        return poemsById[id]
    }

    /// False when the pack fails to load.
    public func containsCategory(_ id: CategoryID) -> Bool {
        ((try? categoryIfPresent(id: id)) ?? nil) != nil
    }

    public func containsPoem(_ id: PoemID) -> Bool {
        ((try? poemIfPresent(id: id)) ?? nil) != nil
    }

    /// Number of poems in the pack (0 when it cannot be loaded).
    public func poemCount() -> Int {
        (try? load())?.poems.count ?? 0
    }

    /// Loads the pack eagerly and rethrows decoding errors (the other accessors load lazily).
    public func contentPack() throws -> ContentPack {
        try load()
    }

    /// All poems of the pack (for search and artist listing). Empty when the pack cannot be loaded.
    public func allPoems() -> [Poem] {
        (try? load())?.poems ?? []
    }
}
