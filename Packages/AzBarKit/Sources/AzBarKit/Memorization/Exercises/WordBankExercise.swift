import Foundation

public struct WordTile: Identifiable, Sendable, Hashable {
    public let id: Int
    public let text: String
    public let normalized: String
    public let isDistractor: Bool

    public init(id: Int, text: String, normalized: String, isDistractor: Bool) {
        self.id = id
        self.text = text
        self.normalized = normalized
        self.isDistractor = isDistractor
    }
}

public struct WordBankExercise: Sendable, Hashable {
    public let coupletIndex: Int
    public let mesraIndex: Int
    /// The mesra's words in the correct order.
    public let answer: [WordTile]
    /// Answer tiles plus distractors, shuffled.
    public let bank: [WordTile]

    public init(coupletIndex: Int, mesraIndex: Int, answer: [WordTile], bank: [WordTile]) {
        self.coupletIndex = coupletIndex
        self.mesraIndex = mesraIndex
        self.answer = answer
        self.bank = bank
    }

    /// Returns `nil` when the mesra has fewer than 3 words.
    public static func make(poem: Poem, coupletIndex: Int, mesraIndex: Int, distractorCount: Int) -> WordBankExercise? {
        guard let couplet = poem.couplet(at: coupletIndex), couplet.verses.indices.contains(mesraIndex) else { return nil }
        let words = ExerciseTokens.words(couplet.verses[mesraIndex].text)
        guard words.count >= 3 else { return nil }
        var rng = SplitMix64(seed: FNV1a64.hash("wb:\(poem.id):\(coupletIndex):\(mesraIndex)"))

        let answer = words.enumerated().map {
            WordTile(id: $0.offset, text: $0.element.core, normalized: $0.element.normalized, isDistractor: false)
        }
        let answerSet = Set(answer.map(\.normalized))

        var candidates: [String: MesraToken] = [:]
        for other in poem.memorizableCouplets where other.index != coupletIndex {
            for verse in other.verses {
                for t in ExerciseTokens.words(verse.text)
                where !ExerciseTokens.isStopword(t) && !answerSet.contains(t.normalized) && candidates[t.normalized] == nil {
                    candidates[t.normalized] = t
                }
            }
        }
        var pool = candidates.keys.sorted().compactMap { candidates[$0] }
        ExerciseTokens.shuffle(&pool, rng: &rng)
        let distractors = pool.prefix(max(0, distractorCount)).enumerated().map {
            WordTile(id: answer.count + $0.offset, text: $0.element.core, normalized: $0.element.normalized, isDistractor: true)
        }

        var bank = answer + distractors
        ExerciseTokens.shuffle(&bank, rng: &rng)
        // Never hand out the answer already in order.
        let answerPositions = bank.indices.filter { !bank[$0].isDistractor }
        if answerPositions.map({ bank[$0].id }) == answer.map(\.id), answerPositions.count >= 2 {
            bank.swapAt(answerPositions[0], answerPositions[1])
        }
        return WordBankExercise(coupletIndex: coupletIndex, mesraIndex: mesraIndex, answer: answer, bank: bank)
    }

    /// Compares normalized sequences, so duplicate words are interchangeable.
    public func evaluate(_ chosen: [WordTile.ID]) -> ExerciseResult {
        let byId = Dictionary(uniqueKeysWithValues: bank.map { ($0.id, $0) })
        let chosenTiles = chosen.map { byId[$0] }
        var wrong: Set<Int> = []
        for (i, tile) in chosenTiles.enumerated() {
            if i >= answer.count || tile == nil || !AnswerMatcher.equivalent(tile!.normalized, answer[i].normalized) {
                wrong.insert(i)
            }
        }
        let correct = chosen.count == answer.count && wrong.isEmpty
        return ExerciseResult(isCorrect: correct, wrongPositions: wrong,
                              expected: answer.map(\.text).joined(separator: " "))
    }
}
