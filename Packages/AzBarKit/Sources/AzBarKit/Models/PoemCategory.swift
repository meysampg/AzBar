import Foundation

public struct PoemSummary: Identifiable, Codable, Sendable, Hashable {
    public var id: PoemID
    public var categoryId: CategoryID
    public var title: String
    public var urlSlug: String
    public var excerpt: String?
    public var coupletCount: Int?

    public init(id: PoemID, categoryId: CategoryID, title: String, urlSlug: String,
                excerpt: String? = nil, coupletCount: Int? = nil) {
        self.id = id
        self.categoryId = categoryId
        self.title = title
        self.urlSlug = urlSlug
        self.excerpt = excerpt
        self.coupletCount = coupletCount
    }
}

public struct PoemCategory: Identifiable, Codable, Sendable, Hashable {
    public var id: CategoryID
    public var poetId: PoetID
    public var title: String
    public var slug: String
    public var parentId: CategoryID?
    public var children: [CategoryRef]
    public var poems: [PoemSummary]

    public init(id: CategoryID, poetId: PoetID, title: String, slug: String, parentId: CategoryID? = nil,
                children: [CategoryRef] = [], poems: [PoemSummary] = []) {
        self.id = id
        self.poetId = poetId
        self.title = title
        self.slug = slug
        self.parentId = parentId
        self.children = children
        self.poems = poems
    }

    private enum CodingKeys: String, CodingKey {
        case id, poetId, title, slug, parentId, children, poems
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        poetId = try c.decode(Int.self, forKey: .poetId)
        title = try c.decode(String.self, forKey: .title)
        slug = try c.decodeIfPresent(String.self, forKey: .slug) ?? ""
        parentId = try c.decodeIfPresent(Int.self, forKey: .parentId)
        children = try c.decodeIfPresent([CategoryRef].self, forKey: .children) ?? []
        poems = try c.decodeIfPresent([PoemSummary].self, forKey: .poems) ?? []
    }
}
