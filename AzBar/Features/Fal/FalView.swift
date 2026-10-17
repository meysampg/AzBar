import SwiftUI

struct FalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.contentRepository) private var content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppModel.self) private var appModel
    @Environment(AppSettings.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(AudioPlayerService.self) private var audio
    @Environment(GamificationStore.self) private var gamification

    @State private var model = FalModel()

    var body: some View {
        NavigationStack {
            ZStack {
                switch model.phase {
                case .niyyat:
                    FalNiyyatView { model.confirmNiyyat() }
                        .transition(.opacity)
                case .opening:
                    FalOpeningView()
                        .transition(.opacity)
                case .failed:
                    LibraryErrorView { model.confirmNiyyat() }
                        .transition(.opacity)
                case .result(let poem):
                    FalResultView(poem: poem, onMemorize: { memorize(poem) })
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.5), value: model.phase)
            .navigationTitle("فال حافظ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
                if case .result = model.phase {
                    ToolbarItem(placement: .primaryAction) {
                        Button("فال دوباره", systemImage: "arrow.clockwise") {
                            audio.stop()
                            model.reset()
                        }
                        .sensoryFeedback(.selection, trigger: model.phase)
                    }
                }
            }
        }
        .onChange(of: model.phase) { _, phase in
            if case .result = phase { gamification.recordFalOpened() }
        }
        .task(id: model.requestId) {
            await model.open(content: content)
        }
        .onDisappear {
            if case .result(let poem) = model.phase, audio.poemId == poem.id { audio.stop() }
        }
    }

    private func memorize(_ poem: Poem) {
        let poetName = content.catalog.entry(poem.poetId)?.name ?? "حافظ"
        if progress.plan(poemId: poem.id) == nil {
            progress.addPlan(poem: poem, poetName: poetName)
        }
        audio.stop()
        let poetId = poem.poetId
        let model = appModel
        dismiss()
        Task { @MainActor in
            // Let the sheet finish dismissing before presenting the learning cover.
            try? await Task.sleep(for: .milliseconds(500))
            model.startLearning(poemId: poem.id, poetId: poetId)
        }
    }
}

// MARK: - Phase 1: niyyat

private struct FalNiyyatView: View {
    let onConfirm: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let niyyat = "ای حافظ شیرازی! تو محرم هر رازی! تو را به خدا و به شاخ نباتت قسم می\u{200C}دهم که هر چه صلاح و مصلحت می\u{200C}بینی برایم آشکار و آرزوی مرا برآورده سازی."

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                    .symbolEffect(.breathe, isActive: !reduceMotion)
                    .accessibilityHidden(true)
                Text("فال حافظ")
                    .font(.app(.largeTitle))
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: niyyat)
                    .font(.poem(settings.poemFont, size: 20))
                    .lineSpacing(settings.poemFont.lineSpacing(20))
                    .padding(.vertical, settings.poemFont.verticalPadding(20))
                    .multilineTextAlignment(.center)
                    .padding(Theme.Spacing.xl)
                    .frame(maxWidth: .infinity)
                    .background(.background.secondary, in: .rect(cornerRadius: Theme.Radius.card))
                Text("فال حافظ رسمی دیرینه در فرهنگ ایرانی است: غزلی تصادفی از دیوان برای خواندن، تأمل و از بر کردن.")
                    .font(.app(.footnote))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.top, Theme.Spacing.xl)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.Spacing.m) {
                Text("نیت کنید و دکمه را نگه دارید")
                    .font(.app(.footnote))
                    .foregroundStyle(.secondary)
                HoldToConfirmButton("نیت کردم", onConfirm: onConfirm)
            }
            .padding(.bottom, Theme.Spacing.l)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Phase 2: opening

private struct FalOpeningView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "book.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
                .symbolEffect(.wiggle, options: .repeating, isActive: !reduceMotion)
                .accessibilityHidden(true)
            Text("در حال گشودن دیوان…")
                .font(.app(.headline))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Phase 3: result

private struct FalResultView: View {
    let poem: Poem
    let onMemorize: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(AudioPlayerService.self) private var audio
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var width: CGFloat = 0

    private var layout: CoupletLayout {
        width >= 700 && !dynamicTypeSize.isAccessibilitySize ? .sideBySide : .stacked
    }

    private var recitation: Recitation? {
        RecitationPicker.preferred(poem.recitations, artist: settings.preferredReciter)
    }

    private var isPlayingThis: Bool { audio.poemId == poem.id && audio.isPlaying }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("فال شما: \(poem.title)")
                    .font(.app(.title2))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)

                ForEach(poem.couplets) { couplet in
                    CoupletView(couplet: couplet, layout: layout, showMeaning: settings.showMeaning,
                                transform: settings.showDiacritics ? { $0 } : { PersianText.removingDiacritics($0) })
                }

                if let summary = poem.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Label("تفسیر", systemImage: "text.book.closed")
                            .font(.app(.headline))
                        Text(verbatim: summary)
                            .font(.app(.subheadline))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.l)
                    .background(.background.secondary, in: .rect(cornerRadius: Theme.Radius.card))
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.l)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .safeAreaInset(edge: .bottom) { actions }
    }

    private var actions: some View {
        GlassEffectContainer(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                if let recitation {
                    Button {
                        Task { await togglePlayback(recitation) }
                    } label: {
                        Label(isPlayingThis ? "توقف" : "پخش", systemImage: isPlayingThis ? "pause.fill" : "play.fill")
                            .font(.app(.subheadline, weight: .medium))
                            .lineLimit(1)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                }
                Button(action: onMemorize) {
                    Text("حفظ کن")
                        .font(.app(.headline))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)

                ShareLink(item: poem.plainText, subject: Text(verbatim: poem.title)) {
                    Label("اشتراک‌گذاری", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.s)
    }

    private func togglePlayback(_ recitation: Recitation) async {
        if audio.poemId == poem.id, audio.recitation?.id == recitation.id {
            if case .failed = audio.status {
                await audio.load(poem: poem, recitation: recitation, autoplay: true)
            } else {
                audio.toggle()
            }
        } else {
            await audio.load(poem: poem, recitation: recitation, autoplay: true)
        }
    }
}

#Preview {
    PreviewContainer {
        Text(verbatim: "")
            .sheet(isPresented: .constant(true)) { FalView() }
    }
}
