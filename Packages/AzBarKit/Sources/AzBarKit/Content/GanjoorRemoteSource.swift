import Foundation

/// Fetches poets, categories and poems from api.ganjoor.net, caching domain-encoded JSON on disk.
/// Poet and category entries expire after 7 days; poems never expire. On a network failure a stale
/// cache entry is returned when one exists.
public actor GanjoorRemoteSource: PoemSource {
    public static let categoryMaxAge: TimeInterval = 7 * 24 * 3600

    private let session: URLSession
    private let cache: DiskCache
    private let endpoints: GanjoorEndpoints
    private let decoder = JSONDecoder()

    public init(session: URLSession = .shared, cacheDirectory: URL,
                baseURL: URL = URL(string: "https://api.ganjoor.net")!) {
        self.session = session
        self.cache = DiskCache(directory: cacheDirectory)
        self.endpoints = GanjoorEndpoints(baseURL: baseURL)
    }

    public func poet(id: PoetID) async throws -> Poet {
        try await cachedOrFetch(kind: "poet", id: id, maxAge: Self.categoryMaxAge) {
            let dto: GanjoorCatWithPoetDTO = try await self.fetch(self.endpoints.poet(id: id))
            guard let p = dto.poet else { throw ContentError.notFound }
            return GanjoorMapper.poet(from: p)
        }
    }

    /// A remote source is not bound to a poet; use `category(id:)` with the poet's root category id.
    public func rootCategory() async throws -> PoemCategory { throw ContentError.notFound }

    public func category(id: CategoryID) async throws -> PoemCategory {
        try await cachedOrFetch(kind: "cat", id: id, maxAge: Self.categoryMaxAge) {
            let dto: GanjoorCatWithPoetDTO = try await self.fetch(self.endpoints.category(id: id))
            guard let cat = dto.cat else { throw ContentError.notFound }
            return GanjoorMapper.category(from: cat, poetId: dto.poet?.id ?? 0)
        }
    }

    public func poem(id: PoemID) async throws -> Poem {
        try await cachedOrFetch(kind: "poem", id: id, maxAge: nil) {
            let dto: GanjoorPoemDTO = try await self.fetch(self.endpoints.poem(id: id))
            guard let poem = GanjoorMapper.poem(from: dto) else {
                throw ContentError.decoding("poem \(id): missing category info")
            }
            return poem
        }
    }

    // MARK: - Internals

    private func cachedOrFetch<T: Codable & Sendable>(kind: String, id: Int, maxAge: TimeInterval?,
                                                      fetch: () async throws -> T) async throws -> T {
        let hit = cache.read(T.self, kind: kind, id: id, maxAge: maxAge)
        if let hit, hit.isFresh { return hit.value }
        do {
            let value = try await fetch()
            cache.write(value, kind: kind, id: id)
            return value
        } catch let error as ContentError {
            if case .notFound = error { throw error }
            if let hit { return hit.value }
            throw error
        } catch {
            if let hit { return hit.value }
            throw ContentError.network(error.localizedDescription)
        }
    }

    private func fetch<D: Decodable>(_ url: URL) async throws -> D {
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue("AzBar/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ContentError.network(error.localizedDescription)
        }
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 404 { throw ContentError.notFound }
            guard (200..<300).contains(http.statusCode) else {
                throw ContentError.network("HTTP \(http.statusCode)")
            }
        }
        do {
            return try decoder.decode(D.self, from: data)
        } catch {
            throw ContentError.decoding(String(describing: error))
        }
    }
}
