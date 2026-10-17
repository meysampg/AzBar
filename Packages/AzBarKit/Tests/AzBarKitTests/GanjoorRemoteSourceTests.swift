import Foundation
import Testing
@testable import AzBarKit

/// URLProtocol stub serving fixtures (or failing) without touching the network.
final class StubProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) -> (Int, Data)?)?
    nonisolated(unsafe) static var requestCount = 0
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requestCount += 1
        if let (code, data) = Self.handler?(request) {
            let resp = HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
        }
    }
    override func stopLoading() {}
}

@Suite(.serialized) struct GanjoorRemoteSourceTests {
    private func makeSource(_ dir: URL) -> GanjoorRemoteSource {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [StubProtocol.self]
        return GanjoorRemoteSource(session: URLSession(configuration: cfg), cacheDirectory: dir)
    }

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("azbar-remote-\(UUID().uuidString)")
    }

    @Test func fetchesMapsAndCachesPoem() async throws {
        // catInfo=true response = the cached fixture plus a category block.
        var obj = try #require(JSONSerialization.jsonObject(with: Fixture.data("ganjoor-poem-2130.json")) as? [String: Any])
        obj["category"] = ["poet": ["id": 2], "cat": ["id": 24]]
        let body = try JSONSerialization.data(withJSONObject: obj)
        StubProtocol.requestCount = 0
        StubProtocol.handler = { _ in (200, body) }
        let dir = tempDir()
        let source = makeSource(dir)
        let poem = try await source.poem(id: 2130)
        #expect(poem.poetId == 2)
        #expect(poem.categoryId == 24)
        #expect(poem.couplets.count == 7)
        _ = try await source.poem(id: 2130)       // poems never expire: served from disk
        #expect(StubProtocol.requestCount == 1)
        #expect(FileManager.default.fileExists(atPath: dir.appendingPathComponent("poem-2130.json").path))
    }

    @Test func staleCategoryFallsBackWhenOffline() async throws {
        let dir = tempDir()
        let cat = PoemCategory(id: 26, poetId: 2, title: "رباعیات", slug: "robaee2")
        let cache = DiskCache(directory: dir)
        cache.write(cat, kind: "cat", id: 26)
        // age the file by 30 days
        let old = Date().addingTimeInterval(-30 * 24 * 3600)
        try FileManager.default.setAttributes([.modificationDate: old], ofItemAtPath: cache.fileURL(kind: "cat", id: 26).path)
        #expect(cache.read(PoemCategory.self, kind: "cat", id: 26, maxAge: GanjoorRemoteSource.categoryMaxAge)?.isFresh == false)

        StubProtocol.handler = { _ in nil }   // network failure
        let source = makeSource(dir)
        let got = try await source.category(id: 26)
        #expect(got == cat)
    }

    @Test func refreshesExpiredCategoryWhenOnline() async throws {
        let dir = tempDir()
        let cache = DiskCache(directory: dir)
        cache.write(PoemCategory(id: 26, poetId: 2, title: "قدیمی", slug: "x"), kind: "cat", id: 26)
        let old = Date().addingTimeInterval(-30 * 24 * 3600)
        try FileManager.default.setAttributes([.modificationDate: old], ofItemAtPath: cache.fileURL(kind: "cat", id: 26).path)
        let body = try Fixture.data("ganjoor-cat-26.json")
        StubProtocol.handler = { _ in (200, body) }
        let got = try await makeSource(dir).category(id: 26)
        #expect(got.title == "رباعیات")
        #expect(got.poems.count == 42)
    }

    @Test func offlineWithoutCacheThrowsNetworkAndNotFoundOn404() async throws {
        StubProtocol.handler = { _ in nil }
        let source = makeSource(tempDir())
        await #expect(throws: ContentError.self) { try await source.poem(id: 5) }
        StubProtocol.handler = { _ in (404, Data()) }
        await #expect(throws: ContentError.notFound) { try await source.poem(id: 5) }
    }

    @Test func syncLoaderUsesSession() async throws {
        let body = try Fixture.data("sync-2840.json")
        StubProtocol.handler = { _ in (200, body) }
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [StubProtocol.self]
        let points = try await RecitationSyncLoader().load(URL(string: "https://api.ganjoor.net/api/audio/xml/2840")!,
                                                           session: URLSession(configuration: cfg))
        #expect(points.count == 14)
    }
}
