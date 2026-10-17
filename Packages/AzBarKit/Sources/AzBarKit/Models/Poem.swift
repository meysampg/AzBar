import Foundation

public struct Poem: Identifiable, Codable, Sendable, Hashable {
    public var id: PoemID
    public var poetId: PoetID
    public var categoryId: CategoryID
    public var title: String
    public var fullTitle: String
    public var urlSlug: String
    public var fullUrl: String
    public var summary: String?
    public var couplets: [Couplet]
    public var recitations: [Recitation]

    public init(id: PoemID, poetId: PoetID, categoryId: CategoryID, title: String, fullTitle: String,
                urlSlug: String, fullUrl: String, summary: String? = nil,
                couplets: [Couplet], recitations: [Recitation] = []) {
        self.id = id
        self.poetId = poetId
        self.categoryId = categoryId
        self.title = title
        self.fullTitle = fullTitle
        self.urlSlug = urlSlug
        self.fullUrl = fullUrl
        self.summary = summary
        self.couplets = couplets
        self.recitations = recitations
    }

    private enum CodingKeys: String, CodingKey {
        case id, poetId, categoryId, title, fullTitle, urlSlug, fullUrl, summary, couplets, recitations
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        poetId = try c.decode(Int.self, forKey: .poetId)
        categoryId = try c.decode(Int.self, forKey: .categoryId)
        title = try c.decode(String.self, forKey: .title)
        fullTitle = try c.decodeIfPresent(String.self, forKey: .fullTitle) ?? title
        urlSlug = try c.decodeIfPresent(String.self, forKey: .urlSlug) ?? ""
        fullUrl = try c.decodeIfPresent(String.self, forKey: .fullUrl) ?? ""
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        couplets = try c.decodeIfPresent([Couplet].self, forKey: .couplets) ?? []
        recitations = try c.decodeIfPresent([Recitation].self, forKey: .recitations) ?? []
    }

    /// All verses of all couplets, sorted by `order` (matches the sync `VerseOrder` offsets).
    public var orderedVerses: [Verse] {
        couplets.flatMap(\.verses).sorted { $0.order < $1.order }
    }

    public var memorizableCouplets: [Couplet] { couplets.filter(\.isMemorizable) }

    public func couplet(at index: Int) -> Couplet? {
        couplets.first { $0.index == index }
    }

    /// The memorizable couplet immediately preceding `index` (by couplet index), if any.
    public func previousMemorizable(before index: Int) -> Couplet? {
        memorizableCouplets.last { $0.index < index }
    }

    /// Maps a 0-based offset into `orderedVerses` to the index of the couplet containing that verse.
    public func coupletIndex(forVerseOffset offset: Int) -> Int? {
        let verses = orderedVerses
        guard verses.indices.contains(offset) else { return nil }
        let verseId = verses[offset].id
        return couplets.first { c in c.verses.contains { $0.id == verseId } }?.index
    }

    public var plainText: String {
        couplets.map { $0.verses.map(\.text).joined(separator: "\n") }.joined(separator: "\n")
    }

    public var ganjoorURL: URL {
        URL(string: "https://ganjoor.net" + fullUrl) ?? URL(string: "https://ganjoor.net")!
    }
}
