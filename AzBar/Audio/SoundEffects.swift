import AVFoundation

/// Short feedback sounds. Uses the `.ambient` category when no recitation is active, so the silent
/// switch is respected and other audio keeps playing; while a recitation plays, the `.playback`
/// session is left untouched. The session is never deactivated.
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
    private var players: [Effect: AVAudioPlayer] = [:]

    init(settings: AppSettings, isRecitationActive: @escaping @MainActor () -> Bool) {
        self.settings = settings
        self.isRecitationActive = isRecitationActive
    }

    func play(_ effect: Effect) {
        guard settings.soundsEnabled, let player = player(for: effect) else { return }
        if !isRecitationActive() {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.ambient, mode: .default)
            try? session.setActive(true)
        }
        player.currentTime = 0
        player.play()
    }

    private func player(for effect: Effect) -> AVAudioPlayer? {
        if let existing = players[effect] { return existing }
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        players[effect] = player
        return player
    }
}
