import Foundation

public struct ContentPack: Codable, Sendable, Hashable {
    public var schemaVersion: Int
    public var generatedAt: String
    public var source: String
    public var poet: Poet
    public var categories: [PoemCategory]
    public var poems: [Poem]

    public init(schemaVersion: Int = 1, generatedAt: String, source: String, poet: Poet,
                categories: [PoemCategory], poems: [Poem]) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.source = source
        self.poet = poet
        self.categories = categories
        self.poems = poems
    }
}
