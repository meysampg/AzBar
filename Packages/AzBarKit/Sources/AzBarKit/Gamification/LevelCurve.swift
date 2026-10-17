import Foundation

public struct LevelInfo: Sendable, Hashable {
    public let totalXP: Int
    public let level: Int
    public let xpIntoLevel: Int
    public let xpForNextLevel: Int

    public init(totalXP: Int, level: Int, xpIntoLevel: Int, xpForNextLevel: Int) {
        self.totalXP = totalXP
        self.level = level
        self.xpIntoLevel = xpIntoLevel
        self.xpForNextLevel = xpForNextLevel
    }

    public var xpRemaining: Int { max(0, xpForNextLevel - xpIntoLevel) }

    public var fraction: Double {
        guard xpForNextLevel > 0 else { return 1 }
        return min(1, max(0, Double(xpIntoLevel) / Double(xpForNextLevel)))
    }
}

/// Cumulative threshold `T(L) = 10·(L−1)·(L+2)`: T(1)=0, T(2)=40, T(3)=100, T(4)=180.
public enum LevelCurve {
    public static let maxLevel = 99

    public static func threshold(level: Int) -> Int {
        let l = max(1, level)
        return 10 * (l - 1) * (l + 2)
    }

    public static func level(forXP xp: Int) -> Int {
        guard xp > 0 else { return 1 }
        var l = Int(((-1 + (9 + 0.4 * Double(xp)).squareRoot()) / 2).rounded(.down))
        l = min(max(l, 1), maxLevel)
        while l < maxLevel, threshold(level: l + 1) <= xp { l += 1 }
        while l > 1, threshold(level: l) > xp { l -= 1 }
        return l
    }

    public static func info(totalXP: Int) -> LevelInfo {
        let xp = max(0, totalXP)
        let l = level(forXP: xp)
        let base = threshold(level: l)
        return LevelInfo(totalXP: xp, level: l, xpIntoLevel: xp - base,
                         xpForNextLevel: threshold(level: l + 1) - base)
    }
}
