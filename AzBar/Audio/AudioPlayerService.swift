import AVFoundation
import MediaPlayer

/// Streams a poem recitation with AVPlayer, exposes sync-point based verse tracking, couplet segment
/// playback, and Now Playing / remote command integration.
@MainActor @Observable
final class AudioPlayerService {
    enum Status: Equatable { case idle, loading, playing, paused, failed(String) }

    private(set) var status: Status = .idle
    private(set) var poemId: PoemID?
    private(set) var recitation: Recitation?
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var syncPoints: [SyncPoint] = []
    /// The user's play intent (true while buffering after a play request).
    private(set) var wantsToPlay = false

    /// True while audio is playing or is about to play once buffered.
    var isPlaying: Bool { status == .playing || (status == .loading && wantsToPlay) }

    /// Last sync point with milliseconds <= currentTime * 1000.
    var currentVerseOffset: Int? {
        let ms = Int(currentTime * 1000)
        return syncPoints.last { $0.milliseconds <= ms }?.verseOffset
    }

    @ObservationIgnored private var player: AVPlayer?
    @ObservationIgnored private var currentPoem: Poem?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var boundaryObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?
    @ObservationIgnored private var itemObservation: NSKeyValueObservation?
    @ObservationIgnored private var segmentEnd: TimeInterval?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var remoteCommandsConfigured = false

    init() {}

    // MARK: Loading

    /// `autoplay` starts playback as soon as the item is buffered (before sync points finish loading).
    func load(poem: Poem, recitation: Recitation, autoplay: Bool = false) async {
        if case .failed = status {} else if poemId == poem.id, self.recitation?.id == recitation.id, player != nil {
            return
        }
        teardownPlayer()
        generation += 1
        let gen = generation
        currentPoem = poem
        poemId = poem.id
        self.recitation = recitation
        syncPoints = []
        currentTime = 0
        duration = 0
        status = .loading
        wantsToPlay = autoplay

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
        configureRemoteCommands()

        let item = AVPlayerItem(url: recitation.mp3Url)
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = true
        self.player = player
        if autoplay { player.play() }

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main
        ) { [weak self] time in
            let seconds = time.seconds
            MainActor.assumeIsolated { self?.tick(seconds) }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.didFinishPlaying() }
        }
        itemObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            let itemStatus = item.status
            let message = item.error?.localizedDescription
            let seconds = item.duration.seconds
            Task { @MainActor in
                self?.itemStatusChanged(itemStatus, message: message, duration: seconds, generation: gen)
            }
        }

        if recitation.synced, let url = recitation.syncUrl {
            let points = (try? await RecitationSyncLoader().load(url, session: .shared)) ?? []
            guard gen == generation else { return }
            syncPoints = points.sorted { $0.milliseconds < $1.milliseconds }
        }
        updateNowPlaying()
    }

    // MARK: Transport

    func play() {
        guard let player else { return }
        if case .failed = status { return }
        wantsToPlay = true
        configureSessionActive()
        player.play()
        if status == .paused { status = .playing }
        updateNowPlaying()
    }

    func pause() {
        wantsToPlay = false
        player?.pause()
        if status == .playing { status = .paused }
        updateNowPlaying()
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        clearSegment()
        let upper = duration > 0 ? duration : .greatestFiniteMagnitude
        let target = min(max(0, time), upper)
        currentTime = target
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { _ in })
        updateNowPlaying()
    }

    func skip(by seconds: TimeInterval) {
        seek(to: currentTime + seconds)
    }

    func stop() {
        teardownPlayer()
        generation += 1
        poemId = nil
        recitation = nil
        currentPoem = nil
        syncPoints = []
        currentTime = 0
        duration = 0
        wantsToPlay = false
        status = .idle
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: Couplet seeking

    func seek(toCouplet index: Int, in poem: Poem) {
        guard poem.id == poemId, let range = segment(ofCouplet: index, in: poem) else { return }
        seek(to: range.start)
    }

    /// Plays only the given couplet: seeks to its start and pauses at the next couplet's start.
    func playCouplet(_ index: Int, in poem: Poem) async {
        guard player != nil, poem.id == poemId else { return }
        guard let range = segment(ofCouplet: index, in: poem) else {
            play()
            return
        }
        clearSegment()
        currentTime = range.start
        player?.seek(to: CMTime(seconds: range.start, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { _ in })
        if let end = range.end { armSegmentEnd(end) }
        play()
    }

    /// Start and (optional) end time of a couplet from the sync points.
    private func segment(ofCouplet index: Int, in poem: Poem) -> (start: TimeInterval, end: TimeInterval?)? {
        guard !syncPoints.isEmpty, let couplet = poem.couplet(at: index) else { return nil }
        let ordered = poem.orderedVerses
        let ids = Set(couplet.verses.map(\.id))
        let offsets = ordered.indices.filter { ids.contains(ordered[$0].id) }
        guard let last = offsets.max() else { return nil }
        let own = syncPoints.filter { offsets.contains($0.verseOffset) }
        guard let startMs = own.map(\.milliseconds).min() else { return nil }
        let following = syncPoints.filter { $0.verseOffset > last }.sorted { $0.verseOffset < $1.verseOffset }
        let endMs = following.first?.milliseconds
        return (Double(startMs) / 1000, endMs.map { Double($0) / 1000 })
    }

    // MARK: Segment handling

    private func armSegmentEnd(_ end: TimeInterval) {
        segmentEnd = end
        let value = NSValue(time: CMTime(seconds: end, preferredTimescale: 600))
        boundaryObserver = player?.addBoundaryTimeObserver(forTimes: [value], queue: .main) { [weak self] in
            MainActor.assumeIsolated { self?.segmentFinished() }
        }
    }

    private func clearSegment() {
        segmentEnd = nil
        if let boundaryObserver { player?.removeTimeObserver(boundaryObserver) }
        boundaryObserver = nil
    }

    private func segmentFinished() {
        guard segmentEnd != nil else { return }
        clearSegment()
        pause()
    }

    // MARK: Callbacks

    private func tick(_ seconds: TimeInterval) {
        guard seconds.isFinite else { return }
        currentTime = seconds
        if duration == 0, let d = player?.currentItem?.duration.seconds, d.isFinite, d > 0 {
            duration = d
            updateNowPlaying()
        }
        if let end = segmentEnd, seconds >= end { segmentFinished() }
    }

    private func itemStatusChanged(_ itemStatus: AVPlayerItem.Status, message: String?, duration seconds: TimeInterval, generation gen: Int) {
        guard gen == generation else { return }
        switch itemStatus {
        case .readyToPlay:
            if seconds.isFinite, seconds > 0 { duration = seconds }
            if status == .loading { status = wantsToPlay ? .playing : .paused }
            updateNowPlaying()
        case .failed:
            wantsToPlay = false
            status = .failed(message ?? "پخش خوانش ناموفق بود")
        default:
            break
        }
    }

    private func didFinishPlaying() {
        clearSegment()
        wantsToPlay = false
        status = .paused
        currentTime = 0
        player?.seek(to: .zero)
        updateNowPlaying()
    }

    // MARK: Session, Now Playing, remote commands

    private func configureSessionActive() {
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func teardownPlayer() {
        clearSegment()
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        timeObserver = nil
        itemObservation?.invalidate()
        itemObservation = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }

    private func updateNowPlaying() {
        guard let poem = currentPoem, let recitation else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: poem.title,
            MPMediaItemPropertyArtist: recitation.artist,
            MPMediaItemPropertyAlbumTitle: poem.fullTitle,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: status == .playing ? 1.0 : 0.0,
        ]
        if duration > 0 { info[MPMediaItemPropertyPlaybackDuration] = duration }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func configureRemoteCommands() {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.play() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.toggle() }
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [10]
        center.skipForwardCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.skip(by: 10) }
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [10]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.skip(by: -10) }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let position = (event as? MPChangePlaybackPositionCommandEvent)?.positionTime else {
                return .commandFailed
            }
            MainActor.assumeIsolated { self?.seek(to: position) }
            return .success
        }
    }
}
