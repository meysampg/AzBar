import Foundation

/// URL builders for the Ganjoor REST API.
public struct GanjoorEndpoints: Sendable {
    public let baseURL: URL

    public init(baseURL: URL = URL(string: "https://api.ganjoor.net")!) {
        self.baseURL = baseURL
    }

    public static let poemQuery = "verseDetails=true&recitations=true&catInfo=true&rhymes=false&next=false&prev=false&images=false&songs=false&comments=false&navigation=false&relatedpoems=false"

    private func url(_ path: String) -> URL {
        URL(string: baseURL.absoluteString.trimmingSuffix("/") + path) ?? baseURL
    }

    public func poet(id: PoetID) -> URL { url("/api/ganjoor/poet/\(id)") }
    public func category(id: CategoryID) -> URL { url("/api/ganjoor/cat/\(id)?poems=true") }
    public func poem(id: PoemID) -> URL { url("/api/ganjoor/poem/\(id)?\(Self.poemQuery)") }
    public func syncXML(recitationId: Int) -> URL { url("/api/audio/xml/\(recitationId)") }
}

private extension String {
    func trimmingSuffix(_ s: String) -> String {
        hasSuffix(s) ? String(dropLast(s.count)) : self
    }
}
