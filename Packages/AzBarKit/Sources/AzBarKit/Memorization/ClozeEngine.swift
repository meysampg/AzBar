// STUB (WP2): replace implementation, keep signatures
import Foundation

public struct ClozeEngine: Sendable {
    public let tokens: [[MesraToken]]
    public let hidingOrder: [Int]
    public static let defaultLevels: [Double] = [0, 0.3, 0.6, 1.0]

    public init(poemId: Int, couplet: Couplet) {
        var all: [[MesraToken]] = []
        var nextId = 0
        for (i, verse) in couplet.verses.enumerated() {
            let t = PersianTokenizer.tokenize(verse.text, mesraIndex: i, startId: nextId)
            nextId += t.count
            all.append(t)
        }
        tokens = all
        // STUB: real implementation uses seeded weighted priorities.
        hidingOrder = all.flatMap { $0 }.filter(\.isWord).map(\.id)
    }

    public func hiddenIds(fraction: Double) -> Set<Int> {
        let n = hidingOrder.count
        let k: Int
        if fraction <= 0 { k = 0 } else if fraction >= 1 { k = n } else { k = max(1, Int((fraction * Double(n)).rounded(.up))) }
        return Set(hidingOrder.prefix(k))
    }

    public func hiddenIds(level: Int, levels: [Double] = ClozeEngine.defaultLevels) -> Set<Int> {
        guard !levels.isEmpty else { return [] }
        return hiddenIds(fraction: levels[min(max(level, 0), levels.count - 1)])
    }

    public static func firstLetterHint(_ t: MesraToken) -> String {
        guard let first = t.core.first else { return "" }
        let nonJoining: Set<Character> = ["ا", "آ", "أ", "إ", "د", "ذ", "ر", "ز", "ژ", "و", "ؤ"]
        if nonJoining.contains(first) { return String(first) + "…" }
        let remaining = t.core.count - 1
        return String(first) + String(repeating: "ـ", count: min(4, max(1, remaining)))
    }
}
