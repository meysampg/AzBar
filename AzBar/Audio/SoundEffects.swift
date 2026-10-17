// STUB (P-A): implement, keep signatures
import Foundation

/// Short feedback sounds. P0 ships the contract; package A implements playback.
@MainActor
final class SoundEffects {
    enum Effect: String, CaseIterable {
        case correct = "sfx-correct"
        case wrong = "sfx-wrong"
        case lessonComplete = "sfx-lesson-complete"
        case levelUp = "sfx-level-up"
    }

    private let settings: AppSettings
    private let isRecitationActive: @MainActor () -> Bool

    init(settings: AppSettings, isRecitationActive: @escaping @MainActor () -> Bool) {
        self.settings = settings
        self.isRecitationActive = isRecitationActive
    }

    func play(_ effect: Effect) {
        guard settings.soundsEnabled else { return }
        _ = (effect, isRecitationActive())
    }
}
