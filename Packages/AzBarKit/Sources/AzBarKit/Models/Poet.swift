import Foundation

public typealias PoetID = Int
public typealias CategoryID = Int
public typealias PoemID = Int

public struct Poet: Identifiable, Codable, Sendable, Hashable {
    public var id: PoetID
    public var name: String
    public var fullName: String
    public var slug: String
    public var rootCategoryId: CategoryID
    public var description: String?
    public var birthYearHijri: Int?
    public var deathYearHijri: Int?

    public init(id: PoetID, name: String, fullName: String, slug: String, rootCategoryId: CategoryID,
                description: String? = nil, birthYearHijri: Int? = nil, deathYearHijri: Int? = nil) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.slug = slug
        self.rootCategoryId = rootCategoryId
        self.description = description
        self.birthYearHijri = birthYearHijri
        self.deathYearHijri = deathYearHijri
    }
}

public struct CategoryRef: Identifiable, Codable, Sendable, Hashable {
    public var id: CategoryID
    public var title: String
    /// True when this child exists only on the network (not in the bundled pack).
    public var isOnlineOnly: Bool

    public init(id: CategoryID, title: String, isOnlineOnly: Bool = false) {
        self.id = id
        self.title = title
        self.isOnlineOnly = isOnlineOnly
    }

    private enum CodingKeys: String, CodingKey {
        case id, title
        case isOnlineOnly = "onlineOnly"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        isOnlineOnly = try c.decodeIfPresent(Bool.self, forKey: .isOnlineOnly) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        if isOnlineOnly { try c.encode(true, forKey: .isOnlineOnly) }
    }
}
