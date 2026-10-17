import SwiftUI

/// The children (and direct poems) of a poet's root category.
struct PoetView: View {
    let poetId: PoetID

    @Environment(\.contentRepository) private var content
    @Environment(ProgressStore.self) private var progress
    @State private var phase: LibraryLoadPhase<PoemCategory> = .loading

    private var title: String { content.catalog.entry(poetId)?.name ?? "" }

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed:
                LibraryErrorView { Task { await load() } }
            case .loaded(let category):
                list(category)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .task { await load() }
    }

    private func list(_ category: PoemCategory) -> some View {
        let favorites = Set(progress.favorites().map(\.poemId))
        let planned = Set(progress.activePlans().map(\.poemId))
        return List {
            if !category.children.isEmpty {
                Section {
                    ForEach(category.children) { child in
                        NavigationLink(value: LibraryRoute.category(child.id, poetId: poetId)) {
                            Label {
                                Text(verbatim: child.title).font(.app(.body, weight: .medium))
                            } icon: {
                                Image(systemName: "folder")
                            }
                        }
                    }
                } header: {
                    Text("بخش‌ها").font(.app(.footnote, weight: .medium))
                }
            }
            if !category.poems.isEmpty {
                Section {
                    ForEach(category.poems) { summary in
                        PoemRow(summary: summary, poetId: poetId,
                                isFavorite: favorites.contains(summary.id),
                                isMemorizing: planned.contains(summary.id))
                    }
                } header: {
                    Text("اشعار").font(.app(.footnote, weight: .medium))
                }
            }
        }
        .overlay {
            if category.children.isEmpty && category.poems.isEmpty {
                ContentUnavailableView("شعری یافت نشد", systemImage: "text.book.closed")
            }
        }
    }

    private func load() async {
        phase = .loading
        do {
            phase = .loaded(try await content.rootCategory(poetId: poetId))
        } catch {
            if !Task.isCancelled { phase = .failed }
        }
    }
}

#Preview {
    PreviewContainer {
        NavigationStack {
            PoetView(poetId: 2)
                .libraryDestinations()
        }
    }
}
