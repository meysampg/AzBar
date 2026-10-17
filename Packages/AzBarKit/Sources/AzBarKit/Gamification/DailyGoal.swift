import Foundation

public enum DailyGoal {
    public static let options = [10, 20, 30, 50]
    public static let defaultGoal = 20

    /// Fraction in 0...1.
    public static func progress(xp: Int, goal: Int) -> Double {
        guard goal > 0 else { return 0 }
        return min(1, max(0, Double(xp) / Double(goal)))
    }

    public static func justMet(before: Int, after: Int, goal: Int) -> Bool {
        before < goal && after >= goal
    }
}
