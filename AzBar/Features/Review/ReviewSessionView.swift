import SwiftUI

struct ReviewSessionView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = ReviewSessionModel()
    @State private var isConfirmingClose = false

    var body: some View {
        NavigationStack {
            Group {
                switch model.phase {
                case .loading:
                    ProgressView()
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .empty:
                    ContentUnavailableView(
                        "مروری باقی نمانده",
                        systemImage: "checkmark.seal",
                        description: Text("بیتی برای مرور آماده نیست.")
                    )
                case .session:
                    sessionContent
                case .summary:
                    ReviewSummaryView(counts: model.counts, streak: model.streak, onDone: { dismiss() })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("بستن", systemImage: "xmark") {
                        if model.phase == .session { isConfirmingClose = true } else { dismiss() }
                    }
                    .accessibilityLabel("بستن")
                }
                if model.phase == .session {
                    ToolbarItem(placement: .principal) {
                        Text("\(model.position.fa) از \(model.total.fa)")
                            .font(.app(.headline))
                            .accessibilityAddTraits(.isHeader)
                    }
                }
            }
            .confirmationDialog("مرور را ترک می‌کنید؟", isPresented: $isConfirmingClose, titleVisibility: .visible) {
                Button("ترک مرور", role: .destructive) { dismiss() }
                Button("ادامه", role: .cancel) {}
            } message: {
                Text("امتیازهایی که داده‌اید ذخیره شده است.")
            }
        }
        .interactiveDismissDisabled(model.phase == .session)
        .task { await model.load(content: app.content, progress: app.progress, settings: app.settings) }
    }

    private var sessionContent: some View {
        ScrollView {
            ReviewStepBody(model: model)
                .id(model.stepKey)
                .transition(.opacity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: model.stepKey)
        .safeAreaInset(edge: .top, spacing: 0) {
            ProgressView(value: model.progressValue)
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.xs)
                .accessibilityLabel("پیشرفت مرور")
                .accessibilityValue("\(Int((model.progressValue * 100).rounded()).fa) درصد")
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ReviewBottomBar(model: model)
        }
    }
}

// MARK: - Step body

struct ReviewStepBody: View {
    let model: ReviewSessionModel

    @Environment(AppSettings.self) private var settings: AppSettings?

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.xs) {
                Text(model.heading)
                    .font(.app(.title3))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: model.contextTitle)
                    .font(.app(.footnote))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            if let couplet = model.couplet {
                promptContent(couplet)
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.xl)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func promptContent(_ couplet: Couplet) -> some View {
        switch model.mode {
        case .recallSecond:
            if model.isRevealed {
                RevealedCoupletCard(couplet: couplet, showMeaning: settings?.showMeaning ?? false)
            } else {
                SessionCard {
                    VStack(spacing: Theme.Spacing.m) {
                        MesraText(text: couplet.firstMesra, font: settings?.poemFont ?? .naskh,
                                  size: CGFloat(settings?.poemFontSize ?? 22))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        RecallPlaceholder(label: "مصراع دوم پنهان است")
                    }
                }
            }
        case .recallChain:
            VStack(spacing: Theme.Spacing.l) {
                if let previous = model.previousCouplet {
                    RevealedCoupletCard(couplet: previous, dimmed: true)
                        .accessibilityLabel("بیت پیشین")
                }
                Image(systemName: "arrow.down")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
                if model.isRevealed {
                    RevealedCoupletCard(couplet: couplet, showMeaning: settings?.showMeaning ?? false)
                } else {
                    RecallPlaceholder(label: "بیت بعد پنهان است")
                }
            }
        case .recallFromHints:
            if model.isRevealed {
                RevealedCoupletCard(couplet: couplet, showMeaning: settings?.showMeaning ?? false)
            } else if let cloze = model.cloze {
                SessionCard {
                    ClozeCoupletView(cloze: cloze, hiddenIds: cloze.hiddenIds(level: 3), style: .hints)
                }
            }
        case nil:
            EmptyView()
        }
    }
}

// MARK: - Bottom bar

struct ReviewBottomBar: View {
    let model: ReviewSessionModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        SessionActionBar {
            if model.isRevealed {
                RatingBar(previews: model.ratingPreviews(), now: model.previewDate) { rating in
                    animated { model.rate(rating) }
                }
            } else {
                SessionPrimaryButton(title: "نمایش پاسخ", systemImage: "eye") {
                    animated { model.reveal() }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: model.isRevealed)
    }

    private func animated(_ body: () -> Void) {
        if reduceMotion { body() } else { withAnimation(.smooth, body) }
    }
}

#Preview {
    PreviewContainer { ReviewSessionView() }
}
