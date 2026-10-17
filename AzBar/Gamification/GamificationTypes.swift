import Foundation

/// What a finished lesson, practice node or challenge reports to `GamificationStore.completeLesson`.
struct LessonOutcome {
    let poemId: PoemID
    /// Path node id ("L2", "R3", "C", or "<id>-p" for re-practice); nil when there is no path node.
    let nodeId: String?
    let kind: LessonKind
    let gradedCount: Int
    let mistakes: Int
    let newCouplets: Int
    let passed: Bool
    let finishedAt: Date
}

enum Celebration: Hashable, Identifiable {
    case streak(days: Int)
    case dailyGoal(goal: Int)
    case levelUp(level: Int)
    case badge(BadgeID)

    var id: String {
        switch self {
        case .streak(let days): "streak-\(days)"
        case .dailyGoal(let goal): "goal-\(goal)"
        case .levelUp(let level): "level-\(level)"
        case .badge(let id): "badge-\(id.rawValue)"
        }
    }
}

struct SessionReward: Equatable {
    var xpEarned: Int
    /// 0...1; nil when nothing was graded.
    var accuracy: Double?
    var celebrations: [Celebration]
}
