import SwiftData

/// V1 -> V2 only adds entities (DailyXP, LessonRecord, AchievementRecord, FrozenDay, GamificationState,
/// PoemPathState), so a lightweight stage is enough and existing rows survive untouched.
enum AzBarMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [AzBarSchemaV1.self, AzBarSchemaV2.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: AzBarSchemaV1.self, toVersion: AzBarSchemaV2.self)]
    }
}
