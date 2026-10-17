import Foundation

public enum BadgeID: String, Codable, Sendable, CaseIterable {
    case firstLesson, perfectLesson, firstGhazal, tenGhazals, firstChallenge
    case streak3, streak7, streak30, reviews100, reviews500, mature50, level10
    case nightOwl, earlyBird, falSeeker
}

public enum BadgeMetric: Sendable, Hashable {
    case lessons, perfectLessons, poemsCompleted, challenges, longestStreak, reviews
    case matureCouplets, level, nightSessions, earlySessions, falOpened
}

public struct BadgeDefinition: Sendable, Hashable, Identifiable {
    public let id: BadgeID
    public let metric: BadgeMetric
    public let target: Int

    public init(id: BadgeID, metric: BadgeMetric, target: Int) {
        self.id = id
        self.metric = metric
        self.target = target
    }
}

public struct GamificationSnapshot: Sendable, Hashable {
    public var lessonsCompleted: Int, perfectLessons: Int, poemsCompleted: Int, challengesPassed: Int
    public var longestStreak: Int, reviewsTotal: Int, matureCouplets: Int, level: Int
    public var nightSessions: Int, earlySessions: Int, falOpened: Int

    public init(lessonsCompleted: Int = 0, perfectLessons: Int = 0, poemsCompleted: Int = 0,
                challengesPassed: Int = 0, longestStreak: Int = 0, reviewsTotal: Int = 0,
                matureCouplets: Int = 0, level: Int = 0, nightSessions: Int = 0,
                earlySessions: Int = 0, falOpened: Int = 0) {
        self.lessonsCompleted = lessonsCompleted
        self.perfectLessons = perfectLessons
        self.poemsCompleted = poemsCompleted
        self.challengesPassed = challengesPassed
        self.longestStreak = longestStreak
        self.reviewsTotal = reviewsTotal
        self.matureCouplets = matureCouplets
        self.level = level
        self.nightSessions = nightSessions
        self.earlySessions = earlySessions
        self.falOpened = falOpened
    }

    public func value(_ m: BadgeMetric) -> Int {
        switch m {
        case .lessons: lessonsCompleted
        case .perfectLessons: perfectLessons
        case .poemsCompleted: poemsCompleted
        case .challenges: challengesPassed
        case .longestStreak: longestStreak
        case .reviews: reviewsTotal
        case .matureCouplets: matureCouplets
        case .level: level
        case .nightSessions: nightSessions
        case .earlySessions: earlySessions
        case .falOpened: falOpened
        }
    }
}

public struct BadgeProgress: Sendable, Hashable {
    /// Clamped to `target`.
    public let current: Int
    public let target: Int

    public init(current: Int, target: Int) {
        self.current = max(0, min(current, target))
        self.target = target
    }

    public var fraction: Double { target > 0 ? Double(current) / Double(target) : 1 }
    public var isComplete: Bool { current >= target }
}

public enum SessionTime: Sendable {
    case night, early

    /// Hours 22-23 and 0-3 are night; 4-6 are early.
    public static func classify(hour: Int) -> SessionTime? {
        switch hour {
        case 22...23, 0...3: .night
        case 4...6: .early
        default: nil
        }
    }
}

public enum BadgeCatalog {
    /// Table order of the plan (§3f).
    public static let all: [BadgeDefinition] = [
        BadgeDefinition(id: .firstLesson, metric: .lessons, target: 1),
        BadgeDefinition(id: .perfectLesson, metric: .perfectLessons, target: 1),
        BadgeDefinition(id: .firstGhazal, metric: .poemsCompleted, target: 1),
        BadgeDefinition(id: .tenGhazals, metric: .poemsCompleted, target: 10),
        BadgeDefinition(id: .firstChallenge, metric: .challenges, target: 1),
        BadgeDefinition(id: .streak3, metric: .longestStreak, target: 3),
        BadgeDefinition(id: .streak7, metric: .longestStreak, target: 7),
        BadgeDefinition(id: .streak30, metric: .longestStreak, target: 30),
        BadgeDefinition(id: .reviews100, metric: .reviews, target: 100),
        BadgeDefinition(id: .reviews500, metric: .reviews, target: 500),
        BadgeDefinition(id: .mature50, metric: .matureCouplets, target: 50),
        BadgeDefinition(id: .level10, metric: .level, target: 10),
        BadgeDefinition(id: .nightOwl, metric: .nightSessions, target: 1),
        BadgeDefinition(id: .earlyBird, metric: .earlySessions, target: 1),
        BadgeDefinition(id: .falSeeker, metric: .falOpened, target: 5),
    ]

    public static func definition(_ id: BadgeID) -> BadgeDefinition {
        all.first { $0.id == id }!
    }

    public static func progress(_ id: BadgeID, snapshot: GamificationSnapshot) -> BadgeProgress {
        let d = definition(id)
        return BadgeProgress(current: snapshot.value(d.metric), target: d.target)
    }

    public static func newlyUnlocked(snapshot: GamificationSnapshot, alreadyUnlocked: Set<BadgeID>) -> [BadgeID] {
        all.filter { !alreadyUnlocked.contains($0.id) && progress($0.id, snapshot: snapshot).isComplete }.map(\.id)
    }
}
