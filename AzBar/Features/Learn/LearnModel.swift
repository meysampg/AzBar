import SwiftUI

@MainActor @Observable
final class LearnModel {
    enum Phase {
        case loading
        case failed
        case session
        case summary
    }

    private(set) var phase: Phase = .loading
    private(set) var poem: Poem?
    private(set) var engine: LearnSessionEngine?
    private(set) var batchCount = 0
    private(set) var learnedKeys: Set<Int> = []
    private(set) var isPoemComplete = false
    /// Date used to compute the interval previews (fixed when the answer is revealed).
    private(set) var previewDate: Date = .now
    /// True while this session has started audio, so it can be stopped on exit.
    private(set) var didStartAudio = false

    private let request: LearnRequest
    private var progress: ProgressStore?
    private var settings: AppSettings?
    private var clozeCache: [Int: ClozeEngine] = [:]

    init(request: LearnRequest) {
        self.request = request
    }

    // MARK: Loading

    func load(content: ContentRepository, progress: ProgressStore, settings: AppSettings) async {
        guard poem == nil else { return }
        self.progress = progress
        self.settings = settings
        phase = .loading
        do {
            let poem = try await content.poem(request.poemId, poetId: request.poetId)
            self.poem = poem
            if progress.plan(poemId: poem.id) == nil {
                progress.addPlan(poem: poem, poetName: content.catalog.entry(poem.poetId)?.name ?? "")
            }
            startBatch()
        } catch {
            phase = .failed
        }
    }

    func retry(content: ContentRepository, progress: ProgressStore, settings: AppSettings) async {
        poem = nil
        await load(content: content, progress: progress, settings: settings)
    }

    /// Picks the next couplets without a card, starting at the plan's next index.
    func startBatch() {
        guard let poem, let progress, let settings else { return }
        let start = progress.plan(poemId: poem.id)?.nextCoupletIndex ?? 0
        let existing = progress.cards(poemId: poem.id)
        let candidates = poem.memorizableCouplets.filter {
            $0.index >= max(start, 0) && existing[CoupletKey(poemId: poem.id, coupletIndex: $0.index)] == nil
        }
        let chosen = candidates.prefix(settings.newCoupletsPerSession).map(\.index)
        learnedKeys = []
        clozeCache = [:]
        batchCount = chosen.count
        if chosen.isEmpty {
            engine = nil
            isPoemComplete = true
            phase = .summary
        } else {
            engine = LearnSessionEngine(poem: poem, coupletIndices: chosen)
            isPoemComplete = false
            phase = .session
        }
    }

    // MARK: Derived state

    var step: LearnStep? { engine?.currentStep }
    var currentCoupletIndex: Int? { engine?.currentItem?.coupletIndex }
    var isRetry: Bool { engine?.currentItem?.isRetry ?? false }

    var couplet: Couplet? {
        guard let poem, let index = currentCoupletIndex else { return nil }
        return poem.couplet(at: index)
    }

    var previousCouplet: Couplet? {
        guard let poem, let index = currentCoupletIndex else { return nil }
        return poem.previousMemorizable(before: index)
    }

    var cloze: ClozeEngine? {
        guard let poem, let couplet else { return nil }
        if let cached = clozeCache[couplet.index] { return cached }
        let engine = ClozeEngine(poemId: poem.id, couplet: couplet)
        clozeCache[couplet.index] = engine
        return engine
    }

    /// Distinct couplet position within the batch, 1-based.
    var positionInBatch: Int {
        guard let engine else { return batchCount }
        let uniqueBefore = Set(engine.queue.prefix(engine.itemPosition).map(\.coupletIndex)).count
        let current = engine.currentItem.map { item in
            engine.queue.prefix(engine.itemPosition).contains { $0.coupletIndex == item.coupletIndex } ? 0 : 1
        } ?? 0
        return min(max(uniqueBefore + current, 1), max(batchCount, 1))
    }

    var progressValue: Double { engine?.progress ?? 1 }
    var isRevealed: Bool { engine?.isRevealed ?? false }
    var isRecallStep: Bool { engine?.isRecallStep ?? false }
    var awaitsRating: Bool { engine?.awaitsRating ?? false }

    var heading: String {
        switch step {
        case .read: "بخوان و گوش کن"
        case .cloze(let level): "جاهای خالی را به یاد آور · مرحلهٔ \(level.fa) از ۳"
        case .firstLetters: "با حرف نخست هر واژه"
        case .recallSecond: "مصراع دوم را به یاد آور"
        case .recallChain: "بیت بعد چیست؟"
        // STUB (P-C): headings for the interactive steps.
        case .fillBlank, .wordBank: ""
        case nil: ""
        }
    }

    /// Identity of the visible screen, used to animate step changes.
    var stepKey: String {
        guard let engine else { return "none" }
        return "\(engine.itemPosition)-\(engine.stepPosition)"
    }

    var scheduler: FSRSScheduler {
        FSRSScheduler(parameters: settings?.fsrsParameters ?? FSRSParameters())
    }

    func ratingPreviews() -> [Rating: SchedulingResult]? {
        guard let poem, let index = currentCoupletIndex, let progress else { return nil }
        let card = progress.card(CoupletKey(poemId: poem.id, coupletIndex: index)) ?? FSRSCard.new(now: previewDate)
        return scheduler.preview(card, now: previewDate)
    }

    // MARK: Actions

    func next() {
        engine?.advance()
    }

    func reveal() {
        previewDate = .now
        engine?.reveal()
    }

    func rate(_ rating: Rating) {
        guard let poem, let progress, engine != nil else { return }
        guard let event = engine?.rate(rating) else { return }
        let key = CoupletKey(poemId: poem.id, coupletIndex: event.coupletIndex)
        progress.record(rating, key: key, poetId: poem.poetId, isLearning: true, scheduler: scheduler)
        learnedKeys.insert(event.coupletIndex)
        // First memorizable couplet without a card is where the next session starts.
        let cards = progress.cards(poemId: poem.id)
        let next = poem.memorizableCouplets.first {
            cards[CoupletKey(poemId: poem.id, coupletIndex: $0.index)] == nil
        }?.index ?? -1
        progress.advancePlan(poemId: poem.id, to: next)
        if engine?.isFinished == true {
            isPoemComplete = next == -1
            phase = .summary
        }
    }

    // MARK: Audio

    var hasSyncedRecitation: Bool {
        poem?.recitations.contains(where: \.synced) ?? false
    }

    func playCurrentCouplet(audio: AudioPlayerService) {
        guard let poem, let index = currentCoupletIndex, let recitation = preferredRecitation(for: poem) else { return }
        didStartAudio = true
        Task {
            if audio.poemId != poem.id || audio.recitation?.id != recitation.id {
                await audio.load(poem: poem, recitation: recitation)
            }
            await audio.playCouplet(index, in: poem)
        }
    }

    func stopAudioIfNeeded(audio: AudioPlayerService) {
        if didStartAudio { audio.stop() }
    }

    private func preferredRecitation(for poem: Poem) -> Recitation? {
        let synced = poem.recitations.filter(\.synced).sorted { $0.order < $1.order }
        if let artist = settings?.preferredReciter, let match = synced.first(where: { $0.artist == artist }) {
            return match
        }
        return synced.first(where: { $0.type == 0 }) ?? synced.first
    }
}
