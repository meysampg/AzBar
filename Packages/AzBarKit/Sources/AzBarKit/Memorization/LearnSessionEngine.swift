import Foundation

public enum LearnStep: Hashable, Sendable {
    case read, cloze(level: Int), firstLetters, recallSecond, recallChain
    case fillBlank(mesraIndex: Int)
    case wordBank(mesraIndex: Int, distractors: Int)
}

public enum LearnSessionMode: String, Sendable, Hashable { case learn, practice, challenge }

public struct LearnSessionOptions: Sendable, Hashable {
    public var mode: LearnSessionMode
    public var includeExercises: Bool

    public init(mode: LearnSessionMode = .learn, includeExercises: Bool = false) {
        self.mode = mode
        self.includeExercises = includeExercises
    }

    public static let classic = LearnSessionOptions(mode: .learn, includeExercises: false)
    public static let interactive = LearnSessionOptions(mode: .learn, includeExercises: true)
    public static let practice = LearnSessionOptions(mode: .practice, includeExercises: true)
    public static let challenge = LearnSessionOptions(mode: .challenge, includeExercises: true)
}

public enum LearnExercise: Sendable, Hashable {
    case wordBank(WordBankExercise)
    case fillBlank(FillBlankExercise)
}

public struct LearnItem: Hashable, Sendable {
    public var coupletIndex: Int
    public var isRetry: Bool

    public init(coupletIndex: Int, isRetry: Bool) {
        self.coupletIndex = coupletIndex
        self.isRetry = isRetry
    }
}

public struct LearnRatingEvent: Sendable {
    public var coupletIndex: Int
    public var rating: Rating
    /// Wrong graded answers for this couplet during the session.
    public var mistakes: Int

    public init(coupletIndex: Int, rating: Rating, mistakes: Int = 0) {
        self.coupletIndex = coupletIndex
        self.rating = rating
        self.mistakes = mistakes
    }
}

public struct LearnSessionEngine: Sendable {
    private let poem: Poem
    public private(set) var queue: [LearnItem]
    public private(set) var itemPosition: Int = 0
    public private(set) var stepPosition: Int = 0
    public private(set) var isRevealed: Bool = false
    private var finished: Set<Int> = []
    private var peakProgress: Double = 0
    public let options: LearnSessionOptions
    public private(set) var gradedCount: Int = 0
    public private(set) var totalMistakes: Int = 0
    private var mistakeCounts: [Int: Int] = [:]
    private var peekCounts: [Int: Int] = [:]
    private var exerciseCache: [ExerciseKey: LearnExercise] = [:]

    private struct ExerciseKey: Hashable {
        let coupletIndex: Int
        let step: LearnStep
    }

    public init(poem: Poem, coupletIndices: [Int], options: LearnSessionOptions = .classic) {
        self.poem = poem
        self.options = options
        self.queue = []
        // Exercises are built once; steps whose exercise cannot be built are dropped from the lists.
        if options.mode != .learn || options.includeExercises {
            for index in coupletIndices {
                for item in [LearnItem(coupletIndex: index, isRetry: false), LearnItem(coupletIndex: index, isRetry: true)] {
                    for step in Self.rawSteps(poem: poem, item: item, options: options) where Self.isGraded(step) {
                        if let e = Self.buildExercise(poem: poem, step: step, coupletIndex: index) {
                            exerciseCache[ExerciseKey(coupletIndex: index, step: step)] = e
                        }
                    }
                }
            }
        }
        let items = coupletIndices.map { LearnItem(coupletIndex: $0, isRetry: false) }
        self.queue = items
        if options.mode != .learn {
            self.queue = items.filter { !steps(for: $0).isEmpty }
        }
    }

    private static func isGraded(_ step: LearnStep) -> Bool {
        switch step {
        case .fillBlank, .wordBank: true
        default: false
        }
    }

    private static func buildExercise(poem: Poem, step: LearnStep, coupletIndex: Int) -> LearnExercise? {
        switch step {
        case .fillBlank(let m):
            return FillBlankExercise.make(poem: poem, coupletIndex: coupletIndex, mesraIndex: m).map(LearnExercise.fillBlank)
        case .wordBank(let m, let d):
            return WordBankExercise.make(poem: poem, coupletIndex: coupletIndex, mesraIndex: m, distractorCount: d).map(LearnExercise.wordBank)
        default:
            return nil
        }
    }

    /// The step list before graded steps without an exercise are removed.
    private static func rawSteps(poem: Poem, item: LearnItem, options: LearnSessionOptions) -> [LearnStep] {
        let isSingle = poem.couplet(at: item.coupletIndex)?.kind == .single
        let hasChain = poem.previousMemorizable(before: item.coupletIndex) != nil
        switch options.mode {
        case .practice:
            return isSingle ? [.fillBlank(mesraIndex: 0), .wordBank(mesraIndex: 0, distractors: 2)]
                : [.fillBlank(mesraIndex: 1), .wordBank(mesraIndex: 0, distractors: 1), .wordBank(mesraIndex: 1, distractors: 2)]
        case .challenge:
            return isSingle ? [.wordBank(mesraIndex: 0, distractors: 2)]
                : [.wordBank(mesraIndex: 0, distractors: 2), .wordBank(mesraIndex: 1, distractors: 2)]
        case .learn:
            break
        }
        if !options.includeExercises {
            if item.isRetry { return isSingle ? [.cloze(level: 2), .cloze(level: 3)] : [.cloze(level: 2), .recallSecond] }
            var s: [LearnStep] = [.read, .cloze(level: 1), .cloze(level: 2), .cloze(level: 3)]
            if isSingle {
                // Without a chain the final step is cloze(3), treated as the recall step.
                if hasChain { s.append(contentsOf: [.firstLetters, .recallChain]) }
            } else {
                s.append(contentsOf: [.firstLetters, .recallSecond])
                if hasChain { s.append(.recallChain) }
            }
            return s
        }
        if item.isRetry {
            return isSingle ? [.cloze(level: 2), .wordBank(mesraIndex: 0, distractors: 1)]
                : [.cloze(level: 2), .wordBank(mesraIndex: 1, distractors: 1), .recallSecond]
        }
        if isSingle {
            var s: [LearnStep] = [.read, .cloze(level: 1), .cloze(level: 2), .fillBlank(mesraIndex: 0),
                                  .cloze(level: 3), .wordBank(mesraIndex: 0, distractors: 1)]
            if hasChain { s.append(contentsOf: [.firstLetters, .recallChain]) }
            return s
        }
        var s: [LearnStep] = [.read, .cloze(level: 1), .cloze(level: 2), .fillBlank(mesraIndex: 1), .cloze(level: 3),
                              .wordBank(mesraIndex: 0, distractors: 0), .firstLetters,
                              .wordBank(mesraIndex: 1, distractors: 1), .recallSecond]
        if hasChain { s.append(.recallChain) }
        return s
    }

    public var currentItem: LearnItem? { queue.indices.contains(itemPosition) ? queue[itemPosition] : nil }

    public func steps(for item: LearnItem) -> [LearnStep] {
        Self.rawSteps(poem: poem, item: item, options: options).filter { step in
            !Self.isGraded(step) || exerciseCache[ExerciseKey(coupletIndex: item.coupletIndex, step: step)] != nil
        }
    }

    public var currentStep: LearnStep? {
        guard let item = currentItem else { return nil }
        let s = steps(for: item)
        return s.indices.contains(stepPosition) ? s[stepPosition] : nil
    }

    public var isRecallStep: Bool {
        switch currentStep {
        case .recallSecond, .recallChain: return true
        case .fillBlank, .wordBank, nil: return false
        default: return isLastStep
        }
    }

    private var isLastStep: Bool {
        guard let item = currentItem else { return false }
        return stepPosition == steps(for: item).count - 1
    }

    public var awaitsRating: Bool { options.mode == .learn && isRevealed && isLastStep }

    /// True on a fill-blank or word-bank step, which is answered with `check(correct:)`.
    public var isGradedStep: Bool { currentStep.map(Self.isGraded) ?? false }

    public func exercise(for step: LearnStep, coupletIndex: Int) -> LearnExercise? {
        if let cached = exerciseCache[ExerciseKey(coupletIndex: coupletIndex, step: step)] { return cached }
        return Self.buildExercise(poem: poem, step: step, coupletIndex: coupletIndex)
    }

    public var currentExercise: LearnExercise? {
        guard let item = currentItem, let step = currentStep else { return nil }
        return exercise(for: step, coupletIndex: item.coupletIndex)
    }

    public func mistakes(for coupletIndex: Int) -> Int { mistakeCounts[coupletIndex] ?? 0 }

    public func suggestedRating(for coupletIndex: Int) -> Rating {
        LessonScoring.suggestedRating(mistakes: mistakes(for: coupletIndex), peeks: peekCounts[coupletIndex] ?? 0)
    }

    /// Records the answer to a graded step and reveals its feedback. Ignored elsewhere and when already checked.
    public mutating func check(correct: Bool) {
        guard isGradedStep, !isRevealed, let item = currentItem else { return }
        gradedCount += 1
        if !correct {
            totalMistakes += 1
            mistakeCounts[item.coupletIndex, default: 0] += 1
        }
        isRevealed = true
    }

    /// Counts a hint peek (tapping a hidden word) for the current couplet.
    public mutating func notePeek() {
        guard let item = currentItem else { return }
        peekCounts[item.coupletIndex, default: 0] += 1
    }
    public var isFinished: Bool { currentItem == nil }

    /// Completed steps / total steps (including retries). Never decreases.
    public var progress: Double { max(peakProgress, rawProgress) }

    private var rawProgress: Double {
        let total = queue.reduce(0) { $0 + steps(for: $1).count }
        guard total > 0 else { return 1 }
        if isFinished { return 1 }
        let done = queue.prefix(itemPosition).reduce(0) { $0 + steps(for: $1).count } + stepPosition
        return min(1, Double(done) / Double(total))
    }

    /// Number of couplets whose learning (including a possible retry) is complete.
    public var learnedCount: Int { finished.count }

    /// Moves to the next step. Valid when not on a recall step, or on a revealed non-final recall step.
    public mutating func advance() {
        guard let item = currentItem else { return }
        if isGradedStep {
            guard isRevealed else { return }
        } else {
            guard !isRecallStep || (isRevealed && !awaitsRating) else { return }
        }
        if isLastStep, options.mode != .learn, isRevealed {
            // Practice and challenge never rate: the item ends with its last checked step.
            finished.insert(item.coupletIndex)
            peakProgress = max(peakProgress, rawProgress)
            itemPosition += 1
            stepPosition = 0
            isRevealed = false
            peakProgress = max(peakProgress, rawProgress)
            return
        }
        if stepPosition < steps(for: item).count - 1 {
            stepPosition += 1
            isRevealed = false
            peakProgress = max(peakProgress, rawProgress)
        }
    }

    /// Reveals the answer of a recall step. Graded steps are revealed by `check(correct:)` instead.
    public mutating func reveal() {
        guard !isGradedStep else { return }
        isRevealed = true
    }

    @discardableResult
    public mutating func rate(_ r: Rating) -> LearnRatingEvent {
        guard let item = currentItem else { return LearnRatingEvent(coupletIndex: -1, rating: r) }
        if r == .again && !item.isRetry {
            queue.append(LearnItem(coupletIndex: item.coupletIndex, isRetry: true))
        } else {
            finished.insert(item.coupletIndex)
        }
        peakProgress = max(peakProgress, rawProgress)
        itemPosition += 1
        stepPosition = 0
        isRevealed = false
        peakProgress = max(peakProgress, rawProgress)
        return LearnRatingEvent(coupletIndex: item.coupletIndex, rating: r, mistakes: mistakes(for: item.coupletIndex))
    }
}
