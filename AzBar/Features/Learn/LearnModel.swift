import SwiftUI

@MainActor @Observable
final class LearnModel {
    enum Phase {
        case loading
        case failed
        /// The poem has no memorizable couplets (prose); no plan is created.
        case unavailable
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

    /// Reward of the finished lesson (set when `phase == .summary` after a completed session).
    private(set) var reward: SessionReward?
    private(set) var kind: LessonKind = .lesson
    private(set) var nodeId: String?
    private(set) var passed = true
    /// XP awarded during the session through graded answers and first ratings.
    private(set) var sessionXP = 0

    // Exercise answer state (reset on every step change).
    var chosenTileIds: [Int] = []
    var selectedOption: Int?
    private(set) var checkResult: ExerciseResult?
    private(set) var checkCount = 0
    private(set) var lastCheckXP = 0

    private let request: LearnRequest
    private var activeMode: LearnMode
    private var progress: ProgressStore?
    private var settings: AppSettings?
    private var gamification: GamificationStore?
    private var sounds: SoundEffects?
    private var clozeCache: [Int: ClozeEngine] = [:]

    init(request: LearnRequest) {
        self.request = request
        self.activeMode = request.mode
    }

    // MARK: Loading

    func load(content: ContentRepository, progress: ProgressStore, settings: AppSettings,
              gamification: GamificationStore, sounds: SoundEffects) async {
        guard poem == nil else { return }
        self.progress = progress
        self.settings = settings
        self.gamification = gamification
        self.sounds = sounds
        phase = .loading
        do {
            let poem = try await content.poem(request.poemId, poetId: request.poetId)
            self.poem = poem
            guard !poem.memorizableCouplets.isEmpty else {
                phase = .unavailable
                return
            }
            if progress.plan(poemId: poem.id) == nil {
                progress.addPlan(poem: poem, poetName: content.catalog.entry(poem.poetId)?.name ?? "")
            }
            startBatch()
        } catch {
            phase = .failed
        }
    }

    func retry(content: ContentRepository, progress: ProgressStore, settings: AppSettings,
               gamification: GamificationStore, sounds: SoundEffects) async {
        poem = nil
        await load(content: content, progress: progress, settings: settings, gamification: gamification, sounds: sounds)
    }

    /// Starts the next batch of the session: the next lesson, a practice node or the challenge.
    func startBatch() {
        guard let poem, let progress, let settings else { return }
        gamification?.beginSession()
        learnedKeys = []
        clozeCache = [:]
        reward = nil
        sessionXP = 0
        passed = true
        resetAnswer()

        var chosen: [Int] = []
        var options = LearnSessionOptions.classic
        switch activeMode {
        case .challenge:
            kind = .challenge
            nodeId = "C"
            chosen = poem.memorizableCouplets.map(\.index)
            options = .challenge
        case .practice(let node, let indices):
            kind = .practice
            nodeId = node
            chosen = indices
            options = .practice
        case .lesson(let node, let indices):
            kind = .lesson
            nodeId = node
            let existing = progress.cards(poemId: poem.id)
            chosen = indices.filter { existing[CoupletKey(poemId: poem.id, coupletIndex: $0)] == nil }
            if chosen.isEmpty { chosen = indices }
            options = settings.exercisesEnabled ? .interactive : .classic
        case .nextLesson:
            kind = .lesson
            nodeId = nil
            let existing = progress.cards(poemId: poem.id)
            if let gamification, let node = LearningPath.currentNode(in: gamification.path(for: poem)), node.kind == .lesson {
                chosen = node.coupletIndices.filter { existing[CoupletKey(poemId: poem.id, coupletIndex: $0)] == nil }
                if !chosen.isEmpty { nodeId = node.id }
            }
            if chosen.isEmpty {
                let start = progress.plan(poemId: poem.id)?.nextCoupletIndex ?? 0
                let candidates = poem.memorizableCouplets.filter {
                    $0.index >= max(start, 0) && existing[CoupletKey(poemId: poem.id, coupletIndex: $0.index)] == nil
                }
                chosen = candidates.prefix(settings.newCoupletsPerSession).map(\.index)
            }
            options = settings.exercisesEnabled ? .interactive : .classic
        }

        batchCount = chosen.count
        if chosen.isEmpty {
            engine = nil
            isPoemComplete = kind == .lesson
            phase = .summary
            return
        }
        let newEngine = LearnSessionEngine(poem: poem, coupletIndices: chosen, options: options)
        engine = newEngine
        isPoemComplete = false
        batchCount = kind == .lesson ? chosen.count : newEngine.queue.count
        if newEngine.isFinished {
            reward = SessionReward(xpEarned: 0, accuracy: nil, celebrations: [])
            phase = .summary
        } else {
            phase = .session
        }
    }

    /// Continues with the next lesson of the path after a finished lesson.
    func startNextLesson() {
        activeMode = .nextLesson
        startBatch()
    }

    var hasNextLesson: Bool { kind == .lesson && !isPoemComplete && reward != nil }

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

    /// Toolbar title: couplet position for lessons, a fixed label for practice and challenge.
    var titleText: String {
        switch kind {
        case .lesson: "بیت \(positionInBatch.fa) از \(batchCount.fa)"
        case .practice: "تمرین"
        case .challenge: "آزمون پایانی"
        }
    }
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
        case .fillBlank: "واژهٔ جاافتاده را برگزینید"
        case .wordBank(let mesra, _):
            couplet?.kind == .single ? "مصراع را بچینید" : (mesra == 0 ? "مصراع نخست را بچینید" : "مصراع دوم را بچینید")
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

    // MARK: Exercise state

    var isGradedStep: Bool { engine?.isGradedStep ?? false }
    var currentExercise: LearnExercise? { engine?.currentExercise }

    /// True when the current graded step has an answer ready to check.
    var canCheck: Bool {
        switch currentExercise {
        case .wordBank: !chosenTileIds.isEmpty
        case .fillBlank: selectedOption != nil
        case nil: false
        }
    }

    /// Mesra shown above a fill-blank exercise for context.
    var fillBlankContext: String? {
        guard case .fillBlank(let exercise)? = currentExercise, exercise.mesraIndex > 0 else { return nil }
        return couplet?.firstMesra
    }

    /// Rating the bar highlights; only meaningful when graded answers were collected.
    var suggestedRating: Rating? {
        guard let engine, engine.options.includeExercises, let index = currentCoupletIndex else { return nil }
        return engine.suggestedRating(for: index)
    }

    static let correctMessages = ["آفرین!", "عالی!", "درست است!", "احسنت!", "بسیار خوب!"]

    var correctMessage: String {
        let n = (engine?.itemPosition ?? 0) + (engine?.stepPosition ?? 0)
        return Self.correctMessages[n % Self.correctMessages.count]
    }

    private func resetAnswer() {
        chosenTileIds = []
        selectedOption = nil
        checkResult = nil
    }

    // MARK: Actions

    func next() {
        engine?.advance()
        resetAnswer()
        finishIfNeeded()
    }

    func reveal() {
        previewDate = .now
        engine?.reveal()
    }

    /// Checks the collected answer; `giveUp` counts as a wrong answer («نمی‌دانم»).
    func check(giveUp: Bool = false) {
        guard let engine, engine.isGradedStep, !engine.isRevealed, let exercise = engine.currentExercise else { return }
        let result: ExerciseResult
        switch exercise {
        case .wordBank(let e):
            let base = e.evaluate(chosenTileIds)
            result = giveUp ? ExerciseResult(isCorrect: false, wrongPositions: base.wrongPositions, expected: base.expected) : base
        case .fillBlank(let e):
            if giveUp {
                let base = e.evaluate(optionIndex: e.correctOptionIndex)
                result = ExerciseResult(isCorrect: false, wrongPositions: [], expected: base.expected)
            } else {
                guard let selectedOption else { return }
                result = e.evaluate(optionIndex: selectedOption)
            }
        }
        previewDate = .now
        self.engine?.check(correct: result.isCorrect)
        checkResult = result
        checkCount += 1
        if result.isCorrect {
            lastCheckXP = award([XPAward(.exerciseCorrect, XPTable.exerciseCorrect)])
            sounds?.play(.correct)
        } else {
            lastCheckXP = 0
            sounds?.play(.wrong)
        }
    }

    @discardableResult
    private func award(_ awards: [XPAward]) -> Int {
        let amount = gamification?.award(awards) ?? awards.reduce(0) { $0 + $1.amount }
        sessionXP += amount
        return amount
    }

    func rate(_ rating: Rating) {
        guard let poem, let progress, engine != nil else { return }
        let wasRetry = engine?.currentItem?.isRetry ?? false
        guard let event = engine?.rate(rating) else { return }
        resetAnswer()
        let key = CoupletKey(poemId: poem.id, coupletIndex: event.coupletIndex)
        progress.record(rating, key: key, poetId: poem.poetId, isLearning: true, scheduler: scheduler)
        if !wasRetry {
            award([XPAward(.coupletLearned, XPTable.coupletLearned)])
        }
        learnedKeys.insert(event.coupletIndex)
        // First memorizable couplet without a card is where the next session starts.
        let cards = progress.cards(poemId: poem.id)
        let next = poem.memorizableCouplets.first {
            cards[CoupletKey(poemId: poem.id, coupletIndex: $0.index)] == nil
        }?.index ?? -1
        progress.advancePlan(poemId: poem.id, to: next)
        if engine?.isFinished == true {
            isPoemComplete = next == -1
            finish()
        }
    }

    /// Practice and challenge sessions end through `advance()`, learn sessions through `rate`.
    private func finishIfNeeded() {
        if let engine, engine.options.mode != .learn, engine.isFinished, phase == .session {
            finish()
        }
    }

    private func finish() {
        guard let poem, let engine, let gamification else {
            phase = .summary
            return
        }
        let graded = engine.gradedCount
        let mistakes = engine.totalMistakes
        passed = kind == .challenge ? LessonScoring.challengePassed(graded: graded, mistakes: mistakes) : true
        let outcome = LessonOutcome(poemId: poem.id, nodeId: nodeId, kind: kind, gradedCount: graded,
                                    mistakes: mistakes, newCouplets: learnedKeys.count, passed: passed,
                                    finishedAt: .now)
        reward = gamification.completeLesson(outcome)
        phase = .summary
    }

    /// Total XP of the session shown on the summary.
    var totalXP: Int { max(reward?.xpEarned ?? 0, sessionXP) }

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
