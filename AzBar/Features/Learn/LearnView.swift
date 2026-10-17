import SwiftUI

struct LearnView: View {
    let request: LearnRequest

    @Environment(AppModel.self) private var app
    @Environment(AudioPlayerService.self) private var audio
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: LearnModel
    @State private var isConfirmingClose = false

    init(request: LearnRequest) {
        self.request = request
        _model = State(initialValue: LearnModel(request: request))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch model.phase {
                case .loading:
                    ProgressView()
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed:
                    ContentUnavailableView {
                        Label("بارگذاری شعر ممکن نشد", systemImage: "exclamationmark.triangle")
                    } actions: {
                        Button("تلاش دوباره") {
                            Task { await reload() }
                        }
                        .buttonStyle(.glass)
                    }
                case .session:
                    sessionContent
                case .summary:
                    LearnSummaryView(
                        learnedCount: model.learnedKeys.count,
                        isPoemComplete: model.isPoemComplete,
                        poemTitle: model.poem?.title ?? "",
                        onContinue: {
                            withAnimation(reduceMotion ? nil : .smooth) { model.startBatch() }
                        },
                        onFinish: { dismiss() }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("بستن", systemImage: "xmark") {
                        if model.phase == .session {
                            isConfirmingClose = true
                        } else {
                            dismiss()
                        }
                    }
                    .accessibilityLabel("بستن")
                }
                if model.phase == .session {
                    ToolbarItem(placement: .principal) {
                        Text("بیت \(model.positionInBatch.fa) از \(model.batchCount.fa)")
                            .font(.app(.headline))
                            .accessibilityAddTraits(.isHeader)
                    }
                }
            }
            .confirmationDialog("جلسه را ترک می‌کنید؟", isPresented: $isConfirmingClose, titleVisibility: .visible) {
                Button("ترک جلسه", role: .destructive) { dismiss() }
                Button("ادامه", role: .cancel) {}
            } message: {
                Text("پیشرفت بیت‌هایی که امتیاز داده‌اید ذخیره شده است.")
            }
        }
        .interactiveDismissDisabled(model.phase == .session)
        .task { await model.load(content: app.content, progress: app.progress, settings: app.settings) }
        .onDisappear { model.stopAudioIfNeeded(audio: audio) }
    }

    private var sessionContent: some View {
        ScrollView {
            LearnStepBody(model: model)
                .id(model.stepKey)
                .transition(.opacity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: model.stepKey)
        .safeAreaInset(edge: .top, spacing: 0) {
            ProgressView(value: model.progressValue)
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.xs)
                .accessibilityLabel("پیشرفت جلسه")
                .accessibilityValue("\(Int((model.progressValue * 100).rounded()).fa) درصد")
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LearnBottomBar(model: model)
        }
    }

    private func reload() async {
        await model.retry(content: app.content, progress: app.progress, settings: app.settings)
    }
}

#Preview {
    PreviewContainer {
        LearnView(request: LearnRequest(poemId: 2130, poetId: 2))
    }
}
