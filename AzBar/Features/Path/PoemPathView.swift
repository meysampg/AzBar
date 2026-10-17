import SwiftUI

/// The learning path of one poem: header, one continuous curve through medallion nodes, completion card.
struct PoemPathView: View {
    let poemId: PoemID
    let poetId: PoetID

    @Environment(AppModel.self) private var appModel
    @Environment(ProgressStore.self) private var progress
    @Environment(GamificationStore.self) private var gamification
    @Environment(\.contentRepository) private var content

    private enum Phase {
        case loading, failed
        case loaded(Poem)
    }

    @State private var phase: Phase = .loading

    var body: some View {
        Group {
            switch phase {
            case .loading:
                AzLoadingView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed:
                AzErrorView { Task { await load() } }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let poem):
                if poem.memorizableCouplets.isEmpty {
                    AzEmptyState("text.alignright", "این متن بیتی برای حفظ ندارد",
                                 "متن‌های نثر را می‌توان خواند، اما مسیر حفظ ندارند.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    pathContent(poem)
                }
            }
        }
        .azScreenBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: LibraryRoute.poem(poemId, poetId: poetId)) {
                    Label("متن شعر", systemImage: "text.book.closed")
                }
            }
        }
        .task { await load() }
    }

    private var title: String {
        if case .loaded(let poem) = phase { return poem.title }
        return "مسیر یادگیری"
    }

    private func load() async {
        if case .loaded = phase { return }
        phase = .loading
        do {
            phase = .loaded(try await content.poem(poemId, poetId: poetId))
        } catch {
            phase = .failed
        }
    }

    private func pathContent(_ poem: Poem) -> some View {
        let nodes = gamification.path(for: poem)
        let cards = progress.cards(poemId: poem.id)
        let started = Set(cards.filter { $0.value.state != .new }.map(\.key.coupletIndex))
        let memorizable = poem.memorizableCouplets.map(\.index)
        let position = Dictionary(uniqueKeysWithValues: memorizable.enumerated().map { ($1, $0 + 1) })
        let learned = memorizable.filter(started.contains).count
        let crowns = nodes.filter { $0.state == .mastered }.count
        let current = LearningPath.currentNode(in: nodes)
        let lessonsDone = nodes.filter { $0.kind == .lesson }.allSatisfy { $0.state >= .completed }
        let challengeOK = nodes.last(where: { $0.kind == .challenge }).map { $0.state >= .completed } ?? true
        let poemComplete = !nodes.isEmpty && lessonsDone && challengeOK
        let poetName = progress.plan(poemId: poemId)?.poetName ?? content.catalog.entry(poetId)?.name ?? ""

        var ranges: [String: ClosedRange<Int>] = [:]
        for node in nodes where node.kind == .lesson {
            if let a = node.coupletIndices.first.flatMap({ position[$0] }),
               let b = node.coupletIndices.last.flatMap({ position[$0] }), a <= b {
                ranges[node.id] = a...b
            }
        }
        let partial = current.flatMap { $0.coupletIndices.contains(where: started.contains) ? $0.id : nil }

        return ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    PathHeader(title: poem.title, poetName: poetName, totalCouplets: memorizable.count,
                               learned: learned, crowns: crowns)
                        .padding(.horizontal, Theme.Layout.margin)
                    PathMapView(nodes: nodes, beytRanges: ranges, partialNodeId: partial) { mode in
                        appModel.startLearning(poemId: poemId, poetId: poetId, mode: mode)
                    }
                    if poemComplete {
                        Label("این شعر را کامل از بر کردید!", systemImage: "party.popper.fill")
                            .font(.azHeadline)
                            .foregroundStyle(Theme.Palette.goldDeep)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .azCard(fill: Theme.Palette.goldSoft)
                            .padding(.horizontal, Theme.Layout.margin)
                    }
                }
                .frame(maxWidth: Theme.Layout.readableWidth)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.l)
            }
            .onAppear {
                if let current { proxy.scrollTo(current.id, anchor: .center) }
            }
        }
    }
}

#Preview {
    PreviewContainer {
        NavigationStack { PoemPathView(poemId: 2130, poetId: 2).libraryDestinations() }
    }
}
