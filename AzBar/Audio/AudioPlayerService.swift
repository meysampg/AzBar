// STUB (WP3): replace implementation, keep signatures
import Foundation

@MainActor @Observable
final class AudioPlayerService {
    enum Status: Equatable { case idle, loading, playing, paused, failed(String) }

    private(set) var status: Status = .idle
    private(set) var poemId: PoemID?
    private(set) var recitation: Recitation?
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var syncPoints: [SyncPoint] = []

    /// Last sync point with milliseconds <= currentTime * 1000.
    var currentVerseOffset: Int? {
        let ms = Int(currentTime * 1000)
        return syncPoints.last { $0.milliseconds <= ms }?.verseOffset
    }

    init() {}

    func load(poem: Poem, recitation: Recitation) async {}
    func play() {}
    func pause() {}
    func toggle() {}
    func seek(to time: TimeInterval) {}
    func skip(by seconds: TimeInterval) {}
    func stop() {}
    func seek(toCouplet index: Int, in poem: Poem) {}
    func playCouplet(_ index: Int, in poem: Poem) async {}
}
