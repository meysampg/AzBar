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
            .azScreenBackground()
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
                Circle()
                    .fill(Theme.Palette.goldSoft)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Theme.Palette.goldDeep)
                            .symbolEffect(.breathe, isActive: !reduceMotion)
                    }
                    .accessibilityHidden(true)
                Text("فال حافظ")
                    .font(.azTitle)
                    .foregroundStyle(Theme.Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: niyyat)
                    .font(.poem(settings.poemFont, size: 20))
                    .lineSpacing(settings.poemFont.lineSpacing(20))
                    .padding(.vertical, settings.poemFont.verticalPadding(20))
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .azCard(padding: Theme.Spacing.xl)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                            .strokeBorder(Theme.Palette.gold, lineWidth: 1)
                    }
                Text("فال حافظ رسمی دیرینه در فرهنگ ایرانی است: غزلی تصادفی از دیوان برای خواندن، تأمل و از بر کردن.")
                    .font(.azMeta)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Layout.margin)
            .padding(.top, Theme.Spacing.xl)
            .frame(maxWidth: Theme.Layout.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.Spacing.m) {
                Text("نیت کنید و دکمه را نگه دارید")
                    .font(.azMeta)
                    .foregroundStyle(Theme.Palette.inkSecondary)
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
            Circle()
                .fill(Theme.Palette.goldSoft)
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "book.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Theme.Palette.goldDeep)
                        .symbolEffect(.wiggle, options: .repeating, isActive: !reduceMotion)
                }
                .accessibilityHidden(true)
            Text("در حال گشودن دیوان…")
                .font(.azHeadline)
                .foregroundStyle(Theme.Palette.inkSecondary)
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
            VStack(spacing: Theme.Spacing.l) {
                Text("فال شما: \(poem.title)")
                    .font(.azTitle)
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: Theme.Spacing.xl - 4) {
                    ForEach(poem.couplets) { couplet in
                        CoupletView(couplet: couplet, layout: layout, showMeaning: settings.showMeaning,
                                    transform: settings.showDiacritics ? { $0 } : { PersianText.removingDiacritics($0) })
                    }
                }
                .frame(maxWidth: .infinity)
                .azCard()

                if let summary = poem.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        AzSectionHeader("تفسیر")
                        Text(verbatim: summary)
                            .font(.azMeta)
                            .foregroundStyle(Theme.Palette.inkSecondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .azCard()
                }
            }
            .padding(.horizontal, Theme.Layout.margin)
            .padding(.vertical, Theme.Spacing.l)
            .frame(maxWidth: Theme.Layout.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .safeAreaInset(edge: .bottom) { actions }
    }

    private var actions: some View {
        SessionActionBar {
            HStack(spacing: Theme.Spacing.m) {
                if let recitation {
                    Button {
                        Task { await togglePlayback(recitation) }
                    } label: {
                        Label(isPlayingThis ? "توقف" : "پخش", systemImage: isPlayingThis ? "pause.fill" : "play.fill")
                            .lineLimit(1)
                    }
                    .buttonStyle(.azSecondary)
                }
                if !poem.memorizableCouplets.isEmpty {
                    Button(action: onMemorize) {
                        Text("حفظ کن").lineLimit(1)
                    }
                    .buttonStyle(.azPrimary)
                }
                ShareLink(item: poem.plainText, subject: Text(verbatim: poem.title)) {
                    Label("اشتراک‌گذاری", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.azSecondary)
            }
        }
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
