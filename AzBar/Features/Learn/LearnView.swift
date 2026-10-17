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
                    LessonCompleteView(
                        kind: model.kind,
                        passed: model.passed,
                        reward: model.reward,
                        xp: model.totalXP,
                        learnedCount: model.learnedKeys.count,
                        isPoemComplete: model.isPoemComplete,
                        hasNextLesson: model.hasNextLesson,
                        onNext: {
                            withAnimation(reduceMotion ? nil : .smooth) { model.startNextLesson() }
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
                        Text(model.titleText)
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
        .task {
            await model.load(content: app.content, progress: app.progress, settings: app.settings,
                             gamification: app.gamification, sounds: app.sounds)
        }
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
            LessonProgressBar(value: model.progressValue)
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.s)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LearnBottomBar(model: model)
        }
    }

    private func reload() async {
        await model.retry(content: app.content, progress: app.progress, settings: app.settings,
                          gamification: app.gamification, sounds: app.sounds)
    }
}

#Preview {
    PreviewContainer {
        LearnView(request: LearnRequest(poemId: 2130, poetId: 2))
    }
}
