import SwiftUI

// MARK: - Shared session chrome (used by Learn and Review)

/// Floating bottom bar for session screens. Content is expected to be glass buttons.
struct SessionActionBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GlassEffectContainer(spacing: Theme.Spacing.s) {
            content
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.s)
        .padding(.top, Theme.Spacing.xs)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }
}

/// Full-width primary glass button.
struct SessionPrimaryButton: View {
    let title: LocalizedStringKey
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(.app(.headline))
            .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
    }
}

/// Both mesras of a couplet as cloze rows, laid out like `CoupletView(.stacked)`.
struct ClozeCoupletView: View {
    let cloze: ClozeEngine
    let hiddenIds: Set<Int>
    var style: ClozeMesraView.Style = .blank

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if cloze.tokens.count > 1, sizeClass == .compact {
            VStack(spacing: Theme.Spacing.m) {
                ClozeMesraView(tokens: cloze.tokens[0], hiddenIds: hiddenIds, style: style, rowAlignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ClozeMesraView(tokens: cloze.tokens[1], hiddenIds: hiddenIds, style: style, rowAlignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        } else {
            VStack(spacing: Theme.Spacing.m) {
                ForEach(Array(cloze.tokens.enumerated()), id: \.offset) { _, tokens in
                    ClozeMesraView(tokens: tokens, hiddenIds: hiddenIds, style: style)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

/// Dashed placeholder standing for the mesra/beyt the user must recall.
struct RecallPlaceholder: View {
    var label: String = "مصراع پنهان"

    @Environment(AppSettings.self) private var settings: AppSettings?

    var body: some View {
        let font = settings?.poemFont ?? .naskh
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .strokeBorder(.tertiary, style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
            .frame(maxWidth: .infinity, minHeight: 96)
            .overlay {
                Text("؟")
                    .font(.poem(font, size: 34))
                    .foregroundStyle(.tertiary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
    }
}

/// Wraps a couplet in the shared secondary content card.
struct SessionCard<Content: View>: View {
    var dimmed = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(Theme.Spacing.l)
            .frame(maxWidth: .infinity)
            .background(.background.secondary, in: .rect(cornerRadius: Theme.Radius.card))
            .opacity(dimmed ? 0.55 : 1)
    }
}

/// A fully visible couplet inside a card.
struct RevealedCoupletCard: View {
    let couplet: Couplet
    var dimmed = false
    var showMeaning = false

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        SessionCard(dimmed: dimmed) {
            CoupletView(couplet: couplet, layout: sizeClass == .compact ? .stacked : .sideBySide,
                        showMeaning: showMeaning)
        }
    }
}

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
        SessionActionBar {
            if model.awaitsRating {
                RatingBar(previews: model.ratingPreviews(), now: model.previewDate) { rating in
                    animated { model.rate(rating) }
                }
            } else if model.isRecallStep && !model.isRevealed {
                SessionPrimaryButton(title: "نمایش", systemImage: "eye") {
                    animated { model.reveal() }
                }
            } else {
                SessionPrimaryButton(title: "بعدی") {
                    animated { model.next() }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: model.stepKey)
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
            .task { await model.load(content: app.content, progress: app.progress, settings: app.settings) }
    }
}
