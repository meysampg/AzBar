import Foundation

public struct CoupletKey: Hashable, Codable, Sendable {
    public var poemId: Int
    public var coupletIndex: Int

    public init(poemId: Int, coupletIndex: Int) {
        self.poemId = poemId
        self.coupletIndex = coupletIndex
    }

    /// `"2130:0"`
    public var stringValue: String { "\(poemId):\(coupletIndex)" }

    public init?(string: String) {
        let parts = string.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, let p = Int(parts[0]), let c = Int(parts[1]) else { return nil }
        self.init(poemId: p, coupletIndex: c)
    }
}
