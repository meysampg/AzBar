import Foundation

public enum CoupletKind: String, Codable, Sendable, Hashable {
    case beyt, single, paragraph
}

public struct Verse: Identifiable, Codable, Sendable, Hashable {
    /// Ganjoor verse id.
    public var id: Int
    /// Ganjoor `vOrder` (1-based).
    public var order: Int
    public var position: Int
    public var text: String

    public init(id: Int, order: Int, position: Int, text: String) {
        self.id = id
        self.order = order
        self.position = position
        self.text = text
    }
}

public struct Couplet: Identifiable, Codable, Sendable, Hashable {
    public var index: Int
    public var kind: CoupletKind
    public var verses: [Verse]
    public var summary: String?

    public init(index: Int, kind: CoupletKind, verses: [Verse], summary: String? = nil) {
        self.index = index
        self.kind = kind
        self.verses = verses
        self.summary = summary
    }

    public var id: Int { index }
    public var firstMesra: String { verses.first?.text ?? "" }
    public var secondMesra: String? { verses.count > 1 ? verses[1].text : nil }
    public var isMemorizable: Bool { kind != .paragraph && index >= 0 }

    private enum CodingKeys: String, CodingKey { case index, kind, verses, summary }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        index = try c.decode(Int.self, forKey: .index)
        kind = try c.decode(CoupletKind.self, forKey: .kind)
        verses = try c.decode([Verse].self, forKey: .verses)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
    }
}
