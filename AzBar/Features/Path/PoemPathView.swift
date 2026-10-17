import SwiftUI

/// The learning path of one poem (Duolingo-style winding node list).
struct PoemPathView: View {
    let poemId: PoemID
    let poetId: PoetID

    @Environment(AppModel.self) private var appModel
    @Environment(ProgressStore.self) private var progress
    @Environment(GamificationStore.self) private var gamification
    @Environment(\.contentRepository) private var content

    @State private var phase: LibraryLoadPhase<Poem> = .loading
    @State private var width: CGFloat = 360

    private static let zig: [CGFloat] = [0, 0.66, 1, 0.66, 0, -0.66, -1, -0.66]

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView().controlSize(.large).frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed:
                LibraryErrorView { Task { await load() } }
            case .loaded(let poem):
                pathContent(poem)
            }
        }
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
        let challengeDone = nodes.last.map { $0.kind == .challenge && $0.state >= .completed } ?? false
        let amp = min(90, width * 0.22)
        let poetName = progress.plan(poemId: poemId)?.poetName ?? content.catalog.entry(poetId)?.name ?? ""

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 28) {
                    PathHeader(title: poem.title, poetName: poetName, totalCouplets: memorizable.count,
                               learned: learned, crowns: crowns)
                        .padding(.bottom, Theme.Spacing.s)
                    ForEach(Array(nodes.enumerated()), id: \.element.id) { i, node in
                        PathNodeView(
                            node: node,
                            beytRange: range(of: node, position: position),
                            isPartial: node.state == .current && node.coupletIndices.contains(where: started.contains),
                            onStart: { mode in appModel.startLearning(poemId: poemId, poetId: poetId, mode: mode) }
                        )
                        .offset(x: Self.zig[i % Self.zig.count] * amp)
                        .id(node.id)
                    }
                    if challengeDone {
                        Label("این غزل را کامل از بر کردید!", systemImage: "party.popper.fill")
                            .font(.app(.headline))
                            .foregroundStyle(Theme.Playful.gold)
                            .multilineTextAlignment(.center)
                            .padding(.top, Theme.Spacing.l)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.l)
            }
            .onAppear {
                if let current { proxy.scrollTo(current.id, anchor: .center) }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .background(Color(.systemGroupedBackground))
    }

    private func range(of node: PathNode, position: [Int: Int]) -> ClosedRange<Int>? {
        guard node.kind == .lesson,
              let a = node.coupletIndices.first.flatMap({ position[$0] }),
              let b = node.coupletIndices.last.flatMap({ position[$0] }), a <= b else { return nil }
        return a...b
    }
}

#Preview {
    PreviewContainer {
        NavigationStack { PoemPathView(poemId: 2130, poetId: 2).libraryDestinations() }
    }
}
