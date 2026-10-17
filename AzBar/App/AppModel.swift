import SwiftUI
import SwiftData
import os

@MainActor @Observable
final class AppModel {
    let container: ModelContainer
    let content: ContentRepository
    let progress: ProgressStore
    let settings: AppSettings
    let audio: AudioPlayerService
    let reminders: ReminderScheduler

    var selectedTab: AppTab = .today
    var learnRequest: LearnRequest?
    var isReviewPresented = false
    var isFalPresented = false

    init(container: ModelContainer, content: ContentRepository, settings: AppSettings) {
        self.container = container
        self.content = content
        self.settings = settings
        self.progress = ProgressStore(container: container)
        self.audio = AudioPlayerService()
        self.reminders = ReminderScheduler()
    }

    static func live() -> AppModel {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Schema(versionedSchema: AzBarSchemaV1.self),
                migrationPlan: AzBarMigrationPlan.self
            )
        } catch {
            Logger(subsystem: "com.meysam.azbar", category: "persistence").error("On-disk ModelContainer failed: \(String(describing: error))")
            #if DEBUG
            assertionFailure("On-disk ModelContainer failed: \(error)")
            #endif
            container = Self.inMemoryContainer()
        }
        return AppModel(container: container, content: .live(bundle: .main), settings: AppSettings())
    }

    static func preview() -> AppModel {
        let suite = UserDefaults(suiteName: "azbar.preview") ?? .standard
        return AppModel(container: inMemoryContainer(), content: .live(bundle: .main), settings: AppSettings(defaults: suite))
    }

    private static func inMemoryContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // An in-memory container for a valid schema cannot realistically fail.
        return try! ModelContainer(for: Schema(versionedSchema: AzBarSchemaV1.self),
                                   migrationPlan: AzBarMigrationPlan.self, configurations: config)
    }

    func startLearning(poemId: PoemID, poetId: PoetID) {
        learnRequest = LearnRequest(poemId: poemId, poetId: poetId)
    }
}
