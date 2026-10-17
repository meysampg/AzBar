import Foundation

public struct FillBlankExercise: Sendable, Hashable {
    public let coupletIndex: Int
    public let mesraIndex: Int
    /// All tokens of the mesra (ids as in `ClozeEngine`).
    public let tokens: [MesraToken]
    public let blankTokenId: Int
    public let options: [String]
    public let correctOptionIndex: Int

    public init(coupletIndex: Int, mesraIndex: Int, tokens: [MesraToken], blankTokenId: Int,
                options: [String], correctOptionIndex: Int) {
        self.coupletIndex = coupletIndex
        self.mesraIndex = mesraIndex
        self.tokens = tokens
        self.blankTokenId = blankTokenId
        self.options = options
        self.correctOptionIndex = correctOptionIndex
    }

    /// Returns `nil` when the mesra has no non-stopword word or fewer than 2 distractors exist.
    public static func make(poem: Poem, coupletIndex: Int, mesraIndex: Int, optionCount: Int = 4) -> FillBlankExercise? {
        guard let couplet = poem.couplet(at: coupletIndex), couplet.verses.indices.contains(mesraIndex) else { return nil }
        let engine = ClozeEngine(poemId: poem.id, couplet: couplet)
        guard engine.tokens.indices.contains(mesraIndex) else { return nil }
        let mesraTokens = engine.tokens[mesraIndex]
        let byId = Dictionary(uniqueKeysWithValues: mesraTokens.map { ($0.id, $0) })
        guard let target = engine.hidingOrder.compactMap({ byId[$0] }).first(where: { !ExerciseTokens.isStopword($0) }) else { return nil }

        var rng = SplitMix64(seed: FNV1a64.hash("fb:\(poem.id):\(coupletIndex):\(mesraIndex)"))
        var candidates: [String: MesraToken] = [:]
        for other in poem.memorizableCouplets {
            for verse in other.verses {
                for t in ExerciseTokens.words(verse.text)
                where !ExerciseTokens.isStopword(t) && t.normalized != target.normalized && candidates[t.normalized] == nil {
                    candidates[t.normalized] = t
                }
            }
        }
        let sorted = candidates.keys.sorted().compactMap { candidates[$0] }
        guard sorted.count >= 2 else { return nil }
        let ranked = sorted.map { t -> (token: MesraToken, diff: Int, jitter: UInt64) in
            (t, abs(t.normalized.count - target.normalized.count), rng.next())
        }.sorted { $0.diff != $1.diff ? $0.diff < $1.diff : $0.jitter < $1.jitter }

        let picked = ranked.prefix(max(1, optionCount - 1)).map(\.token)
        var options = ([target] + picked).map(\.core)
        ExerciseTokens.shuffle(&options, rng: &rng)
        guard let correct = options.firstIndex(of: target.core) else { return nil }
        return FillBlankExercise(coupletIndex: coupletIndex, mesraIndex: mesraIndex, tokens: mesraTokens,
                                 blankTokenId: target.id, options: options, correctOptionIndex: correct)
    }

    public func evaluate(optionIndex: Int) -> ExerciseResult {
        let isCorrect = optionIndex == correctOptionIndex
        return ExerciseResult(isCorrect: isCorrect, wrongPositions: isCorrect ? [] : [0],
                              expected: options.indices.contains(correctOptionIndex) ? options[correctOptionIndex] : "")
    }
}
