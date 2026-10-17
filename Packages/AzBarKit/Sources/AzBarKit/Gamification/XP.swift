import Foundation

public enum XPSource: String, Codable, Sendable, CaseIterable {
    case exerciseCorrect, coupletLearned, lessonCompleted, perfectBonus, reviewRated
    case reviewSessionCompleted, practiceCompleted, challengePassed, perfectChallengeBonus, legacy
}

public struct XPAward: Sendable, Hashable {
    public let source: XPSource
    public let amount: Int

    public init(_ source: XPSource, _ amount: Int) {
        self.source = source
        self.amount = amount
    }
}

public enum LessonKind: String, Codable, Sendable {
    case lesson, practice, challenge
}

public enum XPTable {
    public static let exerciseCorrect = 2, coupletLearned = 3, lessonCompleted = 10, perfectBonus = 5
    public static let reviewSessionCompleted = 5, reviewSessionMinimumCards = 5, practiceCompleted = 8
    public static let challengePassed = 25, perfectChallengeBonus = 10

    public static func reviewRated(_ r: Rating) -> Int {
        switch r {
        case .again: 1
        case .hard: 2
        case .good, .easy: 3
        }
    }

    /// Awards for finishing a lesson, practice node or challenge. Per-exercise and per-couplet XP
    /// (`exerciseCorrect`, `coupletLearned`) are awarded separately while the session runs.
    /// `passed` only matters for challenges; lessons and practice always complete.
    public static func completionAwards(kind: LessonKind, gradedCount: Int, mistakes: Int, passed: Bool) -> [XPAward] {
        let perfect = gradedCount >= 2 && mistakes == 0
        switch kind {
        case .lesson:
            var a = [XPAward(.lessonCompleted, lessonCompleted)]
            if perfect { a.append(XPAward(.perfectBonus, perfectBonus)) }
            return a
        case .practice:
            var a = [XPAward(.practiceCompleted, practiceCompleted)]
            if perfect { a.append(XPAward(.perfectBonus, perfectBonus)) }
            return a
        case .challenge:
            guard passed else { return [] }
            var a = [XPAward(.challengePassed, challengePassed)]
            if perfect { a.append(XPAward(.perfectChallengeBonus, perfectChallengeBonus)) }
            return a
        }
    }

    public static func reviewSessionAwards(cardsReviewed: Int) -> [XPAward] {
        cardsReviewed >= reviewSessionMinimumCards ? [XPAward(.reviewSessionCompleted, reviewSessionCompleted)] : []
    }

    /// `reviewLogs` counts only entries that are not learning entries.
    public static func legacyXP(learnedCards: Int, reviewLogs: Int) -> Int {
        8 * max(0, learnedCards) + 3 * max(0, reviewLogs)
    }
}
