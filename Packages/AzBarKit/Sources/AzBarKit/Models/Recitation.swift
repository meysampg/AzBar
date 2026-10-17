import Foundation

public struct Recitation: Identifiable, Codable, Sendable, Hashable {
    public var id: Int
    public var artist: String
    public var mp3Url: URL
    public var syncUrl: URL?
    public var order: Int
    public var type: Int
    public var synced: Bool

    public init(id: Int, artist: String, mp3Url: URL, syncUrl: URL? = nil, order: Int, type: Int, synced: Bool) {
        self.id = id
        self.artist = artist
        self.mp3Url = mp3Url
        self.syncUrl = syncUrl
        self.order = order
        self.type = type
        self.synced = synced
    }

    private enum CodingKeys: String, CodingKey { case id, artist, mp3Url, syncUrl, order, type, synced }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        artist = try c.decode(String.self, forKey: .artist)
        mp3Url = try c.decode(URL.self, forKey: .mp3Url)
        syncUrl = try c.decodeIfPresent(URL.self, forKey: .syncUrl)
        order = try c.decodeIfPresent(Int.self, forKey: .order) ?? 0
        type = try c.decodeIfPresent(Int.self, forKey: .type) ?? 0
        synced = try c.decodeIfPresent(Bool.self, forKey: .synced) ?? false
    }
}

public struct SyncPoint: Codable, Sendable, Hashable {
    /// 0-based index into `Poem.orderedVerses`.
    public var verseOffset: Int
    public var milliseconds: Int

    public init(verseOffset: Int, milliseconds: Int) {
        self.verseOffset = verseOffset
        self.milliseconds = milliseconds
    }
}
