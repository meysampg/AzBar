import SwiftUI

/// Sub-categories and poems of one category, with local search.
struct CategoryView: View {
    let categoryId: CategoryID
    let poetId: PoetID

    @Environment(\.contentRepository) private var content
    @Environment(ProgressStore.self) private var progress
    @State private var phase: LibraryLoadPhase<PoemCategory> = .loading
    @State private var searchText = ""

    private var loadedTitle: String? {
        if case .loaded(let category) = phase { return category.title }
        return nil
    }

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
        .navigationTitle(loadedTitle ?? "")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText,
                    prompt: loadedTitle.map { "جستجو در \($0)" } ?? "جستجو")
        .task { await load() }
    }

    private func filtered(_ poems: [PoemSummary]) -> [PoemSummary] {
        let q = PersianText.normalizeForSearch(searchText)
        guard !q.isEmpty else { return poems }
        return poems.filter {
            PersianText.normalizeForSearch($0.title).contains(q)
                || PersianText.normalizeForSearch($0.excerpt ?? "").contains(q)
        }
    }

    private func list(_ category: PoemCategory) -> some View {
        let favorites = Set(progress.favorites().map(\.poemId))
        let planned = Set(progress.activePlans().map(\.poemId))
        let poems = filtered(category.poems)
        let isSearching = !searchText.trimmingCharacters(in: .whitespaces).isEmpty
        return List {
            if !category.children.isEmpty && !isSearching {
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
            if !poems.isEmpty {
                Section {
                    ForEach(poems) { summary in
                        PoemRow(summary: summary, poetId: poetId,
                                isFavorite: favorites.contains(summary.id),
                                isMemorizing: planned.contains(summary.id))
                    }
                } header: {
                    Text("اشعار · \(poems.count.fa)").font(.app(.footnote, weight: .medium))
                }
            }
        }
        .overlay {
            if poems.isEmpty && (isSearching || category.children.isEmpty) {
                if isSearching {
                    ContentUnavailableView("نتیجه‌ای یافت نشد", systemImage: "magnifyingglass",
                                           description: Text("عبارت دیگری را امتحان کنید."))
                } else {
                    ContentUnavailableView("شعری یافت نشد", systemImage: "text.book.closed")
                }
            }
        }
    }

    private func load() async {
        phase = .loading
        do {
            phase = .loaded(try await content.category(categoryId, poetId: poetId))
        } catch {
            if !Task.isCancelled { phase = .failed }
        }
    }
}

#Preview {
    PreviewContainer {
        NavigationStack {
            CategoryView(categoryId: 24, poetId: 2)
                .libraryDestinations()
        }
    }
}
