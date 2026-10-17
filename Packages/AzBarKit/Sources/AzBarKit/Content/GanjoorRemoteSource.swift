// STUB (WP1): replace implementation, keep signatures
import Foundation

public actor GanjoorRemoteSource: PoemSource {
    private let session: URLSession
    private let cacheDirectory: URL
    private let baseURL: URL

    public init(session: URLSession = .shared, cacheDirectory: URL,
                baseURL: URL = URL(string: "https://api.ganjoor.net")!) {
        self.session = session
        self.cacheDirectory = cacheDirectory
        self.baseURL = baseURL
    }

    public func poet(id: PoetID) async throws -> Poet { throw ContentError.notFound }
    public func rootCategory() async throws -> PoemCategory { throw ContentError.notFound }
    public func category(id: CategoryID) async throws -> PoemCategory { throw ContentError.notFound }
    public func poem(id: PoemID) async throws -> Poem { throw ContentError.notFound }
}
