import SwiftUI

// MARK: - Learn step body

struct LearnStepBody: View {
    @Bindable var model: LearnModel

    @Environment(AudioPlayerService.self) private var audio
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showMeaning = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Text(model.heading)
                .font(.app(.title3))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
            if model.isRetry {
                Label("مرور دوباره", systemImage: "arrow.counterclockwise")
                    .font(.app(.footnote, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            if let couplet = model.couplet {
                stepContent(for: couplet)
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.xl)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
        .onChange(of: model.stepKey) { _, _ in showMeaning = false }
    }

    @ViewBuilder
    private func stepContent(for couplet: Couplet) -> some View {
        switch model.step {
        case .read:
            readContent(couplet)
        case .cloze(let level):
            if model.isRevealed {
                RevealedCoupletCard(couplet: couplet)
            } else if let cloze = model.cloze {
                SessionCard { ClozeCoupletView(cloze: cloze, hiddenIds: cloze.hiddenIds(level: level)) }
                hint("روی جای خالی ضربه بزنید تا لحظه‌ای واژه را ببینید")
            }
        case .firstLetters:
            if let cloze = model.cloze {
                SessionCard { ClozeCoupletView(cloze: cloze, hiddenIds: cloze.hiddenIds(level: 3), style: .hints) }
                hint("روی هر واژه ضربه بزنید تا لحظه‌ای آن را ببینید")
            }
        case .recallSecond:
            recallSecondContent(couplet)
        case .recallChain:
            recallChainContent(couplet)
        case .fillBlank:
            if case .fillBlank(let exercise)? = model.currentExercise {
                FillBlankView(exercise: exercise, contextMesra: model.fillBlankContext,
                              selected: $model.selectedOption, result: model.checkResult)
            }
        case .wordBank:
            if case .wordBank(let exercise)? = model.currentExercise {
                WordBankView(exercise: exercise, chosen: $model.chosenTileIds, result: model.checkResult)
                hint("روی واژه‌ها به ترتیب ضربه بزنید")
            }
        case nil:
            EmptyView()
        }
    }

    private func hint(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.app(.footnote))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private func readContent(_ couplet: Couplet) -> some View {
        VStack(spacing: Theme.Spacing.l) {
            SessionCard {
                CoupletView(couplet: couplet, layout: sizeClass == .compact ? .stacked : .sideBySide,
                            showMeaning: false)
            }
            if showMeaning, let summary = couplet.summary, !summary.isEmpty {
                Text(verbatim: summary)
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.Spacing.s)
                    .transition(.opacity)
            }
            HStack(spacing: Theme.Spacing.m) {
                if let summary = couplet.summary, !summary.isEmpty {
                    Button {
                        withAnimation(.smooth) { showMeaning.toggle() }
                    } label: {
                        Label("معنی", systemImage: showMeaning ? "text.bubble.fill" : "text.bubble")
                    }
                    .buttonStyle(.glass)
                    .accessibilityHint(showMeaning ? "پنهان کردن معنی" : "نمایش معنی")
                }
                if model.hasSyncedRecitation {
                    Button {
                        model.playCurrentCouplet(audio: audio)
                    } label: {
                        Label("پخش این بیت", systemImage: "speaker.wave.2")
                    }
                    .buttonStyle(.glass)
                }
            }
            .font(.app(.subheadline, weight: .medium))
        }
    }

    private func recallSecondContent(_ couplet: Couplet) -> some View {
        VStack(spacing: Theme.Spacing.l) {
            if model.isRevealed {
                RevealedCoupletCard(couplet: couplet)
            } else {
                SessionCard {
                    VStack(spacing: Theme.Spacing.m) {
                        MesraText(text: couplet.firstMesra, font: settingsFont, size: settingsSize)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        RecallPlaceholder(label: "مصراع دوم پنهان است")
                    }
                }
            }
        }
    }

    private func recallChainContent(_ couplet: Couplet) -> some View {
        VStack(spacing: Theme.Spacing.l) {
            if let previous = model.previousCouplet {
                RevealedCoupletCard(couplet: previous, dimmed: true)
                    .accessibilityLabel("بیت پیشین")
            }
            Image(systemName: "arrow.down")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            if model.isRevealed {
                RevealedCoupletCard(couplet: couplet)
            } else {
                RecallPlaceholder(label: "بیت بعد پنهان است")
            }
        }
    }

    @Environment(AppSettings.self) private var settings: AppSettings?
    private var settingsFont: PoemFont { settings?.poemFont ?? .naskh }
    private var settingsSize: CGFloat { CGFloat(settings?.poemFontSize ?? 22) }
}

// MARK: - Learn bottom bar

struct LearnBottomBar: View {
    @Bindable var model: LearnModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if model.isGradedStep, model.isRevealed, let result = model.checkResult {
                feedback(result)
                    .transition(.move(edge: .bottom))
            } else {
                SessionActionBar { actions }
            }
        }
        .sensoryFeedback(trigger: model.checkCount) { _, _ in
            model.checkResult?.isCorrect == true ? .success : .error
        }
        .sensoryFeedback(.selection, trigger: model.stepKey)
    }

    @ViewBuilder
    private var actions: some View {
        if model.isGradedStep {
            VStack(spacing: Theme.Spacing.s) {
                Button("بررسی") { animated { model.check() } }
                    .buttonStyle(.chunky(Theme.Playful.correct))
                    .disabled(!model.canCheck)
                Button("نمی‌دانم") { animated { model.check(giveUp: true) } }
                    .font(.app(.subheadline, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 36)
            }
        } else if model.awaitsRating {
            RatingBar(previews: model.ratingPreviews(), now: model.previewDate, suggested: model.suggestedRating) { rating in
                animated { model.rate(rating) }
            }
        } else if model.isRecallStep && !model.isRevealed {
            Button { animated { model.reveal() } } label: {
                Label("نمایش پاسخ", systemImage: "eye")
            }
            .buttonStyle(.chunky(.blue))
        } else {
            Button("ادامه") { animated { model.next() } }
                .buttonStyle(.chunky(Theme.Playful.correct))
        }
    }

    private var ratingBar: some View {
        RatingBar(previews: model.ratingPreviews(), now: model.previewDate, suggested: model.suggestedRating) { rating in
            animated { model.rate(rating) }
        }
    }

    @ViewBuilder
    private func feedback(_ result: ExerciseResult) -> some View {
        let advance = { animated { model.next() } }
        if model.awaitsRating {
            if result.isCorrect {
                FeedbackPanel(kind: .correct(message: model.correctMessage), xp: model.lastCheckXP, onContinue: advance) { ratingBar }
            } else {
                FeedbackPanel(kind: .incorrect(answer: result.expected), xp: 0, onContinue: advance) { ratingBar }
            }
        } else if result.isCorrect {
            FeedbackPanel(kind: .correct(message: model.correctMessage), xp: model.lastCheckXP, onContinue: advance)
        } else {
            FeedbackPanel(kind: .incorrect(answer: result.expected), xp: 0, onContinue: advance)
        }
    }

    private func animated(_ body: () -> Void) {
        if reduceMotion { body() } else { withAnimation(.smooth, body) }
    }
}

#Preview("Read") {
    PreviewContainer {
        LearnStepPreview()
    }
}

private struct LearnStepPreview: View {
    @Environment(AppModel.self) private var app
    @State private var model = LearnModel(request: LearnRequest(poemId: 2130, poetId: 2))

    var body: some View {
        ScrollView { LearnStepBody(model: model) }
            .safeAreaInset(edge: .bottom) { LearnBottomBar(model: model) }
            .task {
                await model.load(content: app.content, progress: app.progress, settings: app.settings,
                                 gamification: app.gamification, sounds: app.sounds)
            }
    }
}
