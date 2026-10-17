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

    public init(id: CategoryID, title: String) {
        self.id = id
        self.title = title
    }
}
