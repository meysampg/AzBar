import Foundation

public enum LessonScoring {
    /// mistakes >= 2 -> again; mistakes == 1 or peeks >= 3 -> hard; otherwise good.
    public static func suggestedRating(mistakes: Int, peeks: Int) -> Rating {
        if mistakes >= 2 { return .again }
        if mistakes == 1 || peeks >= 3 { return .hard }
        return .good
    }

    /// 0...1; 1 when nothing was graded.
    public static func accuracy(graded: Int, mistakes: Int) -> Double {
        guard graded > 0 else { return 1 }
        return min(1, max(0, 1 - Double(mistakes) / Double(graded)))
    }

    public static func challengePassed(graded: Int, mistakes: Int) -> Bool {
        mistakes <= max(1, graded / 5)
    }
}
