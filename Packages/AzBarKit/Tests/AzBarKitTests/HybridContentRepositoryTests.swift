import Foundation
import Testing
@testable import AzBarKit

final class HybridStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) -> (Int, Data)?)?
    nonisolated(unsafe) static var paths: [String] = []
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.paths.append(request.url?.path ?? "")
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

@Suite(.serialized) struct HybridContentRepositoryTests {
    private func remote() -> GanjoorRemoteSource {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [HybridStub.self]
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("azbar-hybrid-\(UUID().uuidString)")
        return GanjoorRemoteSource(session: URLSession(configuration: cfg), cacheDirectory: dir)
    }

    private func repo(pack: URL = Fixture.url("pack-hybrid.json")) -> ContentRepository {
        let catalog = PoetCatalog(poets: [
            PoetCatalogEntry(id: 900, slug: "azmoon", name: "آزمون", fullName: "شاعر آزمون", rootCategoryId: 500,
                             bundledPack: "pack-hybrid", bundledCategoryIds: [501], sortOrder: 0)])
        return ContentRepository(catalog: catalog, bundledPacks: [900: pack], remote: remote())
    }

    private func installStub() throws {
        let cat = try Fixture.data("ganjoor-cat-26.json")
        var obj = try #require(JSONSerialization.jsonObject(with: Fixture.data("ganjoor-poem-2130.json")) as? [String: Any])
        obj["category"] = ["poet": ["id": 900], "cat": ["id": 502]]
        let poemBody = try JSONSerialization.data(withJSONObject: obj)
        HybridStub.paths = []
        HybridStub.handler = { req in
            let p = req.url?.path ?? ""
            if p.contains("/cat/") { return (200, cat) }
            if p.contains("/poem/") { return (200, poemBody) }
            return nil
        }
    }

    @Test func bundledPartsServedWithoutRequests() async throws {
        try installStub()
        let r = repo()
        let cat = try await r.category(501, poetId: 900)
        #expect(cat.poems.count == 2)
        let poem = try await r.poem(9001, poetId: 900)
        #expect(poem.id == 9001)
        _ = try await r.rootCategory(poetId: 900)
        _ = try await r.poet(900)
        #expect(HybridStub.paths.isEmpty)
    }

    @Test func onlineOnlyPartsHitRemote() async throws {
        try installStub()
        let r = repo()
        let cat = try await r.category(502, poetId: 900)
        #expect(cat.id == 26)
        #expect(HybridStub.paths.count == 1)
        let poem = try await r.poem(9002, poetId: 900)   // summary in a bundled category, body not bundled
        #expect(poem.id == 2130)
        #expect(HybridStub.paths.count == 2)
    }

    @Test func rootMarksOnlineOnlyChildren() async throws {
        let root = try await repo().rootCategory(poetId: 900)
        #expect(root.children[0].isOnlineOnly == false)
        #expect(root.children[1].isOnlineOnly == true)
    }

    @Test func isBundled() async throws {
        let r = repo()
        #expect(await r.isBundled(categoryId: 501, poetId: 900))
        #expect(await r.isBundled(categoryId: 502, poetId: 900) == false)
        #expect(await r.isBundled(poemId: 9001, poetId: 900))
        #expect(await r.isBundled(poemId: 9002, poetId: 900) == false)
        #expect(await r.isBundled(categoryId: 501, poetId: 1) == false)
    }

    @Test func remoteFailureThrowsNetwork() async throws {
        HybridStub.paths = []
        HybridStub.handler = { _ in nil }
        let r = repo()
        await #expect(throws: ContentError.self) { try await r.category(502, poetId: 900) }
        do { _ = try await r.poem(9002, poetId: 900); Issue.record("expected throw") }
        catch let e as ContentError {
            guard case .network = e else { Issue.record("expected network, got \(e)"); return }
        }
    }

    @Test func missingPackFileFallsBackToRemote() async throws {
        try installStub()
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("nope-\(UUID()).json")
        let r = repo(pack: missing)
        let cat = try await r.category(501, poetId: 900)      // pack unreadable -> remote
        #expect(cat.id == 26)
        #expect(HybridStub.paths.count == 1)
        _ = try await r.rootCategory(poetId: 900)             // remote root of catalog entry
        #expect(await r.isBundled(categoryId: 501, poetId: 900) == false)
        #expect(await r.search("بنفشه").isEmpty)              // no crash, empty index
        #expect(await r.recitationArtists().isEmpty)
    }

    @Test func liveSkipsMissingPackFiles() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("azbar-bundle-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let catalog = """
        {"schemaVersion":1,"poets":[{"id":7,"slug":"saadi","name":"سعدی","rootCategoryId":118,
        "bundledPack":"pack-saadi-missing","bundledCategoryIds":[120],"sortOrder":1}]}
        """
        try catalog.write(to: dir.appendingPathComponent("poets-catalog.json"), atomically: true, encoding: .utf8)
        let bundle = try #require(Bundle(url: dir))
        let r = ContentRepository.live(bundle: bundle)
        #expect(r.catalog.poets.count == 1)
        #expect(r.catalog.poets[0].isPartiallyBundled)
        #expect(await r.isBundled(categoryId: 120, poetId: 7) == false)
        #expect(await r.search("سعدی").isEmpty)
    }
}

@Suite struct CatalogAndRefCodingTests {
    @Test func categoryRefOnlineOnlyCoding() throws {
        let old = try JSONDecoder().decode(CategoryRef.self, from: Data(#"{"id":1,"title":"a"}"#.utf8))
        #expect(old.isOnlineOnly == false)
        let on = CategoryRef(id: 2, title: "b", isOnlineOnly: true)
        let data = try JSONEncoder().encode(on)
        #expect(String(decoding: data, as: UTF8.self).contains("onlineOnly"))
        #expect(try JSONDecoder().decode(CategoryRef.self, from: data) == on)
        let off = try JSONEncoder().encode(CategoryRef(id: 3, title: "c"))
        #expect(!String(decoding: off, as: UTF8.self).contains("onlineOnly"))
    }

    @Test func catalogBundledCategoryIds() throws {
        let json = """
        {"schemaVersion":1,"poets":[
        {"id":1,"slug":"a","name":"a","rootCategoryId":1,"bundledPack":"pack-a"},
        {"id":2,"slug":"b","name":"b","rootCategoryId":2,"bundledPack":"pack-b","bundledCategoryIds":[5,6]},
        {"id":3,"slug":"c","name":"c","rootCategoryId":3,"bundledPack":null,"bundledCategoryIds":[]}]}
        """
        let c = try JSONDecoder().decode(PoetCatalog.self, from: Data(json.utf8))
        #expect(c.poets[0].isFullyBundled && !c.poets[0].isPartiallyBundled)
        #expect(c.poets[1].bundledCategoryIds == [5, 6])
        #expect(c.poets[1].isPartiallyBundled && !c.poets[1].isFullyBundled)
        #expect(!c.poets[2].isFullyBundled && !c.poets[2].isPartiallyBundled)
    }
}
