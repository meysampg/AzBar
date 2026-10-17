import SwiftUI

struct ReaderView: View {
    let poemId: PoemID
    let poetId: PoetID

    @Environment(AppSettings.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(AudioPlayerService.self) private var audio
    @Environment(\.contentRepository) private var content
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var model: ReaderModel
    @State private var width: CGFloat = 0
    @State private var isBarCollapsed = false
    @State private var highlightedIndex: Int?
    @State private var showPath = false

    init(poemId: PoemID, poetId: PoetID) {
        self.poemId = poemId
        self.poetId = poetId
        _model = State(initialValue: ReaderModel(poemId: poemId, poetId: poetId))
    }

    private var layout: CoupletLayout {
        width >= 700 && !dynamicTypeSize.isAccessibilitySize ? .sideBySide : .stacked
    }

    var body: some View {
        Group {
            switch model.phase {
            case .loading:
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed:
                LibraryErrorView { Task { await load() } }
            case .loaded:
                if let poem = model.poem { content(for: poem) }
            }
        }
        .navigationTitle(model.poem?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .navigationDestination(isPresented: $showPath) {
            PoemPathView(poemId: poemId, poetId: poetId)
        }
        .task { await load() }
        .onDisappear {
            if audio.poemId == poemId { audio.stop() }
        }
    }

    private func load() async {
        await model.load(content: content, preferredReciter: settings.preferredReciter)
    }

    // MARK: Content

    private func content(for poem: Poem) -> some View {
        let cards = progress.cards(poemId: poem.id)
        let memorized = Set(cards.filter { $0.value.state != .new }.map(\.key.coupletIndex))
        let transform: (String) -> String = settings.showDiacritics ? { $0 } : { PersianText.removingDiacritics($0) }

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 22) {
                    ReaderHeaderView(poem: poem, poetName: model.poetName)
                    ForEach(poem.couplets) { couplet in
                        coupletRow(couplet, in: poem, isMemorized: memorized.contains(couplet.index), transform: transform)
                            .id(couplet.index)
                    }
                    Text("منبع: گنجور")
                        .font(.app(.footnote))
                        .foregroundStyle(.tertiary)
                        .padding(.top, Theme.Spacing.s)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.s)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .onChange(of: highlightedIndex) { _, new in
                guard let new, audio.status == .playing else { return }
                withAnimation(reduceMotion ? nil : .smooth) {
                    proxy.scrollTo(new, anchor: .center)
                }
            }
        }
        .background { HighlightObserver(model: model, poemId: poem.id, highlighted: $highlightedIndex) }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { old, new in
            let delta = new - old
            if new < 24 || delta < -8 {
                isBarCollapsed = false
            } else if delta > 8 {
                isBarCollapsed = true
            }
        }
        .safeAreaInset(edge: .bottom) {
            ReaderBottomBar(
                poem: poem,
                model: model,
                isCollapsed: isBarCollapsed,
                hasPlan: progress.plan(poemId: poem.id) != nil
            ) {
                memorize(poem)
            }
        }
    }

    private func coupletRow(_ couplet: Couplet, in poem: Poem, isMemorized: Bool,
                            transform: @escaping (String) -> String) -> some View {
        CoupletView(couplet: couplet, layout: layout, isHighlighted: highlightedIndex == couplet.index,
                    showMeaning: settings.showMeaning, transform: transform)
            .overlay(alignment: .topTrailing) {
                if isMemorized {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.green)
                        .padding(Theme.Spacing.s)
                        .accessibilityLabel("حفظ‌شده")
                }
            }
            .contentShape(.rect)
            .onTapGesture {
                model.seekIfPlaying(toCouplet: couplet.index, audio: audio)
            }
            .contextMenu {
                Button("کپی بیت", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = couplet.verses.map { transform($0.text) }.joined(separator: "\n")
                }
                if !poem.recitations.isEmpty {
                    Button("پخش از این بیت", systemImage: "play") {
                        Task { await model.playCouplet(couplet.index, audio: audio) }
                    }
                }
            }
            .accessibilityAction(named: "کپی بیت") {
                UIPasteboard.general.string = couplet.verses.map { transform($0.text) }.joined(separator: "\n")
            }
    }

    private func memorize(_ poem: Poem) {
        if progress.plan(poemId: poem.id) == nil {
            progress.addPlan(poem: poem, poetName: model.poetName)
        }
        audio.stop()
        showPath = true
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if let poem = model.poem {
            ToolbarItemGroup(placement: .topBarTrailing) {
                let isFavorite = progress.isFavorite(poem.id)
                Button {
                    progress.toggleFavorite(poemId: poem.id, poetId: poetId, title: poem.title)
                } label: {
                    Label(isFavorite ? "حذف از علاقه‌مندی‌ها" : "افزودن به علاقه‌مندی‌ها",
                          systemImage: isFavorite ? "heart.fill" : "heart")
                }
                .sensoryFeedback(.selection, trigger: isFavorite)

                Menu {
                    Toggle("نمایش معنی", systemImage: "text.bubble", isOn: Bindable(settings).showMeaning)
                    Toggle("نمایش اعراب", systemImage: "textformat", isOn: Bindable(settings).showDiacritics)
                    Divider()
                    ShareLink(item: poem.plainText, subject: Text(verbatim: poem.title)) {
                        Label("اشتراک‌گذاری", systemImage: "square.and.arrow.up")
                    }
                    Link(destination: poem.ganjoorURL) {
                        Label("مشاهده در گنجور", systemImage: "safari")
                    }
                } label: {
                    Label("بیشتر", systemImage: "ellipsis.circle")
                }
            }
        }
    }
}

/// Observes audio playback in isolation so only this tiny view re-evaluates on every tick.
private struct HighlightObserver: View {
    let model: ReaderModel
    let poemId: PoemID
    @Binding var highlighted: Int?
    @Environment(AudioPlayerService.self) private var audio

    private var index: Int? {
        guard audio.poemId == poemId, audio.isPlaying || audio.currentTime > 0.1,
              let offset = audio.currentVerseOffset else { return nil }
        return model.coupletIndex(forVerseOffset: offset)
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: index, initial: true) { _, new in highlighted = new }
    }
}

/// Floating glass layer: player capsule plus the memorize call-to-action.
private struct ReaderBottomBar: View {
    let poem: Poem
    let model: ReaderModel
    let isCollapsed: Bool
    let hasPlan: Bool
    let onMemorize: () -> Void

    @Environment(AudioPlayerService.self) private var audio

    private var hasAudio: Bool { !poem.recitations.isEmpty }
    private var isThisPoem: Bool { audio.poemId == poem.id }

    var body: some View {
        GlassEffectContainer(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                if hasAudio {
                    PlayerBar(
                        isPlaying: isThisPoem && audio.isPlaying,
                        isLoading: isThisPoem && audio.status == .loading,
                        currentTime: isThisPoem ? audio.currentTime : 0,
                        duration: isThisPoem ? audio.duration : 0,
                        recitations: poem.recitations,
                        selectedRecitationId: model.selectedRecitation?.id,
                        isCollapsed: isCollapsed,
                        onToggle: { Task { await model.togglePlayback(audio: audio) } },
                        onSkipBack: { audio.skip(by: -10) },
                        onSelect: { r in Task { await model.select(r, audio: audio) } }
                    )
                }
                if isCollapsed && hasAudio {
                    Spacer(minLength: 0)
                } else {
                    Button(action: onMemorize) {
                        Text(hasPlan ? "ادامهٔ حفظ" : "حفظ کن")
                            .font(.app(.headline))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, Theme.Spacing.s)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .frame(maxWidth: hasAudio ? nil : .infinity)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.s)
        .animation(.smooth, value: isCollapsed)
        .sensoryFeedback(.impact(weight: .light), trigger: hasPlan)
    }
}

#Preview {
    PreviewContainer {
        NavigationStack {
            ReaderView(poemId: 2130, poetId: 2)
        }
    }
}
