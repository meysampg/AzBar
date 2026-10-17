import Foundation

public enum AnswerMatcher {
    /// Equal after search normalization: diacritics, ZWNJ, tatweel and Arabic letter variants are ignored.
    public static func equivalent(_ a: String, _ b: String) -> Bool {
        PersianText.normalizeForSearch(a) == PersianText.normalizeForSearch(b)
    }

    public static func sequenceEquivalent(_ a: [String], _ b: [String]) -> Bool {
        a.count == b.count && zip(a, b).allSatisfy { equivalent($0, $1) }
    }
}

public struct ExerciseResult: Sendable, Hashable {
    public let isCorrect: Bool
    /// Indices into the chosen sequence that do not match.
    public let wrongPositions: Set<Int>
    /// The correct answer as display text.
    public let expected: String

    public init(isCorrect: Bool, wrongPositions: Set<Int>, expected: String) {
        self.isCorrect = isCorrect
        self.wrongPositions = wrongPositions
        self.expected = expected
    }
}

/// Word tokens of a verse (punctuation peeled, `isWord` only), shared by the exercise builders.
enum ExerciseTokens {
    static func words(_ text: String) -> [MesraToken] {
        PersianTokenizer.tokenize(text, mesraIndex: 0, startId: 0).filter(\.isWord)
    }

    static func isStopword(_ t: MesraToken) -> Bool { PersianStopwords.set.contains(t.normalized) }

    /// In-place Fisher-Yates driven by the seeded generator.
    static func shuffle<T>(_ items: inout [T], rng: inout SplitMix64) {
        guard items.count > 1 else { return }
        for i in stride(from: items.count - 1, to: 0, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            items.swapAt(i, j)
        }
    }
}
