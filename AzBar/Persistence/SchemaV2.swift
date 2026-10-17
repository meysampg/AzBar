import Foundation
import SwiftData

enum AzBarSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [CoupletCard.self, MemorizationPlan.self, ReviewLogEntry.self, FavoritePoem.self, DailyActivity.self,
         DailyXP.self, LessonRecord.self, AchievementRecord.self, FrozenDay.self, GamificationState.self,
         PoemPathState.self]
    }
}

extension AzBarSchemaV2 {

    @Model final class CoupletCard {
        #Index<CoupletCard>([\.due], [\.poemId])
        @Attribute(.unique) var key: String
        var poemId: Int
        var poetId: Int
        var coupletIndex: Int
        var stateRaw: Int
        var stability: Double
        var difficulty: Double
        var due: Date
        var lastReview: Date?
        var reps: Int
        var lapses: Int
        var createdAt: Date

        init(key: String, poemId: Int, poetId: Int, coupletIndex: Int, stateRaw: Int = 0,
             stability: Double = 0, difficulty: Double = 0, due: Date = .now, lastReview: Date? = nil,
             reps: Int = 0, lapses: Int = 0, createdAt: Date = .now) {
            self.key = key
            self.poemId = poemId
            self.poetId = poetId
            self.coupletIndex = coupletIndex
            self.stateRaw = stateRaw
            self.stability = stability
            self.difficulty = difficulty
            self.due = due
            self.lastReview = lastReview
            self.reps = reps
            self.lapses = lapses
            self.createdAt = createdAt
        }
    }

    @Model final class MemorizationPlan {
        @Attribute(.unique) var poemId: Int
        var poetId: Int
        var title: String
        var poetName: String
        var memorizableCount: Int
        /// Index of the next couplet to learn; -1 if done.
        var nextCoupletIndex: Int
        var addedAt: Date
        var lastStudiedAt: Date?
        var isArchived: Bool

        init(poemId: Int, poetId: Int, title: String, poetName: String, memorizableCount: Int,
             nextCoupletIndex: Int, addedAt: Date = .now, lastStudiedAt: Date? = nil, isArchived: Bool = false) {
            self.poemId = poemId
            self.poetId = poetId
            self.title = title
            self.poetName = poetName
            self.memorizableCount = memorizableCount
            self.nextCoupletIndex = nextCoupletIndex
            self.addedAt = addedAt
            self.lastStudiedAt = lastStudiedAt
            self.isArchived = isArchived
        }
    }

    @Model final class ReviewLogEntry {
        var cardKey: String
        var ratingRaw: Int
        var reviewedAt: Date
        var elapsedDays: Double
        var scheduledDays: Double
        var stateBeforeRaw: Int
        var isLearning: Bool

        init(cardKey: String, ratingRaw: Int, reviewedAt: Date, elapsedDays: Double,
             scheduledDays: Double, stateBeforeRaw: Int, isLearning: Bool) {
            self.cardKey = cardKey
            self.ratingRaw = ratingRaw
            self.reviewedAt = reviewedAt
            self.elapsedDays = elapsedDays
            self.scheduledDays = scheduledDays
            self.stateBeforeRaw = stateBeforeRaw
            self.isLearning = isLearning
        }
    }

    @Model final class FavoritePoem {
        @Attribute(.unique) var poemId: Int
        var poetId: Int
        var title: String
        var addedAt: Date

        init(poemId: Int, poetId: Int, title: String, addedAt: Date = .now) {
            self.poemId = poemId
            self.poetId = poetId
            self.title = title
            self.addedAt = addedAt
        }
    }

    @Model final class DailyActivity {
        /// yyyy-MM-dd, gregorian, local time zone.
        @Attribute(.unique) var dayKey: String
        var reviewCount: Int
        var learnedCount: Int

        init(dayKey: String, reviewCount: Int = 0, learnedCount: Int = 0) {
            self.dayKey = dayKey
            self.reviewCount = reviewCount
            self.learnedCount = learnedCount
        }
    }

    // MARK: Added in V2 (purely additive: new entities only)

    @Model final class DailyXP {
        /// yyyy-MM-dd, gregorian, local time zone (same format as `DailyActivity.dayKey`).
        @Attribute(.unique) var dayKey: String
        var xp: Int
        var goal: Int
        var lessons: Int
        var perfectLessons: Int
        var goalMetAt: Date?

        init(dayKey: String, xp: Int = 0, goal: Int = 20, lessons: Int = 0, perfectLessons: Int = 0,
             goalMetAt: Date? = nil) {
            self.dayKey = dayKey
            self.xp = xp
            self.goal = goal
            self.lessons = lessons
            self.perfectLessons = perfectLessons
            self.goalMetAt = goalMetAt
        }
    }

    @Model final class LessonRecord {
        #Index<LessonRecord>([\.poemId], [\.nodeId])
        var poemId: Int
        var nodeId: String
        /// `LessonKind.rawValue`.
        var kindRaw: String
        var completedAt: Date
        var dayKey: String
        var gradedCount: Int
        var mistakes: Int
        var xp: Int
        var passed: Bool

        init(poemId: Int, nodeId: String, kindRaw: String, completedAt: Date = .now, dayKey: String,
             gradedCount: Int = 0, mistakes: Int = 0, xp: Int = 0, passed: Bool = true) {
            self.poemId = poemId
            self.nodeId = nodeId
            self.kindRaw = kindRaw
            self.completedAt = completedAt
            self.dayKey = dayKey
            self.gradedCount = gradedCount
            self.mistakes = mistakes
            self.xp = xp
            self.passed = passed
        }
    }

    @Model final class AchievementRecord {
        /// `BadgeID.rawValue`.
        @Attribute(.unique) var badgeId: String
        var unlockedAt: Date
        var isSeen: Bool

        init(badgeId: String, unlockedAt: Date = .now, isSeen: Bool = false) {
            self.badgeId = badgeId
            self.unlockedAt = unlockedAt
            self.isSeen = isSeen
        }
    }

    @Model final class FrozenDay {
        @Attribute(.unique) var dayKey: String
        var appliedAt: Date

        init(dayKey: String, appliedAt: Date = .now) {
            self.dayKey = dayKey
            self.appliedAt = appliedAt
        }
    }

    @Model final class GamificationState {
        /// Singleton row, key "main".
        @Attribute(.unique) var key: String
        var legacyXP: Int
        var freezesAvailable: Int
        /// Persian week key "yyyy-ww" of the last weekly freeze grant.
        var lastFreezeGrantWeek: String
        var longestStreak: Int
        var falOpenCount: Int
        var nightSessions: Int
        var earlySessions: Int
        var didBackfill: Bool

        init(key: String = "main", legacyXP: Int = 0, freezesAvailable: Int = 0, lastFreezeGrantWeek: String = "",
             longestStreak: Int = 0, falOpenCount: Int = 0, nightSessions: Int = 0, earlySessions: Int = 0,
             didBackfill: Bool = false) {
            self.key = key
            self.legacyXP = legacyXP
            self.freezesAvailable = freezesAvailable
            self.lastFreezeGrantWeek = lastFreezeGrantWeek
            self.longestStreak = longestStreak
            self.falOpenCount = falOpenCount
            self.nightSessions = nightSessions
            self.earlySessions = earlySessions
            self.didBackfill = didBackfill
        }
    }

    @Model final class PoemPathState {
        @Attribute(.unique) var poemId: Int
        /// Fixed when the path is first created, so changing the setting never reshuffles it.
        var lessonSize: Int
        var createdAt: Date

        init(poemId: Int, lessonSize: Int, createdAt: Date = .now) {
            self.poemId = poemId
            self.lessonSize = lessonSize
            self.createdAt = createdAt
        }
    }
}

typealias CoupletCard = AzBarSchemaV2.CoupletCard
typealias MemorizationPlan = AzBarSchemaV2.MemorizationPlan
typealias ReviewLogEntry = AzBarSchemaV2.ReviewLogEntry
typealias FavoritePoem = AzBarSchemaV2.FavoritePoem
typealias DailyActivity = AzBarSchemaV2.DailyActivity
typealias DailyXP = AzBarSchemaV2.DailyXP
typealias LessonRecord = AzBarSchemaV2.LessonRecord
typealias AchievementRecord = AzBarSchemaV2.AchievementRecord
typealias FrozenDay = AzBarSchemaV2.FrozenDay
typealias GamificationState = AzBarSchemaV2.GamificationState
typealias PoemPathState = AzBarSchemaV2.PoemPathState
