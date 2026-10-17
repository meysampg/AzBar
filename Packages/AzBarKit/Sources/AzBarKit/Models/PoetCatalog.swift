import Foundation

public struct PoetCatalogEntry: Identifiable, Codable, Sendable, Hashable {
    public var id: PoetID
    public var slug: String
    public var name: String
    public var fullName: String
    public var rootCategoryId: CategoryID
    public var bundledPack: String?
    /// Categories bundled in the pack. nil/empty with a pack means the whole poet is bundled.
    public var bundledCategoryIds: [CategoryID]?
    public var falCategoryId: CategoryID?
    public var birthYearHijri: Int?
    public var deathYearHijri: Int?
    public var sortOrder: Int
    public var isEnabled: Bool

    public init(id: PoetID, slug: String, name: String, fullName: String, rootCategoryId: CategoryID,
                bundledPack: String? = nil, bundledCategoryIds: [CategoryID]? = nil, falCategoryId: CategoryID? = nil,
                birthYearHijri: Int? = nil, deathYearHijri: Int? = nil,
                sortOrder: Int = 0, isEnabled: Bool = true) {
        self.id = id
        self.slug = slug
        self.name = name
        self.fullName = fullName
        self.rootCategoryId = rootCategoryId
        self.bundledPack = bundledPack
        self.bundledCategoryIds = bundledCategoryIds
        self.falCategoryId = falCategoryId
        self.birthYearHijri = birthYearHijri
        self.deathYearHijri = deathYearHijri
        self.sortOrder = sortOrder
        self.isEnabled = isEnabled
    }

    public var isFullyBundled: Bool { bundledPack != nil && (bundledCategoryIds ?? []).isEmpty }
    public var isPartiallyBundled: Bool { bundledPack != nil && !(bundledCategoryIds ?? []).isEmpty }

    private enum CodingKeys: String, CodingKey {
        case id, slug, name, fullName, rootCategoryId, bundledPack, bundledCategoryIds, falCategoryId
        case birthYearHijri, deathYearHijri, sortOrder, isEnabled
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        slug = try c.decode(String.self, forKey: .slug)
        name = try c.decode(String.self, forKey: .name)
        fullName = try c.decodeIfPresent(String.self, forKey: .fullName) ?? name
        rootCategoryId = try c.decode(Int.self, forKey: .rootCategoryId)
        bundledPack = try c.decodeIfPresent(String.self, forKey: .bundledPack)
        bundledCategoryIds = try c.decodeIfPresent([Int].self, forKey: .bundledCategoryIds)
        falCategoryId = try c.decodeIfPresent(Int.self, forKey: .falCategoryId)
        birthYearHijri = try c.decodeIfPresent(Int.self, forKey: .birthYearHijri)
        deathYearHijri = try c.decodeIfPresent(Int.self, forKey: .deathYearHijri)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    }
}

public struct PoetCatalog: Codable, Sendable, Hashable {
    public var schemaVersion: Int
    public var poets: [PoetCatalogEntry]

    public init(schemaVersion: Int = 1, poets: [PoetCatalogEntry] = []) {
        self.schemaVersion = schemaVersion
        self.poets = poets
    }

    public static func load(from url: URL) throws -> PoetCatalog {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(PoetCatalog.self, from: data)
    }

    /// Enabled poets sorted by `sortOrder`.
    public var enabledPoets: [PoetCatalogEntry] {
        poets.filter(\.isEnabled).sorted { $0.sortOrder < $1.sortOrder }
    }

    public func entry(_ id: PoetID) -> PoetCatalogEntry? {
        poets.first { $0.id == id }
    }
}
