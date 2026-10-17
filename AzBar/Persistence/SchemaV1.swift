import Foundation
import SwiftData

enum AzBarSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [CoupletCard.self, MemorizationPlan.self, ReviewLogEntry.self, FavoritePoem.self, DailyActivity.self]
    }
}

enum AzBarMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [AzBarSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

extension AzBarSchemaV1 {
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
}

typealias CoupletCard = AzBarSchemaV1.CoupletCard
typealias MemorizationPlan = AzBarSchemaV1.MemorizationPlan
typealias ReviewLogEntry = AzBarSchemaV1.ReviewLogEntry
typealias FavoritePoem = AzBarSchemaV1.FavoritePoem
typealias DailyActivity = AzBarSchemaV1.DailyActivity
