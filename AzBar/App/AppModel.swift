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
    let gamification: GamificationStore
    let sounds: SoundEffects

    var selectedTab: AppTab = .today
    var learnRequest: LearnRequest?
    var isReviewPresented = false
    var isFalPresented = false

    init(container: ModelContainer, content: ContentRepository, settings: AppSettings) {
        self.container = container
        self.content = content
        self.settings = settings
        let audio = AudioPlayerService()
        self.audio = audio
        self.reminders = ReminderScheduler()
        let progress = ProgressStore(container: container)
        self.progress = progress
        self.gamification = GamificationStore(container: container, progress: progress, settings: settings)
        self.sounds = SoundEffects(settings: settings, isRecitationActive: {
            switch audio.status {
            case .idle, .failed: false
            case .loading, .playing, .paused: true
            }
        })
    }

    static func live() -> AppModel {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Schema(versionedSchema: AzBarSchemaV2.self),
                migrationPlan: AzBarMigrationPlan.self
            )
        } catch {
            Logger(subsystem: "com.github.meysampg.azbar", category: "persistence").error("On-disk ModelContainer failed: \(String(describing: error))")
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
        return try! ModelContainer(for: Schema(versionedSchema: AzBarSchemaV2.self),
                                   migrationPlan: AzBarMigrationPlan.self, configurations: config)
    }

    func startLearning(poemId: PoemID, poetId: PoetID, mode: LearnMode = .nextLesson) {
        learnRequest = LearnRequest(poemId: poemId, poetId: poetId, mode: mode)
    }
}
